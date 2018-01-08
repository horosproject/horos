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

#import "N3Geometry.h"

@class N3MutableBezierPath;
@class CPRVolumeData;
@class DICOMExport;

// all points in the CurvedPath live in patient space
// in order to avoid confusion about what coordinate space things are in, all methods take points in an arbitrary coordinate
// space and take the transform from that space to the patient space

typedef uint32_t CPRCurvedPathControlToken;

extern const int32_t CPRCurvedPathControlTokenNone;

// CPRCurved path is all the data related to a CPR. All the transitory UI stuff is in CPRDisplayInfo

@interface CPRCurvedPath : NSObject <NSCopying, NSCoding>
{
    N3MutableBezierPath *_bezierPath;
    NSMutableArray *_nodes;
    NSMutableArray *_nodeRelativePositions; // NSNumbers with a cache of the nodes' relative positions;
    
    N3Vector _baseDirection;
    CGFloat _angle;
    CGFloat _thickness;
    CGFloat _transverseSectionSpacing;
    CGFloat _transverseSectionPosition;
}

+ (BOOL)controlTokenIsNode:(CPRCurvedPathControlToken)token;
+ (NSInteger)nodeIndexForToken:(CPRCurvedPathControlToken)token;
+ (CPRCurvedPathControlToken)controlTokenForNodeIndex:(NSInteger)nodeIndex;

- (id)init;

- (void)addNode:(NSPoint)point transform:(N3AffineTransform)transform; // adds the point to z = 0 in the arbitrary coordinate space
- (void)insertPatientNode:(N3Vector)node atIndex:(NSUInteger)index; // adds the point to z = 0 in the arbitrary coordinate space to a given index
- (void)addPatientNode:(N3Vector)node;
- (NSInteger)insertNodeAtRelativePosition:(CGFloat)relativePosition; // returns the node index of the inserted node
- (void)removeNodeAtIndex:(NSInteger)index;
- (void)clearPath;

- (void)moveControlToken:(CPRCurvedPathControlToken)token toPoint:(NSPoint)point transform:(N3AffineTransform)transform; // resets Z by default
- (void)moveNodeAtIndex:(NSInteger)index toVector:(N3Vector)vector; // for this exceptional method, the vector is given in patient space

- (CPRCurvedPathControlToken)controlTokenNearPoint:(NSPoint)point transform:(N3AffineTransform)transform;

- (CGFloat)relativePositionForPoint:(NSPoint)point transform:(N3AffineTransform)transform;
- (CGFloat)relativePositionForPoint:(NSPoint)point transform:(N3AffineTransform)transform distanceToPoint:(CGFloat *)distance; // returns the distance in the coordinate space of point (screen coordinates)
- (CGFloat)relativePositionForControlToken:(CPRCurvedPathControlToken)token;
- (CGFloat)relativePositionForNodeAtIndex:(NSUInteger)nodeIndex;

- (NSArray *)transverseSliceRequestsForSpacing:(CGFloat)spacing outputWidth:(NSUInteger)width outputHeight:(NSUInteger)height mmWide:(CGFloat)mmWide; // mmWide is the how wide in patient coordinates the transverse slice should be

- (BOOL)isPlaneMeasurable; // bad name, but if this is true, we will let folks make measurements on the generated plane

@property (nonatomic, readonly, retain) N3MutableBezierPath *bezierPath;
@property (nonatomic, readwrite, assign) CGFloat thickness;
@property (nonatomic, readwrite, assign) N3Vector baseDirection; // a base direction from which to define things such as the initial normal
@property (nonatomic, readwrite, assign) CGFloat angle;
@property (nonatomic, readwrite, assign) N3Vector initialNormal;
@property (nonatomic, readwrite, assign) CGFloat transverseSectionSpacing; // in mm
@property (nonatomic, readwrite, assign) CGFloat transverseSectionPosition; // as a relative position [0, 1] pass -1 if you don't want the trasvers section to appear
@property (nonatomic, readonly, assign) CGFloat leftTransverseSectionPosition;
@property (nonatomic, readonly, assign) CGFloat rightTransverseSectionPosition;
@property (readonly, copy) NSArray* nodes; // N3Vectors stored in NSValues

- (N3Vector)stretchedProjectionNormal;

@end
