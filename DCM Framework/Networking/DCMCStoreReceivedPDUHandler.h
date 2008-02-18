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
#import "DCMCompositeResponseHandler.h"

@class DCMPDataPDU;
@class DCMAssociation;
@class DCMObject;
@class DCMCEchoRequest;
@class DCMCStoreRequest;
@class DCMCFindRequest;
@class DCMCMoveRequest;

@class DCMCommandMessage;

@interface DCMCStoreReceivedPDUHandler : DCMCompositeResponseHandler {

	//NSMutableData *commandReceived;
	DCMObject *dcmObject;
	DCMCEchoRequest *echoRequest;
	DCMCStoreRequest *storeRequest;
	DCMCFindRequest *findRequest;
	DCMCMoveRequest *moveRequest;
	DCMCommandMessage *responseMessage;
	NSData *response;
	unsigned char presentationContextID;
	NSString *fileName;
	NSString *folder;
	int numberReceived;
	int errorCount;
	NSString *patientName;
	NSString *studyDescription;
	NSString *studyID;
	NSString *callingAET;
	int commandType;
	id scpDelegate;

}
@property(readonly) DCMObject *dicomObject;
@property(readonly) unsigned char presentationContextID;
@property(readonly) NSData *response;
@property(readonly) DCMCommandMessage *responseMessage;
@property(retain) NSString *callingAET;
@property(retain, setter=setSCPDelegate:) id scpDelegate;
@property(readonly) int commandType;

+ (id)cStoreDataHanderWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug;
- (id)initWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug;
- (void)cEchoResponse;
- (void)cStoreResponse;
- (void)cMoveResponse;
- (void)cFindResponse;

//- (void)sendPDataIndication:(DCMPDataPDU *)pData forAssociation:(DCMAssociation *)association;
- (void)reset;
- (void)updateReceiveStatus:(NSDictionary *)userInfo;
@end
