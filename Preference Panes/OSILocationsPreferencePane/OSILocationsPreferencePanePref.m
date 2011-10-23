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

//#import "DDKeychain.h"

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

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation OSILocationsPreferencePanePref

@synthesize WADOPort, WADOhttps, WADOTransferSyntax, WADOUrl;

@synthesize TLSEnabled, TLSAuthenticated, TLSUseDHParameterFileURL;
@synthesize TLSDHParameterFileURL;
@synthesize TLSSupportedCipherSuite;
@synthesize TLSCertificateVerification;
@synthesize TLSAuthenticationCertificate;

/*+(void)initialize { // TODO: this should more likely be initialized in OsiriX
	NSLog(@"+[OSILocationsPreferencePanePref initialize]");
	
	NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	// merge our initial values with the existing ones
	NSMutableDictionary* initialValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										  [NSNumber numberWithBool:NO], @"DoNotSearchForBonjourServices",
										  [NSNumber numberWithBool:NO], @"dontAuthorizeAutoRetrieve",
										  [NSMutableArray array], @"localDatabasePaths",
										  [NSMutableArray array], @"OSIRIXSERVERS", // TODO: is this the right place?
										  [NSNumber numberWithBool:NO], @"Ping",
										  [NSNumber numberWithBool:NO], @"restartAutoQueryAndRetrieve",
										  [NSNumber numberWithBool:NO], @"searchDICOMBonjour",
										  [NSMutableArray array], @"SERVERS",
										  [NSNumber numberWithBool:NO], @"syncDICOMNodes",
										  @"http://www.example.net/DicomNodes.plist", @"syncDICOMNodesURL",
										  [NSNumber numberWithBool:NO], @"syncOsiriXDB",
										  @"http://www.example.net/OsiriXNodes.plist", @"syncOsiriXDBURL",
										  NULL];
	[initialValues addEntriesFromDictionary:[defaults initialValues]];
	[defaults setInitialValues:[NSDictionary dictionaryWithDictionary:initialValues]];
}*/

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"OSILocationsPreferencePanePref" bundle: nil];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}


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
					if ([[NSUserDefaults standardUserDefaults] boolForKey: @"HideSameAETitleAlert"] == NO)
					{
						NSAlert* alert = [[NSAlert new] autorelease];
						[alert setMessageText: NSLocalizedString(@"Same AETitle", 0L)];
						[alert setInformativeText:  [NSString stringWithFormat: NSLocalizedString(@"This AETitle is not unique: %@. AETitles should be unique, otherwise Q&R (C-Move SCP/SCU) can fail.", 0L), currentAETitle]];
						[alert setShowsSuppressionButton:YES ];
						[alert addButtonWithTitle: NSLocalizedString(@"OK", nil)];
						
						[alert runModal];
						
						if ([[alert suppressionButton] state] == NSOnState)
							[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"HideSameAETitleAlert"];
						
						i = [serverList count];
						x = [serverList count];
					}
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
	
	[DDKeychain lockTmpFiles];
	
	if([[serverParameters objectForKey:@"TLSEnabled"] boolValue])
	{
		// TLS support. Options listed here http://support.dcmtk.org/docs/echoscu.html
		
		if([[serverParameters objectForKey:@"TLSAuthenticated"] boolValue])
		{
			[args addObject:@"--enable-tls"]; // use authenticated secure TLS connection

			[DICOMTLS generateCertificateAndKeyForServerAddress:address port: [port intValue] AETitle:aet]; // export certificate/key from the Keychain to the disk
			[args addObject:[DICOMTLS keyPathForServerAddress:address port:[port intValue] AETitle:aet]]; // [p]rivate key file
			[args addObject:[DICOMTLS certificatePathForServerAddress:address port:[port intValue] AETitle:aet]]; // [c]ertificate file: string
			
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

	[DDKeychain unlockTmpFiles];
	
	if( [theTask terminationStatus] == 0) return YES;
	else return NO;
}

- (void) enableControls: (BOOL) val
{
//	[[NSUserDefaults standardUserDefaults] setBool: val forKey: @"preferencesModificationsEnabled"];
//	[[NSUserDefaults standardUserDefaults] setBool: [[NSUserDefaults standardUserDefaults] boolForKey:@"syncDICOMNodes"] forKey: @"syncDICOMNodes"];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
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
	[aServer setObject: [NSNumber numberWithInt: 0] forKey: @"WADOhttps"];
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

- (IBAction) testWADOUrl: (id) sender
{
	NSString *protocol = WADOhttps ? @"https" : @"http";
	
	NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex: [[dicomNodes tableView] selectedRow]];
	
	NSString *baseURL = [NSString stringWithFormat: @"%@://%@:%d/%@?requestType=WADO", protocol, [aServer valueForKey: @"Address"], WADOPort, WADOUrl];
	
	NSURL *url = [NSURL URLWithString: [baseURL stringByAppendingFormat:@"&studyUID=%@&seriesUID=%@&objectUID=%@&contentType=application/dicom%@", @"1", @"1", @"1", @"&useOrig=true"]];
	
	NSLog( @"URL to test: %@", baseURL);
	
	@try
	{
		[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
	}
	@catch (NSException * e)
	{
		NSLog( @"******* NSURLRequest setAllowsAnyHTTPSCertificate");
	}
	
	NSError *error = nil;
	[NSData dataWithContentsOfURL: url options: 0 error: &error];
	
	if( error)
		NSRunCriticalAlertPanel( NSLocalizedString( @"URL download Error", nil), [error localizedDescription], NSLocalizedString( @"OK", nil), nil, nil);
	else
		NSRunInformationalAlertPanel( NSLocalizedString( @"URL download Succeeded", nil), NSLocalizedString( @"It works !", nil), NSLocalizedString( @"OK", nil), nil, nil);
}

- (IBAction) editWADO: (id) sender
{
	NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex: [[dicomNodes tableView] selectedRow]];
	
	self.WADOPort = [[aServer valueForKey: @"WADOPort"] intValue];
	self.WADOUrl = [aServer valueForKey: @"WADOUrl"];
	self.WADOTransferSyntax = [[aServer valueForKey: @"WADOTransferSyntax"] intValue];
	self.WADOhttps = [[aServer valueForKey: @"WADOhttps"] intValue];
	
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
		[aServer setObject: [NSNumber numberWithInt: WADOhttps] forKey: @"WADOhttps"];
		[aServer setObject: WADOUrl forKey: @"WADOUrl"];
		
		// disable TLS
		[aServer setObject:[NSNumber numberWithBool:NO] forKey:@"TLSEnabled"];
		
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
			else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString( @"Cannot download data from this URL.", 0L), NSLocalizedString( @"OK", nil), nil, nil);
		}
		else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString( @"This URL is invalid. Check syntax.", 0L), NSLocalizedString( @"OK", nil), nil, nil);
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
			if( NSRunInformationalAlertPanel(NSLocalizedString(@"Load locations", 0L), NSLocalizedString(@"Should I add or replace this locations list? If you choose 'replace', the current list will be deleted.", 0L), NSLocalizedString(@"Add", nil), NSLocalizedString(@"Replace", nil), nil) == NSAlertDefaultReturn)
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
			else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"Cannot download data from this URL.", 0L), NSLocalizedString(@"OK", nil), nil, nil);
		}
		else NSRunInformationalAlertPanel(NSLocalizedString(@"URL Invalid", 0L), NSLocalizedString(@"This URL is invalid. Check syntax.", 0L), NSLocalizedString(@"OK", nil), nil, nil);
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
			if( NSRunInformationalAlertPanel(NSLocalizedString(@"Load locations", 0L), NSLocalizedString(@"Should I add or replace this locations list? If you choose 'replace', the current list will be deleted.", 0L), NSLocalizedString(@"Add", nil), NSLocalizedString(@"Replace", nil), nil) == NSAlertDefaultReturn)
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
		
		[[dicomNodes tableView] selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
		[[dicomNodes tableView] display];
		
		if ([OSILocationsPreferencePanePref echoServer:aServer])
			status = 0;
		else
			status = -1;
		
		[aServer setObject:[NSNumber numberWithInt: status] forKey:@"test"];
	}
	
	[progress stopAnimation: self];
	
	[[dicomNodes tableView] selectRowIndexes: [NSIndexSet indexSetWithIndex: selectedRow] byExtendingSelection: NO];
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
	
	NSArray *selectedCipherSuites = [aServer valueForKey:@"TLSCipherSuites"];

	if ([selectedCipherSuites count])
		self.TLSSupportedCipherSuite = selectedCipherSuites;
	else
		self.TLSSupportedCipherSuite = [DICOMTLS defaultCipherSuites];

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

- (IBAction)chooseTLSCertificate:(id)sender
{
	NSArray *certificates = [DDKeychain KeychainAccessCertificatesList];
	
	if([certificates count])
	{
		[[SFChooseIdentityPanel sharedChooseIdentityPanel] setAlternateButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")];
		NSInteger clickedButton = [[SFChooseIdentityPanel sharedChooseIdentityPanel] runModalForIdentities:certificates message:NSLocalizedString(@"Choose a certificate from the following list.", nil)];
		
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
	else
	{
		NSInteger clickedButton = NSRunCriticalAlertPanel( NSLocalizedString( @"No Valid Certificate", nil), NSLocalizedString( @"Your Keychain does not contain any valid certificate.", nil), NSLocalizedString( @"Help", nil), NSLocalizedString( @"Cancel", nil), nil);
		
		if(clickedButton==NSOKButton)
		{
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://osirix.svn.sourceforge.net/viewvc/osirix/Documentation/Guides/Security/index.html"]];
		}
		
		return;
	}
}

- (IBAction)viewTLSCertificate:(id)sender;
{
	NSString *label = [self DICOMTLSUniqueLabelForSelectedServer];
	[DDKeychain openCertificatePanelForLabel:label];
}

- (void)getTLSCertificate;
{	
	NSString *label = [self DICOMTLSUniqueLabelForSelectedServer];
	NSString *name = [DDKeychain certificateNameForLabel:label];
	NSImage *icon = [DDKeychain certificateIconForLabel:label];
	
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

- (NSString*)DICOMTLSUniqueLabelForSelectedServer;
{
	NSMutableDictionary *aServer = [[dicomNodes arrangedObjects] objectAtIndex:[[dicomNodes tableView] selectedRow]];
	return [DICOMTLS uniqueLabelForServerAddress:[aServer valueForKey:@"Address"] port:[NSString stringWithFormat:@"%d",[[aServer valueForKey:@"Port"] intValue]] AETitle:[aServer valueForKey:@"AETitle"]];
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

@end


@implementation NotWADOValueTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
	if (value != nil)
	{
		float retrieveMode = [value intValue]; // this should be the tag of the retrieve mode
		if (retrieveMode==2)
			return [NSNumber numberWithInt:0];
		return [NSNumber numberWithInt:1];
	}
	return [NSNumber numberWithInt:1];
}

@end