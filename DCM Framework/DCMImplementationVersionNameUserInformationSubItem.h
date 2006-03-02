//
//  DCMImplementationVersionNameUserInformationSubItem.h
//  OsiriX
//
//  Created by Lance Pysher on 12/2/04.

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
#import "DCMUserInformationSubItem.h"


@interface DCMImplementationVersionNameUserInformationSubItem : DCMUserInformationSubItem {
	NSString *implementationVersionName;
}
+ (id)implementationVersionNameUserInformationSubItemWithType:(unsigned char)aType length:(int)theLength implementationVersionName:(NSString *)implementationName;
- (id)initWithType:(unsigned char)aType length:(int)theLength implementationVersionName:(NSString *)implementationName;


- (NSString *)implementationVersionName;

@end
