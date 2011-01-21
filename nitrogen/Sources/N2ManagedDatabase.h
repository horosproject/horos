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
	NSManagedObjectContext* context;
	@private
		NSRecursiveLock* writeLock;
}

@property(readonly,retain) NSManagedObjectContext* context;
@property(readonly,retain) NSString* basePath;

// locking actually locks the context
-(void)lock;
-(BOOL)tryLock;
-(void)unlock;
// write locking uses writeLock member
-(void)writeLock;
-(BOOL)tryWriteLock;
-(void)writeUnlock;

-(NSManagedObjectModel*)model;
-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary;
-(NSString*)sqlFilePath;

-(id)initWithPath:(NSString*)path;

-(NSManagedObjectContext*)independentContext;

-(NSEntityDescription*)entityForName:(NSString*)name;

-(void)save:(NSError**)err;


@end
