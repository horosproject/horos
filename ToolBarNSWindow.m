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

#import "ToolBarNSWindow.h"
#import "ToolbarPanel.h"
#import "ViewerController.h"
#import "N2Debug.h"
#import "AppController.h"

@implementation ToolBarNSWindow

- (BOOL) canBecomeMainWindow
{
	return NO;
}

- (BOOL) canBecomeKeyWindow
{
	return YES;
}

- (void) orderOut:(id)sender
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideToolbarIfNotActive"] == NO && [AppController USETOOLBARPANEL] == YES)
    {
        ViewerController *v = [ViewerController frontMostDisplayed2DViewerForScreen: self.screen];
        if( v)
        {
            [self.windowController setToolbar: v.toolbar viewer: v];
            [self orderWindow: NSWindowBelow relativeTo: v.window.windowNumber];
        }
        else
        {
            [self.windowController setToolbar: nil viewer: nil];
            [super orderOut:sender];
        }
    }
    else
        [super orderOut:sender];
}

-(NSTimeInterval)animationResizeTime:(NSRect)newFrame {
	return 0;
}

-(NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen*)screen {
	return frameRect; // not movable, and OsiriX knows where to place toolbars ;)
}

@end
