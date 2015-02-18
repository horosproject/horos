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

#import "CPRUnsignedInt16ImageRep.h"


@implementation CPRUnsignedInt16ImageRep

@synthesize windowWidth = _windowWidth;
@synthesize windowLevel = _windowLevel;

@synthesize offset = _offset;
@synthesize slope = _slope;
@synthesize pixelSpacingX = _pixelSpacingX;
@synthesize pixelSpacingY = _pixelSpacingY;
@synthesize sliceThickness = _sliceThickness;
@synthesize imageToDicomTransform = _imageToDicomTransform;

- (id)initWithData:(uint16_t *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    if ( (self = [super init]) ) {
        if (data == NULL) {
            _unsignedInt16Data = malloc(sizeof(uint16_t) * pixelsWide * pixelsHigh);
            _freeWhenDone = YES;
            if (_unsignedInt16Data == NULL) {
                [self autorelease];
                return nil;
            }
        } else {
            _unsignedInt16Data = data;
        }
        
        [self setPixelsWide:pixelsWide];
        [self setPixelsHigh:pixelsHigh];
        [self setSize:NSMakeSize(pixelsWide, pixelsHigh)];
        _offset = 0;
        _slope = 1;
        _imageToDicomTransform = N3AffineTransformIdentity;
    }
    
    return self;
}

- (void)dealloc
{
    if (_freeWhenDone) {
        free(_unsignedInt16Data);
    }
    
    [super dealloc];
}

-(BOOL)draw
{
    assert(false); // one day it would be cool if this could actually be used as an image rep in an NSImage
    return NO;
}

- (uint16_t *)unsignedInt16Data
{
    return _unsignedInt16Data;
}

@end


@implementation CPRUnsignedInt16ImageRep (DCMPixAndVolume)

- (void)getOrientation:(float[6])orientation
{
    double doubleOrientation[6];
    NSInteger i;
    
    [self getOrientationDouble:doubleOrientation];
    
    for (i = 0; i < 6; i++) {
        orientation[i] = doubleOrientation[i];
    }
}

- (void)getOrientationDouble:(double[6])orientation
{
    N3Vector xBasis;
    N3Vector yBasis;
        
    xBasis = N3VectorNormalize(N3VectorMake(_imageToDicomTransform.m11, _imageToDicomTransform.m12, _imageToDicomTransform.m13));
    yBasis = N3VectorNormalize(N3VectorMake(_imageToDicomTransform.m21, _imageToDicomTransform.m22, _imageToDicomTransform.m23));
    
    orientation[0] = xBasis.x; orientation[1] = xBasis.y; orientation[2] = xBasis.z;
    orientation[3] = yBasis.x; orientation[4] = yBasis.y; orientation[5] = yBasis.z; 
}

- (float)originX
{
    return _imageToDicomTransform.m41;
}

- (float)originY
{    
    return _imageToDicomTransform.m42;
}

- (float)originZ
{
    return _imageToDicomTransform.m43;
}

@end


