/*
 *  CPRGeometry.h
 *  OsiriX
 *
 *  Created by Joël Spaltenstein on 9/26/10.
 *  Copyright 2010 OsiriX Team. All rights reserved.
 *
 */

#ifndef _CPRGEOMETRY_H_
#define _CPRGEOMETRY_H_

#include <ApplicationServices/ApplicationServices.h>
#include <QuartzCore/CATransform3D.h>

#ifdef __OBJC__
#import <Foundation/NSValue.h>
#endif

CG_EXTERN_C_BEGIN
 
struct CPRVector {
    CGFloat x;
    CGFloat y;
    CGFloat z;
};
typedef struct CPRVector CPRVector;

// A CPRLine is an infinite line throught space
struct CPRLine {
    CPRVector point; // the line goes through this point
    CPRVector vector; // this is the direction of the line, the line is not valid if this is CPRVectorZero, try to keep this of unit length... I wish I would have called this direction...
};
typedef struct CPRLine CPRLine;

extern const CPRLine CPRLineXAxis;
extern const CPRLine CPRLineYAxis;
extern const CPRLine CPRLineZAxis;
extern const CPRLine CPRLineInvalid;

struct CPRPlane {
	CPRVector point;
	CPRVector normal;
};
typedef struct CPRPlane CPRPlane;

extern const CPRPlane CPRPlaneXZero;
extern const CPRPlane CPRPlaneYZero;
extern const CPRPlane CPRPlaneZZero;
extern const CPRPlane CPRPlaneInvalid;

typedef CPRVector *CPRVectorPointer;
typedef CPRVector *CPRVectorArray;

typedef CATransform3D CPRAffineTransform3D;

extern const CPRVector CPRVectorZero;

CPRVector CPRVectorMake(CGFloat x, CGFloat y, CGFloat z);

bool CPRVectorEqualToVector(CPRVector vector1, CPRVector vector2);
bool CPRVectorIsCoincidentToVector(CPRVector vector1, CPRVector vector2); // coincident to an arbitratry tolerance
bool CPRVectorIsZero(CPRVector vector);

CPRVector CPRVectorAdd(CPRVector vector1, CPRVector vector2);
CPRVector CPRVectorSubtract(CPRVector vector1, CPRVector vector2);
CPRVector CPRVectorScalarMultiply(CPRVector vector1, CGFloat scalar);

CGFloat CPRVectorDistance(CPRVector vector1, CPRVector vector2);

CGFloat CPRVectorDotProduct(CPRVector vector1, CPRVector vector2);
CPRVector CPRVectorCrossProduct(CPRVector vector1, CPRVector vector2);
CGFloat CPRVectorAngleBetweenVectorsAroundVector(CPRVector vector1, CPRVector vector2, CPRVector aroundVector); // returns [0, 2*M_PI)

CGFloat CPRVectorLength(CPRVector vector);
CPRVector CPRVectorNormalize(CPRVector vector);
CPRVector CPRVectorProject(CPRVector vector1, CPRVector vector2); // project vector1 onto vector2

CPRVector CPRVectorInvert(CPRVector vector);
CPRVector CPRVectorApplyTransform(CPRVector vector, CPRAffineTransform3D transform);
CPRVector CPRVectorApplyTransformToDirectionalVector(CPRVector vector, CPRAffineTransform3D transform); // this will not apply the translation to the vector, this is to be used when the vector does not coorespond to a point in space, but instead to a direction

CPRVector CPRVectorBend(CPRVector vectorToBend, CPRVector originalDirection, CPRVector newDirection); // applies the rotation that would be needed to turn originalDirection into newDirection, to vectorToBend
bool CPRVectorIsOnLine(CPRVector vector, CPRLine line);
bool CPRVectorIsOnPlane(CPRVector vector, CPRPlane plane);
CGFloat CPRVectorDistanceToLine(CPRVector vector, CPRLine line);

CPRLine CPRLineMake(CPRVector point, CPRVector vector);
CPRLine CPRLineMakeFromPoints(CPRVector point1, CPRVector point2);
bool CPRLineEqualToLine(CPRLine line1, CPRLine line2);
bool CPRLineIsCoincidentToLine(CPRLine line2, CPRLine line1); // do the two lines represent the same line in space, to a small amount of round-off slop
bool CPRLineIsOnPlane(CPRLine line, CPRPlane plane);
bool CPRLineIsParallelToLine(CPRLine line1, CPRLine line2);
bool CPRLineIsValid(CPRLine line);
bool CPRLineIntersectsPlane(CPRLine line, CPRPlane plane);
CPRVector CPRLineIntersectionWithPlane(CPRLine line, CPRPlane plane);
CPRVector CPRLinePointClosestToVector(CPRLine line, CPRVector vector);
CPRLine CPRLineApplyTransform(CPRLine line, CPRAffineTransform3D transform);
CGFloat CPRLineClosestPoints(CPRLine line1, CPRLine line2, CPRVectorPointer line1PointPtr, CPRVectorPointer line2PointPtr); // given two lines, find points on each line that are the closest to each other, note that the line the goes through these two points will be normal to both lines

CPRPlane CPRPlaneMake(CPRVector point, CPRVector normal);
bool CPRPlaneEqualToPlane(CPRPlane plane1, CPRPlane plane2);
bool CPRPlaneIsCoincidentToPlane(CPRPlane plane1, CPRPlane plane2);
bool CPRPlaneIsValid(CPRPlane plane);
CPRVector CPRPlanePointClosestToVector(CPRPlane plane, CPRVector vector);
bool CPRPlaneInterectsPlane(CPRPlane plane1, CPRPlane plane2);
bool CPRPlaneIsBetweenVectors(CPRPlane plane, CPRVector vector1, CPRVector vector2);
CPRLine CPRPlaneIntersectionWithPlane(CPRPlane plane1, CPRPlane plane2);
CPRPlane CPRPlaneApplyTransform(CPRPlane plane, CPRAffineTransform3D transform);

void CPRVectorScalarMultiplyVectors(CGFloat scalar, CPRVectorArray vectors, CFIndex numVectors);
void CPRVectorAddVectors(CPRVectorArray vectors1, const CPRVectorArray vectors2, CFIndex numVectors);
void CPRVectorApplyTransformToVectors(CPRAffineTransform3D transform, CPRVectorArray vectors, CFIndex numVectors);
void CPRVectorCrossProductWithVectors(CPRVectorArray vectors1, const CPRVectorArray vectors2, CFIndex numVectors);

CG_INLINE NSPoint NSPointFromCPRVector(CPRVector vector) {return NSMakePoint(vector.x, vector.y);}
CG_INLINE CPRVector CPRVectorMakeFromNSPoint(NSPoint point) {return CPRVectorMake(point.x, point.y, 0);}

extern const CPRAffineTransform3D CPRAffineTransform3DIdentity;

bool CPRAffineTransform3DIsRectilinear(CPRAffineTransform3D t); // this is not the right term, but what is a transform that only includes scale and translation called?
                                                 
                                        
CG_INLINE bool CPRAffineTransform3DIsIdentity(CPRAffineTransform3D t) {return CATransform3DIsIdentity(t);}
CG_INLINE bool CPRAffineTransform3DIsAffine(CPRAffineTransform3D t) {return (t.m14 == 0.0 && t.m24 == 0.0 && t.m34 == 0.0 && t.m44 == 1.0);}
CG_INLINE bool CPRAffineTransform3DEqualToTransform(CPRAffineTransform3D a, CPRAffineTransform3D b) {return CATransform3DEqualToTransform(a, b);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DMakeTranslation(tx, ty, tz);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DMakeTranslationWithVector(CPRVector vector) {return CATransform3DMakeTranslation(vector.x, vector.y, vector.z);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DMakeScale (CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DMakeScale(sx, sy, sz);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DMakeRotation (CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DMakeRotation(angle, x, y, z);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DMakeRotationAroundVector (CGFloat angle, CPRVector vector) {return CATransform3DMakeRotation(angle, vector.x, vector.y, vector.z);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DTranslate (CPRAffineTransform3D t, CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DTranslate(t, tx, tz, tz);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DScale (CPRAffineTransform3D t, CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DScale(t, sx, sy, sz);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DRotate (CPRAffineTransform3D t, CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DRotate(t, angle, x, y, z);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DRotateAroundVector (CPRAffineTransform3D t, CGFloat angle, CPRVector vector) {return CATransform3DRotate(t, angle, vector.x, vector.y, vector.z);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DConcat (CPRAffineTransform3D a, CATransform3D b) {return CATransform3DConcat(a, b);}
CG_INLINE CPRAffineTransform3D CPRAffineTransform3DInvert (CPRAffineTransform3D t) {return CATransform3DInvert(t);}

CFDictionaryRef CPRVectorCreateDictionaryRepresentation(CPRVector vector);
CFDictionaryRef CPRLineCreateDictionaryRepresentation(CPRLine line);
CFDictionaryRef CPRPlaneCreateDictionaryRepresentation(CPRPlane plane);

bool CPRVectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, CPRVector *vector);
bool CPRLineMakeWithDictionaryRepresentation(CFDictionaryRef dict, CPRLine *line);
bool CPRPlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, CPRPlane *plane);

// returns the real numbered roots of ax+b
CFIndex findRealLinearRoot(CGFloat a, CGFloat b, CGFloat *root); // returns the number of roots set
// returns the real numbered roots of ax^2+bx+c
CFIndex findRealQuadraticRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat *root1, CGFloat *root2); // returns the number of roots set
 // returns the real numbered roots of ax^3+bx^2+cx+d
CFIndex findRealCubicRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *root1, CGFloat *root2, CGFloat *root3); // returns the number of roots set 

CG_EXTERN_C_END

/** NSValue support. **/
 
#ifdef __OBJC__

@class NSString;
NSString *NSStringFromCPRAffineTransform3D(CPRAffineTransform3D transform);
NSString *NSStringFromCPRVector(CPRVector vector);
NSString *NSStringFromCPRLine(CPRLine line);
NSString *NSStringFromCPRPlane(CPRPlane plane);

@interface NSValue (CPRGeometryAdditions)

+ (NSValue *)valueWithCPRVector:(CPRVector)vector;
- (CPRVector)CPRVectorValue;

+ (NSValue *)valueWithCPRLine:(CPRLine)line;
- (CPRLine)CPRLineValue;

+ (NSValue *)valueWithCPRPlane:(CPRPlane)plane;
- (CPRPlane)CPRPlaneValue;

+ (NSValue *)valueWithCPRAffineTransform3D:(CPRAffineTransform3D)transform;
- (CPRAffineTransform3D)CPRAffineTransform3DValue;

@end

#import "Point3D.h"

@interface Point3D (CPRGeometryAdditions)

+ (id)pointWithCPRVector:(CPRVector)vector;
- (id)initWithCPRVector:(CPRVector)vector;
- (CPRVector)CPRVectorValue;

@end


#endif /* __OBJC__ */

#if defined(__cplusplus)

class vtkMatrix4x4;
CPRAffineTransform3D CPRAffineTransform3DMakeFromVTKMatrix4x4(vtkMatrix4x4 *matrix);

#endif /* __cplusplus */

#endif	/* _CPRGEOMETRY_H_ */



