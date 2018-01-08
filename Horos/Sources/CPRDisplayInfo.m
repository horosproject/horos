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
@synthesize mouseTransverseSection = _mouseTransverseSection;
@synthesize mouseTransverseSectionDistance = _mouseTransverseSectionDistance;
@synthesize planeIntersectionMouseCoordinates = _planeIntersectionMouseCoordinates;

- (id)init
{
	if ( (self = [super init]) ) {
		_mouseCursorHidden = YES;
        _draggedPositionHidden = YES;
        _hoverNodeHidden = YES;
        _mouseTransverseSection = CPRTransverseViewNoneSectionType;
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
        _mouseTransverseSection = displayInfo.mouseTransverseSection;
        _mouseTransverseSectionDistance = displayInfo.mouseTransverseSectionDistance;
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

- (void)setMouseVector:(N3Vector)vector forPlane:(NSString *)planeName
{
	[_planeIntersectionMouseCoordinates setObject:[NSValue valueWithN3Vector:vector] forKey:planeName];
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

- (N3Vector)mouseVectorForPlane:(NSString *)planeName
{
	return [[_planeIntersectionMouseCoordinates objectForKey:planeName] N3VectorValue];
}



@end
