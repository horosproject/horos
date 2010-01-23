//
//  ShadingArrayController.h
//  OsiriX
//
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "OSIWindowController.h"

@interface ShadingArrayController : NSArrayController {
	BOOL				_enableEditing;
	OSIWindowController	*winController;
}

- (BOOL)enableEditing;
- (void)setEnableEditing:(BOOL)enable;
- (void)setWindowController:(OSIWindowController*) ctrl;

@end
