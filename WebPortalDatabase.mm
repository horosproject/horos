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

@property(readwrite, retain) NSManagedObjectContext* managedObjectContext;

@end


@implementation WebPortalDatabase

@synthesize managedObjectContext;

+(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* managedObjectModel = NULL;
	
	if (!managedObjectModel)
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"WebPortalDB.momd"]]];
    
    return managedObjectModel;
}

+(NSManagedObjectContext*)managedObjectContextAtPath:(NSString*)path {
    NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
    managedObjectContext.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel] autorelease];
	managedObjectContext.undoManager = NULL;
	
    NSURL* url = [NSURL fileURLWithPath:path];
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, NULL]; // [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, NULL];
	NSError* err = NULL;
	if (![managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:options error:&err]) {
		NSLog(@"Error: [WebPortal managedObjectContextAtPath:] %@", err);
		NSRunCriticalAlertPanel(NSLocalizedString(@"Web Users Database Error", NULL), err.localizedDescription, NSLocalizedString(@"OK", NULL), NULL, NULL);
		
		// error = [NSError osirixErrorWithCode:0 underlyingError:error localizedDescriptionFormat:NSLocalizedString(@"Store Configuration Failure: %@", NULL), error.localizedDescription? error.localizedDescription : NSLocalizedString(@"Unknown Error", NULL)];
		
		// delete the old file...
		[NSFileManager.defaultManager removeItemAtPath:path error:NULL];
		// [NSFileManager.defaultManager removeItemAtPath: [DefaultWebPortalUsersDatabasePath.stringByExpandingTildeInPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"WebUsers.vers"] error:NULL];
		
		[managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:options error:NULL];
	}
	
	// this line is very important, if there is no sql file
	[managedObjectContext save:NULL];
	
    return managedObjectContext;
}

-(id)initWithContext:(NSManagedObjectContext*)context {
	self = [super init];
	self.managedObjectContext = context;
	return self;
}

-(id)initWithPath:(NSString*)sqlFilePath {
	return [self initWithContext:[WebPortalDatabase managedObjectContextAtPath:sqlFilePath.stringByExpandingTildeInPath]];
}

-(void)dealloc {
	self.managedObjectContext = NULL;
	[super dealloc];
}

-(void)save:(NSError**)err {
	[managedObjectContext lock];
	@try {
		NSError* perr = NULL;
		NSError** rerr = err? err : &perr;
		[managedObjectContext save:rerr];
		if (!err && perr) NSLog(@"Error: [WebPortalDatabase save:] %@", perr.description);
	} @catch(NSException* e) {
		if (!err)
			NSLog(@"Exception: [WebPortalDatabase save:] %@", e.description);
		else *err = [NSError errorWithDomain:@"Exception" code:-1 userInfo:[NSDictionary dictionaryWithObject:e forKey:@"Exception"]];
	} @finally {
		[managedObjectContext unlock];
	}
}

-(NSEntityDescription*)entityForName:(NSString*)name {
	return [NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext];
}

-(NSManagedObject*)objectWithID:(NSString*)theId {
	return [managedObjectContext objectWithID:[managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:theId]]];
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
