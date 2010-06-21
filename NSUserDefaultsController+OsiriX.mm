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


@implementation NSUserDefaultsController (OsiriX)

#pragma mark Bonjour Sharing

NSString* const OsirixBonjourSharingActiveFlagDefaultsKey = @"bonjourSharing";

+(BOOL)isBonjourSharingActive {
	return [[self sharedUserDefaultsController] boolForKey:OsirixBonjourSharingActiveFlagDefaultsKey];
}

NSString* const OsirixBonjourSharingNameDefaultsKey = @"bonjourServiceName";

+(NSString*)bonjourSharingName {
	NSString* r = [[self sharedUserDefaultsController] stringForKey:OsirixBonjourSharingNameDefaultsKey];
	if (!r) return [self defaultBonjourSharingName];
	return r;
}

+(NSString*)defaultBonjourSharingName {
	char s[_POSIX_HOST_NAME_MAX+1];
	gethostname(s, _POSIX_HOST_NAME_MAX);
	
	NSString* c = [NSString stringWithUTF8String:s];
	
	NSRange range = [c rangeOfString: @"."];
	if (range.location != NSNotFound)
		c = [c substringToIndex:range.location];
	
	return c;
}

NSString* const OsirixBonjourSharingPasswordFlagDefaultsKey = @"bonjourPasswordProtected";

+(BOOL)isBonjourSharingPasswordProtected {
	return [[self sharedUserDefaultsController] boolForKey:OsirixBonjourSharingPasswordFlagDefaultsKey];
}

NSString* const OsirixBonjourSharingPasswordDefaultsKey = @"bonjourPassword";

+(NSString*)bonjourSharingPassword {
	return [self isBonjourSharingPasswordProtected]? [[self sharedUserDefaultsController] stringForKey:OsirixBonjourSharingPasswordDefaultsKey] : NULL;
}

#pragma mark Other

NSString* const OsirixWLWWDefaultsKey = @"WLWW3";
NSString* OsirixActivityWindowVisibleDefaultsKey = @"ActivityWindowVisibleFlag";

@end
