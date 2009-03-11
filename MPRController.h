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
#import "OSIWindowController.h"
#import "MPRDCMView.h"
#import "VRController.h"
#import "VRView.h"

@class MPRDCMView;

@interface MPRController : Window3DController
{
	IBOutlet NSSplitView *topSplitView, *bottomSplitView;
	IBOutlet NSView *containerFor3DView;
	
	IBOutlet MPRDCMView *mprView1, *mprView2, *mprView3;
	
	ViewerController *viewer2D;
	VRController *hiddenVRController;
	VRView *vrView, *hiddenVRView;
	
	NSMutableArray *filesList[200], *pixList[200];
	DCMPix *originalPix;
	NSData *volumeData[200];
	short curMovieIndex, maxMovieIndex;
	BOOL avoidReentry;
	
	// 4D Data support
	NSTimeInterval lastMovieTime;
    NSTimer	*movieTimer;
	
	Point3D *mousePosition;
	int mouseViewID;
	
	// Clipping Range
	float clippingRangeThickness;
	int clippingRangeMode;
}

@property float clippingRangeThickness;
@property int clippingRangeMode, mouseViewID;
@property (retain) Point3D *mousePosition;
@property (readonly) DCMPix *originalPix;

+ (double) angleBetweenVector:(float*) a andPlane:(float*) orientation;

- (id)initWithDCMPixList:(NSMutableArray*)pix filesList:(NSMutableArray*)files volumeData:(NSData*)volume viewerController:(ViewerController*)viewer fusedViewerController:(ViewerController*)fusedViewer;
- (DCMPix*) emptyPix: (DCMPix*) originalPix width: (long) w height: (long) h;

- (void) computeCrossReferenceLines:(MPRDCMView*) sender;
- (IBAction)setTool:(id)sender;
- (void) propagateWLWW:(MPRDCMView*) sender;
- (void)bringToFrontROI:(ROI*) roi;


@end
