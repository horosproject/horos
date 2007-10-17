/** /brief Addition to NSFont to allow easy OpenGL display list creation of bitmaps
 * based on the receiver's font.
 *
 * Addition to NSFont to allow easy OpenGL display list creation of bitmaps
 * based on the receiver's font.  Example usage:
 *
 * [ myFont makeGLDisplayListFirst:' ' count:95 base:displayListBase ];
 *
 * This creates a set of display lists, starting at displayListBase, with 95
 * characters starting with the space.  Returns TRUE if all went well,
 * FALSE otherwise.
 *
 * By default, if any errors are encountered, NSLog() will be used to note
 * what happened; use
 *
 * [ NSFont setOpenGLLogging:NO ];
 *
 * to disable logging.
 *
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
 */

/* NSFont_OpenGL.h */

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

@interface NSFont (withay_OpenGL)

+ (void) setOpenGLLogging:(BOOL)logEnabled;
+ (void) resetFont: (BOOL) preview;
+ (void) initFontImage:(unichar)first count:(int)count font:(NSFont*) font previewFont:(BOOL) preview;
- (BOOL) makeGLDisplayListFirst:(unichar)first count:(int)count base:(GLint)base :(long*) charSizeArrayIn :(BOOL) preview;
+ (unsigned char*) createCharacterWithImage:(NSBitmapImageRep *)bitmap;
@end
