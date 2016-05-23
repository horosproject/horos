//
//  OnOffSwitchControl.m
//  OnOffSwitchControl
//
//  Created by Peter Hosey on 2010-01-10.
//  Copyright 2010 Peter Hosey. All rights reserved.
//
//  Extended by Dain Kaplan on 2012-01-31.
//  Copyright 2012 Dain Kaplan. All rights reserved.
//

#import "OnOffSwitchControl.h"
#import "OnOffSwitchControlCell.h"

@implementation OnOffSwitchControl

+ (void) initialize {
	[self setCellClass:[OnOffSwitchControlCell class]];
}
- (void) awakeFromNib {
	[[self class] setCellClass:[OnOffSwitchControlCell class]];
}

- (void) keyDown:(NSEvent *)event {
	unichar character = [[event characters] characterAtIndex:0UL];
	switch (character) {
		case NSLeftArrowFunctionKey:
		case NSRightArrowFunctionKey:
			//Do nothing (yet). We'll handle this in keyUp:.
			break;
		default:
			[super keyDown:event];
			break;
	}
}

- (void) keyUp:(NSEvent *)event {
	unichar character = [[event characters] characterAtIndex:0UL];
	switch (character) {
		case NSLeftArrowFunctionKey:
			switch ([self state]) {
				case NSOffState:
					NSBeep();
					break;
				case NSMixedState:
					[self setState:NSOffState];
					break;
				case NSOnState:
					if ([self allowsMixedState])
						[self setState:NSMixedState];
					else
						[self setState:NSOffState];
					break;
			}
			break;
		case NSRightArrowFunctionKey:
			switch ([self state]) {
				case NSOffState:
					if ([self allowsMixedState])
						[self setState:NSMixedState];
					else
						[self setState:NSOnState];
					break;
				case NSMixedState:
					[self setState:NSOnState];
					break;
				case NSOnState:
					NSBeep();
					break;
			}
			break;
		default:
			[super keyUp:event];
			break;
	}
}

@end
