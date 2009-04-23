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

#import "StringTexture.h"

@implementation StringTexture

- (void) deleteTexture
{
	NSOpenGLContext *c = [NSOpenGLContext currentContext];
	
	NSUInteger index = [ctxArray indexOfObjectIdenticalTo: c];
	
	if( c && index != NSNotFound)
	{
		GLuint t = [[textArray objectAtIndex: index] intValue];
		CGLContextObj cgl_ctx = [c CGLContextObj];
		
		if( t)
			(*cgl_ctx->disp.delete_textures)(cgl_ctx->rend, 1, &t);
		
		[ctxArray removeObjectAtIndex: index];
		[textArray removeObjectAtIndex: index];
	}
}

- (void) deleteTexture:(NSOpenGLContext*) c
{
	NSUInteger index = [ctxArray indexOfObjectIdenticalTo: c];
	
	if( c && index != NSNotFound)
	{
		GLuint t = [[textArray objectAtIndex: index] intValue];
		CGLContextObj cgl_ctx = [c CGLContextObj];
		
		if( t)
			(*cgl_ctx->disp.delete_textures)(cgl_ctx->rend, 1, &t);
		
		[ctxArray removeObjectAtIndex: index];
		[textArray removeObjectAtIndex: index];
	}
}

// designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	[super init];
	antialiasing = NO;
	texSize.width = 0.0f;
	texSize.height = 0.0f;
	[attributedString retain];
	string = attributedString;
	[text retain];
	[box retain];
	[border retain];
	textColor = text;
	boxColor = box;
	borderColor = border;
	staticFrame = NO;
	marginSize.width = 4.0f; // standard margins
	marginSize.height = 2.0f;
	ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
	textArray = [[NSMutableArray arrayWithCapacity: 10] retain];
	// all other variables 0 or NULL
	return self;
}

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	if( aString == nil) aString = @"";
	return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease] withTextColor:text withBoxColor:box withBorderColor:border];
}

// basic methods that pick up defaults
- (id) initWithAttributedString:(NSAttributedString *)attributedString;
{
	if( attributedString == nil) attributedString = @"";
	return [self initWithAttributedString:attributedString withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs
{
	if( aString == nil) aString = @"";
	return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease] withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (void) dealloc
{
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	[ctxArray release];
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	[textArray release];
	
	[textColor release];
	[boxColor release];
	[borderColor release];
	[string release];
	
	[super dealloc];
}


- (NSSize) texSize
{
	return texSize;
}

- (NSColor *) textColor
{
	return textColor;
}

- (NSColor *) boxColor
{
	return boxColor;
}

- (NSColor *) borderColor
{
	return borderColor;
}

- (NSSize) frameSize
{
	if ((NO == staticFrame) && (0.0f == frameSize.width) && (0.0f == frameSize.height)) { // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
	}
	return frameSize;
}

- (NSSize) marginSize
{
	return marginSize;
}

- (BOOL) staticFrame
{
	return staticFrame;
}

- (void) setAntiAliasing:(BOOL) a
{
	antialiasing = a;
}

- (GLuint) genTexture; // generates the texture without drawing texture to current context
{
	NSImage * image;
	NSBitmapImageRep * bitmap;
	
	NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
	CGLContextObj cgl_ctx = [currentContext CGLContextObj];
	
	if( currentContext == nil)
	{
		NSLog( @"********* NO CURRENT CONTEXT for genTexture");
		return 0;
	}
	
	[self deleteTexture: currentContext];
	if ((NO == staticFrame) && (0.0f == frameSize.width) && (0.0f == frameSize.height)) { // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
	}
	
	GLuint texName = 0;
	
	bitmap = nil;
	image = [[NSImage alloc] initWithSize:frameSize];
	if( [image size].width > 0 && [image size].height > 0)
	{
		[image lockFocus];
		
		[[NSGraphicsContext currentContext] setShouldAntialias: antialiasing];
		
		if ([boxColor alphaComponent]) { // this should be == 0.0f but need to make sure
			[boxColor set]; 
			NSRectFill (NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height));
		}
		if ([borderColor alphaComponent]) {
			[borderColor set]; 
			NSFrameRect (NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height));
		}
		[textColor set];
		[string drawAtPoint:NSMakePoint (marginSize.width, marginSize.height)];
		
		bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height)];
		
		[image unlockFocus];
	
		texSize.width = [bitmap size].width;
		texSize.height = [bitmap size].height;
		
		glGenTextures (1, &texName);
		glBindTexture (GL_TEXTURE_RECTANGLE_EXT, texName);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 0);
		glTexImage2D (GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, texSize.width, texSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
		
		[ctxArray addObject: currentContext];
		[textArray addObject: [NSNumber numberWithInt: texName]];
			
		[bitmap release];
	}
	
	[image release];
	
	return texName;
}

- (void) setFlippedX: (BOOL) x Y:(BOOL) y
{
	xFlipped = x;
	yFlipped = y;
}

- (void) drawWithBounds:(NSRect)bounds
{
	NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
	GLuint texName = 0;
	NSUInteger index = [ctxArray indexOfObjectIdenticalTo: currentContext];
	if( index != NSNotFound)
		texName = [[textArray objectAtIndex: index] intValue];
	
	if (!texName)
		texName = [self genTexture];
	
	if (texName)
	{
		CGLContextObj cgl_ctx = [currentContext CGLContextObj];
		
		glBindTexture (GL_TEXTURE_RECTANGLE_EXT, texName);
		
		glBegin (GL_QUADS);
		
		if( yFlipped == NO && xFlipped == NO)
		{
			glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y);
	
			glTexCoord2f (0.0f, texSize.height); // draw lower left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);

			glTexCoord2f (texSize.width, texSize.height); // draw upper right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (texSize.width, 0.0f); // draw lower right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);

		}
		else if( yFlipped == YES && xFlipped == YES)
		{
			glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (0.0f, texSize.height); // draw lower left in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);

			glTexCoord2f (texSize.width, texSize.height); // draw upper right in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y);
	
			glTexCoord2f (texSize.width, 0.0f); // draw lower right in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
		}
		else if( yFlipped == YES && xFlipped == NO)
		{
			glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (0.0f, texSize.height); // draw lower left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y);

			glTexCoord2f (texSize.width, texSize.height); // draw upper right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);
	
			glTexCoord2f (texSize.width, 0.0f); // draw lower right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
		}
		else if( yFlipped == NO && xFlipped == YES)
		{
			glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);
	
			glTexCoord2f (0.0f, texSize.height); // draw lower left in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);

			glTexCoord2f (texSize.width, texSize.height); // draw upper right in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (texSize.width, 0.0f); // draw lower right in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y);
		}
		
		glEnd ();
	}
}

- (void) drawAtPoint:(NSPoint)point ratio:(float) ratio
{
	NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
	GLuint texName = 0;
	NSUInteger index = [ctxArray indexOfObjectIdenticalTo: currentContext];
	if( index != NSNotFound)
		texName = [[textArray objectAtIndex: index] intValue];
	
	if (!texName)
		texName = [self genTexture];
	
	if (texName) // if successful
		[self drawWithBounds:NSMakeRect (point.x, point.y, texSize.width, texSize.height*ratio)];

}

- (void) drawAtPoint:(NSPoint)point
{
	[self drawAtPoint: point ratio: 1.0];
}


// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size // set offset size and size to fit with offset
{
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	
	marginSize = size;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	[self genTexture];
}

- (void) useStaticFrame:(NSSize)size // set static frame size and size to frame
{
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	
	frameSize = size;
	staticFrame = YES;
	[self genTexture];
}

- (void) useDynamicFrame
{
	if (staticFrame)
	{ // set to dynamic frame and set to regen texture
		while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
		if( [textArray count]) NSLog( @"** not all texture were deleted...");
		
		staticFrame = NO;
		frameSize.width = 0.0f; // ensure frame sizes will be recalculated
		frameSize.height = 0.0f;
		[self genTexture];
	}
}

- (void) setString:(NSAttributedString *)attributedString // set string after initial creation
{
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	
	[attributedString retain];
	[string release];
	string = attributedString;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	[self genTexture];
}

- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation
{
	if( aString == nil) aString = @"";
	[self setString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease]];
}

- (void) setTextColor:(NSColor *)color // set default text color
{
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	
	[color retain];
	[textColor release];
	textColor = color;
	[self genTexture];
}

- (void) setBoxColor:(NSColor *)color // set default text color
{
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	
	[color retain];
	[boxColor release];
	boxColor = color;
	[self genTexture];
}

- (void) setBorderColor:(NSColor *)color // set default text color
{
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	
	[color retain];
	[borderColor release];
	borderColor = color;
	[self genTexture];
}

@end
