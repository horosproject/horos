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

#import "CPRBezierPath.h"
#import "CPRGeometry.h"
#import "CPRBezierCore.h"
#import "CPRBezierCoreAdditions.h"

@interface _CPRBezierCoreSteward : NSObject
{
	CPRBezierCoreRef _bezierCore;
}

- (id)initWithCPRBezierCore:(CPRBezierCoreRef)bezierCore;
- (CPRBezierCoreRef)CPRBezierCore;

@end

@implementation _CPRBezierCoreSteward

- (id)initWithCPRBezierCore:(CPRBezierCoreRef)bezierCore
{
	if ( (self = [super init]) ) {
		_bezierCore	= CPRBezierCoreRetain(bezierCore);
	}
	return self;
}

- (CPRBezierCoreRef)CPRBezierCore
{
	return _bezierCore;
}

- (void)dealloc
{
	CPRBezierCoreRelease(_bezierCore);
	_bezierCore = nil;
	[super dealloc];
}
				  
@end



@implementation CPRBezierPath

- (id)init
{
    if ( (self = [super init]) ) {
        _bezierCore = CPRBezierCoreCreateMutable();
    }
    return self;
}

- (id)initWithBezierPath:(CPRBezierPath *)bezierPath
{
    if ( (self = [super init]) ) {
        _bezierCore = CPRBezierCoreCreateMutableCopy([bezierPath CPRBezierCore]);
		_length = bezierPath->_length;
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict
{
	if ( (self = [super init]) ) {
		_bezierCore = CPRBezierCoreCreateMutableWithDictionaryRepresentation((CFDictionaryRef)dict);
		if (_bezierCore == nil) {
			[self autorelease];
			return nil;
		}
	}
	return self;
}

- (id)initWithCPRBezierCore:(CPRBezierCoreRef)bezierCore
{
    if ( (self = [super init]) ) {
        _bezierCore = CPRBezierCoreCreateMutableCopy(bezierCore);
    }
    return self;
}

- (id)initWithNodeArray:(NSArray *)nodes // array of CPRVectors in NSValues;
{
    CPRVectorArray vectorArray;
    NSInteger i;
    
    if ( (self = [super init]) ) {
		if ([nodes count] >= 2) {
			vectorArray = malloc(sizeof(CPRVector) * [nodes count]);
			
			for (i = 0; i < [nodes count]; i++) {
				vectorArray[i] = [[nodes objectAtIndex:i] CPRVectorValue];
			}
			
			_bezierCore = CPRBezierCoreCreateMutableCurveWithNodes(vectorArray, [nodes count]);
			
			free(vectorArray);
		} else if ([nodes count] == 0) {
			_bezierCore = CPRBezierCoreCreateMutable();
		} else {
			_bezierCore = CPRBezierCoreCreateMutable();
			CPRBezierCoreAddSegment(_bezierCore, CPRMoveToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, [[nodes objectAtIndex:0] CPRVectorValue]);
			if ([nodes count] > 1) {
				CPRBezierCoreAddSegment(_bezierCore, CPRLineToBezierCoreSegmentType, CPRVectorZero, CPRVectorZero, [[nodes objectAtIndex:1] CPRVectorValue]);
			}
		}

        
        if (_bezierCore == NULL) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	NSDictionary *bezierDict;
	
	bezierDict = [decoder decodeObjectForKey:@"bezierPathDictionaryRepresentation"];
	
	if ( (self = [self initWithDictionaryRepresentation:bezierDict]) ) {
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CPRMutableBezierPath *bezierPath;
    
    bezierPath = [[CPRMutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    CPRMutableBezierPath *bezierPath;
    
    bezierPath = [[CPRMutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

+ (id)bezierPath
{
    return [[[[self class] alloc] init] autorelease];
}

+ (id)bezierPathWithBezierPath:(CPRBezierPath *)bezierPath
{
    return [[[[self class] alloc] initWithBezierPath:bezierPath] autorelease];
}

+ (id)bezierPathCPRBezierCore:(CPRBezierCoreRef)bezierCore
{
    return [[[[self class] alloc] initWithCPRBezierCore:bezierCore] autorelease];
}

- (void)dealloc
{
    CPRBezierCoreRelease(_bezierCore);
    _bezierCore = nil;
    CPRBezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = nil;
    
    [super dealloc];
}

- (BOOL)isEqualToBezierPath:(CPRBezierPath *)bezierPath
{
    if (self == bezierPath) {
        return YES;
    }
    
    return CPRBezierCoreEqualToBezierCore(_bezierCore, [bezierPath CPRBezierCore]);
}

- (BOOL)isEqual:(id)anObject
{
    if ([anObject isKindOfClass:[CPRBezierPath class]]) {
        return [self isEqualToBezierPath:(CPRBezierPath *)anObject];
    }
    return NO;
}

- (NSUInteger)hash
{
    return CPRBezierCoreSegmentCount(_bezierCore);
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[self dictionaryRepresentation] forKey:@"bezierPathDictionaryRepresentation"];
}

- (CPRBezierPath *)bezierPathByFlattening:(CGFloat)flatness
{
    CPRMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath flatten:flatness];
    return newBezierPath;
}

- (CPRBezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
{
    CPRMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath subdivide:maxSegmentLength];
    return newBezierPath;
}

- (CPRBezierPath *)bezierPathByApplyingTransform:(CPRAffineTransform3D)transform
{
    CPRMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath applyAffineTransform:transform];
    return newBezierPath;
}

- (CPRBezierPath *)bezierPathByAppendingBezierPath:(CPRBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
{
    CPRMutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath appendBezierPath:bezierPath connectPaths:connectPaths];
    return newBezierPath;
}

- (CPRBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(CPRVector)initalNormal spacing:(CGFloat)spacing;
{
    CPRBezierPath *outlinePath;
    CPRBezierCoreRef outlineCore;
    
	if (CPRBezierCoreSubpathCount(_bezierCore) != 1) {
		return nil;
	}
	
    outlineCore = CPRBezierCoreCreateOutline(_bezierCore, distance, spacing, initalNormal);
    outlinePath = [[CPRBezierPath alloc] initWithCPRBezierCore:outlineCore];
    CPRBezierCoreRelease(outlineCore);
    return [outlinePath autorelease];
}

- (NSInteger)elementCount
{
    return CPRBezierCoreSegmentCount(_bezierCore);
}

- (CGFloat)length
{
	@synchronized (self) {
		if (_length	== 0.0) {
			_length = CPRBezierCoreLength(_bezierCore);
		}
	}
	return _length;
}

- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element
{
    return CPRBezierCoreLengthToSegmentAtIndex(_bezierCore, element, CPRBezierDefaultFlatness);
}

- (CPRBezierCoreRef)CPRBezierCore
{
	_CPRBezierCoreSteward *bezierCoreSteward;
	CPRBezierCoreRef copy;
	copy = CPRBezierCoreCreateCopy(_bezierCore);
	bezierCoreSteward = [[_CPRBezierCoreSteward alloc] initWithCPRBezierCore:copy];
	CPRBezierCoreRelease(copy);
	[bezierCoreSteward autorelease];
    return [bezierCoreSteward CPRBezierCore];
}

- (NSDictionary *)dictionaryRepresentation
{
	return [(NSDictionary *)CPRBezierCoreCreateDictionaryRepresentation(_bezierCore) autorelease];
}

- (CPRVector)vectorAtStart
{
    return CPRBezierCoreVectorAtStart(_bezierCore);
}

- (CPRVector)vectorAtEnd
{
    return CPRBezierCoreVectorAtEnd(_bezierCore);
}

- (CPRVector)tangentAtStart
{
    return CPRBezierCoreTangentAtStart(_bezierCore);
}

- (CPRVector)tangentAtEnd
{
    return CPRBezierCoreTangentAtEnd(_bezierCore);
}

- (CPRVector)normalAtEndWithInitialNormal:(CPRVector)initialNormal
{
	if (CPRBezierCoreSubpathCount(_bezierCore) != 1) {
		return CPRVectorZero;
	}
	
    return CPRBezierCoreNormalAtEndWithInitialNormal(_bezierCore, initialNormal);
}

- (CPRBezierPathElement)elementAtIndex:(NSInteger)index
{
    return [self elementAtIndex:index control1:NULL control2:NULL endpoint:NULL];
}

- (CPRBezierPathElement)elementAtIndex:(NSInteger)index control1:(CPRVectorPointer)control1 control2:(CPRVectorPointer)control2 endpoint:(CPRVectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is always the end
{
    CPRBezierCoreSegmentType segmentType;
    CPRVector control1Vector;
    CPRVector control2Vector;
    CPRVector endpointVector;
    
    @synchronized (self) {
        if (_bezierCoreRandomAccessor == NULL) {
            _bezierCoreRandomAccessor = CPRBezierCoreRandomAccessorCreateWithMutableBezierCore(_bezierCore);
        }
    }
    
    segmentType = CPRBezierCoreRandomAccessorGetSegmentAtIndex(_bezierCoreRandomAccessor, index, &control1Vector,  &control2Vector, &endpointVector);
    
    switch (segmentType) {
        case CPRMoveToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return CPRMoveToBezierPathElement;
        case CPRLineToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return CPRLineToBezierPathElement;
        case CPRCurveToBezierCoreSegmentType:
            if (control1) {
                *control1 = control1Vector;
            }
            if (control2) {
                *control2 = control2Vector;
            }
            if (endpoint) {
                *endpoint = endpointVector;
            }
            return CPRCurveToBezierPathElement;
		case CPRCloseBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return CPRCloseBezierPathElement;
    }
    assert(0);
    return 0;
}

- (CPRVector)vectorAtRelativePosition:(CGFloat)relativePosition // RelativePosition is in [0, 1]
{
    CPRVector vector;
    
    if (CPRBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], CPRVectorZero, &vector, NULL, NULL, 1)) {
        return vector;
    } else {
        return [self vectorAtEnd];
    }
}

- (CPRVector)tangentAtRelativePosition:(CGFloat)relativePosition
{
    CPRVector tangent;
    
    if (CPRBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], CPRVectorZero, NULL, &tangent, NULL, 1)) {
        return tangent;
    } else {
        return [self tangentAtEnd];
    }    
}

- (CPRVector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(CPRVector)initialNormal
{
    CPRVector normal;
    
	if (CPRBezierCoreSubpathCount(_bezierCore) != 1) {
		return CPRVectorZero;
	}
	
    if (CPRBezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], initialNormal, NULL, NULL, &normal, 1)) {
        return normal;
    } else {
        return [self normalAtEndWithInitialNormal:initialNormal];
    }    
}

- (CGFloat)relalativePositionClosestToVector:(CPRVector)vector
{
    return CPRBezierCoreRelativePositionClosestToVector(_bezierCore, vector, NULL, NULL);
}

- (CGFloat)relalativePositionClosestToLine:(CPRLine)line;
{
    return CPRBezierCoreRelativePositionClosestToLine(_bezierCore, line, NULL, NULL);
}

- (CGFloat)relalativePositionClosestToLine:(CPRLine)line closestVector:(CPRVectorPointer)vectorPointer;
{
    return CPRBezierCoreRelativePositionClosestToLine(_bezierCore, line, vectorPointer, NULL);
}

- (CPRBezierPath *)bezierPathByCollapsingZ
{
    CPRMutableBezierPath *collapsedBezierPath;
    CPRAffineTransform3D collapseTransform;
    
    collapsedBezierPath = [self mutableCopy];
    
    collapseTransform = CPRAffineTransform3DIdentity;
    collapseTransform.m33 = 0.0;
    
    [collapsedBezierPath applyAffineTransform:collapseTransform];
    
    return [collapsedBezierPath autorelease];
}

- (NSArray*)intersectionsWithPlane:(CPRPlane)plane // returns NSNumbers of the relativePositions of the intersections with the plane.
{
	CPRMutableBezierPath *flattenedPath;
	CPRBezierCoreRef bezierCore;
	NSInteger intersectionCount;
	NSInteger i;
	NSMutableArray *intersectionArray;
	CGFloat *relativePositions;
	
	flattenedPath = [self mutableCopy];
	[flattenedPath subdivide:CPRBezierDefaultSubdivideSegmentLength];
	[flattenedPath flatten:CPRBezierDefaultFlatness];
	
	bezierCore = [flattenedPath CPRBezierCore];
	intersectionCount = CPRBezierCoreCountIntersectionsWithPlane(bezierCore, plane);
	relativePositions = malloc(intersectionCount * sizeof(CGFloat));
	
	intersectionCount = CPRBezierCoreIntersectionsWithPlane(bezierCore, plane, NULL, relativePositions, intersectionCount);
	
	intersectionArray = [NSMutableArray arrayWithCapacity:intersectionCount];
	for (i = 0; i < intersectionCount; i++) {
		[intersectionArray addObject:[NSNumber numberWithDouble:relativePositions[i]]];
	}
	
	free(relativePositions);
	[flattenedPath release];
	
	return intersectionArray;
}

@end

@interface CPRMutableBezierPath ()

- (void)_clearRandomAccessor;

@end


@implementation CPRMutableBezierPath

- (void)moveToVector:(CPRVector)vector
{
    [self _clearRandomAccessor];
    CPRBezierCoreAddSegment(_bezierCore, CPRMoveToBezierPathElement, CPRVectorZero, CPRVectorZero, vector);
}

- (void)lineToVector:(CPRVector)vector
{
    [self _clearRandomAccessor];
    CPRBezierCoreAddSegment(_bezierCore, CPRLineToBezierPathElement, CPRVectorZero, CPRVectorZero, vector);
}

- (void)curveToVector:(CPRVector)vector controlVector1:(CPRVector)controlVector1 controlVector2:(CPRVector)controlVector2
{
    [self _clearRandomAccessor];
    CPRBezierCoreAddSegment(_bezierCore, CPRCurveToBezierPathElement, controlVector1, controlVector2, vector);
}

- (void)close
{
	[self _clearRandomAccessor];
    CPRBezierCoreAddSegment(_bezierCore, CPRCloseBezierPathElement, CPRVectorZero, CPRVectorZero, CPRVectorZero);
}

- (void)flatten:(CGFloat)flatness
{
    [self _clearRandomAccessor];
    CPRBezierCoreFlatten(_bezierCore, flatness);
}

- (void)subdivide:(CGFloat)maxSegmentLength;
{
    [self _clearRandomAccessor];
    CPRBezierCoreSubdivide(_bezierCore, maxSegmentLength);
}

- (void)applyAffineTransform:(CPRAffineTransform3D)transform
{
    [self _clearRandomAccessor];
    CPRBezierCoreApplyTransform(_bezierCore, transform);
}

- (void)appendBezierPath:(CPRBezierPath *)bezierPath connectPaths:(BOOL)connectPaths
{
    [self _clearRandomAccessor];
    CPRBezierCoreAppendBezierCore(_bezierCore, [bezierPath CPRBezierCore], connectPaths);
}

- (void)_clearRandomAccessor
{
    CPRBezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = NULL;
	_length = 0.0;
}

- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(CPRVector)control1 control2:(CPRVector)control2 endpoint:(CPRVector)endpoint
{
	[self elementAtIndex:index]; // just to make sure that the _bezierCoreRandomAccessor has been initialized
	CPRBezierCoreRandomAccessorSetVectorsForSegementAtIndex(_bezierCoreRandomAccessor, index, control1, control2, endpoint);
}

@end

















