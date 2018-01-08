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
#ifdef _STEREO_VISION_

#import "VRController+StereoVision.h"
#import "VRView+StereoVision.h"

#import "AppController.h"
#import "VRController.h"
#import "DCMView.h"
#import "DicomFile.h"
#import "NSFullScreenWindow.h"
#import "BrowserController.h"
#include <Accelerate/Accelerate.h>
#import "Photos.h"
#import "DICOMExport.h"
#import "VRFlyThruAdapter.h"
#import "DicomImage.h"
#import "VRView.h"
#import "ROI.h"
#import "ROIVolume.h"
#import "ROIVolumeManagerController.h"
#import "CLUTOpacityView.h"
#import "VRPresetPreview.h"
#import "Notifications.h"
#import "OSIWindow.h"

static NSString* 	VRStandardToolbarIdentifier = @"VR Toolbar Identifier";
static NSString* 	VRPanelToolbarIdentifier = @"VRPanel Toolbar Identifier";

static NSString*	QTExportToolbarItemIdentifier = @"QTExport.pdf";
static NSString*	PhotosToolbarItemIdentifier = @"iPhoto.icns";
//static NSString*	QTExportVRToolbarItemIdentifier = @"QTExportVR.icns";
static NSString*	StereoIdentifier = @"Stereo.icns";
static NSString*	CaptureToolbarItemIdentifier = @"BestRendering.pdf";
static NSString*	CroppingToolbarItemIdentifier = @"Cropping.pdf";
static NSString*	OrientationToolbarItemIdentifier= @"OrientationWidget.tif";
static NSString*	ToolsToolbarItemIdentifier = @"Tools";
static NSString*	WLWWToolbarItemIdentifier = @"WLWW";
static NSString*	LODToolbarItemIdentifier = @"LOD";
static NSString*	BlendingToolbarItemIdentifier = @"2DBlending";
static NSString*	MovieToolbarItemIdentifier = @"Movie";
static NSString*	ExportToolbarItemIdentifier = @"Export.icns";
static NSString*	MailToolbarItemIdentifier = @"Mail.icns";
static NSString*	ShadingToolbarItemIdentifier	= @"Shading";
static NSString*	EngineToolbarItemIdentifier = @"Engine";
static NSString*	PerspectiveToolbarItemIdentifier= @"Perspective";
static NSString*	ResetToolbarItemIdentifier = @"Reset.pdf";
static NSString*	RevertToolbarItemIdentifier = @"Revert.tif";
static NSString*	ModeToolbarItemIdentifier = @"Mode";
static NSString*	FlyThruToolbarItemIdentifier	= @"FlyThru.pdf";
static NSString*	ScissorStateToolbarItemIdentifier	= @"ScissorState";
static NSString*	ROIManagerToolbarItemIdentifier = @"ROIManager.pdf";
static NSString*	OrientationsViewToolbarItemIdentifier = @"OrientationsView";
static NSString*	ConvolutionViewToolbarItemIdentifier = @"ConvolutionView";
static NSString*	BackgroundColorViewToolbarItemIdentifier = @"BackgroundColorView";
static NSString*	PresetsPanelToolbarItemIdentifier = @"3DPresetsPanel.tif";
static NSString*	ClippingRangeViewToolbarItemIdentifier = @"ClippingRange";
static NSString*	CLUTEditorsViewToolbarItemIdentifier = @"CLUTEditors";

#include <3DConnexionClient/ConnexionClientAPI.h>


@implementation  VRController (StereoVision)

- (void)windowDidResize:(NSNotification *)notification
{
	if([view StereoVisionOn])
	{
		[view adjustWindowContent:[[view window]frame].size];
	}
}

//Added SilvanWidmer 04-03-10
// Overrides the Fullscreen function of Window3DController
- (IBAction) fullScreenMenu: (id) sender
{
	if (FullScreenOn == -1){
		NSLog(@"FullScreen Mode Disabled");
	}
	
    else if( FullScreenOn == YES )									// we need to go back to non-full screen
    {
        [StartingWindow setContentView: contentView];
		//		[FullScreenWindow setContentView: nil];
		
        [FullScreenWindow setDelegate:nil];
        [FullScreenWindow close];
        [FullScreenWindow release];
		// Added SilvanWidmer 04-03
        if([view StereoVisionOn])
			[view adjustWindowContent:[StartingWindow frame].size];
		
        [StartingWindow makeKeyAndOrderFront: self];
        FullScreenOn = NO;
    }
    else														// FullScreenOn == NO
    {
        unsigned int windowStyle;
        NSRect       contentRect;
		
        StartingWindow = [self window];
        windowStyle    = NSBorderlessWindowMask; 
        contentRect    = [[NSScreen mainScreen] frame];
        FullScreenWindow = [[NSFullScreenWindow alloc] initWithContentRect:contentRect styleMask: windowStyle backing:NSBackingStoreBuffered defer: NO];
        if(FullScreenWindow != nil)
        {
            [FullScreenWindow setTitle: @"myWindow"];			
            [FullScreenWindow setReleasedWhenClosed: NO];
            [FullScreenWindow setLevel: NSScreenSaverWindowLevel - 1];
            [FullScreenWindow setBackgroundColor:[NSColor blackColor]];
			
            contentView = [[self window] contentView];
            [FullScreenWindow setContentView: contentView];
			
			if([view StereoVisionOn])
				[view adjustWindowContent:[contentView frame].size];
            
            [FullScreenWindow makeKeyAndOrderFront: self];
            [FullScreenWindow makeFirstResponder: [self view]];
			
            [FullScreenWindow setDelegate: self];
            [FullScreenWindow setWindowController: self];
            
            FullScreenOn = YES;
        }
    }
}


- (IBAction) ApplyGeometrieSettings: (id) sender
{
	[VRGeometrieSettingsWindow orderOut:sender];
	[NSApp endSheet:VRGeometrieSettingsWindow returnCode:[sender tag]];
	
	double height = [heightValue doubleValue];
    double distance = [distanceValue doubleValue];
	double eyeDist = [eyeDistance doubleValue];
	
	if (height < 0.01)
		height=0.01;
	if (distance < 0.01)
		distance=0.01;
	
	if([sender tag])
	{
		[[NSUserDefaults standardUserDefaults] setDouble: [distanceValue doubleValue] forKey: @"DISTANCETOSCREEN"];
		[[NSUserDefaults standardUserDefaults] setDouble: [heightValue doubleValue] forKey: @"SCREENHEIGHT"];
		[[NSUserDefaults standardUserDefaults] setDouble: [eyeDistance doubleValue] forKey: @"EYESEPARATION"];
		
		[view setNewGeometry: height: distance: eyeDist];	
	}
}



- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
//    
//	if ([itemIdent isEqualToString: QTExportVRToolbarItemIdentifier])
//	{
//		[toolbarItem setLabel: NSLocalizedString(@"Export QTVR",nil)];
//		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export QTVR",nil)];
//		[toolbarItem setToolTip: NSLocalizedString(@"Export this image in a Quicktime VR file",nil)];
//		[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
//		[toolbarItem setTarget: view];
//		[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
//    }
//	else
        if ([itemIdent isEqualToString: StereoIdentifier])
	{
        [toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Stereo",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Switch Stereo Mode ON/OFF",nil)];
		[toolbarItem setView: stereoIconView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([stereoIconView frame]), NSHeight([stereoIconView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([stereoIconView frame]), NSHeight([stereoIconView frame]))];
		
		/*
		[toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Stereo",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Switch Stereo Mode ON/OFF",nil)];
		[toolbarItem setImage: [NSImage imageNamed: StereoIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(SwitchStereoMode:)];*/
    }
	else if ([itemIdent isEqualToString: MailToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Email",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Email",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image",nil)];
		[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(sendMail:)];
    }
	else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Reset to initial 3D view",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(resetImage:)];
    }
	else if ([itemIdent isEqualToString: RevertToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Revert",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Revert",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Revert series by re-loading images from disk",nil)];
		[toolbarItem setImage: [NSImage imageNamed: RevertToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(revertSeries:)];
	}
	else if ([itemIdent isEqualToString: ShadingToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Shading",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Shading",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Shading Properties",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: shadingView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([shadingView frame]), NSHeight([shadingView frame]))];
    }
	else if ([itemIdent isEqualToString: EngineToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Engine",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Engine",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Engine",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: engineView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
    }
	else if ([itemIdent isEqualToString: PerspectiveToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Perspective",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Perspective",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Perspective Properties",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: perspectiveView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([perspectiveView frame]), NSHeight([perspectiveView frame]))];
    }
	else if ([itemIdent isEqualToString: QTExportToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Movie Export",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image in a Quicktime file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else if ([itemIdent isEqualToString: PhotosToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Photos",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Photos",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Export this image to Photos",nil)];
		[toolbarItem setImage: [NSImage imageNamed:@"Photos"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(export2iPhoto:)];
    }
	else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
		[toolbarItem setLabel:NSLocalizedString( @"DICOM File",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"DICOM",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image in a DICOM file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
	//	else if ([itemIdent isEqualToString: SendToolbarItemIdentifier]) {
	//        
	//	[toolbarItem setLabel: @"Send DICOM"];
	//	[toolbarItem setPaletteLabel: @"Send DICOM"];
	//        [toolbarItem setToolTip: @"Send this image to a DICOM node"];
	//	[toolbarItem setImage: [NSImage imageNamed: SendToolbarItemIdentifier]];
	//	[toolbarItem setTarget: self];
	//	[toolbarItem setAction: @selector(exportDICOMPACS:)];
	//    }
	else if ([itemIdent isEqualToString: CroppingToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Crop",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Cropping Cube",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Show and manipulate cropping cube",nil)];
		[toolbarItem setImage: [NSImage imageNamed: CroppingToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(showCropCube:)];
    }
	else if ([itemIdent isEqualToString: OrientationToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Orientation",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientation Cube",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Show orientation cube",nil)];
		[toolbarItem setImage: [NSImage imageNamed: OrientationToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(switchOrientationWidget:)];
    }
	else if ([itemIdent isEqualToString: CaptureToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Best",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Best Rendering",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Render this image at the best resolution",nil)];
		[toolbarItem setImage: [NSImage imageNamed: CaptureToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(bestRendering:)];
    }
    else if([itemIdent isEqualToString: WLWWToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT & Opacity",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"WL/WW & CLUT & Opacity",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Change the WL/WW & CLUT & Opacity",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: WLWWView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
		[[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
	else if([itemIdent isEqualToString: MovieToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"4D Player",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"4D Player",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: movieView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
    }
	else if([itemIdent isEqualToString: OrientationsViewToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Orientations", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientations", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Orientations", nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: OrientationsView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([OrientationsView frame]), NSHeight([OrientationsView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([OrientationsView frame]), NSHeight([OrientationsView frame]))];
    }
	else if([itemIdent isEqualToString: ConvolutionViewToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Filters", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Filters", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Filters", nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: convolutionView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([convolutionView frame]), NSHeight([convolutionView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([convolutionView frame]), NSHeight([convolutionView frame]))];
    }
	else if([itemIdent isEqualToString: BackgroundColorViewToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Color", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Color", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Background Color", nil)];
		
		[toolbarItem setView: BackgroundColorView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([BackgroundColorView frame]), NSHeight([BackgroundColorView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([BackgroundColorView frame]), NSHeight([BackgroundColorView frame]))];
    }
	else if([itemIdent isEqualToString: ScissorStateToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"3D Scissor State", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Scissor State", nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: scissorStateView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
    }
	else if([itemIdent isEqualToString: BlendingToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel:NSLocalizedString( @"Fusion",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: BlendingView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
    }
	else if([itemIdent isEqualToString: ModeToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel:NSLocalizedString( @"Mode",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Mode",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Mode",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: modeView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([modeView frame]), NSHeight([modeView frame]))];
	}
	else if([itemIdent isEqualToString: LODToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Level of Detail",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Level of Detail",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"Change Level of Detail",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: LODView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([LODView frame]), NSHeight([LODView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
	else if([itemIdent isEqualToString: ToolsToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: toolsView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
	else if([itemIdent isEqualToString: FlyThruToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Fly Thru",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Fly Thru",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Fly Thru Set up",nil)];
		
		[toolbarItem setImage: [NSImage imageNamed: FlyThruToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(flyThruControllerInit:)];
    }
	else if ([itemIdent isEqualToString: ROIManagerToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"ROI Manager",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"ROI Manager",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"ROI Manager",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ROIManagerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(roiGetManager:)];
    }
	else if ([itemIdent isEqualToString: PresetsPanelToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"3D Presets",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"3D Presets",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Show 3D Presets Panel",nil)];
		[toolbarItem setImage: [NSImage imageNamed: PresetsPanelToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(load3DSettings:)];
    }
	else if( [itemIdent isEqualToString: ClippingRangeViewToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Clipping",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Clipping",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Clipping",nil)];
		
		[toolbarItem setView: ClippingRangeView];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([ClippingRangeView frame]), NSHeight([ClippingRangeView frame]))];
	}
	else if( [itemIdent isEqualToString: CLUTEditorsViewToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"CLUT Editor",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"CLUT Editor",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"CLUT Editor",nil)];
		
		[toolbarItem setView: CLUTEditorsView];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([CLUTEditorsView frame]), NSHeight([CLUTEditorsView frame]))];
	}
	else
	{
		[toolbarItem release];
		toolbarItem = nil;
	}
	
	return [toolbarItem autorelease];
}

// { Begin addition by P. Thevenaz on June 11, 2010
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    
	if( [style isEqualToString:@"standard"])
		return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
												WLWWToolbarItemIdentifier,
												CLUTEditorsViewToolbarItemIdentifier,
												PresetsPanelToolbarItemIdentifier,
												LODToolbarItemIdentifier,
												CaptureToolbarItemIdentifier,
												CroppingToolbarItemIdentifier,
												OrientationToolbarItemIdentifier,
												ShadingToolbarItemIdentifier,
												StereoIdentifier,						// <- added with respect to "VRController.mm" (P. Thevenaz)
												PerspectiveToolbarItemIdentifier,
												ConvolutionViewToolbarItemIdentifier,
												ClippingRangeViewToolbarItemIdentifier,
												NSToolbarFlexibleSpaceItemIdentifier,
												QTExportToolbarItemIdentifier,
//												QTExportVRToolbarItemIdentifier,
												OrientationsViewToolbarItemIdentifier,
												ResetToolbarItemIdentifier,
												RevertToolbarItemIdentifier,
												ExportToolbarItemIdentifier,
												FlyThruToolbarItemIdentifier,
												nil];
	else
		return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
												ModeToolbarItemIdentifier,
												WLWWToolbarItemIdentifier,
												LODToolbarItemIdentifier,
												CaptureToolbarItemIdentifier,
												BlendingToolbarItemIdentifier,
												CroppingToolbarItemIdentifier,
												OrientationToolbarItemIdentifier,
												NSToolbarFlexibleSpaceItemIdentifier,
												QTExportToolbarItemIdentifier,
												OrientationsViewToolbarItemIdentifier,
												ResetToolbarItemIdentifier,
												ExportToolbarItemIdentifier,
												nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette
	
	if( [style isEqualToString:@"standard"])
	{
		NSMutableArray * a = [NSMutableArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											WLWWToolbarItemIdentifier,
											CLUTEditorsViewToolbarItemIdentifier,
											PresetsPanelToolbarItemIdentifier,
											LODToolbarItemIdentifier,
											CaptureToolbarItemIdentifier,
											CroppingToolbarItemIdentifier,
											OrientationToolbarItemIdentifier,
											ShadingToolbarItemIdentifier,
											PerspectiveToolbarItemIdentifier,
											OrientationsViewToolbarItemIdentifier,
											ToolsToolbarItemIdentifier,
											ModeToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											StereoIdentifier,						// <- added with respect to "VRController.mm" (P. Thevenaz)
											QTExportToolbarItemIdentifier,
											PhotosToolbarItemIdentifier,
											//QTExportVRToolbarItemIdentifier,
											MailToolbarItemIdentifier,
											ResetToolbarItemIdentifier,
											RevertToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											FlyThruToolbarItemIdentifier,
											ScissorStateToolbarItemIdentifier,
											ROIManagerToolbarItemIdentifier,
											ConvolutionViewToolbarItemIdentifier,
											BackgroundColorViewToolbarItemIdentifier,
											ClippingRangeViewToolbarItemIdentifier,
											nil];
		
//		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"showGPUEngineRendering"])
//			[a addObject: EngineToolbarItemIdentifier];
			
		return a;
	}
	else
		return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											WLWWToolbarItemIdentifier,
											CLUTEditorsViewToolbarItemIdentifier,
											LODToolbarItemIdentifier,
											CaptureToolbarItemIdentifier,
											CroppingToolbarItemIdentifier,
											OrientationToolbarItemIdentifier,
											OrientationsViewToolbarItemIdentifier,
											QTExportToolbarItemIdentifier,
											PhotosToolbarItemIdentifier,
											MailToolbarItemIdentifier,
											ResetToolbarItemIdentifier,
											RevertToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											nil];
}
// end addition by P. Thevenaz on June 11, 2010}

@end
#endif
