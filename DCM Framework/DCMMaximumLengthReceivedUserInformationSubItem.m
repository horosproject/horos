//
//  DCMMaximumLengthReceivedUserInformationSubItem.m
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

#import "DCMMaximumLengthReceivedUserInformationSubItem.h"


@implementation DCMMaximumLengthReceivedUserInformationSubItem

+ (id)maximumLengthReceivedUserInformationSubItemWithType:(unsigned char)aType length:(int)theLength  maxLengthReceived:(int)max{
	return [[[DCMMaximumLengthReceivedUserInformationSubItem alloc] initWithType:aType length:theLength  maxLengthReceived:max] autorelease];
}

- (id)initWithType:(unsigned char)aType length:(int)theLength  maxLengthReceived:(int)max{
	if (self = [super initWithType:aType length:theLength])
		maximumLengthReceived = max;
	return self;
}

- (int)maximumLengthReceived{
	return maximumLengthReceived;
}

@end
