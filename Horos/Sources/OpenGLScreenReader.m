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
/*
 
 File: OpenGLScreenReader.m
 
 Abstract: OpenGLScreenReader class implementation. Contains
            OpenGL code which creates a full-screen OpenGL context
            to use for rendering, then calls glReadPixels to read the 
            actual screen bits.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2007 Apple Inc. All Rights Reserved.
 
 */ 
 
#import "OpenGLScreenReader.h"

@interface OpenGLScreenReader (PrivateMethods)
	-(void)flipImageData;
	-(CGImageRef)createRGBImageFromBufferData;
@end

@implementation OpenGLScreenReader (PrivateMethods)

/*
  * perform an in-place swap from Quadrant 1 to Quadrant III format
  * (upside-down PostScript/GL to right side up QD/CG raster format)
  * We do this in-place, which requires more copying, but will touch
  * only half the pages.  (Display grabs are BIG!)
  *
  * Pixel reformatting may optionally be done here if needed.
  */
  
-(void)flipImageData
{
    long top, bottom;
    void * buffer;
    void * topP;
    void * bottomP;
    void * base;
    long rowBytes;

    top = 0;
    bottom = mHeight - 1;
    base = mData;
    rowBytes = mByteWidth;
    buffer = malloc(rowBytes);
    NSAssert( buffer != nil, @"malloc failure");

    while ( top < bottom )
    {
        topP = (void *)((top * rowBytes) + (intptr_t)base);
        bottomP = (void *)((bottom * rowBytes) + (intptr_t)base);

        /*
          * Save and swap scanlines.
          *
          * This code does a simple in-place exchange with a temp buffer.
          * If you need to reformat the pixels, replace the first two bcopy()
          * calls with your own custom pixel reformatter.
          */
        bcopy( topP, buffer, rowBytes );
        bcopy( bottomP, topP, rowBytes );
        bcopy( buffer, bottomP, rowBytes );

        ++top;
        --bottom;
    }
    free( buffer );
}

// Create a RGB CGImageRef from our buffer data
-(CGImageRef)createRGBImageFromBufferData
{
    CGColorSpaceRef cSpace = CGColorSpaceCreateWithName (kCGColorSpaceGenericRGB);
    NSAssert( cSpace != NULL, @"CGColorSpaceCreateWithName failure");

    CGContextRef bitmap = CGBitmapContextCreate(mData, mWidth, mHeight, 8, mByteWidth,
                                    cSpace,  
	#if __BIG_ENDIAN__
		kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big /* XRGB Big Endian */);
	#else
		kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little /* XRGB Little Endian */);
	#endif                                    
    NSAssert( bitmap != NULL, @"CGBitmapContextCreate failure");

    // Get rid of color space
//    CFRelease(cSpace);

    // Make an image out of our bitmap; does a cheap vm_copy of the  
    // bitmap
    CGImageRef image = CGBitmapContextCreateImage(bitmap);
    NSAssert( image != NULL, @"CGBitmapContextCreate failure");

    // Get rid of bitmap
    CFRelease(bitmap);
    CGColorSpaceRelease( cSpace);
    
    return image;
}

@end

@implementation OpenGLScreenReader

// Take a "snapshot" of the screen and save the image to a TIFF file on disk
+ (void) screenSnapshotToFilePath:(NSString*)path;
{
    // Create a screen reader object
	OpenGLScreenReader *mOpenGLScreenReader = [[OpenGLScreenReader alloc] init];
    
	// Read the screen bits
    [mOpenGLScreenReader readFullScreenToBuffer];
	
    // Write our image to a TIFF file on disk
    [mOpenGLScreenReader createTIFFImageFileToPath:path];
	
    // Finished, so let's cleanup
    [mOpenGLScreenReader release];
}

#pragma mark ---------- Initialization ----------

-(id) init
{
    if (self = [super init])
    {
		// Create a full-screen OpenGL graphics context
		
		// Specify attributes of the GL graphics context
		NSOpenGLPixelFormatAttribute attributes[] = {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            NSOpenGLPFAFullScreen,
#pragma clang diagnostic pop
            NSOpenGLPFAScreenMask,
			CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
			(NSOpenGLPixelFormatAttribute) 0
			};

		NSOpenGLPixelFormat *glPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
		if (!glPixelFormat)
		{
            [self autorelease];
			return nil;
		}

		// Create OpenGL context used to render
		mGLContext = [[[NSOpenGLContext alloc] initWithFormat:glPixelFormat shareContext:nil] autorelease];

		// Cleanup, pixel format object no longer needed
		[glPixelFormat release];
    
        if (!mGLContext)
        {
            [self autorelease];
            return nil;
        }
        [mGLContext retain];

        // Set our context as the current OpenGL context
        [mGLContext makeCurrentContext];
        // Set full-screen mode
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [mGLContext setFullScreen];
#pragma clang diagnostic pop

		NSRect mainScreenRect = [[NSScreen mainScreen] frame];
		mWidth = mainScreenRect.size.width;
		mHeight = mainScreenRect.size.height;

        mByteWidth = mWidth * 4;                // Assume 4 bytes/pixel for now
        mByteWidth = (mByteWidth + 3) & ~3;    // Align to 4 bytes

        mData = malloc(mByteWidth * mHeight);
        NSAssert( mData != 0, @"malloc failed");
    }
    return self;
}

#pragma mark ---------- Screen Reader  ----------

// Perform a simple, synchronous full-screen read operation using glReadPixels(). 
// Although this is not the most optimal technique, it is sufficient for doing 
// simple one-shot screen grabs.
- (void) readFullScreenToBuffer
{
    [self readPartialScreenToBuffer: mWidth bufferHeight: mHeight bufferBaseAddress: mData];
}

// Use this routine if you want to read only a portion of the screen pixels
- (void) readPartialScreenToBuffer: (size_t) width bufferHeight:(size_t) height bufferBaseAddress: (void *) baseAddress
{
    // select front buffer as our source for pixel data
    glReadBuffer(GL_FRONT);
    
    //Read OpenGL context pixels directly.

    // For extra safety, save & restore OpenGL states that are changed
    glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4); /* Force 4-byte alignment */
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    
    //Read a block of pixels from the frame buffer
    glReadPixels(0, 0, width, height, GL_BGRA, 
    /*
    IMPORTANT
    
    For the pixel data format and type parameters you should *always* specify:
    
        format: GL_BGRA
        type: GL_UNSIGNED_INT_8_8_8_8_REV
    
    because this is the native format of the GPU for both PPC and Intel and will 
    give you the best performance. Any deviation from this format will not give 
    you optimal performance!
    
    BACKGROUND
    
    When using GL_UNSIGNED_INT_8_8_8_8_REV, the OpenGL implementation 
    expects to find data in byte order ARGB on big-endian systems, but BGRA on 
    little-endian systems. Because there is no explicit way in OpenGL to specify 
    a byte order of ARGB with 32-bit or 16-bit packed pixels (which are common
    image formats on Macintosh PowerPC computers), many applications specify 
    GL_BGRA with GL_UNSIGNED_INT_8_8_8_8_REV. This practice works on a 
    big-endian system such as PowerPC, but the format is interpreted differently 
    on a little-endian system, and causes images to be rendered with incorrect colors.

    To prevent images from being rendered incorrectly by this application on little 
    endian systems, you must specify the ordering of the data (big/little endian)
    when creating Quartz bitmap contexts using the CGBitmapContextCreate function. 
    See the createRGBImageFromBufferData: method in the Buffer.m source file for
    the details.

    Also, if you need to reverse endianness, consider using vImage after the read. See: 

    http://developer.apple.com/documentation/Performance/Conceptual/vImage/
    
    */
            GL_UNSIGNED_INT_8_8_8_8_REV,
            baseAddress);

    glPopClientAttrib();

    //Check for OpenGL errors
    GLenum theError = GL_NO_ERROR;
    theError = glGetError();
    NSAssert1( theError == GL_NO_ERROR, @"OpenGL error 0x%04X", theError);
}

// Create a TIFF file on the desktop from our data buffer
-(void)createTIFFImageFileOnDesktop
{
	// Make full pathname to the desktop directory
    NSString *desktopDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains
	(NSDesktopDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)  
    {
        desktopDirectory = [paths objectAtIndex:0];
    }
	
    NSMutableString *fullFilePathStr = [NSMutableString stringWithString:desktopDirectory];
    NSAssert( fullFilePathStr != nil, @"stringWithString failed");
    [fullFilePathStr appendString:@"/ScreenSnapshot.tiff"];
	
    NSString *finalPath = [NSString stringWithString:fullFilePathStr];
    NSAssert( finalPath != nil, @"stringWithString failed");
	
	[self createTIFFImageFileToPath:finalPath];
}

// Create a TIFF file from our data buffer
-(void)createTIFFImageFileToPath:(NSString*)path
{
    // glReadPixels writes things from bottom to top, but we
    // need a top to bottom representation, so we must flip
    // the buffer contents.
    [self flipImageData];

    // Create a Quartz image from our pixel buffer bits
    CGImageRef imageRef = [self createRGBImageFromBufferData];
    NSAssert( imageRef != 0, @"cgImageFromPixelBuffer failed");

    CFURLRef url = CFURLCreateWithFileSystemPath (
												kCFAllocatorDefault,
												(CFStringRef)path,
												kCFURLPOSIXPathStyle,
												false);
    NSAssert( url != 0, @"CFURLCreateWithFileSystemPath failed");
    // Save our screen bits to an image file on disk

    // Save the image to the file
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, CFSTR("public.tiff"), 1, nil);
    NSAssert( dest != 0, @"CGImageDestinationCreateWithURL failed");

    // Set the image in the image destination to be `image' with
    // optional properties specified in saved properties dict.
    CGImageDestinationAddImage(dest, imageRef, nil);
    
    bool success = CGImageDestinationFinalize(dest);
    NSAssert( success != 0, @"Image could not be written successfully");

    CFRelease(dest);
    CGImageRelease(imageRef);
    CFRelease(url);
}

#pragma mark ---------- Cleanup  ----------

-(void)dealloc
{    
    // Get rid of GL context
    [NSOpenGLContext clearCurrentContext];
    // disassociate from full screen
    [mGLContext clearDrawable];
    // and release the context
    [mGLContext release];
	// release memory for screen data
	free(mData);

    [super dealloc];
}

@end
