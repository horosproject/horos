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
#include <GLUT/glut.h>

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

@interface ROI : NSObject <NSCoding>
{
	int				textureWidth, textureHeight;

	unsigned char*	textureBuffer;
	GLuint			textureName, textureName2;
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
	float			_sliceThickness;
	int				_calciumCofactor;
	
	NSString		*layerReferenceFilePath;
	NSImage			*layerImage;//, *layerImageWhenSelected;
	NSData			*layerImageJPEG;//, *layerImageWhenSelectedJPEG;
	float			layerPixelSpacingX, layerPixelSpacingY;
	BOOL			needsLoadTexture, needsLoadTexture2;
	BOOL			isLayerOpacityConstant;
	BOOL			canColorizeLayer;
	NSColor			*layerColor;
	
	NSNumber		*uniqueID;		// <- not saved, only valid during the 'life' of a ROI
	NSTimeInterval	groupID;		// timestamp of a ROI group. Grouped ROI will be selected/deleted together.
	
	BOOL			displayTextualData;
}

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
- (BOOL) clickInTextBox;

- (int)textureDownRightCornerX;
- (int)textureDownRightCornerY;
- (int)textureUpLeftCornerX;
- (int)textureUpLeftCornerY;

- (int)textureWidth;
- (int)textureHeight;
- (unsigned char*)	textureBuffer;
- (void)displayTexture;
- (float) opacity;
- (void) setOpacity:(float)newOpacity;
- (NSString*) name;
- (void) setName:(NSString*) a;

// Return/Set the comments of the ROI
- (NSString*) comments;
- (void) setComments:(NSString*) a;

// Return the type of the ROI
- (long) type;

// Return the current state of the ROI
- (long) ROImode;

// Return/set the points state of the ROI
- (NSMutableArray*) points;
- (void) setPoints:(NSArray*) points;
- (NSMutableArray*) zPositions;

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

// To create a Rectangular ROI (tROI) or an Oval ROI (tOval)
- (void) setROIRect:(NSRect) rect;
- (NSRect) rect;

- (float*) dataValuesAsFloatPointer :(long*) no;

// Return the DCMPix associated to this ROI
- (DCMPix*) pix;

// Return the DCMView associated to this ROI
- (DCMView*) curView;

+ (NSPoint) pointBetweenPoint:(NSPoint) a and:(NSPoint) b ratio: (float) r;
+ (NSMutableArray*) resamplePoints: (NSArray*) points number:(int) no;

// Set/retrieve default ROI name (if not set, then default name is the currentTool)
+ (void) setDefaultName:(NSString*) n;
+ (NSString*) defaultName;
- (void) setDefaultName:(NSString*) n;
- (NSString*) defaultName;

- (BOOL)mouseRoiDown:(NSPoint)pt :(int)slice :(float)scale;
- (void) setMousePosMeasure:(float) p;
- (NSData*) data;
- (void) roiMove:(NSPoint) offset;
- (void) roiMove:(NSPoint) offset :(BOOL) sendNotification;
- (BOOL) mouseRoiDown:(NSPoint) pt :(float) scale;
- (BOOL) mouseRoiDragged:(NSPoint) pt :(unsigned int) modifier :(float) scale;
- (NSMutableArray*) dataValues;
- (BOOL) valid;
- (void) drawROI :(float) scaleValue :(float) offsetx :(float) offsety :(float) spacingx :(float) spacingy;
- (BOOL) needQuartz;
- (void) setROIMode :(long) v;
- (BOOL) deleteSelectedPoint;
- (RGBColor) rgbcolor;
- (void) setColor:(RGBColor) a;
- (float) thickness;
- (void) setThickness:(float) a;
- (NSMutableDictionary*) dataString;
- (BOOL) mouseRoiUp:(NSPoint) pt;
- (void) setRoiFont: (long) f :(long*) s :(DCMView*) v;
- (void) glStr: (unsigned char *) cstrOut :(float) x :(float) y :(float) line;
- (void) recompute;
- (void) rotate: (float) angle :(NSPoint) center;
- (BOOL)canResize;
- (void) resize: (float) factor :(NSPoint) center;
- (void) setPix: (DCMPix*) newPix;
- (DCMPix*) pix;
- (BOOL) reduceTextureIfPossible;
- (void) addMarginToBuffer: (int) margin;
- (void) drawTextualData;
- (long) clickInROI:(NSPoint) pt :(float) offsetx :(float) offsety :(float) scale :(BOOL) testDrawRect;
- (NSPoint) ProjectionPointLine: (NSPoint) Point :(NSPoint) startPoint :(NSPoint) endPoint;
// parent ROI
- (ROI*) parentROI;
- (void) setParentROI: (ROI*) aROI;

// Calcium Scoring

- (int)calciumScoreCofactor;
- (float)calciumScore;
- (float)calciumVolume;
- (float)calciumMass;
- (void)setDisplayCalciumScoring:(BOOL)value;
- (void)setCalciumThreshold:(int)threshold;

- (float) sliceThickness;
- (void) setSliceThickness:(float)sliceThickness;

- (void)setLayerReferenceFilePath:(NSString*)path;
- (NSString*)layerReferenceFilePath;
- (void)setLayerImage:(NSImage*)image;
//- (void)setLayerImageWhenSelected:(NSImage*)image;
- (void)loadLayerImageTexture;
//- (void)loadLayerImageWhenSelectedTexture;
- (void)generateEncodedLayerImage;
- (void)setLayerPixelSpacingX:(float)x;
- (void)setLayerPixelSpacingY:(float)y;
- (BOOL)isPoint:(NSPoint)point inRectDefinedByPointA:(NSPoint)pointA pointB:(NSPoint)pointB pointC:(NSPoint)pointC pointD:(NSPoint)pointD;
- (NSPoint)rotatePoint:(NSPoint)point withAngle:(float)alpha aroundCenter:(NSPoint)center;

- (void)setTextualBoxLine1:(NSString*)line;
- (void)setTextualBoxLine2:(NSString*)line;
- (void)setTextualBoxLine3:(NSString*)line;
- (void)setTextualBoxLine4:(NSString*)line;
- (void)setTextualBoxLine5:(NSString*)line;

- (NSTimeInterval)groupID;
- (void)setGroupID:(NSTimeInterval)timestamp;

- (NSPoint) lowerRightPoint;

- (void)setIsLayerOpacityConstant:(BOOL)boo;
- (void)setCanColorizeLayer:(BOOL)boo;

- (BOOL)setDisplayTextualData:(BOOL)boo;

- (NSPoint)clickPoint;

@end
