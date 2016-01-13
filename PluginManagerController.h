/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "PluginManager.h"

/** \brief Window Controller for PluginFilter management */

@interface PluginsTableView : NSTableView
{

}
@end

@interface PluginManagerController : NSWindowController <NSURLDownloadDelegate>
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
	NSString *downloadURL;
	IBOutlet NSButton *downloadButton;
	IBOutlet NSTextField *statusTextField;
	IBOutlet NSProgressIndicator *statusProgressIndicator;
    
    NSMutableDictionary *downloadingPlugins;
}

- (NSMutableArray*)plugins;
- (NSArray*)availabilities;
- (IBAction)modifiyActivation:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)modifiyAvailability:(id)sender;
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
