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
#import "ROIVolumeController.h"
#import "ROIVolumeView.h"
#import "Notifications.h"
#import "ROI.h"
#import "DCMView.h"

@implementation ROIVolumeController

@synthesize volumeField, seriesName;

- (ViewerController*) viewer
{
	return viewer;
}

- (IBAction) changeParameters:(id) sender
{
	[view setOpacity: [opacity floatValue] showPoints: [showPoints state] showSurface: [showSurfaces state] showWireframe: [showWireframe state] texture: [textured state] useColor: [color state] color: [[colorWell color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]];
	
}

- (IBAction) reload:(id)sender
{
	[view renderVolume];
	
	[self changeParameters: self];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == viewer)
	{
		[[self window] close];
	}
}

- (id) initWithRoi:(ROI*) iroi  viewer:(ViewerController*) iviewer
{
	viewer = [iviewer retain];
	roi = [iroi retain];
	
    self = [super initWithWindowNibName:@"ROIVolume"];
    
    [[self window] setDelegate:self];
    
	NSDictionary *data = [view setPixSource: roi];
    if( data == nil)
    {
        [self autorelease];
        return nil;
    }
    
    NSMutableString	*s = [NSMutableString string];
    
    if( roi.name && roi.name.length > 0)
        [s appendString: [NSString stringWithFormat:NSLocalizedString(@"%@\r", nil), roi.name]];
    
    NSString *volumeString;
    
    if( [[data objectForKey: @"volume"] floatValue] < 0.01)
        volumeString = [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f mm\u00B3", @"mm\u00B3 == mm3"), [[data objectForKey: @"volume"] floatValue]*1000.];
    else
        volumeString = [NSString stringWithFormat:NSLocalizedString(@"Volume : %2.4f cm\u00B3", @"cm\u00B3 == mm3"), [[data objectForKey: @"volume"] floatValue]];
    
    [s appendString: volumeString];
    
    [s appendString: [NSString stringWithFormat:NSLocalizedString(@"\rMean: %2.4f SDev: %2.4f Total: %2.4f", nil), [[data valueForKey:@"mean"] floatValue], [[data valueForKey:@"dev"] floatValue], [[data valueForKey:@"total"] floatValue]]];
    [s appendString: [NSString stringWithFormat:NSLocalizedString(@"\rMin: %2.4f Max: %2.4f ", nil), [[data valueForKey:@"min"] floatValue], [[data valueForKey:@"max"] floatValue]]];
    if( [data valueForKey:@"skewness"] && [data valueForKey:@"kurtosis"])
        [s appendString: [NSString stringWithFormat:NSLocalizedString(@"\rSkewness: %2.4f Kurtosis: %2.4f ", nil), [[data valueForKey:@"skewness"] floatValue], [[data valueForKey:@"kurtosis"] floatValue]]];
    
	[volumeField setStringValue: s];
	[seriesName setStringValue: volumeString];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
		   selector: @selector(CloseViewerNotification:)
			   name: OsirixCloseViewerNotification
			 object: nil];
	
	[self changeParameters: self];
	
    return self;
}

-(void) dealloc
{
    NSLog(@"Dealloc ROIVolumeController");
	
	[viewer release];
	[roi release];
	
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
    [[self window] setDelegate:nil];
    
    [self autorelease];
}

- (ROI*) roi
{
	return roi;
}

@end
