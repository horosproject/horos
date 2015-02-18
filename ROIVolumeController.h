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




#import <Cocoa/Cocoa.h>
#import "DCMPix.h"
#import "ViewerController.h"
#import "Window3DController.h"

@class ROIVolumeView;

/** \brief  Window Controller for ROI Volume display */

@interface ROIVolumeController : Window3DController <NSWindowDelegate>
{
    IBOutlet ROIVolumeView			*view;
	IBOutlet NSTextField			*volumeField, *seriesName;
	
	IBOutlet NSButton				*showSurfaces, *showPoints, *showWireframe, *textured, *color;
	IBOutlet NSColorWell			*colorWell;
	IBOutlet NSSlider				*opacity;
	
	ViewerController				*viewer;
	ROI								*roi;
}

@property (readonly) NSTextField *volumeField, *seriesName;

- (id) initWithRoi:(ROI*) iroi  viewer:(ViewerController*) iviewer;
- (IBAction) changeParameters:(id) sender;
- (ViewerController*) viewer;
- (ROI*) roi;
- (IBAction) reload:(id)sender;
@end