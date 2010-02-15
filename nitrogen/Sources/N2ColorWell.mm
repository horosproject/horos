/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "N2ColorWell.h"
#import "NSButton+N2.h"
#import <algorithm>

@interface N2ColorWellCell : NSButtonCell {
}

@end
@implementation N2ColorWellCell

-(void)drawBezelWithFrame:(NSRect)frame inView:(N2ColorWell*)colorWell {
	[NSGraphicsContext saveGraphicsState];
	
	[super drawBezelWithFrame:frame inView:colorWell];
	
	NSRect colorRect = NSInsetRect(frame, std::max(CGFloat(5), frame.size.width/10), std::max(CGFloat(3), frame.size.height/3));
	[[[colorWell color] colorWithAlphaComponent:0.5] setFill];
	[[NSBezierPath bezierPathWithRoundedRect:colorRect xRadius:colorRect.size.height/2 yRadius:colorRect.size.height/2] fill];
	colorRect = NSInsetRect(colorRect, 1, 1);
	[[colorWell color] setFill];
	[[NSBezierPath bezierPathWithRoundedRect:colorRect xRadius:colorRect.size.height/2 yRadius:colorRect.size.height/2] fill];

	[NSGraphicsContext restoreGraphicsState];
}

@end


@implementation N2ColorWell
@synthesize color = _color;

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	NSCell* cell = [[N2ColorWellCell alloc] init];
	[cell setControlSize:NSMiniControlSize];
	[self setCell:cell];
	[cell release];
	
	[self setBezelStyle:NSRecessedBezelStyle];
	[self setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
	
	[self setTitle:@""];
	[self setAction:@selector(click:)];
	[self setTarget:self];
	
	return self;
}

-(void)dealloc {
	[self setColor:NULL];
	[super dealloc];
}

-(void)setColor:(NSColor*)color {
	[_color release];
	_color = [color retain];
	[self setNeedsDisplay:YES];
}

-(void)takeColorFrom:(id)sender {
	[self setColor:[sender color]];
}

-(void)click:(NSNotification*)notification {
	NSColorPanel* panel = [NSColorPanel sharedColorPanel];
//	if (![panel isVisible] || [panel target] != self) {
		[panel setTarget:self];
		[panel setAction:@selector(takeColorFrom:)];
		[panel setShowsAlpha:NO];
		[panel setColor:[self color]];
		[panel setContinuous:YES];
		[panel orderFront:self];
//	} else [panel orderOut:self];
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	if (NSIsEmptyRect([self frame]))
		return [super optimalSizeForWidth:width];
	return [self frame].size;
}

@end
