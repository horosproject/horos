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

#import "OrthogonalMPRViewer.h"
#import "EndoscopyViewer.h"
#import "EndoscopyMPRView.h"
#import "DICOMExport.h"
#import "OSIVoxel.h"
#import "VRView.h"
#import "EndoscopyVRView.h"
#import "EndoscopyFlyThruController.h"
#import "OrthogonalMPRController.h"

static NSString* 	EndoscopyToolbarIdentifier				= @"Endoscopy Viewer Toolbar Identifier";
static NSString*	endo3DToolsToolbarItemIdentifier		= @"3DTools";
static NSString*	endoMPRToolsToolbarItemIdentifier		= @"MPRTools";
static NSString*	endo3DWLWWToolbarItemIdentifier			= @"3DWLWW";
static NSString*	endoMPRWLWWToolbarItemIdentifier		= @"MPRWLWW";
static NSString*	FlyThruToolbarItemIdentifier			= @"FlyThru.tif";
static NSString*	EngineToolbarItemIdentifier				= @"Engine";
static NSString*	CroppingToolbarItemIdentifier			= @"Cropping.icns";
static NSString*	WLWW3DToolbarItemIdentifier				= @"WLWW3D";
static NSString*	WLWW2DToolbarItemIdentifier				= @"WLWW2D";
static NSString*	ExportToolbarItemIdentifier				= @"Export.icns";
static NSString*	ShadingToolbarItemIdentifier			= @"Shading";
static NSString*	LODToolbarItemIdentifier				= @"LOD";
static NSString*	CenterlineToolbarItemIdentifier			= @"Centerline";

@implementation EndoscopyViewer

@synthesize vrController;

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC : (ViewerController*) vC
{
	self = [super initWithWindowNibName:@"Endoscopy"];
	[[self window] setShowsResizeIndicator:YES];
	
	[topSplitView setDelegate:self];
	[bottomSplitView setDelegate:self];
	
//	[[NSNotificationCenter defaultCenter]	addObserver: self
//											selector: @selector(CloseViewerNotification:)
//											name: @"CloseViewerNotification"
//											object: nil];

	// initialisations
	pixList = pix;
	[pixList retain];
	// 3D VR
	[vrController initWithPix: pix : files : vData : bC : vC];
	[vrController load3DState];
	
	[[vrController view] setProjectionMode: 2]; // endoscopy mode
	
	//[[vrController view] setEngine:1]; // Open GL engine
	
	[vrController setCurrentTool:18]; // 3D camera rotate tool
	
	[[self window] setWindowController: self]; // we don't want the VRController to become the window controller!!!
	
	// 2D MPR
	[mprController initWithPixList: pix : files : vData : vC: bC :self];
	
	[[self window] setDelegate:self];
	//[[self window] performZoom:self]; // this is done in the VRController init... do it twice and it would have zero effect...
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
           selector: @selector(changeFocalPoint:)
               name: @"changeFocalPoint"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(setCameraRepresentation:)
               name: @"VRCameraDidChange"
             object: nil];
	
	 [nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: @"CloseViewerNotification"
             object: nil];
			 
	// CLUT Menu
	cur2DCLUTMenu = NSLocalizedString(@"No CLUT", nil);
	
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
           selector: @selector(Update2DCLUTMenu:)
               name: @"Update2DCLUTMenu"
             object: nil];
	[nc postNotificationName: @"Update2DCLUTMenu" object: cur2DCLUTMenu userInfo: 0L];
	
	// WL/WW Menu	
	cur2DWLWWMenu = NSLocalizedString(@"Other", nil);
	[nc addObserver: self
           selector: @selector(Update2DWLWWMenu:)
               name: @"Update2DWLWWMenu"
             object: nil];
	[nc postNotificationName: @"Update2DWLWWMenu" object: cur2DWLWWMenu userInfo: 0L];

	
	// camera representation
	//[self setCameraRepresentation];
	
	exportAllViews = NO;
	
	return self;
}

- (void) dealloc {
	[pixList release];
	[toolbar setDelegate: 0L];
	[toolbar release];
	[super dealloc];
}
#pragma mark-
#pragma mark Endoscopy Viewer methods

- (void) setCameraRepresentation: (NSNotification*) note
{
	if([note object]==[vrController view])
	{
		[self setCameraRepresentation];
	}
}

- (void) setCameraRepresentation
{
	// get the camera
	Camera *curCamera = [((VRView*)[vrController view]) cameraWithThumbnail: NO];
	
	[self setCameraPositionRepresentation: curCamera];
	[self setCameraFocalPointRepresentation: curCamera];
	[self setCameraViewUpRepresentation: curCamera];
			
	// refresh the views
	[[mprController originalView] setNeedsDisplay: YES];
	[[mprController xReslicedView] setNeedsDisplay: YES];
	[[mprController yReslicedView] setNeedsDisplay: YES];
}

- (void) setCameraPositionRepresentation: (Camera*) aCamera
{
	float factor = [vrController factor];
	
	// coordinates conversion
	double pos[3], pos2D[3];
	pos[0] = [[aCamera position] x];
	pos[1] = [[aCamera position] y];
	pos[2] = [[aCamera position] z];
	[[vrController view] convert3Dto2Dpoint:pos :pos2D];
	pos2D[0] /= factor;
	pos2D[1] /= factor;
	pos2D[2] /= factor;
				
	// orthogonal projection of Camera vectors
	// originalView
	[(EndoscopyMPRView*)[mprController originalView] setCameraPosition:pos2D[0] :pos2D[1]];
	[mprController reslice: (long)(pos2D[0]+0.0):  (long)(pos2D[1]+0.0): [mprController originalView]];
	long sliceIndex = (long)(pos2D[2]+0.5);
	sliceIndex = (sliceIndex<0)? 0 :sliceIndex;
	sliceIndex = (sliceIndex>=[[[mprController originalView] dcmPixList] count])? [[[mprController originalView] dcmPixList] count]-1 :sliceIndex;
	[[mprController originalView] setIndex:sliceIndex];
	[[mprController originalView] setCrossPositionX: (float)(pos2D[0])+0.5];
	[[mprController originalView] setCrossPositionY: (float)(pos2D[1])+0.5];
		
	// xReslicedView
	[(EndoscopyMPRView*)[mprController xReslicedView] setCameraPosition:pos2D[0] :pos2D[2]];
	long h = pos2D[2]+0.5;
	h = ([mprController sign]>0)? [[[mprController originalView] dcmPixList] count]-h-1 : h ;
	[[mprController xReslicedView] setCrossPositionX: (float)(pos2D[0]+0.5)];
	[[mprController xReslicedView] setCrossPositionY: h+0.5];
	
	// yReslicedView
	[(EndoscopyMPRView*)[mprController yReslicedView] setCameraPosition:pos2D[1] :pos2D[2]];
	[[mprController yReslicedView] setCrossPositionX: (float)(pos2D[1]+0.5)];
	[[mprController yReslicedView] setCrossPositionY: h+0.5];

}

- (void) setCameraFocalPointRepresentation: (Camera*) aCamera
{
	float factor = [vrController factor];
	
	// coordinates conversion
	double focal[3], focal2D[3];
	focal[0] = [[aCamera focalPoint] x];
	focal[1] = [[aCamera focalPoint] y];
	focal[2] = [[aCamera focalPoint] z];
	[[vrController view] convert3Dto2Dpoint:focal :focal2D];
	focal2D[0] /= factor;
	focal2D[1] /= factor;
	focal2D[2] /= factor;
				
	// orthogonal projection of Camera vectors
	// originalView
	[(EndoscopyMPRView*)[mprController originalView] setCameraFocalPoint:focal2D[0] :focal2D[1]];
	[(EndoscopyMPRView*)[mprController originalView] setFocalPointX: (long)(focal2D[0]+0.5)];
	[(EndoscopyMPRView*)[mprController originalView] setFocalPointY: (long)(focal2D[1]+0.5)];
	
	// xReslicedView
	[(EndoscopyMPRView*)[mprController xReslicedView] setCameraFocalPoint:focal2D[0] :focal2D[2]];
	long hfocal = focal2D[2]+0.5;
	hfocal = ([mprController sign]>0)? [[[mprController originalView] dcmPixList] count]-hfocal-1 : hfocal ;
	[(EndoscopyMPRView*)[mprController xReslicedView] setFocalPointX: (long)(focal2D[0]+0.5)];
	[(EndoscopyMPRView*)[mprController xReslicedView] setFocalPointY: hfocal];
	
	// yReslicedView
	[(EndoscopyMPRView*)[mprController yReslicedView] setCameraFocalPoint:focal2D[1] :focal2D[2]];
	[(EndoscopyMPRView*)[mprController yReslicedView] setFocalPointX: (long)(focal2D[1]+0.5)];
	[(EndoscopyMPRView*)[mprController yReslicedView] setFocalPointY: hfocal];
}

- (void) setCameraViewUpRepresentation: (Camera*) aCamera
{
	float factor = [vrController factor];
	
	// coordinates conversion	
	float viewUp[3], viewUp2D[3];
	viewUp[0] = [[aCamera viewUp] x]*10.0;
	viewUp[1] = [[aCamera viewUp] y]*10.0;
	viewUp[2] = [[aCamera viewUp] z]*10.0;
	//[[vrController view] convert3Dto2Dpoint:viewUp :viewUp2D];

	// originalView
	[(EndoscopyMPRView*)[mprController originalView] setViewUpX: (long)(viewUp[0]+0.5)];
	[(EndoscopyMPRView*)[mprController originalView] setViewUpY: (long)(viewUp[1]+0.5)];
	
	// xReslicedView
	long hviewup = viewUp[2]+0.5;
	hviewup = ([mprController sign]>0)? -hviewup : hviewup ;
	[(EndoscopyMPRView*)[mprController xReslicedView] setViewUpX: (long)(viewUp[0]+0.5)];
	[(EndoscopyMPRView*)[mprController xReslicedView] setViewUpY: (long)(hviewup)];	

	// yReslicedView
	[(EndoscopyMPRView*)[mprController yReslicedView] setViewUpX: (long)(viewUp[1]+0.5)];
	[(EndoscopyMPRView*)[mprController yReslicedView] setViewUpY: (long)(hviewup)];
}

- (void) setCamera
{
	double position1[3], focalPoint1[3], focalPoint2[3];
	double x, y, z;
	
	// get the camera
	// Camera *cam = [[vrController view] camera];
	Camera *curCamera = [[vrController view] cameraWithThumbnail: NO];
	// change the Position	
	[[[[mprController originalView] pixList] objectAtIndex:[[mprController originalView] curImage]] convertPixDoubleX:[(EndoscopyMPRView*)[mprController originalView] crossPositionX]
																									pixY:[(EndoscopyMPRView*)[mprController originalView] crossPositionY]
																									toDICOMCoords:position1
																									pixelCenter: YES];
						
//	[[[[mprController xReslicedView] pixList] objectAtIndex:[[mprController xReslicedView] curImage]]	convertPixDoubleX: [(EndoscopyMPRView*)[mprController xReslicedView] crossPositionX]
//																										pixY: [(EndoscopyMPRView*)[mprController xReslicedView] crossPositionY]
//																										toDICOMCoords: position2];

	float factor = [vrController factor];
	float sliceInterval;
	if ([[[self pixList] objectAtIndex:0] sliceInterval]==0)
	{
		sliceInterval = [[pixList objectAtIndex: 1] sliceLocation]-[[pixList objectAtIndex:0] sliceLocation];
	}
	else
	{
		sliceInterval = [[pixList objectAtIndex:0] sliceInterval];
	}
	
//	position1[2] -= sliceInterval/2.;
	
	position1[0] = position1[0] * factor;
	position1[1] = position1[1] * factor;
	position1[2] = position1[2] * factor;
	
	//NSLog(@"new camera 3D position : %f, %f, %f", position1[0], position1[1], position2[1]);

	[curCamera setPosition:[[Point3D alloc] initWithValues: position1[0]
													: position1[1]
													: position1[2]]];
	// change the Focal Point
	[[[self pixList]	objectAtIndex:[[mprController originalView] curImage]]
						convertPixDoubleX: [(EndoscopyMPRView*)[mprController originalView] focalPointX]
						pixY: [(EndoscopyMPRView*)[mprController originalView] focalPointY]
						toDICOMCoords: focalPoint1
						pixelCenter: YES];
	
	

	
	float s = (sliceInterval>0)? 1.0: -1.0;
	
	//long focalPointZ = focalPoint1[2] + [mprController sign] * [[[mprController originalView] curDCM] sliceInterval] * [(EndoscopyMPRView*)[mprController xReslicedView] focalShiftY];
	float focalPointZ = focalPoint1[2] + s * sliceInterval * (-1.0) * (float)[(EndoscopyMPRView*)[mprController xReslicedView] focalShiftY];
	//NSLog(@"focalPoint1[2] : %f", focalPoint1[2]);
	//NSLog(@"s : %f", s);
	//NSLog(@"sliceInterval : %f", sliceInterval);
	//NSLog(@"[(EndoscopyMPRView*)[mprController xReslicedView] focalShiftY] : %d", [(EndoscopyMPRView*)[mprController xReslicedView] focalShiftY]);
	//NSLog(@"focalPointZ : %f", focalPointZ);
		
//	long focalPointZ = [(EndoscopyMPRView*)[mprController xReslicedView] focalPointY];
//	focalPointZ = ([mprController sign]>0)? [[[mprController originalView] dcmPixList] count]-focalPointZ-1 : focalPointZ ;
	
//	[[[[mprController xReslicedView] pixList]	objectAtIndex:[[mprController xReslicedView] curImage]]
//						convertPixX: [(EndoscopyMPRView*)[mprController xReslicedView] focalPointX]
//						pixY: focalPointZ
//						toDICOMCoords: focalPoint2];

	//NSLog(@"new camera 3D focal point : %f, %f, %f", focalPoint1[0], focalPoint1[1], focalPoint2[1]);
	
	focalPoint1[0] = focalPoint1[0] * factor;
	focalPoint1[1] = focalPoint1[1] * factor;
	focalPointZ = focalPointZ * factor;
	
	//NSLog(@"new camera 3D focal point : %f, %f, %f", focalPoint1[0], focalPoint1[1], focalPointZ);
						
	[curCamera setFocalPoint:[[Point3D alloc] initWithValues	: focalPoint1[0]
														: focalPoint1[1]
//														: focalPoint2[1]]];
														: focalPointZ]];

//	[cam setFocalPoint:[[Point3D alloc] initWithValues	: position1[0]+[(EndoscopyMPRView*)[mprController originalView] focalShiftX]
//														: position1[1]+[(EndoscopyMPRView*)[mprController originalView] focalShiftY]
//														: position1[2]+[(EndoscopyMPRView*)[mprController xReslicedView] focalShiftY]]];
														
	// change the Angle
	//[cam setViewAngle:[(EndoscopyMPRView*)[mprController originalView] cameraAngle]];
	// set the new amera
	[[vrController view] setCamera: curCamera];
	//NSLog(@"curCamera : %@", curCamera);

}

- (void) changeFocalPoint: (NSNotification*) note
{
	EndoscopyMPRView *sender = [note object];
	if([sender isEqualTo:[mprController originalView]])
	{
		[(EndoscopyMPRView*)[mprController xReslicedView] setFocalShiftX:[sender focalShiftX]];
		[(EndoscopyMPRView*)[mprController yReslicedView] setFocalShiftX:[sender focalShiftY]];
		[[mprController xReslicedView] setNeedsDisplay:YES];
		[[mprController yReslicedView] setNeedsDisplay:YES];
	}
	else if([sender isEqualTo:[mprController xReslicedView]])
	{
		[(EndoscopyMPRView*)[mprController originalView] setFocalShiftX:[sender focalShiftX]];
		[(EndoscopyMPRView*)[mprController yReslicedView] setFocalShiftY:[sender focalShiftY]];
		[[mprController originalView] setNeedsDisplay:YES];
		[[mprController yReslicedView] setNeedsDisplay:YES];
	}
	else if([sender isEqualTo:[mprController yReslicedView]])
	{
		[(EndoscopyMPRView*)[mprController originalView] setFocalShiftY:[sender focalShiftX]];
		[(EndoscopyMPRView*)[mprController xReslicedView] setFocalShiftY:[sender focalShiftY]];
		[[mprController originalView] setNeedsDisplay:YES];
		[[mprController xReslicedView] setNeedsDisplay:YES];
	}
	[self setCamera];
	
	[self setCameraViewUpRepresentation: [[vrController view] cameraWithThumbnail: NO]];
	// refresh the MPR views
	[[mprController originalView] setNeedsDisplay:YES];
	[[mprController xReslicedView] setNeedsDisplay:YES];
	[[mprController yReslicedView] setNeedsDisplay:YES];
}

- (void) setCameraPosition:(OSIVoxel *)position  focalPoint:(OSIVoxel *)focalPoint{
	Camera *curCamera = [[vrController view] cameraWithThumbnail: NO];
	float factor = [vrController factor];
		// coordinates conversion
	float pos[3], fp[3];
	 // The order of the piXList appears reversed in the views relative to the orginal viewer2D
	int pixCount = [[[mprController originalView] dcmPixList] count];
	// tranform coordinates

	[[[[mprController originalView] pixList]	objectAtIndex:round(position.z)]
												convertPixX: position.x
												pixY: position.y
												toDICOMCoords: pos
												pixelCenter: YES];
												
	[[[[mprController originalView] pixList]	objectAtIndex:round(focalPoint.z) ]
												convertPixX: focalPoint.x
												pixY: focalPoint.y
												toDICOMCoords: fp
												pixelCenter: YES];
	pos[0] *= factor;
	pos[1] *= factor;
	pos[2] *= factor;
	fp[0] *= factor;
	fp[1] *= factor;
	fp[2] *= factor;

	
	[curCamera setPosition:[[Point3D alloc] initWithValues: pos[0]
													: pos[1]
													: pos[2]]];
													
	[curCamera setFocalPoint:[[Point3D alloc] initWithValues: fp[0]
														: fp[1]
														: fp[2]]];

	[[vrController view] setCenterlineCamera: curCamera];
	[[vrController view] setNeedsDisplay:YES];
	[[mprController originalView] setNeedsDisplay:YES];
	[[mprController xReslicedView] setNeedsDisplay:YES];
	[[mprController yReslicedView] setNeedsDisplay:YES];
	
	[[self window] display];
	
	//NSLog(@"camera: %@", [[vrController view] camera]);
	
}

#pragma mark-

- (BOOL) is2DViewer
{
	return NO;
}

- (void) ApplyCLUTString:(NSString*) str
{
	[mprController ApplyCLUTString:str];
	[vrController ApplyCLUTString:str];
}

- (void) setWLWW:(float) iwl :(float) iww
{
	[mprController setWLWW:iwl :iww];
	//[vrController setWLWW:iwl :iww];
}

- (IBAction) showWindow:(id)sender
{
	[mprController showViews:sender];
	// camera representation
	[self setCameraRepresentation];
	[super showWindow:sender];
}

- (NSMutableArray*) pixList
{
	return pixList;
}

#pragma mark-
#pragma mark Tools Selection

- (IBAction) change2DTool:(id) sender
{
	if( [sender tag] >= 0)
    {
		[tools2DMatrix selectCellWithTag: [[sender selectedCell] tag]];
		[mprController setCurrentTool: [[sender selectedCell] tag]];
    }
}

- (void) setCurrentTool:(short) newTool
{
	[vrController setCurrentTool: newTool];
}

- (IBAction) change3DTool:(id) sender
{
	if( [sender tag] >= 0)
    {
		[tools3DMatrix selectCellWithTag: [[sender selectedCell] tag]];
		[vrController setCurrentTool: [[sender selectedCell] tag]];
    }
}

#pragma mark-
#pragma mark Orthogonal MPR Viewer methods

- (void) blendingPropagateOriginal:(OrthogonalMPRView*) sender
{
	[mprController blendingPropagateOriginal: sender];
}

- (void) blendingPropagateX:(OrthogonalMPRView*) sender
{
	[mprController blendingPropagateX: sender];
}

- (void) blendingPropagateY:(OrthogonalMPRView*) sender
{
	[mprController blendingPropagateY: sender];
}

- (void) saveCrossPositions
{
	[mprController saveCrossPositions];
}

- (void) toggleDisplayResliceAxes
{
	[mprController toggleDisplayResliceAxes:self];
}

#pragma mark-
#pragma mark VR Viewer methods

- (IBAction) flyThruControllerInit:(id) sender
{
	[vrController flyThruControllerInit:sender];
	[[[vrController flyThruController] exportButtonOption] setHidden:NO];
	[[[vrController flyThruController] exportButtonOption] setTarget:self];
	[[[vrController flyThruController] exportButtonOption] setAction:@selector(setExportAllViews:)];
}

- (IBAction) centerline: (id) sender
{
	// Display the Fly Thru Controller
	
	[self flyThruControllerInit: sender];
	[(EndoscopyFlyThruController*) [vrController flyThruController] calculate: sender];
}

- (void) applyWLWWForString:(NSString*) str
{
//	[mprController applyWLWWForString: str];
}

- (void) ApplyWLWW:(id) sender
{
	if([[sender menu] isEqualTo: [[vrController wlwwPopup] menu]])
	{
		[vrController ApplyWLWW:sender];
	}
	else if([[sender menu] isEqualTo: [wlww2DPopup menu]])
	{
//		[mprController ApplyWLWW:sender];
	}
}

- (void) ApplyCLUT:(id) sender
{
	if([[sender menu] isEqualTo: [[vrController clutPopup] menu]])
	{
		[vrController ApplyCLUT:sender];
	}
	else if([[sender menu] isEqualTo: [clut2DPopup menu]])
	{
		[self Apply2DCLUT:sender];
	}
}

- (void) ApplyOpacity:(id) sender
{
	if([[sender menu] isEqualTo: [[vrController OpacityPopup] menu]])
	{
		[vrController ApplyOpacity:sender];
	}
}

- (void) Apply2DCLUTString:(NSString*) str
{
	[mprController ApplyCLUTString: str];
	cur2DCLUTMenu = str;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Update2DCLUTMenu" object: cur2DCLUTMenu userInfo: 0L];		
	[[[clut2DPopup menu] itemAtIndex:0] setTitle:str];
}

-(void) Update2DCLUTMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    i = [[clut2DPopup menu] numberOfItems];
    while(i-- > 0) [[clut2DPopup menu] removeItemAtIndex:0];
	
	[[clut2DPopup menu] addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:nil keyEquivalent:@""];
    [[clut2DPopup menu] addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:@selector(ApplyCLUT:) keyEquivalent:@""];
	[[clut2DPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clut2DPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector(ApplyCLUT:) keyEquivalent:@""];
    }
	[[[clut2DPopup menu] itemAtIndex:0] setTitle:cur2DCLUTMenu];
}

- (void) Apply2DCLUT:(id) sender
{
		[self Apply2DCLUTString:[sender title]];
}

- (void) set2DWLWW:(float) iwl :(float) iww
{
	[mprController setWLWW: iwl : iww];
	[mprController setCurWLWWMenu:cur2DWLWWMenu];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Update2DWLWWMenu" object: cur2DWLWWMenu userInfo: 0L];
}

-(void) Update2DWLWWMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    i = [[wlww2DPopup menu] numberOfItems];
    while(i-- > 0) [[wlww2DPopup menu] removeItemAtIndex:0];
    [[wlww2DPopup menu] addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:nil keyEquivalent:@""];
	[[wlww2DPopup menu] addItemWithTitle: NSLocalizedString(@"Other", nil) action:@selector (Apply2DWLWW:) keyEquivalent:@""];
	[[wlww2DPopup menu] addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:@selector (Apply2DWLWW:) keyEquivalent:@""];
	[[wlww2DPopup menu] addItemWithTitle: NSLocalizedString(@"Full dynamic", nil) action:@selector (Apply2DWLWW:) keyEquivalent:@""];
	[[wlww2DPopup menu] addItem: [NSMenuItem separatorItem]];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[wlww2DPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (Apply2DWLWW:) keyEquivalent:@""];
    }
	[[[wlww2DPopup menu] itemAtIndex:0] setTitle:[[mprController originalView] curWLWWMenu]];
}

- (void) Apply2DWLWW:(id) sender
{
	cur2DWLWWMenu = [sender title];

	if( [[sender title] isEqualToString:NSLocalizedString(@"Other", nil)] == YES)
	{
		//[imageView setWLWW:0 :0];
	}
	else if( [[sender title] isEqualToString:NSLocalizedString(@"Default WL & WW", nil)] == YES)
	{
		[self set2DWLWW:[[[mprController originalView] curDCM] savedWL] :[[[mprController originalView] curDCM] savedWW]];
	}
	else if( [[sender title] isEqualToString:NSLocalizedString(@"Full dynamic", nil)] == YES)
	{
		[self set2DWLWW:0 :0];
	}
	else
	{
		NSArray		*value;
		value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey:[sender title]];
		[self set2DWLWW:[[value objectAtIndex: 0] floatValue] :[[value objectAtIndex: 1] floatValue]];
	}
	
	[[[wlww2DPopup menu] itemAtIndex:0] setTitle:[sender title]];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Update2DWLWWMenu" object: cur2DWLWWMenu userInfo: 0L];
	cur2DWLWWMenu = NSLocalizedString(@"Other", 0L);
}

- (void) setCur2DWLWWMenu: (NSString*) wlww
{
	cur2DWLWWMenu = wlww;
}

- (long) movieFrames
{
	[vrController movieFrames];
}

#pragma mark-
#pragma mark NSWindow related methods

- (void) windowDidLoad
{
    [self setupToolbar];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	long				i;
	ViewerController	*v = [note object];
	
//	for( i = 0; i < maxMovieIndex; i++)
	{
		if( [v pixList] == pixList)
		{
			[[self window] close];
			return;
		}
	}
}


- (void) windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Window3DClose" object: self userInfo: 0];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Window3DClose" object: vrController userInfo: 0];	//<- to close the FlyThru controller !
	
    [[self window] setDelegate:0L];
	
	[topSplitView setDelegate:0L];	
	[bottomSplitView setDelegate:0L];
	
	[self release];
}

#pragma mark-
#pragma mark NSSplitview's delegate methods

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return NO;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	NSSplitView	*currentSplitView = [aNotification object];
	NSArray	*subviews = [currentSplitView subviews];
	
	if( [subviews count] > 1)
	{
		NSRect	rect1, rect2, old_rect1, old_rect2;
		
		rect1 = [[subviews objectAtIndex:0] frame];
		rect2 = [[subviews objectAtIndex:1] frame];
		
		if([currentSplitView isEqual:bottomSplitView])
		{
			subviews = [topSplitView subviews];
			old_rect1 = [[subviews objectAtIndex:0] frame];
			old_rect2 = [[subviews objectAtIndex:1] frame];
			
			old_rect1.origin.x = rect1.origin.x;
			old_rect1.size.width = rect1.size.width;
			old_rect2.origin.x = rect2.origin.x;
			old_rect2.size.width = rect2.size.width;
		
			[[subviews objectAtIndex:0] setFrame:old_rect1];
			[[subviews objectAtIndex:1] setFrame:old_rect2];
			
			[topSplitView setNeedsDisplay:YES];
		}
		else if ([currentSplitView isEqual:topSplitView])
		{
			subviews = [bottomSplitView subviews];
			old_rect1 = [[subviews objectAtIndex:0] frame];
			old_rect2 = [[subviews objectAtIndex:1] frame];
			old_rect1.origin.x = rect1.origin.x;
			old_rect1.size.width = rect1.size.width;
			old_rect2.origin.x = rect2.origin.x;
			old_rect2.size.width = rect2.size.width;
		
			[[subviews objectAtIndex:0] setFrame:old_rect1];
			[[subviews objectAtIndex:1] setFrame:old_rect2];
			
			[bottomSplitView setNeedsDisplay:YES];
		}
	}
}

#pragma mark-
#pragma mark NSToolbar Related Methods

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: EndoscopyToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
   
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
}

- (IBAction) customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
 
	if([itemIdent isEqual: endo3DToolsToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"3D Mouse button function",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Mouse button function",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"Change the mouse function for the 3D view",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: tools3DView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([tools3DView frame]), NSHeight([tools3DView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([tools3DView frame]),NSHeight([tools3DView frame]))];
    }
	else if([itemIdent isEqual: endoMPRToolsToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"MPR Mouse button function",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"MPR Mouse button function",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"Change the mouse function for the MPR views",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: tools2DView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([tools2DView frame]), NSHeight([tools2DView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([tools2DView frame]),NSHeight([tools2DView frame]))];
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
	else if ([itemIdent isEqualToString: EngineToolbarItemIdentifier])
	{
		 // Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Engine",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Engine",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Engine",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: engineView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
    }
	else if ([itemIdent isEqualToString: CroppingToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Crop",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Cropping Cube",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Show and manipulate cropping cube",nil)];
		[toolbarItem setImage: [NSImage imageNamed: CroppingToolbarItemIdentifier]];
		[toolbarItem setTarget: [vrController view]];
		[toolbarItem setAction: @selector(showCropCube:)];
    }
	else if([itemIdent isEqualToString: WLWW3DToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"3D WL/WW & CLUT & Opacity",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"3D WL/WW & CLUT & Opacity",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Change the WL/WW & CLUT & Opacity in the 3D view",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: WLWW3DView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWW3DView frame]), NSHeight([WLWW3DView frame]))];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWW3DView frame]), NSHeight([WLWW3DView frame]))];
		
        [[[vrController wlwwPopup] cell] setUsesItemFromMenu:YES];
    }
	else if([itemIdent isEqualToString: WLWW2DToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"MPR WL/WW & CLUT & Opacity",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"MPR WL/WW & CLUT & Opacity",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Change the WL/WW & CLUT & Opacity in the MPR views",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: WLWW2DView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWW2DView frame]), NSHeight([WLWW2DView frame]))];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWW2DView frame]), NSHeight([WLWW2DView frame]))];
		
        [[[vrController wlwwPopup] cell] setUsesItemFromMenu:YES];
    }
	else if ([itemIdent isEqual: ExportToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"DICOM File",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Save as DICOM",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export this image in a DICOM file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		// target is not set, it will be the first responder
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
	else if ([itemIdent isEqualToString: ShadingToolbarItemIdentifier])
	{
		 // Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Shading",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Shading",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Shading Properties",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: shadingView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([shadingView frame]), NSHeight([shadingView frame]))];
    }
	else if([itemIdent isEqualToString: CenterlineToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Centerline",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Centerline",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"Compute Centerline",nil)];
		
		[toolbarItem setImage: [NSImage imageNamed: CenterlineToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( centerline:)];	
    }
	else if([itemIdent isEqualToString: LODToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"Level of Detail",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Level of Detail",nil)];
		[toolbarItem setToolTip:NSLocalizedString( @"Change Level of Detail",nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: LODView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([LODView frame]), NSHeight([LODView frame]))];
			
		//[[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
    else
	{
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
    return [NSArray arrayWithObjects:       endoMPRToolsToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											FlyThruToolbarItemIdentifier,
											ShadingToolbarItemIdentifier,
											endo3DToolsToolbarItemIdentifier,
											nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects:       NSToolbarCustomizeToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											ExportToolbarItemIdentifier,
											endo3DToolsToolbarItemIdentifier,
											endoMPRToolsToolbarItemIdentifier,
											FlyThruToolbarItemIdentifier,
											CenterlineToolbarItemIdentifier,
											EngineToolbarItemIdentifier,
											//CroppingToolbarItemIdentifier,
											WLWW3DToolbarItemIdentifier,
											WLWW2DToolbarItemIdentifier,
											ShadingToolbarItemIdentifier,
											LODToolbarItemIdentifier,
											nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
//    NSToolbarItem *item = [[notif userInfo] objectForKey: @"item"];
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
    return enable;
}


#pragma mark-
#pragma mark export

- (IBAction) setExportAllViews: (id) sender
{
	if([[sender class] isEqual:[NSButton class]])
		exportAllViews = ([sender state] == NSOnState); // for the fly thru: it's a check box
	else
		exportAllViews = ([sender selectedTag] == 0); // for the DICOM export sheet: it's a matrix with 2 radio buttons
}

- (BOOL) exportAllViews
{
	return exportAllViews;
}

- (void) exportDICOMFile:(id) sender
{
	[[self window] makeFirstResponder: (NSView*) [vrController view]];
	[NSApp beginSheet: exportDCMWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

-(IBAction) endDCMExportSettings:(id) sender
{
	[exportDCMWindow orderOut:sender];
	[NSApp endSheet:exportDCMWindow returnCode:[sender tag]];
	
	if ([exportDCMViewsChoice selectedTag] == 0)
	{
		// export the 4 views
		long	width, height, spp, bpp, err;
		unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp];
				
		// let's write the file on the disk
		DICOMExport *exportDCM = [[DICOMExport alloc] init];
		float	o[9];

		if(dataPtr)
		{
			[exportDCM setSourceFile: [[[mprController originalView] curDCM] sourceFile]];
			[exportDCM setSeriesDescription: [exportDCMSeriesName stringValue]];
			[exportDCM setSeriesNumber:5500];
			[exportDCM setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
			[[vrController view] getOrientation: o];
			[exportDCM setOrientation: o];
			
			NSString *f = [exportDCM writeDCMFile: 0L];
			if( f == 0L) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", 0L),  NSLocalizedString( @"Error during the creation of the DICOM File!", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
			free(dataPtr);
		}
	}
	else
	{
		// export only current view
		NSResponder *currentFocusedView = [[self window] firstResponder];
		if ([currentFocusedView isEqualTo:[vrController view]])
		{
			// 3D view
			[(VRView*)currentFocusedView exportDCMCurrentImage];
		}
		else
		{
			// MPR view
			[(OrthogonalMPRViewer*) currentFocusedView exportDICOMFile:self];
		}
	}
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp
{
	// grab the content of the 4 views
	unsigned char *axialDataPtr, *coronalDataPtr, *sagittalDataPtr, *view3DDataPtr;
	long	widthAx, heightAx, sppAx, bppAx;
	long	widthCor, heightCor, sppCor, bppCor;
	long	widthSag, heightSag, sppSag, bppSag;
	long	width3D, height3D, spp3D, bpp3D;
	
	long	annotations	= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
	
	[[self window] makeFirstResponder: (NSView*) [vrController view]];
	[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
	[DCMView setDefaults];
	
	[[mprController originalView] display];
	[[mprController xReslicedView] display];
	[[mprController yReslicedView] display];

	axialDataPtr = [(EndoscopyMPRView*)[mprController originalView] superGetRawPixels:&widthAx :&heightAx :&sppAx :&bppAx :YES :YES :NO];
	coronalDataPtr = [(EndoscopyMPRView*)[mprController xReslicedView] superGetRawPixels:&widthCor :&heightCor :&sppCor :&bppCor :YES :YES :NO];
	sagittalDataPtr = [(EndoscopyMPRView*)[mprController yReslicedView] superGetRawPixels:&widthSag :&heightSag :&sppSag :&bppSag :YES :YES :NO];
	
	[[NSUserDefaults standardUserDefaults] setInteger: annotations forKey: @"ANNOTATIONS"];
	
	[[mprController originalView] setNeedsDisplay: YES];
	[[mprController xReslicedView] setNeedsDisplay: YES];
	[[mprController yReslicedView] setNeedsDisplay: YES];

	view3DDataPtr = [(EndoscopyVRView*) [vrController view] superGetRawPixels:&width3D :&height3D :&spp3D :&bpp3D :YES :YES];
	
	// append the 4 views into one memory block
	//long	width, height, spp, bpp;
	
	if( widthSag+width3D > widthAx+widthCor) *width = widthSag+width3D;
	else *width = widthAx+widthCor;
	
	*height = heightAx+heightSag;
	*spp = 3;
	*bpp = 8;
	unsigned char *dataPtr = malloc(*width**height*3*sizeof(char));

	if(dataPtr)
	{
		int i;
		// copy the axial and coronal views row by row
		for(i=0; i<heightAx; i++)
		{
			memcpy(dataPtr+i*(*width)*3,axialDataPtr+i*widthAx*3,widthAx*3);
			memcpy(dataPtr+widthAx*3+i*(*width)*3,coronalDataPtr+i*widthCor*3,widthCor*3);
		}
		free(axialDataPtr);
		free(coronalDataPtr);
		// copy the sagittal and 3D views row by row
		for(i=0; i<heightSag; i++)
		{
			memcpy(dataPtr+(heightAx*widthAx+heightCor*widthCor)*3+i*(*width)*3,sagittalDataPtr+i*widthSag*3,widthSag*3);
			memcpy(dataPtr+(heightAx*widthAx+heightCor*widthCor)*3+widthSag*3+i*(*width)*3,view3DDataPtr+i*width3D*3,width3D*3);
		}
		free(sagittalDataPtr);
		free(view3DDataPtr);
	}
	return dataPtr;
}

- (NSManagedObject *)currentStudy{
	return [vrController currentStudy];
}
- (NSManagedObject *)currentSeries{
	return [vrController currentSeries];
}

- (NSManagedObject *)currentImage{
	return [vrController currentImage];
}

-(float)curWW{
	return [vrController curWW];
}

-(float)curWL{
	return [vrController curWL];
}

- (NSString *)curCLUTMenu{
	return [vrController curCLUTMenu];
}



@end
