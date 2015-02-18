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

@class ViewerController;


/** \brief Segmentation WindowController
*/


@interface ITKSegmentation3DController : NSWindowController {

				ViewerController		*viewer, *resultsViewer;

	// parameters
	IBOutlet	NSBox					*parametersBox;
	IBOutlet	NSMatrix				*growingMode;
	IBOutlet	NSPopUpButton			*algorithmPopup;
				NSPoint					startingPoint;
	IBOutlet	NSTextField				*startingPointWorldPosition, *startingPointPixelPosition, *startingPointValue;
	IBOutlet	NSForm					*params;
	// results
	IBOutlet	NSBox					*resultsBox;
	IBOutlet	NSMatrix				*outputResult;
	IBOutlet	NSMatrix				*pixelsSet;
	IBOutlet	NSMatrix				*pixelsValue;
	IBOutlet	NSSlider				*roiResolution;
	IBOutlet	NSTextField				*newName;

	IBOutlet	NSButton				*computeButton;
	
	// Algorithms
				NSArray			*algorithms;
				NSArray			*parameters;
				NSArray			*defaultsParameters;
				NSArray			*urlHelp;
}
+ (id) segmentationControllerForViewer:(ViewerController*) v;

- (IBAction) compute:(id) sender;
- (IBAction) preview:(id) sender;
- (id) initWithViewer:(ViewerController*) v;
- (ViewerController*) viewer;
- (IBAction) changeAlgorithm: (id) sender;
- (void) setNumberOfParameters: (int) n;

- (IBAction) algorithmGetHelp:(id) sender;
- (void) fillAlgorithmPopup;

@end
