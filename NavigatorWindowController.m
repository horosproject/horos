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

#import "NavigatorWindowController.h"
#import "ViewerController.h"

@implementation NavigatorWindowController

- (id)initWithViewer:(ViewerController*)viewer;
{
	self = [super initWithWindowNibName:@"Navigator"];
	if (self != nil) {
		viewerController = viewer;
	}
	return self;
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	[navigatorView setViewer:viewerController];
	NSSize size = [navigatorView frame].size;
	size.height += 27;
	[[self window] setMaxSize:size];
	[[self window] setFrame:NSMakeRect([[self window] frame].origin.x, [[self window] frame].origin.x, [[self window] frame].size.width, size.height) display:YES];
	
	NSSize minSize = NSMakeSize(navigatorView.thumbnailWidth, navigatorView.thumbnailHeight);
	minSize.height += 27;
	[[self window] setMinSize:minSize];

}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[self release];
}

@end