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

//#define VIEW_1_RED 1.0f
//#define VIEW_1_GREEN 0.1f
//#define VIEW_1_BLUE 0.0f
//#define VIEW_1_ALPHA 1.0f
//
//#define VIEW_2_RED 0.6f
//#define VIEW_2_GREEN 0.0f
//#define VIEW_2_BLUE 1.0f
//#define VIEW_2_ALPHA 1.0f
//
//#define VIEW_3_RED 0.0f
//#define VIEW_3_GREEN 0.5f
//#define VIEW_3_BLUE 1.0f
//#define VIEW_3_ALPHA 1.0f

#define VIEW_COLOR_LABEL_SIZE 25

static int splitPosition[ 2];
static BOOL frameZoomed = NO;

@implementation MPRDCMView

@synthesize pix, camera, angleMPR, vrView, viewExport, toIntervalExport, fromIntervalExport, rotateLines, moveCenter;

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
	
	rotation = 0;
	
	pix = [pixList lastObject];
	
	currentTool = t3DRotate;
	
	frameZoomed = NO;
	
	windowController = [self windowController];
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

- (BOOL) hasCameraMoved: (Camera*) currentCamera
{
	if( currentCamera.position.x != camera.position.x) return YES;
	if( currentCamera.position.y != camera.position.y) return YES;
	if( currentCamera.position.z != camera.position.z) return YES;

	if( currentCamera.focalPoint.x != camera.focalPoint.x) return YES;
	if( currentCamera.focalPoint.y != camera.focalPoint.y) return YES;
	if( currentCamera.focalPoint.z != camera.focalPoint.z) return YES;

	if( currentCamera.viewUp.x != camera.viewUp.x) return YES;
	if( currentCamera.viewUp.y != camera.viewUp.y) return YES;
	if( currentCamera.viewUp.z != camera.viewUp.z) return YES;

	if( currentCamera.viewAngle != camera.viewAngle) return YES;
	if( currentCamera.eyeAngle != camera.eyeAngle) return YES;
	
	return NO;

}

- (BOOL) hasCameraChanged: (Camera*) currentCamera
{
	if( camera.forceUpdate)
	{
		camera.forceUpdate = NO;
		return YES;
	}
	
	if( currentCamera.position.x != camera.position.x) return YES;
	if( currentCamera.position.y != camera.position.y) return YES;
	if( currentCamera.position.z != camera.position.z) return YES;

	if( currentCamera.focalPoint.x != camera.focalPoint.x) return YES;
	if( currentCamera.focalPoint.y != camera.focalPoint.y) return YES;
	if( currentCamera.focalPoint.z != camera.focalPoint.z) return YES;

	if( currentCamera.viewUp.x != camera.viewUp.x) return YES;
	if( currentCamera.viewUp.y != camera.viewUp.y) return YES;
	if( currentCamera.viewUp.z != camera.viewUp.z) return YES;

	if( currentCamera.viewAngle != camera.viewAngle) return YES;
	if( currentCamera.eyeAngle != camera.eyeAngle) return YES;
	if( currentCamera.parallelScale != camera.parallelScale) return YES;

	if( currentCamera.clippingRangeNear != camera.clippingRangeNear) return YES;
	if( currentCamera.clippingRangeFar != camera.clippingRangeFar) return YES;
	
	if( currentCamera.LOD < camera.LOD) return YES;
	
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
		BOOL cameraMoved = [self hasCameraMoved: currentCamera];
		
		if( [self frame].size.width > 0 && [self frame].size.height > 0)
			[vrView render];
		
		float *imagePtr = [vrView imageInFullDepthWidth: &w height: &h isRGB: &isRGB];
		
		[self saveCamera];
		
		if( imagePtr)
		{
			if( [pix pwidth] == w && [pix pheight] == h && isRGB == [pix isRGB])
			{
				memcpy( [pix fImage], imagePtr, w*h*sizeof( float));
				free( imagePtr);
			}
			else
			{
				[pix setRGB: isRGB];
				[pix setfImage: imagePtr];
				[pix setPwidth: w];
				[pix setPheight: h];
				
				NSMutableArray *savedROIs = nil;
				if( cameraMoved == NO)
					savedROIs = [[curRoiList copy] autorelease];
				
				[self setIndex: 0];
				
				if( cameraMoved == NO)
				{
					[curRoiList addObjectsFromArray: savedROIs];
				}
			}
			float porigin[ 3];
			[vrView getOrigin: porigin windowCentered: YES sliceMiddle: YES];
			[pix setOrigin: porigin];
			
			float resolution = [vrView getResolution] * [vrView imageSampleDistance];
			[pix setPixelSpacingX: resolution];
			[pix setPixelSpacingY: resolution];
			
			float orientation[ 9];
			[vrView getOrientation: orientation];
			[pix setOrientation: orientation];
			[pix setSliceThickness: [vrView getClippingRangeThicknessInMm]];
			
			[self setWLWW: previousWL :previousWW];
			[self setScaleValue: [vrView imageSampleDistance]];
			
			for( ROI* r in curRoiList)
			{
				[r setOriginAndSpacing: resolution : resolution :[DCMPix originCorrectedAccordingToOrientation: pix] :NO];
			}
		}
		
		if( blendingView)
		{
			[blendingView getWLWW: &previousWL :&previousWW];
			
			[vrView renderBlendedVolume];
			
			float *blendedImagePtr = [vrView imageInFullDepthWidth: &w height: &h isRGB: &isRGB blendingView: YES];
			
			DCMPix *bPix = [blendingView curDCM];
			
			if( [bPix pwidth] == w && [bPix pheight] == h && isRGB == [bPix isRGB])
			{
				memcpy( [bPix fImage], blendedImagePtr, w*h*sizeof( float));
				free( blendedImagePtr);
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
			
			float resolution = [vrView getResolution] * [vrView blendingImageSampleDistance];
			[bPix setPixelSpacingX: resolution];
			[bPix setPixelSpacingY: resolution];
			
			float orientation[ 9];
			[vrView getOrientation: orientation];
			[bPix setOrientation: orientation];
			[bPix setSliceThickness: [vrView getClippingRangeThicknessInMm]];
			
			[blendingView setWLWW: previousWL :previousWW];
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

- (void) subDrawRect: (NSRect) r
{
	if( [stringID isEqualToString: @"export"])
		return;
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable(GL_BLEND);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);
	
	if( windowController.displayCrossLines)
	{
		// All pix have the same thickness
		float thickness = [pix sliceThickness];
		
		switch( viewID)
		{
			case 1:
				glColor4f ([windowController.colorAxis2 redComponent], [windowController.colorAxis2 greenComponent], [windowController.colorAxis2 blueComponent], [windowController.colorAxis2 alphaComponent]);
				if( crossLinesA[ 0][ 0] != HUGE_VALF)
				{
					if( thickness > 2)
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: 0];
						
						glLineWidth(1.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: -thickness/2.];
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: thickness/2.];
					}
					else
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: 0];
					}
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
					{
						glLineWidth(1.0);
						
						if( fromIntervalExport > 0)
						{
							for( int i = 0; i < fromIntervalExport; i++)
								[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
						}
					
						if( toIntervalExport > 0)
						{
							for( int i = 0; i < toIntervalExport; i++)
								[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
						}
					}
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
					{
						for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
						{
							glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
							[self drawCrossLines: crossLinesA ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
							glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
						}
					}
				}
				glColor4f ([windowController.colorAxis3 redComponent], [windowController.colorAxis3 greenComponent], [windowController.colorAxis3 blueComponent], [windowController.colorAxis3 alphaComponent]);
				if( crossLinesB[ 0][ 0] != HUGE_VALF)
				{
					if( thickness > 2)
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: 0];
					
						glLineWidth(1.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: -thickness/2.];
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: thickness/2.];
					}
					else
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: 0];
					}
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
					{
						glLineWidth(1.0);
						
						if( fromIntervalExport > 0)
						{
							for( int i = 0; i < fromIntervalExport; i++)
								[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
						}
					
						if( toIntervalExport > 0)
						{
							for( int i = 0; i < toIntervalExport; i++)
								[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
						}
					}
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
					{
						for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
						{
							glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
							[self drawCrossLines: crossLinesB ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
							glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
						}
					}
				}
			break;
			
			case 2:
				glColor4f ([windowController.colorAxis1 redComponent], [windowController.colorAxis1 greenComponent], [windowController.colorAxis1 blueComponent], [windowController.colorAxis1 alphaComponent]);
				if( crossLinesA[ 0][ 0] != HUGE_VALF)
				{
					if( thickness > 2)
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: 0];
						
						glLineWidth(1.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: -thickness/2.];
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: thickness/2.];
					}
					else
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: 0];
					}
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
					{
						glLineWidth(1.0);
						
						if( fromIntervalExport > 0)
						{
							for( int i = 0; i < fromIntervalExport; i++)
								[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
						}
					
						if( toIntervalExport > 0)
						{
							for( int i = 0; i < toIntervalExport; i++)
								[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
						}
					}
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
					{
						for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
						{
							glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
							[self drawCrossLines: crossLinesA ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
							glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
						}
					}
				}
				
				glColor4f ([windowController.colorAxis3 redComponent], [windowController.colorAxis3 greenComponent], [windowController.colorAxis3 blueComponent], [windowController.colorAxis3 alphaComponent]);
				if( crossLinesB[ 0][ 0] != HUGE_VALF)
				{
					if( thickness > 2)
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: 0];
						
						glLineWidth(1.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: -thickness/2.];
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: thickness/2.];
					}
					else
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: 0];
					}
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
					{
						glLineWidth(1.0);
						
						if( fromIntervalExport > 0)
						{
							for( int i = 0; i < fromIntervalExport; i++)
								[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
						}
					
						if( toIntervalExport > 0)
						{
							for( int i = 0; i < toIntervalExport; i++)
								[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
						}
					}
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
					{
						for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
						{
							glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
							[self drawCrossLines: crossLinesB ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
							glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
						}
					}
				}
			break;
			
			case 3:
				glColor4f ([windowController.colorAxis1 redComponent], [windowController.colorAxis1 greenComponent], [windowController.colorAxis1 blueComponent], [windowController.colorAxis1 alphaComponent]);
				if( crossLinesA[ 0][ 0] != HUGE_VALF)
				{
					if( thickness > 2)
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: 0];
						
						glLineWidth(1.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: -thickness/2.];
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: thickness/2.];
					}
					else
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: 0];
					}
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
					{
						glLineWidth(1.0);
						
						if( fromIntervalExport > 0)
						{
							for( int i = 0; i < fromIntervalExport; i++)
								[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
						}
					
						if( toIntervalExport > 0)
						{
							for( int i = 0; i < toIntervalExport; i++)
								[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
						}
					}
					
					if( viewExport == 0 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
					{
						for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
						{
							glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
							[self drawCrossLines: crossLinesA ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
							glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
						}
					}
				}
				
				glColor4f ([windowController.colorAxis2 redComponent], [windowController.colorAxis2 greenComponent], [windowController.colorAxis2 blueComponent], [windowController.colorAxis2 alphaComponent]);
				if( crossLinesB[ 0][ 0] != HUGE_VALF)
				{
					if( thickness > 2)
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: 0];
						
						glLineWidth(1.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: -thickness/2.];
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: thickness/2.];
					}
					else
					{
						glLineWidth(2.0);
						[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: 0];
					}
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 0)
					{
						glLineWidth(1.0);
						
						if( fromIntervalExport > 0)
						{
							for( int i = 0; i < fromIntervalExport; i++)
								[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
						}
					
						if( toIntervalExport > 0)
						{
							for( int i = 0; i < toIntervalExport; i++)
								[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
						}
					}
					
					if( viewExport == 1 && windowController.dcmMode == 0 && windowController.dcmSeriesMode == 1) // Rotation
					{
						for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
						{
							glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
							[self drawCrossLines: crossLinesB ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
							glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
						}
					}
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
	
	if( windowController.displayCrossLines && windowController.displayMousePosition && !windowController.mprView1.rotateLines && !windowController.mprView2.rotateLines && !windowController.mprView3.rotateLines
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
	
	if( windowController.displayCrossLines == NO)
		return 0;
	
	// Intersection of the lines
	NSPoint r = [self centerLines];
	
	if( r.x != 0 || r.y != 0)
	{
		mouseLocation = [self ConvertFromNSView2GL: mouseLocation];
		
		mouseLocation.x *= curDCM.pixelSpacingX;
		mouseLocation.y *= curDCM.pixelSpacingY;
		
		float f = scaleValue * curDCM.pixelSpacingX / [windowController LOD];
		
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
	
	[vrView setLODLow: YES]; 
	
	[vrView scrollWheel: theEvent];
	
	[self updateViewMPR];
	[self updateMousePosition: theEvent];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: self];	
	[windowController performSelector: @selector( delayedFullLODRendering:) withObject: self afterDelay: 0.3];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
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
	[self restoreCamera];
	
	[vrView rightMouseDragged: theEvent];
	
	[self updateViewMPR];
	
	[self updateMousePosition: theEvent];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
	[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.3];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
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
	
	if( [theEvent clickCount] == 2)
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
		[vrView setLODLow: NO];
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
			[[NSCursor closedHandCursor] set];
		}
		else if( mouseOnLines == 1)
		{
			rotateLines = YES;
			
			NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
			mouseLocation.x *= curDCM.pixelSpacingX;	mouseLocation.y *= curDCM.pixelSpacingY;
			rotateLinesStartAngle = [self angleBetween: mouseLocation center: [self centerLines]] - angleMPR;
			
			[[NSCursor rotateAxisCursor] set];
		}
		else
		{
			long tool = [self getTool: theEvent];
			
			vrView.keep3DRotateCentered = YES;
			if( tool == tCamera3D)
			{
				if( windowController.displayCrossLines == NO)
					vrView.keep3DRotateCentered = NO;
				else
				{
					if( [theEvent modifierFlags] & NSAlternateKeyMask)
						vrView.keep3DRotateCentered = NO;
				}
			}
			
			[self restoreCamera];
			
			if([self is2DTool:tool])
			{
				[super mouseDown: theEvent];
				[windowController propagateWLWW: self];
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
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
	
	[self restoreCamera];
	
	if( rotateLines || moveCenter)
	{
		[vrView setLODLow: NO];
		if( moveCenter)
		{
			camera.windowCenterX = 0;
			camera.windowCenterY = 0;
			camera.forceUpdate = YES;
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
		}
		else
		{
			[vrView mouseUp: theEvent];
			
			if( [vrView _tool] == tRotate)
				[self updateViewMPR: NO];
			else
				[self updateViewMPR];
		}
	}
	
	[self updateMousePosition: theEvent];
}

- (void) mouseDraggedImageScroll:(NSEvent *) event
{
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
	[vrView setLODLow: YES];
	[vrView scrollInStack: delta];
	[self updateViewMPR];
	[self updateMousePosition: event];
	[vrView setLODLow: NO];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	[self restoreCamera];
	
	if( rotateLines)
	{
		[[NSCursor rotateAxisCursor] set];
		
		[vrView setLODLow: YES];
		
		NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
		mouseLocation.x *= curDCM.pixelSpacingX;	mouseLocation.y *= curDCM.pixelSpacingY;
		angleMPR = [self angleBetween: mouseLocation center: [self centerLines]];
		
		angleMPR -= rotateLinesStartAngle;
		
		[self updateViewMPR];
		
		[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
		[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.3];
	}
	else if( moveCenter)
	{
		[vrView setLODLow: YES];
		[vrView setWindowCenter: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
		[self updateViewMPR];
		
		[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
		[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.3];
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
			if( [vrView _tool] == tRotate)
				[self.pix orientation: before];
			
			[vrView mouseDragged: theEvent];
			
			if( [vrView _tool] == tRotate)
			{
				[vrView getCosMatrix: after];
				angleMPR -= [MPRController angleBetweenVector: after andPlane: before];
				
				[self updateViewMPR: NO];
			}
			else [self updateViewMPR];
			
			[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
			[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.3];
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
 