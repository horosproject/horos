/*
 *  CPRBezierCore.h
 *  OsiriX
 *
 *  Created by Joël Spaltenstein on 9/26/10.
 *  Copyright 2010 OsiriX Team. All rights reserved.
 *
 */

#ifndef _CPRBEZIERCORE_H_
#define _CPRBEZIERCORE_H_

#include <ApplicationServices/ApplicationServices.h>

#include "CPRGeometry.h"

/* look in CPRBezierCoreAdditions.h for additional functions that could be of interest */

CG_EXTERN_C_BEGIN

enum CPRBezierCoreSegmentType {
    CPRMoveToBezierCoreSegmentType,
    CPRLineToBezierCoreSegmentType,
    CPRCurveToBezierCoreSegmentType,
    CPRCloseBezierCoreSegmentType,
    CPREndBezierCoreSegmentType = 0xFFFFFFFF
};
typedef enum CPRBezierCoreSegmentType CPRBezierCoreSegmentType;

extern const CGFloat CPRBezierDefaultFlatness;
extern const CGFloat CPRBezierDefaultSubdivideSegmentLength;

typedef const struct CPRBezierCore *CPRBezierCoreRef;
typedef struct CPRBezierCore *CPRMutableBezierCoreRef;
typedef struct CPRBezierCoreIterator *CPRBezierCoreIteratorRef;
typedef const struct CPRBezierCoreRandomAccessor *CPRBezierCoreRandomAccessorRef;

CPRBezierCoreRef CPRBezierCoreCreate();
CPRMutableBezierCoreRef CPRBezierCoreCreateMutable();
void *CPRBezierCoreRetain(CPRBezierCoreRef bezierCore);
void CPRBezierCoreRelease(CPRBezierCoreRef bezierCore);
bool CPRBezierCoreEqualToBezierCore(CPRBezierCoreRef bezierCore1, CPRBezierCoreRef bezierCore2);
bool CPRBezierCoreHasCurve(CPRBezierCoreRef bezierCore);

CPRBezierCoreRef CPRBezierCoreCreateCopy(CPRBezierCoreRef bezierCore);
CPRMutableBezierCoreRef CPRBezierCoreCreateMutableCopy(CPRBezierCoreRef bezierCore);

void CPRBezierCoreAddSegment(CPRMutableBezierCoreRef bezierCore, CPRBezierCoreSegmentType segmentType, CPRVector control1, CPRVector control2, CPRVector endpoint);
void CPRBezierCoreFlatten(CPRMutableBezierCoreRef bezierCore, CGFloat flatness);
void CPRBezierCoreSubdivide(CPRMutableBezierCoreRef bezierCore, CGFloat maxSegementLength);
void CPRBezierCoreApplyTransform(CPRMutableBezierCoreRef bezierCore, CPRAffineTransform3D transform);
void CPRBezierCoreAppendBezierCore(CPRMutableBezierCoreRef bezierCore, CPRBezierCoreRef appenedBezier, bool connectPaths);

CPRBezierCoreRef CPRBezierCoreCreateFlattenedCopy(CPRBezierCoreRef bezierCore, CGFloat flatness);
CPRMutableBezierCoreRef CPRBezierCoreCreateFlattenedMutableCopy(CPRBezierCoreRef bezierCore, CGFloat flatness);
CPRBezierCoreRef CPRBezierCoreCreateSubdividedCopy(CPRBezierCoreRef bezierCore, CGFloat maxSegementLength);
CPRMutableBezierCoreRef CPRBezierCoreCreateSubdividedMutableCopy(CPRBezierCoreRef bezierCore, CGFloat maxSegementLength);
CPRBezierCoreRef CPRBezierCoreCreateTransformedCopy(CPRBezierCoreRef bezierCore, CPRAffineTransform3D transform);
CPRMutableBezierCoreRef CPRBezierCoreCreateTransformedMutableCopy(CPRBezierCoreRef bezierCore, CPRAffineTransform3D transform);

CFIndex CPRBezierCoreSegmentCount(CPRBezierCoreRef bezierCore);
CFIndex CPRBezierCoreSubpathCount(CPRBezierCoreRef bezierCore);
CGFloat CPRBezierCoreLength(CPRBezierCoreRef bezierCore);

/* This requires a traverse though a linked list on every call, if you care for speed use a BezierCoreIterator or a BezierCoreRandomAccessor */
CPRBezierCoreSegmentType CPRBezierCoreGetSegmentAtIndex(CPRBezierCoreRef bezierCore, CFIndex index, CPRVectorPointer control1, CPRVectorPointer control2, CPRVectorPointer endpoint);

/* Debug */
void CPRBezierCoreCheckDebug(CPRBezierCoreRef bezierCore);

/* BezierCoreIterator */

CPRBezierCoreIteratorRef CPRBezierCoreIteratorCreateWithBezierCore(CPRBezierCoreRef bezierCore);
CPRBezierCoreIteratorRef CPRBezierCoreIteratorRetain(CPRBezierCoreIteratorRef bezierCoreIterator);
void CPRBezierCoreIteratorRelease(CPRBezierCoreIteratorRef bezierCoreIterator);

CPRBezierCoreSegmentType CPRBezierCoreIteratorGetNextSegment(CPRBezierCoreIteratorRef bezierCoreIterator, CPRVectorPointer control1, CPRVectorPointer control2, CPRVectorPointer endpoint);

bool CPRBezierCoreIteratorIsAtEnd(CPRBezierCoreIteratorRef bezierCoreIterator);
CFIndex CPRBezierCoreIteratorIndex(CPRBezierCoreIteratorRef bezierCoreIterator);
void CPRBezierCoreIteratorSetIndex(CPRBezierCoreIteratorRef bezierCoreIterator, CFIndex index);
CFIndex CPRBezierCoreIteratorSegmentCount(CPRBezierCoreIteratorRef bezierCoreIterator);


/* BezierCoreRandomAccessor */
/* Caches pointers to each element of the linked list so iterating is O(n) not O(n^2) */

CPRBezierCoreRandomAccessorRef CPRBezierCoreRandomAccessorCreateWithBezierCore(CPRBezierCoreRef bezierCore);
CPRBezierCoreRandomAccessorRef CPRBezierCoreRandomAccessorRetain(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor);
void CPRBezierCoreRandomAccessorRelease(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor);

CPRBezierCoreSegmentType CPRBezierCoreRandomAccessorGetSegmentAtIndex(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, CPRVectorPointer control1, CPRVectorPointer control2, CPRVectorPointer endpoint);
CFIndex CPRBezierCoreRandomAccessorSegmentCount(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor);

CG_EXTERN_C_END

#endif	/* _CPRBEZIERCORE_H_ */
