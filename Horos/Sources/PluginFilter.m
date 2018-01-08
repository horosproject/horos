/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/


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
