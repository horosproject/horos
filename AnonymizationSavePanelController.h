//
//  AnonymizationSavePanelController.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/20/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

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
