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

#include "N3BezierCore.h"
#include <libkern/OSAtomic.h>

static const void *_N3BezierCoreRetainCallback(CFAllocatorRef allocator, const void *value)
{
	return N3BezierCoreRetain((N3BezierCoreRef)value);
}

static void _N3BezierCoreReleaseCallback(CFAllocatorRef allocator, const void *value)
{
	N3BezierCoreRelease((N3BezierCoreRef)value);
}

static CFStringRef _N3BezierCoreCopyDescriptionCallBack(const void *value)
{
	return N3BezierCoreCopyDescription((N3BezierCoreRef)value);
}

static Boolean _N3BezierCoreEqualCallBack(const void *value1, const void *value2)
{
	return N3BezierCoreEqualToBezierCore((N3BezierCoreRef)value1, (N3BezierCoreRef)value2);
}

const CFArrayCallBacks kN3BezierCoreArrayCallBacks = {
	0,
	_N3BezierCoreRetainCallback,
	_N3BezierCoreReleaseCallback,
	_N3BezierCoreCopyDescriptionCallBack,
	_N3BezierCoreEqualCallBack
};

const CFDictionaryValueCallBacks kN3BezierCoreDictionaryValueCallBacks = {
	0,
	_N3BezierCoreRetainCallback,
	_N3BezierCoreReleaseCallback,
	_N3BezierCoreCopyDescriptionCallBack,
	_N3BezierCoreEqualCallBack
};


const CGFloat N3BezierDefaultFlatness = 0.1;
const CGFloat N3BezierDefaultSubdivideSegmentLength = 3;

typedef struct N3BezierCoreElement *N3BezierCoreElementRef; 

struct N3BezierCore
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    N3BezierCoreElementRef elementList;
    N3BezierCoreElementRef lastElement;
    CFIndex elementCount;
};

struct N3BezierCoreElement {
    N3BezierCoreSegmentType segmentType;
    N3Vector control1;
    N3Vector control2;
    N3Vector endpoint;
    N3BezierCoreElementRef next; // the last element has next set to NULL
    N3BezierCoreElementRef previous; // the first element has previous set to NULL
};
typedef struct N3BezierCoreElement N3BezierCoreElement;

struct N3BezierCoreIterator
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    N3BezierCoreRef bezierCore;
    CFIndex index;
    N3BezierCoreElementRef elementAtIndex;
};
typedef struct N3BezierCoreIterator N3BezierCoreIterator;

struct N3BezierCoreRandomAccessor {
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    N3MutableBezierCoreRef bezierCore;
    N3BezierCoreElementRef *elementArray;
	char mutableBezierCore; // boolean
};
typedef struct N3BezierCoreRandomAccessor N3BezierCoreRandomAccessor;

static CGFloat _N3BezierCoreElementLength(N3BezierCoreElementRef element); // only gives a very rough approximation for curved paths, but the approximation is guaranteed to be the real length or longer
static CGFloat _N3BezierCoreElementFlatness(N3BezierCoreElementRef element);
static void _N3BezierCoreElementDivide(N3BezierCoreElementRef element);
static bool _N3BezierCoreElementEqualToElement(N3BezierCoreElementRef element1, N3BezierCoreElementRef element2);
static N3Vector _N3BezierCoreLastMoveTo(N3BezierCoreRef bezierCore);

#pragma mark -
#pragma mark N3BezierCore


N3BezierCoreRef N3BezierCoreCreate()
{
    return N3BezierCoreCreateMutable();
}

N3MutableBezierCoreRef N3BezierCoreCreateMutable()
{
    N3MutableBezierCoreRef bezierCore;

    bezierCore = malloc(sizeof(struct N3BezierCore));
    memset(bezierCore, 0, sizeof(struct N3BezierCore));
    
    N3BezierCoreRetain(bezierCore);
    N3BezierCoreCheckDebug(bezierCore);
    return bezierCore;
}

void *N3BezierCoreRetain(N3BezierCoreRef bezierCore)
{
    N3MutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (N3MutableBezierCoreRef)bezierCore;
    if (bezierCore) {
        OSAtomicIncrement32(&(mutableBezierCore->retainCount));
        N3BezierCoreCheckDebug(bezierCore);
    }
    return mutableBezierCore;
}


void N3BezierCoreRelease(N3BezierCoreRef bezierCore)
{
    N3MutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (N3MutableBezierCoreRef)bezierCore;
    N3BezierCoreElementRef element;
    N3BezierCoreElementRef nextElement;
        
    if (bezierCore) {
        N3BezierCoreCheckDebug(bezierCore);
        assert(bezierCore->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCore->retainCount)) == 0) {
            element = bezierCore->elementList;
            
            while (element) {
                nextElement = element->next;
                free(element);
                element = nextElement;
            }
            
            free((N3MutableBezierCoreRef) bezierCore);
        }
    }
}

bool N3BezierCoreEqualToBezierCore(N3BezierCoreRef bezierCore1, N3BezierCoreRef bezierCore2)
{
    N3BezierCoreElementRef element1;
    N3BezierCoreElementRef element2;
    
    if (bezierCore1 == bezierCore2) {
        return true;
    }
    
    if (bezierCore1->elementCount != bezierCore2->elementCount) {
        return false;
    }

    element1 = bezierCore1->elementList;
    element2 = bezierCore2->elementList;
    
    while (element1) {
        if (_N3BezierCoreElementEqualToElement(element1, element2) == false) {
            return false;
        }
        element1 = element1->next;
        element2 = element2->next;
    }
    
    return true;
}

bool N3BezierCoreHasCurve(N3BezierCoreRef bezierCore)
{
    N3BezierCoreElementRef element;
    
    if (bezierCore->elementList == NULL) {
        return false;
    }
    
    element = bezierCore->elementList->next;
    
    while (element) {
        if (element->segmentType == N3CurveToBezierCoreSegmentType) {
            return true;
        }
        element = element->next;
    }
    
    return false;
}

CFStringRef N3BezierCoreCopyDescription(N3BezierCoreRef bezierCore)
{
	CFDictionaryRef dictionaryRep;
	CFStringRef description;
	
	dictionaryRep = N3BezierCoreCreateDictionaryRepresentation(bezierCore);
	description = (CFStringRef)[[(NSDictionary *)dictionaryRep description] retain];
	CFRelease(dictionaryRep);
	return description;
}

N3BezierCoreRef N3BezierCoreCreateCopy(N3BezierCoreRef bezierCore)
{
    return N3BezierCoreCreateMutableCopy(bezierCore);
}

N3MutableBezierCoreRef N3BezierCoreCreateMutableCopy(N3BezierCoreRef bezierCore)
{
    N3MutableBezierCoreRef newBezierCore;
    N3BezierCoreElementRef element;
    N3BezierCoreElementRef prevNewElement;
    N3BezierCoreElementRef newElement;
    CFIndex elementCount;

    newBezierCore = malloc(sizeof(struct N3BezierCore));
    memset(newBezierCore, 0, sizeof(struct N3BezierCore));
    
    newElement = NULL;
    element = bezierCore->elementList;
    prevNewElement = 0;
    elementCount = 0;
    
    if (element) {
        newElement = malloc(sizeof(N3BezierCoreElement));
        memcpy(newElement, element, sizeof(N3BezierCoreElement));
        assert(newElement->previous == NULL);
        
        newBezierCore->elementList = newElement;
        elementCount++;
        
        prevNewElement = newElement;
        element = element->next;
    }
    
    while (element) {
        newElement = malloc(sizeof(N3BezierCoreElement));
        memcpy(newElement, element, sizeof(N3BezierCoreElement));
        
        prevNewElement->next = newElement;
        newElement->previous = prevNewElement;
        
        elementCount++;
        prevNewElement = newElement;
        element = element->next;
    }
    
    if (newElement) {
        newElement->next = NULL;
        newBezierCore->lastElement = newElement;
    }
    
    assert(elementCount == bezierCore->elementCount);
    newBezierCore->elementCount = bezierCore->elementCount;
    
    N3BezierCoreRetain(newBezierCore);

    N3BezierCoreCheckDebug(bezierCore);
    return newBezierCore;
}

CFDictionaryRef N3BezierCoreCreateDictionaryRepresentation(N3BezierCoreRef bezierCore)
{
	NSMutableArray *segments;
	NSDictionary *segmentDictionary;
	N3Vector control1;
	N3Vector control2;
	N3Vector endpoint;
	CFDictionaryRef control1Dict;
	CFDictionaryRef control2Dict;
	CFDictionaryRef endpointDict;
	N3BezierCoreSegmentType segmentType;
	N3BezierCoreIteratorRef bezierCoreIterator;
	
	segments = [NSMutableArray array];
	bezierCoreIterator = N3BezierCoreIteratorCreateWithBezierCore(bezierCore);
	
	while (N3BezierCoreIteratorIsAtEnd(bezierCoreIterator) == NO) {
		segmentType = N3BezierCoreIteratorGetNextSegment(bezierCoreIterator, &control1, &control2, &endpoint);
		control1Dict = N3VectorCreateDictionaryRepresentation(control1);
		control2Dict = N3VectorCreateDictionaryRepresentation(control2);
		endpointDict = N3VectorCreateDictionaryRepresentation(endpoint);
		switch (segmentType) {
			case N3MoveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"moveTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case N3LineToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"lineTo", @"segmentType", (id)endpointDict, @"endpoint", nil];
				break;
			case N3CloseBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"close", @"segmentType", (id)endpointDict, @"endpoint", nil];
                break;
            case N3CurveToBezierCoreSegmentType:
				segmentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"curveTo", @"segmentType", (id)control1Dict, @"control1",
									 (id)control2Dict, @"control2", (id)endpointDict, @"endpoint", nil];
				break;
			default:
				assert(0);
				break;
		}
		CFRelease(control1Dict);
		CFRelease(control2Dict);
		CFRelease(endpointDict);
		[segments addObject:segmentDictionary];
	}
	N3BezierCoreIteratorRelease(bezierCoreIterator);
	return (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:segments, @"segments", nil];
}

N3BezierCoreRef N3BezierCoreCreateWithDictionaryRepresentation(CFDictionaryRef dict)
{
	return N3BezierCoreCreateMutableWithDictionaryRepresentation(dict);
}

// we could make this a bit more robust against passing in junk
N3MutableBezierCoreRef N3BezierCoreCreateMutableWithDictionaryRepresentation(CFDictionaryRef dict)
{
	NSArray *segments;
	NSDictionary *segmentDictionary;
	N3MutableBezierCoreRef mutableBezierCore;
	N3Vector control1;
	N3Vector control2;
	N3Vector endpoint;
	
	segments = [(NSDictionary*)dict objectForKey:@"segments"];
	if (segments == nil) {
		return NULL;
	}
	
	mutableBezierCore = N3BezierCoreCreateMutable();
	
	for (segmentDictionary in segments) {
		if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"moveTo"]) {
			endpoint = N3VectorZero;
			N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			N3BezierCoreAddSegment(mutableBezierCore, N3MoveToBezierCoreSegmentType, N3VectorZero, N3VectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"lineTo"]) {
			endpoint = N3VectorZero;
			N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			N3BezierCoreAddSegment(mutableBezierCore, N3LineToBezierCoreSegmentType, N3VectorZero, N3VectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"close"]) {
			endpoint = N3VectorZero;
			N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			N3BezierCoreAddSegment(mutableBezierCore, N3CloseBezierCoreSegmentType, N3VectorZero, N3VectorZero, endpoint);
		} else if ([[segmentDictionary objectForKey:@"segmentType"] isEqualToString:@"curveTo"]) {
			control1 = N3VectorZero;
			control2 = N3VectorZero;
			endpoint = N3VectorZero;
			N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control1"], &control1);
			N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"control2"], &control2);
			N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[segmentDictionary objectForKey:@"endpoint"], &endpoint);
			N3BezierCoreAddSegment(mutableBezierCore, N3CurveToBezierCoreSegmentType, control1, control2, endpoint);
		} else {
			assert(0);
		}
	}
	
	N3BezierCoreCheckDebug(mutableBezierCore);
	
	return mutableBezierCore;
}


void N3BezierCoreAddSegment(N3MutableBezierCoreRef bezierCore, N3BezierCoreSegmentType segmentType, N3Vector control1, N3Vector control2, N3Vector endpoint)
{
    N3BezierCoreElementRef element;
    
    // if this is the first element, make sure it is a moveto
    assert(bezierCore->elementCount != 0 || segmentType == N3MoveToBezierCoreSegmentType);
	
	// if the previous element was a close, make sure the next element is a moveTo
	assert(bezierCore->elementCount == 0 || bezierCore->lastElement->segmentType != N3CloseBezierCoreSegmentType || segmentType == N3MoveToBezierCoreSegmentType);
	    
    element = malloc(sizeof(N3BezierCoreElement));
    memset(element, 0, sizeof(N3BezierCoreElement));
    
    element->segmentType = segmentType;
	element->previous = bezierCore->lastElement;
	if (segmentType == N3MoveToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == N3LineToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == N3CurveToBezierCoreSegmentType) {
		element->control1 = control1;
		element->control2 = control2;
		element->endpoint = endpoint;
	} else if (segmentType == N3CloseBezierCoreSegmentType) {
		element->endpoint = _N3BezierCoreLastMoveTo(bezierCore);
	}
	
    if (bezierCore->lastElement) {
        bezierCore->lastElement->next = element;
    }
    bezierCore->lastElement = element;
    if (bezierCore->elementList == NULL) {
        bezierCore->elementList = element;
    }
    
    bezierCore->elementCount++;
}

void N3BezierCoreSetVectorsForSegementAtIndex(N3MutableBezierCoreRef bezierCore, CFIndex index, N3Vector control1, N3Vector control2, N3Vector endpoint)
{
	N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor;
	
	bezierCoreRandomAccessor = N3BezierCoreRandomAccessorCreateWithMutableBezierCore(bezierCore);
	N3BezierCoreRandomAccessorSetVectorsForSegementAtIndex(bezierCoreRandomAccessor, index, control1, control2, endpoint);
	N3BezierCoreRandomAccessorRelease(bezierCoreRandomAccessor);
}

void N3BezierCoreSubdivide(N3MutableBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    N3BezierCoreElementRef element;
    N3BezierCoreElementRef lastElement;
    	
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (maxSegementLength == 0.0) {
        maxSegementLength = N3BezierDefaultSubdivideSegmentLength;
    }
    
    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_N3BezierCoreElementLength(element) > maxSegementLength) {
            _N3BezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    N3BezierCoreCheckDebug(bezierCore);    
}


void N3BezierCoreFlatten(N3MutableBezierCoreRef bezierCore, CGFloat flatness)
{
    N3BezierCoreElementRef element;
    N3BezierCoreElementRef lastElement;
    
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (flatness == 0.0) {
        flatness = N3BezierDefaultFlatness;
    }

    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_N3BezierCoreElementFlatness(element) > flatness) {
            _N3BezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            if (element->segmentType == N3CurveToBezierCoreSegmentType) {
                element->segmentType = N3LineToBezierCoreSegmentType;
                element->control1 = N3VectorZero;
                element->control2 = N3VectorZero;
            }
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    N3BezierCoreCheckDebug(bezierCore);
}

void N3BezierCoreApplyTransform(N3MutableBezierCoreRef bezierCore, N3AffineTransform transform)
{
    N3BezierCoreElementRef element;
    
    element = bezierCore->elementList;
    
    while (element) {
        element->endpoint = N3VectorApplyTransform(element->endpoint, transform);
		
		if (element->segmentType == N3CurveToBezierCoreSegmentType) {
			element->control1 = N3VectorApplyTransform(element->control1, transform);
			element->control2 = N3VectorApplyTransform(element->control2, transform);
		}
        element = element->next;
    }
    
    N3BezierCoreCheckDebug(bezierCore);
}

void N3BezierCoreAppendBezierCore(N3MutableBezierCoreRef bezierCore, N3BezierCoreRef appenedBezier, bool connectPaths)
{
    N3BezierCoreElementRef element;
    N3BezierCoreElementRef lastElement;
    
    element = appenedBezier->elementList;
    
    if (element != NULL && connectPaths) {
        element = element->next; // remove the first moveto
		
		if (bezierCore->lastElement->segmentType == N3CloseBezierCoreSegmentType) { // remove the last close if it is there
			bezierCore->lastElement->previous->next = NULL;
			lastElement = bezierCore->lastElement;
			bezierCore->lastElement = bezierCore->lastElement->previous;
			free(lastElement);
			bezierCore->elementCount -= 1;
		}
    }
    
    while (element) {
        N3BezierCoreAddSegment(bezierCore, element->segmentType, element->control1, element->control2, element->endpoint);
        element = element->next;
    }
    
    N3BezierCoreCheckDebug(bezierCore);
}

N3BezierCoreRef N3BezierCoreCreateFlattenedCopy(N3BezierCoreRef bezierCore, CGFloat flatness)
{
    return N3BezierCoreCreateFlattenedMutableCopy(bezierCore, flatness);
}

N3MutableBezierCoreRef N3BezierCoreCreateFlattenedMutableCopy(N3BezierCoreRef bezierCore, CGFloat flatness)
{
    N3MutableBezierCoreRef newBezierCore;
    
    newBezierCore = N3BezierCoreCreateMutableCopy(bezierCore);
    N3BezierCoreFlatten(newBezierCore, flatness);
    
    N3BezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}

N3BezierCoreRef N3BezierCoreCreateSubdividedCopy(N3BezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    return N3BezierCoreCreateSubdividedMutableCopy(bezierCore, maxSegementLength);
}

N3MutableBezierCoreRef N3BezierCoreCreateSubdividedMutableCopy(N3BezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    N3MutableBezierCoreRef newBezierCore;
    
    newBezierCore = N3BezierCoreCreateMutableCopy(bezierCore);
    N3BezierCoreSubdivide(newBezierCore, maxSegementLength);
    
    N3BezierCoreCheckDebug(newBezierCore);
    
    return newBezierCore;    
}    

N3BezierCoreRef N3BezierCoreCreateTransformedCopy(N3BezierCoreRef bezierCore, N3AffineTransform transform)
{
    return N3BezierCoreCreateTransformedMutableCopy(bezierCore, transform);
}

N3MutableBezierCoreRef N3BezierCoreCreateTransformedMutableCopy(N3BezierCoreRef bezierCore, N3AffineTransform transform)
{
    N3MutableBezierCoreRef newBezierCore;
    
    newBezierCore = N3BezierCoreCreateMutableCopy(bezierCore);
    N3BezierCoreApplyTransform(newBezierCore, transform);
    
    N3BezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}    

CFIndex N3BezierCoreSegmentCount(N3BezierCoreRef bezierCore)
{
    return bezierCore->elementCount;
}

CFIndex N3BezierCoreSubpathCount(N3BezierCoreRef bezierCore)
{
	N3BezierCoreElementRef element;
	CFIndex subpathCount;
	
	subpathCount = 0;
	element = bezierCore->elementList;
	while (element) {
		if (element->segmentType == N3MoveToBezierCoreSegmentType) {
			subpathCount++;
		}
		element = element->next;
	}
	
	return subpathCount;
}

CGFloat N3BezierCoreLength(N3BezierCoreRef bezierCore)
{
    N3BezierCoreElementRef element;
    N3BezierCoreRef flattenedBezierCore;
    N3Vector lastPoint;
    CGFloat length;
    
    if (bezierCore->elementList == NULL) {
        return 0.0;
    }
    
    lastPoint = bezierCore->elementList->endpoint;
    element = bezierCore->elementList->next;
    length = 0.0;
    
    while (element) {
        if (element->segmentType == N3CurveToBezierCoreSegmentType) {
            flattenedBezierCore = N3BezierCoreCreateFlattenedCopy(bezierCore, N3BezierDefaultFlatness);
            length = N3BezierCoreLength(flattenedBezierCore);
            N3BezierCoreRelease(flattenedBezierCore);
            return length;
        } else if (element->segmentType == N3LineToBezierCoreSegmentType || element->segmentType == N3CloseBezierCoreSegmentType) {
            length += N3VectorDistance(lastPoint, element->endpoint);
        }
        
        lastPoint = element->endpoint;
        element = element->next;
    }
    
    return length;
}

N3BezierCoreSegmentType N3BezierCoreGetSegmentAtIndex(N3BezierCoreRef bezierCore, CFIndex index, N3VectorPointer control1, N3VectorPointer control2, N3VectorPointer endpoint)
{
    N3BezierCoreElementRef element;
    CFIndex i;
    
    N3BezierCoreCheckDebug(bezierCore);

    assert (index < bezierCore->elementCount && index >= 0);
    
    if (index < bezierCore->elementCount / 2) {
        element = bezierCore->elementList;
        for (i = 1; i <= index; i++) {
            element = element->next;
        }
    } else {
        element = bezierCore->lastElement;
        for (i = bezierCore->elementCount - 2; i + 1 > index; i--) {
            element = element->previous;
        }
    }

    assert(element);
    
    if (control1) {
        *control1 = element->control1;
    }
    if (control2) {
        *control2 = element->control2;
    }
    if (endpoint) {
        *endpoint = element->endpoint;
    }

    return element->segmentType;
}

#pragma mark -
#pragma mark DEBUG


void N3BezierCoreCheckDebug(N3BezierCoreRef bezierCore)
{
#ifndef NDEBUG
    // the first segment must be a moveto
    // the member lastElement should really point to the last element
    // the number of elements in the list should really be elementCount
	// the endpoint of a close must be equal to the last moveTo;
	// the element right after a close must be a moveTo
    
    CFIndex elementCount;
    N3BezierCoreElementRef element;
    N3BezierCoreElementRef prevElement;
	N3Vector lastMoveTo;
	bool needsMoveTo;
    element = NULL;
	needsMoveTo = false;
    
    assert(bezierCore->retainCount > 0);
    if (bezierCore->elementList == NULL) {
        assert(bezierCore->elementCount == 0);
        assert(bezierCore->lastElement == NULL);
    } else {
        element = bezierCore->elementList;
        elementCount = 1;
        assert(element->previous == NULL);
        assert(element->segmentType == N3MoveToBezierCoreSegmentType);
		lastMoveTo = element->endpoint;
        
        while (element->next) {
            elementCount++;
            prevElement = element;
            element = element->next;
            assert(element->previous == prevElement);
            switch (element->segmentType) {
                case N3MoveToBezierCoreSegmentType:
					lastMoveTo = element->endpoint;
					needsMoveTo = false;
					break;
                case N3LineToBezierCoreSegmentType:
                case N3CurveToBezierCoreSegmentType:
					assert(needsMoveTo == false);
					break;
                case N3CloseBezierCoreSegmentType:
					assert(needsMoveTo == false);
					assert(N3VectorEqualToVector(element->endpoint, lastMoveTo));
					needsMoveTo = true;
                    break;
                default:
                    assert(0);
                    break;
            }
        }
        
        assert(bezierCore->elementCount == elementCount);
        assert(bezierCore->lastElement == element);
    }
#endif
}


#pragma mark -
#pragma mark N3BezierCoreIterator

N3BezierCoreIteratorRef N3BezierCoreIteratorCreateWithBezierCore(N3BezierCoreRef bezierCore)
{
    N3BezierCoreIteratorRef bezierCoreIterator;
    
    bezierCoreIterator = malloc(sizeof(N3BezierCoreIterator));
    memset(bezierCoreIterator, 0, sizeof(N3BezierCoreIterator));
    
    bezierCoreIterator->bezierCore = N3BezierCoreRetain(bezierCore);
    bezierCoreIterator->elementAtIndex = bezierCore->elementList;
    
    N3BezierCoreIteratorRetain(bezierCoreIterator);
    
    return bezierCoreIterator;
}

N3BezierCoreIteratorRef N3BezierCoreIteratorRetain(N3BezierCoreIteratorRef bezierCoreIterator)
{
    if (bezierCoreIterator) {
        OSAtomicIncrement32(&(bezierCoreIterator->retainCount));
    }
    return bezierCoreIterator;    
}

void N3BezierCoreIteratorRelease(N3BezierCoreIteratorRef bezierCoreIterator)
{    
    if (bezierCoreIterator) {
        assert(bezierCoreIterator->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(bezierCoreIterator->retainCount)) == 0) {
            N3BezierCoreRelease(bezierCoreIterator->bezierCore);
            free(bezierCoreIterator);
        }
    }
}

N3BezierCoreSegmentType N3BezierCoreIteratorGetNextSegment(N3BezierCoreIteratorRef bezierCoreIterator, N3VectorPointer control1, N3VectorPointer control2, N3VectorPointer endpoint)
{
    N3BezierCoreSegmentType segmentType;
    
    if (bezierCoreIterator->elementAtIndex == NULL) {
        if (control1) {
            *control1 = N3VectorZero;
        }
        if (control2) {
            *control2 = N3VectorZero;
        }
        if (endpoint) {
            *endpoint = N3VectorZero;
        }        
        return N3EndBezierCoreSegmentType;
    }
        
    if (control1) {
        *control1 = bezierCoreIterator->elementAtIndex->control1;
    }
    if (control2) {
        *control2 = bezierCoreIterator->elementAtIndex->control2;
    }
    if (endpoint) {
        *endpoint = bezierCoreIterator->elementAtIndex->endpoint;
    }
    
    segmentType = bezierCoreIterator->elementAtIndex->segmentType;
    
    bezierCoreIterator->index++;
    bezierCoreIterator->elementAtIndex = bezierCoreIterator->elementAtIndex->next;
    
    return segmentType;
}

bool N3BezierCoreIteratorIsAtEnd(N3BezierCoreIteratorRef bezierCoreIterator)
{
    return (bezierCoreIterator->elementAtIndex == NULL);
}

CFIndex N3BezierCoreIteratorIndex(N3BezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->index;
}

void N3BezierCoreIteratorSetIndex(N3BezierCoreIteratorRef bezierCoreIterator, CFIndex index)
{
    N3BezierCoreElementRef element;
    CFIndex i;
    
    assert (index < bezierCoreIterator->bezierCore->elementCount);
    
    if (index == bezierCoreIterator->index) {
        return;
    }
    
    element = bezierCoreIterator->bezierCore->elementList;
    
    for (i = 1; i <= index; i++) {
        element = element->next;
    }
    
    assert(element);
    
    bezierCoreIterator->elementAtIndex = element;
    bezierCoreIterator->index = index;
}

CFIndex N3BezierCoreIteratorSegmentCount(N3BezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->bezierCore->elementCount;
}

#pragma mark -
#pragma mark N3BezierCoreRandomAccessor

N3BezierCoreRandomAccessorRef N3BezierCoreRandomAccessorCreateWithBezierCore(N3BezierCoreRef bezierCore)
{
    N3BezierCoreRandomAccessor *bezierCoreRandomAccessor;
    N3BezierCoreElementRef element;
    CFIndex i;
    
    bezierCoreRandomAccessor = malloc(sizeof(N3BezierCoreRandomAccessor));
    memset(bezierCoreRandomAccessor, 0, sizeof(N3BezierCoreRandomAccessor));
    
    bezierCoreRandomAccessor->bezierCore = N3BezierCoreRetain(bezierCore); // this does the casting to mutable for us
    if (bezierCore->elementCount) {
        bezierCoreRandomAccessor->elementArray = malloc(sizeof(N3BezierCoreElementRef) * bezierCore->elementCount);
        
        element = bezierCore->elementList;
        bezierCoreRandomAccessor->elementArray[0] = element;
        
        for (i = 1; i < bezierCore->elementCount; i++) {
            element = element->next;
            bezierCoreRandomAccessor->elementArray[i] = element;
        }
    }
    
    N3BezierCoreRandomAccessorRetain(bezierCoreRandomAccessor);
    
    return bezierCoreRandomAccessor;
}

N3BezierCoreRandomAccessorRef N3BezierCoreRandomAccessorCreateWithMutableBezierCore(N3MutableBezierCoreRef bezierCore)
{
	N3BezierCoreRandomAccessor *bezierCoreRandomAccessor;
	
	bezierCoreRandomAccessor = (N3BezierCoreRandomAccessor *)N3BezierCoreRandomAccessorCreateWithBezierCore(bezierCore);
	bezierCoreRandomAccessor->mutableBezierCore = true;
	return bezierCoreRandomAccessor;
}

N3BezierCoreRandomAccessorRef N3BezierCoreRandomAccessorRetain(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    N3BezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (N3BezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        OSAtomicIncrement32(&(mutableBezierCoreRandomAccessor->retainCount));
    }
    return bezierCoreRandomAccessor;    
}

void N3BezierCoreRandomAccessorRelease(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    N3BezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (N3BezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        assert(bezierCoreRandomAccessor->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCoreRandomAccessor->retainCount)) == 0) {
            N3BezierCoreRelease(bezierCoreRandomAccessor->bezierCore);
            free(bezierCoreRandomAccessor->elementArray);
            free(mutableBezierCoreRandomAccessor);
        }
    }    
}

N3BezierCoreSegmentType N3BezierCoreRandomAccessorGetSegmentAtIndex(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, N3VectorPointer control1, N3VectorPointer control2, N3VectorPointer endpoint)
{
    N3BezierCoreElementRef element;
    
    if (index == bezierCoreRandomAccessor->bezierCore->elementCount) {
        return N3EndBezierCoreSegmentType;
    }

    assert (index <= bezierCoreRandomAccessor->bezierCore->elementCount);
    
    element = bezierCoreRandomAccessor->elementArray[index];
    
    if (control1) {
        *control1 = element->control1;
    }
    if (control2) {
        *control2 = element->control2;
    }
    if (endpoint) {
        *endpoint = element->endpoint;
    }
    
    return element->segmentType;
}

void N3BezierCoreRandomAccessorSetVectorsForSegementAtIndex(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, N3Vector control1, N3Vector control2, N3Vector endpoint)
{
    N3BezierCoreElementRef element;
	
	assert (bezierCoreRandomAccessor->mutableBezierCore);
    assert (index < bezierCoreRandomAccessor->bezierCore->elementCount);
	
	element = bezierCoreRandomAccessor->elementArray[index];
	switch (element->segmentType) {
		case N3MoveToBezierCoreSegmentType: // ouch figure out if there is a closepath later on, and update it too
			element->endpoint = endpoint;
			element = element->next;
			while (element) {
				if (element->segmentType == N3CloseBezierCoreSegmentType) {
					element->endpoint = endpoint;
					break;
				} else if (element->segmentType == N3MoveToBezierCoreSegmentType) {
					break;
				}
				element = element->next;
			}
			break;
		case N3LineToBezierCoreSegmentType:
			element->endpoint = endpoint;
			break;
		case N3CurveToBezierCoreSegmentType:
			element->control1 = control1;
			element->control2 = control2;
			element->endpoint = endpoint;
			break;
		case N3CloseBezierCoreSegmentType:
			break;
		default:
			assert(0);
			break;
	}
}

CFIndex N3BezierCoreRandomAccessorSegmentCount(N3BezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    return bezierCoreRandomAccessor->bezierCore->elementCount;
}


#pragma mark -
#pragma mark Private Methods

static CGFloat _N3BezierCoreElementLength(N3BezierCoreElementRef element) // only gives a very rough approximation for curved paths
{
    CGFloat distance;
    
    assert(element->segmentType == N3MoveToBezierCoreSegmentType || element->previous);

    distance = 0.0;
	
	switch (element->segmentType) {
		case N3LineToBezierCoreSegmentType:
		case N3CloseBezierCoreSegmentType:
			distance = N3VectorDistance(element->endpoint, element->previous->endpoint);
			break;
		case N3CurveToBezierCoreSegmentType:
			distance = N3VectorDistance(element->previous->endpoint, element->control1);
			distance += N3VectorDistance(element->control1, element->control2);
			distance += N3VectorDistance(element->control2, element->endpoint);			
			break;
		default:
			break;
	}
    
    return distance;
}


static CGFloat _N3BezierCoreElementFlatness(N3BezierCoreElementRef element)
{
    CGFloat flatness1;
    CGFloat endFlatness1;
    CGFloat flatness2;
    CGFloat endFlatness2;
    CGFloat maxFlatness;
    N3Vector line;
    CGFloat lineLength;
    N3Vector vectorToControl1;
    CGFloat control1ScalarProjection;
    N3Vector vectorToControl2;
    CGFloat control2ScalarProjection;
    
    if (element->segmentType != N3CurveToBezierCoreSegmentType) {
        return 0.0;
    }
    
    assert(element->previous);
    
    line = N3VectorSubtract(element->endpoint, element->previous->endpoint);
    vectorToControl1 = N3VectorSubtract(element->control1, element->previous->endpoint);
    vectorToControl2 = N3VectorSubtract(element->control2, element->endpoint);
    
    lineLength = N3VectorLength(line);
    
    control1ScalarProjection = N3VectorDotProduct(line, vectorToControl1) / lineLength;
    endFlatness1 = control1ScalarProjection * -1.0;
    flatness1 = N3VectorLength(N3VectorSubtract(vectorToControl1, N3VectorScalarMultiply(line, control1ScalarProjection / lineLength)));
    
    control2ScalarProjection = N3VectorDotProduct(line, vectorToControl2) / lineLength;
    endFlatness2 = control2ScalarProjection;
    flatness2 = N3VectorLength(N3VectorSubtract(vectorToControl2, N3VectorScalarMultiply(line, control2ScalarProjection / lineLength)));
    
    maxFlatness = flatness1;
    if (flatness2 > maxFlatness) {
        maxFlatness = flatness2;
    }
    if (endFlatness1 > maxFlatness) {
        maxFlatness = endFlatness1;
    }
    if (endFlatness2 > maxFlatness) {
        maxFlatness = endFlatness2;
    }
    
    return maxFlatness;
}

static void _N3BezierCoreElementDivide(N3BezierCoreElementRef element)
{
    N3BezierCoreElementRef newElement;
    N3Vector q0;
    N3Vector q1;
    N3Vector q2;
    N3Vector r0;
    N3Vector r1;
    N3Vector b;
    
	assert(element->segmentType != N3MoveToBezierCoreSegmentType); // it doesn't make any sense to divide a moveTo
    assert(element->segmentType == N3CurveToBezierCoreSegmentType || element->segmentType == N3LineToBezierCoreSegmentType || element->segmentType == N3CloseBezierCoreSegmentType);
    assert(element->previous); // there better be a previous so that the starting position is set.
    
    newElement = malloc(sizeof(N3BezierCoreElement));
    memset(newElement, 0, sizeof(N3BezierCoreElement));
    newElement->previous = element;
    newElement->next = element->next;
    newElement->endpoint = element->endpoint;
    newElement->segmentType = element->segmentType;

    
    if (element->next) {
        element->next->previous = newElement;
    }
    element->next = newElement;
    
    if (element->segmentType == N3LineToBezierCoreSegmentType) {
        element->endpoint = N3VectorScalarMultiply(N3VectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
    } else if (element->segmentType == N3CloseBezierCoreSegmentType) {
        element->endpoint = N3VectorScalarMultiply(N3VectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
		element->segmentType = N3LineToBezierCoreSegmentType;
		newElement->segmentType = N3CloseBezierCoreSegmentType;
    } else if (element->segmentType == N3CurveToBezierCoreSegmentType) {
        q0 = N3VectorScalarMultiply(N3VectorAdd(element->previous->endpoint, element->control1), 0.5);
        q1 = N3VectorScalarMultiply(N3VectorAdd(element->control1, element->control2), 0.5);
        q2 = N3VectorScalarMultiply(N3VectorAdd(element->control2, element->endpoint), 0.5);
        r0 = N3VectorScalarMultiply(N3VectorAdd(q0, q1), 0.5);
        r1 = N3VectorScalarMultiply(N3VectorAdd(q1, q2), 0.5);
        b = N3VectorScalarMultiply(N3VectorAdd(r0, r1), 0.5);
        
        newElement->control1 = r1;
        newElement->control2 = q2;
        element->control1 = q0;
        element->control2 = r0;
        element->endpoint = b;
    }
}

static bool _N3BezierCoreElementEqualToElement(N3BezierCoreElementRef element1, N3BezierCoreElementRef element2)
{
    if (element1 == element2) {
        return true;
    }
    
    if (element1->segmentType != element2->segmentType) {
        return false;
    }
    
    if (element1->segmentType == N3CurveToBezierCoreSegmentType) {
        return N3VectorEqualToVector(element1->endpoint, element2->endpoint) &&
                N3VectorEqualToVector(element1->control1, element2->control1) &&
                N3VectorEqualToVector(element1->control2, element2->control2);
	} else {
        return N3VectorEqualToVector(element1->endpoint, element2->endpoint);
    }
}

static N3Vector _N3BezierCoreLastMoveTo(N3BezierCoreRef bezierCore)
{
	N3BezierCoreElementRef element;
	N3Vector lastMoveTo;
	
	lastMoveTo = N3VectorZero;
	element = bezierCore->lastElement;
	
	while (element) {
		if (element->segmentType == N3MoveToBezierCoreSegmentType) {
			lastMoveTo = element->endpoint;
			break;
		}
		element = element->previous;
	}
	
	return lastMoveTo;
}


















