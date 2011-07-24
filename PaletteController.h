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



#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "ROI.h"
@class ViewerController;

/** \brief  Window Controller for ROI palette */

@interface PaletteController : NSWindowController <NSWindowDelegate>
{
	ViewerController			*viewer;
	IBOutlet NSSegmentedControl	*modeControl;
	IBOutlet NSSlider			*sizeSlider;
	IBOutlet NSTextField		*sliderTextValue;
}
- (id) initWithViewer:(ViewerController*) v;
- (IBAction)changeBrushSize:(id)sender;
- (IBAction)changeMode:(id)sender;
@end
