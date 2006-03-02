//
//  DCMNActionResponse.m
//  OsiriX
//
//  Created by Lance Pysher on 9/2/05.

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

#import "DCMNActionResponse.h"
#import "DCM.h"


@implementation DCMNActionResponse

+ (id) nActionResponseWithObject: (DCMObject *)object{
	return [[[ DCMNActionResponse alloc] initWithObject:object] autorelease];
}

- (id) initWithObject:(DCMObject *)object {
	if (self = [super initWithObject:object])
		actionType = [[dcmObject attributeValueWithName:@"ActionTypeID"] shortValue];
	return self;
}

@end
