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


#import "AnonymizationTagsView.h"
#import "DCMAttributeTag.h"
#import "N2HighlightImageButtonCell.h"
#import "AnonymizationViewController.h"
#import "AnonymizationTagsPopUpButton.h"
#include <algorithm>
#include <cmath>

@implementation AnonymizationTagsView

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	viewGroups = [[NSMutableArray alloc] init];
	intercellSpacing = NSMakeSize(13,1);
	
	dcmTagsPopUpButton = [[AnonymizationTagsPopUpButton alloc] initWithSize:NSZeroSize];
	[dcmTagsPopUpButton.cell setControlSize:NSMiniControlSize];
	[dcmTagsPopUpButton setFont:[NSFont labelFontOfSize:[NSFont smallSystemFontSize]-2]];
	[self addSubview:dcmTagsPopUpButton];
	
	NSButtonCell* addButtonCell = [[N2HighlightImageButtonCell alloc] initWithImage:[NSImage imageNamed:@"PlusButton"]];
	dcmTagAddButton = [[NSButton alloc] initWithSize:NSZeroSize];
	dcmTagAddButton.cell = addButtonCell;
	[addButtonCell release];
	dcmTagAddButton.target = self;
	dcmTagAddButton.action = @selector(addButtonAction:);
	[self addSubview:dcmTagAddButton];
	
	return self;
}

-(NSArray*)groupForView:(id)view {
	for (NSArray* group in viewGroups)
		for (id obj in group)
			if (view == obj || [obj isEqual:view])
				return group;
	return NULL;
}

-(void)addButtonAction:(NSButton*)sender {
	[anonymizationViewController addTag:dcmTagsPopUpButton.selectedTag];
	[[anonymizationViewController.tagsView checkBoxForTag:dcmTagsPopUpButton.selectedTag] setState:NSOnState];
	[self.window makeFirstResponder:[anonymizationViewController.tagsView textFieldForTag:dcmTagsPopUpButton.selectedTag]];
	[dcmTagsPopUpButton setSelectedTag:NULL];
}

-(void)rmButtonAction:(NSButton*)sender {
	[anonymizationViewController removeTag:[[self groupForView:sender] objectAtIndex:3]];
}

-(void)awakeFromNib {
	[self resizeSubviewsWithOldSize:self.frame.size];
}

-(BOOL)isFlipped {
	return YES;
}

-(void)dealloc {
	NSLog(@"AnonymizationTagsView dealloc");
	[dcmTagsPopUpButton release];
	[dcmTagAddButton release];
	[viewGroups release];
	[super dealloc];
}

-(NSInteger)columnCount {
	return 2;
}

-(NSInteger)rowCount {
	return std::ceil(CGFloat(viewGroups.count+1)/self.columnCount);
}

-(NSRect)cellFrameForIndex:(NSInteger)index {
	NSInteger column = index%self.columnCount, row = std::floor(CGFloat(index)/self.columnCount);
	return NSMakeRect((cellSize.width+intercellSpacing.width)*column, (cellSize.height+intercellSpacing.height)*row, cellSize.width, cellSize.height);
}

#define kMaxTextFieldWidth 200.f
#define kButtonSpace 15.f

-(NSRect)checkBoxFrameForCellFrame:(NSRect)frame {
	CGFloat textFieldWidth;
	if((frame.size.width-kButtonSpace)/2 < kMaxTextFieldWidth) textFieldWidth = (frame.size.width-kButtonSpace)/2;
	else textFieldWidth = kMaxTextFieldWidth;
	frame.size.width -= frame.size.height+textFieldWidth;
	return frame;
}

-(NSRect)textFieldFrameForCellFrame:(NSRect)frame {
	CGFloat textFieldWidth;
	if((frame.size.width-kButtonSpace)/2 < kMaxTextFieldWidth) textFieldWidth = (frame.size.width-kButtonSpace)/2;
	else textFieldWidth = kMaxTextFieldWidth;
	frame.origin.x += frame.size.width - textFieldWidth - frame.size.height;
	frame.size.width = textFieldWidth;
	return frame;
}

-(NSRect)buttonFrameForCellFrame:(NSRect)frame {
	frame.origin.x += frame.size.width-10;
	frame.origin.y += 4;
	frame.size = NSMakeSize(10,10);
	return frame;
}

-(NSRect)popUpButtonFrameForCellFrame:(NSRect)frame {
	frame.size.width -= kButtonSpace;
	return frame;
}

-(void)repositionGroupViews:(NSArray*)group {
	NSRect cellFrame = [self cellFrameForIndex:[viewGroups indexOfObject:group]];
	[[group objectAtIndex:0] setFrame:[self checkBoxFrameForCellFrame:cellFrame]];
	[[group objectAtIndex:1] setFrame:[self textFieldFrameForCellFrame:cellFrame]];
	[[group objectAtIndex:2] setFrame:[self buttonFrameForCellFrame:cellFrame]];
}

-(void)repositionAddTagInterface {
	NSRect cellFrame = [self cellFrameForIndex:viewGroups.count];
	[dcmTagsPopUpButton setFrame:[self popUpButtonFrameForCellFrame:cellFrame]];
	[dcmTagAddButton setFrame:[self buttonFrameForCellFrame:cellFrame]];
}

-(void)addTag:(DCMAttributeTag*)tag {
	static const NSFont* font = [[NSFont labelFontOfSize:[NSFont smallSystemFontSize]-1] retain];

	NSButton* checkBox = [[NSButton alloc] initWithSize:NSZeroSize];
	[[checkBox cell] setControlSize:NSMiniControlSize];
	[checkBox setFont:font];
	[[checkBox cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[checkBox setButtonType:NSSwitchButton];
	[checkBox setTitle:tag.name];
	[self addSubview:checkBox];
	
	NSTextField* textField = [[NSTextField alloc] initWithSize:NSZeroSize];
	[[textField cell] setControlSize:NSMiniControlSize];
	[textField setFont:font];
	[textField setBezeled:YES];
	[textField setBezelStyle:NSTextFieldSquareBezel];
	[textField setDrawsBackground:YES];
	[[textField cell] setPlaceholderString:NSLocalizedString(@"Reset", @"Placeholder string for Anonymization Tag cells")];
	[textField setStringValue:@""];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeTextFieldDidEndEditing:) name:NSControlTextDidEndEditingNotification object:textField];
	[self addSubview:textField];
	
	NSLog( @"VR: %@", tag.vr);
	
	if ([tag.vr isEqual:@"DA"]) { //Date String
		NSDateFormatter* f = [[[NSDateFormatter alloc] init] autorelease];
		[f setFormatterBehavior:NSDateFormatterBehavior10_4];
		[f setTimeStyle:NSDateFormatterNoStyle];
		[f setDateStyle:NSDateFormatterShortStyle];
		[textField.cell setFormatter:f];
	} else if ([tag.vr isEqual:@"TM"]) { //Time String
		NSDateFormatter* f = [[[NSDateFormatter alloc] init] autorelease];
		[f setFormatterBehavior:NSDateFormatterBehavior10_4];
		[f setTimeStyle:NSDateFormatterShortStyle];
		[f setDateStyle:NSDateFormatterNoStyle];
		[textField.cell setFormatter:f];
	} else if ([tag.vr isEqual:@"DT"]) { //Date Time
		NSDateFormatter* f = [[[NSDateFormatter alloc] init] autorelease];
		[f setFormatterBehavior:NSDateFormatterBehavior10_4];
		[f setTimeStyle:NSDateFormatterShortStyle];
		[f setDateStyle:NSDateFormatterShortStyle];
		[textField.cell setFormatter:f];
	} else if ([tag.vr isEqual:@"DS"]) { //Decimal String representing floating point
	} else if ([tag.vr isEqual:@"IS"]) { //Integer String
	} else if ([tag.vr isEqual:@"SL"]) { //signed long
	} else if ([tag.vr isEqual:@"SS"]) { //signed short
	} else if ([tag.vr isEqual:@"UL"]) { //unsigned long
	} else if ([tag.vr isEqual:@"US"]) { //unsigned short
	} else if ([tag.vr isEqual:@"FL"]) { //float
	} else if ([tag.vr isEqual:@"FD"]) { //double
	}
	
	NSButtonCell* rmButtonCell = [[N2HighlightImageButtonCell alloc] initWithImage:[NSImage imageNamed:@"MinusButton"]];
	NSButton* rmButton = [[NSButton alloc] initWithSize:NSZeroSize];
	rmButton.cell = rmButtonCell;
	[rmButtonCell release];
	rmButton.target = self;
	rmButton.action = @selector(rmButtonAction:);
	[self addSubview:rmButton];
	
	[textField bind:@"enabled" toObject:checkBox.cell withKeyPath:@"state" options:NULL];
	
	NSArray* group = [NSArray arrayWithObjects: checkBox, textField, rmButton, tag, NULL];
	[viewGroups addObject:group];
	[self resizeSubviewsWithOldSize:self.frame.size];
	
	[checkBox release];
	[textField release];
	[rmButton release];
}

-(void)removeTag:(DCMAttributeTag*)tag {
	NSArray* group = [self groupForView:tag];
	if (!group) return;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidEndEditingNotification object:[group objectAtIndex:1]];
	[[group objectAtIndex:0] removeFromSuperview];
	[[group objectAtIndex:1] removeFromSuperview];
	[[group objectAtIndex:2] removeFromSuperview];
	
	[viewGroups removeObject:group];

	[self resizeSubviewsWithOldSize:self.frame.size];
}

-(void)observeTextFieldDidEndEditing:(NSNotification*)notification {
	NSTextField* textField = notification.object;
	if (textField.formatter) {
		id obj = NULL;
		NSString* err = NULL;
		[textField.formatter getObjectValue:&obj forString:textField.stringValue errorDescription:&err];
	//	if (obj)
	//		[textField setObjectValue:obj];
	//	else NSLog(@"%@ error: %@", textField.formatter, err);
		if (err) 
			NSLog(@"%@ error: %@", textField.formatter, err);
	}
}

-(NSButton*)checkBoxForTag:(DCMAttributeTag*)tag {
	return [[self groupForView:tag] objectAtIndex:0];
}

-(NSTextField*)textFieldForTag:(DCMAttributeTag*)tag {
	return [[self groupForView:tag] objectAtIndex:1];
}

-(NSSize)idealSize {
	NSInteger columnCount = self.columnCount, rowCount = self.rowCount;
	float rC = rowCount-1;
	if( rC < 0) rC = 0;
	float cC = columnCount-1;
	if( cC < 0) cC = 0;
	
	return NSMakeSize(cellSize.width*columnCount+intercellSpacing.width*cC, cellSize.height*rowCount+intercellSpacing.height*rC);
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	cellSize = NSMakeSize((self.frame.size.width-intercellSpacing.width*(self.columnCount-1))/2,17);
	for (NSArray* group in viewGroups)
		[self repositionGroupViews:group];
	[self repositionAddTagInterface];
}







@end
