//
//  N2ManagedDatabase.mm
//  OsiriX
//
//  Created by Alessandro Volz on 17.01.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "N2ManagedDatabase.h"


@interface N2ManagedDatabase ()

@property(readwrite,retain) NSString* basePath;
@property(readwrite,retain) NSManagedObjectContext* managedObjectContext;

@end


@implementation N2ManagedDatabase

@synthesize basePath, managedObjectContext;

-(NSManagedObjectModel*)managedObjectModel {
	[NSException raise:NSGenericException format:@"[%@ model] must be defined", self.className];
	return NULL;
}

-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary {
	static NSMutableDictionary* dict = NULL;
	if (!dict)
		dict = [[NSMutableDictionary alloc] initWithCapacity:4];
	return dict;
}

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	sqlFilePath = sqlFilePath.stringByExpandingTildeInPath;
	
    NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] init];
	moc.undoManager = NULL;
	
	@synchronized (self) {
		moc.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
		if (!moc.persistentStoreCoordinator)
			moc.persistentStoreCoordinator = [self.persistentStoreCoordinatorsDictionary objectForKey:sqlFilePath];
		if (!moc.persistentStoreCoordinator) {
			moc.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel] autorelease];
			[self.persistentStoreCoordinatorsDictionary setObject:moc.persistentStoreCoordinator forKey:sqlFilePath];
		}
	}
	
    NSURL* url = [NSURL fileURLWithPath:sqlFilePath];
	NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, NULL]; // [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, NULL];
	NSError* err = NULL;
	if (![moc.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:options error:&err]) {
		NSLog(@"Error: [N2ManagedDatabase contextAtPath:] %@", err);
		NSRunCriticalAlertPanel(NSLocalizedString(@"Database Error", NULL), err.localizedDescription, NSLocalizedString(@"OK", NULL), NULL, NULL);
		
		// error = [NSError osirixErrorWithCode:0 underlyingError:error localizedDescriptionFormat:NSLocalizedString(@"Store Configuration Failure: %@", NULL), error.localizedDescription? error.localizedDescription : NSLocalizedString(@"Unknown Error", NULL)];
		
		// delete the old file...
		[[NSFileManager defaultManager] removeItemAtPath:sqlFilePath error:NULL];
		// [NSFileManager.defaultManager removeItemAtPath: [defaultPortalUsersDatabasePath.stringByExpandingTildeInPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"WebUsers.vers"] error:NULL];
		
		[moc.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:options error:NULL];
	}
	
	// this line is very important, if there is no sql file
	[moc save:NULL];
	
    return [moc autorelease];
}

-(void)lock {
	[self.managedObjectContext lock];
}

-(BOOL)tryLock {
	return [self.managedObjectContext tryLock];
}

-(void)unlock {
	[self.managedObjectContext unlock];
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

-(id)initWithPath:(NSString*)p context:(NSManagedObjectContext*)c {
	self = [super init];
	writeLock = [[NSRecursiveLock alloc] init];
	self.basePath = p;
	self.managedObjectContext = c;
	return self;
}

-(id)initWithPath:(NSString*)p {
	self = [self initWithPath:p context:NULL];
	self.managedObjectContext = [self contextAtPath:[self sqlFilePath]];
	return self;
}

-(void)dealloc {
	self.managedObjectContext = NULL;
	self.basePath = NULL;
	[writeLock release];
	[super dealloc];
}

-(NSManagedObjectContext*)independentContext {
	return [self contextAtPath:self.sqlFilePath];
}

-(NSEntityDescription*)entityForName:(NSString*)name {
	return [NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext];
}

-(NSManagedObject*)objectWithID:(NSString*)theId {
	return [self.managedObjectContext objectWithID:[self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:theId]]];
}

-(NSArray*)objectsForEntity:(NSEntityDescription*)e predicate:(NSPredicate*)p {
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = e;
	req.predicate = p;
	return [managedObjectContext executeFetchRequest:req error:NULL];
}

-(void)save:(NSError**)err {
	NSError* perr = NULL;
	NSError** rerr = err? err : &perr;
	[self lock];
	@try {
		[self.managedObjectContext save:rerr];
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
