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




#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLContext.h>
#import <OpenGL/CGLMacro.h>


/** \brief  Converts NSStrings to OpenGL textures*/
@interface StringTexture : NSObject
{
	NSMutableArray *ctxArray;	//All contexts where this texture is used
	NSMutableArray *textArray;	//All texture id
	NSBitmapImageRep *bitmap;
	
	NSSize texSize;
	
	BOOL xFlipped;
	BOOL yFlipped;
	
	NSAttributedString * string;
	NSColor * textColor; // default is opaque white
	NSColor * boxColor; // default transparent or none
	NSColor * borderColor; // default transparent or none
	BOOL staticFrame; // default in NO
	NSSize marginSize; // offset or frame size, default is 4 width 2 height
	NSSize frameSize; // offset or frame size, default is 4 width 2 height
	BOOL antialiasing;
    float sf; // screen factor during creation
}

// this API requires a current rendering context and all operations will be performed in regards to thar context
// the same context should be current for all method calls for a particular object instance

// designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString withTextColor:(NSColor *)color withBoxColor:(NSColor *)color withBorderColor:(NSColor *)color;

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs withTextColor:(NSColor *)color withBoxColor:(NSColor *)color withBorderColor:(NSColor *)color;

// basic methods that pick up defaults
- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs;
- (id) initWithAttributedString:(NSAttributedString *)attributedString;

- (void) dealloc;
- (void) deleteTexture;
- (void) deleteTexture:(NSOpenGLContext*) c;

- (NSSize) texSize; // actually size of texture generated in texels, (0, 0) if no texture allocated

- (void) setFlippedX: (BOOL) x Y:(BOOL) y;
- (NSColor *) textColor; // get the pre-multiplied default text color (includes alpha) string attributes could override this
- (NSColor *) boxColor; // get the pre-multiplied box color (includes alpha) alpha of 0.0 means no background box
- (NSColor *) borderColor; // get the pre-multiplied border color (includes alpha) alpha of 0.0 means no border
- (BOOL) staticFrame; // returns whether or not a static frame will be used

- (NSSize) frameSize; // returns either dynamc frame (text size + margins) or static frame size (switch with staticFrame)

- (NSSize) marginSize; // current margins for text offset and pads for dynamic frame

- (GLuint) genTexture; // generates the texture without drawing texture to current context
- (GLuint) genTextureWithBackingScaleFactor: (float) backingScaleFactor;
- (void) drawWithBounds:(NSRect)bounds; // will update the texture if required due to change in settings (note context should be setup to be orthographic scaled to per pixel scale)
- (void) drawAtPoint:(NSPoint)point;
- (void) drawAtPoint:(NSPoint)point ratio:(float) ratio;

// these will force the texture to be regenerated at the next draw

- (void) setString:(NSAttributedString *)attributedString; // set string after initial creation
- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation

- (void) setTextColor:(NSColor *)color; // set default text color
- (void) setBoxColor:(NSColor *)color; // set default text color
- (void) setBorderColor:(NSColor *)color; // set default text color
- (void) setAntiAliasing:(BOOL) a;
@end

