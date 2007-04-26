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
	NSImage *checkImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDCheckbox%@%@.tiff", position, state]];
	
	NSSize size = [checkImage size];
	float addX = 2;
	float y = NSMaxY(frame) - (frame.size.height-size.height)/2.0;
	float x = frame.origin.x+addX;
	
	[checkImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if([self showsStateBy] != NSNoCellMask){
		[super drawWithFrame:cellFrame inView:controlView];
		return;
	}

	NSString *state = [self isHighlighted] ? @"P" : @"N";
	NSImage *leftImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDButtonLeft%@.tiff", state]];
	NSImage *fillImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDButtonFill%@", state]];
	NSImage *rightImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDButtonRight%@", state]];
				
	NSSize size = [leftImage size];
	float addX = size.width / 2.0;
	float y = NSMaxY(cellFrame) - (cellFrame.size.height-size.height)/2.0 - 1;
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
