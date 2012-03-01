//
//  ForkedInterface.h
//  OsiriX_Lion
//
//  Created by Alessandro Volz on 01.03.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParentForkedInterface : NSObject {
    
}

@end

@class ChildForkedObject;

@interface ChildForkedInterface : NSObject {
    NSPipe* _c2ppipe;
    NSPipe* _p2cpipe;
    NSFileHandle* _c2p;
    NSFileHandle* _p2c;
}

-(id)initWithC2PPipe:(NSPipe*)c2ppipe P2CPipe:(NSPipe*)p2cpipe;

-(ChildForkedObject*)defaultDatabaseItemWithID:(NSString*)objectIdUriString keys:(NSArray*)keys;
-(NSArray*)defaultDatabaseItemsWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate keys:(NSArray*)keys;
-(void)sendDone;

@end

@interface ChildForkedObject : NSObject {
    NSMutableDictionary* _dictionary;
    ChildForkedInterface* _cfi;
}

@end