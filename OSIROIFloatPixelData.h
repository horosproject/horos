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
#import "OSIROIMask.h"
// this is the representation of the data within the generic ROI

/**  
 
 The `OSIROIFloatPixelData` class is used to access pixel in a OSIFloatVolumeData instance data under a given OSIROIMask.
 
 */


@class OSIFloatVolumeData;
@class OSIStudy;

@interface OSIROIFloatPixelData : NSObject {
	OSIROIMask *_ROIMask;
	OSIFloatVolumeData *_volumeData;
}

///-----------------------------------
/// @name Creating ROI Float Pixel Data Objects
///-----------------------------------

/** Initializes and returns a newly created ROI Float Pixel Data Object.
 
 Creates a Float Pixel Data instance to access pixels covered by the given mask in the given Float Volume Data
	
 @return The initialized ROI Float Pixel Data object or `nil` if there was a problem initializing the object.
 
 @param roiMask the ROI Mask under which the receiver will access pixels.
 @param volumeData The Float Volume Data the receiver will use to access pixels.
 */

- (id)initWithROIMask:(OSIROIMask *)roiMask floatVolumeData:(OSIFloatVolumeData *)volumeData;

///-----------------------------------
/// @name Accessing Properties
///-----------------------------------

/** The receiver’s mask.
 */
@property (nonatomic, readonly, retain) OSIROIMask *ROIMask;
/** The receiver’s Float Volume Data.
 */
@property (nonatomic, readonly, retain) OSIFloatVolumeData *floatVolumeData;

///-----------------------------------
/// @name Accessing Standard Metrics
///-----------------------------------

/** Returns the mean intensity of the pixels under the mask.
 
 @return The mean intensity of the pixels under the mask
 */
- (float)meanIntensity;

/** Returns the maximum intensity of the pixels under the mask.
 
 @return The maximum intensity of the pixels under the mask
 */
- (float)maxIntensity;

/** Returns the minumim intensity of the pixels under the mask.
 
 @return The minumim intensity of the pixels under the mask
 */
- (float)minIntensity;

///-----------------------------------
/// @name Accessing Pixel Data
///-----------------------------------

/** Returns the number of pixels under the mask.
 
 @return The number of pixels under the mask.
 */
- (NSUInteger)floatCount;

/** Copies a number of floats from the start of the receiver's data into a given buffer
 
 This will copy `count * sizeof(float)` bytes into the given buffer.
 
 @return The number of floats copied.
 
 @param buffer A buffer into which to copy data.
 @param count The number of floats to copy.
 */
- (NSUInteger)getFloatData:(float *)buffer floatCount:(NSUInteger)count;

/** Returns the range within the receiver's floatVolumeData of the given Mask Run.
 
 @return The range within the receiver's floatVolumeData of the given Mask Run.
 
 @param maskRun The mask run for which to return a range
 */
- (NSRange)volumeRangeForROIMaskRun:(OSIROIMaskRun)maskRun;

/** Returns the range within the receiver's floatVolumeData of the given Mask Index.
 
 @return The range within the receiver's floatVolumeData of the given Mask Index.
 The length of the returned range will be 1.
 
 @param maskIndex The mask index for which to return a range
 */
- (NSRange)volumeRangeForROIMaskIndex:(OSIROIMaskIndex)maskIndex;

@end
