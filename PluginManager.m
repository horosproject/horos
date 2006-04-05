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


#import "PluginManager.h"
#import "ViewerController.h"

#import "browserController.h"
extern BrowserController *browserWindow;

NSMutableDictionary		*plugins = 0L, *pluginsDict = 0L, *fileFormatPlugins = 0L;
NSMutableDictionary		*reportPlugins = 0L;

NSMutableArray			*preProcessPlugins = 0L;
NSMenu					*fusionPluginsMenu = 0L;
PluginManager			*pluginManager = 0L;

@implementation PluginManager

- (void) setMenus:(NSMenu*) filtersMenu :(NSMenu*) roisMenu :(NSMenu*) othersMenu :(NSMenu*) dbMenu
{
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
				long	i;
				
				for( i = 0; i < [menuTitles count]; i++)
				{
					NSString *menuTitle = [menuTitles objectAtIndex: i];
					NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
					[item setTitle:menuTitle];
					
					if( [pluginType isEqualToString:@"fusionFilter"])
					{
						[item setTag:-1];		// Useful for fusionFilter
						[item setAction:@selector(endBlendingType:)];
					}
					else if( [pluginType isEqualToString:@"Database"] || [pluginType isEqualToString:@"Report"]){
						[item setTarget:browserWindow];	//  browserWindow responds to DB plugins
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
					[item setTarget:browserWindow];	//  browserWindow responds to DB plugins
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
	
    [self discoverPlugins];
	}
	return self;
}

- (NSString*) pathResolved:(NSString*) inPath
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
	else return (NSString *)resolvedPath;
}



- (void) discoverPlugins
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
    NSEnumerator *pathEnum = [paths objectEnumerator];
    NSString *path;
	
    plugins = [[NSMutableDictionary alloc] init];
	pluginsDict = [[NSMutableDictionary alloc] init];
	fileFormatPlugins = [[NSMutableDictionary alloc] init];
	preProcessPlugins = [[NSMutableArray alloc] initWithCapacity:0];
	reportPlugins = [[NSMutableDictionary alloc] init];
	
	fusionPluginsMenu = [[NSMenu alloc] initWithTitle:@""];
	[fusionPluginsMenu insertItemWithTitle:NSLocalizedString(@"Select a fusion plug-in", nil) action:0L keyEquivalent:@"" atIndex:0];
	
    while ( path = [pathEnum nextObject] )
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		
		while ( name = [e nextObject] )
		{
			if ( [[name pathExtension] isEqualToString:@"plugin"] )
			{
				NSBundle *plugin = [NSBundle bundleWithPath:[self pathResolved:[path stringByAppendingPathComponent:name]]];
				//NSLog(@"plugin: %@", [plugin  description]);
				//NSLog(@"plugin principal class : %@", NSStringFromClass([plugin principalClass]));
				//NSLog(@"plugin principal class Name : %@", [[plugin infoDictionary] objectForKey:@"NSPrincipalClass"]);
				if ( filterClass = [plugin principalClass])
				{
					
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
								long	i;
								
								for( i = 0; i < [menuTitles count]; i++)
								{
									NSString *menuTitle = [menuTitles objectAtIndex: i];
									
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
						NSLog(@"report PLugin: %@", [[plugin infoDictionary] description]);
						[reportPlugins setObject: plugin forKey:[[plugin infoDictionary] objectForKey:@"CFBundleExecutable"]];
					}
				}
			}
		}
    }
}

-(void) noPlugins:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/Plugins.html"]];
}

@end
