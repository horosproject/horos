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

#import <Cocoa/Cocoa.h>


@interface NSUserDefaultsController (OsiriX)

#pragma mark Bonjour Sharing

extern NSString* const OsirixBonjourSharingActiveFlagDefaultsKey;
+(BOOL)IsBonjourSharingActive;

extern NSString* const OsirixBonjourSharingNameDefaultsKey;
+(NSString*)BonjourSharingName;
+(NSString*)DefaultBonjourSharingName;

extern NSString* const OsirixBonjourSharingPasswordFlagDefaultsKey;
+(BOOL)IsBonjourSharingPasswordProtected;

extern NSString* const OsirixBonjourSharingPasswordDefaultsKey;
+(NSString*)BonjourSharingPassword;

extern NSString* const OsirixWebServerUsesWeasisDefaultsKey;
+(BOOL)WebServerUsesWeasis;

extern NSString* const OsirixWadoServerActiveDefaultsKey;
+(BOOL)WadoServerActive;

extern NSString* const OsirixWebServerPrefersFlashDefaultsKey;
+(BOOL)WebServerPrefersFlash;

@end
