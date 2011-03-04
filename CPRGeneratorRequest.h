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
#import "CPRProjectionOperation.h"

// a class to encapsulate all the different parameters required to generate a CPR Image
// still working on how to engineer this, it this version sticks, this will be broken up into two files

@class N3BezierPath;

@interface CPRGeneratorRequest : NSObject  <NSCopying> {
    NSUInteger _pixelsWide;
    NSUInteger _pixelsHigh;
    
    CGFloat _slabWidth;
    CGFloat _slabSampleDistance;
    
    void *_context;
}

// specifify the size of the returned data
@property (nonatomic, readwrite, assign) NSUInteger pixelsWide;
@property (nonatomic, readwrite, assign) NSUInteger pixelsHigh;

@property (nonatomic, readwrite, assign) CGFloat slabWidth; // width of the slab in millimeters
@property (nonatomic, readwrite, assign) CGFloat slabSampleDistance; // mm/slab if this is set to 0, a reasonable value will be picked automatically, otherwise, this value 

@property (nonatomic, readwrite, assign) void *context;

- (BOOL)isEqual:(id)object;

- (Class)operationClass;

@end


@interface CPRStraightenedGeneratorRequest : CPRGeneratorRequest
{
    N3BezierPath *_bezierPath;
    N3Vector _initialNormal;
    
    CPRProjectionMode _projectionMode;
//    BOOL _vertical; // it would be cool to implement this one day
}

@property (nonatomic, readwrite, retain) N3BezierPath *bezierPath;
@property (nonatomic, readwrite, assign) N3Vector initialNormal; // the down direction on the left/top of the output CPR, this vector must be normal to the initial tangent of the curve

@property (nonatomic, readwrite, assign) CPRProjectionMode projectionMode;

// these are not yet implemented, depending on how we want to implement panning and zooming of the curved MPR, they could be useful 
// @property (nonatomic, readwrite, assign) BOOL vertical; // the straightened bezier is horizantal across the screen, or vertical it would be cool to implement this one day

- (BOOL)isEqual:(id)object;

@end


