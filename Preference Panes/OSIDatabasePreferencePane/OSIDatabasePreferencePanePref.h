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


@interface OSIDatabasePreferencePanePref : NSPreferencePane 
{
	IBOutlet NSScrollView	*scrollView;
	IBOutlet NSMatrix *locationMatrix;
	IBOutlet NSTextField *locationURLField;
	IBOutlet NSMatrix *copyDatabaseModeMatrix;
	IBOutlet NSButton *copyDatabaseOnOffButton;
	IBOutlet NSButton *localizerOnOffButton;
	IBOutlet NSMatrix *columnsDisplay;
	IBOutlet NSMatrix *multipleScreensMatrix;
	IBOutlet NSMatrix *seriesOrderMatrix;
	IBOutlet NSMatrix *reportsMode;
	IBOutlet NSPopUpButton	*reportsPluginsMenu;
	
	IBOutlet NSButton		*commentsAutoFill;
	IBOutlet NSTextField	*commentsGroup, *commentsElement;
	
	// Auto-Cleaning
	
	IBOutlet NSButton *older;
	IBOutlet NSMatrix *olderType;
	IBOutlet NSPopUpButton *olderThanProduced, *olderThanOpened;
	
	IBOutlet NSButton *freeSpace;
	IBOutlet NSMatrix *freeSpaceType;
	IBOutlet NSPopUpButton *freeSpaceSize;

}

- (void) mainViewDidLoad;
- (IBAction)setLocation:(id)sender;
- (IBAction)setLocationURL:(id)sender;
- (IBAction)setCopyDatabaseMode:(id)sender;
- (IBAction)setCopyDatabaseOnOff:(id)sender;
- (IBAction)setLocalizerOnOff:(id)sender;
- (IBAction)setMultipleScreens:(id)sender;
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
