//
//  ThreadsManager.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ThreadsManager : NSObject {
	@private 
    NSMutableArray* _threads;
	NSArrayController* _threadsController;
}

@property(readonly) NSMutableArray* threads;
@property(readonly) NSArrayController* threadsController;

+(ThreadsManager*)defaultManager;

-(NSUInteger)threadsCount;
-(NSThread*)threadAtIndex:(NSUInteger)index;
-(void)addThread:(NSThread*)thread;
-(void)removeThread:(NSThread*)thread;

-(NSUInteger)countOfThreads;
-(id)objectInThreadsAtIndex:(NSUInteger)index;
-(void)insertObject:(id)obj inThreadsAtIndex:(NSUInteger)index;
-(void)removeObjectFromThreadsAtIndex:(NSUInteger)index;
-(void)replaceObjectInThreadsAtIndex:(NSUInteger)index withObject:(id)obj;

@end
