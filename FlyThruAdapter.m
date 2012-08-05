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




#import "FlyThruAdapter.h"

// abstract class
@implementation FlyThruAdapter

- (id) initWithWindow3DController: (Window3DController*) aWindow3DController
{
	self = [super init];
	controller = aWindow3DController;
	return self;
}
-(void) dealloc
{
	[super dealloc];
}

- (Camera*) getCurrentCamera{return nil;}
- (void) setCurrentViewToCamera:(Camera*)aCamera{}
- (NSImage*) getCurrentCameraImage:(BOOL) highQuality {return nil;}
- (void) setCurrentViewToLowResolutionCamera:(Camera*)aCamera
{
	[self setCurrentViewToCamera: aCamera];
}
- (void) prepareMovieGenerating{}
- (void) endMovieGenerating{}
@end
