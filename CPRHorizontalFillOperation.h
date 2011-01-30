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

@class CPRVolumeData;

// This operation will fill out floatBytes from the given data. FloatBytes is assumed to be tightly packed float image of width "width" and height "height"
// float bytes will be filled in with values at vectors and each successive scan line will be filled with with values at vector+normal*scanlineNumber
@interface CPRHorizontalFillOperation : NSOperation {
    CPRVolumeData *_volumeData;
    
    float *_floatBytes;
    NSUInteger _width;
    NSUInteger _height;
        
    CPRVectorArray _vectors;
    CPRVectorArray _normals;
    
    BOOL _linearInterpolating;
}

// vectors and normals need to be arrays of length width
- (id)initWithVolumeData:(CPRVolumeData *)volumeData floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(CPRVectorArray)vectors normals:(CPRVectorArray)normals;

@property (readonly, retain) CPRVolumeData *volumeData;

@property (readonly, assign) float *floatBytes;
@property (readonly, assign) NSUInteger width;
@property (readonly, assign) NSUInteger height;

@property (readonly, assign) CPRVectorArray vectors;
@property (readonly, assign) CPRVectorArray normals;

@property (readwrite, assign, getter=isLinearInterpolating) BOOL linearInterpolating; // YES by default

@end
