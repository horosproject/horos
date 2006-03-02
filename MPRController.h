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
//#import "DCMPix.h"
//#import "ColorTransferView.h"
#import "ViewerController.h"
#import "Window3DController.h"
@class DCMPix;
@class MPRView;

enum { xSlider = 0, ySlider = 1, zSlider = 2};

@interface MPRController : Window3DController
{
    IBOutlet NSSlider       *Xslider, *Yslider, *Zslider, *viewSlider;
    IBOutlet NSView         *toolsView;
    IBOutlet NSView         *WLWWView, *axesView, *BlendingView, *movieView;
	IBOutlet MPRView        *view;
	IBOutlet NSView			*ThickSlabView;
	
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
	IBOutlet NSMatrix		*selectedPlaneMatrix;
}

-(void) getPlanes:(long*) x :(long*) y;
-(IBAction) selectPlane:(id) sender;
-(IBAction) nextPlane:(id) sender;
-(NSMutableArray*) pixList;
-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) volumeData :(ViewerController*) bc;
-(void) sliderAction:(id) sender;
- (void) setupToolbar;
-(void) setDefaultTool:(id) sender;
-(ViewerController*) blendingController;
-(void) updateBlendingImage;
- (void) blendingSlider:(id) sender;
-(void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) wl :(float) ww;
- (void) getWLWW:(float*) wl :(float*) ww;
- (void) MoviePlayStop:(id) sender;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;
-(void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData;
-(IBAction) slider2DAction:(id) sender;

@end
