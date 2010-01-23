/*=========================================================================
  Program:   OsiriX

  Copyright(c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <Cocoa/Cocoa.h>

@class FlyThruController;


/** \brief  Manages the array of FlyThru steps
*
* A subclass of NSArrayController used to manage the steps of the flythru.
* Each step consists of a Camera -- See Camera.h
* Uses the usual NSArrayController methods.
*/


@interface FlyThruStepsArrayController : NSArrayController {
	IBOutlet FlyThruController *flyThruController;
	IBOutlet NSTableView	*tableview;
}

- (IBAction) flyThruButton:(id) sender;
- (void) flyThruTag:(int) x;
- (void) resetCameraIndexes;
- (IBAction)updateCamera:(id)sender;
- (IBAction)resetCameras:(id)sender;
- (void) keyDown:(NSEvent *)theEvent;

@end
