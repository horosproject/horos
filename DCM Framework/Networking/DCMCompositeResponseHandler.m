//
//  DCMCompositeResponseHandler.m
//  OsiriX
//
//  Created by Lance Pysher on 12/15/04.

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

#import "DCMCompositeResponseHandler.h"
#import "DCM.h"
#import "DCMPresentationDataValue.h"
#import "DCMPDataPDU.h"
#import "DCMAssociation.h"


@implementation DCMCompositeResponseHandler

- (id)initWithDebugLevel:(int)debug{
	if (self = [super initWithDebugLevel:debug]){
		success = NO;
		allowData = NO;
		status = 0;
		commandReceived = [[NSMutableData data] retain];
		dataReceived = [[NSMutableData data] retain];
		date = [[NSDate date] retain];
	}
	return self;
}

- (DCMObject *)objectFromCommandOrData:(NSData *)data withTransferSyntax:(DCMTransferSyntax *)syntax{
	DCMObject *dcmObject = [[[DCMObject alloc] initWithData:data transferSyntax:syntax] autorelease];
	//if (debugLevel)
	//	NSLog(@"Handler data:%@", [dcmObject description]);
	return dcmObject;
}

- (void)sendPDataIndication:(DCMPDataPDU *)pdu   association:(DCMAssociation *)association{
	//NSLog(@"sendPDataIndication pdvList: count: %d", [[pdu pdvList] count]);	
	NSEnumerator *enumerator = [[pdu pdvList] objectEnumerator];
	DCMPresentationDataValue *pdv;
	while (pdv = [enumerator nextObject]){
		if ([pdv isCommand]){
			[commandReceived appendData:[pdv value]];
			if ([pdv isLastFragment]){
				DCMObject *dcmObject = [self objectFromCommandOrData:commandReceived withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];
				[self evaluateStatusAndSetSuccess:dcmObject];
				//NSLog(@"sent evaluateStatusAndSetSuccess");
			}
		}
		else if(allowData){	
			[dataReceived appendData:[pdv value]];
			if ([pdv isLastFragment]){
				DCMObject *dcmObject = [self objectFromCommandOrData:dataReceived withTransferSyntax:[association  transferSyntaxForPresentationContextID:[pdv presentationContextID]]];
				[self makeUseOfDataSet:dcmObject];
				// need to release the old dataReceived and start fresh.
				[dataReceived release];
				dataReceived = [[NSMutableData data] retain];
			}
		}
		else
			NSLog(@"Unexpected data fragment in response PDU");
	}
	//NSLog(@" End sendPDataIndication pdvList: count: %d", [[pdu pdvList] count]);	
}

- (void) makeUseOfDataSet:(DCMObject *)object{
}


- (BOOL)wasSuccessful{
	return success;
}

- (int)status{
	return status;
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object{

}

- (NSString *)calledAET{
	return calledAET;
}

- (void)setCalledAET:(NSString *)aet{
	[calledAET release];
	calledAET = [aet retain];
}

- (void)dealloc{
	//NSLog(@"commandReceived count: %d", [commandReceived retainCount]);
	//NSLog(@"dataReceived  count: %d", [dataReceived retainCount]);
	[commandReceived release];
	[dataReceived  release];
	[calledAET release];
	[date release];
	[super dealloc];
}

@end
