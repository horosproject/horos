/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "ThumbnailsListPanel.h"
#import "ViewerController.h"
#import "AppController.h"
#import "NSWindow+N2.h"
#import "N2Debug.h"
#import "Notifications.h"
#import "ToolbarPanel.h"
#import "NavigatorWindowController.h"

static 	NSMutableDictionary *associatedScreen = nil;

@implementation ThumbnailsListPanel

@synthesize viewer;

+ (long) fixedWidth {

    float w = 0;
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
    {
        case -1: w = 100 * 0.8; break;
        case 0: w = 100; break;
        case 1: w = 100 * 1.3; break;
    }
    
    w += 10;
    
    return w;
}

+ (void) checkScreenParameters
{
    for( NSScreen *s in [NSScreen screens])
        [[AppController thumbnailsListPanelForScreen: s] applicationDidChangeScreenParameters: nil];
}

-(void)applicationDidChangeScreenParameters:(NSNotification*)aNotification
{
	if ([[NSScreen screens] count] <= screen)
		return;
    
	NSRect screenRect = [[[NSScreen screens] objectAtIndex:screen] visibleFrame];
	
	NSRect dstframe;
	dstframe.size.height = screenRect.size.height;
	dstframe.size.width = [ThumbnailsListPanel fixedWidth];
	dstframe.origin.x = screenRect.origin.x;
	dstframe.origin.y = screenRect.origin.y;
    dstframe.size.height -= [ToolbarPanelController exposedHeight];
    
    if( NavigatorWindowController.navigatorWindowController.window.screen == self.window.screen)
    {
        dstframe.origin.y += NavigatorWindowController.navigatorWindowController.window.frame.size.height;
        dstframe.size.height -= NavigatorWindowController.navigatorWindowController.window.frame.size.height;
    }
    
    if( NSEqualRects(self.window.frame, dstframe) == NO)
        [[self window] setFrame:dstframe display:YES];
}

- (id)initForScreen: (long) s
{
	screen = s;
	
	if (self = [super initWithWindowNibName:@"ThumbnailsList"])
	{
		thumbnailsView = nil;
		
        [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
        [[self window] setLevel: NSNormalWindowLevel];
        
        [self applicationDidChangeScreenParameters: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name: OsirixCloseViewerNotification object: nil];
		
		if( [AppController hasMacOSXSnowLeopard])
			[[self window] setCollectionBehavior: 1 << 6]; //NSWindowCollectionBehaviorIgnoresCycle
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:0];
        
        [self.window safelySetMovable:NO];
        
        if( self.window == nil)
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"UseFloatingThumbnailsList"];
	}
    
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    
	[thumbnailsView release];
	[super dealloc];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowAbove relativeTo: [[viewer window] windowNumber]];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible])
		{
			if( [[viewer window] isVisible])
				[[viewer window] makeKeyAndOrderFront: self];
            
            if( viewer && viewer.window.windowNumber > 0)
                [[self window] orderWindow: NSWindowAbove relativeTo: viewer.window.windowNumber];
            else
            {
                [self.window orderOut: self];
            }
		}
	}
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowAbove relativeTo: viewer.window.windowNumber];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		[[viewer window] makeKeyAndOrderFront: self];
        
		if( [[self window] isVisible] && viewer)
            [[self window] orderWindow: NSWindowAbove relativeTo: viewer.window.windowNumber];
        
		return;
	}
	
	if( [(NSWindow*)[aNotification object] level] != NSNormalWindowLevel)
        return;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
	{
		[[self window] orderOut:self];
		return;
	}
	
	//[self checkPosition];
	
    NSWindow *window = [aNotification object];
	if( [[window windowController] isKindOfClass:[ViewerController class]] && window.isVisible)
	{
		if( [[NSScreen screens] count] > screen)
		{
			if( [window screen] == [[NSScreen screens] objectAtIndex: screen])
			{
                if( viewer && viewer.window.windowNumber > 0)
                    [[self window] orderWindow: NSWindowAbove relativeTo: viewer.window.windowNumber];
			}
			else
				[self.window orderOut:self];
		}
	}
	
	[[self window] setFrame:[[self window] frame] display:YES];
}

- (void) thumbnailsListWillClose :(NSView*) tb
{
	if( thumbnailsView == tb)
	{
		[[self window] orderOut: self];
		
		if( [[self window] screen])
			[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: thumbnailsView]];
		else
			[associatedScreen removeObjectForKey: [NSValue valueWithPointer: thumbnailsView]];
		
		[associatedScreen removeObjectForKey: [NSValue valueWithPointer: thumbnailsView]];
		
		[thumbnailsView release];
		thumbnailsView = 0L;
		
        [viewer release];
		viewer = 0L;
	}
}

- (void) viewerWillClose: (NSNotification*) n
{
    if( [n object] == viewer)
    {
        [self setThumbnailsView: nil viewer: nil];
    }
}

- (NSView*) thumbnailsView
{
    return thumbnailsView;
}

- (void) setThumbnailsView:(NSView*) tb viewer:(ViewerController*) v
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
        return;
    
	if( associatedScreen == nil) associatedScreen = [[NSMutableDictionary alloc] init];
	
    NSDisableScreenUpdates();
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SeriesListVisible"] == NO)
        tb = nil;
    
    @try
    {
        if( tb == thumbnailsView)
        {
            if( tb && v && v.window.windowNumber > 0)
                [[self window] orderWindow: NSWindowAbove relativeTo: [[v window] windowNumber]];
        
            if( tb)
            {
                if( [associatedScreen objectForKey: [NSValue valueWithPointer: tb]] != [[self window] screen])
                {
                    if( [[self window] screen])
                        [associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: tb]];
                    else
                        [associatedScreen removeObjectForKey: [NSValue valueWithPointer: tb]];
                }
            }
            else
            {
                if( self.window.isVisible)
                    [self.window orderOut: self];
            }
            
            return;
        }
        
        [viewer release];
        viewer = [v retain];
        
        if( thumbnailsView != tb)
        {
            [superView addSubview: thumbnailsView];
            
            [thumbnailsView release];
            thumbnailsView = [tb retain];
            
            superView = [thumbnailsView superview];
            
            [self.window.contentView addSubview: thumbnailsView];
            [thumbnailsView setHidden: NO];
            [thumbnailsView setFrameSize: thumbnailsView.superview.frame.size];
        }
        
        if( thumbnailsView)
        {
            @try
            {
                if( [associatedScreen objectForKey: [NSValue valueWithPointer: thumbnailsView]] != [[self window] screen])
                {
                    if( [[self window] screen])
                        [associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: thumbnailsView]];
                    else
                        [associatedScreen removeObjectForKey: [NSValue valueWithPointer: thumbnailsView]];
                }
                
                if( [[viewer window] isKeyWindow])
                    [[self window] orderBack: self];
            }
            @catch (NSException *exception) {
                N2LogException( exception);
            }
        }
        else
        {
            if( self.window.isVisible)
                [self.window orderOut: self];
        }
        
        if( thumbnailsView && viewer)
        {
            [self applicationDidChangeScreenParameters:nil];
            
            if( [[viewer window] isKeyWindow])
                [[self window] orderWindow: NSWindowAbove relativeTo: [[viewer window] windowNumber]];
        }
            
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    @finally {
        NSEnableScreenUpdates();
    }
}

@end
