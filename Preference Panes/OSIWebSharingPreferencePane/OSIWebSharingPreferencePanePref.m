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

#import "OSIWebSharingPreferencePanePref.h"
#import "DefaultsOsiriX.h"
#import "BrowserController.h"

#include <netdb.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

char *GetPrivateIP()
{
	struct			hostent *h;
	char			hostname[100];
	gethostname(hostname, 99);
	if ((h=gethostbyname(hostname)) == NULL)
	{
        perror("Error: ");
        return "(Error locating Private IP Address)";
    }
	
    return (char*) inet_ntoa(*((struct in_addr *)h->h_addr));
}

@implementation OSIWebSharingPreferencePanePref

- (NSManagedObjectContext*) managedObjectContext
{
	return [[BrowserController currentBrowser] userManagedObjectContext];
}

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
	
	if( aView == _authView) return;
	
    if ([aView isKindOfClass: [NSControl class] ])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }

	// Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
}

- (void) enableControls: (BOOL) val
{
	[[NSUserDefaults standardUserDefaults] setBool: val forKey: @"authorizedToEdit"];
	
	[self checkView: [self mainView] :val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTHENTICATION"])
		[self enableControls: NO];
	else
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"authorizedToEdit"];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIWebSharingPreferencePanePref");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"authorizedToEdit"];
		
		[_authView setString:"com.rossetantoine.osirix.preferences.listener"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];
	
	[studiesArrayController addObserver:self forKeyPath: @"selection" options:(NSKeyValueObservingOptionNew) context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// Automatically display the selected study in the main DB window
	if( [[studiesArrayController selectedObjects] lastObject])
		[[BrowserController currentBrowser]	findObject:	[NSString stringWithFormat: @"patientUID =='%@' AND studyInstanceUID == '%@'", [[[studiesArrayController selectedObjects] lastObject] valueForKey:@"patientUID"], [[[studiesArrayController selectedObjects] lastObject] valueForKey:@"studyInstanceUID"]] table: @"Study" execute: @"Select" elements: nil];
}

- (void) willUnselect
{
	[[BrowserController currentBrowser] saveUserDatabase];
	
	[BrowserController currentBrowser].testPredicate = nil;
	[[BrowserController currentBrowser] outlineViewRefresh];
}

- (IBAction)smartAlbumHelpButton: (id)sender
{
	if( [sender tag] == 0)
		[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource: @"OsiriXTables" ofType:@"pdf"]];
	
	if( [sender tag] == 1)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];

	if( [sender tag] == 2)
	{
		[[[self mainView] window] makeFirstResponder: nil];
		
		@try
		{
			[BrowserController currentBrowser].testPredicate = [[BrowserController currentBrowser] smartAlbumPredicateString: [[[userArrayController selectedObjects] lastObject] valueForKey: @"studyPredicate"]];
			[[BrowserController currentBrowser] outlineViewRefresh];
			[BrowserController currentBrowser].testPredicate = nil;
			NSRunInformationalAlertPanel( NSLocalizedString(@"It works !",nil), NSLocalizedString(@"This filter works: the result is now displayed in the Database Window.", nil), NSLocalizedString(@"OK",nil), nil, nil);
		}
		@catch (NSException * e)
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Error",nil), [NSString stringWithFormat: NSLocalizedString(@"This filter is NOT working: %@", nil), e], NSLocalizedString(@"OK",nil), nil, nil);
		}
	}
}

- (IBAction) openKeyChainAccess:(id) sender
{
	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.keychainaccess"];
	
	[[NSWorkspace sharedWorkspace] launchApplication: path];
}
@end
