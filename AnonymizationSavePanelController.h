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

#import "AnonymizationPanelController.h"

enum AnonymizationSavePanelEnds {
	AnonymizationSavePanelSaveAs = AnonymizationPanelOk,
	AnonymizationSavePanelAdd,
	AnonymizationSavePanelReplace
};

@class AnonymizationViewController;

@interface AnonymizationSavePanelController : AnonymizationPanelController {
	NSString* outputDir; // valid if Save As...
}

@property(retain) NSString* outputDir;

-(IBAction)actionOk:(NSView*)sender;
-(IBAction)actionAdd:(NSView*)sender;
-(IBAction)actionReplace:(NSView*)sender;

@end
