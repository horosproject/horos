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
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/



#import <Cocoa/Cocoa.h>
#import "OrthogonalMPRController.h"
#import "VRController.h"
#import "EndoscopyVRController.h"
#import "Camera.h"
#import "Window3DController.h"
#import "FlyAssistant.h"

@class OSIVoxel;

/** \brief   Window Controller for Endoscopy
*/


@interface EndoscopyViewer : Window3DController <NSToolbarDelegate, NSWindowDelegate, NSSplitViewDelegate>
{
	IBOutlet OrthogonalMPRController	*mprController;
	IBOutlet EndoscopyVRController		*vrController;
	NSMutableArray						*pixList;
	
	IBOutlet NSSplitView				*topSplitView, *bottomSplitView;
	
	NSToolbar							*toolbar;
    IBOutlet NSView						*tools3DView, *tools2DView, *engineView, *shadingView, *LODView;
	IBOutlet NSMatrix					*tools3DMatrix, *tools2DMatrix;
	
	IBOutlet NSView						*WLWW3DView, *WLWW2DView;
	IBOutlet NSPopUpButton				*wlww2DPopup, *clut2DPopup;
	
	NSString							*cur2DWLWWMenu, *cur2DCLUTMenu;
	
	IBOutlet NSWindow					*exportDCMWindow;
	IBOutlet NSMatrix					*exportDCMViewsChoice;
	IBOutlet NSTextField				*exportDCMSeriesName;
	
	BOOL								exportAllViews;
	
    float lodDisplayed;
    int engine;
	
	// Fly assistant
	FlyAssistant* assistant;
	NSMutableArray* centerline;
	NSMutableArray* centerlineAxial, *centerlineCoronal, *centerlineSagittal;
	Point3D*   pointA, *pointB;
	float* assistantInputData;
	int flyAssistantMode;
	BOOL isFlyPathLocked;
	int flyAssistantPositionIndex;
	float centerlineResampleStepLength;
	BOOL lockCameraFocusOnPath;
	BOOL isShowCenterLine;
	BOOL isLookingBackwards;
	
	// Path Assistant
	IBOutlet NSPanel *pathAssistantPanel;
	IBOutlet NSButton *pathAssistantBasicModeButton;
	IBOutlet NSButton *pathAssistantSetPointAButton;
	IBOutlet NSButton *pathAssistantSetPointBButton;
	IBOutlet NSButton *pathAssistantLookBackButton;
	IBOutlet NSMatrix *pathAssistantCameraOrFocalOnPathMatrix;
	IBOutlet NSButton *pathAssistantExportToFlyThruButton;
	
	// assistant advanced settings
	IBOutlet NSPanel *assistantSettingPanel;
	IBOutlet NSTextField *assistantPanelTextThreshold;
	IBOutlet NSTextField *assistantPanelTextResampleSize;
	IBOutlet NSTextField *assistantPanelTextStepLength;
	IBOutlet NSSlider *assistantPanelSliderThreshold;
	IBOutlet NSSlider *assistantPanelSliderResampleSize;
	IBOutlet NSSlider *assistantPanelSliderStepLength;
}


@property(readonly) EndoscopyVRController *vrController;
@property float lodDisplayed;
@property int engine;

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC : (ViewerController*) vC;
- (BOOL) is2DViewer;
- (NSMutableArray*) pixList;
//- (IBAction) centerline: (id) sender;
- (void) setCameraRepresentation: (NSNotification*) note;
- (void) setCameraRepresentation;
- (void) setCameraPositionRepresentation: (Camera*) aCamera;
- (void) setCameraFocalPointRepresentation: (Camera*) aCamera;
- (void) setCameraViewUpRepresentation: (Camera*) aCamera;
- (void) setCamera;
- (void) setupToolbar;
- (void) Apply2DCLUT:(id) sender;
- (void) setCameraPosition:(OSIVoxel *)position  focalPoint:(OSIVoxel *)focalPoint;


#pragma mark-
#pragma mark VR Viewer methods
- (void) ApplyWLWW:(id) sender;

#pragma mark-
#pragma mark Tools Selection
- (IBAction) change2DTool:(id) sender;
- (IBAction) change3DTool:(id) sender;
#pragma mark-
#pragma mark NSSplitview's delegate methods
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;

#pragma mark-
#pragma mark export
- (IBAction) setExportAllViews: (id) sender;
- (BOOL) exportAllViews;
- (IBAction) endDCMExportSettings:(id) sender;
- (unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp;
#pragma mark-
#pragma mark path assistant
- (IBAction)showPathAssistantPanel:(id)sender;
- (IBAction)pathAssistantSetPointA:(id)sender;
- (IBAction)pathAssistantSetPointB:(id)sender;
- (IBAction)pathAssistantBasicModeButtonAction:(id)sender;
- (IBAction)pathAssistantChangeMode:(id)sender;
- (IBAction)pathAssistantExportToFlyThru:(id)sender;
#pragma mark-
#pragma mark fly assistant
//assistant
- (void) initFlyAssistant:(NSData*) vData;
- (void) flyThruAssistantGoForward: (NSNotification*)note;
- (void) flyThruAssistantGoBackward: (NSNotification*)note;
- (IBAction) applyNewSettingForFlyAssistant:(id) sender;
- (IBAction) showingAssistantSettings:(id) sender;
- (IBAction) showOrHideCenterlines:(id) sender;
- (IBAction) lookBackwards:(id) sender;
- (IBAction) lockCameraOrFocusOnPath:(id) sender;
- (void) updateCenterlineInMPRViews;
- (void) setCameraAtPosition:(OSIVoxel *)cpos TowardsPosition:(OSIVoxel *)fpos;
@end
