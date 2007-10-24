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




#import <Foundation/Foundation.h>
#import "MyPoint.h"

#import <OpenGL/CGLMacro.h>

enum
{
	ROI_sleep = 0,
	ROI_drawing = 1,
	ROI_selected = 2,
	ROI_selectedModify = 3
};

@class DCMView;
@class DCMPix;
@class StringTexture;
@class DCMObject;

/** \brief ROI */

@interface ROI : NSObject <NSCoding>
{
	NSLock			*roiLock;
	
	int				textureWidth, textureHeight;

	unsigned char*	textureBuffer;
	
	NSMutableArray *ctxArray;	//All contexts where this texture is used
	NSMutableArray *textArray;	//All texture id

	int				textureUpLeftCornerX,textureUpLeftCornerY,textureDownRightCornerX,textureDownRightCornerY;
	int				textureFirstPoint;
	
	NSMutableArray  *points;
	NSMutableArray  *zPositions;
	NSRect			rect;
	
	long			type;
	long			mode;
	BOOL			needQuartz;
	
	float			thickness;
	
	BOOL			fill;
	float			opacity;
	RGBColor		color;
	
	BOOL			closed,clickInTextBox;
	
	NSString		*name;
	NSString		*comments;
	
	float			pixelSpacingX, pixelSpacingY;
	NSPoint			imageOrigin;
	
	// **** **** **** **** **** **** **** **** **** **** TRACKING
	
	long			selectedModifyPoint;
	NSPoint			clickPoint, previousPoint, originAnchor;
	long			fontListGL, *fontSize;
	
	DCMView			*curView;
	DCMPix			*pix;
	
	float			rmean, rmax, rmin, rdev, rtotal;
	float			Brmean, Brmax, Brmin, Brdev, Brtotal;
	
	float			mousePosMeasure;
	
	StringTexture			*stringTex;
	NSMutableDictionary		*stanStringAttrib;
	
	ROI*			parentROI;
	
	NSRect			drawRect;
	
	float			offsetTextBox_x, offsetTextBox_y;
	
	char			line1[ 256], line2[ 256], line3[ 256], line4[ 256], line5[ 256];
	NSString		*textualBoxLine1, *textualBoxLine2, *textualBoxLine3, *textualBoxLine4, *textualBoxLine5;
	
	BOOL			_displayCalciumScoring;
	int				_calciumThreshold;
	double			_sliceThickness;
	int				_calciumCofactor;
	
	NSString		*layerReferenceFilePath;
	NSImage			*layerImage;//, *layerImageWhenSelected;
	NSData			*layerImageJPEG;//, *layerImageWhenSelectedJPEG;
	float			layerPixelSpacingX, layerPixelSpacingY;
	BOOL			isLayerOpacityConstant;
	BOOL			canColorizeLayer, canResizeLayer;
	NSColor			*layerColor;
	
	NSNumber		*uniqueID;		// <- not saved, only valid during the 'life' of a ROI
	NSTimeInterval	groupID;		// timestamp of a ROI group. Grouped ROI will be selected/deleted together.
	
	BOOL			displayTextualData;
}

@property(readonly) int textureWidth, textureHeight;
@property(readonly) int textureDownRightCornerX,textureDownRightCornerY, textureUpLeftCornerX, textureUpLeftCornerY;
@property(readonly) unsigned char *textureBuffer;
@property float opacity;
@property(retain) NSString *name, *comments;
@property(readonly) long type;
@property(setter=setROIMode:) long ROImode;
@property(retain) NSMutableArray *points; // Return/set the points state of the ROI
@property(readonly) NSMutableArray *zPositions;
@property(readonly) BOOL clickInTextBox;
@property(setter=setROIRect:) NSRect rect; // To create a Rectangular ROI (tROI) or an Oval ROI (tOval)
@property(retain) DCMPix *pix; // The DCMPix associated to this ROI
@property(readonly) DCMView *curView;  // The DCMView associated to this ROI
@property float mousePosMeasure;
@property(readonly) NSData *data;
@property(setter=setColor:) RGBColor rgbcolor;
@property float thickness;
@property(retain) ROI *parentROI;
@property double sliceThickness;

// Set/retrieve default ROI name (if not set, then default name is the currentTool)
+ (void) setDefaultName:(NSString*) n;
+ (NSString*) defaultName;
@property(retain) NSString *defaultName;

+(void) loadDefaultSettings;
+(void) saveDefaultSettings;

// Create a new ROI, needs the current pixel resolution and image origin
- (id) initWithType: (long) itype :(float) ipixelSpacing :(NSPoint) iimageOrigin;
- (id) initWithType: (long) itype :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin;

// arg: specific methods for tPlain roi
- (id) initWithTexture: (unsigned char*)tBuff  textWidth:(int)tWidth textHeight:(int)tHeight textName:(NSString*)tName
			 positionX:(int)posX positionY:(int)posY
			  spacingX:(float) ipixelSpacingx spacingY:(float) ipixelSpacingy imageOrigin:(NSPoint) iimageOrigin;


- (void) setTextBoxOffset:(NSPoint) o;

- (void)displayTexture;

// Set resolution and origin associated to the ROI
- (void) setOriginAndSpacing :(float) ipixelSpacing :(NSPoint) iimageOrigin;
- (void) setOriginAndSpacing :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin;
- (void) setOriginAndSpacing :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin :(BOOL) sendNotification;

// Compute the roiArea in cm2
- (float) roiArea;

// Compute the geometric centroid in pixel space
- (NSPoint) centroid;

// Compute the length for tMeasure ROI in cm
- (float) MesureLength: (float*) pixels;
- (float) Length:(NSPoint) mesureA :(NSPoint) mesureB;

// Compute an angle between 2 lines
- (float) Angle:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3;

- (float*) dataValuesAsFloatPointer :(long*) no;

+ (NSPoint) pointBetweenPoint:(NSPoint) a and:(NSPoint) b ratio: (float) r;
+ (NSMutableArray*) resamplePoints: (NSArray*) points number:(int) no;

- (BOOL)mouseRoiDown:(NSPoint)pt :(int)slice :(float)scale;
- (void) roiMove:(NSPoint) offset;
- (void) roiMove:(NSPoint) offset :(BOOL) sendNotification;
- (BOOL) mouseRoiDown:(NSPoint) pt :(float) scale;
- (BOOL) mouseRoiDragged:(NSPoint) pt :(unsigned int) modifier :(float) scale;
- (NSMutableArray*) dataValues;
- (BOOL) valid;
- (void) drawROI :(float) scaleValue :(float) offsetx :(float) offsety :(float) spacingx :(float) spacingy;
- (BOOL) needQuartz;
- (BOOL) deleteSelectedPoint;
- (NSMutableDictionary*) dataString;
- (BOOL) mouseRoiUp:(NSPoint) pt;
- (void) setRoiFont: (long) f :(long*) s :(DCMView*) v;
- (void) glStr: (unsigned char *) cstrOut :(float) x :(float) y :(float) line;
- (void) recompute;
- (void) rotate: (float) angle :(NSPoint) center;
- (BOOL)canResize;
- (void) resize: (float) factor :(NSPoint) center;
- (BOOL) reduceTextureIfPossible;
- (void) addMarginToBuffer: (int) margin;
- (void) drawTextualData;
- (long) clickInROI:(NSPoint) pt :(float) offsetx :(float) offsety :(float) scale :(BOOL) testDrawRect;
- (NSPoint) ProjectionPointLine: (NSPoint) Point :(NSPoint) startPoint :(NSPoint) endPoint;
- (void) deleteTexture:(NSOpenGLContext*) c;

- (void)setCanResizeLayer:(BOOL)boo;


// Calcium Scoring

- (int)calciumScoreCofactor;
- (float)calciumScore;
- (float)calciumVolume;
- (float)calciumMass;

@property BOOL displayCalciumScoring;
@property int calciumThreshold;

@property(retain) NSString *layerReferenceFilePath;
@property(retain) NSImage *layerImage;
@property float layerPixelSpacingX, layerPixelSpacingY;

- (GLuint)loadLayerImageTexture;
- (void)generateEncodedLayerImage;
- (BOOL)isPoint:(NSPoint)point inRectDefinedByPointA:(NSPoint)pointA pointB:(NSPoint)pointB pointC:(NSPoint)pointC pointD:(NSPoint)pointD;
- (NSPoint)rotatePoint:(NSPoint)point withAngle:(float)alpha aroundCenter:(NSPoint)center;

@property(retain) NSString *textualBoxLine1, *textualBoxLine2, *textualBoxLine3, *textualBoxLine4, *textualBoxLine5;
@property NSTimeInterval groupID;

- (NSPoint) lowerRightPoint;

@property BOOL isLayerOpacityConstant;
@property BOOL canColorizeLayer;
@property BOOL displayTextualData;
@property(readonly) NSPoint clickPoint;

@end
