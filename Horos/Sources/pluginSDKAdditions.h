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
