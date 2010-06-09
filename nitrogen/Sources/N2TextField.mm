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

#import "N2TextField.h"


@implementation N2TextField

@synthesize invalidContentBackgroundColor;

-(id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	return self;
}

-(void)dealloc {
	self.invalidContentBackgroundColor = NULL;
	[super dealloc];
}

-(void)refreshBackground {
	if (invalidContentBackgroundColor && self.formatter) {
		id obj = NULL;
		BOOL ok = [self.formatter getObjectValue:&obj forString:self.stringValue errorDescription:NULL];
		[self setBackgroundColor: ok? [NSColor whiteColor] : invalidContentBackgroundColor ];
		[self setNeedsDisplay:YES];
	}
}

-(void)setInvalidContentBackgroundColor:(NSColor*)color {
	[invalidContentBackgroundColor release];
	invalidContentBackgroundColor = [color retain];
	[self refreshBackground];
}

-(void)keyDown:(NSEvent*)event {
	[super keyDown:event];
	[self refreshBackground];
}

-(void)textDidChange:(NSNotification*)notif {
	[super textDidChange:notif];
	[self refreshBackground];
}

-(void)setObjectValue:(id)value {
	[super setObjectValue:value];
	[self refreshBackground];
}

-(void)setStringValue:(id)value {
	[super setStringValue:value];
	[self refreshBackground];
}

@end
