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

#import "N2ManagedDatabase.h"
#import "NSMutableDictionary+N2.h"
#import "N2Debug.h"
#import "NSFileManager+N2.h"
#import "NSException+N2.h"
#import "DCMTKQueryNode.h"
//#import "DicomDatabase.h" // for debug purposes, REMOVE

static int gTotalN2ManagedObjectContext = 0;

@interface N2ManagedDatabase ()

@property(readwrite,retain) NSString* sqlFilePath;
@property(readwrite,retain) id mainDatabase;

@end

#define N2PersistentStoreCoordinator NSPersistentStoreCoordinator // for debug purposes, disable this #define and enable the commented N2PersistentStoreCoordinator implementation

@implementation N2ManagedObjectContext

@synthesize database = _database;

- (id)initWithDatabase:(N2ManagedDatabase *)db concurrencyType:(NSManagedObjectContextConcurrencyType)ct
{
    if (!(self = [super initWithConcurrencyType:ct]))
        return nil;
    
    _database = db;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector( N2ManagedDatabaseDealloced:) name: @"N2ManagedDatabaseDealloced" object: db];
    
#ifndef NDEBUG
    gTotalN2ManagedObjectContext++;
    
    if( gTotalN2ManagedObjectContext > 10)
        NSLog( @"-- gTotalN2ManagedObjectContext = %d", gTotalN2ManagedObjectContext);
#endif
    
    return self;
}

-(void)N2ManagedDatabaseDealloced:(NSNotification*) n
{
    if( n.object != _database)
        N2LogStackTrace( @"******* N2ManagedDatabaseDealloced");
    _database = nil;
}

-(void)dealloc {
#ifndef NDEBUG
    [_database checkForCorrectContextThread: self];
    
    gTotalN2ManagedObjectContext--;
#endif
    [NSNotificationCenter.defaultCenter removeObserver:self];
	_database = nil;
	[super dealloc]; //test if db is deallocated
}

-(BOOL)save:(NSError**)error {
    [self lock];
#ifndef NDEBUG
    [_database checkForCorrectContextThread: self];
#endif
    @try {
        return [super save:error];
//        for (NSPersistentStore* ps in [[self persistentStoreCoordinator] persistentStores])
//            if (ps.URL.isFileURL)
//                [NSFileManager.defaultManager applyFileModeOfParentToItemAtPath:ps.URL.path];
    } @catch (...) {
        @throw;
    } @finally {
        [self unlock];
    }
    
    return NO;
}

-(NSManagedObject*)existingObjectWithID:(NSManagedObjectID*)objectID error:(NSError**)error {
    [self lock];
#ifndef NDEBUG
    [_database checkForCorrectContextThread: self];
#endif
    @try {
        return [super existingObjectWithID:objectID error:error];
    } @catch (...) {
        @throw;
    } @finally {
        [self unlock];
    }
    
    return nil;
}

/*
 http://developer.apple.com/DOCUMENTATION/Cocoa/Conceptual/CoreData/Articles/cdMultiThreading.html#//apple_ref/doc/uid/TP40003385-SW2
 "If you lock (or successfully tryLock) a context, that context must be retained until
 you invoke unlock. If you don’t properly retain a context in a multi-threaded environment, you may cause a deadlock."
 */

-(void)lock {
    [self retain];
//    [self.persistentStoreCoordinator lock];
    [super lock];
    
#ifndef NDEBUG
    [_database checkForCorrectContextThread: self];
#endif
    // for debug
/*    if (!lockhist)
        lockhist = [[NSMutableArray alloc] init];
    NSString* stack = nil;
    @try {
        [NSException raise:NSGenericException format:@""];
    } @catch (NSException* e) {
        stack = [e stackTrace];
    }
    if (stack)
        [lockhist addObject:stack];*/
}

-(void)unlock {
  //  [lockhist removeLastObject];
    [super unlock];
//    [self.persistentStoreCoordinator unlock];
    [self autorelease];
}

#ifndef NDEBUG
- (NSArray *)executeFetchRequest:(NSFetchRequest *)request error:(NSError **)error
{
    [_database checkForCorrectContextThread: self];
    
	return [super executeFetchRequest: request error: error];
}

- (void)deleteObject:(NSManagedObject *)object
{
    [_database checkForCorrectContextThread: self];
    
	return [super deleteObject: object];
}
- (NSUInteger)countForFetchRequest:(NSFetchRequest *)request error:(NSError **)error
{
    [_database checkForCorrectContextThread: self];
    
    return [super countForFetchRequest: request error: error];
}
- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID
{
    [_database checkForCorrectContextThread: self];
    
    return [super objectWithID: objectID];
}
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
{
    [_database checkForCorrectContextThread: self];
    
    return [super mergeChangesFromContextDidSaveNotification: notification];
}
#endif

@end


@implementation N2ManagedDatabase
#ifndef NDEBUG
@synthesize associatedThread;
#endif
@synthesize sqlFilePath = _sqlFilePath;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize mainDatabase = _mainDatabase;

#ifndef NDEBUG
-(void) checkForCorrectContextThread
{
    [self checkForCorrectContextThread: _managedObjectContext];
}

-(void) checkForCorrectContextThread: (NSManagedObjectContext*) c
{

    if( c == _managedObjectContext && associatedThread && associatedThread != [NSThread currentThread])
    {
        NSLog( @"------------------------------");
        NSLog( @"SQL path: %@", _sqlFilePath);
        N2LogStackTrace( @"--- warning : managedObjectContext was created in (%@, mainThread=%d), and is now used in (%@, mainThread=%d)", associatedThread.name, associatedThread == [NSThread mainThread], [[NSThread currentThread] name], [NSThread isMainThread]);
        NSLog( @"--");
    }
}
#endif

-(BOOL)isMainDatabase {
    return (_mainDatabase == nil);
}

-(NSManagedObjectContext*)managedObjectContext {
	return _managedObjectContext;
}

-(void)setManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	if (managedObjectContext != _managedObjectContext) {
        [self willChangeValueForKey:@"managedObjectContext"];
        
        [_managedObjectContext autorelease];
		_managedObjectContext = [managedObjectContext retain];
        
#ifndef NDEBUG
        [associatedThread release];
        associatedThread = [[NSThread currentThread] retain];
#endif
        
        [self didChangeValueForKey:@"managedObjectContext"];
    }
}

+(NSString*)modelName {
	[NSException raise:NSGenericException format:@"[class modelName] must be defined"];
	return NULL;
}

-(BOOL) deleteSQLFileIfOpeningFailed
{
    return NO;
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

- (void) renewManagedObjectContext
{
    self.managedObjectContext = self.isMainDatabase? [self contextAtPath: self.sqlFilePath] : [self.mainDatabase contextAtPath: self.sqlFilePath];
}

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	sqlFilePath = sqlFilePath.stringByExpandingTildeInPath;
	
    if( sqlFilePath.length == 0)
        return nil;
    
    N2ManagedObjectContext* moc = [[[N2ManagedObjectContext alloc] initWithDatabase:self concurrencyType:NSConfinementConcurrencyType] autorelease];
    //	NSLog(@"---------- NEW %@ at %@", moc, sqlFilePath);
	moc.undoManager = nil;
	
    //	NSMutableDictionary* persistentStoreCoordinatorsDictionary = self.persistentStoreCoordinatorsDictionary;
	
    @try {
        @synchronized (self) {
    //        if (self.managedObjectContext.hasChanges)
    //            [self save];
            
            if ([sqlFilePath isEqualToString:self.sqlFilePath] && [NSFileManager.defaultManager fileExistsAtPath:sqlFilePath])
                moc.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
            
            if (!moc.persistentStoreCoordinator) {
                //			moc.persistentStoreCoordinator = [persistentStoreCoordinatorsDictionary objectForKey:sqlFilePath];
                
                BOOL isNewFile = ![NSFileManager.defaultManager fileExistsAtPath:sqlFilePath];
                if (isNewFile)
                {
                    [[NSFileManager defaultManager] confirmDirectoryAtPath:[sqlFilePath stringByDeletingLastPathComponent]];
                    moc.persistentStoreCoordinator = nil;
                }
                
                if (!moc.persistentStoreCoordinator)
                {
                    NSString *localModelsPath = [[sqlFilePath stringByDeletingPathExtension] stringByAppendingPathExtension: @"momd"];
                    NSManagedObjectModel *models = self.managedObjectModel;
                    
                    @try
                    {
                        NSManagedObjectModel *localModels = [[[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: localModelsPath]] autorelease]; //Forward compatibility !
                        models = [NSManagedObjectModel modelByMergingModels: [NSArray arrayWithObjects: self.managedObjectModel, localModels, nil]]; //warning localModels can be nil: put it at last position
                    }
                    @catch (NSException *exception)
                    {
                        models = self.managedObjectModel;
                    }
                    
                    NSPersistentStoreCoordinator* persistentStoreCoordinator = moc.persistentStoreCoordinator = [[[N2PersistentStoreCoordinator alloc] initWithManagedObjectModel: models] autorelease];
                    
                    //[persistentStoreCoordinatorsDictionary setObject:persistentStoreCoordinator forKey:sqlFilePath];
                    
                    NSPersistentStore* pStore = nil;
                    int i = 0;
                    do { // try 2 times
                        ++i;
                        
                        NSError* err = nil;
                        NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:[self migratePersistentStoresAutomatically]], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
                        NSURL* url = [NSURL fileURLWithPath:sqlFilePath];
                        @try {
                            pStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&err];
                        } @catch (...) {
                        }
                        
                        if (!pStore && i == 1)
                        {
                            NSLog(@"Error: [N2ManagedDatabase contextAtPath:] %@", [err description]);
                            if ([NSThread isMainThread]) {
                                NSInteger result = NSRunCriticalAlertPanel( [NSString stringWithFormat:NSLocalizedString(@"%@ Storage Error", nil), [self className]], @"%@\r\r%@\r\r%@", NSLocalizedString(@"Continue", nil), NSLocalizedString(@"Delete the SQL index", nil), nil, err.localizedDescription, sqlFilePath, NSLocalizedString(@"I could delete the SQL index file to reset it.", nil));
                                
                                if( result == NSAlertAlternateReturn) {
                                    NSInteger result = NSRunCriticalAlertPanel( [NSString stringWithFormat:NSLocalizedString(@"%@ Storage Error", nil), [self className]], @"%@\r\r%@", NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Delete", nil), nil, NSLocalizedString( @"Do you confirm to delete this index file? This operation cannot be undone.", nil), sqlFilePath);
                                    
                                    if( result == NSAlertAlternateReturn) {
                                        [NSFileManager.defaultManager removeItemAtPath:sqlFilePath error: nil];
                                        i = 0;
                                    }
                                }
                            }
                            
                            // error = [NSError osirixErrorWithCode:0 underlyingError:error localizedDescriptionFormat:NSLocalizedString(@"Store Configuration Failure: %@", nil), error.localizedDescription? error.localizedDescription : NSLocalizedString(@"Unknown Error", nil)];
                            
                            // delete the old file... for the Database.sql model ONLY(Dont do this for the WebUser db)
                            if( self.deleteSQLFileIfOpeningFailed)
                                [NSFileManager.defaultManager removeItemAtPath:sqlFilePath error:nil];
                        }
                    } while (!pStore && i < 2);
                    
                    // Save the models for forward compatibility with old OsiriX versions that don't know the current model
                    NSString *modelsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: [[self class] modelName]];
                    [[NSFileManager defaultManager] removeItemAtPath: localModelsPath error: nil];
                    [[NSFileManager defaultManager] copyItemAtPath:modelsPath toPath:localModelsPath error:nil];

                }
                
                if (isNewFile) {
                    [moc save:NULL];
                    NSLog(@"New database file created at %@", sqlFilePath);
                }
                
            } else {
                if (self.mainDatabase)
                    N2LogStackTrace(@"****************************: creating independent context from already independent database");
                
                // Our main DicomDatabase context will listen to changes from the independentContext
                // Warning: our independentContext will NOT receive changes from the main DicomDatabase context: add it by yourself if needed (see WebPortalConnection.mm)
                [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:moc];
            }
            
        }
    }
    @catch (NSException *exception) {
        moc = nil;
    }
    
    return moc;
}

-(void)mergeChangesFromContextDidSaveNotification:(NSNotification*)n {
    NSManagedObjectContext* moc = [n object];
    
    if (self.managedObjectContext.persistentStoreCoordinator != moc.persistentStoreCoordinator)
        return;
    
    if (self.managedObjectContext == moc)
        return;
    
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:n waitUntilDone:NO];
    }
    else
    {
        [self.managedObjectContext lock];
        @try {
            [self.managedObjectContext mergeChangesFromContextDidSaveNotification:n];
            
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        } @finally {
            [self.managedObjectContext unlock];
        }
    }
}

-(BOOL)lockBeforeDate:(NSDate*) date
{
    while( [[NSDate date] laterDate: date] == date)
    {
        if( [self.managedObjectContext tryLock])
            return YES;
        [NSThread sleepForTimeInterval: 0.1];
    }
    return NO;
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
	
//#ifndef NDEBUG
//    if( [NSThread isMainThread] == NO && mainDbReference == nil)
//        NSLog( @"****** WARNING - Creating a MAIN database, NOT on the MAIN thread... Be aware that this managedObjectContext could be later used on the MAIN thread, unless you renewManagedObjectContext on the main thread.");
//#endif
    
	self.managedObjectContext = c? c : [self contextAtPath:p];
    
	return self;
}

-(void)dealloc {
    // this should fix dealloc cycles
    if (_isDeallocating)
        return;
    _isDeallocating = YES;
    
#ifndef NDEBUG
    [associatedThread release];
    associatedThread = nil;
#endif
    
    [NSNotificationCenter.defaultCenter postNotificationName: @"N2ManagedDatabaseDealloced" object:self];
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    if ([self.managedObjectContext hasChanges] && [NSFileManager.defaultManager fileExistsAtPath:[self.sqlFilePath stringByDeletingLastPathComponent]])
        [self save];
    
    if (self.mainDatabase)
        [NSNotificationCenter.defaultCenter removeObserver:self.mainDatabase name:NSManagedObjectContextDidSaveNotification object:self];
    
    self.mainDatabase = nil;
	self.managedObjectContext = nil;
	self.sqlFilePath = nil;
    
	[super dealloc];
}

-(NSManagedObjectContext*)independentContext:(BOOL)independent
{
    if( independent)
    {
#ifndef NDEBUG
        if( [NSThread isMainThread])
            N2LogStackTrace( @"independentContext not required on main thread.");
#endif
    }
    
	return independent? [self contextAtPath:self.sqlFilePath] : self.managedObjectContext;
}

-(NSManagedObjectContext*)independentContext {
	return [self independentContext:YES];
}

-(id)independentDatabase {
    
#ifndef NDEBUG
    if( [NSThread isMainThread])
        N2LogStackTrace( @"independentDatabase not required on main thread.");
#endif
    
	return [[[[self class] alloc] initWithPath:self.sqlFilePath context:[self independentContext] mainDatabase:self] autorelease];
}

-(id)objectWithID:(id)oid {
    
#ifndef NDEBUG
    [self checkForCorrectContextThread];
#endif
    [self.managedObjectContext lock];
    @try {
        if ([oid isKindOfClass:[NSManagedObjectID class]]) {
            // nothing, just avoid all other checks for performance
        } else if ([oid isKindOfClass:[NSManagedObject class]]) {
            oid = [oid objectID];
        }
#ifndef OSIRIX_LIGHT
        else if ([oid isKindOfClass:[DCMTKQueryNode class]]) {
            return oid;
        }
#endif
        else if ([oid isKindOfClass:[NSURL class]]) {
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
    
#ifndef NDEBUG
    [self checkForCorrectContextThread];
#endif
    
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

-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)error {
    return [self objectsForEntity:e predicate:p error:error fetchLimit:0 sortDescriptors:nil];
}

-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)error fetchLimit:(NSUInteger)fetchLimit sortDescriptors:(NSArray*)sortDescriptors{
	[self _entity:&e];
    
#ifndef NDEBUG
    [self checkForCorrectContextThread];
#endif
    
    NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = e;
	req.predicate = p? p : [NSPredicate predicateWithValue:YES];
    req.sortDescriptors = sortDescriptors;
    if( fetchLimit>0)
        req.fetchLimit = fetchLimit;
    
    [self.managedObjectContext lock];
    @try {
        return [self.managedObjectContext executeFetchRequest:req error:error];
    } @catch (NSException* e) {
        if (error && !*error)
            *error = [NSError errorWithDomain:N2ErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey]];
        else N2LogException(e);
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

-(NSUInteger)countObjectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)error {
	[self _entity:&e];

	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = e;
	req.predicate = p? p : [NSPredicate predicateWithValue:YES];
    
    [self.managedObjectContext lock];
    @try {
        return [self.managedObjectContext countForFetchRequest:req error:error];
    } @catch (NSException* e) {
        if (error && !*error)
            *error = [NSError errorWithDomain:N2ErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey]];
        else N2LogException(e);
    } @finally {
        [self.managedObjectContext unlock];
    }
    
	return 0;
}

-(id)newObjectForEntity:(id)entity {
    [self _entity:&entity];
    return [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:self.managedObjectContext];
}

-(BOOL)save {
    return [self save:NULL];
}

-(BOOL)save:(NSError**)error {
	NSError* perr = NULL;
	if (!error) error = &perr;
	
	BOOL b = NO;
	
#ifndef NDEBUG
    [self checkForCorrectContextThread];
#endif
    
    [self.managedObjectContext lock];
    
    @try {
        b = [self.managedObjectContext save:error];
    } @catch(NSException* e) {
        if (error && !*error)
            *error = [NSError errorWithDomain:N2ErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey]];
        else N2LogException(e);
    } @finally {
        [self.managedObjectContext unlock];
    }
	
	return b;
}


@end
