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

@interface NSArray (ArrayCategory)

- (NSArray*)shuffledArray;

@end

@interface NSMutableArray (MutableArrayCategory)

//appends array to self except when the object is already in the array as determined by isEqual:
- (void)mergeWithArray:(NSArray*)array;
- (BOOL)containsString:(NSString *)string;

//randomizes the array
- (void)shuffle;

@end
