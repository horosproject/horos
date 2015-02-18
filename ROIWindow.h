/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/




#import <AppKit/AppKit.h>
#import "ROI.h"
#import "MyNSTextView.h"
#import "ViewerController.h"

/** \brief Window Controller for ROI */

@interface ROIWindow : NSWindowController <NSComboBoxDataSource>
{	
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
	
	NSTimer					*getName;
	
	NSString				*previousName;
}
- (IBAction)acceptSheet:(id)sender;
- (IBAction) recalibrate:(id) sender;
- (id) initWithROI: (ROI*) iroi :(ViewerController*) c;
- (IBAction) exportData:(id) sender;
- (IBAction) histogram:(id) sender;
- (IBAction) plot:(id) sender;
- (ROI*) curROI;
- (IBAction) setColor:(NSColorWell*) sender;
- (IBAction) setThickness:(NSSlider*) sender;
- (IBAction) setOpacity:(NSSlider*) sender;
- (IBAction) setTextData:(id) sender;
- (IBAction) roiSaveCurrent: (id) sender;
- (void) setROI: (ROI*) iroi :(ViewerController*) c;
- (BOOL) allWithSameName;
- (void) windowWillClose:(NSNotification *)notification;

@end
