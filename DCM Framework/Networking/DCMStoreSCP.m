//
//  DCMStoreSCP.m
//  OsiriX
//
//  Created by Lance Pysher on 12/23/04.

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

#import "DCMStoreSCP.h"
#import "DCM.h"
#import "DCMCStoreReceivedPDUHandler.h"
#import "DCMAssociationResponder.h"
#import "DCMNetworking.h"



@implementation DCMStoreSCP

+ (void)runStoreSCP:(NSDictionary *)params{
	 DCMStoreSCP *storeSCP = [[DCMStoreSCP alloc] initWithParameters:params];
	 [storeSCP run];
	 [storeSCP release];
}

- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init]){
		folder = [[params objectForKey:@"folder"] retain];
		calledAET= [[params objectForKey:@"calledAET"] retain];
		socket = [[params objectForKey:@"socket"] retain];
		socketHandle = [[params objectForKey:@"socketHandle"] retain];
		debugLevel = 0;
		if ([params objectForKey:@"debugLevel"])
			debugLevel = [[params objectForKey:@"debugLevel"] intValue];
		if ([params objectForKey:@"receivedDataHandler"])
			dataHandler = [[params objectForKey:@"receivedDataHandler"] retain];
		else
			[self newDataHandler];
		timeout = 5000;
		if ([params objectForKey:@"timeout"])
			timeout = [[params objectForKey:@"timeout"] intValue];
		[dataHandler setSCPDelegate:self];
		//[dataHandler setCallingAET:[params objectForKey:@"callingAET"]];
		if (debugLevel)
			NSLog(@"init new Store SCP: %@", [params description]);
	}
	return self;
}

- (void)dealloc{
	[folder release];
	[calledAET release];
	[callingAET release];
	[socket release];
	[socketHandle release];
	[dataHandler release];
	[super dealloc];
}
	
	
- (void)run{
	NSAutoreleasePool *subPool = nil;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *objects = nil;
	NSArray *keys = nil;
	NS_DURING

		objects= [NSArray arrayWithObjects:dataHandler, self, [NSNumber numberWithInt:debugLevel], folder, calledAET, socketHandle, [NSNumber numberWithInt:timeout], nil];
		keys =	[NSArray arrayWithObjects:@"receivedDataHandler", @"delegate", @"debugLevel", @"folder", @"calledAET",  @"socketHandle", @"timeout",  nil];

		NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		association = [[DCMAssociationResponder associationResponderWithParameters:params] retain];
		
		
		while (association){
			subPool = [[NSAutoreleasePool alloc] init];		
			[self receiveOneSOPInstance];
			[subPool release];
			subPool = nil;
			if ([(DCMCStoreReceivedPDUHandler *)dataHandler commandType] == 0x0020) {
				NSLog(@"Release Association after find complete");
				[association waitForCommandPDataPDUs];
				break;
			}

		}
	NS_HANDLER
		if (subPool)
			[subPool release];
		NSLog(@"error running storeSCP: %@", [localException name]);
	NS_ENDHANDLER
	//exit thread so we can release the socket and ourself	
	[pool release];
	//NSLog(@"exit storeSCP");
	//[NSThread exit];		Antoine - The problem with this: it will bypass all calls to [pool release]....
}

- (void)newDataHandler{
	dataHandler = [[DCMCStoreReceivedPDUHandler cStoreDataHanderWithDestinationFolder:folder debugLevel:debugLevel] retain];
}

- (void)receiveOneSOPInstance{
	[dataHandler setIsDone:NO];
	[association waitForPDataPDUsUntilHandlerReportsDone];
	unsigned char contextID = [dataHandler presentationContextID];
	DCMCommandMessage *message = [(DCMCStoreReceivedPDUHandler *)dataHandler responseMessage];
	//numberReceived++;
	if (debugLevel) {
		NSLog(@"received one SOP instance contextID:%d",contextID);
		NSLog(@"send response:\n%@", [message description]);
	}

	if ([message data]) 
		[association send:[message data]  asCommand:YES  presentationContext:contextID];
		
	[dataHandler reset];


}

- (void)sendCommand:(DCMCommandMessage *)command data:(DCMObject *)dataObject forAffectedSOPClassUID:(NSString *)sopClassUID{
	if (debugLevel)
		NSLog(@"send command: %@", [command description]);
	unsigned char usePresentationContextID = [association presentationContextIDForAbstractSyntax:sopClassUID];
	DCMTransferSyntax *transferSyntax = [association transferSyntaxForPresentationContextID:usePresentationContextID];
	if (association){
		[association send:[command data]  asCommand:YES  presentationContext:usePresentationContextID];
		//if (debugLevel)
		//			NSLog(@"send dataset:%@", [dcmObject description]);
		[association send:[dataObject writeDatasetWithTransferSyntax:transferSyntax quality:DCMLosslessQuality] asCommand:NO presentationContext:usePresentationContextID];
	}
		
	
}

- (void)associationReleased{
	//[association releaseAssociation];
	NSLog(@"release storeSCP association");
	[association release];
	association = nil;
}




@end
