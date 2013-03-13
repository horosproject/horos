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

+(NSString*) modelName
{
    return @"WebPortalDB.momd";
}

-(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* model = NULL;
	if (!model)
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent: WebPortalDatabase.modelName]]];
    return model;
}

NSString* const WebPortalDatabaseUserEntityName = @"User";
NSString* const WebPortalDatabaseStudyEntityName = @"Study";

-(NSEntityDescription*)userEntity {
	return [self entityForName:WebPortalDatabaseUserEntityName];
}

-(NSEntityDescription*)studyEntity {
	return [self entityForName:WebPortalDatabaseStudyEntityName];
}

-(NSArray*)usersWithPredicate:(NSPredicate*)p {
	return [self objectsForEntity:self.userEntity predicate:p];
}

-(WebPortalUser*)userWithName:(NSString*)name {
	NSArray* res = [self usersWithPredicate:[NSPredicate predicateWithFormat:@"name LIKE[cd] %@", name]];
	if (res.count)
		return [res objectAtIndex:0];
	return NULL;
}

-(WebPortalUser*)newUser {
    
    id newUser = [NSEntityDescription insertNewObjectForEntityForName:WebPortalDatabaseUserEntityName inManagedObjectContext:self.managedObjectContext];
    
    [newUser setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [NSDate timeIntervalSinceReferenceDate] + [[NSUserDefaults standardUserDefaults] integerForKey: @"temporaryUserDuration"] * 60L*60L*24L] forKey: @"deletionDate"];
    
	return newUser;
}

@end
