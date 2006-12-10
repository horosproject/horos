/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import "AdvancedQuerySubview.h"


@implementation AdvancedQuerySubview

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		filterKeyPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(9,18,135,26) pullsDown:NO];
		[filterKeyPopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Patient Name", nil), NSLocalizedString(@"Patient ID", nil), NSLocalizedString(@"Modality", nil), NSLocalizedString(@"Study Date", nil), nil]];
		searchTypePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(146,18,135,26) pullsDown:NO];
		[searchTypePopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"contains", nil), NSLocalizedString(@"starts with", nil), NSLocalizedString(@"ends with", nil), NSLocalizedString(@"is", nil), nil]];
		[searchTypePopup setHidden:YES];
		valueField = [[NSTextField alloc] initWithFrame:NSMakeRect(287,20,140,22)];
		[valueField setHidden:YES];
		datePicker = [[NSDatePicker alloc] initWithFrame:NSMakeRect(287,20,140,22)];
		[datePicker setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
		[datePicker setDatePickerStyle: NSTextFieldAndStepperDatePickerStyle];
		
		[datePicker setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
		
		[datePicker setBackgroundColor: [NSColor whiteColor]];
		[datePicker setDrawsBackground: YES];
		[datePicker setHidden:YES];
		addButton = [[NSButton  alloc] initWithFrame:NSMakeRect(436,14,39,38)];
		[addButton setImage:[NSImage imageNamed:@"add.tif"]];
		[addButton setImagePosition:NSImageOnly];
		[addButton setBezelStyle:NSCircularBezelStyle];
		removeButton = [[NSButton  alloc] initWithFrame:NSMakeRect(469,14,39,38)];
		[removeButton setImage:[NSImage imageNamed:@"minus.tif"]];
		[removeButton setImagePosition:NSImageOnly];
		[removeButton setBezelStyle:NSCircularBezelStyle];
		[removeButton setEnabled:NO];
		NSArray *views = [NSArray arrayWithObjects:filterKeyPopup, searchTypePopup, valueField, addButton, removeButton, datePicker, nil];
		NSEnumerator *enumerator = [views objectEnumerator];
		id view;
		NSView *lastView = nil;
		while (view = [enumerator nextObject]) {
			[lastView setNextKeyView:view];
			[self addSubview:view];
			lastView = view;
		}
		
		dateRangePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(287,18,135,26) pullsDown:NO];
		[dateRangePopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"the last day", nil), NSLocalizedString(@"the last 2 days", nil), NSLocalizedString(@"the last week", nil), NSLocalizedString(@"the last month", nil), NSLocalizedString(@"the last 2 months", nil), NSLocalizedString(@"the last 3 month", nil), NSLocalizedString(@"the last year", nil), nil]];
		[self addSubview:dateRangePopup];
		[dateRangePopup setHidden:YES];
		[dateRangePopup release];

    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	//NSLog(@"rect %@ %f %f %f %f", [self description], rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
//	NSLog (@"box
	[super drawRect:rect];
}

- (id) filterKeyPopup{
	return filterKeyPopup;
}
- (id) searchTypePopup{
	return searchTypePopup;
}
- (id) valueField{
	return valueField;
}
- (id) addButton{
	return addButton;
}
- (id) removeButton{
	return removeButton;
}
- (id) datePicker{
	return datePicker;
}
- (id) dateRangePopup{
	return dateRangePopup;
}

- (id) modalityPopup{
	return modalityPopup;
}

- (IBAction) showSearchTypePopup: (id) sender
{
	[searchTypePopup setHidden:YES];
	[dateRangePopup setHidden:YES];
	[valueField setHidden:YES];
	[datePicker setHidden:YES];

	[searchTypePopup setHidden:NO];
	//Study date selected. Need to adjust searchType parameters and add Date formtter.
	[searchTypePopup removeAllItems];
	if ([sender indexOfSelectedItem] == 3 || [sender indexOfSelectedItem] == 11) {  //dates
		[searchTypePopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"is Today", nil), NSLocalizedString(@"is Yesterday", nil),
		  NSLocalizedString(@"is before", nil), NSLocalizedString(@"is after", nil),NSLocalizedString(@"is within", nil), NSLocalizedString(@"is exactly", nil), nil]];
	}
	else if ([sender indexOfSelectedItem] == 2) {  //Modality
		[searchTypePopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"is CR", nil), NSLocalizedString(@"is CT", nil),
		  NSLocalizedString(@"is DX", nil), NSLocalizedString(@"is ES", nil), NSLocalizedString(@"is MG", nil), NSLocalizedString(@"is MR", nil),
		  NSLocalizedString(@"is NM", nil), NSLocalizedString(@"is OT", nil),NSLocalizedString(@"is PT", nil),NSLocalizedString(@"is RF", nil),
		  NSLocalizedString(@"is SC", nil),NSLocalizedString(@"is US", nil),NSLocalizedString(@"is XA", nil),NSLocalizedString(@"is Other", nil), nil]];
	}
	else if ([sender indexOfSelectedItem] == 10) {  //Status
		[searchTypePopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"is empty", nil), NSLocalizedString(@"is unread", nil),
		  NSLocalizedString(@"is reviewed", nil), NSLocalizedString(@"is dictated", nil), nil]];
	}
	else  //not dates
		[searchTypePopup addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"contains", nil), NSLocalizedString(@"starts with", nil),
		  NSLocalizedString(@"ends with", nil), NSLocalizedString(@"is", nil), nil]];
		
	[self showValueField: searchTypePopup];
}

- (IBAction) showValueField: (id) sender{

	[datePicker setHidden:YES];

	// need date range Popup
	if ( ([filterKeyPopup indexOfSelectedItem] == 3 || [filterKeyPopup indexOfSelectedItem] == 11) && [searchTypePopup indexOfSelectedItem] == 4) {
		[dateRangePopup setHidden:NO];
		[valueField setHidden:YES];
		[searchTypePopup setNextKeyView:dateRangePopup];
	}
	// Modalities
	else if ([filterKeyPopup indexOfSelectedItem] == 2 && [searchTypePopup indexOfSelectedItem] < 13) {
		[dateRangePopup setHidden:YES];
		[valueField setHidden:YES];
	}
	// Study status
	else if ([filterKeyPopup indexOfSelectedItem] == 10) {
		[dateRangePopup setHidden:YES];
		[valueField setHidden:YES];
	}
	//add date formatter
	else if (([filterKeyPopup indexOfSelectedItem] == 3 || [filterKeyPopup indexOfSelectedItem] == 11)) {
		if (([searchTypePopup indexOfSelectedItem] == 2) || ([searchTypePopup indexOfSelectedItem] == 3) || ([searchTypePopup indexOfSelectedItem] == 5)) {
			[dateRangePopup setHidden:YES];
			[valueField setHidden:YES];
			[datePicker setHidden:NO];
			
		//	NSDateFormatter *formatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%m/%d/%Y" allowNaturalLanguage:NO] autorelease];
		//	[[valueField cell] setFormatter:formatter];
		//	[valueField setObjectValue:[NSDate date]];
		}
		else {
		// no other fields to view Selection is today  or Yesterday exact match
			[dateRangePopup setHidden:YES];
			[valueField setHidden:YES];
			[searchTypePopup setNextKeyView:valueField];
		}
	}
	// just standard text
	else {
		[dateRangePopup setHidden:YES];
		[valueField setHidden:NO];
	}
}

- (IBAction)showModalityPopup:(id)sender{
	[modalityPopup setHidden:NO];
}

@end
