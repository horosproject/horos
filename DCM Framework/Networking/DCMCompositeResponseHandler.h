//
//  DCMCompositeResponseHandler.h
//  OsiriX
//
//  Created by Lance Pysher on 12/15/04.

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
#import "DCMReceivedDataHandler.h"

@class DCMObject;
@class DCMTransferSyntax;
@class DCMPDataPDU;
@class DCMAssociation;
@interface DCMCompositeResponseHandler : DCMReceivedDataHandler {

	BOOL success;
	int status;
	BOOL allowData;
	NSString *calledAET;
	NSDate *date;
}
@property(readonly) BOOL wasSuccessful;
@property(readonly) int status;
@property(copy) NSString *calledAET;

- (DCMObject *)objectFromCommandOrData:(NSData *)data withTransferSyntax:(DCMTransferSyntax *)syntax;
- (void)sendPDataIndication:(DCMPDataPDU *)pdu   association:(DCMAssociation *)association;
- (void)evaluateStatusAndSetSuccess:(DCMObject *)object;
- (void)makeUseOfDataSet:(DCMObject *)object;

@end
