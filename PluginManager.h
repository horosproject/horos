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



#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"

@interface PluginManager : NSObject
{
}

- (void)discoverPlugins;
- (void) setMenus:(NSMenu*) filtersMenu :(NSMenu*) roisMenu :(NSMenu*) othersMenu :(NSMenu*) dbMenu;

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
+ (void)desactivatePluginWithName:(NSString*)pluginName;
+ (void)deletePluginWithName:(NSString*)pluginName;
+ (NSArray*)pluginsList;
+ (void)createDirectory:(NSString*)directoryPath;

@end
