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
#import "OSIGeometry.h"
#import <OpenGL/CGLTypes.h>

// abstract 

//@class OSIROIFloatPixelData;
//@class OSIFloatVolumeData;
@class OSIStudy;
@class ROI;
@class OSIROIMask;
@class OSIFloatVolumeData;
@class OSIROIFloatPixelData;

// this is an abstract class
// how do you identify an ROI? Does an ROI have an ID and that is how you know what an ROI is, or is the ROI the actual object...
// polygon compilation ROI

/**  
 
 OSIROI is an abstract ROI class. It is the super class of all OsiriX SDK plugin ROI types and provides basic support for accessing pixel data and properties common to all ROIs.
 
 Subclasses must implement convexHull, name, label, homeFloatVolumeData, and ROIMaskForFloatVolumeData:.
 
 @warning *Important:* For now the Plugin SDK classes only works with intensity data and does not work with RGB data.

 
 */


@interface OSIROI : NSObject {
}

//@property (nonatomic, readwrite, assign) void *context;

//- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;

///-----------------------------------
/// @name Getting ROI Attributes
///-----------------------------------


/** Returns the name of the receiver.
  
 @return The name of the receiver
 */
- (NSString *)name;

/** Returns a reasonable label to print for the receiver.
 
 The OSIROI implementation of this method concatenates the labels for all the available metrics.
 
 Concrete subclasses may override this method to return more meaningful labels.
 
 @return A reasonable label to print for the receiver.
 @see labelForMetric:
 @see metricNames
 */
- (NSString *)label;

/** Returns an array of `NSString` objects that represent the names of all the metrics that can be recovered from this ROI.
  
 Concrete subclasses may override this method to return additional metrics.
 
 @return An array of `NSString` objects that represent the names of all the metrics that can be recovered from this ROI.
 @see label
 @see labelForMetric:
 @see unitForMetric:
 @see valueForMetric:
*/
- (NSArray *)metricNames;

/** Returns a reasonable label to print for the given metric.
 
 Concrete subclasses may override this method to return a reasonable label for specific metrics.
 
 @return A reasonable label to print for the given metric.
 @param metric The metric name for which to return a label.
 @see label
 @see metricNames
 @see unitForMetric:
 @see valueForMetric:
 */
- (NSString *)labelForMetric:(NSString *)metric;

/** Returns the unit for a given metric.
 
 Concrete subclasses may override this method to return units for any additional metric they may define.
 
 @return The unit for a given metric.
 @param metric The metric name for which to return the unit.
 @see label
 @see metricNames
 @see labelForMetric:
 @see valueForMetric:
 */
- (NSString *)unitForMetric:(NSString *)metric;

/** Returns the value for a given metric.
 
 Concrete subclasses may override this method to return values for any additional metric they may define.
  
 @return The value for a given metric.
 @param metric The metric name for which to return a value.
 @see label
 @see metricNames
 @see labelForMetric:
 @see unitForMetric:
 */
- (id)valueForMetric:(NSString *)metric;

///-----------------------------------
/// @name Getting Pixel/Voxel Data values
///-----------------------------------


//- (OSIStudy *)study;

/** Returns the float pixel data under this ROI.
 
 This is a convenience for getting the pixel data in the receiver's home float volume.
 
 @return The float pixel data under this ROI.
 @see homeFloatVolumeData
 @see ROIFloatPixelDataForFloatVolumeData:
 @see ROIMaskForFloatVolumeData:
 */
- (OSIROIFloatPixelData *)ROIFloatPixelData; // convenience method

/** Returns the a OSIROIFloatPixelData object that can be used to access pixels under this ROI in the given Float Volume data.

 This is a convenience for getting the ROI Mask for the given Float Volume Data and generating a Float Pixel Data object from that mask and the given Float Volume Data.

 @return The a OSIROIFloatPixelData object that can be used to access pixels under this ROI in the given Float Volume data.
 @param floatVolume the Float Volume Data for which to generate a Float Pixel Data object.
 @see homeFloatVolumeData
 @see ROIFloatPixelData
 @see ROIMaskForFloatVolumeData:
 */
- (OSIROIFloatPixelData *)ROIFloatPixelDataForFloatVolumeData:(OSIFloatVolumeData *)floatVolume; // convenience method

/** Returns the a OSIROIMask object that represents the volume the receiver covers in the given Float Volume data.
 
 Concrete subclasses must override this method.
 
 @return The a OSIROIFloatPixelData object that can be used to access pixels under this ROI in the given Float Volume data.
 @param floatVolume the Float Volume Data for which to generate a mask.
 @see homeFloatVolumeData
 @see ROIFloatPixelData
 @see ROIFloatPixelDataForFloatVolumeData:
 */
- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume;
//- (BOOL)containsVector:(OSIVector)vector;


/** Returns the original Float Volume Data on which the receiver or the OsiriX `ROI` objects this reciever represents were drawn on.
 
 Concrete subclasses must override this method.
 
 @warning *Important:* This concept will probably go away since, for example, a coalesced ROI might span mutiple volumes, (such as time).

 
 @return The a OSIROIFloatPixelData object that can be used to access pixels under this ROI in the given Float Volume data
 @see ROIFloatPixelData
 @see ROIMaskForFloatVolumeData:
 @see ROIFloatPixelDataForFloatVolumeData:
 */
- (OSIFloatVolumeData *)homeFloatVolumeData; // the volume data on which the ROI was drawn

//- (NSDictionary *)dictionaryRepresentation; // make sure this is a plist serializable dictionary;

///-----------------------------------
/// @name Representing the general position of the ROI
///-----------------------------------


/** Returns an array of points that represent the outside bounds of the ROI.
 
 Note: For now these points don't actually need to lie on the convex hull, but the ROI *must* be within the convex hull of these points.
 
 These points are in patient space.
 
 Concrete subclasses must implement this method.
 
 @return An array of points that represent the outside bounds of the ROI.
 */
- (NSArray *)convexHull; // OSIVectors stored in NSValue objects. The ROI promises to live inside of these points

///-----------------------------------
/// @name Drawing
///-----------------------------------

/** Overridden by subclasses to draw the receiver’s image within the passed-in rectangle..
 
 The receiver is expected to draw into OpenGL. The current OpenGL model matrix is set up so that rendering is in pix space.
  
 @param dirtyRect A rectangle defining the dirty area of the view that requires redrawing.
 @param dicomToPixTransform A matrix that converts points in Patient Space (Dicom space in mm) into pix space.
 
 @return An array of points that represent the outside bounds of the ROI.
 */
- (void)drawSlab:(OSISlab)slab inCGLContext:(CGLContextObj)glContext pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform;

// for drawing in 3D what we really want is for the ROI to return a VTK actor, and then it will be the actor and VTK that will decide how to draw

///-----------------------------------
/// @name Breaking out of the SDK
///-----------------------------------

/** Returns an array of OsiriX `ROI` objects that are the basis of this OSIROI.
 
 Concrete subclasses need to implement this method if the receiver depends on OsiriX `ROI` objects.
 
 @return An array of OsiriX `ROI` objects that are the basis of this OSIROI.
 */
- (NSArray *)osiriXROIs; // returns the primitive ROIs that are represented by this object

// at some point I would love to support drawing new ROI types...

@end
