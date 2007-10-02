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
	ViewerController *viewer2D = [(EndoscopyVRController *)controller3D viewer2D];
	EndoscopyViewer *endoscopyViewer = [viewer2D openEndoscopyViewer];

	// coordinates conversion
	float pos[3], pos2D[3];
	
	pos[0] = [[self.currentCamera position] x];
	pos[1] = [[self.currentCamera position] y];
	pos[2] = [[self.currentCamera position] z];
	[[(EndoscopyVRController *)controller3D view] convert3Dto2Dpoint:pos :pos2D];
	OSIVoxel *seed = [OSIVoxel pointWithX:pos2D[0]  y:pos2D[1]  z:pos2D[2] value:nil];
	NSLog(@"Compute centerline starting Point: %@", seed);
	[seeds addObject:seed];
	
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWithPix :[viewer2D pixList]  volume:[viewer2D volumePtr]   slice:-1  resampleData:NO];
	NSArray *centerlinePoints = [itk endoscopySegmentationForViewer:viewer2D seeds:seeds];

	OSIVoxel *firstPoint = [centerlinePoints objectAtIndex:0];
	int count  = [centerlinePoints count] - 1;
	for (int i = 0; i < count; i++) {
		OSIVoxel *firstPoint = [centerlinePoints objectAtIndex:i];
		OSIVoxel *secondPoint = [centerlinePoints objectAtIndex:i + 1];
		[endoscopyViewer setCameraPosition:firstPoint  
			focalPoint:secondPoint];
		[stepsArrayController add:self];
	}
	[itk release];
	
}

- (IBAction)calculate: (id)sender{
	[self compute];
}

@end
