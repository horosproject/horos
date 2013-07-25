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
//#import "DDKeychain.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <OsiriXAPI/WebPortal.h>
#import <OsiriXAPI/WebPortalDatabase.h>
#import "NSAppleScript+N2.h"

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

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIListenerPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}

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
    {
        [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/OsiriXTables.pdf" error:nil];
        [[NSFileManager defaultManager] copyItemAtPath: [[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"] toPath: @"/tmp/OsiriXTables.pdf" error: nil];
		[[NSWorkspace sharedWorkspace] openFile: @"/tmp/OsiriXTables.pdf"];
	}
    
	if( [sender tag] == 1)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];
}

- (IBAction) openKeyChainAccess:(id) sender
{
	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.keychainaccess"];
	
	[[NSWorkspace sharedWorkspace] launchApplication: path];
}

-(IBAction)editAddresses:(id)sender {
    NSAppleScript* as = [[[NSAppleScript alloc] initWithSource:
                          @"tell application \"System Preferences\"\n"
                          @"activate\n"
                          @"set current pane to pane \"com.apple.preference.network\"\n"
                          @"end tell\n"] autorelease];
    [as runWithArguments:nil error:NULL];
}

-(IBAction)editHostname:(id)sender {
    NSAppleScript* as = [[[NSAppleScript alloc] initWithSource:
                          @"tell application \"System Preferences\"\n"
                          @"activate\n"
                          @"set current pane to pane \"com.apple.preferences.sharing\"\n"
                          @"end tell\n"] autorelease];
    [as runWithArguments:nil error:NULL];
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
		[[SFChooseIdentityPanel sharedChooseIdentityPanel] setAlternateButtonTitle:NSLocalizedString(@"Cancel", nil)];
		NSInteger clickedButton = [[SFChooseIdentityPanel sharedChooseIdentityPanel] runModalForIdentities:certificates message:NSLocalizedString( @"Choose a certificate from the following list.", nil)];
		
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
		NSInteger clickedButton = NSRunCriticalAlertPanel(NSLocalizedString(@"No Valid Certificate", nil), NSLocalizedString(@"Your Keychain does not contain any valid certificate.", nil), NSLocalizedString(@"Help", nil), NSLocalizedString(@"Cancel", nil), nil);
		
		if(clickedButton==NSOKButton)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.osirix-viewer.com/Documentation/Guides/Security/index.html"]];
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
		name = NSLocalizedString(@"No certificate selected.", nil);	
		[TLSCertificateButton setHidden:YES];
		[TLSChooseCertificateButton setTitle:NSLocalizedString(@"Choose", nil)];
	}
	else
	{
		[TLSCertificateButton setHidden:NO];
		[TLSCertificateButton setImage:icon];
		[TLSChooseCertificateButton setTitle:NSLocalizedString(@"Change", nil)];
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
			
			NSString *msg = [NSString stringWithFormat:NSLocalizedString( @"The port %d is already use by the standard DICOM Listener. The port %d was automatically chosen instead.", nil), submittedPort, newPort];
			NSRunAlertPanel(NSLocalizedString(@"Port already in use", nil),  msg, NSLocalizedString(@"OK", nil), nil, nil);
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
