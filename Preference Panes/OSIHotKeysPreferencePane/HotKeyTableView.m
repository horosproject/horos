//
//  HotKeyTableView.m
//  OSIHotKeysPreferencePane
//
//  Created by antoinerosset on 02.02.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HotKeyTableView.h"
#import "OSIHotKeysPref.h"

@implementation HotKeyTableView

- (void) keyDown:(NSEvent *)theEvent
{
	unichar		c = [[theEvent characters] characterAtIndex:0];
	
	if (c == NSUpArrowFunctionKey || c == NSDownArrowFunctionKey || c == NSLeftArrowFunctionKey || c == NSRightArrowFunctionKey || c == NSEnterCharacter || c == NSCarriageReturnCharacter || c == 27)
		return [super keyDown: theEvent];
	else
		[[OSIHotKeysPref currentKeysPref] keyDown: theEvent];
}

@end
