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

#import <Cocoa/Cocoa.h>
#import "OSIROIMask.h"
// this is the representation of the data within the generic ROI

/**  
 
 The `OSIROIFloatPixelData` class is used to access pixel in a OSIFloatVolumeData instance data under a given OSIROIMask.
 
 */


@class OSIFloatVolumeData;
@class OSIStudy;

@interface OSIROIFloatPixelData : NSObject {
    NSMutableDictionary *_valueCache;
    NSData *_floatData;
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
- (float)intensityMean;

/** Returns the maximum intensity of the pixels under the mask.
 
 @return The maximum intensity of the pixels under the mask
 */
- (float)intensityMax;

/** Returns the minumim intensity of the pixels under the mask.
 
 @return The minumim intensity of the pixels under the mask
 */
- (float)intensityMin;

/** Returns the median intensity of the pixels under the mask.
 
 @return The media intensity of the pixels under the mask
 */
- (float)intensityMedian;

/** Returns the interquartile range of the intensity of the pixels under the mask.
 
 @return The interquartile range of the intensity of the pixels under the mask
 */
- (float)intensityInterQuartileRange;

/** Returns the standard deviation of the intensity of the pixels under the mask.
 
 @return The standard deviation of the intensity of the pixels under the mask
 */
- (float)intensityStandardDeviation;

/** Returns by reference the quartiles of the intensity of the pixels under the mask. 
 
 Pass NULL to any parameter you don't care about
 
 */
- (void)getIntensityMinimum:(float *)minimum firstQuartile:(float *)firstQuartile secondQuartile:(float *)secondQuartile thirdQuartile:(float *)thirdQuartile maximum:(float *)maximum;


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

/** Returns a NSData containing the values of the reciever's data
  
 @return a NSData containing the values of the reciever's data.
 
 */
- (NSData *)floatData;


@end
