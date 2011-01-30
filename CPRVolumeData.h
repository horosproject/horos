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
#import "CPRGeometry.h"

@class CPRUnsignedInt16ImageRep;

CF_EXTERN_C_BEGIN

typedef struct { // build one of these on the stack and then use -[CPRVolumeData getInlineBuffer:] to initialize it
    const float *floatBytes;
    
    NSUInteger pixelsWide;
    NSUInteger pixelsHigh;
    NSUInteger pixelsDeep;
    
    NSUInteger pixelsWideTimesPixelsHigh; // just in the interest of not calculating this a million times...
    
    CPRAffineTransform3D volumeTransform;
} CPRVolumeDataInlineBuffer;

// Interface to the data
@interface CPRVolumeData : NSObject {
    const float *_floatBytes;
    
    NSUInteger _pixelsWide;
    NSUInteger _pixelsHigh;
    NSUInteger _pixelsDeep;
    
    CPRAffineTransform3D _volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data
    
    BOOL _freeWhenDone;
}


- (id)initWithFloatBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
               volumeTransform:(CPRAffineTransform3D)volumeTransform freeWhenDone:(BOOL)freeWhenDone; // volumeTransform is the transform from Dicom (patient) space to pixel data

@property (readonly) NSUInteger pixelsWide;
@property (readonly) NSUInteger pixelsHigh;
@property (readonly) NSUInteger pixelsDeep;

@property (readonly, getter=isRectilinear) BOOL rectilinear;

@property (readonly) CGFloat minPixelSpacing; // the smallet pixel spacing in any direction;
@property (readonly) CGFloat pixelSpacingX;
@property (readonly) CGFloat pixelSpacingY;
@property (readonly) CGFloat pixelSpacingZ;

@property (readonly) CPRAffineTransform3D volumeTransform;

- (const float *)floatBytes;

- (CPRUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z;

- (float)floatAtPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z;
- (float)linearInterpolatedFloatAtDicomVector:(CPRVector)vector; // these are slower, use the inline buffer if you care about speed

- (void)getInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer; 

// not done yet, will crash if given vectors that are outside of the volume
- (NSUInteger)tempBufferSizeForNumVectors:(NSUInteger)numVectors;
- (void)linearInterpolateVolumeVectors:(CPRVectorArray)volumeVectors outputValues:(float *)outputValues numVectors:(NSUInteger)numVectors tempBuffer:(void *)tempBuffer;
// end not done
@end


@interface CPRVolumeData (DCMPixAndVolume) // make a nice clean interface between the rest of of OsiriX that deals with pixlist and all their complications, and fill out our convenient data structure.

- (id) initWithWithPixList:(NSArray *)pixList volume:(NSData *)volume;

@end


CF_INLINE float CPRVolumeDataGetFloatAtPixelCoordinate(CPRVolumeDataInlineBuffer *inlineBuffer, NSUInteger x, NSUInteger y, NSUInteger z)
{
    return (inlineBuffer->floatBytes)[x + y*inlineBuffer->pixelsWide + z*inlineBuffer->pixelsWideTimesPixelsHigh];
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

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtDicomVector(CPRVolumeDataInlineBuffer *inlineBuffer, CPRVector vector) // coordinate in mm dicom space
{
    vector = CPRVectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtVolumeVector(CPRVolumeDataInlineBuffer *inlineBuffer, CPRVector vector)
{
    return CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}



CF_EXTERN_C_END

