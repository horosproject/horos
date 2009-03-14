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

#define PRESETS_DIRECTORY @"/3DPRESETS/"
#define CLUTDATABASE @"/CLUTs/"

extern short intersect3D_2Planes( float *Pn1, float *Pv1, float *Pn2, float *Pv2, float *u, float *iP);
static float deg2rad = 3.14159265358979/180.0; 

@implementation MPRController

@synthesize clippingRangeThickness, clippingRangeMode, mousePosition, mouseViewID, originalPix, wlwwMenuItems, LOD, dcmFrom, dcmTo, dcmMode, dcmRotationDirection, dcmSeriesMode, dcmSize, dcmRotation, dcmNumberOfFrames, dcmQuality, dcmInterval, dcmSeriesName;

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
	self = [super initWithWindowNibName:@"MPR"];
	
	//[shadingsPresetsController setWindowController: self];
	
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
	
	[[self window] setWindowController: self];
	
	DCMPix *emptyPix = [self emptyPix: originalPix width: 100 height: 100];
	[mprView1 setDCMPixList:  [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] volumeData: [NSData dataWithBytes: [emptyPix fImage] length: [emptyPix pheight] * [emptyPix pwidth] * sizeof( float)] roiList:nil firstImage:0 type:'i' reset:YES];
	[mprView1 setFlippedData: [[viewer imageView] flippedData]];
	
	emptyPix = [self emptyPix: originalPix width: 100 height: 100];
	[mprView2 setDCMPixList:  [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] volumeData: [NSData dataWithBytes: [emptyPix fImage] length: [emptyPix pheight] * [emptyPix pwidth] * sizeof( float)] roiList:nil firstImage:0 type:'i' reset:YES];
	[mprView2 setFlippedData: [[viewer imageView] flippedData]];
	
	emptyPix = [self emptyPix: originalPix width: 100 height: 100];
	[mprView3 setDCMPixList:  [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] volumeData: [NSData dataWithBytes: [emptyPix fImage] length: [emptyPix pheight] * [emptyPix pwidth] * sizeof( float)] roiList:nil firstImage:0 type:'i' reset:YES];
	[mprView3 setFlippedData: [[viewer imageView] flippedData]];
	
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
	[self setLOD: 1.5];
	hiddenVRView.keep3DRotateCentered = YES;
	
	[mprView1 setVRView: hiddenVRView viewID: 1];
	[mprView1 setWLWW: [originalPix wl] :[originalPix ww]];
	
	[mprView2 setVRView: hiddenVRView viewID: 2];
	[mprView2 setWLWW: [originalPix wl] :[originalPix ww]];
	
	[mprView3 setVRView: hiddenVRView viewID: 3];
	[mprView3 setWLWW: [originalPix wl] :[originalPix ww]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateWLWWMenu:) name:@"UpdateWLWWMenu" object:nil];
	curWLWWMenu = @"";
	[curWLWWMenu retain];
	[self UpdateWLWWMenu:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateCLUTMenu:) name:@"UpdateCLUTMenu" object: nil];
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	[self UpdateCLUTMenu:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:@"CloseViewerNotification" object:nil];
	
	[shadingCheck setAction:@selector(switchShading:)];
	[shadingCheck setTarget:hiddenVRView];

	
	return self;
}

- (void) updateViewsAccordingToFrame:(id) sender	// see setFrame in MPRDCMView.m
{
	[mprView1 camera].forceUpdate = YES;
	[mprView2 camera].forceUpdate = YES;
	[mprView3 camera].forceUpdate = YES;
	
	[[self window] makeFirstResponder: mprView3];
	[mprView3 restoreCamera];
	[mprView3 updateViewMPR];
}

- (void) showWindow:(id) sender
{
	// Default Init
	[self setClippingRangeMode: 1]; // MIP
	[self setClippingRangeThickness: 1];
	
	[[self window] makeFirstResponder: mprView1];
	[mprView1.vrView resetImage: self];
	[mprView1 updateViewMPR];
	
	mprView2.camera.viewUp = [Point3D pointWithX:0 y:-1 z:0];
	
	[[self window] makeFirstResponder: mprView3];
	[mprView3 restoreCamera];
	[mprView3 updateViewMPR];
	
	[super showWindow: sender];
}

-(void) awakeFromNib
{
	[shadingsPresetsController setWindowController: self];
	[shadingCheck setAction:@selector(switchShading:)];
	[shadingCheck setTarget:hiddenVRView];
}

- (void) dealloc
{
	[mousePosition release];
	[wlwwMenuItems release];
	
	[super dealloc];
	
	NSLog( @"dealloc MPRController");
}

- (BOOL) is2DViewer
{
	return NO;
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == viewer2D)
	{
		[self offFullScreen];
		[[self window] close];
	}
}

- (NSArray*) pixList
{
	return pixList[ curMovieIndex];
}

- (IBAction)setTool:(id)sender;
{
	NSLog(@"setTool");
	int toolIndex;
	
	if([sender isKindOfClass:[NSMatrix class]])
		toolIndex = [[sender selectedCell] tag];
	else if([sender respondsToSelector:@selector(tag)])
		toolIndex = [sender tag];
	
	NSLog(@"toolIndex : %d", toolIndex);
		
	[mprView1 setCurrentTool:toolIndex];
	[mprView2 setCurrentTool:toolIndex];
	[mprView3 setCurrentTool:toolIndex];
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
}

- (void) computeCrossReferenceLines:(MPRDCMView*) sender
{
	float a[2][3];
	float b[2][3];
	
	if( sender)
	{
		if( sender != mprView1) mprView1.camera.parallelScale = sender.camera.parallelScale;
		if( sender != mprView2) mprView2.camera.parallelScale = sender.camera.parallelScale;
		if( sender != mprView3) mprView3.camera.parallelScale = sender.camera.parallelScale;
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

- (void)bringToFrontROI:(ROI*) roi;
{}
#pragma mark 

- (void)setLOD:(float)lod;
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

    [tmp addObject:[NSMenuItem separatorItem]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector(AddCurrentWLWW:) keyEquivalent:@""] autorelease]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector(SetWLWW:) keyEquivalent:@""] autorelease]];	
	
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
	[super UpdateCLUTMenu:note];
	
	// path 1 : /OsiriX Data/CLUTs/
	NSMutableString *path = [NSMutableString stringWithString: [[BrowserController currentBrowser] documentsDirectory]];
	[path appendString: CLUTDATABASE];
	// path 2 : /resources_bundle_path/CLUTs/
	NSMutableString *bundlePath = [NSMutableString stringWithString:[[NSBundle mainBundle] resourcePath]];
	[bundlePath appendString: CLUTDATABASE];
	
	NSMutableArray *paths = [NSMutableArray arrayWithObjects:path, bundlePath, nil];
	
	NSMutableArray *clutArray = [NSMutableArray array];
	BOOL isDir;
	
	for (NSUInteger j=0; j<[paths count]; j++)
	{
		if([[NSFileManager defaultManager] fileExistsAtPath:[paths objectAtIndex:j] isDirectory:&isDir] && isDir)
		{
			NSArray *content = [[NSFileManager defaultManager] directoryContentsAtPath:[paths objectAtIndex:j]];
			for (NSUInteger i=0; i<[content count]; i++)
			{
				if( [[content objectAtIndex:i] length] > 0)
				{
					if( [[content objectAtIndex:i] characterAtIndex: 0] != '.')
					{
						NSDictionary* clut = [CLUTOpacityView presetFromFileWithName:[[content objectAtIndex:i] stringByDeletingPathExtension]];
						if(clut)
						{
							[clutArray addObject:[[content objectAtIndex:i] stringByDeletingPathExtension]];
						}
					}
				}
			}
		}
	}
	
	[clutArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMenuItem *item;
	item = [[clutPopup menu] insertItemWithTitle:@"8-bit CLUTs" action:@selector(noAction:) keyEquivalent:@"" atIndex:3];
	
	if( [clutArray count])
	{
		[[clutPopup menu] insertItem:[NSMenuItem separatorItem] atIndex:[[clutPopup menu] numberOfItems]-2];
		
		item = [[clutPopup menu] insertItemWithTitle:@"16-bit CLUTs" action:@selector(noAction:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
		
		for (NSUInteger i=0; i<[clutArray count]; i++)
		{
			item = [[clutPopup menu] insertItemWithTitle:[clutArray objectAtIndex:i] action:@selector(loadAdvancedCLUTOpacity:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
			if([mprView1.vrView isRGB])
				[item setEnabled:NO];
		}
	}
	
    item = [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"16-bit CLUT Editor", nil) action:@selector(showCLUTOpacityPanel:) keyEquivalent:@""];
	if([[pixList[ 0] objectAtIndex:0] isRGB])
		[item setEnabled:NO];
		
	//[mprView1 updateViewMPR];
	//[mprView2 updateViewMPR];
	//[mprView3 updateViewMPR];
}

-(void) ApplyCLUTString:(NSString*) str
{
	NSString	*previousColorName = [NSString stringWithString: curCLUTMenu];
	
	if( str == nil) return;
	
	[OpacityPopup setEnabled:YES];
//	[clutOpacityView cleanup];
//	if([clutOpacityDrawer state]==NSDrawerOpenState)
//	{
//		[clutOpacityDrawer close];
//	}
	
	[self ApplyOpacityString:curOpacityMenu];
	
	if( [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str] == nil)
		str = @"No CLUT";
	
	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
	
	if(clippingRangeMode==0) //VR
	{
		int i, x;
		for ( x = 0; x < maxMovieIndex; x++)
		{
			for ( i = 0; i < [pixList[ x] count]; i ++) [[pixList[ x] objectAtIndex:i] setBlackIndex: 0];
		}
		
		[mprView1 setCLUT: nil :nil :nil];
		[mprView2 setCLUT: nil :nil :nil];
		[mprView3 setCLUT: nil :nil :nil];
		
		[mprView1 setIndex:[mprView1 curImage]];
		[mprView2 setIndex:[mprView2 curImage]];
		[mprView3 setIndex:[mprView3 curImage]];				
	}
	else
	{
		//[mprView1.vrView setCLUT: nil :nil :nil];
	}
	
	if([str isEqualToString:NSLocalizedString(@"No CLUT", nil)])
	{
		if(clippingRangeMode==0)
		{
			[mprView1.vrView setCLUT: nil :nil :nil];
		}
		else
		{
			int i, x;
			for ( x = 0; x < maxMovieIndex; x++)
			{
				for ( i = 0; i < [pixList[ x] count]; i ++) [[pixList[ x] objectAtIndex:i] setBlackIndex: 0];
			}
			
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
				int darkness = 256 * 3;
				int darknessIndex = 0;
				
				for( i = 0; i < 256; i++)
				{
					if( red[i] + green[i] + blue[i] < darkness)
					{
						darknessIndex = i;
						darkness = red[i] + green[i] + blue[i];
					}
				}
				
				int x;
				for ( x = 0; x < maxMovieIndex; x++)
				{
					for ( i = 0; i < [pixList[ x] count]; i ++)
					{
						[[pixList[ x] objectAtIndex:i] setBlackIndex: darknessIndex];
					}
				}
				
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

-(void) ApplyOpacityString:(NSString*) str
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
}


#pragma mark GUI ObjectController - Cocoa Bindings

- (void) setClippingRangeThickness:(float) f
{
	clippingRangeThickness = f;
	
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
}

- (void) setClippingRangeMode:(int) f
{
	float pWL, pWW;
	
	if( clippingRangeMode == 1 || clippingRangeMode == 3) // MIP
		[mprView1 getWLWW: &pWL :&pWW];
	else
		[mprView1.vrView getWLWW: &pWL :&pWW];
	
	clippingRangeMode = f;
	
	[mprView1.vrView setMode: clippingRangeMode];
	[mprView2.vrView setMode: clippingRangeMode];
	[mprView3.vrView setMode: clippingRangeMode];

	if( clippingRangeMode == 1 || clippingRangeMode == 3)	// MIP - Mean
	{		
		[mprView1.vrView prepareFullDepthCapture];
		[mprView2.vrView prepareFullDepthCapture];
		[mprView3.vrView prepareFullDepthCapture];
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
	}
	[self ApplyCLUTString:curCLUTMenu];
		
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3) [mprView1 setWLWW: pWL :pWW];
	else [mprView1.vrView setWLWW: pWL :pWW];
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3) [mprView2 setWLWW: pWL :pWW];
	else [mprView2.vrView setWLWW: pWL :pWW];
	[mprView2 updateViewMPR];

	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3) [mprView3 setWLWW: pWL :pWW];
	else [mprView3.vrView setWLWW: pWL :pWW];
	[mprView3 updateViewMPR];
}

#pragma mark Export	

#define DATABASEPATH @"/DATABASE.noindex/"
-(IBAction) endDCMExportSettings:(id) sender
{
	[dcmWindow orderOut:sender];
	[NSApp endSheet:dcmWindow returnCode:[sender tag]];
	
	MPRDCMView *curView = nil;
	if( [[self window] firstResponder] == mprView1) curView = mprView1;
	if( [[self window] firstResponder] == mprView2) curView = mprView2;
	if( [[self window] firstResponder] == mprView3) curView = mprView3;
	if( curView == nil) curView = mprView3;
	
	if( [sender tag])
	{
		NSMutableArray *producedFiles = [NSMutableArray array];
		
		[curView restoreCamera];
		[curView.vrView setViewSizeToMatrix3DExport];
		
		// CURRENT image only
		if( dcmMode == 0)
		{
			[producedFiles addObject: [curView.vrView exportDCMCurrentImage]];
		}
		// 4th dimension
		else if( dcmMode == 2)
		{
			Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating a DICOM series", nil)];
			[progress showWindow: self];
			[[progress progress] setMaxValue: maxMovieIndex];
			
			curView.vrView.exportDCM = [[[DICOMExport alloc] init] autorelease];
			[curView.vrView.exportDCM setSeriesNumber:8730 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
			
			for( int i = 0; i < maxMovieIndex; i++)
			{
				[[[self window] windowController] setMovieFrame: i];
				
				[producedFiles addObject: [curView.vrView exportDCMCurrentImage]];
				
				[progress incrementBy: 1];
				if( [progress aborted])
					break;
				
				[curView.vrView resetAutorotate: self];
			}
			
			[progress close];
			[progress release];
			
			[NSThread sleepForTimeInterval: 1];
			[[BrowserController currentBrowser] checkIncomingNow: self];
		}
		else if( dcmMode == 2) // A 3D sequence or batch sequence
		{
			Wait *progress = [[Wait alloc] initWithString: @"Creating a DICOM series"];
			[progress showWindow:self];
			[progress setCancel:YES];
			
			if( dcmSeriesMode == 0)
			{
				if( maxMovieIndex > 1)
				{
					self.dcmNumberOfFrames /= maxMovieIndex;
					self.dcmNumberOfFrames *= maxMovieIndex;
				}
				
				[[progress progress] setMaxValue: self.dcmNumberOfFrames];
				
				curView.vrView.exportDCM = [[[DICOMExport alloc] init] autorelease];
				[curView.vrView.exportDCM setSeriesNumber:8930 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
				
				for( int i = 0; i < self.dcmNumberOfFrames; i++)
				{
					if( maxMovieIndex > 1)
					{	
						short movieIndex = i;
				
						while( movieIndex >= maxMovieIndex) movieIndex -= maxMovieIndex;
						if( movieIndex < 0) movieIndex = 0;
				
						[self setMovieFrame: movieIndex];
					}
					
					[producedFiles addObject: [curView.vrView exportDCMCurrentImage]];
					
					[progress incrementBy: 1];
					
					if( [progress aborted])
						break;
					
					switch( dcmRotationDirection)
					{
						case 0:
							[curView.vrView Azimuth: (float) dcmRotation / (float) self.dcmNumberOfFrames];
						break;
						
						case 1:
							[curView.vrView Vertical: (float) dcmRotation / (float) self.dcmNumberOfFrames];
						break;
					}
				}
			}
			else // A batch sequence
			{
//				[[progress progress] setMaxValue: value];
			}
			
			[curView.vrView endRenderImageWithBestQuality];
			
			[progress close];
			[progress release];
		}
		
		[NSThread sleepForTimeInterval: 1];
		[[BrowserController currentBrowser] checkIncomingNow: self];
		
		if( ([[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"] || [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"]) && [producedFiles count])
		{
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
		
		[curView.vrView restoreViewSizeAfterMatrix3DExport];
		
		[NSThread sleepForTimeInterval: 1];
		[[BrowserController currentBrowser] checkIncomingNow: self];
	}
}

- (void) exportDICOMFile:(id) sender
{
	[NSApp beginSheet: dcmWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

#pragma mark NSWindow Notifications action

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
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
		
		[hiddenVRView setNeedsDisplay: YES];
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

@end