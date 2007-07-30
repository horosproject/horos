//
//  DCMAssociation.m
//  OsiriX
//
//  Created by Lance Pysher on 12/3/04.

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


/***************************************** Modifications *********************************************

Version 2.3
	20051221	LP	Modified send:asCommand:presentationContext: to get rid of NSAutoreleasePools

*****************************************************************************************************/

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMAssociation.h"
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






#import "DCMSocket.h"
#include <sys/select.h>
#include <sys/uio.h>
#include <unistd.h>

static int defaultMaximumLengthReceived = 0;
//static int defaultMaximumLengthReceived = 8192;
//static int defaultReceiveBufferSize = 65536;
static int defaultReceiveBufferSize = 8192;
static int defaultSendBufferSize = 0;
static int defaultTimeout = 5000; // in milliseconds


@implementation DCMAssociation


+ (int)defaultMaximumLengthReceived{
	return defaultMaximumLengthReceived;
}

+ (int) defaultReceiveBufferSize{
	return defaultReceiveBufferSize;
}

+ (int)defaultSendBufferSize{
	return defaultSendBufferSize;
}

+ (id)associationInitiatorWithParameters:(NSDictionary *)params{
	return [[[DCMAssociation alloc] initInitiatorWithParameters:params] autorelease];
}

+ (id)associationResponderWithParameters:(NSDictionary *)params{
	return [[[DCMAssociation alloc] initResponderWithParameters:params] autorelease];
}

+ (id)listenerOnPort:(int)port{
	return nil;
}

- (id)initResponderWithParameters:(NSDictionary *)params{			
	return nil;	
}
/**
	 * Opens a transport connection and initiates an association.
	 *
	 * The default Maximum PDU Size of the toolkit is used.
	 *
	 * The open association is left in state 6 - Data Transfer.
	 *
	 * @param	hostname			hostname or IP address (dotted quad) component of presentation address of the remote AE (them)
	 * @param	port				TCP port component of presentation address of the remote AE (them)
	 * @param	calledAET			the AE Title of the remote (their) end of the association
	 * @param	callingAET			the AE Title of the local (our) end of the association
	 * @param	implementationClassUID		the Implementation Class UID of the local (our) end of the association supplied as a User Information Sub-item
	 * @param	implementationVersionName	the Implementation Class UID of the local (our) end of the association supplied as a User Information Sub-item
	 * @param	ourMaximumLengthReceived	the maximum PDU length that we will offer to receive
	 * @param	socketReceiveBufferSize		the TCP socket receive buffer size to set (if possible), 0 means leave at the default
	 * @param	socketSendBufferSize		the TCP socket send buffer size to set (if possible), 0 means leave at the default
	 * @param	presentationContexts		a java.util.LinkedList of {@link PresentationContext PresentationContext} objects,
	 *						each of which contains an Abstract Syntax (SOP Class UID) and one or more Transfer Syntaxes
	 * @param	debugLevel			0 for no debugging, > 0 for increasingly verbose debugging
	 * @exception	IOException
	 * @exception	DicomNetworkException		thrown for A-ASSOCIATE-RJ, A-ABORT and A-P-ABORT indications
	 */
	
- (id)initInitiatorWithParameters:(NSDictionary *)params{
	if (self = [super init]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSException *exception = nil;
		NS_DURING
			terminate = NO;
			socketHandle = 0L;
			ARTIM = nil;
			dataHandler = [[params objectForKey:@"receivedDataHandler"] retain];
			//socketHandle =  [[params objectForKey:@"socketHandle"] retain];
			_delegate = [params objectForKey:@"delegate"];
			debugLevel = 0;
			if ([params objectForKey:@"debugLevel"])
				debugLevel = [[params objectForKey:@"debugLevel"] intValue];
			//debugLevel = 1;
			hostname = [[params objectForKey:@"hostname"] retain];
			port = [[params objectForKey:@"port"] intValue];
			callingAET = [[params objectForKey:@"callingAET"] retain];
			calledAET = [[params objectForKey:@"calledAET"] retain];
			presentationContexts = [[params objectForKey:@"presentationContexts"] retain];	
			timeout = defaultTimeout;
			if ([params objectForKey:@"timeout"])
				timeout = [[params objectForKey:@"timeout"] intValue];
			if (debugLevel)
				NSLog(@"timeout: %d seconds", timeout/1000);
			maximumLengthReceived =	defaultMaximumLengthReceived;
			if ([params objectForKey:@"ourMaximumLengthReceived"])
				maximumLengthReceived = [[params objectForKey:@"ourMaximumLengthReceived"] intValue];
			if (debugLevel)
				NSLog(@"connect");
			

			NSLog(@"port: %d  hostname: %@", port, hostname);
			if ([params objectForKey:@"netService"])
				socketHandle = [[NSFileHandle alloc] initWithNetService:[params objectForKey:@"netService"]];
			else
				socketHandle = [[NSFileHandle alloc] initWithHostname:hostname port:(unsigned short)port];

			if (!socketHandle) {
				exception = [NSException exceptionWithName:@"DCMException" reason:@"Association failed to connect:" userInfo:nil];
				[exception raise];
			}
				


			receivedBufferSize = defaultReceiveBufferSize;
			if ([params objectForKey:@"receivedBufferSize"]){
				receivedBufferSize = [[params objectForKey:@"receivedBufferSize"] intValue];
				//[socket setReadBufferSize:receivedBufferSize];
			}
				
			NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
			[parameters  setObject:presentationContexts forKey:@"presentationContexts"];
			[parameters  setObject:callingAET forKey:@"callingAET"];
			[parameters  setObject:calledAET forKey:@"calledAET"];
			if ([params objectForKey:@"implementationClassUID"])
				[parameters  setObject:[params objectForKey:@"implementationClassUID"] forKey:@"implementationClassUID"];
			else
				[parameters  setObject:[DCMObject implementationClassUID] forKey:@"implementationClassUID"];
			if ([params objectForKey:@"implementationVersionName"] )
				[parameters  setObject:[params objectForKey:@"implementationVersionName"] forKey:@"implementationVersionName"];
			else
				[parameters  setObject:[DCMObject implementationVersionName] forKey:@"implementationVersionName"];
			[parameters  setObject:[NSNumber numberWithInt:maximumLengthReceived] forKey:@"ourMaximumLengthReceived"];
			DCMRequestPDU *requestPDU = [DCMRequestPDU requestWithParameters:parameters];
			if (debugLevel)
				NSLog(@"Association Parameters: %@", [params description]);
			// State 1 - Idle
			// AE-1    - Issue TP Connect Primitive

			if (debugLevel)
				NSLog(@"Connecting");
			// State 4 - Awaiting TP open to complete
			//         - Transport connection confirmed 
			// AE-2     - Send A-ASSOCIATE-RQ PDU
			[self send:[requestPDU pdu]];
			// State 5  - Awaiting A-ASSOCIATE-AC or -RJ PDU
			NSMutableData *data = [NSMutableData data];
			NSData *socketData;
			if (debugLevel)
				NSLog(@"Wrote Data: %@", [requestPDU description]);
			while (YES) {
				socketData = [self readData];
				if (debugLevel)
					NSLog(@"reading Data length:%d", [socketData length]);
				if ([socketData length] > 0)
					[data appendData:socketData];
				unsigned char pduType = 0;
				int pduLength = 0;
				if ([data length] >= 6) {
					if (debugLevel)
						NSLog(@"returningPDU: %@", [[[NSString alloc] initWithData:data  encoding:NSASCIIStringEncoding] autorelease]);
					[data getBytes:&pduType  range:NSMakeRange(0,1)];
					[data getBytes:&pduLength	range:NSMakeRange(2,4)];
					pduLength = NSSwapBigIntToHost(pduLength);
					if (debugLevel > 1)
						NSLog(@"pdu type:%d  length: %d", pduType, pduLength);
						//           - A-ASSOCIATE-AC PDU
						if ([data length] == pduLength + 6){
							if (pduType == 0x02) {
								if (debugLevel)
									NSLog(@"Accept PDU");
								DCMAcceptPDU *pdu = [DCMAcceptPDU acceptPDUWithData:[data subdataWithRange:NSMakeRange(0, pduLength + 6)]];
								
								NSArray *newPresentationContexts = 
								[pdu acceptedPresentationContextsWithAbstractSyntaxIncludedFromRequest: presentationContexts];
								[presentationContexts release];
								presentationContexts = [newPresentationContexts retain];
								if (maximumLengthReceived == 0  || [pdu maximumLengthReceived] <  maximumLengthReceived )
									maximumLengthReceived = [pdu maximumLengthReceived];
								if (debugLevel) {
									NSLog(@"Accepted presentation contexts: %@", [newPresentationContexts description]);
									NSLog(@"Max PDU size for sending: %d", maximumLengthReceived);
								}
								break;
							}
							else if (pduType == 0x03) {	
								DCMRejectPDU *pdu = [DCMRejectPDU rejectWithData:[data subdataWithRange:NSMakeRange(0, pduLength + 6)]];
								exception = [NSException exceptionWithName:@"DCMException" reason:@"Association Rejected:" userInfo:[NSDictionary dictionaryWithObject:pdu  forKey:@"RejectPDU"]];
								[exception raise];
							}
							else if (pduType == 0x07) {		
								DCMAbortPDU *pdu = [DCMAbortPDU abortWithData:[data subdataWithRange:NSMakeRange(0, pduLength + 6)]];
								exception = [NSException exceptionWithName:@"DCMException" reason:@"Association Aborted:" userInfo:[NSDictionary dictionaryWithObject:pdu  forKey:@"AbortPDU"]];
								[exception raise];
							}
							else{
								DCMAbortPDU *pdu = [DCMAbortPDU abortWithSource:0x02  reason:0x02];
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
				NSLog(@"Exception while creating association: %@", [exception reason]);
			//self = nil;
			NSLog(@"error: %@", [localException reason]);
			[self release];
			self = nil;
		NS_ENDHANDLER
		[pool release];
	}
			// falls through only from State 6 - Data Transfer
	return self;

}

- (void)dealloc{
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[hostname release];
	[callingAET release];
	[calledAET release];
	[presentationContexts release];
	[ARTIM invalidate];
	[ARTIM release];
	[dataHandler release];
	[socketHandle release];
	socketHandle = 0L;
	[_dataLock release];
	[_incomingData release];
	//[timeStamp release];
	//NSLog(@"dealloc Association");
	[super dealloc];
}

- (void)terminate:(id)sender{
	NSLog(@"Terminate association");
	terminate = YES;
}

- (void)releaseAssociation{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	DCMReleasePDU *releasePDU = [DCMReleasePDU releasePDUWithType:0x05];
	[self send:[releasePDU pdu]]; // AR-1      - Send A-RELEASE-RQ PDU
	NSMutableData *response = [NSMutableData data];
	BOOL isLoop = YES;
	while (isLoop){
		NSAutoreleasePool *subPool;
		NSData *data = nil;
		subPool = [[NSAutoreleasePool alloc] init];
		NS_DURING 
			
			data = [socketHandle availableData];

			if (!data  || [data length] == 0)
				isLoop = NO;
			else {
				[response appendData:data];
				unsigned char pduType;
				unsigned int length;			
				[response getBytes:&pduType range:NSMakeRange(0,1)];
				[response getBytes:&length range:NSMakeRange(2,4)];
				length = NSSwapBigIntToHost(length);
				if (pduType == 0x06) {	//           - A-RELEASE-RP PDU
					isLoop = NO;

					// AR-3      - Issue A-RELEASE confirmation primitive and close transport connection
					// fall through to normal return
					// State 1   - Idle

				}
				else if (pduType == 0x05) {						//           - A-RELEASE-RQ PDU ... release request collision
					releasePDU = [DCMReleasePDU releasePDUWithType:0x06];
					[self send:[releasePDU pdu]];
					// State 11  -
					isLoop = NO;

					// AR-3      - Issue A-RELEASE confirmation primitive and close transport connection
					// fall through to normal return
				}
				else if (pduType == 0x07) {
					// AA-3      - Close transport connection and indicate abort
					isLoop = NO;
				}
				else{
					DCMAbortPDU *abortPDU = [DCMAbortPDU abortWithSource:0x02  reason:0x02];
					[self send:[abortPDU pdu]];
					isLoop = NO;
				}
				[NSThread  sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
			}
		
		NS_HANDLER 
			// Probably disconnected
			NSLog(@"Exception raised while releasing association: %@", localException);
			isLoop = NO;
		 
		NS_ENDHANDLER;
		[subPool release];
		NSLog(@"release association");
	}
	
	[self close];
	[pool release];
}

- (void)abort{
	NSLog(@"ABORT");
	DCMAbortPDU *abortPDU = [DCMAbortPDU abortWithSource:0x01  reason:0x00];
	[self send:[abortPDU pdu]];
	[self close];
}

/**
	 * Send a command and/or data in a single PDU, each PDV with the last fragment flag set.
	 *
	 * @param	presentationContextID	included in the header of each PDU
	 * @param	command			the command PDV payload, or null if none
	 * @param	data			the data PDV payload, or null if none
	 * @exception	DicomNetworkException
	 */
	 
- (void)sendPresentationContextID:(unsigned char)contextID  command:(NSData *)command  data:(NSData *)data{
	// let's build a single command PDV and a single data PDV (if needed) in a single PDU
	NSMutableArray *listOfPDVs = [NSMutableArray array];
	[listOfPDVs count];
	if (command){
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject:[NSNumber numberWithChar:contextID]  forKey:@"contextID"];
		[params setObject:command	forKey:@"value"];
		[params setObject:[NSNumber numberWithBool:YES]	forKey:@"isCommand"];
		[params setObject:[NSNumber numberWithBool:YES]	forKey:@"isLastFragment"];
		[listOfPDVs addObject:[DCMPresentationDataValue pdvWithParameters:params]];
	}
	if (data) {
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject:[NSNumber numberWithChar:contextID]  forKey:@"contextID"];
		[params setObject:data	forKey:@"value"];
		[params setObject:[NSNumber numberWithBool:YES]	forKey:@"isCommand"];
		[params setObject:[NSNumber numberWithBool:NO]	forKey:@"isLastFragment"];
		[listOfPDVs addObject:[DCMPresentationDataValue pdvWithParameters:params]];
	}
	DCMPDataPDU *pdu = [DCMPDataPDU pDataPDUWithPDVs:listOfPDVs];
	[self send:[pdu pdu]];
	[self associationAborted];
	
}

/**
	 * Implement the ARTIM, in order to not close the transport connection immediately after
	 * sending an a A-RELEASE-RP or A-ABORT PDU.
	 *
	 * (E.g., ADW 3.1 reports that a preceding send failed if transport connection is immediately closed).
	 *
	 * The method is synchronized only in order to allow access to wait().
	 *
	 */
	 
- (void)waitForARTIMBeforeTransportConnectionClose{
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timeout/1000]];
}


- (NSData *)readData{
	NSData *socketData = nil;
	
	NS_DURING
				
		//if (debugLevel)
		//	NSLog(@"Getting data");
		int fd = [socketHandle fileDescriptor] ;
		fd_set readfds, writefds, exceptfds;
		FD_ZERO(&writefds);
		FD_ZERO(&exceptfds);
		FD_SET(fd, &readfds);
		
		struct timeval timeoutS;
		timeoutS.tv_sec = 0;
		timeoutS.tv_usec = 1;
		if (select(fd  + 1 , &readfds, &writefds, &exceptfds, &timeoutS))
		{
			if( FD_ISSET(fd, &readfds))
			{
				socketData = [socketHandle availableData];
				
				[self invalidateARTIM:nil];
			}
			else
			{
				socketData = nil;
			}
		}
		else
		{
			socketData = nil;
		}

		
	NS_HANDLER
		if (debugLevel)
			NSLog(@"Exception: %@ reason%@", [localException name], [localException reason]);
		//[self terminate:nil];
		socketData = nil;
		
	NS_ENDHANDLER

	if ([socketData length] == 0)
	{
		if (ARTIM == 0L) [self startARTIM:nil];
	}
	else [self invalidateARTIM:nil];
	
	 return socketData;
	

}


/**
	 * Continue to transfer data (remain in State 6) until the specified number of PDUs have been
	 * received or the specified conditions are satisfied.
	 *
	 * The registered receivedDataHandler is sent a PDataIndication.
	 *
	 * @param	count				the number of PDUs to be transferred, or -1 if no limit (stop only when conditions satisfied)
	 * @param	stopAfterLastFragmentOfCommand	stop after the last fragment of a command has been received
	 * @param	stopAfterLastFragmentOfData	stop after the last fragment of data has been received
	 * @param	stopAfterHandlerReportsDone	stop after data handler reports that it is done
	 * @exception	DicomNetworkException		A-ABORT or A-P-ABORT indication
	 * @exception	AReleaseException		A-RELEASE indication; transport connection is closed
	 */

- (void)waitForPDataPDUs:(NSDictionary *)params{
	int count = 0;
	BOOL stopAfterLastFragmentOfCommand =  YES;
	BOOL stopAfterLastFragmentOfData = YES;
	BOOL stopAfterHandlerReportsDone = YES;
	NSAutoreleasePool *pool = nil;
	NSException *exception = nil;
	if ([params objectForKey:@"count"])
		count = [[params objectForKey:@"count"] intValue];
	if ([params objectForKey:@"stopAfterLastFragmentOfCommand"])
		stopAfterLastFragmentOfCommand = [[params objectForKey:@"stopAfterLastFragmentOfCommand"] boolValue]; 
	if ([params objectForKey:@"stopAfterLastFragmentOfData"])
		stopAfterLastFragmentOfData = [[params objectForKey:@"stopAfterLastFragmentOfData"] boolValue]; 
	if ([params objectForKey:@"stopAfterHandlerReportsDone"])
		stopAfterHandlerReportsDone = [[params objectForKey:@"stopAfterHandlerReportsDone"] boolValue]; 
	NSMutableData *data = [[NSMutableData data] retain];
	if (debugLevel)
		NSLog(@"waitForPDataPDUs: %@", [params description]);
		
	
	NS_DURING
		while ((count == -1 || count-- > 0) && !terminate) {	
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];	// Antoine <- We have to add this line to allow the NSTimer to work!
			// -1 is flag to loop forever
			pool = [[NSAutoreleasePool alloc] init];
			NSData *socketData;
			if (socketData = [self readData])  {

				if ([socketData length] > 0) {
					[data appendData:socketData];
					if (debugLevel)
						NSLog(@"Data length: %d", [data length]);
				}
			}
			//else
			//	NSLog(@"empty socketData");
			if ([data length] > 6) {
				unsigned char pduType;
				[data getBytes:&pduType range:NSMakeRange(0,1)];
				int pduLength;
				[data getBytes:&pduLength range:NSMakeRange(2,4)];
				pduLength = NSSwapBigIntToHost(pduLength);
				if (debugLevel)
					NSLog(@"pduLength:%d  type:0x%x", pduLength, pduType);
				if (pduLength + 6  <= [data length]){
					if (pduType == 0x04) {	
												//           - P-DATA PDU
						
						NSData *subdata = [data subdataWithRange:NSMakeRange(0, pduLength + 6)];
						DCMPDataPDU *pData = [DCMPDataPDU pDataPDUWithData:subdata];
						[dataHandler sendPDataIndication:pData   association:self];	
						
						// DT-2      - send P-DATA indication primitive
						// State 6   - Data Transfer
						if ((stopAfterLastFragmentOfCommand && [pData containsLastCommandFragment])
							 || (stopAfterLastFragmentOfData && [pData containsLastDataFragment])
							 || (stopAfterHandlerReportsDone && [dataHandler isDone])
							 ) {
							 if (debugLevel)
								NSLog(@"Finished getting PDU data");
							 break;
						}
						else{
							if (debugLevel)
							NSLog(@"more data waiting");
						}
					}
					else if (pduType == 0x05) {						//           - A-RELEASE-RQ PDU
							// AR-2      - Issue A-RELEASE indication primitive
							// State 8   - Awaiting local A-RELEASE response primitive
							//           - Assume local A-RELEASE response primitive
							DCMReleasePDU *rPDU = [DCMReleasePDU releasePDUWithType:0x06]; // AR-4      - send a A-RELEASE-RP (and start ARTIM)
							[self send:[rPDU pdu]];
							[self waitForARTIMBeforeTransportConnectionClose];
							exception = [NSException exceptionWithName:@"DCMException" reason:@"A-RELEASE indication while waiting for P-DATA" userInfo:nil];
							//NSLog(@"release PDU");
							//[self associationReleased];
							[exception raise];
					
					}
					else if (pduType == 0x07) {		
						DCMAbortPDU *aPDU = [DCMAbortPDU abortWithData:[(NSData *)data subdataWithRange:NSMakeRange(0, pduLength + 6)]];
						exception = [NSException exceptionWithName:@"DCMException" reason: @"A-ABORT indication" userInfo:[NSDictionary dictionaryWithObject:aPDU forKey:@"pdu"]];
							[exception raise];
					}
					else {	
						DCMAbortPDU *aPDU = [DCMAbortPDU abortWithSource:0x02  reason:0x02];
						[self send:[aPDU pdu]];
						[self waitForARTIMBeforeTransportConnectionClose];
						exception = [NSException exceptionWithName:@"DCMException" reason: @"A-ABORT indication" userInfo:nil];
					//	[self associationAborted];
					NSLog(@"Abort: Unknown PDU");
						[exception raise];
					}
					//get rid of last PDU
					//NSLog(@"data retain count: %d", [data retainCount]);
					NSMutableData *newData = [[data subdataWithRange:NSMakeRange(pduLength + 6, [data length] - (pduLength + 6))] mutableCopy];
					[data release];
					data = newData;
					if (count >= 0)
						count++;
				}
				
			}
			
			[pool release];
			pool = nil;
			
		}
		//NSLog(@"exited waitForPData");
	NS_HANDLER
		if (exception)
			NSLog(@"Exception while waiting for PDUs: %@", [exception reason]);
		else
			NSLog(@"Exception: %@ reason%@", [localException name], [localException reason]);
		//if (pool)
		//	[pool release];
		[self associationReleased];
	NS_ENDHANDLER
		if (pool)
			[pool release];
		[data release];
		
	if (terminate) {
		NSLog(@"terminate");
		[self associationAborted];
	}
	// normal return is after all requested P-DATA PDUs have been received, still in State 6
		//NSLog(@"end waitForPData");
	
	
}

/**
	 * Continue to transfer data (remain in State 6) until one PDU has been
	 * received.
	 *
	 * The registered receivedDataHandler is sent a PDataIndication.
	 *
	 * @exception	DicomNetworkException		A-ABORT or A-P-ABORT indication
	 * @exception	AReleaseException		A-RELEASE indication; transport connection is closed
	 */

- (void) waitForOnePDataPDU{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[NSNumber numberWithInt:1]  forKey:@"count"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterLastFragmentOfCommand"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterLastFragmentOfData"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterHandlerReportsDone"];
	[self waitForPDataPDUs:params];
}

	/**
	 * Continue to transfer data (remain in State 6) until the last fragment of a command has been received.
	 *
	 * The registered receivedDataHandler is sent a PDataIndication.
	 *
	 * @exception	DicomNetworkException		A-ABORT or A-P-ABORT indication
	 * @exception	AReleaseException		A-RELEASE indication; transport connection is closed
	 */
- (void) waitForCommandPDataPDUs{
	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[NSNumber numberWithInt:-1]  forKey:@"count"];
	[params setObject:[NSNumber numberWithBool:YES] forKey:@"stopAfterLastFragmentOfCommand"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterLastFragmentOfData"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterHandlerReportsDone"];
	[self waitForPDataPDUs:params];
}

/**
	 * Continue to transfer data (remain in State 6) until the last fragment of data has been received.
	 *
	 * The registered receivedDataHandler is sent a PDataIndication.
	 *
	 * @exception	DicomNetworkException		A-ABORT or A-P-ABORT indication
	 * @exception	AReleaseException		A-RELEASE indication; transport connection is closed
	 */
- (void) waitForDataPDataPDUs{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[NSNumber numberWithInt:-1]  forKey:@"count"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterLastFragmentOfCommand"];
	[params setObject:[NSNumber numberWithBool:YES] forKey:@"stopAfterLastFragmentOfData"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterHandlerReportsDone"];
	[self waitForPDataPDUs:params];
	}


/**
	 * Continue to transfer data (remain in State 6) until the data handler reports that it is done.
	 *
	 * The registered receivedDataHandler is sent a PDataIndication.
	 *
	 * @exception	DicomNetworkException		A-ABORT or A-P-ABORT indication
	 * @exception	AReleaseException		A-RELEASE indication; transport connection is closed
	 */
- (void) waitForPDataPDUsUntilHandlerReportsDone{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[NSNumber numberWithInt:-1]  forKey:@"count"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterLastFragmentOfCommand"];
	[params setObject:[NSNumber numberWithBool:NO] forKey:@"stopAfterLastFragmentOfData"];
	[params setObject:[NSNumber numberWithBool:YES] forKey:@"stopAfterHandlerReportsDone"];
	//NSLog(@"waitForPDataPDUsUntilHandlerReportsDone");
	[self waitForPDataPDUs:params];
	}
	
- (unsigned char)presentationContextIDForAbstractSyntax:(NSString *)abstractSytaxUID{
	unsigned char contextID = 0;
	NSEnumerator *enumerator = [presentationContexts objectEnumerator];
	DCMPresentationContext *context;
	NSArray *syntaxes = [NSArray arrayWithObjects:
		[DCMTransferSyntax JPEG2000LossyTransferSyntax], 
		[DCMTransferSyntax JPEG2000LosslessTransferSyntax], 
		[DCMTransferSyntax JPEGExtendedTransferSyntax],
		[DCMTransferSyntax JPEGBaselineTransferSyntax], 
		[DCMTransferSyntax JPEGLosslessTransferSyntax],
		[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax],
		[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax],
		[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax],
		nil];
	while (context = [enumerator nextObject]){
		//NSLog(@"context: %@", [context description]);
		if ([[context abstractSyntax] isEqualToString:abstractSytaxUID]) {
			DCMTransferSyntax *ts = [[context transferSyntaxes] objectAtIndex:0];
			NSEnumerator *enumerator2 = [syntaxes objectEnumerator];
			DCMTransferSyntax *syntax;
			while (syntax = [enumerator2 nextObject]) {
				if ([syntax isEqualToTransferSyntax:ts] && contextID == 0)
				//if ([syntax isEqualToTransferSyntax:ts] && contextID <= 1)
					contextID = [context contextID];
			}
		}						
	}
	//should we accept something else?
	if (contextID == 0) {
		enumerator = [presentationContexts objectEnumerator];
		while (context = [enumerator nextObject]){
			if ([[context abstractSyntax] isEqualToString:abstractSytaxUID]) 
				contextID = [context contextID];
		}
	}
		
	return contextID;
}

- (unsigned char)presentationContextIDForAbstractSyntax:(NSString *)abstractSytaxUID transferSyntax:(DCMTransferSyntax *)transferSyntax{

	unsigned char contextID = 0;
	NSEnumerator *enumerator = [presentationContexts objectEnumerator];
	DCMPresentationContext *context;
	while (context = [enumerator nextObject]){
		if ([[context abstractSyntax] isEqualToString:abstractSytaxUID] 
		&& [transferSyntax isEqualToTransferSyntax:[[context transferSyntaxes] objectAtIndex:0]])
			contextID = [context contextID];
	}
	
	return contextID;
}

- (DCMTransferSyntax *)transferSyntaxForPresentationContextID:(unsigned char)contextID{
	NSEnumerator *enumerator = [presentationContexts objectEnumerator];
	DCMPresentationContext *context;
	while (context = [enumerator nextObject]){
		if ([context contextID] == contextID)
			return [[context transferSyntaxes] objectAtIndex:0];
	}
	return nil;
}

- (NSString *)callingAET{
	return callingAET;
}

- (NSString *)calledAET{
	return calledAET;
}

- (void)send:(NSData *)data{
	//NSLog(@"send data length: %d bufferSize; %d", [data length], receivedBufferSize);
	if( socketHandle == 0L)
	{
		NSLog(@"already released !!??");
		return;
	}
	NS_DURING
		[socketHandle writeData:data];
	NS_HANDLER
		NSLog(@"Error Sending: %@", [localException reason]);
	NS_ENDHANDLER

}


- (void)send:(NSData *)data  asCommand:(BOOL)isCommand  presentationContext:(unsigned char)contextID{
	//if ([data length]  + 6 < receivedBufferSize) {
	if ([data length]  + 6 < maximumLengthReceived || maximumLengthReceived == 0) {
	
		DCMPresentationDataValue *pdv = [[DCMPresentationDataValue alloc] initWithBytes:(unsigned char *)[data bytes] 
										length:[data length] 
										isCommand:(BOOL)isCommand 
										isLastFragment:YES 
										contextID:(unsigned char)contextID];
										
		NSMutableArray *listOfPDVs = [NSMutableArray arrayWithObject:pdv];
		DCMPDataPDU *pdu = [DCMPDataPDU pDataPDUWithPDVs:listOfPDVs];
		[self send:[pdu pdu]];	
		[pdv release];
	}
	//we need several PDUs for the data
	else {
	//subtract 12 for PDU and PDV headers
		int bufferSize = (maximumLengthReceived - 12);
		int numberOfFragments = [data length] / bufferSize;
		int remainder = [data length] % bufferSize;
		int i;
		for (i = 0; i < numberOfFragments; i++){
		//	NSAutoreleasePool *pool= [[NSAutoreleasePool alloc] init];
			int position = i * bufferSize;
			//NSData *subdata = [data subdataWithRange:NSMakeRange(position, bufferSize)];
			unsigned char *buffer = (unsigned char *)[data bytes] + position;
			DCMPresentationDataValue *pdv = [[DCMPresentationDataValue alloc] initWithBytes:buffer
										length:bufferSize
										isCommand:(BOOL)isCommand 
										isLastFragment:NO 
										contextID:(unsigned char)contextID];
			NSMutableArray *listOfPDVs = [NSMutableArray arrayWithObject:pdv];
			DCMPDataPDU *pdu = [DCMPDataPDU pDataPDUWithPDVs:listOfPDVs];
		//	NSLog(@"fragment %d time: %f",i , -[timeStamp timeIntervalSinceNow]);
			[self send:[pdu pdu]];		
		//	[pool release];
			[pdv release];
		}
			//NSAutoreleasePool *pool= [[NSAutoreleasePool alloc] init];
			int position = i * bufferSize;
			//NSData *subdata = [data subdataWithRange:NSMakeRange(position, remainder)];
			unsigned char *buffer = (unsigned char *)[data bytes] + position;
			DCMPresentationDataValue *pdv = [[DCMPresentationDataValue alloc] initWithBytes:buffer 
										length:remainder
										isCommand:(BOOL)isCommand 
										isLastFragment:YES 
										contextID:(unsigned char)contextID];
			NSMutableArray *listOfPDVs = [NSMutableArray arrayWithObject:pdv];
			DCMPDataPDU *pdu = [DCMPDataPDU pDataPDUWithPDVs:listOfPDVs];
		//	NSLog(@"fragment %d time: %f", ++i, -[timeStamp timeIntervalSinceNow]);
			[self send:[pdu pdu]];		
		//	[pool release];
			[pdv release];
	}
}



- (void)setReceivedDataHandler:(DCMReceivedDataHandler *)handler{
	[dataHandler release];
	dataHandler = [handler retain];
}

- (void)setDelegate: (id)delegate{
	_delegate = delegate;
}
- (id)delegate{
	return _delegate;
}

//To delegate
- (void)associationAborted{	
	NSLog(@"associationAborted");
	[_delegate associationAborted];
}
- (void)associationReleased{
	[_delegate associationReleased];
}

- (void)startARTIM:(NSObject *)object{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (ARTIM)
		[self invalidateARTIM:nil];
	//NSLog(@"timeout: %d seconds", timeout/1000);
	ARTIM = [[NSTimer scheduledTimerWithTimeInterval:timeout/1000 target:self selector:@selector(timeoutOver:) userInfo:nil repeats:NO] retain];
	[pool release];

}
- (void)invalidateARTIM:(NSObject *)object{
	//NSLog(@"Stop ARTIM");
	[ARTIM invalidate];
	[ARTIM release];
	ARTIM = nil;

}
- (void)timeoutOver:(NSTimer *)timer{
	NSLog(@"ARTIM fired");
	terminate = YES;
	[ARTIM invalidate];
	[ARTIM release];
	ARTIM = nil;
	//[self abort];
}



- (BOOL)isConnected{

	if (socketHandle)
		return YES;
	else
		return NO;

}

- (void)close{
	NSLog(@"socketHandle close");

	NS_DURING
		[socketHandle release];
		socketHandle = 0L;
	NS_HANDLER
	NS_ENDHANDLER
}


- (void)availableData:(NSNotification *)note{
	NSException *exception = nil;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NS_DURING
	if ((_receivePDataCount == -1 ||_receivePDataCount-- > 0) && !terminate) {	
			// -1 is flag to loop forever
			
			//if ([[[note userData] NSFileHandleConnectionAcceptedNotification] isEqual:socketHandle])
			NSData *socketData = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem] ;
			if (!(_incomingData))
				_incomingData = [[NSMutableData data] retain];
			if ([socketData length] > 0) {
				[_incomingData appendData:socketData];
				if (debugLevel)
					NSLog(@"Data length: %d", [_incomingData length]);
			}

			//else
			//	NSLog(@"empty socketData");
			if ([_incomingData length] > 6) {
				unsigned char pduType;
				[_incomingData getBytes:&pduType range:NSMakeRange(0,1)];
				int pduLength;
				[_incomingData getBytes:&pduLength range:NSMakeRange(2,4)];
				pduLength = NSSwapBigIntToHost(pduLength);
				if (debugLevel)
					NSLog(@"pduLength:%d  type:0x%x", pduLength, pduType);
				if (pduLength + 6  <= [_incomingData length]){
					if (pduType == 0x04) {	
												//           - P-DATA PDU
						
						NSData *subdata = [_incomingData subdataWithRange:NSMakeRange(0, pduLength + 6)];
						DCMPDataPDU *pData = [DCMPDataPDU pDataPDUWithData:subdata];
						[dataHandler sendPDataIndication:pData   association:self];	
						
						// DT-2      - send P-DATA indication primitive
						// State 6   - Data Transfer
						if ((_stopAfterLastFragmentOfCommand && [pData containsLastCommandFragment])
							 || (_stopAfterLastFragmentOfData && [pData containsLastDataFragment])
							 || (_stopAfterHandlerReportsDone && [dataHandler isDone])
							 ) {
							 if (debugLevel)
								NSLog(@"Finished getting PDU data");
							// break;
						}
						else{
							if (debugLevel)
							NSLog(@"more data waiting");
						}
					}
					else if (pduType == 0x05) {						//           - A-RELEASE-RQ PDU
							// AR-2      - Issue A-RELEASE indication primitive
							// State 8   - Awaiting local A-RELEASE response primitive
							//           - Assume local A-RELEASE response primitive
							DCMReleasePDU *rPDU = [DCMReleasePDU releasePDUWithType:0x06]; // AR-4      - send a A-RELEASE-RP (and start ARTIM)
							[self send:[rPDU pdu]];
							[self waitForARTIMBeforeTransportConnectionClose];
							exception = [NSException exceptionWithName:@"DCMException" reason:@"A-RELEASE indication while waiting for P-DATA" userInfo:nil];
							//NSLog(@"release PDU");
							//[self associationReleased];
							[exception raise];
					
					}
					else if (pduType == 0x07) {		
						DCMAbortPDU *aPDU = [DCMAbortPDU abortWithData:[(NSData *)_incomingData subdataWithRange:NSMakeRange(0, pduLength + 6)]];
						exception = [NSException exceptionWithName:@"DCMException" reason: @"A-ABORT indication" userInfo:[NSDictionary dictionaryWithObject:aPDU forKey:@"pdu"]];
							[exception raise];
					}
					else {	
						DCMAbortPDU *aPDU = [DCMAbortPDU abortWithSource:0x02  reason:0x02];
						[self send:[aPDU pdu]];
						[self waitForARTIMBeforeTransportConnectionClose];
						exception = [NSException exceptionWithName:@"DCMException" reason: @"A-ABORT indication" userInfo:nil];
					//	[self associationAborted];
					NSLog(@"Abort: Unknown PDU");
						[exception raise];
					}
					//get rid of last PDU

					NSData *newData = [[_incomingData subdataWithRange:NSMakeRange(pduLength + 6, [_incomingData length] - (pduLength + 6))] mutableCopy];
					[_incomingData release];
					_incomingData = newData;
					if (_receivePDataCount >= 0)
						_receivePDataCount++;
				}
				
			}
			[pool release];
			pool = nil;
			
		}
		//NSLog(@"exited waitForPData");
	NS_HANDLER
		if (exception)
			NSLog(@"Exception while waiting for PDUs: %@", [exception reason]);
		else
			NSLog(@"Exception: %@ reason%@", [localException name], [localException reason]);

		[self associationReleased];
	NS_ENDHANDLER
		if (pool)
			[pool release];
	//	[_incomingData release];
		
	if (terminate)
		[self associationAborted];
		//[self abortAssociation];
	// normal return is after all requested P-DATA PDUs have been received, still in State 6
		//NSLog(@"end waitForPData");
	
	
}






	

@end
