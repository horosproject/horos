/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Cocoa/Cocoa.h>
#import "DCMPix.h"
#import "ColorTransferView.h"
#import "ViewerController.h"
#import "Window3DController.h"
#import "MIPView.h"

@class MIPView;

@interface MIPController : Window3DController
{
    IBOutlet NSSlider       *LODSlider;
    IBOutlet MIPView        *view;
    IBOutlet NSView         *toolsView, *WLWWView, *LODView, *BlendingView, *perspectiveView, *movieView;
	
    IBOutlet NSWindow       *addWLWWWindow;
    IBOutlet NSTextField    *newName;
    IBOutlet NSTextField    *wl;
    IBOutlet NSTextField    *ww;
	IBOutlet NSMatrix		*toolsMatrix;
    IBOutlet NSPopUpButton  *wlwwPopup;
	IBOutlet NSPopUpButton  *clutPopup;
	
	IBOutlet NSWindow       *addCLUTWindow;
	IBOutlet NSTextField    *clutName;
	IBOutlet ColorTransferView  *clutView;
	
    NSToolbar				*toolbar;
    NSString				*curWLWWMenu, *curCLUTMenu;
    NSMutableArray			*pixList[ 50];
	NSMutableArray			*fileList;
	
	IBOutlet NSTextField    *blendingPercentage;
	IBOutlet NSSlider       *blendingSlider;
	BOOL					blending;
	NSData					*blendingVolumeData;
    NSMutableArray			*blendingPixList;
	ViewerController		*blendingController;
	
    BOOL                    FullScreenOn;
    NSWindow                *FullScreenWindow;
    NSWindow                *StartingWindow;
    NSView                  *contentView;
	NSData					*volumeData[ 50];
	short					curMovieIndex, maxMovieIndex;
	
	NSTimeInterval			lastMovieTime;
    NSTimer					*movieTimer;
	
	IBOutlet NSTextField    *movieTextSlide;
	IBOutlet NSButton		*moviePlayStop;
	IBOutlet NSSlider       *movieRateSlider;
	IBOutlet NSSlider       *moviePosSlider;
	
	float					*undodata[ 50];
}

- (void) load3DState;
- (void) updateBlendingImage;
- (ViewerController*) blendingController;
- (void) LODsliderAction:(id) sender;
- (id) initWithPix:(NSMutableArray*) pix :(NSMutableArray*) file :(NSData*) vData :(ViewerController*) bC;
- (void) setupToolbar;
- (void) setDefaultTool:(id) sender;
- (IBAction) endNameWLWW:(id) sender;
- (NSMatrix*) toolsMatrix;
- (void) setWLWW:(long) iwl :(long) iww;
- (void) ApplyCLUT:(id) sender;
- (void) blendingSlider:(id) sender;
- (void) ApplyCLUTString:(NSString*) str;
- (IBAction) endCLUT:(id) sender;
- (IBAction) clutAction:(id)sender;
- (void) MoviePlayStop:(id) sender;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;
- (void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData;
- (void) prepareUndo;
- (void) applyScissor : (NSArray*) object;
@end
