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

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface OSIRoutingPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSTableView *calendarTable;
	NSMutableArray *routingCalendars;
	IBOutlet NSButton *routingActivated;
	IBOutlet NSWindow *ruleWindow;
	IBOutlet NSArrayController *routesController;
	
	IBOutlet SFAuthorizationView			*_authView;
}

- (void) mainViewDidLoad;
- (IBAction)setActivated:(id)sender;
- (IBAction) newCalendar:(id)sender;
- (void) deleteSelectedRow:(id)sender;

@end
