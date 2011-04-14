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
	NSUInteger count = self.count, size = MAX(minSize, round(float(count)/maxArrays));
	
	NSMutableArray* chunks = [NSMutableArray array];
	
	NSRange range = NSMakeRange(0, size);
	NSUInteger i = 0;
	do {
		if (++i == maxArrays)
			range.length = count-range.location;
		else if (range.location+range.length > count)
				range.length = count-range.location;
		[chunks addObject:[self subarrayWithRange:range]];
	} while (range.location+range.length < count);
	
	return chunks;
}

@end
