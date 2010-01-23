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


#import <Cocoa/Cocoa.h>

/** \brief move manager */
@interface MoveManager : NSObject {
	NSMutableSet *_set;
}

+ (id)sharedManager;
- (void)addMove:(id)move;
- (void)removeMove:(id)move;
- (BOOL)containsMove:(id)move;

@end
