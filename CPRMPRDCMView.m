/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import "CPRController.h"
#import "CPRMPRDCMView.h"
#import "VRController.h"
#import "VRView.h"
#import "DCMCursor.h"
#import "ROI.h"
#import "Notifications.h"
#import "CPRController.h"
#import "CPRCurvedPath.h"
#import "CPRDisplayInfo.h"
#import "CPRBezierPath.h"

#include <OpenGL/CGLMacro.h>


static float deg2rad = 3.14159265358979/180.0; 

#define CROSS(dest,v1,v2) \
dest[0]=v1[1]*v2[2]-v1[2]*v2[1]; \
dest[1]=v1[2]*v2[0]-v1[0]*v2[2]; \
dest[2]=v1[0]*v2[1]-v1[1]*v2[0];

static BOOL arePlanesParallel( float *Pn1, float *Pn2)
{
	float u[ 3];
	
	CROSS(u, Pn1, Pn2);
	
	float    ax = (u[0] >= 0 ? u[0] : -u[0]);
    float    ay = (u[1] >= 0 ? u[1] : -u[1]);
    float    az = (u[2] >= 0 ? u[2] : -u[2]);
	
    if ((ax+ay+az) < 0.001)
		return YES;
	
    return NO;
}

#define VIEW_COLOR_LABEL_SIZE 25

static int splitPosition[3];
static BOOL frameZoomed = NO;

static CGFloat CPRMPRDCMViewCurveMouseTrackingDistance = 20.0;

@interface CPRMPRDCMView ()

- (void)drawCurvedPathInGL;
- (void)drawCircleAtPoint:(NSPoint)point pointSize:(CGFloat)pointSize;
- (void)drawCircleAtPoint:(NSPoint)point;
- (void)sendWillEditCurvedPath;
- (void)sendDidUpdateCurvedPath;
- (void)sendDidEditCurvedPath;
- (void)sendWillEditDisplayInfo;
- (void)sendDidEditDisplayInfo;
@end

@implementation CPRMPRDCMView

@synthesize delegate;
@synthesize curvedPath;
@synthesize displayInfo;
@synthesize dontUseAutoLOD, pix, camera, angleMPR, vrView, viewExport, toIntervalExport, fromIntervalExport, rotateLines, moveCenter, displayCrossLines, LOD;

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
			if( vrView.renderingMode == 1 || vrView.renderingMode == 3 || vrView.renderingMode == 2) return YES; // MIP
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
		case tCurvedROI:
			return YES;
            break;
	}
	
	return NO;
}

- (void) setDCMPixList:(NSMutableArray*)pixList filesList:(NSArray*)files roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
{
	[super setPixels:pixList files:files rois:rois firstImage:firstImage level:type reset:reset];
    
	[[NSNotificationCenter defaultCenter]	addObserver: self
                                             selector: @selector(removeROI:)
                                                 name: OsirixRemoveROINotification
                                               object: nil];
    
    
	rotation = 0;
	
	pix = [pixList lastObject];
	
	currentTool = t3DRotate;
	
	frameZoomed = NO;
	displayCrossLines = YES;
	
	windowController = [self windowController];
	
	[windowController updateToolbarItems];
    draggedToken = CPRCurvedPathControlTokenNone;
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

- (void)setCurvedPath:(CPRCurvedPath *)newCurvedPath
{
    if (curvedPath != newCurvedPath) {
        [curvedPath release];
        curvedPath = [newCurvedPath copy];
        [self setNeedsDisplay:YES];
    }
}

- (void)setDisplayInfo:(CPRDisplayInfo *)newDisplayInfo
{
    if (displayInfo != newDisplayInfo) {
        [displayInfo release];
        displayInfo = [newDisplayInfo copy];
        [self setNeedsDisplay:YES];
    }
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
    [curvedPath release];
    [displayInfo release];
	[camera release];
	
	[super dealloc];
}

-(void) updateViewMPR
{
	[self updateViewMPR: YES];
}

- (void) setLOD: (float) l
{
	LOD = l;
}

- (void) updateViewMPR:(BOOL) computeCrossReferenceLines
{
	long h, w;
	float previousWW, previousWL;
	BOOL isRGB;
	BOOL previousOriginInPlane = NO;
	
	[self getWLWW: &previousWL :&previousWW];
	
	Camera *currentCamera = [vrView cameraWithThumbnail: NO];
	
	if( [self hasCameraChanged: currentCamera] == YES)
	{
		// AutoLOD
		if( dontUseAutoLOD == NO && lastRenderingWasMoveCenter == NO)
		{
			DCMPix *o = [windowController originalPix];
			
			float minimumResolution = [o pixelSpacingX];
			
			if( minimumResolution > [o pixelSpacingY])
				minimumResolution = [o pixelSpacingY];
			
			if( minimumResolution > [o sliceInterval])
				minimumResolution = [o sliceInterval];
			
			if( windowController.clippingRangeThickness <= 3)
				minimumResolution *= 0.9;
			else
				minimumResolution *= 0.7;
			
			if( minimumResolution > previousPixelSpacing && previousPixelSpacing != 0)
				LOD *= ( minimumResolution / previousPixelSpacing);
			
			if( previousResolution == 0)
				previousResolution = [vrView getResolution];
			
			float currentResolution = [vrView getResolution];
			
			if( previousResolution < currentResolution)
				LOD *= (previousResolution / currentResolution);
			
			if( LOD < windowController.LOD)
				LOD = windowController.LOD;
			
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
			if( windowController.maxMovieIndex > 1 && (windowController.clippingRangeMode == 1 || windowController.clippingRangeMode == 3 || windowController.clippingRangeMode == 2))	//To avoid the wrong pixel value bug...
				[vrView prepareFullDepthCapture];
			
			if( moveCenter)
			{
				lastRenderingWasMoveCenter = YES;
				[vrView setLOD: 100];	// We dont need to really compute the image - we just want image origin for the other views.
			}
			else lastRenderingWasMoveCenter = NO;
			
			[vrView render];
		}
		
		float *imagePtr = nil;
		
		if( moveCenter)
		{
			imagePtr = [pix fImage];
			w = [pix pwidth];
			h = [pix pheight];
			isRGB = [pix isRGB];
			
			[vrView setLOD: LOD];
		}
		else
			imagePtr = [vrView imageInFullDepthWidth: &w height: &h isRGB: &isRGB];
		
		////
		float orientation[ 9];
		[vrView getOrientation: orientation];
		
		float location[ 3] = {previousOrigin[ 0], previousOrigin[ 1], previousOrigin[ 2]}, orig[ 3] = {currentCamera.position.x, currentCamera.position.y, currentCamera.position.z}, locationTemp[ 3];
		float distance = [DCMView pbase_Plane: location :orig :&(orientation[ 6]) :locationTemp];
		if( distance < pix.sliceThickness / 2.)
			previousOriginInPlane = YES;
		else
			previousOriginInPlane = NO;
		
		[self saveCamera];
		
		if( imagePtr)
		{
			BOOL cameraMoved = YES;
			
			if( [curRoiList count] > 0)
			{
				if( previousOriginInPlane == NO || arePlanesParallel( orientation+6, previousOrientation+6) == NO)
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
			
			[self willChangeValueForKey:@"plane"];
			[pix setOrientation: orientation];
			[self didChangeValueForKey:@"plane"];
			[pix setSliceThickness: [vrView getClippingRangeThicknessInMm]];
			
			[self setWLWW: previousWL :previousWW];
			
			if( !moveCenter)
			{
				[self setScaleValue: [vrView imageSampleDistance]];
				
				float rotationPlane = 0;
				if( cameraMoved == NO && [curRoiList count] > 0)
				{
					if( previousOrientation[ 0] != 0 || previousOrientation[ 1] != 0 || previousOrientation[ 2] != 0)
						rotationPlane = -[CPRController angleBetweenVector: orientation andPlane: previousOrientation];
					if( fabs( rotationPlane) < 0.01)
						rotationPlane = 0;
				}
				
				NSPoint rotationCenter = NSMakePoint( [pix pwidth]/2., [pix pheight]/2.);
				
				for( ROI* r in curRoiList)
				{
					if( rotationPlane)
					{
						[r setOriginAndSpacing: resolution : resolution : r.imageOrigin :NO];
						
						[r rotate: rotationPlane :rotationCenter];
						r.imageOrigin = [DCMPix originCorrectedAccordingToOrientation: pix];
						r.pixelSpacingX = [pix pixelSpacingX];
						r.pixelSpacingY = [pix pixelSpacingY];
					}
					else
						[r setOriginAndSpacing: resolution : resolution :[DCMPix originCorrectedAccordingToOrientation: pix] :NO];
				}
				
				[pix orientation: previousOrientation];
				previousOrigin[ 0] = currentCamera.position.x;
				previousOrigin[ 1] = currentCamera.position.y;
				previousOrigin[ 2] = currentCamera.position.z;
				
				[self detect2DPointInThisSlice];
				
				previousResolution = [vrView getResolution];
				previousPixelSpacing = [pix pixelSpacingX];
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
//	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
//	
//	glLineWidth(1.0);
//    
//	if( fromIntervalExport > 0)
//	{
//		for( int i = 1; i <= fromIntervalExport; i++)
//			[self drawCrossLines: sft ctx: cgl_ctx withShift: -i * [windowController dcmInterval]];
//	}
//	
//	if( !windowController.dcmBatchReverse)
//		[self drawCrossLines: sft ctx: cgl_ctx withShift: -fromIntervalExport * [windowController dcmInterval] showPoint: YES];
//	
//	if( toIntervalExport > 0)
//	{
//		for( int i = 1; i <= toIntervalExport; i++)
//			[self drawCrossLines: sft ctx: cgl_ctx withShift: i * [windowController dcmInterval]];
//	}
//	
//	if( windowController.dcmBatchReverse)
//		[self drawCrossLines: sft ctx: cgl_ctx withShift: toIntervalExport * [windowController dcmInterval] showPoint: YES];
}

- (void) drawRotationLines: (float[2][3]) sft
{
//	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
//	
//	for( int i = 1; i < windowController.dcmNumberOfFrames; i++)
//	{
//		glRotatef( (float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
//		[self drawCrossLines: sft ctx: cgl_ctx perpendicular: NO withShift: 0 half: YES];
//		glRotatef( -(float) (i * windowController.dcmRotation) / (float) windowController.dcmNumberOfFrames, 0, 0, 1);
//	}
}

- (void) drawTextualData:(NSRect) size :(long) annotations
{
	float copyScale = scaleValue;
	scaleValue = 1;
	[super drawTextualData: size :annotations];
	scaleValue = copyScale;
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
	
	[self drawCurvedPathInGL];
	
	NSString *planeName;
	for (planeName in [displayInfo planesWithMouseVectors]) {
		if ([planeName  isEqualToString:[self planeName]]) {
			CPRVector cursorVector;
			CPRAffineTransform3D transform;
			[self colorForView:viewID];
			glEnable(GL_POINT_SMOOTH);
			glPointSize(8);
			transform = CPRAffineTransform3DConcat(CPRAffineTransform3DInvert([self pixToDicomTransform]), [self pixToSubDrawRectTransform]);
			cursorVector = CPRVectorApplyTransform([displayInfo mouseVectorForPlane:planeName], transform);
			glBegin(GL_POINTS);
			glVertex2f(cursorVector.x, cursorVector.y);
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

-(void) setCurrentTool:(short) i
{
	if( i != tRepulsor)
		[super setCurrentTool: i];
}

- (void)keyDown:(NSEvent *)theEvent
{
    unichar c = [[theEvent characters] characterAtIndex:0];
    
	long tool = [self getTool: theEvent];
	
	if( c ==  ' ' || c == 27) // 27 : escape
	{
		[windowController keyDown:theEvent];
	}
	else if( tool == tCurvedROI && (c == NSDeleteCharacter || c == NSDeleteFunctionKey))
	{
		if ([CPRCurvedPath controlTokenIsNode:draggedToken])
		{
			[self sendWillEditCurvedPath];
			[curvedPath removeNodeAtIndex:[CPRCurvedPath nodeIndexForToken:draggedToken]];
			[self sendDidUpdateCurvedPath];
			[self sendDidEditCurvedPath];
			draggedToken = CPRCurvedPathControlTokenNone;
			[self setNeedsDisplay:YES];
		}
		else // Delete the entire curve?
		{
			if( NSRunInformationalAlertPanel(	NSLocalizedString(@"Delete the Curve", nil),
											 NSLocalizedString(@"Are you sure you want to delete the entire curve?", nil),
											 NSLocalizedString(@"OK",nil),
											 NSLocalizedString(@"Cancel",nil),
											 nil) == NSAlertDefaultReturn)
			{
				[self sendWillEditCurvedPath];
				while( curvedPath.nodes.count > 0)
					[curvedPath removeNodeAtIndex: 0];
				[self sendDidUpdateCurvedPath];
				[self sendDidEditCurvedPath];
				[self setNeedsDisplay:YES];
			}
		}
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
			ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :p.pixelSpacingX :p.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: p]] autorelease];
			
			[new2DPointROI setROIRect: NSMakeRect( sc[ 0], sc[ 1], 0, 0)];
			
			[[viewer2D imageView] roiSet:new2DPointROI];
			[[[viewer2D roiList] objectAtIndex: sc[ 2]] addObject: new2DPointROI];
			
			// notify the change
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object: new2DPointROI userInfo: nil];
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

//- (BOOL)acceptsFirstResponder
//{
//	return NO;
//}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
	return YES;
}

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
	
	if( LOD == 0)
		return 0;
	
	if( curDCM.pixelSpacingX == 0)
		return 0;
	
	// Intersection of the lines
	NSPoint r = [self centerLines];
	
	if( r.x != 0 || r.y != 0)
	{
		mouseLocation = [self ConvertFromNSView2GL: mouseLocation];
		
		mouseLocation.x *= curDCM.pixelSpacingX;
		mouseLocation.y *= curDCM.pixelSpacingY;
		
		float f = curDCM.pixelSpacingX / LOD;	//scaleValue * 
		
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
	NSPoint mouseLocation;
	
	[windowController addToUndoQueue:@"mprCamera"];
	
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
	
	if (draggedToken != CPRCurvedPathControlTokenNone) {
		mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView: nil];
		[self sendWillEditCurvedPath];
        [curvedPath moveControlToken:draggedToken toPoint:mouseLocation transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])];
		[self sendDidEditCurvedPath];
		
		if ([CPRCurvedPath controlTokenIsNode:draggedToken]) {
			[self sendWillEditDisplayInfo];
            displayInfo.draggedPosition = [curvedPath relativePositionForControlToken:draggedToken];
			[self sendDidEditDisplayInfo];
        }
		
        [self setNeedsDisplay:YES];
    }	
	
	[self restoreCamera];
	
	windowController.lowLOD = YES;
	
	[vrView scrollWheel: theEvent];
	
	[self updateViewMPR: NO];
	[self updateMousePosition: theEvent];
	
	[windowController delayedFullLODRendering: self];
	
//	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: self];	
//	[windowController performSelector: @selector( delayedFullLODRendering:) withObject: self afterDelay: 0.2];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self flagsChanged: theEvent];
    
	[windowController addToUndoQueue:@"mprCamera"];
	
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
	
	[self magicTrick];
	
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
	
	windowController.lowLOD = YES;
	
	[vrView rightMouseDragged: theEvent];
	
	[self updateViewMPR: NO];
	
	[self updateMousePosition: theEvent];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
	[windowController performSelector: @selector( delayedFullLODRendering:) withObject: nil afterDelay: 0.4];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self flagsChanged: theEvent];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: windowController selector:@selector( delayedFullLODRendering:) object: nil];
	
	windowController.lowLOD = NO;
	
	windowController.mprView1.LOD *= 0.9;
	windowController.mprView2.LOD *= 0.9;
	windowController.mprView3.LOD *= 0.9;
	
	[self restoreCamera];
	
	[vrView rightMouseUp: theEvent];
    
	if( vrView.lowResLODFactor > 1)
	{
		windowController.mprView1.camera.forceUpdate = YES;
		windowController.mprView2.camera.forceUpdate = YES;
		windowController.mprView3.camera.forceUpdate = YES;
	}
    
	[self updateViewMPR];
	
	[self updateMousePosition: theEvent];
}

- (void) magicTrick	// Dont ask me to explain this function... it's just magic : rendering time is increased by 2 after this call...
{
	[self restoreCamera];
	camera.forceUpdate = YES;
	dontUseAutoLOD = YES;
	moveCenter = YES;
	[self updateViewMPR: NO];
	moveCenter = NO;
	dontUseAutoLOD = NO;
}

- (void) mouseDown:(NSEvent *)theEvent
{
    CGFloat relativePositionOnCurve;
    CGFloat distanceToCurve;
	
	if( [[self window] firstResponder] != self)
	{
		[[self window] makeFirstResponder: self];
		return;
	}
	
	dontCheckRoiChange = YES;
	
	[self checkCursor];
	
	int clickCount = 1;
	
	@try
	{
		if( [theEvent type] ==	NSLeftMouseDown || [theEvent type] ==	NSRightMouseDown || [theEvent type] ==	NSLeftMouseUp || [theEvent type] == NSRightMouseUp)
			clickCount = [theEvent clickCount];
	}
	@catch (NSException * e)
	{
		clickCount = 1;
	}
	
	if( clickCount == 2)
	{
		long tool = [self getTool: theEvent];
		
		if( tool == tText)
		{
			[[self windowController] roiGetInfo: self];
		}
		else if( tool == tCurvedROI)
		{
			if( windowController.curvedPathCreationMode)
			{
				windowController.curvedPathCreationMode = NO;
				draggedToken = CPRCurvedPathControlTokenNone;
			}
			else
			{
				NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView: nil];
				CPRCurvedPathControlToken token = [curvedPath controlTokenNearPoint:mouseLocation transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])];
				if ([CPRCurvedPath controlTokenIsNode:token])
				{
					[windowController CPRView:self setCrossCenter:[[curvedPath.nodes objectAtIndex: [CPRCurvedPath nodeIndexForToken: token]] CPRVectorValue]];
				}
			}
		}
		else
		{
			if( frameZoomed == NO)
			{
				splitPosition[0] = [[windowController mprView1] frame].origin.x + [[windowController mprView1] frame].size.width; // vert
				splitPosition[1] = [[windowController mprView1] frame].origin.y + [[windowController mprView1] frame].size.height; // hori12
				splitPosition[2] = [[windowController mprView3] frame].origin.y + [[windowController mprView3] frame].size.height; // horiz2
				
				frameZoomed = YES;
				switch( viewID)
				{
					case 1:
						[windowController.verticalSplit setPosition: [windowController.verticalSplit maxPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
						[windowController.horizontalSplit1 setPosition: [windowController.horizontalSplit1 maxPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
                        break;
                        
					case 2:
						[windowController.verticalSplit setPosition: [windowController.verticalSplit maxPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
						[windowController.horizontalSplit1 setPosition: [windowController.horizontalSplit1 minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
                        break;
                        
					case 3:
						[windowController.verticalSplit setPosition: [windowController.verticalSplit minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
						[windowController.horizontalSplit2 setPosition: [windowController.horizontalSplit2 maxPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
                        break;
				}
			}
			else
			{
				frameZoomed = NO;
				[windowController.verticalSplit setPosition: splitPosition[ 0] ofDividerAtIndex: 0];
				[windowController.horizontalSplit1 setPosition: splitPosition[ 1] ofDividerAtIndex: 0];
				[windowController.horizontalSplit2 setPosition: splitPosition[ 2] ofDividerAtIndex: 0];
			}
			
			[self restoreCamera];
			windowController.lowLOD = NO;
			[self updateViewMPR];
		}
	}
	else
	{
		[self magicTrick];
		
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
				if( tool != tCurvedROI)
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
				else // tool == tCurvedROI
				{
					[super mouseDown: theEvent];
					[self deleteMouseDownTimer];
					
					NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView: nil];
					
					if( windowController.curvedPathCreationMode == NO && curvedPath.nodes.count == 0)
						windowController.curvedPathCreationMode = YES;
					
					if (windowController.curvedPathCreationMode)
					{
						draggedToken = [curvedPath controlTokenNearPoint:mouseLocation transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])];
						
//						if( draggedToken != CPRCurvedPathControlTokenNone && [CPRCurvedPath nodeIndexForToken: draggedToken] > 1) // Two clicks on the last point to close the curved and stop edition
//						{
//							windowController.curvedPathCreationMode = NO;
//							draggedToken = CPRCurvedPathControlTokenNone;
//						}
						if ([CPRCurvedPath controlTokenIsNode:draggedToken])
						{
							[self sendWillEditCurvedPath];
							[self sendWillEditDisplayInfo];
							displayInfo.draggedPositionHidden = NO;
							displayInfo.draggedPosition = [curvedPath relativePositionForControlToken:draggedToken];
							displayInfo.mouseCursorHidden = YES;
							displayInfo.mouseCursorPosition = 0;
							[self sendDidEditDisplayInfo];
							
							[cursor release];
							cursor = [[NSCursor closedHandCursor]retain];
							[cursor set];
						}
						else
						{
							[self sendWillEditCurvedPath];
							[curvedPath addNode:mouseLocation transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])];
							[self sendDidUpdateCurvedPath];
							[self sendDidEditCurvedPath];
							[self setNeedsDisplay:YES];
							
							[windowController CPRView:self setCrossCenter:[[curvedPath.nodes lastObject] CPRVectorValue]];
							
//							CPRVector v = [curvedPath.bezierPath vectorAtRelativePosition: 1];
						}
					}
					else
					{
						draggedToken = [curvedPath controlTokenNearPoint:mouseLocation transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])];
						if ([CPRCurvedPath controlTokenIsNode:draggedToken])
						{
							[self sendWillEditCurvedPath];
							[self sendWillEditDisplayInfo];
							displayInfo.draggedPositionHidden = NO;
							displayInfo.draggedPosition = [curvedPath relativePositionForControlToken:draggedToken];
							displayInfo.mouseCursorHidden = YES;
							displayInfo.mouseCursorPosition = 0;
							[self sendDidEditDisplayInfo];
							
							[cursor release];
							cursor = [[NSCursor closedHandCursor]retain];
							[cursor set];
						}
						else if (draggedToken != CPRCurvedPathControlTokenNone)
						{
							[cursor release];
							cursor = [[NSCursor closedHandCursor]retain];
							[cursor set];
							
							[self sendWillEditCurvedPath];
						}
						
						if (draggedToken != CPRCurvedPathControlTokenNone)
						{
							return;
						}
						
						relativePositionOnCurve = [curvedPath relativePositionForPoint:mouseLocation transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])
																	   distanceToPoint:&distanceToCurve];
						
						if (distanceToCurve < 5) {
							[self sendWillEditCurvedPath];
							[curvedPath insertNodeAtRelativePosition:relativePositionOnCurve];
							[self sendDidEditCurvedPath];
							return;
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
    CGFloat relativePositionOnCurve;
    CGFloat distanceToCurve;
    NSPoint viewPoint;
    
	viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
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
        
		windowController.mprView1.LOD *= 0.9;
		windowController.mprView2.LOD *= 0.9;
		windowController.mprView3.LOD *= 0.9;
		
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
			
			windowController.mprView1.LOD *= 0.9;
			windowController.mprView2.LOD *= 0.9;
			windowController.mprView3.LOD *= 0.9;
			
			if( [vrView _tool] == tRotate)
				[self updateViewMPR: NO];
			else
				[self updateViewMPR];
		}
	}
	
	if (draggedToken != CPRCurvedPathControlTokenNone)
	{
		[windowController CPRView:self setCrossCenter:[[curvedPath.nodes objectAtIndex: [CPRCurvedPath nodeIndexForToken: draggedToken]] CPRVectorValue]];
		
		draggedToken = CPRCurvedPathControlTokenNone;
		[self sendDidEditCurvedPath];
	}
    if (displayInfo.draggedPositionHidden == NO) {
        relativePositionOnCurve = [curvedPath relativePositionForPoint:viewPoint transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])
                                                       distanceToPoint:&distanceToCurve];

		[self sendWillEditDisplayInfo];
        displayInfo.draggedPositionHidden = YES;
        displayInfo.draggedPosition = 0.0;
        
        if (distanceToCurve < CPRMPRDCMViewCurveMouseTrackingDistance) {
            displayInfo.mouseCursorHidden = NO;
            displayInfo.mouseCursorPosition = relativePositionOnCurve;
        } else {
            displayInfo.mouseCursorHidden = YES;
            displayInfo.mouseCursorPosition = 0.0;
        }
        
		[self sendDidEditDisplayInfo];
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
			if (draggedToken != CPRCurvedPathControlTokenNone)
			{
				NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView: nil];
				
				[curvedPath moveControlToken:draggedToken toPoint:mouseLocation transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])];
				[self sendDidUpdateCurvedPath];
				
				if ([CPRCurvedPath controlTokenIsNode:draggedToken])
				{
					[self sendWillEditDisplayInfo];
					displayInfo.draggedPosition = [curvedPath relativePositionForControlToken:draggedToken];
					[self sendDidEditDisplayInfo];
				}
				
				[super mouseDragged: theEvent];
				
				[self setNeedsDisplay:YES];
			}
			else
			{
				[super mouseDragged: theEvent];
				[windowController propagateWLWW: self];
			}
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
				angleMPR -= [CPRController angleBetweenVector: after andPlane: before];
				
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
    CGFloat relativePositionOnCurve;
    CGFloat distanceToCurve;
    NSPoint viewPoint;
    CPRCurvedPathControlToken curveToken;
    BOOL needToModifyCurve;
    
	if( [windowController windowWillClose])
		return;
    
	NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
	viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
	if( view == self)
	{
		[super mouseMoved: theEvent];
		
		long tool = [self getTool: theEvent];
		
		if( tool == tCurvedROI)
		{
			[cursor release];
			cursor = [[NSCursor crosshairCursor] retain];
			
			relativePositionOnCurve = [curvedPath relativePositionForPoint:viewPoint transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])
														   distanceToPoint:&distanceToCurve];
			curveToken = [curvedPath controlTokenNearPoint:viewPoint transform:CPRAffineTransform3DConcat([self viewToPixTransform], [self pixToDicomTransform])];
			
			needToModifyCurve = NO;
			
			if ([CPRCurvedPath controlTokenIsNode:curveToken]) {
				if (displayInfo.hoverNodeHidden == YES || displayInfo.hoverNodeIndex != [CPRCurvedPath nodeIndexForToken:curveToken]) {
					needToModifyCurve = YES;
				}
			} else {
				if (displayInfo.hoverNodeHidden == NO) {
					needToModifyCurve = YES;
				}
			}
			
			if (distanceToCurve < CPRMPRDCMViewCurveMouseTrackingDistance)
			{
				needToModifyCurve = YES;
			}
			else
			{
				if (displayInfo.mouseCursorHidden == NO) {
					needToModifyCurve = YES;
				}
			}
			
			if (needToModifyCurve) {
				[self sendWillEditDisplayInfo];
			}
			
			if ([CPRCurvedPath controlTokenIsNode:curveToken])
			{
				if( windowController.curvedPathCreationMode == NO)
				{
					[cursor release];
					if( [theEvent type] == NSLeftMouseDragged)
						cursor = [[NSCursor closedHandCursor]retain];
					else
						cursor = [[NSCursor openHandCursor]retain];
				}
				
				displayInfo.hoverNodeHidden = NO;
				displayInfo.hoverNodeIndex = [CPRCurvedPath nodeIndexForToken:curveToken];
			}
			else if (curveToken != CPRCurvedPathControlTokenNone)
			{
				[cursor release];
				if( [theEvent type] == NSLeftMouseDragged)
					cursor = [[NSCursor closedHandCursor]retain];
				else
					cursor = [[NSCursor openHandCursor]retain];
			}
			else
			{
				displayInfo.hoverNodeHidden = YES;
				displayInfo.hoverNodeIndex = 0;
			}
			
			if (distanceToCurve < CPRMPRDCMViewCurveMouseTrackingDistance) {
				displayInfo.mouseCursorHidden = NO;
				displayInfo.mouseCursorPosition = relativePositionOnCurve;
			} else {
				displayInfo.mouseCursorHidden = YES;
				displayInfo.mouseCursorPosition = 0;
			}
			
			if (needToModifyCurve)
			{
				[self sendDidEditDisplayInfo];
				[self setNeedsDisplay:YES];
			}
		}
        
		int mouseOnLines = [self mouseOnLines:viewPoint];
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

- (void)mouseExited:(NSEvent *)theEvent
{
    BOOL needToModifyCurve;
    
    needToModifyCurve = NO;
    if (displayInfo.hoverNodeHidden == NO) {
        needToModifyCurve = YES;
    }
    
    if (displayInfo.mouseCursorHidden == NO) {
        needToModifyCurve = YES;
    }
    
    if (needToModifyCurve) {
		[self sendWillEditDisplayInfo];
    }
    
    displayInfo.hoverNodeHidden = YES;
    displayInfo.hoverNodeIndex = 0;
    
    displayInfo.mouseCursorHidden = YES;
    displayInfo.mouseCursorPosition = 0;
    
    if (needToModifyCurve) {
		[self sendDidEditDisplayInfo];
        [self setNeedsDisplay:YES];
    }
    
    [super mouseExited:theEvent];
}


#pragma mark-

- (void)sendWillEditCurvedPath
{
	if (editingCurvedPathCount == 0) {
		if ([delegate respondsToSelector:@selector(CPRViewWillEditCurvedPath:)]) {
			[delegate CPRViewWillEditCurvedPath:self];
		}
	}
	editingCurvedPathCount++;
}

- (void)sendDidUpdateCurvedPath
{
	if ([delegate respondsToSelector:@selector(CPRViewDidUpdateCurvedPath:)]) {
		[delegate CPRViewDidUpdateCurvedPath:self];
	}
}

- (void)sendDidEditCurvedPath
{
	editingCurvedPathCount--;
	if (editingCurvedPathCount == 0) {
		if ([delegate respondsToSelector:@selector(CPRViewDidEditCurvedPath:)]) {
			[delegate CPRViewDidEditCurvedPath:self];
		}
	}
}

- (void)sendWillEditDisplayInfo
{
	if ([delegate respondsToSelector:@selector(CPRViewWillEditDisplayInfo:)]) {
		[delegate CPRViewWillEditDisplayInfo:self];
	}
}

- (void)sendDidEditDisplayInfo
{
	if ([delegate respondsToSelector:@selector(CPRViewDidEditDisplayInfo:)]) {
		[delegate CPRViewDidEditDisplayInfo:self];
	}
}

- (void)setCrossCenter:(NSPoint)crossCenter
{
	[self restoreCamera];
	
	[vrView setWindowCenter:crossCenter];
	
	dontUseAutoLOD = YES;
	LOD = 40;
	
	[self updateViewMPR];
	
	camera.windowCenterX = 0;
	camera.windowCenterY = 0;
	
	dontUseAutoLOD = NO;
	LOD = windowController.LOD;
}

- (void)drawCurvedPathInGL
{
	if( curvedPath.nodes.count == 0)
		return;
	
	CPRAffineTransform3D transform;
	CPRBezierPath *bezierPath;
    CPRMutableBezierPath *transformedBezierPath; // transformed path to be used to draw control points
    CPRMutableBezierPath *flattenedBezierPath; // path used for rendering
    CPRBezierPath *flattenedNotTransformedBezierPath;
    CPRMutableBezierPath *outlinePath;
    CPRVector vector;
    CPRVector control1;
    CPRVector control2;
    CPRVector prevVector;
    CPRVector middleVector;
    CPRVector cursorVector;
    CGFloat spacing;
    CGFloat x;
    NSInteger i;
    BOOL above;
    CGLContextObj cgl_ctx;
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    
	transform = CPRAffineTransform3DConcat(CPRAffineTransform3DInvert([self pixToDicomTransform]), [self pixToSubDrawRectTransform]);
    
	// Just a single point
	if( curvedPath.nodes.count == 1)
	{
        cursorVector = CPRVectorApplyTransform([[curvedPath.nodes objectAtIndex: 0] CPRVectorValue], transform);
		glColor4d(1.0, 0.0, 0.0, 1.0);
        [self drawCircleAtPoint:NSPointFromCPRVector(cursorVector)];
		
		return;
	}
	
	bezierPath = curvedPath.bezierPath;
    flattenedBezierPath = [bezierPath mutableCopy];
	//    [flattenedBezierPath subdivide:CPRBezierDefaultSubdivideSegmentLength];
	//    [flattenedBezierPath flatten:CPRBezierDefaultFlatness];
    flattenedNotTransformedBezierPath = [bezierPath bezierPathByFlattening:CPRBezierDefaultFlatness];
    
    CGFloat length;
    
    length = [flattenedBezierPath length];
    
    [flattenedBezierPath applyAffineTransform:transform];
	
    transformedBezierPath = [bezierPath mutableCopy];
    [transformedBezierPath applyAffineTransform:transform];
    [flattenedBezierPath flatten:CPRBezierDefaultFlatness];
	
	float pathRed = [windowController.curvedPathColor redComponent];
	float pathGreen = [windowController.curvedPathColor greenComponent];
	float pathBlue = [windowController.curvedPathColor blueComponent];
	
    glColor4d( pathRed, pathGreen, pathBlue, 1.0);
    above = YES;
    
    glLineWidth(2.0);
    glBegin(GL_LINE_STRIP);
    for (i = 0; i < [flattenedBezierPath elementCount]; i++) { // draw the line segments
        [flattenedBezierPath elementAtIndex:i control1:NULL control2:NULL endpoint:&vector];
        
        if (vector.z <= 0.000001 != above) {
            if (i > 0) {
                [flattenedBezierPath elementAtIndex:i-1 control1:NULL control2:NULL endpoint:&prevVector];
                
                x = vector.z/(vector.z-prevVector.z);
                middleVector = CPRVectorAdd(CPRVectorScalarMultiply(prevVector, x), CPRVectorScalarMultiply(vector, 1.0-x));
                glVertex2d(middleVector.x, middleVector.y);
            }
			
            above = !above;
            if (above) {
                glColor4d( pathRed, pathGreen, pathBlue, 1.0);
            } else {
                glColor4d( pathRed, pathGreen, pathBlue, 0.3);
            }
            
            if (i > 0) {
                glVertex2d(middleVector.x, middleVector.y);
            }
        }
        
        glVertex2d(vector.x, vector.y);
    }
    glEnd();
    
    // draw the thick slab outline
    if ([bezierPath elementCount] >= 2 && curvedPath.thickness > 2.0 && length > 3.0) {
        glLineWidth(1.0);
        outlinePath = [[bezierPath outlineBezierPathAtDistance:curvedPath.thickness / 2.0 initialNormal:CPRVectorCrossProduct(curvedPath.initialNormal, [flattenedBezierPath tangentAtStart]) spacing:1.0] mutableCopy];
        [outlinePath applyAffineTransform:transform];
        glColor4d(0.0, 1.0, 0.0, 1.0); 
        glBegin(GL_LINE_STRIP);
        for (i = 0; i < [outlinePath elementCount]; i++) {
            if ([outlinePath elementAtIndex:i control1:NULL control2:NULL endpoint:&vector] == CPRLineToBezierPathElement) {
                glVertex2d(vector.x, vector.y);
            } else {
                glEnd();
                glBegin(GL_LINE_STRIP);
                glVertex2d(vector.x, vector.y);
            }
			
        }
        glEnd();
        [outlinePath release];
        outlinePath = nil;
    }
	
    
	//    glColor4d(1.0, 0.0, 1.0, 1.0); // draw the normal lines
	//    glBegin(GL_LINES);
	//    for (i = 0; i < numVectors; i++) {
	//        CPRVector start = CPRVectorApplyTransform(CPRVectorAdd(vectors[i], CPRVectorScalarMultiply(normals[i], 10)), transform);
	//        CPRVector end = CPRVectorApplyTransform(CPRVectorSubtract(vectors[i], CPRVectorScalarMultiply(normals[i], 10)), transform);
	//        glVertex2d(start.x, start.y);
	//        glVertex2d(end.x, end.y);
	//    }
	//    glEnd();
    
    
    glColor4d(1.0, 0.0, 0.0, 1.0); // draw the ends of the line segements
    for (i = 0; i < [transformedBezierPath elementCount]; i++) {
        [transformedBezierPath elementAtIndex:i control1:NULL control2:NULL endpoint:&vector];
        [self drawCircleAtPoint:NSMakePoint(vector.x, vector.y)];
    }
    
	// draw the cursor positions
    if (displayInfo.mouseCursorHidden == NO) {
        cursorVector = CPRVectorApplyTransform([flattenedNotTransformedBezierPath vectorAtRelativePosition:displayInfo.mouseCursorPosition], transform);
        glColor4d(0.0, 1.0, 0.0, 1.0);
        [self drawCircleAtPoint:NSPointFromCPRVector(cursorVector)];
    }
    
	// draw the cursor positions
    if (displayInfo.hoverNodeHidden == NO && displayInfo.hoverNodeIndex < [curvedPath.nodes count]) {
        cursorVector = CPRVectorApplyTransform([[curvedPath.nodes objectAtIndex:displayInfo.hoverNodeIndex] CPRVectorValue], transform);
        glColor4d(1.0, 0.5, 0.0, 1.0);
        [self drawCircleAtPoint:NSPointFromCPRVector(cursorVector)];
    }
    
    // draw the transverse positions
    cursorVector = CPRVectorApplyTransform([flattenedNotTransformedBezierPath vectorAtRelativePosition:curvedPath.transverseSectionPosition], transform);
    glColor4d(1.0, 1.0, 0.0, 1.0);
    [self drawCircleAtPoint:NSPointFromCPRVector(cursorVector)];
    
    cursorVector = CPRVectorApplyTransform([flattenedNotTransformedBezierPath vectorAtRelativePosition:curvedPath.leftTransverseSectionPosition], transform);
    glColor4d(1.0, 1.0, 0.0, 1.0);
    [self drawCircleAtPoint:NSPointFromCPRVector(cursorVector) pointSize:4];
    
    cursorVector = CPRVectorApplyTransform([flattenedNotTransformedBezierPath vectorAtRelativePosition:curvedPath.rightTransverseSectionPosition], transform);
    glColor4d(1.0, 1.0, 0.0, 1.0);
    [self drawCircleAtPoint:NSPointFromCPRVector(cursorVector) pointSize:4];
    
    
	//    glColor4d(1.0, 1.0, 0.0, 1.0); // draw the endpoints
	//    for (i = 0; i < [flattenedBezierPath elementCount]; i++) {
	//        [flattenedBezierPath elementAtIndex:i control1:NULL control2:NULL endpoint:&vector];
	//        [self drawCircleAtPoint:NSMakePoint(vector.x, vector.y)];
	//    }
    
	//    glColor4d(0.0, 1.0, 1.0, 1.0); // draw the control points
	//    for (i = 0; i < [transformedBezierPath elementCount]; i++) {
	//        if ([transformedBezierPath elementAtIndex:i control1:&control1 control2:&control2 endpoint:&vector] == CPRCurveToBezierPathElement) {
	//            [self drawCircleAtPoint:NSMakePoint(control1.x, control1.y)];
	//            [self drawCircleAtPoint:NSMakePoint(control2.x, control2.y)];
	//        }
	//    }
    
    
    [transformedBezierPath release];
    [flattenedBezierPath release];
}

- (void)drawCircleAtPoint:(NSPoint)point pointSize:(CGFloat)pointSize
{
    CGLContextObj cgl_ctx;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    
    glEnable(GL_POINT_SMOOTH);
    glPointSize(pointSize);
    
    glBegin(GL_POINTS);
    glVertex2f(point.x, point.y);
    glEnd();    
}


- (void)drawCircleAtPoint:(NSPoint)point
{
    [self drawCircleAtPoint:point pointSize:8];
}


- (CPRAffineTransform3D)pixToDicomTransform // converts points in the DCMPix's coordinate space ("Slice Coordinates") into the DICOM space (patient space with mm units)
{
    CPRAffineTransform3D pixToDicomTransform;
    double spacingX;
    double spacingY;
    //    double spacingZ;
    double orientation[9];
    
    memset(orientation, 0, sizeof(double) * 9);
    [pix orientationDouble:orientation];
    spacingX = pix.pixelSpacingX;
    spacingY = pix.pixelSpacingY;
    //    spacingZ = pix.sliceInterval;
    
    pixToDicomTransform = CPRAffineTransform3DIdentity;
    pixToDicomTransform.m41 = pix.originX;
    pixToDicomTransform.m42 = pix.originY;
    pixToDicomTransform.m43 = pix.originZ;
    pixToDicomTransform.m11 = orientation[0]*spacingX;
    pixToDicomTransform.m12 = orientation[1]*spacingX;
    pixToDicomTransform.m13 = orientation[2]*spacingX;
    pixToDicomTransform.m21 = orientation[3]*spacingY;
    pixToDicomTransform.m22 = orientation[4]*spacingY;
    pixToDicomTransform.m23 = orientation[5]*spacingY;
    pixToDicomTransform.m31 = orientation[6];
    pixToDicomTransform.m32 = orientation[7];
    pixToDicomTransform.m33 = orientation[8];
    
    return pixToDicomTransform;
}

- (CPRPlane)plane
{
    CPRAffineTransform3D pixToDicomTransform;
	CPRPlane plane;
    
    pixToDicomTransform = [self pixToDicomTransform];
    
    plane.point = CPRVectorApplyTransform(CPRVectorMake((CGFloat)curDCM.pwidth/2.0, (CGFloat)curDCM.pheight/2.0, 0.0), pixToDicomTransform);
    plane.normal = CPRVectorNormalize(CPRVectorApplyTransformToDirectionalVector(CPRVectorMake(0.0, 0.0, 1.0), pixToDicomTransform));
    
	if (CPRPlaneIsValid(plane)) {
		return plane;
	} else {
		return CPRPlaneInvalid;
	}
}

- (NSString *)planeName
{
	switch( viewID)
	{
		case 1:
			return @"orange";
			break;
			
		case 2:
			return @"purple";
			break;
			
		case 3:
			return @"blue";
			break;
	}
	assert(0);
	return nil;
}

- (NSColor *)colorForPlaneName:(NSString *)planeName
{
	if ([planeName isEqualToString:@"orange"]) {
		return windowController.colorAxis1;
	} else if ([planeName isEqualToString:@"purple"]) {
		return windowController.colorAxis2;
	} else if ([planeName isEqualToString:@"blue"]) {
		return windowController.colorAxis3;
	}
	assert(0);
	return nil;
}

@end

@implementation DCMView (CPRAdditions)


- (CPRAffineTransform3D)viewToPixTransform // converts coordinates in the NSView's space to coordinates on a DCMPix object in "Slice Coordinates"
{
    // since there is no way to get matrix values directly for this transformation, we will figure out how the basis vectors get transformed, and contruct the matrix from these values
    CPRAffineTransform3D viewToPixTransform;
    NSPoint orginBasis;
    NSPoint xBasis;
    NSPoint yBasis;
    
    orginBasis = [self ConvertFromNSView2GL:NSMakePoint(0, 0)];
    xBasis = [self ConvertFromNSView2GL:NSMakePoint(1, 0)];
    yBasis = [self ConvertFromNSView2GL:NSMakePoint(0, 1)];
    
    viewToPixTransform = CPRAffineTransform3DIdentity;
    viewToPixTransform.m41 = orginBasis.x;
    viewToPixTransform.m42 = orginBasis.y;
    viewToPixTransform.m11 = xBasis.x - orginBasis.x;
    viewToPixTransform.m12 = xBasis.y - orginBasis.y;
    viewToPixTransform.m21 = yBasis.x - orginBasis.x;
    viewToPixTransform.m22 = yBasis.y - orginBasis.y;
    
    return viewToPixTransform;
}

- (CPRAffineTransform3D)pixToSubDrawRectTransform // converst points in DCMPix "Slice Coordinates" to coordinates that need to be passed to GL in subDrawRect
{
    CPRAffineTransform3D pixToSubDrawRectTransform;
    
    pixToSubDrawRectTransform = CPRAffineTransform3DIdentity;
    //    pixToSubDrawRectTransform = CPRAffineTransform3DConcat(pixToSubDrawRectTransform, CPRAffineTransform3DMakeScale(1.0/curDCM.pixelSpacingX, 1.0/curDCM.pixelSpacingY, 1));
    pixToSubDrawRectTransform = CPRAffineTransform3DConcat(pixToSubDrawRectTransform, CPRAffineTransform3DMakeTranslation(curDCM.pwidth * -0.5, curDCM.pheight * -0.5, 0));
    pixToSubDrawRectTransform = CPRAffineTransform3DConcat(pixToSubDrawRectTransform, CPRAffineTransform3DMakeScale(scaleValue, scaleValue, 1));
    
    return pixToSubDrawRectTransform;
}

@end
