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

#import "CPRDisplayInfo.h"


@interface CPRDisplayInfo()

- (id)_initWithDisplayInfo:(CPRDisplayInfo *)displayInfo;
@property (nonatomic, readonly, retain) NSMutableDictionary *planeIntersectionMouseCoordinates;

@end

@implementation CPRDisplayInfo

@synthesize draggedPositionHidden = _draggedPositionHidden;
@synthesize draggedPosition = _draggedPosition;
@synthesize hoverNodeHidden = _hoverNodeHidden;
@synthesize hoverNodeIndex = _hoverNodeIndex;
@synthesize mouseCursorHidden = _mouseCursorHidden;
@synthesize mouseCursorPosition = _mouseCursorPosition;
@synthesize planeIntersectionMouseCoordinates = _planeIntersectionMouseCoordinates;

- (id)init
{
	if ( (self = [super init]) ) {
		_mouseCursorHidden = YES;
        _draggedPositionHidden = YES;
        _hoverNodeHidden = YES;
		_planeIntersectionMouseCoordinates = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)_initWithDisplayInfo:(CPRDisplayInfo *)displayInfo
{
	if ( (self = [super init]) ) {
		_draggedPositionHidden = displayInfo.draggedPositionHidden;
        _draggedPosition = displayInfo.draggedPosition;
        _hoverNodeHidden = displayInfo.hoverNodeHidden;
        _hoverNodeIndex = displayInfo.hoverNodeIndex;
        _mouseCursorHidden = displayInfo.mouseCursorHidden;
        _mouseCursorPosition = displayInfo.mouseCursorPosition;
		_planeIntersectionMouseCoordinates = [displayInfo.planeIntersectionMouseCoordinates mutableCopy];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CPRDisplayInfo *copy;
    
    copy = [[CPRDisplayInfo allocWithZone:zone] _initWithDisplayInfo:self];
    
    return copy;
}

- (void)dealloc
{
	[_planeIntersectionMouseCoordinates release];
	_planeIntersectionMouseCoordinates = nil;
	[super dealloc];
}

- (void)setMouseVector:(CPRVector)vector forPlane:(NSString *)planeName
{
	[_planeIntersectionMouseCoordinates setObject:[NSValue valueWithCPRVector:vector] forKey:planeName];
}

- (void)clearMouseVectorForPlaneName:(NSString *)planeName
{
	[_planeIntersectionMouseCoordinates removeObjectForKey:planeName];
}

- (void)clearAllMouseVectors
{
	[_planeIntersectionMouseCoordinates removeAllObjects];
}

- (NSArray *)planesWithMouseVectors
{
	return [_planeIntersectionMouseCoordinates allKeys];
}

- (CPRVector)mouseVectorForPlane:(NSString *)planeName
{
	return [[_planeIntersectionMouseCoordinates objectForKey:planeName] CPRVectorValue];
}



@end
