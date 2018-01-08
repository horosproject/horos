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
#import <Security/Security.h>
#import <SecurityInterface/SFCertificatePanel.h>

@interface DDKeychain : NSObject
{

}

+ (NSString *)passwordForHTTPServer;
+ (BOOL)setPasswordForHTTPServer:(NSString *)password;

+ (void)createNewIdentity;
+ (NSArray *)SSLIdentityAndCertificates;

+ (NSString *)applicationTemporaryDirectory;
+ (NSString *)stringForSecExternalFormat:(SecExternalFormat)extFormat;
+ (NSString *)stringForSecExternalItemType:(SecExternalItemType)itemType;
+ (NSString *)stringForSecKeychainAttrType:(SecKeychainAttrType)attrType;
+ (NSString *)stringForError:(OSStatus)status;

+ (NSArray *)KeychainAccessCertificatesList;
+ (void)KeychainAccessExportTrustedCertificatesToDirectory:(NSString*)directory;
+ (SecIdentityRef)KeychainAccessPreferredIdentityForName:(NSString*)name keyUse:(int)keyUse;
+ (void)KeychainAccessSetPreferredIdentity:(SecIdentityRef)identity forName:(NSString*)name keyUse:(int)keyUse;
+ (NSString*)KeychainAccessCertificateCommonNameForIdentity:(SecIdentityRef)identity;
+ (NSImage*)KeychainAccessCertificateIconForIdentity:(SecIdentityRef)identity;
+ (NSArray*)KeychainAccessCertificateChainForIdentity:(SecIdentityRef)identity;
+ (void)KeychainAccessExportCertificateForIdentity:(SecIdentityRef)identity toPath:(NSString*)path;
+ (void)KeychainAccessExportPrivateKeyForIdentity:(SecIdentityRef)identity toPath:(NSString*)path cryptWithPassword:(NSString*)password;
+ (void)KeychainAccessOpenCertificatePanelForIdentity:(SecIdentityRef)identity;

+ (SecIdentityRef)identityForLabel:(NSString*)label;
+ (NSString*)certificateNameForLabel:(NSString*)label;
+ (NSImage*)certificateIconForLabel:(NSString*)label;
+ (void)openCertificatePanelForLabel:(NSString*)label;

//+ (SecIdentityRef)DICOMTLSIdentityForLabel:(NSString*)label;
//+ (NSString*)DICOMTLSCertificateNameForLabel:(NSString*)label;
//+ (NSImage*)DICOMTLSCertificateIconForLabel:(NSString*)label;
//+ (void)DICOMTLSOpenCertificatePanelForLabel:(NSString*)label;
//+ (void)DICOMTLSGenerateCertificateAndKeyForLabel:(NSString*)label;
//+ (void)DICOMTLSGenerateCertificateAndKeyForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
//+ (NSString*)DICOMTLSUniqueLabelForServerAddress:(NSString*)address port:(NSString*)port AETitle:(NSString*)aetitle;
//+ (NSString*)DICOMTLSKeyPathForLabel:(NSString*)label;
//+ (NSString*)DICOMTLSKeyPathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
//+ (NSString*)DICOMTLSCertificatePathForLabel:(NSString*)label;
//+ (NSString*)DICOMTLSCertificatePathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;

+ (void)generatePseudoRandomFileToPath:(NSString*)path;
+ (void)lockFile:(NSString*)path;
+ (void)unlockFile:(NSString*)path;
+ (void)lockTmpFiles;
+ (void)unlockTmpFiles;

@end
