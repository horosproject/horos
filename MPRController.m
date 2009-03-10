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

extern short intersect3D_2Planes( float *Pn1, float *Pv1, float *Pn2, float *Pv2, float *u, float *iP);
static float deg2rad = 3.14159265358979/180.0; 

@implementation MPRController

@synthesize clippingRangeThickness, clippingRangeMode, mousePosition, mouseViewID;

+ (double) angleBetweenVector:(float*) a andPlane:(float*) orientation
{
	double sc[ 2];
	
	sc[ 0 ] = a[ 0] * orientation[ 0 ] + a[ 1] * orientation[ 1 ] + a[ 2] * orientation[ 2 ];
	sc[ 1 ] = a[ 0] * orientation[ 3 ] + a[ 1] * orientation[ 4 ] + a[ 2] * orientation[ 5 ];
	
	return ((atan2( sc[1], sc[0])) / deg2rad);
}

- (DCMPix*) emptyPix: (DCMPix*) originalPix width: (long) w height: (long) h
{
	long size = sizeof( float) * w * h;
	float *imagePtr = malloc( size);
	DCMPix *emptyPix = [[[DCMPix alloc] initwithdata: imagePtr :32 :w :h :[originalPix pixelSpacingX] :[originalPix pixelSpacingY] :[originalPix originX] :[originalPix originY] :[originalPix originZ]] autorelease];
	free( imagePtr);
	
	return emptyPix;
}

- (id)initWithDCMPixList:(NSMutableArray*)pix filesList:(NSMutableArray*)files volumeData:(NSData*)volume viewerController:(ViewerController*)viewer fusedViewerController:(ViewerController*)fusedViewer;
{
	self = [super initWithWindowNibName:@"MPR"];
	
	DCMPix *originalPix = [pix lastObject];
	
	pixList[0] = pix;
	filesList[0] = files;
	volumeData[0] = volume;
	
	[[self window] setDelegate:self];
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
	
	// To avoid the "invalid drawable" message
	[[hiddenVRController window] setLevel: 0];
	[[hiddenVRController window] orderBack: self];
	[[hiddenVRController window] orderOut: self];

	[hiddenVRController load3DState];
	
	hiddenVRView = [hiddenVRController view];
	[hiddenVRView setClipRangeActivated: YES];
	[hiddenVRView resetImage: self];
	[hiddenVRView setLOD: 2.0];
	hiddenVRView.keep3DRotateCentered = YES;
	
	[mprView1 setVRView: hiddenVRView viewID: 1];
	[mprView1 setWLWW: [originalPix wl] :[originalPix ww]];
	
	[mprView2 setVRView: hiddenVRView viewID: 2];
	[mprView2 setWLWW: [originalPix wl] :[originalPix ww]];
	
	[mprView3 setVRView: hiddenVRView viewID: 3];
	[mprView3 setWLWW: [originalPix wl] :[originalPix ww]];
		
	return self;
}

- (void) updateViewsAccordingToFrame:(id) sender	// see setFrame in MPRDCMView.m
{
	[mprView3 restoreCamera];
	[mprView3 updateView];
}

- (void) showWindow:(id) sender
{
	// Default Init
	[self setClippingRangeMode: 1]; // MIP
	[self setClippingRangeThickness: 1];
	
	[[self window] makeFirstResponder: mprView1];
	[mprView1.vrView resetImage: self];
	[mprView1 updateView];
	
	mprView2.camera.viewUp = [Point3D pointWithX:0 y:-1 z:0];
	[mprView1 updateView];
	
	[super showWindow: sender];
}

- (void) dealloc
{
	[mousePosition release];
	
	[super dealloc];
}

- (BOOL) is2DViewer
{
	return NO;
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
	
	if( sender != mprView1) mprView1.camera.parallelScale = sender.camera.parallelScale;
	if( sender != mprView2) mprView2.camera.parallelScale = sender.camera.parallelScale;
	if( sender != mprView3) mprView3.camera.parallelScale = sender.camera.parallelScale;
	
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
			
			[mprView1 updateView];
		}
		
		if( sender != mprView2)
		{
			[mprView2 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView2.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView2.vrView setWLWW: l : w];
			}
			
			[mprView2 updateView];
		}
		
		if( sender != mprView3)
		{
			[mprView3 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView3.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView3.vrView setWLWW: l : w];
			}
			
			[mprView3 updateView];
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

#pragma mark GUI ObjectController - Cocoa Bindings

- (void) setClippingRangeThickness:(float) f
{
	clippingRangeThickness = f;
	
	[mprView1 restoreCamera];
	mprView1.vrView.dontResetImage = YES;
	[mprView1.vrView setClippingRangeThickness: f];
	[mprView1 updateView];
	
	[mprView2 restoreCamera];
	mprView2.vrView.dontResetImage = YES;
	[mprView2.vrView setClippingRangeThickness: f];
	[mprView2 updateView];
	
	[mprView3 restoreCamera];
	mprView3.vrView.dontResetImage = YES;
	[mprView3.vrView setClippingRangeThickness: f];
	[mprView3 updateView];
}

- (void) setClippingRangeMode:(int) f
{
	float pWL, pWW;
	
	if( clippingRangeMode == 1) // MIP
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

	[mprView1 restoreCamera];
	if( clippingRangeMode == 1) [mprView1 setWLWW: pWL :pWW];
	else [mprView1.vrView setWLWW: pWL :pWW];
	[mprView1 updateView];
	
	[mprView2 restoreCamera];
	if( clippingRangeMode == 1) [mprView2 setWLWW: pWL :pWW];
	else [mprView2.vrView setWLWW: pWL :pWW];
	[mprView2 updateView];

	[mprView3 restoreCamera];
	if( clippingRangeMode == 1) [mprView3 setWLWW: pWL :pWW];
	else [mprView3.vrView setWLWW: pWL :pWW];
	[mprView3 updateView];
}

#pragma mark NSWindow Notifications action

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [hiddenVRController window])
	{
		hiddenVRController = nil;
	}
	
	if( [notification object] == [self window])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: @"Window3DClose" object: self userInfo: 0];
		
		if( movieTimer)
		{
			[movieTimer invalidate];
			[movieTimer release];
			movieTimer = nil;
		}
		
		[hiddenVRController close];
		
		[[self window] setDelegate:nil];
		[[self window] setWindowController:nil];
		[self release];
	}
}

@end
