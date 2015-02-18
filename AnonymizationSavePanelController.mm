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

#import "AnonymizationSavePanelController.h"
#import "AnonymizationViewController.h"
#import "NSFileManager+N2.h"


@implementation AnonymizationSavePanelController

@synthesize outputDir;

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values {
	return [self initWithTags:shownDcmTags values:values nibName:@"AnonymizationSavePanel"];
}

-(void)dealloc {
	NSLog(@"AnonymizationSavePanelController dealloc");
	self.outputDir = NULL;
	[super dealloc];
}

#pragma mark Save Panel

-(IBAction)actionOk:(NSView*)sender {
	end = AnonymizationPanelOk;
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	panel.canChooseFiles = NO;
	panel.canChooseDirectories = YES;
	panel.canCreateDirectories = YES;
	panel.allowsMultipleSelection = NO;
	panel.accessoryView = NULL;
	panel.message = NSLocalizedString(@"Select the location where to export the DICOM files:", NULL);
	panel.prompt = NSLocalizedString(@"Choose", NULL);
	// TODO: save and reuse location
	[panel beginSheetForDirectory:NULL file:NULL modalForWindow:self.window modalDelegate:self didEndSelector:@selector(saveAsSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)saveAsSheetDidEnd:(NSOpenPanel*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	if (returnCode == 1) {
		self.outputDir = [sheet.filenames objectAtIndex:0];
		[NSApp endSheet:self.window];
	}
}

-(IBAction)actionAdd:(NSView*)sender {
	end = AnonymizationSavePanelAdd;
	[NSApp endSheet:self.window];
}

-(IBAction)actionReplace:(NSView*)sender {
	end = AnonymizationSavePanelReplace;
	[NSApp endSheet:self.window];
}

@end
