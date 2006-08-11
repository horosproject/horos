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

@interface OSIDatabasePreferencePanePref : NSPreferencePane 
{
	IBOutlet NSButton		*displayAllStudies;
	IBOutlet NSMatrix		*locationMatrix;
	IBOutlet NSTextField	*locationURLField;
	IBOutlet NSMatrix		*copyDatabaseModeMatrix;
	IBOutlet NSButton		*copyDatabaseOnOffButton;
	IBOutlet NSButton		*localizerOnOffButton;
	IBOutlet NSMatrix		*columnsDisplay;
	IBOutlet NSMatrix		*seriesOrderMatrix;
	IBOutlet NSMatrix		*reportsMode;
	IBOutlet NSPopUpButton	*reportsPluginsMenu;
	
	IBOutlet NSMatrix		*commentsDeleteMatrix;
	IBOutlet NSTextField	*commentsDeleteText;
	
	IBOutlet NSButton		*commentsAutoFill;
	IBOutlet NSTextField	*commentsGroup, *commentsElement;
	
	// Auto-Cleaning

	IBOutlet NSButton		*older, *deleteOriginal;
	IBOutlet NSMatrix		*olderType;
	IBOutlet NSPopUpButton	*olderThanProduced, *olderThanOpened;
	
	IBOutlet NSButton		*freeSpace;
	IBOutlet NSMatrix		*freeSpaceType;
	IBOutlet NSPopUpButton	*freeSpaceSize;
	
	IBOutlet SFAuthorizationView *_authView;

}

- (void) mainViewDidLoad;
- (IBAction)setLocation:(id)sender;
- (IBAction)setLocationURL:(id)sender;
- (IBAction)setCopyDatabaseMode:(id)sender;
- (IBAction)setCopyDatabaseOnOff:(id)sender;
- (IBAction)setLocalizerOnOff:(id)sender;
- (IBAction)setDisplayPatientName:(id)sender;
- (IBAction)databaseCleaning:(id)sender;
- (IBAction)setSeriesOrder:(id)sender;
- (IBAction)setAutoComments:(id) sender;
- (IBAction)setReportMode:(id) sender;

- (BOOL)splitMultiEchoMR;
- (void)setSplitMultiEchoMR:(BOOL)value;
- (BOOL)combineProjectionSeries;
- (void)setCombineProjectionSeries:(BOOL)value;
@end
