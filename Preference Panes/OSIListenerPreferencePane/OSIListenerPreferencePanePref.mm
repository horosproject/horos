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

#import "OSIListenerPreferencePanePref.h"
#import <OsiriXAPI/DefaultsOsiriX.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/NSUserDefaultsController+OsiriX.h>
#import "DDKeychain.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <OsiriXAPI/WebPortal.h>
#import <OsiriXAPI/WebPortalDatabase.h>

#include <netdb.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

//char *GetPrivateIP()
//{
//	struct			hostent *h;
//	char			hostname[100];
//	gethostname(hostname, 99);
//	if ((h=gethostbyname(hostname)) == NULL)
//	{
//        perror("Error: ");
//        return (char*)"(Error locating Private IP Address)";
//    }
//	
//    return (char*) inet_ntoa(*((struct in_addr *)h->h_addr));
//}

@implementation OSIListenerPreferencePanePref

@synthesize TLSAuthenticationCertificate;
@synthesize TLSSupportedCipherSuite;
@synthesize TLSCertificateVerification;
@synthesize TLSUseDHParameterFileURL;
@synthesize TLSDHParameterFileURL;
@synthesize TLSUseSameAETITLE;
@synthesize TLSStoreSCPAETITLE;
@synthesize TLSStoreSCPAETITLEIsDefaultAET;

- (NSManagedObjectContext*) managedObjectContext
{
	return WebPortal.defaultWebPortal.database.managedObjectContext;
}

-(NSArray*)IPv4Address;
{
	NSEnumerator* e = [[[DefaultsOsiriX currentHost] addresses] objectEnumerator];
	NSString* addr;
	NSMutableArray* r = [NSMutableArray array];

	while (addr = (NSString*)[e nextObject])
	{
		if ([[addr componentsSeparatedByString:@"."] count] == 4 && ![addr isEqual:@"127.0.0.1"])
		{
			[r addObject: addr];
		}
	}
	
	if( [r count] == 0) [r addObject: [NSString stringWithFormat:@"127.0.0.1"]];
   
   return r;
}

-(void)awakeFromNib {
	[sharingNameField.cell setPlaceholderString:NSUserDefaults.defaultBonjourSharingName];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIListenerPreferencePanePref");
	
	[TLSAuthenticationCertificate release];
	[TLSSupportedCipherSuite release];
	[TLSDHParameterFileURL release];
	[TLSStoreSCPAETITLE release];
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if( [defaults integerForKey:@"DICOMTimeout"] < 1)
		[defaults setObject:@"1" forKey:@"DICOMTimeout"];
	
	if( [defaults integerForKey:@"DICOMTimeout"] > 480)
		[defaults setObject:@"480" forKey:@"DICOMTimeout"];
	

	//setup GUI
	
//	NSString *ip = [NSString stringWithCString:GetPrivateIP()];
	NSString *ip = [[self IPv4Address] componentsJoinedByString:@", "];
	char hostname[ _POSIX_HOST_NAME_MAX+1];
	gethostname(hostname, _POSIX_HOST_NAME_MAX);
	NSString *name = [NSString stringWithUTF8String: hostname];
	
	[ipField setStringValue: ip];
	[nameField setStringValue: name];
	
	[self getTLSCertificate];
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"] < 1)
		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"DICOMTimeout"];
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"] > 480)
		[[NSUserDefaults standardUserDefaults] setObject:@"480" forKey:@"DICOMTimeout"];
}

- (IBAction)smartAlbumHelpButton: (id)sender
{
	if( [sender tag] == 0)
		[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"]];
	
	if( [sender tag] == 1)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];
}

- (IBAction) openKeyChainAccess:(id) sender
{
	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.keychainaccess"];
	
	[[NSWorkspace sharedWorkspace] launchApplication: path];
}

-(IBAction)editAddresses:(id)sender {
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:[NSArray arrayWithObject:[[NSBundle bundleForClass:[self class]] pathForResource:@"OpenNetworkSysPrefs" ofType:@"scpt"]]];
}

-(IBAction)editHostname:(id)sender {
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:[NSArray arrayWithObject:[[NSBundle bundleForClass:[self class]] pathForResource:@"OpenSharingSysPrefs" ofType:@"scpt"]]];
}

#pragma mark TLS

- (IBAction)editTLS:(id)sender;
{
	NSArray *selectedCipherSuites = [[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPCipherSuites"];
	
	if ([selectedCipherSuites count])
	{
		NSMutableArray *mutableSelectedCipherSuites = [NSMutableArray array];
		for( id suite in selectedCipherSuites)
			[mutableSelectedCipherSuites addObject: [[suite mutableCopy] autorelease]];
		self.TLSSupportedCipherSuite = mutableSelectedCipherSuites;
	}
	else
		self.TLSSupportedCipherSuite = [DICOMTLS defaultCipherSuites];

	self.TLSUseDHParameterFileURL = [[[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPUseDHParameterFileURL"] boolValue];
	NSString *dhParameterFileURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPDHParameterFileURL"];
	if(!dhParameterFileURL)
		dhParameterFileURL = NSHomeDirectory();
	self.TLSDHParameterFileURL = [NSURL fileURLWithPath:dhParameterFileURL];
	
	if([[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPCertificateVerification"])
		self.TLSCertificateVerification = (TLSCertificateVerificationType)[[[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPCertificateVerification"] intValue];
	else
		self.TLSCertificateVerification = IgnorePeerCertificate;
	
	self.TLSUseSameAETITLE = [[[NSUserDefaults standardUserDefaults] valueForKey:@"TLSUseSameAETITLE"] boolValue];
	self.TLSStoreSCPAETITLE = [[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPAETITLE"];
	
	[self updateTLSStoreSCPAETITLEIsDefaultAETButton];
	
	[TLSPreferredSyntaxTextField setStringValue:[[preferredSyntaxPopUpButton selectedItem] title]];
	
	if( [self.TLSStoreSCPAETITLE length] <= 0)
	{
		self.TLSUseSameAETITLE = YES;
		self.TLSStoreSCPAETITLE = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
	}
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"TLSStoreSCPAEPORT"] <= 0)
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"AEPORT"] + 1 forKey: @"TLSStoreSCPAEPORT"]; 
		
	[NSApp beginSheet: TLSSettingsWindow
	   modalForWindow: [[self mainView] window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	int result = [NSApp runModalForWindow: TLSSettingsWindow];
	[TLSSettingsWindow makeFirstResponder: nil];
	
	[NSApp endSheet: TLSSettingsWindow];
	[TLSSettingsWindow orderOut: self];
	
	if( result == NSRunStoppedResponse)
	{
		if( [self.TLSStoreSCPAETITLE length] <= 0)
		{
			self.TLSUseSameAETITLE = YES;
			self.TLSStoreSCPAETITLE = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
		}
		
		if( [[NSUserDefaults standardUserDefaults] integerForKey: @"TLSStoreSCPAEPORT"] <= 0)
			[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"AEPORT"] + 1 forKey: @"TLSStoreSCPAEPORT"]; 
		
		[[NSUserDefaults standardUserDefaults] setObject:self.TLSSupportedCipherSuite forKey:@"TLSStoreSCPCipherSuites"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.TLSUseDHParameterFileURL] forKey:@"TLSStoreSCPUseDHParameterFileURL"];
		[[NSUserDefaults standardUserDefaults] setObject:[self.TLSDHParameterFileURL path] forKey:@"TLSStoreSCPDHParameterFileURL"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.TLSCertificateVerification] forKey:@"TLSStoreSCPCertificateVerification"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.TLSUseSameAETITLE] forKey:@"TLSUseSameAETITLE"];
		[[NSUserDefaults standardUserDefaults] setObject:self.TLSStoreSCPAETITLE forKey:@"TLSStoreSCPAETITLE"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.TLSStoreSCPAETITLEIsDefaultAET] forKey:@"TLSStoreSCPAETITLEIsDefaultAET"];
		
		NSRunAlertPanel( NSLocalizedString( @"DICOM Listener", nil), NSLocalizedString( @"Restart OsiriX to apply these changes.", nil), NSLocalizedString( @"OK", nil), nil, nil);
	}
}

- (IBAction)cancel:(id)sender;
{
	[NSApp abortModal];
}

- (IBAction)ok:(id)sender;
{
	[NSApp stopModal];
}

- (IBAction)selectAllSuites:(id)sender;
{
	for( NSMutableDictionary *suite in self.TLSSupportedCipherSuite)
		[suite setObject: [NSNumber numberWithBool: YES] forKey: @"Supported"];
}

- (IBAction)deselectAllSuites:(id)sender;
{
	for( NSMutableDictionary *suite in self.TLSSupportedCipherSuite)
		[suite setObject: [NSNumber numberWithBool: NO] forKey: @"Supported"];
}

- (IBAction)chooseTLSCertificate:(id)sender;
{
	NSArray *certificates = [DDKeychain KeychainAccessCertificatesList];

	if([certificates count])
	{	
		[[SFChooseIdentityPanel sharedChooseIdentityPanel] setAlternateButtonTitle:NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil)];
		NSInteger clickedButton = [[SFChooseIdentityPanel sharedChooseIdentityPanel] runModalForIdentities:certificates message:NSLocalizedStringFromTableInBundle( @"Choose a certificate from the following list.", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil)];
		
		if(clickedButton==NSOKButton)
		{
			SecIdentityRef identity = [[SFChooseIdentityPanel sharedChooseIdentityPanel] identity];
			if(identity)
			{
				[DDKeychain KeychainAccessSetPreferredIdentity:identity forName:TLS_KEYCHAIN_IDENTITY_NAME_SERVER keyUse:CSSM_KEYUSE_ANY];
				[self getTLSCertificate];
			}
		}
		else if(clickedButton==NSCancelButton)
			return;
	}
	else
	{
		NSInteger clickedButton = NSRunCriticalAlertPanel(NSLocalizedStringFromTableInBundle(@"No Valid Certificate", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"Your Keychain does not contain any valid certificate.", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"Help", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil), NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil), nil);
		
		if(clickedButton==NSOKButton)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://osirix.svn.sourceforge.net/viewvc/osirix/Documentation/Security/index.html"]];
		}
		
		return;
	}
}

- (IBAction)viewTLSCertificate:(id)sender;
{
	[DDKeychain openCertificatePanelForLabel:TLS_KEYCHAIN_IDENTITY_NAME_SERVER];
}

- (void)getTLSCertificate;
{	
	NSString *name = [DDKeychain certificateNameForLabel:TLS_KEYCHAIN_IDENTITY_NAME_SERVER];
	NSImage *icon = [DDKeychain certificateIconForLabel:TLS_KEYCHAIN_IDENTITY_NAME_SERVER];
	
	if(!name)
	{
		name = NSLocalizedStringFromTableInBundle(@"No certificate selected.", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil);	
		[TLSCertificateButton setHidden:YES];
		[TLSChooseCertificateButton setTitle:NSLocalizedStringFromTableInBundle(@"Choose", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil)];
	}
	else
	{
		[TLSCertificateButton setHidden:NO];
		[TLSCertificateButton setImage:icon];
		[TLSChooseCertificateButton setTitle:NSLocalizedStringFromTableInBundle(@"Change", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil)];
	}
	
	self.TLSAuthenticationCertificate = name;
}

- (IBAction)useSameAETitleForTLSListener:(id)sender;
{
	NSString *aet;
	if([sender state] == NSOnState)
	{
		aet = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
		self.TLSStoreSCPAETITLE = aet;
		[self updateTLSStoreSCPAETITLEIsDefaultAETButton];
	}
}

- (IBAction)activateDICOMTLSListenerAction:(id)sender;
{
	[self updateTLSStoreSCPAETITLEIsDefaultAETButton];
}

- (void)updateTLSStoreSCPAETITLEIsDefaultAETButton;
{
	// default state
	[TLSStoreSCPAETITLEIsDefaultAETButton setEnabled:NO];
	[TLSStoreSCPAETITLEIsDefaultAETButton setState:NSOffState];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCP"]
		&& [[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCPTLS"]
		&& ![[TLSAETitleTextField stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"]])
	{
		[TLSStoreSCPAETITLEIsDefaultAETButton setEnabled:YES];
		NSInteger state = ([[NSUserDefaults standardUserDefaults] boolForKey:@"TLSStoreSCPAETITLEIsDefaultAET"]) ? NSOnState : NSOffState;
		[TLSStoreSCPAETITLEIsDefaultAETButton setState:state];
	}	
}

#pragma mark NSControl Delegate Methods

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField *textField = [aNotification object];
	if (textField == TLSPortTextField)
	{
		NSString *submittedPortString = [textField stringValue];
		NSString *portString = [[NSUserDefaults standardUserDefaults] objectForKey:@"AEPORT"];
		int submittedPort = [submittedPortString intValue];
		int port = [portString intValue];
		
		if(submittedPort == port)
		{		
			int newPort = submittedPort;
			if(submittedPort+1<131072) newPort = submittedPort+1;
			else if(submittedPort-1>1) newPort = submittedPort-1;
			
			NSString *newStr = [NSString stringWithFormat:@"%d", newPort];
			
			[textField setStringValue:newStr];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:newPort] forKey:@"TLSStoreSCPAEPORT"];
			
			NSString *msg = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle( @"The port %d is already use by the standard DICOM Listener. The port %d was automatically chosen instead.", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil), submittedPort, newPort];
			NSRunAlertPanel(NSLocalizedStringFromTableInBundle(@"Port already in use", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil),  msg, NSLocalizedStringFromTableInBundle(@"OK", nil, [NSBundle bundleForClass: [OSIListenerPreferencePanePref class]], nil), nil, nil);
		}
	}
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSTextField *textField = [aNotification object];
	if (textField == TLSAETitleTextField)
	{
		[self updateTLSStoreSCPAETITLEIsDefaultAETButton];
	}
}

@end
