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

@implementation MPRDCMView

@synthesize pix, camera;

- (void) setDCMPixList:(NSMutableArray*)pixList filesList:(NSArray*)files volumeData:(NSData*)volume roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
{
	[super setDCM:pixList :files :rois :firstImage :type :reset];
	
	pix = [pixList lastObject];
	
	currentTool = t3DRotate;
	
	windowController = [self windowController];
}

- (void) setVRView: (VRView*) v
{
	vrView = v;
	[vrView prepareFullDepthCapture];
}

- (void) dealloc
{
	[vrView restoreFullDepthCapture];
	[camera release];
	
	[super dealloc];
}

- (void) checkForFrame
{
	NSRect frame = [self frame];
	NSPoint o = [self convertPoint: NSMakePoint(0, 0) toView:0L];
	frame.origin = o;
	
	if( NSEqualRects( frame, [vrView frame]) == NO)
		[vrView setFrame: frame];
}

- (void) updateView
{
	long h, w;
	float previousWW, previousWL;
	
	[self getWLWW: &previousWL :&previousWW];
	
	[vrView render];
	
	float *imagePtr = [vrView imageInFullDepthWidth: &w height: &h];
	
	[camera release];
	camera = [[vrView cameraWithThumbnail: NO] retain];
	
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
		[vrView getOrigin: porigin];
		[pix setOrigin: porigin];
		
		float resolution = [vrView getResolution] * [vrView imageSampleDistance];
		[pix setPixelSpacingX: resolution];
		[pix setPixelSpacingY: resolution];
		
		float orientation[ 9];
		[vrView getOrientation: orientation];
		[pix setOrientation: orientation];
		
		[self setWLWW: previousWL :previousWW];
		[self setScaleValue: [vrView imageSampleDistance]];
		
		[windowController computeCrossReferenceLines: self];
	}
	
	[self setNeedsDisplay: YES];
}


- (void) subDrawRect: (NSRect) r
{
	if( crossLinesA[ 0][ 0] != HUGE_VALF)
		[self drawCrossLines: crossLinesA ctx: [[NSOpenGLContext currentContext] CGLContextObj] green: YES];
	
	if( crossLinesB[ 0][ 0] != HUGE_VALF)
		[self drawCrossLines: crossLinesB ctx: [[NSOpenGLContext currentContext] CGLContextObj] green: YES];
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

- (void)scrollWheel:(NSEvent *)theEvent
{
	[self checkForFrame];
	[vrView setCamera: camera];
	
	[vrView scrollWheel: theEvent];
	
	[self updateView];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self checkForFrame];
	[vrView setCamera: camera];
	
	[vrView rightMouseDown: theEvent];
	
	[self updateView];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self checkForFrame];
	[vrView setCamera: camera];
	
	[vrView rightMouseDragged: theEvent];
	
	[self updateView];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self checkForFrame];
	[vrView setCamera: camera];
	
	[vrView rightMouseUp: theEvent];
	
	[self updateView];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	long tool = [self getTool: theEvent];

	[self checkForFrame];
	[vrView setCamera: camera];
	
	if( tool == tWL)
		[super mouseDown: theEvent];
	else
	{
		[vrView mouseDown: theEvent];
		[self updateView];
	}
}

- (void) mouseUp:(NSEvent *)theEvent
{
	long tool = [self getTool: theEvent];
	
	[self checkForFrame];
	[vrView setCamera: camera];
	
	if( tool == tWL)
		[super mouseUp: theEvent];
	else
	{
		[vrView mouseUp: theEvent];
		[self updateView];
	}
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	long tool = [self getTool: theEvent];
	
	[self checkForFrame];
	[vrView setCamera: camera];
	
	if( tool == tWL)
		[super mouseDragged: theEvent];
	else
	{
		[vrView mouseDragged: theEvent];
		[self updateView];
	}
}
@end
 