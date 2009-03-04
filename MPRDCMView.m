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

- (void) setDCMPixList:(NSMutableArray*)pixList filesList:(NSArray*)files volumeData:(NSData*)volume roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
{
	[super setDCM:pixList :files :rois :firstImage :type :reset];
	
	pix = [pixList lastObject];
	
	currentTool = t3DRotate;
}

- (void) setVRView: (VRView*) v
{
	vrView = v;
	
	[vrView prepareFullDepthCapture];
}

- (void) dealloc
{
	[vrView restoreFullDepthCapture];
	[cam release];
	
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
	
	[cam release];
	cam = [[vrView cameraWithThumbnail: NO] retain];
	
	if( imagePtr)
	{
		if( [pix pwidth] == w && [pix pheight] == h)
		{
			memcpy( [pix fImage], imagePtr, w*h*sizeof( float));
			free( imagePtr);
		}
		else
		{
			[pix setNeedToCompute8bitRepresentation: YES];
			[pix kill8bitsImage];
			
			[pix setfImage: imagePtr];
			[pix setPwidth: w];
			[pix setPheight: h];
			[pix baseAddr];
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
	}
	
	[self setNeedsDisplay: YES];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	if( cam)
	{
		[self checkForFrame];
		
		[vrView setCamera: cam];
	}
	
	[vrView scrollWheel: theEvent];
	
	[self updateView];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	if( cam)
	{
		[self checkForFrame];
		
		[vrView setCamera: cam];
	}
	
	[vrView rightMouseDown: theEvent];
	
	[self updateView];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	if( cam)
	{
		[self checkForFrame];
		
		[vrView setCamera: cam];
	}
	
	[vrView rightMouseDragged: theEvent];
	
	[self updateView];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	if( cam)
	{
		[self checkForFrame];
		
		[vrView setCamera: cam];
	}
	
	[vrView rightMouseUp: theEvent];
	
	[self updateView];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	long tool = [self getTool: theEvent];

	if( cam)
	{
		[self checkForFrame];
		
		[vrView setCamera: cam];
	}
	
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
	
	if( cam)
	{
		[self checkForFrame];
		
		[vrView setCamera: cam];
	}
	
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
	
	if( tool == tWL)
		[super mouseDragged: theEvent];
	else
	{
		[vrView mouseDragged: theEvent];
		[self updateView];
	}
}
@end
 