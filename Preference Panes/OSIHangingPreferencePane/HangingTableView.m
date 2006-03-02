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


#import "HangingTableView.h"
#import "OSIHangingPreferencePanePref.h"

@implementation HangingTableView

- (void)keyDown:(NSEvent *)event{
	unichar c = [[event characters] characterAtIndex:0];
	if ((c == NSDeleteCharacter || c == NSBackspaceCharacter) && [self selectedRow] > 0) {
			[[self delegate] deleteSelectedRow:self];
	}
	else
		 [super keyDown:event];
}

@end
