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
#import "PluginFilter.h"
/** \brief Mangages PluginFilter loading */
@interface PluginManager : NSObject
{
	NSMutableArray *downloadQueue;
	BOOL startedUpdateProcess;
}

@property(retain,readwrite) NSMutableArray *downloadQueue;

+ (int) compareVersion: (NSString *) v1 withVersion: (NSString *) v2;
+ (NSMutableDictionary*) plugins;
+ (NSMutableDictionary*) pluginsDict;
+ (NSMutableDictionary*) fileFormatPlugins;
+ (NSMutableDictionary*) reportPlugins;
+ (NSArray*) preProcessPlugins;
+ (NSMenu*) fusionPluginsMenu;
+ (NSArray*) fusionPlugins;

+ (void) startProtectForCrashWithFilter: (id) filter;
+ (void) startProtectForCrashWithPath: (NSString*) path;
+ (void) endProtectForCrash;

#ifdef OSIRIX_VIEWER

+ (NSString*) pathResolved:(NSString*) inPath __deprecated;
+ (void)discoverPlugins;
+ (void) unloadPluginWithName: (NSString*) name;
+ (void) loadPluginAtPath: (NSString*) path;
+ (void) setMenus:(NSMenu*) filtersMenu :(NSMenu*) roisMenu :(NSMenu*) othersMenu :(NSMenu*) dbMenu;
+ (BOOL) isComPACS;
+ (void) installPluginFromPath: (NSString*) path;
+ (NSString*)activePluginsDirectoryPath;
+ (NSString*)inactivePluginsDirectoryPath;
+ (NSString*)userActivePluginsDirectoryPath;
+ (NSString*)userInactivePluginsDirectoryPath;
+ (NSString*)systemActivePluginsDirectoryPath;
+ (NSString*)systemInactivePluginsDirectoryPath;
+ (NSString*)appActivePluginsDirectoryPath;
+ (NSString*)appInactivePluginsDirectoryPath;
+ (NSArray*)activeDirectories;
+ (NSArray*)inactiveDirectories;
+ (void)movePluginFromPath:(NSString*)sourcePath toPath:(NSString*)destinationPath;
+ (void)activatePluginWithName:(NSString*)pluginName;
+ (void)deactivatePluginWithName:(NSString*)pluginName;
+ (void)changeAvailabilityOfPluginWithName:(NSString*)pluginName to:(NSString*)availability;
+ (NSString*)deletePluginWithName:(NSString*)pluginName;
+ (NSString*) deletePluginWithName:(NSString*)pluginName availability: (NSString*) availability isActive:(BOOL) isActive;
+ (NSArray*)pluginsList;
+ (void)createDirectory:(NSString*)directoryPath;
+ (NSArray*)availabilities;

- (IBAction)checkForUpdates:(id)sender;
- (void)displayUpdateMessage:(NSDictionary*)messageDictionary;

#endif

@end
