//
//  LLMPRView.m
//  OsiriX
//
//  Created by Joris Heuberger on 08/05/06.
//  Copyright 2006 HUG. All rights reserved.
//

#import "OrthogonalMPRController.h"
#import "LLMPRView.h"
#import "DCMCursor.h"

@implementation LLMPRView

- (void) keyDown:(NSEvent *)event
{
	unichar		c = [[event characters] characterAtIndex:0];

	if (c == NSUpArrowFunctionKey)
	{
		[(LLMPRController*)controller shiftView: self x:0 y:-1];
	}
	else if (c == NSDownArrowFunctionKey)
	{
		[(LLMPRController*)controller shiftView: self x:0 y:1];
	}
	else if (c == NSLeftArrowFunctionKey)
	{
		[(LLMPRController*)controller shiftView: self x:-1 y:0];
	}
	else if (c == NSRightArrowFunctionKey)
	{
		[(LLMPRController*)controller shiftView: self x:1 y:0];
	}
	else if (c == NSEnterCharacter || c == NSCarriageReturnCharacter || c == 27) // 27 = Escape
	{
		return; // desactivation of full window mode
	}
	else
	{
		[super keyDown:event];
	}
	[viewer refreshSubtractedViews];
}

- (void) mouseDown:(NSEvent *)event
{
	if ([event clickCount] == 2)
	{
		return; // desactivation of full window mode
	}
	else
	{
		//[controller saveCrossPositions];
		int tool = [self getTool: event];
		if( tool == tBonesRemoval)
		{
			[(LLMPRController*)controller removeBonesAtX:(int)mouseXPos y:(int)mouseYPos fromView:self];
		}
		else [super mouseDown:event];
	}
}

-(void) setCursorForView: (long) tool
{
	NSCursor	*c;
	
	if (tool == tBonesRemoval)
	{
		c = [NSCursor bonesRemovalCursor];
		if( c != cursor)
		{
			[cursor release];
			cursor = [c retain];
			[[self window] invalidateCursorRectsForView: self];
		}
	}
	else
		[super setCursorForView: tool];	
}

-(long)thickSlabX;
{
	return thickSlabX;
}

-(long)thickSlabY;
{
	return thickSlabY;
}

- (void) dealloc {
	//NSLog(@"LLMPR View dealloc");
	[super dealloc];
}


@end
