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

#import "CPRVolumeData.h"
#import "DCMPix.h"
#import "CPRUnsignedInt16ImageRep.h"
#include <libkern/OSAtomic.h>

@interface CPRVolumeData ()

- (BOOL)_testOrientationMatrix:(double[9])orientation; // returns YES if the orientation matrix's determinant is non-zero

@end


@implementation CPRVolumeData

@synthesize outOfBoundsValue = _outOfBoundsValue;
@synthesize pixelsWide = _pixelsWide;
@synthesize pixelsHigh = _pixelsHigh;
@synthesize pixelsDeep = _pixelsDeep;
@synthesize volumeTransform = _volumeTransform;

- (id)initWithFloatBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
               volumeTransform:(N3AffineTransform)volumeTransform outOfBoundsValue:(float)outOfBoundsValue freeWhenDone:(BOOL)freeWhenDone; // volumeTransform is the transform from Dicom (patient) space to pixel data
{
    if ( (self = [super init]) ) {
        if (floatBytes == NULL) {
            _floatBytes = malloc(sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep);
        } else {
            _floatBytes = floatBytes;
        }
        _outOfBoundsValue = outOfBoundsValue;
        _isValid = YES;
        _pixelsWide = pixelsWide;
        _pixelsHigh = pixelsHigh;
        _pixelsDeep = pixelsDeep;
        _volumeTransform = volumeTransform;
        _freeWhenDone = freeWhenDone;
        _childSubvolumes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    CPRVolumeData *childVolume;
    
    if (_freeWhenDone) {
        for (childVolume in [_childSubvolumes allValues]) {
            [childVolume invalidateData];
        }
        
        free((void *)_floatBytes);
        _floatBytes = NULL;
    }
    
    [_childSubvolumes release];
    _childSubvolumes = nil;
    [super dealloc];
}

- (BOOL)isRectilinear
{
    return N3AffineTransformIsRectilinear(_volumeTransform);
}

- (CGFloat)minPixelSpacing
{
    return MIN(MIN(self.pixelSpacingX, self.pixelSpacingY), self.pixelSpacingZ);
}

- (CGFloat)pixelSpacingX
{
    N3Vector zero;
    N3AffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_volumeTransform.m11;
    } else {
        inverseTransform = N3AffineTransformInvert(_volumeTransform);
        zero = N3VectorApplyTransform(N3VectorZero, inverseTransform);
        return N3VectorDistance(zero, N3VectorApplyTransform(N3VectorMake(1.0, 0.0, 0.0), inverseTransform));
    }
}

- (CGFloat)pixelSpacingY
{
    N3Vector zero;
    N3AffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_volumeTransform.m22;
    } else {
        inverseTransform = N3AffineTransformInvert(_volumeTransform);
        zero = N3VectorApplyTransform(N3VectorZero, inverseTransform);
        return N3VectorDistance(zero, N3VectorApplyTransform(N3VectorMake(0.0, 1.0, 0.0), inverseTransform));
    }
}

- (CGFloat)pixelSpacingZ
{
    N3Vector zero;
    N3AffineTransform inverseTransform;

    if (self.rectilinear) {
        return 1.0/_volumeTransform.m33;
    } else {
        inverseTransform = N3AffineTransformInvert(_volumeTransform);
        zero = N3VectorApplyTransform(N3VectorZero, inverseTransform);
        return N3VectorDistance(zero, N3VectorApplyTransform(N3VectorMake(0.0, 0.0, 1.0), inverseTransform));
    }
}

- (BOOL)isDataValid
{
    return _isValid;
}

- (void)invalidateData; // this is to be called right before freeing the data by objects who own the floatBytes that were given to the receiver
{                       // this may lock temporarily if other threads are accessing the data, after this returns, it is ok to free floatBytes and all calls to access data will fail gracefully
    struct timespec rqtp = {0, 100};
    struct timespec rmtp = {0, 0};
    CPRVolumeData *childVolume;
    
    assert(_freeWhenDone == NO); // you can't invalidate the data if it is owned by the CPRVolumeData 
        
    _isValid = NO;
    OSMemoryBarrier(); // make sure that the _isValid was set
    while (_readerCount > 0) { // spin until we no know that any readers that were reading before the _isValid was set would have exited
        nanosleep(&rqtp, &rmtp);
    }
    
    @synchronized(_childSubvolumes) {
        for (childVolume in [_childSubvolumes allValues]) {
            [childVolume invalidateData];
        }
    }    
    
    // now we know that everything is ok and it is safe to return and have the caller free the data;
    _floatBytes = NULL;
    return;
}

// will copy fill length*sizeof(float) bytes
- (BOOL)getFloatRun:(float *)buffer atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z length:(NSUInteger)length
{
    if (_isValid == NO) {
        memset(buffer, 0, sizeof(float) * length);
        return NO;
    }
    
    assert(x < _pixelsWide);
    assert(y < _pixelsHigh);
    assert(z < _pixelsDeep);
    assert(x + length < _pixelsWide);
    
    OSAtomicIncrement32Barrier(&_readerCount);
    if (_isValid) {
        memcpy(buffer, &(_floatBytes[x + y*_pixelsWide + z*_pixelsWide*_pixelsHigh]), length * sizeof(float));
        OSAtomicDecrement32Barrier(&_readerCount);
        return YES;
    } else {
        OSAtomicDecrement32Barrier(&_readerCount);
        memset(buffer, 0, sizeof(float) * length);
        return NO;
    }
}

- (CPRUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z
{
    CPRUnsignedInt16ImageRep *imageRep;
    uint16_t *unsignedInt16Data;
    vImage_Buffer floatBuffer;
    vImage_Buffer unsignedInt16Buffer;
    
    if (_isValid == NO) {
        return nil;
    }    
    
    OSAtomicIncrement32Barrier(&_readerCount);
    if (_isValid) {
        imageRep = [[CPRUnsignedInt16ImageRep alloc] initWithData:NULL pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh];
        imageRep.pixelSpacingX = [self pixelSpacingX];
        imageRep.pixelSpacingY = [self pixelSpacingY];
        imageRep.sliceThickness = [self pixelSpacingZ];
        imageRep.imageToDicomTransform = N3AffineTransformConcat(N3AffineTransformMakeTranslation(0.0, 0.0, (CGFloat)z), N3AffineTransformInvert(_volumeTransform));
        
        unsignedInt16Data = [imageRep unsignedInt16Data];
        
        floatBuffer.data = (void *)_floatBytes + (_pixelsWide * _pixelsHigh * sizeof(float) * z);
        floatBuffer.height = _pixelsHigh;
        floatBuffer.width = _pixelsWide;
        floatBuffer.rowBytes = sizeof(float) * _pixelsWide;
        
        unsignedInt16Buffer.data = unsignedInt16Data;
        unsignedInt16Buffer.height = _pixelsHigh;
        unsignedInt16Buffer.width = _pixelsWide;
        unsignedInt16Buffer.rowBytes = sizeof(uint16_t) * _pixelsWide;
        
        vImageConvert_FTo16U(&floatBuffer, &unsignedInt16Buffer, -1024, 1, 0);
        imageRep.slope = 1;
        imageRep.offset = -1024;
        
        OSAtomicDecrement32Barrier(&_readerCount);
        return [imageRep autorelease];
    } else {
        OSAtomicDecrement32Barrier(&_readerCount);
        return nil;
    }    
}

- (CPRVolumeData *)volumeDataForSliceAtIndex:(NSUInteger)z
{
    CPRVolumeData *childVolume;
    CPRVolumeData *existingVolume;
    N3AffineTransform childVolumeTransform;
    
    childVolumeTransform = N3AffineTransformConcat(_volumeTransform, N3AffineTransformMakeTranslation(0, 0, -z));
    childVolume = [[CPRVolumeData alloc] initWithFloatBytesNoCopy:_floatBytes + (_pixelsWide*_pixelsHigh*z) pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh pixelsDeep:1
                                                  volumeTransform:childVolumeTransform outOfBoundsValue:_outOfBoundsValue freeWhenDone:NO];
    
    OSAtomicIncrement32Barrier(&_readerCount);
    if ([self isDataValid] == NO) {
        [childVolume invalidateData];
    }
    @synchronized(_childSubvolumes) {
        existingVolume = [_childSubvolumes objectForKey:[NSNumber numberWithInteger:z]];
        if (existingVolume) {
            [childVolume release];
            childVolume = [existingVolume retain];
        } else {
            [_childSubvolumes setObject:childVolume forKey:[NSNumber numberWithInteger:z]];
        }
    }
    OSAtomicDecrement32Barrier(&_readerCount);
    
    return [childVolume autorelease];
}

- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z
{
    CPRVolumeDataInlineBuffer inlineBuffer;
    
    if (_isValid == NO) {
        return NO;
    }    
    
    if ([self aquireInlineBuffer:&inlineBuffer]) {
        *floatPtr = CPRVolumeDataGetFloatAtPixelCoordinate(&inlineBuffer, x, y, z);
        [self releaseInlineBuffer:&inlineBuffer];
        return YES;
    } else {
        [self releaseInlineBuffer:&inlineBuffer];
        *floatPtr = 0.0;
        return NO;
    }
}

- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector
{
    CPRVolumeDataInlineBuffer inlineBuffer;

    if (_isValid == NO) {
        return NO;
    }    
    
    if ([self aquireInlineBuffer:&inlineBuffer]) {
        *floatPtr = CPRVolumeDataLinearInterpolatedFloatAtDicomVector(&inlineBuffer, vector);
        [self releaseInlineBuffer:&inlineBuffer];
        return YES;
    } else {
        [self releaseInlineBuffer:&inlineBuffer];
        *floatPtr = 0.0;
        return NO;
    }        
}

- (BOOL)getNearestNeighborInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector
{
    CPRVolumeDataInlineBuffer inlineBuffer;
    
    if (_isValid == NO) {
        return NO;
    }
    
    if ([self aquireInlineBuffer:&inlineBuffer]) {
        *floatPtr = CPRVolumeDataNearestNeighborInterpolatedFloatAtDicomVector(&inlineBuffer, vector);
        [self releaseInlineBuffer:&inlineBuffer];
        return YES;
    } else {
        [self releaseInlineBuffer:&inlineBuffer];
        *floatPtr = 0.0;
        return NO;
    }
}

- (BOOL)getCubicInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector
{
    CPRVolumeDataInlineBuffer inlineBuffer;

    if (_isValid == NO) {
        return NO;
    }

    if ([self aquireInlineBuffer:&inlineBuffer]) {
        *floatPtr = CPRVolumeDataCubicInterpolatedFloatAtDicomVector(&inlineBuffer, vector);
        [self releaseInlineBuffer:&inlineBuffer];
        return YES;
    } else {
        [self releaseInlineBuffer:&inlineBuffer];
        *floatPtr = 0.0;
        return NO;
    }
}


- (NSUInteger)tempBufferSizeForNumVectors:(NSUInteger)numVectors
{
    return numVectors * sizeof(float) * 11;
}

// not done yet, will crash if given vectors that are outside of the volume
- (void)linearInterpolateVolumeVectors:(N3VectorArray)volumeVectors outputValues:(float *)outputValues numVectors:(NSUInteger)numVectors tempBuffer:(void *)tempBuffer
{
    float *interpolateBuffer = (float *)tempBuffer;
    
    float *scrap;
    
    float *yFloors;
    float *zFloors;
    float *yFrac;
    float *zFrac;
    float *yNegFrac;
    float *zNegFrac;
    float negOne;
    
    float *i1Positions;
    float *i2Positions;
    float *j1Positions;
    float *j2Positions;
    
    float *yFloorPosition;
    float *yCielPosition;
    float *zFloorPosition;
    float *zCielPosition;

    float width;
    float widthTimesHeight;
    float widthTimesHeightTimeDepth;
    
    float *i1;
    float *i2;
    float *j1;
    float *j2;
    
    float *w1;
    float *w2;

    negOne = -1.0;
    width = _pixelsWide;
    widthTimesHeight = _pixelsWide*_pixelsHigh;
    widthTimesHeightTimeDepth = widthTimesHeight*_pixelsDeep;
    
    yFrac = interpolateBuffer + (numVectors * 0);
    zFrac = interpolateBuffer + (numVectors * 1);
    yFloors = interpolateBuffer + (numVectors * 2);
    zFloors = interpolateBuffer + (numVectors * 3);
    
    vDSP_vfrac(((float *)volumeVectors) + 1, 3, yFrac, 1, numVectors);
    vDSP_vsub(yFrac, 1, ((float *)volumeVectors) + 1, 3, yFloors, 1, numVectors);

    vDSP_vfrac(((float *)volumeVectors) + 2, 3, zFrac, 1, numVectors);
    vDSP_vsub(zFrac, 1, ((float *)volumeVectors) + 2, 3, zFloors, 1, numVectors);
    
    yFloorPosition = interpolateBuffer + (numVectors * 6);
    yCielPosition = interpolateBuffer + (numVectors * 7);
    zFloorPosition = interpolateBuffer + (numVectors * 8);
    zCielPosition = interpolateBuffer + (numVectors * 9);
        
    vDSP_vsmul(yFloors, 1, &width, yFloorPosition, 1, numVectors);
    vDSP_vsadd(yFloorPosition, 1, &width, yCielPosition, 1, numVectors);
    vDSP_vsmul(zFloors, 1, &widthTimesHeight, zFloorPosition, 1, numVectors);
    vDSP_vsadd(zFloorPosition, 1, &widthTimesHeight, zCielPosition, 1, numVectors);
    
    i1Positions = interpolateBuffer + (numVectors * 2);
    i2Positions = interpolateBuffer + (numVectors * 3);
    j1Positions = interpolateBuffer + (numVectors * 4);
    j2Positions = interpolateBuffer + (numVectors * 5);
    
    // i1 yFloor zFloor
    // i2 yFloor zCiel
    // j1 yCiel zFloor
    // j2 yCiel zCiel
    
    vDSP_vadd((float *)volumeVectors, 3, yFloorPosition, 1, i1Positions, 1, numVectors);
    
    vDSP_vadd(i1Positions, 1, zCielPosition, 1, i2Positions, 1, numVectors);
    vDSP_vadd(i1Positions, 1, zFloorPosition, 1, i1Positions, 1, numVectors);
    
    vDSP_vadd((float *)volumeVectors, 3, yCielPosition, 1, j1Positions, 1, numVectors);
    
    vDSP_vadd(j1Positions, 1, zCielPosition, 1, j2Positions, 1, numVectors);
    vDSP_vadd(j1Positions, 1, zFloorPosition, 1, j1Positions, 1, numVectors);
    
    
    i1 = interpolateBuffer + (numVectors * 6);
    i2 = interpolateBuffer + (numVectors * 7);
    j1 = interpolateBuffer + (numVectors * 8);
    j2 = interpolateBuffer + (numVectors * 9);
    
    vDSP_vlint((float *)_floatBytes, i1Positions, 1, i1, 1, numVectors * 4, widthTimesHeightTimeDepth);
                
    yNegFrac = interpolateBuffer + (numVectors * 2);
    zNegFrac = interpolateBuffer + (numVectors * 3);
    
    vDSP_vsadd(yFrac, 1, &negOne, yNegFrac, 1, numVectors);
    vDSP_vneg(yNegFrac, 1, yNegFrac, 1, numVectors);
    
    vDSP_vsadd(zFrac, 1, &negOne, zNegFrac, 1, numVectors);
    vDSP_vneg(zNegFrac, 1, zNegFrac, 1, numVectors);
        
    w1 = interpolateBuffer + (numVectors * 4);
    w2 = interpolateBuffer + (numVectors * 5);
    
    scrap = interpolateBuffer + (numVectors * 10);
    
    vDSP_vmul(i1, 1, zNegFrac, 1, w1, 1, numVectors);
    vDSP_vmul(i2, 1, zFrac, 1, scrap, 1, numVectors);
    vDSP_vadd(w1, 1, scrap, 1, w1, 1, numVectors);
    
    vDSP_vmul(j1, 1, zNegFrac, 1, w2, 1, numVectors);
    vDSP_vmul(j2, 1, zFrac, 1, scrap, 1, numVectors);
    vDSP_vadd(w2, 1, scrap, 1, w2, 1, numVectors);
    
    
    vDSP_vmul(w1, 1, yNegFrac, 1, outputValues, 1, numVectors);
    vDSP_vmul(w2, 1, yFrac, 1, scrap, 1, numVectors);
    vDSP_vadd(outputValues, 1, scrap, 1, outputValues, 1, numVectors);
}

        

- (BOOL)aquireInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer
{
    memset(inlineBuffer, 0, sizeof(CPRVolumeDataInlineBuffer));
    
    if (_isValid == NO) {
        return NO;
    }
    
    OSAtomicIncrement32Barrier(&_readerCount);
    if (_isValid) {
        inlineBuffer->floatBytes = _floatBytes;
        inlineBuffer->outOfBoundsValue = _outOfBoundsValue;
        inlineBuffer->pixelsWide = _pixelsWide;
        inlineBuffer->pixelsHigh = _pixelsHigh;
        inlineBuffer->pixelsDeep = _pixelsDeep;
        inlineBuffer->pixelsWideTimesPixelsHigh = _pixelsWide*_pixelsHigh;
        inlineBuffer->volumeTransform = _volumeTransform;
        return YES;
    } else {
        OSAtomicDecrement32Barrier(&_readerCount);
        return NO;
    }
}

- (void)releaseInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer
{
    if (inlineBuffer->floatBytes != NULL) {
        OSAtomicDecrement32Barrier(&_readerCount);
    }
    memset(inlineBuffer, 0, sizeof(CPRVolumeDataInlineBuffer));
}

- (BOOL)_testOrientationMatrix:(double[9])orientation // returns YES if the orientation matrix's determinant is non-zero
{
    N3AffineTransform transform;
    
    transform = N3AffineTransformIdentity;
    transform.m11 = orientation[0];
    transform.m12 = orientation[1];
    transform.m13 = orientation[2];
    transform.m21 = orientation[3];
    transform.m22 = orientation[4];
    transform.m23 = orientation[5];
    transform.m31 = orientation[6];
    transform.m32 = orientation[7];
    transform.m33 = orientation[8];
    
    return N3AffineTransformDeterminant(transform) != 0.0;
}

@end

@implementation CPRVolumeData (DCMPixAndVolume)

- (id)initWithWithPixList:(NSArray *)pixList volume:(NSData *)volume
{
    DCMPix *firstPix;
    float sliceThickness;
    N3AffineTransform pixToDicomTransform;
    double spacingX;
    double spacingY;
    double spacingZ;
    double orientation[9];
	
    firstPix = [pixList objectAtIndex:0];
    
    sliceThickness = [firstPix sliceInterval];
	if(sliceThickness == 0)
	{
		NSLog(@"slice interval = slice thickness!");
		sliceThickness = [firstPix sliceThickness];
	}
        
    memset(orientation, 0, sizeof(double) * 9);
    [firstPix orientationDouble:orientation];
    spacingX = firstPix.pixelSpacingX;
    spacingY = firstPix.pixelSpacingY;
    if(sliceThickness == 0) { // if the slice thickness is still 0, make it the same as the average of the spacingX and spacingY
        sliceThickness = (spacingX + spacingY)/2.0;
    }
    spacingZ = sliceThickness;
    
    // test to make sure that orientation is initialized, when the volume is curved or something, it doesn't make sense to talk about orientation, and
    // so the orientation is really bogus
    // the test we will do is to make sure that orientation is 3 non-degenerate vectors
    if ([self _testOrientationMatrix:orientation] == NO) {
        memset(orientation, 0, sizeof(double)*9);
        orientation[0] = orientation[4] = orientation[8] = 1;
    }
    
    pixToDicomTransform = N3AffineTransformIdentity;
    pixToDicomTransform.m41 = firstPix.originX;
    pixToDicomTransform.m42 = firstPix.originY;
    pixToDicomTransform.m43 = firstPix.originZ;
    pixToDicomTransform.m11 = orientation[0]*spacingX;
    pixToDicomTransform.m12 = orientation[1]*spacingX;
    pixToDicomTransform.m13 = orientation[2]*spacingX;
    pixToDicomTransform.m21 = orientation[3]*spacingY;
    pixToDicomTransform.m22 = orientation[4]*spacingY;
    pixToDicomTransform.m23 = orientation[5]*spacingY;
    pixToDicomTransform.m31 = orientation[6]*spacingZ;
    pixToDicomTransform.m32 = orientation[7]*spacingZ;
    pixToDicomTransform.m33 = orientation[8]*spacingZ;
    
    self = [self initWithFloatBytesNoCopy:(const float *)[volume bytes] pixelsWide:[firstPix pwidth] pixelsHigh:[firstPix pheight] pixelsDeep:[pixList count]
                          volumeTransform:N3AffineTransformInvert(pixToDicomTransform) outOfBoundsValue:-1000 freeWhenDone:NO];
    return self;
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
    N3AffineTransform pixelToDicomTransform;
    N3Vector xBasis;
    N3Vector yBasis;
    
    pixelToDicomTransform = N3AffineTransformInvert(_volumeTransform);
    
    xBasis = N3VectorNormalize(N3VectorMake(pixelToDicomTransform.m11, pixelToDicomTransform.m12, pixelToDicomTransform.m13));
    yBasis = N3VectorNormalize(N3VectorMake(pixelToDicomTransform.m21, pixelToDicomTransform.m22, pixelToDicomTransform.m23));
    
    orientation[0] = xBasis.x; orientation[1] = xBasis.y; orientation[2] = xBasis.z;
    orientation[3] = yBasis.x; orientation[4] = yBasis.y; orientation[5] = yBasis.z; 
}

- (float)originX
{
    N3AffineTransform pixelToDicomTransform;
    
    pixelToDicomTransform = N3AffineTransformInvert(_volumeTransform);
    
    return pixelToDicomTransform.m41;
}

- (float)originY
{
    N3AffineTransform pixelToDicomTransform;
    
    pixelToDicomTransform = N3AffineTransformInvert(_volumeTransform);
    
    return pixelToDicomTransform.m42;
}

- (float)originZ
{
    N3AffineTransform pixelToDicomTransform;
    
    pixelToDicomTransform = N3AffineTransformInvert(_volumeTransform);
    
    return pixelToDicomTransform.m43;
}


@end














