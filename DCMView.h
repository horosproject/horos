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




#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>


#define STAT_UPDATE					0.6f
#define IMAGE_COUNT					1
#define IMAGE_DEPTH					32


// Tools.

enum
{
    tWL							=	0,
    tTranslate,					//	1
    tZoom,						//	2
    tRotate,					//	3
    tNext,						//	4
    tMesure,					//	5
    tROI,						//	6
	t3DRotate,					//	7
	tCross,						//	8
	tOval,						//	9
	tOPolygon,					//	10
	tCPolygon,					//	11
	tAngle ,					//	12
	tText,						//	13
	tArrow,						//	14
	tPencil,					//	15
	t3Dpoint,					//	16
	t3DCut,						//	17
	tCamera3D,					//	18
	t2DPoint,					//	19
	tPlain,						//	20
	tBonesRemoval				//	21
};


enum { annotNone = 0, annotGraphics, annotBase, annotFull };
enum { barHide = 0, barOrigin, barFused, barBoth };



@class DCMPix;
@class DCMView;
@class ROI;
@class OrthogonalMPRController;

@interface DCMView: NSOpenGLView
{
	int				_imageRows;
	int				_imageColumns;
	int				_tag;

	BOOL			flippedData;
	
	NSString		*yearOld;
	
	ROI				*curROI;
	BOOL			drawingROI, noScale, volumicSeries;
	DCMView			*blendingView;
	float			blendingFactor, blendingFactorStart;
	BOOL			eraserFlag; // use by the PaletteController to switch between the Brush and the Eraser
	BOOL			colorTransfer;
	unsigned char   *colorBuf, *blendingColorBuf;
	unsigned char   alphaTable[256], redTable[256], greenTable[256], blueTable[256];
	float			redFactor, greenFactor, blueFactor;
	long			blendingMode;
	float			sliceVector[ 3], slicePoint[ 3], slicePointO[ 3], slicePointI[ 3];
	float			sliceVector2[ 3], slicePoint2[ 3], slicePointO2[ 3], slicePointI2[ 3];
	float			slicePoint3D[ 3];
	float			syncRelativeDiff;
	long			syncSeriesIndex;
	
	float			mprVector[ 3], mprPoint[ 3];
	
	short			thickSlabMode, thickSlabStacks;
	
    NSImage         *myImage;
	
	NSMutableArray	*rectArray;
	
    NSMutableArray  *dcmPixList;
    NSArray			*dcmFilesList;
	NSMutableArray  *dcmRoiList, *curRoiList;
    DCMPix			*curDCM;
	
    NSTimer			*mouseModifiers;
	
    char            listType;
    
    short           curImage, startImage;
    
    short           currentTool, currentToolRight;
    
	BOOL			suppress_labels; // keep from drawing the labels when command+shift is pressed

	NSString		*shortDateString;
	NSDictionary	*localeDictionnary;

    NSPoint         start, originStart, originOffsetStart, previous;
	
    float			startWW, curWW, startMin, startMax;
    float			startWL, curWL;
	
    NSSize          scaleStart, scaleInit;
    
	BOOL			convolution;
	short			kernelsize, normalization;
	short			kernel[ 25];
	
    float           scaleValue, startScaleValue;
    float           rotation, rotationStart;
    NSPoint			origin, originOffset;
	NSPoint			cross, crossPrev;
	float			angle, slab, switchAngle;
	short			crossMove;
    
    NSMatrix        *matrix;
    
    long            count;
	
    BOOL            QuartzExtreme;
	
    BOOL            xFlipped, yFlipped;

	long			fontListGLSize[256];
	long			labelFontListGLSize[ 256];
	NSSize			stringSize;
	NSFont			*labelFont;
	NSFont			*fontGL;
	NSColor			*fontColor;
    GLuint          fontListGL;
	GLuint          labelFontListGL;
    
    NSPoint         mesureA, mesureB;
    NSRect          roiRect;
	NSString		*stringID;
	NSSize			previousViewSize;
	
	float			mouseXPos, mouseYPos;
	float			pixelMouseValue;
	long			pixelMouseValueR, pixelMouseValueG, pixelMouseValueB;
    
	float			blendingMouseXPos, blendingMouseYPos;
	float			blendingPixelMouseValue;
	long			blendingPixelMouseValueR, blendingPixelMouseValueG, blendingPixelMouseValueB;
	
    long			textureX, blendingTextureX; // number of horizontal textures
    long			textureY, blendingTextureY; // number of vertical textures
    GLuint			* pTextureName; // array for texture names (# = textureX * textureY)
	GLuint			* blendingTextureName; // array for texture names (# = textureX * textureY)
    long			textureWidth; // total width of texels with cover image (including any border on image, but not internal texture overlaps)
    long			textureHeight; // total height of texels with cover image (including any border on image, but not internal texture overlaps)
    
	BOOL			f_ext_texture_rectangle; // is texture rectangle extension supported
	BOOL			f_arb_texture_rectangle; // is texture rectangle extension supported
	BOOL			f_ext_client_storage; // is client storage extension supported
	BOOL			f_ext_packed_pixel; // is packed pixel extension supported
	BOOL			f_ext_texture_edge_clamp; // is SGI texture edge clamp extension supported
	BOOL			f_gl_texture_edge_clamp; // is OpenGL texture edge clamp support (1.2+)
	unsigned long	edgeClampParam; // the param that is passed to the texturing parmeteres
	long			maxTextureSize; // the minimum max texture size across all GPUs
	long			maxNOPTDTextureSize; // the minimum max texture size across all GPUs that support non-power of two texture dimensions
	long			TEXTRECTMODE;
	
	BOOL			isKeyView; //needed for Image View subclass
	NSCursor		*cursor;
	BOOL			cursorSet;
	NSPoint			display2DPoint;
	
	NSMutableDictionary	*stringTextureCache;
	
	BOOL           _dragInProgress; // Are we drag and dropping
	NSTimer			*_mouseDownTimer; //Timer to check if mouseDown is Persisiting;
	NSImage			*destinationImage; //image will be dropping
}
+ (void)setPluginOverridesMouse: (BOOL)override;
+ (void) computePETBlendingCLUT;
- (void) applyImageTransformation;
- (void) initFont;
- (NSMutableArray*) rectArray;
-(BOOL) flippedData;
-(void) setFlippedData:(BOOL) f;
 -(NSMutableArray*) dcmPixList;
 -(NSMutableArray*) dcmRoiList;
- (long) indexForPix: (long) pixIndex; // Return the index into fileList that coresponds to the index in pixList
- (long) syncSeriesIndex;
- (void) setSyncSeriesIndex:(long) i;
- (float) syncRelativeDiff;
- (void) setSyncRelativeDiff: (float) v;
- (long) findPlaneAndPoint:(float*) pt :(float*) location;
- (unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits;
- (unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical;
- (void) setCrossPrev:(NSPoint) c;
-(NSPoint) cross;
-(NSPoint) crossPrev;
-(void) setSlab:(float) s;
-(void) blendingPropagate;
-(void) subtract:(DCMView*) bV;
-(void) multiply:(DCMView*) bV;
-(void) setBlendingMode:(long) f;
- (GLuint *) loadTextureIn:(GLuint *) texture blending:(BOOL) blending colorBuf: (unsigned char**) colorBufPtr textureX:(long*) tX textureY:(long*) tY redTable:(unsigned char*) rT greenTable:(unsigned char*) gT blueTable:(unsigned char*) bT;
/*			DCMView proxy not necesary between ViewerController and DCMPix
- (void) setSubtraction:(long) imID;
- (NSPoint) subOffset;
- (void) setSubOffset:(NSPoint) subCtrlOffset;
*/
- (BOOL)xFlipped;
- (void)setXFlipped: (BOOL)v;
- (BOOL)yFlipped;
- (void)setYFlipped:(BOOL) v;
- (BOOL) roiTool:(long) tool;
- (void) sliderAction2DMPR:(id) sender;
- (void) setStringID:(NSString*) str;
-(NSString*) stringID;
- (float) angle;
- (void) setCrossCoordinatesPer:(float) val;
- (void) setCrossCoordinates:(float) x :(float) y :(BOOL) update;
- (void) setCross:(long) x :(long)y :(BOOL) update;
- (void) setMPRAngle: (float) vectorMPR;
- (NSPoint) ConvertFromView2GL:(NSPoint) a;
- (NSPoint) ConvertFromGL2View:(NSPoint) a;
- (void) cross3D:(float*) x :(float*) y :(float*) z;

- (void) setWLWW:(float) wl :(float) ww;
- (void)discretelySetWLWW:(float)wl :(float)ww;
- (void) getWLWW:(float*) wl :(float*) ww;

- (void) setConv:(short*) matrix :(short) size :(short) norm;
- (void) setCLUT:( unsigned char*) r :(unsigned char*) g :(unsigned char*) b;
- (void) setCurrentTool:(short)i;
- (short) currentTool;
- (short) currentToolRight;
- (void) setRightTool:(short) i;
- (void) dealloc;
- (NSImage*) nsimage:(BOOL) originalSize;
- (void) setTheMatrix:(NSMatrix*)m;
- (void) setIndex:(short) index;
- (void) setIndexWithReset:(short) index :(BOOL)sizeToFit;
- (void) setDCM:(NSMutableArray*) c :(NSArray*)d :(NSMutableArray*)e :(short) firstImage :(char) type :(BOOL) reset;
- (short) curImage;
- (BOOL) suppressLabels;
- (void) sendSyncMessage:(short) inc;
- (void) setQuartzExtreme:(BOOL) set;
- (void) loadTextures;
- (void) flipVertical:(id) sender;
- (void) flipHorizontal:(id) sender;
- (void) setFusion:(short) mode :(short) stacks;
- (void) FindMinimumOpenGLCapabilities;
- (float) scaleValue;
- (void) setScaleValue:(float) x;
- (float) rotation;
- (void) setRotation:(float) x;
-(NSPoint) rotatePoint:(NSPoint) a;
- (NSPoint) origin;
- (NSPoint) originOffset;
- (void) setOrigin:(NSPoint) x;
- (void) setOriginOffset:(NSPoint) x;
- (void) setBlending:(DCMView*) bV;
- (float) pixelSpacing;
- (float) pixelSpacingX;
- (float) pixelSpacingY;
- (void) scaleToFit;
- (void) setBlendingFactor:(float) f;
- (void) sliderAction:(id) sender;
- (DCMPix*)curDCM;
- (void) roiSet;
-(void) roiSet:(ROI*) aRoi;
- (void) colorTables:(unsigned char **) a :(unsigned char **) r :(unsigned char **)g :(unsigned char **) b;
- (void) blendingColorTables:(unsigned char **) a :(unsigned char **) r :(unsigned char **)g :(unsigned char **) b;
- (void )changeFont:(id)sender;
- (NSSize)sizeOfString:(NSString *)string forFont:(NSFont *)font;
- (long) lengthOfString:( char *) cstr forFont:(long *)fontSizeArray;
- (void) getCrossCoordinates:(float*) x: (float*) y;
- (IBAction) sliderRGBFactor:(id) sender;
- (IBAction) alwaysSyncMenu:(id) sender;
- (void) getCLUT:( unsigned char**) r : (unsigned char**) g : (unsigned char**) b;
- (void) doSyncronize:(NSNotification*)note;
- (BOOL) volumicSeries;
- (id)initWithFrame:(NSRect)frame imageRows:(int)rows  imageColumns:(int)columns;
- (float)getSUV;
- (IBAction) roiLoadFromXMLFiles: (id) sender;
- (float)mouseXPos;
- (float)mouseYPos;
- (GLuint)fontListGL;
- (void) drawRectIn:(NSRect) size :(GLuint *) texture :(NSPoint) offset :(long) tX :(long) tY;
- (void) DrawNSStringGL: (NSString*) cstrOut :(GLuint) fontL :(long) x :(long) y;
- (void) DrawNSStringGL: (NSString*) str :(GLuint) fontL :(long) x :(long) y rightAlignment: (BOOL) right useStringTexture: (BOOL) stringTex;
- (void) DrawCStringGL: ( char *) cstrOut :(GLuint) fontL :(long) x :(long) y;
- (void) DrawCStringGL: ( char *) cstrOut :(GLuint) fontL :(long) x :(long) y rightAlignment: (BOOL) right useStringTexture: (BOOL) stringTex;
- (void) drawTextualData:(NSRect) size :(long) annotations;
- (void) draw2DPointMarker;
- (void) setSyncro:(long) s;
- (long) syncro;
- (NSFont*)fontGL;
- (void) setScaleValueCentered:(float) x;
//notifications
-(void) updateCurrentImage: (NSNotification*) note;
-(void)updateImageTiling:(NSNotification *)note;
-(void)setImageParamatersFromView:(DCMView *)aView;
-(void) setRows:(int)rows columns:(int)columns;
-(void)setTag:( long)aTag;
-( long)tag;
-(float)curWW;
-(float)curWL;
-(float)scaleValue;
-(NSPoint)origin;
- (int)rows;
- (int)columns;
-(DCMView *)blendingView;
- (float)blendingFactor;
- (float)blendingMode;
- (NSCursor *)cursor;
-(void) becomeMainWindow;
- (BOOL)eraserFlag;
- (void)setEraserFlag: (BOOL)aFlag;
- (NSManagedObject *)imageObj;
- (NSManagedObject *)seriesObj;
- (void)updatePresentationStateFromSeries;
- (IBAction)resetSeriesPresentationState:(id)sender;
- (IBAction)resetImagePresentationState:(id)sender;
- (void) setCursorForView: (long) tool;
- (long) getTool: (NSEvent*) event;
- (void)resizeWindowToScale:(float)resizeScale;
- (float) getBlendedSUV;
- (OrthogonalMPRController*) controller;
-(void) roiChange:(NSNotification*)note;
-(void) roiSelected:(NSNotification*) note;
- (void) setStartWLWW;
- (void) stopROIEditing;
- (void)subDrawRect: (NSRect)aRect;  // Subclassable, default does nothing.

// methodes to access global variables (for plugins)
+ (BOOL) display2DMPRLines;
+ (unsigned char*) PETredTable;
+ (unsigned char*) PETgreenTable;
+ (unsigned char*) PETblueTable;

//Timer method to start drag
- (void) startDrag:(NSTimer*)theTimer;
- (void)deleteMouseDownTimer;
- (id)dicomImage;
@end
