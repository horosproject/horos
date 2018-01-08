/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "PaletteController.h"
#import "ViewerController.h"
#import "ROI.h"
#import "Notifications.h"

@implementation PaletteController

//- (IBAction)changeColor:(id)sender
//{
//	long			i, x;
//	BOOL			done = NO;
//	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
//	NSMutableArray	*selectedRois = [NSMutableArray array ];
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
//		[[sender color] getRed:&r green:&g blue:&b alpha:nil];
//	
//		RGBColor c;
//		
//		c.red = r * 65535.;
//		c.green = g * 65535.;
//		c.blue = b * 65535.;
//		
//		[(ROI*) [selectedRois objectAtIndex:i] setColor:c];
//		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:[selectedRois objectAtIndex:i] userInfo: nil];
//	}
//}

//- (IBAction)changeOpacity:(id)sender
//{
//	[opacityTextValue setStringValue: [NSString stringWithFormat:@"%0.1f", [sender floatValue]]];
//	
//	long			i, x;
//	BOOL			done = NO;
//	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
//	NSMutableArray	*selectedRois = [NSMutableArray array ];
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
//		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:[selectedRois objectAtIndex:i] userInfo: nil];
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
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"ROIRegionThickness"] == 0)
	{
		[[NSUserDefaults standardUserDefaults] setFloat: 2.0 forKey:@"ROIRegionThickness"];
	}
	
	[[self window] setFrameAutosaveName:@"BrushTool"];
	[[self window] setDelegate:self];
		
	viewer = v;
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];

	[self showWindow:self];
	
	[viewer setROIToolTag: tPlain];
	
	return self;
}

-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		[[self window] close];
	}
}

- (void) dealloc
{
	NSLog( @"PaletteController dealloc");
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[self autorelease];
}
@end
