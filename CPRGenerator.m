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

@interface CPRGenerator ()

- (void)_didFinishOperation;
- (void)_cullGeneratedFrameTimes;
- (void)_logFrameRate:(NSTimer *)timer;

@end


@implementation CPRGenerator

@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;

+ (CPRVolumeData *)synchronousRequestVolume:(CPRGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData
{
    CPRGeneratorOperation *operation;
    NSOperationQueue *operationQueue;
    CPRVolumeData *generatedVolume;
    
    operation = [[[request operationClass] alloc] initWithRequest:request volumeData:volumeData];
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue addOperation:operation];
    [operationQueue waitUntilAllOperationsAreFinished];
    generatedVolume = [[operation.generatedVolume retain] autorelease];
    [operation release];
    [operationQueue release];
    
    return generatedVolume;
}

- (id)initWithVolumeData:(CPRVolumeData *)volumeData
{
    if ( (self = [super init]) ) {
        _volumeData = [volumeData retain];
        _generatorQueue = [[NSOperationQueue alloc] init];
        [_generatorQueue setMaxConcurrentOperationCount:1];
        _observedOperations = [[NSMutableSet alloc] init];
        _finishedOperations = [[NSMutableArray alloc] init];
        _generatedFrameTimes = [[NSMutableArray alloc] init];
        
//        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_logFrameRate:) userInfo:nil repeats:YES];
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

- (void) waitUntilAllOperationsAreFinished
{
	[_generatorQueue waitUntilAllOperationsAreFinished];
	[self _didFinishOperation];
}

- (void)requestVolume:(CPRGeneratorRequest *)request
{
    CPRGeneratorOperation *operation;
    
    for (operation in _observedOperations) {
        if ([operation isExecuting] == NO) {
            [operation cancel];
        }
    }
    
    operation = [[[request operationClass] alloc] initWithRequest:request volumeData:_volumeData];
    [self retain]; // so that the generator can't disappear while the operation is running
    [operation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_generatorQueue];
    [_observedOperations addObject:operation];
    [_generatorQueue addOperation:operation];
    
    [operation release];
}

- (CGFloat)frameRate
{
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
                [self performSelectorOnMainThread:@selector(_didFinishOperation) withObject:nil waitUntilDone:NO];
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
    BOOL sentGeneratedVolume;
    
    sentGeneratedVolume = NO;
    
    @synchronized (_finishedOperations) {
        finishedOperations = [_finishedOperations copy];
        [_finishedOperations removeAllObjects];
    }
    
    for (operation in finishedOperations) {
        [operation removeObserver:self forKeyPath:@"isFinished"];
        [self autorelease]; // to match the retain in -[CPRGenerator requestVolume:]
        
        volumeData = operation.generatedVolume;
        if (volumeData && [operation isCancelled] == NO && sentGeneratedVolume == NO) {
            if ([_delegate respondsToSelector:@selector(generator:didGenerateVolume:request:)]) {
                [_generatedFrameTimes addObject:[NSDate date]];
                [self _cullGeneratedFrameTimes];
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













