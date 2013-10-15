#import "DDKeychain.h"
#import "DICOMTLS.h"
#include <stdio.h>

static NSMutableDictionary *lockedFiles = nil;
static NSRecursiveLock *lockFile = nil;

/*
 * Function: SSLSecPolicyCopy
 * Purpose:
 *   Returns a copy of the SSL policy.
 */
static OSStatus SSLSecPolicyCopy(SecPolicyRef *ret_policy)
{
	SecPolicyRef policy;
	SecPolicySearchRef policy_search;
	OSStatus status;
	
	*ret_policy = NULL;
	status = SecPolicySearchCreate(CSSM_CERT_X_509v3, &CSSMOID_APPLE_TP_SSL, NULL, &policy_search);
	//status = SecPolicySearchCreate(CSSM_CERT_X_509v3, &CSSMOID_APPLE_X509_BASIC, NULL, &policy_search);
	require_noerr(status, SecPolicySearchCreate);
	
	status = SecPolicySearchCopyNext(policy_search, &policy);
	require_noerr(status, SecPolicySearchCopyNext);
	
	*ret_policy = policy;
	
SecPolicySearchCopyNext:
	
	CFRelease(policy_search);
	
SecPolicySearchCreate:
	
	return (status);
}


@implementation DDKeychain

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Retrieves the password stored in the keychain for the HTTP server.
**/
+ (NSString *)passwordForHTTPServer
{
	NSString *password = nil;
	
	const char *service = [@"OsiriX HTTP Server" UTF8String];
	const char *account = [@"OsiriX" UTF8String];
	
	UInt32 passwordLength = 0;
	void *passwordBytes = nil;
	
	OSStatus status;
	status = SecKeychainFindGenericPassword(NULL,            // default keychain
											strlen(service), // length of service name
											service,         // service name
											strlen(account), // length of account name
											account,         // account name
											&passwordLength, // length of password
											&passwordBytes,  // pointer to password data
											NULL);           // keychain item reference (NULL if unneeded)
	
	if(status == noErr)
	{
		NSData *passwordData = [NSData dataWithBytesNoCopy:passwordBytes length:passwordLength freeWhenDone:NO];
		password = [[[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding] autorelease];
	}
	
	// SecKeychainItemFreeContent(attrList, data)
	// attrList - previously returned attributes
	// data - previously returned password
	
	if(passwordBytes) SecKeychainItemFreeContent(NULL, passwordBytes);
	
	return password;
}


/**
 * This method sets the password for the HTTP server.
**/
+ (BOOL)setPasswordForHTTPServer:(NSString *)password
{
	const char *service = [@"OsiriX HTTP Server" UTF8String];
	const char *account = [@"OsiriX" UTF8String];
	const char *kind    = [@"OsiriX password" UTF8String];
	const char *passwd  = [password UTF8String];
	
	SecKeychainItemRef itemRef = NULL;
	
	// The first thing we need to do is check to see a password for the library already exists in the keychain
	OSStatus status;
	status = SecKeychainFindGenericPassword(NULL,            // default keychain
											strlen(service), // length of service name
											service,         // service name
											strlen(account), // length of account name
											account,         // account name
											NULL,            // length of password (NULL if unneeded)
											NULL,            // pointer to password data (NULL if unneeded)
											&itemRef);       // the keychain item reference
	
	if(status == errSecItemNotFound)
	{
		// Setup the attributes the for the keychain item
		SecKeychainAttribute attrs[] = {
			{ kSecServiceItemAttr, strlen(service), (char *)service },
			{ kSecAccountItemAttr, strlen(account), (char *)account },
			{ kSecDescriptionItemAttr, strlen(kind), (char *)kind }
		};
		SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
		
		status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, // class of item to create
												  &attributes,                  // pointer to the list of attributes
												  strlen(passwd),               // length of password
												  passwd,                       // pointer to password data
												  NULL,                         // default keychain
												  NULL,                         // access list (NULL if this app only)
												  &itemRef);                    // the keychain item reference
	}
	else if(status == noErr)
	{
		// A keychain item for the library already exists
		// All we need to do is update it with the new password
		status = SecKeychainItemModifyAttributesAndData(itemRef,        // the keychain item reference
														NULL,           // no change to attributes
														strlen(passwd),	// length of password
														passwd);        // pointer to password data
	}
	
	// Don't forget to release anything we create
	if(itemRef)    CFRelease(itemRef);
	
	return (status == noErr);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Identity:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method creates a new identity, and adds it to the keychain.
 * An identity is simply a certificate (public key and public information) along with a matching private key.
 * This method generates a new private key, and then uses the private key to generate a new self-signed certificate.
**/
+ (void)createNewIdentity
{
	// Declare any Carbon variables we may create
	// We do this here so it's easier to compare to the bottom of this method where we release them all
	SecKeychainRef keychain = NULL;
	CFArrayRef outItems = NULL;
	
	// Configure the paths where we'll create all of our identity files
	NSString *basePath = [DDKeychain applicationTemporaryDirectory];
	
	NSString *privateKeyPath  = [basePath stringByAppendingPathComponent:@"private.pem"];
	NSString *reqConfPath     = [basePath stringByAppendingPathComponent:@"req.conf"];
	NSString *certificatePath = [basePath stringByAppendingPathComponent:@"certificate.crt"];
	NSString *certWrapperPath = [basePath stringByAppendingPathComponent:@"certificate.p12"];
	
	// You can generate your own private key by running the following command in the terminal:
	// openssl genrsa -out private.pem 1024
	//
	// Where 1024 is the size of the private key.
	// You may used a bigger number.
	// It is probably a good recommendation to use at least 1024...
	
	NSArray *privateKeyArgs = [NSArray arrayWithObjects:@"genrsa", @"-out", privateKeyPath, @"1024", nil];
	
	NSTask *genPrivateKeyTask = [[[NSTask alloc] init] autorelease];
	
	[genPrivateKeyTask setLaunchPath:@"/usr/bin/openssl"];
	[genPrivateKeyTask setArguments:privateKeyArgs];
    [genPrivateKeyTask launch];
	
	// Don't use waitUntilExit - I've had too many problems with it in the past
	do {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	} while([genPrivateKeyTask isRunning]);
	
	// Now we want to create a configuration file for our certificate
	// This is an optional step, but we do it so people who are browsing their keychain
	// know exactly where the certificate came from, and don't delete it.
	
	NSMutableString *mStr = [NSMutableString stringWithCapacity:500];
	[mStr appendFormat:@"%@\n", @"[ req ]"];
	[mStr appendFormat:@"%@\n", @"distinguished_name  = req_distinguished_name"];
	[mStr appendFormat:@"%@\n", @"prompt              = no"];
	[mStr appendFormat:@"%@\n", @""];
	[mStr appendFormat:@"%@\n", @"[ req_distinguished_name ]"];
	[mStr appendFormat:@"%@\n", @"C                   = CH"];
	[mStr appendFormat:@"%@\n", @"ST                  = Geneva"];
	[mStr appendFormat:@"%@\n", @"L                   = Geneva"];
	[mStr appendFormat:@"%@\n", @"O                   = OsiriX Team"];
	[mStr appendFormat:@"%@\n", @"OU                  = Open Source"];
	[mStr appendFormat:@"%@\n", @"CN                  = OsiriX HTTP Server"];
	[mStr appendFormat:@"%@\n", @"emailAddress        = osirix@osirix-viewer.com"];
	
	[mStr writeToFile:reqConfPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
	
	// You can generate your own certificate by running the following command in the terminal:
	// openssl req -new -x509 -key private.pem -out certificate.crt -text -days 365 -batch
	// 
	// You can optionally create a configuration file, and pass an extra command to use it:
	// -config req.conf
	
	NSArray *certificateArgs = [NSArray arrayWithObjects:@"req", @"-new", @"-x509",
														 @"-key", privateKeyPath,
	                                                     @"-config", reqConfPath,
	                                                     @"-out", certificatePath,
	                                                     @"-text", @"-days", @"365", @"-batch", nil];
	
	NSTask *genCertificateTask = [[[NSTask alloc] init] autorelease];
	
	[genCertificateTask setLaunchPath:@"/usr/bin/openssl"];
	[genCertificateTask setArguments:certificateArgs];
    [genCertificateTask launch];
	
	// Don't use waitUntilExit - I've had too many problems with it in the past
	do {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	} while([genCertificateTask isRunning]);
	
	// Mac OS X has problems importing private keys, so we wrap everything in PKCS#12 format
	// You can create a p12 wrapper by running the following command in the terminal:
	// openssl pkcs12 -export -in certificate.crt -inkey private.pem -passout pass:password -out certificate.p12 -name "Open Source"
	
	NSArray *certWrapperArgs = [NSArray arrayWithObjects:@"pkcs12", @"-export", @"-export",
														 @"-in", certificatePath,
	                                                     @"-inkey", privateKeyPath,
	                                                     @"-passout", @"pass:password",
	                                                     @"-out", certWrapperPath,
	                                                     @"-name", @"OsiriX HTTP Server",
														nil];
	
	NSTask *genCertWrapperTask = [[[NSTask alloc] init] autorelease];
	
	[genCertWrapperTask setLaunchPath:@"/usr/bin/openssl"];
	[genCertWrapperTask setArguments:certWrapperArgs];
    [genCertWrapperTask launch];
	
	// Don't use waitUntilExit - I've had too many problems with it in the past
	do {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	} while([genCertWrapperTask isRunning]);
	
	// At this point we've created all the identity files that we need
	// Our next step is to import the identity into the keychain
	// We can do this by using the SecKeychainItemImport() method.
	// But of course this method is "Frozen in Carbonite"...
	// So it's going to take us 100 lines of code to build up the parameters needed to make the method call
	NSData *certData = [NSData dataWithContentsOfFile:certWrapperPath];
	
	/* SecKeyImportExportFlags - typedef uint32_t
	 * Defines values for the flags field of the import/export parameters.
	 * 
	 * enum 
	 * {
	 *    kSecKeyImportOnlyOne        = 0x00000001,
	 *    kSecKeySecurePassphrase     = 0x00000002,
	 *    kSecKeyNoAccessControl      = 0x00000004
	 * };
	 * 
	 * kSecKeyImportOnlyOne
	 *     Prevents the importing of more than one private key by the SecKeychainItemImport function.
	 *     If the importKeychain parameter is NULL, this bit is ignored. Otherwise, if this bit is set and there is
	 *     more than one key in the incoming external representation,
	 *     no items are imported to the specified keychain and the error errSecMultipleKeys is returned.
	 * kSecKeySecurePassphrase
	 *     When set, the password for import or export is obtained by user prompt. Otherwise, you must provide the
	 *     password in the passphrase field of the SecKeyImportExportParameters structure.
	 *     A user-supplied password is preferred, because it avoids having the cleartext password appear in the
	 *     application’s address space at any time.
	 * kSecKeyNoAccessControl
	 *     When set, imported private keys have no access object attached to them. In the absence of both this bit and
	 *     the accessRef field in SecKeyImportExportParameters, imported private keys are given default access controls
	**/
	
	SecKeyImportExportFlags importFlags = kSecKeyImportOnlyOne;
	
	/* SecKeyImportExportParameters - typedef struct
	 *
	 * FOR IMPORT AND EXPORT:
	 * uint32_t version
	 *     The version of this structure; the current value is SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION.
	 * SecKeyImportExportFlags flags
	 *     A set of flag bits, defined in "Keychain Item Import/Export Parameter Flags".
	 * CFTypeRef passphrase
	 *     A password, used for kSecFormatPKCS12 and kSecFormatWrapped formats only...
	 *     IE - kSecFormatWrappedOpenSSL, kSecFormatWrappedSSH, or kSecFormatWrappedPKCS8
	 * CFStringRef alertTitle
	 *     Title of secure password alert panel.
	 *     When importing or exporting a key, if you set the kSecKeySecurePassphrase flag bit,
	 *     you can optionally use this field to specify a string for the password panel’s title bar.
	 * CFStringRef alertPrompt
	 *     Prompt in secure password alert panel.
	 *     When importing or exporting a key, if you set the kSecKeySecurePassphrase flag bit,
	 *     you can optionally use this field to specify a string for the prompt that appears in the password panel.
	 *
	 * FOR IMPORT ONLY:
	 * SecAccessRef accessRef
	 *     Specifies the initial access controls of imported private keys.
	 *     If more than one private key is being imported, all private keys get the same initial access controls.
	 *     If this field is NULL when private keys are being imported, then the access object for the keychain item
	 *     for an imported private key depends on the kSecKeyNoAccessControl bit in the flags parameter.
	 *     If this bit is 0 (or keyParams is NULL), the default access control is used.
	 *     If this bit is 1, no access object is attached to the keychain item for imported private keys.
	 * CSSM_KEYUSE keyUsage
	 *     A word of bits constituting the low-level use flags for imported keys as defined in cssmtype.h.
	 *     If this field is 0 or keyParams is NULL, the default value is CSSM_KEYUSE_ANYCSSM_KEYUSE_ANY.
	 * CSSM_KEYATTR_FLAGS keyAttributes
	 *     The following are valid values for these flags:
	 *     CSSM_KEYATTR_PERMANENT, CSSM_KEYATTR_SENSITIVE, and CSSM_KEYATTR_EXTRACTABLE.
	 *     The default value is CSSM_KEYATTR_SENSITIVE | CSSM_KEYATTR_EXTRACTABLE
	 *     The CSSM_KEYATTR_SENSITIVE bit indicates that the key can only be extracted in wrapped form.
	 *     Important: If you do not set the CSSM_KEYATTR_EXTRACTABLE bit,
	 *     you cannot extract the imported key from the keychain in any form, including in wrapped form.
	**/
	
	SecKeyImportExportParameters importParameters;
	importParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	importParameters.flags = importFlags;
	importParameters.passphrase = CFSTR("password");
	importParameters.accessRef = NULL;
	importParameters.keyUsage = CSSM_KEYUSE_ANY;
	importParameters.keyAttributes = CSSM_KEYATTR_SENSITIVE | CSSM_KEYATTR_EXTRACTABLE;
	
	/* SecKeychainItemImport - Imports one or more certificates, keys, or identities and adds them to a keychain.
	 * 
	 * Parameters:
	 * CFDataRef importedData
	 *     The external representation of the items to import.
	 * CFStringRef fileNameOrExtension
	 *     The name or extension of the file from which the external representation was obtained.
	 *     Pass NULL if you don’t know the name or extension.
	 * SecExternalFormat *inputFormat
	 *     On input, points to the format of the external representation.
	 *     Pass kSecFormatUnknown if you do not know the exact format.
	 *     On output, points to the format that the function has determined the external representation to be in.
	 *     Pass NULL if you don’t know the format and don’t want the format returned to you.
	 * SecExternalItemType *itemType
	 *     On input, points to the item type of the item or items contained in the external representation.
	 *     Pass kSecItemTypeUnknown if you do not know the item type.
	 *     On output, points to the item type that the function has determined the external representation to contain.
	 *     Pass NULL if you don’t know the item type and don’t want the type returned to you.
	 * SecItemImportExportFlags flags
	 *     Unused; pass in 0.
	 * const SecKeyImportExportParameters *keyParams
	 *     A pointer to a structure containing a set of input parameters for the function.
	 *     If no key items are being imported, these parameters are optional
	 *     and you can set the keyParams parameter to NULL.
	 * SecKeychainRef importKeychain
	 *     A keychain object indicating the keychain to which the key or certificate should be imported.
	 *     If you pass NULL, the item is not imported.
	 *     Use the SecKeychainCopyDefault function to get a reference to the default keychain.
	 *     If the kSecKeyImportOnlyOne bit is set and there is more than one key in the
	 *     incoming external representation, no items are imported to the specified keychain and the
	 *     error errSecMultiplePrivKeys is returned.
	 * CFArrayRef *outItems
	 *     On output, points to an array of SecKeychainItemRef objects for the imported items.
	 *     You must provide a valid pointer to a CFArrayRef object to receive this information.
	 *     If you pass NULL for this parameter, the function does not return the imported items.
	 *     Release this object by calling the CFRelease function when you no longer need it.
	**/
	
	SecExternalFormat inputFormat = kSecFormatPKCS12;
	SecExternalItemType itemType = kSecItemTypeUnknown;
	
	SecKeychainCopyDefault(&keychain);
	
	OSStatus err = 0;
	err = SecKeychainItemImport((CFDataRef)certData,   // CFDataRef importedData
								NULL,                  // CFStringRef fileNameOrExtension
								&inputFormat,          // SecExternalFormat *inputFormat
								&itemType,             // SecExternalItemType *itemType
								0,                     // SecItemImportExportFlags flags (Unused)
								&importParameters,     // const SecKeyImportExportParameters *keyParams
								keychain,              // SecKeychainRef importKeychain
								&outItems);            // CFArrayRef *outItems
	
	NSLog(@"OSStatus: %i", (int) err);
	
	NSLog(@"SecExternalFormat: %@", [DDKeychain stringForSecExternalFormat:inputFormat]);
	NSLog(@"SecExternalItemType: %@", [DDKeychain stringForSecExternalItemType:itemType]);
	
	NSLog(@"outItems: %@", (NSArray *)outItems);
	
	SecIdentityRef identity = (SecIdentityRef)[(NSArray *)outItems lastObject];
	[DDKeychain KeychainAccessSetPreferredIdentity:identity forName:@"com.osirixviewer.osirixwebserver" keyUse:CSSM_KEYUSE_ANY];
	
	// Don't forget to delete the temporary files
	[[NSFileManager defaultManager] removeFileAtPath:privateKeyPath handler:nil];
	[[NSFileManager defaultManager] removeFileAtPath:reqConfPath handler:nil];
	[[NSFileManager defaultManager] removeFileAtPath:certificatePath handler:nil];
	[[NSFileManager defaultManager] removeFileAtPath:certWrapperPath handler:nil];
	
	// Don't forget to release anything we may have created
	if(keychain)   CFRelease(keychain);
	if(outItems)   CFRelease(outItems);
}

/**
 * Returns an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 * Currently this method is designed to return the identity created in the method above.
 * You will most likely alter this method to return a proper identity based on what it is you're trying to do.
**/
+ (NSArray *)SSLIdentityAndCertificates
{
	// Declare any Carbon variables we may create
	// We do this here so it's easier to compare to the bottom of this method where we release them all
	SecKeychainRef keychain = NULL;
	SecIdentitySearchRef searchRef = NULL;
	
	// Create array to hold the results
	NSMutableArray *result = [NSMutableArray array];
	
	/* SecKeychainAttribute - typedef struct
	 * Contains keychain attributes.
	 *
	 * struct SecKeychainAttribute
	 * {
	 *   SecKeychainAttrType tag;
	 *   UInt32 length;
	 *   void *data;
	 * };
	 *
	 * Fields:
	 * tag
	 *     A 4-byte attribute tag. See “Keychain Item Attribute Constants” for valid attribute types.
	 * length
	 *     The length of the buffer pointed to by data.
	 * data
	 *     A pointer to the attribute data.
	**/

	/* SecKeychainAttributeList - typedef struct
	 * Represents a list of keychain attributes.
	 * 
	 * struct SecKeychainAttributeList
	 * {
	 *   UInt32 count;
	 *   SecKeychainAttribute *attr;
	 * };
	 *
	 * Fields:
	 * count
	 *     An unsigned 32-bit integer that represents the number of keychain attributes in the array.
	 * attr
	 *     A pointer to the first keychain attribute in the array.
	**/
	
	SecKeychainCopyDefault(&keychain);
	
	SecIdentitySearchCreate(keychain, CSSM_KEYUSE_ANY, &searchRef);
	
	SecIdentityRef currentIdentityRef = NULL;
	while(searchRef && (SecIdentitySearchCopyNext(searchRef, &currentIdentityRef) != errSecItemNotFound))
	{
		// Extract the private key from the identity, and examine it to see if it will work for us
		SecKeyRef privateKeyRef = NULL;
		SecIdentityCopyPrivateKey(currentIdentityRef, &privateKeyRef);
		
		if(privateKeyRef)
		{
			// Get the name attribute of the private key
			// We're looking for a private key with the name of "Mojo User"
			
			SecItemAttr itemAttributes[] = {kSecKeyPrintName};
			
			SecExternalFormat externalFormats[] = {kSecFormatUnknown};
			
			int itemAttributesSize  = sizeof(itemAttributes) / sizeof(*itemAttributes);
			int externalFormatsSize = sizeof(externalFormats) / sizeof(*externalFormats);
			NSAssert(itemAttributesSize == externalFormatsSize, @"Arrays must have identical counts!");
			
			SecKeychainAttributeInfo info = {itemAttributesSize, (void *)&itemAttributes, (void *)&externalFormats};
			
			SecKeychainAttributeList *privateKeyAttributeList = NULL;
			SecKeychainItemCopyAttributesAndData((SecKeychainItemRef)privateKeyRef,
			                                     &info, NULL, &privateKeyAttributeList, NULL, NULL);
			
			if(privateKeyAttributeList)
			{
				SecKeychainAttribute nameAttribute = privateKeyAttributeList->attr[0];
				
				NSString *name = [[[NSString alloc] initWithBytes:nameAttribute.data
														   length:(nameAttribute.length)
														 encoding:NSUTF8StringEncoding] autorelease];
				
				// Ugly Hack
				// For some reason, name sometimes contains odd characters at the end of it
				// I'm not sure why, and I don't know of a proper fix, thus the use of the hasPrefix: method
				if([name hasPrefix: @"com.osirixviewer.osirixwebserver"])
				{
					// It's possible for there to be more than one private key with the above prefix
					// But we're only allowed to have one identity, so we make sure to only add one to the array
					if([result count] == 0)
					{
						[result addObject:(id)currentIdentityRef];
					}
				}
				
				SecKeychainItemFreeAttributesAndData(privateKeyAttributeList, NULL);
			}
			
			CFRelease(privateKeyRef);
		}
		
		CFRelease(currentIdentityRef);
	}
	
	if(keychain)  CFRelease(keychain);
	if(searchRef) CFRelease(searchRef);
	
	return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Creates (if necessary) and returns a temporary directory for the application.
 *
 * A general temporary directory is provided for each user by the OS.
 * This prevents conflicts between the same application running on multiple user accounts.
 * We take this a step further by putting everything inside another subfolder, identified by our application name.
**/
+ (NSString *)applicationTemporaryDirectory
{
	NSString *userTempDir = NSTemporaryDirectory();
	NSString *appTempDir = [userTempDir stringByAppendingPathComponent:@"OsiriX HTTP Server"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:appTempDir] == NO)
	{
		[fileManager createDirectoryAtPath:appTempDir attributes:nil];
	}
	
	return appTempDir;
}

/**
 * Simple utility class to convert a SecExternalFormat into a string suitable for printing/logging.
**/
+ (NSString *)stringForSecExternalFormat:(SecExternalFormat)extFormat
{
	switch(extFormat)
	{
		case kSecFormatUnknown              : return @"kSecFormatUnknown";
			
		/* Asymmetric Key Formats */
		case kSecFormatOpenSSL              : return @"kSecFormatOpenSSL";
		case kSecFormatSSH                  : return @"kSecFormatSSH - Not Supported";
		case kSecFormatBSAFE                : return @"kSecFormatBSAFE";
			
		/* Symmetric Key Formats */
		case kSecFormatRawKey               : return @"kSecFormatRawKey";
			
		/* Formats for wrapped symmetric and private keys */
		case kSecFormatWrappedPKCS8         : return @"kSecFormatWrappedPKCS8";
		case kSecFormatWrappedOpenSSL       : return @"kSecFormatWrappedOpenSSL";
		case kSecFormatWrappedSSH           : return @"kSecFormatWrappedSSH - Not Supported";
		case kSecFormatWrappedLSH           : return @"kSecFormatWrappedLSH - Not Supported";
			
		/* Formats for certificates */
		case kSecFormatX509Cert             : return @"kSecFormatX509Cert";
			
		/* Aggregate Types */
		case kSecFormatPEMSequence          : return @"kSecFormatPEMSequence";
		case kSecFormatPKCS7                : return @"kSecFormatPKCS7";
		case kSecFormatPKCS12               : return @"kSecFormatPKCS12";
		case kSecFormatNetscapeCertSequence : return @"kSecFormatNetscapeCertSequence";
			
		default                             : return @"Unknown";
	}
}

/**
 * Simple utility class to convert a SecExternalItemType into a string suitable for printing/logging.
**/
+ (NSString *)stringForSecExternalItemType:(SecExternalItemType)itemType
{
	switch(itemType)
	{
		case kSecItemTypeUnknown     : return @"kSecItemTypeUnknown";
			
		case kSecItemTypePrivateKey  : return @"kSecItemTypePrivateKey";
		case kSecItemTypePublicKey   : return @"kSecItemTypePublicKey";
		case kSecItemTypeSessionKey  : return @"kSecItemTypeSessionKey";
		case kSecItemTypeCertificate : return @"kSecItemTypeCertificate";
		case kSecItemTypeAggregate   : return @"kSecItemTypeAggregate";
		
		default                      : return @"Unknown";
	}
}

/**
 * Simple utility class to convert a SecKeychainAttrType into a string suitable for printing/logging.
**/
+ (NSString *)stringForSecKeychainAttrType:(SecKeychainAttrType)attrType
{
	switch(attrType)
	{
		case kSecCreationDateItemAttr       : return @"kSecCreationDateItemAttr";
		case kSecModDateItemAttr            : return @"kSecModDateItemAttr";
		case kSecDescriptionItemAttr        : return @"kSecDescriptionItemAttr";
		case kSecCommentItemAttr            : return @"kSecCommentItemAttr";
		case kSecCreatorItemAttr            : return @"kSecCreatorItemAttr";
		case kSecTypeItemAttr               : return @"kSecTypeItemAttr";
		case kSecScriptCodeItemAttr         : return @"kSecScriptCodeItemAttr";
		case kSecLabelItemAttr              : return @"kSecLabelItemAttr";
		case kSecInvisibleItemAttr          : return @"kSecInvisibleItemAttr";
		case kSecNegativeItemAttr           : return @"kSecNegativeItemAttr";
		case kSecCustomIconItemAttr         : return @"kSecCustomIconItemAttr";
		case kSecAccountItemAttr            : return @"kSecAccountItemAttr";
		case kSecServiceItemAttr            : return @"kSecServiceItemAttr";
		case kSecGenericItemAttr            : return @"kSecGenericItemAttr";
		case kSecSecurityDomainItemAttr     : return @"kSecSecurityDomainItemAttr";
		case kSecServerItemAttr             : return @"kSecServerItemAttr";
		case kSecAuthenticationTypeItemAttr : return @"kSecAuthenticationTypeItemAttr";
		case kSecPortItemAttr               : return @"kSecPortItemAttr";
		case kSecPathItemAttr               : return @"kSecPathItemAttr";
		case kSecVolumeItemAttr             : return @"kSecVolumeItemAttr";
		case kSecAddressItemAttr            : return @"kSecAddressItemAttr";
		case kSecSignatureItemAttr          : return @"kSecSignatureItemAttr";
		case kSecProtocolItemAttr           : return @"kSecProtocolItemAttr";
		case kSecCertificateType            : return @"kSecCertificateType";
		case kSecCertificateEncoding        : return @"kSecCertificateEncoding";
		case kSecCrlType                    : return @"kSecCrlType";
		case kSecCrlEncoding                : return @"kSecCrlEncoding";
		case kSecAlias                      : return @"kSecAlias";
		default                             : return @"Unknown";
	}
}

+ (NSString *)stringForError:(OSStatus)status;
{
	CFStringRef msg = SecCopyErrorMessageString(status, NULL);
	NSString *errorMsg = [NSString stringWithString:(NSString*)msg];
	CFRelease(msg);
	
	return errorMsg;
}

# pragma mark Keychain Access


+ (NSArray *)KeychainAccessCertificatesList {
    CFArrayRef searchList;
    SecKeychainCopySearchList (&searchList);
    
    CFTypeRef   arrayRef     = NULL;
    NSDictionary * dict = @{
                            (id) kSecClass: (id) kSecClassIdentity,
                            (id) kSecMatchLimit: (id) kSecMatchLimitAll,
                            (id) kSecReturnAttributes: (id) kCFBooleanTrue,
                            (id) kSecReturnRef: (id) kCFBooleanTrue,
                            };
    
    OSStatus err = SecItemCopyMatching((CFDictionaryRef) dict, &arrayRef);

    if (err != errSecSuccess) {
        if (err == errSecItemNotFound)
            return [NSArray array];
        NSLog(@"%@:%s: SecItemCopyMatching failed: %@", [[self class] description],
              __PRETTY_FUNCTION__, [DDKeychain stringForError:err]);
        return nil;
    }
    
    NSMutableArray * found = [NSMutableArray array];
    
    for(int i = 0; i < CFArrayGetCount(arrayRef); i++) {
        NSDictionary * attr = (__bridge NSDictionary *)(CFArrayGetValueAtIndex(arrayRef, i));
        NSString * label = (NSString *)[attr objectForKey:kSecAttrLabel];
        
        if (YES)  {
            SecIdentityRef identityRef = (__bridge SecIdentityRef)([attr objectForKey:kSecValueRef]);
            SecCertificateRef certRef;
            err = SecIdentityCopyCertificate(identityRef, &certRef);
            if (err != errSecSuccess) {
                NSLog(@"%@:%s: SecIdentityCopyCertificate failed: %@ (skipping %@)", [[self class] description],
                      __PRETTY_FUNCTION__, [DDKeychain stringForError:err], identityRef);
                goto skip;
            }

            NSDictionary * valRef = CFBridgingRelease(SecCertificateCopyValues(certRef, nil, nil));

#if 0
            SecKeychainRef keychainRef;
            err = SecKeychainItemCopyKeychain((SecKeychainItemRef)identityRef, &keychainRef);
            if (err != errSecSuccess) {
                NSLog(@"%@:%s: SecKeychainItemCopyKeychain failed: %@ (skipping %@)", [[self class] description],
                      __PRETTY_FUNCTION__, [DDKeychain stringForError:err], identityRef);
                goto skip;
            };
            
            char path[PATH_MAX];
            UInt32 len = sizeof(path);
            err = SecKeychainGetPath(keychainRef, &len, path);
            if (err != errSecSuccess) {
                NSLog(@"%@:%s: SecKeychainGetPath failed: %@ (skipping %@)", [[self class] description],
                      __PRETTY_FUNCTION__, [DDKeychain stringForError:err], identityRef);
                goto skip;
            };
            NSLog(@"%@: %s",[valRef objectForKey:(__bridge id)(kSecOIDCommonName)], path);
#endif
            
            // Skip certs which cannot be used. Page 29 of ITU-T Rec. X.509 (11/2008):
            //
            // KeyUsage  ::=  BIT STRING {
            //    digitalSignature  (0),
            //    contentCommitment (1),
            //    keyEncipherment   (2),
            //    dataEncipherment  (3),
            //    keyAgreement      (4),
            //    keyCertSign       (5),
            //    cRLSign           (6),
            //    encipherOnly      (7),
            //    decipherOnly      (8),
            //
            NSDictionary * keyUsage = [valRef objectForKey:(__bridge id)(kSecOIDKeyUsage)];
            NSInteger flag = keyUsage ? [[keyUsage objectForKey:@"value"] integerValue] : 0;
            
            CFBooleanRef invisible = (CFBooleanRef) [valRef objectForKey:(__bridge id)(kSecAttrIsInvisible)];
            
            // Value of 0 is implies any use - seems to be passed by apple if none is set.
            //
            if (invisible == kCFBooleanTrue)
                goto skip;
            
            if ((flag != 0)&& ((flag & 1) == 0))
                goto skip;
                
                [found addObject:(__bridge id)(identityRef)];
        skip:
            CFRelease(certRef);
        }
    };
    if (arrayRef)
        CFRelease(arrayRef);
    if (searchList)
        CFRelease(searchList);

    return found;
}

+ (void)KeychainAccessExportTrustedCertificatesToDirectory:(NSString*)directory;
{
	BOOL isDirectory, directoryExists;
	
	directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory];
	if(directoryExists) return;
	if(!directoryExists)[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:nil];
		
	int domains[3] = {kSecTrustSettingsDomainUser, kSecTrustSettingsDomainAdmin, kSecTrustSettingsDomainSystem};
	
	CFArrayRef certArray = NULL;
	OSStatus status;
	CFIndex numCerts, dex;
	int i;
	for (i=0; i<3; i++)
	{
		status = SecTrustSettingsCopyCertificates(domains[i], &certArray);
		if(status) cssmPerror("SecTrustSettingsCopyCertificates", status);
		
		if( certArray)
		{
			numCerts = CFArrayGetCount(certArray);

			for(dex=0; dex<numCerts; dex++)
			{
				SecCertificateRef certRef = (SecCertificateRef)CFArrayGetValueAtIndex(certArray, dex);			
				CFDataRef certificateDataRef = NULL;
				status = SecKeychainItemExport(certRef, kSecFormatX509Cert, kSecItemPemArmour, NULL, &certificateDataRef);
				
				if(status==0)
				{
					NSString *path = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d_%d.pem", i, (int) dex]];
					if(![[NSFileManager defaultManager] fileExistsAtPath:path])
						[(NSData*)certificateDataRef writeToFile:path atomically:YES];
				}
				else NSLog(@"SecKeychainItemExport : error : %@", [DDKeychain stringForError:status]);
				
			}
			
			CFRelease(certArray);
			certArray = NULL;
		}
	}
}

// Returns a reference to the preferred identity, or NULL if none was found.
// Call the CFRelease function to release this object when you are finished with it.
+ (SecIdentityRef)KeychainAccessPreferredIdentityForName:(NSString*)name keyUse:(int)keyUse;
{
	SecIdentityRef identity = NULL;
	OSStatus status = SecIdentityCopyPreference((CFStringRef)name, keyUse, NULL, &identity);
	if(status!=0) NSLog(@"KeychainAccessPreferredIdentityForName:%@ keyUse: error: %@", name, [DDKeychain stringForError:status]);
	return identity;
}

+ (void)KeychainAccessSetPreferredIdentity:(SecIdentityRef)identity forName:(NSString*)name keyUse:(int)keyUse;
{
	if(identity)
	{
		OSStatus status = SecIdentitySetPreference(identity, (CFStringRef)name, keyUse);
		if(status!=0) NSLog(@"KeychainAccessSetPreferredIdentity:forName:keyUse: error: %@", [DDKeychain stringForError:status]);
	}
}	

+ (NSString*)KeychainAccessCertificateCommonNameForIdentity:(SecIdentityRef)identity;
{
	NSString *name = nil;
	if(identity)
	{		
		SecCertificateRef certificateRef = NULL;
		SecIdentityCopyCertificate(identity, &certificateRef);
		if(certificateRef)
		{
			CFStringRef commonName = NULL;
			OSStatus status = SecCertificateCopyCommonName(certificateRef, &commonName);
			if(status==0)
			{
				name = [NSString stringWithString:(NSString*)commonName];
				CFRelease(commonName);
			}
			else NSLog(@"KeychainAccessCertificateCommonNameForIdentity: error: %@", [DDKeychain stringForError:status]);
			
			CFRelease(certificateRef);
		}		
	}	
	return name;
}

/*
 * The following method returns the correct icon for a certificate:
 *	- the blue icon for "Standard certificates"
 *	- the gold icon for "Self signed certificates"
 *
 *	The hypothese is : if the subject == the issuer then it is a Self signed certificate
 *	It _seems_ to work (Joris)
 */
+ (NSImage*)KeychainAccessCertificateIconForIdentity:(SecIdentityRef)identity;
{
	NSImage *icon = nil;
	
	if(identity)
	{	
		SecCertificateRef certificateRef = NULL;
		SecIdentityCopyCertificate(identity, &certificateRef);	
		if(certificateRef)
		{
			const CSSM_X509_NAME *subject, *issuer;
			SecCertificateGetSubject(certificateRef, &subject);
			SecCertificateGetIssuer(certificateRef, &issuer);
			
			BOOL equal = YES;
			if(subject->numberOfRDNs==issuer->numberOfRDNs)
			{
				int i, j;
				for (i=0; i<subject->numberOfRDNs; i++)
				{
					CSSM_X509_RDN issuerRDN = issuer->RelativeDistinguishedName[i];
					CSSM_X509_RDN subjectRDN = subject->RelativeDistinguishedName[i];
										
					if(issuerRDN.numberOfPairs==subjectRDN.numberOfPairs)
					{
						for (j=0; j<subjectRDN.numberOfPairs; j++)
						{
							CSSM_X509_TYPE_VALUE_PAIR issuerVP = issuerRDN.AttributeTypeAndValue[j];
							CSSM_X509_TYPE_VALUE_PAIR subjectVP = subjectRDN.AttributeTypeAndValue[j];

							NSData *issuerVPData = [NSData dataWithBytes:issuerVP.value.Data length:issuerVP.value.Length];
							NSData *subjectVPData = [NSData dataWithBytes:subjectVP.value.Data length:subjectVP.value.Length];
							
							if ([issuerVPData isEqualToData:subjectVPData])
								equal &= YES;
							else
							{
								equal = NO;
								break;
							}
						}
					}
					else
					{
						equal = NO;
						break;
					}
				}
			}
			else
				equal = NO;

			CFRelease(certificateRef);
			
			if(equal)
			{
				// Self signed certificate
				icon = [NSImage imageNamed:@"CertSmallRoot.tif"];
			}
			else 
			{
				// Standard certificate
				icon = [NSImage imageNamed:@"CertSmallStd.tif"];
			}
		}	
	}	
	return icon;
}

+ (NSArray*)KeychainAccessCertificateChainForIdentity:(SecIdentityRef)identity;
{
	OSStatus status;
    NSArray *returnedValue = nil;
    
	if(identity)
	{		
		SecCertificateRef certificateRef = NULL;
		SecIdentityCopyCertificate(identity, &certificateRef);
		
		if(certificateRef)
		{
			SecPolicyRef sslPolicy = NULL;		
			status = SSLSecPolicyCopy(&sslPolicy);
			
			if(status==0)
			{
				if(sslPolicy)
				{
					SecTrustRef trust = NULL;
					status = SecTrustCreateWithCertificates((CFArrayRef)[NSArray arrayWithObject:(id)certificateRef], sslPolicy, &trust);
					if(status==0)
					{
						SecTrustResultType result;
						status = SecTrustEvaluate(trust, &result);
						
						if(status==0)
						{
							CFArrayRef certChain;
							CSSM_TP_APPLE_EVIDENCE_INFO *statusChain;
							status = SecTrustGetResult(trust, &result, &certChain, &statusChain);
							if(status==0)
							{
								NSArray *certificatesChain = [NSArray arrayWithArray:(NSArray*)certChain];
								CFRelease(certChain);
								returnedValue = certificatesChain;
							}
							else NSLog(@"SecTrustGetResult : error : %@", [DDKeychain stringForError:status]);
						}
						else NSLog(@"SecTrustEvaluate : error : %@", [DDKeychain stringForError:status]);	
						
						CFRelease(trust);
					}
					else NSLog(@"SecTrustCreateWithCertificates : error : %@", [DDKeychain stringForError:status]);

					CFRelease(sslPolicy);
				}
			}
			else NSLog(@"SSLSecPolicyCopy : error : %@", [DDKeychain stringForError:status]);

			CFRelease(certificateRef);
		}
	}
	return returnedValue;
}

+ (void)KeychainAccessExportCertificateForIdentity:(SecIdentityRef)identity toPath:(NSString*)path;
{
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) return;
	
	SecCertificateRef certificate = NULL;
	OSStatus status = SecIdentityCopyCertificate(identity, &certificate);
	if(status==0)
	{
		CFDataRef certificateDataRef = NULL;
		status = SecKeychainItemExport(certificate, kSecFormatX509Cert, kSecItemPemArmour, NULL, &certificateDataRef);
		
		if(status==0)
		{
			[(NSData*)certificateDataRef writeToFile:path atomically:YES];
		}
		else NSLog(@"SecKeychainItemExport : error : %@", [DDKeychain stringForError:status]);
		
		CFRelease(certificate);	
	}
	else NSLog(@"SecIdentityCopyCertificate : error : %@", [DDKeychain stringForError:status]);	
}

+ (void)KeychainAccessExportPrivateKeyForIdentity:(SecIdentityRef)identity toPath:(NSString*)path cryptWithPassword:(NSString*)password;
{
	if([[NSFileManager defaultManager] fileExistsAtPath:path]) return;
		
	SecKeyRef privateKey = NULL;
	OSStatus status = SecIdentityCopyPrivateKey(identity, &privateKey);
	if(status==0)
	{
		CFDataRef privateKeyDataRef = NULL;
		SecKeyImportExportParameters exportParameters = {.passphrase=(CFStringRef)password};
		
		status = SecKeychainItemExport(privateKey, kSecFormatPKCS12, 0, &exportParameters, &privateKeyDataRef);
		
		if(status==0)
		{
			[(NSData*)privateKeyDataRef writeToFile:[path stringByAppendingPathExtension:@"p12"] atomically:YES];
			
			// convert the private key file from PKCS#12 format to PEM format:
			// $ openssl pkcs12 -in key.p12 -out key.pem -passin pass:passwordIN -passout pass:passwordOUT
			
			NSArray *args = [NSArray arrayWithObjects:	@"pkcs12",
							 @"-in", [path stringByAppendingPathExtension:@"p12"],
							 @"-out", path,
							 @"-passin", [NSString stringWithFormat:@"pass:%@", password],
							 @"-passout", [NSString stringWithFormat:@"pass:%@", password], nil];
			
			NSTask *convertTask = [[[NSTask alloc] init] autorelease];
			[convertTask setLaunchPath:@"/usr/bin/openssl"];
			[convertTask setArguments:args];
			[convertTask launch];
			
            while( [convertTask isRunning])
                [NSThread sleepForTimeInterval: 0.1];
            
			[[NSFileManager defaultManager] removeFileAtPath:[path stringByAppendingPathExtension:@"p12"] handler:nil]; // remove the .p12 file
		}
		else NSLog(@"SecKeychainItemExport : error : %@", [DDKeychain stringForError:status]);
		
		CFRelease(privateKey);
	}
	else NSLog(@"SecIdentityCopyPrivateKey : error : %@", [DDKeychain stringForError:status]);			
}

+ (void)KeychainAccessOpenCertificatePanelForIdentity:(SecIdentityRef)identity;
{
	if(identity)
	{		
		SecCertificateRef certificateRef = NULL;
		SecIdentityCopyCertificate(identity, &certificateRef);
		if(certificateRef)
		{
			NSMutableArray *certificates = [NSMutableArray arrayWithObject:(id)certificateRef];
			NSArray *certificateChain = [DDKeychain KeychainAccessCertificateChainForIdentity:identity];
			[certificates addObjectsFromArray:certificateChain];
			
			[[SFCertificatePanel sharedCertificatePanel] runModalForCertificates:certificates showGroup:YES];		
			CFRelease(certificateRef);
		}
	}
}

#pragma mark-

// Returns a reference to the preferred identity for DICOM TLS, or NULL if none was found.
// Call the CFRelease function to release this object when you are finished with it.
+ (SecIdentityRef)identityForLabel:(NSString*)label;
{
	return [DDKeychain KeychainAccessPreferredIdentityForName:label keyUse:CSSM_KEYUSE_ANY];
}

+ (NSString*)certificateNameForLabel:(NSString*)label;
{
	SecIdentityRef identity = [DDKeychain identityForLabel:label];
	
	NSString *name = nil;
	if(identity)
	{
		name = [NSString stringWithString:[DDKeychain KeychainAccessCertificateCommonNameForIdentity:identity]];
		CFRelease(identity);
	}
	
	return name;
}

+ (NSImage*)certificateIconForLabel:(NSString*)label;
{
	SecIdentityRef identity = [DDKeychain identityForLabel:label];
	
	NSImage *icon = nil;
	if(identity)
	{
		icon = [DDKeychain KeychainAccessCertificateIconForIdentity:identity];
		CFRelease(identity);
	}
	
	return icon;
}

+ (void)openCertificatePanelForLabel:(NSString*)label;
{
	SecIdentityRef identity = [DDKeychain identityForLabel:label];
	if(identity)
	{
		[DDKeychain KeychainAccessOpenCertificatePanelForIdentity:identity];
		CFRelease(identity);
	}
}

#pragma mark Other Utilities

+ (void)generatePseudoRandomFileToPath:(NSString*)path;
{
	NSPoint mouseLocation = [NSEvent mouseLocation];
	NSTimeInterval time = [[NSDate date] timeIntervalSince1970];

	NSString *string = [NSString stringWithFormat:@"%f%f%lf", mouseLocation.x, mouseLocation.y, time];
	[string writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)lockFile:(NSString*)path;
{
	if(!lockedFiles) lockedFiles = [[NSMutableDictionary dictionary] retain];
	
	@synchronized( lockedFiles)
	{
		int n=0;
		
		if([[lockedFiles allKeys] containsObject:path])
		{
			n = [(NSNumber*)[lockedFiles objectForKey:path] intValue];
		}
		
		[lockedFiles setObject:[NSNumber numberWithInt:n+1] forKey:path];
		NSLog(@"lockFile: %d %@", n+1, path);
	}
}

+ (void)unlockFile:(NSString*)path;
{	
	@synchronized( lockedFiles)
	{
		int n=0;
		
		if(lockedFiles)
		{
			if([[lockedFiles allKeys] containsObject:path])
			{
				n = [(NSNumber*)[lockedFiles objectForKey:path] intValue];
				n--;
				[lockedFiles setObject:[NSNumber numberWithInt:n] forKey:path];
				NSLog(@"unlockFile: %d %@", n, path);
			}
		}
		
		if(n==0)
		{
			[lockedFiles removeObjectForKey:path];
			//[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			//NSLog(@"removeFileAtPath: %@", path);
		}
	}
}

+ (void)lockTmpFiles;
{
	if(!lockFile) lockFile = [[NSRecursiveLock alloc] init];
	
	[lockFile lock];
}

+ (void)unlockTmpFiles;
{
	[lockFile unlock];
	//NSString *cmd = [NSString stringWithFormat:@"rm %@* %@*", TLS_PRIVATE_KEY_FILE, TLS_CERTIFICATE_FILE];
	//system([cmd cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
