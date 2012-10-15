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

#import <Cocoa/Cocoa.h>
#import "CPRVolumeData.h"

@class OSIROIMask;

// volume data represents a volume in the three natural dimensions
// this strictly represents a float volume, color volumes will be supported with a OSIRGBVolumeData, but no one really cares about that so it is being put off

/**  
 
 The `OSIFloatVolumeData` class represents a volume in the three natural dimensions. Objects of this class strictly represent float intensity data.
 In the future a `OSIRGBVolumeData` may represent RGB data.
 
 */


@interface OSIFloatVolumeData : CPRVolumeData {

}

///-----------------------------------
/// @name Getting Volume Geometry
///-----------------------------------


/** How many pixels wide the data is.
 
 @see pixelsHigh
 @see pixelsDeep
 @see pixelSpacingX
 */
@property (readonly) NSUInteger pixelsWide;

/** How many pixels high the data is.
 
 @see pixelsWide
 @see pixelsDeep
 @see pixelSpacingY
 */
@property (readonly) NSUInteger pixelsHigh;

/** How many pixels deep the data is.
 
 @see pixelsHigh
 @see pixelsDeep
 @see pixelSpacingZ
 */
@property (readonly) NSUInteger pixelsDeep;


/** The smallest pixel spacing in any direction.
 
 @see pixelSpacingX
 @see pixelSpacingY
 @see pixelSpacingZ
 */
@property (readonly) CGFloat minPixelSpacing; // the smallet pixel spacing in any direction;

/** The distance in mm between pixels in the X direction.
 
 @see pixelSpacingY
 @see pixelSpacingZ
 @see pixelsWide
 @see volumeTransform
 */
@property (readonly) CGFloat pixelSpacingX;

/** The distance in mm between pixels in the Y direction.
 
 @see pixelSpacingX
 @see pixelSpacingZ
 @see pixelsHigh
 @see volumeTransform
 */
@property (readonly) CGFloat pixelSpacingY;

/** The distance in mm between pixels in the Z direction.
 
 @see pixelSpacingX
 @see pixelSpacingY
 @see pixelsDeep
 @see volumeTransform
 */
@property (readonly) CGFloat pixelSpacingZ;

/** The affine transform that transforms coordinates in the Patient Space (aka Dicom space, in mm) into pixel coordinates.
 
 @see pixelSpacingX
 @see pixelSpacingY
 @see pixelSpacingZ
 */
@property (readonly) N3AffineTransform volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data coordinates.

// /-----------------------------------
// / @name Accessing Volume Pixel Data
// /-----------------------------------

// /** Copies a range of floats from the receiver’s data into a given buffer.
// 
// This will copy `range.length * sizeof(float)` bytes into the given buffer.
// 
// @param buffer The memory buffer to fill.
// @param range The range of floats in the receiver's data to copy to buffer. The range must lie within the receiver's data.
// 
// @return YES if the data was available and the buffer was filled.
// 
// @see floatAtPixelCoordinateX:y:z:
// @see linearInterpolatedFloatAtDicomVector:
// */
// //- (BOOL)getFloatData:(void *)buffer range:(NSRange)range;

/** Copies a run of floats from the receiver’s data into a given buffer.
 
 This will copy `length * sizeof(float)` bytes into the given buffer. A run a is a series of pixels in the x direction.
 
 @see floatAtPixelCoordinateX:y:z:
 @see linearInterpolatedFloatAtDicomVector:
*/

- (BOOL)getFloatRun:(float *)buffer atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z length:(NSUInteger)length;


/** Returns by indirection the value of the float at the given pixel coordinates.

 @return The value of the float at the given pixel coordinates.
 @param floatPtr Provide a location where to put the requested float
 @param x X Coordinate
 @param y Y Coordinate
 @param z Z Coordinate
 
 @return YES if the data was available and the buffer was filled.

 @see floatBytes
 @see getFloatData:range:
 @see linearInterpolatedFloatAtDicomVector:
 */
- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z; // returns YES if the float was sucessfully gotten

/** Returns by indirection the linearly interpolated value of the pixel at the given coordinate in Patient Space (aka Dicom Space in mm).
 
 @return The value of the float at the given Dicom coordinates.
 @param floatPtr Provide a location where to put the requested float
 @param vector The requested coordinates in Patient Space (aka Dicom Space in mm).
 
 @return YES if the data was available and the buffer was filled.

 @see floatBytes
 @see getFloatData:range:
 @see floatAtPixelCoordinateX:y:z:
 */
- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector; // these are slower, use the inline buffer if you care about speed

- (BOOL)checkDebugROIMask:(OSIROIMask *)roiMask; // returns true if the ROI mask is entirely with the float volume; 

@end
