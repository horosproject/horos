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


@interface N2ManagedDatabase ()

@property(readwrite,retain) NSString* sqlFilePath;
@property(readwrite,retain) N2ManagedDatabase* mainDatabase;

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
	[NSNotificationCenter.defaultCenter removeObserver:self]; // Apple bug? It seems the managedObjectContext gets notified by the persistentStore, and the notifications are still sent after the context's dealloc..
}

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
		// the database's main databaseObjectContext doesn't retain the database
		if ([managedObjectContext isKindOfClass:[N2ManagedObjectContext class]])
            ((N2ManagedObjectContext*)managedObjectContext).database = nil;
		[self willChangeValueForKey:@"managedObjectContext"];
		[_managedObjectContext release];
		_managedObjectContext = [managedObjectContext retain];
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
        if (self.managedObjectContext.hasChanges)
            [self save];
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
			
			if (isNewFile)
				NSLog(@"New database file created at %@", sqlFilePath);
            
            // this line is very important, if there is no sql file
            [moc save:NULL];

		} else {
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:moc]; // TODO: remove observer later
        }
        
	}
    
    return moc;
}

-(void)mergeChangesFromContextDidSaveNotification:(NSNotification*)n {
    if (![NSThread isMainThread])
        [self performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:n waitUntilDone:NO];
    else {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:n];
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
    if ([self.managedObjectContext hasChanges])
        [self save];
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

-(id)objectWithURI:(NSString*)urlString {
	return [self.managedObjectContext existingObjectWithID:[self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:urlString]] error:NULL];
}

-(NSArray*)objectsWithIDs:(NSArray*)objectIDs {
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:objectIDs.count];
    for (NSManagedObjectID* oid in objectIDs) {
        id o = [self.managedObjectContext existingObjectWithID:oid error:NULL];
        if (o) [r addObject:o];
    }
    
    return r;
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
    
    @try {
        return [self.managedObjectContext executeFetchRequest:req error:err];
    } @catch (NSException* e) {
        N2LogException(e);
    } @finally {
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
    
//    [self.managedObjectContext.persistentStoreCoordinator lock];
    @try {
        BOOL isMainThread = [NSThread isMainThread];
        NSManagedObjectContext* searchmoc = isMainThread? self.managedObjectContext : self.independentContext;
        return [searchmoc countForFetchRequest:req error:err];
    } @catch (NSException* e) {
        N2LogException(e);
    } @finally {
//		[self.managedObjectContext.persistentStoreCoordinator unlock];
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
	
    [self.managedObjectContext.persistentStoreCoordinator lock];
    @try {
        b = [self.managedObjectContext save:err];
    } @catch(NSException* e) {
        if (!*err)
            *err = [NSError errorWithDomain:@"Exception" code:-1 userInfo:[NSDictionary dictionaryWithObject:e forKey:@"Exception"]];
    } @finally {
        [self.managedObjectContext.persistentStoreCoordinator unlock];
    }
	
	return b;
}


@end
