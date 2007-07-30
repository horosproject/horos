//
//  DCMCFindRequest.h
//  OsiriX
//
//  Created by Lance Pysher on 12/31/04.

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

@class DCMObject;
@interface DCMCFindRequest : DCMCommandMessage {

}

+ (id)findRequestWithAffectedSOPClassUID:(NSString *)classUID;
+ (id)findRequestWithObject:(DCMObject *)object;
- (id)initWithObject:(DCMObject *)object;
- (id)initWithAffectedSOPClassUID:(NSString *)classUID;
- (int)priority;

@end
