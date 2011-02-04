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

#import "CPRCurvedPath.h"
#import "CPRBezierPath.h"
#import "CPRBezierCoreAdditions.h"
#include <OpenGL/CGLMacro.h>

static const CGFloat _CPRCurvedPathNodeSpacingThreshold = 1e-10;

const int32_t CPRCurvedPathControlTokenNone = -1;

enum CPRCurvedPathControlTokens {
//    CPRCurvedPathControlTokenNone = -1,
    CPRCurvedPathControlTokenTransverseSection = 1, 
    CPRCurvedPathControlTokenTransverseSpacing = 2 
};

static BOOL _isElementControlToken(CPRCurvedPathControlToken token)
{
    return (token & 3) == 0;
}

static NSInteger _elementForControlToken(CPRCurvedPathControlToken token)
{
    if (_isElementControlToken(token)) {
        return token >> 2;
    } else {
        return -1;
    }
}

static CPRCurvedPathControlToken _controlTokenForElement(NSInteger element)
{
    return element << 2;
}

@interface CPRCurvedPath ()

@property (nonatomic, readwrite, retain) NSMutableArray *nodeRelativePositions;
@property (nonatomic, readwrite, retain) CPRMutableBezierPath *bezierPath;
- (id)_initWithCurvedPath:(CPRCurvedPath *)curvedPath;
- (void)_resetNodeRelativePositions;

@end

@implementation CPRCurvedPath

@synthesize bezierPath = _bezierPath;
@synthesize nodes = _nodes;
@synthesize nodeRelativePositions = _nodeRelativePositions;
@synthesize initialNormal = _initialNormal;
@synthesize thickness = _thickness;
@synthesize transverseSectionSpacing = _transverseSectionSpacing;
@synthesize transverseSectionPosition = _transverseSectionPosition;

+ (BOOL)controlTokenIsNode:(CPRCurvedPathControlToken)token
{
    return _isElementControlToken(token);
}

+ (NSInteger)nodeIndexForToken:(CPRCurvedPathControlToken)token
{
    return _elementForControlToken(token);
}

- (id)init
{
    if ( (self = [super init]) ) {
        _bezierPath = [[CPRMutableBezierPath alloc] init];
        _nodes = [[NSMutableArray alloc] init];
        _nodeRelativePositions = [[NSMutableArray alloc] init];
        _transverseSectionPosition = 0.5;
        _transverseSectionSpacing = 2;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	NSArray *nodesAsDictionaries;
	NSDictionary *nodeDictionary;
	NSMutableArray *nodes;
	CPRVector node;
	
	if ( (self = [super init]) ) {
		nodes = [[NSMutableArray alloc] init];
		nodesAsDictionaries = [decoder decodeObjectForKey:@"nodesAsDictionaries"];
		for (nodeDictionary in nodesAsDictionaries) {
			node = CPRVectorZero;
			CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)nodeDictionary, &node);
			[nodes addObject:[NSValue valueWithCPRVector:node]];
		}
		
		_bezierPath = [[decoder decodeObjectForKey:@"bezierPath"] retain];
		_nodes = nodes;
		_nodeRelativePositions = [[decoder decodeObjectForKey:@"nodeRelativePositions"] retain];
		
		_initialNormal = CPRVectorZero;
		CPRVectorMakeWithDictionaryRepresentation((CFDictionaryRef)[decoder decodeObjectForKey:@"initialNormalDictionary"], &_initialNormal);
		_thickness = [decoder decodeDoubleForKey:@"thickness"];
		_transverseSectionSpacing = [decoder decodeDoubleForKey:@"transverseSectionSpacing"];
		_transverseSectionPosition = [decoder decodeDoubleForKey:@"transverseSectionPosition"];
	}
	return self;
}

- (id)_initWithCurvedPath:(CPRCurvedPath *)curvedPath
{
    if ( (self = [super init]) ) {
        _bezierPath = [curvedPath.bezierPath mutableCopy];
        _nodes = [curvedPath.nodes mutableCopy];
        _nodeRelativePositions = [curvedPath.nodeRelativePositions mutableCopy];
        _initialNormal = curvedPath.initialNormal;
        _thickness = curvedPath.thickness;
        _transverseSectionSpacing = curvedPath.transverseSectionSpacing;
        _transverseSectionPosition = curvedPath.transverseSectionPosition;
    }
    return self;
}

- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [_nodes release];
    _nodes = nil;
    [_nodeRelativePositions release];
    _nodeRelativePositions = nil;
    
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[CPRCurvedPath allocWithZone:zone] _initWithCurvedPath:self];
}

- (void)setBezierPath:(CPRMutableBezierPath *)bezierPath
{
    if ([_bezierPath isEqualToBezierPath:bezierPath] == NO) {
        [_bezierPath release];
        _bezierPath = [bezierPath retain];
        [self _resetNodeRelativePositions];
    }
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	NSMutableArray *nodeVectorsAsDictionaries;
	NSValue *value;
	
	nodeVectorsAsDictionaries = [NSMutableArray array];
	for (value in _nodes) {
		[nodeVectorsAsDictionaries addObject:[(NSDictionary *)CPRVectorCreateDictionaryRepresentation([value CPRVectorValue]) autorelease]];
	}
	
	[encoder encodeObject:_bezierPath forKey:@"bezierPath"];
	[encoder encodeObject:nodeVectorsAsDictionaries forKey:@"nodesAsDictionaries"];
	[encoder encodeObject:_nodeRelativePositions forKey:@"nodeRelativePositions"];
	
	[encoder encodeObject:[(NSDictionary *)CPRVectorCreateDictionaryRepresentation(_initialNormal) autorelease] forKey:@"initialNormalDictionary"];
	[encoder encodeDouble:_thickness forKey:@"thickness"];
	[encoder encodeDouble:_transverseSectionSpacing forKey:@"transverseSectionSpacing"];
	[encoder encodeDouble:_transverseSectionPosition forKey:@"transverseSectionPosition"];
}

- (void)addNode:(NSPoint)point transform:(CPRAffineTransform3D)transform // adds the point to z = 0 in the arbitrary coordinate space
{
    CPRVector node;
    
    node = CPRVectorMake(point.x, point.y, 0);
    node = CPRVectorApplyTransform(node, transform);
    
    if ([_nodes count] && CPRVectorDistance([[_nodes lastObject] CPRVectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to add a node too close to the last node");
        return; // don't bother adding the point if it is already the last point
    }
    
    [_nodes addObject:[NSValue valueWithCPRVector:node]];
    
    if ([_nodes count] >= 2) {
        self.bezierPath = [[[CPRMutableBezierPath alloc] initWithNodeArray:_nodes] autorelease];
    } else {
        self.bezierPath = [[[CPRMutableBezierPath alloc] init] autorelease];
    }
}

- (void)insertNodeAtRelativePosition:(CGFloat)relativePosition
{
    CPRVector vectorAtRelativePosition;
    NSInteger insertIndex;
    
    if ([_nodes count] < 2) {
        NSLog(@"Warning, CPRCurvedPath trying to insert a node into a path that on has %d nodes", [_nodes count]);
        return;
    }
    
    for (insertIndex = 0; insertIndex < [_nodes count]; insertIndex++) {
        if ([self relativePositionForNodeAtIndex:insertIndex] > relativePosition) {
            break;
        }
    }
    
    if (insertIndex == [_nodes count]) {
        insertIndex = [_nodes count]-1;
    }
    
    vectorAtRelativePosition = [_bezierPath vectorAtRelativePosition:relativePosition];
    
    if (insertIndex > 0 && CPRVectorDistance([[_nodes objectAtIndex:insertIndex-1] CPRVectorValue], vectorAtRelativePosition) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to insert a node too close the the previous node");
        return;
    }
    if (insertIndex <= [_nodes count]-1 && CPRVectorDistance([[_nodes objectAtIndex:insertIndex] CPRVectorValue], vectorAtRelativePosition) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to insert a node too close the the next node");
        return;
    }
            
    [_nodes insertObject:[NSValue valueWithCPRVector:vectorAtRelativePosition] atIndex:insertIndex];
    
    self.bezierPath = [[[CPRMutableBezierPath alloc] initWithNodeArray:_nodes] autorelease];
}

- (void)removeNodeAtIndex:(NSInteger)index
{
	assert(index >= 0);
	assert(index < [_nodes count]);
	[_nodes removeObjectAtIndex:index];
	
    if ([_nodes count] >= 2) {
        self.bezierPath = [[[CPRMutableBezierPath alloc] initWithNodeArray:_nodes] autorelease];
    } else {
        self.bezierPath = [[[CPRMutableBezierPath alloc] init] autorelease];
    }
}

- (void)moveControlToken:(CPRCurvedPathControlToken)token toPoint:(NSPoint)point transform:(CPRAffineTransform3D)transform // resets Z by default
{
    CPRVector node;
    NSUInteger element;
    CGFloat relativePosition;
    
    node = CPRVectorMake(point.x, point.y, 0);
    node = CPRVectorApplyTransform(node, transform);

    if (_isElementControlToken(token)) {
        element = _elementForControlToken(token);
        if ([_nodes count] > element - 1 && CPRVectorDistance([[_nodes objectAtIndex:element - 1] CPRVectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
            NSLog(@"Warning, CPRCurvedPath trying to move a node too close the the previous node");
            return; //refuse to move a node right on top the the previous node
        }
        if ([_nodes count] > element + 1 && CPRVectorDistance([[_nodes objectAtIndex:element + 1] CPRVectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
            NSLog(@"Warning, CPRCurvedPath trying to move a node too close the the next node]");
            return; //refuse to move a node right on top the the next node
        }
            
        [_nodes replaceObjectAtIndex:element withObject:[NSValue valueWithCPRVector:node]];
        
        if ([_nodes count] >= 2) {
            self.bezierPath = [[[CPRMutableBezierPath alloc] initWithNodeArray:_nodes] autorelease];
        } else {
            self.bezierPath = [[[CPRMutableBezierPath alloc] init] autorelease];
        }
    } else if (token == CPRCurvedPathControlTokenTransverseSection) {
        _transverseSectionPosition = [self relativePositionForPoint:point transform:transform];
    } else if (token == CPRCurvedPathControlTokenTransverseSpacing) {
        relativePosition = [self relativePositionForPoint:point transform:transform];;
        _transverseSectionSpacing = ABS(_transverseSectionPosition - relativePosition)*[_bezierPath length];
    }
}

- (CPRCurvedPathControlToken)controlTokenNearPoint:(NSPoint)point transform:(CPRAffineTransform3D)transform;
{
    NSValue *value;
    NSUInteger i;
    CPRVector pointVector;
    CPRVector nodeVector;
    CPRVector transverseSectionVector;
    CPRBezierPath *flattenedBezierPath;
    
    flattenedBezierPath = [_bezierPath bezierPathByFlattening:CPRBezierDefaultFlatness];
    
    // center
    transverseSectionVector = CPRVectorApplyTransform([flattenedBezierPath vectorAtRelativePosition:_transverseSectionPosition], CPRAffineTransform3DInvert(transform));
    transverseSectionVector.z = 0;
    if (CPRVectorDistance(CPRVectorMakeFromNSPoint(point), transverseSectionVector) <= 4.0) {
        return CPRCurvedPathControlTokenTransverseSection;
    }

    // left
    transverseSectionVector = CPRVectorApplyTransform([flattenedBezierPath vectorAtRelativePosition:self.leftTransverseSectionPosition], CPRAffineTransform3DInvert(transform));
    transverseSectionVector.z = 0;
    if (CPRVectorDistance(CPRVectorMakeFromNSPoint(point), transverseSectionVector) <= 8.0) {
        return CPRCurvedPathControlTokenTransverseSpacing;
    }
    
    //right
    transverseSectionVector = CPRVectorApplyTransform([flattenedBezierPath vectorAtRelativePosition:self.rightTransverseSectionPosition], CPRAffineTransform3DInvert(transform));
    transverseSectionVector.z = 0;
    if (CPRVectorDistance(CPRVectorMakeFromNSPoint(point), transverseSectionVector) <= 8.0) {
        return CPRCurvedPathControlTokenTransverseSpacing;
    }
    
    
    for (i = 0; i < [_nodes count]; i++) {
        nodeVector = [[_nodes objectAtIndex:i] CPRVectorValue];
        nodeVector = CPRVectorApplyTransform(nodeVector, CPRAffineTransform3DInvert(transform));
        nodeVector.z = 0.0;
        
        if (CPRVectorDistance(CPRVectorMakeFromNSPoint(point), nodeVector) <= 5.0) {
            return _controlTokenForElement(i);
        }
    }
    return CPRCurvedPathControlTokenNone;
}

- (CGFloat)relativePositionForPoint:(NSPoint)point transform:(CPRAffineTransform3D)transform
{
    CPRLine clickRay;
    clickRay = CPRLineApplyTransform(CPRLineMake(CPRVectorMakeFromNSPoint(point), CPRVectorMake(0, 0, 1)), transform);
    return [_bezierPath relalativePositionClosestToLine:clickRay];                        
}

- (CGFloat)relativePositionForPoint:(NSPoint)point transform:(CPRAffineTransform3D)transform distanceToPoint:(CGFloat *)distance // returns the distance the coordinate space of point (screen coordinates)
{
    CPRLine clickRay;
    CPRVector closestVector;
    CPRVector closestLineVector;
    CGFloat relativePosition;
    CPRAffineTransform3D inverseTransform;
    
    clickRay = CPRLineApplyTransform(CPRLineMake(CPRVectorMakeFromNSPoint(point), CPRVectorMake(0, 0, 1)), transform);
    inverseTransform = CPRAffineTransform3DInvert(transform);
    
    relativePosition = [_bezierPath relalativePositionClosestToLine:clickRay closestVector:&closestVector];
    closestLineVector = CPRLinePointClosestToVector(clickRay, closestVector);
    
    closestVector = CPRVectorApplyTransform(closestVector, inverseTransform);
    closestVector.z = 0.0;
    closestLineVector = CPRVectorApplyTransform(closestLineVector, inverseTransform);
    closestLineVector.z = 0.0;
    
    if (distance) {
        *distance = CPRVectorDistance(closestVector, closestLineVector);
    }
    
    return relativePosition;
}

- (CGFloat)relativePositionForControlToken:(CPRCurvedPathControlToken)token;
{
    NSUInteger element;
    CGFloat lengthToSegment;
    CGFloat length;
    
    if (_isElementControlToken(token)) {
        element = _elementForControlToken(token);
        return [self relativePositionForNodeAtIndex:element];
    } else if (token == CPRCurvedPathControlTokenTransverseSection) {
         return _transverseSectionPosition;
    } else if (token == CPRCurvedPathControlTokenTransverseSpacing) {
        return 0.0;
    }
    return 0.0;
}

- (CGFloat)relativePositionForNodeAtIndex:(NSUInteger)nodeIndex
{
    return (CGFloat)[[_nodeRelativePositions objectAtIndex:nodeIndex] doubleValue];
}

- (CGFloat)leftTransverseSectionPosition
{
    return MAX(_transverseSectionPosition - _transverseSectionSpacing/[_bezierPath length], 0.0);
}

- (CGFloat)rightTransverseSectionPosition
{
    return MIN(_transverseSectionPosition + _transverseSectionSpacing/[_bezierPath length], 1.0);
}


- (void)_resetNodeRelativePositions
{
    NSMutableArray *nodeRelativePositions;
    CGFloat curveLength;
    NSInteger i;
    
    curveLength = [_bezierPath length];

    nodeRelativePositions = [NSMutableArray array];

    if (curveLength > 0) {
        for (i = 0; i < [_nodes count]; i++) {
            [nodeRelativePositions addObject:[NSNumber numberWithDouble:MIN([_bezierPath lengthThroughElementAtIndex:i] / curveLength, 1.0)]];
        }
    } else {
        for (i = 0; i < [_nodes count]; i++) {
            [nodeRelativePositions addObject:[NSNumber numberWithDouble:0.0]];
        }
    }
    self.nodeRelativePositions = nodeRelativePositions;
}

@end








