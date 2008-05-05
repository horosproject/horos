//
//  OpenGLView.m
//  DCMSampleApp
//
//  Created by Lance Pysher on Tue Aug 03 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import "OpenGLView.h"
#import <veclib/veclib.h>
#import <OpenGL/gl.h>
#import "DCM.h"

vImage_Buffer *pixels;

@implementation OpenGLView

- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)format{
   if ( self = [super initWithFrame:frame pixelFormat:[NSOpenGLView defaultPixelFormat]])
		pixels = nil;
    return self;
}

- (void)drawRect:(NSRect)rect {
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glMatrixMode(GL_TEXTURE);
	glLoadIdentity();
	glClearColor( 0.0f, 0.0f, 0.0f, 1.0f );
	glClear (GL_COLOR_BUFFER_BIT); // clear the color buffer before drawing
	glViewport (0, 0, [self frame].size.width, [self frame].size.height); // set the viewport to cover entire window
    if (pixels){
		glRasterPos3d (0, 0, 0);
		glDrawPixels(pixels->width,
					pixels->height,
					GL_ALPHA,
					GL_FLOAT,
					pixels->data);
	}
	[[self openGLContext] flushBuffer];
	[self glErrorCheck];
}

- (void)setDDCMObject:(DCMObject *)object{
	vImage_Buffer *src = malloc(sizeof(vImage_Buffer));
	vImage_Buffer *dst = malloc(sizeof(vImage_Buffer));
	height = [[[object attributeForTag:[DCMAttributeTag tagWithName:@"Rows"]] value] intValue];
	width =  [[[object attributeForTag:[DCMAttributeTag tagWithName:@"Columns"]] value] intValue];
	pixelDepth = [[[object attributeForTag:[DCMAttributeTag tagWithName:@"BitsStored"]] value] intValue];	
	spp = [[[object attributeForTag:[DCMAttributeTag tagWithName:@"SamplesperPixel"]] value] intValue];
	NSData *pixelData = [[object attributeForTag:[DCMAttributeTag tagWithName:@"PixelData"]] value];
	if (pixelDepth <= 8) {
		MyInitBuffer( src, height, width, spp );
		MyInitBuffer( dst, height, width, spp * 4 );
		[pixelData getBytes:src->data];
		vImage_Error err =  vImageConvert_Planar8toPlanarF (
			src, 
			dst, 
			1.0, 
			0.0, 
			nil
			);
		NSLog(@"err %d", err);
	}
	else{
		MyInitBuffer( src, height, width, spp * 2);
		MyInitBuffer( dst, height, width, spp  * 4);
		[pixelData getBytes:src->data];
		vImage_Error err = vImageConvert_16SToF ( 
			src, 
			dst, 
			0.5, 
			4000, 
			nil 
			);
		NSLog(@"err %d", err);
	}
	pixels = dst;
	[dcmObject release];
	dcmObject = [object retain];
	[self setNeedsDisplay:YES];
	
}

- (void)glErrorCheck{
    GLenum errorCode;
   // GLubyte *errorString;
    while ((errorCode = glGetError()) != GL_NO_ERROR)
        NSLog(@"%@ OpenGL Error %s", [self description], gluErrorString(errorCode));
}



@end
