/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import <PreferencePanes/PreferencePanes.h>

#import <OsiriXAPI/DICOMTLS.h>

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
