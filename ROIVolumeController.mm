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
#import "ROIVolume.h"
#import "ROIVolumeController.h"
#import "ROIVolumeView.h"

#import "DCMView.h"

@implementation ROIVolumeController

- (IBAction) changeParameters:(id) sender
{
	[view setOpacity: [opacity floatValue] showPoints: [showPoints state] showSurface: [showSurfaces state]];
}

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
	
	roiVolume = 0L;
	viewer = iviewer;
	
    self = [super initWithWindowNibName:@"ROIVolume"];
    
    [[self window] setDelegate:self];
    
	[view setPixSource:pts];
	
	if( volume < 0.01)
		[volumeField setStringValue: [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f mm3.", nil), volume*1000.]];
	else
		[volumeField setStringValue: [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f cm3.", nil), volume]];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
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

	roiVolume = [[ROIVolume alloc] init];
	[roiVolume setROIList: roiList];
	
	[view setROIActorVolume:[roiVolume roiVolumeActor]];
	
	if( volume < 0.01)
		[volumeField setStringValue: [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f mm3.", nil), volume*1000.]];
	else
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
	
	[roiVolume release];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[self window] setDelegate:nil];
    
    [self release];
}
@end
