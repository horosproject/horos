//
//  DCMStoreSCU.m
//  OsiriX
//
//  Created by Lance Pysher on 12/20/04.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMStoreSCU.h"
#import "DCM.h"
#import "DCMPresentationContext.h"
#import "DCMAbstractSyntaxUID.h"
#import "DCMAssociation.h"
#import "DCMCStoreRequest.h"
#import "DCMCStoreResponseHandler.h"


@implementation DCMStoreSCU

+ (id)sendWithParameters:(NSDictionary *)parameters{
	DCMStoreSCU *storeSCU = [[[DCMStoreSCU alloc] initWithParameters:parameters] autorelease];
	[storeSCU send];
	
	return storeSCU;
}
	

- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init]) {
		affectedSOPClassUIDs = [[NSMutableArray array] retain];
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abortSend:) name:@"DCMAbortSendNotification" object:nil];
		debugLevel = 0;

		if ([params objectForKey:@"debugLevel"])
			debugLevel = [[params objectForKey:@"debugLevel"] intValue];
		filesToSend = [[params objectForKey:@"filesToSend"] retain];
		if (filesToSend){
			numberOfFiles = [filesToSend count];
			compression = [[params objectForKey:@"compression"] intValue];
			preferredSyntax = [[params objectForKey:@"transferSyntax"] retain];
			if (!preferredSyntax){
				DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:[filesToSend objectAtIndex:0] decodingPixelData:NO];
				preferredSyntax = [[[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"TransferSyntaxUID"]] value] retain];
			}
			affectedSOPClassUID = [[params objectForKey:@"affectedSOPClassUID"] retain];
			if (!affectedSOPClassUID) {
				DCMObject *object = [DCMObject objectWithContentsOfFile:[filesToSend objectAtIndex:0] decodingPixelData:NO];
				affectedSOPClassUID = [[object attributeValueWithName:@"SOPClassUID"] retain];
			}
			else
				[affectedSOPClassUIDs addObject:affectedSOPClassUID];
		}
		
		NSMutableArray *presentationContexts = [NSMutableArray array];
		NSEnumerator *syntaxEnumerator = [[DCMAbstractSyntaxUID imageSyntaxes] objectEnumerator];
		NSString *abstractSyntax;
		unsigned char presentationContextID = 0x01;	// always odd numbered, starting with 0x01
		//first PresentationContex contains all syntaxes for sopClassUID
		while (abstractSyntax = [syntaxEnumerator nextObject]){
			DCMPresentationContext *context = [DCMPresentationContext contextWithID:presentationContextID];
			[context setAbstractSyntax:abstractSyntax];
			
			[context addTransferSyntax:preferredSyntax];
			
			// if preferredSyntax is lossy add lossless version
			if ([preferredSyntax isEqualToTransferSyntax:[DCMTransferSyntax JPEG2000LossyTransferSyntax]])
				[context addTransferSyntax:[DCMTransferSyntax JPEG2000LosslessTransferSyntax]];
			if ([preferredSyntax isEqualToTransferSyntax:[DCMTransferSyntax JPEGExtendedTransferSyntax]])
				[context addTransferSyntax:[DCMTransferSyntax JPEGLosslessTransferSyntax]];
			if ([preferredSyntax isEqualToTransferSyntax:[DCMTransferSyntax JPEGBaselineTransferSyntax]])
				[context addTransferSyntax:[DCMTransferSyntax JPEGLosslessTransferSyntax]];

			//add uncompressed syntaxes
			if (![preferredSyntax isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]])
				[context addTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]];
			if (![preferredSyntax isEqualToTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]])
				[context addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];

			[presentationContexts addObject:context];
			
			
			//add separate presentation Contexts for each syntax
			NSEnumerator *enumerator  = [[context transferSyntaxes] objectEnumerator];
			DCMTransferSyntax *syntax;
			while (syntax = [enumerator nextObject]) {
				NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
				presentationContextID += 2;
				DCMPresentationContext *pContext = [DCMPresentationContext contextWithID:presentationContextID];
				[pContext setAbstractSyntax:abstractSyntax];
				[pContext addTransferSyntax:syntax];
				[presentationContexts addObject:pContext];
				[subPool release];
			}
		}
		NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
		[newParams setObject:self  forKey:@"delegate"];
		[newParams setObject:presentationContexts forKey:@"presentationContexts"];
		if (![newParams objectForKey:@"receivedDataHandler"]) {
			dataHandler = [[DCMCStoreResponseHandler alloc] initWithDebugLevel:0];
			[newParams setObject:dataHandler forKey:@"receivedDataHandler"];
		}
		else
		  dataHandler = [[newParams objectForKey:@"receivedDataHandler"] retain];
		
		[dataHandler setNumberOfFiles:numberOfFiles];
		if ([params objectForKey:@"moveHandler"])
			[dataHandler setMoveHandler:[params objectForKey:@"moveHandler"]];
		else
			[dataHandler setMoveHandler:nil];
		[dataHandler setCalledAET:[newParams objectForKey:@"calledAET"]];

		[newParams setObject:[NSNumber numberWithInt:debugLevel] forKey:@"debugLevel"];
		
		if (debugLevel)
			NSLog(@"Create association for storeSCU");
		association  = [[DCMAssociation associationInitiatorWithParameters:newParams] retain];
		
		[pool release];
	}
	return self;
}

- (void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[dataHandler release];
	[affectedSOPClassUID release];
	[affectedSOPClassUIDs release];
	[filesToSend release];
	[preferredSyntax release];
	[transferSyntax  release];
	[super dealloc];
}

- (BOOL)createAssociationWithParameters:(NSDictionary *)parameters{
	return NO;
}


- (void)send{
	if (association && [association isConnected]){
		//if (debugLevel)
		//	NSLog(@"Start sending");
		 usePresentationContextID = [association presentationContextIDForAbstractSyntax:affectedSOPClassUID];
		 transferSyntax = [[association transferSyntaxForPresentationContextID:usePresentationContextID] retain];
		 if (debugLevel)
			NSLog(@"using transfer syntax:%@", [transferSyntax description]);
		 NSEnumerator *enumerator = [filesToSend objectEnumerator];
		 NSString *file;
		 while (file = [enumerator nextObject]){
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
			//create new SOPInstance UID if new lossy transfer syntax
	
			NSString *sopInstance = [[dcmObject attributeForTag:[DCMAttributeTag tagWithName:@"SOPInstanceUID"]] value];
			DCMCStoreRequest *request = [DCMCStoreRequest storeRequestWithAffectedSOPClassUID:affectedSOPClassUID  affectedSOPInstanceUID:sopInstance];
			[dataHandler setCurrentObject:dcmObject];
			if ([association isConnected]){
				usePresentationContextID = [association presentationContextIDForAbstractSyntax:[dcmObject attributeValueWithName:@"SOPClassUID"]];
				[association send:[request data]  asCommand:YES  presentationContext:usePresentationContextID];
				[association send:[dcmObject writeDatasetWithTransferSyntax:transferSyntax quality:compression] asCommand:NO
					presentationContext:usePresentationContextID];
				[association waitForCommandPDataPDUs];
			}
			[pool release];
		}
		[association releaseAssociation];
	}
	else{
		NSLog(@"No valid association for send");
	}
}

- (void)sendObject:(DCMObject *)dcmObject{
}

- (void)abortSend:(NSNotification *)note{
	[association terminate:self];
}

@end
