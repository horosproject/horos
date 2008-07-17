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

@interface OSIAutoroutingPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSButton					*autoroutingActivated;
	IBOutlet NSWindow					*newRoute;
	IBOutlet NSTableView				*routesTable;
	IBOutlet SFAuthorizationView		*_authView;
	
	IBOutlet NSTextField				*newName, *addressAndPort, *newFilter, *newDescription;
	IBOutlet NSPopUpButton				*serverPopup;
	
	IBOutlet NSPopUpButton				*previousPopup;
	IBOutlet NSButton					*previousModality;
	IBOutlet NSButton					*previousDescription;
	IBOutlet NSButton					*cfindTest;
	
	IBOutlet NSPopUpButton				*failurePopup;
	
	NSMutableArray						*routesArray;
}

- (void) mainViewDidLoad;
- (IBAction) setActivated:(id)sender;
- (IBAction) endNewRoute:(id) sender;
- (IBAction) newRoute:(id) sender;
- (IBAction) syntaxHelpButtons:(id) sender;
- (void) deleteSelectedRow:(id)sender;
- (IBAction) selectServer:(id) sender;
- (IBAction) selectPrevious:(id) sender;

@end
