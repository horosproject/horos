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
