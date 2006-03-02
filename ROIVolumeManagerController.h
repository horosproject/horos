//
//  ROIVolumeManagerController.h
//  OsiriX
//
//  Created by joris on 1/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ROIVolumeManagerController : NSWindowController
{
		NSWindowController			*viewer;
		IBOutlet NSTableView		*tableView;
		IBOutlet NSTableColumn		*columnDisplay, *columnName, *columnVolume, *columnRed, *columnGreen, *columnBlue, *columnOpacity;
		NSMutableArray				*roiVolumes;//, *displayRoiVolumes;
		IBOutlet NSArrayController	*roiVolumesController;
		IBOutlet NSObjectController	*controllerAlias;
}

- (id) initWithViewer:(NSWindowController*) v;
	// Table view data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void) setRoiVolumes: (NSMutableArray*) volumes;
- (NSMutableArray*) roiVolumes;

@end
