//
//  DCMStoreSCP.h
//  OsiriX
//
//  Created by Lance Pysher on 12/23/04.

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

#import <Cocoa/Cocoa.h>
#import "DCMSOPClass.h"

@class DCMCStoreReceivedPDUHandler;
@class ONTCPSocket;
@class DCMAssociationResponder;
@class DCMCommandMessage;
@class DCMObject;

@interface DCMStoreSCP : DCMSOPClass {

	NSString *folder;
	NSString *calledAET;
	NSString *callingAET;
	ONTCPSocket *socket;
	NSFileHandle *socketHandle;
	DCMCStoreReceivedPDUHandler  *dataHandler;
	int timeout;

	//int debugLevel;
	//DCMAssociationResponder *association;

}

+ (void)runStoreSCP:(NSDictionary *)params;
- (id)initWithParameters:(NSDictionary *)params;
- (void)run;
- (void)newDataHandler;
- (void)receiveOneSOPInstance;
- (void)sendCommand:(DCMCommandMessage *)command data:(DCMObject *)dataObject forAffectedSOPClassUID:(NSString *)sopClassUID;
//- (void)releaseAssociation;
@end
