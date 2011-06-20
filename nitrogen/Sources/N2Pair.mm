/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "N2Pair.h"

@implementation N2Pair
@synthesize first = _first, second = _second;

-(id)initWith:(id)first and:(id)second {
	self = [super init];
	
	_first = [first retain];
	_second = [second retain];
	
	return self;
}

-(void)dealloc {
	[_first release];
	[_second release];
	[super dealloc];
}

@end
