#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

@interface NSFont (withay_OpenGL)

+ (void) setOpenGLLogging:(BOOL)logEnabled;
+ (void) resetFont: (int) preview;
+ (void) initFontImage:(unichar)first count:(int)count font:(NSFont*) font fontType:(int) preview  scaling: (float) scaling;
- (BOOL) makeGLDisplayListFirst:(unichar)first count:(int)count base:(GLint)base :(long*) charSizeArrayIn :(int) fontType : (float) scaling;
+ (unsigned char*) createCharacterWithImage:(NSBitmapImageRep *)bitmap;
@end
