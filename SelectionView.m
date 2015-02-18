/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
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

#import "SelectionView.h"


@implementation SelectionView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self acceptsFirstMouse:NO];
    }
    return self;
}

- (void) drawRect:(NSRect)aRect
{
	NSRect insideRect = NSMakeRect(aRect.origin.x+1,aRect.origin.y+1,aRect.size.width-2,aRect.size.height-2);
	NSBezierPath *outsidePath = [NSBezierPath bezierPathWithRect:aRect];
	NSBezierPath *insidePath = [NSBezierPath bezierPathWithRect:insideRect];
	
	[outsidePath setLineWidth:2.0];
		
	[[NSColor blackColor] set];
	[insidePath stroke];

	[[NSColor selectedTextBackgroundColor] set];
	[outsidePath stroke];
}

- (BOOL)mouse:(NSPoint)aPoint inRect:(NSRect)aRect;
{
	return NO;
}

- (BOOL)acceptsFirstResponder;
{
	return NO;
}

@end
