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

#import "DCMView.h"
#import "VRController.h"
#import "MPRController.h"

@interface MPRDCMView : DCMView
{
	int viewID, mouseDownTool;
	VRView *vrView;
	DCMPix *pix;
	Camera *camera;
	MPRController *windowController;
	float angleMPR;
	BOOL dontUseAutoLOD;
	
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

- (BOOL)is2DTool:(short)tool;
- (void) setDCMPixList:(NSMutableArray*)pix filesList:(NSArray*)files roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
- (void) setVRView: (VRView*) v viewID:(int) i;
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

@end
