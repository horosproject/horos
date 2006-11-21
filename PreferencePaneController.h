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




#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>



@class AppController;
@interface PreferencePaneController : NSWindowController
{
	NSPreferencePane			*pane;
	NSDictionary				*previousDefaults;
	IBOutlet	NSView			*destView;
	//IBOutlet	NSMatrix		*m_SelectionMatrix;
	BOOL						showRestartNeeded;
	IBOutlet	NSView				*allView;
}

- (void)setPane:(NSPreferencePane *)aPane;
- (NSPreferencePane *)pane;
- (IBAction)selectPane:(id)sender;
- (IBAction)showAll:(id)sender;
- (void) reopenDatabase;
- (void) selectFirstPane;
@end
