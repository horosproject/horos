/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/




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
