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

#import "OsiriXToolbar.h"
#import "ViewerController.h"
#import "ToolbarPanel.h"
#import "NSWindow+N2.h"

extern  ToolbarPanelController *toolbarPanel[ 10];
extern  BOOL USETOOLBARPANEL;

@implementation OsiriXToolbar

- (void) checkIfCustomizationIsRunning:(NSTimer*) timer
{
	if( [self customizationPaletteIsRunning] == NO)
	{
		for( ViewerController *v in [ViewerController getDisplayed2DViewers])
			[[v window] safelySetMovable: YES];
		
		for( int i = 0 ; i < 10; i++)
		{
			if( [toolbarPanel[ i] toolbar] == self)
				[[toolbarPanel[ i] window] setLevel: NSNormalWindowLevel];
		}
		
		[timer invalidate];
	}
}

- (void)runCustomizationPalette:(id)sender
{
	for( ViewerController *v in [ViewerController getDisplayed2DViewers])
		[[v window] safelySetMovable: NO];
	
	for( int i = 0 ; i < 10; i++)
	{
		if( [toolbarPanel[ i] toolbar] == self)
			[[toolbarPanel[ i] window] setLevel: NSFloatingWindowLevel];
	}
	
	[super runCustomizationPalette: sender];
	
	[NSTimer scheduledTimerWithTimeInterval: 0.3 target: self selector: @selector( checkIfCustomizationIsRunning:) userInfo: nil repeats: YES];
}

@end
