#import "OsiriXHTTPConnection.h"
#import "DDKeychain.h"

@implementation OsiriXHTTPConnection

- (BOOL)isPasswordProtected:(NSString *)path
{
	// We're only going to password protect the "secret" directory.
	
	return [path hasPrefix:@"/secret"];
}

- (BOOL)useDigestAccessAuthentication
{
	// Digest access authentication is the default setting.
	// Notice in Safari that when you're prompted for your password,
	// Safari tells you "Your login information will be sent securely."
	// 
	// If you return NO in this method, the HTTP server will use
	// basic authentication. Try it and you'll see that Safari
	// will tell you "Your password will be sent unencrypted",
	// which is strongly discouraged.
	
	return YES;
}

- (NSString *)passwordForUser:(NSString *)username
{
	// You can do all kinds of cool stuff here.
	// For simplicity, we're not going to check the username, only the password.
	
	return @"secret";
}

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)isSecureServer
{
	// Create an HTTPS server (all connections will be secured via SSL/TLS)
	return YES;
}

/**
 * Overrides HTTPConnection's method
 * 
 * This method is expected to returns an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 **/
- (NSArray *)sslIdentityAndCertificates
{
	NSArray *result = [DDKeychain SSLIdentityAndCertificates];
	if([result count] == 0)
	{
		[DDKeychain createNewIdentity];
		return [DDKeychain SSLIdentityAndCertificates];
	}
	return result;
}


@end
