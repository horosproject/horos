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

#import <Cocoa/Cocoa.h>
#import "N3Geometry.h"

@class CPRUnsignedInt16ImageRep;

CF_EXTERN_C_BEGIN

typedef struct { // build one of these on the stack and then use -[CPRVolumeData aquireInlineBuffer:] to initialize it. Then make sure to release it too!
    const float *floatBytes;
    
    NSUInteger pixelsWide;
    NSUInteger pixelsHigh;
    NSUInteger pixelsDeep;
    
    NSUInteger pixelsWideTimesPixelsHigh; // just in the interest of not calculating this a million times...
    
    N3AffineTransform volumeTransform;
} CPRVolumeDataInlineBuffer;

// Interface to the data
@interface CPRVolumeData : NSObject {
    volatile int32_t _readerCount __attribute__ ((aligned (4)));
    volatile BOOL _isValid;

    const float *_floatBytes;
    
    NSUInteger _pixelsWide;
    NSUInteger _pixelsHigh;
    NSUInteger _pixelsDeep;
    
    N3AffineTransform _volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data
    
    BOOL _freeWhenDone;
    
    NSMutableDictionary *_childSubvolumes; // volumeData objects that point to the same underlying data
}


- (id)initWithFloatBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
               volumeTransform:(N3AffineTransform)volumeTransform freeWhenDone:(BOOL)freeWhenDone; // volumeTransform is the transform from Dicom (patient) space to pixel data

@property (readonly) NSUInteger pixelsWide;
@property (readonly) NSUInteger pixelsHigh;
@property (readonly) NSUInteger pixelsDeep;

@property (readonly, getter=isRectilinear) BOOL rectilinear;

@property (readonly) CGFloat minPixelSpacing; // the smallest pixel spacing in any direction;
@property (readonly) CGFloat pixelSpacingX;
@property (readonly) CGFloat pixelSpacingY;
@property (readonly) CGFloat pixelSpacingZ;

@property (readonly) N3AffineTransform volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data

- (BOOL)isDataValid;
- (void)invalidateData; // this is to be called right before freeing the data by objects who own the floatBytes that were given to the receiver
						// this may lock temporarily if other threads are accessing the data, after this returns, it is ok to free floatBytes and all calls to access data will fail gracefully
						// (except inlineBuffer based calls, check the return value of aquireInlineBuffer: to make sure it is ok to call the inline functions) 
                        // if the data is not owned by the CPRVolumeData, make sure to call invalidateData before freeing the data, even before releasing,
                        // in case other objects have retained the receiver

- (BOOL)getFloatData:(float *)buffer range:(NSRange)range; // returns YES if the data was sucessfully filled

- (CPRUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z;
- (CPRVolumeData *)volumeDataForSliceAtIndex:(NSUInteger)z;

- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z; // returns YES if the float was sucessfully gotten
- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector; // these are slower, use the inline buffer if you care about speed

- (BOOL)aquireInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer; // make sure to pair this with a releaseInlineBuffer (even if it returns NO!), returns YES if the data is valid. The data will be locked and remain valid until releaseInlineBuffer: is called
- (void)releaseInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer; 

// not done yet, will crash if given vectors that are outside of the volume
- (NSUInteger)tempBufferSizeForNumVectors:(NSUInteger)numVectors;
- (void)linearInterpolateVolumeVectors:(N3VectorArray)volumeVectors outputValues:(float *)outputValues numVectors:(NSUInteger)numVectors tempBuffer:(void *)tempBuffer;
// end not done

@end


@interface CPRVolumeData (DCMPixAndVolume) // make a nice clean interface between the rest of of OsiriX that deals with pixlist and all their complications, and fill out our convenient data structure.

- (id) initWithWithPixList:(NSArray *)pixList volume:(NSData *)volume;

- (void)getOrientation:(float[6])orientation;
- (void)getOrientationDouble:(double[6])orientation;

@property (readonly) float originX;
@property (readonly) float originY;
@property (readonly) float originZ;

@end

CF_INLINE const float* CPRVolumeDataFloatBytes(CPRVolumeDataInlineBuffer *inlineBuffer)
{
	return inlineBuffer->floatBytes;
}

CF_INLINE float CPRVolumeDataGetFloatAtPixelCoordinate(CPRVolumeDataInlineBuffer *inlineBuffer, NSUInteger x, NSUInteger y, NSUInteger z)
{
    if (inlineBuffer->floatBytes) {
        return (inlineBuffer->floatBytes)[x + y*inlineBuffer->pixelsWide + z*inlineBuffer->pixelsWideTimesPixelsHigh];
    } else {
        return 0;
    }
}

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(CPRVolumeDataInlineBuffer *inlineBuffer, CGFloat x, CGFloat y, CGFloat z) // coordinate in the pixel space
{
    float returnValue;
    
    NSInteger floorX = x;
    NSInteger ceilX = floorX+1.0;
    NSInteger floorY = y;
    NSInteger ceilY = floorY+1.0;
    NSInteger floorZ = z;
    NSInteger ceilZ = floorZ+1.0;
    
    bool outside = false;
    outside |= floorX < 0;
    outside |= floorY < 0;
    outside |= floorZ < 0;
    outside |= ceilX >= inlineBuffer->pixelsWide;
    outside |= ceilY >= inlineBuffer->pixelsHigh;
    outside |= ceilZ >= inlineBuffer->pixelsDeep;
    
    if (outside) {
        returnValue = -1000.0f;
    } else {
        float xd = x - floorf((float)x);
        float yd = y - floorf((float)y);
        float zd = z - floorf((float)z);
        
        float xda = 1.0f - xd;
        float yda = 1.0f - yd;
        float zda = 1.0f - zd;
        
        float i1 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, floorY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, floorY, ceilZ)*zd;
        float i2 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, ceilY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, ceilY, ceilZ)*zd;
        
        float w1 = i1*yda + i2*yd;
        
        float j1 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, floorY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, floorY, ceilZ)*zd;
        float j2 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, ceilY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, ceilY, ceilZ)*zd;
        
        float w2 = j1*yda + j2*yd;
        
        returnValue = w1*xda + w2*xd;
    }
    
    return returnValue;
}

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtDicomVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector) // coordinate in mm dicom space
{
    vector = N3VectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtVolumeVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector)
{
    return CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_EXTERN_C_END

