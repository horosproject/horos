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

#import "ServerTableView.h"
#import "OSIAutoroutingPreferencePanePref.h"

@implementation ServerTableView

- (void)keyDown:(NSEvent *)event{
	unichar c = [[event characters] characterAtIndex:0];
	if ((c == NSDeleteCharacter || c == NSBackspaceCharacter) && [self selectedRow] >= 0 && [self numberOfRows] > 0)
	{
		if( NSRunInformationalAlertPanel(NSLocalizedString(@"Delete Route", 0L), NSLocalizedString(@"Are you sure you want to delete the selected route?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil) == NSAlertDefaultReturn)
			[[self delegate] deleteSelectedRow:self];
	}
	else
		 [super keyDown:event];
}

@end
