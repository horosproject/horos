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

// Hanging Protocol Controller manages the current Active Advanced Hanging Protocol.
#import <Cocoa/Cocoa.h>

@class LayoutWindowController;
@class LayoutArrayController;
@interface HangingProtocolController : NSObjectController {
	IBOutlet LayoutWindowController *_layoutWindowController;
	IBOutlet LayoutArrayController *_layoutArrayController;
}



@end
