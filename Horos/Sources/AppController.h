/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


// This will be added to the main inded page of the Doxygen documentation
/** \mainpage Horos index page
*  <img src= "../../../osirix/Binaries/Icons/SmallLogo.tif">
* \section Intro Horos DICOM workstation
*  Osirix is a free open source DICOM workstation with full 64 bit support.
*
*  We extend out thanks to other in the open source community.
*
*  VTK, ITK, and DCMTK open source projects are extensively used in Horos.
*
*  The OsiriX team.
*/

#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
#ifndef MACAPPSTORE
#import <Growl/Growl.h>
#endif
#endif
#endif

#import <AppKit/AppKit.h>
#import "XMLRPCMethods.h"

#include "options.h"

//@class ThreadPoolServer;
//@class ThreadPerConnectionServer;

//#import "IChatTheatreDelegate.h"

@class PreferenceController;
@class BrowserController;
@class SplashScreen;
@class DCMNetServiceDelegate;
@class WebPortal;

enum
{
	compression_sameAsDefault = 0,
	compression_none = 1,
	compression_JPEG = 2,
	compression_JPEG2000 = 3,
    compression_JPEGLS = 4
};

enum
{
	always = 0,
	cdOnly = 1,
	notMainDrive = 2,
	ask = 3
};

@class PluginFilter;

#ifdef __cplusplus
extern "C"
{
#endif
    NSRect screenFrame(void);
	NSString * documentsDirectoryFor( int mode, NSString *url) __deprecated;
    NSString * documentsDirectory(void) __deprecated;
#ifdef __cplusplus
}
#endif

/** \brief  NSApplication delegate
*
*  NSApplication delegate 
*  Primarily manages the user defaults and server
*  Also controls some general main items
*
*
*/

//#if defined(OSIRIX_VIEWER) && !defined(OSIRIX_LIGHT) && !defined(MACAPPSTORE)
//#else
//@protocol GrowlApplicationBridgeDelegate
//@end
//#endif

@class AppController, ToolbarPanelController, ThumbnailsListPanel, BonjourPublisher;

extern AppController* OsiriX;

@interface AppController : NSObject	<NSNetServiceBrowserDelegate, NSNetServiceDelegate, NSSoundDelegate, NSMenuDelegate > //, FRFeedbackReporterDelegate> // GrowlApplicationBridgeDelegate
{
	IBOutlet BrowserController		*browserController;

    IBOutlet NSMenu					*filtersMenu;
	IBOutlet NSMenu					*roisMenu;
	IBOutlet NSMenu					*othersMenu;
	IBOutlet NSMenu					*dbMenu;
	IBOutlet NSWindow				*dbWindow;
	IBOutlet NSMenu					*windowsTilingMenuRows, *windowsTilingMenuColumns;
    IBOutlet NSMenu                 *recentStudiesMenu;
	
	NSDictionary					*previousDefaults;
	
	BOOL							showRestartNeeded;
		
    SplashScreen					*splashController;
	
    volatile BOOL					quitting;
	BOOL							verboseUpdateCheck;
	NSNetService					*BonjourDICOMService;
	
	NSTimer							*updateTimer;
	XMLRPCInterface					*XMLRPCServer;
	
	BOOL							checkAllWindowsAreVisibleIsOff, isSessionInactive;
	
	int								lastColumns, lastRows, lastCount;
    
    BonjourPublisher* _bonjourPublisher;
}

@property BOOL checkAllWindowsAreVisibleIsOff, isSessionInactive;
@property (readonly) NSMenu *filtersMenu, *recentStudiesMenu, *windowsTilingMenuRows, *windowsTilingMenuColumns;
@property(readonly) NSNetService* dicomBonjourPublisher;
@property (readonly) XMLRPCInterface *XMLRPCServer;
@property(readonly) BonjourPublisher* bonjourPublisher;

+ (BOOL) isFDACleared;
+ (BOOL) willExecutePlugin;
+ (BOOL) willExecutePlugin:(id) filter;

+ (BOOL) hasMacOSXLeopard;
+ (BOOL) hasMacOSXSnowLeopard;
+ (BOOL) hasMacOSXLion;         // >= 10.7.5
+ (BOOL) hasMacOSXMountainLion;
+ (BOOL) hasMacOSX1083;
+ (BOOL) hasMacOSXMaverick;
+ (BOOL) hasMacOSXYosemite;

+(NSString*)UID;

#pragma mark-
#pragma mark initialization of the main event loop singleton

+ (void) createNoIndexDirectoryIfNecessary:(NSString*) path __deprecated;
#ifdef WITH_IMPORTANT_NOTICE
+ (void) displayImportantNotice:(id) sender;
#endif
+ (AppController*) sharedAppController; /**< Return the shared AppController instance */
+ (void) resizeWindowWithAnimation:(NSWindow*) window newSize: (NSRect) newWindowFrame;
+ (void) pause __deprecated;
+ (ThumbnailsListPanel*)thumbnailsListPanelForScreen:(NSScreen*)screen;
+ (NSString*)printStackTrace:(NSException*)e __deprecated; // use -[NSException printStackTrace] from NSException+N2
+ (BOOL) isKDUEngineAvailable;

#pragma mark-
#pragma mark HTML Templates
+ (void)checkForHTMLTemplates __deprecated;


#pragma mark-
#pragma mark  Server management
- (IBAction) terminate :(id) sender; /**< Terminate listener (Q/R SCP) */
- (void) restartSTORESCP; /**< Restart listener (Q/R SCP) */
- (void) startSTORESCP:(id) sender; /**< Start listener (Q/R SCP) */
- (void) startSTORESCPTLS:(id) sender; /**< Start TLS listener (Q/R SCP) */
- (void) installPlugins: (NSArray*) pluginsArray;
- (BOOL) isStoreSCPRunning;

#pragma mark-
#pragma mark static menu items
//===============OSIRIX========================
- (IBAction) about:(id)sender; /**< Display the about window */
- (IBAction) showPreferencePanel:(id)sender; /**< Show Preferences window */
#ifndef OSIRIX_LIGHT
#ifndef MACAPPSTORE
- (IBAction) checkForUpdates:(id) sender;  /**< Check for update */
#endif
- (IBAction) autoQueryRefresh:(id)sender;
#endif
//===============WINDOW========================
- (IBAction) setFixedTilingRows: (id) sender;
- (IBAction) setFixedTilingColumns: (id) sender;
- (void) initTilingWindows;
- (IBAction) tileWindows:(id)sender;  /**< Tile open window */
- (IBAction) tile3DWindows:(id)sender; /**< Tile 3D open window */
- (void) tileWindows:(id)sender windows: (NSMutableArray*) viewersList display2DViewerToolbar: (BOOL) display2DViewerToolbar displayThumbnailsList: (BOOL) displayThumbnailsList;
- (void) scaleToFit:(id)sender;    /**< Scale opened windows */
- (IBAction) closeAllViewers: (id) sender;  /**< Close All Viewers */
- (void) checkAllWindowsAreVisible:(id) sender;
- (void) checkAllWindowsAreVisible:(id) sender makeKey: (BOOL) makeKey;
//- (IBAction)toggleActivityWindow:(id)sender;


//===============HELP==========================
- (IBAction) openHorosWebPage: (id) sender;
- (IBAction) help: (id) sender;
- (IBAction) openHorosSupport: (id) sender;
- (IBAction) openCommunityPage: (id) sender;
- (IBAction) openBugReportPage:(id)sender;
- (IBAction) sendEmail: (id) sender;
- (IBAction) osirix64bit: (id) sender;
//=============================================

- (IBAction) killAllStoreSCU:(id) sender;

- (id) splashScreen;

#pragma mark-
#pragma mark window routines
- (IBAction) updateViews:(id) sender;  /**< Update Viewers */
- (NSScreen *)dbScreen;  /**< Return monitor with DB */
- (NSArray *)viewerScreens; /**< Return array of monitors for displaying viewers */

 /** 
 * Find the WindowController with the named nib and using the pixList
 * This is commonly used to find the 3D Viewer associated with a ViewerController.
 * Conversely this could be used to find the ViewerController that created a 3D Viewer
 * Each 3D Viewer has its own distinctly named nib as does the ViewerController.
 * The pixList is the Array of DCMPix that the viewer uses.  It should uniquely identify related viewers
*/
- (id) FindViewer:(NSString*) nib :(NSArray*) pixList;
- (NSArray*) FindRelatedViewers:(NSArray*) pixList; /**< Return an array of all WindowControllers using the pixList */
- (IBAction) cancelModal: (id) sender;
- (IBAction) okModal: (id) sender;
- (NSString*) privateIP;
- (void) killDICOMListenerWait:(BOOL) w;
- (void) runPreferencesUpdateCheck:(NSTimer*) timer;
+ (void) checkForPreferencesUpdate: (BOOL) b;
+ (BOOL) USETOOLBARPANEL;
+ (void) setUSETOOLBARPANEL: (BOOL) b;
+ (NSRect) usefullRectForScreen: (NSScreen*) screen;

- (void) addStudyToRecentStudiesMenu: (NSManagedObjectID*) studyID;
- (void) loadRecentStudy: (id) sender;
- (void) buildRecentStudiesMenu;

- (NSMenu*) viewerMenu;
- (NSMenu*) fileMenu;
- (NSMenu*) exportMenu;
- (NSMenu*)imageTilingMenu;
- (NSMenu*) orientationMenu;
- (NSMenu*) opacityMenu;
- (NSMenu*) wlwwMenu;
- (NSMenu*) convMenu;
- (NSMenu*) clutMenu;
- (NSMenu*) workspaceMenu;

#pragma mark-
#pragma mark growl
- (void) growlTitle:(NSString*) title description:(NSString*) description name:(NSString*) name;
//- (NSDictionary *) registrationDictionaryForGrowl;

//#pragma mark-
//#pragma mark display setters and getters
//- (IBAction) saveLayout: (id)sender;

#pragma mark-
#pragma mark 12 Bit Display support.
+ (BOOL)canDisplay12Bit;
+ (void)setCanDisplay12Bit:(BOOL)boo;
+ (void)setLUT12toRGB:(unsigned char*)lut;
+ (unsigned char*)LUT12toRGB;
+ (void)set12BitInvocation:(NSInvocation*)invocation;
+ (NSInvocation*)fill12BitBufferInvocation;

#pragma mark -
-(WebPortal*)defaultWebPortal;

#ifndef OSIRIX_LIGHT
-(NSString*)weasisBasePath;
#endif

-(void)setReceivingIcon;
-(void)unsetReceivingIcon;
-(void)setBadgeLabel:(NSString*)label;

- (void)playGrabSound;

- (void)displayError:(NSString *)err;

@end

