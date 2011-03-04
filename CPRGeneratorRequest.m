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

#import "CPRGeneratorRequest.h"
#import "N3BezierPath.h"
#import "CPRStraightenedOperation.h"

@implementation CPRGeneratorRequest

@synthesize pixelsWide = _pixelsWide;
@synthesize pixelsHigh = _pixelsHigh;
@synthesize slabWidth = _slabWidth;
@synthesize slabSampleDistance = _slabSampleDistance;
@synthesize context = _context;

- (id)copyWithZone:(NSZone *)zone
{
    CPRGeneratorRequest *copy;
    
    copy = [[[self class] allocWithZone:zone] init];
    copy.pixelsWide = _pixelsWide;
    copy.pixelsHigh = _pixelsHigh;
    copy.slabWidth = _slabWidth;
    copy.slabSampleDistance = _slabSampleDistance;
    copy.context = _context;
    
    return copy;
}

- (BOOL)isEqual:(id)object
{
    CPRGeneratorRequest *generatorRequest;
    if ([object isKindOfClass:[CPRGeneratorRequest class]]) {
        generatorRequest = (CPRGeneratorRequest *)object;
        if (_pixelsWide == generatorRequest.pixelsWide &&
            _pixelsHigh == generatorRequest.pixelsHigh &&
            _slabWidth == generatorRequest.slabWidth &&
            _slabSampleDistance == generatorRequest.slabSampleDistance &&
            _context == generatorRequest.context) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash
{
    return _pixelsWide ^ _pixelsHigh ^ *((NSUInteger *)&_slabWidth) ^ *((NSUInteger *)&_slabSampleDistance) ^ ((NSUInteger)_context);
}

- (Class)operationClass
{
    return nil;
}

@end

@implementation CPRStraightenedGeneratorRequest

@synthesize bezierPath = _bezierPath;
@synthesize initialNormal = _initialNormal;

@synthesize projectionMode = _projectionMode;
// @synthesize vertical = _vertical;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = CPRProjectionModeNone;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CPRStraightenedGeneratorRequest *copy;
    
    copy = [super copyWithZone:zone];
    copy.bezierPath = _bezierPath;
    copy.initialNormal = _initialNormal;
    copy.projectionMode = _projectionMode;
//    copy.vertical = _vertical;
    return copy;
}

- (BOOL)isEqual:(id)object
{
    CPRStraightenedGeneratorRequest *straightenedGeneratorRequest;
    
    if ([object isKindOfClass:[CPRStraightenedGeneratorRequest class]]) {
        straightenedGeneratorRequest = (CPRStraightenedGeneratorRequest *)object;
        if ([super isEqual:object] &&
            [_bezierPath isEqualToBezierPath:straightenedGeneratorRequest.bezierPath] &&
            N3VectorEqualToVector(_initialNormal, straightenedGeneratorRequest.initialNormal) &&
            _projectionMode == straightenedGeneratorRequest.projectionMode /*&&*/ 
            /* _vertical == straightenedGeneratorRequest.vertical */) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash // a not that great hash function....
{
    return [super hash] ^ [_bezierPath hash] ^ (NSUInteger)N3VectorLength(_initialNormal) ^ (NSUInteger)_projectionMode /* ^ (NSUInteger)_vertical */;
}


- (void)dealloc
{
    [_bezierPath release];
    _bezierPath = nil;
    [super dealloc];
}

- (Class)operationClass
{
    return [CPRStraightenedOperation class];
}

@end