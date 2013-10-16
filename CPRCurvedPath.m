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
#import "N3BezierPath.h"
#import "N3BezierCoreAdditions.h"
#import "CPRGeneratorRequest.h"
#include <OpenGL/CGLMacro.h>
#import "WaitRendering.h"
#import "Notifications.h"

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
    return (int32_t)(element << 2);
}

@interface CPRCurvedPath ()

@property (nonatomic, readwrite, retain) NSMutableArray *nodeRelativePositions;
@property (nonatomic, readwrite, retain) N3MutableBezierPath *bezierPath;
- (id)_initWithCurvedPath:(CPRCurvedPath *)curvedPath;
- (void)_resetNodeRelativePositions;

@end

@implementation CPRCurvedPath

@synthesize bezierPath = _bezierPath;
@synthesize nodes = _nodes;
@synthesize nodeRelativePositions = _nodeRelativePositions;
@synthesize angle = _angle;
@synthesize baseDirection = _baseDirection;
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

+ (CPRCurvedPathControlToken)controlTokenForNodeIndex:(NSInteger)nodeIndex
{
    return _controlTokenForElement(nodeIndex);
}

- (id)init
{
    if ( (self = [super init]) ) {
        _bezierPath = [[N3MutableBezierPath alloc] init];
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
	N3Vector node;
    N3Vector initialNormal;
	
	if ( (self = [super init]) ) {
		nodes = [[NSMutableArray alloc] init];
		nodesAsDictionaries = [decoder decodeObjectForKey:@"nodesAsDictionaries"];
		for (nodeDictionary in nodesAsDictionaries) {
			node = N3VectorZero;
			N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)nodeDictionary, &node);
			[nodes addObject:[NSValue valueWithN3Vector:node]];
		}
		
		_bezierPath = [[decoder decodeObjectForKey:@"bezierPath"] retain];
		_nodes = nodes;
		_nodeRelativePositions = [[decoder decodeObjectForKey:@"nodeRelativePositions"] retain];
		
        if ([decoder containsValueForKey:@"initialNormalDictionary"]) { // older versions saved this out
            initialNormal = N3VectorZero;
            N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[decoder decodeObjectForKey:@"initialNormalDictionary"], &initialNormal);
            [self setInitialNormal:initialNormal];
        }
        
        if ([decoder containsValueForKey:@"baseDirectionDictionary"]) {
            _baseDirection = N3VectorZero;
            N3VectorMakeWithDictionaryRepresentation((CFDictionaryRef)[decoder decodeObjectForKey:@"baseDirectionDictionary"], &initialNormal);
        }
        
        if ([decoder containsValueForKey:@"angle"]) {
            _angle = [decoder decodeDoubleForKey:@"angle"];
        }
        
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
        _baseDirection = curvedPath.baseDirection;
        _angle = curvedPath.angle;
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

- (void)setBezierPath:(N3MutableBezierPath *)bezierPath
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
		[nodeVectorsAsDictionaries addObject:[(NSDictionary *)N3VectorCreateDictionaryRepresentation([value N3VectorValue]) autorelease]];
	}
	
	[encoder encodeObject: [N3BezierPath bezierPathWithBezierPath: _bezierPath] forKey:@"bezierPath"];
	[encoder encodeObject:nodeVectorsAsDictionaries forKey:@"nodesAsDictionaries"];
	[encoder encodeObject:_nodeRelativePositions forKey:@"nodeRelativePositions"];
	
	[encoder encodeObject:[(NSDictionary *)N3VectorCreateDictionaryRepresentation(_baseDirection) autorelease] forKey:@"baseDirectionDictionary"];
	[encoder encodeDouble:_angle forKey:@"angle"];
	[encoder encodeDouble:_thickness forKey:@"thickness"];
	[encoder encodeDouble:_transverseSectionSpacing forKey:@"transverseSectionSpacing"];
	[encoder encodeDouble:_transverseSectionPosition forKey:@"transverseSectionPosition"];
}

- (void)setInitialNormal:(N3Vector)initialNormal
{
    N3Vector baseNormal;
    N3Vector tangentAtStart;

    // set the angle if it is possible, set it to 0 if not;
    if (N3VectorIsZero(_baseDirection)) {
        _baseDirection = N3VectorANormalVector([_bezierPath tangentAtStart]);
    }
    
    tangentAtStart = [_bezierPath tangentAtStart];
    baseNormal = N3VectorNormalize(N3VectorCrossProduct(_baseDirection, tangentAtStart));
    _angle = N3VectorAngleBetweenVectorsAroundVector(baseNormal, initialNormal, tangentAtStart);
}

- (N3Vector)initialNormal
{
    N3Vector initialNormal;
    N3Vector baseNormal;
    N3Vector tangentAtStart;
    
    tangentAtStart = [_bezierPath tangentAtStart];
    baseNormal = N3VectorNormalize(N3VectorCrossProduct(_baseDirection, tangentAtStart));
    initialNormal = N3VectorApplyTransform(baseNormal, N3AffineTransformMakeRotationAroundVector(_angle, tangentAtStart));
    
    return initialNormal;
}

- (void)addNode:(NSPoint)point transform:(N3AffineTransform)transform // adds the point to z = 0 in the arbitrary coordinate space
{
    N3Vector node;
    
    node = N3VectorMake(point.x, point.y, 0);
    node = N3VectorApplyTransform(node, transform);
    
    if ([_nodes count] && N3VectorDistance([[_nodes lastObject] N3VectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to add a node too close to the last node");
        return; // don't bother adding the point if it is already the last point
    }
    
    assert(N3VectorIsZero(node) == false);
    
    [_nodes addObject:[NSValue valueWithN3Vector:node]];
    
    if ([_nodes count] >= 2) {
        self.bezierPath = [[[N3MutableBezierPath alloc] initWithNodeArray:_nodes style:N3BezierNodeOpenEndsStyle] autorelease];
    } else {
        self.bezierPath = [[[N3MutableBezierPath alloc] init] autorelease];
    }
}

- (void)insertPatientNode:(N3Vector)node atIndex:(NSUInteger)index // adds the point to z = 0 in the arbitrary coordinate space to a given index
{
    assert(index >= 0);
    if ([_nodes count] && N3VectorDistance([[_nodes lastObject] N3VectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to add a node too close to the last node");
        return; // don't bother adding the point if it is already the last point
    }
    
    assert(N3VectorIsZero(node) == false);
    
    if (index < [_nodes count]) {
        [_nodes insertObject:[NSValue valueWithN3Vector:node] atIndex:index];
    } else {
        [_nodes addObject:[NSValue valueWithN3Vector:node]];
    }
    
    if ([_nodes count] >= 2) {
        self.bezierPath = [[[N3MutableBezierPath alloc] initWithNodeArray:_nodes style:N3BezierNodeOpenEndsStyle] autorelease];
    } else {
        self.bezierPath = [[[N3MutableBezierPath alloc] init] autorelease];
    }
}

- (void)addPatientNode:(N3Vector)node
{
    if ([_nodes count] && N3VectorDistance([[_nodes lastObject] N3VectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to add a node too close to the last node");
        return; // don't bother adding the point if it is already the last point
    }
    
    assert(N3VectorIsZero(node) == false);
    
    [_nodes addObject:[NSValue valueWithN3Vector:node]];
    
    if ([_nodes count] >= 2) {
        self.bezierPath = [[[N3MutableBezierPath alloc] initWithNodeArray:_nodes style:N3BezierNodeOpenEndsStyle] autorelease];
    } else {
        self.bezierPath = [[[N3MutableBezierPath alloc] init] autorelease];
    }
}


- (NSInteger)insertNodeAtRelativePosition:(CGFloat)relativePosition
{
    N3Vector vectorAtRelativePosition;
    NSInteger insertIndex;
    
    if ([_nodes count] < 2) {
        NSLog(@"Warning, CPRCurvedPath trying to insert a node into a path that on has %d nodes", (int) [_nodes count]);
        return -1;
    }
    
    for (insertIndex = 0; insertIndex < [_nodes count]; insertIndex++) {
        if ([self relativePositionForNodeAtIndex:insertIndex] > relativePosition) {
            break;
        }
    }
    
    if (insertIndex == [_nodes count]) {
        insertIndex = (long)[_nodes count]-1;
    }
    
    vectorAtRelativePosition = [_bezierPath vectorAtRelativePosition:relativePosition];
    
    if (insertIndex > 0 && N3VectorDistance([[_nodes objectAtIndex:insertIndex-1] N3VectorValue], vectorAtRelativePosition) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to insert a node too close the the previous node");
        return -1;
    }
    if (insertIndex <= (long)[_nodes count]-1 && N3VectorDistance([[_nodes objectAtIndex:insertIndex] N3VectorValue], vectorAtRelativePosition) < _CPRCurvedPathNodeSpacingThreshold) {
        NSLog(@"Warning, CPRCurvedPath trying to insert a node too close the the next node");
        return -1;
    }
            
    [_nodes insertObject:[NSValue valueWithN3Vector:vectorAtRelativePosition] atIndex:insertIndex];
    
    self.bezierPath = [[[N3MutableBezierPath alloc] initWithNodeArray:_nodes style:N3BezierNodeOpenEndsStyle] autorelease];
    return insertIndex;
}

- (void)removeNodeAtIndex:(NSInteger)index
{
    assert(index >= 0);
    assert(index < [_nodes count]);
    [_nodes removeObjectAtIndex:index];
    
    if ([_nodes count] >= 2) {
        self.bezierPath = [[[N3MutableBezierPath alloc] initWithNodeArray:_nodes style:N3BezierNodeOpenEndsStyle] autorelease];
    } else {
        self.bezierPath = [[[N3MutableBezierPath alloc] init] autorelease];
    }
}

- (void)clearPath
{
    [_bezierPath release];
    _bezierPath = [[N3MutableBezierPath alloc] init];
    [_nodes release];
    _nodes = [[NSMutableArray alloc] init];
    [_nodeRelativePositions release];
    _nodeRelativePositions = [[NSMutableArray alloc] init];
    _transverseSectionPosition = 0.5;
    _transverseSectionSpacing = 2;
}

- (void)moveControlToken:(CPRCurvedPathControlToken)token toPoint:(NSPoint)point transform:(N3AffineTransform)transform // resets Z by default
{
    N3Vector node;
    NSUInteger element;
    CGFloat relativePosition;
    
    node = N3VectorMake(point.x, point.y, 0);
    node = N3VectorApplyTransform(node, transform);

    if (_isElementControlToken(token)) {
        element = _elementForControlToken(token);
        if ([_nodes count] > element - 1 && N3VectorDistance([[_nodes objectAtIndex:element - 1] N3VectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
            NSLog(@"Warning, CPRCurvedPath trying to move a node too close the the previous node");
            return; //refuse to move a node right on top the the previous node
        }
        if ([_nodes count] > element + 1 && N3VectorDistance([[_nodes objectAtIndex:element + 1] N3VectorValue], node) < _CPRCurvedPathNodeSpacingThreshold) {
            NSLog(@"Warning, CPRCurvedPath trying to move a node too close the the next node]");
            return; //refuse to move a node right on top the the next node
        }
            
        [_nodes replaceObjectAtIndex:element withObject:[NSValue valueWithN3Vector:node]];
        
        if ([_nodes count] >= 2) {
            self.bezierPath = [[[N3MutableBezierPath alloc] initWithNodeArray:_nodes style:N3BezierNodeOpenEndsStyle] autorelease];
        } else {
            self.bezierPath = [[[N3MutableBezierPath alloc] init] autorelease];
        }
    } else if (token == CPRCurvedPathControlTokenTransverseSection) {
        _transverseSectionPosition = [self relativePositionForPoint:point transform:transform];
    } else if (token == CPRCurvedPathControlTokenTransverseSpacing) {
        relativePosition = [self relativePositionForPoint:point transform:transform];;
        _transverseSectionSpacing = ABS(_transverseSectionPosition - relativePosition)*[_bezierPath length];
    }
}

- (void)moveNodeAtIndex:(NSInteger)index toVector:(N3Vector)vector // for this exceptional method, the vector is given in patient space
{
    // hacky implementation, but why not....
    [self moveControlToken:[[self class] controlTokenForNodeIndex:index] toPoint:NSPointFromN3Vector(vector) transform:N3AffineTransformMakeTranslation(0, 0, vector.z)];
}

- (CPRCurvedPathControlToken)controlTokenNearPoint:(NSPoint)point transform:(N3AffineTransform)transform;
{
    NSUInteger i;
    N3Vector nodeVector;
    
    for (i = 0; i < [_nodes count]; i++) {
        nodeVector = [[_nodes objectAtIndex:i] N3VectorValue];
        nodeVector = N3VectorApplyTransform(nodeVector, N3AffineTransformInvert(transform));
        nodeVector.z = 0.0;
        
        if (N3VectorDistance(N3VectorMakeFromNSPoint(point), nodeVector) <= 5.0) {
            return _controlTokenForElement(i);
        }
    }
    return CPRCurvedPathControlTokenNone;
}

- (CGFloat)relativePositionForPoint:(NSPoint)point transform:(N3AffineTransform)transform
{
    N3Line clickRay;
    clickRay = N3LineApplyTransform(N3LineMake(N3VectorMakeFromNSPoint(point), N3VectorMake(0, 0, 1)), transform);
    return [_bezierPath relativePositionClosestToLine:clickRay];                        
}

- (CGFloat)relativePositionForPoint:(NSPoint)point transform:(N3AffineTransform)transform distanceToPoint:(CGFloat *)distance // returns the distance the coordinate space of point (screen coordinates)
{
    N3Line clickRay;
    N3Vector closestVector;
    N3Vector closestLineVector;
    CGFloat relativePosition;
    N3AffineTransform inverseTransform;
    
	if( N3AffineTransformIsAffine( transform) == NO)
		return 0;
	
    clickRay = N3LineApplyTransform(N3LineMake(N3VectorMakeFromNSPoint(point), N3VectorMake(0, 0, 1)), transform);
    inverseTransform = N3AffineTransformInvert(transform);
    
    relativePosition = [_bezierPath relativePositionClosestToLine:clickRay closestVector:&closestVector];
    closestLineVector = N3LinePointClosestToVector(clickRay, closestVector);
    
    closestVector = N3VectorApplyTransform(closestVector, inverseTransform);
    closestVector.z = 0.0;
    closestLineVector = N3VectorApplyTransform(closestLineVector, inverseTransform);
    closestLineVector.z = 0.0;
    
    if (distance) {
        *distance = N3VectorDistance(closestVector, closestLineVector);
    }
    
    return relativePosition;
}

- (CGFloat)relativePositionForControlToken:(CPRCurvedPathControlToken)token;
{
    NSUInteger element;
    
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

- (NSArray *)transverseSliceRequestsForSpacing:(CGFloat)spacing outputWidth:(NSUInteger)width outputHeight:(NSUInteger)height mmWide:(CGFloat)mmWide
{
    NSMutableArray *requests;
    CGFloat curveLength;
    CGFloat mmPerPixel;
    NSInteger requestCount;
    NSInteger i;
    N3Vector cross;
    N3VectorArray normals;
    N3VectorArray vectors;
    N3VectorArray tangents;
    N3MutableBezierPath *flattenedPath;
    CPRObliqueSliceGeneratorRequest *request;
    
    requests = [NSMutableArray array];
    
    flattenedPath = [_bezierPath mutableCopy];
    [flattenedPath subdivide:N3BezierDefaultSubdivideSegmentLength];
    [flattenedPath flatten:N3BezierDefaultFlatness];
    
    curveLength = [flattenedPath length];
    requestCount = curveLength/spacing;
    requestCount++;
	
    if (requestCount < 2)
	{
		[flattenedPath release];
		return requests;
    }
    
    normals = malloc(requestCount * sizeof(N3Vector));
    memset(normals, 0, requestCount * sizeof(N3Vector));
    
    vectors = malloc(requestCount * sizeof(N3Vector));
    memset(vectors, 0, requestCount * sizeof(N3Vector));
    
    tangents = malloc(requestCount * sizeof(N3Vector));
    memset(tangents, 0, requestCount * sizeof(N3Vector));
    
	float startingDistance = curveLength - (requestCount-1) * spacing;
	startingDistance /= 2;
	
    requestCount = N3BezierCoreGetVectorInfo([flattenedPath N3BezierCore], spacing, startingDistance, self.initialNormal, vectors, tangents, normals, requestCount);
    
    mmPerPixel = mmWide / (CGFloat)width;
    
    for (i = 0; i < requestCount; i++) {
        cross = N3VectorNormalize(N3VectorCrossProduct(tangents[i], normals[i]));
        
        request = [[CPRObliqueSliceGeneratorRequest alloc] initWithCenter:vectors[i] pixelsWide:width pixelsHigh:height
                                                                   xBasis:N3VectorScalarMultiply(cross, mmPerPixel)
                                                                   yBasis:N3VectorScalarMultiply(normals[i], mmPerPixel)];
        
        [requests addObject:request];
        [request release];
    }
    
    free(normals);
    free(vectors);
    free(tangents);
    [flattenedPath release];
    
    return requests;
}

- (BOOL)isPlaneMeasurable
{
	N3Plane plane;
	
	if( [self.bezierPath isPlanar]) {
		plane = [self.bezierPath leastSquaresPlane];
		if (ABS(N3VectorDotProduct(N3VectorNormalize(self.initialNormal), N3VectorNormalize(plane.normal))) > 0.9999 /*~cos(1deg)*/) {
			return YES;
		}
	}
	return NO;
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

- (N3Vector)stretchedProjectionNormal
{
    N3Vector curveDirection;
    N3Vector baseNormal;
    
    curveDirection = N3VectorSubtract([_bezierPath vectorAtEnd], [_bezierPath vectorAtStart]);
    baseNormal = N3VectorNormalize(N3VectorCrossProduct(_baseDirection, curveDirection));
    return N3VectorApplyTransform(baseNormal, N3AffineTransformMakeRotationAroundVector(_angle, curveDirection));
}

@end








