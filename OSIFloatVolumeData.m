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


@implementation OSIFloatVolumeData

@dynamic pixelsWide;
@dynamic pixelsHigh;
@dynamic pixelsDeep;
@dynamic minPixelSpacing;
@dynamic pixelSpacingX;
@dynamic pixelSpacingY;
@dynamic pixelSpacingZ;
@dynamic volumeTransform;

- (BOOL)getFloatData:(void *)buffer range:(NSRange)range;
{
	return [super getFloatData:buffer range:range];
}

- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z; // returns YES if the float was sucessfully gotten
{
	return [super getFloat:floatPtr atPixelCoordinateX:x y:y z:z];
}

- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector
{
	return [super getLinearInterpolatedFloat:floatPtr atDicomVector:vector];
}

@end
