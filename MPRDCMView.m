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

#import "MPRDCMView.h"
#import "VRController.h"
#import "VRView.h"
#import "DCMCursor.h"
#import "ROI.h"

static float deg2rad = 3.14159265358979/180.0; 

extern short intersect3D_2Planes( float *Pn1, float *Pv1, float *Pn2, float *Pv2, float *u, float *iP);

#define VIEW_COLOR_LABEL_SIZE 25

static int splitPosition[ 2];
static BOOL frameZoomed = NO;

@implementation MPRDCMView

@synthesize pix, camera, angleMPR, vrView, viewExport, toIntervalExport, fromIntervalExport, rotateLines, moveCenter, displayCrossLines, LOD;

- (BOOL)becomeFirstResponder
{
	BOOL v = [super becomeFirstResponder];
	
	[windowController updateToolbarItems];

	return v;
}

- (void) setDisplayCrossLines: (BOOL) b
{
	displayCrossLines = b;
	[windowController updateToolbarItems];
}

- (BOOL)is2DTool:(short)tool;
{
	switch( tool)
	{
		case tWL:
			if( vrView.renderingMode == 1 || vrView.renderingMode == 3) return YES; // MIP
			else return NO; // VR
		break;
		
		case tNext:
		case tMesure:
		case tROI:
		case tOval:
		case tOPolygon:
		case tCPolygon:
		case tAngle:
		case tArrow:
		case tText:
		case tPencil:
		case tPlain:
		case t2DPoint:
		case tRepulsor:
		case tLayerROI:
		case tROISelector:
			return YES;
		break;
	}
	
	return NO;
}

- (void) setDCMPixList:(NSMutableArray*)pixList filesList:(NSArray*)files roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
{
	[super setDCM:pixList :files :rois :firstImage :type :reset];

	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(removeROI:)
											name: @"removeROI"
											object: nil];


	rotation = 0;
	
	pix = [pixList lastObject];
	
	currentTool = t3DRotate;
	
	frameZoomed = NO;
	displayCrossLines = YES;
	
	windowController = [self windowController];
	
	[windowController updateToolbarItems];
}

- (void) setVRView: (VRView*) v viewID:(int) i
{
	viewID = i;
	vrView = v;
	[vrView prepareFullDepthCapture];
}

- (void) saveCamera
{
	[camera release];
	camera = [[vrView cameraWithThumbnail: NO] retain];
}

- (void) setFrame:(NSRect)frameRect
{
	if( NSEqualRects( frameRect, [self frame]) == NO)
	{
		[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( updateViewsAccordingToFrame:) object: nil];
		[windowController performSelector: @selector( updateViewsAccordingToFrame:) withObject: nil afterDelay: 0.1];
	}
	
	if( blendingView)
	{
		[blendingView setFrame: frameRect];
		blendingView.drawingFrameRect = frameRect; // very important to have correct position values with PET-CT
	}
	
	[super setFrame: frameRect];
}

- (void) checkForFrame
{
	NSRect frame = [self frame];
	NSPoint o = [self convertPoint: NSMakePoint(0, 0) toView:0L];
	frame.origin = o;
	
	if( NSEqualRects( frame, [vrView frame]) == NO)
	{
		[vrView setFrame: frame];
	}
}
//
//- (BOOL) hasCameraMoved: (Camera*) currentCamera
//{
//	if( fabs( currentCamera.position.x - camera.position.x) > 0.1) return YES;
//	if( fabs( currentCamera.position.y - camera.position.y) > 0.1) return YES;
//	if( fabs( currentCamera.position.z - camera.position.z) > 0.1) return YES;
//
//	if( fabs( currentCamera.focalPoint.x - camera.focalPoint.x) > 0.1) return YES;
//	if( fabs( currentCamera.focalPoint.y - camera.focalPoint.y) > 0.1) return YES;
//	if( fabs( currentCamera.focalPoint.z - camera.focalPoint.z) > 0.1) return YES;
//
//	if( fabs( currentCamera.viewUp.x - camera.viewUp.x) > 0.1) return YES;
//	if( fabs( currentCamera.viewUp.y - camera.viewUp.y) > 0.1) return YES;
//	if( fabs( currentCamera.viewUp.z - camera.viewUp.z) > 0.1) return YES;
//
//	if( fabs( currentCamera.viewAngle - camera.viewAngle) > 3) return YES;
//	if( fabs( currentCamera.eyeAngle - camera.eyeAngle) > 3) return YES;
//	
//	return NO;
//
//}

- (BOOL) hasCameraChanged: (Camera*) currentCamera
{
	if( camera.forceUpdate)
	{
		camera.forceUpdate = NO;
		return YES;
	}
	
	#define PRECISION 0.0001
	
	if( fabs( currentCamera.position.x - camera.position.x) > PRECISION) return YES;
	if( fabs( currentCamera.position.y - camera.position.y) > PRECISION) return YES;
	if( fabs( currentCamera.position.z - camera.position.z) > PRECISION) return YES;

	if( fabs( currentCamera.focalPoint.x - camera.focalPoint.x) > PRECISION) return YES;
	if( fabs( currentCamera.focalPoint.y - camera.focalPoint.y) > PRECISION) return YES;
	if( fabs( currentCamera.focalPoint.z - camera.focalPoint.z) > PRECISION) return YES;

	if( fabs( currentCamera.viewUp.x - camera.viewUp.x) > PRECISION) return YES;
	if( fabs( currentCamera.viewUp.y - camera.viewUp.y) > PRECISION) return YES;
	if( fabs( currentCamera.viewUp.z - camera.viewUp.z) > PRECISION) return YES;

	if( fabs( currentCamera.viewAngle - camera.viewAngle) > PRECISION) return YES;
	if( fabs( currentCamera.eyeAngle - camera.eyeAngle) > PRECISION) return YES;
	if( fabs( currentCamera.parallelScale - camera.parallelScale) > PRECISION) return YES;

	if( currentCamera.clippingRangeNear != camera.clippingRangeNear) return YES;
	if( currentCamera.clippingRangeFar != camera.clippingRangeFar) return YES;
	
//	if( currentCamera.LOD < camera.LOD) return YES;
	
	if( currentCamera.wl != camera.wl) return YES;
	if( currentCamera.ww != camera.ww) return YES;
	
	return NO;
}

- (void) restoreCamera
{
	return [self restoreCameraAndCheckForFrame: YES];
}

- (void) restoreCameraAndCheckForFrame: (BOOL) v
{
	if( v)
		[self checkForFrame];
	[vrView setCamera: camera];
}

- (void) dealloc
{
//	[vrView restoreFullDepthCapture];
	[camera release];
	
	[super dealloc];
}

-(void) updateViewMPR
{
	[self updateViewMPR: YES];
}

- (void) updateViewMPR:(BOOL) computeCrossReferenceLines
{
	long h, w;
	float previousWW, previousWL;
	BOOL isRGB;
	
	[self getWLWW: &previousWL :&previousWW];
	
	Camera *currentCamera = [vrView cameraWithThumbnail: NO];
	
	if( [self hasCameraChanged: currentCamera] == YES)
	{
		// AutoLOD
		if( windowController.dontUseAutoLOD == NO)
		{
			DCMPix *o = [windowController originalPix];
			
			float minimumResolution = [o pixelSpacingX];
			
			if( minimumResolution > [o pixelSpacingY])
				minimumResolution = [o pixelSpacingY];
			
			if( minimumResolution > [o sliceInterval])
				minimumResolution = [o sliceInterval];
			
			minimumResolution *= 0.9;
			
			float currentResolution = [pix pixelSpacingX];
			
			if( minimumResolution > currentResolution && currentResolution != 0)
				LOD *= ( minimumResolution / currentResolution);
			
			if( previousResolution == 0)
				previousResolution = [vrView getResolution];
			
			if( previousResolution < [vrView getResolution])
				LOD *= (previousResolution / [vrView getResolution]);
			
			if( LOD < windowController.LOD)
				LOD = windowController.LOD;
			
			previousResolution = [vrView getResolution];
			
			if( LOD > 4) LOD = 4;
			
			if( windowController.lowLOD)
				[vrView setLOD: LOD * vrView.lowResLODFactor];
			else
				[vrView setLOD: LOD];
		}
		else
			[vrView setLOD: LOD];
		
		if( [self frame].size.width > 0 && [self frame].size.height > 0)
		{
			if( windowController.maxMovieIndex > 1 && (windowController.clippingRangeMode == 1 || windowController.clippingRangeMode == 3))	//To avoid the wrong pixel value bug...
				[vrView prepareFullDepthCapture];
			
			if( moveCenter)
				[vrView setLOD: 100];	// We dont need to really compute the image - we just want image origin for the other views.
//			else NSLog( @"viewID: %d %f", viewID, LOD);
			
			[vrView render];
		}
		
		float *imagePtr = nil;
		
		if( moveCenter)
		{
			imagePtr = [pix fImage];
			w = [pix pwidth];
			h = [pix pheight];
			isRGB = [pix isRGB];
		}
		else
			imagePtr = [vrView imageInFullDepthWidth: &w height: &h isRGB: &isRGB];
		
		[self saveCamera];
		
		if( imagePtr)
		{
			float orientation[ 9];
			
			[vrView getOrientation: orientation];
			
			float slicePoint[ 3], sV[ 3];
			float fakeOrigin[ 3] = {0, 0, 0};
			BOOL cameraMoved;
			if( intersect3D_2Planes( orientation+6, fakeOrigin, previousOrientation+6, fakeOrigin, sV, slicePoint) == noErr)
				cameraMoved = YES;
			else
				cameraMoved = NO;
			
			if( cameraMoved == YES)
			{
				for( int i = [curRoiList count] -1 ; i >= 0; i--)
				{
					ROI *r = [curRoiList objectAtIndex: i];
					if( [r type] != t2DPoint)
						[curRoiList removeObjectAtIndex: i];
				}
			}
			
			if( [pix pwidth] == w && [pix pheight] == h && isRGB == [pix isRGB])
			{
				if( imagePtr != [pix fImage])
				{
					memcpy( [pix fImage], imagePtr, w*h*sizeof( float));
					free( imagePtr);
				}
			}
			else
			{
				[pix setRGB: isRGB];
				[pix setfImage: imagePtr];
				[pix freefImageWhenDone: YES];
				[pix setPwidth: w];
				[pix setPheight: h];
				
				NSMutableArray *savedROIs = [[curRoiList copy] autorelease];
				
				[self setIndex: 0];
				
				[curRoiList addObjectsFromArray: savedROIs];
			}
			float porigin[ 3];
			[vrView getOrigin: porigin windowCentered: YES sliceMiddle: YES];
			[pix setOrigin: porigin];
			
			float resolution = 0;
			if( !moveCenter)
			{
				resolution = [vrView getResolution] * [vrView imageSampleDistance];
				[pix setPixelSpacingX: resolution];
				[pix setPixelSpacingY: resolution];
			}
			
			[pix setOrientation: orientation];
			[pix setSliceThickness: [vrView getClippingRangeThicknessInMm]];
			
			[self setWLWW: previousWL :previousWW];
			
			if( !moveCenter)
			{
				[self setScaleValue: [vrView imageSampleDistance]];
				
				float rotationPlane = 0;
				if( cameraMoved == NO)
				{
					if( previousOrientation[ 0] != 0 || previousOrientation[ 1] != 0 || previousOrientation[ 2] != 0)
						rotationPlane = -[MPRController angleBetweenVector: orientation andPlane: previousOrientation];
					if( fabs( rotationPlane) < 0.01) rotationPlane = 0;
				}
				
				NSPoint rotationCenter = NSMakePoint( [pix pwidth]/2., [pix pheight]/2.);
				for( ROI* r in curRoiList)
				{
					if( rotationPlane)
					{
						[r rotate: rotationPlane :rotationCenter];
						r.imageOrigin = [DCMPix originCorrectedAccordingToOrientation: pix];
						r.pixelSpacingX = [pix pixelSpacingX];
						r.pixelSpacingY = [pix pixelSpacingY];
					}
					else
						[r setOriginAndSpacing: resolution : resolution :[DCMPix originCorrectedAccordingToOrientation: pix] :NO];
				}
				[pix orientation: previousOrientation];
				
				[self detect2DPointInThisSlice];
			}
		}
		
		if( blendingView)
		{
			[blendingView getWLWW: &previousWL :&previousWW];
			
			[vrView renderBlendedVolume];
			
			float *blendedImagePtr = nil;
			DCMPix *bPix = [blendingView curDCM];
			
			if( moveCenter)
			{
				blendedImagePtr = [bPix fImage];
				w = [bPix pwidth];
				h = [bPix pheight];
				isRGB = [bPix isRGB];
			}
			else
				blendedImagePtr = [vrView imageInFullDepthWidth: &w height: &h isRGB: &isRGB blendingView: YES];
			
			if( [bPix pwidth] == w && [bPix pheight] == h && isRGB == [bPix isRGB])
			{
				if( blendedImagePtr != [bPix fImage])
				{
					memcpy( [bPix fImage], blendedImagePtr, w*h*sizeof( float));
					free( blendedImagePtr);
				}
			}
			else
			{
				[bPix setRGB: isRGB];
				[bPix setfImage: blendedImagePtr];
				[bPix setPwidth: w];
				[bPix setPheight: h];
				
				[blendingView setIndex: 0];
			}
			float porigin[ 3];
			[vrView getOrigin: porigin windowCentered: YES sliceMiddle: YES blendedView: YES];
			[bPix setOrigin: porigin];
			
			if( !moveCenter)
			{
				float resolution = [vrView getResolution] * [vrView blendingImageSampleDistance];
				[bPix setPixelSpacingX: resolution];
				[bPix setPixelSpacingY: resolution];
			}
			
			float orientation[ 9];
			[vrView getOrientation: orientation];
			[bPix setOrientation: orientation];
			[bPix setSliceThickness: [vrView getClippingRangeThicknessInMm]];
			
			[blendingView setWLWW: previousWL :previousWW];
			
			if( !moveCenter)
				[blendingView setScaleValue: [vrView blendingImageSampleDistance]];
		}
	}
	
	if( dontReenterCrossReferenceLines == NO)
	{
		dontReenterCrossReferenceLines = YES;
		
		if( computeCrossReferenceLines)
			[windowController computeCrossReferenceLines: self];
		else
			[windowController computeCrossReferenceLines: nil];
		
		dontReenterCrossReferenceLines = NO;
	}
	
	[self setNeedsDisplay: YES];
}

- (void) colorForView:(int) v
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	switch( v)
	{
		case 1:
			//glColor4f (VIEW_1_RED, VIEW_1_GREEN, VIEW_1_BLUE, VIEW_1_ALPHA);
			glColor4f ([windowController.colorAxis1 redComponent], [windowController.colorAxis1 greenComponent], [windowController.colorAxis1 blueComponent], [windowController.colorAxis1 alphaComponent]);
		break;
		
		case 2:
			//glColor4f (VIEW_2_RED, VIEW_2_GREEN, VIEW_2_BLUE, VIEW_2_ALPHA);
			glColor4f ([windowController.colorAxis2 redComponent], [windowController.colorAxis2 greenComponent], [windowController.colorAxis2 blueComponent], [windowController.colorAxis2 alphaComponent]);
		break;
		
		case 3:
			//glColor4f (VIEW_3_RED, VIEW_3_GREEN, VIEW_3_BLUE, VIEW_3_ALPHA);
			glColor4f ([windowController.colorAxis3 redComponent], [windowController.colorAxis3 greenComponent], [windowController.colorAxis3 blueComponent], [windowController.colorAxis3 alphaComponent]);
		break;
	}
}

- (void) drawLine: (float[2][3]) sft thickness: (float) thickness
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	if( thickness > 2)
	{
		glLineWidth(2.0);
		[self drawCrossLines: sft ctx: cgl_ctx withShift: 0];
		
		glLineWidth(1.0);
		[self drawCrossLines: sft ctx: cgl_ctx withShift: -thickness/2.];
		[self drawCrossLines: sft ctx: cgl_ctx withShift: thickness/2.];
	}
	else
	{
		glLineWidth(2.0);
		[self drawCrossLines: sft ctx: cgl_ctx withShift: 0];
	}
}

- (void) drawExportLines: (float[2][3]) sft
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glLineWidth(1.0);
						
	if( fromIntervalExport > 0)
	{
		for( int i = 1; i <= fromIntervalExport; i++)
			[self drawCrossLines: sft ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
	}
	
	if( !windowController.dcmBatchReverse)
		[self drawCrossLines: sft ctx: cgl_ctx withShift: -fromIntervalExport * [windowController dcmInterval] showPoint: YES];
	
	if( toIntervalExport > 0)
	{
		for( int i = 1; i <= toIntervalExport; i++)
			[self drawCrossLines: sft ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
	}
	
	if( windowController.dcmBatchReverse)
		[self drawCrossLines: sft ctx: cgl_ctx withShift: toIntervalExport * [windowController dcmInterval] showPoint: YES];
}

- (void) drawRotationLines: (float[2][3]) sft
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
	{
		glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
		[self drawCrossLines: sft ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
		glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
	}
}

- (void) subDrawRect: (NSRect) r
{
	if( [stringID isEqualToString: @"export"])
		return;
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable(GL_BLEND);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glPointSize( 12);
	
	if( displayCrossLines)
	{
		// All pix have the same thickness
		float thickness = [pix sliceThickness];
		
		switch( viewID)
		{
			case 1:
				glColor4f ([windowController.colorAxis2 redComponent], [windowController.colorAxis2 greenComponent], [windowController.colorAxis2 blueComponent], [windowController.colorAxis2 alphaComponent]);
				if( crossLinesA[ 0][ 0] != HUGE_VALF)
				{
					[self drawLine: crossLinesA thickness: thickness];
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
						[self drawExportLines: crossLinesA];
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
						[self drawRotationLines: crossLinesA];
				}
				glColor4f ([windowController.colorAxis3 redComponent], [windowController.colorAxis3 greenComponent], [windowController.colorAxis3 blueComponent], [windowController.colorAxis3 alphaComponent]);
				if( crossLinesB[ 0][ 0] != HUGE_VALF)
				{
					[self drawLine: crossLinesB thickness: thickness];
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
						[self drawExportLines: crossLinesB];
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
						[self drawRotationLines: crossLinesB];
				}
			break;
			
			case 2:
				glColor4f ([windowController.colorAxis1 redComponent], [windowController.colorAxis1 greenComponent], [windowController.colorAxis1 blueComponent], [windowController.colorAxis1 alphaComponent]);
				if( crossLinesA[ 0][ 0] != HUGE_VALF)
				{
					[self drawLine: crossLinesA thickness: thickness];
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
						[self drawExportLines: crossLinesA];
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
						[self drawRotationLines: crossLinesA];
				}
				
				glColor4f ([windowController.colorAxis3 redComponent], [windowController.colorAxis3 greenComponent], [windowController.colorAxis3 blueComponent], [windowController.colorAxis3 alphaComponent]);
				if( crossLinesB[ 0][ 0] != HUGE_VALF)
				{
					[self drawLine: crossLinesB thickness: thickness];
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
						[self drawExportLines: crossLinesB];
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
						[self drawRotationLines: crossLinesB];
				}
			break;
			
			case 3:
				glColor4f ([windowController.colorAxis1 redComponent], [windowController.colorAxis1 greenComponent], [windowController.colorAxis1 blueComponent], [windowController.colorAxis1 alphaComponent]);
				if( crossLinesA[ 0][ 0] != HUGE_VALF)
				{
					[self drawLine: crossLinesA thickness: thickness];
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
						[self drawExportLines: crossLinesA];
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
						[self drawRotationLines: crossLinesA];
				}
				
				glColor4f ([windowController.colorAxis2 redComponent], [windowController.colorAxis2 greenComponent], [windowController.colorAxis2 blueComponent], [windowController.colorAxis2 alphaComponent]);
				if( crossLinesB[ 0][ 0] != HUGE_VALF)
				{
					[self drawLine: crossLinesB thickness: thickness];
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
						[self drawExportLines: crossLinesB];
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
						[self drawRotationLines: crossLinesB];
				}
			break;
		}
	}
	
	float heighthalf = self.frame.size.height/2;
	float widthhalf = self.frame.size.width/2;
	
	[self colorForView: viewID];
	
	// Red Square
	if( [[self window] firstResponder] == self)
	{
		glLineWidth(8.0);
		glBegin(GL_LINE_LOOP);
			glVertex2f(  -widthhalf, -heighthalf);
			glVertex2f(  -widthhalf, heighthalf);
			glVertex2f(  widthhalf, heighthalf);
			glVertex2f(  widthhalf, -heighthalf);
		glEnd();
	}
	
	glLineWidth(2.0);
	glBegin(GL_POLYGON);
		glVertex2f(widthhalf-VIEW_COLOR_LABEL_SIZE, -heighthalf+VIEW_COLOR_LABEL_SIZE);
		glVertex2f(widthhalf-VIEW_COLOR_LABEL_SIZE, -heighthalf);
		glVertex2f(widthhalf, -heighthalf);
		glVertex2f(widthhalf, -heighthalf+VIEW_COLOR_LABEL_SIZE);
	glEnd();
	glLineWidth(1.0);
	
	if( displayCrossLines && windowController.displayMousePosition && !windowController.mprView1.rotateLines && !windowController.mprView2.rotateLines && !windowController.mprView3.rotateLines
																					&& !windowController.mprView1.moveCenter && !windowController.mprView2.moveCenter && !windowController.mprView3.moveCenter)
	{
		// Mouse Position
		if( viewID == windowController.mouseViewID)
		{
			DCMPix *pixA, *pixB;
			int viewIDA, viewIDB;
			
			switch (viewID)
			{	
				case 1:
					pixA = [windowController.mprView2 pix];
					pixB = [windowController.mprView3 pix];
					viewIDA = 2;
					viewIDB = 3;
					break;
				case 2:
					pixA = [windowController.mprView1 pix];
					pixB = [windowController.mprView3 pix];
					viewIDA = 1;
					viewIDB = 3;					
					break;
				case 3:
					pixA = [windowController.mprView1 pix];
					pixB = [windowController.mprView2 pix];
					viewIDA = 1;
					viewIDB = 2;
					break;		
			}
			
			[self colorForView:viewIDA];
			Point3D *pt = windowController.mousePosition;
			float sc[ 3], dc[ 3] = { pt.x, pt.y, pt.z}, location[ 3];
			[pixA convertDICOMCoords: dc toSliceCoords: sc pixelCenter: YES];
			sc[0] = sc[ 0] / pixA.pixelSpacingX;
			sc[1] = sc[ 1] / pixA.pixelSpacingY;
			[pixA convertPixX:sc[0] pixY:sc[1] toDICOMCoords:location pixelCenter:YES];
			[pix convertDICOMCoords:location toSliceCoords:sc pixelCenter:YES];
			
			glPointSize( 10);
			glBegin( GL_POINTS);
			sc[0] = sc[ 0] / curDCM.pixelSpacingX;
			sc[1] = sc[ 1] / curDCM.pixelSpacingY;
			sc[0] -= curDCM.pwidth * 0.5f;
			sc[1] -= curDCM.pheight * 0.5f;
			glVertex2f( scaleValue*sc[ 0], scaleValue*sc[ 1]);
			glEnd();

			
			[self colorForView:viewIDB];
			pt = windowController.mousePosition;
			dc[0] = pt.x; dc[1] = pt.y; dc[2] = pt.z;
			[pixB convertDICOMCoords: dc toSliceCoords: sc pixelCenter: YES];
			sc[0] = sc[ 0] / pixB.pixelSpacingX;
			sc[1] = sc[ 1] / pixB.pixelSpacingY;
			[pixB convertPixX:sc[0] pixY:sc[1] toDICOMCoords:location pixelCenter:YES];
			[pix convertDICOMCoords:location toSliceCoords:sc pixelCenter:YES];
			
			glPointSize( 10);
			glBegin( GL_POINTS);
			sc[0] = sc[ 0] / curDCM.pixelSpacingX;
			sc[1] = sc[ 1] / curDCM.pixelSpacingY;
			sc[0] -= curDCM.pwidth * 0.5f;
			sc[1] -= curDCM.pheight * 0.5f;
			glVertex2f( scaleValue*sc[ 0], scaleValue*sc[ 1]);
			glEnd();

		}
		if( viewID != windowController.mouseViewID)
		{
			[self colorForView: viewID];
//			[self colorForView: windowController.mouseViewID];
			Point3D *pt = windowController.mousePosition;
			float sc[ 3], dc[ 3] = { pt.x, pt.y, pt.z};
			
			[pix convertDICOMCoords: dc toSliceCoords: sc pixelCenter: YES];
			
			glPointSize( 10);
			glBegin( GL_POINTS);
			sc[0] = sc[ 0] / curDCM.pixelSpacingX;
			sc[1] = sc[ 1] / curDCM.pixelSpacingY;
			sc[0] -= curDCM.pwidth * 0.5f;
			sc[1] -= curDCM.pheight * 0.5f;
			glVertex2f( scaleValue*sc[ 0], scaleValue*sc[ 1]);
			glEnd();
		}
	}
	
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);
}

- (void) setCrossReferenceLines: (float[2][3]) a and: (float[2][3]) b
{	
	crossLinesA[ 0][ 0] = a[ 0][ 0];
	crossLinesA[ 0][ 1] = a[ 0][ 1];
	crossLinesA[ 0][ 2] = a[ 0][ 2];
	crossLinesA[ 1][ 0] = a[ 1][ 0];
	crossLinesA[ 1][ 1] = a[ 1][ 1];
	crossLinesA[ 1][ 2] = a[ 1][ 2];
	
	crossLinesB[ 0][ 0] = b[ 0][ 0];
	crossLinesB[ 0][ 1] = b[ 0][ 1];
	crossLinesB[ 0][ 2] = b[ 0][ 2];
	crossLinesB[ 1][ 0] = b[ 1][ 0];
	crossLinesB[ 1][ 1] = b[ 1][ 1];
	crossLinesB[ 1][ 2] = b[ 1][ 2];
}

- (void)keyDown:(NSEvent *)theEvent
{
    unichar c = [[theEvent characters] characterAtIndex:0];
    
	if( c ==  ' ' || c == 27) // 27 : escape
	{
		[windowController keyDown:theEvent];
	}
	else
	{
		[super keyDown: theEvent];
		
		[windowController propagateWLWW: self];
	}
}

#pragma mark-
#pragma mark 3D ROI Point	

- (void) detect2DPointInThisSlice
{
	ViewerController *viewer2D = [windowController viewer];
	
	if (viewer2D)
	{
		// First delete all 2D Points in our pix
		
		NSMutableDictionary *ROIsStateSaved = [NSMutableDictionary dictionary];
		
		for( int i = [curRoiList count] -1 ; i >= 0; i--)
		{
			ROI *r = [curRoiList objectAtIndex: i];
			if( [r type] == t2DPoint)
			{
				if( r.parentROI)
					[ROIsStateSaved setObject: [NSNumber numberWithInt: [r ROImode]] forKey: [NSValue valueWithPointer: r.parentROI]];
				[curRoiList removeObjectAtIndex: i];
			}
		}
		
		NSArray *roiList = [viewer2D roiList: [windowController curMovieIndex]];
		NSArray *pixList = [viewer2D pixList: [windowController curMovieIndex]];
		
		for( int i = 0; i < [roiList count]; i++)
		{
			NSArray *pts = [roiList objectAtIndex: i];
			DCMPix *p = [pixList objectAtIndex: i];
			
			for( ROI *r in pts)
			{
				if( [r type] == t2DPoint)
				{
					float location[ 3];
					
					[p convertPixX: r.rect.origin.x pixY: r.rect.origin.y toDICOMCoords: location pixelCenter: YES];
					
					// Is this point in our plane?
					
					int		ii = -1;
					float	vectors[ 9], orig[ 3], locationTemp[ 3];
					float	distance = 999999;
					
					orig[ 0] = [pix originX];
					orig[ 1] = [pix originY];
					orig[ 2] = [pix originZ];
					
					[pix orientation: vectors];
					
					distance = [DCMView pbase_Plane: location :orig :&(vectors[ 6]) :locationTemp];
					
					if( distance < pix.sliceThickness)
					{
						float sc[ 3];
						
						[pix convertDICOMCoords: location toSliceCoords: sc pixelCenter: YES];
						
						sc[ 0] = sc[ 0] / pix.pixelSpacingX;
						sc[ 1] = sc[ 1] / pix.pixelSpacingY;
						
						ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :pix.pixelSpacingX :pix.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: pix]];
						
						[new2DPointROI setROIRect: NSMakeRect( sc[ 0], sc[ 1], 0, 0)];
						
						[new2DPointROI setParentROI: r];
						[self roiSet: new2DPointROI];
						[curRoiList addObject: new2DPointROI];
						
						int mode = [[ROIsStateSaved objectForKey: [NSValue valueWithPointer: r]] intValue];
						if( mode)
							[new2DPointROI setROIMode: mode];
					}
				}
			}
		}
		
		[self setNeedsDisplay: YES];
	}
}

- (void) add2DPoint: (float*) r
{
	ViewerController *viewer2D = [windowController viewer];
	
	if (viewer2D)
	{
		DCMPix *p = [[viewer2D pixList] objectAtIndex: 0];
		
		float sc[ 3];
		
		[p convertDICOMCoords: r toSliceCoords: sc pixelCenter: YES];

		sc[ 0] = sc[ 0] / p.pixelSpacingX;
		sc[ 1] = sc[ 1] / p.pixelSpacingY;
		sc[ 2] = sc[ 2] / p.sliceInterval;
		
		sc[ 2] = round( sc[ 2]);
		
		if (sc[ 2] >= 0 && sc[ 2] < [[viewer2D pixList] count])
		{
			// Create the new 2D Point ROI
			ROI *new2DPointROI = [[ROI alloc] initWithType: t2DPoint :p.pixelSpacingX :p.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: p]];
			
			[new2DPointROI setROIRect: NSMakeRect( sc[ 0], sc[ 1], 0, 0)];
			
			[[viewer2D imageView] roiSet:new2DPointROI];
			[[[viewer2D roiList] objectAtIndex: sc[ 2]] addObject: new2DPointROI];
			
			// notify the change
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object: new2DPointROI userInfo: nil];
		}
	}
}

-(void) roiChange:(NSNotification*)note
{
	if( dontCheckRoiChange == NO)
	{
		ROI *r = [note object];
		
		if( [r curView] != nil && [r curView] == [[windowController viewer] imageView])
			[self detect2DPointInThisSlice];
	}
	
	[super roiChange: note];
}

- (void) removeROI: (NSNotification*) note
{
	ROI *r = [note object];
	
	if( [r type] == t2DPoint && r.parentROI)
	{
		[[windowController viewer] deleteROI: r.parentROI];
		r.parentROI = nil;
		
	}
	
	if( dontCheckRoiChange == NO)
	{
		if( [r curView] != nil && [r curView] == [[windowController viewer] imageView])
			[self detect2DPointInThisSlice];
	}
}

#pragma mark-
#pragma mark Mouse Events	

#define BS 10.

- (float) angleBetween:(NSPoint) mouseLocation center:(NSPoint) center
{
	mouseLocation.x -= center.x;
	mouseLocation.y -= center.y;
	
	return -atan2( mouseLocation.x, mouseLocation.y) / deg2rad;
}

- (NSPoint) centerLines
{
	NSPoint a1 = NSMakePoint( crossLinesA[ 0][ 0], crossLinesA[ 0][ 1]);
	NSPoint a2 = NSMakePoint( crossLinesA[ 1][ 0], crossLinesA[ 1][ 1]);
	
	NSPoint b1 = NSMakePoint( crossLinesB[ 0][ 0], crossLinesB[ 0][ 1]);
	NSPoint b2 = NSMakePoint( crossLinesB[ 1][ 0], crossLinesB[ 1][ 1]);
	
	NSPoint r = NSMakePoint( 0, 0);
	
	[DCMView intersectionBetweenTwoLinesA1: a1 A2: a2 B1: b1 B2: b2 result: &r];
	
	return r;
}

- (int) mouseOnLines: (NSPoint) mouseLocation
{
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotNone)
		return 0;
	
	if( displayCrossLines == NO)
		return 0;
	
	// Intersection of the lines
	NSPoint r = [self centerLines];
	
	if( r.x != 0 || r.y != 0)
	{
		mouseLocation = [self ConvertFromNSView2GL: mouseLocation];
		
		mouseLocation.x *= curDCM.pixelSpacingX;
		mouseLocation.y *= curDCM.pixelSpacingY;
		
		float f = scaleValue * curDCM.pixelSpacingX / LOD;
		
		if( mouseLocation.x > r.x - BS * f && mouseLocation.x < r.x + BS* f && mouseLocation.y > r.y - BS* f && mouseLocation.y < r.y + BS* f)
		{
			return 2;
		}
		else
		{
			float distance1, distance2;
			
			NSPoint a1 = NSMakePoint( crossLinesA[ 0][ 0], crossLinesA[ 0][ 1]);
			NSPoint a2 = NSMakePoint( crossLinesA[ 1][ 0], crossLinesA[ 1][ 1]);
			
			NSPoint b1 = NSMakePoint( crossLinesB[ 0][ 0], crossLinesB[ 0][ 1]);
			NSPoint b2 = NSMakePoint( crossLinesB[ 1][ 0], crossLinesB[ 1][ 1]);			
			
			[DCMView DistancePointLine:mouseLocation :a1 :a2 :&distance1];
			[DCMView DistancePointLine:mouseLocation :b1 :b2 :&distance2];
			
			distance1 /= curDCM.pixelSpacingX;
			distance2 /= curDCM.pixelSpacingX;
			
			if( distance1 * scaleValue < 10 || distance2 * scaleValue < 10)
			{
				return 1;
			}
		}
	}
	
	return 0;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[windowController addToUndoQueue:@"mprCamera"];
	
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
	
	[self restoreCamera];
	
	windowController.lowLOD = YES;
	
	[vrView scrollWheel: theEvent];
	
	[self updateViewMPR: NO];
	[self updateMousePosition: theEvent];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: self];	
	[windowController performSelector: @selector( delayedFullLODRendering:) withObject: self afterDelay: 0.2];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self flagsChanged: theEvent];

	[windowController addToUndoQueue:@"mprCamera"];
	
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
	
	rotateLines = NO;
	moveCenter = NO;
	
	[self restoreCamera];
	
	[vrView rightMouseDown: theEvent];
	
	[self updateViewMPR];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self flagsChanged: theEvent];
	
	[self restoreCamera];
	
	[vrView rightMouseDragged: theEvent];
	
	[self updateViewMPR: NO];
	
	[self updateMousePosition: theEvent];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
	[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.4];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	windowController.lowLOD = NO;
	[self flagsChanged: theEvent];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
	
	[self restoreCamera];
	
	[vrView rightMouseUp: theEvent];
	
	[self updateViewMPR];
	
	[self updateMousePosition: theEvent];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
	
	dontCheckRoiChange = YES;
	
	[self checkCursor];
	
	int clickCount = 1;
	
	@try
	{
		if( [theEvent type] == NSLeftMouseDown || [theEvent type] == NSRightMouseDown)
			clickCount = [theEvent clickCount];
	}
	@catch (NSException * e)
	{
		clickCount = 1;
	}
	
	if( clickCount == 2)
	{
		if( frameZoomed == NO)
		{
			splitPosition[ 0] = [[windowController mprView1] frame].origin.y + [[windowController mprView1] frame].size.height;
			splitPosition[ 1] = [[windowController mprView1] frame].origin.x + [[windowController mprView1] frame].size.width;
			
			frameZoomed = YES;
			switch( viewID)
			{
				case 1:
					[windowController.horizontalSplit setPosition: [windowController.horizontalSplit maxPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
					[windowController.verticalSplit setPosition: [windowController.verticalSplit maxPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
				break;
				
				case 2:
					[windowController.horizontalSplit setPosition: [windowController.horizontalSplit minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
					[windowController.verticalSplit setPosition: [windowController.verticalSplit maxPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
				break;
				
				case 3:
					[windowController.horizontalSplit setPosition: [windowController.horizontalSplit minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
					[windowController.verticalSplit setPosition: [windowController.verticalSplit minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
				break;
			}
		}
		else
		{
			frameZoomed = NO;
			[windowController.horizontalSplit setPosition: splitPosition[ 0] ofDividerAtIndex: 0];
			[windowController.verticalSplit setPosition: splitPosition[ 1] ofDividerAtIndex: 0];
		}
		
		[self restoreCamera];
		windowController.lowLOD = NO;
		[self updateViewMPR];
	}
	else
	{	
		[windowController addToUndoQueue:@"mprCamera"];
		
		rotateLines = NO;
		moveCenter = NO;
		
		int mouseOnLines = [self mouseOnLines: [self convertPoint:[theEvent locationInWindow] fromView:nil]];
		if( mouseOnLines == 2)
		{
			moveCenter = YES;
			
			[self mouseDragged: theEvent];
			
			[[NSCursor closedHandCursor] set];
		}
		else if( mouseOnLines == 1)
		{
			rotateLines = YES;
			
			NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
			mouseLocation.x *= curDCM.pixelSpacingX;	mouseLocation.y *= curDCM.pixelSpacingY;
			rotateLinesStartAngle = [self angleBetween: mouseLocation center: [self centerLines]] - angleMPR;
			
			[self mouseDragged: theEvent];
			
			[[NSCursor rotateAxisCursor] set];
		}
		else
		{
			long tool = [self getTool: theEvent];
			
			vrView.keep3DRotateCentered = YES;
			if( tool == tCamera3D)
			{
				if( displayCrossLines == NO || frameZoomed == YES)
					vrView.keep3DRotateCentered = NO;
				else
				{
					if( [theEvent modifierFlags] & NSAlternateKeyMask)
						vrView.keep3DRotateCentered = NO;
				}
			}
			
			[self restoreCamera];
			
			if([self is2DTool: tool])
			{
				[super mouseDown: theEvent];
				[windowController propagateWLWW: self];
				
				for( ROI *r in curRoiList)
				{
					int mode;
					
					if( [r type] == t2DPoint && r.parentROI)
					{
						mode = [r ROImode];
						if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
						{
							[[windowController viewer] deleteROI: r.parentROI];
							r.parentROI = nil;
						}
					}
				}
			}
			else
			{
				[vrView mouseDown: theEvent];
				
				if( [vrView _tool] == tRotate)
					[self updateViewMPR: NO];
				else
					[self updateViewMPR];
			}
		}
	}
}

- (void) mouseUp:(NSEvent *)theEvent
{
	[self checkCursor];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
	
	windowController.lowLOD = NO;
	
	[self restoreCamera];
	
	if( rotateLines || moveCenter)
	{
		if( moveCenter)
		{
			camera.windowCenterX = 0;
			camera.windowCenterY = 0;
			camera.forceUpdate = YES;
		}
		
		if( vrView.lowResLODFactor > 1)
		{
			windowController.mprView1.camera.forceUpdate = YES;
			windowController.mprView2.camera.forceUpdate = YES;
			windowController.mprView3.camera.forceUpdate = YES;
		}
		
		rotateLines = NO;
		moveCenter = NO;

		[self restoreCamera];
		[self updateViewMPR];
		
		[cursor set];
	}
	else
	{
		long tool = [self getTool: theEvent];
		
		if([self is2DTool:tool])
		{
			[super mouseUp: theEvent];
			[windowController propagateWLWW: self];
		
			if( tool == tNext)
				[windowController updateViewsAccordingToFrame: self];
			
			for( ROI *r in curRoiList)
			{
				int mode;
				
				if( [r type] == t2DPoint && r.parentROI == nil)
				{
					float location[ 3];
					[pix convertPixX: r.rect.origin.x pixY: r.rect.origin.y toDICOMCoords: location pixelCenter: YES];
					[self add2DPoint: location];
				}
			}
			
			[self detect2DPointInThisSlice];
		}
		else
		{
			[vrView mouseUp: theEvent];
			
			if( vrView.lowResLODFactor > 1)
			{
				windowController.mprView1.camera.forceUpdate = YES;
				windowController.mprView2.camera.forceUpdate = YES;
				windowController.mprView3.camera.forceUpdate = YES;
			}
			
			if( [vrView _tool] == tRotate)
				[self updateViewMPR: NO];
			else
				[self updateViewMPR];
		}
	}
	
	[self updateMousePosition: theEvent];
	
	dontCheckRoiChange = NO;
}

- (void) mouseDraggedImageScroll:(NSEvent *) event
{
	[self checkCursor];
	
	NSPoint current = [self currentPointInView: event];
	
	if( scrollMode == 0)
	{
		if( fabs( start.x - current.x) < fabs( start.y - current.y))
		{
			if( fabs( start.y - current.y) > 3) scrollMode = 1;
		}
		else if( fabs( start.x - current.x) >= fabs( start.y - current.y))
		{
			if( fabs( start.x - current.x) > 3) scrollMode = 2;
		}
	}
	
	float delta;
	
	if( scrollMode == 1)
		delta = ((previous.y - current.y) * 512. )/ ([self frame].size.width/2);
	else
		delta = ((current.x - previous.x) * 512. )/ ([self frame].size.width/2);
	
	[self restoreCamera];
	windowController.lowLOD = YES;
	[vrView scrollInStack: delta];
	[self updateViewMPR];
	[self updateMousePosition: event];
	windowController.lowLOD = NO;
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	[self restoreCamera];
	
	if( rotateLines)
	{
		[[NSCursor rotateAxisCursor] set];
		
		windowController.lowLOD = YES;
		
		NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
		mouseLocation.x *= curDCM.pixelSpacingX;	mouseLocation.y *= curDCM.pixelSpacingY;
		angleMPR = [self angleBetween: mouseLocation center: [self centerLines]];
		
		angleMPR -= rotateLinesStartAngle;
		
		[self updateViewMPR];
		
		[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
		[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.4];
	}
	else if( moveCenter)
	{
		windowController.lowLOD = YES;
		[vrView setWindowCenter: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
		[self updateViewMPR];
		
		[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
		[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.4];
	}
	else
	{
		long tool = [self getTool: theEvent];
		
		if([self is2DTool:tool])
		{
			[super mouseDragged: theEvent];
			[windowController propagateWLWW: self];
		}
		else
		{
			float before[ 9], after[ 9];
			
			windowController.lowLOD = YES;
			
			if( [vrView _tool] == tRotate)
				[self.pix orientation: before];
			
			[vrView mouseDragged: theEvent];
			
			if( [vrView _tool] == tRotate)
			{
				[vrView getCosMatrix: after];
				angleMPR -= [MPRController angleBetweenVector: after andPlane: before];
				
				[self updateViewMPR: NO];
			}
			else if( [vrView _tool] == tZoom) [self updateViewMPR: NO];
			else [self updateViewMPR];
			
			[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
			[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.4];
		}
	}
	
	[self updateMousePosition: theEvent];
}

- (void) updateMousePosition: (NSEvent*) theEvent
{
	float location[ 3];
	
	[pix convertPixX: mouseXPos pixY: mouseYPos toDICOMCoords: location pixelCenter: YES];

	Point3D *pt = [Point3D pointWithX: location[ 0] y: location[ 1] z: location[ 2]];
	windowController.mousePosition = pt;
	windowController.mouseViewID = viewID;
}

- (void) mouseMoved: (NSEvent *) theEvent
{
	NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
	
	if( view == self)
	{
		[super mouseMoved: theEvent];
		
		int mouseOnLines = [self mouseOnLines: [self convertPoint:[theEvent locationInWindow] fromView:nil]];
		if( mouseOnLines==2)
		{
			if( [theEvent type] == NSLeftMouseDragged) [[NSCursor closedHandCursor] set];
			else [[NSCursor openHandCursor] set];
		}
		else if( mouseOnLines==1)
		{
			[[NSCursor rotateAxisCursor] set];
		}
		else
		{
			[cursor set];
		}
		
		[self updateMousePosition: theEvent];
	}
	else
	{
		[view mouseMoved:theEvent];
	}
}

#pragma mark-

@end
 