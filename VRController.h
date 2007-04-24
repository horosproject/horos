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
#import "VRFlyThruAdapter.h"

// ROIs Volumes
#define roi3Dvolume


@class CLUTOpacityView;
@class VRView;
@class ROIVolume;

@interface VRController : Window3DController
{
    IBOutlet NSSlider       *LODSlider;
	IBOutlet VRView			*view;
	
	NSString				*style;
	
    IBOutlet NSView         *toolsView, *WLWWView, *LODView, *BlendingView, *movieView, *shadingView, *engineView, *perspectiveView, *modeView, *scissorStateView;
	
	IBOutlet NSView			*OrientationsView;
	
	IBOutlet NSView			*BackgroundColorView;
	
	IBOutlet NSMatrix		*modeMatrix;
	
	IBOutlet NSMatrix		*toolsMatrix;
	IBOutlet NSPopUpButton  *enginePopup;
		
	IBOutlet NSWindow       *shadingEditWindow;
	IBOutlet NSForm			*shadingForm;

	IBOutlet NSButton		*shadingCheck;
	IBOutlet NSTextField    *shadingValues;

	IBOutlet NSView			*convolutionView;
	IBOutlet NSPopUpButton	*convolutionMenu;
	
    NSToolbar				*toolbar;
	
    NSMutableArray			*pixList[ 100];
	NSArray					*fileList;
	NSData					*volumeData[ 100];
	short					curMovieIndex, maxMovieIndex;
	
	IBOutlet NSTextField    *blendingPercentage;
	IBOutlet NSSlider       *blendingSlider;
	BOOL					blending;
	NSData					*blendingVolumeData;
    NSMutableArray			*blendingPixList;
	ViewerController		*blendingController;
	
	NSTimeInterval			lastMovieTime;
    NSTimer					*movieTimer;
	
	IBOutlet NSTextField    *movieTextSlide;
	IBOutlet NSButton		*moviePlayStop;
	IBOutlet NSSlider       *movieRateSlider;
	IBOutlet NSSlider       *moviePosSlider;
	
	float					*undodata[ 100];
	float					minimumValue, maximumValue;
	float					blendingMinimumValue, blendingMaximumValue;
	
	// Fly Thru
	FlyThruController		*flyThruController;
	VRFlyThruAdapter		*FTAdapter;

	// 3D Points
	ViewerController		*viewer2D;
	NSMutableArray			*roi2DPointsArray, *sliceNumber2DPointsArray, *x2DPointsArray, *y2DPointsArray, *z2DPointsArray;
	
	// ROIs Volumes
	NSMutableArray			*roiVolumes;
	
	NSString				*_renderingMode;
	
	// CLUT & Opacity panel
	//IBOutlet NSPanel		*clutOpacityPanel;
	IBOutlet NSDrawer		*clutOpacityDrawer;
	IBOutlet CLUTOpacityView *clutOpacityView;
	
	IBOutlet NSPanel			*shadingPanel;
	IBOutlet NSArrayController	*shadingsPresetsController;
	//NSMutableArray				*shadingsPresets;
	BOOL						shadingEditable;
}

- (IBAction) applyConvolution:(id) sender;
- (IBAction) setOrientation:(id) sender;
- (NSString*) style;
- (void) setModeIndex:(long) val;
- (IBAction) setMode:(id)sender;
- (NSMutableArray*) pixList;
- (NSMutableArray*) curPixList;
- (void) load3DState;
- (void) updateBlendingImage;
- (ViewerController*) blendingController;
- (void) LODsliderAction:(id) sender;
- (id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC;
- (id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC style:(NSString*) m mode:(NSString*) renderingMode;
- (void) setupToolbar;
- (void) setDefaultTool:(id) sender;
- (void) setCurrentTool:(short) newTool;
- (NSMatrix*) toolsMatrix;
- (void) setWLWW:(float) iwl :(float) iww;
- (void) getWLWW:(float*) iwl :(float*) iww;
- (void) ApplyWLWW:(id) sender;
- (void)applyWLWWForString:(NSString *)menuString;
- (void) blendingSlider:(id) sender;
- (void) ApplyCLUTString:(NSString*) str;
- (void) ApplyOpacityString:(NSString*) str;
- (void) MoviePlayStop:(id) sender;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;
- (long) movieFrames;
- (void) setMovieFrame: (long) l;
- (void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData;
- (short)curMovieIndex;
- (BOOL)is4D;
- (IBAction) editShadingValues:(id) sender;
- (IBAction) setEngine:(id) sender;
- (void) updateEngine;
- (void) prepareUndo;
- (VRView*) view;
- (void) applyScissor : (NSArray*) object;
- (NSString*) getUniqueFilenameScissorState;
- (NSArray*) fileList;
- (void)createContextualMenu;
- (float) factor;
- (void) remove3DPoint: (NSNotification*) note;
- (void) add2DPoint: (float) x : (float) y : (float) z :(float*) mm;
- (void) remove2DPoint: (float) x : (float) y : (float) z;
- (NSMutableArray*) roi2DPointsArray;
- (NSMutableArray*) sliceNumber2DPointsArray;
- (IBAction) undo:(id) sender;
- (void) sendMail:(id) sender;
- (void) exportJPEG:(id) sender;
- (void) export2iPhoto:(id) sender;
- (void) exportTIFF:(id) sender;
- (void) computeMinMax;
- (float) minimumValue;
- (float) maximumValue;
- (float) blendingMinimumValue;
- (float) blendingMaximumValue;
- (FlyThruController *) flyThruController;
- (IBAction) flyThruControllerInit:(id) sender;
- (IBAction) applyShading:(id) sender;
- (void) findShadingPreset:(id) sender;

#ifdef roi3Dvolume
// ROIs Volumes
- (void) computeROIVolumes;
- (NSMutableArray*) roiVolumes;
//- (void) displayROIVolumeAtIndex: (int) index;
//- (void) hideROIVolumeAtIndex: (int) index;
- (void) displayROIVolume: (ROIVolume*) v;
- (void) hideROIVolume: (ROIVolume*) v;
- (void) displayROIVolumes;
- (IBAction) roiGetManager:(id) sender;
#endif

- (ViewerController*) viewer2D;

- (NSString *)renderingMode;
- (void)setRenderingMode:(NSString *)renderingMode;
- (NSString *)curCLUTMenu;

- (NSDrawer*)clutOpacityDrawer;
- (void)showCLUTOpacityPanel:(id)sender;
- (void)delete16BitCLUT:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;

@end
