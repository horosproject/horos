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
