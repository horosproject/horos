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

#import "ColorTransferView.h"
#import "ViewerController.h"
#import "Window3DController.h"
#import "DCMPix.h"

// Fly Thru
#import "FlyThruController.h"
#import "FlyThru.h"
#import "VRPROFlyThruAdapter.h"


@class VRPROView;

/** \brief WindowController for VPRO */

@interface VRPROController : Window3DController
{
    IBOutlet NSSlider       *LODSlider;
    IBOutlet VRPROView		*view;
    IBOutlet NSView         *toolsView, *WLWWView, *LODView, *BlendingView, *movieView, *shadingView, *engineView, *perspectiveView, *scissorStateView, *modeView;
	
	IBOutlet NSMatrix		*modeMatrix;
	
	IBOutlet NSMatrix		*toolsMatrix;
	IBOutlet NSPopUpButton  *enginePopup;
	
	IBOutlet NSWindow       *shadingEditWindow;
	IBOutlet NSForm			*shadingForm;

	IBOutlet NSButton		*shadingCheck;
	IBOutlet NSTextField    *shadingValues;
	
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
	ViewerController		*viewer2D, *blendingController;
		
	NSTimeInterval			lastMovieTime;
    NSTimer					*movieTimer;
	
	IBOutlet NSTextField    *movieTextSlide;
	IBOutlet NSButton		*moviePlayStop;
	IBOutlet NSSlider       *movieRateSlider;
	IBOutlet NSSlider       *moviePosSlider;
	
	float					*undodata[ 100];
	
	// Fly Thru
	VRPROFlyThruAdapter		*FTAdapter;
	
	NSString				*_renderingMode;
}

+(BOOL) available;
+(BOOL) hardwareCheck;

- (IBAction) resetShading:(id) sender;
- (void) setModeIndex:(long) val;
-(NSMutableArray*) pixList;
-(void) load3DState;
-(void) updateBlendingImage;
-(ViewerController*) blendingController;
-(ViewerController*) viewer2D;
-(void) LODsliderAction:(id) sender;
-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC;
-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC mode:(NSString*) renderingMode;
- (void) setupToolbar;
-(void) setDefaultTool:(id) sender;
-(NSMatrix*) toolsMatrix;
- (void) setWLWW:(float) iwl :(float) iww;
- (void) blendingSlider:(id) sender;
- (void) ApplyCLUTString:(NSString*) str;
- (void) ApplyOpacityString:(NSString*) str;
- (void) MoviePlayStop:(id) sender;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;
- (long) movieFrames;
- (void) setMovieFrame: (long) l;
-(void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData;
-(IBAction) endShadingEditing:(id) sender;
-(IBAction) editShadingValues:(id) sender;
-(IBAction) setEngine:(id) sender;
- (void) updateEngine;
- (void) prepareUndo;
- (void) applyScissor : (NSArray*) object;
- (IBAction) setMode:(id) sender;
- (NSArray*) fileList;
- (void)createContextualMenu;

- (NSString *)renderingMode;
- (void)setRenderingMode:(NSString *)renderingMode;
@end
