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
#import "DefaultsOsiriX.h"
#import "BrowserController.h"
#import "DDKeychain.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>

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

@implementation OSIListenerPreferencePanePref

@synthesize TLSAuthenticationCertificate;
@synthesize TLSSupportedCipherSuite;
@synthesize TLSCertificateVerification;
@synthesize TLSUseDHParameterFileURL;
@synthesize TLSDHParameterFileURL;
@synthesize TLSUseSameAETITLE;
@synthesize TLSStoreSCPAETITLE;

- (NSManagedObjectContext*) managedObjectContext
{
	return [[BrowserController currentBrowser] userManagedObjectContext];
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
	[self checkView: [self mainView] :val];

//	[characterSetPopup setEnabled: val];
//	[addServerDICOM setEnabled: val];
//	[addServerSharing setEnabled: val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
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

//-(IBAction) setExtraStoreSCP:(id) sender
//{
//	[[NSUserDefaults standardUserDefaults] setObject:[extrastorescp stringValue] forKey:@"STORESCPEXTRA"];
//}

-(IBAction) setCheckInterval:(id) sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[checkIntervalField intValue] forKey:@"LISTENERCHECKINTERVAL"];
}

-(IBAction) helpstorescp:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"http://support.dcmtk.org/docs/storescp.html"]];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if( [defaults integerForKey:@"DICOMTimeout"] < 1)
		[defaults setObject:@"1" forKey:@"DICOMTimeout"];
	
	if( [defaults integerForKey:@"DICOMTimeout"] > 480)
		[defaults setObject:@"480" forKey:@"DICOMTimeout"];
	
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
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


	//setup GUI
	
//	NSString *ip = [NSString stringWithCString:GetPrivateIP()];
	NSString *ip = [[self IPv4Address] componentsJoinedByString:@", "];
	char hostname[ _POSIX_HOST_NAME_MAX+1];
	gethostname(hostname, _POSIX_HOST_NAME_MAX);
	NSString *name = [NSString stringWithUTF8String: hostname];
	
	[ipField setStringValue: ip];
	[nameField setStringValue: name];
	
	[generateLogsButton setState:[defaults boolForKey:@"NETWORKLOGS"]];
	[listenerOnOffButton setState:[defaults boolForKey:@"STORESCP"]];
	
	[singleProcessButton setState:[defaults boolForKey:@"SINGLEPROCESS"]];
	
	[decompressButton setState:[defaults boolForKey:@"DECOMPRESSDICOMLISTENER"]];
	[compressButton setState:[defaults boolForKey:@"COMPRESSDICOMLISTENER"]];
	
//	[useStoreSCPModeMatrix selectCellWithTag:[defaults boolForKey:@"USESTORESCP"]];
//	
//	[defaults boolForKey:@"USESTORESCP"] ? 
//	[transferSyntaxBox setHidden:NO] : [transferSyntaxBox setHidden:YES];
//	int index = 7;
//	if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+x="]) //local byte order
//		index = 0;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xe"]) // explicit litle
//		index = 1;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xb"]) // explicit Big
//		index = 2;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xs"]) // jpeg lossless
//		index = 3;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xy"]) // jpeg lossy 8
//		index = 4;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xx"]) //jpeg lossy 12
//		index = 5;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xr"]) // rle
//		index = 6;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xi"]) // implicit
//		index = 7;
//	
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xv"]) // jpeg 2000 lossless
//		index = 8;
//	else if ([[defaults stringForKey:@"AETransferSyntax"] isEqualToString:@"+xw"]) // jpeg 2000 lossy
//		index = 9;
//	
//	[transferSyntaxModeMatrix selectCellWithTag:index];

	[deleteFileModeMatrix selectCellWithTag:[defaults boolForKey:@"DELETEFILELISTENER"]];
	
	[listenerOnOffAnonymize setState:[defaults boolForKey:@"ANONYMIZELISTENER"]];
	
	[logDurationPopup selectItemWithTag: [defaults integerForKey:@"LOGCLEANINGDAYS"]];
	
	[checkIntervalField setIntValue: [defaults integerForKey:@"LISTENERCHECKINTERVAL"]];
	
	[self getTLSCertificate];
}

- (IBAction)setLogDuration:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[[logDurationPopup selectedItem] tag]  forKey:@"LOGCLEANINGDAYS"];
}

- (IBAction)setCompress:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"COMPRESSDICOMLISTENER"];
}
- (IBAction)setDecompress:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"DECOMPRESSDICOMLISTENER"];
}
- (IBAction)setSingleProcess:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"SINGLEPROCESS"];
}
- (IBAction)setDeleteFileMode:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey:@"DELETEFILELISTENER"];
}
- (IBAction)setListenerOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"STORESCP"];
}
- (IBAction)setGenerateLogs:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"NETWORKLOGS"];
}
- (IBAction)setAnonymizeListenerOnOff:(id)sender{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"ANONYMIZELISTENER"];
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

- (IBAction) webServerSettings: (id) sender
{
	[NSApp beginSheet: webServerSettingsWindow modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];

	[NSApp runModalForWindow: webServerSettingsWindow];
	
	[webServerSettingsWindow makeFirstResponder: nil];
	
    [NSApp endSheet: webServerSettingsWindow];
	
    [webServerSettingsWindow orderOut: self];
	
	[[BrowserController currentBrowser] saveUserDatabase];
}

#pragma mark TLS

- (IBAction)editTLS:(id)sender;
{
	NSArray *selectedCipherSuites = [[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPCipherSuites"];
	
	if ([selectedCipherSuites count])
		self.TLSSupportedCipherSuite = selectedCipherSuites;
	else
		self.TLSSupportedCipherSuite = [DICOMTLS defaultCipherSuites];

	self.TLSUseDHParameterFileURL = [[[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPUseDHParameterFileURL"] boolValue];
	NSString *dhParameterFileURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPDHParameterFileURL"];
	if(!dhParameterFileURL)
		dhParameterFileURL = NSHomeDirectory();
	self.TLSDHParameterFileURL = [NSURL fileURLWithPath:dhParameterFileURL];
	
	if([[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPCertificateVerification"])
		self.TLSCertificateVerification = [[[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPCertificateVerification"] intValue];
	else
		self.TLSCertificateVerification = IgnorePeerCertificate;
	
	self.TLSUseSameAETITLE = [[[NSUserDefaults standardUserDefaults] valueForKey:@"TLSUseSameAETITLE"] boolValue];
	self.TLSStoreSCPAETITLE = [[NSUserDefaults standardUserDefaults] valueForKey:@"TLSStoreSCPAETITLE"];
	
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
		[[NSUserDefaults standardUserDefaults] setObject:self.TLSSupportedCipherSuite forKey:@"TLSStoreSCPCipherSuites"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.TLSUseDHParameterFileURL] forKey:@"TLSStoreSCPUseDHParameterFileURL"];
		[[NSUserDefaults standardUserDefaults] setObject:[self.TLSDHParameterFileURL path] forKey:@"TLSStoreSCPDHParameterFileURL"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:self.TLSCertificateVerification] forKey:@"TLSStoreSCPCertificateVerification"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.TLSUseSameAETITLE] forKey:@"TLSUseSameAETITLE"];
		[[NSUserDefaults standardUserDefaults] setObject:self.TLSStoreSCPAETITLE forKey:@"TLSStoreSCPAETITLE"];
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

- (IBAction)chooseTLSCertificate:(id)sender;
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

- (IBAction)useSameAETitleForTLSListener:(id)sender;
{
	NSString *aet;
	if([sender state] == NSOnState)
	{
		aet = [[NSUserDefaults standardUserDefaults] objectForKey:@"AETITLE"];
	}
	else
	{
		aet = @"";
	}
	self.TLSStoreSCPAETITLE = aet;
}

#pragma mark NSControl Delegate Methods

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	NSTextField *textField = [aNotification object];

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

@end
