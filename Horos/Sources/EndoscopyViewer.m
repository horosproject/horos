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

#import "OrthogonalMPRViewer.h"
#import "EndoscopyViewer.h"
#import "EndoscopyMPRView.h"
#import "DICOMExport.h"
#import "OSIVoxel.h"
#import "VRView.h"
#import "EndoscopyVRView.h"
#import "EndoscopyFlyThruController.h"
#import "OrthogonalMPRController.h"
#import "BrowserController.h"
#import "Notifications.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DicomDatabase.h"
#import "PluginManager.h"

#define	NAVIGATORMODE_BASIC 1
#define NAVIGATORMODE_2POINT 2

static NSString* 	EndoscopyToolbarIdentifier				= @"Endoscopy Viewer Toolbar Identifier";
static NSString*	endo3DToolsToolbarItemIdentifier		= @"3DTools";
static NSString*	endoMPRToolsToolbarItemIdentifier		= @"MPRTools";
static NSString*	FlyThruToolbarItemIdentifier			= @"FlyThru.pdf";
static NSString*	EngineToolbarItemIdentifier				= @"Engine";
static NSString*	CroppingToolbarItemIdentifier			= @"Cropping.pdf";
static NSString*	WLWW3DToolbarItemIdentifier				= @"WLWW3D";
static NSString*	WLWW2DToolbarItemIdentifier				= @"WLWW2D";
static NSString*	ExportToolbarItemIdentifier				= @"Export.icns";
static NSString*	ShadingToolbarItemIdentifier			= @"Shading";
static NSString*	LODToolbarItemIdentifier				= @"LOD";
//assistant
static NSString*	PathAssistantToolbarItemIdentifier		= @"PathAssistant";
//static NSString*	CenterlineToolbarItemIdentifier			= @"Centerline";

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
    //											name: OsirixCloseViewerNotification
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
               name: OsirixChangeFocalPointNotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(setCameraRepresentation:)
               name: OsirixVRCameraDidChangeNotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];
    //assistant
    [nc addObserver: self selector: @selector(flyThruAssistantGoForward:) name:@"PathAssistantGoForwardNotification" object:nil];
    [nc addObserver: self selector: @selector(flyThruAssistantGoBackward:) name:@"PathAssistantGoBackwardNotification" object:nil];
    [nc addObserver:self selector:@selector(windowWillCloseNotificationSelector:) name:NSWindowWillCloseNotification object:nil];
    
    // CLUT Menu
    cur2DCLUTMenu = NSLocalizedString(@"No CLUT", nil);
    
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(Update2DCLUTMenu:)
               name: OsirixUpdate2dCLUTMenuNotification
             object: nil];
    [nc postNotificationName: OsirixUpdate2dCLUTMenuNotification object: cur2DCLUTMenu userInfo: nil];
    
    // WL/WW Menu
    cur2DWLWWMenu = NSLocalizedString(@"Other", nil);
    [nc addObserver: self
           selector: @selector(Update2DWLWWMenu:)
               name: OsirixUpdate2dWLWWMenuNotification
             object: nil];
    [nc postNotificationName: OsirixUpdate2dWLWWMenuNotification object: cur2DWLWWMenu userInfo: nil];
    
    
    // camera representation
    //[self setCameraRepresentation];
    
    exportAllViews = NO;
    
    //assistant
    [self initFlyAssistant:vData];
    
    [self setupToolbar];
    
    return self;
}

- (void) dealloc {
    //assistant delloc
    [centerline release];
    [(EndoscopyMPRView*)[mprController originalView] setFlyThroughPath:nil];
    [(EndoscopyMPRView*)[mprController xReslicedView] setFlyThroughPath:nil];
    [(EndoscopyMPRView*)[mprController yReslicedView] setFlyThroughPath:nil];
    [centerlineAxial release];
    [centerlineCoronal release];
    [centerlineSagittal release];
    [pointA release];
    [pointB release];
    [assistant release];
    
    [pixList release];
    [toolbar setDelegate: nil];
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
    sliceIndex = (sliceIndex>=[[[mprController originalView] dcmPixList] count])? (long)[[[mprController originalView] dcmPixList] count]-1 :sliceIndex;
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
    
    // coordinates conversion
    float viewUp[3];
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
    double position1[3], focalPoint1[3];
    DCMPix *pix = [[[mprController originalView] pixList] objectAtIndex:[[mprController originalView] curImage]];
    
    // get the camera
    Camera *curCamera = [[vrController view] cameraWithThumbnail: NO];
    
    // change the Position
    [pix convertPixDoubleX:[(EndoscopyMPRView*)[mprController originalView] crossPositionX]
                      pixY:[(EndoscopyMPRView*)[mprController originalView] crossPositionY]
             toDICOMCoords:position1
               pixelCenter: YES];
    
    float factor = [vrController factor];
    
    position1[0] = position1[0] * factor;
    position1[1] = position1[1] * factor;
    position1[2] = position1[2] * factor;
    
    [curCamera setPosition:[[[Point3D alloc] initWithValues: position1[0]
                                                           : position1[1]
                                                           : position1[2]] autorelease]];
    // change the Focal Point
    [[[self pixList]	objectAtIndex:[[mprController originalView] curImage]]
     convertPixDoubleX: [(EndoscopyMPRView*)[mprController originalView] focalPointX]
     pixY: [(EndoscopyMPRView*)[mprController originalView] focalPointY]
     toDICOMCoords: focalPoint1
     pixelCenter: YES];
    
    DCMPix *pix1 = [[[mprController originalView] pixList] objectAtIndex: 0];
    DCMPix *pix2 = [[[mprController originalView] pixList] objectAtIndex: 1];
    
    double interval3d;
    
    double xd = [pix2 originX] - [pix1 originX];
    double yd = [pix2 originY] - [pix1 originY];
    double zd = [pix2 originZ] - [pix1 originZ];
    
    interval3d = sqrt(xd*xd + yd*yd + zd*zd);
    
    xd /= interval3d;
    yd /= interval3d;
    zd /= interval3d;
    
    double orientation[9];
    
    [pix orientationDouble: orientation];
    
    //	long orientationVector = [mprController orientationVector];
    
    float xSign = 1.0;
    //	float ySign = 1.0;
    
    //	switch( orientationVector)	// See applyOrientation in OrthogonalMPRController.mm
    //	{
    //		case eSagittalPos:
    //		case eSagittalNeg:
    //			xSign = -1.0;
    //			ySign = -1.0;
    //		break;
    //
    //		case eCoronalPos:
    //		case eCoronalNeg:
    //			xSign = -1.0;
    //			ySign = 1.0;
    //		break;
    //
    //		case eAxialPos:
    //			xSign = 1.0;
    //			ySign = 1.0;
    //		break;
    //
    //		case eAxialNeg:
    //			xSign = -1.0;
    //			ySign = -1.0;
    //		break;
    //	}
    
    float zShift = xSign * [pix sliceInterval] * -1.0 * (float)[(EndoscopyMPRView*)[mprController xReslicedView] focalShiftY];
    
    focalPoint1[ 0] += zShift * orientation[ 6];
    focalPoint1[ 1] += zShift * orientation[ 7];
    focalPoint1[ 2] += zShift * orientation[ 8];
    
    focalPoint1[ 0] = focalPoint1[ 0] * factor;
    focalPoint1[ 1] = focalPoint1[ 1] * factor;
    focalPoint1[ 2] = focalPoint1[ 2] * factor;
    
    [curCamera setFocalPoint:[[[Point3D alloc] initWithValues: focalPoint1[0] :focalPoint1[1] :focalPoint1[2]] autorelease]];
    
    // set the new camera
    [[vrController view] setCamera: curCamera];
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

- (float*) syncOriginPosition
{
    return nil;
}

- (void) setCameraPosition:(OSIVoxel *)position  focalPoint:(OSIVoxel *)focalPoint
{
    Camera *curCamera = [[vrController view] cameraWithThumbnail: NO];
    float factor = [vrController factor];
    // coordinates conversion
    float pos[3], fp[3];
    // The order of the piXList appears reversed in the views relative to the orginal viewer2D
    
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
    
    
    [curCamera setPosition:[[[Point3D alloc] initWithValues: pos[0]
                                                           : pos[1]
                                                           : pos[2]] autorelease]];
    
    [curCamera setFocalPoint:[[[Point3D alloc] initWithValues: fp[0]
                                                             : fp[1]
                                                             : fp[2]] autorelease]];
    
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
    
    [self.window makeFirstResponder: [mprController originalView]];
}

- (NSMutableArray*) pixList
{
    return pixList;
}

#pragma mark-
#pragma mark Tools Selection

- (void)bringToFrontROI:(ROI*)roi;{}

- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;{}

- (IBAction) change2DTool:(id) sender
{
    if( [sender tag] >= 0)
    {
        [tools2DMatrix selectCellWithTag: [[sender selectedCell] tag]];
        [mprController setCurrentTool: [[sender selectedCell] tag]];
    }
}

- (void) setCurrentTool:(ToolMode) newTool
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

- (int) engine
{
    return vrController.view.engine;
}

- (void) setEngine: (int) newEngine
{
    vrController.view.engine = newEngine;
}

- (float) lodDisplayed
{
    return vrController.view.lodDisplayed;
}

- (void) setLodDisplayed: (float) newValue
{
    vrController.view.lodDisplayed = newValue;
}

- (IBAction) flyThruControllerInit:(id) sender
{
    [vrController flyThruControllerInit:sender];
    [[[vrController flyThruController] exportButtonOption] setHidden:NO];
    [[[vrController flyThruController] exportButtonOption] setTarget:self];
    [[[vrController flyThruController] exportButtonOption] setAction:@selector(setExportAllViews:)];
}

//- (IBAction) centerline: (id) sender
//{
//	// Display the Fly Thru Controller
//
//	[self flyThruControllerInit: sender];
//	[(EndoscopyFlyThruController*) [vrController flyThruController] calculate: sender];
//}

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
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdate2dCLUTMenuNotification object: cur2DCLUTMenu userInfo: nil];
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
    
    [[clut2DPopup menu] removeAllItems];
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdate2dWLWWMenuNotification object: cur2DWLWWMenu userInfo: nil];
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
    
    [[wlww2DPopup menu] removeAllItems];
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
    
    if( [[sender title] isEqualToString:NSLocalizedString(@"Other", nil)])
    {
        //[imageView setWLWW:0 :0];
    }
    else if( [[sender title] isEqualToString:NSLocalizedString(@"Default WL & WW", nil)])
    {
        [self set2DWLWW:[[[mprController originalView] curDCM] savedWL] :[[[mprController originalView] curDCM] savedWW]];
    }
    else if( [[sender title] isEqualToString:NSLocalizedString(@"Full dynamic", nil)])
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
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdate2dWLWWMenuNotification object: cur2DWLWWMenu userInfo: nil];
    cur2DWLWWMenu = NSLocalizedString(@"Other", nil);
}

- (void) setCur2DWLWWMenu: (NSString*) wlww
{
    cur2DWLWWMenu = wlww;
}

- (long) movieFrames
{
    return [vrController movieFrames];
}

#pragma mark-
#pragma mark NSWindow related methods

- (void) CloseViewerNotification: (NSNotification*) note
{
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
    [[self window] setAcceptsMouseMovedEvents: NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixWindow3dCloseNotification object: self userInfo: 0];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixWindow3dCloseNotification object: vrController userInfo: 0];	//<- to close the FlyThru controller !
    
    [[self window] setDelegate:nil];
    
    [topSplitView setDelegate:nil];
    [bottomSplitView setDelegate:nil];
    
    [self autorelease];
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
    
#ifdef EXPORTTOOLBARITEM
    NSLog(@"************** WARNING EXPORTTOOLBARITEM ACTIVATED");
    for( id s in [self toolbarAllowedItemIdentifiers: toolbar])
    {
        @try
        {
            id item = [self toolbar: toolbar itemForItemIdentifier: s willBeInsertedIntoToolbar: YES];
            
            
            NSImage *im = [item image];
            
            if( im == nil)
            {
                @try
                {
                    if( [item respondsToSelector:@selector(setRecursiveEnabled:)])
                        [item setRecursiveEnabled: YES];
                    else if( [[item view] respondsToSelector:@selector(setRecursiveEnabled:)])
                        [[item view] setRecursiveEnabled: YES];
                    else if( item)
                        NSLog( @"%@", item);
                    
                    im = [[item view] screenshotByCreatingPDF];
                }
                @catch (NSException * e)
                {
                    NSLog( @"a");
                }
            }
            
            if( im)
            {
                NSBitmapImageRep *bits = [[[NSBitmapImageRep alloc] initWithData:[im TIFFRepresentation]] autorelease];
                
                NSString *path = [NSString stringWithFormat: @"/tmp/sc/%@.png", [[[[item label] stringByReplacingOccurrencesOfString: @"&" withString:@"And"] stringByReplacingOccurrencesOfString: @" " withString:@""] stringByReplacingOccurrencesOfString: @"/" withString:@"-"]];
                [[bits representationUsingType: NSPNGFileType properties: nil] writeToFile:path  atomically: NO];
            }
        }
        @catch (NSException * e)
        {
            NSLog( @"b");
        }
    }
#endif
}

- (IBAction) customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if([itemIdent isEqualToString: endo3DToolsToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"3D Mouse button function",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"3D Mouse button function",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: tools3DView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([tools3DView frame]), NSHeight([tools3DView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([tools3DView frame]),NSHeight([tools3DView frame]))];
    }
    else if([itemIdent isEqualToString: endoMPRToolsToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"MPR Mouse button function",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"MPR Mouse button function",nil)];
        
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
    else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"DICOM File",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"Save as DICOM",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image in a DICOM file",nil)];
        [toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
        // target is not set, it will be the first responder
        [toolbarItem setTarget: vrController.view];
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
    //	else if([itemIdent isEqualToString: CenterlineToolbarItemIdentifier])
    //	{
    //		// Set up the standard properties
    //		[toolbarItem setLabel: NSLocalizedString(@"Centerline",nil)];
    //		[toolbarItem setPaletteLabel:NSLocalizedString( @"Centerline",nil)];
    //		[toolbarItem setToolTip:NSLocalizedString( @"Compute Centerline",nil)];
    //
    //		[toolbarItem setImage: [NSImage imageNamed: CenterlineToolbarItemIdentifier]];
    //		[toolbarItem setTarget: self];
    //		[toolbarItem setAction: @selector(centerline:)];
    //    }
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
    else if ([itemIdent isEqualToString:PathAssistantToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel:NSLocalizedString(@"Path Assistant", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Path Assistant", nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Path Assistant", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setImage:[NSImage imageNamed:PathAssistantToolbarItemIdentifier]];
        // target is not set, it will be the first responder
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(showPathAssistantPanel:)];
    }
    
    else
    {
        toolbarItem = nil;
    }
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarItemForItemIdentifier:forViewer:)])
        {
            NSToolbarItem *item = [[[PluginManager plugins] objectForKey:key] toolbarItemForItemIdentifier: itemIdent forViewer: self];
            
            if( item)
                toolbarItem = item;
        }
    }
    
    return toolbarItem;
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
            PathAssistantToolbarItemIdentifier,
            nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed
    // The set of allowed items is used to construct the customization palette
    NSMutableArray *array = [NSMutableArray arrayWithObjects:       NSToolbarCustomizeToolbarItemIdentifier,
                             NSToolbarFlexibleSpaceItemIdentifier,
                             NSToolbarSpaceItemIdentifier,
                             NSToolbarSeparatorItemIdentifier,
                             ExportToolbarItemIdentifier,
                             endo3DToolsToolbarItemIdentifier,
                             endoMPRToolsToolbarItemIdentifier,
                             FlyThruToolbarItemIdentifier,
                             //CenterlineToolbarItemIdentifier,
                             EngineToolbarItemIdentifier,
                             //CroppingToolbarItemIdentifier,
                             WLWW3DToolbarItemIdentifier,
                             WLWW2DToolbarItemIdentifier,
                             ShadingToolbarItemIdentifier,
                             LODToolbarItemIdentifier,
                             PathAssistantToolbarItemIdentifier,
                             nil];
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarAllowedIdentifiersForViewer:)])
            [array addObjectsFromArray: [[[PluginManager plugins] objectForKey:key] toolbarAllowedIdentifiersForViewer: self]];
    }
    
    return array;
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
#ifdef EXPORTTOOLBARITEM
    return YES;
#endif
    
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

-(IBAction) endDCMExportSettings:(id) sender
{
    [exportDCMWindow makeFirstResponder: nil];	// To force nstextfield validation.
    [exportDCMWindow orderOut: self];
    [NSApp endSheet:exportDCMWindow returnCode:[sender tag]];
    
    NSMutableArray *producedFiles = [NSMutableArray array];
    
    DICOMExport *exportDCM = [[[DICOMExport alloc] init] autorelease];
    
    if ([exportDCMViewsChoice selectedTag] == 0)
    {
        // export the 4 views
        long	width, height, spp, bpp;
        unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp];
        
        // let's write the file on the disk
        
        if(dataPtr)
        {
            [exportDCM setSourceFile: [[[mprController originalView] curDCM] srcFile]];
            [exportDCM setSeriesDescription: [exportDCMSeriesName stringValue]];
            [exportDCM setSeriesNumber:5500];
            [exportDCM setPixelData: dataPtr samplesPerPixel:spp bitsPerSample:bpp width: width height: height];
            
            NSString *f = [exportDCM writeDCMFile: nil];
            if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
            if( f)
                [producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil]];
            
            free(dataPtr);
        }
    }
    else
    {
        // 3D view
        VRView *view = [vrController view];
        
        view.dcmSeriesString = [exportDCMSeriesName stringValue];
        
        [producedFiles addObject: [view exportDCMCurrentImageIn16bit: NO]];
    }
    
    if( [producedFiles count])
    {
        NSArray *objects = [BrowserController.currentBrowser.database addFilesAtPaths: [producedFiles valueForKey: @"file"]
                                                                    postNotifications: YES
                                                                            dicomOnly: YES
                                                                  rereadExistingItems: YES
                                                                    generatedByOsiriX: YES];
        
        objects = [BrowserController.currentBrowser.database objectsWithIDs: objects];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"])
            [[BrowserController currentBrowser] selectServer: objects];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"])
        {
            for( NSManagedObject *im in objects)
                [im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
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
    [DCMView setDefaults];
    
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
    unsigned char *dataPtr = (unsigned char*) malloc(*width**height*3*sizeof(char));
    
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

- (DicomStudy *)currentStudy
{
    return [vrController currentStudy];
}
- (DicomSeries *)currentSeries
{
    return [vrController currentSeries];
}

- (DicomImage *)currentImage
{
    return [vrController currentImage];
}

-(float)curWW
{
    return [vrController curWW];
}

-(float)curWL
{
    return [vrController curWL];
}

- (NSString *)curCLUTMenu
{
    return [vrController curCLUTMenu];
}

#pragma mark-
#pragma mark Path Assistant

- (IBAction)showPathAssistantPanel:(id)sender;
{
    [pathAssistantPanel makeKeyAndOrderFront: self];
}

- (IBAction)pathAssistantSetPointA:(id)sender;
{
    isLookingBackwards=NO;
    [pathAssistantLookBackButton setState:NSOffState];
    [pathAssistantSetPointBButton setEnabled:YES];
    [pathAssistantExportToFlyThruButton setEnabled:NO];
    
    if(!pointA)
        pointA = [[Point3D alloc] init];
    pointA.x = [(EndoscopyMPRView*)[mprController originalView] crossPositionX];
    pointA.y = [(EndoscopyMPRView*)[mprController originalView] crossPositionY];
    pointA.z = [[mprController originalView] curImage];
}

- (IBAction)pathAssistantSetPointB:(id)sender;
{
    isLookingBackwards=NO;
    [pathAssistantLookBackButton setState:NSOffState];
    [pathAssistantExportToFlyThruButton setEnabled:YES];
    
    if(!pointB)
        pointB = [[Point3D alloc] init];
    pointB.x = [(EndoscopyMPRView*)[mprController originalView] crossPositionX];
    pointB.y = [(EndoscopyMPRView*)[mprController originalView] crossPositionY];
    pointB.z = [[mprController originalView] curImage];
    
    [centerline removeAllObjects];
    
    WaitRendering* waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Finding Path...", nil)];
    [waiting showWindow:self];
    int err=[assistant createCenterline:centerline FromPointA:pointA ToPointB:pointB withSmoothing:YES];
    [waiting close];
    [waiting autorelease];
    
    if(!err)
    {
        [self updateCenterlineInMPRViews];
        flyAssistantPositionIndex=0;
        OSIVoxel* cpos = [centerline objectAtIndex:0];
        OSIVoxel * fpos = [centerline objectAtIndex:4];
        [self setCameraPosition:cpos focalPoint:fpos];
    }
    else if(err == ERROR_NOENOUGHMEM)
    {
        NSRunAlertPanel(NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"Path Assistant can not allocate enough memory, try to increase the resample voxel size in the settings.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    else if(err == ERROR_CANNOTFINDPATH)
    {
        NSRunAlertPanel(NSLocalizedString(@"Can't find path", nil), NSLocalizedString(@"Path Assistant can not find a path from A to B.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    else if(err==ERROR_DISTTRANSNOTFINISH)
    {
        int i;
        waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Distance Transform...", nil)];
        [waiting showWindow:self];
        
        for(i=0; i<5; i++)
        {
            sleep(2);
            err= [assistant createCenterline:centerline FromPointA:pointA ToPointB:pointB withSmoothing:YES];
            if(err!=ERROR_DISTTRANSNOTFINISH)
                break;
        }
        [waiting close];
        [waiting autorelease];
        if(err==ERROR_CANNOTFINDPATH)
        {
            NSRunAlertPanel(NSLocalizedString(@"Can't find path", nil), NSLocalizedString(@"Path Assistant can not find a path from current location.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            return;
        }
        else if(err==ERROR_DISTTRANSNOTFINISH)
        {
            NSRunAlertPanel(NSLocalizedString(@"Unexpected error", nil), NSLocalizedString(@"Path Assistant failed to initialize!", nil), NSLocalizedString(@"OK", nil), nil, nil);
            return;
        }
    }
}

- (IBAction)pathAssistantLockPath:(id)sender;
{
    isLookingBackwards=NO;
    [pathAssistantLookBackButton setState:NSOffState];
    [pathAssistantExportToFlyThruButton setEnabled:YES];
    
    isFlyPathLocked = YES;
    [assistant downSampleCenterlineWithLocalRadius:centerline];
    [assistant createSmoothedCenterlin:centerline withStepLength:centerlineResampleStepLength];
    
    [self updateCenterlineInMPRViews];
    flyAssistantPositionIndex=0;
    [self flyThruAssistantGoForward:nil];
}

- (IBAction)pathAssistantDeletePath:(id)sender;
{
    isLookingBackwards=NO;
    [pathAssistantLookBackButton setState:NSOffState];
    [pathAssistantExportToFlyThruButton setEnabled:NO];
    
    isFlyPathLocked = NO;
    [centerline removeAllObjects];
    [self updateCenterlineInMPRViews];
    flyAssistantPositionIndex=0;
}

- (IBAction)pathAssistantBasicModeButtonAction:(id)sender;
{
    if ([[pathAssistantBasicModeButton title] isEqualToString:@"Lock Path"])
    {
        [self pathAssistantLockPath:self];
        [pathAssistantBasicModeButton setTitle:@"Delete Path"];
    }
    else if ([[pathAssistantBasicModeButton title] isEqualToString:@"Delete Path"])
    {
        [self pathAssistantDeletePath:self];
        [pathAssistantBasicModeButton setTitle:@"Lock Path"];
    }
}

- (IBAction)pathAssistantChangeMode:(id)sender;
{
    if([sender selectedRow]==0)
    {
        isFlyPathLocked = NO;
        [pathAssistantBasicModeButton setEnabled:YES];
        [pathAssistantBasicModeButton setTitle:@"Lock Path"];
        [pathAssistantSetPointAButton setEnabled:NO];
        [pathAssistantSetPointBButton setEnabled:NO];
        [pathAssistantExportToFlyThruButton setEnabled:NO];
        if([centerline count])
        {
            [self flyThruAssistantGoBackward:nil];
        }
        flyAssistantMode = NAVIGATORMODE_BASIC;
    }
    else if([sender selectedRow]==1){
        [pathAssistantBasicModeButton setEnabled:NO];
        [pathAssistantBasicModeButton setTitle:@"Lock Path"];
        [pathAssistantSetPointAButton setEnabled:YES];
        [pathAssistantSetPointBButton setEnabled:NO];
        [pathAssistantExportToFlyThruButton setEnabled:NO];
        flyAssistantMode = NAVIGATORMODE_2POINT;
    }
    
}

- (IBAction)pathAssistantExportToFlyThru:(id)sender;
{
    [self flyThruControllerInit:sender];
    
    if(flyAssistantMode == NAVIGATORMODE_2POINT || isFlyPathLocked)
    {
        int numberOfPointsInCenterline = [centerline count];
        int increment = 1;
        
        if(numberOfPointsInCenterline<=30)
        {
            increment = 1;
        }
        else if(numberOfPointsInCenterline<=100)
        {
            increment = 2;
        }
        else
        {
            increment = numberOfPointsInCenterline/50;
        }
        
        [[vrController flyThruController].stepsArrayController flyThruTag:2]; // reset fly thru
        
        flyAssistantPositionIndex = 0;
        while(flyAssistantPositionIndex < numberOfPointsInCenterline-1)
        {
            // move camera
            OSIVoxel* cpos = [centerline objectAtIndex:flyAssistantPositionIndex];
            OSIVoxel * fpos;
//            if (/*NO*/YES) {
                fpos = [assistant computeMaximizingViewDirectionFrom:cpos
                                                           LookingAt:[centerline objectAtIndex:flyAssistantPositionIndex+1]];
//            }
//            else
//            {
//                fpos = [centerline objectAtIndex:flyAssistantPositionIndex+1];
//            }
            [self setCameraAtPosition:cpos TowardsPosition:fpos];
            
            // add current camera to Fly Thru
            [[vrController flyThruController].stepsArrayController addObject:[vrController flyThruController].currentCamera];
            [[vrController flyThruController].stepsArrayController resetCameraIndexes];
            
            // prepare the next move
            flyAssistantPositionIndex += increment;
        }
    }
}

- (void)windowWillCloseNotificationSelector:(NSNotification*)notification
{
    if([notification object]==pathAssistantPanel)
    {
        if(assistantSettingPanel)
        {
            [assistantSettingPanel close];
        }
        
    }
}

#pragma mark-
#pragma mark Fly Assistant
//assistant
//
- (void) initFlyAssistant:(NSData*) vData
{
    //init assistant
    [[mprController originalView] becomeFirstResponder];
    [[self window] makeKeyAndOrderFront:nil];
    assistantInputData = (float*)[vData bytes];
    int dim[3];
    DCMPix* firstObject = [pixList objectAtIndex:0];
    dim[0] = [firstObject pwidth];
    dim[1] = [firstObject pheight];
    dim[2] = [pixList count];
    float spacing[3];
    spacing[0]=[firstObject pixelSpacingX];
    spacing[1]=[firstObject pixelSpacingY];
    float sliceThickness = [firstObject sliceInterval];
    if( sliceThickness == 0)
    {
        NSLog(@"Slice interval = slice thickness!");
        sliceThickness = [firstObject sliceThickness];
    }
    spacing[2]=sliceThickness;
    float resamplesize=spacing[0];
    if(dim[0]>256 || dim[1]>256)
    {
        if(spacing[0]*(float)dim[0]>spacing[1]*(float)dim[1])
            resamplesize = spacing[0]*(float)dim[0]/256.0;
        else {
            resamplesize = spacing[1]*(float)dim[1]/256.0;
        }
        
    }
    
    assistant = [[FlyAssistant alloc] initWithVolume:assistantInputData WidthDimension:dim Spacing:spacing ResampleVoxelSize:resamplesize];
    centerlineResampleStepLength = 3.0; //mm
    if(assistant)
    {
        //[assistant setThreshold:-600.0 Asynchronous:YES];
        
        [assistant setCenterlineResampleStepLength:centerlineResampleStepLength];
    }
    else {
        NSRunAlertPanel(NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"Path Assistant can not allocate enough memory, try to increase the resample voxel size in the settings.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    
    //misc
    
    [assistantPanelTextThreshold setIntValue:-600];
    [assistantPanelTextResampleSize setFloatValue:resamplesize];
    [assistantPanelTextStepLength setFloatValue:centerlineResampleStepLength];
    [assistantPanelSliderThreshold setIntValue:-600];
    [assistantPanelSliderResampleSize setFloatValue:resamplesize];
    [assistantPanelSliderStepLength setFloatValue:centerlineResampleStepLength];
    
    centerline = [[NSMutableArray alloc] initWithCapacity:100];
    centerlineAxial = [[NSMutableArray alloc] initWithCapacity:100];
    centerlineCoronal = [[NSMutableArray alloc] initWithCapacity:100];
    centerlineSagittal = [[NSMutableArray alloc] initWithCapacity:100];
    [(EndoscopyMPRView*)[mprController originalView] setFlyThroughPath:centerlineAxial];
    [(EndoscopyMPRView*)[mprController xReslicedView] setFlyThroughPath:centerlineCoronal];
    [(EndoscopyMPRView*)[mprController yReslicedView] setFlyThroughPath:centerlineSagittal];
    
    
    flyAssistantMode = NAVIGATORMODE_BASIC;
    isFlyPathLocked = NO;
    
    [pathAssistantBasicModeButton setTitle:@"Lock Path"];
    [pathAssistantSetPointAButton setEnabled:NO];
    [pathAssistantSetPointBButton setEnabled:NO];
    
    isLookingBackwards=NO;
    isShowCenterLine=YES;
    
    [pathAssistantLookBackButton setState:NSOffState];
    [pathAssistantLookBackButton setEnabled:NO];
    [pathAssistantCameraOrFocalOnPathMatrix setEnabled:NO];
    [pathAssistantExportToFlyThruButton setEnabled:NO];
    
}
- (IBAction) applyNewSettingForFlyAssistant:(id) sender
{
    if(assistant)
        [assistant release];
    int dim[3];
    DCMPix* firstObject = [pixList objectAtIndex:0];
    dim[0] = [firstObject pwidth];
    dim[1] = [firstObject pheight];
    dim[2] = [pixList count];
    float spacing[3];
    spacing[0]=[firstObject pixelSpacingX];
    spacing[1]=[firstObject pixelSpacingY];
    float sliceThickness = [firstObject sliceInterval];
    if( sliceThickness == 0)
    {
        NSLog(@"Slice interval = slice thickness!");
        sliceThickness = [firstObject sliceThickness];
    }
    spacing[2]=sliceThickness;
    float resamplesize = [assistantPanelTextResampleSize floatValue];
    assistant = [[FlyAssistant alloc] initWithVolume:assistantInputData WidthDimension:dim Spacing:spacing ResampleVoxelSize:resamplesize];
    float threshold = [assistantPanelTextThreshold floatValue];
    centerlineResampleStepLength = [assistantPanelTextStepLength floatValue];
    if(assistant)
    {
        WaitRendering* waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Distance Transform...", nil)];
        [waiting showWindow:self];
        [assistant setThreshold:threshold Asynchronous:NO];
        [assistant setCenterlineResampleStepLength:centerlineResampleStepLength];
        [waiting close];
        [waiting autorelease];
    }
    else {
        NSRunAlertPanel(NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"Path Assistant can not allocate enough memory, try to increase the resample voxel size in the settings.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
}
- (void) flyThruAssistantGoForward: (NSNotification*)note
{
    if(flyAssistantMode == NAVIGATORMODE_2POINT || isFlyPathLocked)
    {
        if(flyAssistantPositionIndex + 1 < [centerline count])
        {
            OSIVoxel* cpos = [centerline objectAtIndex:flyAssistantPositionIndex];
            OSIVoxel * fpos = [centerline objectAtIndex:flyAssistantPositionIndex+1];
            [self setCameraAtPosition:cpos TowardsPosition:fpos];
            flyAssistantPositionIndex++;
        }
        
    }
    else if(flyAssistantMode == NAVIGATORMODE_BASIC && isFlyPathLocked==NO)
    {
        Point3D* pt = [Point3D point];
        Point3D* dir = [Point3D point];
        pt.x = [(EndoscopyMPRView*)[mprController originalView] crossPositionX];
        pt.y = [(EndoscopyMPRView*)[mprController originalView] crossPositionY];
        pt.z = [pixList count]-[[mprController xReslicedView] crossPositionY];
        
        dir.x = [(EndoscopyMPRView*)[mprController originalView] focalShiftX];
        dir.y = [(EndoscopyMPRView*)[mprController originalView] focalShiftY];
        dir.z = -[(EndoscopyMPRView*)[mprController xReslicedView] focalShiftY];
        
        int err= [assistant caculateNextPositionFrom:pt Towards:dir];
        if(err==ERROR_NOENOUGHMEM)
        {
            NSRunAlertPanel(NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"Path Assistant can not allocate enough memory, try to increase the resample voxel size in the settings.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            return;
        }
        else if(err==ERROR_CANNOTFINDPATH)
        {
            NSRunAlertPanel(NSLocalizedString(@"Can't find path", nil), NSLocalizedString(@"Path Assistant can not find a path from current location.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            return;
        }
        else if(err==ERROR_DISTTRANSNOTFINISH)
        {
            int i;
            WaitRendering* waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Distance Transform...", nil)];
            [waiting showWindow:self];
            
            for(i=0; i<5; i++)
            {
                sleep(2);
                err= [assistant caculateNextPositionFrom:pt Towards:dir];
                if(err!=ERROR_DISTTRANSNOTFINISH)
                    break;
            }
            [waiting close];
            [waiting autorelease];
            if(err==ERROR_CANNOTFINDPATH)
            {
                NSRunAlertPanel(NSLocalizedString(@"Can't find path", nil), NSLocalizedString(@"Path Assistant can not find a path from current location.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                return;
            }
            else if(err==ERROR_DISTTRANSNOTFINISH)
            {
                NSRunAlertPanel(NSLocalizedString(@"Unexpected error", nil), NSLocalizedString(@"Path Assistant failed to initialize!", nil), NSLocalizedString(@"OK", nil), nil, nil);
                return;
            }
        }
        
        OSIVoxel * cpos=[OSIVoxel pointWithPoint3D:pt];
        float foclength=30;
        if(dir.z>0)
            foclength = ((long)[pixList count] -1 - pt.z)/dir.z;
        else if(dir.z<0){
            foclength = (1 - pt.z)/dir.z;
        }
        if(foclength>30)
            foclength = 30;
        
        dir.x=pt.x+dir.x*foclength;dir.y=pt.y+dir.y*foclength;dir.z=pt.z+dir.z*foclength;
        OSIVoxel * fpos=[OSIVoxel pointWithPoint3D:dir];
        
        [self setCameraPosition:cpos focalPoint:fpos];
        
        [centerline addObject:cpos];
        flyAssistantPositionIndex = (long)[centerline count]-1;
        
        [self updateCenterlineInMPRViews];
        
    }
    
    
}
- (void) flyThruAssistantGoBackward: (NSNotification*)note
{
    if(flyAssistantMode == NAVIGATORMODE_BASIC && isFlyPathLocked==NO )
    {
        if([centerline count]<2)
            return;
        OSIVoxel* cpos = [centerline objectAtIndex:[centerline count]-2];
        OSIVoxel * fpos = [centerline objectAtIndex:(long)[centerline count]-1];
        [self setCameraAtPosition:cpos TowardsPosition:fpos];
        [centerline removeLastObject];
        flyAssistantPositionIndex = (long)[centerline count]-1;
        [self updateCenterlineInMPRViews];
    }
    else if(flyAssistantMode == NAVIGATORMODE_2POINT || isFlyPathLocked){
        if(flyAssistantPositionIndex > 0)
        {
            OSIVoxel* cpos = [centerline objectAtIndex:flyAssistantPositionIndex-1];
            OSIVoxel * fpos = [centerline objectAtIndex:flyAssistantPositionIndex];
            [self setCameraAtPosition:cpos TowardsPosition:fpos];
            flyAssistantPositionIndex--;
        }
    }
    
}

- (IBAction) showingAssistantSettings:(id) sender
{
    [assistantSettingPanel makeKeyAndOrderFront: self];
}
- (void) updateCenterlineInMPRViews
{
    int i;
    [centerlineAxial removeAllObjects];
    [centerlineCoronal removeAllObjects];
    [centerlineSagittal removeAllObjects];
    if(isShowCenterLine)
    {
        int zmax = [pixList count];
        for(i=0;i<[centerline count];i++)
        {
            OSIVoxel* pt = [centerline objectAtIndex:i];
            Point3D* pto = [Point3D point];
            pto.x = pt.x; pto.y = pt.y;
            [centerlineAxial addObject:pto];
            Point3D* ptx = [Point3D point];
            ptx.x = pt.x; ptx.y = zmax - pt.z;
            [centerlineCoronal addObject:ptx];
            Point3D* pty = [Point3D point];
            pty.x = pt.y; pty.y = zmax - pt.z;
            [centerlineSagittal addObject:pty];
            
        }
    }
    if([centerline count]>2&&(isFlyPathLocked||flyAssistantMode == NAVIGATORMODE_2POINT))
    {
        [pathAssistantLookBackButton setEnabled:YES];
        [pathAssistantCameraOrFocalOnPathMatrix setEnabled:YES];
    }
    else
    {
        [pathAssistantLookBackButton setEnabled:NO];
        [pathAssistantCameraOrFocalOnPathMatrix setEnabled:NO];
    }
    
    [[mprController originalView] setNeedsDisplay: YES];
    [[mprController xReslicedView] setNeedsDisplay: YES];
    [[mprController yReslicedView] setNeedsDisplay: YES];
    
}
- (void) setCameraAtPosition:(OSIVoxel *)cpos TowardsPosition:(OSIVoxel *)fpos
{
    OSIVoxel* dir=[OSIVoxel pointWithX:0 y:0 z:0 value:nil];
    dir.x = fpos.x - cpos.x;
    dir.y = fpos.y - cpos.y;
    dir.z = fpos.z - cpos.z;
    float len=sqrt(dir.x*dir.x + dir.y*dir.y + dir.z*dir.z);
    if (len > 1.0e-6)
    {
        dir.x = dir.x/len;
        dir.y = dir.y/len;
        dir.z = dir.z/len;
    }
    if(isLookingBackwards)
    {
        dir.x = -dir.x;
        dir.y = -dir.y;
        dir.z = -dir.z;
    }
    
    float localradius = [assistant radiusAtPoint:cpos];
    if(localradius < centerlineResampleStepLength )
        localradius = centerlineResampleStepLength;
    int neighborrange = localradius*4.0/centerlineResampleStepLength;
    localradius = [assistant averageRadiusAt:flyAssistantPositionIndex On:centerline InRange:neighborrange];
    //float localradius = 30;
    if(localradius < centerlineResampleStepLength )
        localradius = centerlineResampleStepLength;
    float foclength=localradius*2.0;
    if(foclength<1.0)
        foclength=1.0;
    if(dir.z>0)
        foclength = ((long)[pixList count] -1 - cpos.z)/dir.z;
    else if(dir.z<0){
        foclength = (1 - cpos.z)/dir.z;
    }
    if(foclength>localradius*2.0)
        foclength = localradius*2.0;
    
    if(lockCameraFocusOnPath)
    {
        dir.x = -dir.x*foclength + cpos.x;
        dir.y = -dir.y*foclength + cpos.y;
        dir.z = -dir.z*foclength + cpos.z;
        [self setCameraPosition:dir focalPoint:cpos];
    }
    else {
        dir.x = dir.x*foclength + cpos.x;
        dir.y = dir.y*foclength + cpos.y;
        dir.z = dir.z*foclength + cpos.z;
        [self setCameraPosition:cpos focalPoint:dir];
    }
}

- (IBAction) showOrHideCenterlines:(id) sender
{
    if([sender state]==NSOnState)
        isShowCenterLine=YES;
    else {
        isShowCenterLine=NO;
    }
    [self updateCenterlineInMPRViews];
    
    
}
- (IBAction)lookBackwards:(id)sender
{
    if([sender state]==NSOnState)
        isLookingBackwards=YES;
    else {
        isLookingBackwards=NO;
    }
    [self flyThruAssistantGoBackward:nil];
}

- (IBAction)lockCameraOrFocusOnPath:(id)sender
{
    if([sender selectedRow]==0)
    {
        lockCameraFocusOnPath=NO;
    }
    else {
        lockCameraFocusOnPath=YES;
    }
}

@end
