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

#import "OSIFloatVolumeData.h"
#import "OSIROIMask.h"

@implementation OSIFloatVolumeData

@dynamic pixelsWide;
@dynamic pixelsHigh;
@dynamic pixelsDeep;
@dynamic minPixelSpacing;
@dynamic pixelSpacingX;
@dynamic pixelSpacingY;
@dynamic pixelSpacingZ;
@dynamic volumeTransform;

//- (BOOL)getFloatData:(void *)buffer range:(NSRange)range; // just here to suppress warnings
//{
//	return [super getFloatData:buffer range:range];
//}
//

- (BOOL)getFloatRun:(float *)buffer atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z length:(NSUInteger)length
{
    return [super getFloatRun:buffer atPixelCoordinateX:x y:y z:z length:length];
}

- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;  // just here to suppress warnings
{
	return [super getFloat:floatPtr atPixelCoordinateX:x y:y z:z];
}

- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector // just here to suppress warnings
{
	return [super getLinearInterpolatedFloat:floatPtr atDicomVector:vector];
}

// returns true if the ROI mask is entirely with the float volume; 
- (BOOL)checkDebugROIMask:(OSIROIMask *)roiMask
{
    NSValue *maskRunValue;
    OSIROIMaskRun maskRun;
    
    for (maskRunValue in [roiMask maskRuns]) {
        maskRun = [maskRunValue OSIROIMaskRunValue];
        
        if (maskRun.depthIndex >= _pixelsDeep || maskRun.heightIndex >= _pixelsHigh ||
            maskRun.widthRange.location + maskRun.widthRange.length >= _pixelsWide) {
            return NO;
        }
    }
    return YES;
}


@end
