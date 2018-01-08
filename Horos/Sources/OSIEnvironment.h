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

@class OSIVolumeWindow;
@class ViewerController;

/**  
 
 The OSIEnvironment class is the main access point into the Horos Plugin SDK. It provides access to the list of Viewer Windows that are currently open.
 Whenever a Viewer Window is opened or closed a `OSIEnvironmentOpenVolumeWindowsDidUpdateNotification` is posted. 
 
 */


extern NSString* const OSIEnvironmentOpenVolumeWindowsDidUpdateNotification; 


@interface OSIEnvironment : NSObject {
	NSMutableDictionary *_volumeWindows;
}


///-----------------------------------
/// @name Obtaining the Shared Environment Object
///-----------------------------------

/** Returns the shared `OSIEnvironment` instance.
 
 @return The shared `OSIEnvironment` instance
 */
+ (OSIEnvironment *)sharedEnvironment;

///-----------------------------------
/// @name Managing Volume Windows
///-----------------------------------

/** Returns the `OSIVolumeWindow` object that is paired with the given viewerController
 
 @return The Volume Window for cooresponding to the viewerController.
 @param viewerController The Viewer Controller for which to return a Volume Window.
 */
- (OSIVolumeWindow *)volumeWindowForViewerController:(ViewerController *)viewerController;

// I don't like the name because "open" can be taken to be meant as the verb not the adjective

/** Returns an array of all the displayed Volume Windows
 
 This property is observable using key-value observing.
 
 @return An array of OSIVolumeWindow objects.
 */
- (NSArray *)openVolumeWindows; // this is observeable

/** Returns the frontmost Volume Window
 
 @return The frontmost Volume Window.
 */
- (OSIVolumeWindow *)frontmostVolumeWindow; // not observable will return nil if there is no reasonable frontmost controller, 

// this probably should be mainVolumeWindow, but do all the windows behave nicely?

// not done

//- (NSArray *)openFloatVolumes; // returns OSIVolumeData
//- (NSArray *)openStudies; // returns all the studies that are open somewhere in the app // will this be KVO-able?


@end



///-----------------------------------
/// @name Notifications
///-----------------------------------

/** The notification.
 
 */
