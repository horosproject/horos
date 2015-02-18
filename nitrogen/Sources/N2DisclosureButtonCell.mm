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

#import <N2DisclosureButtonCell.h>

@implementation N2DisclosureButtonCell
@synthesize attributes = _attributes;

-(id)init {
	self = [super init];
	[self setBezelStyle:NSDisclosureBezelStyle];
	[self setButtonType:NSOnOffButton];
	[self setState:NSOnState];
	[self setControlSize:NSSmallControlSize];
	[self sendActionOn:NSLeftMouseDownMask];
	
	_attributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
//						[NSColor whiteColor], NSForegroundColorAttributeName,
//						[NSFont labelFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
					NULL] retain];
	
	return self;
}

-(void)dealloc {
	[_attributes release];
	[super dealloc];
}

-(NSRect)titleRectForBounds:(NSRect)bounds {
//	NSSize size = [super cellSizeForBounds:bounds];
	NSSize textSize = [self textSize];
	return NSMakeRect(bounds.origin.x+bounds.size.width, bounds.origin.y, textSize.width, textSize.height);
}

-(NSSize)textSize {
	return [[self title] sizeWithAttributes:_attributes];
}

-(NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
	[[self title] drawInRect:frame withAttributes:_attributes];
	return frame;
}

-(id)copyWithZone:(NSZone *)zone {
    N2DisclosureButtonCell* copy = [super copyWithZone:zone];
    
    copy->_attributes = [self.attributes copyWithZone:zone];
    
    return copy;
}

@end
