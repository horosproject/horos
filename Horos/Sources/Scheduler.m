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


#import "Scheduler.h"
#import "Schedulable.h"

@interface Scheduler (PrivateMethods)
-(NSSet *)_getNextUnitsToPerform;
-(void)_setNumberOfThreads:(unsigned)numThreads;
-(void)_setSchedulableObject:(NSObject <Schedulable> *)schedObj;
-(void)_setWorkUnitsRemaining:(NSMutableSet *)unitsRemaining;
@end

@implementation Scheduler

-(id)initForSchedulableObject:(NSObject <Schedulable> *)schedObj andNumberOfThreads:(unsigned)numThreads {
    if ( self = [super init] ) {
        [self _setSchedulableObject:schedObj];
        [self _setNumberOfThreads:numThreads];
        _remainingUnitsLock = [[NSLock alloc] init];
    }
    return self;
}

-(id)initForSchedulableObject:(NSObject <Schedulable> *) schedObj {
    return [self initForSchedulableObject:schedObj andNumberOfThreads: [[NSProcessInfo processInfo] processorCount]];
}

-(void)dealloc {
    [_schedulableObject release];
    [_workUnitsRemaining release];
    [_remainingUnitsLock release];
    [super dealloc];
}


-(void)performScheduleForWorkUnits:(NSSet *)workUnits {
    id <Schedulable> schedObj = [self schedulableObject];

    NSAssert( nil != schedObj, @"Schedulable object nil in performScheduleForWorkUnits:" );

    // Keep track of which units are still left to perform
    [self _setWorkUnitsRemaining: [[workUnits mutableCopy] autorelease]];

    // Set the cancellation flag
    _scheduleWasCancelled = NO;

    // Inform delegate that we are beginning
    if ( [_delegate respondsToSelector:@selector(schedulerWillBeginSchedule:)])
        [_delegate schedulerWillBeginSchedule:self];

    // Start each thread
    _numberOfDetachedThreads = 0;
    unsigned threadIndex;
    for ( threadIndex = 0; threadIndex < [self numberOfThreads]; ++threadIndex ) {
        _numberOfDetachedThreads++;
        [NSThread detachNewThreadSelector:@selector(_performWorkUnitsInWorkerThread)
            toTarget:self 
            withObject:nil];
    }
}

-(void)_performWorkUnitsInWorkerThread {
    NSSet *nextUnits = nil;
    BOOL performNextUnits;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    while ( ( nextUnits = [self _getNextUnitsToPerform] ) && !_scheduleWasCancelled ) {

        // Inform delegate that new units will be performed. Also give chance to veto.
        performNextUnits = YES;
        if ( [_delegate respondsToSelector:@selector(scheduler:shouldBeginUnits:)] )
            performNextUnits = [_delegate scheduler:self shouldBeginUnits:nextUnits];

        if ( performNextUnits ) {
            [[self schedulableObject] performWorkUnits:nextUnits forScheduler:self];

            // Inform delegate of completion
            if ( [_delegate respondsToSelector:@selector(scheduler:didCompleteUnits:)] )
                [_delegate scheduler:self didCompleteUnits:nextUnits];

        }

    }

    // Inform the main thread that this worker thread is finished its units.
    [self performSelectorOnMainThread:@selector(_didFinishPerformingWorkUnits)
        withObject:nil waitUntilDone:NO];

    [pool release];

}

// Returns the next units to perform, and removes them from the work units remaining set.
// This operation is threadsafe.
-(NSSet *)_getNextUnitsToPerform {
    NSSet *nextUnits = nil;

    // Need to lock here because a race condition could arise for the work units
    // remaining set.
    [_remainingUnitsLock lock];
    nextUnits = [self _workUnitsToExecuteForRemainingUnits:[self _workUnitsRemaining]];
    [[self _workUnitsRemaining] minusSet:nextUnits];
    [_remainingUnitsLock unlock];

    return ( 0 == [nextUnits count] ? nil : nextUnits );
}

-(unsigned) numberOfDetachedThreads
{
	return _numberOfDetachedThreads;
}

-(void)_didFinishPerformingWorkUnits {

    _numberOfDetachedThreads--;
		
    // If all workers are finished, inform the delegate of successful completion or cancellation.
    if ( 0 == _numberOfDetachedThreads ) {
        if ( !_scheduleWasCancelled &&
            [_delegate respondsToSelector:@selector(schedulerDidFinishSchedule:)] ) {
            [_delegate schedulerDidFinishSchedule:self];
        }
        else if ( _scheduleWasCancelled &&
            [_delegate respondsToSelector:@selector(schedulerDidCancelSchedule:)] ) {
            [_delegate schedulerDidCancelSchedule:self];
        }
    }

}

-(void)cancelSchedule {
    _scheduleWasCancelled = YES;
}

// Abstract method. Returns nil if there are no more units to complete.
-(NSSet *)_workUnitsToExecuteForRemainingUnits:(NSSet *)remainingUnits {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

// Accessors
-(void)_setNumberOfThreads:(unsigned)numThreads {
    _numberOfThreads = numThreads;
}

-(unsigned)numberOfThreads {
    return _numberOfThreads;
}

-(id)delegate {
    return _delegate;
}

-(void)setDelegate:(id)delegate {
    _delegate = delegate;
}

-(void)_setSchedulableObject:(NSObject <Schedulable> *)schedObj {
    [schedObj retain];
    [_schedulableObject release];
    _schedulableObject = schedObj;
}

-(id <Schedulable>)schedulableObject {
    return _schedulableObject;
}

-(void)_setWorkUnitsRemaining:(NSMutableSet *)unitsRemaining {
    [unitsRemaining retain];
    [_workUnitsRemaining release];
    _workUnitsRemaining = unitsRemaining;
}

-(NSMutableSet *)_workUnitsRemaining {
    return _workUnitsRemaining;
}

@end