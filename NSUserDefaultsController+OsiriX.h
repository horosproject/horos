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
+(BOOL)isBonjourSharingActive;

extern NSString* const OsirixBonjourSharingNameDefaultsKey;
+(NSString*)bonjourSharingName;
+(NSString*)defaultBonjourSharingName;

extern NSString* const OsirixBonjourSharingPasswordFlagDefaultsKey;
+(BOOL)isBonjourSharingPasswordProtected;

extern NSString* const OsirixBonjourSharingPasswordDefaultsKey;
+(NSString*)bonjourSharingPassword;

#pragma mark Other

extern NSString* const OsirixWLWWDefaultsKey;
extern NSString* OsirixActivityWindowVisibleDefaultsKey;
extern NSString* OsirixBrowserDidResizeForDrawerSpace;

@end
