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
-(void)addThreadAndStart:(NSThread*)thread;
-(void)removeThread:(NSThread*)thread;

-(NSUInteger)countOfThreads;
-(id)objectInThreadsAtIndex:(NSUInteger)index;
-(void)insertObject:(id)obj inThreadsAtIndex:(NSUInteger)index;
-(void)removeObjectFromThreadsAtIndex:(NSUInteger)index;
-(void)replaceObjectInThreadsAtIndex:(NSUInteger)index withObject:(id)obj;

@end
