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


#import "PluginFilter.h"

@implementation PluginFilter

+ (PluginFilter *)filter
{
    return [[[self alloc] init] autorelease];
}

- (id)init {
	if (self = [super init])
	{
		[self initPlugin];
	}
	return self;
}

- (void) willUnload
{
    // Subclass this function if needed: Plugin will unload : prepare for dealloc: release memory and kill sub-process
}

- (void) dealloc
{
	NSLog( @"PluginFilter dealloc");
	
	[super dealloc];
}

- (void) initPlugin
{
	return;
}

- (void)setMenus {  // Opportunity for plugins to make Menu changes if necessary
	return;
}

- (long) prepareFilter:(ViewerController*) vC
{
	NSLog( @"Prepare Filter");
	viewerController = vC;
	
	return 0;
}

- (BOOL) isCertifiedForMedicalImaging
{
    return NO;
}

- (ViewerController*) duplicateCurrent2DViewerWindow
{
	return [viewerController copyViewerWindow];
}

- (NSArray*) viewerControllersList
{
	return [ViewerController getDisplayed2DViewers];
}

- (long) filterImage:(NSString*) menuName
{
	NSLog( @"Error, you should not be here!: %@", menuName);
    return -1;
}

- (long) processFiles: (NSMutableArray*) files
{
	
	return 0;
}

- (id) report: (NSManagedObject*) study action:(NSString*) action
{
	return 0;
}

// Following stubs are to be subclassed.  Included here to remove compile-time warning messages.

- (id)reportDateForStudy: (NSManagedObject*)study {
	return nil;
}

- (BOOL)deleteReportForStudy: (NSManagedObject*)study {
	return NO;
}

- (BOOL)createReportForStudy: (NSManagedObject*)study {
	return NO;
}

@end
