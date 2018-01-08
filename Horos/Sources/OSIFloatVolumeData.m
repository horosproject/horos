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
