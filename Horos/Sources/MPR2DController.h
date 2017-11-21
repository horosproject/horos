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
#import "DCMPix.h"
#import "ColorTransferView.h"
#import "ViewerController.h"
#import "PreviewView.h"
#import "Window3DController.h"


@class MPR2DView;
@class DICOMExport;

/** \brief Window Controller for 2D MPR */
@interface MPR2DController : Window3DController
{
    IBOutlet NSWindow       *quicktimeWindow;
	IBOutlet NSMatrix		*quicktimeMode;
	IBOutlet NSMatrix		*quicktimeRotation, *quicktimeRotationView;
	IBOutlet NSTextField    *quicktimeFrames;
	
	IBOutlet NSSlider       *slider;
	IBOutlet PreviewView	*originalView;
    IBOutlet NSView         *toolsView, *ThickSlabView;
    IBOutlet NSView         *WLWWView, *axesView, *BlendingView, *movieView, *iPhotoView, *orientationView;
	IBOutlet MPR2DView		*view;
	IBOutlet NSMatrix		*orientationMatrix;
	
    NSToolbar				*toolbar;
    NSMutableArray			*pixList[ 100];
	NSArray					*fileList;
	NSData					*volumeData[ 100];
	short					curMovieIndex, maxMovieIndex;

	IBOutlet NSTextField    *blendingPercentage;
	IBOutlet NSSlider       *blendingSlider;
	BOOL					blending;
	ViewerController		*blendingController, *viewerController;
	
	NSTimeInterval			lastMovieTime;
    NSTimer					*movieTimer;
	
	IBOutlet NSTextField    *movieTextSlide;
	IBOutlet NSButton		*moviePlayStop;
	IBOutlet NSSlider       *movieRateSlider;
	IBOutlet NSSlider       *moviePosSlider;
	IBOutlet NSMatrix		*toolMatrix;
	
	DICOMExport				*exportDCM;
}

-(NSSlider*) slider;
-(void) setSliderValue:(int) i;
-(void) load3DState;
-(MPR2DView*) MPR2Dview;
-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) files :(NSData*) volumeData :(ViewerController*) bC :(ViewerController*) vC;
- (void) setupToolbar;
-(void) setDefaultTool:(id) sender;
- (void)setCurrentTool:(int)tool;
- (void) ApplyOpacityString:(NSString*) str;
-(ViewerController*) blendingController;
-(void) updateBlendingImage;
- (void) blendingSlider:(id) sender;
-(void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) wl :(float) ww;
- (void) MoviePlayStop:(id) sender;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;
-(void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData;
-(DCMView*) originalView;
- (IBAction) updateImage:(id) sender;
-(IBAction) endQuicktime:(id) sender;
-(IBAction) export2iPhoto:(id) sender;
- (ViewerController *)viewerController;
- (void)applyWLWWForString:(NSString *)menuString;
- (void)bringToFrontROI:(ROI*)roi;
- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;
- (IBAction) setOrientationTool:(id)sender;
- (void) updateOrientationMatrix;
@end
