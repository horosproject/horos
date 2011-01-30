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

#import "CPRHorizontalFillOperation.h"
#import "CPRVolumeData.h"
#import "CPRGeometry.h"

@interface CPRHorizontalFillOperation ()

- (void)_nearestNeighborFill;
- (void)_linearInterpolatingFill;

@end


@implementation CPRHorizontalFillOperation

@synthesize volumeData = _volumeData;
@synthesize width = _width;
@synthesize height = _height;
@synthesize floatBytes = _floatBytes;
@synthesize vectors = _vectors;
@synthesize normals = _normals;
@synthesize linearInterpolating = _linearInterpolating;

- (id)initWithVolumeData:(CPRVolumeData *)volumeData floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(CPRVectorArray)vectors normals:(CPRVectorArray)normals
{
    if ( (self = [super init])) {
        _volumeData = [volumeData retain];
        _floatBytes = floatBytes;
        _width = width;
        _height = height;
        _vectors = malloc(width * sizeof(CPRVector));
        memcpy(_vectors, vectors, width * sizeof(CPRVector));
        _normals = malloc(width * sizeof(CPRVector));
        memcpy(_normals, normals, width * sizeof(CPRVector));
        _linearInterpolating = YES;
    }
    return self;
}

- (void)dealloc
{
    [_volumeData release];
    _volumeData = nil;
    free(_vectors);
    _vectors = NULL;
    free(_normals);
    _normals = NULL;
    [super dealloc];
}

- (void)main
{
    NSAutoreleasePool *pool;
    double threadPriority;
    
    @try {
        pool = [[NSAutoreleasePool alloc] init];
        
        if ([self isCancelled]) {
			[pool release];
            return;
        }
        
        threadPriority = [NSThread threadPriority];
        [NSThread setThreadPriority:threadPriority * .5];
        
        if (_linearInterpolating) {
            [self _linearInterpolatingFill];
        } else {
            [self _nearestNeighborFill];
        }
        
        [NSThread setThreadPriority:threadPriority];
        
        [pool release];
    }
    @catch (...) {
    }
}

- (void)_linearInterpolatingFill
{
    NSUInteger x;
    NSUInteger y;
    CPRAffineTransform3D vectorTransform;
    CPRVectorArray volumeVectors;
    CPRVectorArray volumeNormals;
    CPRVolumeDataInlineBuffer inlineBuffer;
    
    volumeVectors = malloc(_width * sizeof(CPRVector));
    memcpy(volumeVectors, _vectors, _width * sizeof(CPRVector));
    CPRVectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);
    
    volumeNormals = malloc(_width * sizeof(CPRVector));
    memcpy(volumeNormals, _normals, _width * sizeof(CPRVector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    CPRVectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);
    
    [_volumeData getInlineBuffer:&inlineBuffer];
    for (y = 0; y < _height; y++) {
        if ([self isCancelled]) {
            break;
        }
        
        for (x = 0; x < _width; x++) {
            _floatBytes[y*_width + x] = CPRVolumeDataLinearInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
        }
        
        CPRVectorAddVectors(volumeVectors, volumeNormals, _width);
    }
    
    free(volumeVectors);
    free(volumeNormals);
}

- (void)_nearestNeighborFill
{
    NSLog(@"_nearestNeighborFill implement me");
    memset(_floatBytes, 0, _height * _width);
}

@end
