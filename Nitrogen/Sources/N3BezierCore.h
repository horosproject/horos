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

#ifndef _N3BEZIERCORE_H_
#define _N3BEZIERCORE_H_

#include <ApplicationServices/ApplicationServices.h>

#include "N3Geometry.h"

/* look in N3BezierCoreAdditions.h for additional functions that could be of interest */

CF_EXTERN_C_BEGIN

enum N3BezierCoreSegmentType {
    N3MoveToBezierCoreSegmentType,
    N3LineToBezierCoreSegmentType,
    N3CurveToBezierCoreSegmentType,
    N3CloseBezierCoreSegmentType,
    N3EndBezierCoreSegmentType = 0xFFFFFFFF
};
typedef enum N3BezierCoreSegmentType N3BezierCoreSegmentType;

extern const CFDictionaryValueCallBacks kN3BezierCoreDictionaryValueCallBacks;
extern const CFArrayCallBacks kN3BezierCoreArrayCallBacks;

extern const CGFloat N3BezierDefaultFlatness;
extern const CGFloat N3BezierDefaultSubdivideSegmentLength;

typedef const struct N3BezierCore *N3BezierCoreRef;
typedef struct N3BezierCore *N3MutableBezierCoreRef;
typedef struct N3BezierCoreIterator *N3BezierCoreIteratorRef;
typedef const struct N3BezierCoreRandomAccessor *N3BezierCoreRandomAccessorRef;

N3BezierCoreRef N3BezierCoreCreate(void);
N3MutableBezierCoreRef N3BezierCoreCreateMutable(void);
void *N3BezierCoreRetain(N3BezierCoreRef bezierCore);
void N3BezierCoreRelease(N3BezierCoreRef bezierCore);
bool N3BezierCoreEqualToBezierCore(N3BezierCoreRef bezierCore1, N3BezierCoreRef bezierCore2);
CFStringRef N3BezierCoreCopyDescription(N3BezierCoreRef bezierCore);
bool N3BezierCoreHasCurve(N3BezierCoreRef bezierCore);

N3BezierCoreRef N3BezierCoreCreateCopy(N3BezierCoreRef bezierCore);
N3MutableBezierCoreRef N3BezierCoreCreateMutableCopy(N3BezierCoreRef bezierCore);

CFDictionaryRef N3BezierCoreCreateDictionaryRepresentation(N3BezierCoreRef bezierCore);
N3BezierCoreRef N3BezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict);
N3MutableBezierCoreRef N3BezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict);

void N3BezierCoreAddSegment(N3MutableBezierCoreRef bezierCore, N3BezierCoreSegmentType segmentType, N3Vector control1, N3Vector control2, N3Vector endpoint);
void N3BezierCoreSetVectorsForSegementAtIndex(N3MutableBezierCoreRef bezierCore, CFIndex index, N3Vector control1, N3Vector control2, N3Vector endpoint);
void N3BezierCoreFlatten(N3MutableBezierCoreRef bezierCore, CGFloat flatness);
void N3BezierCoreSubdivide(N3MutableBezierCoreRef bezierCore, CGFloat maxSegementLength);
void N3BezierCoreApplyTransform(N3MutableBezierCoreRef bezierCore, N3AffineTransform transform);
void N3BezierCoreAppendBezierCore(N3MutableBezierCoreRef bezierCore, N3BezierCoreRef appenedBezier, bool connectPaths);

N3BezierCoreRef N3BezierCoreCreateFlattenedCopy(N3BezierCoreRef bezierCore, CGFloat flatness);
N3MutableBezierCoreRef N3BezierCoreCreateFlattenedMutableCopy(N3BezierCoreRef bezierCore, CGFloat flatness);
N3BezierCoreRef N3BezierCoreCreateSubdividedCopy(N3BezierCoreRef bezierCore, CGFloat maxSegementLength);
N3MutableBezierCoreRef N3BezierCoreCreateSubdividedMutableCopy(N3BezierCoreRef bezierCore, CGFloat maxSegementLength);
N3BezierCoreRef N3BezierCoreCreateTransformedCopy(N3BezierCoreRef bezierCore, N3AffineTransform transform);
N3MutableBezierCoreRef N3BezierCoreCreateTransformedMutableCopy(N3BezierCoreRef bezierCore, N3AffineTransform transform);

CFIndex N3BezierCoreSegmentCount(N3BezierCoreRef bezierCore);
CFIndex N3BezierCoreSubpathCount(N3BezierCoreRef bezierCore);
CGFloat N3BezierCoreLength(N3BezierCoreRef bezierCore);

/* This requires a traverse though a linked list on every call, if you care for speed use a BezierCoreIterator or a BezierCoreRandomAccessor */
N3BezierCoreSegmentType N3BezierCoreGetSegmentAtIndex(N3BezierCoreRef bezierCore, CFIndex index, N3VectorPointer control1, N3VectorPointer control2, N3VectorPointer endpoint);

/* Debug */
void N3BezierCoreCheckDebug(N3BezierCoreRef bezierCore);

/* BezierCoreIterator */

N3BezierCoreIteratorRef N3BezierCoreIteratorCreateWithBezierCore(N3BezierCoreRef bezierCore);
N3BezierCoreIteratorRef N3BezierCoreIteratorRetain(N3BezierCoreIteratorRef bezierCoreIterator);
void N3BezierCoreIteratorRelease(N3BezierCoreIteratorRef bezierCoreIterator);

N3BezierCoreSegmentType N3BezierCoreIteratorGetNextSegment(N3BezierCoreIteratorRef bezierCoreIterator, N3VectorPointer control1, N3VectorPointer control2, N3VectorPointer endpoint);

bool N3BezierCoreIteratorIsAtEnd(N3BezierCoreIteratorRef bezierCoreIterator);
CFIndex N3BezierCoreIteratorIndex(N3BezierCoreIteratorRef bezierCoreIterator);
void N3BezierCoreIteratorSetIndex(N3BezierCoreIteratorRef bezierCoreIterator, CFIndex index);
CFIndex N3BezierCoreIteratorSegmentCount(N3BezierCoreIteratorRef bezierCoreIterator);


/* BezierCoreRandomAccessor */
/* Caches pointers to each element of the linked list so iterating is O(n) not O(n^2) */

N3BezierCoreRandomAccessorRef N3BezierCoreRandomAccessorCreateWithBezierCore(N3BezierCoreRef bezierCore);
N3BezierCoreRandomAccessorRef N3BezierCoreRandomAccessorCreateWithMutableBezierCore(N3MutableBezierCoreRef bezierCore);
N3BezierCoreRandomAccessorRef N3BezierCoreRandomAccessorRetain(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor);
void N3BezierCoreRandomAccessorRelease(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor);

N3BezierCoreSegmentType N3BezierCoreRandomAccessorGetSegmentAtIndex(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, N3VectorPointer control1, N3VectorPointer control2, N3VectorPointer endpoint);
void N3BezierCoreRandomAccessorSetVectorsForSegementAtIndex(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, N3Vector control1, N3Vector control2, N3Vector endpoint); // the random accessor must have been created with the mutable beziercore
CFIndex N3BezierCoreRandomAccessorSegmentCount(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor);

CF_EXTERN_C_END

#endif	/* _N3BEZIERCORE_H_ */
