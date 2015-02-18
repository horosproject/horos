/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "N3Geometry.h"
#import "CPRTransverseView.h"

// this class is used to separate display only related data from the real data in an MVC sense

@interface CPRDisplayInfo : NSObject <NSCopying>
{
    NSInteger _hoverNodeIndex; // the node over which the mouse is currently hovering. This node should be drawn differently
    BOOL _hoverNodeHidden;
    BOOL _draggedPositionHidden;
    CGFloat _draggedPosition;
    BOOL _mouseCursorHidden;
    CGFloat _mouseCursorPosition;
	
    CPRTransverseViewSection _mouseTransverseSection; 
    CGFloat _mouseTransverseSectionDistance;
    
	// to handle tracking the mouse on intersections of the plane and the CPR
	NSMutableDictionary *_planeIntersectionMouseCoordinates; 
}

@property (nonatomic, readwrite, assign, getter=isDraggedPositionHidden) BOOL draggedPositionHidden;
@property (nonatomic, readwrite, assign) CGFloat draggedPosition; // as a relative position [0, 1]
@property (nonatomic, readwrite, assign, getter=isHoverNodeHidden) BOOL hoverNodeHidden;
@property (nonatomic, readwrite, assign) NSInteger hoverNodeIndex;
@property (nonatomic, readwrite, assign, getter=isMouseCursorHidden) BOOL mouseCursorHidden;
@property (nonatomic, readwrite, assign) CGFloat mouseCursorPosition;
@property (nonatomic, readwrite, assign) CPRTransverseViewSection mouseTransverseSection;
@property (nonatomic, readwrite, assign) CGFloat mouseTransverseSectionDistance;



- (void)setMouseVector:(N3Vector)vector forPlane:(NSString *)planeName;
- (void)clearMouseVectorForPlaneName:(NSString *)planeName;
- (void)clearAllMouseVectors;
- (NSArray *)planesWithMouseVectors;
- (N3Vector)mouseVectorForPlane:(NSString *)planeName;

@end
