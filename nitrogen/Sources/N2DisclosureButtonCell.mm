/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
	
    _attributes = [[NSMutableDictionary alloc] initWithDictionary:@{
//						NSForegroundColorAttributeName: [NSColor whiteColor],
//						NSFontAttributeName: [NSFont labelFontOfSize:[NSFont smallSystemFontSize]],
                                                                    }];
	
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
