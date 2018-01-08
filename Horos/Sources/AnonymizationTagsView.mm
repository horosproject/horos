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


#import "AnonymizationTagsView.h"
#import "DCMAttributeTag.h"
#import "N2HighlightImageButtonCell.h"
#import "AnonymizationViewController.h"
#import "N2TextField.h"
#import "AnonymizationTagsPopUpButton.h"
#include <algorithm>
#include <cmath>

@implementation AnonymizationTagsView

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	viewGroups = [[NSMutableArray alloc] init];
	intercellSpacing = NSMakeSize(13,1);
	
	dcmTagsPopUpButton = [[AnonymizationTagsPopUpButton alloc] initWithFrame:NSZeroRect];
	[dcmTagsPopUpButton.cell setControlSize:NSMiniControlSize];
	[dcmTagsPopUpButton setFont:[NSFont labelFontOfSize:[NSFont smallSystemFontSize]-2]];
	[self addSubview:dcmTagsPopUpButton];
	
	NSButtonCell* addButtonCell = [[N2HighlightImageButtonCell alloc] initWithImage:[NSImage imageNamed:@"PlusButton"]];
	dcmTagAddButton = [[NSButton alloc] initWithFrame:NSZeroRect];
	dcmTagAddButton.cell = addButtonCell;
	[addButtonCell release];
	dcmTagAddButton.target = self;
	dcmTagAddButton.action = @selector(addButtonAction:);
	[self addSubview:dcmTagAddButton];
	
	return self;
}

-(NSArray*)groupForObject:(id)object {
	for (NSArray* group in viewGroups)
		for (id obj in group)
			if (object == obj || [obj isEqual:object])
				return group;
	return NULL;
}

-(void)addButtonAction:(NSButton*)sender {
	[anonymizationViewController addTag:dcmTagsPopUpButton.selectedDCMAttributeTag];
	[[anonymizationViewController.tagsView checkBoxForObject:dcmTagsPopUpButton.selectedDCMAttributeTag] setState:NSOnState];
	[self.window makeFirstResponder:[anonymizationViewController.tagsView textFieldForObject:dcmTagsPopUpButton.selectedDCMAttributeTag]];
	[dcmTagsPopUpButton setSelectedDCMAttributeTag:NULL];
}

-(void)rmButtonAction:(NSButton*)sender {
	[anonymizationViewController removeTag:[[self groupForObject:sender] objectAtIndex:3]];
}

-(void)awakeFromNib {
	[self resizeSubviewsWithOldSize:self.frame.size];
}

-(BOOL)isFlipped {
	return YES;
}

-(void)dealloc {
//	NSLog(@"AnonymizationTagsView dealloc");
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
	static NSFont* font = [[NSFont labelFontOfSize:[NSFont smallSystemFontSize]-1] retain];

	NSButton* checkBox = [[NSButton alloc] initWithFrame:NSZeroRect];
	[[checkBox cell] setControlSize:NSMiniControlSize];
	[checkBox setFont:font];
	[[checkBox cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[checkBox setButtonType:NSSwitchButton];
	[checkBox setTitle:tag.name];
	[self addSubview:checkBox];
	
	N2TextField* textField = [[N2TextField alloc] initWithFrame:NSZeroRect];
	[[textField cell] setControlSize:NSMiniControlSize];
	[textField setFont:font];
	[textField setBezeled:YES];
	[textField setBezelStyle:NSTextFieldSquareBezel];
	[textField setDrawsBackground:YES];
	[[textField cell] setPlaceholderString:NSLocalizedString(@"Reset", @"Placeholder string for Anonymization Tag cells")];
	[textField setStringValue:@""];
	[self addSubview:textField];
	
//	NSLog( @"VR: %@", tag.vr);
	
	NSDateFormatter* df = NULL;
	NSNumberFormatter* nf = NULL;
	if ([tag.vr isEqualToString:@"DA"] || [tag.vr isEqualToString:@"TM"] || [tag.vr isEqualToString:@"DT"])
    {
		[textField.cell setFormatter: df = [[[NSDateFormatter alloc] init] autorelease]];
		[df setFormatterBehavior:NSDateFormatterBehavior10_4];
		if ([tag.vr isEqualToString:@"DA"]) { //Date String
			[df setTimeStyle:NSDateFormatterNoStyle];
			[df setDateStyle:NSDateFormatterShortStyle];
		} else if ([tag.vr isEqualToString:@"TM"]) { //Time String
			[df setTimeStyle:NSDateFormatterShortStyle];
			[df setDateStyle:NSDateFormatterNoStyle];
		} else if ([tag.vr isEqualToString:@"DT"]) { //Date Time
			[df setTimeStyle:NSDateFormatterShortStyle];
			[df setDateStyle:NSDateFormatterShortStyle];
		}
        
        if ([df.dateFormat rangeOfString:@"yyyy"].location == NSNotFound && [df.dateFormat rangeOfString:@"yy"].location != NSNotFound)
        {
            NSString *fourDigitYearFormat = [[df dateFormat] stringByReplacingOccurrencesOfString:@"yy" withString:@"yyyy"];
            [df setDateFormat:fourDigitYearFormat];
        }
        
        [textField setToolTip: [NSString stringWithFormat: NSLocalizedString( @"Required format: %@", nil), df.dateFormat]];
        
	} else if ([tag.vr isEqualToString:@"DS"] || [tag.vr isEqualToString:@"IS"] || [tag.vr isEqualToString:@"SL"] || [tag.vr isEqualToString:@"SS"] || [tag.vr isEqualToString:@"UL"] || [tag.vr isEqualToString:@"US"] || [tag.vr isEqualToString:@"FL"] || [tag.vr isEqualToString:@"FD"]) {
		[textField.cell setFormatter: nf = [[[NSNumberFormatter alloc] init] autorelease]];
		[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[nf setNumberStyle:NSNumberFormatterDecimalStyle];
		if ([tag.vr isEqualToString:@"DS"]) { //Decimal String representing floating point
			[nf setMaximumSignificantDigits:16];
            [textField setToolTip: NSLocalizedString( @"Required format: floating point number", nil)];
		} else if ([tag.vr isEqualToString:@"IS"]) { //Integer String
			[nf setMaximumSignificantDigits:12];
			[nf setAllowsFloats:NO];
            [textField setToolTip: NSLocalizedString( @"Required format: integer number", nil)];
		} else if ([tag.vr isEqualToString:@"SL"]) { //signed long
			[nf setAllowsFloats:NO];
			[nf setMinimum:[NSNumber numberWithInteger:-0x80000000]];
			[nf setMaximum:[NSNumber numberWithInteger:0x7FFFFFFF]];
            [textField setToolTip: NSLocalizedString( @"Required format: integer number", nil)];
		} else if ([tag.vr isEqualToString:@"SS"]) { //signed short
			[nf setAllowsFloats:NO];
			[nf setMinimum:[NSNumber numberWithInteger:-0x8000]];
			[nf setMaximum:[NSNumber numberWithInteger:0x7FFF]];
            [textField setToolTip: NSLocalizedString( @"Required format: integer number", nil)];
		} else if ([tag.vr isEqualToString:@"UL"]) { //unsigned long
			[textField.cell setFormatter: nf = [[[NSNumberFormatter alloc] init] autorelease]];
			[nf setAllowsFloats:NO];
			[nf setMinimum:[NSNumber numberWithInteger:0]];
			[nf setMaximum:[NSNumber numberWithInteger:0xFFFFFFFF]];
            [textField setToolTip: NSLocalizedString( @"Required format: integer number", nil)];
		} else if ([tag.vr isEqualToString:@"US"]) { //unsigned short
			[nf setAllowsFloats:NO];
			[nf setMinimum:[NSNumber numberWithInteger:0]];
			[nf setMaximum:[NSNumber numberWithInteger:0xFFFF]];
            [textField setToolTip: NSLocalizedString( @"Required format: integer number", nil)];
		} else if ([tag.vr isEqualToString:@"FL"]) { //float
            [textField setToolTip: NSLocalizedString( @"Required format: floating point number", nil)];
		} else if ([tag.vr isEqualToString:@"FD"]) { //double
            [textField setToolTip: NSLocalizedString( @"Required format: floating point number", nil)];
		}
	}
	
	NSButtonCell* rmButtonCell = [[N2HighlightImageButtonCell alloc] initWithImage:[NSImage imageNamed:@"MinusButton"]];
	NSButton* rmButton = [[NSButton alloc] initWithFrame:NSZeroRect];
	rmButton.cell = rmButtonCell;
	[rmButtonCell release];
	rmButton.target = self;
	rmButton.action = @selector(rmButtonAction:);
	[self addSubview:rmButton];
	
	[textField bind:@"enabled" toObject:checkBox.cell withKeyPath:@"state" options:NULL];
	[checkBox.cell addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionInitial context:textField];
	[textField addObserver:self forKeyPath:@"formatIsOk" options:NSKeyValueObservingOptionInitial context:textField];
	
	NSArray* group = [NSArray arrayWithObjects: checkBox, textField, rmButton, tag, NULL];
	[viewGroups addObject:group];
	[self resizeSubviewsWithOldSize:self.frame.size];
	
	[checkBox release];
	[textField release];
	[rmButton release];
}

-(void)removeTag:(DCMAttributeTag*)tag {
	NSArray* group = [self groupForObject:tag];
	if (!group) return;
	
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidEndEditingNotification object:[group objectAtIndex:1]];
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:[group objectAtIndex:1]];
	[[[group objectAtIndex:0] cell] removeObserver:self forKeyPath:@"state"];
	[[group objectAtIndex:1] removeObserver:self forKeyPath:@"formatIsOk"];
//	[[group objectAtIndex:1] removeObserver:self forKeyPath:@"value"];
	[[group objectAtIndex:0] removeFromSuperview];
	[[group objectAtIndex:1] removeFromSuperview];
	[[group objectAtIndex:2] removeFromSuperview];
	
	[viewGroups removeObject:group];

	[self resizeSubviewsWithOldSize:self.frame.size];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	N2TextField* textField = (id)context;
	
	if ([textField isKindOfClass:[NSTextField class]]) {
		NSButton* checkBox = [self checkBoxForObject:textField];
		[textField setBackgroundColor: (checkBox.state&&textField.stringValue.length&&!textField.formatIsOk)? [NSColor colorWithCalibratedHue:[[NSColor orangeColor] hueComponent] saturation:0.25 brightness:1 alpha:1] : [NSColor whiteColor] ];
	}
}

-(void)observeTextDidChange:(NSNotification*)notification {
	NSTextField* textField = notification.object;
	[self observeValueForKeyPath:NULL ofObject:NULL change:NULL context:textField];
}

-(NSButton*)checkBoxForObject:(id)object {
	return [[self groupForObject:object] objectAtIndex:0];
}

-(N2TextField*)textFieldForObject:(id)object {
	return [[self groupForObject:object] objectAtIndex:1];
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
