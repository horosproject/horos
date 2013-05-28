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


#import "PluginManager.h"
#import "ViewerController.h"
#import "AppController.h"
#import "browserController.h"
#import "BLAuthentication.h"
#import "PluginManagerController.h"
#import "Notifications.h"
#import "NSFileManager+N2.h"
#import "NSMutableDictionary+N2.h"
#import "PreferencesWindowController.h"
#import "N2Debug.h"

static NSMutableDictionary		*plugins = nil, *pluginsDict = nil, *fileFormatPlugins = nil;
static NSMutableDictionary		*reportPlugins = nil, *pluginsBundleDictionnary = nil;

static NSMutableArray			*preProcessPlugins = nil;
static NSMenu					*fusionPluginsMenu = nil;
static NSMutableArray			*fusionPlugins = nil;
static NSMutableDictionary		*pluginsNames = nil;
static BOOL						ComPACSTested = NO, isComPACS = NO;

BOOL gPluginsAlertAlreadyDisplayed = NO;

@implementation PluginManager

@synthesize downloadQueue;

+ (void) startProtectForCrashWithFilter: (id) filter
{
//    *(long*)0 = 0xDEADBEEF;
    
    for( NSBundle *bundle in [pluginsBundleDictionnary allValues])
    {
        if( [NSStringFromClass( [filter class]) isEqualToString: NSStringFromClass( [bundle principalClass])])
        {
            [PluginManager startProtectForCrashWithPath: [bundle bundlePath]];
           
//            *(long*)0 = 0xDEADBEEF;
            
            return;
        }
    }
    
    NSLog( @"***** unknown plugin - startProtectForCrashWithFilter - %@", NSStringFromClass( [filter principalClass]));
}

+ (void) startProtectForCrashWithPath: (NSString*) path
{
    // Match with AppController, ILCrashReporter
    [path writeToFile: @"/tmp/PluginCrashed" atomically: YES encoding: NSUTF8StringEncoding error: nil];
}

+ (void) endProtectForCrash
{
    // Match with AppController, ILCrashReporter
    [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/PluginCrashed" error: nil];
}

+ (int) compareVersion: (NSString *) v1 withVersion: (NSString *) v2
{
	@try
	{
		NSArray *v1Tokens = [v1 componentsSeparatedByString: @"."];
		NSArray *v2Tokens = [v2 componentsSeparatedByString: @"."];
		int maxLen;
		
		if ( [v1Tokens count] > [v2Tokens count])
			maxLen = [v1Tokens count];
		else
			maxLen = [v2Tokens count];
		
		for (int i = 0; i < maxLen; i++)
		{
			int n1, n2;
			
			n1 = n2 = 0;
			
			if (i < [v1Tokens count])
				n1 = [[v1Tokens objectAtIndex: i] intValue];
			
			if (n1 <= 0)
				[NSException raise: @"compareVersion raised" format: @"compareVersion raised"];
			
			if (i < [v2Tokens count])
				n2 = [[v2Tokens objectAtIndex: i] intValue];
			
			if (n2 <= 0)
				[NSException raise: @"compareVersion raised" format: @"compareVersion raised"];
			
			if (n1 > n2)
				return 1;
			else if (n1 < n2)
				return -1;
		}
		
		return 0;
	}
	@catch (NSException *e)
	{
		return -1;
	}
	return -1;
}

+ (BOOL) isComPACS
{
	if( ComPACSTested == NO)
	{
		ComPACSTested = YES;
		
		if( [[PluginManager plugins] valueForKey:@"ComPACS"])
			isComPACS = YES;
		else
			isComPACS = NO;
	}
	return isComPACS;
}

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

+(void)sortMenu:(NSMenu*)menu
{
    // [CH] Get an array of all menu items.
    NSArray* items = [menu itemArray];
    [menu removeAllItems];
    // [CH] Sort the array
    items = [items sortedArrayUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)], nil]];
    // [CH] ok, now set it back.
    for(NSMenuItem* item in items)
    {
        [menu addItem:item];
        /**
         * [CH] The following code fixes NSPopUpButton's confusion that occurs when
         * we sort this list. NSPopUpButton listens to the NSMenu's add notifications
         * and hides the first item. Sorting this blows it up.
         **/
        if(item.isHidden){
            [item setHidden: false];
        }
    }
}

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
		
        [PluginManager startProtectForCrashWithPath: [plugin bundlePath]];
        
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
						
						if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
						{
							[fusionPlugins addObject:[item title]];
							[item setAction:@selector(endBlendingType:)];
						}
						else if( [pluginType rangeOfString: @"Database"].location != NSNotFound || [pluginType rangeOfString: @"Report"].location != NSNotFound)
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
				
				if( [pluginType rangeOfString: @"imageFilter"].location != NSNotFound)
				{
					if( [filtersMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [filtersMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[filtersMenu numberOfItems]];
						[filtersMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType rangeOfString: @"roiTool"].location != NSNotFound)
				{
					if( [roisMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [roisMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[roisMenu numberOfItems]];
						[roisMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
				{
					if( [fusionPluginsMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [fusionPluginsMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[fusionPluginsMenu numberOfItems]];
						[fusionPluginsMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType rangeOfString: @"Database"].location != NSNotFound)
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
                
                [subMenuItem setRepresentedObject:plugin];
			}
			else
			{
				// Create a menu item
				
				NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
				
				[item setTitle: [menuTitles objectAtIndex: 0]];	//pluginName];
                [item setRepresentedObject:plugin];
				
				if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
				{
					[fusionPlugins addObject:[item title]];
					[item setAction:@selector(endBlendingType:)];
				}
				else if( [pluginType rangeOfString: @"Database"].location != NSNotFound || [pluginType rangeOfString: @"Report"].location != NSNotFound)
				{
					[item setTarget:[BrowserController currentBrowser]];	//  browserWindow responds to DB plugins
					[item setAction:@selector(executeFilterDB:)];
				}
				else
				{
					[item setTarget:nil];	// FIRST RESPONDER !
					[item setAction:@selector(executeFilter:)];
				}
				
				if( [pluginType rangeOfString: @"imageFilter"].location != NSNotFound)
					[filtersMenu insertItem:item atIndex:[filtersMenu numberOfItems]];
				
				else if( [pluginType rangeOfString: @"roiTool"].location != NSNotFound)
					[roisMenu insertItem:item atIndex:[roisMenu numberOfItems]];
				
				else if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
					[fusionPluginsMenu insertItem:item atIndex:[fusionPluginsMenu numberOfItems]];
				
				else if( [pluginType rangeOfString: @"Database"].location != NSNotFound)
					[dbMenu insertItem:item atIndex:[dbMenu numberOfItems]];
				
				else
					[othersMenu insertItem:item atIndex:[othersMenu numberOfItems]];
			}
		}
        
        [PluginManager endProtectForCrash];
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
	
	if( [fusionPluginsMenu numberOfItems] <= 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[fusionPluginsMenu removeItemAtIndex: 0];
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
	
    [PluginManager sortMenu: dbMenu];
    [PluginManager sortMenu: roisMenu];
    [PluginManager sortMenu: filtersMenu];
    [PluginManager sortMenu: othersMenu];
    
	NSEnumerator *pluginEnum = [plugins objectEnumerator];
	PluginFilter *pluginFilter;
	
	while( pluginFilter = [pluginEnum nextObject])
    {
        [PluginManager startProtectForCrashWithFilter: pluginFilter];
        
        @try
        {
            [pluginFilter setMenus];
        }
        @catch (NSException *e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
        }
        
        [PluginManager endProtectForCrash];
	}
}

- (id)init
{
	if (self = [super init])
	{
		// Set DefaultROINames *before* initializing plugins (which may change these)
		
		NSMutableArray *defaultROINames = [NSMutableArray array];
		
		[defaultROINames addObject:@"ROI 1"];
		[defaultROINames addObject:@"ROI 2"];
		[defaultROINames addObject:@"ROI 3"];
		[defaultROINames addObject:@"ROI 4"];
		[defaultROINames addObject:@"ROI 5"];
		
		[ViewerController setDefaultROINames: defaultROINames];
		
		[PluginManager discoverPlugins];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadNext:) name:OsirixPluginDownloadInstallDidFinishNotification object:nil];
	}
	return self;
}

+ (NSString*) pathResolved:(NSString*) inPath
{
	CFStringRef resolvedPath = nil;
	CFURLRef	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)inPath, kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if (url != NULL)
    {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef))
        {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, &targetIsFolder, &wasAliased) == noErr && wasAliased)
            {
				CFURLRef resolvedurl = CFURLCreateFromFSRef(NULL /*allocator*/, &fsRef);
				if (resolvedurl != NULL)
                {
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

+ (void) releaseInstanciedObjectsOfClass: (Class) class
{
    for( int i = 0; i < [preProcessPlugins count]; i++)
    {
        if( [[preProcessPlugins objectAtIndex: i] class] == class)
        {
            NSObject *filter = [preProcessPlugins objectAtIndex: i];
            
            if( [filter respondsToSelector: @selector(willUnload)])
                [filter performSelector: @selector(willUnload)];
            
            [preProcessPlugins removeObjectAtIndex: i];
            i--;
        }
    }
    
    for( NSString *key in [plugins allKeys])
    {
        if( [[plugins valueForKey: key] class] == class)
        {
            NSObject *filter = [plugins valueForKey: key];
            
            if( [filter respondsToSelector: @selector(willUnload)])
                [filter performSelector: @selector(willUnload)];
            
            [plugins removeObjectForKey: key];
        }
    }
}

+ (void) unloadPlugin: (NSBundle*) bundle
{
//    NSLog( @"--- will unloadplugin: %@", [bundle bundlePath]);
//    @try
//    {
//        [PluginManager startProtectForCrashWithPath: [bundle bundlePath]];
//        
//        Class filterClass = [bundle principalClass];
//                
//        [PluginManager releaseInstanciedObjectsOfClass: filterClass];
//        
//        [PreferencesWindowController removePluginPaneWithBundle: bundle];
//        
//        [pluginsNames removeObjectForKey: [[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension]];
//        [fileFormatPlugins removeObject: bundle];
//        [pluginsDict removeObject: bundle];
//        [reportPlugins removeObject: bundle];
//        
//        [PluginManager endProtectForCrash];
//        
//        if( [bundle unload] == NO) unload crash, if KVO Bindings is used in a plugin...
//        {
//            NSLog( @"***** failed to unload plugin: %@", [bundle bundlePath]);
//        }
//        else
//        {
//            for( NSString *key in [pluginsBundleDictionnary allKeys])
//            {
//                if( [pluginsBundleDictionnary valueForKey: key] == bundle)
//                {
//                    [pluginsBundleDictionnary removeObjectForKey: key];
//                    return;
//                }
//            }
//        }
//    }
//    @catch (NSException *e)
//    {
//        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
//    }
}

+ (void) unloadPluginWithName: (NSString*) name
{
    for( NSBundle *bundle in [pluginsBundleDictionnary allValues])
    {
        if( [[[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension] isEqualToString: name])
            [PluginManager unloadPlugin: bundle];
    }
}

+ (void) loadPluginAtPath: (NSString*) path
{
    NSString *name = [path lastPathComponent];
    
    path = [path stringByDeletingLastPathComponent];
    
    if (([[name pathExtension] isEqualToString:@"plugin"] || [[name pathExtension] isEqualToString:@"osirixplugin"]))
    {
        if( [pluginsNames valueForKey: [[name lastPathComponent] stringByDeletingPathExtension]])
        {
            NSLog( @"***** Multiple plugins: %@", [name lastPathComponent]);
            
            NSString *message = NSLocalizedString(@"Warning! Multiple instances of the same plugin have been found. Only one instance will be loaded. Check the Plugin Manager (Plugins menu) for multiple identical plugins.", nil);
            
            message = [message stringByAppendingFormat:@"\r\r%@", [name lastPathComponent]];
            
            NSRunAlertPanel( NSLocalizedString(@"Plugins", nil), message , nil, nil, nil);
        }
        else
        {
            [pluginsNames setValue: path forKey: [[name lastPathComponent] stringByDeletingPathExtension]];
            
            @try
            {
                NSString *pathResolved = [PluginManager pathResolved: [path stringByAppendingPathComponent: name]];
                
                [PluginManager startProtectForCrashWithPath: pathResolved];
                
                NSBundle *plugin = [NSBundle bundleWithPath: pathResolved];
                
                if( plugin == nil)
                    NSLog( @"**** Bundle opening failed for plugin: %@", [path stringByAppendingPathComponent:name]);
                else
                {
                    if (![plugin load])
                    {
                        NSLog( @"******* Bundle code loading failed for plugin %@", [path stringByAppendingPathComponent:name]);
                    }
                    else
                    {
                        Class filterClass = [plugin principalClass];
                        
                        if( filterClass)
                        {
                            [pluginsBundleDictionnary setObject: plugin forKey: pathResolved];
                            
                            NSString *version = [[plugin infoDictionary] valueForKey: (NSString*) kCFBundleVersionKey];
                            
                            if( version == nil)
                                version = [[plugin infoDictionary] valueForKey: @"CFBundleShortVersionString"];
                            
                            NSLog( @"Loaded: %@, vers: %@ (%@)", [name stringByDeletingPathExtension], version, path);
                            
                            if( filterClass == NSClassFromString( @"ARGS")) return;
                            
                            if ([[[plugin infoDictionary] objectForKey:@"pluginType"] rangeOfString:@"Pre-Process"].location != NSNotFound) 
                            {
                                PluginFilter *filter = [filterClass filter];
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
                            else if ( [filterClass instancesRespondToSelector:@selector(filterImage:)])
                            {
                                NSArray *menuTitles = [[plugin infoDictionary] objectForKey:@"MenuTitles"];
                                PluginFilter *filter = [filterClass filter];
                                
                                if( menuTitles)
                                {
                                    for( NSString *menuTitle in menuTitles)
                                    {
                                        [plugins setObject:filter forKey:menuTitle];
                                        [pluginsDict setObject:plugin forKey:menuTitle];
                                    }
                                }
                                
                                NSArray *toolbarNames = [[plugin infoDictionary] objectForKey:@"ToolbarNames"];
                                
                                if( toolbarNames)
                                {
                                    for( NSString *toolbarName in toolbarNames)
                                    {
                                        [plugins setObject:filter forKey:toolbarName];
                                        [pluginsDict setObject:plugin forKey:toolbarName];
                                    }
                                }
                            }
                            
                            if ([[[plugin infoDictionary] objectForKey:@"pluginType"] rangeOfString: @"Report"].location != NSNotFound) 
                            {
                                [reportPlugins setObject: plugin forKey:[[plugin infoDictionary] objectForKey:@"CFBundleExecutable"]];
                            }
                        }
                        else NSLog( @"********* principal class not found for: %@ - %@", name, [plugin principalClass]);
                    }
                }
                
                [PluginManager endProtectForCrash];
            }
            @catch( NSException *e)
            {
                NSLog( @"******** Plugin loading exception: %@", e);
            }
        }
    }
}

+ (void) discoverPlugins
{
	@try
	{
		NSString	*appSupport = @"Library/Application Support/OsiriX/";
        NSString	*appAppStoreSupport = @"Library/Application Support/OsiriX App/";
		NSString	*appPath = [[NSBundle mainBundle] builtInPlugInsPath];
        NSString	*userAppStorePath = [NSHomeDirectory() stringByAppendingPathComponent:appAppStoreSupport];
		NSString	*userPath = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
		NSString	*sysPath = [@"/" stringByAppendingPathComponent:appSupport];
		
		#ifndef MACAPPSTORE
		if ([[NSFileManager defaultManager] fileExistsAtPath:appPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:appPath attributes:nil];
		if ([[NSFileManager defaultManager] fileExistsAtPath:userPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:userPath attributes:nil];
		if ([[NSFileManager defaultManager] fileExistsAtPath:sysPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:sysPath attributes:nil];
		#endif
		
		appSupport = [appSupport stringByAppendingPathComponent :@"Plugins/"];
		appAppStoreSupport = [appAppStoreSupport stringByAppendingPathComponent :@"Plugins/"];
		
		userPath = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
        userAppStorePath = [NSHomeDirectory() stringByAppendingPathComponent:appAppStoreSupport];
		sysPath = [@"/" stringByAppendingPathComponent:appSupport];
		
		#ifndef MACAPPSTORE
		if ([[NSFileManager defaultManager] fileExistsAtPath:userPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:userPath attributes:nil];
		if ([[NSFileManager defaultManager] fileExistsAtPath:sysPath] == NO) [[NSFileManager defaultManager] createDirectoryAtPath:sysPath attributes:nil];
		#endif
		
		NSArray* paths = [NSArray arrayWithObjects: [NSNull null], appPath, userPath, userAppStorePath, sysPath, nil]; // [NSNull null] is a placeholder for launch parameters load commands
		
        for( NSBundle *bundle in [pluginsBundleDictionnary allValues])
            [PluginManager unloadPlugin: bundle];
        
		[plugins release];
		[pluginsDict release];
		[fileFormatPlugins release];
		[preProcessPlugins release];
		[reportPlugins release];
		[fusionPlugins release];
		[fusionPluginsMenu release];
		[pluginsNames  release];
        [pluginsBundleDictionnary release];
        
        pluginsBundleDictionnary = [[NSMutableDictionary alloc] init];
		plugins = [[NSMutableDictionary alloc] init];
		pluginsDict = [[NSMutableDictionary alloc] init];
		fileFormatPlugins = [[NSMutableDictionary alloc] init];
		preProcessPlugins = [[NSMutableArray alloc] initWithCapacity:0];
		reportPlugins = [[NSMutableDictionary alloc] init];
		pluginsNames = [[NSMutableDictionary alloc] init];
		fusionPlugins = [[NSMutableArray alloc] initWithCapacity:0];
		
		fusionPluginsMenu = [[NSMenu alloc] initWithTitle:@""];
		[fusionPluginsMenu insertItemWithTitle:NSLocalizedString(@"Select a fusion plug-in", nil) action:nil keyEquivalent:@"" atIndex:0];
		
		NSLog( @"|||||||||||||||||| Plugins loading START ||||||||||||||||||");
        #ifndef OSIRIX_LIGHT
		
        NSString *pluginCrash = [[[NSFileManager defaultManager] userApplicationSupportFolderForApp] stringByAppendingPathComponent:@"Plugin_Loading"];
        if ([[NSFileManager defaultManager] fileExistsAtPath: pluginCrash] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotDeleteCrashingPlugins"])
        {
            NSString *pluginCrashPath = [NSString stringWithContentsOfFile: pluginCrash encoding: NSUTF8StringEncoding error: nil];
            
            int result = NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX crashed", nil), [NSString stringWithFormat: NSLocalizedString(@"Previous crash is maybe related to a plugin.\r\rShould I remove this plugin (%@)?", nil), [pluginCrashPath lastPathComponent]], NSLocalizedString(@"Delete Plugin",nil), NSLocalizedString(@"Continue",nil), nil);
            
            if( result == NSAlertDefaultReturn) // Delete Plugin
            {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath: pluginCrashPath error: &error];
                
                if( error)
                    NSLog( @"**** Cannot Delete File : Crashing Plugin Delete Error: %@", error);
            }
            
            [[NSFileManager defaultManager] removeItemAtPath: pluginCrash error: nil];
        }
        
        NSMutableArray* pathsOfPluginsToLoad = [NSMutableArray array];
        
        for (id path in paths)
            @try {
                NSArray* donotloadnames = nil;
                if (![path isKindOfClass:[NSNull class]]) {
                    donotloadnames = [[NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"DoNotLoad.txt"]] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    if ([donotloadnames containsObject:@"*"])
                        break;
                }

                NSEnumerator* e = nil;
                if ([path isKindOfClass:[NSString class]])
                    e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
                else if (path == [NSNull null])
                {
                    path = @"/";
                    NSMutableArray* cl = [NSMutableArray array];
                    NSArray* args = [[NSProcessInfo processInfo] arguments];
                    for (NSInteger i = 0; i < [args count]; ++i)
                        if ([[args objectAtIndex:i] isEqualToString:@"--LoadPlugin"] && [args count] > i+1) {
                            [cl addObject:[args objectAtIndex:++i]];
                        }
                    e = [cl objectEnumerator];
                }
                
                NSString* name;
                while (name = [e nextObject])
                    if (/*[[name pathExtension] isEqualToString:@"osirixplugin"] &&*/ [donotloadnames containsObject:[name stringByDeletingPathExtension]] == NO)
                        [pathsOfPluginsToLoad addObject:[NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[path stringByAppendingPathComponent: name]]];
            } @catch (NSException* e) {
                N2LogExceptionWithStackTrace(e);
            }
        
//        NSLog(@"paths: %@", pathsOfPluginsToLoad);

        // some plugins require other plugins to be loaded before them
        for (__block NSInteger i = pathsOfPluginsToLoad.count-1; i >= 0; --i) {
            
            
            NSBundle* bundle = [NSBundle bundleWithPath:[pathsOfPluginsToLoad objectAtIndex:i]];
            NSString* name = [bundle.infoDictionary objectForKey:@"CFBundleName"];
            if (!name) name = [[[pathsOfPluginsToLoad objectAtIndex:i] lastPathComponent] stringByDeletingPathExtension];
//            
//            NSLog(@"for %@", name);
            
            // list of requirements
            for (NSString* req in [bundle.infoDictionary objectForKey:@"Requirements"]) {
                // make sure they're loaded before this plugin
                NSIndexSet* is = [pathsOfPluginsToLoad indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    NSBundle* bundle = [NSBundle bundleWithPath:obj];
                    NSString* name = [bundle.infoDictionary objectForKey:@"CFBundleName"];
                    if (!name) name = [[obj lastPathComponent] stringByDeletingPathExtension];
                    return [name isEqualToString:req];
                }];
                if (!is.count)
                    NSLog(@"Warning: plugin requirement %@ not available for %@", req, name); // we actually may decide not to load this plugin, since it requires something that apparently isn't available, but hopefully it'll just raise an exception and end up not being loaded...
                [is enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    if (idx > i) {
                        id o = [[[pathsOfPluginsToLoad objectAtIndex:idx] retain] autorelease];
                        [pathsOfPluginsToLoad removeObjectAtIndex:idx];
                        [pathsOfPluginsToLoad insertObject:o atIndex:i++];
                    }
                }];
            }
            
//            NSLog(@"paths: %@", pathsOfPluginsToLoad);
        }
        
        for (id path in pathsOfPluginsToLoad)
            [PluginManager loadPluginAtPath:path];
            
		#endif
		
        NSLog( @"|||||||||||||||||| Plugins loading END ||||||||||||||||||");
	}
	@catch (NSException * e)
	{
        N2LogExceptionWithStackTrace(e);
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
    #ifdef MACAPPSTORE
	return @"Library/Application Support/OsiriX App/Plugins/";
    #else
    return @"Library/Application Support/OsiriX/Plugins/";
    #endif
}

+ (NSString*)inactivePluginsDirectoryPath;
{
    #ifdef MACAPPSTORE
	return @"Library/Application Support/OsiriX App/Plugins Disabled/";
    #else
    return @"Library/Application Support/OsiriX/Plugins Disabled/";
    #endif
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
//	NSMutableArray *paths = [NSMutableArray array];
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
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: destinationPath] == NO)
    {
        NSMutableArray *args = [NSMutableArray array];
        [args addObject:@"-f"];
        [args addObject:@"-R"];
        [args addObject:sourcePath];
        [args addObject:destinationPath];
        
        [[BLAuthentication sharedInstance] executeCommand:@"/bin/cp" withArgs:args];
    }
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
    
    if( !gPluginsAlertAlreadyDisplayed)
        NSRunInformationalAlertPanel(NSLocalizedString(@"Plugins", @""), NSLocalizedString( @"Restart OsiriX to apply the changes to the plugin.", @""), NSLocalizedString(@"OK", @""), nil, nil);
    gPluginsAlertAlreadyDisplayed = YES;
}

+ (void)deactivatePluginWithName:(NSString*)pluginName;
{
//    [PluginManager unloadPluginWithName: pluginName];
    
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
    
    if( !gPluginsAlertAlreadyDisplayed)
        NSRunInformationalAlertPanel(NSLocalizedString(@"Plugins", @""), NSLocalizedString( @"Restart OsiriX to apply the changes to the plugin.", @""), NSLocalizedString(@"OK", @""), nil, nil);
    gPluginsAlertAlreadyDisplayed = YES;
}

+ (void)changeAvailabilityOfPluginWithName:(NSString*)pluginName to:(NSString*)availability;
{
    NSArray *availabilities = [PluginManager availabilities];
    
#ifdef MACAPPSTORE
    if([availability isEqualTo:[availabilities objectAtIndex:0]] == NO)
    {
        NSRunCriticalAlertPanel( NSLocalizedString(@"Plugin",nil),  NSLocalizedString( @"You cannot move the plugin to another location with this version of OsiriX.", nil), NSLocalizedString(@"OK",nil), nil, nil);
    }
#endif
    
	NSMutableArray *paths = [NSMutableArray array];
	[paths addObjectsFromArray:[PluginManager activeDirectories]];
	[paths addObjectsFromArray:[PluginManager inactiveDirectories]];

	NSEnumerator *pathEnum = [paths objectEnumerator];
    NSString *path;
	NSString *completePluginPath = nil;
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
	
	
	if([availability isEqualTo:[availabilities objectAtIndex:0]])
	{
		[newDirectory setString:[PluginManager userActivePluginsDirectoryPath]];
	}
	else if(availabilities.count >= 1 && [availability isEqualTo:[availabilities objectAtIndex:1]])
	{
		[newDirectory setString:[PluginManager systemActivePluginsDirectoryPath]];
	}
	else if(availabilities.count >= 2 && [availability isEqualTo:[availabilities objectAtIndex:2]])
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

#pragma mark Instalation

+ (void) installPluginFromPath: (NSString*) path
{
    // move the plugin package into the plugins (active) directory
    NSString *destinationDirectory = nil;
    NSString *destinationPath = nil;
    
    NSMutableDictionary *active = [NSMutableDictionary dictionary];
	NSMutableDictionary *availabilities = [NSMutableDictionary dictionary];
	
    NSString *pluginBundleName = [[path lastPathComponent] stringByDeletingPathExtension];
    
    for(NSDictionary *plug in [PluginManager pluginsList])
    {
        if([pluginBundleName isEqualToString: [plug objectForKey:@"name"]])
        {
            [availabilities setObject: [plug objectForKey:@"availability"] forKey:path];
            [active setObject: [plug objectForKey:@"active"] forKey:path];
        }
    }
    
    NSString *availability = [availabilities objectForKey: path];
    BOOL isActive = [[active objectForKey:path] boolValue];
    
    if(!availability)
        isActive = YES;
    
    if([availability isEqualToString:[[PluginManager availabilities] objectAtIndex:0]])
    {
        if(isActive)
            destinationDirectory = [PluginManager userActivePluginsDirectoryPath];
        else
            destinationDirectory = [PluginManager userInactivePluginsDirectoryPath];
    }
#ifndef MACAPPSTORE
    else if([availability isEqualToString:[[PluginManager availabilities] objectAtIndex:1]])
    {
        if(isActive)
            destinationDirectory = [PluginManager systemActivePluginsDirectoryPath];
        else
            destinationDirectory = [PluginManager systemInactivePluginsDirectoryPath];
    }
    else if([availability isEqualToString:[[PluginManager availabilities] objectAtIndex:2]])
    {
        if(isActive)
            destinationDirectory = [PluginManager appActivePluginsDirectoryPath];
        else
            destinationDirectory = [PluginManager appInactivePluginsDirectoryPath];
    }
    else
#endif
    {
        if(isActive)
            destinationDirectory = [PluginManager userActivePluginsDirectoryPath];
        else
            destinationDirectory = [PluginManager userInactivePluginsDirectoryPath];
    }
    
    destinationPath = [destinationDirectory stringByAppendingPathComponent: [path lastPathComponent]];
    
    // delete the plugin if it already exists.
    [PluginManager deletePluginWithName: [path lastPathComponent]];
    
    // move the new plugin to the plugin folder				
    [PluginManager movePluginFromPath: path toPath: destinationPath];
    
//    // load the plugin - The User has to restart
//    [PluginManager loadPluginAtPath: destinationPath];
}

#pragma mark Deletion

+ (NSString*) deletePluginWithName:(NSString*)pluginName;
{
	return [PluginManager deletePluginWithName: pluginName availability: nil isActive: YES];
}

+ (NSString*) deletePluginWithName:(NSString*)pluginName availability: (NSString*) availability isActive:(BOOL) isActive
{
    pluginName = [pluginName stringByDeletingPathExtension];
    
    // First unload the plugin, if currently running
//    [PluginManager unloadPluginWithName: pluginName];
    
	NSMutableArray *pluginsPaths = [NSMutableArray arrayWithArray:[PluginManager activeDirectories]];
	[pluginsPaths addObjectsFromArray:[PluginManager inactiveDirectories]];
	
    NSString *path, *returnPath = nil;
	NSString *trashDir = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
	
	NSString *directory = nil;
	NSArray *availabilities = [PluginManager availabilities];
	if( [availability isEqualToString:[availabilities objectAtIndex:0]])
	{
		if( isActive)
			directory = [PluginManager userActivePluginsDirectoryPath];
		else
			directory = [PluginManager userInactivePluginsDirectoryPath];
	}
	else if( availabilities.count >= 1 && [availability isEqualToString:[availabilities objectAtIndex:1]])
	{
		if(isActive)
			directory = [PluginManager systemActivePluginsDirectoryPath];
		else
			directory = [PluginManager systemInactivePluginsDirectoryPath];
	}
	else if( availabilities.count >= 2 && [availability isEqualToString:[availabilities objectAtIndex:2]])
	{
		if(isActive)
			directory = [PluginManager appActivePluginsDirectoryPath];
		else
			directory = [PluginManager appInactivePluginsDirectoryPath];
	}
	
	for(path in pluginsPaths)
	{
		NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
		NSString *name;
		while(name = [e nextObject])
		{
			if([[name stringByDeletingPathExtension] isEqualToString: [pluginName stringByDeletingPathExtension]] && (directory == nil || [directory isEqualTo: path]))
			{
				NSInteger tag = 0;
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
	
    if( !gPluginsAlertAlreadyDisplayed)
        NSRunInformationalAlertPanel(NSLocalizedString(@"Plugins", @""), NSLocalizedString( @"Restart OsiriX to inactivate the deleted plugins.", @""), NSLocalizedString(@"OK", @""), nil, nil);
    gPluginsAlertAlreadyDisplayed = YES;
    
	return returnPath;
}

#pragma mark plugins

NSInteger sortPluginArray(id plugin1, id plugin2, void *context)
{
    NSString *name1 = [plugin1 objectForKey:@"name"];
    NSString *name2 = [plugin2 objectForKey:@"name"];
    
	return [name1 compare:name2 options: NSCaseInsensitiveSearch];
}

+ (NSArray*)pluginsList;
{
	NSString *userActivePath = [PluginManager userActivePluginsDirectoryPath];
	NSString *userInactivePath = [PluginManager userInactivePluginsDirectoryPath];
	NSString *sysActivePath = [PluginManager systemActivePluginsDirectoryPath];
	NSString *sysInactivePath = [PluginManager systemInactivePluginsDirectoryPath];

//	NSArray *paths = [NSArray arrayWithObjects:userActivePath, userInactivePath, sysActivePath, sysInactivePath, nil];
	
	NSMutableArray *paths = [NSMutableArray array];
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
		
		NSString *availability = nil;
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
					{
						versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleVersion"));
					
						if(versionString == nil)
							versionString = CFDictionaryGetValue(bundleInfoDict, CFSTR("CFBundleShortVersionString"));
					}
					
					NSString *pluginVersion;
					if(versionString != NULL)
						pluginVersion = (NSString*)versionString;
					else
						pluginVersion = @"";
						
					[pluginDescription setObject:pluginVersion forKey:@"version"];
					
					if(bundleInfoDict != NULL)
						CFRelease( bundleInfoDict);
					
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
	
    [NSThread currentThread].name = @"Check for plugins updates";
    
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
			
			if( onlinePlugin)
			{
				NSString *currVersion = [installedPlugin objectForKey:@"version"];
				NSString *onlineVersion = [onlinePlugin objectForKey:@"version"];
				
				if(currVersion && onlineVersion && [currVersion length] > 0 && [currVersion length] > 0)
				{
					if( [currVersion isEqualToString:onlineVersion] == NO && [PluginManager compareVersion: currVersion withVersion: onlineVersion] < 0)
					{
						NSLog( @"PLUGIN UPDATE NEEDED -------> current vers: %@ versus online vers: %@ - %@", currVersion, onlineVersion, pluginName);
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
        if( !gPluginsAlertAlreadyDisplayed)
            NSRunInformationalAlertPanel(NSLocalizedString(@"Plugin Update Completed", @""), NSLocalizedString(@"All your plugins are now up to date. Restart OsiriX to use the new or updated plugins.", @""), NSLocalizedString(@"OK", @""), nil, nil);
		gPluginsAlertAlreadyDisplayed = YES;
        
        startedUpdateProcess = NO;
	}
}

#endif

@end
