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

#import "CPRVolumeData.h"
#import "DCMPix.h"
#import "CPRUnsignedInt16ImageRep.h"
#include <libkern/OSAtomic.h>

@interface CPRVolumeData ()


@end


@implementation CPRVolumeData

@synthesize pixelsWide = _pixelsWide;
@synthesize pixelsHigh = _pixelsHigh;
@synthesize pixelsDeep = _pixelsDeep;
@synthesize volumeTransform = _volumeTransform;

- (id)initWithFloatBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
               volumeTransform:(N3AffineTransform)volumeTransform freeWhenDone:(BOOL)freeWhenDone; // volumeTransform is the transform from Dicom (patient) space to pixel data
{
    if ( (self = [super init]) ) {
        if (floatBytes == NULL) {
            _floatBytes = malloc(sizeof(float) * pixelsWide * pixelsHigh * pixelsDeep);
        } else {
            _floatBytes = floatBytes;
        }
        _isValid = YES;
        _pixelsWide = pixelsWide;
        _pixelsHigh = pixelsHigh;
        _pixelsDeep = pixelsDeep;
        _volumeTransform = volumeTransform;
        _freeWhenDone = freeWhenDone;
    }
    return self;
}

- (void)dealloc
{
    if (_freeWhenDone) {
        free((void *)_floatBytes);
        _floatBytes = NULL;
    }
    
    [super dealloc];
}

- (BOOL)isRectilinear
{
    return N3AffineTransformIsRectilinear(_volumeTransform);
}

- (CGFloat)minPixelSpacing
{
    N3Vector zero;
    CGFloat spacing;
    
    if (self.rectilinear) {
        return MIN(MIN(self.pixelSpacingX, self.pixelSpacingY), self.pixelSpacingZ);
    } else {
        zero = N3VectorApplyTransform(N3VectorZero, _volumeTransform);
        
        spacing = N3VectorDistance(zero, N3VectorApplyTransform(N3VectorMake(1.0, 0.0, 0.0), _volumeTransform));
        spacing = MAX(spacing, N3VectorDistance(zero, N3VectorApplyTransform(N3VectorMake(0.0, 1.0, 0.0), _volumeTransform)));
        spacing = MAX(spacing, N3VectorDistance(zero, N3VectorApplyTransform(N3VectorMake(0.0, 0.0, 1.0), _volumeTransform)));
        return 1.0/spacing;
    }
}

- (CGFloat)pixelSpacingX
{
    if (self.rectilinear) {
        return 1.0/_volumeTransform.m11;
    } else {
        return 0.0;
    }
}

- (CGFloat)pixelSpacingY
{
    if (self.rectilinear) {
        return 1.0/_volumeTransform.m22;
    } else {
        return 0.0;
    }
}

- (CGFloat)pixelSpacingZ
{
    if (self.rectilinear) {
        return 1.0/_volumeTransform.m33;
    } else {
        return 0.0;
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
    
    assert(_freeWhenDone == NO); // you can't invalidate the data if it is owned by the CPRVolumeData 
    
    _isValid = NO;
    OSMemoryBarrier(); // make sure that the _isValid was set
    while (_readerCount > 0) { // spin until we no know that any readers that were reading before the _isValid was set would have exited
        nanosleep(&rqtp, &rmtp);
    }
    
    // now we know that everything is ok and it is safe to return and have the caller free the data;
    _floatBytes = NULL;
    return;
}

- (BOOL)getFloatData:(void *)buffer range:(NSRange)range
{
    OSAtomicIncrement32Barrier(&_readerCount);
    if (_isValid) {
        memcpy(buffer, _floatBytes + range.location, range.length * sizeof(float));
        OSAtomicDecrement32(&_readerCount);
        return YES;
    } else {
        OSAtomicDecrement32(&_readerCount);
        return NO;
    }
}

- (CPRUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z
{
    CPRUnsignedInt16ImageRep *imageRep;
    uint16_t *unsignedInt16Data;
    vImage_Buffer floatBuffer;
    vImage_Buffer unsignedInt16Buffer;
    
    OSAtomicIncrement32Barrier(&_readerCount);
    if (_isValid) {
        imageRep = [[CPRUnsignedInt16ImageRep alloc] initWithData:NULL pixelsWide:_pixelsWide pixelsHigh:_pixelsHigh];
        imageRep.pixelSpacingX = [self pixelSpacingX];
        imageRep.pixelSpacingY = [self pixelSpacingY];
        imageRep.sliceThickness = [self pixelSpacingZ];
        
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
        
        OSAtomicDecrement32(&_readerCount);
        return [imageRep autorelease];
    } else {
        OSAtomicDecrement32(&_readerCount);
        return nil;
    }    
}

- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z
{
    CPRVolumeDataInlineBuffer inlineBuffer;
    
    if ([self aquireInlineBuffer:&inlineBuffer]) {
        *floatPtr = CPRVolumeDataGetFloatAtPixelCoordinate(&inlineBuffer, x, y, z);
        [self releaseInlineBuffer:&inlineBuffer];
        return YES;
    } else {
        [self releaseInlineBuffer:&inlineBuffer];
        return NO;
    }
}

- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector
{
    CPRVolumeDataInlineBuffer inlineBuffer;

    if ([self aquireInlineBuffer:&inlineBuffer]) {
        *floatPtr = CPRVolumeDataLinearInterpolatedFloatAtDicomVector(&inlineBuffer, vector);
        [self releaseInlineBuffer:&inlineBuffer];
        return YES;
    } else {
        [self releaseInlineBuffer:&inlineBuffer];
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
    
    float *xPositionClipped;
    
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
    
    OSAtomicIncrement32Barrier(&_readerCount);
    if (_isValid) {
        inlineBuffer->floatBytes = _floatBytes;
        inlineBuffer->pixelsWide = _pixelsWide;
        inlineBuffer->pixelsHigh = _pixelsHigh;
        inlineBuffer->pixelsDeep = _pixelsDeep;
        inlineBuffer->pixelsWideTimesPixelsHigh = _pixelsWide*_pixelsHigh;
        inlineBuffer->volumeTransform = _volumeTransform;
        return YES;
    } else {
        return NO;
    }
}

- (void)releaseInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer
{
    OSAtomicDecrement32(&_readerCount);
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
	if( sliceThickness == 0)
	{
		NSLog(@"slice interval = slice thickness!");
		sliceThickness = [firstPix sliceThickness];
	}
    
    memset(orientation, 0, sizeof(double) * 9);
    [firstPix orientationDouble:orientation];
    spacingX = firstPix.pixelSpacingX;
    spacingY = firstPix.pixelSpacingY;
    spacingZ = sliceThickness;
    
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
                            volumeTransform:N3AffineTransformInvert(pixToDicomTransform) freeWhenDone:NO];
    return self;
}

@end














