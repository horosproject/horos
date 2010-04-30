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

#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <SecurityInterface/SFCertificateView.h>

#import "OSIWebSharingPreferencePanePref.h"
#import <OsiriX Headers/DefaultsOsiriX.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/AppController.h>
#import "DDKeychain.h"

#include <netdb.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

extern BOOL hasMacOSXSnowLeopard();

@implementation OSIWebSharingPreferencePanePref

@synthesize TLSAuthenticationCertificate;

- (NSString*) UniqueLabelForSelectedServer;
{
	return @"com.osirixviewer.osirixwebserver";
}

- (void)getTLSCertificate;
{	
	NSString *label = [self UniqueLabelForSelectedServer];
	NSString *name = [DDKeychain certificateNameForLabel:label];
	NSImage *icon = [DDKeychain certificateIconForLabel:label];
	
	if(!name)
	{
		name = NSLocalizedStringFromTableInBundle(@"No certificate selected.", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], @"No certificate selected.");	
		[TLSCertificateButton setHidden:YES];
		[TLSChooseCertificateButton setTitle:NSLocalizedStringFromTableInBundle(@"Choose", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], @"Choose")];
	}
	else
	{
		[TLSCertificateButton setHidden:NO];
		[TLSCertificateButton setImage:icon];
		[TLSChooseCertificateButton setTitle:NSLocalizedStringFromTableInBundle(@"Change", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], @"Change")];
	}

	self.TLSAuthenticationCertificate = name;
}

- (IBAction)chooseTLSCertificate:(id)sender
{
	NSArray *certificates = [DDKeychain KeychainAccessCertificatesList];
	
	if([certificates count])
	{
		[[SFChooseIdentityPanel sharedChooseIdentityPanel] setAlternateButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], @"Cancel")];
		NSInteger clickedButton = [[SFChooseIdentityPanel sharedChooseIdentityPanel] runModalForIdentities:certificates message:NSLocalizedStringFromTableInBundle(@"Choose a certificate from the following list.", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], @"Choose a certificate from the following list.")];
		
		if(clickedButton==NSOKButton)
		{
			SecIdentityRef identity = [[SFChooseIdentityPanel sharedChooseIdentityPanel] identity];
			if(identity)
			{
				[DDKeychain KeychainAccessSetPreferredIdentity:identity forName:[self UniqueLabelForSelectedServer] keyUse:CSSM_KEYUSE_ANY];
				[self getTLSCertificate];
			}
		}
		else if(clickedButton==NSCancelButton)
			return;
	}
	else
	{
		NSInteger clickedButton = NSRunCriticalAlertPanel(NSLocalizedStringFromTableInBundle(@"No Valid Certificate", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"Your Keychain does not contain any valid certificate.", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"Help", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), nil);

		if(clickedButton==NSOKButton)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://osirix.svn.sourceforge.net/viewvc/osirix/Documentation/Security/index.html"]];
		}
		
		return;
	}
}

- (IBAction)viewTLSCertificate:(id)sender;
{
	NSString *label = [self UniqueLabelForSelectedServer];
	[DDKeychain openCertificatePanelForLabel:label];
}

- (NSManagedObjectContext*) managedObjectContext
{
	return [[BrowserController currentBrowser] userManagedObjectContext];
}

//- (void) enableControls: (BOOL) val
//{
///	[[NSUserDefaults standardUserDefaults] setBool: val forKey: @"authorizedToEdit"];
//}

- (void) dealloc
{
	NSLog(@"dealloc OSIWebSharingPreferencePanePref");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	[studiesArrayController addObserver: self forKeyPath: @"selection" options:(NSKeyValueObservingOptionNew) context:NULL];
	
	
	[self getTLSCertificate];
	
	
	if( hasMacOSXSnowLeopard() == NO)
		NSRunCriticalAlertPanel( NSLocalizedStringFromTableInBundle( @"Unsupported", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle( @"It is highly recommend to upgrade to MacOS 10.6 or higher to use the OsiriX Web Server.", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle( @"OK", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil) , nil, nil);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if( [keyPath isEqualToString: @"selection"] && [NSThread isMainThread])
	{
		// Automatically display the selected study in the main DB window
		if( [[studiesArrayController selectedObjects] lastObject])
			[[BrowserController currentBrowser]	findObject:	[NSString stringWithFormat: @"patientUID =='%@' AND studyInstanceUID == '%@'", [[[studiesArrayController selectedObjects] lastObject] valueForKey:@"patientUID"], [[[studiesArrayController selectedObjects] lastObject] valueForKey:@"studyInstanceUID"]] table: @"Study" execute: @"Select" elements: nil];
	}
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
	
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
			NSRunInformationalAlertPanel( NSLocalizedStringFromTableInBundle(@"Study Filter", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"The result is now displayed in the Database Window.", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"OK", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), nil, nil);
		}
		@catch (NSException * e)
		{
			NSRunCriticalAlertPanel( NSLocalizedStringFromTableInBundle(@"Error", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), [NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"This filter is NOT working: %@", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), e], NSLocalizedStringFromTableInBundle(@"OK", nil, [NSBundle bundleForClass: [OSIWebSharingPreferencePanePref class]], nil), nil, nil);
		}
	}
}

- (IBAction) openKeyChainAccess:(id) sender
{
	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.keychainaccess"];
	
	[[NSWorkspace sharedWorkspace] launchApplication: path];
}
@end
