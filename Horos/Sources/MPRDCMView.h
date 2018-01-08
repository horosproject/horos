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

#import "DCMView.h"
#import "VRController.h"
#import "MPRController.h"
#import "N3Geometry.h"

@class OSIROIManager;

@interface MPRDCMView : DCMView
{
	int viewID;
    ToolMode mouseDownTool;
	VRView *vrView;
	DCMPix *pix;
	Camera *camera;
	MPRController *windowController;
	float angleMPR;
	BOOL dontUseAutoLOD;
	OSIROIManager *_ROIManager;

	float crossLinesA[2][3];
	float crossLinesB[2][3];
	
	int viewExport;
	float fromIntervalExport, toIntervalExport;
	float LOD, previousResolution, previousPixelSpacing, previousOrientation[ 9], previousOrigin[ 3];
	
	BOOL rotateLines;
	BOOL moveCenter;
	BOOL displayCrossLines;
	BOOL lastRenderingWasMoveCenter;
	
	float rotateLinesStartAngle;
	
	BOOL dontReenterCrossReferenceLines;
	
	BOOL dontCheckRoiChange;
}

@property (readonly) DCMPix *pix;
@property (retain) Camera *camera;
@property float angleMPR, fromIntervalExport, toIntervalExport, LOD;
@property int viewExport;
@property (nonatomic) BOOL displayCrossLines, dontUseAutoLOD;
@property (readonly) VRView *vrView;
@property (readonly) BOOL rotateLines, moveCenter;

- (BOOL)is2DTool:(ToolMode)tool;
- (void) setDCMPixList:(NSMutableArray*)pix filesList:(NSArray*)files roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
- (void) setVRView: (VRView*) v viewID:(int) i;
- (void) updateViewMPROnLoading:(BOOL) isLoading;
- (void) updateViewMPR;
- (void) updateViewMPR:(BOOL) computeCrossReferenceLines;
- (void) setCrossReferenceLines: (float[2][3]) a and: (float[2][3]) b;
- (void) saveCamera;
- (void) restoreCamera;
- (void) restoreCameraAndCheckForFrame: (BOOL) v;
- (void) updateMousePosition: (NSEvent*) theEvent;
- (void) detect2DPointInThisSlice;
- (void) magicTrick;
- (void) removeROI: (NSNotification*) note;

- (N3AffineTransform)pixToDicomTransform; // converts points in the DCMPix's coordinate space ("Slice Coordinates") into the DICOM space (patient space with mm units)

@end
