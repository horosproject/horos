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
		offsetRotationAngle = 0.0;
		offsetZoomFactor = 0.0;
		zoomFactor = 0.0;
		
		drawLeftLateralScrollBar = NO;
		drawRightLateralScrollBar = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeWLWW:) name:@"changeWLWW" object:nil];
		
		GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
		[[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
    }
    return self;
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
	
	[super dealloc];
}

- (void)setViewer:(ViewerController*)v;
{
	viewer = v;
	[self initTextureArray];
	[self computeThumbnailSize];
	[self setFrameSize:NSMakeSize([[viewer pixList] count]*thumbnailWidth, [viewer maxMovieIndex]*thumbnailHeight)];
	wl = [viewer imageView].curWL;
	ww = [viewer imageView].curWW;
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
		
	for(int t=0; t<[viewer maxMovieIndex]; t++)
	{
		NSMutableArray *pixList = [viewer pixList:t];
		for(int z=0; z<[pixList count]; z++)
		{
			[thumbnailsTextureArray addObject:[NSNumber numberWithInt:-1]];
			[isTextureWLWWUpdated addObject:[NSNumber numberWithBool:NO]];
		}
	}
}

- (void)generateTextureForSlice:(int)z movieIndex:(int)t arrayIndex:(int)i;
{
	if(!thumbnailsTextureArray) [self initTextureArray];
	
	[[self openGLContext] makeCurrentContext];
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];

	NSMutableArray *pixList = [viewer pixList:t];
	DCMPix *pix = [pixList objectAtIndex:z];
	
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
	DCMPix *aPix = [[viewer pixList] objectAtIndex:0];
	int width = [aPix pwidth];
	int height = [aPix pheight];
	
	float wFactor = (float)width / (float)thumbnailMaxWidth;
	float hFactor = (float)height / (float)thumbnailMaxHeight;
	sizeFactor = (wFactor>hFactor)? wFactor : hFactor;
	
	thumbnailWidth = width / sizeFactor;
	thumbnailHeight = height / sizeFactor;
	
	[[self enclosingScrollView] setHorizontalPageScroll:thumbnailWidth];
}

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
	glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
		
	glScalef(2.0f/(viewSize.width), -2.0f/(viewSize.height), 1.0f);
	glTranslatef(-(viewSize.width)/2.0, -(viewSize.height)/2.0, 0.0);
	
	int i=0;
	NSPoint upperLeft;
	NSRect thumbRect;
	
	for(int t=0; t<[viewer maxMovieIndex]; t++)
	{
		NSMutableArray *pixList = [viewer pixList:t];
		for(int z=0; z<[pixList count]; z++)
		{
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
				
				float f = exp2f(offsetZoomFactor+zoomFactor);
				texUpperLeft = [self zoomPoint:texUpperLeft withCenter:centerPoint factor:f];
				texUpperRight = [self zoomPoint:texUpperRight withCenter:centerPoint factor:f];
				texLowerLeft = [self zoomPoint:texLowerLeft withCenter:centerPoint factor:f];
				texLowerRight = [self zoomPoint:texLowerRight withCenter:centerPoint factor:f];
				
				NSPoint pt, rotPt;
				
				NSPoint translate;
				translate.x = (offset.x+translation.x)*f;
				translate.y = (offset.y+translation.y)*f;
				translate = [self rotatePoint:translate aroundPoint:NSMakePoint(0, 0) angle:offsetRotationAngle+rotationAngle];
				
				float angle = offsetRotationAngle+rotationAngle;
				
				// draw texture
				glBegin(GL_QUAD_STRIP);
					pt = texUpperLeft;
					rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];
					glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);
					glVertex2f(upperLeft.x, upperLeft.y);
					
					pt = texUpperRight;
					rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];
					glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);
					glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y);

					pt = texLowerLeft;
					rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];
					glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);
					glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight);

					pt = texLowerRight;
					rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];						
					glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);
					glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y+thumbnailHeight);
				glEnd();
			}
			else
			{
				GLuint oldTextureName = [[thumbnailsTextureArray objectAtIndex:i] intValue];
				glDeleteTextures(1, &oldTextureName);
				[thumbnailsTextureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:-1]];
			}

			i++;
		}
	}

	glDisable(GL_TEXTURE_RECTANGLE_EXT);

	// draw selection
	glEnable(GL_LINE_SMOOTH);
	
	// selected time line
	int t = [viewer curMovieIndex];
	upperLeft.y = t*thumbnailHeight+viewBounds.origin.y+viewSize.height-[self frame].size.height;
	upperLeft.x = 0.0;
	
	glLineWidth(2.0);
	glColor3f(1.0f, 1.0f, 0.0f);
	glBegin(GL_LINE_LOOP);
		glVertex2f(upperLeft.x, upperLeft.y);
		glVertex2f(upperLeft.x+viewSize.width, upperLeft.y);
		glVertex2f(upperLeft.x+viewSize.width, upperLeft.y+thumbnailHeight);
		glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight);
	glEnd();
	glColor3f(0.0f, 0.0f, 0.0f);
	glLineWidth(1.0);	
	
	// selected image
	int z = [viewer imageIndex];
	upperLeft.x = z*thumbnailWidth-viewBounds.origin.x;
	thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, thumbnailWidth, thumbnailHeight);

	if(NSIntersectsRect(thumbRect, viewFrame))
	{
		glLineWidth(2.0);
		glColor3f(1.0f, 0.0f, 0.0f);
		glBegin(GL_LINE_LOOP);
			glVertex2f(upperLeft.x, upperLeft.y);
			glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y);
			glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y+thumbnailHeight);
			glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight);
		glEnd();
		glColor3f(0.0f, 0.0f, 0.0f);
		glLineWidth(1.0);	
	}
	
	glDisable(GL_LINE_SMOOTH);
	
	// lateral scroll bar	
	if(drawLeftLateralScrollBar)
	{
		// draw the dark part
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glEnable(GL_POLYGON_SMOOTH);
		glColor4f(0.0f, 0.0f, 0.0f, 0.5f);
		glBegin(GL_POLYGON);
			glVertex2f(0.0, 0.0);
			glVertex2f(lateralScrollBarSize, 0.0);
			glVertex2f(lateralScrollBarSize, viewSize.height);
			glVertex2f(0.0, viewSize.height);
		glEnd();
		//glColor3f(0.0f, 0.0f, 0.0f);
		
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
	
	if(drawRightLateralScrollBar)
	{
		// draw the dark part
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glEnable(GL_POLYGON_SMOOTH);
		glColor4f(0.0f, 0.0f, 0.0f, 0.5f);
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

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

#pragma mark-
#pragma mark Mouse functions

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

	if([theEvent modifierFlags] & NSShiftKeyMask) userAction=zoom;
	else if([theEvent modifierFlags] & NSCommandKeyMask) userAction=translate;
	else if([theEvent modifierFlags] & NSControlKeyMask) userAction=rotate;
	else if([theEvent modifierFlags] & NSAlternateKeyMask) userAction=wlww;
	else userAction = [viewer imageView].currentTool;
	
	startWW = ww;
	startWL = wl;

	changeWLWW = NO;
	
	BOOL scrollLeft = [self isMouseOnLeftLateralScrollBar:mouseDownPosition];
	BOOL scrollRight = [self isMouseOnRightLateralScrollBar:mouseDownPosition];
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

	userAction = [viewer imageView].currentToolRight;

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
	[self setNeedsDisplay:YES];
}

- (void)rightMouseDragged:(NSEvent *)theEvent;
{
	[self mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent;
{
	offset.x += translation.x;
	offset.y += translation.y;
	translation.x = 0.0;
	translation.y = 0.0;
	
	offsetRotationAngle += rotationAngle;
	rotationAngle = 0.0;
	
	offsetZoomFactor += zoomFactor;
	zoomFactor = 0.0;

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

	translation.x *= sizeFactor;
	translation.y *= sizeFactor;
}

- (void)rotateFrom:(NSPoint)start to:(NSPoint)stop;
{
	rotationAngle = stop.x-start.x;
	rotationAngle /= sizeFactor;
	rotationAngle /= 10.;
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
	zoomFactor = stop.y - start.y;
	zoomFactor /= sizeFactor;
	zoomFactor /= 10.;
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
	}
	else
	{
		changeWLWW = NO;
	}
}

- (void)wlwwFrom:(NSPoint)start to:(NSPoint)stop;
{
	float WWAdapter = startWW / 100.0;
	if( WWAdapter < 0.001) WWAdapter = 0.001;
	
	wl = startWL + (stop.y -  start.y)*WWAdapter;
	ww = startWW + (stop.x -  start.x)*WWAdapter;
	
	[[viewer imageView] setWLWW:wl :ww];
	changeWLWW = YES;
	for (int i=0; i<[isTextureWLWWUpdated count]; i++)
		[isTextureWLWWUpdated replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
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

- (void)scrollHorizontallyOfAmount:(float)amount;
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	NSPoint newOrigin = viewBounds.origin;
	newOrigin.x += amount;
	newOrigin.y += 20; // ... ?? don't know why but it works.. size of the horizontal ruler?
		
	if(newOrigin.x<0) newOrigin.x = 0.0;
	if(newOrigin.x+viewBounds.size.width>[self frame].size.width) newOrigin.x = [self frame].size.width - viewBounds.size.width;

	if(newOrigin.x!=viewBounds.origin.x)
		[clipView setBoundsOrigin:newOrigin];
}

- (void)scrollLeft;
{
	[self scrollHorizontallyOfAmount:-[[self enclosingScrollView] horizontalPageScroll]];
}

- (void)scrollRight;
{
	[self scrollHorizontallyOfAmount:[[self enclosingScrollView] horizontalPageScroll]];
}

- (void)scrollLeft:(NSTimer*)theTimer;
{
	[self scrollLeft];
}

- (void)scrollRight:(NSTimer*)theTimer;
{
	[self scrollRight];
}

@end
