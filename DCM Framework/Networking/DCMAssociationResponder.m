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


/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMAssociationResponder.h"
//#import <OmniNetworking/OmniNetworking.h>
#import "DCMReleasePDU.h"
#import "DCMRequestPDU.h"
#import "DCMAbortPDU.h"
#import "DCMRejectPDU.h"
#import "DCMAcceptPDU.h"
#import "DCMPresentationDataValue.h"
#import "DCMPDataPDU.h"
#import "DCM.h"
#import "DCMPresentationContext.h"
#import "DCMReceivedDataHandler.h"
#import "DCMAbstractSyntaxUID.h"
#import "DCMSocket.h"

static int defaultMaximumLengthReceived = 16384;
//static int defaultMaximumLengthReceived = 8192;
static int defaultReceiveBufferSize = 8192;
//static int defaultReceiveBufferSize = 65536;
//static int defaultSendBufferSize = 0;
static int defaultTimeout = 5000; // in milliseconds

static BOOL AETitleMustBeIdentical = NO; 

@implementation DCMAssociationResponder

+ (id)associationResponderWithParameters:(NSDictionary *)params{
	return [[[DCMAssociationResponder alloc] initWithParameters:params] autorelease];
}
- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSException *exception = nil;
		if (DCMDEBUG)
			NSLog(@"New Association");
		NS_DURING
			dataHandler = [[params objectForKey:@"receivedDataHandler"] retain]; 
			_delegate = [params objectForKey:@"delegate"];
			debugLevel = 0;
			if ([params objectForKey:@"debugLevel"])
				debugLevel = [[params objectForKey:@"debugLevel"] intValue];	
			//debugLevel = 1;
			calledAET = [[params objectForKey:@"calledAET"] retain];	
			timeout = defaultTimeout;
			if ([params objectForKey:@"timeout"])
				timeout = [[params objectForKey:@"timeout"] intValue];
			maximumLengthReceived =	defaultMaximumLengthReceived;
			if ([params objectForKey:@"ourMaximumLengthReceived"])
				maximumLengthReceived = [[params objectForKey:@"ourMaximumLengthReceived"] intValue];
			
			receivedBufferSize = defaultReceiveBufferSize;
			if ([params objectForKey:@"receivedBufferSize"]){
				receivedBufferSize = [[params objectForKey:@"receivedBufferSize"] intValue];
				
			if([params objectForKey:@"AETitleMustBeIdentical"])
				AETitleMustBeIdentical = [[params objectForKey:@"AETitleMustBeIdentical"] boolValue];
			}

			socketHandle = [[params objectForKey:@"socketHandle"] retain];
							
			// AE-5    - TP Connect Indication
			// State 2 - Transport connection open (Awaiting A-ASSOCIATE-RQ PDU)
			
			NSMutableData *data = [NSMutableData data];
			NSData *socketData;

			while (YES) {
				socketData = [self readData];
				
				if ([socketData length] > 0)
					[data appendData:socketData];
				unsigned char pduType = 0;
				int pduLength = 0;
				if ([data length] >= 6) {
					
					[data getBytes:&pduType  range:NSMakeRange(0,1)];
					[data getBytes:&pduLength	range:NSMakeRange(2,4)];
					pduLength = NSSwapBigIntToHost(pduLength);
						//    - A-ASSOCIATE-AC PDU
						if ([data length] == pduLength + 6){
							//			- A-ASSOCIATE-RQ PDU
							// AE-6		- Stop ARTIM and send A-ASSOCIATE indication primitive
							if (pduType == 0x01) {

								DCMRequestPDU *pdu = [DCMRequestPDU requestWithData:[data subdataWithRange:NSMakeRange(0, pduLength + 6)]];
								if (debugLevel)
									NSLog(@"Request PDU:\n%@", [pdu description]);
								presentationContexts = [[pdu requestedPresentationContexts] retain];
								maximumLengthReceived = [pdu  maximumLengthReceived];
								NSLog(@"maximumLengthReceived %d", maximumLengthReceived);
								callingAET = [[[pdu callingAET] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
								
								NSLog( @"calledAET: %@ / calledAET: %@", calledAET, [[pdu calledAET] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
								
								//check our AET against request
								if (AETitleMustBeIdentical == NO || [calledAET isEqualToString:[[pdu calledAET] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]])
								{
									//	     - Implicit A-ASSOCIATE response primitive accept
									// AE-7      - Send A-ASSOCIATE-AC PDU
									
									presentationContexts = [self applySelectionPolicies:presentationContexts];
									NSArray *newContexts  = [self sanitizePresentationContextsForAcceptance:presentationContexts];
									//[presentationContexts release];
									//presentationContexts = [newContexts retain];
									
									NSMutableDictionary *newParams = [NSMutableDictionary dictionary];
									[newParams setObject:[[pdu calledAET] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"calledAET"];
									[newParams setObject:callingAET forKey:@"callingAET"];
									[dataHandler setCallingAET:callingAET];
									[newParams setObject:[DCMObject implementationClassUID] forKey:@"implementationClassUID"];
									[newParams setObject:[DCMObject implementationVersionName] forKey:@"implementationVersionName"];
									[newParams setObject:[NSNumber numberWithInt:maximumLengthReceived] forKey:@"ourMaximumLengthReceived"];
									[newParams setObject:newContexts forKey:@"presentationContexts"];	

									DCMAcceptPDU *accept= [DCMAcceptPDU acceptPDUWithParameters:newParams];
									
									if (debugLevel)
										NSLog(@"Accept PDU:\n%@", [accept description]);

									[self send:[accept pdu]];
									
								}
								//not our AET reject
								else{
									DCMRejectPDU *rejection = [DCMRejectPDU rejectWithSource:0x01 reason:0x01  result:0x07];
									//[socket writeData:[rejection pdu]];
									[self send:[rejection pdu]];
									// State 13					
									// At this point AA-6, AA-7, AA-2, AR-5 or AA-7 could be needed,
									// however let's just close the connection and be done with it
									// without worrying about whether the other end is doing the same
									// or has sent a PDU that really should trigger us to send an A-ABORT first
									// and we don't have a timer to stop
									exception = [NSException exceptionWithName:@"DCMException" reason:@"Association rejected: Wrong called AET" userInfo:[NSDictionary dictionaryWithObject:pdu  forKey:@"rejection"]];
									[exception raise];
								}
									
							}
							else if (pduType == 0x07) {		
								DCMAbortPDU *pdu = [DCMAbortPDU abortWithData:[data subdataWithRange:NSMakeRange(0, pduLength + 6)]];
								exception = [NSException exceptionWithName:@"DCMException" reason:@"Association Aborted:" userInfo:[NSDictionary dictionaryWithObject:pdu  forKey:@"AbortPDU"]];
								[exception raise];
							}
							else{
								DCMAbortPDU *pdu = [DCMAbortPDU abortWithSource:0x00  reason:0x00];
								//[socket writeData:[pdu pdu]];
								[self send:[pdu pdu]];
								[self waitForARTIMBeforeTransportConnectionClose];
								exception = [NSException exceptionWithName:@"DCMException" reason:@"Association Aborted:" userInfo:[NSDictionary dictionaryWithObject:pdu  forKey:@"AbortPDU"]];
								[exception raise];
							}

							break;
						}
								
					}
		
			}
		NS_HANDLER
			if (exception)
				NSLog(@"Exception while accepting association: %@", [exception reason]);
			else
				NSLog(@"Exception while accepting association: %@ reason: %@", [localException name], [localException reason]);
			self = nil;
		NS_ENDHANDLER
		[pool release];
	}
			// falls through only from State 6 - Data Transfer

	return self;

}

- (void)dealloc{
	[super dealloc];
}

- (NSArray *)applySelectionPolicies:(NSArray *)contexts{
	
	NSArray *abstractArray = [self applyAbstractSyntaxSelectionPolicy:contexts];
	NSArray *tsArray = [self applyTransferSyntaxSelectionPolicy:abstractArray];
	NSArray *explicitArray = [[self applyExplicitTransferSyntaxPreferencePolicy:tsArray] retain];
	[explicitArray autorelease];
	return explicitArray;
}

- (NSArray *)applyAbstractSyntaxSelectionPolicy:(NSArray *)contexts {
	for ( DCMPresentationContext *context in contexts ) {
		if ([DCMAbstractSyntaxUID isVerification:[context abstractSyntax]] || [DCMAbstractSyntaxUID isImageStorage:[context abstractSyntax]] || [DCMAbstractSyntaxUID isQuery:[context abstractSyntax]] )
			[context setReason:0x00];  // acceptance
		else
			[context setReason:0x03]; // abstract syntax not supported (provider rejection)	
	}
	
	return contexts;
}

- (NSArray *)applyTransferSyntaxSelectionPolicy:(NSArray *)contexts {
	for ( DCMPresentationContext *context in contexts ) {
		BOOL foundExplicitVRLittleEndian = NO;
		BOOL foundImplicitVRLittleEndian = NO;
		BOOL foundExplicitVRBigEndian = NO;
		BOOL foundLosslessJPEG = NO;
		BOOL foundLossyJPEGBaseline = NO;
		BOOL foundLossyJPEGExtended = NO;
		BOOL foundLosslessJPEG2000 = NO;
		BOOL foundLossyJPEG2000 = NO;
	//	BOOL foundRLE = NO;
		for ( DCMTransferSyntax *ts in contexts ){
		
			if ([ts isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]])
				foundExplicitVRLittleEndian = YES;
			else if ([ts isEqualToTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]])
				foundImplicitVRLittleEndian = YES;
			else if ([ts isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
				foundExplicitVRBigEndian = YES;
			else if ([ts isEqualToTransferSyntax:[DCMTransferSyntax JPEG2000LosslessTransferSyntax]])
				foundLosslessJPEG2000 = YES;
			else if ([ts isEqualToTransferSyntax:[DCMTransferSyntax JPEGLosslessTransferSyntax]])
				foundLosslessJPEG = YES;
			else if ([ts isEqualToTransferSyntax:[DCMTransferSyntax JPEG2000LossyTransferSyntax]])
				foundLossyJPEG2000 = YES;
			else if  ([ts isEqualToTransferSyntax:[DCMTransferSyntax JPEGBaselineTransferSyntax]])
				foundLossyJPEGBaseline = YES;
			else if ([ts isEqualToTransferSyntax:[DCMTransferSyntax JPEGExtendedTransferSyntax]] )			
				foundLossyJPEGExtended = YES;
		
		}	
		
		[context setTransferSyntaxes:[NSMutableArray array]];
		if (foundLossyJPEG2000)
			[context addTransferSyntax:[DCMTransferSyntax JPEG2000LossyTransferSyntax]];
		else if (foundLosslessJPEG2000)
			[context addTransferSyntax:[DCMTransferSyntax JPEG2000LosslessTransferSyntax]];
		else if (foundLossyJPEGBaseline)
			[context addTransferSyntax:[DCMTransferSyntax JPEGBaselineTransferSyntax]];
		else if (foundLossyJPEGExtended)
			[context addTransferSyntax:[DCMTransferSyntax JPEGExtendedTransferSyntax]];		
		else if (foundLosslessJPEG)
			[context addTransferSyntax:[DCMTransferSyntax JPEGLosslessTransferSyntax]];
		else if (foundExplicitVRLittleEndian)
			[context addTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]];
		else if (foundImplicitVRLittleEndian)
			[context addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];
		else if (foundExplicitVRBigEndian)
			[context addTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]];
		else
			[context setReason:0x04];
	}

	return contexts;
}
- (NSArray *)applyExplicitTransferSyntaxPreferencePolicy:(NSArray *)contexts{
	NSMutableSet *abstractSyntaxSet = [NSMutableSet set];
	for ( DCMPresentationContext *context in contexts ) {
		if ([[context transferSyntaxes] objectAtIndex:0] && [[[context transferSyntaxes] objectAtIndex:0] isExplicit])
			[abstractSyntaxSet addObject:[context abstractSyntax]];
	}
	
	for ( DCMPresentationContext *context in contexts ) {
		if ([[context transferSyntaxes] objectAtIndex:0] && ![[[context transferSyntaxes] objectAtIndex:0] isExplicit]  && [abstractSyntaxSet member:[context abstractSyntax]])
			[context setReason:0x02];
	}

	return contexts;
}

- (NSArray *)sanitizePresentationContextsForAcceptance:(NSArray *)contexts {
	NSMutableArray *newContexts = [NSMutableArray array];
	DCMPresentationContext *newContext;
	for ( DCMPresentationContext *presentationContext in contexts ) {
		newContext = [DCMPresentationContext contextWithID:[presentationContext contextID]]; 
		if ([[presentationContext transferSyntaxes] count] > 0) 
			[newContext addTransferSyntax:[[presentationContext transferSyntaxes] objectAtIndex:0]];
		else
			[newContext addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];

	[newContexts addObject:newContext];

	}
	return newContexts;
}


@end
