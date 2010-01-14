//
//  DICOMTLS.m
//  OsiriX
//
//  Created by joris on 1/14/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DICOMTLS.h"

@implementation DICOMTLS

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

#pragma mark Keychain Access

+ (void)generateCertificateAndKeyForLabel:(NSString*)label;
{	
	SecIdentityRef identity = [DDKeychain identityForLabel:label];
	if(identity)
	{		
		// identity to certificate
		[DDKeychain KeychainAccessExportCertificateForIdentity:identity toPath:[DICOMTLS certificatePathForLabel:label]];
		// identity to private key
		[DDKeychain KeychainAccessExportPrivateKeyForIdentity:identity toPath:[DICOMTLS keyPathForLabel:label] cryptWithPassword:TLS_PRIVATE_KEY_PASSWORD];
		CFRelease(identity);
	}
}

+ (void)generateCertificateAndKeyForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
{	
	[DICOMTLS generateCertificateAndKeyForLabel:[DICOMTLS uniqueLabelForServerAddress:address port:[NSString stringWithFormat:@"%d",port] AETitle:aetitle]];
}

+ (NSString*)uniqueLabelForServerAddress:(NSString*)address port:(NSString*)port AETitle:(NSString*)aetitle;
{
	NSMutableString *label = [NSMutableString string];
	[label appendString:TLS_KEYCHAIN_IDENTITY_NAME];
	[label appendString:@"."];
	[label appendString:address];
	[label appendString:@"."];
	[label appendString:port];
	[label appendString:@"."];
	[label appendString:aetitle];
	
	return [NSString stringWithString:label];
}

+ (NSString*)keyPathForLabel:(NSString*)label;
{
	return [NSString stringWithFormat:@"%@.%@", TLS_PRIVATE_KEY_FILE, label];
}

+ (NSString*)keyPathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
{
	return [DICOMTLS keyPathForLabel:[DICOMTLS uniqueLabelForServerAddress:address port:[NSString stringWithFormat:@"%d",port] AETitle:aetitle]];
}

+ (NSString*)certificatePathForLabel:(NSString*)label;
{
	return [NSString stringWithFormat:@"%@.%@", TLS_CERTIFICATE_FILE, label];
}

+ (NSString*)certificatePathForServerAddress:(NSString*)address port:(int)port AETitle:(NSString*)aetitle;
{
	return [DICOMTLS certificatePathForLabel:[DICOMTLS uniqueLabelForServerAddress:address port:[NSString stringWithFormat:@"%d",port] AETitle:aetitle]];
}

@end
