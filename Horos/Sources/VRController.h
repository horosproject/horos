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
#import "ShadingArrayController.h"

// Fly Thru
#import "FlyThruController.h"
#import "FlyThru.h"
#import "VRFlyThruAdapter.h"

// ROIs Volumes
#define roi3Dvolume

@class CLUTOpacityView;
@class VRView;
@class ROIVolume;

@class VRPresetPreview;
#import "ColorView.h"


/** \brief Window Controller for VR and MIP 
*/


@interface VRController : Window3DController <NSWindowDelegate, NSToolbarDelegate>
{
	IBOutlet VRView			*view;
	
	NSString				*style;
	
    IBOutlet NSView         *toolsView, *WLWWView, *CLUTEditorsView, *LODView, *ClippingRangeView, *BlendingView, *movieView, *shadingView, *engineView, *perspectiveView, *modeView, *scissorStateView;
	
	IBOutlet NSView			*OrientationsView;
	
	IBOutlet NSView			*BackgroundColorView;
	
	IBOutlet NSMatrix		*modeMatrix;
	
	IBOutlet NSMatrix		*toolsMatrix;
		
	IBOutlet NSWindow       *shadingEditWindow;
	IBOutlet NSWindow       *growingRegionWindow;
	BOOL					growingSet;
	
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
	float					deleteValue;
	
	// Fly Thru
	VRFlyThruAdapter		*FTAdapter;

	// 3D Points
	ViewerController		*viewer2D;
	NSMutableArray			*roi2DPointsArray, *sliceNumber2DPointsArray, *x2DPointsArray, *y2DPointsArray, *z2DPointsArray;
	
	// ROIs Volumes
	NSMutableArray			*roiVolumes[ MAX4D];
	
	NSString				*_renderingMode;
	
	// CLUT & Opacity panel
	IBOutlet NSDrawer		*clutOpacityDrawer;
	IBOutlet CLUTOpacityView *clutOpacityView;
	
	IBOutlet NSPanel				*shadingPanel;
	IBOutlet ShadingArrayController	*shadingsPresetsController;
	BOOL							shadingEditable;
	
	NSMutableArray			*appliedConvolutionFilters;
	
	IBOutlet NSWindow		*save3DSettingsWindow;
	IBOutlet NSTextField	*settingsCLUTTextField, *settingsOpacityTextField, *settingsShadingsTextField, *settingsWLWWTextField, *settingsConvolutionFilterTextField, *settingsProjectionTextField, *settingsBackgroundColorTextField;
	IBOutlet NSTextField	*settingsNameTextField, *settingsNewGroupNameTextField, *settingsNewGroupNameLabelTextField;
	IBOutlet NSPopUpButton	*settingsGroupPopUpButton;
	IBOutlet NSButton		*settingsSaveButton;
	
	IBOutlet NSWindow		*presetsPanel;
	IBOutlet NSPopUpButton	*presetsGroupPopUpButton;
	IBOutlet NSButton		*presetsApplyButton;
	
	IBOutlet VRPresetPreview *presetPreview1, *presetPreview2, *presetPreview3, *presetPreview4, *presetPreview5, *presetPreview6, *presetPreview7, *presetPreview8, *presetPreview9;
	VRPresetPreview			*selectedPresetPreview;
	IBOutlet NSTextField	*presetName1, *presetName2, *presetName3, *presetName4, *presetName5, *presetName6, *presetName7, *presetName8, *presetName9;
	NSMutableArray			*presetPreviewArray;
	NSMutableArray			*presetNameArray;
	int						presetPageNumber, presetPageMax, presetPageMin;
    BOOL                    panelInstantiated;
	IBOutlet NSButton		*nextPresetPageButton, *previousPresetPageButton;
	IBOutlet NSTextField	*numberOfPresetInGroupTextField;

	IBOutlet NSWindow		*presetsInfoPanel;
	IBOutlet NSTextField	*infoNameTextField, *infoCLUTTextField, *infoOpacityTextField, *infoShadingsTextField, *infoWLWWTextField, *infoConvolutionFilterTextField, *infoProjectionTextField, *infoBackgroundColorTextField;
	IBOutlet ColorView		*infoBackgroundColorView;
	
	NSPoint					presetsPanelUserDefinedOrigin;
	BOOL					needToMovePresetsPanelToUserDefinedPosition;
	BOOL					firstTimeDisplayed;
	
	NSTimeInterval			flyThruRecordingTimeFrame;
	
	IBOutlet NSWindow       *editDeleteValue;
	
#ifdef _STEREO_VISION_
	//Added SilvanWidmer 26-08-09
	
	IBOutlet NSWindow       *VRGeometrieSettingsWindow;
	IBOutlet NSTextField    *distanceValue;
	IBOutlet NSTextField	*heightValue;
	IBOutlet NSTextField	*eyeDistance;
	IBOutlet NSView        *stereoIconView;
#endif
}

@property float deleteValue;

- (IBAction) applyConvolution:(id) sender;
- (IBAction) setOrientation:(id) sender;
- (NSString*) style;
- (IBAction) setModeIndex:(long) val;
- (IBAction) setMode:(id)sender;
- (NSMutableArray*) pixList;
- (NSMutableArray*) curPixList;
- (void) load3DState;
- (void) updateBlendingImage;
- (ViewerController*) blendingController;
- (id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC;
- (id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC style:(NSString*) m mode:(NSString*) renderingMode;
- (void) setupToolbar;
- (IBAction) setDefaultTool:(id) sender;
- (void) setCurrentTool:(ToolMode) newTool;
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
- (void) prepareUndo;
- (VRView*) view;
- (void) applyScissor : (NSArray*) object;
+ (NSString*) getUniqueFilenameScissorStateFor:(NSManagedObject*) obj;
- (NSArray*) fileList;
- (float) factor;
- (void) remove3DPointROI: (ROI*) removedROI;
- (void) remove3DPoint: (NSNotification*) note;
- (void) add2DPoint: (float) x : (float) y : (float) z :(float*) mm;
- (void) add2DPoint: (float) x : (float) y : (float) z :(float*) mm :(RGBColor) rgb;
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
- (void)recordFlyThru;
- (IBAction) applyShading:(id) sender;
- (void) findShadingPreset:(id) sender;

#ifdef roi3Dvolume
// ROIs Volumes
- (void) computeROIVolumes;
- (NSMutableArray*) roiVolumes;
- (void) displayROIVolume: (ROIVolume*) v;
- (void) hideROIVolume: (ROIVolume*) v;
- (void) displayROIVolumes;
- (IBAction) roiGetManager:(id) sender;
#endif

- (ViewerController*) viewer2D;

- (NSString *)renderingMode;
- (void)setRenderingMode:(NSString *)renderingMode;
- (NSString *)curCLUTMenu;
- (void)setCurCLUTMenu:(NSString*)clut;

- (NSDrawer*)clutOpacityDrawer;
- (IBAction)showCLUTOpacityPanel:(id)sender;
- (void)loadAdvancedCLUTOpacity:(id)sender;
- (void)delete16BitCLUT:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
- (IBAction) editGrowingRegion:(id) sender;
- (IBAction) endEditGrowingRegion:(id) sender;
- (NSMutableDictionary*)getCurrent3DSettings;
- (IBAction)save3DSettings:(id)sender;
- (NSArray*)find3DSettingsGroups;
- (IBAction)enable3DSettingsSaveButton:(id)sender;
- (IBAction)show3DSettingsNewGroupTextField:(id)sender;
- (IBAction)close3DSettingsSavePanel:(id)sender;
- (void)save3DSettings:(NSMutableDictionary*)settings WithName:(NSString*)name group:(NSString*)groupName;
- (void)updatePresetsGroupPopUpButton;
- (void)updatePresetsGroupPopUpButtonSelectingGroupWithName:(NSString*)groupName;
- (void)load3DSettings;
- (IBAction)load3DSettings:(id)sender;
- (IBAction)displayPresetsForSelectedGroup:(id)sender;
- (void)displayPresetsForSelectedGroup;
- (void)load3DSettingsDictionary:(NSDictionary*)preset forPreview:(VRPresetPreview*)preview;
- (void)setSelectedPresetPreview:(VRPresetPreview*)aPresetPreview;
- (IBAction)nextPresetPage:(id)sender;
- (IBAction)previousPresetPage:(id)sender;
- (void)enablePresetPageButtons;
- (void)showPresetsPanel;
- (void)centerPresetsPanel;
- (void)updatePresetInfoPanel;
- (IBAction)showPresetInfoPanel:(id)sender;
- (void)windowWillCloseNotification:(NSNotification*)notification;

- (void)setVtkCameraForAllPresetPreview:(void*)aCamera;

@end
