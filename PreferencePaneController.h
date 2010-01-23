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




#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>



@class AppController;

/** \brief Window Controller for Preferences */
@interface PreferencePaneController : NSWindowController
{
	int							curPaneIndex;
	NSPreferencePane			*pane;
	IBOutlet	NSView			*destView;
	IBOutlet	NSView			*allView;
	
	NSMutableDictionary			*bundles;
}


/** Set the Preference pane to display */
- (void)setPane:(NSPreferencePane *)aPane;

/** The current preference pane */
- (NSPreferencePane *)pane;

/** Action to select a pane */
- (IBAction)selectPane:(id)sender;

/** Return to the all Panes view */
- (IBAction)showAll:(id)sender;

/** Reset database to the default database */
- (void) reopenDatabase;

/** Action to go the next or previous preference pane */
- (IBAction)nextAndPrevPane:(id)sender;

/** Select the preference pane with the index */
- (void)selectPaneIndex:(int) index;
@end
