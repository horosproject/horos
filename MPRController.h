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
	// To avoid the Cocoa bindings memory leak bug...
	IBOutlet NSObjectController *ob;
	
	// To be able to use Cocoa bindings with toolbar...
	IBOutlet NSView *tbLOD, *tbThickSlab, *tbWLWW, *tbTools, *tbShading;
	
	NSToolbar *toolbar;
	
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
	
	BOOL displayCrossLines;
	
	// Export Dcm
	IBOutlet NSWindow *dcmWindow;
	IBOutlet NSView *dcmSeriesView;
	int dcmFrom, dcmTo;
	float dcmInterval, previousDcmInterval;
	int dcmMode;
	int dcmSeriesMode;
	int dcmRotation, dcmRotationDirection, dcmNumberOfFrames, dcmQuality, dcmBatchNumberOfFrames;
	BOOL dcmSameIntervalAndThickness;
	NSString *dcmSeriesName;
	MPRDCMView *curExportView;
	
	// Clipping Range
	float clippingRangeThickness;
	int clippingRangeMode;
	
	NSArray *wlwwMenuItems;
	
	float LOD;
	
	IBOutlet NSPanel *shadingPanel;
	IBOutlet ShadingArrayController *shadingsPresetsController;
	BOOL shadingEditable;
	IBOutlet NSButton *shadingCheck;
	IBOutlet NSTextField *shadingValues;
	
	IBOutlet NSView *tbAxisColors;
	NSColor *colorAxis1, *colorAxis2, *colorAxis3;
}

@property float clippingRangeThickness, dcmInterval;
@property int clippingRangeMode, mouseViewID, dcmFrom, dcmTo, dcmMode, dcmSeriesMode, dcmRotation, dcmRotationDirection, dcmNumberOfFrames, dcmQuality, dcmBatchNumberOfFrames;
@property (retain) Point3D *mousePosition;
@property (retain) NSArray *wlwwMenuItems;
@property (retain) NSString *dcmSeriesName;
@property (readonly) DCMPix *originalPix;
@property float LOD;
@property BOOL dcmSameIntervalAndThickness, displayCrossLines;
@property (retain) NSColor *colorAxis1, *colorAxis2, *colorAxis3;

+ (double) angleBetweenVector:(float*) a andPlane:(float*) orientation;

- (id)initWithDCMPixList:(NSMutableArray*)pix filesList:(NSMutableArray*)files volumeData:(NSData*)volume viewerController:(ViewerController*)viewer fusedViewerController:(ViewerController*)fusedViewer;
- (DCMPix*) emptyPix: (DCMPix*) originalPix width: (long) w height: (long) h;

- (void) computeCrossReferenceLines:(MPRDCMView*) sender;
- (IBAction)setTool:(id)sender;
- (void) propagateWLWW:(MPRDCMView*) sender;
- (void)bringToFrontROI:(ROI*) roi;

- (void)createWLWWMenuItems;
- (void)UpdateWLWWMenu:(NSNotification*)note;
- (void)ApplyWLWW:(id)sender;
- (void)applyWLWWForString:(NSString *)menuString;
- (void) updateViewsAccordingToFrame:(id) sender;
- (void)findShadingPreset:(id) sender;
- (IBAction)editShadingValues:(id) sender;

-(IBAction) endDCMExportSettings:(id) sender;

@end
