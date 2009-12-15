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

typedef enum
{
	PasswordNone = 0,
	PasswordAsk,
	PasswordString
} TLSPasswordType;

typedef enum
{
	PEM = 0,
	DER
} TLSFileFormat;

typedef enum
{
	RequirePeerCertificate = 0,
	VerifyPeerCertificate,
	IgnorePeerCertificate
} TLSCertificateVerificationType;


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
	NSURL							*TLSCertificateFileURL, *TLSPrivateKeyFileURL;
	BOOL							TLSUsePrivateKeyFilePassword;
	TLSPasswordType					TLSPrivateKeyFilePasswordType;
	NSString						*TLSPrivateKeyFilePassword;
	TLSFileFormat					TLSKeyAndCertificateFileFormat;
	IBOutlet DNDArrayController		*TLSCipherSuitesArrayController;
	NSArray							*TLSSupportedCipherSuite;
	BOOL							TLSUseTrustedCACertificatesFolderURL, TLSUseDHParameterFileURL;
	NSURL							*TLSTrustedCACertificatesFolderURL, *TLSDHParameterFileURL;
	TLSCertificateVerificationType	TLSCertificateVerification;
	
	IBOutlet SFAuthorizationView	*_authView;
}

@property int WADOPort, WADOTransferSyntax;
@property (retain) NSString *WADOUrl;

@property BOOL TLSEnabled, TLSAuthenticated, TLSUseTrustedCACertificatesFolderURL, TLSUseDHParameterFileURL;
@property (retain) NSURL *TLSCertificateFileURL, *TLSPrivateKeyFileURL, *TLSTrustedCACertificatesFolderURL, *TLSDHParameterFileURL;
@property BOOL TLSUsePrivateKeyFilePassword;
@property (setter=setTLSPrivateKeyFilePasswordType:) TLSPasswordType TLSPrivateKeyFilePasswordType;
@property (retain) NSString *TLSPrivateKeyFilePassword;
@property TLSFileFormat TLSKeyAndCertificateFileFormat;
@property (retain) NSArray *TLSSupportedCipherSuite;
@property TLSCertificateVerificationType TLSCertificateVerification;

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

@end
