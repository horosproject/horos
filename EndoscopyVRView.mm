//
//  EndoscopyVRView.m
//  OsiriX
//
//  Created by joris on 2/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "EndoscopyVRView.h"
#import "EndoscopyViewer.h"

@implementation EndoscopyVRView

-(unsigned char*) superGetRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	[super getRawPixels:width :height :spp :bpp :screenCapture :force8bits];
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
