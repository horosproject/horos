//
//  DCMNGetResponse.m
//  OsiriX
//
//  Created by Lance Pysher on 9/2/05.

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


#import "DCMNGetResponse.h"
#import "DCM.h"


@implementation DCMNGetResponse

+ (id) nGetResponseWithObject: (DCMObject *)object{
	return [[[ DCMNGetResponse alloc] initWithObject:object] autorelease];
}

@end
