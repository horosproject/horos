/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "AppController.h"
#import "StringTexture.h"
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>

#import "ROI.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "ITKSegmentation3D.h"
#import "Notifications.h"
#import "N2Debug.h"
#import "ITKBrushROIFilter.h"

#import "DCMUSRegion.h"   // mapping ultrason

#define CIRCLERESOLUTION 200
#define ROIVERSION 11

static		float					deg2rad = M_PI / 180.0f;
static		float					fontHeight = 0;
static		NSString				*defaultName;
static		int						gUID = 0;

extern long BresLine(int Ax, int Ay, int Bx, int By,long **xBuffer, long **yBuffer);

static float ROIRegionOpacity, ROITextThickness, ROIThickness, ROIOpacity, ROIColorR, ROIColorG, ROIColorB, ROITextColorR, ROITextColorG, ROITextColorB;
static float ROIRegionThickness, ROIRegionColorR, ROIRegionColorG, ROIRegionColorB, ROIArrowThickness;
static BOOL ROITEXTIFSELECTED, ROITEXTNAMEONLY, ROITextIfMouseIsOver, ROIDrawPlainEdge;
static BOOL ROIDefaultsLoaded = NO;
static BOOL splineForROI = NO;
static BOOL displayCobbAngle = NO;

int spline( NSPoint *Pt, int tot, NSPoint **newPt, long **correspondingSegmentPt, double scale)
{
	NSPoint p1, p2;
	long long  i, j;
	double xi, yi;
	long long nb;
	double *px, *py;
	int ok;

	double *a, b, *c, *cx, *cy, *d, *g, *h;
	double bet, *gam;
	double aax, bbx, ccx, ddx, aay, bby, ccy, ddy; // coef of spline

	if( scale > 5) scale = 5;

	// function spline S(x) = a x3 + bx2 + cx + d
	// with S continue, S1 continue, S2 continue.
	// smoothing of a closed polygon given by a list of points (x,y)
	// we compute a spline for x and a spline for y
	// where x and y are function of d where t is the distance between points

	// compute tridiag matrix
	//   | b1 c1 0 ...                   |   |  u1 |   |  r1 |
	//   | a2 b2 c2 0 ...                |   |  u2 |   |  r2 |
	//   |  0 a3 b3 c3 0 ...             | * | ... | = | ... |
	//   |                  ...          |   | ... |   | ... |
	//   |                an-1 bn-1 cn-1 |   | ... |   | ... |
	//   |                 0    an   bn  |   |  un |   |  rn |
	// bi = 4
	// resolution algorithm is taken from the book : Numerical recipes in C

	// initialization of different vectors
	// element number 0 is not used (except h[0])
	nb  = tot + 2;
	a   = malloc(nb*sizeof(double));	
	c   = malloc(nb*sizeof(double));	
	cx  = malloc(nb*sizeof(double));	
	cy  = malloc(nb*sizeof(double));	
	d   = malloc(nb*sizeof(double));	
	g   = malloc(nb*sizeof(double));	
	gam = malloc(nb*sizeof(double));	
	h   = malloc(nb*sizeof(double));	
	px  = malloc(nb*sizeof(double));	
	py  = malloc(nb*sizeof(double));	

	
	BOOL failed = NO;
	
	if( !a) failed = YES;
	if( !c) failed = YES;
	if( !cx) failed = YES;
	if( !cy) failed = YES;
	if( !d) failed = YES;
	if( !g) failed = YES;
	if( !gam) failed = YES;
	if( !h) failed = YES;
	if( !px) failed = YES;
	if( !py) failed = YES;
	
	if( failed)
	{
		if( a) 		free(a);
		if( c) 		free(c);
		if( cx)		free(cx);
		if( cy)		free(cy);
		if( d) 		free(d);
		if( g) 		free(g);
		if( gam)		free(gam);
		if( h) 		free(h);
		if( px)		free(px);
		if( py)		free(py);
		
		return 0;
	}
	
	//initialisation
	for (i=0; i<nb; i++)
		h[i] = a[i] = cx[i] = d[i] = c[i] = cy[i] = g[i] = gam[i] = 0.0;

	// as a spline starts and ends with a line one adds two points
	// in order to have continuity in starting point
	for (i=0; i<tot; i++)
	{
		px[i+1] = Pt[i].x;// * fZoom / 100;
		py[i+1] = Pt[i].y;// * fZoom / 100;
	}
	px[0] = px[nb-3]; px[nb-1] = px[2];
	py[0] = py[nb-3]; py[nb-1] = py[2];

	// check all points are separate, if not do not smooth
	// this happens when the zoom factor is too small
	// so in this case the smooth is not useful

	ok=TRUE;
	if(nb<3) ok=FALSE;

	for (i=1; i<nb; i++) 
	if (px[i] == px[i-1] && py[i] == py[i-1]) {ok = FALSE; break;}
	if (ok == FALSE)
		failed = YES;
		
	if( failed)
	{
		if( !a) 		free(a);
		if( !c) 		free(c);
		if( !cx)		free(cx);
		if( !cy)		free(cy);
		if( !d) 		free(d);
		if( !g) 		free(g);
		if( !gam)		free(gam);
		if( !h) 		free(h);
		if( !px)		free(px);
		if( !py)		free(py);
		
		return 0;
	}
			 
	// define hi (distance between points) h0 distance between 0 and 1.
	// di distance of point i from start point
	for (i = 0; i<nb-1; i++)
	{
		xi = px[i+1] - px[i];
		yi = py[i+1] - py[i];
		h[i] = (double) sqrt(xi*xi + yi*yi) * scale;
		d[i+1] = d[i] + h[i];
	}

	// define ai and ci
	for (i=2; i<nb-1; i++) a[i] = 2.0 * h[i-1] / (h[i] + h[i-1]);
	for (i=1; i<nb-2; i++) c[i] = 2.0 * h[i] / (h[i] + h[i-1]);

	// define gi in function of x
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(di - di+1) - (yi+1 - yi+2)/(di+1 - di+2)]
	//                      / (di - di+2)
	for (i=1; i<nb-1; i++) 
		g[i] = 6.0 * ( ((px[i-1] - px[i]) / (d[i-1] - d[i])) - ((px[i] - px[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);

	// compute cx vector
	b=4; bet=4;
	cx[1] = g[1]/b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cx[j] = (g[j] - a[j] * cx[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cx[j] -= gam[j+1] * cx[j+1];

	// define gi in function of y
	// gi+1 = 6 * Y[hi, hi+1, hi+2], 
	// Y[hi, hi+1, hi+2] = [(yi - yi+1)/(hi - hi+1) - (yi+1 - yi+2)/(hi+1 - hi+2)]
	//                      / (hi - hi+2)
	for (i=1; i<nb-1; i++)
		g[i] = 6.0 * ( ((py[i-1] - py[i]) / (d[i-1] - d[i])) - ((py[i] - py[i+1]) / (d[i] - d[i+1])) ) / (d[i-1]-d[i+1]);

	// compute cy vector
	b = 4.0; bet = 4.0;
	cy[1] = g[1] / b;
	for (j=2; j<nb-1; j++)
	{
		gam[j] = c[j-1] / bet;
		bet = b - a[j] * gam[j];
		cy[j] = (g[j] - a[j] * cy[j-1]) / bet;
	}
	for (j=(nb-2); j>=1; j--) cy[j] -= gam[j+1] * cy[j+1];

	// OK we have the cx and cy vectors, from that we can compute the
	// coeff of the polynoms for x and y and for each interval
	// S(x) (xi, xi+1)  = ai + bi (x-xi) + ci (x-xi)2 + di (x-xi)3
	// di = (ci+1 - ci) / 3 hi
	// ai = yi
	// bi = ((ai+1 - ai) / hi) - (hi/3) (ci+1 + 2 ci)
	int totNewPt = 0;
	for (i=1; i<nb-2; i++)
	{
		totNewPt++;
		for (j = 1; j <= h[i]; j++) totNewPt++;
	}

	*newPt = calloc(totNewPt, sizeof(NSPoint));
	if( newPt == nil)
	{
		if( !a) 		free(a);
		if( !c) 		free(c);
		if( !cx)		free(cx);
		if( !cy)		free(cy);
		if( !d) 		free(d);
		if( !g) 		free(g);
		if( !gam)		free(gam);
		if( !h) 		free(h);
		if( !px)		free(px);
		if( !py)		free(py);
		
		return 0;
	}
	
	if( correspondingSegmentPt)
	{
		*correspondingSegmentPt = calloc(totNewPt, sizeof(long));
		if( *correspondingSegmentPt == nil)
		{
			free( newPt);
			
			if( !a) 		free(a);
			if( !c) 		free(c);
			if( !cx)		free(cx);
			if( !cy)		free(cy);
			if( !d) 		free(d);
			if( !g) 		free(g);
			if( !gam)		free(gam);
			if( !h) 		free(h);
			if( !px)		free(px);
			if( !py)		free(py);
			
			return 0;
		}
	}
		
	int tt = 0;
	// for each interval
	for (i=1; i<nb-2; i++)
	{
		// compute coef for x polynom
		ccx = cx[i];
		aax = px[i];
		ddx = (cx[i+1] - cx[i]) / (3.0 * h[i]);
		bbx = ((px[i+1] - px[i]) / h[i]) - (h[i] / 3.0) * (cx[i+1] + 2.0 * cx[i]);

		// compute coef for y polynom
		ccy = cy[i];
		aay = py[i];
		ddy = (cy[i+1] - cy[i]) / (3.0 * h[i]);
		bby = ((py[i+1] - py[i]) / h[i]) - (h[i] / 3.0) * (cy[i+1] + 2.0 * cy[i]);

		// compute points in this interval and display
		p1.x = aax;
		p1.y = aay;

		(*newPt)[tt]=p1;
		if( correspondingSegmentPt)
			(*correspondingSegmentPt)[tt]=i-1;
		tt++;
		
		for (j = 1; j <= h[i]; j++)
		{
			p2.x = (aax + bbx * (double)j + ccx * (double)(j * j) + ddx * (double)(j * j * j));
			p2.y = (aay + bby * (double)j + ccy * (double)(j * j) + ddy * (double)(j * j * j));
			(*newPt)[tt]=p2;
			if( correspondingSegmentPt)
				(*correspondingSegmentPt)[tt]=i-1;
			tt++;
		}//endfor points in 1 interval
	}//endfor each interval

	// delete dynamic structures
	free(a);
	free(c);
	free(cx);
	free(cy);
	free(d);
	free(g);
	free(gam);
	free(h);
	free(px);
	free(py);

	return tt;
}

@implementation ROI
@synthesize min = rmin, max = rmax, mean = rmean;
@synthesize textureWidth, textureHeight, textureBuffer, locked, selectable, isAliased, originalIndexForAlias, imageOrigin, pixelSpacingX, pixelSpacingY;
@synthesize textureDownRightCornerX,textureDownRightCornerY, textureUpLeftCornerX, textureUpLeftCornerY;
@synthesize opacity, hidden;
@synthesize name, comments, type, ROImode = mode, thickness;
@synthesize zPositions;
@synthesize clickInTextBox;
@synthesize rect;
@synthesize pix, displayCMOrPixels;
@synthesize curView;
@synthesize mousePosMeasure;
@synthesize rgbcolor = color;
@synthesize parentROI;
@synthesize displayCalciumScoring = _displayCalciumScoring, calciumThreshold = _calciumThreshold;
@synthesize sliceThickness = _sliceThickness;
@synthesize layerReferenceFilePath;
@synthesize layerImage;
@synthesize layerPixelSpacingX, layerPixelSpacingY;
@synthesize textualBoxLine1, textualBoxLine2, textualBoxLine3, textualBoxLine4, textualBoxLine5, textualBoxLine6;
@synthesize groupID, mouseOverROI;
@synthesize isLayerOpacityConstant, canColorizeLayer, displayTextualData, clickPoint;

+(void) setFontHeight: (float) f
{
	fontHeight = f;
}

+(void) saveDefaultSettings
{
	if( ROIDefaultsLoaded)
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
		[[NSUserDefaults standardUserDefaults] setFloat: ROIArrowThickness forKey: @"ROIArrowThickness"];
	}
}

+(void) loadDefaultSettings
{
	ROIRegionOpacity = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionOpacity"];
	if( ROIRegionOpacity < 0.3) ROIRegionOpacity = 0.3;
	
	ROITextThickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROITextThickness"];
	ROIThickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIThickness"];
    if( ROIThickness < 0.3) ROIThickness = 0.3;
    
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
	ROIArrowThickness = [[NSUserDefaults standardUserDefaults] floatForKey: @"ROIArrowThickness"];
	
	ROITEXTIFSELECTED = [[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTIFSELECTED"];
    ROITextIfMouseIsOver = [NSUserDefaults.standardUserDefaults boolForKey: @"ROITextIfMouseIsOver"];
	ROITEXTNAMEONLY = [[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTNAMEONLY"];
	splineForROI = [[NSUserDefaults standardUserDefaults] boolForKey: @"splineForROI"];
	displayCobbAngle = [[NSUserDefaults standardUserDefaults] boolForKey: @"displayCobbAngle"];
    ROIDrawPlainEdge = [[NSUserDefaults standardUserDefaults] boolForKey: @"ROIDrawPlainEdge"];
	
	ROIDefaultsLoaded = YES;
}

+ (BOOL) splineForROI
{
	return splineForROI;
}

-(void)setIsSpline:(BOOL)isSpline {
	_isSpline = isSpline;
	_hasIsSpline = YES;
}

-(BOOL)isSpline {
	return _hasIsSpline? _isSpline : [ROI splineForROI];
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
    return NSMakePoint(a.x*(1.0-r)+b.x*r, a.y*(1.0-r)+b.y*r);
}

+ (float) lengthBetween:(NSPoint) mesureA and :(NSPoint) mesureB
{
    return sqrtf((mesureA.x-mesureB.x)*(mesureA.x-mesureB.x)+(mesureA.y-mesureB.y)*(mesureA.y-mesureB.y));
}

+ (NSPoint) segmentDistToPoint: (NSPoint) segA :(NSPoint) segB :(NSPoint) p
{
    NSPoint p2 = NSMakePoint(segB.x - segA.x, segB.y - segA.y);
    float f = p2.x*p2.x + p2.y*p2.y;
    float u = ((p.x - segA.x) * p2.x + (p.y - segA.y) * p2.y) / f;
    
//    if (u > 1)
//        u = 1;
//    else if (u < 0)
//        u = 0;
    
    float x = segA.x + u * p2.x;
    float y = segA.y + u * p2.y;
    
//    float dx = x - p.x;
//    float dy = y - p.y;
//
//    float length = sqrtf(dx*dx + dy*dy);
    
    return NSMakePoint( x, y);
}

+(NSPoint) positionAtDistance: (float) distance inPolygon:(NSArray*) points
{
	int i = 0;
	float position = 0, ratio;
	NSPoint p;
	
	if( [points count] == 0)
		return NSMakePoint( 0, 0);
	
	if( distance == 0) return [[points objectAtIndex:0] point];
	
	while( position < distance && i < (long)[points count] -1)
	{
		position += [ROI lengthBetween:[[points objectAtIndex:i] point] and:[[points objectAtIndex:i+1] point]];
		i++;
	}
	
	if( position < distance)
	{
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
	
	for( i = 0; i < (long)[points count]-1; i++ )
	{
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
	
	if (abs(distance) > [newPts count]/2)
	{
		if( distance >= 0) reverse = YES;
		else reverse = NO;
	}
	else
	{
		if (distance >= 0) reverse = NO;
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
			if( minxIndex < 0) minxIndex = (long)[newPts count] -1;
		}
	}
	
	return orderedPts;
}

- (BOOL) isValidForVolume
{
    if( type == tCPolygon || type == tOPolygon || type == tPlain || type == tPencil || type == tOval)
        return YES;
    else
        return NO;
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

- (void) setOpacity:(float) a
{
	[self setOpacity: a globally: YES];
}

- (void) setOpacity:(float)newOpacity globally: (BOOL) g
{
	opacity = newOpacity;
	
	if( type == tPlain)
	{
		if( g)
			ROIRegionOpacity = opacity;
	}
	else if(type == tLayerROI)
	{
		while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	}
	else if( g)
		ROIOpacity = opacity;
}

- (DCMPix*)pix
{
	if( pix)
	{
		return pix;
	}
	else
	{
		NSLog( @"----- warning pix == [curView curDCM]");
		
		return pix = [curView.curDCM retain];
	}
}

- (id) initWithCoder:(NSCoder*) coder
{
	long fileVersion;
	
    if( self = [super init])
    {
		uniqueID = [[NSNumber numberWithInt: gUID++] retain];
		groupID = 0.0;
		PointUnderMouse = -1;
		selectedModifyPoint = -1;
		
		fileVersion = [coder versionForClassName: @"ROI"];
		
		parentROI = nil;
		points = [coder decodeObject];
		rect = NSRectFromString( [coder decodeObject]);
		type = [[coder decodeObject] floatValue];
        
        
/////////////////////////////////// OsiriX 6.0 or later ////////////////////////////////
        //tBall,                      //  30
        //tOvalAngle                  //  31
        if (type == 31 || type == 30)
        {
            [self release];
            return nil;
        }
////////////////////////////////////////////////////////////////////////////////////////
        
        
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
		
		if (type == tPlain)
		{
			textureWidth = [[coder decodeObject] intValue];
			[[coder decodeObject] intValue];	// Keep it for backward compatibility & compatibility with encoder
			textureHeight = [[coder decodeObject] intValue];
			[[coder decodeObject] intValue];	// Keep it for backward compatibility & compatibility with encoder
			
			textureUpLeftCornerX = [[coder decodeObject] intValue];
			textureUpLeftCornerY = [[coder decodeObject] intValue];
			textureDownRightCornerX = [[coder decodeObject] intValue];
			textureDownRightCornerY = [[coder decodeObject] intValue];
			
			textureBuffer=(unsigned char*)malloc(textureWidth*textureHeight*sizeof(unsigned char));
			
			@try
			{
				unsigned char* pointerBuff=(unsigned char*)[[coder decodeObject] bytes];
				
				for( int j=0; j<textureHeight; j++ )
				{
					for( int i=0; i<textureWidth; i++ )
						textureBuffer[i+j*textureWidth]=pointerBuff[i+j*textureWidth];
				}
			}
			@catch (NSException * e)
			{
			}
		}
		
		if( fileVersion >= 3)
		{
			zPositions = [coder decodeObject];
		}
		else zPositions = [[NSMutableArray array] retain];
		
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
				
				while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
				//needsLoadTexture2 = YES;
			}
			textualBoxLine1 = [coder decodeObject];
			textualBoxLine2 = [coder decodeObject];
			textualBoxLine3 = [coder decodeObject];
			textualBoxLine4 = [coder decodeObject];
			textualBoxLine5 = [coder decodeObject];
			[textualBoxLine1 retain];
			[textualBoxLine2 retain];
			[textualBoxLine3 retain];
			[textualBoxLine4 retain];
			[textualBoxLine5 retain];
		}

		if (fileVersion >= 7)
		{
			isLayerOpacityConstant = [[coder decodeObject] boolValue];
			canColorizeLayer = [[coder decodeObject] boolValue];
			layerColor = [coder decodeObject];
			if(layerColor)[layerColor retain];
			displayTextualData = [[coder decodeObject] boolValue];
		}
		else displayTextualData = YES;
		
		if (fileVersion >= 8)
		{
			canResizeLayer = [[coder decodeObject] boolValue];
		}
		
		if( fileVersion >= 9)
		{
			selectable = [[coder decodeObject] boolValue];
			locked = [[coder decodeObject] boolValue];
		}
		else
		{
			selectable = YES;
			locked = NO;
		}
		
		if( fileVersion >= 10)
		{
			isAliased = [[coder decodeObject] boolValue];
		}
		else
		{
			isAliased = NO;
		}
		
		if( fileVersion >= 11)
		{
			_isSpline = [[coder decodeObject] boolValue];
			_hasIsSpline = [[coder decodeObject] boolValue];
		}
		else
		{
			_isSpline = NO;
			_hasIsSpline = NO;
		}
        
        
/////////////////////////////////// OsiriX 6.0 or later ////////////////////////////////
        if( fileVersion >= 12)
        {
            /*savedStudyInstanceUID =*/ [[coder decodeObject] copy];
        }
        
        if( fileVersion >= 13 && type == 31/*tOvalAngle*/)
        {
            /*ovalAngle1 =*/ [[coder decodeObject] doubleValue];
            /*ovalAngle2 =*/ [[coder decodeObject] doubleValue];
        }
        
        if( fileVersion >= 14)
            /*roiRotation =*/ [[coder decodeObject] doubleValue];
        
        if( fileVersion >= 15)
            /*zLocation =*/ [[coder decodeObject] doubleValue];
////////////////////////////////////////////////////////////////////////////////////////
		
        
		[points retain];
		[name retain];
		[comments retain];
		[zPositions retain]; 
		mode = ROI_sleep;
		
		previousPoint.x = previousPoint.y = -1000;
		
		stringTex = nil;
		rmean = rmax = rmin = rdev = rtotal = -1;
		Brmean = Brmax = Brmin = Brdev = Brtotal = -1;
		mousePosMeasure = -1;
		
		ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		textArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		
        // init fonts for use with strings
        NSFont * font =[NSFont fontWithName:@"Helvetica" size: 12.0 + thickness*2];
        stanStringAttrib = [[NSMutableDictionary dictionary] retain];
        [stanStringAttrib setObject:font forKey:NSFontAttributeName];
        [stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		[self reduceTextureIfPossible];
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
    
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	ROI *c = [[[self class] allocWithZone: zone] init];
	if( c == nil) return nil;
	
	c->uniqueID = [[NSNumber numberWithInt: gUID++] retain];
	c->groupID = 0.0;
	c->PointUnderMouse = -1;
	c->selectedModifyPoint = -1;
	
	c->parentROI = nil;
	
	NSMutableArray *a = [[NSMutableArray array] retain];
	
	for( MyPoint *p in points)
		[a addObject: [[p copy] autorelease]];
		
	c->points = a;
	
	c->rect = rect;
	c->type = type;
	c->needQuartz = needQuartz;
	c->thickness = thickness;
	c->fill = fill;
	c->opacity = opacity;
	c->color = color;
	c->name = [name copy];
	c->comments = [comments copy];
	c->pixelSpacingX = pixelSpacingX;
	c->imageOrigin = imageOrigin;
	c->pixelSpacingY = pixelSpacingY;
	
	if (c->type == tPlain)
	{
		c->textureWidth = textureWidth;
		c->textureHeight = textureHeight;
		
		c->textureUpLeftCornerX = textureUpLeftCornerX;
		c->textureUpLeftCornerY = textureUpLeftCornerY;
		c->textureDownRightCornerX = textureDownRightCornerX;
		c->textureDownRightCornerY = textureDownRightCornerY;
		
		c->textureBuffer = (unsigned char*) malloc( textureWidth*textureHeight*sizeof(unsigned char));
        if( c->textureBuffer == nil)
        {
            [c autorelease];
            return nil;
        }
		if( c->textureBuffer && textureBuffer)
			memcpy( c->textureBuffer, textureBuffer, textureWidth*textureHeight*sizeof(unsigned char));
	}
	
	NSMutableArray *z = [[NSMutableArray array] retain];
	for( NSNumber *p in zPositions)
		[z addObject: [[p copy] autorelease]];
	c->zPositions = z;
	
	c->offsetTextBox_x = offsetTextBox_x;
	c->offsetTextBox_y = offsetTextBox_y;
	
	c->_calciumThreshold = _calciumThreshold;
	c->_displayCalciumScoring = _displayCalciumScoring;

	c->groupID = groupID;
	if (c->type == tLayerROI)
	{
		c->layerImageJPEG = [layerImageJPEG copy];
		c->layerImage = [[NSImage alloc] initWithData: c->layerImageJPEG];
		
        if( c->layerImage == nil)
            return nil;
        
		while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	}
	c->textualBoxLine1 = [textualBoxLine1 copy];
	c->textualBoxLine2 = [textualBoxLine2 copy];
	c->textualBoxLine3 = [textualBoxLine3 copy];
	c->textualBoxLine4 = [textualBoxLine4 copy];
	c->textualBoxLine5 = [textualBoxLine5 copy];

	c->isLayerOpacityConstant = isLayerOpacityConstant;
	c->canColorizeLayer = canColorizeLayer;
	c->layerColor = [layerColor copy];
	c->displayTextualData = displayTextualData;

	c->canResizeLayer = canResizeLayer;

	c->selectable = selectable;
	c->locked = locked;

	c->isAliased = isAliased;
	
	c->mode = ROI_sleep;
	
	c->previousPoint.x = c->previousPoint.y = -1000;
	
	c->stringTex = nil;
	c->rmean = c->rmax = c->rmin = c->rdev = c->rtotal = -1;
	c->Brmean = c->Brmax = c->Brmin = c->Brdev = c->Brtotal = -1;
	c->mousePosMeasure = -1;
	
	c->ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
	c->textArray = [[NSMutableArray arrayWithCapacity: 10] retain];
	
	// init fonts for use with strings
	NSFont * font =[NSFont fontWithName:@"Helvetica" size: 12.0 + c->thickness*2];
	c->stanStringAttrib = [[NSMutableDictionary dictionary] retain];
	[c->stanStringAttrib setObject:font forKey:NSFontAttributeName];
	[c->stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	
	[c reduceTextureIfPossible];
	
	c->_hasIsSpline = _hasIsSpline;
	c->_isSpline = _isSpline;
	
	return c;
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
		if( layerImageJPEG == nil)
		{
//			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData: [layerImage TIFFRepresentation]];
//			NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.3] forKey:NSImageCompressionFactor];
//	
//			layerImageJPEG = [[imageRep representationUsingType:NSJPEG2000FileType properties:imageProps] retain];	//NSJPEGFileType
			[self generateEncodedLayerImage];
		}
//		if( layerImageWhenSelectedJPEG == nil)
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
	
	// ROIVERSION = 8
	[coder encodeObject:[NSNumber numberWithBool:canResizeLayer]];
	
	// ROIVERSION = 9
	[coder encodeObject:[NSNumber numberWithBool: selectable]];
	[coder encodeObject:[NSNumber numberWithBool: locked]];
	
	// ROIVERSION = 10
	[coder encodeObject:[NSNumber numberWithBool: isAliased]];
	
	// ROIVERSION = 11
	[coder encodeObject:[NSNumber numberWithBool: _isSpline]];
	[coder encodeObject:[NSNumber numberWithBool: _hasIsSpline]];
}

- (NSData*) data
{
	return [NSArchiver archivedDataWithRootObject: self];
}

- (void) deleteTexture:(NSOpenGLContext*) c
{
    NSUInteger index;
    do
    {
        index = [ctxArray indexOfObjectIdenticalTo: c];
        
        if( c && index != NSNotFound)
        {
            GLuint t = [[textArray objectAtIndex: index] intValue];
            CGLContextObj cgl_ctx = [c CGLContextObj];
            if( cgl_ctx == nil)
                return;
            
            if( t)
                (*cgl_ctx->disp.delete_textures)(cgl_ctx->rend, 1, &t);
            
            [ctxArray removeObjectAtIndex: index];
            [textArray removeObjectAtIndex: index];
        }
    } while( index != NSNotFound);
}


- (void) prepareForRelease // We need to unlink the links related to OpenGLContext
{
    [stringTextureCache release];
    stringTextureCache = nil;
    
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	[ctxArray release];
    ctxArray = nil;
	
	if( [textArray count]) NSLog( @"** not all texture were deleted...");
	[textArray release];
    textArray = nil;
}

- (void) dealloc
{
	self.parentROI = nil;
	
	// This autorelease pool is required : postNotificationName seems to keep the self object with an autorelease, creating a conflict with the 'hard' [super dealloc] at the end of this function.
	// We have to drain the pool before !
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:self userInfo: nil];
		[pool release];
	}
	
    [self prepareForRelease];
	
	if (textureBuffer) free(textureBuffer);
	[self textureBufferHasChanged];
    
	[uniqueID release];
	[points release];
	[zPositions release];
	[name release];
	[comments release];
	[stringTex release];
	[stanStringAttrib release];
    [stringTexA release];
    [stringTexB release];
    [stringTexC release];
	[roiLock release];
	roiLock = 0;
	
	[layerImageJPEG release];

	[layerReferenceFilePath release];
	[layerImage release];
	[layerColor release];
	
	[textualBoxLine1 release];
	[textualBoxLine2 release];
	[textualBoxLine3 release];
	[textualBoxLine4 release];
	[textualBoxLine5 release];
	[textualBoxLine6 release];
	
	[parentROI release];
	[pix release];
    
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
	[self setOriginAndSpacing :ipixelSpacingx :ipixelSpacingy :iimageOrigin :sendNotification :YES];
}

- (void) setOriginAndSpacing :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin :(BOOL) sendNotification :(BOOL) inImageCheck
{
	BOOL	change = NO;
	
	if( ipixelSpacingx == 0) return;
	if( ipixelSpacingy == 0) return;
	
	if( pixelSpacingY == 0 || pixelSpacingX == 0)
	{
	
	}
	else
	{
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
		
		long modeSaved = mode;
		mode = ROI_selected;
		
		if( type == tPlain)
		{
			vImage_Buffer	srcVimage, dstVimage;
			
			srcVimage.data = textureBuffer;
			srcVimage.height = textureHeight;
			srcVimage.width = textureWidth;
			srcVimage.rowBytes = textureWidth;
			
			textureWidth *= pixelSpacingX / ipixelSpacingx;
			textureHeight *= pixelSpacingX / ipixelSpacingx;
			
			unsigned char *newBuffer = malloc( textureWidth * textureHeight * sizeof(unsigned char));
			
			dstVimage.height = textureHeight;
			dstVimage.width = textureWidth;
			dstVimage.rowBytes = textureWidth;
			dstVimage.data = newBuffer;
			
			vImageScale_Planar8( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
			
			textureUpLeftCornerX *= pixelSpacingX / ipixelSpacingx;
			textureUpLeftCornerY *= pixelSpacingY / ipixelSpacingy;
			textureDownRightCornerX = textureUpLeftCornerX + textureWidth;
			textureDownRightCornerY = textureUpLeftCornerY + textureHeight;
			
			for( int x = 0 ; x < textureWidth; x++)
			{
				for( int y = 0 ; y < textureHeight; y++)
				{
					if( newBuffer[ y*textureWidth + x] < 127)
						newBuffer[ y*textureWidth + x] = 0;
					else
						newBuffer[ y*textureWidth + x] = 0xFF;
				}
			}
			
			offset.x = (imageOrigin.x - iimageOrigin.x)/pixelSpacingX;
			offset.y = (imageOrigin.y - iimageOrigin.y)/pixelSpacingY;
			
			offset.x *= (pixelSpacingX/ipixelSpacingx);
			offset.y *= (pixelSpacingY/ipixelSpacingy);
			
			[self roiMove:offset :sendNotification];
			
			free( textureBuffer);
			textureBuffer = newBuffer;
            
            [self textureBufferHasChanged];
		}
		else
		{
			offset.x = (imageOrigin.x - iimageOrigin.x)/pixelSpacingX;
			offset.y = (imageOrigin.y - iimageOrigin.y)/pixelSpacingY;
			
			[self roiMove:offset :sendNotification];
			
			if( pix && inImageCheck)
			{
				BOOL inImage = NO;
				NSRect imRect = NSMakeRect( 0, 0, pix.pwidth, pix.pheight);
				NSArray *pts = [self points];
				for( MyPoint* pt in pts)
				{
					if( NSPointInRect( NSMakePoint( pt.x * (pixelSpacingX/ipixelSpacingx), pt.y * (pixelSpacingX/ipixelSpacingx)), imRect))
					{
						inImage = YES;
						break;
					}
				}
				
				if( inImage == NO)
					[self roiMove: NSMakePoint( -offset.x, -offset.y) :sendNotification];
			}
			
			
			rect.origin.x *= (pixelSpacingX/ipixelSpacingx);
			rect.origin.y *= (pixelSpacingY/ipixelSpacingy);
			rect.size.width *= (pixelSpacingX/ipixelSpacingx);
			rect.size.height *= (pixelSpacingY/ipixelSpacingy);
			
			for( int i = 0; i < [points count]; i++)
			{
				NSPoint aPoint = [[points objectAtIndex:i] point];
				
				aPoint.x *= (pixelSpacingX/ipixelSpacingx);
				aPoint.y *= (pixelSpacingY/ipixelSpacingy);
				
				[[points objectAtIndex:i] setPoint: aPoint];
			}
		}
		
		mode = modeSaved;
	}
	
	pixelSpacingX = ipixelSpacingx;
	pixelSpacingY = ipixelSpacingy;
	imageOrigin = iimageOrigin;
	
	if( sendNotification)
	{
		rtotal = -1;
		Brtotal = -1;
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	}
}

- (id) initWithType: (ToolMode) itype :(float) ipixelSpacing :(NSPoint) iimageOrigin
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
        if( tWidth < 0 || tHeight < 0)
            return nil;
        
		textureBuffer=(unsigned char*)malloc(tWidth*tHeight*sizeof(unsigned char));
        
		if( textureBuffer == nil)
            return nil;
		
		// basic init from other rois ...
		uniqueID = [[NSNumber numberWithInt: gUID++] retain];
		groupID = 0.0;
		PointUnderMouse = -1;
		selectedModifyPoint = -1;
		
		ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		textArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		
		selectable = YES;
		locked = NO;
        type = tPlain;
		mode = ROI_sleep;
		parentROI = nil;
		thickness = 2.0;
		opacity = 0.5;
		mousePosMeasure = -1;
		pixelSpacingX = ipixelSpacingx;
		pixelSpacingY = ipixelSpacingy;
		imageOrigin = iimageOrigin;
		points = [[NSMutableArray array] retain];
		zPositions = [[NSMutableArray array] retain];
		comments = [[NSString alloc] initWithString:@""];
		stringTex = nil;
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
		
		memcpy( textureBuffer, tBuff, tHeight*tWidth);
		[self reduceTextureIfPossible];
		
		self.name = tName;
		displayTextualData = YES;
		
		thickness = ROIRegionThickness;	//;
		color.red = ROIRegionColorR;	//;
		color.green = ROIRegionColorG;	//;
		color.blue = ROIRegionColorB;	//;
		opacity = ROIRegionOpacity;		//;
	}
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotNone)
	{
		[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
		[DCMView setDefaults];
	}
		
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	return self;
}

- (id) initWithType: (ToolMode) itype :(float) ipixelSpacingx :(float) ipixelSpacingy :(NSPoint) iimageOrigin
{
	self = [super init];
    if (self)
	{
		uniqueID = [[NSNumber numberWithInt: gUID++] retain];
		groupID = 0.0;
		PointUnderMouse = -1;
		selectedModifyPoint = -1;
		
		ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		textArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		
        opacity = 1.0;
		selectable = YES;
		locked = NO;
        type = itype;
		mode = ROI_sleep;
		parentROI = nil;
		
		previousPoint.x = previousPoint.y = -1000;
		
		if( type == tText) thickness = ROITextThickness;
		else if( type == tArrow) thickness = ROIArrowThickness;
		else if( type == tPlain) thickness = ROIRegionThickness;
		else thickness = ROIThickness;
		
		opacity = ROIOpacity;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIOpacity"];
		color.red = ROIColorR;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorR"];
		color.green = ROIColorG;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorG"];
		color.blue = ROIColorB;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIColorB"];
		
		mousePosMeasure = -1;
		
		pixelSpacingX = ipixelSpacingx;
		pixelSpacingY = ipixelSpacingy;
		imageOrigin = iimageOrigin;
		
		points = [[NSMutableArray array] retain];
		zPositions = [[NSMutableArray array] retain];
		
		comments = [[NSString alloc] initWithString:@""];
		
		stringTex = nil;
		rmean = rmax = rmin = rdev = rtotal = -1;
		Brmean = Brmax = Brmin = Brdev = Brtotal = -1;
		
		if( type == tText)
		{
			// init fonts for use with strings
			NSFont * font =[NSFont fontWithName:@"Helvetica" size:12.0 + thickness*2];
			stanStringAttrib = [[NSMutableDictionary dictionary] retain];
			[stanStringAttrib setObject:font forKey:NSFontAttributeName];
			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			self.name = NSLocalizedString( @"Double-Click to edit", nil);	// Recompute the texture
			
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
			textureFirstPoint		=0;
			
			thickness = ROIRegionThickness;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionThickness"];
			color.red = ROIRegionColorR;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorR"];
			color.green = ROIRegionColorG;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorG"];
			color.blue = ROIRegionColorB;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorB"];
			opacity = ROIRegionOpacity;		//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionOpacity"];
			
			self.name = NSLocalizedString( @"Region", nil);
		}
		else if(type == tLayerROI)
		{
			layerReferenceFilePath = @"";
			[layerReferenceFilePath retain];
			layerImage = nil;
//			layerImageWhenSelected = nil;
			layerPixelSpacingX = 1.0 / 72.0 * 25.4; // 1/72 inches in milimeters
			layerPixelSpacingY = layerPixelSpacingX;
			self.name = NSLocalizedString( @"Layer", nil);
			textualBoxLine1 = @"";
			textualBoxLine2 = @"";
			textualBoxLine3 = @"";
			textualBoxLine4 = @"";
			textualBoxLine5 = @"";
			textualBoxLine6 = @"";
			
			[textualBoxLine1 retain];
			[textualBoxLine2 retain];
			[textualBoxLine3 retain];
			[textualBoxLine4 retain];
			[textualBoxLine5 retain];
			[textualBoxLine6 retain];
			
			while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
			//needsLoadTexture2 = NO;
		}
		else
		{
			self.name = NSLocalizedString( @"Unnamed", nil);
		}
		
		displayTextualData = YES;
		
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotNone)
		{
			[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
			[DCMView setDefaults];
		}
    }
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
    return self;
}

-(void)updateLabelFont
{
    [stringTextureCache removeAllObjects];
    [curView setNeedsDisplay: YES];
}

- (StringTexture*) stringTextureForString: (NSString*) str
{
    if( stringTextureCache == nil)
    {
        stringTextureCache = [[NSCache alloc] init];
        stringTextureCache.countLimit = 50;
    }
    
    StringTexture *sT = [stringTextureCache objectForKey: str];
    if( sT == nil)
    {
        NSMutableDictionary *attrib = [NSMutableDictionary dictionary];
        
        NSFont *fontGL = [NSFont fontWithName: [[NSUserDefaults standardUserDefaults] stringForKey:@"LabelFONTNAME"] size: [[NSUserDefaults standardUserDefaults] floatForKey: @"LabelFONTSIZE"]];
        
        [attrib setObject: fontGL forKey:NSFontAttributeName];
        [attrib setObject: [NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        
        
        sT = [[[StringTexture alloc] initWithString: str withAttributes: attrib] autorelease];
        [sT setAntiAliasing: YES];
        [sT genTextureWithBackingScaleFactor: curView.window.backingScaleFactor];
        
        [stringTextureCache setObject: sT forKey: str];
    }
    
    return sT;
}

- (long) maxStringWidth: (NSString*) str max:(long) max
{
	if( str.length == 0)
        return max;
    
	long temp = [[self stringTextureForString: str] texSize].width;
    
	if( temp > max)
        max = temp;
	
	return max;
}

- (void) glStr: (NSString*) str :(float) x :(float) y :(float) line
{
#define MAXLENGTH 300
    
	if( str.length == 0) return;
    if( str.length > MAXLENGTH)
        str = [str substringToIndex: MAXLENGTH];
    
	float xx, yy;
	
	line *= fontHeight*curView.window.backingScaleFactor;
	
	xx = x;
	yy = y + line;
	
    StringTexture *sT= [self stringTextureForString: str];
    
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
    glEnable (GL_TEXTURE_RECTANGLE_EXT);
//    glEnable(GL_BLEND);
//    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    
    long xc, yc;
    xc = xx - 2*curView.window.backingScaleFactor;
    yc = yy-[sT texSize].height;
    
    glColor4f (0, 0, 0, 1.0f);
    [sT drawAtPoint: NSMakePoint( xc+1, yc+1)];
    
    glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
    [sT drawAtPoint: NSMakePoint( xc, yc)];
    
//    glDisable(GL_BLEND);
    glDisable (GL_TEXTURE_RECTANGLE_EXT);
}

-(float) EllipseArea
{
	return fabs (M_PI * rect.size.width*2. * rect.size.height*2.) / 4.;
}

-(float) plainArea
{
    if( textureBuffer == nil)
        return 0;
    
	long x = 0;
	for( long i = 0; i < textureWidth*textureHeight ; i++ )
	{
		if( textureBuffer[i] != 0) x++;
	}
	
	return x;
}

-(float) Area: (NSMutableArray*) pts
{
	float area = 0;

   for( long i = 0 ; i < [pts count] ; i++ )
   {
      long j = (i + 1) % [pts count];
	  
      area += [[pts objectAtIndex:i] x] * [[pts objectAtIndex:j] y];
      area -= [[pts objectAtIndex:i] y] * [[pts objectAtIndex:j] x];
   }

   area *= 0.5f;
   
   return fabs( area );
}

-(float) Area
{
	if( type == tPlain)
	{
		return [self plainArea];
	}
	
	return [self Area: [self splinePoints]];
}

- (double) angleBetween2Lines: (NSPoint) line1pt1 :(NSPoint) line1pt2 : (NSPoint) line2pt1 :(NSPoint) line2pt2
{
    double angle1 = atan2(line1pt1.y - line1pt2.y, line1pt1.x - line1pt2.x);
    double angle2 = atan2(line2pt1.y - line2pt2.y, line2pt1.x - line2pt2.x);
    
    return (angle1 - angle2) * (180. / M_PI);
}

-(float) Angle:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3
{
    float ax,ay,bx,by, val, angle, px = 1, py = 1;
    
    if( pixelSpacingX != 0 && pixelSpacingY != 0) {
        px = pixelSpacingX;
        py = pixelSpacingY;
    }
    
    ax = p2.x*px - p1.x*px;
    ay = p2.y*py - p1.y*py;
    bx = p3.x*px - p1.x*px;
    by = p3.y*py - p1.y*py;
    
    if (ax == 0 && ay == 0)
        return 0;
    
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

// in cm or in pixels if no pixelspacing values
-(float) Length:(NSPoint) mesureA :(NSPoint) mesureB
{
	return [self LengthFrom: mesureA to : mesureB inPixel: NO];
}

// in cm or in pixels if no pixelspacing values
-(float) LengthFrom:(NSPoint) mesureA to:(NSPoint) mesureB inPixel: (BOOL) inPixel
{
//	short yT, xT;
	float mesureLength;
	
//	if( mesureA.x > mesureB.x) { yT = mesureA.y;  xT = mesureA.x;}
//	else {yT = mesureB.y;   xT = mesureB.x;}
	
	{
		double coteA, coteB;
		
		coteA = fabs(mesureA.x - mesureB.x);
		coteB = fabs(mesureA.y - mesureB.y);
		
		if( pixelSpacingX != 0 && pixelSpacingY != 0)
		{
			if( inPixel == NO)
			{
				coteA *= pixelSpacingX;
				coteB *= pixelSpacingY;
			}
		}
		
		if( coteA == 0) mesureLength = coteB;
		else if( coteB == 0) mesureLength = coteA;
		else mesureLength = coteB / (sin (atan( coteB / coteA)));
		
		if( pixelSpacingX != 0 && pixelSpacingY != 0)
		{
			if( inPixel == NO)
			{
				mesureLength /= 10.0;
			}
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
		
	U /= ( LineMag * LineMag);
	
    if( U < -0.01f || U > 1.01f)
	{
		*Distance = 100;
		return 0;
	}
	
    Intersection.x = startPoint.x + U * ( endPoint.x - startPoint.x );
    Intersection.y = startPoint.y + U * ( endPoint.y - startPoint.y );

    *Distance = [self Magnitude: Point :Intersection];
 
    return 1;
}

- (NSPoint) lowerRightPoint
{
	float		xmin, xmax, ymin, ymax;
	NSPoint		result = NSZeroPoint;
	
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
		case tDynAngle:
		case tAxis:
		case tCPolygon:
		case tOPolygon:
		case tPencil:
        case tTAGT:
		
			xmin = xmax = [[points objectAtIndex:0] x];
			ymin = ymax = [[points objectAtIndex:0] y];
			
			for( MyPoint *p in points)
			{
				if( [p x] < xmin) xmin = [p x];
				if( [p x] > xmax) xmax = [p x];
				if( [p y] < ymin) ymin = [p y];
				if( [p y] > ymax) ymax = [p y];
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
        default:;
	}
	
	return result;
}

- (NSMutableArray*) points
{
	if(type == t2DPoint)
	{
		NSMutableArray  *tempArray = [NSMutableArray array];
		MyPoint			*tempPoint;
		
		tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( NSMinX( rect), NSMinY( rect))];
		[tempArray addObject:tempPoint];
		[tempPoint release];
		
		return tempArray;
	}
	
	if(type == tROI)
	{
		NSMutableArray  *tempArray = [NSMutableArray array];
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
		NSMutableArray  *tempArray = [NSMutableArray array];
		MyPoint			*tempPoint;
		float			angle;
		
		for( int i = 0; i < CIRCLERESOLUTION ; i++ )
		{
			angle = i * 2 * M_PI /CIRCLERESOLUTION;
		  
			tempPoint = [[MyPoint alloc] initWithPoint: NSMakePoint( rect.origin.x + rect.size.width*cos(angle), rect.origin.y + rect.size.height*sin(angle))];
			[tempArray addObject:tempPoint];
			[tempPoint release];
		}
		
		return tempArray;
	}
	
	#ifndef OSIRIX_LIGHT
	if( type == tPlain)
	{
		NSMutableArray  *tempArray = [ITKSegmentation3D extractContour:textureBuffer width:textureWidth height:textureHeight];
		
		for( MyPoint *pt in tempArray)
			[pt move: textureUpLeftCornerX :textureUpLeftCornerY];
		
		return tempArray;
	}
	#endif
	
	return points;
}

- (void) setPoints: (NSMutableArray*) pts
{
	if ( type == tROI || type == tOval || type == t2DPoint) return;  // Doesn't make sense to set points for these types.
	
	if( locked) return;
	
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

- (void) addPointUnderMouse: (NSPoint) pt scale:(float) scale
{
    float backingScaleFactor = curView.window.backingScaleFactor;
    
	switch( type)
	{
		case tOPolygon:
		case tCPolygon:
		case tPencil:
		{
			BOOL nearPoint = NO;
			
			// Is it near from existing points?
			for( MyPoint *p in points)
			{
				if( [p isNearToPoint: pt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]])
					nearPoint = YES;
			}
			
			if( nearPoint == NO)
			{
				float distance;
				NSMutableArray *correspondingSegments = nil;
				NSMutableArray *splinePoints = [self splinePoints: scale correspondingSegmentArray: &correspondingSegments];
				
				if( [splinePoints count] > 0)
				{
					int i;
					for( i = 0; i < ([splinePoints count] - 1); i++ )
					{					
						[self DistancePointLine:pt :[[splinePoints objectAtIndex:i] point] : [[splinePoints objectAtIndex:(i+1)] point] :&distance];
						
						if( distance*scale < 5.0)
						{
							// Add a point here, if distant from existing points.
							[points insertObject: [MyPoint point: pt] atIndex: [[correspondingSegments objectAtIndex: i] intValue] +1];
							break;
						}
					}
				}
			}
		}
		default:;
	}
}

- (long) clickInROI:(NSPoint) pt :(float) offsetx :(float) offsety :(float) scale :(BOOL) testDrawRect
{
	NSRect		arect;
	long		imode = ROI_sleep;
	
    if( hidden)
        return ROI_sleep;
    
	if( selectable == NO)
		return ROI_sleep;
	
	if( mode == ROI_drawing)
		return ROI_sleep;
	
	clickInTextBox = NO;
	previousMode = mode;
    
    #define NEIGHBORHOODRADIUS 10.0
    float neighborhoodRad = NEIGHBORHOODRADIUS * curView.window.backingScaleFactor;
    float backingScaleFactor = curView.window.backingScaleFactor;
	
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
                        width = bitmap.pixelsWide;
                        height = bitmap.pixelsHigh;
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
                    float x, y;
                    if (v.x) {
                        y = (c.y-c.x*(v.y/v.x))/(w.y-w.x*(v.y/v.x));
                        x = (c.x-y*w.x)/v.x;
                    } else {
                        y = (c.x-c.y*(v.x/v.y))/(w.x-w.y*(v.x/v.y));
                        x = (c.y-y*w.y)/v.y;
                    }
					
					x *= scaleRatio;
					y *= scaleRatio;
					
					// test if the clicked pixel is not transparent (otherwise the ROI won't be selected)
					// define a neighborhood around the point					
					float xi, yj;
					BOOL found = NO;

					for( int i=-neighborhoodRad; i<=neighborhoodRad && !found; i++ )
					{
						for( int j=-neighborhoodRad; j<=neighborhoodRad && !found; j++ )
						{
							xi = x+i;
							yj = y+j;
							if(xi>=0.0 && yj>=0.0 && xi<width && yj<height)
							{
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
				if (pt.x > textureUpLeftCornerX && pt.x < textureDownRightCornerX && pt.y > textureUpLeftCornerY && pt.y < textureDownRightCornerY)
				{
                    if( textureBuffer[ (int) pt.x - textureUpLeftCornerX + textureWidth * ( (int) pt.y - textureUpLeftCornerY)] > 1)
                    {
                        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
                        {
                            imode = mode;
                            if([curView currentTool] == tPlain)
                                imode = ROI_selectedModify; // tPlain ROIs can only be modified by the tPlain tool
                        }
                        else
                        {
                            imode = ROI_selected;
                        }
                    }
				}
				break;
//			case tOval:
//				arect = NSMakeRect( rect.origin.x -rect.size.width -(neighborhoodRad/2)/scale, rect.origin.y -rect.size.height -(neighborhoodRad/2)/scale, 2*rect.size.width + neighborhoodRad/scale, 2*rect.size.height + neighborhoodRad/scale);
//				
//				if( NSPointInRect( pt, arect))
//                    imode = ROI_selected;
//			break;
			
			
//			case tROI:
//				arect = NSMakeRect( rect.origin.x -(neighborhoodRad/2), rect.origin.y-(neighborhoodRad/2), rect.size.width+neighborhoodRad, rect.size.height+neighborhoodRad);
//				
//				if( NSPointInRect( pt, arect))
//                    imode = ROI_selected;
//			break;
			
            case tROI:
            {
				float distance;
				NSArray *pts = [self points];
				
				if( pts.count > 0)
				{
					for( int i = 0; i < [pts count]; i++ )
					{
                        if( i == pts.count-1) // last point
                            [self DistancePointLine:pt :[[pts objectAtIndex:i] point] : [[pts objectAtIndex: 0] point] :&distance];
						else
                            [self DistancePointLine:pt :[[pts objectAtIndex:i] point] : [[pts objectAtIndex:(i+1)] point] :&distance];
						
						if( distance*scale < neighborhoodRad/2)
						{
							imode = ROI_selected;
							break;
						}
					}
				}
			}
            break;
                
			case t2DPoint:
				arect = NSMakeRect( rect.origin.x - neighborhoodRad/scale, rect.origin.y - neighborhoodRad/scale, neighborhoodRad*2/scale, neighborhoodRad*2/scale);
				
				if( NSPointInRect( pt, arect))
                    imode = ROI_selected;
			break;
			
			case tText:
				arect = NSMakeRect( rect.origin.x - rect.size.width/(2*scale), rect.origin.y - rect.size.height/(2*scale), rect.size.width/scale, rect.size.height/scale);
				
				if( NSPointInRect( pt, arect))
                    imode = ROI_selected;
			break;
			
			
			case tArrow:
			case tMesure:
			{
				float distance;
				
				[self DistancePointLine:pt :[[points objectAtIndex:0] point] : [[points objectAtIndex:1] point] :&distance];
				
				if( distance*scale < neighborhoodRad/2)
					imode = ROI_selected;
			}
			break;
			
			
            case tOval:
			case tOPolygon:
			case tAngle:
			{
				NSMutableArray *splinePoints = [self splinePoints: scale];
				
				if( [splinePoints count] > 0)
				{
					for( int i = 0; i < ([splinePoints count] - 1); i++ )
					{
                        float distance;
						[self DistancePointLine:pt :[[splinePoints objectAtIndex:i] point] : [[splinePoints objectAtIndex:(i+1)] point] :&distance];
						
						if( distance*scale < neighborhoodRad/2)
						{
							imode = ROI_selected;
							break;
						}
					}
                    
                    // Test ROI center
                    if( imode != ROI_selected)
                    {
                        float distance = [self Magnitude: pt :rect.origin];
                        if( distance*scale < neighborhoodRad/2)
						{
							imode = ROI_selected;
							break;
						}
                    }
				}
			}
			break;
			
			case tDynAngle:
			case tAxis:
			case tCPolygon:
			case tPencil:
            case tTAGT:
			{
				float distance;
				NSMutableArray *splinePoints = [self splinePoints: scale];
				
				if( [splinePoints count] > 0)
				{
					int i;
					for( i = 0; i < ([splinePoints count] - 1); i++ )
					{					
						[self DistancePointLine:pt :[[splinePoints objectAtIndex:i] point] : [[splinePoints objectAtIndex:(i+1)] point] :&distance];
						if( distance*scale < neighborhoodRad/2)
						{
							imode = ROI_selected;
							break;
						}
					}
					
					[self DistancePointLine:pt :[[splinePoints objectAtIndex:i] point] : [[splinePoints objectAtIndex:0] point] :&distance];
					if( distance*scale < neighborhoodRad/2)
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
            default:;
		}
	}
	
//	if( imode == ROI_selected)
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
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 1;
				
				aPt.x = rect.origin.x - rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 2;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 3;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y - rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 4;
				
				if( selectedModifyPoint) imode = ROI_selectedModify;
			break;
			
			case tROI:
				selectedModifyPoint = 0;
				
				aPt.x = rect.origin.x;		aPt.y = rect.origin.y;
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 1;
				
				aPt.x = rect.origin.x;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 2;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 3;
				
				aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y;
				if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) selectedModifyPoint = 4;
				
				if( selectedModifyPoint) imode = ROI_selectedModify;
			break;
			
			case tAngle:
			case tArrow:
			case tMesure:
			case tDynAngle:
			case tAxis:
			case tCPolygon:
			case tOPolygon:
			case tPencil:
            case tTAGT:
			{
                if( mode != ROI_selectedModify)
                    selectedModifyPoint = -1;
                
				for( int i = 0 ; i < [points count]; i++ )
				{
					if( [[points objectAtIndex: i] isNearToPoint: pt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]])
					{
						imode = ROI_selectedModify;
						selectedModifyPoint = i;
					}
				}
			}
			break;
            default:;
		}
		
		clickPoint = pt;
		
		[tempPoint release];
	}
	
	return imode;
}

- (void) displayPointUnderMouse:(NSPoint) pt :(float) offsetx :(float) offsety :(float) scale
{
    if( hidden)
        return;
    
	MyPoint		*tempPoint = [[[MyPoint alloc] initWithPoint: pt] autorelease];
	
	int previousPointUnderMouse = PointUnderMouse;
	
	PointUnderMouse = -1;
	NSPoint aPt;
	float backingScaleFactor = curView.window.backingScaleFactor;
    
	switch( type)
	{
		case tOval:
			aPt.x = rect.origin.x - rect.size.width;		aPt.y = rect.origin.y - rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 1;
			
			aPt.x = rect.origin.x - rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 2;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 3;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y - rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 4;
		break;
		
		case tROI:
			aPt.x = rect.origin.x;		aPt.y = rect.origin.y;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 1;
			
			aPt.x = rect.origin.x;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 2;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 3;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y;
			if( [tempPoint isNearToPoint: aPt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]]) PointUnderMouse = 4;
		break;
		
		case tAngle:
		case tArrow:
		case tMesure:
		case tDynAngle:
		case tAxis:
		case tCPolygon:
		case tOPolygon:
		case tPencil:
        case tTAGT:
		{
			for( int i = 0 ; i < [points count]; i++ )
			{
				if( [[points objectAtIndex: i] isNearToPoint: pt :scale/backingScaleFactor :[[curView curDCM] pixelRatio]])
				{
					PointUnderMouse = i;
				}
			}
		}
		break;
        default:;
	}
	
	if( PointUnderMouse != previousPointUnderMouse)
	{
		[curView setNeedsDisplay: YES];
	}
}

- (BOOL)mouseRoiDown:(NSPoint)pt :(float)scale
{
	return [self mouseRoiDown:pt :[curView curImage] :scale];
}

- (BOOL)mouseRoiDownIn:(NSPoint)pt :(int)slice :(float)scale
{
    float backingScaleFactor = curView.window.backingScaleFactor;
	MyPoint	*mypt;
	
	if( selectable == NO)
	{
		mode = ROI_sleep;
		return NO;
	}
	
	if( mode == ROI_sleep)
	{
		mode = ROI_drawing;
	}
	
	if( locked)
	{
		return NO;
	}
	
	if( [self.comments isEqualToString: @"morphing generated"] ) self.comments = @"";
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	
	if (type == tPlain)
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
			
            [self textureBufferHasChanged];
            
			mode = ROI_drawing;
		}
		else
		{
			mode = ROI_selected;
		}
		
		previousPoint = pt;
		
		return NO;
	}
	
	if( type == t2DPoint)
	{
		rect.origin.x = pt.x;
		rect.origin.y = pt.y;
		rect.size.height = 0;
		rect.size.width = 0;
		
		mode = ROI_selected;
		
		return NO;
	}
	else if( type == tText)
	{
		rect.size = [stringTex frameSize];
		rect.origin.x = pt.x;// - rect.size.width/2;
		rect.origin.y = pt.y;// - rect.size.height/2;
		
		if( pixelSpacingX != 0 && pixelSpacingY != 0 )
			rect.size.height *= pixelSpacingX/pixelSpacingY;
		
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
    else if(type == tTAGT)
	{
        NSPoint o = pt;
        
        pt = o;
        pt.x += 20 / scale;
        mypt = [MyPoint point: pt];
		[points addObject: mypt];
        
        pt.y += 40 / scale;
        mypt = [MyPoint point: pt];
		[points addObject: mypt];
        
        pt = o;
        pt.x += 40 / scale;
        mypt = [MyPoint point: pt];
		[points addObject: mypt];
        
        pt.y += 40 / scale;
        mypt = [MyPoint point: pt];
		[points addObject: mypt];
        
        pt = o;
        mypt = [MyPoint point: pt];
		[points addObject: mypt];
        
        pt.x += 100 / scale;
		mypt = [MyPoint point: pt];
		[points addObject: mypt];
        
        [self valid];
		
		mode = ROI_selected;
		
		return NO;
	}
//	else if (type == tPencil)
//	{
//		mode = ROI_selected;
//	}
	else
	{
		if( [[points lastObject] isNearToPoint: pt : scale/(thickness*backingScaleFactor) :[[curView curDCM] pixelRatio]] == NO)
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
			if( [points count] > 2)
                mode = ROI_selected;
		}
	}
	
	if( type == tPencil) return NO;
	
	if( mode == ROI_drawing) return YES;
	else return NO;
}

- (BOOL)mouseRoiDown:(NSPoint)pt :(int)slice :(float)scale
{
	[roiLock lock];
	
	BOOL result = NO;
	
	@try
	{
		result = [self mouseRoiDownIn:pt :slice :scale];
	}
	@catch (NSException * e)
	{
		NSLog( @"**** mouseRoiDown exception %@", e);
	}
	
	[roiLock unlock];
	
	return result;
}

- (void) flipVertically: (BOOL) vertically
{
	if( locked) return;
    
    float new_x, new_y;
	NSMutableArray	*pts = self.points;
	
	if( type == tROI)
	{
		self.isSpline = NO;
	}
	
	if( pts.count > 0)
	{
		if( type == tROI || type == tOval)
		{
			type = tCPolygon;
			[points release];
			points = [pts copy];
		}
		
//		float ratio = [[self pix] pixelRatio];
//		
//		if( ratio == 0)
//			ratio = 1.0;
		
        NSPoint centroid = self.centroid;
        
		for( MyPoint *pt in pts)
		{
            if( vertically)
            {
                new_x = pt.x;
                new_y = -(pt.y - centroid.y) + centroid.y;
			}
            else
            {
                new_x = -(pt.x - centroid.x) + centroid.x;
                new_y = pt.y;
            }
            
			[pt setPoint: NSMakePoint( new_x, new_y)];
		}
		
		rtotal = -1;
		Brtotal = -1;
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	}
}

- (void) rotate: (float) angle :(NSPoint) center
{
	if( locked) return;

    float theta;
    float new_x;
    float new_y;
	float intYCenter, intXCenter;
	NSMutableArray	*pts = self.points;
	
	if( type == tROI)
	{
		self.isSpline = NO;
	}
	
	if( pts.count > 0)
	{
		theta = deg2rad * angle; 
		
		if( type == tROI || type == tOval)
		{
			type = tCPolygon;
			[points release];
			points = [pts copy];
		}
		
		intXCenter = center.x;
		intYCenter = center.y;
		
		float ratio = [[self pix] pixelRatio];
		
		if( ratio == 0)
			ratio = 1.0;
		
		for( MyPoint *pt in pts)
		{ 
			new_x = cos(theta) * ([pt x] - intXCenter) - sin(theta) * ([pt y] - intYCenter)  * ratio;
			new_y = sin(theta) * ([pt x] - intXCenter) + cos(theta) * ([pt y] - intYCenter)  * ratio;
			
			[pt setPoint: NSMakePoint( new_x + intXCenter, new_y / ratio + intYCenter)];
		}
		
		rtotal = -1;
		Brtotal = -1;
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	}
}

- (BOOL)canResize;
{
	if(type == tLayerROI)
		return canResizeLayer;
	else
		return YES;
}

- (void) resize: (float) factor :(NSPoint) center
{
	if(![self canResize]) return;
	
	if( locked) return;
	
    float new_x;
    float new_y;
	float intYCenter, intXCenter;
	NSMutableArray	*pts = self.points;
	
	if( pts.count > 0)
	{
		if( type == tROI || type == tOval)
		{
			intXCenter = center.x;
			intYCenter = center.y;
			
			rect.origin.y = intYCenter + (rect.origin.y - intYCenter) * factor;
			rect.origin.x = intXCenter + (rect.origin.x - intXCenter) * factor;
			
			rect.size.width *= factor;
			rect.size.height *= factor;
		}
		else
		{
			intXCenter = center.x;
			intYCenter = center.y;
			
			for( MyPoint *pt in pts)
			{ 
				new_x = ([pt x] - intXCenter) * factor;
				new_y = ([pt y] - intYCenter) * factor;
				
				[pt setPoint: NSMakePoint( new_x + intXCenter, new_y + intYCenter)];
			}
		}
		
		rtotal = -1;
		Brtotal = -1;
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	}
}

- (BOOL) valid
{
	if( mode == ROI_drawing) return YES;
	
	switch( type)
	{
        case tPlain:
            if( [self plainArea] == 0)
                return NO;
            break;
            
		case tOval:
			if( rect.size.width < 0)
			{
				rect.size.width = -rect.size.width;
			}
			
			if( rect.size.height < 0)
			{
				rect.size.height = -rect.size.height;
			}
			
			if( rect.size.width < 0.2) return NO;
			if( rect.size.height < 0.2) return NO;
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
			
			if( rect.size.width < 0.2) return NO;
			if( rect.size.height < 0.2) return NO;
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
			
			if( ABS([[points objectAtIndex:0] x] - [[points objectAtIndex:1] x]) < 0.2 && ABS([[points objectAtIndex:0] y] - [[points objectAtIndex:1] y]) < 0.2) return NO;
		break;
		
		case tDynAngle:
			if( [points count] < 4) return NO;
		break;
		case tAxis:
			if( [points count] < 4) return NO;
		break;
        case tTAGT:
            if( [points count] < 6) return NO;
            
            // 0-1, 2-3
            
            //Points 2 and must be on the A line
            
            [points replaceObjectAtIndex: 0 withObject: [MyPoint point: [ROI segmentDistToPoint: [[points objectAtIndex: 4] point] :[[points objectAtIndex: 5] point] :[[points objectAtIndex: 1] point]]]];
        
            [points replaceObjectAtIndex: 2 withObject: [MyPoint point: [ROI segmentDistToPoint: [[points objectAtIndex: 4] point] :[[points objectAtIndex: 5] point] :[[points objectAtIndex: 3] point]]]];
        break;
        default:;
	}
	
	return YES;
}

- (void) recompute
{
	rtotal = -1;
	Brtotal = -1;
//	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
}

- (void) roiMove:(NSPoint) offset :(BOOL) sendNotification
{
	if( locked) return;

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
			case tDynAngle:
			case tAxis:
			case tCPolygon:
			case tOPolygon:
			case tMesure:
			case tArrow:
			case tAngle:
			case tPencil:
			case tLayerROI:
            case tTAGT:
				for( int i = 0; i < [points count]; i++) [[points objectAtIndex: i] move: offset.x : offset.y];
			break;
			
			case tPlain:
				textureUpLeftCornerX += (int) offset.x;
				textureUpLeftCornerY += (int) offset.y;
				textureDownRightCornerX += (int) offset.x;
				textureDownRightCornerY += (int) offset.y;
			break;
            default:;
		}
		
		if( sendNotification)
		{
			rtotal = -1;
			Brtotal = -1;
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
		}
	}
}

- (void) roiMove:(NSPoint) offset
{
	[self roiMove:offset :YES];
}

- (BOOL) mouseRoiUp:(NSPoint) pt
{
	return [self mouseRoiUp: pt scaleValue: 1];
}

- (BOOL) mouseRoiUp:(NSPoint) pt scaleValue: (float) scaleValue
{
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: [NSDictionary dictionaryWithObjectsAndKeys:@"mouseUp", @"action", nil]];
	
	previousPoint.x = previousPoint.y = -1000;
	
	if( type == tOval || type == tROI || type == tText || type == tArrow || type == tMesure || type == tPencil || type == t2DPoint || type == tPlain)
	{
		[self reduceTextureIfPossible];
		
		if( mode == ROI_drawing)
		{
			rtotal = -1;
			Brtotal = -1;
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: [NSDictionary dictionaryWithObjectsAndKeys:@"mouseUp", @"action", nil]];
			
			mode = ROI_selected;
			return NO;
		}
	}
	else
	{
		if( mode == ROI_selectedModify) 
			mode = ROI_selected;
	}
	
	if( clickPoint.x == pt.x && clickPoint.y == pt.y && previousMode == mode && (mode == ROI_selected || mode == ROI_selectedModify))
	{
		[self addPointUnderMouse: pt scale: scaleValue];
	}
	
	return YES;
}

- (void) mergeWithTexture: (ROI*) r
{
	if( type != tPlain) return;
	if( r.type != tPlain) return;
	if( self == r) return;
	
	#define min(x,y) ((x<y)? x:y)
	#define max(x,y) ((x>y)? x:y)
	
	int	newTextureUpLeftCornerX = min( textureUpLeftCornerX, r.textureUpLeftCornerX);
	int	newTextureDownRightCornerX = max( textureDownRightCornerX, r.textureDownRightCornerX);
	
	int	newTextureUpLeftCornerY = min( textureUpLeftCornerY, r.textureUpLeftCornerY);
	int	newTextureDownRightCornerY = max( textureDownRightCornerY, r.textureDownRightCornerY);
	
	int newTextureWidth = newTextureDownRightCornerX - newTextureUpLeftCornerX;
	int newTextureHeight = newTextureDownRightCornerY - newTextureUpLeftCornerY;
	
	NSRect aRect = NSMakeRect( textureUpLeftCornerX, textureUpLeftCornerY, textureWidth, textureHeight);
	NSRect bRect = NSMakeRect( r.textureUpLeftCornerX, r.textureUpLeftCornerY, r.textureWidth, r.textureHeight);
	
	unsigned char	*tempBuf = calloc( newTextureWidth * newTextureHeight, sizeof(unsigned char));
	
	for( int y = 0; y < newTextureHeight ; y++)
	{
		for( int x = 0; x < newTextureWidth; x++)
		{
			NSPoint p = NSMakePoint( x + newTextureUpLeftCornerX, y + newTextureUpLeftCornerY);
			
			if( NSPointInRect( p, aRect))
			{
				unsigned char v = *(textureBuffer +  x + newTextureUpLeftCornerX - textureUpLeftCornerX + textureWidth * ( y + newTextureUpLeftCornerY - textureUpLeftCornerY));
				
				if( v)
				{
					*(tempBuf + x + ( y * newTextureWidth)) = v;
				}
			}
			
			if( NSPointInRect( p, bRect))
			{
				unsigned char v = *(r.textureBuffer +  x + newTextureUpLeftCornerX - r.textureUpLeftCornerX + r.textureWidth * ( y + newTextureUpLeftCornerY - r.textureUpLeftCornerY));
				
				if( v)
				{
					*(tempBuf + x + ( y * newTextureWidth)) = v;
				}
			}
		}
	}
	
	textureUpLeftCornerX = newTextureUpLeftCornerX;
	textureDownRightCornerX = newTextureDownRightCornerX;
	textureUpLeftCornerY = newTextureUpLeftCornerY;
	textureDownRightCornerY = newTextureDownRightCornerY;
	
	textureWidth = newTextureWidth;
	textureHeight = newTextureHeight;
	
	free( textureBuffer);
	textureBuffer = tempBuf;
	
	[self reduceTextureIfPossible];
    
    [self textureBufferHasChanged];
}

- (void) textureBufferHasChanged
{
    if( textureBufferSelected)
    {
        free( textureBufferSelected);
        textureBufferSelected = nil;
    }
}

- (BOOL) reduceTextureIfPossible
{
	if( type != tPlain) return YES;
	
	int				minX, maxX, minY, maxY;
	unsigned char	*tempBuf = textureBuffer;
	
    if( tempBuf == nil)
        return NO;
    
	minX = textureWidth;
	maxX = 0;
	minY = textureHeight;
	maxY = 0;
	
	for( int y = 0; y < textureHeight ; y++)
	{
		for( int x = 0; x < textureWidth; x++)
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
	
	if( minX > maxX) return YES;	// means the ROI is empty;
	if( minY > maxY) return YES;	// means the ROI is empty;
	
	#define CUTOFF 8
	
//	NSLog( @"%d %d %d %d", minX, maxX, minY, maxY);
//	NSLog( @"%d %d %d %d", 0, textureWidth, 0, textureHeight);
	
	if( minX > CUTOFF || maxX < textureWidth-CUTOFF || minY > CUTOFF || maxY < textureHeight-CUTOFF)
//	 || textureWidth%4 != 0 || textureHeight%4 != 0)
	{
		minX -= 2;
		minY -= 2;
		maxX += 2;
		maxY += 2;
		
		if( minX < 0) minX = 0;
		if( minY < 0) minY = 0;
		if( maxX-minX > textureWidth) maxX = textureWidth+1+minX;
		if( maxY-minY > textureHeight) maxY = textureHeight+1+minY;
		
		int offsetTextureY = minY;
		int offsetTextureX = minX;
		
		int oldTextureWidth = textureWidth;
		int oldTextureHeight = textureHeight;
		
		textureWidth = maxX - minX+1;
		textureHeight = maxY - minY+1;
		
//		if( textureWidth%4) {textureWidth /=4;		textureWidth *=4;		textureWidth += 4;}
//		if( textureHeight%4) {textureHeight /=4;	textureHeight *=4;		textureHeight += 4;}
		
		if( textureWidth > oldTextureWidth)
		{
			textureWidth = oldTextureWidth;
			offsetTextureX = 0;
		}
		if( oldTextureWidth < textureWidth + offsetTextureX)
		{
			textureWidth = oldTextureWidth;
			offsetTextureX = 0;
		}
		if( textureHeight > oldTextureHeight)
		{
			textureHeight = oldTextureHeight;
			offsetTextureY = 0;
		}
		
		unsigned char*	newTextureBuffer;
		
		newTextureBuffer = calloc( (1+textureWidth)*(1+textureHeight), sizeof(unsigned char));
		if( newTextureBuffer == nil)
		{
			textureWidth = oldTextureWidth;
			textureHeight = oldTextureHeight;
			return NO;
		}
		
		for( int y = 0 ; y < textureHeight ; y++)
		{
			if( y + offsetTextureY < oldTextureHeight)
				memcpy( newTextureBuffer + (y * textureWidth), textureBuffer + offsetTextureX+ (y+ offsetTextureY)*oldTextureWidth, textureWidth);
		}
		
		if( newTextureBuffer != textureBuffer)
		{
			free( textureBuffer);
			textureBuffer = newTextureBuffer;
		}
		
		textureUpLeftCornerX += offsetTextureX;
		textureUpLeftCornerY += offsetTextureY;
		textureDownRightCornerX = textureUpLeftCornerX + textureWidth-1;
		textureDownRightCornerY = textureUpLeftCornerY + textureHeight-1;
        
        [self textureBufferHasChanged];
	}
	
	return NO;	// means the ROI is NOT empty;
}

+ (void) fillCircle:(unsigned char *) buf :(int) width :(unsigned char) val
{
	int		xsqr;
	int		radsqr = (width*width)/4;
	int		rad = width/2;
	
	for( int x = 0; x < rad; x++ )
	{
		xsqr = x*x;
		for( int y = 0 ; y < rad; y++)
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
	if( locked)
		return NO;
		
	if( selectable == NO)
		return NO;

	[roiLock lock];
	
	BOOL action = NO;
	float backingScaleFactor = curView.window.backingScaleFactor;
    
	@try
	{
		BOOL textureGrowDownX = YES,textureGrowDownY = YES;
		float oldTextureUpLeftCornerX, oldTextureUpLeftCornerY, offsetTextureX, offsetTextureY;
			
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
                    
                {
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
					unsigned char* tempTextureBuffer = nil;
					
					// copy current Buffer to temp Buffer	
					if (textureBuffer!=NULL)
					{
						tempTextureBuffer = malloc( oldTextureHeight*oldTextureWidth*sizeof(unsigned char));
						memcpy( tempTextureBuffer, textureBuffer, oldTextureWidth*oldTextureHeight);
						free(textureBuffer);
						textureBuffer = nil;
                        
                        [self textureBufferHasChanged];
					}
					
					// new width and height
					textureWidth = (textureDownRightCornerX-textureUpLeftCornerX) + 1;
					textureHeight = (textureDownRightCornerY-textureUpLeftCornerY) + 1;
					
	//				if( textureWidth%4) {textureWidth /=4;		textureWidth *=4;		textureWidth +=4;}
	//				if( textureHeight%4) {textureHeight /=4;	textureHeight *=4;		textureHeight += 4;}
					
					textureDownRightCornerX = textureWidth+textureUpLeftCornerX-1;
					textureDownRightCornerY = textureHeight+textureUpLeftCornerY-1;
					
					// ROI cannot be smaller !
					if (textureWidth<oldTextureWidth)
						textureWidth=oldTextureWidth;
						
					if (textureHeight<oldTextureHeight)
						textureHeight=oldTextureHeight;
					
					// new texture buffer		
					textureBuffer = calloc( textureWidth * textureHeight, sizeof(unsigned char));
					if( textureBuffer)
					{
						// copy temp buffer to the new buffer
                        
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
					}
						
					free(tempTextureBuffer);
					tempTextureBuffer = nil;
						
					oldTextureWidth = textureWidth;
					oldTextureHeight = textureHeight;	
					
					unsigned char val;
					
					if( ![curView eraserFlag]) val = 0xFF;
					else val = 0x00;
					
					if( modifier & NSCommandKeyMask && !(modifier & NSShiftKeyMask))
					{
						if( val == 0xFF) val = 0;
						else val = 0xFF;
					}
					
					long size, *xPoints, *yPoints;
					
					if( previousPoint.x == -1000 && previousPoint.y == -1000) previousPoint = pt;
					
					int intThickness = thickness;
					
					unsigned char *brush = calloc( intThickness*2*intThickness*2, sizeof( unsigned char));
					
					[ROI fillCircle: brush :intThickness*2 :0xFF];

					size = BresLine(	previousPoint.x,
										previousPoint.y,
										pt.x,
										pt.y,
										&xPoints,
										&yPoints);
					
					for( long x = 0 ; x < size; x++)
                    {
						long xx = xPoints[ x];
						long yy = yPoints[ x];
								
						for( long j =- intThickness; j < intThickness; j++ ) {
							for( long i =- intThickness; i < intThickness; i++ ) {
								
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
                    
                    [self textureBufferHasChanged];
                }
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
				if( [[points lastObject] isNearToPoint: pt : scale/(thickness*backingScaleFactor) :[[curView curDCM] pixelRatio]] == NO)
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
					if( selectedModifyPoint >= 0)
						[[points objectAtIndex: selectedModifyPoint] setPoint: pt];
					rtotal = -1;
					Brtotal = -1;
					action = YES;
				break;
			}
		}
		else
		{
			if( type == tLayerROI)
                clickPoint = pt;
			
			switch( mode)
			{
				case ROI_drawing:
                    
                    [[points lastObject] setPoint: pt];
                    if( type == tMesure)
                    {
                        if( (modifier & NSShiftKeyMask) && points.count == 2)
                        {
                            NSPoint first = [[points objectAtIndex: 0] point];
                            NSPoint last = [[points lastObject] point];
                            
                            if( fabs( first.y - last.y) / fabs( first.x - last.x) < 0.5)
                                last.y = first.y;
                            else if( fabs( first.y - last.y) / fabs( first.x - last.x) < 1.5)
                                last.y = first.y + (last.x - first.x) * copysignf( 1.0, first.y - last.y) * copysignf( 1.0, first.x - last.x);
                            else
                                last.x = first.x;
                            
                            [[points lastObject] setPoint: last];
                        }
                    }
                    
					rtotal = -1;
					Brtotal = -1;
					action = YES;
				break;
				
				case ROI_selected:
					action = NO;
				break;
				
				case ROI_selectedModify:
                    
					if( selectedModifyPoint >= 0)
                    {
						[[points objectAtIndex: selectedModifyPoint] setPoint: pt];
					
                        if( type == tMesure)
                        {
                            if( (modifier & NSShiftKeyMask) && points.count == 2)
                            {
                                NSPoint first = selectedModifyPoint ? [[points objectAtIndex: 0] point] : [[points objectAtIndex: 1] point];
                                NSPoint last = [[points objectAtIndex: selectedModifyPoint] point];
                                
                                if( fabs( first.y - last.y) / fabs( first.x - last.x) < 0.5)
                                    last.y = first.y;
                                else if( fabs( first.y - last.y) / fabs( first.x - last.x) < 1.5)
                                    last.y = first.y + (last.x - first.x) * copysignf( 1.0, first.y - last.y) * copysignf( 1.0, first.x - last.x);
                                else
                                    last.x = first.x;
                                
                                [[points objectAtIndex: selectedModifyPoint] setPoint: last];
                            }
                        }
                    }
                        
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
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
		}
	}
	@catch (NSException * e)
	{
		NSLog( @"***** mouseRoiDragged exception: %@", e);
	}
	[roiLock unlock];
	
	return action;
}

- (BOOL) selectable
{
    if( hidden)
        return NO;
    
    return selectable;
}

- (BOOL) locked
{
    if( hidden)
        return YES;
    
    return locked;
}

- (void) setHidden:(BOOL) h
{
    hidden = h;
    curView.needsDisplay = YES;
}

- (void) setROIMode: (long) m
{
    if( hidden)
        m = ROI_sleep;
    
	if( mode != m)
	{
        if( [NSEvent pressedMouseButtons] != 0 && (mode == ROI_drawing || mode == ROI_selectedModify))
            NSLog( @"---- change ROI mode during modification?");
        
		mode = m;
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	}
}

- (void) setName:(NSString*) a
{
	if( a == nil)
		a = @"";
	
	if( name != a && ![name isEqualToString:a])
	{
		[name release];
		
		if (type != tText && [a length] > 256)
			a = [a substringToIndex: 256];
		
        name = [a copy];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	}
	
	if( type == tText)
	{
		NSString *finalString;
		
		if( [comments length] > 0) finalString = [name stringByAppendingFormat:@"\r%@", comments];
		else finalString = name;
		
		if( [finalString length] > 4096)
			finalString = [finalString substringToIndex: 4096];
		
		if (stringTex) [stringTex setString: finalString withAttributes:stanStringAttrib];
		else
		{
			stringTex = [[StringTexture alloc] initWithString: finalString withAttributes:stanStringAttrib withTextColor:[NSColor colorWithDeviceRed:color.red / 65535. green:color.green / 65535. blue:color.blue / 65535. alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
			[stringTex setAntiAliasing: YES];
		}
		
		rect.size = [stringTex frameSize];
		if( pixelSpacingX != 0 && pixelSpacingY != 0 )
			rect.size.height *= pixelSpacingX/pixelSpacingY;
	}
}

- (void) setColor:(RGBColor) a
{
	[self setColor: a globally: YES];
}

- (void) setColor:(RGBColor) a globally: (BOOL) g
{
	color = a;
	
	if( type == tText)
	{
		if( g)
		{
			ROITextColorR = color.red;	//[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROITextColorR"];
			ROITextColorG = color.green;	//[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROITextColorG"];
			ROITextColorB = color.blue;	//[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROITextColorB"];
		}
	}
	else if( type == tPlain)
	{
		if( g)
		{
			ROIRegionColorR = color.red;	//[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROIRegionColorR"];
			ROIRegionColorG = color.green;	//[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROIRegionColorG"];
			ROIRegionColorB = color.blue;	//[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROIRegionColorB"];
		}
	}
	else if( type == tLayerROI)
	{
		if(!canColorizeLayer) return;
		if(layerColor) [layerColor release];
		layerColor = [NSColor colorWithCalibratedRed:color.red/65535.0 green:color.green/65535.0 blue:color.blue/65535.0 alpha:1.0];
		[layerColor retain];
		while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	}
	else
	{
		if( g)
		{
			ROIColorR = color.red;		//[[NSUserDefaults standardUserDefaults] setFloat:color.red forKey:@"ROIColorR"];
			ROIColorG = color.green;		//[[NSUserDefaults standardUserDefaults] setFloat:color.green forKey:@"ROIColorG"];
			ROIColorB = color.blue;		//[[NSUserDefaults standardUserDefaults] setFloat:color.blue forKey:@"ROIColorB"];
		}
	}
}

- (void) setThickness:(float) a
{
	[self setThickness: a globally: YES];
}

- (void) setThickness:(float) a globally: (BOOL) g
{
	float v = roundf( a);	// To reduce the Opengl memory leak - PointSize LineWidth
	
	if( v < 1) v = 1;
	if( v > 20) v = 20;
	
	thickness = v;
	
	if( type == tPlain)
	{
		if( g)
			ROIRegionThickness = thickness;	//[[NSUserDefaults standardUserDefaults] setFloat:thickness forKey:@"ROIRegionThickness"];
	}
	else if( type == tArrow)
	{
		if( g)
			ROIArrowThickness = thickness;
	}
	else if( type == tText || type == tTAGT)
	{
		if( g)
			ROITextThickness = thickness;	//[[NSUserDefaults standardUserDefaults] setFloat:thickness forKey:@"ROITextThickness"];
		
		[stanStringAttrib release];
		
		// init fonts for use with strings
		NSFont * font =[NSFont fontWithName:@"Helvetica" size: 12.0 + thickness*2];
		stanStringAttrib = [[NSMutableDictionary dictionary] retain];
		[stanStringAttrib setObject:font forKey:NSFontAttributeName];
		[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
        [stringTexA release];   stringTexA = nil;
        [stringTexB release];   stringTexB = nil;
        [stringTexC release];   stringTexC = nil;
        
		self.name = name;
	}
	else
	{
		if( g)
			ROIThickness = thickness;
	}
}

- (BOOL) deleteSelectedPoint
{
    if( hidden)
        return NO;
    
	if( locked)
		return NO;

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
			if( mode == ROI_selectedModify)
			{
				if( selectedModifyPoint >= 0)
					[points removeObjectAtIndex: selectedModifyPoint];
			}
			else [points removeLastObject];
			
			if( selectedModifyPoint >= [points count]) selectedModifyPoint = (long)[points count]-1;
		break;
		case tDynAngle:
		case tAxis:
        case tTAGT:
			if(selectedModifyPoint>3 && selectedModifyPoint >= 0)
			{
				if( mode == ROI_selectedModify)
					[points removeObjectAtIndex: selectedModifyPoint];
				else
                    [points removeLastObject];
                
				if( selectedModifyPoint >= [points count]) selectedModifyPoint = (long)[points count]-1;
			}
		break;
        default:;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:self userInfo: nil];
	
	return [self valid];
}

// in cm or in pixels if no pixelspacing values
-(float) MesureLength:(float*) pixels pointA: (NSPoint) a pointB: (NSPoint) b
{
	float val = [self Length:a :b];
	
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

-(float) MesureLength:(float*) pixels
{
	return [self MesureLength: pixels pointA:[[points objectAtIndex:0] point] pointB:[[points objectAtIndex:1] point]];
}

+ (NSString*) formattedLength: (float) lCm
{
    if ( lCm < .01)
        return [NSString stringWithFormat: NSLocalizedString( @"%0.1f %cm", nil), lCm * 10000.0, 0xb5];
    else if ( lCm < 1)
        return [NSString stringWithFormat: NSLocalizedString( @"%0.2f mm", nil), lCm * 10.];
    else
        return [NSString stringWithFormat: NSLocalizedString( @"%0.2f cm", nil), lCm];
}

void gl_round_box(int mode, float minx, float miny, float maxx, float maxy, float rad, float factor)
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
//	glLineWidth( 0.1 * factor);
//	glBegin(GL_POLYGON);
//		glVertex2f(  minx, miny);
//		glVertex2f(  minx, maxy);
//		glVertex2f(  maxx, maxy);
//		glVertex2f(  maxx, miny);
//	glEnd();
    
    float vec[7][2]= {{0.195, 0.02}, {0.383, 0.067}, {0.55, 0.169}, {0.707, 0.293}, {0.831, 0.45}, {0.924, 0.617}, {0.98, 0.805}};
    
    rad *= factor;
    
    if( fabs( miny-maxy) < rad * 5.)
        rad = fabs( miny-maxy) / 5.;
    
    for( int a=0; a<7; a++)
    {
        vec[a][0]*= rad;
        vec[a][1]*= rad;
    }
    
    glBegin(mode);
    
    glVertex2f( maxx-rad, miny);
    for( int a=0; a<7; a++)
        glVertex2f( maxx-rad+vec[a][0], miny+vec[a][1]);
    glVertex2f( maxx, miny+rad);
    
    glVertex2f( maxx, maxy-rad);
    for( int a=0; a<7; a++)
        glVertex2f( maxx-vec[a][1], maxy-rad+vec[a][0]);
    glVertex2f( maxx-rad, maxy);
    
    glVertex2f( minx+rad, maxy);
    for( int a=0; a<7; a++)
        glVertex2f( minx+rad-vec[a][0], maxy-vec[a][1]);
    glVertex2f( minx, maxy-rad);
    
    glVertex2f( minx, miny+rad);
    for( int a=0; a<7; a++)
        glVertex2f( minx+vec[a][1], miny+rad-vec[a][0]);
    glVertex2f( minx+rad, miny);
	 
    glEnd();
}

- (NSRect) findAnEmptySpaceForMyRect:(NSRect) dRect :(BOOL*) moved
{
	NSMutableArray *rectArray = [curView rectArray];
	
	if( rectArray == nil)
	{
		*moved = NO;
		return dRect;
	}
	
	int direction = 0, maxRedo = [rectArray count] + 2;
	
	*moved = NO;
	
	dRect.origin.x += 8;
	dRect.origin.y += 8;
	
	//Does it intersect with the frame view?
	NSRect displayingRect = [curView drawingFrameRect];
	displayingRect.origin.x = -displayingRect.size.width/2;
	displayingRect.origin.y = -displayingRect.size.height/2;
	if( NSIntersectsRect( dRect, displayingRect))
	{
		if( NSEqualRects( NSUnionRect( dRect, displayingRect), displayingRect) == NO)
		{
			if( dRect.origin.x < displayingRect.origin.x)
				dRect.origin.x = displayingRect.origin.x;
			
			if( dRect.origin.y < displayingRect.origin.y)
				dRect.origin.y = displayingRect.origin.y;
			
			if( dRect.origin.y + dRect.size.height > displayingRect.origin.y + displayingRect.size.height)
				dRect.origin.y = displayingRect.origin.y + displayingRect.size.height - dRect.size.height;
			
			if( dRect.origin.x + dRect.size.width > displayingRect.origin.x + displayingRect.size.width)
				dRect.origin.x = displayingRect.origin.x + displayingRect.size.width - dRect.size.width;
		}
	}
	
	for( int i = 0; i < [rectArray count]; i++ )
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
	if(!displayTextualData)
        return NO;
	
    if( hidden)
        return NO;
    
	// NO text for Calcium Score
	if (_displayCalciumScoring)
		return NO;
		
	BOOL drawTextBox = NO;
	
	if( ROITEXTIFSELECTED == NO || mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
	{
		drawTextBox = YES;
	}
    
    if( ROITEXTIFSELECTED)
    {
        if( mouseOverROI)
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
	
    if( hidden)
    {
        drawRect = NSMakeRect(0, 0, 0, 0);
        return;
    }
    
	if( textualBoxLine1.length == 0 && textualBoxLine2.length == 0  && textualBoxLine3.length == 0  && textualBoxLine4.length == 0  && textualBoxLine5.length == 0  && textualBoxLine6.length == 0 )
	{
		drawRect = NSMakeRect(0, 0, 0, 0);
		return;
	}
	
	if(!displayTextualData)
	{
		drawRect = NSMakeRect(0, 0, 0, 0);
		return;
	}
	
	drawRect = [self findAnEmptySpaceForMyRect: drawRect : &moved];
	
	if(type == tDynAngle || type == tTAGT || type == tAxis ||type == tCPolygon || type == tOPolygon || type == tPencil) moved = YES;

//	if( type == tCPolygon || type == tOPolygon || type == tPencil) moved = YES;
//	if( fabs( offsetTextBox_x) > 0 || fabs( offsetTextBox_y) > 0) moved = NO;
	
	if( moved && ![curView suppressLabels] && self.isTextualDataDisplayed )	// Draw bezier line
	{
        NSPoint anchor = originAnchor;
        
        if( type == tPlain)
            anchor = [curView ConvertFromGL2View: NSMakePoint( textureDownRightCornerX - textureWidth/2, textureDownRightCornerY - textureHeight/2)];
        
		CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx == nil)
            return;
        
		glLoadIdentity();
//		glScalef( 2.0f /([curView frame].size.width), -2.0f / ([curView frame].size.height), 1.0f);	// JORIS ! Here is the problem for iChat : if ICHAT [curView frame] should be 640 *480....
		glScalef( 2.0f /([curView drawingFrameRect].size.width), -2.0f / ([curView drawingFrameRect].size.height), 1.0f);
		
		GLfloat ctrlpoints[4][3];
		
		const int OFF = 30;
		
		ctrlpoints[0][0] = NSMinX( drawRect);				ctrlpoints[0][1] = NSMidY( drawRect);							ctrlpoints[0][2] = 0;
		ctrlpoints[1][0] = anchor.x - OFF;                  ctrlpoints[1][1] = anchor.y;								ctrlpoints[1][2] = 0;
		ctrlpoints[2][0] = anchor.x;                        ctrlpoints[2][1] = anchor.y;								ctrlpoints[2][2] = 0;
		
		glLineWidth( 3.0 * curView.window.backingScaleFactor);
		if( mode == ROI_sleep) glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
		else glColor4f(0.3f, 0.0f, 0.0f, 0.8f);
		
		glMap1f(GL_MAP1_VERTEX_3, 0.0, 1.0, 3, 3,&ctrlpoints[0][0]);
		glEnable(GL_MAP1_VERTEX_3);
		
	    glBegin(GL_LINE_STRIP);
        for ( int i = 0; i <= 30; i++ ) glEvalCoord1f((GLfloat) i/30.0);
		glEnd();
		glDisable(GL_MAP1_VERTEX_3);
		
		glLineWidth( 1.0 * curView.window.backingScaleFactor);
		
		glColor4f( 1.0, 1.0, 1.0, 0.5);
		
		glMap1f(GL_MAP1_VERTEX_3, 0.0, 1.0, 3, 3,&ctrlpoints[0][0]);
		glEnable(GL_MAP1_VERTEX_3);
		
	    glBegin(GL_LINE_STRIP);
        for ( int i = 0; i <= 30; i++ ) glEvalCoord1f((GLfloat) i/30.0);
		glEnd();
		glDisable(GL_MAP1_VERTEX_3);
		
		[curView applyImageTransformation];
	}

	if( self.isTextualDataDisplayed )
	{
		if( type != tText)
		{
			
			CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
            if( cgl_ctx == nil)
                return;
            
            glLoadIdentity();
            
			glEnable(GL_BLEND);
			glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			
            float sf = curView.window.backingScaleFactor;
            
			glScalef( 2.0f /([curView drawingFrameRect].size.width), -2.0f / ([curView drawingFrameRect].size.height), 1.0f);
            
            if( mode == ROI_sleep) glColor4f(0.0f, 0.0f, 0.0f, 0.4f);
			else glColor4f(0.3f, 0.0f, 0.0f, 0.8f);
            
            glBegin(GL_POLYGON);
            glVertex2f(  drawRect.origin.x, drawRect.origin.y-1);
            glVertex2f(  drawRect.origin.x, drawRect.origin.y+drawRect.size.height);
            glVertex2f(  drawRect.origin.x+drawRect.size.width, drawRect.origin.y+drawRect.size.height);
            glVertex2f(  drawRect.origin.x+drawRect.size.width, drawRect.origin.y-1);
            glEnd();
            
//            glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
//			glEnable(GL_POLYGON_SMOOTH);
//			gl_round_box(GL_POLYGON, drawRect.origin.x, drawRect.origin.y-1, drawRect.origin.x+drawRect.size.width, drawRect.origin.y+drawRect.size.height, fontHeight*sf/5., sf);
//			glDisable(GL_POLYGON_SMOOTH);
            
			NSPoint tPt = NSMakePoint( drawRect.origin.x + 4*sf, drawRect.origin.y + (fontHeight*sf + 2*sf));
			
			long line = 0;
			
			[self glStr: textualBoxLine1 : tPt.x : tPt.y : line];	if( textualBoxLine1.length) line++;
			[self glStr: textualBoxLine2 : tPt.x : tPt.y : line];	if( textualBoxLine2.length) line++;
			[self glStr: textualBoxLine3 : tPt.x : tPt.y : line];	if( textualBoxLine3.length) line++;
			[self glStr: textualBoxLine4 : tPt.x : tPt.y : line];	if( textualBoxLine4.length) line++;
			[self glStr: textualBoxLine5 : tPt.x : tPt.y : line];	if( textualBoxLine5.length) line++;
			[self glStr: textualBoxLine6 : tPt.x : tPt.y : line];	if( textualBoxLine6.length) line++;
			
			
			glDisable(GL_BLEND);
			
			[curView applyImageTransformation];
		}
	}
	else
	{
		drawRect = NSMakeRect(0, 0, 0, 0);
	}
}

- (void) prepareTextualData:(NSPoint) tPt
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
	maxWidth = [self maxStringWidth:textualBoxLine1 max: maxWidth];	if( textualBoxLine1.length) line++;
	maxWidth = [self maxStringWidth:textualBoxLine2 max: maxWidth];	if( textualBoxLine2.length) line++;
	maxWidth = [self maxStringWidth:textualBoxLine3 max: maxWidth];	if( textualBoxLine3.length) line++;
	maxWidth = [self maxStringWidth:textualBoxLine4 max: maxWidth];	if( textualBoxLine4.length) line++;
	maxWidth = [self maxStringWidth:textualBoxLine5 max: maxWidth];	if( textualBoxLine5.length) line++;
	maxWidth = [self maxStringWidth:textualBoxLine6 max: maxWidth];	if( textualBoxLine6.length) line++;
	
	drawRect.size.height = line * fontHeight*curView.window.backingScaleFactor + 2;
	drawRect.size.width = maxWidth + 8;
	
	if( type == tDynAngle || type == tAxis || type == tTAGT || type == tCPolygon || type == tOPolygon || type == tPencil)
	{
		if( [points count] > 0)
		{
			float ymin = [[points objectAtIndex:0] y];
			
			tPt.y = [[points objectAtIndex: 0] y];
			tPt.x = [[points objectAtIndex: 0] x];
			
			for( long i = 0; i < [points count]; i++ )
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
			originAnchor = tPt;
			
			tPt = ctPt;
			tPt.x += offsetTextBox_x;
			tPt.y += offsetTextBox_y;
			
			tPt = [curView ConvertFromGL2View: tPt];
			drawRect.origin = tPt;
		}
	}
}

- (NSString*) description
{
	float mean = 0, min = 0, max = 0, total = 0, dev = 0;
	
	[pix computeROI:self :&mean :&total :&dev :&min :&max];
	
	return [NSString stringWithFormat:@"%@	%.3f	%.3f	%.3f	%.3f	%.3f", name, mean, min, max, total, dev];
}

- (void) drawROI :(float) scaleValue :(float) offsetx :(float) offsety :(float) spacingX :(float) spacingY;
{
	[self drawROIWithScaleValue:scaleValue offsetX:offsetx offsetY:offsety pixelSpacingX:spacingX pixelSpacingY:spacingY highlightIfSelected:YES thickness:thickness prepareTextualData: YES];
}

- (void) setTexture: (unsigned char*) t width: (int) w height:(int) h
{
    if( textureBuffer)
        free( textureBuffer);
    
    textureBuffer = t;
    textureWidth = w;
    textureHeight = h;
    
    [self textureBufferHasChanged];
}

- (void) drawROIWithScaleValue:(float)scaleValue offsetX:(float)offsetx offsetY:(float)offsety pixelSpacingX:(float)spacingX pixelSpacingY:(float)spacingY highlightIfSelected:(BOOL)highlightIfSelected thickness:(float)thick prepareTextualData:(BOOL) prepareTextualData;
{
    if( hidden)
        return;
    
	if( roiLock == nil) roiLock = [[NSRecursiveLock alloc] init];
	
	if( curView == nil && prepareTextualData == YES) {NSLog(@"curView == nil! We will not draw this ROI..."); return;}
	
    float backingScaleFactor = curView.window.backingScaleFactor;
    
	[roiLock lock];
	
    self.textualBoxLine1 = self.textualBoxLine2 = self.textualBoxLine3 = self.textualBoxLine4 = self.textualBoxLine5 = self.textualBoxLine6 = nil;
    
	@try
	{
		if( selectable == NO)
			mode = ROI_sleep;
		
		pixelSpacingX = spacingX;
		pixelSpacingY = spacingY;
		
		float screenXUpL,screenYUpL,screenXDr,screenYDr; // for tPlain ROI
		
		NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
		CGLContextObj cgl_ctx = [currentContext CGLContextObj];
        if( cgl_ctx == nil)
            return;
        
		glColor3f ( 1.0f, 1.0f, 1.0f);
		
		glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
		glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
		glEnable(GL_POINT_SMOOTH);
		glEnable(GL_LINE_SMOOTH);
		glEnable(GL_POLYGON_SMOOTH);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		
		switch( type)
		{
#pragma mark tLayerROI
			case tLayerROI:
			{
				if(layerImage)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                    
                    NSBitmapImageRep* layerImageRep = (NSBitmapImageRep *)[[layerImage representations] objectAtIndex:0];
                    
					NSSize imageSize = NSMakeSize(layerImageRep.pixelsWide, layerImageRep.pixelsHigh); // [layerImage size];
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
						GLuint texName = 0;
						NSUInteger index = [ctxArray indexOfObjectIdenticalTo: currentContext];
						if( index != NSNotFound)
							texName = [[textArray objectAtIndex: index] intValue];
						
						if (!texName)
							texName = [self loadLayerImageTexture];
							
						glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texName);
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
					if(mode==ROI_selected && highlightIfSelected)
					{
						glColor3f (0.5f, 0.5f, 1.0f);
						glPointSize( 8.0 * backingScaleFactor);
						glBegin(GL_POINTS);
						glVertex3f(p1.x, p1.y, 0.0);
						glVertex3f(p2.x, p2.y, 0.0);
						glVertex3f(p3.x, p3.y, 0.0);
						glVertex3f(p4.x, p4.y, 0.0);
						glEnd();
						glColor3f (1.0f, 1.0f, 1.0f);
					}
					
					if( self.isTextualDataDisplayed && prepareTextualData)
					{
						// TEXT
						NSPoint tPt = self.lowerRightPoint;
                        
                        if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                        else self.textualBoxLine1 = nil;

						[self prepareTextualData:tPt];
					}
					[pool release];
				}
			}
			break;
#pragma mark tPlain
			case tPlain:
			//	if( mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing)
			{
				glDisable(GL_POLYGON_SMOOTH);
				
                if( highlightIfSelected && ROIDrawPlainEdge)
                {
                    switch( mode)
                    {
                        case 	ROI_drawing:
                        case 	ROI_selected:
                        case 	ROI_selectedModify:
                        {
                            #define MARGINSELECTED 1
                            int margin = MARGINSELECTED;
                            
                            int newWidth = textureWidth + 2*margin;
                            int newHeight = textureHeight + 2*margin;
//                            int newTextureDownRightCornerX = textureDownRightCornerX+margin;
//                            int newTextureDownRightCornerY = textureDownRightCornerY+margin;
                            int newTextureUpLeftCornerX = textureUpLeftCornerX-margin;
                            int newTextureUpLeftCornerY = textureUpLeftCornerY-margin;
                            
                            if( textureBufferSelected == nil)
                            {
                                textureBufferSelected = [ROI addMargin: margin buffer: textureBuffer width: textureWidth height: textureHeight];
                                
                                if( textureBufferSelected)
                                {
                                    unsigned char* newBufferCopy = malloc( newWidth*newHeight);
                                    if( newBufferCopy)
                                    {
                                        memcpy( newBufferCopy, textureBufferSelected, newWidth*newHeight);
                                        
                                        {
                                            // input buffer
                                            unsigned char *buff = textureBufferSelected;
                                            int bufferWidth = newWidth;
                                            int bufferHeight = newHeight;
                                            
                                            margin *= 2;
                                            margin ++;
                                            
                                            unsigned char *kernelDilate = (unsigned char*) calloc( margin*margin, sizeof(unsigned char));
                                            if( kernelDilate)
                                            {
                                                memset(kernelDilate,0x00,margin*margin);
                                                
                                                vImage_Buffer srcbuf, dstBuf;
                                                vImage_Error err;
                                                srcbuf.data = buff;
                                                dstBuf.data = malloc( bufferHeight * bufferWidth);
                                                if( dstBuf.data)
                                                {
                                                    dstBuf.height = srcbuf.height = bufferHeight;
                                                    dstBuf.width = srcbuf.width = bufferWidth;
                                                    dstBuf.rowBytes = srcbuf.rowBytes = bufferWidth;
                                                    err = vImageDilate_Planar8( &srcbuf, &dstBuf, 0, 0, kernelDilate, margin, margin, kvImageDoNotTile);
                                                
                                                    memcpy(buff,dstBuf.data,bufferWidth*bufferHeight);
                                                    free( dstBuf.data);
                                                }
                                                free( kernelDilate);
                                            }
                                        }
                                        
                                        // Subtraction
                                        for( long i = 0; i < newWidth*newHeight;i++)
                                            if( newBufferCopy[ i]) textureBufferSelected[ i] = 0;
                                        
                                        free( newBufferCopy);
                                    }
                                }
                            }
                            
                            if( textureBufferSelected)
                            {
                                GLuint textureName = 0;
                                
                                glEnable(GL_TEXTURE_RECTANGLE_EXT);
                                glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, newWidth * newHeight, textureBufferSelected);
                                glGenTextures (1, &textureName);
                                glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
                                glPixelStorei (GL_UNPACK_ROW_LENGTH, newWidth);
                                glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
                                glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
                                
                                glBlendEquation(GL_FUNC_ADD);
                                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                                
                                if( [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"])
                                {
                                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);	//GL_LINEAR_MIPMAP_LINEAR
                                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);	//GL_LINEAR_MIPMAP_LINEAR
                                }
                                else
                                {
                                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
                                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
                                }
                                
                                glTexImage2D (GL_TEXTURE_RECTANGLE_EXT, 0, GL_INTENSITY8, newWidth, newHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, textureBufferSelected);
                                
                                glColor4f( 0, 0, 0, 1.0);
                                
                                screenXUpL = (newTextureUpLeftCornerX-offsetx)*scaleValue;
                                screenYUpL = (newTextureUpLeftCornerY-offsety)*scaleValue;
                                screenXDr = screenXUpL + newWidth*scaleValue;
                                screenYDr = screenYUpL + newHeight*scaleValue;
                                
                                glBegin (GL_QUAD_STRIP); // draw either tri strips of line strips (so this will drw either two tris or 3 lines)
                                glTexCoord2f (0, 0); // draw upper left in world coordinates
                                glVertex3d (screenXUpL, screenYUpL, 0.0);
                                
                                glTexCoord2f (newWidth, 0); // draw lower left in world coordinates
                                glVertex3d (screenXDr, screenYUpL, 0.0);
                                
                                glTexCoord2f (0, newHeight); // draw upper right in world coordinates
                                glVertex3d (screenXUpL, screenYDr, 0.0);
                                
                                glTexCoord2f (newWidth, newHeight); // draw lower right in world coordinates
                                glVertex3d (screenXDr, screenYDr, 0.0);
                                glEnd();
                                
                                glDeleteTextures( 1, &textureName);
                                
                                glDisable(GL_TEXTURE_RECTANGLE_EXT);
                            }
                        }
                        break;
                    }
                }
                
                GLuint textureName = 0;
				
                glEnable(GL_TEXTURE_RECTANGLE_EXT);
				glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, textureWidth * textureHeight, textureBuffer);
				glGenTextures (1, &textureName);
				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
				glPixelStorei (GL_UNPACK_ROW_LENGTH, textureWidth);
				glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
				glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
				
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				
                if( [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"])
                {
                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);	//GL_LINEAR_MIPMAP_LINEAR
                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);	//GL_LINEAR_MIPMAP_LINEAR
                }
                else
                {
                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
                    glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
                }
                
                glTexImage2D (GL_TEXTURE_RECTANGLE_EXT, 0, GL_INTENSITY8, textureWidth, textureHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, textureBuffer);
                
                glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
                
                screenXUpL = (textureUpLeftCornerX-offsetx)*scaleValue;
				screenYUpL = (textureUpLeftCornerY-offsety)*scaleValue;
				screenXDr = screenXUpL + textureWidth*scaleValue;
				screenYDr = screenYUpL + textureHeight*scaleValue;
                
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
				
                glDeleteTextures( 1, &textureName);
                
				glDisable(GL_TEXTURE_RECTANGLE_EXT);
                
				glEnable(GL_POLYGON_SMOOTH);
				
				switch( mode)
				{
					case 	ROI_drawing:
					case 	ROI_selected:
					case 	ROI_selectedModify:
						if(highlightIfSelected && ROIDrawPlainEdge == NO)
						{
							glColor3f (0.5f, 0.5f, 1.0f);
							//smaller points for calcium scoring
							if (_displayCalciumScoring)
								glPointSize( 3.0 * backingScaleFactor);
							else
								glPointSize( 8.0 * backingScaleFactor);
							glBegin(GL_POINTS);
							glVertex3f(screenXUpL, screenYUpL, 0.0);
							glVertex3f(screenXDr, screenYUpL, 0.0);
							glVertex3f(screenXUpL, screenYDr, 0.0);
							glVertex3f(screenXDr, screenYDr, 0.0);
							glEnd();
						}
					break;
				}
				
				glLineWidth(1.0 * backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				if( self.isTextualDataDisplayed && prepareTextualData)
				{
					NSPoint tPt = [self lowerRightPoint];
					
					if( [name isEqualToString: @"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                    else self.textualBoxLine1 = nil;
					
					if ( ROITEXTNAMEONLY == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax :&rskewness :&rkurtosis];
						
						float area = [self plainArea];

						if (!_displayCalciumScoring)
						{
                            
                            // US Regions (Brush) --->
                            BOOL roiInside2DUSRegion = FALSE;
                            if ([[self pix] hasUSRegions]) {
                                
                                NSPoint roiPoint1 = NSMakePoint(textureUpLeftCornerX, textureUpLeftCornerY);
                                NSPoint roiPoint2 = NSMakePoint(textureDownRightCornerX, textureDownRightCornerY);
                                
                                //NSLog(@"roi [%i,%i] [%i,%i]", (int)roiPoint1.x, (int)roiPoint1.y, (int)roiPoint2.x, (int)roiPoint2.y);
                                
                                NSEnumerator *usRegionsEnum = [[[self pix] usRegions] objectEnumerator];
                                DCMUSRegion *anUsRegion;
                                
                                while(anUsRegion = [usRegionsEnum nextObject]) {
                                    if (!roiInside2DUSRegion && [anUsRegion regionSpatialFormat] == 1) {
                                        // 2D spatial format
                                        int usRegionMinX = [anUsRegion regionLocationMinX0];
                                        int usRegionMinY = [anUsRegion regionLocationMinY0];
                                        int usRegionMaxX = [anUsRegion regionLocationMaxX1];
                                        int usRegionMaxY = [anUsRegion regionLocationMaxY1];
                                        
                                        //NSLog(@"usRegion [%i,%i] [%i,%i]", usRegionMinX, usRegionMinY, usRegionMaxX, usRegionMaxY);
                                        
                                        roiInside2DUSRegion = (((int)roiPoint1.x >= usRegionMinX) && ((int)roiPoint1.x <= usRegionMaxX) &&
                                                               ((int)roiPoint1.y >= usRegionMinY) && ((int)roiPoint1.y <= usRegionMaxY) &&
                                                               ((int)roiPoint2.x >= usRegionMinX) && ((int)roiPoint2.x <= usRegionMaxX) &&
                                                               ((int)roiPoint2.y >= usRegionMinY) && ((int)roiPoint2.y <= usRegionMaxY));
                                    }
                                }
                                
                            }
                            //if( pixelSpacingX != 0 && pixelSpacingY != 0 )
                            if (roiInside2DUSRegion || ((pixelSpacingX != 0 && pixelSpacingY != 0) && (![[self pix] hasUSRegions])))
                            // <--- US Regions (Brush)
                            {
                                if( area*pixelSpacingX*pixelSpacingY < 1.)
                                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.1f %cm\u00B2", nil), area*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5];
                                else if( area*pixelSpacingX*pixelSpacingY/100. < 1.)
                                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f mm\u00B2", nil), area*pixelSpacingX*pixelSpacingY];
                                else
                                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f cm\u00B2", nil), area*pixelSpacingX*pixelSpacingY/100.];
                            }
                            else
                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f pix2", nil), area];
							
                            NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", self.pix.rescaleType];
                            
                            if( [self pix].SUVConverted)
                                pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                            
							self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), rmean, pixelUnit, rdev, pixelUnit, rtotal, pixelUnit];
                            if( rskewness || rkurtosis)
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), rmin, pixelUnit, rmax, pixelUnit, rskewness, rkurtosis];
                            else
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@", nil), rmin, pixelUnit, rmax, pixelUnit];
						}
						else
						{
							self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Calcium Score: %0.1f", nil), [self calciumScore]];
							self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Calcium Volume: %0.1f", nil), [self calciumVolume]];
							self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Calcium Mass: %0.1f", nil), [self calciumMass]];
						}
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [self copy];
							blendedROI.pix = blendedPix;
							[blendedROI setOriginAndSpacing: blendedPix.pixelSpacingX: blendedPix.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: blendedPix]];
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax :&Brskewness :&Brkurtosis];
							[blendedROI release];
							
                            NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", blendedPix.rescaleType];
                            
                            if( blendedPix.SUVConverted)
                                pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                            
							self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), Brmean, pixelUnit, Brdev, pixelUnit, Brtotal, pixelUnit];
                            if( Brskewness || Brkurtosis)
                                self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), Brmin, pixelUnit, Brmax, pixelUnit, Brskewness, Brkurtosis];
                            else
                                self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@", nil), Brmin, pixelUnit, Brmax, pixelUnit];
						}
					}
					//if (!_displayCalciumScoring)
					[self prepareTextualData:tPt];
				}
			}
			break;
#pragma mark t2DPoint
			case t2DPoint:
			{
				float angle;
				
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);

				glBegin(GL_LINE_LOOP);
				for( int i = 0; i < CIRCLERESOLUTION ; i++ )
				{
				  angle = i * 2 * M_PI /CIRCLERESOLUTION;
				  
				  if( pixelSpacingX != 0 && pixelSpacingY != 0 )
					glVertex2f( (rect.origin.x - offsetx)*scaleValue + 8*cos(angle), (rect.origin.y - offsety)*scaleValue + 8*sin(angle)*pixelSpacingX/pixelSpacingY);
				  else
					glVertex2f( (rect.origin.x - offsetx)*scaleValue + 8*cos(angle), (rect.origin.y - offsety)*scaleValue + 8*sin(angle));
				}
				glEnd();
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected) glColor4f (0.5f, 0.5f, 1.0f, opacity);
				else glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				//else glColor4f (1.0f, 0.0f, 0.0f, opacity);
				
				glPointSize( (1 + sqrt( thick))*3.5 * backingScaleFactor);
				glBegin( GL_POINTS);
				glVertex2f(  (rect.origin.x  - offsetx)*scaleValue, (rect.origin.y  - offsety)*scaleValue);
				glEnd();
				
				glLineWidth(1.0 * backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				if( self.isTextualDataDisplayed && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					
					if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                    else self.textualBoxLine1 = nil;
					
					if( ROITEXTNAMEONLY == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax :&rskewness :&rkurtosis];
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [[[ROI alloc] initWithType: type :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
							
							NSRect blendedRect = [self rect];
							blendedRect.origin = [curView ConvertFromGL2GL: blendedRect.origin toView:[curView blendingView]];
							[blendedROI setROIRect: blendedRect];
							
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax :&rskewness :&rkurtosis];
						}
                        
                        // US Regions (Point) --->
                        double roiPosXValue, roiPosYValue;
                        int physicalUnitsXDirection, physicalUnitsYDirection;
                        BOOL roiInsideMModeOrSpectralUSRegion = FALSE;
                        BOOL isReferencePixelX0Present, isReferencePixelY0Present = FALSE;
                        if ([[self pix] hasUSRegions]) {
                            
                            NSEnumerator *usRegionsEnum = [[[self pix] usRegions] objectEnumerator];
                            DCMUSRegion *anUsRegion;
                            
                            while(anUsRegion = [usRegionsEnum nextObject]) {
                                if (!roiInsideMModeOrSpectralUSRegion && ([anUsRegion regionSpatialFormat] == 2 || [anUsRegion regionSpatialFormat] == 3)) {
                                    // M-Mode or Spectral spatial format
                                    int usRegionMinX = [anUsRegion regionLocationMinX0];
                                    int usRegionMinY = [anUsRegion regionLocationMinY0];
                                    int usRegionMaxX = [anUsRegion regionLocationMaxX1];
                                    int usRegionMaxY = [anUsRegion regionLocationMaxY1];
                                    
                                    //NSLog(@"usRegion [%i,%i] [%i,%i]", usRegionMinX, usRegionMinY, usRegionMaxX, usRegionMaxY);
                                    
                                    roiInsideMModeOrSpectralUSRegion = (((int)rect.origin.x >= usRegionMinX) && ((int)rect.origin.x <= usRegionMaxX) &&
                                                                        ((int)rect.origin.y >= usRegionMinY) && ((int)rect.origin.y <= usRegionMaxY));
                                    
                                    if (roiInsideMModeOrSpectralUSRegion)
                                    {
                                        // X axis
                                        physicalUnitsXDirection = [anUsRegion physicalUnitsXDirection];
                                        isReferencePixelX0Present = [anUsRegion isReferencePixelX0Present];
                                        if (isReferencePixelX0Present)
                                            roiPosXValue = (rect.origin.x - (usRegionMinX + [anUsRegion referencePixelX0]) + [anUsRegion refPixelPhysicalValueX]) * [anUsRegion physicalDeltaX];
                                        
                                        // Y axis
                                        physicalUnitsYDirection = [anUsRegion physicalUnitsYDirection];
                                        isReferencePixelY0Present = [anUsRegion isReferencePixelY0Present];
                                        if (isReferencePixelY0Present)
                                        {
                                            if ([anUsRegion regionSpatialFormat] == 2)
                                                // M-Mode
                                                roiPosYValue = -((usRegionMinY + [anUsRegion referencePixelY0]) - rect.origin.y + [anUsRegion refPixelPhysicalValueY]) * fabs([anUsRegion    physicalDeltaY]);
                                            else
                                                // Spectral
                                                roiPosYValue = ((usRegionMinY + [anUsRegion referencePixelY0]) - rect.origin.y + [anUsRegion refPixelPhysicalValueY]) * fabs([anUsRegion    physicalDeltaY]);
                                        }
                                    }
                                }
                            }
                        }
                        // <--- US Regions (Point)
                        
                        NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", self.pix.rescaleType];
                        
                        if( [self pix].SUVConverted)
                            pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                        
                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Value: %0.3f%@", nil), rmean, pixelUnit];
                        
						if( Brtotal != -1)
                        {
                            DCMPix	*blendedPix = [[curView blendingView] curDCM];
                            
                            NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", blendedPix.rescaleType];
                            
                            if( blendedPix.SUVConverted)
                                pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                            
                            self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Value: %0.3f%@", nil), Brmean, pixelUnit];
                        }
						
                        // US Regions (Point) --->
                        if (roiInsideMModeOrSpectralUSRegion) {
                            NSArray * physicalUnitsXYDirection = [NSArray arrayWithObjects:
                                                                  NSLocalizedString( @"none", nil), @"%", NSLocalizedString( @"dB", @"decibel"), NSLocalizedString( @"cm", nil), NSLocalizedString( @"sec", @"second"), NSLocalizedString( @"hertz", nil), NSLocalizedString( @"dB/sec", @"decibel per second"), NSLocalizedString( @"cm/sec", nil), NSLocalizedString( @"cm\u00B2", @"cm2"), NSLocalizedString( @"cm\u00B2/sec", @"cm2/sec"), NSLocalizedString( @"cm\u00B3", @"cm3"), NSLocalizedString( @"cm\u00B3/sec", @"cm3/sec"), @"\u00B0", nil];
                            
                            NSString * unitsX;
                            NSString * unitsY;
                            if ((physicalUnitsXDirection < 0) || (physicalUnitsXDirection > 12)) {
                                unitsX = NSLocalizedString( @"unknown", nil);
                            } else if ((physicalUnitsYDirection < 0) || (physicalUnitsYDirection > 12)) {
                                unitsY = NSLocalizedString( @"unknown", nil);
                            } else {
                                unitsX = [physicalUnitsXYDirection objectAtIndex:physicalUnitsXDirection];
                                unitsY = [physicalUnitsXYDirection objectAtIndex:physicalUnitsYDirection];
                            }
                            
                            if ((!isReferencePixelX0Present) && (isReferencePixelY0Present)) {
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"2D Pos: X:n/a %@ Y:%0.3f %@", nil), unitsX, roiPosYValue, unitsY];
                            } else if ((isReferencePixelX0Present) && (!isReferencePixelY0Present)) {
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"2D Pos: X:%0.3f %@ Y:n/a %@", nil), roiPosXValue, unitsX, unitsY];
                            } else if ((!isReferencePixelX0Present) && (!isReferencePixelY0Present)) {
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"2D Pos: X:n/a %@ Y:n/a %@", nil), unitsX, unitsY];
                            } else
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"2D Pos: X:%0.3f %@ Y:%0.3f %@", nil), roiPosXValue, unitsX, roiPosYValue, unitsY];
                            
                        } else {
                        // <--- US Regions (Point)
                            self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"2D Pos: X:%0.3f px Y:%0.3f px", nil), rect.origin.x, rect.origin.y];
                        } // US Regions (Point)
						
						float location[ 3 ];
						[[curView curDCM] convertPixX: rect.origin.x pixY: rect.origin.y toDICOMCoords: location pixelCenter: YES];
                        
						self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"3D Pos: X:%0.3f mm Y:%0.3f mm Z:%0.3f mm", nil), location[0], location[1], location[2]];
					}
					[self prepareTextualData:tPt];
				}
			}
			break;
#pragma mark tText
			case tText:
			{
				glPushMatrix();
				
				float ratio = 1;
				
				if( pixelSpacingX != 0 && pixelSpacingY != 0)
					ratio = pixelSpacingX / pixelSpacingY;
				
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f /([curView xFlipped] ? -([curView drawingFrameRect].size.width) : [curView drawingFrameRect].size.width), -2.0f / ([curView yFlipped] ? -([curView drawingFrameRect].size.height) : [curView drawingFrameRect].size.height), 1.0f); // scale to port per pixel scale
				glTranslatef( [curView origin].x, -[curView origin].y, 0.0f);

				NSRect centeredRect = rect;
				NSRect unrotatedRect = rect;
				
				centeredRect.origin.y -= offsety + [curView origin].y*ratio/scaleValue;
				centeredRect.origin.x -= offsetx - [curView origin].x/scaleValue;
				
				unrotatedRect.origin.x = centeredRect.origin.x*cos( -curView.rotation*deg2rad) + centeredRect.origin.y*sin( -curView.rotation*deg2rad)/ratio;
				unrotatedRect.origin.y = -centeredRect.origin.x*sin( -curView.rotation*deg2rad) + centeredRect.origin.y*cos( -curView.rotation*deg2rad)/ratio;
				
				unrotatedRect.origin.y *= ratio;
				
				unrotatedRect.origin.y += offsety + [curView origin].y*ratio/scaleValue;
				unrotatedRect.origin.x += offsetx - [curView origin].x/scaleValue;
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( 2.0 * 3 * backingScaleFactor);
					glBegin( GL_POINTS);
					glVertex2f(  (unrotatedRect.origin.x - offsetx)*scaleValue - unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue - unrotatedRect.size.height/2/ratio);
					glVertex2f(  (unrotatedRect.origin.x - offsetx)*scaleValue - unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue + unrotatedRect.size.height/2/ratio);
					glVertex2f(  (unrotatedRect.origin.x- offsetx)*scaleValue + unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue + unrotatedRect.size.height/2/ratio);
					glVertex2f(  (unrotatedRect.origin.x - offsetx)*scaleValue + unrotatedRect.size.width/2, (unrotatedRect.origin.y - offsety)/ratio*scaleValue - unrotatedRect.size.height/2/ratio);
					glEnd();
				}
				
				glLineWidth(1.0 * backingScaleFactor);
				
				NSPoint tPt = NSMakePoint( unrotatedRect.origin.x, unrotatedRect.origin.y);
				tPt.x = (tPt.x - offsetx)*scaleValue - unrotatedRect.size.width/2;
				tPt.y = (tPt.y - offsety)/ratio*scaleValue - unrotatedRect.size.height/2/ratio;
				
				glEnable (GL_TEXTURE_RECTANGLE_EXT);
				
				glEnable(GL_BLEND);
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				
				if( stringTex == nil ) self.name = name;
				
				[stringTex setFlippedX: [curView xFlipped] Y:[curView yFlipped]];
				
				glColor4f (0, 0, 0, opacity);
				[stringTex drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+ 1.0) ratio: 1];
					
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				[stringTex drawAtPoint:tPt ratio: 1];
					
				glDisable (GL_TEXTURE_RECTANGLE_EXT);
				
				glColor3f (1.0f, 1.0f, 1.0f);
				
				glPopMatrix();
			}
			break;
#pragma mark tMesure / tArrow
			case tMesure:
			case tArrow:
			{
                if( points.count > 2)
                    type = tOPolygon;
                
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				glLineWidth( thick * backingScaleFactor);
				
				if( type == tArrow)
				{
                    thick *= 0.5;
                    
                    if( thick > 5)
                        thick = 5;
                    
					NSPoint a, b;
					float   slide, adj, op, angle;
					
					a.x = ([[points objectAtIndex: 0] x]- offsetx) * scaleValue;
					a.y = ([[points objectAtIndex: 0] y]- offsety) * scaleValue;
					
					b.x = ([[points objectAtIndex: 1] x]- offsetx) * scaleValue;
					b.y = ([[points objectAtIndex: 1] y]- offsety) * scaleValue;
					
					if( (b.y-a.y) == 0) slide = (b.x-a.x)/-0.001;
					else
					{
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							slide = (b.x-a.x)/((b.y-a.y) * (pixelSpacingY / pixelSpacingX));
						else
							slide = (b.x-a.x)/((b.y-a.y));
					}
					#define ARROWSIZEConstant 25.0
					
					float ARROWSIZE = ARROWSIZEConstant * (thick * backingScaleFactor / 3.0);
					
					// LINE
					glLineWidth( thick*2*backingScaleFactor);
					
					angle = 90 - atan( slide)/deg2rad;
					adj = (ARROWSIZE + thick * backingScaleFactor * 13)  * cos( angle*deg2rad);
					op = (ARROWSIZE + thick * backingScaleFactor * 13) * sin( angle*deg2rad);
					
					glBegin(GL_LINE_STRIP);
						if(b.y-a.y > 0)
						{	
							if( pixelSpacingX != 0 && pixelSpacingY != 0 )
								glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
							else
								glVertex2f( a.x + adj, a.y + (op));
						}
						else
						{
							if( pixelSpacingX != 0 && pixelSpacingY != 0 )
								glVertex2f( a.x - adj, a.y - (op*pixelSpacingX / pixelSpacingY));
							else
								glVertex2f( a.x - adj, a.y - (op));
						}
						glVertex2f( b.x, b.y);
					glEnd();
					
					glPointSize( thick*2 * backingScaleFactor);
						
					glBegin( GL_POINTS);
					if(b.y-a.y > 0)
					{	
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							glVertex2f( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							glVertex2f( a.x + adj, a.y + (op));
					}
					else
					{
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							glVertex2f( a.x - adj, a.y - (op*pixelSpacingX / pixelSpacingY));
						else
							glVertex2f( a.x - adj, a.y - (op));
					}
					glVertex2f( b.x, b.y);
					glEnd();
					
					// ARROW
					NSPoint aa1, aa2, aa3;
					
					if(b.y-a.y > 0) 
					{
						angle = atan( slide)/deg2rad;
						
						angle = 80 - angle - thick * backingScaleFactor;
						adj = (ARROWSIZE + thick * backingScaleFactor * 15)  * cos( angle*deg2rad);
						op = (ARROWSIZE + thick * backingScaleFactor * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa1 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa1 = NSMakePoint( a.x + adj, a.y + (op));
							
						angle = atan( slide)/deg2rad;
						angle = 100 - angle + thick * backingScaleFactor;
						adj = (ARROWSIZE + thick * backingScaleFactor * 15) * cos( angle*deg2rad);
						op = (ARROWSIZE + thick * backingScaleFactor * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa2 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa2 = NSMakePoint( a.x + adj, a.y + (op));
					}
					else
					{
						angle = atan( slide)/deg2rad;
						
						angle = 180 + 80 - angle - thick * backingScaleFactor;
						adj = (ARROWSIZE + thick * backingScaleFactor * 15) * cos( angle*deg2rad);
						op = (ARROWSIZE + thick * backingScaleFactor * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa1 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa1 = NSMakePoint( a.x + adj, a.y + (op));
							
						angle = atan( slide)/deg2rad;
						angle = 180 + 100 - angle + thick * backingScaleFactor;
						adj = (ARROWSIZE + thick * backingScaleFactor * 15) * cos( angle*deg2rad);
						op = (ARROWSIZE + thick * backingScaleFactor * 15) * sin( angle*deg2rad);
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 )
							aa2 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
						else
							aa2 = NSMakePoint( a.x + adj, a.y + (op));
					}
					aa3 = NSMakePoint( a.x , a.y );
					
					glLineWidth( 1.0*backingScaleFactor);
					glBegin(GL_TRIANGLES);
					
					glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
					
					glVertex2f( aa1.x, aa1.y);
					glVertex2f( aa2.x, aa2.y);
					glVertex2f( aa3.x, aa3.y);
					
					glEnd();
//
//					glBegin(GL_LINE_LOOP);
//					glBlendFunc(GL_ONE_MINUS_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//					glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
//					
//					glVertex2f( aa1.x, aa1.y);
//					glVertex2f( aa2.x, aa2.y);
//					glVertex2f( aa3.x, aa3.y);
//					
//					glEnd();
				}
				else
				{
					// If there is another line, compute cobb's angle
					if( curView && displayCobbAngle && displayCMOrPixels == NO)
					{
						NSArray *roiList = curView.curRoiList;
						
						NSUInteger index = [roiList indexOfObject: self];
						if( index != NSNotFound)
						{
                            int no = 0;
                            for( ROI *r  in roiList)
                            {
                                if( [r type] == tMesure)
                                {
                                    no++;
                                    if( no >= 2)
                                        break;
                                }
                            }
                            
                            if( no >= 2)
                            {
                                BOOL f = NO;
                                for( int i = 0; i < index; i++)
                                {
                                    ROI *r = [roiList objectAtIndex: i];
                                    
                                    if( [r type] == tMesure)
                                    {
                                        f = YES;
                                        break;
                                    }
                                }
                                
                                if( f == NO)
                                {
                                    glColor4f ( 1.0, 1.0, 0.0, 0.5);
                                    glLineWidth( thick * 3. *backingScaleFactor);
                                    
                                    glBegin(GL_LINE_STRIP);
                                    for( id pt in points)
                                    {
                                        glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
                                    }
                                    glEnd();
                                    
                                    glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
                                    glLineWidth( thick * backingScaleFactor);
                                }
                            }
						}
					}
					
					glBegin(GL_LINE_STRIP);
					for( id pt in points)
					{
						glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
					}
					glEnd();
					
					glPointSize( thick * backingScaleFactor);
				
					glBegin( GL_POINTS);
					for( id pt in points)
					{
						glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
					}
					glEnd();
				}
				
				if( highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					
					if( tArrow)
						glPointSize( sqrt( thick)*3. * backingScaleFactor);
					else
						glPointSize( thick*2 * backingScaleFactor);
					
					glBegin( GL_POINTS);
					for( long i = 0; i < [points count]; i++)
					{
						if(i == selectedModifyPoint || i == PointUnderMouse)
						{
							glColor3f (1.0f, 0.2f, 0.2f);
							glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
						}
						else if( mode >= ROI_selected)
						{
							glColor3f (0.5f, 0.5f, 1.0f);
							glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
						}
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
					glPointSize( (1 * backingScaleFactor + sqrt( thick))*3.5 * backingScaleFactor);
					glBegin( GL_POINTS);
						glVertex2f( (pt.x - offsetx) * scaleValue , (pt.y - offsety) * scaleValue);
					glEnd();
				}
				
				glLineWidth(1.0*backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				if( self.isTextualDataDisplayed && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					
					if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                    else self.textualBoxLine1 = nil;
                    
					if( type == tMesure && ROITEXTNAMEONLY == NO)
					{
                        // US Regions (Length) --->
                        //if( pixelSpacingX != 0 && pixelSpacingY != 0)
                        if ((pixelSpacingX != 0 && pixelSpacingY != 0) || 
                            ([[self pix] hasUSRegions] && [[[self pix] usRegions] count] == 1)) // traitement des US contenant une seule région dont le format spatial n'est pas 2D
                        // <--- US Regions (Length)
						{
							float lPix, lCm = [self MesureLength: &lPix];
							
							if( displayCMOrPixels)   // CPR
							{
                                self.textualBoxLine2 = [ROI formattedLength: lCm];
							}
							else
							{
                                // US Regions (Length) --->
                                if ([[self pix] hasUSRegions]) {
                                    
                                    //NSLog(@"L'image courante contient une ou plusieurs régions US");

                                    NSPoint roiPoint1 = [[points objectAtIndex:0] point];
                                    NSPoint roiPoint2 = [[points objectAtIndex:1] point];

                                    //NSLog(@"ROI [point1 (%i,%i) point2 (%i,%i)]", roiPoint1X, roiPoint1Y, roiPoint2X, roiPoint2Y);

                                    NSEnumerator *usRegionsEnum = [[[self pix] usRegions] objectEnumerator];
                                    DCMUSRegion *anUsRegion;
                                    BOOL roiInsideAnUsRegion = FALSE;
                                    int regionSpatialFormat = 0;
                                    int physicalUnitsXDirection = 0;
                                    int physicalUnitsYDirection = 0;
                                    double physicalDeltaX = 0.0;
                                    double physicalDeltaY = 0.0;
                                    
                                    while (anUsRegion = [usRegionsEnum nextObject]) {

                                        //NSLog(@"US Region [upperLeft (%i,%i) lowerRight(%i,%i)]", [anUsRegion regionLocationMinX0], [anUsRegion regionLocationMinY0], [anUsRegion regionLocationMaxX1], [anUsRegion regionLocationMaxY1]);

                                        if (!roiInsideAnUsRegion) {
                                            roiInsideAnUsRegion = (((int)roiPoint1.x <= [anUsRegion regionLocationMaxX1] && (int)roiPoint1.x >= [anUsRegion regionLocationMinX0]) &&
                                                                   ((int)roiPoint1.y <= [anUsRegion regionLocationMaxY1] && (int)roiPoint1.y >= [anUsRegion regionLocationMinY0]) &&
                                                                   ((int)roiPoint2.x <= [anUsRegion regionLocationMaxX1] && (int)roiPoint2.x >= [anUsRegion regionLocationMinX0]) &&
                                                                   ((int)roiPoint2.y <= [anUsRegion regionLocationMaxY1] && (int)roiPoint2.y >= [anUsRegion regionLocationMinY0]));
                                            
                                            if (roiInsideAnUsRegion) {
                                                regionSpatialFormat = [anUsRegion regionSpatialFormat];
                                                physicalUnitsXDirection = [anUsRegion physicalUnitsXDirection];
                                                physicalUnitsYDirection = [anUsRegion physicalUnitsYDirection];
                                                physicalDeltaX = [anUsRegion physicalDeltaX];
                                                physicalDeltaY = [anUsRegion physicalDeltaY];
                                                
                                                if ((regionSpatialFormat == 0) && (physicalUnitsXDirection == 0) && (physicalUnitsYDirection == 0)) {
                                                    // RSF=none, PUXD=none, PUYD=none
                                                    roiInsideAnUsRegion = FALSE;
                                                }
                                            }
                                        }
                                    }
                                    
                                    if (roiInsideAnUsRegion) {
                                        if ((regionSpatialFormat == 1) && (physicalUnitsXDirection == 3) && (physicalUnitsYDirection == 3)) {
                                            // RSF=2D, PUXD=cm, PUYD=cm
                                            if (lCm < .01)
                                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.1f %cm", nil), lCm * 10000.0, 0xb5];
                                            else if( lCm < 1)
                                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f mm", nil), lCm * 10.];
                                            else
                                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f cm", nil), lCm];
                                        } else {
                                            // Other formats
                                            double lengthX = fabs(roiPoint2.x - roiPoint1.x) * fabs(physicalDeltaX);
                                            double lengthY = fabs(roiPoint2.y - roiPoint1.y) * fabs(physicalDeltaY);
                                            
                                            NSArray * physicalUnitsXYDirection = [NSArray arrayWithObjects:
                                                                                  NSLocalizedString( @"none", nil), @"%", NSLocalizedString( @"dB", @"decibel"), NSLocalizedString( @"cm", nil), NSLocalizedString( @"sec", @"second"), NSLocalizedString( @"hertz", nil), NSLocalizedString( @"dB/sec", @"decibel per second"), NSLocalizedString( @"cm/sec", nil), NSLocalizedString( @"cm\u00B2", @"cm2"), NSLocalizedString( @"cm\u00B2/sec", @"cm2/sec"), NSLocalizedString( @"cm\u00B3", @"cm3"), NSLocalizedString( @"cm\u00B3/sec", @"cm3/sec"), @"\u00B0", nil];
                                            
                                            NSString * unitsX;
                                            NSString * unitsY;
                                            if ((physicalUnitsXDirection < 0) || (physicalUnitsXDirection > 12)) {
                                                unitsX = NSLocalizedString( @"unknown", nil);
                                            } else if ((physicalUnitsYDirection < 0) || (physicalUnitsYDirection > 12)) {
                                                unitsY = NSLocalizedString( @"unknown", nil);
                                            } else {
                                                unitsX = [physicalUnitsXYDirection objectAtIndex:physicalUnitsXDirection];
                                                unitsY = [physicalUnitsXYDirection objectAtIndex:physicalUnitsYDirection];
                                            }
                                            
                                            if (([unitsY isEqualToString: NSLocalizedString( @"cm/sec", nil)]) && (lengthY >= 100.0)) {
                                                unitsY = NSLocalizedString( @"m/sec", nil);
                                                lengthY = lengthY / 100.0;
                                            }
                                            
                                            self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: X=%0.3f %@, Y=%0.3f %@", nil), lengthX, unitsX, lengthY, unitsY];
                                        }
                                    } else
                                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f pix", nil), lPix];
                                } else   // <--- US Regions (Length)
                                    if (lCm < .01)
                                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.1f %cm", nil), lCm * 10000.0, 0xb5];
                                    else if (lCm < 1)
                                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f mm", nil), lCm * 10.];
                                    else
                                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f cm", nil), lCm];
							}
						}
						else
							self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f pix", nil), [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]]];
						
						// If there is another line, compute cobb's angle
						if( curView && displayCobbAngle && displayCMOrPixels == NO)
						{
							NSArray *roiList = curView.curRoiList;
							
							NSUInteger index = [roiList indexOfObject: self];
							if( index != NSNotFound)
							{
								if( index > 0)
								{
									for( int i = 0 ; i < index; i++)
									{
										ROI *r = [roiList objectAtIndex: i];
										
										if( [r type] == tMesure)
										{
											NSArray *B = [r points];
											NSPoint	u1 = [[[self points] objectAtIndex: 0] point], u2 = [[[self points] objectAtIndex: 1] point], v1 = [[B objectAtIndex: 0] point], v2 = [[B objectAtIndex: 1] point];
											
											float pX = [curView.curDCM pixelSpacingX];
											float pY = [curView.curDCM pixelSpacingY];
											
											if( pX == 0 || pY == 0)
											{
												pX = 1;
												pY = 1;
											}
											
											NSPoint a1 = NSMakePoint(u1.x * pX, u1.y * pY);
											NSPoint a2 = NSMakePoint(u2.x * pX, u2.y * pY);
											NSPoint b1 = NSMakePoint(v1.x * pX, v1.y * pY);
											NSPoint b2 = NSMakePoint(v2.x * pX, v2.y * pY);
											
                                            double angle = [self angleBetween2Lines: a1 :a2 :b1 :b2];
                                            
                                            if( angle < -180)
                                                angle = -180 - angle;
                                            else if( angle < -90)
                                                angle += 180;
                                            else if( angle < 0)
                                                angle *= -1;
                                            
                                            if( angle > 270)
                                                angle = 360 - angle;
                                            else if( angle > 180)
                                                angle -= 180;
                                            else if( angle > 90)
                                                angle = 180 -angle;
                                            
                                            NSString *rName = r.name;
                                            
                                            if( [rName isEqualToString: @"Unnamed"] || [rName isEqualToString: NSLocalizedString( @"Unnamed", nil)])
                                                rName = nil;
                                            
                                            if( rName)
                                                self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Angle: %0.2f%@ with: %@", nil), angle, @"\u00B0", rName];
                                            else
                                                self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Angle: %0.2f%@", nil), angle, @"\u00B0"];
                                            
                                            break;
										}
									}
								}
							}
						}
					}
					[self prepareTextualData:tPt];
				}
			}
			break;
#pragma mark tROI
			case tROI:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				glLineWidth( thick*backingScaleFactor);
				glBegin(GL_LINE_LOOP);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glEnd();
				
				glPointSize( thick * backingScaleFactor);
				glBegin( GL_POINTS);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glEnd();
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( (1 * backingScaleFactor + sqrt( thick))*3.5 * backingScaleFactor);
					glBegin( GL_POINTS);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
					glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
					glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
					glEnd();
				}
				
				glLineWidth(1.0*backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				{
					if( self.isTextualDataDisplayed && prepareTextualData)
                    {
						NSPoint			tPt = self.lowerRightPoint;
						
						if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
						else self.textualBoxLine1 = nil;
						
						if( ROITEXTNAMEONLY == NO )
						{
							if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax :&rskewness :&rkurtosis];
							
                            // US Regions (Rectangle) --->
                            BOOL roiInside2DUSRegion = FALSE;
                            if ([[self pix] hasUSRegions]) {

                                NSPoint roiPoint1 = NSMakePoint(rect.origin.x, rect.origin.y);
                                NSPoint roiPoint2 = NSMakePoint(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
                                
                                //NSLog(@"roi [%i,%i] [%i,%i]", (int)roiPoint1.x, (int)roiPoint1.y, (int)roiPoint2.x, (int)roiPoint2.y);
                                
                                NSEnumerator *usRegionsEnum = [[[self pix] usRegions] objectEnumerator];
                                DCMUSRegion *anUsRegion;
                                
                                while(anUsRegion = [usRegionsEnum nextObject]) {
                                    if (!roiInside2DUSRegion && [anUsRegion regionSpatialFormat] == 1) {
                                        // 2D spatial format
                                        int usRegionMinX = [anUsRegion regionLocationMinX0];
                                        int usRegionMinY = [anUsRegion regionLocationMinY0];
                                        int usRegionMaxX = [anUsRegion regionLocationMaxX1];
                                        int usRegionMaxY = [anUsRegion regionLocationMaxY1];
                                        
                                        //NSLog(@"usRegion [%i,%i] [%i,%i]", usRegionMinX, usRegionMinY, usRegionMaxX, usRegionMaxY);
                                        
                                        roiInside2DUSRegion = (((int)roiPoint1.x >= usRegionMinX) && ((int)roiPoint1.x <= usRegionMaxX) &&
                                                               ((int)roiPoint1.y >= usRegionMinY) && ((int)roiPoint1.y <= usRegionMaxY) &&
                                                               ((int)roiPoint2.x >= usRegionMinX) && ((int)roiPoint2.x <= usRegionMaxX) &&
                                                               ((int)roiPoint2.y >= usRegionMinY) && ((int)roiPoint2.y <= usRegionMaxY));
                                    }
                                }
                                
                            }
                            //if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
                            if (roiInside2DUSRegion || (pixelSpacingX != 0 && pixelSpacingY != 0 && ![[self pix] hasUSRegions])) {
                            // <--- US Regions (Rectangle)
                                if ( fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY) < 1.)
                                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.1f %cm\u00B2 (W: %0.1f %cm H: %0.1f %cm)", @"W = Width, H = Height"), fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY * 1000000.0), 0xB5, fabs(NSWidth(rect)*pixelSpacingX)*1000.0, 0xB5, fabs(NSHeight(rect)*pixelSpacingY)*1000.0, 0xB5];
                                else if ( fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY)/100. < 1.)
                                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f mm\u00B2 (W: %0.3f mm H: %0.3f mm)", @"W = Width, H = Height"), fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY), fabs(NSWidth(rect)*pixelSpacingX), fabs(NSHeight(rect)*pixelSpacingY)];
                                else
                                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f cm\u00B2 (W: %0.3f cm H: %0.3f cm)", @"W = Width, H = Height"), fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY/100.), fabs(NSWidth(rect)*pixelSpacingX)/10., fabs(NSHeight(rect)*pixelSpacingY)/10.];
                            }
                            else
                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f pix2 (W: %0.3f pix H: %0.3f pix)", @"W = Width, H = Height"), fabs( NSWidth(rect)*NSHeight(rect)), fabs(NSWidth(rect)), fabs(NSHeight(rect))];
                            
                            NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", self.pix.rescaleType];
                            
                            if( [self pix].SUVConverted)
                                pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                            
							self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), rmean, pixelUnit, rdev, pixelUnit, rtotal, pixelUnit];
                            if( rskewness || rkurtosis)
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), rmin, pixelUnit, rmax, pixelUnit, rskewness, rkurtosis];
                            else
                                self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@", nil), rmin, pixelUnit, rmax, pixelUnit];
							
							if( [curView blendingView])
							{
								DCMPix	*blendedPix = [[curView blendingView] curDCM];
								
								ROI *blendedROI = [[[ROI alloc] initWithType: type :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
								
								NSRect blendedRect = [self rect];
								NSPoint downRight = NSMakePoint( blendedRect.origin.x + blendedRect.size.width, blendedRect.origin.y + blendedRect.size.height);
								
								blendedRect.origin = [curView ConvertFromGL2GL: blendedRect.origin toView:[curView blendingView]];
								
								downRight = [curView ConvertFromGL2GL: downRight toView:[curView blendingView]];
								
								blendedRect.size.width = downRight.x - blendedRect.origin.x;
								blendedRect.size.height = downRight.y - blendedRect.origin.y;
								
								[blendedROI setROIRect: blendedRect];
								
								[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax :&Brskewness :&Brkurtosis];
								
                                NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", blendedPix.rescaleType];
                                
                                if( blendedPix.SUVConverted)
                                    pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                                
								self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), Brmean, pixelUnit, Brdev, pixelUnit, Brtotal, pixelUnit];
                                
                                if( Brskewness || Brkurtosis)
                                    self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), Brmin, pixelUnit, Brmax, pixelUnit, Brskewness, Brkurtosis];
                                else
                                    self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@", nil), Brmin, pixelUnit, Brmax, pixelUnit];
							}
						}
						
						[self prepareTextualData:tPt];
					}
				}
			}
			break;
#pragma mark tOval
			case tOval:
			{
				float angle;
				
				glColor4f( color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				glLineWidth( thick*backingScaleFactor);
				
				NSRect rrect = rect;
				
				if( rrect.size.height < 0)
					rrect.size.height = -rrect.size.height;
				
				if( rrect.size.width < 0)
					rrect.size.width = -rrect.size.width;
				
				int resol = (rrect.size.height + rrect.size.width) * 1.5 * scaleValue;
				
				glBegin(GL_LINE_LOOP);
				for( int i = 0; i < resol ; i++ )
				{
					angle = i * 2 * M_PI /resol;
				  
				  glVertex2f( (rrect.origin.x + rrect.size.width*cos(angle) - offsetx)*scaleValue, (rrect.origin.y + rrect.size.height*sin(angle)- offsety)*scaleValue);
				}
				glEnd();
				
				glPointSize( thick * backingScaleFactor);
				glBegin( GL_POINTS);
				for( int i = 0; i < resol ; i++ )
				{
					angle = i * 2 * M_PI /resol;
				  
				  glVertex2f( (rrect.origin.x + rrect.size.width*cos(angle) - offsetx)*scaleValue, (rrect.origin.y + rrect.size.height*sin(angle)- offsety)*scaleValue);
				}
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"drawROICircleCenter"])
                    glVertex2f( (rrect.origin.x - offsetx) * scaleValue, (rrect.origin.y - offsety) * scaleValue);
                
				glEnd();
				
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( (1 * backingScaleFactor + sqrt( thick))*3.5 * backingScaleFactor);
					glBegin( GL_POINTS);
					glVertex2f( (rrect.origin.x - offsetx - rrect.size.width) * scaleValue, (rrect.origin.y - rrect.size.height - offsety) * scaleValue);
					glVertex2f( (rrect.origin.x - offsetx - rrect.size.width) * scaleValue, (rrect.origin.y + rrect.size.height - offsety) * scaleValue);
					glVertex2f( (rrect.origin.x + rrect.size.width - offsetx) * scaleValue, (rrect.origin.y + rrect.size.height - offsety) * scaleValue);
					glVertex2f( (rrect.origin.x + rrect.size.width - offsetx) * scaleValue, (rrect.origin.y - rrect.size.height - offsety) * scaleValue);
					
					//Center
					glVertex2f( (rrect.origin.x - offsetx) * scaleValue, (rrect.origin.y - offsety) * scaleValue);
					glEnd();
				}
				
				glLineWidth(1.0*backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);
				
				// TEXT
				
				if( self.isTextualDataDisplayed && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					
					if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                    else self.textualBoxLine1 = nil;
                    
					if( ROITEXTNAMEONLY == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax :&rskewness :&rkurtosis];
						
                        // US Regions (Oval) --->
                        BOOL roiInside2DUSRegion = FALSE;
                        if ([[self pix] hasUSRegions]) {
                            
                            NSPoint roiPoint1 = NSMakePoint(rrect.origin.x-rrect.size.width, rrect.origin.y-rrect.size.height);
                            NSPoint roiPoint2 = NSMakePoint(rrect.origin.x+rrect.size.width, rrect.origin.y+rrect.size.height);
                            
                            //NSLog(@"roi [%i,%i] [%i,%i]", (int)roiPoint1.x, (int)roiPoint1.y, (int)roiPoint2.x, (int)roiPoint2.y);
                            
                            NSEnumerator *usRegionsEnum = [[[self pix] usRegions] objectEnumerator];
                            DCMUSRegion *anUsRegion;
                            
                            while(anUsRegion = [usRegionsEnum nextObject]) {
                                if (!roiInside2DUSRegion && [anUsRegion regionSpatialFormat] == 1) {
                                    // 2D spatial format
                                    int usRegionMinX = [anUsRegion regionLocationMinX0];
                                    int usRegionMinY = [anUsRegion regionLocationMinY0];
                                    int usRegionMaxX = [anUsRegion regionLocationMaxX1];
                                    int usRegionMaxY = [anUsRegion regionLocationMaxY1];
                                    
                                    //NSLog(@"usRegion [%i,%i] [%i,%i]", usRegionMinX, usRegionMinY, usRegionMaxX, usRegionMaxY);
                                    
                                    roiInside2DUSRegion = (((int)roiPoint1.x >= usRegionMinX) && ((int)roiPoint1.x <= usRegionMaxX) &&
                                                           ((int)roiPoint1.y >= usRegionMinY) && ((int)roiPoint1.y <= usRegionMaxY) &&
                                                           ((int)roiPoint2.x >= usRegionMinX) && ((int)roiPoint2.x <= usRegionMaxX) &&
                                                           ((int)roiPoint2.y >= usRegionMinY) && ((int)roiPoint2.y <= usRegionMaxY));
                                }
                            }
                        }
                        //if( pixelSpacingX != 0 && pixelSpacingY != 0)
                        if (roiInside2DUSRegion || (pixelSpacingX != 0 && pixelSpacingY != 0 && ![[self pix] hasUSRegions]))
                        // <--- US Regions (Oval)
                        {
                            float area = [self EllipseArea];
                            if( area*pixelSpacingX*pixelSpacingY < 1.)
                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.1f %cm\u00B2 (W: %0.1f %cm H: %0.1f %cm)", @"W = Width, H = Height"), area*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5, 2.0*fabs(NSWidth(rect))*pixelSpacingX*10000.0, 0xB5, 2.0*fabs(NSHeight(rect))*pixelSpacingY*10000.0, 0xB5];
                            else if( area*pixelSpacingX*pixelSpacingY/100. < 1.)
                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f mm\u00B2 (W: %0.3f mm H: %0.3f mm)", @"W = Width, H = Height"), area*pixelSpacingX*pixelSpacingY, 2.0*fabs(NSWidth(rect))*pixelSpacingX, 2.0*fabs(NSHeight(rect))*pixelSpacingY];
                            else
                                self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f cm\u00B2 (W: %0.3f cm H: %0.3f cm)", @"W = Width, H = Height"), area*pixelSpacingX*pixelSpacingY/100., 2.0*fabs(NSWidth(rect))*pixelSpacingX/10., 2.0*fabs(NSHeight(rect))*pixelSpacingY/10.];
                        }
                        else
                            self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f pix2 (W: %0.3f pix H: %0.3f pix)", @"W = Width, H = Height"), [self EllipseArea], 2.0*fabs(NSWidth(rect)), 2.0*fabs(NSHeight(rect))];
                        
                        NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", self.pix.rescaleType];
                        
                        if( [self pix].SUVConverted)
                            pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                        
						self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), rmean, pixelUnit, rdev, pixelUnit, rtotal, pixelUnit];
                        
                        if( rskewness || rkurtosis)
                            self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), rmin, pixelUnit, rmax, pixelUnit, rskewness, rkurtosis];
						else
                            self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@", nil), rmin, pixelUnit, rmax, pixelUnit];
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
							
							NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
							
							for( MyPoint *p in pts)
								[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
							
							[blendedROI setPoints: pts];
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax :&Brskewness :&Brkurtosis];
							
                            NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", blendedPix.rescaleType];
                            
                            if( blendedPix.SUVConverted)
                                pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                            
							self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), Brmean, pixelUnit, Brdev, pixelUnit, Brtotal, pixelUnit];
                            if( Brskewness || Brkurtosis)
                                self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), Brmin, pixelUnit, Brmax, pixelUnit, Brskewness, Brkurtosis];
                            else
                                self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@", nil), Brmin, pixelUnit, Brmax, pixelUnit];
						}
					}
					
					[self prepareTextualData:tPt];
				}
			}
			break;
#pragma mark tAxis
			case tAxis:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				if( mode == ROI_drawing) 
					glLineWidth( thick * 2*backingScaleFactor);
				else 
					glLineWidth( thick * backingScaleFactor);
				
				glBegin(GL_LINE_LOOP);
				
				for( long i = 0; i < [points count]; i++)
				{				
					//NSLog(@"JJCP--	tAxis- New point: %f x, %f y",[[points objectAtIndex:i] x],[[points objectAtIndex:i] y]);
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
					if(i>2)
					{
						//glEnd();
						break;
					}
				}
				glEnd();
				if( [points count]>3 )
				{
					for( long i=4;i<[points count];i++ ) [points removeObjectAtIndex: i];
				}
				//TEXT
				if( self.isTextualDataDisplayed && prepareTextualData)
				{
					NSPoint tPt = self.lowerRightPoint;
					
					if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                    else self.textualBoxLine1 = nil;
                    
					[self prepareTextualData:tPt];
				}
					if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
					{
						NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: nil];
						tempPt = [curView ConvertFromNSView2GL:tempPt];
						
						glColor3f (0.5f, 0.5f, 1.0f);
						glPointSize( (1 * backingScaleFactor + sqrt( thick))*3.5 * backingScaleFactor);
						glBegin( GL_POINTS);
						for( long i = 0; i < [points count]; i++) {
							if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
							else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/(thick*backingScaleFactor) :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
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
				glLineWidth(1.0*backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);			
			}
			break;
#pragma mark tTAGT
            case tTAGT:
            if( [points count] == 6)
            {
                [self valid];
                
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
                glLineWidth(thick * backingScaleFactor);
                
                // B
				glBegin(GL_LINE_STRIP);
                glVertex2f( ([[points objectAtIndex: 0] x]- offsetx) * scaleValue , ([[points objectAtIndex: 0] y]- offsety) * scaleValue);
				glVertex2f( ([[points objectAtIndex: 1] x]- offsetx) * scaleValue , ([[points objectAtIndex: 1] y]- offsety) * scaleValue);
				glEnd();
                
                // C
                glBegin(GL_LINE_STRIP);
                glVertex2f( ([[points objectAtIndex: 2] x]- offsetx) * scaleValue , ([[points objectAtIndex: 2] y]- offsety) * scaleValue);
				glVertex2f( ([[points objectAtIndex: 3] x]- offsetx) * scaleValue , ([[points objectAtIndex: 3] y]- offsety) * scaleValue);
				glEnd();
                
                // A : main line
                glBegin(GL_LINE_STRIP);
                glVertex2f( ([[points objectAtIndex: 4] x]- offsetx) * scaleValue , ([[points objectAtIndex: 4] y]- offsety) * scaleValue);
				glVertex2f( ([[points objectAtIndex: 5] x]- offsetx) * scaleValue , ([[points objectAtIndex: 5] y]- offsety) * scaleValue);
				glEnd();
                
				//TEXT
				if( self.isTextualDataDisplayed && prepareTextualData)
				{
                    NSPoint tPt = self.lowerRightPoint;
                    
                    if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                    else self.textualBoxLine1 = nil;
                    
                    float lCm = [self MesureLength: nil pointA: [[points objectAtIndex: 4] point] pointB: [[points objectAtIndex: 5] point]];
                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"A: %@", nil), [ROI formattedLength: lCm]];
                    
                    lCm = [self MesureLength: nil pointA: [[points objectAtIndex: 0] point] pointB: [[points objectAtIndex: 1] point]];
                    self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"B: %@", nil), [ROI formattedLength: lCm]];
                    
                    lCm = [self MesureLength: nil pointA: [[points objectAtIndex: 2] point] pointB: [[points objectAtIndex: 3] point]];
                    self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"C: %@", nil), [ROI formattedLength: lCm]];
                    
                    lCm = [self MesureLength: nil pointA: [[points objectAtIndex: 0] point] pointB: [[points objectAtIndex: 2] point]];
                    self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"B-C: %@", nil), [ROI formattedLength: lCm]];
                    
                    [self prepareTextualData:tPt];
				}
				//ROI MODE
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: nil];
					tempPt = [curView ConvertFromNSView2GL:tempPt];
					
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( thick*2 * backingScaleFactor);
					glBegin( GL_POINTS);
					for( long i = 0; i < [points count]; i++)
                    {
                        if( i == 0 || i == 2)
                            continue;
                        
						if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
						else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/(thick*backingScaleFactor) :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
						else
                            glColor3f (0.5f, 0.5f, 1.0f);
                        
						glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
					}
					glEnd();
				}
				
				glLineWidth(1.0 * backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);
                
                // --- Text
                if( stanStringAttrib == nil)
                {
                    stanStringAttrib = [[NSMutableDictionary dictionary] retain];
                    [stanStringAttrib setObject:[NSFont fontWithName:@"Helvetica" size: 14.0] forKey:NSFontAttributeName];
                    [stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
                }
                
                if( stringTexA == nil)
                {
                    stringTexA = [[StringTexture alloc] initWithString: @"A"
                                                        withAttributes:stanStringAttrib
                                                         withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
                                                          withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
                                                       withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
                    [stringTexA setAntiAliasing: YES];
                    [stringTexA genTextureWithBackingScaleFactor: curView.window.backingScaleFactor];
                }
                if( stringTexB == nil)
                {
                    stringTexB = [[StringTexture alloc] initWithString: @"B"
                                                        withAttributes:stanStringAttrib
                                                         withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
                                                          withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
                                                       withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
                    [stringTexB setAntiAliasing: YES];
                    [stringTexB genTextureWithBackingScaleFactor: curView.window.backingScaleFactor];
                }
                if( stringTexC == nil)
                {
                    stringTexC = [[StringTexture alloc] initWithString: @"C"
                                                        withAttributes:stanStringAttrib
                                                         withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
                                                          withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
                                                       withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
                    [stringTexC setAntiAliasing: YES];
                    [stringTexC genTextureWithBackingScaleFactor: curView.window.backingScaleFactor];
                }
                
                glEnable (GL_TEXTURE_RECTANGLE_EXT);
                glEnable(GL_BLEND);
                glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
                
                for( int i = 0; i < [points count]; i+=2)
                {
                    [stringTexA setFlippedX: [curView xFlipped] Y:[curView yFlipped]];
                    [stringTexB setFlippedX: [curView xFlipped] Y:[curView yFlipped]];
                    [stringTexC setFlippedX: [curView xFlipped] Y:[curView yFlipped]];
                    
                    StringTexture *tex = nil;
                    if( i == 0) tex = stringTexB;
                    if( i == 2) tex = stringTexC;
                    if( i == 4) tex = stringTexA;
                    
                    NSPoint tPt = [[points objectAtIndex: i+1] point];
                    
                    glColor4f (0, 0, 0, 1);	[tex drawAtPoint:NSMakePoint((tPt.x+1./scaleValue - offsetx) * scaleValue, (tPt.y+1./scaleValue- offsety) * scaleValue) ratio: 1];
                    glColor4f (1, 1, 0, 1);	[tex drawAtPoint:NSMakePoint((tPt.x- offsetx) * scaleValue, (tPt.y- offsety) * scaleValue) ratio: 1];
                }
                
                glDisable (GL_TEXTURE_RECTANGLE_EXT);
                
			}
            break;
                
#pragma mark tDynAngle
			case tDynAngle:
			{
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				if( mode == ROI_drawing) 
					glLineWidth(thick * 2 * backingScaleFactor);
				else 
					glLineWidth(thick * backingScaleFactor);
				
				glBegin(GL_LINE_STRIP);
				
				for( long i = 0; i < [points count]; i++)
                {
					if(i==1||i==2)
						glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., 0.1);
					else
						glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
                    
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
					if(i>2)
						break;
				}
				glEnd();
				if( [points count]>3)
				{
					for( long i=4; i<[points count]; i++ ) [points removeObjectAtIndex: i];
				}
				NSPoint a1,a2,b1,b2;
				float angle=0;
				if([points count]>3)
				{
					a1 = [[points objectAtIndex: 0] point];
					a2 = [[points objectAtIndex: 1] point];
					b1 = [[points objectAtIndex: 2] point];
					b2 = [[points objectAtIndex: 3] point];
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0)
					{
						a1 = NSMakePoint(a1.x * pixelSpacingX, a1.y * pixelSpacingY);
						a2 = NSMakePoint(a2.x * pixelSpacingX, a2.y * pixelSpacingY);
						b1 = NSMakePoint(b1.x * pixelSpacingX, b1.y * pixelSpacingY);
						b2 = NSMakePoint(b2.x * pixelSpacingX, b2.y * pixelSpacingY);
					}
					
                    angle = [self angleBetween2Lines: a1 :a2 :b1 :b2];
                    
                    if( angle < -180)
                        angle = -180 - angle;
                    else if( angle < -90)
                        angle += 180;
                    else if( angle < 0)
                        angle *= -1;
                    
                    if( angle > 270)
                        angle = 360 - angle;
                    else if( angle > 180)
                        angle -= 180;
                    else if( angle > 90)
                        angle = 180 -angle;
				}
				//TEXT
				if( self.isTextualDataDisplayed && prepareTextualData)
				{
                    NSPoint tPt = self.lowerRightPoint;
                    
                    if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                    else self.textualBoxLine1 = nil;
                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Angle: %0.2f%@", nil), angle, @"\u00B0"];
                    self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Angle 2: %0.2f%@", nil), 360 - angle, @"\u00B0"];
                    self.textualBoxLine4 = nil;
                    self.textualBoxLine5 = nil;
                    
                    [self prepareTextualData:tPt];
				}
				//ROI MODE
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: nil];
					tempPt = [curView ConvertFromNSView2GL:tempPt];
					
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( (1 * backingScaleFactor + sqrt( thick))*3.5 * backingScaleFactor);
					glBegin( GL_POINTS);
					for( long i = 0; i < [points count]; i++)
                    {
						if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
						else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/(thick*backingScaleFactor) :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
						else glColor3f (0.5f, 0.5f, 1.0f);
						
						glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
					}
					glEnd();
				}
				
				glLineWidth(1.0 * backingScaleFactor);
				glColor3f (1.0f, 1.0f, 1.0f);
			}
			break;
#pragma mark tCPolygon, tOPolygon, tAngle, tPencil
			case tCPolygon:
			case tOPolygon:
			case tAngle:
			case tPencil:
			{
				#define RATIO_FOROPOLYGONAREA 3.
			
				glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				if( mode == ROI_drawing) glLineWidth(thick * 2 * backingScaleFactor);
				else glLineWidth(thick * backingScaleFactor);
				
				NSMutableArray *splinePoints = [self splinePoints: scaleValue];
				
				if( [splinePoints count] >= 1)
				{
					if( (type == tCPolygon || type == tPencil) && mode != ROI_drawing ) glBegin(GL_LINE_LOOP);
					else glBegin(GL_LINE_STRIP);
					
					for(long i=0; i<[splinePoints count]; i++)
					{
						glVertex2d( ((double) [[splinePoints objectAtIndex:i] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints objectAtIndex:i] y]-(double) offsety)*(double) scaleValue);
					}
					glEnd();
					
					if( type == tOPolygon)
					{
						float length = 0;
						for( int i = 0; i < (long)[splinePoints count]-1; i++)
							length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
								
						// The first and the last point are too far away : probably not a good idea to display the Area
						if( [self Length: [[splinePoints objectAtIndex: 0] point] :[[splinePoints lastObject] point]] < length / RATIO_FOROPOLYGONAREA)
						{
							glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity/4.);
							glBegin(GL_LINE_STRIP);
							glVertex2d( ((double) [[splinePoints objectAtIndex: 0] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints objectAtIndex: 0] y]-(double) offsety)*(double) scaleValue);
							glVertex2d( ((double) [[splinePoints lastObject] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints lastObject] y]-(double) offsety)*(double) scaleValue);
							glEnd();
							glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
						}
					}
					
					if( mode == ROI_drawing) glPointSize( thick * 2 * backingScaleFactor);
					else glPointSize( thick * backingScaleFactor);
					
					glBegin( GL_POINTS);
					for(long i=0; i<[splinePoints count]; i++)
					{
						glVertex2d( ((double) [[splinePoints objectAtIndex:i] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints objectAtIndex:i] y]-(double) offsety)*(double) scaleValue);
					}
					glEnd();
					
					// TEXT
					if( type == tCPolygon || type == tPencil)
					{
						if( self.isTextualDataDisplayed && prepareTextualData)
						{
							NSPoint tPt = self.lowerRightPoint;
							float   length;
							
							if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                            else self.textualBoxLine1 = nil;
                            
							if( ROITEXTNAMEONLY == NO )
							{
								if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax :&rskewness :&rkurtosis];
                                
                                // US Regions (Pencil or Closed Polygon) --->
                                BOOL roiInside2DUSRegion = FALSE;
                                if ([[self pix] hasUSRegions]) {
                                
                                    MyPoint *firstPoint = [splinePoints objectAtIndex:0];
                                
                                    float xMin = [firstPoint x];
                                    float xMax = [firstPoint x];
                                    float yMin = [firstPoint y];
                                    float yMax = [firstPoint y];
                                    
                                    float x, y;
                                    
                                    for (MyPoint *aPoint in splinePoints) {
                                        x = [aPoint x];
                                        y = [aPoint y];
                                        
                                        if (x < xMin) xMin = x;
                                        if (x > xMax) xMax = x;
                                        if (y < yMin) yMin = y;
                                        if (y > yMax) yMax = y;
                                    }
                                    
                                    NSPoint roiPoint1 = NSMakePoint(xMin, yMin);
                                    NSPoint roiPoint2 = NSMakePoint(xMax, yMax);
                                    
                                    //NSLog(@"roi [%i,%i] [%i,%i]", (int)roiPoint1.x, (int)roiPoint1.y, (int)roiPoint2.x, (int)roiPoint2.y);
                                    
                                    NSEnumerator *usRegionsEnum = [[[self pix] usRegions] objectEnumerator];
                                    DCMUSRegion *anUsRegion;
                                    
                                    while(anUsRegion = [usRegionsEnum nextObject]) {
                                        if (!roiInside2DUSRegion && [anUsRegion regionSpatialFormat] == 1) {
                                            // 2D spatial format
                                            int usRegionMinX = [anUsRegion regionLocationMinX0];
                                            int usRegionMinY = [anUsRegion regionLocationMinY0];
                                            int usRegionMaxX = [anUsRegion regionLocationMaxX1];
                                            int usRegionMaxY = [anUsRegion regionLocationMaxY1];
                                            
                                            //NSLog(@"usRegion [%i,%i] [%i,%i]", usRegionMinX, usRegionMinY, usRegionMaxX, usRegionMaxY);
                                            
                                            roiInside2DUSRegion = (((int)roiPoint1.x >= usRegionMinX) && ((int)roiPoint1.x <= usRegionMaxX) &&
                                                                   ((int)roiPoint1.y >= usRegionMinY) && ((int)roiPoint1.y <= usRegionMaxY) &&
                                                                   ((int)roiPoint2.x >= usRegionMinX) && ((int)roiPoint2.x <= usRegionMaxX) &&
                                                                   ((int)roiPoint2.y >= usRegionMinY) && ((int)roiPoint2.y <= usRegionMaxY));
                                        }
                                    }
                                }
                                //if( pixelSpacingX != 0 && pixelSpacingY != 0 )
                                if (roiInside2DUSRegion || (pixelSpacingX != 0 && pixelSpacingY != 0 && ![[self pix] hasUSRegions]))
                                // <--- US Regions (Pencil or Closed Polygon)
                                {
                                    float area = [self Area];
                                    
                                    if( area *pixelSpacingX*pixelSpacingY < 1.)
                                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.1f %cm\u00B2", nil), area *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5];
                                    else if(area *pixelSpacingX*pixelSpacingY/100. < 1.)
                                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f mm\u00B2", nil), area *pixelSpacingX*pixelSpacingY];
                                    else
                                        self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f cm\u00B2", nil), area *pixelSpacingX*pixelSpacingY / 100.];
                                }
                                else
                                    self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f pix2", nil), [self Area]];
                                
                                NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", self.pix.rescaleType];
                                
                                if( [self pix].SUVConverted)
                                    pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                                
                                self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), rmean, pixelUnit, rdev, pixelUnit, rtotal, pixelUnit];
                                if( rskewness || rkurtosis)
                                    self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), rmin, pixelUnit, rmax, pixelUnit, rskewness, rkurtosis];
								else
                                    self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@", nil), rmin, pixelUnit, rmax, pixelUnit];
                                
								length = 0;
								
								if( [splinePoints count] < 2)
								{
									self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f cm", nil), length];
								}
								else
								{
									if( [curView blendingView])
									{
										DCMPix	*blendedPix = [[curView blendingView] curDCM];
										
										ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
										
										NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
										
										for( MyPoint *p in pts)
											[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
										
										[blendedROI setPoints: pts];
										[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax :&Brskewness :&Brkurtosis];
										
                                        NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", blendedPix.rescaleType];
                                        
                                        if( blendedPix.SUVConverted)
                                            pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                                        
										self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), Brmean, pixelUnit, Brdev, pixelUnit, Brtotal, pixelUnit];
                                        
                                        if( Brskewness || Brkurtosis)
                                            self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@ Skewness: %0.3f Kurtosis: %0.3f", nil), Brmin, pixelUnit, Brmax, pixelUnit, Brskewness, Brkurtosis];
                                        else
                                            self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@", nil), Brmin, pixelUnit, Brmax, pixelUnit];
									}
									else
									{
										int i = 0;
										for( i = 0; i < (long)[splinePoints count]-1; i++ )
										{
											length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
										}
										length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:0] point]];
										
										if (length < .01)
											self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.1f %cm", nil), length * 10000.0, 0xB5];
                                        else if (length < 1)
											self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f mm", nil), length * 10.0];
										else
											self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f cm", nil), length];
									}
								}
							}
							
							[self prepareTextualData:tPt];
						}
					}
					else if( type == tOPolygon)
					{
						if( self.isTextualDataDisplayed && prepareTextualData)
						{
							NSPoint tPt = self.lowerRightPoint;
							float   length;
							
							if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                            else self.textualBoxLine1 = nil;
                            
							if( ROITEXTNAMEONLY == NO )
							{
								if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax :&rskewness :&rkurtosis];
                                
                                // US Regions (Opened Polygon) --->
                                BOOL roiInside2DUSRegion = FALSE;
                                if ([[self pix] hasUSRegions]) {
                                    
                                    MyPoint *firstPoint = [splinePoints objectAtIndex:0];
                                    
                                    float xMin = [firstPoint x];
                                    float xMax = [firstPoint x];
                                    float yMin = [firstPoint y];
                                    float yMax = [firstPoint y];
                                    
                                    float x, y;
                                    
                                    for (MyPoint *aPoint in splinePoints) {
                                        x = [aPoint x];
                                        y = [aPoint y];
                                        
                                        if (x < xMin) xMin = x;
                                        if (x > xMax) xMax = x;
                                        if (y < yMin) yMin = y;
                                        if (y > yMax) yMax = y;
                                    }
                                    
                                    NSPoint roiPoint1 = NSMakePoint(xMin, yMin);
                                    NSPoint roiPoint2 = NSMakePoint(xMax, yMax);
                                    
                                    //NSLog(@"roi [%i,%i] [%i,%i]", (int)roiPoint1.x, (int)roiPoint1.y, (int)roiPoint2.x, (int)roiPoint2.y);
                                    
                                    NSEnumerator *usRegionsEnum = [[[self pix] usRegions] objectEnumerator];
                                    DCMUSRegion *anUsRegion;
                                    
                                    while(anUsRegion = [usRegionsEnum nextObject]) {
                                        if (!roiInside2DUSRegion && [anUsRegion regionSpatialFormat] == 1) {
                                            // 2D spatial format
                                            int usRegionMinX = [anUsRegion regionLocationMinX0];
                                            int usRegionMinY = [anUsRegion regionLocationMinY0];
                                            int usRegionMaxX = [anUsRegion regionLocationMaxX1];
                                            int usRegionMaxY = [anUsRegion regionLocationMaxY1];
                                            
                                            //NSLog(@"usRegion [%i,%i] [%i,%i]", usRegionMinX, usRegionMinY, usRegionMaxX, usRegionMaxY);
                                            
                                            roiInside2DUSRegion = (((int)roiPoint1.x >= usRegionMinX) && ((int)roiPoint1.x <= usRegionMaxX) &&
                                                                   ((int)roiPoint1.y >= usRegionMinY) && ((int)roiPoint1.y <= usRegionMaxY) &&
                                                                   ((int)roiPoint2.x >= usRegionMinX) && ((int)roiPoint2.x <= usRegionMaxX) &&
                                                                   ((int)roiPoint2.y >= usRegionMinY) && ((int)roiPoint2.y <= usRegionMaxY));
                                        }
                                    }
                                }
                                
								BOOL areaAvailable = YES;
								
								length = 0;
								
								for( int i = 0; i < (long)[splinePoints count]-1; i++)
									length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
								
								// The first and the last point are too far away : probably not a good idea to display the Area
								if( [self Length: [[splinePoints objectAtIndex: 0] point] :[[splinePoints lastObject] point]] > length / RATIO_FOROPOLYGONAREA)
								{
									areaAvailable = NO;
								}
								else
								{
									if (roiInside2DUSRegion || (pixelSpacingX != 0 && pixelSpacingY != 0 && ![[self pix] hasUSRegions]))
									// <--- US Regions (Opened Polygon)
									{
                                        float area = [self Area];
										if (area *pixelSpacingX*pixelSpacingY < 1.)
											self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.1f %cm\u00B2", nil), area *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5];
                                        else if (area *pixelSpacingX*pixelSpacingY/100. < 1.)
											self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f mm\u00B2", nil), area *pixelSpacingX*pixelSpacingY];
										else
											self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f cm\u00B2", nil), area *pixelSpacingX*pixelSpacingY / 100.];
									}
									else
										self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Area: %0.3f pix2", nil), [self Area]];
                                    
                                    NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", self.pix.rescaleType];
                                    
                                    if( [self pix].SUVConverted)
                                        pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                                    
									self.textualBoxLine3 = [NSString stringWithFormat: NSLocalizedString( @"Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), rmean, pixelUnit, rdev, pixelUnit, rtotal, pixelUnit];
									self.textualBoxLine4 = [NSString stringWithFormat: NSLocalizedString( @"Min: %0.3f%@ Max: %0.3f%@", nil), rmin, pixelUnit, rmax, pixelUnit];
								}
								
								if( [curView blendingView])
								{
									DCMPix *blendedPix = [[curView blendingView] curDCM];
									
									ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: blendedPix]] autorelease];
									
									NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
									
									for( MyPoint *p in pts)
										[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
									
									[blendedROI setPoints: pts];
									[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax :&Brskewness :&Brkurtosis];
									
                                    NSString *pixelUnit = [NSString stringWithFormat:@" %@ ", blendedPix.rescaleType];
                                    
                                    if( blendedPix.SUVConverted)
                                        pixelUnit = [NSString stringWithFormat:@" %@ ", NSLocalizedString( @"SUV", @"SUV = Standard Uptake Value")];
                                    
									self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Mean: %0.3f%@ SDev: %0.3f%@ Sum: %0.0f%@", nil), Brmean, pixelUnit, Brdev, pixelUnit, Brtotal, pixelUnit];
									self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"Fused Image Min: %0.3f%@ Max: %0.3f%@", nil), Brmin, pixelUnit, Brmax, pixelUnit];
								}
								
								if( length < .01)
									self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.1f %cm", nil), length * 10000.0, 0xB5];
                                else if( length < 1)
									self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f mm", nil), length * 10.0];
								else
									self.textualBoxLine5 = [NSString stringWithFormat: NSLocalizedString( @"Length: %0.3f cm", nil), length];
								
								// 3D Length
								if( curView && pixelSpacingX != 0 && pixelSpacingY != 0 && [[NSUserDefaults standardUserDefaults] boolForKey: @"splineForROI"] == NO)
								{
									NSArray *zPosArray = [self zPositions];
						
									if( [zPosArray count])
									{
										int zPos = [[zPosArray objectAtIndex:0] intValue];
										for( int i = 1; i < [zPosArray count]; i++)
										{
											if( zPos != [[zPosArray objectAtIndex:i] intValue])
											{
												if( [zPosArray count] != [points count])
													NSLog( @"***** [zPosArray count] != [points count]");
												
												double sliceInterval = [[self pix] sliceInterval];
												
												// Compute 3D distance between each points
												double distance3d = 0;
												for( i = 1; i < (long)[points count]; i++)
												{
													double x[ 3];
													double y[ 3];
													
													
													x[ 0] = [[points objectAtIndex:i] point].x * pixelSpacingX;
													x[ 1] = [[points objectAtIndex:i] point].y * pixelSpacingY;
													x[ 2] = [[zPosArray objectAtIndex:i] intValue] * sliceInterval;
													
													y[ 0] = [[points objectAtIndex:i-1] point].x * pixelSpacingX;
													y[ 1] = [[points objectAtIndex:i-1] point].y * pixelSpacingY;
													y[ 2] = [[zPosArray objectAtIndex:i-1] intValue] * sliceInterval;
													
													distance3d += sqrt((x[0]-y[0])*(x[0]-y[0]) + (x[1]-y[1])*(x[1]-y[1]) +  (x[2]-y[2])*(x[2]-y[2]));
												}
												
												if (length < .01)
													self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"3D Length: %0.1f %cm", nil), distance3d * 10000.0, 0xB5];
                                                else if (length < 1)
													self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"3D Length: %0.3f mm", nil), distance3d * 10.0];
												else
													self.textualBoxLine6 = [NSString stringWithFormat: NSLocalizedString( @"3D Length: %0.3f cm", nil), distance3d / 10.];
												break;
											}
										}
									}
								}
							}
							
							[self prepareTextualData:tPt];
						}
					}
					else if( type == tAngle)
					{
						if( [points count] == 3)
						{
							displayTextualData = YES;
                            
							if( self.isTextualDataDisplayed && prepareTextualData)
							{
								NSPoint tPt = self.lowerRightPoint;
								float   angle;
								
								if( [name isEqualToString:@"Unnamed"] == NO && [name isEqualToString: NSLocalizedString( @"Unnamed", nil)] == NO) self.textualBoxLine1 = name;
                                else self.textualBoxLine1 = nil;
                                
								angle = [self Angle:[[points objectAtIndex: 0] point] :[[points objectAtIndex: 1] point] : [[points objectAtIndex: 2] point]];
								
								self.textualBoxLine2 = [NSString stringWithFormat: NSLocalizedString( @"Angle: %0.3f%@ / %0.3f%@", nil), angle, @"\u00B0", 360 - angle, @"\u00B0"];
								
								[self prepareTextualData:tPt];
							}
						}
						else displayTextualData = NO;
					}
					
					if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
					{
						[curView window];
						
						NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: nil];
						tempPt = [curView ConvertFromNSView2GL:tempPt];
						
						glColor3f (0.5f, 0.5f, 1.0f);
						glPointSize( (1 * backingScaleFactor + sqrt( thick))*3.5 * backingScaleFactor);
						glBegin( GL_POINTS);
						for( long i = 0; i < [points count]; i++)
						{
							if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
							else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/(thick*backingScaleFactor) :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
							else glColor3f (0.5f, 0.5f, 1.0f);
							
							glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
						}
						glEnd();
					}
					
					if( PointUnderMouse != -1)
					{
						if( PointUnderMouse < [points count])
						{
							glColor3f (1.0f, 0.0f, 1.0f);
							glPointSize( (1 * backingScaleFactor + sqrt( thick))*3.5 * backingScaleFactor);
							glBegin( GL_POINTS);
							
							glVertex2f( ([[points objectAtIndex: PointUnderMouse] x]- offsetx) * scaleValue , ([[points objectAtIndex: PointUnderMouse] y]- offsety) * scaleValue);
							
							glEnd();
						}
					}
					
					glLineWidth(1.0 * backingScaleFactor);
					glColor3f (1.0f, 1.0f, 1.0f);
				}
			}
			break;
            default:;
		}
		
		glPointSize( 1.0 * backingScaleFactor);
		
		glDisable(GL_LINE_SMOOTH);
		glDisable(GL_POLYGON_SMOOTH);
		glDisable(GL_POINT_SMOOTH);
		glDisable(GL_BLEND);
	}
	@catch (NSException *e)
	{
		NSLog( @"drawROIWithScaleValue exception : %@", e);
	}
	[roiLock unlock];
}

- (float*) dataValuesAsFloatPointer :(long*) no
{
	float *data = nil;
	
	switch(type)
	{
		case tMesure:
			data = [[self pix] getLineROIValue:no :self];
		break;
		
		default:
			data = [[self pix] getROIValue:no :self :nil];
		break;
	}
	
	return data;
}

- (NSMutableArray*) dataValues
{
	NSMutableArray*		array = [NSMutableArray array];
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


-(NSPoint)pointAtIndex:(NSUInteger)index {
	return [[[self points] objectAtIndex:index] point];
}

-(void)setPoint:(NSPoint)point atIndex:(NSUInteger)index {
	[[[self points] objectAtIndex:index] setPoint:point];
}

-(void)addPoint:(NSPoint)point {
	[[self points] addObject:[MyPoint point:point]];
}



- (NSMutableDictionary*) dataString
{
	NSMutableDictionary* array = [NSMutableDictionary dictionary];
		
	switch( type)
	{
		case tOval:
		case tROI:
		case tDynAngle:
        case tTAGT:
		case tAxis:
		case tCPolygon:
		case tOPolygon:
		case tPencil:
		case tPlain: {
			array = [NSMutableDictionary dictionaryWithCapacity:0];
		
			if( rtotal == -1) [[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax :&rskewness :&rkurtosis];
			
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
			
			float length = 0;
			long i;
            NSMutableArray* ptsTemp = self.points;
            if( self.points > 0)
            {
                for( i = 0; i < (long)[ptsTemp count]-1; i++ )
				length += [self Length:[[ptsTemp objectAtIndex:i] point] :[[ptsTemp objectAtIndex:i+1] point]];
			}
            
			if( type != tOPolygon && [ptsTemp count] > 0) length += [self Length:[[ptsTemp objectAtIndex:i] point] :[[ptsTemp objectAtIndex:0] point]];
			
			[array setObject: [NSNumber numberWithFloat:length] forKey:@"Length"];
		} break;
		
		case tAngle: {
			array = [NSMutableDictionary dictionaryWithCapacity:0];
			
			float angle = [self Angle:[[points objectAtIndex: 0] point] :[[points objectAtIndex: 1] point] : [[points objectAtIndex: 2] point]];
			[array setObject: [NSNumber numberWithFloat:angle] forKey:@"Angle"];
		} break;
		
		case tMesure: {
			array = [NSMutableDictionary dictionaryWithCapacity:0];
			
			float length = [self Length: [[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]];
			[array setObject: [NSNumber numberWithFloat:length] forKey:@"Length"];
		} break;
        default:;
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

- (void) setRoiView:(DCMView*) v
{
	self.curView = v;
}

- (float) roiArea
{
	if( pixelSpacingX == 0 && pixelSpacingY == 0 ) return 0;

	switch( type)
	{
		case tDynAngle:
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
            if( textureBuffer)
            {
                for( long i = 0; i < textureWidth*textureHeight;i++)
                    if (textureBuffer[i]!=0) area++;
            }
			return (area*pixelSpacingX*pixelSpacingY)/100.;
		}
		break;
        default:;
	}
	
	return 0.0f;
}

- (NSPoint) centroid
{
	if ( type == tROI || type == tOval )
	{
		return rect.origin;
	}
	
	NSPoint centroid;
	
	centroid.x = centroid.y = 0;
	
	float num_points = [self.points count];
	
	for ( MyPoint *p in self.points)
	{
		centroid.x += [p x] / num_points;
		centroid.y += [p y] / num_points;
	}
	
	return centroid;
}

+ (unsigned char*) addMargin: (int) margin buffer: (unsigned char *) textureBuffer width: (int) width height: (int) height
{
	int newWidth = width + 2*margin;
	int newHeight = height + 2*margin;
    
	unsigned char* newBuffer, *originalBuffer;
    
    newBuffer = originalBuffer = (unsigned char*)calloc(newWidth*newHeight, sizeof(unsigned char));
	
	if( newBuffer)
	{
		for( int i=0; i<margin; i++)
		{
			// skip the 'margin' first lines
			newBuffer += newWidth;
		}
		
		unsigned char *temptextureBuffer = textureBuffer;
		
		for( int i=0; i<height; i++)
		{
			newBuffer += margin; // skip the left margin pixels
			memcpy( newBuffer,temptextureBuffer,width*sizeof(unsigned char));
			newBuffer += width+margin; // move to the next line, skipping the right margin pixels
			temptextureBuffer += width; // move to the next line
		}
	}
    
    return originalBuffer;
}

- (void) addMarginToBuffer: (int) margin
{
    unsigned char* newBuffer = [ROI addMargin: margin buffer: textureBuffer width: textureWidth height: textureHeight];
    
	textureWidth += 2*margin;
	textureHeight += 2*margin;
	
    if( textureBuffer) free( textureBuffer);
    textureBuffer = newBuffer;
    
    textureDownRightCornerX += margin;
    textureDownRightCornerY += margin;
    textureUpLeftCornerX -= margin;
    textureUpLeftCornerY -= margin;
    
    [self textureBufferHasChanged];
}

// Calcium Scoring
// Should we check to see if we using a brush ROI and other appropriate checks before return a calcium measurement?

- (int)calciumScoreCofactor
{
	/* 
	Cofactor values used by Agaston.  
	Using a threshold of 90 rather than 130. Assuming
	multislice CT rather than electron beam.
	We could have a flag for Electron beam rather than multichannel CT
	and use 130 as a cutoff
	*/	
	if( rtotal == -1) [[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	if (_calciumCofactor == 0)
		_calciumCofactor =  [[self pix] calciumCofactorForROI:self threshold:_calciumThreshold];
	//NSLog(@"cofactor: %d", _calciumCofactor);
	return _calciumCofactor;
}

- (float)calciumScore
{
	// roi Area * cofactor;  area is is mm2.
	//plainArea is number of pixels 
	// still to compensate for overlapping slices interval/sliceThickness
	
	if( rtotal == -1) [[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	//area needs to be > 1 mm
	
	float intervalRatio = 1;
	
	if( curView)
		intervalRatio = fabs([[self pix] sliceInterval] / [[self pix] sliceThickness]);
	else
		NSLog( @"curView == nil");
	
	if (intervalRatio > 1)
		intervalRatio = 1;
	
	float area = [self plainArea] * pixelSpacingX * pixelSpacingY;
	//if (area < 1)
	//	return 0;
	return area * [self calciumScoreCofactor] * intervalRatio ;   
}

- (float)calciumVolume
{
	// area * thickness
	
	if( rtotal == -1) [[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	float area = [self plainArea] * pixelSpacingX * pixelSpacingY;
	//if (area < 1)
	//	return 0;
	
	return area * [[self pix] sliceThickness];
	//return [self roiArea] * [self thickness] * 100;
}
- (float) calciumMass
{
	//Volume * mean CT Density / 250 
	if( rtotal == -1)
		[[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	
	return fabs( [self calciumVolume] * rmean)/ 250;
}

- (void) setLayerImage:(NSImage*)image;
{
	if(layerImage) [layerImage release];
	layerImage = [image retain];
	
	isLayerOpacityConstant = YES;
	canColorizeLayer = NO;
	
//    NSBitmapImageRep* rep = [[image representations] objectAtIndex:0];
//	NSSize imageSize = NSMakeSize(rep.pixelsWide, rep.pixelsHigh); // [layerImage size];
	NSSize imageSize = [layerImage size];
	float imageWidth = imageSize.width;
	float imageHeight = imageSize.height;
	
	float scaleFactorX;
	float scaleFactorY;

	if( pixelSpacingX != 0 && pixelSpacingY != 0 )
	{
		scaleFactorX = layerPixelSpacingX / pixelSpacingX;
		scaleFactorY = layerPixelSpacingY / pixelSpacingY;
	}
	else
	{
		scaleFactorX = 1.0;
		scaleFactorY = 1.0;
	}
	
	NSPoint p1, p2, p3, p4;
	p1 = NSMakePoint(0.0, 0.0);
	p2 = NSMakePoint(imageWidth*scaleFactorX, 0.0);
	p3 = NSMakePoint(imageWidth*scaleFactorX, imageHeight*scaleFactorY);
	p4 = NSMakePoint(0.0, imageHeight*scaleFactorY);

	NSArray *pts = [NSArray arrayWithObjects:[MyPoint point:p1], [MyPoint point:p2], [MyPoint point:p3], [MyPoint point:p4], nil];
	[points setArray:pts];

	[self generateEncodedLayerImage];
	
	[self loadLayerImageTexture];
}

- (GLuint) loadLayerImageTexture;
{
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData: [layerImage TIFFRepresentation]];
    size_t height = [bitmap pixelsHigh], width = [bitmap pixelsWide];
//    NSSize osize = [layerImage size];

	int bytesPerRow = [bitmap bytesPerRow];
	int spp = [bitmap samplesPerPixel];
	
	if(textureBuffer) free(textureBuffer);
	
    [self textureBufferHasChanged];
    
	if(spp == 1)
	{
		bytesPerRow = [bitmap bytesPerRow]/spp;
		bytesPerRow *= 4;

		unsigned char *ptr, *tmpImage;
		int	loop = (int) height * bytesPerRow/4;
		tmpImage = malloc (bytesPerRow * height);
		ptr   = tmpImage;
		
		unsigned char   *bufPtr;
		bufPtr = [bitmap bitmapData];
		while( loop-- > 0)
		{
			*ptr++	= *bufPtr;
			*ptr++	= *bufPtr;
			*ptr++	= *bufPtr++;
			*ptr++	= 255;
		}
		
		textureBuffer = tmpImage;
	}
	else if(spp == 3) 
	{
		bytesPerRow = [bitmap bytesPerRow]/spp;
		bytesPerRow *= 4;

		unsigned char *ptr, *tmpImage;
		int	loop = (int) height * bytesPerRow/4;
		tmpImage = malloc (bytesPerRow * height);
		ptr   = tmpImage;
		
		unsigned char   *bufPtr;
		bufPtr = [bitmap bitmapData];
		while( loop-- > 0)
		{
			*ptr++	= *bufPtr++;
			*ptr++	= *bufPtr++;
			*ptr++	= *bufPtr++;
			*ptr++	= 255;
		}
		
		textureBuffer = tmpImage;
	}
	else
	{
		textureBuffer = malloc(  bytesPerRow * height);
		memcpy( textureBuffer, [bitmap bitmapData], [bitmap bytesPerRow] * height);
	}
	
	if(!isLayerOpacityConstant)// && opacity<1.0)
	{
		unsigned char*	rgbaPtr = (unsigned char*) textureBuffer;
		long			ss = bytesPerRow/4 * height;
		
		while( ss-->0)
		{
			unsigned char r = *(rgbaPtr+0);
			unsigned char g = *(rgbaPtr+1);
			unsigned char b = *(rgbaPtr+2);
			
			*(rgbaPtr+0) = (r+g+b) / 3 * opacity;
			*(rgbaPtr+1) = r;
			*(rgbaPtr+2) = g;
			*(rgbaPtr+3) = b;
			
			rgbaPtr+= 4;
		}
	}
	else
	{
		unsigned char*	rgbaPtr = (unsigned char*) textureBuffer;
		long			ss = bytesPerRow/4 * height;
		
		while( ss-->0)
		{
			unsigned char r = *(rgbaPtr+0);
			unsigned char g = *(rgbaPtr+1);
			unsigned char b = *(rgbaPtr+2);
			unsigned char a = *(rgbaPtr+3);
			
			*(rgbaPtr+0) = a;
			*(rgbaPtr+1) = r;
			*(rgbaPtr+2) = g;
			*(rgbaPtr+3) = b;
			
			rgbaPtr+= 4;
		}
	}

	if(canColorizeLayer && layerColor)
	{
		vImage_Buffer src, dest;
		
		dest.height = height;
		dest.width = width;
		dest.rowBytes = bytesPerRow;
		dest.data = textureBuffer;
		
		src = dest;
		
		unsigned char	redTable[ 256], greenTable[ 256], blueTable[ 256], alphaTable[ 256];
			
		for( int i = 0; i < 256; i++ ) {
			redTable[i] = (float) i * [layerColor redComponent];
			greenTable[i] = (float) i * [layerColor greenComponent];
			blueTable[i] = (float) i * [layerColor blueComponent];
			alphaTable[i] = (float) i * opacity;
		}
		
		//vImageOverwriteChannels_ARGB8888(const vImage_Buffer *newSrc, &src, &dest, 0x4, 0);
		
//		#if __BIG_ENDIAN__
//		vImageTableLookUp_ARGB8888( &src, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) redTable, (Pixel_8*) greenTable, (Pixel_8*) blueTable, 0);
//		#else
//		vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) blueTable, (Pixel_8*) greenTable, (Pixel_8*) redTable, (Pixel_8*) &alphaTable, 0);
//		#endif

		vImageTableLookUp_ARGB8888( &src, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) redTable, (Pixel_8*) greenTable, (Pixel_8*) blueTable, 0);
	}
	
	NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
	CGLContextObj cgl_ctx = [currentContext CGLContextObj];
	
	[self deleteTexture: currentContext];
	
	GLuint textureName = 0;
	
	glGenTextures(1, &textureName);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, bytesPerRow/4);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
	glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);

    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"])
    {
        glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);	//GL_LINEAR_MIPMAP_LINEAR
        glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);	//GL_LINEAR_MIPMAP_LINEAR
    }
    else
    {
        glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
        glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	//GL_LINEAR_MIPMAP_LINEAR
	}
    
	#if __BIG_ENDIAN__
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, textureBuffer);
	#else
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, textureBuffer);
	#endif

	[ctxArray addObject: currentContext];
	[textArray addObject: [NSNumber numberWithInt: textureName]];
			
	[bitmap release];
	
	return textureName;
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
	layerImageJPEG = [[imageRep representationUsingType:NSPNGFileType properties:imageProps] retain];	//NSJPEGFileType //NSJPEG2000FileType
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
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:pointA];
    [path lineToPoint:pointB];
    [path lineToPoint:pointC];
    [path lineToPoint:pointD];
    [path closePath];
    return [path containsPoint:point];
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
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
}

- (void)setCanColorizeLayer:(BOOL)boo;
{
	canColorizeLayer = boo;
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
}

- (void)setCanResizeLayer:(BOOL)boo
{
	canResizeLayer = boo;
}

-(NSMutableArray*) splinePoints:(float) scale;
{
	return [self splinePoints: scale correspondingSegmentArray: nil];
}

-(NSMutableArray*) splinePoints:(float) scale correspondingSegmentArray: (NSMutableArray**) correspondingSegmentArray
{
	// activated in the prefs
	if ([self isSpline] == NO) return [self points];
	
	// available only for ROI types : Open Polygon, Close Polygon, Pencil
	// for other types, returns the original points
	if(type!=tOPolygon && type!=tCPolygon && type!=tPencil) return [self points];
	
	// available only for polygons with at least 3 points
	if([points count]<3) return [self points];
	
	
	int nb;
    ToolMode localType = type;
	
	if( mode == ROI_drawing)
		localType = tOPolygon;
	
	if( localType == tOPolygon) nb = [points count];
	else nb = [points count]+1;

	NSPoint pts[nb];
	
	for( int i=0; i<[points count]; i++)
		pts[i] = [[points objectAtIndex:i] point];
	
	if( localType != tOPolygon && [points count] > 0)
		pts[[points count]] = [[points objectAtIndex:0] point]; // we add the first point as the last one to smooth the spline
							
	NSPoint *splinePts;
	
	long newNb = 0;
	long *correspondingSegments = nil;
	
	if( correspondingSegmentArray)
		newNb = spline( pts, nb, &splinePts, &correspondingSegments, scale);
	else 
		newNb = spline( pts, nb, &splinePts, nil, scale);
	
	NSMutableArray *newPoints = [NSMutableArray array];
	for(long i=0; i<newNb; i++)
	{
		[newPoints addObject:[MyPoint point:splinePts[i]]];
	}
	
	if( correspondingSegmentArray)
	{
		*correspondingSegmentArray = [NSMutableArray array];
		
		for(long i=0; i<newNb; i++)
		{
			[*correspondingSegmentArray addObject: [NSNumber numberWithLong: correspondingSegments[ i]]];
		}
	}

	if(newNb) free(splinePts);
	
	if( [newPoints count] == 0)
		return [self points];
	
	return newPoints;
}

-(NSMutableArray*) splinePoints;
{
	return [self splinePoints: 5.0];
}

-(NSMutableArray*)splineZPositions;
{
	// activated in the prefs
	if([self isSpline] == NO) return zPositions;
	
	// available only for ROI types : Open Polygon, Close Polygon, Pencil
	// for other types, returns the original points
	if(type!=tOPolygon && type!=tCPolygon && type!=tPencil) return zPositions;
	
	// available only for polygons with at least 3 points
	if([points count]<3) return zPositions;
	
	int nb; // number of points
	if(type==tOPolygon) nb = [zPositions count];
	else nb = [zPositions count]+1;

	NSPoint pts[nb];
	
	for(long i=0; i<[zPositions count]; i++)
		pts[i] = NSMakePoint([[zPositions objectAtIndex:i] floatValue], i);
	
	if(type != tOPolygon && [zPositions count] > 0)
		pts[[zPositions count]] = NSMakePoint([[zPositions objectAtIndex:0] floatValue], 0.0); // we add the first point as the last one to smooth the spline
							
	NSPoint *splinePts;
	long newNb = spline(pts, nb, &splinePts, nil, 1);
	
	NSMutableArray *newPoints = [NSMutableArray array];
	for(long i=0; i<newNb; i++)
	{
		[newPoints addObject:[NSNumber numberWithFloat:splinePts[i].x]];
	}

	if(newNb) free(splinePts);
	
	return newPoints;
}

-(void)setNSColor:(NSColor*)nsColor {
	[self setNSColor:nsColor globally:YES];
}

-(NSColor*)NSColor {
	return [NSColor colorWithCalibratedRed:color.red/0xffff green:color.green/0xffff blue:color.blue/0xffff alpha:opacity];
}

-(void)setNSColor:(NSColor*)nsColor globally:(BOOL)g {
	[self setOpacity:[nsColor alphaComponent] globally:g];
	RGBColor rgbColor = {[nsColor redComponent]*0xffff, [nsColor greenComponent]*0xffff, [nsColor blueComponent]*0xffff};
	[self setColor:rgbColor globally:g];
}


@end
