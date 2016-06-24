/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import <PreferencePanes/PreferencePanes.h>

#import "DICOMTLS.h"

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
	
	TLSCertificateVerificationType	TLSCertificateVerification;
	
	BOOL TLSUseSameAETITLE;
	NSString *TLSStoreSCPAETITLE;
	IBOutlet NSButton *TLSStoreSCPAETITLEIsDefaultAETButton;
	BOOL TLSStoreSCPAETITLEIsDefaultAET;
	
	IBOutlet NSTextField *TLSAETitleTextField;
	IBOutlet NSTextField *TLSPortTextField;
	IBOutlet NSTextField *TLSPreferredSyntaxTextField;
	
	IBOutlet NSWindow *mainWindow;
}

@property (retain) NSString *TLSAuthenticationCertificate, *TLSStoreSCPAETITLE;
@property (retain) NSArray *TLSSupportedCipherSuite;
@property BOOL TLSUseDHParameterFileURL, TLSUseSameAETITLE, TLSStoreSCPAETITLEIsDefaultAET;
@property (retain) NSURL *TLSDHParameterFileURL;
@property TLSCertificateVerificationType TLSCertificateVerification;

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
