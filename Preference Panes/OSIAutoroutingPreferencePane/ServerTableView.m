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

#import "ServerTableView.h"
#import "OSIAutoroutingPreferencePanePref.h"

@implementation ServerTableView

- (void)keyDown:(NSEvent *)event{
	unichar c = [[event characters] characterAtIndex:0];
	if ((c == NSDeleteCharacter || c == NSBackspaceCharacter) && [self selectedRow] >= 0 && [self numberOfRows] > 0)
	{
		if( NSRunInformationalAlertPanel(NSLocalizedStringFromTableInBundle( @"Delete Route", nil, [NSBundle bundleForClass: [OSIAutoroutingPreferencePanePref class]], 0L), NSLocalizedStringFromTableInBundle( @"Are you sure you want to delete the selected route?", nil, [NSBundle bundleForClass: [OSIAutoroutingPreferencePanePref class]], 0L), NSLocalizedStringFromTableInBundle(@"OK", nil, [NSBundle bundleForClass: [OSIAutoroutingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle bundleForClass: [OSIAutoroutingPreferencePanePref class]], nil), nil) == NSAlertDefaultReturn)
			[[self delegate] deleteSelectedRow:self];
	}
	else
		 [super keyDown:event];
}

@end
