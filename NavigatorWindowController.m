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
#import "AppController.h"

static NavigatorWindowController *nav = 0L;

@implementation NavigatorWindowController

@synthesize navigatorView;

+ (NavigatorWindowController*) navigatorWindowController
{
	return nav;
}

- (id)initWithViewer:(ViewerController*)viewer;
{
	self = [super initWithWindowNibName:@"Navigator"];
	if (self != nil) {
		[self setViewer:viewer];
		nav = self;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeViewerNotification:) name:@"CloseViewerNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:@"NSApplicationWillBecomeActiveNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:@"NSApplicationWillResignActiveNotification" object:nil];
	}
	return self;
}

- (void)awakeFromNib; 
{
	[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)setViewer:(ViewerController*)viewer;
{
	viewerController = viewer;
	[self initView];
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
}

- (void)closeViewerNotification:(NSNotification*)notif;
{
	if([[ViewerController getDisplayed2DViewers] count]==0)
	{
		[[self window] close];
	}
}

- (void) adjustWindowPosition;
{
	dontReEnter = YES;
	
	float height = [[self window] frame].size.height;
	[[self window] setFrame:[NavigatorView rect] display:YES];
	
	if([NavigatorView rect].size.height != height) [[AppController sharedAppController] tileWindows:self];
	
	dontReEnter = NO;
}

- (void)windowDidMove:(NSNotification *)notification
{
	if( dontReEnter == NO)
		[self adjustWindowPosition];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
	if( dontReEnter == NO)
		[self adjustWindowPosition];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] orderOut:self];
	[self release];
}

- (void)dealloc
{
	NSLog(@"NavigatorWindowController dealloc");
	nav = 0L;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
	[[AppController sharedAppController] tileWindows:self];
}

- (void)computeMinAndMaxSize;
{	
	NSSize maxSize = [navigatorView frame].size;
	maxSize.height += 16; // 16px for the title bar
	float screenWidth = [[[viewerController window] screen] frame].size.width;
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