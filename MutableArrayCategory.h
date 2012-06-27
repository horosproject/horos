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
/** \brief  Category to shuffle arrays */
@interface NSArray (ArrayCategory)

- (NSArray*)shuffledArray;

@end

/** \brief  Category to shuffle mutableArrays */
@interface NSMutableArray (MutableArrayCategory)

//appends array to self except when the object is already in the array as determined by isEqual:
- (void)mergeWithArray:(NSArray*)array;
- (BOOL)containsString:(NSString *)string __deprecated; // Deprecated: why use this instead of containsObject: ?
- (void) removeDuplicatedStrings;
- (void) removeDuplicatedStringsInSyncWithThisArray: (NSMutableArray*) otherArray;
- (void) removeDuplicatedObjects;

//randomizes the array
- (void)shuffle;

@end
