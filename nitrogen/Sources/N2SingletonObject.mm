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

#import "N2SingletonObject.h"

@implementation N2SingletonObject

-(id)init {
	if (!_hasInited) {
		self = [super init];
		_hasInited = YES;
	}
	
	return self;
}

-(id)retain {
	return self;
}

-(oneway void)release {
}

-(id)autorelease {
	return self;
}

-(NSUInteger)retainCount {
	return UINT_MAX;
}

@end
