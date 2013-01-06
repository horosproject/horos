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

#import "QueryOutlineView.h"


@implementation QueryOutlineView

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	 
	if( c >= 0xF700 && c <= 0xF8FF) // Functions keys
		[super keyDown: event];
	else if( c == 9) // Tab Key
		[super keyDown: event];
	else
		[[[self window] windowController] keyDown: event];
}

- (BOOL)becomeFirstResponder
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"])
        [self setNeedsDisplay: YES];
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"])
        [self setNeedsDisplay: YES];
    
    return YES;
}
@end
