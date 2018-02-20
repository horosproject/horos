/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <SecurityInterface/SFCertificateView.h>
#import "WebPortalUser.h"
#import "OSIWebSharingPreferencePanePref.h"
#import "DefaultsOsiriX.h"
#import "NSUserDefaults+OsiriX.h"
#import "BrowserController.h"
#import "AppController.h"
#import "NSFileManager+N2.h"
#import "WebPortal.h"
#import "WebPortalDatabase.h"
#import "DicomDatabase.h"
#import "DicomStudy.h"

#import "DDKeychain.h"
#import "url.h"

//#include <netdb.h>
//#include <unistd.h>
//#include <netinet/in.h>
//#include <arpa/inet.h>

@interface SecondsToMinutesTransformer: NSValueTransformer {}
@end
@implementation SecondsToMinutesTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

+ (Class)transformedValueClass {
    return [NSNumber class];
}

- (id)transformedValue:(NSNumber*) number {
    return [NSNumber numberWithInt: (number.integerValue / 60)];
}

- (id)reverseTransformedValue:(NSNumber*) number
{
    return [NSNumber numberWithInt: (number.integerValue * 60)];
}
@end

@implementation OSIWebSharingPreferencePanePref

@synthesize TLSAuthenticationCertificate;

- (void) usernameChanged: (NSNotification*) notification
{
    WebPortalUser *user = [notification object];
    
    if( user == [[userArrayController selectedObjects] lastObject])
        NSRunInformationalAlertPanel( NSLocalizedString(@"User's name", nil), NSLocalizedString(@"User's name changed. The password has been reset to a new password: %@", nil), NSLocalizedString(@"OK", nil), nil, nil, user.password);
}

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"OSIWebSharingPreferencePanePref" bundle: nil];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
        [usersPanel retain];
        
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(usernameChanged:) name: @"WebPortalUsernameChanged" object: nil];
	}
	
	return self;
}

-(void)awakeFromNib
{
	[addressTextField.cell setPlaceholderString:NSUserDefaults.defaultWebPortalAddress];
	[portTextField.cell setPlaceholderString:[NSNumber numberWithInteger:NSUserDefaults.webPortalPortNumber].stringValue];
	
	[usersTable setSortDescriptors:[NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
}

- (NSString*) UniqueLabelForSelectedServer;
{
	return @"org.horosproject.horoswebserver";
}

- (void)getTLSCertificate;
{	
	NSString *label = [self UniqueLabelForSelectedServer];
	NSString *name = [DDKeychain certificateNameForLabel:label];
	NSImage *icon = [DDKeychain certificateIconForLabel:label];
	
	if(!name)
	{
		name = NSLocalizedString(@"No certificate selected.", @"No certificate selected.");	
		[TLSCertificateButton setHidden:YES];
		[TLSChooseCertificateButton setTitle:NSLocalizedString(@"Choose", @"Choose")];
	}
	else
	{
		[TLSCertificateButton setHidden:NO];
		[TLSCertificateButton setImage:icon];
		[TLSChooseCertificateButton setTitle:NSLocalizedString(@"Change", @"Change")];
	}

	self.TLSAuthenticationCertificate = name;
}

- (IBAction)chooseTLSCertificate:(id)sender
{
	NSArray *certificates = [DDKeychain KeychainAccessCertificatesList];
	
	if([certificates count])
	{
		[[SFChooseIdentityPanel sharedChooseIdentityPanel] setAlternateButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")];
		NSInteger clickedButton = [[SFChooseIdentityPanel sharedChooseIdentityPanel] runModalForIdentities:certificates message:NSLocalizedString(@"Choose a certificate from the following list.", @"Choose a certificate from the following list.")];
		
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
		NSInteger clickedButton = NSRunCriticalAlertPanel(NSLocalizedString(@"No Valid Certificate", nil), NSLocalizedString(@"Your Keychain does not contain any valid certificate.", nil), NSLocalizedString(@"Help", nil), NSLocalizedString(@"Cancel", nil), nil);

		if(clickedButton==NSOKButton)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URL_HOROS_DOC_SECURITY]];
		}
		
		return;
	}
}

- (IBAction)viewTLSCertificate:(id)sender;
{
	NSString *label = [self UniqueLabelForSelectedServer];
	[DDKeychain openCertificatePanelForLabel:label];
}

- (NSManagedObjectContext*)managedObjectContext
{
	return WebPortal.defaultWebPortal.database.managedObjectContext;
}

//- (void) enableControls: (BOOL) val
//{
///	[[NSUserDefaults standardUserDefaults] setBool: val forKey: @"authorizedToEdit"];
//}

- (void) dealloc
{
	NSLog(@"dealloc OSIWebSharingPreferencePanePref");
	
    [studiesArrayController removeObserver: self forKeyPath: @"selection"];
    
    [usersPanel release];
    
    [_tlos release]; _tlos = nil;
    
	[super dealloc];
}

- (void) mainViewDidLoad
{
	[studiesArrayController addObserver: self forKeyPath: @"selection" options:(NSKeyValueObservingOptionNew) context:NULL];
	
	[self getTLSCertificate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if( [keyPath isEqualToString: @"selection"] && [NSThread isMainThread])
	{
		DicomStudy* study = [[studiesArrayController selectedObjects] lastObject];
        // Automatically display the selected study in the main DB window
		if( study)
			[[BrowserController currentBrowser] displayStudy:study object:study command:@"Select"];
	}
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
	
	[WebPortal.defaultWebPortal.database save];
	
	[BrowserController currentBrowser].testPredicate = nil;
	[[BrowserController currentBrowser] outlineViewRefresh];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (IBAction)smartAlbumHelpButton: (id)sender
{
	if( [sender tag] == 0)
    {
        [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/OsiriXTables.pdf" error:nil];
        [[NSFileManager defaultManager] copyItemAtPath: [[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"] toPath: @"/tmp/OsiriXTables.pdf" error: nil];
		[[NSWorkspace sharedWorkspace] openFile: @"/tmp/OsiriXTables.pdf"];
	}
    
	if( [sender tag] == 1)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];

	if( [sender tag] == 2)
	{
		[[[self mainView] window] makeFirstResponder: nil];
		
		@try
		{
			[BrowserController currentBrowser].testPredicate = [DicomDatabase predicateForSmartAlbumFilter: [[[userArrayController selectedObjects] lastObject] valueForKey: @"studyPredicate"]];
			[[BrowserController currentBrowser] outlineViewRefresh];
			[BrowserController currentBrowser].testPredicate = nil;
			NSRunInformationalAlertPanel( NSLocalizedString(@"Study Filter", nil), NSLocalizedString(@"The result is now displayed in the Database Window.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
		@catch (NSException * e)
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil), NSLocalizedString(@"This filter is NOT working: %@", nil), NSLocalizedString(@"OK", nil), nil, nil, e);
		}
	}
}

- (IBAction) openKeyChainAccess:(id) sender
{
	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.keychainaccess"];
	
	[[NSWorkspace sharedWorkspace] launchApplication: path];
}

- (IBAction) copyMissingCustomizedFiles: (id) sender
{
	#ifdef MACAPPSTORE
    [[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WebServicesHTML"] toPath: [@"~/Library/Application Support/Horos App/WebServicesHTML" stringByExpandingTildeInPath] byReplacingExisting:NO error:NULL];
    #else
    [[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"WebServicesHTML"] toPath: [@"~/Library/Application Support/Horos/WebServicesHTML" stringByExpandingTildeInPath] byReplacingExisting:NO error:NULL];
    #endif
}

- (IBAction) editUsers: (id) sender {
	[NSApp beginSheet:usersPanel modalForWindow:self.mainView.window modalDelegate:self didEndSelector:@selector(editUsersSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(IBAction)exitEditUsers:(NSButton*)sender {
	[usersPanel makeFirstResponder: nil];
	[NSApp endSheet:usersPanel];
}

- (void)editUsersSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:NULL];
    
    [[self managedObjectContext] save: NULL];
}

@end
