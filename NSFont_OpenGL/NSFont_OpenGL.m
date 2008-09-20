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

#define MAXCOUNT 256

@interface NSFont (withay_OpenGL_InternalMethods)
+ (unsigned char*) createCharacterWithImage:(NSBitmapImageRep *)bitmap;
+ (void) doOpenGLLog:(NSString *)format, ...;
@end

@implementation NSFont (withay_OpenGL)

static  BOOL					openGLLoggingEnabled = YES;
static  NSMutableArray			*imageArray = 0L, *imageArrayPreview = 0L,  *imageArrayROI = 0L;
static  long					charSizeArray[ MAXCOUNT], charSizeArrayPreview[ MAXCOUNT], charSizeArrayROI[ MAXCOUNT];
static  unsigned char			*charPtrArray[ MAXCOUNT], *charPtrArrayPreview[ MAXCOUNT], *charPtrArrayROI[ MAXCOUNT];

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
	
	switch( fontType)
	{
		case 0:
			if( imageArray)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					free( charPtrArray[ i]);
				}
				[imageArray release];
				imageArray = 0L;
			}
		break;
		
		case 1:
			if( imageArrayPreview)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					free( charPtrArrayPreview[ i]);
				}
				[imageArrayPreview release];
				imageArrayPreview = 0L;
			}
		break;
		
		case 2:
			if( imageArrayROI)
			{
				for( i = 0; i < MAXCOUNT; i++)
				{
					free( charPtrArrayROI[ i]);
				}
				[imageArrayROI release];
				imageArrayROI = 0L;
			}
		break;
	}
}

+ (void) initFontImage:(unichar)first count:(int)count font:(NSFont*) font fontType:(int) fontType
{
	GLint				curListIndex;
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

	switch( fontType)
	{
		case 1:
			curArray = imageArrayPreview;
			curSizeArray = charSizeArrayPreview;
			for( i = 0; i < MAXCOUNT; i++) charPtrArrayPreview[ i] = 0;
		break;
		
		case 0:
			curArray = imageArray;
			curSizeArray = charSizeArray;
			for( i = 0; i < MAXCOUNT; i++) charPtrArray[ i] = 0;
		break;
		
		case 2:
			curArray = imageArrayROI;
			curSizeArray = charSizeArrayROI;
			for( i = 0; i < MAXCOUNT; i++) charPtrArrayROI[ i] = 0;
		break;
	}
	
	if( curArray == 0L) curArray = [[NSMutableArray alloc] initWithCapacity:0];
	else [curArray removeAllObjects];

	blackColor = [ NSColor blackColor ];
	attribDict = [ NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, [ NSColor whiteColor ], NSForegroundColorAttributeName, blackColor, NSBackgroundColorAttributeName, nil ];
	charRect.origin.x = charRect.origin.y = 0;
	retval = TRUE;
	for( currentUnichar = first; currentUnichar < first + count; currentUnichar++ )
	{
		currentChar = [ NSString stringWithCharacters:&currentUnichar length:1 ];
		charSize = [ currentChar sizeWithAttributes:attribDict ];
		charRect.size = charSize;
		charRect = NSIntegralRect( charRect );
		if( charRect.size.width <= 0 && charRect.size.height <= 0 ) // character with no glyph in the current font
		{
			currentChar = [ NSString stringWithString:@"?"];
			charSize = [ currentChar sizeWithAttributes:attribDict ];
			charRect.size = charSize;
			charRect = NSIntegralRect( charRect );
		}	
		theImage = [[NSImage alloc ] initWithSize:NSMakeSize( 0, 0 ) ];
		curSizeArray[ currentUnichar] = charRect.size.width;
		[ theImage setSize:charRect.size ];
		[ theImage lockFocus ];
		[ blackColor set ];
		[ NSBezierPath fillRect:charRect ];
		[ [ NSGraphicsContext currentContext ] setShouldAntialias:NO ];
		[ currentChar drawInRect:charRect withAttributes:attribDict ];
		[ theImage unlockFocus ];

		bitmap = [NSBitmapImageRep imageRepWithData:[ theImage TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:0]];

		[curArray addObject: bitmap];
		[theImage release];
			
		switch( fontType)
		{
			case 1:
				charPtrArrayPreview[ currentUnichar] = [NSFont createCharacterWithImage:[curArray objectAtIndex: currentUnichar - first]];
			break;
			
			case 0:
				charPtrArray[ currentUnichar] = [NSFont createCharacterWithImage:[curArray objectAtIndex: currentUnichar - first]];
			break;
			
			case 2:
				charPtrArrayROI[ currentUnichar] = [NSFont createCharacterWithImage:[curArray objectAtIndex: currentUnichar - first]];
			break;
		}
	}

	switch( fontType)
	{
		case 1:
			imageArrayPreview = curArray;
		break;
		
		case 0:
			imageArray = curArray;
		break;
		
		case 2:
			imageArrayROI = curArray;
		break;
	}
}

/*
 * Create the set of display lists for the bitmaps
 */
- (BOOL) makeGLDisplayListFirst:(unichar)first count:(int)count base:(GLint)base :(long*) charSizeArrayIn :(int) fontType
{
	GLint curListIndex;
	NSColor *blackColor;
	NSDictionary *attribDict;
	GLint dListNum;
	NSString *currentChar;
	unichar currentUnichar;
	NSSize charSize;
	NSRect charRect;
	NSImage *theImage;
	BOOL retval;
	NSFont  *fontGL;
	
	NSMutableArray  *curArray;
	long *curSizeArray;
	
	switch( fontType)
	{
		case 0:
			if( imageArray == 0L)
				[NSFont initFontImage:' ' count:150 font:self fontType: fontType];
			
			curArray = imageArray;
			curSizeArray = charSizeArray;
		break;
		
		case 1:
			if( imageArrayPreview == 0L)
				[NSFont initFontImage:' ' count:150 font:self fontType: fontType];
			
			curArray = imageArrayPreview;
			curSizeArray = charSizeArrayPreview;
		break;
		
		case 2:
			if( imageArrayROI == 0L)
				[NSFont initFontImage:' ' count:150 font:self fontType: fontType];
				
			curArray = imageArrayROI;
			curSizeArray = charSizeArrayROI;
		break;
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

   retval = TRUE;
   for( dListNum = base, currentUnichar = first; currentUnichar < first + count;
        dListNum++, currentUnichar++ )
   {
		charSizeArrayIn[ currentUnichar] = curSizeArray[ currentUnichar];
		
		NSBitmapImageRep *bitmap = [curArray objectAtIndex: currentUnichar - first];
		
		glNewList( dListNum, GL_COMPILE );
		
		switch( fontType)
		{
			case 0:
				glBitmap( [bitmap pixelsWide ], [bitmap pixelsHigh], 0, 0, [bitmap  pixelsWide], 0, charPtrArray[ currentUnichar]);
			break;
			
			case 1:
				glBitmap( [bitmap pixelsWide ], [bitmap pixelsHigh], 0, 0, [bitmap  pixelsWide], 0, charPtrArrayPreview[ currentUnichar]);
			break;
			
			case 2:
				glBitmap( [bitmap pixelsWide ], [bitmap pixelsHigh], 0, 0, [bitmap  pixelsWide], 0, charPtrArrayROI[ currentUnichar]);
			break;
		}
		glEndList();
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

   pixelsHigh = [ bitmap pixelsHigh ];
   pixelsWide = [ bitmap pixelsWide ];
   bitmapBytes = [ bitmap bitmapData ];
   bytesPerRow = [ bitmap bytesPerRow ];
   samplesPerPixel = [ bitmap samplesPerPixel ];
   
   newBuffer = calloc( ceil( (float) bytesPerRow / 8.0 ), pixelsHigh );
   if( newBuffer == NULL )
   {
		NSLog(@"Failed to calloc() memory in");
		return 0L;
   }

   movingBuffer = newBuffer;
   /*
    * Convert the color bitmap into a true bitmap, ie, one bit per pixel.  We
    * read at last row, write to first row as Cocoa and OpenGL have opposite
    * y origins
    */
   for( rowIndex = pixelsHigh - 1; rowIndex >= 0; rowIndex-- )
   {
      currentBit = 0x80;
      byteValue = 0;
      for( colIndex = 0; colIndex < pixelsWide; colIndex++ )
      {
         if( bitmapBytes[ rowIndex * bytesPerRow + colIndex * samplesPerPixel ] ) byteValue |= currentBit;
         currentBit >>= 1;
         if( currentBit == 0 )
         {
            *movingBuffer++ = byteValue;
            currentBit = 0x80;
            byteValue = 0;
         }
      }
      if( currentBit != 0x80 )
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
