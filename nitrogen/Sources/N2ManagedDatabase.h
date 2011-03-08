//
//  N2ManagedDatabase.h
//  OsiriX
//
//  Created by Alessandro Volz on 17.01.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface N2ManagedDatabase : NSObject {
	NSString* basePath;
	NSManagedObjectContext* managedObjectContext;
	@private
		NSRecursiveLock* writeLock;
}

@property(readonly,retain) NSManagedObjectContext* managedObjectContext;
@property(readonly,retain) NSString* basePath;

// locking actually locks the context
-(void)lock;
-(BOOL)tryLock;
-(void)unlock;
// write locking uses writeLock member
-(void)writeLock;
-(BOOL)tryWriteLock;
-(void)writeUnlock;

-(NSManagedObjectModel*)managedObjectModel;
-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary;
-(NSString*)sqlFilePath;

-(id)initWithPath:(NSString*)path;
-(id)initWithPath:(NSString*)p context:(NSManagedObjectContext*)c; // TODO: this will one day get __deprecated

-(NSManagedObjectContext*)independentContext;

-(NSEntityDescription*)entityForName:(NSString*)name;
-(NSManagedObject*)objectWithID:(NSString*)theId;
-(NSArray*)objectsForEntity:(NSEntityDescription*)e predicate:(NSPredicate*)p;

-(void)save:(NSError**)err;


@end
