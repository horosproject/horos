/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "SmartWindowController.h"
#import "SearchSubview.h"
#import "QueryFilter.h"

@implementation SmartWindowController

- (id)init{
	if (self = [super initWithWindowNibName:@"SmartAlbum"])
		subviews = [[NSMutableArray array] retain];
	return self;
}

- (void) dealloc {
	[subviews release];
	[criteria release];
	[super dealloc];
}

/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/

- (void)windowDidLoad{
	firstTime = YES;
	[self addSubview:nil];
	[albumNameField setStringValue:NSLocalizedString(@"Smart Album", nil)];
	[super windowDidLoad];
	
}

- (void)addSubview:(id)sender
{
	//setup subview
	float subViewHeight = 50.0;
	SearchSubview *subview = [[[SearchSubview alloc] initWithFrame:NSMakeRect(0.0,0.0,507.0,subViewHeight)] autorelease];
	//AdvancedQuerySubview *subview = [[[AdvancedQuerySubview alloc] initWithFrame:NSMakeRect(0.0,0.0,507.0,subViewHeight)] autorelease];
	[filterBox addSubview:subview];	
	[subviews  addObject:subview];
	[[subview addButton] setTarget:self];
	[[subview addButton] setAction:@selector(addSubview:)];
	[[subview filterKeyPopup] setTarget:subview];
	[[subview filterKeyPopup] setAction:@selector(showSearchTypePopup:)];
	[[subview searchTypePopup] setTarget:subview];
	[[subview searchTypePopup] setAction:@selector(showValueField:)];
	[[subview removeButton] setTarget:self];
	[[subview removeButton] setAction:@selector(removeSubview:)];
	[self drawSubviews];
	
	[subview showSearchTypePopup: [subview filterKeyPopup]];
}	

- (void)removeSubview:(id)sender{
	NSView *view = [sender superview];
	[subviews removeObject:view];
	[view removeFromSuperview];
	[self drawSubviews];
}

- (void)drawSubviews{


	float subViewHeight = 50.0;
	float windowHeight = 156.0;
	//displays wrong when sheet first displayed
	if (!firstTime)
		windowHeight -= 22.0;
		//resize Autoresizing not working.  Need to manually seet window height and origin.
	int count = [subviews  count];
	NSRect windowFrame = [[self window] frame];
	NSRect boxFrame = [filterBox frame];
	float oldWindowHeight = windowFrame.size.height;
	float newWindowHeight = windowHeight  + subViewHeight * count;
	float y = windowFrame.origin.y - (newWindowHeight - oldWindowHeight);
	//NSLog(@"old height %f  new Height  %f count %d", oldWindowHeight, newWindowHeight, count);
	NSEnumerator *enumerator = [subviews reverseObjectEnumerator];
	id view;
	int i = 0;
	while (view = [enumerator nextObject]) {
		NSRect viewFrame = [view frame];
		[view setFrame:NSMakeRect(viewFrame.origin.x, subViewHeight * i++, viewFrame.size.width, viewFrame.size.height)];
		
	}
	
	[[self window] setFrame: NSMakeRect(windowFrame.origin.x, y, windowFrame.size.width, newWindowHeight) display:YES];

	[self updateRemoveButtons];
	firstTime = NO;
	
}

- (void)updateRemoveButtons{
	if ([subviews count] == 1) {
		AdvancedQuerySubview *view = [subviews objectAtIndex:0];
		[[view removeButton] setEnabled:NO];
	}
	else {
		NSEnumerator *enumerator = [subviews  objectEnumerator];
		AdvancedQuerySubview *view;
		while (view = [enumerator nextObject])
				[[view removeButton] setEnabled:YES];
	}
}

- (void) windowWillClose: (NSNotification*) notification
{
    [[self window] setDelegate:nil];
}

-(void) createCriteria {
	NSEnumerator *enumerator = [subviews objectEnumerator];
	AdvancedQuerySubview *view;
	criteria = [[NSMutableArray array] retain];
	while (view = [enumerator nextObject])
	{
		NSString *predicateString = 0L;
		NSString *value = 0L;
		int searchType;
		
		NSString *key = [[view filterKeyPopup] titleOfSelectedItem];
		// Modality	
		if ([key isEqualToString:NSLocalizedString(@"Modality", 0L)])
		{
			switch ([[view searchTypePopup] indexOfSelectedItem]) {
				case osiCR: value = @"CR";
						break;
				case osiCT: value = @"CT";
						break;;
				case osiDX: value = @"DX";
						break;
				case osiES: value = @"ES";
						break;
				case osiMG: value = @"MG";
						break;
				case osiMR: value = @"MR";
						break;
				case osiNM: value = @"NM";
						break;
				case osiOT: value = @"OT";
						break;
				case osiPT: value = @"PT";
						break;
				case osiRF: value = @"RF";
						break;
				case osiSC: value = @"SC";
						break;
				case osiUS: value = @"US";
						break;
				case osiXA: value = @"XA";
						break;
				default:
					value = [[view valueField] stringValue];
					if( [value isEqualToString:@""]) value = @"OT";
				break;
			}
			
			predicateString = [NSString stringWithFormat:@"modality LIKE[cd] \"%@\"", value];
		}
		// Study status	
		else if ([key isEqualToString:NSLocalizedString(@"Study Status", 0L)])
		{
			switch ([[view searchTypePopup] indexOfSelectedItem]) {
				case empty: value = @"0";
						break;
				case unread: value = @"1";
						break;
				case reviewed: value = @"2";
						break;
				case dictated: value = @"3";
						break;
				default: value = [[view valueField] stringValue];
			}
			
			if( [value isEqualToString:@""]) value = @"0";
			
			predicateString = [NSString stringWithFormat:@"stateText == \"%@\"", value];
		}		
		// Dates		
		else if ([key isEqualToString:NSLocalizedString(@"Study Date", nil)] == YES || [key isEqualToString:NSLocalizedString(@"Date Added", nil)])
		{
			NSDate		*date = 0L;
			NSString	*field;
			
			if ([key isEqualToString:NSLocalizedString(@"Study Date", nil)]) field = [NSString stringWithString: @"date"];
			if( [key isEqualToString:NSLocalizedString(@"Date Added", nil)]) field = [NSString stringWithString: @"dateAdded"];
			
			switch ([[view searchTypePopup] indexOfSelectedItem] + 4)
			{
				case SearchToday:
					predicateString = [NSString stringWithFormat:@"%@ >= CAST($TODAY, \"NSDate\")", field];
				break;
				
				case searchYesterday:
					predicateString = [NSString stringWithFormat:@"%@ >= CAST($YESTERDAY, \"NSDate\") AND %@ <= CAST($TODAY, \"NSDate\")", field, field];
				break;
														
				case searchWithin:
					switch( [[view dateRangePopup] indexOfSelectedItem])
					{
						case 0:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($YESTERDAY, \"NSDate\")", field];		break;
						case 1:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($2DAYS, \"NSDate\")", field];			break;
						case 2:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($WEEK, \"NSDate\")", field];			break;
						case 3:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($MONTH, \"NSDate\")", field];			break;
						case 4:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($2MONTHS, \"NSDate\")", field];			break;
						case 5:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($3MONTHS, \"NSDate\")", field];			break;
						case 6:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($YEAR, \"NSDate\")", field];			break;
						case 8:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($LASTHOUR, \"NSDate\")", field];		break;
						case 9:		predicateString = [NSString stringWithFormat:@"%@ >= CAST($LAST6HOURS, \"NSDate\")", field];		break;
						case 10:	predicateString = [NSString stringWithFormat:@"%@ >= CAST($LAST12HOURS, \"NSDate\")", field];		break;
					}
				break;
				
				case searchBefore:
					//date = [[view valueField] objectValue];
					date = [[view datePicker] objectValue];
					predicateString = [NSString stringWithFormat:@"%@ <= CAST(%lf, \"NSDate\")", field, [date timeIntervalSinceReferenceDate]];
				break;
				
				case searchAfter:
					//date = [[view valueField] objectValue];
					date = [[view datePicker] objectValue];
					predicateString = [NSString stringWithFormat:@"%@ >= CAST(%lf, \"NSDate\")", field, [date timeIntervalSinceReferenceDate]];
				break;
				
				case searchExactDate:
					date = [[view datePicker] objectValue];
					predicateString = [NSString stringWithFormat:@"%@ >= CAST(%lf, \"NSDate\") AND %@ < CAST(%lf, \"NSDate\")", field, [date timeIntervalSinceReferenceDate], field, [[date addTimeInterval:60*60*24] timeIntervalSinceReferenceDate]];
				break;
			}
		}
		else {
			searchType = [[view searchTypePopup] indexOfSelectedItem];
			value = [[view valueField] stringValue];
		}
		
		if ([key isEqualToString:NSLocalizedString(@"Patient Name", 0L)])
			key = @"name";
		else if ([key isEqualToString:NSLocalizedString(@"Patient ID", 0L)])
			key = @"patientID";
		else if ([key isEqualToString:NSLocalizedString(@"Study ID", 0L)])
			key = @"id";
		else if ([key isEqualToString:NSLocalizedString(@"Study Description", 0L)])
			key = @"studyName";
		else if ([key isEqualToString:NSLocalizedString(@"Referring Physician", 0L)])
			key = @"referringPhysician";
		else if ([key isEqualToString:NSLocalizedString(@"Performing Physician", 0L)])
			key = @"performingPhysician";
		else if ([key isEqualToString:NSLocalizedString(@"Institution", 0L)])	
			key = @"institutionName";
		else if ([key isEqualToString:NSLocalizedString(@"Comments", 0L)])	
			key = @"comment";
		else if ([key isEqualToString:NSLocalizedString(@"Study Status", 0L)])
		{
			key = @"stateText";
			predicateString = [NSString stringWithFormat:@"stateText == %d", [value intValue]];
		}
		
		if( predicateString == 0L)
		{
			if( [value isEqualToString:@""]) value = @"OT";
			
			switch( searchType)
			{
				case searchContains:			predicateString = [NSString stringWithFormat:@"%@ LIKE[cd] \"*%@*\"", key, value];		break;
				case searchStartsWith:			predicateString = [NSString stringWithFormat:@"%@ LIKE[cd] \"%@*\"", key, value];		break;
				case searchEndsWith:			predicateString = [NSString stringWithFormat:@"%@ LIKE[cd] \"*%@\"", key, value];		break;
				case searchExactMatch:
									{
										if([[[view valueField] stringValue] isEqualToString:@""]) value = [NSString stringWithString: @"<empty>"];
										predicateString = [NSString stringWithFormat:@"%@ LIKE[cd] \"%@\"", key, value];	break;
									}
			}
		}
		
		[criteria addObject: predicateString];
	}
}

-(NSMutableArray *)criteria{
	return criteria;
}
-(NSString *)albumTitle{
	return [albumNameField stringValue];
}

- (NSCalendarDate *)dateBeforeNow:(int)value{
	NSCalendarDate *today = [NSCalendarDate date];
	NSCalendarDate *date;
	switch (value) {
		case searchWithinToday: 
			date = today;
			break;
		case searchWithinLast2Days: 
			date = [today dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
			break;
		case searchWithinLastWeek: 
			date = [today dateByAddingYears:0 months:0 days:-7 hours:0 minutes:0 seconds:0];
			break;
		case searchWithinLast2Weeks: 
			date = [today dateByAddingYears:0 months:0 days:-14 hours:0 minutes:0 seconds:0];
			break;
		case searchWithinLastMonth: 
			date = [today dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
			break;
		case searchWithinLast2Months: 
			date = [today dateByAddingYears:0 months:-2 days:0 hours:0 minutes:0 seconds:0];
			break;
		case searchWithinLast3Months: 
			date = [today dateByAddingYears:0 months:-3 days:0 hours:0 minutes:0 seconds:0];
			break;
		case searchWithinLastYear:  
			date = [today dateByAddingYears:-1 months:0 days:0 hours:0 minutes:0 seconds:0];
			break;
		default:
			date = today;
			break;
	
	}
	return date;
}

- (IBAction)newAlbum:(id)sender{
	if ([sender tag] == 0)
		madeCriteria = NO;
	else {
		madeCriteria = YES;
		[self createCriteria];
	}
	[NSApp stopModal];
}

- (BOOL)madeCriteria {
	return madeCriteria;
}
		

@end
