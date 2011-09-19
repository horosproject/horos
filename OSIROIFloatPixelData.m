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
#import "OSIFloatVolumeData.h";
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
	[super dealloc];
}

- (float)meanIntensity
{
	float* buffer;
	NSUInteger floatCount;
	float mean;
	
	floatCount = [self floatCount];
	buffer = malloc(floatCount * sizeof(float));
	floatCount = [self getFloatData:buffer floatCount:floatCount];
	vDSP_meanv(buffer, 1, &mean, floatCount);
	free(buffer);
	return mean;
}

- (float)maxIntensity
{
	float* buffer;
	NSUInteger floatCount;
	float mean;
	
	floatCount = [self floatCount];
	buffer = malloc(floatCount * sizeof(float));
	floatCount = [self getFloatData:buffer floatCount:floatCount];
	vDSP_maxv(buffer, 1, &mean, floatCount);
	free(buffer);
	return mean;	
}

- (float)minIntensity
{
	float* buffer;
	NSUInteger floatCount;
	float mean;
	
	floatCount = [self floatCount];
	buffer = malloc(floatCount * sizeof(float));
	floatCount = [self getFloatData:buffer floatCount:floatCount];
	vDSP_minv(buffer, 1, &mean, floatCount);
	free(buffer);
	return mean;	
}

- (NSUInteger)floatCount
{
	NSUInteger floatCount;
	NSValue *runValue;
	OSIROIMaskRun maskRun;
	
	floatCount = 0;
	for (runValue in [_ROIMask maskRuns]) {
		maskRun = [runValue OSIROIMaskRunValue];
		floatCount += maskRun.widthRange.length;
	}
	
	return floatCount;
}

- (NSUInteger)getFloatData:(float *)buffer floatCount:(NSUInteger)count
{
	NSUInteger bytesCopied;
	NSValue *runValue;
	OSIROIMaskRun maskRun;
	float *floatBuffer;
	NSRange volumeRange;
	
	bytesCopied = 0;
	floatBuffer = buffer;
	memset(buffer, 0, sizeof(float));
	
	for (runValue in [_ROIMask maskRuns]) {
		maskRun = [runValue OSIROIMaskRunValue];
		if (count >= bytesCopied + maskRun.widthRange.length) {
			volumeRange = [self volumeRangeForROIMaskRun:maskRun];
			[_volumeData getFloatData:floatBuffer range:volumeRange];
			bytesCopied += volumeRange.length;
			floatBuffer += volumeRange.length;
		}
	}
	return bytesCopied;
}

- (NSRange)volumeRangeForROIMaskRun:(OSIROIMaskRun)maskRun
{
	return NSMakeRange(maskRun.depthIndex*_volumeData.pixelsWide*_volumeData.pixelsHigh + 
					   maskRun.heightIndex*_volumeData.pixelsWide + maskRun.widthRange.location, maskRun.widthRange.length);
}


- (NSRange)volumeRangeForROIMaskIndex:(OSIROIMaskIndex)maskIndex
{
	return NSMakeRange(maskIndex.z*_volumeData.pixelsWide*_volumeData.pixelsHigh + 
					   maskIndex.y*_volumeData.pixelsWide + maskIndex.x, 1);
}


			
			
			
		 
		 


@end
