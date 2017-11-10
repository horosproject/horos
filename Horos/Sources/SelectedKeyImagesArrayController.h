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
#import "AllKeyImagesArrayController.h"


 /** \brief  Controller for array of keyImages */
 

@interface SelectedKeyImagesArrayController : AllKeyImagesArrayController {
	
}

- (void)addKeyImages:(NSNotification *)note;
- (void)select:(id)sender;

@end
