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
#import "NSThread+N2.h"

@implementation ThreadsManager

@synthesize threadsController = _threadsController;

+(ThreadsManager*)defaultManager {
	static ThreadsManager* threadsManager = [[self alloc] init];
	return threadsManager;
}

-(id)init {
	self = [super init];
	
	//_threads = [[NSMutableArray alloc] init];
	
	_threadsController = [[NSArrayController alloc] init];
	[_threadsController setSelectsInsertedObjects:NO];
	[_threadsController setAvoidsEmptySelection:NO];
	[_threadsController setObjectClass:[NSThread class]];
	
	return self;
}

-(void)dealloc {
	[_threadsController release];
	[super dealloc];
}

#pragma mark Interface

-(NSArray*)threads {
	@synchronized (_threadsController) {
		return _threadsController.arrangedObjects;
	} return nil;
}

-(NSUInteger)threadsCount {
	@synchronized (_threadsController) {
		return [_threadsController.arrangedObjects count];
	} return nil;
}

-(NSThread*)threadAtIndex:(NSUInteger)index {
	@synchronized (_threadsController) {
		return [_threadsController.arrangedObjects objectAtIndex:index];
	} return nil;
}

-(void)subAddThread:(NSThread*)thread
{
	@synchronized (_threadsController) {
	@synchronized (thread)
	{
		if (![NSThread isMainThread])
			NSLog( @"***** NSThread we should NOT be here");
		
		if ([_threadsController.arrangedObjects containsObject:thread])
			return;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExit:) name:NSThreadWillExitNotification object:thread];
		[_threadsController addObject:thread];
		
		if (![thread isMainThread] && ![thread isExecuting])
			@try {
				[thread start]; // We need to start the thread NOW, to be sure, it happens AFTER the addObject
			} @catch (NSException* e) { // ignore
			}
		
		[thread release]; // This is not a memory leak - See Below
	}
	}
}

-(void)addThreadAndStart:(NSThread*)thread
{
	@synchronized (_threadsController) {
	@synchronized (thread)
	{
		[thread retain]; // This is not a memory leak - release will happen in subAddThread:
		
		if (![NSThread isMainThread])
			[self performSelectorOnMainThread:@selector(subAddThread:) withObject:thread waitUntilDone: NO];
		else [self subAddThread:thread];
	}
	}
}

-(void) subRemoveThread:(NSThread*)thread
{
	@synchronized (_threadsController) {
	@synchronized (thread)
	{
		if (![NSThread isMainThread])
			NSLog( @"***** NSThread we should NOT be here");

		if (![_threadsController.arrangedObjects containsObject:thread])
			return;
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:thread];
		[_threadsController removeObject:thread];
		
		[thread release]; // This is not a memory leak - See Below
	}
	}
}

-(void)removeThread:(NSThread*)thread
{
	@synchronized (_threadsController) {
	@synchronized (thread)
	{
		[thread retain]; // This is not a memory leak - release will happen in subRemoveThread:
		
		if (![NSThread isMainThread])
			[self performSelectorOnMainThread:@selector(subRemoveThread:) withObject:thread waitUntilDone:NO];
		else [self subRemoveThread:thread];
	}
	}
}

-(void)threadWillExit:(NSNotification*)notification {
	[self removeThread:notification.object];
}

@end
