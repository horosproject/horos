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
#import "MPRDCMView.h"
#import "VRController.h"
#import "VRView.h"

@class MPRDCMView;

@interface MPRController : NSWindowController {
	
	IBOutlet NSSplitView *topSplitView, *bottomSplitView;
	IBOutlet NSView *containerFor3DView;
	
	IBOutlet MPRDCMView *mprView1, *mprView2, *mprView3;

	VRController *vrController, *hiddenVRController;
	VRView *vrView, *hiddenVRView;
	
	NSMutableArray *filesList[200], *pixList[200];
	NSData *volumeData[200];
	short curMovieIndex, maxMovieIndex;
}

- (id)initWithDCMPixList:(NSMutableArray*)pix filesList:(NSMutableArray*)files volumeData:(NSData*)volume viewerController:(ViewerController*)viewer fusedViewerController:(ViewerController*)fusedViewer;
- (DCMPix*) emptyPix: (DCMPix*) originalPix width: (long) w height: (long) h;

- (void) computeCrossReferenceLines:(MPRDCMView*) sender;
- (IBAction)setTool:(id)sender;

@end
