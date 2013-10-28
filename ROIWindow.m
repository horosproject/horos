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




#import "ROIWindow.h"
#import "HistogramWindow.h"
#import "PlotWindow.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "Notifications.h"

@implementation ROIWindow

- (void)comboBoxWillPopUp:(NSNotification *)notification
{
	NSLog(@"will display...");
	roiNames = [curController generateROINamesArray];
	[[notification object] setDataSource: self];
	
	[[notification object] noteNumberOfItemsChanged];
	[[notification object] reloadData];
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	if( roiNames == nil) roiNames = [curController generateROINamesArray];
	
	long i;
	
	for(i = 0; i < [roiNames count]; i++)
	{
		if( [[roiNames objectAtIndex: i] isEqualToString: aString]) return i;
	}
	
	return NSNotFound;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if( roiNames == nil) roiNames = [curController generateROINamesArray];
	return [roiNames count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if ( index > -1 )
    {
		if( roiNames == nil) roiNames = [curController generateROINamesArray];
		return [roiNames objectAtIndex: index];
    }
    
    return nil;
}


- (IBAction) roiSaveCurrent: (id) sender
{
	NSSavePanel     *panel = [NSSavePanel savePanel];
	
	NSMutableArray  *selectedROIs = [NSMutableArray  arrayWithObject:curROI];
	
	[panel setCanSelectHiddenExtension:NO];
	[panel setRequiredFileType:@"roi"];
	
	if( [panel runModalForDirectory:nil file:[[selectedROIs objectAtIndex:0] name]] == NSFileHandlingPanelOKButton)
	{
		[NSArchiver archiveRootObject: selectedROIs toFile :[panel filename]];
	}
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[previousName release];
	previousName = nil;
	
	[super dealloc];
}

- (void) CloseViewerNotification :(NSNotification*) note
{
	if( [note object] == curController)
	{
		[self windowWillClose: nil];
	}
}

- (void) removeROI :(NSNotification*) note
{
	if( [note object] == curROI)
	{
		[self windowWillClose: nil];
	}
}

- (IBAction) recalibrate:(id) sender
{
    int		modalVal;
	float	pixels;
	float   newResolution;
	
    [NSApp beginSheet:recalibrateWindow 
            modalForWindow: [self window]
            modalDelegate:self 
            didEndSelector:NULL 
            contextInfo:NULL];
	
	[recalibrateValue setStringValue: [NSString stringWithFormat:@"%0.3f", (float) [curROI MesureLength :&pixels]] ];
	
    modalVal = [NSApp runModalForWindow:recalibrateWindow];
	
	if( modalVal)
	{
		newResolution = [recalibrateValue floatValue] / pixels;
		newResolution *= 10.0;
		
		for( DCMPix *pix in [curController pixList])
		{
			float previousX = [pix pixelSpacingX];
			
			[pix setPixelSpacingX: newResolution];
			
			if( previousX)
				[pix setPixelSpacingY: [pix pixelSpacingY] * newResolution / previousX];
			else
				[pix setPixelSpacingY: newResolution];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRecomputeROINotification object:curController userInfo: nil];
	}
	
    [NSApp endSheet:recalibrateWindow];
    [recalibrateWindow orderOut:NULL];   
}

- (IBAction)acceptSheet:(id)sender
{
    [NSApp stopModalWithCode: [sender tag]];
}

- (BOOL) allWithSameName
{
	return [allWithSameName state]==NSOnState;
}

- (void) setROI: (ROI*) iroi :(ViewerController*) c
{
	if( curROI == iroi) return;
	
	[curROI setComments: [NSString stringWithString: [comments string]]];	// stringWithString is very important - see NSText string !
	[curROI setName: [name stringValue]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];

	curController = c;
	curROI = iroi;
	
	RGBColor	rgb = [curROI rgbcolor];
	NSColor		*color = [NSColor colorWithDeviceRed:rgb.red/65535. green: rgb.green/65535. blue:rgb.blue/65535. alpha:1.0];
	
	[colorButton setColor: color];
	
	[thicknessSlider setFloatValue: [curROI thickness]];
	[opacitySlider setFloatValue: [curROI opacity]];
	
	[name setStringValue:[curROI name]];
	[name selectText: self];
	[comments setString:[curROI comments]];
		
	if( [curROI type] == tMesure) [recalibrate setEnabled: YES];
	else [recalibrate setEnabled: NO];
	
	if( [curROI type] == tMesure) [xyPlot setEnabled: YES];
	else [xyPlot setEnabled: NO];

	if( [curROI type] == tLayerROI) [exportToXMLButton setEnabled:NO];
	else [exportToXMLButton setEnabled:YES];
}

- (void)roiChange:(NSNotification*)notification;
{
//	ROI* roi = [notification object];
//	[comments setString:[roi comments]];
//	[name setStringValue:[roi name]];
}

- (void) getName:(NSTimer*)theTimer
{
	if( [[name stringValue] isEqualToString: previousName] == NO)
	{
		[self setTextData: name];
		[previousName release];
		previousName = [[name stringValue] retain];
	}
}

- (id) initWithROI: (ROI*) iroi :(ViewerController*) c
{
	self = [super initWithWindowNibName:@"ROI"];
	
	[[self window] setFrameAutosaveName:@"ROIInfoWindow"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiChange:) name:OsirixROIChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(removeROI:) name: OsirixRemoveROINotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(CloseViewerNotification:) name: OsirixCloseViewerNotification object: nil];
	
	getName = [[NSTimer scheduledTimerWithTimeInterval: 0.1 target:self selector:@selector(getName:) userInfo:0 repeats: YES] retain];
	
	roiNames = nil;
	
	[self setROI: iroi :c];
		
	return self;
}

- (void) windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[getName invalidate];
	[getName release];
	getName = nil;
	
	[ROI saveDefaultSettings];
	
	[curROI setComments: [NSString stringWithString: [comments string]]]; 	// stringWithString is very important - see NSText string !
	[curROI setName: [name stringValue]];
	curROI = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
	
	[self autorelease];
}

- (void) setAllMatchingROIsToSameParamsAs: (ROI*) iROI withNewName: (NSString*) newName
{	
	NSArray *roiSeriesList = [curController roiList];	
	
	for ( NSArray *roiImageList in roiSeriesList )
	{
		for ( ROI *roi in roiImageList )
		{
			if ( roi == curROI ) continue;
			
			if ( [[roi name] isEqualToString: [iROI name]] )
			{
				[roi setColor: [iROI rgbcolor]];
				[roi setThickness: [iROI thickness]];
				[roi setOpacity: [iROI opacity]];
				if ( newName ) [roi setName: newName];
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:roi userInfo: nil];
			}
		}
	}
}

- (void) removeAllROIsWithName: (NSString*) roiName
{		
	NSArray *roiSeriesList = [curController roiList];	
	
	for ( NSMutableArray *roiImageList in roiSeriesList )
	{
		int j;
		
		for ( j = 0; j < [roiImageList count]; j++ )
		{
			ROI *roi = [roiImageList objectAtIndex: j ];
			
			if ( [[roi name] isEqualToString: roiName] )
			{
				[roiImageList removeObjectAtIndex: j];
				j--;
			}
		}
	}
	[[curController imageView] setNeedsDisplay: YES];
	
	[self windowWillClose: nil];
}

- (IBAction) setTextData:(id) sender
{
	if ( [self allWithSameName] ) [self setAllMatchingROIsToSameParamsAs: curROI withNewName: [sender stringValue]];
	
	[curROI setName: [sender stringValue]];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
}

- (IBAction) setThickness:(NSSlider*) sender
{
	[curROI setThickness: [sender floatValue]];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
	
	if ( [self allWithSameName] ) [self setAllMatchingROIsToSameParamsAs: curROI withNewName: [curROI name]];
}

- (IBAction) setOpacity:(NSSlider*) sender
{
	[curROI setOpacity: [sender floatValue]];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
	
	if ( [self allWithSameName] ) [self setAllMatchingROIsToSameParamsAs: curROI withNewName: [curROI name]];
}

- (IBAction) setColor:(NSColorWell*) sender
{
//	if( loaded == NO) return;
	
	CGFloat r, g, b;
	
	[[[sender color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:nil];
	
	RGBColor c;
	
	c.red = r * 65535.;
	c.green = g * 65535.;
	c.blue = b * 65535.;
	
	[curROI setColor:c];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
	
	if ( [self allWithSameName] ) [self setAllMatchingROIsToSameParamsAs: curROI withNewName: [curROI name]];

	[comments setTextColor:nil];
}

+ (void) addROIValues: (ROI*) r dictionary: (NSMutableDictionary*) d
{
    if( r.name.length)
        [d setObject: r.name forKey:@"Name"];
    
    if( r.comments.length)
        [d setObject: r.comments forKey:@"Comments"];
    
    NSMutableArray *ROIPoints = [NSMutableArray array];
    for( MyPoint *p in [r points])
        [ROIPoints addObject: NSStringFromPoint( [p point])];
    
    [d setObject: ROIPoints forKey:@"ROIPoints"];
    
    if( [r dataString])
        [d setObject:[r dataString] forKey:@"DataSummary"];
    
    if( [r dataValues])
        [d setObject:[r dataValues] forKey:@"DataValues"];
}

- (IBAction) exportData:(id) sender
{
	if([curROI type]==tPlain)
	{
		NSInteger confirm = NSRunInformationalAlertPanel(NSLocalizedString(@"Export to XML", @""), NSLocalizedString(@"Exporting this kind of ROI to XML will only export the contour line.", @""), NSLocalizedString(@"OK", @""), NSLocalizedString(@"Cancel", @""), nil);
		if(!confirm) return;
	}
	else if([curROI type]==tLayerROI)
	{
		NSRunAlertPanel(NSLocalizedString(@"Export to XML", @""), NSLocalizedString(@"This kind of ROI can not be exported to XML.", @""), NSLocalizedString(@"OK", @""), nil, nil);
		return;
	}
	
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	[panel setCanSelectHiddenExtension:NO];
	[panel setRequiredFileType:@"xml"];
	
	if( [panel runModalForDirectory:nil file:[curROI name]] == NSFileHandlingPanelOKButton)
	{
		NSMutableDictionary *xml = [NSMutableDictionary dictionary];
		
		if( [self allWithSameName])
		{
			NSArray *roiSeriesList = [curController roiList];
			NSMutableArray *roiArray = [NSMutableArray array];
			
			int i;			
			for ( i = 0; i < [roiSeriesList count]; i++ )
			{
				NSArray *roiImageList = [roiSeriesList objectAtIndex: i];
				
				for( ROI *roi in roiImageList )
				{
					if ( [[roi name] isEqualToString: [curROI name]])
					{
						NSMutableDictionary *roiData = [NSMutableDictionary dictionary];
						
                        [ROIWindow addROIValues: roi dictionary: roiData];
						[roiData setObject:[NSNumber numberWithInt: i + 1] forKey: @"Slice"];
						
						[roiArray addObject: roiData];
					}
				}
			}
			
			[xml setObject: roiArray forKey: @"ROI array"];
		}
		
		else // Output curROI only
            [ROIWindow addROIValues: curROI dictionary: xml];
		
		[xml writeToFile:[panel filename] atomically: TRUE];
	}
}

- (IBAction) histogram:(id) sender
{
	NSArray *winList = [NSApp windows];
	BOOL	found = NO;
	
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString:@"Histogram"])
		{
			if( [[loopItem windowController] curROI] == curROI)
			{
				found = YES;
				[[[loopItem windowController] window] makeKeyAndOrderFront:self];
			}
		}
	}
	
	if( found == NO)
	{
		if( [[curROI points] count] > 0)
		{
			HistoWindow* roiWin = [[HistoWindow alloc] initWithROI: curROI];
			[roiWin showWindow:self];
		}
		else NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Cannot create an histogram from this ROI.", nil), nil, nil, nil);
	}
}

- (IBAction) plot:(id) sender
{
	NSArray *winList = [NSApp windows];
	BOOL	found = NO;
	
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString:@"Plot"])
		{
			if( [[loopItem windowController] curROI] == curROI)
			{
				found = YES;
				[[[loopItem windowController] window] makeKeyAndOrderFront:self];
			}
		}
	}
	
	if( found == NO)
	{
		PlotWindow* roiWin = [[PlotWindow alloc] initWithROI: curROI];
		[roiWin showWindow:self];
	}
}

-(ROI*) curROI {return curROI;}

@end
