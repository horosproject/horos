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

- (void) resignMainWindow
{
}

- (BOOL) canBecomeMainWindow
{
	return YES;
}

- (BOOL) canBecomeKeyWindow
{
	return YES;
}

- (void) orderBack:(id)sender
{
    ViewerController *v = (ViewerController*) self.toolbar.delegate;
    
    if( v.window.isVisible)
    {
        NSDisableScreenUpdates();
        [super orderBack: self];
        [v.toolbarPanel applicationDidChangeScreenParameters: nil];
        [self orderWindow: NSWindowAbove relativeTo: v.window.windowNumber];
        NSEnableScreenUpdates();
    }
}

- (void) orderOut:(id)sender
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideToolbarIfNotActive"] == NO && [AppController USETOOLBARPANEL] == YES)
    {
        NSDisableScreenUpdates();
        
        ViewerController *v = [ViewerController frontMostDisplayed2DViewerForScreen: self.screen];
        
        if( v.toolbarPanel.window != self)
        {
            if( [self.toolbar customizationPaletteIsRunning] == NO)
                [super orderOut:sender];
        }
        
        if( v)
        {
            if( [v.toolbarPanel.window.toolbar customizationPaletteIsRunning] == NO)
                [v.toolbarPanel.window orderBack: self];
        }
        NSEnableScreenUpdates();
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
