//
//  MPRController.m
//  OsiriX
//
//  Created by joris on 2/26/09.
//  Copyright 2009 The OsiriX Foundation. All rights reserved.
//

#import "MPRController.h"


@implementation MPRController

- (id)initWithDCMPixList:(NSMutableArray*)pix filesList:(NSMutableArray*)files volumeData:(NSData*)volume viewerController:(ViewerController*)viewer fusedViewerController:(ViewerController*)fusedViewer;
{
	if(![super initWithWindowNibName:@"MPR"]) return nil;
	pixList[0] = pix;
	filesList[0] = files;
	volumeData[0] = volume;
	
	[[self window] setWindowController: self];
		
	[mprView1 setDCMPixList:pixList[0] filesList:files volumeData:volume roiList:nil firstImage:[pixList[0] count]/2 type:'i' reset:YES];
	[mprView1 setFlippedData: [[viewer imageView] flippedData]];

	[mprView2 setDCMPixList:pixList[0] filesList:files volumeData:volume roiList:nil firstImage:[pixList[0] count]/2 type:'i' reset:YES];
	[mprView2 setFlippedData: [[viewer imageView] flippedData]];	
	
	[mprView3 setDCMPixList:pixList[0] filesList:files volumeData:volume roiList:nil firstImage:[pixList[0] count]/2 type:'i' reset:YES];
	[mprView3 setFlippedData: [[viewer imageView] flippedData]];
	
	vrController = [[VRController alloc] initWithPix:pix :files :volume :fusedViewer :viewer style:@"noNib" mode:@"VR"];
	hiddenVRController = [[VRController alloc] initWithPix:pix :files :volume :fusedViewer :viewer style:@"noNib" mode:@"VR"];
	hiddenVRView = [hiddenVRController view];
	
//	[containerFor3DView addSubview:hiddenVRView];
//	[hiddenVRView setFrame:containerFor3DView.frame];
		
	return self;
}

- (void) dealloc
{
	[vrController release];
	[hiddenVRController release];
	[super dealloc];
}

//- (void)windowWillLoad
//{
//	[hiddenVRView setFrame:containerFor3DView.frame];
//}

- (BOOL) is2DViewer
{
	return NO;
}

- (NSMutableArray*) pixList
{
	return pixList[ curMovieIndex];
}

@end
