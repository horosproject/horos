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

@implementation ToolBarNSWindow

- (BOOL) canBecomeMainWindow
{
	return NO;
}

- (BOOL) canBecomeKeyWindow
{
	return YES;
}

- (void) orderOutIfNeeded:(id)sender
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideToolbarIfNotActive"] == NO)
    {
        BOOL found = NO;
        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
        {
            if( [v.window.screen isEqualTo: self.screen])
            {
                [self orderWindow: NSWindowBelow relativeTo: v.window.windowNumber];
                found = YES;
            }
        }
        
        if( found == NO)
            [super orderOut:sender];
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
