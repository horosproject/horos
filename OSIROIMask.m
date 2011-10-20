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
#import "OSIFloatVolumeData.h"

const OSIROIMaskRun OSIROIMaskRunZero = {{0.0, 0.0}, 0, 0, 1.0};


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

+ (id)ROIMaskFromVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
    NSInteger i;
    NSInteger j;
    NSInteger k;
    float intensity;
    NSMutableArray *maskRuns;
    OSIROIMaskRun maskRun;
    CPRVolumeDataInlineBuffer inlineBuffer;
        
    maskRuns = [NSMutableArray array];
    maskRun = OSIROIMaskRunZero;
    maskRun.intensity = 0.0;
    
    if ([floatVolumeData aquireInlineBuffer:&inlineBuffer]) {
        for (k = 0; k < inlineBuffer.pixelsDeep; k++) {
            for (j = 0; j < inlineBuffer.pixelsHigh; j++) {
                for (i = 0; i < inlineBuffer.pixelsWide; i++) {
                    intensity = CPRVolumeDataGetFloatAtPixelCoordinate(&inlineBuffer, i, j, k);
                    intensity = roundf(intensity*255.0f)/255.0f;
                    
                    if (intensity != maskRun.intensity) { // maybe start a run, maybe close a run
                        if (maskRun.intensity != 0) { // we need to end the previous run
                            [maskRuns addObject:[NSValue valueWithOSIROIMaskRun:maskRun]];
                            maskRun = OSIROIMaskRunZero;
                            maskRun.intensity = 0.0;
                        }
                        
                        if (intensity != 0) { // we need to start a new mask run
                            maskRun.depthIndex = k;
                            maskRun.heightIndex = j;
                            maskRun.widthRange = NSMakeRange(i, 1);
                            maskRun.intensity = intensity;
                        }
                    } else  { // maybe extend a run // maybe do nothing
                        if (intensity != 0) { // we need to extend the run
                            maskRun.widthRange.length += 1;
                        }
                    }
                }
                // after each run scan line we need to close out any open mask run
                if (maskRun.intensity != 0) {
                    [maskRuns addObject:[NSValue valueWithOSIROIMaskRun:maskRun]];
                    maskRun = OSIROIMaskRunZero;
                    maskRun.intensity = 0.0;
                }
            }
        }
    }
    
    [floatVolumeData releaseInlineBuffer:&inlineBuffer];
    
    return [[[[self class] alloc] initWithMaskRuns:maskRuns] autorelease];    
}

- (id)initWithMaskRuns:(NSArray *)maskRuns
{
	if ( (self = [super init]) ) {
		_maskRuns = [[NSArray alloc] initWithArray:maskRuns];
	}
	return self;
}

- (void)dealloc
{
    [_maskRunsData release];
    _maskRunsData = nil;
    [_maskRuns release];
    _maskRuns = nil;
    
    [super dealloc];
}

- (OSIROIMask *)ROIMaskByTranslatingByX:(NSInteger)x Y:(NSInteger)y Z:(NSInteger)z
{
    OSIROIMaskRun maskRun;
    NSValue *maskRunValue;
    NSMutableArray *newMaskRuns;
    
    newMaskRuns = [NSMutableArray arrayWithCapacity:[_maskRuns count]];
    
    for (maskRunValue in _maskRuns) {
        maskRun = [maskRunValue OSIROIMaskRunValue];
        
        assert((NSInteger)maskRun.widthRange.location >= -x);
        maskRun.widthRange.location += x;
        
        assert((NSInteger)maskRun.heightIndex >= -y);
        maskRun.heightIndex += y;
        
        assert((NSInteger)maskRun.depthIndex >= -z);
        maskRun.depthIndex += z;
        
        [newMaskRuns addObject:[NSValue valueWithOSIROIMaskRun:maskRun]];
    }
    
    return [[[[self class] alloc] initWithMaskRuns:newMaskRuns] autorelease];
}

- (NSArray *)maskRuns 
{
	return _maskRuns;
}

- (NSData *)maskRunsData
{
    OSIROIMaskRun *maskRunArray;
    NSInteger i;;
    
    if (_maskRunsData == nil) {
        maskRunArray = malloc([_maskRuns count] * sizeof(OSIROIMaskRun));
        
        for (i = 0; i < [_maskRuns count]; i++) {
            maskRunArray[i] = [[_maskRuns objectAtIndex:i] OSIROIMaskRunValue];
        }
        
        _maskRunsData = [[NSData alloc] initWithBytesNoCopy:maskRunArray length:[_maskRuns count] * sizeof(OSIROIMaskRun) freeWhenDone:YES];
    }
    
    return _maskRunsData;
}

- (NSArray *)maskIndexes
{
	NSValue *maskRunValue;
	NSMutableArray *indexes;
    OSIROIMaskRun maskRun;
	
	indexes = [NSMutableArray array];
			   
	for (maskRunValue in _maskRuns) {
        maskRun = [maskRunValue OSIROIMaskRunValue];
        if (maskRun.intensity) {
            [indexes addObjectsFromArray:OSIROIMaskIndexesInRun(maskRun)];
        }
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











