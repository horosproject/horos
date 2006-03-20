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

+ (id) sharedAppController;


- (IBAction) cancelModal: (id) sender;
- (IBAction) okModal: (id) sender;
- (IBAction) sendEmail: (id) sender;
- (IBAction) openOsirixWebPage: (id) sender;
- (IBAction) help: (id) sender;
- (IBAction) openOsirixWikiWebPage: (id) sender;
- (IBAction) openOsirixDiscussion: (id) sender;
- (IBAction) openOsirixBugReporter: (id) sender;
- (IBAction) openOsirixFeatureRequest: (id) sender;

- (IBAction) closeAllViewers: (id) sender;
- (IBAction) updateViews:(id) sender;
- (IBAction) checkForUpdates:(id) sender;
- (IBAction) showPreferencePanel:(id)sender;
- (IBAction) about:(id)sender;
- (void) startSTORESCP:(id) sender;
- (void) tileWindows:(id)sender;
- (NSScreen *)dbScreen;
- (NSArray *)viewerScreens;
- (void) restartSTORESCP;
- (id) FindViewer:(NSString*) nib :(NSMutableArray*) pixList;
- (NSArray*) FindRelatedViewers:(NSMutableArray*) pixList;
- (void) setCurrentHangingProtocolForModality: (NSString*) modality description: (NSString*) description;
- (NSDictionary*) currentHangingProtocol;

- (void) terminate :(id) sender;
- (IBAction) cancelModal:(id) sender;
- (IBAction) okModal:(id) sender;
- (void) startDICOMBonjourSearch;

- (BOOL) xFlipped;
- (void) setXFlipped: (BOOL) v;
- (BOOL) yFlipped;
- (void) setYFlipped: (BOOL) v;

- ( NSMenuItem *)	syncSeriesMenuItem;

#pragma mark-
#pragma mark Geneva University Hospital (HUG) specific function
+ (BOOL) isHUG;
- (void) HUGVerifyComPACSPlugin;
- (void) HUGDisableBonjourFeature;
@end
