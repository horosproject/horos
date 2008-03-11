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

#import "ThreeDPositionController.h"
#import "ViewerController.h"
#import "AppController.h"
#import "DCMPix.h"
#import "DCMView.h"

static ThreeDPositionController *nav = 0L;

@implementation ThreeDPositionController

@synthesize viewerController;

+ (ThreeDPositionController*) threeDPositionController
{
	return nav;
}

- (id)initWithViewer:(ViewerController*)viewer;
{
	self = [super initWithWindowNibName:@"3DPosition"];
	if (self != nil)
	{
		nav = self;
		
		[self window];	// generate the awake from nib ! and populates the nib variables like navigatorView
		
		[self setViewer: viewer];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeViewerNotification:) name:@"CloseViewerNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:@"NSApplicationWillBecomeActiveNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:@"NSApplicationWillResignActiveNotification" object:nil];
	}
	return self;
}

- (IBAction) changePosition:(id) sender
{
	float move[ 3] = { 0, 0, 0};
	
	DCMPix *d = [[viewerController pixList] objectAtIndex: 0];
	
	switch( [sender tag])
	{
		case 0:			move[ 0] += [d pixelSpacingX];		break;
		case 1:			move[ 0] -= [d pixelSpacingX];		break;
		case 2:			move[ 1] += [d pixelSpacingY];		break;
		case 3:			move[ 1] -= [d pixelSpacingY];		break;
		case 4:			move[ 2] += [d sliceInterval];		break;
		case 5:			move[ 2] -= [d sliceInterval];		break;
	}
	
	for( int i = 0; i < [viewerController maxMovieIndex]; i++)
	{
		for( DCMPix *p in [viewerController pixList: i])
		{
			float o[ 3];
			
			o[ 0] = [p originX] + move[ 0];
			o[ 1] = [p originY] + move[ 1];
			o[ 2] = [p originZ] + move[ 2];
			
			[p setOrigin: o];
			
			[p setSliceInterval: 0];
			
			double orientation[ 9];
			
			[p orientationDouble: orientation];
			
			if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
				[p setSliceLocation: o[ 0]];
			
			if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
				[p setSliceLocation: o[ 1]];
			
			if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
				[p setSliceLocation: o[ 2]];
		}
	}
	
	[viewerController computeInterval];
	[viewerController propagateSettings];
	
	for( ViewerController * v in [ViewerController getDisplayed2DViewers])
	{
		[[v imageView] sendSyncMessage: 0];
		[v refresh];
	}
}

- (void)awakeFromNib; 
{
	[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)setViewer:(ViewerController*)viewer;
{
	if( viewerController != viewer)
	{
		[viewerController release];
		viewerController = [viewer retain];
	}
	
	if( [viewerController isDataVolumicIn4D: YES] == NO)
	{
		NSLog( @"unsupported data for ThreeDPositionController");
		[[self window] close];
		return;
	}
}

- (void)closeViewerNotification:(NSNotification*)notif;
{
	if([[ViewerController getDisplayed2DViewers] count] == 0)
	{
		[[self window] close];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] orderOut:self];
	[self release];
}

- (void)dealloc
{
	NSLog(@"ThreeDPositionController dealloc");
	nav = 0L;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[viewerController release];
	[super dealloc];
}

- (void)setWindowLevel:(NSNotification*)notification;
{
	NSString *name = [notification name];
	if([name isEqualToString:NSApplicationWillBecomeActiveNotification])
		[[self window] setLevel:NSFloatingWindowLevel];
	else if([name isEqualToString:NSApplicationWillResignActiveNotification])
		[[self window] setLevel:[[viewerController window] level]];
}

@end