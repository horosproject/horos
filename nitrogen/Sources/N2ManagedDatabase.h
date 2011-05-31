//
//  N2ManagedDatabase.h
//  OsiriX
//
//  Created by Alessandro Volz on 17.01.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

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

-(NSEntityDescription*)entityForName:(NSString*)name;
-(NSManagedObject*)objectWithID:(NSString*)theId;
-(NSArray*)objectsForEntity:(NSEntityDescription*)e;
-(NSArray*)objectsForEntity:(NSEntityDescription*)e predicate:(NSPredicate*)p;
-(NSArray*)objectsForEntity:(NSEntityDescription*)e predicate:(NSPredicate*)p error:(NSError**)err;
-(id)newObjectForEntity:(NSEntityDescription*)entity;

-(BOOL)isVolatile;
-(BOOL)save:(NSError**)err;


@end
