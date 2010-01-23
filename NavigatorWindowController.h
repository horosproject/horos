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
#import "NavigatorView.h"
@class ViewerController;
@class DCMView;

/** \brief Window Controller for the Navigator. The Navigator provides a unrolled view of the selected series (in 3D and in 4D).*/
@interface NavigatorWindowController : NSWindowController
{
	ViewerController *viewerController;
	IBOutlet NavigatorView *navigatorView;
	BOOL dontReEnter;
}

/**  Returns the Navigator Window Controller (which is a unique object).*/
+ (NavigatorWindowController*) navigatorWindowController;
- (void) adjustWindowPosition;
- (id)initWithViewer:(ViewerController*)viewer;
- (void)setViewer:(ViewerController*)viewer;
- (void)initView;
/**  Computes minSize and maxSize of its window.*/
- (void)computeMinAndMaxSize;
- (void)setWindowLevel:(NSNotification*)notification;

@property(readonly) NavigatorView *navigatorView;
@property(readonly) ViewerController *viewerController;

@end
