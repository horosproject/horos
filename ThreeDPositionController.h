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

#import <Cocoa/Cocoa.h>
@class ViewerController;
@class DCMView;

/** \brief Window Controller for the ThreeDPosition. The ThreeDPosition provides a GUI to move a 3D DataSet in space (3D coordinates).*/
@interface ThreeDPositionController : NSWindowController
{
	ViewerController *viewerController;
}

+ (ThreeDPositionController*) threeDPositionController;
- (id)initWithViewer:(ViewerController*)viewer;
- (void)setViewer:(ViewerController*)viewer;
- (IBAction) changePosition:(id) sender;

@property(readonly) ViewerController *viewerController;

@end
