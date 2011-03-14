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

#if defined(OSIRIX)
#import <OsiriXAPI/DICOMTLS.h>
#endif

@interface OSIListenerPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSTextField *ipField;
	IBOutlet NSTextField *nameField;
	
	IBOutlet NSTextField* sharingNameField;	
	
	IBOutlet NSPopUpButton *preferredSyntaxPopUpButton;	
	
	IBOutlet NSWindow *TLSSettingsWindow;
	NSString *TLSAuthenticationCertificate;
	IBOutlet NSButton *TLSChooseCertificateButton, *TLSCertificateButton;
	NSArray *TLSSupportedCipherSuite;
	BOOL TLSUseDHParameterFileURL;
	NSURL *TLSDHParameterFileURL;
	
	#if defined(OSIRIX)
	TLSCertificateVerificationType	TLSCertificateVerification;
	#endif
	
	BOOL TLSUseSameAETITLE;
	NSString *TLSStoreSCPAETITLE;
	IBOutlet NSButton *TLSStoreSCPAETITLEIsDefaultAETButton;
	BOOL TLSStoreSCPAETITLEIsDefaultAET;
	
	IBOutlet NSTextField *TLSAETitleTextField;
	IBOutlet NSTextField *TLSPortTextField;
	IBOutlet NSTextField *TLSPreferredSyntaxTextField;
}

@property (retain) NSString *TLSAuthenticationCertificate, *TLSStoreSCPAETITLE;
@property (retain) NSArray *TLSSupportedCipherSuite;
@property BOOL TLSUseDHParameterFileURL, TLSUseSameAETITLE, TLSStoreSCPAETITLEIsDefaultAET;
@property (retain) NSURL *TLSDHParameterFileURL;
#if defined(OSIRIX)
@property TLSCertificateVerificationType TLSCertificateVerification;
#endif

- (void) mainViewDidLoad;

-(IBAction)editAddresses:(id)sender;
-(IBAction)editHostname:(id)sender;

#pragma mark TLS
- (IBAction)editTLS:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)chooseTLSCertificate:(id)sender;
- (IBAction)viewTLSCertificate:(id)sender;
- (void)getTLSCertificate;
- (IBAction)useSameAETitleForTLSListener:(id)sender;
- (IBAction)activateDICOMTLSListenerAction:(id)sender;
- (void)updateTLSStoreSCPAETITLEIsDefaultAETButton;
- (IBAction)selectAllSuites:(id)sender;
- (IBAction)deselectAllSuites:(id)sender;

@end
