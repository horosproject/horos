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


#import "MoveManager.h"

static MoveManager *sharedManager = 0L;

@implementation MoveManager

+ (id)sharedManager{
	if (!sharedManager)
		sharedManager = [[MoveManager alloc] init];
	return sharedManager;
}

- (id)init{
	if (self = [super init])
		_set = [[NSMutableSet alloc] init];
	return self;
}


- (void)addMove:(id)move{
	[_set addObject:move];
}

- (void)removeMove:(id)move{
	[_set removeObject:move];
}

- (BOOL)containsMove:(id)move{
	return [_set containsObject:move];
}



@end
