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
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <SecurityInterface/SFCertificateView.h>
#import "DNDArrayController.h"

#if defined(OSIRIX)
#import "DICOMTLS.h"
#endif

@interface OSILocationsPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSPopUpButton			*characterSetPopup;
	IBOutlet NSButton				*addServerDICOM, *addServerSharing, *searchDICOMBonjourNodes, *verifyPing, *addLocalPath, *loadNodes;
	NSString						*stringEncoding;
	IBOutlet NSProgressIndicator	*progress;
	
	IBOutlet DNDArrayController		*localPaths, *osiriXServers, *dicomNodes;
	
	// WADO
	IBOutlet NSWindow				*WADOSettings;
	int								WADOPort;
	int								WADOTransferSyntax;
	NSString						*WADOUrl;
	
	// TLS
	IBOutlet NSWindow				*TLSSettings;
	BOOL							TLSEnabled;
	BOOL							TLSAuthenticated;
	NSString						*TLSAuthenticationCertificate;
	IBOutlet NSButton				*TLSChooseCertificateButton, *TLSCertificateButton;
	IBOutlet DNDArrayController		*TLSCipherSuitesArrayController;
	NSArray							*TLSSupportedCipherSuite;
	BOOL							TLSUseDHParameterFileURL;
	NSURL							*TLSDHParameterFileURL;
	#if defined(OSIRIX)
	TLSCertificateVerificationType	TLSCertificateVerification;
	#endif
	
	IBOutlet SFAuthorizationView	*_authView;
}

@property int WADOPort, WADOTransferSyntax;
@property (retain) NSString *WADOUrl;

@property BOOL TLSEnabled, TLSAuthenticated, TLSUseDHParameterFileURL;
@property (retain) NSURL *TLSDHParameterFileURL;
@property (retain) NSArray *TLSSupportedCipherSuite;
#if defined(OSIRIX)
@property TLSCertificateVerificationType TLSCertificateVerification;
#endif

@property (retain) NSString *TLSAuthenticationCertificate;


+ (BOOL) echoServer:(NSDictionary*)serverParameters;

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

- (IBAction)chooseTLSCertificate:(id)sender;
- (IBAction)viewTLSCertificate:(id)sender;
- (void)getTLSCertificate;
- (NSString*)DICOMTLSUniqueLabelForSelectedServer;

@end
