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
#import <OsiriX Headers/DICOMTLS.h>
#endif

@interface OSIListenerPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSForm *aeForm;
	IBOutlet NSMatrix *deleteFileModeMatrix;
	IBOutlet NSButton *listenerOnOffButton;
	IBOutlet NSTextField *ipField;
	IBOutlet NSTextField *nameField;
	IBOutlet NSButton *listenerOnOffAnonymize;
	IBOutlet NSButton *generateLogsButton;
	IBOutlet NSButton *decompressButton, *compressButton;
	IBOutlet NSTextField *checkIntervalField, *timeout;
	IBOutlet NSButton *singleProcessButton;
	IBOutlet NSPopUpButton *logDurationPopup;
	IBOutlet NSWindow *webServerSettingsWindow;
	
	IBOutlet NSTextField* sharingNameField;	
	
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
}

@property (retain) NSString *TLSAuthenticationCertificate, *TLSStoreSCPAETITLE;
@property (retain) NSArray *TLSSupportedCipherSuite;
@property BOOL TLSUseDHParameterFileURL, TLSUseSameAETITLE;
@property (retain) NSURL *TLSDHParameterFileURL;
#if defined(OSIRIX)
@property TLSCertificateVerificationType TLSCertificateVerification;
#endif

- (void) mainViewDidLoad;
- (IBAction)setDeleteFileMode:(id)sender;
- (IBAction)setListenerOnOff:(id)sender;
- (IBAction)setAnonymizeListenerOnOff:(id)sender;
- (IBAction)setGenerateLogs:(id)sender;
- (IBAction)helpstorescp:(id) sender;
- (IBAction)setSingleProcess:(id)sender;
- (IBAction)setLogDuration:(id)sender;
- (IBAction)setCheckInterval:(id) sender;
- (IBAction)setDecompress:(id)sender;
- (IBAction)setCompress:(id)sender;
- (IBAction)webServerSettings:(id)sender;
- (IBAction)smartAlbumHelpButton:(id)sender;
- (IBAction)openKeyChainAccess:(id)sender;

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
- (IBAction)selectAllSuites:(id)sender;
- (IBAction)deselectAllSuites:(id)sender;

@end
