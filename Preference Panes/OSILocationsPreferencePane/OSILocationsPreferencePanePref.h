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

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import "DNDArrayController.h"

@interface OSILocationsPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSPopUpButton			*characterSetPopup;
	IBOutlet NSButton				*addServerDICOM, *addServerSharing, *searchDICOMBonjourNodes, *verifyPing, *addLocalPath, *loadNodes;
	NSString						*stringEncoding;
	IBOutlet NSProgressIndicator	*progress;
	
	IBOutlet DNDArrayController		*localPaths, *osiriXServers, *dicomNodes;
	
	IBOutlet NSWindow				*WADOSettings;
	
	int								WADOPort;
	int								WADOTransferSyntax;
	NSString						*WADOUrl;
	
	IBOutlet NSWindow				*TLSSettings;
	BOOL							TLSEnabled;
	BOOL							TLSAuthenticated;
	NSURL							*TLSCertificatesURL;
	IBOutlet DNDArrayController		*TLSCipherSuitesArrayController;
	NSArray							*TLSSupportedCipherSuite;
	NSArray							*TLSAvailableCipherSuite;
	
	IBOutlet SFAuthorizationView	*_authView;
}

@property int WADOPort, WADOTransferSyntax;
@property (retain) NSString *WADOUrl;

@property BOOL TLSEnabled, TLSAuthenticated;
@property (retain) NSURL *TLSCertificatesURL;
@property (retain) NSArray *TLSSupportedCipherSuite;

- (IBAction) refreshNodesListURL: (id) sender;
- (void) mainViewDidLoad;
- (IBAction) newServer:(id)sender;
- (IBAction) osirixNewServer:(id)sender;
- (IBAction) setStringEncoding:(id)sender;
- (IBAction) test:(id) sender;
- (void) resetTest;
- (IBAction) saveAs:(id) sender;
- (IBAction) loadFrom:(id) sender;
- (IBAction) addPath:(id) sender;
- (IBAction) OsiriXDBsaveAs:(id) sender;
- (IBAction) refreshNodesOsiriXDB: (id) sender;
- (IBAction) OsiriXDBloadFrom:(id) sender;

- (IBAction) cancel:(id)sender;
- (IBAction) ok:(id)sender;
- (IBAction) editWADO: (id) sender;

- (IBAction) editTLS: (id) sender;
- (NSArray*)availableCipherSuites;
- (NSArray*)defaultCipherSuites;

@end
