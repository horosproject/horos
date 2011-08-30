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
	long					screen;
	NSToolbar				*emptyToolbar;
	ViewerController		*viewer;
	BOOL					dontReenter;
}

@property (readonly) ViewerController *viewer;

- (long) fixedHeight;
- (long) hiddenHeight;
- (long) exposedHeight;
- (void) setToolbar :(NSToolbar*) tb viewer:(ViewerController*) v;
//- (void) fixSize;
- (void) toolbarWillClose :(NSToolbar*) tb;
- (id)initForScreen: (long) s;
- (NSToolbar*) toolbar;

@end
