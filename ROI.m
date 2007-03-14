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

/***************************************** Modifications *********************************************

Version 2.3
	20051227	LP	Preliminary: Adding ability to import and export DICOM presentation states.
					Added ***UID to keep track of Series, SOP, and referenced UIDs.
	20060318	RBR	Added menu item 'Display Name Only' to not display statistical data.
	
	
*/


#import "AppController.h"
#import "StringTexture.h"
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>

#import "ROI.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "ITKSegmentation3D.h"

#define CIRCLERESOLUTION 40
#define ROIVERSION		5

static		float					PI = 3.14159265358979;
static		float					deg2rad = 3.14159265358979/180.0; 

static		NSString				*defaultName;

extern long BresLine(int Ax, int Ay, int Bx, int By,long **xBuffer, long **yBuffer);

// if error dump gl errors to debugger string, return error
GLenum glReportError (void)
{
	GLenum err = glGetError();
	if (GL_NO_ERROR != err)
	{
		NSLog(@"ERR");
	}
	return err;
}

@implementation ROI
+(void) setDefaultName:(NSString*) n
{
	[defaultName release];
	if ( n == nil ) {
		defaultName = nil;
		return;
	}
	defaultName = [[[NSString alloc] initWithString: n] retain];
}

+(NSString*) defaultName {
	return defaultName;
}

-(void) setDefaultName:(NSString*) n
{
	[ROI setDefaultName: n];
}

-(NSString*) defaultName {
	return defaultName;
}
// --- tPlain functions 
-(void)displayTexture
{
	int i,j;
	printf("-*- DISPLAY ROI TEXTURE -*-\n");
	for (j=0;j<textureHeight;j++)
	{
		for(i=0;i<textureWidth;i++)
			printf("%d ",textureBuffer[i+j*textureWidth]);
		printf("\n");
	}
}
- (int)textureDownRightCornerX
{
	return textureDownRightCornerX;
}
-(int)textureDownRightCornerY
{
	return textureDownRightCornerY;
}
- (int)textureUpLeftCornerX
{
	return textureUpLeftCornerX;
}
- (int)textureUpLeftCornerY
{
	return textureUpLeftCornerY;
}
- (int)textureWidth
{
	return textureWidth;
}
-(int)textureHeight
{
	return textureHeight;
}
- (unsigned char*)	textureBuffer
{
	return textureBuffer;
}
- (float) opacity
{
	return opacity;
}
- (void) setOpacity:(float)newOpacity
{
	opacity = newOpacity;
	
	if( type == tPlain)
	{
		[[NSUserDefaults standardUserDefaults] setFloat:opacity forKey:@"ROIRegionOpacity"];
	}
}
-(DCMView*) curView
{
	return curView;
}

- (void) setPix: (DCMPix*) newPix
{
	pix = newPix;
}

-(DCMPix*) pix
{
	if(pix)
	{
		return pix;
	}
	else
	{
		return [curView curDCM];
	}
}

- (id) initWithCoder:(NSCoder*) coder
{
	long fileVersion;
	
    if( self = [super init])
    {
		fileVersion = [coder versionForClassName: @"ROI"];
		
		parentROI = 0L;
		points = [coder decodeObject];
		rect = NSRectFromString( [coder decodeObject]);
		type = [[coder decodeObject] floatValue];
		needQuartz = [[coder decodeObject] floatValue];
		thickness = [[coder decodeObject] floatValue];
		fill = [[coder decodeObject] floatValue];
		opacity = [[coder decodeObject] floatValue];
		color.red = [[coder decodeObject] floatValue];
		color.green = [[coder decodeObject] floatValue];
		color.blue = [[coder decodeObject] floatValue];
		name = [coder decodeObject];
		comments = [coder decodeObject];
		pixelSpacingX = [[coder decodeObject] floatValue];
		imageOrigin = NSPointFromString( [coder decodeObject]);
		
		if( fileVersion >= 2)
		{
			pixelSpacingY = [[coder decodeObject] floatValue];
		}
		else pixelSpacingY = pixelSpacingX;
		if (type==tPlain)
		{
			textureWidth=[[coder decodeObject] intValue];
//			oldTextureWidth=
			[[coder decodeObject] intValue];
			textureHeight=[[coder decodeObject] intValue];
//			oldTextureHeight=
			[[coder decodeObject] intValue];
			
			textureUpLeftCornerX=[[coder decodeObject] intValue];
			textureUpLeftCornerY=[[coder decodeObject] intValue];
			textureDownRightCornerX=[[coder decodeObject] intValue];
			textureDownRightCornerY=[[coder decodeObject] intValue];
			
			unsigned char* pointerBuff=(unsigned char*)[[coder decodeObject] bytes];
//			tempTextureBuffer=(unsigned char*)malloc(textureWidth*textureHeight*sizeof(unsigned char));
			textureBuffer=(unsigned char*)malloc(textureWidth*textureHeight*sizeof(unsigned char));
			long i,j;
			for(j=0;j<textureHeight;j++)
				for(i=0;i<textureWidth;i++)
				{
				//	tempTextureBuffer[i+j*textureWidth]=pointerBuff[i+j*textureWidth];
					textureBuffer[i+j*textureWidth]=pointerBuff[i+j*textureWidth];
				}
		}
		
		if( fileVersion >= 3)
		{
			zPositions = [coder decodeObject];
		}
		else zPositions = [[NSMutableArray arrayWithCapacity:0] retain];
		
		if( fileVersion >= 4)
		{
			offsetTextBox_x = [[coder decodeObject] floatValue];
			offsetTextBox_y = [[coder decodeObject] floatValue];
		}
		else
		{
			offsetTextBox_x = 0;
			offsetTextBox_y = 0;
		}
		
		if (fileVersion >= 5) {
			_calciumThreshold = [[coder decodeObject] intValue];
			_displayCalciumScoring = [[coder decodeObject] boolValue];
		}	
		
		[points retain];
		[name retain];
		[comments retain];
		[zPositions retain]; 
		mode = ROI_sleep;
		
		previousPoint.x = previousPoint.y = -1000;
		
		fontListGL = -1;
		curView = 0L;
		stringTex = 0L;
		rmean = rmax = rmin = rdev = rtotal = -1;
		Brmean = Brmax = Brmin = Brdev = Brtotal = -1;
		mousePosMeasure = -1;
		textureName = 0L;
		{
			// init fonts for use with strings
			NSFont * font =[NSFont fontWithName:@"Helvetica" size: 12.0 + thickness*2];
			stanStringAttrib = [[NSMutableDictionary dictionary] retain];
			[stanStringAttrib setObject:font forKey:NSFontAttributeName];
			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		}
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*) coder
{
	[ROI setVersion:ROIVERSION];
	
    [coder encodeObject:points];
    [coder encodeObject:NSStringFromRect(rect)];
    [coder encodeObject:[NSNumber numberWithFloat:type]]; 
    [coder encodeObject:[NSNumber numberWithFloat:needQuartz]];
	[coder encodeObject:[NSNumber numberWithFloat:thickness]];
	[coder encodeObject:[NSNumber numberWithFloat:fill]];
	[coder encodeObject:[NSNumber numberWithFloat:opacity]];
	[coder encodeObject:[NSNumber numberWithFloat:color.red]];
	[coder encodeObject:[NSNumber numberWithFloat:color.green]];
	[coder encodeObject:[NSNumber numberWithFloat:color.blue]];
	[coder encodeObject:name];
	[coder encodeObject:comments];
	[coder encodeObject:[NSNumber numberWithFloat:pixelSpacingX]];
	[coder encodeObject:NSStringFromPoint(imageOrigin)];
	[coder encodeObject:[NSNumber numberWithFloat:pixelSpacingY]];
	if (type==tPlain)
	{
		/*
		 int			textureWidth, oldTextureWidth, textureHeight, oldTextureHeight;
		 unsigned char*	textureBuffer;
		 unsigned char* tempTextureBuffer;
		 int textureUpLeftCornerX,textureUpLeftCornerY,textureDownRightCornerX,textureDownRightCornerY;
		 int textureFirstPoint;
		 */
		[coder encodeObject:[NSNumber numberWithInt:textureWidth]];
		[coder encodeObject:[NSNumber numberWithInt:0]];
		[coder encodeObject:[NSNumber numberWithInt:textureHeight]];
		[coder encodeObject:[NSNumber numberWithInt:0]];
		
		[coder encodeObject:[NSNumber numberWithInt:textureUpLeftCornerX]];
		[coder encodeObject:[NSNumber numberWithInt:textureUpLeftCornerY]];
		[coder encodeObject:[NSNumber numberWithInt:textureDownRightCornerX]];
		[coder encodeObject:[NSNumber numberWithInt:textureDownRightCornerY]];
		[coder encodeObject:[NSData dataWithBytes:textureBuffer length:(textureWidth*textureHeight)]];
	}
	[coder encodeObject:zPositions];
	[coder encodeObject:[NSNumber numberWithFloat:offsetTextBox_x]];
	[coder encodeObject:[NSNumber numberWithFloat:offsetTextBox_y]];
	[coder encodeObject:[NSNumber numberWithInt:_calciumThreshold]];
	[coder encodeObject:[NSNumber numberWithBool:_displayCalciumScoring]];
}

- (NSData*) data
{
	return [NSArchiver archivedDataWithRootObject: self];
}

- (void) dealloc
{
	if (textureBuffer) free(textureBuffer);
		
	[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:self userInfo: 0L];
	
	[points release];
	[zPositions release];
	[name release];
	[comments release];
	[stringTex release];
	[stanStringAttrib release];
	
	[_roiSeriesInstanceUID release];
	[_sopInstanceUID release];
	[_referencedSOPInstanceUID release];
	[_referencedSOPClassUID release];
	[parentROI release];

	if(layerReferenceFilePath) [layerReferenceFilePath release];
	if(layerImage) [layerImage release];
	if(layerImageWhenSelected) [layerImageWhenSelected release];
	
	[super dealloc];
}


- (void)finalize {
	if(textureBuffer) free(textureBuffer);
	[super finalize];
}


- (void) setOriginAndSpacing :(float) ipixelSpacing :(NSPoint) iimageOrigin
{
	[self setOriginAndSpacing :ipixelSpacing :ipixelSpacing :iimageOrigin];
}

- (void) setOriginAndSpacing :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin
{
	[self setOriginAndSpacing :ipixelSpacingx :ipixelSpacingy :iimageOrigin :YES];
}

- (void) setOriginAndSpacing :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin :(BOOL) sendNotification
{
	long	i;
	BOOL	change = NO;
	
	if( ipixelSpacingx == 0) return;
	if( ipixelSpacingy == 0) return;
	
	if( pixelSpacingX != ipixelSpacingx)
	{
		change = YES;
	}
	
	if( pixelSpacingY != ipixelSpacingy)
	{
		change = YES;
	}
	
	if( imageOrigin.x != iimageOrigin.x || imageOrigin.y != iimageOrigin.y)
	{
		change = YES;
	}
	
	if( change == NO) return;
	
	NSPoint offset;
	
	offset.x = (imageOrigin.x - iimageOrigin.x)/pixelSpacingX;
	offset.y = (imageOrigin.y - iimageOrigin.y)/pixelSpacingY;
	
	long modeSaved = mode;
	mode = ROI_selected;
	[self roiMove:offset :sendNotification];
	mode = modeSaved;

	rect.origin.x *= (pixelSpacingX/ipixelSpacingx);
	rect.origin.y *= (pixelSpacingY/ipixelSpacingy);
	rect.size.width *= (pixelSpacingX/ipixelSpacingx);
	rect.size.height *= (pixelSpacingY/ipixelSpacingy);
	
	for( i = 0; i < [points count]; i++)
	{
		NSPoint aPoint = [[points objectAtIndex:i] point];
		
		aPoint.x *= (pixelSpacingX/ipixelSpacingx);
		aPoint.y *= (pixelSpacingY/ipixelSpacingy);
		
		[[points objectAtIndex:i] setPoint: aPoint];
	}
	
	pixelSpacingX = ipixelSpacingx;
	pixelSpacingY = ipixelSpacingy;
	imageOrigin = iimageOrigin;
	
	if( sendNotification)
	{
		rtotal = -1;
		Brtotal = -1;
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	}
}

- (id) initWithType: (long) itype :(float) ipixelSpacing :(NSPoint) iimageOrigin
{
	return [self initWithType: itype :ipixelSpacing :ipixelSpacing :iimageOrigin];
}
- (id) initWithTexture: (unsigned char*)tBuff  textWidth:(int)tWidth textHeight:(int)tHeight textName:(NSString*)tName
			 positionX:(int)posX positionY:(int)posY
			  spacingX:(float) ipixelSpacingx spacingY:(float) ipixelSpacingy imageOrigin:(NSPoint) iimageOrigin
{
	self = [super init];
    if (self)
	{
		// basic init from other rois ...
		long i,j;
        type = tPlain;
		mode = ROI_sleep;
		parentROI = 0L;
		thickness = 2.0;
		opacity = 0.5;
		textureName = 0L;
		mousePosMeasure = -1;
		pixelSpacingX = ipixelSpacingx;
		pixelSpacingY = ipixelSpacingy;
		imageOrigin = iimageOrigin;
		points = [[NSMutableArray arrayWithCapacity:0] retain];
		zPositions = [[NSMutableArray arrayWithCapacity:0] retain];
		comments = [[NSString alloc] initWithString:@""];
		fontListGL = -1;
		curView = 0L; //@TODO attention curView Null impossible de recuperer l'etat de la gomme !
		stringTex = 0L;
		rmean = rmax = rmin = rdev = rtotal = -1;
		Brmean = Brmax = Brmin = Brdev = Brtotal = -1;
		previousPoint.x = previousPoint.y = -1000;
		
		// specific init for tPlain ...
		textureFirstPoint=1; // a simple indic use to know when it is the first time we create a texture ...
		textureUpLeftCornerX=posX;
		textureUpLeftCornerY=posY;
		textureDownRightCornerX=posX+tWidth-1;
		textureDownRightCornerY=posY+tHeight-1;
		textureWidth=tWidth;
		textureHeight=tHeight;
	//	oldTextureWidth=tWidth;
	//	oldTextureHeight=tHeight;
		
		textureBuffer=(unsigned char*)malloc(tWidth*tHeight*sizeof(unsigned char));
	//	tempTextureBuffer=(unsigned char*)malloc(tWidth*tHeight*sizeof(unsigned char));

//		for(j=0;j<tHeight;j++)
//		{
//			for(i=0;i<tWidth;i++)
//			{
//			//	tempTextureBuffer[i+j*tWidth]=tBuff[i+j*tWidth];
//				textureBuffer[i+j*tWidth]= tBuff[i+j*tWidth];
//			}
//		}
		
		memcpy( textureBuffer, tBuff, tHeight*tWidth);
				
		color.red = 0.67*65535.;
		color.green = 0.90*65535.;
		color.blue = 0.58*65535.;
		name = [[NSString alloc] initWithString:tName];
		
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	return self;
}

- (id) initWithType: (long) itype :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin
{
	self = [super init];
    if (self)
	{
        type = itype;
		mode = ROI_sleep;
		parentROI = 0L;
		
		previousPoint.x = previousPoint.y = -1000;
		
		thickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIThickness"];
		opacity = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIOpacity"];
		color.red = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorR"];
		color.green = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorG"];
		color.blue = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorB"];
		
		mousePosMeasure = -1;
		
		pixelSpacingX = ipixelSpacingx;
		pixelSpacingY = ipixelSpacingy;
		imageOrigin = iimageOrigin;
		
		points = [[NSMutableArray arrayWithCapacity:0] retain];
		zPositions = [[NSMutableArray arrayWithCapacity:0] retain];
		
		comments = [[NSString alloc] initWithString:@""];
		
		textureName = 0L;
		fontListGL = -1;
		curView = 0L;
		stringTex = 0L;
		rmean = rmax = rmin = rdev = rtotal = -1;
		Brmean = Brmax = Brmin = Brdev = Brtotal = -1;
		
		if( type == tText)
		{
			// init fonts for use with strings
			NSFont * font =[NSFont fontWithName:@"Helvetica" size:12.0 + thickness*2];
			stanStringAttrib = [[NSMutableDictionary dictionary] retain];
			[stanStringAttrib setObject:font forKey:NSFontAttributeName];
			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			name = [[NSString alloc] initWithString:@"Double-Click to edit"];
			
			[self setName:name];	// Recompute the texture
			
			color.red = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorR"];
			color.green = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorG"];
			color.blue = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorB"];
		}
		else if (type == tPlain)
		{
			textureUpLeftCornerX	=0.0;
			textureUpLeftCornerY	=0.0;
			textureDownRightCornerX	=0.0;
			textureDownRightCornerY	=0.0;
			textureWidth			=128;
			textureHeight			=128;
			textureBuffer			=NULL;
	//		tempTextureBuffer		=NULL;
			textureFirstPoint		=0;
			
			thickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionThickness"];
			color.red = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorR"];
			color.green = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorG"];
			color.blue = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorB"];
			opacity = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionOpacity"];
			
			name = [[NSString alloc] initWithString:@"Region"];
		}
		else if(type == tLayerROI)
		{
			layerReferenceFilePath = @"";
			[layerReferenceFilePath retain];
			layerImage = nil;
			layerImageWhenSelected = nil;
			layerUpperLeftCornerPosition = NSMakePoint(0, 0);
			layerLowerRightCornerPosition = NSMakePoint(100, 100);
			layerRotationAngle = 0;
			layerRotationCenter = NSMakePoint(0, 0);
			layerTranslation = NSMakePoint(0, 0);
			name = [[NSString alloc] initWithString:@"Layer"];
		}
		else
		{
			name = [[NSString alloc] initWithString:@"Unnamed"];
		}
		
		
    }
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
    return self;
}

- (id)initWithDICOMPresentationState:(DCMObject *)presentationState
		referencedSOPInstanceUID:(NSString *)referencedSOPInstanceUID
		referencedSOPClassUID:(NSString *)referencedSOPClassUID{
		
	return nil;
}

- (long) maxStringWidth:( char *) cstr max:(long) max
{
	if( cstr[ 0] == 0) return max;
	
	long i = 0, temp = 0;
	
	while( cstr[ i] != 0)
	{
		temp += fontSize[ cstr[ i]];
		i++;
	}
	
	if( temp > max) max = temp;
	
	return max;
}

- (void) glStr: (unsigned char *) cstrOut :(float) x :(float) y :(float) line
{
	if( cstrOut[ 0] == 0) return;

	float xx, yy, rotation = 0, ratio;
	
	line *= 12;
	
	xx = x + 1.0f;
	yy = y + (line + 1.0);
	
    glColor3f (0.0, 0.0, 0.0);

    glRasterPos3d (xx, yy, 0);
	
    GLint i = 0;
    while (cstrOut [i]) glCallList (fontListGL + cstrOut[i++] - ' ');

	xx = x;
	yy = y + line;
	
    glColor3f (1.0f, 1.0f, 1.0f);
    glRasterPos3d (xx, yy, 0);
    i = 0;
    while (cstrOut [i]) glCallList (fontListGL + cstrOut[i++] - ' ');
}

-(float) EllipseArea
{
	return fabs (3.14159265358979 * rect.size.width*2. * rect.size.height*2.) / 4.;
}

-(float) plainArea
{
	long i, x;
	
	
	for( i = 0, x = 0 ; i < textureWidth*textureHeight ; i++)
	{
		if( textureBuffer[i] != 0)
		{
			x++;
		}
	}
	
	return x;
}

-(float) Area
{
   long		i,j;
   float	area = 0;

   for( i = 0 ; i < [points count] ; i++)
   {
      j = (i + 1) % [points count];
	  
      area += [[points objectAtIndex:i] x] * [[points objectAtIndex:j] y];
      area -= [[points objectAtIndex:i] y] * [[points objectAtIndex:j] x];
   }

   area /= 2;
   
   return fabs( area);
}

-(float) Angle:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3
{
  float 		ax,ay,bx,by;
  float			val, angle;
  float			px = 1, py = 1;
  
  if( pixelSpacingX != 0 && pixelSpacingY != 0)
  {
	px = pixelSpacingX;
	py = pixelSpacingY;
  }
  
  ax = p2.x*px - p1.x*px;
  ay = p2.y*py - p1.y*py;
  bx = p3.x*px - p1.x*px;
  by = p3.y*py - p1.y*py;
  
  if (ax == 0 && ay == 0) return 0;
  val = ((ax * bx) + (ay * by)) / (sqrt(ax*ax + ay*ay) * sqrt(bx*bx + by*by));
  angle = acos (val) / deg2rad;
  return angle;
}

-(float) Magnitude:( NSPoint) Point1 :(NSPoint) Point2 
{
    NSPoint Vector;

    Vector.x = Point2.x - Point1.x;
    Vector.y = Point2.y - Point1.y;

    return (float)sqrt( Vector.x * Vector.x + Vector.y * Vector.y);
}


-(float) Length:(NSPoint) mesureA :(NSPoint) mesureB
{
	short yT, xT;
	float mesureLength;
	
	if( mesureA.x > mesureB.x) { yT = mesureA.y;  xT = mesureA.x;}
	else {yT = mesureB.y;   xT = mesureB.x;}
	
	{
		double coteA, coteB;
		
		coteA = fabs(mesureA.x - mesureB.x);
		coteB = fabs(mesureA.y - mesureB.y);	// * [[curView curDCM] pixelRatio]
		
		if( pixelSpacingX != 0 && pixelSpacingY != 0)
		{
			coteA *= pixelSpacingX;
			coteB *= pixelSpacingY;
		}
		
		if( coteA == 0) mesureLength = coteB;
		else if( coteB == 0) mesureLength = coteA;
		else mesureLength = coteB / (sin (atan( coteB / coteA)));
		
		if( pixelSpacingX != 0 && pixelSpacingY != 0)
		{
			mesureLength /= 10.0;
		}
	}
	
	return mesureLength;
}

-(NSPoint) ProjectionPointLine: (NSPoint) Point :(NSPoint) startPoint :(NSPoint) endPoint
{
    float   LineMag;
    float   U;
    NSPoint Intersection;
 
    LineMag = [self Magnitude: endPoint : startPoint];
 
    U = ( ( ( Point.x - startPoint.x ) * ( endPoint.x - startPoint.x ) ) +
        ( ( Point.y - startPoint.y ) * ( endPoint.y - startPoint.y ) ) );
		
	U /= ( LineMag * LineMag );

//    if( U < -0.2f || U > 1.2f )
//	{
//		return 0;
//	}
	
    Intersection.x = startPoint.x + U * ( endPoint.x - startPoint.x );
    Intersection.y = startPoint.y + U * ( endPoint.y - startPoint.y );
	
    return Intersection;
}

-(int) DistancePointLine: (NSPoint) Point :(NSPoint) startPoint :(NSPoint) endPoint :(float*) Distance
{
    float   LineMag;
    float   U;
    NSPoint Intersection;
 
    LineMag = [self Magnitude: endPoint : startPoint];
 
    U = ( ( ( Point.x - startPoint.x ) * ( endPoint.x - startPoint.x ) ) +
        ( ( Point.y - startPoint.y ) * ( endPoint.y - startPoint.y ) ) );
		
	U /= ( LineMag * LineMag );

    if( U < -0.2f || U > 1.2f )
	{
		*Distance = 100;
		return 0;   // closest point does not fall within the line segment
	}
	
    Intersection.x = startPoint.x + U * ( endPoint.x - startPoint.x );
    Intersection.y = startPoint.y + U * ( endPoint.y - startPoint.y );

//    Intersection.Z = LineStart->Z + U * ( endPoint->Z - LineStart->Z );
 
    *Distance = [self Magnitude: Point :Intersection];
 
    return 1;
}

- (NSPoint) lowerRightPoint
{
	long		i;
	float		xmin, xmax, ymin, ymax;
	NSPoint		result;
	
	switch( type)
	{
		case tMesure:
			if( [[points objectAtIndex:0] x] < [[points objectAtIndex:1] x]) result = [[points objectAtIndex:1] point];
			else result = [[points objectAtIndex:0] point];
		break;
			
		case tPlain:
			result.x = textureDownRightCornerX;
			result.y = textureDownRightCornerY;
			break;
			
		case tArrow:
			result = [[points objectAtIndex:1] point];
		break;
		
		case tAngle:
			result = [[points objectAtIndex:1] point];
		break;
		
		case tCPolygon:
		case tOPolygon:
		case tPencil:
		
			xmin = xmax = [[points objectAtIndex:0] x];
			ymin = ymax = [[points objectAtIndex:0] y];
			
			for( i = 0; i < [points count]; i++)
			{
				if( [[points objectAtIndex:i] x] < xmin) xmin = [[points objectAtIndex:i] x];
				if( [[points objectAtIndex:i] x] > xmax) xmax = [[points objectAtIndex:i] x];
				if( [[points objectAtIndex:i] y] < ymin) ymin = [[points objectAtIndex:i] y];
				if( [[points objectAtIndex:i] y] > ymax) ymax = [[points objectAtIndex:i] y];
			}
			
			result.x = xmax;
			result.y = ymax;
		break;
		
		case t2DPoint:
		case tText:
			result.x = rect.origin.x;
			result.y = rect.origin.y;
		break;
		
		case tOval:
			result.x = rect.origin.x + rect.size.width/4;
			result.y = rect.origin.y + rect.size.height;
		break;
		
		case tROI:
			result.x = rect.origin.x + rect.size.width;
			result.y = rect.origin.y + rect.size.height;
		break;
	}
	
	return result;
}

- (void) setROIRect:(NSRect) irect
{
	rect = irect;
}
- (NSRect) rect
{
return rect;
}
- (NSMutableArray*) points
{
	long i;
	
	if(type == t2DPoint)
	{
		NSMutableArray  *tempArray = [NSMutableArray arrayWithCapacity:0];
		MyPoint			*tempPoint;
		
		tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( NSMinX( rect), NSMinY( rect))];
		[tempArray addObject:tempPoint];
		[tempPoint release];
		
		return tempArray;
	}
	
	if(type == tROI)
	{
		NSMutableArray  *tempArray = [NSMutableArray arrayWithCapacity:0];
		MyPoint			*tempPoint;
		
		tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( NSMinX( rect), NSMinY( rect))];
		[tempArray addObject:tempPoint];
		[tempPoint release];
		
		tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( NSMinX( rect), NSMaxY( rect))];
		[tempArray addObject:tempPoint];
		[tempPoint release];
		
		tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( NSMaxX( rect), NSMaxY( rect))];
		[tempArray addObject:tempPoint];
		[tempPoint release];
		
		tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( NSMaxX( rect), NSMinY( rect))];
		[tempArray addObject:tempPoint];
		[tempPoint release];
		
		return tempArray;
	}
	
	if(  type == tOval)
	{
		NSMutableArray  *tempArray = [NSMutableArray arrayWithCapacity:0];
		MyPoint			*tempPoint;
		float			angle;
		
		for(i = 0; i < CIRCLERESOLUTION ; i++)
		{
			// M_PI defined in cmath.h
			angle = i * 2 * M_PI /CIRCLERESOLUTION;
		  
			tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( rect.origin.x + rect.size.width*cos(angle), rect.origin.y + rect.size.height*sin(angle))];
			[tempArray addObject:tempPoint];
			[tempPoint release];
		}
		
		return tempArray;
	}
	
	if( type == tPlain)
	{
		NSMutableArray  *tempArray = [ITKSegmentation3D extractContour:textureBuffer width:textureWidth  height:textureHeight];
		
		for( i = 0; i < [tempArray count]; i++)
		{
			MyPoint	*pt = [tempArray objectAtIndex: i];
			[pt move: textureUpLeftCornerX :textureUpLeftCornerY];
		}
		
		return tempArray;
	}
	
	return points;
}

- (void) setPoints: (NSArray*) pts {
	long i;
	
	if ( type == tROI || type == tOval ) return;  // Doesn't make sense to set points for these types.
	
	for ( i = 0; i < [pts count]; i++ )
		[points addObject: [pts objectAtIndex: i]];
	
	return;
}

- (NSMutableArray*) zPositions;
{
	return zPositions;
}

- (BOOL) clickInTextBox
{
	return clickInTextBox;
}

- (void) setTextBoxOffset:(NSPoint) o
{
	offsetTextBox_x += o.x;
	offsetTextBox_y += o.y;
}

- (long) clickInROI:(NSPoint) pt :(float) offsetx :(float) offsety :(float) scale :(BOOL) testDrawRect
{
	NSRect		arect;
	long		i, j;
	long		xmin, xmax, ymin, ymax;
	long		imode = ROI_sleep;

	if( mode == ROI_drawing)
	{
		return 0;
	}
	
	clickInTextBox = NO;
	
	if( testDrawRect)
	{
		NSPoint cPt = [curView ConvertFromGL2View: pt];
		
		if( NSPointInRect( cPt, drawRect))
		{
			imode = ROI_selected;
			
			clickInTextBox = YES;
		}
	}
	else
	{
		switch( type)
		{
			case tLayerROI:
			{
				NSPoint p1, p2, p3, p4;
				p1 = layerUpperLeftCornerPosition;
				p2 = layerLowerRightCornerPosition;
				p3 = NSMakePoint(layerUpperLeftCornerPosition.x,layerLowerRightCornerPosition.y);
				p4 = NSMakePoint(layerLowerRightCornerPosition.x,layerUpperLeftCornerPosition.y);

				NSLog(@"angle : %f // center: %f, %f", layerRotationAngle, layerRotationCenter.x, layerRotationCenter.y);
//				if(layerRotationAngle>0)
//				{
					p1 = [self rotatePoint:p1 withAngle:layerRotationAngle aroundCenter:layerRotationCenter];
					p2 = [self rotatePoint:p2 withAngle:layerRotationAngle aroundCenter:layerRotationCenter];
					p3 = [self rotatePoint:p3 withAngle:layerRotationAngle aroundCenter:layerRotationCenter];
					p4 = [self rotatePoint:p4 withAngle:layerRotationAngle aroundCenter:layerRotationCenter];
//				}

				
				NSLog(@"layerTranslation : %f, %f", layerTranslation.x, layerTranslation.y);				
				if(layerTranslation.x!=0)
				{
					p1.x += layerTranslation.x;
					p2.x += layerTranslation.x;
					p3.x += layerTranslation.x;
					p4.x += layerTranslation.x;
				}
				
				if(layerTranslation.y!=0)
				{
					p1.y += layerTranslation.y;
					p2.y += layerTranslation.y;
					p3.y += layerTranslation.y;
					p4.y += layerTranslation.y;
				}
				
				if(layerRotationAngle==0) // no rotation...
				{
					NSLog(@"no rotation");
					if(pt.x>=layerUpperLeftCornerPosition.x+layerTranslation.x && pt.x<=layerLowerRightCornerPosition.x+layerTranslation.x && pt.y<=layerLowerRightCornerPosition.y+layerTranslation.y && pt.y>=layerUpperLeftCornerPosition.y+layerTranslation.y)
					{
						NSLog(@"in layer !");
						imode = ROI_selected;
					}
					else
					{
						NSLog(@"out...");
					}					
				}
				else if([self isPoint:pt inRectDefinedByPointA:p1 pointB:p2 pointC:p3 pointD:p4])
				{
					NSLog(@"in layer !");
					imode = ROI_selected;
				}
				else
				{
					NSLog(@"out...");
				}
				
//				// bring selected layer to front
//				if(imode == ROI_selected)
//				{
//					[[[curView windowController] roiLock] lock];
//					NSMutableArray *curROIList = [[curView dcmRoiList] objectAtIndex:[curView curImage]]; // ROI List for this slice
//					[curROIList removeObject:self];
//					[curROIList insertObject:self atIndex:0];
//					[[[curView windowController] roiLock] unlock];
//				}
			}
			break;
			case tPlain:
				if (pt.x>textureUpLeftCornerX && pt.x<textureDownRightCornerX && pt.y>textureUpLeftCornerY && pt.y<textureDownRightCornerY)
				{
					if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
					{
						imode = ROI_selectedModify;
					}
					else
					{
						imode = ROI_selected;
					}
				}
				break;
			case tOval:
				arect = NSMakeRect( rect.origin.x -rect.size.width -5./scale, rect.origin.y -rect.size.height -5./scale, 2*rect.size.width +10./scale, 2*rect.size.height +10./scale);
				
				if( NSPointInRect( pt, arect)) imode = ROI_selected;
			break;
			
			
			case tROI:
				arect = NSMakeRect( rect.origin.x -5, rect.origin.y-5, rect.size.width+10, rect.size.height+10);
				
				if( NSPointInRect( pt, arect)) imode = ROI_selected;
			break;
			
			case t2DPoint:
				arect = NSMakeRect( rect.origin.x - 8/scale, rect.origin.y - 8/scale, 8*2/scale, 8*2/scale);
				
				if( NSPointInRect( pt, arect)) imode = ROI_selected;
			break;
			
			case tText:
				arect = NSMakeRect( rect.origin.x - rect.size.width/(2*scale), rect.origin.y - rect.size.height/(2*scale), rect.size.width/scale, rect.size.height/scale);
				
				if( NSPointInRect( pt, arect)) imode = ROI_selected;
			break;
			
			
			case tArrow:
			case tMesure:
			{
				float distance;
				
				[self DistancePointLine:pt :[[points objectAtIndex:0] point] : [[points objectAtIndex:1] point] :&distance];
				
				if( distance*scale < 5.0)
				{
					imode = ROI_selected;
				}
			}
			break;
			
			
			case tOPolygon:
			case tAngle:
			{
				float distance;

				for( i = 0; i < ([points count] - 1); i++)
				{
					[self DistancePointLine:pt :[[points objectAtIndex:i] point] : [[points objectAtIndex:(i+1)] point] :&distance];
					if( distance*scale < 5.0)
					{
						imode = ROI_selected;
						break;
					}
				}
			}
			break;
			
			case tCPolygon:
			case tPencil:
			{
				float distance;

				for( i = 0; i < ([points count] - 1); i++)
				{
					[self DistancePointLine:pt :[[points objectAtIndex:i] point] : [[points objectAtIndex:(i+1)] point] :&distance];
					if( distance*scale < 5.0)
					{
						imode = ROI_selected;
						break;
					}
				}
				
				[self DistancePointLine:pt :[[points objectAtIndex:i] point] : [[points objectAtIndex:0] point] :&distance];
				if( distance*scale < 5.0)
				{
					imode = ROI_selected;
				}
			}
			break;

//			case tCPolygon:
//			case tPencil:
//			{
//				int count = 0;
//				
//				for (j = 0; j < 5; j++)
//				{
//					NSPoint selectPt = pt;
//					
//					switch(j)
//					{
//						case 0: break;
//						case 1: selectPt.x += 5.0/scale; break;
//						case 2: selectPt.x -= 5.0/scale; break;
//						case 3: selectPt.y += 5.0/scale; break;
//						case 4: selectPt.y -= 5.0/scale; break;
//					}
//					for( i = 0; i < [points count]; i++)
//					{
//						NSPoint p1 = [[points objectAtIndex:i] point];
//						NSPoint p2 = [[points objectAtIndex:(i+1)%[points count]] point];
//						double intercept;
//						
//						if (selectPt.y > MIN(p1.y, p2.y) && selectPt.y <= MAX(p1.y, p2.y) && selectPt.x <= MAX(p1.x, p2.x) && p1.y != p2.y)
//						{
//							intercept = (selectPt.y-p1.y)*(p2.x-p1.x)/(p2.y-p1.y)+p1.x;
//							if (p1.x == p2.x || selectPt.x <= intercept)
//								count = !count;
//						}
//					}
//					
//					if (count)
//					{
//						imode = ROI_selected;
//						break;
//					}
//				}
//				break;
//			}
		}
	}
	
	if( imode == ROI_selected)
	{
		MyPoint		*tempPoint = [[MyPoint alloc] initWithPoint: pt];
		NSPoint		aPt;
		
		switch( type)
		{
//			case tPlain:
//				imode = ROI_selectedModify;
//			break;
			case tOval:
				selectedModifyPoint = 0;
				
				aPt.x = rect.origin.x - rect.size.width;		aPt.y = rect.origin.y - rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 1;
				
				aPt.x = rect.origin.x - rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 2;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 3;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y - rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 4;
				
				if( selectedModifyPoint) imode = ROI_selectedModify;
			break;
			
			case tROI:
				selectedModifyPoint = 0;
				
				aPt.x = rect.origin.x;		aPt.y = rect.origin.y;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 1;
				
				aPt.x = rect.origin.x;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 2;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 3;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y;
				if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 4;
				
				if( selectedModifyPoint) imode = ROI_selectedModify;
			break;
			
			case tAngle:
			case tArrow:
			case tMesure:
			case tCPolygon:
			case tOPolygon:
			case tPencil:
				for( i = 0 ; i < [points count]; i++)
				{
					if( [[points objectAtIndex: i] isNearToPoint: pt :scale :[[curView curDCM] pixelRatio]])
					{
						imode = ROI_selectedModify;
						selectedModifyPoint = i;
					}
				}
			break;
		}
		
		clickPoint = pt;
		
		[tempPoint release];
	}
	
	return imode;
}

- (BOOL)mouseRoiDown:(NSPoint)pt :(float)scale
{
	[self mouseRoiDown:pt :[curView curImage] :scale];
}

- (BOOL)mouseRoiDown:(NSPoint)pt :(int)slice :(float)scale
{
	MyPoint				*mypt;
	
	if( mode == ROI_sleep)
	{
		mode = ROI_drawing;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	
	if (type==tPlain)
	{
		if (textureFirstPoint==0)
		{
			textureUpLeftCornerX=pt.x;
			textureUpLeftCornerY=pt.y;
			textureDownRightCornerX=pt.x+1;
			textureDownRightCornerY=pt.y+1;
			textureFirstPoint=1;
			textureWidth=2;
			textureHeight=2;
	//		oldTextureWidth = 2;
	//		oldTextureHeight=2;
			textureBuffer = malloc(textureWidth*textureHeight*sizeof(unsigned char));
			memset (textureBuffer, 0, textureHeight*textureWidth);
	//		tempTextureBuffer = malloc(textureWidth*textureHeight*sizeof(unsigned char));
	//		memset (tempTextureBuffer, 0, textureHeight*textureWidth);
			
			mode = ROI_drawing;
		}
		else
		{
			mode = ROI_selected;
		}
		
		previousPoint = pt;
		
				
		return NO;
	}
	
	if( type == tText || type == t2DPoint)
	{
		rect.size = [stringTex frameSize];
		rect.origin.x = pt.x;// - rect.size.width/2;
		rect.origin.y = pt.y;// - rect.size.height/2;
		
		if( type == t2DPoint)
		{
			rect.size.height = 0;// - rect.size.width/2;
			rect.size.width = 0;// - rect.size.height/2;
		}
		
//		rect.size.width /= scale;
//		rect.size.height /= scale;
		
		mode = ROI_selected;
		
		return NO;
	}
	else if( type == tOval || type == tROI)
	{
		rect.origin = pt;
		rect.size.width = 0;
		rect.size.height = 0;
		
		mode = ROI_drawing;
		
		return NO;
	}
	else if(type == tArrow || type == tMesure)
	{
		mypt = [[MyPoint alloc] initWithPoint: pt];
		[points addObject: mypt];
		[mypt release];
		
		mypt = [[MyPoint alloc] initWithPoint: pt];
		[points addObject: mypt];
		[mypt release];
		
		mode = ROI_drawing;
		
		return NO;
	}
//	else if (type == tPencil)
//	{
//		mode = ROI_selected;
//	}
	else
	{
		if( [[points lastObject] isNearToPoint: pt : scale/thickness :[[curView curDCM] pixelRatio]] == NO)
		{
			mypt = [[MyPoint alloc] initWithPoint: pt];
			
			[points addObject: mypt];
			[mypt release];
			
//			NSLog(@" [ROI, mouseRoiDown] adding point for polygon...");
//			NSLog(@" [ROI, mouseRoiDown] slice : %d", slice);
			[zPositions addObject:[NSNumber numberWithInt:slice]];
			
			clickPoint = pt;
		}
		else	// Click on same point as last object -> STOP drawing
		{
			mode = ROI_selected;
		}
		
		if( type == tAngle)
		{
			if( [points count] > 2) mode = ROI_selected;
		}
	}
	
	if( type == tPencil) return NO;
	
	if( mode == ROI_drawing) return YES;
	else return NO;
}

- (void) rotate: (float) angle :(NSPoint) center
{
	if(type==tLayerROI)
	{
		layerRotationAngle += angle;
		if(layerRotationAngle>=360) layerRotationAngle -= 360;
		//layerRotationCenter = center;
		return;
	}

    float theta;
    float dtheta;
    long i;
    long intUpper;
    float new_x;
    float new_y;
	float intYCenter, intXCenter;
	NSMutableArray	*pts = [self points];
	
    intUpper = [pts count];
	if( intUpper > 0)
	{
		dtheta = deg2rad;
		theta = dtheta * angle; 
		
//		// Center of polygon
//		intYCenter = intXCenter = 0;
//		for( i = 0; i < intUpper; i++)
//		{ 
//			intYCenter += [[pts objectAtIndex: i] y];
//			intXCenter += [[pts objectAtIndex: i] x];
//		}
//		
//		intYCenter /= intUpper;
//		intXCenter /= intUpper;
		
		if( type == tROI || type == tOval)
		{
			type = tCPolygon;
			[points release];
			points = [pts retain];
		}
		
		intXCenter = center.x;
		intYCenter = center.y;
		
		for( i = 0; i < intUpper; i++)
		{ 
			new_x = cos(theta) * ([[pts objectAtIndex: i] x] - intXCenter) - sin(theta) * ([[pts objectAtIndex: i] y] - intYCenter);
			new_y = sin(theta) * ([[pts objectAtIndex: i] x] - intXCenter) + cos(theta) * ([[pts objectAtIndex: i] y] - intYCenter);
			
			[[pts objectAtIndex: i] setPoint: NSMakePoint( new_x + intXCenter, new_y + intYCenter)];
		}
		
		rtotal = -1;
		Brtotal = -1;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	}
}

- (void) resize: (float) factor :(NSPoint) center
{
    long i;
    long intUpper;
    float new_x;
    float new_y;
	float intYCenter, intXCenter;
	NSMutableArray	*pts = [self points];

    intUpper = [pts count];
	if( intUpper > 0)
	{
		if( type == tROI || type == tOval)
		{
			type = tCPolygon;
			[points release];
			points = [pts retain];
		}
		
		intXCenter = center.x;
		intYCenter = center.y;
		
		for( i = 0; i < intUpper; i++)
		{ 
			new_x = ([[pts objectAtIndex: i] x] - intXCenter) * factor;
			new_y = ([[pts objectAtIndex: i] y] - intYCenter) * factor;
			
			[[pts objectAtIndex: i] setPoint: NSMakePoint( new_x + intXCenter, new_y + intYCenter)];
		}
		
		rtotal = -1;
		Brtotal = -1;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	}
}

- (BOOL) valid
{
	if( mode == ROI_drawing) return YES;
	
	switch( type)
	{
		case tOval:
			if( rect.size.width < 0)
			{
				rect.size.width = -rect.size.width;
			}
			
			if( rect.size.height < 0)
			{
				rect.size.height = -rect.size.height;
			}
			
			if( rect.size.width < 1) return NO;
			if( rect.size.height < 1) return NO;
		break;
		
		case t2DPoint:
			if( rect.size.width < 0)
			{
				rect.origin.x = rect.origin.x + rect.size.width;
				rect.size.width = 0;
			}
			
			if( rect.size.height < 0)
			{
				rect.origin.y = rect.origin.y + rect.size.height;
				rect.size.height = 0;
			}
		break;
		
		case tText:
		case tROI:
		
			if( rect.size.width < 0)
			{
				rect.origin.x = rect.origin.x + rect.size.width;
				rect.size.width = -rect.size.width;
			}
			
			if( rect.size.height < 0)
			{
				rect.origin.y = rect.origin.y + rect.size.height;
				rect.size.height = -rect.size.height;
			}
			
			if( rect.size.width < 1) return NO;
			if( rect.size.height < 1) return NO;
		break;
		
		case tCPolygon:
		case tOPolygon:
		case tPencil:
			if( [points count] < 3) return NO;
		break;
		
		case tAngle:
			if( [points count] < 3) return NO;
		break;
		
		case tMesure:
		case tArrow:
			if( [points count] < 2) return NO;
			
			if( ABS([[points objectAtIndex:0] x] - [[points objectAtIndex:1] x]) < 1.0 && ABS([[points objectAtIndex:0] y] - [[points objectAtIndex:1] y]) < 1.0) return NO;
		break;
			
	}
	
	return YES;
}

- (void) recompute
{
	rtotal = -1;
	Brtotal = -1;
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
}

- (void) roiMove:(NSPoint) offset :(BOOL) sendNotification
{
	if( mode == ROI_selected)
	{
		long i;

		switch( type)
		{
			case tOval:
			case tText:
			case t2DPoint:
			case tROI:
				rect = NSOffsetRect( rect, offset.x, offset.y);
			break;
			
			case tCPolygon:
			case tOPolygon:
			case tMesure:
			case tArrow:
			case tAngle:
			case tPencil:
				for( i = 0; i < [points count]; i++)
				{
					[[points objectAtIndex: i] move: offset.x : offset.y];
				}
			break;
			
			case tLayerROI:
//				layerUpperLeftCornerPosition.x += offset.x;
//				layerUpperLeftCornerPosition.y += offset.y;
//				layerLowerRightCornerPosition.x += offset.x;
//				layerLowerRightCornerPosition.y += offset.y;
				layerTranslation.x += offset.x;
				layerTranslation.y += offset.y;
			break;
		}
		
		if( sendNotification)
		{
			rtotal = -1;
			Brtotal = -1;
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
		}
	}
}

- (void) roiMove:(NSPoint) offset
{
	[self roiMove:offset :YES];
}

- (BOOL) mouseRoiUp:(NSPoint) pt
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: [NSDictionary dictionaryWithObjectsAndKeys:@"mouseUp", @"action", 0L]];
	
	previousPoint.x = previousPoint.y = -1000;
	
	if( type == tOval || type == tROI || type == tText || type == tArrow || type == tMesure || type == tPencil || type == t2DPoint || type == tPlain)
	{
		[self reduceTextureIfPossible];
		
		if( mode == ROI_drawing)
		{
			rtotal = -1;
			Brtotal = -1;
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
			
			mode = ROI_selected;
			return NO;
		}
	}
	
	
	
	return YES;
}

- (BOOL) reduceTextureIfPossible
{
	if( type != tPlain) return YES;
	
	long			x, y;
	long			minX, maxX, minY, maxY;
	unsigned char	*tempBuf = textureBuffer;
	
	minX = textureWidth;
	maxX = 0;
	minY = textureHeight;
	maxY = 0;
	
	for( y = 0; y < textureHeight ; y++)
	{
		for( x = 0; x < textureWidth; x++)
		{                      
			if( *tempBuf++ != 0)
			{
				if( x < minX) minX = x;
				if( x > maxX) maxX = x;
				if( y < minY) minY = y;
				if( y > maxY) maxY = y;
			}
		}
	}
	
	if( minX > maxX) return YES;
	if( minY > maxY) return YES;
	
	#define CUTOFF 8
	
	if( minX > CUTOFF || maxX < textureWidth-CUTOFF || minY > CUTOFF || maxY < textureHeight-CUTOFF)
	{
		minX -= 2;
		minY -= 2;
		maxX += 2;
		maxY += 2;
		
		if( minX < 0) minX = 0;
		if( minY < 0) minY = 0;
		if( maxX >= textureWidth) maxX = textureWidth-1;
		if( maxY >= textureHeight) maxY = textureHeight-1;
		
		int offsetTextureY = minY;
		int offsetTextureX = minX;
		
		int oldTextureWidth = textureWidth;
		int oldTextureHeight = textureHeight;
		
		textureWidth = maxX - minX+1;
		textureHeight = maxY - minY+1;
		
		for( y = 0 ; y < textureHeight ; y++)
		{
			memcpy( textureBuffer + (y * textureWidth), textureBuffer + offsetTextureX+ (y+ offsetTextureY)*oldTextureWidth,  textureWidth);
		}
		
		textureUpLeftCornerX += minX;
		textureUpLeftCornerY += minY;
		textureDownRightCornerX = textureUpLeftCornerX + textureWidth-1;
		textureDownRightCornerY = textureUpLeftCornerY + textureHeight-1;
	}
	
	return NO;
}

+ (void) fillCircle:(unsigned char *) buf :(int) width :(unsigned char) val
{
	int		x,y;
	int		xsqr;
	int		radsqr = (width*width)/4;
	int		rad = width/2;
	
	for(x = 0; x < rad; x++)
	{
		xsqr = x*x;
		for( y = 0 ; y < rad; y++)
		{
			if((xsqr + y*y) < radsqr)
			{
				buf[ rad+x + (rad+y)*width] = val;
				buf[ rad-x + (rad+y)*width] = val;
				buf[ rad+x + (rad-y)*width] = val;
				buf[ rad-x + (rad-y)*width] = val;
			}
			else break;
		}
	}
}

- (BOOL) mouseRoiDragged:(NSPoint) pt :(unsigned int) modifier :(float) scale
{
	BOOL		action = NO;
	long		i,j, x;
	BOOL		textureGrowDownX=YES,textureGrowDownY=YES;
	float		oldTextureUpLeftCornerX,oldTextureUpLeftCornerY,offsetTextureX,offsetTextureY;

	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	
	if( type == tText || type == t2DPoint)
	{
		action = NO;
	}
	else if( type == tPlain)
	{
		switch( mode)
		{
			case ROI_selectedModify:
			case ROI_drawing:
				
				thickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionThickness"];
			
				if (textureUpLeftCornerX > pt.x-thickness)
				{
					oldTextureUpLeftCornerX = textureUpLeftCornerX;
					textureUpLeftCornerX = pt.x-thickness - 4;
					textureGrowDownX=NO;
				}
				if (textureUpLeftCornerY > pt.y-thickness)
				{
					oldTextureUpLeftCornerY=textureUpLeftCornerY;
					textureUpLeftCornerY=pt.y-thickness - 4;
					textureGrowDownY=NO;
				}
				if (textureDownRightCornerX < pt.x+thickness)
				{
					textureDownRightCornerX=pt.x+thickness + 4;
					textureGrowDownX=YES;
				}
				if (textureDownRightCornerY < pt.y+thickness)
				{
					textureDownRightCornerY=pt.y+thickness + 4;
					textureGrowDownY=YES;
				}
				
				int oldTextureHeight = textureHeight;
				int oldTextureWidth = textureWidth;
				unsigned char* tempTextureBuffer = 0L;
				
				// copy current Buffer to temp Buffer	
				if (textureBuffer!=NULL)
				{
					
					tempTextureBuffer = malloc( oldTextureHeight*oldTextureWidth*sizeof(unsigned char));
	
					for( i = 0; i < oldTextureWidth*oldTextureHeight;i++) tempTextureBuffer[i]=textureBuffer[i];
					free(textureBuffer);
					textureBuffer = 0L;
				}
				
				// new width and height
				textureWidth=((textureDownRightCornerX-textureUpLeftCornerX))+1;
				textureHeight=((textureDownRightCornerY-textureUpLeftCornerY))+1;	
			  	
				// ROI cannot be smaller !
				if (textureWidth<oldTextureWidth)
					textureWidth=oldTextureWidth;
					
				if (textureHeight<oldTextureHeight)
					textureHeight=oldTextureHeight;
						
				// new texture buffer		
				textureBuffer = malloc(textureWidth*textureHeight*sizeof(unsigned char));
				
				if (textureBuffer!=NULL)
				{
					// copy temp buffer to the new buffer
					for( i = 0; i < textureWidth*textureHeight;i++) textureBuffer[i]=0;
					
					if (textureGrowDownX && textureGrowDownY)
					{
						for(j=0;j<oldTextureHeight;j++)
							for(i=0;i<oldTextureWidth;i++)
								textureBuffer[i+j*textureWidth] = tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					if (!textureGrowDownX && textureGrowDownY)
					{
						offsetTextureX=(oldTextureUpLeftCornerX-textureUpLeftCornerX);
						for(j=0;j<oldTextureHeight;j++)
							for(i=0;i<oldTextureWidth;i++)
								textureBuffer[(long)(i+offsetTextureX+j*textureWidth)]=tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					if (textureGrowDownX && !textureGrowDownY)
					{
						offsetTextureY=(oldTextureUpLeftCornerY-textureUpLeftCornerY);
						for(j=0;j<oldTextureHeight;j++)
							for(i=0;i<oldTextureWidth;i++)
								textureBuffer[(long)(i+(j+offsetTextureY)*textureWidth)]=tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					if (!textureGrowDownX && !textureGrowDownY)
					{
						offsetTextureY=(oldTextureUpLeftCornerY-textureUpLeftCornerY);
						offsetTextureX=(oldTextureUpLeftCornerX-textureUpLeftCornerX);
						for(j=0;j<oldTextureHeight;j++)
							for(i=0;i<oldTextureWidth;i++)
								textureBuffer[(long)(i+offsetTextureX+(j+offsetTextureY)*textureWidth)]=tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					free(tempTextureBuffer);
					tempTextureBuffer = 0L;
				}
					
				oldTextureWidth = textureWidth;
				oldTextureHeight = textureHeight;	
				tempTextureBuffer = malloc(textureWidth*textureHeight*sizeof(unsigned char));
				
				//NSLog(@"mouseRoiDragged - textureDownRightCornerX-textureUpLeftCornerX=%0.2f",textureDownRightCornerX-textureUpLeftCornerX);
				//NSLog(@"mouseRoiDragged - textureWidth=(ceil(textureDownRightCornerX-textureUpLeftCornerX))=%0.2f",(ceil(textureDownRightCornerX-textureUpLeftCornerX)));
				
				unsigned char	val;
				
				if (![curView eraserFlag]) val = 0xFF;
				else val = 0x00;
				
				if( modifier & NSCommandKeyMask && !(modifier & NSShiftKeyMask))
				{
					if( val == 0xFF) val = 0;
					else val = 0xFF;
				}
				
				long			size, *xPoints, *yPoints;
				
				if( previousPoint.x == -1000 && previousPoint.y == -1000) previousPoint = pt;
				
				int intThickness = thickness;
				
				unsigned char	*brush = calloc( intThickness*2*intThickness*2, sizeof( unsigned char));
				
				[ROI fillCircle: brush :intThickness*2 :0xFF];

				size = BresLine(	previousPoint.x,
									previousPoint.y,
									pt.x,
									pt.y,
									&xPoints,
									&yPoints);
				
				for( x = 0 ; x < size; x++)
				{
					long xx = xPoints[ x];
					long yy = yPoints[ x];
							
					for ( j =- intThickness; j < intThickness; j++)
					{
						for ( i =- intThickness; i < intThickness; i++)
						{
							if( xx+j > textureUpLeftCornerX && xx+j < textureDownRightCornerX)
							{
								if( yy+i > textureUpLeftCornerY && yy+i < textureDownRightCornerY)
								{
									if( brush[ (j + intThickness) + (i + intThickness)*intThickness*2] != 0)
										textureBuffer[(i+( xx - textureUpLeftCornerX) + textureWidth*(j+( yy - textureUpLeftCornerY)))] = val;
								}
							}
						}
					}
				}
				
				free( brush);
				
				free( xPoints);
				free( yPoints);
				
				previousPoint = pt;
				
				
				
				action = YES;
				
				rtotal = -1;
				Brtotal = -1;
			break;
			
			case ROI_selected:
				action = NO;
				break;
		}
	}	
	else if( type == tOval || type == tROI)
	{
		switch( mode)
		{
			case ROI_drawing:
				rect.size.width = pt.x - rect.origin.x;
				rect.size.height = pt.y - rect.origin.y;
				
				if( modifier & NSShiftKeyMask) rect.size.width = rect.size.height;
					
					rtotal = -1;
				Brtotal = -1;
				action = YES;
				break;
				
			case ROI_selected:
				action = NO;
				break;
				
			case ROI_selectedModify:
				rtotal = -1;
				Brtotal = -1;
				if( type == tROI)
				{
					NSPoint leftUp, rightUp, leftDown, rightDown;
					
					leftUp.x = rect.origin.x;
					leftUp.y = rect.origin.y;
					
					rightUp.x = rect.origin.x + rect.size.width;
					rightUp.y = rect.origin.y;
					
					leftDown.x = rect.origin.x;
					leftDown.y = rect.origin.y + rect.size.height;
					
					rightDown.x = rect.origin.x + rect.size.width;
					rightDown.y = rect.origin.y + rect.size.height;
					
					switch( selectedModifyPoint)
					{
						case 1: leftUp = pt;		rightUp.y = pt.y;		leftDown.x = pt.x;		break;
						case 4: rightUp = pt;		leftUp.y = pt.y;		rightDown.x = pt.x;		break;
						case 3: rightDown = pt;		rightUp.x = pt.x;		leftDown.y = pt.y;		break;
						case 2: leftDown = pt;		leftUp.x = pt.x;		rightDown.y = pt.y;		break;
					}
					
					rect = NSMakeRect( leftUp.x, leftUp.y, (rightDown.x - leftUp.x), (rightDown.y - leftUp.y));
					
					action = YES;
				}
				else  // tOval
				{
					rect.size.height = pt.y - rect.origin.y;
					rect.size.width = ( modifier & NSShiftKeyMask) ? rect.size.height : pt.x - rect.origin.x;
					
					action = YES;
				}
				break;
		}
	}
	else if( type == tPencil )
	{
		switch( mode)
		{
			case ROI_drawing:
			if( [[points lastObject] isNearToPoint: pt : scale/thickness :[[curView curDCM] pixelRatio]] == NO)
			{
				MyPoint *mypt = [[MyPoint alloc] initWithPoint: pt];
			
				[points addObject: mypt];
			
				[mypt release];
			
				clickPoint = pt;
			
			//	[[points lastObject] setPoint: pt];
				rtotal = -1;
				Brtotal = -1;
				action = YES;
			}
			break;
			
			case ROI_selected:
				action = NO;
			break;
			
			case ROI_selectedModify:
				[[points objectAtIndex: selectedModifyPoint] setPoint: pt];
				rtotal = -1;
				Brtotal = -1;
				action = YES;
			break;
		}
	}
	else
	{
		switch( mode)
		{
			case ROI_drawing:
				[[points lastObject] setPoint: pt];
				rtotal = -1;
				Brtotal = -1;
				action = YES;
			break;
			
			case ROI_selected:
				action = NO;
			break;
			
			case ROI_selectedModify:
				[[points objectAtIndex: selectedModifyPoint] setPoint: pt];
				rtotal = -1;
				Brtotal = -1;
				action = YES;
			break;
		}
	}
	
	[self valid];
	
	if( action) [[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	
	return action;
}

- (NSString*) name {return name;}
- (void) setName:(NSString*) a
{
	if( name != a)
	{
		[name release]; name = [a retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	}
	
	if( type == tText || type == t2DPoint)
	{
		if (stringTex) [stringTex setString:name withAttributes:stanStringAttrib];
		else
		{
			stringTex = [[StringTexture alloc] initWithString:name withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:color.red / 65535. green:color.green / 65535. blue:color.blue / 65535. alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
			[stringTex setAntiAliasing: YES];
		}
		
		rect.size = [stringTex frameSize];
	}	
}
- (NSString*) comments {return comments;}
- (void) setComments:(NSString*) a
{
	if( a != comments)
	{
		[comments release];
		comments = [a retain];
	}
}
- (RGBColor) rgbcolor {return color;}

- (void) setColor:(RGBColor) a
{
	color = a;
	if( type == tText)
	{
		[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROITextColorR"];
		[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROITextColorG"];
		[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROITextColorB"];
	}
	else if( type == tPlain)
	{
		[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROIRegionColorR"];
		[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROIRegionColorG"];
		[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROIRegionColorB"];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROIColorR"];
		[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROIColorG"];
		[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROIColorB"];
	}
}

- (float) thickness {return thickness;}
- (void) setThickness:(float) a
{
	thickness = a;
	
	if( type == tPlain)
	{
		[[NSUserDefaults standardUserDefaults] setFloat:thickness forKey:@"ROIRegionThickness"];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setFloat:thickness forKey:@"ROIThickness"];
		
		if( type == tText)
		{
			[stanStringAttrib release];
			
			// init fonts for use with strings
			NSFont * font =[NSFont fontWithName:@"Helvetica" size: 12.0 + thickness*2];
			stanStringAttrib = [[NSMutableDictionary dictionary] retain];
			[stanStringAttrib setObject:font forKey:NSFontAttributeName];
			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			[self setName:name];
		}
	}
}

- (void) setROIMode :(long) v
{
	mode = v;
}

- (long) ROImode { return mode;}

- (BOOL) deleteSelectedPoint
{
	switch( type)
	{
		case tPlain:
			return NO;
			break;
		case tText:
		case t2DPoint:
		case tOval:
		case tROI:
			rect.size.width = 0;
			rect.size.height = 0;
		break;
		
		case tMesure:
		case tArrow:
		case tCPolygon:
		case tOPolygon:
		case tPencil:
			if( mode == ROI_selectedModify) [points removeObjectAtIndex: selectedModifyPoint];
			else [points removeLastObject];
			
			if( selectedModifyPoint >= [points count]) selectedModifyPoint = [points count]-1;
		break;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	
	return [self valid];
}


-(float) MesureLength:(float*) pixels
{
	float val = [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]];
	
	if( pixels)
	{
		if( pixelSpacingX != 0)
		{
			float mesureLength = val;
			
			mesureLength *= 10.0;
			mesureLength /= pixelSpacingX;
			
			*pixels = mesureLength;
		}
		else *pixels = val;
	}
	
	return val;
}

- (void) setMousePosMeasure:(float) p
{
	mousePosMeasure = p;
}


static int roundboxtype= 15;

void gl_round_box(int mode, float minx, float miny, float maxx, float maxy, float rad)
{
	 float vec[7][2]= {{0.195, 0.02}, {0.383, 0.067}, {0.55, 0.169}, {0.707, 0.293},
					   {0.831, 0.45}, {0.924, 0.617}, {0.98, 0.805}};
	 int a;
	 
	 /* mult */
	 for(a=0; a<7; a++) {
			 vec[a][0]*= rad; vec[a][1]*= rad;
	 }

	 glBegin(mode);

	 /* start with corner right-bottom */
	 if(roundboxtype & 4) {
			 glVertex2f( maxx-rad, miny);
			 for(a=0; a<7; a++) {
					 glVertex2f( maxx-rad+vec[a][0], miny+vec[a][1]);
			 }
			 glVertex2f( maxx, miny+rad);
	 }
	 else glVertex2f( maxx, miny);
	 
	 /* corner right-top */
	 if(roundboxtype & 2) {
			 glVertex2f( maxx, maxy-rad);
			 for(a=0; a<7; a++) {
					 glVertex2f( maxx-vec[a][1], maxy-rad+vec[a][0]);
			 }
			 glVertex2f( maxx-rad, maxy);
	 }
	 else glVertex2f( maxx, maxy);
	 
	 /* corner left-top */
	 if(roundboxtype & 1) {
			 glVertex2f( minx+rad, maxy);
			 for(a=0; a<7; a++) {
					 glVertex2f( minx+rad-vec[a][0], maxy-vec[a][1]);
			 }
			 glVertex2f( minx, maxy-rad);
	 }
	 else glVertex2f( minx, maxy);
	 
	 /* corner left-bottom */
	 if(roundboxtype & 8) {
			 glVertex2f( minx, miny+rad);
			 for(a=0; a<7; a++) {
					 glVertex2f( minx+vec[a][1], miny+rad-vec[a][0]);
			 }
			 glVertex2f( minx+rad, miny);
	 }
	 else glVertex2f( minx, miny);
	 
	 glEnd();
}

- (NSRect) findAnEmptySpaceForMyRect:(NSRect) dRect :(BOOL*) moved
{
	long				i;
	NSMutableArray		*rectArray = [curView rectArray];
	
	if( rectArray == 0L)
	{
		*moved = NO;
		return dRect;
	}
	
	long				direction = 0, maxRedo = [rectArray count] + 2;
	
	*moved = NO;
	
	dRect.origin.x += 8;
	dRect.origin.y += 8;
	
	for( i = 0; i < [rectArray count]; i++)
	{
		NSRect	curRect = [[rectArray objectAtIndex: i] rectValue];
		
		if( NSIntersectsRect( curRect, dRect))
		{
			NSRect interRect = NSIntersectionRect( curRect, dRect);
			
			interRect.size.height++;
			interRect.size.width++;
			
			NSPoint cInterRect = NSMakePoint( NSMidX( interRect), NSMidY( interRect));
			NSPoint cCurRect = NSMakePoint( NSMidX( curRect), NSMidY( curRect));
			
			if( direction)
			{
				if( direction == -1) dRect.origin.y -= interRect.size.height;
				else dRect.origin.y += interRect.size.height;
			}
			else
			{
				if( cInterRect.y < cCurRect.y)
				{
					dRect.origin.y -= interRect.size.height;
					direction = -1;
				}
				else
				{
					dRect.origin.y += interRect.size.height;
					direction = 1;
				}
			}
			
			if( maxRedo-- >= 0) i = -1;
			
			*moved = YES;
		}
	}
	
	if( *moved)
	{
		dRect.origin.x += 5;
	}
	
	[rectArray addObject: [NSValue valueWithRect: dRect]];
	
	return dRect;
}

- (BOOL) isTextualDataDisplayed
{
	// NO text for Calcium Score
	if (_displayCalciumScoring)
		return NO;
		
	BOOL drawTextBox = NO;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ROITEXTIFSELECTED"] == NO || mode == ROI_selected)
	{
		drawTextBox = YES;
	}
	
	if( mode == ROI_selectedModify || mode == ROI_drawing)
	{
		if(	type == tOPolygon ||
			type == tCPolygon ||
			type == tPencil ||
			type == tPlain) drawTextBox = NO;
			
	}

	return drawTextBox;
}

- (void) drawTextualData
{
	if( [self isTextualDataDisplayed])
	{
		if( type != tText)
		{
			//glEnable(GL_POLYGON_SMOOTH);
			glEnable(GL_BLEND);
			glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
			
			if( mode == ROI_sleep) glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
			else glColor4f(0.3f, 0.0f, 0.0f, 0.8f);
			
			glLoadIdentity();
			
			glScalef( 2.0f /([curView frame].size.width), -2.0f / ([curView frame].size.height), 1.0f);
			
			gl_round_box(GL_POLYGON, drawRect.origin.x, drawRect.origin.y-1, drawRect.origin.x+drawRect.size.width, drawRect.origin.y+drawRect.size.height, 3);
			
			NSPoint tPt;
			
			tPt.x = drawRect.origin.x + 4;
			tPt.y = drawRect.origin.y + (12 + 2);
			
			long line = 0;
			
			[self glStr: (unsigned char*)line1 : tPt.x : tPt.y : line];	if( line1[0]) line++;
			[self glStr: (unsigned char*)line2 : tPt.x : tPt.y : line];	if( line2[0]) line++;
			[self glStr: (unsigned char*)line3 : tPt.x : tPt.y : line];	if( line3[0]) line++;
			[self glStr: (unsigned char*)line4 : tPt.x : tPt.y : line];	if( line4[0]) line++;
			[self glStr: (unsigned char*)line5 : tPt.x : tPt.y : line];	if( line5[0]) line++;
			
			//glDisable(GL_POLYGON_SMOOTH);
			glDisable(GL_BLEND);
			
			[curView applyImageTransformation];
		}
	}
	else
	{
		drawRect = NSMakeRect(0, 0, 0, 0);
	}
}

- (void) prepareTextualData:( char*) l1 :( char*) l2 :( char*) l3 :( char*) l4 :( char*) l5 location:(NSPoint) tPt
{
	long		maxWidth = 0, line;
	NSPoint		origin, ctPt = tPt;
	
	tPt = [curView ConvertFromGL2View: ctPt];
	origin = tPt;
	
	ctPt.x += offsetTextBox_x;
	ctPt.y += offsetTextBox_y;
	
	tPt = [curView ConvertFromGL2View: ctPt];
	drawRect.origin = tPt;
	
	line = 0;
	maxWidth = [self maxStringWidth:l1 max: maxWidth];	if( l1[0]) line++;
	maxWidth = [self maxStringWidth:l2 max: maxWidth];	if( l2[0]) line++;
	maxWidth = [self maxStringWidth:l3 max: maxWidth];	if( l3[0]) line++;
	maxWidth = [self maxStringWidth:l4 max: maxWidth];	if( l4[0]) line++;
	maxWidth = [self maxStringWidth:l5 max: maxWidth];	if( l5[0]) line++;
	
	drawRect.size.height = line * 12 + 4;
	drawRect.size.width = maxWidth + 8;
	
	BOOL moved;
	
	if( type == tCPolygon || type == tOPolygon || type == tPencil)
	{
		float ymin = [[points objectAtIndex:0] y];
		
		tPt.y = [[points objectAtIndex: 0] y];
		tPt.x = [[points objectAtIndex: 0] x];
		
		long i;
		
		for( i = 0; i < [points count]; i++)
		{
			if( [[points objectAtIndex:i] y] > ymin)
			{
				ymin = [[points objectAtIndex:i] y];
				tPt.y = [[points objectAtIndex:i] y];
				tPt.x = [[points objectAtIndex:i] x];
			}
		}
		
		ctPt = tPt;
		
		tPt = [curView ConvertFromGL2View: ctPt];
		origin = tPt;
		
		tPt = ctPt;
		tPt.x += offsetTextBox_x;
		tPt.y += offsetTextBox_y;
		
		tPt = [curView ConvertFromGL2View: tPt];
		drawRect.origin = tPt;
	}
	
	drawRect = [self findAnEmptySpaceForMyRect: drawRect : &moved];
	
	if( type == tCPolygon || type == tOPolygon || type == tPencil) moved = YES;
	
//	if( fabs( offsetTextBox_x) > 0 || fabs( offsetTextBox_y) > 0) moved = NO;
	
	if( moved && ![curView suppressLabels])	// Draw bezier line
	{
		glLoadIdentity();
		glScalef( 2.0f /([curView frame].size.width), -2.0f / ([curView frame].size.height), 1.0f);
		
		GLfloat ctrlpoints[4][3];
		
		const int OFF = 30;
		
		ctrlpoints[0][0] = NSMinX( drawRect);				ctrlpoints[0][1] = NSMidY( drawRect);							ctrlpoints[0][2] = 0;
		ctrlpoints[1][0] = origin.x - OFF;					ctrlpoints[1][1] = origin.y;									ctrlpoints[1][2] = 0;
		ctrlpoints[2][0] = origin.x;						ctrlpoints[2][1] = origin.y;									ctrlpoints[2][2] = 0;
		
		glLineWidth( 3.0);
		if( mode == ROI_sleep) glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
		else glColor4f(0.3f, 0.0f, 0.0f, 0.8f);
		
		glMap1f(GL_MAP1_VERTEX_3, 0.0, 1.0, 3, 3,&ctrlpoints[0][0]);
		glEnable(GL_MAP1_VERTEX_3);
		
	    glBegin(GL_LINE_STRIP);
		int i;
        for (i = 0; i <= 30; i++) 
            glEvalCoord1f((GLfloat) i/30.0);
		glEnd();
		glDisable(GL_MAP1_VERTEX_3);
		
		glLineWidth( 1.0);
		
		glColor4f( 1.0, 1.0, 1.0, 0.5);
		
		glMap1f(GL_MAP1_VERTEX_3, 0.0, 1.0, 3, 3,&ctrlpoints[0][0]);
		glEnable(GL_MAP1_VERTEX_3);
		
	    glBegin(GL_LINE_STRIP);
        for (i = 0; i <= 30; i++) 
            glEvalCoord1f((GLfloat) i/30.0);
		glEnd();
		glDisable(GL_MAP1_VERTEX_3);
		
		[curView applyImageTransformation];
	}
}

- (NSString*) description
{
	float mean = 0, min = 0, max = 0, total = 0, dev = 0;
	
	[pix computeROI:self :&mean :&total :&dev :&min :&max];
	
	return [NSString stringWithFormat:@"%@	%.3f	%.3f	%.3f	%.3f	%.3f", name, mean, min, max, total, dev];
}

- (void) drawROI :(float) scaleValue :(float) offsetx :(float) offsety :(float) spacingX :(float) spacingY
{
	long	i;
	
	if( fontListGL == -1) NSLog(@"ERROR: fontListGL == -1 !");
	if( curView == 0L) NSLog(@"ERROR: curView == 0L !");
	
	pixelSpacingX = spacingX;
	pixelSpacingY = spacingY;
	
	float screenXUpL,screenYUpL,screenXDr,screenYDr; // for tPlain ROI
	
    glEnable(GL_POINT_SMOOTH);
    glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

	switch( type)
	{
	
		case tLayerROI:
		{
			if(layerImage)
			{
				NSSize imageSize = [layerImage size];
				float imageWidth = imageSize.width;
				float imageHeight = imageSize.height;
				
				glDisable(GL_POLYGON_SMOOTH);
				glEnable(GL_TEXTURE_RECTANGLE_EXT);

				if(layerImageWhenSelected && mode==ROI_selected)
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName2);
				else
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
									
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				
				glTranslatef(layerTranslation.x*scaleValue, layerTranslation.y*scaleValue, 0.0f);	
		
				screenXUpL = (layerUpperLeftCornerPosition.x-offsetx)*scaleValue;
				screenYUpL = (layerUpperLeftCornerPosition.y-offsety)*scaleValue;
				screenXDr = (layerLowerRightCornerPosition.x-offsetx)*scaleValue;
				screenYDr = (layerLowerRightCornerPosition.y-offsety)*scaleValue;

				NSPoint center = NSMakePoint((layerRotationCenter.x-offsetx)*scaleValue,(layerRotationCenter.y-offsety)*scaleValue);
				
				NSPoint screenUpL = NSMakePoint(screenXUpL, screenYUpL);
				screenUpL = [self rotatePoint:screenUpL withAngle:-layerRotationAngle aroundCenter:center];
				screenXUpL = screenUpL.x;
				screenYUpL = screenUpL.y;
				
				NSPoint screenDr = NSMakePoint(screenXDr, screenYDr);
				screenDr = [self rotatePoint:screenDr withAngle:-layerRotationAngle aroundCenter:center];
				screenXDr = screenDr.x;
				screenYDr = screenDr.y;
				
				NSPoint p1, p2, p3, p4;
				p1 = layerUpperLeftCornerPosition;
				p2 = layerLowerRightCornerPosition;
				p3 = NSMakePoint(layerUpperLeftCornerPosition.x,layerLowerRightCornerPosition.y);
				p4 = NSMakePoint(layerLowerRightCornerPosition.x,layerUpperLeftCornerPosition.y);
				
				p1.x = (p1.x-offsetx)*scaleValue;
				p1.y = (p1.y-offsety)*scaleValue;
				p2.x = (p2.x-offsetx)*scaleValue;
				p2.y = (p2.y-offsety)*scaleValue;
				p3.x = (p3.x-offsetx)*scaleValue;
				p3.y = (p3.y-offsety)*scaleValue;
				p4.x = (p4.x-offsetx)*scaleValue;
				p4.y = (p4.y-offsety)*scaleValue;
							
				p1 = [self rotatePoint:p1 withAngle:layerRotationAngle aroundCenter:center];
				p2 = [self rotatePoint:p2 withAngle:layerRotationAngle aroundCenter:center];
				p3 = [self rotatePoint:p3 withAngle:layerRotationAngle aroundCenter:center];
				p4 = [self rotatePoint:p4 withAngle:layerRotationAngle aroundCenter:center];

				
				glBegin(GL_QUAD_STRIP); // draw either tri strips of line strips (so this will drw either two tris or 3 lines)
					glTexCoord2f(0, 0); // draw upper left in world coordinates
					glVertex3d(p1.x, p1.y, 0.0);
					
					glTexCoord2f(imageWidth, 0); // draw lower left in world coordinates
					glVertex3d(p4.x, p4.y, 0.0);
					
					glTexCoord2f(0, imageHeight); // draw upper right in world coordinates
					glVertex3d(p3.x, p3.y, 0.0);
					
					glTexCoord2f(imageWidth, imageHeight); // draw lower right in world coordinates
					glVertex3d(p2.x, p2.y, 0.0);
				glEnd();

				glTranslatef(-layerTranslation.x*scaleValue, -layerTranslation.y*scaleValue, 0.0f);

				glDisable(GL_TEXTURE_RECTANGLE_EXT);
				glEnable(GL_POLYGON_SMOOTH);
			}
		}
		break;
		
		case tPlain:
		//	if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
		{
			//	NSLog(@"drawROI - tPlain, mode=%i, (ROI_sleep = 0,ROI_drawing = 1,ROI_selected = 2,	ROI_selectedModify = 3)",mode);
			// test to display something !
			// init
			screenXUpL = (textureUpLeftCornerX-offsetx)*scaleValue;
			screenYUpL = (textureUpLeftCornerY-offsety)*scaleValue;
			screenXDr = screenXUpL + textureWidth*scaleValue;
			screenYDr = screenYUpL + textureHeight*scaleValue;

		//	screenXDr = (textureDownRightCornerX-offsetx)*scaleValue;
		//	screenYDr = (textureDownRightCornerY-offsety)*scaleValue;
			
			glDisable(GL_POLYGON_SMOOTH);
			glEnable(GL_TEXTURE_RECTANGLE_EXT);
			
			//for( i = 0; i < textureWidth*textureHeight;i++) textureBuffer[ i] = i;
			
			if( textureName)
				glDeleteTextures (1, &textureName);
			
		//	NSLog( @"%d", textureWidth);
			
			glPixelStorei (GL_UNPACK_ROW_LENGTH, textureWidth);
			
			glGenTextures (1, &textureName);
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
			
			glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
			
			glBlendEquation(GL_FUNC_ADD);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			glTexImage2D (GL_TEXTURE_RECTANGLE_EXT, 0, GL_INTENSITY8, textureWidth, textureHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, textureBuffer);
			
			glBegin (GL_QUAD_STRIP); // draw either tri strips of line strips (so this will drw either two tris or 3 lines)
			glTexCoord2f (0, 0); // draw upper left in world coordinates
			glVertex3d (screenXUpL, screenYUpL, 0.0);
			
			glTexCoord2f (textureWidth, 0); // draw lower left in world coordinates
			glVertex3d (screenXDr, screenYUpL, 0.0);
			
			glTexCoord2f (0, textureHeight); // draw upper right in world coordinates
			glVertex3d (screenXUpL, screenYDr, 0.0);
			
			glTexCoord2f (textureWidth, textureHeight); // draw lower right in world coordinates
			glVertex3d (screenXDr, screenYDr, 0.0);
			glEnd();
			
			glDisable(GL_TEXTURE_RECTANGLE_EXT);
			glEnable(GL_POLYGON_SMOOTH);
			
			switch( mode)
			{
				case 	ROI_drawing:
				case 	ROI_selected:
				case 	ROI_selectedModify:
					glColor3f (0.5f, 0.5f, 1.0f);
					//smaller points for calcium scoring
					if (_displayCalciumScoring)
						glPointSize( 3.0);
					else
						glPointSize( 8.0);
					glBegin(GL_POINTS);
					glVertex3f(screenXUpL, screenYUpL, 0.0);
					glVertex3f(screenXDr, screenYUpL, 0.0);
					glVertex3f(screenXUpL, screenYDr, 0.0);
					glVertex3f(screenXDr, screenYDr, 0.0);
					glEnd();
				break;
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
			if( [self isTextualDataDisplayed])
			{
				NSPoint tPt = [self lowerRightPoint];
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
				
				if ( [[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTNAMEONLY"] == NO ) {
					if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
					
					float area = [self plainArea];

					if (!_displayCalciumScoring) {
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if( area*pixelSpacingX*pixelSpacingY < 1. )
								sprintf (line2, "A: %0.1f %cm2", area*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", area*pixelSpacingX*pixelSpacingY/100.);
						}
						else
							sprintf (line2, "Area: %0.3f pix2", area);
						
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
					}
					else {
						sprintf (line2, "Calcium Score: %0.1f", [self calciumScore]);
						sprintf (line3, "Calcium Volume: %0.1f", [self calciumVolume]);
						sprintf (line4, "Calcium Mass: %0.1f", [self calciumMass]);
					}
				}
				//if (!_displayCalciumScoring)
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
			}
		}
		break;
		
		case t2DPoint:
		{
			float angle;
			
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			glBegin(GL_LINE_LOOP);
			for(i = 0; i < CIRCLERESOLUTION ; i++)
			{
			  // M_PI defined in cmath.h
			  angle = i * 2 * M_PI /CIRCLERESOLUTION;
			  
			  glVertex2f( (rect.origin.x - offsetx)*scaleValue + 8*cos(angle), (rect.origin.y - offsety)*scaleValue + 8*sin(angle)*pixelSpacingX/pixelSpacingY);
			}
			glEnd();
			
			if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing) glColor4f (0.5f, 0.5f, 1.0f, opacity);
			else glColor4f (1.0f, 0.0f, 0.0f, opacity);
			
			glPointSize( thickness * 3);
			glBegin( GL_POINTS);
			glVertex2f(  (rect.origin.x  - offsetx)*scaleValue, (rect.origin.y  - offsety)*scaleValue);
			glEnd();
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
			if( [self isTextualDataDisplayed])
			{
				NSPoint tPt = [self lowerRightPoint];
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ROITEXTNAMEONLY"] == NO )
				{
					if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
//					if( [curView blendingView])		Sadly this doesn't work AT ALL ! Antoine
//					{
//						if( Brtotal == -1)
//						{
//							DCMPix	*blendedPix = [[curView blendingView] curDCM];
//							
//							[self setOriginAndSpacing:[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :NSMakePoint( [blendedPix originX], [blendedPix originY]) :NO];
//							[blendedPix computeROI:self :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
//							[self setOriginAndSpacing:[[curView curDCM] pixelSpacingX] :[[curView curDCM] pixelSpacingY] :NSMakePoint( [[curView curDCM] originX], [[curView curDCM] originY]) :NO];
//						}
//					}
					
					sprintf (line2, "Val: %0.3f", rmean);
					if( Brtotal != -1) sprintf (line3, "Fused Val: %0.3f", Brmean);
					
					sprintf (line4, "2D Pos: X:%0.3f px Y:%0.3f px", rect.origin.x, rect.origin.y);
					
					float location[ 3 ];
					[[curView curDCM] convertPixX: rect.origin.x pixY: rect.origin.y toDICOMCoords: location];
					if(fabs(location[0]) < 1.0 && location[0] != 0.0)
						sprintf (line5, "3D Pos: X:%0.1f %cm Y:%0.1f %cm Z:%0.1f %cm", location[0] * 1000.0, 0xB5, location[1] * 1000.0, 0xB5, location[2] * 1000.0, 0xB5);
					else
						sprintf (line5, "3D Pos: X:%0.3f mm Y:%0.3f mm Z:%0.3f mm", location[0], location[1], location[2]);
				}
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
			}
		}
		break;
		
		case tText:
			if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( 2.0 * 3);
				glBegin( GL_POINTS);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue - rect.size.width/2, (rect.origin.y - offsety)*scaleValue - rect.size.height/2);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue - rect.size.width/2, (rect.origin.y - offsety)*scaleValue + rect.size.height/2);
				glVertex2f(  (rect.origin.x- offsetx)*scaleValue + rect.size.width/2, (rect.origin.y - offsety)*scaleValue + rect.size.height/2);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue + rect.size.width/2, (rect.origin.y - offsety)*scaleValue - rect.size.height/2);
				glEnd();
			}
			
//			glLineWidth(1.0);
			
			
			NSPoint tPt = [self lowerRightPoint];
			tPt.x = (tPt.x - offsetx)*scaleValue  - rect.size.width/2;		tPt.y = (tPt.y - offsety)*scaleValue - rect.size.height/2;
			
			GLint matrixMode;
			
			glEnable (GL_TEXTURE_RECTANGLE_EXT);
			
			glEnable(GL_BLEND);
			if( opacity > 0.5) opacity = 1.0;
			if( opacity == 1.0) glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			else glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			
			glColor4f (0, 0, 0, opacity);
			[stringTex drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+1)];
			
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			if( stringTex == 0L) [self setName: name];
			[stringTex drawAtPoint:tPt];
			
			glDisable (GL_TEXTURE_RECTANGLE_EXT);
			
			glColor3f (1.0f, 1.0f, 1.0f);
		break;
		
		case tMesure:
		case tArrow:
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			glLineWidth(thickness);
			
			if( type == tArrow)
			{
				NSPoint a, b, c;
				float   slide, adj, op, angle;
				
				a.x = ([[points objectAtIndex: 0] x]- offsetx) * scaleValue;
				a.y = ([[points objectAtIndex: 0] y]- offsety) * scaleValue;
				
				b.x = ([[points objectAtIndex: 1] x]- offsetx) * scaleValue;
				b.y = ([[points objectAtIndex: 1] y]- offsety) * scaleValue;
				
				if( (b.y-a.y) == 0) slide = (b.x-a.x)/-0.001;
				else slide = (b.x-a.x)/(b.y-a.y);
				
				#define ARROWSIZE 30.0
				
				// LINE
				angle = 90 - atan( slide)/deg2rad;
				adj = (ARROWSIZE + thickness * 13)  * cos( angle*deg2rad);
				op = (ARROWSIZE + thickness * 13) * sin( angle*deg2rad);
				glBegin(GL_LINE_STRIP);
					if(b.y-a.y > 0) glVertex2f( a.x + adj, a.y + op);
					else glVertex2f( a.x - adj, a.y - op);
					glVertex2f( b.x, b.y);
				glEnd();
				
				// ARROW
				glBegin(GL_TRIANGLES);
								
				if(b.y-a.y > 0) 
				{
					angle = atan( slide)/deg2rad;
					
					angle = 80 - angle - thickness;
					adj = (ARROWSIZE + thickness * 15)  * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					glVertex2f( a.x + adj, a.y + op);
					
					angle = atan( slide)/deg2rad;
					angle = 100 - angle + thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					glVertex2f( a.x + adj, a.y + op);
				}
				else
				{
					angle = atan( slide)/deg2rad;
					
					angle = 180 + 80 - angle - thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					glVertex2f( a.x + adj, a.y + op);

					angle = atan( slide)/deg2rad;
					angle = 180 + 100 - angle + thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					glVertex2f( a.x + adj, a.y + op);
				}
				glVertex2f( a.x , a.y );
				glEnd();
			}
			else
			{
				glBegin(GL_LINE_STRIP);
				for( i = 0; i < [points count]; i++)
				{
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
				}
				glEnd();
			}
			
			if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
				for( i = 0; i < [points count]; i++)
				{
					if( mode == ROI_selectedModify && i == selectedModifyPoint) glColor3f (1.0f, 0.2f, 0.2f);
					
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
					
					if( mode == ROI_selectedModify && i == selectedModifyPoint) glColor3f (0.5f, 0.5f, 1.0f);
				}
				glEnd();
			}
			
			if( mousePosMeasure != -1)
			{
				NSPoint	pt = NSMakePoint( [[points objectAtIndex: 0] x], [[points objectAtIndex: 0] y]);
				float	theta, pyth;
				
				theta = atan( ([[points objectAtIndex: 1] y] - [[points objectAtIndex: 0] y]) / ([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]));
				
				pyth =	([[points objectAtIndex: 1] y] - [[points objectAtIndex: 0] y]) * ([[points objectAtIndex: 1] y] - [[points objectAtIndex: 0] y]) +
						([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]) * ([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]);
				pyth = sqrt( pyth);
				
				if( ([[points objectAtIndex: 1] x] - [[points objectAtIndex: 0] x]) < 0)
				{
					pt.x -= (mousePosMeasure * ( pyth)) * cos( theta);
					pt.y -= (mousePosMeasure * ( pyth)) * sin( theta);
				}
				else
				{
					pt.x += (mousePosMeasure * ( pyth)) * cos( theta);
					pt.y += (mousePosMeasure * ( pyth)) * sin( theta);
				}
				
				glColor3f (1.0f, 0.0f, 0.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
					glVertex2f( (pt.x - offsetx) * scaleValue , (pt.y - offsety) * scaleValue );
				glEnd();
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
			if( [self isTextualDataDisplayed])
			{
				NSPoint tPt = [self lowerRightPoint];
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
				if( type == tMesure &&[[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTNAMEONLY"] == NO) {
					if( pixelSpacingX != 0 && pixelSpacingY != 0) {
						if ([self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]] < .1)
							sprintf (line2, "L: %0.1f %cm", [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]] * 10000.0, 0xb5);
						else
							sprintf (line2, "Length: %0.3f cm", [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]]);
					}
					else
						sprintf (line2, "Length: %0.3f pix", [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]]);
				}
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
			}
		break;
		
		case tROI:
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			glLineWidth(thickness);
			glBegin(GL_LINE_LOOP);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
			glEnd();
			
			if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glEnd();
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			{
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
				if( [self isTextualDataDisplayed])
				{
					NSPoint			tPt = [self lowerRightPoint];
					long			line = 0;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
					else line1[ 0] = 0;
					
					if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ROITEXTNAMEONLY"] == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if ( fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY) < 1.)
								sprintf (line2, "A: %0.1f %cm2", fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY * 1000000.0), 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY/100.));
						}
						else
							sprintf (line2, "Area: %0.3f pix2", fabs( NSWidth(rect)*NSHeight(rect)));
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
				}
			}
		break;
		
		case tOval:
		{
			float angle;
			
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			glLineWidth(thickness);
			
			glBegin(GL_LINE_LOOP);
			for(i = 0; i < CIRCLERESOLUTION ; i++)
			{
			  // M_PI defined in cmath.h
			  angle = i * 2 * M_PI /CIRCLERESOLUTION;
			  
			  glVertex2f( (rect.origin.x + rect.size.width*cos(angle) - offsetx)*scaleValue, (rect.origin.y + rect.size.height*sin(angle)- offsety)*scaleValue);
			}
			glEnd();
			
			if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
				glVertex2f( (rect.origin.x - offsetx - rect.size.width) * scaleValue, (rect.origin.y - rect.size.height - offsety) * scaleValue);
				glVertex2f( (rect.origin.x - offsetx - rect.size.width) * scaleValue, (rect.origin.y + rect.size.height - offsety) * scaleValue);
				glVertex2f( (rect.origin.x + rect.size.width - offsetx) * scaleValue, (rect.origin.y + rect.size.height - offsety) * scaleValue);
				glVertex2f( (rect.origin.x + rect.size.width - offsetx) * scaleValue, (rect.origin.y - rect.size.height - offsety) * scaleValue);
				glEnd();
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
			if( [self isTextualDataDisplayed])
			{
				NSPoint			tPt = [self lowerRightPoint];
				long			line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ROITEXTNAMEONLY"] == NO ) {
					if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0)
					{
						if( [self EllipseArea]*pixelSpacingX*pixelSpacingY < 1.)
							sprintf (line2, "A: %0.1f %cm2", [self EllipseArea]*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5);
						else
							sprintf (line2, "Area: %0.3f cm2", [self EllipseArea]*pixelSpacingX*pixelSpacingY/100.);
					}
					else
						sprintf (line2, "Area: %0.3f pix2", [self EllipseArea]);
					
					sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
					sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
				}
				
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
			}
		}
		break;
		
		case tCPolygon:
		case tOPolygon:
		case tAngle:
		case tPencil:
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			if( mode == ROI_drawing) glLineWidth(thickness * 2);
			else glLineWidth(thickness);
			
			if( type == tCPolygon || type == tPencil)	glBegin(GL_LINE_LOOP);
			else										glBegin(GL_LINE_STRIP);
			
			for( i = 0; i < [points count]; i++)
			{
				glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
			}
			glEnd();
			
			// TEXT
			if( type == tCPolygon || type == tPencil)
			{
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
				if( [self isTextualDataDisplayed])
				{
					NSPoint tPt = [self lowerRightPoint];
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
					
					if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ROITEXTNAMEONLY"] == NO ) {
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if([self Area] *pixelSpacingX*pixelSpacingY < 1.)
								sprintf (line2, "A: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
						}
						else
							sprintf (line2, "Area: %0.3f pix2", [self Area]);
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						
						length = 0;
						for( i = 0; i < [points count]-1; i++ ) {
							length += [self Length:[[points objectAtIndex:i] point] :[[points objectAtIndex:i+1] point]];
						}
						length += [self Length:[[points objectAtIndex:i] point] :[[points objectAtIndex:0] point]];
						
						if (length < .1)
							sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
						else
							sprintf (line5, "Length: %0.3f cm", length);
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
				}
			}
			else if( type == tOPolygon)
			{
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
				if( [self isTextualDataDisplayed])
				{
					NSPoint tPt = [self lowerRightPoint];
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
					
					if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ROITEXTNAMEONLY"] == NO ) {
						
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if ([self Area] *pixelSpacingX*pixelSpacingY < 1.)
								sprintf (line2, "A: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
						}
						else
							sprintf (line2, "Area: %0.3f pix2", [self Area]);
						
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						
						length = 0;
						for( i = 0; i < [points count]-1; i++ ) {
							length += [self Length:[[points objectAtIndex:i] point] :[[points objectAtIndex:i+1] point]];
						}
						
						if (length < .1)
							sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
						else
							sprintf (line5, "Length: %0.3f cm", length);
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
				}
			}
			else if( type == tAngle)
			{
				if( [points count] == 3)
				{
					line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
					if( [self isTextualDataDisplayed])
					{
						NSPoint tPt = [self lowerRightPoint];
						long	line = 0;
						float   angle;
						
						if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name cString]);
						
						angle = [self Angle:[[points objectAtIndex: 0] point] :[[points objectAtIndex: 1] point] : [[points objectAtIndex: 2] point]];
						
						sprintf (line2, "Angle: %0.3f / %0.3f", angle, 360 - angle);
						
						[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
					}
				}
			}
			
			if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
			{
				NSPoint tempPt = [[[[NSApp currentEvent] window] contentView] convertPoint: [NSEvent mouseLocation] toView: curView];
				tempPt.y = [curView frame].size.height - tempPt.y ;
				tempPt = [curView ConvertFromView2GL:tempPt];
				
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
				for( i = 0; i < [points count]; i++)
				{
					if( mode == ROI_selectedModify && i == selectedModifyPoint) glColor3f (1.0f, 0.2f, 0.2f);
					else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/thickness :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
					else glColor3f (0.5f, 0.5f, 1.0f);
					
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
				}
				glEnd();
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
		break;
		
//		case tLayerROI:
//		{
//			
//		}
//		break;
	}
	
	glPointSize( 1.0);
	
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);
}

- (float*) dataValuesAsFloatPointer :(long*) no
{
	long				i;
	float				*data = 0L;
	
	switch(type)
	{
		case tMesure:
			data = [[curView curDCM] getLineROIValue:no :self];
		break;
		
		default:
			data = [[curView curDCM] getROIValue:no :self :0L];
		break;
	}
	
	return data;
}

- (NSMutableArray*) dataValues
{
	NSMutableArray*		array = [NSMutableArray arrayWithCapacity:0];
	long				no, i;
	float				*data;
	
	data = [self dataValuesAsFloatPointer: &no];
	
	if( data)
	{
		for( i = 0 ; i < no; i++)
		{
			[array addObject:[NSNumber numberWithFloat: data[ i]]];
		}
		
		free( data);
	}
	
	return array;
}


- (NSMutableDictionary*) dataString
{
	NSMutableDictionary*		array = 0L;
	long						i, length;
	NSMutableArray				*ptsTemp = [self points];
		
	switch( type)
	{
		case tOval:
		case tROI:
		case tCPolygon:
		case tOPolygon:
		case tPencil:
		case tPlain:
			array = [NSMutableDictionary dictionaryWithCapacity:0];
		
			if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
			
			if( type == tOval)
			{
				if( pixelSpacingX != 0 && pixelSpacingY != 0)   [array setObject: [NSNumber numberWithFloat:[self EllipseArea] *pixelSpacingX*pixelSpacingY / 100.] forKey:@"AreaCM2"];
				else [array setObject: [NSNumber numberWithFloat:[self EllipseArea]] forKey:@"AreaPIX2"];
			}
			else if( type == tROI)
			{
				if( pixelSpacingX != 0 && pixelSpacingY != 0)   [array setObject: [NSNumber numberWithFloat:NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY / 100.] forKey:@"AreaCM2"];
				else [array setObject: [NSNumber numberWithFloat:NSWidth(rect)*NSHeight(rect)] forKey:@"AreaPIX2"];
			}
			else
			{
				if( pixelSpacingX != 0 && pixelSpacingY != 0)   [array setObject: [NSNumber numberWithFloat:[self Area] *pixelSpacingX*pixelSpacingY / 100.] forKey:@"AreaCM2"];
				else [array setObject: [NSNumber numberWithFloat:[self Area]] forKey:@"AreaPIX2"];
			}
				
			[array setObject: [NSNumber numberWithFloat:rmean] forKey:@"Mean"];
			[array setObject: [NSNumber numberWithFloat:rdev] forKey:@"Dev"];
			[array setObject: [NSNumber numberWithFloat:rtotal] forKey:@"Total"];
			[array setObject: [NSNumber numberWithFloat:rmin] forKey:@"Min"];
			[array setObject: [NSNumber numberWithFloat:rmax] forKey:@"Max"];
			
			length = 0;
			for( i = 0; i < [ptsTemp count]-1; i++)
			{
				length += [self Length:[[ptsTemp objectAtIndex:i] point] :[[ptsTemp objectAtIndex:i+1] point]];
			}
			if( type != tOPolygon) length += [self Length:[[ptsTemp objectAtIndex:i] point] :[[ptsTemp objectAtIndex:0] point]];
			
			[array setObject: [NSNumber numberWithFloat:length] forKey:@"Length"];
		break;
		
		case tAngle:
		{
			array = [NSMutableDictionary dictionaryWithCapacity:0];
			
			float angle = [self Angle:[[points objectAtIndex: 0] point] :[[points objectAtIndex: 1] point] : [[points objectAtIndex: 2] point]];
			[array setObject: [NSNumber numberWithFloat:angle] forKey:@"Angle"];
		}
		break;
		
		case tMesure:
			array = [NSMutableDictionary dictionaryWithCapacity:0];
			
			length = [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]];
			[array setObject: [NSNumber numberWithFloat:length] forKey:@"Length"];
		break;
	}
	
	return array;
}

- (long)type {
	return type;
}

- (BOOL) needQuartz
{
	switch( type)
	{
		
		default: return NO; break;
	}
	
	return NO;
}

- (void) setRoiFont: (long) f :(long*) s :(DCMView*) v
{
	fontListGL = f;
	curView = v;
	fontSize = s;
}

- (float) roiArea
{
	if( pixelSpacingX == 0 && pixelSpacingY == 0 ) return 0;

	switch( type)
	{
		case tOPolygon:
		case tCPolygon:
		case tPencil:
			return ([self Area] *pixelSpacingX*pixelSpacingY) / 100.;
		break;
		
		case tROI:
			return NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY/100.;
		break;
		
		case tOval:
			return ([self EllipseArea]*pixelSpacingX*pixelSpacingY)/100.;
		break;
		case tPlain:
		{
			long i;
			float area=0.0;;
			for( i = 0; i < textureWidth*textureHeight;i++)
				if (textureBuffer[i]!=0) area++;;
				return (area*pixelSpacingX*pixelSpacingY)/100.;
		}
			break;
			
	}
	
	return 0.;
}

- (NSPoint) centroid {
	
	if ( type == tROI || type == tOval ) {
		return rect.origin;
	}
	
	int num_points = [points count];
	
	NSPoint centroid;
	int i;
	
	for ( i = 0; i < num_points; i++ ) {
		centroid.x += [[points objectAtIndex:i] x] / num_points;
		centroid.y += [[points objectAtIndex:i] y] / num_points;
	}
	
	return centroid;
}

//DICOM presentation State UID accessors
- (NSString *)roiSeriesInstanceUID{
	return _roiSeriesInstanceUID;
}

- (NSString *)sopInstanceUID{
	return _sopInstanceUID;
}

- (NSString *)referencedSOPInstanceUID{
	return _referencedSOPInstanceUID;
}

- (NSString *)referencedSOPClassUID{
	return _referencedSOPClassUID;
}

- (int) frameNumber{
	return _frameNumber;
}


- (void)setRoiSeriesInstanceUID:(NSString *)roiSeriesInstanceUID{
	[_roiSeriesInstanceUID release];
	_roiSeriesInstanceUID = [roiSeriesInstanceUID retain];
}

- (void)setSopInstanceUID:(NSString *)sopInstanceUID{
	[_sopInstanceUID release];
	_sopInstanceUID = [sopInstanceUID retain];
}

- (void)setReferencedSOPInstanceUID:(NSString *)referencedSOPInstanceUID{
	[_referencedSOPInstanceUID release];
	_referencedSOPInstanceUID = [referencedSOPInstanceUID retain];
}

- (void)setReferencedSOPClassUID:(NSString *)referencedSOPClassUID{
	[_referencedSOPClassUID release];
	_referencedSOPClassUID = [referencedSOPClassUID retain];
}

- (void)setFrameNumber: (int)frameNumber{
	_frameNumber = frameNumber;
}

- (void) addMarginToBuffer: (int) margin
{
	int newWidth = textureWidth + 2*margin;
	int newHeight = textureHeight + 2*margin;
	unsigned char* newBuffer = (unsigned char*)calloc(newWidth*newHeight, sizeof(unsigned char));
	
	if(newBuffer)
	{
		int i;
		for(i=0; i<margin; i++)
		{
			// skip the 'margin' first lines
			newBuffer += newWidth; 
		}
		
		unsigned char	*temptextureBuffer = textureBuffer;
		
		for(i=0; i<textureHeight; i++)
		{
			newBuffer += margin; // skip the left margin pixels
			memcpy( newBuffer,temptextureBuffer,textureWidth*sizeof(unsigned char));
			newBuffer += textureWidth+margin; // move to the next line, skipping the right margin pixels
			temptextureBuffer += textureWidth; // move to the next line
		}
		
		newBuffer -= textureHeight*(textureWidth+2*margin)+newWidth*margin; // beginning of the buffer
		
		if( textureBuffer) free( textureBuffer);
		textureBuffer = newBuffer;
		textureDownRightCornerX += margin;
		textureDownRightCornerY += margin;
		textureUpLeftCornerX -= margin;
		textureUpLeftCornerY -= margin;
		textureWidth = newWidth;
		textureHeight = newHeight;
	}
}

// parent ROI
- (ROI*) parentROI
{
	return parentROI;
}

- (void) setParentROI: (ROI*) aROI;
{
	if( aROI == parentROI) return;
	
	[parentROI release];
	
	parentROI = [aROI retain];
}


// Calcium Scoring
// Should we check to see if we using a brush ROI and other appropriate checks before return a calcium measurement?


- (int)calciumScoreCofactor{
	/* 
	Cofactor values used by Agaston.  
	Using a threshold of 90 rather than 130. Assuming
	multislice CT rather than electron beam.
	We could have a flag for Electron beam rather than multichannel CT
	and use 130 as a cutoff
	*/	
	if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	if (_calciumCofactor == 0)
		_calciumCofactor =  [[curView curDCM] calciumCofactorForROI:self threshold:_calciumThreshold];
	//NSLog(@"cofactor: %d", _calciumCofactor);
	return _calciumCofactor;

}

- (float)calciumScore{
	// roi Area * cofactor;  area is is mm2.
	//plainArea is number of pixels 
	// still to compensate for overlapping slices interval/sliceThickness
	
	if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	//area needs to be > 1 mm
	float intervalRatio = fabs([[curView curDCM] sliceInterval] / [[curView curDCM] sliceThickness]);
	if (intervalRatio > 1)
		intervalRatio = 1;
	float area = [self plainArea] * pixelSpacingX * pixelSpacingY;
	//if (area < 1)
	//	return 0;
	return area * [self calciumScoreCofactor] * intervalRatio ;   
}

- (float)calciumVolume{
	// area * thickeness
	//
	if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	float area = [self plainArea] * pixelSpacingX * pixelSpacingY;
	//if (area < 1)
	//	return 0;
	return area * [[curView curDCM] sliceThickness];
	//return [self roiArea] * [self thickness] * 100;
}
- (float)calciumMass{
	//Volume * mean CT Density / 250 
	if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	return fabs([self calciumVolume] * rmean)/ 250;
}
- (void)setDisplayCalciumScoring:(BOOL)value{
	_displayCalciumScoring = value;
}

- (void)setCalciumThreshold:(int)threshold{
	_calciumThreshold = threshold;
}

- (float) sliceThickness{
	return _sliceThickness;
}

- (void) setSliceThickness:(float)sliceThickness{
	_sliceThickness = sliceThickness;
}

- (void)setLayerReferenceFilePath:(NSString*)path;
{
	if(layerReferenceFilePath) [layerReferenceFilePath release];
	layerReferenceFilePath = path;
	[layerReferenceFilePath retain];
}

- (void)setLayerImage:(NSImage*)image;
{
	if(layerImage) [layerImage release];
	layerImage = image;
	[layerImage retain];
	
	layerLowerRightCornerPosition.x = layerUpperLeftCornerPosition.x + [image size].width;
	layerLowerRightCornerPosition.y = layerUpperLeftCornerPosition.y + [image size].height;

	layerRotationCenter.x = (layerLowerRightCornerPosition.x + layerUpperLeftCornerPosition.x) /2.0;
	layerRotationCenter.y = (layerLowerRightCornerPosition.y + layerUpperLeftCornerPosition.y) /2.0;
	
	NSSize imageSize = [layerImage size];
	float imageWidth = imageSize.width;
	float imageHeight = imageSize.height;

	NSBitmapImageRep *bitmap;
	bitmap = [[NSBitmapImageRep alloc] initWithData:[layerImage TIFFRepresentation]];
	unsigned char *imageBuffer = [bitmap bitmapData];
	
	[[curView openGLContext] makeCurrentContext];
	
	glGenTextures(1, &textureName);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/4);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, imageBuffer);
}

- (void)setLayerImageWhenSelected:(NSImage*)image;
{
	if(layerImageWhenSelected) [layerImageWhenSelected release];
	layerImageWhenSelected = image;
	[layerImageWhenSelected retain];
	
	NSSize imageSize = [layerImageWhenSelected size];
	float imageWidth = imageSize.width;
	float imageHeight = imageSize.height;

	NSBitmapImageRep *bitmap;
	bitmap = [[NSBitmapImageRep alloc] initWithData:[layerImageWhenSelected TIFFRepresentation]];
	unsigned char *imageBuffer = [bitmap bitmapData];
	
	[[curView openGLContext] makeCurrentContext];
	
	glGenTextures(1, &textureName2);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName2);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/4);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, imageBuffer);

}

int sortPointArrayAlongX(id point1, id point2, void *context)
{
    float x1 = (float)[point1 pointValue].x;
    float x2 = (float)[point2 pointValue].x;
    
	if (x1 < x2)
        return NSOrderedAscending;
    else if (x1 > x2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (BOOL)isPoint:(NSPoint)point inRectDefinedByPointA:(NSPoint)pointA pointB:(NSPoint)pointB pointC:(NSPoint)pointC pointD:(NSPoint)pointD;
{
	// sorting points along axis x
	NSPoint p1, p2, p3, p4, tempPoint;
	NSArray *pointsList = [NSArray arrayWithObjects:[NSValue valueWithPoint:pointA], [NSValue valueWithPoint:pointB], [NSValue valueWithPoint:pointC], [NSValue valueWithPoint:pointD], nil];
	NSArray *sortedPoints = [pointsList sortedArrayUsingFunction:sortPointArrayAlongX context:NULL];
	p1 = [[sortedPoints objectAtIndex:0] pointValue];
	p2 = [[sortedPoints objectAtIndex:1] pointValue];
	p3 = [[sortedPoints objectAtIndex:2] pointValue];
	p4 = [[sortedPoints objectAtIndex:3] pointValue];

//	if(p4.y < p3.y)
//	{
//		tempPoint = p4;
//		p4 = p3;
//		p3 = tempPoint;
//	}
	
	if(p2.y > p3.y)
	{
		tempPoint = p2;
		p2 = p3;
		p3 = tempPoint;
	}

	NSLog(@"point : %f, %f", point.x, point.y);
	NSLog(@"sortedPoints");
	NSLog(@"p1 : %f, %f", p1.x, p1.y);
	NSLog(@"p2 : %f, %f", p2.x, p2.y);
	NSLog(@"p3 : %f, %f", p3.x, p3.y);
	NSLog(@"p4 : %f, %f", p4.x, p4.y);
	
	if(p1.x==p2.x || p1.x==p3.x || layerRotationAngle==0) // no rotation...
	{
		NSLog(@"no rotation");
		return (point.x>=p1.x && point.x<=p4.x && point.y<=p3.y && point.y>=p2.y);
	}
	
	float a, b; // y = ax+b
	
	// line between p1 and p2
	a = (p2.y-p1.y) / (p2.x-p1.x);
	b = p1.y - a * p1.x;
	float y1 = a * point.x + b;
	// line between p1 and p3
	a = (p3.y-p1.y) / (p3.x-p1.x);
	b = p1.y - a * p1.x;
	float y2 = a * point.x + b;
	// line between p4 and p2
	a = (p2.y-p4.y) / (p2.x-p4.x);
	b = p4.y - a * p4.x;
	float y3 = a * point.x + b;
	// line between p4 and p3
	a = (p3.y-p4.y) / (p3.x-p4.x);
	b = p4.y - a * p4.x;
	float y4 = a * point.x + b;
	
	return (point.y>=y1 && point.y<=y2 && point.y>=y3 && point.y<=y4);
}

- (NSPoint)rotatePoint:(NSPoint)point withAngle:(float)alpha aroundCenter:(NSPoint)center;
{
	float x, y;
	float alphaRad = alpha * deg2rad;
	x = cos(alphaRad) * (point.x - center.x) - sin(alphaRad) * (point.y - center.y);
	y = sin(alphaRad) * (point.x - center.x) + cos(alphaRad) * (point.y - center.y);
	return NSMakePoint(x+center.x, y+center.y);
}

@end
