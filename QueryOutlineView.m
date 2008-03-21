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

#import "QueryOutlineView.h"


@implementation QueryOutlineView

- (void)keyDown:(NSEvent *)event
{
	unichar c = [[event characters] characterAtIndex:0];
	 
	if( c >= 0xF700 && c <= 0xF8FF) // Functions keys
		[super keyDown: event];
	else
		[[[self window] windowController] keyDown: event];
}
@end
