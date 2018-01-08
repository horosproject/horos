/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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
//  NFHUDSliderCell.m
//  iLife HUD Slider
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFHUDSliderCell.h"
#import "NSImage+FrameworkImage.h"

@implementation NFHUDSliderCell

- (void)drawBarInside:(NSRect)cellFrame flipped:(BOOL)flipped
{
	NSImage *leftImage = [NSImage frameworkImageNamed:@"HUDSliderTrackLeft.tif"];
	NSImage *fillImage = [NSImage frameworkImageNamed:@"HUDSliderTrackFill.tif"];
	NSImage *rightImage = [NSImage frameworkImageNamed:@"HUDSliderTrackRight.tif"];
				
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
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [fillImage setScalesWhenResized:YES];
#pragma clang diagnostic pop
	[fillImage setSize:NSMakeSize(fillWidth, [fillImage size].height)];
	[fillImage drawAtPoint:NSMakePoint(fillX, y) fromRect: NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
}

- (void)drawKnob:(NSRect)rect
{
	NSImage *knob;
	
	if([self numberOfTickMarks] == 0)
		knob = [NSImage frameworkImageNamed:@"HUDSliderKnobRound.tif"];
	else
		knob = [NSImage frameworkImageNamed:@"HUDSliderKnob.tif"];
	
	float x = rect.origin.x + (rect.size.width - [knob size].width) / 2;
	float y = NSMaxY(rect) - (rect.size.height - [knob size].height) / 2 ;
	
	[knob drawAtPoint:NSMakePoint(x, y) fromRect: NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
}

-(NSRect)knobRectFlipped:(BOOL)flipped
{
	NSRect rect = [super knobRectFlipped:flipped];
	if([self numberOfTickMarks] > 0){
		rect.size.height+=2;
		return NSOffsetRect(rect, 0, flipped ? 2 : -2);
		}
	return rect;
}

- (BOOL)_usesCustomTrackImage
{
	return YES;
}

@end
