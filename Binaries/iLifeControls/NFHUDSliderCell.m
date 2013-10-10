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
	
	[fillImage setScalesWhenResized:YES];
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
