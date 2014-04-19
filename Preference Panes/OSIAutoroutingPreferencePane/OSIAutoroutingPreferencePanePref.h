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

#import <PreferencePanes/PreferencePanes.h>

@interface OSIAutoroutingPreferencePanePref : NSPreferencePane <NSTableViewDelegate>
{
	IBOutlet NSWindow					*newRoute;
	IBOutlet NSTableView				*routesTable;
	
	IBOutlet NSTextField				*newName, *addressAndPort, *newFilter, *newDescription;
	IBOutlet NSPopUpButton				*serverPopup;
	
	IBOutlet NSPopUpButton				*previousPopup;
	IBOutlet NSButton					*previousModality;
	IBOutlet NSButton					*previousDescription;
	IBOutlet NSButton					*cfindTest;
	
	IBOutlet NSPopUpButton				*failurePopup;
	
	NSMutableArray						*routesArray;
	NSArray								*serversArray;
	int filterType;
    BOOL imagesOnly;
	
	IBOutlet NSWindow *mainWindow;
}

@property int filterType;
@property BOOL imagesOnly;

- (void) mainViewDidLoad;
- (IBAction) endNewRoute:(id) sender;
- (IBAction) newRoute:(id) sender;
- (IBAction) syntaxHelpButtons:(id) sender;
- (void) deleteSelectedRow:(id)sender;
- (IBAction) selectServer:(id) sender;
- (IBAction) selectPrevious:(id) sender;

@end
