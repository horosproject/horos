//
//  DCMNCreateResponse.m
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

#import "DCMNCreateResponse.h"
#import "DCM.h"


@implementation DCMNCreateResponse

+ (id)nCreateResponseWithObject: (DCMObject *)object {
	return [[[DCMNCreateResponse alloc] initWithObject:object] autorelease];
}

@end
