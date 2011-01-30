/*
 *  CPRGeometry.c
 *  OsiriX
 *
 *  Created by Joël Spaltenstein on 9/26/10.
 *  Copyright 2010 OsiriX Team. All rights reserved.
 *
 */

#include "CPRGeometry.h"
#include <ApplicationServices/ApplicationServices.h>
#include <math.h>
#include <Accelerate/Accelerate.h>

#define _CPRGeometrySmallNumber (CGFLOAT_MIN * 1E5)

const CPRVector CPRVectorZero = {0.0, 0.0, 0.0};
const CPRAffineTransform3D CPRAffineTransform3DIdentity = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
const CPRLine CPRLineXAxis = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const CPRLine CPRLineYAxis = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const CPRLine CPRLineZAxis = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const CPRLine CPRLineInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
const CPRPlane CPRPlaneXZero = {{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}};
const CPRPlane CPRPlaneYZero = {{0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}};
const CPRPlane CPRPlaneZZero = {{0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}};
const CPRPlane CPRPlaneInvalid = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};

CPRVector CPRVectorMake(CGFloat x, CGFloat y, CGFloat z)
{
    CPRVector vector;
    vector.x = x,
    vector.y = y;
    vector.z = z;
    return vector;
}

bool CPRVectorEqualToVector(CPRVector vector1, CPRVector vector2)
{
    return vector1.x == vector2.x && vector1.y == vector2.y && vector1.z == vector2.z;
}

bool CPRVectorIsCoincidentToVector(CPRVector vector1, CPRVector vector2)
{
    return CPRVectorDistance(vector1, vector2) < _CPRGeometrySmallNumber;
}

bool CPRVectorIsZero(CPRVector vector)
{
    return CPRVectorEqualToVector(vector, CPRVectorZero);
}

CPRVector CPRVectorAdd(CPRVector vector1, CPRVector vector2)
{
    CPRVector vector;
    vector.x = vector1.x + vector2.x;
    vector.y = vector1.y + vector2.y;
    vector.z = vector1.z + vector2.z;
    return vector;    
}

CPRVector CPRVectorSubtract(CPRVector vector1, CPRVector vector2)
{
    CPRVector vector;
    vector.x = vector1.x - vector2.x;
    vector.y = vector1.y - vector2.y;
    vector.z = vector1.z - vector2.z;
    return vector;    
}

CPRVector CPRVectorScalarMultiply(CPRVector vector, CGFloat scalar)
{
    CPRVector newVector;
    newVector.x = vector.x * scalar;
    newVector.y = vector.y * scalar;
    newVector.z = vector.z * scalar;
    return newVector;    
}

CGFloat CPRVectorDistance(CPRVector vector1, CPRVector vector2)
{
    return CPRVectorLength(CPRVectorSubtract(vector1, vector2));
}

CGFloat CPRVectorDotProduct(CPRVector vector1, CPRVector vector2)
{
    return (vector1.x*vector2.x) + (vector1.y*vector2.y) + (vector1.z*vector2.z);
    
}

CPRVector CPRVectorCrossProduct(CPRVector vector1, CPRVector vector2)
{
	CPRVector newVector;
	newVector.x = vector1.y*vector2.z - vector1.z*vector2.y;
	newVector.y = vector1.z*vector2.x - vector1.x*vector2.z;
	newVector.z = vector1.x*vector2.y - vector1.y*vector2.x;
	return newVector;
}

CGFloat CPRVectorAngleBetweenVectorsAroundVector(CPRVector vector1, CPRVector vector2, CPRVector aroundVector) // returns [0, M_PI*2)
{
    CPRVector crossProduct;
    CGFloat angle;
    
    aroundVector = CPRVectorNormalize(aroundVector);
    vector1 = CPRVectorNormalize(CPRVectorSubtract(CPRVectorProject(vector1, aroundVector), vector1));
    vector2 = CPRVectorNormalize(CPRVectorSubtract(CPRVectorProject(vector2, aroundVector), vector2));
    
    crossProduct = CPRVectorCrossProduct(vector1, vector2);
    
#if CGFLOAT_IS_DOUBLE
    angle = asin(MIN(CPRVectorLength(crossProduct), 1.0));
#else
    angle = asinf(MIN(CPRVectorLength(crossProduct), 1.0f));
#endif
    
    if (CPRVectorDotProduct(vector1, vector2) < 0.0) {
        angle = M_PI - angle;
    }
    
    if (CPRVectorDotProduct(crossProduct, aroundVector) < 0.0) {
        angle = M_PI*2 - angle;
    }
    
    return angle;    
}

CGFloat CPRVectorLength(CPRVector vector)
{
#if CGFLOAT_IS_DOUBLE
    return sqrt(CPRVectorDotProduct(vector, vector));
#else
    return sqrtf(CPRVectorDotProduct(vector, vector));
#endif
}

CPRVector CPRVectorNormalize(CPRVector vector)
{
    CGFloat length;
    length = CPRVectorLength(vector);
    if (length == 0.0) {
        return CPRVectorZero;
    } else {
        return CPRVectorScalarMultiply(vector, 1.0/length);
    }
}

CPRVector CPRVectorProject(CPRVector vector1, CPRVector vector2) // project vector1 onto vector2
{
    CGFloat length;
    length = CPRVectorLength(vector2);
    if (length != 0.0) {
        return CPRVectorScalarMultiply(vector2, CPRVectorDotProduct(vector1, vector2) / length);
    } else {
        return CPRVectorZero;
    }

}

CPRVector CPRVectorInvert(CPRVector vector)
{
    return CPRVectorSubtract(CPRVectorZero, vector);
}

CPRVector CPRVectorApplyTransform(CPRVector vector, CPRAffineTransform3D transform)
{
    CPRVector newVector;
    
    assert(CPRAffineTransform3DIsAffine(transform));
    
    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31)+transform.m41;
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32)+transform.m42;
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33)+transform.m43;
    
    return newVector;
}

CPRVector CPRVectorApplyTransformToDirectionalVector(CPRVector vector, CPRAffineTransform3D transform)
{
    CPRVector newVector;
    
    assert(CPRAffineTransform3DIsAffine(transform));
    
    newVector.x = (vector.x*transform.m11)+(vector.y*transform.m21)+(vector.z*transform.m31);
    newVector.y = (vector.x*transform.m12)+(vector.y*transform.m22)+(vector.z*transform.m32);
    newVector.z = (vector.x*transform.m13)+(vector.y*transform.m23)+(vector.z*transform.m33);
    
    return newVector;
}

void CPRVectorScalarMultiplyVectors(CGFloat scalar, CPRVectorArray vectors, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vsmulD((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#else
    vDSP_vsmul((CGFloat *)vectors, 1, &scalar, (CGFloat *)vectors, 1, numVectors*3);
#endif
}

void CPRVectorAddVectors(CPRVectorArray vectors1, const CPRVectorArray vectors2, CFIndex numVectors)
{
#if CGFLOAT_IS_DOUBLE
    vDSP_vaddD((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#else
    vDSP_vadd((CGFloat *)vectors1, 1, (CGFloat *)vectors2, 1, (CGFloat *)vectors1, 1, numVectors*3);
#endif
}

void CPRVectorApplyTransformToVectors(CPRAffineTransform3D transform, CPRVectorArray vectors, CFIndex numVectors)
{
    CGFloat *transformedVectors;
    CGFloat smallTransform[9];

    assert(CPRAffineTransform3DIsAffine(transform));

    transformedVectors = malloc(numVectors * sizeof(CPRVector));
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

void CPRVectorCrossProductWithVectors(CPRVectorArray vectors1, const CPRVectorArray vectors2, CFIndex numVectors)
{
    CFIndex i;
    
    for (i = 0; i < numVectors; i++) {
        vectors1[i] = CPRVectorCrossProduct(vectors1[i], vectors2[i]);
    }
}

CPRVector CPRVectorBend(CPRVector vectorToBend, CPRVector originalDirection, CPRVector newDirection) // this aught to be re-written to be more numerically stable!
{
    CPRAffineTransform3D rotateTransform;
    CPRVector rotationAxis;
    CPRVector bentVector;
    CGFloat angle;
    
    rotationAxis = CPRVectorCrossProduct(CPRVectorNormalize(originalDirection), CPRVectorNormalize(newDirection));
    
#if CGFLOAT_IS_DOUBLE
    angle = asin(MIN(CPRVectorLength(rotationAxis), 1.0));
#else
    angle = asinf(MIN(CPRVectorLength(rotationAxis), 1.0f));
#endif

    if (CPRVectorDotProduct(originalDirection, newDirection) < 0.0) {
        angle = M_PI - angle;
    }
    
    rotateTransform = CPRAffineTransform3DMakeRotationAroundVector(angle, rotationAxis);

    bentVector = CPRVectorApplyTransform(vectorToBend, rotateTransform);
    return bentVector;
}

bool CPRVectorIsOnLine(CPRVector vector, CPRLine line)
{
    return CPRVectorDistanceToLine(vector, line) < _CPRGeometrySmallNumber;
}

bool CPRVectorIsOnPlane(CPRVector vector, CPRPlane plane)
{
    CPRVector planeNormal;
    planeNormal = CPRVectorNormalize(plane.normal);
    return CPRVectorDotProduct(planeNormal, CPRVectorSubtract(vector, plane.point)) < _CPRGeometrySmallNumber;
}

CGFloat CPRVectorDistanceToLine(CPRVector vector, CPRLine line)
{
    CPRVector translatedPoint;
    assert(CPRLineIsValid(line));
    translatedPoint = CPRVectorSubtract(vector, line.point);
    return CPRVectorLength(CPRVectorSubtract(translatedPoint, CPRVectorProject(translatedPoint, line.vector)));
}

CPRLine CPRLineMake(CPRVector point, CPRVector vector)
{
    CPRLine line;
    line.point = point;
    line.vector = vector;
    assert(CPRLineIsValid(line));
    return line;
}

CPRLine CPRLineMakeFromPoints(CPRVector point1, CPRVector point2)
{
    CPRLine line;
    line.point = point1;
    line.vector = CPRVectorNormalize(CPRVectorSubtract(point2, point1));
    assert(CPRLineIsValid(line));
    return line;
}

bool CPRLineEqualToLine(CPRLine line1, CPRLine line2)
{
    return CPRVectorEqualToVector(line1.point, line2.point) && CPRVectorEqualToVector(line1.vector, line2.vector);
}

bool CPRLineIsCoincidentToLine(CPRLine line1, CPRLine line2)
{
    if (CPRLineIsParallelToLine(line1, line2) == false) {
        return false;
    }
    return CPRVectorIsOnLine(line1.point, line2);
}

bool CPRLineIsOnPlane(CPRLine line, CPRPlane plane)
{
    if (CPRVectorIsOnPlane(line.point, plane) == false) {
        return false;
    }
    return CPRVectorDotProduct(line.vector, plane.normal) < _CPRGeometrySmallNumber;
}

bool CPRLineIsParallelToLine(CPRLine line1, CPRLine line2)
{
    if (CPRVectorLength(CPRVectorCrossProduct(line1.vector, line2.vector)) < _CPRGeometrySmallNumber) {
        return true;
    }
    return false;
}

bool CPRLineIsValid(CPRLine line)
{
    return CPRVectorLength(line.vector) > _CPRGeometrySmallNumber;
}

bool CPRLineIntersectsPlane(CPRLine line, CPRPlane plane)
{
    if (CPRVectorDotProduct(plane.normal, line.vector) < _CPRGeometrySmallNumber) {
        if (CPRVectorIsOnPlane(line.point, plane) == false) {
            return false;
        }
    }
    return true;
}

CPRVector CPRLineIntersectionWithPlane(CPRLine line, CPRPlane plane)
{
	CGFloat u;
	CGFloat numerator;
	CGFloat denominator;
    CPRVector planeNormal;
    CPRVector lineVector;
    
    planeNormal = CPRVectorNormalize(plane.normal);
    lineVector = CPRVectorNormalize(line.vector);
	
	numerator = CPRVectorDotProduct(planeNormal, CPRVectorSubtract(plane.point, line.point));
	denominator = CPRVectorDotProduct(planeNormal, lineVector);
	
	if (ABS(denominator) < _CPRGeometrySmallNumber) {
        if (numerator < 0.0) {
            return CPRVectorAdd(line.point, CPRVectorScalarMultiply(lineVector, -(CGFLOAT_MAX/1.0e10)));
        } else if (numerator > 0.0) {
            return CPRVectorAdd(line.point, CPRVectorScalarMultiply(lineVector, (CGFLOAT_MAX/1.0e10)));
        } else {
            return line.point;
        }
	}
	
	return CPRVectorAdd(line.point, CPRVectorScalarMultiply(lineVector, numerator/denominator));
}


CPRVector CPRLinePointClosestToVector(CPRLine line, CPRVector vector)
{
    return CPRVectorAdd(CPRVectorProject(CPRVectorSubtract(vector, line.point), line.vector), line.point);
}

CPRLine CPRLineApplyTransform(CPRLine line, CPRAffineTransform3D transform)
{
    CPRLine newLine;
    newLine.point = CPRVectorApplyTransform(line.point, transform);
    newLine.vector = CPRVectorNormalize(CPRVectorApplyTransformToDirectionalVector(line.vector, transform));
    assert(CPRLineIsValid(newLine));
    return newLine;
}

CGFloat CPRLineClosestPoints(CPRLine line1, CPRLine line2, CPRVectorPointer line1PointPtr, CPRVectorPointer line2PointPtr) // given two lines, find points on each line that are the closest to each other, note that the line the goes through these two points will be normal to both lines
{ 
    CPRVector p13, p43, p21, p1, p3, pa, pb;
    CGFloat d1343, d4321, d1321, d4343, d2121;
    CGFloat numerator, denominator;
    CGFloat mua, mub;
    
    assert(CPRLineIsValid(line1) && CPRLineIsValid(line2));
    
    if (CPRLineIsParallelToLine(line1, line2)) {
        pa = line1.point;
        pb = CPRVectorAdd(line2.point, CPRVectorProject(CPRVectorSubtract(line2.point, line1.point), line2.vector));
        return CPRVectorDistance(pa, pb);
    } else {
        p1 = line1.point;
        p3 = line2.point;
        
        p13 = CPRVectorSubtract(p1, p3);
        p21 = line1.vector;
        p43 = line2.vector;
        
        d1343 = CPRVectorDotProduct(p13, p43);
        d4321 = CPRVectorDotProduct(p43, p21);
        d1321 = CPRVectorDotProduct(p13, p21);
        d4343 = CPRVectorDotProduct(p43, p43);
        d2121 = CPRVectorDotProduct(p21, p21);    
        
        numerator = d1343*d4321 - d1321*d4343;
        denominator = d2121*d4343 - d4321*d4321;
        
		if (denominator == 0.0) { // as can happen if the lines were almost parallel
			pa = line1.point;
			pb = CPRVectorAdd(line2.point, CPRVectorProject(CPRVectorSubtract(line2.point, line1.point), line2.vector));
			return CPRVectorDistance(pa, pb);			
		}
        mua = numerator / denominator;
        assert(d4343); // this should never happen, otherwise the line2 would not be valid
        mub = (d1343 + d4321*mua) / d4343;
        
        pa = CPRVectorAdd(p1, CPRVectorScalarMultiply(p21, mua));
        pb = CPRVectorAdd(p3, CPRVectorScalarMultiply(p43, mub));
    }
    
    if (line1PointPtr) {
        *line1PointPtr = pa;
    }
    if (line2PointPtr) {
        *line2PointPtr = pb;
    }
    
    return CPRVectorDistance(pa, pb);
}

CPRPlane CPRPlaneMake(CPRVector point, CPRVector normal)
{
	CPRPlane plane;
	plane.point = point;
	plane.normal = normal;
	return plane;
}

bool CPRPlaneEqualToPlane(CPRPlane plane1, CPRPlane plane2)
{
    return CPRVectorEqualToVector(plane1.point, plane2.point) && CPRVectorEqualToVector(plane1.normal, plane2.normal);
}

bool CPRPlaneIsCoincidentToPlane(CPRPlane plane1, CPRPlane plane2)
{
    if (CPRVectorLength(CPRVectorCrossProduct(plane1.normal, plane2.normal)) < _CPRGeometrySmallNumber) {
        return false;
    }
    return CPRVectorIsOnPlane(plane1.point, plane2);
}

bool CPRPlaneIsValid(CPRPlane plane)
{
    return CPRVectorLength(plane.normal) > _CPRGeometrySmallNumber;
}

CPRPlane CPRPlaneApplyTransform(CPRPlane plane, CPRAffineTransform3D transform)
{
    CPRPlane newPlane;
    newPlane.point = CPRVectorApplyTransform(plane.point, transform);
    newPlane.normal = CPRVectorNormalize(CPRVectorApplyTransformToDirectionalVector(plane.normal, transform));
    assert(CPRPlaneIsValid(newPlane));
    return newPlane;    
}

CPRVector CPRPlanePointClosestToVector(CPRPlane plane, CPRVector vector)
{
    CPRVector planeNormal;
    planeNormal = CPRVectorNormalize(plane.normal);
    return CPRVectorAdd(vector, CPRVectorScalarMultiply(planeNormal, CPRVectorDotProduct(planeNormal, CPRVectorSubtract(plane.point, vector))));
}

bool CPRPlaneInterectsPlane(CPRPlane plane1, CPRPlane plane2)
{
    return CPRVectorLength(CPRVectorCrossProduct(plane1.normal, plane2.normal)) >= _CPRGeometrySmallNumber;
}

bool CPRPlaneIsBetweenVectors(CPRPlane plane, CPRVector vector1, CPRVector vector2)
{
    return CPRVectorDotProduct(plane.normal, CPRVectorSubtract(vector2, plane.point)) < 0.0 != CPRVectorDotProduct(plane.normal, CPRVectorSubtract(vector1, plane.point)) < 0.0;
}

CPRLine CPRPlaneIntersectionWithPlane(CPRPlane plane1, CPRPlane plane2)
{
    CPRLine line;
    CPRLine intersectionLine;
    
    line.vector = CPRVectorNormalize(CPRVectorCrossProduct(plane1.normal, plane2.normal));
    
    if (CPRVectorIsZero(line.vector)) { // if the planes do not intersect, return halfway-reasonable BS
        line.vector = CPRVectorNormalize(CPRVectorCrossProduct(plane1.normal, CPRVectorMake(1.0, 0.0, 0.0)));
        if (CPRVectorIsZero(line.vector)) {
            line.vector = CPRVectorNormalize(CPRVectorCrossProduct(plane1.normal, CPRVectorMake(0.0, 1.0, 0.0)));
        }
        line.point = plane1.point;
        return line;
    }
    
    intersectionLine.point = plane1.point;
    intersectionLine.vector = CPRVectorNormalize(CPRVectorSubtract(plane2.normal, CPRVectorProject(plane2.normal, plane1.normal)));
    line.point = CPRLineIntersectionWithPlane(intersectionLine, plane2);
    return line;
}


bool CPRAffineTransform3DIsRectilinear(CPRAffineTransform3D t) // this is not the right term, but what is a transform that only includes scale and translation called?
{
    return (                t.m12 == 0.0 && t.m13 == 0.0 && t.m14 == 0.0 &&
            t.m21 == 0.0 &&                 t.m23 == 0.0 && t.m24 == 0.0 &&
            t.m31 == 0.0 && t.m32 == 0.0 &&                 t.m34 == 0.0 &&
                                                            t.m44 == 1.0);
}

NSString *NSStringFromCPRAffineTransform3D(CPRAffineTransform3D transform)
{
    return [NSString stringWithFormat:@"{{%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}\n {%8.2f, %8.2f, %8.2f, %8.2f}}",
            transform.m11, transform.m12, transform.m13, transform.m14, transform.m21, transform.m22, transform.m23, transform.m24,
            transform.m31, transform.m32, transform.m33, transform.m34, transform.m41, transform.m42, transform.m43, transform.m44];
}

NSString *NSStringFromCPRVector(CPRVector vector)
{
	return [NSString stringWithFormat:@"{%f, %f, %f}", vector.x, vector.y, vector.z];
}

NSString *NSStringFromCPRLine(CPRLine line)
{
	return [NSString stringWithFormat:@"{%@, %@}", NSStringFromCPRVector(line.point), NSStringFromCPRVector(line.vector)];
}

NSString *NSStringFromCPRPlane(CPRPlane plane)
{
	return [NSString stringWithFormat:@"{%@, %@}", NSStringFromCPRVector(plane.point), NSStringFromCPRVector(plane.normal)];
}

CFDictionaryRef CPRVectorCreateDictionaryRepresentation(CPRVector vector)
{
	CFDictionaryRef dict;
	CFStringRef keys[3];
	CFNumberRef numbers[3];
	CFNumberType numberType;
	
	keys[0] = (CFStringRef)@"x";
	keys[1] = (CFStringRef)@"y";
	keys[2] = (CFStringRef)@"z";
	
#if CGFLOAT_IS_DOUBLE
	numberType = kCFNumberDoubleType;
#else
	numberType = kCFNumberFloatType;
#endif
	
	numbers[0] = CFNumberCreate(kCFAllocatorDefault, numberType, &(vector.x));
	numbers[1] = CFNumberCreate(kCFAllocatorDefault, numberType, &(vector.y));
	numbers[2] = CFNumberCreate(kCFAllocatorDefault, numberType, &(vector.z));
	
	dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)numbers, 3, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	CFRelease(numbers[0]);
	CFRelease(numbers[1]);
	CFRelease(numbers[2]);
	
	return dict;
}

CFDictionaryRef CPRLineCreateDictionaryRepresentation(CPRLine line)
{
	CFDictionaryRef pointDict;
	CFDictionaryRef vectorDict;
	CFDictionaryRef lineDict;
	
	pointDict = CPRVectorCreateDictionaryRepresentation(line.point);
	vectorDict = CPRVectorCreateDictionaryRepresentation(line.vector);
	lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)vectorDict, @"vector", nil];
	CFRelease(pointDict);
	CFRelease(vectorDict);
	return lineDict;
}

CFDictionaryRef CPRPlaneCreateDictionaryRepresentation(CPRPlane plane)
{
	CFDictionaryRef pointDict;
	CFDictionaryRef normalDict;
	CFDictionaryRef lineDict;
	
	pointDict = CPRVectorCreateDictionaryRepresentation(plane.point);
	normalDict = CPRVectorCreateDictionaryRepresentation(plane.normal);
	lineDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)pointDict, @"point", (id)normalDict, @"normal", nil];
	CFRelease(pointDict);
	CFRelease(normalDict);
	return lineDict;
}

bool CPRVectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, CPRVector *vector)
{
	CFNumberRef x;
	CFNumberRef y;
	CFNumberRef z;
	CFNumberType numberType;
	CPRVector tempVector;
	
	if (dict == NULL) {
		return false;
	}
	
	x = CFDictionaryGetValue(dict, @"x");
	y = CFDictionaryGetValue(dict, @"y");
	z = CFDictionaryGetValue(dict, @"z");
	
	if (x == NULL || CFGetTypeID(x) != CFNumberGetTypeID() ||
		y == NULL || CFGetTypeID(y) != CFNumberGetTypeID() ||
		z == NULL || CFGetTypeID(z) != CFNumberGetTypeID()) {
		return false;
	}
	
#if CGFLOAT_IS_DOUBLE
	numberType = kCFNumberDoubleType;
#else
	numberType = kCFNumberFloatType;
#endif
	
	if (CFNumberGetValue(x, numberType, &(tempVector.x)) == false) {
		return false;
	}
	if (CFNumberGetValue(y, numberType, &(tempVector.y)) == false) {
		return false;
	}
	if (CFNumberGetValue(z, numberType, &(tempVector.z)) == false) {
		return false;
	}
	
	if (vector) {
		*vector = tempVector;
	}
	
	return true;
}

bool CPRLineMakeWithDictionaryRepresentation(CFDictionaryRef dict, CPRLine *line)
{
	CPRLine tempLine;
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
	
	if (CPRVectorMakeWithDictionaryRepresentation(pointDict, &(tempLine.point)) == false) {
		return false;
	}
	if (CPRVectorMakeWithDictionaryRepresentation(vectorDict, &(tempLine.vector)) == false) {
		return false;
	}
	
	if (line) {
		*line = tempLine;
	}
	return true;
}

bool CPRPlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, CPRPlane *plane)
{
	CPRPlane tempPlane;
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
	
	if (CPRVectorMakeWithDictionaryRepresentation(pointDict, &(tempPlane.point)) == false) {
		return false;
	}
	if (CPRVectorMakeWithDictionaryRepresentation(normalDict, &(tempPlane.normal)) == false) {
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
    A = -1.0*copysign(pow(abs(R)+sqrt(R2-Q3), 1.0/3.0), R);
#else
    A = -1.0*copysignf(powf(abs(R)+sqrtf(R2-Q3), 1.0/3.0), R);
#endif
    if (A == 0) {
        B = 0;
    } else {
        B = Q/A;
    }
    
    *root1 = (A+B)-b_3;
    return 1;
}

@implementation NSValue (CPRGeometryAdditions)

+ (NSValue *)valueWithCPRVector:(CPRVector)vector
{
    return [NSValue valueWithBytes:&vector objCType:@encode(CPRVector)];
}

- (CPRVector)CPRVectorValue
{
    CPRVector vector;
    assert(strcmp([self objCType], @encode(CPRVector)) == 0);
    [self getValue:&vector];
    return vector;
}

+ (NSValue *)valueWithCPRLine:(CPRLine)line
{
    return [NSValue valueWithBytes:&line objCType:@encode(CPRLine)];
}

- (CPRLine)CPRLineValue
{
	CPRLine line;
    assert(strcmp([self objCType], @encode(CPRLine)) == 0);
    [self getValue:&line];
    return line;
}	

+ (NSValue *)valueWithCPRPlane:(CPRPlane)plane
{
	return [NSValue valueWithBytes:&plane objCType:@encode(CPRPlane)];

}

- (CPRPlane)CPRPlaneValue
{
	CPRPlane plane;
    assert(strcmp([self objCType], @encode(CPRPlane)) == 0);
    [self getValue:&plane];
    return plane;
}	

+ (NSValue *)valueWithCPRAffineTransform3D:(CPRAffineTransform3D)transform
{
    return [NSValue valueWithBytes:&transform objCType:@encode(CPRAffineTransform3D)];
}

- (CPRAffineTransform3D)CPRAffineTransform3DValue
{
    CPRAffineTransform3D transform;
    assert(strcmp([self objCType], @encode(CPRAffineTransform3D)) == 0);
    [self getValue:&transform];
    return transform;
}

@end

@implementation Point3D (CPRGeometryAdditions)

+ (id)pointWithCPRVector:(CPRVector)vector
{
	return [[[Point3D alloc] initWithCPRVector:vector] autorelease];
}

- (id)initWithCPRVector:(CPRVector)vector
{
	if ( (self = [super init]) ) {
		self.x = vector.x;
		self.y = vector.y;
		self.z = vector.z;
	}
	return self;
}

- (CPRVector)CPRVectorValue
{
	CPRVector vector;
	vector.x = self.x;
	vector.y = self.y;
	vector.z = self.z;
	return vector;
}

@end










