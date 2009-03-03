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
}

- (void) setVRView: (VRView*) v
{
	vrView = v;
	
	[vrView prepareFullDepthCapture];
}

- (void) dealloc
{
	[vrView restoreFullDepthCapture];
	
	[super dealloc];
}

- (void) updateView
{
	long h, w;
	
	[vrView setFrame: [self frame]];
	
	[vrView render];
	
	float *imagePtr = [vrView imageInFullDepthWidth: &w height: &h];
	
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
		
		float wwl, www;
		
		[vrView getWLWW: &wwl :&www];
		[self setWLWW: wwl :www];
		
		[self setScaleValue: [vrView imageSampleDistance]];
	}
	
	[self setNeedsDisplay: YES];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[vrView scrollWheel: theEvent];
	
	[self updateView];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[vrView rightMouseDown: theEvent];
	
	[self updateView];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[vrView rightMouseDragged: theEvent];
	
	[self updateView];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[vrView rightMouseUp: theEvent];
	
	[self updateView];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	[vrView mouseDown: theEvent];
	
	[self updateView];
}

- (void) mouseUp:(NSEvent *)theEvent
{
	[vrView mouseUp: theEvent];
	
	[self updateView];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	[vrView mouseDragged: theEvent];
	
	[self updateView];
}
@end
 