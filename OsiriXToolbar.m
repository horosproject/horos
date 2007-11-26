//
//  OsiriXToolbar.m
//  OsiriX
//
//  Created by Antoine Rosset on 26.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "OsiriXToolbar.h"
#import "ViewerController.h"
#import "ToolbarPanel.h"

extern  ToolbarPanelController  *toolbarPanel[ 10];
extern  BOOL					USETOOLBARPANEL;

@implementation OsiriXToolbar

- (void)runCustomizationPalette:(id)sender
{
	if( USETOOLBARPANEL)
	{
		NSArray	*viewers = [ViewerController getDisplayed2DViewers];
	
		for( ViewerController *v in viewers)
			[v refreshToolbar];
		
		for( ViewerController *v in viewers)
		{
			if( [v toolbar] == self)
				[v refreshToolbar];
		}
	}
	
	[super runCustomizationPalette: sender];
}

@end
