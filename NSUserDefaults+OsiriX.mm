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

#import "NSUserDefaults+OsiriX.h"
#import "N2Shell.h"
#import <Foundation/Foundation.h>


@implementation NSUserDefaults (OsiriX)

#pragma mark General

NSString* const OsirixDateTimeFormatDefaultsKey = @"DBDateFormat2";

+(NSString*)dateTimeFormat {
	NSString* r = [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixDateTimeFormatDefaultsKey];
	if (!r) r = [[[[NSDateFormatter alloc] init] autorelease] dateFormat];
	return r;
}

+(NSDateFormatter*)dateTimeFormatter {
	static NSDateFormatter* formatter = NULL;
	if (!formatter)
		formatter = [[NSDateFormatter alloc] init];
	
	if (![formatter.dateFormat isEqual:self.dateTimeFormat])
		formatter.dateFormat = self.dateTimeFormat;
	
	return formatter;
}

NSString* const OsirixDateFormatDefaultsKey = @"DBDateOfBirthFormat2";

+(NSString*)dateFormat {
	NSString* r = [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixDateFormatDefaultsKey];
	if (!r) r = [[[[NSDateFormatter alloc] init] autorelease] dateFormat];
	return r;
}

+(NSDateFormatter*)dateFormatter {
	static NSDateFormatter* formatter = NULL;
	if (!formatter)
		formatter = [[NSDateFormatter alloc] init];
	
	if (![formatter.dateFormat isEqual:self.dateFormat])
		formatter.dateFormat = self.dateFormat;
	
	return formatter;
}


#pragma mark Bonjour Sharing

NSString* const OsirixBonjourSharingIsActiveDefaultsKey = @"bonjourSharing";
+(BOOL)bonjourSharingIsActive {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixBonjourSharingIsActiveDefaultsKey];
}

NSString* const OsirixBonjourSharingNameDefaultsKey = @"bonjourServiceName";
+(NSString*)bonjourSharingName {
	NSString* r = [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixBonjourSharingNameDefaultsKey];
	if (!r) r = [self defaultBonjourSharingName];
	return r;
}
+(NSString*)defaultBonjourSharingName {
	char s[_POSIX_HOST_NAME_MAX+1];
	gethostname(s, _POSIX_HOST_NAME_MAX);
	
	NSString* r = [NSString stringWithUTF8String:s];
	
	NSRange range = [r rangeOfString: @"."];
	if (range.location != NSNotFound)
		r = [r substringToIndex:range.location];
	
	return r;
}

NSString* const OsirixBonjourSharingIsPasswordProtectedDefaultsKey = @"bonjourPasswordProtected";
+(BOOL)bonjourSharingIsPasswordProtected {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixBonjourSharingIsPasswordProtectedDefaultsKey];
}

NSString* const OsirixBonjourSharingPasswordDefaultsKey = @"bonjourPassword";
+(NSString*)bonjourSharingPassword {
	return self.bonjourSharingIsPasswordProtected? [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixBonjourSharingPasswordDefaultsKey] : NULL;
}

#pragma mark Web Portal

NSString* const OsirixWebPortalEnabledDefaultsKey = @"httpWebServer";
+(BOOL)webPortalEnabled {
	#ifdef OSIRIX_LIGHT
	return NO;
	#else
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalEnabledDefaultsKey];
	#endif
}

NSString* const OsirixWebPortalAddressDefaultsKey = @"webServerAddress";
+(NSString*)webPortalAddress {
	NSString* r = [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixWebPortalAddressDefaultsKey];
	if (!r.length) r = self.defaultWebPortalAddress;
	return r;
}
+(NSString*)defaultWebPortalAddress {
	return N2Shell.hostname;
}

NSString* const OsirixWebPortalPortNumberDefaultsKey = @"httpWebServerPort";
+(NSInteger)webPortalPortNumber {
	NSInteger r = [NSUserDefaultsController.sharedUserDefaultsController integerForKey:OsirixWebPortalPortNumberDefaultsKey];
	if (!r) r = self.defaultWebPortalPortNumber;
	return r;
}
+(NSInteger)defaultWebPortalPortNumber {
	return 3333;
}

NSString* const OsirixWebPortalUsesSSLDefaultsKey = @"encryptedWebServer";
+(BOOL)webPortalUsesSSL {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalUsesSSLDefaultsKey];
}

NSString* const OsirixWebPortalUsesWeasisDefaultsKey = @"WebServerUsesWeasis";
+(BOOL)webPortalUsesWeasis {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalUsesWeasisDefaultsKey];
}

NSString* const OsirixWadoServiceEnabledDefaultsKey = @"wadoServer";
+(BOOL)wadoServiceEnabled {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWadoServiceEnabledDefaultsKey];
}

NSString* const OsirixWebPortalPrefersFlashDefaultsKey = @"WebServerPrefersFlash";

+(BOOL)webPortalPrefersFlash {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalPrefersFlashDefaultsKey];
}

NSString* const OsirixWebPortalPrefersCustomWebPagesKey = @"customWebPages";
+(BOOL)webPortalPrefersCustomWebPages {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalPrefersCustomWebPagesKey];
}

NSString* const OsirixWebPortalNotificationsEnabledDefaultsKey = @"notificationsEmails";
+(BOOL)webPortalNotificationsEnabled {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalNotificationsEnabledDefaultsKey];
}

NSString* const OsirixWebPortalNotificationsIntervalDefaultsKey = @"notificationsEmailsInterval";
+(NSInteger)webPortalNotificationsInterval {
	return [NSUserDefaultsController.sharedUserDefaultsController integerForKey:OsirixWebPortalNotificationsIntervalDefaultsKey];
}

NSString* const OsirixWebPortalRequiresAuthenticationDefaultsKey = @"passwordWebServer";
+(BOOL)webPortalRequiresAuthentication {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalRequiresAuthenticationDefaultsKey];
}

NSString* const OsirixWebPortalUsersCanRestorePasswordDefaultsKey = @"restorePasswordWebServer";
+(BOOL)webPortalUsersCanRestorePassword {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalUsersCanRestorePasswordDefaultsKey];
}

// MARK: DICOM Communications

+ (NSString*)defaultAETitle;
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCPTLS"])
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCP"]
			&& ![[NSUserDefaults standardUserDefaults] boolForKey:@"TLSStoreSCPAETITLEIsDefaultAET"])
		{
			return [[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"];
		}
		return [[NSUserDefaults standardUserDefaults] stringForKey:@"TLSStoreSCPAETITLE"];
	}
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"];
}

+ (int)defaultAEPort;
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCPTLS"])
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCP"]
			&& ![[NSUserDefaults standardUserDefaults] boolForKey:@"TLSStoreSCPAETITLEIsDefaultAET"])
		{
			return [[[NSUserDefaults standardUserDefaults] stringForKey:@"AEPORT"] intValue];
		}
		return [[[NSUserDefaults standardUserDefaults] stringForKey:@"TLSStoreSCPAEPORT"] intValue];
	}
	return [[[NSUserDefaults standardUserDefaults] stringForKey:@"AEPORT"] intValue];
}

@end
