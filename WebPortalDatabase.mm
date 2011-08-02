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

#import "WebPortalDatabase.h"
#import "WebPortalUser.h"
#import "NSString+N2.h"


@implementation WebPortalDatabase

-(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* model = NULL;
	if (!model)
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"WebPortalDB.momd"]]];
    return model;
}

const NSString* const WebPortalDatabaseUserEntityName = @"User";
const NSString* const WebPortalDatabaseStudyEntityName = @"Study";

-(NSEntityDescription*)userEntity {
	return [self entityForName: [NSString stringWithString: WebPortalDatabaseUserEntityName]];
}

-(NSEntityDescription*)studyEntity {
	return [self entityForName: [NSString stringWithString: WebPortalDatabaseStudyEntityName]];
}

-(NSArray*)usersWithPredicate:(NSPredicate*)p {
	return [self objectsForEntity:self.userEntity predicate:p];
}

-(WebPortalUser*)userWithName:(NSString*)name {
	NSArray* res = [self usersWithPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
	if (res.count)
		return [res objectAtIndex:0];
	return NULL;
}

-(WebPortalUser*)newUser {
	return [NSEntityDescription insertNewObjectForEntityForName: [NSString stringWithString: WebPortalDatabaseUserEntityName] inManagedObjectContext:self.managedObjectContext];
}

@end
