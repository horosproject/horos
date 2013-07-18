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

#ifndef _N3GEOMETRY_H_
#define _N3GEOMETRY_H_

#include <QuartzCore/CATransform3D.h>

#ifdef __OBJC__
#import <Foundation/NSValue.h>
@class NSString;
#endif

CF_EXTERN_C_BEGIN
 
struct N3Vector {
    CGFloat x;
    CGFloat y;
    CGFloat z;
};
typedef struct N3Vector N3Vector;

// A N3Line is an infinite line throught space
struct N3Line {
    N3Vector point; // the line goes through this point
    N3Vector vector; // this is the direction of the line, the line is not valid if this is N3VectorZero, try to keep this of unit length... I wish I would have called this direction...
};
typedef struct N3Line N3Line;

extern const N3Line N3LineXAxis;
extern const N3Line N3LineYAxis;
extern const N3Line N3LineZAxis;
extern const N3Line N3LineInvalid;

struct N3Plane {
	N3Vector point;
	N3Vector normal;
};
typedef struct N3Plane N3Plane;

extern const N3Plane N3PlaneXZero;
extern const N3Plane N3PlaneYZero;
extern const N3Plane N3PlaneZZero;
extern const N3Plane N3PlaneInvalid;

typedef N3Vector *N3VectorPointer;
typedef N3Vector *N3VectorArray;

typedef N3Line *N3LinePointer;
typedef N3Line *N3LineArray;

typedef N3Plane *N3PlanePointer;
typedef N3Plane *N3PlaneArray;

typedef CATransform3D N3AffineTransform;

typedef N3AffineTransform *N3AffineTransformPointer;
typedef N3AffineTransform *N3AffineTransformArray;

extern const N3Vector N3VectorZero;

N3Vector N3VectorMake(CGFloat x, CGFloat y, CGFloat z);

bool N3VectorEqualToVector(N3Vector vector1, N3Vector vector2);
bool N3VectorIsCoincidentToVector(N3Vector vector1, N3Vector vector2); // coincident to an arbitratry tolerance
bool N3VectorIsZero(N3Vector vector);

N3Vector N3VectorAdd(N3Vector vector1, N3Vector vector2);
N3Vector N3VectorSubtract(N3Vector vector1, N3Vector vector2);
N3Vector N3VectorScalarMultiply(N3Vector vector1, CGFloat scalar);

N3Vector N3VectorANormalVector(N3Vector vector); // returns a vector that is normal to the given vector

CGFloat N3VectorDistance(N3Vector vector1, N3Vector vector2);

CGFloat N3VectorDotProduct(N3Vector vector1, N3Vector vector2);
N3Vector N3VectorCrossProduct(N3Vector vector1, N3Vector vector2);
N3Vector N3VectorLerp(N3Vector vector1, N3Vector vector2, CGFloat t); // when t == 0.0 the result is vector 1, when t == 1.0 the result is vector2
CGFloat N3VectorAngleBetweenVectorsAroundVector(N3Vector vector1, N3Vector vector2, N3Vector aroundVector); // returns [0, 2*M_PI)

CGFloat N3VectorLength(N3Vector vector);
N3Vector N3VectorNormalize(N3Vector vector);
N3Vector N3VectorProject(N3Vector vector1, N3Vector vector2); // project vector1 onto vector2

N3Vector N3VectorInvert(N3Vector vector);
N3Vector N3VectorApplyTransform(N3Vector vector, N3AffineTransform transform);
N3Vector N3VectorApplyTransformToDirectionalVector(N3Vector vector, N3AffineTransform transform); // this will not apply the translation to the vector, this is to be used when the vector does not coorespond to a point in space, but instead to a direction

N3Vector N3VectorBend(N3Vector vectorToBend, N3Vector originalDirection, N3Vector newDirection); // applies the rotation that would be needed to turn originalDirection into newDirection, to vectorToBend
bool N3VectorIsOnLine(N3Vector vector, N3Line line);
bool N3VectorIsOnPlane(N3Vector vector, N3Plane plane);
CGFloat N3VectorDistanceToLine(N3Vector vector, N3Line line);
CGFloat N3VectorDistanceToPlane(N3Vector vector, N3Plane plane);

N3Line N3LineMake(N3Vector point, N3Vector vector);
N3Line N3LineMakeFromPoints(N3Vector point1, N3Vector point2);
bool N3LineEqualToLine(N3Line line1, N3Line line2);
bool N3LineIsCoincidentToLine(N3Line line2, N3Line line1); // do the two lines represent the same line in space, to a small amount of round-off slop
bool N3LineIsOnPlane(N3Line line, N3Plane plane);
bool N3LineIsParallelToLine(N3Line line1, N3Line line2);
bool N3LineIsValid(N3Line line);
bool N3LineIntersectsPlane(N3Line line, N3Plane plane);
N3Vector N3LineIntersectionWithPlane(N3Line line, N3Plane plane);
N3Vector N3LinePointClosestToVector(N3Line line, N3Vector vector);
N3Line N3LineApplyTransform(N3Line line, N3AffineTransform transform);
CGFloat N3LineClosestPoints(N3Line line1, N3Line line2, N3VectorPointer line1PointPtr, N3VectorPointer line2PointPtr); // given two lines, find points on each line that are the closest to each other. Returns the distance between these two points. Note that the line that goes through these two points will be normal to both lines

N3Plane N3PlaneMake(N3Vector point, N3Vector normal);
bool N3PlaneEqualToPlane(N3Plane plane1, N3Plane plane2);
bool N3PlaneIsCoincidentToPlane(N3Plane plane1, N3Plane plane2);
bool N3PlaneIsValid(N3Plane plane);
N3Vector N3PlanePointClosestToVector(N3Plane plane, N3Vector vector);
bool N3PlaneIsParallelToPlane(N3Plane plane1, N3Plane plane2);
bool N3PlaneIsBetweenVectors(N3Plane plane, N3Vector vector1, N3Vector vector2);
N3Line N3PlaneIntersectionWithPlane(N3Plane plane1, N3Plane plane2);
N3Plane N3PlaneLeastSquaresPlaneFromPoints(N3VectorArray vectors, CFIndex numVectors); // BOGUS TODO not written yet, will give a plane, but it won't be the least squares plane
N3Plane N3PlaneApplyTransform(N3Plane plane, N3AffineTransform transform);

void N3VectorScalarMultiplyVectors(CGFloat scalar, N3VectorArray vectors, CFIndex numVectors);
void N3VectorCrossProductVectors(N3Vector vector, N3VectorArray vectors, CFIndex numVectors);
void N3VectorAddVectors(N3VectorArray vectors1, const N3VectorArray vectors2, CFIndex numVectors);
void N3VectorApplyTransformToVectors(N3AffineTransform transform, N3VectorArray vectors, CFIndex numVectors);
void N3VectorCrossProductWithVectors(N3VectorArray vectors1, const N3VectorArray vectors2, CFIndex numVectors);
void N3VectorNormalizeVectors(N3VectorArray vectors, CFIndex numVectors);

CG_INLINE NSPoint NSPointFromN3Vector(N3Vector vector) {return NSMakePoint(vector.x, vector.y);}
CG_INLINE N3Vector N3VectorMakeFromNSPoint(NSPoint point) {return N3VectorMake(point.x, point.y, 0);}

extern const N3AffineTransform N3AffineTransformIdentity;

bool N3AffineTransformIsRectilinear(N3AffineTransform t); // this is not the right term, but what is a transform that only includes scale and translation called?
N3AffineTransform N3AffineTransformTranspose(N3AffineTransform t);
CGFloat N3AffineTransformDeterminant(N3AffineTransform t);
N3AffineTransform N3AffineTransformInvert (N3AffineTransform t);
N3AffineTransform N3AffineTransformConcat (N3AffineTransform a, N3AffineTransform b);

CG_INLINE bool N3AffineTransformIsIdentity(N3AffineTransform t) {return CATransform3DIsIdentity(t);}
CG_INLINE bool N3AffineTransformIsAffine(N3AffineTransform t) {return (t.m14 == 0.0 && t.m24 == 0.0 && t.m34 == 0.0 && t.m44 == 1.0);}
CG_INLINE bool N3AffineTransformEqualToTransform(N3AffineTransform a, N3AffineTransform b) {return CATransform3DEqualToTransform(a, b);}
CG_INLINE N3AffineTransform N3AffineTransformMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DMakeTranslation(tx, ty, tz);}
CG_INLINE N3AffineTransform N3AffineTransformMakeTranslationWithVector(N3Vector vector) {return CATransform3DMakeTranslation(vector.x, vector.y, vector.z);}
CG_INLINE N3AffineTransform N3AffineTransformMakeScale(CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DMakeScale(sx, sy, sz);}
CG_INLINE N3AffineTransform N3AffineTransformMakeRotation(CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DMakeRotation(angle, x, y, z);}
CG_INLINE N3AffineTransform N3AffineTransformMakeRotationAroundVector(CGFloat angle, N3Vector vector) {return CATransform3DMakeRotation(angle, vector.x, vector.y, vector.z);}
CG_INLINE N3AffineTransform N3AffineTransformTranslate(N3AffineTransform t, CGFloat tx, CGFloat ty, CGFloat tz) {return CATransform3DTranslate(t, tx, ty, tz);}
CG_INLINE N3AffineTransform N3AffineTransformTranslateWithVector(N3AffineTransform t, N3Vector vector) {return CATransform3DTranslate(t, vector.x, vector.y, vector.z);}
CG_INLINE N3AffineTransform N3AffineTransformScale(N3AffineTransform t, CGFloat sx, CGFloat sy, CGFloat sz) {return CATransform3DScale(t, sx, sy, sz);}
CG_INLINE N3AffineTransform N3AffineTransformRotate(N3AffineTransform t, CGFloat angle, CGFloat x, CGFloat y, CGFloat z) {return CATransform3DRotate(t, angle, x, y, z);}
CG_INLINE N3AffineTransform N3AffineTransformRotateAroundVector(N3AffineTransform t, CGFloat angle, N3Vector vector) {return CATransform3DRotate(t, angle, vector.x, vector.y, vector.z);}

CFDictionaryRef N3VectorCreateDictionaryRepresentation(N3Vector vector);
CFDictionaryRef N3LineCreateDictionaryRepresentation(N3Line line);
CFDictionaryRef N3PlaneCreateDictionaryRepresentation(N3Plane plane);

bool N3VectorMakeWithDictionaryRepresentation(CFDictionaryRef dict, N3Vector *vector);
bool N3LineMakeWithDictionaryRepresentation(CFDictionaryRef dict, N3Line *line);
bool N3PlaneMakeWithDictionaryRepresentation(CFDictionaryRef dict, N3Plane *plane);

// gets openGL matrix values out of a N3AffineTransform
void N3AffineTransformGetOpenGLMatrixd(N3AffineTransform transform, double *d); // d better be 16 elements long
void N3AffineTransformGetOpenGLMatrixf(N3AffineTransform transform, float *f); // f better be 16 elements long

N3AffineTransform N3AffineTransformMakeFromOpenGLMatrixd(double *d); // d better be 16 elements long
N3AffineTransform N3AffineTransformMakeFromOpenGLMatrixf(float *f); // f better be 16 elements long

// returns the real numbered roots of ax+b
CFIndex findRealLinearRoot(CGFloat a, CGFloat b, CGFloat *root); // returns the number of roots set
// returns the real numbered roots of ax^2+bx+c
CFIndex findRealQuadraticRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat *root1, CGFloat *root2); // returns the number of roots set
 // returns the real numbered roots of ax^3+bx^2+cx+d
CFIndex findRealCubicRoots(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat *root1, CGFloat *root2, CGFloat *root3); // returns the number of roots set 

CF_EXTERN_C_END

 
#ifdef __OBJC__

NSString *NSStringFromN3AffineTransform(N3AffineTransform transform);
NSString *NSStringFromN3Vector(N3Vector vector);
NSString *NSStringFromN3Line(N3Line line);
NSString *NSStringFromN3Plane(N3Plane plane);

/** NSValue support. **/

@interface NSValue (N3GeometryAdditions)

+ (NSValue *)valueWithN3Vector:(N3Vector)vector;
- (N3Vector)N3VectorValue;

+ (NSValue *)valueWithN3Line:(N3Line)line;
- (N3Line)N3LineValue;

+ (NSValue *)valueWithN3Plane:(N3Plane)plane;
- (N3Plane)N3PlaneValue;

+ (NSValue *)valueWithN3AffineTransform:(N3AffineTransform)transform;
- (N3AffineTransform)N3AffineTransformValue;

@end



#endif /* __OBJC__ */

#endif	/* _N3GEOMETRY_H_ */



