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
 OsiriX Project.
 
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

#import <Cocoa/Cocoa.h>
#import "DDKeychain.h"

typedef enum
{
	RequirePeerCertificate = 0,
	VerifyPeerCertificate,
	IgnorePeerCertificate
} TLSCertificateVerificationType;

#define TLS_SEED_FILE @"/tmp/OsiriXTLSSeed"
#define TLS_WRITE_SEED_FILE "/tmp/OsiriXTLSSeedWrite"
#define TLS_PRIVATE_KEY_FILE @"/tmp/TLSKey"
#define TLS_CERTIFICATE_FILE @"/tmp/TLSCert"
#define TLS_TRUSTED_CERTIFICATES_DIR @"/tmp/TLSTrustedCert" 
#define TLS_KEYCHAIN_IDENTITY_NAME_CLIENT @"com.osirixviewer.dicomtlsclient"
#define TLS_KEYCHAIN_IDENTITY_NAME_SERVER @"com.osirixviewer.dicomtlsserver"

/** \brief
 A utility class for secure DICOM connections with TLS.
 It provides an access to Mac OS X Keychain.
 */
@interface DICOMTLS : NSObject {

}

#pragma mark Cipher Suites
/**
	Returns the list of available Ciphersuites.
	These are basically the one available through DCMTK.
 */
+ (NSArray*)availableCipherSuites;
+ (NSArray*)defaultCipherSuites;

+ (NSString*) TLS_PRIVATE_KEY_PASSWORD;
+ (void) eraseKeys;

#pragma mark Keychain Access
+ (void)generateCertificateAndKeyForLabel:(NSString*)label withStringID:(NSString*)stringID;
+ (void)generateCertificateAndKeyForLabel:(NSString*)label;
+ (void)generateCertificateAndKeyForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle withStringID:(NSString*)stringID;
+ (void)generateCertificateAndKeyForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
+ (NSString*)uniqueLabelForServerAddress:(NSString*)address port:(NSString*)port AETitle:(NSString*)aetitle;
+ (NSString*)keyPathForLabel:(NSString*)label withStringID:(NSString*)stringID;
+ (NSString*)keyPathForLabel:(NSString*)label;
+ (NSString*)keyPathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle withStringID:(NSString*)stringID;
+ (NSString*)keyPathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
+ (NSString*)certificatePathForLabel:(NSString*)label withStringID:(NSString*)stringID;
+ (NSString*)certificatePathForLabel:(NSString*)label;
+ (NSString*)certificatePathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle withStringID:(NSString*)stringID;
+ (NSString*)certificatePathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
	
@end
