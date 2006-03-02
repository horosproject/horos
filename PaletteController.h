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



#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "ROI.h"
@class ViewerController;
@interface PaletteController : NSWindowController
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
