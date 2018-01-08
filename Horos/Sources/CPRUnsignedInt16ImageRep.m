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


