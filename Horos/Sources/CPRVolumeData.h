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

#import <Cocoa/Cocoa.h>
#import "N3Geometry.h"

@class CPRUnsignedInt16ImageRep;

CF_EXTERN_C_BEGIN

enum _CPRInterpolationMode {
    CPRInterpolationModeLinear, // don't use this, it is not implemented
    CPRInterpolationModeNearestNeighbor,
    CPRInterpolationModeCubic,
	
	CPRInterpolationModeNone = 0xFFFFFF,
};
typedef NSInteger CPRInterpolationMode;

typedef struct { // build one of these on the stack and then use -[CPRVolumeData aquireInlineBuffer:] to initialize it. Then make sure to release it too!
    const float *floatBytes;
    
    float outOfBoundsValue;
    
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
    float _outOfBoundsValue;
    
    NSUInteger _pixelsWide;
    NSUInteger _pixelsHigh;
    NSUInteger _pixelsDeep;
    
    N3AffineTransform _volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data
    
    BOOL _freeWhenDone;
    
    NSMutableDictionary *_childSubvolumes; // volumeData objects that point to the same underlying data
}


- (id)initWithFloatBytesNoCopy:(const float *)floatBytes pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh pixelsDeep:(NSUInteger)pixelsDeep
               volumeTransform:(N3AffineTransform)volumeTransform outOfBoundsValue:(float)outOfBoundsValue freeWhenDone:(BOOL)freeWhenDone; // volumeTransform is the transform from Dicom (patient) space to pixel data

@property (readonly) NSUInteger pixelsWide;
@property (readonly) NSUInteger pixelsHigh;
@property (readonly) NSUInteger pixelsDeep;

@property (readonly, getter=isRectilinear) BOOL rectilinear;

@property (readonly) CGFloat minPixelSpacing; // the smallest pixel spacing in any direction;
@property (readonly) CGFloat pixelSpacingX;// mm/pixel
@property (readonly) CGFloat pixelSpacingY;
@property (readonly) CGFloat pixelSpacingZ;

@property (readonly) float outOfBoundsValue;

@property (readonly) N3AffineTransform volumeTransform; // volumeTransform is the transform from Dicom (patient) space to pixel data

- (BOOL)isDataValid;
- (void)invalidateData; // this is to be called right before freeing the data by objects who own the floatBytes that were given to the receiver
						// this may lock temporarily if other threads are accessing the data, after this returns, it is ok to free floatBytes and all calls to access data will fail gracefully
						// (except inlineBuffer based calls, check the return value of aquireInlineBuffer: to make sure it is ok to call the inline functions) 
                        // if the data is not owned by the CPRVolumeData, make sure to call invalidateData before freeing the data, even before releasing,
                        // in case other objects have retained the receiver

//- (BOOL)getFloatData:(float *)buffer range:(NSRange)range; // returns YES if the data was sucessfully filled

// will copy fill length*sizeof(float) bytes, the coordinates better be within the volume!!!
// a run a is a series of pixels in the x direction
- (BOOL)getFloatRun:(float *)buffer atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z length:(NSUInteger)length; 

- (CPRUnsignedInt16ImageRep *)unsignedInt16ImageRepForSliceAtIndex:(NSUInteger)z;
- (CPRVolumeData *)volumeDataForSliceAtIndex:(NSUInteger)z;

- (BOOL)getFloat:(float *)floatPtr atPixelCoordinateX:(NSUInteger)x y:(NSUInteger)y z:(NSUInteger)z; // returns YES if the float was sucessfully gotten
- (BOOL)getLinearInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector; // these are slower, use the inline buffer if you care about speed
- (BOOL)getNearestNeighborInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector; // these are slower, use the inline buffer if you care about speed
- (BOOL)getCubicInterpolatedFloat:(float *)floatPtr atDicomVector:(N3Vector)vector; // these are slower, use the inline buffer if you care about speed

- (BOOL)aquireInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer; // make sure to pair this with a releaseInlineBuffer (even if it returns NO!), returns YES if the data is valid. The data will be locked and remain valid until releaseInlineBuffer: is called
- (void)releaseInlineBuffer:(CPRVolumeDataInlineBuffer *)inlineBuffer; 

// not done yet, will crash if given vectors that are outside of the volume
- (NSUInteger)tempBufferSizeForNumVectors:(NSUInteger)numVectors;
- (void)linearInterpolateVolumeVectors:(N3VectorArray)volumeVectors outputValues:(float *)outputValues numVectors:(NSUInteger)numVectors tempBuffer:(void *)tempBuffer;
// end not done

@end


@interface CPRVolumeData (DCMPixAndVolume) // make a nice clean interface between the rest of of Horos that deals with pixlist and all their complications, and fill out our convenient data structure.

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


CF_INLINE float CPRVolumeDataGetFloatAtPixelCoordinate(CPRVolumeDataInlineBuffer *inlineBuffer, NSInteger x, NSInteger y, NSInteger z)
{
    bool outside;
    
    if (inlineBuffer->floatBytes) {
        outside = false;
        
        outside |= x < 0;
        outside |= y < 0;
        outside |= z < 0;
        outside |= x >= inlineBuffer->pixelsWide;
        outside |= y >= inlineBuffer->pixelsHigh;
        outside |= z >= inlineBuffer->pixelsDeep;
        
        if (!outside) {
            return (inlineBuffer->floatBytes)[x + y*inlineBuffer->pixelsWide + z*inlineBuffer->pixelsWideTimesPixelsHigh];
        } else {
            return inlineBuffer->outOfBoundsValue;
        }
    } else {
        return 0;
    }
}

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(CPRVolumeDataInlineBuffer *inlineBuffer, CGFloat x, CGFloat y, CGFloat z) // coordinate in the pixel space
{
    float returnValue;
    
    NSInteger floorX = (x);
    NSInteger ceilX = floorX+1.0;
    NSInteger floorY = (y);
    NSInteger ceilY = floorY+1.0;
    NSInteger floorZ = (z);
    NSInteger ceilZ = floorZ+1.0;
    
    bool outside = false;
    outside |= floorX < 0;
    outside |= floorY < 0;
    outside |= floorZ < 0;
    outside |= ceilX >= inlineBuffer->pixelsWide;
    outside |= ceilY >= inlineBuffer->pixelsHigh;
    outside |= ceilZ >= inlineBuffer->pixelsDeep;
    
    if (outside || !inlineBuffer->floatBytes) {
        returnValue = inlineBuffer->outOfBoundsValue;
    } else {
        float xd = x - floorX;
        float yd = y - floorY;
        float zd = z - floorZ;
//        
//        float xda = 1.0f - xd;
//        float yda = 1.0f - yd;
//        float zda = 1.0f - zd;
//        
//        float i1 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, floorY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, floorY, ceilZ)*zd;
//        float i2 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, ceilY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, floorX, ceilY, ceilZ)*zd;
//        
//        float w1 = i1*yda + i2*yd;
//        
//        float j1 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, floorY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, floorY, ceilZ)*zd;
//        float j2 = CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, ceilY, floorZ)*zda + CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, ceilX, ceilY, ceilZ)*zd;
//        
//        float w2 = j1*yda + j2*yd;
//        
//        returnValue = w1*xda + w2*xd;
        
        
#define trilinFuncMacro(v,x,y,z,a,b,c,d,e,f,g,h)         \
t00 =   a + (x)*(b-a);      \
t01 =   c + (x)*(d-c);      \
t10 =   e + (x)*(f-e);      \
t11 =   g + (x)*(h-g);      \
t0  = t00 + (y)*(t01-t00);  \
t1  = t10 + (y)*(t11-t10);  \
v   =  t0 + (z)*(t1-t0);

        float A, B, C, D, E, F, G, H;
        float t00, t01, t10, t11, t0, t1;
        int Binc, Cinc, Dinc, Einc, Finc, Ginc, Hinc;
        int xinc, yinc, zinc;
        
        xinc = 1;
        yinc = (int)inlineBuffer->pixelsWide;
        zinc = (int)inlineBuffer->pixelsWideTimesPixelsHigh;
        
        // Compute the increments to get to the other 7 voxel vertices from A
        Binc = xinc;
        Cinc = yinc;
        Dinc = xinc + yinc;
        Einc = zinc;
        Finc = zinc + xinc;
        Ginc = zinc + yinc;
        Hinc = zinc + xinc + yinc;
        
        // Set values for the first pass through the loop
        const float *dptr = inlineBuffer->floatBytes + floorZ * zinc + floorY * yinc + floorX;
        A = *(dptr);
        B = *(dptr + Binc);
        C = *(dptr + Cinc);
        D = *(dptr + Dinc);
        E = *(dptr + Einc);
        F = *(dptr + Finc);
        G = *(dptr + Ginc);
        H = *(dptr + Hinc);
        
        trilinFuncMacro( returnValue, xd, yd, zd, A, B, C, D, E, F, G, H );
    }
    
    return returnValue;
}

CF_INLINE float CPRVolumeDataNearestNeighborInterpolatedFloatAtVolumeCoordinate(CPRVolumeDataInlineBuffer *inlineBuffer, CGFloat x, CGFloat y, CGFloat z) // coordinate in the pixel space
{
    NSInteger roundX = (x + 0.5f);
    NSInteger roundY = (y + 0.5f);
    NSInteger roundZ = (z + 0.5f);
        
    return CPRVolumeDataGetFloatAtPixelCoordinate(inlineBuffer, roundX, roundY, roundZ);
}

CF_INLINE NSInteger CPRVolumeDataIndexAtCoordinate(NSInteger x, NSInteger y, NSInteger z, NSUInteger pixelsWide, NSInteger pixelsHigh, NSInteger pixelsDeep, NSInteger outOfBoundsIndex)
{
    if (x < 0 || x >= pixelsWide ||
        y < 0 || y >= pixelsHigh ||
        z < 0 || z >= pixelsDeep) {
        return outOfBoundsIndex;
    }
    return x + pixelsWide*(y + pixelsHigh*z);
}

CF_INLINE NSInteger CPRVolumeDataUncheckedIndexAtCoordinate(NSInteger x, NSInteger y, NSInteger z, NSUInteger pixelsWide, NSInteger pixelsHigh, NSInteger pixelsDeep)
{
    return x + pixelsWide*(y + pixelsHigh*z);
}

CF_INLINE void CPRVolumeDataGetCubicIndexes(NSInteger cubicIndexes[64], NSInteger x, NSInteger y, NSInteger z, NSUInteger pixelsWide, NSInteger pixelsHigh, NSInteger pixelsDeep, NSInteger outOfBoundsIndex)
{
    if (x <= 2 || y <= 2 || z <= 2 || x >= pixelsWide-3 || y >= pixelsHigh-3 || z >= pixelsDeep-3) {
        for (int i = 0; i < 4; ++i) {
            for (int j = 0; j < 4; ++j) {
                for (int k = 0; k < 4; ++k) {
                    cubicIndexes[i+4*(j+4*k)] = CPRVolumeDataIndexAtCoordinate(x+i-1, y+j-1, z+k-1, pixelsWide, pixelsHigh, pixelsDeep, outOfBoundsIndex);
                }
            }
        }
    } else {
        for (int i = 0; i < 4; ++i) {
            for (int j = 0; j < 4; ++j) {
                for (int k = 0; k < 4; ++k) {
                    cubicIndexes[i+4*(j+4*k)] = CPRVolumeDataUncheckedIndexAtCoordinate(x+i-1, y+j-1, z+k-1, pixelsWide, pixelsHigh, pixelsDeep);
                }
            }
        }
    }
}

CF_INLINE float CPRVolumeDataCubicInterpolatedFloatAtVolumeCoordinate(CPRVolumeDataInlineBuffer *inlineBuffer, CGFloat x, CGFloat y, CGFloat z) // coordinate in the pixel space
{
#if CGFLOAT_IS_DOUBLE
    const CGFloat x_floor = floor(x);
    const CGFloat y_floor = floor(y);
    const CGFloat z_floor = floor(z);
#else
    const CGFloat x_floor = floorf(x);
    const CGFloat y_floor = floorf(y);
    const CGFloat z_floor = floorf(z);
#endif

    const CGFloat dx = x-x_floor;
    const CGFloat dy = y-y_floor;
    const CGFloat dz = z-z_floor;

    const CGFloat dxx = dx*dx;
    const CGFloat dxxx = dxx*dx;

    const CGFloat dyy = dy*dy;
    const CGFloat dyyy = dyy*dy;

    const CGFloat dzz = dz*dz;
    const CGFloat dzzz = dzz*dz;

    const CGFloat wx0 = 0.5 * (    - dx + 2.0*dxx -       dxxx);
    const CGFloat wx1 = 0.5 * (2.0      - 5.0*dxx + 3.0 * dxxx);
    const CGFloat wx2 = 0.5 * (      dx + 4.0*dxx - 3.0 * dxxx);
    const CGFloat wx3 = 0.5 * (         -     dxx +       dxxx);

    const CGFloat wy0 = 0.5 * (    - dy + 2.0*dyy -       dyyy);
    const CGFloat wy1 = 0.5 * (2.0      - 5.0*dyy + 3.0 * dyyy);
    const CGFloat wy2 = 0.5 * (      dy + 4.0*dyy - 3.0 * dyyy);
    const CGFloat wy3 = 0.5 * (         -     dyy +       dyyy);

    const CGFloat wz0 = 0.5 * (    - dz + 2.0*dzz -       dzzz);
    const CGFloat wz1 = 0.5 * (2.0      - 5.0*dzz + 3.0 * dzzz);
    const CGFloat wz2 = 0.5 * (      dz + 4.0*dzz - 3.0 * dzzz);
    const CGFloat wz3 = 0.5 * (         -     dzz +       dzzz);

    // this is a horible hack, but it works
    // what I'm doing is looking at memory addresses to find an index into inlineBuffer->floatBytes that would jump out of
    // the array and instead point to inlineBuffer->outOfBoundsValue which is on the stack
    // This relies on both inlineBuffer->floatBytes and inlineBuffer->outOfBoundsValue being on a sizeof(float) boundry
    NSInteger outOfBoundsIndex = (((NSInteger)&(inlineBuffer->outOfBoundsValue)) - ((NSInteger)inlineBuffer->floatBytes)) / sizeof(float);

    NSInteger cubicIndexes[64];
    CPRVolumeDataGetCubicIndexes(cubicIndexes, x_floor, y_floor, z_floor, inlineBuffer->pixelsWide, inlineBuffer->pixelsHigh, inlineBuffer->pixelsDeep, outOfBoundsIndex);

    const float *floatBytes = inlineBuffer->floatBytes;

    return wz0*(
             wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*0)]]) +
             wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*0)]]) +
             wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*0)]]) +
             wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*0)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*0)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*0)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*0)]])
             ) +
        wz1*(
             wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*1)]]) +
             wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*1)]]) +
             wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*1)]]) +
             wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*1)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*1)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*1)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*1)]])
             ) +
        wz2*(
             wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*2)]]) +
             wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*2)]]) +
             wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*2)]]) +
             wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*2)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*2)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*2)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*2)]])
             ) +
        wz3*(
             wy0*(wx0 * floatBytes[cubicIndexes[0+4*(0+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(0+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(0+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(0+4*3)]]) +
             wy1*(wx0 * floatBytes[cubicIndexes[0+4*(1+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(1+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(1+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(1+4*3)]]) +
             wy2*(wx0 * floatBytes[cubicIndexes[0+4*(2+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(2+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(2+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(2+4*3)]]) +
             wy3*(wx0 * floatBytes[cubicIndexes[0+4*(3+4*3)]] + wx1 * floatBytes[cubicIndexes[1+4*(3+4*3)]] +  wx2 * floatBytes[cubicIndexes[2+4*(3+4*3)]] + wx3 * floatBytes[cubicIndexes[3+4*(3+4*3)]])
             );
}

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtDicomVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector) // coordinate in mm dicom space
{
    vector = N3VectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float CPRVolumeDataNearestNeighborInterpolatedFloatAtDicomVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector) // coordinate in mm dicom space
{
    vector = N3VectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return CPRVolumeDataNearestNeighborInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float CPRVolumeDataCubicInterpolatedFloatAtDicomVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector) // coordinate in mm dicom space
{
    vector = N3VectorApplyTransform(vector, inlineBuffer->volumeTransform);
    return CPRVolumeDataCubicInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float CPRVolumeDataLinearInterpolatedFloatAtVolumeVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector)
{
    return CPRVolumeDataLinearInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float CPRVolumeDataNearestNeighborInterpolatedFloatAtVolumeVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector)
{
    return CPRVolumeDataNearestNeighborInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_INLINE float CPRVolumeDataCubicInterpolatedFloatAtVolumeVector(CPRVolumeDataInlineBuffer *inlineBuffer, N3Vector vector)
{
    return CPRVolumeDataCubicInterpolatedFloatAtVolumeCoordinate(inlineBuffer, vector.x, vector.y, vector.z);
}

CF_EXTERN_C_END

