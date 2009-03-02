//
//  MPRController.h
//  OsiriX
//
//  Created by joris on 2/26/09.
//  Copyright 2009 The OsiriX Foundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPRDCMView.h"
#import "VRController.h"

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


@end
