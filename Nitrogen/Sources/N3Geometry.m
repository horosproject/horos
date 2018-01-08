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

#include "N3Geometry.h"
#include <ApplicationServices/ApplicationServices.h>
#include <math.h>
#include <Accelerate/Accelerate.h>

static const CGFloat _N3GeometrySmallNumber = (CGFLOAT_MIN * 1E5);

const N3Vector N3VectorZero = {0.0, 0.0, 0.0};
const N3AffineTransform N3AffineTransformIdentity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
const N3Line N3LineXAxis = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const N3Line N3LineYAxis = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const N3Line N3LineZAxis = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const N3Line N3LineInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
const N3Plane N3PlaneXZero = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const N3Plane N3PlaneYZero = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const N3Plane N3PlaneZZero = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const N3Plane N3PlaneInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};

N3Vector N3VectorMake(CGFloat x, CGFloat y, CGFloat z)
{
    N3Vector vector;
    vector.x = x;
    vector.y = y;
    vector.z = z;
    return vector;
}

bool N3VectorEqualToVector(N3Vector vector1, N3Vector vector2)
{
    return vector1.x == vector2.x && vector1.y == vector2.y && vector1.z == vector2.z;
}

bool N3VectorIsCoincidentToVector(N3Vector vector1, N3Vector vector2)
{
    return N3VectorDistance(vector1, vector2) < _N3GeometrySmallNumber;
}

bool N3VectorIsZero(N3Vector vector)
{
    return N3VectorEqualToVector(vector, N3VectorZero);
}

N3Vector N3VectorAdd(N3Vector vector1, N3Vector vector2)
{
    N3Vector vector;
    vector.x = vector1.x + vector2.x;
    vector.y = vector1.y + vector2.y;
    vector.z = vector1.z + vector2.z;
    return vector;    
}

N3Vector N3VectorSubtract(N3Vector vector1, N3Vector vector2)
{
    N3Vector vector;
    vector.x = vector1.x - vector2.x;
    vector.y = vector1.y - vector2.y;
    vector.z = vector1.z - vector2.z;
    return vector;    
}

N3Vector N3VectorScalarMultiply(N3Vector vector, CGFloat scalar)
{
    N3Vector newVector;
    newVector.x = vector.x * scalar;
    newVector.y = vector.y * scalar;
    newVector.z = vector.z * scalar;
    return newVector;    
}

N3Vector N3VectorANormalVector(N3Vector vector) // returns a vector that is normal to the given vector
{
	N3Vector normal1;
	N3Vector normal2;
	N3Vector normal3;
	CGFloat length1;
	CGFloat length2;
	CGFloat length3;
	
	normal1 = N3VectorMake(-vector.y, vector.x, 0.0);
	normal2 = N3VectorMake(-vector.z, 0.0, vector.x);
	normal3 = N3VectorMake(0.0, -vector.z, vector.y);
	
	length1 = N3VectorLength(normal1);
	length2 = N3VectorLength(normal2);
	length3 = N3VectorLength(normal3);
	
	if (length1 > length2) {
		if (length1 > length3) {
			return N3VectorNormalize(normal1);
		} else {
			return N3VectorNormalize(normal3);
		}
	} else {
		if (length2 > length3) {
			return N3VectorNormalize(normal2);
		} else {
			return N3VectorNormalize(normal3);
		}
	}
}

CGFloat N3VectorDistance(N3Vector vector1, N3Vector vector2)
{
    return N3VectorLength(N3VectorSubtract(vector1, vector2));
}

CGFloat N3VectorDotProduct(N3Vector vector1, N3Vector vector2)
{
    return (vector1.x*vector2.x) + (vector1.y*vector2.y) + (vector1.z*vector2.z);
    
}

N3Vector N3VectorCrossProduct(N3Vector vector1, N3Vector vector2)
{
	N3Vector newVector;
	newVector.x = vector1.y*vector2.z - vector1.z*vector2.y;
	newVector.y = vector1.z*vector2.x - vector1.x*vector2.z;
	newVector.z = vector1.x*vector2.y - vector1.y*vector2.x;
	return newVector;
}

CGFloat N3VectorAngleBetweenVectorsAroundVector(N3Vector vector1, N3Vector vector2, N3Vector aroundVector) // returns [0, M_PI*2)
{
    N3Vector crossProduct;
    CGFloat angle;
    
    aroundVector = N3VectorNormalize(aroundVector);
    vector1 = N3VectorNormalize(N3VectorSubtract(N3VectorProject(vector1, aroundVector), vector1));
    vector2 = N3VectorNormalize(N3VectorSubtract(N3VectorProject(vector2, aroundVector), vector2));
    
    crossProduct = N3VectorCrossProduct(vector1, vector2);
    
#if CGFLOAT_IS_DOUBLE
    angle = asin(MIN(N3VectorLength(crossProduct), 1.0));
#else
    angle = asinf(MIN(N3VectorLength(crossProduct), 1.0f));
#endif
    
    if (N3VectorDotProduct(vector1, vector2) < 0.0) {
        angle = M_PI - angle;
    }
    
    if (N3VectorDotProduct(crossProduct, aroundVector) < 0.0) {
        angle = M_PI*2 - angle;
    }
    
    return angle;    
}

CGFloat N3VectorLength(N3Vector vector)
{
#if CGFLOAT_IS_DOUBLE
    return sqrt(N3VectorDotProduct(vector, vector));
#else
    return sqrtf(N3VectorDotProduct(vector, vector));
#endif
}

N3Vector N3VectorNormalize(N3Vector vector)
{
    CGFloat length;
    length = N3VectorLength(vector);
    if (length == 0.0) {
        return N3VectorZero;
    } else {
        return N3VectorScalarMultiply(vector, 1.0/length);
    }
}

N3Vector N3VectorProject(N3Vector vector1, N3Vector vector2) // project vector1 onto vector2
{
    CGFloat length;
    length = N3VectorLength(vector2);
    if (length != 0.0) {
        return N3VectorScalarMultiply(vector2, N3VectorDotProduct(vector1, vector2) / length);
    } else {
        return N3VectorZero;
    }

}

N3Vector N3VectorInvert(N3Vector vector)
{
    return N3VectorSubtract(N3VectorZero, vector);
}

N3Vector N3VectorApplyTransform(N3Vector vector, N3AffineTransform transform)
{
    N3Vector newVector;
    
    assert(N3AffineTransformIsAffine(transform));
    
    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31)+transform.m41;
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32)+transform.m42;
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33)+transform.m43;
    
    return newVector;
}

N3Vector N3VectorApplyTransformToDirectionalVector(N3Vector vector, N3AffineTransform transform)
{
    N3Vector newVector;
    
    assert(N3AffineTransformIsAffine(transform));
    
    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31);
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32);
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33);
    
    return newVector;
}

void N3VectorScalarMultiplyVectors(CGFloat scalar, N3VectorArray vectors, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vsmulD((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#else
    vDSP_vsmul((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#endif
}

void N3VectorCrossProductVectors(N3Vector vector, N3VectorArray vectors, CFIndex numVectors)
{
    CFIndex i;
    
    for (i = 0; i < numVectors; i++) {
        vectors[i] = N3VectorCrossProduct(vector, vectors[i]);
    }
}

void N3VectorAddVectors(N3VectorArray vectors1, const N3VectorArray vectors2, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vaddD((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#else
    vDSP_vadd((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#endif
}

void N3VectorApplyTransformToVectors(N3AffineTransform transform, N3VectorArray vectors, CFIndex numVectors)
{
    CGFloat *transformedVectors;
    CGFloat smallTransform[9];

    assert(N3AffineTransformIsAffine(transform));

    transformedVectors = malloc(numVectors * sizeof(CGFloat) * 3);
    smallTransform[0] = transform.m11;
    smallTransform[1] = transform.m12;
    smallTransform[2] = transform.m13;
    smallTransform[3] = transform.m21;
    smallTransform[4] = transform.m22;
    smallTransform[5] = transform.m23;
    smallTransform[6] = transform.m31;
    smallTransform[7] = transform.m32;
    smallTransform[8] = transform.m33;
    
#if CGFLOAT_IS_DOUBLE
    vDSP_mmulD((CGFloat *)vectors, 1, smallTransform, 1, (CGFloat *)transformedVectors, 1, numVectors, 3, 3);
    vDSP_vsaddD(transformedVectors, 3, &transform.m41, (CGFloat *)vectors, 3, numVectors);
    vDSP_vsaddD(transformedVectors + 1, 3, &transform.m42, ((CGFloat *)vectors) + 1, 3, numVectors);
    vDSP_vsaddD(transformedVectors + 2, 3, &transform.m43, ((CGFloat *)vectors) + 2, 3, numVectors);
#else
    vDSP_mmul((CGFloat *)vectors, 1, smallTransform, 1, (CGFloat *)transformedVectors, 1, numVectors, 3, 3);
    vDSP_vsadd(transformedVectors, 3, &transform.m41, (CGFloat *)vectors, 3, numVectors);
    vDSP_vsadd(transformedVectors + 1, 3, &transform.m42, ((CGFloat *)vectors) + 1, 3, numVectors);
    vDSP_vsadd(transformedVectors + 2, 3, &transform.m43, ((CGFloat *)vectors) + 2, 3, numVectors);
#endif
    
    free(transformedVectors);
}

void N3VectorCrossProductWithVectors(N3VectorArray vectors1, const N3VectorArray vectors2, CFIndex numVectors)
{
    CFIndex i;
    
    for (i = 0; i < numVectors; i++) {
        vectors1[i] = N3VectorCrossProduct(vectors1[i], vectors2[i]);
    }
}

void N3VectorNormalizeVectors(N3VectorArray vectors, CFIndex numVectors)
{
    CFIndex i;
    
    for (i = 0; i < numVectors; i++) {
        vectors[i] = N3VectorNormalize(vectors[i]);
    }
}

N3Vector N3VectorLerp(N3Vector vector1, N3Vector vector2, CGFloat t)
{
    return N3VectorAdd(N3VectorScalarMultiply(vector1, 1.0 - t), N3VectorScalarMultiply(vector2, t));
}

N3Vector N3VectorBend(N3Vector vectorToBend, N3Vector originalDirection, N3Vector newDirection) // this aught to be re-written to be more numerically stable!
{
    N3AffineTransform rotateTransform;
    N3Vector rotationAxis;
    N3Vector bentVector;
    CGFloat angle;
    
    rotationAxis = N3VectorCrossProduct(N3VectorNormalize(originalDirection), N3VectorNormalize(newDirection));
    
#if CGFLOAT_IS_DOUBLE
    angle = asin(MIN(N3VectorLength(rotationAxis), 1.0));
#else
    angle = asinf(MIN(N3VectorLength(rotationAxis), 1.0f));
#endif

    if (N3VectorDotProduct(originalDirection, newDirection) < 0.0) {
        angle = M_PI - angle;
    }
    
    rotateTransform = N3AffineTransformMakeRotationAroundVector(angle, rotationAxis);

    bentVector = N3VectorApplyTransform(vectorToBend, rotateTransform);
    return bentVector;
}

bool N3VectorIsOnLine(N3Vector vector, N3Line line)
{
    return N3VectorDistanceToLine(vector, line) < _N3GeometrySmallNumber;
}

bool N3VectorIsOnPlane(N3Vector vector, N3Plane plane)
{
    N3Vector planeNormal;
    planeNormal = N3VectorNormalize(plane.normal);
    return ABS(N3VectorDotProduct(planeNormal, N3VectorSubtract(vector, plane.point))) < _N3GeometrySmallNumber;
}

CGFloat N3VectorDistanceToLine(N3Vector vector, N3Line line)
{
    N3Vector translatedPoint;
    assert(N3LineIsValid(line));
    translatedPoint = N3VectorSubtract(vector, line.point);
    return N3VectorLength(N3VectorSubtract(translatedPoint, N3VectorProject(translatedPoint, line.vector)));
}

CGFloat N3VectorDistanceToPlane(N3Vector vector, N3Plane plane)
{
    return ABS(N3VectorDotProduct(N3VectorSubtract(vector, plane.point), N3VectorNormalize(plane.normal)));
}

N3Line N3LineMake(N3Vector point, N3Vector vector)
{
    N3Line line;
    line.point = point;
    line.vector = vector;
    assert(N3LineIsValid(line));
    return line;
}

N3Line N3LineMakeFromPoints(N3Vector point1, N3Vector point2)
{
    N3Line line;
    line.point = point1;
    line.vector = N3VectorNormalize(N3VectorSubtract(point2, point1));
    assert(N3LineIsValid(line));
    return line;
}

bool N3LineEqualToLine(N3Line line1, N3Line line2)
{
    return N3VectorEqualToVector(line1.point, line2.point) && N3VectorEqualToVector(line1.vector, line2.vector);
}

bool N3LineIsCoincidentToLine(N3Line line1, N3Line line2)
{
    if (N3LineIsParallelToLine(line1, line2) == false) {
        return false;
    }
    return N3VectorIsOnLine(line1.point, line2);
}

bool N3LineIsOnPlane(N3Line line, N3Plane plane)
{
    if (N3VectorIsOnPlane(line.point, plane) == false) {
        return false;
    }
    return ABS(N3VectorDotProduct(line.vector, plane.normal)) < _N3GeometrySmallNumber;
}

bool N3LineIsParallelToLine(N3Line line1, N3Line line2)
{
    if (N3VectorLength(N3VectorCrossProduct(line1.vector, line2.vector)) < _N3GeometrySmallNumber) {
        return true;
    }
    return false;
}

bool N3LineIsValid(N3Line line)
{
    return N3VectorLength(line.vector) > _N3GeometrySmallNumber;
}

bool N3LineIntersectsPlane(N3Line line, N3Plane plane)
{
    if (ABS(N3VectorDotProduct(plane.normal, line.vector)) < _N3GeometrySmallNumber) {
        if (N3VectorIsOnPlane(line.point, plane) == false) {
            return false;
        }
    }
    return true;
}

N3Vector N3LineIntersectionWithPlane(N3Line line, N3Plane plane)
{
	CGFloat numerator;
	CGFloat denominator;
    N3Vector planeNormal;
    N3Vector lineVector;
    
    planeNormal = N3VectorNormalize(plane.normal);
    lineVector = N3VectorNormalize(line.vector);
	
	numerator = N3VectorDotProduct(planeNormal, N3VectorSubtract(plane.point, line.point));
	denominator = N3VectorDotProduct(planeNormal, lineVector);
	
	if (ABS(denominator) < _N3GeometrySmallNumber) {
        if (numerator < 0.0) {
            return N3VectorAdd(line.point, N3VectorScalarMultiply(lineVector, -(CGFLOAT_MAX/1.0e10)));
        } else if (numerator > 0.0) {
            return N3VectorAdd(line.point, N3VectorScalarMultiply(lineVector, (CGFLOAT_MAX/1.0e10)));
        } else {
            return line.point;
        }
	}
	
	return N3VectorAdd(line.point, N3VectorScalarMultiply(lineVector, numerator/denominator));
}


N3Vector N3LinePointClosestToVector(N3Line line, N3Vector vector)
{
    return N3VectorAdd(N3VectorProject(N3VectorSubtract(vector, line.point), line.vector), line.point);
}

N3Line N3LineApplyTransform(N3Line line, N3AffineTransform transform)
{
    N3Line newLine;
    newLine.point = N3VectorApplyTransform(line.point, transform);
    newLine.vector = N3VectorNormalize(N3VectorApplyTransformToDirectionalVector(line.vector, transform));
    assert(N3LineIsValid(newLine));
    return newLine;
}

CGFloat N3LineClosestPoints(N3Line line1, N3Line line2, N3VectorPointer line1PointPtr, N3VectorPointer line2PointPtr) // given two lines, find points on each line that are the closest to each other, note that the line that goes through these two points will be normal to both lines
{ 
    N3Vector p13, p43, p21, p1, p3, pa, pb;
    CGFloat d1343, d4321, d1321, d4343, d2121;
    CGFloat numerator, denominator;
    CGFloat mua, mub;
    
    assert(N3LineIsValid(line1) && N3LineIsValid(line2));
    
    if (N3LineIsParallelToLine(line1, line2)) {
        pa = line1.point;
        pb = N3VectorAdd(line2.point, N3VectorProject(N3VectorSubtract(line2.point, line1.point), line2.vector));
        return N3VectorDistance(pa, pb);
    } else {
        p1 = line1.point;
        p3 = line2.point;
        
        p13 = N3VectorSubtract(p1, p3);
        p21 = line1.vector;
        p43 = line2.vector;
        
        d1343 = N3VectorDotProduct(p13, p43);
        d4321 = N3VectorDotProduct(p43, p21);
        d1321 = N3VectorDotProduct(p13, p21);
        d4343 = N3VectorDotProduct(p43, p43);
        d2121 = N3VectorDotProduct(p21, p21);    
        
        numerator = d1343*d4321 - d1321*d4343;
        denominator = d2121*d4343 - d4321*d4321;
        
		if (denominator == 0.0) { // as can happen if the lines were almost parallel
			pa = line1.point;
			pb = N3VectorAdd(line2.point, N3VectorProject(N3VectorSubtract(line2.point, line1.point), line2.vector));
			return N3VectorDistance(pa, pb);			
		}
        mua = numerator / denominator;
        assert(d4343); // this should never happen, otherwise the line2 would not be valid
        mub = (d1343 + d4321*mua) / d4343;
        
        pa = N3VectorAdd(p1, N3VectorScalarMultiply(p21, mua));
        pb = N3VectorAdd(p3, N3VectorScalarMultiply(p43, mub));
    }
    
    if (line1PointPtr) {
        *line1PointPtr = pa;
    }
    if (line2PointPtr) {
        *line2PointPtr = pb;
    }
    
    return N3VectorDistance(pa, pb);
}

N3Plane N3PlaneMake(N3Vector point, N3Vector normal)
{
	N3Plane plane;
	plane.point = point;
	plane.normal = normal;
	return plane;
}

bool N3PlaneEqualToPlane(N3Plane plane1, N3Plane plane2)
{
    return N3VectorEqualToVector(plane1.point, plane2.point) && N3VectorEqualToVector(plane1.normal, plane2.normal);
}

bool N3PlaneIsCoincidentToPlane(N3Plane plane1, N3Plane plane2)
{
    if (N3VectorLength(N3VectorCrossProduct(plane1.normal, plane2.normal)) > _N3GeometrySmallNumber) {
        return false;
    }
    return N3VectorIsOnPlane(plane1.point, plane2);
}

bool N3PlaneIsValid(N3Plane plane)
{
    return N3VectorLength(plane.normal) > _N3GeometrySmallNumber;
}

N3Plane N3PlaneLeastSquaresPlaneFromPoints(N3VectorArray vectors, CFIndex numVectors) // BOGUS TODO not written yet, will give a plane, but it won't be the least squares plane
{
    N3Plane plane;
    
    if (numVectors <= 3) {
        return N3PlaneInvalid;
    }
    
    plane.point = vectors[0];
    plane.normal = N3VectorNormalize(N3VectorCrossProduct(N3VectorSubtract(vectors[1], vectors[0]), N3VectorSubtract(vectors[2], vectors[0])));
    
    if (N3VectorIsZero(plane.normal)) {
        return N3PlaneInvalid;
    } else {
        return plane;
    }
}


N3Plane N3PlaneApplyTransform(N3Plane plane, N3AffineTransform transform)
{
    N3Plane newPlane;
	N3AffineTransform normalTransform;
	
    newPlane.point = N3VectorApplyTransform(plane.point, transform);
	normalTransform = transform;
	normalTransform.m41 = 0.0; normalTransform.m42 = 0.0; normalTransform.m43 = 0.0;
	
    newPlane.normal = N3VectorNormalize(N3VectorApplyTransform(plane.normal, N3AffineTransformTranspose(N3AffineTransformInvert(normalTransform))));
    assert(N3PlaneIsValid(newPlane));
    return newPlane;    
}

N3Vector N3PlanePointClosestToVector(N3Plane plane, N3Vector vector)
{
    N3Vector planeNormal;
    planeNormal = N3VectorNormalize(plane.normal);
    return N3VectorAdd(vector, N3VectorScalarMultiply(planeNormal, N3VectorDotProduct(planeNormal, N3VectorSubtract(plane.point, vector))));
}

bool N3PlaneIsParallelToPlane(N3Plane plane1, N3Plane plane2)
{
    return N3VectorLength(N3VectorCrossProduct(plane1.normal, plane2.normal)) <= _N3GeometrySmallNumber;
}

bool N3PlaneIsBetweenVectors(N3Plane plane, N3Vector vector1, N3Vector vector2)
{
    return N3VectorDotProduct(plane.normal, N3VectorSubtract(vector2, plane.point)) < 0.0 != N3VectorDotProduct(plane.normal, N3VectorSubtract(vector1, plane.point)) < 0.0;
}

N3Line N3PlaneIntersectionWithPlane(N3Plane plane1, N3Plane plane2)
{
    N3Line line;
    N3Line intersectionLine;
    
    line.vector = N3VectorNormalize(N3VectorCrossProduct(plane1.normal, plane2.normal));
    
    if (N3VectorIsZero(line.vector)) { // if the planes do not intersect, return halfway-reasonable BS
        line.vector = N3VectorNormalize(N3VectorCrossProduct(plane1.normal, N3VectorMake(1.0, 0.0, 0.0)));
        if (N3VectorIsZero(line.vector)) {
            line.vector = N3VectorNormalize(N3VectorCrossProduct(plane1.normal, N3VectorMake(0.0, 1.0, 0.0)));
        }
        line.point = plane1.point;
        return line;
    }
    
    intersectionLine.point = plane1.point;
    intersectionLine.vector = N3VectorNormalize(N3VectorSubtract(plane2.normal, N3VectorProject(plane2.normal, plane1.normal)));
    line.point = N3LineIntersectionWithPlane(intersectionLine, plane2);
    return line;
}


bool N3AffineTransformIsRectilinear(N3AffineTransform t) // this is not the right term, but what is a transform that only includes scale and translation called?
{
    return (                t.m12 == 0.0 && t.m13 == 0.0 && t.m14 == 0.0 &&
            t.m21 == 0.0 &&                 t.m23 == 0.0 && t.m24 == 0.0 &&
            t.m31 == 0.0 && t.m32 == 0.0 &&                 t.m34 == 0.0 &&
                                                            t.m44 == 1.0);
}

N3AffineTransform N3AffineTransformTranspose(N3AffineTransform t)
{
	N3AffineTransform transpose;

	transpose.m11 = t.m11; transpose.m12 = t.m21; transpose.m13 = t.m31; transpose.m14 = t.m41; 
	transpose.m21 = t.m12; transpose.m22 = t.m22; transpose.m23 = t.m32; transpose.m24 = t.m42; 
	transpose.m31 = t.m13; transpose.m32 = t.m23; transpose.m33 = t.m33; transpose.m34 = t.m43; 
	transpose.m41 = t.m14; transpose.m42 = t.m24; transpose.m43 = t.m34; transpose.m44 = t.m44;
	return transpose;
}

CGFloat N3AffineTransformDeterminant(N3AffineTransform t)
{
	assert(N3AffineTransformIsAffine(t));
	
	return t.m11*t.m22*t.m33 + t.m21*t.m32*t.m13 + t.m31*t.m12*t.m23 - t.m11*t.m32*t.m23 - t.m21*t.m12*t.m33 - t.m31*t.m22*t.m13;
}

N3AffineTransform N3AffineTransformInvert(N3AffineTransform t)
{
    BOOL isAffine;
    N3AffineTransform inverse;
    
    isAffine = N3AffineTransformIsAffine(t);
    inverse = CATransform3DInvert(t);
    
    if (isAffine) { // in some cases CATransform3DInvert returns a matrix that does not have exactly these values even if the input matrix did have these values
        inverse.m14 = 0.0;
        inverse.m24 = 0.0;
        inverse.m34 = 0.0;
        inverse.m44 = 1.0;
    }
    return inverse;
}

N3AffineTransform N3AffineTransformConcat(N3AffineTransform a, N3AffineTransform b)
{
    BOOL affine;
    N3AffineTransform concat;
    
    affine = N3AffineTransformIsAffine(a) && N3AffineTransformIsAffine(b);
    concat = CATransform3DConcat(a, b);
    
    if (affine) { // in some cases CATransform3DConcat returns a matrix that does not have exactly these values even if the input matrix did have these values
        concat.m14 = 0.0;
        concat.m24 = 0.0;
        concat.m34 = 0.0;
        concat.m44 = 1.0;
    }
    return concat;
}

NSString *NSStringFromN3AffineTransform(N3AffineTransform transform)
{
    return [NSString stringWithFormat:@"{{%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}}",
            transform.m11, transform.m12, transform.m13, transform.m14, transform.m21, transform.m22, transform.m23, transform.m24,
            transform.m31, transform.m32, transform.m33, transform.m34, transform.m41, transform.m42, transform.m43, transform.m44];
}

NSString *NSStringFromN3Vector(N3Vector vector)
{
	return [NSString stringWithFormat:@"{%f, %f, %f}", vector.x, vector.y, vector.z];
}

NSString *NSStringFromN3Line(N3Line line)
{
	return [NSString stringWithFormat:@"{%@, %@}", NSStringFromN3Vector(line.point), NSStringFromN3Vector(line.vector)];
}

NSString *NSStringFromN3Plane(N3Plane plane)
{
	return [NSString stringWithFormat:@"{%@, %@}", NSStringFromN3Vector(plane.point), NSStringFromN3Vector(plane.normal)];
}

CFDictionaryRef N3VectorCreateDictionaryRepresentation(N3Vector vector)
{
	CFDictionaryRef dict;
	CFStringRef keys[3];
	CFNumberRef numbers[3];
	
	keys[0] = CFSTR("x");
	keys[1] = CFSTR("y");
	keys[2] = CFSTR("z");
	
	numbers[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(vector.x));
	numbers[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(vector.y));
	numbers[2] = CFNumberCreate(kCFAllocatorDefault, kCFNumberCGFloatType, &(vector.z));
	
	dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)numbers, 3, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	CFRelease(numbers[0]);
	CFRelease(numbers[1]);
	CFRelease(numbers[2]);
	
	return dict;
}

CFDictionaryRef N3LineCreateDictionaryRepresentation(N3Line line)
{
	CFDictionaryRef pointDict;
	CFDictionaryRef vectorDict;
	CFDictionaryRef lineDict;
	
	pointDict = N3VectorCreateDictionaryRepresentation(line.point);
	vectorDict = N3VectorCreateDictionaryRepresentation(line.vector);
	lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)vectorDict, @"vector", nil];
	CFRelease(pointDict);
	CFRelease(vectorDict);
	return lineDict;
}

CFDictionaryRef N3PlaneCreateDictionaryRepresentation(N3Plane plane)
{
	CFDictionaryRef pointDict;
	CFDictionaryRef normalDict;
	CFDictionaryRef lineDict;
	
	pointDict = N3VectorCreateDictionaryRepresentation(plane.point);
	normalDict = N3VectorCreateDictionaryRepresentation(plane.normal);
	lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)normalDict, @"normal", nil];
	CFRelease(pointDict);
	CFRelease(normalDict);
	return lineDict;
}

bool N3VectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, N3Vector *vector)
{
	CFNumberRef x;
	CFNumberRef y;
	CFNumberRef z;
	N3Vector tempVector;
	
	if (dict == NULL) {
		return false;
	}
	
	x = CFDictionaryGetValue(dict, CFSTR("x"));
	y = CFDictionaryGetValue(dict, CFSTR("y"));
	z = CFDictionaryGetValue(dict, CFSTR("z"));
	
	if (x == NULL || CFGetTypeID(x) != CFNumberGetTypeID() ||
		y == NULL || CFGetTypeID(y) != CFNumberGetTypeID() ||
		z == NULL || CFGetTypeID(z) != CFNumberGetTypeID()) {
		return false;
	}
	
    CFNumberGetValue(x, kCFNumberCGFloatType, &(tempVector.x));
    CFNumberGetValue(y, kCFNumberCGFloatType, &(tempVector.y));
    CFNumberGetValue(z, kCFNumberCGFloatType, &(tempVector.z));
    
//	if (CFNumberGetValue(x, kCFNumberCGFloatType, &(tempVector.x)) == false) {
//		return false;    NO ! CFNumberGetValue can return false, if the value was saved in float 64 bit, and then converted to a lossy 32 bit : this situation happens if the path was created in an OsiriX 64-bit version, then loaded in OsiriX 32-bit
// If the argument type differs from the return type, and the conversion is lossy or the return value is out of range, then this function passes back an approximate value in valuePtr and returns false.
//	}
//	if (CFNumberGetValue(y, kCFNumberCGFloatType, &(tempVector.y)) == false) {
//		return false;
//	}
//	if (CFNumberGetValue(z, kCFNumberCGFloatType, &(tempVector.z)) == false) {
//		return false;
//	}
	
	if (vector) {
		*vector = tempVector;
	}
	
	return true;
}

bool N3LineMakeWithDictionaryRepresentation(CFDictionaryRef dict, N3Line *line)
{
	N3Line tempLine;
	CFDictionaryRef pointDict;
	CFDictionaryRef vectorDict;
	
	if (dict == NULL) {
		return false;
	}
	
	pointDict = CFDictionaryGetValue(dict, @"point");
	vectorDict = CFDictionaryGetValue(dict, @"vector");
	
	if (pointDict == NULL || CFGetTypeID(pointDict) != CFDictionaryGetTypeID() ||
		vectorDict == NULL || CFGetTypeID(vectorDict) != CFDictionaryGetTypeID()) {
		return false;
	}
	
	if (N3VectorMakeWithDictionaryRepresentation(pointDict, &(tempLine.point)) == false) {
		return false;
	}
	if (N3VectorMakeWithDictionaryRepresentation(vectorDict, &(tempLine.vector)) == false) {
		return false;
	}
	
	if (line) {
		*line = tempLine;
	}
	return true;
}

bool N3PlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, N3Plane *plane)
{
	N3Plane tempPlane;
	CFDictionaryRef pointDict;
	CFDictionaryRef normalDict;
	
	if (dict == NULL) {
		return false;
	}
	
	pointDict = CFDictionaryGetValue(dict, @"point");
	normalDict = CFDictionaryGetValue(dict, @"normal");
	
	if (pointDict == NULL || CFGetTypeID(pointDict) != CFDictionaryGetTypeID() ||
		normalDict == NULL || CFGetTypeID(normalDict) != CFDictionaryGetTypeID()) {
		return false;
	}
	
	if (N3VectorMakeWithDictionaryRepresentation(pointDict, &(tempPlane.point)) == false) {
		return false;
	}
	if (N3VectorMakeWithDictionaryRepresentation(normalDict, &(tempPlane.normal)) == false) {
		return false;
	}
	
	if (plane) {
		*plane = tempPlane;
	}
	return true;
}

// returns the real numbered roots of ax+b
CFIndex findRealLinearRoot(CGFloat a, CGFloat b, CGFloat *root) // returns the number of roots set
{
    assert(root);
    
    if (a == 0) {
        return 0;
    }
    
    *root = -b/a;
    return 1;
}

// returns the real numbered roots of ax^2+bx+c
CFIndex findRealQuadraticRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat *root1, CGFloat *root2) // returns the number of roots set
{
    CGFloat discriminant;
    CGFloat q;
    
    assert(root1);
    assert(root2);
    
    if (a == 0) {
        return findRealLinearRoot(b, c, root1);
    }
    
    discriminant = b*b - 4.0*a*c;
    
    if (discriminant < 0.0) {
        return 0;
    } else if (discriminant == 0) {
        *root1 = b / (a * -2.0);
        return 1;
    }
    
#if CGFLOAT_IS_DOUBLE
    if (b == 0) {
        *root1 = sqrt(c/a);
        *root2 = -*root1;
        return 2;
    }
    q = (b + copysign(sqrt(discriminant), b)) * 0.5;
#else
    if (b == 0) {
        *root1 = sqrtf(c/a);
        *root2 = *root1 * -1.0;
        return 2;
    }    
    q = (b + copysignf(sqrtf(discriminant), b)) * 0.5f;
#endif
    *root1 = q / a;
    *root2 = c / q;
    
    return 2;
}

// returns the real numbered roots of ax^3+bx^2+cx+d
CFIndex findRealCubicRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *root1, CGFloat *root2, CGFloat *root3) // returns the number of roots set 
{
    CGFloat Q;
    CGFloat R;
    CGFloat A;
    CGFloat B;
    CGFloat theta;
    CGFloat R2;
    CGFloat Q3;
    CGFloat sqrtQ_2;
    CGFloat b_3;
    
    if (a == 0) {
        return findRealQuadraticRoots(b, c, d, root1, root2);
    }
    
    b /= a;
    c /= a;
    d /= a;
    
    Q = (b*b - 3.0*c)/9.0;
    R = (2.0*b*b*b - 9.0*b*c + 27.0*d)/54.0;
    
    R2 = R*R;
    Q3 = Q*Q*Q;
    b_3 = b/3.0;
    
    if (R2 < Q3) {
#if CGFLOAT_IS_DOUBLE
        theta = acos(R/sqrt(Q3));
        sqrtQ_2 = -2.0*sqrt(Q);
        
        *root1 = sqrtQ_2*cos(theta/3.0)-b_3;
        *root2 = sqrtQ_2*cos((theta + 2.0*M_PI)/3.0)-b_3;
        if (theta == 0.0) {
            return 2;
        } else {
            *root3 = sqrtQ_2*cos((theta - 2.0*M_PI)/3.0)-b_3;
            return 3;
        }
#else
        theta = acosf(R/sqrtf(Q3));
        sqrtQ_2 = -2.0*sqrtf(Q);
        
        *root1 = sqrtQ_2*cosf(theta/3.0)-b_3;
        *root2 = sqrtQ_2*cosf((theta + 2.0*M_PI)/3.0)-b_3;
        if (theta == 0.0) {
            return 2;
        } else {
            *root3 = sqrtQ_2*cosf((theta - 2.0*M_PI)/3.0)-b_3;
            return 3;
        }
#endif
        return 3;
    }

#if CGFLOAT_IS_DOUBLE
    A = -1.0*copysign(pow(fabs(R)+sqrt(R2-Q3), 1.0/3.0), R);
#else
    A = -1.0*copysignf(powf(fabsf(R)+sqrtf(R2-Q3), 1.0/3.0), R);
#endif
    if (A == 0) {
        B = 0;
    } else {
        B = Q/A;
    }
    
    *root1 = (A+B)-b_3;
    return 1;
}

void N3AffineTransformGetOpenGLMatrixd(N3AffineTransform transform, double *d) // d better be 16 elements long
{
    d[0] =  transform.m11; d[1] =  transform.m12; d[2] =  transform.m13; d[3] =  transform.m14; 
    d[4] =  transform.m21; d[5] =  transform.m22; d[6] =  transform.m23; d[7] =  transform.m24; 
    d[8] =  transform.m31; d[9] =  transform.m32; d[10] = transform.m33; d[11] = transform.m34; 
    d[12] = transform.m41; d[13] = transform.m42; d[14] = transform.m43; d[15] = transform.m44; 
}

void N3AffineTransformGetOpenGLMatrixf(N3AffineTransform transform, float *f) // f better be 16 elements long
{
    f[0] =  transform.m11; f[1] =  transform.m12; f[2] =  transform.m13; f[3] =  transform.m14; 
    f[4] =  transform.m21; f[5] =  transform.m22; f[6] =  transform.m23; f[7] =  transform.m24; 
    f[8] =  transform.m31; f[9] =  transform.m32; f[10] = transform.m33; f[11] = transform.m34; 
    f[12] = transform.m41; f[13] = transform.m42; f[14] = transform.m43; f[15] = transform.m44;     
}

N3AffineTransform N3AffineTransformMakeFromOpenGLMatrixd(double *d) // d better be 16 elements long
{
    N3AffineTransform transform;
    transform.m11 = d[0];  transform.m12 = d[1];  transform.m13 = d[2];  transform.m14 = d[3];
    transform.m21 = d[4];  transform.m22 = d[5];  transform.m23 = d[6];  transform.m24 = d[7];
    transform.m31 = d[8];  transform.m32 = d[9];  transform.m33 = d[10]; transform.m34 = d[11];
    transform.m41 = d[12]; transform.m42 = d[13]; transform.m43 = d[14]; transform.m44 = d[15];
    return transform;
}

N3AffineTransform N3AffineTransformMakeFromOpenGLMatrixf(float *f) // f better be 16 elements long
{
    N3AffineTransform transform;
    transform.m11 = f[0];  transform.m12 = f[1];  transform.m13 = f[2];  transform.m14 = f[3];
    transform.m21 = f[4];  transform.m22 = f[5];  transform.m23 = f[6];  transform.m24 = f[7];
    transform.m31 = f[8];  transform.m32 = f[9];  transform.m33 = f[10]; transform.m34 = f[11];
    transform.m41 = f[12]; transform.m42 = f[13]; transform.m43 = f[14]; transform.m44 = f[15];
    return transform;
}

@implementation NSValue (N3GeometryAdditions)

+ (NSValue *)valueWithN3Vector:(N3Vector)vector
{
    return [NSValue valueWithBytes:&vector objCType:@encode(N3Vector)];
}

- (N3Vector)N3VectorValue
{
    N3Vector vector;
    assert(strcmp([self objCType], @encode(N3Vector)) == 0);
    [self getValue:&vector];
    return vector;
}

+ (NSValue *)valueWithN3Line:(N3Line)line
{
    return [NSValue valueWithBytes:&line objCType:@encode(N3Line)];
}

- (N3Line)N3LineValue
{
	N3Line line;
    assert(strcmp([self objCType], @encode(N3Line)) == 0);
    [self getValue:&line];
    return line;
}	

+ (NSValue *)valueWithN3Plane:(N3Plane)plane
{
	return [NSValue valueWithBytes:&plane objCType:@encode(N3Plane)];

}

- (N3Plane)N3PlaneValue
{
	N3Plane plane;
    assert(strcmp([self objCType], @encode(N3Plane)) == 0);
    [self getValue:&plane];
    return plane;
}	

+ (NSValue *)valueWithN3AffineTransform:(N3AffineTransform)transform
{
    return [NSValue valueWithBytes:&transform objCType:@encode(N3AffineTransform)];
}

- (N3AffineTransform)N3AffineTransformValue
{
    N3AffineTransform transform;
    assert(strcmp([self objCType], @encode(N3AffineTransform)) == 0);
    [self getValue:&transform];
    return transform;
}

@end











