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

#import "NSArray+N2.h"


@implementation NSArray (N2)

-(NSArray*)splitArrayIntoArraysOfMinSize:(NSUInteger)minSize maxArrays:(NSUInteger)maxArrays {
	NSMutableArray* chunks = [NSMutableArray array];
	
	for (NSValue* rangeValue in [self splitArrayIntoChunksOfMinSize:minSize maxChunks:maxArrays]) 
        [chunks addObject:[self subarrayWithRange:[rangeValue rangeValue]]];
	
	return chunks;
}

-(NSArray*)splitArrayIntoChunksOfMinSize:(NSUInteger)minSize maxChunks:(NSUInteger)maxChunks {
	NSUInteger count = self.count, size = maxChunks? MAX(minSize, round(float(count)/maxChunks)) : minSize;
	
	NSMutableArray* chunks = [NSMutableArray array];
	
	NSRange range = NSMakeRange(0, size);
	NSUInteger i = 0;
	do {
		if (++i == maxChunks)
			range.length = count-range.location;
		else if (range.location+range.length > count)
            range.length = count-range.location;
		[chunks addObject:[NSValue valueWithRange:range]];
        range.location += range.length;
	} while (range.location < count);
	
	return chunks;
}

@end

@implementation NSMutableArray (N2)

-(void)addUniqueObjectsFromArray:(NSArray*)array {
    for (id obj in array)
        if (![self containsObject:obj])
            [self addObject:obj];
}

@end