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


#import "OSIRoutingPreferencePanePref.h"

@implementation OSIRoutingPreferencePanePref

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	routingCalendars = [[[defaults arrayForKey:@"ROUTING CALENDARS"]  mutableCopy] retain];
	//setup GUI
	[routingActivated setState: [defaults boolForKey:@"ROUTINGACTIVATED"]];
	//[calendarTable setEnabled:[routingActivated state]];
}

- (void)dealloc{

	NSLog(@"dealloc OSIRoutingPreferencePanePref");
	//NSLog(@"content: %@", [[routesController content]  description]);
	[[NSUserDefaults standardUserDefaults] setObject:[routesController content]  forKey:@"RoutingRules"];
	[routingCalendars release];
	[super dealloc];
}

- (IBAction)setActivated:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"ROUTINGACTIVATED"];
	//[calendarTable setEnabled:[routingActivated state]];

}

- (IBAction) newCalendar:(id)sender
{
    [routingCalendars addObject:@"OsiriX Calendar"];    
    [calendarTable reloadData];
	
//Set to edit new entry
	[calendarTable selectRow:[routingCalendars count] - 1 byExtendingSelection:NO];
	[calendarTable editColumn:0 row:[routingCalendars count] - 1  withEvent:nil select:YES];
	
	[[NSUserDefaults standardUserDefaults] setObject:routingCalendars forKey:@"ROUTING CALENDARS"];
}

//****** TABLEVIEW

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [routingCalendars count];
}

- (void)tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{   
		NSParameterAssert(rowIndex >= 0 && rowIndex < [routingCalendars count]);
		[routingCalendars replaceObjectAtIndex:rowIndex withObject:anObject];
		
		[[NSUserDefaults standardUserDefaults] setObject:routingCalendars forKey:@"ROUTING CALENDARS"];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
	return [routingCalendars objectAtIndex:rowIndex];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	return YES;
}

- (void) deleteSelectedRow:(id)sender{
	[routingCalendars removeObjectAtIndex:[calendarTable selectedRow]];
	[calendarTable reloadData];
	[[NSUserDefaults standardUserDefaults] setObject:routingCalendars forKey:@"ROUTING CALENDARS"];
}


@end
