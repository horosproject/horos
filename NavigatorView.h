/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "ViewerController.h"

typedef enum {
	zoom = tZoom,
	pan = tTranslate,
	wlww = tWL,
	rotate = tRotate,
	idle = -1
} mouseEventType;

@interface NavigatorView : NSOpenGLView {
	ViewerController *viewer;
	NSMutableArray *thumbnailsTextureArray;
	int thumbnailWidth, thumbnailHeight;

	NSPoint mouseDownPosition, mouseDraggedPosition;
	mouseEventType userAction;
	NSPoint translation;
}

@property(readonly) int thumbnailWidth, thumbnailHeight;

- (void)setViewer:(ViewerController*)v;
- (void)generateTextures;
- (void)initTextureArray;
- (void)generateTextureForSlice:(int)z movieIndex:(int)t arrayIndex:(int)i;
- (void)computeThumbnailSize;

- (NSPoint)convertPointFromWindowToOpenGL:(NSPoint)pointInWindow;
- (void)translationFrom:(NSPoint)start to:(NSPoint)stop;

@end
