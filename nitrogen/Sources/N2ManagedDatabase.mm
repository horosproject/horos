//
//  N2ManagedDatabase.mm
//  OsiriX
//
//  Created by Alessandro Volz on 17.01.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "N2ManagedDatabase.h"


@interface N2ManagedDatabase ()

@property(readwrite,retain) NSString* path;
@property(readwrite,retain) NSManagedObjectContext* context;

@end


@implementation N2ManagedDatabase

@synthesize basePath, context;

-(NSManagedObjectModel*)model {
	[NSException raise:NSGenericException format:@"[%@ model] must be defined", self.className];
	return NULL;
}

-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary {
	return NULL;
}

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	sqlFilePath = sqlFilePath.stringByExpandingTildeInPath;
	
    NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
	managedObjectContext.undoManager = NULL;
	
	managedObjectContext.persistentStoreCoordinator = [self.persistentStoreCoordinatorsDictionary objectForKey:sqlFilePath];
	if (!managedObjectContext.persistentStoreCoordinator) {
		managedObjectContext.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model] autorelease];
		[self.persistentStoreCoordinatorsDictionary setObject:managedObjectContext.persistentStoreCoordinator forKey:sqlFilePath];
	}
	
    NSURL* url = [NSURL fileURLWithPath:sqlFilePath];
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, NULL]; // [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, NULL];
	NSError* err = NULL;
	if (![managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:options error:&err]) {
		NSLog(@"Error: [N2ManagedDatabase contextAtPath:] %@", err);
		NSRunCriticalAlertPanel(NSLocalizedString(@"Database Error", NULL), err.localizedDescription, NSLocalizedString(@"OK", NULL), NULL, NULL);
		
		// error = [NSError osirixErrorWithCode:0 underlyingError:error localizedDescriptionFormat:NSLocalizedString(@"Store Configuration Failure: %@", NULL), error.localizedDescription? error.localizedDescription : NSLocalizedString(@"Unknown Error", NULL)];
		
		// delete the old file...
		[NSFileManager.defaultManager removeItemAtPath:path error:NULL];
		// [NSFileManager.defaultManager removeItemAtPath: [defaultPortalUsersDatabasePath.stringByExpandingTildeInPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"WebUsers.vers"] error:NULL];
		
		[managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:options error:NULL];
	}
	
	// this line is very important, if there is no sql file
	[managedObjectContext save:NULL];
	
    return [managedObjectContext autorelease];
}

-(void)lock {
	[self.context lock];
}

-(BOOL)tryLock {
	return [self.context tryLock];
}

-(void)unlock {
	[self.context unlock];
}

-(void)writeLock {
	[writeLock lock];
}

-(BOOL)tryWriteLock {
	return [writeLock tryLock];
}

-(void)writeUnlock {
	[writeLock unlock];
}

-(NSString*)sqlFilePath {
	return self.basePath;
}

-(id)initWithPath:(NSString*)p {
	self = [super init];
	writeLock = [[NSRecursiveLock alloc] init];
	self.basePath = p;
	self.context = [self contextAtPath:[self sqlFilePath]];
	return self;
}

-(void)dealloc {
	self.context = NULL;
	self.basePath = NULL;
	[writeLock release];
	[super dealloc];
}

-(NSManagedObjectContext*)independentContext {
	return [self contextAtPath:self.path];
}

-(NSEntityDescription*)entityForName:(NSString*)name {
	return [NSEntityDescription entityForName:name inManagedObjectContext:self.context];
}

-(void)save:(NSError**)err {
	NSError* perr = NULL;
	NSError** rerr = err? err : &perr;
	[self lock];
	@try {
		[self.context save:rerr];
		if (!err && perr) NSLog(@"Error: [N2ManagedDatabase save:] %@", perr.description);
	} @catch(NSException* e) {
		if (!err)
			NSLog(@"Exception: [N2ManagedDatabase save:] %@", e.description);
		else *err = [NSError errorWithDomain:@"Exception" code:-1 userInfo:[NSDictionary dictionaryWithObject:e forKey:@"Exception"]];
	} @finally {
		[self unlock];
	}
}


@end
