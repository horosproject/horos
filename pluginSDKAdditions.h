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
#import "ViewerController.h"
#import "N3Geometry.h"
#import "DCMPix.h"

@class OSIFloatVolumeData;
@class OSIVolumeWindow;

/** Additional methods used by the Plugin SDK
 
 */


@interface ViewerController (PluginSDKAdditions)


///-----------------------------------
/// @name Working with the Volume Window
///-----------------------------------

/** Returns the Volume Window that is paired with the receiver.
 
 @return The Volume Window that is paired with the receiver.
 
 @see [OSIEnvironment volumeWindowForViewerController:]
 @see [OSIEnvironment openVolumeWindows]
 */
- (OSIVolumeWindow *)volumeWindow;

///-----------------------------------
/// @name Getting Float Volume Data Objects
///-----------------------------------

/** Returns the Float Volume Data that represents that float data at given movie index.
 
 @return The Float Volume Data that represents that float data at given movie index.
 
 @param index The movie index for which to return a Float Volume Data.
*/
//- (OSIFloatVolumeData *)floatVolumeDataForMovieIndex:(long)index;

@end

/** Additional methods used by the Plugin SDK
 
 */


@interface DCMPix (PluginSDKAdditions)

///-----------------------------------
/// @name Getting a Transformation Matrix
///-----------------------------------

/** Returns a transformation matrix that converts pixel coordinates in the receiver to coordinates in Patient Space (Dicom space in mm).

 See also:
 
 [DCMView viewToPixTransform] defined in DCMView(CPRAdditions) in CPRMPRDCMView.h
 
 [DCMView pixToSubDrawRectTransform] defined in DCMView(CPRAdditions) in CPRMPRDCMView.h

 @return A transformation matrix that converts pixel coordinates in the receiver to coordinates in Patient Space (Dicom space in mm).
 */
- (N3AffineTransform)pixToDicomTransform; // converts points in the DCMPix's coordinate space ("Slice Coordinates") into the DICOM space (patient space with mm units)

@end
