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




#import <AppKit/AppKit.h>
#import "ROI.h"
#import "MyNSTextView.h"
#import "ViewerController.h"

/** \brief Window Controller for ROI */

@interface ROIWindow : NSWindowController {
	
	ROI						*curROI;
	ViewerController		*curController;
	
	BOOL					loaded;
	IBOutlet NSButton		*allWithSameName;
	
	IBOutlet NSComboBox		*name;
	IBOutlet MyNSTextView   *comments;
	IBOutlet NSColorWell	*colorButton;
	IBOutlet NSSlider		*thicknessSlider, *opacitySlider;
	IBOutlet NSButton		*recalibrate;
	IBOutlet NSButton		*xyPlot;
	IBOutlet NSButton		*exportToXMLButton;
	IBOutlet NSWindow		*recalibrateWindow;
	IBOutlet NSTextField	*recalibrateValue;
	
	NSMutableArray			*roiNames;
}

@property(readonly) ROI *curROI;
@property(readonly) BOOL allWithSameName;

- (id) initWithROI: (ROI*) iroi :(ViewerController*) c;
- (void) setROI: (ROI*) iroi :(ViewerController*) c;

// Actions
- (IBAction)acceptSheet:(id)sender;
- (IBAction) recalibrate:(id) sender;
- (IBAction) exportData:(id) sender;
- (IBAction) histogram:(id) sender;
- (IBAction) plot:(id) sender;
- (IBAction) setColor:(NSColorWell*) sender;
- (IBAction) setThickness:(NSSlider*) sender;
- (IBAction) setOpacity:(NSSlider*) sender;
- (IBAction) setTextData:(id) sender;
- (IBAction) roiSaveCurrent: (id) sender;
- (IBAction) deleteROI:(id) sender;

@end
