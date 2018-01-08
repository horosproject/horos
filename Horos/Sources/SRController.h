/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/


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
    IBOutlet NSView         *toolsView, *LODView, *BlendingView, *export3DView, *perspectiveView, *OrientationsView, *BackgroundColorView;
	IBOutlet SRView			*view;
	IBOutlet NSWindow       *SRSettingsWindow;
    
    BOOL                    fusionSettingsWindow;
    
    NSToolbar				*toolbar;
    NSMutableArray			*pixList;
	NSArray					*fileList;
	
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
	BOOL					_shouldDecimate, _shouldSmooth, _useFirstSurface, _useSecondSurface, _shouldRenderFusion;
	
    NSMutableDictionary     *settings, *blendingSettings;
    
	NSTimeInterval			flyThruRecordingTimeFrame;
	
    
    
    
    // Backward compatibility for older xibs, to be delete in next release : not used !
    float                   fusionFirstSurface,  fusionSecondSurface, fusionResolution, fusionFirstTransparency, fusionSecondTransparency, fusionDecimate;
    int                     fusionSmooth;
    NSColor                 *fusionFirstColor, *fusionSecondColor;
    BOOL                    fusionShouldDecimate, fusionShouldSmooth, fusionUseFirstSurface, fusionUseSecondSurface;
    
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

@property float firstSurface, secondSurface, resolution, firstTransparency, secondTransparency, decimate;
@property int smooth;
@property (retain) NSColor *firstColor, *secondColor;
@property BOOL shouldDecimate, shouldSmooth, useFirstSurface, useSecondSurface, shouldRenderFusion;

// Backward compatibility for older xibs, to be delete in next release : not used !
@property float                   fusionFirstSurface,  fusionSecondSurface, fusionResolution, fusionFirstTransparency, fusionSecondTransparency, fusionDecimate;
@property int                     fusionSmooth;
@property (retain) NSColor        *fusionFirstColor, *fusionSecondColor;
@property BOOL                    fusionShouldDecimate, fusionShouldSmooth, fusionUseFirstSurface, fusionUseSecondSurface;


- (IBAction) setOrientation:(id) sender;
- (ViewerController*) blendingController;
- (id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC;
- (void) setupToolbar;
- (void) setDefaultTool:(id) sender;
- (IBAction) ApplySettings:(id) sender;
- (void) ChangeSettings:(id) sender;
- (IBAction) SettingsPopup:(id) sender;
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
- (void) computeROIVolumes;
- (NSMutableArray*) roiVolumes;
- (void) displayROIVolume: (ROIVolume*) v;
- (void) hideROIVolume: (ROIVolume*) v;
- (void) displayROIVolumes;
- (IBAction) roiGetManager:(id) sender;
#endif

- (BOOL) shouldRenderFusion;

@end





	
