/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "DCMPix.h"
#import "ColorTransferView.h"
#import "ViewerController.h"
#import "Window3DController.h"

// Fly Thru
#import "FlyThruController.h"
#import "FlyThru.h"
#import "SRFlyThruAdapter.h"

// ROIs Volumes
#define roi3Dvolume

@class SRView;
@class ROIVolume;

@interface SRController : Window3DController
{
    IBOutlet NSSlider       *LODSlider;
    IBOutlet NSView         *toolsView, *LODView, *BlendingView, *export3DView, *perspectiveView;
	IBOutlet SRView			*view;	
	
	IBOutlet NSWindow       *SRSettingsWindow;
	IBOutlet NSButton		*checkFirst, *checkSecond;
	IBOutlet NSTextField    *firstValue, *secondValue;
	IBOutlet NSSlider		*resolSlide, *firstTrans, *secondTrans;
	IBOutlet NSPopUpButton  *firstPopup, *secondPopup;
	IBOutlet NSColorWell	*firstColor, *secondColor;

	IBOutlet NSWindow       *BSRSettingsWindow;
	IBOutlet NSButton		*BcheckFirst, *BcheckSecond;
	IBOutlet NSTextField    *BfirstValue, *BsecondValue;
	IBOutlet NSSlider		*BresolSlide, *BfirstTrans, *BsecondTrans;
	IBOutlet NSPopUpButton  *BfirstPopup, *BsecondPopup;
	IBOutlet NSColorWell	*BfirstColor, *BsecondColor;
	
	IBOutlet NSMatrix		*preprocessMatrix;
	IBOutlet NSTextField	*decimate, *smooth;
	
	IBOutlet NSMatrix		*BpreprocessMatrix;
	IBOutlet NSTextField	*Bdecimate, *Bsmooth;
		
    NSToolbar				*toolbar;
    NSMutableArray			*pixList;
	NSArray					*fileList;
	
	IBOutlet NSTextField    *blendingPercentage;
	IBOutlet NSSlider       *blendingSlider;
	BOOL					blending;
	NSData					*blendingVolumeData;
    NSMutableArray			*blendingPixList;
	ViewerController		*blendingController;
	
	NSData					*volumeData;
	
	// Fly Thru
	FlyThruController		*flyThruController;
	SRFlyThruAdapter		*FTAdapter;
	
	// 3D Points
	ViewerController		*viewer2D;
	NSMutableArray			*roi2DPointsArray, *sliceNumber2DPointsArray, *x2DPointsArray, *y2DPointsArray, *z2DPointsArray;
	
	// ROIs Volumes
	NSMutableArray			*roiVolumes;
}

- (ViewerController*) blendingController;
- (id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC;
- (void) setupToolbar;
- (void) setDefaultTool:(id) sender;
- (IBAction) ApplySettings:(id) sender;
- (void) ChangeSettings:(id) sender;
- (IBAction) SettingsPopup:(id) sender;
- (IBAction) BApplySettings:(id) sender;
- (void) BChangeSettings:(id) sender;
- (IBAction) BSettingsPopup:(id) sender;
- (NSArray*) fileList;

// 3D Points
- (void) add2DPoint: (float) x : (float) y : (float) z;
- (void) remove2DPoint: (float) x : (float) y : (float) z;
- (void) add3DPoint: (NSNotification*) note;
- (void) remove3DPoint: (NSNotification*) note;

- (void) createContextualMenu;

#ifdef roi3Dvolume
// ROIs Volumes
- (void) computeROIVolumes;
- (NSMutableArray*) roiVolumes;
//- (void) displayROIVolumeAtIndex: (int) index;
- (void) displayROIVolume: (ROIVolume*) v;
//- (void) hideROIVolumeAtIndex: (int) index;
- (void) hideROIVolume: (ROIVolume*) v;
- (void) displayROIVolumes;
- (IBAction) roiGetManager:(id) sender;
#endif
@end
