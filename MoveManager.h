//
//  MoveManager.h
//  OsiriX
//
//  Created by Lance Pysher on 4/10/06.

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

#import <Cocoa/Cocoa.h>


@interface MoveManager : NSObject {
	NSMutableSet *_set;
}

+ (id)sharedManager;
- (void)addMove:(id)move;
- (void)removeMove:(id)move;
- (BOOL)containsMove:(id)move;

@end
