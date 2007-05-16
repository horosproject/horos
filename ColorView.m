//
//  ColorView.m
//  OsiriX
//
//  Created by joris on 15/05/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "ColorView.h"


@implementation ColorView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        color = [[NSColor clearColor] retain];
    }
    return self;
}

- (void) dealloc
{
	[color release];
	[super dealloc];
}

- (void)setColor:(NSColor*)newColor;
{
	[color release];
	color = newColor;
	[color retain];
}

- (void)drawRect:(NSRect)rect
{
    [color set];
	NSRectFill(rect);
	
    [[NSColor whiteColor] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	[NSBezierPath strokeRect:rect];
}

@end
