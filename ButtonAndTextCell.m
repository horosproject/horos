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




#import "ButtonAndTextCell.h"



@implementation ButtonAndTextCell



- (id)initImageCell:(NSImage *)anImage{
	if (self = [super initImageCell:anImage])
		NSLog(@"initImageCell");
	return self;
}

- (id)initTextCell:(NSString *)aString{
	if (self = [super initTextCell:aString])
		NSLog(@"initTextCell");
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder{
	if (self = [super initWithCoder:decoder]) {

		buttonCell = [[NSButtonCell alloc] initImageCell:nil];
		[buttonCell setButtonType:NSSwitchButton];
		[buttonCell  setControlSize:NSMiniControlSize];
		[buttonCell setState:NSOnState];
		
		//textCell = [[NSTextFieldCell alloc] initTextCell:@""];
		[self setBezeled:YES];
		[self setBezelStyle:NSTextFieldSquareBezel];
		[self setDrawsBackground:YES];
		[self setControlSize:NSMiniControlSize];
		[self setEditable:YES];
		
		
		
	}

	return self;
}

-(void)dealloc{
	[textCell release];
	[super dealloc];
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
//	NSRect buttonFrame = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width/2- 10 , cellFrame.size.height);
//	NSRect textFrame = NSMakeRect(cellFrame.size.width/2 + 10, cellFrame.origin.y, cellFrame.size.width/2 - 10, cellFrame.size.height);
//	NSLog(@"draw Interior x:%f y:%f, width %f height %f", cellFrame.origin.x,cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
	//NSLog(@"drawInteriorWithFrame:");
	[super drawInteriorWithFrame:cellFrame inView:controlView];
//	[textCell drawInteriorWithFrame:textFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	NSRect textFrame = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - 120, cellFrame.origin.y, 120 , cellFrame.size.height);
	NSLog(@"drawWithFrame:");
	//[super drawWithFrame:buttonFrame inView:controlView];
	[textCell drawWithFrame:textFrame inView:controlView];
}

- (IBAction) peformAction:(id)sender{
/*
	if ([self state] == NSOnState)
		[textCell setEnabled:YES];
	else
		[textCell setEnabled:NO];

	NSLog(@"State:%d", [self state]);
*/
}
/*
- (void)setState:(int)value{
	[super setState:value];
	if ([self state] == NSOnState)
		[textCell setEnabled:YES];
	else
		[textCell setEnabled:NO];
}

- (BOOL)refusesFirstResponder{
	return NO;
}

- (BOOL)acceptsFirstResponder{
	return [textCell acceptsFirstResponder];
}
*/	
@end
