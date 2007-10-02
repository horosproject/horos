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


#import "ITKSegmentation3D.h"
#import "EndoscopyFlyThruController.h"
#import "EndoscopyVRController.h"
#import "EndoscopyViewer.h"
#import "OSIVoxel.h"





@implementation EndoscopyFlyThruController

@synthesize seeds;

- (id) initWithFlyThruAdapter:(FlyThruAdapter*)aFlyThruAdapter
{
	if (self = [super initWithWindowNibName:@"EndoscopyFlyThru"]) {
		[self setupController];
		self.FTAdapter = aFlyThruAdapter;
		self.seeds = [NSMutableArray array];
	}	
	return self;
}

- (void)dealloc{
	[seeds release];
	[super dealloc];
}

- (void)compute{
	// coordinates conversion
	float pos[3], pos2D[3];
	
	pos[0] = [[self.currentCamera position] x];
	pos[1] = [[self.currentCamera position] y];
	pos[2] = [[self.currentCamera position] z];
	[[controller3D view] convert3Dto2Dpoint:pos :pos2D];
	OSIVoxel *seed = [OSIVoxel pointWithX:pos2D[0]  y:pos2D[1]  z:pos2D[2] value:nil];
	NSLog(@"Compute centerline starting Point: %@", seed);
	[seeds addObject:seed];
	/*
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWithPix :[controller3D pixList]  volume:[controller3D volumePtr]  slice:-1  resampleData:NO];
	NSArray *centerlinePoints = [itk endoscopySegmentationForViewer:_viewer seeds:_seeds];
	//EndoscopyViewer *endoscopyViewer = [vrController openEndoscopyViewer];
	//[[endoscopyViewer vrController] flyThruControllerInit:self];
	OSIVoxel *firstPoint = [centerlinePoints objectAtIndex:0];
	int count  = [centerlinePoints count] - 1;
	for (int i = 0; i < count; i++) {
		OSIVoxel *firstPoint = [centerlinePoints objectAtIndex:i];
		OSIVoxel *secondPoint = [centerlinePoints objectAtIndex:i + 1];
		[controller3D setCameraPosition:firstPoint  
			focalPoint:secondPoint];
		[self flyThruTag:0];
	}
	[itk release];
	*/
}

- (IBAction)calculate: (id)sender{
	[self compute];
}

@end
