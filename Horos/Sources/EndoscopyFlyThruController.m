/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
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
#import "VRView.h"

@implementation EndoscopyFlyThruController

@synthesize seeds;

- (id) initWithFlyThruAdapter:(FlyThruAdapter*)aFlyThruAdapter
{
	self = [super initWithFlyThruAdapter: aFlyThruAdapter];
	
	self.seeds = [NSMutableArray array];
	
	return self;
}

- (void)dealloc{
	[seeds release];
	[super dealloc];
}

- (void)compute{
	// Create centerline
	// get ViewerController, EndoscopyViewer, and pixlist.
	ViewerController *viewer2D = [(EndoscopyVRController *)controller3D viewer2D];
	EndoscopyViewer *endoscopyViewer = [viewer2D openEndoscopyViewer];
	NSArray *pixList = [viewer2D pixList];
	int count = [pixList count];
	// coordinates conversion  need to convert by 'the factor' to get final conversion
	double pos[3], pos2D[3];
	float factor = [(EndoscopyVRController *)controller3D factor];
	pos[0] = [[self.currentCamera position] x];
	pos[1] = [[self.currentCamera position] y];
	pos[2] = [[self.currentCamera position] z];

	[[(EndoscopyVRController *)controller3D view] convert3Dto2Dpoint:pos :pos2D];
	pos2D[0] /= factor;
	pos2D[1] /= factor;
	pos2D[2] /= factor;
	// Pixlists in VR are reversed from the Viewer Controller
	//pos2D[2] = count - pos2D[2];
	OSIVoxel *seed = [OSIVoxel pointWithX:pos2D[0]  y:pos2D[1]  z:pos2D[2] value:nil];
	[seeds addObject:seed];
	
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWithPix :[viewer2D pixList]  volume:[viewer2D volumePtr]   slice:-1  resampleData:NO];
	NSArray *centerlinePoints = [[itk endoscopySegmentationForViewer:viewer2D seeds:seeds] copy];
	[itk release];
	
	count  = [centerlinePoints count] - 1;
	//NSLog(@"Centerline count: %d", count);
	NSMutableArray *steps = [NSMutableArray array];
	for (int i = 0; i < count; i++) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		OSIVoxel *firstPoint = [centerlinePoints objectAtIndex:i];
		OSIVoxel *secondPoint = [centerlinePoints objectAtIndex:i + 1];
		[endoscopyViewer setCameraPosition:firstPoint  
			focalPoint:secondPoint];
		[steps addObject:self.currentCamera];
		[pool release];		
	}
	for (int i = count; i > 0; i--) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		OSIVoxel *firstPoint = [centerlinePoints objectAtIndex:i];
		OSIVoxel *secondPoint = [centerlinePoints objectAtIndex:i - 1];
		[endoscopyViewer setCameraPosition:firstPoint  
			focalPoint:secondPoint];
		[steps addObject:self.currentCamera];
		[pool release];	
	}
	[centerlinePoints release];
	[stepsArrayController addObjects:steps];
	self.tabIndex = 1;
	
	//NSLog(@"end compute centerline: %d", [steps count]);
	
}

- (IBAction)calculate: (id)sender{
	[self compute];
}

@end
