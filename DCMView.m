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

	20051217	DDP	Added support for page up and page down to decrement or increment the image.
	20060110	DDP	Reducing the variable duplication of userDefault objects (work in progress).
	20060114	Changed off Fullscren to offFullScreen.
	20060119	SUV
*/


#import <DCMView.h>
#import "StringTexture.h"
#import <DCMPix.h>
#import "ROI.h"
#import "NSFont_OpenGL.h"
#import "DCMCursor.h"
#include <Accelerate/Accelerate.h>

#import "ViewerController.h"
#import "MPRController.h"
#import "ThickSlabController.h"
#import "browserController.h"
#import "AppController.h"
#import "MPR2DController.h"
#import "MPR2DView.h"
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"
#import "ROIWindow.h"
#import "ToolbarPanel.h"

#include <QuickTime/ImageCompression.h> // for image loading and decompression
#include <QuickTime/QuickTimeComponents.h> // for file type support

#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#if defined (MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	#import <CoreVideo/CoreVideo.h>
#endif

#import "DefaultsOsiriX.h"
//#include <OpenGL/gl.h> // for OpenGL API
//#include <OpenGL/glext.h> // for OpenGL extension support 

#include "NSFont_OpenGL/NSFont_OpenGL.h"

@class OrthogonalMPRPETCTView;

#define BS 10.

//#define TEXTRECTMODE GL_TEXTURE_2D
//GL_TEXTURE_2D
//#define RECTANGLE false
//GL_TEXTURE_RECTANGLE_EXT - GL_TEXTURE_2D



extern		NSThread					*mainThread;
extern		BOOL						USETOOLBARPANEL;
extern		ToolbarPanelController		*toolbarPanel[10];
extern      BrowserController			*browserWindow;
extern		AppController				*appController;
			short						syncro = syncroLOC;
static		float						deg2rad = 3.14159265358979/180.0; 
extern		long						numberOf2DViewer;
			BOOL						display2DMPRLines = YES;

extern NSMutableDictionary				*plugins;

static		unsigned char				*PETredTable = 0L, *PETgreenTable = 0L, *PETblueTable = 0L;

static		BOOL						NOINTERPOLATION = NO, FULL32BITPIPELINE = NO, IndependentCRWLWW, COPYSETTINGSINSERIES, pluginOverridesMouse = NO;  // Allows plugins to override mouse click actions.
static		int							CLUTBARS, ANNOTATIONS;
static		BOOL						gClickCountSet = NO;
static		float						margin = 2;

NSString *pasteBoardOsiriX = @"OsiriX pasteboard";
NSString *pasteBoardOsiriXPlugin = @"OsiriXPluginDataType";

#define CROSS(dest,v1,v2) \
          dest[0]=v1[1]*v2[2]-v1[2]*v2[1]; \
          dest[1]=v1[2]*v2[0]-v1[0]*v2[2]; \
          dest[2]=v1[0]*v2[1]-v1[1]*v2[0];
		  
#define DOT(v1,v2) (v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2])

#define SUB(dest,v1,v2) dest[0]=v1[0]-v2[0]; \
						dest[1]=v1[1]-v2[1]; \
						dest[2]=v1[2]-v2[2]; 

XYZ ArbitraryRotate(XYZ p,double theta,XYZ r)
{
   XYZ q = {0.0,0.0,0.0};
   float costheta,sintheta;

//   Normalise(&r);
   costheta = cos(theta);
   sintheta = sin(theta);

   q.x += (costheta + (1 - costheta) * r.x * r.x) * p.x;
   q.x += ((1 - costheta) * r.x * r.y - r.z * sintheta) * p.y;
   q.x += ((1 - costheta) * r.x * r.z + r.y * sintheta) * p.z;

   q.y += ((1 - costheta) * r.x * r.y + r.z * sintheta) * p.x;
   q.y += (costheta + (1 - costheta) * r.y * r.y) * p.y;
   q.y += ((1 - costheta) * r.y * r.z - r.x * sintheta) * p.z;

   q.z += ((1 - costheta) * r.x * r.z - r.y * sintheta) * p.x;
   q.z += ((1 - costheta) * r.y * r.z + r.x * sintheta) * p.y;
   q.z += (costheta + (1 - costheta) * r.z * r.z) * p.z;

   return(q);
}

short intersect3D_2Planes( float *Pn1, float *Pv1, float *Pn2, float *Pv2, float *u, float *iP)
{
	CROSS(u, Pn1, Pn2);         // cross product -> perpendicular vector
	
	float    ax = (u[0] >= 0 ? u[0] : -u[0]);
    float    ay = (u[1] >= 0 ? u[1] : -u[1]);
    float    az = (u[2] >= 0 ? u[2] : -u[2]);
	
    // test if the two planes are parallel
    if ((ax+ay+az) < 0.01)
	{   // Pn1 and Pn2 are near parallel
        // test if disjoint or coincide
        //Vector   v = Pn2.V0 - Pn1.V0;

        //if (dot(Pn1.n, v) == 0)         // Pn2.V0 lies in Pn1
        //    return -2;                   // Pn1 and Pn2 coincide
        //else 
            return -1;                   // Pn1 and Pn2 are disjoint
    }
	
    // Pn1 and Pn2 intersect in a line
    // first determine max abs coordinate of cross product
    int      maxc;                      // max coordinate
    if (ax > ay) {
        if (ax > az)
             maxc = 1;
        else maxc = 3;
    }
    else {
        if (ay > az)
             maxc = 2;
        else maxc = 3;
    }
	
    // next, to get a point on the intersect line
    // zero the max coord, and solve for the other two
	
    float    d1, d2;            // the constants in the 2 plane equations
    d1 = -DOT(Pn1, Pv1); 		// note: could be pre-stored with plane
    d2 = -DOT(Pn2, Pv2); 		// ditto
	
    switch (maxc) {            // select max coordinate
    case 1:                    // intersect with x=0
        iP[0] = 0;
        iP[1] = (d2*Pn1[2] - d1*Pn2[2]) / u[0];
        iP[2] = (d1*Pn2[1] - d2*Pn1[1]) / u[0];
        break;
    case 2:                    // intersect with y=0
        iP[0] = (d1*Pn2[2] - d2*Pn1[2]) / u[1];
        iP[1] = 0;
        iP[2] = (d2*Pn1[0] - d1*Pn2[0]) / u[1];
        break;
    case 3:                    // intersect with z=0
        iP[0] = (d2*Pn1[1] - d1*Pn2[1]) / u[2];
        iP[1] = (d1*Pn2[0] - d2*Pn1[0]) / u[2];
        iP[2] = 0;
    }
    return noErr;
}


// ---------------------------------
/*
static void DrawGLTexelGrid (float textureWidth, float textureHeight, float imageWidth, float imageHeight, float zoom) // in pixels
{
    long i; // iterator
    float perpenCoord, coord, coordStep; //  perpendicular coordinate, dawing (iteratoring) coordinate, coordiante step amount per line
	
	glBegin (GL_LINES); // draw using lines
		// vertical lines
		perpenCoord = 0.5f * imageHeight * zoom; // 1/2 height of image in world space
		coord =  -0.5f * imageWidth * zoom; // starting scaled coordinate for half of image width (world space)
		coordStep = imageWidth / textureWidth * zoom; // space between each line (maps texture size to image size)
		for (i = 0; i <= textureWidth; i++) // ith column
		{
			glVertex3f (coord, -perpenCoord, 0.0f); // draw from current column, top of image to...
			glVertex3f (coord, perpenCoord, 0.0f); // current column, bottom of image
			coord += coordStep; // step to next column
		}
		// horizontal lines
		perpenCoord = 0.5f * imageWidth * zoom; // 1/2 width of image in world space
    	coord =  -0.5f * imageHeight * zoom; // scaled coordinate for half of image height (actual drawing coords)
		coordStep = imageHeight / textureHeight * zoom; // space between each line (maps texture size to image size)
		for (i = 0; i <= textureHeight; i++) // ith row
		{
			glVertex3f (-perpenCoord, coord, 0.0f); // draw from current row, left edge of image to...
			glVertex3f (perpenCoord, coord, 0.0f);// current row, right edge of image
			coord += coordStep; // step to next row
		}
	glEnd(); // end our set of lines
}*/

static void DrawGLImageTile (unsigned long drawType, float imageWidth, float imageHeight, float zoom, float textureWidth, float textureHeight,
                            float offsetX, float offsetY, float endX, float endY, Boolean texturesOverlap, Boolean textureRectangle)
{
	float startXDraw = (offsetX - imageWidth * 0.5f) * zoom; // left edge of poly: offset is in image local coordinates convert to world coordinates
	float endXDraw = (endX - imageWidth * 0.5f) * zoom; // right edge of poly: offset is in image local coordinates convert to world coordinates
	float startYDraw = (offsetY - imageHeight * 0.5f) * zoom; // top edge of poly: offset is in image local coordinates convert to world coordinates
	float endYDraw = (endY - imageHeight * 0.5f) * zoom; // bottom edge of poly: offset is in image local coordinates convert to world coordinates
	float texOverlap =  texturesOverlap ? 1.0f : 0.0f; // size of texture overlap, switch based on whether we are using overlap or not
	float startXTexCoord = texOverlap / (textureWidth + 2.0f * texOverlap); // texture right edge coordinate (stepped in one pixel for border if required)
	float endXTexCoord = 1.0f - startXTexCoord; // texture left edge coordinate (stepped in one pixel for border if required)
	float startYTexCoord = texOverlap / (textureHeight + 2.0f * texOverlap); // texture top edge coordinate (stepped in one pixel for border if required)
	float endYTexCoord = 1.0f - startYTexCoord; // texture bottom edge coordinate (stepped in one pixel for border if required)
	if (textureRectangle)
	{
		startXTexCoord = texOverlap; // texture right edge coordinate (stepped in one pixel for border if required)
		endXTexCoord = textureWidth + texOverlap; // texture left edge coordinate (stepped in one pixel for border if required)
		startYTexCoord = texOverlap; // texture top edge coordinate (stepped in one pixel for border if required)
		endYTexCoord = textureHeight + texOverlap; // texture bottom edge coordinate (stepped in one pixel for border if required)
	}
	if (endX > (imageWidth + 0.5)) // handle odd image sizes, (+0.5 is to ensure there is no fp resolution problem in comparing two fp numbers)
	{
		endXDraw = (imageWidth * 0.5f) * zoom; // end should never be past end of image, so set it there
		if (textureRectangle)
			endXTexCoord -= 1.0f;
		else
			endXTexCoord = 1.0f -  2.0f * startXTexCoord; // for the last texture in odd size images there are two texels of padding so step in 2
	}
	if (endY > (imageHeight + 0.5f)) // handle odd image sizes, (+0.5 is to ensure there is no fp resolution problem in comparing two fp numbers)
	{
		endYDraw = (imageHeight * 0.5f) * zoom; // end should never be past end of image, so set it there
		if (textureRectangle)
			endYTexCoord -= 1.0f;
		else
			endYTexCoord = 1.0f -  2.0f * startYTexCoord; // for the last texture in odd size images there are two texels of padding so step in 2
	}
	
	glBegin (drawType); // draw either tri strips of line strips (so this will drw either two tris or 3 lines)
		glTexCoord2f (startXTexCoord, startYTexCoord); // draw upper left in world coordinates
		glVertex3d (startXDraw, startYDraw, 0.0);

		glTexCoord2f (endXTexCoord, startYTexCoord); // draw lower left in world coordinates
		glVertex3d (endXDraw, startYDraw, 0.0);

		glTexCoord2f (startXTexCoord, endYTexCoord); // draw upper right in world coordinates
		glVertex3d (startXDraw, endYDraw, 0.0);

		glTexCoord2f (endXTexCoord, endYTexCoord); // draw lower right in world coordinates
		glVertex3d (endXDraw, endYDraw, 0.0);
	glEnd();
	
	// finish strips
/*	if (drawType == GL_LINE_STRIP) // draw top and bottom lines which were not draw with above
	{
		glBegin (GL_LINES);
			glVertex3d(startXDraw, endYDraw, 0.0); // top edge
			glVertex3d(startXDraw, startYDraw, 0.0);
	
			glVertex3d(endXDraw, startYDraw, 0.0); // bottom edge
			glVertex3d(endXDraw, endYDraw, 0.0);
		glEnd();
	}*/
}


static long GetNextTextureSize (long textureDimension, long maxTextureSize, Boolean textureRectangle)
{
	long targetTextureSize = maxTextureSize; // start at max texture size
	if (textureRectangle)
	{
		if (textureDimension >= targetTextureSize) // the texture dimension is greater than the target texture size (i.e., it fits)
			return targetTextureSize; // return corresponding texture size
		else
			return textureDimension; // jusr return the dimension
	}
	else
	{
		do // while we have txture sizes check for texture value being equal or greater
		{  
			if (textureDimension >= targetTextureSize) // the texture dimension is greater than the target texture size (i.e., it fits)
				return targetTextureSize; // return corresponding texture size
		}
		while (targetTextureSize >>= 1); // step down to next texture size smaller
	}
	return 0; // no textures fit so return zero
}

static long GetTextureNumFromTextureDim (long textureDimension, long maxTextureSize, Boolean texturesOverlap, Boolean textureRectangle) 
{
	// start at max texture size 
	// loop through each texture size, removing textures in turn which are less than the remaining texture dimension
	// each texture has 2 pixels of overlap (one on each side) thus effective texture removed is 2 less than texture size
	
	long i = 0; // initially no textures
	long bitValue = maxTextureSize; // start at max texture size
	long texOverlapx2 = texturesOverlap ? 2 : 0;
	textureDimension -= texOverlapx2; // ignore texture border since we are using effective texure size (by subtracting 2 from the initial size)
	if (textureRectangle)
	{
		// count number of full textures
		while (textureDimension > (bitValue - texOverlapx2)) // while our texture dimension is greater than effective texture size (i.e., minus the border)
		{
			i++; // count a texture
			textureDimension -= bitValue - texOverlapx2; // remove effective texture size
		}
		// add one partial texture
		i++; 
	}
	else
	{
		do
		{
			while (textureDimension >= (bitValue - texOverlapx2)) // while our texture dimension is greater than effective texture size (i.e., minus the border)
			{
				i++; // count a texture
				textureDimension -= bitValue - texOverlapx2; // remove effective texture size
			}
		}
		while ((bitValue >>= 1) > texOverlapx2); // step down to next texture while we are greater than two (less than 4 can't be used due to 2 pixel overlap)
	if (textureDimension > 0x0) // if any textureDimension is left there is an error, because we can't texture these small segments and in anycase should not have image pixels left
		NSLog (@"GetTextureNumFromTextureDim error: Texture to small to draw, should not ever get here, texture size remaining");
	}
	return i; // return textures counted
}

float min(float a, float b)
{
	if(a < b) return a;
	else return b;
}

float distanceNSPoint(NSPoint p1, NSPoint p2)
{
	float dx = p1.x - p2.x;
	float dy = p1.y - p2.y;
	return sqrt(dx*dx+dy*dy);
}

BOOL lineIntersectsRect(NSPoint lineStarts, NSPoint lineEnds, NSRect rect)
{
	if(NSPointInRect(lineStarts, rect) || NSPointInRect(lineEnds, rect)) return YES;

	float width = fabsf(lineStarts.x - lineEnds.x);
	float height = fabsf(lineStarts.y - lineEnds.y);
	NSRect lineBoundingBox = NSMakeRect(min(lineStarts.x, lineEnds.x), min(lineStarts.y, lineEnds.y), width, height);

	if(NSIsEmptyRect(lineBoundingBox))
	{
		if(distanceNSPoint(lineStarts, lineEnds)<=1) // really small rect
			return NO;
		else // the line is vertical or horizontal
		{
			NSPoint midPoint;
			midPoint.x = (lineStarts.x+lineEnds.x)/2.0;
			midPoint.y = (lineStarts.y+lineEnds.y)/2.0;
			return lineIntersectsRect(lineStarts, midPoint, rect) || lineIntersectsRect(midPoint, lineEnds, rect);
		}
	}
	else if(NSIntersectsRect(lineBoundingBox, rect))
	{
		NSPoint midPoint = NSMakePoint(NSMidX(lineBoundingBox), NSMidY(lineBoundingBox));
		return lineIntersectsRect(lineStarts, midPoint, rect) || lineIntersectsRect(midPoint, lineEnds, rect);
	}
	else return NO;
}

@implementation DCMView

+ (BOOL) intersectionBetweenTwoLinesA1:(NSPoint) a1 A2:(NSPoint) a2 B1:(NSPoint) b1 B2:(NSPoint) b2 result:(NSPoint*) r
{
	float x1 = a1.x,	y1 = a1.y;
	float x2 = a2.x,	y2 = a2.y;
	float x3 = b1.x,	y3 = b1.y;
	float x4 = b2.x,	y4 = b2.y;
	
	float d = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4);
	
	if (d == 0) return NO;
	
	float xi = ((x3-x4)*(x1*y2-y1*x2)-(x1-x2)*(x3*y4-y3*x4))/d;
	float yi = ((y3-y4)*(x1*y2-y1*x2)-(y1-y2)*(x3*y4-y3*x4))/d;
	
	float mag1 = [DCMView Magnitude: a1 : a2];
    float U1 =	(	( ( xi - x1 ) * ( x2 - x1 ) ) +
					( ( yi - y1 ) * ( y2 - y1 ) ) );
	U1 /= (mag1*mag1);
	
	float mag2 = [DCMView Magnitude: b1 : b2];
	float U2 =	(	( ( xi - x3 ) * ( x4 - x3 ) ) +
					( ( yi - y3 ) * ( y4 - y3 ) ) );
	U2 /= (mag2 * mag2);
	
	if( U1 >= 0 && U1 <= 1 && U2 >= 0 && U2 <= 1)
	{
		if( r)
		{
			r->x = xi;
			r->y = yi;
		}
		
		return YES;
	}
	
	return NO;
}

+ (float) Magnitude:( NSPoint) Point1 :(NSPoint) Point2 
{
    NSPoint Vector;

    Vector.x = Point2.x - Point1.x;
    Vector.y = Point2.y - Point1.y;

    return (float)sqrt( Vector.x * Vector.x + Vector.y * Vector.y);
}

+ (int) DistancePointLine: (NSPoint) Point :(NSPoint) startPoint :(NSPoint) endPoint :(float*) Distance
{
    float   LineMag;
    float   U;
    NSPoint Intersection;
 
    LineMag = [DCMView Magnitude: endPoint : startPoint];
 
    U = ( ( ( Point.x - startPoint.x ) * ( endPoint.x - startPoint.x ) ) +
        ( ( Point.y - startPoint.y ) * ( endPoint.y - startPoint.y ) ) );
		
	U /= ( LineMag * LineMag );

//    if( U < 0.0f || U > 1.0f )
//	{
//		NSLog(@"Distance Err");
//		return 0;   // closest point does not fall within the line segment
//	}
	
    Intersection.x = startPoint.x + U * ( endPoint.x - startPoint.x );
    Intersection.y = startPoint.y + U * ( endPoint.y - startPoint.y );

//    Intersection.Z = LineStart->Z + U * ( endPoint->Z - LineStart->Z );
 
    *Distance = [DCMView Magnitude: Point :Intersection];
 
    return 1;
}

+ (NSString*) findWLWWPreset: (float) wl :(float) ww :(DCMPix*) pix
{
	NSDictionary	*list = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"];
	NSArray			*allKeys = [list allKeys];
	
	int i;
	
	for( i = 0 ; i < [allKeys count] ; i++)
	{
		NSArray		*value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey: [allKeys objectAtIndex: i]];
		
		if( [[value objectAtIndex: 0] floatValue] == wl && [[value objectAtIndex: 1] floatValue] == ww) return [allKeys objectAtIndex: i];
	}
	
	if( pix)
	{
		if( wl == [pix fullwl] && ww == [pix fullww]) return NSLocalizedString( @"Full Dynamic", 0L);
		if( wl == [pix savedWL] && ww == [pix savedWW]) return NSLocalizedString(@"Default WL & WW", nil);
	}
	
	return NSLocalizedString( @"Other", 0L);
}

+ (long) lengthOfString:( char *) cstr forFont:(long *)fontSizeArray
{
	long i = 0, temp = 0;
	
	while( cstr[ i] != 0)
	{
		temp += fontSizeArray[ cstr[ i]];
		i++;
	}
	return temp;
}

+(void) setDefaults
{
	NOINTERPOLATION = [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"];
	FULL32BITPIPELINE = [[NSUserDefaults standardUserDefaults] boolForKey:@"FULL32BITPIPELINE"];
	FULL32BITPIPELINE = NO;
	
	IndependentCRWLWW = [[NSUserDefaults standardUserDefaults] boolForKey:@"IndependentCRWLWW"];
	COPYSETTINGSINSERIES = [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGSINSERIES"];
	CLUTBARS = [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	ANNOTATIONS = [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
}

+(void) setCLUTBARS:(int) c ANNOTATIONS:(int) a
{
	CLUTBARS = c;
	ANNOTATIONS = a;
}

+ (NSSize)sizeOfString:(NSString *)string forFont:(NSFont *)font
{
	NSDictionary *attr = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:string attributes:attr] autorelease];
	return [attrString size];
}

- (IBAction)print:(id)sender
{
	if ([self is2DViewer] == YES)
	{
		[[self windowController] print: self];
	}
	else
	{
		NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo]; 
		
		NSLog(@"Orientation %d", [printInfo orientation]);
		
		NSImage *im = [self nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];
		
		NSLog( @"w:%f, h:%f", [im size].width, [im size].height);
		
		if ([im size].height < [im size].width)
			[printInfo setOrientation: NSLandscapeOrientation];
		else
			[printInfo setOrientation: NSPortraitOrientation];
		
		//NSRect	r = NSMakeRect( 0, 0, [printInfo paperSize].width, [printInfo paperSize].height);
		
		NSRect	r = NSMakeRect( 0, 0, [im size].width/2, [im size].height/2);
		
		NSImageView *imageView = [[NSImageView alloc] initWithFrame: r];
		
	//	r = NSMakeRect( 0, 0, [im size].width, [im size].height);
		
	//	NSWindow	*pwindow = [[NSWindow alloc]  initWithContentRect: r styleMask: NSBorderlessWindowMask backing: NSBackingStoreNonretained defer: NO];
		
	//	[pwindow setContentView: imageView];
		
		[im setScalesWhenResized:YES];
		
		[imageView setImage: im];
		[imageView setImageScaling: NSScaleProportionally];
		[imageView setImageAlignment: NSImageAlignCenter];
		
		[printInfo setVerticallyCentered:YES];
		[printInfo setHorizontallyCentered:YES];
		
	//	[printInfo setTopMargin: 0.0f];
	//	[printInfo setBottomMargin: 0.0f];
	//	[printInfo setRightMargin: 0.0f];
	//	[printInfo setLeftMargin: 0.0f];


		// print imageView
		
		[printInfo setHorizontalPagination:NSFitPagination];
		[printInfo setVerticalPagination:NSFitPagination];
		
		NSPrintOperation * printOperation = [NSPrintOperation printOperationWithView: imageView];
		
		[printOperation runOperation];
		
	//	[pwindow release];
		[imageView release];
		[im release];
	}
} 

- (void) erase2DPointMarker
{
	display2DPoint = NSMakePoint(0,0);
}

- (void) draw2DPointMarker
{
	if( display2DPoint.x != 0 || display2DPoint.y != 0)
	{
		glColor3f (0.0f, 0.5f, 1.0f);
		glLineWidth(2.0);
		glBegin(GL_LINES);
		
		float crossx, crossy;
		
		crossx = display2DPoint.x - [curDCM pwidth]/2.;
		crossy = display2DPoint.y - [curDCM pheight]/2.;
		
		glVertex2f( scaleValue * (crossx - 40), scaleValue*(crossy));
		glVertex2f( scaleValue * (crossx - 5), scaleValue*(crossy));
		glVertex2f( scaleValue * (crossx + 40), scaleValue*(crossy));
		glVertex2f( scaleValue * (crossx + 5), scaleValue*(crossy));
		
		glVertex2f( scaleValue * (crossx), scaleValue*(crossy-40));
		glVertex2f( scaleValue * (crossx), scaleValue*(crossy-5));
		glVertex2f( scaleValue * (crossx), scaleValue*(crossy+5));
		glVertex2f( scaleValue * (crossx), scaleValue*(crossy+40));
		glEnd();
	}
}

- (void)drawRepulsorToolArea;
{
	glEnable(GL_BLEND);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	long i;
	
	int circleRes = 20;
	circleRes = (repulsorRadius>5) ? 30 : circleRes;
	circleRes = (repulsorRadius>10) ? 40 : circleRes;
	circleRes = (repulsorRadius>50) ? 60 : circleRes;
	circleRes = (repulsorRadius>70) ? 80 : circleRes;
	
	glColor4f(1.0,1.0,0.0,repulsorAlpha);

	glBegin(GL_POLYGON);	
	for(i = 0; i < circleRes ; i++)
	{
		// M_PI defined in cmath.h
		float alpha = i * 2 * M_PI /circleRes;
		glVertex2f( repulsorPosition.x + repulsorRadius*cos(alpha) * scaleValue, repulsorPosition.y + repulsorRadius*sin(alpha) * scaleValue);//*[curDCM pixelSpacingY]/[curDCM pixelSpacingX]
	}
	glEnd();
	glDisable(GL_BLEND);
}

- (void)setAlphaRepulsor:(NSTimer*)theTimer
{
	if (repulsorAlpha >= 0.4) repulsorAlphaSign = -1.0;
	else if (repulsorAlpha <= 0.1) repulsorAlphaSign = 1.0;
	
	repulsorAlpha += repulsorAlphaSign*0.02;
	
	[self setNeedsDisplay:YES];
}


- (void)drawROISelectorRegion;
{
	glEnable(GL_BLEND);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	#define ROISELECTORREGION_R 0.8
	#define ROISELECTORREGION_G 0.8
	#define ROISELECTORREGION_B 1.0

	// inside: fill
	glColor4f(ROISELECTORREGION_R, ROISELECTORREGION_G, ROISELECTORREGION_B, 0.3);
	glBegin(GL_POLYGON);		
	glVertex2f(ROISelectorStartPoint.x, ROISelectorStartPoint.y);
	glVertex2f(ROISelectorStartPoint.x, ROISelectorEndPoint.y);
	glVertex2f(ROISelectorEndPoint.x, ROISelectorEndPoint.y);
	glVertex2f(ROISelectorEndPoint.x, ROISelectorStartPoint.y);
	glEnd();

	// border
	glColor4f(ROISELECTORREGION_R, ROISELECTORREGION_G, ROISELECTORREGION_B, 0.75);
	glBegin(GL_LINE_LOOP);
	glVertex2f(ROISelectorStartPoint.x, ROISelectorStartPoint.y);
	glVertex2f(ROISelectorStartPoint.x, ROISelectorEndPoint.y);
	glVertex2f(ROISelectorEndPoint.x, ROISelectorEndPoint.y);
	glVertex2f(ROISelectorEndPoint.x, ROISelectorStartPoint.y);
	glEnd();
	
	glDisable(GL_BLEND);
}

- (void) Display3DPoint:(NSNotification*) note
{
	if( stringID == 0L)
	{
		NSMutableArray	*v = [note object];
		
		if( v == dcmPixList)
		{
			display2DPoint.x = [[[note userInfo] valueForKey:@"x"] intValue];
			display2DPoint.y = [[[note userInfo] valueForKey:@"y"] intValue];
			[self setNeedsDisplay: YES];
		}
	}
}

-(OrthogonalMPRController*) controller
{
	return 0L;	// Only defined in herited classes
}

- (void) stopROIEditingForce:(BOOL) force
{
	long i, x, no;
	
	drawingROI = NO;
	for( i = 0; i < [curRoiList count]; i++)
	{
		if( curROI != [curRoiList objectAtIndex:i])
		{
			if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selectedModify || [[curRoiList objectAtIndex:i] ROImode] == ROI_drawing)
			{
				ROI	*roi = [curRoiList objectAtIndex:i];
				[roi setROIMode: ROI_selected];
			}
		}
	}
	
	if( curROI)
	{
		if( [curROI ROImode] == ROI_selectedModify || [curROI ROImode] == ROI_drawing)
		{
			// Does this ROI have alias in other views?
			for( x = 0, no = 0; x < [dcmRoiList count]; x++)
			{
				if( [[dcmRoiList objectAtIndex: x] containsObject: curROI]) no++;
			}
		
			if( no <= 1 || force == YES)
			{
				[curROI setROIMode: ROI_selected];
				curROI = 0L;
			}
		}
		else
		{
			[curROI setROIMode: ROI_selected];
			curROI = 0L;
		}
	}
}

- (void) stopROIEditing
{
	[self stopROIEditingForce: NO];
}

- (void) blendingPropagate
{
//	if([stringID isEqualToString:@"OrthogonalMPRVIEW"] && blendingView)
//	{
//		[[self controller] blendingPropagate: self];
//	}
//	else 
	if( blendingView)
	{
		if( [stringID isEqualToString:@"Original"])
		{
			float fValue = [self scaleValue] / [self pixelSpacing];
			[blendingView setScaleValue: fValue * [blendingView pixelSpacing]];
		}
		else [blendingView setScaleValue: scaleValue];
		
		[blendingView setRotation: rotation];
		[blendingView setOrigin: origin];
		[blendingView setOriginOffset: originOffset];
	}
}

- (IBAction) roiLoadFromFiles: (id) sender
{
    long    i, j, x, result;
    
    NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:NO];
    
    result = [oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"roi"]];
    
    if (result == NSOKButton) 
    {
        // Unselect all ROIs
        for( i = 0 ; i < [curRoiList count] ; i++) [[curRoiList objectAtIndex: i] setROIMode: ROI_sleep];
        
        for( i = 0; i < [[oPanel filenames] count]; i++)
        {
            NSMutableArray*    roiArray = [NSUnarchiver unarchiveObjectWithFile: [[oPanel filenames] objectAtIndex:i]];

            for( j = 0 ; j < [roiArray count] ; j++)
            {
                [[roiArray objectAtIndex: j] setOriginAndSpacing:[curDCM pixelSpacingX] :[curDCM pixelSpacingY] :NSMakePoint( [curDCM originX], [curDCM originY])];
                [[roiArray objectAtIndex: j] setROIMode: ROI_selected];
                [[roiArray objectAtIndex: j] setRoiFont: labelFontListGL :labelFontListGLSize :self];
                
                [[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: [roiArray objectAtIndex: j] userInfo: nil];
            }
            
            [curRoiList addObjectsFromArray: roiArray];
        }
        
        [self setNeedsDisplay:YES];
    }
}

- (IBAction) roiSaveSelected: (id) sender
{
	NSSavePanel     *panel = [NSSavePanel savePanel];
    short           i;
	
	NSMutableArray  *selectedROIs = [NSMutableArray  arrayWithCapacity:0];
	
	for( i = 0; i < [curRoiList count]; i++)
	{
		if( [[curRoiList objectAtIndex: i] ROImode] == ROI_selected)
		{
			[selectedROIs addObject: [curRoiList objectAtIndex: i]];
		}
	}
	
	if( [selectedROIs count] > 0)
	{
		[panel setCanSelectHiddenExtension:NO];
		[panel setRequiredFileType:@"roi"];
		
		if( [panel runModalForDirectory:0L file:[[selectedROIs objectAtIndex:0] name]] == NSFileHandlingPanelOKButton)
		{
			[NSArchiver archiveRootObject: selectedROIs toFile :[panel filename]];
		}
	}
	else
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Save Error",nil), NSLocalizedString(@"No ROI(s) selected to save!",nil) , NSLocalizedString(@"OK",nil), nil, nil);
	}
}

- (IBAction) roiLoadFromXMLFiles: (id) sender
{
	long	i, x, result;
	
	NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
	
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:NO];
	
	result = [oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"xml"]];
    
    if (result != NSOKButton) return;
	
	// Unselect all ROIs
	for( i = 0 ; i < [curRoiList count] ; i++) [[curRoiList objectAtIndex: i] setROIMode: ROI_sleep];
	
	for( i = 0; i < [[oPanel filenames] count]; i++)
	{
		NSDictionary*	xml = [NSDictionary dictionaryWithContentsOfFile: [[oPanel filenames] objectAtIndex:i]];
		NSArray*		roiArray = [xml objectForKey: @"ROI array"];
		
		if ( roiArray )
		{
			int j;
			for ( j = 0; j < [roiArray count]; j++ )
			{
				NSDictionary *roiDict = [roiArray objectAtIndex: j];
				
				int sliceIndex = [[roiDict objectForKey: @"Slice"] intValue] - 1;
				
				NSMutableArray *roiList = [dcmRoiList objectAtIndex: sliceIndex];
				DCMPix *dcm = [dcmPixList objectAtIndex: sliceIndex];
				
				if ( roiList == nil || dcm == nil ) continue;  // No such slice.  Can't add ROI.
				
				NSArray *pointsStringArray = [roiDict objectForKey: @"ROIPoints"];
				
				int type = tCPolygon;
				if( [pointsStringArray count] == 2) type = tMesure;
				if( [pointsStringArray count] == 1)  type = t2DPoint;
				
				ROI *roi = [[ROI alloc] initWithType: type :[dcm pixelSpacingX] :[dcm pixelSpacingY] :NSMakePoint( [dcm originX], [dcm originY])];
				[roi setName: [roiDict objectForKey: @"Name"]];
				[roi setComments: [roiDict objectForKey: @"Comments"]];
				
				NSMutableArray *pointsArray = [NSMutableArray arrayWithCapacity: 0];
				
				int k;
				for ( k = 0; k < [pointsStringArray count]; k++ ) {
					MyPoint *pt = [MyPoint point: NSPointFromString( [pointsStringArray objectAtIndex: k] )];
					[pointsArray addObject: pt];
				}
				
				[roi setPoints: pointsArray];
				[roi setRoiFont: labelFontListGL :labelFontListGLSize :self];
				
				[roiList addObject: roi];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: roi userInfo: nil];
				
				[roi release];
			}
		}
		else
		{
			// Single ROI - assume current slice
			
			NSArray *pointsStringArray = [xml objectForKey: @"ROIPoints"];
			
			int type = tCPolygon;
			if( [pointsStringArray count] == 2) type = tMesure;
			if( [pointsStringArray count] == 1)  type = t2DPoint;
			
			ROI *roi = [[ROI alloc] initWithType: type :[curDCM pixelSpacingX] :[curDCM pixelSpacingY] :NSMakePoint( [curDCM originX], [curDCM originY])];
			[roi setName: [xml objectForKey: @"Name"]];
			[roi setComments: [xml objectForKey: @"Comments"]];
			
			NSMutableArray *pointsArray = [NSMutableArray arrayWithCapacity: 0];
			
			if( [pointsStringArray count] > 0)
			{
				int j;
				for ( j = 0; j < [pointsStringArray count]; j++ ) {
					MyPoint *pt = [MyPoint point: NSPointFromString( [pointsStringArray objectAtIndex: j] )];
					[pointsArray addObject: pt];
				}
				
				[roi setPoints: pointsArray];
				[roi setROIMode: ROI_selected];
				[roi setRoiFont: labelFontListGL :labelFontListGLSize :self];
				
				[curRoiList addObject: roi];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: roi userInfo: nil];
			}
			
			[roi release];
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void) undo:(id) sender
{
	[[self windowController] undo: sender];
}

- (void) redo:(id) sender
{
	[[self windowController] redo: sender];
}

- (void)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSData *archived_data = [pb dataForType:@"ROIObject"];
	
	if( archived_data)
	{
		[[self windowController] addToUndoQueue:@"roi"];
		
		long	i;
		NSMutableArray*	roiArray = [NSUnarchiver unarchiveObjectWithData: archived_data];
		
		// Unselect all ROIs
		for( i = 0 ; i < [curRoiList count] ; i++) [[curRoiList objectAtIndex: i] setROIMode: ROI_sleep];
		
		for( i = 0 ; i < [roiArray count] ; i++)
		{
			[[roiArray objectAtIndex: i] setOriginAndSpacing:[curDCM pixelSpacingX] :[curDCM pixelSpacingY] :NSMakePoint( [curDCM originX], [curDCM originY])];
			[[roiArray objectAtIndex: i] setROIMode: ROI_selected];
			[[roiArray objectAtIndex: i] setRoiFont: labelFontListGL :labelFontListGLSize :self];
		}
		
		[curRoiList addObjectsFromArray: roiArray];
		
		for( i = 0 ; i < [roiArray count] ; i++)
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: [roiArray objectAtIndex: i] userInfo: nil];

		[self setNeedsDisplay:YES];
	}
}

-(IBAction) copy:(id) sender
{
    NSPasteboard	*pb = [NSPasteboard generalPasteboard];
	BOOL			roiSelected = NO;
	long			i;
	NSMutableArray  *roiSelectedArray = [NSMutableArray arrayWithCapacity:0];
	
	for( i = 0; i < [curRoiList count]; i++)
	{
		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
		{
			roiSelected = YES;
			
			[roiSelectedArray addObject: [curRoiList objectAtIndex:i]];
		}
	}

	if( roiSelected == NO)
	{
		NSImage *im;
		
		[pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
		
		im = [self nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];
		
		[pb setData: [[NSBitmapImageRep imageRepWithData: [im TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] forType:NSTIFFPboardType];
		
		
		[im release];
	}
	else
	{
		[pb declareTypes:[NSArray arrayWithObjects:@"ROIObject", NSStringPboardType, nil] owner:nil];
		[pb setData: [NSArchiver archivedDataWithRootObject: roiSelectedArray] forType:@"ROIObject"];
		
		NSMutableString		*r = [NSMutableString string];
		
		for( i = 0 ; i < [roiSelectedArray count] ; i++)
		{
			[r appendString: [[roiSelectedArray objectAtIndex: i] description]];
			if( i != [roiSelectedArray count]-1) [r appendString:@"\r"];
		}
		
		[pb setString: r  forType:NSStringPboardType];
	}
}

-(IBAction) cut:(id) sender
{
	[self copy:sender];
	
	long	i;
	BOOL	done = NO;
	NSTimeInterval groupID;

	[[self windowController] addToUndoQueue:@"roi"];
	
	for( i = 0; i < [curRoiList count]; i++)
	{
		if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
		{
			groupID = [[curRoiList objectAtIndex:i] groupID];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:[curRoiList objectAtIndex:i] userInfo: 0L];
			[curRoiList removeObjectAtIndex:i];
			i--;
			if(groupID!=0.0)[self deleteROIGroupID:groupID];
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiRemovedFromArray" object: 0L userInfo: 0L];
	
	[self setNeedsDisplay:YES];
}

-(BOOL)yFlipped{
	return yFlipped;
}

- (void) setYFlipped:(BOOL) v {
	yFlipped = v;
	[[self seriesObj]  setValue:[NSNumber numberWithBool:yFlipped] forKey:@"yFlipped"];
	
	[appController setYFlipped: yFlipped];	
    [self setNeedsDisplay:YES];
}

-(BOOL)xFlipped{
	return xFlipped;
}

- (void) setXFlipped:(BOOL) v {
	xFlipped = v;
	[[self seriesObj]  setValue:[NSNumber numberWithBool:xFlipped] forKey:@"xFlipped"];

	[appController setXFlipped: xFlipped];
    [self setNeedsDisplay:YES];
}

- (void)flipVertical: (id)sender {
	[self setYFlipped: !yFlipped];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"]];
}

- (void)flipHorizontal: (id)sender {
	[self setXFlipped: !xFlipped];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"]];
}

- (void) DrawNSStringGL: (NSString*) str :(GLuint) fontL :(long) x :(long) y rightAlignment: (BOOL) right useStringTexture: (BOOL) stringTex
{
	if( stringTex)
	{
		if( stringTextureCache == 0L) stringTextureCache = [[NSMutableDictionary alloc] initWithCapacity: 0];
		
		StringTexture *stringTex = [stringTextureCache objectForKey: str];
		if( stringTex == 0L)
		{
			if( [stringTextureCache count] > 100) [stringTextureCache removeAllObjects];
			
			NSMutableDictionary *stanStringAttrib = [NSMutableDictionary dictionary];
			
			if( fontL == labelFontListGL) [stanStringAttrib setObject:labelFont forKey:NSFontAttributeName];
			else [stanStringAttrib setObject:fontGL forKey:NSFontAttributeName];
			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];

			stringTex = [[StringTexture alloc] initWithString:str withAttributes:stanStringAttrib];
			[stringTex genTexture];
			[stringTextureCache setObject:stringTex forKey:str];
			[stringTex release];
		}
		
		if( right) x -= [stringTex texSize].width;
		else x -= 5;
		
		glEnable (GL_TEXTURE_RECTANGLE_EXT);
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		
		long xc, yc;
		xc = x+2;
		yc = y+1-[stringTex texSize].height;
		glColor4f (0.0f, 0.0f, 0.0f, 1.0f);
		[stringTex drawAtPoint:NSMakePoint( xc+1, yc+1)];
		
		glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
		[stringTex drawAtPoint:NSMakePoint( xc, yc)];
		
		glDisable(GL_BLEND);
		glDisable (GL_TEXTURE_RECTANGLE_EXT);
	}
	else
	{
		char	*cstrOut = (char*) [str UTF8String];
		if( right)
		{
			if( fontL == labelFontListGL) x -= [DCMView lengthOfString:cstrOut forFont:labelFontListGLSize] + 2;
			else x -= [DCMView lengthOfString:cstrOut forFont:fontListGLSize] + 2;
		}
		unsigned char	*lstr = (unsigned char*) cstrOut;
		
		if (fontColor)
			glColor4f([fontColor redComponent], [fontColor greenComponent], [fontColor blueComponent], [fontColor alphaComponent]);
		else
			glColor4f (0.0, 0.0, 0.0, 1.0);

		glRasterPos3d (x+1, y+1, 0);
		
		GLint i = 0;
		while (lstr [i])
		{
			long val = lstr[i++] - ' ';
			if( val < 150 && val >= 0) glCallList (fontL+val);
		}
		
		glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
		
		glRasterPos3d (x, y, 0);
		
		i = 0;
		while (lstr [i])
		{
			long val = lstr[i++] - ' ';
			if( val < 150 && val >= 0) glCallList (fontL+val);
		}
	}
}

- (void) DrawCStringGL: ( char *) cstrOut :(GLuint) fontL :(long) x :(long) y rightAlignment: (BOOL) right useStringTexture: (BOOL) stringTex
{
	[self DrawNSStringGL: [NSString stringWithCString: cstrOut] :(GLuint) fontL :(long) x :(long) y rightAlignment: (BOOL) right useStringTexture: (BOOL) stringTex];
}

- (void) DrawCStringGL: (char *) cstrOut :(GLuint) fontL :(long) x :(long) y
{
	[self DrawCStringGL: (char *) cstrOut :(GLuint) fontL :(long) x :(long) y rightAlignment: NO useStringTexture: NO];
}

- (void) DrawNSStringGL: (NSString*) cstrOut :(GLuint) fontL :(long) x :(long) y
{
	[self DrawNSStringGL: (NSString*) cstrOut :(GLuint) fontL :(long) x :(long) y rightAlignment: NO useStringTexture: NO];
}

- (short) currentTool {return currentTool;}
- (short) currentToolRight  {return currentToolRight;}

-(void) setRightTool:(short) i
{
	currentToolRight = i;
	
	[[NSUserDefaults standardUserDefaults] setInteger:currentToolRight forKey: @"DEFAULTRIGHTTOOL"];
}

-(void) setCurrentTool:(short) i
{
    currentTool = i;

//  Not activated by default    
//	[[NSUserDefaults standardUserDefaults] setInteger:currentTool forKey: @"DEFAULTLEFTTOOL"];
	
	[self stopROIEditingForce: YES];
	
    mesureA.x = mesureA.y = mesureB.x = mesureB.y = 0;
    roiRect.origin.x = roiRect.origin.y = roiRect.size.width = roiRect.size.height = 0;
	
	// Unselect previous ROIs
	for( i = 0; i < [curRoiList count]; i++) [[curRoiList objectAtIndex: i] setROIMode : ROI_sleep];
	
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	
	switch( currentTool)
	{
		case tPlain:
			if ([self is2DViewer] == YES)
			{
				[[self windowController] brushTool: self];
			}
		break;
		
		case tZoom:
			if( [event type] != NSKeyDown)
			{
				if( [event clickCount] == 2)
				{
					origin.x = origin.y = 0;
					rotation = 0;
					[self scaleToFit];
					
					//set value for Series Object Presentation State
					if ([self is2DViewer] == YES)
					{
						[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
						[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
						[[self seriesObj] setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
						[[self seriesObj] setValue:[NSNumber numberWithFloat:0] forKey:@"displayStyle"]; 
						[[self seriesObj] setValue:[NSNumber numberWithFloat:scaleValue] forKey:@"scale"];
					}
				}
				
				if( [event clickCount] == 3)
				{
					origin.x = origin.y = 0;
					rotation = 0;
					scaleValue = 1;
					if ([self is2DViewer] == YES)
					{
						[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
						[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
						[[self seriesObj] setValue:[NSNumber numberWithFloat:scaleValue] forKey:@"scale"];
						[[self seriesObj] setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
						[[self seriesObj] setValue:[NSNumber numberWithFloat:1] forKey:@"displayStyle"];
					}
				}
			}
		break;
		
		case tRotate:
			if( [event type] != NSKeyDown)
			{
				if( [event clickCount] == 2 && gClickCountSet == NO && [[self window] isKeyWindow])
				{
					gClickCountSet = YES;
					
					if ([event modifierFlags] & NSAlternateKeyMask) rotation -= 180;		// -> 180
					else if ([event modifierFlags] & NSShiftKeyMask) rotation -= 90;	// -> 90
					else rotation += 90;	// -> 90
					
					[[self seriesObj] setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
					
					if( [self is2DViewer] == YES) [[self windowController] propagateSettings];
					
					[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"]];
				}
			}
		break;
	}
	
	[self setCursorForView : currentTool];
	[self setNeedsDisplay:YES];
}

- (void) gClickCountSetReset
{
	gClickCountSet = NO;
}

-(void) checkVisible
{
    float newYY, newXX, xx, yy;
    
    xx = origin.x*cos(rotation*deg2rad) + origin.y*sin(rotation*deg2rad);
    yy = origin.x*sin(rotation*deg2rad) - origin.y*cos(rotation*deg2rad);

    NSRect size = [self bounds];
    if( scaleValue > 1.0)
    {
        size.size.width = [curDCM pwidth]*scaleValue;
        size.size.height = [curDCM pheight]*scaleValue;
    }
    
    if( xx*scaleValue < -size.size.width/2) newXX = (-size.size.width/2.0/scaleValue);
    else if( xx*scaleValue > size.size.width/2) newXX = (size.size.width/2.0/scaleValue);
    else newXX = xx;
    
    if( yy*scaleValue < -size.size.height/2) newYY = -size.size.height/2.0/scaleValue;
    else  if( yy*scaleValue > size.size.height/2) newYY = size.size.height/2.0/scaleValue;
    else newYY = yy;
    
    origin.x = newXX*cos(rotation*deg2rad) + newYY*sin(rotation*deg2rad);
    origin.y = newXX*sin(rotation*deg2rad) - newYY*cos(rotation*deg2rad);
}

-(void) setTheMatrix:(NSMatrix*) m
{
    matrix = m;
}

- (void) scaleToFit
{
	if ([[[self seriesObj] valueForKey:@"displayStyle"] intValue] == 0 || [self is2DViewer] == NO) {
		NSRect  sizeView = [self bounds];
		
		if( sizeView.size.width/[curDCM pwidth] < sizeView.size.height/[curDCM pheight]/[curDCM pixelRatio])
		{
			[self setScaleValue:(sizeView.size.width/[curDCM pwidth])];
	//		scaleValue = sizeView.size.width/[curDCM pwidth];
		}
		else
		{
			[self setScaleValue:(sizeView.size.height/[curDCM pheight]/[curDCM pixelRatio])];
	//		scaleValue = sizeView.size.height/[curDCM pheight]/[curDCM pixelRatio];
		}
	}
	else
		[self setScaleValue: [[[self seriesObj] valueForKey:@"scale"] floatValue]];
	
	int i;	
	for( i = 0; i < [dcmPixList count]; i++) [[dcmPixList objectAtIndex: i] setIndependentZoom: scaleValue];
	
	[self setNeedsDisplay:YES];
}

- (void) scaleBy2AndCenterShutter
{
	scaleValue *= 1;//JF20070103 does make better sense not to apply zoom 200%
	origin.x = (([curDCM pwidth] / 2) - ([curDCM DCMPixShutterRectOriginX] + ([curDCM DCMPixShutterRectWidth]/2))) * scaleValue;
	origin.y = -(([curDCM pheight] / 2) - ([curDCM DCMPixShutterRectOriginY] + ([curDCM DCMPixShutterRectHeight]/2))) * scaleValue;
	[self setNeedsDisplay:YES];
}

- (void) setIndexWithReset:(short) index :(BOOL) sizeToFit
{
	long i;
	if( dcmPixList && index != -1)
    {
		[[self window] setAcceptsMouseMovedEvents: YES];

		curROI = 0L;
		
		origin.x = origin.y = 0;
		curImage = index; 
		if( curImage >= [dcmPixList count]) curImage = [dcmPixList count] -1;
		
		[curDCM release];
		curDCM = [[dcmPixList objectAtIndex: curImage] retain];
		
		[curRoiList release];
		
		if( dcmRoiList) curRoiList = [[dcmRoiList objectAtIndex: curImage] retain];
		else
		{
			curRoiList = [[NSMutableArray alloc] initWithCapacity:0];
		}
		
		for( i = 0; i < [curRoiList count]; i++)
		{
			[[curRoiList objectAtIndex:i ] setRoiFont: labelFontListGL :labelFontListGLSize :self];
			[[curRoiList objectAtIndex:i ] recompute];
			// Unselect previous ROIs
			[[curRoiList objectAtIndex: i] setROIMode : ROI_sleep];
		}
		
		curWW = [curDCM ww];
		curWL = [curDCM wl];
		
		rotation = 0;
		
		//get Presentation State info from series Object
		[self updatePresentationStateFromSeries];
		
		[curDCM checkImageAvailble :curWW :curWL];
		
//		NSSize  sizeView = [[self enclosingScrollView] contentSize];
//		[self setFrameSize:sizeView];
		
		NSRect  sizeView = [self bounds];
		if( sizeToFit && [[[self seriesObj] valueForKey:@"displayStyle"] intValue] == 0 || [self is2DViewer] == NO)
		{
			[self scaleToFit];
		}
		
		if( [self is2DViewer] == YES)
		{
			if( [curDCM sourceFile])
			{
				if( [self is2DViewer] == YES) [[self window] setRepresentedFilename: [curDCM sourceFile]];
			}
		}
		
		[self loadTextures];
		[self setNeedsDisplay:YES];
		
//		if( [self is2DViewer] == YES)
//			[[self windowController] propagateSettings];
		
		if( [stringID isEqualToString:@"FinalView"] == YES || [stringID isEqualToString:@"OrthogonalMPRVIEW"]) [self blendingPropagate];
//		if( [stringID isEqualToString:@"Original"] == YES) [self blendingPropagate];

		[yearOld release];
		
		if( [[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOld"] isEqualToString: [[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOldAcquisition"]])
			yearOld = [[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOld"] retain];
		else
			yearOld = [[NSString stringWithFormat:@"%@ / %@", [[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOld"], [[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOldAcquisition"]] retain];
	}
}

- (void) setDCM:(NSMutableArray*) c :(NSArray*)d :(NSMutableArray*)e :(short) firstImage :(char) type :(BOOL) reset
{
	long i;
	
	[curDCM release];
	curDCM = 0L;
	
    [self setXFlipped: NO];
	[self setYFlipped: NO];
	
	if( dcmPixList != c)
	{
		if( dcmPixList) [dcmPixList release];
		dcmPixList = c;
		[dcmPixList retain];
		volumicSeries = YES;
		if( [stringID isEqualToString:@"previewDatabase"] == NO)
			if( [[dcmPixList objectAtIndex: 0] sliceLocation] == [[dcmPixList objectAtIndex: [dcmPixList count]-1] sliceLocation]) volumicSeries = NO;
    }
	
	if( dcmFilesList != d)
	{
		if( dcmFilesList) [dcmFilesList release];
		dcmFilesList = d;
		[dcmFilesList retain];
	}
	
	flippedData = NO;
	
	if( dcmRoiList != e)
	{
		if( dcmRoiList) [dcmRoiList release];
		dcmRoiList = e;
		[dcmRoiList retain];
    }
	
    listType = type;
    
	if( dcmPixList)
	{
		if( reset == YES) [self setIndexWithReset: firstImage :YES];
	}
	
	//get Presentation State info from series Object
	[self updatePresentationStateFromSeries];
	
    [self setNeedsDisplay:true];
}

- (void) dealloc
{	
	NSLog(@"DCMView released");
	
	[mouseModifiers release]; 
	[shortDateString release];
	[shortDateTimeString release];
	[localeDictionnary release];
	
	[dcmFilesList release];
	dcmFilesList = 0L;
	
	[curDCM release];
	curDCM = 0L;
	
	[dcmPixList release];
	dcmPixList = 0L;

	[stringID release];
	
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
	
	[[self openGLContext] makeCurrentContext];
	
    glDeleteLists (fontListGL, 150);
	glDeleteLists(labelFontListGL, 150);
	
	if( pTextureName)
	{
		glDeleteTextures (textureX * textureY, pTextureName);
		free( (Ptr) pTextureName);
		pTextureName = 0L;
	}
	if( blendingTextureName)
	{
		glDeleteTextures ( blendingTextureX * blendingTextureY, blendingTextureName);
		free( (Ptr) blendingTextureName);
		blendingTextureName = 0L;
	}
	if( colorBuf) free( colorBuf);
	if( blendingColorBuf) free( blendingColorBuf);
	
	[curRoiList release];
	curRoiList = 0L;
	
	[dcmRoiList release];
	dcmRoiList = 0L;
	
	[fontColor release];
	[fontGL release];
	[labelFont release];
	[yearOld release];
	
	[cursor release];
	[stringTextureCache release];
	
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];
	
	[destinationImage release];
	
	[_alternateContext release];
	
	[_hotKeyDictionary release];
	
	if(repulsorColorTimer)
	{
		[repulsorColorTimer invalidate];
		[repulsorColorTimer release];
		repulsorColorTimer = nil;
	}
	
	//[self clearGLContext];	// <- This is the bug, Joris.... Have a nice week in Cupertino !
	
    [super dealloc];
}

- (void) switchCopySettingsInSeries:(id) sender
{
	int i;
	
	for( i = 0; i < [dcmPixList count] ; i++)
	{
		[[dcmPixList objectAtIndex: i] setIndependentRotation: rotation];
		[[dcmPixList objectAtIndex: i] setIndependentZoom: scaleValue];
		[[dcmPixList objectAtIndex: i] setIndependentOffset: origin];
		[[dcmPixList objectAtIndex: i] changeWLWW :curWL :curWW];
	}
}

- (void) setIndex:(short) index
{
	long	i;
	BOOL	keepIt;
	
    if( dcmPixList && index > -1)
    {
		[self stopROIEditing];
		
		if( [[[[dcmFilesList objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"]) noScale = YES;
		else noScale = NO;

		if( [self is2DViewer] == YES)
		{
			[[self windowController] setLoadingPause: YES];
		}
		
		[[self window] setAcceptsMouseMovedEvents: YES];
		
		if( curDCM)
		{
			[curDCM setIndependentRotation: rotation];
			[curDCM setIndependentZoom:scaleValue];
			[curDCM setIndependentOffset:origin];
		}
		
        curImage = index;
        if( curImage >= [dcmPixList count]) curImage = [dcmPixList count] -1;
		
		[curDCM release];
        curDCM = [[dcmPixList objectAtIndex:curImage] retain];
		
		[curRoiList release];
		
		if( dcmRoiList) curRoiList = [[dcmRoiList objectAtIndex: curImage] retain];
		else
		{
			curRoiList = [[NSMutableArray alloc] initWithCapacity:0];
		}

		keepIt = NO;
		for( i = 0; i < [curRoiList count]; i++)
		{
			[[curRoiList objectAtIndex:i ] setRoiFont: labelFontListGL :labelFontListGLSize :self];
			
			[[curRoiList objectAtIndex:i ] recompute];
			
			if( curROI == [curRoiList objectAtIndex:i ]) keepIt = YES;
			// Unselect previous ROIs
			//	[[curRoiList objectAtIndex: i] setROIMode : ROI_sleep];
		}
		if( keepIt == NO) curROI = 0L;
		
		BOOL done = NO;
		
		if( [self is2DViewer] == YES)
		{
			if( ([[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"CR"]  && IndependentCRWLWW) || COPYSETTINGSINSERIES == NO)
			{
				[curDCM checkImageAvailble :[curDCM ww] :[curDCM wl]];
				
				rotation = [curDCM independentRotation];
				scaleValue = [curDCM independentZoom];
				origin = [curDCM independentOffset];
				
				done = YES;
			}
		}
		
		if( done == NO)
		{
			if( curWW != [curDCM ww] || curWL != [curDCM wl] || [curDCM updateToApply] == YES)
			{
				[curDCM changeWLWW :curWL :curWW];
			}
			else [curDCM checkImageAvailble :curWW :curWL];
		}
		
        [self loadTextures];
		
		if( [self is2DViewer] == YES)
		{
			[[self windowController] setLoadingPause: NO];
		}
    }
    
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	
	[self mouseMoved: event];
	[self setNeedsDisplay:YES];
	
	if (isKeyView) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"];
		[[NSNotificationCenter defaultCenter]  postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: userInfo];
	}

	[yearOld release];
	
	if( [[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOld"] isEqualToString: [[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOldAcquisition"]])
		yearOld = [[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOld"] retain];
	else
		yearOld = [[NSString stringWithFormat:@"%@ / %@", [[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOld"], [[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.yearOldAcquisition"]] retain];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
	if( currentTool >= 5)   // A ROI TOOL !
	{	 
		return NO;	 
	}	 
	else return YES;
}

- (BOOL)acceptsFirstResponder {
     return YES;
}

- (void) keyDown:(NSEvent *)event
{
	unichar		c = [[event characters] characterAtIndex:0];
	long		xMove = 0, yMove = 0, val;
	BOOL		Jog = NO;


	if( [self windowController]  == browserWindow) { [super keyDown:event]; return;}
	
//	if([stringID isEqualToString:@"Perpendicular"] == YES || [stringID isEqualToString:@"Original"] == YES )
//	{
//		display2DMPRLines =!display2DMPRLines;
//	}
		
    if( dcmPixList)
    {
        short   inc, previmage = curImage;
		
		if( flippedData)
		{
			if (c == NSLeftArrowFunctionKey) c = NSRightArrowFunctionKey;
			else if (c == NSRightArrowFunctionKey) c = NSLeftArrowFunctionKey;
			else if( c == NSPageUpFunctionKey) c = NSPageDownFunctionKey;
			else if( c == NSPageDownFunctionKey) c = NSPageUpFunctionKey;
		}
		
		if( c == 127) // Delete
		{
			[[self windowController] addToUndoQueue:@"roi"];
			
			// NE PAS OUBLIER DE CHANGER EGALEMENT LE CUT !
			long	i;
			BOOL	done = NO;
			NSTimeInterval groupID;
			
			for( i = 0; i < [curRoiList count]; i++)
			{
				if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selectedModify || [[curRoiList objectAtIndex:i] ROImode] == ROI_drawing)
				{
					if( [[curRoiList objectAtIndex:i] deleteSelectedPoint] == NO)
					{
						groupID = [[curRoiList objectAtIndex:i] groupID];
						[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:[curRoiList objectAtIndex:i] userInfo: 0L];
						[curRoiList removeObjectAtIndex:i];
						i--;
						if(groupID!=0.0)[self deleteROIGroupID:groupID];
					}
				}
			}
			
			for( i = 0; i < [curRoiList count]; i++)
			{
				if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
				{
					groupID = [[curRoiList objectAtIndex:i] groupID];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:[curRoiList objectAtIndex:i] userInfo: 0L];
					[curRoiList removeObjectAtIndex:i];
					i--;
					if(groupID!=0.0)[self deleteROIGroupID:groupID];
				}
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiRemovedFromArray" object: 0L userInfo: 0L];
			
			[self setNeedsDisplay: YES];
		}
        else if( c == 13 || c == 3 || c == ' ')	// Return - Enter - Space
		{
			if( [self is2DViewer] == YES) [[self windowController] PlayStop:[[self windowController] findPlayStopButton]];
		}
		else if( c == 27)			// Escape
		{
			if( [self is2DViewer] == YES)
				[[self windowController] offFullScreen];
		}
        else if (c == NSLeftArrowFunctionKey)
        {
			if (([event modifierFlags] & NSCommandKeyMask))
			{
				[super keyDown:event];
			}
			else
			{
				if( [event modifierFlags]  & NSControlKeyMask)
				{
					inc = -[curDCM stack];
					curImage += inc;
					if( curImage < 0) curImage = 0;
				}
				else
				{
				
					inc = -_imageRows * _imageColumns;
					curImage -= _imageRows * _imageColumns;
					if( curImage < 0) curImage = 0;
				}
			}
        }
        else if(c ==  NSRightArrowFunctionKey)
        {
			if (([event modifierFlags] & NSCommandKeyMask))
			{
				[super keyDown:event];
			}
			else
			{
				if( [event modifierFlags]  & NSControlKeyMask)
				{
					inc = [curDCM stack];
					curImage += inc;
					if( curImage >= [dcmPixList count]) curImage = [dcmPixList count]-1;
				}
				else
				{
					inc = _imageRows * _imageColumns;
					curImage += _imageRows * _imageColumns;
					if( curImage >= [dcmPixList count]) curImage = [dcmPixList count]-1;
				}
			}
        }
        else if (c == NSUpArrowFunctionKey)
        {
			if( [self is2DViewer] == YES && [[self windowController] maxMovieIndex] > 1) [super keyDown:event];
			else
			{
				[self setScaleValue:(scaleValue+1./50.)];
//				scaleValue += 1./50.;
//        
//				if( scaleValue > 100) scaleValue = 100;
            
				[self setNeedsDisplay:YES];
			}
        }
        else if(c ==  NSDownArrowFunctionKey)
        {
            if( [[self windowController] maxMovieIndex] > 1 && [[self windowController] maxMovieIndex] > 1) [super keyDown:event];
			else
			{
				[self setScaleValue:(scaleValue-1./50.)];
//				scaleValue -= 1./50.;
//                    
//				if( scaleValue < 0.01) scaleValue = 0.01;
            
				[self setNeedsDisplay:YES];
			}
        }
		else if (c == NSPageUpFunctionKey)
		{
			inc = -_imageRows * _imageColumns;
			curImage -= _imageRows * _imageColumns;
			if (curImage < 0) curImage = 0;
		}
		else if (c == NSPageDownFunctionKey)
		{
			inc = _imageRows * _imageColumns;
			curImage += _imageRows * _imageColumns;
			if( curImage >= [dcmPixList count]) curImage = [dcmPixList count]-1;
		}
		else if (c == NSHomeFunctionKey)
			curImage = 0;
		else if (c == NSEndFunctionKey)
			curImage = [dcmPixList count]-1; 
		
		
		// SHUTTLE PRO
		else if(c =='z')		// X MOVE LEFT
		{
			Jog = YES;
			xMove = -2;
		}
		else if(c == 'x')		// X MOVE RIGHT
		{
			Jog = YES;
			xMove = 2;
		}
		else if(c =='Z')		// Y MOVE LEFT
		{
			Jog = YES;
			yMove = -2;
		}
		else if(c == 'X')		// Y MOVE RIGHT
		{
			Jog = YES;
			yMove = 2;
		}
        else
        {
			if( [self actionForHotKey:[event characters]] == NO) [super keyDown:event];
        }
        
		
		if( Jog == YES)
		{
			if (currentTool == tZoom)
			{
				if( yMove) val = yMove;
				else val = xMove;
				
				[self setScaleValue:(scaleValue+val/10.0)];
//				scaleValue += val/10.0;
//				
//				if( scaleValue < 0.01) scaleValue = 0.01;
//				if( scaleValue > 100) scaleValue = 100;
			}
			
			if (currentTool == tTranslate)
			{
				float xmove, ymove, xx, yy;
			//	GLfloat deg2rad = 3.14159265358979/180.0; 
				
				xmove = xMove*10;
				ymove = yMove*10;
				
				if( xFlipped) xmove = -xmove;
				if( yFlipped) ymove = -ymove;
				
				xx = xmove*cos(rotation*deg2rad) + ymove*sin(rotation*deg2rad);
				yy = xmove*sin(rotation*deg2rad) - ymove*cos(rotation*deg2rad);
				
				origin.x = origin.x + xx;
				origin.y = origin.y + yy;
			}
			
			if (currentTool == tRotate)
			{
				if( yMove) val = yMove * 3;
				else val = xMove * 3;
				
				rotation += val;
				
				
				if( rotation < 0) rotation += 360;
				if( rotation > 360) rotation -= 360;
				

			}
			
			if (currentTool == tNext)
			{
				short   inc, now, prev, previmage;
				
				if( yMove) val = yMove/abs(yMove);
				else val = xMove/abs(xMove);
				
				previmage = curImage;
				
				if( val < 0)
				{
					inc = -1;
					curImage--;
					if( curImage < 0) curImage = [dcmPixList count]-1;
				}
				else if(val> 0)
				{
					inc = 1;
					curImage++;
					if( curImage >= [dcmPixList count]) curImage = 0;
				}
			}
			
			if( currentTool == tWL)
			{
				[curDCM changeWLWW : [curDCM wl] +yMove*10 :[curDCM ww] +xMove*10];
				
				curWW = [curDCM ww];
				curWL = [curDCM wl];
				
				[self loadTextures];
			}
			
			[self setNeedsDisplay:YES];
		}
		
        if( previmage != curImage)
        {
			if( listType == 'i') [self setIndex:curImage];
            else [self setIndexWithReset:curImage :YES];
            
            if( matrix)
            {
                [matrix selectCellAtRow :curImage/[browserWindow COLUMN] column:curImage%[browserWindow COLUMN]];
            }
            
			if( [self is2DViewer] == YES)
				[[self windowController] adjustSlider];
			
			if( stringID)
			{
				if( [stringID isEqualToString:@"Perpendicular"]  || [stringID isEqualToString:@"Original"]  || [stringID isEqualToString:@"FinalView"] || [stringID isEqualToString:@"FinalViewBlending"])
					[[self windowController] adjustSlider];
			}
            // SYNCRO
			[self sendSyncMessage:inc];
			
			[self setNeedsDisplay:YES];
        }
		
		if( [self is2DViewer] == YES)
			[[self windowController] propagateSettings];
		
		if( [stringID isEqualToString:@"FinalView"] == YES || [stringID isEqualToString:@"OrthogonalMPRVIEW"]) [self blendingPropagate];
//		if( [stringID isEqualToString:@"Original"] == YES) [self blendingPropagate];
    }
}

- (void)deleteROIGroupID:(NSTimeInterval)groupID;
{
	int i;
	for(i=0; i<[curRoiList count]; i++)
	{
		if([[curRoiList objectAtIndex:i] groupID] == groupID)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"removeROI" object:[curRoiList objectAtIndex:i] userInfo:nil];
			[curRoiList removeObjectAtIndex:i];
			i--;
		}
	}
}

- (void)flagsChanged:(NSEvent *)event
{
	if( [self is2DViewer] == YES)
	{
		BOOL update = NO;
		if (([event modifierFlags] & (NSCommandKeyMask | NSShiftKeyMask)) == (NSCommandKeyMask | NSShiftKeyMask))
		{
			if (suppress_labels == NO) update = YES;
			suppress_labels = YES;
		}
		else
		{
			if (suppress_labels == YES) update = YES;
			suppress_labels = NO;
		}		
			
		if (update == YES) [self setNeedsDisplay:YES];
	}
	[super flagsChanged:event];
}

- (void)mouseUp:(NSEvent *)event {
	// get rid of timer
	[self deleteMouseDownTimer];

	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:curImage], @"curImage", event, @"event", nil];
	
	if( [[self window] isVisible] == NO) return;
	if( [self is2DViewer] == YES)
	{
		if( [[self windowController] windowWillClose]) return;
	}
	
	// If caplock is on changes to scale, rotation, zoom, ww/wl will apply only to the current image
	BOOL modifyImageOnly = NO;
	if ([event modifierFlags] & NSAlphaShiftKeyMask) modifyImageOnly = YES;
	
    if( dcmPixList)
    {
		[self mouseMoved: event];	// Update some variables...
		
        if( curImage != startImage && (matrix && browserWindow))
        {
            NSButtonCell *cell = [matrix cellAtRow:curImage/[browserWindow COLUMN] column:curImage%[browserWindow COLUMN]];
            [cell performClick:0L];
            [matrix selectCellAtRow :curImage/[browserWindow COLUMN] column:curImage%[browserWindow COLUMN]];
        }
		
		if ( pluginOverridesMouse && ( [event modifierFlags] & NSControlKeyMask ) ) {  // Simulate Right Mouse Button action
			[nc postNotificationName: @"PLUGINrightMouseUp" object: self userInfo: userInfo];
			[nc postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: userInfo];
			return;
		}
		
		long tool = [self getTool:event];
		
		if( crossMove >= 0) tool = tCross;
		
		if( tool == tCross && ![[self stringID] isEqualToString:@"OrthogonalMPRVIEW"]) {
			[nc postNotificationName: @"crossMove" object: stringID userInfo: [NSDictionary dictionaryWithObject:@"mouseUp" forKey:@"action"]];
		}
		
//		if ([[self stringID] isEqualToString:@"OrthogonalMPRVIEW"])
//		{
//			[[self controller] propa];
//			NSPoint     eventLocation = [event locationInWindow];
//			NSRect size = [self frame];
//			eventLocation = [self convertPoint:eventLocation fromView: self];
//			eventLocation = [[[event window] contentView] convertPoint:eventLocation toView:self];
//			eventLocation.y = size.size.height - eventLocation.y;
//			eventLocation = [self ConvertFromView2GL:eventLocation];
//
//			[self setCrossPosition:(float)eventLocation.x : (float)eventLocation.y];
//			[self setNeedsDisplay:YES];
//		}
		
		if( tool == tWL || tool == tWLBlended)
		{
			if( [self is2DViewer] == YES)
			{
				[[[self windowController] thickSlabController] setLowQuality: NO];
				[curDCM changeWLWW :curWL : curWW];
				[self loadTextures];
				[self setNeedsDisplay:YES];
			}
			
			if( stringID)
			{
				if( [stringID isEqualToString:@"Perpendicular"]  || [stringID isEqualToString:@"Original"] || [stringID isEqualToString:@"FinalView"] || [stringID isEqualToString:@"FinalViewBlending"])
				{
					[[[self windowController] MPR2Dview] adjustWLWW: curWL :curWW :@"set"];
				}
			}
		}
		
		if( [self roiTool: tool])
		{
			long		i;
			NSRect      size = [self frame];
			NSPoint     eventLocation = [event locationInWindow];
			NSPoint		tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			
			tempPt.y = size.size.height - tempPt.y ;
			
			tempPt = [self ConvertFromView2GL:tempPt];
			
			for( i = 0; i < [curRoiList count]; i++)
			{
				[[curRoiList objectAtIndex:i] mouseRoiUp: tempPt];
				
				if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)	{
					[nc postNotificationName: @"roiSelected" object: [curRoiList objectAtIndex:i] userInfo: nil];
					break;
				}
			}
			
			for( i = 0; i < [curRoiList count]; i++)
			{
				if( [[curRoiList objectAtIndex: i] valid] == NO)
				{
					[curRoiList removeObjectAtIndex: i];
					i--;
				}
			}
			
			[self setNeedsDisplay:YES];
		}
		
		if(repulsorROIEdition)
		{
			currentTool = tRepulsor;
			tool = tRepulsor;
			repulsorROIEdition = NO;
		}
		
		if(tool == tRepulsor)
		{
			repulsorRadius = 0;
			if(repulsorColorTimer)
			{
				[repulsorColorTimer invalidate];
				[repulsorColorTimer release];
				repulsorColorTimer = nil;
			}
			[self setNeedsDisplay:YES];
		}

		if(selectorROIEdition)
		{
			currentTool = tROISelector;
			tool = tROISelector;
			selectorROIEdition = NO;
		}
		
		if(tool == tROISelector)
		{
			[ROISelectorSelectedROIList release];
			
			NSRect rect = NSMakeRect(ROISelectorStartPoint.x-1, ROISelectorStartPoint.y-1, fabsf(ROISelectorEndPoint.x-ROISelectorStartPoint.x)+2, fabsf(ROISelectorEndPoint.y-ROISelectorStartPoint.y)+2);
			ROISelectorStartPoint = NSMakePoint(0.0, 0.0);
			ROISelectorEndPoint = NSMakePoint(0.0, 0.0);
			[self drawRect:rect];
		}	
    }

	[nc postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: userInfo];
}

-(void) roiSet:(ROI*) aRoi
{
	[aRoi setRoiFont: labelFontListGL :labelFontListGLSize :self];
}

-(void) roiSet
{
	long i;
	for( i = 0; i < [curRoiList count]; i++)
	{
		[[curRoiList objectAtIndex:i ] setRoiFont: labelFontListGL :labelFontListGLSize :self];
	}
}

// checks to see if tool is a valid ID for ROIs
// A better name might be  - (BOOL)isToolforROIs:(long)tool;
-(BOOL) roiTool:(long) tool
{
	switch( tool)
	{
		case tMesure:
		case tROI:
		case tOval:
		case tOPolygon:
		case tCPolygon:
		//JJCP
		case tDynAngle:
		//JJCP
		case tAxis:
		case tAngle:
		case tArrow:
		case tText:
		case tPencil:
		case tPlain:
		case t2DPoint:
			return YES;
		break;
	}
	
	return NO;
}

- (IBAction) selectAll: (id) sender
{
	long i;
	
	for( i = 0; i < [curRoiList count]; i++)
	{
		[[curRoiList objectAtIndex: i] setROIMode: ROI_selected];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: [curRoiList objectAtIndex: i] userInfo: nil];
	}
	
	[self setNeedsDisplay:YES];
}

- (void) checkMouseModifiers:(id) sender
{
	if( [[[NSApplication sharedApplication] currentEvent] modifierFlags])
	{
		long tool = [self getTool: [[NSApplication sharedApplication] currentEvent]];
		[self setCursorForView: tool];
	}
}

-(void) mouseMoved: (NSEvent*) theEvent
{
	if( !drawing) return;
	if( [[self window] isVisible] == NO) return;
	if( [self is2DViewer] == YES)
	{
		if( [[self windowController] windowWillClose]) return;
	}
	
	if( curDCM == 0L) return;
	
	[BrowserController updateActivity];
	
	NSPoint     eventLocation = [theEvent locationInWindow];
	NSRect      size = [self frame];
	
	if( dcmPixList == 0L) return;
	
	if( [[self window] isVisible] && [[self window] isKeyWindow])
	{
		BOOL	needUpdate = NO;
		
		float	cpixelMouseValueR = pixelMouseValueR;
		float	cpixelMouseValueG = pixelMouseValueG;
		float	cpixelMouseValueB = pixelMouseValueB;
		float	cmouseXPos = mouseXPos;
		float	cmouseYPos = mouseYPos;
		float	cpixelMouseValue = pixelMouseValue;
		
		eventLocation = [self convertPoint:eventLocation fromView:nil];
		eventLocation.y = size.size.height - eventLocation.y;
		
		NSPoint imageLocation = [self ConvertFromView2GL:eventLocation];
		
		pixelMouseValueR = 0;
		pixelMouseValueG = 0;
		pixelMouseValueB = 0;
		mouseXPos = 0;							// DDP (041214): if outside view bounds show zeros
		mouseYPos = 0;							// otherwise update mouseXPos, mouseYPos, pixelMouseValue
		pixelMouseValue = 0;
		
		if( imageLocation.x >= 0 && imageLocation.x < [curDCM pwidth])	//&& NSPointInRect( eventLocation, size)) <- this doesn't work in MPR Ortho
		{
			if( imageLocation.y >= 0 && imageLocation.y < [curDCM pheight])
			{
				mouseXPos = imageLocation.x;
				mouseYPos = imageLocation.y;
				
				int
					xPos = (int)mouseXPos,
					yPos = (int)mouseYPos;
				
				if( [curDCM isRGB])
				{
					pixelMouseValueR = ((unsigned char*) [curDCM fImage])[ 4 * (xPos + yPos * [curDCM pwidth]) +1];
					pixelMouseValueG = ((unsigned char*) [curDCM fImage])[ 4 * (xPos + yPos * [curDCM pwidth]) +2];
					pixelMouseValueB = ((unsigned char*) [curDCM fImage])[ 4 * (xPos + yPos * [curDCM pwidth]) +3];
				}
				else pixelMouseValue = [curDCM getPixelValueX: xPos Y:yPos];
			}
		}

		if(	cpixelMouseValueR != pixelMouseValueR)	needUpdate = YES;
		if(	cpixelMouseValueG != pixelMouseValueG)	needUpdate = YES;
		if(	cpixelMouseValueB != pixelMouseValueB)	needUpdate = YES;
		if(	cmouseXPos != mouseXPos)	needUpdate = YES;
		if(	cmouseYPos != mouseYPos)	needUpdate = YES;
		if(	cpixelMouseValue != pixelMouseValue)	needUpdate = YES;
		
		float	cblendingMouseXPos = blendingMouseXPos;
		float	cblendingMouseYPos = blendingMouseYPos;
		float	cblendingPixelMouseValue = blendingPixelMouseValue;
		float	cblendingPixelMouseValueR = blendingPixelMouseValueR;
		float	cblendingPixelMouseValueG = blendingPixelMouseValueG;
		float	cblendingPixelMouseValueB = blendingPixelMouseValueB;

		blendingMouseXPos = 0;
		blendingMouseYPos = 0;
		blendingPixelMouseValue = 0;
		blendingPixelMouseValueR = 0;
		blendingPixelMouseValueG = 0;
		blendingPixelMouseValueB = 0;
		
		// Blended view
		if( blendingView)
		{
			NSPoint	offset;
			
			if( [curDCM pixelSpacingX] != 0 && [curDCM pixelSpacingY] != 0 &&  [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"] == YES)
			{
				float	vectorP[ 9], tempOrigin[ 3], tempOriginBlending[ 3];
				
				// Compute blended view offset
				[curDCM orientation: vectorP];
				
				tempOrigin[ 0] = [curDCM originX] * vectorP[ 0] + [curDCM originY] * vectorP[ 1] + [curDCM originZ] * vectorP[ 2];
				tempOrigin[ 1] = [curDCM originX] * vectorP[ 3] + [curDCM originY] * vectorP[ 4] + [curDCM originZ] * vectorP[ 5];
				tempOrigin[ 2] = [curDCM originX] * vectorP[ 6] + [curDCM originY] * vectorP[ 7] + [curDCM originZ] * vectorP[ 8];
				
				tempOriginBlending[ 0] = [[blendingView curDCM] originX] * vectorP[ 0] + [[blendingView curDCM] originY] * vectorP[ 1] + [[blendingView curDCM] originZ] * vectorP[ 2];
				tempOriginBlending[ 1] = [[blendingView curDCM] originX] * vectorP[ 3] + [[blendingView curDCM] originY] * vectorP[ 4] + [[blendingView curDCM] originZ] * vectorP[ 5];
				tempOriginBlending[ 2] = [[blendingView curDCM] originX] * vectorP[ 6] + [[blendingView curDCM] originY] * vectorP[ 7] + [[blendingView curDCM] originZ] * vectorP[ 8];
				
				offset.x = (tempOrigin[0] + [curDCM pwidth]*[curDCM pixelSpacingX]/2. - (tempOriginBlending[ 0] + [[blendingView curDCM] pwidth]*[[blendingView curDCM] pixelSpacingX]/2.));
				offset.y = (tempOrigin[1] + [curDCM pheight]*[curDCM pixelSpacingY]/2. - (tempOriginBlending[ 1] + [[blendingView curDCM] pheight]*[[blendingView curDCM] pixelSpacingY]/2.));
				
				offset.x /= [[blendingView curDCM] pixelSpacingX];
				offset.y /= [[blendingView curDCM] pixelSpacingY];
			}
			else
			{
				offset.x = 0;
				offset.y = 0;
			}
			
//			NSLog( @"%f %f", offset.x, offset.y);
			
			// Convert screen position to pixel position in blended image
			float xx, yy;
			NSRect size = [self frame];
			NSPoint a = eventLocation;
						
			if( xFlipped) a.x = size.size.width - a.x;
			if( yFlipped) a.y = size.size.height - a.y;
			
			a.x -= size.size.width/2;
			a.x /= [blendingView scaleValue];
			
			a.y -= size.size.height/2;
			a.y /= [blendingView scaleValue];
			
			xx = a.x*cos([blendingView rotation]*deg2rad) + a.y*sin([blendingView rotation]*deg2rad);
			yy = -a.x*sin([blendingView rotation]*deg2rad) + a.y*cos([blendingView rotation]*deg2rad);

			a.y = yy;
			a.x = xx;
			
			a.x -= ([blendingView origin].x + [blendingView originOffset].x)/[blendingView scaleValue];
			a.y += ([blendingView origin].y + [blendingView originOffset].y)/[blendingView scaleValue];
						
			if( curDCM)
			{
				a.x += [[blendingView curDCM] pwidth]/2.;
				a.y += [[blendingView curDCM] pheight]*[[blendingView curDCM] pixelRatio]/ 2.;
				a.y /= [[blendingView curDCM] pixelRatio];
			}
			
			a.x += offset.x;
			a.y += offset.y;
			
			NSPoint blendedLocation = a;						//= [blendingView ConvertFromView2GL:eventLocation];
			
			if( blendedLocation.x >= 0 && blendedLocation.x < [[blendingView curDCM] pwidth])
			{
				if( blendedLocation.y >= 0 && blendedLocation.y < [[blendingView curDCM] pheight])
				{
					blendingMouseXPos = blendedLocation.x;
					blendingMouseYPos = blendedLocation.y;
					
					int
						xPos = (int)blendingMouseXPos,
						yPos = (int)blendingMouseYPos;
					
					if( [[blendingView curDCM] isRGB])
					{
						blendingPixelMouseValueR = ((unsigned char*) [[blendingView curDCM] fImage])[ 4 * (xPos + yPos * [[blendingView curDCM] pwidth]) +1];
						blendingPixelMouseValueG = ((unsigned char*) [[blendingView curDCM] fImage])[ 4 * (xPos + yPos * [[blendingView curDCM] pwidth]) +2];
						blendingPixelMouseValueB = ((unsigned char*) [[blendingView curDCM] fImage])[ 4 * (xPos + yPos * [[blendingView curDCM] pwidth]) +3];
					}
					else blendingPixelMouseValue = [[blendingView curDCM] getPixelValueX: xPos Y:yPos];
				}
			}
		}
		
		if( cblendingMouseXPos != blendingMouseXPos) needUpdate = YES;
		if( cblendingMouseYPos != blendingMouseYPos) needUpdate = YES;
		if( cblendingPixelMouseValue != blendingPixelMouseValue) needUpdate = YES;
		if( cblendingPixelMouseValueR != blendingPixelMouseValueR) needUpdate = YES;
		if( cblendingPixelMouseValueG != blendingPixelMouseValueG) needUpdate = YES;
		if( cblendingPixelMouseValueB != blendingPixelMouseValueB) needUpdate = YES;
		
		if( needUpdate) [self setNeedsDisplay: YES];
		
		if( stringID)
		{
			if( [stringID isEqualToString:@"Perpendicular"] || [stringID isEqualToString:@"Original"]  || [stringID isEqualToString:@"FinalView"] || [stringID isEqualToString:@"FinalViewBlending"])
			{
				NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
				
				if( view == self)
				{
					if( cross.x != -9999 && cross.y != -9999)
					{
						NSPoint tempPt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
						
						tempPt.y = size.size.height - tempPt.y ;
						
						tempPt = [self ConvertFromView2GL:tempPt];
						
						if( tempPt.x > cross.x - BS/scaleValue && tempPt.x < cross.x + BS/scaleValue && tempPt.y > cross.y - BS/scaleValue && tempPt.y < cross.y + BS/scaleValue == YES)	//&& [stringID isEqualToString:@"Original"] 
						{
							if( [theEvent type] == NSLeftMouseDragged || [theEvent type] == NSLeftMouseDown) [[NSCursor closedHandCursor] set];
							else [[NSCursor openHandCursor] set];
						}
						else
						{
							// TESTE SUR LA LIGNE !!!
							float		distance;
							NSPoint		cross1 = cross, cross2 = cross;
							
							cross1.x -=  1000*mprVector[ 0];
							cross1.y -=  1000*mprVector[ 1];

							cross2.x +=  1000*mprVector[ 0];
							cross2.y +=  1000*mprVector[ 1];
							
							[DCMView DistancePointLine:tempPt :cross1 :cross2 :&distance];
							
							if( distance * scaleValue < 10)
							{
								if( [theEvent type] == NSLeftMouseDragged || [theEvent type] == NSLeftMouseDown) [[NSCursor closedHandCursor] set];
								else [[NSCursor openHandCursor] set];
							}
							else [cursor set];
						}
					}
				}
				else [view mouseMoved:theEvent];
			}
		}
	}
	
	if ([self is2DViewer] == YES)
	{
		[super mouseMoved: theEvent];
	}
}



- (long) getTool: (NSEvent*) event
{
	long tool;
	
	if( [event type] == NSRightMouseDown || [event type] == NSRightMouseDragged || [event type] == NSRightMouseUp) tool = currentToolRight;
	else if( [event type] == NSOtherMouseDown || [event type] == NSOtherMouseDragged || [event type] == NSOtherMouseUp) tool = tTranslate;
	else tool = currentTool;
	
	if (([event modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
	if (([event modifierFlags] & NSAlternateKeyMask))  tool = tWL;
	if (([event modifierFlags] & NSControlKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))
	{
		if( blendingView) tool = tWLBlended;
		else tool = tWL;
	}
	if( [self roiTool:currentTool] != YES && currentTool!=tROISelector)   // Not a ROI TOOL !
	{
		if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))  tool = tRotate;
		if (([event modifierFlags] & NSShiftKeyMask))  tool = tZoom;
	}
	else
	{
		if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask)) tool = currentTool;
		if (([event modifierFlags] & NSCommandKeyMask)) tool = currentTool;
	}
	
	return tool;
}

- (void) setStartWLWW
{
	startWW = [curDCM ww];
	startWL = [curDCM wl];
	startMin = [curDCM wl] - [curDCM ww]/2;
	startMax = [curDCM wl] + [curDCM ww]/2;
	
	bdstartWW = [[blendingView curDCM] ww];
	bdstartWL = [[blendingView curDCM] wl];
	bdstartMin = [[blendingView curDCM] wl] - [[blendingView curDCM] ww]/2;
	bdstartMax = [[blendingView curDCM] wl] + [[blendingView curDCM] ww]/2;
}

- (void)mouseDown:(NSEvent *)event
{
	if( !drawing) return;
	if( [[self window] isVisible] == NO) return;
	if( [self is2DViewer] == YES)
	{
		if( [[self windowController] windowWillClose]) return;
	}
	
	if (_mouseDownTimer) {
		[self deleteMouseDownTimer];
	}
	if ([event type] == NSLeftMouseDown)
		_mouseDownTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self   selector:@selector(startDrag:) userInfo: event  repeats:NO] retain];
	
    if( dcmPixList)
    {
		[self erase2DPointMarker];
		if( blendingView) [blendingView erase2DPointMarker];
		
        NSPoint     eventLocation = [event locationInWindow];
        NSRect      size = [self frame];
        long		tool;
		
		[self mouseMoved: event];	// Update some variables...
		
		start = previous = [self convertPoint:eventLocation fromView:self];
        
		tool = [self getTool: event];
		
        startImage = curImage;
        [self setStartWLWW];
        startScaleValue = scaleValue;
        rotationStart = rotation;
		blendingFactorStart = blendingFactor;
		scrollMode = 0;
        		
        originStart = origin;
		originOffsetStart = originOffset;
        
        mesureB = mesureA = [[[event window] contentView] convertPoint:eventLocation toView:self];
        mesureB.y = mesureA.y = size.size.height - mesureA.y ;
        
        roiRect.origin = [[[event window] contentView] convertPoint:eventLocation toView:self];
        roiRect.origin.y = size.size.height - roiRect.origin.y;
        
		if( [self is2DViewer] == YES)
		{
			NSPoint tempPt = [self ConvertFromView2GL:mesureA];
			
			NSDictionary	*dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:tempPt.y], @"Y", [NSNumber numberWithLong:tempPt.x],@"X",0L];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"mouseDown" object: [self windowController] userInfo: dict];
		}
		
        if( [event clickCount] > 1 && [self window] == [browserWindow window])
        {
            [browserWindow matrixDoublePressed:nil];
        }
		else if( [event clickCount] > 1 && ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSCommandKeyMask))
		{
			if( [self is2DViewer] == YES)
				[[self windowController] setKeyImage: self];
		}
		else if( [event clickCount] > 1 && stringID == 0L)
		{
			if( [self is2DViewer] == YES)
				[[self windowController] showCurrentThumbnail: self];
				
			float location[ 3];
			
			[curDCM convertPixX: mouseXPos pixY: mouseYPos toDICOMCoords: location];
						
			DCMPix	*thickDCM;
		
			if( [curDCM stack] > 1)
			{
				long maxVal;
				
//				if( flippedData)
//				{
//					maxVal = [dcmPixList count] - ([curDCM ID] + ([curDCM stack]-1));
//					if( maxVal < 0) maxVal = 0;
//					if( maxVal >= [dcmPixList count]) maxVal = [dcmPixList count]-1;
//				}
//				else
				{
					maxVal = curImage+([curDCM stack]-1);
					if( maxVal < 0) maxVal = 0;
					if( maxVal >= [dcmPixList count]) maxVal = [dcmPixList count]-1;
				}
				
				thickDCM = [dcmPixList objectAtIndex: maxVal];
			}
			else thickDCM = 0L;
			
			int pos;
			if( flippedData) pos = [dcmPixList count] -1 -curImage;
			else pos = curImage;
			
			NSDictionary *instructions = [[[NSDictionary alloc] initWithObjectsAndKeys:     self, @"view",
																							[NSNumber numberWithLong: pos],@"Pos",
																							[NSNumber numberWithFloat:[[dcmPixList objectAtIndex:curImage] sliceLocation]],@"Location", 
																							[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.studyInstanceUID"], @"studyID", 
																							curDCM, @"DCMPix",
																							[NSNumber numberWithFloat: syncRelativeDiff],@"offsetsync",
																							[NSNumber numberWithFloat: location[0]],@"point3DX",
																							[NSNumber numberWithFloat: location[1]],@"point3DY",
																							[NSNumber numberWithFloat: location[2]],@"point3DZ",
																							thickDCM, @"DCMPix2",
																							nil]
																							autorelease];
			NSNotificationCenter *nc;
			nc = [NSNotificationCenter defaultCenter];
			[nc postNotificationName: @"sync" object: self userInfo: instructions];
		}
		
		if( cross.x != -9999 && cross.y != -9999)
		{
			NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			tempPt.y = size.size.height - tempPt.y ;
			
			tempPt = [self ConvertFromView2GL:tempPt];
			if( tempPt.x > cross.x - BS/scaleValue && tempPt.x < cross.x + BS/scaleValue && tempPt.y > cross.y - BS/scaleValue && tempPt.y < cross.y + BS/scaleValue == YES)	//&& [stringID isEqualToString:@"Original"] 
			{
				crossMove = 1;
			}
			else
			{
				// TESTE SUR LA LIGNE !!!
				float		distance;
				NSPoint		cross1 = cross, cross2 = cross;
				
				cross1.x -=  1000*mprVector[ 0];
				cross1.y -=  1000*mprVector[ 1];

				cross2.x +=  1000*mprVector[ 0];
				cross2.y +=  1000*mprVector[ 1];
				
				[DCMView DistancePointLine:tempPt :cross1 :cross2 :&distance];
				
			//	NSLog( @"Dist:%0.0f / %0.0f_%0.0f", distance, tempPt.x, tempPt.y);
				
				if( distance * scaleValue < 10)
				{
					crossMove = 0;
					switchAngle = -1;
				}
				else crossMove = -1;
			}
		}
		else crossMove = -1;
		
		if(tool == tRepulsor)
		{
			[self deleteMouseDownTimer];
			
			[[self windowController] addToUndoQueue:@"roi"];
			
			NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			tempPt.y = size.size.height - tempPt.y ;
			tempPt = [self ConvertFromView2GL:tempPt];
			//repulsorPosition = tempPt;
			
			int i, j;
			BOOL clickInROI = NO;
			for( i = 0; i < [curRoiList count]; i++) 
			{
				if([[curRoiList objectAtIndex: i] clickInROI:tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :YES])
				{
					clickInROI = YES;
				}
			}

			if(!clickInROI)
			{
				for( i = 0; i < [curRoiList count]; i++)
				{
					if([[curRoiList objectAtIndex: i] clickInROI:tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :NO])
					{
						clickInROI = YES;
					}
				}
			}
			
			if(clickInROI)
			{
				currentTool = tPencil;
				tool = tPencil;
				repulsorROIEdition = YES;
			}
			else
			{
				[self deleteMouseDownTimer];
				repulsorColorTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(setAlphaRepulsor:) userInfo:event repeats:YES] retain];
				repulsorAlpha = 0.1;
				repulsorAlphaSign = 1.0;
				repulsorRadius = 0;
								
				float dx, dx2, dy, dy2, d;
				NSPoint pt;
				float distance;
				
				float pixSpacingRatio = 1.0;
				if([self pixelSpacingY]!=0 && [self pixelSpacingX]!=0)
					pixSpacingRatio = [self pixelSpacingY]/[self pixelSpacingX];
					
				if([curRoiList count]>0)
				{
					pt = [[[[curRoiList objectAtIndex:0] points] objectAtIndex:0] point];
					dx = (pt.x-tempPt.x);
					dx2 = dx * dx;
					dy = (pt.y-tempPt.y)*pixSpacingRatio;
					dy2 = dy * dy;
					distance = sqrt(dx2 + dy2);
				}
				else distance = 0.0;
				
				NSMutableArray *points;
				for(i=0; i<[curRoiList count]; i++)
				{
					points = [[curRoiList objectAtIndex:i] points];
					for(j=0; j<[points count]; j++)
					{
						pt = [[points objectAtIndex:j] point];
						dx = (pt.x-tempPt.x);
						dx2 = dx * dx;
						dy = (pt.y-tempPt.y) *pixSpacingRatio;
						dy2 = dy * dy;
						d = sqrt(dx2 + dy2);
						distance = (d < distance) ? d : distance ;
					}
				}
				repulsorRadius = (int) ((distance + 0.5) * 0.8);
				if(repulsorRadius<2) repulsorRadius = 2;
				if(repulsorRadius>[curDCM pwidth]/2) repulsorRadius = [curDCM pwidth]/2;
				
				if( [curRoiList count] == 0)
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"Repulsor",nil),NSLocalizedString(@"The Repulsor tool works only if there are ROIs on the image.",nil), NSLocalizedString(@"OK",nil), nil,nil);
				}
			}
		}
		
		if(tool == tROISelector)
		{
			int i, j;
			ROISelectorSelectedROIList = [[NSMutableArray arrayWithCapacity:0] retain];
			
			// if shift key is pressed, we need to keep track of the ROIs that were selected before the click 
			if([event modifierFlags] & NSShiftKeyMask)
			{
				for(i=0; i<[curRoiList count]; i++)
				{
					if([[curRoiList objectAtIndex:i] ROImode]==ROI_selected)
						[ROISelectorSelectedROIList addObject:[curRoiList objectAtIndex:i]];
				}
			}
			
			NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			tempPt.y = size.size.height - tempPt.y ;

			ROISelectorStartPoint = tempPt;
			ROISelectorEndPoint = tempPt;

			[self deleteMouseDownTimer];
			
			//if( [self is2DViewer]) [[self windowController] addToUndoQueue:@"roi"];
			
			tempPt = [self ConvertFromView2GL:tempPt];

			BOOL clickInROI = NO;
			for( i = 0; i < [curRoiList count]; i++) 
			{
				if([[curRoiList objectAtIndex: i] clickInROI:tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :YES])
				{
					clickInROI = YES;
				}
			}

			if(!clickInROI)
			{
				for( i = 0; i < [curRoiList count]; i++)
				{
					if([[curRoiList objectAtIndex: i] clickInROI:tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :NO])
					{
						clickInROI = YES;
					}
				}
			}
			
			if(clickInROI)
			{
				currentTool = tPencil;
				tool = tPencil;
				selectorROIEdition = YES;
			}
		}
		
		// ROI TOOLS
		if( [self roiTool:tool] == YES && crossMove == -1)
		{
			[self deleteMouseDownTimer];
			
			[[self windowController] addToUndoQueue:@"roi"];
			
			BOOL	DoNothing = NO;
			long	selected = -1, i, x;
			NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			tempPt.y = size.size.height - tempPt.y ;
			tempPt = [self ConvertFromView2GL:tempPt];
			
			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotNone)
				[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
			
			BOOL roiFound = NO;
			
			if (!(([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSShiftKeyMask)))
				for( i = 0; i < [curRoiList count] && !roiFound; i++)
				{
					if( [[curRoiList objectAtIndex: i] clickInROI: tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :YES])
					{
						selected = i;
						roiFound = YES;
					}
				}
			
			if( roiFound == NO)
			{
				for( i = 0; i < [curRoiList count]; i++)
				{
					if( [[curRoiList objectAtIndex: i] clickInROI: tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :NO])
					{
						selected = i;
						break;
					}
				}
			}
					
			if (([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSCommandKeyMask))
			{
				if( selected != -1)
				{
					if( [[curRoiList objectAtIndex: selected] ROImode] == ROI_selected) 
					{
						[[curRoiList objectAtIndex: selected] setROIMode: ROI_sleep];
						// unselect all ROIs in the same group
						[[self windowController] setMode:ROI_sleep toROIGroupWithID:[[curRoiList objectAtIndex:selected] groupID]];
						DoNothing = YES;
					}
				}
			}
			else
			{
				if( selected == -1 || ( [[curRoiList objectAtIndex: selected] ROImode] != ROI_selected &&  [[curRoiList objectAtIndex: selected] ROImode] != ROI_selectedModify))
				{
					// Unselect previous ROIs
					for( i = 0; i < [curRoiList count]; i++) [[curRoiList objectAtIndex: i] setROIMode : ROI_sleep];
				}
			}
					
			if( DoNothing == NO)
			{
				if( selected >= 0 && drawingROI == NO)
				{
					curROI = 0L;
					
					// Bring the selected ROI to the first position in array
					ROI	*roi = [[curRoiList objectAtIndex: selected] retain];
					[[self windowController] bringToFrontROI:roi];
//					[curRoiList removeObject: roi];
//					[curRoiList insertObject: roi atIndex: 0];
//					[roi release];
					
					selected = [curRoiList indexOfObject:roi];//0;
					
					long roiVal = [[curRoiList objectAtIndex: selected] clickInROI: tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :YES];
					if( roiVal == ROI_sleep) roiVal = [[curRoiList objectAtIndex: selected] clickInROI: tempPt :[curDCM pwidth]/2. :[curDCM pheight]/2. :scaleValue :NO];
					
					[[self windowController] setMode:roiVal toROIGroupWithID:[[curRoiList objectAtIndex:selected] groupID]]; // change the mode to the whole group before the selected ROI!
					[[curRoiList objectAtIndex: selected] setROIMode: roiVal];
										
					NSArray *winList = [[NSApplication sharedApplication] windows];
					BOOL	found = NO;
					
					for( i = 0; i < [winList count]; i++)
					{
						if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROI"])
						{
							found = YES;
							[[[winList objectAtIndex:i] windowController] setROI: [curRoiList objectAtIndex: selected] :[self windowController]];
						}
					}
					
					if( [event clickCount] > 1 && [self is2DViewer] == YES)
					{
						if( found == NO)
						{
							ROIWindow* roiWin = [[ROIWindow alloc] initWithROI: [curRoiList objectAtIndex: selected] :[self windowController]];
							[roiWin showWindow:self];
						}
					}
				}
				else // Start drawing a new ROI !
				{
					if( curROI)
					{
						drawingROI = [curROI mouseRoiDown:tempPt :scaleValue];
						
						if( drawingROI == NO)
						{
							curROI = 0L;
						}
						
						if( [curROI ROImode] == ROI_selected)
							[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: curROI userInfo: nil];
					}
					else
					{
						// Unselect previous ROIs
						for( i = 0; i < [curRoiList count]; i++) [[curRoiList objectAtIndex: i] setROIMode : ROI_sleep];
						
						ROI*		aNewROI;
						NSString	*roiName = 0L, *finalName;
						long		counter;
						BOOL		existsAlready;
						
						drawingROI = NO;
						
						curROI = aNewROI = [[ROI alloc] initWithType: currentTool :[curDCM pixelSpacingX] :[curDCM pixelSpacingY] :NSMakePoint( [curDCM originX], [curDCM originY])];
											
						if ( [ROI defaultName] != nil ) {
							[aNewROI setName: [ROI defaultName]];
						}
						else { 
							switch( currentTool)
							{
								case  tOval:
									roiName = [NSString stringWithString:@"Oval "];
									break;
								//JJCP
								case tDynAngle:
									roiName = [NSString stringWithString:@"Dynamic Angle "];
									break;
								//JJCP
								case tAxis:
									roiName = [NSString stringWithString:@"Bone Axis "];
									break;
								case tOPolygon:
								case tCPolygon:
									roiName = [NSString stringWithString:@"Polygon "];
									break;
									
								case tAngle:
									roiName = [NSString stringWithString:@"Angle "];
									break;
									
								case tArrow:
									roiName = [NSString stringWithString:@"Arrow "];
									break;
								
								case tPlain:
								case tPencil:
									roiName = [NSString stringWithString:@"ROI "];
									break;
									
								case tMesure:
									roiName = [NSString stringWithString:@"Measurement "];
									break;
									
								case tROI:
									roiName = [NSString stringWithString:@"Rectangle "];
									break;
									
								case t2DPoint:
									roiName = [NSString stringWithString:@"Point "];
									break;
							}
							
							if( roiName)
							{
								counter = 1;
								
								do
								{
									existsAlready = NO;
									
									finalName = [roiName stringByAppendingFormat:@"%d", counter++];
									
									for( i = 0; i < [dcmRoiList count]; i++)
									{
										for( x = 0; x < [[dcmRoiList objectAtIndex: i] count]; x++)
										{
											if( [[[[dcmRoiList objectAtIndex: i] objectAtIndex: x] name] isEqualToString: finalName])
											{
												existsAlready = YES;
											}
										}
									}
									
								} while (existsAlready != NO);
								
								[aNewROI setName: finalName];
							}
						}
						
						// Create aliases of current ROI to the entire series
						if (([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSCommandKeyMask))
						{
							for( i = 0; i < [dcmRoiList count]; i++)
							{
								[[dcmRoiList objectAtIndex: i] addObject: aNewROI];
							}
						}
						else [curRoiList addObject: aNewROI];
						
						[aNewROI setRoiFont: labelFontListGL :labelFontListGLSize :self];
						drawingROI = [aNewROI mouseRoiDown: tempPt :scaleValue];
						if( drawingROI == NO)
						{
							curROI = 0L;
						}
						
						if( [aNewROI ROImode] == ROI_selected)
							[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: aNewROI userInfo: nil];
						
						NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	aNewROI,							@"ROI",
																								[NSNumber numberWithInt:curImage],	@"sliceNumber", 
																								nil];
					   
						[[NSNotificationCenter defaultCenter] postNotificationName: @"addROI" object:self userInfo:userInfo];
						
						[aNewROI release];
					}
				}
			}
			
			for( x = 0; x < [dcmRoiList count]; x++)
			{
				for( i = 0; i < [[dcmRoiList objectAtIndex: x] count]; i++)
				{
					if( [[[dcmRoiList objectAtIndex: x] objectAtIndex: i] valid] == NO)
					{
						[[dcmRoiList objectAtIndex: x] removeObjectAtIndex: i];
						i--;
					}
				}
			}
		}
		[self mouseDragged:event];
    }
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	float				reverseScrollWheel;					// DDP (050913): allow reversed scroll wheel preference.
	
	if( !drawing) return;
	if( [[self window] isVisible] == NO) return;
	if( [self is2DViewer] == YES)
	{
		if( [[self windowController] windowWillClose]) return;
	}

	float deltaX = [theEvent deltaX];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ZoomWithHorizonScroll"] == NO) deltaX = 0;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Scroll Wheel Reversed"])
		reverseScrollWheel=-1.0;
	else
		reverseScrollWheel=1.0;
	
	if( flippedData) reverseScrollWheel *= -1.0;
	
    if( dcmPixList)
    {
        short inc;
        
		if( [stringID isEqualToString:@"OrthogonalMPRVIEW"])
		{
			//[[self windowController] saveCrossPositions];
			[[self controller] saveCrossPositions];
			float change;
			if( fabs( [theEvent deltaY]) >  fabs( deltaX))
			{
				change = reverseScrollWheel * [theEvent deltaY];
				if( change > 0)
				{
					change = ceil( change);
					if( change < 1) change = 1;
				}
				else
				{
					change = floor( change);
					if( change > -1) change = -1;		
				}
				if ( [self isKindOfClass: [OrthogonalMPRView class]] ) {
					[(OrthogonalMPRView*)self scrollTool: 0 : (long)change];
				}
			}
			else
			{
				change = reverseScrollWheel * deltaX;
				if( change > 0)
				{
					change = ceil( change);
					if( change < 1) change = 1;
				}
				else
				{
					change = floor( change);
					if( change > -1) change = -1;		
				}
				if ( [self isKindOfClass: [OrthogonalMPRView class]] ) {
					[(OrthogonalMPRView*)self scrollTool: 0 : (long)change];
				}
			}
			
			[self mouseMoved: [[NSApplication sharedApplication] currentEvent]];
		}
		else if( [stringID isEqualToString:@"previewDatabase"])
		{
			[super scrollWheel: theEvent];
		}
		else if( [stringID isEqualToString:@"FinalView"] || [stringID isEqualToString:@"Perpendicular"] )
		{
			[super scrollWheel: theEvent];
		}
		else
		{
			if( fabs( [theEvent deltaY]) * 2.0f >  fabs( deltaX))
			{
				if( [theEvent modifierFlags]  & NSAlternateKeyMask)
				{
					if( [self is2DViewer])
					{
						// 4D Direction scroll - Cardiac CT eg
						
						float change = reverseScrollWheel * [theEvent deltaY] / 2.5f;
						
						if( change > 0)
						{
							change = ceil( change);
							if( change < 1) change = 1;
							
							change += [[self windowController] curMovieIndex];
							while( change >= [[self windowController] maxMovieIndex]) change -= [[self windowController] maxMovieIndex];
						}
						else
						{
							change = floor( change);
							if( change > -1) change = -1;
							
							change += [[self windowController] curMovieIndex];
							while( change < 0) change += [[self windowController] maxMovieIndex];
						}
						
						[[self windowController] setMovieIndex: change];
					}
				}
				else if( [theEvent modifierFlags]  & NSShiftKeyMask)
				{
					float change = reverseScrollWheel * [theEvent deltaY] / 2.5f;
					
					if( change > 0)
					{
						change = ceil( change);
						if( change < 1) change = 1;
						
						inc = [curDCM stack] * change;
						curImage += inc;
					}
					else
					{
						change = floor( change);
						if( change > -1) change = -1;
						
						inc = [curDCM stack] * change;
						curImage += inc;
					}
				}
				else
				{
					float change = reverseScrollWheel * [theEvent deltaY] / 2.5f;
					
					if( change > 0)
					{
						change = ceil( change);
						if( change < 1) change = 1;
						
						inc = _imageRows * _imageColumns * change;
						curImage += inc;
					}
					else
					{
						change = floor( change);
						if( change > -1) change = -1;
						
						inc = _imageRows * _imageColumns * change;
						curImage += inc;
					}
				}
			}
			else if( fabs( deltaX) > 0.7)
			{
				[self mouseMoved: theEvent];	// Update some variables...
				
//				NSLog(@"delta x: %f", deltaX);
				
				float sScaleValue = scaleValue;
				
				[self setScaleValue:sScaleValue + deltaX * scaleValue / 10];
//				scaleValue = sScaleValue + deltaX * scaleValue / 10;
//				if( scaleValue < 0.01) scaleValue = 0.01;
//				if( scaleValue > 100) scaleValue = 100;
				
				origin.x = ((origin.x * scaleValue) / sScaleValue);
				origin.y = ((origin.y * scaleValue) / sScaleValue);
				
				originOffset.x = ((originOffset.x * scaleValue) / sScaleValue);
				originOffset.y = ((originOffset.y * scaleValue) / sScaleValue);
				
				if( [self is2DViewer] == YES)
					[[self windowController] propagateSettings];
				
				if( [stringID isEqualToString:@"FinalView"] == YES || [stringID isEqualToString:@"OrthogonalMPRVIEW"]) [self blendingPropagate];
		//		if( [stringID isEqualToString:@"Original"] == YES) [self blendingPropagate];
				
				[self setNeedsDisplay:YES];
			}
			
			if( [dcmPixList count] > 3)
			{
				if( curImage < 0) curImage = [dcmPixList count]-1;
				if( curImage >= [dcmPixList count]) curImage = 0;
			}
			else
			{
				if( curImage < 0) curImage = 0;
				if( curImage >= [dcmPixList count]) curImage = [dcmPixList count]-1;
			}
			
			if( listType == 'i') [self setIndex:curImage];
			else [self setIndexWithReset:curImage :YES];
			
			if( matrix)
			{
				[matrix selectCellAtRow :curImage/[browserWindow COLUMN] column:curImage%[browserWindow COLUMN]];
			}
			
			if( [self is2DViewer] == YES)
				[[self windowController] adjustSlider];    //mouseDown:theEvent];
				
			if( stringID)
			{
				if( [stringID isEqualToString:@"Perpendicular"] || [stringID isEqualToString:@"Original"]  || [stringID isEqualToString:@"FinalView"] || [stringID isEqualToString:@"FinalViewBlending"])
					[[self windowController] adjustSlider];
			}
			
			// SYNCRO
			[self sendSyncMessage:inc];
			
			if( [self is2DViewer] == YES)
				[[self windowController] propagateSettings];
			
			if( [stringID isEqualToString:@"FinalView"] == YES || [stringID isEqualToString:@"OrthogonalMPRVIEW"]) [self blendingPropagate];
//			if( [stringID isEqualToString:@"Original"] == YES) [self blendingPropagate];
			
			[self setNeedsDisplay:YES];
		}
    }
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"];
	[nc postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: userInfo];
}

- (void) otherMouseDown:(NSEvent *)event
{
	[self mouseDown: event];
}

- (void) rightMouseDown:(NSEvent *)event {
	
	if ( pluginOverridesMouse ) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:curImage], @"curImage", event, @"event", nil];
		[nc postNotificationName: @"PLUGINrightMouseDown" object: self userInfo: userInfo];
		return;
	}
		
	[self mouseDown: event];
	
//    if( dcmPixList)
//    {
//        NSPoint eventLocation = [event locationInWindow];
//        start = [self convertPoint:eventLocation fromView:self];
//        
//        startScaleValue = scaleValue;
//		originStart = origin;
//		originOffsetStart = originOffset;
//		originOffsetRegistrationStart = originOffsetRegistration;
//    }
}

//added by lpysher 4/22/04. Mimics single click to open contextual menu.
- (void) rightMouseUp:(NSEvent *)event {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithInt:curImage], @"curImage", event, @"event", nil];

	if ( pluginOverridesMouse ) {
		[nc postNotificationName: @"PLUGINrightMouseUp" object: self userInfo: userInfo];
	}
	else {
		 if ([event clickCount] == 1)
				[NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
		//[super rightMouseUp:event];
	}
	
	[nc postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: userInfo];
}

- (void)otherMouseDragged:(NSEvent *)event
{
	[self mouseDragged:(NSEvent *)event];
}

- (void)rightMouseDragged:(NSEvent *)event {
	
	if ( pluginOverridesMouse ) {
		[self mouseMoved: event];	// Update some variables...
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:curImage], @"curImage", event, @"event", nil];
		[nc postNotificationName: @"PLUGINrightMouseDragged" object: self userInfo: userInfo];
		return;
	}
	
	[self mouseDragged:(NSEvent *)event];
}

-(NSMenu*) menuForEvent:(NSEvent *)theEvent {
	if ( pluginOverridesMouse ) return nil;  // Turn off contextual menu.  RBR 3/26/06
	NSPoint contextualMenuWhere = [theEvent locationInWindow]; 	//JF20070103 WindowAnchored ctrl-clickPoint registered 
	contextualMenuInWindowPosX = contextualMenuWhere.x;
	contextualMenuInWindowPosY = contextualMenuWhere.y;	
	//NSLog(@"event.x:%f", contextualMenuWhere.x);//relative to Window	
	//NSLog(@"event.y:%f", contextualMenuWhere.y);//relative to Window	
	//NSLog(@"mouseXPos:%f", mouseXPos);//relative to DCMPix	
	//NSLog(@"mouseYPos:%f", mouseYPos);//relative to DCMPix	
	if (([theEvent modifierFlags] & NSControlKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) return 0L;
	return [self menu];  // Default
}

- (float) contextualMenuInWindowPosX {return contextualMenuInWindowPosX;}
- (float) contextualMenuInWindowPosY {return contextualMenuInWindowPosY;}
	
-(NSString*) stringID
{
	return stringID;
}

-(void) setStringID:(NSString*) str
{
	if( str != stringID)
	{
		[stringID release];
		stringID = str;
		[stringID retain];
	}
}


#pragma mark-
#pragma mark Mouse dragging methods	
- (void)mouseDragged:(NSEvent *)event
{
	// if window is not visible do nothing
	if( [[self window] isVisible] == NO) return;
	
	// if window will close do nothing
	if( [self is2DViewer] == YES)
	{
		if( [[self windowController] windowWillClose]) return;
	}
	
	// We have dragged before timer went off turn off timer and contine with drag
	if (_dragInProgress == NO && ([event deltaX] != 0 || [event deltaY] != 0)) {
		[self deleteMouseDownTimer];
	}
	
	// we are dragging don't do anything
	if (_dragInProgress == YES) return;
	
	// if we have images do drag
    if( dcmPixList)
    {
		
        NSPoint     eventLocation = [event locationInWindow];
        NSPoint     current = [self convertPoint:eventLocation fromView:self];
        short       tool;
        NSRect      size = [self frame];
		
		[self mouseMoved: event];	// Update some variables...
		
		tool = [self getTool: event];
		
		if( crossMove >= 0) tool = tCross;
		
		// if ROI tool is valid continue with drag
		/**************** ROI actions *********************************/
		if( [self roiTool: tool])
		{
			long	i;
			BOOL	action = NO;
			
			NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			
			// get point in Open GL
			tempPt.y = size.size.height - tempPt.y;
			tempPt = [self ConvertFromView2GL:tempPt];
			
			// check rois for hit Test.
			action = [self checkROIsForHitAtPoint:tempPt forEvent:event];
			
			// if we have action the ROI is being drawn. Don't move and rotate ROI
			if( action == NO) // Is there a selected ROI -> rotate or move it
				[self mouseDraggedForROIs: event];
		}
		
		/********** Actions for Various Tools *********************/
		else {
			switch (tool) {
				case t3DRotate:[self mouseDragged3DRotate:event];
					break;
				case tCross: [self mouseDraggedCrosshair:event];
					break;
				case tZoom: [self mouseDraggedZoom:event];
					break;
				case tTranslate:[self mouseDraggedTranslate:event];
					break;
				case tRotate:[self mouseDraggedRotate:event];
					break;
				case tNext:[self mouseDraggedImageScroll:event];
					break;
				case tWLBlended: [self mouseDraggedBlending:event];
					break;
				case tWL:[self mouseDraggedWindowLevel:event];
					break;
				case tRepulsor: [self mouseDraggedRepulsor:event];
					break;
				case tROISelector: [self mouseDraggedROISelector:event];
					break;

				default:break;
			}
		}
   
		
		
		/****************** Update Display ***********************/
		
		previous = current;
        
        [self setNeedsDisplay:YES];
		
		if( [self is2DViewer] == YES)
			[[self windowController] propagateSettings];
		
		if( [stringID isEqualToString:@"FinalView"] == YES || [stringID isEqualToString:@"OrthogonalMPRVIEW"]) [self blendingPropagate];
//		if( [stringID isEqualToString:@"Original"] == YES) [self blendingPropagate];



    }
}


// get current Point for Event in the local view Coordinates
- (NSPoint)currentPointInView:(NSEvent *)event{
	NSPoint     eventLocation = [event locationInWindow];
	return [self convertPoint:eventLocation fromView:self];
}

// Check to see if an roi is selected at the Open GL point
- (BOOL)checkROIsForHitAtPoint:(NSPoint)point  forEvent:(NSEvent *)event{
	BOOL haveHit = NO;
	int i;
	for( i = 0; i < [curRoiList count]; i++)
	{
		if( [[curRoiList objectAtIndex:i] mouseRoiDragged: point :[event modifierFlags] :scaleValue] != NO)
		{
			haveHit = YES;
		}
	}
	return haveHit;			
}

// Modifies the Selected ROIs for the drag. Can rotate, scalem move the ROI or the Text Box.
- (void)mouseDraggedForROIs:(NSEvent *)event{
	
	NSRect  frame = [self frame];
	NSPoint current = [self currentPointInView:event];
	int i = 0;
	// Command and Alternate rotate ROI
	if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))
	{
		NSPoint rotatePoint = [[[event window] contentView] convertPoint:start toView:self];
		rotatePoint.y = frame.size.height - start.y ;
		rotatePoint = [self ConvertFromView2GL: rotatePoint];

		NSPoint offset;
		float   xx, yy;
		
		offset.x = - (previous.x - current.x) / scaleValue;
		offset.y =  (previous.y - current.y) / scaleValue;
		
		for( i = 0; i < [curRoiList count]; i++)
		{
			if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected) [[curRoiList objectAtIndex:i] rotate: offset.x :rotatePoint];
		}
	}
	// Command and Shift scale
	else if (([event modifierFlags] & NSCommandKeyMask) && !([event modifierFlags] & NSShiftKeyMask))
	{
		NSPoint rotatePoint = [[[event window] contentView] convertPoint:start toView:self];
		rotatePoint.y = frame.size.height - start.y ;
		rotatePoint = [self ConvertFromView2GL: rotatePoint];

		NSPoint offset;
		float   xx, yy;
		
		offset.x = - (previous.x - current.x) / scaleValue;
		offset.y =  (previous.y - start.y) / scaleValue;
		
		for( i = 0; i < [curRoiList count]; i++)
		{
			if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected) [[curRoiList objectAtIndex:i] resize: 1 + (offset.x)/20. :rotatePoint];
		}
	}
	// Move ROI
	else
	{
		BOOL textBoxMove = NO;
		NSPoint offset;
		float   xx, yy;
		
		offset.x = - (previous.x - current.x) / scaleValue;
		offset.y =  (previous.y - current.y) / scaleValue;
		
		if( xFlipped) offset.x = -offset.x;
		if( yFlipped) offset.y = -offset.y;
		
		xx = offset.x;		yy = offset.y;
		
		offset.x = xx*cos(rotation*deg2rad) + yy*sin(rotation*deg2rad);
		offset.y = -xx*sin(rotation*deg2rad) + yy*cos(rotation*deg2rad);
		
		offset.y /=  [curDCM pixelRatio];
		// hit test for text box
		for( i = 0; i < [curRoiList count]; i++)
		{
			if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
			{
				if( [[curRoiList objectAtIndex: i] clickInTextBox]) textBoxMove = YES;
			}
		}
		// Move text Box
		if( textBoxMove)
		{
			for( i = 0; i < [curRoiList count]; i++)
			{
				if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
				{
					[[curRoiList objectAtIndex: i] setTextBoxOffset: offset];
				}
			}
		}
		// move ROI
		else
		{
			for( i = 0; i < [curRoiList count]; i++)
			{
				if( [[curRoiList objectAtIndex:i] ROImode] == ROI_selected)
				{
					[[curRoiList objectAtIndex:i] roiMove: offset];
				}
			}
		}
	}
}


// Method for mouse dragging while 3D rotate. Does nothing
- (void)mouseDragged3DRotate:(NSEvent *)event{
}

- (void)mouseDraggedCrosshair:(NSEvent *)event{
	//Moved OrthogonalMPRView specific code to that class
	
	NSRect  frame = [self frame];
	NSPoint current = [self currentPointInView:event];
	NSPoint   eventLocation = [event locationInWindow];
	//if( ![[self stringID] isEqualToString:@"OrthogonalMPRVIEW"])
	//{
		crossPrev = cross;
		
		if( crossMove)
		{
			NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			tempPt.y = frame.size.height - tempPt.y ;
			
			
			cross = [self ConvertFromView2GL:tempPt];
		}
		else
		{
			float newAngle;
			
			NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
			tempPt.y = frame.size.height - tempPt.y ;
			
			tempPt = [self ConvertFromView2GL:tempPt];
			
			tempPt.x -= cross.x;
			tempPt.y -= cross.y;
			
			if( tempPt.y < 0) newAngle = 180 + atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
			else newAngle = atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
			newAngle += 90;
			newAngle = 360 - newAngle;
			
		//	NSLog(@"%2.2f", newAngle);
			if( switchAngle == -1)
			{
				if( fabs( newAngle - angle) > 90 && fabs( newAngle - angle) < 270)
				{
					switchAngle = 1;
				}
				else switchAngle = 0;
			}
			
		//	NSLog(@"AV: old angle: %2.2f new angle: %2.2f", angle, newAngle);
			
			if( switchAngle == 1)
			{
		//		NSLog(@"switch");
				newAngle -= 180;
				if( newAngle < 0) newAngle += 360;
			}
			
		//	NSLog(@"AP: old angle: %2.2f new angle: %2.2f", angle, newAngle);
			
			[self setMPRAngle: newAngle];
		}
		
		[self mouseMoved: event];	// Update some variables...
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object:stringID userInfo: [NSDictionary dictionaryWithObject:@"dragged" forKey:@"action"]];
	//}

}


// Methods for Zooming with mouse Drag
- (void)mouseDraggedZoom:(NSEvent *)event{
	NSPoint current = [self currentPointInView:event];
	[self setScaleValue: (startScaleValue + (current.y - start.y) / (80.))];

	origin.x = ((originStart.x * scaleValue) / startScaleValue);
	origin.y = ((originStart.y * scaleValue) / startScaleValue);
	
	originOffset.x = ((originOffsetStart.x * scaleValue) / startScaleValue);
	originOffset.y = ((originOffsetStart.y * scaleValue) / startScaleValue);
	
	//set value for Series Object Presentation State
	if ([self is2DViewer] == YES)
	{
		[[self seriesObj] setValue:[NSNumber numberWithFloat:scaleValue] forKey:@"scale"];
		[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
		[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
		[[self seriesObj] setValue:[NSNumber numberWithFloat:1] forKey:@"displayStyle"];
	}

}


// Method for translating the image while dragging
- (void)mouseDraggedTranslate:(NSEvent *)event{
	NSPoint current = [self currentPointInView:event];
	float xmove, ymove, xx, yy;
            
	xmove = (current.x - start.x);
	ymove = -(current.y - start.y);
	
	if( xFlipped) xmove = -xmove;
	if( yFlipped) ymove = -ymove;
	
	xx = xmove*cos((rotation)*deg2rad) + ymove*sin((rotation)*deg2rad);
	yy = xmove*sin((rotation)*deg2rad) - ymove*cos((rotation)*deg2rad);
	
	origin.x = originStart.x + xx;
	origin.y = originStart.y + yy;
	
	//set value for Series Object Presentation State
	if ([self is2DViewer] == YES)
	{
		[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
		[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
	}

}


//Method for rotating
- (void)mouseDraggedRotate:(NSEvent *)event{
	NSPoint current = [self currentPointInView:event];
	rotation = rotationStart - (current.x - start.x);
	while( rotation < 0) rotation += 360;
	while( rotation > 360) rotation -= 360;
	
	//set value for Series Object Presentation State
	[[self seriesObj] setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
}

//Scrolling through images with Mouse
// could be cleaned up by subclassing DCMView
- (void)mouseDraggedImageScroll:(NSEvent *)event{
	short   inc, now, prev, previmage;
	BOOL	movie4Dmove = NO;
	NSPoint current = [self currentPointInView:event];
	if( scrollMode == 0)
	{
		if( fabs( start.x - current.x) < fabs( start.y - current.y))
		{
			prev = start.y/2;
			now = current.y/2;
			if( fabs( start.y - current.y) > 3) scrollMode = 1;
		}
		else if( fabs( start.x - current.x) >= fabs( start.y - current.y))
		{
			prev = start.x/2;
			now = current.x/2;
			if( fabs( start.x - current.x) > 3) scrollMode = 2;
		}
		
	//	NSLog(@"scrollMode : %d", scrollMode);
	}
	
	if( movie4Dmove == NO)
	{
		previmage = curImage;
		
		if( scrollMode == 2)
		{
			curImage = startImage + ((current.x - start.x) * [dcmPixList count] )/ ([self frame].size.width/2);
		}
		else if( scrollMode == 1)
		{
			curImage = startImage + ((start.y - current.y) * [dcmPixList count] )/ ([self frame].size.height/2);
		}
		
		if( curImage < 0) curImage = 0;
		if( curImage >= [dcmPixList count]) curImage = [dcmPixList count] -1;
		
		if(previmage != curImage)
		{
			if( listType == 'i') [self setIndex:curImage];
			else [self setIndexWithReset:curImage :YES];
			
			if( matrix) [matrix selectCellAtRow :curImage/[browserWindow COLUMN] column:curImage%[browserWindow COLUMN]];
			
			if( [self is2DViewer] == YES)
				[[self windowController] adjustSlider];
			
			if( stringID) [[self windowController] adjustSlider];
			
			// SYNCRO
			[self sendSyncMessage: curImage - previmage];
		}
	}
}

- (void)mouseDraggedBlending:(NSEvent *)event{
	float WWAdapter = bdstartWW / 100.0;
	NSPoint current = [self currentPointInView:event];
	if( WWAdapter < 0.001) WWAdapter = 0.001;

	if( [self is2DViewer] == YES)
	{
		[[[self windowController] thickSlabController] setLowQuality: YES];
	}

	if( [[[[blendingView dcmFilesList] objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[[blendingView dcmFilesList] objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"NM"] == YES))
	{
		float startlevel;
		float endlevel;
		
		float eWW, eWL;
		
		NSLog( @"PT");
		
		switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"])
		{
			case 0:
				eWL = bdstartWL + (current.y -  start.y)*WWAdapter;
				eWW = bdstartWW + (current.x -  start.x)*WWAdapter;
				
				if( eWW < 0.1) eWW = 0.1;
			break;
			
			case 1:
				endlevel = bdstartMax + (current.y -  start.y) * WWAdapter ;
				
				eWL = (endlevel - bdstartMin) / 2 + [[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"];
				eWW = endlevel - bdstartMin;
				
				if( eWW < 0.1) eWW = 0.1;
				if( eWL - eWW/2 < 0) eWL = eWW/2;
			break;
			
			case 2:
				endlevel = bdstartMax + (current.y -  start.y) * WWAdapter ;
				startlevel = bdstartMin + (current.x -  start.x) * WWAdapter ;
				
				if( startlevel < 0) startlevel = 0;
				
				eWL = startlevel + (endlevel - startlevel) / 2;
				eWW = endlevel - startlevel;
				
				if( eWW < 0.1) eWW = 0.1;
				if( eWL - eWW/2 < 0) eWL = eWW/2;
			break;
		}
		
		[[blendingView curDCM] changeWLWW :eWL  :eWW];
	}
	else
	{
		[[blendingView curDCM] changeWLWW : bdstartWL + (current.y -  start.y)*WWAdapter :bdstartWW + (current.x -  start.x)*WWAdapter];
	}

	if( [self is2DViewer] == YES)
	{
		[[blendingView windowController] setCurWLWWMenu: [DCMView findWLWWPreset: [[blendingView curDCM] wl] :[[blendingView curDCM] ww] :curDCM]];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [DCMView findWLWWPreset: [[blendingView curDCM] wl] :[[blendingView curDCM] ww] :curDCM] userInfo: 0L];


	[blendingView loadTextures];
	[self loadTextures];

	[[NSNotificationCenter defaultCenter] postNotificationName: @"changeWLWW" object: blendingView userInfo:0L];

}

- (void)mouseDraggedWindowLevel:(NSEvent *)event{
	NSPoint current = [self currentPointInView:event];
	// Not blending
	//if( !([stringID isEqualToString:@"OrthogonalMPRVIEW"] && (blendingView != 0L)))
	{
		float WWAdapter = startWW / 100.0;

		if( WWAdapter < 0.001) WWAdapter = 0.001;
		
		if( [self is2DViewer] == YES)
		{
			[[[self windowController] thickSlabController] setLowQuality: YES];
		}
		
		if( [[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"NM"] == YES))
		{
			float startlevel;
			float endlevel;
			
			float eWW, eWL;
			
			switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"])
			{
				case 0:
					eWL = startWL + (current.y -  start.y)*WWAdapter;
					eWW = startWW + (current.x -  start.x)*WWAdapter;
					
					if( eWW < 0.1) eWW = 0.1;
				break;
				
				case 1:
					endlevel = startMax + (current.y -  start.y) * WWAdapter ;
					
					eWL = (endlevel - startMin) / 2 + [[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"];
					eWW = endlevel - startMin;
					
					if( eWW < 0.1) eWW = 0.1;
					if( eWL - eWW/2 < 0) eWL = eWW/2;
				break;
				
				case 2:
					endlevel = startMax + (current.y -  start.y) * WWAdapter ;
					startlevel = startMin + (current.x -  start.x) * WWAdapter ;
					
					if( startlevel < 0) startlevel = 0;
					
					eWL = startlevel + (endlevel - startlevel) / 2;
					eWW = endlevel - startlevel;
					
					if( eWW < 0.1) eWW = 0.1;
					if( eWL - eWW/2 < 0) eWL = eWW/2;
				break;
			}
			
			[curDCM changeWLWW :eWL  :eWW];
		}
		else
		{
			[curDCM changeWLWW : startWL + (current.y -  start.y)*WWAdapter :startWW + (current.x -  start.x)*WWAdapter];
		}
		
		curWW = [curDCM ww];
		curWL = [curDCM wl];
		
		if( [self is2DViewer] == YES)
		{
			[[self windowController] setCurWLWWMenu: [DCMView findWLWWPreset: curWL :curWW :curDCM]];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [DCMView findWLWWPreset: curWL :curWW :curDCM] userInfo: 0L];
		// Probably can move this to the end of MPRPreview after calling the super 
		if( stringID)
		{
			if( [stringID isEqualToString:@"Perpendicular"] || [stringID isEqualToString:@"FinalView"] || [stringID isEqualToString:@"Original"] || [stringID isEqualToString:@"FinalViewBlending"])
			{
				[[[self windowController] MPR2Dview] adjustWLWW: curWL :curWW :@"dragged"];
			}

			else [self loadTextures];
		}
		else [self loadTextures];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"changeWLWW" object: curDCM userInfo:0L];
		
		if( [curDCM SUVConverted] == NO)
		{
			//set value for Series Object Presentation State
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
		}
		else
		{
			if( [self is2DViewer] == YES)
			{
				[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
				[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
			}
		}
	}
	//Blending and OrthogonalMPRVIEW
	/*
	else if([stringID isEqualToString:@"OrthogonalMPRVIEW"] && (blendingView != 0L))
	{
		// change blending value
		blendingFactor = blendingFactorStart + (current.x - start.x);
			
		if( blendingFactor < -256.0) blendingFactor = -256.0;
		if( blendingFactor > 256.0) blendingFactor = 256.0;
		
		[self setBlendingFactor: blendingFactor];
	}
	*/
}

- (void)mouseDraggedRepulsor:(NSEvent *)event
{
	NSRect frame = [self frame];
	NSPoint     eventLocation = [event locationInWindow];
	NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
	tempPt.y = frame.size.height - tempPt.y ;
	repulsorPosition = tempPt;
	tempPt = [self ConvertFromView2GL:tempPt];
	
	float pixSpacingRatio = 1.0;
	if([self pixelSpacingY]!=0 && [self pixelSpacingX]!=0)
		pixSpacingRatio = [self pixelSpacingY]/[self pixelSpacingX];
	
	float dx, dx2, dy, dy2, d;
	NSPoint pt, pt2;

	float minD, maxD, maxN;
	minD = 10.0 / scaleValue;
	maxD = 50.0 / scaleValue;
	maxN = 10.0 * scaleValue;
	
	int i, j, k;
	NSMutableArray *points;
		
	NSRect repulsorRect = NSMakeRect(tempPt.x-repulsorRadius, tempPt.y-repulsorRadius, repulsorRadius*2.0 , repulsorRadius*2.0);
		
	for(i=0; i<[curRoiList count]; i++)
	{	
		if([(ROI*)[curRoiList objectAtIndex:i] type] != tAxis && [(ROI*)[curRoiList objectAtIndex:i] type] != tDynAngle) //JJCP
		{		
			points = [[curRoiList objectAtIndex:i] points];
			int n = 0;
			for(j=0; j<[points count]; j++)
			{
				pt = [[points objectAtIndex:j] point];
				if(NSPointInRect(pt, repulsorRect))
				{
					dx = (pt.x-tempPt.x);
					dx2 = dx * dx;
					dy = (pt.y-tempPt.y)*pixSpacingRatio;
					dy2 = dy * dy;
					d = sqrt(dx2 + dy2);
					
					if(d<repulsorRadius)
					{
						if([(ROI*)[curRoiList objectAtIndex:i] type] == t2DPoint)
							[[curRoiList objectAtIndex:i] setROIRect:NSOffsetRect([[curRoiList objectAtIndex:i] rect],dx/d*repulsorRadius-dx,dy/d*repulsorRadius-dy)];
						else
							[[points objectAtIndex:j] move:dx/d*repulsorRadius-dx :dy/d*repulsorRadius-dy];
						
						pt.x += dx/d*repulsorRadius-dx;
						pt.y += dy/d*repulsorRadius-dy;
						
						int delta;
						for(delta=-1; delta<=1; delta++)
						{
							k = j+delta;
							if([(ROI*)[curRoiList objectAtIndex:i] type] == tCPolygon || [(ROI*)[curRoiList objectAtIndex:i] type] == tPencil)
							{
								if(k==-1)
									k = [points count]-1;
								else if(k==[points count])
									k = 0;
							}
							
							if(k!=j && k>=0 && k<[points count])
							{
								pt2 = [[points objectAtIndex:k] point];
								dx = (pt2.x-pt.x);
								dx2 = dx * dx;
								dy = (pt2.y-pt.y)*pixSpacingRatio;
								dy2 = dy * dy;
								d = sqrt(dx2 + dy2);
								
								if(d<=minD && d<repulsorRadius)
								{
									[points removeObjectAtIndex:k];
									if(delta==-1) j--;
								}
								else if((d>=maxD || d>=repulsorRadius) && n<maxN)
								{
									NSPoint pt3;
									pt3.x = (pt2.x+pt.x)/2.0;
									pt3.y = (pt2.y+pt.y)/2.0;
									MyPoint *p = [[MyPoint alloc] initWithPoint:pt3];
									int index = (delta==-1)? j : j+1 ;
									if(delta==-1) j++;
									[points insertObject:p atIndex:index];
									n++;
								}
							}
						}
						
						if( [[[curRoiList objectAtIndex:i] comments] isEqualToString: @"morphing generated"])
							[[curRoiList objectAtIndex:i] setComments:@""];
						[[NSNotificationCenter defaultCenter] postNotificationName:@"roiChange" object:[curRoiList objectAtIndex:i] userInfo: 0L];
					}
				}
			}
		}
	}
}
		
- (void)mouseDraggedROISelector:(NSEvent *)event;
{
	int i, j, k;
	NSMutableArray *points;
	
	// deselect all ROIs
	for(i=0; i<[curRoiList count]; i++)
	{
		// ROISelectorSelectedROIList contains ROIs that were selected _before_ the click
		if([ROISelectorSelectedROIList containsObject:[curRoiList objectAtIndex:i]])// this will be possible only if shift key is pressed
			[[curRoiList objectAtIndex:i] setROIMode:ROI_selected];
		else
			[[curRoiList objectAtIndex:i] setROIMode:ROI_sleep];
	}

	NSRect frame = [self frame];
	NSPoint eventLocation = [event locationInWindow];
	NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
	tempPt.y = frame.size.height - tempPt.y ;
	ROISelectorEndPoint = tempPt;
	
	NSPoint	polyRect[ 4];
	
	NSRect rect;
	
	if( rotation == 0)
	{	
		NSPoint tempStartPoint = [self ConvertFromView2GL:ROISelectorStartPoint];
		NSPoint tempEndPoint = [self ConvertFromView2GL:ROISelectorEndPoint];
		
		rect = NSMakeRect(min(tempStartPoint.x, tempEndPoint.x), min(tempStartPoint.y, tempEndPoint.y), fabsf(tempStartPoint.x - tempEndPoint.x), fabsf(tempStartPoint.y - tempEndPoint.y));
		
		if(rect.size.width<1)rect.size.width=1;
		if(rect.size.height<1)rect.size.height=1;
	}
	else
	{
		polyRect[ 0] = [self ConvertFromView2GL:ROISelectorStartPoint];
		polyRect[ 1] = [self ConvertFromView2GL:NSMakePoint(ROISelectorStartPoint.x,ROISelectorStartPoint.y - (ROISelectorStartPoint.y-ROISelectorEndPoint.y))];
		polyRect[ 2] = [self ConvertFromView2GL:ROISelectorEndPoint];
		polyRect[ 3] = [self ConvertFromView2GL:NSMakePoint(ROISelectorStartPoint.x - (ROISelectorStartPoint.x-ROISelectorEndPoint.x),ROISelectorStartPoint.y)];
	}
	
	// select ROIs in the selection rectangle
	for(i=0; i<[curRoiList count]; i++)
	{
		ROI *roi = [curRoiList objectAtIndex:i];
		BOOL intersected = NO;
		long roiType = [roi type];
		
		if( rotation == 0)
		{
			if(roiType==tText)
			{
				float w = [roi rect].size.width/scaleValue;
				float h = [roi rect].size.height/scaleValue;
				NSPoint o = [roi rect].origin;
				NSRect curROIRect = NSMakeRect( o.x-w/2.0, o.y-h/2.0, w, h);
				intersected = NSIntersectsRect(rect, curROIRect);
			}
			else if(roiType==tROI)
			{
				intersected = NSIntersectsRect(rect, [roi rect]);
			}
			else if(roiType==t2DPoint)
			{
				intersected = NSPointInRect([[[roi points] objectAtIndex:0] point], rect);
			}
			else
			{
				points = [[curRoiList objectAtIndex:i] points];
				NSPoint p1, p2;
				for(j=0; j<[points count]-1 && !intersected; j++)
				{
					p1 = [[points objectAtIndex:j] point];
					p2 = [[points objectAtIndex:j+1] point];
					intersected = lineIntersectsRect(p1, p2,  rect);
				}
				// last segment: between last point and first one
				if(!intersected && roiType!=tMesure && roiType!=tAngle && roiType!=t2DPoint && roiType!=tOPolygon && roiType!=tArrow)
				{
					p1 = [[points lastObject] point];
					p2 = [[points objectAtIndex:0] point];
					intersected = lineIntersectsRect(p1, p2,  rect);
				}
			}
		}
		else
		{
			if(roiType==tText)
			{
				float w = [roi rect].size.width/scaleValue;
				float h = [roi rect].size.height/scaleValue;
				NSPoint o = [roi rect].origin;
				NSRect curROIRect = NSMakeRect( o.x-w/2.0, o.y-h/2.0, w, h);
				
				if(!intersected) intersected = [DCMPix IsPoint: NSMakePoint( NSMinX( curROIRect), NSMinY( curROIRect)) inPolygon:polyRect size:4];
				if(!intersected) intersected = [DCMPix IsPoint: NSMakePoint( NSMinX( curROIRect), NSMaxY( curROIRect)) inPolygon:polyRect size:4];
				if(!intersected) intersected = [DCMPix IsPoint: NSMakePoint( NSMaxX( curROIRect), NSMaxY( curROIRect)) inPolygon:polyRect size:4];
				if(!intersected) intersected = [DCMPix IsPoint: NSMakePoint( NSMaxX( curROIRect), NSMinY( curROIRect)) inPolygon:polyRect size:4];
			}
			else if(roiType==t2DPoint)
			{
				intersected = [DCMPix IsPoint: [[[roi points] objectAtIndex:0] point] inPolygon:polyRect size:4];
			}
			else
			{
				points = [[curRoiList objectAtIndex:i] points];
				NSPoint p1, p2;
				for(j=0; j<[points count] && !intersected; j++)
				{
					intersected = [DCMPix IsPoint: [[points objectAtIndex:j] point] inPolygon:polyRect size:4];
				}
				
				if( !intersected)
				{
					NSPoint	*p = malloc( sizeof( NSPoint) * [points count]);
					for(j=0; j<[points count]; j++) p[ j] = [[points objectAtIndex:j] point];
					for(j=0; j<4 && !intersected; j++)
					{
						intersected = [DCMPix IsPoint: polyRect[j] inPolygon:p size:[points count]];
					}
					free(p);
				}
				
				if( !intersected)
				{
					points = [[curRoiList objectAtIndex:i] points];
					NSPoint p1, p2;
					for(j=0; j<[points count]-1 && !intersected; j++)
					{
						p1 = [[points objectAtIndex:j] point];
						p2 = [[points objectAtIndex:j+1] point];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[0] B2:polyRect[1] result: 0L];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[1] B2:polyRect[2] result: 0L];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[2] B2:polyRect[3] result: 0L];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[3] B2:polyRect[0] result: 0L];
					}
					
					// last segment: between last point and first one
					if(!intersected && roiType!=tMesure && roiType!=tAngle && roiType!=t2DPoint && roiType!=tOPolygon && roiType!=tArrow)
					{
						p1 = [[points lastObject] point];
						p2 = [[points objectAtIndex:0] point];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[0] B2:polyRect[1] result: 0L];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[1] B2:polyRect[2] result: 0L];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[2] B2:polyRect[3] result: 0L];
						if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[3] B2:polyRect[0] result: 0L];
					}
				}
			}
		}
		
		if(intersected)
		{
			if([event modifierFlags] & NSShiftKeyMask) // invert the mode: selected->sleep, sleep->selected
			{
				long mode = [roi ROImode];
				if(mode==ROI_sleep) mode=ROI_selected;
				else if(mode==ROI_selected) mode=ROI_sleep;
					
				// set the mode for the ROI and its group (if any)
				[roi setROIMode:mode];
				[[self windowController] setMode:mode toROIGroupWithID:[roi groupID]];
			}
			else
			{
				[[self windowController] selectROI:roi deselectingOther:NO];
			}
		}
	}
	
	
	
}

#pragma mark-
#pragma mark ww/wl
- (void) getWLWW:(float*) wl :(float*) ww
{
	if( curDCM == 0L) NSLog(@"curDCM 0L");
	else
	{
		if(wl) *wl = [curDCM wl];
		if(ww) *ww = [curDCM ww];
	}
}

- (void) changeWLWW: (NSNotification*) note
{
	DCMPix	*otherPix = [note object];
	
	if( ([[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"CR"] && IndependentCRWLWW) || COPYSETTINGSINSERIES == NO) return;
	
	if( [dcmPixList containsObject: otherPix])
	{
		float iwl, iww;
		
		iww = [otherPix ww];
		iwl = [otherPix wl];
		
		if( iww != [curDCM ww] || iwl != [curDCM wl])
			[self setWLWW: iwl :iww];
	}
	
	if( blendingView)
	{
		if( [[blendingView dcmPixList] containsObject: otherPix])
		{
			float iwl, iww;
			
			iww = [otherPix ww];
			iwl = [otherPix wl];
			
			if( iww != [[blendingView curDCM] ww] || iwl != [[blendingView curDCM] wl])
			{
				[blendingView setWLWW: iwl :iww];
				[self loadTextures];
				[self setNeedsDisplay:YES];
			}
		}
	}
}

- (void) setWLWW:(float) wl :(float) ww
{
    [curDCM changeWLWW :wl : ww];
    
    curWW = [curDCM ww];
    curWL = [curDCM wl];
    	
    [self loadTextures];
    [self setNeedsDisplay:YES];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"changeWLWW" object: curDCM userInfo:0L];
	
	//set value for Series Object Presentation State
	if( [curDCM SUVConverted] == NO)
	{
		[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
		[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
	}
	else
	{
		if( [self is2DViewer] == YES)
		{
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
		}
	}
}

- (void)discretelySetWLWW:(float)wl :(float)ww;
{
    [curDCM changeWLWW :wl : ww];
    
    curWW = [curDCM ww];
    curWL = [curDCM wl];
	
    [self loadTextures];
    [self setNeedsDisplay:YES];
	
	//set value for Series Object Presentation State
	if( [curDCM SUVConverted] == NO)
	{
		[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
		[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
	}
	else
	{
		if( [self is2DViewer] == YES)
		{
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
		}
	}
}

-(void) setFusion:(short) mode :(short) stacks
{
	long i, x;
	
	thickSlabMode = mode;
	thickSlabStacks = stacks;
	
	for ( i = 0; i < [dcmPixList count]; i ++)
	{
		[[dcmPixList objectAtIndex:i] setFusion:mode :stacks :flippedData];
	}
	
	[self setIndex: curImage];
}

-(void) multiply:(DCMView*) bV
{
	[curDCM imageArithmeticMultiplication: [bV curDCM]];
	
	[curDCM changeWLWW :curWL: curWW];
	[self loadTextures];
	[self setNeedsDisplay: YES];
}

-(void) subtract:(DCMView*) bV
{
	[curDCM imageArithmeticSubtraction: [bV curDCM]];
	
	[curDCM changeWLWW :curWL: curWW];
	[self loadTextures];
	[self setNeedsDisplay: YES];
}

-(void) setBlending:(DCMView*) bV
{
	float orientA[9], orientB[9];
	float result[3];
	
	if( blendingView == bV) return;
	
	if( bV)
	{
		if( [bV curDCM])
		{
			[curDCM orientation:orientA];
			[[bV curDCM] orientation:orientB];
			
			if( orientB[ 6] == 0 && orientB[ 7] == 0 && orientB[ 8] == 0) { blendingView = bV;	return;}
			if( orientA[ 6] == 0 && orientA[ 7] == 0 && orientA[ 8] == 0) { blendingView = bV;	return;}
			
			// normal vector of planes
			
			result[0] = fabs( orientB[ 6] - orientA[ 6]);
			result[1] = fabs( orientB[ 7] - orientA[ 7]);
			result[2] = fabs( orientB[ 8] - orientA[ 8]);
			
			if( result[0] + result[1] + result[2] > 0.01)  // Planes are not paralel!
			{
				if( NSRunCriticalAlertPanel(NSLocalizedString(@"2D Planes",nil),NSLocalizedString(@"These 2D planes are not parallel. The result in 2D will be distorted.",nil), NSLocalizedString(@"Continue",nil), NSLocalizedString(@"Cancel",nil),nil) != NSAlertDefaultReturn)
				{
					blendingView = 0L;
				}
				else blendingView = bV;
			}
			else blendingView = bV;
		}
	}
	else blendingView = 0L;
}

-(void) getCLUT:( unsigned char**) r : (unsigned char**) g : (unsigned char**) b
{
	*r = redTable;
	*g = greenTable;
	*b = blueTable;
}

- (void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long i;

	if( r)
	{
		for( i = 0; i < 256; i++)
		{
			redTable[i] = r[i];
			greenTable[i] = g[i];
			blueTable[i] = b[i];
		}
		
		colorTransfer = YES;
	}
	else
	{
		colorTransfer = NO;
		if( colorBuf) free(colorBuf);
		colorBuf = 0L;
		
		for( i = 0; i < 256; i++)
		{
			redTable[i] = i;
			greenTable[i] = i;
			blueTable[i] = i;
		}
	}
	
//JF not necesary	[curDCM changeWLWW :curWL: curWW];
}

-(short) curImage
{
    return curImage;
}

- (BOOL) suppressLabels
{
	return suppress_labels;
}


- (void) prepareOpenGL
{

}

- (float) syncRelativeDiff {return syncRelativeDiff;}
- (void) setSyncRelativeDiff: (float) v
{
	syncRelativeDiff = v;
	NSLog(@"sync relative: %2.2f", syncRelativeDiff);
}

+ (void) computePETBlendingCLUT
{
	if( PETredTable != 0L) free( PETredTable);
	if( PETgreenTable != 0L) free( PETgreenTable);
	if( PETblueTable != 0L) free( PETblueTable);
	
	NSDictionary		*aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Blending CLUT"]];
	if( aCLUT)
	{
		long				i;
		NSArray				*array;
		
		PETredTable = malloc( 256);
		PETgreenTable = malloc( 256);
		PETblueTable = malloc( 256);
		
		array = [aCLUT objectForKey:@"Red"];
		for( i = 0; i < 256; i++)
		{
			PETredTable[i] = [[array objectAtIndex: i] longValue];
		}
		
		array = [aCLUT objectForKey:@"Green"];
		for( i = 0; i < 256; i++)
		{
			PETgreenTable[i] = [[array objectAtIndex: i] longValue];
		}
		
		array = [aCLUT objectForKey:@"Blue"];
		for( i = 0; i < 256; i++)
		{
			PETblueTable[i] = [[array objectAtIndex: i] longValue];
		}
	}
}

- (void) initFont
{
	fontListGL = glGenLists (150);
	fontGL = [[NSFont fontWithName: [[NSUserDefaults standardUserDefaults] stringForKey:@"FONTNAME"] size: [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"]] retain];
	if( fontGL == 0L) fontGL = [[NSFont fontWithName:@"Geneva" size:14] retain];
	[fontGL makeGLDisplayListFirst:' ' count:150 base: fontListGL :fontListGLSize :NO];
	stringSize = [DCMView sizeOfString:@"B" forFont:fontGL];
}

- (id)initWithFrameInt:(NSRect)frameRect
{
	long i;
	
	if( PETredTable == 0L)
	{
		[DCMView computePETBlendingCLUT];
	}
	
	yearOld = 0L;
	shortDateString = [[[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateOfBirthFormat"] retain];
	shortDateTimeString = [[[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateFormat"] retain];
	localeDictionnary = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
	syncSeriesIndex = -1;
	mouseXPos = mouseYPos = 0;
	pixelMouseValue = 0;
	originOffset.x = originOffset.y = 0;
	curDCM = 0L;
	curRoiList = 0L;
	blendingMode = 0;
	display2DPoint = NSMakePoint(0,0);
	colorBuf = 0L;
	blendingColorBuf = 0L;
	stringID = 0L;
	mprVector[ 0] = 0;
	mprVector[ 1] = 0;
	crossMove = -1;
	previousViewSize.height = previousViewSize.width = 0;
	slab = 0;
	cursor = 0L;
	cursorSet = NO;
	syncRelativeDiff = 0;
	volumicSeries = YES;
	currentToolRight = [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTRIGHTTOOL"];
	thickSlabMode = 0;
	thickSlabStacks = 0;
	
	suppress_labels = NO;
	
    NSLog(@"DCMView alloc");

    // Init pixel format attribs
//    NSOpenGLPixelFormatAttribute attrs[] =
//    {
//            NSOpenGLPFADoubleBuffer,
//			NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32,
//			0
//	};

	NSOpenGLPixelFormatAttribute attrs[] =
    {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
            NSOpenGLPFADoubleBuffer,
			NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32,
			0
	};
	
	
	// Get pixel format from OpenGL
    NSOpenGLPixelFormat* pixFmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
    if (!pixFmt)
    {
    //        NSRunCriticalAlertPanel(NSLocalizedString(@"OPENGL ERROR",nil), NSLocalizedString(@"Not able to run Quartz Extreme: OpenGL+Quartz. Update your video hardware!",nil), NSLocalizedString(@"OK",nil), nil, nil);
	//		exit(1);
    }
	self = [super initWithFrame:frameRect pixelFormat:pixFmt];
	
	blendingView = 0L;
	pTextureName = 0L;
	blendingTextureName = 0L;
	
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(doSyncronize:)
               name: @"sync"
             object: nil];
	
	[nc	addObserver: self
			selector: @selector(Display3DPoint:)
				name: @"Display3DPoint"
			object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"roiChange"
             object: nil];
			 
	[nc addObserver: self
           selector: @selector(roiSelected:)
               name: @"roiSelected"
             object: nil];
             
    [nc addObserver: self
           selector: @selector(updateView:)
               name: @"updateView"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(setFontColor:)
               name:  @"DCMNewFontColor" 
             object: nil];
			 
	[nc addObserver: self
           selector: @selector(changeGLFontNotification:)
               name:  @"changeGLFontNotification" 
             object: nil];
			
	[nc	addObserver: self
			selector: @selector(changeWLWW:)
				name: @"changeWLWW"
			object: nil];
	
    colorTransfer = NO;
	
	for (i = 0; i < 256; i++)
	{
		alphaTable[i] = 0xFF;
		redTable[i] = i;
		greenTable[i] = i;
		blueTable[i] = i;
	}

	redFactor = 1.0;
	greenFactor = 1.0;
	blueFactor = 1.0;
	
    dcmPixList = 0L;
    dcmFilesList = 0L;
    
    [[self openGLContext] makeCurrentContext];
    

    blendingFactor = 0.5;
	
    long swap = 1;  // LIMIT SPEED TO VBL if swap == 1
	[[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
    
	[self FindMinimumOpenGLCapabilities];

//    glEnable (GL_MULTISAMPLE_ARB);
//    glHint (GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
	
//	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

    // This hint is for antialiasing
	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

    // Setup some basic OpenGL stuff
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	fontColor = nil;
	
	[self initFont];
		
	labelFontListGL = glGenLists (150);
	labelFont = [[NSFont fontWithName:@"Monaco" size:12] retain];
	[labelFont makeGLDisplayListFirst:' ' count:150 base: labelFontListGL :labelFontListGLSize :YES];
	
    currentTool =  [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTLEFTTOOL"];
    
	cross.x = cross.y = -9999;
	
	mouseModifiers = [[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkMouseModifiers:) userInfo:nil repeats:YES] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: 0L];
	
	_alternateContext = [[NSOpenGLContext alloc] initWithFormat:pixFmt shareContext:[self openGLContext]];

	_hotKeyDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYS"] retain];
	
	repulsorRadius = 0;
	
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
	//	NSLog( @"windowWillClose - NSView level");
		[mouseModifiers invalidate];
		[mouseModifiers release];
		mouseModifiers = 0L;
		
		[[NSNotificationCenter defaultCenter] removeObserver: self];
	}
}

-(BOOL) volumicSeries
{
	return volumicSeries;
}

-(void) sendSyncMessage:(short) inc
{
	if( numberOf2DViewer > 1   && isKeyView)	//&&  [[self window] isMainWindow] == YES
    {
		DCMPix	*thickDCM;
		
		if( [curDCM stack] > 1)
		{
			long maxVal;
			
			if( flippedData) maxVal = curImage-([curDCM stack]-1);
			else maxVal = curImage+[curDCM stack]-1;
			if( maxVal < 0) maxVal = 0;
			if( maxVal >= [dcmPixList count]) maxVal = [dcmPixList count]-1;
			
			thickDCM = [dcmPixList objectAtIndex: maxVal];
		}
		else thickDCM = 0L;
		
		int pos;
		if( flippedData) pos = [dcmPixList count] -1 -curImage;
		else pos = curImage;
		
		if( flippedData) inc = -inc;
		
        NSDictionary *instructions = [[[NSDictionary alloc] initWithObjectsAndKeys:     self, @"view",
																						[NSNumber numberWithLong:pos],@"Pos",
                                                                                        [NSNumber numberWithLong:inc], @"Direction",
																						[NSNumber numberWithFloat:[[dcmPixList objectAtIndex:curImage] sliceLocation]],@"Location", 
																						[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.studyInstanceUID"], @"studyID", 
																						[NSNumber numberWithFloat: syncRelativeDiff],@"offsetsync",
																						curDCM, @"DCMPix",
																						thickDCM, @"DCMPix2", // WARNING thickDCM can be nil!! nothing after this one...
																						nil]
                                                                                        autorelease];
        
		if( stringID == 0L)		//|| [stringID isEqualToString:@"Original"])
		{
			NSNotificationCenter *nc;
			nc = [NSNotificationCenter defaultCenter];
			[nc postNotificationName: @"sync" object: self userInfo: instructions];
		}
		// most subclasses just need this. NO sync notification for subclasses.
		if( blendingView) // We have to reload the blending image..
		{
			[self loadTextures];
			[self setNeedsDisplay: YES];
		}
    }
}

-(void) becomeMainWindow
{
	[self setFusion: thickSlabMode :-1];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMNewImageViewResponder" object: self userInfo: 0L];
	
	sliceVector[ 0] = sliceVector[ 1] = sliceVector[ 2] = 0;
	slicePoint3D[ 0] = slicePoint3D[ 1] = slicePoint3D[ 2] = 0;
	sliceVector2[ 0] = sliceVector2[ 1] = sliceVector2[ 2] = 0;
	[self sendSyncMessage:0];
	
	[appController setXFlipped: xFlipped];
	[appController setYFlipped: yFlipped];
	
	[self setNeedsDisplay:YES];
}

-(void) becomeKeyWindow
{
	sliceVector[ 0] = sliceVector[ 1] = sliceVector[ 2] = 0;
	slicePoint3D[ 0] = slicePoint3D[ 1] = slicePoint3D[ 2] = 0;
	sliceVector2[ 0] = sliceVector2[ 1] = sliceVector2[ 2] = 0;
	[self sendSyncMessage:0];
	[self setNeedsDisplay:YES];
}

-(void) computeSlice:(DCMPix*) oPix :(DCMPix*) oPix2
// COMPUTE SLICE PLANE
{
	float vectorA[ 9], vectorA2[ 9], vectorB[ 9];
	float originA[ 3], originA2[ 3], originB[ 3];
	
	originA[ 0] = [oPix originX];		originA[ 1] = [oPix originY];		originA[ 2] = [oPix originZ];
	if( oPix2)
	{
		originA2[ 0] = [oPix2 originX];		originA2[ 1] = [oPix2 originY];		originA2[ 2] = [oPix2 originZ];
	}
	originB[ 0] = [curDCM originX];		originB[ 1] = [curDCM originY];		originB[ 2] = [curDCM originZ];
	
	[oPix orientation: vectorA];		//vectorA[0] = vectorA[6];	vectorA[1] = vectorA[7];	vectorA[2] = vectorA[8];
	if( oPix2) [oPix2 orientation: vectorA2];
	[curDCM orientation: vectorB];		//vectorB[0] = vectorB[6];	vectorB[1] = vectorB[7];	vectorB[2] = vectorB[8];
	
	if( intersect3D_2Planes( vectorA+6, originA, vectorB+6, originB, sliceVector, slicePoint) == noErr)
	{
		float perpendicular[ 3], temp[ 3];
		
		CROSS( perpendicular, sliceVector, (vectorB + 6));
		
		// Now reoriente this 3D line in our plane!
		
	//	NSLog(@"slice compute");
		
		temp[ 0] = sliceVector[ 0] * vectorB[ 0] + sliceVector[ 1] * vectorB[ 1] + sliceVector[ 2] * vectorB[ 2];
		temp[ 1] = sliceVector[ 0] * vectorB[ 3] + sliceVector[ 1] * vectorB[ 4] + sliceVector[ 2] * vectorB[ 5];
		temp[ 2] = sliceVector[ 0] * vectorB[ 6] + sliceVector[ 1] * vectorB[ 7] + sliceVector[ 2] * vectorB[ 8];
		sliceVector[ 0] = temp[ 0];
		sliceVector[ 1] = temp[ 1];
		sliceVector[ 2] = temp[ 2];
		
		slicePoint[ 0] -= [curDCM originX];
		slicePoint[ 1] -= [curDCM originY];
		slicePoint[ 2] -= [curDCM originZ];
		
		slicePoint[ 0] += perpendicular[ 0] * [oPix sliceThickness]/2.;
		slicePoint[ 1] += perpendicular[ 1] * [oPix sliceThickness]/2.;
		slicePoint[ 2] += perpendicular[ 2] * [oPix sliceThickness]/2.;
		
		slicePointO[ 0] = slicePoint[ 0] + perpendicular[ 0] * [oPix sliceThickness]/2.;
		slicePointO[ 1] = slicePoint[ 1] + perpendicular[ 1] * [oPix sliceThickness]/2.;
		slicePointO[ 2] = slicePoint[ 2] + perpendicular[ 2] * [oPix sliceThickness]/2.;
		
		slicePointI[ 0] = slicePoint[ 0] - perpendicular[ 0] * [oPix sliceThickness]/2.;
		slicePointI[ 1] = slicePoint[ 1] - perpendicular[ 1] * [oPix sliceThickness]/2.;
		slicePointI[ 2] = slicePoint[ 2] - perpendicular[ 2] * [oPix sliceThickness]/2.;
		
		temp[ 0] = slicePoint[ 0] * vectorB[ 0] + slicePoint[ 1] * vectorB[ 1] + slicePoint[ 2]*vectorB[ 2];
		temp[ 1] = slicePoint[ 0] * vectorB[ 3] + slicePoint[ 1] * vectorB[ 4] + slicePoint[ 2]*vectorB[ 5];
		temp[ 2] = slicePoint[ 0] * vectorB[ 6] + slicePoint[ 1] * vectorB[ 7] + slicePoint[ 2]*vectorB[ 8];
		slicePoint[ 0] = temp[ 0];	slicePoint[ 1] = temp[ 1];	slicePoint[ 2] = temp[ 2];
	
		slicePoint[ 0] /= [curDCM pixelSpacingX];
		slicePoint[ 1] /= [curDCM pixelSpacingY];
		slicePoint[ 0] -= [curDCM pwidth]/2.;
		slicePoint[ 1] -= [curDCM pheight]/2.;
		
		temp[ 0] = slicePointO[ 0] * vectorB[ 0] + slicePointO[ 1] * vectorB[ 1] + slicePointO[ 2]*vectorB[ 2];
		temp[ 1] = slicePointO[ 0] * vectorB[ 3] + slicePointO[ 1] * vectorB[ 4] + slicePointO[ 2]*vectorB[ 5];
		temp[ 2] = slicePointO[ 0] * vectorB[ 6] + slicePointO[ 1] * vectorB[ 7] + slicePointO[ 2]*vectorB[ 8];
		slicePointO[ 0] = temp[ 0];	slicePointO[ 1] = temp[ 1];	slicePointO[ 2] = temp[ 2];
		slicePointO[ 0] /= [curDCM pixelSpacingX];
		slicePointO[ 1] /= [curDCM pixelSpacingY];
		slicePointO[ 0] -= [curDCM pwidth]/2.;
		slicePointO[ 1] -= [curDCM pheight]/2.;
		
		temp[ 0] = slicePointI[ 0] * vectorB[ 0] + slicePointI[ 1] * vectorB[ 1] + slicePointI[ 2]*vectorB[ 2];
		temp[ 1] = slicePointI[ 0] * vectorB[ 3] + slicePointI[ 1] * vectorB[ 4] + slicePointI[ 2]*vectorB[ 5];
		temp[ 2] = slicePointI[ 0] * vectorB[ 6] + slicePointI[ 1] * vectorB[ 7] + slicePointI[ 2]*vectorB[ 8];
		slicePointI[ 0] = temp[ 0];	slicePointI[ 1] = temp[ 1];	slicePointI[ 2] = temp[ 2];
		slicePointI[ 0] /= [curDCM pixelSpacingX];
		slicePointI[ 1] /= [curDCM pixelSpacingY];
		slicePointI[ 0] -= [curDCM pwidth]/2.;
		slicePointI[ 1] -= [curDCM pheight]/2.;
	}
	else
	{
		sliceVector[0] = sliceVector[1] = sliceVector[2] = 0; 
		slicePoint[0] = slicePoint[1] = slicePoint[2] = 0; 
	}
	
	if( oPix2)
	{
		if( intersect3D_2Planes( vectorA2+6, originA2, vectorB+6, originB, sliceVector2, slicePoint2) == noErr)
		{
			float perpendicular[ 3], temp[ 3];
			
			CROSS( perpendicular, sliceVector2, (vectorB + 6));
			
			// Now reoriente this 3D line in our plane!
			
			temp[ 0] = sliceVector2[ 0] * vectorB[ 0] + sliceVector2[ 1] * vectorB[ 1] + sliceVector2[ 2] * vectorB[ 2];
			temp[ 1] = sliceVector2[ 0] * vectorB[ 3] + sliceVector2[ 1] * vectorB[ 4] + sliceVector2[ 2] * vectorB[ 5];
			temp[ 2] = sliceVector2[ 0] * vectorB[ 6] + sliceVector2[ 1] * vectorB[ 7] + sliceVector2[ 2] * vectorB[ 8];
			sliceVector2[ 0] = temp[ 0];
			sliceVector2[ 1] = temp[ 1];
			sliceVector2[ 2] = temp[ 2];
			
			slicePoint2[ 0] -= [curDCM originX];
			slicePoint2[ 1] -= [curDCM originY];
			slicePoint2[ 2] -= [curDCM originZ];
			
			slicePoint2[ 0] += perpendicular[ 0] * [oPix2 sliceThickness]/2.;
			slicePoint2[ 1] += perpendicular[ 1] * [oPix2 sliceThickness]/2.;
			slicePoint2[ 2] += perpendicular[ 2] * [oPix2 sliceThickness]/2.;
			
			slicePointO2[ 0] = slicePoint2[ 0] + perpendicular[ 0] * [oPix2 sliceThickness]/2.;
			slicePointO2[ 1] = slicePoint2[ 1] + perpendicular[ 1] * [oPix2 sliceThickness]/2.;
			slicePointO2[ 2] = slicePoint2[ 2] + perpendicular[ 2] * [oPix2 sliceThickness]/2.;
			
			slicePointI2[ 0] = slicePoint2[ 0] - perpendicular[ 0] * [oPix2 sliceThickness]/2.;
			slicePointI2[ 1] = slicePoint2[ 1] - perpendicular[ 1] * [oPix2 sliceThickness]/2.;
			slicePointI2[ 2] = slicePoint2[ 2] - perpendicular[ 2] * [oPix2 sliceThickness]/2.;
			
			temp[ 0] = slicePoint2[ 0] * vectorB[ 0] + slicePoint2[ 1] * vectorB[ 1] + slicePoint2[ 2]*vectorB[ 2];
			temp[ 1] = slicePoint2[ 0] * vectorB[ 3] + slicePoint2[ 1] * vectorB[ 4] + slicePoint2[ 2]*vectorB[ 5];
			temp[ 2] = slicePoint2[ 0] * vectorB[ 6] + slicePoint2[ 1] * vectorB[ 7] + slicePoint2[ 2]*vectorB[ 8];
			slicePoint2[ 0] = temp[ 0];	slicePoint2[ 1] = temp[ 1];	slicePoint2[ 2] = temp[ 2];
		
			slicePoint2[ 0] /= [curDCM pixelSpacingX];
			slicePoint2[ 1] /= [curDCM pixelSpacingY];
			slicePoint2[ 0] -= [curDCM pwidth]/2.;
			slicePoint2[ 1] -= [curDCM pheight]/2.;
			
			temp[ 0] = slicePointO2[ 0] * vectorB[ 0] + slicePointO2[ 1] * vectorB[ 1] + slicePointO2[ 2]*vectorB[ 2];
			temp[ 1] = slicePointO2[ 0] * vectorB[ 3] + slicePointO2[ 1] * vectorB[ 4] + slicePointO2[ 2]*vectorB[ 5];
			temp[ 2] = slicePointO2[ 0] * vectorB[ 6] + slicePointO2[ 1] * vectorB[ 7] + slicePointO2[ 2]*vectorB[ 8];
			slicePointO2[ 0] = temp[ 0];	slicePointO2[ 1] = temp[ 1];	slicePointO2[ 2] = temp[ 2];
			slicePointO2[ 0] /= [curDCM pixelSpacingX];
			slicePointO2[ 1] /= [curDCM pixelSpacingY];
			slicePointO2[ 0] -= [curDCM pwidth]/2.;
			slicePointO2[ 1] -= [curDCM pheight]/2.;
			
			temp[ 0] = slicePointI2[ 0] * vectorB[ 0] + slicePointI2[ 1] * vectorB[ 1] + slicePointI2[ 2]*vectorB[ 2];
			temp[ 1] = slicePointI2[ 0] * vectorB[ 3] + slicePointI2[ 1] * vectorB[ 4] + slicePointI2[ 2]*vectorB[ 5];
			temp[ 2] = slicePointI2[ 0] * vectorB[ 6] + slicePointI2[ 1] * vectorB[ 7] + slicePointI2[ 2]*vectorB[ 8];
			slicePointI2[ 0] = temp[ 0];	slicePointI2[ 1] = temp[ 1];	slicePointI2[ 2] = temp[ 2];
			slicePointI2[ 0] /= [curDCM pixelSpacingX];
			slicePointI2[ 1] /= [curDCM pixelSpacingY];
			slicePointI2[ 0] -= [curDCM pwidth]/2.;
			slicePointI2[ 1] -= [curDCM pheight]/2.;
		}
		else
		{
			sliceVector2[0] = sliceVector2[1] = sliceVector2[2] = 0; 
			slicePoint2[0] = slicePoint2[1] = slicePoint2[2] = 0; 
		}
	}
	else
	{
		sliceVector2[0] = sliceVector2[1] = sliceVector2[2] = 0; 
		slicePoint2[0] = slicePoint2[1] = slicePoint2[2] = 0; 
	}
}

- (IBAction) alwaysSyncMenu:(id) sender
{
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"SAMESTUDY"] == NSOnState)
		[[NSUserDefaults standardUserDefaults] setInteger: NSOnState forKey:@"SAMESTUDY"];
	else [[NSUserDefaults standardUserDefaults] setInteger: NSOffState forKey:@"SAMESTUDY"];
}

-(void) doSyncronize:(NSNotification*)note
{
	syncOnLocationImpossible = NO;
	
	if (![[[note object] superview] isEqual:[self superview]] && [self is2DViewer])
	{
	BOOL	stringOK = NO;
	
	long prevImage = curImage;
	
//	if( stringID)
//	{
//		if( [stringID isEqualToString:@"Original"]) stringOK = YES;
//	}
//	
//	if( [[note object] stringID])
//	{
//		if( [[[note object] stringID] isEqualToString:@"Original"]) stringOK = YES;
//	}
//	
//	if( stringID == 0L && [[note object] stringID] == 0L) stringOK = YES;
	
	if( [[self window] isVisible] == NO)
	{
		NSLog(@"not visible...");
		return;
	}
	
    if( [note object] != self && isKeyView == YES && matrix == 0 && stringID == 0L && [[note object] stringID] == 0L && curImage > -1 )   //|| [[[note object] stringID] isEqualToString:@"Original"] == YES))   // Dont change the browser preview....
    {
        NSDictionary *instructions = [note userInfo];

        long		diff = [[instructions valueForKey: @"Direction"] longValue];
        long		pos = [[instructions valueForKey: @"Pos"] longValue];
		float		loc = [[instructions valueForKey: @"Location"] floatValue];
		float		offsetsync = [[instructions valueForKey: @"offsetsync"] floatValue];
		NSString	*oStudyId = [instructions valueForKey: @"studyID"];
		DCMPix		*oPix = [instructions valueForKey: @"DCMPix"];
		DCMPix		*oPix2 = [instructions valueForKey: @"DCMPix2"];
		DCMView		*otherView = [instructions valueForKey: @"view"];
		long		stack = [oPix stack];
		float		destPoint3D[ 3];
		BOOL		point3D = NO;
		
		if( [instructions valueForKey: @"offsetsync"] == 0L) { NSLog(@"err offsetsync");	return;}
		
		if( [instructions valueForKey: @"view"] == 0L) { NSLog(@"err view");	return;}
		
		if( [instructions valueForKey: @"point3DX"])
		{
			destPoint3D[ 0] = [[instructions valueForKey: @"point3DX"] floatValue];
			destPoint3D[ 1] = [[instructions valueForKey: @"point3DY"] floatValue];
			destPoint3D[ 2] = [[instructions valueForKey: @"point3DZ"] floatValue];
			
			point3D = YES;
		}
		
		if( [oStudyId isEqualToString:[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.studyInstanceUID"]] || [[NSUserDefaults standardUserDefaults] boolForKey:@"SAMESTUDY"] == NO || syncSeriesIndex != -1)  // We received a message from the keyWindow -> display the slice cut to our window!
		{
			if( [oStudyId isEqualToString:[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.studyInstanceUID"]])
			{
				if( [oStudyId isEqualToString:[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.studyInstanceUID"]])
				{
					[self computeSlice: oPix :oPix2];
				}
				else
				{
					sliceVector2[0] = sliceVector2[1] = sliceVector2[2] = 0; 
					slicePoint2[0] = slicePoint2[1] = slicePoint2[2] = 0; 
				}
				
				// Double-Click -> find the nearest point on our plane, go to this plane and draw the intersection!
				if( point3D)
				{
					float	resultPoint[ 3];
					
					long newIndex = [self findPlaneAndPoint: destPoint3D :resultPoint];
					
					if( newIndex != -1)
					{
						curImage = newIndex;
						
						slicePoint3D[ 0] = resultPoint[ 0];
						slicePoint3D[ 1] = resultPoint[ 1];
						slicePoint3D[ 2] = resultPoint[ 2];
					}
					else
					{
						slicePoint3D[ 0] = 0;
						slicePoint3D[ 1] = 0;
						slicePoint3D[ 2] = 0;
					}
				}
				else
				{
					slicePoint3D[ 0] = 0;
					slicePoint3D[ 1] = 0;
					slicePoint3D[ 2] = 0;
				}
			}
			
			// Absolute Vodka
			if( syncro == syncroABS && point3D == NO && syncSeriesIndex == -1)
			{
				if( flippedData) curImage = [dcmPixList count] -1 -pos;
				else curImage = pos;
				
				//NSLog(@"Abs");
				
				if( curImage >= [dcmPixList count]) curImage = [dcmPixList count] - 1;
				if( curImage < 0) curImage = 0;
			}
			
			// Based on Location
			if( (syncro == syncroLOC && point3D == NO) || syncSeriesIndex != -1)
			{
				if( volumicSeries == YES && [otherView volumicSeries] == YES)
				{
					if( [[self windowController] orthogonalOrientation] == [[otherView windowController] orthogonalOrientation])
					{
						if( (sliceVector[0] == 0 && sliceVector[1] == 0 && sliceVector[2] == 0) || syncSeriesIndex != -1)  // Planes are parallel !
						{
							BOOL	noSlicePosition, everythingLoaded = YES;
							float   firstSliceLocation;
							long	index, i;
							float   smallestdiff = -1, fdiff, slicePosition;
							
							everythingLoaded = [[self windowController] isEverythingLoaded];
							
							noSlicePosition = NO;
							
							if( everythingLoaded) firstSliceLocation = [[dcmPixList objectAtIndex: 0] sliceLocation];
							else firstSliceLocation = [[[dcmFilesList objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue];
							
							for( i = 0; i < [dcmFilesList count]; i++)
							{
								if( everythingLoaded) slicePosition = [[dcmPixList objectAtIndex: i] sliceLocation];
								else slicePosition = [[[dcmFilesList objectAtIndex: i] valueForKey:@"sliceLocation"] floatValue];
								
								fdiff = slicePosition - loc;
								
								if( [oStudyId isEqualToString:[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.studyInstanceUID"]] == NO || syncSeriesIndex != -1)
								{						
									if( [otherView syncSeriesIndex] != -1)
									{
										slicePosition -= [[dcmPixList objectAtIndex: syncSeriesIndex] sliceLocation];
										
										fdiff = slicePosition - (loc - [[[otherView dcmPixList] objectAtIndex: [otherView syncSeriesIndex]] sliceLocation]);
									}
									else if( [[NSUserDefaults standardUserDefaults] boolForKey:@"SAMESTUDY"] ) noSlicePosition = YES;
								}
								
								if( fdiff < 0) fdiff = -fdiff;
								
								if( fdiff < smallestdiff || smallestdiff == -1)
								{
									smallestdiff = fdiff;
									index = i;
								}
							}
							
							if( noSlicePosition == NO)
							{
								curImage = index;
								
								if( [dcmPixList count] > 1)
								{
									float sliceDistance = fabs( [[dcmPixList objectAtIndex: 1] sliceLocation] - [[dcmPixList objectAtIndex: 0] sliceLocation]);
									
									if( fabs( smallestdiff) > sliceDistance * 2)
										syncOnLocationImpossible = YES;
								}
								
								if( curImage >= [dcmFilesList count]) curImage = [dcmFilesList count]-1;
								if( curImage < 0) curImage = 0;
							}
						}
					}
				}
				else if( volumicSeries == NO && [otherView volumicSeries] == NO)	// For example time or functional series
				{
					if( flippedData) curImage = [dcmPixList count] -1 -pos;
					else curImage = pos;
					
					//NSLog(@"Not volumic...");
					
					if( curImage >= [dcmPixList count]) curImage = [dcmPixList count] - 1;
					if( curImage < 0) curImage = 0;
				}
			}

			// Relative
			 if( syncro == syncroREL && point3D == NO && syncSeriesIndex == -1)
			 {
				if( flippedData) curImage -= diff;
				else curImage += diff;
				
				//NSLog(@"Rel");
				
				if( curImage < 0)
				{
					curImage += [dcmPixList count];
				}

				if( curImage >= [dcmPixList count]) curImage -= [dcmPixList count];
			 }
			
			// Relatif
			if( curImage != prevImage)
			{
				if( listType == 'i') [self setIndex:curImage];
				else [self setIndexWithReset:curImage :YES];
			}
			
			if( [self is2DViewer] == YES)
				[[self windowController] adjustSlider];
			
			if( [oStudyId isEqualToString:[[dcmFilesList objectAtIndex:[self indexForPix:curImage]] valueForKeyPath:@"series.study.studyInstanceUID"]])
				{
					[self computeSlice: oPix :oPix2];
				}
				else
				{
					sliceVector2[0] = sliceVector2[1] = sliceVector2[2] = 0; 
					slicePoint2[0] = slicePoint2[1] = slicePoint2[2] = 0; 
				}
				
			[self setNeedsDisplay:YES];
		}
		else
		{
			sliceVector[0] = sliceVector[1] = sliceVector[2] = 0; 
			slicePoint[0] = slicePoint[1] = slicePoint[2] = 0;
			sliceVector2[0] = sliceVector2[1] = sliceVector2[2] = 0; 
			slicePoint2[0] = slicePoint2[1] = slicePoint2[2] = 0; 
		}
    }
	}
}

-(void) roiSelected:(NSNotification*) note
{
	NSArray *winList = [[NSApplication sharedApplication] windows];
	long	i;
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROI"])
		{
			[[[winList objectAtIndex:i] windowController] setROI: [note object] :[self windowController]];
		}
	}
}

-(void) roiChange:(NSNotification*)note
{
	long i;
	
	// A ROI changed... do we display it? If yes, update!
	for( i = 0; i < [curRoiList count]; i++)
	{
		if( [curRoiList objectAtIndex:i] == [note object])
		{
			[[note object] setRoiFont:labelFontListGL :labelFontListGLSize :self];
			[self setNeedsDisplay:YES];
		}
	}
}

-(void) updateView:(NSNotification*)note
{
    [self setNeedsDisplay:YES];
}

-(void) barMenu:(id) sender
{
    NSMenu   *menu = [sender menu];
    short    i;
    
    i = [menu numberOfItems];
    while(i-- > 0) [[menu itemAtIndex:i] setState:NSOffState];   
    
	[[NSUserDefaults standardUserDefaults] setInteger: [sender tag] forKey: @"CLUTBARS"];

    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: @"updateView" object: self userInfo: nil];
}

-(void) annotMenu:(id) sender
{
	short chosenLine = [sender tag];

    NSMenu   *menu = [sender menu];
    short    i;
    
    i = [menu numberOfItems];
    while(i-- > 0) [[menu itemAtIndex:i] setState:NSOffState];   
    
	[[NSUserDefaults standardUserDefaults] setInteger: chosenLine forKey: @"ANNOTATIONS"];
    
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: @"updateView" object: self userInfo: nil];
}

-(void) syncronize:(id) sender
{
	[self setSyncro: [sender tag]];
}

-(void) setSyncro:(long) s
{
	[appController willChangeValueForKey:@"syncroOFF"];
	[appController willChangeValueForKey:@"syncroABS"];
	[appController willChangeValueForKey:@"syncroREL"];
	[appController willChangeValueForKey:@"syncroLOC"];
	
	syncro = s;
	
	[appController didChangeValueForKey:@"syncroOFF"];
	[appController didChangeValueForKey:@"syncroABS"];
	[appController didChangeValueForKey:@"syncroREL"];
	[appController didChangeValueForKey:@"syncroLOC"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"notificationSyncSeries" object:0L userInfo: 0L];
}

-(long) syncro
{
	return syncro;
}

-(void) FindMinimumOpenGLCapabilities
{
    GLint deviceMaxTextureSize = 0, NPOTDMaxTextureSize = 0;
    
    // init desired caps to max values
    f_ext_texture_rectangle = YES;
    f_arb_texture_rectangle = YES;
    f_ext_client_storage = YES;
    f_ext_packed_pixel = YES;
    f_ext_texture_edge_clamp = YES;
    f_gl_texture_edge_clamp = YES;
    maxTextureSize = 0x7FFFFFFF;
    maxNOPTDTextureSize = 0x7FFFFFFF;
    
    // get strings
    enum { kShortVersionLength = 32 };
    const GLubyte * strVersion = glGetString (GL_VERSION); // get version string
    const GLubyte * strExtension = glGetString (GL_EXTENSIONS);	// get extension string
    
    // get just the non-vendor specific part of version string
    GLubyte strShortVersion [kShortVersionLength];
    short i = 0;
    while ((((strVersion[i] <= '9') && (strVersion[i] >= '0')) || (strVersion[i] == '.')) && (i < kShortVersionLength)) // get only basic version info (until first space)
            strShortVersion [i] = strVersion[i++];
    strShortVersion [i] = 0; //truncate string
    
    // compare capabilities based on extension string and GL version
    f_ext_texture_rectangle = 
            f_ext_texture_rectangle && strstr ((const char *) strExtension, "GL_EXT_texture_rectangle");
    f_arb_texture_rectangle = 
            f_arb_texture_rectangle && strstr ((const char *) strExtension, "GL_ARB_texture_rectangle");
    f_ext_client_storage = 
            f_ext_client_storage && strstr ((const char *) strExtension, "GL_APPLE_client_storage");
    f_ext_packed_pixel = 
            f_ext_packed_pixel && strstr ((const char *) strExtension, "GL_APPLE_packed_pixel");
    f_ext_texture_edge_clamp = 
            f_ext_texture_edge_clamp && strstr ((const char *) strExtension, "GL_SGIS_texture_edge_clamp");
    f_gl_texture_edge_clamp = 
            f_gl_texture_edge_clamp && (!strstr ((const char *) strShortVersion, "1.0") && !strstr ((const char *) strShortVersion, "1.1")); // if not 1.0 and not 1.1 must be 1.2 or greater
    
    // get device max texture size
    glGetIntegerv (GL_MAX_TEXTURE_SIZE, &deviceMaxTextureSize);
    if (deviceMaxTextureSize < maxTextureSize)
            maxTextureSize = deviceMaxTextureSize;
    // get max size of non-power of two texture on devices which support
    if (NULL != strstr ((const char *) strExtension, "GL_EXT_texture_rectangle"))
    {
    #ifdef GL_MAX_RECTANGLE_TEXTURE_SIZE_EXT
            glGetIntegerv (GL_MAX_RECTANGLE_TEXTURE_SIZE_EXT, &NPOTDMaxTextureSize);
            if (NPOTDMaxTextureSize < maxNOPTDTextureSize)
                    maxNOPTDTextureSize = NPOTDMaxTextureSize;
	#endif
    }
	
//			maxTextureSize = 500;
	
    // set clamp param based on retrieved capabilities
    if (f_gl_texture_edge_clamp) // if OpenGL 1.2 or later and texture edge clamp is supported natively
                            edgeClampParam = GL_CLAMP_TO_EDGE;  // use 1.2+ constant to clamp texture coords so as to not sample the border color
    else if (f_ext_texture_edge_clamp) // if GL_SGIS_texture_edge_clamp extension supported
            edgeClampParam = GL_CLAMP_TO_EDGE_SGIS; // use extension to clamp texture coords so as to not sample the border color
    else
            edgeClampParam = GL_CLAMP; // clamp texture coords to [0, 1]
			
	if( f_arb_texture_rectangle && f_ext_texture_rectangle)
	{
//		NSLog(@"ARB Rectangular Texturing!");
		TEXTRECTMODE = GL_TEXTURE_RECTANGLE_ARB;
		maxTextureSize = maxNOPTDTextureSize;
	}
	else
	if( f_ext_texture_rectangle)
	{
//		NSLog(@"Rectangular Texturing!");
		TEXTRECTMODE = GL_TEXTURE_RECTANGLE_EXT;
		maxTextureSize = maxNOPTDTextureSize;
	}
	else
	{
		TEXTRECTMODE = GL_TEXTURE_2D;
	}
}

-(void) setCrossCoordinatesPer:(float) val
{
	cross.x -= val*cos(angle);
	cross.y -= val*sin(angle);
	
	[self setNeedsDisplay: YES];
}

-(void) getCrossCoordinates:(float*) x: (float*) y
{
	*x = cross.x;
	*y = -cross.y;
}

-(void) setCrossCoordinates:(float) x :(float) y :(BOOL) update
{
	cross.x =  x;
	cross.y = -y;
	
	[self setNeedsDisplay: YES];
	
	if( update)
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: stringID userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

-(void) setCross:(long) x :(long) y :(BOOL) update
{
	NSRect      size = [self frame];
    
	cross.x = x + size.size.width/2;
	cross.y = y + size.size.height/2;
	
	cross.y = size.size.height - cross.y ;
	cross = [self ConvertFromView2GL:cross];
	
	[self setNeedsDisplay:true];
	
	if( update)
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: stringID userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

-(void) setMPRAngle: (float) vectorMPR
{
	angle = vectorMPR;
	mprVector[ 0] = cos(vectorMPR*deg2rad);
	mprVector[ 1] = sin(vectorMPR*deg2rad);
				
	[self setNeedsDisplay:true];
}

-(float) angle { return angle;}

- (NSPoint) cross
{
	return cross;
}

- (NSPoint) crossPrev
{
	return crossPrev;
}

- (void) setCrossPrev:(NSPoint) c
{
	crossPrev = c;
}

-(void) cross3D:(float*) x :(float*) y :(float*) z 
{
	NSPoint cPt = cross;	//[self ConvertFromView2GL:cross];

//	cPt.x += [curDCM pwidth]/2.;
//	cPt.y += [curDCM pheight]/2.;
	
	if( x) *x = cPt.x * [[dcmPixList objectAtIndex:0] pixelSpacingX];
	if( y) *y = cPt.y * [[dcmPixList objectAtIndex:0] pixelSpacingY];
	
//	if( [curDCM sliceThickness] < 0) NSLog(@"thickness NEG");
	if( z) *z = curImage;  //* [curDCM sliceThickness];
//	*z =  [curDCM sliceLocation];
	
	// Now convert this local point in a global 3D coordinate!
	
	float temp[ 3], vectorB[ 9];
	
//	*x += [curDCM originX];
//	*y += [curDCM originY];
//	*z += [curDCM originZ];

//	[curDCM orientation: vectorB];

//	temp[ 0] = *x * vectorB[ 0] + *y * vectorB[ 1] + *z * vectorB[ 2];
//	temp[ 1] = *x * vectorB[ 3] + *y * vectorB[ 4] + *z * vectorB[ 5];
//	temp[ 2] = *x * vectorB[ 6] + *y * vectorB[ 7] + *z * vectorB[ 8];
//	
//	*x = temp[ 0];
//	*y = temp[ 1];
//	*z = temp[ 2];
	
//	*x =  temp[ 0];
//	*y =  temp[ 1];
//	*z =  temp[ 2];

//	*x -= [curDCM originX];
//	*y -= [curDCM originY];
//	*z -= [curDCM originZ];
	
//	NSLog(@"3D Pt: X=%0.0f Y=%0.0f Z=%0.0f", *x, *y, *z);

}

-(NSPoint) rotatePoint:(NSPoint) a
{
    float xx, yy;
    NSRect size = [self frame];
    
	if( xFlipped) a.x = size.size.width - a.x;
	if( yFlipped) a.y = size.size.height - a.y;
	
    a.x -= size.size.width/2;
//    a.x /= scaleValue;
	
    a.y -= size.size.height/2;
  //  a.y /= scaleValue;
    
    xx = a.x*cos(rotation*deg2rad) + a.y*sin(rotation*deg2rad);
    yy = -a.x*sin(rotation*deg2rad) + a.y*cos(rotation*deg2rad);
    
    a.y = yy;
    a.x = xx;

    a.x -= (origin.x + originOffset.x);
    a.y += (origin.y + originOffset.y);

	a.x += [curDCM pwidth]/2.;
	a.y += [curDCM pheight]/ 2.;
	
    return a;
}

-(NSPoint) ConvertFromGL2View:(NSPoint) a
{
    float xx, yy;
    NSRect size = [self frame];
	
	if( curDCM)
	{
		a.y *= [curDCM pixelRatio];
		a.y -= [curDCM pheight]*[curDCM pixelRatio]/ 2.;
		a.x -= [curDCM pwidth]/2.;
	}
	
	a.y -= (origin.y + originOffset.y)/scaleValue;
	a.x += (origin.x + originOffset.x)/scaleValue;

    xx = a.x*cos(-rotation*deg2rad) + a.y*sin(-rotation*deg2rad);
    yy = -a.x*sin(-rotation*deg2rad) + a.y*cos(-rotation*deg2rad);

    a.y = yy;
    a.x = xx;

    a.y *= scaleValue;
	a.y += size.size.height/2;
	
    a.x *= scaleValue;
	a.x += size.size.width/2;
	
	if( xFlipped) a.x = size.size.width - a.x;
	if( yFlipped) a.y = size.size.height - a.y;
	
	a.x -= size.size.width/2;
	a.y -= size.size.height/2;
	
    return a;
}

-(NSPoint) ConvertFromView2GL:(NSPoint) a
{
    float xx, yy;
    NSRect size = [self frame];
    
	if( xFlipped) a.x = size.size.width - a.x;
	if( yFlipped) a.y = size.size.height - a.y;
	
    a.x -= size.size.width/2;
    a.x /= scaleValue;
	
    a.y -= size.size.height/2;
    a.y /= scaleValue;
    
    xx = a.x*cos(rotation*deg2rad) + a.y*sin(rotation*deg2rad);
    yy = -a.x*sin(rotation*deg2rad) + a.y*cos(rotation*deg2rad);
    
    a.y = yy;
    a.x = xx;

    a.x -= (origin.x + originOffset.x)/scaleValue;
    a.y += (origin.y + originOffset.y)/scaleValue;
    
	if( curDCM)
	{
		a.x += [curDCM pwidth]/2.;
		a.y += [curDCM pheight]*[curDCM pixelRatio]/ 2.;
		a.y /= [curDCM pixelRatio];
    }
    return a;
}

- (void) setQuartzExtreme:(BOOL) set
{
	if( set != QuartzExtreme)
	{
		QuartzExtreme = set;
		
		if( QuartzExtreme)		// ACTIVATE
		{
			long negativeOne = -1;
			[[self openGLContext] setValues:&negativeOne forParameter:NSOpenGLCPSurfaceOrder];
			[[self window] setOpaque:NO];
			[[self window] setAlphaValue:.999f];
		}
		else					// DE-ACTIVATE
		{
			long negativeOne = 1;
			[[self openGLContext] setValues:&negativeOne forParameter:NSOpenGLCPSurfaceOrder];
			[[self window] setOpaque:YES];
			[[self window] setAlphaValue:1.0f];
		}
	}
}

- (void) drawRectIn:(NSRect) size :(GLuint *) texture :(NSPoint) offset :(long) tX :(long) tY
{
	if( mainThread != [NSThread currentThread])
	{
		NSLog(@"Warning! OpenGL activity NOT in the main thread???");
	}
	
	long effectiveTextureMod = 0; // texture size modification (inset) to account for borders
	long x, y, k = 0, offsetY, offsetX = 0, currTextureWidth, currTextureHeight;

    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity ();
	
	glDepthMask (GL_TRUE);
	
	glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f); // scale to port per pixel scale
	glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
	glTranslatef( origin.x - offset.x + originOffset.x, -origin.y - offset.y - originOffset.y, 0.0f);

	if( [curDCM pixelRatio] != 1.0) glScalef( 1.f, [curDCM pixelRatio], 1.f);
	
	effectiveTextureMod = 0;	//2;	//OVERLAP
	
	glEnable (TEXTRECTMODE); // enable texturing
	glColor4f (1.0f, 1.0f, 1.0f, 1.0f); 

	for (x = 0; x < tX; x++) // for all horizontal textures
	{
			// use remaining to determine next texture size
			currTextureWidth = GetNextTextureSize (textureWidth - offsetX, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // current effective texture width for drawing
			offsetY = 0; // start at top
			for (y = 0; y < tY; y++) // for a complete column
			{
					// use remaining to determine next texture size
					currTextureHeight = GetNextTextureSize (textureHeight - offsetY, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // effective texture height for drawing
					glBindTexture(TEXTRECTMODE, texture[k++]); // work through textures in same order as stored, setting each texture name as current in turn
					DrawGLImageTile (GL_TRIANGLE_STRIP, [curDCM pwidth], [curDCM pheight], (scaleValue),		//
										currTextureWidth, currTextureHeight, // draw this single texture on two tris 
										offsetX,  offsetY, 
										currTextureWidth + offsetX, 
										currTextureHeight + offsetY, 
										false, f_ext_texture_rectangle);		// OVERLAP
					offsetY += currTextureHeight; // offset drawing position for next texture vertically
			}
			offsetX += currTextureWidth; // offset drawing position for next texture horizontally
	}
	
    glDisable (TEXTRECTMODE); // done with texturing
}

-(float) pixelSpacing
{
	return [curDCM pixelSpacingX];
}

- (float) pixelSpacingX
{
	return [curDCM pixelSpacingX];
}

- (float) pixelSpacingY
{
	return [curDCM pixelSpacingY];
}

- (DCMPix*) curDCM { return curDCM;}

- (void) getOrientationText:(char *) orientation : (float *) vector :(BOOL) inv
{
	char orientationX;
	char orientationY;
	char orientationZ;

	char *optr = orientation;
	*optr = 0;
	
	if( inv)
	{
		orientationX = -vector[ 0] < 0 ? 'R' : 'L';
		orientationY = -vector[ 1] < 0 ? 'A' : 'P';
		orientationZ = -vector[ 2] < 0 ? 'I' : 'S';
		//orientationZ = -vector[ 2] < 0 ? 'F' : 'H';
	}
	else
	{
		orientationX = vector[ 0] < 0 ? 'R' : 'L';
		orientationY = vector[ 1] < 0 ? 'A' : 'P';
		orientationZ = vector[ 2] < 0 ? 'I' : 'S';
		//orientationZ = vector[ 2] < 0 ? 'F' : 'H';
	}
	
	float absX = fabs( vector[ 0]);
	float absY = fabs( vector[ 1]);
	float absZ = fabs( vector[ 2]);
	
	int i; 
	// get first 3 AXIS
	for (i=0; i < 3; ++i)
	{
		if (absX>.2 && absX>absY && absX>absZ)
		{
			*optr++=orientationX; absX=0;
		}
		else if (absY>.2 && absY>absX && absY>absZ)
		{
			*optr++=orientationY; absY=0;
		} else if (absZ>.2 && absZ>absX && absZ>absY)
		{
			*optr++=orientationZ; absZ=0;
		} else break; *optr='\0';
	}
}

//- (void) drawRect:(NSRect)aRect
//{
//	long i;
//    [[self openGLContext] makeCurrentContext];
//		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//			// init GL stuff here
//	glEnable(GL_DEPTH_TEST);
//
//	glShadeModel(GL_SMOOTH);    
//	glEnable(GL_CULL_FACE);
//	glFrontFace(GL_CCW);
//	glPolygonOffset (1.0f, 1.0f);
//	
//	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
//
//			for( i = 0; i < [curRoiList count]; i++)
//		{
//			[[curRoiList objectAtIndex:i] drawROI: scaleValue :[curDCM pwidth]/2. :[curDCM pheight]/2. :[curDCM pixelSpacingX]];
//		}
//		
//	[[self openGLContext] flushBuffer];
//}

-(void) setSlab:(float)s
{
	slab = s;
	
	[self setNeedsDisplay:true];
}

// Copyright 2001, softSurfer (www.softsurfer.com)
// This code may be freely used and modified for any purpose
// providing that this copyright notice is included with it.
// SoftSurfer makes no warranty for this code, and cannot be held
// liable for any real or imagined damage resulting from its use.
// Users of this code must verify correctness for their application.

// Assume that classes are already given for the objects:
//    Point and Vector with
//        coordinates {float x, y, z;}
//        operators for:
//            Point  = Point ± Vector
//            Vector = Point - Point
//            Vector = Scalar * Vector    (scalar product)
//    Plane with a point and a normal {Point V0; Vector n;}
//===================================================================

// dot product (3D) which allows vector operations in arguments

#define dot(u,v)   ((u)[0] * (v)[0] + (u)[1] * (v)[1] + (u)[2] * (v)[2])
#define norm(v)    sqrt(dot(v,v))  // norm = length of vector
#define d(u,v)     norm(u-v)       // distance = norm of difference

// pbase_Plane(): get base of perpendicular from point to a plane
//    Input:  P = a 3D point
//            PL = a plane with point V0 and normal n
//    Output: *B = base point on PL of perpendicular from P
//    Return: the distance from P to the plane PL

- (float) pbase_Plane: (float*) point :(float*) planeOrigin :(float*) planeVector :(float*) pointProjection
{
    float	sb, sn, sd;
	float	sub[ 3];
	
	sub[ 0] = point[ 0] - planeOrigin[ 0];
	sub[ 1] = point[ 1] - planeOrigin[ 1];
	sub[ 2] = point[ 2] - planeOrigin[ 2];
	
    sn = -dot( planeVector, sub);
    sd = dot( planeVector, planeVector);
    sb = sn / sd;
	
	pointProjection[ 0] = point[ 0] + sb * planeVector[ 0];
	pointProjection[ 1] = point[ 1] + sb * planeVector[ 1];
	pointProjection[ 2] = point[ 2] + sb * planeVector[ 2];
	
	sub[ 0] = point[ 0] - pointProjection[ 0];
	sub[ 1] = point[ 1] - pointProjection[ 1];
	sub[ 2] = point[ 2] - pointProjection[ 2];

    return norm( sub);
}
//===================================================================

- (long) findPlaneAndPoint:(float*) pt :(float*) location
{
	long	i, ii = -1;
	float	vectors[ 9], orig[ 3], locationTemp[ 3];
	float	distance = 999999, tempDistance;
	
	for( i = 0; i < [dcmPixList count]; i++)
	{
		[[dcmPixList objectAtIndex: i] orientation: vectors];
		
		orig[ 0] = [[dcmPixList objectAtIndex: i] originX];
		orig[ 1] = [[dcmPixList objectAtIndex: i] originY];
		orig[ 2] = [[dcmPixList objectAtIndex: i] originZ];
		
		tempDistance = [self pbase_Plane: pt :orig :&(vectors[ 6]) :locationTemp];
		
		if( tempDistance < distance)
		{
			location[ 0] = locationTemp[ 0];
			location[ 1] = locationTemp[ 1];
			location[ 2] = locationTemp[ 2];
			distance = tempDistance;
			ii = i;
		}
	}
	
	if( ii != -1)
	{
		NSLog(@"Distance: %2.2f, Index: %d", distance, ii);
		
		if( distance > [curDCM sliceThickness] * 2) ii = -1;
	}
	
	return ii;
}

- (void) drawOrientation:(NSRect) size
{
	// Determine Anterior, Posterior, Left, Right, Head, Foot
	char	string[ 10];
	float   vectors[ 9];
	
	[self orientationCorrectedToView: vectors];
	// Left
	[self getOrientationText:string :vectors :YES];
	[self DrawCStringGL: string : labelFontListGL :6 :2+size.size.height/2];
	// Right
	float offset = 28;
	[self getOrientationText:string :vectors :NO];

	// Vary Position of Right string depending on length
	if (strlen(string) == 1)
		offset = 16;
	else if (strlen(string) == 2)
		offset = 22;
	[self DrawCStringGL: string : labelFontListGL :size.size.width - offset :2+size.size.height/2];
	//Top 
	[self getOrientationText:string :vectors+3 :YES];
	[self DrawCStringGL: string : labelFontListGL :size.size.width/2 :15];
	
	if( [curDCM laterality]) [self DrawNSStringGL: [curDCM laterality] : fontListGL :size.size.width/2 :12 + stringSize.height];
	//Bottom
	[self getOrientationText:string :vectors+3 :NO];
	[self DrawCStringGL: string : labelFontListGL :size.size.width/2 :2+size.size.height - 6];
}

-(void) getThickSlabThickness:(float*) thickness location:(float*) location
{
	*thickness = [curDCM sliceThickness];
	*location = [curDCM sliceLocation];
	
	if( [curDCM sliceThickness] != 0 && [curDCM sliceLocation] != 0)
	{
		if( [curDCM stack] > 1)
		{
			long maxVal;
			
			if( flippedData) maxVal = curImage-[curDCM stack];
			else maxVal = curImage+[curDCM stack];
			
			if( maxVal < 0) maxVal = curImage;
			else if( maxVal > [dcmPixList count]) maxVal = [dcmPixList count] - curImage;
			else maxVal = [curDCM stack];
			
			float vv = fabs( (maxVal-1) * [[dcmPixList objectAtIndex:0] sliceInterval]);
			
			vv += [curDCM sliceThickness];
			
			float pp;
			
			if( flippedData)
				pp = ([[dcmPixList objectAtIndex: curImage] sliceLocation] + [[dcmPixList objectAtIndex: curImage - maxVal+1] sliceLocation])/2.;
			else
				pp = ([[dcmPixList objectAtIndex: curImage] sliceLocation] + [[dcmPixList objectAtIndex: curImage + maxVal-1] sliceLocation])/2.;
				
			*thickness = vv;
			*location = pp;
		}
	}
}

- (void) drawTextualData:(NSRect) size :(long) annotations
{
	NSManagedObject   *file;
	file = [dcmFilesList objectAtIndex:[self indexForPix:curImage]];
	
		
	//** TEXT INFORMATION
	glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
	glScalef (2.0f / size.size.width, -2.0f /  size.size.height, 1.0f); // scale to port per pixel scale
	glTranslatef (-(size.size.width) / 2.0f, -(size.size.height) / 2.0f, 0.0f); // translate center to upper left
	
	//draw line around edge for key Images only in 2D Viewer
	
	if ([[self windowController] isMemberOfClass:[ViewerController class]] && [[self windowController] isKeyImage:curImage] && stringID == 0L) {
		glLineWidth(8.0);
		glColor3f (1.0f, 1.0f, 0.0f);
		glBegin(GL_LINE_LOOP);
			glVertex2f(0.0,                                      0.0);
			glVertex2f(0.0,                   size.size.height - 0.0);
			glVertex2f(size.size.width - 0.0, size.size.height - 0.0);
			glVertex2f(size.size.width - 0.0,                    0.0);
		glEnd();
	}
		
	
	glColor3f (0.0f, 0.0f, 0.0f);
//	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glLineWidth(1.0);
	
	
	if (annotations == 4) [[NSNotificationCenter defaultCenter] postNotificationName: @"PLUGINdrawTextInfo" object: self];
	else //none, base, noName, full annotation
	{
		NSString	*tempString;
		long		yRaster = 1, xRaster;
		BOOL		fullText = YES;

		
		if( stringID && [stringID isEqualToString:@"OrthogonalMPRVIEW"] == YES)
		{
			fullText = NO;
			
			if( isKeyView == NO)
			{
				[self drawOrientation:size];
				return;
			}
		}
		
		if( fullText)
		{
			tempString = [NSString stringWithFormat: @"Image size: %ld x %ld", (long) [curDCM pwidth], (long) [curDCM pheight]];
			[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height rightAlignment: NO useStringTexture: YES];
			
			tempString = [NSString stringWithFormat: @"View size: %ld x %ld", (long) size.size.width, (long) size.size.height];
			[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height];
		}
		
		if( mouseXPos != 0 && mouseYPos != 0)
		{
			if( [curDCM isRGB]) tempString = [NSString stringWithFormat: @"X: %d px Y: %d px Value: R:%ld G:%ld B:%ld", (int)mouseXPos, (int)mouseYPos, pixelMouseValueR, pixelMouseValueG, pixelMouseValueB];
			else tempString = [NSString stringWithFormat: @"X: %d px Y: %d px Value: %2.2f", (int)mouseXPos, (int)mouseYPos, pixelMouseValue];
			[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height];
			
			if( blendingView)
			{
				if( [[blendingView curDCM] isRGB]) tempString = [NSString stringWithFormat: @"Fused Image : X: %d px Y: %d px Value: R:%ld G:%ld B:%ld", (int)blendingMouseXPos, (int)blendingMouseYPos, blendingPixelMouseValueR, blendingPixelMouseValueG, blendingPixelMouseValueB];
				else tempString = [NSString stringWithFormat: @"Fused Image : X: %d px Y: %d px Value: %2.2f", (int)blendingMouseXPos, (int)blendingMouseYPos, blendingPixelMouseValue];
				[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height];
			}
			
			if( [curDCM displaySUVValue])
			{
				if( [curDCM hasSUV] == YES && [curDCM SUVConverted] == NO)
				{
					tempString = [NSString stringWithFormat: @"SUV: %.2f", [self getSUV]];
					[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height];
				}
			}
			
			if( blendingView)
			{
				if( [[blendingView curDCM] displaySUVValue] && [[blendingView curDCM] hasSUV] && [[blendingView curDCM] SUVConverted] == NO)
				{
					tempString = [NSString stringWithFormat: @"SUV (fused image): %.2f", [self getBlendedSUV]];
					[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height];
				}
			}
		}
		
		float	lwl, lww;
		
	
		lwl = [curDCM wl];
		lww = [curDCM ww];
		
	//	if( fullText)
		{
			if( lww < 50) tempString = [NSString stringWithFormat: @"WL: %0.4f WW: %0.4f", lwl, lww];
			else tempString = [NSString stringWithFormat: @"WL: %ld WW: %ld", (long) lwl, (long) lww];
			[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height];
			
			if( [[[dcmFilesList objectAtIndex: 0] valueForKey:@"modality"] isEqualToString:@"PT"]  == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"NM"] == YES))
			{
				if( [curDCM maxValueOfSeries])
				{
					float min = lwl - lww/2, max = lwl + lww/2;
					
					tempString = [NSString stringWithFormat: @"From: %d %% (%0.2f) to: %d %% (%0.2f)", (long) (min * 100. / [curDCM maxValueOfSeries]), lwl - lww/2, (long) (max * 100. / [curDCM maxValueOfSeries]), lwl + lww/2];
					[self DrawNSStringGL: tempString : fontListGL :4 :yRaster++ * stringSize.height];
				}
			}
			
		}		
		// Draw any additional plugin text information
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat: yRaster++ * stringSize.height], @"yPos", nil];
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"PLUGINdrawTextInfo"
																object: self
															  userInfo: userInfo];
		}
		
		
		// BOTTOM LEFT
		
		yRaster = size.size.height-2;
		
		if( stringID == 0L || [stringID isEqualToString:@"OrthogonalMPRVIEW"] || [stringID isEqualToString:@"FinalView"])
		{
			if( mouseXPos != 0 && mouseYPos != 0)
			{
				float location[ 3 ];
				
				if( [curDCM stack] > 1)
				{
					long maxVal;
				
					if( flippedData) maxVal = curImage-([curDCM stack]-1)/2;
					else maxVal = curImage+([curDCM stack]-1)/2;
					
					if( maxVal < 0) maxVal = 0;
					if( maxVal >= [dcmPixList count]) maxVal = [dcmPixList count]-1;
					
					[[dcmPixList objectAtIndex: maxVal] convertPixX: mouseXPos pixY: mouseYPos toDICOMCoords: location];
				}
				else
				{
					[curDCM convertPixX: mouseXPos pixY: mouseYPos toDICOMCoords: location];
				}
				
				if(fabs(location[0]) < 1.0 && location[0] != 0.0)
					tempString = [NSString stringWithFormat: @"X: %2.2f %cm Y: %2.2f %cm Z: %2.2f %cm", location[0] * 1000.0, 0xB5, location[1] * 1000.0, 0xB5, location[2] * 1000.0, 0xB5];
				else
					tempString = [NSString stringWithFormat: @"X: %2.2f mm Y: %2.2f mm Z: %2.2f mm", location[0], location[1], location[2]];
				
				[self DrawNSStringGL: tempString : fontListGL :4 :yRaster];
				yRaster -= stringSize.height;
			}
		}
		
		// Thickness
		if( [curDCM sliceThickness] != 0 && [curDCM sliceLocation] != 0)
		{
			if( [curDCM stack] > 1)
			{
				float vv, pp;
				
				[self getThickSlabThickness: &vv location: &pp];
				
				if( vv < 1.0 && vv != 0.0)
				{
					if( fabs( pp) < 1.0 && pp != 0.0)
						tempString = [NSString stringWithFormat: @"Thickness: %0.2f %cm Location: %0.2f %cm", fabs( vv * 1000.0), 0xB5, pp * 1000.0, 0xB5];
					else
						tempString = [NSString stringWithFormat: @"Thickness: %0.2f %cm Location: %0.2f mm", fabs( vv * 1000.0), 0xB5, pp];
				}
				else
					tempString = [NSString stringWithFormat: @"Thickness: %0.2f mm Location: %0.2f mm", fabs( vv), pp];
				
				[self DrawNSStringGL: tempString : fontListGL :4 :yRaster];
				yRaster -= stringSize.height;
			}
			else if( fullText)
			{
				if ([curDCM sliceThickness] < 1.0 && [curDCM sliceThickness] != 0.0)
				{
					if( fabs( [curDCM sliceLocation]) < 1.0 && [curDCM sliceLocation] != 0.0)
						tempString = [NSString stringWithFormat: @"Thickness: %0.2f %cm Location: %0.2f %cm", [curDCM sliceThickness] * 1000.0, 0xB5, [curDCM sliceLocation] * 1000.0, 0xB5];
					else
						tempString = [NSString stringWithFormat: @"Thickness: %0.2f %cm Location: %0.2f mm", [curDCM sliceThickness] * 1000.0, 0xB5, [curDCM sliceLocation]];
				}
				else
					tempString = [NSString stringWithFormat: @"Thickness: %0.2f mm Location: %0.2f mm", [curDCM sliceThickness], [curDCM sliceLocation]];
				
				[self DrawNSStringGL: tempString : fontListGL :4 :yRaster];
				yRaster -= stringSize.height;
			}
		} 
		else if( [curDCM viewPosition] || [curDCM patientPosition])	 
		{	 
			 NSString        *nsstring = 0L;	 

			 if( [curDCM viewPosition]) nsstring = [NSString stringWithFormat: @"Position: %@ ", [curDCM viewPosition]];	 
			 if( [curDCM patientPosition])	 
			 {	 
				if( nsstring) nsstring = [nsstring stringByAppendingString: [curDCM patientPosition]];	 
				else nsstring = [NSString stringWithFormat: @"Position: %@ ", [curDCM patientPosition]];	 
			 }	 

			 // Position
			 [self DrawNSStringGL: nsstring : fontListGL :4 :yRaster rightAlignment: NO useStringTexture: YES];
			 yRaster -= stringSize.height;	 
		}
		
		if( fullText)
		{
			// Zoom
			tempString = [NSString stringWithFormat: @"Zoom: %0.0f%% Angle: %0.0f", (float) scaleValue*100.0, (float) ((long) rotation % 360)];
			[self DrawNSStringGL: tempString : fontListGL :4 :yRaster];
			yRaster -= stringSize.height;
		}
		
		// Image Position
		
		if( [curDCM stack] > 1)
		{
			long maxVal;
			
			if( flippedData) maxVal = curImage-[curDCM stack]+1;
			else maxVal = curImage+[curDCM stack];
			
			if( maxVal < 0) maxVal = 0;
			if( maxVal > [dcmPixList count]) maxVal = [dcmPixList count];
			
			if( flippedData) tempString = [NSString stringWithFormat: @"Im: %ld-%ld/%ld", (long) [dcmPixList count] - curImage, [dcmPixList count] - maxVal, (long) [dcmPixList count]];
			else tempString = [NSString stringWithFormat: @"Im: %ld-%ld/%ld", (long) curImage+1, maxVal, (long) [dcmPixList count]];
			
			[self DrawNSStringGL: tempString : fontListGL :4 :yRaster];
			yRaster -= stringSize.height;
		} 
		else if( fullText)
		{
			if( flippedData) tempString = [NSString stringWithFormat: @"Im: %ld/%ld", (long) [dcmPixList count] - curImage, (long) [dcmPixList count]];
			else tempString = [NSString stringWithFormat: @"Im: %ld/%ld", (long) curImage+1, (long) [dcmPixList count]];
			
			[self DrawNSStringGL: tempString : fontListGL :4 :yRaster];
			yRaster -= stringSize.height;
		}
		
		[self drawOrientation: size];
		
		// More informations
		
		//yRaster = 1;
		yRaster = 0; //absolute value for yRaster;
		NSManagedObject   *file;

		file = [dcmFilesList objectAtIndex:[self indexForPix:curImage]];
		if( annotations >= annotBase && fullText)
		{
			if( annotations >= annotFull)
			{
				if( [file valueForKeyPath:@"series.study.name"])
				{
					NSString	*nsstring;
					
					if( [file valueForKeyPath:@"series.study.dateOfBirth"])
					{
						nsstring = [NSString stringWithFormat: @"%@ - %@ - %@",[file valueForKeyPath:@"series.study.name"], [[file valueForKeyPath:@"series.study.dateOfBirth"] descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary], yearOld];
					}
					else  nsstring = [file valueForKeyPath:@"series.study.name"];
					
					xRaster = size.size.width;
					[self DrawNSStringGL: nsstring : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
					yRaster += (stringSize.height + stringSize.height/10);
				}
			}
			else
			{
				if( [file valueForKeyPath:@"series.study.dateOfBirth"])
				{
					NSString *nsstring = [NSString stringWithFormat: @"%@ - %@",[[file valueForKeyPath:@"series.study.dateOfBirth"] descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary], yearOld];
					
					xRaster = size.size.width;
					[self DrawNSStringGL: nsstring : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
					yRaster += (stringSize.height + stringSize.height/10);
				}
			}
			
			if( [file valueForKeyPath:@"series.study.patientID"])
			{
				xRaster = size.size.width;
				[self DrawNSStringGL: [file valueForKeyPath:@"series.study.patientID"] : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
		} //annotations >= annotFull
		
		if( annotations >= annotBase && fullText)
		{
			if( [file valueForKeyPath:@"series.study.studyName"])
			{
				xRaster = size.size.width;
				[self DrawNSStringGL: [file valueForKeyPath:@"series.study.studyName"] : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
			if( [file valueForKeyPath:@"series.name"])
			{
				xRaster = size.size.width;
				[self DrawNSStringGL: [file valueForKeyPath:@"series.name"] : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
			if( [file valueForKeyPath:@"series.study.id"])
			{
				xRaster = size.size.width;		
				[self DrawNSStringGL: [file valueForKeyPath:@"series.study.id"] : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
			if( [file valueForKeyPath:@"series.id"])
			{
				xRaster = size.size.width;
				[self DrawNSStringGL: [[file valueForKeyPath:@"series.id"] stringValue] : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
			if( [curDCM echotime] != 0L &&  [curDCM repetitiontime] != 0L) 
			{
				float repetitiontime = [[curDCM repetitiontime] floatValue];
				float echotime = [[curDCM echotime] floatValue];
				tempString = [NSString stringWithFormat:@"TR: %.2f, TE: %.2f", repetitiontime, echotime];
				xRaster = size.size.width;// - ([self lengthOfString:cptr forFont:fontListGLSize] + 2);		
				[self DrawNSStringGL: tempString : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
			if( [curDCM flipAngle] != 0L)
			{
				float flipAngle = [[curDCM flipAngle] floatValue];
				tempString = [NSString stringWithFormat:@"Flip Angle: %.2f", flipAngle];
				xRaster = size.size.width;
				[self DrawNSStringGL: tempString : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
			if( [curDCM protocolName] != 0L)
			{
				xRaster = size.size.width;		
				[self DrawNSStringGL: [curDCM protocolName] : fontListGL :xRaster :yRaster + stringSize.height rightAlignment: YES useStringTexture: YES];
				yRaster += (stringSize.height + stringSize.height/10);
			}
			
			yRaster = size.size.height-2;
			xRaster = size.size.width;
			[self DrawNSStringGL: @"Made In OsiriX" : fontListGL :xRaster :yRaster rightAlignment: YES useStringTexture: YES];
			yRaster -= (stringSize.height + stringSize.height/10);
			
			NSCalendarDate  *date = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[file valueForKey:@"date"] timeIntervalSinceReferenceDate]];
			if( date && [date yearOfCommonEra] != 3000)
			{
				tempString = [date descriptionWithCalendarFormat: shortDateString];
				xRaster = size.size.width;	
				[self DrawNSStringGL: tempString : fontListGL :xRaster :yRaster rightAlignment: YES useStringTexture: YES];
				yRaster -= (stringSize.height + stringSize.height/10);
			}
			//yRaster -= 12;
			
			if( [curDCM acquisitionTime]) date = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[curDCM acquisitionTime] timeIntervalSinceReferenceDate]];
			if( date && [date yearOfCommonEra] != 3000)
			{
				tempString = [date descriptionWithCalendarFormat: [[NSUserDefaults standardUserDefaults] objectForKey: NSTimeFormatString]];	//	DDP localized from "%I:%M %p" 
				xRaster = size.size.width;
				[self DrawNSStringGL: tempString : fontListGL :xRaster :yRaster rightAlignment: YES useStringTexture: NO];
				yRaster -= (stringSize.height + stringSize.height/10);
			}
		}
	}
}

#pragma mark-
#pragma mark image transformation


- (void) applyImageTransformation
{
	NSSize size = [self frame].size;
	
	glLoadIdentity ();
	glViewport(0, 0, size.width, size.height);

	glScalef (2.0f /(xFlipped ? -(size.width) : size.width), -2.0f / (yFlipped ? -(size.height) : size.height), 1.0f);
	glRotatef (rotation, 0.0f, 0.0f, 1.0f);
	glTranslatef( origin.x + originOffset.x, -origin.y - originOffset.y, 0.0f);
	glScalef( 1.f, [curDCM pixelRatio], 1.f);
}

- (void) setDrawing:(BOOL) v
{
	drawing = v;
}

- (void) drawRect:(NSRect)aRect
{
	if( drawing == NO) return;
	
	@synchronized (self)
	{
		[self drawRect:(NSRect)aRect withContext: [self openGLContext]];
	}
}

- (void) drawRect:(NSRect)aRect withContext:(NSOpenGLContext *)ctx
{
	long		clutBars	= CLUTBARS;	//[[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	long		annotations	= ANNOTATIONS;	//[[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
	
	if( noScale)
	{
		//scaleValue = 1;
		[self setScaleValue:1];
		origin.x = 0;
		origin.y = 0;
	}
	
	if ( [NSGraphicsContext currentContextDrawingToScreen] )
	{
		NSPoint offset;
		
		offset.y = offset.x = 0;
		
		// Make this context current
		//[[self openGLContext] makeCurrentContext];
		
		[ctx makeCurrentContext];
		
		NSRect size;
		
		if( ctx == [self openGLContext]) size = [self frame];
		else size = aRect;
		
		glViewport (0, 0, size.size.width, size.size.height); // set the viewport to cover entire window
		
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear (GL_COLOR_BUFFER_BIT);
		
		if( dcmPixList && curImage > -1)
		{
			if( blendingView != 0L && syncOnLocationImpossible == NO)
			{
				glBlendFunc(GL_ONE, GL_ONE);
				glEnable( GL_BLEND);
			}
			else glDisable( GL_BLEND);
			
			[self drawRectIn:size :pTextureName :offset :textureX :textureY];
			
			if( blendingView != 0L && syncOnLocationImpossible == NO)
			{
				if( [curDCM pixelSpacingX] != 0 && [curDCM pixelSpacingY] != 0 &&  [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"] == YES)
				{
//					float vectorP[ 9], tempOrigin[ 3], tempOriginBlending[ 3];
//					
//					[curDCM orientation: vectorP];
//					
//					tempOrigin[ 0] = [curDCM originX] * vectorP[ 0] + [curDCM originY] * vectorP[ 1] + [curDCM originZ] * vectorP[ 2];
//					tempOrigin[ 1] = [curDCM originX] * vectorP[ 3] + [curDCM originY] * vectorP[ 4] + [curDCM originZ] * vectorP[ 5];
//					tempOrigin[ 2] = [curDCM originX] * vectorP[ 6] + [curDCM originY] * vectorP[ 7] + [curDCM originZ] * vectorP[ 8];
//					
//					tempOriginBlending[ 0] = [[blendingView curDCM] originX] * vectorP[ 0] + [[blendingView curDCM] originY] * vectorP[ 1] + [[blendingView curDCM] originZ] * vectorP[ 2];
//					tempOriginBlending[ 1] = [[blendingView curDCM] originX] * vectorP[ 3] + [[blendingView curDCM] originY] * vectorP[ 4] + [[blendingView curDCM] originZ] * vectorP[ 5];
//					tempOriginBlending[ 2] = [[blendingView curDCM] originX] * vectorP[ 6] + [[blendingView curDCM] originY] * vectorP[ 7] + [[blendingView curDCM] originZ] * vectorP[ 8];
//					
//					offset.x = (tempOrigin[0] + [curDCM pwidth]*[curDCM pixelSpacingX]/2. - (tempOriginBlending[ 0] + [[blendingView curDCM] pwidth]*[[blendingView curDCM] pixelSpacingX]/2.));
//					offset.y = (tempOrigin[1] + [curDCM pheight]*[curDCM pixelSpacingY]/2. - (tempOriginBlending[ 1] + [[blendingView curDCM] pheight]*[[blendingView curDCM] pixelSpacingY]/2.));
//					
//					offset.x *= scaleValue;
//					offset.x /= [curDCM pixelSpacingX];
//					
//					offset.y *= scaleValue;
//					offset.y /= [curDCM pixelSpacingY];
					
					offset.y = 0;
					offset.x = 0;
				}
				else
				{
					offset.y = 0;
					offset.x = 0;
				}
				
				//NSLog(@"offset:%f - %f", offset.x, offset.y);
				
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				
				if( blendingTextureName)
					[blendingView drawRectIn:size :blendingTextureName :offset :blendingTextureX :blendingTextureY];
				else
					NSLog( @"blendingTextureName == 0L");
				
				glDisable( GL_BLEND);
			}
			
			//** SLICE CUT FOR 2D MPR
			if( cross.x != -9999 && cross.y != -9999 && display2DMPRLines == YES)
			{
				glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
				glEnable(GL_BLEND);
				glEnable(GL_POINT_SMOOTH);
				glEnable(GL_LINE_SMOOTH);
				glEnable(GL_POLYGON_SMOOTH);
				
				if(( mprVector[ 0] != 0 || mprVector[ 1] != 0))
				{
					float tvec[ 2];
						
					tvec[ 0] = cos((angle+90)*deg2rad);
					tvec[ 1] = sin((angle+90)*deg2rad);

					glColor3f (0.0f, 0.0f, 1.0f);
					
						// Thick Slab
						if( slab > 1)
						{
							float crossx, crossy;
							float slabx, slaby;

							glLineWidth(1.0);
							glBegin(GL_LINES);
							
							crossx = cross.x-[curDCM pwidth]/2.;
							crossy = cross.y-[curDCM pheight]/2.;
							
							slabx = (slab/2.)/[curDCM pixelSpacingX]*tvec[ 0];
							slaby = (slab/2.)/[curDCM pixelSpacingY]*tvec[ 1];
							
							glVertex2f( scaleValue * (crossx - 1000*mprVector[ 0] - slabx), scaleValue*(crossy - 1000*mprVector[ 1] - slaby));
							glVertex2f( scaleValue * (crossx + 1000*mprVector[ 0] - slabx), scaleValue*(crossy + 1000*mprVector[ 1] - slaby));

							glVertex2f( scaleValue*(crossx - 1000*mprVector[ 0]), scaleValue*(crossy - 1000*mprVector[ 1]));
							glVertex2f( scaleValue*(crossx + 1000*mprVector[ 0]), scaleValue*(crossy + 1000*mprVector[ 1]));

							glVertex2f( scaleValue*(crossx - 1000*mprVector[ 0] + slabx), scaleValue*(crossy - 1000*mprVector[ 1] + slaby));
							glVertex2f( scaleValue*(crossx + 1000*mprVector[ 0] + slabx), scaleValue*(crossy + 1000*mprVector[ 1] + slaby));
						}
						else
						{
							float crossx, crossy;
							
							glLineWidth(2.0);
							glBegin(GL_LINES);

							crossx = cross.x-[curDCM pwidth]/2.;
							crossy = cross.y-[curDCM pheight]/2.;
							
							glVertex2f( scaleValue*(crossx - 1000*mprVector[ 0]), scaleValue*(crossy - 1000*mprVector[ 1]));
							glVertex2f( scaleValue*(crossx + 1000*mprVector[ 0]), scaleValue*(crossy + 1000*mprVector[ 1]));
						}
					glEnd();
					
					if( [stringID isEqualToString:@"Original"])
					{
						glColor3f (1.0f, 0.0f, 0.0f);
						glLineWidth(1.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(cross.x-[curDCM pwidth]/2. - 1000*tvec[ 0]), scaleValue*(cross.y-[curDCM pheight]/2. - 1000*tvec[ 1]));
							glVertex2f( scaleValue*(cross.x-[curDCM pwidth]/2. + 1000*tvec[ 0]), scaleValue*(cross.y-[curDCM pheight]/2. + 1000*tvec[ 1]));
						glEnd();
					}
				}

				NSPoint crossB = cross;

				crossB.x -= [curDCM pwidth]/2.;
				crossB.y -= [curDCM pheight]/2.;
				
				crossB.x *=scaleValue;
				crossB.y *=scaleValue;
				
				glColor3f (1.0f, 0.0f, 0.0f);
				
		//		if( [stringID isEqualToString:@"Perpendicular"])
		//		{
		//			glLineWidth(2.0);
		//			glBegin(GL_LINES);
		//				glVertex2f( crossB.x-BS, crossB.y);
		//				glVertex2f(  crossB.x+BS, crossB.y);
		//				
		//				glVertex2f( crossB.x, crossB.y-BS);
		//				glVertex2f(  crossB.x, crossB.y+BS);
		//			glEnd();
		//		}
		//		else
				{
					glLineWidth(2.0);
//					glBegin(GL_LINE_LOOP);
//						glVertex2f( crossB.x-BS, crossB.y-BS);
//						glVertex2f( crossB.x+BS, crossB.y-BS);
//						glVertex2f( crossB.x+BS, crossB.y+BS);
//						glVertex2f( crossB.x-BS, crossB.y+BS);
//						glVertex2f( crossB.x-BS, crossB.y-BS);
//					glEnd();
					
					glBegin(GL_LINE_LOOP);
					
					long i;
					
					#define CIRCLERESOLUTION 20
					for(i = 0; i < CIRCLERESOLUTION ; i++)
					{
					  // M_PI defined in cmath.h
					  float alpha = i * 2 * M_PI /CIRCLERESOLUTION;
					  
					  glVertex2f( crossB.x + BS*cos(alpha), crossB.y + BS*sin(alpha)/[curDCM pixelRatio]);
					}
					glEnd();
				}
				glLineWidth(1.0);
				
				glColor3f (0.0f, 0.0f, 0.0f);
				
				glDisable(GL_LINE_SMOOTH);
				glDisable(GL_POLYGON_SMOOTH);
				glDisable(GL_POINT_SMOOTH);
				glDisable(GL_BLEND);
			}
			
			// ***********************
			// DRAW CLUT BARS ********
			
			if( [self is2DViewer] == YES && annotations != annotNone)
			{
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f /(size.size.width), -2.0f / (size.size.height), 1.0f); // scale to port per pixel scale

				if( clutBars == barOrigin || clutBars == barBoth)
				{
					float			heighthalf = size.size.height/2 - 1;
					float			widthhalf = size.size.width/2 - 1;
					long			yRaster = 1, xRaster, i;
					NSString		*tempString = 0L;
					
					//#define BARPOSX1 50.f
					//#define BARPOSX2 20.f
					
					#define BARPOSX1 62.f
					#define BARPOSX2 32.f
					
					heighthalf = 0;
					
//					glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
//					glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f);
					
					glLineWidth(1.0);
					glBegin(GL_LINES);
					for( i = 0; i < 256; i++)
					{
						glColor3ub ( redTable[ i], greenTable[ i], blueTable[ i]);
						
						glVertex2f(  widthhalf - BARPOSX1, heighthalf - (-128.f + i));
						glVertex2f(  widthhalf - BARPOSX2, heighthalf - (-128.f + i));
					}
					glColor3ub ( 128, 128, 128);
					glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX2 , heighthalf - -128.f);
					glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);			glVertex2f(  widthhalf - BARPOSX2 , heighthalf - 127.f);
					glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);
					glVertex2f(  widthhalf - BARPOSX2 ,heighthalf -  -128.f);		glVertex2f(  widthhalf - BARPOSX2, heighthalf - 127.f);
					glEnd();
					
					if( curWW < 50)
					{
						tempString = [NSString stringWithFormat: @"%0.4f", curWL - curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - -133 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.4f", curWL];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.4f", curWL + curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 120 rightAlignment: YES useStringTexture: NO];
					}
					else
					{
						tempString = [NSString stringWithFormat: @"%0.0f", curWL - curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - -133 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.0f", curWL];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.0f", curWL + curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 120 rightAlignment: YES useStringTexture: NO];
					}
				} //clutBars == barOrigin || clutBars == barBoth
				
				if( blendingView)
				{
					if( clutBars == barFused || clutBars == barBoth)
					{
						unsigned char	*bred, *bgreen, *bblue;
						float			heighthalf = size.size.height/2 - 1;
						float			widthhalf = size.size.width/2 - 1;
						long			yRaster = 1, xRaster, i;
						float			bwl, bww;
						NSString		*tempString = 0L;
						
						if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
						{
							bred = PETredTable;
							bgreen = PETgreenTable;
							bblue = PETblueTable;
						}
						else [blendingView getCLUT:&bred :&bgreen :&bblue];
						
						#define BBARPOSX1 55.f
						#define BBARPOSX2 25.f
						
						heighthalf = 0;
						
//						glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
//						glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f);
						
						glLineWidth(1.0);
						glBegin(GL_LINES);
						for( i = 0; i < 256; i++)
						{
							glColor3ub ( bred[ i], bgreen[ i], bblue[ i]);
							
							glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - (-128.f + i));
							glVertex2f(  -widthhalf + BBARPOSX2, heighthalf - (-128.f + i));
						}
						glColor3ub ( 128, 128, 128);
						glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - -128.f);		glVertex2f(  -widthhalf + BBARPOSX2 , heighthalf - -128.f);
						glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - 127.f);		glVertex2f(  -widthhalf + BBARPOSX2 , heighthalf - 127.f);
						glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - -128.f);		glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - 127.f);
						glVertex2f(  -widthhalf + BBARPOSX2 ,heighthalf -  -128.f);		glVertex2f(  -widthhalf + BBARPOSX2, heighthalf - 127.f);
						glEnd();
						
						[blendingView getWLWW: &bwl :&bww];
						
						if( curWW < 50)
						{
							tempString = [NSString stringWithFormat: @"%0.4f", bwl - bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - -133];
							
							tempString = [NSString stringWithFormat: @"%0.4f", bwl];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 0];
							
							tempString = [NSString stringWithFormat: @"%0.4f", bwl + bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 120];
						}
						else
						{
							tempString = [NSString stringWithFormat: @"%0.0f", bwl - bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - -133];
							
							tempString = [NSString stringWithFormat: @"%0.0f", bwl];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 0];
							
							tempString = [NSString stringWithFormat: @"%0.0f", bwl + bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 120];
						}
					}
				} //blendingView
			} //[self is2DViewer] == YES

			
			if (annotations != annotNone)
			{
				long yRaster = 1, xRaster;
				char cstr [400], *cptr;
			
				//    NSRect size = [self frame];
				
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f); // scale to port per pixel scale

				//FRAME RECT IF MORE THAN 1 WINDOW and IF THIS WINDOW IS THE FRONTMOST
				if(( numberOf2DViewer > 1 && [self is2DViewer] == YES && stringID == 0L) || [stringID isEqualToString:@"OrthogonalMPRVIEW"])
				{	// draw line around key View
					if( [[self window] isMainWindow] && isKeyView)
					{
						float heighthalf = size.size.height/2;
						float widthhalf = size.size.width/2;
						
						glEnable(GL_BLEND);
						glColor4f (1.0f, 0.0f, 0.0f, 0.8f);
						glLineWidth(8.0);
						glBegin(GL_LINE_LOOP);
							glVertex2f(  -widthhalf, -heighthalf);
							glVertex2f(  -widthhalf, heighthalf);
							glVertex2f(  widthhalf, heighthalf);
							glVertex2f(  widthhalf, -heighthalf);
						glEnd();
						glLineWidth(1.0);
						glDisable(GL_BLEND);
					}
				}  //drawLines for ImageView Frames
				
				if ((_imageColumns > 1 || _imageRows > 1) && [self is2DViewer] == YES && stringID == 0L) {
					float heighthalf = size.size.height/2 - 1;
					float widthhalf = size.size.width/2 - 1;
					
					glColor3f (0.5f, 0.5f, 0.5f);
					glLineWidth(1.0);
					glBegin(GL_LINE_LOOP);
						glVertex2f(  -widthhalf, -heighthalf);
						glVertex2f(  -widthhalf, heighthalf);
						glVertex2f(  widthhalf, heighthalf);
						glVertex2f(  widthhalf, -heighthalf);
					glEnd();
					glLineWidth(1.0);
					if (isKeyView && [[self window] isMainWindow]) {
						float heighthalf = size.size.height/2 - 1;
						float widthhalf = size.size.width/2 - 1;
						
						glColor3f (1.0f, 0.0f, 0.0f);
						glLineWidth(2.0);
						glBegin(GL_LINE_LOOP);
							glVertex2f(  -widthhalf, -heighthalf);
							glVertex2f(  -widthhalf, heighthalf);
							glVertex2f(  widthhalf, heighthalf);
							glVertex2f(  widthhalf, -heighthalf);
						glEnd();
						glLineWidth(1.0);
					}
				}
				
				glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
				glTranslatef( origin.x + originOffset.x, -origin.y - originOffset.y, 0.0f);
				glScalef( 1.f, [curDCM pixelRatio], 1.f);
				
				// Draw ROIs
				BOOL drawROI = NO;
				
				if( [self is2DViewer] == YES) drawROI = [[[self windowController] roiLock] tryLock];
				else drawROI = YES;
				
				if( drawROI)
				{
					BOOL resetData = NO;
					if(_imageColumns > 1 || _imageRows > 1) resetData = YES;	//For alias ROIs
					
					NSSortDescriptor * roiSorting = [[[NSSortDescriptor alloc] initWithKey:@"uniqueID" ascending:NO] autorelease];
					
					rectArray = [[NSMutableArray alloc] initWithCapacity: [curRoiList count]];
					int i;
					for( i = [curRoiList count]-1; i >= 0; i--)
					{
						if( resetData) [[curRoiList objectAtIndex:i] recompute];
						[[curRoiList objectAtIndex:i] setRoiFont: labelFontListGL :labelFontListGLSize :self];
						[[curRoiList objectAtIndex:i] drawROI: scaleValue :[curDCM pwidth]/2. :[curDCM pheight]/2. :[curDCM pixelSpacingX] :[curDCM pixelSpacingY]];
					}
					
					
					if (!suppress_labels)
					{
						NSArray	*sortedROIs = [curRoiList sortedArrayUsingDescriptors: [NSArray arrayWithObject: roiSorting]];
						for(i=[sortedROIs count]-1; i>=0; i--) [[sortedROIs objectAtIndex:i] drawTextualData];
					}
					
					[rectArray release];
					rectArray = 0L;
				}
				
				if( drawROI && [self is2DViewer] == YES) [[[self windowController] roiLock] unlock];
				
				// Draw 2D point cross (used when double-click in 3D panel)
				
				[self draw2DPointMarker];
				if( blendingView) [blendingView draw2DPointMarker];
				
				// Draw any Plugin objects
				
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithFloat: scaleValue], @"scaleValue",
																						[NSNumber numberWithFloat: [curDCM pwidth]/2.], @"offsetx",
																						[NSNumber numberWithFloat: [curDCM pheight]/2.], @"offsety",
																						[NSNumber numberWithFloat: [curDCM pixelSpacingX]], @"spacingX",
																						[NSNumber numberWithFloat: [curDCM pixelSpacingY]], @"spacingY",
																						0L];
				
				[[NSNotificationCenter defaultCenter] postNotificationName: @"PLUGINdrawObjects" object: self userInfo: userInfo];
				
				//**SLICE CUR FOR 3D MPR
				if( stringID)
				{
					if( [stringID isEqualToString:@"OrthogonalMPRVIEW"])
					{
						[self subDrawRect: aRect];
						[self setScaleValue: scaleValue];
					}
				}
				
				//** SLICE CUT BETWEEN SERIES
				
				if( stringID == 0L)
				{
					glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
					glEnable(GL_BLEND);
					glEnable(GL_POINT_SMOOTH);
					glEnable(GL_LINE_SMOOTH);
					glEnable(GL_POLYGON_SMOOTH);

					if( sliceVector[ 0] != 0 | sliceVector[ 1] != 0  | sliceVector[ 2] != 0 )
					{
						glColor3f (0.0f, 0.6f, 0.0f);
						glLineWidth(2.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePoint[ 0] - 10000*sliceVector[ 0]), scaleValue*(slicePoint[ 1] - 10000*sliceVector[ 1]));
							glVertex2f( scaleValue*(slicePoint[ 0] + 10000*sliceVector[ 0]), scaleValue*(slicePoint[ 1] + 10000*sliceVector[ 1]));
						glEnd();
						glLineWidth(1.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointI[ 0] - 10000*sliceVector[ 0]), scaleValue*(slicePointI[ 1] - 10000*sliceVector[ 1]));
							glVertex2f( scaleValue*(slicePointI[ 0] + 10000*sliceVector[ 0]), scaleValue*(slicePointI[ 1] + 10000*sliceVector[ 1]));
						glEnd();
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointO[ 0] - 10000*sliceVector[ 0]), scaleValue*(slicePointO[ 1] - 10000*sliceVector[ 1]));
							glVertex2f( scaleValue*(slicePointO[ 0] + 10000*sliceVector[ 0]), scaleValue*(slicePointO[ 1] + 10000*sliceVector[ 1]));
						glEnd();
					}
					
					if( slicePoint3D[ 0] != 0 | slicePoint3D[ 1] != 0  | slicePoint3D[ 2] != 0 )
					{
						float vectorP[ 9], tempPoint3D[ 3], rotateVector[ 2];
						
					//	glColor3f (0.6f, 0.0f, 0.0f);
						
						[curDCM orientation: vectorP];
						
						glLineWidth(2.0);
						
					//	NSLog(@"Before: %2.2f / %2.2f / %2.2f", slicePoint3D[ 0], slicePoint3D[ 1], slicePoint3D[ 2]);
						
						slicePoint3D[ 0] -= [curDCM originX];
						slicePoint3D[ 1] -= [curDCM originY];
						slicePoint3D[ 2] -= [curDCM originZ];
						
						tempPoint3D[ 0] = slicePoint3D[ 0] * vectorP[ 0] + slicePoint3D[ 1] * vectorP[ 1] + slicePoint3D[ 2] * vectorP[ 2];
						tempPoint3D[ 1] = slicePoint3D[ 0] * vectorP[ 3] + slicePoint3D[ 1] * vectorP[ 4] + slicePoint3D[ 2] * vectorP[ 5];
						tempPoint3D[ 2] = slicePoint3D[ 0] * vectorP[ 6] + slicePoint3D[ 1] * vectorP[ 7] + slicePoint3D[ 2] * vectorP[ 8];
						
						slicePoint3D[ 0] += [curDCM originX];
						slicePoint3D[ 1] += [curDCM originY];
						slicePoint3D[ 2] += [curDCM originZ];
						
					//	NSLog(@"After: %2.2f / %2.2f / %2.2f", tempPoint3D[ 0], tempPoint3D[ 1], tempPoint3D[ 2]);
						
						tempPoint3D[0] /= [curDCM pixelSpacingX];
						tempPoint3D[1] /= [curDCM pixelSpacingY];
						
						tempPoint3D[0] -= [curDCM pwidth]/2.;
						tempPoint3D[1] -= [curDCM pheight]/2.;
						
						if( sliceVector[ 0] != 0 | sliceVector[ 1] != 0  | sliceVector[ 2] != 0 )
						{
							rotateVector[ 0] = sliceVector[ 1];
							rotateVector[ 1] = -sliceVector[ 0];
							
							glBegin(GL_LINES);
							glVertex2f( scaleValue*(tempPoint3D[ 0]-20/[curDCM pixelSpacingX] *(rotateVector[ 0])), scaleValue*(tempPoint3D[ 1]-20/[curDCM pixelSpacingY]*(rotateVector[ 1])));
							glVertex2f( scaleValue*(tempPoint3D[ 0]+20/[curDCM pixelSpacingX] *(rotateVector[ 0])), scaleValue*(tempPoint3D[ 1]+20/[curDCM pixelSpacingY]*(rotateVector[ 1])));
							glEnd();
						}
						else
						{
							glColor3f (0.0f, 0.6f, 0.0f);
							glLineWidth(2.0);
							
							glBegin(GL_LINES);
								glVertex2f( scaleValue*(tempPoint3D[ 0]-20/[curDCM pixelSpacingX]), scaleValue*(tempPoint3D[ 1]));
								glVertex2f( scaleValue*(tempPoint3D[ 0]+20/[curDCM pixelSpacingX]), scaleValue*(tempPoint3D[ 1]));
								
								glVertex2f( scaleValue*(tempPoint3D[ 0]), scaleValue*(tempPoint3D[ 1]-20/[curDCM pixelSpacingY]));
								glVertex2f( scaleValue*(tempPoint3D[ 0]), scaleValue*(tempPoint3D[ 1]+20/[curDCM pixelSpacingY]));
							glEnd();
						}
						
						
						
						glLineWidth(1.0);
					}
					
					if( sliceVector2[ 0] != 0 | sliceVector2[ 1] != 0  | sliceVector2[ 2] != 0 )
					{
						glColor3f (0.0f, 0.6f, 0.0f);
						glLineWidth(2.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePoint2[ 0] - 10000*sliceVector2[ 0]), scaleValue*(slicePoint2[ 1] - 10000*sliceVector2[ 1]));
							glVertex2f( scaleValue*(slicePoint2[ 0] + 10000*sliceVector2[ 0]), scaleValue*(slicePoint2[ 1] + 10000*sliceVector2[ 1]));
						glEnd();
						glLineWidth(1.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointI2[ 0] - 10000*sliceVector2[ 0]), scaleValue*(slicePointI2[ 1] - 10000*sliceVector2[ 1]));
							glVertex2f( scaleValue*(slicePointI2[ 0] + 10000*sliceVector2[ 0]), scaleValue*(slicePointI2[ 1] + 10000*sliceVector2[ 1]));
						glEnd();
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointO2[ 0] - 10000*sliceVector2[ 0]), scaleValue*(slicePointO2[ 1] - 10000*sliceVector2[ 1]));
							glVertex2f( scaleValue*(slicePointO2[ 0] + 10000*sliceVector2[ 0]), scaleValue*(slicePointO2[ 1] + 10000*sliceVector2[ 1]));
						glEnd();
					}
					
					glDisable(GL_LINE_SMOOTH);
					glDisable(GL_POLYGON_SMOOTH);
					glDisable(GL_POINT_SMOOTH);
					glDisable(GL_BLEND);
				}
				
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f / size.size.width, -2.0f /  size.size.height, 1.0f); // scale to port per pixel scale
				
				glColor3f (0.0f, 1.0f, 0.0f);
				
				 if( annotations >= annotBase)
				 {
					//** PIXELSPACING LINES
					float yOffset = 24;
					float xOffset = 32;
					//float xOffset = 10;
					//float yOffset = 12;
					glBegin(GL_LINES);
					if( [curDCM pixelSpacingX] != 0 && [curDCM pixelSpacingX] * 1000.0 < 1)
					{ 
						glVertex2f(scaleValue  * (-0.02/[curDCM pixelSpacingX]), size.size.height/2 - yOffset); 
						glVertex2f(scaleValue  * (0.02/[curDCM pixelSpacingX]), size.size.height/2 - yOffset);

						glVertex2f(-size.size.width/2 + xOffset , scaleValue  * (-0.02/[curDCM pixelSpacingY]*[curDCM pixelRatio])); 
						glVertex2f(-size.size.width/2 + xOffset , scaleValue  * (0.02/[curDCM pixelSpacingY]*[curDCM pixelRatio]));

						short i, length;
						for (i = -20; i<=20; i++)
						{
							if (i % 10 == 0) length = 10;
							else  length = 5;
						
							glVertex2f(i*scaleValue *0.001/[curDCM pixelSpacingX], size.size.height/2 - yOffset);
							glVertex2f(i*scaleValue *0.001/[curDCM pixelSpacingX], size.size.height/2 - yOffset - length);
							
							glVertex2f(-size.size.width/2 + xOffset +  length,  i* scaleValue *0.001/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
							glVertex2f(-size.size.width/2 + xOffset,  i* scaleValue * 0.001/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
						}
					}
					else if( [curDCM pixelSpacingX] != 0 && [curDCM pixelSpacingY] != 0)
					{
						glVertex2f(scaleValue  * (-50/[curDCM pixelSpacingX]), size.size.height/2 - yOffset); 
						glVertex2f(scaleValue  * (50/[curDCM pixelSpacingX]), size.size.height/2 - yOffset);
						
						glVertex2f(-size.size.width/2 + xOffset , scaleValue  * (-50/[curDCM pixelSpacingY]*[curDCM pixelRatio])); 
						glVertex2f(-size.size.width/2 + xOffset , scaleValue  * (50/[curDCM pixelSpacingY]*[curDCM pixelRatio]));

						short i, length;
						for (i = -5; i<=5; i++)
						{
							if (i % 5 == 0) length = 10;
							else  length = 5;
						
							glVertex2f(i*scaleValue *10/[curDCM pixelSpacingX], size.size.height/2 - yOffset);
							glVertex2f(i*scaleValue *10/[curDCM pixelSpacingX], size.size.height/2 - yOffset - length);
							
							glVertex2f(-size.size.width/2 + xOffset +  length,  i* scaleValue *10/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
							glVertex2f(-size.size.width/2 + xOffset,  i* scaleValue * 10/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
						}
					}
					glEnd();
					
					[self drawTextualData: size :annotations];
					
				} //annotations >= annotBase
				} //Annotation  != None
				
				if(repulsorRadius != 0)
				{
					glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
					glScalef (2.0f / size.size.width, -2.0f /  size.size.height, 1.0f); // scale to port per pixel scale
					glTranslatef (-(size.size.width) / 2.0f, -(size.size.height) / 2.0f, 0.0f); // translate center to upper left
					
					[self drawRepulsorToolArea];
				}
				
				if(ROISelectorStartPoint.x!=ROISelectorEndPoint.x || ROISelectorStartPoint.y!=ROISelectorEndPoint.y)
				{
					glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
					glScalef (2.0f / size.size.width, -2.0f /  size.size.height, 1.0f); // scale to port per pixel scale
					glTranslatef (-(size.size.width) / 2.0f, -(size.size.height) / 2.0f, 0.0f); // translate center to upper left
					
					[self drawROISelectorRegion];
				}
			}  
		
		else {  //no valid image  ie curImage = -1
			//NSLog(@"no IMage");
			glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
			glClear (GL_COLOR_BUFFER_BIT);
		}
		
	// Swap buffer to screen
	//	[[self openGLContext] flushBuffer];
	[ctx  flushBuffer];
	(void)[self _checkHasChanged:YES];
		
//		GLenum err = glGetError();
//		if (GL_NO_ERROR != err)
//		{
//			NSString * errString = [NSString stringWithFormat:@"Error: %d.", err];
//			NSLog (@"%@\n", errString);
//		}
		
	}  //[NSGraphicsContext currentContextDrawingToScreen] 
	else  //not drawing to screen
	{
//        long		width, height;
//		NSRect		dstRect;
//		float		scale;
//		
//		NSLog(@"size: %f, %f", aRect.size.width, aRect.size.height);
//		
//		NSImage *im = [self nsimage:YES];
//		
//		[im setScalesWhenResized:YES];
//        
//		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
//		
//		if( [im size].width / aRect.size.width > [im size].height / aRect.size.height)
//		{
//			scale = [im size].width / aRect.size.width;
//		}
//		else
//		{
//			scale = [im size].height / aRect.size.height;
//		}
//		
//		dstRect = NSMakeRect( 0, 0, [im size].width / scale, [im size].height / scale);
//		
//		[im drawRepresentation:[im bestRepresentationForDevice:nil] inRect:dstRect]; 
	}
}

- (NSMutableArray*) rectArray
{
	return rectArray;
}

- (void)reshape	// scrolled, moved or resized
{
	if( dcmPixList && [[self window] isVisible])
    {
		NSRect rect = [self frame];
		
		if( previousViewSize.width != 0)
		{
			// Adapted scale to new viewSize!
			
			float   maxChanged, xChanged = rect.size.width / previousViewSize.width, yChanged = rect.size.height / previousViewSize.height;
			
			if( xChanged < 1 || yChanged < 1)
			{
			//	if(  xChanged < yChanged) maxChanged = xChanged;
			//	else
				maxChanged = yChanged;
			}
			else
			{
			//	if(  xChanged > yChanged) maxChanged = xChanged;
			//	else
				maxChanged = yChanged;
			}
			
			if( maxChanged > 0.01 && maxChanged < 1000) maxChanged = maxChanged;
			else maxChanged = 0.01;
			
			[self setScaleValue: (scaleValue * maxChanged)];
			//scaleValue *= maxChanged;
			
			//if( scaleValue < 0.01) scaleValue = 0.01;
			
			origin.x *= maxChanged;
			origin.y *= maxChanged;
			
			originOffset.x *= maxChanged;
			originOffset.y *= maxChanged;
			
			if( [self is2DViewer] == YES)
				[[self windowController] propagateSettings];
			
			if( [stringID isEqualToString:@"FinalView"] == YES || [stringID isEqualToString:@"OrthogonalMPRVIEW"]) [self blendingPropagate];
			if( [stringID isEqualToString:@"Original"] == YES) [self blendingPropagate];
		}
		previousViewSize = rect.size;
		//[self setNeedsDisplay:true];
    }
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	return [self getRawPixels:width :height :spp :bpp :screenCapture :force8bits :YES];
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical
{
	return [self getRawPixels:width :height :spp :bpp :screenCapture :force8bits :removeGraphical :NO];
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical :(BOOL) squarePixels
{
	unsigned char	*buf = 0L;
	long			i;
	
	if( screenCapture)	// Pixels displayed in current window
	{
		for( i = 0; i < [curRoiList count]; i++)	[[curRoiList objectAtIndex: i] setROIMode: ROI_sleep];
		
	//	if( force8bits)
		{
			NSRect size = [self bounds];
			
			*width = size.size.width;
			*width/=4;
			*width*=4;
			*height = size.size.height;
			*spp = 3;
//			*spp = 4;
			*bpp = 8;
			
			buf = malloc( 1 + *width * *height * 4 * *bpp/8);
			if( buf)
			{
				if(removeGraphical)
				{
					NSString	*str = [[self stringID] retain];
					[self setStringID: @"export"];
					
					[self display];
					
					[self setStringID: str];
					[str release];
				}
				else if( [curRoiList count]) [self display];
				
				[[self openGLContext] makeCurrentContext];
				
				#if __BIG_ENDIAN__
					glReadPixels(0, 0, *width, *height, GL_RGB, GL_UNSIGNED_BYTE, buf);
				#else
					glReadPixels(0, 0, *width, *height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, buf);		//GL_ABGR_EXT
					
					register int ii = *width * *height;
					register unsigned char	*t_argb = buf;
					register unsigned char	*t_rgb = buf;
					while( ii-->0)
					{
						*((int*) t_rgb) = *((int*) t_argb);
						t_argb+=4;
						t_rgb+=3;
					}
				#endif
				
				long rowBytes = *width**spp**bpp/8;
				
				unsigned char	*tempBuf = malloc( rowBytes);
				
				for( i = 0; i < *height/2; i++)
				{
					memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
					memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
					memcpy( buf + i*rowBytes, tempBuf, rowBytes);
				}
				
				free( tempBuf);
			}
		}
//		else
//		{
//			// Convert data to 16 bits
//			vImage_Buffer			srcf, dst8;
//				
//			*spp = 1;
//			*bpp = 16;
//			*width = [curDCM pwidth];
//			*height = [curDCM pheight];
//		
//			srcf.height = *height;
//			srcf.width = *width;
//			srcf.rowBytes = *width * sizeof( float);
//			
//			dst8.height =  *height;
//			dst8.width = *width;
//			dst8.rowBytes = *width * sizeof( short);
//			
//			srcf.data = [curDCM fImage];
//			
//			i = *width * *height * *spp * *bpp / 8;
//			unsigned short	*srcBuf = malloc( i);
//			if( srcBuf)
//			{
//				dst8.data = srcBuf;
//				vImageConvert_FTo16U( &srcf, &dst8, -1024,  1, 0);	//By default, we use a 1024 rescale intercept !!
//			}
//			
//			NSPoint pt1 = [self frame].origin;
//			NSPoint pt2;
//			
//			pt2.x = [self frame].origin.x + [self frame].size.width;
//			pt2.y = [self frame].origin.y + [self frame].size.height;
//			
//			pt1 = [self ConvertFromView2GL:pt1];
//			pt2 = [self ConvertFromView2GL:pt2];
//			
//		//	NSLog( @"%f %f - %f %f", pt1.x, pt1.y, pt2.x, pt2.y);
//			
//			long newWidth, newHeight, originX, originY;
//			long x, y;
//			
//			newWidth = pt2.x - pt1.x;
//			newHeight = pt2.y - pt1.y;
//			
//			newWidth /= 2;
//			newHeight /= 2;
//			newWidth *= 2;
//			newHeight *= 2;
//			
//			originX = pt1.x;
//			originY = pt1.y;
//			
//			i = newWidth * newHeight * *spp * *bpp / 8;
//			unsigned short	*cropBuf = malloc( i);
//			
//			if( cropBuf)
//			{
//				memset( cropBuf, -1024, i);
//				
//				for( x = originX; x < originX+newWidth; x++)
//				{
//					for( y = originY; y < originY+newHeight; y++)
//					{
//						if( x >= 0 && x < *width && y >= 0 && y < *height)
//							cropBuf[ (x-originX) + newWidth*(y-originY)] = srcBuf[ x + *width*y];
//					}
//				}
//			}
//			
//			free( srcBuf);
//			buf = (unsigned char*) cropBuf;
//			
//			*width = newWidth;
//			*height = newHeight;
//		}
	}
	else				// Pixels contained in memory  -> only RGB or 16 bits data
	{
		BOOL	isRGB = [curDCM isRGB];
		
		*width = [curDCM pwidth];
		*height = [curDCM pheight];
		
		if( [curDCM thickSlabVRActivated])
		{
			force8bits = YES;
			
			if( [curDCM stackMode] == 4 || [curDCM stackMode] == 5) isRGB = YES;
		}
		
		if( isRGB == YES)
		{
			*spp = 3;
			*bpp = 8;
			
			i = *width * *height * *spp * *bpp / 8;
			buf = malloc( i);
			if( buf)
			{
				unsigned char *dst = buf, *src = (unsigned char*) [curDCM baseAddr];
				i = *width * *height;
				
				// CONVERT ARGB TO RGB
				while( i-- > 0)
				{
					src++;
					*dst++ = *src++;
					*dst++ = *src++;
					*dst++ = *src++;
				}
			}
		}
		else if( colorBuf != 0L)		// A CLUT is applied
		{
			*spp = 3;
			*bpp = 8;
			
			i = *width * *height * *spp * *bpp / 8;
			buf = malloc( i);
			if( buf)
			{
				unsigned char *dst = buf, *src = colorBuf;
				i = *width * *height;
				
				#if __BIG_ENDIAN__
				// CONVERT ARGB TO RGB
				while( i-- > 0)
				{
					src++;
					*dst++ = *src++;
					*dst++ = *src++;
					*dst++ = *src++;
				}
				#else
				while( i-- > 0)
				{
					dst[2] = src[0];
					dst[1] = src[1];
					dst[0] = src[2];
					src+=4;
					dst+=3;
				}
				#endif
			}
		}
		else
		{
			if( force8bits)	// I don't want 16 bits data, only 8 bits data
			{
				*spp = 1;
				*bpp = 8;
				
				i = *width * *height * *spp * *bpp / 8;
				buf = malloc( i);
				if( buf)
				{
					memcpy( buf, [curDCM baseAddr], *width**height);
				}
			}
			else	// Give me 16 bits !
			{
				vImage_Buffer			srcf, dst8;
				
				*spp = 1;
				*bpp = 16;
				
				srcf.height = *height;
				srcf.width = *width;
				srcf.rowBytes = *width * sizeof( float);
				
				dst8.height =  *height;
				dst8.width = *width;
				dst8.rowBytes = *width * sizeof( short);
				
				srcf.data = [curDCM computefImage];
				
				i = *width * *height * *spp * *bpp / 8;
				buf = malloc( i);
				if( buf)
				{
					dst8.data = buf;
					vImageConvert_FTo16U( &srcf, &dst8, -1024,  1, 0);	//By default, we use a 1024 rescale intercept !!
				}
				
				if( srcf.data != [curDCM fImage]) free( srcf.data);
			}
		}
		
		// IF 8 bits or RGB, IF non-square pixels -> square pixels
		
		if( squarePixels == YES && *bpp == 8 && [self pixelSpacingX] != [self pixelSpacingY])
		{
			vImage_Buffer	srcVimage, dstVimage;
			
			srcVimage.data = buf;
			srcVimage.height = *height;
			srcVimage.width = *width;
			srcVimage.rowBytes = *width * (*bpp/8) * *spp;
			
			dstVimage.height =  (int) ((float) *height * [self pixelSpacingY] / [self pixelSpacingX]);
			dstVimage.width = *width;
			dstVimage.rowBytes = *width * (*bpp/8) * *spp;
			dstVimage.data = malloc( dstVimage.rowBytes * dstVimage.height);
			
			if( *spp == 3)
			{
				vImage_Buffer	argbsrcVimage, argbdstVimage;
				
				argbsrcVimage = srcVimage;
				argbsrcVimage.rowBytes =  *width * 4;
				argbsrcVimage.data = malloc( argbsrcVimage.rowBytes * argbsrcVimage.height);
				
				argbdstVimage = dstVimage;
				argbdstVimage.rowBytes =  *width * 4;
				argbdstVimage.data = malloc( argbdstVimage.rowBytes * argbdstVimage.height);
				
				vImageConvert_RGB888toARGB8888( &srcVimage, 0L, 0, &argbsrcVimage, 0, 0);
				vImageScale_ARGB8888( &argbsrcVimage, &argbdstVimage, 0L, kvImageHighQualityResampling);
				vImageConvert_ARGB8888toRGB888( &argbdstVimage, &dstVimage, 0);
				
				free( argbsrcVimage.data);
				free( argbdstVimage.data);
			}
			else
				vImageScale_Planar8( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
				
			free( buf);
			
			buf = dstVimage.data;
			*height = dstVimage.height;
		}
	}
	
	return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
	return [self nsimage: originalSize allViewers: NO];
}

-(NSImage*) nsimage:(BOOL) originalSize allViewers:(BOOL) allViewers
{
	NSBitmapImageRep	*rep;
	long				width, height, i, spp, bpp, x;
	NSString			*colorSpace;
	unsigned char		*data;
		
	if( numberOf2DViewer > 1 && stringID == 0L && originalSize == NO)
	{
		stringID = [@"copy" retain];	// to remove the red square around the image
		[self display];
	}
	
	if( allViewers)
	{
		unsigned char	*tempData = 0L;
		NSRect			unionRect;
		NSArray			*viewers = [ViewerController getDisplayed2DViewers];
		
		//order windows from left-top to right-bottom
		NSMutableArray	*cWindows = [NSMutableArray arrayWithArray: viewers];
		NSMutableArray	*cResult = [NSMutableArray array];
		int wCount = [cWindows count];
		for( i = 0; i < wCount; i++)
		{		
			int index = 0;
			float minY = [[[cWindows objectAtIndex: 0] window] frame].origin.y;
			
			for( x = 0; x < [cWindows count]; x++)
			{
				if( [[[cWindows objectAtIndex: x] window] frame].origin.y > minY)
				{
					minY  = [[[cWindows objectAtIndex: x] window] frame].origin.y;
					index = x;
				}
			}
			
			float minX = [[[cWindows objectAtIndex: index] window] frame].origin.x;
			
			for( x = 0; x < [cWindows count]; x++)
			{
				if( [[[cWindows objectAtIndex: x] window] frame].origin.x < minX && [[[cWindows objectAtIndex: x] window] frame].origin.y >= minY)
				{
					minX = [[[cWindows objectAtIndex: x] window] frame].origin.x;
					index = x;
				}
			}
			
			[cResult addObject: [cWindows objectAtIndex: index]];
			[cWindows removeObjectAtIndex: index];
		}
		
		viewers = cResult;
		
		NSMutableArray	*viewsRect = [NSMutableArray array];
		
		// Compute the enclosing rect
		for( i = 0; i < [viewers count]; i++)
		{
			NSRect	bounds = [[[viewers objectAtIndex: i] imageView] bounds];
			NSPoint or = [[[viewers objectAtIndex: i] imageView] convertPoint: bounds.origin toView: 0L];
			bounds.origin = [[[viewers objectAtIndex: i] window] convertBaseToScreen: or];
			
			bounds = NSIntegralRect( bounds);
			
			[viewsRect addObject: [NSValue valueWithRect: bounds]];
			
			if( i == 0)  unionRect = bounds;
			else unionRect = NSUnionRect( bounds, unionRect);
		}
		
		for( i = 0; i < [viewers count]; i++)
		{
			NSRect curRect = [[viewsRect objectAtIndex: i] rectValue];
			BOOL intersect;
			
			// X move
			do
			{
				intersect = NO;
				
				for( x = 0 ; x < [viewers count]; x++)
				{
					if( x != i)
					{
						NSRect	rect = [[viewsRect objectAtIndex: x] rectValue];
						if( NSIntersectsRect( curRect, rect))
						{
							curRect.origin.x += 2;
							intersect = YES;
						}
					}
				}
				
				if( intersect == NO)
				{
					curRect.origin.x --;
					if( curRect.origin.x <= unionRect.origin.x) intersect = YES;
				}
			}
			while( intersect == NO);
			
			[viewsRect replaceObjectAtIndex: i withObject: [NSValue valueWithRect: curRect]];
		}
		
		for( i = 0; i < [viewers count]; i++)
		{
			NSRect curRect = [[viewsRect objectAtIndex: i] rectValue];
			BOOL intersect;
			
			// Y move
			do
			{
				intersect = NO;
				
				for( x = 0 ; x < [viewers count]; x++)
				{
					if( x != i)
					{
						NSRect	rect = [[viewsRect objectAtIndex: x] rectValue];
						if( NSIntersectsRect( curRect, rect))
						{
							curRect.origin.y-= 2;
							intersect = YES;
						}
					}
				}
				
				if( intersect == NO)
				{
					curRect.origin.y ++;
					if( curRect.origin.y + curRect.size.height > unionRect.origin.y + unionRect.size.height) intersect = YES;
				}
			}
			while( intersect == NO);
			
			[viewsRect replaceObjectAtIndex: i withObject: [NSValue valueWithRect: curRect]];
		}
		
		// Re-Compute the enclosing rect
		unionRect = [[viewsRect objectAtIndex: 0] rectValue];
		for( i = 0; i < [viewers count]; i++)
		{
			unionRect = NSUnionRect( [[viewsRect objectAtIndex: i] rectValue], unionRect);
		}
		
		width = unionRect.size.width;
		if(width % 4 != 0) width += 4;
		width /= 4;
		width *= 4;
		height = unionRect.size.height;
		spp = 3;
		bpp = 8;
		
		data = calloc( 1, width * height * spp * bpp/8);
		for( i = 0; i < [viewers count]; i++)
		{
			long	iwidth, iheight, ispp, ibpp;
			
			tempData = [[[viewers objectAtIndex: i] imageView] getRawPixels:&iwidth :&iheight :&ispp :&ibpp :YES :NO];
			
			NSRect	bounds = [[viewsRect objectAtIndex: i] rectValue];	//[[[viewers objectAtIndex: i] imageView] bounds];
			
			bounds.origin.x -= unionRect.origin.x;
			bounds.origin.y -= unionRect.origin.y;
			
//			NSPoint origin = [[[viewers objectAtIndex: i] imageView] convertPoint: bounds.origin toView: 0L];
//			bounds.origin = [[[viewers objectAtIndex: i] window] convertBaseToScreen: origin];
			
			unsigned char	*o = data + spp*width* (int) (height - bounds.origin.y - iheight) + (int) bounds.origin.x*spp;
			
			int y;
			for( y = 0 ; y < iheight; y++)
			{
				memcpy( o + y*spp*width, tempData + y*ispp*iwidth, ispp*iwidth);
			}
			
			free( tempData);
		}
	}
	else data = [self getRawPixels :&width :&height :&spp :&bpp :!originalSize : YES :NO :YES];
	
	if( [stringID isEqualToString:@"copy"])
	{
		[stringID release];
		stringID = 0L;
		
		[self setNeedsDisplay: YES];
	}
	
	if( spp == 3) colorSpace = NSCalibratedRGBColorSpace;
	else colorSpace = NSCalibratedWhiteColorSpace;
	
	rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:0L
						   pixelsWide:width
						   pixelsHigh:height
						bitsPerSample:bpp
					  samplesPerPixel:spp
							 hasAlpha:NO
							 isPlanar:NO
					   colorSpaceName:colorSpace
						  bytesPerRow:width*bpp*spp/8
						 bitsPerPixel:bpp*spp] autorelease];
	
	memcpy( [rep bitmapData], data, height*width*bpp*spp/8);
	
	NSImage *image = [[NSImage alloc] init];
	[image addRepresentation:rep];
     
	free( data);
	 
    return image;
}

-(float) scaleValue;
{
	return scaleValue;
}

-(void) setScaleValueCentered:(float) x
{
	if( scaleValue)
	{
		origin.x = ((origin.x * x) / scaleValue);
		origin.y = ((origin.y * x) / scaleValue);
				
		originOffset.x = ((originOffset.x * x) / scaleValue);
		originOffset.y = ((originOffset.y * x) / scaleValue);
	}
	scaleValue = x;
	
	if( x < 0.01) scaleValue = 0.01;
	if( x > 100) scaleValue = 100;
	
	[self setNeedsDisplay:YES];
}

-(void) setScaleValue:(float) x
{
	if( scaleValue != x)
	{
		scaleValue = x;
		if( x < 0.01) scaleValue = 0.01;
		if( x > 100) scaleValue = 100;

	//	if( scaleValue > 0.01 && scaleValue < 100) scaleValue = scaleValue;
	//	else scaleValue = 0.01;
		
		[self setNeedsDisplay:YES];
	}
}


-(NSArray*) dcmFilesList
{
	return dcmFilesList;
}

-(NSMutableArray*) dcmPixList
{
	return dcmPixList;
}

-(NSMutableArray*) dcmRoiList
{
	return dcmRoiList;
}

- (long) indexForPix: (long) pixIndex
{
	if ([[[dcmFilesList objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] == 1)
		return curImage;
	else
		return 0;
}

- (long) syncSeriesIndex
{
	return syncSeriesIndex;
}

-(void) setSyncSeriesIndex:(long) i
{
	syncSeriesIndex = i;
}

-(void) setAlpha:(float) a
{
	long	i;
	float   val, ii;
	float   src[ 256];
	
	switch( blendingMode)
	{
		case 0:				// LINEAR FUSION
			for( i = 0; i < 256; i++) src[ i] = i;
		break;
		
		case 1:				// HIGH-LOW-HIGH
			for( i = 0; i < 128; i++) src[ i] = (127 - i)*2;
			for( i = 128; i < 256; i++) src[ i] = (i-127)*2;
		break;
		
		case 2:				// LOW-HIGH-LOW
			for( i = 0; i < 128; i++) src[ i] = i*2;
			for( i = 128; i < 256; i++) src[ i] = 256 - (i-127)*2;
		break;
		
		case 3:				// LOG
			for( i = 0; i < 256; i++) src[ i] = 255. * log10( 1. + (i/255.)*9.);
		break;
		
		case 4:				// LOG INV
			for( i = 0; i < 256; i++) src[ i] = 255. * (1. - log10( 1. + ((255-i)/255.)*9.));
		break;
		
		case 5:				// FLAT
			for( i = 0; i < 256; i++) src[ i] = 128;
		break;
	}
	
	if( a <= 0)
	{
		a += 256;
		
		for(i=0; i < 256; i++) 
		{
			ii = src[ i];
			val = (a * ii) / 256.;
			
			if( val > 255) val = 255;
			if( val < 0) val = 0;
			alphaTable[i] = val;
		}
	}
	else
	{
		if( a == 256) for(i=0; i < 256; i++) alphaTable[i] = 255;
		else
		{
			for(i=0; i < 256; i++) 
			{
				ii = src[ i];
				val = (256. * ii)/(256 - a);
				
				if( val > 255) val = 255;
				if( val < 0) val = 0;
				alphaTable[i] = val;
			}
		}
	}
}

-(void) setBlendingFactor:(float) f
{
	blendingFactor = f;
	
	[blendingView setAlpha: blendingFactor];
	[self loadTextures];
	[self setNeedsDisplay: YES];
}

-(void) setBlendingMode:(long) f
{
	blendingMode = f;
	
	[blendingView setBlendingMode: blendingMode];
	
	[blendingView setAlpha: blendingFactor];
	
	[self loadTextures];
	[self setNeedsDisplay: YES];
}

-(float) rotation;
{
	return rotation;
}

-(void) setRotation:(float) x
{
	rotation = x;
	
	if( rotation < 0) rotation += 360;
	if( rotation > 360) rotation -= 360;
	
	[[self seriesObj] setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"]];
}

- (void) orientationCorrectedToView:(float*) correctedOrientation
{
	float	o[ 9];
	float   yRot = -1, xRot = -1;
	float	rot = rotation;
	
	[curDCM orientation: o];
	
	if( yFlipped && xFlipped)
	{
		rot = rot + 180;
	}
	else
	{
		if( yFlipped)
		{
			xRot *= -1;
			yRot *= -1;
			
			o[ 3] *= -1;
			o[ 4] *= -1;
			o[ 5] *= -1;
		}
		
		if( xFlipped)
		{
			xRot *= -1;
			yRot *= -1;
			
			o[ 0] *= -1;
			o[ 1] *= -1;
			o[ 2] *= -1;
		}
	}

	// Compute normal vector
	o[6] = o[1]*o[5] - o[2]*o[4];
	o[7] = o[2]*o[3] - o[0]*o[5];
	o[8] = o[0]*o[4] - o[1]*o[3];

	XYZ vector, rotationVector; 
	
	rotationVector.x = o[ 6];	rotationVector.y = o[ 7];	rotationVector.z = o[ 8];
	
	vector.x = o[ 0];	vector.y = o[ 1];	vector.z = o[ 2];
	vector =  ArbitraryRotate(vector, xRot*rot*deg2rad, rotationVector);
	o[ 0] = vector.x;	o[ 1] = vector.y;	o[ 2] = vector.z;
	
	vector.x = o[ 3];	vector.y = o[ 4];	vector.z = o[ 5];
	vector =  ArbitraryRotate(vector, yRot*rot*deg2rad, rotationVector);
	o[ 3] = vector.x;	o[ 4] = vector.y;	o[ 5] = vector.z;

	// Compute normal vector
	o[6] = o[1]*o[5] - o[2]*o[4];
	o[7] = o[2]*o[3] - o[0]*o[5];
	o[8] = o[0]*o[4] - o[1]*o[3];

	int i;
	for( i = 0; i < 9; i++) correctedOrientation[ i] = o[ i];
}

-(NSPoint) origin
{
	return origin;
}

-(NSPoint) originOffset
{
	return originOffset;
}

-(void) setOrigin:(NSPoint) x
{
	if( x.x > -100000 && x.x < 100000) x.x = x.x;
	else x.x = 0;

	if( x.y > -100000 && x.y < 100000) x.y = x.y;
	else x.y = 0;
	
	origin = x;
	
	[self setNeedsDisplay:YES];
}

-(void) setOriginOffset:(NSPoint) x
{
	originOffset = x;
	
	[self setNeedsDisplay:YES];
}

- (void) colorTables:(unsigned char **) a :(unsigned char **) r :(unsigned char **)g :(unsigned char **) b
{
	*a = alphaTable;
	*r = redTable;
	*g = greenTable;
	*b = blueTable;
}

- (void) blendingColorTables:(unsigned char **) a :(unsigned char **) r :(unsigned char **)g :(unsigned char **) b
{
	if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
	{
		*a = alphaTable;
		*r = PETredTable;
		*g = PETgreenTable;
		*b = PETblueTable;
	}
	else
	{
		[blendingView colorTables:a :r :g :b];
	}
}

- (GLuint *) loadTextureIn:(GLuint *) texture blending:(BOOL) blending colorBuf: (unsigned char**) colorBufPtr textureX:(long*) tX textureY:(long*) tY redTable:(unsigned char*) rT greenTable:(unsigned char*) gT blueTable:(unsigned char*) bT 
{
	if(  rT == 0L)
	{
		rT = redTable;
		gT = greenTable;
		bT = blueTable;
	}

	if( curDCM == 0L) NSLog( @"err curDCM == 0L");
	
	if( noScale == YES)
	{
		[curDCM changeWLWW :127 : 256];
	}
	
	if( mainThread != [NSThread currentThread])
	{
		NSLog(@"Warning! OpenGL activity NOT in the main thread???");
	}
	
    if( texture)
	{
		glDeleteTextures( *tX * *tY, texture);
		free( (char*) texture);
		texture = 0L;
	}
	
	if( [curDCM isRGB] == YES)
	{
		if((colorTransfer == YES) || (blending == YES))
		{
			vImage_Buffer src, dest;
			
			[curDCM changeWLWW :curWL: curWW];
			
			src.height = [curDCM pheight];
			src.width = [curDCM pwidth];
			src.rowBytes = [curDCM rowBytes];
			src.data = [curDCM baseAddr];
			
			dest.height = [curDCM pheight];
			dest.width = [curDCM pwidth];
			dest.rowBytes = [curDCM rowBytes];
			dest.data = [curDCM baseAddr];
			
			if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
			{
				unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
				long i;
				
				for( i = 0; i < 256; i++)
				{
					credTable[ i] = rT[ i] * redFactor;
					cgreenTable[ i] = gT[ i] * greenFactor;
					cblueTable[ i] = bT[ i] * blueFactor;
				}
				#if __BIG_ENDIAN__
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
				#else
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &cblueTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &credTable, (Pixel_8*) &alphaTable, 0);
				#endif
			}
			else
			{
				#if __BIG_ENDIAN__
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) rT, (Pixel_8*) gT, (Pixel_8*) bT, 0);
				#else
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) bT, (Pixel_8*) gT, (Pixel_8*) rT, (Pixel_8*) &alphaTable, 0);
				#endif
			}
		}
		else if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
		{
			unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
			long i;
			
			vImage_Buffer src, dest;
			
			[curDCM changeWLWW :curWL: curWW];
			
			src.height = [curDCM pheight];
			src.width = [curDCM pwidth];
			src.rowBytes = [curDCM rowBytes];
			src.data = [curDCM baseAddr];
			
			dest.height = [curDCM pheight];
			dest.width = [curDCM pwidth];
			dest.rowBytes = [curDCM rowBytes];
			dest.data = [curDCM baseAddr];
			
			for( i = 0; i < 256; i++)
			{
				credTable[ i] = rT[ i] * redFactor;
				cgreenTable[ i] = gT[ i] * greenFactor;
				cblueTable[ i] = bT[ i] * blueFactor;
			}
			#if __BIG_ENDIAN__
			vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
			#else
			vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &cblueTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &credTable, (Pixel_8*) &alphaTable, 0);
			#endif

		}
	}
	else if( (colorTransfer == YES) || (blending == YES))
	{
		if( *colorBufPtr)
		{
			free( *colorBufPtr);
		}
		*colorBufPtr = malloc( [curDCM rowBytes] * [curDCM pheight] * 4);
		
		vImage_Buffer src8, dest8;
		
		src8.height = [curDCM pheight];
		src8.width = [curDCM pwidth];
		src8.rowBytes = [curDCM rowBytes];
		src8.data = [curDCM baseAddr];
		
		dest8.height = [curDCM pheight];
		dest8.width = [curDCM pwidth];
		dest8.rowBytes = [curDCM rowBytes]*4;
		dest8.data = *colorBufPtr;
		
		vImageConvert_Planar8toARGB8888(&src8, &src8, &src8, &src8, &dest8, 0);
		
		if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
		{
			unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
			long i;
			
			for( i = 0; i < 256; i++)
			{
				credTable[ i] = rT[ i] * redFactor;
				cgreenTable[ i] = gT[ i] * greenFactor;
				cblueTable[ i] = bT[ i] * blueFactor;
			}
			vImageTableLookUp_ARGB8888( &dest8, &dest8, (Pixel_8*) &alphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
		}
		else vImageTableLookUp_ARGB8888( &dest8, &dest8, (Pixel_8*) &alphaTable, (Pixel_8*) rT, (Pixel_8*) gT, (Pixel_8*) bT, 0);
	}
	
    glEnable(TEXTRECTMODE);

	char*			baseAddr = 0L;
	int				rowBytes = 0;

	if( [curDCM isRGB] == YES || [curDCM thickSlabVRActivated] == YES)
	{
		textureWidth = [curDCM rowBytes]/4;
		rowBytes = [curDCM rowBytes];
		baseAddr = [curDCM baseAddr];
	}
    else
	{
		if( FULL32BITPIPELINE)
		{
			textureWidth = [curDCM pwidth];
			rowBytes = [curDCM rowBytes]*4;
			baseAddr = (char*) [curDCM fImage];
		}
		else
		{
			textureWidth = [curDCM rowBytes];
			rowBytes = [curDCM rowBytes];
			baseAddr = [curDCM baseAddr];
		}
	}
	
	textureHeight = [curDCM pheight];
	
    glPixelStorei (GL_UNPACK_ROW_LENGTH, textureWidth); // set image width in groups (pixels), accounts for border this ensures proper image alignment row to row
    // get number of textures x and y
    // extract the number of horiz. textures needed to tile image
    *tX = GetTextureNumFromTextureDim (textureWidth, maxTextureSize, false, f_ext_texture_rectangle); //OVERLAP
    // extract the number of horiz. textures needed to tile image
    *tY = GetTextureNumFromTextureDim (textureHeight, maxTextureSize, false, f_ext_texture_rectangle); //OVERLAP
	
	texture = (GLuint *) malloc ((long) sizeof (GLuint) * *tX * *tY);
	
//	NSLog( @"%d %d - No Of Textures: %d", textureWidth, textureHeight, *tX * *tY);
	if( *tX * *tY > 1) NSLog(@"NoOfTextures: %d", *tX * *tY);
	glTextureRangeAPPLE(TEXTRECTMODE, textureWidth * textureHeight * 4, baseAddr);
	glGenTextures (*tX * *tY, texture); // generate textures names need to support tiling
    {
            long x, y, k = 0, offsetY, offsetX = 0, currWidth, currHeight; // texture iterators, texture name iterator, image offsets for tiling, current texture width and height
            for (x = 0; x < *tX; x++) // for all horizontal textures
            {
				currWidth = GetNextTextureSize (textureWidth - offsetX, maxTextureSize, f_ext_texture_rectangle); // use remaining to determine next texture size 
				
				offsetY = 0; // reset vertical offest for every column
				for (y = 0; y < *tY; y++) // for all vertical textures
				{
					unsigned char * pBuffer;
					
					if( [curDCM isRGB] == YES || [curDCM thickSlabVRActivated] == YES)
					{
						pBuffer =   (unsigned char*) baseAddr +			//baseAddr
									offsetY * rowBytes +      //depth
									offsetX * 4;							//depth
					}
					else if( (colorTransfer == YES) || (blending == YES))
						pBuffer =  *colorBufPtr +			//baseAddr
									offsetY * rowBytes * 4 +      //depth
									offsetX * 4;							//depth
									
					else
					{
						if( FULL32BITPIPELINE)
						{
							pBuffer =  (unsigned char*) baseAddr +			
										offsetY * rowBytes*4 +      
										offsetX;
						}
						else
						{
							pBuffer =  (unsigned char*) baseAddr +			
										offsetY * rowBytes +      
										offsetX;
						}
					}
					currHeight = GetNextTextureSize (textureHeight - offsetY, maxTextureSize, f_ext_texture_rectangle); // use remaining to determine next texture size
					glBindTexture (TEXTRECTMODE, texture[k++]);
					
					glTexParameterf (TEXTRECTMODE, GL_TEXTURE_PRIORITY, 1.0f);
					
					if (f_ext_client_storage) glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);	// Incompatible with GL_TEXTURE_STORAGE_HINT_APPLE
					else  glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 0);
					
					if (f_arb_texture_rectangle && f_ext_texture_rectangle)
					{
						if( textureWidth > 2048 && textureHeight > 2048 || [self class] == [OrthogonalMPRPETCTView class] || [self class] == [OrthogonalMPRView class])
						{
							glTexParameteri (TEXTRECTMODE, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);		//<- this produce 'artefacts' when changing WL&WW for small matrix in RGB images... if	GL_UNPACK_CLIENT_STORAGE_APPLE is set to 1
						}
					}
						
					if( NOINTERPOLATION)
					{
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
					}
					else
					{
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
					}
					glTexParameteri (TEXTRECTMODE, GL_TEXTURE_WRAP_S, edgeClampParam);
					glTexParameteri (TEXTRECTMODE, GL_TEXTURE_WRAP_T, edgeClampParam);
					
					glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
					
					if( FULL32BITPIPELINE)
					{					
						#if __BIG_ENDIAN__
						if( [curDCM isRGB] == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
						#else
						if( [curDCM isRGB] == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, pBuffer);
						#endif
						else if( (colorTransfer == YES) | (blending == YES)) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
						else
						{
							NSLog( @"FLOAT");
							float min = curWL - curWW / 2;
							float max = curWL + curWW / 2;
							
							glPixelTransferf( GL_RED_BIAS, -min/(max-min));
//							glPixelTransferf( GL_GREEN_BIAS, -min/(max-min));
//							glPixelTransferf( GL_BLUE_BIAS, -min/(max-min));

							glPixelTransferf( GL_RED_SCALE, 1./(max-min));
//							glPixelTransferf( GL_GREEN_SCALE,  1./(max-min));
//							glPixelTransferf( GL_BLUE_SCALE,  1./(max-min));
							
							glTexImage2D (TEXTRECTMODE, 0, GL_LUMINANCE_FLOAT32_APPLE, currWidth, currHeight, 0, GL_LUMINANCE, GL_FLOAT, pBuffer);
							//GL_RGBA, GL_LUMINANCE, GL_INTENSITY12, GL_INTENSITY16, GL_LUMINANCE12, GL_LUMINANCE16, 
							// GL_LUMINANCE_FLOAT16_APPLE, GL_LUMINANCE_FLOAT32_APPLE, GL_RGBA_FLOAT32_APPLE, GL_RGBA_FLOAT16_APPLE
						
							glPixelTransferf( GL_RED_BIAS, 0);		//glPixelTransferf( GL_GREEN_BIAS, 0);		glPixelTransferf( GL_BLUE_BIAS, 0);
							glPixelTransferf( GL_RED_SCALE, 1);		//glPixelTransferf( GL_GREEN_SCALE, 1);		glPixelTransferf( GL_BLUE_SCALE, 1);

						}
					}
					else
					{
						#if __BIG_ENDIAN__
						if( [curDCM isRGB] == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
						#else
						if( [curDCM isRGB] == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, pBuffer);
						#endif
						else if( (colorTransfer == YES) | (blending == YES)) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
						else glTexImage2D (TEXTRECTMODE, 0, GL_INTENSITY8, currWidth, currHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pBuffer);
					}
					
					offsetY += currHeight;// - 2 * 1; // OVERLAP, offset in for the amount of texture used, 
					//  since we are overlapping the effective texture used is 2 texels less than texture width
				}
				offsetX += currWidth;// - 2 * 1; // OVERLAP, offset in for the amount of texture used, 
				//  since we are overlapping the effective texture used is 2 texels less than texture width
            }
    }
    glDisable (TEXTRECTMODE);
	
	return texture;
}

- (void) sliderAction2DMPR:(id) sender
{
long	x = curImage;
BOOL	lowRes = NO;

	if( [[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseDragged) lowRes = YES;
	
	if( flippedData) curImage = [dcmPixList count] -1 -[sender intValue];
	else  curImage = [sender intValue];
	
	if( curImage < 0) curImage = 0;
	if( curImage >= [dcmPixList count]) curImage = [dcmPixList count]-1;
	
	[self setIndex:curImage];
	
//	[self sendSyncMessage:curImage - x];
	
	if( lowRes) [[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object:stringID userInfo:  [NSDictionary dictionaryWithObject:@"dragged" forKey:@"action"]];
	else [[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object:stringID userInfo:  [NSDictionary dictionaryWithObject:@"slider" forKey:@"action"]];
}

- (IBAction) sliderRGBFactor:(id) sender
{
	switch( [sender tag])
	{
		case 0: redFactor = [sender floatValue];  break;
		case 1: greenFactor = [sender floatValue];  break;
		case 2: blueFactor = [sender floatValue];  break;
	}
	
	[curDCM changeWLWW :curWL: curWW];
	
	[self loadTextures];
	[self setNeedsDisplay:YES];
}

- (void) sliderAction:(id) sender
{
//NSLog(@"DCMView sliderAction");
	long	x = curImage;//x = curImage before sliderAction

	if( flippedData) curImage = [dcmPixList count] -1 -[sender intValue];
    else curImage = [sender intValue];
		
	[self setIndex:curImage];
	
	[self sendSyncMessage:curImage - x];
	
	if( [self is2DViewer] == YES)
	{
		[[self windowController] propagateSettings];
		[[self windowController] adjustKeyImage];
	}
			
	if( [stringID isEqualToString:@"FinalView"] == YES) [self blendingPropagate];
}

- (void) changeGLFontNotification:(NSNotification*) note
{
	[[self openGLContext] makeCurrentContext];
	
	glDeleteLists (fontListGL, 150);
	fontListGL = glGenLists (150);
	
	[fontGL release];

	fontGL = [[NSFont fontWithName: [[NSUserDefaults standardUserDefaults] stringForKey:@"FONTNAME"] size: [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"]] retain];
	if( fontGL == 0L) fontGL = [[NSFont fontWithName:@"Geneva" size:14] retain];
	
	[fontGL makeGLDisplayListFirst:' ' count:150 base: fontListGL :fontListGLSize :NO];
	stringSize = [DCMView sizeOfString:@"B" forFont:fontGL];
	
	[stringTextureCache release];
	stringTextureCache = 0L;
	
	[self setNeedsDisplay:YES];
}

- (void)changeFont:(id)sender
{
    NSFont *oldFont = fontGL;
    NSFont *newFont = [sender convertFont:oldFont];
	
	[[NSUserDefaults standardUserDefaults] setObject: [newFont fontName] forKey: @"FONTNAME"];
	[[NSUserDefaults standardUserDefaults] setFloat: [newFont pointSize] forKey: @"FONTSIZE"];
	[NSFont resetFont: NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"changeGLFontNotification" object: sender];
}

- (void)loadTextures
{
    [[self openGLContext] makeCurrentContext];
	
	pTextureName = [self loadTextureIn:pTextureName blending:NO colorBuf:&colorBuf textureX:&textureX textureY:&textureY redTable: redTable greenTable:greenTable blueTable:blueTable];
	
	if( blendingView)
	{
		if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
			blendingTextureName = [blendingView loadTextureIn:blendingTextureName blending:YES colorBuf:&blendingColorBuf textureX:&blendingTextureX textureY:&blendingTextureY redTable: PETredTable greenTable:PETgreenTable blueTable:PETblueTable];
		else
			blendingTextureName = [blendingView loadTextureIn:blendingTextureName blending:YES colorBuf:&blendingColorBuf textureX:&blendingTextureX textureY:&blendingTextureY redTable:0L greenTable:0L blueTable:0L];
	}
}

- (BOOL)becomeFirstResponder{	

	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMNewImageViewResponder" object: self userInfo: 0L];
	if (curImage < 0)
		if( listType == 'i') [self setIndex:0];
	else [self setIndexWithReset:0 :YES];
	
	isKeyView = YES;
	[self setNeedsDisplay:YES];
	
	return YES;
}

//- (BOOL)resignFirstResponder{
//	isKeyView = NO;
//	return [super resignFirstResponder];
//}

//- (void)changeColor:(id)sender{
//	NSLog(@"changed color");
//	[fontColor release];
//	fontColor = [[(NSColorPanel *)sender color] retain];	
//	[self setNeedsDisplay:YES];
//	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:fontColor  forKey:@"fontColor"];
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMNewFontColor" object: self userInfo: 0L];
//}
//
//-(void)setFontColor:(NSNotification *)note{
//	if ([note object] != self) {
//		[fontColor release];
//		fontColor = [[note userInfo] objectForKey:@"fontColor"];	
//		[self setNeedsDisplay:YES];
//	}
//}
	
// ** TILING SUPPORT

- (id)initWithFrame:(NSRect)frame {

	[AppController initialize];
	
	[DCMView setDefaults];
	
	return [self initWithFrame:frame imageRows:1  imageColumns:1];

}

- (id)initWithFrame:(NSRect)frame imageRows:(int)rows  imageColumns:(int)columns{
	self = [self initWithFrameInt:frame];
    if (self)
	{
		drawing = YES;
        _tag = 0;
		_imageRows = rows;
		_imageColumns = columns;
		isKeyView = NO;
		[self setAutoresizingMask:NSViewMinXMargin];
		
		noScale = NO;
		flippedData = NO;
		
		//notifications
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
           selector: @selector(updateCurrentImage:)
               name: @"DCMUpdateCurrentImage"
             object: nil];
		[nc addObserver: self
           selector: @selector(updateImageTiling:)
               name: @"DCMImageTilingHasChanged"
             object: nil];
			 /*
		[nc addObserver: self
           selector: @selector(newImageViewisKey:)
               name: @"DCMNewImageViewResponder"
             object: nil];
			 */
    }
    return self;

}

-(BOOL) flippedData
{
	return flippedData;
}

-(void) setFlippedData:(BOOL) f
{
	flippedData = f;
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSiz
{
	if( [self is2DViewer] != YES)
	{
		[super resizeWithOldSuperviewSize:oldBoundsSiz];
		return;
	}
	NSRect superFrame = [[self superview] bounds];
	float newWidth = superFrame.size.width / _imageColumns;
	float newHeight = superFrame.size.height / _imageRows;
	float newY = newHeight * (int)(_tag / _imageColumns);
	float newX = newWidth * (int)(_tag % _imageColumns);
	NSRect newFrame = NSMakeRect(newX, newY, newWidth, newHeight);
	//NSLog(@"newFrame:x:%f y:%f  width:%f  height:%f", newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
	[self setFrame:newFrame];
	[self reshape];
	//[self resetCursorRects];
	[self setNeedsDisplay:YES];
}

-(void)keyUp:(NSEvent *)theEvent
{
	[super keyUp:theEvent];
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"];
	[nc postNotificationName: @"DCMUpdateCurrentImage" object: self userInfo: userInfo];
}

-(void) setRows:(int)rows columns:(int)columns
{
	if( _imageRows == 1 && _imageColumns == 1 && rows == 1 && columns == 1)
	{
		NSLog(@"No Resize");
		return;
	}
	_imageRows = rows;
	_imageColumns = columns;
	NSRect rect = [[self superview] bounds];
	[self resizeWithOldSuperviewSize:rect.size];
	[self setNeedsDisplay:YES];
}

-(void)setTag:(long)aTag{
	_tag = aTag;
}
- (long)tag{
	return _tag;
}
-(float)curWW{
	return curWW;
}
-(float)curWL{
	return curWL;
}

- (int)rows{
	return _imageRows;
}
- (int)columns{
	return _imageColumns;
}

-(DCMView *)blendingView{
	return blendingView;
}

- (float)blendingMode{
	return blendingMode;
}

- (float)blendingFactor{
	return blendingFactor;
}

-(void)setImageParamatersFromView:(DCMView *)aView
{
	if (aView != self)
	{
		int offset = [self tag] - [aView tag];
		curImage = [aView curImage] + offset;
		//get Image
		if (curImage >= [dcmPixList count])
			curImage = -1;
		else if (curImage < 0)
			curImage = -1;
		
		if( ([[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"CR"] && IndependentCRWLWW) || COPYSETTINGSINSERIES == NO)
		{
			
		}
		else
		{
			//set ww/wl
				curWW = [aView curWW];
				curWL = [aView curWL];
			//scale
				[self setScaleValue: [aView scaleValue]];
				//scaleValue = [aView scaleValue];
			//rotation
				rotation = [aView rotation];
			//translate
				origin = [aView origin];
		}
		[self setXFlipped: [aView xFlipped]];
		[self setYFlipped: [aView yFlipped]];
		
		if( curImage < 0) return;
		
		//blending
		if (blendingView != [aView blendingView])
			[self setBlending:[aView blendingView]];
		if (blendingFactor != [aView blendingFactor])
			[self setBlendingFactor:[aView blendingFactor]];
		if (blendingMode != [aView blendingMode])
			[self setBlendingMode:[aView blendingMode]];
		//[self setIndex:curImage];
		if( listType == 'i') [self setIndex:curImage];
		else [self setIndexWithReset:curImage :YES];
		
		
		
		// CLUT
		unsigned char *aR, *aG, *aB;
		[aView getCLUT: &aR :&aG :&aB];
		[self setCLUT:aR :aG: aB];
		
		[self setIndex:[self curImage]];
		
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)resignFirstResponder{
	isKeyView = NO;
	[self setNeedsDisplay:YES];
	return [super resignFirstResponder];
}


//notifications

-(void) updateCurrentImage: (NSNotification*) note{

	if( stringID == 0L)
	{
		DCMView *object = [note object];
		if ([[[note object] superview] isEqual:[self superview]] && ![object isEqual: self]) 
			[self setImageParamatersFromView:object];
	}
}

-(void)updateImageTiling:(NSNotification *)note{
	if ([[self window] isKeyWindow]) 
		[self setRows:[[[note userInfo] objectForKey:@"Rows"] intValue] columns:[[[note userInfo] objectForKey:@"Columns"] intValue]];
}

-(void)newImageViewisKey:(NSNotification *)note{
	if ([note object] != self)
		isKeyView = NO;
}
//cursor methods

- (void) resetCursorRects
{
	[self addCursorRect:[self bounds] cursor: cursor];
}

- (NSCursor *)cursor{
    return cursor;
}

-(void) setCursorForView: (long) tool
{
	NSCursor	*c;
	
	if ([self roiTool:tool])
		c = [NSCursor crosshairCursor];
	else if (tool == tTranslate)
		c = [NSCursor openHandCursor];
	else if (tool == tRotate)
		c = [NSCursor rotateCursor];
	else if (tool == tZoom)
		c = [NSCursor zoomCursor];
	else if (tool == tWL)
		c = [NSCursor contrastCursor];
	else if (tool == tNext)
		c = [NSCursor stackCursor];
	else if (tool == tText)
		c = [NSCursor IBeamCursor];
	else if (tool == t3DRotate)
		c = [NSCursor crosshairCursor];
	else if (tool == tCross)
		c = [NSCursor crosshairCursor];
	else if (tool == tRepulsor)
		c = [NSCursor crosshairCursor];
	else if (tool == tROISelector)
		c = [NSCursor crosshairCursor];
	else	
		c = [NSCursor arrowCursor];
		
	if( c != cursor)
	{
		[cursor release];
		
		cursor = [c retain];
		
		[[self window] invalidateCursorRectsForView: self];
	}
}

/*
*  Formula K(SUV)=K(Bq/cc)*(Wt(kg)/Dose(Bq)*1000 cc/kg 
*						  
*  Where: K(Bq/cc) = is a pixel value calibrated to Bq/cc and decay corrected to scan start time
*		 Dose = the injected dose in Bq at injection time (This value is decay corrected to scan start time. The injection time must be part of the dataset.)
*		 Wt = patient weight in kg
*		 1000=the number of cc/kg for water (an approximate conversion of patient weight to distribution volume)
*/

- (float) getBlendedSUV
{
	if( [[blendingView curDCM] SUVConverted]) return blendingPixelMouseValue;
	
	if( [[[blendingView curDCM] units] isEqualToString:@"CNTS"]) return blendingPixelMouseValue * [[blendingView curDCM] philipsFactor];
	return blendingPixelMouseValue * [[blendingView curDCM] patientsWeight] * 1000. / [[blendingView curDCM] radionuclideTotalDoseCorrected];
}

- (float)getSUV
{
	if( [curDCM SUVConverted]) return pixelMouseValue;
	
	if( [[curDCM units] isEqualToString:@"CNTS"]) return pixelMouseValue * [curDCM philipsFactor];
	else return pixelMouseValue * [curDCM patientsWeight] * 1000. / [curDCM radionuclideTotalDoseCorrected];
}

- (float)mouseXPos {
	return mouseXPos;
}

- (float)mouseYPos {
	return mouseYPos;
}

+ (void)setPluginOverridesMouse: (BOOL)override {
	pluginOverridesMouse = override;
}

- (GLuint)fontListGL {
	return fontListGL;
}

- (IBOutlet)actualSize:(id)sender{
	origin.x = origin.y = 0;
	rotation = 0;
	[self setScaleValue:1];
	//scaleValue = 1;
}
- (BOOL)eraserFlag
{
	return eraserFlag;
}
- (void)setEraserFlag: (BOOL)aFlag
{
	eraserFlag = aFlag;
}

- (NSFont*)fontGL {
	return fontGL;
}

//Database links
- (NSManagedObject *)imageObj
{
	if( stringID == 0L)
	{
		if( curDCM)	return [curDCM imageObj];
		else return 0L;
	}
	else return 0L;
}

- (NSManagedObject *)seriesObj
{
	if( stringID == 0L || [stringID isEqualToString:@"previewDatabase"])
	{
		if( curDCM) return [curDCM seriesObj];
		else return 0L;
	}
	else return 0L;
}

- (void)updatePresentationStateFromSeries{
	//get Presentation State info from series Object
	id series = [self seriesObj];
	if( series)
	{
		//NSLog(@"Series for DCMView: %@", [series valueForKey:@"seriesInstanceUID"]);
		[self setXFlipped: [[series valueForKey:@"xFlipped"] boolValue]];
		[self setYFlipped: [[series valueForKey:@"yFlipped"] boolValue]];
				
		if ([series valueForKey:@"scale"] != 0L && [self is2DViewer] == YES)
			if( [[[self seriesObj] valueForKey:@"scale"] floatValue] > 0.0)
				scaleValue = [[series valueForKey:@"scale"] floatValue];
		
		if( [series valueForKey:@"rotationAngle"])
			rotation = [[series valueForKey:@"rotationAngle"] floatValue];
		
		if ([self is2DViewer] == YES)
		{
			if( [series valueForKey:@"xOffset"]) origin.x = [[series valueForKey:@"xOffset"] floatValue];
			if( [series valueForKey:@"yOffset"]) origin.y = [[series valueForKey:@"yOffset"] floatValue];
		}
		
		if ([[self seriesObj] valueForKey:@"windowWidth"])
		{
			if( [[[self seriesObj] valueForKey:@"windowWidth"] floatValue] != 0.0)
			{
				if( [[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"NM"] == YES))
				{
					float from, to;
					
					switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"DEFAULTPETWLWW"])
					{
						case 0:
							if( [curDCM SUVConverted] == NO)
							{
								curWW = [[[self seriesObj] valueForKey:@"windowWidth"] floatValue];
								curWL = [[[self seriesObj] valueForKey:@"windowLevel"] floatValue];
							}
							else
							{
								if( [self is2DViewer] == YES)
								{
									curWW = [[[self seriesObj] valueForKey:@"windowWidth"] floatValue] * [[self windowController] factorPET2SUV];
									curWL = [[[self seriesObj] valueForKey:@"windowLevel"] floatValue] * [[self windowController] factorPET2SUV];
								}
							}
						break;
						
						case 1:
							from = [curDCM maxValueOfSeries] * [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWFROM"] / 100.;
							to = [curDCM maxValueOfSeries] * [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWTO"] / 100.;
							
							curWW = to - from;
							curWL = from + (curWW/2.);
						break;
						
						case 2:
							if( [curDCM SUVConverted])
							{
								from = [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWFROMSUV"];
								to = [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWTOSUV"];
								
								curWW = to - from;
								curWL = from + (curWW/2.);
							}
							else
							{
								curWW = [[[self seriesObj] valueForKey:@"windowWidth"] floatValue];
								curWL = [[[self seriesObj] valueForKey:@"windowLevel"] floatValue];
							}
						break;
					}
				}
				else
				{
					curWW = [[[self seriesObj] valueForKey:@"windowWidth"] floatValue];
					curWL = [[[self seriesObj] valueForKey:@"windowLevel"] floatValue];
				}
			}
		}
	}
}

- (IBAction)resetSeriesPresentationState:(id)sender{
	id series = [self seriesObj];
	if( series)
	{
		[self setXFlipped: NO];
		[self setYFlipped: NO];

		rotation =  0.0;
		[series setValue:[NSNumber numberWithFloat:0.0] forKey:@"rotationAngle"];
		origin.x = 0.0;
		[series setValue:[NSNumber numberWithFloat:0.0] forKey:@"xOffset"];
		origin.y = 0.0;
		[series setValue:[NSNumber numberWithFloat:0.0] forKey:@"yOffset"];
		
		[self setWLWW:[[self curDCM] savedWL] :[[self curDCM] savedWW]];
		if( [curDCM SUVConverted] == NO)
		{
			
			[series setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
			[series setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
		}
		else
		{
			if( [self is2DViewer] == YES)
			{
				[series setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
				[series setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
			}
		}
		
		[[self seriesObj] setValue:[NSNumber numberWithFloat:0] forKey:@"displayStyle"]; 
		[self scaleToFit];
	}
	[self setNeedsDisplay:YES];
}

- (IBAction)resetImagePresentationState:(id)sender
{
}

//resize Window to a scale of Image Size
-(void)resizeWindowToScale:(float)resizeScale
{
	NSRect frame =  [self frame]; 
	long i;
	float curImageWidth = [curDCM pwidth] * resizeScale;
	float curImageHeight = [curDCM pheight]* resizeScale;
	float frameWidth = frame.size.width;
	float frameHeight = frame.size.height;
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	float newWidth = windowFrame.size.width - (frameWidth - curImageWidth) * _imageColumns;
	float newHeight = windowFrame.size.height - (frameHeight - curImageHeight) * _imageRows;
	float topLeftY = windowFrame.size.height + windowFrame.origin.y;
	NSPoint center;
	center.x = windowFrame.origin.x + windowFrame.size.width/2.0;
	center.y = windowFrame.origin.y + windowFrame.size.height/2.0;
	
	NSArray *screens = [NSScreen screens];
	
	for( i = 0; i < [screens count]; i++)
	{
		if( NSPointInRect( center, [[screens objectAtIndex: i] frame]))
		{
			NSRect	screenFrame = [[screens objectAtIndex: i] visibleFrame];
			
			if( USETOOLBARPANEL || [[NSUserDefaults standardUserDefaults] boolForKey: @"USEALWAYSTOOLBARPANEL"] == YES)
			{
				screenFrame.size.height -= [ToolbarPanelController fixedHeight];
			}
			
			if( newHeight > screenFrame.size.height) newHeight = screenFrame.size.height;
			if( newWidth > screenFrame.size.width) newWidth = screenFrame.size.width;
			
			if( center.y + newHeight/2.0 > screenFrame.size.height)
			{
				center.y = screenFrame.size.height/2.0;
			}
		}
	}
	
	windowFrame.size.height = newHeight;
	windowFrame.size.width = newWidth;

	//keep window centered
	windowFrame.origin.y = center.y - newHeight/2.0;
	windowFrame.origin.x = center.x - newWidth/2.0;
	[[self seriesObj] setValue:[NSNumber numberWithFloat:0] forKey:@"displayStyle"]; 
	
	[window setFrame:windowFrame display:YES];
	[self setScaleValue: resizeScale];
	[self setNeedsDisplay:YES];
}

- (IBAction)resizeWindow:(id)sender{
	// 2006-02-09 masu: resizing a view, which is in fullscreen mode, cuts connection
	// between view and window. When more viewers are open the app will crash.
	// So resizing is only allowed in non fullscreen mode.
	if([[self windowController] FullScreenON] == FALSE)
	{
		float resizeScale = 1.0;
		float curImageWidth = [curDCM pwidth];
		float curImageHeight = [curDCM pheight];
		float widthRatio =  320.0 / curImageWidth ;
		float heightRatio =  320.0 / curImageHeight;
		switch ([sender tag]) {
			case 0: resizeScale = 0.25; // 25%
					break;
			case 1: resizeScale = 0.5;  //50%
					break;
			case 2: resizeScale = 1.0; //Actual Size 100%
					break;
			case 3: resizeScale = 2.0; // 200%
					break;
			case 4: resizeScale = 3.0; //300%
					break;
			case 5: // iPod Video
					resizeScale = (widthRatio <= heightRatio) ? widthRatio : heightRatio;
					break;
		}
		[self resizeWindowToScale:resizeScale];
	}
}

- (void)subDrawRect: (NSRect)aRect {  // Subclassable, default does nothing.
	return;
}

+ (BOOL) display2DMPRLines
{
	return display2DMPRLines;
}


#pragma mark-  PET  Tables
+ (unsigned char*) PETredTable
{
	return PETredTable;
}

+ (unsigned char*) PETgreenTable
{
	return PETgreenTable;
}

+ (unsigned char*) PETblueTable
{
	return PETblueTable;
}

#pragma mark-  Drag and Drop

- (void) startDrag:(NSTimer*)theTimer
{
	NS_DURING
	_dragInProgress = YES;
	NSEvent *event = (NSEvent *)[theTimer userInfo];
	NSLog( [event description]);
	
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard]; 
	NSMutableArray *pbTypes = [NSMutableArray array];
	// The image we will drag 
	NSImage *image;
	if ([event modifierFlags] & NSShiftKeyMask)
		image = [self nsimage: YES];
	else
		image = [self nsimage: NO];
		
	// Thumbnail image and position
	NSPoint event_location = [event locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	local_point.x -= 35;
	local_point.y -= 35;

	NSSize originalSize = [image size];
	
	float ratio = originalSize.width / originalSize.height;
	
	NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize(100, 100/ratio)] autorelease];

	[thumbnail lockFocus];
	[image drawInRect: NSMakeRect(0, 0, 100, 100/ratio) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
	[thumbnail unlockFocus];
	
	if ([event modifierFlags] & NSAlternateKeyMask)
	{	
		[pbTypes addObject: NSFilesPromisePboardType];
	}
	else
	{
		[pbTypes addObject: NSTIFFPboardType];	
	}
	
	if ([self dicomImage])
	{
		[pbTypes addObject:pasteBoardOsiriX];
		[pboard declareTypes:pbTypes  owner:self];
		[pboard setData:nil forType:pasteBoardOsiriX]; 
	}
	else
		[pboard declareTypes:pbTypes  owner:self];

		
	if ([event modifierFlags] & NSAlternateKeyMask) {
		NSRect imageLocation;
		local_point = [self convertPoint:event_location fromView:nil];
		imageLocation.origin =  local_point;
		imageLocation.size = NSMakeSize(32,32);
		[pboard setData:nil forType:NSFilesPromisePboardType]; 
		
		if (destinationImage)
			[destinationImage release];
		destinationImage = [image copy];
		
		[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"jpg"]
            fromRect:imageLocation
            source:self
            slideBack:YES
            event:event];
	} 
	else
	{
		[pboard setData: [[NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] forType:NSTIFFPboardType];
		
		[self dragImage:thumbnail
			at:local_point
			offset:dragOffset
			event:event 
			pasteboard:pboard 
			source:self 
			slideBack:YES];
	}
	
	[image release];

	NS_HANDLER
		NSLog(@"Exception while dragging: %@", [localException description]);
	NS_ENDHANDLER
	
	_dragInProgress = NO;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination{
	NSString *name = [[self dicomImage] valueForKeyPath:@"series.study.name"];
	name = @"OsiriX";
	name = [name stringByAppendingPathExtension:@"jpg"];
	NSArray *array = [NSArray arrayWithObject:name];
	
	NSData *data = [[NSBitmapImageRep imageRepWithData: [destinationImage TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
	NSURL *url = [NSURL  URLWithString:name  relativeToURL:dropDestination];
	[data writeToURL:url  atomically:YES];
	[destinationImage release];
	destinationImage = nil;
	return array;
}

- (void)deleteMouseDownTimer{
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];
	_mouseDownTimer = nil;
	_dragInProgress = NO;
}

//part of Dragging Source Protocol
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
	return NSDragOperationEvery;
}

- (id)dicomImage{
	return [dcmFilesList objectAtIndex:[self indexForPix:curImage]];
}

#pragma mark -
#pragma mark Hot Keys.
//Hot key action
-(BOOL)actionForHotKey:(NSString *)hotKey
{
	BOOL returnedVal = YES;
	
	if ([hotKey length] > 0)
	{
		NSDictionary *userInfo = nil;
		NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"];
		NSArray *wwwlValues = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
		NSArray *wwwl = nil;
		unichar key = [hotKey characterAtIndex:0];
		if( [_hotKeyDictionary objectForKey:hotKey])
		{
			key = [[_hotKeyDictionary objectForKey:hotKey] intValue];
			
			NSLog( @"hot key: %d", key);
			
			int index = 1;
			switch (key){
				case DefaultWWWLHotKeyAction: [self setWLWW:[[self curDCM] savedWL] :[[self curDCM] savedWW]];	// default WW/WL
							break;
				case FullDynamicWWWLHotKeyAction: [self setWLWW:0 :0];												// full dynamic WW/WL
					break;
																							// 1 - 9 will be presets WW/WL
				case Preset1WWWLHotKeyAction: if([wwwlValues count] >= 1) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:0]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:0]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:0] userInfo: 0L];
						}	
						break;
				case Preset2WWWLHotKeyAction: if([wwwlValues count] >= 2) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:1]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:1]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:1] userInfo: 0L];
						}	
						break;
				case Preset3WWWLHotKeyAction: if([wwwlValues count] >= 3) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:2]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:2]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:2] userInfo: 0L];
						}	
						break;
				case Preset4WWWLHotKeyAction: if([wwwlValues count] >= 4) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:3]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:3]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:3] userInfo: 0L];
						}	
						break;
				case Preset5WWWLHotKeyAction: if([wwwlValues count] >= 5) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:4]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:4]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:4] userInfo: 0L];
						}	
						break;
				case Preset6WWWLHotKeyAction: if([wwwlValues count] >= 6) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:5]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:5]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:5] userInfo: 0L];
						}	
						break;
				case Preset7WWWLHotKeyAction: if([wwwlValues count] >= 7) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:6]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:6]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:6] userInfo: 0L];
						}	
						break;
				case Preset8WWWLHotKeyAction: if([wwwlValues count] >= 8) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:7]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:7]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:7] userInfo: 0L];
						}	
						break;
				case Preset9WWWLHotKeyAction: if([wwwlValues count] >= 9) {
								wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex:8]];
								[self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
								if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex:8]];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [wwwlValues objectAtIndex:8] userInfo: 0L];
						}	
						break;
				
				// Flip
				case FlipVerticalHotKeyAction: [self flipVertical:nil];
						break;
				case  FlipHorizontalHotKeyAction: [self flipHorizontal:nil];
						break;
				// mouse functions
				case WWWLToolHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tWL], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case MoveHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tTranslate], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case ZoomHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tZoom], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case RotateHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tRotate], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case ScrollHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tNext], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case LengthHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tMesure], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case AngleHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tAngle], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case RectangleHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tROI], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case OvalHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tOval], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case TextHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tText], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case ArrowHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tArrow], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case OpenPolygonHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tOPolygon], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case ClosedPolygonHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tCPolygon], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case PencilHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tPencil], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case ThreeDPointHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:t3Dpoint], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case PlainToolHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tPlain], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case RepulsorHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tRepulsor], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				
				default:
					returnedVal = NO;
				break;
			}
		}
		else returnedVal = NO;
	}
	else returnedVal = NO;
	
	return returnedVal;
}

#pragma mark -
#pragma mark IMAVManager delegate methods.
#if defined (MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
//#if !__LP64__

// The IMAVManager will call this to ask for the context we'll be providing frames with.
- (void)getOpenGLBufferContext:(CGLContextObj *)contextOut pixelFormat:(CGLPixelFormatObj *)pixelFormatOut {
	NSLog(@"alt context: %@ format: %@", [_alternateContext description], [[self pixelFormat] description]);
    *contextOut = [_alternateContext CGLContextObj];
    *pixelFormatOut = [[self pixelFormat] CGLPixelFormatObj];
}

// The IMAVManager will call this when it wants a frame.
// Note that this will be called on a non-main thread.

- (BOOL)renderIntoOpenGLBuffer:(CVOpenGLBufferRef)buffer onScreen:(int *)screenInOut forTime:(CVTimeStamp*)timeStamp {
	// We ignore the timestamp, signifying that we're providing content for 'now'.
	NSLog(@"renderIntoOpenGLBuffer:");
	// Make sure we agree on the screen ID.
 	CGLContextObj cgl_ctx = [_alternateContext CGLContextObj];
	CGLGetVirtualScreen(cgl_ctx, screenInOut);
	NSLog(@"get virtual screen");
	// Attach the OpenGLBuffer and render into the _alternateContext.
    if (CVOpenGLBufferAttach(buffer, [_alternateContext CGLContextObj], 0, 0, *screenInOut) == kCVReturnSuccess) {
        // In case the buffers have changed in size, reset the viewport.
        NSDictionary *attributes = (NSDictionary *)CVOpenGLBufferGetAttributes(buffer);
        GLfloat width = [[attributes objectForKey:(NSString *)kCVOpenGLBufferWidth] floatValue];
        GLfloat height = [[attributes objectForKey:(NSString *)kCVOpenGLBufferHeight] floatValue];
		NSLog(@"width %f  height %f:", width, height);

		NSLog(@"render");
		// Render!
        [self drawRect:NSMakeRect(0,0,width,height) withContext:_alternateContext];
        return YES;
    } else {
        // This should never happen.  The safest thing to do if it does it return
        // 'NO' (signifying that the frame has not changed).
        return NO;
    }
}

// Callback from IMAVManager asking what pixel format we'll be providing frames in.
- (void)getPixelBufferPixelFormat:(OSType *)pixelFormatOut {
    *pixelFormatOut = kCVPixelFormatType_32ARGB;
}

// This callback is called periodically when we're in the IMAVActive state.
// We copy (actually, re-render) what's currently on the screen into the provided 
// CVPixelBufferRef.
//
// Note that this will be called on a non-main thread. 
- (BOOL) renderIntoPixelBuffer:(CVPixelBufferRef)buffer forTime:(CVTimeStamp*)timeStamp {
    // We ignore the timestamp, signifying that we're providing content for 'now'.
	CVReturn err;
	
	// If the image has not changed since we provided the last one return 'NO'.
    // This enables more efficient transmission of the frame when there is no
    // new information.
	if ([self checkHasChanged])
		return NO;
	
    // Lock the pixel buffer's base address so that we can draw into it.
	if((err = CVPixelBufferLockBaseAddress(buffer, 0)) != kCVReturnSuccess) {
        // This should not happen.  If it does, the safe thing to do is return 
        // 'NO'.
		NSLog(@"Warning, could not lock pixel buffer base address in %s - error %ld", __func__, (long)err);
		return NO;
	}
    @synchronized (self) {
    // Create a CGBitmapContext with the CVPixelBuffer.  Parameters /must/ match 
    // pixel format returned in getPixelBufferPixelFormat:, above, width and
    // height should be read from the provided CVPixelBuffer.
    size_t width = CVPixelBufferGetWidth(buffer); 
    size_t height = CVPixelBufferGetHeight(buffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(buffer),
                                                   width, height,
                                                   8,
                                                   CVPixelBufferGetBytesPerRow(buffer),
                                                   colorSpace,
                                                   kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    // Derive an NSGraphicsContext, make it current, and ask our SlideshowView 
    // to draw.
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
    [NSGraphicsContext setCurrentContext:context];
	//get NSImage and draw in the rect
	
    [self drawImage:[self nsimage:NO] inBounds:NSMakeRect(0.0, 0.0, width, height)];
    [context flushGraphics];
    
    // Clean up - remember to unlock the pixel buffer's base address (we locked
    // it above so that we could draw into it).
    CGContextRelease(cgContext);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    }
    return YES;
}



- (void)drawImage:(NSImage *)image inBounds:(NSRect)rect
{
    // We synchronise to make sure we're not drawing in two threads
    // simultaneously.
   
		[[NSColor blackColor] set];
		NSRectFill(rect);
		
		if (image != nil) {
			NSRect imageBounds = { NSZeroPoint, [image size] };
			float scaledHeight = NSWidth(rect) * NSHeight(imageBounds);
			float scaledWidth  = NSHeight(rect) * NSWidth(imageBounds);
			
			if (scaledHeight < scaledWidth) {
				// rect is wider than image: fit height
				float horizMargin = NSWidth(rect) - scaledWidth / NSHeight(imageBounds);
				rect.origin.x += horizMargin / 2.0;
				rect.size.width -= horizMargin;
			} else {
				// rect is taller than image: fit width
				float vertMargin = NSHeight(rect) - scaledHeight / NSWidth(imageBounds);
				rect.origin.y += vertMargin / 2.0;
				rect.size.height -= vertMargin;
			}
			
			[image drawInRect:rect fromRect:imageBounds operation:NSCompositeSourceOver fraction:fraction];
		}

	//}
}


//#endif
#endif

// The _hasChanged flag is set to 'NO' after any check (by a client of this 
// class), and 'YES' after a frame is drawn that is not identical to the 
// previous one (in the drawInBounds: method).

// Returns the current state of the flag, and sets it to the passed in value.
- (BOOL)_checkHasChanged:(BOOL)flag {
    BOOL hasChanged;
    @synchronized (self) {
        hasChanged = _hasChanged;
        _hasChanged = flag;
    }
    return hasChanged;
}

- (BOOL)checkHasChanged {
    // Calling with 'NO' clears _hasChanged after the call (see above).
    return [self _checkHasChanged:NO];
}

#pragma mark -
#pragma mark Window Controler methods.
- (id)windowController{
	return [[self window] windowController];
}

- (BOOL)is2DViewer{
	// if DCMView was subclassed for the non 2D Viewers. We could just override this method rather than checking to see if the WindowController is 2D
	return [[self windowController] is2DViewer];
	// probably it would  better to check for the class rather than the 2D method in the long run. It just adds an extra method to any controller;
	//if ([[self windowController] isMemberOfClass:[ViewerController class]])
	//	return YES;
	//return NO;
}
@end