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

#import "CPRGenerator.h"
#import "CPRVolumeData.h"
#import "CPRGeneratorRequest.h"
#import "CPRGeneratorOperation.h"
#import "DCMPix.h"

static NSOperationQueue *_synchronousRequestQueue = nil;
NSString * const _CPRGeneratorRunLoopMode = @"_CPRGeneratorRunLoopMode";

@interface CPRGenerator ()

+ (NSOperationQueue *)_synchronousRequestQueue;
- (void)_didFinishOperation;
- (void)_cullGeneratedFrameTimes;
- (void)_logFrameRate:(NSTimer *)timer;

@end


@implementation CPRGenerator

@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;

+ (NSOperationQueue *)_synchronousRequestQueue
{
    @synchronized (self) {
        if (_synchronousRequestQueue == nil) {
            _synchronousRequestQueue = [[NSOperationQueue alloc] init];
            
            NSUInteger threads = [[NSProcessInfo processInfo] processorCount];
            if( threads > 2)
                threads = 2;
            
			[_synchronousRequestQueue setMaxConcurrentOperationCount: threads];
        }
    }
    
    return _synchronousRequestQueue;
}



+ (CPRVolumeData *)synchronousRequestVolume:(CPRGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData
{
    CPRGeneratorOperation *operation;
    NSOperationQueue *operationQueue;
    CPRVolumeData *generatedVolume;
    
    operation = [[[request operationClass] alloc] initWithRequest:request volumeData:volumeData];
	[operation setQueuePriority:NSOperationQueuePriorityVeryHigh];
    operationQueue = [self _synchronousRequestQueue];
    [operationQueue addOperation:operation];
    [operationQueue waitUntilAllOperationsAreFinished];
    generatedVolume = [[operation.generatedVolume retain] autorelease];
    [operation release];
    
    return generatedVolume;
}

- (id)initWithVolumeData:(CPRVolumeData *)volumeData
{
	assert([NSThread isMainThread]);

    if ( (self = [super init]) ) {
        _volumeData = [volumeData retain];
        _generatorQueue = [[NSOperationQueue alloc] init];
        
        NSUInteger threads = [[NSProcessInfo processInfo] processorCount];
        if( threads > 2)
            threads = 2;
        
        [_generatorQueue setMaxConcurrentOperationCount: threads];
        _observedOperations = [[NSMutableSet alloc] init];
        _finishedOperations = [[NSMutableArray alloc] init];
        _generatedFrameTimes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_volumeData release];
    _volumeData = nil;
    [_generatorQueue release];
    _generatorQueue = nil;
    [_observedOperations release];
    _observedOperations = nil;
    [_finishedOperations release];
    _finishedOperations = nil;
    [_generatedFrameTimes release];
    _generatedFrameTimes = nil;
    [super dealloc];
}

- (void)runUntilAllRequestsAreFinished
{
	assert([NSThread isMainThread]);

	while( [_observedOperations count] > 0) {
		[[NSRunLoop mainRunLoop] runMode:_CPRGeneratorRunLoopMode beforeDate:[NSDate distantFuture]];
	}
}

- (void)requestVolume:(CPRGeneratorRequest *)request
{
    CPRGeneratorOperation *operation;
 
	assert([NSThread isMainThread]);

    for (operation in _observedOperations) {
        if ([operation isExecuting] == NO && [operation isFinished] == NO) {
            [operation cancel];
        }
    }
    
    operation = [[[request operationClass] alloc] initWithRequest:[[request copy] autorelease] volumeData:_volumeData];
	[operation setQueuePriority:NSOperationQueuePriorityNormal];
    [self retain]; // so that the generator can't disappear while the operation is running
    [operation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_generatorQueue];
    [_observedOperations addObject:operation];
    [_generatorQueue addOperation:operation];
    
    [operation release];
}

- (CGFloat)frameRate
{
	assert([NSThread isMainThread]);

    [self _cullGeneratedFrameTimes];
    return (CGFloat)[_generatedFrameTimes count] / 4.0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CPRGeneratorOperation *generatorOperation;
    if (context == &self->_generatorQueue) {
        assert([object isKindOfClass:[CPRGeneratorOperation class]]);
        generatorOperation = (CPRGeneratorOperation *)object;
        
        if ([keyPath isEqualToString:@"isFinished"]) {
            if ([object isFinished]) {
                @synchronized (_finishedOperations) {
                    [_finishedOperations addObject:generatorOperation];
                }
                [self performSelectorOnMainThread:@selector(_didFinishOperation) withObject:nil waitUntilDone:NO
											modes:[NSArray arrayWithObjects:NSRunLoopCommonModes, _CPRGeneratorRunLoopMode, nil]];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)_didFinishOperation;
{
    CPRVolumeData *volumeData;
    CPRGeneratorOperation *operation;
    NSArray *finishedOperations;
	NSInteger i;
    BOOL sentGeneratedVolume;
    
	assert([NSThread isMainThread]);

    sentGeneratedVolume = NO;
    
    @synchronized (_finishedOperations) {
        finishedOperations = [_finishedOperations copy];
        [_finishedOperations removeAllObjects];
    }
    
	for (i = [finishedOperations count] - 1; i >= 0; i--) {
		operation = [finishedOperations objectAtIndex:i];
        [operation removeObserver:self forKeyPath:@"isFinished"];
        [self autorelease]; // to match the retain in -[CPRGenerator requestVolume:]
        
        volumeData = operation.generatedVolume;
        if (volumeData && [operation isCancelled] == NO && sentGeneratedVolume == NO) {
			[_generatedFrameTimes addObject:[NSDate date]];
			[self _cullGeneratedFrameTimes];
            if ([_delegate respondsToSelector:@selector(generator:didGenerateVolume:request:)]) {
                [_delegate generator:self didGenerateVolume:operation.generatedVolume request:operation.request];
            }
            sentGeneratedVolume = YES;
        } else {
            if ([_delegate respondsToSelector:@selector(generator:didAbandonRequest:)]) {
                [_delegate generator:self didAbandonRequest:operation.request];
            }
        }
        [_observedOperations removeObject:operation];
    }
    
    [finishedOperations release];
}

- (void)_cullGeneratedFrameTimes
{
    BOOL done;
    
	assert([NSThread isMainThread]);

    // remove times that are older than 4 seconds
    done = NO;
    while (!done) {
        if ([_generatedFrameTimes count] && [[_generatedFrameTimes objectAtIndex:0] timeIntervalSinceNow] < -4.0) {
            [_generatedFrameTimes removeObjectAtIndex:0];
        } else {
            done = YES;
        }
    }
}

- (void)_logFrameRate:(NSTimer *)timer
{
    NSLog(@"CPRGenerator frame rate: %f", [self frameRate]);
}

@end













