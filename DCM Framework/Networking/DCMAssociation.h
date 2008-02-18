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

#import <Cocoa/Cocoa.h>

//static int NO_DATA = 0;
//static int DATA_AVAILABLE = 1;



@class DCMTransferSyntax;
@class DCMReceivedDataHandler;
@interface DCMAssociation : NSObject {
	int timeout;
	NSString *calledAET;
	NSString *callingAET;
	int port;
	NSString *hostname;
	NSArray *presentationContexts;
	int maximumLengthReceived;
	int receivedBufferSize;
	BOOL terminate;
	DCMReceivedDataHandler *dataHandler;
	int debugLevel;
	id _delegate;
	NSTimer *ARTIM;
	NSDate *timeStamp;
//	NSSocketPort *socketPort;
	NSFileHandle *socketHandle;
//	NSConnection *connection;

/*
need instance variables so that we can do an asychronous
read of data when using DCMSocket and NSFileHandle
 */
	BOOL _stopAfterLastFragmentOfCommand;
	BOOL _stopAfterLastFragmentOfData;
	BOOL _stopAfterHandlerReportsDone;
	int _receivePDataCount;
	NSMutableData *_incomingData;
	NSConditionLock *_dataLock;
	
}

@property(readonly) NSString *callingAET, *calledAET;
@property(retain) id delegate;

+ (int)defaultMaximumLengthReceived;
+ (int)defaultReceiveBufferSize;
+ (int)defaultSendBufferSize;

/*********
	Parameters needed for initiation are:
	@"hostname"					string
	@"port"						NSNumber int
	@"calledAET"				string
	@"callingAET"				string
	@"presentationContexts"		NSArray of  DCMPresentationContexts
*********/
		
+ (id)associationInitiatorWithParameters: (NSDictionary*)params;

/*********
	Parameters needed for acceptance are:
	@"socket"					ONTCPSocket
	@"calledAET"				string
**********/

+ (id)associationResponderWithParameters: (NSDictionary*)params;
+ (id)listenerOnPort: (int)port;
- (id)initResponderWithParameters: (NSDictionary*)params;
- (id)initInitiatorWithParameters: (NSDictionary*)params;
- (void) terminate: (id)sender;
- (void)releaseAssociation;
- (void)abort;
- (void)sendPresentationContextID: (unsigned char)contextID  command: (NSData*)command  data: (NSData*)data;
- (void)waitForARTIMBeforeTransportConnectionClose;
- (void)waitForPDataPDUs: (NSDictionary*)params;
- (void)waitForOnePDataPDU;
- (void)waitForCommandPDataPDUs;
- (void)waitForDataPDataPDUs;
- (void)waitForPDataPDUsUntilHandlerReportsDone;

- (unsigned char)presentationContextIDForAbstractSyntax: (NSString*)abstractSytaxUID;
- (unsigned char)presentationContextIDForAbstractSyntax: (NSString*)abstractSytaxUID transferSyntax: (DCMTransferSyntax*)transferSyntax;
- (DCMTransferSyntax*) transferSyntaxForPresentationContextID: (unsigned char)contextID;

- (void) send: (NSData*)data;
- (void) send: (NSData*)data  asCommand: (BOOL)isCommand  presentationContext: (unsigned char)contextID;
- (void)setReceivedDataHandler: (DCMReceivedDataHandler*)handler;

- (void)startARTIM: (NSObject*)object;
- (void)invalidateARTIM: (NSObject*)object;
- (void)timeoutOver: (NSTimer*)timer;

- (NSData*) readData;


//To delegate
- (void)associationAborted;
- (void)associationReleased;

- (BOOL)isConnected;

- (void)close;

@end
