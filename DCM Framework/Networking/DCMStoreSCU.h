//
//  DCMStoreSCU.h
//  OsiriX
//
//  Created by Lance Pysher on 12/20/04.

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

@class DCMAssociation;
@class DCMCStoreResponseHandler;
@class DCMTransferSyntax;
@class DCMObject;

@interface DCMStoreSCU : DCMSOPClass {
	//int debugLevel;
	int compression;
	//DCMAssociation *association;
	DCMCStoreResponseHandler *dataHandler;
	NSMutableArray *affectedSOPClassUIDs;
	NSString *affectedSOPClassUID;
	NSArray *filesToSend;
	DCMTransferSyntax *preferredSyntax;
	DCMTransferSyntax *transferSyntax;
	int numberOfFiles;
	unsigned char usePresentationContextID;
	id moveHandler;
}

/*
Parameters:
@"filestoSend"
@"compression"
@"transferSyntax"
plus DCMAssociation parameters
*/
+ (id)sendWithParameters:(NSDictionary *)parameters;
- (id)initWithParameters:(NSDictionary *)params;
- (BOOL)createAssociationWithParameters:(NSDictionary *)parameters;
- (void)send;
- (void)sendObject:(DCMObject *)dcmObject;


@end
