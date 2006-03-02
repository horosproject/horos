//
//  DCMMoveSCU.h
//  OsiriX
//
//  Created by Lance Pysher on 12/31/04.

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
#import "DCMSOPClass.h"

@class DCMCMoveResponseDataHandler;
@class DCMObject;
@class DCMTransferSyntax;

@interface DCMMoveSCU : DCMSOPClass {
	
	DCMCMoveResponseDataHandler *dataHandler;
	NSString *affectedSOPClassUID;
	DCMObject *moveObject;
	DCMTransferSyntax *preferredSyntax;
	DCMTransferSyntax *transferSyntax;
	NSString *moveDestination;
	int numberOfFiles;
	unsigned char usePresentationContextID;

}


+ (void)moveWithParameters:(NSDictionary *)parameters;
- (id)initWithParameters:(NSDictionary *)params;
- (void)move;




@end
