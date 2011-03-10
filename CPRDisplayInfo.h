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
