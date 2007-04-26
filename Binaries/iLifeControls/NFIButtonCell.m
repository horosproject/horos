//
//  NFIButtonCell.m
//  iLife Button
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFIButtonCell.h"
#import "NSImage+FrameworkImage.h"

@implementation NFIButtonCell

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView
{
	if([self showsStateBy] == NSNoCellMask){
		[super drawImage:image withFrame:frame inView:controlView];
		return;
	}
	
	NSString *state = [self isEnabled] ? ([self isHighlighted] ? @"P" : @"N") : @"D";
	NSString *position = [self intValue] ? @"On" : @"Off";
	NSImage *checkImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"Checkbox%@%@.tiff", position, state]];
	
	NSSize size = [checkImage size];
	float addX = 2;
	float y = NSMaxY(frame) - (frame.size.height-size.height)/2.0;
	float x = frame.origin.x+addX;
	
	[checkImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if([self showsStateBy] != NSNoCellMask){
		[super drawInteriorWithFrame:cellFrame inView:controlView];
		return;
	}

	NSString *state = [self isEnabled] ? ([self isHighlighted] ? @"P" : @"N") : @"D";
	NSImage *leftImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"ButtonLeft%@.tiff", state]];
	NSImage *fillImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"ButtonFill%@", state]];
	NSImage *rightImage = [NSImage frameworkImageNamed:[NSString stringWithFormat:@"ButtonRight%@", state]];
				
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
}

- (void)drawImageWithFrame:(NSRect)frame inView:(NSButton *)view
{
	NSImage *image;
	if ([self isHighlighted] && [self alternateImage])
		image = [self alternateImage];
	else
		image = [self image];

	[super drawImage:image withFrame:NSOffsetRect(frame, 0, ([view isFlipped] ? -1 : 1)) inView:view];
}

- (void)drawWithFrame:(NSRect)frame inView:(NSButton *)view
{
	[self drawInteriorWithFrame:frame inView:view];
	
	if([self showsStateBy] != NSNoCellMask){
		return;
	}
	
	[NSGraphicsContext saveGraphicsState]; 
	NSShadow* theShadow = [[NSShadow alloc] init]; 
	[theShadow setShadowOffset:NSMakeSize(0, -1)]; 
	[theShadow setShadowBlurRadius:0.9]; 

	[theShadow setShadowColor:[[NSColor whiteColor]
             colorWithAlphaComponent:1.0]]; 
	
	[theShadow set];
	
	if ([self image] && [self imagePosition] != NSNoImage)
		[self drawImageWithFrame:frame inView:view];
	else
		[self drawTitle:[view attributedTitle] withFrame:frame inView:view];
	
	[NSGraphicsContext restoreGraphicsState];
	[theShadow release];
}

@end
