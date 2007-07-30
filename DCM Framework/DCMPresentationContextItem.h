//
//  DCMPresentationContextItem.h
//  OsiriX
//
//  Created by Lance Pysher on 12/2/04.

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
#import "DCMUserInformationSubItem.h"

@class DCMPresentationContext;
@interface DCMPresentationContextItem : DCMUserInformationSubItem {
	DCMPresentationContext *context;
}
+ (id)presentationContextItemWithType:(unsigned char)aType length:(int)theLength presentationContext:(DCMPresentationContext *)theContext;
+ (id)presentationContextItemWithType:(unsigned char)aType length:(int)theLength contextID:(unsigned char)contextID  reason:(unsigned char)reason;
- (id)initWithType:(unsigned char)aType length:(int)theLength contextID:(unsigned char)contextID  reason:(unsigned char)reason;
- (id)initWithType:(unsigned char)aType length:(int)theLength presentationContext:(DCMPresentationContext *)theContext;
- (DCMPresentationContext *)context;

@end
