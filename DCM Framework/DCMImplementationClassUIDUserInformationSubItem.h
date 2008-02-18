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
#import "DCMUserInformationSubItem.h"


@interface DCMImplementationClassUIDUserInformationSubItem : DCMUserInformationSubItem {
	NSString *implementationClassUID;
}
+ (id)implementationClassUIDUserInformationSubItemWithType:(unsigned char)aType length:(int)theLength implementationClassUID:(NSString *)implementationClass;
- (id)initWithType:(unsigned char)aType length:(int)theLength implementationClassUID:(NSString *)implementationClass;
- (NSString *)implementationClassUID;


@end
