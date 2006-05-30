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




#import <AppKit/AppKit.h>
//#import "DICOMStoreSCPDispatcher.h"

@class PreferenceController;
@class BrowserController;
@class SplashScreen;
@class DCMNetServiceDelegate;

//#define SINGLE_WINDOW_MODE YES
enum
{
	always = 0,
	cdOnly = 1,
	notMainDrive = 2,
	ask = 3
};

NSRect screenFrame();

@interface AppController : NSObject
{
	IBOutlet BrowserController		*browserController;

    IBOutlet NSMenu					*filtersMenu;
	IBOutlet NSMenu					*roisMenu;
	IBOutlet NSMenu					*othersMenu;
	IBOutlet NSMenu					*dbMenu;
	IBOutlet NSMenuItem				*syncSeriesMenuItem;
	IBOutlet NSWindow				*dbWindow;
		
    SplashScreen					*splashController;
	
    volatile BOOL					quitting;
	BOOL							verboseUpdateCheck;
    NSTask							*theTask;
	
	BOOL							xFlipped, yFlipped;  // Dependent on current DCMView settings.
	
	//DICOMStoreSCPDispatcher *dicomStoreSCPDispatcher;
	NSMutableDictionary *currentHangingProtocol;
	DCMNetServiceDelegate *dicomNetServiceDelegate;
}
#pragma mark-
#pragma mark initialization of the main event loop singleton
+ (id) sharedAppController;
- (void) terminate :(id) sender;
- (void) restartSTORESCP;
- (void) startSTORESCP:(id) sender;
- (void) startDICOMBonjourSearch;

#pragma mark-
#pragma mark static menu items
//===============OSIRIX========================
- (IBAction) about:(id)sender;
- (IBAction) showPreferencePanel:(id)sender;
- (IBAction) checkForUpdates:(id) sender;
//===============2D VIEWER=====================
- ( NSMenuItem *)	syncSeriesMenuItem;
//===============WINDOW========================
- (void) tileWindows:(id)sender;
- (IBAction) closeAllViewers: (id) sender;
//===============HELP==========================
- (IBAction) sendEmail: (id) sender;
- (IBAction) openOsirixWebPage: (id) sender;
- (IBAction) openOsirixDiscussion: (id) sender;
//---------------------------------------------
- (IBAction) help: (id) sender;
- (IBAction) openOsirixWikiWebPage: (id) sender;
//=============================================

#pragma mark-
#pragma mark window routines
- (IBAction) updateViews:(id) sender;
- (NSScreen *)dbScreen;
- (NSArray *)viewerScreens;
- (id) FindViewer:(NSString*) nib :(NSMutableArray*) pixList;
- (NSArray*) FindRelatedViewers:(NSMutableArray*) pixList;
- (IBAction) cancelModal: (id) sender;
- (IBAction) okModal: (id) sender;

#pragma mark-
#pragma mark display setters and getters
- (void) setCurrentHangingProtocolForModality: (NSString*) modality description: (NSString*) description;
- (NSDictionary*) currentHangingProtocol;
- (BOOL) xFlipped;
- (void) setXFlipped: (BOOL) v;
- (BOOL) yFlipped;
- (void) setYFlipped: (BOOL) v;

#pragma mark-
#pragma mark Geneva University Hospital (HUG) specific function
+ (BOOL) isHUG;
- (void) HUGVerifyComPACSPlugin;
- (void) HUGDisableBonjourFeature;
@end

