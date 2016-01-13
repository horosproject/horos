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
//
//  NFHUDButtonCell.m
//  iLife HUD Button
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFHUDButtonCell.h"
#import "NSImage+FrameworkImage.h"

@implementation NFHUDButtonCell

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView
{
	if([self showsStateBy] == NSNoCellMask){
		[super drawImage:image withFrame:frame inView:controlView];
		return;
	}
	
	NSString *state = [self isHighlighted] ? @"P" : @"N";
	NSString *position = [self intValue] ? @"On" : @"Off";
	NSImage *checkImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDCheckbox%@%@.tif", position, state]];
	
	NSSize size = [checkImage size];
	float addX = 2;
	float y = NSMaxY(frame) - (frame.size.height-size.height)/2.0;
	float x = frame.origin.x+addX;
	
	[checkImage drawAtPoint:NSMakePoint(x, y) fromRect: NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if([self showsStateBy] != NSNoCellMask){
		[super drawWithFrame:cellFrame inView:controlView];
		return;
	}

	NSString *state = [self isHighlighted] ? @"P" : @"N";
	NSImage *leftImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDButtonLeft%@.tif", state]];
	NSImage *fillImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDButtonFill%@", state]];
	NSImage *rightImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDButtonRight%@", state]];
				
	NSSize size = [leftImage size];
	float addX = size.width / 2.0;
	float y = NSMaxY(cellFrame) - (cellFrame.size.height-size.height)/2.0 - 1;
	float x = cellFrame.origin.x+addX;
	float fillX = x + size.width;
	float fillWidth = cellFrame.size.width - size.width - addX;
	
	[leftImage drawAtPoint:NSMakePoint(x, y) fromRect: NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];

	size = [rightImage size];
	addX = size.width / 2.0;
	x = NSMaxX(cellFrame) - size.width - addX;
	fillWidth -= size.width+addX;
	
	[rightImage drawAtPoint:NSMakePoint(x, y) fromRect: NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
	
	[fillImage setScalesWhenResized:YES];
	[fillImage setSize:NSMakeSize(fillWidth, [fillImage size].height)];
	[fillImage drawAtPoint:NSMakePoint(fillX, y) fromRect: NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
	
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
