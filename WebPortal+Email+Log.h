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

#import "WebPortal.h"


@class WebPortalUser;

@interface WebPortal (EmailLog)

-(void)emailNotifications;
-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate customText:(NSString*)customText;
-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate customText:(NSString*)customText from:(WebPortalUser*) from;

-(void)updateLogEntryForStudy:(NSManagedObject*)study withMessage:(NSString*)message forUser:(NSString*)user ip:(NSString*)ip;

-(WebPortalUser*)newUserWithEmail:(NSString*)email;

@end
