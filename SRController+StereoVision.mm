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
#ifdef _STEREO_VISION_


#import "SRController+StereoVision.h"
#import "SRController.h"
#import "DCMView.h"
#import "iPhoto.h"
#import "SRView.h"
#import	"SRView+StereoVision.h"
#import "SRFlyThruAdapter.h"
#import "ROI.h"
#import "ROIVolumeManagerController.h"
#import "ROIVolume.h"
#import "BrowserController.h"
#import "Notifications.h"

static NSString* 	MIPToolbarIdentifier				= @"SR Toolbar Identifier";
static NSString*	QTExportToolbarItemIdentifier		= @"QTExport.pdf";
static NSString*	iPhotoToolbarItemIdentifier			= @"iPhoto.icns";
static NSString*	StereoIdentifier					= @"Stereo.icns";
//static NSString*	QTExportVRToolbarItemIdentifier		= @"QTExportVR.icns";
static NSString*	SRSettingsToolbarItemIdentifier		= @"SRSettings.tif";
static NSString*	BSRSettingsToolbarItemIdentifier	= @"BSRSettings.tif";
static NSString*	ToolsToolbarItemIdentifier			= @"Tools";
static NSString*	Export3DFileFormat					= @"3DExportFileFormat";
static NSString*	FlyThruToolbarItemIdentifier		= @"FlyThru.pdf";
static NSString*	OrientationToolbarItemIdentifier	= @"OrientationWidget.tiff";
static NSString*	ToggleDisplay3DpointsItemIdentifier	= @"Point.tiff";
static NSString*	PerspectiveToolbarItemIdentifier	= @"Perspective";
static NSString*	ResetToolbarItemIdentifier			= @"Reset.pdf";
static NSString*	ROIManagerToolbarItemIdentifier		= @"ROIManager.pdf";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	OrientationsViewToolbarItemIdentifier		= @"OrientationsView";
static NSString*	BackgroundColorViewToolbarItemIdentifier		= @"BackgroundColorView";


@implementation SRController (StereoVision)


- (void) dealloc
{
    NSLog(@"Dealloc SRController");
	
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
	[fileList release];
    [pixList release];
	[volumeData release];
	
	[toolbar setDelegate: nil];
	[toolbar release];

	[roi2DPointsArray release];
	[sliceNumber2DPointsArray release];
	[x2DPointsArray release];
	[y2DPointsArray release];
	[z2DPointsArray release];
	[viewer2D release];
	[roiVolumes release];
		
	[super dealloc];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == viewer2D)
	{
		[self offFullScreen];
		[[self window] close];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixWindow3dCloseNotification object: self userInfo: 0];
	
    [[self window] setDelegate:nil];
    
    [self autorelease];
}

-(IBAction) ApplySettings:(id) sender
{
    [SRSettingsWindow orderOut:sender];
    
    [NSApp endSheet:SRSettingsWindow returnCode:[sender tag]];
    	
    if( [sender tag])   //User clicks OK Button
    {
		[self renderSurfaces];
		//Added SilvanWidmer 18-08-09
		if([view StereoVisionOn])
			[view updateStereoLeftRight];
		
		[view setNeedsDisplay:YES];
    }
	
}

- (IBAction) ApplyGeometrieSettings: (id) sender
{
	[SRGeometrieSettingsWindow orderOut:sender];

	[NSApp endSheet:SRGeometrieSettingsWindow returnCode:[sender tag]];
	
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

//	if ([itemIdent isEqualToString: QTExportVRToolbarItemIdentifier]) {
//		
//		[toolbarItem setLabel: NSLocalizedString(@"Export QTVR",nil)];
//		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export QTVR",nil)];
//		[toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime VR file",nil)];
//		[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
//		[toolbarItem setTarget: view];
//		[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
//	}	
//	else
        if ([itemIdent isEqualToString: StereoIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Stereo",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Switch Stereo Modes",nil)];
		[toolbarItem setView: stereoIconView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([stereoIconView frame]), NSHeight([stereoIconView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([stereoIconView frame]), NSHeight([stereoIconView frame]))];
	}
	else if ([itemIdent isEqualToString: QTExportToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(exportQuicktime:)];
	}
	else if ([itemIdent isEqualToString: iPhotoToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"iPhoto",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export this series to iPhoto",nil)];
		[toolbarItem setImage: [NSImage imageNamed: iPhotoToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(export2iPhoto:)];
	}
	else if ([itemIdent isEqualToString: Export3DFileFormat]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Export 3D-SR",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Export 3D-SR",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export this series in a 3D file format",nil)];
		[toolbarItem setView: export3DView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([export3DView frame]), NSHeight([export3DView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([export3DView frame]), NSHeight([export3DView frame]))];
	}
	else if ([itemIdent isEqualToString: SRSettingsToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Surface Settings",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Surface Settings",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"change Surface Settings",nil)];
		[toolbarItem setImage: [NSImage imageNamed: SRSettingsToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(ChangeSettings:)];
	}
	else if ([itemIdent isEqualToString: BSRSettingsToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Fusion Surface Settings",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Fusion Surface Settings",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"change Fusion Surface Settings",nil)];
		[toolbarItem setImage: [NSImage imageNamed: BSRSettingsToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(BChangeSettings:)];
	}
	else if ([itemIdent isEqualToString: OrientationToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Orientation",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientation Cube",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Show orientation cube",nil)];
		[toolbarItem setImage: [NSImage imageNamed: OrientationToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(switchOrientationWidget:)];
	}
	else if([itemIdent isEqualToString: ToolsToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel:NSLocalizedString( @"Mouse button function",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Mouse button function",nil)];
		
		[toolbarItem setView: toolsView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	}
	else if([itemIdent isEqualToString: FlyThruToolbarItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Fly Thru",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Fly Thru",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Fly Thru Set up",nil)];
		
		[toolbarItem setImage: [NSImage imageNamed: FlyThruToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(flyThruControllerInit:)];
		
	}
	else if([itemIdent isEqualToString: ToggleDisplay3DpointsItemIdentifier]) {
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Show/Hide",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Show/Hide 3D points",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Show/Hide 3D points",nil)];
		
		[toolbarItem setImage: [NSImage imageNamed: ToggleDisplay3DpointsItemIdentifier]];
		[toolbarItem setTarget: [self view]];
		[toolbarItem setAction: @selector(toggleDisplay3DPoints)];
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
	else if ([itemIdent isEqualToString: ROIManagerToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"ROI Manager",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"ROI Manager",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"ROI Manager",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ROIManagerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(roiGetManager:)];
	}
	else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Reset to initial 3D view",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(resetImage:)];
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
	else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
		
		[toolbarItem setLabel:NSLocalizedString( @"DICOM File",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Save as DICOM",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Export this image in a DICOM file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: view];
		[toolbarItem setAction: @selector(exportDICOMFile:)];
	}
	else
	{
		[toolbarItem release];
		toolbarItem = nil;
	}
	return [toolbarItem autorelease];
}
	

- (void)windowDidResize:(NSNotification *)notification
{
	if([view StereoVisionOn])
	{
		[view adjustWindowContent:[[view window]frame].size];
	}
}

//Added SilvanWidmer 21-08-09
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
		// Added SilvanWidmer 21-08
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


@end

#endif