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

#import "MPRController.h"
#import "BrowserController.h"
#import "Wait.h"
#import "DICOMExport.h"
#import "DicomImage.h"
#import "ROI.h"
#import "iPhoto.h"

#define PRESETS_DIRECTORY @"/3DPRESETS/"
#define CLUTDATABASE @"/CLUTs/"
#define DATABASEPATH @"/DATABASE.noindex/"
#define UNDOQUEUESIZE 40

extern short intersect3D_2Planes( float *Pn1, float *Pv1, float *Pn2, float *Pv2, float *u, float *iP);
static float deg2rad = 3.14159265358979/180.0; 

@implementation MPRController

@synthesize dcmSameIntervalAndThickness, clippingRangeThickness, clippingRangeMode, mousePosition, mouseViewID, originalPix, wlwwMenuItems, LOD, dcmFrom;
@synthesize dcmmN, dcmTo, dcmMode, dcmRotationDirection, dcmSeriesMode, dcmRotation, dcmNumberOfFrames, dcmQuality, dcmInterval, dcmSeriesName, dcmBatchNumberOfFrames;
@synthesize colorAxis1, colorAxis2, colorAxis3, displayMousePosition, movieRate, blendingPercentage, horizontalSplit, verticalSplit;
@synthesize mprView1, mprView2, mprView3, curMovieIndex, maxMovieIndex, blendingMode, dcmFormat, blendingModeAvailable, dcmBatchReverse;

+ (double) angleBetweenVector:(float*) a andPlane:(float*) orientation
{
	double sc[ 2];
	
	sc[ 0 ] = a[ 0] * orientation[ 0 ] + a[ 1] * orientation[ 1 ] + a[ 2] * orientation[ 2 ];
	sc[ 1 ] = a[ 0] * orientation[ 3 ] + a[ 1] * orientation[ 4 ] + a[ 2] * orientation[ 5 ];
	
	return ((atan2( sc[1], sc[0])) / deg2rad);
}

- (DCMPix*) emptyPix: (DCMPix*) oP width: (long) w height: (long) h
{
	long size = sizeof( float) * w * h;
	float *imagePtr = malloc( size);
	DCMPix *emptyPix = [[[DCMPix alloc] initwithdata: imagePtr :32 :w :h :[oP pixelSpacingX] :[oP pixelSpacingY] :[oP originX] :[oP originY] :[oP originZ]] autorelease];
	free( imagePtr);
	
	[emptyPix setImageObj: [oP imageObj]];
	[emptyPix setSrcFile: [oP srcFile]];
	[emptyPix setAnnotationsDictionary: [oP annotationsDictionary]];
	
	return emptyPix;
}

- (id)initWithDCMPixList:(NSMutableArray*)pix filesList:(NSMutableArray*)files volumeData:(NSData*)volume viewerController:(ViewerController*)viewer fusedViewerController:(ViewerController*)fusedViewer;
{
	@try
	{
		self = [super initWithWindowNibName:@"MPR"];
		
		[[self window] setWindowController: self];
		[[[self window] toolbar] setDelegate: self];
		
		originalPix = [pix lastObject];
		
		if( [originalPix isRGB])
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval",nil), NSLocalizedString( @"RGB images are not supported.",nil), NSLocalizedString(@"OK",nil), nil, nil);
			return nil;
		}
		
		pixList[0] = pix;
		filesList[0] = files;
		volumeData[0] = volume;
		viewer2D = viewer;
		fusedViewer2D = fusedViewer;
		
		if( fusedViewer2D)
			self.blendingModeAvailable = YES;
		
		self.displayMousePosition = [[NSUserDefaults standardUserDefaults] boolForKey: @"MPRDisplayMousePosition"];
		self.maxMovieIndex = 0;
		
		[self updateToolbarItems];
		
		for( int i = 0; i < [popupRoi numberOfItems]; i++)
			[[popupRoi itemAtIndex: i] setImage: [self imageForROI: [[popupRoi itemAtIndex: i] tag]]];
		
		DCMPix *emptyPix = [self emptyPix: originalPix width: 100 height: 100];
		[mprView1 setDCMPixList: [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] roiList: nil firstImage:0 type:'i' reset:YES];
		[mprView1 setFlippedData: [[viewer imageView] flippedData]];
		
		emptyPix = [self emptyPix: originalPix width: 100 height: 100];
		[mprView2 setDCMPixList: [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] roiList: nil firstImage:0 type:'i' reset:YES];
		[mprView2 setFlippedData: [[viewer imageView] flippedData]];
		
		emptyPix = [self emptyPix: originalPix width: 100 height: 100];
		[mprView3 setDCMPixList: [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] roiList: nil firstImage:0 type:'i' reset:YES];
		[mprView3 setFlippedData: [[viewer imageView] flippedData]];
		
		if( fusedViewer)
		{
			blendedMprView1 = [[DCMView alloc] initWithFrame: [mprView1 frame]];
			blendedMprView2 = [[DCMView alloc] initWithFrame: [mprView2 frame]];
			blendedMprView3 = [[DCMView alloc] initWithFrame: [mprView3 frame]];
			
			emptyPix = [[[[fusedViewer imageView] curDCM] copy] autorelease];
			[blendedMprView1 setDCM:  [NSMutableArray arrayWithObject: emptyPix] : [NSArray arrayWithObject: [files lastObject]] :nil :0 :'i' :YES];
			
			emptyPix = [[[[fusedViewer imageView] curDCM] copy] autorelease];
			[blendedMprView2 setDCM:  [NSMutableArray arrayWithObject: emptyPix] : [NSArray arrayWithObject: [files lastObject]] :nil :0 :'i' :YES];
			
			emptyPix = [[[[fusedViewer imageView] curDCM] copy] autorelease];
			[blendedMprView3 setDCM:  [NSMutableArray arrayWithObject: emptyPix] : [NSArray arrayWithObject: [files lastObject]] :nil :0 :'i' :YES];
			
			[mprView1 setBlending: blendedMprView1];
			[mprView2 setBlending: blendedMprView2];
			[mprView3 setBlending: blendedMprView3];
			
			[mprView1 setBlendingFactor: 0.5];
			[mprView2 setBlendingFactor: 0.5];
			[mprView3 setBlendingFactor: 0.5];
			
			[mprView1 setWLWW: [[fusedViewer imageView] curDCM].wl :[[fusedViewer imageView] curDCM].ww];
			[mprView2 setWLWW: [[fusedViewer imageView] curDCM].wl :[[fusedViewer imageView] curDCM].ww];
			[mprView3 setWLWW: [[fusedViewer imageView] curDCM].wl :[[fusedViewer imageView] curDCM].ww];
			
			self.blendingPercentage = 50;
			self.blendingMode = 0;
		}
		
		hiddenVRController = [[VRController alloc] initWithPix:pix :files :volume :fusedViewer :viewer style:@"noNib" mode:@"MIP"];
		[hiddenVRController retain];
		
		// To avoid the "invalid drawable" message
		[[hiddenVRController window] setLevel: 0];
		[[hiddenVRController window] orderBack: self];
		[[hiddenVRController window] orderOut: self];
		
		[hiddenVRController load3DState];
		
		hiddenVRView = [hiddenVRController view];
		[hiddenVRView setClipRangeActivated: YES];
		[hiddenVRView resetImage: self];
		[hiddenVRView setLOD: 20];
		hiddenVRView.keep3DRotateCentered = YES;
		
		[mprView1 setVRView: hiddenVRView viewID: 1];
		[mprView1 setWLWW: [originalPix wl] :[originalPix ww]];
		
		[mprView2 setVRView: hiddenVRView viewID: 2];
		[mprView2 setWLWW: [originalPix wl] :[originalPix ww]];
		
		[mprView3 setVRView: hiddenVRView viewID: 3];
		[mprView3 setWLWW: [originalPix wl] :[originalPix ww]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultToolModified:) name:@"defaultToolModified" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateWLWWMenu:) name:@"UpdateWLWWMenu" object:nil];
		curWLWWMenu = [[viewer2D curWLWWMenu] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateCLUTMenu:) name:@"UpdateCLUTMenu" object: nil];
		curCLUTMenu = [[viewer2D curCLUTMenu] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: nil];
		
		startingOpacityMenu = [[viewer2D curOpacityMenu] retain];
		curOpacityMenu = [startingOpacityMenu retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateOpacityMenu:) name:@"UpdateOpacityMenu" object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:@"CloseViewerNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(changeWLWW:) name: @"changeWLWW" object: nil];
		
		[shadingCheck setAction:@selector(switchShading:)];
		[shadingCheck setTarget:self];
		
		self.dcmNumberOfFrames = 50;
		self.dcmRotationDirection = 0;
		self.dcmRotation = 360;
		self.dcmSeriesName = @"MPR";
		float r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3;
		r1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_RED"];
		g1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_GREEN"];
		b1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_BLUE"];
		a1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_ALPHA"];
		
		r2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_RED"];
		g2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_GREEN"];
		b2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_BLUE"];
		a2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_ALPHA"];
		
		r3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_RED"];
		g3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_GREEN"];
		b3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_BLUE"];
		a3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_ALPHA"];
		
		if(r1==0.0 && g1==0.0 && b1==0.0 && a1==0.0 && r2==0.0 && g2==0.0 && b2==0.0 && a2==0.0 && r3==0.0 && g3==0.0 && b3==0.0 && a3==0.0)
		{
			r1 = 1.0; g1 = 0.67; b1 = 0.0; a1 = 0.8;
			r2 = 0.6; g2 = 0.0; b2 = 1.0; a2 = 0.8;
			r3 = 0.0; g3 = 0.5; b3 = 1.0; a3 = 0.8;
		}
		
		self.colorAxis1 = [NSColor colorWithDeviceRed:r1 green:g1 blue:b1 alpha:a1];
		self.colorAxis2 = [NSColor colorWithDeviceRed:r2 green:g2 blue:b2 alpha:a2];
		self.colorAxis3 = [NSColor colorWithDeviceRed:r3 green:g3 blue:b3 alpha:a3];
		
		[[NSColorPanel sharedColorPanel] setShowsAlpha: YES];
		
		undoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
		redoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
		
		[self setToolIndex: tWL];
	}
	
	@catch (NSException *e)
	{
		NSLog( @"MPR Init failed: %@", e);
		return nil;
	}
	
	return self;
}

- (void) delayedFullLODRendering:(id) sender
{
	if( windowWillClose) return;
	
	if( hiddenVRView.lowResLODFactor > 1 || sender != nil)
	{
		[hiddenVRView setLODLow: NO];
	
		[self updateViewsAccordingToFrame: sender];
	
		[hiddenVRView setLODLow: YES];
	}
}

- (void) updateViewsAccordingToFrame:(id) sender	// see setFrame in MPRDCMView.m
{
	if( windowWillClose) return;
	
	id view = [[self window] firstResponder];
	
	[mprView1 camera].forceUpdate = YES;
	[mprView2 camera].forceUpdate = YES;
	[mprView3 camera].forceUpdate = YES;
	
	if( sender)
	{
		[[self window] makeFirstResponder: sender];
		[sender restoreCamera];
		[sender updateViewMPR];
	}
	else
	{
		[[self window] makeFirstResponder: mprView3];
		[mprView3 restoreCamera];
		[mprView3 updateViewMPR];
	}
	
	if( view)
		[[self window] makeFirstResponder: view];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
}

- (void) showWindow:(id) sender
{
	[hiddenVRView setLOD: 20];
	
	// Default Init
	[self setClippingRangeMode: 1]; // MIP
	[self setClippingRangeThickness: 1];
	if( [self getClippingRangeThicknessInMm] < fabs( [originalPix sliceInterval]) / 2.)
		[self setClippingRangeThickness: 2];
	
	[[self window] makeFirstResponder: mprView1];
	[mprView1.vrView resetImage: self];

	mprView1.angleMPR = 0;
	mprView2.angleMPR = 0;
	mprView3.angleMPR = 0;

	[mprView1 updateViewMPR];
	
	mprView2.camera.viewUp = [Point3D pointWithX:0 y:-1 z:0];
	
	[[self window] makeFirstResponder: mprView3];
	mprView3.camera.viewUp = [Point3D pointWithX:0 y:0 z:1];
	mprView3.camera.rollAngle = 0;
	mprView3.angleMPR = 0;
	[mprView3 restoreCamera];
	[mprView3 updateViewMPR];
	
	[super showWindow: sender];
	
	[self setLOD: [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultMPRLOD"]];
}

-(void) awakeFromNib
{
	[shadingsPresetsController setWindowController: self];
	[shadingCheck setAction:@selector(switchShading:)];
	[shadingCheck setTarget:self];
}

- (void) dealloc
{
	[mousePosition release];
	[wlwwMenuItems release];
	[toolbar release];
	[dcmSeriesName release];
	
	[colorAxis1 release];
	[colorAxis2 release];
	[colorAxis3 release];
	
	[undoQueue release];
	[redoQueue release];
	
	[movieTimer release];
	
	[blendedMprView1 release];
	[blendedMprView2 release];
	[blendedMprView3 release];
	
	[startingOpacityMenu release];
	
	[super dealloc];
	
	NSLog( @"dealloc MPRController");
}

- (BOOL) is2DViewer
{
	return NO;
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if( [note object] == viewer2D || [note object] == fusedViewer2D)
	{
		[self offFullScreen];
		[[self window] close];
	}
}

- (NSArray*) pixList
{
	return pixList[ curMovieIndex];
}

- (void) setToolIndex: (int) toolIndex
{
	[mprView1 setCurrentTool:toolIndex];
	[mprView2 setCurrentTool:toolIndex];
	[mprView3 setCurrentTool:toolIndex];
	[mprView1.vrView setCurrentTool:toolIndex];
	[mprView2.vrView setCurrentTool:toolIndex];
	[mprView3.vrView setCurrentTool:toolIndex];
}

- (IBAction) setTool:(id)sender;
{
	int toolIndex;
	
	if([sender isKindOfClass:[NSMatrix class]])
		toolIndex = [[sender selectedCell] tag];
	else if([sender respondsToSelector:@selector(tag)])
		toolIndex = [sender tag];
	
	[self setToolIndex: toolIndex];
	[self setROIToolTag: toolIndex];
}

- (void) computeCrossReferenceLinesBetween: (MPRDCMView*) mp1 and:(MPRDCMView*) mp2 result: (float[2][3]) s
{
	float vectorA[ 9], vectorB[ 9];
	float originA[ 3], originB[ 3];

	s[ 0][ 0] = HUGE_VALF; s[ 0][ 1] = HUGE_VALF; s[ 0][ 2] = HUGE_VALF;
	s[ 1][ 0] = HUGE_VALF; s[ 1][ 1] = HUGE_VALF; s[ 1][ 2] = HUGE_VALF;
	
	originA[ 0] = mp2.pix.originX; originA[ 1] = mp2.pix.originY; originA[ 2] = mp2.pix.originZ;
	originB[ 0] = mp1.pix.originX; originB[ 1] = mp1.pix.originY; originB[ 2] = mp1.pix.originZ;
	
	[mp2.pix orientation: vectorA];
	[mp1.pix orientation: vectorB];
	
	float slicePoint[ 3];
	float sliceVector[ 3];
	
	if( intersect3D_2Planes( vectorA+6, originA, vectorB+6, originB, sliceVector, slicePoint) == noErr)
	{
		[mp1 computeSliceIntersection: mp2.pix sliceFromTo: s vector: vectorB origin: originB];
	}
}

- (void) propagateWLWW:(MPRDCMView*) sender
{
	[mprView1 setWLWW: [sender curWL] :[sender curWW]];
	[mprView2 setWLWW: [sender curWL] :[sender curWW]];
	[mprView3 setWLWW: [sender curWL] :[sender curWW]];

	mprView1.camera.wl = [sender curWL];	mprView1.camera.ww = [sender curWW];
	mprView2.camera.wl = [sender curWL];	mprView2.camera.ww = [sender curWW];
	mprView3.camera.wl = [sender curWL];	mprView3.camera.ww = [sender curWW];
}

- (void) computeCrossReferenceLines:(MPRDCMView*) sender
{
	float a[2][3];
	float b[2][3];
	
	if( sender)
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"syncZoomLevelMPR"])
		{
			if( sender != mprView1) mprView1.camera.parallelScale = sender.camera.parallelScale;
			if( sender != mprView2) mprView2.camera.parallelScale = sender.camera.parallelScale;
			if( sender != mprView3) mprView3.camera.parallelScale = sender.camera.parallelScale;
		}
	}

	// Center other views on the sender view
	if( sender && [sender isKeyView] == YES && avoidReentry == NO)
	{
		avoidReentry = YES;
		
		float x, y, z;
		Camera *cam = sender.camera;
		Point3D *position = cam.position;
		Point3D *viewUp = cam.viewUp;
		float halfthickness = sender.vrView.clippingRangeThickness / 2.;
		float cos[ 9];
		[sender.pix orientation: cos];
		
		// Correct slice position according to slice center (VR: position is the beginning of the slice)
		position = [Point3D pointWithX: position.x + halfthickness*cos[ 6] y:position.y + halfthickness*cos[ 7] z:position.z + halfthickness*cos[ 8]];
		
		if( sender != mprView1) mprView1.camera.position = position;
		if( sender != mprView2) mprView2.camera.position = position;
		if( sender != mprView3) mprView3.camera.position = position;
		
		if( sender == mprView1)
		{
			float angle = mprView1.angleMPR;
			XYZ vector, rotationVector;
			rotationVector.x = cos[ 6];	rotationVector.y = cos[ 7];	rotationVector.z = cos[ 8];
			
			vector.x = cos[ 3];	vector.y = cos[ 4];	vector.z = cos[ 5];
			vector =  ArbitraryRotate(vector, (angle-180.)*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView2.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			Point3D *p = mprView2.camera.position;
			mprView2.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
			
			vector.x = cos[ 0];	vector.y = cos[ 1];	vector.z = cos[ 2];
			vector =  ArbitraryRotate(vector, angle*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView3.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			p = mprView3.camera.position;
			mprView3.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
		}
		
		if( sender == mprView2)
		{
			float angle = mprView2.angleMPR;
			XYZ vector, rotationVector;
			rotationVector.x = cos[ 6];	rotationVector.y = cos[ 7];	rotationVector.z = cos[ 8];
			
			vector.x = cos[ 3];	vector.y = cos[ 4];	vector.z = cos[ 5];
			vector =  ArbitraryRotate(vector, angle*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView3.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			Point3D *p = mprView3.camera.position;
			mprView3.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
			
			vector.x = cos[ 0];	vector.y = cos[ 1];	vector.z = cos[ 2];
			vector =  ArbitraryRotate(vector, (angle-180.)*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView1.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			p = mprView1.camera.position;
			mprView1.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
		}
		
		if( sender == mprView3)
		{
			float angle = mprView3.angleMPR;
			XYZ vector, rotationVector;
			rotationVector.x = cos[ 6];	rotationVector.y = cos[ 7];	rotationVector.z = cos[ 8];
			
			vector.x = cos[ 3];	vector.y = cos[ 4];	vector.z = cos[ 5];
			vector =  ArbitraryRotate(vector, (angle-180.)*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView2.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			Point3D *p = mprView2.camera.position;
			mprView2.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
			
			vector.x = -cos[ 0];	vector.y = -cos[ 1];	vector.z = -cos[ 2];
			vector =  ArbitraryRotate(vector, angle*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView1.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			p = mprView1.camera.position;
			mprView1.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
		}
		
		float l, w;
		[sender.vrView getWLWW: &l : &w];
			
		if( sender != mprView1)
		{
			[mprView1 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView1.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView1.vrView setWLWW: l : w];
			}
			
			[mprView1 updateViewMPR];
		}
		
		if( sender != mprView2)
		{
			[mprView2 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView2.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView2.vrView setWLWW: l : w];
			}
			
			[mprView2 updateViewMPR];
		}
		
		if( sender != mprView3)
		{
			[mprView3 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView3.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView3.vrView setWLWW: l : w];
			}
			
			[mprView3 updateViewMPR];
		}
		
		if( sender == mprView1)
		{
			float o[ 9], orientation[ 9];
			
			[sender.pix orientation: o];
			
			[mprView2.pix orientation: orientation];
			mprView2.angleMPR = [MPRController angleBetweenVector: o+6 andPlane:orientation]-180.;
			
			[mprView3.pix orientation: orientation];
			mprView3.angleMPR = [MPRController angleBetweenVector: o+6 andPlane:orientation]-180.;
		}
		
		if( sender == mprView2)
		{
			float o[ 9], orientation[ 9], sc[ 2];
			[sender.pix orientation: o];
			
			[mprView1.pix orientation: orientation];
			mprView1.angleMPR = [MPRController angleBetweenVector: o+6 andPlane:orientation]+90.;
			
			[mprView3.pix orientation: orientation];
			mprView3.angleMPR = [MPRController angleBetweenVector: o+6 andPlane:orientation]+90.;
		}
		
		if( sender == mprView3)
		{
			float o[ 9], orientation[ 9], sc[ 2];
			[sender.pix orientation: o];
			
			[mprView1.pix orientation: orientation];
			mprView1.angleMPR = [MPRController angleBetweenVector: o+6 andPlane:orientation];
			
			[mprView2.pix orientation: orientation];
			mprView2.angleMPR = [MPRController angleBetweenVector: o+6 andPlane:orientation]-90.;
		}
	}
	
	[self computeCrossReferenceLinesBetween: mprView1 and: mprView2 result: a];
	[self computeCrossReferenceLinesBetween: mprView1 and: mprView3 result: b];
	[mprView1 setCrossReferenceLines: a and: b];
	
	[self computeCrossReferenceLinesBetween: mprView2 and: mprView1 result: a];
	[self computeCrossReferenceLinesBetween: mprView2 and: mprView3 result: b];
	[mprView2 setCrossReferenceLines: a and: b];
	
	[self computeCrossReferenceLinesBetween: mprView3 and: mprView1 result: a];
	[self computeCrossReferenceLinesBetween: mprView3 and: mprView2 result: b];
	[mprView3 setCrossReferenceLines: a and: b];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
	
	avoidReentry = NO;
}

- (void) setMousePosition:(Point3D*) pt
{
	[mousePosition release];
	mousePosition = [pt retain];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
}

- (void)keyDown:(NSEvent *)theEvent
{
    unichar c = [[theEvent characters] characterAtIndex:0];
    
	if( c ==  ' ')
	{
		[self toogleAxisVisibility:self];
	}
	else if(c == 27) // 27 : escape
	{
		if(FullScreenOn) [self fullScreenMenu:self];
	}
	else [super keyDown: theEvent];
}

- (id) view
{
	return mprView1;
}

-(void) defaultToolModified: (NSNotification*) note
{
	id sender = [note object];
	int tag;
	
	if( sender)
	{
		if ([sender isKindOfClass:[NSMatrix class]])
		{
			NSButtonCell *theCell = [sender selectedCell];
			tag = [theCell tag];
		}
		else
			tag = [sender tag];
	}
	else
		tag = [[[note userInfo] valueForKey:@"toolIndex"] intValue];
	
	if( tag >= 0)
	{
		[toolsMatrix selectCellWithTag: tag];
		[self setToolIndex: tag];
		[self setROIToolTag: tag];
	}
}

#pragma mark ROI

- (void)bringToFrontROI:(ROI*) roi;
{

}

- (NSImage*) imageForROI: (int) i
{
	NSString	*filename = nil;
	switch( i)
	{
		case tMesure:		filename = @"Length";			break;
		case tAngle:		filename = @"Angle";			break;
		case tROI:			filename = @"Rectangle";		break;
		case tOval:			filename = @"Oval";				break;
		case tText:			filename = @"Text";				break;
		case tArrow:		filename = @"Arrow";			break;
		case tOPolygon:		filename = @"Opened Polygon";	break;
		case tCPolygon:		filename = @"Closed Polygon";	break;
		case tPencil:		filename = @"Pencil";			break;
		case t2DPoint:		filename = @"Point";			break;
		case tPlain:		filename = @"Brush";			break;
		case tRepulsor:		filename = @"Repulsor";			break;
		case tROISelector:	filename = @"ROISelector";		break;
		case tAxis:			filename = @"Axis";				break;
		case tDynAngle:		filename = @"DynamicAngle";		break;
	}
	
	if( filename == nil)
		return nil;
	
	return [NSImage imageNamed: filename];
}

-(void) setROIToolTag:(int) roitype
{
	NSImage *im = [self imageForROI: roitype];
	
	if( im)
	{
		NSButtonCell *cell = [toolsMatrix cellAtRow:0 column:6];
		[cell setTag: roitype];
		[cell setImage: im];
		
		[toolsMatrix selectCellAtRow:0 column:6];
	}
}

- (IBAction) roiDeleteAll:(id) sender
{
	[self addToUndoQueue: @"roi"];
	
	MPRDCMView *s = [self selectedView];
	
	[s stopROIEditingForce: YES];
	
	for( int y = 0; y < maxMovieIndex; y++)
	{
		for( ROI *r in [s curRoiList])
			[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object: r userInfo: nil];
		
		[[s curRoiList] removeAllObjects];
	}
	
	[s setIndex: [s curImage]];
}

#pragma mark Undo

- (id) prepareObjectForUndo:(NSString*) string
{
//	if( [string isEqualToString: @"roi"])
//	{
//		NSMutableArray	*rois = [NSMutableArray array];
//		
//		for( int i = 0; i < maxMovieIndex+1; i++)
//		{
//			NSMutableArray *array = [NSMutableArray array];
//			for( NSArray *ar in roiList[ i])
//			{
//				NSMutableArray	*a = [NSMutableArray array];
//				
//				for( ROI *r in ar)
//					[a addObject: [[r copy] autorelease]];
//				
//				[array addObject: a];
//			}
//			[rois addObject: array];
//		}
//		
//		return [NSDictionary dictionaryWithObjectsAndKeys: string, @"type", rois, @"rois", nil];
//	}
	
	if( [string isEqualToString: @"mprCamera"])
	{
		NSMutableArray	*cameras = [NSMutableArray array];
		
		[cameras addObject: [[mprView1.camera copy] autorelease]];
		[cameras addObject: [[mprView2.camera copy] autorelease]];
		[cameras addObject: [[mprView3.camera copy] autorelease]];
		
		NSMutableArray	*angleMPRs = [NSMutableArray array];
		
		[angleMPRs addObject: [NSNumber numberWithFloat: mprView1.angleMPR]];
		[angleMPRs addObject: [NSNumber numberWithFloat: mprView2.angleMPR]];
		[angleMPRs addObject: [NSNumber numberWithFloat: mprView3.angleMPR]];
		
		return [NSDictionary dictionaryWithObjectsAndKeys: string, @"type", cameras, @"cameras", angleMPRs, @"angleMPRs", nil];
	}
	
	return nil;
}

- (void) executeUndo:(NSMutableArray*) u
{
	if( [u count])
	{
		if( [[[u lastObject] objectForKey: @"type"] isEqualToString:@"mprCamera"])
		{
			NSArray	*cameras = [[u lastObject] objectForKey: @"cameras"];
			
			mprView1.camera = [cameras objectAtIndex: 0];
			mprView2.camera = [cameras objectAtIndex: 1];
			mprView3.camera = [cameras objectAtIndex: 2];
			
			NSArray	*angleMPRs = [[u lastObject] objectForKey: @"angleMPRs"];
			
			mprView1.angleMPR = [[angleMPRs objectAtIndex: 0] floatValue];
			mprView2.angleMPR = [[angleMPRs objectAtIndex: 1] floatValue];
			mprView3.angleMPR = [[angleMPRs objectAtIndex: 2] floatValue];
			
			[self updateViewsAccordingToFrame: nil];
		}
		
//		if( [[[u lastObject] objectForKey: @"type"] isEqualToString:@"roi"])
//		{
//			NSMutableArray	*rois = [[u lastObject] objectForKey: @"rois"];
//			
//			int i, x, z;
//			
//			for( i = 0; i < maxMovieIndex+1; i++)
//			{
//				for( x = 0; x < [roiList[ i] count] ; x++)
//				{
//					for( z = 0; z < [[roiList[ i] objectAtIndex: x] count]; z++)
//						[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:[[roiList[ i] objectAtIndex: x] objectAtIndex: z] userInfo: nil];
//						
//					[[roiList[ i] objectAtIndex: x] removeAllObjects];
//				}
//			}
//			
//			for( i = 0; i < maxMovieIndex+1; i++)
//			{
//				NSArray *r = [rois objectAtIndex: i];
//				
//				for( x = 0; x < [roiList[ i] count] ; x++)
//				{
//					[[roiList[ i] objectAtIndex: x] addObjectsFromArray: [r objectAtIndex: x]];
//					
//					for( ROI *r in [roiList[ i] objectAtIndex: x])
//					{
//						[imageView roiSet: r];
//						[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object: r userInfo: nil];
//					}
//				}
//			}
//			
//			[imageView setIndex: [imageView curImage]];
//			
//			NSLog( @"roi undo");
//		}
		
		[u removeLastObject];
	}
}

- (IBAction) redo:(id) sender
{
	if( [redoQueue count])
	{
		id obj = [self prepareObjectForUndo: [[redoQueue lastObject] objectForKey:@"type"]];
		
		if( obj)
			[undoQueue addObject: obj];
		
		[self executeUndo: redoQueue];
	}
	else NSBeep();
}

- (IBAction) undo:(id) sender
{
	if( [undoQueue count])
	{
		id obj = [self prepareObjectForUndo: [[undoQueue lastObject] objectForKey:@"type"]];
		
		if( obj)
			[redoQueue addObject: obj];
		
		[self executeUndo: undoQueue];
	}
	else NSBeep();
}

- (void) removeLastItemFromUndoQueue
{
	if( [undoQueue count])
		[undoQueue removeLastObject];
}

- (void) addToUndoQueue:(NSString*) string
{
	id obj = [self prepareObjectForUndo: string];
	
	if( obj)
		[undoQueue addObject: obj];
	
	if( [undoQueue count] > UNDOQUEUESIZE)
	{
		[undoQueue removeObjectAtIndex: 0];
	}
}

#pragma mark LOD

- (void) bestRendering:(id) sender
{
	[hiddenVRView setLOD: 1.0];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];
	
	[hiddenVRView setLOD: LOD];
}

- (void) setLOD: (float)lod;
{
	LOD = lod;
	[hiddenVRView setLOD: lod];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];
	
	[[NSUserDefaults standardUserDefaults] setFloat: LOD forKey: @"defaultMPRLOD"];
}

#pragma mark Window Level / Window width

- (void)createWLWWMenuItems;
{
    // Presets VIEWER Menu
	NSArray *keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] allKeys];
	NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableArray *tmp = [NSMutableArray array];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:curWLWWMenu action:nil keyEquivalent:@""] autorelease]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other", nil) action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Default WL & WW", nil) action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Full dynamic", nil) action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];
	[tmp addObject:[NSMenuItem separatorItem]];
    for(int i = 0; i < [sortedKeys count]; i++)
		[tmp addObject:[[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];

//    [tmp addObject:[NSMenuItem separatorItem]];
//	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector(AddCurrentWLWW:) keyEquivalent:@""] autorelease]];
//	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector(SetWLWW:) keyEquivalent:@""] autorelease]];	
	
	self.wlwwMenuItems = tmp;
}


- (void)UpdateWLWWMenu:(NSNotification*)note;
{
    NSUInteger i;	
    i = [[wlwwPopup menu] numberOfItems];
    while(i-- > 0) [[wlwwPopup menu] removeItemAtIndex:0];
	
	[self createWLWWMenuItems];
	
    for( i = 0; i < [self.wlwwMenuItems count]; i++)
    {
        [[wlwwPopup menu] addItem:[self.wlwwMenuItems objectAtIndex:i]];
    }
	
	if( [note object])
	{
		[curWLWWMenu release];
		curWLWWMenu = [[note object] retain];
		[wlwwPopup setTitle: curWLWWMenu];
	}
}

- (void)ApplyWLWW:(id)sender;
{
	NSString *menuString = [sender title];
	
	if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)])
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)])
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)])
	{
	}
	else
	{
		menuString = [menuString substringFromIndex: 4];
	}
	
	[self applyWLWWForString: menuString];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: nil];
}

- (void)applyWLWWForString:(NSString *)menuString;
{
	if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)])
	{
		//[imageView setWLWW:0 :0];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)])
	{
		[mprView1 setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[mprView2 setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[mprView3 setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)])
	{
		[mprView1 setWLWW:0 :0];
		[mprView2 setWLWW:0 :0];
		[mprView3 setWLWW:0 :0];
	}
	else
	{
		if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
		{
			NSBeginAlertSheet( NSLocalizedString(@"Delete a WL/WW preset",nil), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [menuString retain], [NSString stringWithFormat:@"Are you sure you want to delete preset : '%@'?", menuString]);
		}
		else
		{
			NSArray    *value;
			
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey:menuString];
			
			[mprView1 setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[mprView2 setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[mprView3 setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
		}
	}
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:menuString];
	
	if( curWLWWMenu != menuString)
	{
		[curWLWWMenu release];
		curWLWWMenu = [menuString retain];
	}	
}

#pragma mark CLUTs

- (void)UpdateCLUTMenu:(NSNotification*)note
{
    //*** Build the menu
    int i;
    NSArray *keys;
    NSArray *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    i = [[clutPopup menu] numberOfItems];
    while(i-- > 0) [[clutPopup menu] removeItemAtIndex:0];
	
	[[clutPopup menu] addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:nil keyEquivalent:@""];
    [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:@selector (ApplyCLUT:) keyEquivalent:@""];
	[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
    }
	
	[[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
	
//	// path 1 : /OsiriX Data/CLUTs/
//	NSMutableString *path = [NSMutableString stringWithString: [[BrowserController currentBrowser] documentsDirectory]];
//	[path appendString: CLUTDATABASE];
//	// path 2 : /resources_bundle_path/CLUTs/
//	NSMutableString *bundlePath = [NSMutableString stringWithString:[[NSBundle mainBundle] resourcePath]];
//	[bundlePath appendString: CLUTDATABASE];
//	
//	NSMutableArray *paths = [NSMutableArray arrayWithObjects:path, bundlePath, nil];
//	
//	NSMutableArray *clutArray = [NSMutableArray array];
//	BOOL isDir;
//	
//	for (NSUInteger j=0; j<[paths count]; j++)
//	{
//		if([[NSFileManager defaultManager] fileExistsAtPath:[paths objectAtIndex:j] isDirectory:&isDir] && isDir)
//		{
//			NSArray *content = [[NSFileManager defaultManager] directoryContentsAtPath:[paths objectAtIndex:j]];
//			for (NSUInteger i=0; i<[content count]; i++)
//			{
//				if( [[content objectAtIndex:i] length] > 0)
//				{
//					if( [[content objectAtIndex:i] characterAtIndex: 0] != '.')
//					{
//						NSDictionary* clut = [CLUTOpacityView presetFromFileWithName:[[content objectAtIndex:i] stringByDeletingPathExtension]];
//						if(clut)
//						{
//							[clutArray addObject:[[content objectAtIndex:i] stringByDeletingPathExtension]];
//						}
//					}
//				}
//			}
//		}
//	}
//	
//	[clutArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
//	
//	NSMenuItem *item;
//	item = [[clutPopup menu] insertItemWithTitle:@"8-bit CLUTs" action:@selector(noAction:) keyEquivalent:@"" atIndex:3];
//	
//	if( [clutArray count])
//	{
//		[[clutPopup menu] insertItem:[NSMenuItem separatorItem] atIndex:[[clutPopup menu] numberOfItems]-2];
//		
//		item = [[clutPopup menu] insertItemWithTitle:@"16-bit CLUTs" action:@selector(noAction:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
//		
//		for (NSUInteger i=0; i<[clutArray count]; i++)
//		{
//			item = [[clutPopup menu] insertItemWithTitle:[clutArray objectAtIndex:i] action:@selector(loadAdvancedCLUTOpacity:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
//			if([mprView1.vrView isRGB])
//				[item setEnabled:NO];
//		}
//	}
//	
//    item = [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"16-bit CLUT Editor", nil) action:@selector(showCLUTOpacityPanel:) keyEquivalent:@""];
//	if([[pixList[ 0] objectAtIndex:0] isRGB])
//		[item setEnabled:NO];
}

-(void) ApplyCLUTString:(NSString*) str
{
	NSString	*previousColorName = [NSString stringWithString: curCLUTMenu];
	
	if( str == nil) return;
		
	[OpacityPopup setEnabled:YES];
	
	[self ApplyOpacityString:curOpacityMenu];
	
	if( [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str] == nil)
		str = @"No CLUT";
	
	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
	
	if( clippingRangeMode == 0) //VR
	{
		[mprView1 setCLUT: nil :nil :nil];
		[mprView2 setCLUT: nil :nil :nil];
		[mprView3 setCLUT: nil :nil :nil];
		
		[mprView1 setIndex:[mprView1 curImage]];
		[mprView2 setIndex:[mprView2 curImage]];
		[mprView3 setIndex:[mprView3 curImage]];
	}
	
	if([str isEqualToString:NSLocalizedString(@"No CLUT", nil)])
	{
		if(clippingRangeMode==0)
		{
			[mprView1.vrView setCLUT: nil :nil :nil];
		}
		else
		{
			[mprView1 setCLUT: nil :nil :nil];
			[mprView2 setCLUT: nil :nil :nil];
			[mprView3 setCLUT: nil :nil :nil];
			
			[mprView1 setIndex:[mprView1 curImage]];
			[mprView2 setIndex:[mprView2 curImage]];
			[mprView3 setIndex:[mprView3 curImage]];
			
			if( str != curCLUTMenu)
			{
				[curCLUTMenu release];
				curCLUTMenu = [str retain];
			}					
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: nil];
		
		[[[clutPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		NSDictionary *aCLUT;
		NSArray *array;
		long i;
		unsigned char red[256], green[256], blue[256];
		
		aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str];
		if( aCLUT)
		{
			array = [aCLUT objectForKey:@"Red"];
			for( i = 0; i < 256; i++)
			{
				red[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Green"];
			for( i = 0; i < 256; i++)
			{
				green[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Blue"];
			for( i = 0; i < 256; i++)
			{
				blue[i] = [[array objectAtIndex: i] longValue];
			}
			
			if(clippingRangeMode==0)
			{
				[mprView1.vrView setCLUT:red :green: blue];

				[mprView1 restoreCamera];
				mprView1.camera.forceUpdate = YES;
				[mprView1 updateViewMPR];
				
				[mprView2 restoreCamera];
				mprView2.camera.forceUpdate = YES;
				[mprView2 updateViewMPR];
				
				[mprView3 restoreCamera];
				mprView3.camera.forceUpdate = YES;
				[mprView3 updateViewMPR];
			}
			else
			{
				[mprView1 setCLUT:red :green: blue];
				[mprView2 setCLUT:red :green: blue];
				[mprView3 setCLUT:red :green: blue];
				
				[mprView1 setIndex:[mprView1 curImage]];
				[mprView2 setIndex:[mprView2 curImage]];
				[mprView3 setIndex:[mprView3 curImage]];
				
				if( str != curCLUTMenu)
				{
					[curCLUTMenu release];
					curCLUTMenu = [str retain];
				}
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: nil];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle: curCLUTMenu];
		}
	}
}

#pragma mark Opacity

-(void) UpdateOpacityMenu: (NSNotification*) note
{
    //*** Build the menu
    NSUInteger  i;
    NSArray     *keys;
    NSArray     *sortedKeys;
	
    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    i = [[OpacityPopup menu] numberOfItems];
    while(i-- > 0) [[OpacityPopup menu] removeItemAtIndex:0];
	
    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
	[[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[OpacityPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyOpacity:) keyEquivalent:@""];
    }
//    [[OpacityPopup menu] addItem: [NSMenuItem separatorItem]];
//    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Add an Opacity Table", nil) action:@selector (AddOpacity:) keyEquivalent:@""];
	
	[[[OpacityPopup menu] itemAtIndex:0] setTitle:curOpacityMenu];
}

- (void) OpacityChanged: (NSNotification*) note
{
	[hiddenVRView setOpacity: [[note object] getPoints]];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];	
}

- (void)ApplyOpacityString:(NSString*)str
{
	if( clippingRangeMode == 1 || clippingRangeMode == 3)
	{
		[self Apply2DOpacityString:str];
	}
	else
	{
		[self Apply3DOpacityString:str];
	}
}

- (void)Apply3DOpacityString:(NSString*)str;
{
	NSDictionary *aOpacity;
	NSArray *array;
	
	if( str == nil) return;
	
	if( curOpacityMenu != str)
	{
		[curOpacityMenu release];
		curOpacityMenu = [str retain];
	}
	
	if( [str isEqualToString:@"Linear Table"])
	{
		[mprView1.vrView setOpacity:[NSArray array]];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if( aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			[mprView1.vrView setOpacity:array];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle: curOpacityMenu];
		}
	}
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];	
}

- (void)Apply2DOpacityString:(NSString*)str;
{
	NSDictionary *aOpacity;
	NSArray *array;
	
	if( [str isEqualToString:NSLocalizedString(@"Linear Table", nil)])
	{
		//[thickSlab setOpacity:[NSArray array]];
		
		if( curOpacityMenu != str)
		{
			[curOpacityMenu release];
			curOpacityMenu = [str retain];
		}
		
		//lastMenuNotification = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
		
		[[mprView1 pix] setTransferFunction:nil];
		[[mprView2 pix] setTransferFunction:nil];
		[[mprView3 pix] setTransferFunction:nil];
		
		[mprView1 setIndex:[mprView1 curImage]];
		[mprView2 setIndex:[mprView2 curImage]];
		[mprView3 setIndex:[mprView3 curImage]];
		
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if (aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			//[thickSlab setOpacity:array];
			if( curOpacityMenu != str)
			{
				[curOpacityMenu release];
				curOpacityMenu = [str retain];
			}
			
			//lastMenuNotification = nil;
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
			
			NSData	*table = [OpacityTransferView tableWith4096Entries: [aOpacity objectForKey:@"Points"]];
			
			[[mprView1 pix] setTransferFunction: table];
			[[mprView2 pix] setTransferFunction: table];
			[[mprView3 pix] setTransferFunction: table];
		}
		
		[mprView1 setIndex:[mprView1 curImage]];
		[mprView2 setIndex:[mprView2 curImage]];
		[mprView3 setIndex:[mprView3 curImage]];
		
	}
}

#pragma mark GUI ObjectController - Cocoa Bindings

- (float) getClippingRangeThicknessInMm
{
	return [mprView1.vrView getClippingRangeThicknessInMm];
}

- (void) setClippingRangeThickness:(float) f
{
	clippingRangeThickness = f;
	
	if( clippingRangeThickness <= 1)
		hiddenVRView.lowResLODFactor = 1.0;
	else
	{
		if( MPProcessors() >= 4)
			hiddenVRView.lowResLODFactor = 1.5;
		else
			hiddenVRView.lowResLODFactor = 2.5;
	}
	
	[mprView1 restoreCamera];
	mprView1.vrView.dontResetImage = YES;
	[mprView1.vrView setClippingRangeThickness: f];
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.vrView.dontResetImage = YES;
	[mprView2.vrView setClippingRangeThickness: f];
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.vrView.dontResetImage = YES;
	[mprView3.vrView setClippingRangeThickness: f];
	[mprView3 updateViewMPR];
	
	[self willChangeValueForKey:@"clippingRangeThicknessInMm"];
	[self didChangeValueForKey:@"clippingRangeThicknessInMm"];
}

- (void) setClippingRangeMode:(int) f
{
	float pWL, pWW;
	float bpWL, bpWW;
	
	if( clippingRangeMode == 1 || clippingRangeMode == 3)		// MIP
	{
		[mprView1 getWLWW: &pWL :&pWW];
		[blendedMprView1 getWLWW: &bpWL :&bpWW];
	}
	else
	{
		[mprView1.vrView getWLWW: &pWL :&pWW];
		[mprView1.vrView getBlendingWLWW: &bpWL :&bpWW];
	}
	
	clippingRangeMode = f;
	
	[mprView1.vrView setMode: clippingRangeMode];
	[mprView2.vrView setMode: clippingRangeMode];
	[mprView3.vrView setMode: clippingRangeMode];

	[mprView1.vrView setBlendingMode: clippingRangeMode];
	[mprView2.vrView setBlendingMode: clippingRangeMode];
	[mprView3.vrView setBlendingMode: clippingRangeMode];

	if( clippingRangeMode == 1 || clippingRangeMode == 3)	// MIP - Mean
	{		
		[mprView1.vrView prepareFullDepthCapture];
		[mprView2.vrView prepareFullDepthCapture];
		[mprView3.vrView prepareFullDepthCapture];
		
		// switch linear opacity table
		[curOpacityMenu release];
		curOpacityMenu = [startingOpacityMenu retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateOpacityMenu:) name:@"UpdateOpacityMenu" object:nil];
	}
	else
	{
		// VR mode
		
		[mprView1.vrView restoreFullDepthCapture];
		[mprView2.vrView restoreFullDepthCapture];
		[mprView3.vrView restoreFullDepthCapture];
		
		[mprView1 setWLWW:128 :256];
		[mprView2 setWLWW:128 :256];
		[mprView3 setWLWW:128 :256];
		
		[blendedMprView1 setWLWW:128 :256];
		[blendedMprView2 setWLWW:128 :256];
		[blendedMprView3 setWLWW:128 :256];
		
		// switch log inverse table
		[curOpacityMenu release];
		curOpacityMenu = [NSLocalizedString(@"Logarithmic Inverse Table", nil) retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateOpacityMenu:) name:@"UpdateOpacityMenu" object:nil];
	}
	[self ApplyCLUTString:curCLUTMenu];
	[self ApplyOpacityString:curOpacityMenu];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3)
	{
		[mprView1 setWLWW: pWL :pWW];
		[blendedMprView1 setWLWW: bpWL :bpWW];
	}
	else
	{
		[mprView1.vrView setWLWW: pWL :pWW];
		[mprView1.vrView setBlendingWLWW: bpWL :bpWW];
	}
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3)
	{
		[mprView2 setWLWW: pWL :pWW];
		[blendedMprView2 setWLWW: bpWL :bpWW];
	}
	else
	{
		[mprView2.vrView setWLWW: pWL :pWW];
		[mprView2.vrView setBlendingWLWW: bpWL :bpWW];
	}
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3)
	{
		[mprView3 setWLWW: pWL :pWW];
		[blendedMprView3 setWLWW: bpWL :bpWW];
	}
	else
	{
		[mprView3.vrView setWLWW: pWL :pWW];
		[mprView3.vrView setBlendingWLWW: bpWL :bpWW];
	}
	[mprView3 updateViewMPR];
}

#pragma mark Export	

- (void) setDcmBatchReverse: (BOOL) v
{
	dcmBatchReverse = v;
	
	[self willChangeValueForKey: @"dcmFromString"];
	[self didChangeValueForKey: @"dcmFromString"];
	
	[self willChangeValueForKey: @"dcmToString"];
	[self didChangeValueForKey: @"dcmToString"];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
}

- (NSString*) getDcmFromString
{
	if( dcmBatchReverse) return NSLocalizedString(@"To:", nil);
	else return NSLocalizedString(@"From:", nil);
}

- (NSString*) getDcmToString
{
	if( dcmBatchReverse) return NSLocalizedString(@"From:", nil);
	else return NSLocalizedString(@"To:", nil);
}

- (MPRDCMView*) selectedView
{
	MPRDCMView *v = nil;
	
	if( [[self window] firstResponder] == mprView1)
		v = mprView1;
	if( [[self window] firstResponder] == mprView2)
		v = mprView2;
	if( [[self window] firstResponder] == mprView3)
		v = mprView3;
	
	if( v == nil) v = mprView3;
	
	return v;
}

-(IBAction) endDCMExportSettings:(id) sender
{
	[dcmWindow makeFirstResponder: nil];	// To force nstextfield validation.
	
	if( quicktimeExportMode)
	{
		[quicktimeWindow orderOut: sender];
		[NSApp endSheet: quicktimeWindow returnCode: [sender tag]];
		
		qtFileArray = [[NSMutableArray alloc] initWithCapacity: 0];
	}
	else
	{
		[dcmWindow orderOut: sender];
		[NSApp endSheet: dcmWindow returnCode: [sender tag]];
	}
	
	Camera *c1, *c2, *c3;
	int savedIndex = self.curMovieIndex;
	
	c1 = [[[mprView1 camera] copy] autorelease];
	c2 = [[[mprView2 camera] copy] autorelease];
	c3 = [[[mprView3 camera] copy] autorelease];
	
	mprView1.viewExport = mprView2.viewExport = mprView3.viewExport = -1;
	
	if( [sender tag])
	{
		NSMutableArray *producedFiles = [NSMutableArray array];
		
		[curExportView restoreCamera];
		curExportView.vrView.bestRenderingMode = NO;	// We will manually adapt the rendering level with setLOD
		
		if( quicktimeExportMode)
		{
			self.dcmFormat = 0; //RGB Capture
		}
		
		if( self.dcmQuality == 1)
			[curExportView.vrView setLOD: 1.0];
		
		if( self.dcmFormat) 
			[curExportView.vrView setViewSizeToMatrix3DExport];
		
		if( curExportView.vrView.exportDCM == nil)
			curExportView.vrView.exportDCM = [[[DICOMExport alloc] init] autorelease];

		curExportView.vrView.dcmSeriesString = self.dcmSeriesName;
		
		[curExportView.vrView.exportDCM setSeriesDescription: self.dcmSeriesName];
		[curExportView.vrView.exportDCM setSeriesNumber: 9983];
		
		int resizeImage = 0;
		
		switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"EXPORTMATRIXFOR3D"])
		{
			case 1: resizeImage = 512; break;
			case 2: resizeImage = 768; break;
		}
		
		// CURRENT image only
		if( dcmMode == 1)
		{
			if( self.dcmFormat) 
				[producedFiles addObject: [curExportView.vrView exportDCMCurrentImage]];
			else
				[producedFiles addObject: [curExportView exportDCMCurrentImage: curExportView.vrView.exportDCM size: resizeImage]];
		}
		// 4th dimension
		else if( dcmMode == 2)
		{
			Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating series", nil)];
			[progress showWindow: self];
			[[progress progress] setMaxValue: maxMovieIndex+1];
			
			curExportView.vrView.exportDCM = [[[DICOMExport alloc] init] autorelease];
			[curExportView.vrView.exportDCM setSeriesDescription: self.dcmSeriesName];
			[curExportView.vrView.exportDCM setSeriesNumber:8730 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
			
			for( int i = 0; i < maxMovieIndex+1; i++)
			{
				self.curMovieIndex = i;
				
				[curExportView restoreCamera];
				
				if( quicktimeExportMode)
				{
					[curExportView updateViewMPR: NO];
					[qtFileArray addObject: [curExportView exportNSImageCurrentImageWithSize: resizeImage]];
				}
				else
				{
					if( self.dcmFormat)
					{
						[curExportView.vrView setViewSizeToMatrix3DExport];
						[producedFiles addObject: [curExportView.vrView exportDCMCurrentImage]];
					}
					else
					{
						[curExportView updateViewMPR: NO];
						[producedFiles addObject: [curExportView exportDCMCurrentImage: curExportView.vrView.exportDCM size: resizeImage]];
					}
				}
				
				[progress incrementBy: 1];
				if( [progress aborted])
					break;
			}
			
			[progress close];
			[progress release];
		}
		else if( dcmMode == 0) // A 3D sequence or batch sequence
		{
			Wait *progress = [[Wait alloc] initWithString: @"Creating series"];
			[progress showWindow:self];
			[progress setCancel:YES];
			
			curExportView.vrView.exportDCM = [[[DICOMExport alloc] init] autorelease];
			[curExportView.vrView.exportDCM setSeriesDescription: self.dcmSeriesName];
			[curExportView.vrView.exportDCM setSeriesNumber:8930 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
			
			if( dcmSeriesMode == 1)
			{
				if( maxMovieIndex > 0)
				{
					self.dcmNumberOfFrames /= maxMovieIndex+1;
					self.dcmNumberOfFrames *= maxMovieIndex+1;
				}
				
				[[progress progress] setMaxValue: self.dcmNumberOfFrames];
				
				for( int i = 0; i < self.dcmNumberOfFrames; i++)
				{
					if( curExportView == mprView3)
					{
						switch( dcmRotationDirection)
						{
							case 0:
								mprView2.angleMPR += (float) dcmRotation / (float) self.dcmNumberOfFrames;
								
								[[self window] makeFirstResponder: mprView2];
								[mprView2 restoreCamera];
								[mprView2 updateViewMPR];
								break;
							case 1:
								mprView1.angleMPR += (float) dcmRotation / (float) self.dcmNumberOfFrames;
								
								[[self window] makeFirstResponder: mprView1];
								[mprView1 restoreCamera];
								[mprView1 updateViewMPR];
								break;
						}
					}
					
					if( curExportView == mprView2)
					{
						switch( dcmRotationDirection)
						{
							case 0:
								mprView3.angleMPR += (float) dcmRotation / (float) self.dcmNumberOfFrames;
								
								[[self window] makeFirstResponder: mprView3];
								[mprView3 restoreCamera];
								[mprView3 updateViewMPR];
								break;
							case 1:
								mprView1.angleMPR += (float) dcmRotation / (float) self.dcmNumberOfFrames;
								
								[[self window] makeFirstResponder: mprView1];
								[mprView1 restoreCamera];
								[mprView1 updateViewMPR];
								break;
						}
					}
					
					if( curExportView == mprView1)
					{
						switch( dcmRotationDirection)
						{
							case 0:
								mprView2.angleMPR += (float) dcmRotation / (float) self.dcmNumberOfFrames;
								
								[[self window] makeFirstResponder: mprView2];
								[mprView2 restoreCamera];
								[mprView2 updateViewMPR];
								break;
							case 1:
								mprView3.angleMPR += (float) dcmRotation / (float) self.dcmNumberOfFrames;
								
								[[self window] makeFirstResponder: mprView3];
								[mprView3 restoreCamera];
								[mprView3 updateViewMPR];
								break;
						}
					}
					
					if( quicktimeExportMode)
					{
						[curExportView updateViewMPR: NO];
						[qtFileArray addObject: [curExportView exportNSImageCurrentImageWithSize: resizeImage]];
					}
					else
					{
						if( self.dcmFormat)
							[producedFiles addObject: [curExportView.vrView exportDCMCurrentImage]];
						else
						{
							[curExportView updateViewMPR: NO];
							[producedFiles addObject: [curExportView exportDCMCurrentImage: curExportView.vrView.exportDCM size: resizeImage]];
						}
					}
					
					[progress incrementBy: 1];
					
					if( [progress aborted])
						break;
				}
			}
			else // A batch sequence
			{
				[[progress progress] setMaxValue: dcmBatchNumberOfFrames];
				
				float cos[ 9];
				float interval = dcmInterval * [curExportView.vrView factor];
				
				[curExportView.pix orientation: cos];
				
				if( dcmBatchReverse)
				{
					// Go to first position
					curExportView.camera.position = [Point3D pointWithX: curExportView.camera.position.x + interval*cos[ 6]*-dcmTo y:curExportView.camera.position.y + interval*cos[ 7]*-dcmTo z:curExportView.camera.position.z + interval*cos[ 8]*-dcmTo];
				}
				else
				{
					// Go to first position
					curExportView.camera.position = [Point3D pointWithX: curExportView.camera.position.x + interval*cos[ 6]*dcmFrom y:curExportView.camera.position.y + interval*cos[ 7]*dcmFrom z:curExportView.camera.position.z + interval*cos[ 8]*dcmFrom];
				}
				
				curExportView.camera.focalPoint = [Point3D pointWithX: curExportView.camera.position.x + cos[ 6] y:curExportView.camera.position.y + cos[ 7] z:curExportView.camera.position.z + cos[ 8]];
				
				[curExportView restoreCameraAndCheckForFrame: NO];
				
				if( self.dcmBatchNumberOfFrames < 1)
					self.dcmBatchNumberOfFrames = 1;
				
				for( int i = 0; i < self.dcmBatchNumberOfFrames; i++)
				{
					if( quicktimeExportMode)
					{
						[curExportView updateViewMPR: NO];
						[qtFileArray addObject: [curExportView exportNSImageCurrentImageWithSize: resizeImage]];
					}
					else
					{
						if( self.dcmFormat)
							[producedFiles addObject: [curExportView.vrView exportDCMCurrentImage]];
						else
						{
							[curExportView updateViewMPR: NO];
							[producedFiles addObject: [curExportView exportDCMCurrentImage: curExportView.vrView.exportDCM size: resizeImage]];
						}
					}
					
					if( dcmBatchReverse)
						curExportView.camera.position = [Point3D pointWithX: curExportView.camera.position.x + interval*cos[ 6] y:curExportView.camera.position.y + interval*cos[ 7] z:curExportView.camera.position.z + interval*cos[ 8]];
					else
						curExportView.camera.position = [Point3D pointWithX: curExportView.camera.position.x - interval*cos[ 6] y:curExportView.camera.position.y - interval*cos[ 7] z:curExportView.camera.position.z - interval*cos[ 8]];
					curExportView.camera.focalPoint = [Point3D pointWithX: curExportView.camera.position.x + cos[ 6] y:curExportView.camera.position.y + cos[ 7] z:curExportView.camera.position.z + cos[ 8]];
					
					[curExportView restoreCameraAndCheckForFrame: NO];
					
					[progress incrementBy: 1];
					
					if( [progress aborted])
						break;
				}
			}
			
			[curExportView.vrView endRenderImageWithBestQuality];
			
			[progress close];
			[progress release];
		}
		
		if( quicktimeExportMode == NO)
		{
			if( ([[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"] || [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"]) && [producedFiles count])
			{
				[NSThread sleepForTimeInterval: 0.5];
				[[BrowserController currentBrowser] checkIncomingNow: self];
				
				NSMutableArray *imagesForThisStudy = [NSMutableArray array];
				
				[[[BrowserController currentBrowser] managedObjectContext] lock];
				
				for( NSManagedObject *s in [[[viewer2D currentStudy] valueForKey: @"series"] allObjects])
					[imagesForThisStudy addObjectsFromArray: [[s valueForKey: @"images"] allObjects]];
				
				[[[BrowserController currentBrowser] managedObjectContext] unlock];
				
				NSArray *sopArray = [producedFiles valueForKey: @"SOPInstanceUID"];
				
				NSMutableArray *objects = [NSMutableArray array];
				for( NSString *sop in sopArray)
				{
					for( DicomImage *im in imagesForThisStudy)
					{
						if( [[im sopInstanceUID] isEqualToString: sop])
							[objects addObject: im];
					}
				}
				
				if( [objects count] != [producedFiles count])
					NSLog( @"WARNING !! [objects count] != [producedFiles count]");
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"])
					[[BrowserController currentBrowser] selectServer: objects];
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"])
				{
					for( DicomImage *im in objects)
						[im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
				}
			}
		}
		else
		{
			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :[qtFileArray count]];
			[mov createMovieQTKit: YES  :NO :[[filesList[0] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];			
			[mov release];
		}
		
		if( self.dcmFormat) 
			[curExportView.vrView restoreViewSizeAfterMatrix3DExport];
		
		[curExportView.vrView setLOD: LOD];
		
		[[NSUserDefaults standardUserDefaults] setInteger: dcmMode forKey: @"lastMPRdcmExportMode"];
		
		if( dcmMode == 2)
			self.curMovieIndex = savedIndex;
		
		mprView1.camera = c1;
		mprView2.camera = c2;
		mprView3.camera = c3;
		
		[self updateViewsAccordingToFrame: nil];
	}
	
	[qtFileArray release];
	qtFileArray = nil;
	quicktimeExportMode = NO;
}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	return [qtFileArray objectAtIndex: [cur intValue]];
}

- (void) exportDICOMFile:(id) sender
{
	if( [quicktimeWindow isVisible])
		return;
	if( [dcmWindow isVisible])
		return;
	
	curExportView = [self selectedView];
	
	if( quicktimeExportMode)
		[NSApp beginSheet: quicktimeWindow modalForWindow: nil modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
	else
		[NSApp beginSheet: dcmWindow modalForWindow: nil modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
	
	if( [self selectedView] != mprView1) mprView1.displayCrossLines = YES;
	if( [self selectedView] != mprView2) mprView2.displayCrossLines = YES;
	if( [self selectedView] != mprView3) mprView3.displayCrossLines = YES;
	
	self.dcmSameIntervalAndThickness = YES;
	self.dcmQuality = 1;
	
	if( clippingRangeMode == 0) // VR
		self.dcmFormat = 0; //SC in 8-bit
	else
		self.dcmFormat = 1; // full depth
	
	self.dcmMode = [[NSUserDefaults standardUserDefaults] integerForKey: @"lastMPRdcmExportMode"];
	if( [self getMovieDataAvailable] == NO && self.dcmMode == 2)
		self.dcmMode = 0;
}

- (void) exportQuicktime:(id) sender
{
	if( [quicktimeWindow isVisible])
		return;
	if( [dcmWindow isVisible])
		return;
		
	quicktimeExportMode = YES;
	[self exportDICOMFile: sender];
}

- (void) displayFromToSlices
{
	mprView1.viewExport = mprView2.viewExport = mprView3.viewExport = -1;
	
	if( curExportView == mprView3)
	{
		if( dcmSeriesMode == 0) // Batch
		{
			mprView1.toIntervalExport = dcmTo;
			mprView1.fromIntervalExport = dcmFrom;
			mprView1.viewExport = 1;
			
			mprView2.toIntervalExport = dcmTo;
			mprView2.fromIntervalExport = dcmFrom;
			mprView2.viewExport = 1;
		}
		else // Rotation
		{
			if( dcmRotationDirection == 1)
				mprView1.viewExport = 1;
			else
				mprView2.viewExport = 1;
		}
	}
	
	if( curExportView == mprView2)
	{
		if( dcmSeriesMode == 0) // Batch
		{
			mprView1.toIntervalExport = dcmTo;
			mprView1.fromIntervalExport = dcmFrom;
			mprView1.viewExport = 0;
			
			mprView3.toIntervalExport = dcmTo;
			mprView3.fromIntervalExport = dcmFrom;
			mprView3.viewExport = 1;
		}
		else // Rotation
		{
			if( dcmRotationDirection == 1)
				mprView1.viewExport = 0;
			else
				mprView3.viewExport = 1;
		}
	}
	
	if( curExportView == mprView1)
	{
		if( dcmSeriesMode == 0) // Batch
		{
			mprView2.toIntervalExport = dcmTo;
			mprView2.fromIntervalExport = dcmFrom;
			mprView2.viewExport = 0;
			
			mprView3.toIntervalExport = dcmTo;
			mprView3.fromIntervalExport = dcmFrom;
			mprView3.viewExport = 0;
		}
		else // Rotation
		{
			if( dcmRotationDirection == 1)
				mprView3.viewExport = 0;
			else
				mprView2.viewExport = 0;
		}
	}
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
	
	self.dcmBatchNumberOfFrames = 1 + dcmTo + dcmFrom;
}

- (void) setDcmSeriesMode: (int) f
{
	dcmSeriesMode = f;
	
	[self displayFromToSlices];
}

- (void) setDcmMode: (int) f
{
	dcmMode = f;
	
	[self displayFromToSlices];
}

- (void) setDcmInterval:(float) f
{
	dcmInterval = f;
	
	if( previousDcmInterval)
	{
		self.dcmTo =  round(( (float) dcmTo * previousDcmInterval) /  dcmInterval);
		self.dcmFrom = round(( (float) dcmFrom * previousDcmInterval) / dcmInterval);
	}
	
	previousDcmInterval = f;
	
	[self displayFromToSlices];
}

- (void) setDcmRotation:(int) v
{
	dcmRotation = v;
	[self displayFromToSlices];
}

- (void) setDcmRotationDirection:(int) v
{
	dcmRotationDirection = v;
	[self displayFromToSlices];
}

- (void) setDcmNumberOfFrames:(int) v
{
	dcmNumberOfFrames = v;
	[self displayFromToSlices];
}

- (void) setDcmTo:(int) f
{
	dcmTo = f;
	[self displayFromToSlices];
}

- (void) setDcmFrom:(int) f
{
	dcmFrom = f;
	[self displayFromToSlices];
}

- (void) setDcmSameIntervalAndThickness: (BOOL) f
{
	dcmSameIntervalAndThickness = f;
	
	if( dcmSameIntervalAndThickness)
		self.dcmInterval = [curExportView.vrView getClippingRangeThicknessInMm];
}

-(void) sendMail:(id) sender
{
	NSImage *im = [[self selectedView] nsimage:NO];
	
	[self sendMailImage: im];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:nil file:@"3D VR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [[self selectedView] nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

-(void) export2iPhoto:(id) sender
{
	iPhoto		*ifoto;
	NSImage		*im = [[self selectedView] nsimage:NO];
	
	NSArray		*representations;
	NSData		*bitmapData;
	
	representations = [im representations];
	
	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
	[bitmapData writeToFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
	
	ifoto = [[iPhoto alloc] init];
	[ifoto importIniPhoto: [NSArray arrayWithObject:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
	[ifoto release];
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"tif"];
	
	if( [panel runModalForDirectory:nil file:@"3D MPR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [[self selectedView] nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

#pragma mark NSWindow Notifications action

- (ViewerController*) viewer
{
	return viewer2D;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
		windowWillClose = YES;
		
		[[NSUserDefaults standardUserDefaults] setBool: self.displayMousePosition forKey: @"MPRDisplayMousePosition"];
	
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector( updateViewsAccordingToFrame:) object: nil];
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector( delayedFullLODRendering:) object: nil];
		
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"Window3DClose" object: self userInfo: 0];
		
		if( movieTimer)
		{
			[movieTimer invalidate];
			[movieTimer release];
			movieTimer = nil;
		}
		
		[hiddenVRController close];
		[hiddenVRController release];
		
		[ob setContent: nil];	// To allow the dealloc of MPRController ! otherwise memory leak
		
		[self release];
	}
}

#pragma mark Shadings

- (IBAction)switchShading:(id)sender;
{
	[hiddenVRView switchShading:sender];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];
	
}

- (IBAction)applyShading:(id)sender;
{
	NSDictionary *dict = [[shadingsPresetsController selectedObjects] lastObject];
	
	float ambient, diffuse, specular, specularpower;
	
	ambient = [[dict valueForKey:@"ambient"] floatValue];
	diffuse = [[dict valueForKey:@"diffuse"] floatValue];
	specular = [[dict valueForKey:@"specular"] floatValue];
	specularpower = [[dict valueForKey:@"specularPower"] floatValue];
	
	float sambient, sdiffuse, sspecular, sspecularpower;	
	[hiddenVRView getShadingValues: &sambient :&sdiffuse :&sspecular :&sspecularpower];
	
	if( sambient != ambient || sdiffuse != diffuse || sspecular != specular || sspecularpower != specularpower)
	{
		[hiddenVRView setShadingValues: ambient :diffuse :specular :specularpower];
		[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.2f\nDiffuse: %2.2f\nSpecular :%2.2f, %2.2f", ambient, diffuse, specular, specularpower]];

		[mprView1 restoreCamera];
		mprView1.camera.forceUpdate = YES;
		[mprView1 updateViewMPR];
		
		[mprView2 restoreCamera];
		mprView2.camera.forceUpdate = YES;
		[mprView2 updateViewMPR];
		
		[mprView3 restoreCamera];
		mprView3.camera.forceUpdate = YES;
		[mprView3 updateViewMPR];		
	}
}

- (void)findShadingPreset:(id)sender;
{
	float ambient, diffuse, specular, specularpower;
	
	[hiddenVRView getShadingValues: &ambient :&diffuse :&specular :&specularpower];
	
	NSArray *shadings = [shadingsPresetsController arrangedObjects];
	int i;
	for( i = 0; i < [shadings count]; i++)
	{
		NSDictionary *dict = [shadings objectAtIndex: i];
		if( ambient == [[dict valueForKey:@"ambient"] floatValue] && diffuse == [[dict valueForKey:@"diffuse"] floatValue] && specular == [[dict valueForKey:@"specular"] floatValue] && specularpower == [[dict valueForKey:@"specularPower"] floatValue])
		{
			[shadingsPresetsController setSelectedObjects: [NSArray arrayWithObject: dict]];
			break;
		}
	}
}

- (IBAction)editShadingValues:(id)sender;
{
	[shadingPanel makeKeyAndOrderFront: self];
	[self findShadingPreset: self];
}

#pragma mark Toolbar

- (void) setupToolbar
{
	toolbar = [[NSToolbar alloc] initWithIdentifier: @"3DMPR Toolbar Identifier"];
    
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    
    [toolbar setDelegate: self];
    
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton: NO];
	[[[self window] toolbar] setVisible: YES];
}

- (void) windowDidLoad
{
	[self setupToolbar];
}

- (IBAction)customizeViewerToolBar:(id)sender
{
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
	if ([itemIdent isEqualToString: @"tbLOD"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"LOD",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"LOD",nil)];
		
		[toolbarItem setView: tbLOD];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbLOD frame]), NSHeight([tbLOD frame]))];
    }
	else if ([itemIdent isEqualToString: @"Reset.tiff"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Reset",nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"Reset.tiff"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( showWindow:)];
    }
	else if ([itemIdent isEqualToString: @"Export.icns"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"DICOM",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"DICOM",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Export this image in a DICOM file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"Export.icns"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( exportDICOMFile:)];
    }
	else if ([itemIdent isEqualToString: @"Capture.icns"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Best",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Best",nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"Capture.icns"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( bestRendering:)];
    }
	else if ([itemIdent isEqualToString: @"QTExport.icns"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Movie Export",nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"QTExport.icns"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( exportQuicktime:)];
    }
	else if ([itemIdent isEqualToString: @"tbBlending"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Fusion",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
		
		[toolbarItem setView: tbBlending];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbBlending frame]), NSHeight([tbBlending frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbThickSlab"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Thick Slab",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Thick Slab",nil)];
		
		[toolbarItem setView: tbThickSlab];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbThickSlab frame]), NSHeight([tbThickSlab frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbWLWW"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"WL & WW",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"WL & WW",nil)];
		
		[toolbarItem setView: tbWLWW];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbWLWW frame]), NSHeight([tbWLWW frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbTools"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Tools",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Tools",nil)];
		
		[toolbarItem setView: tbTools];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbTools frame]), NSHeight([tbTools frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbMovie"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"4D Player",nil)];
		
		[toolbarItem setView: tbMovie];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbMovie frame]), NSHeight([tbMovie frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbShading"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Shadings",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Shadings",nil)];
		
		[toolbarItem setView: tbShading];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbShading frame]), NSHeight([tbShading frame]))];
    }
	else if ([itemIdent isEqualToString:@"AxisColors"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Axis Colors",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Axis Colors",nil)];
		[toolbarItem setView: tbAxisColors];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbAxisColors frame]), NSHeight([tbAxisColors frame]))];
    }
	else if ([itemIdent isEqualToString:@"AxisShowHide"])
	{
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Axis",nil)];
		
		[toolbarItem setLabel:NSLocalizedString(@"Axis",nil)];
		if( ![self selectedView].displayCrossLines)
			[toolbarItem setImage:[NSImage imageNamed:@"MPRAxisHide"]];
		else
			[toolbarItem setImage:[NSImage imageNamed:@"MPRAxisShow"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(toogleAxisVisibility:)];
    }
	else if ([itemIdent isEqualToString:@"MousePositionShowHide"])
	{
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Mouse Position",nil)];
		
		[toolbarItem setLabel:NSLocalizedString(@"Mouse Position",nil)];
		if( !self.displayMousePosition)
			[toolbarItem setImage:[NSImage imageNamed:@"MPRMousePositionHide"]];
		else
			[toolbarItem setImage:[NSImage imageNamed:@"MPRMousePositionShow"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(toogleMousePositionVisibility:)];
    }
	else if ([itemIdent isEqualToString: @"syncZoomLevel"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Sync Zoom",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Sync Zoom",nil)];
		
		[toolbarItem setView: tbSyncZoomLevel];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbSyncZoomLevel frame]), NSHeight([tbSyncZoomLevel frame]))];
    }
	else
	{
		[toolbarItem release];
		toolbarItem = nil;
	}
	
	return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
		return [NSArray arrayWithObjects: @"tbTools", @"tbWLWW", @"tbLOD", @"tbThickSlab", @"tbShading", NSToolbarFlexibleSpaceItemIdentifier, @"Reset.tiff", @"Export.icns", @"Capture.icns", @"QTExport.icns", @"AxisShowHide", @"MousePositionShowHide", @"syncZoomLevel", nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
		return [NSArray arrayWithObjects: NSToolbarCustomizeToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											@"tbTools", @"tbWLWW", @"tbLOD", @"tbThickSlab", @"tbBlending", @"tbShading", @"Reset.tiff", @"Export.icns", @"Capture.icns", @"QTExport.icns", @"tbTools", @"AxisColors", @"AxisShowHide", @"MousePositionShowHide", @"syncZoomLevel", nil];
}

- (void)updateToolbarItems;
{
	NSArray *toolbarItems = [toolbar items];
	for(NSToolbarItem *item in toolbarItems)
	{
		if([[item itemIdentifier] isEqualToString:@"AxisShowHide"])
		{
			if( ![self selectedView].displayCrossLines)
				[item setImage:[NSImage imageNamed:@"MPRAxisHide"]];
			else
				[item setImage:[NSImage imageNamed:@"MPRAxisShow"]];
		}
		else if([[item itemIdentifier] isEqualToString:@"MousePositionShowHide"])
		{
			if( !self.displayMousePosition)
				[item setImage:[NSImage imageNamed:@"MPRMousePositionHide"]];
			else
				[item setImage:[NSImage imageNamed:@"MPRMousePositionShow"]];
		}
		
	}
}

#pragma mark Axis / Mouse Position : Show / Hide

- (void)toogleAxisVisibility:(id) sender;
{
	[self selectedView].displayCrossLines = ![self selectedView].displayCrossLines;
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
	
	[self updateToolbarItems];
}

- (void)toogleMousePositionVisibility:(id) sender;
{
	self.displayMousePosition = !self.displayMousePosition;
	
	if( self.displayMousePosition && ![self selectedView].displayCrossLines)
		[self selectedView].displayCrossLines = YES;
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
	
	[self updateToolbarItems];
}

#pragma mark Blending

- (void) changeWLWW: (NSNotification*) note
{
	DCMPix	*otherPix = [note object];
	
	if( [[fusedViewer2D pixList] containsObject: otherPix])
	{
		float iwl, iww;
		
		iww = [otherPix ww];
		iwl = [otherPix wl];
		
		if( iww != [[blendedMprView1 curDCM] ww] || iwl != [[blendedMprView1 curDCM] wl])
		{
			if( clippingRangeMode == 0)
			{
				[blendedMprView1 setWLWW:128 :256];
				[blendedMprView2 setWLWW:128 :256];
				[blendedMprView3 setWLWW:128 :256];
				
				[mprView1.vrView setBlendingWLWW: iwl :iww];
				[mprView2.vrView setBlendingWLWW: iwl :iww];
				[mprView3.vrView setBlendingWLWW: iwl :iww];
				
				[mprView1 restoreCamera];
				mprView1.camera.forceUpdate = YES;
				[mprView1 updateViewMPR];
				
				[mprView2 restoreCamera];
				mprView2.camera.forceUpdate = YES;
				[mprView2 updateViewMPR];
				
				[mprView3 restoreCamera];
				mprView3.camera.forceUpdate = YES;
				[mprView3 updateViewMPR];
			}
			else
			{
				[blendedMprView1 setWLWW: iwl :iww];
				[blendedMprView2 setWLWW: iwl :iww];
				[blendedMprView3 setWLWW: iwl :iww];
			}
			
			[mprView1 updateImage];
			[mprView2 updateImage];
			[mprView3 updateImage];
		}
	}
}

- (void) setBlendingMode: (int) m
{
	blendingMode = m;
	
	[mprView1 setBlendingMode: m];
	[mprView2 setBlendingMode: m];
	[mprView3 setBlendingMode: m];
}

- (void) setBlendingPercentage: (float) f
{
	blendingPercentage = f;
	
	f -= 50.;
	f /= 50.;
	f *= 256.;
	
	[mprView1 setBlendingFactor: f];
	[mprView2 setBlendingFactor: f];
	[mprView3 setBlendingFactor: f];
}

#pragma mark 4D Data

- (BOOL) getMovieDataAvailable
{
	if( self.maxMovieIndex > 0) return YES;
	else return NO;
}

-(void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData
{
	pixList[ maxMovieIndex] = pix;
	volumeData[ maxMovieIndex] = vData;
	
	self.movieRate = 20;
	self.maxMovieIndex++;
	[moviePosSlider setNumberOfTickMarks: maxMovieIndex+1];
	
	[hiddenVRController addMoviePixList: pix :vData];	

	if( clippingRangeMode == 1 || clippingRangeMode == 3)
		[mprView1.vrView prepareFullDepthCapture];
	else
		[mprView1.vrView restoreFullDepthCapture];
	
	[self willChangeValueForKey: @"movieDataAvailable"];
	[self didChangeValueForKey: @"movieDataAvailable"];
}

- (void) setCurMovieIndex: (int) m
{
	curMovieIndex = m;
	
	mprView1.camera.movieIndexIn4D = m;
	mprView2.camera.movieIndexIn4D = m;
	mprView3.camera.movieIndexIn4D = m;
	
	[fusedViewer2D setMovieIndex: curMovieIndex];
	
	[hiddenVRController setMovieFrame: m];
	
	if( clippingRangeMode == 1 || clippingRangeMode == 3)
		[mprView1.vrView prepareFullDepthCapture];
	else
		[mprView1.vrView restoreFullDepthCapture];
	
	[self updateViewsAccordingToFrame: nil];
	
	[mprView1 mouseMoved: [[NSApplication sharedApplication] currentEvent]];
	[mprView2 mouseMoved: [[NSApplication sharedApplication] currentEvent]];
	[mprView3 mouseMoved: [[NSApplication sharedApplication] currentEvent]];
}

- (void) performMovieAnimation:(id) sender
{
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
    if( thisTime - lastMovieTime > 1.0 / self.movieRate)
    {
        val = self.curMovieIndex;
        val ++;
        
		if( val < 0) val = 0;
		if( val > self.maxMovieIndex) val = 0;
		
		self.curMovieIndex = val;
        lastMovieTime = thisTime;
    }
}

- (NSString*) playStopButtonString
{
	if( movieTimer)
		return @"Stop";
	else
		return @"Play";
}

- (void) moviePlayStop:(id) sender
{
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
    }
    else
    {
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector( performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
    
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
    }
	
	[self willChangeValueForKey: @"playStopButtonString"];
	[self didChangeValueForKey: @"playStopButtonString"];
}

#pragma mark Axis Colors

- (void)setColorAxis1:(NSColor*)color;
{
	[colorAxis1 release];
	colorAxis1 = [color retain];
	[mprView1 setNeedsDisplay:YES];
	[mprView2 setNeedsDisplay:YES];
	[mprView3 setNeedsDisplay:YES];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 redComponent] forKey:@"MPR_AXIS_1_RED"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 greenComponent] forKey:@"MPR_AXIS_1_GREEN"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 blueComponent] forKey:@"MPR_AXIS_1_BLUE"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 alphaComponent] forKey:@"MPR_AXIS_1_ALPHA"];
}

- (void)setColorAxis2:(NSColor*)color;
{
	[colorAxis2 release];
	colorAxis2 = [color retain];
	[mprView1 setNeedsDisplay:YES];
	[mprView2 setNeedsDisplay:YES];
	[mprView3 setNeedsDisplay:YES];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 redComponent] forKey:@"MPR_AXIS_2_RED"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 greenComponent] forKey:@"MPR_AXIS_2_GREEN"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 blueComponent] forKey:@"MPR_AXIS_2_BLUE"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 alphaComponent] forKey:@"MPR_AXIS_2_ALPHA"];
}

- (void)setColorAxis3:(NSColor*)color;
{
	[colorAxis3 release];
	colorAxis3 = [color retain];
	[mprView1 setNeedsDisplay:YES];
	[mprView2 setNeedsDisplay:YES];
	[mprView3 setNeedsDisplay:YES];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 redComponent] forKey:@"MPR_AXIS_3_RED"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 greenComponent] forKey:@"MPR_AXIS_3_GREEN"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 blueComponent] forKey:@"MPR_AXIS_3_BLUE"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 alphaComponent] forKey:@"MPR_AXIS_3_ALPHA"];
}

@end