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
#import "DCMView.h"
#import "ViewerController.h"

@class SRAnnotation;

@interface SRAnnotationController : NSWindowController {
	SRAnnotation *annotation;
	DCMView *view;
	ViewerController *viewer;
	IBOutlet NSMatrix *whichROIsMatrix;
}

- (id)initWithViewerController:(ViewerController*)aViewer;

- (void)beginSheet;
- (void)endSheet;
- (IBAction)endSheet:(id)sender;

- (BOOL)exportAllROIs;
- (BOOL)exportAllROIsForCurrentDCMPix;
- (BOOL)exportSelectedROI;

//- (void)writeResult;
//- (IBAction)export:(id)sender;

@end
