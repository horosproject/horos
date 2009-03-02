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

- (void) setVRController: (VRController*) v
{
	vrCtrl = v;
}

- (void) dealloc
{
	[super dealloc];
}

//- (void)setFrame:(NSRect)frameRect
//{
//	[super setFrame: frameRect];
//	
//	[[vrCtrl view] setFrame: frameRect];
//	[self updateView];
//}

- (void) updateView
{
	long h, w;
	
	[[vrCtrl view] setFrame: [self frame]];
	
	[[vrCtrl view] render];
	
	float *imagePtr = [[vrCtrl view] imageInFullDepthWidth: &w height: &h];
	
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
		[[vrCtrl view] getOrigin: porigin];
		[pix setOrigin: porigin];
		
		float resolution = [[vrCtrl view] getResolution] * [[vrCtrl view] imageSampleDistance];
		[pix setPixelSpacingX: resolution];
		[pix setPixelSpacingY: resolution];
		
		float orientation[ 9];
		[[vrCtrl view] getOrientation: orientation];
		[pix setOrientation: orientation];
		
		float wwl, www;
		
		[[vrCtrl view] getWLWW: &wwl :&www];
		[self setWLWW: wwl :www];
		
		[self setScaleValue: [[vrCtrl view] imageSampleDistance]];
	}
	
	[self setNeedsDisplay: YES];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[[vrCtrl view] scrollWheel: theEvent];
	
	[self updateView];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[[vrCtrl view] rightMouseDown: theEvent];
	
	[self updateView];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[[vrCtrl view] rightMouseDragged: theEvent];
	
	[self updateView];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[[vrCtrl view] rightMouseUp: theEvent];
	
	[self updateView];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	[[vrCtrl view] mouseDown: theEvent];
	
	[self updateView];
}

- (void) mouseUp:(NSEvent *)theEvent
{
	[[vrCtrl view] mouseUp: theEvent];
	
	[self updateView];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	[[vrCtrl view] mouseDragged: theEvent];
	
	[self updateView];
}
@end
 