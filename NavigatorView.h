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
	translate = tTranslate,
	wlww = tWL,
	rotate = tRotate,
	idle = -1
} MouseEventType;

@interface NavigatorView : NSOpenGLView {
	ViewerController *viewer;
	NSMutableArray *thumbnailsTextureArray;
	int thumbnailWidth, thumbnailHeight;
	float sizeFactor;

	NSPoint mouseDownPosition, mouseDraggedPosition, mouseMovedPosition;
	MouseEventType userAction;
	NSPoint offset, translation;
	float rotationAngle, zoomFactor;
	
	BOOL changeWLWW;
	float wl, ww, startWL, startWW;
	NSMutableArray *isTextureWLWWUpdated;
	
	BOOL drawLeftLateralScrollBar, drawRightLateralScrollBar;
	NSTimer *scrollTimer;
}

@property(readonly) int thumbnailWidth, thumbnailHeight;

- (void)setViewer:(ViewerController*)v;
- (void)initTextureArray;
- (void)generateTextureForSlice:(int)z movieIndex:(int)t arrayIndex:(int)i;
- (void)computeThumbnailSize;

- (NSPoint)convertPointFromWindowToOpenGL:(NSPoint)pointInWindow;
- (void)translationFrom:(NSPoint)start to:(NSPoint)stop;
- (void)rotateFrom:(NSPoint)start to:(NSPoint)stop;
- (NSPoint)rotatePoint:(NSPoint)pt aroundPoint:(NSPoint)c angle:(float)a;
- (void)zoomFrom:(NSPoint)start to:(NSPoint)stop;
- (NSPoint)zoomPoint:(NSPoint)pt withCenter:(NSPoint)c factor:(float)f;
- (void)changeWLWW:(NSNotification*)notif;
- (void)wlwwFrom:(NSPoint)start to:(NSPoint)stop;
- (BOOL)isMouseOnLeftLateralScrollBar:(NSPoint)mousePos;
- (BOOL)isMouseOnRightLateralScrollBar:(NSPoint)mousePos;

- (BOOL)canScrollHorizontallyOfAmount:(float)amount;
- (void)scrollHorizontallyOfAmount:(float)amount;
- (void)scrollLeft;
- (void)scrollRight;
- (void)scrollLeft:(NSTimer*)theTimer;
- (void)scrollRight:(NSTimer*)theTimer;

- (void)doubleClick;
- (void)openNewViewerAtSlice:(int)z movieFrame:(int)t;

@end