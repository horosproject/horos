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

#import "ThreadsManager.h"
#import "ThreadModalForWindowController.h"

@implementation ThreadsManager

@synthesize threads = _threads;
@synthesize threadsController = _threadsController;

+(ThreadsManager*)defaultManager {
	static ThreadsManager* threadsManager = [[self alloc] init];
	return threadsManager;
}

-(id)init {
	self = [super init];
	
	_threads = [[NSMutableArray alloc] init];
	
	_threadsController = [[NSArrayController alloc] init];
	[_threadsController setSelectsInsertedObjects:NO];
	[_threadsController setAvoidsEmptySelection:NO];
	[_threadsController setObjectClass:[NSThread class]];
    [_threadsController bind:@"contentArray" toObject:self withKeyPath:@"threads" options:NULL];
	
	return self;
}

-(void)dealloc {
	[_threads release];
	[super dealloc];
}

#pragma mark Interface

-(NSUInteger)threadsCount {
	return [self countOfThreads];
}

-(NSThread*)threadAtIndex:(NSUInteger)index {
	return [self objectInThreadsAtIndex:index];
}

-(void)addThread:(NSThread*)thread
{
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(addThread:) withObject:thread waitUntilDone: NO];
	} else if (![_threads containsObject:thread]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExit:) name:NSThreadWillExitNotification object:thread];
		[[self mutableArrayValueForKey:@"threads"] addObject:thread];
		//// We need this to avoid the exit before created bug...
		//[[ActivityWindowController defaultController].tableView reloadData];
		//[[ActivityWindowController defaultController].tableView display];
	}
}

-(void)addThreadAndStart:(NSThread*)thread {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(addThreadAndStart:) withObject:thread waitUntilDone: NO];
	} else if (![_threads containsObject:thread]) {
		[self addThread:thread];
		if (![thread isMainThread] && ![thread isExecuting])
			[thread start]; // We need to start the thread NOW, to be sure, it happens AFTER the addObject
	}
}

-(void)removeThread:(NSThread*)thread {
	if (![[NSThread currentThread] isMainThread])
		[self performSelectorOnMainThread:@selector(removeThread:) withObject:thread waitUntilDone:NO];
	else if ([_threads containsObject:thread]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:thread];
		[[self mutableArrayValueForKey:@"threads"] removeObject:thread];
	}
}

-(void)threadWillExit:(NSNotification*)notification {
	[self removeThread:notification.object];
}

#pragma mark Core Data

-(NSUInteger)countOfThreads {
    return [_threads count];
}

-(id)objectInThreadsAtIndex:(NSUInteger)index {
    return [_threads objectAtIndex:index];
}

-(void)insertObject:(id)obj inThreadsAtIndex:(NSUInteger)index {
    [_threads insertObject:obj atIndex:index];
}

-(void)removeObjectFromThreadsAtIndex:(NSUInteger)index {
    [_threads removeObjectAtIndex:index];
}

-(void)replaceObjectInThreadsAtIndex:(NSUInteger)index withObject:(id)obj {
    [_threads replaceObjectAtIndex:index withObject:obj];
}

@end
