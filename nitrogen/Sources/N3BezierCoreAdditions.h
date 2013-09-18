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

#ifndef _N3BEZIERCORE_ADDITIONS_H_
#define _N3BEZIERCORE_ADDITIONS_H_

#include "N3BezierCore.h"

// N3BezierCore functions that don't need any access to the actual implementation details of the N3BezierCore

CF_EXTERN_C_BEGIN

enum N3BezierNodeStyle {
    N3BezierNodeOpenEndsStyle, // the direction of the end segements point out. this is the style used by the CPR View
    N3BezierNodeEndsMeetStyle, // the direction of the end segements point to each other. this is the style that mimics what open ROIs do
};
typedef enum N3BezierNodeStyle N3BezierNodeStyle;

N3BezierCoreRef N3BezierCoreCreateCurveWithNodes(N3VectorArray vectors, CFIndex numVectors, N3BezierNodeStyle style);
N3MutableBezierCoreRef N3BezierCoreCreateMutableCurveWithNodes(N3VectorArray vectors, CFIndex numVectors, N3BezierNodeStyle style);

N3Vector N3BezierCoreVectorAtStart(N3BezierCoreRef bezierCore);
N3Vector N3BezierCoreVectorAtEnd(N3BezierCoreRef bezierCore);

N3Vector N3BezierCoreTangentAtStart(N3BezierCoreRef bezierCore);
N3Vector N3BezierCoreTangentAtEnd(N3BezierCoreRef bezierCore);
N3Vector N3BezierCoreNormalAtEndWithInitialNormal(N3BezierCoreRef bezierCore, N3Vector initialNormal);

CGFloat N3BezierCoreRelativePositionClosestToVector(N3BezierCoreRef bezierCore, N3Vector vector, N3VectorPointer closestVector, CGFloat *distance); // a relative position is a value between [0, 1]
CGFloat N3BezierCoreRelativePositionClosestToLine(N3BezierCoreRef bezierCore, N3Line line, N3VectorPointer closestVector, CGFloat *distance);

CFIndex N3BezierCoreGetVectorInfo(N3BezierCoreRef bezierCore, CGFloat spacing, CGFloat startingPoint, N3Vector initialNormal,  // returns evenly spaced vectors, tangents and normals starting at startingPoint
                    N3VectorArray vectors, N3VectorArray tangents, N3VectorArray normals, CFIndex numVectors); // fills numVectors in the vector arrays, returns the actual number of vectors that were set in the arrays

// for stretched CPR
CFIndex N3BezierCoreGetProjectedVectorInfo(N3BezierCoreRef bezierCore, CGFloat spacing, CGFloat startingDistance, N3Vector projectionDirection,
                                           N3VectorArray vectors, N3VectorArray tangents, N3VectorArray normals, CGFloat *relativePositions, CFIndex numVectors);

N3BezierCoreRef N3BezierCoreCreateOutline(N3BezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, N3Vector initialNormal); // distance from the center, spacing is the distance between ponts on the curve that are sampled to generate the outline
N3MutableBezierCoreRef N3BezierCoreCreateMutableOutline(N3BezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, N3Vector initialNormal);

N3BezierCoreRef N3BezierCoreCreateOutlineWithNormal(N3BezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, N3Vector projectionNormal);
N3MutableBezierCoreRef N3BezierCoreCreateMutableOutlineWithNormal(N3BezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, N3Vector projectionNormal);


CGFloat N3BezierCoreLengthToSegmentAtIndex(N3BezierCoreRef bezierCore, CFIndex index, CGFloat flatness); // the length up to and including the segment at index
CFIndex N3BezierCoreSegmentLengths(N3BezierCoreRef bezierCore, CGFloat *lengths, CFIndex numLengths, CGFloat flatness); // returns the number of lengths set

CFIndex N3BezierCoreCountIntersectionsWithPlane(N3BezierCoreRef bezierCore, N3Plane plane);
CFIndex N3BezierCoreIntersectionsWithPlane(N3BezierCoreRef bezierCore, N3Plane plane, N3VectorArray intersections, CGFloat *relativePositions, CFIndex numVectors);

N3MutableBezierCoreRef N3BezierCoreCreateMutableCopyWithEndpointsAtPlaneIntersections(N3BezierCoreRef bezierCore, N3Plane plane); // creates a N3BezierCore that is sure to have an endpoint every time the bezier core intersects the plane. If the input bezier is not already flattened, this routine will flatten it first

N3BezierCoreRef N3BezierCoreCreateCopyProjectedToPlane(N3BezierCoreRef bezierCore, N3Plane plane);
N3MutableBezierCoreRef N3BezierCoreCreateMutableCopyProjectedToPlane(N3BezierCoreRef bezierCore, N3Plane plane);

N3Plane N3BezierCoreLeastSquaresPlane(N3BezierCoreRef bezierCore);
CGFloat N3BezierCoreMeanDistanceToPlane(N3BezierCoreRef bezierCore, N3Plane plane);
bool N3BezierCoreIsPlanar(N3BezierCoreRef bezierCore, N3PlanePointer bezierCorePlane); // pass NULL for bezierCorePlane if you don't care

bool N3BezierCoreGetBoundingPlanesForNormal(N3BezierCoreRef bezierCore, N3Vector normal, N3PlanePointer topPlanePtr, N3PlanePointer bottomPlanePtr); // returns true on success

N3BezierCoreRef N3BezierCoreCreateCopyByReversing(N3BezierCoreRef bezierCore);
N3MutableBezierCoreRef N3BezierCoreCreateMutableCopyByReversing(N3BezierCoreRef bezierCore);

CFArrayRef N3BezierCoreCopySubpaths(N3BezierCoreRef bezierCore);
N3BezierCoreRef N3BezierCoreCreateCopyByClipping(N3BezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition);
N3MutableBezierCoreRef N3BezierCoreCreateMutableCopyByClipping(N3BezierCoreRef bezierCore, CGFloat startRelativePosition, CGFloat endRelativePosition);
CGFloat N3BezierCoreSignedAreaUsingNormal(N3BezierCoreRef bezierCore, N3Vector normal);

CF_EXTERN_C_END

#endif // _N3BEZIERCORE_ADDITIONS_H_