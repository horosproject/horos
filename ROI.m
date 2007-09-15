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
#define ROIVERSION		7

static		float					deg2rad = M_PI / 180.0f; 

static		NSString				*defaultName;
static		int						gUID = 0;

extern long BresLine(int Ax, int Ay, int Bx, int By,long **xBuffer, long **yBuffer);

static float ROIRegionOpacity, ROITextThickness, ROIThickness, ROIOpacity, ROIColorR, ROIColorG, ROIColorB, ROITextColorR, ROITextColorG, ROITextColorB;
static float ROIRegionThickness, ROIRegionColorR, ROIRegionColorG, ROIRegionColorB;
static BOOL ROITEXTIFSELECTED, ROITEXTNAMEONLY;

@implementation ROI

@synthesize textureWidth, textureHeight, textureBuffer;
@synthesize textureDownRightCornerX,textureDownRightCornerY, textureUpLeftCornerX, textureUpLeftCornerY;
@synthesize opacity;
@synthesize name, comments, type, ROImode = mode, thickness;
@synthesize zPositions;
@synthesize clickInTextBox;
@synthesize rect;
@synthesize pix;
@synthesize curView;
@synthesize mousePosMeasure;
@synthesize rgbcolor = color;
@synthesize parentROI;
@synthesize displayCalciumScoring = _displayCalciumScoring, calciumThreshold = _calciumThreshold;
@synthesize sliceThickness = _sliceThickness;
@synthesize layerReferenceFilePath;
@synthesize layerImage;
@synthesize layerPixelSpacingX, layerPixelSpacingY;
@synthesize textualBoxLine1, textualBoxLine2, textualBoxLine3, textualBoxLine4, textualBoxLine5;
@synthesize groupID;
@synthesize isLayerOpacityConstant, canColorizeLayer, displayTextualData, clickPoint;

+(void) saveDefaultSettings
{
	[[NSUserDefaults standardUserDefaults] setFloat: ROIRegionOpacity forKey: @"ROIRegionOpacity"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROITextThickness forKey: @"ROITextThickness"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIThickness forKey: @"ROIThickness"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIOpacity forKey: @"ROIOpacity"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIColorR forKey: @"ROIColorR"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIColorG forKey: @"ROIColorG"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIColorB forKey: @"ROIColorB"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROITextColorR forKey: @"ROITextColorR"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROITextColorG forKey: @"ROITextColorG"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROITextColorB forKey: @"ROITextColorB"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIRegionColorR forKey: @"ROIRegionColorR"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIRegionColorG forKey: @"ROIRegionColorG"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIRegionColorB forKey: @"ROIRegionColorB"];
	[[NSUserDefaults standardUserDefaults] setFloat: ROIRegionThickness forKey: @"ROIRegionThickness"];
}

+(void) loadDefaultSettings
{
	ROIRegionOpacity = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionOpacity"];
	if( ROIRegionOpacity < 0.3) ROIRegionOpacity = 0.3;
	
	ROITextThickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextThickness"];
	ROIThickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIThickness"];
	ROIOpacity = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIOpacity"];
	if( ROIOpacity < 0.3) ROIOpacity = 0.3;
	
	ROIColorR = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorR"];
	ROIColorG = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorG"];
	ROIColorB = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorB"];
	ROITextColorR = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorR"];
	ROITextColorG = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorG"];
	ROITextColorB = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorB"];
	ROIRegionColorR = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorR"];
	ROIRegionColorG = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorG"];
	ROIRegionColorB = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorB"];
	ROIRegionThickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionThickness"];
	
	ROITEXTIFSELECTED = [[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTIFSELECTED"];
	ROITEXTNAMEONLY = [[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTNAMEONLY"];
}

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

+ (NSPoint) pointBetweenPoint:(NSPoint) a and:(NSPoint) b ratio: (float) r
{
	NSPoint	pt = NSMakePoint( a.x, a.y);
	float	theta, pyth;
	
	if( b.x == a.x &&  b.y == a.y) return pt;
	
	if( (b.x - a.x) == 0)
	{
		pt.y += r * (b.y-a.y);
	}
	
	theta = atan( (b.y -  a.y) / (b.x - a.x));
	
	pyth =	(b.y - a.y) * (b.y - a.y) +
			(b.x - a.x) * (b.x - a.x);
	
	pyth = sqrt( pyth);
	
	if( (b.x - a.x) < 0)
	{
		pt.x -= (r * pyth) * cos( theta);
		pt.y -= (r * pyth) * sin( theta);
	}
	else
	{
		pt.x += (r * pyth) * cos( theta);
		pt.y += (r * pyth) * sin( theta);
	}
	
	return pt;
}

+ (float) lengthBetween:(NSPoint) mesureA and :(NSPoint) mesureB
{
	short yT, xT;
	float mesureLength;
	
	if( mesureA.x > mesureB.x) { yT = mesureA.y;  xT = mesureA.x;}
	else {yT = mesureB.y;   xT = mesureB.x;}
	
	{
		double coteA, coteB;
		
		coteA = fabs(mesureA.x - mesureB.x);
		coteB = fabs(mesureA.y - mesureB.y);
		
		if( coteA == 0) mesureLength = coteB;
		else if( coteB == 0) mesureLength = coteA;
		else mesureLength = coteB / (sin (atan( coteB / coteA)));
	}
	
	return mesureLength;
}

+(NSPoint) positionAtDistance: (float) distance inPolygon:(NSArray*) points
{
	int i = 0;
	float previousPosition, position = 0, ratio;
	NSPoint p;
	
	if( distance == 0) return [[points objectAtIndex:0] point];
	
	while( position < distance && i < [points count] -1)
	{
		position += [ROI lengthBetween:[[points objectAtIndex:i] point] and:[[points objectAtIndex:i+1] point]];
		i++;
	}
	
	if( position < distance)
	{
		previousPosition = position;
		position += [ROI lengthBetween:[[points objectAtIndex:i] point] and:[[points objectAtIndex:0] point]];
		i++;
	}
	
	if( i == [points count])
	{
		ratio = (position - distance) / [ROI lengthBetween: [[points objectAtIndex:i-1] point]  and:[[points objectAtIndex: 0] point]];
		p = [ROI pointBetweenPoint:[[points objectAtIndex:i-1] point] and:[[points objectAtIndex:0] point] ratio: 1.0 - ratio];
	}
	else
	{
		ratio = (position - distance) / [ROI lengthBetween: [[points objectAtIndex:i-1] point]  and:[[points objectAtIndex:i] point]];
		p = [ROI pointBetweenPoint:[[points objectAtIndex:i-1] point] and:[[points objectAtIndex:i] point] ratio: 1.0 - ratio];
	}
	
	return p;
}

+(NSMutableArray*) resamplePoints: (NSArray*) points number:(int) no
{
	float length = 0.0f;
	int i;
	
	for( i = 0; i < [points count]-1; i++ )	{
		length += [ROI lengthBetween:[[points objectAtIndex:i] point] and:[[points objectAtIndex:i+1] point]];
	}
	length += [ROI lengthBetween:[[points objectAtIndex:i] point] and:[[points objectAtIndex:0] point]];
	
	NSMutableArray* newPts = [NSMutableArray array];
	for( int i = 0; i < no; i++) {
		float s = (i * length) / no;
		
		NSPoint p = [ROI positionAtDistance: s inPolygon: points];
		
		[newPts addObject: [MyPoint point: p]];
	}
	
	float minx = [[newPts objectAtIndex: 0] x];
	float miny = [[newPts objectAtIndex: 0] y];
	int minyIndex = 0, minxIndex = 0;
	
	//find min x - reorder the points
	for( int i = 0 ; i < [newPts count] ; i++) {
		
		if( minx > [[newPts objectAtIndex: i] x])
		{
			minx = [[newPts objectAtIndex: i] x];
			minxIndex = i;
		}
		
		if( miny > [[newPts objectAtIndex: i] y])
		{
			miny = [[newPts objectAtIndex: i] y];
			minyIndex = i;
		}
	}
	BOOL reverse = NO;
	
	int distance = 0;
	
	distance = minxIndex - minyIndex;
	
	if( fabs( distance) > [newPts count]/2)
	{
		if( distance >= 0) reverse = YES;
		else reverse = NO;
	}
	else
	{
		if( distance >= 0) reverse = NO;
		else reverse = YES;
	}
	
	NSMutableArray* orderedPts = [NSMutableArray array];
	if( reverse == NO )
	{
		for( int i = 0 ; i < [newPts count] ; i++) {
			
			[orderedPts addObject: [newPts objectAtIndex: minxIndex]];
			minxIndex++;
			if( minxIndex == [newPts count]) minxIndex = 0;
		}
	}
	else
	{
		for( int i = 0 ; i < [newPts count] ; i++) {
			
			[orderedPts addObject: [newPts objectAtIndex: minxIndex]];
			minxIndex--;
			if( minxIndex < 0) minxIndex = [newPts count] -1;
		}
	}
	
	return orderedPts;
}

-(void) setDefaultName:(NSString*) n { [ROI setDefaultName: n]; }
-(NSString*) defaultName { return defaultName; }
 
// --- tPlain functions 
-(void)displayTexture
{
	printf( "-*- DISPLAY ROI TEXTURE -*-\n" );
	for ( int j=0; j<textureHeight; j++ ) {
		for( int i=0; i<textureWidth; i++ )
			printf( "%d ",textureBuffer[i+j*textureWidth] );
		printf("\n");
	}
}

- (void) setOpacity:(float)newOpacity
{
	ROIOpacity = opacity = newOpacity;
	
	if( type == tPlain)
	{
		ROIRegionOpacity = opacity;
	}
	else if(type == tLayerROI)
	{
		needsLoadTexture = YES;
	}
}

- (DCMPix*)pix {
	if ( pix )	{
		return pix;
	}
	else {
		NSLog( @"***** warning pix == [curView curDCM]");
		
		return pix = curView.curDCM;
	}
}

- (id) initWithCoder:(NSCoder*) coder
{
	long fileVersion;
	
    if( self = [super init])
    {
		uniqueID = [[NSNumber numberWithInt: gUID++] retain];
		groupID = 0.0;
		
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

			for( long j=0; j<textureHeight; j++ ) {
				for( long i=0; i<textureWidth; i++ ) {
					textureBuffer[i+j*textureWidth]=pointerBuff[i+j*textureWidth];
				}
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

		if (fileVersion >= 6)
		{
			groupID = [[coder decodeObject] doubleValue];
			if (type==tLayerROI)
			{
				layerImageJPEG = [coder decodeObject];
				[layerImageJPEG retain];
//				layerImageWhenSelectedJPEG = [coder decodeObject];
//				[layerImageWhenSelectedJPEG retain];
				
				layerImage = [[NSImage alloc] initWithData: layerImageJPEG];
//				layerImageWhenSelected = [[NSImage alloc] initWithData: layerImageWhenSelectedJPEG];
				
				needsLoadTexture = YES;
				//needsLoadTexture2 = YES;
			}
			textualBoxLine1 = [coder decodeObject];
			textualBoxLine2 = [coder decodeObject];
			textualBoxLine3 = [coder decodeObject];
			textualBoxLine4 = [coder decodeObject];
			textualBoxLine5 = [coder decodeObject];
			if(textualBoxLine1) [textualBoxLine1 retain];
			if(textualBoxLine2) [textualBoxLine2 retain];
			if(textualBoxLine3) [textualBoxLine3 retain];
			if(textualBoxLine4) [textualBoxLine4 retain];
			if(textualBoxLine5) [textualBoxLine5 retain];
		}

		if (fileVersion >= 7)
		{
			isLayerOpacityConstant = [[coder decodeObject] boolValue];
			canColorizeLayer = [[coder decodeObject] boolValue];
			layerColor = [coder decodeObject];
			if(layerColor)[layerColor retain];
			displayTextualData = [[coder decodeObject] boolValue];
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
	
	// ROIVERSION = 6
	[coder encodeObject:[NSNumber numberWithDouble:groupID]];
	if (type==tLayerROI)
	{
		if( layerImageJPEG == 0L)
		{
//			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [layerImage TIFFRepresentation]];
//			NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.3] forKey:NSImageCompressionFactor];
//	
//			layerImageJPEG = [[imageRep representationUsingType:NSJPEG2000FileType properties:imageProps] retain];	//NSJPEGFileType
			[self generateEncodedLayerImage];
		}
//		if( layerImageWhenSelectedJPEG == 0L)
//		{
//			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [layerImage TIFFRepresentation]];
//			NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.3] forKey:NSImageCompressionFactor];
//	
//			layerImageWhenSelectedJPEG = [[imageRep representationUsingType:NSJPEG2000FileType properties:imageProps] retain];	//NSJPEGFileType
//		}
		[coder encodeObject: layerImageJPEG];
//		[coder encodeObject: layerImageWhenSelectedJPEG];
	}
	[coder encodeObject:textualBoxLine1];
	[coder encodeObject:textualBoxLine2];
	[coder encodeObject:textualBoxLine3];
	[coder encodeObject:textualBoxLine4];
	[coder encodeObject:textualBoxLine5];
	
	// ROIVERSION = 7
	[coder encodeObject:[NSNumber numberWithBool:isLayerOpacityConstant]];
	[coder encodeObject:[NSNumber numberWithBool:canColorizeLayer]];
	[coder encodeObject:layerColor];
	[coder encodeObject:[NSNumber numberWithBool:displayTextualData]];
}

- (NSData*) data { return [NSArchiver archivedDataWithRootObject: self]; }

- (void) releaseStringTexture
{
	[stringTex deleteTexture];
}

- (void) dealloc
{
	if (textureBuffer) free(textureBuffer);
		
	[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:self userInfo: 0L];
	
	[uniqueID release];
	[points release];
	[zPositions release];
	[name release];
	[comments release];
	[stringTex release];
	[stanStringAttrib release];
	
	[layerImageJPEG release];
//	[layerImageWhenSelectedJPEG release];

	if(layerReferenceFilePath) [layerReferenceFilePath release];
	if(layerImage) [layerImage release];
//	if(layerImageWhenSelected) [layerImageWhenSelected release];
	if(layerColor) [layerColor release];
	
	if(textualBoxLine1) [textualBoxLine1 release];
	if(textualBoxLine2) [textualBoxLine2 release];
	if(textualBoxLine3) [textualBoxLine3 release];
	if(textualBoxLine4) [textualBoxLine4 release];
	if(textualBoxLine5) [textualBoxLine5 release];
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	if( textureName) glDeleteTextures (1, &textureName);
	
	[super dealloc];
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
	
	for( long i = 0; i < [points count]; i++)
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
		uniqueID = [[NSNumber numberWithInt: gUID++] retain];
		groupID = 0.0;
		
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
		displayTextualData = YES;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	return self;
}

- (id) initWithType: (long) itype :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin
{
	self = [super init];
    if (self)
	{
		uniqueID = [[NSNumber numberWithInt: gUID++] retain];
		groupID = 0.0;
		
        type = itype;
		mode = ROI_sleep;
		parentROI = 0L;
		
		previousPoint.x = previousPoint.y = -1000;
		
		if( type == tText) thickness = ROITextThickness;
		else thickness = ROIThickness;
		
		opacity = ROIOpacity;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIOpacity"];
		color.red = ROIColorR;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorR"];
		color.green = ROIColorG;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorG"];
		color.blue = ROIColorB;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorB"];
		
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
			
			self.name = name;	// Recompute the texture
			
			color.red = ROITextColorR;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorR"];
			color.green = ROITextColorG;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorG"];
			color.blue = ROITextColorB;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextColorB"];
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
			
			thickness = ROIRegionThickness;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionThickness"];
			color.red = ROIRegionColorR;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorR"];
			color.green = ROIRegionColorG;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorG"];
			color.blue = ROIRegionColorB;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorB"];
			opacity = ROIRegionOpacity;		//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionOpacity"];
			
			name = [[NSString alloc] initWithString:@"Region"];
		}
		else if(type == tLayerROI)
		{
			layerReferenceFilePath = @"";
			[layerReferenceFilePath retain];
			layerImage = nil;
//			layerImageWhenSelected = nil;
			layerPixelSpacingX = 1.0 / 72.0 * 25.4; // 1/72 inches in milimeters
			layerPixelSpacingY = layerPixelSpacingX;
			name = [[NSString alloc] initWithString:@"Layer"];
			textualBoxLine1 = @"";
			textualBoxLine2 = @"";
			textualBoxLine3 = @"";
			textualBoxLine4 = @"";
			textualBoxLine5 = @"";
			needsLoadTexture = NO;
			//needsLoadTexture2 = NO;
		}
		else
		{
			name = [[NSString alloc] initWithString:@"Unnamed"];
		}
		
		displayTextualData = YES;
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
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
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
	long x = 0;
	for( long i = 0; i < textureWidth*textureHeight ; i++ )	{
		if( textureBuffer[i] != 0) x++;
	}
	
	return x;
}

-(float) Area {
	
   float	area = 0;

   for( long i = 0 ; i < [points count] ; i++ )
   {
      long j = (i + 1) % [points count];
	  
      area += [[points objectAtIndex:i] x] * [[points objectAtIndex:j] y];
      area -= [[points objectAtIndex:i] y] * [[points objectAtIndex:j] x];
   }

   area *= 0.5f;
   
   return fabs( area );
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
		//JJCP
		case tDynAngle:
		//JJCP
		case tAxis:
		case tCPolygon:
		case tOPolygon:
		case tPencil:
		
			xmin = xmax = [[points objectAtIndex:0] x];
			ymin = ymax = [[points objectAtIndex:0] y];
			
			for( long i = 0; i < [points count]; i++ ) {
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

		case tLayerROI:
			result = [[points objectAtIndex:2] point];
		break;
	}
	
	return result;
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
		
		for( long i = 0; i < CIRCLERESOLUTION ; i++ ) {

			angle = i * 2 * M_PI /CIRCLERESOLUTION;
		  
			tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( rect.origin.x + rect.size.width*cos(angle), rect.origin.y + rect.size.height*sin(angle))];
			[tempArray addObject:tempPoint];
			[tempPoint release];
		}
		
		return tempArray;
	}
	
	if( type == tPlain)
	{
		NSMutableArray  *tempArray = [ITKSegmentation3D extractContour:textureBuffer width:textureWidth height:textureHeight];
		
		for( long i = 0; i < [tempArray count]; i++) {
			
			MyPoint	*pt = [tempArray objectAtIndex: i];
			[pt move: textureUpLeftCornerX :textureUpLeftCornerY];
		}
		
		return tempArray;
	}
	
	return points;
}

- (void) setPoints: (NSMutableArray*) pts {
	
	if ( type == tROI || type == tOval ) return;  // Doesn't make sense to set points for these types.
	
	[points removeAllObjects];
	for ( long i = 0; i < [pts count]; i++ )
		[points addObject: [pts objectAtIndex: i]];
	
	return;
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
				p1 = [[points objectAtIndex:0] point];
				p2 = [[points objectAtIndex:1] point];
				p3 = [[points objectAtIndex:2] point];
				p4 = [[points objectAtIndex:3] point];
								
				if([self isPoint:pt inRectDefinedByPointA:p1 pointB:p2 pointC:p3 pointD:p4])
				{
					float width;
					float height;
					NSBitmapImageRep *bitmap;
//					if(mode==ROI_selected)
//					{
//						bitmap = [[NSBitmapImageRep alloc] initWithData:[layerImageWhenSelected TIFFRepresentation]];
//						width = [layerImageWhenSelected size].width;
//						height = [layerImageWhenSelected size].height;
//					}
//					else
					{
						bitmap = [[NSBitmapImageRep alloc] initWithData:[layerImage TIFFRepresentation]];
						width = [layerImage size].width;
						height = [layerImage size].height;
					}
					
					// base vectors of the layer image coordinate system
					NSPoint v, w;
					v.x = (p2.x - p1.x);
					v.y = (p2.y - p1.y);
					float l = sqrt(v.x*v.x + v.y*v.y);
					v.x /= l;
					v.y /= l;
					
					float scaleRatio = width / l; // scale factor between the ROI (actual display size) and the texture image (stored)
					
					w.x = (p4.x - p1.x);
					w.y = (p4.y - p1.y);
					l = sqrt(w.x*w.x + w.y*w.y);
					w.x /= l;
					w.y /= l;
					
					// clicked point
					NSPoint c;
					c.x = pt.x - p1.x;
					c.y = pt.y - p1.y;

					// point in the layer image coordinate system
					float y = (c.y-c.x*(v.y/v.x))/(w.y-w.x*(v.y/v.x));
					float x = (c.x-y*w.x)/v.x;
					
					x *= scaleRatio;
					y *= scaleRatio;
					
					// test if the clicked pixel is not transparent (otherwise the ROI won't be selected)
					// define a neighborhood around the point					
					#define NEIGHBORHOODRADIUS 10.0

					float xi, yj;
					BOOL found = NO;

					for( int i=-NEIGHBORHOODRADIUS; i<=NEIGHBORHOODRADIUS && !found; i++ ) {
						for( int j=-NEIGHBORHOODRADIUS; j<=NEIGHBORHOODRADIUS && !found; j++ ) {
							xi = x+i;
							yj = y+j;
							if(xi>=0.0 && yj>=0.0 && xi<width && yj<height)	{
								
								NSColor *pixelColor = [bitmap colorAtX:xi y:yj];
								if([pixelColor alphaComponent]>0.0)
									found = YES;
							}
						}
					}
					if(found)	
						imode = ROI_selected;
					[bitmap release];
				}
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

				for( int i = 0; i < ([points count] - 1); i++ )	{
					
					[self DistancePointLine:pt :[[points objectAtIndex:i] point] : [[points objectAtIndex:(i+1)] point] :&distance];
					if( distance*scale < 5.0)
					{
						imode = ROI_selected;
						break;
					}
				}
			}
			break;
			//JJCP
			case tDynAngle:
			//JJCP
			case tAxis:
			case tCPolygon:
			case tPencil:
			{
				float distance;

				int i;
				for( i = 0; i < ([points count] - 1); i++ )	{
					
					[self DistancePointLine:pt :[[points objectAtIndex:i] point] : [[points objectAtIndex:(i+1)] point] :&distance];
					if( distance*scale < 5.0)
					{
						imode = ROI_selected;
						break;
					}
				}
				
				[self DistancePointLine:pt :[[points objectAtIndex:i] point] : [[points objectAtIndex:0] point] :&distance];
				if( distance*scale < 5.0f )	imode = ROI_selected;

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
			//JJCP
			case tDynAngle:
			//JJCP
			case tAxis:
			case tCPolygon:
			case tOPolygon:
			case tPencil:
				for( int i = 0 ; i < [points count]; i++ ) {
					
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
	
	if( [self.comments isEqualToString: @"morphing generated"] ) self.comments = @"";
	
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
			textureBuffer = malloc(textureWidth*textureHeight*sizeof(unsigned char));
			memset (textureBuffer, 0, textureHeight*textureWidth);
			
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
		
		rect.size.height *= pixelSpacingX/pixelSpacingY;
		
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
    float theta;
    float dtheta;
    long intUpper;
    float new_x;
    float new_y;
	float intYCenter, intXCenter;
	NSMutableArray	*pts = self.points;
	
    intUpper = [pts count];
	if( intUpper > 0)
	{
		dtheta = deg2rad;
		theta = dtheta * angle; 
				
		if( type == tROI || type == tOval)
		{
			type = tCPolygon;
			[points release];
			points = [pts retain];
		}
		
		intXCenter = center.x;
		intYCenter = center.y;
		
		for( long i = 0; i < intUpper; i++)	{ 
			new_x = cos(theta) * ([[pts objectAtIndex: i] x] - intXCenter) - sin(theta) * ([[pts objectAtIndex: i] y] - intYCenter);
			new_y = sin(theta) * ([[pts objectAtIndex: i] x] - intXCenter) + cos(theta) * ([[pts objectAtIndex: i] y] - intYCenter);
			
			[[pts objectAtIndex: i] setPoint: NSMakePoint( new_x + intXCenter, new_y + intYCenter)];
		}
		
		rtotal = -1;
		Brtotal = -1;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	}
}

- (BOOL)canResize;
{
	if(type == tLayerROI)
		return NO;
	else
		return YES;
}

- (void) resize: (float) factor :(NSPoint) center
{
	if(![self canResize]) return;
	
    long intUpper;
    float new_x;
    float new_y;
	float intYCenter, intXCenter;
	NSMutableArray	*pts = self.points;

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
		
		for( long i = 0; i < intUpper; i++) { 
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
		
		//JJCP
		case tDynAngle:
			if( [points count] < 4) return NO;
		break;
		//JJCP
		case tAxis:
			if( [points count] < 4) return NO;
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
		switch( type)
		{
			case tOval:
			case tText:
			case t2DPoint:
			case tROI:
				rect = NSOffsetRect( rect, offset.x, offset.y);
			break;
			//JJCP
			case tDynAngle:
			//JJCP
			case tAxis:
			case tCPolygon:
			case tOPolygon:
			case tMesure:
			case tArrow:
			case tAngle:
			case tPencil:
			case tLayerROI:
				for( long i = 0; i < [points count]; i++) [[points objectAtIndex: i] move: offset.x : offset.y];
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
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: [NSDictionary dictionaryWithObjectsAndKeys:@"mouseUp", @"action", 0L]];
			
			mode = ROI_selected;
			return NO;
		}
	}
	
	
	
	return YES;
}

- (BOOL) reduceTextureIfPossible
{
	if( type != tPlain) return YES;
	
	long			minX, maxX, minY, maxY;
	unsigned char	*tempBuf = textureBuffer;
	
	minX = textureWidth;
	maxX = 0;
	minY = textureHeight;
	maxY = 0;
	
	for( long y = 0; y < textureHeight ; y++)
	{
		for( long x = 0; x < textureWidth; x++)
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
		
		for( long y = 0 ; y < textureHeight ; y++)
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
	int		xsqr;
	int		radsqr = (width*width)/4;
	int		rad = width/2;
	
	for( int x = 0; x < rad; x++ ) {
		
		xsqr = x*x;
		for( int y = 0 ; y < rad; y++) {
			
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
	BOOL		textureGrowDownX=YES,textureGrowDownY=YES;
	float		oldTextureUpLeftCornerX,oldTextureUpLeftCornerY,offsetTextureX,offsetTextureY;
	
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
				
				thickness = ROIRegionThickness;
			
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
					
					for( long i = 0; i < oldTextureWidth*oldTextureHeight;i++) tempTextureBuffer[i]=textureBuffer[i];
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
					for( long i = 0; i < textureWidth*textureHeight;i++) textureBuffer[i]=0;
					
					if (textureGrowDownX && textureGrowDownY)
					{
						for( long j=0; j<oldTextureHeight; j++ )
							for( long i=0; i<oldTextureWidth; i++ )
								textureBuffer[i+j*textureWidth] = tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					if (!textureGrowDownX && textureGrowDownY)
					{
						offsetTextureX=(oldTextureUpLeftCornerX-textureUpLeftCornerX);
						for(long j=0; j<oldTextureHeight; j++ )
							for( long i=0; i<oldTextureWidth; i++)
								textureBuffer[(long)(i+offsetTextureX+j*textureWidth)]=tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					if (textureGrowDownX && !textureGrowDownY)
					{
						offsetTextureY=(oldTextureUpLeftCornerY-textureUpLeftCornerY);
						for( long j=0; j<oldTextureHeight; j++ )
							for( long i=0; i<oldTextureWidth; i++ )
								textureBuffer[(long)(i+(j+offsetTextureY)*textureWidth)]=tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					if (!textureGrowDownX && !textureGrowDownY)
					{
						offsetTextureY=(oldTextureUpLeftCornerY-textureUpLeftCornerY);
						offsetTextureX=(oldTextureUpLeftCornerX-textureUpLeftCornerX);
						for( long j=0; j<oldTextureHeight; j++ )
							for( long i=0; i<oldTextureWidth; i++)
								textureBuffer[(long)(i+offsetTextureX+(j+offsetTextureY)*textureWidth)]=tempTextureBuffer[i+j*oldTextureWidth];
					}
					
					free(tempTextureBuffer);
					tempTextureBuffer = 0L;
				}
					
				oldTextureWidth = textureWidth;
				oldTextureHeight = textureHeight;	
				tempTextureBuffer = malloc(textureWidth*textureHeight*sizeof(unsigned char));
				
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
				
				for( long x = 0 ; x < size; x++ ) {
					long xx = xPoints[ x];
					long yy = yPoints[ x];
							
					for ( long j =- intThickness; j < intThickness; j++ ) {
						for ( long i =- intThickness; i < intThickness; i++ ) {
							
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
		if(type==tLayerROI) clickPoint = pt;
		
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
	
	if( action)
	{
		if ( [self.comments isEqualToString: @"morphing generated"] ) self.comments = @"";
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	}
	return action;
}

- (void) setName:(NSString*) a
{
	if( a == 0L) a = @"";
	
	if( name != a)
	{
		[name release]; name = [a retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:self userInfo: 0L];
	}
	
	if( type == tText || type == t2DPoint)
	{
		NSString	*finalString;
		
		if( [comments length] > 0)	finalString  = [name stringByAppendingFormat:@"\r%@", comments];
		else finalString = name;
		
		if (stringTex) [stringTex setString:finalString withAttributes:stanStringAttrib];
		else
		{
			stringTex = [[StringTexture alloc] initWithString:finalString withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:color.red / 65535. green:color.green / 65535. blue:color.blue / 65535. alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
			[stringTex setAntiAliasing: YES];
		}
		
		rect.size = [stringTex frameSize];
		rect.size.height *= pixelSpacingX/pixelSpacingY;
	}	
}

- (void) setColor:(RGBColor) a
{
	color = a;
	if( type == tText)
	{
		ROITextColorR = color.red;	//[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROITextColorR"];
		ROITextColorG = color.green;	//[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROITextColorG"];
		ROITextColorB = color.blue;	//[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROITextColorB"];
	}
	else if( type == tPlain)
	{
		ROIRegionColorR = color.red;	//[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROIRegionColorR"];
		ROIRegionColorG = color.green;	//[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROIRegionColorG"];
		ROIRegionColorB = color.blue;	//[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROIRegionColorB"];
	}
	else if( type == tLayerROI)
	{
		if(!canColorizeLayer) return;
		if(layerColor) [layerColor release];
		layerColor = [NSColor colorWithCalibratedRed:color.red/65535.0 green:color.green/65535.0 blue:color.blue/65535.0 alpha:1.0];
		[layerColor retain];
		needsLoadTexture = YES;
	}
	else
	{
		ROIColorR = color.red;		//[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROIColorR"];
		ROIColorG = color.green;		//[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROIColorG"];
		ROIColorB = color.blue;		//[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROIColorB"];
	}
}

- (void) setThickness:(float) a
{
	thickness = a;
	
	if( type == tPlain)
	{
		ROIRegionThickness = thickness;	//[[NSUserDefaults standardUserDefaults] setFloat:thickness forKey:@"ROIRegionThickness"];
	}
	else if( type == tText)
	{
		ROITextThickness = thickness;	//[[NSUserDefaults standardUserDefaults] setFloat:thickness forKey:@"ROITextThickness"];
		
		[stanStringAttrib release];
		
		// init fonts for use with strings
		NSFont * font =[NSFont fontWithName:@"Helvetica" size: 12.0 + thickness*2];
		stanStringAttrib = [[NSMutableDictionary dictionary] retain];
		[stanStringAttrib setObject:font forKey:NSFontAttributeName];
		[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		self.name = name;
	}
	else {
		ROIThickness = thickness;
	}
}

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
		//JJCP
		case tDynAngle:
		//JJCP
		case tAxis:
			if(selectedModifyPoint>3)
			{
				if( mode == ROI_selectedModify)
					[points removeObjectAtIndex: selectedModifyPoint];
				else [points removeLastObject];			
				if( selectedModifyPoint >= [points count]) selectedModifyPoint = [points count]-1;
			}
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

static int roundboxtype= 15;

void gl_round_box(int mode, float minx, float miny, float maxx, float maxy, float rad)
{
	 float vec[7][2]= {{0.195, 0.02}, {0.383, 0.067}, {0.55, 0.169}, {0.707, 0.293},
					   {0.831, 0.45}, {0.924, 0.617}, {0.98, 0.805}};

	 /* mult */
	 for( int a=0; a<7; a++) {
			 vec[a][0]*= rad; vec[a][1]*= rad;
	 }

	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	 glBegin(mode);

	 /* start with corner right-bottom */
	 if(roundboxtype & 4) {
			 glVertex2f( maxx-rad, miny);
			 for( int a=0; a<7; a++ ) {
					 glVertex2f( maxx-rad+vec[a][0], miny+vec[a][1]);
			 }
			 glVertex2f( maxx, miny+rad);
	 }
	 else glVertex2f( maxx, miny);
	 
	 /* corner right-top */
	 if(roundboxtype & 2) {
			 glVertex2f( maxx, maxy-rad);
			 for( int a=0; a<7; a++ ) {
					 glVertex2f( maxx-vec[a][1], maxy-rad+vec[a][0]);
			 }
			 glVertex2f( maxx-rad, maxy);
	 }
	 else glVertex2f( maxx, maxy);
	 
	 /* corner left-top */
	 if(roundboxtype & 1) {
			 glVertex2f( minx+rad, maxy);
			 for( int a=0; a<7; a++ ) {
					 glVertex2f( minx+rad-vec[a][0], maxy-vec[a][1]);
			 }
			 glVertex2f( minx, maxy-rad);
	 }
	 else glVertex2f( minx, maxy);
	 
	 /* corner left-bottom */
	 if(roundboxtype & 8) {
			 glVertex2f( minx, miny+rad);
			 for( int a=0; a<7; a++ ) {
					 glVertex2f( minx+vec[a][1], miny+rad-vec[a][0]);
			 }
			 glVertex2f( minx+rad, miny);
	 }
	 else glVertex2f( minx, miny);
	 
	 glEnd();
}

- (NSRect) findAnEmptySpaceForMyRect:(NSRect) dRect :(BOOL*) moved
{
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
	
	for( long i = 0; i < [rectArray count]; i++ ) {
		
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
	if(!displayTextualData) return NO;
	
	// NO text for Calcium Score
	if (_displayCalciumScoring)
		return NO;
		
	BOOL drawTextBox = NO;
	
	if( ROITEXTIFSELECTED == NO || mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
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
	BOOL moved;
	
	drawRect = [self findAnEmptySpaceForMyRect: drawRect : &moved];
	//JJCP
	if(type == tDynAngle || type == tAxis ||type == tCPolygon || type == tOPolygon || type == tPencil) moved = YES;

//	if( type == tCPolygon || type == tOPolygon || type == tPencil) moved = YES;
	
//	if( fabs( offsetTextBox_x) > 0 || fabs( offsetTextBox_y) > 0) moved = NO;
	
	if( moved && ![curView suppressLabels] && self.isTextualDataDisplayed )	// Draw bezier line
	{
		CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
		glLoadIdentity();
//		glScalef( 2.0f /([curView frame].size.width), -2.0f / ([curView frame].size.height), 1.0f);	// JORIS ! Here is the problem for iChat : if ICHAT [curView frame] should be 640 *480....
		glScalef( 2.0f /([curView drawingFrameRect].size.width), -2.0f / ([curView drawingFrameRect].size.height), 1.0f);
		
		GLfloat ctrlpoints[4][3];
		
		const int OFF = 30;
		
		ctrlpoints[0][0] = NSMinX( drawRect);				ctrlpoints[0][1] = NSMidY( drawRect);							ctrlpoints[0][2] = 0;
		ctrlpoints[1][0] = originAnchor.x - OFF;			ctrlpoints[1][1] = originAnchor.y;								ctrlpoints[1][2] = 0;
		ctrlpoints[2][0] = originAnchor.x;					ctrlpoints[2][1] = originAnchor.y;								ctrlpoints[2][2] = 0;
		
		glLineWidth( 3.0);
		if( mode == ROI_sleep) glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
		else glColor4f(0.3f, 0.0f, 0.0f, 0.8f);
		
		glMap1f(GL_MAP1_VERTEX_3, 0.0, 1.0, 3, 3,&ctrlpoints[0][0]);
		glEnable(GL_MAP1_VERTEX_3);
		
	    glBegin(GL_LINE_STRIP);
        for ( int i = 0; i <= 30; i++ ) glEvalCoord1f((GLfloat) i/30.0);
		glEnd();
		glDisable(GL_MAP1_VERTEX_3);
		
		glLineWidth( 1.0);
		
		glColor4f( 1.0, 1.0, 1.0, 0.5);
		
		glMap1f(GL_MAP1_VERTEX_3, 0.0, 1.0, 3, 3,&ctrlpoints[0][0]);
		glEnable(GL_MAP1_VERTEX_3);
		
	    glBegin(GL_LINE_STRIP);
        for ( int i = 0; i <= 30; i++ ) glEvalCoord1f((GLfloat) i/30.0);
		glEnd();
		glDisable(GL_MAP1_VERTEX_3);
		
		[curView applyImageTransformation];
	}

	if( self.isTextualDataDisplayed ) {
		if( type != tText) {
			
			//glEnable(GL_POLYGON_SMOOTH);
			CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
			glEnable(GL_BLEND);
			glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
			
			if( mode == ROI_sleep) glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
			else glColor4f(0.3f, 0.0f, 0.0f, 0.8f);
			
			glLoadIdentity();
			
			glScalef( 2.0f /([curView drawingFrameRect].size.width), -2.0f / ([curView drawingFrameRect].size.height), 1.0f);
			
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
	NSPoint		ctPt = tPt;
	
	tPt = [curView ConvertFromGL2View: ctPt];
	originAnchor = tPt;
	
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
	//JJCP
	if( type == tDynAngle || type == tAxis || type == tCPolygon || type == tOPolygon || type == tPencil)
	{
		float ymin = [[points objectAtIndex:0] y];
		
		tPt.y = [[points objectAtIndex: 0] y];
		tPt.x = [[points objectAtIndex: 0] x];
		
		for( long i = 0; i < [points count]; i++ ) {
			if( [[points objectAtIndex:i] y] > ymin)
			{
				ymin = [[points objectAtIndex:i] y];
				tPt.y = [[points objectAtIndex:i] y];
				tPt.x = [[points objectAtIndex:i] x];
			}
		}
		
		ctPt = tPt;
		
		tPt = [curView ConvertFromGL2View: ctPt];
		originAnchor = tPt;
		
		tPt = ctPt;
		tPt.x += offsetTextBox_x;
		tPt.y += offsetTextBox_y;
		
		tPt = [curView ConvertFromGL2View: tPt];
		drawRect.origin = tPt;
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
	if( fontListGL == -1) NSLog(@"ERROR: fontListGL == -1 !");
	if( curView == 0L) NSLog(@"ERROR: curView == 0L !");
	
	pixelSpacingX = spacingX;
	pixelSpacingY = spacingY;
	
	float screenXUpL,screenYUpL,screenXDr,screenYDr; // for tPlain ROI
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
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
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				NSSize imageSize = [layerImage size];
				float imageWidth = imageSize.width;
				float imageHeight = imageSize.height;
																
				glDisable(GL_POLYGON_SMOOTH);
				glEnable(GL_TEXTURE_RECTANGLE_EXT);

//				if(needsLoadTexture)
//				{
//					[self loadLayerImageTexture];
//					if(layerImageWhenSelected)
//						[self loadLayerImageWhenSelectedTexture];
//					needsLoadTexture = NO;
//				}
				
//				if(layerImageWhenSelected && mode==ROI_selected)
//				{
//					if(needsLoadTexture2) [self loadLayerImageWhenSelectedTexture];
//					needsLoadTexture2 = NO;
//					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName2);
//				}
//				else
				{
					if(needsLoadTexture)[self loadLayerImageTexture];
					needsLoadTexture = NO;
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
				}
				
				
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);			
				
				NSPoint p1, p2, p3, p4;
				p1 = [[points objectAtIndex:0] point];
				p2 = [[points objectAtIndex:1] point];
				p3 = [[points objectAtIndex:2] point];
				p4 = [[points objectAtIndex:3] point];
				
				p1.x = (p1.x-offsetx)*scaleValue;
				p1.y = (p1.y-offsety)*scaleValue;
				p2.x = (p2.x-offsetx)*scaleValue;
				p2.y = (p2.y-offsety)*scaleValue;
				p3.x = (p3.x-offsetx)*scaleValue;
				p3.y = (p3.y-offsety)*scaleValue;
				p4.x = (p4.x-offsetx)*scaleValue;
				p4.y = (p4.y-offsety)*scaleValue;
							
				glBegin(GL_QUAD_STRIP); // draw either tri strips of line strips (so this will draw either two tris or 3 lines)
					glTexCoord2f(0, 0); // draw upper left corner
					glVertex3d(p1.x, p1.y, 0.0);
					
					glTexCoord2f(imageWidth, 0); // draw upper left corner
					glVertex3d(p2.x, p2.y, 0.0);
					
					glTexCoord2f(0, imageHeight); // draw lower left corner
					glVertex3d(p4.x, p4.y, 0.0);
																				
					glTexCoord2f(imageWidth, imageHeight); // draw lower right corner
					glVertex3d(p3.x, p3.y, 0.0);
					
				glEnd();
				glDisable( GL_BLEND);
				
				glDisable(GL_TEXTURE_RECTANGLE_EXT);
				glEnable(GL_POLYGON_SMOOTH);
				
				// draw the 4 points defining the bounding box
				if(mode==ROI_selected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( 8.0);
					glBegin(GL_POINTS);
					glVertex3f(p1.x, p1.y, 0.0);
					glVertex3f(p2.x, p2.y, 0.0);
					glVertex3f(p3.x, p3.y, 0.0);
					glVertex3f(p4.x, p4.y, 0.0);
					glEnd();
					glColor3f (1.0f, 1.0f, 1.0f);
				}
				
				if( self.isTextualDataDisplayed )
				{
					// TEXT
					line1[0] = 0; line2[0] = 0; line3[0] = 0; line4[0] = 0; line5[0] = 0;
					NSPoint tPt = self.lowerRightPoint;
				
					if(![name isEqualToString:@"Unnamed"]) strcpy(line1, [name UTF8String]);
					if(textualBoxLine1 && ![textualBoxLine1 isEqualToString:@""]) strcpy(line1, [textualBoxLine1 UTF8String]);
					if(textualBoxLine2 && ![textualBoxLine2 isEqualToString:@""]) strcpy(line2, [textualBoxLine2 UTF8String]);
					if(textualBoxLine3 && ![textualBoxLine3 isEqualToString:@""]) strcpy(line3, [textualBoxLine3 UTF8String]);
					if(textualBoxLine4 && ![textualBoxLine4 isEqualToString:@""]) strcpy(line4, [textualBoxLine4 UTF8String]);
					if(textualBoxLine5 && ![textualBoxLine5 isEqualToString:@""]) strcpy(line5, [textualBoxLine5 UTF8String]);

					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
				}
				[pool release];
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
			if( self.isTextualDataDisplayed ) {
				NSPoint tPt = [self lowerRightPoint];
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if ( ROITEXTNAMEONLY == NO ) {
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
			for( long i = 0; i < CIRCLERESOLUTION ; i++ ) {

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
			if( self.isTextualDataDisplayed )
			{
				NSPoint tPt = self.lowerRightPoint;
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if( ROITEXTNAMEONLY == NO )
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
			
			glLineWidth(1.0);
			
			NSPoint tPt = self.lowerRightPoint;
			tPt.x = (tPt.x - offsetx)*scaleValue  - rect.size.width/2;		tPt.y = (tPt.y - offsety)*scaleValue - rect.size.height/2;
			
			GLint matrixMode;
			
			glEnable (GL_TEXTURE_RECTANGLE_EXT);
			
			glEnable(GL_BLEND);
//			if( opacity > 0.5) opacity = 1.0;
			if( opacity == 1.0) glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			else glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			
			if( stringTex == nil ) self.name = name;
			
			[stringTex setFlippedX: [curView xFlipped] Y:[curView yFlipped]];
			
			glColor4f (0, 0, 0, opacity);
			[stringTex drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+ (1.0*pixelSpacingX / pixelSpacingY)) ratio: pixelSpacingX / pixelSpacingY];
			
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			[stringTex drawAtPoint:tPt ratio: pixelSpacingX / pixelSpacingY];
			
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
				else slide = (b.x-a.x)/((b.y-a.y) * (pixelSpacingY / pixelSpacingX));
				
				#define ARROWSIZE 30.0
				
				// LINE
				angle = 90 - atan( slide)/deg2rad;
				adj = (ARROWSIZE + thickness * 13)  * cos( angle*deg2rad);
				op = (ARROWSIZE + thickness * 13) * sin( angle*deg2rad);
				glBegin(GL_LINE_STRIP);
					if(b.y-a.y > 0) glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
					else glVertex2f( a.x - adj, a.y - (op*pixelSpacingX / pixelSpacingY));
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
					glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
					
					angle = atan( slide)/deg2rad;
					angle = 100 - angle + thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
				}
				else
				{
					angle = atan( slide)/deg2rad;
					
					angle = 180 + 80 - angle - thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));

					angle = atan( slide)/deg2rad;
					angle = 180 + 100 - angle + thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
				}
				glVertex2f( a.x , a.y );
				glEnd();
			}
			else
			{
				glBegin(GL_LINE_STRIP);
				for( long i = 0; i < [points count]; i++ ) {
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
				}
				glEnd();
			}
			
			if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
				for( long i = 0; i < [points count]; i++) {
					
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
			if( self.isTextualDataDisplayed ) {
				NSPoint tPt = self.lowerRightPoint;
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				if( type == tMesure && ROITEXTNAMEONLY == NO) {
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
				if( self.isTextualDataDisplayed ) {
					NSPoint			tPt = self.lowerRightPoint;
					long			line = 0;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					else line1[ 0] = 0;
					
					if( ROITEXTNAMEONLY == NO )
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
			for( long i = 0; i < CIRCLERESOLUTION ; i++ ) {

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
			if( self.isTextualDataDisplayed ) {
				NSPoint			tPt = self.lowerRightPoint;
				long			line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if( ROITEXTNAMEONLY == NO ) {
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
		//JJCP
		case tAxis:
			//NSLog(@"JJCP--	Plot of ROI tAxis");
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			if( mode == ROI_drawing) 
				glLineWidth(thickness * 2);
			else 
				glLineWidth(thickness);
			
			glBegin(GL_LINE_LOOP);
			
			for( long i = 0; i < [points count]; i++) {				
				//NSLog(@"JJCP--	tAxis- New point: %f x, %f y",[[points objectAtIndex:i] x],[[points objectAtIndex:i] y]);
				glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
				if(i>2)
				{
					//glEnd();
					break;
				}
			}
			glEnd();
			if( [points count]>3 ){
				for( long i=4;i<[points count];i++ ) [points removeObjectAtIndex: i];
			}
			//TEXTO
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
			if( self.isTextualDataDisplayed ) {
				NSPoint tPt = self.lowerRightPoint;
				long	line = 0;
				float   length;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if( ROITEXTNAMEONLY == NO ) {
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
					long i;
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
				if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
				{
					NSPoint tempPt = [[[[NSApp currentEvent] window] contentView] convertPoint: [NSEvent mouseLocation] toView: curView];
					tempPt.y = [curView drawingFrameRect].size.height - tempPt.y ;
					tempPt = [curView ConvertFromView2GL:tempPt];
					
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( thickness * 3);
					glBegin( GL_POINTS);
					for( long i = 0; i < [points count]; i++) {
						if( mode == ROI_selectedModify && i == selectedModifyPoint) glColor3f (1.0f, 0.2f, 0.2f);
						else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/thickness :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
						else glColor3f (0.5f, 0.5f, 1.0f);
						
						glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
					}
					glEnd();
				}
				if(1)
				{	
					BOOL plot=NO;
					BOOL plot2=NO;
					NSPoint tPt0, tPt1, tPt01, tPt2, tPt3, tPt23, tPt03, tPt21;
					if([points count]>3)
					{
						//Calculus of middle point between 0 and 1.
						tPt0.x = ([[points objectAtIndex: 0] x]- offsetx) * scaleValue;
						tPt0.y = ([[points objectAtIndex: 0] y]- offsety) * scaleValue;
						tPt1.x = ([[points objectAtIndex: 1] x]- offsetx) * scaleValue;
						tPt1.y = ([[points objectAtIndex: 1] y]- offsety) * scaleValue;
						//Calculus of middle point between 2 and 3.
						tPt2.x = ([[points objectAtIndex: 2] x]- offsetx) * scaleValue;
						tPt2.y = ([[points objectAtIndex: 2] y]- offsety) * scaleValue;
						tPt3.x = ([[points objectAtIndex: 3] x]- offsetx) * scaleValue;
						tPt3.y = ([[points objectAtIndex: 3] y]- offsety) * scaleValue;
						plot=YES;
						plot2=YES;
					}
					//else
					/*
					 {
						 tPt0.x=0-offsetx*scaleValue;
						 tPt0.y=0-offsety*scaleValue;
						 tPt1.x=0-offsetx*scaleValue;
						 tPt1.y=0-offsety*scaleValue;
						 tPt2.x=0-offsetx*scaleValue;
						 tPt2.y=0-offsety*scaleValue;
						 tPt3.x=0-offsetx*scaleValue;
						 tPt3.y=0-offsety*scaleValue;
						 
					 }*/
					//Calcular punto medio entre el punto 0 y 1.
					tPt01.x  = (tPt1.x+tPt0.x)/2;
					tPt01.y  = (tPt1.y+tPt0.y)/2;
					//Calcular punto medio entre el punto 2 y 3.
					tPt23.x  = (tPt3.x+tPt2.x)/2;
					tPt23.y  = (tPt3.y+tPt2.y)/2;
					
					
					/*****Line equation p1-p2
						*
						* 	// line between p1 and p2
						*	float a, b; // y = ax+b
					*	a = (p2.y-p1.y) / (p2.x-p1.x);
					*	b = p1.y - a * p1.x;
					*	float y1 = a * point.x + b;
					*   point.x=(y1-b)/a;
					*
						******/
					//Line 1. Equation
					float a1,b1,a2,b2;
					a1=(tPt23.y-tPt01.y)/(tPt23.x-tPt01.x);
					b1=tPt01.y-a1*tPt01.x;
					float x1,x2,x3,x4,y1,y2,y3,y4;
					y1=tPt01.y-125;
					y2=tPt23.y+125;					
					x1=(y1-b1)/a1;
					x2=(y2-b1)/a1;
					//Line 2. Equation
					tPt03.x  = (tPt3.x+tPt0.x)/2;
					tPt03.y  = (tPt3.y+tPt0.y)/2;
					tPt21.x  = (tPt1.x+tPt2.x)/2;
					tPt21.y  = (tPt1.y+tPt2.y)/2;
					a2=(tPt21.y-tPt03.y)/(tPt21.x-tPt03.x);
					b2=tPt03.y-a2*tPt03.x;
					x3=tPt03.x-125;
					x4=tPt21.x+125;
					y3=a2*x3+b2;
					y4=a2*x4+b2;
					if(plot)
					{
						glBegin(GL_LINE_STRIP);
						glColor3f (0.0f, 0.0f, 1.0f);
						glVertex2f(x1,y1);
						glVertex2f(x2,y2);
						//glVertex2f(tPt01.x, tPt01.y);
						//glVertex2f(tPt23.x, tPt23.y);
						glEnd();
						glBegin(GL_LINE_STRIP);
						glColor3f (1.0f, 0.0f, 0.0f);
						glVertex2f(x3,y3);
						glVertex2f(x4,y4);
						//glVertex2f(tPt03.x, tPt03.y);
						//glVertex2f(tPt21.x, tPt21.y);
						glEnd();
					}
					if(plot2)
					{
						NSPoint p1, p2, p3, p4;
						p1 = [[points objectAtIndex:0] point];
						p2 = [[points objectAtIndex:1] point];
						p3 = [[points objectAtIndex:2] point];
						p4 = [[points objectAtIndex:3] point];
						
						p1.x = (p1.x-offsetx)*scaleValue;
						p1.y = (p1.y-offsety)*scaleValue;
						p2.x = (p2.x-offsetx)*scaleValue;
						p2.y = (p2.y-offsety)*scaleValue;
						p3.x = (p3.x-offsetx)*scaleValue;
						p3.y = (p3.y-offsety)*scaleValue;
						p4.x = (p4.x-offsetx)*scaleValue;
						p4.y = (p4.y-offsety)*scaleValue;
						//if(1)
						{	
							glEnable(GL_BLEND);
							glDisable(GL_POLYGON_SMOOTH);
							glDisable(GL_POINT_SMOOTH);
							glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
							// inside: fill							
							glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., 0.25);
							glBegin(GL_POLYGON);		
							glVertex2f(p1.x, p1.y);
							glVertex2f(p2.x, p2.y);
							glVertex2f(p3.x, p3.y);
							glVertex2f(p4.x, p4.y);
							glEnd();
							
							// no border
							
							/*	glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., 0.2);						
							glBegin(GL_LINE_LOOP);
							glVertex2f(p1.x, p1.y);
							glVertex2f(p2.x, p2.y);
							glVertex2f(p3.x, p3.y);
							glVertex2f(p4.x, p4.y);
							glEnd();
							*/	
							glDisable(GL_BLEND);
						}											
					}
			}			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);			
			break;
			//JJCP
		case tDynAngle:
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			if( mode == ROI_drawing) 
				glLineWidth(thickness * 2);
			else 
				glLineWidth(thickness);
			
			glBegin(GL_LINE_STRIP);
			
			for( long i = 0; i < [points count]; i++) {				
				if(i==1||i==2)
				{
					glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., 0.1);
				}
				else
				{
					glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				}
				glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
				if(i>2)
				{
					//glEnd();
					break;
				}
			}
			glEnd();
			if( [points count]>3 ) {
				for( long i=4; i<[points count]; i++ ) [points removeObjectAtIndex: i];
			}			
			BOOL plot=NO;
			BOOL plot2=NO;
			NSPoint a1,a2,b1,b2;
			NSPoint a,b,c,d;
			float angle=0;
			if([points count]>3)
			{
				a1 = [[points objectAtIndex: 0] point];
				a2 = [[points objectAtIndex: 1] point];
				b1 = [[points objectAtIndex: 2] point];
				b2 = [[points objectAtIndex: 3] point];				
				//plot=YES;
				//plot2=YES;
				
				//Code from Cobb's angle plugin.
				a = NSMakePoint( a1.x + (a2.x - a1.x)/2, a1.y + (a2.y - a1.y)/2);
				
				float slope1 = (a2.y - a1.y) / (a2.x - a1.x);
				slope1 = -1./slope1;
				float or1 = a.y - slope1*a.x;
				
				float slope2 = (b2.y - b1.y) / (b2.x - b1.x);
				float or2 = b1.y - slope2*b1.x;
				
				float xx = (or2 - or1) / (slope1 - slope2);
				
				d = NSMakePoint( xx, or1 + xx*slope1);
				
				b = [self ProjectionPointLine: a :b1 :b2];
				
				b.x = b.x + (d.x - b.x)/2.;
				b.y = b.y + (d.y - b.y)/2.;
				
				slope2 = -1./slope2;
				or2 = b.y - slope2*b.x;
				
				xx = (or2 - or1) / (slope1 - slope2);
				
				c = NSMakePoint( xx, or1 + xx*slope1);
				
				//Angle given by b,c,d points
				angle = [self Angle:b :c :d];
			}
			//TEXTO
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
			if( self.isTextualDataDisplayed ) {
					NSPoint tPt = self.lowerRightPoint;
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO ) {
						
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
						for( long i = 0; i < [points count]-1; i++ ) {
							length += [self Length:[[points objectAtIndex:i] point] :[[points objectAtIndex:i+1] point]];
						}
						
						if (length < .1)
							sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
						else
							sprintf (line5, "Length: %0.3f cm", length);
					}
					sprintf (line2, "Angle: %0.2f", angle);
					sprintf (line3, "Angle 2: %0.2f",360 - angle);
					sprintf (line4,"");
					//sprintf (line5,"");
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
			}
			//ROI MODE
			if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
			{
				NSPoint tempPt = [[[[NSApp currentEvent] window] contentView] convertPoint: [NSEvent mouseLocation] toView: curView];
				tempPt.y = [curView drawingFrameRect].size.height - tempPt.y ;
				tempPt = [curView ConvertFromView2GL:tempPt];
				
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
				for( long i = 0; i < [points count]; i++) {
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
			
		case tCPolygon:
		case tOPolygon:
		case tAngle:
		case tPencil:
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			if( mode == ROI_drawing) glLineWidth(thickness * 2);
			else glLineWidth(thickness);
			
			if( type == tCPolygon || type == tPencil)	glBegin(GL_LINE_LOOP);
			else										glBegin(GL_LINE_STRIP);
			
			for( long i = 0; i < [points count]; i++) {
				glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
			}
			glEnd();
			
			// TEXT
			if( type == tCPolygon || type == tPencil)
			{
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;
				if( self.isTextualDataDisplayed ) {
					NSPoint tPt = self.lowerRightPoint;
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO ) {
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
						long i;
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
				if( self.isTextualDataDisplayed ) {
					NSPoint tPt = self.lowerRightPoint;
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO ) {
						
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
						for( long i = 0; i < [points count]-1; i++ ) {
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
					if( self.isTextualDataDisplayed ) {
						NSPoint tPt = self.lowerRightPoint;
						long	line = 0;
						float   angle;
						
						if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
						
						angle = [self Angle:[[points objectAtIndex: 0] point] :[[points objectAtIndex: 1] point] : [[points objectAtIndex: 2] point]];
						
						sprintf (line2, "Angle: %0.3f / %0.3f", angle, 360 - angle);
						
						[self prepareTextualData:line1 :line2 :line3 :line4 :line5 location:tPt];
					}
				}
			}
			
			if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
			{
				NSPoint tempPt = [[[[NSApp currentEvent] window] contentView] convertPoint: [NSEvent mouseLocation] toView: curView];
				tempPt.y = [curView drawingFrameRect].size.height - tempPt.y ;
				tempPt = [curView ConvertFromView2GL:tempPt];
				
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( thickness * 3);
				glBegin( GL_POINTS);
				for( long i = 0; i < [points count]; i++) {
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
	long				no;
	float				*data;
	
	data = [self dataValuesAsFloatPointer: &no];
	
	if( data)
	{
		for( long i = 0 ; i < no; i++) {
			[array addObject:[NSNumber numberWithFloat: data[ i]]];
		}
		
		free( data);
	}
	
	return array;
}


- (NSMutableDictionary*) dataString
{
	NSMutableDictionary*		array = 0L;
	NSMutableArray				*ptsTemp = self.points;
		
	switch( type)
	{
		case tOval:
		case tROI:
		//JJCP
		case tDynAngle:
		//JJCP
		case tAxis:
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
			
			long length = 0;
			long i;
			for( i = 0; i < [ptsTemp count]-1; i++ ) {
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
		//JJCP
		case tDynAngle:
		//JJCP
		case tAxis:
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
				float area=0.0;;
				for( long i = 0; i < textureWidth*textureHeight;i++)
					if (textureBuffer[i]!=0) area++;
				return (area*pixelSpacingX*pixelSpacingY)/100.;
			}
			break;
	}
	
	return 0.0f;
}

- (NSPoint) centroid {
	
	if ( type == tROI || type == tOval ) {
		return rect.origin;
	}
	
	NSArray	*pts = self.points;
	
	int num_points = [pts count];
	
	NSPoint centroid;
	
	for ( int i = 0; i < num_points; i++ ) {
		centroid.x += [[pts objectAtIndex:i] x] / num_points;
		centroid.y += [[pts objectAtIndex:i] y] / num_points;
	}
	
	return centroid;
}


- (void) addMarginToBuffer: (int) margin
{
	int newWidth = textureWidth + 2*margin;
	int newHeight = textureHeight + 2*margin;
	unsigned char* newBuffer = (unsigned char*)calloc(newWidth*newHeight, sizeof(unsigned char));
	
	if(newBuffer) {
		for( int i=0; i<margin; i++) {
			// skip the 'margin' first lines
			newBuffer += newWidth; 
		}
		
		unsigned char	*temptextureBuffer = textureBuffer;
		
		for( int i=0; i<textureHeight; i++ ) {
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

- (void)setLayerImage:(NSImage*)image;
{
	if(layerImage) [layerImage release];
	layerImage = image;
	[layerImage retain];
	
	isLayerOpacityConstant = YES;
	canColorizeLayer = NO;
	
	NSSize imageSize = [layerImage size];
	float imageWidth = imageSize.width;
	float imageHeight = imageSize.height;
	
	float scaleFactorX = layerPixelSpacingX / pixelSpacingX;
	float scaleFactorY = layerPixelSpacingY / pixelSpacingY;
	
	NSPoint p1, p2, p3, p4;
	p1 = NSMakePoint(0.0, 0.0);
	p2 = NSMakePoint(imageWidth*scaleFactorX, 0.0);
	p3 = NSMakePoint(imageWidth*scaleFactorX, imageHeight*scaleFactorY);
	p4 = NSMakePoint(0.0, imageHeight*scaleFactorY);

	NSArray *pts = [NSArray arrayWithObjects:[MyPoint point:p1], [MyPoint point:p2], [MyPoint point:p3], [MyPoint point:p4], nil];
	[points setArray:pts];

	[self generateEncodedLayerImage];
	[[curView openGLContext] makeCurrentContext];
	[self loadLayerImageTexture];
	
}


- (void)loadLayerImageTexture;
{
	NSBitmapImageRep *bitmap;
	bitmap = [[NSBitmapImageRep alloc] initWithData:layerImageJPEG];
	
	
	if(textureBuffer) free(textureBuffer);
	textureBuffer = malloc(  [bitmap bytesPerRow] * [layerImage size].height);
	memcpy( textureBuffer, [bitmap bitmapData], [bitmap bytesPerRow] * [layerImage size].height);
	
	if(!isLayerOpacityConstant)// && opacity<1.0)
	{
		unsigned char*	argbPtr = (unsigned char*) textureBuffer;
		long			ss = [bitmap bytesPerRow]/4 * [layerImage size].height;
		
		while( ss-->0)
		{
			*argbPtr = (*(argbPtr+1) + *(argbPtr+2) + *(argbPtr+3)) / 3 * opacity;
			argbPtr+=4;
		}
	}

	if(canColorizeLayer && layerColor)
	{
		vImage_Buffer src, dest;
		
		dest.height = [layerImage size].height;
		dest.width = [layerImage size].width;
		dest.rowBytes = [bitmap bytesPerRow];
		dest.data = textureBuffer;
		
		src = dest;
		
		src.data = [bitmap bitmapData];
		
		unsigned char	redTable[ 256], greenTable[ 256], blueTable[ 256], alphaTable[ 256];
			
		for( int i = 0; i < 256; i++ ) {
			redTable[i] = i * [layerColor redComponent];
			greenTable[i] = i * [layerColor greenComponent];
			blueTable[i] = i * [layerColor blueComponent];
			alphaTable[i] = i;
		}
		
		//vImageOverwriteChannels_ARGB8888(const vImage_Buffer *newSrc, &src, &dest, 0x4, 0);
		
		#if __BIG_ENDIAN__
		vImageTableLookUp_ARGB8888( &src, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) redTable, (Pixel_8*) greenTable, (Pixel_8*) blueTable, 0);
		#else
		vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) blueTable, (Pixel_8*) greenTable, (Pixel_8*) redTable, (Pixel_8*) &alphaTable, 0);
		#endif

//		vImageTableLookUp_ARGB8888( &src, &dest, (Pixel_8*) redTable , (Pixel_8*) greenTable, (Pixel_8*)blueTable, (Pixel_8*) &alphaTable, 0);
	}

	[[curView openGLContext] makeCurrentContext];

	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	if(textureName)
		glDeleteTextures(1, &textureName);
		
	textureName = 0L;
	glGenTextures(1, &textureName);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/4);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);

//	if(!isLayerOpacityConstant)
//	{
//		NSLog(@"isLayerOpacityConstant : NO");
//		glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, [layerImage size].width, [layerImage size].height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, textureBuffer);
//	}
//	else
//	{
//		NSLog(@"isLayerOpacityConstant : YES");
//		glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, [layerImage size].width, [layerImage size].height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, textureBuffer);
//	}

	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, [layerImage size].width, [layerImage size].height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, textureBuffer);

	[bitmap release];
}

- (void)generateEncodedLayerImage;
{
	if(layerImageJPEG) [layerImageJPEG release];
	
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [layerImage TIFFRepresentation]];
	NSSize size = [layerImage size];
	NSDictionary *imageProps;
	if(size.height>512 && size.width>512)
		imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.3] forKey:NSImageCompressionFactor];
	else
		imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
	layerImageJPEG = [[imageRep representationUsingType:NSJPEG2000FileType properties:imageProps] retain];	//NSJPEGFileType
}

NSInteger sortPointArrayAlongX(id point1, id point2, void *context)
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

	if(p2.y > p3.y)
	{
		tempPoint = p2;
		p2 = p3;
		p3 = tempPoint;
	}
	
	if(p1.x==p2.x || p1.x==p3.x) // no rotation...
	{
		float minX = p1.x;
		float maxX = p4.x;

		float minY = p1.y;
		if(p2.y<minY) minY = p2.y;
		if(p4.y<minY) minY = p4.y;

		float maxY = p1.y;
		if(p2.y>maxY) maxY = p2.y;
		if(p4.y>maxY) maxY = p4.y;

		return (point.x>=minX && point.x<=maxX && point.y<=maxY && point.y>=minY);
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

- (void)setIsLayerOpacityConstant:(BOOL)boo;
{
	isLayerOpacityConstant = boo;
	needsLoadTexture = YES;
}

- (void)setCanColorizeLayer:(BOOL)boo;
{
	canColorizeLayer = boo;
	needsLoadTexture = YES;
}

@end
