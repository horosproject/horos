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

#import <Cocoa/Cocoa.h>

#import "DCMView.h"
#import "VRController.h"

@interface MPRDCMView : DCMView
{
	VRView *vrView;
	DCMPix *pix;
	Camera *cam;
}

- (void) setDCMPixList:(NSMutableArray*)pix filesList:(NSArray*)files volumeData:(NSData*)volume roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;
- (void) setVRView: (VRView*) v;
- (void) updateView;
@end
