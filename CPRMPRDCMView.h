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
#import "CPRGeometry.h"
#import "CPRCurvedPath.h"

@class CPRController;
@class CPRDisplayInfo;

@protocol CPRViewDelegate;

@interface CPRMPRDCMView : DCMView
{
    id <CPRViewDelegate> delegate;
	int viewID;
	VRView *vrView;
	DCMPix *pix;
	Camera *camera;
	CPRController *windowController;
    CPRCurvedPath *curvedPath;
    CPRDisplayInfo *displayInfo;
	NSInteger editingCurvedPathCount;
    CPRCurvedPathControlToken draggedToken;
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

@property (assign) id <CPRViewDelegate> delegate;
@property (readonly) DCMPix *pix;
@property (retain) Camera *camera;
@property (copy) CPRCurvedPath *curvedPath;
@property (copy) CPRDisplayInfo *displayInfo;
@property float angleMPR, fromIntervalExport, toIntervalExport, LOD;
@property int viewExport;
@property BOOL displayCrossLines, dontUseAutoLOD;
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

- (void)setCrossCenter:(NSPoint)crossCenter;

- (CPRAffineTransform3D)pixToDicomTransform; // converts points in the DCMPix's coordinate space ("Slice Coordinates") into the DICOM space (patient space with mm units)
- (CPRPlane)plane;
- (NSString *)planeName;
- (NSColor *)colorForPlaneName:(NSString *)planeName;

@end


@protocol CPRViewDelegate <NSObject>

@optional
- (void)CPRViewWillEditCurvedPath:(id)CPRMPRDCMView;
- (void)CPRViewDidUpdateCurvedPath:(id)CPRMPRDCMView;
- (void)CPRViewDidEditCurvedPath:(id)CPRMPRDCMView; // the controller will use didBegin and didEnd to log the undo

- (void)CPRViewWillEditDisplayInfo:(id)CPRMPRDCMView;
- (void)CPRViewDidEditDisplayInfo:(id)CPRMPRDCMView;

- (void)CPRViewDidChangeGeneratedHeight:(id)CPRMPRDCMView;
- (void)CPRView:(CPRMPRDCMView*)CPRMPRDCMView setCrossCenter:(CPRVector)crossCenter;

@end


@interface DCMView (CPRAdditions) 

- (CPRAffineTransform3D)viewToPixTransform; // converts coordinates in the NSView's space to coordinates on a DCMPix object in "Slice Coordinates"
- (CPRAffineTransform3D)pixToSubDrawRectTransform; // converst points in DCMPix "Slice Coordinates" to coordinates that need to be passed to GL in subDrawRect


@end


