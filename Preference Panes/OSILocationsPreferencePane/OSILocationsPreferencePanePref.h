/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX project.
 
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
#import <SecurityInterface/SFChooseIdentityPanel.h>
#import <SecurityInterface/SFCertificateView.h>
#import "DNDArrayController.h"
#import <WebKit/WebKit.h>

#import "DICOMTLS.h"

@interface OSILocationsPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSPopUpButton			*characterSetPopup;
	IBOutlet NSButton				*addServerDICOM, *addServerSharing, *searchDICOMBonjourNodes, *verifyPing, *addLocalPath, *loadNodes;
	NSString						*stringEncoding;
	
	IBOutlet DNDArrayController		*localPaths, *osiriXServers, *dicomNodes;
	
	// WADO
	IBOutlet NSWindow				*WADOSettings;
	int								WADOPort, WADOTransferSyntax, WADOhttps;
	NSString						*WADOUrl;
	NSString						*WADOUsername;
	NSString						*WADOPassword;
	
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
	TLSCertificateVerificationType	TLSCertificateVerification;
	
	IBOutlet NSWindow						*mainWindow;
    BOOL                            testingNodes;
    
    id _tlos;
}

@property int WADOhttps, WADOPort, WADOTransferSyntax;
@property (retain) NSString *WADOUrl;
@property (retain) NSString *WADOUsername;
@property (retain) NSString *WADOPassword;

@property BOOL TLSEnabled, TLSAuthenticated, TLSUseDHParameterFileURL, testingNodes;
@property (retain) NSURL *TLSDHParameterFileURL;
@property (retain) NSArray *TLSSupportedCipherSuite;
@property TLSCertificateVerificationType TLSCertificateVerification;

@property (retain) NSString *TLSAuthenticationCertificate;


+ (BOOL)echoServer:(NSDictionary*)serverParameters;

- (IBAction) testWADOUrl: (id) sender;
- (IBAction)refreshNodesListURL:(id)sender;
- (void)mainViewDidLoad;
- (IBAction)newServer:(id)sender;
- (IBAction)osirixNewServer:(id)sender;
- (IBAction)setStringEncoding:(id)sender;
- (IBAction)test:(id)sender;
- (void)resetTest;
- (IBAction)saveAs:(id)sender;
- (IBAction)loadFrom:(id)sender;
- (IBAction)addPath:(id)sender;
- (IBAction)OsiriXDBsaveAs:(id)sender;
- (IBAction)refreshNodesOsiriXDB:(id)sender;
- (IBAction)OsiriXDBloadFrom:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)editWADO:(id)sender;

- (IBAction)editTLS:(id)sender;
- (IBAction)chooseTLSCertificate:(id)sender;
- (IBAction)viewTLSCertificate:(id)sender;
- (void)getTLSCertificate;
- (NSString*)DICOMTLSUniqueLabelForSelectedServer;
- (IBAction)selectAllSuites:(id)sender;
- (IBAction)deselectAllSuites:(id)sender;
@end


@interface NotWADOValueTransformer: NSValueTransformer
{}
@end
