//
//  DCMVerificationSOPClassSCU.m
//  OsiriX
//
//  Created by Lance Pysher on 12/13/04.

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

#import "DCMVerificationSOPClassSCU.h"
#import "DCM.h"
#import "DCMPresentationContext.h"
#import "DCMAbstractSyntaxUID.h"
#import "DCMAssociation.h"
#import "DCMCEchoRequest.h"
#import "DCMEchoResponseHandler.h"


@implementation DCMVerificationSOPClassSCU

+ (id)verificationSCUWithParameters:(NSDictionary *)params{
	return [[[DCMVerificationSOPClassSCU alloc] initWithParameters:params] autorelease];
}

+ (BOOL) echoSCUWithParams:(NSDictionary *)params{
	DCMVerificationSOPClassSCU *echo = [DCMVerificationSOPClassSCU verificationSCUWithParameters:params];
	return [echo echo];
}


- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init] ){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(abortEcho:) name:@"DCMAbortEchoNotification" object:nil];
		debugLevel = 0;
		if ([params objectForKey:@"debugLevel"])
			debugLevel = [[params objectForKey:@"debugLevel"] intValue];
		NSMutableArray *contexts = [NSMutableArray array];
		NSMutableArray *syntaxes = [NSMutableArray array];
		[syntaxes addObject:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];
		DCMPresentationContext *context = [DCMPresentationContext contextWithID:0x01];		
		[context addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];
		[context addTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]];
		[context setAbstractSyntax:[DCMAbstractSyntaxUID verificationClassUID]];
		[contexts addObject:context];
		
		context = [DCMPresentationContext contextWithID:0x03];		
		[context addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];
		[context setAbstractSyntax:[DCMAbstractSyntaxUID verificationClassUID]];
		[contexts addObject:context];
		
		context = [DCMPresentationContext contextWithID:0x05];
		[context addTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]];
		[context setAbstractSyntax:[DCMAbstractSyntaxUID verificationClassUID]];
		[contexts addObject:context];
		
		
		
		
		NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
		[newParams setObject:contexts forKey:@"presentationContexts"];
		[newParams setObject:[NSNumber numberWithInt:debugLevel] forKey:@"debugLevel"];
		[newParams setObject:self  forKey:@"delegate"];
		 dataHandler = [[DCMEchoResponseHandler alloc] initWithDebugLevel:debugLevel];
		[newParams setObject:dataHandler forKey:@"receivedDataHandler"];
		if (debugLevel)
			NSLog(@"Create association for verification");
		association  = [[DCMAssociation associationInitiatorWithParameters:newParams] retain];
		if (debugLevel)
			NSLog(@"Association: %@", [association description]);
		//[association setReceivedDataHandler:nil];
		[pool release];
	}
	return self;
}

- (BOOL)echo{
	//BOOL success = NO;
	if (association && [association isConnected]) {
		if (debugLevel)
			NSLog(@"perform echo");
		unsigned char usePresentationContextID = [association presentationContextIDForAbstractSyntax:[DCMAbstractSyntaxUID verificationClassUID]];
		
		DCMCEchoRequest *echoRequest = [DCMCEchoRequest CEchoRequest];
		if (debugLevel)
			NSLog(@"Echo request:\n%@", [[echoRequest dcmObject] description]);
		//[association send:[echoRequest data];
		NS_DURING
			[association send:[echoRequest data]  asCommand:YES  presentationContext:usePresentationContextID];
			if (debugLevel)
				NSLog(@"waitForCommandPDataPDUs");
			[association waitForCommandPDataPDUs];
			[association releaseAssociation];
	
		NS_HANDLER
			NSLog(@"Exception with Echo:%@", [localException name]);
			return NO;
		NS_ENDHANDLER
		
		return [dataHandler success];
	}
	else{
		NSLog(@"No valid association");
		return NO;
	}
}

- (void)dealloc{

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[dataHandler release];
	[super dealloc];
}

- (void)abortEcho:(NSNotification *)note{
	[association terminate:self];
}

@end
