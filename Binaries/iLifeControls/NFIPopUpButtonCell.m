//
//  NFIPopUpButtonCell.m
//  iLife PopUp Button
//
//  Created by Sean Patrick O'Brien on 9/25/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFIPopUpButtonCell.h"
#import "NSImage+FrameworkImage.h"

@implementation NFIPopUpButtonCell

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSString *state = [self isEnabled] ? ([self isHighlighted] ? @"P" : @"N") : @"D";
	NSImage *leftImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"PopUpLeft%@.tiff", state]];
	NSImage *fillImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"PopUpFill%@", state]];
	NSImage *rightImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"PopUpRight%@", state]];
				
	NSSize size = [leftImage size];
	float addX = size.width / 2.0;
	float y = NSMaxY(cellFrame) - (cellFrame.size.height-size.height)/2.0;
	float x = cellFrame.origin.x+addX;
	float fillX = x + size.width;
	float fillWidth = cellFrame.size.width - size.width - addX;
	
	[leftImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];

	size = [rightImage size];
	addX = size.width / 2.0;
	x = NSMaxX(cellFrame) - size.width - addX;
	fillWidth -= size.width+addX;
	
	[rightImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
	
	[fillImage setScalesWhenResized:YES];
	[fillImage setSize:NSMakeSize(fillWidth, [fillImage size].height)];
	[fillImage compositeToPoint:NSMakePoint(fillX, y) operation:NSCompositeSourceOver];
	
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
