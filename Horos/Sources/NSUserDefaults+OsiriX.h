/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import <Cocoa/Cocoa.h>
#import "NSUserDefaultsController+OsiriX.h"


@interface NSUserDefaults (OsiriX)

#pragma mark General

extern NSString* const OsirixDateTimeFormatDefaultsKey;
+(NSDateFormatter*)dateTimeFormatter;
+(NSString*)formatDateTime:(NSDate*)date;

extern NSString* const OsirixDateFormatDefaultsKey;
+(NSDateFormatter*)dateFormatter;
+(NSString*)formatDate:(NSDate*)date;

extern NSString* const OsirixCanActivateDefaultDatabaseOnlyDefaultsKey;
+(BOOL)canActivateOnlyDefaultDatabase;
+(BOOL)canActivateAnyLocalDatabase;

extern NSString* const O2NonViewerScreensDefaultsKey;
#ifdef OSIRIX_VIEWER
-(NSArray*)screensUsedForViewers;
-(BOOL)screenIsUsedForViewers:(NSScreen*)screen;
-(void)screen:(NSScreen*)screen setIsUsedForViewers:(BOOL)flag;
#endif

#pragma mark Bonjour Sharing

extern NSString* const OsirixBonjourSharingIsActiveDefaultsKey;
+(BOOL)bonjourSharingIsActive;

extern NSString* const OsirixBonjourSharingNameDefaultsKey;
+(NSString*)bonjourSharingName;
+(NSString*)defaultBonjourSharingName;

extern NSString* const OsirixBonjourSharingIsPasswordProtectedDefaultsKey;
+(BOOL)bonjourSharingIsPasswordProtected;

extern NSString* const OsirixBonjourSharingPasswordDefaultsKey;
+(NSString*)bonjourSharingPassword;

#pragma mark Web Portal

extern NSString* const OsirixWebPortalEnabledDefaultsKey;
+(BOOL)webPortalEnabled;

extern NSString* const OsirixWebPortalAddressDefaultsKey;
+(NSString*)webPortalAddress;
+(NSString*)defaultWebPortalAddress;

extern NSString* const OsirixWebPortalPortNumberDefaultsKey;
+(NSInteger)webPortalPortNumber;
+(NSInteger)defaultWebPortalPortNumber;

extern NSString* const OsirixWebPortalUsesSSLDefaultsKey;
+(BOOL)webPortalUsesSSL;

extern NSString* const OsirixWebPortalUsesWeasisDefaultsKey;
+(BOOL)webPortalUsesWeasis;

extern NSString* const OsirixWadoServiceEnabledDefaultsKey;
+(BOOL)wadoServiceEnabled;

extern NSString* const OsirixWebPortalPrefersFlashDefaultsKey;
+(BOOL)webPortalPrefersFlash;

extern NSString* const OsirixWebPortalPrefersCustomWebPagesKey;
+(BOOL)webPortalPrefersCustomWebPages;

extern NSString* const OsirixWebPortalNotificationsEnabledDefaultsKey;
+(BOOL)webPortalNotificationsEnabled;

extern NSString* const OsirixWebPortalNotificationsIntervalDefaultsKey;
+(NSInteger)webPortalNotificationsInterval;

extern NSString* const OsirixWebPortalRequiresAuthenticationDefaultsKey;
+(BOOL)webPortalRequiresAuthentication;

extern NSString* const OsirixWebPortalUsersCanRestorePasswordDefaultsKey;
+(BOOL)webPortalUsersCanRestorePassword;

// MARK: DICOM Communications

+ (NSString*)defaultAETitle;
+ (int)defaultAEPort;

@end
