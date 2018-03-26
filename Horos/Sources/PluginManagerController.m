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

#import "PluginManagerController.h"
//#import <Message/NSMailDelivery.h>
#import "WaitRendering.h"
#import "Notifications.h"
#import "PreferencesWindowController.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "AppController.h"

#import "url.h"



static NSArray *CachedOsiriXPluginsList = nil;
static NSDate *CachedOsiriXPluginsListDate = nil;

static NSArray *CachedHorosPluginsList = nil;
static NSDate *CachedHorosPluginsListDate = nil;



@implementation PluginsTableView

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0)
        return;
    
	unichar c = [[event characters] characterAtIndex:0];
	
    if ( (c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey) && [self selectedRow] >= 0 && [self numberOfRows] > 0 )
    {
		[(PluginManagerController*)[self delegate] delete:self];
    }
	else
    {
		 [super keyDown:event];
    }
}

@end



@implementation PluginManagerController


- (void) WebViewProgressStartedNotification: (NSNotification*) n
{
    NSProgressIndicator *statusProgressIndicator = nil;
    
    if (osirixPluginWebView == [n object])
    {
        statusProgressIndicator = osirixPluginStatusProgressIndicator;
    }
    else
    {
        statusProgressIndicator = horosPluginStatusProgressIndicator;
    }
    
    [statusProgressIndicator setHidden: NO];
	[statusProgressIndicator startAnimation: self];
    
    [[self window] display];
}


- (void) WebViewProgressFinishedNotification: (NSNotification*) n
{
    NSProgressIndicator *statusProgressIndicator = nil;
    
    if (osirixPluginWebView == [n object])
    {
        statusProgressIndicator = osirixPluginStatusProgressIndicator;
    }
    else
    {
        statusProgressIndicator = horosPluginStatusProgressIndicator;
    }
    
    [statusProgressIndicator setHidden: YES];
	[statusProgressIndicator stopAnimation: self];
    
    [[self window] display];
}


- (id)init
{
	self = [super initWithWindowNibName:@"PluginManager"];
	
    downloadingPlugins = [[NSMutableDictionary dictionary] retain];
    
	plugins = [[NSMutableArray arrayWithArray:[PluginManager pluginsList]] retain];
	
	osirixPluginListURLs = [[NSArray arrayWithObjects:OSIRIX_PLUGIN_LIST_URL, OSIRIX_PLUGIN_LIST_ALT_URL, nil] retain];
    horosPluginListURLs = [[NSArray arrayWithObjects:HOROS_PLUGIN_LIST_URL, HOROS_PLUGIN_LIST_ALT_URL, nil] retain];
	 
	return self;
}


- (void)windowDidBecomeMain:(NSNotification *)notification
{
    if( [AppController isFDACleared])
    {
        NSRunCriticalAlertPanel( NSLocalizedString( @"Important Notice", nil), NSLocalizedString( @"Plugins are not certified for primary diagnosis in medical imaging, unless specifically written by the plugin author(s).", nil), NSLocalizedString( @"OK", nil), nil, nil);
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self]; 
     
	[plugins release];
    
	[osirixPluginListURLs release];
    [horosPluginListURLs release];
	
    [osirixPluginDownloadURL release];
    [horosPluginDownloadURL release];
    
    [downloadingPlugins release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark installed

- (NSMutableArray*)plugins;
{
	return plugins;
}


- (NSArray*) availabilities;
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
	[pluginTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [pluginTable clickedRow]] byExtendingSelection:NO];
}


- (IBAction) delete:(id)sender;
{
    if ([[pluginsArrayController arrangedObjects] count] == 0)
        return;
    
	if( NSRunInformationalAlertPanel(NSLocalizedString(@"Delete a plugin", nil),
									 NSLocalizedString(@"Are you sure you want to delete the selected plugin?", nil),
									 NSLocalizedString(@"OK",nil),
									 NSLocalizedString(@"Cancel",nil),
									 nil) == NSAlertDefaultReturn)
	{
		NSArray *pluginsList = [pluginsArrayController arrangedObjects];
		NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable selectedRow]] objectForKey:@"name"];
		NSString *availability = [[pluginsList objectAtIndex:[pluginTable selectedRow]] objectForKey:@"availability"];
		BOOL pluginIsActive = [[[pluginsList objectAtIndex:[pluginTable selectedRow]] objectForKey:@"active"] boolValue];
		
		[PluginManager deletePluginWithName:pluginName
                               availability:availability
                                   isActive: pluginIsActive];
        
		[self refreshPluginList];
	}
}


- (IBAction)modifiyAvailability:(id)sender;
{
	NSArray *pluginsList = [pluginsArrayController arrangedObjects];
	NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"name"];
	
	[PluginManager changeAvailabilityOfPluginWithName:pluginName to:[[sender selectedCell] title]];
	
	[self refreshPluginList]; // needed to restore the availability menu in case the user did provided a good admin password
}


- (IBAction)loadPlugins:(id)sender;
{
	[PluginManager setMenus:filtersMenu :roisMenu :othersMenu :dbMenu];
}


- (void)windowWillClose:(NSNotification *)aNotification;
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
    @try
    {
        [self refreshPluginList];
    }
    @catch (NSException * e)
    {
        NSLog( @"windowwillClose exception pluginmanagercontroller: %@", e);
    }
}



- (IBAction) showWindow:(id)sender;
{
    if ([[self window] isVisible])
    {
        [[self window] makeKeyAndOrderFront:nil];
        return;
    }
    
    WaitRendering *splash = [[WaitRendering alloc] init:NSLocalizedString( @"Initializing Plugin Manager...", nil)];
    [splash showWindow:self];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self availableOsiriXPlugins];
        [self availableHorosPlugins];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSArray *viewers = [ViewerController getDisplayed2DViewers];
            for (ViewerController *viewer in viewers)
            {
                [[viewer window] close];
            }
            
            [super showWindow:sender];
            
            
            [self refreshPluginList];
            
            
            
            ////////////////////////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////////
            
            if ([DCMPix isRunOsiriXInProtectedModeActivated])
                [protectedModeLabel setHidden:NO];
            else
                [protectedModeLabel setHidden:YES];
            
            
            [osirixPluginWebView setPolicyDelegate:self];
            [horosPluginWebView setPolicyDelegate:self];
            
            [osirixPluginStatusTextField setHidden:YES];
            [osirixPluginStatusProgressIndicator setHidden:YES];
            
            [horosPluginStatusTextField setHidden:YES];
            [horosPluginStatusProgressIndicator setHidden:YES];
            
            // deactivate the back/forward options in the webView's contextual menu
            [[osirixPluginWebView backForwardList] setCapacity:0];
            [[horosPluginWebView backForwardList] setCapacity:0];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WebViewProgressStartedNotification:)  name:WebViewProgressStartedNotification  object:osirixPluginWebView];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WebViewProgressFinishedNotification:) name:WebViewProgressFinishedNotification object:osirixPluginWebView];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WebViewProgressStartedNotification:)  name:WebViewProgressStartedNotification  object:horosPluginWebView];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WebViewProgressFinishedNotification:) name:WebViewProgressFinishedNotification object:horosPluginWebView];
            
            ////////////////////////////////////////////////////////////////////////////////////////
            
            if ([[self availableOsiriXPlugins] count]<1)
            {
                [osirixPluginListPopUp removeAllItems];
                [osirixPluginListPopUp setEnabled:NO];
                [osirixPluginDownloadButton setEnabled:NO];
                
                [osirixPluginStatusTextField setHidden:NO];
                [osirixPluginStatusTextField setStringValue:NSLocalizedString(@"No OsiriX plugin server available.", nil)];
            }
            else
            {
                [self generateAvailableOsiriXPluginsMenu];
                [self setURLforOsiriXPluginWithName:[[[self availableOsiriXPlugins] objectAtIndex:0] valueForKey:@"name"]];
                [self setOsiriXPluginDownloadURL:[[[self availableOsiriXPlugins] objectAtIndex:0] valueForKey:@"download_url"]];
                
                [self setOsiriXPluginHorosCompatibility:
                 [ [ [ [self availableOsiriXPlugins] objectAtIndex:0] valueForKey:@"HorosCompatiblePlugin" ] boolValue]
                 ];
            }
            
            ////////////////////////////////////////////////////////////////////////////////////////
            
            if ([[self availableHorosPlugins] count]<1)
            {
                [horosPluginListPopUp removeAllItems];
                [horosPluginListPopUp setEnabled:NO];
                [horosPluginDownloadButton setEnabled:NO];
                
                [horosPluginStatusTextField setHidden:NO];
                [horosPluginStatusTextField setStringValue:NSLocalizedString(@"No Horos plugin server available.", nil)];
            }
            else
            {
                [self generateAvailableHorosPluginsMenu];
                [self setURLforHorosPluginWithName:[[[self availableHorosPlugins] objectAtIndex:0] valueForKey:@"name"]];
                [self setHorosPluginDownloadURL:[[[self availableHorosPlugins] objectAtIndex:0] valueForKey:@"download_url"]];
            }
            
            ////////////////////////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////////
            
            
            
            // If we need to remove a plugin with a custom pref pane
            for (NSWindow* window in [NSApp windows])
            {
                if ([window.windowController isKindOfClass:[PreferencesWindowController class]])
                {
                    [window close];
                }
            }
            
            [[self window] makeKeyAndOrderFront:nil];
            
            
            [ splash close ];
            [ splash release ];
        
        });
    });
}


- (void) awakeFromNib
{
    [super awakeFromNib];
}


- (void)refreshPluginList;
{
	NSIndexSet *selectedIndexes = [pluginTable selectedRowIndexes];
	
    [PluginManager setMenus:filtersMenu :roisMenu :othersMenu :dbMenu];
	
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
    
	return [name1 compare:name2 options: NSCaseInsensitiveSearch];
}


- (NSArray*) availableOsiriXPlugins;
{
	NSString *pluginsListURL = @"";
	NSArray *pluginsList = nil;
	
	if (CachedOsiriXPluginsListDate == nil || [CachedOsiriXPluginsListDate timeIntervalSinceNow] < -10*60)
	{
        
	}
	else if (CachedOsiriXPluginsList)
	{
		return CachedOsiriXPluginsList;
	}
    
    ////////////////////////////////////////////

	for (int i=0; i < [osirixPluginListURLs count] && !pluginsList; i++)
	{
		pluginsListURL = [osirixPluginListURLs objectAtIndex:i];
		pluginsList = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:pluginsListURL]];
	}
	
    ////////////////////////////////////////////
    
	if (!pluginsList)
        return nil;
	
	NSArray *sortedPlugins = [pluginsList sortedArrayUsingFunction:sortPluginArrayByName context:NULL];
	
	[CachedOsiriXPluginsListDate release];
	CachedOsiriXPluginsListDate = [[NSDate date] retain];
	
	[CachedOsiriXPluginsList release];
	CachedOsiriXPluginsList = [sortedPlugins retain];
	
	return sortedPlugins;
}



- (NSArray*) availableHorosPlugins;
{
    NSString *pluginsListURL = @"";
    NSArray *pluginsList = nil;
    
    if (CachedHorosPluginsListDate == nil || [CachedHorosPluginsListDate timeIntervalSinceNow] < -10*60)
    {
        
    }
    else if (CachedHorosPluginsList)
    {
        return CachedHorosPluginsList;
    }
    
    ////////////////////////////////////////////
    
    for (int i=0; i < [horosPluginListURLs count] && !pluginsList; i++)
    {
        pluginsListURL = [horosPluginListURLs objectAtIndex:i];
        pluginsList = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:pluginsListURL]];
    }
    
    ////////////////////////////////////////////
    
    if (!pluginsList)
        return nil;
    
    NSArray *sortedPlugins = [pluginsList sortedArrayUsingFunction:sortPluginArrayByName context:NULL];
    
    [CachedHorosPluginsListDate release];
    CachedHorosPluginsListDate = [[NSDate date] retain];
    
    [CachedHorosPluginsList release];
    CachedHorosPluginsList = [sortedPlugins retain];
    
    return sortedPlugins;
}



- (void )generateAvailableOsiriXPluginsMenu;
{
    [osirixPluginListPopUp removeAllItems];
    
    NSArray *availablePlugins = [self availableOsiriXPlugins];
    
    for (id loopItem in availablePlugins)
    {
        [osirixPluginListPopUp addItemWithTitle:[loopItem objectForKey:@"name"]];
    }
}


- (void )generateAvailableHorosPluginsMenu;
{
	[horosPluginListPopUp removeAllItems];
	
	NSArray *availablePlugins = [self availableHorosPlugins];
	
    for (id loopItem in availablePlugins)
	{
		[horosPluginListPopUp addItemWithTitle:[loopItem objectForKey:@"name"]];
	}
	
	//[[horosPluginListPopUp menu] addItem:[NSMenuItem separatorItem]];
    
	//[horosPluginListPopUp addItemWithTitle:NSLocalizedString(@"Your Horos Plugin here!", nil)];
}



#pragma mark OsiriX web page

- (void)setOsiriXPluginURL:(NSString*)url;
{
	[[osirixPluginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void)setURLforOsiriXPluginWithName:(NSString*) name
{
	NSArray* availablePlugins = [self availableOsiriXPlugins];
    
    ////////////////////////////
	
    for (NSDictionary *plugin in availablePlugins)
	{
		if ([[plugin valueForKey:@"name"] isEqualToString:name])
		{
            if ([[plugin valueForKey:@"HorosCompatiblePlugin"] boolValue])
            {
                [self->validatedInHorosBox setHidden:NO];
                [self->NOTvalidatedInHorosBox setHidden:YES];
            }
            else
            {
                [self->NOTvalidatedInHorosBox setHidden:NO];
                [self->validatedInHorosBox setHidden:YES];
            }
            
			[self setOsiriXPluginURL:[plugin valueForKey:@"url"]];
			[self setOsiriXPluginDownloadURL:[plugin valueForKey:@"download_url"]];
            [self setOsiriXPluginHorosCompatibility:[[plugin valueForKey:@"HorosCompatiblePlugin"] boolValue]];
			
			BOOL alreadyInstalled = NO;
			BOOL sameName = NO;
			BOOL sameVersion = NO;
			for(NSDictionary *installedPlugin in plugins)
			{	
				NSString *name = [[[plugin valueForKey:@"download_url"] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				name = [name stringByDeletingPathExtension]; // removes the .zip extension
				name = [name stringByDeletingPathExtension]; // removes .osirixplugin extension
				
                sameName = [name isEqualToString:[installedPlugin valueForKey:@"name"]];
                
                sameVersion = [[plugin valueForKey:@"version"] isEqualToString:[installedPlugin valueForKey:@"version"]];
                
                @try
                {
                    NSDecimalNumber* installedVersion = [NSDecimalNumber decimalNumberWithString:[installedPlugin valueForKey:@"version"] locale:nil];
                    NSDecimalNumber* availableVersion = [NSDecimalNumber decimalNumberWithString:[plugin valueForKey:@"version"] locale:nil];
                    
                    sameVersion = ([installedVersion floatValue] >= [availableVersion floatValue]);
                }
                @catch(...)
                {
                   
                }
                
				alreadyInstalled = alreadyInstalled || sameName || (sameName && sameVersion);
				
				if (alreadyInstalled)
                    break;
			}
			
			if (alreadyInstalled)
			{
				[osirixPluginStatusTextField setHidden:NO];
                
				if (sameName && sameVersion)
					[osirixPluginStatusTextField setStringValue:NSLocalizedString(@"Plugin already installed", nil)];
				else
					[osirixPluginStatusTextField setStringValue:NSLocalizedString(@"Download the new version!", nil)];
			}
			else
			{
				[osirixPluginStatusTextField setHidden:YES];
			}
            
			return;
		}
	}
}

- (IBAction) changeOsiriXPluginWebView:(id)sender;
{
	[self setURLforOsiriXPluginWithName:[sender title]];
}


#pragma mark Horos web page

- (void) setHorosPluginURL:(NSString*)url;
{
    [[horosPluginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}


- (void) setURLforHorosPluginWithName:(NSString*) name
{
    NSArray* availablePlugins = [self availableHorosPlugins];
    
    ////////////////////////////
    
    for (NSDictionary *plugin in availablePlugins)
    {
        if([[plugin valueForKey:@"name"] isEqualToString:name])
        {
            [self setHorosPluginURL:[plugin valueForKey:@"url"]];
            [self setHorosPluginDownloadURL:[plugin valueForKey:@"download_url"]];
            
            BOOL alreadyInstalled = NO;
            BOOL sameName = NO;
            BOOL sameVersion = NO;
            for(NSDictionary *installedPlugin in plugins)
            {
                NSString *name = [[[plugin valueForKey:@"download_url"] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                name = [name stringByDeletingPathExtension]; // removes the .zip extension
                name = [name stringByDeletingPathExtension]; // removes the .horosplugin
                
                sameName = [name isEqualToString:[installedPlugin valueForKey:@"name"]];
                
                sameVersion = [[plugin valueForKey:@"version"] isEqualToString:[installedPlugin valueForKey:@"version"]];
                
                @try
                {
                    NSDecimalNumber* installedVersion = [NSDecimalNumber decimalNumberWithString:[installedPlugin valueForKey:@"version"] locale:nil];
                    NSDecimalNumber* availableVersion = [NSDecimalNumber decimalNumberWithString:[plugin valueForKey:@"version"] locale:nil];
                    
                    sameVersion = ([installedVersion floatValue] >= [availableVersion floatValue]);
                }
                @catch(...)
                {
                    
                }
                
                alreadyInstalled = alreadyInstalled || sameName || (sameName && sameVersion);
                
                if (alreadyInstalled)
                    break;
            }
            
            if(alreadyInstalled)
            {
                [horosPluginStatusTextField setHidden:NO];
                
                if(sameName && sameVersion)
                    [horosPluginStatusTextField setStringValue:NSLocalizedString(@"Plugin already installed", nil)];
                else
                    [horosPluginStatusTextField setStringValue:NSLocalizedString(@"Download the new version!", nil)];
            }
            else
            {
                [horosPluginStatusTextField setHidden:YES];
            }
            
            return;
        }
        else if ([name isEqualToString:NSLocalizedString(@"Your Horos Plugin here!", nil)])
        {
            [self loadSubmitPluginPage];
            
            return;
        }
    }
}

- (IBAction) changeHorosPluginWebView:(id)sender;
{
    [self setURLforHorosPluginWithName:[sender title]];
}


#pragma mark download

- (void) setOsiriXPluginHorosCompatibility:(BOOL) compatible
{
    osiriXPluginHorosCompatibility = compatible;
}

- (void) setOsiriXPluginDownloadURL:(NSString*)url
{
	if (osirixPluginDownloadURL)
    {
        [osirixPluginDownloadURL release];
    }
	
    osirixPluginDownloadURL = url;
    
    [osirixPluginDownloadURL retain];
	
    if ([osirixPluginDownloadURL isEqualToString:@""])
    {
		[osirixPluginDownloadButton setHidden:YES];
    }
	else
    {
		[osirixPluginDownloadButton setHidden:NO];
    }
}


- (void) setHorosPluginDownloadURL:(NSString*)url
{
    if (horosPluginDownloadURL)
    {
        [horosPluginDownloadURL release];
    }
    
    horosPluginDownloadURL = url;
    
    [horosPluginDownloadURL retain];
    
    if ([horosPluginDownloadURL isEqualToString:@""])
    {
        [horosPluginDownloadButton setHidden:YES];
    }
    else
    {
        [horosPluginDownloadButton setHidden:NO];
    }
}


- (void) fakeThread: (NSString*) downloadedFilePath
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    BOOL downloading = YES;
    
    while( downloading)
    {
        @synchronized( downloadingPlugins)
        {
            if( [downloadingPlugins objectForKey: downloadedFilePath] == nil)
            {
                downloading = NO;
            }
            
            [NSThread sleepForTimeInterval: 1];
        }
    }
    
    [pool release];
}


- (IBAction) downloadOsiriXPlugin:(id)sender;
{
    if (self->osiriXPluginHorosCompatibility == NO)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No",nil)];
        [alert setMessageText:NSLocalizedString(@"Not validated OsiriX plugin.",nil)];
        [alert setInformativeText:NSLocalizedString(@"Not validated OsiriX plugins may cause Horos run-time errors. In case of problems, you can disable/uninstall them in [Plugins => Plugin Manager]. Continue installing?",nil)];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] != NSAlertFirstButtonReturn)
        {
            [alert release];
            return;
        }
        
        [alert release];
    }
    
    NSString *downloadedFilePath = [NSString stringWithFormat:@"/tmp/%@", [[osirixPluginDownloadURL lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    @synchronized(downloadingPlugins)
    {
        if( [downloadingPlugins objectForKey: downloadedFilePath])
            NSLog( @"---- Already downloading...");
        
        else
        {
            NSURLDownload *download = [[[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:osirixPluginDownloadURL]] delegate:self] autorelease];
            
            [download setDestination: downloadedFilePath allowOverwrite:YES];
            
            [downloadingPlugins setObject: download forKey: downloadedFilePath];
            
            NSThread *t = [[[NSThread alloc] initWithTarget:self selector: @selector(fakeThread:) object: downloadedFilePath] autorelease];
            t.name = NSLocalizedString( @"Plugin download...", nil);
            t.status = osirixPluginDownloadURL;
            [[ThreadsManager defaultManager] addThreadAndStart: t];
        }
    }
}


- (IBAction) downloadHorosPlugin:(id)sender;
{
    NSString *downloadedFilePath = [NSString stringWithFormat:@"/tmp/%@", [[horosPluginDownloadURL lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    @synchronized( downloadingPlugins)
    {
        if( [downloadingPlugins objectForKey: downloadedFilePath])
            NSLog( @"---- Already downloading...");
        
        else
        {
            NSURLDownload *download = [[[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:horosPluginDownloadURL]] delegate:self] autorelease];
            
            [download setDestination: downloadedFilePath allowOverwrite:YES];
            
            [downloadingPlugins setObject: download forKey: downloadedFilePath];
            
            NSThread *t = [[[NSThread alloc] initWithTarget:self selector: @selector(fakeThread:) object: downloadedFilePath] autorelease];
            t.name = NSLocalizedString( @"Plugin download...", nil);
            t.status = horosPluginDownloadURL;
            [[ThreadsManager defaultManager] addThreadAndStart: t];
        }
    }
}



- (void)downloadDidBegin:(NSURLDownload *) download
{
    NSTextField *statusTextField = nil;
    NSProgressIndicator *statusProgressIndicator = nil;
    
    //////////////
    
    NSArray *paths = nil;
    @synchronized(downloadingPlugins)
    {
        paths = [downloadingPlugins allKeysForObject:download];
        
        if (paths.count == 1)
        {
            if ([[paths objectAtIndex:0] containsString:@"osirixplugin"])
            {
                statusTextField = osirixPluginStatusTextField;
                statusProgressIndicator = osirixPluginStatusProgressIndicator;
            }
            else
            {
                statusTextField = horosPluginStatusTextField;
                statusProgressIndicator = horosPluginStatusProgressIndicator;
            }
        }
    }
    
    //////////////
    
	[statusTextField setHidden:NO];
	[statusTextField setStringValue:NSLocalizedString(@"Downloading...", nil)];
	[statusProgressIndicator setHidden:NO];
	[statusProgressIndicator startAnimation:self];
}


- (void)downloadDidFinish:(NSURLDownload *) download
{
    NSTextField *statusTextField = nil;
    NSProgressIndicator *statusProgressIndicator = nil;
    
    //////////////
    
    NSArray *paths = nil;
    @synchronized(downloadingPlugins)
    {
        paths = [downloadingPlugins allKeysForObject:download];
        
        if (paths.count == 1)
        {
            if ([[paths objectAtIndex:0] containsString:@"osirixplugin"])
            {
                statusTextField = osirixPluginStatusTextField;
                statusProgressIndicator = osirixPluginStatusProgressIndicator;
            }
            else
            {
                statusTextField = horosPluginStatusTextField;
                statusProgressIndicator = horosPluginStatusProgressIndicator;
            }
        }
    }
    
    //////////////
    
	[statusTextField setStringValue:NSLocalizedString(@"Plugin downloaded", nil)];
	[statusProgressIndicator setHidden:YES];
	[statusProgressIndicator stopAnimation:self];
    
    //////////////
    
    @synchronized( downloadingPlugins)
    {
        paths = [downloadingPlugins allKeysForObject: download];
    }
    
    if (paths.count == 1)
    {
        [self installDownloadedPluginAtPath: [paths lastObject]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AppPluginDownloadInstallDidFinishNotification object:self userInfo:nil];
        
        @synchronized( downloadingPlugins)
        {
            [downloadingPlugins removeObjectForKey: [paths lastObject]];
        }
    }
    else
    {
        NSLog( @"***** downloadDidFinish path for download?");
    }
}


- (void) download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    NSTextField *statusTextField = nil;
    NSProgressIndicator *statusProgressIndicator = nil;
    
    //////////////
    
    NSArray *paths = nil;
    @synchronized(downloadingPlugins)
    {
        paths = [downloadingPlugins allKeysForObject:download];
        
        if (paths.count == 1)
        {
            if ([[paths objectAtIndex:0] containsString:@"osirixplugin"])
            {
                statusTextField = osirixPluginStatusTextField;
                statusProgressIndicator = osirixPluginStatusProgressIndicator;
            }
            else
            {
                statusTextField = horosPluginStatusTextField;
                statusProgressIndicator = horosPluginStatusProgressIndicator;
            }
        }
    }
    
    //////////////
    
	[statusTextField setHidden:NO];
	[statusTextField setStringValue:NSLocalizedString(@"Download failed", nil)];
     
    NSRunCriticalAlertPanel( NSLocalizedString(@"Download failed", nil), @"%@",
                             NSLocalizedString(@"OK", nil), nil, nil,
                             [error localizedDescription]);
    
	[statusProgressIndicator setHidden:YES];
	[statusProgressIndicator stopAnimation:self];
    
    //////////////
    
    @synchronized( downloadingPlugins)
    {
        paths = [downloadingPlugins allKeysForObject: download];
    }
    
    if(paths.count == 1)
    {
        @synchronized( downloadingPlugins)
        {
            [downloadingPlugins removeObjectForKey:[paths lastObject]];
        }
    }
    else
    {
        NSLog( @"***** download didFailWithError path for download?");
    }
}



#pragma mark install / uinstall

- (void) installDownloadedPluginAtPath:(NSString*) path;
{
    NSTextField *statusTextField = nil;
    NSProgressIndicator *statusProgressIndicator = nil;
    
    if ([path containsString:@"osirixplugin"])
    {
        statusTextField = osirixPluginStatusTextField;
        statusProgressIndicator = osirixPluginStatusProgressIndicator;
    }
    else
    {
        statusTextField = horosPluginStatusTextField;
        statusProgressIndicator = horosPluginStatusProgressIndicator;
    }
    
    
	[statusProgressIndicator setHidden:NO];
	[statusProgressIndicator startAnimation:self];
	
	[statusTextField setStringValue:NSLocalizedString(@"Installing...", nil)];
	
	NSString *pluginPath = path;
	
	if([self isZippedFileAtPath:path] && [self unZipFileAtPath:path])
	{
		pluginPath = [path stringByDeletingPathExtension];
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	}
    else
    {
        [statusTextField setStringValue:NSLocalizedString(@"Error: bad zip file", nil)];
        [statusProgressIndicator setHidden:YES];
        [statusProgressIndicator stopAnimation:self];
        return;
    }
	
	NSString *oldPath = [PluginManager deletePluginWithName: [pluginPath lastPathComponent]];
	
	// determine in which directory to install the plugin (default = user dir, or if the plugin was already installed: in the same dir)	
	NSString *installDirectoryPath;

	if( oldPath)
		installDirectoryPath = oldPath;
	else
		installDirectoryPath = [PluginManager userActivePluginsDirectoryPath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:installDirectoryPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:installDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
	
    // Install the plugin
	[PluginManager movePluginFromPath:pluginPath toPath: installDirectoryPath];	
	
    // load the plugin
    [PluginManager loadPluginAtPath: [installDirectoryPath stringByAppendingPathComponent: [pluginPath lastPathComponent]]];
	
	[statusTextField setStringValue:NSLocalizedString( @"Plugin Installed", nil)];
	[statusProgressIndicator setHidden:YES];
	[statusProgressIndicator stopAnimation:self];

	[self refreshPluginList];
}


- (BOOL) isZippedFileAtPath:(NSString*)path;
{
	return [[path pathExtension] isEqualTo:@"zip"];
}


- (BOOL) unZipFileAtPath:(NSString*)path;
{
    if( path.length == 0)
        return NO;
    
    @try
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
        while( [aTask isRunning])
            [NSThread sleepForTimeInterval: 0.1];
        
        //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
        [aTask release];
	}
    @catch (NSException *e)
    {
        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
    }
        
	if([[NSFileManager defaultManager] fileExistsAtPath:[path stringByDeletingPathExtension]])
		return YES;
	else
        return NO;
}



#pragma mark submit plugin

- (void)loadSubmitPluginPage;
{
    [self setHorosPluginURL:HOROS_PLUGIN_SUBMISSION_URL];
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
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:"URL_EMAIL]];
}



#pragma mark WebPolicyDelegate Protocol methods

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener;
{
	if(![sender isEqualTo:osirixPluginWebView] && ![sender isEqualTo:horosPluginWebView])
    {
        [listener use];
    }

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
