/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

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
