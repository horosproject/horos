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

// This will be added to the main inded page of the Doxygen documentation
/** \mainpage OsiriX index page
*  <img src= "../../../osirix/Binaries/Icons/SmallLogo.tif">
* \section Intro OsiriX DICOM workstation
*  Osirix is a free open source DICOM workstation with full 64 bit support.
*
*  We extend out thanks to other in the open source community.
*
*  VTK, ITK, and DCMTK open source projects are extensively used in OsiriX.
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
	NSRect screenFrame();
	NSString * documentsDirectoryFor( int mode, NSString *url) __deprecated;
	NSString * documentsDirectory() __deprecated;
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

@class AppController, ToolbarPanelController, BonjourPublisher;

extern AppController* OsiriX;

@interface AppController : NSObject	<NSNetServiceBrowserDelegate, NSNetServiceDelegate, NSSoundDelegate> // GrowlApplicationBridgeDelegate
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
+ (BOOL) hasMacOSXLion;
+ (BOOL) hasMacOSXSnowLeopard;
+ (BOOL) hasMacOSXLeopard;

+(NSString*)UID;

#pragma mark-
#pragma mark initialization of the main event loop singleton

+ (void) createNoIndexDirectoryIfNecessary:(NSString*) path __deprecated;
+ (void) displayImportantNotice:(id) sender;
+ (AppController*) sharedAppController; /**< Return the shared AppController instance */
+ (NSString*)checkForPagesTemplate; /**< Check for Pages report template */
+ (void) resizeWindowWithAnimation:(NSWindow*) window newSize: (NSRect) newWindowFrame;
+ (void) pause __deprecated;
+ (void) resetToolbars;
+ (ToolbarPanelController*)toolbarForScreen:(NSScreen*)screen;
+ (NSString*)printStackTrace:(NSException*)e __deprecated; // use -[NSException printStackTrace] form NSException+N2
+ (BOOL) isKDUEngineAvailable;

#pragma mark-
#pragma mark HTML Templates
+ (void)checkForHTMLTemplates __deprecated;


#pragma mark-
#pragma mark  Server management
- (void) terminate :(id) sender; /**< Terminate listener (Q/R SCP) */
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
- (void) tileWindows:(id)sender windows: (NSMutableArray*) viewersList display2DViewerToolbar: (BOOL) display2DViewerToolbar;
- (void) scaleToFit:(id)sender;    /**< Scale opened windows */
- (IBAction) closeAllViewers: (id) sender;  /**< Close All Viewers */
- (void) checkAllWindowsAreVisible:(id) sender;
- (void) checkAllWindowsAreVisible:(id) sender makeKey: (BOOL) makeKey;
//- (IBAction)toggleActivityWindow:(id)sender;
//===============HELP==========================
- (IBAction) sendEmail: (id) sender;   /**< Send email to lead developer */
- (IBAction) openOsirixWebPage: (id) sender;  /**<  Open OsiriX web page */
- (IBAction) openOsirixDiscussion: (id) sender; /**< Open OsiriX discussion web page */
- (IBAction) osirix64bit: (id) sender;
//---------------------------------------------
- (IBAction) help: (id) sender;  /**< Open help window */
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
- (id) FindViewer:(NSString*) nib :(NSMutableArray*) pixList; 
- (NSArray*) FindRelatedViewers:(NSMutableArray*) pixList; /**< Return an array of all WindowControllers using the pixList */
- (IBAction) cancelModal: (id) sender;
- (IBAction) okModal: (id) sender;
- (NSString*) privateIP;
- (void) killDICOMListenerWait:(BOOL) w;
- (void) runPreferencesUpdateCheck:(NSTimer*) timer;
+ (void) checkForPreferencesUpdate: (BOOL) b;
+ (BOOL) USETOOLBARPANEL;
+ (void) setUSETOOLBARPANEL: (BOOL) b;

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

@end

