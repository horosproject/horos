//
//  DCMApplicationContextItem.m
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

#import "DCMApplicationContextItem.h"


@implementation DCMApplicationContextItem

+ (id)applicationContextItemWithType:(unsigned char)aType length:(int)theLength  name:(NSString *)name{
	return [[[DCMApplicationContextItem alloc] initWithType:aType length:theLength  name:name] autorelease];
}

- (id)initWithType:(unsigned char)aType length:(int)theLength  name:(NSString *)name{
	if (self = [super initWithType:aType length:theLength])
		applicationContextName = [name retain];
	return self;
}

- (void)dealloc{
	[applicationContextName release];
	[super dealloc];
}

- (NSString *)applicationContextName{
	return applicationContextName;
}

@end
