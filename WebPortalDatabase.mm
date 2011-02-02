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


@interface WebPortalDatabase ()

//@property(readwrite, retain) NSManagedObjectContext* managedObjectContext;

@end


@implementation WebPortalDatabase

//@synthesize managedObjectContext;

-(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* model = NULL;
	if (!model)
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"WebPortalDB.momd"]]];
    return model;
}

-(WebPortalUser*)userWithName:(NSString*)name {
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	req.predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
	NSArray* res = [managedObjectContext executeFetchRequest:req error:NULL];
	if (res.count)
		return [res objectAtIndex:0];
	return NULL;
}

-(WebPortalUser*)newUser {
	return [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
}

@end
