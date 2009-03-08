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

static float deg2rad = 3.14159265358979/180.0; 

@implementation MPRDCMView

@synthesize pix, camera, angleMPR, vrView;

+ (BOOL)is2DTool:(short)tool;
{
	switch( tool)
	{
		case tWL:
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

- (void) setDCMPixList:(NSMutableArray*)pixList filesList:(NSArray*)files volumeData:(NSData*)volume roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
{
	[super setDCM:pixList :files :rois :firstImage :type :reset];
	
	pix = [pixList lastObject];
	
	currentTool = t3DRotate;
	
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

- (void) checkForFrame
{
	NSRect frame = [self frame];
	NSPoint o = [self convertPoint: NSMakePoint(0, 0) toView:0L];
	frame.origin = o;
	
	if( NSEqualRects( frame, [vrView frame]) == NO)
		[vrView setFrame: frame];
}

- (void) restoreCamera
{
	[self checkForFrame];
	[vrView setCamera: camera];
}

- (void) dealloc
{
	[vrView restoreFullDepthCapture];
	[camera release];
	
	[super dealloc];
}

- (void) updateView
{
	long h, w;
	float previousWW, previousWL;
	
	[self getWLWW: &previousWL :&previousWW];
	
	[vrView render];
	
	float *imagePtr = [vrView imageInFullDepthWidth: &w height: &h];
	
	[self saveCamera];
	
	if( imagePtr)
	{
		if( [pix pwidth] == w && [pix pheight] == h)
		{
			memcpy( [pix fImage], imagePtr, w*h*sizeof( float));
			free( imagePtr);
		}
		else
		{
			[pix setfImage: imagePtr];
			[pix setPwidth: w];
			[pix setPheight: h];
			
			[self setIndex: 0];
		}
		float porigin[ 3];
		[vrView getOrigin: porigin windowCentered: YES];
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
		
		[windowController computeCrossReferenceLines: self];
	}
	
	[self setNeedsDisplay: YES];
}


- (void) subDrawRect: (NSRect) r
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable(GL_BLEND);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);
	
	// All pix have the same thickness
	float thickness = [pix sliceThickness];
	
	switch( viewID)
	{
		case 1:
			glColor4f (0.0f, 1.0f, 0.0f, 1.0f);
			if( crossLinesA[ 0][ 0] != HUGE_VALF)
			{
				glLineWidth(2.0);
				[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: 0];
				
				glLineWidth(0.5);
				[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: -thickness/2.];
				[self drawCrossLines: crossLinesA ctx: cgl_ctx withShift: thickness/2.];
			}
			glColor4f (0.0f, 0.0f, 1.0f, 1.0f);
			if( crossLinesB[ 0][ 0] != HUGE_VALF)
			{
				glLineWidth(2.0);
				[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: 0];
				
				glLineWidth(0.5);
				[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: -thickness/2.];
				[self drawCrossLines: crossLinesB ctx: cgl_ctx withShift: thickness/2.];
			}
		break;
		
		case 2:
			glColor4f (1.0f, 0.0f, 0.0f, 1.0f);
			if( crossLinesA[ 0][ 0] != HUGE_VALF)
				[self drawCrossLines: crossLinesA ctx: cgl_ctx];
			
			glColor4f (0.0f, 0.0f, 1.0f, 1.0f);
			if( crossLinesB[ 0][ 0] != HUGE_VALF)
				[self drawCrossLines: crossLinesB ctx: cgl_ctx];
		break;
		
		case 3:
			glColor4f (1.0f, 0.0f, 0.0f, 1.0f);
			if( crossLinesA[ 0][ 0] != HUGE_VALF)
				[self drawCrossLines: crossLinesA ctx: cgl_ctx];
			
			glColor4f (0.0f, 1.0f, 0.0f, 1.0f);
			if( crossLinesB[ 0][ 0] != HUGE_VALF)
				[self drawCrossLines: crossLinesB ctx: cgl_ctx];
		break;
	}
	
	switch( viewID)
	{
		case 1:
			glColor4f (1.0f, 0.0f, 0.0f, 1.0f);
		break;
		
		case 2:
			glColor4f (0.0f, 1.0f, 0.0f, 1.0f);
		break;
		
		case 3:
			glColor4f (0.0f, 0.0f, 1.0f, 1.0f);
		break;
	}
	
	float heighthalf = self.frame.size.height/2 - 1;
	float widthhalf = self.frame.size.width/2 - 1;
	
	glLineWidth(6.0);
	glBegin(GL_LINE_LOOP);
		glVertex2f(  -widthhalf, -heighthalf);
		glVertex2f(  -widthhalf, heighthalf);
		glVertex2f(  widthhalf, heighthalf);
		glVertex2f(  widthhalf, -heighthalf);
	glEnd();
	glLineWidth(1.0);
					
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
	// Intersection of the lines
	NSPoint r = [self centerLines];
	
	if( r.x != 0 || r.y != 0)
	{
		mouseLocation = [self ConvertFromNSView2GL: mouseLocation];
		
		mouseLocation.x *= curDCM.pixelSpacingX;
		mouseLocation.y *= curDCM.pixelSpacingY;
		
		if( mouseLocation.x > r.x - BS/scaleValue && mouseLocation.x < r.x + BS/scaleValue && mouseLocation.y > r.y - BS/scaleValue && mouseLocation.y < r.y + BS/scaleValue)
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
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
		
	[self restoreCamera];
	
	[vrView scrollWheel: theEvent];
	
	[self updateView];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
	
	rotateLines = NO;
	moveCenter = NO;
	
	[self restoreCamera];
	
	[vrView rightMouseDown: theEvent];
	
	[self updateView];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self restoreCamera];
	
	[vrView rightMouseDragged: theEvent];
	
	[self updateView];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self restoreCamera];
	
	[vrView rightMouseUp: theEvent];
	
	[self updateView];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	if( [[self window] firstResponder] != self)
		[[self window] makeFirstResponder: self];
	
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
		
		[[NSCursor closedHandCursor] set];
	}
	else
	{
		long tool = [self getTool: theEvent];
		
		[self restoreCamera];
		
		if([MPRDCMView is2DTool:tool])
		{
			[super mouseDown: theEvent];
			[windowController propagateWLWW: self];
		}
		else
		{
			[vrView mouseDown: theEvent];
			[self updateView];
		}
	}
}

- (void) mouseUp:(NSEvent *)theEvent
{
	[self restoreCamera];
	
	if( rotateLines || moveCenter)
	{
		if( moveCenter)
		{
			camera.windowCenterX = 0;
			camera.windowCenterY = 0;
			[self restoreCamera];
			[self updateView];
		}
		
		rotateLines = NO;
		moveCenter = NO;
		
		[cursor set];
	}
	else
	{
		long tool = [self getTool: theEvent];
		
		if([MPRDCMView is2DTool:tool])
		{
			[super mouseUp: theEvent];
			[windowController propagateWLWW: self];
		}
		else
		{
			[vrView mouseUp: theEvent];
			[self updateView];
		}
	}
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	[self restoreCamera];
	
	if( rotateLines)
	{
		[[NSCursor closedHandCursor] set];
		
		NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
		mouseLocation.x *= curDCM.pixelSpacingX;	mouseLocation.y *= curDCM.pixelSpacingY;
		angleMPR = [self angleBetween: mouseLocation center: [self centerLines]];
		
		angleMPR -= rotateLinesStartAngle;
		
		[self updateView];
	}
	else if( moveCenter)
	{
		[vrView setWindowCenter: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
		[self updateView];
	}
	else
	{
		long tool = [self getTool: theEvent];
		
		if([MPRDCMView is2DTool:tool])
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
			}
			[self updateView];
		}
	}
}

- (void) mouseMoved: (NSEvent *) theEvent
{
	NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
	
	if( view == self)
	{
		[super mouseMoved: theEvent];
		
		if( [self mouseOnLines: [self convertPoint:[theEvent locationInWindow] fromView:nil]])
		{
			[[NSCursor openHandCursor] set];
		}
	}
	else [view mouseMoved:theEvent];
}

#pragma mark-

@end
 