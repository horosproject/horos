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

#import <Cocoa/Cocoa.h>


@interface N2ManagedDatabase : NSObject {
	@protected
    NSString* _sqlFilePath;
	@private
	NSManagedObjectContext* _managedObjectContext;
    id _mainDatabase;
    volatile BOOL _isDeallocating;
    
#ifndef NDEBUG
    NSThread *associatedThread;
#endif
}

#ifndef NDEBUG
@property(readonly) NSThread* associatedThread;
#endif

@property(readonly,retain) NSString* sqlFilePath;
@property(readonly) NSManagedObjectModel* managedObjectModel;
@property(readwrite,retain) NSManagedObjectContext* managedObjectContext; // only change this value if you know what you're doing

@property(readonly,retain) id mainDatabase; // for independentDatabases
-(BOOL)isMainDatabase;

// locking actually locks the context
-(void)lock;
-(BOOL)lockBeforeDate:(NSDate*) date;
-(BOOL)tryLock;
-(void)unlock;
#ifndef NDEBUG
-(void) checkForCorrectContextThread;
-(void) checkForCorrectContextThread: (NSManagedObjectContext*) c;
#endif
// write locking uses writeLock member
//-(void)writeLock;
//-(BOOL)tryWriteLock;
//-(void)writeUnlock;

+(NSString*) modelName;
-(BOOL) deleteSQLFileIfOpeningFailed;
-(NSManagedObjectModel*)managedObjectModel;
//-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary;
-(BOOL)migratePersistentStoresAutomatically; // default implementation returns YES

-(id)initWithPath:(NSString*)sqlFilePath;
-(id)initWithPath:(NSString*)sqlFilePath context:(NSManagedObjectContext*)context;
-(id)initWithPath:(NSString*)sqlFilePath context:(NSManagedObjectContext*)context mainDatabase:(N2ManagedDatabase*)mainDbReference;

- (void) renewManagedObjectContext;
-(NSManagedObjectContext*)independentContext:(BOOL)independent;
-(NSManagedObjectContext*)independentContext;
-(id)independentDatabase;

-(NSEntityDescription*)entityForName:(NSString*)name;

-(id)objectWithID:(id)oid;
-(NSArray*)objectsWithIDs:(NSArray*)objectIDs;

// in these methods, e can be an NSEntityDescription* or an NSString*
-(NSArray*)objectsForEntity:(id)e;
-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p;
-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)err;
-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)error fetchLimit:(NSUInteger)fetchLimit sortDescriptors:(NSArray*)sortDescriptors;
-(NSUInteger)countObjectsForEntity:(id)e;
-(NSUInteger)countObjectsForEntity:(id)e predicate:(NSPredicate*)p;
-(NSUInteger)countObjectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)err;
-(id)newObjectForEntity:(id)e;

-(BOOL)save;
-(BOOL)save:(NSError**)err;

@end

@interface N2ManagedDatabase (Protected)

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath;

@end

@interface N2ManagedObjectContext : NSManagedObjectContext {
    
	N2ManagedDatabase* _database;
}

@property(readonly) N2ManagedDatabase* database;

- (instancetype)initWithDatabase:(N2ManagedDatabase *)db concurrencyType:(NSManagedObjectContextConcurrencyType)ct NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct NS_UNAVAILABLE;

@end
