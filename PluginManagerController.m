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

#import "PluginManagerController.h"
#import <Message/NSMailDelivery.h>

// this is the address of the plist containing the list of the available plugins.
// the alternative link will be used if the first one doesn't reply...

#define PLUGIN_LIST_URL @"http://www.osirix-viewer.com/osirix_plugins/plugins.plist"
#define PLUGIN_LIST_ALT_URL @"http://www.osirixviewer.com/osirix_plugins/plugins.plist"

#define PLUGIN_SUBMISSION_URL @"http://www.osirix-viewer.com/osirix_plugins/submit_plugin/index.html"
#define PLUGIN_SUBMISSION_NO_MAIL_APP_URL @"http://www.osirix-viewer.com/osirix_plugins/submit_plugin/index_no_mail_app.html"

@implementation PluginManagerController

- (id)init
{
	self = [super initWithWindowNibName:@"PluginManager"];
	
	plugins = [[NSMutableArray arrayWithArray:[PluginManager pluginsList]] retain];
	
	pluginsListURLs = [[NSArray arrayWithObjects:PLUGIN_LIST_URL, PLUGIN_LIST_ALT_URL, nil] retain];

	NSRect windowFrame = [[self window] frame];
	[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y,500,700) display:YES];
	 
	[webView setPolicyDelegate:self];
	
	[statusTextField setHidden:YES];
	[statusProgressIndicator setHidden:YES];
	downloadedFilePath = @"";
	
	// deactivate the back/forward options in the webView's contextual menu
	[[webView backForwardList] setCapacity:0];
	
	return self;
}

- (void)dealloc
{
	[plugins release];
	[pluginsListURLs release];
	[downloadURL release];
	[downloadedFilePath release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark installed

- (NSMutableArray*)plugins;
{
	return plugins;
}

- (NSArray*)availabilities;
{
	return [PluginManager availabilities];
}

- (IBAction)modifiyActivation:(id)sender;
{
	NSArray *pluginsList = [pluginsArrayController arrangedObjects];
	NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"name"];
	BOOL pluginIsActive = [[[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"active"] boolValue];

	if(!pluginIsActive)
	{
		[PluginManager deactivatePluginWithName:pluginName];
	}
	else
	{
		[PluginManager activatePluginWithName:pluginName];
	}
	
	[self refreshPluginList];
	[pluginTable selectRow:[pluginTable clickedRow] byExtendingSelection:NO];
}

- (IBAction)delete:(id)sender;
{
	if( NSRunInformationalAlertPanel(	NSLocalizedString(@"Delete a plugin", 0L),
												 NSLocalizedString(@"Are you sure you want to delete the selected plugin?", 0L),
												 NSLocalizedString(@"OK",nil),
												 NSLocalizedString(@"Cancel",nil),
												 0L) == NSAlertDefaultReturn)
	{
		NSArray *pluginsList = [pluginsArrayController arrangedObjects];
		NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable selectedRow]] objectForKey:@"name"];
	
		[PluginManager deletePluginWithName:pluginName];
	
		[self refreshPluginList];
	}
}

- (IBAction)modifiyAvailability:(id)sender;
{
	NSArray *pluginsList = [pluginsArrayController arrangedObjects];
	NSString *pluginAvailability = [[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"availability"];
	NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"name"];
	
	[PluginManager changeAvailabilityOfPluginWithName:pluginName to:[[sender selectedCell] title]];
	
	[self refreshPluginList]; // needed to restore the availability menu in case the user did provided a good admin password
}

- (void)loadPlugins;
{
	while([filtersMenu numberOfItems]>0)
	{
		[filtersMenu removeItemAtIndex:0];
	}
		
	while([roisMenu numberOfItems]>0)
	{
		[roisMenu removeItemAtIndex:0];
	}
	
	while([othersMenu numberOfItems]>0)
	{
		[othersMenu removeItemAtIndex:0];
	}

	while([dbMenu numberOfItems]>0)
	{
		[dbMenu removeItemAtIndex:0];
	}
	
	[PluginManager discoverPlugins];
	[PluginManager setMenus:filtersMenu :roisMenu :othersMenu :dbMenu];
	
	pluginsNeedToReload = NO;
}

- (IBAction)loadPlugins:(id)sender;
{
	[self loadPlugins];
}

- (void)windowWillClose:(NSNotification *)aNotification;
{
	if( pluginsNeedToReload)
	{
		[self refreshPluginList];
		[self loadPlugins];
	}
}

- (IBAction)showWindow:(id)sender;
{
	if([[self availablePlugins] count]<1)
	{
		[pluginsListPopUp removeAllItems];
		[pluginsListPopUp setEnabled:NO];
		[downloadButton setEnabled:NO];
		[statusTextField setHidden:NO];
		[statusTextField setStringValue:NSLocalizedString(@"No plugin server available.", nil)];
		//return;
	}
	else
	{
		[self generateAvailablePluginsMenu];
		[self setURLforPluginWithName:[[[self availablePlugins] objectAtIndex:0] valueForKey:@"name"]];
		[self setDownloadURL:[[[self availablePlugins] objectAtIndex:0] valueForKey:@"download_url"]];
	}

	NSArray *viewers = [ViewerController getDisplayed2DViewers];
	for (ViewerController *viewer in viewers)
	{
		[[viewer window] close];
	}

	[super showWindow:sender];
	[self refreshPluginList];
}

- (void)refreshPluginList;
{
	NSIndexSet *selectedIndexes = [pluginTable selectedRowIndexes];
	pluginsNeedToReload = YES;
	
	[self willChangeValueForKey:@"plugins"];
	[plugins removeAllObjects];
	[plugins addObjectsFromArray:[PluginManager pluginsList]];
	[self didChangeValueForKey:@"plugins"];
	
	[pluginTable selectRowIndexes:selectedIndexes byExtendingSelection:NO];
}

#pragma mark NSTabView Delegate methods

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if([tabViewItem isEqualTo:installedPluginsTabViewItem])
		[self refreshPluginList];
}

#pragma mark -
#pragma mark web view

#pragma mark pop up menu

NSInteger sortPluginArrayByName(id plugin1, id plugin2, void *context)
{
    NSString *name1 = [plugin1 objectForKey:@"name"];
    NSString *name2 = [plugin2 objectForKey:@"name"];
    
	return [name1 compare:name2];
}

- (NSArray*) availablePlugins;
{
	NSString *pluginsListURL = @"";
	NSArray *pluginsList = nil;
	
	int i;
	for (i=0; i<[pluginsListURLs count] && !pluginsList; i++)
	{
		pluginsListURL = [pluginsListURLs objectAtIndex:i];
		pluginsList = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:pluginsListURL]];
	}

	if(!pluginsList) return nil;
	
	NSArray *sortedPlugins = [pluginsList sortedArrayUsingFunction:sortPluginArrayByName context:NULL];
	return sortedPlugins;
}

- (void)generateAvailablePluginsMenu;
{
	[pluginsListPopUp removeAllItems];
	
	NSArray *availablePlugins = [self availablePlugins];
	for (id loopItem in availablePlugins)
	{
		[pluginsListPopUp addItemWithTitle:[loopItem objectForKey:@"name"]];
	}
	
	[[pluginsListPopUp menu] addItem:[NSMenuItem separatorItem]];
	[pluginsListPopUp addItemWithTitle:NSLocalizedString(@"Your Plugin here!", nil)];
}

#pragma mark web page

- (void)setURL:(NSString*)url;
{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
	[statusTextField setHidden:YES];
	[statusProgressIndicator setHidden:YES];
}

- (void)setURLforPluginWithName:(NSString*)name;
{
	NSArray* availablePlugins = [self availablePlugins];
	for(NSDictionary *plugin in availablePlugins)
	{
		if([[plugin valueForKey:@"name"] isEqualToString:name])
		{
			[self setURL:[plugin valueForKey:@"url"]];
			[self setDownloadURL:[plugin valueForKey:@"download_url"]];
			
			BOOL alreadyInstalled = NO;
			BOOL sameName = NO;
			BOOL sameVersion = NO;
			for(NSDictionary *installedPlugin in plugins)
			{	
				NSString *name = [[[plugin valueForKey:@"download_url"] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				name = [name stringByDeletingPathExtension]; // removes the .zip extension
				name = [name stringByDeletingPathExtension]; // removes the .osirixplugin extension
				sameName = [name isEqualToString:[installedPlugin valueForKey:@"name"]];
				sameVersion = [[plugin valueForKey:@"version"] isEqualToString:[installedPlugin valueForKey:@"version"]];

				alreadyInstalled = alreadyInstalled || sameName || (sameName && sameVersion);
				
				if(alreadyInstalled) break;
			}
			
			if(alreadyInstalled)
			{
				[statusTextField setHidden:NO];
				if(sameName && sameVersion)
					[statusTextField setStringValue:NSLocalizedString(@"Plugin already installed", nil)];
				else
					[statusTextField setStringValue:NSLocalizedString(@"Download the new version!", nil)];
			}
			else
			{
				[statusTextField setHidden:YES];
			}
			
			return;
		}
		else if([name isEqualToString:NSLocalizedString(@"Your Plugin here!", nil)])
		{
			[self loadSubmitPluginPage];
		}
	}
}

- (IBAction)changeWebView:(id)sender;
{
	[self setURLforPluginWithName:[sender title]];
}

#pragma mark download

- (void)setDownloadURL:(NSString*)url;
{
	if(downloadURL) [downloadURL release];
	downloadURL = url;
	[downloadURL retain];
	if([downloadURL isEqualToString:@""])
		[downloadButton setHidden:YES];
	else
		[downloadButton setHidden:NO];
}

- (IBAction)download:(id)sender;
{
	NSURLDownload *download = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:downloadURL]] delegate:self];
	//downloadedFilePath = [NSString stringWithFormat:@"%@/Desktop/%@", NSHomeDirectory(), [[downloadURL lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	downloadedFilePath = [NSString stringWithFormat:@"/tmp/%@", [[downloadURL lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[download setDestination:downloadedFilePath allowOverwrite:YES];
}

- (void)downloadDidBegin:(NSURLDownload *)download
{
	[statusTextField setHidden:NO];
	[statusTextField setStringValue:NSLocalizedString(@"Downloading...", nil)];
	[statusProgressIndicator setHidden:NO];
	[statusProgressIndicator startAnimation:self];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	[statusTextField setStringValue:NSLocalizedString(@"Plugin downloaded", nil)];
	[statusProgressIndicator setHidden:YES];
	[statusProgressIndicator stopAnimation:self];
	[self installDownloadedPluginAtPath:downloadedFilePath];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"PluginManagerControllerDownloadAndInstallDidFinish" object:self userInfo:nil];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[statusTextField setHidden:NO];
	[statusTextField setStringValue:[NSString stringWithFormat:@"%@ (%@)",NSLocalizedString(@"Download failed", nil), [error localizedDescription]]];
	[statusProgressIndicator setHidden:YES];
	[statusProgressIndicator stopAnimation:self];
}

#pragma mark install

- (void)installDownloadedPluginAtPath:(NSString*)path;
{
	[statusProgressIndicator setHidden:NO];
	[statusProgressIndicator startAnimation:self];
	
	[statusTextField setStringValue:NSLocalizedString(@"Installing...", nil)];
	
	NSString *pluginPath = path;
	
	if([self isZippedFileAtPath:path])
	{
		if(![self unZipFileAtPath:path])
		{
			[statusTextField setStringValue:NSLocalizedString(@"Error: bad zip file.", nil)];
			[statusProgressIndicator setHidden:YES];
			[statusProgressIndicator stopAnimation:self];
			return;
		}
		pluginPath = [path stringByDeletingPathExtension];
		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	}
	
	//NSString *userPluginsDirectoryPath = [PluginManager userActivePluginsDirectoryPath];
	
	// determine in which directory to install the plugin (default = user active dir, or if the plugin was already installed: in the same dir)	
	NSString *installDirectoryPath = [PluginManager userActivePluginsDirectoryPath]; // default = user active directory
	
	[PluginManager deletePluginWithName: [pluginPath lastPathComponent]];
	
	[PluginManager movePluginFromPath:pluginPath toPath:installDirectoryPath];	
	
//	NSTask *aTask = [[NSTask alloc] init];
//    NSMutableArray *args = [NSMutableArray array];
//	
//    [args addObject:pluginPath];
//    [aTask setLaunchPath:@"/usr/bin/touch"];
//    [aTask setArguments:args];
//    [aTask launch];
//	[aTask waitUntilExit];
//	[aTask release];
	
	[statusTextField setStringValue:NSLocalizedString(@"Plugin Installed", nil)];
	[statusProgressIndicator setHidden:YES];
	[statusProgressIndicator stopAnimation:self];

	[self refreshPluginList];
}

- (BOOL)isZippedFileAtPath:(NSString*)path;
{
	return [[path pathExtension] isEqualTo:@"zip"];
}

- (BOOL)unZipFileAtPath:(NSString*)path;
{
	NSTask *aTask = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];

	[args addObject:@"-o"];
    [args addObject:path];
    [args addObject:@"-d"];
	[args addObject:[path stringByDeletingLastPathComponent]];
    [aTask setLaunchPath:@"/usr/bin/unzip"];
    [aTask setArguments:args];
    [aTask launch];
	[aTask waitUntilExit];
		
	if([[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingPathExtension]])
	{
		return YES;
	}
	else
	{
		BOOL boo = [[NSWorkspace sharedWorkspace] openFile:path];
		while(![[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingPathExtension]]){ /*wait until unzip ends*/}
		return boo;
	}
	
	[aTask release];
}

#pragma mark submit plugin

- (void)loadSubmitPluginPage;
{
	#if !__LP64__
	if([NSMailDelivery hasDeliveryClassBeenConfigured])
		[self setURL:PLUGIN_SUBMISSION_URL];
	else
	#endif
		[self setURL:PLUGIN_SUBMISSION_NO_MAIL_APP_URL];
	
	[self setDownloadURL:@""];
}

- (void)sendPluginSubmission:(NSString*)request;
{
	NSString *parameters = [[request componentsSeparatedByString:@"?"] objectAtIndex:1];
	NSArray *parametersArray = [parameters componentsSeparatedByString:@"&"];
		
	NSMutableString *emailMessage = [NSMutableString stringWithString:@""];
	
	for (id loopItem in parametersArray)
	{
		NSArray *param = [loopItem componentsSeparatedByString:@"="];
		[emailMessage appendFormat:@"%@: %@ \n", [param objectAtIndex:0], [[param objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	
	NSString *emailAddress = @"joris@osirix-viewer.com,rossetantoine@osirix-viewer.com";
	NSString *emailSubject = @"OsiriX: New Plugin Submission"; // don't localize this. This is the subject of the email WE will receive.
	
	#if !__LP64__
	[NSMailDelivery deliverMessage:emailMessage subject:emailSubject to:emailAddress];
	#endif
}

#pragma mark WebPolicyDelegate Protocol methods

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener;
{
	if(![sender isEqualTo:webView]) [listener use];

	if([[actionInformation valueForKey:WebActionNavigationTypeKey] intValue]==WebNavigationTypeLinkClicked)
	{
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
	else if([[actionInformation valueForKey:WebActionNavigationTypeKey] intValue]==WebNavigationTypeFormSubmitted)
	{
		[self sendPluginSubmission:[[request URL] absoluteString]];
	}
	else
	{
		[listener use];
	}
}

@end
