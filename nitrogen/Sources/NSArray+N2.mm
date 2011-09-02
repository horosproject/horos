//
//  NSArray+N2.mm
//  OsiriX
//
//  Created by Alessandro Volz on 14.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

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
