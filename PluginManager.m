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


#import "PluginManager.h"
#import "ViewerController.h"

#import "browserController.h"
#import "BLAuthentication.h"


static NSMutableDictionary		*plugins = 0L, *pluginsDict = 0L, *fileFormatPlugins = 0L;
static NSMutableDictionary		*reportPlugins = 0L;

static NSMutableArray			*preProcessPlugins = 0L;
static NSMenu					*fusionPluginsMenu = 0L;

@implementation PluginManager

+ (NSMutableDictionary*) plugins
{
	return plugins;
}

+ (NSMutableDictionary*) pluginsDict
{
	return pluginsDict;
}

+ (NSMutableDictionary*) fileFormatPlugins
{
	return fileFormatPlugins;
}

+ (NSMutableDictionary*) reportPlugins
{
	return reportPlugins;
}

+ (NSArray*) preProcessPlugins
{
	return preProcessPlugins;
}

+ (NSMenu*) fusionPluginsMenu
{
	return fusionPluginsMenu;
}

#ifdef OSIRIX_VIEWER

+ (void) setMenus:(NSMenu*) filtersMenu :(NSMenu*) roisMenu :(NSMenu*) othersMenu :(NSMenu*) dbMenu
{
	while([filtersMenu numberOfItems])[filtersMenu removeItemAtIndex:0];
	while([roisMenu numberOfItems])[roisMenu removeItemAtIndex:0];
	while([othersMenu numberOfItems])[othersMenu removeItemAtIndex:0];
	while([dbMenu numberOfItems])[dbMenu removeItemAtIndex:0];
	
	NSEnumerator *enumerator = [pluginsDict objectEnumerator];
	NSBundle *plugin;
	
	while ((plugin = [enumerator nextObject]))
	{
		NSString	*pluginName = [[plugin infoDictionary] objectForKey:@"CFBundleExecutable"];
		NSString	*pluginType = [[plugin infoDictionary] objectForKey:@"pluginType"];
		NSArray		*menuTitles = [[plugin infoDictionary] objectForKey:@"MenuTitles"];
	
		if( menuTitles)
		{
			if( [menuTitles count] > 1)
			{
				// Create a sub menu item
				
				NSMenu  *subMenu = [[[NSMenu alloc] initWithTitle: pluginName] autorelease];
				
				for( NSString *menuTitle in menuTitles)
				{
					NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
					[item setTitle:menuTitle];
					
					if( [pluginType isEqualToString:@"fusionFilter"])
					{
						[item setTag:-1];		// Useful for fusionFilter
						[item setAction:@selector(endBlendingType:)];
					}
					else if( [pluginType isEqualToString:@"Database"] || [pluginType isEqualToString:@"Report"]){
						[item setTarget: [BrowserController currentBrowser]];	//  browserWindow responds to DB plugins
						[item setAction:@selector(executeFilterDB:)];
					}
					else
					{
						[item setTarget:0L];	// FIRST RESPONDER !
						[item setAction:@selector(executeFilter:)];
					}
					
					[subMenu insertItem:item atIndex:[subMenu numberOfItems]];
				}
				
				id  subMenuItem;
				
				if( [pluginType isEqualToString:@"imageFilter"])
				{
					if( [filtersMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [filtersMenu insertItemWithTitle:pluginName action:0L keyEquivalent:@"" atIndex:[filtersMenu numberOfItems]];
						[filtersMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType isEqualToString:@"roiTool"])
				{
					if( [roisMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [roisMenu insertItemWithTitle:pluginName action:0L keyEquivalent:@"" atIndex:[roisMenu numberOfItems]];
						[roisMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType isEqualToString:@"fusionFilter"])
				{
					if( [fusionPluginsMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [fusionPluginsMenu insertItemWithTitle:pluginName action:0L keyEquivalent:@"" atIndex:[roisMenu numberOfItems]];
						[fusionPluginsMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType isEqualToString:@"Database"])
				{
					if( [dbMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [dbMenu insertItemWithTitle:pluginName action:0L keyEquivalent:@"" atIndex:[dbMenu numberOfItems]];
						[dbMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				} 
				else
				{
					if( [othersMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [othersMenu insertItemWithTitle:pluginName action:0L keyEquivalent:@"" atIndex:[othersMenu numberOfItems]];
						[othersMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
			}
			else
			{
				// Create a menu item
				
				NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
				
				[item setTitle: [menuTitles objectAtIndex: 0]];	//pluginName];
				
				if( [pluginType isEqualToString:@"fusionFilter"])
				{
					[item setTag:-1];		// Useful for fusionFilter
					[item setAction:@selector(endBlendingType:)];
				}
				else if( [pluginType isEqualToString:@"Database"] || [pluginType isEqualToString:@"Report"])
				{
					[item setTarget:[BrowserController currentBrowser]];	//  browserWindow responds to DB plugins
					[item setAction:@selector(executeFilterDB:)];
				}
				else
				{
					[item setTarget:0L];	// FIRST RESPONDER !
					[item setAction:@selector(executeFilter:)];
				}
				
				if( [pluginType isEqualToString:@"imageFilter"])		[filtersMenu insertItem:item atIndex:[filtersMenu numberOfItems]];
				else if( [pluginType isEqualToString:@"roiTool"])		[roisMenu insertItem:item atIndex:[roisMenu numberOfItems]];
				else if( [pluginType isEqualToString:@"fusionFilter"])	[fusionPluginsMenu insertItem:item atIndex:[fusionPluginsMenu numberOfItems]];
				else if( [pluginType isEqualToString:@"Database"])		[dbMenu insertItem:item atIndex:[dbMenu numberOfItems]];
				else [othersMenu insertItem:item atIndex:[othersMenu numberOfItems]];
			}
		}
	}
	
	if( [filtersMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)]; 
		
		[filtersMenu insertItem:item atIndex:0];
	}
	
	if( [roisMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[roisMenu insertItem:item atIndex:0];
	}
	
	if( [othersMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[othersMenu insertItem:item atIndex:0];
	}
	
	if( [fusionPluginsMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[fusionPluginsMenu insertItem:item atIndex:0];
	}
	
	if( [dbMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[dbMenu insertItem:item atIndex:0];
	}
	
	NSEnumerator *pluginEnum = [plugins objectEnumerator];
	PluginFilter *pluginFilter;
	
	while ( pluginFilter = [pluginEnum nextObject] ) {
		[pluginFilter setMenus];
	}
}

- (id)init {
	if (self = [super init])
	{
		// Set DefaultROINames *before* initializing plugins (which may change these)
		
		NSMutableArray *defaultROINames = [[NSMutableArray alloc] initWithCapacity:0];
		
		[defaultROINames addObject:@"ROI 1"];
		[defaultROINames addObject:@"ROI 2"];
		[defaultROINames addObject:@"ROI 3"];
		[defaultROINames addObject:@"ROI 4"];
		[defaultROINames addObject:@"ROI 5"];
		[defaultROINames addObject:@"-"];
		[defaultROINames addObject:@"DiasLength"];
		[defaultROINames addObject:@"SystLength"];
		[defaultROINames addObject:@"-"];
		[defaultROINames addObject:@"DiasLong"];
		[defaultROINames addObject:@"SystLong"];
		[defaultROINames addObject:@"-"];
		[defaultROINames addObject:@"DiasHorLong"];
		[defaultROINames addObject:@"SystHorLong"];
		[defaultROINames addObject:@"DiasVerLong"];
		[defaultROINames addObject:@"SystVerLong"];
		[defaultROINames addObject:@"-"];
		[defaultROINames addObject:@"DiasShort"];
		[defaultROINames addObject:@"SystShort"];
		[defaultROINames addObject:@"-"];
		[defaultROINames addObject:@"DiasMitral"];
		[defaultROINames addObject:@"SystMitral"];
		[defaultROINames addObject:@"DiasPapi"];
		[defaultROINames addObject:@"SystPapi"];
		
		[ViewerController setDefaultROINames: defaultROINames];
		
		//[self discoverPlugins];
		[PluginManager discoverPlugins];
	}
	return self;
}

+ (NSString*) pathResolved:(NSString*) inPath
{
	CFStringRef resolvedPath = nil;
	CFURLRef	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)inPath, kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if (url != NULL) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, &targetIsFolder, &wasAliased) == noErr && wasAliased) {
				CFURLRef resolvedurl = CFURLCreateFromFSRef(NULL /*allocator*/, &fsRef);
				if (resolvedurl != NULL) {
					resolvedPath = CFURLCopyFileSystemPath(resolvedurl, kCFURLPOSIXPathStyle);
					CFRelease(resolvedurl);
				}
			}
		}
		CFRelease(url);
	}
	
	if( resolvedPath == 0L) return inPath;
	else return [(NSString *) resolvedPath autorelease];
}

+ (void) discoverPlugins
{
	BOOL		conflict = NO;
    Class		filterClass;
    NSString	*appSupport = @"Library/Application Support/OsiriX/";
    long		i;
	NSString	*appPath = [[NSBundle mainBundle] builtInPlugInsPath];
    NSString	*userPath = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
    NSString	*sysPath = [@"/" stringByAppendingPathComponent:appSupport];
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:appPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:appPath attributes:nil];
	if ([[NSFileManager defaultManager] fileExistsAtPath:userPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:userPath attributes:nil];
	if ([[NSFileManager defaultManager] fileExistsAtPath:sysPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:sysPath attributes:nil];
	
    appSupport = [appSupport stringByAppendingPathComponent :@"Plugins/"];
	
	userPath = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
	sysPath = [@"/" stringByAppendingPathComponent:appSupport];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:userPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:userPath attributes:nil];
	if ([[NSFileManager defaultManager] fileExistsAtPath:sysPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:sysPath attributes:nil];
	
	NSArray *paths = [NSArray arrayWithObjects:appPath, userPath, sysPath, nil];
    NSString *path;
	
	[plugins release];
	[pluginsDict release];
	[fileFormatPlugins release];
	[preProcessPlugins release];
	[reportPlugins release];
	[fusionPluginsMenu release];
	
    plugins = [[NSMutableDictionary alloc] init];
	pluginsDict = [[NSMutableDictionary alloc] init];
	fileFormatPlugins = [[NSMutableDictionary alloc] init];
	preProcessPlugins = [[NSMutableArray alloc] initWithCapacity:0];
	reportPlugins = [[NSMutableDictionary alloc] init];
	
	fusionPluginsMenu = [[NSMenu alloc] initWithTitle:@""];
	[fusionPluginsMenu insertItemWithTitle:NSLocalizedString(@"Select a fusion plug-in", nil) action:0L keyEquivalent:@"" atIndex:0];
	
    for ( path in paths )
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		
		while ( name = [e nextObject] )
		{
			if ( [[name pathExtension] isEqualToString:@"plugin"] || [[name pathExtension] isEqualToString:@"osirixplugin"])
			{
				NSBundle *plugin = [NSBundle bundleWithPath:[PluginManager pathResolved:[path stringByAppendingPathComponent:name]]];
				 
				if (filterClass = [plugin principalClass])	
				{
					if ( filterClass == NSClassFromString( @"ARGS" ) ) continue;
					
					if ([[[plugin infoDictionary] objectForKey:@"pluginType"] isEqualToString:@"Pre-Process"]) 
					{
						PluginFilter*	filter = [filterClass filter];
						[preProcessPlugins addObject: filter];
					}
					else if ([[plugin infoDictionary] objectForKey:@"FileFormats"]) 
					{
						NSEnumerator *enumerator = [[[plugin infoDictionary] objectForKey:@"FileFormats"] objectEnumerator];
						NSString *fileFormat;
						while (fileFormat = [enumerator nextObject])
						{
							//we will save the bundle rather than a filter.  Each file decode will require a separate decoder
							[fileFormatPlugins setObject:plugin forKey:fileFormat];
						}
					}
					else if ( [filterClass instancesRespondToSelector:@selector(filterImage:)] )
					{
						NSString	*pluginName = [[plugin infoDictionary] objectForKey:@"CFBundleExecutable"];
						NSString	*pluginType = [[plugin infoDictionary] objectForKey:@"pluginType"];
						NSArray		*menuTitles = [[plugin infoDictionary] objectForKey:@"MenuTitles"];
						
						if( menuTitles)
						{
							PluginFilter*	filter = [filterClass filter];
							
							if( [menuTitles count] > 1)
							{
								
								for( NSString *menuTitle in menuTitles)
								{
									
									[plugins setObject:filter forKey:menuTitle];
									[pluginsDict setObject:plugin forKey:menuTitle];
								}
							}
							else
							{
								[plugins setObject:filter forKey: [menuTitles objectAtIndex: 0]];
								[pluginsDict setObject:plugin forKey:[menuTitles objectAtIndex: 0]];
							}
						}
					}
					
					if ([[[plugin infoDictionary] objectForKey:@"pluginType"] isEqualToString:@"Report"]) 
					{
						[reportPlugins setObject: plugin forKey:[[plugin infoDictionary] objectForKey:@"CFBundleExecutable"]];
					}
				}
				else NSLog( @"********* principal class not found for: %@", name);
			}
		}
    }
}

-(void) noPlugins:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Plugins.html"]];
}

#pragma mark -
#pragma mark Plugin user management

#pragma mark directories

+ (NSString*)activePluginsDirectoryPath;
{
	return @"Library/Application Support/OsiriX/Plugins/";
}

+ (NSString*)inactivePluginsDirectoryPath;
{
	return @"Library/Application Support/OsiriX/Plugins (off)/";
}

+ (NSString*)userActivePluginsDirectoryPath;
{
	return [NSHomeDirectory() stringByAppendingPathComponent:[PluginManager activePluginsDirectoryPath]];
}

+ (NSString*)userInactivePluginsDirectoryPath;
{
	return [NSHomeDirectory() stringByAppendingPathComponent:[PluginManager inactivePluginsDirectoryPath]];
}

+ (NSString*)systemActivePluginsDirectoryPath;
{
	NSString *s = @"/";
	return [s stringByAppendingPathComponent:[PluginManager activePluginsDirectoryPath]];
}

+ (NSString*)systemInactivePluginsDirectoryPath;
{
	NSString *s = @"/";
	return [s stringByAppendingPathComponent:[PluginManager inactivePluginsDirectoryPath]];
}

+ (NSString*)appActivePluginsDirectoryPath;
{
	return [[NSBundle mainBundle] builtInPlugInsPath];
}

+ (NSString*)appInactivePluginsDirectoryPath;
{
	NSMutableString *appPath = [NSMutableString stringWithString:[[NSBundle mainBundle] builtInPlugInsPath]];
	[appPath appendString:@" (off)"];
	return appPath;
}

+ (NSArray*)activeDirectories;
{
	return [NSArray arrayWithObjects:[PluginManager userActivePluginsDirectoryPath], [PluginManager systemActivePluginsDirectoryPath], [PluginManager appActivePluginsDirectoryPath], nil];
}

+ (NSArray*)inactiveDirectories;
{
	return [NSArray arrayWithObjects:[PluginManager userInactivePluginsDirectoryPath], [PluginManager systemInactivePluginsDirectoryPath], [PluginManager appInactivePluginsDirectoryPath], nil];
}

#pragma mark activation

//- (BOOL)pluginIsActiveForName:(NSString*)pluginName;
//{
//	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:0];
//	[paths addObjectsFromArray:[self activeDirectories]];
//	
//	NSEnumerator *pathEnum = [paths objectEnumerator];
//    NSString *path;
//	while(path=[pathEnum nextObject])
//	{
//		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
//		NSString *name;
//		while(name = [e nextObject])
//		{
//			if([[name stringByDeletingPathExtension] isEqualToString:pluginName])
//			{
//				return YES;
//			}
//		}
//	}
//	
//	return NO;
//}

+ (void)movePluginFromPath:(NSString*)sourcePath toPath:(NSString*)destinationPath;
{
    NSMutableArray *args = [NSMutableArray array];
	[args addObject:@"-f"];
    [args addObject:sourcePath];
    [args addObject:destinationPath];

	if([[sourcePath stringByDeletingLastPathComponent] isEqualToString:[PluginManager userActivePluginsDirectoryPath]] || [[sourcePath stringByDeletingLastPathComponent] isEqualToString:[PluginManager userInactivePluginsDirectoryPath]] || [[destinationPath stringByDeletingLastPathComponent] isEqualToString:[PluginManager userActivePluginsDirectoryPath]] || [[destinationPath stringByDeletingLastPathComponent] isEqualToString:[PluginManager userInactivePluginsDirectoryPath]])
	{
		NSTask *aTask = [[NSTask alloc] init];
		[aTask setLaunchPath:@"/bin/mv"];
		[aTask setArguments:args];
		[aTask launch];
		[aTask waitUntilExit];
		[aTask release];
	}
	else
		[[BLAuthentication sharedInstance] executeCommand:@"/bin/mv" withArgs:args];
}

+ (void)activatePluginWithName:(NSString*)pluginName;
{
	NSMutableArray *activePaths = [NSMutableArray arrayWithArray:[PluginManager activeDirectories]];
	NSMutableArray *inactivePaths = [NSMutableArray arrayWithArray:[PluginManager inactiveDirectories]];
	
	NSEnumerator *activePathEnum = [activePaths objectEnumerator];
    NSString *activePath;
    NSString *inactivePath;
	
	for(inactivePath in inactivePaths)
	{
		activePath = [activePathEnum nextObject];
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:inactivePath] objectEnumerator];
		NSString *name;
		while(name = [e nextObject])
		{
			if([[name stringByDeletingPathExtension] isEqualToString:pluginName])
			{
				NSString *sourcePath = [NSString stringWithFormat:@"%@/%@", inactivePath, name];
				NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", activePath, name];
				[PluginManager movePluginFromPath:sourcePath toPath:destinationPath];
			}
		}
	}
}

+ (void)deactivatePluginWithName:(NSString*)pluginName;
{
	NSMutableArray *activePaths = [NSMutableArray arrayWithArray:[PluginManager activeDirectories]];
	NSMutableArray *inactivePaths = [NSMutableArray arrayWithArray:[PluginManager inactiveDirectories]];
	
    NSString *activePath;
	NSEnumerator *inactivePathEnum = [inactivePaths objectEnumerator];
    NSString *inactivePath;
	
	for(activePath in activePaths)
	{
		inactivePath = [inactivePathEnum nextObject];
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:activePath] objectEnumerator];
		NSString *name;
		while(name = [e nextObject])
		{
			if([[name stringByDeletingPathExtension] isEqualToString:pluginName])
			{
				BOOL isDir = YES;
				if (![[NSFileManager defaultManager] fileExistsAtPath:inactivePath isDirectory:&isDir] && isDir)
					[PluginManager createDirectory:inactivePath];
				//	[[NSFileManager defaultManager] createDirectoryAtPath:inactivePath attributes:nil];
				NSString *sourcePath = [NSString stringWithFormat:@"%@/%@", activePath, name];
				NSString *destinationPath = [NSString stringWithFormat:@"%@/%@", inactivePath, name];
				[PluginManager movePluginFromPath:sourcePath toPath:destinationPath];
			}
		}
	}
}

+ (void)changeAvailabilityOfPluginWithName:(NSString*)pluginName to:(NSString*)availability;
{
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:0];
	[paths addObjectsFromArray:[PluginManager activeDirectories]];
	[paths addObjectsFromArray:[PluginManager inactiveDirectories]];

	NSEnumerator *pathEnum = [paths objectEnumerator];
    NSString *path;
	NSString *completePluginPath;
	BOOL found = NO;
	
	while((path = [pathEnum nextObject]) && !found)
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		while((name = [e nextObject]) && !found)
		{
			if([[name stringByDeletingPathExtension] isEqualToString:pluginName])
			{
				completePluginPath = [NSString stringWithFormat:@"%@/%@", path, name];
				found = YES;
			}
		}
	}
	
	NSString *directory = [completePluginPath stringByDeletingLastPathComponent];
	NSMutableString *newDirectory = [NSMutableString stringWithString:@""];
	
	NSArray *availabilities = [PluginManager availabilities];
	if([availability isEqualTo:[availabilities objectAtIndex:0]])
	{
		[newDirectory setString:[PluginManager userActivePluginsDirectoryPath]];
	}
	else if([availability isEqualTo:[availabilities objectAtIndex:1]])
	{
		[newDirectory setString:[PluginManager systemActivePluginsDirectoryPath]];
	}
	else if([availability isEqualTo:[availabilities objectAtIndex:2]])
	{
		[newDirectory setString:[PluginManager appActivePluginsDirectoryPath]];
	}
	[newDirectory setString:[newDirectory stringByDeletingLastPathComponent]]; // remove /Plugins/
	[newDirectory setString:[newDirectory stringByAppendingPathComponent:[directory lastPathComponent]]]; // add /Plugins/ or /Plugins (off)/
	
	NSMutableString *newPluginPath = [NSMutableString stringWithString:@""];
	[newPluginPath setString:[newDirectory stringByAppendingPathComponent:[completePluginPath lastPathComponent]]];
	
	[PluginManager movePluginFromPath:completePluginPath toPath:newPluginPath];
}

+ (void)createDirectory:(NSString*)directoryPath;
{
	BOOL isDir = YES;
	BOOL directoryCreated = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir] && isDir)
		directoryCreated = [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath attributes:nil];

	if(!directoryCreated)
	{
	    NSMutableArray *args = [NSMutableArray array];
		[args addObject:directoryPath];
		[[BLAuthentication sharedInstance] executeCommand:@"/bin/mkdir" withArgs:args];
	}
}

#pragma mark Deletion

+ (void)deletePluginWithName:(NSString*)pluginName;
{
	NSMutableArray *pluginsPaths = [NSMutableArray arrayWithArray:[PluginManager activeDirectories]];
	[pluginsPaths addObjectsFromArray:[PluginManager inactiveDirectories]];
	
    NSString *path;
	
	for(path in pluginsPaths)
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		while(name = [e nextObject])
		{
			if([[name stringByDeletingPathExtension] isEqualToString:pluginName])
			{
				// delete
				BOOL deleted = [[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithFormat:@"%@/%@", path, name] handler:nil];
				if(!deleted)
				{
					NSMutableArray *args = [NSMutableArray array];
					[args addObject:@"-r"];
					[args addObject:[NSString stringWithFormat:@"%@/%@", path, name]];
					[[BLAuthentication sharedInstance] executeCommand:@"/bin/rm" withArgs:args];
				}
			}
		}
	}
}

#pragma mark plugins

NSInteger sortPluginArray(id plugin1, id plugin2, void *context)
{
    NSString *name1 = [plugin1 objectForKey:@"name"];
    NSString *name2 = [plugin2 objectForKey:@"name"];
    
	return [name1 compare:name2];
}

+ (NSArray*)pluginsList;
{
	NSString *userActivePath = [PluginManager userActivePluginsDirectoryPath];
	NSString *userInactivePath = [PluginManager userInactivePluginsDirectoryPath];
	NSString *sysActivePath = [PluginManager systemActivePluginsDirectoryPath];
	NSString *sysInactivePath = [PluginManager systemInactivePluginsDirectoryPath];

//	NSArray *paths = [NSArray arrayWithObjects:userActivePath, userInactivePath, sysActivePath, sysInactivePath, nil];
	
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:0];
	[paths addObjectsFromArray:[PluginManager activeDirectories]];
	[paths addObjectsFromArray:[PluginManager inactiveDirectories]];
	
    NSString *path;
	
    NSMutableArray *plugins = [[NSMutableArray alloc] init];
	Class filterClass;
    for(path in paths)
	{
//		BOOL active = ([path isEqualToString:userActivePath] || [path isEqualToString:sysActivePath]);
//		BOOL allUsers = ([path isEqualToString:sysActivePath] || [path isEqualToString:sysInactivePath]);
		BOOL active = [[PluginManager activeDirectories] containsObject:path];
		BOOL allUsers = ([path isEqualToString:sysActivePath] || [path isEqualToString:sysInactivePath] || [path isEqualToString:[PluginManager appActivePluginsDirectoryPath]] || [path isEqualToString:[PluginManager appInactivePluginsDirectoryPath]]);
		
		NSString *availability;
		if([path isEqualToString:sysActivePath] || [path isEqualToString:sysInactivePath])
			availability = [[PluginManager availabilities] objectAtIndex:1];
		else if([path isEqualToString:[PluginManager appActivePluginsDirectoryPath]] || [path isEqualToString:[PluginManager appInactivePluginsDirectoryPath]])
			availability = [[PluginManager availabilities] objectAtIndex:2];
		else if([path isEqualToString:userActivePath] || [path isEqualToString:userInactivePath])
			availability = [[PluginManager availabilities] objectAtIndex:0];
		
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		while(name = [e nextObject])
		{
			if([[name pathExtension] isEqualToString:@"plugin"] || [[name pathExtension] isEqualToString:@"osirixplugin"])
			{
//				NSBundle *plugin = [NSBundle bundleWithPath:[PluginManager pathResolved:[path stringByAppendingPathComponent:name]]];
//				if (filterClass = [plugin principalClass])	
				{					
					NSMutableDictionary *pluginDescription = [NSMutableDictionary dictionaryWithCapacity:3];
					[pluginDescription setObject:[name stringByDeletingPathExtension] forKey:@"name"];
					[pluginDescription setObject:[NSNumber numberWithBool:active] forKey:@"active"];
					[pluginDescription setObject:[NSNumber numberWithBool:allUsers] forKey:@"allUsers"];
						
					[pluginDescription setObject:availability forKey:@"availability"];
					
					// plugin version
					
					// taking the "version" through NSBundle is a BAD idea: Cocoa keeps the NSBundle in cache... thus for a same path you'll always have the same version
					
					NSURL *bundleURL = [NSURL fileURLWithPath:[PluginManager pathResolved:[path stringByAppendingPathComponent:name]]];
					CFDictionaryRef bundleInfoDict = CFBundleCopyInfoDictionaryInDirectory((CFURLRef)bundleURL);
								
					CFStringRef versionString = 0L;
					if(bundleInfoDict != NULL)
						versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleVersion"));
					
					NSString *pluginVersion;
					if(versionString != NULL)
						pluginVersion = (NSString*)versionString;
					else
						pluginVersion = @"";
						
					[pluginDescription setObject:pluginVersion forKey:@"version"];
					
//					if( versionString) CFRelease(versionString);	// Joris, pourquoi un release???
					if( bundleInfoDict) CFRelease( bundleInfoDict);
					
					// plugin description dictionary
					[plugins addObject:pluginDescription];
				}
			}
		}
	}
	NSArray *sortedPlugins = [plugins sortedArrayUsingFunction:sortPluginArray context:NULL];
	return sortedPlugins;
}

+ (NSArray*)availabilities;
{
	return [NSArray arrayWithObjects:NSLocalizedString(@"Current user", nil), NSLocalizedString(@"All users", nil), NSLocalizedString(@"OsiriX bundle", nil), nil];
}

#endif

@end
