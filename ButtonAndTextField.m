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




#import "ButtonAndTextField.h"
#import "ButtonAndTextCell.h"

@implementation ButtonAndTextField

- (id)initWithFrame:(NSRect)frameRect{
	NSRect subFrame = NSMakeRect(frameRect.origin.x,frameRect.origin.y, frameRect.size.width/2, frameRect.size.height);
	NSRect textFrame = NSMakeRect(frameRect.origin.x + frameRect.size.width/2+ 10 ,frameRect.origin.y, frameRect.size.width/2 - 10, frameRect.size.height);

	NSLog(@"init Button and text cell");
	if (self = [super initWithFrame:subFrame]) {
		textField = [[NSTextField alloc] initWithFrame:textFrame];
		[[textField cell] setControlSize:[[self cell] controlSize]];
		[textField setStringValue:@"This is a test"];
	}
	return self;
}

- (void)dealloc{
	[textField release];
	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent{
}

@end
