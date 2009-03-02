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

- (void) updateView
{
	long h, w;
	
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
	}
	
	[self setNeedsDisplay: YES];
}

- (void) mouseDown:(NSEvent *)theEvent
{
	[[vrCtrl view] mouseDown: theEvent];
	
	[self updateView];
}

@end
 