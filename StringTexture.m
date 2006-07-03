/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "StringTexture.h"

@implementation StringTexture

- (void) deleteTexture
{
	if (texName && cgl_ctx) {
		(*cgl_ctx->disp.delete_textures)(cgl_ctx->rend, 1, &texName);
		texName = 0; // ensure it is zeroed for failure cases
		cgl_ctx = 0;
	}
}

// designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	[super init];
	cgl_ctx = NULL;
	texName = 0;
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
	// all other variables 0 or NULL
	return self;
}

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease] withTextColor:text withBoxColor:box withBorderColor:border];
}

// basic methods that pick up defaults
- (id) initWithAttributedString:(NSAttributedString *)attributedString;
{
	return [self initWithAttributedString:attributedString withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs
{
	return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease] withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (void) dealloc
{
	[self deleteTexture];
	[textColor release];
	[boxColor release];
	[borderColor release];
	[string release];
	[super dealloc];
}

- (GLuint) texName
{
	return texName;
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

- (void) genTexture; // generates the texture without drawing texture to current context
{
	NSImage * image;
	NSBitmapImageRep * bitmap;
	
	[self deleteTexture];
	if ((NO == staticFrame) && (0.0f == frameSize.width) && (0.0f == frameSize.height)) { // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
	}
	image = [[NSImage alloc] initWithSize:frameSize];
	[image lockFocus];
	
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	
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
	if (cgl_ctx = CGLGetCurrentContext ()) { // if we successfully retrieve a current context (required)
		glGenTextures (1, &texName);
		glBindTexture (GL_TEXTURE_RECTANGLE_EXT, texName);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 0);
		glTexImage2D (GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, texSize.width, texSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
	} else
		NSLog (@"StringTexture -genTexture: Failure to get current OpenGL context\n");
	[bitmap release];
	[image release];
}

- (void) drawWithBounds:(NSRect)bounds
{
	if (!texName)
		[self genTexture];
	if (texName) {
		glBindTexture (GL_TEXTURE_RECTANGLE_EXT, texName);
		glBegin (GL_QUADS);
			glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y);
	
			glTexCoord2f (0.0f, texSize.height); // draw lower left in world coordinates
			glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (texSize.width, texSize.height); // draw upper right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
	
			glTexCoord2f (texSize.width, 0.0f); // draw lower right in world coordinates
			glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);
		glEnd ();
	}
}

- (void) drawAtPoint:(NSPoint)point
{
	if (!texName)
		[self genTexture]; // ensure size is calculated for bounds
	if (texName) // if successful
		[self drawWithBounds:NSMakeRect (point.x, point.y, texSize.width, texSize.height)];
}

// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size // set offset size and size to fit with offset
{
	[self deleteTexture];
	marginSize = size;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
}

- (void) useStaticFrame:(NSSize)size // set static frame size and size to frame
{
	[self deleteTexture];
	frameSize = size;
	staticFrame = YES;
}

- (void) useDynamicFrame
{
	if (staticFrame) { // set to dynamic frame and set to regen texture
		[self deleteTexture];
		staticFrame = NO;
		frameSize.width = 0.0f; // ensure frame sizes will be recalculated
		frameSize.height = 0.0f;
	}
}

- (void) setString:(NSAttributedString *)attributedString // set string after initial creation
{
	[self deleteTexture];
	[attributedString retain];
	[string release];
	string = attributedString;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
}

- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation
{
	[self setString:[[[NSAttributedString alloc] initWithString:aString attributes:attribs] autorelease]];
}

- (void) setTextColor:(NSColor *)color // set default text color
{
	[self deleteTexture];
	[color retain];
	[textColor release];
	textColor = color;
}

- (void) setBoxColor:(NSColor *)color // set default text color
{
	[self deleteTexture];
	[color retain];
	[boxColor release];
	boxColor = color;
}

- (void) setBorderColor:(NSColor *)color // set default text color
{
	[self deleteTexture];
	[color retain];
	[borderColor release];
	borderColor = color;
}

@end
