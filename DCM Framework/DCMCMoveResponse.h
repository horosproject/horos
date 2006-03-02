//
//  DCMCMoveResponse.h
//  OsiriX
//
//  Created by Lance Pysher on 2/8/05.

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
#import "DCMCommandMessage.h"




@interface DCMCMoveResponse : DCMCommandMessage {
	
	unsigned short remainingSuboperations;
	unsigned short	completedSuboperations;
	unsigned short	failedSuboperations;
	unsigned short	warningSuboperations;
}

+ (id)cMoveResponseWithObject:(DCMObject *)aObject;
+ (id)cMoveResponseWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus;

- (id)initWithAffectedSOPClassUID:(NSString *)classUID  
		priority:(unsigned short)aPriority  
		messageIDBeingRespondedTo:(int)messageIDBRT 
		remainingSuboperations:(unsigned short)rso
		completedSuboperations:(unsigned short)cso
		failedSuboperations:(unsigned short)fso
		warningSuboperations:(unsigned short)wso
		status:(unsigned short)aStatus;

@end
