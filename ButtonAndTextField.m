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




#import "ButtonAndTextField.h"
#import "ButtonAndTextCell.h"

@implementation ButtonAndTextField

- (id)initWithFrame:(NSRect)frameRect{
	NSRect subFrame = NSMakeRect(frameRect.origin.x,frameRect.origin.y, frameRect.size.width/2, frameRect.size.height);
	NSRect textFrame = NSMakeRect(frameRect.origin.x + frameRect.size.width/2+ 10 ,frameRect.origin.y, frameRect.size.width/2 - 10, frameRect.size.height);

	NSLog(@"init Button and text cell");
	if (self = [super initWithFrame:subFrame]) {
		textField = [[NSTextField alloc] initWithFrame:textFrame];
		[[textField cell] setControlSize:[[self cell] controlSize]];
		[textField setStringValue:@"This is a test"];
	}
	return self;
}

- (void)dealloc{
	[textField release];
	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent{
}

@end
