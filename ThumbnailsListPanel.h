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

#import <AppKit/AppKit.h>
#import "ViewerController.h"

@interface ThumbnailsListPanel : NSWindowController
{	
	NSView                  *thumbnailsView;
    NSView                  *superView;
	long					screen;
	ViewerController		*viewer;
	BOOL					dontReenter;
}

@property (readonly) ViewerController *viewer;

+ (long) fixedWidth;
- (void) setThumbnailsView :(NSView*) tb viewer:(ViewerController*) v;
- (void) thumbnailsListWillClose :(NSView*) tb;
- (id)initForScreen: (long) s;
- (NSView*) thumbnailsView;
+ (void) checkScreenParameters;

@end
