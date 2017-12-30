/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
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
