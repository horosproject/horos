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

#import "OSIROIFloatPixelData.h"
#import "OSIFloatVolumeData.h"
#import "OSIROIMask.h"
#include <Accelerate/Accelerate.h>

@implementation OSIROIFloatPixelData

@synthesize ROIMask = _ROIMask;
@synthesize floatVolumeData = _volumeData;

- (id)initWithROIMask:(OSIROIMask *)roiMask floatVolumeData:(OSIFloatVolumeData *)volumeData
{
	if ( (self = [super init]) ) {
		_ROIMask = [roiMask retain];
		_volumeData = [volumeData retain];
	}
	return self;
}

- (void)dealoc
{
	[_ROIMask release];
	_ROIMask = nil;
	[_volumeData release];
	_volumeData = nil;
	[_floatData release];
	_floatData = nil;
	[super dealloc];
}

- (float)meanIntensity
{
	NSUInteger floatCount;
	float mean;
	
    if (floatCount == 0) {
        return NAN;
    }
    
	floatCount = [self floatCount];
	vDSP_meanv((float *)[[self floatData] bytes], 1, &mean, floatCount);
	return mean;
}

- (float)maxIntensity
{
	NSUInteger floatCount;
	float mean;
	
    if (floatCount == 0) {
        return NAN;
    }
    
	floatCount = [self floatCount];
	vDSP_maxv((float *)[[self floatData] bytes], 1, &mean, floatCount);
	return mean;	
}

- (float)minIntensity
{
	NSUInteger floatCount;
	float mean;
	
    if (floatCount == 0) {
        return NAN;
    }
    
	floatCount = [self floatCount];
	vDSP_minv((float *)[[self floatData] bytes], 1, &mean, floatCount);
	return mean;	
}

- (float)intensityStandardDeviation
{
    float negativeMean = -[self meanIntensity];
    float unscaledStdDev;
    NSUInteger floatCount = [self floatCount];
    
    if (floatCount == 0) {
        return NAN;
    }
    
    float *scrap1 = malloc(floatCount * sizeof(float));
    float *scrap2 = malloc(floatCount * sizeof(float));
    
    vDSP_vsadd((float *)[[self floatData] bytes], 1, &negativeMean, scrap1, 1, floatCount);
    vDSP_vsq(scrap1, 1, scrap2, 1, floatCount);
    vDSP_sve(scrap2, 1, &unscaledStdDev, floatCount);
    
    free(scrap1);
    free(scrap2);
    
    return sqrtf(unscaledStdDev / (float)floatCount);
}

- (NSUInteger)floatCount
{
    NSUInteger floatCount;
    @synchronized(self) {
        if (_floatData) {
            return [_floatData length] / sizeof(float);
        }

        NSValue *runValue;
        OSIROIMaskRun maskRun;
        
        floatCount = 0;
        for (runValue in [_ROIMask maskRuns]) {
            maskRun = [runValue OSIROIMaskRunValue];
            floatCount += maskRun.widthRange.length;
        }
    }
    return floatCount;
}

- (NSUInteger)getFloatData:(float *)buffer floatCount:(NSUInteger)count
{
    NSUInteger bytesCopied;
    @synchronized(self) {
        bytesCopied = MIN(count, [[self floatData] length] / sizeof(float));
        [[self floatData] getBytes:buffer length:[[self floatData] length]];
    }
    return bytesCopied;
}

- (NSData *)floatData
{
    @synchronized(self) {
        if (_floatData) {
            return _floatData;
        }
        
        NSValue *runValue;
        OSIROIMaskRun maskRun;
        float *buffer;
        float *floatBuffer;

        floatBuffer = malloc([self floatCount] * sizeof(float));
        buffer = floatBuffer;
        memset(floatBuffer, 0, [self floatCount] * sizeof(float));
        
        for (runValue in [_ROIMask maskRuns]) {
            maskRun = [runValue OSIROIMaskRunValue];
            [_volumeData getFloatRun:floatBuffer atPixelCoordinateX:maskRun.widthRange.location y:maskRun.heightIndex z:maskRun.depthIndex length:maskRun.widthRange.length];
            floatBuffer += maskRun.widthRange.length;
        }
        
        _floatData = [[NSData alloc] initWithBytesNoCopy:buffer length:[self floatCount] * sizeof(float) freeWhenDone:YES];
    }
    return _floatData;
}

//- (NSRange)volumeRangeForROIMaskRun:(OSIROIMaskRun)maskRun
//{
//	return NSMakeRange(maskRun.depthIndex*_volumeData.pixelsWide*_volumeData.pixelsHigh + 
//					   maskRun.heightIndex*_volumeData.pixelsWide + maskRun.widthRange.location, maskRun.widthRange.length);
//}


- (NSRange)volumeRangeForROIMaskIndex:(OSIROIMaskIndex)maskIndex
{
	return NSMakeRange(maskIndex.z*_volumeData.pixelsWide*_volumeData.pixelsHigh + 
					   maskIndex.y*_volumeData.pixelsWide + maskIndex.x, 1);
}


			
			
			
		 
		 


@end
