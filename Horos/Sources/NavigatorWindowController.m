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

#import "NavigatorWindowController.h"
#import "ViewerController.h"
#import "AppController.h"
#import "Notifications.h"
#import "ThumbnailsListPanel.h"

static NavigatorWindowController *nav = nil;

@implementation NavigatorWindowController

@synthesize navigatorView;
@synthesize viewerController;

+ (NavigatorWindowController*) navigatorWindowController
{
	return nav;
}

- (id)initWithViewer:(ViewerController*)viewer;
{
	self = [super initWithWindowNibName:@"Navigator"];
	if (self != nil)
	{
		nav = self;
		
		[self window];	// generate the awake from nib ! and populates the nib variables like navigatorView
		
		[self setViewer: viewer];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeViewerNotification:) name:OsirixCloseViewerNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:NSApplicationWillBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:NSApplicationWillResignActiveNotification object:nil];
	}
	return self;
}

- (void)awakeFromNib; 
{
	[[self window] setAcceptsMouseMovedEvents:YES];
    [scrollview setScrollerStyle: NSScrollerStyleLegacy];
}

- (void)setViewer:(ViewerController*)viewer;
{
	[navigatorView saveTransformForCurrentViewer];
	BOOL needsUpdate = NO;
	if( viewerController != viewer)
	{
		[viewerController release];
		viewerController = [viewer retain];
		needsUpdate = YES;
	}
	
	if( [viewerController isDataVolumicIn4D: YES] == NO)
	{
		NSLog( @"unsupported data for 4D");
		[[self window] close];
		return;
	}
	
	if(needsUpdate)[self initView];
	
	//[navigatorView setViewer];
}

- (void)initView;
{
	[navigatorView setViewer];
	[self computeMinAndMaxSize];
	[self adjustWindowPosition];
	[[self window] setAcceptsMouseMovedEvents:YES];
	[[self window] makeFirstResponder:navigatorView];
}

- (IBAction)showWindow:(id)sender
{
	[self initView];
	[super showWindow:sender];
    [ThumbnailsListPanel checkScreenParameters];
}

- (void)closeViewerNotification:(NSNotification*)notif;
{
//	if( [notif object] == viewerController)
//	{
//		[self setViewer: nil];
//	}
	
	if([[ViewerController getDisplayed2DViewers] count] == 0)
	{
		[[self window] close];
	}
}

- (void) adjustWindowPositionWithTiling: (BOOL) withTiling;
{
	dontReEnter = YES;
	
	int height = [[self window] frame].size.height;
	
	NSRect r = [NavigatorView rect];
	
    NSScreen *screen = [[[AppController sharedAppController] viewerScreens] objectAtIndex: 0];
    
	r.origin.y = [screen visibleFrame].origin.y;
	r.size.height = height + [[self window] frame].origin.y - r.origin.y;
	
	if( r.size.height > [NavigatorView rect].size.height)
		r.size.height = [NavigatorView rect].size.height;
		
	if( r.size.height < [navigatorView minimumWindowHeight])
		r.size.height = [navigatorView minimumWindowHeight];
	
	[[self window] setFrame: r display:YES];
	
	if( r.size.height != height && withTiling == YES)
		[[AppController sharedAppController] tileWindows: nil];
	
	dontReEnter = NO;
}

- (void) adjustWindowPosition;
{
	return [self adjustWindowPositionWithTiling: YES];
}

- (void)windowDidMove:(NSNotification *)notification
{
	if( dontReEnter == NO)
		[self adjustWindowPositionWithTiling: YES];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
	if( dontReEnter == NO)
		[self adjustWindowPositionWithTiling: YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[self window] orderOut:self];
    
	[self autorelease];
}

- (void)dealloc
{
	NSLog(@"NavigatorWindowController dealloc");
	nav = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[viewerController release];
	[super dealloc];
	[[AppController sharedAppController] tileWindows: nil];
    [ThumbnailsListPanel checkScreenParameters];
}

- (void)computeMinAndMaxSize;
{	
	NSSize maxSize = [navigatorView frame].size;
	maxSize.height += 16; // 16px for the title bar
    
    NSScreen *screen = [[[AppController sharedAppController] viewerScreens] objectAtIndex: 0];
    
	float screenWidth = [screen frame].size.width;
	maxSize.width = screenWidth;
	if([[self window] frame].size.width < [navigatorView frame].size.width) maxSize.height += 11; // 11px for the horizontal scroller

	[[self window] setMaxSize:maxSize];
	
	NSSize minSize = NSMakeSize(navigatorView.thumbnailWidth, navigatorView.thumbnailHeight);
	minSize.height += 16; // 16px for the title bar
	minSize.width = screenWidth;
	if([[self window] frame].size.width < [navigatorView frame].size.width) minSize.height += 11; // 11px for the horizontal scroller
	
	[[self window] setMinSize:minSize];
}

- (void)setWindowLevel:(NSNotification*)notification;
{
	NSString *name = [notification name];
	if([name isEqualToString:NSApplicationWillBecomeActiveNotification])
		[[self window] setLevel:NSFloatingWindowLevel];
	else if([name isEqualToString:NSApplicationWillResignActiveNotification])
		[[self window] setLevel:[[viewerController window] level]];
}

@end
