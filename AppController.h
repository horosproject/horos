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




//#if !__LP64__
#import <Growl/Growl.h>
//#endif

#import <AppKit/AppKit.h>
#import "XMLRPCMethods.h"
#import "WebServicesMethods.h"

#import "IChatTheatreDelegate.h"

@class PreferenceController;
@class BrowserController;
@class SplashScreen;
@class DCMNetServiceDelegate;

enum
{
	always = 0,
	cdOnly = 1,
	notMainDrive = 2,
	ask = 3
};

static unsigned char *LUT12toRGB;
static BOOL canDisplay12Bit;
static NSInvocation *fill12BitBufferInvocation;
@class PluginFilter;
static PluginFilter *totokuPlugin;

#ifdef __cplusplus
extern "C"
{
#endif
	NSRect screenFrame();
	NSString * documentsDirectoryFor( int mode, NSString *url);
	NSString * documentsDirectory();
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
//#if !__LP64__
@interface AppController : NSObject	<GrowlApplicationBridgeDelegate>
//#else
//@interface AppController : NSObject
//#endif
{
	IBOutlet BrowserController		*browserController;

    IBOutlet NSMenu					*filtersMenu;
	IBOutlet NSMenu					*roisMenu;
	IBOutlet NSMenu					*othersMenu;
	IBOutlet NSMenu					*dbMenu;
	IBOutlet NSWindow				*dbWindow;
	
	NSDictionary					*previousDefaults;
	
	BOOL							showRestartNeeded;
		
    SplashScreen					*splashController;
	
    volatile BOOL					quitting;
	BOOL							verboseUpdateCheck;
    NSTask							*theTask;
	NSNetService					*BonjourDICOMService;
	
	BOOL							xFlipped, yFlipped;  // Dependent on current DCMView settings.
	
	NSTimer							*updateTimer;
	DCMNetServiceDelegate			*dicomNetServiceDelegate;
	XMLRPCMethods					*XMLRPCServer;
	WebServicesMethods				*webServer;
}

#pragma mark-
#pragma mark initialization of the main event loop singleton

+ (void) displayImportantNotice:(id) sender;
+ (id) sharedAppController; /**< Return the shared AppController instance */
+ (void)checkForPagesTemplate; /**< Check for Pages report template */
+ (NSString*) currentHostName; /**< Return Network hostname */
+ (void) resizeWindowWithAnimation:(NSWindow*) window newSize: (NSRect) newWindowFrame;
+ (NSThread*) mainThread;

#pragma mark-
#pragma mark HTML Templates
+ (void)checkForHTMLTemplates;


#pragma mark-
#pragma mark  Server management
- (void) terminate :(id) sender; /**< Terminate listener (Q/R SCP) */
- (void) restartSTORESCP; /**< Restart listener (Q/R SCP) */
- (void) startSTORESCP:(id) sender; /**< Start listener (Q/R SCP) */
- (void) startDICOMBonjourSearch; /**< Use Bonjour to search for other DICOM services */



#pragma mark-
#pragma mark static menu items
//===============OSIRIX========================
- (IBAction) about:(id)sender; /**< Display the about window */
- (IBAction) showPreferencePanel:(id)sender; /**< Show Preferences window */
- (IBAction) checkForUpdates:(id) sender;  /**< Check for update */
//===============WINDOW========================
- (void) tileWindows:(id)sender;  /**< Tile open window */
- (void) scaleToFit:(id)sender;    /**< Scale opened windows */
- (IBAction) closeAllViewers: (id) sender;  /**< Close All Viewers */
- (void) checkAllWindowsAreVisible:(id) sender;
- (void) checkAllWindowsAreVisible:(id) sender makeKey: (BOOL) makeKey;
//===============HELP==========================
- (IBAction) sendEmail: (id) sender;   /**< Send email to lead developer */
- (IBAction) openOsirixWebPage: (id) sender;  /**<  Open OsiriX web page */
- (IBAction) openOsirixDiscussion: (id) sender; /**< Open OsiriX discussion web page */
- (IBAction) osirix64bit: (id) sender;
//---------------------------------------------
- (IBAction) help: (id) sender;  /**< Open help window */
//=============================================

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
- (BOOL) echoTest;

#pragma mark-
#pragma mark growl
- (void) growlTitle:(NSString*) title description:(NSString*) description name:(NSString*) name;
- (NSDictionary *) registrationDictionaryForGrowl;

//#pragma mark-
//#pragma mark display setters and getters
//- (IBAction) saveLayout: (id)sender;

#pragma mark-
#pragma mark Geneva University Hospital (HUG) specific function
- (void) HUGVerifyComPACSPlugin;
- (void) HUGDisableBonjourFeature;

#pragma mark-
#pragma mark 12 Bit Display support.
+ (BOOL)canDisplay12Bit;
+ (void)setCanDisplay12Bit:(BOOL)boo;
+ (void)setLUT12toRGB:(unsigned char*)lut;
+ (unsigned char*)LUT12toRGB;
+ (void)set12BitInvocation:(NSInvocation*)invocation;
+ (NSInvocation*)fill12BitBufferInvocation;

@end

