//
//  NFHUDPopUpButtonCell.m
//  iLife HUD PopUpButton
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFHUDPopUpButtonCell.h"
#import "NSImage+FrameworkImage.h"

@implementation NFHUDPopUpButtonCell

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSString *state = [self isHighlighted] ? @"P" : @"N";
	NSImage *leftImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDPopUpLeft%@.tif", state]];
	NSImage *fillImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDPopUpFill%@", state]];
	NSImage *rightImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"HUDPopUpRight%@", state]];
				
	NSSize size = [leftImage size];
	float addX = size.width / 2.0;
	float y = NSMaxY(cellFrame) - (cellFrame.size.height-size.height)/2.0;
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

- (NSRect)titleRectForBounds:(NSRect)bounds;
{
	return NSOffsetRect([super titleRectForBounds:bounds], 2, 0);
}

-(void)drawTitleWithFrame:(NSRect)frame inView:(NSView *)view
{
	NSMutableDictionary *attrs = [[[NSMutableDictionary alloc]init] autorelease];
	[attrs addEntriesFromDictionary:[[self attributedTitle] attributesAtIndex:0 effectiveRange:NULL]];
	NSFont *font = [NSFont fontWithName:@"LucidaGrande" size:11.0];
	[attrs setObject:font forKey:NSFontAttributeName];
	[attrs setObject:[NSColor whiteColor]forKey:NSForegroundColorAttributeName];
	NSMutableAttributedString *attrStr = [[[NSMutableAttributedString alloc] initWithString:[self title] attributes:attrs] autorelease];
	frame = [self titleRectForBounds:frame];
	[super drawTitle:attrStr withFrame:frame inView:view];
}

@end
