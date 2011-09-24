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

#import "OSIROI.h"
#import "OSIROI+Private.h"
#import "OSIPlanarPathROI.h"
#import "OSICoalescedROI.h"
#import "OSIROIFloatPixelData.h"
#import "OSIFloatVolumeData.h"
#import "DCMView.h"
#import "N3Geometry.h"
#import "ROI.h"

@implementation OSIROI

- (NSString *)name
{
	assert(0);
	return nil;
}

- (NSArray *)convexHull
{
	assert(0);
	return nil;
}

- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume
{
	return nil;
}

- (NSArray *)osiriXROIs
{
	return [NSArray array];
}

- (NSString *)label
{
	NSString *metric;
	NSMutableString *label;
	
	label = [NSMutableString string];
	for (metric in [self metricNames]) {
		[label appendFormat:@"%@: %@%@, ", [self labelForMetric:metric], [self valueForMetric:metric], [self unitForMetric:metric]];
	}
	return label;
}

- (NSArray *)metricNames
{
	return [NSArray arrayWithObjects:@"meanIntensity", @"maxIntensity", @"minIntensity", nil];
}

- (NSString *)labelForMetric:(NSString *)metric
{
	if ([metric isEqualToString:@"meanIntensity"]) {
		return @"Mean Intensity"; // localize me!
	} else if ([metric isEqualToString:@"maxIntensity"]) {
		return @"Maximum Intensity"; // localize me!
	} else if ([metric isEqualToString:@"minIntensity"]) {
		return @"Minimum Intensity"; // localize me!
	}
	return nil;
}

- (NSString *)unitForMetric:(NSString *)metric // make me smarter!
{
	if ([metric isEqualToString:@"meanIntensity"]) {
		return @"";
	} else if ([metric isEqualToString:@"maxIntensity"]) {
		return @""; 
	} else if ([metric isEqualToString:@"minIntensity"]) {
		return @"";
	}
	return nil;
}

- (id)valueForMetric:(NSString *)metric
{
	if ([metric isEqualToString:@"meanIntensity"]) {
		return [NSNumber numberWithDouble:[[self ROIFloatPixelData] meanIntensity]];
	} else if ([metric isEqualToString:@"maxIntensity"]) {
		return [NSNumber numberWithDouble:[[self ROIFloatPixelData] maxIntensity]];
	} else if ([metric isEqualToString:@"minIntensity"]) {
		return [NSNumber numberWithDouble:[[self ROIFloatPixelData] minIntensity]];
	}
	return nil;
}	

- (OSIROIFloatPixelData *)ROIFloatPixelData
{
	return [self ROIFloatPixelDataForFloatVolumeData:[self homeFloatVolumeData]];
}

- (OSIROIFloatPixelData *)ROIFloatPixelDataForFloatVolumeData:(OSIFloatVolumeData *)floatVolume; // convenience method
{
    OSIROIMask *roiMask;
    roiMask = [self ROIMaskForFloatVolumeData:floatVolume];

    assert([floatVolume checkDebugROIMask:roiMask]);
    
	return [[[OSIROIFloatPixelData alloc] initWithROIMask:roiMask floatVolumeData:floatVolume] autorelease];
}

- (OSIFloatVolumeData *)homeFloatVolumeData // the volume data on which the ROI was drawn
{
	return nil;
}

- (void)drawSlab:(OSISlab)slab inCGLContext:(CGLContextObj)glContext pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform;
{
}

@end

@implementation OSIROI (Private)

+ (id)ROIWithOsiriXROI:(ROI *)roi pixToDICOMTransfrom:(N3AffineTransform)pixToDICOMTransfrom homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData;
{
	switch ([roi type]) {
		case tMesure:
		case tOPolygon:
		case tCPolygon:
			return [[[OSIPlanarPathROI alloc] initWithOsiriXROI:roi pixToDICOMTransfrom:pixToDICOMTransfrom homeFloatVolumeData:floatVolumeData] autorelease];
			break;
		default:
			return nil;;
	}
}


+ (id)ROICoalescedWithSourceROIs:(NSArray *)rois homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
	return [[[OSICoalescedROI alloc] initWithSourceROIs:rois homeFloatVolumeData:floatVolumeData] autorelease];
}


@end
