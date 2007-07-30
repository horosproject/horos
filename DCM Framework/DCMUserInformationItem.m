//
//  DCMUserInformationItem.m
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

#import "DCMUserInformationItem.h"


@implementation DCMUserInformationItem

+ (id)userInformationItemWithType:(unsigned char)aType length:(int)theLength{
	return [[[DCMUserInformationItem alloc] initWithType:aType length:theLength] autorelease];
}

- (id)initWithType:(unsigned char)aType length:(int)theLength{
	if (self = [super initWithType:aType length:theLength])
		subItemList = [[NSMutableArray array] retain];
	return self;
}

- (void)dealloc{
	[subItemList release];
	[super dealloc];
}

- (void)addSubItem:( DCMAssociationItem *)item{
	[subItemList addObject:item];
}


@end
