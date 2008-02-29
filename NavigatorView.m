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

#import "NavigatorView.h"
#import "NavigatorWindowController.h"

#include <OpenGL/CGLMacro.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>

#import "DCMPix.h"

// max size of the thumbnails in pixels
#define thumbnailMaxHeight 100
#define thumbnailMaxWidth 100

// maximum number of thumbnails displayed at the same time in the view
#define maxThumbRow 10
#define maxThumbColumn 20

// lateral scroll bar size
#define lateralScrollBarSize 20

@implementation NavigatorView

@synthesize thumbnailWidth, thumbnailHeight;

+ (NSRect) rect
{
	if( [NavigatorWindowController navigatorWindowController])
	{
		NavigatorView * n = [[NavigatorWindowController navigatorWindowController] navigatorView];
		ViewerController *v = [n viewer];
		NSRect rect;
		
		rect.size.width = [[n window] maxSize].width;//[[v pixList] count]*n.thumbnailWidth;
		rect.size.height = [v maxMovieIndex]*n.thumbnailHeight;
		
		if( rect.size.width > [[[v window] screen] visibleFrame].size.width) rect.size.width = [[[v window] screen] visibleFrame].size.width;
		
		rect.origin.x = [[[v window] screen] visibleFrame].origin.x;
		rect.origin.y = [[[v window] screen] visibleFrame].origin.y;
		
		float scrollbarShift = 0.0;
		if(rect.size.width < [n frame].size.width) scrollbarShift = 11;
		
		rect.size.height += 16+scrollbarShift;
		
		return rect;
	}
	
	return NSMakeRect( 0, 0, 0, 0);
}

+ (NSRect) adjustIfScreenAreaIf4DNavigator: (NSRect) frame;
{
	NSRect navRect = [NavigatorView rect];
	
	if( NSIsEmptyRect( navRect) == NO)
	{
		NSRect iRect = NSIntersectionRect( frame, navRect);
		
		if( NSIsEmptyRect( iRect) == NO)
		{
			frame.size.height = frame.size.height - iRect.size.height;
			frame.origin.y = iRect.origin.y + iRect.size.height;
		}
	}
	
	return frame;
}

- (void) removeNotificationObserver;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) addNotificationObserver;
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeWLWW:) name:@"changeWLWW" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:@"DCMViewIndexChanged" object:nil];
}

- (id)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute attrs[] = { NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, 0};
	NSOpenGLPixelFormat* pixFmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
	  
	self = [super initWithFrame:frame pixelFormat:pixFmt];
	
    if(self)
	{
		userAction = idle;
		translation = NSMakePoint(0, 0);
		offset = NSMakePoint(0, 0);
		sizeFactor = 1.0;
		zoomFactor = 1.0;
		
		drawLeftLateralScrollBar = NO;
		drawRightLateralScrollBar = NO;

		previousImageIndex = -1;
		previousMovieIndex = -1;
		
		previousViewer = nil;
		
		cursorTracking = [[NSTrackingArea alloc] initWithRect:[self visibleRect] options:(NSTrackingActiveWhenFirstResponder|NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow) owner:self userInfo:0L];
		[self addTrackingArea:cursorTracking];
		
		[self addNotificationObserver];
		
		[[self window] setDelegate:self];
		
		GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
		[[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
    }
    return self;
}

- (void)awakeFromNib
{
	[[self enclosingScrollView] setBackgroundColor:[NSColor blackColor]];
}

- (void)dealloc
{
	NSLog(@"NavigatorView dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[thumbnailsTextureArray release];
	[isTextureWLWWUpdated release];
	
	if(scrollTimer)
	{
		[scrollTimer invalidate];
		[scrollTimer release];
		scrollTimer = nil;
	}
	
	[cursorTracking release];
	
	[super dealloc];
}

- (void)setViewer;
{
	[self initTextureArray];
	[self computeThumbnailSize];
	[self setFrameSize:NSMakeSize([[[self viewer] pixList] count]*thumbnailWidth, [[self viewer] maxMovieIndex]*thumbnailHeight)];
	wl = [[self viewer] imageView].curWL;
	ww = [[self viewer] imageView].curWW;
	previousImageIndex = -1;
	previousMovieIndex = -1;
	previousViewer = [self viewer];
	[self setNeedsDisplay:YES];
}

- (void)initTextureArray;
{
	if(!thumbnailsTextureArray)
		thumbnailsTextureArray = [[NSMutableArray array] retain];
	else
	{
		[[self openGLContext] makeCurrentContext];
		CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];

		for (NSNumber *n in thumbnailsTextureArray)
		{
			GLuint textureName = [n intValue];
			glDeleteTextures(1, &textureName);
		}
		[thumbnailsTextureArray removeAllObjects];
	}

	if(!isTextureWLWWUpdated)
		isTextureWLWWUpdated = [[NSMutableArray array] retain];
	else
		[isTextureWLWWUpdated removeAllObjects];
		
	for(int t=0; t<[[self viewer] maxMovieIndex]; t++)
	{
		NSMutableArray *pixList = [[self viewer] pixList:t];
		for(int z=0; z<[pixList count]; z++)
		{
			[thumbnailsTextureArray addObject:[NSNumber numberWithInt:-1]];
			[isTextureWLWWUpdated addObject:[NSNumber numberWithBool:NO]];
		}
	}
}

- (void)generateTextureForSlice:(int)z movieIndex:(int)t arrayIndex:(int)i;
{
	if(!thumbnailsTextureArray || i>=[thumbnailsTextureArray count]) [self initTextureArray];
	
	[[self openGLContext] makeCurrentContext];
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];

	NSMutableArray *pixList = [[self viewer] pixList:t];
	
	DCMPix *pix;
	if( [[[self viewer] imageView] flippedData]) pix = [pixList objectAtIndex: [pixList count] -z -1];
	else pix = [pixList objectAtIndex:z];
	
	if(changeWLWW) [pix changeWLWW:wl :ww];
	else if(![[isTextureWLWWUpdated objectAtIndex:i] boolValue]) [pix changeWLWW:wl :ww];

	[isTextureWLWWUpdated replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:YES]];	
	
	char* textureBuffer = [pix baseAddr];
			
	if( textureBuffer)
	{
		GLuint textureName = 0L;
		
		glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, [pix pwidth]*[pix pheight]*4, textureBuffer);
		
		glGenTextures(1, &textureName);
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, [pix pwidth]);
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);

		GLfloat borderColor[4] = {0., 0., 0., 1.0};
		glTexParameterfv(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_BORDER_COLOR, borderColor);

		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_INTENSITY8, [pix pwidth], [pix pheight], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, textureBuffer);
		
		//[thumbnailsTextureArray addObject:[NSNumber numberWithInt:textureName]];
		if([[thumbnailsTextureArray objectAtIndex:i] intValue]>=0)
		{
			GLuint oldTextureName = [[thumbnailsTextureArray objectAtIndex:i] intValue];
			glDeleteTextures(1, &oldTextureName);
		}
		[thumbnailsTextureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:textureName]];
	}
//	else
//		[thumbnailsTextureArray replaceObjectAtIndex:z*[pixList count]+t withObject:[NSNumber numberWithInt:-1]];
}

- (void)computeThumbnailSize;
{
	// we consider that every image has the same size
	DCMPix *aPix = [[[self viewer] pixList] objectAtIndex:0];
	int width = [aPix pwidth];
	int height = [aPix pheight];
	
	float wFactor = (float)width / (float)thumbnailMaxWidth;
	float hFactor = (float)height / (float)thumbnailMaxHeight;
	sizeFactor = (wFactor>hFactor)? wFactor : hFactor;
	
	thumbnailWidth = width / sizeFactor;
	thumbnailHeight = height / sizeFactor;
	
	[[self enclosingScrollView] setHorizontalPageScroll:thumbnailWidth];
	[[self enclosingScrollView] setHorizontalLineScroll:thumbnailWidth];
	
	[[self enclosingScrollView] setVerticalPageScroll:thumbnailHeight];
	[[self enclosingScrollView] setVerticalLineScroll:thumbnailHeight];
}

#pragma mark-
#pragma mark Drawing

- (void)drawRect:(NSRect)rect
{
	[[self openGLContext] makeCurrentContext];

	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	NSRect viewFrame = [clipView frame];
	NSSize viewSize = viewFrame.size;
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	glViewport(0, 0, viewSize.width, viewSize.height); // set the viewport to cover entire view
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);

    glMatrixMode (GL_MODELVIEW);
	glLoadIdentity();
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	
	glDepthMask (GL_TRUE);
		
	glScalef(2.0f/(viewSize.width), -2.0f/(viewSize.height), 1.0f);
	glTranslatef(-(viewSize.width)/2.0, -(viewSize.height)/2.0, 0.0);
	
	int i=0;
	NSPoint upperLeft;
	NSRect thumbRect;
	
	for(int t=0; t<[[self viewer] maxMovieIndex]; t++)
	{
		BOOL highlightLine = NO;
		glColor4f (0.5f, 0.5f, 0.5f, 1.0f);
		
		if(t == [[self viewer] curMovieIndex])
			highlightLine = YES;
		else
		{
			// associated Viewers	
			for (ViewerController *v in [self associatedViewers])
			{
				if(t == [v curMovieIndex]) highlightLine = YES;
			}
		}
		
		if([[self viewer] isPlaying4D]) highlightLine = YES;
		
		BOOL highlightThumbnail = NO;
		NSMutableArray *pixList = [[self viewer] pixList:t];
		for(int z=0; z<[pixList count]; z++)
		{
			highlightThumbnail = highlightLine || (z == [[self viewer] imageIndex]);
				
			if(highlightThumbnail)
				glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
			else
				glColor4f (0.5f, 0.5f, 0.5f, 1.0f);				
			
			upperLeft = NSMakePoint(z*thumbnailWidth-viewBounds.origin.x, t*thumbnailHeight+viewBounds.origin.y+viewSize.height-[self frame].size.height);
			thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, thumbnailWidth, thumbnailHeight);

			if(NSIntersectsRect(thumbRect, viewFrame))
			{
				[self generateTextureForSlice:z movieIndex:t arrayIndex:i];
				
				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, [(NSNumber*)[thumbnailsTextureArray objectAtIndex:i] intValue]);
			
				DCMPix *pix = [pixList objectAtIndex:z];
				
				NSPoint texUpperLeft, texUpperRight, texLowerLeft, texLowerRight;
				texUpperLeft.x = 0.0;
				texUpperLeft.y = 0.0;
				texUpperRight.x = pix.pwidth;
				texUpperRight.y = 0.0;
				texLowerLeft.x = 0.0;
				texLowerLeft.y = pix.pheight;
				texLowerRight.x = pix.pwidth;
				texLowerRight.y = pix.pheight;
				
				NSPoint centerPoint;
				centerPoint.x = (texUpperLeft.x+texLowerRight.x)/2.0;
				centerPoint.y = (texUpperLeft.y+texLowerRight.y)/2.0;
								
				NSPoint translate;
				translate.x = (offset.x);
				translate.y = (offset.y);
				translate = [self rotatePoint:translate aroundPoint:NSMakePoint(0, 0) angle:rotationAngle];

				// zoomed texture
				texUpperLeft = [self zoomPoint:texUpperLeft withCenter:centerPoint factor:zoomFactor];
				texUpperRight = [self zoomPoint:texUpperRight withCenter:centerPoint factor:zoomFactor];
				texLowerLeft = [self zoomPoint:texLowerLeft withCenter:centerPoint factor:zoomFactor];
				texLowerRight = [self zoomPoint:texLowerRight withCenter:centerPoint factor:zoomFactor];
				
				centerPoint.x = (texUpperLeft.x+texLowerRight.x)/2.0;
				centerPoint.y = (texUpperLeft.y+texLowerRight.y)/2.0;
				NSPoint modifiedCenter;
				modifiedCenter.x = centerPoint.x + offset.x;
				modifiedCenter.y = centerPoint.y + offset.y;
				
				NSPoint pt, rotPt;
				// draw texture
				glBegin(GL_QUAD_STRIP);
					pt = texUpperLeft;
					pt.x += offset.x;	pt.y += offset.y;
					rotPt = [self rotatePoint:pt aroundPoint:modifiedCenter angle:rotationAngle];
					glTexCoord2f(rotPt.x, rotPt.y);
					glVertex2f(upperLeft.x, upperLeft.y);
					
					pt = texUpperRight;
					pt.x += offset.x;	pt.y += offset.y;
					rotPt = [self rotatePoint:pt aroundPoint:modifiedCenter angle:rotationAngle];
					glTexCoord2f(rotPt.x, rotPt.y);
					glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y);

					pt = texLowerLeft;
					pt.x += offset.x;	pt.y += offset.y;
					rotPt = [self rotatePoint:pt aroundPoint:modifiedCenter angle:rotationAngle];
					glTexCoord2f(rotPt.x, rotPt.y);
					glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight);

					pt = texLowerRight;
					pt.x += offset.x;	pt.y += offset.y;
					rotPt = [self rotatePoint:pt aroundPoint:modifiedCenter angle:rotationAngle];
					glTexCoord2f(rotPt.x, rotPt.y);
					glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y+thumbnailHeight);
				glEnd();
			}
			else
			{
				if(i<[thumbnailsTextureArray count])
				{
					GLuint oldTextureName = [[thumbnailsTextureArray objectAtIndex:i] intValue];
					glDeleteTextures(1, &oldTextureName);
					[thumbnailsTextureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:-1]];
				}
				else
					[thumbnailsTextureArray addObject:[NSNumber numberWithInt:-1]];
			}
			i++;
		}
	}

	glDisable(GL_TEXTURE_RECTANGLE_EXT);

	// draw selection
	glEnable(GL_LINE_SMOOTH);
	
	// selected time line
	int t = [[self viewer] curMovieIndex];
	upperLeft.y = t*thumbnailHeight+viewBounds.origin.y+viewSize.height-[self frame].size.height;
//	upperLeft.x = 0.0;
//	
//	glLineWidth(2.0);
//	glColor3f(1.0f, 1.0f, 0.0f);
//	glBegin(GL_LINE_LOOP);
//		glVertex2f(upperLeft.x, upperLeft.y);
//		glVertex2f(upperLeft.x+viewSize.width, upperLeft.y);
//		glVertex2f(upperLeft.x+viewSize.width, upperLeft.y+thumbnailHeight);
//		glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight);
//	glEnd();
//	glColor3f(0.0f, 0.0f, 0.0f);
//	glLineWidth(1.0);	
	
	// selected image
	int z = [[self viewer] imageIndex];
	upperLeft.x = z*thumbnailWidth-viewBounds.origin.x;
	thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, thumbnailWidth, thumbnailHeight);

	if(NSIntersectsRect(thumbRect, viewFrame))
	{
		glLineWidth(3.0);
		glColor3f(1.0f, 0.0f, 0.0f);
		glBegin(GL_LINE_LOOP);
			glVertex2f(upperLeft.x, upperLeft.y+1.0);
			glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y+1.0);
			glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y+thumbnailHeight-1.0);
			glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight-1.0);
		glEnd();
		glColor3f(0.0f, 0.0f, 0.0f);
		glLineWidth(1.0);	
	}
	
//	// associated Viewers	
//	// selected time line
//	for (ViewerController *v in [self associatedViewers])
//	{
//		int t = [v curMovieIndex];
//		upperLeft.y = t*thumbnailHeight+viewBounds.origin.y+viewSize.height-[self frame].size.height;
//		upperLeft.x = 0.0;
//		
//		float shift = 2.0;
//		upperLeft.y += shift;
//		
//		glLineWidth(2.0);
//		glColor3f(0.8f, 1.0f, 0.7f);
//		glBegin(GL_LINE_LOOP);
//			glVertex2f(upperLeft.x, upperLeft.y);
//			glVertex2f(upperLeft.x+viewSize.width, upperLeft.y);
//			glVertex2f(upperLeft.x+viewSize.width, upperLeft.y+thumbnailHeight-2.0*shift);
//			glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight-2.0*shift);
//		glEnd();
//		glColor3f(0.0f, 0.0f, 0.0f);
//		glLineWidth(1.0);	
//	}
	
	glDisable(GL_LINE_SMOOTH);
	
	// lateral scroll bar	
	if(drawLeftLateralScrollBar && [self cansScrollLeft])
	{
		// draw the dark part
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glEnable(GL_POLYGON_SMOOTH);
		glColor4f(0.0f, 0.0f, 0.0f, 0.75f);
		glBegin(GL_POLYGON);
			glVertex2f(0.0, 0.0);
			glVertex2f(lateralScrollBarSize, 0.0);
			glVertex2f(lateralScrollBarSize, viewSize.height);
			glVertex2f(0.0, viewSize.height);
		glEnd();
		
		// draw the triangle
		glColor4f(1.0f, 1.0f, 1.0f, 0.9f);
		glBegin(GL_POLYGON);
			glVertex2f(lateralScrollBarSize-7.0, viewBounds.size.height/2.0-6.0);
			glVertex2f(lateralScrollBarSize-7.0, viewBounds.size.height/2.0+6.0);
			glVertex2f(3.0, viewBounds.size.height/2.0);
		glEnd();
		glColor3f(0.0f, 0.0f, 0.0f);
		
		glDisable(GL_BLEND);
		glDisable(GL_POLYGON_SMOOTH);
	}
	
	if(drawRightLateralScrollBar && [self cansScrollRight])
	{
		// draw the dark part
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glEnable(GL_POLYGON_SMOOTH);
		glColor4f(0.0f, 0.0f, 0.0f, 0.75f);
		glBegin(GL_POLYGON);
			glVertex2f(viewBounds.size.width-lateralScrollBarSize, 0.0);
			glVertex2f(viewBounds.size.width, 0.0);
			glVertex2f(viewBounds.size.width, viewSize.height);
			glVertex2f(viewBounds.size.width-lateralScrollBarSize, viewSize.height);
		glEnd();
				
		// draw the triangle
		glColor4f(1.0f, 1.0f, 1.0f, 0.9f);
		glBegin(GL_POLYGON);
			glVertex2f(viewBounds.size.width-lateralScrollBarSize+6.0, viewBounds.size.height/2.0-6.0);
			glVertex2f(viewBounds.size.width-lateralScrollBarSize+6.0, viewBounds.size.height/2.0+6.0);
			glVertex2f(viewBounds.size.width-4.0, viewBounds.size.height/2.0);
		glEnd();
		glColor3f(0.0f, 0.0f, 0.0f);
		
		glDisable(GL_BLEND);
		glDisable(GL_POLYGON_SMOOTH);
	}
	
// mouse position (for debug purpose)	
//	glPointSize(10.0);
//	glColor3f(0.0f, 1.0f, 1.0f);
//	glBegin(GL_POINTS);
//		glVertex2f(mouseMovedPosition.x, mouseMovedPosition.y);
//	glEnd();
//	glColor3f(0.0f, 0.0f, 0.0f);
//	glPointSize(1.0);

	[[self openGLContext] flushBuffer];
}

#pragma mark-
#pragma mark Mouse functions

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (NSPoint)convertPointFromWindowToOpenGL:(NSPoint)pointInWindow;
{
	NSPoint pointInView = [self convertPoint:pointInWindow fromView:nil];
	pointInView.y = [[[self enclosingScrollView] contentView] documentVisibleRect].size.height-pointInView.y;
	pointInView.x -= [[[self enclosingScrollView] contentView] documentVisibleRect].origin.x;
	return pointInView;
}

- (void)mouseDown:(NSEvent *)theEvent;
{
	NSPoint event_location = [theEvent locationInWindow];
	mouseDownPosition = [self convertPointFromWindowToOpenGL:event_location];	

	BOOL scrollLeft = [self isMouseOnLeftLateralScrollBar:mouseDownPosition] && [self cansScrollLeft];
	BOOL scrollRight = [self isMouseOnRightLateralScrollBar:mouseDownPosition] && [self cansScrollRight];

	if([theEvent modifierFlags] & NSShiftKeyMask) userAction=zoom;
	else if(([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) userAction=rotate;
	else if([theEvent modifierFlags] & NSCommandKeyMask) userAction=translate;
	else if([theEvent modifierFlags] & NSAlternateKeyMask) userAction=wlww;
	else if([theEvent clickCount]==2 && !scrollLeft && !scrollRight)
	{
		[self doubleClick];
		return;
	}
	else userAction = [[self viewer] imageView].currentTool;

	startWW = ww;
	startWL = wl;

	changeWLWW = NO;
	
	if(scrollLeft && !scrollTimer) scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(scrollLeft:) userInfo:nil repeats:YES] retain];
	else if(scrollRight && !scrollTimer) scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(scrollRight:) userInfo:nil repeats:YES] retain];

	if(scrollLeft || scrollRight)
	{
		userAction = idle;
	}
	
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	mouseDownPosition = [self convertPointFromWindowToOpenGL:event_location];	

	userAction = [[self viewer] imageView].currentToolRight;

	changeWLWW = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent;
{
	NSPoint event_location = [theEvent locationInWindow];
	mouseDraggedPosition = [self convertPointFromWindowToOpenGL:event_location];
	
	if(userAction==translate)
		[self translationFrom:mouseDownPosition to:mouseDraggedPosition];
	else if(userAction==rotate)
		[self rotateFrom:mouseDownPosition to:mouseDraggedPosition];
	else if(userAction==zoom)
		[self zoomFrom:mouseDownPosition to:mouseDraggedPosition];
	else if(userAction==wlww)
		[self wlwwFrom:mouseDownPosition to:mouseDraggedPosition];
		
	if(userAction!=wlww) mouseDownPosition = mouseDraggedPosition;
	
	[self setNeedsDisplay:YES];
}

- (void)rightMouseDragged:(NSEvent *)theEvent;
{
	[self mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent;
{
	changeWLWW = NO;
	
	userAction = idle;
	if(scrollTimer)
	{
		[scrollTimer invalidate];
		[scrollTimer release];
		scrollTimer = nil;
	}
}

- (void)rightMouseUp:(NSEvent *)theEvent;
{
	[self mouseUp:theEvent];
}

- (void)translationFrom:(NSPoint)start to:(NSPoint)stop;
{
	translation.x = start.x - stop.x;
	translation.y = start.y - stop.y;

	translation = [self rotatePoint:translation aroundPoint:NSMakePoint(0, 0) angle:rotationAngle];

	offset.x += translation.x*zoomFactor*sizeFactor;
	offset.y += translation.y*zoomFactor*sizeFactor;
}

- (void)rotateFrom:(NSPoint)start to:(NSPoint)stop;
{
	rotationAngle += (stop.x-start.x) / (sizeFactor * 10.);
}

- (NSPoint)rotatePoint:(NSPoint)pt aroundPoint:(NSPoint)c angle:(float)a;
{
	NSPoint rot;
	
	pt.x -= c.x;
	pt.y -= c.y;
	
	rot.x = cos(a)*pt.x - sin(a)*pt.y;
	rot.y = sin(a)*pt.x + cos(a)*pt.y;

	rot.x += c.x;
	rot.y += c.y;
	
	return rot;
}

- (void)zoomFrom:(NSPoint)start to:(NSPoint)stop;
{
	float zoom = stop.y - start.y;
 	zoom *= zoomFactor;
 	zoom /= 50.;
	
	zoomFactor += zoom;
	
	if( zoomFactor < 0) zoomFactor = 0.001;
}

- (NSPoint)zoomPoint:(NSPoint)pt withCenter:(NSPoint)c factor:(float)f;
{
	pt.x -= c.x;
	pt.y -= c.y;
	
	pt.x *= f;
	pt.y *= f;

	pt.x += c.x;
	pt.y += c.y;
	
	return pt;
}

- (void)changeWLWW:(NSNotification*)notif;
{
	DCMPix *pix = [notif object];
	if(pix.ww!=ww || pix.wl!=wl)
	{
		ww = pix.ww;
		wl = pix.wl;
		changeWLWW = YES;
		for(int i=0; i<[isTextureWLWWUpdated count]; i++)
			[isTextureWLWWUpdated replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
		[self display];
		
		for (ViewerController *viewer in [self associatedViewers])
		{
			[[viewer imageView] setWLWW:wl :ww];
		}
	}
	else
	{
		changeWLWW = NO;
	}
}

- (void)refresh:(NSNotification*)notif;
{
	int curImageIndex = [[self viewer] imageIndex];
	int curMovieIndex = [[self viewer] curMovieIndex];
	if( curImageIndex != previousImageIndex || curMovieIndex != previousMovieIndex)
	{
		[self displaySelectedImage];
		[self setNeedsDisplay:YES];
		previousImageIndex = curImageIndex;
		previousMovieIndex = curMovieIndex;
	}
}

- (void)wlwwFrom:(NSPoint)start to:(NSPoint)stop;
{
	float WWAdapter = startWW / 100.0;
	if( WWAdapter < 0.001) WWAdapter = 0.001;
	
	wl = startWL + -(stop.y -  start.y)*WWAdapter;
	ww = startWW + (stop.x -  start.x)*WWAdapter;
	
	[[[self viewer] imageView] setWLWW:wl :ww];
	changeWLWW = YES;
	for (int i=0; i<[isTextureWLWWUpdated count]; i++)
		[isTextureWLWWUpdated replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
		
	for (ViewerController *viewer in [self associatedViewers])
	{
		[[viewer imageView] setWLWW:wl :ww];
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	mouseMovedPosition = [self convertPointFromWindowToOpenGL:event_location];	
	
	BOOL leftLateralScrollBarAlreadyDrawn = drawLeftLateralScrollBar;
	BOOL rightLateralScrollBarAlreadyDrawn = drawRightLateralScrollBar;

	drawLeftLateralScrollBar = NO;
	drawRightLateralScrollBar = NO;
	
	if([self isMouseOnLeftLateralScrollBar:mouseMovedPosition])
	{
		drawLeftLateralScrollBar = YES;
	}
	else if([self isMouseOnRightLateralScrollBar:mouseMovedPosition])
	{
		drawRightLateralScrollBar = YES;
	}
	
	if(leftLateralScrollBarAlreadyDrawn != drawLeftLateralScrollBar || rightLateralScrollBarAlreadyDrawn != drawRightLateralScrollBar)
		[self setNeedsDisplay:YES];
		
//	BOOL scrollLeft = [self isMouseOnLeftLateralScrollBar:mouseMovedPosition];
//	BOOL scrollRight = [self isMouseOnRightLateralScrollBar:mouseMovedPosition];
//	if(scrollLeft && !scrollTimer) scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(scrollLeft:) userInfo:nil repeats:YES] retain];
//	else if(scrollRight && !scrollTimer) scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(scrollRight:) userInfo:nil repeats:YES] retain];
//
//	if(scrollLeft || scrollRight)
//	{
//		//[scrollTimer fire];
//		userAction = idle;
//	}
//	else if(scrollTimer)
//	{
//		[scrollTimer invalidate];
//		[scrollTimer release];
//		scrollTimer = nil;
//	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	BOOL leftLateralScrollBarAlreadyDrawn = drawLeftLateralScrollBar;
	BOOL rightLateralScrollBarAlreadyDrawn = drawRightLateralScrollBar;

	drawLeftLateralScrollBar = NO;
	drawRightLateralScrollBar = NO;

	if(leftLateralScrollBarAlreadyDrawn != drawLeftLateralScrollBar || rightLateralScrollBarAlreadyDrawn != drawRightLateralScrollBar)
		[self setNeedsDisplay:YES];
}


#pragma mark-
#pragma mark Scroll functions

- (BOOL)isMouseOnLeftLateralScrollBar:(NSPoint)mousePos;
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	BOOL inZone = mousePos.x<=lateralScrollBarSize;
	inZone = inZone && mousePos.x>=0;
	inZone = inZone && mousePos.y+viewBounds.origin.y<=viewBounds.size.height;
	inZone = inZone && mousePos.y+viewBounds.origin.y>=0;
	return inZone;
}

- (BOOL)isMouseOnRightLateralScrollBar:(NSPoint)mousePos;
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	BOOL inZone = mousePos.x>=viewBounds.size.width - lateralScrollBarSize;
	inZone = inZone && mousePos.x<=viewBounds.size.width;
	inZone = inZone && mousePos.y+viewBounds.origin.y<=viewBounds.size.height;
	inZone = inZone && mousePos.y+viewBounds.origin.y>=0;
	return inZone;
}

- (BOOL)canScrollHorizontallyOfAmount:(float)amount;
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	NSPoint origin = viewBounds.origin;
	
	BOOL canScroll = YES;
	
	if(amount<0) canScroll = (origin.x>0);
	else canScroll = (origin.x+viewBounds.size.width<[self frame].size.width);

	return canScroll;
}

- (void)scrollHorizontallyOfAmount:(float)amount;
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	NSPoint newOrigin = viewBounds.origin;
	newOrigin.x += amount;
	if([self needsHorizontalScroller])
		newOrigin.y += 20.0; // ... ?? don't know why, but it works...
		
	if(newOrigin.x<0) newOrigin.x = 0.0;
	if(newOrigin.x+viewBounds.size.width>[self frame].size.width) newOrigin.x = [self frame].size.width - viewBounds.size.width;

	if(newOrigin.x!=viewBounds.origin.x)
		[clipView setBoundsOrigin:newOrigin];
}

- (void)scrollLeft;
{
	[self scrollHorizontallyOfAmount:-[[self enclosingScrollView] horizontalPageScroll]];
}

- (BOOL)cansScrollLeft;
{
	return [self canScrollHorizontallyOfAmount:-[[self enclosingScrollView] horizontalPageScroll]];
}

- (void)scrollRight;
{
	[self scrollHorizontallyOfAmount:[[self enclosingScrollView] horizontalPageScroll]];
}

- (BOOL)cansScrollRight;
{
	return [self canScrollHorizontallyOfAmount:[[self enclosingScrollView] horizontalPageScroll]];
}

- (void)scrollLeft:(NSTimer*)theTimer;
{
	[self scrollLeft];
}

- (void)scrollRight:(NSTimer*)theTimer;
{
	[self scrollRight];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	//float d = [theEvent deltaY];
	if([theEvent deltaY] == 0) return;
	//if( fabs( d) < 1.0) d = 1.0 * fabs( d) / d;
	
	[[[self viewer] imageView] scrollWheel:theEvent];
	
	if(!([theEvent modifierFlags] & NSAlternateKeyMask))
		[self displaySelectedImage];
}	

- (void)displaySelectedImage;
{
	if(![self viewer]) return;
	
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	NSRect viewFrame = [clipView frame];
	NSSize viewSize = viewFrame.size;
	
	int z = [[[self viewer] imageView] curImage];
	int t = [[self viewer] curMovieIndex];
	NSPoint upperLeft;
	upperLeft.x = z*thumbnailWidth;

	if([[[self viewer] imageView] flippedData]) upperLeft.x = ([[[self viewer] pixList] count]-z-1)*thumbnailWidth;
	
	upperLeft.y = t*thumbnailHeight+viewBounds.origin.y+viewSize.height-[self frame].size.height;
	
	//upperLeft.y = t*thumbnailHeight+viewSize.height-[self frame].size.height;
	
	NSRect thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, thumbnailWidth, thumbnailHeight);

	NSRect intersectionRect = NSIntersectionRect(thumbRect, viewBounds);

	if(intersectionRect.size.width < 2.0)
	{
		float horizontalRulerHeight = 0.0;
		if([self needsHorizontalScroller]) horizontalRulerHeight = 20.0;
		
		if(thumbRect.origin.x < viewBounds.origin.x)
			[clipView setBoundsOrigin:NSMakePoint(thumbRect.origin.x, viewBounds.origin.y+horizontalRulerHeight)];
		else if(thumbRect.origin.x >= viewBounds.origin.x + viewBounds.size.width)
			[clipView setBoundsOrigin:NSMakePoint(thumbRect.origin.x+thumbRect.size.width-viewFrame.size.width, viewBounds.origin.y+horizontalRulerHeight)];
		else if(thumbRect.origin.y < viewBounds.origin.y)
			[clipView setBoundsOrigin:NSMakePoint(viewBounds.origin.x, thumbRect.origin.y+horizontalRulerHeight)];
		else if(thumbRect.origin.y >= viewBounds.origin.y + viewBounds.size.height)
			[clipView setBoundsOrigin:NSMakePoint(viewBounds.origin.x, thumbRect.origin.y+thumbRect.size.height-viewFrame.size.height)];
	}
}

- (BOOL)needsHorizontalScroller;
{
	return [[[self viewer] pixList] count]*thumbnailWidth > [[[self enclosingScrollView] contentView] frame].size.width;
}

#pragma mark-
#pragma mark New Viewers

// current selected viewer
- (ViewerController*)viewer;
{
	NSArray *displayed2DViewers = [ViewerController getDisplayed2DViewers];
	
	for (ViewerController *v in displayed2DViewers)
	{
		if([[[v imageView] window] isMainWindow] && [v imageView].isKeyView)
			return v;
	}
	
	if([displayed2DViewers count]) return [displayed2DViewers lastObject];
	
	return previousViewer;
}

// associatedViewers are all the opened viewers that share the same NSData, i.e. same stack
- (NSArray*)associatedViewers;
{
	NSMutableArray *associatedViewers = [NSMutableArray array];
	
	NSArray *displayed2DViewers = [ViewerController getDisplayed2DViewers];
	ViewerController *mainViewer = [self viewer];
	
	for (ViewerController *v in displayed2DViewers)
	{		
		if([v maxMovieIndex]==[mainViewer maxMovieIndex] && v!=mainViewer)
		{
			BOOL sameVolumeData = YES;
			for (int i=0; i<[v maxMovieIndex]; i++)
			{
				sameVolumeData = sameVolumeData && ([v volumeData:i] == [mainViewer volumeData:i]);
			}
			if(sameVolumeData) [associatedViewers addObject:v];
		}
	}
	
	return [NSArray arrayWithArray:associatedViewers];
}

- (void)doubleClick;
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	NSRect viewFrame = [clipView frame];
	NSSize viewSize = viewFrame.size;

	int z = (mouseDownPosition.x + viewBounds.origin.x) / thumbnailWidth;
	int t = (mouseDownPosition.y - viewBounds.origin.y - viewSize.height + [self frame].size.height) / thumbnailHeight;
	
	if(t == [[self viewer] curMovieIndex] || [[self viewer] isPlaying4D]) // same time line: select the clicked slice
	{
		DCMView *view = [[self viewer] imageView];
		if([view flippedData]) [view setIndex:[[[self viewer] pixList] count]-z-1];
		else [view setIndex:z];
		[view sendSyncMessage:1];
	}
	else
	{
		ViewerController *selectedViewer;
		BOOL alreadyOpened = NO;
		for (ViewerController *viewer in [self associatedViewers])
		{
			if(t == [viewer curMovieIndex])
			{
				selectedViewer = viewer;
				alreadyOpened = YES;
			}
		}
		if(!alreadyOpened)
			[self openNewViewerAtSlice:z movieFrame:t]; // creates a new viewer
		else
		{
			// select the correct slice
			DCMView *view = [selectedViewer imageView];
			if([view flippedData]) [view setIndex:[[[self viewer] pixList] count]-z-1];
			else [view setIndex:z];
			// sync other viewers
			[view sendSyncMessage:1];
			// make key viewer
			[[selectedViewer window] makeKeyWindow];
			[self setNeedsDisplay:YES];
		}
	}
}

- (void)openNewViewerAtSlice:(int)z movieFrame:(int)t;
{
	// create the new viewer
	ViewerController *newViewer = [ViewerController newWindow:[[self viewer] pixList:0] :[[self viewer] fileList:0] :[[self viewer] volumeData:0]];
	// add all the 4D frames
	for (int i=1; i<[[self viewer] maxMovieIndex]; i++)
	{
		[newViewer addMovieSerie:[[self viewer] pixList:i] :[[self viewer] fileList:i] :[[self viewer] volumeData:i]];
	}
	[newViewer setMovieIndex:t];

	// select the correct slice
	DCMView *view = [newViewer imageView];
	if([[[self viewer] imageView] flippedData]) [view setIndex:[[[self viewer] pixList] count]-z-1];
	else [view setIndex:z];
	
	// flippedData must be the same on all viewers
	view.flippedData = [[self viewer] imageView].flippedData;
	
	[newViewer adjustSlider];
	[view sendSyncMessage:1];
}

@end