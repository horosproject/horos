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




#import "ToolbarPanel.h"
#import "ViewerController.h"

extern BOOL USETOOLBARPANEL;

@implementation ToolbarPanelController

+ (long) fixedHeight
{
	return 88;
}

- (void) fixSize
{
	NSRect  dstframe;
	NSRect screenRect    = [[[NSScreen screens] objectAtIndex: screen] visibleFrame];

	dstframe.size.height = [ToolbarPanelController fixedHeight];
	dstframe.size.width = screenRect.size.width;
	dstframe.origin.x = screenRect.origin.x;
	dstframe.origin.y = screenRect.origin.y + screenRect.size.height -dstframe.size.height;
	
//	NSLog(@"X: %2.2f Y:%2.2f", dstframe.origin.x, dstframe.origin.y);
	
	[[self window] setFrame:dstframe display:YES];
	
}

- (id)initForScreen: (long) s
{
	screen = s;
	
	if (self = [super initWithWindowNibName:@"ToolbarPanel"])
	{
		toolbar = 0L;
	}
	
	return self;
}

- (void) dealloc
{
	[emptyToolbar release];
	[super dealloc];
}


- (void) WindowDidMoveNotification:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		[[self window] setFrameTopLeftPoint: NSMakePoint([[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.x, [[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.y+[[[NSScreen screens] objectAtIndex: screen] visibleFrame].size.height)];

	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		return;
	}
	
	if( [(NSWindow*)[aNotification object] level] != NSNormalWindowLevel) return;
	
	if( USETOOLBARPANEL == NO)
	{
		[[self window] orderOut:self];
		return;
	}
	
	[[self window] setFrameTopLeftPoint: NSMakePoint([[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.x, [[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.y+[[[NSScreen screens] objectAtIndex: screen] visibleFrame].size.height)];
	[self fixSize];
	
	if( [[[aNotification object] windowController] isKindOfClass:[ViewerController class]])
	{
		if( [[aNotification object] screen] == [[NSScreen screens] objectAtIndex: screen])
		{
			
			[[self window] orderBack:self];
			[toolbar setVisible:YES];
			NSLog(@"show toolbar");
		}
		else
		{
			[self setToolbar: 0L];
			[[self window] orderOut:self];
			NSLog(@"hide toolbar");
		}
	}
	else
	{
		[[self window] orderOut:self];
		NSLog(@"hide toolbar");
	}
	
	[[self window] setFrame:[[self window] frame] display:YES];
}

- (void) windowDidLoad
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WindowDidMoveNotification:) name:NSWindowDidMoveNotification object:0];
	
	[super windowDidLoad];
	
	emptyToolbar = [[NSToolbar alloc] initWithIdentifier: @"nstoolbar osirix"];
	[[self window] setToolbar: emptyToolbar];
}

- (NSToolbar*) toolbar
{
	return toolbar;
}

- (void) toolbarWillClose :(NSToolbar*) tb
{
	if( toolbar == tb)
	{
		[[self window] setToolbar: 0L];
		
		[toolbar release];
		toolbar = 0;
	}
}

- (void) setToolbar :(NSToolbar*) tb
{
	if( tb == toolbar) return;
	
	[toolbar release];
	
	toolbar = [tb retain];
	
	if( toolbar)
	{
		[[self window] setToolbar: 0L];
		[[self window] setShowsToolbarButton:NO];
		[[[self window] toolbar] setVisible: YES];
		[[self window] setToolbar: toolbar];
	}

	if( toolbar) [[self window] orderBack: self];
	else [[self window] orderOut: self];
	
	if( toolbar)
	{
		[[self window] setFrameTopLeftPoint: NSMakePoint([[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.x, [[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.y+[[[NSScreen screens] objectAtIndex: screen] visibleFrame].size.height)];
		[self fixSize];
	}
}

@end
