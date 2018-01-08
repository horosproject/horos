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
//
//  CPRStraightenedView.h
//  OsiriX
//
//  Created by Joël Spaltenstein on 6/4/11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "CPRMPRDCMView.h"
#import "CPRGenerator.h"
#import "CPRProjectionOperation.h"

@class CPRVolumeData;
@class CPRCurvedPath;
@class CPRDisplayInfo;
@class CPRStretchedGeneratorRequest;
@class StringTexture;
@class N3BezierPath;

@interface CPRStretchedView : DCMView <CPRGeneratorDelegate> {
    id<CPRViewDelegate> _delegate;
    
    CPRVolumeData *_volumeData;
    CPRGenerator *_generator;
    
    CPRCurvedPath *_curvedPath;
    CPRDisplayInfo *_displayInfo;
	    
    NSMutableDictionary *_planes;
    NSMutableDictionary *_slabThicknesses;
    NSMutableDictionary *_verticalLines;
    NSMutableDictionary *_planeRuns;
    NSMutableDictionary *_planeColors;    
    
    NSMutableDictionary *_transverseVerticalLines;
    NSMutableDictionary *_transversePlaneRuns;
    
    NSMutableDictionary *_mousePlanePointsInPix; // The display info stores on what
	//	plane and where in 3D the mouse position dots are, but we want to cache where the dots should be drawn in this view.
    
    CPRViewClippingRangeMode _clippingRangeMode;
    
    CPRVolumeData *_curvedVolumeData;
    
    CPRStretchedGeneratorRequest *_lastRequest;
    CGFloat _generatedHeight;

    BOOL _draggingTransverse;
    BOOL _draggingTransverseSpacing;
    
    BOOL _isDraggingNode;
    NSInteger _draggedNode;

    NSInteger _editingCurvedPathCount;
    
    BOOL _drawAllNodes;
    
    BOOL _processingRequest; // synchronous new image requests are generated in drawRect, but code that handles the new image calls' setNeedsDisplay,
                            // so this variable is used to short circuit setNeedsDisplay while the image is being generated.
    BOOL _needsNewRequest;
    
    BOOL _displayCrossLines;
    BOOL _displayTransverseLines;

    N3BezierPath *_centerlinePath; // this is the centerline path of the most recently generated DCM
    N3Vector _midHeightPoint; // a point in patient space that is mid-height in the curDCM
    N3Vector _projectionNormal;
    
    NSMutableDictionary *stanStringAttrib;
	StringTexture *stringTexA, *stringTexB, *stringTexC;
}

@property (nonatomic, readwrite, assign) id<CPRViewDelegate> delegate;

@property (nonatomic, readwrite, retain) CPRVolumeData *volumeData; // the volume data of the original data
@property (nonatomic, readwrite, copy) CPRCurvedPath *curvedPath;
@property (nonatomic, readwrite, copy) CPRDisplayInfo *displayInfo;
@property (nonatomic, readwrite, assign) CPRViewClippingRangeMode clippingRangeMode;

@property (nonatomic, readonly, retain) CPRVolumeData *curvedVolumeData; // the volume data that was generated
@property (nonatomic, readonly, assign) CGFloat generatedHeight; // height of the image that is generated in mm. kinda hack sends CPRViewDidChangeGeneratedHeight to the delegate when this value changes

@property (nonatomic, readwrite, assign) N3Plane orangePlane; // set these to N3PlaneInvalid to keep the plane from appearing
@property (nonatomic, readwrite, assign) N3Plane purplePlane;
@property (nonatomic, readwrite, assign) N3Plane bluePlane;

@property (nonatomic, readwrite, assign) CGFloat orangeSlabThickness;
@property (nonatomic, readwrite, assign) CGFloat purpleSlabThickness;
@property (nonatomic, readwrite, assign) CGFloat blueSlabThickness;

@property (nonatomic, readwrite, retain) NSColor *orangePlaneColor;
@property (nonatomic, readwrite, retain) NSColor *purplePlaneColor;
@property (nonatomic, readwrite, retain) NSColor *bluePlaneColor;

@property (nonatomic, readwrite, assign) BOOL displayTransverseLines;
@property (nonatomic, readwrite, assign) BOOL displayCrossLines;

- (void)waitUntilPixUpdate; // returns once this view's DCM pix object has been updated to reflect any changes made to the view.
- (void)_setNeedsNewRequest;


@end

