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

#import "N2ManagedDatabase.h"


@class WebPortalUser;


@interface WebPortalDatabase : N2ManagedDatabase {
}

extern NSString* const WebPortalDatabaseUserEntityName;
extern NSString* const WebPortalDatabaseStudyEntityName;

-(NSEntityDescription*)userEntity;
-(NSEntityDescription*)studyEntity;

-(NSArray*)usersWithPredicate:(NSPredicate*)p;

-(WebPortalUser*)userWithName:(NSString*)name;
-(WebPortalUser*)newUser;

@end
