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
#import "DCMView.h"
#import "ViewerController.h"

typedef enum
{
	zoom = tZoom,
	translate = tTranslate,
	wlww = tWL,
	rotate = tRotate,
	idle = -1
} MouseEventType;

@interface NavigatorView : NSOpenGLView <NSWindowDelegate>
{
	NSMutableArray *thumbnailsTextureArray;
	int thumbnailWidth, thumbnailHeight;
	float sizeFactor;

	NSPoint mouseDownPosition, mouseDraggedPosition, mouseMovedPosition;
	MouseEventType userAction;
	NSPoint offset, translation;
	float rotationAngle, zoomFactor;
	
	int dontListenToNotification;
	float wl, ww, startWL, startWW;
	NSMutableArray *isTextureWLWWUpdated;
	
	BOOL drawLeftLateralScrollBar, drawRightLateralScrollBar;
	NSTimer *scrollTimer;
	
	NSTrackingArea *cursorTracking;
		
	int previousImageIndex, previousMovieIndex;
	ViewerController *previousViewer;
	
	BOOL mouseDragged, mouseClickedWithCommandKey;
	
	NSMutableDictionary *savedTransformDict;
}

@property(readonly) int thumbnailWidth, thumbnailHeight;

+ (NSRect) rect;
+ (NSRect) adjustIfScreenAreaIf4DNavigator: (NSRect) frame;

- (int) minimumWindowHeight;

/**  Set the data set the Navigator is linked to.*/
- (void)setViewer;

/**  Stops listening to notifications.*/
- (void) removeNotificationObserver;

/**  Start listening to notifications.*/
- (void) addNotificationObserver;

/**  Initializes the texture array.*/
- (void)initTextureArray;

/**  Generates a texture (OpenGL) for an image.
* @param z number of the slice.
* @param t number of the movie frame (for 4D data set).
* @param i index of the texture in the texture array.
*/
- (GLuint)generateTextureForSlice:(int)z movieIndex:(int)t arrayIndex:(int)i;

/**  Computes the size of the images in the Navigator.*/
- (void)computeThumbnailSize;

/**  Converts a mouse location (from NSEvent) to an OpenGL Viewport location.
* @param pointInWindow the mouse location (from locationInWindow of NSEvent).
*/
- (NSPoint)convertPointFromWindowToOpenGL:(NSPoint)pointInWindow;

/**  Computes the translation when the user click and drag the mouse
* @param start starting position of the mouse
* @param stop end position of the mouse
*/
- (void)translationFrom:(NSPoint)start to:(NSPoint)stop;

/**  Computes the rotation when the user click and drag the mouse
* @param start starting position of the mouse
* @param stop end position of the mouse
*/
- (void)rotateFrom:(NSPoint)start to:(NSPoint)stop;

/**  Computes the rotation of a point around another
* @param pt the point to rotate
* @param c the center of the rotation
* @param a the angle of the rotation
*/
- (NSPoint)rotatePoint:(NSPoint)pt aroundPoint:(NSPoint)c angle:(float)a;

/**  Computes the zoom when the user click and drag the mouse
* @param start starting position of the mouse
* @param stop end position of the mouse
*/
- (void)zoomFrom:(NSPoint)start to:(NSPoint)stop;

/**  Computes the 'zoom' of a point according to a specific origin
* @param pt the point to 'zoom'
* @param c the fixed point of the zoom
* @param f the zoom factor
*/
- (NSPoint)zoomPoint:(NSPoint)pt withCenter:(NSPoint)c factor:(float)f;

/**  This method is called when the 2D viewer update its WLWW (when the user changes the WLWW on the 2D viewer)*/
- (void)changeWLWW:(NSNotification*)notif;

/**  Computes the WL and WW when the user click and drag the mouse
* @param start starting position of the mouse
* @param stop end position of the mouse
*/
- (void)wlwwFrom:(NSPoint)start to:(NSPoint)stop;

/**  Determines if the mouse is on the left lateral scroll bar.
* The NavigatorView contains 2 lateral scroll bars: one on each sides of the view (left and right). 
* They consist of a dark semi-opaque rectangle with a white arrow.
* They are use to scroll the view.
* @param mousePos position of the mouse
*/
- (BOOL)isMouseOnLeftLateralScrollBar:(NSPoint)mousePos;

/**  Determines if the mouse is on the right lateral scroll bar.
* The NavigatorView contains 2 lateral scroll bars: one on each sides of the view (left and right). 
* They consist of a dark semi-opaque rectangle with a white arrow.
* They are use to scroll the view.
* @param mousePos position of the mouse
*/
- (BOOL)isMouseOnRightLateralScrollBar:(NSPoint)mousePos;

/**  Determines if the the view can be horizontally scrolled of a certain amout.
* @param amount the amount (in pixel) to test.
*/
- (BOOL)canScrollHorizontallyOfAmount:(float)amount;

/**  Scroll the view horizontally of a certain amout.
* @param amount the amount (in pixel). A negative value will scroll left and a positive value will scroll right.
*/
- (void)scrollHorizontallyOfAmount:(float)amount;

/**  Scroll the view horizontally of 1 image to the left.*/
- (void)scrollLeft;

/**  Determines if the the view can be horizontally scrolled of 1 image to the left.*/
- (BOOL)cansScrollLeft;

/**  Scroll the view horizontally of 1 image to the right.*/
- (void)scrollRight;

/**  Determines if the the view can be horizontally scrolled of 1 image to the right.*/
- (BOOL)cansScrollRight;

/**  Keep scrolling when the mouse is pressed.*/
- (void)scrollLeft:(NSTimer*)theTimer;

/**  Keep scrolling when the mouse is pressed.*/
- (void)scrollRight:(NSTimer*)theTimer;

/**  Updates the view so that the selected image (with the red frame) is visible.*/
- (void)displaySelectedImage;

/**  Determines if the the view needs a horizontal scroller (returns NO if all the images can be displayed on screen).*/
- (BOOL)needsHorizontalScroller;

/** Returns the 2D viewer that is currently linked with the Navigator.*/
- (ViewerController*)viewer;

/** Only in 4D. Returns all the 4D viewers that are linked to the same data set.*/
- (NSArray*)associatedViewers;

/** Clicking in a view of the Navigator will display the selected image in the 2D viewer.
* Holding the command key pressed while clicking will open a new viewer.*/
- (void)displaySelectedViewInNewWindow:(BOOL)newWindow;

/**  Opens a new viewer.
* @param z number of the slice.
* @param t number of the movie frame (for 4D data set).
*/
- (void)openNewViewerAtSlice:(int)z movieFrame:(int)t;

- (void)saveTransformForCurrentViewer;
- (void)loadTransformForCurrentViewer;

@end