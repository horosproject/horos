/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
#import "ROIVolumeController.h"
#import "ROIVolumeView.h"
#import "ROIVolume.h"
#import "DCMView.h"

@implementation ROIVolumeController

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == viewer)
	{
		[[self window] setDelegate:nil];
		[self release];
	}
}

-(id) initWithPoints:(NSMutableArray*) pts :(float) volume :(ViewerController*) iviewer
{
    unsigned long   i;
	
	viewer = iviewer;
	
    self = [super initWithWindowNibName:@"ROIVolume"];
    
    [[self window] setDelegate:self];
    
	[view setPixSource:pts];
	
	[volumeField setStringValue: [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f cm3.", nil), volume]];
	
	NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
	
    return self;
}

-(id) initWithROIs:(NSArray*) roiList :(float) volume :(ViewerController*) iviewer
{
    unsigned long   i;
	
	viewer = iviewer;
	
    self = [super initWithWindowNibName:@"ROIVolume"];
    
    [[self window] setDelegate:self];

    ROIVolume *roiVolume = [[ROIVolume alloc] init];
	[roiVolume setROIList: roiList];
	
	[view setROIActorVolume:[roiVolume roiVolumeActor]];
	
	[volumeField setStringValue: [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f cm3.", nil), volume]];
	
	NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
	
    return self;
}

-(void) dealloc
{
    NSLog(@"Dealloc ROIVolumeController");
	
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[self window] setDelegate:nil];
    
    [self release];
}
@end
