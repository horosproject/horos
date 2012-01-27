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

#import <Cocoa/Cocoa.h>


@interface N2ManagedDatabase : NSObject {
	@protected
		NSString* _sqlFilePath;
	@private
	NSManagedObjectContext* _managedObjectContext;
//		NSRecursiveLock* writeLock;
}

@property(readonly,retain) NSString* sqlFilePath;
@property(readonly) NSManagedObjectModel* managedObjectModel;
@property(readwrite,retain) NSManagedObjectContext* managedObjectContext; // only change this value if you know what you're doing

// locking actually locks the context
-(void)lock;
-(BOOL)tryLock;
-(void)unlock;
// write locking uses writeLock member
//-(void)writeLock;
//-(BOOL)tryWriteLock;
//-(void)writeUnlock;

-(NSManagedObjectModel*)managedObjectModel;
//-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary;
-(BOOL)migratePersistentStoresAutomatically; // default implementation returns YES

-(id)initWithPath:(NSString*)sqlFilePath;
-(id)initWithPath:(NSString*)sqlFilePath context:(NSManagedObjectContext*)c;
-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath; // THIS METHOD IS PROTECTED, you may want to override this, but NEVER CALL IT FROM OUTSIDE

-(NSManagedObjectContext*)independentContext:(BOOL)independent;
-(NSManagedObjectContext*)independentContext;
-(id)independentDatabase;

-(NSEntityDescription*)entityForName:(NSString*)name;
-(NSManagedObject*)objectWithID:(NSString*)theId;
-(NSArray*)objectsForEntity:(NSEntityDescription*)e;
-(NSArray*)objectsForEntity:(NSEntityDescription*)e predicate:(NSPredicate*)p;
-(NSArray*)objectsForEntity:(NSEntityDescription*)e predicate:(NSPredicate*)p error:(NSError**)err;
-(NSUInteger)countObjectsForEntity:(NSEntityDescription*)e;
-(NSUInteger)countObjectsForEntity:(NSEntityDescription*)e predicate:(NSPredicate*)p;
-(NSUInteger)countObjectsForEntity:(NSEntityDescription*)entity predicate:(NSPredicate*)p error:(NSError**)err;
-(id)newObjectForEntity:(NSEntityDescription*)entity;

-(BOOL)save;
-(BOOL)save:(NSError**)err;


@end
