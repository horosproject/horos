//
//  DCMImplementationClassUIDUserInformationSubItem.m
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

#import "DCMImplementationClassUIDUserInformationSubItem.h"


@implementation DCMImplementationClassUIDUserInformationSubItem

+ (id)implementationClassUIDUserInformationSubItemWithType:(unsigned char)aType length:(int)theLength implementationClassUID:(NSString *)implementationClass{
	return [[[DCMImplementationClassUIDUserInformationSubItem alloc] initWithType:aType length:theLength implementationClassUID:implementationClass] autorelease];
}

- (id)initWithType:(unsigned char)aType length:(int)theLength implementationClassUID:(NSString *)implementationClass{
	if (self = [super initWithType:aType length:theLength])
		implementationClassUID = [implementationClass retain];
	return self;
}

- (void)dealloc{
	[implementationClassUID release];
	[super dealloc];
}

- (NSString *)implementationClassUID{
	return implementationClassUID;
}
@end
