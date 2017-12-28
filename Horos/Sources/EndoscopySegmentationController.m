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

#import "EndoscopySegmentationController.h"
#import "ITKSegmentation3D.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#import "browserController.h"
#import "OSIVoxel.h"
#import "EndoscopyViewer.h"
#import "Notifications.h"
//#import "VRView.h"


@implementation EndoscopySegmentationController

- (id)initWithViewer:(ViewerController *)viewer{
	if (self = [super initWithWindowNibName:@"CenterlineSegmentation"]) {
		_viewer = viewer;
		_seeds = [[NSMutableArray alloc] init];
		NSLog(@"init Endoscopy Segmentation");
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(mouseViewerDown:)
				   name: OsirixMouseDownNotification
				 object: nil];
				 
		
		[nc addObserver: self
				selector: @selector(drawStartingPoint:)
				   name: OsirixDrawObjectsNotification
				 object: nil];
				 
//		[nc addObserver: self
//				selector: @selector(removeROI:)
//				   name:  OsirixRemoveROINotification
//				 object: nil];
	}
	return self;
}

- (void)dealloc{
	[_seeds release];
	[super dealloc];
}



- (void)windowDidLoad
{
		
	[[self window] setDelegate: self];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
				selector: @selector(windowDidBeomeKey:)
				   name:  NSWindowDidBecomeMainNotification
				 object: [self window]];

	[[NSNotificationCenter defaultCenter] addObserver: self
           selector: @selector(closeViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];
	
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self autorelease];
}

-(void) closeViewerNotification:(NSNotification*) note
{
	if( [note object] == _viewer) [[self window] close];
}

- (void)windowDidBeomeKey:(NSNotification*) note {

}

- (void) mouseViewerDown:(NSNotification*) note
{
	if([note object] == _viewer)
	{
		int xpx, ypx, zpx; // coordinate in pixels
		float xmm, ymm, zmm; // coordinate in millimeters
		
		xpx = [[[note userInfo] objectForKey:@"X"] intValue];
		ypx = [[[note userInfo] objectForKey:@"Y"] intValue];
		zpx = [[_viewer imageView] curImage];
		
		float location[3];
		[[[_viewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location pixelCenter: YES];
		xmm = location[0];
		ymm = location[1];
		zmm = location[2];
		
		[self addSeed:[OSIVoxel pointWithX:xpx  y:ypx  z:zpx value:nil]];
		
	//	[self setStartingPointPixelPosition:[NSString stringWithFormat:NSLocalizedString(@"px:\t\tx:%d y:%d", nil), xpx, ypx]];
	//	[self setStartingPointWorldPosition:[NSString stringWithFormat:NSLocalizedString(@"mm:\t\tx:%2.2f y:%2.2f z:%2.2f", nil), xmm, ymm, zmm]];
	//	[self setStartingPointValue:[NSString stringWithFormat:NSLocalizedString(@"value:\t%2.2f", nil), [[[_viewer imageView] curDCM] getPixelValueX: xpx Y:ypx]]];
	//	_startingPoint = NSMakePoint(xpx, ypx);
		
		//[self compute: self];
		
	}
}

- (void) drawStartingPoint:(NSNotification*) note
{
	if([note object] == [_viewer imageView])
	{
		if( _startingPoint.x != 0 && _startingPoint.y != 0)
		{
			NSDictionary	*userInfo = [note userInfo];
			
			CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
			glColor3f (0.0f, 1.0f, 0.5f);
			glLineWidth(2.0);
			glBegin(GL_LINES);
			
			float crossx, crossy, scaleValue = [[userInfo valueForKey:@"scaleValue"] floatValue];
			
			crossx = _startingPoint.x - [[userInfo valueForKey:@"offsetx"] floatValue];
			crossy = _startingPoint.y - [[userInfo valueForKey:@"offsety"] floatValue];
			
			glVertex2f( scaleValue * (crossx - 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx - 5), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 40), scaleValue*(crossy));
			glVertex2f( scaleValue * (crossx + 5), scaleValue*(crossy));
			
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-40));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy-5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+5));
			glVertex2f( scaleValue * (crossx), scaleValue*(crossy+40));
			glEnd();
		}
	}
}

- (NSArray *)seeds{
	return _seeds;
}
- (void)addSeed:(id)seed{
	[self willChangeValueForKey:@"seeds"];
	[_seeds addObject:seed];
	[self didChangeValueForKey:@"seeds"];
}

- (void)compute{
	//ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWith:[_viewer pixList] :[_viewer volumePtr] :-1];
	ITKSegmentation3D	*itk = [[ITKSegmentation3D alloc] initWithPix :[_viewer pixList]  volume:[_viewer volumePtr]  slice:-1  resampleData:NO];
	NSArray *centerlinePoints = [itk endoscopySegmentationForViewer:_viewer seeds:_seeds];
	[_viewer endoscopyViewer:self];
	EndoscopyViewer *endoscopyViewer = [_viewer openEndoscopyViewer];
	[[endoscopyViewer vrController] flyThruControllerInit:self];
	
	int count  = [centerlinePoints count] - 1;
	for (int i = 0; i < count; i++) {
		OSIVoxel *firstPoint = [centerlinePoints objectAtIndex:i];
		OSIVoxel *secondPoint = [centerlinePoints objectAtIndex:i + 1];
		[endoscopyViewer setCameraPosition:firstPoint  
			focalPoint:secondPoint];
//		[[[endoscopyViewer vrController] flyThruController] flyThruTag:0];
	}
	
	[itk release];
}

- (IBAction)calculate: (id)sender{
	[self compute];
}


@end
