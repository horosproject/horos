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
#import "OrthogonalMPRController.h"
#import "ViewerController.h"

@class LLMPRViewer;
@class ViewerController;

@interface LLScoutViewer : NSWindowController <NSWindowDelegate>
{
	IBOutlet OrthogonalMPRController	*mprController;
	ViewerController					*viewer, *blendingViewer;
	int									topLimit, bottomLimit;
	LLMPRViewer							*mprViewerTop, *mprVieweMiddle, *mprViewerBottom;
	NSArray								*dcmPixList, *dcmFileList;
}

+ (BOOL)haveSamePixelSpacing:(NSArray*)pixA :(NSArray*)pixB;
+ (BOOL)haveSameImagesCount:(NSArray*)pixA :(NSArray*)pixB;
+ (BOOL)haveSameImagesLocations:(NSArray*)pixA :(NSArray*)pixB;
+ (BOOL)verifyRequiredConditions:(NSArray*)pixA :(NSArray*)pixB;

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC;

- (BOOL)is2DViewer;

- (void)setTopLimit:(int)top bottomLimit:(int)bottom;
- (void)displayMPR:(int)index;

- (void)toggleDisplayResliceAxes;
- (void)blendingPropagateOriginal:(OrthogonalMPRView*)sender;
- (void)blendingPropagateX:(OrthogonalMPRView*)sender;
- (void)blendingPropagateY:(OrthogonalMPRView*)sender;

- (void)CloseViewerNotification:(NSNotification*)note;

- (BOOL)isStackUpsideDown;

@end
