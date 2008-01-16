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

#import "OsiriXToolbar.h"
#import "ViewerController.h"
#import "ToolbarPanel.h"

extern  ToolbarPanelController  *toolbarPanel[ 10];
extern  BOOL					USETOOLBARPANEL;

@implementation OsiriXToolbar

- (void)runCustomizationPalette:(id)sender
{
	[super runCustomizationPalette: sender];
}

@end
