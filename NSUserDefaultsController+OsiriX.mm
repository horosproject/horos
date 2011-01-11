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
#import "NSUserDefaults+OsiriX.h"


@implementation NSUserDefaultsController (OsiriX)
@end

@implementation NSUserDefaultsController (Deprecated)

NSString* const OsirixBonjourSharingActiveFlagDefaultsKey = OsirixBonjourSharingIsActiveDefaultsKey;
NSString* const OsirixBonjourSharingPasswordFlagDefaultsKey = OsirixBonjourSharingIsPasswordProtectedDefaultsKey;
NSString* const OsirixWebServerUsesWeasisDefaultsKey = OsirixWebPortalUsesWeasisDefaultsKey;
NSString* const OsirixWadoServerActiveDefaultsKey = OsirixWadoServiceEnabledDefaultsKey;
NSString* const OsirixWebServerPrefersFlashDefaultsKey = OsirixWebPortalPrefersFlashDefaultsKey;
NSString* const OsirixWebServerPrefersCustomWebPagesKey = OsirixWebPortalPrefersCustomWebPagesKey;

+(BOOL)IsBonjourSharingActive {
	return NSUserDefaults.bonjourSharingIsActive;
}

+(BOOL)IsBonjourSharingPasswordProtected {
	return NSUserDefaults.bonjourSharingIsPasswordProtected;
}

+(NSString*)BonjourSharingPassword {
	return NSUserDefaults.bonjourSharingPassword;
}

+(NSString*)BonjourSharingName {
	return NSUserDefaults.bonjourSharingName;
}

+(NSString*)DefaultBonjourSharingName {
	return NSUserDefaults.defaultBonjourSharingName;
}

+(BOOL)WebServerUsesWeasis {
	return NSUserDefaults.webPortalUsesWeasis;
}

+(BOOL)WadoServerActive {
	return NSUserDefaults.wadoServiceEnabled;
}

+(BOOL)WebServerPrefersFlash {
	return NSUserDefaults.webPortalPrefersFlash;
}

+(BOOL)WebServerPrefersCustomWebPages {
	return NSUserDefaults.webPortalPrefersCustomWebPages;
}

@end