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

#import "ToolBarNSWindow.h"
#import "ToolbarPanel.h"

@implementation ToolBarNSWindow

- (BOOL) canBecomeMainWindow
{
	[self setDelegate: self];
	return NO;
}

- (BOOL) canBecomeKeyWindow
{
	return YES;
}

- (void)windowDidResize:(NSNotification *)notification
{
	[ (ToolbarPanelController*) [self windowController] fixSize];
}
@end
