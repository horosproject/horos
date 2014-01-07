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

#import <AppKit/AppKit.h>
#import "ViewerController.h"

/** Window Controller for Toolbar */
@interface ToolbarPanelController : NSWindowController <NSToolbarDelegate>
{	
	NSToolbar               *toolbar;
	ViewerController		*viewer;
	BOOL					dontReenter;
}

@property (readonly) ViewerController *viewer;

- (long) fixedHeight;
+ (long) hiddenHeight;
- (long) exposedHeight;
+ (long) exposedHeight;
- (id)initForViewer: (ViewerController*) v withToolbar: (NSToolbar*) t;
- (NSToolbar*) toolbar;
+ (void) checkForValidToolbar;
- (void)applicationDidChangeScreenParameters:(NSNotification*)aNotification;

@end
