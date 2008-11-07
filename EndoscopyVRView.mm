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

#import "EndoscopyVRView.h"
#import "EndoscopyViewer.h"

@implementation EndoscopyVRView

-(id)initWithFrame:(NSRect)frame;
{
    if ( self = [super initWithFrame:frame] )
    {
		[self connect2SpaceNavigator];
	}
	return self;
}

-(unsigned char*) superGetRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	return [super getRawPixels:width :height :spp :bpp :screenCapture :force8bits];
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	if ([(EndoscopyViewer*)[[self window] windowController] exportAllViews])
		return [(EndoscopyViewer*)[[self window] windowController] getRawPixels:width :height :spp :bpp];
	else
		return [super getRawPixels:width :height :spp :bpp :screenCapture :force8bits];
}

-(void) restoreViewSizeAfterMatrix3DExport
{
}

-(void) setViewSizeToMatrix3DExport
{
}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower{
	[super setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower];
}

- (void)setIChatFrame:(BOOL)set;
{
	return;
}

@end
