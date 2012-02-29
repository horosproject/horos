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
#import "NSMutableDictionary+N2.h"
#import "N2Debug.h"

//#import "DicomDatabase.h" // for debug purposes, REMOVE

@interface N2ManagedDatabase ()

@property(readwrite,retain) NSString* sqlFilePath;
@property(readwrite,retain) id mainDatabase;

@end


@interface N2ManagedObjectContext : NSManagedObjectContext {
	N2ManagedDatabase* _database;
}

@property(retain) N2ManagedDatabase* database;

@end

@implementation N2ManagedObjectContext

@synthesize database = _database;

-(void)dealloc {
//	NSLog(@"---------- DEL %@", self);
//    [self save:NULL];
	self.database = nil;
	[super dealloc];
	[NSNotificationCenter.defaultCenter removeObserver:self]; // some bug? It seems the managedObjectContext gets notified by the persistentStore, and the notifications are still sent after the context's dealloc..
}

-(BOOL)save:(NSError**)error {
    [self lock];
    [self.persistentStoreCoordinator lock];
    @try {
        return [super save:error];
    } @catch (...) {
        @throw;
    } @finally {
        [self.persistentStoreCoordinator unlock];
        [self unlock];
    }
    
    return NO;
}

-(NSManagedObject*)existingObjectWithID:(NSManagedObjectID*)objectID error:(NSError**)error {
    [self lock];
    [self.persistentStoreCoordinator lock];
    @try {
        return [super existingObjectWithID:objectID error:error];
    } @catch (...) {
        @throw;
    } @finally {
        [self.persistentStoreCoordinator unlock];
        [self unlock];
    }
    
    return nil;
}

/*-(void)lock { // for debug purposes, REMOVE
    [super lock];
    if ([[DicomDatabase defaultDatabase] managedObjectContext] == self)
        N2LogStackTrace(@"default database locked...");
}

-(void)unlock { // for debug purposes, REMOVE
    if ([[DicomDatabase defaultDatabase] managedObjectContext] == self)
        NSLog(@"default database unlocked.");
    [super unlock];
}*/

@end


@implementation N2ManagedDatabase

@synthesize sqlFilePath = _sqlFilePath;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize mainDatabase = _mainDatabase;

-(NSManagedObjectContext*)managedObjectContext {
	return _managedObjectContext;
}

-(void)setManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	if (managedObjectContext != _managedObjectContext) {
        [self willChangeValueForKey:@"managedObjectContext"];

        NSManagedObjectContext* prevManagedObjectContext = [_managedObjectContext retain];

        [prevManagedObjectContext lock];
        [managedObjectContext lock];
		
        // the database's main managedObjectContext doesn't retain the database
		if ([managedObjectContext isKindOfClass:[N2ManagedObjectContext class]])
            ((N2ManagedObjectContext*)managedObjectContext).database = nil;
        
		[_managedObjectContext release];
		_managedObjectContext = [managedObjectContext retain];
        
        [prevManagedObjectContext unlock];
        [prevManagedObjectContext release];
        
        [managedObjectContext unlock];

        [self didChangeValueForKey:@"managedObjectContext"];
    }
}

-(NSManagedObjectModel*)managedObjectModel {
	[NSException raise:NSGenericException format:@"[%@ managedObjectModel] must be defined", self.className];
	return NULL;
}

/*-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary {
	static NSMutableDictionary* dict = NULL;
	if (!dict)
		dict = [[NSMutableDictionary alloc] initWithCapacity:4];
	return dict;
}*/

-(BOOL)migratePersistentStoresAutomatically {
	return YES;
}

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	sqlFilePath = sqlFilePath.stringByExpandingTildeInPath;
	
    N2ManagedObjectContext* moc = [[[N2ManagedObjectContext alloc] init] autorelease];
    //	NSLog(@"---------- NEW %@ at %@", moc, sqlFilePath);
	moc.undoManager = nil;
	moc.database = self;
	
    //	NSMutableDictionary* persistentStoreCoordinatorsDictionary = self.persistentStoreCoordinatorsDictionary;
	
	@synchronized (self) {
//        if (self.managedObjectContext.hasChanges)
//            [self save];
        
		if ([sqlFilePath isEqualToString:self.sqlFilePath])
			moc.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
        
		if (!moc.persistentStoreCoordinator) {
            //			moc.persistentStoreCoordinator = [persistentStoreCoordinatorsDictionary objectForKey:sqlFilePath];
			
			BOOL isNewFile = ![NSFileManager.defaultManager fileExistsAtPath:sqlFilePath];
			if (isNewFile)
				moc.persistentStoreCoordinator = nil;
			
			if (!moc.persistentStoreCoordinator) {
				NSPersistentStoreCoordinator* persistentStoreCoordinator = moc.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel] autorelease];
                //				[persistentStoreCoordinatorsDictionary setObject:persistentStoreCoordinator forKey:sqlFilePath];
				
				NSPersistentStore* pStore = nil;
				int i = 0;
				do { // try 2 times
					++i;
					
					NSError* err = NULL;
					NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:[self migratePersistentStoresAutomatically]], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, NULL];
					NSURL* url = [NSURL fileURLWithPath:sqlFilePath];
					@try {
						pStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:NULL URL:url options:options error:&err];
					} @catch (...) {
					}
					
					if (!pStore && i == 1) {
						NSLog(@"Error: [N2ManagedDatabase contextAtPath:] %@", [err description]);
						NSRunCriticalAlertPanel([NSString stringWithFormat:NSLocalizedString(@"%@ Storage Error", nil), [self className]], err.localizedDescription, NSLocalizedString(@"OK", NULL), NULL, NULL);
						
						// error = [NSError osirixErrorWithCode:0 underlyingError:error localizedDescriptionFormat:NSLocalizedString(@"Store Configuration Failure: %@", NULL), error.localizedDescription? error.localizedDescription : NSLocalizedString(@"Unknown Error", NULL)];
						
						// delete the old file...
						[NSFileManager.defaultManager removeItemAtPath:sqlFilePath error:NULL];
						// [NSFileManager.defaultManager removeItemAtPath: [defaultPortalUsersDatabasePath.stringByExpandingTildeInPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"WebUsers.vers"] error:NULL];
					}
				} while (!pStore && i < 2);
			}
			
			if (isNewFile) {
                [moc save:NULL];
				NSLog(@"New database file created at %@", sqlFilePath);
            }

		} else {
            if (self.mainDatabase)
                NSLog(@"ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR: creating independent context from already independent database");
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:moc];
        }
        
	}
    
    return moc;
}

+(NSManagedObjectContext*)_mocFromContextDidSaveNotification:(NSNotification*)n {
    NSManagedObjectContext* moc = nil;
    for (NSString* key in [NSArray arrayWithObjects: NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey, nil])
        for (NSManagedObject* mo in [n.userInfo objectForKey:key])
            if ((moc = mo.managedObjectContext))
                return moc;
    return nil;
}

-(void)mergeChangesFromContextDidSaveNotification:(NSNotification*)n {
    NSManagedObjectContext* moc = [[self class] _mocFromContextDidSaveNotification:n];

    if (self.managedObjectContext.persistentStoreCoordinator != moc.persistentStoreCoordinator)
        return;
    
    if (![NSThread isMainThread]) {
        if (moc) {
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithDictionary:n.userInfo];
            if (userInfo) [userInfo setObject:moc forKey:@"MOC"]; // we need to retain the moc or it may be released before the mainThread processes this // TODO: do we?
            [self performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:[NSNotification notificationWithName:n.name object:n.object userInfo:userInfo] waitUntilDone:NO];
        }
    } else {
        [self.managedObjectContext lock];
        [self.managedObjectContext.persistentStoreCoordinator lock];
        @try {
            [self.managedObjectContext mergeChangesFromContextDidSaveNotification:n];
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        } @finally {
            [self.managedObjectContext.persistentStoreCoordinator unlock];
            [self.managedObjectContext unlock];
        }
    }
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

-(id)initWithPath:(NSString*)p {
	return [self initWithPath:p context:nil mainDatabase:nil];
}

-(id)initWithPath:(NSString*)p context:(NSManagedObjectContext*)c {
    return [self initWithPath:p context:c mainDatabase:nil];
}

-(id)initWithPath:(NSString*)p context:(NSManagedObjectContext*)c mainDatabase:(N2ManagedDatabase*)mainDbReference {
	self = [super init];
	
	self.sqlFilePath = p;
    self.mainDatabase = mainDbReference;
	
	self.managedObjectContext = c? c : [self contextAtPath:p];
	
	return self;
}

-(void)dealloc {
//    if ([self.managedObjectContext hasChanges])
//        [self save];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    if (self.mainDatabase) [NSNotificationCenter.defaultCenter removeObserver:self.mainDatabase name:NSManagedObjectContextDidSaveNotification object:self];
//	[self.managedObjectContext reset];
    self.mainDatabase = nil;
	self.managedObjectContext = nil;
	self.sqlFilePath = nil;
//	[writeLock release];
	[super dealloc];
}

-(NSManagedObjectContext*)independentContext:(BOOL)independent {
	return independent? [self contextAtPath:self.sqlFilePath] : self.managedObjectContext;
}

-(NSManagedObjectContext*)independentContext {
	return [self independentContext:YES];
}

-(id)independentDatabase {
	return [[[[self class] alloc] initWithPath:self.sqlFilePath context:[self independentContext] mainDatabase:self] autorelease];
}

-(id)objectWithID:(id)oid {
    [self.managedObjectContext lock];
    @try {
        if ([oid isKindOfClass:[NSManagedObjectID class]]) {
            // nothing, just avoid all other checks for performance
        } else if ([oid isKindOfClass:[NSManagedObject class]]) {
            oid = [oid objectID];
        } else if ([oid isKindOfClass:[NSURL class]]) {
            oid = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:oid];
        } else if ([oid isKindOfClass:[NSString class]]) {
            oid = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:oid]];
        } // else we're in trouble: oid is invalid, but let's give Core Data a chance to handle it anyway
        return [self.managedObjectContext existingObjectWithID:oid error:NULL];
    } @catch (...) {
        // nothing, just return nil
    } @finally {
        [self.managedObjectContext unlock];
    }
    
    return nil;
}

-(NSArray*)objectsWithIDs:(NSArray*)objectIDs {
    [self.managedObjectContext lock];
    @try {
        NSMutableArray* r = [NSMutableArray arrayWithCapacity:objectIDs.count];
        for (id oid in objectIDs)
            @try {
                id o = [self objectWithID:oid];
                if (o) [r addObject:o];
            } @catch (NSException* e) {
                // nothing, just look for other objects
            }
        return r;
    } @catch (...) {
        @throw;
    } @finally {
        [self.managedObjectContext unlock];
    }
    
    return nil;
}

-(NSEntityDescription*)entityForName:(NSString*)name {
	return [NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext];
}

-(NSEntityDescription*)_entity:(id*)entity {
    if ([*entity isKindOfClass:[NSString class]])
        *entity = [self entityForName:*entity];
    return *entity;
}

-(NSArray*)objectsForEntity:(id)e {
	return [self objectsForEntity:e predicate:nil error:NULL];
}

-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p {
	return [self objectsForEntity:e predicate:p error:NULL];
}

-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)err {
	[self _entity:&e];
    
    NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = e;
	req.predicate = p? p : [NSPredicate predicateWithValue:YES];
    
    [self.managedObjectContext lock];
    @try {
        return [self.managedObjectContext executeFetchRequest:req error:err];
    } @catch (NSException* e) {
        N2LogException(e);
    } @finally {
        [self.managedObjectContext unlock];
    }
    
    return nil;
}

-(NSUInteger)countObjectsForEntity:(id)e {
	return [self countObjectsForEntity:e predicate:nil error:NULL];
}

-(NSUInteger)countObjectsForEntity:(id)e predicate:(NSPredicate*)p {
	return [self countObjectsForEntity:e predicate:p error:NULL];
}

-(NSUInteger)countObjectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)err {
	[self _entity:&e];

	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = e;
	req.predicate = p? p : [NSPredicate predicateWithValue:YES];
    
    [self.managedObjectContext lock];
    @try {
        return [self.managedObjectContext countForFetchRequest:req error:err];
    } @catch (NSException* e) {
        N2LogException(e);
    } @finally {
        [self.managedObjectContext unlock];
    }
    
	return 0;
}

-(id)newObjectForEntity:(id)entity {
    [self _entity:&entity];
	return [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
}

-(BOOL)save {
    return [self save:NULL];
}

-(BOOL)save:(NSError**)err {
	NSError* perr = NULL;
	if (!err) err = &perr;
	
	BOOL b = NO;
	
    @try {
        b = [self.managedObjectContext save:err];
    } @catch(NSException* e) {
        if (!*err)
            *err = [NSError errorWithDomain:@"Exception" code:-1 userInfo:[NSDictionary dictionaryWithObject:e forKey:@"Exception"]];
    } @finally {
    }
	
	return b;
}


@end
