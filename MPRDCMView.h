/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
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
	int viewID;
	VRView *vrView;
	DCMPix *pix;
	Camera *camera;
	MPRController *windowController;
	float angleMPR;
	
	float crossLinesA[2][3];
	float crossLinesB[2][3];
	
	int viewExport;
	float fromIntervalExport, toIntervalExport;
	
	BOOL rotateLines;
	BOOL moveCenter;
	
	float rotateLinesStartAngle;
	
	BOOL dontReenterCrossReferenceLines;
}

@property (readonly) DCMPix *pix;
@property (readonly) Camera *camera;
@property float angleMPR, fromIntervalExport, toIntervalExport;
@property int viewExport;
@property (readonly) VRView *vrView;

- (BOOL)is2DTool:(short)tool;
- (void) setDCMPixList:(NSMutableArray*)pix filesList:(NSArray*)files volumeData:(NSData*)volume roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
- (void) setVRView: (VRView*) v viewID:(int) i;
- (void) updateViewMPR;
- (void) updateViewMPR:(BOOL) computeCrossReferenceLines;
- (void) setCrossReferenceLines: (float[2][3]) a and: (float[2][3]) b;
- (void) saveCamera;
- (void) restoreCamera;
- (void) updateMousePosition: (NSEvent*) theEvent;

@end
