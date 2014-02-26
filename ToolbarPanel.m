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
#import "N2Debug.h"
#import "Notifications.h"

extern BOOL USETOOLBARPANEL;

//static int MacOSVersion109orHigher = -1;

static int fixedHeight = 92;

@implementation ToolbarPanelController

@synthesize viewer;

- (long) fixedHeight
{
    return fixedHeight;
}

+ (long) hiddenHeight {
	return 15;
}

- (long) exposedHeight {
	return fixedHeight - [ToolbarPanelController hiddenHeight];
}

+ (long) exposedHeight {
	return fixedHeight - [ToolbarPanelController hiddenHeight];
}

+ (void) checkForValidToolbar
{
    // Check that a toolbar is visible for all screens
    for( NSScreen *s in [NSScreen screens])
    {
        ViewerController *v = [ViewerController frontMostDisplayed2DViewerForScreen: s];
        
        if( v) {
            if( [v.toolbarPanel.window.toolbar customizationPaletteIsRunning] == NO)
                [v.toolbarPanel.window orderBack: self];
        }
    }
}

-(void)applicationDidChangeScreenParameters:(NSNotification*)aNotification
{
	NSRect screenRect = [viewer.window.screen visibleFrame];
	
	NSRect dstframe;
	dstframe.size.height = [self fixedHeight];
	dstframe.size.width = screenRect.size.width;
	dstframe.origin.x = screenRect.origin.x;
	dstframe.origin.y = screenRect.origin.y + screenRect.size.height - dstframe.size.height + [ToolbarPanelController hiddenHeight];
	
    if( NSEqualRects( dstframe, self.window.frame) == NO)
        [[self window] setFrame:dstframe display:YES];
}

- (id)initForViewer:(ViewerController *)v withToolbar:(NSToolbar *)t
{
	if (self = [super initWithWindowNibName:@"ToolbarPanel"])
	{
		toolbar = [t retain];
        viewer = [v retain];
		
        [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
        [[self window] setToolbar: toolbar];
        [[self window] setLevel: NSNormalWindowLevel];
        [[self window] makeMainWindow];
        
        [toolbar setShowsBaselineSeparator: NO];
        [toolbar setVisible: YES];
        
        [self applicationDidChangeScreenParameters: nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:NSApp];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name: OsirixCloseViewerNotification object: nil];
		
		if( [AppController hasMacOSXSnowLeopard])
			[[self window] setCollectionBehavior: 1 << 6]; //NSWindowCollectionBehaviorIgnoresCycle
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:0];
        
        [self.window safelySetMovable:NO];
        [self.window setShowsToolbarButton:NO];
	}
	
	return self;
}

- (void) close
{
    [self.window orderOut: self];
    
    [super close];
    
    self.window.toolbar = nil;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [viewer release];
    [toolbar release];
	[super dealloc];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
        if( [[viewer window] isVisible])
        {
            if( [self.window.toolbar customizationPaletteIsRunning] == NO)
            {
                [[viewer window] makeKeyAndOrderFront: self];
                [self.window orderBack: self];
            }
        }
        else
            [self.window orderOut: self];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
        if( [[viewer window] isVisible])
        {
            if( [self.window.toolbar customizationPaletteIsRunning] == NO)
            {
                [[viewer window] makeKeyAndOrderFront: self];
                [self.window orderBack: self];
            }
        }
        else
            [self.window orderOut: self];
	}
}

- (NSToolbar*) toolbar
{
	return toolbar;
}

- (void) viewerWillClose: (NSNotification*) n
{
    if( [n object] == viewer)
        [self.window orderOut: self];
}
@end
