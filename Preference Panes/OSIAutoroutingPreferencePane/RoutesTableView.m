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

#import "RoutesTableView.h"
#import "OSIAutoroutingPreferencePanePref.h"

@implementation RoutesTableView

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	if ((c == NSDeleteCharacter || c == NSBackspaceCharacter) && [self selectedRow] >= 0 && [self numberOfRows] > 0)
	{
		if( NSRunInformationalAlertPanel(NSLocalizedString( @"Delete Route", 0L), NSLocalizedString( @"Are you sure you want to delete the selected route?", 0L), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
			[(OSIAutoroutingPreferencePanePref*) [self delegate] deleteSelectedRow:self];
	}
	else
		 [super keyDown:event];
}

@end
