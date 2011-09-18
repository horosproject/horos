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

#import "OSIROIMask.h"


BOOL OSIROIMaskIndexInRun(OSIROIMaskIndex maskIndex, OSIROIMaskRun maskRun)
{
	if (maskIndex.y != maskRun.heightIndex || maskIndex.z != maskRun.depthIndex) {
		return NO;
	}
	if (NSLocationInRange(maskIndex.x, maskRun.widthRange)) {
		return YES;
	} else {
		return NO;
	}
}

NSArray *OSIROIMaskIndexesInRun(OSIROIMaskRun maskRun)
{
	NSMutableArray *indexes;
	NSUInteger i;
	OSIROIMaskIndex index;
	
	indexes = [NSMutableArray array];
	index.y = maskRun.heightIndex;
	index.z = maskRun.depthIndex;
	
	for (i = maskRun.widthRange.location; i < NSMaxRange(maskRun.widthRange); i++) {
		index.x = i;
		[indexes addObject:[NSValue valueWithOSIROIMaskIndex:index]];
	}
	return indexes;
}


@implementation OSIROIMask

- (id)initWithMaskRuns:(NSArray *)maskRuns
{
	if ( (self = [super init]) ) {
		_maskRuns = [[NSArray alloc] initWithArray:maskRuns];
	}
	return self;
}

- (NSArray *)maskRuns 
{
	return _maskRuns;
}

- (NSArray *)maskIndexes
{
	NSValue *maskRunValue;
	NSMutableArray *indexes;
	
	indexes = [NSMutableArray array];
			   
	for (maskRunValue in _maskRuns) {
		[indexes addObjectsFromArray:OSIROIMaskIndexesInRun([maskRunValue OSIROIMaskRunValue])];
	}
			   
	return indexes;
}

// possibly the slowest implentation I can think of...
- (BOOL)indexInMask:(OSIROIMaskIndex)index
{
	return [[self maskIndexes] containsObject:[NSValue valueWithOSIROIMaskIndex:index]];
}

@end

@implementation NSValue (OSIMaskRun)

+ (NSValue *)valueWithOSIROIMaskRun:(OSIROIMaskRun)volumeRun
{
	return [NSValue valueWithBytes:&volumeRun objCType:@encode(OSIROIMaskRun)];
}

- (OSIROIMaskRun)OSIROIMaskRunValue
{
	OSIROIMaskRun run;
    assert(strcmp([self objCType], @encode(OSIROIMaskRun)) == 0);
    [self getValue:&run];
    return run;
}	

+ (NSValue *)valueWithOSIROIMaskIndex:(OSIROIMaskIndex)maskIndex
{
	return [NSValue valueWithBytes:&maskIndex objCType:@encode(OSIROIMaskIndex)];
}

- (OSIROIMaskIndex)OSIROIMaskIndexValue
{
	OSIROIMaskIndex index;
    assert(strcmp([self objCType], @encode(OSIROIMaskIndex)) == 0);
    [self getValue:&index];
    return index;
}	

@end











