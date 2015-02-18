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


#import "AnonymizationPanelController.h"
#import "AnonymizationViewController.h"
#import "NSFileManager+N2.h"


@interface AnonymizationPanelController ()

@property(retain,readwrite) AnonymizationViewController* anonymizationViewController;

@end

@implementation AnonymizationPanelController

@synthesize containerView;
@synthesize anonymizationViewController;
@synthesize end;
@synthesize representedObject;

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values {
	return [self initWithTags:shownDcmTags values:values nibName:@"AnonymizationPanel"];
}

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values nibName:(NSString*)nibName {
	self = [super initWithWindowNibName:nibName];
	[self window]; // load
	
	self.anonymizationViewController = [[[AnonymizationViewController alloc] initWithTags:shownDcmTags values:values] autorelease];
	self.anonymizationViewController.view.frame = containerView.bounds;
	[containerView addSubview:self.anonymizationViewController.view];
	[self.anonymizationViewController adaptBoxToAnnotations];
	
	return self;
}

-(void)dealloc {
	NSLog(@"AnonymizationPanelController dealloc");
	self.anonymizationViewController = NULL;
	self.representedObject = NULL;
	[super dealloc];
}

#pragma mark Panel

-(IBAction)actionOk:(NSView*)sender {
	end = AnonymizationPanelOk;
	[NSApp endSheet:self.window];
}

-(IBAction)actionCancel:(NSView*)sender {
	end = AnonymizationPanelCancel;
	[NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}

@end
