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

#import "LoupeView.h"


@implementation LoupeView

@synthesize drawLoupeBorder;

- (void)makeTextureFromImage:(NSImage*)image forTexture:(GLuint*)texName buffer:(GLubyte*)buffer;
{	
	NSSize imageSize = [image size];
	
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	
	buffer = malloc([bitmap bytesPerRow] * imageSize.height);
	memcpy(buffer, [bitmap bitmapData], [bitmap bytesPerRow] * imageSize.height);
	
	[bitmap release];
	
	CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
	glGenTextures(1, texName);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, *texName);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/[bitmap samplesPerPixel]);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, ([bitmap samplesPerPixel]==4)?GL_RGBA:GL_RGB, imageSize.width, imageSize.height, 0, ([bitmap samplesPerPixel]==4)?GL_RGBA:GL_RGB, GL_UNSIGNED_BYTE, buffer);
}

- (void)setTexture:(char*)texture withSize:(NSSize)textureSize bytesPerRow:(int)bytesPerRow rotation:(float)rotation;
{
	textureRotation = rotation;
	
	[[self openGLContext] makeCurrentContext];
	CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
	
	if(textureID) glDeleteTextures(1, &textureID);

	if(textureWidth!=textureSize.width || textureHeight!=textureSize.height)
		//free(textureBuffer);
	
	textureWidth = textureSize.width;
	textureHeight = textureSize.height;
	
//	if(!textureBuffer)
//		textureBuffer = malloc(bytesPerRow * textureSize.height);
//	memcpy(textureBuffer, texture, bytesPerRow * textureSize.height);
	textureBuffer = (GLubyte *)texture;
	
	glGenTextures(1, &textureID);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureID);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, bytesPerRow);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glColor4f( 1, 1, 1, 1);
#if __BIG_ENDIAN__
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, textureSize.width, textureSize.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, textureBuffer);
#else
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, textureSize.width, textureSize.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, textureBuffer);
#endif
		
	[self setNeedsDisplay:YES];
}

- (id)initWithFrame:(NSRect)frameRect
{
	NSOpenGLPixelFormatAttribute attrs[] = { NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, 0};
    NSOpenGLPixelFormat* pixFmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];

	self = [super initWithFrame:frameRect pixelFormat:pixFmt];
    if(self)
	{
		NSBundle *bundle = [NSBundle bundleForClass: [LoupeView class]];
		loupeImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"loupe.png"]];
		loupeTextureWidth = [loupeImage size].width;
		loupeTextureHeight = [loupeImage size].height;
		loupeMaskImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"loupeMask.png"]];
		loupeMaskTextureWidth = [loupeMaskImage size].width;
		loupeMaskTextureHeight = [loupeMaskImage size].height;
		drawLoupeBorder = NO;
    }
    return self;
}

- (void) dealloc
{
	if(loupeTextureBuffer)
		free(loupeTextureBuffer);

	if(loupeMaskTextureBuffer)
		free(loupeMaskTextureBuffer);
	
	if(textureBuffer)
		free(textureBuffer);
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];

	GLint opaque = 0;
	[[self openGLContext] setValues:&opaque forParameter:NSOpenGLCPSurfaceOpacity];
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	glViewport(0, 0, [self frame].size.width, [self frame].size.height);
	glScalef(2.0f/[self frame].size.width, -2.0f / [self frame].size.height, 1.0f);
	glTranslatef(-([self frame].size.width)/2.0f, -([self frame].size.height)/2.0f, 0.0f); // translate center to upper left

	glEnable(GL_BLEND);
//	glBlendEquation(GL_FUNC_ADD);
//	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	if(loupeTextureID==0)
		[self makeTextureFromImage:loupeImage forTexture:&loupeTextureID buffer:loupeTextureBuffer];

	if(loupeMaskTextureID==0)
		[self makeTextureFromImage:loupeMaskImage forTexture:&loupeMaskTextureID buffer:loupeMaskTextureBuffer];

	if(loupeMaskTextureID)
	{		
		glEnable(GL_TEXTURE_RECTANGLE_EXT);
		
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, loupeMaskTextureID);
		
		glColor4f(1.0, 1.0, 1.0, 1.0);
		
		glBegin(GL_QUAD_STRIP);
		
		glTexCoord2f(0, 0);
		glVertex2f(0, 0);
		
		glTexCoord2f(loupeMaskTextureWidth, 0);
		glVertex2f(loupeMaskTextureWidth, 0);
		
		glTexCoord2f(0, loupeMaskTextureHeight);
		glVertex2f(0, loupeMaskTextureHeight);
		
		glTexCoord2f(loupeMaskTextureWidth, loupeMaskTextureHeight);
		glVertex2f(loupeMaskTextureWidth, loupeMaskTextureHeight);
		
		glEnd();
		
		glDisable(GL_TEXTURE_RECTANGLE_EXT);
	}

	if(textureID)
	{
		glBlendFunc(GL_DST_ALPHA, GL_ZERO);
		
		glTranslatef([self frame].size.width/2.0f, [self frame].size.height/2.0f, 0.0f); // translate the origin to the center
		glRotatef(textureRotation, 0.0f, 0.0f, 1.0f);
		glTranslatef(-([self frame].size.width)/2.0f, -([self frame].size.height)/2.0f, 0.0f); // translate the origin to upper left corner
		
		glPixelStorei(GL_UNPACK_ROW_LENGTH, textureWidth*4);
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);

		glEnable(GL_TEXTURE_RECTANGLE_EXT);
		
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureID);
				
		glColor4f(1.0, 1.0, 1.0, 1.0);

		glPixelStorei(GL_UNPACK_ROW_LENGTH, textureWidth*4);
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);

		glBegin(GL_QUAD_STRIP);
		
		glTexCoord2f(0, 0);
		glVertex2f(0, 0);
		
		glTexCoord2f(textureWidth, 0);
		glVertex2f([self frame].size.width, 0);
		
		glTexCoord2f(0, textureHeight);
		glVertex2f(0, [self frame].size.height);
		
		glTexCoord2f(textureWidth, textureHeight);
		glVertex2f([self frame].size.width, [self frame].size.height);
	
		glEnd();
		
		glDisable(GL_TEXTURE_RECTANGLE_EXT);
		
		glTranslatef([self frame].size.width/2.0f, [self frame].size.height/2.0f, 0.0f); // translate the origin to the center
		glRotatef(-textureRotation, 0.0f, 0.0f, 1.0f);
		glTranslatef(-([self frame].size.width)/2.0f, -([self frame].size.height)/2.0f, 0.0f); // translate the origin to upper left corner		
	}
	
	glBlendEquation(GL_FUNC_ADD);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	if(loupeTextureID && drawLoupeBorder)
	{
		glEnable(GL_TEXTURE_RECTANGLE_EXT);
		
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, loupeTextureID);
		
		glColor4f(1.0, 1.0, 1.0, 1.0);
		
		glBegin(GL_QUAD_STRIP);
		
			glTexCoord2f(0, 0);
			glVertex2f(0, 0);
			
			glTexCoord2f(loupeTextureWidth, 0);
			glVertex2f(loupeTextureWidth, 0);
			
			glTexCoord2f(0, loupeTextureHeight);
			glVertex2f(0, loupeTextureHeight);
			
			glTexCoord2f(loupeTextureWidth, loupeTextureHeight);
			glVertex2f(loupeTextureWidth, loupeTextureHeight);
		
		glEnd();

		glDisable(GL_TEXTURE_RECTANGLE_EXT);
	}
	
	
//	glColor4f(0.7, 0.7, 0.0, 1.0);
//	glLineWidth(10);
//	
//	int resol = 80;//[self frame].size.width*4.0;
//	
//	NSPoint center;
//	center.x += [self frame].size.width*0.5;
//	center.y += [self frame].size.height*0.5;
//	
//	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
//	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
//	glEnable(GL_POINT_SMOOTH);
//	glEnable(GL_LINE_SMOOTH);
//	glEnable(GL_POLYGON_SMOOTH);
//	
//	float f = [self frame].size.width*0.5-5;
//	float angle;
//	glBegin(GL_LINE_LOOP);
//	int i;
//	for( i = 0; i < resol ; i++ )
//	{
//		angle = i * 2 * M_PI /resol;
//		glVertex2f( center.x + f *cos(angle), center.y + f *sin(angle));
//	}
//	glEnd();
	
//	glPointSize( 10);
//	glBegin( GL_POINTS);
//	for( int i = 0; i < resol ; i++ )
//	{
//		angle = i * 2 * M_PI /resol;
//		
//		glVertex2f( center.x + f *cos(angle), center.y + f *sin(angle));
//	}
//	glEnd();
//	glDisable(GL_LINE_SMOOTH);
//	glDisable(GL_POLYGON_SMOOTH);
//	glDisable(GL_POINT_SMOOTH);
	
	glDisable(GL_BLEND);
	
	[[self openGLContext] flushBuffer];	
	
}

-(void)awakeFromNib
{
    [self setNeedsDisplay:YES];
}

@end
