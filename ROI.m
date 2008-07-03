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

#define CIRCLERESOLUTION 200
#define ROIVERSION		8

static		float					deg2rad = M_PI / 180.0f; 

static		NSString				*defaultName;
static		int						gUID = 0;

extern long BresLine(int Ax, int Ay, int Bx, int By,long **xBuffer, long **yBuffer);

static float ROIRegionOpacity, ROITextThickness, ROIThickness, ROIOpacity, ROIColorR, ROIColorG, ROIColorB, ROITextColorR, ROITextColorG, ROITextColorB;
static float ROIRegionThickness, ROIRegionColorR, ROIRegionColorG, ROIRegionColorB, ROIArrowThickness;
static BOOL ROITEXTIFSELECTED, ROITEXTNAMEONLY;
static BOOL ROIDefaultsLoaded = NO;
static BOOL splineForROI = NO;

int spline(NSPoint *Pt, int tot, NSPoint **newPt, double scale)
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
		tt++;
		
		for (j = 1; j <= h[i]; j++)
		{
			p2.x = (aax + bbx * (double)j + ccx * (double)(j * j) + ddx * (double)(j * j * j));
			p2.y = (aay + bby * (double)j + ccy * (double)(j * j) + ddy * (double)(j * j * j));
			(*newPt)[tt]=p2;
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
@synthesize textualBoxLine1, textualBoxLine2, textualBoxLine3, textualBoxLine4, textualBoxLine5, textualBoxLine6;
@synthesize groupID;
@synthesize isLayerOpacityConstant, canColorizeLayer, displayTextualData, clickPoint;

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
	ROITEXTNAMEONLY = [[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTNAMEONLY"];
	splineForROI = [[NSUserDefaults standardUserDefaults] boolForKey: @"splineForROI"];
	
	ROIDefaultsLoaded = YES;
}

+ (BOOL) splineForROI
{
	return splineForROI;
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
		while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	}
}

- (DCMPix*)pix {
	if ( pix )	{
		return pix;
	}
	else {
		NSLog( @"***** warning pix == [curView curDCM]");
		
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
		
		[points retain];
		[name retain];
		[comments retain];
		[zPositions retain]; 
		mode = ROI_sleep;
		
		previousPoint.x = previousPoint.y = -1000;
		
		fontListGL = -1;
		stringTex = 0L;
		rmean = rmax = rmin = rdev = rtotal = -1;
		Brmean = Brmax = Brmin = Brdev = Brtotal = -1;
		mousePosMeasure = -1;
		
		ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		textArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		
		{
			// init fonts for use with strings
			NSFont * font =[NSFont fontWithName:@"Helvetica" size: 12.0 + thickness*2];
			stanStringAttrib = [[NSMutableDictionary dictionary] retain];
			[stanStringAttrib setObject:font forKey:NSFontAttributeName];
			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		}
		
		[self reduceTextureIfPossible];
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
	
	// ROIVERSION = 8
	[coder encodeObject:[NSNumber numberWithBool:canResizeLayer]];
}

- (NSData*) data { return [NSArchiver archivedDataWithRootObject: self]; }

- (void) deleteTexture:(NSOpenGLContext*) c
{
	NSUInteger index = [ctxArray indexOfObjectIdenticalTo: c];
	
	if( c && index != NSNotFound)
	{
		GLuint t = [[textArray objectAtIndex: index] intValue];
		CGLContextObj cgl_ctx = [c CGLContextObj];
		
		if( t)
			(*cgl_ctx->disp.delete_textures)(cgl_ctx->rend, 1, &t);
		
		[ctxArray removeObjectAtIndex: index];
		[textArray removeObjectAtIndex: index];
	}
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:self userInfo: 0L];
	
	while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
	[ctxArray release];
	[textArray release];
	if( [textArray count]) NSLog( @"** ROI.m dealloc not all texture were deleted...");
	
	if (textureBuffer) free(textureBuffer);
		
	
	[uniqueID release];
	[points release];
	[zPositions release];
	[name release];
	[comments release];
	[stringTex release];
	[stanStringAttrib release];
	[roiLock release];
	roiLock = 0;
	
	[layerImageJPEG release];
//	[layerImageWhenSelectedJPEG release];

	[layerReferenceFilePath release];
	[layerImage release];
//	[layerImageWhenSelected release];
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
		PointUnderMouse = -1;
		
		ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		textArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		
		long i,j;
        type = tPlain;
		mode = ROI_sleep;
		parentROI = 0L;
		thickness = 2.0;
		opacity = 0.5;
		mousePosMeasure = -1;
		pixelSpacingX = ipixelSpacingx;
		pixelSpacingY = ipixelSpacingy;
		imageOrigin = iimageOrigin;
		points = [[NSMutableArray arrayWithCapacity:0] retain];
		zPositions = [[NSMutableArray arrayWithCapacity:0] retain];
		comments = [[NSString alloc] initWithString:@""];
		fontListGL = -1;
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
		
		textureBuffer=(unsigned char*)malloc(tWidth*tHeight*sizeof(unsigned char));
		memcpy( textureBuffer, tBuff, tHeight*tWidth);
		[self reduceTextureIfPossible];
		
		name = [[NSString alloc] initWithString:tName];
		displayTextualData = YES;
		
		thickness = ROIRegionThickness;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionThickness"];
		color.red = ROIRegionColorR;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorR"];
		color.green = ROIRegionColorG;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorG"];
		color.blue = ROIRegionColorB;	//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionColorB"];
		opacity = ROIRegionOpacity;		//[[NSUserDefaults standardUserDefaults] floatForKey: @"ROIRegionOpacity"];
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
		PointUnderMouse = -1;
		
		ctxArray = [[NSMutableArray arrayWithCapacity: 10] retain];
		textArray = [[NSMutableArray arrayWithCapacity: 10] retain];

        type = itype;
		mode = ROI_sleep;
		parentROI = 0L;
		
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
		
		points = [[NSMutableArray arrayWithCapacity:0] retain];
		zPositions = [[NSMutableArray arrayWithCapacity:0] retain];
		
		comments = [[NSString alloc] initWithString:@""];
		
		fontListGL = -1;
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
	
    glRasterPos3d( 0, 0, 0);
	glBitmap (0, 0, 0, 0, xx, -yy, NULL);
	
    GLint i = 0;
    while (cstrOut [i]) glCallList (fontListGL + cstrOut[i++] - ' ');

	xx = x;
	yy = y + line;
	
    glColor3f (1.0f, 1.0f, 1.0f);
    glRasterPos3d( 0, 0, 0);
	glBitmap (0, 0, 0, 0, xx, -yy, NULL);
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
	return [self Area: [self splinePoints]];
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
	return [self LengthFrom: mesureA to : mesureB inPixel: NO];
}

-(float) LengthFrom:(NSPoint) mesureA to:(NSPoint) mesureB inPixel: (BOOL) inPixel
{
	short yT, xT;
	float mesureLength;
	
	if( mesureA.x > mesureB.x) { yT = mesureA.y;  xT = mesureA.x;}
	else {yT = mesureB.y;   xT = mesureB.x;}
	
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
	
	if ( type == tROI || type == tOval || type == t2DPoint) return;  // Doesn't make sense to set points for these types.
	
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
						if([curView currentTool]==tPlain) imode = ROI_selectedModify; // tPlain ROIs can only be modified by the tPlain tool
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
				NSMutableArray *splinePoints = [self splinePoints: scale];
				
				for( int i = 0; i < ([splinePoints count] - 1); i++ )	{
					
					[self DistancePointLine:pt :[[splinePoints objectAtIndex:i] point] : [[splinePoints objectAtIndex:(i+1)] point] :&distance];
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
				NSMutableArray *splinePoints = [self splinePoints: scale];
				
				int i;
				for( i = 0; i < ([splinePoints count] - 1); i++ )	{
					
					[self DistancePointLine:pt :[[splinePoints objectAtIndex:i] point] : [[splinePoints objectAtIndex:(i+1)] point] :&distance];
					if( distance*scale < 5.0)
					{
						imode = ROI_selected;
						break;
					}
				}
				
				[self DistancePointLine:pt :[[splinePoints objectAtIndex:i] point] : [[splinePoints objectAtIndex:0] point] :&distance];
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
			{
				selectedModifyPoint = -1;
				for( int i = 0 ; i < [points count]; i++ )
				{
					if( [[points objectAtIndex: i] isNearToPoint: pt :scale :[[curView curDCM] pixelRatio]])
					{
						imode = ROI_selectedModify;
						selectedModifyPoint = i;
					}
				}
			}
			break;
		}
		
		clickPoint = pt;
		
		[tempPoint release];
	}
	
	return imode;
}

- (void) displayPointUnderMouse:(NSPoint) pt :(float) offsetx :(float) offsety :(float) scale
{
	MyPoint		*tempPoint = [[[MyPoint alloc] initWithPoint: pt] autorelease];
	
	int previousPointUnderMouse = PointUnderMouse;
	
	PointUnderMouse = -1;
	NSPoint aPt;
	
	switch( type)
	{
		case tOval:
			aPt.x = rect.origin.x - rect.size.width;		aPt.y = rect.origin.y - rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 1;
			
			aPt.x = rect.origin.x - rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 2;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 3;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y - rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 4;
		break;
		
		case tROI:
			aPt.x = rect.origin.x;		aPt.y = rect.origin.y;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 1;
			
			aPt.x = rect.origin.x;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 2;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y + rect.size.height;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 3;
			
			aPt.x = rect.origin.x + rect.size.width;		aPt.y = rect.origin.y;
			if( [tempPoint isNearToPoint: aPt :scale :[[curView curDCM] pixelRatio]]) PointUnderMouse = 4;
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
		{
			for( int i = 0 ; i < [points count]; i++ )
			{
				if( [[points objectAtIndex: i] isNearToPoint: pt :scale :[[curView curDCM] pixelRatio]])
				{
					PointUnderMouse = i;
				}
			}
		}
		break;
	}
	
	if( PointUnderMouse != previousPointUnderMouse)
	{
		[curView setNeedsDisplay: YES];
	}
}

- (BOOL)mouseRoiDown:(NSPoint)pt :(float)scale
{
	[self mouseRoiDown:pt :[curView curImage] :scale];
}

- (BOOL)mouseRoiDownIn:(NSPoint)pt :(int)slice :(float)scale
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
		
		if( pixelSpacingX != 0 && pixelSpacingY != 0 )
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

- (BOOL)mouseRoiDown:(NSPoint)pt :(int)slice :(float)scale
{
	[roiLock lock];
	
	BOOL result = [self mouseRoiDownIn:pt :slice :scale];
	
	[roiLock unlock];
	
	return result;
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
		return canResizeLayer;
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
}

- (BOOL) reduceTextureIfPossible
{
	if( type != tPlain) return YES;
	
	int				minX, maxX, minY, maxY;
	unsigned char	*tempBuf = textureBuffer;
	
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
		if( newTextureBuffer == 0L)
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
	}
	
	return NO;	// means the ROI is NOT empty;
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
	[roiLock lock];

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
				}
					
				free(tempTextureBuffer);
				tempTextureBuffer = 0L;
					
				oldTextureWidth = textureWidth;
				oldTextureHeight = textureHeight;	
				
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
				if( selectedModifyPoint >= 0)
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
	
	[roiLock unlock];
	
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
		if( pixelSpacingX != 0 && pixelSpacingY != 0 )
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
		while( [ctxArray count]) [self deleteTexture: [ctxArray lastObject]];
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
	int v = a ;	// To reduce the Opengl memory leak - PointSize LineWidth
	
	thickness = (float) v;
	
	if( type == tPlain)
	{
		ROIRegionThickness = thickness;	//[[NSUserDefaults standardUserDefaults] setFloat:thickness forKey:@"ROIRegionThickness"];
	}
	else if( type == tArrow)
	{
		ROIArrowThickness = thickness;
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
			if( mode == ROI_selectedModify)
			{
				if( selectedModifyPoint >= 0)
					[points removeObjectAtIndex: selectedModifyPoint];
			}
			else [points removeLastObject];
			
			if( selectedModifyPoint >= [points count]) selectedModifyPoint = [points count]-1;
		break;
		//JJCP
		case tDynAngle:
		//JJCP
		case tAxis:
			if(selectedModifyPoint>3 && selectedModifyPoint >= 0)
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
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glLineWidth( 5);
	glBegin(GL_POLYGON);
		glVertex2f(  minx, miny);
		glVertex2f(  minx, maxy);
		glVertex2f(  maxx, maxy);
		glVertex2f(  maxx, miny);
	glEnd();
	
//	glPointSize( 5);
//	glBegin( GL_POINTS);
//		glVertex2f(  minx, miny);
//		glVertex2f(  minx, maxy);
//		glVertex2f(  maxx, maxy);
//		glVertex2f(  maxx, miny);
//	glEnd();

//	 float vec[7][2]= {{0.195, 0.02}, {0.383, 0.067}, {0.55, 0.169}, {0.707, 0.293},
//					   {0.831, 0.45}, {0.924, 0.617}, {0.98, 0.805}};
//
//	 /* mult */
//	 for( int a=0; a<7; a++) {
//			 vec[a][0]*= rad; vec[a][1]*= rad;
//	 }
//
//	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
//	 glBegin(mode);
//
//	 /* start with corner right-bottom */
//	 if(roundboxtype & 4) {
//			 glVertex2f( maxx-rad, miny);
//			 for( int a=0; a<7; a++ ) {
//					 glVertex2f( maxx-rad+vec[a][0], miny+vec[a][1]);
//			 }
//			 glVertex2f( maxx, miny+rad);
//	 }
//	 else glVertex2f( maxx, miny);
//	 
//	 /* corner right-top */
//	 if(roundboxtype & 2) {
//			 glVertex2f( maxx, maxy-rad);
//			 for( int a=0; a<7; a++ ) {
//					 glVertex2f( maxx-vec[a][1], maxy-rad+vec[a][0]);
//			 }
//			 glVertex2f( maxx-rad, maxy);
//	 }
//	 else glVertex2f( maxx, maxy);
//	 
//	 /* corner left-top */
//	 if(roundboxtype & 1) {
//			 glVertex2f( minx+rad, maxy);
//			 for( int a=0; a<7; a++ ) {
//					 glVertex2f( minx+rad-vec[a][0], maxy-vec[a][1]);
//			 }
//			 glVertex2f( minx, maxy-rad);
//	 }
//	 else glVertex2f( minx, maxy);
//	 
//	 /* corner left-bottom */
//	 if(roundboxtype & 8) {
//			 glVertex2f( minx, miny+rad);
//			 for( int a=0; a<7; a++ ) {
//					 glVertex2f( minx+vec[a][1], miny+rad-vec[a][0]);
//			 }
//			 glVertex2f( minx+rad, miny);
//	 }
//	 else glVertex2f( minx, miny);
//	 
//	 glEnd();
}

- (NSRect) findAnEmptySpaceForMyRect:(NSRect) dRect :(BOOL*) moved
{
	NSMutableArray		*rectArray = [curView rectArray];
	
	if( rectArray == 0L)
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
	displayingRect.origin.x -= displayingRect.size.width/2;
	displayingRect.origin.y -= displayingRect.size.height/2;
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
			[self glStr: (unsigned char*)line6 : tPt.x : tPt.y : line];	if( line6[0]) line++;
			
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

- (void) prepareTextualData:( char*) l1 :( char*) l2 :( char*) l3 :( char*) l4 :( char*) l5 :( char*) l6 location:(NSPoint) tPt
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
	maxWidth = [self maxStringWidth:l5 max: maxWidth];	if( l6[0]) line++;
	
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

- (void) drawROI :(float) scaleValue :(float) offsetx :(float) offsety :(float) spacingX :(float) spacingY;
{
	[self drawROIWithScaleValue:scaleValue offsetX:offsetx offsetY:offsety pixelSpacingX:spacingX pixelSpacingY:spacingY highlightIfSelected:YES thickness:thickness prepareTextualData: YES];
}

- (void) drawROIWithScaleValue:(float)scaleValue offsetX:(float)offsetx offsetY:(float)offsety pixelSpacingX:(float)spacingX pixelSpacingY:(float)spacingY highlightIfSelected:(BOOL)highlightIfSelected thickness:(float)thick prepareTextualData:(BOOL) prepareTextualData;
{
	float thicknessCopy = thickness;
	thickness = thick;
	
	if( roiLock == 0L) roiLock = [[NSLock alloc] init];
	
	if( fontListGL == -1 && prepareTextualData == YES) {NSLog(@"fontListGL == -1! We will not draw this ROI..."); return;}
	if( curView == 0L && prepareTextualData == YES) {NSLog(@"curView == 0L! We will not draw this ROI..."); return;}
	
	[roiLock lock];
	
	pixelSpacingX = spacingX;
	pixelSpacingY = spacingY;
	
	float screenXUpL,screenYUpL,screenXDr,screenYDr; // for tPlain ROI
	
	NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
	CGLContextObj cgl_ctx = [currentContext CGLContextObj];
	
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
					GLuint texName = 0L;
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
					glPointSize( 8.0);
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
					line1[0] = 0; line2[0] = 0; line3[0] = 0; line4[0] = 0; line5[0] = 0; line6[0] = 0;
					NSPoint tPt = self.lowerRightPoint;
				
					if(![name isEqualToString:@"Unnamed"]) strcpy(line1, [name UTF8String]);
					if(textualBoxLine1 && ![textualBoxLine1 isEqualToString:@""]) strcpy(line1, [textualBoxLine1 UTF8String]);
					if(textualBoxLine2 && ![textualBoxLine2 isEqualToString:@""]) strcpy(line2, [textualBoxLine2 UTF8String]);
					if(textualBoxLine3 && ![textualBoxLine3 isEqualToString:@""]) strcpy(line3, [textualBoxLine3 UTF8String]);
					if(textualBoxLine4 && ![textualBoxLine4 isEqualToString:@""]) strcpy(line4, [textualBoxLine4 UTF8String]);
					if(textualBoxLine5 && ![textualBoxLine5 isEqualToString:@""]) strcpy(line5, [textualBoxLine5 UTF8String]);
					if(textualBoxLine6 && ![textualBoxLine6 isEqualToString:@""]) strcpy(line6, [textualBoxLine5 UTF8String]);
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
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
			
			[self deleteTexture: currentContext];
			
			GLuint textureName = 0L;
			
			glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, textureWidth * textureHeight, textureBuffer);
			glGenTextures (1, &textureName);
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
			glPixelStorei (GL_UNPACK_ROW_LENGTH, textureWidth);
			glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
			
			[ctxArray addObject: currentContext];
			[textArray addObject: [NSNumber numberWithInt: textureName]];
			
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
					if(highlightIfSelected)
					{
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
					}
				break;
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
			if( self.isTextualDataDisplayed && prepareTextualData) {
				NSPoint tPt = [self lowerRightPoint];
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if ( ROITEXTNAMEONLY == NO ) {
					if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
					
					float area = [self plainArea];

					if (!_displayCalciumScoring) {
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if( area*pixelSpacingX*pixelSpacingY < 1. )
								sprintf (line2, "Area: %0.1f %cm2", area*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5);
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
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
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
			  
			  if( pixelSpacingX != 0 && pixelSpacingY != 0 )
				glVertex2f( (rect.origin.x - offsetx)*scaleValue + 8*cos(angle), (rect.origin.y - offsety)*scaleValue + 8*sin(angle)*pixelSpacingX/pixelSpacingY);
			  else
				glVertex2f( (rect.origin.x - offsetx)*scaleValue + 8*cos(angle), (rect.origin.y - offsety)*scaleValue + 8*sin(angle));
			}
			glEnd();
			
			if((mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing) && highlightIfSelected) glColor4f (0.5f, 0.5f, 1.0f, opacity);
			else glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			//else glColor4f (1.0f, 0.0f, 0.0f, opacity);
			
			glPointSize( (1 + sqrt( thickness))*3.5);
			glBegin( GL_POINTS);
			glVertex2f(  (rect.origin.x  - offsetx)*scaleValue, (rect.origin.y  - offsety)*scaleValue);
			glEnd();
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
			if( self.isTextualDataDisplayed && prepareTextualData)
			{
				NSPoint tPt = self.lowerRightPoint;
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if( ROITEXTNAMEONLY == NO )
				{
					if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
					
					if( [curView blendingView])
					{
						DCMPix	*blendedPix = [[curView blendingView] curDCM];
						
						ROI *blendedROI = [[[ROI alloc] initWithType: type :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :NSMakePoint( [blendedPix originX], [blendedPix originY])] autorelease];
						
						NSRect blendedRect = [self rect];
						blendedRect.origin = [curView ConvertFromGL2GL: blendedRect.origin toView:[curView blendingView]];
						[blendedROI setROIRect: blendedRect];
						
						[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
					}
					
					sprintf (line2, "Val: %0.3f", rmean);
					if( Brtotal != -1) sprintf (line3, "Fused Image Val: %0.3f", Brmean);
					
					sprintf (line4, "2D Pos: X:%0.3f px Y:%0.3f px", rect.origin.x, rect.origin.y);
					
					float location[ 3 ];
					[[curView curDCM] convertPixX: rect.origin.x pixY: rect.origin.y toDICOMCoords: location pixelCenter: YES];
					if(fabs(location[0]) < 1.0 && location[0] != 0.0)
						sprintf (line5, "3D Pos: X:%0.1f %cm Y:%0.1f %cm Z:%0.1f %cm", location[0] * 1000.0, 0xB5, location[1] * 1000.0, 0xB5, location[2] * 1000.0, 0xB5);
					else
						sprintf (line5, "3D Pos: X:%0.3f mm Y:%0.3f mm Z:%0.3f mm", location[0], location[1], location[2]);
				}
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
			}
		}
		break;
		
		case tText:
		{
			if((mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing) && highlightIfSelected)
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
			if( pixelSpacingX != 0 && pixelSpacingY != 0 )
				[stringTex drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+ (1.0*pixelSpacingX / pixelSpacingY)) ratio: pixelSpacingX / pixelSpacingY];
			else
				[stringTex drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+ 1.0) ratio: 1.0];
				
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			if( pixelSpacingX != 0 && pixelSpacingY != 0 )
				[stringTex drawAtPoint:tPt ratio: pixelSpacingX / pixelSpacingY];
			else
				[stringTex drawAtPoint:tPt ratio: 1.0];
				
			glDisable (GL_TEXTURE_RECTANGLE_EXT);
			
			glColor3f (1.0f, 1.0f, 1.0f);
		}
		break;
		
		case tMesure:
		case tArrow:
		{
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
				else
				{
					if( pixelSpacingX != 0 && pixelSpacingY != 0 )
						slide = (b.x-a.x)/((b.y-a.y) * (pixelSpacingY / pixelSpacingX));
					else
						slide = (b.x-a.x)/((b.y-a.y));
				}
				#define ARROWSIZE 25.0
				
				// LINE
				glLineWidth(thickness*2);
				
				angle = 90 - atan( slide)/deg2rad;
				adj = (ARROWSIZE + thickness * 13)  * cos( angle*deg2rad);
				op = (ARROWSIZE + thickness * 13) * sin( angle*deg2rad);
				
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
				
				glPointSize( thickness*2);
					
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
					
					angle = 80 - angle - thickness;
					adj = (ARROWSIZE + thickness * 15)  * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0 )
						aa1 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
					else
						aa1 = NSMakePoint( a.x + adj, a.y + (op));
						
					angle = atan( slide)/deg2rad;
					angle = 100 - angle + thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0 )
						aa2 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
					else
						aa2 = NSMakePoint( a.x + adj, a.y + (op));
				}
				else
				{
					angle = atan( slide)/deg2rad;
					
					angle = 180 + 80 - angle - thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0 )
						aa1 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
					else
						aa1 = NSMakePoint( a.x + adj, a.y + (op));
						
					angle = atan( slide)/deg2rad;
					angle = 180 + 100 - angle + thickness;
					adj = (ARROWSIZE + thickness * 15) * cos( angle*deg2rad);
					op = (ARROWSIZE + thickness * 15) * sin( angle*deg2rad);
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0 )
						aa2 = NSMakePoint( a.x + adj, a.y + (op*pixelSpacingX / pixelSpacingY));
					else
						aa2 = NSMakePoint( a.x + adj, a.y + (op));
				}
				aa3 = NSMakePoint( a.x , a.y );
				
				glLineWidth( 1.0);
				glBegin(GL_TRIANGLES);
				
				glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				glVertex2f( aa1.x, aa1.y);
				glVertex2f( aa2.x, aa2.y);
				glVertex2f( aa3.x, aa3.y);
				
				glEnd();
				
				glBegin(GL_LINE_LOOP);
				glBlendFunc(GL_ONE_MINUS_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				glColor4f(color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
				
				glVertex2f( aa1.x, aa1.y);
				glVertex2f( aa2.x, aa2.y);
				glVertex2f( aa3.x, aa3.y);
				
				glEnd();
			}
			else
			{
				glBegin(GL_LINE_STRIP);
				for( id pt in points)
				{
					glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
				}
				glEnd();
				
				glPointSize( thickness);
			
				glBegin( GL_POINTS);
				for( id pt in points)
				{
					glVertex2f( ([pt x]- offsetx) * scaleValue , ([pt y]- offsety) * scaleValue );
				}
				glEnd();
			}
			
			if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				
				if( tArrow)
					glPointSize( sqrt( thickness)*3.);
				else
					glPointSize( thickness*2);
				
				glBegin( GL_POINTS);
				for( long i = 0; i < [points count]; i++)
				{
					if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
					
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue );
					
					if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (0.5f, 0.5f, 1.0f);
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
				glPointSize( (1 + sqrt( thickness))*3.5);
				glBegin( GL_POINTS);
					glVertex2f( (pt.x - offsetx) * scaleValue , (pt.y - offsety) * scaleValue );
				glEnd();
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
			if( self.isTextualDataDisplayed && prepareTextualData)
			{
				NSPoint tPt = self.lowerRightPoint;
				long	line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				if( type == tMesure && ROITEXTNAMEONLY == NO)
				{
					if( pixelSpacingX != 0 && pixelSpacingY != 0)
					{
						float lPix, lMm = [self MesureLength: &lPix];
						
						if ( lMm < .1)
							sprintf (line2, "Length: %0.1f %cm (%0.3f pix)", lMm * 10000.0, 0xb5, lPix);
						else
							sprintf (line2, "Length: %0.3f cm (%0.3f pix)", lMm, lPix);
					}
					else
						sprintf (line2, "Length: %0.3f pix", [self Length:[[points objectAtIndex:0] point] :[[points objectAtIndex:1] point]]);
				}
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
			}
		}
		break;
		
		case tROI:
		{
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			glLineWidth(thickness);
			glBegin(GL_LINE_LOOP);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
			glEnd();
			
			glPointSize( thickness);
			glBegin( GL_POINTS);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
				glVertex2f(  (rect.origin.x - offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width- offsetx)*scaleValue, (rect.origin.y + rect.size.height- offsety)*scaleValue);
				glVertex2f(  (rect.origin.x+ rect.size.width - offsetx)*scaleValue, (rect.origin.y - offsety)*scaleValue);
			glEnd();
			
			if((mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing) && highlightIfSelected)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( (1 + sqrt( thickness))*3.5);
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
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( self.isTextualDataDisplayed && prepareTextualData) {
					NSPoint			tPt = self.lowerRightPoint;
					long			line = 0;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					else line1[ 0] = 0;
					
					if( ROITEXTNAMEONLY == NO )
					{
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if ( fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY) < 1.)
								sprintf (line2, "Area: %0.1f %cm2", fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY * 1000000.0), 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2 (W:%0.1fmm H:%0.1fmm)", fabs( NSWidth(rect)*pixelSpacingX*NSHeight(rect)*pixelSpacingY/100.), fabs(NSWidth(rect)*pixelSpacingX), fabs(NSHeight(rect)*pixelSpacingY));
						}
						else
							sprintf (line2, "Area: %0.3f pix2", fabs( NSWidth(rect)*NSHeight(rect)));
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [[[ROI alloc] initWithType: type :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :NSMakePoint( [blendedPix originX], [blendedPix originY])] autorelease];
							
							NSRect blendedRect = [self rect];
							NSPoint downRight = NSMakePoint( blendedRect.origin.x + blendedRect.size.width, blendedRect.origin.y + blendedRect.size.height);
							
							blendedRect.origin = [curView ConvertFromGL2GL: blendedRect.origin toView:[curView blendingView]];
							
							downRight = [curView ConvertFromGL2GL: downRight toView:[curView blendingView]];
							
							blendedRect.size.width = downRight.x - blendedRect.origin.x;
							blendedRect.size.height = downRight.y - blendedRect.origin.y;
							
							[blendedROI setROIRect: blendedRect];
							
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
							
							sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Total: %0.0f", Brmean, Brdev, Brtotal);
							sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
						}
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
			}
		}
		break;
		
		case tOval:
		{
			float angle;
			
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			glLineWidth(thickness);
			
			NSRect rrect = rect;
			
			if( rrect.size.height < 0)
			{
				rrect.size.height = -rrect.size.height;
			}
			
			if( rrect.size.width < 0)
			{
				rrect.size.width = -rrect.size.width;
			}
			
			int resol = (rrect.size.height + rrect.size.width) * 1.5 * scaleValue;
			
			glBegin(GL_LINE_LOOP);
			for( long i = 0; i < resol ; i++ ) {

				angle = i * 2 * M_PI /resol;
			  
			  glVertex2f( (rrect.origin.x + rrect.size.width*cos(angle) - offsetx)*scaleValue, (rrect.origin.y + rrect.size.height*sin(angle)- offsety)*scaleValue);
			}
			glEnd();
			
			glPointSize( thickness);
			glBegin( GL_POINTS);
			for( long i = 0; i < resol ; i++ ) {

				angle = i * 2 * M_PI /resol;
			  
			  glVertex2f( (rrect.origin.x + rrect.size.width*cos(angle) - offsetx)*scaleValue, (rrect.origin.y + rrect.size.height*sin(angle)- offsety)*scaleValue);
			}
			glEnd();
			
			if((mode == ROI_selected | mode == ROI_selectedModify | mode == ROI_drawing) && highlightIfSelected)
			{
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( (1 + sqrt( thickness))*3.5);
				glBegin( GL_POINTS);
				glVertex2f( (rrect.origin.x - offsetx - rrect.size.width) * scaleValue, (rrect.origin.y - rrect.size.height - offsety) * scaleValue);
				glVertex2f( (rrect.origin.x - offsetx - rrect.size.width) * scaleValue, (rrect.origin.y + rrect.size.height - offsety) * scaleValue);
				glVertex2f( (rrect.origin.x + rrect.size.width - offsetx) * scaleValue, (rrect.origin.y + rrect.size.height - offsety) * scaleValue);
				glVertex2f( (rrect.origin.x + rrect.size.width - offsetx) * scaleValue, (rrect.origin.y - rrect.size.height - offsety) * scaleValue);
				glEnd();
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
			
			// TEXT
			
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0;	line6[ 0] = 0;
			if( self.isTextualDataDisplayed && prepareTextualData) {
				NSPoint			tPt = self.lowerRightPoint;
				long			line = 0;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if( ROITEXTNAMEONLY == NO ) {
					if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0)
					{
						if( [self EllipseArea]*pixelSpacingX*pixelSpacingY < 1.)
							sprintf (line2, "Area: %0.1f %cm2", [self EllipseArea]*pixelSpacingX*pixelSpacingY* 1000000.0, 0xB5);
						else
							sprintf (line2, "Area: %0.3f cm2", [self EllipseArea]*pixelSpacingX*pixelSpacingY/100.);
					}
					else
						sprintf (line2, "Area: %0.3f pix2", [self EllipseArea]);
					
					sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
					sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
					
					if( [curView blendingView])
					{
						DCMPix	*blendedPix = [[curView blendingView] curDCM];
						
						ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :NSMakePoint( [blendedPix originX], [blendedPix originY])] autorelease];
						
						NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
						
						for( MyPoint *p in pts)
							[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
						
						[blendedROI setPoints: pts];
						[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
						
						sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Total: %0.0f", Brmean, Brdev, Brtotal);
						sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
					}
				}
				
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
			}
		}
		break;
		//JJCP
		case tAxis:
		{
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
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
			if( self.isTextualDataDisplayed && prepareTextualData) {
				NSPoint tPt = self.lowerRightPoint;
				long	line = 0;
				float   length;
				
				if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
				
				if( ROITEXTNAMEONLY == NO ) {
					if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
					
					if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
						if([self Area] *pixelSpacingX*pixelSpacingY < 1.)
							sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
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
				
				[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
			}
				if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
				{
					NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: 0L];
					tempPt = [curView ConvertFromNSView2GL:tempPt];
					
					glColor3f (0.5f, 0.5f, 1.0f);
					glPointSize( (1 + sqrt( thickness))*3.5);
					glBegin( GL_POINTS);
					for( long i = 0; i < [points count]; i++) {
						if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
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
		}
		break;
			//JJCP
		case tDynAngle:
		{
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
				
				if( pixelSpacingX != 0 && pixelSpacingY != 0)
				{
					a1 = NSMakePoint(a1.x * pixelSpacingX, a1.y * pixelSpacingY);
					a2 = NSMakePoint(a2.x * pixelSpacingX, a2.y * pixelSpacingY);
					b1 = NSMakePoint(b1.x * pixelSpacingX, b1.y * pixelSpacingY);
					b2 = NSMakePoint(b2.x * pixelSpacingX, b2.y * pixelSpacingY);
				}
				
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
			line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
			if( self.isTextualDataDisplayed && prepareTextualData) {
					NSPoint tPt = self.lowerRightPoint;
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO ) {
						
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if ([self Area] *pixelSpacingX*pixelSpacingY < 1.)
								sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
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
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
			}
			//ROI MODE
			if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
			{
				NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: 0L];
				tempPt = [curView ConvertFromNSView2GL:tempPt];
				
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( (1 + sqrt( thickness))*3.5);
				glBegin( GL_POINTS);
				for( long i = 0; i < [points count]; i++) {
					if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
					else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/thickness :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
					else glColor3f (0.5f, 0.5f, 1.0f);
					
					glVertex2f( ([[points objectAtIndex: i] x]- offsetx) * scaleValue , ([[points objectAtIndex: i] y]- offsety) * scaleValue);
				}
				glEnd();
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
		}
		break;
			
		case tCPolygon:
		case tOPolygon:
		case tAngle:
		case tPencil:
		{
			glColor4f (color.red / 65535., color.green / 65535., color.blue / 65535., opacity);
			
			if( mode == ROI_drawing) glLineWidth(thickness * 2);
			else glLineWidth(thickness);
			

			if( type == tCPolygon || type == tPencil)	glBegin(GL_LINE_LOOP);
			else										glBegin(GL_LINE_STRIP);
			
			NSMutableArray *splinePoints = [self splinePoints: scaleValue];
						
			for(long i=0; i<[splinePoints count]; i++)
			{
				glVertex2d( ((double) [[splinePoints objectAtIndex:i] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints objectAtIndex:i] y]-(double) offsety)*(double) scaleValue);
			}
			glEnd();
			
			if( mode == ROI_drawing) glPointSize( thickness * 2);
			else glPointSize( thickness);
			
			glBegin( GL_POINTS);
			for(long i=0; i<[splinePoints count]; i++)
			{
				glVertex2d( ((double) [[splinePoints objectAtIndex:i] x]- (double) offsetx)*(double) scaleValue , ((double) [[splinePoints objectAtIndex:i] y]-(double) offsety)*(double) scaleValue);
			}
			glEnd();
			
			// TEXT
			if( type == tCPolygon || type == tPencil)
			{
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( self.isTextualDataDisplayed && prepareTextualData) {
					NSPoint tPt = self.lowerRightPoint;
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO ) {
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if([self Area] *pixelSpacingX*pixelSpacingY < 1.)
								sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
						}
						else
							sprintf (line2, "Area: %0.3f pix2", [self Area]);
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :NSMakePoint( [blendedPix originX], [blendedPix originY])] autorelease];
							
							NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
							
							for( MyPoint *p in pts)
								[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
							
							[blendedROI setPoints: pts];
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
							
							sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Total: %0.0f", Brmean, Brdev, Brtotal);
							sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
						}
						else
						{
							length = 0;
							long i;
							
							for( i = 0; i < [splinePoints count]-1; i++ ) {
								length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
							}
							length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:0] point]];
							
							if (length < .1)
								sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
							else
								sprintf (line5, "Length: %0.3f cm", length);
						}
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
			}
			else if( type == tOPolygon)
			{
				line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
				if( self.isTextualDataDisplayed && prepareTextualData) {
					NSPoint tPt = self.lowerRightPoint;
					long	line = 0;
					float   length;
					
					if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
					
					if( ROITEXTNAMEONLY == NO ) {
						
						if( rtotal == -1) [[curView curDCM] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
						
						if( pixelSpacingX != 0 && pixelSpacingY != 0 ) {
							if ([self Area] *pixelSpacingX*pixelSpacingY < 1.)
								sprintf (line2, "Area: %0.1f %cm2", [self Area] *pixelSpacingX*pixelSpacingY * 1000000.0, 0xB5);
							else
								sprintf (line2, "Area: %0.3f cm2", [self Area] *pixelSpacingX*pixelSpacingY / 100.);
						}
						else
							sprintf (line2, "Area: %0.3f pix2", [self Area]);
						
						sprintf (line3, "Mean: %0.3f SDev: %0.3f Total: %0.0f", rmean, rdev, rtotal);
						sprintf (line4, "Min: %0.3f Max: %0.3f", rmin, rmax);
						
						if( [curView blendingView])
						{
							DCMPix	*blendedPix = [[curView blendingView] curDCM];
							
							ROI *blendedROI = [[[ROI alloc] initWithType: tCPolygon :[blendedPix pixelSpacingX] :[blendedPix pixelSpacingY] :NSMakePoint( [blendedPix originX], [blendedPix originY])] autorelease];
							
							NSMutableArray *pts = [[[NSMutableArray alloc] initWithArray: [self points] copyItems:YES] autorelease];
							
							for( MyPoint *p in pts)
								[p setPoint: [curView ConvertFromGL2GL: [p point] toView:[curView blendingView]]];
							
							[blendedROI setPoints: pts];
							[blendedPix computeROI: blendedROI :&Brmean :&Brtotal :&Brdev :&Brmin :&Brmax];
							
							sprintf (line5, "Fused Image Mean: %0.3f SDev: %0.3f Total: %0.0f", Brmean, Brdev, Brtotal);
							sprintf (line6, "Fused Image Min: %0.3f Max: %0.3f", Brmin, Brmax);
						}
						else
						{
							length = 0;
							for( long i = 0; i < [splinePoints count]-1; i++ ) {
								length += [self Length:[[splinePoints objectAtIndex:i] point] :[[splinePoints objectAtIndex:i+1] point]];
							}
							
							if (length < .1)
								sprintf (line5, "L: %0.1f %cm", length * 10000.0, 0xB5);
							else
								sprintf (line5, "Length: %0.3f cm", length);
						}
					}
					
					[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
				}
			}
			else if( type == tAngle)
			{
				if( [points count] == 3)
				{
					displayTextualData = YES;
					line1[ 0] = 0;		line2[ 0] = 0;	line3[ 0] = 0;		line4[ 0] = 0;	line5[ 0] = 0; line6[0] = 0;
					if( self.isTextualDataDisplayed && prepareTextualData) {
						NSPoint tPt = self.lowerRightPoint;
						long	line = 0;
						float   angle;
						
						if( [name isEqualToString:@"Unnamed"] == NO) strcpy(line1, [name UTF8String]);
						
						angle = [self Angle:[[points objectAtIndex: 0] point] :[[points objectAtIndex: 1] point] : [[points objectAtIndex: 2] point]];
						
						sprintf (line2, "Angle: %0.3f / %0.3f", angle, 360 - angle);
						
						[self prepareTextualData:line1 :line2 :line3 :line4 :line5 :line6 location:tPt];
					}
				}
				else displayTextualData = NO;
			}
			
			if((mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing) && highlightIfSelected)
			{
				[curView window];
				
				NSPoint tempPt = [curView convertPoint: [[curView window] mouseLocationOutsideOfEventStream] fromView: 0L];
				tempPt = [curView ConvertFromNSView2GL:tempPt];
				
				glColor3f (0.5f, 0.5f, 1.0f);
				glPointSize( (1 + sqrt( thickness))*3.5);
				glBegin( GL_POINTS);
				for( long i = 0; i < [points count]; i++)
				{
					if( mode >= ROI_selected && (i == selectedModifyPoint || i == PointUnderMouse)) glColor3f (1.0f, 0.2f, 0.2f);
					else if( mode == ROI_drawing && [[points objectAtIndex: i] isNearToPoint: tempPt : scaleValue/thickness :[[curView curDCM] pixelRatio]] == YES) glColor3f (1.0f, 0.0f, 1.0f);
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
					glPointSize( (1 + sqrt( thickness))*3.5);
					glBegin( GL_POINTS);
					
					glVertex2f( ([[points objectAtIndex: PointUnderMouse] x]- offsetx) * scaleValue , ([[points objectAtIndex: PointUnderMouse] y]- offsety) * scaleValue);
					
					glEnd();
				}
			}
			
			glLineWidth(1.0);
			glColor3f (1.0f, 1.0f, 1.0f);
		}
		break;
		
	}
	
	glPointSize( 1.0);
	
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);
	
	[roiLock unlock];
	
	thickness = thicknessCopy;
}

- (float*) dataValuesAsFloatPointer :(long*) no
{
	long				i;
	float				*data = 0L;
	
	switch(type)
	{
		case tMesure:
			data = [[self pix] getLineROIValue:no :self];
		break;
		
		default:
			data = [[self pix] getROIValue:no :self :0L];
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
		
			if( rtotal == -1) [[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
			
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
	
	centroid.x = 0;
	centroid.y = 0;
	
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
	if( rtotal == -1) [[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	if (_calciumCofactor == 0)
		_calciumCofactor =  [[self pix] calciumCofactorForROI:self threshold:_calciumThreshold];
	//NSLog(@"cofactor: %d", _calciumCofactor);
	return _calciumCofactor;
}

- (float)calciumScore{
	// roi Area * cofactor;  area is is mm2.
	//plainArea is number of pixels 
	// still to compensate for overlapping slices interval/sliceThickness
	
	if( rtotal == -1) [[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	//area needs to be > 1 mm
	
	float intervalRatio = 1;
	
	if( curView)
		intervalRatio = fabs([[self pix] sliceInterval] / [[self pix] sliceThickness]);
	else
		NSLog( @"curView == 0L");
	
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
- (float)calciumMass
{
	//Volume * mean CT Density / 250 
	if( rtotal == -1)
		[[self pix] computeROI:self :&rmean :&rtotal :&rdev :&rmin :&rmax];
	
	return fabs( [self calciumVolume] * rmean)/ 250;
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


- (GLuint )loadLayerImageTexture;
{
	NSBitmapImageRep *bitmap;
	bitmap = [[NSBitmapImageRep alloc] initWithData: [layerImage TIFFRepresentation]];

	int bytesPerRow = [bitmap bytesPerRow];
	int spp = [bitmap samplesPerPixel];
	
	if(textureBuffer) free(textureBuffer);
	
	if(spp == 1)
	{
		bytesPerRow = [bitmap bytesPerRow]/spp;
		bytesPerRow *= 4;

		unsigned char *ptr, *tmpImage;
		int	loop = (int) [layerImage size].height * bytesPerRow/4;
		tmpImage = malloc (bytesPerRow * [layerImage size].height);
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
		int	loop = (int) [layerImage size].height * bytesPerRow/4;
		tmpImage = malloc (bytesPerRow * [layerImage size].height);
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
		textureBuffer = malloc(  bytesPerRow * [layerImage size].height);
		memcpy( textureBuffer, [bitmap bitmapData], [bitmap bytesPerRow] * [layerImage size].height);
	}
	
	if(!isLayerOpacityConstant)// && opacity<1.0)
	{
		unsigned char*	rgbaPtr = (unsigned char*) textureBuffer;
		long			ss = bytesPerRow/4 * [layerImage size].height;
		
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
		long			ss = bytesPerRow/4 * [layerImage size].height;
		
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
		
		dest.height = [layerImage size].height;
		dest.width = [layerImage size].width;
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
	
	GLuint textureName = 0L;
	
	glGenTextures(1, &textureName);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureName);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, bytesPerRow/4);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);

	#if __BIG_ENDIAN__
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, [layerImage size].width, [layerImage size].height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, textureBuffer);
	#else
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, [layerImage size].width, [layerImage size].height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, textureBuffer);
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

-(NSMutableArray*)splinePoints:(float) scale;
{
	// activated in the prefs
	if( splineForROI == NO) return [self points];
	
	// available only for ROI types : Open Polygon, Close Polygon, Pencil
	// for other types, returns the original points
	if(type!=tOPolygon && type!=tCPolygon && type!=tPencil) return [self points];
	
	// available only for polygons with at least 3 points
	if([points count]<3) return [self points];
	
	int nb; // number of points
	if(type==tOPolygon) nb = [points count];
	else nb = [points count]+1;

	NSPoint pts[nb];
	
	for(long i=0; i<[points count]; i++)
		pts[i] = [[points objectAtIndex:i] point];
	
	if(type!=tOPolygon)
		pts[[points count]] = [[points objectAtIndex:0] point]; // we add the first point as the last one to smooth the spline
							
	NSPoint *splinePts;
	long newNb = spline(pts, nb, &splinePts, scale);
	
	NSMutableArray *newPoints = [NSMutableArray array];
	for(long i=0; i<newNb; i++)
	{
		[newPoints addObject:[MyPoint point:splinePts[i]]];
	}

	if(newNb) free(splinePts);
	
	return newPoints;
}

-(NSMutableArray*) splinePoints;
{
	return [self splinePoints: 2.0];
}

-(NSMutableArray*)splineZPositions;
{
	// activated in the prefs
	if( splineForROI == NO) return zPositions;
	
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
	
	if(type!=tOPolygon)
		pts[[zPositions count]] = NSMakePoint([[zPositions objectAtIndex:0] floatValue], 0.0); // we add the first point as the last one to smooth the spline
							
	NSPoint *splinePts;
	long newNb = spline(pts, nb, &splinePts, 1);
	
	NSMutableArray *newPoints = [NSMutableArray array];
	for(long i=0; i<newNb; i++)
	{
		[newPoints addObject:[NSNumber numberWithFloat:splinePts[i].x]];
	}

	if(newNb) free(splinePts);
	
	return newPoints;
}

@end
