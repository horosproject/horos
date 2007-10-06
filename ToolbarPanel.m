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




#import "ToolbarPanel.h"
#import "ViewerController.h"

extern BOOL USETOOLBARPANEL;

@implementation ToolbarPanelController

@synthesize viewer;

+ (long) fixedHeight
{
	return 88;
}

- (void) fixSize
{
	NSRect  dstframe;
	NSRect screenRect    = [[[NSScreen screens] objectAtIndex: screen] visibleFrame];
	
//	if( [[[self window] toolbar] isVisible] == NO) dstframe.size.height = 12;
//	else dstframe.size.height = [ToolbarPanelController fixedHeight];

//	if( [[[self window] toolbar] isVisible] == NO)
//		[[[self window] toolbar] setVisible: YES];

	dstframe.size.height = [ToolbarPanelController fixedHeight];
	dstframe.size.width = screenRect.size.width;
	dstframe.origin.x = screenRect.origin.x;
	dstframe.origin.y = screenRect.origin.y + screenRect.size.height -dstframe.size.height;
	
//	NSLog(@"X: %2.2f Y:%2.2f", dstframe.origin.x, dstframe.origin.y);
	
	[[self window] setFrame:dstframe display: YES];
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
		[self fixSize];
		[[self window] setFrameTopLeftPoint: NSMakePoint([[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.x, [[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.y+[[[NSScreen screens] objectAtIndex: screen] visibleFrame].size.height)];
	}
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible]) [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible])
		{
			[[viewer window] makeKeyAndOrderFront: self];
			[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
		}
	}
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		if( [[self window] isVisible]) [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		[[viewer window] makeKeyAndOrderFront: self];
		if( [[self window] isVisible]) [[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
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
			[[viewer window] orderFront: self];
			
			[[self window] orderBack:self];
			[toolbar setVisible:YES];
			[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
			
			NSLog(@"show toolbar");
		}
		else
		{
			[self setToolbar: 0L viewer: 0L];
			[[self window] orderOut:self];
			NSLog(@"hide toolbar");
		}
	}
//	else
//	{
//		[[self window] orderOut:self];
//		NSLog(@"hide toolbar");
//	}
	
	[[self window] setFrame:[[self window] frame] display:YES];
}

- (void) windowDidLoad
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:0];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WindowDidMoveNotification:) name:NSWindowDidMoveNotification object:0];
	
	[super windowDidLoad];
	
	emptyToolbar = [[NSToolbar alloc] initWithIdentifier: @"nstoolbar osirix"];
	[[self window] setToolbar: emptyToolbar];
	
	
	[[self window] setLevel: NSNormalWindowLevel];
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
		viewer = 0;
	}
}

- (void) setToolbar :(NSToolbar*) tb viewer:(ViewerController*) v
{
	if( tb == toolbar)
	{
		[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
		return;
	}
	
	viewer = v;
	
	if( toolbar != tb)
	{
		[toolbar release];
		toolbar = [tb retain];
	}
	
	if( toolbar)
	{
		[[self window] setToolbar: 0L];
		[[self window] setToolbar: toolbar];
		[[self window] setShowsToolbarButton:NO];
		[[[self window] toolbar] setVisible: YES];
	}

	if( toolbar) [[self window] orderBack: self];
	else [[self window] orderOut: self];
	
	if( toolbar)
	{
		[[self window] setFrameTopLeftPoint: NSMakePoint([[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.x, [[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.y+[[[NSScreen screens] objectAtIndex: screen] visibleFrame].size.height)];
		[self fixSize];
		
		[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
}

@end
