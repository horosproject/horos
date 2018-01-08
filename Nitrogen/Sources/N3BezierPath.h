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
#import "N3BezierCore.h"
#import "N3BezierCoreAdditions.h"

// N3BezierDefaultFlatness and N3BezierDefaultSubdivideSegmentLength are defined in N3BezierCore.h
// N3BezierNodeStyle is defined in N3BezierCoreAdditions.h

@class NSBezierPath;

enum _N3BezierPathElement {
    N3MoveToBezierPathElement,
    N3LineToBezierPathElement,
    N3CurveToBezierPathElement,
	N3CloseBezierPathElement
};
typedef NSInteger N3BezierPathElement;

@interface N3BezierPath : NSObject <NSCopying, NSMutableCopying, NSCoding, NSFastEnumeration> // fast enumeration returns NSValues of the endpoints
{
    N3MutableBezierCoreRef _bezierCore;
    CGFloat _length;
    N3BezierCoreRandomAccessorRef _bezierCoreRandomAccessor;
}

- (id)init;
- (id)initWithBezierPath:(N3BezierPath *)bezierPath;
- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (id)initWithN3BezierCore:(N3BezierCoreRef)bezierCore;
- (id)initWithNodeArray:(NSArray *)nodes style:(N3BezierNodeStyle)style; // array of N3Vectors in NSValues;

+ (id)bezierPath;
+ (id)bezierPathWithBezierPath:(N3BezierPath *)bezierPath;
+ (id)bezierPathN3BezierCore:(N3BezierCoreRef)bezierCore;
+ (id)bezierPathCircleWithCenter:(N3Vector)center radius:(CGFloat)radius normal:(N3Vector)normal;

- (BOOL)isEqualToBezierPath:(N3BezierPath *)bezierPath;

- (N3BezierPath *)bezierPathByFlattening:(CGFloat)flatness;
- (N3BezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
- (N3BezierPath *)bezierPathByApplyingTransform:(N3AffineTransform)transform;
- (N3BezierPath *)bezierPathByAppendingBezierPath:(N3BezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (N3BezierPath *)bezierPathByAddingEndpointsAtIntersectionsWithPlane:(N3Plane)plane; // will  flatten the path if it is not already flattened
- (N3BezierPath *)bezierPathByProjectingToPlane:(N3Plane)plane;
- (N3BezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(N3Vector)initalNormal spacing:(CGFloat)spacing;
- (N3BezierPath *)outlineBezierPathAtDistance:(CGFloat)distance projectionNormal:(N3Vector)projectionNormal spacing:(CGFloat)spacing;

- (NSInteger)elementCount;
- (CGFloat)length;
- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element; // the length of the curve up to and including the element at index
- (N3BezierCoreRef)N3BezierCore;
- (NSDictionary *)dictionaryRepresentation;
- (N3Vector)vectorAtStart;
- (N3Vector)vectorAtEnd;
- (N3Vector)tangentAtStart;
- (N3Vector)tangentAtEnd;
- (N3Vector)normalAtEndWithInitialNormal:(N3Vector)initialNormal;
- (BOOL)isPlanar;
- (N3Plane)leastSquaresPlane;
- (N3Plane)topBoundingPlaneForNormal:(N3Vector)normal;
- (N3Plane)bottomBoundingPlaneForNormal:(N3Vector)normal;
- (N3BezierPathElement)elementAtIndex:(NSInteger)index;
- (N3BezierPathElement)elementAtIndex:(NSInteger)index control1:(N3VectorPointer)control1 control2:(N3VectorPointer)control2 endpoint:(N3VectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is is not always the end

// extra functions to help with rendering and such
- (N3Vector)vectorAtRelativePosition:(CGFloat)relativePosition; // RelativePosition is in [0, 1]
- (N3Vector)tangentAtRelativePosition:(CGFloat)relativePosition;
- (N3Vector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(N3Vector)initialNormal;

- (CGFloat)relativePositionClosestToVector:(N3Vector)vector;
- (CGFloat)relativePositionClosestToLine:(N3Line)line;
- (CGFloat)relativePositionClosestToLine:(N3Line)line closestVector:(N3VectorPointer)vectorPointer;
- (N3BezierPath *)bezierPathByCollapsingZ;
- (N3BezierPath *)bezierPathByReversing;

- (NSArray*)intersectionsWithPlane:(N3Plane)plane; // returns NSValues containing N3Vectors of the intersections.
- (NSArray*)intersectionsWithPlane:(N3Plane)plane relativePositions:(NSArray **)returnedRelativePositions;

- (NSArray *)subPaths;
- (N3BezierPath *)bezierPathByClippingFromRelativePosition:(CGFloat)startRelativePosition toRelativePosition:(CGFloat)endRelativePosition;

- (CGFloat)signedAreaUsingNormal:(N3Vector)normal;

@end


@interface N3MutableBezierPath : N3BezierPath
{
}

- (void)moveToVector:(N3Vector)vector;
- (void)lineToVector:(N3Vector)vector;
- (void)curveToVector:(N3Vector)vector controlVector1:(N3Vector)controlVector1 controlVector2:(N3Vector)controlVector2;
- (void)close;

- (void)flatten:(CGFloat)flatness;
- (void)subdivide:(CGFloat)maxSegmentLength;
- (void)applyAffineTransform:(N3AffineTransform)transform;
- (void)projectToPlane:(N3Plane)plane;
- (void)appendBezierPath:(N3BezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (void)addEndpointsAtIntersectionsWithPlane:(N3Plane)plane; // will  flatten the path if it is not already flattened
- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(N3Vector)control1 control2:(N3Vector)control2 endpoint:(N3Vector)endpoint;

@end



