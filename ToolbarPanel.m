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

#import "ToolbarPanel.h"
#import "ToolBarNSWindow.h"
#import "ViewerController.h"
#import "AppController.h"
#import "NSWindow+N2.h"

extern BOOL USETOOLBARPANEL;

static 	NSMutableDictionary *associatedScreen = nil;
static int increment = 0;

@implementation ToolbarPanelController

@synthesize viewer;

+ (long) fixedHeight {
	return 90;
}

+ (long) hiddenHeight {
	return 16;
}

+ (long) exposedHeight {
	return [self fixedHeight] - [self hiddenHeight];
}

/*- (void) checkPosition
{
	if( [[NSScreen screens] count] > screen)
	{
		NSPoint o = NSMakePoint([[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.x, [[[NSScreen screens] objectAtIndex: screen] visibleFrame].origin.y+[[[NSScreen screens] objectAtIndex: screen] visibleFrame].size.height);
	
//		[[self window] setFrameTopLeftPoint: o];		// fixSize will be called by this function
//		[self fixSize];
	}
}*/

/*- (void) fixSize
{
	NSRect  dstframe;
	NSArray *screens = [NSScreen screens];
	
	if( [screens count] > screen)
	{
		NSRect screenRect = [[screens objectAtIndex: screen] visibleFrame];
		
		dstframe.size.height = [ToolbarPanelController fixedHeight];
		dstframe.size.width = screenRect.size.width;
		dstframe.origin.x = screenRect.origin.x;
		dstframe.origin.y = screenRect.origin.y + screenRect.size.height - dstframe.size.height + [ToolbarPanelController hiddenHeight];
		
		[[self window] setFrame: dstframe display: NO];
	}
}*/

-(void)applicationDidChangeScreenParameters:(NSNotification*)aNotification {
	if ([[NSScreen screens] count] <= screen)
		return;
	
	NSRect screenRect = [[[NSScreen screens] objectAtIndex:screen] visibleFrame];
	
	NSRect dstframe;
	dstframe.size.height = [ToolbarPanelController fixedHeight];
	dstframe.size.width = screenRect.size.width;
	dstframe.origin.x = screenRect.origin.x;
	dstframe.origin.y = screenRect.origin.y + screenRect.size.height - dstframe.size.height + [ToolbarPanelController hiddenHeight];
	
	[[self window] setFrame:dstframe display:YES];
}

- (id)initForScreen: (long) s
{
	screen = s;
	
	if (self = [super initWithWindowNibName:@"ToolbarPanel"])
	{
		toolbar = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
		
		if( [AppController hasMacOSXSnowLeopard])
			[[self window] setCollectionBehavior: 1 << 6]; //NSWindowCollectionBehaviorIgnoresCycle
		
		[self applicationDidChangeScreenParameters:nil];
		
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
	[emptyToolbar release];
	[super dealloc];
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
			if( [[viewer window] isVisible])
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
	
	//[self checkPosition];
	
	if( [[[aNotification object] windowController] isKindOfClass:[ViewerController class]])
	{
		if( [[NSScreen screens] count] > screen)
		{
			if( [[aNotification object] screen] == [[NSScreen screens] objectAtIndex: screen])
			{
				[[viewer window] orderFront: self];
				
				[[self window] orderBack:self];
				[toolbar setVisible:YES];
				[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
				
				if( [[viewer window] isVisible] == NO)
				{
					[[self window] orderBack:self];
					[[self window] close];
					NSLog( @"problem.... ToolbarPanel.m");
				}
			}
			else
			{
				[self setToolbar: nil viewer: nil];
				[[self window] orderOut:self];
				NSLog(@"hide toolbar");
			}
		}
	}
	
	[[self window] setFrame:[[self window] frame] display:YES];
}

- (void) windowDidLoad
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:0];
	
	[super windowDidLoad];
	[self.window safelySetMovable:NO];
	
	emptyToolbar = [[NSToolbar alloc] initWithIdentifier: [NSString stringWithFormat:@"nstoolbar osirix %d", increment++]];
	[emptyToolbar setDelegate: self];
	[emptyToolbar insertItemWithItemIdentifier: @"emptyItem" atIndex: 0];
	
	[[self window] setToolbar: emptyToolbar];
	
	[[self window] setLevel: NSNormalWindowLevel];
	
//	[self checkPosition];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	 return [NSArray arrayWithObject: @"emptyItem"];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	  return [NSArray arrayWithObject: @"emptyItem"];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
	 NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	 
	 if ([itemIdent isEqualToString: @"emptyItem"])
	 {
		#define HEIGHT 53
		[toolbarItem setLabel: @"Aqpghil"];
		[toolbarItem setView: [[[NSView alloc] initWithFrame: NSMakeRect( 0, 0, HEIGHT, HEIGHT)] autorelease]];
		[toolbarItem setMinSize: NSMakeSize( HEIGHT, HEIGHT)];
		[toolbarItem setMaxSize: NSMakeSize( HEIGHT, HEIGHT)];
		[toolbarItem setTarget: nil];
		[toolbarItem setAction: nil];
    }
	else NSLog( @"********** ToolbarPanel.m uh??");
	
	 return [toolbarItem autorelease];
}

- (NSToolbar*) toolbar
{
	return toolbar;
}

- (void) toolbarWillClose :(NSToolbar*) tb
{
	if( toolbar == tb)
	{
//		((ToolBarNSWindow*) [self window]).willClose = YES;
		
		[[self window] orderOut: self];
		
		if( [[self window] screen])
			[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: toolbar]];
		else
			[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
		
		[[self window] setToolbar: emptyToolbar];
//		[[self window] orderOut: self];
		
		[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
		
		[toolbar release];
		toolbar = 0;
		
		viewer = 0;
		
//		((ToolBarNSWindow*) [self window]).willClose = NO;
	}
}

- (void) setToolbar :(NSToolbar*) tb viewer:(ViewerController*) v
{
	if( associatedScreen == nil) associatedScreen = [[NSMutableDictionary alloc] init];
	
	if( tb == nil)
		tb = emptyToolbar;
	
	if( tb == toolbar)
	{
		if( viewer != nil)
			[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	
		if( toolbar)
		{
			if( [associatedScreen objectForKey: [NSValue valueWithPointer: toolbar]] != [[self window] screen])
			{
				if( [[NSScreen screens] count] > 1)
					[[self window] setToolbar: emptyToolbar];
				[[self window] setToolbar: toolbar];
				
				if( [[self window] screen])
					[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: toolbar]];
				else
					[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
			}
		}
		else [[self window] orderOut: self];
		return;
	}
	
	viewer = v;
	
	if( toolbar != tb)
	{
		[toolbar release];
		toolbar = [tb retain];
		[toolbar setShowsBaselineSeparator: NO];
	}
	
	if( toolbar)
	{
		if( [associatedScreen objectForKey: [NSValue valueWithPointer: toolbar]] != [[self window] screen])
		{
			if( [[NSScreen screens] count] > 1)
				[[self window] setToolbar: emptyToolbar];	//To avoid the stupid add an item in customize toolbar.....
				
			if( [[self window] screen])
				[associatedScreen setObject: [[self window] screen] forKey: [NSValue valueWithPointer: toolbar]];
			else
				[associatedScreen removeObjectForKey: [NSValue valueWithPointer: toolbar]];
		}
		
		[[self window] setToolbar: toolbar];
		
		[[self window] setShowsToolbarButton:NO];
		[[[self window] toolbar] setVisible: YES];
		
		
		if( [[viewer window] isKeyWindow])
			[[self window] orderBack: self];
	}
	else
	{
		[[self window] orderOut: self];
	}
	
	if( toolbar)
	{
		[self applicationDidChangeScreenParameters:nil];
		
		if( [[viewer window] isKeyWindow])
			[[self window] orderWindow: NSWindowBelow relativeTo: [[viewer window] windowNumber]];
	}
}

@end
