/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "OSIROI.h"
#import "OSIROI+Private.h"
#import "OSIPlanarPathROI.h"
#import "OSIPlanarBrushROI.h"
#import "OSICoalescedPlanarROI.h"
#import "OSIROIFloatPixelData.h"
#import "OSIFloatVolumeData.h"
#import "DCMView.h"
#import "N3Geometry.h"
#import "ROI.h"

@implementation OSIROI

- (void)dealloc
{
    [_homeFloatVolumeData release];
    _homeFloatVolumeData = nil;
    [super dealloc];
}

- (NSString *)name
{
	assert(0);
	return nil;
}

- (NSColor *)fillColor
{
    NSSet *osiriXROIs = [self osiriXROIs];
    NSColor *color = nil;
    
    for (ROI *roi in osiriXROIs) {
        if (color == nil) {
            if ([roi type] == tPlain) {
                color = [[roi NSColor] colorWithAlphaComponent:[roi opacity]];
            }
        } else if ([color isEqual:[roi NSColor]] == NO) {
            return nil;
        }
    }
    
    return color;
}


- (void)setFillColor:(NSColor *)color
{
    NSSet *osiriXROIs = [self osiriXROIs];
    
    for (ROI *roi in osiriXROIs) {
        if ([roi type] == tPlain) {
            [roi setNSColor:[color colorWithAlphaComponent:1]];
            [roi setOpacity:[color alphaComponent]];
        }
    }
}

- (NSColor *)strokeColor
{
    NSSet *osiriXROIs = [self osiriXROIs];
    NSColor *color = nil;
    
    for (ROI *roi in osiriXROIs) {
        if (color == nil) {
            if ([roi type] != tPlain) {
                color = [[roi NSColor] colorWithAlphaComponent:[roi opacity]];
            }
        } else if ([color isEqual:[roi NSColor]] == NO) {
            return nil;
        }
    }
    
    return color;
}

- (void)setStrokeColor:(NSColor *)color
{
    NSSet *osiriXROIs = [self osiriXROIs];
    
    for (ROI *roi in osiriXROIs) {
        if ([roi type] != tPlain) {
            [roi setNSColor:[color colorWithAlphaComponent:1]];
            [roi setOpacity:[color alphaComponent]];
        }
    }
}

- (CGFloat)strokeThickness
{
    NSSet *osiriXROIs = [self osiriXROIs];
    CGFloat thickness = 0;
    
    for (ROI *roi in osiriXROIs) {
        if (thickness == 0) {
            thickness = [roi thickness];
        } else if (thickness != [roi thickness]) {
            return 0;
        }
    }
    
    return thickness;
}

- (void)setStrokeThickness:(CGFloat)strokeThickness
{
    NSSet *osiriXROIs = [self osiriXROIs];
    
    for (ROI *roi in osiriXROIs) {
        [roi setThickness:strokeThickness];
    }
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

- (NSSet *)osiriXROIs
{
	return [NSSet set];
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
	return [NSArray arrayWithObjects:@"intensityMean", @"intensityMax", @"intensityMin", @"volume", nil];
}

- (NSString *)labelForMetric:(NSString *)metric
{
	if ([metric isEqualToString:@"intensityMean"]) {
		return @"Mean Intensity"; // localize me!
	} else if ([metric isEqualToString:@"intensityMax"]) {
		return @"Maximum Intensity"; // localize me!
	} else if ([metric isEqualToString:@"intensityMin"]) {
		return @"Minimum Intensity"; // localize me!
	}
	return nil;
}

- (NSString *)unitForMetric:(NSString *)metric // make me smarter!
{
	if ([metric isEqualToString:@"intensityMean"]) {
		return @"";
	} else if ([metric isEqualToString:@"intensityMax"]) {
		return @""; 
	} else if ([metric isEqualToString:@"intensityMin"]) {
		return @"";
    } else if ([metric isEqualToString:@"volume"]) {
        return @"mm3";
    }

	return nil;
}

- (id)valueForMetric:(NSString *)metric
{
	if ([metric isEqualToString:@"intensityMean"]) {
		return [NSNumber numberWithDouble:[self intensityMeanWithFloatVolumeData:[self homeFloatVolumeData]]];
	} else if ([metric isEqualToString:@"intensityMax"]) {
		return [NSNumber numberWithDouble:[self intensityMaxWithFloatVolumeData:[self homeFloatVolumeData]]];
	} else if ([metric isEqualToString:@"intensityMin"]) {
		return [NSNumber numberWithDouble:[self intensityMinWithFloatVolumeData:[self homeFloatVolumeData]]];
	} else if ([metric isEqualToString:@"volume"]) {
		return [NSNumber numberWithDouble:(double)[self volume]];
	}
	return nil;
}

- (CGFloat)intensityMeanWithFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
    return [[self ROIFloatPixelDataForFloatVolumeData:floatVolumeData] intensityMean];
}

- (CGFloat)intensityMaxWithFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
    return [[self ROIFloatPixelDataForFloatVolumeData:floatVolumeData] intensityMax];
}

- (CGFloat)intensityMinWithFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
    return [[self ROIFloatPixelDataForFloatVolumeData:floatVolumeData] intensityMin];
}

- (CGFloat)volume
{
    OSIROIMask *mask = [self ROIMaskForFloatVolumeData:[self homeFloatVolumeData]];
    CGFloat voxelVolumeCM3 = self.homeFloatVolumeData.pixelSpacingX * self.homeFloatVolumeData.pixelSpacingY * self.homeFloatVolumeData.pixelSpacingZ* .001;
    return (CGFloat)[mask maskIndexCount]*voxelVolumeCM3;
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
	return _homeFloatVolumeData;
}

- (void)setHomeFloatVolumeData:(OSIFloatVolumeData *)homeFloatVolumeData
{
    if (homeFloatVolumeData != _homeFloatVolumeData) {
        [_homeFloatVolumeData release];
        _homeFloatVolumeData = [homeFloatVolumeData retain];
    }
}

- (N3BezierPath *)bezierPath
{
    return nil;
}

- (N3Vector)centerOfMass
{
    OSIROIMask *roiMask;
    roiMask = [self ROIMaskForFloatVolumeData:[self homeFloatVolumeData]];
    return N3VectorApplyTransform([roiMask centerOfMass], N3AffineTransformInvert([[self homeFloatVolumeData] volumeTransform]));
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
		case tOval:
		case tROI:
        case tPencil:
			return [[[OSIPlanarPathROI alloc] initWithOsiriXROI:roi pixToDICOMTransfrom:pixToDICOMTransfrom homeFloatVolumeData:floatVolumeData] autorelease];
			break;
        case tPlain:
            return [[[OSIPlanarBrushROI alloc] initWithOsiriXROI:roi pixToDICOMTransfrom:pixToDICOMTransfrom homeFloatVolumeData:floatVolumeData] autorelease];
		default:
			return nil;;
	}
}


+ (id)ROICoalescedWithSourceROIs:(NSArray *)rois homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
	return [[[OSICoalescedPlanarROI alloc] initWithSourceROIs:rois homeFloatVolumeData:floatVolumeData] autorelease];
}


@end
