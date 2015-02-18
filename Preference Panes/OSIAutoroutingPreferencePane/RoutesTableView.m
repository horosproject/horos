/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
