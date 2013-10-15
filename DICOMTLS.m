/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DICOMTLS.h"

@implementation DICOMTLS

#pragma mark Cipher Suites

+ (NSArray*)availableCipherSuites;
{
	// list taken from "tlslayer.cc"
	NSArray *cipherSuites = [NSArray arrayWithObjects:	@"TLS_RSA_WITH_NULL_MD5",
							 @"TLS_RSA_WITH_NULL_SHA",
							 @"TLS_RSA_EXPORT_WITH_RC4_40_MD5",
							 @"TLS_RSA_WITH_RC4_128_MD5",
							 @"TLS_RSA_WITH_RC4_128_SHA",
							 @"TLS_RSA_EXPORT_WITH_RC2_CBC_40_MD5",
							 @"TLS_RSA_WITH_IDEA_CBC_SHA",
							 @"TLS_RSA_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_RSA_WITH_DES_CBC_SHA",
							 @"TLS_RSA_WITH_3DES_EDE_CBC_SHA",
							 @"TLS_DH_DSS_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_DH_DSS_WITH_DES_CBC_SHA",        
							 @"TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA",   
							 @"TLS_DH_RSA_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_DH_RSA_WITH_DES_CBC_SHA",        
							 @"TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA",   
							 @"TLS_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA",
							 @"TLS_DHE_DSS_WITH_DES_CBC_SHA",            
							 @"TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA",       
							 @"TLS_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA",   
							 @"TLS_DHE_RSA_WITH_DES_CBC_SHA",            
							 @"TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA",       
							 @"TLS_DH_anon_EXPORT_WITH_RC4_40_MD5",      
							 @"TLS_DH_anon_WITH_RC4_128_MD5",            
							 @"TLS_DH_anon_EXPORT_WITH_DES40_CBC_SHA",   
							 @"TLS_DH_anon_WITH_DES_CBC_SHA",            
							 @"TLS_DH_anon_WITH_3DES_EDE_CBC_SHA",       
							 @"TLS_RSA_EXPORT1024_WITH_DES_CBC_SHA",     
							 @"TLS_RSA_EXPORT1024_WITH_RC4_56_SHA",      
							 @"TLS_DHE_DSS_EXPORT1024_WITH_DES_CBC_SHA", 
							 @"TLS_DHE_DSS_EXPORT1024_WITH_RC4_56_SHA",  
							 @"TLS_DHE_DSS_WITH_RC4_128_SHA",            
							 //if OPENSSL_VERSION_NUMBER >= 0x0090700fL
							 // cipersuites added in OpenSSL 0.9.7
							 @"TLS_RSA_EXPORT_WITH_RC4_56_MD5",         
							 @"TLS_RSA_EXPORT_WITH_RC2_CBC_56_MD5",     
							 /* AES ciphersuites from RFC3268 */
							 @"TLS_RSA_WITH_AES_128_CBC_SHA",           
							 @"TLS_DH_DSS_WITH_AES_128_CBC_SHA",        
							 @"TLS_DH_RSA_WITH_AES_128_CBC_SHA",        
							 @"TLS_DHE_DSS_WITH_AES_128_CBC_SHA",       
							 @"TLS_DHE_RSA_WITH_AES_128_CBC_SHA",       
							 @"TLS_DH_anon_WITH_AES_128_CBC_SHA",       
							 @"TLS_RSA_WITH_AES_256_CBC_SHA",           
							 @"TLS_DH_DSS_WITH_AES_256_CBC_SHA",        
							 @"TLS_DH_RSA_WITH_AES_256_CBC_SHA",        
							 @"TLS_DHE_DSS_WITH_AES_256_CBC_SHA",       
							 @"TLS_DHE_RSA_WITH_AES_256_CBC_SHA",       
							 @"TLS_DH_anon_WITH_AES_256_CBC_SHA",
							 nil];
	return cipherSuites;
}

+ (NSArray*)defaultCipherSuites;
{
	NSArray *availableCipherSuites = [DICOMTLS availableCipherSuites];
	NSMutableArray *cipherSuites = [NSMutableArray arrayWithCapacity:[availableCipherSuites count]];
	
	for (NSString *suite in availableCipherSuites)
	{
		[cipherSuites addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"Supported", suite, @"Cipher", nil]];
	}
	
	return [NSArray arrayWithArray:cipherSuites];
}

#pragma mark Keychain Access

static NSMutableString *TLS_PRIVATE_KEY_PASSWORD = nil;

+ (void) eraseKeys
{
    for( NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: @"/tmp" error: nil])
    {
        path = [@"/tmp/" stringByAppendingPathComponent: path];
        
        if( [path hasPrefix: TLS_SEED_FILE] || [path hasPrefix: [NSString stringWithUTF8String: TLS_WRITE_SEED_FILE]] || [path hasPrefix: TLS_PRIVATE_KEY_FILE] || [path hasPrefix: TLS_CERTIFICATE_FILE] || [path hasPrefix: TLS_TRUSTED_CERTIFICATES_DIR])
        {
            [[NSFileManager defaultManager] removeItemAtPath: path error: nil];
        }
    }
}

+ (NSString*) TLS_PRIVATE_KEY_PASSWORD
{
    if( TLS_PRIVATE_KEY_PASSWORD == nil)
    {
        NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        
        TLS_PRIVATE_KEY_PASSWORD = [[NSMutableString string] retain];
        
        for (int i=0; i<10; i++) {
            [TLS_PRIVATE_KEY_PASSWORD appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
        }
    }
    
    return TLS_PRIVATE_KEY_PASSWORD;
}

+ (void)generateCertificateAndKeyForLabel:(NSString*)label withStringID:(NSString*)stringID;
{	
	SecIdentityRef identity = [DDKeychain identityForLabel:label];
	if( identity)
	{
		// identity to certificate
		[DDKeychain KeychainAccessExportCertificateForIdentity:identity toPath:[[DICOMTLS certificatePathForLabel:label] stringByAppendingFormat:@"%@", stringID]];
		// identity to private key
		[DDKeychain KeychainAccessExportPrivateKeyForIdentity:identity toPath:[[DICOMTLS keyPathForLabel:label] stringByAppendingFormat:@"%@", stringID] cryptWithPassword: [DICOMTLS TLS_PRIVATE_KEY_PASSWORD]];
		CFRelease(identity);
	}
}

+ (void)generateCertificateAndKeyForLabel:(NSString*)label;
{
	[DICOMTLS generateCertificateAndKeyForLabel:label withStringID:@""];
}

+ (void)generateCertificateAndKeyForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle withStringID:(NSString*)stringID;
{	
	[DICOMTLS generateCertificateAndKeyForLabel:[DICOMTLS uniqueLabelForServerAddress:address port:[NSString stringWithFormat:@"%d",port] AETitle:aetitle] withStringID:stringID];
}

+ (void)generateCertificateAndKeyForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
{	
	[DICOMTLS generateCertificateAndKeyForServerAddress:address port:port AETitle:aetitle withStringID:@""];
}

+ (NSString*)uniqueLabelForServerAddress:(NSString*)address port:(NSString*)port AETitle:(NSString*)aetitle;
{
	NSMutableString *label = [NSMutableString string];
	[label appendString:TLS_KEYCHAIN_IDENTITY_NAME_CLIENT];
	[label appendString:@"."];
	[label appendString:address];
	[label appendString:@"."];
	[label appendString:port];
	[label appendString:@"."];
	[label appendString:aetitle];
	
	return [NSString stringWithString:label];
}

+ (NSString*)keyPathForLabel:(NSString*)label withStringID:(NSString*)stringID;
{
	return [NSString stringWithFormat:@"%@.%@.%@", TLS_PRIVATE_KEY_FILE, label, stringID];
}

+ (NSString*)keyPathForLabel:(NSString*)label;
{
	return [DICOMTLS keyPathForLabel:label withStringID:@""];
}

+ (NSString*)keyPathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle withStringID:(NSString*)stringID;
{
	return [DICOMTLS keyPathForLabel:[DICOMTLS uniqueLabelForServerAddress:address port:[NSString stringWithFormat:@"%d",port] AETitle:aetitle] withStringID:stringID];
}

+ (NSString*)keyPathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
{
	return [DICOMTLS keyPathForServerAddress:address port:port AETitle:aetitle withStringID:@""];
}

+ (NSString*)certificatePathForLabel:(NSString*)label withStringID:(NSString*)stringID;
{
	return [NSString stringWithFormat:@"%@.%@.%@", TLS_CERTIFICATE_FILE, label, stringID];
}

+ (NSString*)certificatePathForLabel:(NSString*)label;
{
	return [DICOMTLS certificatePathForLabel:label withStringID:@""];
}

+ (NSString*)certificatePathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle withStringID:(NSString*)stringID;
{
	return [DICOMTLS certificatePathForLabel:[DICOMTLS uniqueLabelForServerAddress:address port:[NSString stringWithFormat:@"%d",port] AETitle:aetitle] withStringID:stringID];
}

+ (NSString*)certificatePathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle
{
	return [DICOMTLS certificatePathForServerAddress:address port:port AETitle:aetitle withStringID:@""];
}

@end
