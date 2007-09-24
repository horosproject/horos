//
//  EndoscopySegmentationController.m
//  OsiriX
//
//  Created by Lance Pysher on 4/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "EndoscopySegmentationController.h"
#import "ITKSegmentation3D.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#import "browserController.h"
#import "OSIPoint3D.h"


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
				   name: @"mouseDown"
				 object: nil];
				 
		
		[nc addObserver: self
				selector: @selector(drawStartingPoint:)
				   name: @"PLUGINdrawObjects"
				 object: nil];
				 
//		[nc addObserver: self
//				selector: @selector(removeROI:)
//				   name:  @"removeROI"
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
               name: @"CloseViewerNotification"
             object: nil];
	
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self release];
}

-(void) closeViewerNotification:(NSNotification*) note
{
	if( [note object] == _viewer) [self close];
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
		[[[_viewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location];
		xmm = location[0];
		ymm = location[1];
		zmm = location[2];
		
		[self addSeed:[OSIPoint3D pointWithX:xpx  y:ypx  z:zpx value:nil]];
		
	//	[self setStartingPointPixelPosition:[NSString stringWithFormat:NSLocalizedString(@"px:\t\tx:%d y:%d", 0L), xpx, ypx]];
	//	[self setStartingPointWorldPosition:[NSString stringWithFormat:NSLocalizedString(@"mm:\t\tx:%2.2f y:%2.2f z:%2.2f", 0L), xmm, ymm, zmm]];
	//	[self setStartingPointValue:[NSString stringWithFormat:NSLocalizedString(@"value:\t%2.2f", 0L), [[[_viewer imageView] curDCM] getPixelValueX: xpx Y:ypx]]];
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
	[itk endoscopySegmentationForViewer:_viewer seeds:_seeds];
	[itk release];
}

- (IBAction)calculate: (id)sender{
	[self compute];
}


@end
