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

#include <OpenGL/CGLMacro.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>

@interface LoupeView : NSOpenGLView {
	NSImage *loupeImage, *loupeMaskImage;
	
	GLuint loupeTextureID, loupeTextureWidth, loupeTextureHeight;
	GLubyte *loupeTextureBuffer;
	
	GLuint loupeMaskTextureID, loupeMaskTextureWidth, loupeMaskTextureHeight;
	GLubyte *loupeMaskTextureBuffer;
	
	GLuint textureID, textureWidth, textureHeight;
	GLubyte *textureBuffer;
	float textureRotation;
	
	BOOL drawLoupeBorder;
}

@property BOOL drawLoupeBorder;

- (void)makeTextureFromImage:(NSImage*)image forTexture:(GLuint*)texName buffer:(GLubyte*)buffer;
- (void)setTexture:(char*)texture withSize:(NSSize)textureSize bytesPerRow:(int)bytesPerRow rotation:(float)rotation;
	
@end
