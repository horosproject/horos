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
#import <WebKit/WebKit.h>
#import "PluginManager.h"

/** \brief Window Controller for PluginFilter management */

@interface PluginsTableView : NSTableView
{

}
@end

@interface PluginManagerController : NSWindowController
{

    IBOutlet NSMenu	*filtersMenu;
	IBOutlet NSMenu	*roisMenu;
	IBOutlet NSMenu	*othersMenu;
	IBOutlet NSMenu	*dbMenu;

	NSMutableArray* plugins;
	IBOutlet NSArrayController* pluginsArrayController;
	IBOutlet PluginsTableView *pluginTable;
	
	IBOutlet NSTabView *tabView;
	IBOutlet NSTabViewItem *installedPluginsTabViewItem, *webViewTabViewItem;
	
	IBOutlet WebView *webView;
	NSArray *pluginsListURLs;
	IBOutlet NSPopUpButton *pluginsListPopUp;
	NSString *downloadURL, *downloadedFilePath;
	IBOutlet NSButton *downloadButton;
	IBOutlet NSTextField *statusTextField;
	IBOutlet NSProgressIndicator *statusProgressIndicator;
	
	BOOL pluginsNeedToReload;
}

- (NSMutableArray*)plugins;
- (NSArray*)availabilities;
- (IBAction)modifiyActivation:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)modifiyAvailability:(id)sender;
- (void)loadPlugins;
- (IBAction)loadPlugins:(id)sender;
- (void)refreshPluginList;

- (NSArray*)availablePlugins;
- (void)generateAvailablePluginsMenu;
- (void)setURL:(NSString*)url;
- (IBAction)changeWebView:(id)sender;
- (void)setURLforPluginWithName:(NSString*)name;

- (void)setDownloadURL:(NSString*)url;
- (IBAction)download:(id)sender;

- (void)installDownloadedPluginAtPath:(NSString*)path;
- (BOOL)isZippedFileAtPath:(NSString*)path;
- (BOOL)unZipFileAtPath:(NSString*)path;
- (void)loadSubmitPluginPage;

@end
