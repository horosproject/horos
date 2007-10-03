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

/** \brief Managed the GUI for Endoscopy flythroughs
*
*  Window controller for Endoscopy flythrus
*  Subclass of Flythru Controller.
*  Single property is NSMutableArray *seeds
*/ 

#import <Cocoa/Cocoa.h>
#import "FlyThruController.h"


@class EndoscopyVRController;
@class EndoscopyViewer;

@interface EndoscopyFlyThruController : FlyThruController {
	NSMutableArray *seeds;
	EndoscopyViewer *vrViewer;
	
}

@property (readwrite, retain) NSMutableArray *seeds;

- (void)compute;
- (IBAction)calculate: (id)sender;

@end
