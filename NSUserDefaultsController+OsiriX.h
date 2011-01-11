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
#import "NSUserDefaultsController+N2.h"


@interface NSUserDefaultsController (OsiriX)
@end

@interface NSUserDefaultsController (Deprecated)

extern NSString* const OsirixBonjourSharingActiveFlagDefaultsKey __deprecated;
extern NSString* const OsirixBonjourSharingPasswordFlagDefaultsKey __deprecated;
extern NSString* const OsirixWebServerUsesWeasisDefaultsKey __deprecated;
extern NSString* const OsirixWadoServerActiveDefaultsKey __deprecated;
extern NSString* const OsirixWebServerPrefersFlashDefaultsKey __deprecated;
extern NSString* const OsirixWebServerPrefersCustomWebPagesKey __deprecated;

+(BOOL)IsBonjourSharingActive __deprecated;
+(BOOL)IsBonjourSharingPasswordProtected __deprecated;
+(NSString*)BonjourSharingPassword __deprecated;
+(NSString*)BonjourSharingName __deprecated;
+(NSString*)DefaultBonjourSharingName __deprecated;

+(BOOL)WebServerUsesWeasis __deprecated;
+(BOOL)WadoServerActive __deprecated;
+(BOOL)WebServerPrefersFlash __deprecated;
+(BOOL)WebServerPrefersCustomWebPages __deprecated;

@end