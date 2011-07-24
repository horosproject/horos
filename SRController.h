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


/** \brief Window Controller for Surface Rendering */
@interface SRController : Window3DController <NSWindowDelegate, NSToolbarDelegate>
{
    IBOutlet NSSlider       *LODSlider;
    IBOutlet NSView         *toolsView, *LODView, *BlendingView, *export3DView, *perspectiveView;
	IBOutlet SRView			*view;	

	IBOutlet NSView			*OrientationsView;
	
	IBOutlet NSView			*BackgroundColorView;
	
	IBOutlet NSWindow       *SRSettingsWindow;
	IBOutlet NSButton		*checkFirst, *checkSecond;
	IBOutlet NSTextField    *firstValue, *secondValue;
	IBOutlet NSSlider		*resolSlide, *firstTrans, *secondTrans;
	IBOutlet NSPopUpButton  *firstPopup, *secondPopup;
	

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
	SRFlyThruAdapter		*FTAdapter;
	
	// 3D Points
	ViewerController		*viewer2D;
	NSMutableArray			*roi2DPointsArray, *sliceNumber2DPointsArray, *x2DPointsArray, *y2DPointsArray, *z2DPointsArray;
	
	// ROIs Volumes
	NSMutableArray			*roiVolumes;
	
	float					_firstSurface,  _secondSurface, _resolution, _firstTransparency, _secondTransparency, _decimate;
	int						_smooth;
	NSColor					*_firstColor, *_secondColor;
	BOOL					_shouldDecimate;
	BOOL					_shouldSmooth;
	BOOL					_useFirstSurface;
	BOOL					_useSecondSurface;
	
	BOOL					_shouldRenderFusion;
	
	float					_fusionFirstSurface,  _fusionSecondSurface, _fusionResolution, _fusionFirstTransparency, _fusionSecondTransparency, _fusionDecimate;
	int						_fusionSmooth;
	NSColor					*_fusionFirstColor, *_fusionSecondColor;
	BOOL					_fusionShouldDecimate;
	BOOL					_fusionShouldSmooth;
	BOOL					_fusionUseFirstSurface;
	BOOL					_fusionUseSecondSurface;
	
	NSTimeInterval			flyThruRecordingTimeFrame;
	
#ifdef _STEREO_VISION_
	//Added SilvanWidmer 26-08-09
	
	IBOutlet NSWindow       *SRGeometrieSettingsWindow;
	double _screenDistance;
	double _screenHeight;
	double _dolly;
	double _camFocal;
	IBOutlet NSTextField    *distanceValue;
	IBOutlet NSTextField	*heightValue;
	IBOutlet NSTextField    *eyeDistance;
	IBOutlet NSTextField	*camFocalValue;
	IBOutlet NSButton		*parallelFlag;
	IBOutlet NSView        *stereoIconView;
#endif

}

- (IBAction) setOrientation:(id) sender;
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

- (IBAction)flyThruButtonMenu:(id)sender;
- (IBAction)flyThruControllerInit:(id)sender;
- (void)recordFlyThru;

// 3D Points
- (void) add2DPoint: (float) x : (float) y : (float) z;
- (void) remove2DPoint: (float) x : (float) y : (float) z;
- (void) add3DPoint: (NSNotification*) note;
- (void) remove3DPointROI: (ROI*) removedROI;
- (void) remove3DPoint: (NSNotification*) note;

- (void) createContextualMenu;

- (ViewerController *) viewer2D;
- (void)renderSurfaces;
- (void)renderFusionSurfaces;

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

//Surface values

- (float) firstSurface;
- (float) secondSurface;
- (float) resolution;
- (float) firstTransparency;
- (float) secondTransparency;
- (float) decimate;
- (int)smooth;
- (NSColor *) firstColor;
- (NSColor *) secondColor;
- (BOOL) shouldDecimate;
- (BOOL) shouldSmooth;
- (BOOL) useFirstSurface;
- (BOOL) useSecondSurface;

- (void) setFirstSurface:(float)pixelValue;
- (void) setSecondSurface:(float)pixelValue;
- (void) setResolution:(float)resolution;
- (void) setFirstTransparency:(float)transparency;
- (void) setSecondTransparency:(float)transparency;
- (void) setDecimate:(float)decimateItr;
- (void) setSmooth:(int)iteration;
- (void) setFirstColor:(NSColor *)color;
- (void) setSecondColor: (NSColor *)color;
- (void) setShouldDecimate: (BOOL)shouldDecimate;
- (void) setShouldSmooth: (BOOL)shouldSmooth;
- (void) setUseFirstSurface:(BOOL)useSurface;
- (void) setUseSecondSurface:(BOOL)useSurface;

//fusion Surface values

- (float) fusionFirstSurface;
- (float) fusionSecondSurface;
- (float) fusionResolution;
- (float) fusionFirstTransparency;
- (float) fusionSecondTransparency;
- (float) fusionDecimate;
- (int) fusionSmooth;
- (NSColor *) fusionFirstColor;
- (NSColor *) fusionSecondColor;
- (BOOL) fusionShouldDecimate;
- (BOOL) fusionShouldSmooth;
- (BOOL) fusionUseFirstSurface;
- (BOOL) fusionUseSecondSurface;

- (BOOL) shouldRenderFusion;

- (void) setFusionFirstSurface:(float)pixelValue;
- (void) setFusionSecondSurface:(float)pixelValue;
- (void) setFusionResolution:(float)resolution;
- (void) setFusionFirstTransparency:(float)transparency;
- (void) setFusionSecondTransparency:(float)transparency;
- (void) setFusionDecimate:(float)decimateItr;
- (void) setFusionSmooth:(int)iteration;
- (void) setFusionFirstColor:(NSColor *)color;
- (void) setFusionSecondColor: (NSColor *)color;
- (void) setFusionShouldDecimate: (BOOL)shouldDecimate;
- (void) setFusionShouldSmooth: (BOOL)shouldSmooth;
- (void) setFusionUseFirstSurface:(BOOL)useSurface;
- (void) setFusionUseSecondSurface:(BOOL)useSurface;
- (void) setShouldRenderFusion:(BOOL)shouldRenderFusion;

@end





	