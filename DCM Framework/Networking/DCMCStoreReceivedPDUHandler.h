//
//  DCMCStoreReceivedPDUHandler.h
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
+ (id)cStoreDataHanderWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug;
- (id)initWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug;
- (void)cEchoResponse;
- (void)cStoreResponse;
- (void)cMoveResponse;
- (void)cFindResponse;

//- (void)sendPDataIndication:(DCMPDataPDU *)pData forAssociation:(DCMAssociation *)association;
- (DCMObject *)dicomObject;
- (unsigned char)presentationContextID;
- (NSData *)response;
- (DCMCommandMessage *)responseMessage;
- (void)reset;
- (NSString *)callingAET;
- (void)setCallingAET:(NSString *)aet;
- (void)setSCPDelegate:(id)delegate;
- (int)commandType;
- (void)updateReceiveStatus:(NSDictionary *)userInfo;
@end
