/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/




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
