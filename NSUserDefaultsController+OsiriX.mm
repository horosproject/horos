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

#import "NSUserDefaultsController+OsiriX.h"
#import "NSUserDefaultsController+N2.h"


@interface NSUserDefaultsControllerOsirixHelper : NSObject
@end
@implementation NSUserDefaultsControllerOsirixHelper

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	if ([keyPath isEqual:valuesKeyPath(OsirixWadoServerActiveDefaultsKey)]) {
		if (![defaults boolForKey:OsirixWadoServerActiveDefaultsKey])
			[defaults setBool:NO forKey:OsirixWebServerUsesWeasisDefaultsKey];	
	}
}

@end


@implementation NSUserDefaultsController (OsiriX)

#pragma mark Bonjour Sharing

NSString* const OsirixBonjourSharingActiveFlagDefaultsKey = @"bonjourSharing";

+(BOOL)IsBonjourSharingActive {
	return [[self sharedUserDefaultsController] boolForKey:OsirixBonjourSharingActiveFlagDefaultsKey];
}

NSString* const OsirixBonjourSharingNameDefaultsKey = @"bonjourServiceName";

+(NSString*)BonjourSharingName {
	NSString* r = [[self sharedUserDefaultsController] stringForKey:OsirixBonjourSharingNameDefaultsKey];
	if (!r) r = [self DefaultBonjourSharingName];
	return r;
}

+(NSString*)DefaultBonjourSharingName {
	char s[_POSIX_HOST_NAME_MAX+1];
	gethostname(s, _POSIX_HOST_NAME_MAX);
	
	NSString* r = [NSString stringWithUTF8String:s];
	
	NSRange range = [r rangeOfString: @"."];
	if (range.location != NSNotFound)
		r = [r substringToIndex:range.location];
	
	return r;
}

NSString* const OsirixBonjourSharingPasswordFlagDefaultsKey = @"bonjourPasswordProtected";

+(BOOL)IsBonjourSharingPasswordProtected {
	return [[self sharedUserDefaultsController] boolForKey:OsirixBonjourSharingPasswordFlagDefaultsKey];
}

NSString* const OsirixBonjourSharingPasswordDefaultsKey = @"bonjourPassword";

+(NSString*)BonjourSharingPassword {
	return [self IsBonjourSharingPasswordProtected]? [[self sharedUserDefaultsController] stringForKey:OsirixBonjourSharingPasswordDefaultsKey] : NULL;
}

NSString* const OsirixWebServerUsesWeasisDefaultsKey = @"WebServerUsesWeasis";

+(BOOL)WebServerUsesWeasis {
	return [[NSUserDefaultsController sharedUserDefaultsController] boolForKey:OsirixWebServerUsesWeasisDefaultsKey];
}

NSString* const OsirixWadoServerActiveDefaultsKey = @"wadoServer";

+(BOOL)WadoServerActive {
	return [[NSUserDefaultsController sharedUserDefaultsController] boolForKey:OsirixWadoServerActiveDefaultsKey];
}

NSString* const OsirixWebServerPrefersFlashDefaultsKey = @"WebServerPrefersFlash";

+(BOOL)WebServerPrefersFlash {
	return [[NSUserDefaultsController sharedUserDefaultsController] boolForKey:OsirixWebServerPrefersFlashDefaultsKey];
}

@end
