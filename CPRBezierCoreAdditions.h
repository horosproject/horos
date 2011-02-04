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

#ifndef _CPRBEZIERCORE_ADDITIONS_H_
#define _CPRBEZIERCORE_ADDITIONS_H_

#include "CPRBezierCore.h"

// CPRBezierCore functions that don't need any access to the actual implementation details of the CPRBezierCore

CG_EXTERN_C_BEGIN

CPRBezierCoreRef CPRBezierCoreCreateCurveWithNodes(CPRVectorArray vectors, CFIndex numVectors);
CPRMutableBezierCoreRef CPRBezierCoreCreateMutableCurveWithNodes(CPRVectorArray vectors, CFIndex numVectors);

CPRVector CPRBezierCoreVectorAtStart(CPRBezierCoreRef bezierCore);
CPRVector CPRBezierCoreVectorAtEnd(CPRBezierCoreRef bezierCore);

CPRVector CPRBezierCoreTangentAtStart(CPRBezierCoreRef bezierCore);
CPRVector CPRBezierCoreTangentAtEnd(CPRBezierCoreRef bezierCore);
CPRVector CPRBezierCoreNormalAtEndWithInitialNormal(CPRBezierCoreRef bezierCore, CPRVector initialNormal);

CGFloat CPRBezierCoreRelativePositionClosestToVector(CPRBezierCoreRef bezierCore, CPRVector vector, CPRVectorPointer closestVector, CGFloat *distance); // a relative position is a value between [0, 1]
CGFloat CPRBezierCoreRelativePositionClosestToLine(CPRBezierCoreRef bezierCore, CPRLine line, CPRVectorPointer closestVector, CGFloat *distance);

CFIndex CPRBezierCoreGetVectorInfo(CPRBezierCoreRef bezierCore, CGFloat spacing, CGFloat startingPoint, CPRVector initialNormal,  // returns evenly spaced vectors, tangents and normals starting at startingPoint
                                              CPRVectorArray vectors, CPRVectorArray tangents, CPRVectorArray normals, CFIndex numVectors); // fills numVectors in the vector arrays, returns the actual number of vectors that were set in the arrays

CPRBezierCoreRef CPRBezierCoreCreateOutline(CPRBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, CPRVector initialNormal); // distance from the center, spacing is the distance between ponts on the curve that are sampled to generate the outline
CPRMutableBezierCoreRef CPRBezierCoreCreateMutableOutline(CPRBezierCoreRef bezierCore, CGFloat distance, CGFloat spacing, CPRVector initialNormal);

CGFloat CPRBezierCoreLengthToSegmentAtIndex(CPRBezierCoreRef bezierCore, CFIndex index, CGFloat flatness); // the length up to and including the segment at index
CFIndex CPRBezierCoreSegmentLengths(CPRBezierCoreRef bezierCore, CGFloat *lengths, CFIndex numLengths, CGFloat flatness); // returns the number of lengths set

CFIndex CPRBezierCoreCountIntersectionsWithPlane(CPRBezierCoreRef bezierCore, CPRPlane plane);
CFIndex CPRBezierCoreIntersectionsWithPlane(CPRBezierCoreRef bezierCore, CPRPlane plane, CPRVectorArray intersections, CGFloat *relativePositions, CFIndex numVectors);

CFDictionaryRef CPRBezierCoreCreateDictionaryRepresentation(CPRBezierCoreRef bezierCore);
CPRBezierCoreRef CPRBezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict);
CPRMutableBezierCoreRef CPRBezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict);

CG_EXTERN_C_END

#endif // _CPRBEZIERCORE_ADDITIONS_H_