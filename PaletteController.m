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



#import "PaletteController.h"
#import "ViewerController.h"
#import "ROI.h"

@implementation PaletteController

//- (IBAction)changeColor:(id)sender
//{
//	long			i, x;
//	BOOL			done = NO;
//	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
//	NSMutableArray	*selectedRois = [NSMutableArray arrayWithCapacity: 0 ];
//	
//	for( i = 0; i < [curRoiList count]; i++)
//	{
//		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selectedModify || [[curRoiList objectAtIndex:i] ROImode] == ROI_drawing)
//		{
//			[selectedRois addObject: [curRoiList objectAtIndex:i]];
//		}
//	}
//	
//	for( i = 0; i < [curRoiList count]; i++)
//	{
//		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
//		{
//			[selectedRois addObject: [curRoiList objectAtIndex:i]];
//		}
//	}
//
//	for( i = 0; i < [selectedRois count]; i++)
//	{
//		float r, g, b;
//	
//		[[sender color] getRed:&r green:&g blue:&b alpha:0L];
//	
//		RGBColor c;
//		
//		c.red = r * 65535.;
//		c.green = g * 65535.;
//		c.blue = b * 65535.;
//		
//		[(ROI*) [selectedRois objectAtIndex:i] setColor:c];
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:[selectedRois objectAtIndex:i] userInfo: 0L];
//	}
//}

//- (IBAction)changeOpacity:(id)sender
//{
//	[opacityTextValue setStringValue: [NSString stringWithFormat:@"%0.1f", [sender floatValue]]];
//	
//	long			i, x;
//	BOOL			done = NO;
//	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
//	NSMutableArray	*selectedRois = [NSMutableArray arrayWithCapacity: 0 ];
//	
//	for( i = 0; i < [curRoiList count]; i++)
//	{
//		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selectedModify || [[curRoiList objectAtIndex:i] ROImode] == ROI_drawing)
//		{
//			[selectedRois addObject: [curRoiList objectAtIndex:i]];
//		}
//	}
//	
//	for( i = 0; i < [curRoiList count]; i++)
//	{
//		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
//		{
//			[selectedRois addObject: [curRoiList objectAtIndex:i]];
//		}
//	}
//	
//	for( i = 0; i < [selectedRois count]; i++)
//	{
//		[(ROI*) [selectedRois objectAtIndex:i] setOpacity:[sender floatValue]];
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:[selectedRois objectAtIndex:i] userInfo: 0L];
//	}
//	
//}

- (IBAction)changeBrushSize:(id)sender
{
	[sliderTextValue setIntValue: [sender intValue] ];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[sender floatValue] forKey:@"ROIRegionThickness"];
}

- (void)awakeFromNib
{
	[sliderTextValue setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey: @"ROIRegionThickness"]];
	
	// init brush size
	[sizeSlider setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey: @"ROIRegionThickness"]];
	
	[[viewer imageView] setEraserFlag: [modeControl selectedSegment]];
}

- (IBAction)changeMode:(id)sender
{
	[viewer setROIToolTag: tPlain];
	
	[[viewer imageView] setEraserFlag: [sender selectedSegment]];
}

- (id) initWithViewer:(ViewerController*) v
{
	self = [super initWithWindowNibName:@"PaletteBrush"];

	[[self window] setFrameAutosaveName:@"BrushTool"];
	[[self window] setDelegate:self];
		
	viewer = v;
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: @"CloseViewerNotification"
             object: nil];

	[self showWindow:self];
	
	[viewer setROIToolTag: tPlain];
	
	return self;
}

-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		[self close];
	}
}

- (void) dealloc
{
	NSLog( @"PaletteController dealloc");
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}


/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/
- (void)windowWillClose:(NSNotification *)notification
{
	[self release];
}
@end
