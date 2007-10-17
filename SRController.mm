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
#import "SRController.h"
#import "DCMView.h"
#import "iPhoto.h"
#import "SRView.h"
#import "SRFlyThruAdapter.h"
#import "ROI.h"
#import "ROIVolumeManagerController.h"
#import "ROIVolume.h"

//#define roi3Dvolume

extern "C"
{
extern NSString * documentsDirectory();
}

static NSString* 	MIPToolbarIdentifier				= @"SR Toolbar Identifier";
static NSString*	QTExportToolbarItemIdentifier		= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier			= @"iPhoto.icns";
static NSString*	StereoIdentifier					= @"Stereo.icns";
static NSString*	QTExportVRToolbarItemIdentifier		= @"QTExportVR.icns";
static NSString*	SRSettingsToolbarItemIdentifier		= @"SRSettings.tif";
static NSString*	BSRSettingsToolbarItemIdentifier	= @"BSRSettings.tif";
static NSString*	ToolsToolbarItemIdentifier			= @"Tools";
static NSString*	Export3DFileFormat					= @"3DExportFileFormat";
static NSString*	FlyThruToolbarItemIdentifier		= @"FlyThru.tif";
static NSString*	OrientationToolbarItemIdentifier	= @"OrientationWidget.tiff";
static NSString*	ToggleDisplay3DpointsItemIdentifier	= @"Point.tiff";
static NSString*	PerspectiveToolbarItemIdentifier	= @"Perspective";
static NSString*	ResetToolbarItemIdentifier			= @"Reset.tiff";
static NSString*	ROIManagerToolbarItemIdentifier		= @"ROIManager.tiff";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	OrientationsViewToolbarItemIdentifier		= @"OrientationsView";
static NSString*	BackgroundColorViewToolbarItemIdentifier		= @"BackgroundColorView";

//static NSString*	LODToolbarItemIdentifier		= @"LOD";
//static NSString*	BlendingToolbarItemIdentifier   = @"2DBlending";



@implementation SRController

- (IBAction) roiDeleteAll:(id) sender
{
	[viewer2D roiDeleteAll: sender];
}

- (IBAction) setOrientation:(id) sender
{
	switch( [[sender selectedCell] tag])
	{
		case 0:
			[view axView: self];
		break;
		
		case 1:
			[view coView: self];
		break;
		
		case 2:
			[view saView: self];
		break;
		
		case 3:
			[view saViewOpposite: self];
		break;
	}
}

- (void) windowDidLoad
{
    [self setupToolbar];
	[self setResolution:0.5];
	[self setShouldDecimate:YES];
	[self setShouldSmooth:YES];
	[self setFirstSurface:300.0];
	[self setSecondSurface: -500.0];
	[self setFirstTransparency: 1.0];
	[self setSecondTransparency: 1.0];
	[self setDecimate: 0.5];
	[self setSmooth: 20];
	[self setFirstColor: [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
	[self setSecondColor: [NSColor colorWithCalibratedRed:1.0 green:0.592 blue:0.608 alpha:1.0]];
	[self setUseFirstSurface:YES];
	[self setUseSecondSurface:NO];
	
	[self setShouldRenderFusion:NO];
	[self setFusionResolution:0.5];
	[self setFusionShouldDecimate:YES];
	[self setFusionShouldSmooth:YES];
	[self setFusionFirstSurface:300.0];
	[self setFusionSecondSurface: -500.0];
	[self setFusionFirstTransparency: 1.0];
	[self setFusionSecondTransparency: 1.0];
	[self setFusionDecimate: 0.5];
	[self setFusionSmooth: 20];
	[self setFusionFirstColor: [NSColor colorWithCalibratedRed:1.0 green:0.285 blue:0.0 alpha:1.0]];
	[self setFusionSecondColor: [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1.0]];
	[self setFusionUseFirstSurface:YES];
	[self setFusionUseSecondSurface:NO];
	

	//[self createContextualMenu];
}

-(ViewerController*) blendingController
{
	return blendingController;
}

-(NSMutableArray*) pixList { return pixList;}

- (NSArray*) fileList
{
	return fileList;
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
	
    pixList = pix;
	volumeData = vData;

    DCMPix  *firstObject = [pixList objectAtIndex:0];
    float sliceThickness = fabs( [firstObject sliceInterval]);  //fabs( [firstObject sliceLocation] - [[pixList objectAtIndex:1] sliceLocation]);
    
    if( sliceThickness == 0)
    {
		sliceThickness = [firstObject sliceThickness];
		
		testInterval = NO;
		
		if( sliceThickness > 0) NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval",nil),  NSLocalizedString(@"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		else
		{
			NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval/thickness",nil), NSLocalizedString( @"Problems with slice thickness/interval to do a 3D reconstruction.",nil), NSLocalizedString(@"OK",nil), nil, nil);
			return 0L;
		}
    }
    
    // CHECK IMAGE SIZE
    for( i =0 ; i < [pixList count]; i++)
    {
        if( [firstObject pwidth] != [[pixList objectAtIndex:i] pwidth]) err = -1;
        if( [firstObject pheight] != [[pixList objectAtIndex:i] pheight]) err = -1;
    }
    if( err)
    {
        NSRunCriticalAlertPanel( NSLocalizedString(@"Images size",nil),  NSLocalizedString(@"These images don't have the same height and width to allow a 3D reconstruction...",nil), NSLocalizedString(@"OK",nil), nil, nil);
        return 0L;
    }
    
    // CHECK IMAGE SIZE
//	if( testInterval)
//	{
//		float prevLoc = [firstObject sliceLocation];
//		for( i = 1 ; i < [pixList count]; i++)
//		{
//			if( fabs( sliceThickness - fabs( [[pixList objectAtIndex:i] sliceLocation] - prevLoc)) > 0.1) err = -1;
//			prevLoc = [[pixList objectAtIndex:i] sliceLocation];
//		}
//		if( err)
//		{
//			if( NSRunCriticalAlertPanel( @"Slices location",  @"Slice thickness/interval is not exactly equal for all images. This could distord the 3D reconstruction...", @"Continue", @"Cancel", nil) != NSAlertDefaultReturn) return 0L;
//			err = 0;
//		}
//	}
	fileList = f;
	[fileList retain];
	
	[pixList retain];
	[volumeData retain];
    self = [super initWithWindowNibName:@"SR"];
    
    [[self window] setDelegate:self];
    
    err = [view setPixSource:pixList :(float*) [volumeData bytes]];
    if( err != 0)
    {
       // [self dealloc];
        return 0L;
    }
    
	blendingController = bC;
	if( blendingController) // Blending! Activate image fusion
	{
		[view setBlendingPixSource: blendingController];
	}

	roi2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	sliceNumber2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	x2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	y2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
	z2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];

	viewer2D = [vC retain];
	if (viewer2D)
	{		
		long i, j;
		float x, y, z;
		NSMutableArray	*curRoiList;
		ROI	*curROI;
		
		for(i=0; i<[[[viewer2D imageView] dcmPixList] count]; i++)
		{
			curRoiList = [[viewer2D roiList] objectAtIndex: i];
			for(j=0; j<[curRoiList count];j++)
			{
				curROI = [curRoiList objectAtIndex:j];
				if ([curROI type] == t2DPoint)
				{
					float location[ 3 ];
					
					[[[viewer2D pixList] objectAtIndex: i] convertPixX: [[[curROI points] objectAtIndex:0] x] pixY: [[[curROI points] objectAtIndex:0] y] toDICOMCoords: location];
					
					x =location[ 0 ];
					y =location[ 1 ];
					z =location[ 2 ];

					// add the 3D Point to the SR view
					[[self view] add3DPoint:  x : y : z];
					// add the 2D Point to our list
					[roi2DPointsArray addObject:curROI];
					[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:i]];
					[x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
					[y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
					[z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
				}
			}
		}
	}
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver: self
		selector: @selector(remove3DPoint:)
		name: @"removeROI"
		object: nil];
	[nc addObserver: self
		selector: @selector(add3DPoint:)
		//name: @"roiChange"
		name: @"roiSelected"
		object: nil];
	[nc	addObserver: self
					selector: @selector(CloseViewerNotification:)
					name: @"CloseViewerNotification"
					object: nil];
//	curWLWWMenu = @"Other";
//	
//	NSNotificationCenter *nc;
//    nc = [NSNotificationCenter defaultCenter];
//    [nc addObserver: self
//           selector: @selector(UpdateWLWWMenu:)
//               name: @"UpdateWLWWMenu"
//             object: nil];
//	
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
//	
//	curCLUTMenu = NSLocalizedString(@"No CLUT", nil);
//	
//    [nc addObserver: self
//           selector: @selector(UpdateCLUTMenu:)
//               name: @"UpdateCLUTMenu"
//             object: nil];
//	
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	
	roiVolumes = [[NSMutableArray alloc] initWithCapacity:0];
#ifdef roi3Dvolume
	[self computeROIVolumes];
	[self displayROIVolumes];
#endif
	//[[self window] performZoom:self];
	
    return self;
}

-(void) dealloc
{
    NSLog(@"Dealloc SRController");
	
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
	[fileList release];
    [pixList release];
	[volumeData release];
	
	[toolbar setDelegate: 0L];
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
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Window3DClose" object: self userInfo: 0];
	
    [[self window] setDelegate:nil];
    
    [self release];
}

//-(NSMatrix*) toolsMatrix
//{
//	return toolsMatrix;
//}

-(void) setDefaultTool:(id) sender
{
    id          theCell = [sender selectedCell];
    
    if( [theCell tag] >= 0)
    {
        [view setCurrentTool: [theCell tag]];
    }
}

-(IBAction) SettingsPopup:(id) sender
{
	
	switch((long) [sender tag])
	{
		case 1:
			[self setFirstSurface: -500.0];
			break;
		case 11:
			[self setSecondSurface: -500.];
			break;
		
		case 2:
			[self setFirstSurface: 500.0];
			break;
		case 12:
			[self setSecondSurface: 500.0];
			break;
		
		case 3:
			[self setFirstSurface: 2000.0];
			break;
		case 13:
			[self setSecondSurface: 2000.0];
			break;
	}
}

-(IBAction) ApplySettings:(id) sender
{
    [SRSettingsWindow orderOut:sender];
    
    [NSApp endSheet:SRSettingsWindow returnCode:[sender tag]];
    	
    if( [sender tag])   //User clicks OK Button
    {
		[self renderSurfaces];
    }
	
}

- (void)renderSurfaces{
	WaitRendering *www = [[WaitRendering alloc] init:@"Preparing 3D Iso Surface..."];
	[www start];

	// FIRST SURFACE
	if( _useFirstSurface)
			[view changeActor   :(long) 0
								:_resolution
								:_firstTransparency
								:[_firstColor redComponent]
								:[_firstColor greenComponent]
								:[_firstColor blueComponent]		
								:_firstSurface
								:_shouldDecimate
								:_decimate
								:_shouldSmooth
								:_smooth];
		else
			[view deleteActor: (long) 0];
		
		// SECOND SURFACE
		if( _useSecondSurface)	
			[view changeActor   :(long) 1
								:_resolution
								:_secondTransparency
								:[_secondColor redComponent]
								:[_secondColor greenComponent]
								:[_secondColor blueComponent]
								:_secondSurface
								:_shouldDecimate
								:_decimate
								:_shouldDecimate
								:_smooth];
		else
			[view deleteActor: (long) 1];
  
	
	[www end];
	[www close];
	[www release];

}

- (void) ChangeSettings:(id) sender
{
    [NSApp beginSheet: SRSettingsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(IBAction) BSettingsPopup:(id) sender
{

	
	switch((long) [sender tag])
	{
		case 1:
			[self setFusionFirstSurface: -500.0];
			break;
		case 11:
			[self setFusionSecondSurface: -500.];
			break;
		
		case 2:
			[self setFusionFirstSurface: 500.0];
			break;
		case 12:
			[self setFusionSecondSurface: 500.0];
			break;
		
		case 3:
			[self setFusionFirstSurface: 2000.0];
			break;
		case 13:
			[self setFusionSecondSurface: 2000.0];
			break;
	}
}

- (void)renderFusionSurfaces{
	if( _fusionUseFirstSurface)
		
		[view BchangeActor   :(long) 0
								: _fusionResolution
								: _fusionFirstTransparency
								:[_fusionFirstColor redComponent]
								:[_fusionFirstColor greenComponent]
								:[_fusionFirstColor blueComponent]
								: _fusionFirstSurface
								: _fusionShouldDecimate
								: _fusionDecimate
								: _fusionShouldSmooth
								: _fusionSmooth];
	else
			[view BdeleteActor: (long) 0];
		
		// SECOND SURFACE
	if(_fusionUseSecondSurface)
	
		[view BchangeActor  :(long) 1
								: _fusionResolution
								: _fusionSecondTransparency
								:[_fusionSecondColor redComponent]
								:[_fusionSecondColor greenComponent]
								:[_fusionSecondColor blueComponent]
								: _fusionSecondSurface
								: _fusionShouldDecimate
								: _fusionDecimate
								: _fusionShouldSmooth
								: _fusionSmooth];
	else
		[view BdeleteActor: (long) 1];

}

-(IBAction) BApplySettings:(id) sender
{
    [BSRSettingsWindow orderOut:sender];
    
    [NSApp endSheet:BSRSettingsWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		[self setShouldRenderFusion:YES];
		[self renderFusionSurfaces];
	}
}

- (void) BChangeSettings:(id) sender
{
    [NSApp beginSheet: BSRSettingsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: MIPToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
    
//    [window makeKeyAndOrderFront:nil];
}

- (IBAction)customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
	if ([itemIdent isEqual: QTExportVRToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export QTVR",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export QTVR",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime VR file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
    }	
	else if ([itemIdent isEqual: StereoIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Stereo",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Switch Stereo Mode ON/OFF",nil)];
	[toolbarItem setImage: [NSImage imageNamed: StereoIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(SwitchStereoMode:)];
    }
	else if ([itemIdent isEqual: QTExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else if ([itemIdent isEqual: iPhotoToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"iPhoto",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series to iPhoto",nil)];
	[toolbarItem setImage: [NSImage imageNamed: iPhotoToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(export2iPhoto:)];
    }
	else if ([itemIdent isEqual: Export3DFileFormat]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export 3D-SR",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Export 3D-SR",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a 3D file format",nil)];
	[toolbarItem setView: export3DView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([export3DView frame]), NSHeight([export3DView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([export3DView frame]), NSHeight([export3DView frame]))];
    }
	else if ([itemIdent isEqual: SRSettingsToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Surface Settings",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Surface Settings",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"change Surface Settings",nil)];
	[toolbarItem setImage: [NSImage imageNamed: SRSettingsToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(ChangeSettings:)];
    }
	else if ([itemIdent isEqual: BSRSettingsToolbarItemIdentifier]) {
	
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
     else if([itemIdent isEqual: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel:NSLocalizedString( @"Mouse button function",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Mouse button function",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the mouse function",nil)];
	
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
	else if([itemIdent isEqual: FlyThruToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fly Thru Set up",nil)];
	
	[toolbarItem setImage: [NSImage imageNamed: FlyThruToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(flyThruControllerInit:)];
	
    }
	else if([itemIdent isEqual: ToggleDisplay3DpointsItemIdentifier]) {
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
	else {
	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
	// Returning nil will inform the toolbar this kind of item is not supported 
	toolbarItem = nil;
    }
     return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
											SRSettingsToolbarItemIdentifier,
											BSRSettingsToolbarItemIdentifier,
											StereoIdentifier,
											OrientationToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											ROIManagerToolbarItemIdentifier,
											QTExportToolbarItemIdentifier,
											QTExportVRToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											Export3DFileFormat,
											OrientationsViewToolbarItemIdentifier,
											FlyThruToolbarItemIdentifier,
											BackgroundColorViewToolbarItemIdentifier,
                                            nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
                                        NSToolbarFlexibleSpaceItemIdentifier,
                                        NSToolbarSpaceItemIdentifier,
                                        NSToolbarSeparatorItemIdentifier,
                                        //WLWWToolbarItemIdentifier,
										//LODToolbarItemIdentifier,
										//CaptureToolbarItemIdentifier,
										//CroppingToolbarItemIdentifier,
										SRSettingsToolbarItemIdentifier,
										BSRSettingsToolbarItemIdentifier,
										StereoIdentifier,
										OrientationToolbarItemIdentifier,
										QTExportToolbarItemIdentifier,
										iPhotoToolbarItemIdentifier,
										QTExportVRToolbarItemIdentifier,
										Export3DFileFormat,
										OrientationsViewToolbarItemIdentifier,
                                        ToolsToolbarItemIdentifier,
										ROIManagerToolbarItemIdentifier,
										FlyThruToolbarItemIdentifier,
										ToggleDisplay3DpointsItemIdentifier,
										PerspectiveToolbarItemIdentifier,
										ResetToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
										BackgroundColorViewToolbarItemIdentifier,
                                        nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
//    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
	
//	[addedItem retain];
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
//	[removedItem retain];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = YES;
	if ([[toolbarItem itemIdentifier] isEqual: BSRSettingsToolbarItemIdentifier])
    {
        if(blendingController == 0L) enable = NO;
    }
    return enable;
}


-(void) export2iPhoto:(id) sender
{
	iPhoto		*ifoto;
	NSImage		*im = [view nsimage:NO];
	
	NSArray		*representations;
	NSData		*bitmapData;
	
	representations = [im representations];
	
	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
	[bitmapData writeToFile:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
	
	ifoto = [[iPhoto alloc] init];
	[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
	[ifoto release];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:0L file:@"3D SR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"tif"];
	
	if( [panel runModalForDirectory:0L file:@"3D SR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

// Fly Thru

- (SRView*) view
{	
	return view;
}

//- (IBAction) flyThruButtonMenu:(id) sender
//{
//	[flyThruController flyThruTag: [sender tag]];
//}

- (IBAction) flyThruControllerInit:(id) sender
{
	//Only open 1 fly through controller
	NSArray *winList = [NSApp windows];
	long	i;
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"FlyThru"])
		{
			[[flyThruController window] makeKeyAndOrderFront :sender];
			return;
		}
	}

	//flythru = [[FlyThru alloc] init];
	FTAdapter = [[SRFlyThruAdapter alloc] initWithSRController: self];
	flyThruController = [[FlyThruController alloc] initWithFlyThruAdapter:FTAdapter];
	[FTAdapter release];
	[flyThruController loadWindow];
	[[flyThruController window] makeKeyAndOrderFront :sender];
	[flyThruController setWindow3DController: self];
}

- (void) add2DPoint: (float) x : (float) y : (float) z
{
	if (viewer2D)
	{
		DCMPix *firstDCMPix = [[viewer2D pixList] objectAtIndex: 0];
		DCMPix *secondDCMPix = [[viewer2D pixList] objectAtIndex: 1];
		// compute 2D Coordinates
		float dc[3], sc[3];
		dc[0] = x;
		dc[1] = y;
		dc[2] = z;
		[view convert3Dto2Dpoint:dc :sc];
		
		// find the slice where we want to introduce the point
		float sliceInterval = [secondDCMPix sliceLocation] - [firstDCMPix sliceLocation];
		long sliceNumber = sc[2]+0.5;
		
		if (sliceNumber>=0 && sliceNumber<[[viewer2D pixList] count])
		{
			// Create the new 2D Point ROI
			ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :[firstDCMPix pixelSpacingX] :[firstDCMPix pixelSpacingY] :NSMakePoint( [firstDCMPix originX], [firstDCMPix originY])];
			NSRect irect;
			irect.origin.x = sc[0];
			irect.origin.y = sc[1];
			irect.size.width = irect.size.height = 0;
			[new2DPointROI setROIRect:irect];
			[[viewer2D imageView] roiSet:new2DPointROI];
			// add the 2D Point ROI to the ROI list
			[[[viewer2D roiList] objectAtIndex: sliceNumber] addObject: new2DPointROI];
			// add the ROI to our list
			[roi2DPointsArray addObject:new2DPointROI];
			[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:sliceNumber]];
			[x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
			[y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
			[z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
			// notify the change
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object: new2DPointROI userInfo: 0L];
		}
	}
}

- (void) remove2DPoint: (float) x : (float) y : (float) z
{
	if (viewer2D)
	{
		long cur2DPointIndex = 0;
		BOOL found = NO;

		while(!found && cur2DPointIndex<[roi2DPointsArray count])
		{
			if(	[[x2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==x 
				&& [[y2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==y
				&& [[z2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==z)
			{
				found = YES;
			}
			else
			{
				cur2DPointIndex++;
			}
		}
		if (found && cur2DPointIndex<[roi2DPointsArray count])
		{
			// the 2D Point ROI object
			ROI * cur2DPoint;
			cur2DPoint = [roi2DPointsArray objectAtIndex:cur2DPointIndex];
			// remove 2D Point on 2D viewer2D
			[[[viewer2D roiList] objectAtIndex: [[sliceNumber2DPointsArray objectAtIndex:cur2DPointIndex] longValue]] removeObject:cur2DPoint];
			//notify
			[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:cur2DPoint userInfo: nil];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"updateView" object:0L userInfo: 0L];

			// remove 2D point in our list
			// done by remove3DPoint (through notification)
		}
	}
}

- (void) add3DPoint: (NSNotification*) note
{
	ROI	*addedROI = [note object];
	
	if ([roi2DPointsArray containsObject:addedROI])
	{
		[self remove3DPoint:note];
	}
	
	if ([addedROI type] == t2DPoint)
	{
		float location[3];
		double x, y, z;
			
		[[[viewer2D pixList] objectAtIndex:[[viewer2D imageView] curImage]] convertPixX: [[[addedROI points] objectAtIndex:0] x] pixY: [[[addedROI points] objectAtIndex:0] y] toDICOMCoords: location];
		
		x = location[0];
		y = location[1];
		z = location[2];

		// add the 3D Point to the SR view
		[[self view] add3DPoint: x : y : z];
		[[self view] setNeedsDisplay:YES];
		// add the 2D Point to our list
		[roi2DPointsArray addObject:addedROI];
		[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:[[viewer2D imageView] curImage]]];
		[x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
		[y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
		[z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
	}
}

- (void) remove3DPoint: (NSNotification*) note
{
	ROI	*removedROI = [note object];
	
	if ([removedROI type] == t2DPoint) // 2D Points
	{
		// find 3D point
		float location[3];
		double x, y, z;
		
		[[[viewer2D pixList] objectAtIndex: 0] convertPixX: [[[removedROI points] objectAtIndex:0] x] pixY: [[[removedROI points] objectAtIndex:0] y] toDICOMCoords: location];

		x = location[0];
		y = location[1];
		z = location[2];

		long cur2DPointIndex = 0;
		BOOL found = NO;

		while(!found && cur2DPointIndex<[roi2DPointsArray count])
		{
			if(	[roi2DPointsArray objectAtIndex:cur2DPointIndex]==removedROI)
			{
				found = YES;
			}
			else
			{
				cur2DPointIndex++;
			}
		}
		if (found && cur2DPointIndex<[roi2DPointsArray count])
		{
			// remove the 3D Point in the SR view
			[[self view] remove3DPointAtIndex: cur2DPointIndex];
			[[self view] setNeedsDisplay:YES];
			// remove 2D point in our list
			[roi2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[sliceNumber2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[x2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[y2DPointsArray removeObjectAtIndex:cur2DPointIndex];
			[z2DPointsArray removeObjectAtIndex:cur2DPointIndex];
		}
	}
}

- (void)createContextualMenu{
	NSMenu *contextual =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	NSMenu *submenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Mode", nil)];
	NSMenuItem *item, *subItem;
	int i = 0;
	
	//tools
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *toolsSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	[item setSubmenu:toolsSubmenu];
	
	
	NSArray *titles = [NSArray arrayWithObjects: 
					NSLocalizedString(@"Move", nil), 
					NSLocalizedString(@"Magnify", nil), 
					NSLocalizedString(@"Rotate", nil), 
					NSLocalizedString(@"Control Model", nil), 
					NSLocalizedString(@"Point", nil), 
					nil];

						
	NSArray *images = [NSArray arrayWithObjects: 
					@"Move",
					@"Zoom", 
					@"Rotate", 
					@"3DRotate",
					@"Point", 
					nil];
					  
	NSArray *tags = [NSArray arrayWithObjects: 
					[NSNumber numberWithInt:1], 
					[NSNumber numberWithInt:2], 
					[NSNumber numberWithInt:3],
					[NSNumber numberWithInt:7],
					[NSNumber numberWithInt:15],  
					nil];
	
	
	NSEnumerator *titleEnumerator = [titles objectEnumerator];
	NSEnumerator *imageEnumerator = [images objectEnumerator];
	NSEnumerator *tagEnumerator = [tags objectEnumerator];
	NSString *title;
	while (title = [titleEnumerator nextObject]) {
		subItem = [[NSMenuItem alloc] initWithTitle:title action: @selector(setDefaultTool:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setImage:[NSImage imageNamed:[imageEnumerator nextObject]]];
		[subItem setTarget:self];
		[toolsSubmenu addItem:subItem];
		[subItem release];
	}
	[toolsSubmenu release];
	[item release];
	
	//View	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *viewSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"View", nil)];
	[item setSubmenu:viewSubmenu];
	
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Axial", nil) action: @selector(axView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: AxToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Right", nil) action: @selector(saView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: SaToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Left", nil) action: @selector(saViewOpposite:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: SaOppositeToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Coronal", nil) action: @selector(coView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: CoToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
	[viewSubmenu release];
	[item release];
	
	//Export
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *exportSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Export", nil)];
	[item setSubmenu:exportSubmenu];
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime", nil)  action:@selector(exportQuicktime:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime VR", nil)  action:@selector(exportQuicktime3DVR:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DICOM", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Email", nil)  action:@selector(sendMail:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"iPhoto", nil)  action:@selector(export2iPhoto:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"JPEG", nil)  action:@selector(exportJPEG:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"TIFF", nil)  action:@selector(exportTIFF:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		
	
	[exportSubmenu release];
	[item release];
	
	
	[view setMenu:contextual];
	[contextual release];
												
}

// ROIs Volumes
#ifdef roi3Dvolume
- (void) computeROIVolumes
{
	int i;
	NSArray *roiNames = [viewer2D roiNames];
	[roiVolumes removeAllObjects];
	
	for(i=0; i<[roiNames count]; i++)
	{
		NSArray *roisWithCurrentName = [viewer2D roisWithName:[roiNames objectAtIndex:i]];
		ROIVolume *volume = [[[ROIVolume alloc] init] autorelease];
		[volume setROIList:roisWithCurrentName];
		if ([volume isVolume])
			[roiVolumes addObject:volume];
	}
}

- (NSMutableArray*) roiVolumes
{
	return roiVolumes;
}

//- (void) displayROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	viewRenderer->AddActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}

- (void) displayROIVolume: (ROIVolume*) v
{
	vtkRenderer *viewRenderer = [view renderer];
	viewRenderer->AddActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}

//- (void) hideROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	viewRenderer->RemoveActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}

- (void) hideROIVolume: (ROIVolume*) v
{
	vtkRenderer *viewRenderer = [view renderer];
	viewRenderer->RemoveActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}

- (void) displayROIVolumes
{
	int i;
	for(i=0; i<[roiVolumes count]; i++)
	{
		if([[roiVolumes objectAtIndex:i] visible])
		{
			[self displayROIVolume:[roiVolumes objectAtIndex:i]];
		}
	}
}

- (IBAction) roiGetManager:(id) sender
{
	BOOL	found = NO;
	NSArray *winList = [NSApp windows];
	long i;
	
	for(i = 0; i < [winList count]; i++)
	{
		if([[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROIVolumeManager"])
		{
			found = YES;
			NSLog(@"FOUND!!");
		}
	}
	if(!found)
	{
		ROIVolumeManagerController *manager = [[ROIVolumeManagerController alloc] initWithViewer: self];
		if(manager)
		{
			[manager showWindow:self];
			[[manager window] makeKeyAndOrderFront:self];
		}
	}
}



#endif

- (void) showWindow:(id) sender
{
	[super showWindow: sender];
	
	[view squareView: self];
}

- (ViewerController *) viewer2D{
	return viewer2D;
}

- (NSManagedObject *)currentStudy{
	return [viewer2D currentStudy];
}
- (NSManagedObject *)currentSeries{
	return [viewer2D currentSeries];
}

- (NSManagedObject *)currentImage{
	return [viewer2D currentImage];
}

//Surface values

- (float) firstSurface{
	return _firstSurface;
}
- (float) secondSurface{
	return _secondSurface;
}
- (float) resolution{
	return _resolution;
}
- (float) firstTransparency{
	return _firstTransparency;
}
- (float) secondTransparency{
	return _secondTransparency;
}

- (float) decimate{
	return _decimate;
}

- (int)smooth{
	return _smooth;
}

- (NSColor *) firstColor{
	return _firstColor;
}

- (NSColor *) secondColor{
	return _secondColor;
}

- (BOOL)shouldDecimate{
	
	return _shouldDecimate;
}
- (BOOL	)shouldSmooth{
	return _shouldSmooth;
}

- (BOOL) useFirstSurface{
	return _useFirstSurface;
}
- (BOOL) useSecondSurface{
	return _useSecondSurface;
}

- (void) setFirstSurface:(float)pixelValue{
	_firstSurface = pixelValue;
}
- (void) setSecondSurface:(float)pixelValue{
	_secondSurface = pixelValue;
}

- (void) setResolution:(float)resolution{
	_resolution = resolution;
}
- (void) setFirstTransparency:(float)transparency{
	_firstTransparency = transparency;
}
- (void) setSecondTransparency:(float)transparency{
	_secondTransparency = transparency;
}
- (void) setDecimate:(float)decimateItr{
	_decimate = decimateItr;
}
- (void) setSmooth:(int)iteration{
	_smooth = iteration;
}
- (void) setFirstColor:(NSColor *)color{
	_firstColor;
	_firstColor  = color;
}

- (void) setSecondColor: (NSColor *)color{
	_secondColor;
	_secondColor  = color;
}

- (void) setShouldDecimate: (BOOL)shouldDecimate{
	_shouldDecimate = shouldDecimate;
}
- (void) setShouldSmooth: (BOOL)shouldSmooth{
	_shouldSmooth = shouldSmooth;
}

- (void) setUseFirstSurface:(BOOL)useSurface{
	_useFirstSurface = useSurface;
}
- (void) setUseSecondSurface:(BOOL)useSurface{
	_useSecondSurface = useSurface;
}

// Fusionm Surface values

- (float) fusionFirstSurface{
	return _fusionFirstSurface;
}
- (float) fusionSecondSurface{
	return _fusionSecondSurface;
}
- (float) fusionResolution{
	return _fusionResolution;
}
- (float) fusionFirstTransparency{
	return _fusionFirstTransparency;
}
- (float) fusionSecondTransparency{
	return _fusionSecondTransparency;
}

- (float) fusionDecimate{
	return _fusionDecimate;
}

- (int)fusionSmooth{
	return _fusionSmooth;
}

- (NSColor *) fusionFirstColor{
	return _fusionFirstColor;
}

- (NSColor *) fusionSecondColor{
	return _fusionSecondColor;
}

- (BOOL) fusionShouldDecimate{
	
	return _fusionShouldDecimate;
}
- (BOOL	)fusionShouldSmooth{
	return _fusionShouldSmooth;
}

- (BOOL) fusionUseFirstSurface{
	return _fusionUseFirstSurface;
}
- (BOOL) fusionUseSecondSurface{
	return _fusionUseSecondSurface;
}

- (BOOL) shouldRenderFusion{
	return _shouldRenderFusion;
}


- (void) setFusionFirstSurface:(float)pixelValue{
	_fusionFirstSurface = pixelValue;
}
- (void) setFusionSecondSurface:(float)pixelValue{
	_fusionSecondSurface = pixelValue;
}

- (void) setFusionResolution:(float)resolution{
	_fusionResolution = resolution;
}
- (void) setFusionFirstTransparency:(float)transparency{
	_fusionFirstTransparency = transparency;
}
- (void) setFusionSecondTransparency:(float)transparency{
	_fusionSecondTransparency = transparency;
}
- (void) setFusionDecimate:(float)decimateItr{
	_fusionDecimate = decimateItr;
}
- (void) setFusionSmooth:(int)iteration{
	_fusionSmooth = iteration;
}
- (void) setFusionFirstColor:(NSColor *)color{
	_fusionFirstColor  = color;
}

- (void) setFusionSecondColor: (NSColor *)color{
	_fusionSecondColor  = color;
}

- (void) setFusionShouldDecimate: (BOOL)shouldDecimate{
	_fusionShouldDecimate = shouldDecimate;
}
- (void) setFusionShouldSmooth: (BOOL)shouldSmooth{
	_fusionShouldSmooth = shouldSmooth;
}

- (void) setFusionUseFirstSurface:(BOOL)useSurface{
	_fusionUseFirstSurface = useSurface;
}
- (void) setFusionUseSecondSurface:(BOOL)useSurface{
	_fusionUseSecondSurface = useSurface;
}

- (void) setShouldRenderFusion:(BOOL)shouldRenderFusion{
	_shouldRenderFusion = shouldRenderFusion;
}


@end
