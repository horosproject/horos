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
	[super dealloc];
}

- (void)setViewer:(ViewerController*)v;
{
	viewer = v;
	[self initTextureArray];
	[self computeThumbnailSize];
	[self setFrameSize:NSMakeSize([[viewer pixList] count]*thumbnailWidth, [viewer maxMovieIndex]*thumbnailHeight)];
}

// generates a texture for each slice and each time frame
- (void)generateTextures;
{
	NSLog(@"generateTextures");
	
	[[self openGLContext] makeCurrentContext];
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	if(!thumbnailsTextureArray)
		thumbnailsTextureArray = [[NSMutableArray array] retain];
	else
	{
		for (NSNumber *n in thumbnailsTextureArray)
		{
			GLuint textureName = [n intValue];
			glDeleteTextures(1, &textureName);
		}
		[thumbnailsTextureArray removeAllObjects];
	}
		

	for(int t=0; t<[viewer maxMovieIndex]; t++)
	{
		NSMutableArray *pixList = [viewer pixList:t];
		for(int z=0; z<[pixList count]; z++)
		{
			DCMPix *pix = [pixList objectAtIndex:z];
			char* textureBuffer = [pix baseAddr];
			
			if( textureBuffer)
			{
				GLuint textureName = 0L;
				
				glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, [pix pwidth]*[pix pheight]*4, textureBuffer);
				
				glGenTextures(1, &textureName);
				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
				glPixelStorei(GL_UNPACK_ROW_LENGTH, [pix pwidth]);
				glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
				glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_INTENSITY8, [pix pwidth], [pix pheight], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, textureBuffer);
				
				[thumbnailsTextureArray addObject:[NSNumber numberWithInt:textureName]];
			}
			else
				[thumbnailsTextureArray addObject:[NSNumber numberWithInt:-1]];
		}
	}
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
	
	for(int t=0; t<[viewer maxMovieIndex]; t++)
	{
		NSMutableArray *pixList = [viewer pixList:t];
		for(int z=0; z<[pixList count]; z++)
			[thumbnailsTextureArray addObject:[NSNumber numberWithInt:-1]];
	}
	NSLog(@"[thumbnailsTextureArray count] : %d", [thumbnailsTextureArray count]);
}

- (void)generateTextureForSlice:(int)z movieIndex:(int)t arrayIndex:(int)i;
{
	//NSLog(@"generateTextureForSlice:%d movieIndex:%d", z, t);
	
	if(!thumbnailsTextureArray) [self initTextureArray];
	
	[[self openGLContext] makeCurrentContext];
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];

	NSMutableArray *pixList = [viewer pixList:t];
	DCMPix *pix = [pixList objectAtIndex:z];
	
	if(changeWLWW) [pix changeWLWW:wl :ww];
	
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

	for(int t=0; t<[viewer maxMovieIndex]; t++)
	{
		NSMutableArray *pixList = [viewer pixList:t];
		for(int z=0; z<[pixList count]; z++)
		{
			//if([(NSNumber*)[thumbnailsTextureArray objectAtIndex:i] intValue]<0)
//				[self generateTextureForSlice:z movieIndex:t arrayIndex:i];
//
//			if([(NSNumber*)[thumbnailsTextureArray objectAtIndex:i] intValue]>=0)
//			{
				NSPoint upperLeft = NSMakePoint(z*thumbnailWidth-viewBounds.origin.x, t*thumbnailHeight+viewBounds.origin.y+viewSize.height-[self frame].size.height);
				NSRect thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, thumbnailWidth, thumbnailHeight);

				if(NSIntersectsRect(thumbRect, viewFrame))
				{
					[self generateTextureForSlice:z movieIndex:t arrayIndex:i];
					
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, [(NSNumber*)[thumbnailsTextureArray objectAtIndex:i] intValue]);
				
					DCMPix *pix = [pixList objectAtIndex:z];
					
					NSPoint texUpperLeft, texUpperRight, texLowerLeft, texLowerRight;
					texUpperLeft.x = 0.0;//offset.x+translation.x;
					texUpperLeft.y = 0.0;//offset.y+translation.y;
					texUpperRight.x = pix.pwidth;//+offset.x+translation.x;
					texUpperRight.y = 0.0;//offset.y+translation.y;
					texLowerLeft.x = 0.0;//offset.x+translation.x;
					texLowerLeft.y = pix.pheight;//+offset.y+translation.y;
					texLowerRight.x = pix.pwidth;//+offset.x+translation.x;
					texLowerRight.y = pix.pheight;//+offset.y+translation.y;
					
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
					
					glBegin(GL_QUAD_STRIP);

						pt = texUpperLeft;
						rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];
						glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);//glTexCoord2f(0+offset.x+translation.x, 0+offset.y+translation.y);
						glVertex2f(upperLeft.x, upperLeft.y);
						
						pt = texUpperRight;
						rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];
						glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);//glTexCoord2f(pix.pwidth+offset.x+translation.x, 0+offset.y+translation.y);
						glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y);

						pt = texLowerLeft;
						rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];
						glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);//glTexCoord2f(0+offset.x+translation.x, pix.pheight+offset.y+translation.y);
						glVertex2f(upperLeft.x, upperLeft.y+thumbnailHeight);

						pt = texLowerRight;
						rotPt = [self rotatePoint:pt aroundPoint:centerPoint angle:angle];						
						glTexCoord2f(rotPt.x+translate.x, rotPt.y+translate.y);//glTexCoord2f(pix.pwidth+offset.x+translation.x, pix.pheight+offset.y+translation.y);
						glVertex2f(upperLeft.x+thumbnailWidth, upperLeft.y+thumbnailHeight);
						
					glEnd();
				}
				else
				{
//					if([[thumbnailsTextureArray objectAtIndex:i] intValue]>=0)
					{
						GLuint oldTextureName = [[thumbnailsTextureArray objectAtIndex:i] intValue];
						glDeleteTextures(1, &oldTextureName);
						[thumbnailsTextureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:-1]];
					}
				}
			//}
			i++;
		}
	}

//	int count = 0;
//	for (int j = 0; j<[thumbnailsTextureArray count]; j++)
//	{
//		if([[thumbnailsTextureArray objectAtIndex:j] intValue]>=0) count++;
//	}
//	NSLog(@"count : %d", count);

	glDisable(GL_TEXTURE_RECTANGLE_EXT);

	[[self openGLContext] flushBuffer];//[cgl_ctx  flushBuffer];
}

#pragma mark-
#pragma mark Mouse functions

- (NSPoint)convertPointFromWindowToOpenGL:(NSPoint)pointInWindow;
{
	NSPoint pointInView = [self convertPoint:pointInWindow fromView:nil];
	pointInView.y = [[[self enclosingScrollView] contentView] documentVisibleRect].size.height-pointInView.y;
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
	NSLog(@"changeWLWW");
	DCMPix *pix = [notif object];
	if(pix.ww!=ww || pix.wl!=wl)
	{
		ww = pix.ww;
		wl = pix.wl;
		changeWLWW = YES;
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
}

@end
