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

#import "CPRGeometry.h"
#import "CPRBezierCore.h"

// CPRBezierDefaultFlatness and CPRBezierDefaultSubdivideSegmentLength are defined in CPRBezierCore.h

@class NSBezierPath;

enum _CPRBezierPathElement {
    CPRMoveToBezierPathElement,
    CPRLineToBezierPathElement,
    CPRCurveToBezierPathElement,
	CPRCloseBezierPathElement
};
typedef NSInteger CPRBezierPathElement;

@interface CPRBezierPath : NSObject <NSCopying, NSMutableCopying, NSCoding>
{
    CPRMutableBezierCoreRef _bezierCore;
	CGFloat _length;
    CPRBezierCoreRandomAccessorRef _bezierCoreRandomAccessor;
}

- (id)init;
- (id)initWithBezierPath:(CPRBezierPath *)bezierPath;
- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (id)initWithCPRBezierCore:(CPRBezierCoreRef)bezierCore;
- (id)initWithNodeArray:(NSArray *)nodes; // array of CPRVectors in NSValues;

+ (id)bezierPath;
+ (id)bezierPathWithBezierPath:(CPRBezierPath *)bezierPath;
+ (id)bezierPathCPRBezierCore:(CPRBezierCoreRef)bezierCore;

- (BOOL)isEqualToBezierPath:(CPRBezierPath *)bezierPath;

- (CPRBezierPath *)bezierPathByFlattening:(CGFloat)flatness;
- (CPRBezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
- (CPRBezierPath *)bezierPathByApplyingTransform:(CPRAffineTransform3D)transform;
- (CPRBezierPath *)bezierPathByAppendingBezierPath:(CPRBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (CPRBezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(CPRVector)initalNormal spacing:(CGFloat)spacing;

- (NSInteger)elementCount;
- (CGFloat)length;
- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element; // the length of the curve up to and including the element at index
- (CPRBezierCoreRef)CPRBezierCore;
- (NSDictionary *)dictionaryRepresentation;
- (CPRVector)vectorAtStart;
- (CPRVector)vectorAtEnd;
- (CPRVector)tangentAtStart;
- (CPRVector)tangentAtEnd;
- (CPRVector)normalAtEndWithInitialNormal:(CPRVector)initialNormal;
- (CPRBezierPathElement)elementAtIndex:(NSInteger)index;
- (CPRBezierPathElement)elementAtIndex:(NSInteger)index control1:(CPRVectorPointer)control1 control2:(CPRVectorPointer)control2 endpoint:(CPRVectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is is not always the end

// extra functions to help with rendering and such
- (CPRVector)vectorAtRelativePosition:(CGFloat)relativePosition; // RelativePosition is in [0, 1]
- (CPRVector)tangentAtRelativePosition:(CGFloat)relativePosition;
- (CPRVector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(CPRVector)initialNormal;

- (CGFloat)relalativePositionClosestToVector:(CPRVector)vector;
- (CGFloat)relalativePositionClosestToLine:(CPRLine)line;
- (CGFloat)relalativePositionClosestToLine:(CPRLine)line closestVector:(CPRVectorPointer)vectorPointer;
- (CPRBezierPath *)bezierPathByCollapsingZ;

- (NSArray*)intersectionsWithPlane:(CPRPlane)plane; // returns NSNumbers of the relativePositions of the intersections with the plane.

@end


@interface CPRMutableBezierPath : CPRBezierPath
{
}

- (void)moveToVector:(CPRVector)vector;
- (void)lineToVector:(CPRVector)vector;
- (void)curveToVector:(CPRVector)vector controlVector1:(CPRVector)controlVector1 controlVector2:(CPRVector)controlVector2;
- (void)close;
- (void)flatten:(CGFloat)flatness;
- (void)subdivide:(CGFloat)maxSegmentLength;
- (void)applyAffineTransform:(CPRAffineTransform3D)transform;
- (void)appendBezierPath:(CPRBezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(CPRVector)control1 control2:(CPRVector)control2 endpoint:(CPRVector)endpoint;

@end



