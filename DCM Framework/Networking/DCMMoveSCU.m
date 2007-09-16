//
//  DCMMoveSCU.m
//  OsiriX
//
//  Created by Lance Pysher on 12/31/04.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/   

#import "DCMMoveSCU.h"
#import "DCM.h"
#import "DCMNetworking.h"


@implementation DCMMoveSCU

+ (void)moveWithParameters:(NSDictionary *)parameters{ 
	DCMMoveSCU *moveSCU = [[[DCMMoveSCU alloc] initWithParameters:parameters] autorelease];
	[moveSCU move];
}


- (id) initWithParameters:(NSDictionary *)parameters{
	if (self = [super init]) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abortMove:) name:@"DCMAbortMoveNotification" object:nil];

			moveObject = [[parameters objectForKey:@"moveObject"] retain];
			debugLevel = 0;
			if ([parameters objectForKey:@"debugLevel"])
				debugLevel = [[parameters objectForKey:@"debugLevel"] intValue];
		
			preferredSyntax = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];
			if ([parameters objectForKey:@"affectedSOPClassUID"])
				affectedSOPClassUID = [[parameters objectForKey:@"affectedSOPClassUID"] retain];
			else
				affectedSOPClassUID = [[DCMAbstractSyntaxUID studyRootQueryRetrieveInformationModelMove] retain];
			moveDestination = [[parameters objectForKey:@"moveDestination"] retain];
			
			NSMutableArray *presentationContexts = [NSMutableArray array];
			
			unsigned char presentationContextID = 0x01;	// always odd numbered, starting with 0x01
			//first PresentationContex contains all syntaxes for sopClassUID
			DCMPresentationContext *context = [DCMPresentationContext contextWithID:presentationContextID];
			[context setAbstractSyntax:affectedSOPClassUID];
			
			[context addTransferSyntax:preferredSyntax];

			//add uncompressed syntaxes
			if (![preferredSyntax isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]]) 			
				[context addTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]];
			if (![preferredSyntax isEqualToTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]])
				[context addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];

			[presentationContexts addObject:context];
			
			
			//add separate presentation Contexts for each syntax
			for ( DCMTransferSyntax *syntax in [context transferSyntaxes] ) {
				NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
				presentationContextID += 2;
				DCMPresentationContext *pContext = [DCMPresentationContext contextWithID:presentationContextID];
				[pContext setAbstractSyntax:affectedSOPClassUID];
				[pContext addTransferSyntax:syntax];
				[presentationContexts addObject:pContext];
				[subPool release];
			}
			
			NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
			[newParams setObject:presentationContexts forKey:@"presentationContexts"];
			[newParams setObject:self  forKey:@"delegate"];
			if (![newParams objectForKey:@"receivedDataHandler"]) {
				dataHandler = [[DCMCMoveResponseDataHandler alloc] initWithDebugLevel:0];
				[newParams setObject:dataHandler forKey:@"receivedDataHandler"];
			}
			else
				dataHandler = [[newParams objectForKey:@"receivedDataHandler"] retain];
				
			if ([newParams objectForKey:@"calledAET"])
				[dataHandler  setCalledAET:[newParams objectForKey:@"calledAET"]];
			
			if (debugLevel)
				NSLog(@"Create association for moveSCU");
			NSLog(@"move Params: %@", [newParams description]);
			association  = [[DCMAssociation associationInitiatorWithParameters:newParams] retain];
			
			[pool release];
		}
		return self;

}

- (void)dealloc{
	//[association release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[dataHandler release];
	[affectedSOPClassUID release];
	[moveObject release];
	[moveDestination release];
	[preferredSyntax release];
	[transferSyntax  release];
	[super dealloc];
}

- (void)move{
	if (association && [association isConnected]){
		if (debugLevel)
			NSLog(@"Start moving");
		 usePresentationContextID = [association presentationContextIDForAbstractSyntax:affectedSOPClassUID];
		 transferSyntax = [[association transferSyntaxForPresentationContextID:usePresentationContextID] retain];
		 if (debugLevel)
			NSLog(@"Move using transfer syntax:%@ destination%@", [transferSyntax description], moveDestination);
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		DCMCMoveRequest *request = [DCMCMoveRequest moveRequestWithAffectedSOPClassUID:affectedSOPClassUID moveDestination:moveDestination];
		//[dataHandler setCurrentObject:dcmObject];
		[association send:[request data]  asCommand:YES  presentationContext:usePresentationContextID];
		[association send:[moveObject writeDatasetWithTransferSyntax:transferSyntax quality:100] asCommand:NO
				presentationContext:usePresentationContextID];
		[association waitForPDataPDUsUntilHandlerReportsDone];
		[pool release];
		[association releaseAssociation];
	}
}

- (void)abortMove:(NSNotification *)note{
	[association terminate:self];
}

@end
