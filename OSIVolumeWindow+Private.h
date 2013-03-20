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
#import "OSIVolumeWindow.h"

@class ViewerController;
@class DCMView;

@interface OSIVolumeWindow (Private)

- (id)initWithViewerController:(ViewerController *)viewerController;
- (void)viewerControllerDidClose;
- (void)viewerControllerWillChangeData;
- (void)viewerControllerDidChangeData;

- (void)drawInDCMView:(DCMView *)dcmView;
- (void)setNeedsDisplay;

@end




