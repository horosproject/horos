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
#import "OSIROIManager.h"

// there is something fundamentally wrong with this. A lot of viewers display multiple images, and that MUST be handled correctly. This is particularly important for the plugin API
// because lots of plugins are used to perform specific tasks and that ofter requires windows with multiple view. It would be really nice if we could 

/**  
 
 Each instance of a OSIVolumeWindow is paired was an OsiriX `ViewerController`. The goal of the Volume Window is to provide a simplified interface to common tasks that are inherently difficult to do directly with a `ViewerController`. 
 
 */

extern NSString* const OSIVolumeWindowDidCloseNotification; 


extern NSString* const OSIVolumeWindowWillChangeDataNotification;
extern NSString* const OSIVolumeWindowDidChangeDataNotification;

// This is a peer of the ViewerController. It provides an abstract and cleaner interface to the ViewerController
// for now 

// it really is the window that is showing stuff, so it should be possible to ask the window what the hell it is showing.

// a study is a tag on images, but many differnt studies could be shown in the same window. a specific volume definitly belongs to a study, and it should be possible to
// ask the environment what all the open studies are.



@class OSIFloatVolumeData;
@class OSIROIManager;
@class ViewerController;

@interface OSIVolumeWindow : NSObject <OSIROIManagerDelegate>  {
	ViewerController *_viewerController; // this is retained
    NSMutableDictionary *_generatedFloatVolumeDataToInvalidate; // we want to keep track of OSIFloatVolumeData objects that have been generated so that we can invalidate them. The key is the pointer to the NSData in the ViewerController
    NSMutableDictionary *_generatedFloatVolumeDatas; // The lazily created VolumeDatas
    NSMutableArray *_OSIROIs; // additional ROIs that have been added to the VolumeWindow 
	OSIROIManager *_ROIManager; // should this really be an ROI manager? or is that another beast altogether?
    BOOL _dataLoaded;
}

///-----------------------------------
/// @name Managing the Volume Window
///-----------------------------------

/** Returns YES if the `ViewerController` paired with this Volume Window is still open.
 
 @see viewerController
 */
- (BOOL)isOpen; // observable. Is this VolumeWindow actually connected to a ViewerController. If the ViewerController is closed, the connection will be lost
// but if the plugin is lazy and doesn't close things properly, at least the ViewerController will be released, the memory will be released, and the plugin will just be holding on to
// a super lightweight object

/** Returns the title of the window represented by this Volume Window.
 
 @return The title of the window represented by this Volume Window.
 */
- (NSString *)title;

/** Returns YES if the `ViewerController` paired with this Volume Window has all it's data loaded, ROIs for example will not be accessible until all the data is loaded.
 Observable.
 
 @see viewerController
 */
- (BOOL)isDataLoaded;

///-----------------------------------
/// @name Managing ROIs
///-----------------------------------

/** Returns the OSIROIManager for this Volume Window.
  
 @return The title of the window represented by this Volume Window.
 
 @warning *Important:* The Volume Window is the delegate of this ROIManger, you should never change its delegate.
 */
- (OSIROIManager *)ROIManager; // no not mess with the delegate of this ROI manager, but feel free to ask if for it's list of ROIs

///-----------------------------------
/// @name Dealing with Volume Data
///-----------------------------------

// not done
//- (NSArray *)selectedROIs; // observable list of selected ROIs
//

/** Returns the dimensions available in the Volume Window.
 
 Volume Data objects represent a volume in the three natural dimensions. Additional dimensions such as _movieIndex_ may be available in a given Volume Window. This method returns the names of the available dimensions as NSString objects
 
 @return An array of NSString objects representing the names of the available dimensions.
 */
- (NSArray *)dimensions; // dimensions other than the 3 natural dimensions, time for example

/** Returns the depth, or avaibable frames in the given dimension.
 
 @return The number of frames available in the given dimension.
 @param dimension The dimension name for which the depth is sought
 */
- (NSUInteger)depthOfDimension:(NSString *)dimension; // I don't like this name


/** Returns a Volume Data object that can be used to access the data at the  given dimension coordinates
 
 @warning *Important:*  OsiriX allocates and deallocates memory at sometimes seemingly odd times, if the OSIFloatVolumeData all of a sudden is invalid, call this function again to try to get a new one 
 
 @return The Volume Data for the dimension coordinates.
 @param dimensions An array of dimension names as NSString objects.
 @param indexes An array of indexes as NSNumber objects in the corresponding dimension 
 */
- (OSIFloatVolumeData *)floatVolumeDataForDimensions:(NSArray *)dimensions indexes:(NSArray *)indexes;

/** Returns a Volume Data object that can be used to access the data at the  given dimension coordinates
 
 @warning *Important:*  OsiriX allocates and deallocates memory at sometimes seemingly odd times, if the OSIFloatVolumeData all of a sudden is invalid, call this function again to try to get a new one 
 
 @return The Volume Data for the dimension coordinates.
 @param firstDimension The first dimension name.
 @param ... First the index in the firstDimension as an NSNumber object, then a null-terminated list of alternating dimension names and indexes.
 */
- (OSIFloatVolumeData *)floatVolumeDataForDimensionsAndIndexes:(NSString *)firstDimension, ... NS_REQUIRES_NIL_TERMINATION;
//
//- (OSIFloatVolumeData *)displayedFloatVolumeData;

///-----------------------------------
/// @name Dealing with ROIs that are not backed by OsiriX ROIs
///-----------------------------------

- (void)addOSIROI:(OSIROI *)roi;
- (void)removeOSIROI:(OSIROI *)roi;
- (NSArray *)OSIROIs; // observable

///-----------------------------------
/// @name Breaking out of the SDK
///-----------------------------------

/** Returns the shared `ViewerController` this Volume Window is paired with.
 
 If the `ViewerController` instance this Volume Window is paired with closes, viewerController will return nil. 
 
 @return The shared `ViewerController` this Volume Window is paired with.
 @see isOpen
 */
- (ViewerController *)viewerController; // if you really want to go into the depths of OsiriX, use at your own peril!


@end
