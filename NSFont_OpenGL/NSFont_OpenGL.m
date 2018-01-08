/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/
/*
 * This program is Copyright © 2002 Bryan L Blackburn.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Neither the names Bryan L Blackburn, Withay.com, nor the names of any
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY BRYAN L BLACKBURN ``AS IS'' AND ANY EXPRESSED OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
 * EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Initial version, 27 October, 2002
 */

/* NSFont_OpenGL.m */

#import "NSFont_OpenGL.h"
#import "N2Debug.h"

#define MAXCOUNT 256

@interface NSFont (withay_OpenGL_InternalMethods)
+ (unsigned char*) createCharacterWithImage:(NSBitmapImageRep *)bitmap;
+ (void) doOpenGLLog:(NSString *)format, ...;
@end

@implementation NSFont (withay_OpenGL)

static  BOOL					openGLLoggingEnabled = YES;
static  NSMutableArray			*imageArray = nil, *imageArrayPreview = nil,  *imageArrayROI = nil;
static  NSMutableArray			*imageArrayScale2 = nil, *imageArrayPreviewScale2 = nil,  *imageArrayROIScale2 = nil;

static	BOOL					fontOpenGLInitialized = NO;
static  long					charSizeArray[ MAXCOUNT], charSizeArrayPreview[ MAXCOUNT], charSizeArrayROI[ MAXCOUNT];
static  unsigned char			*charPtrArray[ MAXCOUNT], *charPtrArrayPreview[ MAXCOUNT], *charPtrArrayROI[ MAXCOUNT];

static  long					charSizeArrayScale2[ MAXCOUNT], charSizeArrayPreviewScale2[ MAXCOUNT], charSizeArrayROIScale2[ MAXCOUNT];
static  unsigned char			*charPtrArrayScale2[ MAXCOUNT], *charPtrArrayPreviewScale2[ MAXCOUNT], *charPtrArrayROIScale2[ MAXCOUNT];
/*
 * Enable/disable logging, class-wide, not object-wide
 */
+ (void) setOpenGLLogging:(BOOL)logEnabled
{
   openGLLoggingEnabled = logEnabled;
}

+ (void) resetFont: (int) fontType
{
	int i;
	
	if( fontOpenGLInitialized == NO)
	{
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayPreview[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArray[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayROI[ i] = 0;
        
        for( i = 0; i < MAXCOUNT; i++) charPtrArrayPreviewScale2[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayScale2[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayROIScale2[ i] = 0;
		
		fontOpenGLInitialized = YES;
	}
	
	switch( fontType)
	{
		case 0:
			if( imageArray)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					if( charPtrArray[ i]) free( charPtrArray[ i]);
					charPtrArray[ i] = 0L;
				}
				[imageArray release];
				imageArray = nil;
			}
            if( imageArrayScale2)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					if( charPtrArrayScale2[ i]) free( charPtrArrayScale2[ i]);
					charPtrArrayScale2[ i] = 0L;
				}
				[imageArrayScale2 release];
				imageArrayScale2 = nil;
			}
		break;
		
		case 1:
			if( imageArrayPreview)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					if( charPtrArrayPreview[ i]) free( charPtrArrayPreview[ i]);
					charPtrArrayPreview[ i] = 0L;
				}
				[imageArrayPreview release];
				imageArrayPreview = nil;
			}
            if( imageArrayPreviewScale2)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					if( charPtrArrayPreviewScale2[ i]) free( charPtrArrayPreviewScale2[ i]);
					charPtrArrayPreviewScale2[ i] = 0L;
				}
				[imageArrayPreviewScale2 release];
				imageArrayPreviewScale2 = nil;
			}
		break;
		
		case 2:
			if( imageArrayROI)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					if( charPtrArrayROI[ i]) free( charPtrArrayROI[ i]);
					charPtrArrayROI[ i] = 0L;
				}
				[imageArrayROI release];
				imageArrayROI = nil;
			}
            if( imageArrayROIScale2)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					if( charPtrArrayROIScale2[ i]) free( charPtrArrayROIScale2[ i]);
					charPtrArrayROIScale2[ i] = 0L;
				}
				[imageArrayROIScale2 release];
				imageArrayROIScale2 = nil;
			}
		break;
	}
}

+ (void) initFontImage:(unichar)first count:(int)count font:(NSFont*) font fontType:(int) fontType scaling: (float) scaling
{
	NSColor				*blackColor;
	NSDictionary		*attribDict;
	NSString			*currentChar;
	unichar				currentUnichar;
	NSSize				charSize;
	NSRect				charRect;
	NSImage				*theImage;
	BOOL				retval;
	NSBitmapImageRep	*bitmap;
	NSMutableArray		*curArray;
	long				*curSizeArray, i;
	
	if( fontOpenGLInitialized == NO)
	{
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayPreview[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArray[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayROI[ i] = 0;
        
        for( i = 0; i < MAXCOUNT; i++) charPtrArrayPreviewScale2[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayScale2[ i] = 0;
		for( i = 0; i < MAXCOUNT; i++) charPtrArrayROIScale2[ i] = 0;
		
		fontOpenGLInitialized = YES;
	}
	
    if( scaling != 1.0 && scaling != 2.0)
    {
        NSLog( @"******* ******* ******* ******* ******* *******");
        NSLog( @"******* UNKNOW scaling factor: %f", scaling);
        NSLog( @"******* ******* ******* ******* ******* *******");
        scaling = [[NSScreen mainScreen] backingScaleFactor];
    }
    
    unsigned char **curPtrArray = nil;
    
    if( scaling == 2.0)
    {
        switch( fontType)
        {
            case 1:
                curArray = imageArrayPreviewScale2;
                curSizeArray = charSizeArrayPreviewScale2;
                curPtrArray = charPtrArrayPreviewScale2;
                break;
                
            case 0:
                curArray = imageArrayScale2;
                curSizeArray = charSizeArrayScale2;
                curPtrArray = charPtrArrayScale2;
                break;
                
            case 2:
                curArray = imageArrayROIScale2;
                curSizeArray = charSizeArrayROIScale2;
                curPtrArray = charPtrArrayROIScale2;
                break;
        }
    }
    else
    {
        switch( fontType)
        {
            case 1:
                curArray = imageArrayPreview;
                curSizeArray = charSizeArrayPreview;
                curPtrArray = charPtrArrayPreview;
            break;
            
            case 0:
                curArray = imageArray;
                curSizeArray = charSizeArray;
                curPtrArray = charPtrArray;
            break;
            
            case 2:
                curArray = imageArrayROI;
                curSizeArray = charSizeArrayROI;
                curPtrArray = charPtrArrayROI;
            break;
        }
    }
    
    for( i = 0; i < MAXCOUNT; i++)
    {
        if( curPtrArray[ i]) free( curPtrArray[ i]);
        curPtrArray[ i] = 0;
    }
	
	if( curArray == nil) curArray = [[NSMutableArray alloc] initWithCapacity:0];
	else [curArray removeAllObjects];
    
    blackColor = [ NSColor blackColor ];
	attribDict = [ NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, [ NSColor whiteColor ], NSForegroundColorAttributeName, blackColor, NSBackgroundColorAttributeName, nil ];
	charRect.origin.x = charRect.origin.y = 0;
	retval = TRUE;
	for( currentUnichar = first; currentUnichar < first + count; currentUnichar++ )
	{
		@try
		{
			currentChar = [NSString stringWithCharacters:&currentUnichar length:1];
			charSize = [currentChar sizeWithAttributes: attribDict];
			charRect.size = charSize;
            
			charRect = NSIntegralRect( charRect);
			if( charRect.size.width <= 0 && charRect.size.height <= 0 ) // character with no glyph in the current font
			{
				currentChar = @"?";
				charSize = [currentChar sizeWithAttributes: attribDict];
                
				charRect.size = charSize;
				charRect = NSIntegralRect( charRect );
			}	
			theImage = [[NSImage alloc] initWithSize:NSMakeSize( 0, 0)];
            
			[theImage setSize: charRect.size];
			
			if([theImage size].width > 0 && [theImage size].height > 0)
			{
				[theImage lockFocus];
                
                if( scaling == 1) // On Retina system, this will cancel the default 2x resolution in the NSImage "world"
                    [[NSAffineTransform transform] set];
                
				[blackColor set];
				[NSBezierPath fillRect:charRect];
				[[NSGraphicsContext currentContext] setShouldAntialias: NO];
				[currentChar drawInRect:charRect withAttributes:attribDict];
				[theImage unlockFocus];
			}
			
			bitmap = [NSBitmapImageRep imageRepWithData:[theImage TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:0]];
			
			if( bitmap)
			{
                if( scaling == 1 && bitmap.pixelsWide / charRect.size.width == 2) //We dont want a Retina image, on a Retina OS...
                    curSizeArray[currentUnichar] = bitmap.pixelsWide/2;
                else
                    curSizeArray[currentUnichar] = bitmap.pixelsWide;
                
				[curArray addObject: bitmap];
				[theImage release];
				
				curPtrArray[ currentUnichar] = [NSFont createCharacterWithImage:[curArray objectAtIndex: currentUnichar - first]];
			}
		}
		@catch (NSException * e)
		{
            N2LogExceptionWithStackTrace(e);
		}
	}
    
    if( scaling == 2.0)
    {
        switch( fontType)
        {
            case 1:     imageArrayPreviewScale2 = curArray; break;
            case 0:     imageArrayScale2 = curArray;    break;
            case 2:     imageArrayROIScale2 = curArray; break;
        }
    }
    else
    {
        switch( fontType)
        {
            case 1: imageArrayPreview = curArray;   break;
            case 0: imageArray = curArray;  break;
            case 2: imageArrayROI = curArray;   break;
        }
    }
}

/*
 * Create the set of display lists for the bitmaps
 */
- (BOOL) makeGLDisplayListFirst:(unichar)first count:(int)count base:(GLint)base :(long*) charSizeArrayIn :(int) fontType :(float) scaling
{
	GLint curListIndex;
	GLint dListNum;
	unichar currentUnichar;
	BOOL retval;
	
	NSMutableArray *curArray = nil;
	long *curSizeArray = nil;
	unsigned char **curPtrArray = nil;
    
    if( scaling == 2.0)
    {
        switch( fontType)
        {
            case 0:
                if( imageArrayScale2 == nil)
                    [NSFont initFontImage:' ' count:150 font:self fontType: fontType scaling: scaling];
                
                curArray = imageArrayScale2;
                curSizeArray = charSizeArrayScale2;
                curPtrArray = charPtrArrayScale2;
                break;
                
            case 1:
                if( imageArrayPreviewScale2 == nil)
                    [NSFont initFontImage:' ' count:150 font:self fontType: fontType scaling: scaling];
                
                curArray = imageArrayPreviewScale2;
                curSizeArray = charSizeArrayPreviewScale2;
                curPtrArray = charPtrArrayPreviewScale2;
                break;
                
            case 2:
                if( imageArrayROIScale2 == nil)
                    [NSFont initFontImage:' ' count:150 font:self fontType: fontType scaling: scaling];
                
                curArray = imageArrayROIScale2;
                curSizeArray = charSizeArrayROIScale2;
                curPtrArray = charPtrArrayROIScale2;
                break;
        }
    }
    else
    {
        switch( fontType)
        {
            case 0:
                if( imageArray == nil)
                    [NSFont initFontImage:' ' count:150 font:self fontType: fontType scaling: scaling];
                
                curArray = imageArray;
                curSizeArray = charSizeArray;
                curPtrArray = charPtrArray;
            break;
            
            case 1:
                if( imageArrayPreview == nil)
                    [NSFont initFontImage:' ' count:150 font:self fontType: fontType scaling: scaling];
                
                curArray = imageArrayPreview;
                curSizeArray = charSizeArrayPreview;
                curPtrArray = charPtrArrayPreview;
            break;
            
            case 2:
                if( imageArrayROI == nil)
                    [NSFont initFontImage:' ' count:150 font:self fontType: fontType scaling: scaling];
                    
                curArray = imageArrayROI;
                curSizeArray = charSizeArrayROI;
                curPtrArray = charPtrArrayROI;
            break;
        }
	}
    
   // Make sure a list isn't already under construction
   glGetIntegerv( GL_LIST_INDEX, &curListIndex );
   if( curListIndex != 0 )
   {
      [ NSFont doOpenGLLog:@"Display list already under construction" ];
      return FALSE;
   }

   // Save pixel unpacking state
   glPushClientAttrib( GL_CLIENT_PIXEL_STORE_BIT );

   glPixelStorei( GL_UNPACK_SWAP_BYTES, GL_FALSE );
   glPixelStorei( GL_UNPACK_LSB_FIRST, GL_FALSE );
   glPixelStorei( GL_UNPACK_SKIP_ROWS, 0 );
   glPixelStorei( GL_UNPACK_SKIP_PIXELS, 0 );
   glPixelStorei( GL_UNPACK_ROW_LENGTH, 0 );
   glPixelStorei( GL_UNPACK_ALIGNMENT, 1 );
	
   glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
   glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
   
   retval = TRUE;
   for( dListNum = base, currentUnichar = first; currentUnichar < first + count;
        dListNum++, currentUnichar++ )
   {
	   charSizeArrayIn[ currentUnichar] = curSizeArray[ currentUnichar];
		
	   if( currentUnichar - first < curArray.count)
		{
			NSBitmapImageRep *bitmap = [curArray objectAtIndex: currentUnichar - first];
			
            if( bitmap)
            {
                glNewList( dListNum, GL_COMPILE);
                
                if( curPtrArray[ currentUnichar])
                    glBitmap( [bitmap pixelsWide], [bitmap pixelsHigh], 0, 0, curSizeArray[currentUnichar], 0, curPtrArray[ currentUnichar]);
                
                glEndList();
            }
		}
   }

   glPopClientAttrib();

   return retval;
}


/*
 * Create one display list based on the given image.  This assumes the image
 * uses 8-bit chunks to represent a sample
 */
+ (unsigned char*) createCharacterWithImage:(NSBitmapImageRep *)bitmap
{
   int				bytesPerRow, pixelsHigh, pixelsWide, samplesPerPixel;
   unsigned char	*bitmapBytes;
   int				currentBit, byteValue;
   unsigned char	*newBuffer, *movingBuffer;
   int				rowIndex, colIndex;

   pixelsHigh = [bitmap pixelsHigh];
   pixelsWide = [bitmap pixelsWide];
   bitmapBytes = [bitmap bitmapData];
   bytesPerRow = [bitmap bytesPerRow];
   samplesPerPixel = [bitmap samplesPerPixel];
   
   newBuffer = calloc( ceil( (float) bytesPerRow / 8.0 ), pixelsHigh);
   if( newBuffer == NULL )
   {
		NSLog(@"Failed to calloc() memory in");
		return nil;
   }

   movingBuffer = newBuffer;
   /*
    * Convert the color bitmap into a true bitmap, ie, one bit per pixel.  We
    * read at last row, write to first row as Cocoa and OpenGL have opposite
    * y origins
    */
   for( rowIndex = pixelsHigh - 1; rowIndex >= 0; rowIndex --)
   {
      currentBit = 0x80;
      byteValue = 0;
      for( colIndex = 0; colIndex < pixelsWide; colIndex ++)
      {
         if( bitmapBytes[ rowIndex * bytesPerRow + colIndex * samplesPerPixel]) byteValue |= currentBit;
         currentBit >>= 1;
         if( currentBit == 0)
         {
            *movingBuffer++ = byteValue;
            currentBit = 0x80;
            byteValue = 0;
         }
      }
      if( currentBit != 0x80)
         *movingBuffer++ = byteValue;
   }
	
	return newBuffer;
}


/*
 * Log the warning/error, if logging is enabled
 */
+ (void) doOpenGLLog:(NSString *)format, ...
{
   va_list args;

   if( openGLLoggingEnabled )
   {
      va_start( args, format );
      NSLogv( [ NSString stringWithFormat:@"NSFont_OpenGL: %@\n", format ],
              args );
      va_end( args );
   }
}

@end
