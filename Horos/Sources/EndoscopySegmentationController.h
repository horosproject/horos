/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - GPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/



#import <Cocoa/Cocoa.h>
#import "OSIVoxel.h"

@class ViewerController;

/** \brief   Window Controller for Centerline segementation. 
* 
*   Window Controller for Centerline segementation
*   DEPRECATED -- PLANNED FOR DELETION
*/
@interface EndoscopySegmentationController : NSWindowController {
	ViewerController		*_viewer, *_resultsViewer;
	NSMutableArray			*_seeds;
	NSPoint					_startingPoint;
}

- (NSArray *)seeds;
- (void)addSeed:(id)seed;
- (IBAction)calculate: (id)sender;

@end
