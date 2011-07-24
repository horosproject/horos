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
#import "Window3DController.h"

/** \brief  Window Controller for managing ROIVolume collection */

@interface ROIVolumeManagerController : NSWindowController <NSTableViewDataSource>
{
		Window3DController			*viewer;
		IBOutlet NSTableView		*tableView;
		IBOutlet NSTableColumn		*columnDisplay, *columnName, *columnVolume, *columnRed, *columnGreen, *columnBlue, *columnOpacity;
		NSMutableArray				*roiVolumes;//, *displayRoiVolumes;
		IBOutlet NSArrayController	*roiVolumesController;
		IBOutlet NSObjectController	*controllerAlias;
}

- (id) initWithViewer:(Window3DController*) v;
	// Table view data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void) setRoiVolumes: (NSMutableArray*) volumes;
- (NSMutableArray*) roiVolumes;

@end
