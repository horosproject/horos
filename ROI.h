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
	GLuint			textureName;
	int				textureUpLeftCornerX,textureUpLeftCornerY,textureDownRightCornerX,textureDownRightCornerY;
	int				textureFirstPoint;
	
	NSMutableArray  *points;
	NSRect			rect;
	
	long			type;
	long			mode;
	BOOL			needQuartz;
	
	float			thickness;
	
	BOOL			fill;
	float			opacity;
	RGBColor		color;
	
	BOOL			closed;
	
	NSString		*name;
	NSString		*comments;
	
	float			pixelSpacingX, pixelSpacingY;
	NSPoint			imageOrigin;
	
	// **** **** **** **** **** **** **** **** **** **** TRACKING
	
	long			selectedModifyPoint;
	NSPoint			clickPoint, previousPoint;
	long			fontListGL, *fontSize;
	DCMView			*curView;
	DCMPix			*pix;
	
	float			rmean, rmax, rmin, rdev, rtotal;
	float			Brmean, Brmax, Brmin, Brdev, Brtotal;
	
	float			mousePosMeasure;
	
	StringTexture			*stringTex;
	NSMutableDictionary		*stanStringAttrib;
	
	NSString		*_roiSeriesInstanceUID;
	NSString		*_sopInstanceUID;
	NSString		*_referencedSOPInstanceUID;
	NSString		*_referencedSOPClassUID;
	int				_frameNumber;
	
	ROI*			parentROI;
	
	NSRect			drawRect;
	
	char			line1[ 256], line2[ 256], line3[ 256], line4[ 256], line5[ 256];
}

// Create a new ROI, needs the current pixel resolution and image origin
- (id) initWithType: (long) itype :(float) ipixelSpacing :(NSPoint) iimageOrigin;
- (id) initWithType: (long) itype :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin;
// arg: specific methods for tPlain roi
- (id) initWithTexture: (unsigned char*)tBuff  textWidth:(int)tWidth textHeight:(int)tHeight textName:(NSString*)tName
			 positionX:(int)posX positionY:(int)posY
			  spacingX:(float) ipixelSpacingx spacingY:(float) ipixelSpacingy imageOrigin:(NSPoint) iimageOrigin;

/*
 convert DICOM presentation state to ROI. 
 Although the referenced values are in the presentation state. 
 ROIs only point to a single image in OsiriX	
*/

- (id)initWithDICOMPresentationState:(DCMObject *)presentationState
		referencedSOPInstanceUID:(NSString *)referencedSOPInstanceUID
		referencedSOPClassUID:(NSString *)referencedSOPClassUID;

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

// Set/retrieve default ROI name (if not set, then default name is the currentTool)
+ (void) setDefaultName:(NSString*) n;
+ (NSString*) defaultName;
- (void) setDefaultName:(NSString*) n;
- (NSString*) defaultName;

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
- (RGBColor) color;
- (void) setColor:(RGBColor) a;
- (float) thickness;
- (void) setThickness:(float) a;
- (NSMutableDictionary*) dataString;
- (BOOL) mouseRoiUp:(NSPoint) pt;
- (void) setRoiFont: (long) f :(long*) s :(DCMView*) v;
- (void) glStr: (unsigned char *) cstrOut :(float) x :(float) y :(float) line;
- (void) recompute;
- (void) rotate: (float) angle :(NSPoint) center;
- (void) resize: (float) factor :(NSPoint) center;
- (void) setPix: (DCMPix*) newPix;
- (DCMPix*) pix;
- (NSString *)roiSeriesInstanceUID;
- (NSString *)sopInstanceUID;
- (NSString *)referencedSOPInstanceUID;
- (NSString *)referencedSOPClassUID;
- (int) frameNumber;
- (void)setRoiSeriesInstanceUID:(NSString *)roiSeriesInstanceUID;
- (void)setSopInstanceUID:(NSString *)sopInstanceUID;
- (void)setReferencedSOPInstanceUID:(NSString *)referencedSOPInstanceUID;
- (void)setReferencedSOPClassUID:(NSString *)referencedSOPClassUID;
- (void)setFrameNumber: (int)frameNumber;
- (BOOL) reduceTextureIfPossible;
- (void) addMarginToBuffer: (int) margin;
- (void) drawTextualData;
- (long) clickInROI:(NSPoint) pt :(float) offsetx :(float) offsety :(float) scale :(BOOL) testDrawRect;

// parent ROI
- (ROI*) parentROI;
- (void) setParentROI: (ROI*) aROI;

@end
