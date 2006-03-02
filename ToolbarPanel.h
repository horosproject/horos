/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <AppKit/AppKit.h>


@interface ToolbarPanelController : NSWindowController {
	
	NSToolbar               *toolbar;
	long					screen;
	NSToolbar				*emptyToolbar;
}

+ (long) fixedHeight;
- (void) setToolbar :(NSToolbar*) tb;
- (void) fixSize;
- (void) toolbarWillClose :(NSToolbar*) tb;
- (id)initForScreen: (long) s;
- (NSToolbar*) toolbar;

@end
