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

#import "CPRStraightenedOperation.h"
#import "CPRGeneratorRequest.h"
#import "N3Geometry.h"
#import "N3BezierCore.h"
#import "N3BezierCoreAdditions.h"
#import "N3BezierPath.h"
#import "CPRVolumeData.h"
#import "CPRHorizontalFillOperation.h"
#import "CPRProjectionOperation.h"
#include <libkern/OSAtomic.h>

static const NSUInteger FILL_HEIGHT = 40;
static NSOperationQueue *_straightenedOperationFillQueue = nil;

@interface CPRStraightenedOperation ()

+ (NSOperationQueue *) _fillQueue;
- (CGFloat)_slabSampleDistance;
- (NSUInteger)_pixelsDeep;

@end


@implementation CPRStraightenedOperation

@dynamic request;

- (id)initWithRequest:(CPRStraightenedGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData
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
    CGFloat bezierLength;
    CGFloat fillDistance;
    CGFloat slabDistance;
    NSInteger numVectors;
    NSInteger i;
    NSInteger y;
    NSInteger z;
    NSInteger pixelsWide;
    NSInteger pixelsHigh;
    NSInteger pixelsDeep;
    N3VectorArray vectors;
    N3VectorArray fillVectors;
    N3VectorArray fillNormals;
    N3VectorArray normals;
    N3VectorArray tangents;
    N3VectorArray inSlabNormals;
    N3MutableBezierCoreRef flattenedBezierCore;
    CPRHorizontalFillOperation *horizontalFillOperation;
    NSMutableSet *fillOperations;
	NSOperationQueue *fillQueue;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        if ([self isCancelled] == NO && self.request.pixelsHigh > 0) {        
            flattenedBezierCore = N3BezierCoreCreateMutableCopy([self.request.bezierPath N3BezierCore]);
            N3BezierCoreSubdivide(flattenedBezierCore, 3.0);
            N3BezierCoreFlatten(flattenedBezierCore, 0.6);
            bezierLength = N3BezierCoreLength(flattenedBezierCore);
            pixelsWide = self.request.pixelsWide;
            pixelsHigh = self.request.pixelsHigh;
            pixelsDeep = [self _pixelsDeep];
            
            numVectors = pixelsWide;
            _sampleSpacing = bezierLength / (CGFloat)pixelsWide;
            
            _floatBytes = malloc(sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep);
            vectors = malloc(sizeof(N3Vector) * pixelsWide);
            fillVectors = malloc(sizeof(N3Vector) * pixelsWide);
            fillNormals = malloc(sizeof(N3Vector) * pixelsWide);
            tangents = malloc(sizeof(N3Vector) * pixelsWide);
            normals = malloc(sizeof(N3Vector) * pixelsWide);
            inSlabNormals = malloc(sizeof(N3Vector) * pixelsWide);
            
            if (_floatBytes == NULL || vectors == NULL || fillVectors == NULL || fillNormals == NULL || tangents == NULL || normals == NULL || inSlabNormals == NULL) {
                free(_floatBytes);
                free(vectors);
                free(fillVectors);
                free(fillNormals);
                free(tangents);
                free(normals);
                free(inSlabNormals);
                
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
                
                N3BezierCoreRelease(flattenedBezierCore);
                return;
            }
            
            numVectors = N3BezierCoreGetVectorInfo(flattenedBezierCore, _sampleSpacing, 0, self.request.initialNormal, vectors, tangents, normals, pixelsWide);
            
            if (numVectors > 0) {
                while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
                    vectors[numVectors] = vectors[numVectors - 1];
                    tangents[numVectors] = tangents[numVectors - 1];
                    normals[numVectors] = normals[numVectors - 1];
                    numVectors++;
                }
            } else { // there are no vectors at all to copy from, so just zero out everthing
                while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
                    vectors[numVectors] = N3VectorZero;
                    tangents[numVectors] = N3VectorZero;
                    normals[numVectors] = N3VectorZero;
                    numVectors++;
                }
            }

                    
            memcpy(fillNormals, normals, sizeof(N3Vector) * pixelsWide);
            N3VectorScalarMultiplyVectors(_sampleSpacing, fillNormals, pixelsWide);
            
            memcpy(inSlabNormals, normals, sizeof(N3Vector) * pixelsWide);
            N3VectorCrossProductWithVectors(inSlabNormals, tangents, pixelsWide);
            N3VectorScalarMultiplyVectors([self _slabSampleDistance], inSlabNormals, pixelsWide);
            
            fillOperations = [NSMutableSet set];
            
            for (z = 0; z < pixelsDeep; z++) {
                for (y = 0; y < pixelsHigh; y += FILL_HEIGHT) {
                    fillDistance = (CGFloat)y - (CGFloat)(pixelsHigh - 1)/2.0; // the distance to go out from the centerline
                    slabDistance = (CGFloat)z - (CGFloat)(pixelsDeep - 1)/2.0; // the distance to go out from the centerline
                    for (i = 0; i < pixelsWide; i++) {
                        fillVectors[i] = N3VectorAdd(N3VectorAdd(vectors[i], N3VectorScalarMultiply(fillNormals[i], fillDistance)), N3VectorScalarMultiply(inSlabNormals[i], slabDistance));
                    }
                    
                    horizontalFillOperation = [[CPRHorizontalFillOperation alloc] initWithVolumeData:_volumeData interpolationMode:self.request.interpolationMode floatBytes:_floatBytes + (y*pixelsWide) + (z*pixelsWide*pixelsHigh) width:pixelsWide height:MIN(FILL_HEIGHT, pixelsHigh - y)
                                                                                             vectors:fillVectors normals:fillNormals];
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
            
            _outstandingFillOperationCount = (int32_t)[fillOperations count];
            			
			fillQueue = [[self class] _fillQueue];
			for (horizontalFillOperation in fillOperations) {
				[fillQueue addOperation:horizontalFillOperation];
			}
			
			free(vectors);
            free(fillVectors);
            free(fillNormals);
            free(tangents);
            free(normals);
            free(inSlabNormals);
            N3BezierCoreRelease(flattenedBezierCore);
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
                oustandingFillOperationCount = OSAtomicDecrement32Barrier(&_outstandingFillOperationCount);
                if (oustandingFillOperationCount == 0) { // done with the fill operations, now do the projection
                    volumeTransform = N3AffineTransformMakeScale(1.0/_sampleSpacing, 1.0/_sampleSpacing, 1.0/[self _slabSampleDistance]);
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

+ (NSOperationQueue *)_fillQueue
{
    @synchronized (self) {
        if (_straightenedOperationFillQueue == nil) {
            _straightenedOperationFillQueue = [[NSOperationQueue alloc] init];
			[_straightenedOperationFillQueue setMaxConcurrentOperationCount:[[NSProcessInfo processInfo] processorCount]];
        }
    }
    
    return _straightenedOperationFillQueue;
}

- (CGFloat)_slabSampleDistance
{
    if (self.request.slabSampleDistance != 0.0) {
        return self.request.slabSampleDistance;
    } else {
        return self.volumeData.minPixelSpacing; // this should be /2.0 to hit nyquist spacing, but it is too slow, and with this implementation to memory intensive
    }
}

- (NSUInteger)_pixelsDeep
{
    return MAX(self.request.slabWidth / [self _slabSampleDistance], 0) + 1;
}


@end











