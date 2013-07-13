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


@interface NSArray (N2)

- (NSArray*)splitArrayIntoArraysOfMinSize:(NSUInteger)chunkSize maxArrays:(NSUInteger)maxArrays;
- (NSArray*)splitArrayIntoChunksOfMinSize:(NSUInteger)chunkSize maxChunks:(NSUInteger)maxChunks;
- (id) deepMutableCopy;

@end


@interface NSMutableArray (N2)

-(void)addUniqueObjectsFromArray:(NSArray*)array;

@end