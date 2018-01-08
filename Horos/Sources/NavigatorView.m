/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "NavigatorView.h"
#import "NavigatorWindowController.h"
#import "ROI.h"
#import "Notifications.h"
#import "AppController.h"

#include <OpenGL/CGLMacro.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>

#import "DCMPix.h"

static float deg2rad = M_PI/180.0; 

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

- (int) minimumWindowHeight
{
	int scrollbarShift = thumbnailHeight;
	//if( [[[[self viewer] window] screen] visibleFrame].size.width < [[self window] maxSize].width) scrollbarShift += 12;
	if( [[[[self viewer] window] screen] visibleFrame].size.width < [self frame].size.width) scrollbarShift += 12;
	return 16 + scrollbarShift;
}

+ (NSRect) rect
{
	if( [NavigatorWindowController navigatorWindowController])
	{
		NavigatorView * n = [[NavigatorWindowController navigatorWindowController] navigatorView];
		ViewerController *v = [[NavigatorWindowController navigatorWindowController] viewerController];
		NSRect rect;
		
		rect.size.width = [[n window] maxSize].width;
		rect.size.height = [v maxMovieIndex]*n.thumbnailHeight;
		
        NSScreen *screen = [[[AppController sharedAppController] viewerScreens] objectAtIndex: 0];
        
		if( rect.size.width > [screen visibleFrame].size.width) rect.size.width = [screen visibleFrame].size.width;
		if( rect.size.height > [screen visibleFrame].size.height/2) rect.size.height = [screen visibleFrame].size.height/2;
		
		rect.origin.x = [screen visibleFrame].origin.x;
		rect.origin.y = [screen visibleFrame].origin.y;
		
		float scrollbarShift = 0;
		if(rect.size.width < [n frame].size.width) scrollbarShift = 12;
		
		rect.size.height += 17+scrollbarShift;
		
		return rect;
	}
	
	return NSMakeRect( 0, 0, 0, 0);
}

+ (NSRect) adjustIfScreenAreaIf4DNavigator: (NSRect) frame;
{
	if( [NavigatorWindowController navigatorWindowController])
	{
		NSRect navRect = [[[NavigatorWindowController navigatorWindowController] window] frame]; 
		
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
	dontListenToNotification++;
}

- (void) addNotificationObserver;
{
	dontListenToNotification--;
}

- (id)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute attrs[] = { NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, 0};
	NSOpenGLPixelFormat* pixFmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
	  
	self = [super initWithFrame:frame pixelFormat:pixFmt];
	
    if(self)
	{
        [self setWantsBestResolutionOpenGLSurface:YES]; // Retina https://developer.apple.com/library/mac/#documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/CapturingScreenContents/CapturingScreenContents.html#//apple_ref/doc/uid/TP40012302-CH10-SW1
        
		userAction = idle;
		translation = NSMakePoint(0, 0);
		offset = NSMakePoint(0, 0);
		sizeFactor = 1.0;
		zoomFactor = 1.0;
		
		drawLeftLateralScrollBar = NO;
		drawRightLateralScrollBar = NO;

		previousImageIndex = -1;
		previousMovieIndex = -1;
		
		savedTransformDict = [[NSMutableDictionary dictionary] retain];
		
//		previousViewer = nil;
		
		cursorTracking = [[NSTrackingArea alloc] initWithRect:[self visibleRect] options:(NSTrackingActiveWhenFirstResponder|NSTrackingInVisibleRect|NSTrackingMouseEnteredAndExited|NSTrackingActiveInKeyWindow) owner:self userInfo:nil];
		[self addTrackingArea:cursorTracking];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeWLWW:) name:OsirixChangeWLWWNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:OsirixDCMViewIndexChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshROIs:) name:OsirixRemoveROINotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshROIs:) name:OsirixROIChangeNotification object:nil];

		[[self window] setDelegate:self];
		
		[[self openGLContext] makeCurrentContext];
		CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx)
        {
            GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
            [[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
		
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        }
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
	[savedTransformDict release];
	
//	[previousViewer release];
	
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
	wl = [[self viewer] imageView].curWL;
	ww = [[self viewer] imageView].curWW;
	[self initTextureArray];
	[self computeThumbnailSize];
	[self setFrame:NSMakeRect(0.0, 0.0, [[[self viewer] pixList] count]*thumbnailWidth, [[self viewer] maxMovieIndex]*thumbnailHeight)];
	previousImageIndex = -1;
	previousMovieIndex = -1;
//	[previousViewer release];
//	previousViewer = [[self viewer] retain];
	[self loadTransformForCurrentViewer];
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
        if( cgl_ctx == nil)
            return;
        
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

- (GLuint) generateTextureForSlice:(int)z movieIndex:(int)t arrayIndex:(int)i;
{
	if(!thumbnailsTextureArray || i>=[thumbnailsTextureArray count]) [self initTextureArray];
	
	NSMutableArray *pixList = [[self viewer] pixList:t];
	
	DCMPix *pix = [pixList objectAtIndex:z];
	
	if(![[isTextureWLWWUpdated objectAtIndex:i] boolValue]) [pix changeWLWW:wl :ww];
	else if( [[thumbnailsTextureArray objectAtIndex:i] intValue] >= 0) return [[thumbnailsTextureArray objectAtIndex:i] intValue];
	
	[[self openGLContext] makeCurrentContext];
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];

	[isTextureWLWWUpdated replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:YES]];	
	
	char* textureBuffer = [pix baseAddr];
	
	GLuint textureName = 0;
	
	if( textureBuffer)
	{
		glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, [pix pwidth]*[pix pheight]*4, textureBuffer);
		
		glGenTextures(1, &textureName);
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, [pix pwidth]);
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
		glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);

		GLfloat borderColor[4] = {0., 0., 0., 1.0};
		glTexParameterfv(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_BORDER_COLOR, borderColor);

		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_INTENSITY8, [pix pwidth], [pix pheight], 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, textureBuffer);
		
		if([[thumbnailsTextureArray objectAtIndex:i] intValue] >= 0)
		{
			GLuint oldTextureName = [[thumbnailsTextureArray objectAtIndex:i] intValue];
			glDeleteTextures(1, &oldTextureName);
		}
		[thumbnailsTextureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:textureName]];
	}
	else
		[thumbnailsTextureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:-1]];
		
	return textureName;
}

- (void)computeThumbnailSize;
{
	// we consider that every image has the same size
	DCMPix *aPix = [[[self viewer] pixList] objectAtIndex:0];
	int width = [aPix pwidth];
	int height = [aPix pheight]*[aPix pixelRatio];
	
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

- (void) reshape
{
	[self setNeedsDisplay: YES];
	
	[super reshape];
}

- (void)drawRect:(NSRect)a
{
	[[self openGLContext] makeCurrentContext];

	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [self convertRectToBacking: [clipView documentVisibleRect]];
	NSRect viewFrame = [self convertRectToBacking: [clipView frame]];
	NSSize viewSize = viewFrame.size;
	
    float scaledThumbnailWidth = thumbnailWidth * self.window.backingScaleFactor;
    float scaledThumbnailHeight = thumbnailHeight * self.window.backingScaleFactor;
    
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
	glViewport(0, 0, viewSize.width, viewSize.height); // set the viewport to cover entire view
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);

    glMatrixMode (GL_MODELVIEW);
	glLoadIdentity();
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	
	glScalef(2.0f/(viewSize.width), -2.0f/(viewSize.height), 1.0f);
	glTranslatef(-(viewSize.width)/2.0, -(viewSize.height)/2.0, 0.0);
		
	int i=0;
	NSPoint upperLeft;
	NSRect thumbRect;
	
	NSArray *associatedViewers = [self associatedViewers];
	
	for(int t=0; t<[[self viewer] maxMovieIndex]; t++)
	{
		BOOL highlightLine = NO;
		glColor4f (0.5f, 0.5f, 0.5f, 1.0f);
		
		if(t == [[self viewer] curMovieIndex])
			highlightLine = YES;
		else
		{
			// associated Viewers	
			for (ViewerController *v in associatedViewers)
			{
				if(t == [v curMovieIndex]) highlightLine = YES;
			}
		}
		
		if([[self viewer] isPlaying4D]) highlightLine = YES;
		
		BOOL highlightThumbnail = NO;
		NSMutableArray *pixList = [[self viewer] pixList:t];
		
		BOOL flippedData = [[[self viewer] imageView] flippedData];
		
		for(int z=0; z<[pixList count]; z++)
		{
			highlightThumbnail = highlightLine || (z == [[self viewer] imageIndex]);
			
			if(highlightThumbnail)
				glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
			else
				glColor4f (0.5f, 0.5f, 0.5f, 1.0f);				
			
			upperLeft = NSMakePoint(z*scaledThumbnailWidth-viewBounds.origin.x, t*scaledThumbnailHeight+viewBounds.origin.y+viewSize.height-viewFrame.size.height);
			thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, scaledThumbnailWidth, scaledThumbnailHeight);
			
			if(NSIntersectsRect(thumbRect, viewFrame))
			{
				int correctedZ = (flippedData) ? [pixList count]-z-1 : z ;
				
				GLuint textureId = [self generateTextureForSlice:correctedZ movieIndex:t arrayIndex:i];
				
				{
					DCMPix *pix = [pixList objectAtIndex:correctedZ];
					
					NSPoint texUpperLeft, texUpperRight, texLowerLeft, texLowerRight;
					texUpperLeft.x = 0.0;
					texUpperLeft.y = 0.0;
					texUpperRight.x = pix.pwidth;
					texUpperRight.y = 0.0;
					texLowerLeft.x = 0.0;
					texLowerLeft.y = pix.pheight;// *[pix pixelRatio];
					texLowerRight.x = pix.pwidth;
					texLowerRight.y = pix.pheight;// *[pix pixelRatio];
					
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureId);

					glScissor( upperLeft.x, viewSize.height - (upperLeft.y+scaledThumbnailHeight), scaledThumbnailWidth, scaledThumbnailHeight);
					glEnable(GL_SCISSOR_TEST);
					
					glTranslatef(upperLeft.x, upperLeft.y, 0.0);
					glTranslatef(scaledThumbnailWidth/2.0, scaledThumbnailHeight/2.0, 0.0);
					glRotatef(-rotationAngle/deg2rad, 0.0f, 0.0f, 1.0f);
					glScalef(1.0/zoomFactor, 1.0/zoomFactor, 1.0);
					glTranslatef(-scaledThumbnailWidth/2.0, -scaledThumbnailHeight/2.0, 0.0);
					glTranslatef(-upperLeft.x, -upperLeft.y, 0.0);
							
					glTranslatef(-offset.x/sizeFactor, -offset.y/sizeFactor, 0.0);
							
					//if([pix pixelRatio]!=1.0) glScalef( 1.0, [pix pixelRatio], 1.0);
						// draw texture
						glBegin(GL_QUAD_STRIP);
							glTexCoord2f(texUpperLeft.x, texUpperLeft.y);
							glVertex2f(upperLeft.x, upperLeft.y);
							
							glTexCoord2f(texUpperRight.x, texUpperRight.y);
							glVertex2f(upperLeft.x+scaledThumbnailWidth, upperLeft.y);

							
							glTexCoord2f(texLowerLeft.x, texLowerLeft.y);
							glVertex2f(upperLeft.x, upperLeft.y+scaledThumbnailHeight);
						
							glTexCoord2f(texLowerRight.x, texLowerRight.y);
							glVertex2f(upperLeft.x+scaledThumbnailWidth, upperLeft.y+scaledThumbnailHeight);					
						glEnd();
						
					glDisable(GL_SCISSOR_TEST);

					//if([pix pixelRatio]!=1.0) glScalef(1.0, 1.0/[pix pixelRatio], 1.0);
					
					glTranslatef(offset.x/sizeFactor, offset.y/sizeFactor, 0.0);
					
					glTranslatef(upperLeft.x, upperLeft.y, 0.0);
					glTranslatef(scaledThumbnailWidth/2.0, scaledThumbnailHeight/2.0, 0.0);
					glScalef(zoomFactor, zoomFactor, 1.0);
					glRotatef (rotationAngle/deg2rad, 0.0f, 0.0f, 1.0f);
					glTranslatef(-scaledThumbnailWidth/2.0, -scaledThumbnailHeight/2.0, 0.0);
					glTranslatef(-upperLeft.x, -(upperLeft.y), 0.0);
				}
			}
			else
			{
				if(i<[thumbnailsTextureArray count])
				{
					if([[thumbnailsTextureArray objectAtIndex:i] intValue] >= 0)
					{
						GLuint oldTextureName = [[thumbnailsTextureArray objectAtIndex:i] intValue];
						glDeleteTextures(1, &oldTextureName);
					}
					[thumbnailsTextureArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:-1]];
				}
				else
					[thumbnailsTextureArray addObject:[NSNumber numberWithInt:-1]];
			}
			i++;
		}
	}
	
	glDisable(GL_TEXTURE_RECTANGLE_EXT);
	
	if([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] > annotNone)
	{
		for(int t=0; t<[[self viewer] maxMovieIndex]; t++)
		{
			NSMutableArray *pixList = [[self viewer] pixList:t];
			NSMutableArray *roiList = [[self viewer] roiList:t];
			
			BOOL flippedData = [[[self viewer] imageView] flippedData];
					
			for(int z=0; z<[pixList count]; z++)
			{
				int correctedZ = (flippedData) ? [pixList count]-z-1 : z ;
				DCMPix *pix = [pixList objectAtIndex:correctedZ];
				
				upperLeft = NSMakePoint(z*scaledThumbnailWidth-viewBounds.origin.x, t*scaledThumbnailHeight+viewBounds.origin.y+viewSize.height-viewFrame.size.height);
				
				glScissor( upperLeft.x, viewSize.height - (upperLeft.y+scaledThumbnailHeight), scaledThumbnailWidth, scaledThumbnailHeight);
				glEnable(GL_SCISSOR_TEST);
		
				NSArray *rois = [roiList objectAtIndex:correctedZ];

				glTranslatef(upperLeft.x, upperLeft.y, 0.0);
				glTranslatef(scaledThumbnailWidth/2.0, scaledThumbnailHeight/2.0, 0.0);
				glRotatef (-rotationAngle/deg2rad, 0.0f, 0.0f, 1.0f);
				
				if([pix pixelRatio]!=1.0) glScalef( 1.0, [pix pixelRatio], 1.0);

                float f = self.window.backingScaleFactor;
                
				for( ROI *r in rois)
				{
					glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
					
					if([r type]!=tText)
					{
						[r drawROIWithScaleValue:f/(zoomFactor*sizeFactor) offsetX:offset.x/f+pix.pwidth/2.0 offsetY:offset.y/(f*[pix pixelRatio])+pix.pheight/2.0 pixelSpacingX:[pix pixelSpacingX] pixelSpacingY:[pix pixelSpacingY] highlightIfSelected:NO thickness:1.0 prepareTextualData: NO];
					}
				}
				
				glDisable(GL_SCISSOR_TEST);
				
				if([pix pixelRatio]!=1.0) glScalef(1.0, 1.0/[pix pixelRatio], 1.0);
				glRotatef (rotationAngle/deg2rad, 0.0f, 0.0f, 1.0f);
				glTranslatef(-scaledThumbnailWidth/2.0, -scaledThumbnailHeight/2.0, 0.0);
				glTranslatef(-upperLeft.x, -(upperLeft.y), 0.0);
			}
		}
	}

	

	// draw selection
	glEnable(GL_LINE_SMOOTH);
		
	// associated Viewers
	for (ViewerController *v in [self associatedViewers])
	{
		int t = [v curMovieIndex];
		upperLeft.y = t*scaledThumbnailHeight+viewBounds.origin.y+viewSize.height-viewFrame.size.height;
		
		int z = [v imageIndex];
		upperLeft.x = z*scaledThumbnailWidth-viewBounds.origin.x;
		thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, scaledThumbnailWidth, scaledThumbnailHeight);
		
		if(NSIntersectsRect(thumbRect, viewFrame))
		{
			glScissor( upperLeft.x, viewSize.height - (upperLeft.y+scaledThumbnailHeight), scaledThumbnailWidth, scaledThumbnailHeight);
			glEnable(GL_SCISSOR_TEST);
			
			glLineWidth(6.0 * self.window.backingScaleFactor);
			glColor3f(0.0f, 1.0f, 0.0f);
			glBegin(GL_LINE_LOOP);
				glVertex2f(upperLeft.x+1, upperLeft.y+1);
				glVertex2f(upperLeft.x-1+scaledThumbnailWidth, upperLeft.y+1);
				glVertex2f(upperLeft.x-1+scaledThumbnailWidth, upperLeft.y+scaledThumbnailHeight-1);
				glVertex2f(upperLeft.x+1, upperLeft.y+scaledThumbnailHeight-1);
			glEnd();
			glDisable(GL_SCISSOR_TEST);
			
			glColor3f(0.0f, 0.0f, 0.0f);
			glLineWidth(1.0 * self.window.backingScaleFactor);	
		}
	}
	
	// selected time line
	int t = [[self viewer] curMovieIndex];
	upperLeft.y = t*scaledThumbnailHeight+viewBounds.origin.y+viewSize.height-viewFrame.size.height;

	// selected image
	int z = [[self viewer] imageIndex];
	upperLeft.x = z*scaledThumbnailWidth-viewBounds.origin.x;
	thumbRect = NSMakeRect(upperLeft.x, upperLeft.y, scaledThumbnailWidth, scaledThumbnailHeight);

	if(NSIntersectsRect(thumbRect, viewFrame))
	{
		glScissor( upperLeft.x, viewSize.height - (upperLeft.y+scaledThumbnailHeight), scaledThumbnailWidth, scaledThumbnailHeight);
		glEnable(GL_SCISSOR_TEST);
		
		glLineWidth(6.0 * self.window.backingScaleFactor);
		glColor3f(1.0f, 0.0f, 0.0f);
		glBegin(GL_LINE_LOOP);
			glVertex2f(upperLeft.x+1, upperLeft.y+1);
			glVertex2f(upperLeft.x-1+scaledThumbnailWidth, upperLeft.y+1);
			glVertex2f(upperLeft.x-1+scaledThumbnailWidth, upperLeft.y+scaledThumbnailHeight-1);
			glVertex2f(upperLeft.x+1, upperLeft.y+scaledThumbnailHeight-1);
		glEnd();
		glDisable(GL_SCISSOR_TEST);
		
		glColor3f(0.0f, 0.0f, 0.0f);
		glLineWidth(1.0 * self.window.backingScaleFactor);	
	}

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
//	glPointSize(10.0 * self.window.backingScaleFactor);
//	glColor3f(0.0f, 1.0f, 1.0f);
//	glBegin(GL_POINTS);
//		glVertex2f(mouseMovedPosition.x, mouseMovedPosition.y);
//	glEnd();
//	glColor3f(0.0f, 0.0f, 0.0f);
//	glPointSize(1.0 * self.window.backingScaleFactor);

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
	pointInView.x -= [[[self enclosingScrollView] contentView] documentVisibleRect].origin.x;
	pointInView.y -= [[[self enclosingScrollView] contentView] documentVisibleRect].origin.y;
	pointInView.y = [[[self enclosingScrollView] contentView] documentVisibleRect].size.height-pointInView.y;
    
    pointInView = [self convertPointToBacking: pointInView];
    
	return pointInView;
}

- (void)mouseDown:(NSEvent *)theEvent;
{
	NSPoint event_location = [theEvent locationInWindow];
	mouseDownPosition = [self convertPointFromWindowToOpenGL:event_location];	
	mouseDragged = NO;
	
	BOOL scrollLeft = [self isMouseOnLeftLateralScrollBar: [self convertPointFromBacking: mouseDownPosition]] && [self cansScrollLeft];
	BOOL scrollRight = [self isMouseOnRightLateralScrollBar: [self convertPointFromBacking: mouseDownPosition]] && [self cansScrollRight];

	mouseClickedWithCommandKey = NO;
	
	if([theEvent modifierFlags] & NSShiftKeyMask) userAction=zoom;
	else if(([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) userAction=rotate;
	else if([theEvent modifierFlags] & NSCommandKeyMask) 
	{
		userAction=translate;
		mouseClickedWithCommandKey = YES;
	}
	else if([theEvent modifierFlags] & NSAlternateKeyMask) userAction=wlww;
	else
	{
		if(!scrollLeft && !scrollRight) [self displaySelectedViewInNewWindow:NO];
		userAction = (MouseEventType)[[self viewer] imageView].currentTool;
	}

	startWW = ww;
	startWL = wl;
	
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

	userAction = (MouseEventType)[[self viewer] imageView].currentToolRight;
}

- (void)mouseDragged:(NSEvent *)theEvent;
{
	NSPoint event_location = [theEvent locationInWindow];
	mouseDraggedPosition = [self convertPointFromWindowToOpenGL:event_location];
	mouseDragged = YES;
	
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
	BOOL scrollLeft = [self isMouseOnLeftLateralScrollBar: [self convertPointFromBacking: mouseDownPosition]] && [self cansScrollLeft];
	BOOL scrollRight = [self isMouseOnRightLateralScrollBar: [self convertPointFromBacking: mouseDownPosition]] && [self cansScrollRight];

	if(!mouseDragged && !scrollLeft && !scrollRight)
	{
		BOOL newWindow = mouseClickedWithCommandKey;
		[self displaySelectedViewInNewWindow:newWindow];
	}
	
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
	
	if( zoomFactor < 0.01) zoomFactor = 0.01;
	if( zoomFactor > 10) zoomFactor = 10;
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
	if(dontListenToNotification > 0) return;

	DCMPix *pix = [notif object];
	if(pix.ww!=ww || pix.wl!=wl)
	{
		ww = pix.ww;
		wl = pix.wl;
		for(int i=0; i<[isTextureWLWWUpdated count]; i++)
			[isTextureWLWWUpdated replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
		[self setNeedsDisplay:YES];
		
		for (ViewerController *viewer in [self associatedViewers])
		{
			[[viewer imageView] setWLWW:wl :ww];
		}
	}
}

- (void)refresh:(NSNotification*)notif;
{
	if(dontListenToNotification > 0) return;
	
	int curImageIndex = [[self viewer] imageIndex];
	int curMovieIndex = [[self viewer] curMovieIndex];
	if( curImageIndex != previousImageIndex || curMovieIndex != previousMovieIndex)
	{
		[self computeThumbnailSize];
		[[[self viewer] imageView] sendSyncMessage:0];
		[self displaySelectedImage];
		[self setNeedsDisplay:YES];
		previousImageIndex = curImageIndex;
		previousMovieIndex = curMovieIndex;
	}
}

- (void)refreshROIs:(NSNotification*)notif;
{
	if(dontListenToNotification > 0) return;
	
	[self displaySelectedImage];
	[self setNeedsDisplay:YES];
}

- (void)wlwwFrom:(NSPoint)start to:(NSPoint)stop;
{
	float WWAdapter = startWW / 100.0;
	if( WWAdapter < 0.001) WWAdapter = 0.001;
	
	wl = startWL + -(stop.y -  start.y)*WWAdapter;
	ww = startWW + (stop.x -  start.x)*WWAdapter;
	
	[[[self viewer] imageView] setWLWW:wl :ww];
	for (int i=0; i<[isTextureWLWWUpdated count]; i++)
		[isTextureWLWWUpdated replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
		
	for (ViewerController *viewer in [self associatedViewers])
	{
		[[viewer imageView] setWLWW:wl :ww];
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	if( ![[self window] isVisible])
		return;
	
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
//	if([self needsHorizontalScroller])
//		newOrigin.y += 20.0; // ... ?? don't know why, but it works...
		
	if(newOrigin.x<0) newOrigin.x = 0.0;
	if(newOrigin.x+viewBounds.size.width>[self frame].size.width) newOrigin.x = [self frame].size.width - viewBounds.size.width;

	if(newOrigin.x!=viewBounds.origin.x)
	{
		[clipView scrollToPoint: [clipView constrainScrollPoint: newOrigin]];//scrollToPoint
		[[self enclosingScrollView] reflectScrolledClipView:clipView];
	}
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
	
	int z = [[[self viewer] imageView] curImage];
	int t = [[self viewer] curMovieIndex];
	NSPoint upperLeft;
	upperLeft.x = z*thumbnailWidth;

	if([[[self viewer] imageView] flippedData]) upperLeft.x = ([[[self viewer] pixList] count]-z-1)*thumbnailWidth;
	
	upperLeft.y = ([[self viewer] maxMovieIndex]-t)*thumbnailHeight;//-viewBounds.origin.y;
	
	NSRect thumbRect = NSMakeRect(upperLeft.x, upperLeft.y-thumbnailHeight, thumbnailWidth, thumbnailHeight);
	NSRect intersectionRect = NSIntersectionRect(thumbRect, viewBounds);

	if(fabs(intersectionRect.size.width) < thumbnailWidth || fabs(intersectionRect.size.height) < thumbnailHeight)
	{
		NSPoint scrollToMe = NSMakePoint(viewBounds.origin.x, viewBounds.origin.y);
		
		if(thumbRect.origin.x < viewBounds.origin.x)
			scrollToMe.x = thumbRect.origin.x;
		else if(thumbRect.origin.x+thumbnailWidth > viewBounds.origin.x + viewBounds.size.width)
			scrollToMe.x = thumbRect.origin.x+thumbRect.size.width-viewFrame.size.width;
		if(thumbRect.origin.y < viewBounds.origin.y)
			scrollToMe.y = thumbRect.origin.y;
		else if(thumbRect.origin.y+thumbnailHeight > viewBounds.origin.y + viewBounds.size.height)
			scrollToMe.y = thumbRect.origin.y+thumbRect.size.height-viewFrame.size.height;
		
		[clipView scrollToPoint:[clipView constrainScrollPoint:scrollToMe]];

		[[self enclosingScrollView] reflectScrolledClipView:clipView];
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
	return [[NavigatorWindowController navigatorWindowController] viewerController];
	
//	NSArray *displayed2DViewers = [ViewerController getDisplayed2DViewers];
//	
//	for (ViewerController *v in displayed2DViewers)
//	{
//		if([[[v imageView] window] isMainWindow] && [v imageView].isKeyView)
//			return v;
//	}
//	
//	if([displayed2DViewers count]) return [displayed2DViewers lastObject];
//	
//	return previousViewer;
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

- (void)displaySelectedViewInNewWindow:(BOOL)newWindow;
{
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	NSRect viewBounds = [clipView documentVisibleRect];
	NSRect viewFrame = [clipView frame];
	NSSize viewSize = viewFrame.size;
    
    NSPoint position = [self convertPointFromBacking: mouseDownPosition];
    
	int z = (position.x + viewBounds.origin.x) / thumbnailWidth;
	int t = (position.y + [self frame].size.height-viewSize.height-viewBounds.origin.y)/thumbnailHeight;

	if(!newWindow)//t == [[self viewer] curMovieIndex] || [[self viewer] isPlaying4D]) // same time line: select the clicked slice
	{
		DCMView *view = [[self viewer] imageView];
		if([view flippedData]) [view setIndex:[[[self viewer] pixList] count]-z-1];
		else [view setIndex:z];
		
		if(t != [[self viewer] curMovieIndex])
		{
			ViewerController *selectedViewer;
			BOOL alreadyOpen = NO;
			for (ViewerController *viewer in [self associatedViewers])
			{
				if(t == [viewer curMovieIndex])
				{
					selectedViewer = viewer;
					alreadyOpen = YES;
				}
			}

			if(t == [[self viewer] curMovieIndex])
			{
				selectedViewer = [self viewer];
				alreadyOpen = YES;
			}

			if(!alreadyOpen)
				[[self viewer] setMovieIndex:t];
			else
			{
				// select the correct slice
				DCMView *view = [selectedViewer imageView];
				if([view flippedData]) [view setIndex:[[[self viewer] pixList] count]-z-1];
				else [view setIndex:z];
				// sync other viewers
				[view sendSyncMessage:0];
				// make key viewer
				[[selectedViewer window] makeKeyWindow];
				[self setNeedsDisplay:YES];
			}

		}
		
		[view sendSyncMessage:0];
	}
	else
	{
		dontListenToNotification++;
		[self openNewViewerAtSlice:z movieFrame:t]; // creates a new viewer
		dontListenToNotification--;
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
	
	for (int i=0; i<[[self viewer] maxMovieIndex]; i++)
	{
		[newViewer setRoiList: i array: [[self viewer] roiList: i]];
	}
	
	[newViewer setMovieIndex:t];

	// select the correct slice
	DCMView *view = [newViewer imageView];
	if([[[self viewer] imageView] flippedData]) [view setIndex:[[[self viewer] pixList] count]-z-1];
	else [view setIndex:z];
	
	// flippedData must be the same on all viewers
	view.flippedData = [[self viewer] imageView].flippedData;
	
	[newViewer adjustSlider];
	
	[[newViewer window] makeKeyAndOrderFront:self];
	[newViewer setWL: wl WW: ww];
	[newViewer propagateSettings];

	//[view sendSyncMessage:0];
	[newViewer checkEverythingLoaded];
}

#pragma mark-
#pragma mark Keyboard

- (void) keyDown:(NSEvent *)event
{
	[[[self viewer] imageView] keyDown:event];
}

#pragma mark-
#pragma mark Saving Transformation Values

- (void)saveTransformForCurrentViewer;
{
	if(![self viewer]) return;
	NSString *seriesInstanceUID = [[[[[self viewer] pixList:0] objectAtIndex:0] seriesObj] valueForKey:@"seriesInstanceUID"];
	NSMutableDictionary *currentTransform = [NSMutableDictionary dictionary];
	[currentTransform setObject:[NSNumber numberWithFloat:zoomFactor] forKey:@"zoomFactor"];
	[currentTransform setObject:[NSNumber numberWithFloat:rotationAngle] forKey:@"rotationAngle"];
	[currentTransform setObject:[NSValue valueWithPoint:offset] forKey:@"offset"];
	[savedTransformDict setObject:currentTransform forKey:seriesInstanceUID];
}

- (void)loadTransformForCurrentViewer;
{
	if(![self viewer]) return;
	NSString *seriesInstanceUID = [[[[[self viewer] pixList:0] objectAtIndex:0] seriesObj] valueForKey:@"seriesInstanceUID"];
	NSMutableDictionary *currentTransform = [savedTransformDict objectForKey:seriesInstanceUID];
	if(currentTransform)
	{
		zoomFactor = [[currentTransform objectForKey:@"zoomFactor"] floatValue];
		rotationAngle = [[currentTransform objectForKey:@"rotationAngle"] floatValue];
		offset = [[currentTransform objectForKey:@"offset"] pointValue];
	}
	else
	{
		zoomFactor = 1.0;
		rotationAngle = 0.0;
		offset = NSMakePoint(0, 0);
	}
	
	[self setNeedsDisplay:YES];
}

@end
