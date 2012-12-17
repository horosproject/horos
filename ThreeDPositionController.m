/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ThreeDPositionController.h"
#import "ThreeDPanView.h"
#import "ViewerController.h"
#import "AppController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "OrthogonalMPRPETCTViewer.h"
#import "Notifications.h"

static ThreeDPositionController *nav = nil;

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
		[axialPan setController: self];
		[verticalPan setController: self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeViewerNotification:) name:OsirixCloseViewerNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:NSApplicationWillBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setWindowLevel:) name:NSApplicationWillResignActiveNotification object:nil];
	}
	return self;
}

- (void) movePositionPosition:(float*) move
{
	for( int i = 0; i < [viewerController maxMovieIndex]; i++)
	{
		for( DCMPix *p in [viewerController pixList: i])
		{
			float o[ 3];
			
			if( move)
			{
				o[ 0] = [p originX] + move[ 0]*[p pixelSpacingX];
				o[ 1] = [p originY] + move[ 1]*[p pixelSpacingY];
				o[ 2] = [p originZ] - move[ 2]*[p sliceInterval];
			}
			else
			{
				o[ 0] = [p originX];
				o[ 1] = [p originY];
				o[ 2] = [p originZ];
			}
			
			[p setOrigin: o];
			
            [p setSliceInterval: 0];
			
            [p computeSliceLocation];
		}
	}
	
	[viewerController computeInterval];
	[viewerController propagateSettings];
	
	for( ViewerController *v in [ViewerController getDisplayed2DViewers])
	{
		[[v imageView] sendSyncMessage: 0];
		[v refresh];
	}
	#ifndef OSIRIX_LIGHT
	for( NSWindow *w in [[NSApplication sharedApplication] windows])
	{
		if( [[w windowController] isKindOfClass: [OrthogonalMPRPETCTViewer class]])
			[[w windowController] realignDataSet: self];
	}
	#endif
}

- (IBAction) reset:(id) sender
{
	[viewerController executeRevert];
	
	[self movePositionPosition: nil];
}

- (IBAction) changeMatrixMode:(id) sender
{
	switch( [matrixMode selectedTag])
	{
		case 0:
			[axialPan setImage: [NSImage imageNamed: @"AxialSmall.tif"]];
			[verticalPan setImage: [NSImage imageNamed: @"CorSmall.tif"]];
		break;
		
		case 1:
			[axialPan setImage: [NSImage imageNamed: @"CorSmall.tif"]];
			[verticalPan setImage: [NSImage imageNamed: @"AxialSmall.tif"]];
		break;
		
		case 2:
			[axialPan setImage: [NSImage imageNamed: @"SagSmall.tif"]];
			[verticalPan setImage: [NSImage imageNamed: @"AxialSmall.tif"]];
		break;
	}
}

- (int) mode
{
	return [matrixMode selectedTag];
}

- (IBAction) changePosition:(id) sender
{
	float move[ 3] = { 0, 0, 0};
	
	switch( [matrixMode selectedTag])
	{
		case 0:
			switch( [sender tag])
			{
				case 0:			move[ 0] -= 1/2.;		break;
				case 1:			move[ 0] += 1/2.;		break;
				case 2:			move[ 1] += 1/2.;		break;
				case 3:			move[ 1] -= 1/2.;		break;
				case 4:			move[ 2] += 1/2.;		break;
				case 5:			move[ 2] -= 1/2.;		break;
				case 6:			move[ 0] -= 1/2.;		break;
				case 7:			move[ 0] += 1/2.;		break;
			}
		break;
		
		case 1:
			switch( [sender tag])
			{
				case 0:			move[ 0] -= 1/2.;		break;
				case 1:			move[ 0] += 1/2.;		break;
				case 2:			move[ 2] += 1/2.;		break;
				case 3:			move[ 2] -= 1/2.;		break;
				case 4:			move[ 1] += 1/2.;		break;
				case 5:			move[ 1] -= 1/2.;		break;
				case 6:			move[ 0] -= 1/2.;		break;
				case 7:			move[ 0] += 1/2.;		break;
			}
		break;
		
		case 2:
			switch( [sender tag])
			{
				case 0:			move[ 1] -= 1/2.;		break;
				case 1:			move[ 1] += 1/2.;		break;
				case 2:			move[ 2] += 1/2.;		break;
				case 3:			move[ 2] -= 1/2.;		break;
				case 4:			move[ 0] += 1/2.;		break;
				case 5:			move[ 0] -= 1/2.;		break;
				case 6:			move[ 0] -= 1/2.;		break;
				case 7:			move[ 0] += 1/2.;		break;
			}
		break;
	}
	
	[self movePositionPosition: move];
}

- (void)awakeFromNib; 
{
	[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)setViewer:(ViewerController*)viewer;
{
	[viewer checkEverythingLoaded];
	
	if( viewerController == nil)
	{
		[matrixMode selectCellWithTag: [viewer currentOrientationTool]];
		[self changeMatrixMode: self];
	}
	
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
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[self window] orderOut:self];
    
	[self autorelease];
}

- (void)dealloc
{
	NSLog(@"ThreeDPositionController dealloc");
	nav = nil;
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