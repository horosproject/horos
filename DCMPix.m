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


#import <DCMPix.h>
#import "DicomImage.h"
#import "xNSImage.h"
#import "Papyrus3/Papyrus3.h"
#import <QuickTime/QuickTime.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import "BrowserController.h"

#import "ROI.h"

#import <DCMView.h>

#import "ThickSlabController.h"
#import "dicomFile.h"
#import "PluginFileFormatDecoder.h"
#include "tiffio.h"
#include "FVTiff.h"
#include "Analyze.h"
#include <Accelerate/Accelerate.h>
#import <QTKit/QTKit.h>

#define PREVIEWSIZE 70.0

struct NSPointInt
{
	long x;
	long y;
};
typedef struct NSPointInt NSPointInt;

NSString * convertDICOM( NSString *inputfile);
NSString* filenameWithDate( NSString *inputfile);
extern NSString* documentsDirectory();

extern NSLock	*PapyrusLock;
extern short		Altivec;
extern NSMutableDictionary *fileFormatPlugins;

#if __ppc__ || __ppc64__
extern void vsubtract(vector float *a, vector float *b, vector float *r, long size);
extern void vmultiply(vector float *a, vector float *b, vector float *r, long size);
extern void vmin(vector float *a, vector float *b, vector float *r, long size);
extern void vmax(vector float *a, vector float *b, vector float *r, long size);
void vmax8(vector unsigned char *a, vector unsigned char *b, vector unsigned char *r, long size);
void vmin8(vector unsigned char *a, vector unsigned char *b, vector unsigned char *r, long size);
#else
extern void vmaxIntel( vFloat *a, vFloat *b, vFloat *r, long size);
extern void vminIntel( vFloat *a, vFloat *b, vFloat *r, long size);
#endif
extern void vminNoAltivec( float *a,  float *b,  float *r, long size);
extern void vmaxNoAltivec(float *a, float *b, float *r, long size);
extern void vsubtractNoAltivec( float *a,  float *b,  float *r, long size);
extern void vmultiplyNoAltivec( float *a,  float *b,  float *r, long size);

void ConvertFloatToNative (float *theFloat)
{
	unsigned int		*myLongPtr;
	
	myLongPtr = (unsigned int *)theFloat;
	*myLongPtr = EndianU32_LtoN(*myLongPtr);
}

void ConvertDoubleToNative (double *theFloat)
{
	unsigned long long		*myLongPtr;
	
	myLongPtr = (unsigned long long*)theFloat;
	*myLongPtr = EndianU64_LtoN(*myLongPtr);
}


uint64_t	MyGetTime( void )
{
	AbsoluteTime theTime = UpTime();

	return ((uint64_t*) &theTime )[0];
}

double MySubtractTime( uint64_t endTime, uint64_t startTime )
{
	union
	{
		Nanoseconds	ns;
		u_int64_t	i;
	}time;

	time.ns = AbsoluteToNanoseconds( SubAbsoluteFromAbsolute( ((AbsoluteTime*) &endTime)[0], ((AbsoluteTime*) &startTime)[0] ) );
	return time.i * 1e-9;
}

unsigned char* CreateIconFrom16 (float* image,  unsigned char*icon,  int height, int width, int rowBytes, long wl, long ww, BOOL isRGB)
// create an icon from an 12 or 16 bit image
{
	unsigned char		*iconPtr;
	float				ratio;
	long				i, j;
	long				line, destWidth, destHeight;
	long				value;
	long				min, max, diff;

	min = wl - ww / 2; //if (min < 0 ) min = 0;
	max = wl + ww / 2;
	diff = max - min;
	
	if( (float) width / PREVIEWSIZE > (float) height / PREVIEWSIZE) ratio = (float) width / PREVIEWSIZE;
	else ratio = (float) height / PREVIEWSIZE;
	
	destWidth = (float) width / ratio;
	destHeight = (float) height / ratio;
	
	// allocate the memory for the icon 
	iconPtr = icon;
	
	if( diff)
	{
		if( isRGB)
		{
			long	x;
			unsigned char   *rgbImage = (unsigned char*) image;
			
			for (i = 0; i < destHeight; i++)  // lines
			{
				line = width * (long) (ratio * i)*4 ;   //ARGB
				iconPtr = icon + rowBytes*i;
				for (j = 0; j < destWidth; j++)         // columns 
				{
					for (x =1; x< 4;x++, iconPtr++)		// Dont take alpha channel
					{
						value = *( rgbImage + line + x + (long) (j * ratio)*4); //ARGB
						
						if( value > max) value = max;
						else if( value < min) value = min;
						
						*iconPtr = (((value-min) * 255L) / diff);
					}
				}
			}
		}
		else
		{
			for (i = 0; i < destHeight; i++)  // lines
			{
				line = width * (long) (ratio * i) ;
				iconPtr = icon + rowBytes*i;
				for (j = 0; j < destWidth; j++, iconPtr++)         // columns 
				{ 
					value = *( image + line + (long) (j * ratio));
					
					if( value > max) value = max;
					else if( value < min) value = min;
					
					*iconPtr = (((value-min) * 255L) / diff);
				}
			}
		}
	}
	
	return icon;
}

// POLY CLIP
		


#define INIT_DELTAS dx=V2.x-V1.x;  dy=V2.y-V1.y;
#define INIT_CLIP INIT_DELTAS if(dx)m=dy/dx;

inline void CLIP_Left(NSPointInt *Polygon, long *count, NSPointInt V1,NSPointInt V2)
{
   float   dx,dy, m=1;
   INIT_CLIP

   // ************OK************
   if ( (V1.x>=0) && (V2.x>=0) )
   Polygon[(*count)++]=V2;
   // *********LEAVING**********
   if ( (V1.x>=0) && (V2.x<0) )
   {
      Polygon[(*count)].x=0;
      Polygon[(*count)++].y=V1.y+m*(0-V1.x);
   }
   // ********ENTERING*********
   if ( (V1.x<0) && (V2.x>=0) )
   {
      Polygon[(*count)].x=0;
      Polygon[(*count)++].y=V1.y+m*(0-V1.x);
      Polygon[(*count)++]=V2;
   }
}
inline void CLIP_Right(NSPointInt *Polygon,long *count, NSPointInt V1,NSPointInt V2, NSPointInt DownRight)
{
   float dx,dy, m=1;
   INIT_CLIP
   // ************OK************
   if ( (V1.x<=DownRight.x) && (V2.x<=DownRight.x) )
      Polygon[(*count)++]=V2;
   // *********LEAVING**********
   if ( (V1.x<=DownRight.x) && (V2.x>DownRight.x) )
   {
      Polygon[(*count)].x=DownRight.x;
      Polygon[(*count)++].y=V1.y+m*(DownRight.x-V1.x);
   }
   // ********ENTERING*********
   if ( (V1.x>DownRight.x) && (V2.x<=DownRight.x) )
   {
      Polygon[(*count)].x=DownRight.x;
      Polygon[(*count)++].y=V1.y+m*(DownRight.x-V1.x);
      Polygon[(*count)++]=V2;
   }
}
/*
=================
CLIP_Top
=================
*/
inline void CLIP_Top(NSPointInt *Polygon,long *count, NSPointInt V1,NSPointInt V2)
{
   float   dx,dy, m=1;
   INIT_CLIP
   // ************OK************
   if ( (V1.y>=0) && (V2.y>=0) )
      Polygon[(*count)++]=V2;
   // *********LEAVING**********
   if ( (V1.y>=0) && (V2.y<0) )
   {
      if(dx)
         Polygon[(*count)].x=V1.x+(0-V1.y)/m;
      else
         Polygon[(*count)].x=V1.x;
      Polygon[(*count)++].y=0;
   }
   // ********ENTERING*********
   if ( (V1.y<0) && (V2.y>=0) )
   {
      if(dx)
         Polygon[(*count)].x=V1.x+(0-V1.y)/m;
      else
         Polygon[(*count)].x=V1.x;
      Polygon[(*count)++].y=0;
      Polygon[(*count)++]=V2;
   }
}
inline void CLIP_Bottom(NSPointInt *Polygon,long *count, NSPointInt V1,NSPointInt V2, NSPointInt DownRight)
{
   float dx,dy, m=1;
   INIT_CLIP
   // ************OK************
   if ( (V1.y<=DownRight.y) && (V2.y<=DownRight.y) )
      Polygon[(*count)++]=V2;
   // *********LEAVING**********
   if ( (V1.y<=DownRight.y) && (V2.y>DownRight.y) )
   {
      if(dx)
         Polygon[(*count)].x=V1.x+(DownRight.y-V1.y)/m;
      else
         Polygon[(*count)].x=V1.x;
      Polygon[(*count)++].y=DownRight.y;
   }
   // ********ENTERING*********
   if ( (V1.y>DownRight.y) && (V2.y<=DownRight.y) )
   {
      if(dx)
         Polygon[(*count)].x=V1.x+(DownRight.y-V1.y)/m;
      else
         Polygon[(*count)].x=V1.x;
      Polygon[(*count)++].y=DownRight.y;
      Polygon[(*count)++]=V2;
   }
}

void CLIP_Polygon(NSPointInt *inPoly, long inCount, NSPointInt *outPoly, long *outCount, long w, long h)
{
	int				v,d;
	NSPointInt		TmpPoly[ 10000];
	long			TmpCount;	
	NSPointInt		DownRight;
	
	DownRight.x = w-1;
	DownRight.y = h-1;

   *outCount = 0;
   TmpCount=0;

   for (v=0; v<inCount; v++)
   {
      d=v+1;
      if(d==inCount)d=0;
      CLIP_Left( TmpPoly, &TmpCount, inPoly[v],inPoly[d]);
   }
   for (v=0; v<TmpCount; v++)
   {
      d=v+1;
      if(d==TmpCount)d=0;
      CLIP_Right(outPoly, outCount, TmpPoly[v],TmpPoly[d], DownRight);
   }
   TmpCount=0;
   for (v=0; v<*outCount; v++)
   {
      d=v+1;
      if(d==*outCount)d=0;
      CLIP_Top( TmpPoly, &TmpCount, outPoly[v],outPoly[d]);
   }
   *outCount=0;
   for (v=0; v<TmpCount; v++)
   {
      d=v+1;
      if(d==TmpCount)d=0;
      CLIP_Bottom(outPoly, outCount, TmpPoly[v],TmpPoly[d], DownRight);
   }
}

// POLY FILL

struct edge {
    struct edge *next;
    long yTop, yBot;
    long xNowWhole, xNowNum, xNowDen, xNowDir;
    long xNowNumStep;
};

#define MAXVERTICAL     10000

inline long sgn( long x)
{
	if( x > 0) return 1;
	else if( x < 0) return -1;
	
	return 0;
}

inline void FillEdges( NSPointInt *p, long no, struct edge *edgeTable[])
{
    int i, j, n = no;

	memset( edgeTable, 0, sizeof(char*) * MAXVERTICAL);

    for (i = 0; i < n; i++)
	{
        NSPointInt *p1, *p2, *p3;
        struct edge *e;
        p1 = &p[ i];
        p2 = &p[ (i + 1) % n];
        if (p1->y == p2->y)
            continue;   /* Skip horiz. edges */
        /* Find next vertex not level with p2 */
        for (j = (i + 2) % n; ; j = (j + 1) % n)
		{
            p3 = &p[ j];
            if (p2->y != p3->y)
                break;
        }
        e = malloc( sizeof( struct edge));
        e->xNowNumStep = ABS(p1->x - p2->x);
        if ( p2->y > p1->y)
		{
            e->yTop = p1->y;
            e->yBot = p2->y;
            e->xNowWhole = p1->x;
            e->xNowDir = sgn( p2->x - p1->x);
            e->xNowDen = e->yBot - e->yTop;
            e->xNowNum = (e->xNowDen >> 1);
            if ( p3->y > p2->y)
                e->yBot--;
        } else {
            e->yTop = p2->y;
            e->yBot = p1->y;
            e->xNowWhole = p2->x;
            e->xNowDir = sgn((p1->x) - (p2->x));
            e->xNowDen = e->yBot - e->yTop;
            e->xNowNum = (e->xNowDen >> 1);
            if ((p3->y) < (p2->y)) {
                e->yTop++;
                e->xNowNum += e->xNowNumStep;
                while (e->xNowNum >= e->xNowDen) {
                    e->xNowWhole += e->xNowDir;
                    e->xNowNum -= e->xNowDen;
                }
            }
        }
        e->next = edgeTable[ e->yTop];
        edgeTable[ e->yTop] = e;
    }
}

/*
 * UpdateActive first removes any edges which curY has entirely
 * passed by.  The removed edges are freed.
 * It then removes any edges from the edge table at curY and
 * places them on the active list.
 */

struct edge *UpdateActive( struct edge *active, struct edge *edgeTable[], long curY)
{
    struct edge *e, **ep;
    for (ep = &active, e = *ep; e != NULL; e = *ep)
        if (e->yBot < curY) {
            *ep = e->next;
            free(e);
        } else
            ep = &e->next;
    *ep = edgeTable[ curY];
    return active;
}

/*
 * DrawRuns first uses an insertion sort to order the X
 * coordinates of each active edge.  It updates the X coordinates
 * for each edge as it does this.
 * Then it draws a run between each pair of coordinates,
 * using the specified fill pattern.
 *
 * This routine is very slow and it would not be that
 * difficult to speed it way up.
 */

inline void DrawRuns(	struct edge *active,
						long curY,
						float *pix,
						long w,
						long h,
						float min,
						float max,
						BOOL outside,
						float newVal,
						BOOL RGB,
						BOOL compute,
						float *imax,
						float *imin,
						long *count,
						float *itotal,
						float *idev,
						float imean,
						long orientation,
						long stackNo)		// Only if X/Y orientation
{
    struct edge		*e;
	long			xCoords[ 4096];
	float			*curPix, val, temp;
    long			numCoords = 0;
    long			i, x, start, end, ims = w * h;
	
    for (e = active; e != NULL; e = e->next) {
        for (i = numCoords; i > 0 &&
          xCoords[i - 1] > e->xNowWhole; i--)
            xCoords[i] = xCoords[i - 1];
        xCoords[i] = e->xNowWhole;
        numCoords++;
        e->xNowNum += e->xNowNumStep;
        while (e->xNowNum >= e->xNowDen) {
            e->xNowWhole += e->xNowDir;
            e->xNowNum -= e->xNowDen;
        }
    }
    if (numCoords % 2)  /* Protect from degenerate polygons */
        xCoords[numCoords] = xCoords[numCoords - 1], numCoords++;
	
    for (i = 0; i < numCoords; i += 2)
	{
		// ** COMPUTE
		if( compute)
		{
			start = xCoords[i];		if( start < 0) start = 0;		if( start >= w) start = w;
			end = xCoords[i + 1];	if( end < 0) end = 0;			if( end >= w) end = w;
			
			switch( orientation)
			{
				case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];			break;
				case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		break;
				case 2:		curPix = &pix[ (curY * w) + start];							break;
			}
			
			x = end - start;
		
			if( RGB == NO)
			{
				while( x-- >= 0)
				{
					val = *curPix;
					
					if( imax)
					{
						if( val > *imax) *imax = val;
						if( val < *imin) *imin = val;
					
						*itotal += val;
						
						(*count)++;
					}
					
					if( idev)
					{
						temp = imean - val;
						temp *= temp;
						*idev += temp;
					}
					
					if( orientation) curPix ++;
					else curPix += w;
				}
			}
		}
		
		// ** DRAW
		else
		{
			if( outside)	// OUTSIDE
			{
				if( i == 0)
				{
					start = 0;			if( start < 0) start = 0;		if( start >= w) start = w;
					end = xCoords[i];	if( end < 0) end = 0;			if( end >= w) end = w;
					i--;
				}
				else
				{
					start = xCoords[i]+1;		if( start < 0) start = 0;		if( start >= w) start = w;
					
					if( i == numCoords-1)
					{
						end = w;
					}
					else end = xCoords[i+1];
					
					if( end < 0) end = 0;			if( end >= w) end = w;
				}
				
				if( RGB == NO)
				{
					switch( orientation)
					{
						case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];		break;
						case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		break;
						case 2:		curPix = &pix[ (curY * w) + start];							break;
					}
				
					x = end - start;
					while( x-- > 0)
					{
						if( *curPix >= min && *curPix <= max) *curPix = newVal;
						
						if( orientation) curPix ++;
						else curPix += w;
					}
				}
				else
				{
					switch( orientation)
					{
						case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];		break;
						case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		break;
						case 2:		curPix = &pix[ (curY * w) + start];							break;
					}
					
					x = end - start;
					
					while( x-- > 0)
					{
						unsigned char*  rgbPtr = (unsigned char*) curPix;
						
						if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] = newVal;
						if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] = newVal;
						if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] = newVal;
						
						if( orientation) curPix ++;
						else curPix += w;
					}
				}
			}
			else		// INSIDE
			{
				start = xCoords[i];		if( start < 0) start = 0;		if( start >= w) start = w;
				end = xCoords[i + 1];	if( end < 0) end = 0;			if( end >= w) end = w;
				
				switch( orientation)
				{
					case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];			break;
					case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		break;
					case 2:		curPix = &pix[ (curY * w) + start];							break;
				}
				
				x = end - start;
				
				if( RGB == NO)
				{
					while( x-- >= 0)
					{
						if( *curPix >= min && *curPix <= max) *curPix = newVal;
						
						if( orientation) curPix ++;
						else curPix += w;
					}
				}
				else
				{
					while( x-- >= 0)
					{
						unsigned char*  rgbPtr = (unsigned char*) curPix;
						
						if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] = newVal;
						if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] = newVal;
						if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] = newVal;
						
						if( orientation) curPix ++;
						else curPix += w;
					}
				}
			}
		}
	}
}

void ras_FillPolygon(	NSPointInt *p,
						long no,
						float *pix,
						long w,
						long h,
						long s,
						float min,
						float max,
						BOOL outside,
						float newVal,
						BOOL RGB,
						BOOL compute,
						float *imax,
						float *imin,
						long *count,
						float *itotal,
						float *idev,
						float imean,
						long orientation,
						long stackNo)
{
	struct edge *edgeTable[MAXVERTICAL];
    struct	edge *active;
    long	curY, i;
	BOOL	clip = NO;
	NSPointInt	*pTemp;
	

	
    FillEdges(p, no, edgeTable);
	
    for (curY = 0; edgeTable[ curY] == NULL; curY++)
        if (curY == MAXVERTICAL - 1)
            return;     /* No edges in polygon */
	
    for (active = NULL; (active = UpdateActive(active, edgeTable, curY)) != NULL; curY++)
	{
		DrawRuns(active, curY, pix, w, h, min, max, outside, newVal, RGB, compute, imax, imin, count, itotal, idev, imean, orientation, stackNo);
	}
	
	if( clip)
	{
		free( pTemp);
	}
}

inline long pnpoly( NSPoint *p, long count, float x, float y)
{
    int		i, j;
	long	c = 0;
    
    for (i = 0, j = count-1; i < count; j = i++)
	{
		if ((((p[i].y <= y) && (y < p[j].y)) ||
            ((p[j].y <= y) && (y < p[i].y))) &&
			(x < (p[j].x - p[i].x) * (y - p[i].y) / (p[j].y - p[i].y) + p[i].x))
        c = !c;
    }
    return c;
}

inline long pnpolyInt( struct NSPointInt *p, long count, long x, long y)
{
    long	i, j;
	long	c = 0;
    
    for (i = 0, j = count-1; i < count; j = i++)
	{
		if ((((p[i].y <= y) && (y < p[j].y)) ||
            ((p[j].y <= y) && (y < p[i].y))) &&
			(x < (p[j].x - p[i].x) * (y - p[i].y) / (p[j].y - p[i].y) + p[i].x))
        c = !c;
    }
    return c;
}

#define SetPixel(x,y,c) FrameBuffer[y*WIDTH+x]=c;

long BresLine(int Ax, int Ay, int Bx, int By,long **xBuffer, long **yBuffer)
{
	long	size = 0;
	long	maxVal = (abs(Ax - Bx)+abs(Ay - By)) + 2;
	
	*xBuffer = malloc( maxVal*sizeof(long));
	*yBuffer = malloc( maxVal*sizeof(long));
	
	int dX = abs(Bx-Ax);	// store the change in X and Y of the line endpoints
	int dY = abs(By-Ay);
	
	//------------------------------------------------------------------------
	// DETERMINE "DIRECTIONS" TO INCREMENT X AND Y (REGARDLESS OF DECISION)
	//------------------------------------------------------------------------
	int Xincr, Yincr;
	if (Ax > Bx) { Xincr=-1; } else { Xincr=1; }	// which direction in X?
	if (Ay > By) { Yincr=-1; } else { Yincr=1; }	// which direction in Y?
	
	//------------------------------------------------------------------------
	// DETERMINE INDEPENDENT VARIABLE (ONE THAT ALWAYS INCREMENTS BY 1 (OR -1) )
	// AND INITIATE APPROPRIATE LINE DRAWING ROUTINE (BASED ON FIRST OCTANT
	// ALWAYS). THE X AND Y'S MAY BE FLIPPED IF Y IS THE INDEPENDENT VARIABLE.
	//------------------------------------------------------------------------
	if (dX >= dY)	// if X is the independent variable
	{           
		int dPr 	= dY<<1;           // amount to increment decision if right is chosen (always)
		int dPru 	= dPr - (dX<<1);   // amount to increment decision if up is chosen
		int P 		= dPr - dX;  // decision variable start value

		for (; dX>=0; dX--)            // process each point in the line one at a time (just use dX)
		{
			(*xBuffer)[ size] = Ax;
			(*yBuffer)[ size] = Ay;
			size++;
			
			if (P > 0)               // is the pixel going right AND up?
			{ 
				Ax+=Xincr;	       // increment independent variable
				Ay+=Yincr;         // increment dependent variable
				P+=dPru;           // increment decision (for up)
			}
			else                     // is the pixel just going right?
			{
				Ax+=Xincr;         // increment independent variable
				P+=dPr;            // increment decision (for right)
			}
		}		
	}
	else              // if Y is the independent variable
	{
		int dPr 	= dX<<1;           // amount to increment decision if right is chosen (always)
		int dPru 	= dPr - (dY<<1);   // amount to increment decision if up is chosen
		int P 		= dPr - dY;  // decision variable start value

		for (; dY>=0; dY--)            // process each point in the line one at a time (just use dY)
		{
			(*xBuffer)[ size] = Ax;
			(*yBuffer)[ size] = Ay;
			size++;
			
			if (P > 0)               // is the pixel going up AND right?
			{ 
				Ax+=Xincr;         // increment dependent variable
				Ay+=Yincr;         // increment independent variable
				P+=dPru;           // increment decision (for up)
			}
			else                     // is the pixel just going up?
			{
				Ay+=Yincr;         // increment independent variable
				P+=dPr;            // increment decision (for right)
			}
		}		
	}
	
	if( maxVal < size)
	{
		NSLog( @"MAJOR BUG");
	}
	
	return size;
}

@implementation DCMPix

//- (void) convertToFull16Bits: (unsigned short*) rawdata size:(long) RawSize BitsAllocated:(long) BitsAllocated BitsStored:(long) BitsStored HighBitPosition:(long) HighBitPosition PixelSign:(BOOL) PixelSign
//{
//	int l = (int)( RawSize / ( BitsAllocated / 8 ) );
//	int i;
//	
//	if ( BitsAllocated == 16 )
//	{
//		// pmask : to mask the 'unused bits' (may contain overlays)
//		uint16_t pmask = 0xffff;
//		pmask = pmask >> ( BitsAllocated - BitsStored );
//
//		uint16_t *deb = (uint16_t*) rawdata;
//	
//		if ( !PixelSign )  // Pixels are unsigned
//		{
//			for(i = 0; i<l; i++)
//			{   
//				*deb = (*deb >> (BitsStored - HighBitPosition - 1)) & pmask;
//				deb++;
//			}
//		}
//		else // Pixels are signed
//		{
//			// smask : to check the 'sign' when BitsStored != BitsAllocated
//			uint16_t smask = 0x0001;
//			smask = smask << ( 16 - (BitsAllocated - BitsStored + 1) );
//			// nmask : to propagate sign bit on negative values
//			int16_t nmask = (int16_t)0x8000;  
//			nmask = nmask >> ( BitsAllocated - BitsStored - 1 );
//			
//			for(i = 0; i<l; i++)
//			{
//				*deb = *deb >> (BitsStored - HighBitPosition - 1);
//				if ( *deb & smask )
//				{
//					*deb = *deb | nmask;
//				}
//				else
//				{
//					*deb = *deb & pmask;
//				}
//				
//				deb++;
//			}
//		}
//	}
//}

+ (NSImage*) resizeIfNecessary:(NSImage*) currentImage dcmPix: (DCMPix*) dcmPix
{
	NSRect sourceRect = NSMakeRect(0.0, 0.0, [currentImage size].width, [currentImage size].height);
	NSRect imageRect;
	float rescale = 1;
	
	// Rescale image if resolution is too high, compared to the original resolution
	
	#define MAXSIZE 1.3
	
	if(		[currentImage size].width > [dcmPix pwidth]*MAXSIZE &&
			[currentImage size].height > [dcmPix pheight]*MAXSIZE)
		{
			if( [currentImage size].width/[dcmPix pwidth] < [currentImage size].height / [dcmPix pheight])
			{
				float ratio = [currentImage size].width / ([dcmPix pwidth] * MAXSIZE);
				imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
				
				NSLog( @"ratio: %f", ratio);
			}
			else
			{
				float ratio = [currentImage size].height / ([dcmPix pheight] * MAXSIZE);
				imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
				
				NSLog( @"ratio: %f", ratio);
			}
		[currentImage setScalesWhenResized:YES];
		
		NSImage *compositingImage = [[NSImage alloc] initWithSize: imageRect.size];
		
		[compositingImage lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		[currentImage drawInRect: imageRect fromRect: sourceRect operation: NSCompositeCopy fraction: 1.0];
		[compositingImage unlockFocus];
		
		NSLog( @"New Size: %f %f", [compositingImage size].width, [compositingImage size].height);
		
		return [compositingImage autorelease];
	}
	else return currentImage;
}

- (NSImage*) image
{
	unsigned char		*buf = 0L;
	long				i;
	NSImage				*imageRep = 0L;
	NSBitmapImageRep	*rep;

	if( [self isRGB] == YES)
	{
		i = width * height * 3;
		buf = malloc( i);
		if( buf)
		{
			unsigned char *dst = buf, *src = (unsigned char*) [self baseAddr];
			i = width * height;
			
			// CONVERT ARGB TO RGB
			while( i-- > 0)
			{
				src++;
				*dst++ = *src++;
				*dst++ = *src++;
				*dst++ = *src++;
			}
		}
		
		rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:0L
						   pixelsWide:width
						   pixelsHigh:height
						bitsPerSample:8
					  samplesPerPixel:3
							 hasAlpha:NO
							 isPlanar:NO
					   colorSpaceName:NSCalibratedRGBColorSpace
						  bytesPerRow:width*3
						 bitsPerPixel:24] autorelease];
						 
		memcpy( [rep bitmapData], buf, height*width*3);
	
		imageRep = [[[NSImage alloc] init] autorelease];
		[imageRep addRepresentation:rep];
     
		free( buf);
	}
	else
	{
		i = width * height;
		buf = malloc( i);
		if( buf)
		{
			memcpy( buf, baseAddr, width*height);
		}
		
		rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:0L
						   pixelsWide:width
						   pixelsHigh:height
						bitsPerSample:8
					  samplesPerPixel:1
							 hasAlpha:NO
							 isPlanar:NO
					   colorSpaceName:NSCalibratedWhiteColorSpace
						  bytesPerRow:width
						 bitsPerPixel:8] autorelease];
		
		memcpy( [rep bitmapData], buf, height*width);
	
		imageRep = [[[NSImage alloc] init] autorelease];
		[imageRep addRepresentation:rep];
     
		free( buf);
	}
	
	return imageRep;
}

- (unsigned char *) ConvertYbrToRgb: (unsigned char *) ybrImage :(int) w :(int) h :(long) theKind :(char) planarConfig
{
  long			loop, size;
  unsigned char		*pYBR, *pRGB;
  unsigned char		*theRGB;
  int			y, y1, r;
  
  
  // the planar configuration should be set to 0 whenever
  // YBR_FULL_422 or YBR_PARTIAL_422 is used
  if (theKind != YBR_FULL && planarConfig == 1)
    return NULL;
  
  // allocate room for the RGB image
  theRGB = (unsigned char *) malloc ((long) w * (long) h * 3L);
  if (theRGB == NULL) return NULL;
  pRGB = theRGB;
  size = (long) w * (long) h;
  
  int32_t R, G, B;
   uint8_t a;
   uint8_t b;
   uint8_t c;

  
  switch (planarConfig)
  {
    case 0 : // all pixels stored one after the other
      switch (theKind)
      {
        case YBR_FULL :		// YBR_FULL
          // loop on the pixels of the image
          for (loop = 0L, pYBR = ybrImage; loop < size; loop++, pYBR += 3)
          {
            // get the Y, B and R channels from the original image
//            y = (int) pYBR [0];
//            b = (int) pYBR [1];
//            r = (int) pYBR [2];

			a = (int) pYBR [0];
            b = (int) pYBR [1];
            c = (int) pYBR [2];

         R = 38142 *(a-16) + 52298 *(c -128);
         G = 38142 *(a-16) - 26640 *(c -128) - 12845 *(b -128);
         B = 38142 *(a-16) + 66093 *(b -128);

         R = (R+16384)>>15;
         G = (G+16384)>>15;
         B = (B+16384)>>15;

         if (R < 0)   R = 0;
         if (G < 0)   G = 0;
         if (B < 0)   B = 0;
         if (R > 255) R = 255;
         if (G > 255) G = 255;
         if (B > 255) B = 255;


            // red
            *pRGB = R;	//(unsigned char) (y + (1.402 *  r));
            pRGB++;	// move the ptr to the Green
            
            // green
            *pRGB = G;	//(unsigned char) (y - (0.344 * b) - (0.714 * r));
            pRGB++;	// move the ptr to the Blue
            
            // blue
            *pRGB = B;	//(unsigned char) (y + (1.772 * b));
            pRGB++;	// move the ptr to the next Red
            
          } // for ...loop on the elements of the image to convert
          break; // YBR_FULL
        
        case YBR_FULL_422 :	// YBR_FULL_422
        case YBR_PARTIAL_422 :	// YBR_PARTIAL_422
          // loop on the pixels of the image
          for (loop = 0L, pYBR = ybrImage; loop < (size / 2); loop++)
          {
            // get the Y, B and R channels from the original image
            y  = (int) pYBR [0];
            y1 = (int) pYBR [1];
            // the Cb and Cr values are sampled horizontally at half the Y rate
            b = (int) pYBR [2];
            r = (int) pYBR [3];
            
            // ***** first pixel *****
            // red 1
            *pRGB = (unsigned char) ((1.1685 * y) + (0.0389 * b) + (1.596 * r));
            pRGB++;	// move the ptr to the Green
            
            // green 1
            *pRGB = (unsigned char) ((1.1685 * y) - (0.401 * b) - (0.813 * r));
            pRGB++;	// move the ptr to the Blue
            
            // blue 1
            *pRGB = (unsigned char) ((1.1685 * y) + (2.024 * b));
            pRGB++;	// move the ptr to the next Red
            
            
            // ***** second pixel *****
            // red 2
            *pRGB = (unsigned char) ((1.1685 * y1) + (0.0389 * b) + (1.596 * r));
            pRGB++;	// move the ptr to the Green
            
            // green 2
            *pRGB = (unsigned char) ((1.1685 * y1) - (0.401 * b) - (0.813 * r));
            pRGB++;	// move the ptr to the Blue
            
            // blue 2
            *pRGB = (unsigned char) ((1.1685 * y1) + (2.024 * b));
            pRGB++;	// move the ptr to the next Red

            // the Cb and Cr values are sampled horizontally at half the Y rate
            pYBR += 4;
            
          } // for ...loop on the elements of the image to convert
          break; // YBR_FULL_422 and YBR_PARTIAL_422
                
        default :
          // none...
          break;
      } // switch ...kind of YBR
      break;
    
    case 1 : // each plane is stored separately (only allowed for YBR_FULL)
    {
      unsigned char *pY, *pB, *pR;	// ptr to Y, Cb and Cr channels of the original image
        
      // points to the begining of each channel in memory
      pY = ybrImage;
      pB = (unsigned char *) (pY + size);
      pR = (unsigned char *) (pB + size);
        
      // loop on the pixels of the image
      for (loop = 0L; loop < size; loop++, pY++, pB++, pR++)
      {
		a = (int) *pY;
		b = (int) *pB;
		c = (int) *pR;

         R = 38142 *(a-16) + 52298 *(c -128);
         G = 38142 *(a-16) - 26640 *(c -128) - 12845 *(b -128);
         B = 38142 *(a-16) + 66093 *(b -128);

         R = (R+16384)>>15;
         G = (G+16384)>>15;
         B = (B+16384)>>15;

         if (R < 0)   R = 0;
         if (G < 0)   G = 0;
         if (B < 0)   B = 0;
         if (R > 255) R = 255;
         if (G > 255) G = 255;
         if (B > 255) B = 255;
	  
	  
        // red
        *pRGB = R;	//(unsigned char) ((int) *pY + (1.402 *  (int) *pR) - 179.448);
        pRGB++;	// move the ptr to the Green
            
        // green
        *pRGB = G;	//(unsigned char) ((int) *pY - (0.344 * (int) *pB) - (0.714 * (int) *pR) + 135.45);
        pRGB++;	// move the ptr to the Blue
            
        // blue
        *pRGB = B;	//(unsigned char) ((int) *pY + (1.772 * (int) *pB) - 226.8);
        pRGB++;	// move the ptr to the next Red
            
      } // for ...loop on the elements of the image to convert
      break;
    } // case 1
    
    default :
      // none
      break;
  
  } // switch
    
  return theRGB;
  
} // endof ConvertYbrToRgb

- (float*) getLineROIValue :(long*) numberOfValues :(ROI*) roi
{
    long			count, i, no, size;
	float			x, y, *values;
	long			*xPoints, *yPoints;
    NSPoint			upleft, downright;
	NSPoint			*pts;
	NSMutableArray  *ptsTemp = [roi points];
	
    [self CheckLoad];
	
	pts = (NSPoint*) malloc( [ptsTemp count] * sizeof(NSPoint));
	no = [ptsTemp count];
	for( i = 0; i < no; i++)
	{
		pts[ i] = [[ptsTemp objectAtIndex: i] point];
	//	pts[ i].x+=1.5;
	//	pts[ i].y+=1.5;
	}	
	
	upleft = downright = [[ptsTemp objectAtIndex:0] point];
	
	for( i = 0; i < [ptsTemp count]; i++)
	{
		if( upleft.x > [[ptsTemp objectAtIndex:i] x]) upleft.x = [[ptsTemp objectAtIndex:i] x];
		if( upleft.y > [[ptsTemp objectAtIndex:i] y]) upleft.y = [[ptsTemp objectAtIndex:i] y];

		if( downright.x < [[ptsTemp objectAtIndex:i] x]) downright.x = [[ptsTemp objectAtIndex:i] x];
		if( downright.y < [[ptsTemp objectAtIndex:i] y]) downright.y = [[ptsTemp objectAtIndex:i] y];
	}
	
	if( upleft.x < 0) upleft.x = 0;
	if( downright.x < 0) downright.x = 0;
	if( upleft.x > width) upleft.x = width;
	if( downright.x > width) downright.x = width;

	if( upleft.y < 0) upleft.y = 0;
	if( downright.y < 0) downright.y = 0;
	if( upleft.y > height) upleft.y = height;
	if( downright.y > height) downright.y = height;
	
	size = BresLine(	[[ptsTemp objectAtIndex:0] x],
						[[ptsTemp objectAtIndex:0] y],
						[[ptsTemp objectAtIndex:1] x],
						[[ptsTemp objectAtIndex:1] y],
						&xPoints,
						&yPoints);
	
	values = (float*) malloc( size * sizeof(float));
	if( values)
	{
		count = 0;
		for( i = 0; i < size; i++)
		{
			if( yPoints[ i] >= 0 && yPoints[ i] < height && xPoints[ i] >= 0 && xPoints[ i] < width)
			{
				if( isRGB)
				{
					unsigned char*  rgbPtr = (unsigned char*) fImage;
					long			pos;
					
					pos =  4*width*yPoints[ i];
					pos += 4*xPoints[ i];
					
					values[ count] = (rgbPtr[ pos+1] + rgbPtr[ pos+2] + rgbPtr[ pos+3])/3;
				}
				else
				{
					values[ count] = fImage[ width*yPoints[ i] + xPoints[ i]];
				}
				
			}
			else values[ count] = 0;
			
			count++;
		}
	}
	*numberOfValues = count;
	
	if( roi) free( pts);
	
	free( xPoints);
	free( yPoints);
	
	return values;
}

- (float*) getROIValue :(long*) numberOfValues :(ROI*) roi :(float**) locations
{
    long			count = 0, i, no;
	long			x, y;
	float			*values = 0L;
	long			upleftx, uplefty, downrightx, downrighty;
	NSPoint			*pts;
	
	if( [roi type] == tPlain)
	{
		long			textWidth = [roi textureWidth];
		long			textHeight = [roi textureHeight];
		long			textureUpLeftCornerX = [roi textureUpLeftCornerX];
		long			textureUpLeftCornerY = [roi textureUpLeftCornerY];
		unsigned char	*buf = [roi textureBuffer];
		
		values = (float*) malloc( textHeight*textWidth* sizeof(float));
		
		if( locations) *locations = (float*) malloc( textHeight*textWidth*2* sizeof(float));
		
		if( values)
		{
			count = 0;
			
			for( y = 0; y < textHeight; y++)
			{
				for( x = 0; x < textWidth; x++)
				{
					if( buf [ x + y * textWidth] != 0)
					{
						long	xx = (x + textureUpLeftCornerX);
						long	yy = (y + textureUpLeftCornerY);
						
						if( xx >= 0 && xx < width && yy >= 0 && yy < height)
						{
							float	*curPix = &fImage[ (yy * width) + xx];
							values[ count] = *curPix;	//fImage[ width*y + x];
							
							if( locations)
							{
								if( *locations)
								{
									(*locations)[ count*2] = x;
									(*locations)[ count*2 + 1] = y;
								}
							}
							count++;
						}
					}
				}
			}
		}
	}
	else
	{
		NSMutableArray  *ptsTemp = [roi points];
		
		if( [ptsTemp count] == 0) return 0L;
		
		[self CheckLoad];
		
		pts = (NSPoint*) malloc( [ptsTemp count] * sizeof(NSPoint));
		no = [ptsTemp count];
		for( i = 0; i < no; i++)
		{
			pts[ i] = [[ptsTemp objectAtIndex: i] point];
		}	

		upleftx = downrightx = [[ptsTemp objectAtIndex:0] x];
		uplefty = downrighty = [[ptsTemp objectAtIndex:0] y];
		
		for( i = 0; i < [ptsTemp count]; i++)
		{
			if( upleftx > [[ptsTemp objectAtIndex:i] x]) upleftx = [[ptsTemp objectAtIndex:i] x];
			if( uplefty > [[ptsTemp objectAtIndex:i] y]) uplefty = [[ptsTemp objectAtIndex:i] y];

			if( downrightx < [[ptsTemp objectAtIndex:i] x]) downrightx = [[ptsTemp objectAtIndex:i] x];
			if( downrighty < [[ptsTemp objectAtIndex:i] y]) downrighty = [[ptsTemp objectAtIndex:i] y];
		}
		
		if( upleftx < 0) upleftx = 0;
		if( downrightx < 0) downrightx = 0;
		if( upleftx > width) upleftx = width;
		if( downrightx > width) downrightx = width;

		if( uplefty < 0) uplefty = 0;
		if( downrighty < 0) downrighty = 0;
		if( uplefty > height) uplefty = height;
		if( downrighty > height) downrighty = height;
		
		count = 0;
		y = (downrighty - uplefty);
		x = (downrightx - upleftx);
		values = (float*) malloc( x*y* sizeof(float));
		if( locations) *locations = (float*) malloc( x*y*2* sizeof(float));
		
		if( values)
		{
			for( y = uplefty; y < downrighty ; y++)
			{
				for( x = upleftx; x < downrightx ; x++)
				{
					if( pnpoly( pts, no, x, y) > 0)
					{
						if( isRGB)
						{
							unsigned char*  rgbPtr = (unsigned char*) fImage;
							long			pos;
							
							pos =  4*width*y;
							pos += 4*x;
							
							values[ count] = (rgbPtr[ pos+1] + rgbPtr[ pos+2] + rgbPtr[ pos+3])/3;
						}
						else
						{
							values[ count] = fImage[ width*y + x];
						}
						
						if( locations)
						{
							if( *locations)
							{
								(*locations)[ count*2] = x;
								(*locations)[ count*2 + 1] = y;
							}
						}
						count++;
					}
				}
			}
		}
		
		y = (downrighty - uplefty);
		x = (downrightx - upleftx);
		
		if( count > x*y)
		{
			NSLog(@"%d / %d", count, (long) ((downrighty - uplefty) * (downrightx - upleftx)));
		}
		
		if( roi) free( pts);
	}
	
	*numberOfValues = count;
	
	return values;
}

- (BOOL) isInROI:(ROI*) roi:(NSPoint) pt
{
	NSMutableArray  *ptsTemp = [roi points];
	BOOL			result = NO;
	long			x, y, z, i, no;
	long			minx, maxx, miny, maxy;
	NSPoint			*pts;

	
    [self CheckLoad];

	if( roi)
	{
		minx = maxx = [[ptsTemp objectAtIndex: 0] x];
		miny = maxy = [[ptsTemp objectAtIndex: 0] y];
		
		// Find the max rectangle of the ROI
		for( z = 0; z < [ptsTemp count]; z++)
		{
			if( minx > [[ptsTemp objectAtIndex: z] x]) minx = [[ptsTemp objectAtIndex: z] x];
			if( maxx < [[ptsTemp objectAtIndex: z] x]) maxx = [[ptsTemp objectAtIndex: z] x];
			if( miny > [[ptsTemp objectAtIndex: z] y]) miny = [[ptsTemp objectAtIndex: z] y];
			if( maxy < [[ptsTemp objectAtIndex: z] y]) maxy = [[ptsTemp objectAtIndex: z] y];
		}
		
		if( pt.x < minx || pt.x > maxx) return NO;
		if( pt.y < miny || pt.y > maxy) return NO;
		
		if( [roi type] == tROI) return YES;
		
		pts = (NSPoint*) malloc( [ptsTemp count] * sizeof(NSPoint));
		no = [ptsTemp count];
		for( i = 0; i < no; i++)
		{
			pts[ i] = [[ptsTemp objectAtIndex: i] point];
		}
		
		x = pt.x;
		y = pt.y;
		
		if( pnpoly( pts, no, x, y))
		{
			result = YES;
		}
		
		free( pts);
	}
	
	return result;
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo
{
    long				count, i, no = 0;
	long				x, y;
    long				upleftx, uplefty, downrightx, downrighty, ims = width * height;
	struct NSPointInt	*ptsInt = 0L;
	NSMutableArray		*ptsTemp = 0L;
	float				*fTempImage;
	BOOL				clip;
	
    [self CheckLoad];

	if( roi)
	{
		if( [roi type] == tPlain)
		{
			long			textWidth = [roi textureWidth];
			long			textHeight = [roi textureHeight];
			long			textureUpLeftCornerX = [roi textureUpLeftCornerX];
			long			textureUpLeftCornerY = [roi textureUpLeftCornerY];
			unsigned char	*buf = [roi textureBuffer];
			
			// *** INSIDE
			
			if( outside == NO)
			{
				for( y = textureUpLeftCornerY; y < textureUpLeftCornerY + textHeight; y++)
				{
					if( isRGB)
					{
						unsigned char *rgbPtr = (unsigned char*) (fImage + textureUpLeftCornerX + y*width);
						for( x = textureUpLeftCornerX; x < textureUpLeftCornerX + textWidth; x++)
						{
							if( *buf++)
							{
								if( x >= 0 && x < width && y >= 0 && y < height)
								{
									if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
									if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
									if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
								}
							}
							rgbPtr += 4;
						}
					}
					else
					{
						float *fTempImage = fImage + textureUpLeftCornerX + y*width;
						for( x = textureUpLeftCornerX; x < textureUpLeftCornerX + textWidth; x++)
						{
							if( *buf++)
							{
								if( x >= 0 && x < width && y >= 0 && y < height)
								{
									if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
								}
							}
							fTempImage++;
						}
					}
				}
			}
			
			// *** OUTSIDE
			
			else
			{
				for( y = 0; y < height; y++)
				{
					for( x = 0; x < width; x++)
					{
						BOOL doit = NO;
						
						if( x >= textureUpLeftCornerX && x < textureUpLeftCornerX + textWidth && y >= textureUpLeftCornerY && y < textureUpLeftCornerY + textHeight)
						{
							if( !buf [ x - textureUpLeftCornerX + (y - textureUpLeftCornerY) * textWidth]) doit = YES;
						} 
						else doit = YES;
						
						if( doit)
						{
							long	xx = x;
							long	yy = y;
						
							if( isRGB)
							{
								unsigned char*  rgbPtr = (unsigned char*) &fImage[ (yy * width) + xx];
								
								if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
								if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
								if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
							}
							else
							{
								float	*fTempImage = &fImage[ (yy * width) + xx];
								
								if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
							}
						}
					}
				}
			}
			
			return;
		}
		else
		{
			ptsTemp = [roi points];
			
			ptsInt = (struct NSPointInt*) malloc( [ptsTemp count] * sizeof( struct NSPointInt));
			no = [ptsTemp count];
			for( i = 0; i < no; i++)
			{
				ptsInt[ i].x = [[ptsTemp objectAtIndex: i] point].x;
				ptsInt[ i].y = [[ptsTemp objectAtIndex: i] point].y;
			}
			
			// Need to clip?
			NSPointInt *pTemp;
			long yIm, xIm;
			
			switch( orientationStack)
			{
				case 0:	yIm = [pixArray count];		xIm = width;	break;
				case 1:	yIm = [pixArray count];		xIm = height;	break;
				case 2:	yIm = height;				xIm = width;	break;
			}
			
			clip = NO;
			switch( orientationStack)
			{
				case 2:
					for( i = 0; i < no && clip == NO; i++)
					{
						if( ptsInt[ i].x < 0) clip = YES;
						if( ptsInt[ i].y < 0) clip = YES;
						if( ptsInt[ i].x >= width) clip = YES;
						if( ptsInt[ i].y >= height) clip = YES;
					}
					
					if( clip)
					{
						long newNo;
						
						pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
						CLIP_Polygon( ptsInt, no, pTemp, &newNo, width, height);
						
						free( ptsInt);
						ptsInt = pTemp;
						
						no = newNo;
					}
					break;
					
				case 0:
					for( i = 0; i < no && clip == NO; i++)
					{
						if( ptsInt[ i].x < 0) clip = YES;
						if( ptsInt[ i].y < 0) clip = YES;
						if( ptsInt[ i].x >= height) clip = YES;
						if( ptsInt[ i].y >= [pixArray count]) clip = YES;
					}
					
					if( clip)
					{
						long newNo;
						
						pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
						CLIP_Polygon( ptsInt, no, pTemp, &newNo, height, [pixArray count]);
						
						free( ptsInt);
						ptsInt = pTemp;
						no = newNo;
					}
					break;
					
				case 1:
					for( i = 0; i < no && clip == NO; i++)
					{
						if( ptsInt[ i].x < 0) clip = YES;
						if( ptsInt[ i].y < 0) clip = YES;
						if( ptsInt[ i].x >= width) clip = YES;
						if( ptsInt[ i].y >= [pixArray count]) clip = YES;
					}
					
					if( clip)
					{
						long newNo;
						
						pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
						CLIP_Polygon( ptsInt, no, pTemp, &newNo, width, [pixArray count]);
						
						free( ptsInt);
						ptsInt = pTemp;
						no = newNo;
					}
				break;
			}
		}
	}
	else ptsInt = 0L;

	if( outside)
	{
		long yIm, xIm;
		
		switch( orientationStack)
		{
			case 0:	yIm = [pixArray count];		xIm = width;	break;
			case 1:	yIm = [pixArray count];		xIm = height;	break;
			case 2:	yIm = height;				xIm = width;	break;
		}
		
		if( roi) uplefty = downrighty = ptsInt[0].y;
		else
		{
			uplefty = 0;
			downrighty = yIm;
		}
		
		for( i = 0; i < no; i++)
		{
			if( uplefty > ptsInt[i].y) uplefty = ptsInt[i].y;
			if( downrighty < ptsInt[i].y) downrighty = ptsInt[i].y;
		}
		
		if( uplefty < 0) uplefty = 0;
		if( uplefty >= yIm) uplefty = yIm-1;
		
		if( downrighty < 0) downrighty = 0;
		if( downrighty >= yIm) downrighty = yIm-1;
		
		
		if( isRGB)
		{
			for( y = 0; y < uplefty ; y++)
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( x = 0; x < width ; x++)
				{
					unsigned char*  rgbPtr = (unsigned char*) fTempImage;
					long			pos;
					
					if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
					if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
					if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
					
					if( orientationStack) fTempImage ++;
					else fTempImage += width;
				}
			}
			
			for( y = downrighty; y < yIm ; y++)
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( x = 0; x < width ; x++)
				{
					unsigned char*  rgbPtr = (unsigned char*) fTempImage;
					long			pos;
					
					if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
					if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
					if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
					
					if( orientationStack) fTempImage ++;
					else fTempImage += width;
				}
			}
		}
		else
		{
			for( y = 0; y < uplefty ; y++)
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( x = 0; x < width ; x++)
				{
					if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
					
					if( orientationStack) fTempImage ++;
					else fTempImage += width;
				}
			}
			
			for( y = downrighty; y < yIm ; y++)
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( x = 0; x < width ; x++)
				{
					if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
					
					if( orientationStack) fTempImage ++;
					else fTempImage += width;
				}
			}
		}
	}
	
	if( ptsInt != 0L && no > 1)
	{
		ras_FillPolygon( ptsInt, no, fImage, width, height, [pixArray count], minValue, maxValue, outside, newVal, isRGB, NO, 0L, 0L, 0L, 0L, 0L, 0, orientationStack, stackNo);
	}
	else	
	{	// Fill the image that contains no ROI :
		if( outside)
		{
			long yIm, xIm;
			
			switch( orientationStack)
			{
				case 0:	yIm = [pixArray count];		xIm = width;	break;
				case 1:	yIm = [pixArray count];		xIm = height;	break;
				case 2:	yIm = height;				xIm = width;	break;
			}
		
			if( isRGB)
			{
				for( y = 0; y < yIm ; y++)
				{
					switch( orientationStack)
					{
						case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
						case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
						case 2:		fTempImage = fImage + width*y;							break;
					}
					
					for( x = 0; x < xIm ; x++)
					{
						unsigned char*  rgbPtr = (unsigned char*) fTempImage;
						
						if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
						if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
						if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
						
						if( orientationStack) fTempImage ++;
						else fTempImage += width;
					}
				}
			}
			else
			{
				for( y = 0; y < yIm ; y++)
				{
					switch( orientationStack)
					{
						case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
						case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
						case 2:		fTempImage = fImage + width*y;							break;
					}
					
					for( x = 0; x < xIm ; x++)
					{
						if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
						
						if( orientationStack) fTempImage ++;
						else fTempImage += width;
					}
				}
			}
		}
	}
	
	if( roi)
	{
		free( ptsInt);
	}
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside
{
	[self fillROI:roi :newVal :minValue :maxValue :outside :2 :-1];
}

- (void) computeROIInt:(ROI*) roi :(float*) mean :(float *)total :(float *)dev :(float *)min :(float *)max
{
	long			count, i, no, x, y;
	float			val, imax, temp, imin, itotal, idev, imean;
	
	count = 0;
	itotal = 0;
	imean = 0;
	idev = 0;
	imin = 99999;
	imax = -99999;
	
	[self CheckLoad];
	
	if( [roi type] == tPlain)
	{
		long			textWidth = [roi textureWidth];
		long			textHeight = [roi textureHeight];
		long			textureUpLeftCornerX = [roi textureUpLeftCornerX];
		long			textureUpLeftCornerY = [roi textureUpLeftCornerY];
		unsigned char	*buf = [roi textureBuffer];
		float			*fImageTemp;
		
		for( y = 0; y < textHeight; y++)
		{
			fImageTemp = fImage + ((y + textureUpLeftCornerY) * width) + textureUpLeftCornerX;
			
			for( x = 0; x < textWidth; x++, fImageTemp++)
			{
				if( *buf++ != 0)
				{
					long	xx = (x + textureUpLeftCornerX);
					long	yy = (y + textureUpLeftCornerY);
					
					if( xx >= 0 && xx < width && yy >= 0 && yy < height)
					{
						if( isRGB)
						{
							unsigned char*  rgbPtr = (unsigned char*) &fImage[ (yy * width) + xx];
							float val = rgbPtr[ 0] + rgbPtr[ 1] + rgbPtr[2] / 3;
							
							count++;
							itotal += val;
							
							if( imin > val) imin = val;
							if( imax < val) imax = val;
						}
						else
						{
							float	val = *fImageTemp;
							
							count++;
							itotal += val;
							
							if( imin > val) imin = val;
							if( imax < val) imax = val;
						}
					}
				}
			}
		}
		
		if( count!= 0) imean = itotal / count;
		
		if( dev != 0L && count > 0)
		{
			idev = 0;
			
			buf = [roi textureBuffer];
			
			for( y = 0; y < textHeight; y++)
			{
				fImageTemp = fImage + ((y + textureUpLeftCornerY) * width) + textureUpLeftCornerX;
				
				for( x = 0; x < textWidth; x++, fImageTemp++)
				{
					if( *buf++ != 0)
					{
						long	xx = (x + textureUpLeftCornerX);
						long	yy = (y + textureUpLeftCornerY);
						
						if( xx >= 0 && xx < width && yy >= 0 && yy < height)
						{
							if( isRGB)
							{
								unsigned char*  rgbPtr = (unsigned char*) &fImage[ (yy * width) + xx];
								float val = rgbPtr[ 0] + rgbPtr[ 1] + rgbPtr[2] / 3;
								
								float temp = imean - val;
								temp *= temp;
								idev += temp;
							}
							else
							{
								float	val = *fImageTemp;
								
								float temp = imean - val;
								temp *= temp;
								idev += temp;
							}
						}
					}
				}
			}
			*dev = idev;
			*dev = *dev / (count-1);
			*dev = sqrt(*dev);
		}
		
		if( max) *max = imax;
		if( min) *min = imin;
		if( total) *total = itotal;
		if( mean) *mean = imean;
	}
	else
	{
		NSMutableArray  *ptsTemp = [roi points];
		NSPointInt		*pts;
		
		pts = (NSPointInt*) malloc( [ptsTemp count] * sizeof(NSPointInt));
		no = [ptsTemp count];
		for( i = 0; i < no; i++)
		{
			pts[ i].x = [[ptsTemp objectAtIndex: i] point].x;
			pts[ i].y = [[ptsTemp objectAtIndex: i] point].y;
		}
		
		// Need to clip?
		NSPointInt *pTemp;
		BOOL clip = NO;

		for( i = 0; i < no && clip == NO; i++)
		{
			if( pts[ i].x < 0) clip = YES;
			if( pts[ i].y < 0) clip = YES;
			if( pts[ i].x >= width) clip = YES;
			if( pts[ i].y >= height) clip = YES;
		}
		
		if( no == 1)
		{
			if( clip)
			{
				if( max) *max = 0;
				if( min) *min = 0;
				if( mean) *mean = 0;
				if( total) *total = 0;
			}
			else if( isRGB)
			{
				unsigned char*  rgbPtr = (unsigned char*) &fImage[ (pts[ 0].y * width) + pts[ 0].x];
				
				float val = rgbPtr[ 0] + rgbPtr[ 1] + rgbPtr[2] / 3;
				
				if( max) *max = val;
				if( min) *min = val;
				if( mean) *mean = val;
				if( total) *total = val;
			}
			else
			{
				float	*curPix = &fImage[ (pts[ 0].y * width) + pts[ 0].x];
				
				float val = *curPix;
				
				if( max) *max = val;
				if( min) *min = val;
				if( mean) *mean = val;
				if( total) *total = val;
			}
		}
		else
		{
			if( clip)
			{
				long newNo;
				
				pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
				CLIP_Polygon( pts, no, pTemp, &newNo, width, height);
				
				free( pts);
				pts = pTemp;
				
				no = newNo;
			}
			
			ras_FillPolygon( pts, no, fImage, width, height, [pixArray count], 0, 0, NO, 0, isRGB, YES, &imax, &imin, &count, &itotal, 0L, 0, 2, 0);
			
			if( max) *max = imax;
			if( min) *min = imin;
			if( total) *total = itotal;
			
			if( count != 0) imean = itotal / count;
			
			if( dev != 0L && count > 0)
			{
				idev = 0 ;
				
				ras_FillPolygon( pts, no, fImage, width, height, [pixArray count], 0, 0, NO, 0, isRGB, YES, 0L, 0L, 0L, 0L, &idev, imean, 2, 0);
				
				*dev = idev;
				*dev = *dev / (count-1);
				*dev = sqrt(*dev);
			}
			
			if( mean) *mean = imean;
		}
		
		free( pts);
	}
	
	if( *max == -99999) *max = 0;
	if( *min == 99999) *min = 0;
}

- (void) computeROI:(ROI*) roi :(float*) mean :(float *)total :(float *)dev :(float *)min :(float *)max
{
	if( (stackMode == 1 || stackMode == 2 || stackMode == 3) && stack >= 1)
	{
		long	i, countstack = 0;
		float	meanslice, totalslice, devslice, minslice, maxslice;
		
		[self computeROIInt: roi :mean :total :dev :min :max];
		countstack++;
			
		for( i = 1; i < stack; i++)
		{
			long next;
			if( stackDirection) next = pixPos-i;
			else next = pixPos+i;
		
			if( next < [pixArray count]  && next >= 0)
			{
				[[pixArray objectAtIndex: next] computeROIInt: roi :&meanslice :&totalslice :&devslice :&minslice :&maxslice];
				countstack++;
				
				if( mean) *mean += meanslice;
				if( dev) *dev += devslice;
				if( total) *total += totalslice;
				
				if( min) if(minslice < *min) *min = minslice;
				if( max) if(maxslice > *max) *max = maxslice;
			}
		}
		
		if( mean) *mean /= countstack;
		if( dev)
		{
			*dev /= countstack;
			
			float vv = fabs( (countstack-1) * sliceInterval);
			vv += sliceThickness;
			
			*dev /= sqrtf( vv / sliceThickness);
		}
		if( total) *total /= countstack;
	}
	else [self computeROIInt: roi :mean :total :dev :min :max];
}

-(short*) oImage
{
	#ifdef USEVIMAGE
	NSLog(@"NOT AVAILABLE USEVIMAGE");
	#endif
	
    [self CheckLoad];
    return oImage;
}

-(void) setfImage:(float*) ptr
{
	if( fVolImage == 0L)
	{
		if( fImage != 0L)
		{
			NSLog(@"free(fImage);");
			free(fImage);
			fImage = 0L;
		}
	}

	fImage = ptr;
	
	if( fVolImage) fVolImage = fImage;
}

-(float*) fImage
{
    [self CheckLoad];
    return fImage;
}

-(void) setPixelSpacingX :(float) s
{
	[self CheckLoad];
	pixelSpacingX = s;
}

-(void) setPixelSpacingY :(float) s
{
	[self CheckLoad];
	pixelSpacingY = s;
}

-(float) originX { [self CheckLoad]; return originX;}
-(float) originY { [self CheckLoad]; return originY;}
-(float) originZ { [self CheckLoad]; return originZ;}
-(void) setOrigin :(float*) o
{
	originX = o[ 0];	originY = o[ 1];	originZ = o[ 2];
}
-(float) pixelSpacingY { [self CheckLoad]; return pixelSpacingY;}
-(float) pixelSpacingX { [self CheckLoad]; return pixelSpacingX;}
-(float) pixelRatio { [self CheckLoad]; return pixelRatio;}
-(void) setPixelRatio:(float) r { pixelRatio = r;}
-(float) sliceLocation { [self CheckLoad]; return sliceLocation;}
-(void) setSliceLocation:(float) l { [self CheckLoad]; sliceLocation = l;}
-(float) sliceThickness { [self CheckLoad]; return sliceThickness;}
-(void) setSliceThickness:(float) l { [self CheckLoad]; sliceThickness = l;}
-(float) slope {[self CheckLoad]; return slope;}
-(float) offset{[self CheckLoad]; return offset;}
- (float) savedWL {[self CheckLoad]; return savedWL;}
- (float) savedWW {[self CheckLoad]; return savedWW;}
- (float) setSavedWL:(float) l {[self CheckLoad]; savedWL = l;}
- (float) setSavedWW:(float) w {[self CheckLoad]; savedWW = w;}


-(float) cineRate {[self CheckLoad]; return cineRate;}

-(float) fullwl
{
	if( fullww == 0 && fullwl == 0) [self computePixMinPixMax];
	return fullwl;
}
-(float) fullww
{
	if( fullww == 0 && fullwl == 0) [self computePixMinPixMax];
	return fullww;
}

-(id) myinitEmpty
{
	//NSLog(@"myInitEmpty");
	displaySUVValue = NO;
	fixed8bitsWLWW = NO;
	checking = [[NSLock alloc] init];
	convertedDICOM = 0L;
	subtractedfImage = 0L;
	units = 0L;
	decayFactor = 1.0;
	decayCorrection = 0L;
	repetitiontime = 0L;
	echotime = 0L;
	protocolName = 0L;
	viewPosition = 0L;
	patientPosition = 0L;
	maxValueOfSeries = 0;
	minValueOfSeries = 0;
	radiopharmaceuticalStartTime = 0L;
	acquisitionTime = 0L;
	radionuclideTotalDose = 0;
	radionuclideTotalDoseCorrected = 0;
	
	orientation[ 0] = 1;
	orientation[ 1] = 0;
	orientation[ 2] = 0;
	orientation[ 3] = 0;
	orientation[ 4] = 1;
	orientation[ 5] = 0;
	// Compute normal vector
	orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
	orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
	orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
	srcFile = 0L;
	generated = YES;
	
    return [super init];
}


-(void) setArrayPix :(NSArray*) array :(short) i
{
	pixArray = array;
	pixPos = i;
	
	if( [array objectAtIndex:i] != self)
	{
		NSLog(@"Beuh... Pix != Pix...");
	}
}

- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ :(BOOL) volSize
{
	//if( pixelSize != 32) NSLog( @"Only floating images are supported...");
	//NSLog(@"initwithdata");
	if( self = [super init])
    {
		acquisitionTime = 0L;
		radiopharmaceuticalStartTime = 0L;
		radionuclideTotalDose = 0;
		radionuclideTotalDoseCorrected = 0;
		maxValueOfSeries = 0;
		minValueOfSeries = 0;
		hasSUV = NO;
		SUVConverted = NO;
		generated = YES;
		fixed8bitsWLWW = NO;
		thickSlab = 0L;
		sliceInterval = 0;
		convertedDICOM = 0L;
		checking = [[NSLock alloc] init];
		stack = 2;
		stackMode = 0;
		updateToBeApplied = NO;
		image = 0L;
		oImage = 0L;
		fImage = 0L;
		fVolImage = 0L;
		baseAddr = 0L;
		imID = 0;
		imTot = 1;
		srcFile = 0L;
		frameNo = 0;
		serieNo = 0;
		isRGB = NO;
		nonDICOM = NO;
		fullwl = fullww = 0;
		thickSlabVRActivated = NO;
			
		repetitiontime = 0L;
		echotime = 0L;
		protocolName = 0L;
		viewPosition = 0L;
		patientPosition = 0L;
		
		units = 0L;
		decayCorrection = 0L;
		decayFactor = 1.0;
		
		offset = 0.0;
		slope  = 1.0;
		
		height = yDim;
		height /= 2;
		height *= 2;
		
		width = xDim;
		width /= 2;
		width *= 2;
		
		pixelSpacingX = xSpace;
		pixelSpacingY = ySpace;
		if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
		else pixelRatio = 1.0;
		
		if( volSize)
		{
			fVolImage = im;
			fImage = im;
		}
		else
		{
			switch( pixelSize)
			{
				case 7:		// ARGB
					isRGB = YES;
				case 32:	// FLOAT
					fImage = malloc(width*height*sizeof(float));
					long i;
					
					if( xDim != width)
					{
					//	NSLog(@"Allocate a new fImage");
						for( i =0; i < height; i++)
						{
							memcpy( fImage + i*width, im + i*xDim, width*sizeof(float));
						}
					}
					else memcpy( fImage, im, width*height*sizeof(float));
				break;
				
				case 8:		// RGBA -> argb
					rowBytes = width * 4;
					fImage = malloc(width*height*4);
				//	fImage = (float*) im;
					
					unsigned char *src = (unsigned char*) im, *dst = (unsigned char*) fImage;
					
				//	vec_rl
					
					for( i =0; i < height*width*4; i+= 4)
					{
						dst[ i] = src[ i+3];
						dst[ i+1] = src[ i];
						dst[ i+2] = src[ i+1];
						dst[ i+3] = src[ i+2];
					}
					
					isRGB = YES;
				break;
			}
		}
				
		originX = oX;
		originY = oY;
		originZ = oZ;
		
		ww = 0;
		wl = 0;
		
		sliceLocation = 0;
		sliceThickness = 0;
		
		long j;
		for (j = 0; j < 9; j++) orientation[ j] = 0;

    }
    return self;
}

- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ
{
	return [self initwithdata: im :pixelSize :xDim :yDim :xSpace :ySpace :oX :oY :oZ :NO];
}

-(long) frameNo { return frameNo;}
-(void) setFrameNo:(long) f
{
	frameNo = f;
}
-(long) serieNo { return serieNo;}
-(BOOL) generated { return generated;}


- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss isBonjour:(BOOL) hello imageObj: (NSManagedObject*) iO
{	
// doesn't load pix data, only initializes instance variables
	if( hello == NO)
		if( [[NSFileManager defaultManager] fileExistsAtPath:s] == NO) return 0L;
		
    if( self = [super init])
    {
		//-------------------------received parameters
		srcFile = s;
		imID = pos;
		imTot = tot;
		fVolImage = ptr;
		frameNo = f;
		serieNo = ss;
		isBonjour = hello;
		imageObj = [iO retain];

		//---------------------------------various
		maxValueOfSeries = 0;
		minValueOfSeries = 0;
		fixed8bitsWLWW = NO;
		savedWL = savedWW = 0;
		pixelRatio = 1.0;
		sliceInterval = 0;
		convertedDICOM = 0L;
		checking = [[NSLock alloc] init];
		stack = 2;
		stackMode = 0;
		updateToBeApplied = NO;
		image = 0L;
		oImage = 0L;
		fImage = 0L;
		baseAddr = 0L;
		isRGB = NO;
		nonDICOM = NO;
		fullwl = fullww = 0;
		repetitiontime = 0L;
		echotime = 0L;
		protocolName = 0L;
		viewPosition = 0L;
		patientPosition = 0L;

		//---------------------------------radiotherapy
		generated = NO;
		displaySUVValue = NO;
		acquisitionTime = 0L;
		radiopharmaceuticalStartTime = 0L;
		radionuclideTotalDose = 0;
		radionuclideTotalDoseCorrected = 0;
		
		//----------------------------------angio
		subPixOffset.x = subPixOffset.y = 0;
		subtractedfPercent = 1;
		subtractedfZero = 0.8;
		subGammaFunction = 0L;
		
		ang = 0;
		rot = 0;
		maskID = 1;
		maskTime = 0;
		fImageTime = 0;
				
		DCMPixShutterOnOff = NSOffState;
		shutterRect_x = 0;
		shutterRect_y = 0;
		shutterRect_w = 0;
		shutterRect_h = 0;
// to be improved with init using Philips corresponding tags value

/*		//Shutter Shape (0018,1600) RECTANGULAR
		subShutterLeftVerticalEdge; //(0018,1602)
		subShutterRightVerticalEdge; //(0018,1604)
		subShutterUpperHorizontalEdge; //(0018,1606)
		subShutterLowerHorizontalEdge; //(0018,1608)
		subPrivateCreatorGroup;//(0019,0010) type of configuration (always(?): CARDIO-D.R. 1.0)
		subImageBlankingShape;//(0019,1000) CIRCULAR, RECTANGULAR
		subImageBlankingLeftVerticalEdge;//(0019,1002)
		subImageBlankingRightVerticalEdge;//(0019,1004)
		subImageBlankingUpperHorizontalEdge;//(0019,1006)
		subImageBlankingLowerHorizontalEdge;//(0019,1008)
		subCenterOfCircularImageBlanking;//(0019,1010)
		subRadiusOfCircularImageBlanking;//(0019,1012)
*/
		//----------------------------------orientation		
		orientation[ 0] = 1;
		orientation[ 1] = 0;
		orientation[ 2] = 0;
		orientation[ 3] = 0;
		orientation[ 4] = 1;
		orientation[ 5] = 0;
		// Compute normal vector
		orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
		orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
		orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];

		[srcFile retain];
    }
    return self;
}

- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss
{
	return [self myinit: s :pos :tot :ptr :f :ss isBonjour:NO imageObj: 0L];
}

- (void) copyFromOther:(DCMPix *) fromDcm
{
    long	i;
	
	self->imageObj = fromDcm->imageObj;
	self->isBonjour = fromDcm->isBonjour;
//	self->fImage = fromDcm->fImage;	// Don't load the image!
	self->height = fromDcm->height;
	self->width = fromDcm->width;
	self->rowBytes = fromDcm->rowBytes;
	self->wl = fromDcm->wl;
	self->ww = fromDcm->ww;
	self->sliceInterval = fromDcm->sliceInterval;
	self->pixelSpacingX = fromDcm->pixelSpacingX;
	self->pixelSpacingY = fromDcm->pixelSpacingY;
	self->sliceLocation = fromDcm->sliceLocation;
	self->sliceThickness = fromDcm->sliceThickness;
	self->pixelRatio = fromDcm->pixelRatio;
	self->originX  = fromDcm->originX;
	self->originY = fromDcm->originY;
	self->originZ = fromDcm->originZ;
	for( i = 0; i < 9; i++) self->orientation[ i] = fromDcm->orientation[ i];
	self->isRGB = fromDcm->isRGB;
	self->cineRate = fromDcm->cineRate;
	self->savedWL = fromDcm->savedWL;
	self->savedWW = fromDcm->savedWW;
	
	self->echotime = [fromDcm->echotime retain];
	self->repetitiontime = [fromDcm->repetitiontime retain];
	self->protocolName = [fromDcm->protocolName retain];
	self->convertedDICOM = [fromDcm->convertedDICOM retain];
	self->viewPosition = [fromDcm->viewPosition retain];
	self->patientPosition = [fromDcm->patientPosition retain];
	
	self->units = [fromDcm->units retain];
	self->decayCorrection = [fromDcm->decayCorrection retain];
	self->radionuclideTotalDose = fromDcm->radionuclideTotalDose;
	self->radionuclideTotalDoseCorrected = fromDcm->radionuclideTotalDoseCorrected;
	self->acquisitionTime = [fromDcm->acquisitionTime retain];
	self->radiopharmaceuticalStartTime = [fromDcm->radiopharmaceuticalStartTime retain];
	self->displaySUVValue = fromDcm->displaySUVValue;
	self->decayFactor = fromDcm->decayFactor;
	self->halflife = fromDcm->halflife;
	self->philipsFactor = fromDcm->philipsFactor;
	self->generated = YES;
	
	self->minValueOfSeries = fromDcm->minValueOfSeries;
	self->maxValueOfSeries = fromDcm->maxValueOfSeries;

}

- (id) copyWithZone:(NSZone *)zone
{
    long	i;
	
	DCMPix *copy = [[[self class] allocWithZone: zone] myinit:self->srcFile :self->imID :self->imTot :self->fVolImage :self->frameNo :self->serieNo];
	
	copy->imageObj = self->imageObj;
	copy->isBonjour = self->isBonjour;
	copy->fImage = self->fImage;	// Don't load the image!
	copy->height = self->height;
	copy->width = self->width;
	copy->rowBytes = self->rowBytes;
	copy->wl = self->wl;
	copy->ww = self->ww;
	copy->sliceInterval = self->sliceInterval;
	copy->pixelSpacingX = self->pixelSpacingX;
	copy->pixelSpacingY = self->pixelSpacingY;
	copy->sliceLocation = self->sliceLocation;
	copy->sliceThickness = self->sliceThickness;
	copy->pixelRatio = self->pixelRatio;
	copy->originX  = self->originX;
	copy->originY = self->originY;
	copy->originZ = self->originZ;
	for( i = 0; i < 9; i++) copy->orientation[ i] = self->orientation[ i];
	copy->isRGB = self->isRGB;
	copy->cineRate = self->cineRate;
	copy->savedWL = self->savedWL;
	copy->savedWW = self->savedWW;
	
	copy->echotime = [self->echotime retain];
	copy->repetitiontime = [self->repetitiontime retain];
	copy->protocolName = [self->protocolName retain];
	copy->convertedDICOM = [self->convertedDICOM retain];
	copy->viewPosition = [self->viewPosition retain];
	copy->patientPosition = [self->patientPosition retain];
	
	copy->units = [self->units retain];
	copy->decayCorrection = [self->decayCorrection retain];
	copy->radionuclideTotalDose = self->radionuclideTotalDose;
	copy->radionuclideTotalDoseCorrected = self->radionuclideTotalDoseCorrected;
	copy->acquisitionTime = [self->acquisitionTime retain];
	copy->radiopharmaceuticalStartTime = [self->radiopharmaceuticalStartTime retain];
	copy->displaySUVValue = self->displaySUVValue;
	copy->decayFactor = self->decayFactor;
	copy->halflife = self->halflife;
	copy->philipsFactor = self->philipsFactor;
	
	copy->generated = YES;

	copy->maxValueOfSeries = self->maxValueOfSeries;
	copy->minValueOfSeries = self->minValueOfSeries;

    return copy;
}

-(void) setRGB : (BOOL) val
{
	isRGB = val;
}

-(BOOL) isRGB
{
	return isRGB;
}

- (NSString*) repetitiontime {return repetitiontime;}
- (NSString*) echotime {return echotime;}
- (void) setRepetitiontime:(NSString*)rep {repetitiontime = rep;}
- (void) setEchotime:(NSString*)echo {echotime = echo;}
- (NSString*) protocolName {return protocolName;}
- (NSString*) viewPosition {return viewPosition;}
- (NSString*) patientPosition {return patientPosition;}

- (char*) UncompressDICOM : (NSString*) file :( long) imageNb
{
	PapyShort		fileNb, err;
	char			*data = 0L;
	SElement		*theGroupP;
	
	NSString *outputfile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/%@", filenameWithDate( file)];
	if ([[NSFileManager defaultManager] fileExistsAtPath:outputfile] == NO) convertedDICOM = [convertDICOM( file) retain];
	else convertedDICOM = [outputfile retain];
	
	[PapyrusLock lock];
	
	fileNb = Papy3FileOpen ( (char*) [convertedDICOM UTF8String], (PAPY_FILE) 0, TRUE, 0);
	if (fileNb >= 0)
	{
		[convertedDICOM retain];
		
		err = Papy3GotoNumber (fileNb, (PapyShort)imageNb, DataSetID);
		
		// then goto group 0x7FE0 
		if ((err = Papy3GotoGroupNb (fileNb, 0x7FE0)) == 0)
		{
			// read group 0x7FE0 from the file 
			if ((err = Papy3GroupRead (fileNb, &theGroupP)) > 0) 
			{
				// PIXEL DATA 
				data = (char*)Papy3GetPixelData (fileNb, imageNb, theGroupP, ImagePixel);
				
				err = Papy3GroupFree (&theGroupP, TRUE);
				
			}
		}
		
		// close and free the file and the associated allocated memory 
		Papy3FileClose (fileNb, TRUE);
	}
	else convertedDICOM = 0L;
	
	[PapyrusLock unlock];
	
	return data;
}


-(void) setSliceInterval :(float) s
{
	[self CheckLoad];
	sliceInterval = s;
}

-(float) sliceInterval {    [self CheckLoad];   return sliceInterval;}

#include "BioradHeader.h"

-(void) LoadBioradPic
{
	FILE		*fp = fopen( [srcFile UTF8String], "r");
	long		i, realwidth, realheight;
	
	//NSLog(@"Handling Biorad PIC File in CheckLoad");
	if( fp)
	{
		long					totSize, maxImage;
		struct BioradHeader 	header;
		NSData					*fileData;
		
		fread(&header, BIORAD_HEADER_LENGTH, 1, fp);
		
		// Note that Biorad files are in little endian format
		realheight = NSSwapLittleShortToHost(header.ny);
		height = realheight/2;
		height *= 2;
		realwidth = NSSwapLittleShortToHost(header.nx);
		width =realwidth/ 2;
		width *= 2;
		
		maxImage = NSSwapLittleShortToHost(header.npic);

		int bytesPerPixel=1;
		// if 8bit, byte_format==1 otherwise 16bit
		if (NSSwapLittleShortToHost(header.byte_format)!=1)
		{
			bytesPerPixel=2;
		}
			
		totSize = realheight * realwidth * 2;
		oImage = malloc( totSize);
		
		if( NSSwapLittleShortToHost(header.byte_format) != 1)  // 16 bit
		{  // GJ: Fetch the data from an offset given by header + frame *bytes per frame

			fseek(fp, BIORAD_HEADER_LENGTH +frameNo*(realheight * realwidth * 2), SEEK_SET);
			
			fread( oImage, realheight * realwidth * 2, 1, fp);
			
			i = realheight * realwidth;
			while( i-- > 0)
			{
				oImage[ i] = NSSwapLittleShortToHost( oImage[ i]);
			}
		}
		else {  // 8 bit image
			unsigned char   *bufPtr;
			short			*ptr, *tmpImage;
			long			loop;
			//NSLog(@"Reading 8 bit PIC file");
			// GJ: Fetch the data from an offset given by header + frame *bytes per frame
			
			fseek(fp, BIORAD_HEADER_LENGTH +frameNo*(realheight * realwidth), SEEK_SET);
			
			bufPtr = malloc( realheight * realwidth);
			fread( bufPtr, realheight * realwidth, 1, fp);
			
			ptr    = oImage;
			
			loop = totSize/2;
			while( loop-- > 0)
			{
				*ptr++ = *bufPtr++;
			}
		}
		
		if( width != realwidth)
		{
			for( i = 0; i < height;i++)
			{
				memmove( oImage + i*width, oImage + i*realwidth, width*2);
			}
		}
		
		// FIND THICKNESS AND PIXEL SIZE
		// NSLog(@"Entering Biorad PIC File footer");

		// GJ: This isn't strictly necessary and some files don't have this flag set.
		//if( header.notesAvailable || 1) {
		
			long numBytes = realheight*realwidth*maxImage*bytesPerPixel;
			
			fseek(fp, BIORAD_HEADER_LENGTH + numBytes, SEEK_SET);
			
			// iterate over Biorad Notes
			struct BioradNote bnote;
			long curPos=0;
			float POS, STEP;
			
		NSRange charRange = {32,127-32+1};
		NSCharacterSet *goodSet = [NSCharacterSet characterSetWithRange:charRange];
		NSScanner *noteCleaner,*noteParser;
		NSString *aLine = @"";
		double zCorrection=1.0;
		
		// Iterate ovet the file's footer
		while( feof(fp) == 0)
		{
			fread( &bnote, BIORAD_NOTE_LENGTH, 1, fp);
			
			NSString *noteText=[NSString stringWithCString:bnote.noteText length:BIORAD_NOTE_TEXT_LENGTH ];
			//NSLog(@"noteText %@",noteText);

			//Remove any illegal characters
			noteCleaner = [NSScanner scannerWithString:noteText];
			if([noteCleaner scanCharactersFromSet:goodSet intoString:&aLine])
			{
				//NSLog(@"aLine %@",aLine);
				
				// now try and see if we can find any indication of axis information
				if([aLine rangeOfString:@"AXIS_"].location!=NSNotFound)
				{
					NSString	*axisNumberString, *pixelSpacingString;

					// The number of the axis (2,3,4 = X,Y,Z)
					axisNumberString = [aLine substringWithRange:NSMakeRange(5,1)];
					// The pixel size is:  - field 3 (0 indexed)
					NSArray *listItems = [aLine componentsSeparatedByString:@" "];
					if([listItems count]>=5){
						pixelSpacingString=[listItems objectAtIndex:3];
					}else{
						pixelSpacingString=@"";
					}

					switch( [axisNumberString intValue])
					{
						case 2: pixelSpacingX = [pixelSpacingString floatValue];  		break;
						case 3: pixelSpacingY = [pixelSpacingString floatValue];  		break;
						case 4: sliceInterval = sliceThickness = [pixelSpacingString floatValue];
								sliceLocation = frameNo * sliceInterval;		break;
					}
				} else{
					//check if this line contains z correction information
					//Z_CORRECT_FACTOR = 0.950000 -2.821782
					if([aLine rangeOfString:@"Z_CORRECT_FACTOR"].location!=NSNotFound){
						NSArray *listItems = [aLine componentsSeparatedByString:@" "];
						NSString	*subStringVal;
						if([listItems count]>=3){
							subStringVal=[listItems objectAtIndex:2];
							zCorrection=[subStringVal floatValue];
							NSLog(@"Set zCorrection factor = %f",zCorrection);
						}else{
							NSLog(@"LoadBioradPic: Error setting zCorrection factor - insufficient fields");
						}
					}

				}
			}
			curPos+=BIORAD_NOTE_LENGTH;
		}
		// GJ: implement Z correction for air/oil/sample refractive index mismatch
		//NSLog(@"zCorrection factor = %f",zCorrection);
		//NSLog(@"sliceInterval factor = %f, sliceThickness = %f",sliceInterval,sliceThickness);
		sliceInterval/=zCorrection; sliceThickness/=zCorrection;
		sliceLocation = frameNo * sliceInterval;
		//NSLog(@"After Z correction: sliceInterval factor = %f, sliceThickness = %f",sliceInterval,sliceThickness);
		
		// END OF READING FOOTER
		
		// CONVERSION TO FLOAT
		
		vImage_Buffer src16, dstf;

		dstf.height = src16.height = height;
		dstf.width = src16.width = width;
		src16.rowBytes = width*2;
		dstf.rowBytes = width*sizeof(float);
		
		src16.data = oImage;
		
		if( fVolImage)
		{
			fImage = fVolImage;
		}
		else
		{
			fImage = malloc(width*height*sizeof(float) + 100);
		}
		
		dstf.data = fImage;
		
		vImageConvert_16SToF( &src16, &dstf, 0, 1, 0);
		
		free(oImage);
		oImage = 0L;
		
		fclose( fp);
		
		savedWL = wl = 127;
		savedWW = ww = 256;
	}
}

-(void) LoadTiff:(long) directory
{
	unsigned char   *argbImage, *tmpPtr, *srcPtr, *srcImage;
	long			i, x, y, totSize;
	int				realwidth;
	long			w, h, row;
	short			bpp, count, tifspp;
	short			cur_page, number_of_pages, dataType = 0;
	
	isRGB = NO;
	
	TIFF* tif = TIFFOpen([srcFile UTF8String], "r");
	if( tif)
	{
		count = 0;
		while (count < directory && TIFFReadDirectory (tif))
			count++;
		/*
		if( frameNo != 0)
		{
			count = 0;
			do
			{
				TIFFReadDirectory (tif);
			   count++;
			} while (!TIFFLastDirectory (tif) && count != frameNo);
		}*/
		
	//	NSLog(@"dir:%d", count);
		
		TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
		TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);
		TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bpp);
		TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &tifspp);
		TIFFGetField(tif, TIFFTAG_DATATYPE, &dataType);
		
		NSLog( @"Bits Per Sample: %d, Samples Per Pixel: %d", bpp, tifspp);
		
		height = h;
		height /= 2;
		height *= 2;
		realwidth = w;
		width = realwidth/2;
		width *= 2;
		
		totSize = (height+1) * (width+1);
		
		
		if( tifspp == 3)	// RGB
		{
			isRGB = YES;
			totSize *= 4;
		}
		else totSize *= 2;
		
		oImage = malloc( totSize);
		
		if( bpp == 16)
		{
			if( tifspp == 3)	// RGB
			{
				unsigned short *buf = _TIFFmalloc(TIFFScanlineSize(tif));
				unsigned char  *dst, *aImage = (unsigned char*) oImage;
				long scanline = TIFFScanlineSize(tif);
				
				for (row = 0; row < h; row++)
				{
					TIFFReadScanline(tif, buf, row, 0);
					
					dst = aImage + (row*(scanline/6) * 4);
					for( i = 0; i < scanline/6; i++)
					{
						dst[ i*4 + 0] = 0;
						dst[ i*4 + 1] = buf[ i*3 + 0] / 256;
						dst[ i*4 + 2] = buf[ i*3 + 1] / 256;
						dst[ i*4 + 3] = buf[ i*3 + 2] / 256;
					}
				}
				
				_TIFFfree(buf);
			}
			else
			{
				for (row = 0; row < h; row++)
				{
					TIFFReadScanline(tif, oImage + (row*TIFFScanlineSize(tif))/2, row, 0);
				}
			}
		}
		else if( bpp == 8)
		{
			if( tifspp == 3)	// RGB
			{
				unsigned char *buf = _TIFFmalloc( TIFFScanlineSize(tif));
				unsigned char  *dst, *aImage = (unsigned char*) oImage;
				long scanline = TIFFScanlineSize(tif);
				
				for (row = 0; row < h; row++)
				{
					TIFFReadScanline(tif, buf, row, 0);
					
					
					dst = aImage + (row*(scanline/3) * 4);
					for( i = 0; i < scanline/3; i++)
					{
						dst[ i*4 + 0] = 0;	//buf[ i*3 + 0];
						dst[ i*4 + 1] = buf[ i*3 + 0];
						dst[ i*4 + 2] = buf[ i*3 + 1];
						dst[ i*4 + 3] = buf[ i*3 + 2];
					}
				}
				
				_TIFFfree(buf);
			}
			else if( tifspp == 1)
			{
				unsigned char *buf = _TIFFmalloc(TIFFScanlineSize(tif));
				short  *dst;
				long scanline = TIFFScanlineSize(tif);
				
				for (row = 0; row < h; row++)
				{
					TIFFReadScanline(tif, buf, row, 0);
					
					dst = oImage + (row*scanline);
					for( i = 0; i < scanline; i++)
					{
						dst[ i] = buf[ i];
					}
				}
				
				_TIFFfree(buf);
			}
		}
		else if( bpp == 32)
		{
			unsigned short  fmt;
			float			*buf, max=-99999, min=99999, diff;
			short			*dst;
			
			TIFFGetField(tif, TIFFTAG_SAMPLEFORMAT, &fmt);
			
			if( fmt == SAMPLEFORMAT_IEEEFP)
			{
				buf = _TIFFmalloc(TIFFScanlineSize(tif));
				
				// FIND MIN AND MAX
				for (row = 0; row < h; row++)
				{
					i = TIFFReadScanline(tif, buf, row, 0);
					if( i!= 1) NSLog(@"ERROR");
					
					for( i = 0; i < TIFFScanlineSize(tif)/4; i++)
					{
						if( buf[ i] < min) min = buf[ i];
						if( buf[ i] > max) max = buf[ i];
					}
				}
				
				diff = max - min;
				
				for (row = 0; row < h; row++)
				{
					i = TIFFReadScanline(tif, buf, row, 0);
					if( i!= 1) NSLog(@"ERROR");
					
					dst = oImage + (row*TIFFScanlineSize(tif))/4;
					for( i = 0; i < TIFFScanlineSize(tif)/4; i++)
					{
						dst[ i] = ((buf[ i] - min) * 16000.f) / diff;
					}
				}
			}
			_TIFFfree(buf);
		}
		
		if( realwidth != width)
		{
			if( isRGB == NO)	// 16 bits
			{
				for( i = 0; i < height;i++)
				{
					memmove( oImage + i*width, oImage + i*realwidth, width*2);
				}
			}
			else				// 32 bits
			{
				for( i = 0; i < height;i++)
				{
					memmove( oImage + i*width*2, oImage + i*realwidth*2, width*4);
				}
			}
		}
		
		if( isRGB == NO)
		{
			// CONVERSION TO FLOAT
			
			vImage_Buffer src16, dstf;
	
			dstf.height = src16.height = height;
			dstf.width = src16.width = width;
			src16.rowBytes = width*2;
			dstf.rowBytes = width*sizeof(float);
			
			src16.data = oImage;
			
			if( fVolImage)
			{
				fImage = fVolImage;
			}
			else
			{
				fImage = malloc(width*height*sizeof(float) + 100);
			}
			
			dstf.data = fImage;
			
			switch( dataType)
			{
				case TIFF_SSHORT:
				case TIFF_SLONG:
					vImageConvert_16SToF( &src16, &dstf, 0, 1, 0);
				break;
				
				default:
					vImageConvert_16UToF( &src16, &dstf, 0, 1, 0);
				break;
			}
		}
		else
		{
			if( fVolImage)
			{
				fImage = fVolImage;
			}
			else
			{
				fImage = malloc(width*height*sizeof(float) + 100);
			}
			
			memcpy( fImage, oImage, width*height*4);
			
			rowBytes = width * 4;
		}
		
		free(oImage);
		oImage = 0L;
		
		TIFFClose(tif);
	}
	else NSLog( @"ERROR TIFF UNKNOWN");
}

-(void) LoadFVTiff
{	
	int success = 0, i;
	short head_size = 0;
	char* head_data = 0;
	int NoOfFrames = 1, NoOfSeries = 1;
	TIFF* tif = TIFFOpen([srcFile UTF8String], "r");
	if(tif)
		success = TIFFGetField(tif, TIFFTAG_FV_MMHEADER, &head_size, &head_data);
	if (success)
	{
		FV_MM_HEAD mm_head;
		
		FV_Read_MM_HEAD(head_data, &mm_head);
		for(i = 0; i < FV_SPATIAL_DIMENSION; i++)
		{
			if (*(mm_head.DimInfo[i].Name) == 'Z')
				NoOfFrames = mm_head.DimInfo[i].Size;
			else if (*(mm_head.DimInfo[i].Name) != 'X' && *(mm_head.DimInfo[i].Name) != 'Y')
				NoOfSeries *= mm_head.DimInfo[i].Size;
		}
		TIFFClose(tif);
		tif = 0;
		int directory = (NoOfFrames*serieNo)+frameNo;
		[self LoadTiff:directory];
		
		// Fill in image dimensions info
		for(i = 0; i < FV_SPATIAL_DIMENSION; i++)
		{
			if (*(mm_head.DimInfo[i].Name) == 'X')
			{
				originX = mm_head.DimInfo[i].Origin / 1000.0;
				pixelSpacingX = mm_head.DimInfo[i].Resolution / 1000.0;
			}
			else if (*(mm_head.DimInfo[i].Name) == 'Y')
			{
				originY = mm_head.DimInfo[i].Origin / 1000.0;
				pixelSpacingY = mm_head.DimInfo[i].Resolution / 1000.0;
			}
			else if (*(mm_head.DimInfo[i].Name) == 'Z')
			{
				originZ = (mm_head.DimInfo[i].Origin + (mm_head.DimInfo[i].Resolution * frameNo)) / 1000.0;
				sliceThickness = sliceInterval = mm_head.DimInfo[i].Resolution / 1000.0;
			}
		}
		sliceLocation = originZ;
		if( pixelSpacingY != 0.0 && pixelSpacingX != 0.0)
			pixelRatio = pixelSpacingY / pixelSpacingX;
	}
	if(tif) TIFFClose(tif);

}


-(void) LoadLSM
{
	// This function has been modified twice by Greg Jefferis on 9 June 2004
	// early am and late pm respectively.  After the second iteration it has been 
	// tested on new and old style 16 and 8 bit LSM tiff files.  Comments?
	FILE	*fp = fopen( [srcFile UTF8String], "r");
	long	i,it = 0;
	long	nextoff = 0;
	int		counter = 0;
	long	pos = 8, k;
	short   shortval;
	int		lsmDebug=0;  // Flag to determine if debugging messages are printed
	
	long	realwidth, realheight;

	long	TIF_NEWSUBFILETYPE = 0; // GJ: flag indicating whether image is "real" or thumbnail 
	long	LENGTH2, TIF_STRIPOFFSETS; // GJ: Number of channels & offset containing file offset to image data
	long	TIF_CZ_LSMINFO, TIF_COMPRESSION; // GJ: Offset of additional data about image
	/* No longer required as of 040609 pm with simplified reader
	long	LENGTH1, TIF_BITSPERSAMPLE_CHANNEL1, TIF_BITSPERSAMPLE_CHANNEL2, TIF_BITSPERSAMPLE_CHANNEL3;
	long	TIF_COMPRESSION, TIF_PHOTOMETRICINTERPRETATION, TIF_STRIPOFFSETS, TIF_SAMPLESPERPIXEL, TIF_STRIPBYTECOUNTS;
	long	TIF_STRIPOFFSETS1, TIF_STRIPOFFSETS2, TIF_STRIPOFFSETS3;
	long	TIF_STRIPBYTECOUNTS1, TIF_STRIPBYTECOUNTS2, TIF_STRIPBYTECOUNTS3;
	long	TIF_STRIPOFFSETS_ARRAY[3];
	*/
	// GJ: this will store the location of the data for this frame
	long	imageDataOffsetForThisFrame;
	int		goodFramesChecked=0;
	int		timeSeries = 0;
	
	// do / while loop which iterates over each image in the directory
	// there will be as many directory entries as there are slices
	// Some of the directory entries will be thumbnails - we will ignore those
	// When we have reached the frame we want (ie frameNo) break out of the loop
	
	
	
	do
	{   
		// 0) Move to the right place
		fseek(fp, pos, SEEK_SET); // GJ: 040609 this fseek should have been pos not 8
		fread(&shortval, 2, 1, fp);
		it = EndianU16_LtoN( shortval);
	
		// 1) Parse the tags at this location
		if(lsmDebug) NSLog(@"Parsing tags in first do/while loop: there are %d tags to parse",it);  //GJ:
		TIF_NEWSUBFILETYPE=-1;
		for( k=0 ; k<it ; k++)
		{
			// read raw tag data
			unsigned char   tags2[ 12];
			fseek(fp, pos+2+12*k, SEEK_SET);
			fread( &tags2, 12, 1, fp);
			
			int TAGTYPE = 0;
			long LENGTH = 0;
			int MASK = 0x00ff;
			long MASK2 = 0x000000ff;
			
			TAGTYPE = ((tags2[1] & MASK) << 8) | ((tags2[0] & MASK ) <<0);
			LENGTH = ((tags2[7] & MASK2) << 24) | ((tags2[6] & MASK2) << 16) | ((tags2[5] & MASK2) << 8) | (tags2[4] & MASK2);
			if(lsmDebug) NSLog(@"FirstTagRound: Analysing tag %d of type %d and length %d",k,TAGTYPE,LENGTH);  //GJ: for reporting
			switch (TAGTYPE)
			{
				case 254:
					// GJ figure out whether this is a thumbnail (!0) or a real image (0)
					TIF_NEWSUBFILETYPE = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
					if(lsmDebug) NSLog(@"LoadLSM: TIF_NEWSUBFILETYPE= %d",TIF_NEWSUBFILETYPE);
					break;
				case 273: 
					//GJ: number of image channels (some of which can be empty)
					LENGTH2 = ((tags2[7] & MASK2) << 24) | ((tags2[6] & MASK2) << 16) | ((tags2[5] & MASK2) << 8) | (tags2[4] & MASK2);
					// Offset of the place where STRIPOFFSETS are recorded
					TIF_STRIPOFFSETS = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
					break;
				//case 279:  
					// the file offset 
					// at which the size of the individual images for each slice are stored
					// (up to 3 numbers in bytes)
				//	TIF_STRIPBYTECOUNTS = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
				//	break;
//				case 34412:
//					TIF_CZ_LSMINFO = ((tags2[11] & MASK2) << 24) | ((tags2[10] & MASK2) << 16) | ((tags2[9] & MASK2) << 8) | (tags2[8] & MASK2);
//				default:
					break;
			}
			// We don't need to process all the tags if this is a thumbnail
			if(TIF_NEWSUBFILETYPE>0) continue;
				
		}  // End of parsing tags at this location
		
//		if( TIF_CZ_LSMINFO)
//		{
//			fseek(fp, TIF_CZ_LSMINFO + 8, SEEK_SET);
//			
//			long	DIMENSION_X, DIMENSION_Y, DIMENSION_Z, NUMBER_OF_CHANNELS, TIMESTACKSIZE, DATATYPE, DATATYPE2;
//			short   SCANTYPE, SPECTRALSCAN;
//			double   VOXELSIZE_X, VOXELSIZE_Y, VOXELSIZE_Z;
//			
//			fread( &DIMENSION_X, 4, 1, fp);		DIMENSION_X = EndianU32_LtoN( DIMENSION_X);
//			fread( &DIMENSION_Y, 4, 1, fp);		DIMENSION_Y = EndianU32_LtoN( DIMENSION_Y);
//			fread( &DIMENSION_Z, 4, 1, fp);		DIMENSION_Z = EndianU32_LtoN( DIMENSION_Z);
//			
//			fread( &NUMBER_OF_CHANNELS, 4, 1, fp);		NUMBER_OF_CHANNELS = EndianU32_LtoN( NUMBER_OF_CHANNELS);
//			//GJ: 
//			//NSLog(@"LoadLSM: Number of Channels %d",NUMBER_OF_CHANNELS);
//			fread( &TIMESTACKSIZE, 4, 1, fp);			TIMESTACKSIZE = EndianU32_LtoN( TIMESTACKSIZE);
//			
//			fread( &DATATYPE, 4, 1, fp);			DATATYPE = EndianU32_LtoN( DATATYPE);
//			
//			fseek(fp, TIF_CZ_LSMINFO + 88, SEEK_SET);
//			fread( &SCANTYPE, 2, 1, fp);			SCANTYPE = EndianU16_LtoN( SCANTYPE);
//
//			switch (SCANTYPE)
//			{
//				case 6:
//				{
//					int group = serieNo / LENGTH2;
//					
//					frameNo = frameNo + group * DIMENSION_Z;
//					
//					serieNo = serieNo - group;
//				}
//				break;
//			}
//		}
		
		// 2) See if this was the frame that we wanted 
		// and if it was store the relevant imageDataOffsetForThisFrame
		if(TIF_NEWSUBFILETYPE==0){
			// This directory entry was a main image
			// Is it also the entry for the image we are looking for?
			if(goodFramesChecked++ == frameNo){
				// yes, so record the imageDataOffsetForThisFrame
				if(LENGTH2==1){
					// for a single channel image it is just TIF_STRIPOFFSETS
					imageDataOffsetForThisFrame = TIF_STRIPOFFSETS;
				}else{
					// if this is a multi channel image, check that serieNo has a sensible value
					if(LENGTH2>1 && serieNo>=LENGTH2){ 
						NSLog(@"LoadLSM: zero indexed serieNo (%d) is greater than number of channels (%d)",serieNo,LENGTH2);
						return;
					}
					// ok serieNo is sensible use the TIF_STRIPOFFSETS to move to the right place
					fseek(fp, TIF_STRIPOFFSETS, SEEK_SET);
					for (i=0; i<=serieNo;i++){
						// read serieNo+1 times to get the offset of the relevant channel's data
						fread(&imageDataOffsetForThisFrame,4,1,fp);
						imageDataOffsetForThisFrame=EndianU32_LtoN(imageDataOffsetForThisFrame);
					}
				}
				// break out of the do/while loop since we have found the image we want
				if(lsmDebug)  NSLog(@"Found frame number %d - breaking out of first loop",frameNo);
				break;
			}
			if(lsmDebug) NSLog(@"goodFramesChecked = %d",goodFramesChecked);
		}
		
		// 3) If not ... move to location containing the offset of the next image directory 
		fseek(fp, (int)pos + 2 + 12 * (int)it, SEEK_SET);
		fread( &nextoff, 4, 1, fp);
		pos = EndianU32_LtoN( nextoff);
		if(lsmDebug)NSLog(@"new pos = %d",pos);
		counter++;
		
	} while (pos!=0); //while (nextoff!=0);
	
	//GJ: OK this next loop is going to parse the first image in the directory in detail
	// we assume this will contain a real image (rather than a thumbnail)
	/* Searches for the number of tags in the first image directory */

	long iterator1;
	fseek(fp, 8, SEEK_SET);
	fread(&shortval, 2, 1, fp);
	iterator1 = EndianU16_LtoN( shortval);
	//NSLog(@"iterator1 = %d",iterator1);
	// Analyses each tag found 
	for ( k=0 ; k<iterator1 ; k++)
	{
		unsigned char   TAG1[ 12];
		fseek(fp, 10+12*k, SEEK_SET);
		fread( &TAG1, 12, 1, fp);
		
		{
			int TAGTYPE = 0;
			long LENGTH = 0;
			int MASK = 0x00ff;
			long MASK2 = 0x000000ff;
			
			
			TAGTYPE = ((TAG1[1] & MASK) << 8) | ((TAG1[0] & MASK ) <<0);
			LENGTH = ((TAG1[7] & MASK2) << 24) | ((TAG1[6] & MASK2) << 16) | ((TAG1[5] & MASK2) << 8) | (TAG1[4] & MASK2);

			//NSLog(@"Analysing tag %d of type %d and length %d",k,TAGTYPE,LENGTH);  //GJ: for reporting
			
			switch (TAGTYPE)
			{
				case 254:
					TIF_NEWSUBFILETYPE = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
					// GJ: this is condition which cannot be handled by the present version of LoadLSM
					if(TIF_NEWSUBFILETYPE!=0){
						NSLog(@"LoadLSM unable to handle files in which the first image directory entry is a thumbnail");
						// give up on trying to read this file and exit method!
						return;
					}
					break;
				case 256:
					realwidth = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
					width =realwidth/ 2; width *= 2;
					break;
				case 257:
					realheight = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
					height = realheight/2; height *= 2;
					break;
				// GJ: don't need to parse these tags as things are wriiten now
				/*
				case 258:
					LENGTH1 = ((TAG1[7] & MASK2) << 24) | ((TAG1[6] & MASK2) << 16) | ((TAG1[5] & MASK2) << 8) | (TAG1[4] & MASK2);
					TIF_BITSPERSAMPLE_CHANNEL1 = ((TAG1[8] & MASK2) << 0);
					TIF_BITSPERSAMPLE_CHANNEL2 = ((TAG1[9] & MASK2) << 0);
					TIF_BITSPERSAMPLE_CHANNEL3 = ((TAG1[10] & MASK2) << 0);
					break;*/
				case 259:
					TIF_COMPRESSION = ((TAG1[8] & MASK2) << 0);
					NSLog( @"COMPRESSION: %d", TIF_COMPRESSION);
					break;
			/*	case 262:
					TIF_PHOTOMETRICINTERPRETATION = ((TAG1[8] & MASK2) << 0);
					break;
				case 273:
					LENGTH2 = ((TAG1[7] & MASK2) << 24) | ((TAG1[6] & MASK2) << 16) | ((TAG1[5] & MASK2) << 8) | (TAG1[4] & MASK2);
					TIF_STRIPOFFSETS = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
					//NSLog(@"LoadLSM:TIF_STRIPOFFSETS = %d; LENGTH2 = %d",TIF_STRIPOFFSETS,LENGTH2);
					break;
				case 277:
					TIF_SAMPLESPERPIXEL = ((TAG1[8] & MASK2) << 0);
					break;
				case 279:
					TIF_STRIPBYTECOUNTS = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
					break; */
				case 34412:
					TIF_CZ_LSMINFO = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
					//NSLog(@"LoadLSM: TIF_CZ_LSMINFO = %d",TIF_CZ_LSMINFO);
					break;
				default:
					break;
			}
		}
	} // end for loop parsing info of first frame
	
	
	if( TIF_CZ_LSMINFO)
	{
		fseek(fp, TIF_CZ_LSMINFO + 8, SEEK_SET);
		
		long	DIMENSION_X, DIMENSION_Y, DIMENSION_Z, NUMBER_OF_CHANNELS, TIMESTACKSIZE, DATATYPE, DATATYPE2;
		short   SCANTYPE, SPECTRALSCAN;
		double   VOXELSIZE_X, VOXELSIZE_Y, VOXELSIZE_Z;
		
		fread( &DIMENSION_X, 4, 1, fp);		DIMENSION_X = EndianU32_LtoN( DIMENSION_X);
		fread( &DIMENSION_Y, 4, 1, fp);		DIMENSION_Y = EndianU32_LtoN( DIMENSION_Y);
		fread( &DIMENSION_Z, 4, 1, fp);		DIMENSION_Z = EndianU32_LtoN( DIMENSION_Z);
		
		fread( &NUMBER_OF_CHANNELS, 4, 1, fp);		NUMBER_OF_CHANNELS = EndianU32_LtoN( NUMBER_OF_CHANNELS);
		//GJ: 
		//NSLog(@"LoadLSM: Number of Channels %d",NUMBER_OF_CHANNELS);
		fread( &TIMESTACKSIZE, 4, 1, fp);			TIMESTACKSIZE = EndianU32_LtoN( TIMESTACKSIZE);
		
		fread( &DATATYPE, 4, 1, fp);			DATATYPE = EndianU32_LtoN( DATATYPE);
		
		fseek(fp, TIF_CZ_LSMINFO + 88, SEEK_SET);
		fread( &SCANTYPE, 2, 1, fp);			SCANTYPE = EndianU16_LtoN( SCANTYPE);

//		switch (SCANTYPE) {
//			case 3:
//				NoOfFrames = TIMESTACKSIZE;
//				break;
//			case 4:
//				NoOfFrames = TIMESTACKSIZE;
//				break;
//			case 6:
//				NoOfFrames = TIMESTACKSIZE * DIMENSION_Z;
//				break;
//			default:
//				NoOfFrames = DIMENSION_Z;
//				break;
//		}
		
		if( fVolImage) fImage = fVolImage;
		else fImage = malloc(width*height*sizeof(float) + 100);
		
		long numPixels=height * width;
		
		// GJ: Move to correct location for image data
		fseek(fp, imageDataOffsetForThisFrame, SEEK_SET);
		// Then read data according to datatype
		switch( DATATYPE)
		{
			default:
			case 1:		// 8 bit image data					
				oImage = malloc( numPixels * 2);
				unsigned char   *eightBitData;
				eightBitData = malloc(numPixels);
				/* 040609 GJ: rationalised this 
				if( LENGTH2 == 1)  // Single channel image
				{
					fseek(fp, TIF_STRIPOFFSETS + frameNo * ((numPixels* NUMBER_OF_CHANNELS) +thumbnailDataSize), SEEK_SET);
					fread( eightBitData, numPixels, 1 ,fp);
				} else {
					// multi channel image
					fseek(fp, TIF_STRIPOFFSETS_ARRAY[serieNo] + frameNo * ((numPixels* NUMBER_OF_CHANNELS) +thumbnailDataSize), SEEK_SET);
					fread( eightBitData, numPixels, 1 ,fp);
				}
				 */
				fseek(fp, imageDataOffsetForThisFrame, SEEK_SET);
				fread( eightBitData, numPixels, 1 ,fp);
				
				// Test
				//NSData  *outData = [NSData dataWithBytes: eightBitData+4 length : numPixels];
				//[outData writeToFile:@"out" atomically:YES];
				
				// Now copy the pixels from the temporary 8 bit array 
				// to the 16 bit "oImage"
				i = numPixels;
				while( i-- > 0) oImage[i] = eightBitData[ i];
				free( eightBitData);
			break;
			
			case 2: 
				// GJ: 040608 added code to handle 16 bit data including multi channels
				oImage = malloc(numPixels*2);
				
				/* 
				// GJ: Move to correct location for image data
				if( LENGTH2 == 1)
				{  // Single channel image
					fseek(fp, TIF_STRIPOFFSETS + frameNo * ((numPixels*2* NUMBER_OF_CHANNELS) +thumbnailDataSize) , SEEK_SET);
				} else {
					// Multi channel image nb serieNo has already been bounds checked
					fseek(fp, TIF_STRIPOFFSETS_ARRAY[serieNo] + frameNo * ((numPixels*2* NUMBER_OF_CHANNELS) +thumbnailDataSize), SEEK_SET);
				}
				 */
				//GJ: read image data
				fread( oImage, numPixels*2, 1 ,fp);
				
				// GJ added conversion of Little/Big endian format
				i = numPixels;
				while( i-- > 0) oImage[i]=NSSwapLittleShortToHost( oImage[ i]);
			break;
			
			case 5:		// float - GJ: I have no test images for this format
				oImage = 0L;
				/*
				if( LENGTH2 == 1) fseek(fp, TIF_STRIPOFFSETS + height * width * ((frameNo * NUMBER_OF_CHANNELS)) * 4, SEEK_SET);
				else fseek(fp, TIF_STRIPOFFSETS1 + height * width * ((frameNo * NUMBER_OF_CHANNELS)), SEEK_SET);
				*/
				// GJ: LSM float data is 32 bit according to LSM_Reader.java
				fread( fImage, numPixels * 4, 1 ,fp);
				i = numPixels;
				while( i-- > 0) ConvertFloatToNative( &fImage[i]);
			break;
		}
		
		if( oImage)
		{
			// CONVERSION TO FLOAT
			
			vImage_Buffer src16, dstf;

			dstf.height = src16.height = height;
			dstf.width = src16.width = width;
			src16.rowBytes = width*2;
			dstf.rowBytes = width*sizeof(float);
			
			src16.data = oImage;
			dstf.data = fImage;
			
			vImageConvert_16SToF( &src16, &dstf, 0, 1, 0);
			
			free(oImage);
		}
		oImage = 0L;
		
		fseek(fp, TIF_CZ_LSMINFO + 40, SEEK_SET);
		fread( &VOXELSIZE_X, 8, 1, fp);
		ConvertDoubleToNative( &VOXELSIZE_X);
		pixelSpacingX = VOXELSIZE_X*1000;
		
		fseek(fp, TIF_CZ_LSMINFO + 48, SEEK_SET);
		fread( &VOXELSIZE_Y, 8, 1, fp);
		ConvertDoubleToNative( &VOXELSIZE_Y);
		pixelSpacingY = VOXELSIZE_Y*1000;
		
		fseek(fp, TIF_CZ_LSMINFO + 56, SEEK_SET);
		fread( &VOXELSIZE_Z, 8, 1, fp);
		ConvertDoubleToNative( &VOXELSIZE_Z);
		sliceInterval = sliceThickness = VOXELSIZE_Z*1000;
		sliceLocation = frameNo * sliceInterval;
		
		savedWL = wl = 127;
		savedWW = ww = 255;
//		

//			stream.seek((int)position + 108);
//			OFFSET_CHANNELSCOLORS = swap(stream.readInt());
//			
//			stream.seek((int)position + 120);
//			OFFSET_CHANNELDATATYPES = swap(stream.readInt());
//			
//			stream.seek((int)position+124);
//			OFFSET_SCANINFO = swap(stream.readInt());
//			
//			stream.seek((int)position+132);
//			OFFSET_TIMESTAMPS = swap(stream.readInt());
//			
//			stream.seek((int)position+204);
//			OFFSET_CHANNELWAVELENGTH = swap(stream.readInt());
	}

	
	fclose( fp);
}

- (void) computeTotalDoseCorrected
{
	// WARNING : only time is correct. NOT year/month/day
	float timebetween = -[radiopharmaceuticalStartTime timeIntervalSinceDate: acquisitionTime];
	if( halflife > 0 && timebetween > 0) radionuclideTotalDoseCorrected = radionuclideTotalDose * exp( -timebetween * logf(2)/halflife);
	else NSLog(@"ERROR IN computeTotalDoseCorrected");
}

- (void) checkSUV
{
	hasSUV = NO;
	
	if ( ![[self units] isEqualToString: @"BQML"] && ![[self units] isEqualToString: @"CNTS"] ) return;  // Must be BQ/cc
	
	if( [[self units] isEqualToString: @"CNTS"] && philipsFactor == 0.0) return;
	
	if ( [self decayCorrection] == nil ) return;
	
	if( decayFactor == 0L) return;
	
	if ( [[self decayCorrection] isEqualToString: @"START"] == NO ) return;
	
	if ( [self radionuclideTotalDose] <= 0.0 ) return;	

	if( halflife <= 0) return;
	
	if( acquisitionTime == 0L || radiopharmaceuticalStartTime == 0L) return;
	
//	if ( [curDCM patientsWeight] <= 0.0 ) return;		// <- This can be manually filled later
	
	hasSUV = YES;
}

- (void)createROIsFromRTSTRUCT: (DCMObject*)dcmObject {

	// First determine if this RTSTRUCT has already been converted in this session.
	// Dunno if this is the best way to do this.  Still have to worry about re-creating
	// ROIs between sessions.  My concerns that this is a temp solution are why the statics
	// are handled below rather than at the class level.

	extern NSThread *mainThread;
	
	//ThreadID threadID;
	
	//OSErr err = GetCurrentThread( &threadID );
	
	if( mainThread != [NSThread currentThread] ) return;
	
	NSLog( @"loadDICOMDCMFramework for RTSTRUCT" );

	static bool first = YES;
	static NSMutableSet *rtstructUIDs;
	
	if ( first ) {
		rtstructUIDs = [[NSMutableSet set] retain];
		first = NO;
	}
	
	NSString *rtstructUID = [dcmObject attributeValueWithName: @"SOPInstanceUID"];
	
	if ( [rtstructUIDs containsObject: rtstructUID] ) return;
	
	[rtstructUIDs addObject: rtstructUID];

	int choice = NSRunAlertPanel( NSLocalizedString( @"Create ROIs?", nil ),
								  NSLocalizedString( @"Would you like to create a set of ROIs from this RTSTRUCT?", nil ),
								  NSLocalizedString( @"Cancel", nil ),
								  NSLocalizedString( @"OK", nil ), nil );

	if ( choice == NSAlertDefaultReturn ) return;
	
	NSString *dirPath = [documentsDirectory() stringByAppendingString:@"/ROIs/"];

	
	// Get all referenced images up front.
	// This is better than running a Fetch Request for EVERY ROI since
	// executeFetchRequest is expensive.

	DCMSequenceAttribute *refFrameSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"ReferencedFrameofReferenceSequence"];

	if ( refFrameSequence == nil ) {
		NSLog( @"ReferencedFrameofReferenceSequence not found" );
		return;
	}

	NSMutableArray *refImgUIDPredicates = [NSMutableArray arrayWithCapacity: 0];
	
	NSString *refSeriesUID = nil;
	NSEnumerator *refFrameEnum = [[refFrameSequence sequence] objectEnumerator];
	DCMObject *refFrameSeqItem;

	while ( refFrameSeqItem = [refFrameEnum nextObject] ) {
		DCMSequenceAttribute *refStudySeq = (DCMSequenceAttribute *)[refFrameSeqItem attributeWithName: @"RTReferencedStudySequence"];
		NSEnumerator *refStudyEnum = [[refStudySeq sequence] objectEnumerator];
		DCMObject *refStudySeqItem;
		
		while ( refStudySeqItem = [refStudyEnum nextObject] ) {
			DCMSequenceAttribute *refSeriesSeq = (DCMSequenceAttribute *)[refStudySeqItem attributeWithName: @"RTReferencedSeriesSequence"];
			NSEnumerator *refSeriesEnum = [[refSeriesSeq sequence] objectEnumerator];
			DCMObject *refSeriesSeqItem;
			
			while ( refSeriesSeqItem = [refSeriesEnum nextObject] ) {
				DCMSequenceAttribute *contourImgSeq = (DCMSequenceAttribute *)[refSeriesSeqItem attributeWithName: @"ContourImageSequence"];
				NSEnumerator *contourImgSeqEnum = [[contourImgSeq sequence] objectEnumerator];
				DCMObject *contourImgSeqItem;
				
				while ( contourImgSeqItem = [contourImgSeqEnum nextObject] ) {
					NSString *refImgUID = [contourImgSeqItem attributeValueWithName: @"ReferencedSOPInstanceUID"];
					NSPredicate *pred = [NSPredicate predicateWithFormat: @"sopInstanceUID like %@", refImgUID];
					[refImgUIDPredicates addObject: pred];
				}
			}
		}
	}
	
	if ( [refImgUIDPredicates count] == 0 ) {
		NSLog( @"No reference images found." );
		return;
	}
	
	//NSString *refStudyUID = [dcmObject attributeValueWithName: @"StudyInstanceUID"];
	
	NSManagedObjectContext *moc = [[BrowserController currentBrowser] managedObjectContext];
	NSError *error = nil;
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity: [NSEntityDescription entityForName: @"Image" inManagedObjectContext: moc]];
	
	//[request setPredicate: [NSPredicate predicateWithFormat: @"series.study.studyInstanceUID like%@", refStudyUID]];

	[request setPredicate: [NSCompoundPredicate orPredicateWithSubpredicates: refImgUIDPredicates]];

	[moc lock];
	NSArray *imgObjects = [moc executeFetchRequest: request error: &error];
	[moc unlock];
	
	if ( [imgObjects count] == 0 ) {
		NSLog( @"No images in Series" );
		return;
	}
	
	// Put all images in a dictionary for quick lookup based on SOP Instance UID
	
	NSMutableDictionary *imgDict = [NSMutableDictionary dictionaryWithCapacity: [imgObjects count]];
	NSMutableArray *dcmImgObjects = [NSMutableArray arrayWithCapacity: [imgObjects count]];
	
	int i;
	for ( i = 0; i < [imgObjects count]; i++ ) {
		DicomImage *imgObj = [imgObjects objectAtIndex: i];
		[imgDict setObject: imgObj forKey: [imgObj valueForKey: @"sopInstanceUID"]];
		[dcmImgObjects addObject: [DCMObject objectWithContentsOfFile: [imgObj completePath] decodingPixelData: NO]];
	}
	
	DCMSequenceAttribute *roiSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"StructureSetROISequence"];
	
	if ( roiSequence == nil ) {
		NSLog( @"StructureSetROISequence not found" );
		return;
	}
	
	NSEnumerator *enumerator = [[roiSequence sequence] objectEnumerator];
	DCMObject *sequenceItem;
	NSMutableDictionary *roiNames = [NSMutableDictionary dictionary];
	
	while ( sequenceItem = [enumerator nextObject] ) {
		[roiNames setValue: [sequenceItem attributeValueWithName: @"ROIName"]
					forKey: [sequenceItem attributeValueWithName: @"ROINumber"]];
	}
	
	DCMSequenceAttribute *roiContourSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"ROIContourSequence"];
	
	if ( roiContourSequence == nil ) {
		NSLog( @"ROIContourSequence not found" );
		return;
	}
	
	enumerator = [[roiContourSequence sequence] objectEnumerator];
	
	while ( sequenceItem = [enumerator nextObject] ) {
		NSArray *rgbArray = [sequenceItem attributeArrayWithName: @"ROIDisplayColor"];
		
		RGBColor color = {
			[[rgbArray objectAtIndex: 0] floatValue] * 65535 / 256.0,
			[[rgbArray objectAtIndex: 1] floatValue] * 65535 / 256.0,
			[[rgbArray objectAtIndex: 2] floatValue] * 65535 / 256.0 };
		
		NSString *roiName = [roiNames valueForKey: [sequenceItem attributeValueWithName: @"ReferencedROINumber"]];
		
		NSLog( @"roiName = %@", roiName );
		DCMSequenceAttribute *contourSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"ContourSequence"];
		if ( roiContourSequence == nil ) {
			NSLog( @"contourSequence not found" );
			return;
		}
		
		DCMObject *contourItem;
		
		NSEnumerator *contourEnum = [[contourSequence sequence] objectEnumerator];
		while ( contourItem = [contourEnum nextObject] ) {
			
			DCMSequenceAttribute *contourImageSequence = (DCMSequenceAttribute*)[contourItem attributeWithName: @"ContourImageSequence"];
			if ( contourImageSequence == nil ) {
				NSLog( @"contourImageSequence not found" );
				return;
			}
		
			
			NSString *contourType = [contourItem attributeValueWithName: @"ContourGeometricType"];
			
			if ( ! [contourType isEqualToString: @"CLOSED_PLANAR"] ) {
				NSLog( @"Contour type %@ is not support at this time.", contourType );
				return;
			}
			
			int type = tCPolygon;
			
			NSString *refImgUID = nil;
			DicomImage *img = nil;
			
			NSArray *dcmPoints = [contourItem attributeArrayWithName: @"ContourData"];
			
			float
				sliceCoords[ 3 ];

			int numPoints = [[contourItem attributeValueWithName: @"NumberofContourPoints"] intValue];
			NSMutableArray *pointsArray = [NSMutableArray arrayWithCapacity: numPoints];

			float posX, posY, posZ;
			
			int pointIndex;
		
			for ( pointIndex = 0; pointIndex < numPoints; pointIndex++ ) {
				
				int imgIndex;
				
				for ( imgIndex = 0; imgIndex < [imgObjects count]; imgIndex++ ) {
					img = [imgObjects objectAtIndex: imgIndex];
					
					DCMObject *imgObject = [dcmImgObjects objectAtIndex: imgIndex];
					
					if ( imgObject == nil ) {
						NSLog( @"Error opening referenced image file" );
						return;
					}
					
					NSArray *pixelSpacings = [imgObject attributeArrayWithName: @"PixelSpacing"];
					NSArray *position = [imgObject attributeArrayWithName: @"ImagePositionPatient"];
					
					posX = [[position objectAtIndex: 0] floatValue];
					posY = [[position objectAtIndex: 1] floatValue];
					posZ = [[position objectAtIndex: 2] floatValue];
					
					pixelSpacingX = [[pixelSpacings objectAtIndex: 0] floatValue];
					pixelSpacingY = [[pixelSpacings objectAtIndex: 1] floatValue];
					
					// Convert ROI points from DICOM space to ROI space
					
					NSArray *imageOrientation = [imgObject attributeArrayWithName: @"ImageOrientationPatient"];
					float
						orients[ 9 ],
						temp[ 3 ];
					
					for ( i = 0; i < 6; i++ ) {
						orients[ i ] = [[imageOrientation objectAtIndex: i] floatValue];
					}
					
					// Normal vector
					orients[6] = orients[1]*orients[5] - orients[2]*orients[4];
					orients[7] = orients[2]*orients[3] - orients[0]*orients[5];
					orients[8] = orients[0]*orients[4] - orients[1]*orients[3];
					
					
					temp[ 0 ] = [[dcmPoints objectAtIndex: 3 * pointIndex] floatValue] - posX;
					temp[ 1 ] = [[dcmPoints objectAtIndex: 3 * pointIndex + 1] floatValue] - posY;
					temp[ 2 ] = [[dcmPoints objectAtIndex: 3 * pointIndex + 2] floatValue] - posZ;
					sliceCoords[ 2 ] = temp[ 0 ] * orients[ 6 ] + temp[ 1 ] * orients[ 7 ] + temp[ 2 ] * orients[ 8 ];
					
					if ( fabs( sliceCoords[ 2 ] ) < 1.5 /*mm*/ ) {  // Nearest slice?  Need a better way to find closest w/o hardcoding a 'nearness'.
						sliceCoords[ 0 ] = temp[ 0 ] * orients[ 0 ] + temp[ 1 ] * orients[ 1 ] + temp[ 2 ] * orients[ 2 ];
						sliceCoords[ 1 ] = temp[ 0 ] * orients[ 3 ] + temp[ 1 ] * orients[ 4 ] + temp[ 2 ] * orients[ 5 ];
						sliceCoords[ 0 ] /= pixelSpacingX;
						sliceCoords[ 1 ] /= pixelSpacingY;
						
						
						break;
					}
					
					//NSLog( @"( %f, %f, %f )", sliceCoords[ 0 ], sliceCoords[ 1 ], sliceCoords[ 2 ] );
				} // Loop over images in series (looking for nearest slice)
				
				[pointsArray addObject: [MyPoint point:NSMakePoint( sliceCoords[ 0 ], sliceCoords[ 1 ] )]];
				
				// Of course with this logic, only the LAST nearest slice is considered to be the ROI slice.
				// Future update, Need to take care of possibility ROI crosses more than one slice!
				
				refImgUID = [img valueForKey: @"sopInstanceUID"];
				
			} // Loop over all points in ROI
			

			//ROI *roi = [[ROI alloc] init];  // Note: initWithType: is WAAAY too expensive.
			
			//[roi setType: type];
			//[roi setOriginAndSpacing: pixelSpacingX : pixelSpacingY : NSMakePoint( posX, posY )];
			
			ROI *roi = [[ROI alloc] initWithType: type
												: pixelSpacingX
												: pixelSpacingY
												: NSMakePoint( posX, posY )];
			
			[roi setName: roiName];
			[roi setColor: color];
			
			[roi setSopInstanceUID: refImgUID];
			[roi setPoints: pointsArray];
			
			// Save ROI to disk by reading in existing ROI list for slice and adding this new ROI.
			
			NSMutableString	*str = [NSMutableString stringWithString: [img valueForKey:@"uniqueFilename"]];
			
			[str replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, [str length])];

			NSString *roiPath = [dirPath stringByAppendingFormat: @"%@-%d", str, 0];
			NSMutableArray *roiArray = [NSUnarchiver unarchiveObjectWithFile: roiPath];
			
			if ( roiArray == nil ) roiArray = [NSMutableArray arrayWithCapacity: 1];
			
			[roiArray addObject: roi];
			[roi release];
			
			[NSArchiver archiveRootObject: roiArray toFile: roiPath];
			
		} // Loop over ContourSequence

	}  // Loop over ROIContourSequence
	
} // end createROIsFromRTSTRUCT

- (void) setVOILUT:(int) first number :(unsigned int) number depth :(unsigned int) depth table :(unsigned int *)table image:(unsigned short*) src isSigned:(BOOL) isSigned
{
	long			i;
	int				index;
	
	if( isSigned)
	{
		int *signedTable = (int*) table;
		int *signedSrc = (int*) src;
		
		i = width * height;
		while( i-- > 0 )
		{
			index = signedSrc[ i] - first;
			if( index <= 0) index = 0;
			if( index >= number) index = number -1;
			
			src[ i] = table[ index];
		}
	}
	else
	{
		i = width * height;
		while( i-- > 0 )
		{
			index = src[ i] - first;
			if( index <= 0) index = 0;
			if( index >= number) index = number -1;
			
			src[ i] = table[ index];
		}
	}
}

#pragma mark-

- (BOOL)loadXAPhilips
{		
	if( pixArray != 0L && frameNo > 0) return YES; //NSLog(@"loadDICOMDCMFramework - pixArray already exists, nothing to do");
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
	if ( dcmObject == nil ) {
		NSLog(@"loadDICOMDCMFramework - no DCMObject at srcFile address, nothing to do");
		[pool release];
		return NO;
	}
	
	int					j;
	int					elemType;
	short				maxFrame = 1;
	short				imageNb = frameNo;
	short				ee;
	
	NSString            *SOPClassUID = [dcmObject attributeValueWithName:@"SOPClassUID"];
	NSString			*MediaStorageSOPInstanceUID = [dcmObject attributeValueWithName:@"MediaStorageSOPInstanceUID"];

	isRGB = FALSE;
	//angio - Philips
	height = [[dcmObject attributeValueWithName:@"Rows"] intValue];
	width = [[dcmObject attributeValueWithName:@"Columns"] intValue];
	NSString *path;
	if((height == 1024) && (width == 1024))
		path = [[NSBundle mainBundle] pathForResource:@"diameter1140frame1024" ofType:@"pbm"];
	else
		path = [[NSBundle mainBundle] pathForResource:@"diameter570frame512" ofType:@"pbm"];

	NSData *PBMdata = [[NSFileManager defaultManager] contentsAtPath:path];
	fIsSigned = 0;
	bitsAllocated = 16;
	spp = 1;
	fPlanarConf = 0; //fPlanarConf = [[dcmObject attributeValueWithName:@"PlanarConfiguration"] intValue];
	slope = 1.0;
	savedWL = 512;
	savedWW = 1024;
	float rotation=[[dcmObject attributeValueWithName:@"PositionerPrimaryAngle"] floatValue]; //0018,1510
	float angle=[[dcmObject attributeValueWithName:@"PositionerSecondaryAngle"] floatValue]; //0018,1511
	//NSLog(@"rotation:%f",rotation);
	//NSLog(@"angle:%f",angle);
	
	maxFrame = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
	if( maxFrame == 0) maxFrame = 1; //monoframe image
	if( pixArray == 0L) maxFrame = 1; //icon for multiframe image

	if ([dcmObject attributeValueWithName:@"PixelData"])
	{	
		DCMPixelDataAttribute *pixelAttr = (DCMPixelDataAttribute *)[dcmObject attributeWithName:@"PixelData"];
		DCMPix	*imPix = 0L;
		float frameTimes[maxFrame];
		NSString *FrameTime = [dcmObject attributeValueWithName:@"FrameTime"];
		float interval;
		
		if (FrameTime)
		{
			//NSLog(@"FrameTime (0018,1063)");
			interval= [FrameTime floatValue]/1000;
			for( ee = 0; ee < maxFrame; ee++) frameTimes[ee]=interval * ee;
		}
		
		//DCMAttribute *frameTimeVector =[ values];	
		if ([dcmObject attributeWithName:@"FrameTimeVector"] != nil )
		{
			//NSLog(@"FrameTime (0018,1065)");
								
			float chronometer = 0;
			NSString *frameTimeVector =[[dcmObject attributeWithName:@"FrameTimeVector"] valuesAsString];
			NSArray *frameTimeVectors = [frameTimeVector componentsSeparatedByString:@","];
			frameTimes[0] = 0;
			for( ee = 1; ee < maxFrame; ee++)			
			{
				interval=[[[frameTimeVectors objectAtIndex:ee] substringFromIndex:2] floatValue]/1000;
				chronometer=chronometer + interval;
				frameTimes[ee]=chronometer;						
			}
		}
		
		
		// frame loop
		for( ee = 0; ee < maxFrame; ee++)			
		{
			NSAutoreleasePool	*subPool = [[NSAutoreleasePool alloc] init];
			if( maxFrame > 1)
			{
				//duplicates DCMPix (one imPix for each frame)
				imPix = [pixArray objectAtIndex: ee];
				[imPix copyFromOther: self];
			}
			else
			{
				imPix = self;
				ee = imageNb;
			}
			
			[[pixArray objectAtIndex: ee]fImageTime:frameTimes[ee]];
			[[pixArray objectAtIndex: ee]maskTime:frameTimes[1]];
			if (rotation) [[pixArray objectAtIndex: ee]rot:rotation];
			if (angle) [[pixArray objectAtIndex: ee]ang:angle];
			
			NSData *pixData = [pixelAttr decodeFrameAtIndex:ee];	//creation of a pointer to the frame
			oImage =  malloc([pixData length]);
			[pixData getBytes:oImage];								//transform data into buffer oImage		

			if(imPix->fVolImage) imPix->fImage = imPix->fVolImage;			//browserViewer (one image at a time)
			else imPix->fImage = malloc(width*height*sizeof(float) + 100);	//2Dviewer (all images in contiguous memory)
			float *fPointer = (imPix->fImage);
			
			//in PBM format after the return (byte 15 or byte 13 in our cases) each bit white=0 black=1

			short *oImagePointer;
			oImagePointer = oImage;
			
			unsigned char *eightAlphaBits, *eightAlphaBitsLast;
			if(height == 1024)
				{
				eightAlphaBits = [PBMdata bytes]+0x0F;
				eightAlphaBitsLast = [PBMdata bytes]+0x20010;
				}				
			else //height == 512
				{
				eightAlphaBits = [PBMdata bytes]+0x0D;
				eightAlphaBitsLast = [PBMdata bytes]+0x800E;
				}				
			while (eightAlphaBits++ < eightAlphaBitsLast)
			{
				switch( (*eightAlphaBits))
				{
					case 255:						
						*fPointer++=*oImagePointer++;
						*fPointer++=*oImagePointer++;
						*fPointer++=*oImagePointer++;
						*fPointer++=*oImagePointer++;
						*fPointer++=*oImagePointer++;
						*fPointer++=*oImagePointer++;
						*fPointer++=*oImagePointer++;
						*fPointer++=*oImagePointer++;
					break;
					
					case 0:
						fPointer+=8;
						oImagePointer+=8;
					break;
					
					default:							
						if (*eightAlphaBits & 0x80) *fPointer++=*oImagePointer++;
						else {*fPointer++ = 0 ; oImagePointer++;}
						if (*eightAlphaBits & 0x40) *fPointer++=*oImagePointer++;
						else {*fPointer++ = 0 ; oImagePointer++;}
						if (*eightAlphaBits & 0x20) *fPointer++=*oImagePointer++;
						else {*fPointer++= 0 ; oImagePointer++;}
						if (*eightAlphaBits & 0x10) *fPointer++=*oImagePointer++;
						else {*fPointer++= 0 ; oImagePointer++;}
						if (*eightAlphaBits & 0x08) *fPointer++=*oImagePointer++;
						else {*fPointer++= 0 ; oImagePointer++;}
						if (*eightAlphaBits & 0x04) *fPointer++=*oImagePointer++;
						else {*fPointer++= 0 ; oImagePointer++;}
						if (*eightAlphaBits & 0x02) *fPointer++=*oImagePointer++;
						else {*fPointer++= 0 ; oImagePointer++;}
						if (*eightAlphaBits & 0x01) *fPointer++=*oImagePointer++;
						else {*fPointer++= 0 ; oImagePointer++;}	
					break;						
				}
			}
			[subPool release];
			free(oImage);
			oImage = 0L;
		}//out of the loop
		
	}//out of if([dcmObject attributeValueWithName:@"PixelData"])
	[pool release];
	return YES;
}







- (BOOL)loadDICOMDCMFramework	// PLEASE, KEEP BOTH FUNCTIONS FOR TESTING PURPOSE. THANKS
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	//________________________exceptions___________________________________________________
	
	//if (DEBUG) NSLog(@"loadDICOMDCMFramework with file: %@", srcFile);	

	if( pixArray != 0L && frameNo > 0)
	{
		NSLog(@"loadDICOMDCMFramework - pixArray already exists, nothing to do");
		while( fImage == 0L) {};
		[pool release];
		return YES;
	}
	
				
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
	if ( dcmObject == nil ) {
		NSLog(@"loadDICOMDCMFramework - no DCMObject at srcFile address, nothing to do");
		[pool release];
		return NO;
	}

	
	NSString            *SOPClassUID = [dcmObject attributeValueWithName:@"SOPClassUID"];
//	NSString			*MediaStorageSOPInstanceUID = [dcmObject attributeValueWithName:@"MediaStorageSOPInstanceUID"];

// Sorry, but I cannot accept this kind of specific code in the 'standard' OsiriX version. Activate it on your side if needed
// This would generate too many bugs and produce different behavior for XA from other constructors.
// I don't want a 'constructor oriented' DICOM viewer

//	if ([SOPClassUID isEqualToString:[DCMAbstractSyntaxUID xrayAngiographicImageStorage]]  &&
//		[MediaStorageSOPInstanceUID hasPrefix:@"1.3.46.670589.7.5"]
//	   ) 
//		{
//			//NSLog(@"XA Philips");
//			[pool release];
//			return [self loadXAPhilips];
//		}
		
	//-----------------------common----------------------------------------------------------	
		
	
	int					j;
	
	int					elemType;
	int					realwidth, realheight;
	short				maxFrame = 1;
	short				imageNb = frameNo;
	short				ee;

//Color LUT
	BOOL				fSetClut = NO, fSetClut16 = NO;
	unsigned char		*clutRed = 0L, *clutGreen = 0L, *clutBlue = 0L;
	unsigned short		clutEntryR, clutEntryG, clutEntryB;
	unsigned short		clutDepthR, clutDepthG, clutDepthB;
	unsigned short		*shortRed, *shortGreen, *shortBlue;

	int					pixmin, pixmax;
		
	
	
#pragma mark *pdf
	if ([ SOPClassUID isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]]) {
		NSLog(@"have PDF");
		NSData *pdfData = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
		NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData:pdfData];	
		[rep setCurrentPage:frameNo];	
		NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
		[pdfImage addRepresentation:rep];
		[pdfImage setBackgroundColor: [NSColor whiteColor]];
		/*
		 NSSize	newSize = [pdfImage size];						
		 newSize.width *= 1.5;		// Increase PDF resolution to 72 * 1.5 DPI !
		 newSize.height *= 1.5;		// KEEP THIS VALUE IN SYNC WITH DICOMFILE.M
		 [pdfImage setScalesWhenResized:YES];
		 [pdfImage setSize: newSize];
		 */
		
		NSData *tiffData = [pdfImage TIFFRepresentation];
		//NSString *dest = [NSString stringWithFormat:@"%@/Desktop/pdf.tif", NSHomeDirectory()];
		
		NSBitmapImageRep	*TIFFRep = [NSBitmapImageRep imageRepWithData: tiffData];
		//NSLog(@"tiffRep: %@", [TIFFRep description]);
		
		height = [TIFFRep pixelsHigh];
		height /= 2;
		height *= 2;
		realwidth = [TIFFRep pixelsWide];
		width = realwidth/2;
		width *= 2;
		rowBytes = [TIFFRep bytesPerRow];
		oImage = 0L;
		unsigned char *srcImage = [TIFFRep bitmapData];
		
		unsigned char   *ptr, *tmpImage ;
		long			loop;
		unsigned char   *argbImage, *tmpPtr, *srcPtr;
		int x,y;
		
		argbImage = malloc( height * width * 4);
		isRGB = YES;
		
		//NSLog(@"height %d", height);
		//NSLog(@"width %d", width);
		switch( [TIFFRep bitsPerPixel])
		{
			case 8:
				NSLog(@"8 bit DICOM PDF");
				tmpPtr = argbImage;
				for( y = 0 ; y < height; y++)
				{
					srcPtr = srcImage + y*rowBytes;
					
					x = width;
					while( x-->0)
					{
						tmpPtr++;
						*tmpPtr++ = *srcPtr;
						*tmpPtr++ = *srcPtr;
						*tmpPtr++ = *srcPtr;
						srcPtr++;
					}
					isRGB = NO;
				}
					break;
				
			case 32:
				//already argb
				//argbImage = srcImage;				
				//NSLog(@"32 bits DICOM PDF");
				tmpPtr = argbImage;
				for( y = 0 ; y < height; y++)
				{
					srcPtr = srcImage + y*rowBytes;
					x = width;
					while( x-->0)
					{
						unsigned char r = *srcPtr++;
						unsigned char g = *srcPtr++;
						unsigned char b = *srcPtr++;
						unsigned char a = *srcPtr++;
						*tmpPtr++ = a;
						*tmpPtr++ = r;
						*tmpPtr++ = g;
						*tmpPtr++ = b;
						
						
					}			
				}
					NSLog(@"finished 32  bit");
				break;
				
			case 24:
				//NSLog(@"loadDICOMDCMFramework 24 bits");
				tmpPtr = argbImage;
				for( y = 0 ; y < height; y++)
				{
					srcPtr = srcImage + y*rowBytes;
					
					x = width;
					while( x-->0)
					{
						unsigned char r = *srcPtr++;
						unsigned char g = *srcPtr++;
						unsigned char b = *srcPtr++;
						unsigned char a = 1.0;
						*tmpPtr++ = a;
						*tmpPtr++ = r;
						*tmpPtr++ = g;
						*tmpPtr++ = b;
						
						
					}
				}
					break;
				
			case 48:
				NSLog(@"48 bits");
				tmpPtr = argbImage;
				for( y = 0 ; y < height; y++)
				{
					srcPtr = srcImage + y*rowBytes;
					
					x = width;
					while( x-->0)
					{
						tmpPtr++;
						*tmpPtr++ = *srcPtr;	srcPtr += 2;
						*tmpPtr++ = *srcPtr;	srcPtr += 2;
						*tmpPtr++ = *srcPtr;	srcPtr += 2;
					}
					
					//BlockMoveData( srcPtr, tmpPtr, width*4);
					//tmpPtr += width*4;
				}
					break;
				
			default:
				NSLog(@"Error - Unknow...");
				break;
		}

		fImage = (float*) argbImage;
		rowBytes = width * 4;
		
		//[pdfData writeToFile:@"/tmp/dcm.pdf" atomically:YES];
		//[[NSWorkspace sharedWorkspace] openFile:@"/tmp/dcm.pdf" withApplication:@"Preview"];
		
		[pool release];
		return YES;												 
	} // end encapsulatedPDF

//----------------------------------------------------------------------------------	

#pragma mark *pixel and image

	//orientation
	
	originX = 0;	originY = 0;	originZ = 0;
	NSArray *ipp = [dcmObject attributeArrayWithName:@"ImagePositionPatient"];
	if( ipp)
	{
		originX = [[ipp objectAtIndex:0] floatValue];
		originY = [[ipp objectAtIndex:1] floatValue];
		originZ = [[ipp objectAtIndex:2] floatValue];
	}
	
	orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0;
	orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
	NSArray *iop = [dcmObject attributeArrayWithName:@"ImageOrientationPatient"];
	if( iop)
	{
		for (j = 0 ; j < [iop count]; j++) 
			orientation[ j] = [[iop objectAtIndex:j] floatValue];
	}

	
	//PixelRepresentation
	
	fIsSigned = [[dcmObject attributeValueWithName:@"PixelRepresentation"] intValue];
	bitsAllocated = [[dcmObject attributeValueWithName:@"BitsAllocated"] intValue]; 
	spp = 1;
	if ([dcmObject attributeValueWithName:@"SamplesperPixel"]) spp = [[dcmObject attributeValueWithName:@"SamplesperPixel"] intValue];
	
	offset = 0.0;
	if ([dcmObject attributeValueWithName:@"RescaleIntercept"]) offset = [[dcmObject attributeValueWithName:@"RescaleIntercept"] floatValue];	
	slope = 1.0;
	if ([dcmObject attributeValueWithName:@"RescaleSlope"] ) slope = [[dcmObject attributeValueWithName:@"RescaleSlope"] floatValue]; 



	// image size
	
	//width = height = 0;	
	//NSString *rows = [dcmObject attributeValueWithName:@"Rows"];
	height = [[dcmObject attributeValueWithName:@"Rows"] intValue];
	realheight= height;
	height /= 2;
	height *= 2;

	//NSString *columns = [dcmObject attributeValueWithName:@"Columns"];
	width =  [[dcmObject attributeValueWithName:@"Columns"] intValue];
	realwidth = width;
	width = realwidth/2;
	width *= 2;
	
	
	
	//window level & width
	
	savedWL = 0;
	if ([dcmObject attributeValueWithName:@"WindowCenter"]) savedWL = (long)[[dcmObject attributeValueWithName:@"WindowCenter"] floatValue]; 
	savedWW = 0;
	if ([dcmObject attributeValueWithName:@"WindowWidth"]) savedWW =  (long) [[dcmObject attributeValueWithName:@"WindowWidth"] floatValue]; 
	//NSLog(@"ww: %d wl: %d", savedWW, savedWL);
	
	
	
	//planar configuration
	
	fPlanarConf = [[dcmObject attributeValueWithName:@"PlanarConfiguration"] intValue]; 
	
	pixmin = pixmax = 0;
	pixelSpacingX = 0;
	pixelSpacingY = 0;
	pixelRatio = 1.0;
	//pixel Spacing
	NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"PixelSpacing"];
	if([pixelSpacing count] >= 2)
	{
		pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
		pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
	}
	else if([pixelSpacing count] >= 1)
	{
		pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
		pixelSpacingX = [[pixelSpacing objectAtIndex:0] floatValue];
	}
	else
	{
		NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"ImagerPixelSpacing"];
		if([pixelSpacing count] >= 2)
		{
			pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
			pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
		}
		else if([pixelSpacing count] >= 1)
		{
			pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
			pixelSpacingX = [[pixelSpacing objectAtIndex:0] floatValue];
		}
	}
	
	
	
	//PixelAspectRatio
	NSArray *par = [dcmObject attributeArrayWithName:@"PixelAspectRatio"];
	if ([par count] >= 2)
	{
		float ratiox = 1, ratioy = 1;
		ratiox = [[par objectAtIndex:0] floatValue];
		ratioy = [[par objectAtIndex:1] floatValue];
		
		if( ratioy != 0)
		{
			pixelRatio = ratiox / ratioy;
		}
	}
	else if( pixelSpacingX != pixelSpacingY)
	{
		if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
	}
	
	
	
	//PhotoInterpret
	if ([[dcmObject attributeValueWithName:@"PhotometricInterpretation"] rangeOfString:@"PALETTE"].location != NSNotFound) {
		// palette conversions done by dcm Object
		isRGB = YES;			
	} // endif ...extraction of the color palette
	

#pragma mark *RTSTRUCT	
	//  Check for RTSTRUCT and create ROIs if needed	
//	if ( [SOPClassUID isEqualToString:[DCMAbstractSyntaxUID RTStructureSetStorage]] ) [self createROIsFromRTSTRUCT: dcmObject];

	// Image object dicom tags
	if( [dcmObject attributeValueWithName:@"PatientsWeight"])	patientsWeight = [[dcmObject attributeValueWithName:@"PatientsWeight"] floatValue];
	if( [dcmObject attributeValueWithName:@"SliceThickness"])	sliceThickness = [[dcmObject attributeValueWithName:@"SliceThickness"] floatValue];
	if( [dcmObject attributeValueWithName:@"RepetitionTime"])	repetitiontime = [[dcmObject attributeValueWithName:@"RepetitionTime"] retain];
	if( [dcmObject attributeValueWithName:@"EchoTime"])			echotime = [[dcmObject attributeValueWithName:@"EchoTime"] retain];	
	if( [dcmObject attributeValueWithName:@"ProtocolName"])		protocolName = [[dcmObject attributeValueWithName:@"ProtocolName"] retain];
	if( [dcmObject attributeValueWithName:@"ViewPosition"])		viewPosition = [[dcmObject attributeValueWithName:@"ViewPosition"] retain];
	if( [dcmObject attributeValueWithName:@"PatientPosition"])	patientPosition = [[dcmObject attributeValueWithName:@"PatientPosition"] retain];
	if( [dcmObject attributeValueWithName:@"CineRate"])			cineRate = [[dcmObject attributeValueWithName:@"CineRate"] floatValue]; 
	if (!cineRate)
	{
		if( [dcmObject attributeValueWithName:@"FrameTimeVector"])
			cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameTimeVector"] floatValue];
	}	

	
#pragma mark *MR/CT functional multiframe
	
	// Is it a new MR/CT multi-frame exam?
	DCMSequenceAttribute *sharedFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"SharedFunctionalGroupsSequence"];
	if (sharedFunctionalGroupsSequence){
		NSEnumerator *enumerator = [[sharedFunctionalGroupsSequence sequence] objectEnumerator];
		DCMObject *sequenceItem;
		while (sequenceItem = [enumerator nextObject]) {
			
			//get Image Orientation for sequence
			DCMSequenceAttribute *planeOrientationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PlaneOrientationSequence"];
			DCMObject *planeOrientationObject = [[planeOrientationSequence sequence] objectAtIndex:0];
			//ImageOrientationPatient
			
			NSArray *iop = [planeOrientationObject attributeArrayWithName:@"ImageOrientationPatient"];
			orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0;
			orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
			for (j = 0 ; j < [iop count]; j++) 
				orientation[ j] = [[iop objectAtIndex:j] floatValue];
			
			// pixelMeasureSequence	
			DCMSequenceAttribute *pixelMeasureSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelMeasuresSequence"];
			DCMObject *pixelMeasureObject = [[pixelMeasureSequence sequence] objectAtIndex:0];
			sliceThickness = [[pixelMeasureObject attributeValueWithName:@"SliceThickness"] floatValue];
			NSArray *pixelSpacing = [pixelMeasureObject attributeArrayWithName:@"PixelSpacing"];
			if ([pixelSpacing count] >= 2) {
				pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
				pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
			}
			
			
			DCMSequenceAttribute *pixelTransformationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelValueTransformationSequence"];
			DCMObject *pixelTransformationSequenceObject = [[pixelTransformationSequence sequence] objectAtIndex:0];
			//RescaleIntercept
			offset = [[pixelTransformationSequenceObject attributeValueWithName:@"RescaleIntercept"] floatValue]; 
			//Rescale Slope
			slope = [[pixelTransformationSequenceObject attributeValueWithName:@"RescaleSlope"] floatValue]; 
			//				if( slope != 0 && fabs( slope) < 0.01)
			//				{
			//					while( slope < 0.01)
			//					{
			//						slope *= 100.;
			//					}
			//				}
		}
	}


#pragma mark *per frame
	
	// ****** ****** ****** ************************************************************************
	// PER FRAME
	// ****** ****** ****** ************************************************************************
				
	//long frameCount = 0;
	DCMSequenceAttribute *perFrameFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"Per-frameFunctionalGroupsSequence"];
	
	//NSLog(@"perFrameFunctionalGroupsSequence: %@", [perFrameFunctionalGroupsSequence description]);
	if (perFrameFunctionalGroupsSequence){
		if ([[perFrameFunctionalGroupsSequence sequence] count] > imageNb && imageNb >= 0){
			DCMObject *sequenceItem = [[perFrameFunctionalGroupsSequence sequence] objectAtIndex:imageNb];
			if (sequenceItem){
				if ([sequenceItem attributeArrayWithName:@"ImagePositionPatient"]){
					NSArray *ipp = [sequenceItem attributeArrayWithName:@"ImagePositionPatient"];
					if ([ipp count] >= 3) {
						originX = [[ipp objectAtIndex:0] floatValue];
						originY = [[ipp objectAtIndex:1] floatValue];
						originZ = [[ipp objectAtIndex:2] floatValue];
					}
				}	
				if ([sequenceItem attributeArrayWithName:@"PixelSpacing"]){
					NSArray *pixelSpacing = [sequenceItem attributeArrayWithName:@"PixelSpacing"];
					if ([pixelSpacing count] >= 2) {
						pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
						pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
					}
				}
			}
			//NSLog(@"per frame origin x: %f y: %f z: %f", originX, originY, originZ);
			//NSLog(@"pixelspacing: x: %f y: %f", pixelSpacingX, pixelSpacingY);
		}
		else{
			NSLog(@"No Frame %d in preFrameFunctionalGroupsSequence/", imageNb);
		}
		
	}
	
#pragma mark *tag group 6000
	
	if( [dcmObject attributeValueForKey: @"6000,0010"] && [[dcmObject attributeValueForKey: @"6000,0010"] isKindOfClass: [NSNumber class]])
	{
		oRows = [[dcmObject attributeValueForKey: @"6000,0010"] intValue];
			
		if( [dcmObject attributeValueForKey: @"6000,0011"])
			oColumns = [[dcmObject attributeValueForKey: @"6000,0011"] intValue];
		
		if( [dcmObject attributeValueForKey: @"6000,0040"])
			oType = [[dcmObject attributeValueForKey: @"6000,0040"] characterAtIndex: 0];
		
		if( [dcmObject attributeValueForKey: @"6000,0050"])
		{
			oOrigin[ 0] = [[dcmObject attributeValueForKey: @"6000,0050"] intValue];
			oOrigin[ 1] = [[dcmObject attributeValueForKey: @"6000,0050"] intValue];
		}
		
		if( [dcmObject attributeValueForKey: @"6000,0100"])
			oBits = [[dcmObject attributeValueForKey: @"6000,0100"] intValue];
		
		if( [dcmObject attributeValueForKey: @"6000,0102"])
			oBitPosition = [[dcmObject attributeValueForKey: @"6000,0102"] intValue];
			
		NSData	*data = [dcmObject attributeValueForKey: @"6000,3000"];
		
		if (data && oBits == 1 && oRows == height && oColumns == width && oType == 'G' && oBitPosition == 0 && oOrigin[ 0] == 1 && oOrigin[ 1] == 1)
		{
			if( oData) free( oData);
			oData = malloc( oRows*oColumns);
			
			unsigned short *pixels = (unsigned short*) [data bytes];
			char			valBit [ 16];
			char			mask = 1;
			int				i, x;
			
			for ( i = 0; i < oColumns*oRows/16; i++)
			{
				unsigned short	octet = pixels[ i];
				
				for (x = 0; x < 16;x ++)
				{
					valBit[ x] = octet & mask ? 1 : 0;
					octet = octet >> 1;
					
					if( valBit[ x]) oData[ i*16 + x] = 0xFF;
					else oData[ i*16 + x] = 0;
				}
			}
		}
	}
	
#pragma mark *SUV	
	
	// Get values needed for SUV calcs:
	if( [dcmObject attributeValueWithName:@"PatientsWeight"]) patientsWeight = [[dcmObject attributeValueWithName:@"PatientsWeight"] floatValue];
	else patientsWeight = 0.0;
	
	[units release];
	units = [[dcmObject attributeValueWithName:@"Units"] retain];
	
	[decayCorrection release];
	decayCorrection = [[dcmObject attributeValueWithName:@"DecayCorrection"] retain];
	
	decayFactor = 1.0;	//1.0 / [[dcmObject attributeValueWithName:@"DecayFactor"] floatValue];	 NOT USED FOR NOW.....
	
	DCMSequenceAttribute *radiopharmaceuticalInformationSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"RadiopharmaceuticalInformationSequence"];
	if( radiopharmaceuticalInformationSequence && [[radiopharmaceuticalInformationSequence sequence] count] > 0)
	{
		DCMObject *radionuclideTotalDoseObject = [[radiopharmaceuticalInformationSequence sequence] objectAtIndex:0];
		radionuclideTotalDose = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideTotalDose"] floatValue];
		halflife = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideHalfLife"] floatValue];
		radiopharmaceuticalStartTime = [[NSCalendarDate	dateWithString: [[radionuclideTotalDoseObject attributeValueWithName:@"RadiopharmaceuticalStartTime"] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
		
		// WARNING : only time is correct. NOT year/month/day
		acquisitionTime = [[NSCalendarDate	dateWithString:[[dcmObject attributeValueWithName:@"AcquisitionTime"] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
		
		[self computeTotalDoseCorrected];
	}
	// Loop over sequence to find injected dose
	
	if( [dcmObject attributeValueForKey: @"7053,1000"])
	{
		philipsFactor = [[NSString stringWithUTF8String:[[dcmObject attributeValueForKey: @"7053,1000"] bytes]] floatValue];
		NSLog( @"philipsFactor = %f", philipsFactor);
	}
	
	// End SUV		
	
#pragma mark *compute normal vector				
	// Compute normal vector

	orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
	orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
	orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
	
	if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
	{
		sliceLocation = originX;
	}
	
	if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
	{
		sliceLocation = originY;
	}
	
	if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
	{
		sliceLocation = originZ;
	}	


#pragma mark READ PIXEL DATA		
	
	maxFrame = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
	if( maxFrame == 0) maxFrame = 1;
	if( pixArray == 0L) maxFrame = 1;
//pixelAttr contains the whole PixelData attribute of every frames. Hence needs to be before the loop
		if ([dcmObject attributeValueWithName:@"PixelData"]) {
			DCMPixelDataAttribute *pixelAttr = (DCMPixelDataAttribute *)[dcmObject attributeWithName:@"PixelData"];



//=====================================================================
	for( ee = 0; ee < maxFrame; ee++)
	{

#pragma mark *loading a frame		
		//duplicates DCMPix (one imPix for each frame)

		NSAutoreleasePool	*subPool = [[NSAutoreleasePool alloc] init];

		DCMPix	*imPix = 0L;
		
		if( maxFrame > 1)
		{
			imPix = [pixArray objectAtIndex: ee];
			[imPix copyFromOther: self]; // duplicates the class fields
		}
		else
		{
			imPix = self;
			ee = imageNb;
		}
		
//moved outside the loop (same *pixelAttr contains the data for all the frames)
//		if ([dcmObject attributeValueWithName:@"PixelData"]) {
//			DCMPixelDataAttribute *pixelAttr = (DCMPixelDataAttribute *)[dcmObject attributeWithName:@"PixelData"];

		
		//get PixelData
			NSData *pixData = [pixelAttr decodeFrameAtIndex:ee];
			oImage =  malloc([pixData length]);	//pointer to a memory zone where each pixel of the data has a short value reserved
			[pixData getBytes:oImage];
			//NSLog(@"image size: %d", ( height * width * 2));
			//NSLog(@"Data size: %d", [pixData length]);
//		}
		
		
		
		if( oImage == 0L) //there was no data for this frame
			//create empty image
		{
			NSLog(@"This is really bad..... Please send this file to rossetantoine@bluewin.ch");
			//NSLog(@"image size: %d", ( height * width * 2));
			oImage = malloc( height * width * 2);
			//gArrPhotoInterpret [fileNb] = MONOCHROME2;
			int i = 0;
			long yo = 0;
			for( i = 0 ; i < height * width; i++)
			{
				oImage[ i] = yo++;
				if( yo>= width) yo = 0;
			}
		}
		
		//-----------------------frame data already loaded in (short) oImage --------------
		
		isRGB = NO;
		inverseVal = NO;
				
		NSString *colorspace = [dcmObject attributeValueWithName:@"PhotometricInterpretation"];		
		if ([colorspace rangeOfString:@"MONOCHROME1"].location != NSNotFound) {inverseVal = YES; savedWL = -savedWL;}													
		/*else if ( [colorspace hasPrefix:@"MONOCHROME2"])	{inverseVal = NO; savedWL = savedWL;} */
		if ( [colorspace hasPrefix:@"YBR"]) isRGB = YES;		
		if ( [colorspace hasPrefix:@"PALETTE"])	{ bitsAllocated = 8; isRGB = YES; NSLog(@"Palette depth conveted to 8 bit");}
		if ([colorspace rangeOfString:@"RGB"].location != NSNotFound) isRGB = YES;			
		/******** dcm Object will do this *******convertYbrToRgb -> planar is converted***/		
		if ([colorspace rangeOfString:@"YBR"].location != NSNotFound) {fPlanarConf = 0; isRGB = YES;}

		
		if (isRGB == YES) // CONVERT RGB TO ARGB FOR BETTER PERFORMANCE THRU VIMAGE
		{
			//NSLog(@"is RGB");		
			unsigned char   *ptr, *tmpImage;
			// realwidth = width = tag columns
			long			loop = (long) height * (long) realwidth;
			tmpImage = malloc (loop * 4L);
			ptr   = tmpImage;
						
			//NSLog(@"height %d width %d loop should be: %d", height , realwidth, (long) height * (long) realwidth);
			//NSLog(@"loop %d", loop);
			
			if( bitsAllocated > 8) // RGB_FFF
			{
// /*
				unsigned short   *bufPtr;
				bufPtr = (unsigned short*) oImage;
				{
					while( loop-- > 0)
					{							//unsigned short=16 bit, then I suppose A should be 65535
						*ptr++	= 255;			//ptr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
													//if (loop % 5000 == 0)
													//NSLog(@"loop: %d", loop);
					}
				}
// */				
			}
			else // RGB_888
			{
				NSLog(@"Convert to ARGB 8 bit");
				unsigned char   *bufPtr;
				bufPtr = (unsigned char*) oImage;
 /*
				long vImage_Error;
				vImage_Error = vImageConvert_RGB888toARGB8888( bufPtr, NULL, 255, ptr, 0, 0); //0=no flag
 */				

				{
					//loop = totSize/4;
					while( loop-- > 0)
					{
						*ptr++	= 255;			//ptr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
						*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
					}
				}
			}
			free(oImage);
			oImage = (short*) tmpImage;
		}

														
		else if( bitsAllocated == 8)	// Planar 8
		{
			//-> 16 bits image
			unsigned char   *bufPtr;
			short			*ptr, *tmpImage;
			long			loop, totSize;
			
			totSize = (long) ((long) height * (long) realwidth * 2L);
			tmpImage = malloc( totSize);
			
			bufPtr = (unsigned char*) oImage;
			ptr    = tmpImage;
 /*
				long vImage_Error;
				vImage_Error = vImageConvert_Planar8to16U (bufPtr, ptr, 0); //0=no flag
 */				
			
			loop = totSize/2;
			while( loop-- > 0)
			{
				*ptr++ = *bufPtr++;
				//	ptr++; bufPtr ++;
			}
			free(oImage);
			//efree3 ((void **) &oImage);
			oImage =  (short*) tmpImage;
		}
		
		
		
		
		
		
		
		if( realwidth != width)
		{
			//NSLog(@"Update width: %d realWidth: %d ", width, realwidth);
			if( isRGB)
			{
				int i;
				char	*ptr = (char*) oImage;
				for( i = 0; i < height;i++)
				{
					memmove( ptr + i*width*4, ptr + i*realwidth*4, width*4);
				}
			}
			else
			{
				if( bitsAllocated == 32)
				{
					int i;
					for( i = 0; i < height;i++)
					{
						memmove( oImage + i*width*2, oImage + i*realwidth*2, width*4);
					}
				}
				else
				{
					int i;					
					for( i = 0; i < height;i++)
					{
						memmove( oImage + i*width, oImage + i*realwidth, width*2);
					}
				}
			}
			//NSLog(@"Updated width");
		}
		
		//***********
		
		if( isRGB)
		{
			if( imPix->fVolImage)
			{
				imPix->fImage = imPix->fVolImage;
				memcpy( imPix->fImage, oImage, realwidth*height*sizeof(float));
				free(oImage);
			}
			else imPix->fImage = (float*) oImage;
			oImage = 0L;
			
			if( oData && [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayDICOMOverlays"] )
			{
				unsigned char	*rgbData = (unsigned char*) imPix->fImage;
				long			y, x;
				
				for( y = 0; y < oRows; y++)
				{
					for( x = 0; x < oColumns; x++)
					{
						if( oData[ y * oColumns + x])
						{
							rgbData[ y * width*4 + x*4 + 1] = 0xFF;
							rgbData[ y * width*4 + x*4 + 2] = 0xFF;
							rgbData[ y * width*4 + x*4 + 3] = 0xFF;
						}
					}
				}
			}
		}
		else
		{
			//NSLog(@"not RGB");
			if( bitsAllocated == 32)
			{
				unsigned long	*uslong = (unsigned long*) oImage;
				long			*slong = (long*) oImage;
				float			*tDestF;
				
				if( imPix->fVolImage)
				{
					tDestF = imPix->fImage = imPix->fVolImage;
				}
				else
				{
					tDestF = imPix->fImage = malloc(width*height*sizeof(float) + 100);
				}
				
				if( fIsSigned > 0)
				{
					long x = height * width;
					while( x-->0)
					{
						*tDestF++ = ((float) (*slong++)) * slope + offset;
					}
				}
				else
				{
					long x = height * width;
					while( x-->0)
					{
						*tDestF++ = ((float) (*uslong++)) * slope + offset;
					}
				}
				
				free(oImage);
				oImage = 0L;
			}
			else
			{
				vImage_Buffer src16, dstf;
				dstf.height = src16.height = height;
				dstf.width = src16.width = width;
				src16.rowBytes = width*2;
				dstf.rowBytes = width*sizeof(float);
				
				src16.data = oImage;
				
				if( imPix->fVolImage)
				{
					imPix->fImage = imPix->fVolImage;
				}
				else
				{
					imPix->fImage = malloc(width*height*sizeof(float) + 100);
				}
				
				dstf.data = imPix->fImage;
				
				if( fIsSigned > 0)
				{
					vImageConvert_16SToF( &src16, &dstf, offset, slope, 0);
				}
				else
				{
					
					vImageConvert_16UToF( &src16, &dstf, offset, slope, 0);
				}
				
				if( inverseVal)
				{
					float neg = -1;
					vDSP_vsmul( fImage, 1, &neg, fImage, 1, height * width);
				}
				
				free(oImage);
				oImage = 0L;
			}
			
			if( oData && [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayDICOMOverlays"] )
			{
				long			y, x;
				
				for( y = 0; y < oRows; y++)
				{
					for( x = 0; x < oColumns; x++)
					{
						if( oData[ y * oColumns + x]) imPix->fImage[ y * width + x] = 0xFF;
					}
				}
			}
		}
		
		if( pixmin == 0 && pixmax == 0)
		{
			
			wl = 0;
			ww = 0; //Computed later, only if needed
		}
		else
		{
			
			wl = pixmin + (pixmax - pixmin)/2;
			ww = (pixmax - pixmin);
		}
		
		if( savedWW != 0)
		{
			
			wl = savedWL;
			ww = savedWW;
		}
		
		[subPool release];

#pragma mark *after loading a frame


	}
}//end of 		if ([dcmObject attributeValueWithName:@"PixelData"])

	[pool release];
	return YES;
}



- (BOOL) loadDICOMPapyrus // PLEASE, KEEP BOTH FUNCTIONS FOR TESTING PURPOSE. THANKS
{
	int				elemType, pixmin, pixmax, realwidth, realheight, highBit;
	PapyShort		fileNb, imageNb, maxFrame = 1, ee,  err, theErr;
	PapyULong		nbVal, i, pos;
	SElement		*theGroupP;
	UValue_T		*val, *tmp;
	BOOL			fSetClut = NO, fSetClut16 = NO;
	unsigned char   *clutRed = 0L, *clutGreen = 0L, *clutBlue = 0L;
	PapyUShort		clutEntryR, clutEntryG, clutEntryB;
	PapyUShort		clutDepthR, clutDepthG, clutDepthB;
	
//	if( pixArray != 0L && frameNo > 0)
//	{
//		while( fImage == 0L) [NSThread  sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
//		return YES;
//	}
	
	[PapyrusLock lock];

	if( convertedDICOM)
	{
		fileNb = Papy3FileOpen ( (char*) [convertedDICOM UTF8String], (PAPY_FILE) 0, TRUE, 0);
	}
	else
	{
		if( srcFile == 0L) fileNb = -1;
		else
		{
			fileNb = Papy3FileOpen ( (char*) [srcFile UTF8String], (PAPY_FILE) 0, TRUE, 0);
//			if( fileNb >= 0)
//			{
//				if( gArrCompression[fileNb] == JPEG_LOSSLESS || gArrCompression[fileNb] == JPEG_LOSSY)
//				{
//					NSLog(@"Allocated Bits: %d", gx0028BitsAllocated [fileNb]);
//					if( gx0028BitsAllocated [fileNb] != 8 || [[NSUserDefaults standardUserDefaults] boolForKey: @"DCMTKJPEG"])
//					{
//						Papy3FileClose (fileNb, TRUE);
//						fileNb = -1;
//					}
//				}
//			}
//			if( fileNb < 0)
//			{
//				if( [[[srcFile pathExtension] lowercaseString] isEqualToString:@"dcm"] || fileNb != papNotPapyrusFile)
//				{
//					NSString *outputfile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/%@", filenameWithDate( srcFile)];
//					
//					convertedDICOM = [convertDICOM( srcFile) retain];
//					
//					fileNb = Papy3FileOpen ( (char*) [convertedDICOM UTF8String], (PAPY_FILE) 0, TRUE, 0);
//				}
//			}
		}
	}
	
	[PapyrusLock unlock];
	
	if (fileNb >= 0)
	{
		long			j;
		UValue_T		*val3, *tmpVal3;
		unsigned short	*shortRed, *shortGreen, *shortBlue;

		imageNb = 1 + frameNo; 
		
		pixelSpacingX = 0;
		pixelSpacingY = 0;
		
		offset = 0.0;
		slope = 1.0;
		
		if (gIsPapyFile [fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
		
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0008);
		if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			val = Papy3GetElement (theGroupP, papAcquisitionTimeGr, &nbVal, &elemType );
			if( val)
			{
				NSString		*cc = [[NSString alloc] initWithCString:val->a length:strlen(val->a)];
				NSCalendarDate	*cd = [[NSCalendarDate alloc] initWithString:cc calendarFormat:@"%H%M%S"];
				
				acquisitionTime = [[NSCalendarDate	dateWithString: [cd descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
				
				[cd release];
				[cc release];
			}
			
			theErr = Papy3GroupFree (&theGroupP, TRUE);
		}
		
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0010);
		if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			val = Papy3GetElement (theGroupP, papPatientsWeightGr, &nbVal, &elemType);
			if (val != NULL) patientsWeight = [[NSString stringWithCString:val->a] floatValue];
			else patientsWeight = 0;
			
			theErr = Papy3GroupFree (&theGroupP, TRUE);
		}
		
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0018);
		if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			val = Papy3GetElement (theGroupP, papSliceThicknessGr, &nbVal, &elemType);
			if (val != NULL)
			{
				sliceThickness = [[NSString stringWithCString:val->a] floatValue];
			}
			else sliceThickness = 0;
			
			val = Papy3GetElement (theGroupP, papRepetitionTimeGr, &nbVal, &elemType);
			if (val != NULL) repetitiontime = [[NSString stringWithFormat:@"%0.1f", [[NSString stringWithCString:val->a] floatValue]] retain];
			else repetitiontime = 0;
			
			val = Papy3GetElement (theGroupP, papEchoTimeGr, &nbVal, &elemType);
			if (val != NULL) echotime = [[NSString stringWithFormat:@"%0.1f", [[NSString stringWithCString:val->a] floatValue]] retain];
			else echotime = 0;
			
			val = Papy3GetElement (theGroupP, papProtocolNameGr, &nbVal, &elemType);
			if (val != NULL) protocolName = [[NSString stringWithCString:val->a] retain];
			else protocolName = 0;
			
			val = Papy3GetElement (theGroupP, papViewPositionGr, &nbVal, &elemType);
			if (val != NULL) viewPosition = [[NSString stringWithCString:val->a] retain];
			else viewPosition = 0;
			
			val = Papy3GetElement (theGroupP, papPatientPositionGr, &nbVal, &elemType);
			if (val != NULL) patientPosition = [[NSString stringWithCString:val->a] retain];
			else patientPosition = 0;
			
			val = Papy3GetElement (theGroupP, papCineRateGr, &nbVal, &elemType);
			if (val != NULL) cineRate = [[NSString stringWithCString:val->a] floatValue];	//[[NSString stringWithFormat:@"%0.1f", ] floatValue];
			else cineRate = 0;
			
			val = Papy3GetElement (theGroupP, papImagerPixelSpacingGr, &nbVal, &elemType);
			if (val != NULL)
			{
				tmp = val;
				pixelSpacingY = [[NSString stringWithCString:tmp->a] floatValue];
				
				if( nbVal > 1)
				{
					tmp++;
					pixelSpacingX = [[NSString stringWithCString:tmp->a] floatValue];
				}
			}
			
			if( cineRate == 0)
			{
				val = Papy3GetElement (theGroupP, papFrameTimeVectorGr, &nbVal, &elemType);
				if (val != NULL)
				{
					cineRate = 1000./[[NSString stringWithCString:val->a] floatValue];
				}
			}
			
			theErr = Papy3GroupFree (&theGroupP, TRUE);
		}
		
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0020);
		if(  theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			originX = 0;
			originY = 0;
			originZ = 0;
			
			val = Papy3GetElement (theGroupP, papImagePositionPatientGr, &nbVal, &elemType);
			if (val != NULL)
			{
				tmp = val;
				
				originX = [[NSString stringWithCString:tmp->a] floatValue];
				
				if( nbVal > 1)
				{
					tmp++;
					originY = [[NSString stringWithCString:tmp->a] floatValue];
				}
				
				if( nbVal > 2)
				{
					tmp++;
					originZ = [[NSString stringWithCString:tmp->a] floatValue];
				}
			}
			
			orientation[ 0] = 1;	orientation[ 1] = 0;	orientation[ 2] = 0;
			orientation[ 3] = 0;	orientation[ 4] = 1;	orientation[ 5] = 0;
			
			val = Papy3GetElement (theGroupP, papImageOrientationPatientGr, &nbVal, &elemType);
			if (val != NULL)
			{
				tmpVal3 = val;
				if( nbVal != 6) { nbVal = 6;		NSLog(@"Orientation is NOT 6 !!!");}
				for (j = 0; j < nbVal; j++)
				{
					orientation[ j]  = [[NSString stringWithCString:tmpVal3->a] floatValue];
					tmpVal3++;
				}
			}
			
//				val = Papy3GetElement (theGroupP, papSliceLocationGr, &nbVal, &elemType);
//				if (val != NULL)
//				{
//					sliceLocation = [[NSString stringWithCString:val->a] floatValue];
//				}
//				else sliceLocation = -1;
			
			theErr = Papy3GroupFree (&theGroupP, TRUE);
		}
					
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0028);
		if(  theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			maxFrame = gArrNbImages [fileNb];
			
			val3 = Papy3GetElement (theGroupP, papRescaleInterceptGr, &pos, &elemType);
			if (val3 != NULL)
			{
				tmpVal3 = val3;
				// get the last offset
				for (j = 1; j < pos; j++) tmpVal3++;
				offset =  [[NSString stringWithCString:tmpVal3->a] floatValue];
			}
			val3 = Papy3GetElement (theGroupP, papRescaleSlopeGr, &pos, &elemType);
			if (val3 != NULL)
			{
				tmpVal3 = val3;
				// get the last slope
				for (j = 1; j < pos; j++) tmpVal3++;
				slope = [[NSString stringWithCString:tmpVal3->a] floatValue];
				
			//	NSLog(@"slope:%f", slope);
				
//						if( slope != 0 && fabs( slope) < 0.01)
//						{
//							while( slope < 0.01)
//							{
//								slope *= 100.;
//							}
//						}
			}
			
			val = Papy3GetElement (theGroupP, papBitsAllocatedGr, &nbVal, &elemType);
			bitsAllocated = (int) val->us;
			
			val = Papy3GetElement (theGroupP, papHighBitGr, &nbVal, &elemType);
			highBit = (int) val->us;
			
			val = Papy3GetElement (theGroupP, papBitsStoredGr, &nbVal, &elemType);
			bitsStored = (int) val->us;
//			if( val->us == 8 && bitsAllocated == 16)
//			{
//				bitsAllocated = 8;
//			}
			
			// extract nb of rows and cols
			width = height = 0;
			
			// ROWS
			val = Papy3GetElement (theGroupP, papRowsGr, &nbVal, &elemType);
			if (val != NULL)
			{
				height = (int) (*val).us;
				height /=2;
				height *=2;
			}
			// COLUMNS
			val = Papy3GetElement (theGroupP, papColumnsGr, &nbVal, &elemType);
			if (val != NULL) 
			{
				realwidth = (int) (*val).us;
				width = realwidth/2;
				width *=2;
				
				if( realwidth != width) NSLog(@"width!=realwidth");
			}
			
			// PIXEL REPRESENTATION
			val = Papy3GetElement (theGroupP, papPixelRepresentationGr, &nbVal, &elemType);
			if (val != NULL && val->us == 1) fIsSigned = YES;
			else fIsSigned = NO;
			
			val = Papy3GetElement (theGroupP, papWindowCenterGr, &nbVal, &elemType);
			if (val != NULL)
			{
				savedWL = [[NSString stringWithCString:val->a] floatValue];
			}
			
			val = Papy3GetElement (theGroupP, papWindowWidthGr, &nbVal, &elemType);
			if (val != NULL)
			{
				savedWW = [[NSString stringWithCString:val->a] floatValue];
			}
			
			// PLANAR CONFIGURATION
			val = Papy3GetElement (theGroupP, papPlanarConfigurationGr, &nbVal, &elemType);
			if (val != NULL) fPlanarConf = (int) val->us;
			else fPlanarConf = 0;
		//	fPlanarConf = 1;
			
			// PIXMIN
		//	val = Papy3GetElement (theGroupP, papSmallestImagePixelValueGr, &nbVal, &elemType);
		//	if (val != NULL) pixmin = (int) val->us;
		//	else pixmin = 0;
			
			// PIXMAX
		//	val = Papy3GetElement (theGroupP, papLargestImagePixelValueGr, &nbVal, &elemType);
		//	if (val != NULL) pixmax = (int) val->us;
		//	else pixmax = 0;
			
			pixmin = pixmax = 0;
			
			pixelRatio = 1.0;
			
			val = Papy3GetElement (theGroupP, papPixelSpacingGr, &nbVal, &elemType);
			if (val != NULL)
			{
				tmp = val;
				
				pixelSpacingY = [[NSString stringWithCString:tmp->a] floatValue];
				
				if( nbVal > 1)
				{
					tmp++;
					
					pixelSpacingX = [[NSString stringWithCString:tmp->a] floatValue];
				}
			}
			
			val = Papy3GetElement (theGroupP, papPixelAspectRatioGr, &nbVal, &elemType);
			if (val != NULL)
			{
				float ratiox = 1, ratioy = 1;
				
				tmp = val;
				
				ratiox = [[NSString stringWithCString:tmp->a] floatValue];
				
				if( nbVal > 1)
				{
					tmp++;
					
					ratioy = [[NSString stringWithCString:tmp->a] floatValue];
				}
				
				if( ratioy != 0)
				{
					pixelRatio = ratiox / ratioy;
				}
			}
			else if( pixelSpacingX != pixelSpacingY)
			{
				if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
			}
			
			if (gArrPhotoInterpret [fileNb] == PALETTE)
			{
				BOOL found = NO, found16 = NO;
				
				clutRed = malloc( 65536);
				clutGreen = malloc( 65536);
				clutBlue = malloc( 65536);
				
				// initialisation
				clutEntryR = clutEntryG = clutEntryB = 0;
				clutDepthR = clutDepthG = clutDepthB = 0;
				
				for (j = 0; j < 65536; j++)
				{
					clutRed[ j] = 0;
					clutGreen[ j] = 0;
					clutBlue[ j] = 0;
				}
				
				// read the RED descriptor of the color lookup table
				val = Papy3GetElement (theGroupP, papRedPaletteColorLookupTableDescriptorGr, &nbVal, &elemType);
				tmp = val;
				if (val != NULL)
				{
				  clutEntryR = tmp->us;
				  tmp++;tmp++;
				  clutDepthR = tmp->us;
				} // if ...read Red palette color descriptor
				
				// read the GREEN descriptor of the color lookup table
				val = Papy3GetElement (theGroupP, papGreenPaletteColorLookupTableDescriptorGr, &nbVal, &elemType);
				if (val != NULL)
				{
				  clutEntryG	= val->us;
				  tmp			= val + 2;
				  clutDepthG	= tmp->us;
				} // if ...read Green palette color descriptor
				
				// read the BLUE descriptor of the color lookup table
				val = Papy3GetElement (theGroupP, papBluePaletteColorLookupTableDescriptorGr, &nbVal, &elemType);
				if (val != NULL)
				{
				  clutEntryB = val->us;
				  tmp     = val + 2;
				  clutDepthB = tmp->us;
				} // if ...read Blue palette color descriptor
				
				if( clutEntryR > 256) NSLog(@"R-Palette > 256");
				if( clutEntryG > 256) NSLog(@"G-Palette > 256");
				if( clutEntryB > 256) NSLog(@"B-Palette > 256");
				
				val = Papy3GetElement (theGroupP, papSegmentedRedPaletteColorLookupTableDataGr, &nbVal, &elemType);
				if (val != NULL)	// SEGMENTED PALETTE - 16 BIT !
				{
					if (clutDepthR == 16  && clutDepthG == 16  && clutDepthB == 16)
					{
						long			length, xx, xxindex, jj;
						
						shortRed = malloc( 65535L * sizeof( unsigned short));
						shortGreen = malloc( 65535L * sizeof( unsigned short));
						shortBlue = malloc( 65535L * sizeof( unsigned short));
						
						// extract the RED palette clut data
						val = Papy3GetElement (theGroupP, papSegmentedRedPaletteColorLookupTableDataGr, &nbVal, &elemType);
						if (val != NULL)
						{
							unsigned short  *ptrs =  (unsigned short*) val->a;
							nbVal = theGroupP[ papSegmentedRedPaletteColorLookupTableDataGr].length / 2;
							
							NSLog(@"red");
							
							xxindex = 0;
							for( jj = 0; jj < nbVal;jj++)
							{
								NSLog(@"val: %d", ptrs[jj]);
								switch( ptrs[jj])
								{
									case 0:	// Discrete
										jj++;
										length = ptrs[jj];
										NSLog(@"length: %d", length);
										jj++;
										for( xx = xxindex; xxindex < xx + length; xxindex++)
										{
											shortRed[ xxindex] = ptrs[ jj++];
											if( xxindex < 256) NSLog(@"%d", shortRed[ xxindex]);
										}
										jj--;
									break;
									
									case 1:	// Linear
										jj++;
										length = ptrs[jj];
										for( xx = xxindex; xxindex < xx + length; xxindex++)
										{
											shortRed[ xxindex] = shortRed[ xx-1] + ((ptrs[jj+1] - shortRed[ xx-1]) * (1+xxindex - xx)) / (length);
									//		if( xxindex < 256) NSLog(@"%d", shortRed[ xxindex]);
										}
										jj ++;
									break;
									
									case 2: // Indirect
										NSLog(@"indirect not supported");
										jj++;
										length = ptrs[jj];

										jj += 2;
									break;
									
									default:
										NSLog(@"Error, Error, OsiriX will soon crash...");
									break;
								}
							}
							found16 = YES; 	// this is used to let us know we have to look for the other element */
							NSLog(@"%d", xxindex);
						}//endif
						
													// extract the GREEN palette clut data
						val = Papy3GetElement (theGroupP, papSegmentedGreenPaletteColorLookupTableDataGr, &nbVal, &elemType);
						if (val != NULL)
						{
							unsigned short  *ptrs =  (unsigned short*) val->a;
							nbVal = theGroupP[ papSegmentedGreenPaletteColorLookupTableDataGr].length / 2;
							
							NSLog(@"green");
							
							xxindex = 0;
							for( jj = 0; jj < nbVal; jj++)
							{
								switch( ptrs[jj])
								{
									case 0:	// Discrete
										jj++;
										length = ptrs[jj];
										jj++;
										for( xx = xxindex; xxindex < xx + length; xxindex++)
										{
											shortGreen[ xxindex] = ptrs[ jj++];
								//			if( xxindex < 256) NSLog(@"%d", shortGreen[ xxindex]);
										}
										jj--;
									break;
									
									case 1:	// Linear
										jj++;
										length = ptrs[jj];
										for( xx = xxindex; xxindex < xx + length; xxindex++)
										{
											shortGreen[ xxindex] = shortGreen[ xx-1] + ((ptrs[jj+1] - shortGreen[ xx-1]) * (1+xxindex - xx)) / (length);
										//	if( xxindex < 256) NSLog(@"%d", shortGreen[ xxindex]);
										}
										jj ++;
									break;
									
									case 2: // Indirect
										NSLog(@"indirect not supported");
										jj++;
										length = ptrs[jj];

										jj += 2;
									break;
									
									default:
										NSLog(@"Error, Error, OsiriX will soon crash...");
									break;
								}
							}
							found16 = YES; 	// this is used to let us know we have to look for the other element */
							NSLog(@"%d", xxindex);
						}//endif
						
													// extract the BLUE palette clut data
						val = Papy3GetElement (theGroupP, papSegmentedBluePaletteColorLookupTableDataGr, &nbVal, &elemType);
						if (val != NULL)
						{
							unsigned short  *ptrs =  (unsigned short*) val->a;
							nbVal = theGroupP[ papSegmentedBluePaletteColorLookupTableDataGr].length / 2;
							
							NSLog(@"blue");
							
							xxindex = 0;
							for( jj = 0; jj < nbVal; jj++)
							{
								switch( ptrs[jj])
								{
									case 0:	// Discrete
										jj++;
										length = ptrs[jj];
										jj++;
										for( xx = xxindex; xxindex < xx + length; xxindex++)
										{
											shortBlue[ xxindex] = ptrs[ jj++];
								//			if( xxindex < 256) NSLog(@"%d", shortBlue[ xxindex]);
										}
										jj--;
									break;
									
									case 1:	// Linear
										jj++;
										length = ptrs[jj];
										for( xx = xxindex; xxindex < xx + length; xxindex++)
										{
											shortBlue[ xxindex] = shortBlue[ xx-1] + ((ptrs[jj+1] - shortBlue[ xx-1]) * (xxindex - xx + 1)) / (length);
								//			if( xxindex < 256) NSLog(@"%d", shortBlue[ xxindex]);
										}
										jj ++;
									break;
									
									case 2: // Indirect
										NSLog(@"indirect not supported");
										jj++;
										length = ptrs[jj];

										jj += 2;
									break;
									
									default:
										NSLog(@"Error, Error, OsiriX will soon crash...");
									break;
								}
							}
							found16 = YES; 	// this is used to let us know we have to look for the other element */
							NSLog(@"%d", xxindex);
						}//endif
						
						for( jj = 0; jj < 65535; jj++)
						{
							shortRed[jj] =shortRed[jj]>>8;
							shortGreen[jj] =shortGreen[jj]>>8;
							shortBlue[jj] =shortBlue[jj]>>8;
							
//								if( shortRed[jj] == shortGreen[jj] && shortRed[jj] == shortBlue[jj])
//								{
//									NSLog(@"%d : %d/%d/%d", jj, shortRed[jj], shortGreen[jj], shortBlue[jj]);
//								}
						}
					}
					else if (clutDepthR == 8  && clutDepthG == 8  && clutDepthB == 8)
					{
						NSLog(@"Segmented palettes for 8 bits ??");
					}
					else
					{
						NSLog(@"Dont know this kind of DICOM CLUT...");
					}
				}
				// EXTRACT THE PALETTE data only if there is 256 entries and depth is 16 bits
				else if (clutDepthR == 16  && clutDepthG == 16  && clutDepthB == 16)
				{
					if( clutEntryR == clutEntryG == clutEntryB == 0)
					{
						clutEntryR = 65535;
						clutEntryG = 65535;
						clutEntryB = 65535;
					}
					
					// extract the RED palette clut data
					val = Papy3GetElement (theGroupP, papRedPaletteCLUTDataGr, &nbVal, &elemType);
					if (val != NULL)
					{
						unsigned short  *ptrs =  (unsigned short*) val->a;
						for (j = 0; j < clutEntryR; j++, ptrs++) clutRed [j] = (int) (*ptrs/256);
						
						found = YES; 	// this is used to let us know we have to look for the other element */
					}//endif

					// extract the GREEN palette clut data
					val = Papy3GetElement (theGroupP, papGreenPaletteCLUTDataGr, &nbVal, &elemType);
					if (val != NULL)
					{
						unsigned short  *ptrs = (unsigned short*) val->a;
						for (j = 0; j < clutEntryG; j++, ptrs++) clutGreen [j] = (int) (*ptrs/256);
					}
					// extract the BLUE palette clut data
					val = Papy3GetElement (theGroupP, papBluePaletteCLUTDataGr, &nbVal, &elemType);
					if (val != NULL)
					{
						unsigned short  *ptrs =  (unsigned short*) val->a;
						for (j = 0; j < clutEntryB; j++, ptrs++) clutBlue [j] = (int) (*ptrs/256);
					}
				} // if ...the palette has 256 entries and thus we extract the clut datas
				else if (clutDepthR == 8  && clutDepthG == 8  && clutDepthB == 8)
				{
				  // extract the RED palette clut data
				  val = Papy3GetElement (theGroupP, papRedPaletteCLUTDataGr, &nbVal, &elemType);
				  if (val != NULL)
				  {
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for (j = 0; j < clutEntryR; j++, ptrs++) clutRed [j] = (int) (*ptrs);
					found = YES; 	// this is used to let us know we have to look for the other element */
				  }//endif

				  // extract the GREEN palette clut data
				  val = Papy3GetElement (theGroupP, papGreenPaletteCLUTDataGr, &nbVal, &elemType);
				  if (val != NULL)
				  {
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for (j = 0; j < clutEntryG; j++, ptrs++) clutGreen [j] = (int) (*ptrs);
					}
				  // extract the BLUE palette clut data
				  val = Papy3GetElement (theGroupP, papBluePaletteCLUTDataGr, &nbVal, &elemType);
				  if (val != NULL)
					{
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for (j = 0; j < clutEntryB; j++, ptrs++) clutBlue [j] = (int) (*ptrs);
					}
				}
				else
				{
					NSLog(@"Dont know this kind of DICOM CLUT...");
				}
				
				// let the rest of the routine know that it should set the clut
				if (found) fSetClut = YES;
				if (found16) fSetClut16 = YES;
			} // endif ...extraction of the color palette
			
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"UseVOILUT"])
			{
				val = Papy3GetElement (theGroupP, papVOILUTSequenceGr, &pos, &elemType );
				
				// Loop over sequence
				
				if ( val != NULL)
				{
					if( val->sq != NULL )
					{
						Papy_List	*dcmList = val->sq->object->item;
						if (dcmList != NULL)	// We use ONLY the first VOILut available
						{
							SElement *gr = (SElement *)dcmList->object->group;
							if ( gr->group == 0x0028 )
							{
								
								val = Papy3GetElement (gr, papLUTDescriptorGr, &pos, &elemType );
								if( val)
								{
									VOILUT_number = val->us;		val++;
									VOILUT_first = val->us;			val++;
									VOILUT_depth = val->us;			val++;
								}
								
								val = Papy3GetElement (gr, papLUTDataGr, &pos, &elemType );
								if( val)
								{
									VOILUT_number = pos;
									
									if( VOILUT_table) free( VOILUT_table);
									VOILUT_table = malloc( sizeof(unsigned int) * VOILUT_number);
									for (j = 0; j < VOILUT_number; j++)
									{
										VOILUT_table [j] = (unsigned int) val->us;			val++;
									}
								}
							}
						//	dcmList = dcmList->next;
						}
					}
				}
			}

			
			theErr = Papy3GroupFree (&theGroupP, TRUE);
		}

#pragma mark SUV

		// Get values needed for SUV calcs:
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x0054);
		if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0) {
			val = Papy3GetElement (theGroupP, papUnitsGr, &pos, &elemType );
			if( val) units = val? [[NSString stringWithCString:val->a] retain] : nil;
			else units = 0L;
			
			val = Papy3GetElement (theGroupP, papDecayCorrectionGr, &pos, &elemType );
			if( val) decayCorrection = val? [[NSString stringWithCString:val->a] retain] : nil;
			else decayCorrection = 0L;
			
			val = Papy3GetElement (theGroupP, papDecayFactorGr, &pos, &elemType );
			if( val) decayFactor = val? [[NSString stringWithCString:val->a] floatValue] : nil;
			else decayFactor = 1.0;
			
			//  Note: Following def for papRadiopharmaceuticalInformationSequence is off by 6!!!!
			val = Papy3GetElement (theGroupP, papRadiopharmaceuticalInformationSequence + 6, &pos, &elemType );
			
			// Loop over sequence to find injected dose
			
			if ( val != NULL)
			{
				if( val->sq != NULL )
				{
					Papy_List	*dcmList = val->sq->object->item;
					while (dcmList != NULL) {
						SElement *gr = (SElement *)dcmList->object->group;
						if ( gr->group == 0x0018 )
						{
							val = Papy3GetElement (gr, papRadionuclideTotalDoseGr, &pos, &elemType );
							radionuclideTotalDose = val? [[NSString stringWithCString:val->a] floatValue] : 0.0;
							
							val = Papy3GetElement (gr, papRadiopharmaceuticalStartTimeGr, &pos, &elemType );
							if( val)
							{
								NSString		*cc = [[NSString alloc] initWithCString:val->a length:strlen(val->a)];
								NSCalendarDate	*cd = [[NSCalendarDate alloc] initWithString:cc calendarFormat:@"%H%M%S"];
								
								radiopharmaceuticalStartTime = [[NSCalendarDate	dateWithString: [cd descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
								
								[cd release];
								[cc release];
							}
							
							val = Papy3GetElement (gr, papRadionuclideHalfLifeGr, &pos, &elemType );
							halflife = val? [[NSString stringWithCString:val->a] floatValue] : 0.0;
							break;
						}
						dcmList = dcmList->next;
					}
				}
						
				[self computeTotalDoseCorrected];
			
				// End of SUV required values
			}

			theErr = Papy3GroupFree (&theGroupP, TRUE);
		}
		
		// End SUV			
		
#pragma mark MR/CT multiframe		
		// Is it a new MR/CT multi-frame exam?
		if ((err = Papy3GotoGroupNb (fileNb, 0x5200)) == 0)
		{
			SElement	  *groupOverlay;
			
			// read group 0x6001 from the file
			if ((err = Papy3GroupRead (fileNb, &groupOverlay)) > 0)
			{
				NSLog(@"Group 5200 available");
				
				// ****** ****** ****** ************************************************************************
				// SHARED FRAME
				// ****** ****** ****** ************************************************************************
				
				val = Papy3GetElement (groupOverlay, papSharedFunctionalGroupsSequence, &nbVal, &elemType);
				
				// there is an element
				if (val != NULL)
				{
					// there is a sequence
					if (val->sq != NULL)
					{
						Papy_List	  *dcmList;
						
						// get a pointer to the first element of the list
						dcmList = val->sq->object->item;
						
						// loop through the elements of the sequence
						while (dcmList != NULL)
						{
							SElement * gr = (SElement *) dcmList->object->group;
							
							//NSLog( @"group:%x, element:%x", gr->group, gr->element);
							
							switch( gr->group)
							{
								case 0x0020:
									val3 = Papy3GetElement (gr, papPlaneOrientationSequence, &nbVal, &elemType);
									if (val3 != NULL && nbVal >= 1)
									{
										// there is a sequence
										if (val3->sq != NULL)
										{
											Papy_List	  *PixelMatrixSeq;
						
											// get a pointer to the first element of the list
											PixelMatrixSeq = val3->sq->object->item;
											
											// loop through the elements of the sequence
											while (PixelMatrixSeq != NULL)
											{
												SElement * gr28 = (SElement *) PixelMatrixSeq->object->group;
												
												//NSLog( @"group:%x, element:%x", gr28->group, gr28->element);
												
												switch( gr28->group)
												{
													case 0x0020:
														val3 = Papy3GetElement (gr28, papImageOrientationPatientGr, &nbVal, &elemType);
														if (val3 != NULL && nbVal >= 1)
														{
															tmpVal3 = val3;
															if( nbVal != 6) { nbVal = 6;		NSLog(@"Orientation is NOT 6 !!!");}
															for (j = 0; j < nbVal; j++)
															{
																orientation[ j]  = [[NSString stringWithCString:tmpVal3->a] floatValue];
																tmpVal3++;
															}
														}
													break;
												}
												
												// get the next element of the list
												PixelMatrixSeq = PixelMatrixSeq->next;
											}
										}
									}
								break;
								
								case 0x0028:
									val3 = Papy3GetElement (gr, papPixelMatrixSequence, &nbVal, &elemType);
									if (val3 != NULL && nbVal >= 1)
									{
										// there is a sequence
										if (val3->sq != NULL)
										{
											Papy_List	  *PixelMatrixSeq;
						
											// get a pointer to the first element of the list
											PixelMatrixSeq = val3->sq->object->item;
											
											// loop through the elements of the sequence
											while (PixelMatrixSeq != NULL)
											{
												SElement * gr28 = (SElement *) PixelMatrixSeq->object->group;
												
												//NSLog( @"group:%x, element:%x", gr28->group, gr28->element);
												
												switch( gr28->group)
												{
													case 0x0018:
														val3 = Papy3GetElement (gr28, papSliceThicknessGr, &nbVal, &elemType);
														if (val3 != NULL && nbVal >= 1)
														{
															sliceThickness = [[NSString stringWithCString:val3->a] floatValue];
														}
													break;
													
													case 0x0028:
														val3 = Papy3GetElement (gr28, papPixelSpacingGr, &nbVal, &elemType);
														if (val3 != NULL && nbVal >= 1)
														{
															tmp = val3;
															
															pixelSpacingY = [[NSString stringWithCString:tmp->a] floatValue];
															
															if( nbVal > 1)
															{
																tmp++;
																pixelSpacingX = [[NSString stringWithCString:tmp->a] floatValue];
															}
														}
													break;
												}
												
												// get the next element of the list
												PixelMatrixSeq = PixelMatrixSeq->next;
											}
										}
									}
									
									val3 = Papy3GetElement (gr, papPixelValueTransformationSequence, &nbVal, &elemType);
									if (val3 != NULL && nbVal >= 1)
									{
										// there is a sequence
										if (val3->sq != NULL)
										{
											Papy_List	  *PixelMatrixSeq;
						
											// get a pointer to the first element of the list
											PixelMatrixSeq = val3->sq->object->item;
											
											// loop through the elements of the sequence
											while (PixelMatrixSeq != NULL)
											{
												SElement * gr28 = (SElement *) PixelMatrixSeq->object->group;
												
												//NSLog( @"group:%x, element:%x", gr28->group, gr28->element);
												
												switch( gr28->group)
												{
													case 0x0028:
														val3 = Papy3GetElement (gr28, papRescaleInterceptGr, &nbVal, &elemType);
														if (val3 != NULL && nbVal >= 1)
														{
															tmpVal3 = val3;
															// get the last offset
															for (j = 1; j < nbVal; j++) tmpVal3++;
															offset =  [[NSString stringWithCString:tmpVal3->a] floatValue];
														}
														
														val3 = Papy3GetElement (gr28, papRescaleSlopeGr, &nbVal, &elemType);
														if (val3 != NULL && nbVal >= 1)
														{
															tmpVal3 = val3;
															// get the last slope
															for (j = 1; j < nbVal; j++) tmpVal3++;
															slope  = [[NSString stringWithCString:tmpVal3->a] floatValue];  //CharToFloat (tmpVal3->a);
															
//															if( slope != 0 && fabs( slope) < 0.01)
//															{
//																while( slope < 0.01)
//																{
//																	slope *= 100.;
//																}
//															}
														}
													break;
												}
												
												// get the next element of the list
												PixelMatrixSeq = PixelMatrixSeq->next;
											}
										}
									}

								break;
							}
							
							// get the next element of the list
							dcmList = dcmList->next;
						} // while ...loop through the sequence
					} // if ...there is a sequence of groups
				} // if ...val is not NULL
				
#pragma mark code for each frame				
				// ****** ****** ****** ************************************************************************
				// PER FRAME
				// ****** ****** ****** ************************************************************************
				
				long frameCount = 0;
				
				val = Papy3GetElement (groupOverlay, papPerFrameFunctionalGroupsSequence, &nbVal, &elemType);
				
				// there is an element
				if (val != NULL)
				{
					// there is a sequence
					if (val->sq != NULL)
					{
						Papy_List	  *dcmList;
						
						// get a pointer to the first element of the list
						dcmList = val->sq;
						
						// loop through the elements of the sequence
						while (dcmList != NULL)
						{
							SElement * gr;
							
							gr = (SElement *) dcmList->object->item->object->group;
							
							//NSLog(@"frameCount:%d imageNb:%d", frameCount, imageNb);
							
							if( frameCount == imageNb-1)
							{
								//NSLog( @"group:%x, element:%x", gr->group, gr->element);
								
								switch( gr->group)
								{
									case 0x0020:
										val = Papy3GetElement (gr, papPlanePositionSequence, &nbVal, &elemType);
										if (val != NULL && nbVal >= 1)
										{
											// there is a sequence
											if (val->sq != NULL)
											{
												Papy_List	  *PlanePositionSequence;
							
												// get a pointer to the first element of the list
												PlanePositionSequence = val->sq->object->item;
												
												// loop through the elements of the sequence
												while (PlanePositionSequence != NULL)
												{
													SElement * gr20 = (SElement *) PlanePositionSequence->object->group;
													
													//NSLog( @"group:%x, element:%x", gr20->group, gr20->element);
													
													switch( gr20->group)
													{
														case 0x0020:
															val3 = Papy3GetElement (gr20, papImagePositionPatientGr, &nbVal, &elemType);
															if (val3 != NULL && nbVal >= 1)
															{
																tmp = val3;
																
																originX = [[NSString stringWithCString:tmp->a] floatValue];
																
																if( nbVal > 1)
																{
																	tmp++;
																	originY = [[NSString stringWithCString:tmp->a] floatValue];
																}
																
																if( nbVal > 2)
																{
																	tmp++;
																	originZ = [[NSString stringWithCString:tmp->a] floatValue];
																}
																
																NSLog(@"X:%f Y:%f Z:%f", originX, originY, originZ);
															}
														break;
														
														case 0x0028:
															val3 = Papy3GetElement (gr20, papPixelSpacingGr, &nbVal, &elemType);
															if (val3 != NULL && nbVal >= 1)
															{
																tmp = val3;
																
																pixelSpacingY = [[NSString stringWithCString:tmp->a] floatValue];
																
																if( nbVal > 1)
																{
																	tmp++;
																	pixelSpacingX = [[NSString stringWithCString:tmp->a] floatValue];
																}
															}
														break;
													}
													
													// get the next element of the list
													PlanePositionSequence = PlanePositionSequence->next;
												}
											}
										}

									break;
								}
								// STOP THE LOOP
								dcmList = 0L;
							} // right frame?
							
							if( dcmList != 0L)
							{
								// get the next element of the list
								dcmList = dcmList->next;
								if( dcmList->object->item == 0L) dcmList = 0L;
								
								frameCount++;
							}
						} // while ...loop through the sequence
					} // if ...there is a sequence of groups
				} // if ...val is not NULL
				
				// free groupOverlay 0x5200
				err = Papy3GroupFree (&groupOverlay, TRUE);

			}//endif ...groupOverlay 0x5200 read
		}//endif ...groupOverlay 0x5200 found
		
#pragma mark tag group 6000		
		
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x6000);
		if(  theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			val = Papy3GetElement (theGroupP, papOverlayRows6000Gr, &nbVal, &elemType);
			if (val != NULL) oRows	= val->us;
			
			val = Papy3GetElement (theGroupP, papOverlayColumns6000Gr, &nbVal, &elemType);
			if (val != NULL) oColumns	= val->us;
			
//			val = Papy3GetElement (theGroupP, papNumberofFramesinOverlayGr, &nbVal, &elemType);
//			if (val != NULL) oRows	= val->us;
			
			val = Papy3GetElement (theGroupP, papOverlayTypeGr, &nbVal, &elemType);
			if (val != NULL) oType	= val->a[ 0];
			
			val = Papy3GetElement (theGroupP, papOriginGr, &nbVal, &elemType);
			if (val != NULL)
			{
				oOrigin[ 0]	= val->us;
				val++;
				oOrigin[ 1]	= val->us;
			}
			
			val = Papy3GetElement (theGroupP, papOverlayBitsAllocatedGr, &nbVal, &elemType);
			if (val != NULL) oBits	= val->us;
			
			val = Papy3GetElement (theGroupP, papBitPositionGr, &nbVal, &elemType);
			if (val != NULL) oBitPosition	= val->us;
			
			val = Papy3GetElement (theGroupP, papOverlayDataGr, &nbVal, &elemType);
			if (val != NULL && oBits == 1 && oRows == height && oColumns == width && oType == 'G' && oBitPosition == 0 && oOrigin[ 0] == 1 && oOrigin[ 1] == 1)
			{
				if( oData) free( oData);
				oData = malloc( oRows*oColumns);
				
				unsigned short *pixels = val->ow;
				char			valBit [ 16];
				char			mask = 1;
				int				x;
				
				for ( i = 0; i < oColumns*oRows/16; i++)
				{
					unsigned short	octet = pixels[ i];
					
					for (x = 0; x < 16;x ++)
					{
						valBit[ x] = octet & mask ? 1 : 0;
						octet = octet >> 1;
						
						if( valBit[ x]) oData[ i*16 + x] = 0xFF;
						else oData[ i*16 + x] = 0;
					}
				}
			}
			err = Papy3GroupFree (&theGroupP, TRUE);
		}
		
#pragma mark PhilipsFactor		
		
		theErr = Papy3GotoGroupNb (fileNb, (PapyShort) 0x7053);
		if( theErr >= 0 && Papy3GroupRead (fileNb, &theGroupP) > 0)
		{
			val = Papy3GetElement (theGroupP, papSUVFactor7053Gr, &nbVal, &elemType);
			
			if( nbVal > 0)
			{
				if( val->a)
				{
					philipsFactor = [[NSString stringWithCString: val->a] floatValue];
					NSLog( @"philipsFactor = %f", philipsFactor);
				}
			}
			err = Papy3GroupFree (&theGroupP, TRUE);
		}
		
#pragma mark compute normal vector
			
		orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
		orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
		orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
		
		if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
		{
		//	NSLog(@"Saggital");
			sliceLocation = originX;
		}
		
		if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
		{
		//	NSLog(@"Coronal");
			sliceLocation = originY;
		}
		
		if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
		{
		//	NSLog(@"Axial");
			sliceLocation = originZ;
		}
		
		
#pragma mark read pixel data	
//		if( pixArray == 0L) maxFrame = 1;
		
//		for( ee = 0; ee < maxFrame; ee++)
		{
			DCMPix	*imPix = 0L;
			
//			if( maxFrame > 1)
//			{
//				imPix = [pixArray objectAtIndex: ee];
//				[imPix copyFromOther: self];
//			}
//			else
			{
				imPix = self;
				ee = imageNb-1;
			}

//	NSLog( @"PAPY frame ee: %d", ee);
			// position the file pointer to the begining of the data set 
			err = Papy3GotoNumber (fileNb, (PapyShort) ee+1, DataSetID);
			
			// then goto group 0x7FE0 
			if ((err = Papy3GotoGroupNb (fileNb, 0x7FE0)) == 0)
			{
				// read group 0x7FE0 from the file 
				if ((err = Papy3GroupRead (fileNb, &theGroupP)) > 0) 
				{
					if( gArrCompression [fileNb] == JPEG_LOSSLESS || gArrCompression [fileNb] == JPEG_LOSSY)
					{
						if(gArrPhotoInterpret [fileNb] == RGB) fPlanarConf = 0;
					}
					
					// PIXEL DATA
					[PapyrusLock lock];
					oImage = (short *)Papy3GetPixelData (fileNb, ee+1, theGroupP, ImagePixel);
					[PapyrusLock unlock];
					
					if( oImage == 0L) // It's probably a problem with JPEG... try to convert to classic DICOM with DCMTK dcmdjpeg
					{
						oImage = (short *) [self UncompressDICOM :srcFile :imageNb];
					}
					
					if( oImage == 0L)
					{
						NSLog(@"This is really bad..... Please send this file to rossetantoine@bluewin.ch");
						oImage = malloc( height * width * 2);
						gArrPhotoInterpret [fileNb] = MONOCHROME2;
						
						long yo = 0;
						for( i = 0 ; i < height * width; i++)
						{
							oImage[ i] = yo++;
							if( yo>= width) yo = 0;
						}
					}
					
					if( gArrPhotoInterpret [fileNb] == MONOCHROME1) // INVERSE IMAGE!
					{
						inverseVal = YES;
						savedWL = -savedWL;
					}
					else inverseVal = NO;
					
					isRGB = NO;
					
					if (gArrPhotoInterpret [fileNb] == YBR_FULL ||
						gArrPhotoInterpret [fileNb] == YBR_FULL_422 ||
						gArrPhotoInterpret [fileNb] == YBR_PARTIAL_422)
					{
						NSLog(@"YBR WORLD");
						
						char *rgbPixel = (char*) [self ConvertYbrToRgb:(unsigned char *) oImage :realwidth :height :gArrPhotoInterpret [fileNb] :(char) fPlanarConf];
						fPlanarConf = 0;	//ConvertYbrToRgb -> planar is converted
						
						efree3 ((void **) &oImage);
						oImage = (short*) rgbPixel;
					}
					
					// This image has a palette -> Convert it to a RGB image !
					if( fSetClut)
					{
						if( clutRed != 0L && clutGreen != 0L && clutBlue != 0L)
						{
							unsigned char   *bufPtr = (unsigned char*) oImage;
							unsigned short	*bufPtr16 = (unsigned short*) oImage;
							unsigned char   *tmpImage;
							long			loop, totSize, pixelR, pixelG, pixelB, x, y;

							totSize = (long) ((long) height * (long) realwidth * 3L);
							tmpImage = malloc( totSize);
							
						//	if( bitsAllocated != 8) NSLog(@"Palette with a non-8 bit image???");
							
							switch( bitsAllocated)
							{
								case 8:
									for( y = 0; y < height; y++)
									{
										for( x = 0; x < width; x++)
										{
											pixelR = pixelG = pixelB = bufPtr[y*width + x];
											
											if( pixelR > clutEntryR) {	pixelR = clutEntryR-1;}
											if( pixelG > clutEntryG) {	pixelG = clutEntryG-1;}
											if( pixelB > clutEntryB) {	pixelB = clutEntryB-1;}
											
											tmpImage[y*width*3 + x*3 + 0] = clutRed[ pixelR];
											tmpImage[y*width*3 + x*3 + 1] = clutGreen[ pixelG];
											tmpImage[y*width*3 + x*3 + 2] = clutBlue[ pixelB];
										}
									}
								break;
								
								case 16:
									#if __BIG_ENDIAN__
									InverseShorts( (vector unsigned short*) oImage, height * realwidth);
									#endif
									
									for( y = 0; y < height; y++)
									{
										for( x = 0; x < width; x++)
										{
											pixelR = pixelG = pixelB = bufPtr16[y*width + x];
											
										//	if( pixelR > clutEntryR) {	pixelR = clutEntryR-1;}
										//	if( pixelG > clutEntryG) {	pixelG = clutEntryG-1;}
										//	if( pixelB > clutEntryB) {	pixelB = clutEntryB-1;}
											
											tmpImage[y*width*3 + x*3 + 0] = clutRed[ pixelR];
											tmpImage[y*width*3 + x*3 + 1] = clutGreen[ pixelG];
											tmpImage[y*width*3 + x*3 + 2] = clutBlue[ pixelB];
										}
									}
									bitsAllocated = 8;
								break;
							}
							isRGB = YES;
							
							efree3 ((void **) &oImage);
							oImage = (short*) tmpImage;
						}
					}
					
					if( fSetClut16)
					{
						unsigned short	*bufPtr = (unsigned short*) oImage;
						unsigned char   *tmpImage;
						long			loop, totSize, x, y, ii;
						unsigned short pixel;
						
						totSize = (long) ((long) height * (long) realwidth * 3L);
						tmpImage = malloc( totSize);
						
						if( bitsAllocated != 16) NSLog(@"Segmented Palette with a non-16 bit image???");
						
						ii = height * realwidth;
						
						#if __ppc__ || __ppc64__
						if( Altivec)
						{
							InverseShorts( (vector unsigned short*) oImage, ii);
						}
						else
						#endif
						
						#if __BIG_ENDIAN__
						{
							PapyUShort	 *theUShortP = (PapyUShort *) oImage;
							PapyUShort val;
							  
							while( ii-- > 0)
							{
								val = *theUShortP;
								*theUShortP++ = (val >> 8) | (val << 8);   // & 0x00FF  --  & 0xFF00
							}
						}
						#endif
						
						for( y = 0; y < height; y++)
						{
							for( x = 0; x < width; x++)
							{
								pixel = bufPtr[y*width + x];
								tmpImage[y*width*3 + x*3 + 0] = shortRed[ pixel];
								tmpImage[y*width*3 + x*3 + 1] = shortGreen[ pixel];
								tmpImage[y*width*3 + x*3 + 2] = shortBlue[ pixel];
							}
						}
						
						isRGB = YES;
						
						efree3 ((void **) &oImage);
						oImage = (short*) tmpImage;
						
						free( shortRed);
						free( shortGreen);
						free( shortBlue);
					}
					
					// we need to know how the pixels are stored
					if (isRGB == YES ||
						gArrPhotoInterpret [fileNb] == RGB ||
						gArrPhotoInterpret [fileNb] == YBR_FULL ||
						gArrPhotoInterpret [fileNb] == YBR_FULL_422 ||
						gArrPhotoInterpret [fileNb] == YBR_PARTIAL_422 ||
						gArrPhotoInterpret [fileNb] == YBR_ICT ||
						gArrPhotoInterpret [fileNb] == YBR_RCT)
					{
						
						unsigned char   *ptr, *tmpImage;
						long			loop, totSize;
						
						isRGB = YES;
						
						// CONVERT RGB TO ARGB FOR BETTER PERFORMANCE THRU VIMAGE
						
						totSize = (long) ((long) height * (long) realwidth * 4L);
						tmpImage = malloc( totSize);
						if( tmpImage)
						{
							ptr    = tmpImage;
							
							if( bitsAllocated > 8) // RGB - 16 bits
							{
								unsigned short   *bufPtr;
								bufPtr = (unsigned short*) oImage;
								
								#if __BIG_ENDIAN__
								InverseShorts( (vector unsigned short*) oImage, height * realwidth * 3);
								#endif
								
								if( fPlanarConf > 0)	// PLANAR MODE
								{
									long imsize = (long) height * (long) realwidth;
									long x = 0;
									
									loop = totSize/4;
									while( loop-- > 0)
									{
										*ptr++	= 255;			//ptr++;
										*ptr++	= bufPtr[ 0 * imsize + x];		//ptr++;  bufPtr++;
										*ptr++	= bufPtr[ 1 * imsize + x];		//ptr++;  bufPtr++;
										*ptr++	= bufPtr[ 2 * imsize + x];		//ptr++;  bufPtr++;
										
										x++;
									}
								}
								else
								{
									loop = totSize/4;
									while( loop-- > 0)
									{
										*ptr++	= 255;			//ptr++;
										*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
										*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
										*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
									}
								}
							}
							else
							{
								unsigned char   *bufPtr;
								bufPtr = (unsigned char*) oImage;
								
								if( fPlanarConf > 0)	// PLANAR MODE
								{
									long imsize = (long) height * (long) realwidth;
									long x = 0;
									
									loop = totSize/4;
									while( loop-- > 0)
									{
										
										*ptr++	= 255;			//ptr++;
										*ptr++	= bufPtr[ 0 * imsize + x];		//ptr++;  bufPtr++;
										*ptr++	= bufPtr[ 1 * imsize + x];		//ptr++;  bufPtr++;
										*ptr++	= bufPtr[ 2 * imsize + x];		//ptr++;  bufPtr++;
										
										x++;
									}
								}
								else
								{
									loop = totSize/4;
									while( loop-- > 0)
									{
									//	#if __BIG_ENDIAN__
										*ptr++	= 255;				//ptr++;
										*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
										*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
										*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
									//	#else
									//	*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
									//	*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
									//	*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
									//	*ptr++	= 255;				//ptr++;
									//	#endif
									}
								}
							}
							efree3 ((void **) &oImage);
							oImage = (short*) tmpImage;
						}
												
					}
					else if( bitsAllocated == 8)	// Black & White 8 bit image -> 16 bits image
					{
						unsigned char   *bufPtr;
						short			*ptr, *tmpImage;
						long			loop, totSize;
						
						totSize = (long) ((long) height * (long) realwidth * 2L);
						tmpImage = malloc( totSize);
						
						bufPtr = (unsigned char*) oImage;
						ptr    = tmpImage;
						
						loop = totSize/2;
						while( loop-- > 0)
						{
							*ptr++ = *bufPtr++;
						//	ptr++; bufPtr ++;
						}
						
						efree3 ((void **) &oImage);
						oImage =  (short*) tmpImage;
					}
//					else if( bitsStored != 16 && fIsSigned == YES && bitsAllocated == 16)
//					{
//						long totSize = (long) ((long) height * (long) realwidth * 2L);
//						
//						[self convertToFull16Bits: (unsigned short*) oImage size: totSize BitsAllocated: bitsAllocated BitsStored: bitsStored HighBitPosition: highBit PixelSign: fIsSigned];
//					}
					
					if( realwidth != width)
					{
						NSLog(@"Update width");
						if( isRGB)
						{
							char	*ptr = (char*) oImage;
							for( i = 0; i < height;i++)
							{
								memmove( ptr + i*width*4, ptr + i*realwidth*4, width*4);
							}
						}
						else
						{
							if( bitsAllocated == 32)
							{
								for( i = 0; i < height;i++)
								{
									memmove( oImage + i*width*2, oImage + i*realwidth*2, width*4);
								}
							}
							else
							{
								for( i = 0; i < height;i++)
								{
									memmove( oImage + i*width, oImage + i*realwidth, width*2);
								}
							}
						}
					}
					
					//if( fIsSigned == YES && 
					
					// free group 7FE0 
					err = Papy3GroupFree (&theGroupP, TRUE);
				} // endif ...group 7FE0 read 
			}
			

#pragma mark RGB or fPlanar

			//***********
			if( isRGB)
			{
				if( imPix->fVolImage)
				{
					imPix->fImage = imPix->fVolImage;
					memcpy( imPix->fImage, oImage, width*height*sizeof(float));
					free(oImage);
				}
				else imPix->fImage = (float*) oImage;
				oImage = 0L;
				
				if( oData && [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayDICOMOverlays"] )
				{
					unsigned char	*rgbData = (unsigned char*) imPix->fImage;
					long			y, x;
					
					for( y = 0; y < oRows; y++)
					{
						for( x = 0; x < oColumns; x++)
						{
							if( oData[ y * oColumns + x])
							{
								rgbData[ y * width*4 + x*4 + 1] = 0xFF;
								rgbData[ y * width*4 + x*4 + 2] = 0xFF;
								rgbData[ y * width*4 + x*4 + 3] = 0xFF;
							}
						}
					}
				}
			}
			else
			{
				if( bitsAllocated == 32)
				{
					unsigned long	*uslong = (unsigned long*) oImage;
					long			*slong = (long*) oImage;
					float			*tDestF;
					
					if( imPix->fVolImage)
					{
						tDestF = imPix->fImage = imPix->fVolImage;
					}
					else
					{
						tDestF = imPix->fImage = malloc(width*height*sizeof(float) + 100);
					}
					
					if( fIsSigned)
					{
						long x = height * width;
						while( x-->0)
						{
							*tDestF++ = ((float) (*slong++)) * slope + offset;
						}
					}
					else
					{
						long x = height * width;
						while( x-->0)
						{
							*tDestF++ = ((float) (*uslong++)) * slope + offset;
						}
					}
					
					free(oImage);
					oImage = 0L;
				}
				else
				{
					if( oImage)
					{
						vImage_Buffer src16, dstf;
						
						dstf.height = src16.height = height;
						dstf.width = src16.width = width;
						src16.rowBytes = width*2;
						dstf.rowBytes = width*sizeof(float);
						
						src16.data = oImage;
						
						if( VOILUT_number != 0 && VOILUT_depth != 0 && VOILUT_table != 0L)
						{
							[self setVOILUT:VOILUT_first number:VOILUT_number depth:VOILUT_depth table:VOILUT_table image:(unsigned short*) oImage isSigned: fIsSigned];
							
							free( VOILUT_table);
							VOILUT_table = 0L;
						}

						if( imPix->fVolImage)
						{
							imPix->fImage = imPix->fVolImage;
						}
						else
						{
							imPix->fImage = malloc(width*height*sizeof(float) + 100);
						}
						
						dstf.data = imPix->fImage;
						
						if( fIsSigned)
						{
							vImageConvert_16SToF( &src16, &dstf, offset, slope, 0);
						}
						else
						{
							vImageConvert_16UToF( &src16, &dstf, offset, slope, 0);
						}
						
						if( inverseVal)
						{
							float neg = -1;
							vDSP_vsmul( fImage, 1, &neg, fImage, 1, height * width);
						}
						
						free(oImage);
					}
					oImage = 0L;
				}
				
				if( oData && [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayDICOMOverlays"] )
				{
					long			y, x;
					
					for( y = 0; y < oRows; y++)
					{
						for( x = 0; x < oColumns; x++)
						{
							if( oData[ y * oColumns + x]) imPix->fImage[ y * width + x] = 0xFF;
						}
					}
				}
			}
			//***********
			
		//	endTime = MyGetTime();
		//	NSLog([ NSString stringWithFormat: @"%d", ((long) (endTime - startTime))/1000 ]);
			
			if( pixmin == 0 && pixmax == 0)
			{
				wl = 0;
				ww = 0; //Computed later, only if needed
			}
			else
			{
				wl = pixmin + (pixmax - pixmin)/2;
				ww = (pixmax - pixmin);
			}
			
			if( savedWW != 0)
			{
				wl = savedWL;
				ww = savedWW;
			}
			
			if( clutRed) free( clutRed);
			if( clutGreen) free( clutGreen);
			if( clutBlue) free( clutBlue);
		}
		
		[PapyrusLock lock];
		
		// close and free the file and the associated allocated memory 
		Papy3FileClose (fileNb, TRUE);
			
		[PapyrusLock unlock];

		
		return YES;
	}
	
	return NO;
}

- (BOOL) isDICOMFile:(NSString *) file
{
BOOL            readable = YES;

	if( imageObj)
	{
		if( [[imageObj valueForKey:@"fileType"] isEqualToString:@"DICOM"] == NO) readable = NO;
	}
	else
	{
		readable = [DicomFile isDICOMFile: file];
    }
	
    return readable;
}

- (void) getDataFromNSImage:(NSImage*) otherImage
{
	int x, y;
	
	NSBitmapImageRep	*TIFFRep = [[NSBitmapImageRep alloc] initWithData: [otherImage TIFFRepresentation]];
	
	height = [TIFFRep pixelsHigh];
	height /= 2;
	height *= 2;
	int realwidth = [TIFFRep pixelsWide];
	width = realwidth/2;
	width *= 2;
	rowBytes = [TIFFRep bytesPerRow];
	oImage = 0L;
	
	unsigned char *srcImage = [TIFFRep bitmapData];
	unsigned char *argbImage = 0L, *srcPtr = 0L, *tmpPtr = 0L;
	
	int totSize = height * width * 4;
	if( fVolImage)
	{
		argbImage =	(unsigned char*) fVolImage;
	}
	else
	{
		argbImage = malloc( totSize);
	}
	
	switch( [TIFFRep bitsPerPixel])
	{
		case 8:
			NSLog(@"8 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < height; y++)
			{
				srcPtr = srcImage + y*rowBytes;
				
				x = width;
				while( x-->0)
				{
					tmpPtr++;
					*tmpPtr++ = *srcPtr;
					*tmpPtr++ = *srcPtr;
					*tmpPtr++ = *srcPtr;
					srcPtr++;
				}
			}
		break;
		
		case 32:
			NSLog(@"32 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < height; y++)
			{
				srcPtr = srcImage + y*rowBytes;
				
				x = width;
				while( x-->0)
				{
					tmpPtr++;
					*tmpPtr++ = *srcPtr++;
					*tmpPtr++ = *srcPtr++;
					*tmpPtr++ = *srcPtr++;
					srcPtr++;
				}
				
				//BlockMoveData( srcPtr, tmpPtr, width*4);
				//tmpPtr += width*4;
			}
		break;
		
		case 24:
			NSLog(@"24 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < height; y++)
			{
				srcPtr = srcImage + y*rowBytes;
				
				x = width;
				while( x-->0)
				{
					tmpPtr++;
					
					*((short*)tmpPtr) = *((short*)srcPtr);
					tmpPtr+=2;
					srcPtr+=2;
					
					*tmpPtr++ = *srcPtr++;

//									tmpPtr++;
//									*tmpPtr++ = srcPtr[ 1];
//									*tmpPtr++ = srcPtr[ 0];
//									*tmpPtr++ = srcPtr[ 2];
//									
//									srcPtr += 3;
				}
			}
		break;
		
		case 48:
			NSLog(@"48 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < height; y++)
			{
				srcPtr = srcImage + y*rowBytes;
				
				x = width;
				while( x-->0)
				{
					tmpPtr++;
					*tmpPtr++ = *srcPtr;	srcPtr += 2;
					*tmpPtr++ = *srcPtr;	srcPtr += 2;
					*tmpPtr++ = *srcPtr;	srcPtr += 2;
				}
				
				//BlockMoveData( srcPtr, tmpPtr, width*4);
				//tmpPtr += width*4;
			}
		break;
		
		default:
			NSLog(@"Error - Unknow...");
		break;
	}
	
	fImage = (float*) argbImage;
	rowBytes = width * 4;
	// TEST IF Black&White -> Convert to float -> Faster....???
//				BOOL BW;
//				i = height * width;
//				i /= 16;
//				
//				while( i -- > 0 && BW == YES)
//				{
//					if( argbImage[ (i*16*4)+1] == argbImage[ (i*16*4)+2] == argbImage[ (i*16*4)+3])
//					{
//						BW = NO;
//					}
//				}
//				
//				if( BW)
//				{
//					NSLog(@"JPEG -> BW conversion");
//					
//					i = height * width;
//					while( i-->0)
//					{
//						fImage[ i] = (argbImage[ (i*4)+1] +  argbImage[ (i*4)+2] + argbImage[ (i*4)+3]) / 3;
//					}
//					
//					isRGB = NO;
//				}
//				else
	{
		isRGB = YES;
	}
	
	[TIFFRep release];

}

- (void) getFrameFromMovie:(NSString*) extension
{
	
	if( [extension isEqualToString:@"mov"] == YES ||
		[extension isEqualToString:@"mpg"] == YES ||
		[extension isEqualToString:@"mpeg"] == YES ||
		[extension isEqualToString:@"avi"] == YES)
		{
			NSTask			*theTask = [[NSTask alloc] init];
			
			NSImage *frame = 0L;
			
			[theTask setArguments: [NSArray arrayWithObjects:@"getFrame", srcFile, [NSString stringWithFormat:@"%d", frameNo], 0L]];
			[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Quicktime"]];
			[theTask launch];
			while( [theTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
			//	[theTask waitUntilExit]; <- The problem with this: it calls the current running loop.... problems with current Lock !
			[theTask release];
		
			//[self getDataFromNSImage: [result objectAtIndex: 0]];
		}
}

- (void) CheckLoadIn
{
	BOOL USECUSTOMTIFF = NO;

	#ifdef USEVIMAGE
	if( fImage == 0L)
	#else
	if( oImage == 0L)
	#endif
	 {
		BOOL	success = NO;
		
		if( srcFile == 0L) return;
		
		if( isBonjour)
		{
			// LOAD THE FILE FROM BONJOUR SHARED DATABASE
			
			[srcFile release];
			srcFile = 0L;
			srcFile = [[BrowserController currentBrowser] getLocalDCMPath: imageObj :0];
			[srcFile retain];
			
			if( srcFile == 0L)
			{
				return;
			}
		}
		
		if( [self isDICOMFile: srcFile])
		{
			if (DEBUG)
				NSLog(@"checkLoad isDICOM: %@", srcFile);
			
			// PLEASE, KEEP BOTH FUNCTIONS FOR TESTING PURPOSE. THANKS
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"USEPAPYRUSDCMPIX"])
			{
				success = [self loadDICOMPapyrus];
				//only try again if is strict DICOM
				if (success == NO && [DCMObject isDICOM:[NSData dataWithContentsOfFile:srcFile]])
					success = [self loadDICOMDCMFramework];
					
				if (success == NO)
				{
					convertedDICOM = [convertDICOM( srcFile) retain];
					success = [self loadDICOMPapyrus];
					
					if( success == YES && imageObj != 0L)
					{
						if( [[imageObj valueForKey:@"inDatabaseFolder"] boolValue])
						{
							[[NSFileManager defaultManager] removeFileAtPath:srcFile handler: 0L];
							[[NSFileManager defaultManager] movePath:convertedDICOM toPath:srcFile handler: 0L];
							
							[convertedDICOM release];
							convertedDICOM = 0L;
						}
					}
				}
			}
			else
			{
				success = [self loadDICOMDCMFramework];
				if (success == NO && [DCMObject isDICOM:[NSData dataWithContentsOfFile:srcFile]])
					success = [self loadDICOMPapyrus];
				
				if (success == NO)
				{
					convertedDICOM = [convertDICOM( srcFile) retain];
					success = [self loadDICOMDCMFramework];
					
					if( success == YES && imageObj != 0L)
					{
						if( [[imageObj valueForKey:@"inDatabaseFolder"] boolValue])
						{
							[[NSFileManager defaultManager] removeFileAtPath:srcFile handler: 0L];
							[[NSFileManager defaultManager] movePath:convertedDICOM toPath:srcFile handler: 0L];
							
							[convertedDICOM release];
							convertedDICOM = 0L;
						}
					}
				}
			}
			
			[self checkSUV];
			
			[pool release];
		}
		
		if( success == NO)	// Is it a NON-DICOM IMAGE ??
		{
			int				realwidth, realheight;
			PapyShort		fileNb, imageNb, err, theErr;
			PapyULong		nbVal, i, pos;
			unsigned char   *clutRed = 0L, *clutGreen = 0L, *clutBlue = 0L;

			NSImage		*otherImage = 0L;
			NSString	*extension = [[srcFile pathExtension] lowercaseString];
			
			id fileFormatBundle;
			if (fileFormatBundle = [fileFormatPlugins objectForKey:[srcFile pathExtension]]) {
				PluginFileFormatDecoder *decoder = [[[fileFormatBundle principalClass] alloc] init];
				fImage = [decoder checkLoadAtPath:srcFile];
				//NSLog(@"decoder width %d", [decoder width]);
				width = [[decoder width] intValue];
				//width = 832;
				//NSLog(@"width %d : %d", width, [decoder width]);
				height = [[decoder height] intValue];
				//NSLog(@"height %d : %d", height, [decoder height]);
				isRGB = [decoder isRGB];
				rowBytes = [[decoder rowBytes] intValue];				
				[decoder release];					
							
			}
			else if( [extension isEqualToString:@"zip"] == YES)  // ZIP
			{
				// the ZIP icon
				NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:srcFile];
				// make it big
				[icon setSize:NSMakeSize(128,128)];
				
				NSBitmapImageRep *TIFFRep = [[NSBitmapImageRep alloc] initWithData: [icon TIFFRepresentation]];

				// size of the image
				height = [TIFFRep pixelsHigh];
				height /= 2;
				height *= 2;
				realwidth = [TIFFRep pixelsWide];
				width = realwidth/2;
				width *= 2;
				rowBytes = [TIFFRep bytesPerRow];
				oImage = 0L;
				
				long totSize;
				totSize = height * width * 4;
				
				unsigned char *argbImage;
				if( fVolImage)
				{
					argbImage =	(unsigned char*) fVolImage;
				}
				else
				{
					argbImage = malloc( totSize);
				}
				
				unsigned char *srcImage = [TIFFRep bitmapData];
				unsigned char *tmpPtr = argbImage, *srcPtr;
				
				long x, y;
				for( y = 0 ; y < height; y++)
				{
					srcPtr = srcImage + y*rowBytes;
					x = width;
					while( x-->0)
					{
						tmpPtr++;
						*tmpPtr++ = *srcPtr++;
						*tmpPtr++ = *srcPtr++;
						*tmpPtr++ = *srcPtr++;
						srcPtr++;
					}
				}

				fImage = (float*) argbImage;
				rowBytes = width * 4;
				isRGB = YES;
				[TIFFRep release];
			}
			else if( [extension isEqualToString:@"lsm"] == YES)  // LSM
			{
				[self LoadLSM];
			}
			else if( [extension isEqualToString:@"pic"] == YES)
			{
				[self LoadBioradPic];
			}
			else if( [DicomFile isFVTiffFile:srcFile])
			{
				[self LoadFVTiff];
			}
			else if( [extension isEqualToString:@"hdr"] == YES) // ANALYZE
			{
				if ([[NSFileManager defaultManager] fileExistsAtPath:[[srcFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] == YES)
				{
					NSData		*file = [NSData dataWithContentsOfFile: srcFile];
					
					if( [file length] == 348)
					{
						long			totSize;
						struct dsr*		Analyze;
						NSData			*fileData;
						BOOL			intelByteOrder = NO;
						
						Analyze = (struct dsr*) [file bytes];
						
						short endian = Analyze->dime.dim[ 0];		// dim[0] 
						if ((endian < 0) || (endian > 15)) 
						{
							intelByteOrder = YES;
						}
						
						height = Analyze->dime.dim[ 2];
						if( intelByteOrder) height = Endian16_Swap( height);
						realheight = height;
						height /= 2;
						height *= 2;
						width = Analyze->dime.dim[ 1];
						if( intelByteOrder) width = Endian16_Swap( width);
						realwidth = width;
						width /= 2;
						width *= 2;
						
						pixelSpacingX = Analyze->dime.pixdim[ 1];
						if( intelByteOrder) ConvertFloatToNative( &pixelSpacingX);
						pixelSpacingY = Analyze->dime.pixdim[ 2];
						if( intelByteOrder) ConvertFloatToNative( &pixelSpacingY);
						sliceThickness = sliceInterval = Analyze->dime.pixdim[ 3];
						if( intelByteOrder) ConvertFloatToNative( &sliceThickness);
						if( intelByteOrder) ConvertFloatToNative( &sliceInterval);
						
						totSize = realheight * realwidth * 2;
						oImage = malloc( totSize);
						
						fileData = [[NSData alloc] initWithContentsOfFile: [[srcFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]];
						
						short datatype = Analyze->dime.datatype;
						if( intelByteOrder) datatype = Endian16_Swap( datatype);
						
						switch( datatype)
						{
							case 2:
							{
								unsigned char   *bufPtr;
								short			*ptr, *tmpImage;
								long			loop;
								
								bufPtr = (unsigned char*) [fileData bytes]+ frameNo*(realheight * realwidth);
								ptr    = oImage;
								
								loop = totSize/2;
								while( loop-- > 0)
								{
									*ptr++ = *bufPtr++;
								}
							}
							break;
							
							case 4:
								memcpy( oImage, [fileData bytes] + frameNo*(realheight * realwidth * 2), realheight * realwidth * 2);
								if( intelByteOrder)
								{
									long			loop;
									short			*ptr = oImage;
									
									loop = realheight * realwidth;
									while( loop-- > 0)
									{
										*ptr = Endian16_Swap( *ptr);
										ptr++;
									}
								}
							break;
							
							case 8:
							{
								unsigned int   *bufPtr;
								short			*ptr, *tmpImage;
								long			loop;
								
								bufPtr = (unsigned int*) [fileData bytes]+ frameNo * (realheight * realwidth)*4;
								ptr    = oImage;
								
								loop = totSize/2;
								while( loop-- > 0)
								{
									if( intelByteOrder)  *ptr++ = Endian32_Swap( *bufPtr++);
									else *ptr++ = *bufPtr++;
								}
							}
							break; 
							
							case 16:
								if( fVolImage)
								{
									fImage = fVolImage;
								}
								else
								{
									fImage = malloc(width*height*sizeof(float) + 100);
								}
								
								for( i = 0; i < height;i++)
								{
									memcpy( fImage + i * width, [fileData bytes]+ frameNo * (realheight * realwidth)*sizeof(float) + i*realwidth*sizeof(float), width*sizeof(float));
								}
								
								free(oImage);
								oImage = 0L;
							break; 
							
							case 128:
//								fi.fileType = FileInfo.RGB_PLANAR; 		// DT_RGB
//								bitsallocated = 24;
								NSLog(@"unsupported... please send me this file");
							break; 
						}
						
						[fileData release];
						
													
						// CONVERSION TO FLOAT
						
						if( datatype != 16)
						{
							if( width != realwidth)
							{
								for( i = 0; i < height;i++)
								{
									memmove( oImage + i*width, oImage + i*realwidth, width*2);
								}
							}

							vImage_Buffer src16, dstf;
							
							dstf.height = src16.height = height;
							dstf.width = src16.width = width;
							src16.rowBytes = width*2;
							dstf.rowBytes = width*sizeof(float);
							
							src16.data = oImage;
							
							if( fVolImage)
							{
								fImage = fVolImage;
							}
							else
							{
								fImage = malloc(width*height*sizeof(float) + 100);
							}
							
							dstf.data = fImage;
							
							vImageConvert_16SToF( &src16, &dstf, 0, 1, 0);
							
							free(oImage);
							oImage = 0L;
						}
					}
				}
			}
			else if( [extension isEqualToString:@"jpg"] == YES ||
				[extension isEqualToString:@"jpeg"] == YES ||
				[extension isEqualToString:@"pdf"] == YES ||
				[extension isEqualToString:@"pct"] == YES ||
				[extension isEqualToString:@"png"] == YES ||
				[extension isEqualToString:@"gif"] == YES)
				{
					otherImage = [[NSImage alloc] initWithContentsOfFile:srcFile];
				}
			
			else if(	[extension isEqualToString:@"tiff"] == YES ||
						[extension isEqualToString:@"stk"] == YES ||
						[extension isEqualToString:@"tif"] == YES)
				{
					TIFF* tif = TIFFOpen([srcFile UTF8String], "r");
					if( tif)
					{
							short   bpp, count, tifspp;
							
							TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bpp);
							TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &tifspp);
							
							if( bpp == 16 || bpp == 32 || bpp == 8)
							{
								if( tifspp == 1) USECUSTOMTIFF = YES;
							}
							
							count = 1;
							while (TIFFReadDirectory(tif))
								count++;
															
							if( count != 1) USECUSTOMTIFF = YES;
							
							TIFFClose(tif);
					}
					
					if( USECUSTOMTIFF == NO)
					{
						otherImage = [[NSImage alloc] initWithContentsOfFile:srcFile];
					}
				}
			
			if( otherImage != 0L || USECUSTOMTIFF == YES)
			{
				unsigned char   *argbImage, *tmpPtr, *srcPtr, *srcImage;
				long			i, x, y, totSize;
				
				if( USECUSTOMTIFF) // Is it a 16/32-bit TIFF not supported by Apple???
				{
					[self LoadTiff:frameNo];

				}
				else
				{
					[otherImage setBackgroundColor: [NSColor whiteColor]];
				
					if( [extension isEqualToString:@"pdf"])
					{
						NSSize			newSize = [otherImage size];
						
						newSize.width *= 1.5;		// Increase PDF resolution to 72 * 1.5 DPI !
						newSize.height *= 1.5;		// KEEP THIS VALUE IN SYNC WITH DICOMFILE.M
						
						[otherImage setScalesWhenResized:YES];
						[otherImage setSize: newSize];
						
						id tempID = [otherImage bestRepresentationForDevice:0L];
						
						if([tempID isKindOfClass: [NSPDFImageRep class]])
						{
							NSPDFImageRep		*pdfRepresentation = tempID;
							
							[pdfRepresentation setCurrentPage:frameNo];
						}
					}
					
					[self getDataFromNSImage: otherImage];
				}
				
				if( otherImage) [otherImage release];
			}
			else	// It's a Movie ??
			{
				#if !__LP64__
				NSMovie *movie = 0L;
				
				if( [extension isEqualToString:@"mov"] == YES ||
					[extension isEqualToString:@"mpg"] == YES ||
					[extension isEqualToString:@"mpeg"] == YES ||
					[extension isEqualToString:@"avi"] == YES)
					{
						movie = [[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:srcFile] byReference:NO];
					}
				
				if( movie)
				{
					Movie			mov = [movie QTMovie];
					TimeValue		aTime = 0;
					OSType			mediatype = 'eyes';
					long			curFrame;
					Rect			tempRect;
					GWorldPtr		ftheGWorld = 0L;
					PixMapHandle 	pixMapHandle;
					Ptr				pixBaseAddr;
					
					GetMovieBox (mov, &tempRect);
					OffsetRect (&tempRect, -tempRect.left, -tempRect.top);
					
					NewGWorld (   &ftheGWorld,
								 32,			// 32 Bits color !
								 &tempRect,
								 0,
								 NULL,
								 (GWorldFlags) keepLocal);
					
					SetMovieGWorld (mov, ftheGWorld, 0L);
					SetMovieActive (mov, TRUE);
					SetMovieBox (mov, &tempRect);
					
					curFrame = 0;
					while (aTime != -1 && curFrame != frameNo)
					{
						GetMovieNextInterestingTime (   mov,
													   nextTimeMediaSample,
													   1,
													   &mediatype,
													   aTime,
													   1,
													   &aTime,
													   0L);
						if (aTime != -1) curFrame++;
					}

					SetMovieTimeValue (mov, aTime);
					UpdateMovie (mov);
					MoviesTask (mov, 0);
					
					// We have the image...
					
					pixMapHandle = GetGWorldPixMap(ftheGWorld);
					LockPixels (pixMapHandle);
					pixBaseAddr = GetPixBaseAddr(pixMapHandle);
					
					unsigned char   *argbImage, *tmpPtr, *srcPtr, *srcImage;
					long			i, x, y, totSize;
					
					height = tempRect.bottom;
					height /= 2;
					height *= 2;
					realwidth = tempRect.right;
					width = realwidth/2;
					width *= 2;
					rowBytes = GetPixRowBytes(pixMapHandle);
					oImage = 0L;
					srcImage = (unsigned char*) pixBaseAddr;

					totSize = height * width * 4;
					
					if( fVolImage)
					{
						argbImage =	(unsigned char*) fVolImage;
					}
					else
					{
						argbImage = malloc( totSize);
					}
					
					tmpPtr = argbImage;
					for( y = 0 ; y < height; y++)
					{
						srcPtr = srcImage + y*rowBytes;
						memcpy( tmpPtr, srcPtr, width*4);
						tmpPtr += width*4;
					}
					
					UnlockPixels (pixMapHandle);
					
					rowBytes = width * 4;
					fImage = (float*) argbImage;
					isRGB = YES;
					
					DisposeGWorld( ftheGWorld);
					
					[movie release];
				}
				#endif
				
//				[self getFrameFromMovie: extension];
			}
		}
		
		if( fImage == 0L)
		{
			long i;
			
			NSLog(@"not able to load the image...");
			
			if( fVolImage)
			{
				fImage = fVolImage;
			}
			else
			{
				fImage = malloc( 256 * 256 * 4);
			}
			
			height = 256;
			rowBytes = width = 256;
			oImage = 0L;
			isRGB = NO;
			
			for( i = 0; i < 256*256; i++) fImage[ i] = i;
		}
		
		if( isRGB)	// COMPUTE ALPHA MASK = ALPHA = R+G+B/3
		{
			unsigned char*	argbPtr = (unsigned char*) fImage;
			long			ss = width * height;
			
			while( ss-->0)
			{
				*argbPtr = (*(argbPtr+1) + *(argbPtr+2) + *(argbPtr+3)) / 3;
				argbPtr+=4;
			}
		}
	}
}

-(void) CheckLoad
{
	// uses DCMPix class variable NSString *srcFile to load (CheckLoadIn method), for the first time or again, an fImage or oImage....

	[checking lock];
	
	[self CheckLoadIn];
	
	[checking unlock];
}

- (void) setBaseAddr :( char*) ptr
{
	baseAddr = ptr;
	[image SetxNSImage: (unsigned char*) baseAddr];
}

- (char*) baseAddr
{
    [self CheckLoad];
	
	if( baseAddr == 0L) [self computeWImage: NO: ww :wl];
	
    return baseAddr;
}

# pragma mark-

-(void) orientation:(float*) c
{
	long i;
	
	for( i = 0 ; i < 9; i ++) c[ i] = orientation[ i];
}

-(void) setOrientation:(float*) c
{
	long i;
	
	for( i = 0 ; i < 6; i ++) orientation[ i] = c[ i];
	
	// Compute normal vector
	orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
	orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
	orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
	
//	NSLog(@"Before: %f %f %f", orientation[6], orientation[7], orientation[8]);
//	
//	float length = sqrt(orientation[6]*orientation[6] + orientation[7]*orientation[7] + orientation[8]*orientation[8]);
//
//   orientation[6] = orientation[ 6] / length;
//   orientation[7] = orientation[ 7] / length;
//   orientation[8] = orientation[ 8] / length;
//   
//   NSLog(@"After: %f %f %f", orientation[6], orientation[7], orientation[8]);

}

-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d {
	d[0] = originX + y*orientation[3]*pixelSpacingY + x*orientation[0]*pixelSpacingX;
	d[1] = originY + y*orientation[4]*pixelSpacingY + x*orientation[1]*pixelSpacingX;
	d[2] = originZ + y*orientation[5]*pixelSpacingY + x*orientation[2]*pixelSpacingX;
}

- (void) convertDICOMCoords: (float*) dc toSliceCoords: (float*) sc {
	
	float temp[ 3 ];
	
	temp[ 0 ] = dc[ 0 ] - originX;
	temp[ 1 ] = dc[ 1 ] - originY;
	temp[ 2 ] = dc[ 2 ] - originZ;

	sc[ 0 ] = temp[ 0 ] * orientation[ 0 ] + temp[ 1 ] * orientation[ 1 ] + temp[ 2 ] * orientation[ 2 ];
	sc[ 1 ] = temp[ 0 ] * orientation[ 3 ] + temp[ 1 ] * orientation[ 4 ] + temp[ 2 ] * orientation[ 5 ];
	sc[ 2 ] = temp[ 0 ] * orientation[ 6 ] + temp[ 1 ] * orientation[ 7 ] + temp[ 2 ] * orientation[ 8 ];
	
}

-(void) computePixMinPixMax
{
	float pixmin, pixmax;
	long i;
	
	if( fImage == 0L) return;
	
	if( isRGB)
	{
		pixmax = 255;
		pixmin = 0;
	}
	else
	{
		float		fmin, fmax;
		
		vDSP_minv ( fImage,  1, &fmin, width * height);
		vDSP_maxv ( fImage , 1, &fmax, width * height);
		
		pixmax = fmax;
		pixmin = fmin;
		
		if( pixmin == pixmax)
		{
			pixmax = pixmin + 20;
		}
	}

	fullwl = pixmin + (pixmax - pixmin)/2;
	fullww = (pixmax - pixmin);
}

-(short) stackMode
{
	return stackMode;
}

-(short) stack
{
	if( stackMode == 0) return 1;
	return stack;
}

-(void) setFusion:(short) m :(short) s :(short) direction
{
	if( s >= 0) stack = s;
	if( m >= 0) stackMode = m;
	if( direction >= 0) stackDirection = direction;
	
	updateToBeApplied = YES;
}

- (void)setSourceFile:(NSString*)s;
{
	[srcFile release];
	srcFile = [s retain];
}

-(NSString*) sourceFile
{
	return srcFile;
}

- (void) ConvertToBW:(long) mode
{
	if( isRGB == NO) return;

	long			i;
	float			*dstPtr = malloc( height * width * 4);
	unsigned char   *srcPtr = (unsigned char*) [self fImage];

	// Set this image as the Red Composant
	switch( mode)
	{
		case 0: // RED
			i = height * width;
			while( i-- > 0) dstPtr[ i] = srcPtr[ i*4 + 1];
		break;
		
		case 1: // GREEN
			i = height * width;
			while( i-- > 0) dstPtr[ i] = srcPtr[ i*4 + 2];
		break;
		
		case 2: // BLUE
			i = height * width;
			while( i-- > 0) dstPtr[ i] = srcPtr[ i*4 + 3];
		break;
		
		case 3: // RGB
			i = height * width;
			while( i-- > 0) dstPtr[ i] = ((float) srcPtr[ i*4 + 1] + (float) srcPtr[ i*4 + 2] + (float) srcPtr[ i*4 + 3]) / 3.;
		break;
	}
	
	[self setRowBytes: [self pwidth]];
	[self setBaseAddr: malloc( [self pwidth] * [self pheight])];
	
	[self setRGB: NO];
	
	memcpy( fImage, dstPtr, height * width * 4);
	
	[self changeWLWW:wl :ww];
	
	free( dstPtr);
}

- (void) ConvertToRGB:(long) mode :(long) cwl :(long) cww
{
	vImage_Buffer		srcf, dst8, dst8888;
	
	if( isRGB) return;
	
	srcf.height = [self pheight];
	srcf.width = [self pwidth];
	srcf.rowBytes =  [self pwidth]*sizeof(float);
	srcf.data =  [self fImage];
	
	dst8.height = [self pheight];
	dst8.width = [self pwidth];
	dst8.rowBytes = [self pwidth]; 
	dst8.data = malloc( [self pheight] * [self pwidth]);
	
	long i;
	
	long min = cwl - cww / 2;
	long max = cwl + cww / 2;
	
	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, max, min, 0);					// FLOAT TO 8 bit
	
	unsigned char*  srcPtr = (unsigned char*) dst8.data;
	unsigned char*  dstPtr = (unsigned char*) [self fImage];
	
	// Set this image as the Red Composant
	switch( mode)
	{
		case 0: // RED
			memset( [self fImage], 0, dst8.height * dst8.width * 4);
			i = dst8.height * dst8.width;
			while( i-- > 0) dstPtr[ i*4 + 1] = srcPtr[ i];
		break;
		
		case 1: // GREEN
			memset( [self fImage], 0, dst8.height * dst8.width * 4);
			i = dst8.height * dst8.width;
			while( i-- > 0) dstPtr[ i*4 + 2] = srcPtr[ i];
		break;
		
		case 2: // BLUE
			memset( [self fImage], 0, dst8.height * dst8.width * 4);
			i = dst8.height * dst8.width;
			while( i-- > 0) dstPtr[ i*4 + 3] = srcPtr[ i];
		break;
		
		case 3: // RGB
			dst8888 = dst8;
			dst8888.rowBytes = [self pwidth]*4;
			dst8888.data =[self fImage];
			
			vImageConvert_Planar8toARGB8888(&dst8, &dst8, &dst8, &dst8, &dst8888, 0);
		break;
	}
	
	[self setRowBytes: [self pwidth]*4];
	
	[self setBaseAddr: malloc( [self pwidth] * [self pheight] * 4)];
	
	[self setRGB: YES];
	
	[self changeWLWW:127 :256];
	
	free( dst8.data);
	
	if( isRGB)
	{
		unsigned char*	argbPtr = (unsigned char*) fImage;
		long			ss = width * height;
		
		while( ss-->0)
		{
			*argbPtr = (*(argbPtr+1) + *(argbPtr+2) + *(argbPtr+3)) / 3;
			argbPtr+=4;
		}
	}
}

-(BOOL) thickSlabVRActivated
{
	return thickSlabVRActivated;
}

- (void) setThickSlabController:( ThickSlabController*) ts
{
	thickSlab = ts;
}

-(void) setFixed8bitsWLWW:(BOOL) f
{
	fixed8bitsWLWW = f;
}

- (float) getPixelValueX: (long) x Y:(long) y
{
	float val = 0;
	
	if( x < 0 || x >= width || y < 0 || y >= height) return 0;
	if( fImage == 0L) return 0;
	
	if( (stackMode == 1 || stackMode == 2 || stackMode == 3) && stack >= 1)
	{
		if( isRGB == NO)
		{
			float   *fNext = 0L;
			long	i, countstack = 0;
			
			val = fImage[ x + (y * width)];
			countstack++;
			
			for( i = 1; i < stack; i++)
			{
				long next;
				if( stackDirection) next = pixPos-i;
				else next = pixPos+i;
			
				if( next < [pixArray count]  && next >= 0)
				{
					fNext = [[pixArray objectAtIndex: next] fImage];
					if( fNext)
					{
						switch( stackMode)
						{
							case 1:		val += fNext[ x + (y * width)];										break;
							case 2:		if( fNext[ x + (y * width)] > val) val = fNext[ x + (y * width)];	break;
							case 3:		if( fNext[ x + (y * width)] < val) val = fNext[ x + (y * width)];	break;
						}
						countstack++;
					}
				}
			}
			
			if( stackMode == 1) val /= countstack;
		}
	}
	else
	{
		val = fImage[ x + (y * width)];
	}
	
	return val;
}

- (void) computeMax:(float*) fResult pos:(int) pos threads:(int) threads
{
	float				*fNext = NULL;
	long				i;
	long				from, to, size = height * width;
	
	from = (pos * size) / threads;
	to = ((pos+1) * size) / threads;
	size = to - from;
	
	for( i = 1; i < stack; i++)
	{
		long res;
		if( stackDirection) res = pixPos-i;
		else res = pixPos+i;
		
		if( res < [pixArray count] && res >= 0)
		{
			fNext = [[pixArray objectAtIndex: res] fImage];
			if( fNext)
			{
				if( stackMode == 2) vDSP_vmax( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
				else if( stackMode == 1) 
				{
					vDSP_vadd( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
					if( from == 0) countstackMean++;
				}
				else vDSP_vmin( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
			}
		}
	}
	
	[processorsLock lock];
	numberOfThreadsForCompute--;
	[processorsLock unlock];

}

- (void) computeMaxThread:(NSDictionary*) dict
{
	[self computeMax: [[dict valueForKey:@"fResult"] pointerValue] pos: [[dict valueForKey:@"pos"] intValue] threads: MPProcessors ()];
}

#pragma mark-
#pragma mark subtraction and changeWLWW

-(void) imageArithmeticMultiplication:(DCMPix*) sub
{
	float   *temp;	
	temp = [self multiplyImages: fImage :[sub fImage]];	
	memcpy( fImage, temp, height * width * sizeof(float));	
	free( temp);
}

-(float*) multiplyImages :(float*) input :(float*) subfImage
{
	long	i = height * width;
	float   *result = malloc( height * width * sizeof(float));
	
	if( subPixOffset.x == 0 && subPixOffset.y == 0)
	{
		#if __ppc__ || __ppc64__
		if( Altivec ) vmultiply( (vector float *)input, (vector float *)subfImage, (vector float *)result, i);
		else
		#endif
		vmultiplyNoAltivec(input, subfImage, result, i);
	}
	else
	{
		long	x, y;
		long	offsetX = subPixOffset.x, offsetY = -subPixOffset.y;
		long	startheight, subheight, startwidth, subwidth;
		float   *tempIn, *tempOut, *tempResult;
		
		if( offsetY > 0) { startheight = offsetY;   subheight = height;}
		else { startheight = 0; subheight = height + offsetY;}
		
		if( offsetX > 0) { startwidth = offsetX;   subwidth = width;}
		else { startwidth = 0; subwidth = width + offsetX;}
		
		for( y = startheight; y < subheight; y++)
		{
			tempResult = result + y*width;
			tempIn = input + y*width;
			tempOut = subfImage + (y-offsetY)*width - offsetX;
			x = subwidth - startwidth;
			while( x-->0)
			{
				*tempResult++ = *tempIn++ * *tempOut++;
			}
		}
	}
	return result;
}

-(void) imageArithmeticSubtraction:(DCMPix*) sub
{
//	float   *temp = [sub fImage];
//	vDSP_vsub (temp,1,fImage,1,fImage,1,height * width * sizeof(float));
	float   *temp;	
	temp = [self arithmeticSubtractImages: fImage :[sub fImage]];	
	memcpy( fImage, temp, height * width * sizeof(float));	
	free( temp);
}

-(float*) arithmeticSubtractImages :(float*) input :(float*) subfImage
{
	long	i = height * width;
	float   *result = malloc( height * width * sizeof(float));
	
	if( subPixOffset.x == 0 && subPixOffset.y == 0)
	{
		#if __ppc__ || __ppc64__
		if( Altivec ) vsubtract( (vector float *)input, (vector float *)subfImage, (vector float *)result, i);
		else
		#endif
		vsubtractNoAltivec(input, subfImage, result, i);
	}
	else
	{
		long	x, y;
		long	offsetX = subPixOffset.x, offsetY = -subPixOffset.y;
		long	startheight, subheight, startwidth, subwidth;
		float   *tempIn, *tempOut, *tempResult;
		
		if( offsetY > 0) { startheight = offsetY;   subheight = height;}
		else { startheight = 0; subheight = height + offsetY;}
		
		if( offsetX > 0) { startwidth = offsetX;   subwidth = width;}
		else { startwidth = 0; subwidth = width + offsetX;}
		
		for( y = startheight; y < subheight; y++)
		{
			tempResult = result + y*width;
			tempIn = input + y*width;
			tempOut = subfImage + (y-offsetY)*width - offsetX;
			x = subwidth - startwidth;
			while( x-->0)
			{
				*tempResult++ = *tempIn++ - *tempOut++;
			}
		}
	}
	return result;
}


//----------------------------Subtraction parameters copied to each Pix---------------------------

- (void) setSubSlidersPercent: (float) p gamma: (float) g zero: (float) z	
{
	subtractedfPercent = p;
	subtractedfZero = z - 0.8 + (p*0.8);
	//subGammaFunction is a pointer which refers to the current gamma for the series
	if( subGammaFunction) vImageDestroyGammaFunction( subGammaFunction);
	subGammaFunction = vImageCreateGammaFunction(g, kvImageGamma_UseGammaValue_half_precision, 0 );	
	updateToBeApplied = YES;
}

-(NSPoint) subPixOffset {return subPixOffset;}
- (void) setSubPixOffset:(NSPoint) subOffset;
{
	subPixOffset = subOffset;
	updateToBeApplied = YES;
}

//----- Min and Max of the subtracted result of all the Pix of the series for a given subfImage------

-(NSPoint) subMinMax:(float*)input :(float*)subfImage
{
	long			i			= height * width;	
	float			*result		= malloc( i * sizeof(float));
	vDSP_vsub (subfImage,1,input,1,result,1,i);				//mask - frame
	vDSP_minv (result,1,&subMinMax.x,i);					//black pixel	
	vDSP_maxv (result,1,&subMinMax.y,i);					//white pixel	
	return subMinMax;
}

- (void) setSubtractedfImage:(float*)mask :(NSPoint)smm
{
	subtractedfImage = mask;
	subMinMax = smm;	
	updateToBeApplied = YES;
}

//------------------------------------------subtraction--------------------------------------------

-(float*) subtractImages:(float*)input :(float*)subfImage
{
	long	firstPixel = subPixOffset.y * width - subPixOffset.x;			
	long	firstPixelAbs = abs(subPixOffset.y * width) + abs(subPixOffset.x);
	float	*firstSourcePixel = subfImage + (firstPixelAbs + firstPixel)/2;
	long	i = height * width;	
	float	*result = malloc( i * sizeof(float));
	float	*firstResultPixel = result + (firstPixelAbs - firstPixel)/2;
	long	lengthToBeCopied = i - firstPixelAbs;

	//preparing mask: the following command registers it in function of the pixel shift, and multiplies it by % 
	vDSP_vsmul (firstSourcePixel,1,&subtractedfPercent,firstResultPixel,1,lengthToBeCopied);//result= % mask	
	
	vDSP_vsub (result,1,input,1,result,1,lengthToBeCopied);				//mask - frame
	
	float ratio = fabs(subMinMax.y-subMinMax.x);						//Max difference in subtraction without pixel shift
	vDSP_vsdiv (result,1,&ratio,result,1,i);							//normalize result [-1...1]
	vDSP_vsadd (result,1,&subtractedfZero,result,1,i);					//normalize result [0...n]
	
	if( input != fImage) free( input);
	
	return result;
}

-(void) fImageTime:(float)newTime {fImageTime = newTime;}
-(float) fImageTime {return fImageTime;}
-(void) maskID:(long)newID {maskID = newID;}
-(long) maskID {return maskID;}
-(void) maskTime:(float)newMaskTime {maskTime = newMaskTime;}
-(float) maskTime {return maskTime;}
-(void) rot:(float)newRot {rot = newRot;}
-(float) rot {return rot;}
-(void) ang:(float)newAng {ang = newAng;}
-(float) ang {return ang;}


-(void) DCMPixShutterRect:(long)x:(long)y:(long)w:(long)h;
{
	shutterRect_x = x;
	shutterRect_y = y;
	shutterRect_w = w;
	shutterRect_h = h;
}
-(long) DCMPixShutterRectWidth {return shutterRect_w;}
-(long) DCMPixShutterRectHeight {return shutterRect_h;}
-(long) DCMPixShutterRectOriginX {return shutterRect_x;}
-(long) DCMPixShutterRectOriginY {return shutterRect_y;}

-(BOOL) DCMPixShutterOnOff  {return DCMPixShutterOnOff;}
-(void) DCMPixShutterOnOff:(BOOL)newDCMPixShutterOnOff
{
	DCMPixShutterOnOff = newDCMPixShutterOnOff;
	updateToBeApplied = YES;
}

-(void) applyShutter
{
	if (DCMPixShutterOnOff == NSOnState)
	{
		if( isRGB == YES || thickSlabVRActivated == YES)
		{
			char*	tempMem = calloc( 1, height * width * 4*sizeof(char));
			
			int i = shutterRect_h;
			
			char*	src = baseAddr + ((shutterRect_y * rowBytes) + shutterRect_x*4);
			char*	dst = tempMem + ((shutterRect_y * rowBytes) + shutterRect_x*4);
			
			while( i-- > 0)
			{
				memcpy( dst, src, shutterRect_w*4);
				
				dst += rowBytes;
				src += rowBytes;
			}
			
			memcpy(baseAddr, tempMem, height * width * 4*sizeof(char));
			
			free( tempMem);
		}
		else
		{
			char*	tempMem = calloc( 1, height * width * sizeof(char));
			
			int i = shutterRect_h;
			
			char*	src = baseAddr + ((shutterRect_y * rowBytes) + shutterRect_x);
			char*	dst = tempMem + ((shutterRect_y * rowBytes) + shutterRect_x);
			
			while( i-- > 0)
			{
				memcpy( dst, src, shutterRect_w);
				
				dst += rowBytes;
				src += rowBytes;
			}
			
			memcpy(baseAddr, tempMem, height * width * sizeof(char));
			
			free( tempMem);
		}
	}
}

- (float*) applyConvolutionOnImage:(float*) src RGB:(BOOL) color
{
	float	*result;
	
	[self CheckLoad]; 
	
	vImage_Buffer dstf, srcf;
		
	dstf.height = height;
	dstf.width = width;
	dstf.rowBytes = width*sizeof(float);
	dstf.data = src;
	
	srcf = dstf;
	srcf.data = result = malloc( height*width*sizeof(float));
	if( srcf.data)
	{
		short err;
		
		if( color)
		{
			err = vImageConvolve_ARGB8888( &dstf, &srcf, 0, 0, 0,  kernel, kernelsize, kernelsize, normalization, 0, kvImageLeaveAlphaUnchanged + kvImageEdgeExtend);
		}
		else
		{
			float  fkernel[25];
			int i;
			
			if( normalization != 0)
				for( i = 0; i < 25; i++) fkernel[ i] = (float) kernel[ i] / (float) normalization; 
			else
				for( i = 0; i < 25; i++) fkernel[ i] = (float) kernel[ i]; 
			
			err = vImageConvolve_PlanarF( &dstf, &srcf, 0, 0, 0, fkernel, kernelsize, kernelsize, 0, kvImageEdgeExtend);
		}
		
		if( err) NSLog(@"Error applyConvolutionOnImage = %d", err);
		
		if( src != fImage) free( src);
	}
	
	return result;
}

- (void) applyConvolutionOnSourceImage
{
	[self CheckLoad];
	
	float *result = [self applyConvolutionOnImage: fImage RGB: isRGB];
	
	memcpy( fImage, result, height*width*sizeof(float));
	
	free( result);
}

- (float*) computeThickSlabRGB
{
	long			countstack = 1;
	BOOL			flip;
	vImage_Buffer   src, dst;
	Pixel_8			convTable[256];
	long			i, diff, val;
	unsigned char	*fNext = NULL, *fResult = malloc( height * width * sizeof(char)*4);
	long			next;
	float			min, max, iwl, iww;

	if( fixed8bitsWLWW)
	{
		iww = 256;
		iwl = 127;
	}
	else
	{
		iww = ww;
		iwl = wl;
	}
	
	min = iwl - iww / 2; 
	max = iwl + iww / 2;
	diff = max - min;

	switch( stackMode)
	{
		case 4:		// Volume Rendering
		case 5:
		break;
		
		case 1:		// Mean
		break;
		
		case 2:		// Maximum IP
		case 3:		// Minimum IP
			if( stackDirection) next = pixPos-1;
			else next = pixPos+1;
			
			if( next < [pixArray count]  && next >= 0)
			{
				fNext = (unsigned char*) [[pixArray objectAtIndex: next] fImage];
				if( fNext)
				{
					#if __ppc__ || __ppc64__
					if( Altivec)
					{
						if( stackMode == 2) vmax8( (vector unsigned char *)fNext, (vector unsigned char *)fImage, (vector unsigned char *)fResult, height * width);
						else vmin8( (vector unsigned char *)fNext, (vector unsigned char *)fImage, (vector unsigned char *)fResult, height * width);
					}
					else
					#endif
					{
						if( stackMode == 2) vmaxNoAltivec(fNext, fImage, fResult, height * width);
						else vminNoAltivec(fNext, fImage, fResult, height * width);
					}
				}
				
				for( i = 2; i < stack; i++)
				{
					long res;
					if( stackDirection) res = pixPos-i;
					else res = pixPos+i;
					
					if( res < [pixArray count])
					{
						long res;
						if( stackDirection) res = pixPos-i;
						else res = pixPos+i;
						
						if( res < [pixArray count] && res >= 0)
						{
							fNext = (unsigned char*) [[pixArray objectAtIndex: res] fImage];
							if( fNext)
							{
								#if __ppc__ || __ppc64__
								if( Altivec)
								{
									if( stackMode == 2) vmax8( (vector unsigned char *)fResult, (vector unsigned char *)fNext, (vector unsigned char *)fResult, height * width);
									else vmin8( (vector unsigned char *)fResult, (vector unsigned char *)fNext, (vector unsigned char *)fResult, height * width);
								}
								else
								#endif
								{
									if( stackMode == 2) vmaxNoAltivec(fResult, fNext, fResult, height * width);
									else vminNoAltivec(fResult, fNext, fResult, height * width);
								}
							}
						}
					}
				}
			}
			else
			{
				memcpy( fResult, fImage, height * width * sizeof(char)*4);
			}
		break;			
	} //end of switch
	
	return( fResult);
}

- (float*) computeThickSlab
{
	BOOL			flip = NO; // case 5
	long			stacksize;
	unsigned char   *rgbaImage;
	float			*fNext = NULL;
	long			i;
	long			next;
	vImage_Buffer	srcf, dst8;
	float			min, max, iwl, iww;
	float			*fResult = 0L;
	
	if( fixed8bitsWLWW)
	{
		iww = 256;
		iwl = 127;
	}
	else
	{
		iww = ww;
		iwl = wl;
	}
	
	min = iwl - iww / 2; 
	max = iwl + iww / 2;
	
	switch( stackMode)
	{
		case 4:		// Volume Rendering
			flip = YES;
		case 5:		// Volume Rendering
			if( thickSlab)
			{											
				if( stackDirection)
				{
					if( pixPos-stack < 0) stacksize = pixPos+1; 
					else stacksize = stack+1;
				}
				else
				{
					if( pixPos+stack < [pixArray count]) stacksize = stack; 
					else stacksize = [pixArray count] - pixPos;
				}
				
				if( stackDirection) [thickSlab setImageSource: fImage - (stacksize-1)*height * width :stacksize];
				else [thickSlab setImageSource: fImage :stacksize];
				[thickSlab setWLWW: iwl: iww];
				
				rgbaImage = [thickSlab renderSlab];
				
				thickSlabVRActivated = YES;
				
				[self setRowBytes: width*4];
				[self setBaseAddr: (char*) rgbaImage];
			}
		break;
		
		// ------------------------------------------------------------------------------------------------
		case 1:		// Mean
		case 2:		// Maximum IP
		case 3:		// Minimum IP
			countstackMean = 1;
			
			fResult = malloc( height * width * sizeof(float));
			memcpy( fResult, fImage, height * width * sizeof(float));

			if( processorsLock == 0L)
				processorsLock = [[NSLock alloc] init];
			
			numberOfThreadsForCompute = MPProcessors ();
			for( i = 0; i < MPProcessors ()-1; i++)
			{
				[NSThread detachNewThreadSelector: @selector( computeMaxThread:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithPointer: fResult], @"fResult", [NSNumber numberWithInt: i], @"pos", 0L]];
			}
			
			[self computeMaxThread: [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithPointer: fResult], @"fResult", [NSNumber numberWithInt: i], @"pos", 0L]];
			
			BOOL done = NO;
			while( done == NO)
			{
				[processorsLock lock];
				if( numberOfThreadsForCompute <= 0) done = YES;
				[processorsLock unlock];
			}
			
			if( countstackMean > 1)
			{
				i = height * width;
				while( i-- > 0) fResult[ i] /= countstackMean;
			}
			//-----------------------------------
		break;
	}
	
	return fResult;
}

- (float*) computefImage
{
	float *result;
	
	thickSlabVRActivated = NO;
	[self setRowBytes: width];

	// = STACK IMAGES thickslab
	if( stackMode > 0 && stack >= 1)
	{
		result = [self computeThickSlab];
	}
	else result = fImage;

	return result;
}

- (void) changeWLWW:(float)newWL :(float)newWW
{
long			i;
float			iwl, iww;

	[self CheckLoad]; 
	
	if( newWW !=0 || newWL != 0)   // new values to be applied
    {
		if( fullww > 256)
		{
			if( newWW < 1) newWW = 2;
			
			if( newWL - newWW/2 == 0)
			{
				newWW = (int) newWW;
				newWL = (int) newWL;
				
				newWL = newWW/2;
			}
			else
			{
				newWW = (int) newWW;
				newWL = (int) newWL;
			}
		}
		
        if( newWW < 0.001) newWW = 0.001;
        
        ww = newWW;
        wl = newWL;
    }
	else                          // need to compute best values... problem with subtraction performed afterwards
	{
		[self computePixMinPixMax];
		
		ww = fullww;
		wl = fullwl;
	}
	
	// --------------------------------
    
	if( fixed8bitsWLWW)
	{
		iww = 256;
		iwl = 127;
	}
	else
	{
		iww = ww;
		iwl = wl;
	}
	
	// ----------------------------------------------------------- iww, iwl contain computMinPixMax or newWW, newWL
    
    if( baseAddr)
    {
		updateToBeApplied = NO;
	
		float  min, max;
		
        min = iwl - iww / 2; 
        max = iwl + iww / 2;
		
		// ***** ***** ***** ***** ***** 
		// ***** SOURCE IMAGE IS 32 BIT FLOAT
		// ***** ***** ***** ***** *****
		
		if( isRGB == NO) //fImage case
		{
			vImage_Error	vIerr;
			vImage_Buffer	srcf, dst8;
			
			srcf.data = [self computefImage];
						
			// CONVERSION TO 8-BIT for displaying
			
			if( thickSlabVRActivated == NO)
			{
				dst8.height = height;
				dst8.width = width;
				dst8.rowBytes = rowBytes;					
				dst8.data = baseAddr;

				srcf.height = height;
				srcf.width = width;
				srcf.rowBytes = width*sizeof(float);
				
				if( subtractedfImage)
				{
					srcf.data = [self subtractImages: srcf.data :subtractedfImage];
					
					if( convolution) srcf.data = [self applyConvolutionOnImage: srcf.data RGB: NO];
					
					if( subGammaFunction == 0L) subGammaFunction = vImageCreateGammaFunction(2.0, kvImageGamma_UseGammaValue_half_precision, 0 );
					vImage_Error vIerr = vImageGamma_PlanarFtoPlanar8 (&srcf, &dst8, subGammaFunction, 0);
				}
				else
				{
					if( convolution) srcf.data = [self applyConvolutionOnImage: srcf.data RGB: NO];
					
					vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, max, min, 0);
				}
				
				if( srcf.data != fImage) free( srcf.data);
			}
		}	
		
		// ***** ***** ***** ***** ***** 
		// ***** SOURCE IMAGE IS RGBA
		// ***** ***** ***** ***** *****
		
		if( isRGB == YES)
		{
			vImage_Buffer   src, dst;
			Pixel_8			convTable[256];
			long			i, diff = max - min, val;
			
			if( stackMode > 0 && stack >= 1)
			{
				src.data = [self computeThickSlabRGB];
			}
			else src.data = fImage;
			
			if( convolution) src.data = [self applyConvolutionOnImage: src.data RGB: YES];
			
			// APPLY WINDOW LEVEL TO RGB IMAGE
			
			for(i = 0; i < 256; i++)
			{
				val = (((i-min) * 255L) / diff);
				if( val < 0) val = 0;
				if( val > 255) val = 255;
				convTable[i] = val;
			}
			
			src.height = height;
			src.width = width;
			src.rowBytes = width*4;
			
			dst.height = height;
			dst.width = width;
			dst.rowBytes = rowBytes;
			dst.data = baseAddr;
			
			vImageTableLookUp_ARGB8888 ( &src,  &dst,  convTable,  convTable,  convTable,  convTable,  0);
			
			if( src.data != fImage) free( src.data);
		}
		
		[self applyShutter];		
    }
}

#pragma mark-


- (void) kill8bitsImage
{	 
	[image release];	 
	baseAddr = 0L;	 
	image = 0L;	 
 }
 
- (void) checkImageAvailble:(float)newWW :(float)newWL
{
	[self CheckLoad];
	
	if( baseAddr == 0L) [self computeWImage: NO: newWW :newWL];
}

- (xNSImage*) computeWImage: (BOOL) smallIcon :(float)newWW :(float)newWL
{
    long    destWidth, destHeight;
	
    [self CheckLoad];

    [image release];
	image = 0L;
	
    if( smallIcon)
    {
        float ratio;
        
        if( (float) width / PREVIEWSIZE > (float) height / PREVIEWSIZE) ratio = (float) width / PREVIEWSIZE;
        else ratio = (float) height / PREVIEWSIZE;
        
        destWidth = (float) width / ratio;
        destHeight = (float) height / ratio;
    }
    else
    {
        destWidth = width;
        destHeight = height;
    }
    
	if( isRGB) rowBytes = destWidth * 4;
	else
	{
		rowBytes = destWidth;
	}
	
    unsigned char *bitmapData = malloc( (rowBytes + 4) * (destHeight+4));
	memset( bitmapData, 0, (rowBytes + 4) * (destHeight+4));
	
	NSBitmapImageRep *bitmapRep;
	
	if( smallIcon)
    {
		if( isRGB)
		{
			bitmapRep = [[NSBitmapImageRep alloc] 
						initWithBitmapDataPlanes:&bitmapData
						pixelsWide:destWidth
						pixelsHigh:destHeight
						bitsPerSample:8
						samplesPerPixel:3
						hasAlpha:NO
						isPlanar:NO
						colorSpaceName:NSCalibratedRGBColorSpace
						bytesPerRow:rowBytes
						bitsPerPixel:24
						];
		}
		else
		{
			bitmapRep = [[NSBitmapImageRep alloc] 
						initWithBitmapDataPlanes:&bitmapData
						pixelsWide:destWidth
						pixelsHigh:destHeight
						bitsPerSample:8
						samplesPerPixel:1  // 1-3 // RGB
						hasAlpha:NO
						isPlanar:NO
						colorSpaceName:NSCalibratedWhiteColorSpace
						bytesPerRow:rowBytes
						bitsPerPixel:8 // 8 - 24 -32
						];
		}
    }
	else bitmapRep = 0L;

	baseAddr = (char*) bitmapData;  //[bitmapRep bitmapData];
	
	if( smallIcon)
	{
		if( bitmapRep)
		{
			if( newWW == 0 && newWL == 0)
			{
				if( ww == 0 & wl == 0)
				{
					[self computePixMinPixMax];
					ww = fullww;
					wl = fullwl;
				}
				newWW = ww;
				newWL = wl;
			}
			
			CreateIconFrom16( fImage, bitmapData, height, width, rowBytes, newWL, newWW, isRGB);
		}
	}
	// necesary to refresh DCMView of the browser
	else [self changeWLWW: newWL : newWW];
	
	if( smallIcon)
	{
		if( bitmapRep)
		{
			image = [[xNSImage alloc] initWithSize:NSMakeSize(destWidth,  destHeight)]; 
			[image addRepresentation:bitmapRep];
			[bitmapRep release];
		}
		baseAddr = 0L;		// We dont keep this information, will be deleted when xNSImage released!
	}
	else image = [[xNSImage alloc] init];
	
	if( image) [image SetxNSImage :bitmapData];
	
    return image;
}

- (xNSImage*) getImage
{
//    [self CheckLoad];
    
	if( image == 0L)
	{
		NSLog(@"image == 0L!!");
	}
	
   // NSLog(@"getImage de DCMPix");
    return image;
}

-(float) ww
{
	[self CheckLoad];
    return ww;
}

-(long) ID
{
    return imID;
}

- (void) setID :(long) i
{
	imID = i;
}

-(long) Tot
{
	[self CheckLoad];
    return imTot;
}

-(void) setTot: (long) tot
{
	[self CheckLoad];
	imTot = tot;
}

-(float) wl
{
	[self CheckLoad];
    return wl;
}

-(long) pwidth
{
	[self CheckLoad];
    return width;
}

-(long) pheight
{
	[self CheckLoad];
    return height;
}

- (long) setPheight:(long) h
{
	height = h;
}

- (long) setPwidth:(long) w
{
	width = w;
}

-(void) setRowBytes:(long) rb
{
	rowBytes = rb;
}

-(long) rowBytes
{
	[self CheckLoad];
    return rowBytes;
}

-(void) setUpdateToApply
{
	updateToBeApplied = YES;
}

-(BOOL) updateToApply { return updateToBeApplied;}



-(void) setConvolutionKernel:(short*)val :(short) size :(short) norm;
{
	long i;
	
	if( val)
	{
		kernelsize = size;
		convolution = YES;
		normalization = norm;
		for(  i = 0; i < kernelsize*kernelsize; i++) kernel[i] = val[i];
	}
	else
	{
		convolution = NO;
	}
	
	updateToBeApplied = YES;
}

-(void) revert
{
	if( fImage == 0L) return;
	
	[checking lock];
	
	SUVConverted = NO;
	fullww = 0;
	fullwl = 0;
	
	[acquisitionTime release];					acquisitionTime = 0L;
	[radiopharmaceuticalStartTime release];		radiopharmaceuticalStartTime = 0L;
	[convertedDICOM release];					convertedDICOM = 0L;
	[repetitiontime release];					repetitiontime = 0L;
	[echotime release];							echotime = 0L;
	[protocolName release];						protocolName = 0L;
	[viewPosition release];						viewPosition = 0L;
	[patientPosition release];					patientPosition = 0L;
	[units release];							units = 0L;
	[decayCorrection release];					decayCorrection = 0L;
	
	if( fVolImage == 0L)
	{
		if( fImage != 0L)
		{
			free(fImage);
			fImage = 0L;
		}
	}
	fImage = 0L;
	
	[checking unlock];
}

- (void) dealloc
{
	[processorsLock release];
	[acquisitionTime release];
	[radiopharmaceuticalStartTime release];
	[convertedDICOM release];
	[repetitiontime release];
	[echotime release];
	[units release];
	[protocolName release];
	[patientPosition release];
	[viewPosition release];
	[decayCorrection release];
	
	if( fVolImage == 0L)
	{
		if( fImage != 0L)
		{
			free(fImage);
			fImage = 0L;
		}
	}
	
    [srcFile release];
    [image release];
    
    if( oImage != 0L) 
    {
        free ( oImage);
        oImage = 0L;
    }
	
	[imageObj release];
	
	[checking release];
	checking = 0L;
	
	if( oData) free( oData);
	if( VOILUT_table) free( VOILUT_table);

	if( subGammaFunction) vImageDestroyGammaFunction( subGammaFunction);
	
    [super dealloc];
}

// Accessor methods needed for SUV calculations
#pragma mark-
#pragma mark SUV
- (NSString *)units {
	return units;
}

- (NSString *)setUnits: (NSString *) s {
	[units release];
	units = [s retain]; 
}

- (NSString *)decayCorrection {
	return decayCorrection;
}

- (float) decayFactor
{
	return decayFactor;
}

- (float) setDecayFactor: (float) f
{
	decayFactor = f;
}

- (void) setDecayCorrection : (NSString*) s
{
	[decayCorrection release];
	decayCorrection = [s retain];
}

- (float) radionuclideTotalDose {
	return radionuclideTotalDose;
}

- (float) radionuclideTotalDoseCorrected {
	return radionuclideTotalDoseCorrected;
}

- (float) patientsWeight {
	return patientsWeight;
}

- (void) setRadionuclideTotalDose: (float) v {
	radionuclideTotalDose = v;
}

- (void) setRadionuclideTotalDoseCorrected: (float) v {
	radionuclideTotalDoseCorrected = v;
}

- (void) setPatientsWeight: (float) v {
	 patientsWeight = v;
}

-(NSCalendarDate*) acquisitionTime
{
	return acquisitionTime;
}

-(void) setAcquisitionTime : (NSCalendarDate*) d
{
	[acquisitionTime release];
	acquisitionTime = [d retain];
}

-(NSCalendarDate*) radiopharmaceuticalStartTime
{
	return radiopharmaceuticalStartTime;
}

-(void) setRadiopharmaceuticalStartTime : (NSCalendarDate*) d
{
	[radiopharmaceuticalStartTime release];
	radiopharmaceuticalStartTime = [d retain];
}

- (BOOL) SUVConverted
{
	return SUVConverted;
}

- (void) setSUVConverted: (BOOL) v
{
	SUVConverted = v;
}

- (float) philipsFactor
{
	return philipsFactor;
}

- (BOOL) hasSUV
{
	return hasSUV;
}

- (BOOL) displaySUVValue
{
	return displaySUVValue;
}

- (void) setDisplaySUVValue : (BOOL) v
{
	displaySUVValue = v;
}

- (float) halflife
{
	return halflife;
}

- (void) setHalflife: (float) f
{
	halflife = f;
}

- (float) maxValueOfSeries
{
	return maxValueOfSeries;
}

- (void) setMaxValueOfSeries: (float) f
{
	maxValueOfSeries = f;
}

- (float) minValueOfSeries
{
	return minValueOfSeries;
}

- (void) setMinValueOfSeries: (float) f
{
	minValueOfSeries = f;
}

-(void) copySUVfrom:(DCMPix*) from
{
	[self setRadiopharmaceuticalStartTime: [from radiopharmaceuticalStartTime]];
	[self setAcquisitionTime: [from acquisitionTime]];
	[self setRadionuclideTotalDose: [from radionuclideTotalDose]];
	[self setRadionuclideTotalDoseCorrected: [from radionuclideTotalDoseCorrected]];
	[self setPatientsWeight: [from patientsWeight]];
	[self setUnits: [from units]];
	[self setDisplaySUVValue: [from displaySUVValue]];
	[self setSUVConverted: [from SUVConverted]];
	[self setDecayCorrection: [from decayCorrection]];
	[self setMaxValueOfSeries: [from maxValueOfSeries]];
	[self setMinValueOfSeries: [from minValueOfSeries]];
	[self setDecayFactor: [from decayFactor]];
	[self setHalflife: [from halflife]];
	[self checkSUV];
}

//Database links
- (NSManagedObject *)imageObj{
	return imageObj;
}

- (NSManagedObject *)seriesObj{
	return [imageObj valueForKey:@"series"];
}

- (NSString *)srcFile
{
	return srcFile;
}

@end
