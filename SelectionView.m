//
//  SelectionView.m
//  OsiriX
//
//  Created by joris on 10/05/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import "SelectionView.h"


@implementation SelectionView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self acceptsFirstMouse:NO];
    }
    return self;
}

- (void) drawRect:(NSRect)aRect
{
	[[NSColor selectedTextBackgroundColor] set];
	NSRectFill(aRect);
	[[NSColor blackColor] set];
	NSRectFill(NSMakeRect(aRect.origin.x+1,aRect.origin.y+1,aRect.size.width-2,aRect.size.height-2));
}

- (BOOL)mouse:(NSPoint)aPoint inRect:(NSRect)aRect;
{
	return NO;
}

- (BOOL)acceptsFirstResponder;
{
	return NO;
}

@end
