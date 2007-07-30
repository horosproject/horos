//
//  DCMCFindResponse.h
//  OsiriX
//
//  Created by Lance Pysher on 2/12/05.

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
#import "DCMCommandMessage.h"
#import "DCMCMoveResponse.h"


@interface DCMCFindResponse : DCMCMoveResponse {

}

+ (id)cFindResponseWithObject:(DCMObject *)aObject;
+ (id)cFindResponseWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus;




@end
