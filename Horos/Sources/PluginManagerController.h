/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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

@interface PluginManagerController : NSWindowController <NSURLDownloadDelegate, WebPolicyDelegate>
{

    IBOutlet NSMenu	*filtersMenu;
	IBOutlet NSMenu	*roisMenu;
	IBOutlet NSMenu	*othersMenu;
	IBOutlet NSMenu	*dbMenu;

	NSMutableArray* plugins;
	IBOutlet NSArrayController* pluginsArrayController;
	IBOutlet PluginsTableView *pluginTable;
	
	IBOutlet NSTabView *tabView;
	IBOutlet NSTabViewItem *installedPluginsTabViewItem, *osirixPluginsTabViewItem, *horosPluginsTabViewItem;
	
    IBOutlet WebView *osirixPluginWebView, *horosPluginWebView;
	NSArray *osirixPluginListURLs, *horosPluginListURLs;
    IBOutlet NSPopUpButton *osirixPluginListPopUp, *horosPluginListPopUp;
	NSString *osirixPluginDownloadURL, *horosPluginDownloadURL;
    BOOL osiriXPluginHorosCompatibility;
    IBOutlet NSButton *osirixPluginDownloadButton, *horosPluginDownloadButton;
    
    IBOutlet NSTextField *osirixPluginStatusTextField, *horosPluginStatusTextField;
    IBOutlet NSProgressIndicator *osirixPluginStatusProgressIndicator, *horosPluginStatusProgressIndicator;
    
    IBOutlet NSBox *validatedInHorosBox;
    IBOutlet NSBox *NOTvalidatedInHorosBox;
    IBOutlet NSTextField *protectedModeLabel;
    
    NSMutableDictionary *downloadingPlugins;
}

- (NSMutableArray*)plugins;
- (NSArray*)availabilities;
- (IBAction)modifiyActivation:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)modifiyAvailability:(id)sender;
- (IBAction)loadPlugins:(id)sender;
- (void)refreshPluginList;

- (NSArray*)availableOsiriXPlugins;
- (NSArray*)availableHorosPlugins;
- (void)generateAvailableOsiriXPluginsMenu;
- (void)generateAvailableHorosPluginsMenu;
- (void)setOsiriXPluginURL:(NSString*)url;
- (void)setHorosPluginURL:(NSString*)url;
- (IBAction) changeOsiriXPluginWebView:(id)sender;
- (IBAction) changeHorosPluginWebView:(id)sender;
- (void)setURLforOsiriXPluginWithName:(NSString*)name;
- (void)setURLforHorosPluginWithName:(NSString*)name;
- (void)setOsiriXPluginDownloadURL:(NSString*)url;
- (void)setHorosPluginDownloadURL:(NSString*)url;

- (IBAction) downloadOsiriXPlugin:(id)sender;
- (IBAction) downloadHorosPlugin:(id)sender;

- (void)installDownloadedPluginAtPath:(NSString*)path;
- (BOOL)isZippedFileAtPath:(NSString*)path;
- (BOOL)unZipFileAtPath:(NSString*)path;
- (void)loadSubmitPluginPage;

@end
