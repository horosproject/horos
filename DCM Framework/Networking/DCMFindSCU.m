//
//  DCMFindSCU.m
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

#import "DCMFindSCU.h"
#import "DCM.h"
#import "DCMNetworking.h"

@implementation DCMFindSCU

+ (void)findWithParameters:(NSDictionary *)parameters{
	DCMFindSCU *findSCU = [[[DCMFindSCU alloc] initWithParameters:parameters] autorelease];
	[findSCU find];
}
- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abortQuery:) name:@"DCMAbortQueryNotification" object:nil];
		findObject = [[params objectForKey:@"findObject"] retain];
		debugLevel = 0;
		if ([params objectForKey:@"debugLevel"])
			debugLevel = [[params objectForKey:@"debugLevel"] intValue];
		
		preferredSyntax = [[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] retain];

		affectedSOPClassUID = [[params objectForKey:@"affectedSOPClassUID"] retain];

		
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
		NSEnumerator *enumerator  = [[context transferSyntaxes] objectEnumerator];
		DCMTransferSyntax *syntax;
		while (syntax = [enumerator nextObject]) {
			NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
			presentationContextID += 2;
			DCMPresentationContext *pContext = [DCMPresentationContext contextWithID:presentationContextID];
			[pContext setAbstractSyntax:affectedSOPClassUID];
			[pContext addTransferSyntax:syntax];
			[presentationContexts addObject:pContext];
			[subPool release];
		}
		
		NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
		[newParams setObject:presentationContexts forKey:@"presentationContexts"];
		 dataHandler = [[DCMCFindResponseDataHandler alloc] initWithDebugLevel:0];
		 if (![newParams objectForKey:@"receivedDataHandler"])
			[newParams setObject:dataHandler forKey:@"receivedDataHandler"];
		[newParams setObject:[NSNumber numberWithInt:120000]  forKey:@"timeout"];
		[newParams setObject:self  forKey:@"delegate"];
		if (debugLevel)
			NSLog(@"Create association for findSCU");
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
	[findObject release];
	[preferredSyntax release];
	[transferSyntax  release];
	[super dealloc];
}

- (void)find{
	if (association && [association isConnected]){
		if (debugLevel)
			NSLog(@"Start sending");
		 usePresentationContextID = [association presentationContextIDForAbstractSyntax:affectedSOPClassUID];
		 transferSyntax = [[association transferSyntaxForPresentationContextID:usePresentationContextID] retain];
		 if (debugLevel)
			NSLog(@"using transfer syntax:%@", [transferSyntax description]);
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		DCMCFindRequest *request = [DCMCFindRequest findRequestWithAffectedSOPClassUID:affectedSOPClassUID];
		//[dataHandler setCurrentObject:dcmObject];
		[association send:[request data]  asCommand:YES  presentationContext:usePresentationContextID];
		[association send:[findObject writeDatasetWithTransferSyntax:transferSyntax quality:100] asCommand:NO
				presentationContext:usePresentationContextID];
		[association waitForPDataPDUsUntilHandlerReportsDone];
		[pool release];
		[association releaseAssociation];
		
	}
}

- (void)abortQuery:(NSNotification *)note{
	[association terminate:self];
}

@end
