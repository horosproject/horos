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
