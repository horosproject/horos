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

#import "CPRObliqueSliceOperation.h"
#import "CPRHorizontalFillOperation.h"
#import "CPRProjectionOperation.h"
#import "CPRGeneratorRequest.h"
#import "CPRVolumeData.h"
#include <libkern/OSAtomic.h>


static const NSUInteger FILL_HEIGHT = 40;
static NSOperationQueue *_obliqueSliceOperationFillQueue = nil;

@interface CPRObliqueSliceOperation ()

+ (NSOperationQueue *) _fillQueue;
- (CGFloat)_slabSampleDistance;
- (NSUInteger)_pixelsDeep;
- (N3AffineTransform)_generatedVolumeTransform;

@end


@implementation CPRObliqueSliceOperation

@dynamic request;

- (id)initWithRequest:(CPRObliqueSliceGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData
{
    if ( (self = [super initWithRequest:request volumeData:volumeData]) ) {
        _fillOperations = [[NSMutableSet alloc] init];
        
    }
    return self;
}

- (void)dealloc
{
    [_fillOperations release];
    _fillOperations = nil;
    [_projectionOperation release];
	_projectionOperation = nil;
    [super dealloc];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting {
    return _operationExecuting;
}

- (BOOL)isFinished {
    return _operationFinished;
}

- (BOOL)didFail
{
    return _operationFailed;
}

- (void)cancel
{
    NSOperation *operation;
    @synchronized (_fillOperations) {
        for (operation in _fillOperations) {
            [operation cancel];
        }
    }
    [_projectionOperation cancel];
    
    [super cancel];
}

- (void)start
{
    if ([self isCancelled])
    {
        [self willChangeValueForKey:@"isFinished"];
        _operationFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    _operationExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self main];
}

- (void)main
{
    NSInteger i;
    NSInteger y;
    NSInteger z;
    NSInteger pixelsWide;
    NSInteger pixelsHigh;
    NSInteger pixelsDeep;
    N3Vector origin;
    N3Vector leftDirection;
    N3Vector downDirection;
    N3Vector inSlabNormal;
    N3Vector heightOffset;
    N3Vector slabOffset;
    N3VectorArray vectors;
    N3VectorArray downVectors;
    N3VectorArray fillVectors;
    CPRHorizontalFillOperation *horizontalFillOperation;
    NSMutableSet *fillOperations;
	NSOperationQueue *fillQueue;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        
        
        if ([self isCancelled] == NO && self.request.pixelsHigh > 0) {        
            pixelsWide = self.request.pixelsWide;
            pixelsHigh = self.request.pixelsHigh;
            pixelsDeep = [self _pixelsDeep];
            origin = self.request.origin;
            leftDirection = N3VectorScalarMultiply(N3VectorNormalize(self.request.directionX), self.request.pixelSpacingX);
            downDirection = N3VectorScalarMultiply(N3VectorNormalize(self.request.directionY), self.request.pixelSpacingY);
            inSlabNormal = N3VectorScalarMultiply(N3VectorNormalize(N3VectorCrossProduct(leftDirection, downDirection)), [self _slabSampleDistance]);
                        
            _floatBytes = malloc(sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep);
            vectors = malloc(sizeof(N3Vector) * pixelsWide);
            fillVectors = malloc(sizeof(N3Vector) * pixelsWide);
            downVectors = malloc(sizeof(N3Vector) * pixelsWide);
            
            if (_floatBytes == NULL || vectors == NULL || fillVectors == NULL || downVectors == NULL) {
                free(_floatBytes);
                free(vectors);
                free(fillVectors);
                free(downVectors);
                
                _floatBytes = NULL;
                
                [self willChangeValueForKey:@"didFail"];
                [self willChangeValueForKey:@"isFinished"];
                [self willChangeValueForKey:@"isExecuting"];
                _operationExecuting = NO;
                _operationFinished = YES;
                _operationFailed = YES;
                [self didChangeValueForKey:@"isExecuting"];
                [self didChangeValueForKey:@"isFinished"];
                [self didChangeValueForKey:@"didFail"];
                
                return;
            }
            
            for (i = 0; i < pixelsWide; i++) {
                vectors[i] = N3VectorAdd(origin, N3VectorScalarMultiply(leftDirection, (CGFloat)i));
                downVectors[i] = downDirection;
            }
            
                        
            fillOperations = [NSMutableSet set];
            
            for (z = 0; z < pixelsDeep; z++) {
                slabOffset = N3VectorScalarMultiply(inSlabNormal, (CGFloat)z - (CGFloat)(pixelsDeep - 1)/2.0);
                for (y = 0; y < pixelsHigh; y += FILL_HEIGHT) {
                    heightOffset = N3VectorScalarMultiply(downDirection, (CGFloat)y);
                    for (i = 0; i < pixelsWide; i++) {
                        fillVectors[i] = N3VectorAdd(N3VectorAdd(vectors[i], heightOffset), slabOffset);
                    }
                    
                    horizontalFillOperation = [[CPRHorizontalFillOperation alloc] initWithVolumeData:_volumeData interpolationMode:self.request.interpolationMode floatBytes:_floatBytes + (y*pixelsWide) + (z*pixelsWide*pixelsHigh) width:pixelsWide height:MIN(FILL_HEIGHT, pixelsHigh - y)
                                                                                             vectors:fillVectors normals:downVectors];
                    [horizontalFillOperation setQueuePriority:[self queuePriority]];
					[fillOperations addObject:horizontalFillOperation];
                    [horizontalFillOperation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_fillOperations];
                    [self retain]; // so we don't get release while the operation is going
                    [horizontalFillOperation release];
                }
            }
            
            @synchronized (_fillOperations) {
                [_fillOperations setSet:fillOperations];
            }            
            
            if ([self isCancelled]) {
                for (horizontalFillOperation in fillOperations) {
                    [horizontalFillOperation cancel];
                }                
            }
            
            _oustandingFillOperationCount = (int32_t)[fillOperations count];
            
			fillQueue = [[self class] _fillQueue];
			for (horizontalFillOperation in fillOperations) {
				[fillQueue addOperation:horizontalFillOperation];
			}
			
			free(vectors);
            free(fillVectors);
            free(downVectors);
        } else {
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            _operationExecuting = NO;
            _operationFinished = YES;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
            return;
        }
    }
    @catch (...) {
        [self willChangeValueForKey:@"isFinished"];
        [self willChangeValueForKey:@"isExecuting"];
        _operationExecuting = NO;
        _operationFinished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
    }
    @finally {
        [pool release];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSOperation *operation;
    CPRVolumeData *generatedVolume;
    N3AffineTransform volumeTransform;
    CPRProjectionOperation *projectionOperation;
    int32_t oustandingFillOperationCount;
    
    if (context == &self->_fillOperations) {
        assert([object isKindOfClass:[NSOperation class]]);
        operation = (NSOperation *)object;
        
        if ([keyPath isEqualToString:@"isFinished"]) {
            if ([operation isFinished]) {
                [operation removeObserver:self forKeyPath:@"isFinished"];
                [self autorelease]; // to balance the retain when we observe operations
                oustandingFillOperationCount = OSAtomicDecrement32Barrier(&_oustandingFillOperationCount);
                if (oustandingFillOperationCount == 0) { // done with the fill operations, now do the projection
                    volumeTransform = [self _generatedVolumeTransform];
                    generatedVolume = [[CPRVolumeData alloc] initWithFloatBytesNoCopy:_floatBytes pixelsWide:self.request.pixelsWide pixelsHigh:self.request.pixelsHigh pixelsDeep:[self _pixelsDeep]
                                                                      volumeTransform:volumeTransform outOfBoundsValue:_volumeData.outOfBoundsValue freeWhenDone:YES];
                    _floatBytes = NULL;
                    projectionOperation = [[CPRProjectionOperation alloc] init];
					[projectionOperation setQueuePriority:[self queuePriority]];
					
                    projectionOperation.volumeData = generatedVolume;
                    projectionOperation.projectionMode = self.request.projectionMode;
					if ([self isCancelled]) {
						[projectionOperation cancel];
					}
                    
                    [generatedVolume release];
                    [projectionOperation addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_fillOperations];
                    [self retain]; // so we don't get released while the operation is going
                    _projectionOperation = projectionOperation;
                    [[[self class] _fillQueue] addOperation:projectionOperation];
                } else if (oustandingFillOperationCount == -1) {
                    assert([operation isKindOfClass:[CPRProjectionOperation class]]);
                    projectionOperation = (CPRProjectionOperation *)operation;
                    self.generatedVolume = projectionOperation.generatedVolume;
                    
                    [self willChangeValueForKey:@"isFinished"];
                    [self willChangeValueForKey:@"isExecuting"];
                    _operationExecuting = NO;
                    _operationFinished = YES;
                    [self didChangeValueForKey:@"isExecuting"];
                    [self didChangeValueForKey:@"isFinished"];
                }
                
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+ (NSOperationQueue *) _fillQueue
{
    @synchronized (self) {
        if (_obliqueSliceOperationFillQueue == nil) {
            _obliqueSliceOperationFillQueue = [[NSOperationQueue alloc] init];
			[_obliqueSliceOperationFillQueue setMaxConcurrentOperationCount:[[NSProcessInfo processInfo] processorCount]];
        }
    }
    
    return _obliqueSliceOperationFillQueue;
}

- (CGFloat)_slabSampleDistance
{
    if (self.request.slabSampleDistance != 0.0) {
        return self.request.slabSampleDistance;
    } else {
        return self.volumeData.minPixelSpacing;
    }
}

- (NSUInteger)_pixelsDeep
{
    return MAX(self.request.slabWidth / [self _slabSampleDistance], 0) + 1;
}

- (N3AffineTransform)_generatedVolumeTransform
{
    N3AffineTransform volumeTransform;
    N3Vector leftDirection;
    N3Vector downDirection;
    N3Vector inSlabNormal;
    N3Vector volumeOrigin;
    
    leftDirection = N3VectorScalarMultiply(N3VectorNormalize(self.request.directionX), self.request.pixelSpacingX);
    downDirection = N3VectorScalarMultiply(N3VectorNormalize(self.request.directionY), self.request.pixelSpacingY);
    inSlabNormal = N3VectorScalarMultiply(N3VectorNormalize(N3VectorCrossProduct(leftDirection, downDirection)), [self _slabSampleDistance]);
    
    volumeOrigin = N3VectorAdd(self.request.origin, N3VectorScalarMultiply(inSlabNormal, (CGFloat)([self _pixelsDeep] - 1)/-2.0));
    
    volumeTransform = N3AffineTransformIdentity;
    volumeTransform.m41 = volumeOrigin.x;
    volumeTransform.m42 = volumeOrigin.y;
    volumeTransform.m43 = volumeOrigin.z;
    volumeTransform.m11 = leftDirection.x;
    volumeTransform.m12 = leftDirection.y;
    volumeTransform.m13 = leftDirection.z;
    volumeTransform.m21 = downDirection.x;
    volumeTransform.m22 = downDirection.y;
    volumeTransform.m23 = downDirection.z;
    volumeTransform.m31 = inSlabNormal.x;
    volumeTransform.m32 = inSlabNormal.y;
    volumeTransform.m33 = inSlabNormal.z;
    
    volumeTransform = N3AffineTransformInvert(volumeTransform);
    return volumeTransform;
}

@end































