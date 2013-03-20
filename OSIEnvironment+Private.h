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
#import "OSIEnvironment.h"

@class ViewerController;
@class DCMView;

@interface OSIEnvironment (Private)

- (void)addViewerController:(ViewerController *)viewerController;
- (void)removeViewerController:(ViewerController *)viewerController;

- (void)viewerControllerWillChangeData:(ViewerController *)viewerController;
- (void)viewerControllerDidChangeData:(ViewerController *)viewerController;

- (void)drawDCMView:(DCMView *)dcmView;

@end
