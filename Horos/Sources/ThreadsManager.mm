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

#import "ThreadsManager.h"
#import "ThreadModalForWindowController.h"
#import "NSThread+N2.h"

@interface ThreadsManager ()

-(void)subRemoveThread:(NSThread*)thread;

@end

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
    
    // cleanup timer
	_timer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(cleanupFinishedThreads:) userInfo:nil repeats:YES] retain];
    
	return self;
}

-(void)dealloc {
    [_timer invalidate];
    [_timer release];
	[_threadsController release];
	[super dealloc];
}

-(void)cleanupFinishedThreads:(NSTimer*)timer {
    @synchronized (_threadsController) {
        for (NSThread* thread in [[_threadsController.content copy] autorelease])
        {
            if (thread.isFinished)
                [self subRemoveThread:thread];
        }
    }
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
	} return 0;
}

-(NSThread*)threadAtIndex:(NSUInteger)index {
	@synchronized (_threadsController) {
		return [_threadsController.arrangedObjects objectAtIndex:index];
	} return nil;
}

-(void)subAddThread:(NSThread*)thread
{
	@synchronized (_threadsController)
    {
	@synchronized (thread)
	{
		if (![NSThread isMainThread])
			NSLog( @"***** NSThread we should NOT be here");
        
		if ([_threadsController.arrangedObjects containsObject:thread] || [thread isFinished])
		{
            // Do nothing
        }
		else
        {
            if (![thread isMainThread]/* && ![thread isExecuting]*/)
            {
                BOOL isExe = [thread isExecuting], isDone = [thread isFinished];
                
                @try
                {

                    if (!isDone) {
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExit:) name:NSThreadWillExitNotification object:thread];
                        [_threadsController addObject:thread];
                    }
                    if (!isExe && !isDone) { // not executing, not done executing... execute now
                        [thread start];
                    }
                    
                    if ([thread isFinished]) // already done?? wtf..
                    {
                        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:thread];
                        [_threadsController removeObject:thread];
                    }
                }
                @catch (NSException* e)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:thread];
                    [_threadsController removeObject:thread];
                }
            }
        }
	}
    }
}

-(void)addThreadAndStart:(NSThread*)thread
{
    if (![NSThread isMainThread])
    {
        if( [thread isExecuting] == NO && [thread isFinished] == NO)
            [thread start]; // We want to start it immediately: subAddThread must add it on main thread: the main thread is maybe locked.
        [self performSelectorOnMainThread:@selector(subAddThread:) withObject:thread waitUntilDone: NO];
    }
    else [self subAddThread:thread];
}

-(void) subRemoveThread:(NSThread*)thread
{
	@synchronized (_threadsController) {
	@synchronized (thread)
	{
		if (![NSThread isMainThread])
			NSLog( @"***** NSThread we should NOT be here");
        
        if ([_threadsController.content containsObject:thread]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:thread];
            [_threadsController removeObject:thread];
        }
	}
	}
}

-(void)removeThread:(NSThread*)thread
{
    if (![NSThread isMainThread])
        [self performSelectorOnMainThread:@selector(subRemoveThread:) withObject:thread waitUntilDone:NO];
    else [self subRemoveThread:thread];
}

-(void)threadWillExit:(NSNotification*)notification {
	[self removeThread:notification.object];
}

@end
