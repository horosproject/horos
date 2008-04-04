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



#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
/** \brief Mangages PluginFilter loading */
@interface PluginManager : NSObject
{
}

+ (NSMutableDictionary*) plugins;
+ (NSMutableDictionary*) pluginsDict;
+ (NSMutableDictionary*) fileFormatPlugins;
+ (NSMutableDictionary*) reportPlugins;
+ (NSArray*) preProcessPlugins;
+ (NSMenu*) fusionPluginsMenu;

#ifdef OSIRIX_VIEWER

+ (NSString*) pathResolved:(NSString*) inPath;
+ (void)discoverPlugins;
+ (void) setMenus:(NSMenu*) filtersMenu :(NSMenu*) roisMenu :(NSMenu*) othersMenu :(NSMenu*) dbMenu;

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
+ (void)deletePluginWithName:(NSString*)pluginName;
+ (NSArray*)pluginsList;
+ (void)createDirectory:(NSString*)directoryPath;
+ (NSArray*)availabilities;

- (IBAction)checkForUpdates:(id)sender;
- (void)displayUpdateMessage:(NSDictionary*)messageDictionary;

#endif

@end
