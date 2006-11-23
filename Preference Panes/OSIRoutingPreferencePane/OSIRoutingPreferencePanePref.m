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

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
	
	if( aView == _authView) return;
	
    if ([aView isKindOfClass: [NSControl class] ])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }

	// Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
}

- (void) enableControls: (BOOL) val
{
	[self checkView: [self mainView] :val];

//	[characterSetPopup setEnabled: val];
//	[addServerDICOM setEnabled: val];
//	[addServerSharing setEnabled: val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.routing"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];


	routingCalendars = [[[defaults arrayForKey:@"ROUTING CALENDARS"]  mutableCopy] retain];
	//setup GUI
	[routingActivated setState: [defaults boolForKey:@"ROUTINGACTIVATED"]];
	//[calendarTable setEnabled:[routingActivated state]];
}

- (void) willUnselect
{
	[[NSUserDefaults standardUserDefaults] setObject:[routesController content]  forKey:@"RoutingRules"];
}

- (void)dealloc{

	NSLog(@"dealloc OSIRoutingPreferencePanePref");
	//NSLog(@"content: %@", [[routesController content]  description]);
	
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

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) return YES;
	else return NO;
}

- (void) deleteSelectedRow:(id)sender
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState)
	{
		[routingCalendars removeObjectAtIndex:[calendarTable selectedRow]];
		[calendarTable reloadData];
		[[NSUserDefaults standardUserDefaults] setObject:routingCalendars forKey:@"ROUTING CALENDARS"];
	}
}


@end
