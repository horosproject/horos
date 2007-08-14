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
#import "DCMView.h"
#import "DCMPix.h"
#import "ROI.h"
#import "ViewerController.h"

@interface ROIManagerController : NSWindowController
{
		ViewerController			*viewer;
		IBOutlet NSTableView		*tableView;
		float						pixelSpacingZ;
}
- (id) initWithViewer:(ViewerController*) v;
- (IBAction)deleteROI:(id)sender;
	// Table view data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex;
- (void) roiListModification :(NSNotification*) note;
- (void) fireUpdate: (NSNotification*) note;
@end
