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
#import "AppController.h"
#import "browserController.h"
#import "BLAuthentication.h"
#import "PluginManagerController.h"

static NSMutableDictionary		*plugins = nil, *pluginsDict = nil, *fileFormatPlugins = nil;
static NSMutableDictionary		*reportPlugins = nil;

static NSMutableArray			*preProcessPlugins = nil;
static NSMenu					*fusionPluginsMenu = nil;
static NSMutableArray			*fusionPlugins = nil;

@implementation PluginManager

@synthesize downloadQueue;

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

+ (NSArray*) fusionPlugins
{
	return fusionPlugins;
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
					NSMenuItem *item;
					
					if ([menuTitle isEqual:@"(-"])
					{
						item = [NSMenuItem separatorItem];
					}
					else
					{
						item = [[[NSMenuItem alloc] init] autorelease];
						[item setTitle:menuTitle];
						
						if( [pluginType isEqualToString:@"fusionFilter"])
						{
							[fusionPlugins addObject:[item title]];
							[item setTag:-((NSInteger) [fusionPlugins count])];		// Useful for fusionFilter
							[item setAction:@selector(endBlendingType:)];
						}
						else if( [pluginType isEqualToString:@"Database"] || [pluginType isEqualToString:@"Report"])
						{
							[item setTarget: [BrowserController currentBrowser]];	//  browserWindow responds to DB plugins
							[item setAction:@selector(executeFilterDB:)];
						}
						else
						{
							[item setTarget:nil];	// FIRST RESPONDER !
							[item setAction:@selector(executeFilter:)];
						}
 					}
					
					[subMenu insertItem:item atIndex:[subMenu numberOfItems]];
				}
				
				id  subMenuItem;
				
				if( [pluginType isEqualToString:@"imageFilter"])
				{
					if( [filtersMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [filtersMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[filtersMenu numberOfItems]];
						[filtersMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType isEqualToString:@"roiTool"])
				{
					if( [roisMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [roisMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[roisMenu numberOfItems]];
						[roisMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType isEqualToString:@"fusionFilter"])
				{
					if( [fusionPluginsMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [fusionPluginsMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[roisMenu numberOfItems]];
						[fusionPluginsMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType isEqualToString:@"Database"])
				{
					if( [dbMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [dbMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[dbMenu numberOfItems]];
						[dbMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				} 
				else
				{
					if( [othersMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [othersMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[othersMenu numberOfItems]];
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
					[item setTarget:nil];	// FIRST RESPONDER !
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
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadNext:) name:@"PluginManagerControllerDownloadAndInstallDidFinish" object:nil];
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
	
	if( resolvedPath == nil) return inPath;
	else return [(NSString *) resolvedPath autorelease];
}

+ (void) discoverPlugins
{
    NSString	*appSupport = @"Library/Application Support/OsiriX/";
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
	[fusionPlugins release];
	[fusionPluginsMenu release];
	
    plugins = [[NSMutableDictionary alloc] init];
	pluginsDict = [[NSMutableDictionary alloc] init];
	fileFormatPlugins = [[NSMutableDictionary alloc] init];
	preProcessPlugins = [[NSMutableArray alloc] initWithCapacity:0];
	reportPlugins = [[NSMutableDictionary alloc] init];
	fusionPlugins = [[NSMutableArray alloc] initWithCapacity:0];
	
	fusionPluginsMenu = [[NSMenu alloc] initWithTitle:@""];
	[fusionPluginsMenu insertItemWithTitle:NSLocalizedString(@"Select a fusion plug-in", nil) action:nil keyEquivalent:@"" atIndex:0];
	
    for ( path in paths )
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		
		while ( name = [e nextObject] )
		{
			if ( [[name pathExtension] isEqualToString:@"plugin"] || [[name pathExtension] isEqualToString:@"osirixplugin"])
			{
				NSBundle *plugin = [NSBundle bundleWithPath: [PluginManager pathResolved: [path stringByAppendingPathComponent:name]]];
				
				if( plugin == nil)
					NSLog( @"Bundle opening failed for: %@", [path stringByAppendingPathComponent:name]);
				else
				{
					Class filterClass = [plugin principalClass];
					
					if( filterClass)
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
							NSArray		*menuTitles = [[plugin infoDictionary] objectForKey:@"MenuTitles"];
							
							if( menuTitles)
							{
								PluginFilter*	filter = [filterClass filter];
								
								for( NSString *menuTitle in menuTitles)
								{
									[plugins setObject:filter forKey:menuTitle];
									[pluginsDict setObject:plugin forKey:menuTitle];
								}
							}
							
							NSArray		*toolbarNames = [[plugin infoDictionary] objectForKey:@"ToolbarNames"];
							
							if( toolbarNames)
							{
								PluginFilter*	filter = [filterClass filter];
								
								for( NSString *toolbarName in toolbarNames)
								{
									[plugins setObject:filter forKey:toolbarName];
									[pluginsDict setObject:plugin forKey:toolbarName];
								}
							}
						}
						
						if ([[[plugin infoDictionary] objectForKey:@"pluginType"] isEqualToString:@"Report"]) 
						{
							[reportPlugins setObject: plugin forKey:[[plugin infoDictionary] objectForKey:@"CFBundleExecutable"]];
						}
					}
					else NSLog( @"********* principal class not found for: %@ - %@", name, [plugin principalClass]);
				}
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
	return @"Library/Application Support/OsiriX/Plugins Disabled/";
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
	[appPath appendString:@" Disabled"];
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
	if([sourcePath isEqualToString:destinationPath]) return;
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:[destinationPath stringByDeletingLastPathComponent]])
		[[NSFileManager defaultManager] createDirectoryAtPath:[destinationPath stringByDeletingLastPathComponent] attributes:nil];

    NSMutableArray *args = [NSMutableArray array];
	[args addObject:@"-f"];
    [args addObject:sourcePath];
    [args addObject:destinationPath];

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

+ (NSString*) deletePluginWithName:(NSString*)pluginName;
{
	NSMutableArray *pluginsPaths = [NSMutableArray arrayWithArray:[PluginManager activeDirectories]];
	[pluginsPaths addObjectsFromArray:[PluginManager inactiveDirectories]];
	
    NSString *path, *returnPath = nil;
	NSString *trashDir = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
	
	for(path in pluginsPaths)
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		while(name = [e nextObject])
		{
			if([[name stringByDeletingPathExtension] isEqualToString: [pluginName stringByDeletingPathExtension]])
			{
				NSInteger tag;
				[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:path destination:trashDir files:[NSArray arrayWithObject:name] tag:&tag];
				if(tag!=0)
				{
					NSLog( @"performFileOperation:NSWorkspaceRecycleOperation failed, will us mv");
					
					NSMutableArray *args = [NSMutableArray array];
					[args addObject:@"-f"];
					[args addObject:[NSString stringWithFormat:@"%@/%@", path, name]];
					[args addObject:[NSString stringWithFormat:@"%@/%@", trashDir, name]];
					[[BLAuthentication sharedInstance] executeCommand:@"/bin/mv" withArgs:args];

				}
				
				returnPath = path;
				
//				// delete
//				BOOL deleted = [[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithFormat:@"%@/%@", path, name] handler:nil];
//				if(!deleted)
//				{
//					NSMutableArray *args = [NSMutableArray array];
//					[args addObject:@"-r"];
//					[args addObject:[NSString stringWithFormat:@"%@/%@", path, name]];
//					[[BLAuthentication sharedInstance] executeCommand:@"/bin/rm" withArgs:args];
//				}
			}
		}
	}
	
	return returnPath;
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
	
    NSMutableArray *plugins = [NSMutableArray array];
	
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
								
					CFStringRef versionString = nil;
					if(bundleInfoDict != NULL)
						versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleVersion"));
					
					NSString *pluginVersion;
					if(versionString != NULL)
						pluginVersion = (NSString*)versionString;
					else
						pluginVersion = @"";
						
					[pluginDescription setObject:pluginVersion forKey:@"version"];
					
					if(bundleInfoDict != NULL) CFRelease( bundleInfoDict);
					
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


#pragma mark -
#pragma mark auto update

- (IBAction)checkForUpdates:(id)sender
{
	NSURL				*url;
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	[NSThread sleepForTimeInterval: 10];
	
	url = [NSURL URLWithString:@"http://www.osirix-viewer.com/osirix_plugins/plugins.plist"];
	
	if(url)
	{
		NSMutableArray *onlinePlugins = [NSMutableArray arrayWithContentsOfURL:url];
		NSArray *installedPlugins = [PluginManager pluginsList];
		
		NSMutableArray *pluginsToUpdate = [NSMutableArray array];
		
		for (NSDictionary *installedPlugin in installedPlugins)
		{
			NSString *pluginName = [installedPlugin valueForKey:@"name"];
			
			NSDictionary *onlinePlugin = nil;
			for (NSDictionary *plugin in onlinePlugins)
			{
				NSString *name = [[[plugin valueForKey:@"download_url"] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				name = [name stringByDeletingPathExtension]; // removes the .zip extension
				name = [name stringByDeletingPathExtension]; // removes the .osirixplugin extension
				if([pluginName isEqualToString:name])
				{
					onlinePlugin = plugin;
					break;
				}
			}
			
			if(onlinePlugin)
			{
				NSString *currVersion = [installedPlugin objectForKey:@"version"];
				NSString *onlineVersion = [onlinePlugin objectForKey:@"version"];
				
				if(currVersion && onlineVersion)
				{
					if(![currVersion isEqualToString:onlineVersion])
					{
						NSMutableDictionary *modifiedOnlinePlugin = [NSMutableDictionary dictionaryWithDictionary:onlinePlugin];
						[modifiedOnlinePlugin setObject:pluginName forKey:@"name"];
						[pluginsToUpdate addObject:modifiedOnlinePlugin];
					}
				}
				[onlinePlugins removeObject:onlinePlugin];
			}
		}
		//ici
		if([pluginsToUpdate count])
		{
			NSString *title;
			NSMutableString *message = [NSMutableString string];
			
			if([pluginsToUpdate count]==1)
			{
				title = NSLocalizedString(@"Plugin Update Available", @"");
				[message appendFormat:NSLocalizedString(@"A new version of the plugin \"%@\" is available.", @""), [[pluginsToUpdate objectAtIndex:0] objectForKey:@"name"]];
			}
			else
			{
				title = NSLocalizedString(@"Plugin Updates Available", @"");
				[message appendString:NSLocalizedString(@"New versions of the following plugins are available:\n", @"")];
				for (NSDictionary *plugin in pluginsToUpdate)
				{
					[message appendFormat:@"%@, ", [plugin objectForKey:@"name"]];
				}
				message = [NSMutableString stringWithString:[message substringToIndex:[message length]-2]];
			}
								
			NSDictionary *messageDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:title, message, pluginsToUpdate, nil] forKeys:[NSArray arrayWithObjects:@"title", @"body", @"plugins", nil]];
			
			[self performSelectorOnMainThread:@selector(displayUpdateMessage:) withObject:messageDictionary waitUntilDone: NO];
		}
	}
	
	[pool release];
}

- (void)displayUpdateMessage:(NSDictionary*)messageDictionary;
{
	[messageDictionary retain];

	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
		int button = NSRunAlertPanel( [messageDictionary objectForKey:@"title"], [messageDictionary objectForKey:@"body"], NSLocalizedString(@"Download", @""), NSLocalizedString( @"Cancel", @""), nil);
			
		if (NSOKButton == button)
		{
			startedUpdateProcess = YES;
			PluginManagerController *pluginManagerController = [[BrowserController currentBrowser] pluginManagerController];

			if(pluginManagerController)
			{
				NSArray *pluginsToDownload = [messageDictionary objectForKey:@"plugins"];
				self.downloadQueue = [NSMutableArray arrayWithArray:pluginsToDownload];
				
				NSLog(@"Download Plugin : %@", [[pluginsToDownload objectAtIndex:0] objectForKey:@"download_url"]);
				[pluginManagerController setDownloadURL:[[pluginsToDownload objectAtIndex:0] objectForKey:@"download_url"]];
				[pluginManagerController download:self];
			}
		}
		else startedUpdateProcess = NO;
	
	[pool release];
	
	[messageDictionary release];
}

-(void)downloadNext:(NSNotification*)notification;
{
	if(!startedUpdateProcess) return;
	
	if([downloadQueue count]>1)
	{
		[downloadQueue removeObjectAtIndex:0];

		PluginManagerController *pluginManagerController = [[BrowserController currentBrowser] pluginManagerController];

		NSLog(@"Download Plugin : %@", [[downloadQueue objectAtIndex:0] objectForKey:@"download_url"]);
		[pluginManagerController setDownloadURL:[[downloadQueue objectAtIndex:0] objectForKey:@"download_url"]];
		[pluginManagerController download:self];
	}
	else
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"Plugin Update Completed", @""), NSLocalizedString(@"All your plugins are now up to date. Restart OsiriX to use the new or updated plugins.", @""), NSLocalizedString(@"OK", @""), nil, nil);
		startedUpdateProcess = NO;
	}
}

#endif

@end
