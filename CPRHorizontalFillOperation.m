/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import "CPRHorizontalFillOperation.h"
#import "CPRVolumeData.h"
#import "N3Geometry.h"

@interface CPRHorizontalFillOperation ()

- (void)_nearestNeighborFill;
- (void)_linearInterpolatingFill;
- (void)_cubicInterpolatingFill;
- (void)_unknownInterpolatingFill;

@end


@implementation CPRHorizontalFillOperation

@synthesize volumeData = _volumeData;
@synthesize width = _width;
@synthesize height = _height;
@synthesize floatBytes = _floatBytes;
@synthesize vectors = _vectors;
@synthesize normals = _normals;
@synthesize interpolationMode = _interpolationMode;

- (id)initWithVolumeData:(CPRVolumeData *)volumeData interpolationMode:(CPRInterpolationMode)interpolationMode floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(N3VectorArray)vectors normals:(N3VectorArray)normals
{
    if ( (self = [super init])) {
        _volumeData = [volumeData retain];
        _floatBytes = floatBytes;
        _width = width;
        _height = height;
        _vectors = malloc(width * sizeof(N3Vector));
        memcpy(_vectors, vectors, width * sizeof(N3Vector));
        _normals = malloc(width * sizeof(N3Vector));  
        memcpy(_normals, normals, width * sizeof(N3Vector));
        _interpolationMode = interpolationMode;
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    double threadPriority;
    
    @try {
        if ([self isCancelled]) {
            return;
        }
        
        threadPriority = [NSThread threadPriority];
        [NSThread setThreadPriority:threadPriority * .5];
        
        if (_interpolationMode == CPRInterpolationModeLinear) {
            [self _linearInterpolatingFill];
        } else if (_interpolationMode == CPRInterpolationModeNearestNeighbor) {
            [self _nearestNeighborFill];
        } else if (_interpolationMode == CPRInterpolationModeCubic) {
            [self _cubicInterpolatingFill];
        } else {
            [self _unknownInterpolatingFill];
        }
        
        [NSThread setThreadPriority:threadPriority];
    }
    @catch (...) {
    }
    @finally {
        [pool release];
    }
}

- (void)_linearInterpolatingFill
{
    NSUInteger x;
    NSUInteger y;
    N3AffineTransform vectorTransform;
    N3VectorArray volumeVectors;
    N3VectorArray volumeNormals;
    CPRVolumeDataInlineBuffer inlineBuffer;
    
    volumeVectors = malloc(_width * sizeof(N3Vector));
    memcpy(volumeVectors, _vectors, _width * sizeof(N3Vector));
    N3VectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);
    
    volumeNormals = malloc(_width * sizeof(N3Vector));
    memcpy(volumeNormals, _normals, _width * sizeof(N3Vector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    N3VectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);
    
    if ([_volumeData aquireInlineBuffer:&inlineBuffer]) {
		for (y = 0; y < _height; y++) {
			if ([self isCancelled]) {
				break;
			}
			
			for (x = 0; x < _width; x++) {
				_floatBytes[y*_width + x] = CPRVolumeDataLinearInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
			}
			
			N3VectorAddVectors(volumeVectors, volumeNormals, _width);
		}
	} else {
        memset(_floatBytes, 0, _height * _width * sizeof(float));
    }

    [_volumeData releaseInlineBuffer:&inlineBuffer];
    
    free(volumeVectors);
    free(volumeNormals);
}

- (void)_nearestNeighborFill
{
    NSUInteger x;
    NSUInteger y;
    N3AffineTransform vectorTransform;
    N3VectorArray volumeVectors;
    N3VectorArray volumeNormals;
    CPRVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(N3Vector));
    memcpy(volumeVectors, _vectors, _width * sizeof(N3Vector));
    N3VectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(N3Vector));
    memcpy(volumeNormals, _normals, _width * sizeof(N3Vector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    N3VectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    if ([_volumeData aquireInlineBuffer:&inlineBuffer]) {
		for (y = 0; y < _height; y++) {
			if ([self isCancelled]) {
				break;
			}
			
			for (x = 0; x < _width; x++) {
				_floatBytes[y*_width + x] = CPRVolumeDataNearestNeighborInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
			}
			
			N3VectorAddVectors(volumeVectors, volumeNormals, _width);
		}
	} else {
        memset(_floatBytes, 0, _height * _width * sizeof(float));
    }
    
    [_volumeData releaseInlineBuffer:&inlineBuffer];
    
    free(volumeVectors);
    free(volumeNormals);
}

- (void)_cubicInterpolatingFill
{
    NSUInteger x;
    NSUInteger y;
    N3AffineTransform vectorTransform;
    N3VectorArray volumeVectors;
    N3VectorArray volumeNormals;
    CPRVolumeDataInlineBuffer inlineBuffer;

    volumeVectors = malloc(_width * sizeof(N3Vector));
    memcpy(volumeVectors, _vectors, _width * sizeof(N3Vector));
    N3VectorApplyTransformToVectors(_volumeData.volumeTransform, volumeVectors, _width);

    volumeNormals = malloc(_width * sizeof(N3Vector));
    memcpy(volumeNormals, _normals, _width * sizeof(N3Vector));
    vectorTransform = _volumeData.volumeTransform;
    vectorTransform.m41 = vectorTransform.m42 = vectorTransform.m43 = 0.0;
    N3VectorApplyTransformToVectors(vectorTransform, volumeNormals, _width);

    if ([_volumeData aquireInlineBuffer:&inlineBuffer]) {
		for (y = 0; y < _height; y++) {
			if ([self isCancelled]) {
				break;
			}

			for (x = 0; x < _width; x++) {
				_floatBytes[y*_width + x] = CPRVolumeDataCubicInterpolatedFloatAtVolumeVector(&inlineBuffer, volumeVectors[x]);
			}

			N3VectorAddVectors(volumeVectors, volumeNormals, _width);
		}
	} else {
        memset(_floatBytes, 0, _height * _width * sizeof(float));
    }

    [_volumeData releaseInlineBuffer:&inlineBuffer];

    free(volumeVectors);
    free(volumeNormals);
}


- (void)_unknownInterpolatingFill
{
    NSLog(@"unknown interpolation mode");
    memset(_floatBytes, 0, _height * _width);
}


@end
