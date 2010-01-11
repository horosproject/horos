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

#import "OSILocationsPreferencePanePref.h"
#include "SimplePing.h"

#import "OpenGLScreenReader.h"
#import "DDKeychain.h"

/************ Transfer Syntaxes *******************
	@"Explicit Little Endian"
	@"JPEG 2000 Lossless"
	@"JPEG 2000 Lossy 10:1"
	@"JPEG 2000 Lossy 20:1"
	@"JPEG 2000 Lossy 50:1"
	@"JPEG Lossless"
	@"JPEG High Quality (9)"	
	@"JPEG Medium High Quality (8)"	
	@"JPEG Medium Quality (7)"
	@"Implicit"
	@"RLE"
*************************************************/

@implementation OSILocationsPreferencePanePref

@synthesize WADOPort, WADOTransferSyntax, WADOUrl;

@synthesize TLSEnabled, TLSAuthenticated, TLSUseDHParameterFileURL;
@synthesize TLSDHParameterFileURL;
@synthesize TLSSupportedCipherSuite;
@synthesize TLSCertificateVerification;
@synthesize TLSAuthenticationCertificate;

- (void) checkUniqueAETitle
{
	int i, x;
	
	NSArray *serverList = [dicomNodes arrangedObjects];
	
	for( x = 0; x < [serverList count]; x++)
	{
		int value = [[[serverList objectAtIndex: x] valueForKey:@"Port"] intValue];
		if( value < 1) value = 1;
		if( value > 131072) value = 131072;
		[[serverList objectAtIndex: x] setValue: [NSNumber numberWithInt: value] forKey: @"Port"];		
		[[serverList objectAtIndex: x] setValue: [[serverList objectAtIndex: x] valueForKey:@"AETitle"] forKey:@"AETitle"];
		
		NSString *currentAETitle = [[serverList objectAtIndex: x] valueForKey: @"AETitle"];
		
		for( i = 0; i < [serverList count]; i++)
		{
			if( i != x)
			{
				if( [currentAETitle isEqualToString: [[serverList objectAtIndex: i] valueForKey: @"AETitle"]])
				{
					NSRunInformationalAlertPanel(NSLocalizedString(@"Same AETitle", 0L), [NSString stringWithFormat: NSLocalizedString(@"This AETitle is not unique: %@. AETitles should be unique, otherwise Q&R (C-Move SCP/SCU) can fail.", 0L), currentAETitle], NSLocalizedString(@"OK",nil), nil, nil);
					
					i = [serverList count];
					x = [serverList count];
				}
			}
		}
	}
}

- (int) echoAddress: (NSString*) address port:(int) port AET:(NSString*) aet
{
	NSTask* theTask = [[[NSTask alloc]init]autorelease];
	
	[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/echoscu"]];

	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/echoscu"]];

	NSArray *args = [NSArray arrayWithObjects: address, [NSString stringWithFormat:@"%d", port], @"-aet", [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"-aec", aet, @"-to", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-ta", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-td", [[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"], @"-d", nil];
	
	NSLog( @"%@", [args description]);
	
	[theTask setArguments:args];
	[theTask launch];
	[theTask waitUntilExit];
	
	return [theTask terminationStatus];
}

+ (BOOL) echoServer:(NSDictionary*)serverParameters
{
	NSString *address = [serverParameters objectForKey:@"Address"];
	NSNumber *port = [serverParameters objectForKey:@"Port"];
	NSString *aet = [serverParameters objectForKey:@"AETitle"];
	
	NSTask* theTask = [[[NSTask alloc] init] autorelease];
	
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/echoscu"]];
	
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/echoscu"]];
		
	NSMutableArray *args = [NSMutableArray array];
	[args addObject:address];
	[args addObject:[NSString stringWithFormat:@"%d", [port intValue]]];
	[args addObject:@"-aet"]; // set my calling AE title
	[args addObject:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"]];
	[args addObject:@"-aec"]; // set called AE title of peer
	[args addObject:aet];
	[args addObject:@"-to"]; // timeout for connection requests
	[args addObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"]];
	[args addObject:@"-ta"]; // timeout for ACSE messages
	[args addObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"]];
	[args addObject:@"-td"]; // timeout for DIMSE messages
	[args addObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"DICOMTimeout"]];
	
	BOOL needsUnlockFiles = NO;
	BOOL needsUnlockDir = NO;
	
	if([[serverParameters objectForKey:@"TLSEnabled"] boolValue])
	{
		// TLS support. Options listed here http://support.dcmtk.org/docs/echoscu.html
		
		if([[serverParameters objectForKey:@"TLSAuthenticated"] boolValue])
		{
			[args addObject:@"--enable-tls"]; // use authenticated secure TLS connection

			[DDKeychain DICOMTLSGenerateCertificateAndKeyForServerAddress:address port: [port intValue] AETitle:aet]; // export certificate/key from the Keychain to the disk
			[DDKeychain lockFile:[DDKeychain DICOMTLSKeyPathForServerAddress:address port:[port intValue] AETitle:aet]];
			[DDKeychain lockFile:[DDKeychain DICOMTLSCertificatePathForServerAddress:address port:[port intValue] AETitle:aet]];
			needsUnlockFiles = YES;
			[args addObject:[DDKeychain DICOMTLSKeyPathForServerAddress:address port:[port intValue] AETitle:aet]]; // [p]rivate key file
			[args addObject:[DDKeychain DICOMTLSCertificatePathForServerAddress:address port:[port intValue] AETitle:aet]]; // [c]ertificate file: string
			
			[args addObject:@"--use-passwd"];
			[args addObject:TLS_PRIVATE_KEY_PASSWORD];
		}
		else
			[args addObject:@"--anonymous-tls"]; // use secure TLS connection without certificate
		
		// key and certificate file format options:
		[args addObject:@"--pem-keys"];
		
		//ciphersuite options:
		for (NSDictionary *suite in [serverParameters objectForKey:@"TLSCipherSuites"])
		{
			if ([[suite objectForKey:@"Supported"] boolValue])
			{
				[args addObject:@"--cipher"]; // add ciphersuite to list of negotiated suites
				[args addObject:[suite objectForKey:@"Cipher"]];
			}
		}

		if([[serverParameters objectForKey:@"TLSUseDHParameterFileURL"] boolValue])
		{
			[args addObject:@"--dhparam"]; // read DH parameters for DH/DSS ciphersuites
			[args addObject:[serverParameters objectForKey:@"TLSDHParameterFileURL"]];
		}

		// peer authentication options:
		TLSCertificateVerificationType verification = [[serverParameters objectForKey:@"TLSCertificateVerification"] intValue];
		if(verification==RequirePeerCertificate)
			[args addObject:@"--require-peer-cert"]; //verify peer certificate, fail if absent (default)
		else if(verification==VerifyPeerCertificate)
			[args addObject:@"--verify-peer-cert"]; //verify peer certificate if present
		else //IgnorePeerCertificate
			[args addObject:@"--ignore-peer-cert"]; //don't verify peer certificate	
		
		// certification authority options:
		if(verification==RequirePeerCertificate || verification==VerifyPeerCertificate)
		{
			[DDKeychain KeychainAccessExportTrustedCertificatesToDirectory:TLS_TRUSTED_CERTIFICATES_DIR];
			[DDKeychain lockFile:TLS_TRUSTED_CERTIFICATES_DIR];
			needsUnlockDir = YES;
			NSArray *trustedCertificates = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TLS_TRUSTED_CERTIFICATES_DIR error:nil];
		
			//[args addObject:@"--add-cert-dir"]; // add certificates in d to list of certificates  .... needs to use OpenSSL & rename files (see http://forum.dicom-cd.de/viewtopic.php?p=3237&sid=bd17bd76876a8fd9e7fdf841b90cf639 )
			for (NSString *cert in trustedCertificates)
			{
				[args addObject:@"--add-cert-file"];
				[args addObject:[TLS_TRUSTED_CERTIFICATES_DIR stringByAppendingPathComponent:cert]];
			}
		}
		
		// pseudo random generator options.
		// see http://www.mevis-research.de/~meyer/dcmtk/docs_352/dcmtls/randseed.txt
		[DDKeychain generatePseudoRandomFileToPath:TLS_SEED_FILE];
		[args addObject:@"--seed"]; // seed random generator with contents of f
		[args addObject:TLS_SEED_FILE];		
	}
		
	[theTask setArguments:args];
	[theTask launch];
	[theTask waitUntilExit];

	//[[NSFileManager defaultManager] removeFileAtPath:[DDKeychain DICOMTLSKeyPathForServerAddress:address port:[port intValue] AETitle:aet] handler:nil];
	//[[NSFileManager defaultManager] removeFileAtPath:[DDKeychain DICOMTLSCertificatePathForServerAddress:address port:[port intValue] AETitle:aet] handler:nil];
	if(needsUnlockFiles)
	{
		[DDKeychain unlockFile:[DDKeychain DICOMTLSKeyPathForServerAddress:address port:[port intValue] AETitle:aet]];
		[DDKeychain unlockFile:[DDKeychain DICOMTLSCertificatePathForServerAddress:address port:[port intValue] AETitle:aet]];
	}
	if(needsUnlockDir)[DDKeychain unlockFile:TLS_TRUSTED_CERTIFICATES_DIR];
	
	if( [theTask terminationStatus] == 0) return YES;
	else return NO;
}

- (void) enableControls: (BOOL) val
{
	[characterSetPopup setEnabled: val];
	[addServerDICOM setEnabled: val];
	[addServerSharing setEnabled: val];
	[verifyPing setEnabled: val];
	[searchDICOMBonjourNodes setEnabled: val];
	[addLocalPath setEnabled: val];
	[loadNodes setEnabled: val];
	
	[[NSUserDefaults standardUserDefaults] setBool: val forKey: @"preferencesModificationsEnabled"];
	
	[[NSUserDefaults standardUserDefaults] setBool: [[NSUserDefaults standardUserDefaults] boolForKey:@"syncDICOMNodes"] forKey: @"syncDICOMNodes"];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.locations"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];

	stringEncoding = [[defaults stringForKey:@"STRINGENCODING"] retain];
	int tag = 0;
	 if( [stringEncoding isEqualToString: @"ISO_IR 192"])	//UTF8
		tag = 0;
	else if ( [stringEncoding isEqualToString: @"ISO_IR 100"])
		tag = 1;
	else if( [stringEncoding isEqualToString: @"ISO_IR 101"])
		tag =  2;
	else if( [stringEncoding isEqualToString: @"ISO_IR 109"])	
		tag =  3;
	else if( [stringEncoding isEqualToString: @"ISO_IR 110"])
		tag =  4;
	else if( [stringEncoding isEqualToString: @"ISO_IR 127"])	
		tag =  5 ;
	else if( [stringEncoding isEqualToString: @"ISO_IR 144"])		
		tag =  6;
	else if( [stringEncoding isEqualToString: @"ISO_IR 126"])	
		tag =  7;
	else if( [stringEncoding isEqualToString: @"ISO_IR 138"])		
		tag =  8 ;
	else if( [stringEncoding isEqualToString: @"GB18030"])	
		tag =  9;
	else if( [stringEncoding isEqualToString: @"ISO 2022 IR 149"])
		tag =  10;
	else if( [stringEncoding isEqualToString: @"ISO 2022 IR 13"])	
		tag =  11;
	else if( [stringEncoding isEqualToString: @"ISO_IR 13"])	
		tag =  12 ;
	else if( [stringEncoding isEqualToString: @"ISO 2022 IR 87"])	
		tag =  13 ;
	else if( [stringEncoding isEqualToString: @"ISO_IR 1166"])
		tag =  14 ;
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject: @"ISO_IR 100" forKey:@"STRINGENCODING"];
		tag = 1;
	}
	
	[characterSetPopup selectItemAtIndex:-1];
	[characterSetPopup selectItemAtIndex:tag];
	
	[self checkUniqueAETitle];
	
	[self resetTest];
	
	int i;
	for( i = 0 ; i < [[dicomNodes arrangedObjects] count]; i++)
	{
		NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex: i];
		if( [aServer valueForKey:@"Send"] == 0L)
			[aServer setValue:[NSNumber numberWithBool:YES] forKey:@"Send"];
	}
	
	[self getTLSCertificate];
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
	
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
}

- (void)dealloc
{
	NSLog(@"dealloc OSILocationsPreferencePanePref");
	
	[WADOUrl release];
	[stringEncoding release];
	
	[TLSDHParameterFileURL release];
	[TLSSupportedCipherSuite release];
	[TLSAuthenticationCertificate release];
	
	[super dealloc];
}

- (IBAction) newServer:(id)sender
{
    NSMutableDictionary *aServer = [NSMutableDictionary dictionary];
    [aServer setObject:@"127.0.0.1" forKey:@"Address"];
    [aServer setObject:@"PACS" forKey:@"AETitle"];
    [aServer setObject:@"11112" forKey:@"Port"];
	[aServer setObject:[NSNumber numberWithBool:YES] forKey:@"QR"];
	[aServer setObject:[NSNumber numberWithBool:YES] forKey:@"Send"];
    [aServer setObject:@"Description" forKey:@"Description"];
	[aServer setObject:[NSNumber numberWithInt:0] forKey:@"TransferSyntax"];
	[aServer setObject: [NSNumber numberWithInt: 0] forKey: @"retrieveMode"]; // CMove
	[aServer setObject: [NSNumber numberWithInt: 8080] forKey: @"WADOPort"];
	[aServer setObject: [NSNumber numberWithInt: -1] forKey: @"WADOTransferSyntax"]; // useOrig=true
	[aServer setObject: @"wado" forKey: @"WADOUrl"];
	
	[aServer setObject:[NSNumber numberWithBool:NO] forKey:@"TLSEnabled"];
	[aServer setObject:[NSNumber numberWithBool:NO] forKey:@"TLSAuthenticated"];
	
	[dicomNodes addObject:aServer];
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	
	[[dicomNodes tableView] scrollRowToVisible: [[dicomNodes tableView] selectedRow]];
	
	[self resetTest];
}

- (IBAction) osirixNewServer:(id)sender
{
    NSMutableDictionary *aServer = [NSMutableDictionary dictionary];
    [aServer setObject:@"osirix.hcuge.ch" forKey:@"Address"];
    [aServer setObject:@"OsiriX PACS Server" forKey:@"Description"];
    
    [osiriXServers addObject: aServer];
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	
	[[osiriXServers tableView] scrollRowToVisible: [[osiriXServers tableView] selectedRow]];
	
	[[[self mainView] window] makeKeyAndOrderFront: self];
}

- (IBAction) cancel:(id)sender
{
	[NSApp abortModal];
}

- (IBAction) ok:(id)sender
{
	[NSApp stopModal];
}

- (IBAction) editWADO: (id) sender
{
	NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex: [[dicomNodes tableView] selectedRow]];
	
	self.WADOPort = [[aServer valueForKey: @"WADOPort"] intValue];
	self.WADOUrl = [aServer valueForKey: @"WADOUrl"];
	self.WADOTransferSyntax = [[aServer valueForKey: @"WADOTransferSyntax"] intValue];
	
	[NSApp beginSheet: WADOSettings
		modalForWindow: [[self mainView] window]
		modalDelegate: nil
		didEndSelector: nil
		contextInfo: nil];
	
	int result = [NSApp runModalForWindow: WADOSettings];
	[WADOSettings makeFirstResponder: nil];
	
	[NSApp endSheet: WADOSettings];
	[WADOSettings orderOut: self];
	
	if( result == NSRunStoppedResponse)
	{
		[aServer setObject: [NSNumber numberWithInt: 2] forKey: @"retrieveMode"]; // WADORetrieveMode
		[aServer setObject: [NSNumber numberWithInt: WADOPort] forKey: @"WADOPort"];
		[aServer setObject: [NSNumber numberWithInt: WADOTransferSyntax] forKey: @"WADOTransferSyntax"];
		[aServer setObject: WADOUrl forKey: @"WADOUrl"];
		
		[[NSUserDefaults standardUserDefaults] setObject: [dicomNodes arrangedObjects] forKey: @"SERVERS"];
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	}
}

- (void) resetTest
{
	int i;
	
	for( i = 0 ; i < [[dicomNodes arrangedObjects] count]; i++)
	{
		NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex: i];
		[aServer removeObjectForKey: @"test"];
	}
}

- (IBAction) OsiriXDBsaveAs:(id) sender;
{
	NSSavePanel		*sPanel		= [NSSavePanel savePanel];

	[sPanel setRequiredFileType:@"plist"];
	
	if ([sPanel runModalForDirectory:0L file:NSLocalizedString(@"OsiriXDB.plist", nil)] == NSFileHandlingPanelOKButton)
	{
		[[osiriXServers arrangedObjects] writeToFile:[sPanel filename] atomically: YES];
	}
}

- (IBAction) refreshNodesOsiriXDB: (id) sender
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncOsiriXDB"])
	{
		NSURL *url = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] valueForKey:@"syncOsiriXDBURL"]];
		
		if( url)
		{
			NSArray	*r = [NSArray arrayWithContentsOfURL: url];
			
			if( r)
			{
				[osiriXServers removeObjects: [osiriXServers arrangedObjects]];
				[osiriXServers addObjects: r];
				
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
			}
			else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"Cannot download data from this URL.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
		}
		else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"This URL is invalid. Check syntax.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

- (IBAction) OsiriXDBloadFrom:(id) sender;
{
	NSOpenPanel		*sPanel		= [NSOpenPanel openPanel];
	
	[self resetTest];
	
	[sPanel setRequiredFileType:@"plist"];
	
	if ([sPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"plist"]] == NSFileHandlingPanelOKButton)
	{
		NSArray	*r = [NSArray arrayWithContentsOfFile: [sPanel filename]];
		
		if( r)
		{
			if( NSRunInformationalAlertPanel(NSLocalizedString(@"Load locations", 0L), NSLocalizedString(@"Should I add or replace this locations list? If you choose 'replace', the current list will be deleted.", 0L), NSLocalizedString(@"Add",nil), NSLocalizedString(@"Replace",nil), nil) == NSAlertDefaultReturn)
			{
				
			}
			else [osiriXServers removeObjects: [osiriXServers arrangedObjects]];
			
			[osiriXServers addObjects: r];
			
			int i, x;
			
			for( i = 0; i < [[osiriXServers arrangedObjects] count]; i++)
			{
				NSDictionary	*server = [[osiriXServers arrangedObjects] objectAtIndex: i];
				
				for( x = 0; x < [[osiriXServers arrangedObjects] count]; x++)
				{
					NSDictionary	*c = [[osiriXServers arrangedObjects] objectAtIndex: x];
					
					if( c != server)
					{
						if( [[server valueForKey:@"Address"] isEqualToString: [c valueForKey:@"Address"]] &&
							[[server valueForKey:@"Description"] isEqualToString: [c valueForKey:@"Description"]])
							{
								[osiriXServers removeObjectAtArrangedObjectIndex: i];
								i--;
								x = [[osiriXServers arrangedObjects] count];
							}
					}
				}
			}
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
		}
	}
}


- (IBAction) saveAs:(id) sender;
{
	NSSavePanel		*sPanel		= [NSSavePanel savePanel];

	[sPanel setRequiredFileType:@"plist"];
	
	[self resetTest];
	
	if ([sPanel runModalForDirectory:0L file:NSLocalizedString(@"DICOMNodes.plist", nil)] == NSFileHandlingPanelOKButton)
	{
		[[dicomNodes arrangedObjects] writeToFile:[sPanel filename] atomically: YES];
	}
}

- (IBAction) refreshNodesListURL: (id) sender
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"syncDICOMNodes"])
	{
		NSURL *url = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] valueForKey:@"syncDICOMNodesURL"]];
		
		if( url)
		{
			NSArray	*r = [NSArray arrayWithContentsOfURL: url];
			
			if( r)
			{
				[dicomNodes removeObjects: [dicomNodes arrangedObjects]];
				[dicomNodes addObjects: r];
				
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
			}
			else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"Cannot download data from this URL.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
		}
		else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"This URL is invalid. Check syntax.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

- (IBAction) loadFrom:(id) sender;
{
	NSOpenPanel		*sPanel		= [NSOpenPanel openPanel];
	
	[self resetTest];
	
	[sPanel setRequiredFileType:@"plist"];
	
	if ([sPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"plist"]] == NSFileHandlingPanelOKButton)
	{
		NSArray	*r = [NSArray arrayWithContentsOfFile: [sPanel filename]];
		
		if( r)
		{
			if( NSRunInformationalAlertPanel(NSLocalizedString(@"Load locations", 0L), NSLocalizedString(@"Should I add or replace this locations list? If you choose 'replace', the current list will be deleted.", 0L), NSLocalizedString(@"Add",nil), NSLocalizedString(@"Replace",nil), nil) == NSAlertDefaultReturn)
			{
				
			}
			else [dicomNodes removeObjects: [dicomNodes arrangedObjects]];
			
			[dicomNodes addObjects: r];
			
			int i, x;
			
			for( i = 0; i < [[dicomNodes arrangedObjects] count]; i++)
			{
				NSDictionary	*server = [[dicomNodes arrangedObjects] objectAtIndex: i];
				
				for( x = 0; x < [[dicomNodes arrangedObjects] count]; x++)
				{
					NSDictionary	*c = [[dicomNodes arrangedObjects] objectAtIndex: x];
					
					if( c != server)
					{
						if( [[server valueForKey:@"AETitle"] isEqualToString: [c valueForKey:@"AETitle"]] &&
							[[server valueForKey:@"Address"] isEqualToString: [c valueForKey:@"Address"]] &&
							[[server valueForKey:@"Port"] intValue] == [[c valueForKey:@"Port"] intValue])
							{
								[dicomNodes removeObjectAtArrangedObjectIndex: i];
								i--;
								x = [[dicomNodes arrangedObjects] count];
							}
					}
				}
			}
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
		}
	}
	
	[self resetTest];
}

- (IBAction) test:(id) sender
{
	int i;
	int status;
	int selectedRow = [[dicomNodes tableView] selectedRow];
	
	[progress startAnimation: self];
	
	NSArray		*serverList = [dicomNodes arrangedObjects];
	
	for( i = 0 ; i < [serverList count]; i++)
	{
		NSMutableDictionary *aServer = [serverList objectAtIndex: i];
		
		[[dicomNodes tableView] selectRow: i byExtendingSelection: NO];
		[[dicomNodes tableView] display];
		
		int numberPacketsReceived = 0;
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"Ping"] == NO || (SimplePing( [[aServer objectForKey:@"Address"] UTF8String], 1, [[NSUserDefaults standardUserDefaults] integerForKey:@"DICOMTimeout"], 1,  &numberPacketsReceived) == 0 && numberPacketsReceived > 0))
		{
			//if( [self echoAddress:[aServer objectForKey:@"Address"] port:[[aServer objectForKey:@"Port"] intValue] AET:[aServer objectForKey:@"AETitle"]] == 0) status = 0;
			
			if ([OSILocationsPreferencePanePref echoServer:aServer])
				status = 0;
			else
				status = -1;
		}
		else status = -2;
		
		[aServer setObject:[NSNumber numberWithInt: status] forKey:@"test"];
	}
	
	[progress stopAnimation: self];
	
	[[dicomNodes tableView] selectRow: selectedRow byExtendingSelection: NO];
	[[dicomNodes tableView] display];
}


- (IBAction) setStringEncoding:(id)sender
{
	NSString *encoding;

	switch ([[sender selectedItem] tag]){
		case 0: encoding = @"ISO_IR 192";
			break;
		case 1: encoding = @"ISO_IR 100";
			break;
		case 2: encoding = @"ISO_IR 101";
			break;
		case 3: encoding = @"ISO_IR 109";
			break;
		case 4: encoding = @"ISO_IR 110";
			break;
		case 5: encoding = @"ISO_IR 127";
			break;
		case 6: encoding = @"ISO_IR 144";
			break;
		case 7: encoding = @"ISO_IR 126";
			break;
		case 8: encoding = @"ISO_IR 138";
			break;
		case 9: encoding = @"GB18030";
			break;
		
		case 10: encoding = @"ISO 2022 IR 149";
			break;
		case 11: encoding = @"ISO 2022 IR 13";
			break;
		case 12: encoding = @"ISO_IR 13";
			break;
		case 13: encoding = @"ISO 2022 IR 87";
			break;
		case 14: encoding = @"ISO_IR 1166";
			break;
		default: encoding = @"ISO_IR 100";
			break;
	}
	[[NSUserDefaults standardUserDefaults] setObject:encoding forKey:@"STRINGENCODING"];
	[stringEncoding release];
	stringEncoding = [encoding retain];
}

- (IBAction) addPath:(id) sender
{
	NSOpenPanel		*oPanel		= [NSOpenPanel openPanel];

    [oPanel setCanChooseFiles:YES];
    [oPanel setCanChooseDirectories:YES];

	if ([oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"sql"]] == NSFileHandlingPanelOKButton)
	{
		NSString	*location = [oPanel filename];
		
		if( [[location lastPathComponent] isEqualToString:@"OsiriX Data"])
		{
			location = [location stringByDeletingLastPathComponent];
		}

		if( [[location lastPathComponent] isEqualToString:@"DATABASE"] && [[[location stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"OsiriX Data"])
		{
			location = [[location stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
		}
		
		BOOL isDirectory;
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: location isDirectory: &isDirectory])
		{
			NSDictionary	*dict = nil;
			
			if( isDirectory)
			{
				dict = [NSDictionary dictionaryWithObjectsAndKeys: location, @"Path", [[location lastPathComponent] stringByAppendingString:@" DB"], @"Description", nil];
				
				[localPaths addObject: dict];
			
				[[localPaths tableView] scrollRowToVisible: [[localPaths tableView] selectedRow]];
			
				[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
			}
		}
	}
	
	[[[self mainView] window] makeKeyAndOrderFront: self];
}

#pragma mark DICOM TLS Support

- (IBAction) editTLS: (id) sender
{	
	NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex:[[dicomNodes tableView] selectedRow]];
	
	self.TLSEnabled = [[aServer valueForKey:@"TLSEnabled"] boolValue];
	self.TLSAuthenticated = [[aServer valueForKey:@"TLSAuthenticated"] boolValue];

	[self getTLSCertificate];
	
	// certificates and keys should be chosen from the Keychain, not from files
	// see Wil Shipley's comment and examples http://www.wilshipley.com/blog/2006/10/pimp-my-code-part-12-frozen-in.html

	NSArray *selectedCipherSuites = [aServer valueForKey:@"TLSCipherSuites"];

	if ([selectedCipherSuites count])
		self.TLSSupportedCipherSuite = selectedCipherSuites;
	else
		self.TLSSupportedCipherSuite = [self defaultCipherSuites];

	self.TLSUseDHParameterFileURL = [[aServer valueForKey:@"TLSUseDHParameterFileURL"] boolValue];
	NSString *dhParameterFileURL = [aServer valueForKey:@"TLSDHParameterFileURL"];
	if(!dhParameterFileURL)
		dhParameterFileURL = NSHomeDirectory();
	self.TLSDHParameterFileURL = [NSURL fileURLWithPath:dhParameterFileURL];
	
	if([aServer valueForKey:@"TLSCertificateVerification"])
		self.TLSCertificateVerification = [[aServer valueForKey:@"TLSCertificateVerification"] intValue];
	else
		self.TLSCertificateVerification = IgnorePeerCertificate;
		
	[NSApp beginSheet: TLSSettings
	   modalForWindow: [[self mainView] window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	int result = [NSApp runModalForWindow: TLSSettings];
	[TLSSettings makeFirstResponder: nil];
	
	[NSApp endSheet: TLSSettings];
	[TLSSettings orderOut: self];
	
	if( result == NSRunStoppedResponse)
	{
		[aServer setObject:[NSNumber numberWithBool:self.TLSEnabled] forKey:@"TLSEnabled"];
		
		if (self.TLSEnabled)
		{
			[aServer setObject:[NSNumber numberWithBool: self.TLSAuthenticated] forKey:@"TLSAuthenticated"];
						
			[aServer setObject:self.TLSSupportedCipherSuite forKey:@"TLSCipherSuites"];
			
			[aServer setObject:[NSNumber numberWithBool:self.TLSUseDHParameterFileURL] forKey:@"TLSUseDHParameterFileURL"];
			[aServer setObject:[self.TLSDHParameterFileURL path] forKey:@"TLSDHParameterFileURL"];
			
			[aServer setObject:[NSNumber numberWithInt:self.TLSCertificateVerification] forKey:@"TLSCertificateVerification"];
		}

		[[NSUserDefaults standardUserDefaults] setObject:[dicomNodes arrangedObjects] forKey:@"SERVERS"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"updateServers"];
	}
}

- (NSArray*)availableCipherSuites;
{
	// list taken from "tlslayer.cc"
	NSArray *cipherSuites = [NSArray arrayWithObjects:	@"TLS_RSA_WITH_NULL_MD5",
							 @"TLS_RSA_WITH_NULL_SHA",
							 @"TLS_RSA_EXPORT_WITH_RC4_40_MD5",
							 @"TLS_RSA_WITH_RC4_128_MD5",
							 @"TLS_RSA_WITH_RC4_128_SHA",
							 @"TLS_RSA_EXPORT_WITH_RC2_CBC_40_MD5",
							 @"TLS_RSA_WITH_IDEA_CBC_SHA",
							 @"TLS_RSA_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_RSA_WITH_DES_CBC_SHA",
							 @"TLS_RSA_WITH_3DES_EDE_CBC_SHA",
							 @"TLS_DH_DSS_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_DH_DSS_WITH_DES_CBC_SHA",        
							 @"TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA",   
							 @"TLS_DH_RSA_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_DH_RSA_WITH_DES_CBC_SHA",        
							 @"TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA",   
							 @"TLS_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_DHE_DSS_WITH_DES_CBC_SHA",            
							 @"TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA",       
							 @"TLS_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA",   
							 @"TLS_DHE_RSA_WITH_DES_CBC_SHA",            
							 @"TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA",       
							 @"TLS_DH_anon_EXPORT_WITH_RC4_40_MD5",      
							 @"TLS_DH_anon_WITH_RC4_128_MD5",            
							 @"TLS_DH_anon_EXPORT_WITH_DES40_CBC_SHA",   
							 @"TLS_DH_anon_WITH_DES_CBC_SHA",            
							 @"TLS_DH_anon_WITH_3DES_EDE_CBC_SHA",       
							 @"TLS_RSA_EXPORT1024_WITH_DES_CBC_SHA",     
							 @"TLS_RSA_EXPORT1024_WITH_RC4_56_SHA",      
							 @"TLS_DHE_DSS_EXPORT1024_WITH_DES_CBC_SHA", 
							 @"TLS_DHE_DSS_EXPORT1024_WITH_RC4_56_SHA",  
							 @"TLS_DHE_DSS_WITH_RC4_128_SHA",            
							 //if OPENSSL_VERSION_NUMBER >= 0x0090700fL
							 // cipersuites added in OpenSSL 0.9.7
							 @"TLS_RSA_EXPORT_WITH_RC4_56_MD5",         
							 @"TLS_RSA_EXPORT_WITH_RC2_CBC_56_MD5",     
							 /* AES ciphersuites from RFC3268 */
							 @"TLS_RSA_WITH_AES_128_CBC_SHA",           
							 @"TLS_DH_DSS_WITH_AES_128_CBC_SHA",        
							 @"TLS_DH_RSA_WITH_AES_128_CBC_SHA",        
							 @"TLS_DHE_DSS_WITH_AES_128_CBC_SHA",       
							 @"TLS_DHE_RSA_WITH_AES_128_CBC_SHA",       
							 @"TLS_DH_anon_WITH_AES_128_CBC_SHA",       
							 @"TLS_RSA_WITH_AES_256_CBC_SHA",           
							 @"TLS_DH_DSS_WITH_AES_256_CBC_SHA",        
							 @"TLS_DH_RSA_WITH_AES_256_CBC_SHA",        
							 @"TLS_DHE_DSS_WITH_AES_256_CBC_SHA",       
							 @"TLS_DHE_RSA_WITH_AES_256_CBC_SHA",       
							 @"TLS_DH_anon_WITH_AES_256_CBC_SHA",
							 nil];
	return cipherSuites;
}

- (NSArray*)defaultCipherSuites;
{
	NSArray *availableCipherSuites = [self availableCipherSuites];
	NSMutableArray *cipherSuites = [NSMutableArray arrayWithCapacity:[availableCipherSuites count]];
	
	for (NSString *suite in availableCipherSuites)
	{
		[cipherSuites addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"Supported", suite, @"Cipher", nil]];
	}
	
	return [NSArray arrayWithArray:cipherSuites];
}

- (IBAction)chooseTLSCertificate:(id)sender
{
	NSArray *certificates = [DDKeychain KeychainAccessCertificatesList];
		
	[[SFChooseIdentityPanel sharedChooseIdentityPanel] setAlternateButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")];
	NSInteger clickedButton = [[SFChooseIdentityPanel sharedChooseIdentityPanel] runModalForIdentities:certificates message:NSLocalizedString(@"Choose a certificate from the following list.", @"Choose a certificate from the following list.")];
	
	if(clickedButton==NSOKButton)
	{
		SecIdentityRef identity = [[SFChooseIdentityPanel sharedChooseIdentityPanel] identity];
		if(identity)
		{
			[DDKeychain KeychainAccessSetPreferredIdentity:identity forName:[self DICOMTLSUniqueLabelForSelectedServer] keyUse:CSSM_KEYUSE_ANY];
			[self getTLSCertificate];
		}
	}
	else if(clickedButton==NSCancelButton)
		return;
}

- (IBAction)viewTLSCertificate:(id)sender;
{
	NSString *label = [self DICOMTLSUniqueLabelForSelectedServer];
	[DDKeychain DICOMTLSOpenCertificatePanelForLabel:label];
}

- (void)getTLSCertificate;
{	
	NSString *label = [self DICOMTLSUniqueLabelForSelectedServer];
	NSString *name = [DDKeychain DICOMTLSCertificateNameForLabel:label];
	NSImage *icon = [DDKeychain DICOMTLSCertificateIconForLabel:label];
	
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
			
//	[DDKeychain DICOMTLSGenerateCertificateAndKeyForLabel:label]; // test
}

- (NSString*)DICOMTLSUniqueLabelForSelectedServer;
{
	NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex:[[dicomNodes tableView] selectedRow]];
	return [DDKeychain DICOMTLSUniqueLabelForServerAddress:[aServer valueForKey:@"Address"] port:[NSString stringWithFormat:@"%d",[[aServer valueForKey:@"Port"] intValue]] AETitle:[aServer valueForKey:@"AETitle"]];
}

@end
