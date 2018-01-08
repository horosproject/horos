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

#import "CPRGeneratorRequest.h"
#import "N3BezierPath.h"
#import "CPRStraightenedOperation.h"
#import "CPRStretchedOperation.h"
#import "CPRObliqueSliceOperation.h"

@implementation CPRGeneratorRequest

@synthesize pixelsWide = _pixelsWide;
@synthesize pixelsHigh = _pixelsHigh;
@synthesize slabWidth = _slabWidth;
@synthesize slabSampleDistance = _slabSampleDistance;
@synthesize interpolationMode = _interpolationMode;
@synthesize context = _context;

- (id)init
{
    if ( (self = [super init]) ) {
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CPRGeneratorRequest *copy;
    
    copy = [[[self class] allocWithZone:zone] init];
    copy.pixelsWide = _pixelsWide;
    copy.pixelsHigh = _pixelsHigh;
    copy.slabWidth = _slabWidth;
    copy.slabSampleDistance = _slabSampleDistance;
    copy.interpolationMode = _interpolationMode;
    copy.context = _context;
    
    return copy;
}

- (BOOL)isEqual:(id)object
{
    CPRGeneratorRequest *generatorRequest;
    if ([object isKindOfClass:[CPRGeneratorRequest class]]) {
        generatorRequest = (CPRGeneratorRequest *)object;
        if (_pixelsWide == generatorRequest.pixelsWide &&
            _pixelsHigh == generatorRequest.pixelsHigh &&
            _slabWidth == generatorRequest.slabWidth &&
            _slabSampleDistance == generatorRequest.slabSampleDistance &&
            _interpolationMode == generatorRequest.interpolationMode &&
            _context == generatorRequest.context) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash
{
    return _pixelsWide ^ _pixelsHigh ^ *((NSUInteger *)&_slabWidth) ^ *((NSUInteger *)&_slabSampleDistance) ^ *((NSUInteger *)&_interpolationMode) ^ ((NSUInteger)_context);
}

- (Class)operationClass
{
    return nil;
}

@end

@implementation CPRStraightenedGeneratorRequest

@synthesize bezierPath = _bezierPath;
@synthesize initialNormal = _initialNormal;

@synthesize projectionMode = _projectionMode;
// @synthesize vertical = _vertical;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = CPRProjectionModeNone;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CPRStraightenedGeneratorRequest *copy;
    
    copy = [super copyWithZone:zone];
    copy.bezierPath = _bezierPath;
    copy.initialNormal = _initialNormal;
    copy.projectionMode = _projectionMode;
    //    copy.vertical = _vertical;
    return copy;
}

- (BOOL)isEqual:(id)object
{
    CPRStraightenedGeneratorRequest *straightenedGeneratorRequest;
    
    if ([object isKindOfClass:[CPRStraightenedGeneratorRequest class]]) {
        straightenedGeneratorRequest = (CPRStraightenedGeneratorRequest *)object;
        if ([super isEqual:object] &&
            [_bezierPath isEqualToBezierPath:straightenedGeneratorRequest.bezierPath] &&
            N3VectorEqualToVector(_initialNormal, straightenedGeneratorRequest.initialNormal) &&
            _projectionMode == straightenedGeneratorRequest.projectionMode /*&&*/ 
            /* _vertical == straightenedGeneratorRequest.vertical */) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash // a not that great hash function....
{
    return [super hash] ^ [_bezierPath hash] ^ (NSUInteger)N3VectorLength(_initialNormal) ^ (NSUInteger)_projectionMode /* ^ (NSUInteger)_vertical */;
}


- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [super dealloc];
}

- (Class)operationClass
{
    return [CPRStraightenedOperation class];
}

@end

@implementation CPRStretchedGeneratorRequest

@synthesize bezierPath = _bezierPath;
@synthesize projectionNormal = _projectionNormal;
@synthesize midHeightPoint = _midHeightPoint;

@synthesize projectionMode = _projectionMode;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = CPRProjectionModeNone;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CPRStretchedGeneratorRequest *copy;
    
    copy = [super copyWithZone:zone];
    copy.bezierPath = _bezierPath;
    copy.projectionNormal = _projectionNormal;
    copy.midHeightPoint = _midHeightPoint;
    copy.projectionMode = _projectionMode;
    //    copy.vertical = _vertical;
    return copy;
}

- (BOOL)isEqual:(id)object
{
    CPRStretchedGeneratorRequest *stretchedGeneratorRequest;
    
    if ([object isKindOfClass:[CPRStretchedGeneratorRequest class]]) {
        stretchedGeneratorRequest = (CPRStretchedGeneratorRequest *)object;
        if ([super isEqual:object] &&
            [_bezierPath isEqualToBezierPath:stretchedGeneratorRequest.bezierPath] &&
            N3VectorEqualToVector(_projectionNormal, stretchedGeneratorRequest.projectionNormal) &&
            N3VectorEqualToVector(_midHeightPoint, stretchedGeneratorRequest.midHeightPoint) &&
            _projectionMode == stretchedGeneratorRequest.projectionMode) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash // a not that great hash function....
{
    return [super hash] ^ [_bezierPath hash] ^ (NSUInteger)N3VectorLength(_projectionNormal) ^ (NSUInteger)N3VectorLength(_midHeightPoint) ^ (NSUInteger)_projectionMode;
}


- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [super dealloc];
}

- (Class)operationClass
{
    return [CPRStretchedOperation class];
}

@end


@implementation CPRObliqueSliceGeneratorRequest : CPRGeneratorRequest

@synthesize origin = _origin;
@synthesize directionX = _directionX;
@synthesize directionY = _directionY;
@synthesize pixelSpacingX = _pixelSpacingX;
@synthesize pixelSpacingY = _pixelSpacingY;
@synthesize projectionMode = _projectionMode;


+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"origin"] ||
        [key isEqualToString:@"directionX"] ||
        [key isEqualToString:@"directionY"] ||
        [key isEqualToString:@"pixelSpacingX"] ||
        [key isEqualToString:@"pixelSpacingY"]) {
        return [keyPaths setByAddingObjectsFromSet:[NSSet setWithObject:@"sliceToDicomTransform"]];
    } else if ([key isEqualToString:@"sliceToDicomTransform"]) {
        return [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:@"origin", @"directionX", @"directionY", @"pixelSpacingX", @"pixelSpacingY", nil]];
    } else {
        return keyPaths;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    CPRObliqueSliceGeneratorRequest *copy;
    
    copy = [super copyWithZone:zone];
    copy.origin = _origin;
    copy.directionX = _directionX;
    copy.directionY = _directionY;
    copy.pixelSpacingX = _pixelSpacingX;
    copy.pixelSpacingY = _pixelSpacingY;
    copy.projectionMode = _projectionMode;

    return copy;
}

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = CPRProjectionModeNone;
    }
    return self;
}

- (id)initWithCenter:(N3Vector)center pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh xBasis:(N3Vector)xBasis yBasis:(N3Vector)yBasis
{
    if ( (self = [super init]) ) {
        self.pixelsWide = pixelsWide;
        self.pixelsHigh = pixelsHigh;
        
        _directionX = N3VectorNormalize(xBasis);
        _pixelSpacingX = N3VectorLength(xBasis);

        _directionY = N3VectorNormalize(yBasis);
        _pixelSpacingY = N3VectorLength(yBasis);

        _origin = N3VectorAdd(N3VectorAdd(center, N3VectorScalarMultiply(xBasis, (CGFloat)pixelsWide/-2.0)), N3VectorScalarMultiply(yBasis, (CGFloat)pixelsHigh/-2.0));
        
        _projectionMode = CPRProjectionModeNone;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    CPRObliqueSliceGeneratorRequest *obliqueSliceGeneratorRequest;
    
    if ([object isKindOfClass:[CPRObliqueSliceGeneratorRequest class]]) {
        obliqueSliceGeneratorRequest = (CPRObliqueSliceGeneratorRequest *)object;
        if ([super isEqual:object] &&
            N3VectorEqualToVector(_origin, obliqueSliceGeneratorRequest.origin) &&
            N3VectorEqualToVector(_directionX, obliqueSliceGeneratorRequest.directionX) &&
            N3VectorEqualToVector(_directionY, obliqueSliceGeneratorRequest.directionY) &&
            _pixelSpacingX == obliqueSliceGeneratorRequest.pixelSpacingX &&
            _pixelSpacingY == obliqueSliceGeneratorRequest.pixelSpacingY &&
            _projectionMode == obliqueSliceGeneratorRequest.projectionMode) {
            return YES;
        }
    }
    return NO;
}

- (Class)operationClass
{
    return [CPRObliqueSliceOperation class];
}

- (void)setDirectionX:(N3Vector)direction
{
    _directionX = N3VectorNormalize(direction);
}

- (void)setDirectionY:(N3Vector)direction
{
    _directionY = N3VectorNormalize(direction);
}

- (void)setSliceToDicomTransform:(N3AffineTransform)sliceToDicomTransform
{
    _directionX = N3VectorMake(sliceToDicomTransform.m11, sliceToDicomTransform.m12, sliceToDicomTransform.m13);
    _pixelSpacingX = N3VectorLength(_directionX);
    _directionX = N3VectorNormalize(_directionX);
    
    _directionY = N3VectorMake(sliceToDicomTransform.m21, sliceToDicomTransform.m22, sliceToDicomTransform.m23);
    _pixelSpacingY = N3VectorLength(_directionY);
    _directionY = N3VectorNormalize(_directionY);
    
    _origin = N3VectorMake(sliceToDicomTransform.m41, sliceToDicomTransform.m42, sliceToDicomTransform.m43);
}

- (N3AffineTransform)sliceToDicomTransform
{
    N3AffineTransform sliceToDicomTransform;
    CGFloat pixelSpacingZ;
    N3Vector crossVector;

    sliceToDicomTransform = N3AffineTransformIdentity;
    crossVector = N3VectorNormalize(N3VectorCrossProduct(_directionX, _directionY));
    pixelSpacingZ = 1.0; // totally bogus, but there is no right value, and this should give something that is reasonable
    
    sliceToDicomTransform.m11 = _directionX.x * _pixelSpacingX;
    sliceToDicomTransform.m12 = _directionX.y * _pixelSpacingX;
    sliceToDicomTransform.m13 = _directionX.z * _pixelSpacingX;
    
    sliceToDicomTransform.m21 = _directionY.x * _pixelSpacingY;
    sliceToDicomTransform.m22 = _directionY.y * _pixelSpacingY;
    sliceToDicomTransform.m23 = _directionY.z * _pixelSpacingY;
    
    sliceToDicomTransform.m31 = crossVector.x * pixelSpacingZ;
    sliceToDicomTransform.m32 = crossVector.y * pixelSpacingZ;
    sliceToDicomTransform.m33 = crossVector.z * pixelSpacingZ;
    
    sliceToDicomTransform.m41 = _origin.x;
    sliceToDicomTransform.m42 = _origin.y;
    sliceToDicomTransform.m43 = _origin.z;
    
    return sliceToDicomTransform;
}


@end

@implementation CPRObliqueSliceGeneratorRequest (DCMPixAndVolume)

- (void)setOrientation:(float[6])orientation
{
    double doubleOrientation[6];
    NSInteger i;
    
    for (i = 0; i < 6; i++) {
        doubleOrientation[i] = orientation[i];
    }
    
    [self setOrientationDouble:doubleOrientation];
}

- (void)setOrientationDouble:(double[6])orientation
{
    _directionX = N3VectorNormalize(N3VectorMake(orientation[0], orientation[1], orientation[2]));
    _directionY = N3VectorNormalize(N3VectorMake(orientation[3], orientation[4], orientation[5]));
}

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
    orientation[0] = _directionX.x; orientation[1] = _directionX.y; orientation[2] = _directionX.z;
    orientation[3] = _directionY.x; orientation[4] = _directionY.y; orientation[5] = _directionY.z; 
}

- (void)setOriginX:(double)origin
{
    _origin.x = origin;
}

- (double)originX
{
    return _origin.x;
}

- (void)setOriginY:(double)origin
{
    _origin.y = origin;
}

- (double)originY
{
    return _origin.y;
}

- (void)setOriginZ:(double)origin
{
    _origin.z = origin;
}

- (double)originZ
{
    return _origin.z;
}

- (void)setSpacingX:(double)spacing
{
    _pixelSpacingX = spacing;
}

- (double)spacingX
{
    return _pixelSpacingX;
}

- (void)setSpacingY:(double)spacing
{
    _pixelSpacingY = spacing;
}

- (double)spacingY
{
    return _pixelSpacingY;
}


@end



