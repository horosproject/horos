/*
 *  CPRBezierCore.m
 *  OsiriX
 *
 *  Created by Joël Spaltenstein on 9/26/10.
 *  Copyright 2010 OsiriX Team. All rights reserved.
 *
 */

#include "CPRBezierCore.h"
#include <libkern/OSAtomic.h>

const CGFloat CPRBezierDefaultFlatness = 0.1;
const CGFloat CPRBezierDefaultSubdivideSegmentLength = 3;

typedef struct CPRBezierCoreElement *CPRBezierCoreElementRef; 

struct CPRBezierCore
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    CPRBezierCoreElementRef elementList;
    CPRBezierCoreElementRef lastElement;
    CFIndex elementCount;
};

struct CPRBezierCoreElement {
    CPRBezierCoreSegmentType segmentType;
    CPRVector control1;
    CPRVector control2;
    CPRVector endpoint;
    CPRBezierCoreElementRef next; // the last element has next set to NULL
    CPRBezierCoreElementRef previous; // the first element has previous set to NULL
};
typedef struct CPRBezierCoreElement CPRBezierCoreElement;

struct CPRBezierCoreIterator
{
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    CPRBezierCoreRef bezierCore;
    CFIndex index;
    CPRBezierCoreElementRef elementAtIndex;
};
typedef struct CPRBezierCoreIterator CPRBezierCoreIterator;

struct CPRBezierCoreRandomAccessor {
    volatile int32_t retainCount __attribute__ ((aligned (4)));
    CPRBezierCoreRef bezierCore;
    CPRBezierCoreElementRef *elementArray;
};
typedef struct CPRBezierCoreRandomAccessor CPRBezierCoreRandomAccessor;

static CGFloat _CPRBezierCoreElementLength(CPRBezierCoreElementRef element); // only gives a very rough approximation for curved paths, but the approximation is guaranteed to be the real length or longer
static CGFloat _CPRBezierCoreElementFlatness(CPRBezierCoreElementRef element);
static void _CPRBezierCoreElementDivide(CPRBezierCoreElementRef element);
static bool _CPRBezierCoreElementEqualToElement(CPRBezierCoreElementRef element1, CPRBezierCoreElementRef element2);
static CPRVector _CPRBezierCoreLastMoveTo(CPRBezierCoreRef bezierCore);

#pragma mark -
#pragma mark CPRBezierCore


CPRBezierCoreRef CPRBezierCoreCreate()
{
    return CPRBezierCoreCreateMutable();
}

CPRMutableBezierCoreRef CPRBezierCoreCreateMutable()
{
    CPRMutableBezierCoreRef bezierCore;

    bezierCore = malloc(sizeof(struct CPRBezierCore));
    memset(bezierCore, 0, sizeof(struct CPRBezierCore));
    
    CPRBezierCoreRetain(bezierCore);
    CPRBezierCoreCheckDebug(bezierCore);
    return bezierCore;
}

void *CPRBezierCoreRetain(CPRBezierCoreRef bezierCore)
{
    CPRMutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (CPRMutableBezierCoreRef)bezierCore;
    if (bezierCore) {
        OSAtomicIncrement32(&(mutableBezierCore->retainCount));
        CPRBezierCoreCheckDebug(bezierCore);
    }
    return mutableBezierCore;
}


void CPRBezierCoreRelease(CPRBezierCoreRef bezierCore)
{
    CPRMutableBezierCoreRef mutableBezierCore;
    mutableBezierCore = (CPRMutableBezierCoreRef)bezierCore;
    CPRBezierCoreElementRef element;
    CPRBezierCoreElementRef nextElement;
        
    if (bezierCore) {
        CPRBezierCoreCheckDebug(bezierCore);
        assert(bezierCore->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCore->retainCount)) == 0) {
            element = bezierCore->elementList;
            
            while (element) {
                nextElement = element->next;
                free(element);
                element = nextElement;
            }
            
            free((CPRMutableBezierCoreRef) bezierCore);
        }
    }
}

bool CPRBezierCoreEqualToBezierCore(CPRBezierCoreRef bezierCore1, CPRBezierCoreRef bezierCore2)
{
    CFIndex i;
    CPRBezierCoreElementRef element1;
    CPRBezierCoreElementRef element2;
    
    if (bezierCore1 == bezierCore2) {
        return true;
    }
    
    if (bezierCore1->elementCount != bezierCore2->elementCount) {
        return false;
    }

    element1 = bezierCore1->elementList;
    element2 = bezierCore2->elementList;
    
    while (element1) {
        if (_CPRBezierCoreElementEqualToElement(element1, element2) == false) {
            return false;
        }
        element1 = element1->next;
        element2 = element2->next;
    }
    
    return true;
}

bool CPRBezierCoreHasCurve(CPRBezierCoreRef bezierCore)
{
    CPRBezierCoreElementRef element;
    
    if (bezierCore->elementList == NULL) {
        return false;
    }
    
    element = bezierCore->elementList->next;
    
    while (element) {
        if (element->segmentType == CPRCurveToBezierCoreSegmentType) {
            return true;
        }
        element = element->next;
    }
    
    return false;
}

CPRBezierCoreRef CPRBezierCoreCreateCopy(CPRBezierCoreRef bezierCore)
{
    return CPRBezierCoreCreateMutableCopy(bezierCore);
}

CPRMutableBezierCoreRef CPRBezierCoreCreateMutableCopy(CPRBezierCoreRef bezierCore)
{
    CPRMutableBezierCoreRef newBezierCore;
    CPRBezierCoreElementRef element;
    CPRBezierCoreElementRef prevNewElement;
    CPRBezierCoreElementRef newElement;
    CFIndex elementCount;

    newBezierCore = malloc(sizeof(struct CPRBezierCore));
    memset(newBezierCore, 0, sizeof(struct CPRBezierCore));
    
    newElement = NULL;
    element = bezierCore->elementList;
    prevNewElement = 0;
    elementCount = 0;
    
    if (element) {
        newElement = malloc(sizeof(CPRBezierCoreElement));
        memcpy(newElement, element, sizeof(CPRBezierCoreElement));
        assert(newElement->previous == NULL);
        
        newBezierCore->elementList = newElement;
        elementCount++;
        
        prevNewElement = newElement;
        element = element->next;
    }
    
    while (element) {
        newElement = malloc(sizeof(CPRBezierCoreElement));
        memcpy(newElement, element, sizeof(CPRBezierCoreElement));
        
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
    
    CPRBezierCoreRetain(newBezierCore);

    CPRBezierCoreCheckDebug(bezierCore);
    return newBezierCore;
}

void CPRBezierCoreAddSegment(CPRMutableBezierCoreRef bezierCore, CPRBezierCoreSegmentType segmentType, CPRVector control1, CPRVector control2, CPRVector endpoint)
{
    CPRBezierCoreElementRef element;
    
    // if this is the first element, make sure it is a moveto
    assert((bezierCore->elementCount == 0 && segmentType != CPRMoveToBezierCoreSegmentType) == false);
	
	// if the previous element was a close, make sure the next element is a moveTo
	assert(bezierCore->elementCount == 0 || bezierCore->lastElement->segmentType != CPRCloseBezierCoreSegmentType || segmentType == CPRMoveToBezierCoreSegmentType);
	    
    element = malloc(sizeof(CPRBezierCoreElement));
    memset(element, 0, sizeof(CPRBezierCoreElement));
    
    element->segmentType = segmentType;
	element->previous = bezierCore->lastElement;
	if (segmentType == CPRMoveToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == CPRLineToBezierCoreSegmentType) {
		element->endpoint = endpoint;
	} else if (segmentType == CPRCurveToBezierCoreSegmentType) {
		element->control1 = control1;
		element->control2 = control2;
		element->endpoint = endpoint;
	} else if (segmentType == CPRCloseBezierCoreSegmentType) {
		element->endpoint = _CPRBezierCoreLastMoveTo(bezierCore);
	}
	
    if (bezierCore->lastElement) {
        bezierCore->lastElement->next = element;
    }
    bezierCore->lastElement = element;
    if (bezierCore->elementList == NULL) {
        bezierCore->elementList = element;
    }
    
    bezierCore->elementCount++;
    
//    CPRBezierCoreCheckDebug(bezierCore);
}

void CPRBezierCoreSubdivide(CPRMutableBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    CPRBezierCoreElementRef element;
    CPRBezierCoreElementRef lastElement;
    	
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (maxSegementLength == 0.0) {
        maxSegementLength = CPRBezierDefaultSubdivideSegmentLength;
    }
    
    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_CPRBezierCoreElementLength(element) > maxSegementLength) {
            _CPRBezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    CPRBezierCoreCheckDebug(bezierCore);    
}


void CPRBezierCoreFlatten(CPRMutableBezierCoreRef bezierCore, CGFloat flatness)
{
    CPRBezierCoreElementRef element;
    CPRBezierCoreElementRef lastElement;
    
    if (bezierCore->elementCount < 2) {
        return;
    }
    
    if (flatness == 0.0) {
        flatness = CPRBezierDefaultFlatness;
    }

    element = bezierCore->elementList->next;
    lastElement = NULL;
    while (element) {
        if (_CPRBezierCoreElementFlatness(element) > flatness) {
            _CPRBezierCoreElementDivide(element);
            bezierCore->elementCount++;
        } else {
            if (element->segmentType == CPRCurveToBezierCoreSegmentType) {
                element->segmentType = CPRLineToBezierCoreSegmentType;
                element->control1 = CPRVectorZero;
                element->control2 = CPRVectorZero;
            }
            lastElement = element;
            element = element->next;
        }
    }
    bezierCore->lastElement = lastElement;
    
    CPRBezierCoreCheckDebug(bezierCore);
}

void CPRBezierCoreApplyTransform(CPRMutableBezierCoreRef bezierCore, CPRAffineTransform3D transform)
{
    CPRBezierCoreElementRef element;
    
    element = bezierCore->elementList;
    
    while (element) {
        element->endpoint = CPRVectorApplyTransform(element->endpoint, transform);
		
		if (element->segmentType == CPRCurveToBezierCoreSegmentType) {
			element->control1 = CPRVectorApplyTransform(element->control1, transform);
			element->control2 = CPRVectorApplyTransform(element->control2, transform);
		}
        element = element->next;
    }
    
    CPRBezierCoreCheckDebug(bezierCore);
}

void CPRBezierCoreAppendBezierCore(CPRMutableBezierCoreRef bezierCore, CPRBezierCoreRef appenedBezier, bool connectPaths)
{
    CPRBezierCoreElementRef element;
    CPRBezierCoreElementRef lastElement;
    
    element = appenedBezier->elementList;
    
    if (element != NULL && connectPaths) {
        element = element->next; // remove the first moveto
		
		if (bezierCore->lastElement->segmentType == CPRCloseBezierCoreSegmentType) { // remove the last close if it is there
			bezierCore->lastElement->previous->next = NULL;
			lastElement = bezierCore->lastElement;
			bezierCore->lastElement = bezierCore->lastElement->previous;
			free(lastElement);
			bezierCore->elementCount -= 1;
		}
    }
    
    while (element) {
        CPRBezierCoreAddSegment(bezierCore, element->segmentType, element->control1, element->control2, element->endpoint);
        element = element->next;
    }
    
    CPRBezierCoreCheckDebug(bezierCore);
}

CPRBezierCoreRef CPRBezierCoreCreateFlattenedCopy(CPRBezierCoreRef bezierCore, CGFloat flatness)
{
    return CPRBezierCoreCreateFlattenedMutableCopy(bezierCore, flatness);
}

CPRMutableBezierCoreRef CPRBezierCoreCreateFlattenedMutableCopy(CPRBezierCoreRef bezierCore, CGFloat flatness)
{
    CPRMutableBezierCoreRef newBezierCore;
    
    newBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
    CPRBezierCoreFlatten(newBezierCore, flatness);
    
    CPRBezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}

CPRBezierCoreRef CPRBezierCoreCreateSubdividedCopy(CPRBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    return CPRBezierCoreCreateSubdividedMutableCopy(bezierCore, maxSegementLength);
}

CPRMutableBezierCoreRef CPRBezierCoreCreateSubdividedMutableCopy(CPRBezierCoreRef bezierCore, CGFloat maxSegementLength)
{
    CPRMutableBezierCoreRef newBezierCore;
    
    newBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
    CPRBezierCoreSubdivide(newBezierCore, maxSegementLength);
    
    CPRBezierCoreCheckDebug(newBezierCore);
    
    return newBezierCore;    
}    

CPRBezierCoreRef CPRBezierCoreCreateTransformedCopy(CPRBezierCoreRef bezierCore, CPRAffineTransform3D transform)
{
    return CPRBezierCoreCreateTransformedMutableCopy(bezierCore, transform);
}

CPRMutableBezierCoreRef CPRBezierCoreCreateTransformedMutableCopy(CPRBezierCoreRef bezierCore, CPRAffineTransform3D transform)
{
    CPRMutableBezierCoreRef newBezierCore;
    
    newBezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
    CPRBezierCoreApplyTransform(newBezierCore, transform);
    
    CPRBezierCoreCheckDebug(newBezierCore);

    return newBezierCore;    
}    

CFIndex CPRBezierCoreSegmentCount(CPRBezierCoreRef bezierCore)
{
    return bezierCore->elementCount;
}

CFIndex CPRBezierCoreSubpathCount(CPRBezierCoreRef bezierCore)
{
	CPRBezierCoreElementRef element;
	CFIndex subpathCount;
	
	subpathCount = 0;
	element = bezierCore->elementList;
	while (element) {
		if (element->segmentType == CPRMoveToBezierCoreSegmentType) {
			subpathCount++;
		}
		element = element->next;
	}
	
	return subpathCount;
}

CGFloat CPRBezierCoreLength(CPRBezierCoreRef bezierCore)
{
    CPRBezierCoreElementRef element;
    CPRBezierCoreRef flattenedBezierCore;
    CPRVector lastPoint;
    CGFloat length;
    
    if (bezierCore->elementList == NULL) {
        return 0.0;
    }
    
    lastPoint = bezierCore->elementList->endpoint;
    element = bezierCore->elementList->next;
    length = 0.0;
    
    while (element) {
        if (element->segmentType == CPRCurveToBezierCoreSegmentType) {
            flattenedBezierCore = CPRBezierCoreCreateFlattenedCopy(bezierCore, CPRBezierDefaultFlatness);
            length = CPRBezierCoreLength(flattenedBezierCore);
            CPRBezierCoreRelease(flattenedBezierCore);
            return length;
        } else if (element->segmentType == CPRLineToBezierCoreSegmentType || element->segmentType == CPRCloseBezierCoreSegmentType) {
            length += CPRVectorDistance(lastPoint, element->endpoint);
        }
        
        lastPoint = element->endpoint;
        element = element->next;
    }
    
    return length;
}

CPRBezierCoreSegmentType CPRBezierCoreGetSegmentAtIndex(CPRBezierCoreRef bezierCore, CFIndex index, CPRVectorPointer control1, CPRVectorPointer control2, CPRVectorPointer endpoint)
{
    CPRBezierCoreElementRef element;
    CFIndex i;
    
    CPRBezierCoreCheckDebug(bezierCore);

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

void CPRBezierCoreCheckDebug(CPRBezierCoreRef bezierCore)
{
    // the first segment must be a moveto
    // the member lastElement should really point to the last element
    // the number of elements in the list should really be elementCount
	// the endpoint of a close must be equal to the last moveTo;
	// the element right after a close must be a moveTo
    
    CFIndex elementCount;
    CPRBezierCoreElementRef element;
    CPRBezierCoreElementRef prevElement;
	CPRVector lastMoveTo;
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
        assert(element->segmentType == CPRMoveToBezierCoreSegmentType);
		lastMoveTo = element->endpoint;
        
        while (element->next) {
            elementCount++;
            prevElement = element;
            element = element->next;
            assert(element->previous == prevElement);
            switch (element->segmentType) {
                case CPRMoveToBezierCoreSegmentType:
					lastMoveTo = element->endpoint;
					needsMoveTo = false;
					break;
                case CPRLineToBezierCoreSegmentType:
                case CPRCurveToBezierCoreSegmentType:
					assert(needsMoveTo == false);
					break;
                case CPRCloseBezierCoreSegmentType:
					assert(needsMoveTo == false);
					assert(CPRVectorEqualToVector(element->endpoint, lastMoveTo));
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
}

#pragma mark -
#pragma mark CPRBezierCoreIterator

CPRBezierCoreIteratorRef CPRBezierCoreIteratorCreateWithBezierCore(CPRBezierCoreRef bezierCore)
{
    CPRBezierCoreIteratorRef bezierCoreIterator;
    
    bezierCoreIterator = malloc(sizeof(CPRBezierCoreIterator));
    memset(bezierCoreIterator, 0, sizeof(CPRBezierCoreIterator));
    
    bezierCoreIterator->bezierCore = CPRBezierCoreRetain(bezierCore);
    bezierCoreIterator->elementAtIndex = bezierCore->elementList;
    
    CPRBezierCoreIteratorRetain(bezierCoreIterator);
    
    return bezierCoreIterator;
}

CPRBezierCoreIteratorRef CPRBezierCoreIteratorRetain(CPRBezierCoreIteratorRef bezierCoreIterator)
{
    if (bezierCoreIterator) {
        OSAtomicIncrement32(&(bezierCoreIterator->retainCount));
    }
    return bezierCoreIterator;    
}

void CPRBezierCoreIteratorRelease(CPRBezierCoreIteratorRef bezierCoreIterator)
{    
    if (bezierCoreIterator) {
        assert(bezierCoreIterator->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(bezierCoreIterator->retainCount)) == 0) {
            CPRBezierCoreRelease(bezierCoreIterator->bezierCore);
            free(bezierCoreIterator);
        }
    }
}

CPRBezierCoreSegmentType CPRBezierCoreIteratorGetNextSegment(CPRBezierCoreIteratorRef bezierCoreIterator, CPRVectorPointer control1, CPRVectorPointer control2, CPRVectorPointer endpoint)
{
    CPRBezierCoreSegmentType segmentType;
    
    if (bezierCoreIterator->elementAtIndex == NULL) {
        if (control1) {
            *control1 = CPRVectorZero;
        }
        if (control2) {
            *control2 = CPRVectorZero;
        }
        if (endpoint) {
            *endpoint = CPRVectorZero;
        }        
        return CPREndBezierCoreSegmentType;
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

bool CPRBezierCoreIteratorIsAtEnd(CPRBezierCoreIteratorRef bezierCoreIterator)
{
    return (bezierCoreIterator->elementAtIndex == NULL);
}

CFIndex CPRBezierCoreIteratorIndex(CPRBezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->index;
}

void CPRBezierCoreIteratorSetIndex(CPRBezierCoreIteratorRef bezierCoreIterator, CFIndex index)
{
    CPRBezierCoreElementRef element;
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

CFIndex CPRBezierCoreIteratorSegmentCount(CPRBezierCoreIteratorRef bezierCoreIterator)
{
    return bezierCoreIterator->bezierCore->elementCount;
}

#pragma mark -
#pragma mark CPRBezierCoreRandomAccessor

CPRBezierCoreRandomAccessorRef CPRBezierCoreRandomAccessorCreateWithBezierCore(CPRBezierCoreRef bezierCore)
{
    CPRBezierCoreRandomAccessor *bezierCoreRandomAccessor;
    CPRBezierCoreElementRef element;
    CFIndex i;
    
    bezierCoreRandomAccessor = malloc(sizeof(CPRBezierCoreRandomAccessor));
    memset(bezierCoreRandomAccessor, 0, sizeof(CPRBezierCoreRandomAccessor));
    
    bezierCoreRandomAccessor->bezierCore = CPRBezierCoreRetain(bezierCore);
    if (bezierCore->elementCount) {
        bezierCoreRandomAccessor->elementArray = malloc(sizeof(CPRBezierCoreElementRef) * bezierCore->elementCount);
        
        element = bezierCore->elementList;
        bezierCoreRandomAccessor->elementArray[0] = element;
        
        for (i = 1; i < bezierCore->elementCount; i++) {
            element = element->next;
            bezierCoreRandomAccessor->elementArray[i] = element;
        }
    }
    
    CPRBezierCoreRandomAccessorRetain(bezierCoreRandomAccessor);
    
    return bezierCoreRandomAccessor;
}


CPRBezierCoreRandomAccessorRef CPRBezierCoreRandomAccessorRetain(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    CPRBezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (CPRBezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        OSAtomicIncrement32(&(mutableBezierCoreRandomAccessor->retainCount));
    }
    return bezierCoreRandomAccessor;    
}

void CPRBezierCoreRandomAccessorRelease(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    CPRBezierCoreRandomAccessor *mutableBezierCoreRandomAccessor;
    mutableBezierCoreRandomAccessor = (CPRBezierCoreRandomAccessor *)bezierCoreRandomAccessor;
    
    if (bezierCoreRandomAccessor) {
        assert(bezierCoreRandomAccessor->retainCount > 0);
        if (OSAtomicDecrement32Barrier(&(mutableBezierCoreRandomAccessor->retainCount)) == 0) {
            CPRBezierCoreRelease(bezierCoreRandomAccessor->bezierCore);
            free(bezierCoreRandomAccessor->elementArray);
            free(mutableBezierCoreRandomAccessor);
        }
    }    
}

CPRBezierCoreSegmentType CPRBezierCoreRandomAccessorGetSegmentAtIndex(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor, CFIndex index, CPRVectorPointer control1, CPRVectorPointer control2, CPRVectorPointer endpoint)
{
    CPRBezierCoreElementRef element;
    
    if (index == bezierCoreRandomAccessor->bezierCore->elementCount) {
        return CPREndBezierCoreSegmentType;
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

CFIndex CPRBezierCoreRandomAccessorSegmentCount(CPRBezierCoreRandomAccessorRef bezierCoreRandomAccessor)
{
    return bezierCoreRandomAccessor->bezierCore->elementCount;
}


#pragma mark -
#pragma mark Private Methods

static CGFloat _CPRBezierCoreElementLength(CPRBezierCoreElementRef element) // only gives a very rough approximation for curved paths
{
    CGFloat distance;
    
    assert(element->segmentType == CPRMoveToBezierCoreSegmentType || element->previous);

    distance = 0.0;
	
	switch (element->segmentType) {
		case CPRLineToBezierCoreSegmentType:
		case CPRCloseBezierCoreSegmentType:
			distance = CPRVectorDistance(element->endpoint, element->previous->endpoint);
			break;
		case CPRCurveToBezierCoreSegmentType:
			distance = CPRVectorDistance(element->previous->endpoint, element->control1);
			distance += CPRVectorDistance(element->control1, element->control2);
			distance += CPRVectorDistance(element->control2, element->endpoint);			
			break;
		default:
			break;
	}
    
    return distance;
}


static CGFloat _CPRBezierCoreElementFlatness(CPRBezierCoreElementRef element)
{
    CGFloat flatness1;
    CGFloat endFlatness1;
    CGFloat flatness2;
    CGFloat endFlatness2;
    CGFloat maxFlatness;
    CPRVector line;
    CGFloat lineLength;
    CPRVector vectorToControl1;
    CGFloat control1ScalarProjection;
    CPRVector vectorToControl2;
    CGFloat control2ScalarProjection;
    
    if (element->segmentType != CPRCurveToBezierCoreSegmentType) {
        return 0.0;
    }
    
    assert(element->previous);
    
    line = CPRVectorSubtract(element->endpoint, element->previous->endpoint);
    vectorToControl1 = CPRVectorSubtract(element->control1, element->previous->endpoint);
    vectorToControl2 = CPRVectorSubtract(element->control2, element->endpoint);
    
    lineLength = CPRVectorLength(line);
    
    control1ScalarProjection = CPRVectorDotProduct(line, vectorToControl1) / lineLength;
    endFlatness1 = control1ScalarProjection * -1.0;
    flatness1 = CPRVectorLength(CPRVectorSubtract(vectorToControl1, CPRVectorScalarMultiply(line, control1ScalarProjection / lineLength)));
    
    control2ScalarProjection = CPRVectorDotProduct(line, vectorToControl2) / lineLength;
    endFlatness2 = control2ScalarProjection;
    flatness2 = CPRVectorLength(CPRVectorSubtract(vectorToControl2, CPRVectorScalarMultiply(line, control2ScalarProjection / lineLength)));
    
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

static void _CPRBezierCoreElementDivide(CPRBezierCoreElementRef element)
{
    CPRBezierCoreElementRef newElement;
    CPRVector q0;
    CPRVector q1;
    CPRVector q2;
    CPRVector r0;
    CPRVector r1;
    CPRVector b;
    
	assert(element->segmentType != CPRMoveToBezierCoreSegmentType); // it doesn't make any sense to divide a moveTo
    assert(element->segmentType == CPRCurveToBezierCoreSegmentType || element->segmentType == CPRLineToBezierCoreSegmentType);
    assert(element->previous); // there better be a previous so that the starting position is set.
    
    newElement = malloc(sizeof(CPRBezierCoreElement));
    memset(newElement, 0, sizeof(CPRBezierCoreElement));
    newElement->previous = element;
    newElement->next = element->next;
    newElement->endpoint = element->endpoint;
    newElement->segmentType = element->segmentType;

    
    if (element->next) {
        element->next->previous = newElement;
    }
    element->next = newElement;
    
    if (element->segmentType == CPRLineToBezierCoreSegmentType) {
        element->endpoint = CPRVectorScalarMultiply(CPRVectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
    } else if (element->segmentType == CPRCloseBezierCoreSegmentType) {
        element->endpoint = CPRVectorScalarMultiply(CPRVectorAdd(element->previous->endpoint, newElement->endpoint), 0.5);
		element->segmentType = CPRLineToBezierCoreSegmentType;
		newElement->segmentType = CPRCloseBezierCoreSegmentType;
    } else if (element->segmentType == CPRCurveToBezierCoreSegmentType) {
        q0 = CPRVectorScalarMultiply(CPRVectorAdd(element->previous->endpoint, element->control1), 0.5);
        q1 = CPRVectorScalarMultiply(CPRVectorAdd(element->control1, element->control2), 0.5);
        q2 = CPRVectorScalarMultiply(CPRVectorAdd(element->control2, element->endpoint), 0.5);
        r0 = CPRVectorScalarMultiply(CPRVectorAdd(q0, q1), 0.5);
        r1 = CPRVectorScalarMultiply(CPRVectorAdd(q1, q2), 0.5);
        b = CPRVectorScalarMultiply(CPRVectorAdd(r0, r1), 0.5);
        
        newElement->control1 = r1;
        newElement->control2 = q2;
        element->control1 = q0;
        element->control2 = r0;
        element->endpoint = b;
    }
}

static bool _CPRBezierCoreElementEqualToElement(CPRBezierCoreElementRef element1, CPRBezierCoreElementRef element2)
{
    if (element1 == element2) {
        return true;
    }
    
    if (element1->segmentType != element2->segmentType) {
        return false;
    }
    
    if (element1->segmentType == CPRCurveToBezierCoreSegmentType) {
        return CPRVectorEqualToVector(element1->endpoint, element2->endpoint) &&
                CPRVectorEqualToVector(element1->control1, element2->control1) &&
                CPRVectorEqualToVector(element1->control2, element2->control2);
	} else {
        return CPRVectorEqualToVector(element1->endpoint, element2->endpoint);
    }
}

static CPRVector _CPRBezierCoreLastMoveTo(CPRBezierCoreRef bezierCore)
{
	CPRBezierCoreElementRef element;
	CPRVector lastMoveTo;
	
	lastMoveTo = CPRVectorZero;
	element = bezierCore->lastElement;
	
	while (element) {
		if (element->segmentType == CPRCloseBezierCoreSegmentType) {
			lastMoveTo = element->endpoint;
			break;
		}
		element = element->previous;
	}
	
	return lastMoveTo;
}


















