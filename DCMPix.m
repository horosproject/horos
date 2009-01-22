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


#import <DCMPix.h>
#import "DicomImage.h"
#import "Papyrus3/Papyrus3.h"
#import <QuickTime/QuickTime.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import "BrowserController.h"
#import "DOClient.h"
#import "PluginManager.h"
#import "ROI.h"
#import "ROISRConverter.h"

#import <DCMView.h>

#import "ThickSlabController.h"
#import "dicomFile.h"
#import "PluginFileFormatDecoder.h"
#include "tiffio.h"
#include "FVTiff.h"
#include "Analyze.h"
#include "nifti1.h"
#include "nifti1_io.h"
#include <Accelerate/Accelerate.h>
#include "AppController.h"

#import <QTKit/QTKit.h>
#import "Point3D.h"

#import "math.h"
#import "altivecFunctions.h"

#ifdef STATIC_DICOM_LIB
#define PREVIEWSIZE 512
#else
#define PREVIEWSIZE 70.0
#endif

BOOL gUserDefaultsSet = NO;
BOOL gUseShutter = NO;
BOOL gDisplayDICOMOverlays = YES;
BOOL gUseVOILUT = NO;
BOOL gUseJPEGColorSpace = NO;
BOOL gUSEPAPYRUSDCMPIX = YES;
BOOL gFULL32BITPIPELINE = NO;

BOOL	anonymizedAnnotations = NO;
BOOL	runOsiriXInProtectedMode = NO;
BOOL	quicktimeRunning = NO;
NSLock	*quicktimeThreadLock = nil;

static NSMutableDictionary *cachedPapyGroups = nil;
static NSMutableDictionary *cachedDCMFrameworkFiles = nil;
static NSMutableArray *nonLinearWLWWThreads = nil;
static NSMutableArray *minmaxThreads = nil;
static NSConditionLock *processorsLock = nil;
static float deg2rad = 3.14159265358979/180.0; 

struct NSPointInt
{
	long x;
	long y;
};
typedef struct NSPointInt NSPointInt;

NSString* filenameWithDate( NSString *inputfile);
extern NSThread *mainThread;
extern NSRecursiveLock *PapyrusLock;
extern short Altivec;

void PapyrusLockFunction( int lock)
{
	if( lock)
		[PapyrusLock lock];
	else
		[PapyrusLock unlock];
}

void ConvertFloatToNative (float *theFloat)
{
	unsigned int		*myLongPtr;
	
	myLongPtr = (unsigned int *)theFloat;
	*myLongPtr = EndianU32_LtoN(*myLongPtr);
}

void SwitchFloat (float *theFloat)
{
	unsigned int		*myLongPtr;
	
	myLongPtr = (unsigned int *)theFloat;
	*myLongPtr = Endian32_Swap(*myLongPtr);
}


//void ConvertDoubleToNative (double *theFloat)
//{
//	unsigned long long		*myLongPtr;
//	
//	myLongPtr = (unsigned long long*)theFloat;
//	*myLongPtr = EndianU64_LtoN(*myLongPtr);
//}

uint64_t	MyGetTime( void)
{
	AbsoluteTime theTime = UpTime();
	
	return ((uint64_t*) &theTime)[0];
}

double MySubtractTime( uint64_t endTime, uint64_t startTime)
{
	union
	{
		Nanoseconds	ns;
		u_int64_t	i;
	}time;
	
	time.ns = AbsoluteToNanoseconds( SubAbsoluteFromAbsolute( ((AbsoluteTime*) &endTime)[0], ((AbsoluteTime*) &startTime)[0]));
	return time.i * 1e-9;
}

unsigned char* CreateIconFrom16 (float* image,  unsigned char*icon,  int height, int width, int iconWidth, long wl, long ww, BOOL isRGB)
// create an icon from an 12 or 16 bit image
{
	unsigned char		*iconPtr;
	float				ratio;
	long				i, j;
	long				line, destWidth, destHeight;
	long				value;
	long				min, max, diff;
	
	min = wl - ww / 2; //if (min < 0) min = 0;
	max = wl + ww / 2;
	diff = max - min;
	
	if( diff <= 0)
	{
		diff = 1;
		max = min + 1;
	}
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
			int x;
			unsigned char *rgbImage = (unsigned char*) image;
			int rowBytes = iconWidth*4;
			
			for (i = 0; i < destHeight; i++)  // lines
			{
				line = width * (long) (ratio * i)*4 ;   //ARGB
				iconPtr = icon + rowBytes*i;
				for (j = 0; j < destWidth; j++)         // columns 
				{
					for (x = 1; x< 4;x++, iconPtr++)		// Dont take alpha channel
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
			int rowBytes = iconWidth;
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

#define MAXVERTICAL     10000

#define INIT_DELTAS dx=V2.x-V1.x;  dy=V2.y-V1.y;
#define INIT_CLIP INIT_DELTAS if(dx)m=dy/dx;

static inline void CLIP_Left(NSPointInt *Polygon, long *count, NSPointInt V1, NSPointInt V2)
{
	float   dx,dy, m=1;
	INIT_CLIP
	
	// ************OK************
	if ( (V1.x>=0) && (V2.x>=0))
		Polygon[(*count)++]=V2;
	// *********LEAVING**********
	if ( (V1.x>=0) && (V2.x<0))
	{
		Polygon[(*count)].x=0;
		Polygon[(*count)++].y=V1.y+m*(0-V1.x);
	}
	// ********ENTERING*********
	if ( (V1.x<0) && (V2.x>=0))
	{
		Polygon[(*count)].x=0;
		Polygon[(*count)++].y=V1.y+m*(0-V1.x);
		Polygon[(*count)++]=V2;
	}
}

static inline void CLIP_Right(NSPointInt *Polygon, long *count, NSPointInt V1, NSPointInt V2, NSPointInt DownRight) 
{
	float dx,dy, m=1;
	INIT_CLIP
	// ************OK************
	if ( (V1.x<=DownRight.x) && (V2.x<=DownRight.x))
		Polygon[(*count)++]=V2;
	// *********LEAVING**********
	if ( (V1.x<=DownRight.x) && (V2.x>DownRight.x))
	{
		Polygon[(*count)].x=DownRight.x;
		Polygon[(*count)++].y=V1.y+m*(DownRight.x-V1.x);
	}
	// ********ENTERING*********
	if ( (V1.x>DownRight.x) && (V2.x<=DownRight.x))
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
static inline void CLIP_Top(NSPointInt *Polygon,long *count, NSPointInt V1,NSPointInt V2)
{
	float   dx,dy, m=1;
	INIT_CLIP
	// ************OK************
	if ( (V1.y>=0) && (V2.y>=0))
		Polygon[(*count)++]=V2;
	// *********LEAVING**********
	if ( (V1.y>=0) && (V2.y<0))
	{
		if(dx)
			Polygon[(*count)].x=V1.x+(0-V1.y)/m;
		else
			Polygon[(*count)].x=V1.x;
		Polygon[(*count)++].y=0;
	}
	// ********ENTERING*********
	if ( (V1.y<0) && (V2.y>=0))
	{
		if(dx)
			Polygon[(*count)].x=V1.x+(0-V1.y)/m;
		else
			Polygon[(*count)].x=V1.x;
		Polygon[(*count)++].y=0;
		Polygon[(*count)++]=V2;
	}
}
static inline void CLIP_Bottom(NSPointInt *Polygon,long *count, NSPointInt V1,NSPointInt V2, NSPointInt DownRight)
{
	float dx,dy, m=1;
	INIT_CLIP
	// ************OK************
	if ( (V1.y<=DownRight.y) && (V2.y<=DownRight.y))
		Polygon[(*count)++]=V2;
	// *********LEAVING**********
	if ( (V1.y<=DownRight.y) && (V2.y>DownRight.y))
	{
		if(dx)
			Polygon[(*count)].x=V1.x+(DownRight.y-V1.y)/m;
		else
			Polygon[(*count)].x=V1.x;
		Polygon[(*count)++].y=DownRight.y;
	}
	// ********ENTERING*********
	if ( (V1.y>DownRight.y) && (V2.y<=DownRight.y))
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
	int				d;
	NSPointInt		*TmpPoly = malloc( MAXVERTICAL * sizeof( NSPointInt));
	long			TmpCount;	
	NSPointInt		DownRight;
	
	DownRight.x = w-1;
	DownRight.y = h-1;
	
	*outCount = 0;
	TmpCount=0;
	
	for ( int v=0; v<inCount; v++)
	{
		d=v+1;
		if(d==inCount)d=0;
		CLIP_Left( TmpPoly, &TmpCount, inPoly[v],inPoly[d]);
	}
	for ( int v=0; v<TmpCount; v++)
	{
		d=v+1;
		if(d==TmpCount)d=0;
		CLIP_Right(outPoly, outCount, TmpPoly[v],TmpPoly[d], DownRight);
	}
	TmpCount=0;
	for ( int v=0; v<*outCount; v++)
	{
		d=v+1;
		if(d==*outCount)d=0;
		CLIP_Top( TmpPoly, &TmpCount, outPoly[v],outPoly[d]);
	}
	*outCount=0;
	for ( int v=0; v<TmpCount; v++)
	{
		d=v+1;
		if(d==TmpCount)d=0;
		CLIP_Bottom(outPoly, outCount, TmpPoly[v],TmpPoly[d], DownRight);
	}
	
	free( TmpPoly);
}

// POLY FILL

struct edge
{
    struct edge *next;
    long yTop, yBot;
    long xNowWhole, xNowNum, xNowDen, xNowDir;
    long xNowNumStep;
};

static inline long sgn( long x)
{
	if( x > 0) return 1;
	else if( x < 0) return -1;
	
	return 0;
}

static inline void FillEdges( NSPointInt *p, long no, struct edge *edgeTable[])
{
    int n = no;
	
	memset( edgeTable, 0, sizeof(char*) * MAXVERTICAL);
	
    for ( int i = 0; i < n; i++)
	{
        NSPointInt *p1, *p2, *p3;
        struct edge *e;
        p1 = &p[ i];
        p2 = &p[ (i + 1) % n];
        if (p1->y == p2->y)
            continue;   /* Skip horiz. edges */
        /* Find next vertex not level with p2 */
        for ( int j = (i + 2) % n; ; j = (j + 1) % n)
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
        }
		else
		{
            e->yTop = p2->y;
            e->yBot = p1->y;
            e->xNowWhole = p2->x;
            e->xNowDir = sgn((p1->x) - (p2->x));
            e->xNowDen = e->yBot - e->yTop;
            e->xNowNum = (e->xNowDen >> 1);
            if ((p3->y) < (p2->y))
			{
                e->yTop++;
                e->xNowNum += e->xNowNumStep;
                while (e->xNowNum >= e->xNowDen)
				{
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
        if (e->yBot < curY)
		{
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

static DCMPix **restoreImageCache = nil;

static inline void DrawRuns(	struct edge *active,
							long curY,
							float *pix,
							long w,
							long h,
							float min,
							float max,
							BOOL outside,
							float newVal,
							BOOL addition,
							BOOL RGB,
							BOOL compute,
							float *imax,
							float *imin,
							long *count,
							float *itotal,
							float *idev,
							float imean,
							long orientation,
							long stackNo,	// Only if X/Y orientation
							BOOL restore)		
{
	long			xCoords[ 4096];
	float			*curPix, val, temp;
    long			numCoords = 0;
    long			start, end, ims = w * h;
	
    for ( struct edge *e = active; e != NULL; e = e->next)
	{
		long i;
        for ( i = numCoords; i > 0 &&
			 xCoords[i - 1] > e->xNowWhole; i--)
            xCoords[i] = xCoords[i - 1];
        xCoords[i] = e->xNowWhole;
        numCoords++;
        e->xNowNum += e->xNowNumStep;
        while (e->xNowNum >= e->xNowDen)
		{
            e->xNowWhole += e->xNowDir;
            e->xNowNum -= e->xNowDen;
        }
    }
	
    if (numCoords % 2)  /* Protect from degenerate polygons */
        xCoords[numCoords] = xCoords[numCoords - 1], numCoords++;
	
    for ( long i = 0; i < numCoords; i += 2)
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
			
			long x = end - start;
			
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
					
					long x = end - start;
					
					if( addition)
					{
						while( x-- > 0)
						{
							if( *curPix >= min && *curPix <= max) *curPix += newVal;
							
							if( orientation) curPix ++;
							else curPix += w;
						}
					}
					else
					{
						while( x-- > 0)
						{
							if( *curPix >= min && *curPix <= max) *curPix = newVal;
							
							if( orientation) curPix ++;
							else curPix += w;
						}
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
					
					long x = end - start;
					
					while( x-- > 0)
					{
						unsigned char*  rgbPtr = (unsigned char*) curPix;
						
						if( addition)
						{
							if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] += newVal;
							if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] += newVal;
							if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] += newVal;
						}
						else
						{
							if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] = newVal;
							if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] = newVal;
							if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] = newVal;
						}
						
						if( orientation) curPix ++;
						else curPix += w;
					}
				}
			}
			else		// INSIDE
			{
				float	*restorePtr = nil;
				
				start = xCoords[i];		if( start < 0) start = 0;		if( start >= w) start = w;
				end = xCoords[i + 1];	if( end < 0) end = 0;			if( end >= w) end = w;
				
				switch( orientation)
				{
					case 0:		curPix = &pix[ (curY * ims) + (start * w) + stackNo];		if( restore && restoreImageCache) restorePtr = &[restoreImageCache[ curY] fImage][(start * w) + stackNo];			break;
					case 1:		curPix = &pix[ (curY * ims) + start + stackNo *w];			if( restore && restoreImageCache) restorePtr = &[restoreImageCache[ curY] fImage][start + stackNo *w];				break;
					case 2:		curPix = &pix[ (curY * w) + start];							if( restore && restoreImageCache) restorePtr = &[restoreImageCache[ stackNo] fImage][(curY * w) + start];			break;
				}
				
				long x = end - start;
				
				if( x >= 0)
				{
					if( restore && restoreImageCache)
					{
						if( RGB == NO )
						{
							if( orientation)
							{
								while( x-- >= 0)
								{
									*curPix = *restorePtr;
									
									curPix ++;
									restorePtr ++;
								}
							}
							else
							{
								while( x-- >= 0)
								{
									*curPix = *restorePtr;
									
									curPix += w;
									restorePtr += w;
								}
							}
						}
						else
						{
							if( orientation )
							{
								while( x-- >= 0)
								{
									unsigned char*  rgbPtr = (unsigned char*) curPix;
									
									rgbPtr[ 1] = restorePtr[ 1];
									rgbPtr[ 2] = restorePtr[ 2];
									rgbPtr[ 3] = restorePtr[ 3];
									
									curPix ++;
									restorePtr ++;
								}
							}
							else
							{
								while( x-- >= 0 )
								{
									unsigned char*  rgbPtr = (unsigned char*) curPix;
									
									rgbPtr[ 1] = restorePtr[ 1];
									rgbPtr[ 2] = restorePtr[ 2];
									rgbPtr[ 3] = restorePtr[ 3];
									
									curPix += w;
									restorePtr += w;
								}
							}
						}
					}
					else
					{
						if( RGB == NO )
						{
							if( addition )
							{
								while( x-- >= 0 )
								{
									if( *curPix >= min && *curPix <= max) *curPix += newVal;
									
									if( orientation) curPix ++;
									else curPix += w;
								}
							}
							else
							{
								while( x-- >= 0)
								{
									if( *curPix >= min && *curPix <= max) *curPix = newVal;
									
									if( orientation) curPix ++;
									else curPix += w;
								}
							}
						}
						else
						{
							while( x-- >= 0)
							{
								unsigned char*  rgbPtr = (unsigned char*) curPix;
								
								if( addition )
								{
									if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] += newVal;
									if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] += newVal;
									if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] += newVal;
								}
								else
								{
									if( rgbPtr[ 1] >= min && rgbPtr[ 1] <= max) rgbPtr[ 1] = newVal;
									if( rgbPtr[ 2] >= min && rgbPtr[ 2] <= max) rgbPtr[ 2] = newVal;
									if( rgbPtr[ 3] >= min && rgbPtr[ 3] <= max) rgbPtr[ 3] = newVal;
								}
								
								if( orientation) curPix ++;
								else curPix += w;
							}
						}
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
					 BOOL addition,
					 BOOL RGB,
					 BOOL compute,
					 float *imax,
					 float *imin,
					 long *count,
					 float *itotal,
					 float *idev,
					 float imean,
					 long orientation,
					 long stackNo,
					 BOOL restore)
{
	struct edge **edgeTable = (struct edge **) malloc( MAXVERTICAL * sizeof( struct edge *));
    struct	edge *active;
	long curY;
	
    FillEdges(p, no, edgeTable);
	
    for ( curY = 0; edgeTable[ curY] == NULL; curY++ )
	{
        if (curY == MAXVERTICAL - 1)
		{
			free( edgeTable);
			return;     /* No edges in polygon */
		}
	}
	
    for (active = NULL; (active = UpdateActive(active, edgeTable, curY)) != NULL; curY++)
	{
		DrawRuns(active, curY, pix, w, h, min, max, outside, newVal, addition, RGB, compute, imax, imin, count, itotal, idev, imean, orientation, stackNo, restore);
	}
	
	free( edgeTable);
}

static inline long pnpoly( NSPoint *p, long count, float x, float y)
{
	long	c = 0;
    
    for ( int i = 0, j = count-1; i < count; j = i++ )
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
	long	c = 0;
    
    for ( int i = 0, j = count-1; i < count; j = i++ )
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

void erase_outside_circle(char *buf, int width, int height, int cx, int cy, int rad, char blackIndex)
{
	int		x,y;
	int		xsqr;
	int		inw = rad*2;
	int		radsqr = (inw*inw)/4;
	
	if( cx < 0 || cx >= width) return;
	if( cy < 0 || cy >= height) return;
	
	cx -= rad;
	cy -= rad;
	
	// top
	for(y = 0; y <= cy; y++)
	{
		for(x = 0; x < width; x++) buf[ x + y*width] = blackIndex;
	}
	
	// bottom
	for(y = cy+inw; y < height; y++)
	{
		for(x = 0; x < width; x++) buf[ x + y*width] = blackIndex;
	}
	
	// left + right
	for(y = cy; y < cy+inw; y++)
	{
		for(x = 0; x <= cx; x++) buf[ x + y*width] = blackIndex;
		for(x = cx+inw; x < width; x++) buf[ x + y*width] = blackIndex;
	}
	
	for(x = 0; x < rad; x++)
	{
		xsqr = x*x;
		for( y = 0 ; y < rad; y++)
		{
			char draw;
			
			if((xsqr + y*y) < radsqr)
			{
				draw = 0;
			}
			else
			{
				draw = 1;
			}
			
			if( draw)
			{
				int xx, yy;
				
				xx = rad+x+cx;	yy = rad+y+cy;
				if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
				
				xx = rad-x+cx;	yy = rad+y+cy;
				if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
				
				xx = rad+x+cx;	yy = rad-y+cy;
				if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
				
				xx = rad-x+cx;	yy = rad-y+cy;
				if( xx >= 0 && xx < width && yy >= 0 && yy < height) buf[ xx + yy*width] = blackIndex;
			}
		}
	}
}

@interface PixThread : NSObject
{
}
@end

@implementation PixThread

- (void) computeMax:(float*) fResult pos:(int) pos threads:(int) threads object: (DCMPix*) o
{
	float				*fNext = NULL;
	long				from, to, size = [o pheight] * [o pwidth];
	
	from = (pos * size) / threads;
	to = ((pos+1) * size) / threads;
	size = to - from;
	
	NSArray *p = o.pixArray;
	int ppos = o.pixPos;
	int stack = o.stack;
	int stackDirection = o.stackDirection;
	int stackMode = o.stackMode;
	
	for( int i = 1; i < stack; i++ )
	{
		int res;
		if( stackDirection) res = ppos-i;
		else res = ppos+i;
		
		if( res < p.count && res >= 0 )
		{
			fNext = [[p objectAtIndex: res] fImage];
			if( fNext )
			{
				if( stackMode == 2) vDSP_vmax( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
				else if( stackMode == 1) 
				{
					vDSP_vadd( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
					if( from == 0) o.countstackMean++;
				}
				else vDSP_vmin( fResult + from, 1, fNext + from, 1, fResult + from, 1, size);
			}
		}
	}
	
	[processorsLock lock];
	[processorsLock unlockWithCondition: [processorsLock condition]-1];
}

- (void)computeMaxThread: (NSDictionary*)dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSConditionLock *threadLock = [dict valueForKey:@"threadLock"];
	
	int p = MPProcessors ();
	
	do
	{
		[threadLock lockWhenCondition: 1];
		
		[self computeMax: [[dict valueForKey:@"fResult"] pointerValue] pos: [[dict valueForKey:@"pos"] intValue] threads: p object: [dict valueForKey:@"self"]];
		
		[threadLock unlockWithCondition: 0];
	}
	while( 1);
	
	[pool release];
}

- (void)applyNonLinearWLWWThread: (NSDictionary*)dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSConditionLock *threadLock = [dict valueForKey:@"threadLock"];
	
	do
	{
		[threadLock lockWhenCondition: 1];
		
		DCMPix *o = [dict valueForKey:@"self"];
		int startLine = [[dict valueForKey:@"start"] intValue];
		int endLine = [[dict valueForKey:@"end"] intValue];
		
		register int			ii = (endLine - startLine) * [o pwidth];
		register unsigned char	*dst8Ptr = (unsigned char*) [o baseAddr] + startLine * [o pwidth];
		register float			*src32Ptr = (float*) [[dict valueForKey:@"src"] pointerValue];
		register float			from = [o wl] - [o ww]/2.;
		register float			ratio = 4096. / [o ww];
		register float			*tfPtr = [o transferFunctionPtr];
		
		src32Ptr += startLine * [o pwidth];
		
		if( tfPtr)
		{
			while( ii-- > 0 )
			{
				int value = ratio * (*src32Ptr++ - from);
				
				if( value < 0) value = 0;
				else if( value >= 4095) value = 4095;
				
				*dst8Ptr++ = 255.*tfPtr[ value];
			}
		}
		
		[processorsLock lock];
		[processorsLock unlockWithCondition: [processorsLock condition]-1];
		
		[threadLock unlockWithCondition: 0];
	}
	while( 1);

	[pool release];
}
@end

@implementation DCMPix

@synthesize countstackMean, stackDirection, full32bitPipeline, needToCompute8bitRepresentation;
@synthesize frameNo;
@synthesize minValueOfSeries, maxValueOfSeries;
@synthesize isRGB, pwidth = width, pheight = height;
@synthesize pixelRatio, transferFunction, subPixOffset, isOriginDefined;

@synthesize DCMPixShutterRectWidth = shutterRect_w;
@synthesize DCMPixShutterRectHeight = shutterRect_h;
@synthesize DCMPixShutterRectOriginX = shutterRect_x;
@synthesize DCMPixShutterRectOriginY = shutterRect_y;

@synthesize frameOfReferenceUID;
@synthesize repetitiontime, echotime;
@synthesize flipAngle, laterality;
@synthesize protocolName, viewPosition, patientPosition;

@synthesize serieNo, pixArray;
@synthesize pixPos, transferFunctionPtr;
@synthesize stackMode, generated, generatedName;
@synthesize sourceFile, imageObj;
@synthesize srcFile, annotationsDictionary;

// SUV properties
@synthesize philipsFactor, patientsWeight;
@synthesize halflife, radionuclideTotalDose;
@synthesize radionuclideTotalDoseCorrected, acquisitionTime;
@synthesize radiopharmaceuticalStartTime, SUVConverted;
@synthesize hasSUV, decayFactor;
@synthesize units, decayCorrection;
@synthesize displaySUVValue;

@synthesize isLUT12Bit;

+ (BOOL) IsPoint:(NSPoint) x inPolygon:(NSPoint*) pts size:(int) no
{
	if( pnpoly( pts, no, x.x, x.y))
		return YES;
	
	return NO;
}

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

+ (void) resetUserDefaults
{
	gUserDefaultsSet = NO;
}

+ (void) checkUserDefaults: (BOOL) update
{
	// Why this? NSUserDefaults performances are poor if not in main thread
	
	if( update) gUserDefaultsSet = NO;
	
	if( gUserDefaultsSet == NO)
	{
		gUserDefaultsSet = YES;
		
		gUseShutter = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseShutter"];
		gDisplayDICOMOverlays = [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayDICOMOverlays"];
		gUseVOILUT = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseVOILUT"];
		gUSEPAPYRUSDCMPIX = [[NSUserDefaults standardUserDefaults] boolForKey:@"USEPAPYRUSDCMPIX2"];
		gUseJPEGColorSpace = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseJPEGColorSpace"];
		gFULL32BITPIPELINE = [[NSUserDefaults standardUserDefaults] boolForKey:@"FULL32BITPIPELINE"];
		
#ifdef STATIC_DICOM_LIB
		gUSEPAPYRUSDCMPIX = YES;
		gUseShutter = NO;
		gDisplayDICOMOverlays = NO;
		gUseJPEGColorSpace = NO;
		gFULL32BITPIPELINE = NO;
#endif
		
		//		NSLog( @"gUseShutter == %d", gUseShutter);
		//		NSLog( @"gDisplayDICOMOverlays == %d", gDisplayDICOMOverlays);
		//		NSLog( @"gUseVOILUT == %d", gUseVOILUT);
		//		NSLog( @"gUSEPAPYRUSDCMPIX == %d", gUSEPAPYRUSDCMPIX);
	}
}

+ (void) setRunOsiriXInProtectedMode:(BOOL) v
{
	runOsiriXInProtectedMode = v;
}

+ (BOOL) isRunOsiriXInProtectedModeActivated
{
	return runOsiriXInProtectedMode;
}

+ (NSPoint) originDeltaBetween:(DCMPix*) pix1 And:(DCMPix*) pix2
{
	double destPixelSpacingX = [pix1 pixelSpacingX];
	double destPixelSpacingY = [pix1 pixelSpacingY];
	double senderPixelSpacingX = [pix2 pixelSpacingX];
	double senderPixelSpacingY = [pix2 pixelSpacingY];
	
	
	if( destPixelSpacingX == 0 || destPixelSpacingY == 0 || senderPixelSpacingX == 0 || senderPixelSpacingY == 0)
	{
		return NSMakePoint( 0, 0);
	}
	
	double destWidth = [pix1 pwidth];
	double destHeight =[pix1 pheight];
	double vectorP1[ 9];
	double destOrigin[ 3];
	
	[pix1 orientationDouble: vectorP1];
	destOrigin[ 0] = [pix1  originX] * vectorP1[ 0] + [pix1  originY] * vectorP1[ 1] + [pix1  originZ] * vectorP1[ 2];
	destOrigin[ 1] = [pix1  originX] * vectorP1[ 3] + [pix1  originY] * vectorP1[ 4] + [pix1  originZ] * vectorP1[ 5];
	destOrigin[ 2] = [pix1  originX] * vectorP1[ 6] + [pix1  originY] * vectorP1[ 7] + [pix1  originZ] * vectorP1[ 8];
	
	double vectorP2[ 9];
	double senderOrigin[ 3];
	
	[pix2 orientationDouble: vectorP2];
	senderOrigin[ 0] = [pix2  originX] * vectorP2[ 0] + [pix2  originY] * vectorP2[ 1] + [pix2  originZ] * vectorP2[ 2];
	senderOrigin[ 1] = [pix2  originX] * vectorP2[ 3] + [pix2  originY] * vectorP2[ 4] + [pix2  originZ] * vectorP2[ 5];
	senderOrigin[ 2] = [pix2  originX] * vectorP2[ 6] + [pix2  originY] * vectorP2[ 7] + [pix2  originZ] * vectorP2[ 8];
	
	NSPoint offset;

	offset.x = destOrigin[ 0] + destPixelSpacingX * destWidth/2 - (senderOrigin[ 0] + senderPixelSpacingX * [pix2 pwidth]/2);
	offset.y = destOrigin[ 1] + destPixelSpacingY * destHeight/2 - (senderOrigin[ 1] + senderPixelSpacingY * [pix2 pheight]/2);
	
	offset.x /= senderPixelSpacingX;
	offset.y /= senderPixelSpacingY;
	
	offset.y *= [pix2 pixelRatio];
	
	return offset;
}

+ (NSImage*) resizeIfNecessary:(NSImage*) currentImage dcmPix: (DCMPix*) dcmPix
{
	NSRect sourceRect = NSMakeRect(0.0, 0.0, [currentImage size].width, [currentImage size].height);
	NSRect imageRect;
	
	if(	[currentImage size].width > 512 &&
	   [currentImage size].height > 512)
	{
		// Rescale image if resolution is too high, compared to the original resolution
		
		float MAXSIZE = 1.5;
		
		int minWidth = [dcmPix pwidth]*MAXSIZE;
		int minHeight = [dcmPix pheight]*MAXSIZE;
		
		if( minWidth < 768) MAXSIZE = 768 / [dcmPix pwidth];
		if( minHeight < 768) MAXSIZE = 768 / [dcmPix pheight];
		
		minWidth = [dcmPix pwidth]*MAXSIZE;
		minHeight = [dcmPix pheight]*MAXSIZE;
		
		if( [currentImage size].width > minWidth && [currentImage size].height > minHeight)
		{
			if( [currentImage size].width/[dcmPix pwidth] < [currentImage size].height / [dcmPix pheight])
			{
				float ratio = [currentImage size].width / (minWidth);
				imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
			}
			else
			{
				float ratio = [currentImage size].height / (minHeight);
				imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
			}
			[currentImage setScalesWhenResized:YES];
			
			NSImage *compositingImage = [[NSImage alloc] initWithSize: imageRect.size];
			
			[compositingImage lockFocus];
			//		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationDefault];
			[currentImage drawInRect: imageRect fromRect: sourceRect operation: NSCompositeCopy fraction: 1.0];
			[compositingImage unlockFocus];
			
			NSLog( @"New Size: %f %f", [compositingImage size].width, [compositingImage size].height);
			
			return [compositingImage autorelease];
		}
	}
	
	return currentImage;
}

- (float) maxValueOfSeries
{
	if( maxValueOfSeries == 0)
	{
		float tmaxValueOfSeries = -100000;
		
		for( DCMPix* pix in pixArray)	 
		{
			if( tmaxValueOfSeries < [pix fullwl] + [pix fullww]/2) tmaxValueOfSeries = [pix fullwl] + [pix fullww]/2;
		}
		
		for( DCMPix* pix in pixArray)
		{
			[pix setMaxValueOfSeries: tmaxValueOfSeries];
		}
	}
	
	return maxValueOfSeries;
}

- (float) minValueOfSeries
{
	if( minValueOfSeries == 0)
	{
		float tminValueOfSeries = 100000;
		
		for( DCMPix* pix in pixArray)	 
		{
			if( tminValueOfSeries > [pix fullwl] - [pix fullww]/2) tminValueOfSeries = [pix fullwl] - [pix fullww]/2;
		}
		
		for( DCMPix* pix in pixArray)
		{
			[pix setMinValueOfSeries: tminValueOfSeries];
		}
	}
	
	return minValueOfSeries;
}

- (NSImage*) image
{
	unsigned char		*buf = nil;
	long				i;
	NSImage				*imageRep = nil;
	NSBitmapImageRep	*rep;
	
	[self compute8bitRepresentation];
	
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
				initWithBitmapDataPlanes:nil
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
		rep = [[[NSBitmapImageRep alloc]
				initWithBitmapDataPlanes:nil
				pixelsWide:width
				pixelsHigh:height
				bitsPerSample:8
				samplesPerPixel:1
				hasAlpha:NO
				isPlanar:NO
				colorSpaceName:NSCalibratedWhiteColorSpace
				bytesPerRow:width
				bitsPerPixel:8] autorelease];
		
		memcpy( [rep bitmapData], baseAddr, height*width);
		
		imageRep = [[[NSImage alloc] init] autorelease];
		[imageRep addRepresentation:rep];
	}
	
	return imageRep;
}

- (unsigned char *) ConvertYbrToRgb: (unsigned char *) ybrImage :(int) w :(int) h :(long) theKind :(char) planarConfig
{
	long			loop, size;
	unsigned char		*pYBR, *pRGB;
	unsigned char		*theRGB;
	int			y, y1, r, x, yy;
	
	
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
		for (loop = 0, pYBR = ybrImage; loop < size; loop++, pYBR += 3)
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
		// loop on the pixels of the image
		pYBR = ybrImage;
		
		for( yy = 0; yy < h; yy++)
		{
			unsigned char	*rr = pRGB;
			unsigned char	*rr2 = pRGB+3*w;
			
			for( x = 0; x < w; x++)
			{
				y  = (int) pYBR [0];
				b = (int) pYBR [1];
				r = (int) pYBR [2];
				
				*(rr) = y;
				*(rr+1) = b;
				*(rr+2) = r;
				
//				*(rr2) = y;
//				*(rr2+1) = b;
//				*(rr2+2) = r;
				
				pYBR += 3;
				rr += 3;
				rr2 += 3;
			}
			
//			pRGB += 2*w*3;
			pRGB += w*3;
		}
		break;
		
        case YBR_PARTIAL_422 :	// YBR_PARTIAL_422
		// loop on the pixels of the image
		for (loop = 0, pYBR = ybrImage; loop < (size / 2); loop++)
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
	for (loop = 0; loop < size; loop++, pY++, pB++, pR++)
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
    long			count, no, size;
	float			*values;
	long			*xPoints, *yPoints;
    NSPoint			upleft, downright;
	NSPoint			*pts;
	NSMutableArray  *ptsTemp = roi.points;
	
    [self CheckLoad];
	
	pts = (NSPoint*) malloc( ptsTemp.count * sizeof(NSPoint) );
	no = [ptsTemp count];
	for( long i = 0; i < no; i++ )
	{
		pts[ i] = [[ptsTemp objectAtIndex: i] point];
		//	pts[ i].x+=1.5;
		//	pts[ i].y+=1.5;
	}	
	
	upleft = downright = [[ptsTemp objectAtIndex:0] point];
	
	for( long i = 0; i < [ptsTemp count]; i++)
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
	if( values )
	{
		count = 0;
		for( long i = 0; i < size; i++ )
		{
			if( yPoints[ i] >= 0 && yPoints[ i] < height && xPoints[ i] >= 0 && xPoints[ i] < width )
			{
				if( isRGB )
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
	
	if( roi ) free( pts );
	
	free( xPoints );
	free( yPoints );
	
	return values;
}

- (float*) getROIValue: (long*)numberOfValues : (ROI*)roi : (float**)locations
{
    long			count = 0, no;
	float			*values = nil;
	long			upleftx, uplefty, downrightx, downrighty;
	NSPoint			*pts;
	
	if( roi.type == tPlain )
	{
		long			textWidth = roi.textureWidth;
		long			textHeight = roi.textureHeight;
		long			textureUpLeftCornerX = roi.textureUpLeftCornerX;
		long			textureUpLeftCornerY = roi.textureUpLeftCornerY;
		unsigned char	*buf = roi.textureBuffer;
		
		values = (float*) malloc( textHeight*textWidth* sizeof(float));
		
		if( locations) *locations = (float*) malloc( textHeight*textWidth*2* sizeof(float));
		
		if( values)	{
			count = 0;
			
			for( long y = 0; y < textHeight; y++ )
			{
				for( long x = 0; x < textWidth; x++ )
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
									(*locations)[ count*2] = xx;
									(*locations)[ count*2 + 1] = yy;
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
		NSMutableArray  *ptsTemp = [roi splinePoints];
		
		if( [ptsTemp count] == 0) return nil;
		
		[self CheckLoad];
		
		pts = (NSPoint*) malloc( [ptsTemp count] * sizeof(NSPoint));
		no = [ptsTemp count];
		for( long i = 0; i < no; i++) pts[ i] = [[ptsTemp objectAtIndex: i] point];
		
		upleftx = downrightx = [[ptsTemp objectAtIndex:0] x];
		uplefty = downrighty = [[ptsTemp objectAtIndex:0] y];
		
		for( long i = 0; i < [ptsTemp count]; i++ )
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
		long y = (downrighty - uplefty);
		long x = (downrightx - upleftx);
		values = (float*) malloc( x*y* sizeof(float));
		if( locations) *locations = (float*) malloc( x*y*2* sizeof(float));
		
		if( values)	{
			
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
						
						if( locations )
						{
							if( *locations )	{
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
		
		if( count > x*y ) NSLog(@"%d / %d", count, (long) ((downrighty - uplefty) * (downrightx - upleftx)));
		
		if( roi ) free( pts );
	}
	
	*numberOfValues = count;
	
	return values;
}

- (BOOL)isInROI: (ROI*)roi: (NSPoint)pt
{
	BOOL			result = NO;
	long			minx, maxx, miny, maxy;
	NSPoint			*pts;
		
    [self CheckLoad];
	
	if( roi)
	{
		if( roi.type == tPlain)
		{
			unsigned char *buf = roi.textureBuffer;
			
			if( pt.x >= roi.textureUpLeftCornerX && pt.x < roi.textureUpLeftCornerX + roi.textureWidth &&
				pt.y >= roi.textureUpLeftCornerY && pt.y < roi.textureUpLeftCornerY + roi.textureHeight)
			{
				int pos = pt.x - roi.textureUpLeftCornerX + (pt.y - roi.textureUpLeftCornerY) * roi.textureWidth;
				if( buf[ pos]) return YES;
				else return NO;
			}
			else return NO;
		}
		else
		{
			NSMutableArray  *ptsTemp = [roi splinePoints];
			
			minx = maxx = [[ptsTemp objectAtIndex: 0] x];
			miny = maxy = [[ptsTemp objectAtIndex: 0] y];
			
			// Find the max rectangle of the ROI
			for( MyPoint *pt in ptsTemp)
			{	
				if( minx > [pt x]) minx = [pt x];
				if( maxx < [pt x]) maxx = [pt x];
				if( miny > [pt y]) miny = [pt y];
				if( maxy < [pt y]) maxy = [pt y];
			}
			
			if( pt.x < minx || pt.x > maxx) return NO;
			if( pt.y < miny || pt.y > maxy) return NO;
			
			if( roi.type == tROI) return YES;
			
			int no = ptsTemp.count;
			pts = (NSPoint*) malloc( no * sizeof(NSPoint));
			int i = 0;
			for( MyPoint *pt in ptsTemp) pts[ i++] = [pt point];
			
			long x = pt.x;
			long y = pt.y;
			
			if( pnpoly( pts, no, x, y))	result = YES;
			
			free( pts);
		}
	}
	
	return result;
}

- (void) prepareRestore
{
	if( restoreImageCache) [self freeRestore];
	
	restoreImageCache = malloc( [pixArray count] * sizeof(void*));
	
	if( restoreImageCache )	{
		for( int i = 0; i < [pixArray count]; i++ )
		{
			DCMPix	*s = [pixArray objectAtIndex:i];
			
			restoreImageCache[ i ] = [[DCMPix alloc] myinit: s.srcFile : i : pixArray.count : nil : s.frameNo : 0];
		}
		
		NSLog( @"prepare Restore cache");
	}
	else NSLog( @"prepare Restore cache - FAILED");
}

- (void) freeRestore
{
	if( restoreImageCache)
	{
		for( int i = 0; i < pixArray.count; i++ )	[restoreImageCache[ i] release];
		
		free( restoreImageCache);
		restoreImageCache = nil;
		
		NSLog( @"free Restore cache");
	}
}

- (unsigned char*) getMapFromPolygonROI:(ROI*) roi size:(NSSize*) size origin:(NSPoint*) ROIorigin
{	
	unsigned char*	map = nil;
	float*			tempImage = nil;
	
	if( [roi type] == tCPolygon || [roi type] == tOPolygon || [roi type] == tPencil )
	{
		NSArray *ptsTemp = [roi points];
		
		int no = ptsTemp.count;
		struct NSPointInt *ptsInt = (struct NSPointInt*) malloc( no * sizeof(struct NSPointInt) );
		
		if( no == 0) NSLog( @"******** ERROR no == 0 getMapFromPolygonROI");
		
		int minX,maxX,minY,maxY;
		
		for( int i = 0; i < no; i++)
		{
			ptsInt[ i].x = [[ptsTemp objectAtIndex: i] point].x + 0.5;
			ptsInt[ i].y = [[ptsTemp objectAtIndex: i] point].y + 0.5;
			
			if( i == 0)
			{
				minX = ptsInt[ 0].x;
				maxX = ptsInt[ 0].x;
				minY = ptsInt[ 0].y;
				maxY = ptsInt[ 0].y;
			}
			else
			{
				if( ptsInt[ i].x < minX) minX = ptsInt[ i].x;
				if( ptsInt[ i].x > maxX) maxX = ptsInt[ i].x;
				if( ptsInt[ i].y < minY) minY = ptsInt[ i].y;
				if( ptsInt[ i].y > maxY) maxY = ptsInt[ i].y;
			}
		}
		
		for( int i = 0; i < no; i++)
		{
			ptsInt[ i].x -= minX;
			ptsInt[ i].y -= minY;
		}
		
		size->width = maxX-minX+2;
		size->height = maxY-minY+2;
		
		ROIorigin->x = minX;
		ROIorigin->y = minY;
		
		map = malloc( size->height * size->width);
		tempImage = calloc( 1, size->height * size->width * sizeof(float));
		
		// Need to clip?
//		NSPointInt *pTemp;
		int yIm, xIm;
		
		yIm = size->height;
		xIm = size->width;
		
//		BOOL clip = NO;
		
//		for( int i = 0; i < no && clip == NO; i++ ) {
//			if( ptsInt[ i].x < 0) clip = YES;
//			if( ptsInt[ i].y < 0) clip = YES;
//			if( ptsInt[ i].x >= width) clip = YES;
//			if( ptsInt[ i].y >= height) clip = YES;
//		}
//		
//		if( clip ) {
//			long newNo;
//			
//			pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
//			CLIP_Polygon( ptsInt, no, pTemp, &newNo, width, height);
//			
//			free( ptsInt);
//			ptsInt = pTemp;
//			
//			no = newNo;
//		}
		
		if( ptsInt != nil && no > 1 )	{
			BOOL restore = NO, addition = NO, outside = NO;
			
			ras_FillPolygon( ptsInt, no, tempImage, size->width, size->height, [pixArray count], -99999, 99999, outside, 255, addition, NO, NO, nil, nil, nil, nil, nil, 0, 2, 0, restore);
		}
		
		// Convert float to char
		int i = size->height * size->width;
		while ( i-- > 0 )	{
			map[ i] = tempImage[ i];
		}
		
		// Keep a free box around the image
		for ( int i = 0 ; i < (int)size->width; i++ )
		{
			map[ i] = 0;
			map[(int)size->height*((int)size->width-2) +i] = 0;
		}
		
		for ( int i = 0 ; i < (int)size->height; i++)
		{
			map[ i*(int)size->width] = 0;
			map[ i*(int)size->width + (int)size->width-1] = 0;
		}
		
		free( tempImage);
		free( ptsInt);
	}
	
	return map;
}

- (void) fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition;
{
	#ifdef OSIRIX_VIEWER
		return [self fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition spline: [ROI splineForROI]];
	#else
		return [self fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition spline: NO];
	#endif
}

- (void) fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue :(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) addition spline:(BOOL) spline;
{
    long				no = 0;
	long				y;
    long				uplefty, downrighty, ims = width * height;
	struct NSPointInt	*ptsInt = nil;
	NSMutableArray		*ptsTemp = nil;
	float				*fTempImage;
	BOOL				clip;
	
    [self CheckLoad];
	
	if( stackNo < 0 && restore)	{
		NSLog( @"error !!!! stackNo < 0 && restore");
		restore = NO;
	}
	
	if( roi )
	{
		if( roi.type == tPlain )
		{
			long			textWidth = roi.textureWidth;
			long			textHeight = roi.textureHeight;
			long			textureUpLeftCornerX = roi.textureUpLeftCornerX;
			long			textureUpLeftCornerY = roi.textureUpLeftCornerY;
			unsigned char	*buf = roi.textureBuffer;
			
			// *** INSIDE
			
			if( outside == NO)
			{
				for( y = textureUpLeftCornerY; y < textureUpLeftCornerY + textHeight; y++)
				{
					if( isRGB)
					{
						
						unsigned char *rgbPtr = (unsigned char*) (fImage + textureUpLeftCornerX + y*width);
						unsigned char *fTempRestore = nil;
						if( restore) fTempRestore = (unsigned char*) &[restoreImageCache[ stackNo] fImage][textureUpLeftCornerX + y*width];
						
						for( long x = textureUpLeftCornerX; x < textureUpLeftCornerX + textWidth; x++)
						{
							if( *buf++)
							{
								if( x >= 0 && x < width && y >= 0 && y < height)
								{
									if( restore)
									{
										rgbPtr[ 1] = fTempRestore[ 1];
										rgbPtr[ 2] = fTempRestore[ 2];
										rgbPtr[ 3] = fTempRestore[ 3];
									}
									else if( addition )
									{
										if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] += newVal;
										if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] += newVal;
										if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] += newVal;
									}
									else
									{
										if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
										if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
										if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
									}
								}
							}
							rgbPtr += 4;
						}
					}
					else
					{
						float *fTempImage = fImage + textureUpLeftCornerX + y*width;
						float *fTempRestore = nil;
						if( restore) fTempRestore = &[restoreImageCache[ stackNo] fImage][textureUpLeftCornerX + y*width];
						
						for( long x = textureUpLeftCornerX; x < textureUpLeftCornerX + textWidth; x++)
						{
							if( *buf++)
							{
								if( x >= 0 && x < width && y >= 0 && y < height)
								{
									if( restore) *fTempImage = *fTempRestore;
									else if( addition)
									{ 
										if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage += newVal;
									}
									else
									{
										if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
									}
								}
							}
							fTempImage++;
							fTempRestore++;
						}
					}
				}
			}
			
			// *** OUTSIDE
			
			else
			{
				for( long y = 0; y < height; y++ ) 
				{
					for( long x = 0; x < width; x++)
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
								
								if( addition)
								{
									if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] += newVal;
									if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] += newVal;
									if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] += newVal;
								}
								else
								{
									if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
									if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
									if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
								}
							}
							else
							{
								float	*fTempImage = &fImage[ (yy * width) + xx];
								
								if( addition)
								{
									if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage += newVal;
								}
								else
								{
									if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
								}
							}
						}
					}
				}
			}
			
			return;
		}
		else
		{
			if( spline) ptsTemp = [roi splinePoints];
			else ptsTemp = [roi points];

			no = ptsTemp.count;

			ptsInt = (struct NSPointInt*) malloc( no * sizeof( struct NSPointInt));

			for( long i = 0; i < no; i++ )
			{
				ptsInt[ i].x = [[ptsTemp objectAtIndex: i] point].x;
				ptsInt[ i].y = [[ptsTemp objectAtIndex: i] point].y;
			}
			
			// Need to clip?
			NSPointInt *pTemp;
			long yIm, xIm;
			
			switch( orientationStack)
			{
				case 0:	yIm = pixArray.count;		xIm = width;	break;
				case 1:	yIm = pixArray.count;		xIm = height;	break;
				case 2:	yIm = height;				xIm = width;	break;
			}
			
			clip = NO;
			switch( orientationStack)
			{
				case 2:
					for( long i = 0; i < no && clip == NO; i++)
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
					for( long i = 0; i < no && clip == NO; i++)
					{
						if( ptsInt[ i].x < 0) clip = YES;
						if( ptsInt[ i].y < 0) clip = YES;
						if( ptsInt[ i].x >= height) clip = YES;
						if( ptsInt[ i].y >= pixArray.count ) clip = YES;
					}
					
					if( clip)
					{
						long newNo;
						
						pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
						CLIP_Polygon( ptsInt, no, pTemp, &newNo, height, pixArray.count );
						
						free( ptsInt);
						ptsInt = pTemp;
						no = newNo;
					}
					break;
					
					case 1:
					for( long i = 0; i < no && clip == NO; i++)
					{
						if( ptsInt[ i].x < 0) clip = YES;
						if( ptsInt[ i].y < 0) clip = YES;
						if( ptsInt[ i].x >= width) clip = YES;
						if( ptsInt[ i].y >= pixArray.count ) clip = YES;
					}
					
					if( clip )
					{
						long newNo;
						
						pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
						CLIP_Polygon( ptsInt, no, pTemp, &newNo, width, pixArray.count );
						
						free( ptsInt);
						ptsInt = pTemp;
						no = newNo;
					}
					break;
			}
		}
	}
	else ptsInt = nil;
	
	if( outside)
	{
		long yIm, xIm;
		
		switch( orientationStack)
		{
			case 0:	yIm = pixArray.count;		xIm = width;	break;
			case 1:	yIm = pixArray.count;		xIm = height;	break;
			case 2:	yIm = height;				xIm = width;	break;
		}
		
		if( roi ) uplefty = downrighty = ptsInt[0].y;
		else
		{
			uplefty = 0;
			downrighty = yIm;
		}
		
		for( long i = 0; i < no; i++)
		{
			if( uplefty > ptsInt[i].y) uplefty = ptsInt[i].y;
			if( downrighty < ptsInt[i].y) downrighty = ptsInt[i].y;
		}
		
		if( uplefty < 0) uplefty = 0;
		if( uplefty >= yIm) uplefty = yIm-1;
		
		if( downrighty < 0) downrighty = 0;
		if( downrighty >= yIm) downrighty = yIm-1;
		
		
		if( isRGB )
		{
			for( long y = 0; y < uplefty ; y++ )
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( long x = 0; x < width ; x++)
				{
					unsigned char*  rgbPtr = (unsigned char*) fTempImage;
					
					if( rgbPtr[ 1] >= minValue && rgbPtr[ 1] <= maxValue) rgbPtr[ 1] = newVal;
					if( rgbPtr[ 2] >= minValue && rgbPtr[ 2] <= maxValue) rgbPtr[ 2] = newVal;
					if( rgbPtr[ 3] >= minValue && rgbPtr[ 3] <= maxValue) rgbPtr[ 3] = newVal;
					
					if( orientationStack) fTempImage++;
					else fTempImage += width;
				}
			}
			
			for( long y = downrighty; y < yIm ; y++)
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( long x = 0; x < width ; x++ )
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
			for( long y = 0; y < uplefty ; y++)
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( long x = 0; x < width ; x++ )
				{
					if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
					
					if( orientationStack) fTempImage ++;
					else fTempImage += width;
				}
			}
			
			for( long y = downrighty; y < yIm ; y++)
			{
				switch( orientationStack)
				{
					case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
					case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
					case 2:		fTempImage = fImage + width*y;							break;
				}
				
				for( long x = 0; x < width ; x++ )
				{ 
					if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
					
					if( orientationStack) fTempImage ++;
					else fTempImage += width;
				}
			}
		}
	}
	
	if( ptsInt != nil && no > 1)
	{
		ras_FillPolygon( ptsInt, no, fImage, width, height, pixArray.count, minValue, maxValue, outside, newVal, addition, isRGB, NO, nil, nil, nil, nil, nil, 0, orientationStack, stackNo, restore);
	}
	else
	{	// Fill the image that contains no ROI :
		if( outside)
		{
			long yIm, xIm;
			
			switch( orientationStack)
			{
				case 0:	yIm = pixArray.count;		xIm = width;	break;
				case 1:	yIm = pixArray.count;		xIm = height;	break;
				case 2:	yIm = height;				xIm = width;	break;
			}
			
			if( isRGB)
			{
				for( long y = 0; y < yIm ; y++ )
				{
					switch( orientationStack)
					{
						case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
						case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
						case 2:		fTempImage = fImage + width*y;							break;
					}
					
					for( long x = 0; x < xIm ; x++ )
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
				for( long y = 0; y < yIm ; y++)
				{
					switch( orientationStack)
					{
						case 1:		fTempImage = fImage + (y * ims) + stackNo*width;		break;
						case 0:		fTempImage = fImage + (y * ims) + stackNo;				break;
						case 2:		fTempImage = fImage + width*y;							break;
					}
					
					for( long x = 0; x < xIm ; x++ )
					{
						if( *fTempImage >= minValue && *fTempImage <= maxValue) *fTempImage = newVal;
						
						if( orientationStack) fTempImage ++;
						else fTempImage += width;
					}
				}
			}
		}
	}
	
	if( roi ) free( ptsInt);
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo
{
	return [self fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo :NO];
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside :(long) orientationStack :(long) stackNo :(BOOL) restore
{
	[self fillROI:(ROI*) roi newVal :(float) newVal minValue :(float) minValue maxValue:(float) maxValue outside :(BOOL) outside orientationStack :(long) orientationStack stackNo :(long) stackNo restore :(BOOL) restore addition:(BOOL) NO];
}

- (void) fillROI:(ROI*) roi :(float) newVal :(float) minValue :(float) maxValue :(BOOL) outside
{
	[self fillROI:roi :newVal :minValue :maxValue :outside :2 :-1];
}

- (int)calciumCofactorForROI:(ROI *)roi threshold:(int)threshold{
	int cf1Count = 0;
	int cf2Count = 0;
	int cf3Count = 0;
	int cf4Count = 0;
	int count = 0;
	[self CheckLoad];
	
	if( roi.type == tPlain )
	{
		long			textWidth = roi.textureWidth;
		long			textHeight = roi.textureHeight;
		long			textureUpLeftCornerX = roi.textureUpLeftCornerX;
		long			textureUpLeftCornerY = roi.textureUpLeftCornerY;
		unsigned char	*buf = roi.textureBuffer;
		float			*fImageTemp;
		
		for( int y = 0; y < textHeight; y++)
		{
			fImageTemp = fImage + ((y + textureUpLeftCornerY) * width) + textureUpLeftCornerX;
			
			for( int x = 0; x < textWidth; x++, fImageTemp++)
			{
				if( *buf++ != 0)
				{
					long	xx = (x + textureUpLeftCornerX);
					long	yy = (y + textureUpLeftCornerY);
					
					if( xx >= 0 && xx < width && yy >= 0 && yy < height)
					{
						if( isRGB == NO )
						{
							float	val = *fImageTemp;
							
							count++;
							//NSLog(@"x: %d  y: %d Calcium %f",xx, yy,  val);
							if(val > threshold) cf1Count++;
							if(val > 200) cf2Count++;
							if(val > 300) cf3Count++;
							if(val > 400) cf4Count++; 
						}
					}
				}
			}
		}
		if (cf4Count > 2) return 4;
		if (cf3Count > 2) return 3;
		if (cf2Count > 2) return 2;
		return 1;
	}
	else
		return 0;
}

- (void) computeROIInt:(ROI*) roi :(float*) mean :(float *)total :(float *)dev :(float *)min :(float *)max
{
	long count, no;
	float imax, imin, itotal, idev, imean;
	
	count = 0;
	itotal = 0;
	imean = 0;
	idev = 0;
	imin = 99999;
	imax = -99999;
	
	[self CheckLoad];
	
	if( roi.type == tPlain)
	{
		int	textWidth = roi.textureWidth;
		int	textHeight = roi.textureHeight;
		int	textureUpLeftCornerX = roi.textureUpLeftCornerX;
		int	textureUpLeftCornerY = roi.textureUpLeftCornerY;
		unsigned char *buf = roi.textureBuffer;
		float *fImageTemp;
		
		for( int y = 0; y < textHeight; y++ )
		{
			fImageTemp = fImage + ((y + textureUpLeftCornerY) * width) + textureUpLeftCornerX;
			
			for( int x = 0; x < textWidth; x++, fImageTemp++)
			{
				if( *buf++ != 0 )
				{
					int	xx = (x + textureUpLeftCornerX);
					int	yy = (y + textureUpLeftCornerY);
					
					if( xx >= 0 && xx < width && yy >= 0 && yy < height)
					{
						if( isRGB )
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
		
		if( count != 0) imean = itotal / count;
		
		if( dev != nil && count > 0 )
		{
			idev = 0;
			
			buf = [roi textureBuffer];
			
			for( int y = 0; y < textHeight; y++ )
			{
				fImageTemp = fImage + ((y + textureUpLeftCornerY) * width) + textureUpLeftCornerX;
				
				for( int x = 0; x < textWidth; x++, fImageTemp++)
				{
					if( *buf++ != 0)
					{
						int	xx = (x + textureUpLeftCornerX);
						int	yy = (y + textureUpLeftCornerY);
						
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
								float val = *fImageTemp;
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
		else if( dev) *dev = 0;
		
		if( max) *max = imax;
		if( min) *min = imin;
		if( total) *total = itotal;
		if( mean) *mean = imean;
	}
	else
	{
		NSMutableArray  *ptsTemp = [roi splinePoints];
		NSPointInt		*pts;
		
		pts = (NSPointInt*) malloc( ptsTemp.count * sizeof(NSPointInt) );
		no = [ptsTemp count];
		for( int i = 0; i < no; i++ )
		{
			pts[ i].x = [[ptsTemp objectAtIndex: i] point].x;
			pts[ i].y = [[ptsTemp objectAtIndex: i] point].y;
		}
		
		// Need to clip?
		NSPointInt *pTemp;
		BOOL clip = NO;
		
		for( int i = 0; i < no && clip == NO; i++)
		{
			if( pts[ i].x < 0) clip = YES;
			if( pts[ i].y < 0) clip = YES;
			if( pts[ i].x >= width) clip = YES;
			if( pts[ i].y >= height) clip = YES;
		}
		
		if( no == 1 )
		{
			if( clip )
			{
				if( max) *max = 0;
				if( min) *min = 0;
				if( mean) *mean = 0;
				if( total) *total = 0;
				if( dev) *dev = 0;
			}
			else if( isRGB)
			{
				unsigned char*  rgbPtr = (unsigned char*) &fImage[ (pts[ 0].y * width) + pts[ 0].x];
				
				float val = rgbPtr[ 0] + rgbPtr[ 1] + rgbPtr[2] / 3;
				
				if( max) *max = val;
				if( min) *min = val;
				if( mean) *mean = val;
				if( total) *total = val;
				if( dev) *dev = 0;
			}
			else
			{
				float	*curPix = &fImage[ (pts[ 0].y * width) + pts[ 0].x];
				
				float val = *curPix;
				
				if( max) *max = val;
				if( min) *min = val;
				if( mean) *mean = val;
				if( total) *total = val;
				if( dev) *dev = 0;
			}
		}
		else
		{
			if( clip )
			{
				long newNo;
				
				pTemp = (NSPointInt*) malloc( sizeof(NSPointInt) * 4 * no);
				CLIP_Polygon( pts, no, pTemp, &newNo, width, height);
				
				free( pts);
				pts = pTemp;
				
				no = newNo;
			}
			
			ras_FillPolygon( pts, no, fImage, width, height, pixArray.count, 0, 0, NO, 0, NO, isRGB, YES, &imax, &imin, &count, &itotal, nil, 0, 2, 0, NO);
			
			if( max) *max = imax;
			if( min) *min = imin;
			if( total) *total = itotal;
			
			if( count != 0) imean = itotal / count;
			
			if( dev != nil && count > 0)
			{
				idev = 0 ;
				
				ras_FillPolygon( pts, no, fImage, width, height, pixArray.count, 0, 0, NO, 0, NO, isRGB, YES, nil, nil, nil, nil, &idev, imean, 2, 0, NO);
				
				*dev = idev;
				*dev = *dev / (count-1);
				*dev = sqrt(*dev);
			}
			else if( dev) *dev = 0;
			
			if( mean) *mean = imean;
		}
		
		free( pts);
	}
	
	if( max)
	{
		if( *max == -99999) *max = 0;
	}
	
	if( min)
	{
		if( *min == 99999) *min = 0;
	}
}

- (void) computeROI:(ROI*) roi :(float*) mean :(float *)total :(float *)dev :(float *)min :(float *)max
{
	if( (stackMode == 1 || stackMode == 2 || stackMode == 3) && stack >= 1)
	{
		long	countstack = 0;
		float	meanslice, totalslice, devslice, minslice, maxslice;
		
		[self computeROIInt: roi :mean :total :dev :min :max];
		countstack++;
		
		for( long i = 1; i < stack; i++)
		{
			long next;
			if( stackDirection) next = pixPos-i;
			else next = pixPos+i;
			
			if( next < pixArray.count && next >= 0)
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

- (void) setRGB:(BOOL) b
{
	isRGB = b;
}

- (void) freefImageWhenDone:(BOOL) b
{
	if( b)
		fExternalOwnedImage = nil;
	else
		fExternalOwnedImage = fImage;
}

-(void) setfImage:(float*) ptr
{
	if( fExternalOwnedImage == nil)
	{
		if( fImage != nil)
		{
			free(fImage);
			fImage = nil;
		}
	}
	
	fImage = ptr;
	
	if( fExternalOwnedImage)
		fExternalOwnedImage = fImage;
}

- (BOOL) isLoaded
{
	BOOL f;
	if( fImage) f = YES;
	else f = NO;
	
	return f;
}

- (float*)fImage
{
    [self CheckLoad];
    return fImage;
}

- (double)pixelRatio { [self CheckLoad]; return pixelRatio; }

- (double)pixelSpacingY { [self CheckLoad]; return pixelSpacingY; }
- (double)pixelSpacingX { [self CheckLoad]; return pixelSpacingX; }

- (void)setPixelSpacingX :(double) s { [self CheckLoad];
	pixelSpacingX = s;
	if( pixelSpacingX) pixelRatio = pixelSpacingY / pixelSpacingX;
}

- (void)setPixelSpacingY :(double) s
{
	[self CheckLoad];
	pixelSpacingY = s;
	if( pixelSpacingX) pixelRatio = pixelSpacingY / pixelSpacingX;
}

- (double)originX { [self CheckLoad]; return originX;}
- (double)originY { [self CheckLoad]; return originY;}
- (double)originZ { [self CheckLoad]; return originZ;}

- (void)origin: (float*)o
{
	[self CheckLoad];
	o[ 0] = originX;
	o[ 1] = originY;
	o[ 2] = originZ;
}
- (void)originDouble: (double*)o
{
	[self CheckLoad];
	o[ 0] = originX;
	o[ 1] = originY;
	o[ 2] = originZ;
}
- (void)setOrigin: (float*)o
{
	originX = o[ 0];
	originY = o[ 1];
	originZ = o[ 2];
}
- (void)setOriginDouble: (double*)o
{
	originX = o[ 0];
	originY = o[ 1];
	originZ = o[ 2];
};
- (double)sliceLocation{ [self CheckLoad]; return sliceLocation;}
- (void)setSliceLocation: (double)l { [self CheckLoad]; sliceLocation = l;}
- (double)sliceThickness { [self CheckLoad]; return sliceThickness;}
- (void)setSliceThickness: (double)l
{
	[self CheckLoad];
	sliceThickness = l;
}
- (double) spacingBetweenSlices { [self CheckLoad]; return spacingBetweenSlices;}

- (double)sliceInterval { [self CheckLoad]; return sliceInterval; }
- (void)setSliceInterval: (double)s { [self CheckLoad]; sliceInterval = s; }

- (float)slope { [self CheckLoad]; return slope; }
- (float)offset { [self CheckLoad]; return offset; }

// WW & WL
- (float)ww { [self CheckLoad]; return ww; }
- (float)wl { [self CheckLoad]; return wl; }

- (float)fullww
{
	if( fullww == 0 && fullwl == 0) [self computePixMinPixMax];
	return fullww;
}

- (float)fullwl
{
	if( fullww == 0 && fullwl == 0) [self computePixMinPixMax];
	return fullwl;
}

- (float)savedWL { [self CheckLoad]; return savedWL; }
- (float)savedWW { [self CheckLoad]; return savedWW; }
- (void)setSavedWL: (float)l { [self CheckLoad]; savedWL = l; }
- (void)setSavedWW: (float)w { [self CheckLoad]; savedWW = w; }


-(float) cineRate {[self CheckLoad]; return cineRate;}


-(id) myinitEmpty
{
	if( cachedPapyGroups == nil)
		cachedPapyGroups = [[NSMutableDictionary dictionary] retain];
		
	if( cachedDCMFrameworkFiles == nil)
		cachedDCMFrameworkFiles = [[NSMutableDictionary dictionary] retain];
	
	checking = [[NSLock alloc] init];
	decayFactor = 1.0;
	
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
	srcFile = nil;
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

- (void) initParameters
{
	[DCMPix checkUserDefaults: NO];
	
	if( cachedPapyGroups == nil)
		cachedPapyGroups = [[NSMutableDictionary dictionary] retain];
	
	if( cachedDCMFrameworkFiles == nil)
		cachedDCMFrameworkFiles = [[NSMutableDictionary dictionary] retain];
	
	needToCompute8bitRepresentation = YES;
	
	//---------------------------------various
	pixelRatio = 1.0;
	checking = [[NSLock alloc] init];
	stack = 2;
	decayFactor = 1.0;
	slope = 1.0;
	//----------------------------------angio
	subtractedfPercent = 1.0;
	subtractedfZ = 0.8;
	subtractedfZero = 0.8;
	subtractedfGamma = 2.0;
	
	maskID = 1;
	
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
	
	annotationsDictionary = [[NSMutableDictionary dictionary] retain];
}

- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ :(BOOL) volSize
{
	//if( pixelSize != 32) NSLog( @"Only floating images are supported...");
	if( self = [super init])
    {
		[self initParameters];
		
		needToCompute8bitRepresentation = YES;
		generated = YES;
		imTot = 1;
		
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
			fExternalOwnedImage = im;
			fImage = im;
			
			if( im == nil)
				NSLog( @"DCMPix initwithdata ERROR im == nil");
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
					
					if( im)
					{
						if( xDim != width)
						{
							//	NSLog(@"Allocate a new fImage");
							for( i =0; i < height; i++)
							{
								memcpy( fImage + i*width, im + i*xDim, width*sizeof(float));
							}
						}
						else memcpy( fImage, im, width*height*sizeof(float));
					}
					break;
					
					case 8:		// RGBA -> argb
					//rowBytes = width * 4;
					fImage = malloc(width*height*4);
					
					if( im)
					{
						unsigned char *src = (unsigned char*) im, *dst = (unsigned char*) fImage;
						
						for( i =0; i < height*width*4; i+= 4)
						{
							dst[ i] = src[ i+3];
							dst[ i+1] = src[ i];
							dst[ i+2] = src[ i+1];
							dst[ i+3] = src[ i+2];
						}
					}
					
					isRGB = YES;
					break;
			}
		}
		
		originX = oX;
		originY = oY;
		originZ = oZ;
		
		isOriginDefined = YES;
		
		ww = 0;
		wl = 0;
		
		sliceLocation = 0;
		sliceThickness = 0;
		
		memset( orientation, 0, sizeof orientation);
		
		[self loadCustomImageAnnotationsPapyLink:-1 DCMLink:nil];
    }
    return self;
}

- (id) initwithdata :(float*) im :(short) pixelSize :(long) xDim :(long) yDim :(float) xSpace :(float) ySpace :(float) oX :(float) oY :(float) oZ
{
	return [self initwithdata: im :pixelSize :xDim :yDim :xSpace :ySpace :oX :oY :oZ :NO];
}

- (id) initWithImageObj: (NSManagedObject *)entity{
	return  [self myinit:[entity valueForKey:@"completePath"] :0 :1 :nil :0 :0 isBonjour:NO imageObj: entity];
}

 - (id)initWithContentsOfFile: (NSString *)file
{
	return  [self myinit:file :0 :1 :nil :0 :0 isBonjour:NO imageObj: nil];
}

- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss isBonjour:(BOOL) hello imageObj: (NSManagedObject*) iO
{	
	// doesn't load pix data, only initializes instance variables
	if( hello == NO && s != nil)
		if( [[NSFileManager defaultManager] fileExistsAtPath:s] == NO) return nil;
	
    if( self = [super init])
    {
		//-------------------------received parameters
		srcFile = [s retain];
		imageObj = [iO retain];
		
		imID = pos;
		imTot = tot;
		fExternalOwnedImage = ptr;
		frameNo = f;
		serieNo = ss;
		isBonjour = hello;
		
		[self initParameters];
    }
    return self;
}

- (id) myinit:(NSString*) s :(long) pos :(long) tot :(float*) ptr :(long) f :(long) ss
{
	return [self myinit: s :pos :tot :ptr :f :ss isBonjour:NO imageObj: nil];
}

//- (void) copyFromOther:(DCMPix *) fromDcm
//{
//	[self->imageObj release];
//	[self->annotationsDictionary release];
//
//	self->imageObj = [fromDcm->imageObj retain];
//	self->isBonjour = fromDcm->isBonjour;
//	//	self->fImage = fromDcm->fImage;	// Don't load the image!
//	self->height = fromDcm->height;
//	self->width = fromDcm->width;
//	self->wl = fromDcm->wl;
//	self->ww = fromDcm->ww;
//	self->sliceInterval = fromDcm->sliceInterval;
//	self->pixelSpacingX = fromDcm->pixelSpacingX;
//	self->pixelSpacingY = fromDcm->pixelSpacingY;
//	self->sliceLocation = fromDcm->sliceLocation;
//	self->spacingBetweenSlices = fromDcm->spacingBetweenSlices;
//	self->sliceThickness = fromDcm->sliceThickness;
//	self->pixelRatio = fromDcm->pixelRatio;
//	self->originX  = fromDcm->originX;
//	self->originY = fromDcm->originY;
//	self->originZ = fromDcm->originZ;
//	
//	memcpy( self->orientation, fromDcm->orientation, sizeof orientation );
//	
//	self->isRGB = fromDcm->isRGB;
//	self->cineRate = fromDcm->cineRate;
//	self->savedWL = fromDcm->savedWL;
//	self->savedWW = fromDcm->savedWW;
//	
//	self->echotime = [fromDcm->echotime retain];
//	self->flipAngle = [fromDcm->flipAngle retain];
//	self->laterality = [fromDcm->laterality retain];
//	self->repetitiontime = [fromDcm->repetitiontime retain];
//	self->protocolName = [fromDcm->protocolName retain];
//	self->convertedDICOM = [fromDcm->convertedDICOM retain];
//	self->viewPosition = [fromDcm->viewPosition retain];
//	self->patientPosition = [fromDcm->patientPosition retain];
//
//	self->patientsWeight = fromDcm->patientsWeight;
//	self->SUVConverted = fromDcm->SUVConverted;
//
//	self->units = [fromDcm->units retain];
//	self->decayCorrection = [fromDcm->decayCorrection retain];
//	self->radionuclideTotalDose = fromDcm->radionuclideTotalDose;
//	self->radionuclideTotalDoseCorrected = fromDcm->radionuclideTotalDoseCorrected;
//	self->acquisitionTime = [fromDcm->acquisitionTime retain];
//	self->radiopharmaceuticalStartTime = [fromDcm->radiopharmaceuticalStartTime retain];
//	self->displaySUVValue = fromDcm->displaySUVValue;
//	self->decayFactor = fromDcm->decayFactor;
//	self->halflife = fromDcm->halflife;
//	self->philipsFactor = fromDcm->philipsFactor;
//	self->generated = YES;
//	
//	self->minValueOfSeries = fromDcm->minValueOfSeries;
//	self->maxValueOfSeries = fromDcm->maxValueOfSeries;
//	self->annotationsDictionary = [fromDcm->annotationsDictionary retain];
//}

- (id) copyWithZone:(NSZone *)zone
{
	DCMPix *copy = [[[self class] allocWithZone: zone] myinit:self->srcFile :self->imID :self->imTot :self->fExternalOwnedImage :self->frameNo :self->serieNo];
	
	if( copy == nil)
	{
		copy = [[[self class] allocWithZone: zone] init];
		{
			//-------------------------received parameters
			copy->srcFile = [self->srcFile retain];
			copy->imageObj = [self->imageObj retain];
			copy->imID = self->imID;
			copy->imTot = self->imTot;
			copy->fExternalOwnedImage = self->fExternalOwnedImage;
			copy->frameNo = self->frameNo;
			copy->serieNo = self->serieNo;
			copy->isBonjour = self->isBonjour;
			
			[self initParameters];
		}
	}
	
	if( copy == nil) return nil;
	
	[copy->imageObj release];
	[copy->annotationsDictionary release];
	
	copy->imageObj = [self->imageObj retain];
	copy->isBonjour = self->isBonjour;
	copy->fImage = self->fImage;	// Don't load the image!
	copy->height = self->height;
	copy->width = self->width;
//	copy->rowBytes = self->rowBytes;
	copy->wl = self->wl;
	copy->ww = self->ww;
	copy->sliceInterval = self->sliceInterval;
	copy->spacingBetweenSlices = self->spacingBetweenSlices;
	copy->pixelSpacingX = self->pixelSpacingX;
	copy->pixelSpacingY = self->pixelSpacingY;
	copy->sliceLocation = self->sliceLocation;
	copy->sliceThickness = self->sliceThickness;
	copy->pixelRatio = self->pixelRatio;
	copy->originX  = self->originX;
	copy->originY = self->originY;
	copy->originZ = self->originZ;
	
	memcpy( copy->orientation, self->orientation, sizeof orientation );
	
	copy->frameOfReferenceUID = [self->frameOfReferenceUID retain];
	
	copy->isRGB = self->isRGB;
	copy->cineRate = self->cineRate;
	copy->savedWL = self->savedWL;
	copy->savedWW = self->savedWW;
	
	copy->echotime = [self->echotime retain];
	copy->flipAngle = [self->flipAngle retain];
	copy->laterality = [self->laterality retain];
	copy->repetitiontime = [self->repetitiontime retain];
	copy->protocolName = [self->protocolName retain];
	copy->viewPosition = [self->viewPosition retain];
	copy->patientPosition = [self->patientPosition retain];
	copy->annotationsDictionary = [self->annotationsDictionary retain];
	
	copy->patientsWeight = self->patientsWeight;
	copy->SUVConverted = self->SUVConverted;
	
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

	copy->shutterRect_w = self->shutterRect_w;
	copy->shutterRect_h = self->shutterRect_h;
	copy->shutterRect_x = self->shutterRect_x;
	copy->shutterRect_y = self->shutterRect_y;
	copy->DCMPixShutterOnOff = self->DCMPixShutterOnOff;
	
	copy->generated = YES;
	
	copy->maxValueOfSeries = self->maxValueOfSeries;
	copy->minValueOfSeries = self->minValueOfSeries;
	copy->isOriginDefined = self->isOriginDefined;
	
    return copy;
}

#include "BioradHeader.h"

-(void) LoadBioradPic
{
	FILE		*fp = fopen( [srcFile UTF8String], "r");
	long		i, realheight;
	
	//NSLog(@"Handling Biorad PIC File in CheckLoad");
	if( fp)
	{
		long					totSize, maxImage;
		struct BioradHeader 	header;
		
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
		short *oImage = malloc( totSize);
		
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
			short			*ptr;
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
		
		NSRange charRange = {32,127-32+1};
		NSCharacterSet *goodSet = [NSCharacterSet characterSetWithRange:charRange];
		NSScanner *noteCleaner;
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
					if([listItems count]>=5)
					{
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
					if([aLine rangeOfString:@"Z_CORRECT_FACTOR"].location!=NSNotFound)
					{
						NSArray *listItems = [aLine componentsSeparatedByString:@" "];
						NSString	*subStringVal;
						if ( listItems.count >= 3 )
						{
							subStringVal=[listItems objectAtIndex:2];
							zCorrection=[subStringVal floatValue];
							NSLog(@"Set zCorrection factor = %f",zCorrection);
						}
						else
						{
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
		
		if( fExternalOwnedImage)
		{
			fImage = fExternalOwnedImage;
		}
		else
		{
			fImage = malloc(width*height*sizeof(float) + 100);
		}
		
		dstf.data = fImage;
		
		vImageConvert_16SToF( &src16, &dstf, 0, 1, 0);
		
		free(oImage);
		oImage = nil;
		
		fclose( fp);
		
		savedWL = wl = 127;
		savedWW = ww = 256;
	}
}

-(void) LoadTiff:(long) directory
{
#ifndef STATIC_DICOM_LIB
	
	long			i, totSize;
	int				w, h, row;
	short			bpp, count, tifspp;
	short			dataType = 0;
	short			planarConfig = 0;
	
	isRGB = NO;
	
	TIFF* tif = TIFFOpen([srcFile UTF8String], "r");
	if( tif )
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
		TIFFGetField(tif, TIFFTAG_PLANARCONFIG, &planarConfig);
		
		NSLog( @"Bits Per Sample: %d, Samples Per Pixel: %d PlanarConfig: %d", bpp, tifspp, planarConfig);
		
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
		
		short *oImage = malloc( totSize);
		
		if( bpp == 16)
		{
			if( tifspp == 3)	// RGB
			{
				if( planarConfig == PLANARCONFIG_SEPARATE)
				{
					unsigned char  *dst = (unsigned char*) oImage;
					
					TIFFReadRGBAImage(tif, w, h, (uint32 *) dst, 0);
					
					for( i =0; i < height*width*4; i+= 4)
					{
						dst[ i+3] = dst[ i+2];
						dst[ i+2] = dst[ i+1];
						dst[ i+1] = dst[ i];
						
						dst[ i] = 0;
					}
				}
				else
				{
					unsigned short *buf = _TIFFmalloc(TIFFScanlineSize(tif));
					unsigned char  *dst, *aImage = (unsigned char*) oImage;
					long scanline = TIFFScanlineSize(tif);
					
					BOOL trueRGB = NO;
					
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
							
							if( buf[ i*3 + 0] == buf[ i*3 + 1] && buf[ i*3 + 0] == buf[ i*3 + 2])
							{
							}
							else trueRGB = YES;
						}
					}
					
					_TIFFfree(buf);
					
					if( trueRGB == NO)	// Convert it to BW
					{
						isRGB = NO;
						
						unsigned char  *dst = (unsigned char*) oImage;
						
						for( i =0; i < height*width*4; i+= 4)
						{
							oImage[ i/4] = dst[ i+1];
						}
					}
				}
				
				//check for true rgb
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
				if( planarConfig == PLANARCONFIG_SEPARATE)
				{
					unsigned char  *dst = (unsigned char*) oImage;
					
					TIFFReadRGBAImage(tif, w, h, (uint32 *) dst, 0);
					
					BOOL trueRGB = NO;
					
					for( i =0; i < height*width*4; i+= 4)
					{
						dst[ i+3] = dst[ i+2];
						dst[ i+2] = dst[ i+1];
						dst[ i+1] = dst[ i];
						
						if( dst[ i+1] == dst[ i+2] && dst[ i+2] == dst[ i+3])
						{
						}
						else trueRGB = YES;
						
						dst[ i] = 0;
					}
					
					if( trueRGB == NO)	// Convert it to BW
					{
						isRGB = NO;
						
						unsigned char  *dst = (unsigned char*) oImage;
						
						for( i =0; i < height*width*4; i+= 4)
						{
							oImage[ i/4] = dst[ i+1];
						}
					}
				}
				else
				{
					unsigned char *buf = _TIFFmalloc( TIFFScanlineSize(tif));
					unsigned char  *dst, *aImage = (unsigned char*) oImage;
					long scanline = TIFFScanlineSize(tif);
					
					BOOL trueRGB = NO;
					
					for (row = 0; row < h; row++)
					{
						TIFFReadScanline(tif, buf, row, 0);
						
						dst = aImage + (row*(scanline/3) * 4);
						for( i = 0; i < scanline/3; i++)
						{
							dst[ i*4 + 0] = 0;
							dst[ i*4 + 1] = buf[ i*3 + 0];
							dst[ i*4 + 2] = buf[ i*3 + 1];
							dst[ i*4 + 3] = buf[ i*3 + 2];
							
							if( buf[ i*3 + 0] == buf[ i*3 + 1] && buf[ i*3 + 0] == buf[ i*3 + 2])
							{
							}
							else trueRGB = YES;
						}
					}
					
					if( trueRGB == NO)	// Convert it to BW
					{
						isRGB = NO;
						
						unsigned char  *dst = (unsigned char*) oImage;
						
						for( i =0; i < height*width*4; i+= 4)
						{
							oImage[ i/4] = dst[ i+1];
						}
					}
					
					_TIFFfree(buf);
				}
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
			
			if( fExternalOwnedImage)
			{
				fImage = fExternalOwnedImage;
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
			if( fExternalOwnedImage)
			{
				fImage = fExternalOwnedImage;
			}
			else
			{
				fImage = malloc(width*height*sizeof(float) + 100);
			}
			
			memcpy( fImage, oImage, width*height*4);
			
//			rowBytes = width * 4;
		}
		
		free(oImage);
		oImage = nil;
		
		TIFFClose(tif);
	}
	else NSLog( @"ERROR TIFF UNKNOWN");
	
#endif
}

-(void) LoadFVTiff
{
#ifndef STATIC_DICOM_LIB
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
				
				isOriginDefined = YES;
			}
			else if (*(mm_head.DimInfo[i].Name) == 'Y')
			{
				originY = mm_head.DimInfo[i].Origin / 1000.0;
				pixelSpacingY = mm_head.DimInfo[i].Resolution / 1000.0;
				
				isOriginDefined = YES;
			}
			else if (*(mm_head.DimInfo[i].Name) == 'Z')
			{
				originZ = (mm_head.DimInfo[i].Origin + (mm_head.DimInfo[i].Resolution * frameNo)) / 1000.0;
				sliceThickness = sliceInterval = mm_head.DimInfo[i].Resolution / 1000.0;
				
				isOriginDefined = YES;
			}
		}
		sliceLocation = originZ;
		if( pixelSpacingY != 0.0 && pixelSpacingX != 0.0)
			pixelRatio = pixelSpacingY / pixelSpacingX;
	}
	if(tif) TIFFClose(tif);
#endif
}


-(void) LoadLSM
{
	// This function has been modified twice by Greg Jefferis on 9 June 2004
	// early am and late pm respectively.  After the second iteration it has been 
	// tested on new and old style 16 and 8 bit LSM tiff files.  Comments?
	FILE *fp = fopen( [srcFile UTF8String], "r");
	int	i,it = 0;
	int	nextoff = 0;
	int counter = 0;
	int	pos = 8, k;
	short shortval;
	int lsmDebug=0;  // Flag to determine if debugging messages are printed
	
	int	realheight;
	
	int	TIF_NEWSUBFILETYPE = 0; // GJ: flag indicating whether image is "real" or thumbnail 
	int	LENGTH2, TIF_STRIPOFFSETS; // GJ: Number of channels & offset containing file offset to image data
	int	TIF_CZ_LSMINFO, TIF_COMPRESSION = 0; // GJ: Offset of additional data about image
	/* No longer required as of 040609 pm with simplified reader
	 int	LENGTH1, TIF_BITSPERSAMPLE_CHANNEL1, TIF_BITSPERSAMPLE_CHANNEL2, TIF_BITSPERSAMPLE_CHANNEL3;
	 int	TIF_COMPRESSION, TIF_PHOTOMETRICINTERPRETATION, TIF_STRIPOFFSETS, TIF_SAMPLESPERPIXEL, TIF_STRIPBYTECOUNTS;
	 int	TIF_STRIPOFFSETS1, TIF_STRIPOFFSETS2, TIF_STRIPOFFSETS3;
	 int	TIF_STRIPBYTECOUNTS1, TIF_STRIPBYTECOUNTS2, TIF_STRIPBYTECOUNTS3;
	 int	TIF_STRIPOFFSETS_ARRAY[3];
	 */
	// GJ: this will store the location of the data for this frame
	int	imageDataOffsetForThisFrame;
	int	goodFramesChecked=0;
	
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
			int LENGTH = 0;
			int MASK = 0x00ff;
			int MASK2 = 0x000000ff;
			
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
		//			int	DIMENSION_X, DIMENSION_Y, DIMENSION_Z, NUMBER_OF_CHANNELS, TIMESTACKSIZE, DATATYPE, DATATYPE2;
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
		if(TIF_NEWSUBFILETYPE==0)
		{
			// This directory entry was a main image
			// Is it also the entry for the image we are looking for?
			if(goodFramesChecked++ == frameNo)
			{
				// yes, so record the imageDataOffsetForThisFrame
				if(LENGTH2==1)
				{
					// for a single channel image it is just TIF_STRIPOFFSETS
					imageDataOffsetForThisFrame = TIF_STRIPOFFSETS;
				}
				else
				{
					// if this is a multi channel image, check that serieNo has a sensible value
					if(LENGTH2>1 && serieNo>=LENGTH2)
					{ 
						NSLog(@"LoadLSM: zero indexed serieNo (%d) is greater than number of channels (%d)",serieNo,LENGTH2);
						return;
					}
					// ok serieNo is sensible use the TIF_STRIPOFFSETS to move to the right place
					fseek(fp, TIF_STRIPOFFSETS, SEEK_SET);
					for (i=0; i<=serieNo;i++)
					{
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
	
	int iterator1;
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
			int LENGTH = 0;
			int MASK = 0x00ff;
			int MASK2 = 0x000000ff;
			
			
			TAGTYPE = ((TAG1[1] & MASK) << 8) | ((TAG1[0] & MASK ) <<0);
			LENGTH = ((TAG1[7] & MASK2) << 24) | ((TAG1[6] & MASK2) << 16) | ((TAG1[5] & MASK2) << 8) | (TAG1[4] & MASK2);
			
			//NSLog(@"Analysing tag %d of type %d and length %d",k,TAGTYPE,LENGTH);  //GJ: for reporting
			
			switch (TAGTYPE)
			{
				case 254:
					TIF_NEWSUBFILETYPE = ((TAG1[11] & MASK2) << 24) | ((TAG1[10] & MASK2) << 16) | ((TAG1[9] & MASK2) << 8) | (TAG1[8] & MASK2);
					// GJ: this is condition which cannot be handled by the present version of LoadLSM
					if(TIF_NEWSUBFILETYPE!=0)
					{
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
		
		int	DIMENSION_X, DIMENSION_Y, DIMENSION_Z, NUMBER_OF_CHANNELS, TIMESTACKSIZE, DATATYPE;
		short   SCANTYPE;
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
		
		if( fExternalOwnedImage) fImage = fExternalOwnedImage;
		else fImage = malloc(width*height*sizeof(float) + 100);
		
		int numPixels = height * width;
		
		// GJ: Move to correct location for image data
		fseek(fp, imageDataOffsetForThisFrame, SEEK_SET);
		// Then read data according to datatype
		
		short *oImage = nil;
		
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
				
				if( TIF_COMPRESSION)
				{
					[self LoadTiff: counter];
					
					// RGBA -> separate according to SerieNo
					
					if( isRGB && serieNo < 3)
					{
						isRGB = NO;
						unsigned char  *dst = (unsigned char*) fImage;
						
						i = numPixels;
						while( i-- > 0)
						{
							oImage[ i] = dst[ i*4+ 1 + serieNo];
						}
					}
				}
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
				oImage = nil;
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
		oImage = nil;
		
		NSSwappedDouble tt;
		
		fseek(fp, TIF_CZ_LSMINFO + 40, SEEK_SET);
		fread( &tt, 8, 1, fp);
		VOXELSIZE_X = NSSwapLittleDoubleToHost( tt);
		pixelSpacingX = VOXELSIZE_X*1000;
		
		fseek(fp, TIF_CZ_LSMINFO + 48, SEEK_SET);
		fread( &tt, 8, 1, fp);
		VOXELSIZE_Y = NSSwapLittleDoubleToHost( tt);
		pixelSpacingY = VOXELSIZE_Y*1000;
		
		fseek(fp, TIF_CZ_LSMINFO + 56, SEEK_SET);
		fread( &tt, 8, 1, fp);
		VOXELSIZE_Z = NSSwapLittleDoubleToHost( tt);
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
	else NSLog(@"ERROR IN computeTotalDoseCorrected : halflife: %f timebetween: %f", halflife, timebetween);
}

- (void)createROIsFromRTSTRUCT: (DCMObject*)dcmObject
{
	
#ifdef OSIRIX_VIEWER
	
	if( [[BrowserController currentBrowser] isCurrentDatabaseBonjour])
	{
		NSLog( @"Can't (or shouldn't?) export ROIs to Bonjour mounted Database" );
		return;
	}
	
	NSLog( @"createROIsFromRTSTRUCT" );
	
	NSDictionary *dict = [NSDictionary dictionaryWithObject: dcmObject forKey: @"dcmObject"];
	
	[NSThread detachNewThreadSelector: @selector(createROIsFromRTSTRUCTThread:) toTarget: self withObject: dict];
	
	NSDictionary *noteDict = [NSDictionary dictionaryWithObjectsAndKeys: 
							  [NSNumber numberWithBool: YES], @"RTSTRUCTProgressBar",
							  [NSNumber numberWithFloat: 0.0f], @"RTSTRUCTProgressPercent",
							  nil];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"RTSTRUCTNotification" object:nil userInfo: noteDict];
	
#endif
}

- (void)createROIsFromRTSTRUCTThread: (NSDictionary*)dict
{
	
#ifdef OSIRIX_VIEWER
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  // Cuz this is run as a detached thread.
	
	DCMObject *dcmObject = [dict objectForKey: @"dcmObject"];
	
	// Get all referenced images up front.
	// This is better than running a Fetch Request for EVERY ROI since
	// executeFetchRequest is expensive.
	
	DCMSequenceAttribute *refFrameSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"ReferencedFrameofReferenceSequence"];
	
	if ( refFrameSequence == nil )
	{
		NSLog( @"ReferencedFrameofReferenceSequence not found" );
		goto END_CREATE_ROIS;
	}
	
	NSMutableArray *refSeriesUIDPredicates = [NSMutableArray arrayWithCapacity: 0];
	
	NSDictionary *noteDict = [NSDictionary dictionaryWithObjectsAndKeys: 
							  [NSNumber numberWithBool: YES], @"RTSTRUCTProgressBar",
							  [NSNumber numberWithFloat: 1.0f], @"RTSTRUCTProgressPercent",
							  nil];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"RTSTRUCTNotification" object:nil userInfo: noteDict];
	
	
	for ( DCMObject *refFrameSeqItem in [refFrameSequence sequence] )
	{
		DCMSequenceAttribute *refStudySeq = (DCMSequenceAttribute *)[refFrameSeqItem attributeWithName: @"RTReferencedStudySequence"];
		
		for ( DCMObject *refStudySeqItem in refStudySeq.sequence )
		{
			DCMSequenceAttribute *refSeriesSeq = (DCMSequenceAttribute *)[refStudySeqItem attributeWithName: @"RTReferencedSeriesSequence"];
			
			for ( DCMObject *refSeriesSeqItem in refSeriesSeq.sequence )
			{
				
				NSString *refSeriesUID = [refSeriesSeqItem attributeValueWithName: @"SeriesInstanceUID"];
				NSPredicate *pred = [NSPredicate predicateWithFormat: @"series.seriesDICOMUID == %@", refSeriesUID];
				[refSeriesUIDPredicates addObject: pred];
				
				/*
				 DCMSequenceAttribute *contourImgSeq = (DCMSequenceAttribute *)[refSeriesSeqItem attributeWithName: @"ContourImageSequence"];
				 NSEnumerator *contourImgSeqEnum = [[contourImgSeq sequence] objectEnumerator];
				 DCMObject *contourImgSeqItem;
				 
				 while ( contourImgSeqItem = [contourImgSeqEnum nextObject] ) {
				 NSString *refImgUID = [contourImgSeqItem attributeValueWithName: @"ReferencedSOPInstanceUID"];
				 NSPredicate *pred = [NSPredicate predicateWithFormat: @"sopInstanceUID like %@", refImgUID];
				 [refImgUIDPredicates addObject: pred];
				 }
				 */
			}
		}
	}
	
	noteDict = [NSDictionary dictionaryWithObjectsAndKeys: 
				[NSNumber numberWithBool: YES], @"RTSTRUCTProgressBar",
				[NSNumber numberWithFloat: 10.0f], @"RTSTRUCTProgressPercent",
				nil];
	
	[nc postNotificationName:@"RTSTRUCTNotification" object:nil userInfo: noteDict];
	
	if ( refSeriesUIDPredicates.count == 0 )
	{
		NSLog( @"No reference series found." );
		goto END_CREATE_ROIS;
	}
	
	NSManagedObjectContext *moc = [[BrowserController currentBrowser] managedObjectContext];
	NSError *error = nil;
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	request.entity = [NSEntityDescription entityForName: @"Image" inManagedObjectContext: moc];	
	request.predicate = [NSCompoundPredicate orPredicateWithSubpredicates: refSeriesUIDPredicates];
	
	[moc lock];
	NSArray *imgObjects = [moc executeFetchRequest: request error: &error];
	[moc unlock];
	
	if ( imgObjects.count == 0 )
	{
		NSLog( @"No images in Series" );
		goto END_CREATE_ROIS;
	}
	
	// Put all images in a dictionary for quick lookup based on SOP Instance UID
	
	NSMutableDictionary *imgDict = [NSMutableDictionary dictionaryWithCapacity: imgObjects.count];
	NSMutableArray *dcmImgObjects = [NSMutableArray arrayWithCapacity: imgObjects.count];
	
	for ( DicomImage *imgObj in imgObjects )
	{
		[imgDict setObject: imgObj forKey: [imgObj valueForKey: @"sopInstanceUID"]];
		[dcmImgObjects addObject: [DCMObject objectWithContentsOfFile: [imgObj completePath] decodingPixelData: NO]];
	}
	
	DCMSequenceAttribute *roiSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"StructureSetROISequence"];
	
	if ( roiSequence == nil )
	{
		NSLog( @"StructureSetROISequence not found" );
		goto END_CREATE_ROIS;
	}
	
	NSMutableDictionary *roiNames = [NSMutableDictionary dictionary];
	
	for ( DCMObject *sequenceItem in [roiSequence sequence] )
	{
		[roiNames setValue: [sequenceItem attributeValueWithName: @"ROIName"]
					forKey: [sequenceItem attributeValueWithName: @"ROINumber"]];
	}
	
	DCMSequenceAttribute *roiContourSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"ROIContourSequence"];
	
	if ( roiContourSequence == nil )
	{
		NSLog( @"ROIContourSequence not found" );
		goto END_CREATE_ROIS;
	}
	
{
	int numStructs = roiContourSequence.sequence.count;
	unsigned int iStruct = 0;
	
	NSMutableArray *roiArray[ imgObjects.count ];  // Array of ROIs for each defined 'image' referenced by the RTSTRUCT
	
	for ( unsigned int i = 0; i < imgObjects.count; i++ ) roiArray[ i ] = [NSMutableArray arrayWithCapacity: 0];
	
	for ( DCMObject *sequenceItem in [roiContourSequence sequence] )
	{
		
		float
		pixSpacingX,
		pixSpacingY;
		
		NSArray *rgbArray = [sequenceItem attributeArrayWithName: @"ROIDisplayColor"];
		
		RGBColor color =
		{
			[[rgbArray objectAtIndex: 0] floatValue] * 65535 / 256.0,
			[[rgbArray objectAtIndex: 1] floatValue] * 65535 / 256.0,
		[[rgbArray objectAtIndex: 2] floatValue] * 65535 / 256.0 };
		
		NSString *roiName = [roiNames valueForKey: [sequenceItem attributeValueWithName: @"ReferencedROINumber"]];
		
		NSLog( @"roiName = %@", roiName );
		DCMSequenceAttribute *contourSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"ContourSequence"];
		if ( roiContourSequence == nil )
		{
			NSLog( @"contourSequence not found" );
			goto END_CREATE_ROIS;
		}
		
		for ( DCMObject *contourItem in [contourSequence sequence] )
		{
			
			//				DCMSequenceAttribute *contourImageSequence = (DCMSequenceAttribute*)[contourItem attributeWithName: @"ContourImageSequence"];
			//				if ( contourImageSequence == nil ) {
			//					NSLog( @"contourImageSequence not found" );
			//					goto END_CREATE_ROIS;
			//				}
			
			NSString *contourType = [contourItem attributeValueWithName: @"ContourGeometricType"];
			
			if ( [contourType isEqualToString: @"CLOSED_PLANAR"] == NO && [contourType isEqualToString: @"INTERPOLATED_PLANAR"] == NO )
			{
				NSLog( @"Contour type %@ is not supported at this time.", contourType );
				continue;
			}
			
			int type = tCPolygon;
			
			NSArray *dcmPoints = [contourItem attributeArrayWithName: @"ContourData"];
			
			// Loop over all slices to determine if slice "contains" the ROI based on distance criterion of FIRST point
			// This of course assumes that ALL the points in the contour are in the same slice.
			// Not considering at this time the possibility that the contour intersects multiple slices.
			
			for ( unsigned int imgIndex = 0; imgIndex < imgObjects.count; imgIndex++ )
			{  
				DicomImage *img = [imgObjects objectAtIndex: imgIndex];
				
				DCMObject *imgObject = [dcmImgObjects objectAtIndex: imgIndex];
				
				if ( imgObject == nil )
				{
					NSLog( @"Error opening referenced image file" );
					goto END_CREATE_ROIS;
				}
				
				NSArray *pixSpacings = [imgObject attributeArrayWithName: @"PixelSpacing"];
				NSArray *position = [imgObject attributeArrayWithName: @"ImagePositionPatient"];
				
				float posX = [[position objectAtIndex: 0] floatValue];
				float posY = [[position objectAtIndex: 1] floatValue];
				float posZ = [[position objectAtIndex: 2] floatValue];
				
				pixSpacingX = [[pixSpacings objectAtIndex: 0] floatValue];
				pixSpacingY = [[pixSpacings objectAtIndex: 1] floatValue];
				
				if ( pixSpacingX == 0.0f || pixSpacingY == 0.0f ) continue;  // Bad slice?
				
				float pixSpacingXrecip = 1.0f / pixSpacingX;
				float pixSpacingYrecip = 1.0f / pixSpacingY;
				
				// Convert ROI points from DICOM space to ROI space
				
				NSArray *imageOrientation = [imgObject attributeArrayWithName: @"ImageOrientationPatient"];
				
				float orients[ 9 ];
				
				for ( unsigned int i = 0; i < 6; i++ )
				{
					orients[ i ] = [[imageOrientation objectAtIndex: i] floatValue];
				}
				
				// Normal vector
				orients[6] = orients[1]*orients[5] - orients[2]*orients[4];
				orients[7] = orients[2]*orients[3] - orients[0]*orients[5];
				orients[8] = orients[0]*orients[4] - orients[1]*orients[3];
				
				float temp[ 3 ];
				
				temp[ 0 ] = [[dcmPoints objectAtIndex: 0] floatValue] - posX;
				temp[ 1 ] = [[dcmPoints objectAtIndex: 1] floatValue] - posY;
				temp[ 2 ] = [[dcmPoints objectAtIndex: 2] floatValue] - posZ;
				
				float distToSlice = fabs( temp[ 0 ] * orients[ 6 ] + temp[ 1 ] * orients[ 7 ] + temp[ 2 ] * orients[ 8 ] );
				float distCriterion = [[imgObject attributeValueWithName: @"SliceThickness"] floatValue] * 0.4;
				if ( distCriterion <= 0.0f ) distCriterion = 0.1f;  // mm
				
				if ( distToSlice < distCriterion )
				{
					float sliceCoords[ 2 ];
					
					sliceCoords[ 0 ] = temp[ 0 ] * orients[ 0 ] + temp[ 1 ] * orients[ 1 ] + temp[ 2 ] * orients[ 2 ];
					sliceCoords[ 1 ] = temp[ 0 ] * orients[ 3 ] + temp[ 1 ] * orients[ 4 ] + temp[ 2 ] * orients[ 5 ];
					sliceCoords[ 0 ] *= pixSpacingXrecip;
					sliceCoords[ 1 ] *= pixSpacingYrecip;
					
					int numPoints = [[contourItem attributeValueWithName: @"NumberofContourPoints"] intValue];
					NSMutableArray *pointsArray = [NSMutableArray arrayWithCapacity: numPoints];
					
					[pointsArray addObject: [MyPoint point:NSMakePoint( sliceCoords[ 0 ], sliceCoords[ 1 ] )]];
					
					// Convert rest of points in contour to sliceCoord space
					
					for ( unsigned int pointIndex = 1; pointIndex < numPoints; pointIndex++ )
					{
						temp[ 0 ] = [[dcmPoints objectAtIndex: 3 * pointIndex] floatValue] - posX;
						temp[ 1 ] = [[dcmPoints objectAtIndex: 3 * pointIndex + 1] floatValue] - posY;
						temp[ 2 ] = [[dcmPoints objectAtIndex: 3 * pointIndex + 2] floatValue] - posZ;
						
						sliceCoords[ 0 ] = temp[ 0 ] * orients[ 0 ] + temp[ 1 ] * orients[ 1 ] + temp[ 2 ] * orients[ 2 ];
						sliceCoords[ 1 ] = temp[ 0 ] * orients[ 3 ] + temp[ 1 ] * orients[ 4 ] + temp[ 2 ] * orients[ 5 ];
						sliceCoords[ 0 ] *= pixSpacingXrecip;
						sliceCoords[ 1 ] *= pixSpacingYrecip;
						[pointsArray addObject: [MyPoint point:NSMakePoint( sliceCoords[ 0 ], sliceCoords[ 1 ] )]];
					}
					
					ROI *roi = [[[ROI alloc] initWithType: type
														 : pixSpacingX
														 : pixSpacingY
														 : NSMakePoint( posX, posY )] autorelease];
					
					roi.name = roiName;
					roi.rgbcolor = color;
					roi.points = pointsArray;
					
					[roiArray[ [imgObjects indexOfObject: img] ] addObject: roi];
					
				}
				
			} // End loop over images in series (looking for containing slices)
			
		} // Loop over ContourSequence
		
		iStruct++;
		
		float percentComplete = ( iStruct / (float)numStructs ) * 90.0f + 10.0f;
		
		noteDict = [NSDictionary dictionaryWithObjectsAndKeys: 
					[NSNumber numberWithBool: YES], @"RTSTRUCTProgressBar",
					[NSNumber numberWithFloat: percentComplete], @"RTSTRUCTProgressPercent",
					nil];
		
		[nc postNotificationName:@"RTSTRUCTNotification" object:nil userInfo: noteDict];
		
	}  // Loop over ROIContourSequence
	
	// Write ROIs to disk and update DB
	
	NSMutableArray	*newDICOMSR = [NSMutableArray array];
	
	for ( unsigned int i = 0; i < imgObjects.count; i++ )
	{
		
		if ( roiArray[ i ].count == 0 ) continue;  // Nothing to see, move on.
		
		DicomImage *img = [imgObjects objectAtIndex: i];
		
		NSString *str = [img SRPathForFrame: 0];  // Assume only one frame for now.   Worry about multi-frame later (if that is even defined in RTSTRUCT).
		
		// Get any pre-existing ROIs and add them to the roiArray
		
		NSData *data = [ROISRConverter roiFromDICOM: str];
		
		if ( data )
		{
			NSMutableArray *array = [NSUnarchiver unarchiveObjectWithData: data];
			if ( array ) [roiArray[ i ] addObjectsFromArray: array];
		}
		
		// Write out the concatenated roiArray
		
		NSString *path = [ROISRConverter archiveROIsAsDICOM: roiArray[ i ] toPath: str forImage: img];
		
		if ( path ) [newDICOMSR addObject: path];
		
	}
	
	if( newDICOMSR.count ) [[BrowserController currentBrowser] addFilesToDatabase: newDICOMSR];
	
	[[BrowserController currentBrowser] saveDatabase: nil];
	
}
	
END_CREATE_ROIS:
	
	noteDict = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO] forKey: @"RTSTRUCTProgressBar"];
	[nc postNotificationName:@"RTSTRUCTNotification" object:nil userInfo: noteDict];
	
	[pool release];
#endif
} // end createROIsFromRTSTRUCT

- (void) setVOILUT:(int) first number :(unsigned int) number depth :(unsigned int) depth table :(unsigned int *)table image:(unsigned short*) src isSigned:(BOOL) isSigned
{
	long			i;
	int				index;
	
	if( isSigned)
	{
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

- (void) reloadAnnotations
{
	#ifdef OSIRIX_VIEWER
	[PapyrusLock lock];
	
	[annotationsDictionary release];
	annotationsDictionary = [[NSMutableDictionary dictionary] retain];
	
	@try
	{
		if( gUSEPAPYRUSDCMPIX)
		{
			[self clearCachedPapyGroups];
			
			PapyShort fileNb = -1;
			
			[self getPapyGroup: 0];
			
			if( [[cachedPapyGroups valueForKey: srcFile] valueForKey: @"fileNb"])
				fileNb = [[[cachedPapyGroups valueForKey: srcFile] valueForKey: @"fileNb"] intValue];
			
			if (fileNb >= 0)
			{
				if (gIsPapyFile [fileNb] == DICOM10) Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
				
				[self loadCustomImageAnnotationsPapyLink:fileNb DCMLink:nil];
			}
		}
		else
		{
			[self clearCachedDCMFrameworkFiles];
			
			DCMObject *dcmObject = 0L;
			
			if( [cachedDCMFrameworkFiles objectForKey: srcFile])
			{
				NSMutableDictionary *dic = [cachedDCMFrameworkFiles objectForKey: srcFile];
				
				dcmObject = [dic objectForKey: @"dcmObject"];
				[dic setValue: [NSNumber numberWithInt: [[dic objectForKey: @"count"] intValue]+1] forKey: @"count"];
			}
			else
			{
				dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
				
				if( dcmObject)
				{
					NSMutableDictionary *dic = [NSMutableDictionary dictionary];
				
					[dic setValue: dcmObject forKey: @"dcmObject"];
					[dic setValue: [NSNumber numberWithInt: 1] forKey: @"count"];
					
					[cachedDCMFrameworkFiles setObject: dic forKey: srcFile];
				}
			}
			
			[self loadCustomImageAnnotationsPapyLink:-1 DCMLink:dcmObject];
		}
	}
	@catch (NSException * e)
	{
		NSLog(@"reloadAnnotations: %@", e);
	}
	
	[PapyrusLock unlock];
	#endif
}

- (void) dcmFrameworkLoad0x0018: (DCMObject*) dcmObject
{
	if( [dcmObject attributeValueWithName:@"FrameofReferenceUID"])
	{
		[frameOfReferenceUID release];
		frameOfReferenceUID = [[dcmObject attributeValueWithName:@"FrameofReferenceUID"] retain];
	}
	if( [dcmObject attributeValueWithName:@"PatientsWeight"]) patientsWeight = [[dcmObject attributeValueWithName:@"PatientsWeight"] floatValue];
	
	if( [dcmObject attributeValueWithName:@"SliceThickness"]) sliceThickness = [[dcmObject attributeValueWithName:@"SliceThickness"] floatValue];
	if( [dcmObject attributeValueWithName:@"SpacingBetweenSlices"]) spacingBetweenSlices = [[dcmObject attributeValueWithName:@"SpacingBetweenSlices"] floatValue];
	if( [dcmObject attributeValueWithName:@"RepetitionTime"])
	{
		[repetitiontime release];
		repetitiontime = [[dcmObject attributeValueWithName:@"RepetitionTime"] retain];
	}
	if( [dcmObject attributeValueWithName:@"EchoTime"])	
	{
		[echotime release];
		echotime = [[dcmObject attributeValueWithName:@"EchoTime"] retain];	
	}
	if( [dcmObject attributeValueWithName:@"FlipAngle"])
	{
		[flipAngle release];
		flipAngle = [[dcmObject attributeValueWithName:@"FlipAngle"] retain];
	}
	if( [dcmObject attributeValueWithName:@"ProtocolName"])
	{
		[protocolName release];
		protocolName = [[dcmObject attributeValueWithName:@"ProtocolName"] retain];
	}
	if( [dcmObject attributeValueWithName:@"ViewPosition"])
	{
		[viewPosition release];
		viewPosition = [[dcmObject attributeValueWithName:@"ViewPosition"] retain];
	}
	if( [dcmObject attributeValueWithName:@"PositionerPrimaryAngle"])
	{
		[positionerPrimaryAngle release];
		positionerPrimaryAngle = [[dcmObject attributeValueWithName:@"PositionerPrimaryAngle"] retain];
	}
	if( [dcmObject attributeValueWithName:@"PositionerSecondaryAngle"])
	{
		[positionerSecondaryAngle release];
		positionerSecondaryAngle = [[dcmObject attributeValueWithName:@"PositionerSecondaryAngle"] retain];
	}
	if( [dcmObject attributeValueWithName:@"PatientPosition"])
	{
		[patientPosition release];
		patientPosition = [[dcmObject attributeValueWithName:@"PatientPosition"] retain];
	}
	if( [dcmObject attributeValueWithName:@"RecommendedDisplayFrameRate"]) cineRate = [[dcmObject attributeValueWithName:@"RecommendedDisplayFrameRate"] floatValue]; 
	if( !cineRate && [dcmObject attributeValueWithName:@"CineRate"]) cineRate = [[dcmObject attributeValueWithName:@"CineRate"] floatValue]; 
	if (!cineRate && [dcmObject attributeValueWithName:@"FrameDelay"])
	{
		if( [[dcmObject attributeValueWithName:@"FrameDelay"] floatValue] > 0)
			cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameDelay"] floatValue];
	}
	if (!cineRate && [dcmObject attributeValueWithName:@"FrameTimeVector"])
	{
		if( [[dcmObject attributeValueWithName:@"FrameTimeVector"] floatValue] > 0)
			cineRate = 1000. / [[dcmObject attributeValueWithName:@"FrameTimeVector"] floatValue];	
	}
	
	if ( gUseShutter)
	{
		if( [dcmObject attributeValueWithName:@"ShutterShape"])
		{
			NSArray *shutterArray = [dcmObject attributeArrayWithName:@"ShutterShape"];
			
			for( NSString *shutter in shutterArray )
			{
				if ( [shutter isEqualToString:@"RECTANGULAR"] )
				{
					DCMPixShutterOnOff = YES;
					
					shutterRect_x = [[dcmObject attributeValueWithName:@"ShutterLeftVerticalEdge"] floatValue]; 
					shutterRect_w = [[dcmObject attributeValueWithName:@"ShutterRightVerticalEdge"] floatValue]  - shutterRect_x;
					shutterRect_y = [[dcmObject attributeValueWithName:@"ShutterUpperHorizontalEdge"] floatValue]; 
					shutterRect_h = [[dcmObject attributeValueWithName:@"ShutterLowerHorizontalEdge"] floatValue]  - shutterRect_y;
				}
				else if( [shutter isEqualToString:@"CIRCULAR"] )
				{
					DCMPixShutterOnOff = YES;
					
					NSArray *centerArray = [dcmObject attributeArrayWithName:@"CenterofCircularShutter"];
					
					if( centerArray.count == 2)
					{
						shutterCircular_x = [[centerArray objectAtIndex:0] intValue];
						shutterCircular_y = [[centerArray objectAtIndex:1] intValue];
					}
					
					shutterCircular_radius = [[dcmObject attributeValueWithName:@"RadiusofCircularShutter"] floatValue];
				}
				else if( [shutter isEqualToString:@"POLYGONAL"] )
				{
					DCMPixShutterOnOff = YES;
					
					NSArray *locArray = [dcmObject attributeArrayWithName:@"VerticesofthePolygonalShutter"];
					
					if( shutterPolygonal) free( shutterPolygonal);
					
					shutterPolygonalSize = 0;
					shutterPolygonal = malloc( [locArray count] * sizeof( NSPoint) / 2);
					for( unsigned int i = 0, x = 0; i < [locArray count]; i+=2, x++ )
					{
						shutterPolygonal[ x].x = [[locArray objectAtIndex: i] intValue];
						shutterPolygonal[ x].y = [[locArray objectAtIndex: i+1] intValue];
						shutterPolygonalSize++;
					}
				}
				else NSLog( @"Shutter not supported: %@", shutter );
			}
		}
	}
}

- (void) dcmFrameworkLoad0x0020: (DCMObject*) dcmObject
{
//orientation
	originX = 0;	originY = 0;	originZ = 0;
	NSArray *ipp = [dcmObject attributeArrayWithName:@"ImagePositionPatient"];
	if( ipp )
	{
		originX = [[ipp objectAtIndex:0] floatValue];
		originY = [[ipp objectAtIndex:1] floatValue];
		originZ = [[ipp objectAtIndex:2] floatValue];
		isOriginDefined = YES;
	}
	
	orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
	orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
	NSArray *iop = [dcmObject attributeArrayWithName:@"ImageOrientationPatient"];
	if( iop )
	{
		for ( int j = 0; j < iop.count; j++ ) 
			orientation[ j ] = [[iop objectAtIndex:j] floatValue];
	}
	
	if( [dcmObject attributeValueWithName:@"ImageLaterality"])
	{
		[laterality release];
		laterality = [[dcmObject attributeValueWithName:@"ImageLaterality"] retain];	
	}
	if( laterality == nil)
	{
		[laterality release];
		laterality = [[dcmObject attributeValueWithName:@"Laterality"] retain];	
	}
}

- (void) dcmFrameworkLoad0x0028: (DCMObject*) dcmObject
{
	// Group 0x0028

	if( [dcmObject attributeValueWithName:@"PixelRepresentation"]) fIsSigned = [[dcmObject attributeValueWithName:@"PixelRepresentation"] intValue];
	if( [dcmObject attributeValueWithName:@"BitsAllocated"]) bitsAllocated = [[dcmObject attributeValueWithName:@"BitsAllocated"] intValue]; 
	
	if( [[dcmObject attributeValueWithName:@"BitsStored"] intValue] == 8 && bitsAllocated == 16 && [[dcmObject attributeValueWithName:@"PhotometricInterpretation"] isEqualToString:@"RGB"])
		bitsAllocated = 8;
	
	if ([dcmObject attributeValueWithName:@"RescaleIntercept"]) offset = [[dcmObject attributeValueWithName:@"RescaleIntercept"] floatValue];
	if ([dcmObject attributeValueWithName:@"RescaleSlope"] ) slope = [[dcmObject attributeValueWithName:@"RescaleSlope"] floatValue]; 
	
	// image size
	if( [dcmObject attributeValueWithName:@"Rows"])
	{
		height = [[dcmObject attributeValueWithName:@"Rows"] intValue];
		height /= 2;
		height *= 2;
	}
	
	if( [dcmObject attributeValueWithName:@"Columns"])
	{
		width =  [[dcmObject attributeValueWithName:@"Columns"] intValue];
		realwidth = width;
		width = realwidth/2;
		width *= 2;
	}
	
	if( shutterRect_w == 0) shutterRect_w = width;
	if( shutterRect_h == 0) shutterRect_h = height;
	
	//window level & width
	if ([dcmObject attributeValueWithName:@"WindowCenter"] && isRGB == NO) savedWL = (int)[[dcmObject attributeValueWithName:@"WindowCenter"] floatValue];
	if ([dcmObject attributeValueWithName:@"WindowWidth"] && isRGB == NO) savedWW =  (int) [[dcmObject attributeValueWithName:@"WindowWidth"] floatValue];
	if(  savedWW < 0) savedWW =-savedWW;
	
	//planar configuration
	if( [dcmObject attributeValueWithName:@"PlanarConfiguration"])
		fPlanarConf = [[dcmObject attributeValueWithName:@"PlanarConfiguration"] intValue]; 
	
	//pixel Spacing
	NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"PixelSpacing"];
	if(pixelSpacing.count >= 2 )
	{
		pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
		pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
	}
	else if(pixelSpacing.count >= 1 )
	{ 
		pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
		pixelSpacingX = [[pixelSpacing objectAtIndex:0] floatValue];
	}
	else
	{
		NSArray *pixelSpacing = [dcmObject attributeArrayWithName:@"ImagerPixelSpacing"];
		if(pixelSpacing.count >= 2 )
		{
			pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
			pixelSpacingX = [[pixelSpacing objectAtIndex:1] floatValue];
		}
		else if(pixelSpacing.count >= 1 )
		{
			pixelSpacingY = [[pixelSpacing objectAtIndex:0] floatValue];
			pixelSpacingX = [[pixelSpacing objectAtIndex:0] floatValue];
		}
	}
	
	DCMSequenceAttribute* seq = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"SequenceofUltrasoundRegions"];
	
	if (seq)
	{
		BOOL spacingFound = NO;
		
		for ( DCMObject *sequenceItem in seq.sequence )
		{
			if( spacingFound == NO)
			{
				int physicalUnitsX = 0;
				int physicalUnitsY = 0;
				
				physicalUnitsX = [[sequenceItem attributeValueWithName:@"PhysicalUnitsXDirection"] intValue];
				physicalUnitsY = [[sequenceItem attributeValueWithName:@"PhysicalUnitsYDirection"] intValue];
				
				if( physicalUnitsX == 3 && physicalUnitsY == 3)	// We want only cm !
				{
					double xxx = 0, yyy = 0;
					
					xxx = [[sequenceItem attributeValueWithName:@"PhysicalDeltaX"] doubleValue];
					yyy = [[sequenceItem attributeValueWithName:@"PhysicalDeltaY"] doubleValue];
					
					if( xxx && yyy)
					{
						pixelSpacingX = fabs( xxx) * 10.;	// These are in cm !
						pixelSpacingY = fabs( yyy) * 10.;
						spacingFound = YES;
					}
				}
			}
		}
	}
	
	//PixelAspectRatio
	NSArray *par = [dcmObject attributeArrayWithName:@"PixelAspectRatio"];
	if ( par.count >= 2 )
	{
		float ratiox = 1, ratioy = 1;
		ratiox = [[par objectAtIndex:0] floatValue];
		ratioy = [[par objectAtIndex:1] floatValue];
		
		if( ratioy != 0 )
		{
			pixelRatio = ratiox / ratioy;
		}
	}
	else if( pixelSpacingX != pixelSpacingY)
	{
		if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
	}
	
	//PhotoInterpret
	if ([[dcmObject attributeValueWithName:@"PhotometricInterpretation"] rangeOfString:@"PALETTE"].location != NSNotFound)
	{
		// palette conversions done by dcm Object
		isRGB = YES;
	}
}

- (BOOL)loadDICOMDCMFramework
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	DCMObject *dcmObject = 0L;
	
	[PapyrusLock lock];
	
	if( [cachedDCMFrameworkFiles objectForKey: srcFile])
	{
		NSMutableDictionary *dic = [cachedDCMFrameworkFiles objectForKey: srcFile];
		
		dcmObject = [dic objectForKey: @"dcmObject"];
		[dic setValue: [NSNumber numberWithInt: [[dic objectForKey: @"count"] intValue]+1] forKey: @"count"];
	}
	else
	{
		dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
		
		if( dcmObject)
		{
			NSMutableDictionary *dic = [NSMutableDictionary dictionary];
			
			[dic setValue: dcmObject forKey: @"dcmObject"];
			[dic setValue: [NSNumber numberWithInt: 1] forKey: @"count"];
			
			[cachedDCMFrameworkFiles setObject: dic forKey: srcFile];
		}
	}
	
	[PapyrusLock unlock];
	
	if(dcmObject == nil)
	{
		NSLog(@"loadDICOMDCMFramework - no DCMObject at srcFile address, nothing to do");
		[pool release];
		return NO;
	}
	
	NSString *SOPClassUID = [dcmObject attributeValueWithName:@"SOPClassUID"];
	
	//-----------------------common----------------------------------------------------------	
	
	short maxFrame = 1;
	short imageNb = frameNo;
	
#pragma mark *pdf
	if ([ SOPClassUID isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
	{
		NSLog(@"have PDF");
		NSData *pdfData = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
		NSPDFImageRep *rep = [NSPDFImageRep imageRepWithData:pdfData];	
		[rep setCurrentPage:frameNo];	
		NSImage *pdfImage = [[[NSImage alloc] init] autorelease];
		[pdfImage addRepresentation:rep];
		[pdfImage setBackgroundColor: [NSColor whiteColor]];
		
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
		unsigned char *srcImage = [TIFFRep bitmapData];
		
		unsigned char   *argbImage, *tmpPtr, *srcPtr;
		
		argbImage = malloc( height * width * 4);
		isRGB = YES;
		
		//NSLog(@"height %d", height);
		//NSLog(@"width %d", width);
		switch( [TIFFRep bitsPerPixel] )
		{
			case 8:
				NSLog(@"8 bit DICOM PDF");
				tmpPtr = argbImage;
				for( int y = 0 ; y < height; y++)
				{
					srcPtr = srcImage + y*[TIFFRep bytesPerRow];
					
					int x = width;
					while( x-- > 0 )
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
				for( int y = 0 ; y < height; y++ )
				{
					srcPtr = srcImage + y*[TIFFRep bytesPerRow];
					int x = width;
					while( x-- > 0 )
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
				for( int y = 0 ; y < height; y++ )
				{
					srcPtr = srcImage + y*[TIFFRep bytesPerRow];
					
					int x = width;
					while( x-- > 0 )
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
				for( int y = 0 ; y < height; y++ )
				{
					srcPtr = srcImage + y*[TIFFRep bytesPerRow];
					
					int x = width;
					while( x-- > 0 )
					{
						tmpPtr++;
						*tmpPtr++ = *srcPtr;	srcPtr += 2;
						*tmpPtr++ = *srcPtr;	srcPtr += 2;
						*tmpPtr++ = *srcPtr;	srcPtr += 2;
					}
				}
				break;
				
				default:
				NSLog(@"Error - Unknow...");
				break;
		}
		
		fImage = (float*) argbImage;
		
		#ifdef OSIRIX_VIEWER
			[self loadCustomImageAnnotationsPapyLink:-1 DCMLink:dcmObject];
		#endif
		
		[pool release];
		return YES;												 
	} // end encapsulatedPDF
	
	
	pixelSpacingX = 0;
	pixelSpacingY = 0;
	offset = 0.0;
	slope = 1.0;
	
	[self dcmFrameworkLoad0x0018: dcmObject];
	[self dcmFrameworkLoad0x0020: dcmObject];
	[self dcmFrameworkLoad0x0028: dcmObject];
	
#pragma mark *MR/CT functional multiframe
	
	// Is it a new MR/CT multi-frame exam?
	DCMSequenceAttribute *sharedFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"SharedFunctionalGroupsSequence"];
	if (sharedFunctionalGroupsSequence)
	{
		for ( DCMObject *sequenceItem in sharedFunctionalGroupsSequence.sequence )
		{
			DCMSequenceAttribute *MRTimingAndRelatedParametersSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"MRTimingAndRelatedParametersSequence"];
			DCMObject *MRTimingAndRelatedParametersObject = [[MRTimingAndRelatedParametersSequence sequence] objectAtIndex:0];
			if( MRTimingAndRelatedParametersObject)
				[self dcmFrameworkLoad0x0020: MRTimingAndRelatedParametersObject];
			
			DCMSequenceAttribute *planeOrientationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PlaneOrientationSequence"];
			DCMObject *planeOrientationObject = [[planeOrientationSequence sequence] objectAtIndex:0];
			if( planeOrientationObject)
				[self dcmFrameworkLoad0x0020: planeOrientationObject];
			
			DCMSequenceAttribute *pixelMeasureSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelMeasuresSequence"];
			DCMObject *pixelMeasureObject = [[pixelMeasureSequence sequence] objectAtIndex:0];
			if( pixelMeasureObject)
				[self dcmFrameworkLoad0x0018: pixelMeasureObject];
			if( pixelMeasureObject)
				[self dcmFrameworkLoad0x0028: pixelMeasureObject];
			
			DCMSequenceAttribute *pixelTransformationSequence = (DCMSequenceAttribute *)[sequenceItem attributeWithName:@"PixelValueTransformationSequence"];
			DCMObject *pixelTransformationSequenceObject = [[pixelTransformationSequence sequence] objectAtIndex:0];
			if( pixelTransformationSequenceObject)
				[self dcmFrameworkLoad0x0028: pixelTransformationSequenceObject];
		}
	}
	
	
#pragma mark *per frame
	
	// ****** ****** ****** ************************************************************************
	// PER FRAME
	// ****** ****** ****** ************************************************************************
	
	//long frameCount = 0;
	DCMSequenceAttribute *perFrameFunctionalGroupsSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"Per-frameFunctionalGroupsSequence"];
	
	//NSLog(@"perFrameFunctionalGroupsSequence: %@", [perFrameFunctionalGroupsSequence description]);
	if (perFrameFunctionalGroupsSequence)
	{
		if ( perFrameFunctionalGroupsSequence.sequence.count > imageNb && imageNb >= 0 )
		{
			DCMObject *sequenceItem = [[perFrameFunctionalGroupsSequence sequence] objectAtIndex:imageNb];
			if (sequenceItem)
			{
				if ([sequenceItem attributeArrayWithName:@"MREchoSequence"])
				{
					DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"MREchoSequence"];
					DCMObject *object = [[seq sequence] objectAtIndex: 0];
					if( object)
						[self dcmFrameworkLoad0x0018: object];
				}
				
				if ([sequenceItem attributeArrayWithName:@"PixelMeasuresSequence"])
				{
					DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"PixelMeasuresSequence"];
					DCMObject *object = [[seq sequence] objectAtIndex: 0];
					if( object)
						[self dcmFrameworkLoad0x0018: object];
					if( object)
						[self dcmFrameworkLoad0x0028: object];
				}
				
				if ([sequenceItem attributeArrayWithName:@"PlanePositionSequence"])
				{
					DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"PlanePositionSequence"];
					DCMObject *object = [[seq sequence] objectAtIndex: 0];
					
					if( object)
						[self dcmFrameworkLoad0x0020: object];
					if( object)
						[self dcmFrameworkLoad0x0028: object];
				}
					
				if ([sequenceItem attributeArrayWithName:@"PlaneOrientationSequence"])
				{
					DCMSequenceAttribute *seq = (DCMSequenceAttribute *) [sequenceItem attributeWithName:@"PlaneOrientationSequence"];
					DCMObject *object = [[seq sequence] objectAtIndex: 0];
					if( object)
						[self dcmFrameworkLoad0x0020: object];
				}
			}
		}
		else
		{
			NSLog(@"No Frame %d in preFrameFunctionalGroupsSequence", imageNb);
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
		
		if( [dcmObject attributeValueForKey: @"6000,0050"] ) 
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
			
			for ( int i = 0; i < oColumns*oRows/16; i++ )
			{
				unsigned short	octet = pixels[ i];
				
				for ( int x = 0; x < 16; x++ )
				{
					valBit[ x ] = octet & mask ? 1 : 0;
					octet = octet >> 1;
					
					if ( valBit[ x]) oData[ i*16 + x] = 0xFF;
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
	
	if( [dcmObject attributeValueWithName:@"DecayFactor"])
		decayFactor = [[dcmObject attributeValueWithName:@"DecayFactor"] floatValue];
	
	DCMSequenceAttribute *radiopharmaceuticalInformationSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"RadiopharmaceuticalInformationSequence"];
	if( radiopharmaceuticalInformationSequence && radiopharmaceuticalInformationSequence.sequence.count > 0 )
	{
		DCMObject *radionuclideTotalDoseObject = [radiopharmaceuticalInformationSequence.sequence objectAtIndex:0];
		radionuclideTotalDose = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideTotalDose"] floatValue];
		halflife = [[radionuclideTotalDoseObject attributeValueWithName:@"RadionuclideHalfLife"] floatValue];
		radiopharmaceuticalStartTime = [[NSCalendarDate	dateWithString: [[radionuclideTotalDoseObject attributeValueWithName:@"RadiopharmaceuticalStartTime"] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
		
		// WARNING : only time is correct. NOT year/month/day
		acquisitionTime = [[NSCalendarDate dateWithString:[[dcmObject attributeValueWithName:@"AcquisitionTime"] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
		
		[self computeTotalDoseCorrected];
	}
	
	DCMSequenceAttribute *detectorInformationSequence = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"DetectorInformationSequence"];
	if( detectorInformationSequence && detectorInformationSequence.sequence.count > 0 )
	{
		DCMObject *detectorInformation = [detectorInformationSequence.sequence objectAtIndex:0];
		
		NSArray *ipp = [detectorInformation attributeArrayWithName:@"ImagePositionPatient"];
		if( ipp )
		{
			originX = [[ipp objectAtIndex:0] floatValue];
			originY = [[ipp objectAtIndex:1] floatValue];
			originZ = [[ipp objectAtIndex:2] floatValue];
			isOriginDefined = YES;
		}
		
		if( spacingBetweenSlices)
			originZ += frameNo * spacingBetweenSlices;
		else
			originZ += frameNo * sliceThickness;
			
		orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
		orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
		
		NSArray *iop = [detectorInformation attributeArrayWithName:@"ImageOrientationPatient"];
		if( iop )
		{
			for ( int j = 0; j < iop.count; j++ ) 
				orientation[ j ] = [[iop objectAtIndex:j] floatValue];
		}
	}
	
	if( [dcmObject attributeValueForKey: @"7053,1000"] )
	{
		@try
		{
			philipsFactor = [[dcmObject attributeValueForKey: @"7053,1000"] floatValue];
		}
		@catch ( NSException *e)
		{
			NSLog( @"philipsFactor exception");
			NSLog( [e description]);
		}
		NSLog( @"philipsFactor = %f", philipsFactor);
	}
	
	// End SUV		
	
#pragma mark *compute normal vector				
	// Compute normal vector
	
	orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
	orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
	orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
	
	if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]) )
	{
		sliceLocation = originX;
	}
	
	if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]) )
	{ 
		sliceLocation = originY;
	}
	
	if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]) )
	{
		sliceLocation = originZ;
	}	
	
	
#pragma mark READ PIXEL DATA		
	
	maxFrame = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
	if( maxFrame == 0) maxFrame = 1;
	if( pixArray == nil) maxFrame = 1;
	//pixelAttr contains the whole PixelData attribute of every frames. Hence needs to be before the loop
	if ([dcmObject attributeValueWithName:@"PixelData"])
	{
		DCMPixelDataAttribute *pixelAttr = (DCMPixelDataAttribute *)[dcmObject attributeWithName:@"PixelData"];
			
		//=====================================================================
		
	#pragma mark *loading a frame
		
		if ( [[dcmObject attributeValueWithName:@"Modality"] isEqualToString: @"RTDOSE"] )
		{  // Set Z value for each frame
			NSArray *gridFrameOffsetArray = [dcmObject attributeArrayWithName: @"GridFrameOffsetVector"];  //List of Z values
			originZ += [[gridFrameOffsetArray objectAtIndex: imageNb] floatValue];
			if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]) )
			{
				sliceLocation = originX;
			}
			
			if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]) )
			{
				sliceLocation = originY;
			}
			
			if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]) )
			{
				sliceLocation = originZ;
			}	
		}
		
		if( gUseShutter && imageNb != frameNo && maxFrame > 1 )
		{
			self->shutterRect_x = shutterRect_x;
			self->shutterRect_y = shutterRect_y;
			self->shutterRect_w = shutterRect_w;
			self->shutterRect_h = shutterRect_h;
			
			self->shutterCircular_x = shutterCircular_x;
			self->shutterCircular_y = shutterCircular_y;
			self->shutterCircular_radius = shutterCircular_radius;
			
			if( shutterPolygonalSize )
			{
				self->shutterPolygonalSize = shutterPolygonalSize;
				self->shutterPolygonal = malloc( shutterPolygonalSize * sizeof( NSPoint));
				memcpy( self->shutterPolygonal, shutterPolygonal, shutterPolygonalSize * sizeof( NSPoint ) );
			}
			
			self->DCMPixShutterOnOff = DCMPixShutterOnOff;
		}
		
		//get PixelData
		NSData *pixData = [pixelAttr decodeFrameAtIndex:imageNb];
		short *oImage =  malloc([pixData length]);	//pointer to a memory zone where each pixel of the data has a short value reserved
		[pixData getBytes:oImage];
		
		if( oImage == nil ) //there was no data for this frame -> create empty image
		{
			NSLog(@"This is really bad..... Please send this file to rossetantoine@bluewin.ch");
			//NSLog(@"image size: %d", ( height * width * 2));
			oImage = malloc( height * width * 2);
			//gArrPhotoInterpret [fileNb] = MONOCHROME2;
			
			long yo = 0;
			for( unsigned long i = 0 ; i < height * width; i++ )
			{
				oImage[ i] = yo++;
				if( yo>= width) yo = 0;
			}
		}
		
		//-----------------------frame data already loaded in (short) oImage --------------
		
		isRGB = NO;
		inverseVal = NO;
		
		NSString *colorspace = [dcmObject attributeValueWithName:@"PhotometricInterpretation"];		
		if ([colorspace rangeOfString:@"MONOCHROME1"].location != NSNotFound)
			{inverseVal = YES; savedWL = -savedWL;}													
		/*else if ( [colorspace hasPrefix:@"MONOCHROME2"])	{inverseVal = NO; savedWL = savedWL;} */
		if ( [colorspace hasPrefix:@"YBR"]) isRGB = YES;		
		if ( [colorspace hasPrefix:@"PALETTE"])	{ bitsAllocated = 8; isRGB = YES; NSLog(@"Palette depth conveted to 8 bit");}
		if ([colorspace rangeOfString:@"RGB"].location != NSNotFound) isRGB = YES;			
		/******** dcm Object will do this *******convertYbrToRgb -> planar is converted***/		
		if ([colorspace rangeOfString:@"YBR"].location != NSNotFound)
		{
			fPlanarConf = 0;
			isRGB = YES;
		}
		
		if (isRGB == YES)
		{
			unsigned char   *ptr, *tmpImage;
			int loop = (int) height * (int) realwidth;
			tmpImage = malloc (loop * 4L);
			ptr   = tmpImage;
			
			if( bitsAllocated > 8)
			{ // RGB_FFF
				unsigned short   *bufPtr;
				bufPtr = (unsigned short*) oImage;
				while( loop-- > 0)
				{		//unsigned short=16 bit, then I suppose A should be 65535
					*ptr++	= 255;			//ptr++;
					*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
					*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
					*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
				}
			}
			else
			{ // RGB_888
				NSLog(@"Convert to ARGB 8 bit");
				unsigned char   *bufPtr;
				bufPtr = (unsigned char*) oImage;
				
				while( loop-- > 0 )
				{
					*ptr++	= 255;			//ptr++;
					*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
					*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
					*ptr++	= *bufPtr++;		//ptr++;  bufPtr++;
				}
				
			}
			free(oImage);
			oImage = (short*) tmpImage;
		}
		else if( bitsAllocated == 32)
		{
			NSLog( @"unsupported 32 bits");
		}
		else if( bitsAllocated == 8)
		{	// Planar 8
			//-> 16 bits image
			unsigned char   *bufPtr;
			short			*ptr, *tmpImage;
			int			loop, totSize;
			
			totSize = (int) ((int) height * (int) realwidth * 2L);
			tmpImage = malloc( totSize);
			
			bufPtr = (unsigned char*) oImage;
			ptr    = tmpImage;
			
			loop = totSize/2;
			while( loop-- > 0 )
			{
				*ptr++ = *bufPtr++;
			}
			free(oImage);
			oImage =  (short*) tmpImage;
		}
		
		
		if( realwidth != width )
		{
			if( isRGB )
			{
				char	*ptr = (char*) oImage;
				for( int i = 0; i < height;i++ )
				{
					memmove( ptr + i*width*4, ptr + i*realwidth*4, width*4);
				}
			}
			else
			{
				if( bitsAllocated == 32 )
				{
					for( int i = 0; i < height;i++ )
					{
						memmove( oImage + i*width*2, oImage + i*realwidth*2, width*4);
					}
				}
				else
				{
					for( int i = 0; i < height; i++)
					{
						memmove( oImage + i*width, oImage + i*realwidth, width*2);
					}
				}
			}
		}
		
		//***********
		
		if( isRGB )
		{
			if( self->fExternalOwnedImage)
			{
				self->fImage = self->fExternalOwnedImage;
				memcpy( self->fImage, oImage, width*height*sizeof(float));
				free(oImage);
			}
			else self->fImage = (float*) oImage;
			oImage = nil;
			
			if( oData && gDisplayDICOMOverlays )
			{
				unsigned char	*rgbData = (unsigned char*) self->fImage;
				
				for( int y = 0; y < oRows; y++ )
				{
					for( int x = 0; x < oColumns; x++ )
					{
						if( oData[ y * oColumns + x] )
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
			if( bitsAllocated == 32 )
			{
				unsigned int	*usint = (unsigned int*) oImage;
				int				*sint = (int*) oImage;
				float			*tDestF;
				
				if( self->fExternalOwnedImage)
				{
					tDestF = self->fImage = self->fExternalOwnedImage;
				}
				else
				{
					tDestF = self->fImage = malloc(width*height*sizeof(float) + 100);
				}
				
				if( fIsSigned > 0 )
				{
					int x = height * width;
					while( x-->0 )
					{
						*tDestF++ = ((float) (*sint++)) * slope + offset;
					}
				}
				else
				{
					int x = height * width;
					while( x-->0 )
					{
						*tDestF++ = ((float) (*usint++)) * slope + offset;
					}
				}
				
				free(oImage);
				oImage = nil;
			}
			else
			{
				vImage_Buffer src16, dstf;
				dstf.height = src16.height = height;
				dstf.width = src16.width = width;
				src16.rowBytes = width*2;
				dstf.rowBytes = width*sizeof(float);
				
				src16.data = oImage;
				
				if( self->fExternalOwnedImage)
				{
					self->fImage = self->fExternalOwnedImage;
				}
				else
				{
					self->fImage = malloc(width*height*sizeof(float) + 100);
				}
				
				dstf.data = self->fImage;
				
				if( fIsSigned > 0 )
				{
					vImageConvert_16SToF( &src16, &dstf, offset, slope, 0);
				}
				else
				{
					
					vImageConvert_16UToF( &src16, &dstf, offset, slope, 0);
				}
				
				if( inverseVal )
				{
					float neg = -1;
					vDSP_vsmul( fImage, 1, &neg, fImage, 1, height * width);
				}
				
				free(oImage);
				oImage = nil;
			}
			
			if( oData && gDisplayDICOMOverlays )
			{
				for( int y = 0; y < oRows; y++ )
				{
					for( int x = 0; x < oColumns; x++ )
					{
						if( oData[ y * oColumns + x]) self->fImage[ y * width + x] = 0xFF;
					}
				}
			}
		}
		
		wl = 0;
		ww = 0; //Computed later, only if needed
		
		if( savedWW != 0 )
		{
			wl = savedWL;
			ww = savedWW;
		}
		
	#pragma mark *after loading a frame
		
	}//end of if ([dcmObject attributeValueWithName:@"PixelData"])

	if( fabs(pixelSpacingX) / fabs(pixelSpacingY) > 10000 || fabs(pixelSpacingX) / fabs(pixelSpacingY) < 0.0001)
	{
		pixelSpacingX = 1;
		pixelSpacingY = 1;
	}
	
	if( pixelSpacingX < 0) pixelSpacingX = -pixelSpacingX;
	if( pixelSpacingY < 0) pixelSpacingY = -pixelSpacingY;
	if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
	
	#ifdef OSIRIX_VIEWER
		[self loadCustomImageAnnotationsPapyLink:-1 DCMLink:dcmObject];
	#endif
	
	[pool release];
	
	return YES;
}

- (void*) getPapyGroup: (int) group
{
	NSString *groupKey = [NSString stringWithFormat:@"%d", group];
	
	SElement *theGroupP = nil;
	
	[PapyrusLock lock];
	
	NSMutableDictionary *cachedGroupsForThisFile = [cachedPapyGroups valueForKey: srcFile];
	
	int fileNb = -1;
	
	if( cachedGroupsForThisFile == nil)
	{
		fileNb = Papy3FileOpen ( (char*) [srcFile UTF8String], (PAPY_FILE) 0, TRUE, 0);
		
		if( fileNb >= 0)
		{
			cachedGroupsForThisFile = [NSMutableDictionary dictionary];
			[cachedPapyGroups setObject: cachedGroupsForThisFile forKey: srcFile];
			[cachedGroupsForThisFile setValue: [NSNumber numberWithInt: fileNb]  forKey: @"fileNb"];
			[cachedGroupsForThisFile setValue: [NSNumber numberWithInt: 1] forKey: @"count"];
			
			if( [cachedPapyGroups count] >= kMax_file_open)
				NSLog( @"WARNING: Too much files opened for Papyrus Toolkit");
		}
		else NSLog( @"Papy3FileOpen failed : %d", fileNb);
	}
	else
	{
		fileNb = [[cachedGroupsForThisFile valueForKey: @"fileNb"] intValue];
		
		if( group == 0L)
		{
			[cachedGroupsForThisFile setValue: [NSNumber numberWithInt: [[cachedGroupsForThisFile valueForKey: @"count"] intValue] +1] forKey: @"count"];
		}
	}
	
	if( fileNb >= 0)
	{
		if( group == 0)
		{
			#if !__LP64__
			theGroupP = (SElement*) 0xFFFFFFFF;
			#else
			theGroupP = (SElement*) 0xFFFFFFFFFFFFFFFF;
			#endif
		}
		else
		{
			if( [cachedGroupsForThisFile valueForKey: groupKey] == nil)
			{
				int theErr = 0;
				
				if (gIsPapyFile[ fileNb] == DICOM10) theErr = Papy3FSeek (gPapyFile [fileNb], SEEK_SET, 132L);
				
				if( theErr == 0 )
				{
					theErr = Papy3GotoGroupNb (fileNb, group);
					
					if( theErr >= 0)
					{
						if( Papy3GroupRead(fileNb, &theGroupP) > 0)
						{
							[cachedGroupsForThisFile setValue: [NSValue valueWithPointer: theGroupP] forKey: groupKey];
						}
						else
							NSLog( @"Error while reading a group (Papyrus)");
					}
					else
					{
						[cachedGroupsForThisFile setValue: [NSValue valueWithPointer: 0L]  forKey: groupKey];
					}
				}
			}
			else
				theGroupP = [[cachedGroupsForThisFile valueForKey: groupKey] pointerValue];
		}
	}
	
	[PapyrusLock unlock];
	
	return theGroupP;
}  

+ (void) purgeCachedDictionaries
{
	[PapyrusLock lock];
	
	[cachedDCMFrameworkFiles removeAllObjects];
	
	for( NSString *file in [cachedPapyGroups allKeys])
	{
		NSMutableDictionary *cachedGroupsForThisFile = [cachedPapyGroups valueForKey: file];
		
		if( cachedGroupsForThisFile)
		{
			int fileNb = [[cachedGroupsForThisFile valueForKey: @"fileNb"] intValue];
			[cachedGroupsForThisFile removeObjectForKey: @"fileNb"];
			[cachedGroupsForThisFile removeObjectForKey: @"count"];
				
			for( NSValue *pointer in [cachedGroupsForThisFile allValues] )
			{
				SElement *theGroupP = (SElement*) [pointer pointerValue];
				Papy3GroupFree ( &theGroupP, TRUE);
			}
				
			[cachedPapyGroups removeObjectForKey: file];
			Papy3FileClose (fileNb, TRUE);
		}
	}
	
	[cachedPapyGroups removeAllObjects];
	
	[PapyrusLock unlock];
}

- (void) clearCachedDCMFrameworkFiles
{
	[PapyrusLock lock];
	
	if( fImage)
	{
		NSMutableDictionary *o = [cachedDCMFrameworkFiles valueForKey: srcFile];
		
		if( o)
		{
			[o setValue: [NSNumber numberWithInt: [[o objectForKey: @"count"] intValue]-1] forKey: @"count"];
			
			if( [[o objectForKey: @"count"] intValue] <= 0)
				[cachedDCMFrameworkFiles removeObjectForKey: srcFile];
		}
	}
	
	[PapyrusLock unlock];
}

- (void) clearCachedPapyGroups
{
	[PapyrusLock lock];
	
	if( fImage)
	{
		NSMutableDictionary *cachedGroupsForThisFile = [cachedPapyGroups valueForKey: srcFile];
		
		if( cachedGroupsForThisFile)
		{
			[cachedGroupsForThisFile setValue: [NSNumber numberWithInt: [[cachedGroupsForThisFile objectForKey: @"count"] intValue]-1] forKey: @"count"];
			
			if( [[cachedGroupsForThisFile objectForKey: @"count"] intValue] <= 0)
			{
				int fileNb = [[cachedGroupsForThisFile valueForKey: @"fileNb"] intValue];
				[cachedGroupsForThisFile removeObjectForKey: @"fileNb"];
				[cachedGroupsForThisFile removeObjectForKey: @"count"];
				
				for( NSValue *pointer in [cachedGroupsForThisFile allValues] )
				{
					SElement *theGroupP = (SElement*) [pointer pointerValue];
					Papy3GroupFree ( &theGroupP, TRUE);
				}
				
				[cachedPapyGroups removeObjectForKey: srcFile];
				Papy3FileClose (fileNb, TRUE);
			}
		}
	}
	
	[PapyrusLock unlock];
}

- (void) papyLoadGroup0x0018: (SElement*) theGroupP
{
	UValue_T *val, *tmp;
	PapyULong nbVal;
	int elemType, i;
	
	val = Papy3GetElement (theGroupP, papFrameofReferenceUIDGr, &nbVal, &elemType);
	if ( val)
	{
		[frameOfReferenceUID release];
		frameOfReferenceUID = [[NSString stringWithCString:val->a] retain];
	}
	
	val = Papy3GetElement (theGroupP, papSliceThicknessGr, &nbVal, &elemType);
	if ( val)
		sliceThickness = atof( val->a);
	
	val = Papy3GetElement (theGroupP, papSpacingBetweenSlicesGr, &nbVal, &elemType);
	if ( val ) spacingBetweenSlices = atof( val->a);
	
	val = Papy3GetElement (theGroupP, papRepetitionTimeGr, &nbVal, &elemType);
	if ( val )
	{
		[repetitiontime release];
		repetitiontime = [[NSString stringWithFormat:@"%0.1f", atof( val->a)] retain];
	}
	
	val = Papy3GetElement (theGroupP, papEchoTimeGr, &nbVal, &elemType);
	if ( val)
	{
		[echotime release];
		echotime = [[NSString stringWithFormat:@"%0.1f", atof( val->a)] retain];
	}
	
	val = Papy3GetElement (theGroupP, papEffectiveEchoTime, &nbVal, &elemType);
	if ( val)
	{
		[echotime release];
		echotime = [[NSString stringWithFormat:@"%0.1f", val->fd] retain];
	}
	
	val = Papy3GetElement (theGroupP, papFlipAngleGr, &nbVal, &elemType);
	if ( val)
	{
		[flipAngle release];
		flipAngle = [[NSString stringWithFormat:@"%0.1f", atof( val->a)] retain];
	}
	
	val = Papy3GetElement (theGroupP, papProtocolNameGr, &nbVal, &elemType);
	if ( val)
	{
		[protocolName release];
		protocolName = [[NSString stringWithCString:val->a] retain];
	}
	
	val = Papy3GetElement (theGroupP, papViewPositionGr, &nbVal, &elemType);
	if ( val )
	{
		[viewPosition release];
		viewPosition = [[NSString stringWithCString:val->a] retain];
	}
	
	val = Papy3GetElement (theGroupP, papPositionerPrimaryAngleGr, &nbVal, &elemType);
	if ( val )
	{
		[positionerPrimaryAngle release];
		positionerPrimaryAngle = [[NSNumber numberWithDouble: atof( val->a)] retain];
	}
	
	val = Papy3GetElement (theGroupP, papPositionerSecondaryAngleGr, &nbVal, &elemType);
	if ( val )
	{
		[positionerSecondaryAngle release];
		positionerSecondaryAngle = [[NSNumber numberWithDouble: atof( val->a)] retain];
	}
	
	val = Papy3GetElement (theGroupP, papPatientPositionGr, &nbVal, &elemType);
	if ( val )
	{
		[patientPosition release];
		patientPosition = [[NSString stringWithCString:val->a] retain];
	}
	
	val = Papy3GetElement (theGroupP, papCineRateGr, &nbVal, &elemType);
	if (!cineRate && val != NULL) cineRate = atof( val->a);	//[[NSString stringWithFormat:@"%0.1f", ] floatValue];
	
	// Ultrasounds pixel spacing
	if( [modalityString isEqualToString:@"US"])
	{
		val = Papy3GetElement (theGroupP, papSequenceofUltrasoundRegionsGr, &nbVal, &elemType);
		if ( val != NULL)
		{
			if( val->sq != NULL )
			{
				BOOL spacingFound = NO;
				
				Papy_List	*dcmList = val->sq;
				while (dcmList != NULL)
				{
					if( dcmList->object->item)
					{
						SElement *gr = (SElement *)dcmList->object->item->object->group;
						if ( gr->group == 0x0018 && spacingFound == NO)
						{
							int physicalUnitsX = 0;
							int physicalUnitsY = 0;
							
							val = Papy3GetElement (gr, papPhysicalUnitsXDirectionGr, &nbVal, &elemType);
							if ( val ) physicalUnitsX = val->us;
							val = Papy3GetElement (gr, papPhysicalUnitsYDirectionGr, &nbVal, &elemType);
							if ( val ) physicalUnitsY = val->us;
							
							if( physicalUnitsX == 3 && physicalUnitsY == 3)	// We want only cm !
							{
								double xxx = 0, yyy = 0;
								
								val = Papy3GetElement (gr, papPhysicalDeltaXGr, &nbVal, &elemType);
								if ( val ) xxx = val->fd;
								val = Papy3GetElement (gr, papPhysicalDeltaYGr, &nbVal, &elemType);
								if ( val ) yyy = val->fd;
								
								if( xxx && yyy)
								{
									pixelSpacingX = fabs( xxx) * 10.;	// These are in cm !
									pixelSpacingY = fabs( yyy) * 10.;
									spacingFound = YES;
								}
							}
						}
					}
					dcmList = dcmList->next;
				}
			}
		}
	}
	
	val = Papy3GetElement (theGroupP, papImagerPixelSpacingGr, &nbVal, &elemType);
	if ( val )
	{
		tmp = val;
		pixelSpacingY = atof( tmp->a);
		
		if( nbVal > 1)
		{
			tmp++;
			pixelSpacingX = atof( tmp->a);
		}
	}
	
	if(!cineRate)
	{
		val = Papy3GetElement (theGroupP, papFrameDelayGr, &nbVal, &elemType);
		if ( val )
		{
			if( atof( val->a) > 0)
				cineRate = 1000./atof( val->a);
		}
	}
	
	if(!cineRate)
	{
		val = Papy3GetElement (theGroupP, papFrameTimeVectorGr, &nbVal, &elemType);
		if ( val )
		{
			if( atof( val->a) > 0)
				cineRate = 1000./atof( val->a);
		}
	}
	
	if( gUseShutter)
	{
		val = Papy3GetElement (theGroupP, papShutterShapeGr, &nbVal, &elemType);
		if ( val )
		{
			PapyULong nbtmp;
			
			for( i = 0 ; i < nbVal; i++)
			{
				if( [[NSString stringWithCString:val->a] isEqualToString:@"RECTANGULAR"])
				{
					DCMPixShutterOnOff = YES;
					
					tmp = Papy3GetElement (theGroupP, papShutterLeftVerticalEdgeGr, &nbtmp, &elemType);
					if (tmp != NULL) shutterRect_x = atoi( tmp->a);
					
					tmp = Papy3GetElement (theGroupP, papShutterRightVerticalEdgeGr, &nbtmp, &elemType);
					if (tmp != NULL) shutterRect_w = atoi( tmp->a) - shutterRect_x;
					
					tmp = Papy3GetElement (theGroupP, papShutterUpperHorizontalEdgeGr, &nbtmp, &elemType);
					if (tmp != NULL) shutterRect_y = atoi( tmp->a);
					
					tmp = Papy3GetElement (theGroupP, papShutterLowerHorizontalEdgeGr, &nbtmp, &elemType);
					if (tmp != NULL) shutterRect_h = atoi( tmp->a) - shutterRect_y;
				}
				else if( [[NSString stringWithCString:val->a] isEqualToString:@"CIRCULAR"])
				{
					DCMPixShutterOnOff = YES;
					
					tmp = Papy3GetElement (theGroupP, papCenterofCircularShutterGr, &nbtmp, &elemType);
					if (tmp != NULL && nbtmp == 2)
					{
						shutterCircular_x = atoi( tmp->a);
						tmp++;
						shutterCircular_y = atoi( tmp->a);
					}
					
					tmp = Papy3GetElement (theGroupP, papRadiusofCircularShutterGr, &nbtmp, &elemType);
					if (tmp != NULL) shutterCircular_radius = atoi( tmp->a);
				}
				else if( [[NSString stringWithCString:val->a] isEqualToString:@"POLYGONAL"])
				{
					DCMPixShutterOnOff = YES;
					
					tmp = Papy3GetElement (theGroupP, papVerticesofthePolygonalShutterGr, &nbtmp, &elemType);
					
					if( shutterPolygonal) free( shutterPolygonal);
					
					shutterPolygonalSize = 0;
					shutterPolygonal = malloc( nbtmp * sizeof( NSPoint) / 2);
					
					int y, x;
					for( y = 0, x = 0 ; y < nbtmp; y+=2, x++)
					{
						shutterPolygonal[ x].x = atoi( tmp->a);		tmp++;
						shutterPolygonal[ x].y = atoi( tmp->a);		tmp++;
						shutterPolygonalSize++;
					}
				}
				else NSLog( @"Shutter not supported: %@", [NSString stringWithCString:val->a]);
				
				val++;
			}
		}
	}
}

- (void) papyLoadGroup0x0020: (SElement*) theGroupP
{
	UValue_T *val, *val3, *tmp, *tmpVal3;
	PapyULong nbVal, pos;
	int elemType, i;
	
	val = Papy3GetElement (theGroupP, papImagePositionPatientGr, &nbVal, &elemType);
	if ( val )
	{
		tmp = val;
		
		originX = atof( tmp->a);
		
		if( nbVal > 1)
		{
			tmp++;
			originY = atof( tmp->a);
		}
		
		if( nbVal > 2)
		{
			tmp++;
			originZ = atof( tmp->a);
		}
		
		isOriginDefined = YES;
	}
	
	val = Papy3GetElement (theGroupP, papImageOrientationPatientGr, &nbVal, &elemType);
	if ( val )
	{
		tmpVal3 = val;
		if( nbVal != 6)
		{
			NSLog(@"Orientation is NOT 6 !!!");
			if( nbVal > 6 ) nbVal = 6;
		}
		
		for ( int j = 0; j < nbVal; j++ )
		{
			orientation[ j]  = atof( tmpVal3->a);
			tmpVal3++;
		}
		
		for ( int j = nbVal; j < 6; j++ )
			orientation[ j] = 0;
	}
	
	val = Papy3GetElement (theGroupP, papImageLateralityGr, &nbVal, &elemType);
	if ( val )
	{
		[laterality release];
		laterality = [[NSString stringWithCString:val->a] retain];
	}
	
	if( laterality == nil )
	{
		val = Papy3GetElement (theGroupP, papLateralityGr, &nbVal, &elemType);
		if ( val )
		{
			[laterality release];
			laterality = [[NSString stringWithCString:val->a] retain];
		}
	}
}

- (void) papyLoadGroup0x0028: (SElement*) theGroupP
{
	UValue_T *val, *val3, *tmp, *tmpVal3;
	PapyULong nbVal, pos;
	int elemType, i;

	val3 = Papy3GetElement (theGroupP, papRescaleInterceptGr, &pos, &elemType);
	if ( val3 )	{
		tmpVal3 = val3;
		// get the last offset
		for ( int j = 1; j < pos; j++ ) tmpVal3++;
		offset =  atof( tmpVal3->a);
	}
	val3 = Papy3GetElement (theGroupP, papRescaleSlopeGr, &pos, &elemType);
	if ( val3 )
	{
		tmpVal3 = val3;
		// get the last slope
		for ( int j = 1; j < pos; j++ ) tmpVal3++;
		slope = atof( tmpVal3->a);
		
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
	if( val)
		bitsAllocated = (int) val->us;
	
//	val = Papy3GetElement (theGroupP, papHighBitGr, &nbVal, &elemType);
//	highBit = (int) val->us;
	
	val = Papy3GetElement (theGroupP, papBitsStoredGr, &nbVal, &elemType);
	if( val)
		bitsStored = (int) val->us;
	
	// ROWS
	val = Papy3GetElement (theGroupP, papRowsGr, &nbVal, &elemType);
	if ( val )
	{
		height = (int) (*val).us;
		height /=2;
		height *=2;
	}
	// COLUMNS
	val = Papy3GetElement (theGroupP, papColumnsGr, &nbVal, &elemType);
	if ( val )
	{
		realwidth = (int) (*val).us;
		width = realwidth/2;
		width *=2;
		
		if( realwidth != width) NSLog(@"width!=realwidth");
	}
	
	if( shutterRect_w == 0) shutterRect_w = width;
	if( shutterRect_h == 0) shutterRect_h = height;
	
	// PIXEL REPRESENTATION
	val = Papy3GetElement (theGroupP, papPixelRepresentationGr, &nbVal, &elemType);
	if (val != NULL)
	{
		if( val->us == 1) fIsSigned = YES;
		else fIsSigned = NO;
	}
	
	val = Papy3GetElement (theGroupP, papWindowCenterGr, &nbVal, &elemType);
	if ( val )
		savedWL = atof( val->a);
	
	val = Papy3GetElement (theGroupP, papWindowWidthGr, &nbVal, &elemType);
	if ( val )
	{
		savedWW = atof( val->a);
		if(  savedWW < 0) savedWW =-savedWW;
	}
	
	// PLANAR CONFIGURATION
	val = Papy3GetElement (theGroupP, papPlanarConfigurationGr, &nbVal, &elemType);
	if ( val)
		fPlanarConf = (int) val->us;
	
	val = Papy3GetElement (theGroupP, papPixelSpacingGr, &nbVal, &elemType);
	if ( val )
	{
		tmp = val;
		
		pixelSpacingY = atof( tmp->a);
		
		if( nbVal > 1)
		{
			tmp++;
			
			pixelSpacingX = atof( tmp->a);
		}
	}
	
	val = Papy3GetElement (theGroupP, papPixelAspectRatioGr, &nbVal, &elemType);
	if ( val )
	{
		float ratiox = 1, ratioy = 1;
		
		tmp = val;
		
		ratiox = atof( tmp->a);
		
		if( nbVal > 1)
		{
			tmp++;
			
			ratioy = atof( tmp->a);
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
	
	[PapyrusLock lock];
	
	if( [[cachedPapyGroups valueForKey: srcFile] valueForKey: @"fileNb"])
	{
		int fileNb = [[[cachedPapyGroups valueForKey: srcFile] valueForKey: @"fileNb"] intValue];
		
		if (gArrPhotoInterpret [fileNb] == PALETTE)
		{
			BOOL found = NO, found16 = NO;
			
			if( clutRed) free( clutRed);
			if( clutGreen) free( clutGreen);
			if( clutBlue) free( clutBlue);
			
			clutRed = calloc( 65536, 1);		if( clutRed == nil) NSLog(@"error clutRed == nil");
			clutGreen = calloc( 65536, 1);		if( clutGreen == nil) NSLog(@"error clutRed == nil");
			clutBlue = calloc( 65536, 1);		if( clutBlue == nil) NSLog(@"error clutRed == nil");
			
			// initialisation
			clutEntryR = clutEntryG = clutEntryB = 0;
			clutDepthR = clutDepthG = clutDepthB = 0;
			
			// read the RED descriptor of the color lookup table
			val = Papy3GetElement (theGroupP, papRedPaletteColorLookupTableDescriptorGr, &nbVal, &elemType);
			tmp = val;
			if ( val )
			{
				clutEntryR = tmp->us;
				tmp++;tmp++;
				clutDepthR = tmp->us;
			} // if ...read Red palette color descriptor
			
			// read the GREEN descriptor of the color lookup table
			val = Papy3GetElement (theGroupP, papGreenPaletteColorLookupTableDescriptorGr, &nbVal, &elemType);
			if ( val )
			{
				clutEntryG	= val->us;
				tmp			= val + 2;
				clutDepthG	= tmp->us;
			} // if ...read Green palette color descriptor
			
			// read the BLUE descriptor of the color lookup table
			val = Papy3GetElement (theGroupP, papBluePaletteColorLookupTableDescriptorGr, &nbVal, &elemType);
			if ( val )
			{
				clutEntryB = val->us;
				tmp     = val + 2;
				clutDepthB = tmp->us;
			} // if ...read Blue palette color descriptor
			
			if( clutEntryR > 256) NSLog(@"R-Palette > 256");
			if( clutEntryG > 256) NSLog(@"G-Palette > 256");
			if( clutEntryB > 256) NSLog(@"B-Palette > 256");
			
			val = Papy3GetElement (theGroupP, papSegmentedRedPaletteColorLookupTableDataGr, &nbVal, &elemType);
			if ( val )	// SEGMENTED PALETTE - 16 BIT !
			{
				if (clutDepthR == 16  && clutDepthG == 16  && clutDepthB == 16)
				{
					long length, xx, xxindex, jj;
					unsigned short	*shortRed, *shortGreen, *shortBlue;
					
					if( shortRed) free( shortRed);
					if( shortGreen) free( shortGreen);
					if( shortBlue) free( shortBlue);
					
					shortRed = malloc( 65535L * sizeof( unsigned short));
					shortGreen = malloc( 65535L * sizeof( unsigned short));
					shortBlue = malloc( 65535L * sizeof( unsigned short));
					
					// extract the RED palette clut data
					val = Papy3GetElement (theGroupP, papSegmentedRedPaletteColorLookupTableDataGr, &nbVal, &elemType);
					if ( val )
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
					}//endif
					
					// extract the GREEN palette clut data
					val = Papy3GetElement (theGroupP, papSegmentedGreenPaletteColorLookupTableDataGr, &nbVal, &elemType);
					if ( val )
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
					if ( val )
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
				if( clutEntryR == 0 && clutEntryG == 0 && clutEntryB == 0)
				{
					NSLog( @"****** clutEntryR == 0 && clutEntryG == 0 && clutEntryB == 0");
					clutEntryR = 65535;
					clutEntryG = 65535;
					clutEntryB = 65535;
				}
				
				// extract the RED palette clut data
				val = Papy3GetElement (theGroupP, papRedPaletteCLUTDataGr, &nbVal, &elemType);
				if ( val )
				{
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for ( int j = 0; j < clutEntryR; j++, ptrs++ ) clutRed [j] = (int) (*ptrs/256);
					
					found = YES; 	// this is used to let us know we have to look for the other element */
				}//endif
				
				// extract the GREEN palette clut data
				val = Papy3GetElement (theGroupP, papGreenPaletteCLUTDataGr, &nbVal, &elemType);
				if ( val )
				{
					unsigned short  *ptrs = (unsigned short*) val->a;
					for ( int j = 0; j < clutEntryG; j++, ptrs++ ) clutGreen [j] = (int) (*ptrs/256);
				}
				// extract the BLUE palette clut data
				val = Papy3GetElement (theGroupP, papBluePaletteCLUTDataGr, &nbVal, &elemType);
				if ( val )
				{
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for ( int j = 0; j < clutEntryB; j++, ptrs++ ) clutBlue [j] = (int) (*ptrs/256);
				}
			} // if ...the palette has 256 entries and thus we extract the clut datas
			else if (clutDepthR == 8  && clutDepthG == 8  && clutDepthB == 8)
			{
				// extract the RED palette clut data
				val = Papy3GetElement (theGroupP, papRedPaletteCLUTDataGr, &nbVal, &elemType);
				if ( val )
				{
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for ( int j = 0; j < clutEntryR; j++, ptrs++) clutRed [j] = (int) (*ptrs);
					found = YES; 	// this is used to let us know we have to look for the other element */
				}//endif
				
				// extract the GREEN palette clut data
				val = Papy3GetElement (theGroupP, papGreenPaletteCLUTDataGr, &nbVal, &elemType);
				if ( val )
				{
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for ( int j = 0; j < clutEntryG; j++, ptrs++) clutGreen [j] = (int) (*ptrs);
				}
				// extract the BLUE palette clut data
				val = Papy3GetElement (theGroupP, papBluePaletteCLUTDataGr, &nbVal, &elemType);
				if ( val )
				{
					unsigned short  *ptrs =  (unsigned short*) val->a;
					for ( int j = 0; j < clutEntryB; j++, ptrs++) clutBlue [j] = (int) (*ptrs);
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
	}
	
	[PapyrusLock unlock];
	
	if( gUseVOILUT)
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
							for ( int j = 0; j < VOILUT_number; j++ )
							{
								VOILUT_table [j] = (unsigned int) val->us;			val++;
							}
						}
					}
				}
			}
		}
	}
}

- (BOOL) loadDICOMPapyrus // PLEASE, KEEP BOTH FUNCTIONS FOR TESTING PURPOSE. THANKS
{
	int				elemType;
	PapyShort		imageNb, ee,  err, theErr;
	PapyULong		nbVal, i, pos;
	SElement		*theGroupP;
	UValue_T		*val, *tmp;
	BOOL			returnValue = NO;
	
	clutRed = nil;
	clutGreen = nil;
	clutBlue = nil;
	
	fSetClut = NO;
	fSetClut16 = NO;
	
	fPlanarConf = 0;
	pixelRatio = 1.0;
	
	orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
	orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
	
	frameOfReferenceUID = 0;
	sliceThickness = 0;
	spacingBetweenSlices = 0;
	repetitiontime = 0;
	echotime = 0;
	flipAngle = 0;
	protocolName = 0;
	viewPosition = 0;
	patientPosition = 0;
	width = height = 0;

	originX = 0;
	originY = 0;
	originZ = 0;
	
	if( [self getPapyGroup: 0])	// This group is mandatory...
	{
		UValue_T		*val3, *tmpVal3;
		unsigned short	*shortRed, *shortGreen, *shortBlue;
		int				fileNb = -1;
		
		[PapyrusLock lock];
		if( [[cachedPapyGroups valueForKey: srcFile] valueForKey: @"fileNb"])
			fileNb = [[[cachedPapyGroups valueForKey: srcFile] valueForKey: @"fileNb"] intValue];
		[PapyrusLock unlock];
		
		modalityString = nil;
		
		imageNb = 1 + frameNo; 
		
		pixelSpacingX = 0;
		pixelSpacingY = 0;
		
		offset = 0.0;
		slope = 1.0;
		
		theGroupP = (SElement*) [self getPapyGroup: 0x0008];
		if( theGroupP )
		{
			val = Papy3GetElement (theGroupP, papRecommendedDisplayFrameRateGr, &nbVal, &elemType );
			if ( val ) cineRate = atof( val->a);	//[[NSString stringWithFormat:@"%0.1f", ] floatValue];
			
			val = Papy3GetElement (theGroupP, papAcquisitionTimeGr, &nbVal, &elemType );
			if( val )
			{
				NSString		*cc = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
				NSCalendarDate	*cd = [[NSCalendarDate alloc] initWithString:cc calendarFormat:@"%H%M%S"];
				
				if( cd == nil) cd = [[NSCalendarDate alloc] initWithString:cc calendarFormat:@"%H%M"];
				
				if( cd)
					acquisitionTime = [[NSCalendarDate	dateWithString: [cd descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
				
				[cd release];
				[cc release];
			}
			
			val = Papy3GetElement (theGroupP, papModalityGr, &nbVal, &elemType);
			if (val != NULL) modalityString = [NSString stringWithCString:val->a encoding: NSASCIIStringEncoding];
		}
		
		theGroupP = (SElement*) [self getPapyGroup: 0x0010];
		if( theGroupP )
		{
			val = Papy3GetElement (theGroupP, papPatientsWeightGr, &nbVal, &elemType);
			if ( val ) patientsWeight = atof( val->a);
			else patientsWeight = 0;
		}
		
		theGroupP = (SElement*) [self getPapyGroup: 0x0018];
		if( theGroupP)
			[self papyLoadGroup0x0018: theGroupP];
			
		theGroupP = (SElement*) [self getPapyGroup: 0x0020];
		if( theGroupP)
			[self papyLoadGroup0x0020: theGroupP];
		
		theGroupP = (SElement*) [self getPapyGroup: 0x0028];
		if( theGroupP ) // This group is MANDATORY...
		{
			[self papyLoadGroup0x0028: theGroupP];
			
	#pragma mark SUV
			
			// Get values needed for SUV calcs:
			theGroupP = (SElement*) [self getPapyGroup: 0x0054];
			if( theGroupP )
			{
				val = Papy3GetElement (theGroupP, papUnitsGr, &pos, &elemType );
				if( val ) units = val? [[NSString stringWithCString:val->a] retain] : nil;
				else units = nil;
				
				val = Papy3GetElement (theGroupP, papDecayCorrectionGr, &pos, &elemType );
				if( val ) decayCorrection = val? [[NSString stringWithCString:val->a] retain] : nil;
				else decayCorrection = nil;
				
				val = Papy3GetElement (theGroupP, papDecayFactorGr, &pos, &elemType );
				if( val ) decayFactor = val? atof( val->a) : 0;
				else decayFactor = 1.0;
				
				val = Papy3GetElement (theGroupP, papRadiopharmaceuticalInformationSequenceGr, &pos, &elemType );
				
				// Loop over sequence to find injected dose
				
				if ( val )
				{
					if( val->sq )
					{
						Papy_List	*dcmList = val->sq;
						while (dcmList != NULL)
						{
							if( dcmList->object->item)
							{
								SElement *gr = (SElement *)dcmList->object->item->object->group;
								if ( gr->group == 0x0018 )
								{
									val = Papy3GetElement (gr, papRadionuclideTotalDoseGr, &pos, &elemType );
									radionuclideTotalDose = val? atof( val->a) : 0.0;
									
									val = Papy3GetElement (gr, papRadiopharmaceuticalStartTimeGr, &pos, &elemType );
									if( val )
									{
										NSString		*cc = [[NSString alloc] initWithCString:val->a encoding: NSASCIIStringEncoding];
										NSCalendarDate	*cd = [[NSCalendarDate alloc] initWithString:cc calendarFormat:@"%H%M%S"];
										if( cd == nil) cd = [[NSCalendarDate alloc] initWithString:cc calendarFormat:@"%H%M"];
										
										radiopharmaceuticalStartTime = [[NSCalendarDate	dateWithString: [cd descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z"]] retain];
										
										[cd release];
										[cc release];
									}
									
									val = Papy3GetElement (gr, papRadionuclideHalfLifeGr, &pos, &elemType );
									halflife = val? atof( val->a) : 0.0;
									break;
								}
							}
							dcmList = dcmList->next;
						}
					}
					
					[self computeTotalDoseCorrected];
					
					// End of SUV required values
				}
				
				val = Papy3GetElement (theGroupP, papDetectorInformationSequenceGr, &pos, &elemType );
				
				if ( val )
				{
					if( val->sq )
					{
						Papy_List *dcmList = val->sq->object->item;
						while (dcmList != NULL)
						{
							SElement * gr = (SElement *) dcmList->object->group;
								
							if( gr)
							{
								if( gr->group == 0x0020 )
								{
									val = Papy3GetElement (gr, papImagePositionPatientGr, &nbVal, &elemType);
									if ( val )
									{
										tmp = val;
										
										originX = atof( tmp->a);
										
										if( nbVal > 1)
										{
											tmp++;
											originY = atof( tmp->a);
										}
										
										if( nbVal > 2)
										{
											tmp++;
											originZ = atof( tmp->a);
										}
										
										isOriginDefined = YES;
									}
									
									if( spacingBetweenSlices)
										originZ += frameNo * spacingBetweenSlices;
									else
										originZ += frameNo * sliceThickness;
									
									orientation[ 0] = 0;	orientation[ 1] = 0;	orientation[ 2] = 0;
									orientation[ 3] = 0;	orientation[ 4] = 0;	orientation[ 5] = 0;
									
									val = Papy3GetElement (gr, papImageOrientationPatientGr, &nbVal, &elemType);
									if ( val )
									{
										tmpVal3 = val;
										if( nbVal != 6)
										{
											NSLog(@"Orientation is NOT 6 !!!");
											if( nbVal > 6 ) nbVal = 6;
										}
										
										for ( int j = 0; j < nbVal; j++ )
										{
											orientation[ j]  = atof( tmpVal3->a);
											tmpVal3++;
										}
										
										for (int j = nbVal; j < 6; j++)
											orientation[ j] = 0;
									}
									break;
								}
							}
							dcmList = dcmList->next;
						}
					}
					
					[self computeTotalDoseCorrected];
					
					// End of SUV required values
				}
			}
			
			// End SUV			
			
			#pragma mark MR/CT multiframe		
			// Is it a new MR/CT multi-frame exam?
			
			SElement *groupOverlay = (SElement*) [self getPapyGroup: 0x5200];
			if( groupOverlay )
			{
				// ****** ****** ****** ************************************************************************
				// SHARED FRAME
				// ****** ****** ****** ************************************************************************
				
				val = Papy3GetElement (groupOverlay, papSharedFunctionalGroupsSequence, &nbVal, &elemType);
				
				// there is an element
				if ( val )
				{
					// there is a sequence
					if (val->sq )
					{
						// get a pointer to the first element of the list
						Papy_List *dcmList = val->sq->object->item;
						
						// loop through the elements of the sequence
						while (dcmList != NULL)
						{
							SElement * gr = (SElement *) dcmList->object->group;
							
							switch( gr->group)
							{
								case 0x0018:
									val3 = Papy3GetElement (gr, papMRTimingAndRelatedParametersSequence, &nbVal, &elemType);
									if (val3 != NULL && nbVal >= 1)
									{
										if (val3->sq )
										{
											Papy_List *PixelMatrixSeq = val3->sq->object->item;
											
											while (PixelMatrixSeq)
											{
												SElement * gr = (SElement *) PixelMatrixSeq->object->group;
												
												switch( gr->group)
												{
													case 0x0018: [self papyLoadGroup0x0018: gr]; break;
												}
												PixelMatrixSeq = PixelMatrixSeq->next;
											}
										}
									}
								break;
								
								case 0x0020:
									val3 = Papy3GetElement (gr, papPlaneOrientationSequence, &nbVal, &elemType);
									if (val3 != NULL && nbVal >= 1)
									{
										// there is a sequence
										if (val3->sq )
										{
											Papy_List *PixelMatrixSeq = val3->sq->object->item;
											
											// loop through the elements of the sequence
											while (PixelMatrixSeq)
											{
												SElement * gr = (SElement *) PixelMatrixSeq->object->group;
												
												switch( gr->group)
												{
													case 0x0020: [self papyLoadGroup0x0020: gr]; break;
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
											Papy_List	  *PixelMatrixSeq = val3->sq->object->item;
											
											// loop through the elements of the sequence
											while (PixelMatrixSeq != NULL)
											{
												SElement * gr = (SElement *) PixelMatrixSeq->object->group;
												
												switch( gr->group)
												{
													case 0x0018: [self papyLoadGroup0x0018: gr]; break;
													case 0x0028: [self papyLoadGroup0x0028: gr]; break;
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
										if (val3->sq)
										{
											// get a pointer to the first element of the list
											Papy_List *PixelMatrixSeq = val3->sq->object->item;
											
											// loop through the elements of the sequence
											while (PixelMatrixSeq)
											{
												SElement * gr = (SElement *) PixelMatrixSeq->object->group;
												
												switch( gr->group)
												{
													case 0x0028: [self papyLoadGroup0x0028: gr]; break;
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
				if ( val )
				{
					// there is a sequence
					if (val->sq)
					{
						// get a pointer to the first element of the list
						Papy_List *dcmList = val->sq;
						
						// loop through the elements of the sequence
						while (dcmList)
						{
							if( dcmList->object->item)
							{
								if( frameCount == imageNb-1 )
								{
									Papy_List *groupsForFrame = dcmList->object->item;
									
									while( groupsForFrame)
									{
										if( groupsForFrame->object->group)
										{
											SElement * gr = (SElement *) groupsForFrame->object->group;
											
											switch( gr->group)
											{
												case 0x0018:
													val = Papy3GetElement (gr, papMREchoSequence, &nbVal, &elemType);
													if (val != NULL && nbVal >= 1)
													{
														// there is a sequence
														if (val->sq)
														{
															// get a pointer to the first element of the list
															Papy_List *seq = val->sq->object->item;
															
															// loop through the elements of the sequence
															while (seq)
															{
																SElement * gr20 = (SElement *) seq->object->group;
																
																switch( gr20->group)
																{
																	case 0x0018: [self papyLoadGroup0x0018: gr20]; break;
																}
																
																// get the next element of the list
																seq = seq->next;
															}
														}
													}
												break;
												
												case 0x0028:
													val = Papy3GetElement (gr, papPixelMatrixSequence, &nbVal, &elemType);
													if (val != NULL && nbVal >= 1)
													{
														// there is a sequence
														if (val->sq)
														{
															// get a pointer to the first element of the list
															Papy_List *seq = val->sq->object->item;
															
															// loop through the elements of the sequence
															while (seq)
															{
																SElement * gr20 = (SElement *) seq->object->group;
																
																switch( gr20->group)
																{
																	case 0x0018: [self papyLoadGroup0x0018: gr20]; break;
																	case 0x0028: [self papyLoadGroup0x0028: gr20]; break;
																}
																
																// get the next element of the list
																seq = seq->next;
															}
														}
													}
												break;
												
												case 0x0020:
													val = Papy3GetElement (gr, papPlanePositionSequence, &nbVal, &elemType);
													if (val != NULL && nbVal >= 1)
													{
														// there is a sequence
														if (val->sq)
														{
															// get a pointer to the first element of the list
															Papy_List *seq = val->sq->object->item;
															
															// loop through the elements of the sequence
															while (seq)
															{
																SElement * gr = (SElement *) seq->object->group;
																
																switch( gr->group)
																{
																	case 0x0020: [self papyLoadGroup0x0020: gr]; break;
																	case 0x0028: [self papyLoadGroup0x0028: gr]; break;
																}
																
																// get the next element of the list
																seq = seq->next;
															}
														}
													}
													
													val = Papy3GetElement (gr, papPlaneOrientationSequence, &nbVal, &elemType);
													if (val != NULL && nbVal >= 1)
													{
														// there is a sequence
														if (val->sq)
														{
															// get a pointer to the first element of the list
															Papy_List *seq = val->sq->object->item;
															
															// loop through the elements of the sequence
															while (seq)
															{
																SElement * gr = (SElement *) seq->object->group;
																
																switch( gr->group)
																{
																	case 0x0020: [self papyLoadGroup0x0020: gr]; break;
																}
																
																// get the next element of the list
																seq = seq->next;
															}
														}
													}
												break;
											} // switch( gr->group)
										} // if( groupsForFrame->object->item)
										
										if( groupsForFrame)
										{
											// get the next element of the list
											groupsForFrame = groupsForFrame->next;
										}
									} // while groupsForFrame
									
									// STOP the loop
									dcmList = nil;
								} // right frame?
							}
							
							if( dcmList )
							{
								// get the next element of the list
								dcmList = dcmList->next;
								
								frameCount++;
							}
						} // while ...loop through the sequence
					} // if ...there is a sequence of groups
				} // if ...val is not NULL
			}
			
	#pragma mark tag group 6000		
			
			theGroupP = (SElement*) [self getPapyGroup: 0x6000];
			if( theGroupP)
			{
				val = Papy3GetElement (theGroupP, papOverlayRows6000Gr, &nbVal, &elemType);
				if ( val ) oRows	= val->us;
				
				val = Papy3GetElement (theGroupP, papOverlayColumns6000Gr, &nbVal, &elemType);
				if ( val ) oColumns	= val->us;
				
				//			val = Papy3GetElement (theGroupP, papNumberofFramesinOverlayGr, &nbVal, &elemType);
				//			if ( val ) oRows	= val->us;
				
				val = Papy3GetElement (theGroupP, papOverlayTypeGr, &nbVal, &elemType);
				if ( val ) oType	= val->a[ 0];
				
				val = Papy3GetElement (theGroupP, papOriginGr, &nbVal, &elemType);
				if ( val )
				{
					oOrigin[ 0]	= val->us;
					val++;
					oOrigin[ 1]	= val->us;
				}
				
				val = Papy3GetElement (theGroupP, papOverlayBitsAllocatedGr, &nbVal, &elemType);
				if ( val ) oBits	= val->us;
				
				val = Papy3GetElement (theGroupP, papBitPositionGr, &nbVal, &elemType);
				if ( val ) oBitPosition	= val->us;
				
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
			}
			
	#pragma mark PhilipsFactor		
			theGroupP = (SElement*) [self getPapyGroup: 0x7053];
			if( theGroupP)
			{
				val = Papy3GetElement (theGroupP, papSUVFactor7053Gr, &nbVal, &elemType);
				
				if( nbVal > 0)
				{
					if( val->a)
					{
						philipsFactor = atof( val->a);
						NSLog( @"philipsFactor = %f", philipsFactor);
					}
				}
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
			
			BOOL toBeUnlocked = YES;
			[PapyrusLock lock];
			
			if( fileNb >= 0)
			{
				DCMPix *imPix = nil;
				short *oImage = nil;
				
				imPix = self;
				ee = imageNb-1;
				
				// position the file pointer to the begining of the data set 
				err = Papy3GotoNumber (fileNb, (PapyShort) ee+1, DataSetID);
				
				// then goto group 0x7FE0 
				if ((err = Papy3GotoGroupNb (fileNb, 0x7FE0)) == 0)
				{
					// read group 0x7FE0 from the file 
					if ((err = Papy3GroupRead (fileNb, &theGroupP)) > 0) 
					{
						if( gArrCompression [fileNb] == JPEG_LOSSLESS || gArrCompression [fileNb] == JPEG_LOSSY || gArrCompression [fileNb] == JPEG2000)
						{
							if(gArrPhotoInterpret [fileNb] == RGB)
								fPlanarConf = 0;
						}
						
						if( bitsStored == 8 && bitsAllocated == 16 && gArrPhotoInterpret[ fileNb] == RGB)
							bitsAllocated = 8;
						
						// PIXEL DATA
						if( gUseJPEGColorSpace)
						{
							if( gArrCompression [fileNb] == JPEG_LOSSLESS || gArrCompression [fileNb] == JPEG_LOSSY)
							{
								if(	gArrPhotoInterpret [fileNb] == YBR_FULL  	||
								   gArrPhotoInterpret [fileNb] == YBR_FULL_422	||
								   gArrPhotoInterpret [fileNb] == YBR_RCT  	||
								   gArrPhotoInterpret [fileNb] == YBR_ICT	||
								   gArrPhotoInterpret [fileNb] == YUV_RCT	||
								   gArrPhotoInterpret [fileNb] == YBR_PARTIAL_422 ||
								   gArrPhotoInterpret [fileNb] == RGB)
									gArrPhotoInterpret [fileNb] = UNKNOWN_COLOR;
							}
						}
						
						oImage = (short*) Papy3GetPixelData (fileNb, ee+1, theGroupP, ImagePixel);
						
						[PapyrusLock unlock];
						toBeUnlocked = NO;
						
						if( oImage == nil)
						{
							NSLog(@"This is really bad..... Please send this file to rossetantoine@bluewin.ch");
							oImage = malloc( height * width * 2);
//							gArrPhotoInterpret [fileNb] = MONOCHROME2;
							
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
							if( clutRed != nil && clutGreen != nil && clutBlue != nil)
							{
								unsigned char   *bufPtr = (unsigned char*) oImage;
								unsigned short	*bufPtr16 = (unsigned short*) oImage;
								unsigned char   *tmpImage;
								int				totSize, pixelR, pixelG, pixelB, x, y;
								
								totSize = (int) ((int) height * (int) realwidth * 3L);
								tmpImage = malloc( totSize);
								
								fPlanarConf = NO;
								
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
							int				totSize, x, y, ii;
							unsigned short pixel;
							
							fPlanarConf = NO;
							
							totSize = (int) ((int) height * (int) realwidth * 3L);
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
							int				loop, totSize;
							
							isRGB = YES;
							
							// CONVERT RGB TO ARGB FOR BETTER PERFORMANCE THRU VIMAGE
							
							totSize = (int) ((int) height * (int) realwidth * 4L);
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
										int imsize = (int) height * (int) realwidth;
										int x = 0;
										
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
										int imsize = (int) height * (int) realwidth;
										int x = 0;
										
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
											*ptr++	= 255;
											*ptr++	= *bufPtr++;
											*ptr++	= *bufPtr++;
											*ptr++	= *bufPtr++;
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
							int				loop, totSize;
							
							totSize = (int) ((int) height * (int) realwidth * 2L);
							tmpImage = malloc( totSize);
							
							bufPtr = (unsigned char*) oImage;
							ptr    = tmpImage;
							
							loop = totSize/2;
							while( loop-- > 0)
							{
								*ptr++ = *bufPtr++;
							}
							
							efree3 ((void **) &oImage);
							oImage =  (short*) tmpImage;
						}
						//					else if( bitsStored != 16 && fIsSigned == YES && bitsAllocated == 16)
						//					{
						//						int totSize = (int) ((int) height * (int) realwidth * 2L);
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
						
						[PapyrusLock lock];
						// free group 7FE0 
						err = Papy3GroupFree (&theGroupP, TRUE);
						[PapyrusLock unlock];
					} // endif ...group 7FE0 read 
				}
				
		#pragma mark RGB or fPlanar
				
				//***********
				if( isRGB)
				{
					if( imPix->fExternalOwnedImage)
					{
						imPix->fImage = imPix->fExternalOwnedImage;
						memcpy( imPix->fImage, oImage, width*height*sizeof(float));
						free(oImage);
					}
					else imPix->fImage = (float*) oImage;
					oImage = nil;
					
					if( oData && gDisplayDICOMOverlays)
					{
						unsigned char	*rgbData = (unsigned char*) imPix->fImage;
						int				y, x;
						
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
						unsigned int	*usint = (unsigned int*) oImage;
						int				*sint = (int*) oImage;
						float			*tDestF;
						
						if( imPix->fExternalOwnedImage)
						{
							tDestF = imPix->fImage = imPix->fExternalOwnedImage;
						}
						else
						{
							tDestF = imPix->fImage = malloc(width*height*sizeof(float) + 100);
						}
						
						if( fIsSigned)
						{
							int x = height * width;
							while( x-->0)
							{
								*tDestF++ = ((float) (*sint++)) * slope + offset;
							}
						}
						else
						{
							int x = height * width;
							while( x-->0)
							{
								*tDestF++ = ((float) (*usint++)) * slope + offset;
							}
						}
						
						free(oImage);
						oImage = nil;
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
							
							if( VOILUT_number != 0 && VOILUT_depth != 0 && VOILUT_table != nil)
							{
								[self setVOILUT:VOILUT_first number:VOILUT_number depth:VOILUT_depth table:VOILUT_table image:(unsigned short*) oImage isSigned: fIsSigned];
								
								free( VOILUT_table);
								VOILUT_table = nil;
							}
							
							if( imPix->fExternalOwnedImage)
							{
								imPix->fImage = imPix->fExternalOwnedImage;
							}
							else
							{
								imPix->fImage = malloc(width*height*sizeof(float) + 100);
							}
							
							dstf.data = imPix->fImage;
							
							if( fIsSigned)
								vImageConvert_16SToF( &src16, &dstf, offset, slope, 0);
							else
								vImageConvert_16UToF( &src16, &dstf, offset, slope, 0);
							
							if( inverseVal)
							{
								float neg = -1;
								vDSP_vsmul( fImage, 1, &neg, fImage, 1, height * width);
							}
							
							free(oImage);
						}
						oImage = nil;
					}
					
					if( oData && gDisplayDICOMOverlays)
					{
						int			y, x;
						
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
				
				wl = 0;
				ww = 0; //Computed later, only if needed
				
				if( isRGB)
				{
					savedWL = 0;
					savedWW = 0;
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
			
			if( toBeUnlocked)
				[PapyrusLock unlock];
			
			#ifdef OSIRIX_VIEWER
			[self loadCustomImageAnnotationsPapyLink: fileNb DCMLink:nil];
			#endif
			
			if( fabs(pixelSpacingX) / fabs(pixelSpacingY) > 10000 || fabs(pixelSpacingX) / fabs(pixelSpacingY) < 0.0001)
			{
				pixelSpacingX = 1;
				pixelSpacingY = 1;
			}
			
			if( pixelSpacingX < 0) pixelSpacingX = -pixelSpacingX;
			if( pixelSpacingY < 0) pixelSpacingY = -pixelSpacingY;
			if( pixelSpacingY != 0 && pixelSpacingX != 0) pixelRatio = pixelSpacingY / pixelSpacingX;
			
			returnValue =  YES;
		}
		else NSLog( @"[self getPapyGroup: 0x0028] failed");
	}
	else NSLog( @"[self getPapyGroup: 0] failed");
	
	return returnValue;
}

- (BOOL) isDICOMFile:(NSString *) file
{
	BOOL            readable = YES;
	
	if( imageObj)
	{
		if( [[imageObj valueForKey:@"fileType"] hasPrefix:@"DICOM"] == NO) readable = NO;
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
	
	realwidth = [TIFFRep pixelsWide];
	width = realwidth/2;
	width *= 2;
	
	unsigned char *srcImage = [TIFFRep bitmapData];
	unsigned char *argbImage = nil, *srcPtr = nil, *tmpPtr = nil;
	
	int totSize = height * width * 4;
	if( fExternalOwnedImage)
	{
		argbImage =	(unsigned char*) fExternalOwnedImage;
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
			srcPtr = srcImage + y*[TIFFRep bytesPerRow];
			
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
			srcPtr = srcImage + y*[TIFFRep bytesPerRow];
			
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
			srcPtr = srcImage + y*[TIFFRep bytesPerRow];
			
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
			srcPtr = srcImage + y*[TIFFRep bytesPerRow];
			
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
//	rowBytes = width * 4;
	isRGB = YES;
	
	[TIFFRep release];
	
}

- (void) getFrameFromMovie:(NSString*) extension
{
	
	if( [extension isEqualToString:@"mov"] == YES ||
	   [extension isEqualToString:@"mpg"] == YES ||
	   [extension isEqualToString:@"mpeg"] == YES ||
	   [extension isEqualToString:@"avi"] == YES)
	{
		if( quicktimeThreadLock == nil) quicktimeThreadLock = [[NSLock alloc] init];
		
		[quicktimeThreadLock lock];
		
		[QTMovie enterQTKitOnThreadDisablingThreadSafetyProtection];
		
		NSError	*error = nil;
		
		QTMovie *movie = [[QTMovie alloc] initWithFile:srcFile error: &error];
		
		if( movie)
		{
			[movie attachToCurrentThread];
			
			int curFrame = 0;
			[movie gotoBeginning];
			
			QTTime previousTime = [movie currentTime];
			
			curFrame = 0;
			
			while( curFrame != frameNo)
			{
				previousTime = [movie currentTime];
				curFrame++;
				[movie stepForward];
				
				if( QTTimeCompare( previousTime, [movie currentTime]) != NSOrderedAscending) curFrame = frameNo;
			}
			
			[self getDataFromNSImage: [movie currentFrameImage]];
			
			[movie release];
		}
		else NSLog( @"movie == nil, %@", [error description]);
		
		[QTMovie exitQTKitOnThread];
		
		[quicktimeThreadLock unlock];
	}
}

- (void) CheckLoadIn
{
	BOOL USECUSTOMTIFF = NO;
	
	if( fImage == nil)
	{
		BOOL success = NO;
		short *oImage = nil;
		
		needToCompute8bitRepresentation = YES;
		
		if( runOsiriXInProtectedMode) return;
		
		if( srcFile == nil) return;
		
		if( isBonjour)
		{
#ifdef OSIRIX_VIEWER
			// LOAD THE FILE FROM BONJOUR SHARED DATABASE
			
			if( imageObj == nil) NSLog( @"We need imageObj for Bonjour loading");
			
			[srcFile release];
			srcFile = nil;
			srcFile = [[BrowserController currentBrowser] getLocalDCMPath: imageObj :0];
			[srcFile retain];
			
			if( srcFile == nil)
			{
				return;
			}
#endif
		}
		
		if( [self isDICOMFile: srcFile])
		{
			if (DEBUG)
				NSLog(@"checkLoad isDICOM: %@", srcFile);
			
			// PLEASE, KEEP BOTH FUNCTIONS FOR TESTING PURPOSE. THANKS
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			@try
			{
				if( gUSEPAPYRUSDCMPIX)
				{
					success = [self loadDICOMPapyrus];
					
					//only try again if is strict DICOM
					if (success == NO && [DCMObject isDICOM:[NSData dataWithContentsOfFile:srcFile]])
					{
						NSLog( @"DICOM File opening: Papyrus Toolkit failed. Try DCMFramework");
						success = [self loadDICOMDCMFramework];
					}
				}
				else
				{
					success = [self loadDICOMDCMFramework];
					
					if (success == NO && [DCMObject isDICOM:[NSData dataWithContentsOfFile:srcFile]])
						success = [self loadDICOMPapyrus];
				}
				
				if( [[imageObj valueForKey: @"numberOfFrames"] intValue] <= 1)
					[self clearCachedPapyGroups];
			}
			
			@catch ( NSException *e)
			{
				NSLog( @"CheckLoadIn Exception");
				NSLog( [e description]);
				NSLog( @"Exception for this file: %@", srcFile);
				success = NO;
			}
			
			[self checkSUV];
			
			[pool release];
		}
		
		if( success == NO)	// Is it a NON-DICOM IMAGE ??
		{
			int				realheight;
			PapyULong		i;
			
			NSImage		*otherImage = nil;
			NSString	*extension = [[srcFile pathExtension] lowercaseString];
			
#ifdef OSIRIX_VIEWER
			id fileFormatBundle;
			if (fileFormatBundle = [[PluginManager fileFormatPlugins] objectForKey:[srcFile pathExtension]])
			{
				PluginFileFormatDecoder *decoder = [[[fileFormatBundle principalClass] alloc] init];
				fImage = [decoder checkLoadAtPath:srcFile];
				//NSLog(@"decoder width %d", [decoder width]);
				width = [[decoder width] intValue];
				//width = 832;
				//NSLog(@"width %d : %d", width, [decoder width]);
				height = [[decoder height] intValue];
				//NSLog(@"height %d : %d", height, [decoder height]);
				isRGB = [decoder isRGB];
//					rowBytes = [[decoder rowBytes] intValue];				
				[decoder release];					
				
			}
			else
#endif
				
				if( [extension isEqualToString:@"zip"] == YES)  // ZIP
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
					
					long totSize;
					totSize = height * width * 4;
					
					unsigned char *argbImage;
					if( fExternalOwnedImage)
					{
						argbImage =	(unsigned char*) fExternalOwnedImage;
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
						srcPtr = srcImage + y*[TIFFRep bytesPerRow];
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
//						rowBytes = width * 4;
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
				else if( (( [extension isEqualToString:@"hdr"] == YES) && 
						  ([[NSFileManager defaultManager] fileExistsAtPath:[[srcFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] == YES)) ||
						( [extension isEqualToString:@"nii"] == YES))
				{
					// NIfTI support developed by Zack Mahdavi at the Center for Neurological Imaging, a division of Harvard Medical School
					// For more information: http://cni.bwh.harvard.edu/
					// For questions or suggestions regarding NIfTI integration in OsiriX, please contact zmahdavi@bwh.harvard.edu
					long			totSize;
					struct nifti_1_header  *NIfTI;
					nifti_image *nifti_imagedata;
					NSData			*fileData;
					BOOL			swapByteOrder = NO;
					
					NIfTI = (nifti_1_header *) nifti_read_header([srcFile UTF8String], nil, 0);
					
					// Verify that this file should be treated as a NIfTI file.  If magic is not set to anything, we must assume it is analyze.
					if( (NIfTI->magic[0] == 'n')                           &&
					   (NIfTI->magic[1] == 'i' || NIfTI->magic[1] == '+')   &&
					   (NIfTI->magic[2] == '1')                           &&
					   (NIfTI->magic[3] == '\0') )
					{
						width = NIfTI->dim[ 1];
						realwidth = width;
						width /= 2;
						width *= 2;
						
						height = NIfTI->dim[ 2];
						realheight = height;
						height /= 2;
						height *= 2;
						
						pixelSpacingX = NIfTI->pixdim[ 1];
						pixelSpacingY = NIfTI->pixdim[ 2];
						sliceThickness = sliceInterval = NIfTI->pixdim[ 3];
						
						totSize = realheight * realwidth * 2;
						//NSLog(@"totSize:  %d", totSize);
						oImage = malloc( totSize);
						
						// Transformation matrix
						short qform_code = NIfTI->qform_code;
						short sform_code = NIfTI->sform_code;
						
						// Read img file or read nii file after vox_offset
						nifti_imagedata = nifti_image_read([srcFile UTF8String], 1);
						if( (NIfTI->magic[0] == 'n')    &&
						   (NIfTI->magic[1] == 'i')	&&
						   (NIfTI->magic[2] == '1')    &&
						   (NIfTI->magic[3] == '\0') )
						{
							// This is a "two file" nifti file.  Image file is separated from header.
							fileData = [[NSData alloc] initWithContentsOfFile: [[srcFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]];
						}
						else
						{
							// Header and image file are together.  
							fileData = [[NSData alloc] initWithBytesNoCopy:nifti_imagedata->data length:(nifti_imagedata->nvox * nifti_imagedata->nbyper)];
						}
						
						// This "datatype" portion is taken from the analyze code.  
						short datatype = NIfTI->datatype;
						
						switch( datatype)
						{
							case 2:
							{
								unsigned char   *bufPtr;
								short			*ptr;
								long			loop;
								
								bufPtr = (unsigned char*) [fileData bytes]+ frameNo*(realheight * realwidth);
								ptr    = oImage;
								
								loop = realheight * realwidth;
								while( loop-- > 0)
								{
									*ptr++ = *bufPtr++;
								}
								//NSLog(@"Loop is done for frame number %i \n", (int) frameNo);
							}
							break;
								
							case 4:
								memcpy( oImage, [fileData bytes] + frameNo*(realheight * realwidth * 2), realheight * realwidth * 2);
								if( swapByteOrder)
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
									short			*ptr;
									long			loop;
									
									bufPtr = (unsigned int*) [fileData bytes];
									bufPtr += frameNo * (realheight * realwidth);
									ptr    = oImage;
									
									loop = realheight * realwidth;
									while( loop-- > 0)
									{
										
										if( swapByteOrder)  *ptr++ = Endian32_Swap( *bufPtr++);
										else *ptr++ = *bufPtr++;
									}
								}
							break; 
								
							case 16:
								if( fExternalOwnedImage)
									fImage = fExternalOwnedImage;
								else
									fImage = malloc( (width+1) * (height+1) * sizeof(float) + 100);
								
								if( [fileData length] < realheight * realwidth * sizeof(float))
									NSLog( @"****** [fileData length] < realheight * realwidth * sizeof(float)");
								
								for( i = 0; i < height;i++)
									memcpy( fImage + i * width, [fileData bytes]+ frameNo * (realheight * realwidth)*sizeof(float) + i*realwidth*sizeof(float), width * sizeof(float));
								
								free(oImage);
								oImage = nil;
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
							
							if( fExternalOwnedImage)
							{
								fImage = fExternalOwnedImage;
							}
							else
							{
								fImage = malloc(width*height*sizeof(float) + 100);
							}
							
							dstf.data = fImage;
							
							vImageConvert_16SToF( &src16, &dstf, 0, 1, 0);
							
							free(oImage);
							oImage = nil;
						}
						
						// Set up origins for nifti file.
						//   - This portion tells OsiriX which view is active for the image.  This allows OsiriX to determine whether the 
						//	   image is axial, sagittal, or coronal.  
						// Grab orientations for i, j, and k axes based on either qform or sform matrices.
						int icod, jcod, kcod;
						if(qform_code > 0)
						{
							nifti_mat44_to_orientation(nifti_imagedata->qto_xyz, &icod, &jcod, &kcod);
						}
						else if(sform_code > 0)
						{
							nifti_mat44_to_orientation(nifti_imagedata->sto_xyz, &icod, &jcod, &kcod);
						}	
						
						if(jcod == NIFTI_A2P || jcod == NIFTI_P2A)
						{
							// This is axial by default, so set originZ.
							originX = 0;
							originY = 0;
							originZ = frameNo * pixelSpacingX;
							
							isOriginDefined = YES;
						}
						else if(jcod == NIFTI_S2I || jcod == NIFTI_I2S)
						{
							if(icod == NIFTI_A2P || icod == NIFTI_P2A)
							{
								// This is sagittal by default, so set originX.
								originX = frameNo * pixelSpacingX;
								originY = 0;
								originZ = 0;
								
								isOriginDefined = YES;
							}
							else if(icod == NIFTI_R2L || icod == NIFTI_L2R)
							{
								// This is coronal by default, so set originY.
								originX = 0;
								originY = frameNo * pixelSpacingX;
								originZ = 0;
								
								isOriginDefined = YES;
							}						
						}
						
						
						
						// Adjust orientation of nifti file
						BOOL flipI = NO;
						BOOL flipJ = NO;
						int shiftNum = 0;
						
						// Grab orientations for i, j, and k axes based on either qform or sform matrices.
						if(qform_code > 0)
						{
							nifti_mat44_to_orientation(nifti_imagedata->qto_xyz, &icod, &jcod, &kcod);
						}
						else if(sform_code > 0)
						{
							nifti_mat44_to_orientation(nifti_imagedata->sto_xyz, &icod, &jcod, &kcod);
						}	
						
						
						if(icod != NIFTI_L2R && icod != NIFTI_R2L)
						{
							// Must shift the orientation matrix so that icod, jcod, and kcod are 
							// aligned with the orientation matrix.
							if(icod == NIFTI_A2P || icod == NIFTI_P2A)
							{
								shiftNum = 2;
							}							
							else if(icod == NIFTI_S2I || icod == NIFTI_I2S)
							{
								shiftNum = 1;
							}
						}
						else
						{
							// verify that jcod is AP or PA
							if(jcod != NIFTI_A2P && jcod != NIFTI_P2A)
							{
								// this means that jcod is S2I or I2S.
								// So set orient[3,4,5] to orient[6,7,8]
								float	orient[ 9]; 
								for( int i = 0 ; i < 9; i ++) orient[ i] = orientation[ i];
								
								orient[ 3] = orient[ 6];
								orient[ 4] = orient[ 7];
								orient[ 5] = orient[ 8];
								
								[self setOrientation: orient];						
							}
						}
						
						
						if(shiftNum > 0)
						{
							// Shift number of times specified.
							// orient[3,4,5] takes on orient[0,1,2], which takes on orient[6,7,8]
							// orient[6,7,8] is recalculated after setOrientation is called.
							while(shiftNum > 0)
							{
								// Shift.
								float	orient[ 9];
								int t6, t7, t8;
								
								for( int i = 0 ; i < 9; i ++) orient[ i] = orientation[ i];
								
								t6 = orient[ 6];
								t7 = orient[ 7];
								t8 = orient[ 8];
								
								orient[ 3] = orient[ 0];
								orient[ 4] = orient[ 1];
								orient[ 5] = orient[ 2];		
								
								orient[ 0] = t6;
								orient[ 1] = t7;
								orient[ 2] = t8;	
								
								[self setOrientation: orient];
								
								shiftNum--;
							}
						} 
						
						if(icod == NIFTI_L2R)
						{
							// Need to flip horizontally.
							flipI = YES;
						}
						else if(icod == NIFTI_P2A)
						{
							// Need to flip horizontally.
							flipI = YES;
						}
						else if(icod == NIFTI_S2I)
						{
							// Need to flip vertically
							flipI = YES;
						}
						
						if(jcod == NIFTI_P2A)
						{
							// Need to flip vertically.
							flipJ = YES;
						}
						else if(jcod == NIFTI_L2R)
						{
							// Need to flip vertically.
							flipJ = YES;
						}
						else if(jcod == NIFTI_S2I)
						{
							// Need to flip vertically
							flipJ = YES;
						}
						
						if(flipI)
						{
							// Flip orientation horizontally
							float	orient[ 9];
							for( int i = 0 ; i < 9; i ++) orient[ i] = orientation[ i];
							
							orient[ 0] *= -1;
							orient[ 1] *= -1;
							orient[ 2] *= -1;
							[self setOrientation: orient];
							sliceInterval = 0;
							
							float	o[3];
							o[ 0] = originX;			o[ 1] = originY;			o[ 2] = originZ;
							o[ 0] -= width * pixelSpacingX;
							[self setOrigin: o];
						}
						
						if(flipJ)
						{
							// Flip orientation vertically
							float	orient[ 9];
							
							for( int i = 0 ; i < 9; i ++) orient[ i] = orientation[ i];
							
							orient[ 3] *= -1;
							orient[ 4] *= -1;
							orient[ 5] *= -1;
							[self setOrientation: orient];
							sliceInterval = 0;
							
							float	o[3];
							o[ 0] = originX;			o[ 1] = originY;			o[ 2] = originZ;
							o[ 1] -=  height * pixelSpacingY;
							[self setOrigin: o];
							
						}
					}
					else if( [extension isEqualToString:@"hdr"] == YES) // 'old' ANALYZE
					{
						if ([[NSFileManager defaultManager] fileExistsAtPath:[[srcFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] == YES)
						{
							NSData		*file = [NSData dataWithContentsOfFile: srcFile];
							
							if( [file length] == 348)
							{
								long			totSize;
								struct dsr*		Analyze;
								NSData			*fileData;
								BOOL			swapByteOrder = NO;
								
								Analyze = (struct dsr*) [file bytes];
								
								short endian = Analyze->dime.dim[ 0];		// dim[0] 
								if ((endian < 0) || (endian > 15)) 
								{
									swapByteOrder = YES;
								}
								
								height = Analyze->dime.dim[ 2];
								if( swapByteOrder) height = Endian16_Swap( height);
								realheight = height;
								height /= 2;
								height *= 2;
								width = Analyze->dime.dim[ 1];
								if( swapByteOrder) width = Endian16_Swap( width);
								realwidth = width;
								width /= 2;
								width *= 2;
								
								float pX = Analyze->dime.pixdim[ 1];
								if( swapByteOrder) SwitchFloat( &pX);
								pixelSpacingX = pX;
								
								pX = Analyze->dime.pixdim[ 2];
								if( swapByteOrder) SwitchFloat( &pX);
								pixelSpacingY = pX;
								
								pX = Analyze->dime.pixdim[ 3];
								if( swapByteOrder) SwitchFloat( &pX);
								sliceThickness = pX;
								sliceInterval = pX;
								
								totSize = realheight * realwidth * 2;
								oImage = malloc( totSize);
								
								fileData = [[NSData alloc] initWithContentsOfFile: [[srcFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]];
								
								short datatype = Analyze->dime.datatype;
								if( swapByteOrder) datatype = Endian16_Swap( datatype);
								
								switch( datatype)
								{
									case 2:
									{
										unsigned char   *bufPtr;
										short			*ptr;
										long			loop;
										
										bufPtr = (unsigned char*) [fileData bytes]+ frameNo*(realheight * realwidth);
										ptr    = oImage;
										
										loop = realheight * realwidth;
										while( loop-- > 0)
										{
											*ptr++ = *bufPtr++;
										}
									}
										break;
										
									case 4:
										memcpy( oImage, [fileData bytes] + frameNo*(realheight * realwidth * 2), realheight * realwidth * 2);
										if( swapByteOrder)
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
											short			*ptr;
											long			loop;
											
											bufPtr = (unsigned int*) [fileData bytes];
											bufPtr += frameNo * (realheight * realwidth);
											ptr    = oImage;
											
											loop = realheight * realwidth;
											while( loop-- > 0)
											{
												
												if( swapByteOrder)  *ptr++ = Endian32_Swap( *bufPtr++);
												else *ptr++ = *bufPtr++;
											}
										}
										break; 
										
										case 16:
										if( fExternalOwnedImage)
										{
											fImage = fExternalOwnedImage;
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
										oImage = nil;
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
									
									if( fExternalOwnedImage)
									{
										fImage = fExternalOwnedImage;
									}
									else
									{
										fImage = malloc(width*height*sizeof(float) + 100);
									}
									
									dstf.data = fImage;
									
									vImageConvert_16SToF( &src16, &dstf, 0, 1, 0);
									
									free(oImage);
									oImage = nil;
								}
							}
						}
					}
					
					free( NIfTI);
					NIfTI = nil;
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
			
				else if( [extension isEqualToString:@"tiff"] == YES ||
							[extension isEqualToString:@"stk"] == YES ||
							[extension isEqualToString:@"tif"] == YES)
				{
#ifndef STATIC_DICOM_LIB
					TIFF* tif = TIFFOpen([srcFile UTF8String], "r");
					if( tif )
					{
						short   bpp, count, tifspp;
						
						TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bpp);
						TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &tifspp);
						
						if( bpp == 16 || bpp == 32 || bpp == 8)
						{
							if( tifspp == 1)
								USECUSTOMTIFF = YES;
						}
						
						count = 1;
						while (TIFFReadDirectory(tif))
							count++;
						
						if( count != 1) USECUSTOMTIFF = YES;
						
						TIFFClose(tif);
					}
#endif
					
					if( USECUSTOMTIFF == NO )
					{
						otherImage = [[NSImage alloc] initWithContentsOfFile:srcFile];
					}
				}
			
			if( otherImage != nil || USECUSTOMTIFF == YES)
			{
				if( USECUSTOMTIFF) // Is it a 16/32-bit TIFF not supported by Apple???
				{
					[self LoadTiff:frameNo];
				}
				else
				{
					[otherImage setBackgroundColor: [NSColor whiteColor]];
					
					if( [extension isEqualToString:@"pdf"] )
					{
						NSSize			newSize = [otherImage size];
						
						newSize.width *= 1.5;		// Increase PDF resolution to 72 * 1.5 DPI !
						newSize.height *= 1.5;		// KEEP THIS VALUE IN SYNC WITH DICOMFILE.M
						
						[otherImage setScalesWhenResized:YES];
						[otherImage setSize: newSize];
						
						id tempID = [otherImage bestRepresentationForDevice:nil];
						
						if( [tempID isKindOfClass: [NSPDFImageRep class]] )
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
				NSMovie *movie = nil;
				
				if( [extension isEqualToString:@"mov"] == YES ||
				   [extension isEqualToString:@"mpg"] == YES ||
				   [extension isEqualToString:@"mpeg"] == YES ||
				   [extension isEqualToString:@"avi"] == YES)
				{
					movie = [[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:srcFile] byReference:NO];
				}
				
				if( movie )
				{
					Movie			mov = [movie QTMovie];
					TimeValue		aTime = 0;
					OSType			mediatype = 'eyes';
					long			curFrame;
					Rect			tempRect;
					GWorldPtr		ftheGWorld = nil;
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
					
					SetMovieGWorld (mov, ftheGWorld, nil);
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
													 nil);
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
					long			totSize;
					
					height = tempRect.bottom;
					height /= 2;
					height *= 2;
					realwidth = tempRect.right;
					width = realwidth/2;
					width *= 2;
//						rowBytes = GetPixRowBytes(pixMapHandle);
					oImage = nil;
					srcImage = (unsigned char*) pixBaseAddr;
					
					totSize = height * width * 4;
					
					if ( fExternalOwnedImage )
					{
						argbImage =	(unsigned char*) fExternalOwnedImage;
					}
					else
					{
						argbImage = malloc( totSize);
					}
					
					tmpPtr = argbImage;
					for( long y = 0 ; y < height; y++ )
					{
						srcPtr = srcImage + y*GetPixRowBytes(pixMapHandle);
						memcpy( tmpPtr, srcPtr, width*4);
						tmpPtr += width*4;
					}
					
					UnlockPixels (pixMapHandle);
					
//						rowBytes = width * 4;
					fImage = (float*) argbImage;
					isRGB = YES;
					
					DisposeGWorld( ftheGWorld);
					
					[movie release];
				}
#else
				[self getFrameFromMovie: extension];
#endif
			}
			
#ifdef OSIRIX_VIEWER
			[self loadCustomImageAnnotationsPapyLink:-1 DCMLink:nil];
#endif
		}
		
		if( fImage == nil )
		{
			NSLog(@"not able to load the image...");
			
			if( fExternalOwnedImage )
			{
				fImage = fExternalOwnedImage;
			}
			else
			{
				fImage = malloc( 128 * 128 * 4);
			}
			
			height = 128;
			width = 128;
//				rowBytes = width*4;
			oImage = nil;
			isRGB = NO;
			
			for( long i = 0; i < 128*128; i++ ) fImage[ i ] = i;
		}
		
		if( isRGB)	// COMPUTE ALPHA MASK = ALPHA = R+G+B/3
		{
			unsigned char*	argbPtr = (unsigned char*) fImage;
			long			ss = width * height;
			
			while( ss-->0 )	{
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
	
	@try
	{
		[self CheckLoadIn];
	}
	@catch (NSException *ne)
	{
		NSLog( @"CheckLoad Exception");
		NSLog( @"Exception : %@", [ne description]);
		NSLog( @"Exception for this file: %@", srcFile);
	}
	
	[checking unlock];
}

- (void)setBaseAddr: (char*) ptr
{
	if( baseAddr) free( baseAddr);
	baseAddr = ptr;
}

- (char*)baseAddr
{
    [self CheckLoad];
	
	if( baseAddr == nil)
		[self allocate8bitRepresentation];
    
	if( needToCompute8bitRepresentation)
		[self compute8bitRepresentation];
	
	return baseAddr;
}

- (void)setLUT12baseAddr: (unsigned char*) ptr
{
	if( ptr != LUT12baseAddr)
	{
		if(LUT12baseAddr) free(LUT12baseAddr);
		LUT12baseAddr = ptr;
	}
}

- (unsigned char*)LUT12baseAddr;
{
    [self CheckLoad];
	if( LUT12baseAddr == nil )
		[self allocate8bitRepresentation];
    return LUT12baseAddr;
}

# pragma mark-

+ (NSPoint) rotatePoint:(NSPoint)pt aroundPoint:(NSPoint)c angle:(float)a;
{
	NSPoint rot;
	
	pt.x -= c.x;
	pt.y -= c.y;
	
	rot.x = cos(a)*pt.x - sin(a)*pt.y;
	rot.y = sin(a)*pt.x + cos(a)*pt.y;

	rot.x += c.x;
	rot.y += c.y;
	
	return rot;
}

- (void) drawImage: (vImage_Buffer*) src inImage: (vImage_Buffer*) dst offset:(NSPoint) oo background:(float) b transparency: (BOOL) t
{
	if( t == NO)
	{
		float *f = (float*) dst->data;
		int i = dst->height * dst->width;
		while( i-->0) *f++ = b;
	}
	
	int ox = oo.x;
	int oy = oo.y;
	
	NSRect dstRect = NSMakeRect( 0, 0, dst->width, dst->height);
	NSRect srcRect = NSMakeRect( ox, oy, src->width, src->height);
	
	NSRect unionRect = NSIntersectionRect( dstRect, srcRect);
	
	int y1 = unionRect.origin.y;
	int y2 = unionRect.origin.y+unionRect.size.height;
	int x1 = unionRect.origin.x;
	int x2 = unionRect.origin.x+unionRect.size.width;
	
	int lineBytes = (x2-x1)*sizeof( float);
	
	float *srcData = (float*) src->data;
	float *dstData = (float*) dst->data;
	
	if( t == NO)
	{
		for( int y = y1; y < y2; y++)
		{
			memcpy( dstData + (y*dst->width + x1), srcData +((y-oy)*src->width + (x1-ox)), lineBytes);
		}
	}
	else
	{
		for( int y = y1; y < y2; y++)
		{
			for( int x = x1; x < x2; x++)
			{
				 float *d = dstData + (y*dst->width + x);
				 float *s = srcData +((y-oy)*src->width + (x-ox));
				 
				 int diff = *s - b;
				 
				 if( diff > 900)
					*d = *s;
			}
		}
	}
}

- (void) drawImage: (vImage_Buffer*) src inImage: (vImage_Buffer*) dst offset:(NSPoint) oo background:(float) b
{
	return [self drawImage:  src inImage:  dst offset: oo background: b transparency:  NO];
}

-(DCMPix*) mergeWithDCMPix:(DCMPix*) o offset:(NSPoint) oo
{
	if( o == nil) return nil;
	if( [o isRGB]) return nil;
	if( [self isRGB]) return nil;
	
	int ox = oo.x;
	int oy = oo.y;
	
	NSRect dstRect = NSMakeRect( 0, 0, [self pwidth], [self pheight]);
	
	NSPoint center = NSMakePoint( [self pwidth]/2 - [o pwidth]/2, [self pheight]/2 - [o pheight]/2);
	NSRect srcRect = NSMakeRect( ox + center.x, oy + center.y, [o pwidth], [o pheight]);
	
	NSRect unionRect = NSUnionRect( dstRect, srcRect);
	
	vImage_Buffer src;
	vImage_Buffer dst;
	
	dst.height = unionRect.size.height;
	dst.width = unionRect.size.width;
	dst.rowBytes = dst.width * 4;
	dst.data = malloc( dst.height * dst.rowBytes);
	
	// Draw first image
	src.height = [self pheight];
	src.width = [self pwidth];
	src.rowBytes = [self pwidth]*4;
	src.data = [self fImage];
		
	[self drawImage:&src inImage:&dst offset:NSMakePoint( -unionRect.origin.x, -unionRect.origin.y) background: [self minValueOfSeries]-1024 transparency: NO];
	
	// Adapt the window level
	
	if( [self wl] != [o wl])
	{
		long i = dst.height * dst.width;
		float *ptr = dst.data;
		float diffww = [o ww]/[self ww];
		float diffwl = ([o wl] - [self wl])*diffww;
		
		while (i-- > 0)
		{
			*ptr  += diffwl;
			*ptr++ *= diffww;
		}
	}

	src.height = [o pheight];
	src.width = [o pwidth];
	src.rowBytes = [o pwidth]*4;
	src.data = [o fImage];
	
	[self drawImage:&src inImage:&dst offset:NSMakePoint( ox+center.x-unionRect.origin.x, oy+center.y-unionRect.origin.y) background: [self minValueOfSeries]-1024 transparency: YES];
	
	// Create final DCMPix
	DCMPix *newPix = [[self copy] autorelease];
	
	[newPix freefImageWhenDone: NO];
	[newPix setfImage: dst.data];
	[newPix freefImageWhenDone: YES];
	
	newPix.pheight = dst.height;
	newPix.pwidth = dst.width;
	
	// New origin
	float or[ 3];
	[newPix convertPixX: unionRect.origin.x pixY: unionRect.origin.y toDICOMCoords: or pixelCenter: NO];
	[newPix setOrigin: or];

	return newPix;
}

- (void) orientationCorrected:(float*) correctedOrientation rotation:(float) rotation xFlipped: (BOOL) xFlipped yFlipped: (BOOL) yFlipped
{
	#ifdef OSIRIX_VIEWER
	float	o[ 9];
	float   yRot = -1, xRot = -1;
	float	rot = rotation;
	
	[self orientation: o];
	
	if( yFlipped && xFlipped)
	{
		rot = rot + 180;
	}
	else
	{
		if( yFlipped )
		{
			xRot *= -1;
			yRot *= -1;
			
			o[ 3] *= -1;
			o[ 4] *= -1;
			o[ 5] *= -1;
		}
		
		if( xFlipped )
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

	memcpy( correctedOrientation, o, sizeof o );
	#endif
}

- (NSRect) usefulRectWithRotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF
{
	int newHeight;
	int newWidth;
	
	float rot = r*deg2rad;
	
	// Apply scale
	newWidth = [self pwidth] * scale;
	newHeight = [self pheight] * scale * pixelRatio;
	
	// Apply rotation
	NSPoint pt[ 4];
	NSPoint centerPt = NSMakePoint( newWidth/2., newHeight/2.);
	NSPoint zeroPt = NSMakePoint( 0, 0);
	
	pt[ 0] = [DCMPix rotatePoint: zeroPt aroundPoint: centerPt angle: rot];
	pt[ 1] = [DCMPix rotatePoint: NSMakePoint( zeroPt.x+newWidth, zeroPt.y) aroundPoint: centerPt angle: rot];
	pt[ 2] = [DCMPix rotatePoint: NSMakePoint( zeroPt.x+newWidth, zeroPt.y+newHeight) aroundPoint: centerPt angle: rot];
	pt[ 3] = [DCMPix rotatePoint: NSMakePoint( zeroPt.x, zeroPt.y+newHeight) aroundPoint: centerPt angle: rot];
	
	float minX, maxX, minY, maxY;
	
	minX = maxX = pt[ 0].x;
	minY = maxY = pt[ 0].y;
	
	for( int i = 0; i < 4; i++)
	{
		minX = minX > pt[ i].x ? pt[ i].x : minX;
		maxX = maxX < pt[ i].x ? pt[ i].x : maxX;
		minY = minY > pt[ i].y ? pt[ i].y : minY;
		maxY = maxY < pt[ i].y ? pt[ i].y : maxY;
	}
	
	NSRect newRect = NSMakeRect( minX, minY, maxX - minX, maxY - minY);
	
	return newRect;
}

- (DCMPix*) renderWithRotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF
{
	return [self renderWithRotation: r scale: scale xFlipped: xF yFlipped: yF backgroundOffset: -1024];
}

- (DCMPix*) renderWithRotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF backgroundOffset: (float) bgO
{
	if( [self isRGB]) return nil;
	
	NSRect dstRect = [self usefulRectWithRotation: r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF];
	
	float rot = r*deg2rad;
	int newHeight;
	int newWidth;
	
	// Apply scale
	newWidth = [self pwidth] * scale;
	newHeight = [self pheight] * scale * pixelRatio;
	NSPoint centerPt = NSMakePoint( newWidth/2., newHeight/2.);
	
	int newW = (dstRect.size.width);
	int newH = (dstRect.size.height);
	
	vImage_Buffer src;
	vImage_Buffer dst;
	
	if( [self isRGB] == NO)
	{
		src.height = [self pheight];
		src.width = [self pwidth];
		src.rowBytes = [self pwidth]*4;
		src.data = [self computefImage];

		if( [self DCMPixShutterOnOff] && [self DCMPixShutterRectWidth] > 0 && [self DCMPixShutterRectHeight] > 0)
		{
			if( [self DCMPixShutterRectOriginY] < 0) self.DCMPixShutterRectOriginY = 0;
			if( [self DCMPixShutterRectOriginX] < 0) self.DCMPixShutterRectOriginX = 0;
			
			if( [self DCMPixShutterRectWidth] + [self DCMPixShutterRectOriginX] > [self pwidth]) self.DCMPixShutterRectWidth = [self pwidth] - [self DCMPixShutterRectOriginX];
			if( [self DCMPixShutterRectHeight] + [self DCMPixShutterRectOriginY] > [self pheight]) self.DCMPixShutterRectHeight = [self pheight] - [self DCMPixShutterRectOriginY];
			
			float *tempMem = malloc( [self pwidth] * [self pheight] * sizeof(float));
			
			if( tempMem)
			{
				float *s = tempMem, m = [self minValueOfSeries]-1024;
				
				long i = [self pwidth] * [self pheight];
				
				while (i-- > 0)
					*s++ = m;
				
				s = src.data;
				s += (([self DCMPixShutterRectOriginY] * [self pwidth]) + [self DCMPixShutterRectOriginX]);
				float *d = tempMem + (([self DCMPixShutterRectOriginY] * [self pwidth]) + [self DCMPixShutterRectOriginX]);
				
				i = self.DCMPixShutterRectHeight;
				while( i-- > 0)
				{
					memcpy( d, s, self.DCMPixShutterRectWidth*4);
					
					d += [self pwidth];
					s += [self pwidth];
				}
				
				if( src.data != [self fImage]) free( src.data);
				src.data = tempMem;
			}
		}

		// Flipping X-Y
		if( xF)
		{
			dst = src;
			dst.data = malloc( dst.height * dst.rowBytes);
			if( dst.data)
				vImageHorizontalReflect_PlanarF ( &src, &dst, 0);
			
			if( src.data != [self fImage]) free( src.data);
			if( dst.data == nil) return nil;
			src = dst;
			
			rot *= -1.;
		}
		
		if( yF)
		{
			dst = src;
			dst.data = malloc( dst.height * dst.rowBytes);
			if( dst.data)
				vImageVerticalReflect_PlanarF ( &src, &dst, 0);
			
			if( src.data != [self fImage]) free( src.data);
			if( dst.data == nil) return nil;
			src = dst;
			
			rot *= -1.;
		}
		
		// Scaling
		
		dst.height = [self pheight]*scale * pixelRatio;
		dst.width = [self pwidth]*scale;
		dst.rowBytes = dst.width*4;
		dst.data = malloc( dst.height * dst.rowBytes);
		if( dst.data)
			vImageScale_PlanarF( &src, &dst, nil, kvImageHighQualityResampling );
		
		// Rotation
		if( src.data != [self fImage]) free( src.data);
		if( dst.data == nil) return nil;
		
		src = dst;
		
		dst.height = newH;
		dst.width = newW;
		dst.rowBytes = newW*4;
		dst.data = malloc( dst.height * dst.rowBytes);
		
		if( dst.data)
		{
			int v = r;
			if( v % 90 == 0)
				vImageRotate_PlanarF( &src, &dst, nil, -rot, [self minValueOfSeries], kvImageHighQualityResampling);
			else
				vImageRotate_PlanarF( &src, &dst, nil, -rot, [self minValueOfSeries] + bgO, kvImageHighQualityResampling+kvImageBackgroundColorFill);
		}
		
		if( src.data != [self fImage]) free( src.data);
		if( dst.data == nil) return nil;
	}
	
	DCMPix *newPix = [[self copy] autorelease];
	
	[newPix freefImageWhenDone: NO];
	[newPix setfImage: dst.data];
	[newPix freefImageWhenDone: YES];
	
	newPix.pheight = dst.height;
	newPix.pwidth = dst.width;
	newPix.pixelSpacingX = pixelSpacingX / scale;
	newPix.pixelSpacingY = pixelSpacingX / scale;
	
	// New orientation
	float v[ 9];
	[newPix orientationCorrected: v rotation: r xFlipped: xF yFlipped: yF];
	[newPix setOrientation: v];
	
	// New origin
	float o[ 3];
	NSPoint a = NSMakePoint( dstRect.origin.x, dstRect.origin.y);
	a = [DCMPix rotatePoint: a aroundPoint: centerPt angle: -rot];
	if( xF) a.x = newWidth - a.x -1;
	if( yF) a.y = newHeight - a.y -1;
	[self convertPixX: a.x/scale pixY: a.y/scale toDICOMCoords: o pixelCenter: NO];
	[newPix setOrigin: o];
	
	return newPix;
}

- (DCMPix*) renderInRectSize:(NSSize) rectSize atPosition:(NSPoint) oo rotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF;
{
	return [self renderInRectSize: rectSize atPosition: oo rotation: r scale: scale xFlipped: xF yFlipped:  yF smartCrop: YES];
}

- (DCMPix*) renderInRectSize:(NSSize) rectSize atPosition:(NSPoint) oo rotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF smartCrop: (BOOL) smartCrop;
{
	if( [self isRGB]) return nil;
	
	DCMPix *newPix = [self renderWithRotation: r scale: scale xFlipped: xF yFlipped:  yF backgroundOffset: 0];
	if( newPix == nil) return nil;
	
	vImage_Buffer src;
	vImage_Buffer dst;
	
	src.height = [newPix pheight];
	src.width = [newPix pwidth];
	src.rowBytes = src.width*4;
	src.data = [newPix fImage];
	
	if( xF) oo.x = - oo.x;
	if( yF) oo.y = - oo.y;
	
	oo = [DCMPix rotatePoint: oo aroundPoint:NSMakePoint( 0, 0) angle: -r*deg2rad];
		
	// zero coordinate is in the center of the view
	NSPoint cov = NSMakePoint( rectSize.width/2 + oo.x - [newPix pwidth]/2, rectSize.height/2 - oo.y - [newPix pheight]/2);
	
	if( smartCrop)	// remove the black part of the image
	{
		NSRect usefulRect;
		
		usefulRect.origin = cov;
		usefulRect.size.width = [newPix pwidth];
		usefulRect.size.height = [newPix pheight];
		
		NSRect frameRect;
		
		frameRect.size = rectSize;
		frameRect.origin.x = frameRect.origin.y = 0;
		
		NSRect smartRect = NSIntersectionRect( frameRect, usefulRect);
		
		rectSize.height = smartRect.size.height;
		rectSize.width = smartRect.size.width;
		
		cov.x -= smartRect.origin.x;
		cov.y -= smartRect.origin.y;
	}
	
	cov.x = (int) cov.x;
	cov.y = (int) cov.y;

	dst.height = rectSize.height;
	dst.width = rectSize.width;
	dst.rowBytes = dst.width*4;
	dst.data = malloc( dst.height * dst.rowBytes);
	
	if( dst.data)
		[self drawImage: &src inImage: &dst offset: cov background: [self minValueOfSeries]-1024];
	else return nil;
	
	DCMPix *rPix = [[newPix copy] autorelease];
	
	[rPix freefImageWhenDone: NO];
	[rPix setfImage: dst.data];
	[rPix freefImageWhenDone: YES];
	
	rPix.pheight = dst.height;
	rPix.pwidth = dst.width;
	
	// New origin
	float o[ 3];
	[rPix convertPixX: -cov.x pixY: -cov.y toDICOMCoords: o pixelCenter: NO];
	[rPix setOrigin: o];
	
	return rPix;
}

- (NSImage*) renderNSImageInRectSize:(NSSize) rectSize atPosition:(NSPoint) oo rotation:(float) r scale:(float) scale xFlipped:(BOOL) xF yFlipped: (BOOL) yF
{
	if( [self isRGB]) return nil;
	
	DCMPix *newPix = [self renderInRectSize: rectSize atPosition: oo rotation: r scale: scale xFlipped: xF yFlipped: yF];
	
	[newPix changeWLWW: [newPix wl] :[newPix ww]];
	
	return [newPix image];
}

-(void) orientationDouble:(double*) c
{
	[self CheckLoad]; 
	
	for( int i = 0 ; i < 9; i ++) c[ i] = orientation[ i];
}

-(BOOL) identicalOrientationTo:(DCMPix*) c
{
	double o[ 9];
	
	[c orientationDouble: o];
	
	for( int i = 0 ; i < 9; i ++) if( o[ i] != orientation[ i]) return NO;
	
	return YES;
}

-(void) orientation:(float*) c
{
	[self CheckLoad]; 
	
	for( int i = 0 ; i < 9; i ++) c[ i] = orientation[ i];
}

-(void) setOrientationDouble:(double*) c
{
	for( int i = 0 ; i < 6; i ++) orientation[ i] = c[ i];
	
	double length = sqrt(orientation[0]*orientation[0] + orientation[1]*orientation[1] + orientation[2]*orientation[2]);
	
	if( length)
	{
		orientation[0] = orientation[ 0] / length;
		orientation[1] = orientation[ 1] / length;
		orientation[2] = orientation[ 2] / length;
	}
	
	length = sqrt(orientation[3]*orientation[3] + orientation[4]*orientation[4] + orientation[5]*orientation[5]);
	
	if( length)
	{
		orientation[3] = orientation[ 3] / length;
		orientation[4] = orientation[ 4] / length;
		orientation[5] = orientation[ 5] / length;
	}
	
	// Compute normal vector
	orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
	orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
	orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
	
	length = sqrt(orientation[6]*orientation[6] + orientation[7]*orientation[7] + orientation[8]*orientation[8]);
	
	if( length)
	{
		orientation[6] = orientation[ 6] / length;
		orientation[7] = orientation[ 7] / length;
		orientation[8] = orientation[ 8] / length;
	}
}

-(void) setOrientation:(float*) c
{
	double d[ 6];
	
	for( int i = 0 ; i < 6; i ++) d[ i] = c[ i];
	
	[self setOrientationDouble: d];
}

-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d pixelCenter: (BOOL) pixelCenter
{
	if( pixelCenter)
	{
		x -= 0.5;
		y -= 0.5;
	}
	
	d[0] = originX + y*orientation[3]*pixelSpacingY + x*orientation[0]*pixelSpacingX;
	d[1] = originY + y*orientation[4]*pixelSpacingY + x*orientation[1]*pixelSpacingX;
	d[2] = originZ + y*orientation[5]*pixelSpacingY + x*orientation[2]*pixelSpacingX;
}

-(void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) d
{
	[self convertPixX: x pixY: y toDICOMCoords: d pixelCenter: YES];
}

-(void) convertPixDoubleX: (double) x pixY: (double) y toDICOMCoords: (double*) d pixelCenter: (BOOL) pixelCenter
{
	if( pixelCenter)
	{
		x -= 0.5;
		y -= 0.5;
	}
	
	d[0] = originX + y*orientation[3]*pixelSpacingY + x*orientation[0]*pixelSpacingX;
	d[1] = originY + y*orientation[4]*pixelSpacingY + x*orientation[1]*pixelSpacingX;
	d[2] = originZ + y*orientation[5]*pixelSpacingY + x*orientation[2]*pixelSpacingX;
}

-(void) convertPixDoubleX: (double) x pixY: (double) y toDICOMCoords: (double*) d
{
	[self convertPixDoubleX: x pixY: y toDICOMCoords: d pixelCenter: YES];
}

-(void) convertDICOMCoords: (float*) dc toSliceCoords: (float*) sc pixelCenter:(BOOL) pixelCenter
{	
	float temp[ 3 ];
	
	temp[ 0 ] = dc[ 0 ] - originX;
	temp[ 1 ] = dc[ 1 ] - originY;
	temp[ 2 ] = dc[ 2 ] - originZ;
	
	sc[ 0 ] = temp[ 0 ] * orientation[ 0 ] + temp[ 1 ] * orientation[ 1 ] + temp[ 2 ] * orientation[ 2 ];
	sc[ 1 ] = temp[ 0 ] * orientation[ 3 ] + temp[ 1 ] * orientation[ 4 ] + temp[ 2 ] * orientation[ 5 ];
	sc[ 2 ] = temp[ 0 ] * orientation[ 6 ] + temp[ 1 ] * orientation[ 7 ] + temp[ 2 ] * orientation[ 8 ];
	
	if( pixelCenter)
	{
		sc[ 0 ] += pixelSpacingX /2.;	// The center of the pixel
		sc[ 1 ] += pixelSpacingY /2.;	// The center of the pixel
	}
}

- (void) convertDICOMCoords: (float*) dc toSliceCoords: (float*) sc
{
	[self convertDICOMCoords: dc toSliceCoords:  sc pixelCenter: YES];
}

- (void) convertDICOMCoordsDouble: (double*) dc toSliceCoords: (double*) sc pixelCenter:(BOOL) pixelCenter
{	
	double temp[ 3 ];
	
	temp[ 0 ] = dc[ 0 ] - originX;
	temp[ 1 ] = dc[ 1 ] - originY;
	temp[ 2 ] = dc[ 2 ] - originZ;
	
	sc[ 0 ] = temp[ 0 ] * orientation[ 0 ] + temp[ 1 ] * orientation[ 1 ] + temp[ 2 ] * orientation[ 2 ];
	sc[ 1 ] = temp[ 0 ] * orientation[ 3 ] + temp[ 1 ] * orientation[ 4 ] + temp[ 2 ] * orientation[ 5 ];
	sc[ 2 ] = temp[ 0 ] * orientation[ 6 ] + temp[ 1 ] * orientation[ 7 ] + temp[ 2 ] * orientation[ 8 ];
	
	if( pixelCenter)
	{
		sc[ 0 ] += pixelSpacingX /2.;	// The center of the pixel
		sc[ 1 ] += pixelSpacingY /2.;	// The center of the pixel
	}
}

- (void) convertDICOMCoordsDouble: (double*) dc toSliceCoords: (double*) sc
{
	[self convertDICOMCoordsDouble: dc toSliceCoords: sc pixelCenter: YES];
}

+(int) nearestSliceInPixelList: (NSArray*)pixList withDICOMCoords: (float*)dicomCoords sliceCoords: (float*)nearestSliceCoords
{
	
	unsigned int count = pixList.count,
	nearestSliceIndx;
	
	float minDist = MAXFLOAT;
	
	for ( unsigned int i = 0; i < count; i++ )
	{
		float sliceCoords[ 3 ];
		DCMPix *pix = [pixList objectAtIndex: i];
		[pix convertDICOMCoords: dicomCoords toSliceCoords: sliceCoords];
		if ( fabs( sliceCoords[ 2 ] ) < minDist )
		{
			minDist = fabs( sliceCoords[ 2 ] );
			memcpy( nearestSliceCoords, sliceCoords, sizeof sliceCoords );
			nearestSliceIndx = i;
		}
	}
	
	return nearestSliceIndx;
}


- (void)computePixMinPixMax
{
	float pixmin, pixmax;
	
	if( fImage == nil ) return;
	
	if( isRGB )
	{
		pixmax = 255;
		pixmin = 0;
	}
	else
	{
		float fmin, fmax;
		
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

- (short)stack{ if( stackMode == 0 ) return 1; return stack; }

- (void)setFusion: (short)m : (short)s : (short)direction
{
	if( s >= 0) stack = s;
	if( m >= 0) stackMode = m;
	if( direction >= 0) stackDirection = direction;
	
	updateToBeApplied = YES;
	needToCompute8bitRepresentation = YES;
}

- (void)setSourceFile:(NSString*)s
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
	
//	[self setRowBytes: [self pwidth]*sizeof( float)];
	[self setBaseAddr: malloc( [self pwidth] * [self pheight])];
	
	[self setRGB: NO];
	
	memcpy( fImage, dstPtr, height * width * 4);
	
	[self changeWLWW:wl :ww];
	
	free( dstPtr);
}



- (void)ConvertToRGB:(long) mode :(long) cwl :(long) cww
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
	
//	[self setRowBytes: [self pwidth]*4];
	
	[self setBaseAddr: malloc( [self pwidth] * [self pheight] * 4)];
	
	[self setRGB: YES];
	
	[self changeWLWW:127 :256];
	
	free( dst8.data);
	
	if( isRGB )
	{
		unsigned char*	argbPtr = (unsigned char*) fImage;
		long			ss = width * height;
		
		while( ss-->0 )
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
	if( fImage == nil) return 0;
	
	if( (stackMode == 1 || stackMode == 2 || stackMode == 3) && stack >= 1)
	{
		if( isRGB == NO )
		{
			float   *fNext = nil;
			long	countstack = 0;
			
			val = fImage[ x + (y * width)];
			countstack++;
			
			for( long i = 1; i < stack; i++ )
			{
				long next;
				if( stackDirection) next = pixPos-i;
				else next = pixPos+i;
				
				if( next < pixArray.count && next >= 0 )
				{
					fNext = [[pixArray objectAtIndex: next] fImage];
					if( fNext )
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
		
		if( offsetY > 0)
			{ startheight = offsetY;   subheight = height;}
		else { startheight = 0; subheight = height + offsetY;}
		
		if( offsetX > 0)
			{ startwidth = offsetX;   subwidth = width;}
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
		long	offsetX = subPixOffset.x, offsetY = -subPixOffset.y;
		long	startheight, subheight, startwidth, subwidth;
		float   *tempIn, *tempOut, *tempResult;
		
		if( offsetY > 0)
			{ startheight = offsetY;   subheight = height;}
		else { startheight = 0; subheight = height + offsetY;}
		
		if( offsetX > 0)
			{ startwidth = offsetX;   subwidth = width;}
		else { startwidth = 0; subwidth = width + offsetX;}
		
		for( long y = startheight; y < subheight; y++ )
		{
			tempResult = result + y*width;
			tempIn = input + y*width;
			tempOut = subfImage + (y-offsetY)*width - offsetX;
			long x = subwidth - startwidth;
			while ( x-- > 0 )
			{
				*tempResult++ = *tempIn++ - *tempOut++;
			}
		}
	}
	return result;
}


//----------------------------Subtraction parameters copied to each Pix---------------------------

- (void)setSubSlidersPercent: (float)p gamma: (float)g zero: (float)z
{
	subtractedfPercent = p;
	subtractedfZ = z;
	subtractedfZero = subtractedfZ - 0.8 + (p*0.8);
	subtractedfGamma = g;
	
	if( subGammaFunction) vImageDestroyGammaFunction( subGammaFunction);
	
	subGammaFunction = vImageCreateGammaFunction( subtractedfGamma, kvImageGamma_UseGammaValue_half_precision, 0 );	
	
	updateToBeApplied = YES;
}

- (void) setSubSlidersPercent: (float) p
{
	[self setSubSlidersPercent: p gamma: subtractedfGamma zero: subtractedfZ];
}

- (void)setSubPixOffset:(NSPoint) subOffset
{
	subPixOffset = subOffset;
	updateToBeApplied = YES;
}

//----- Min and Max of the subtracted result of all the Pix of the series for a given subfImage------

-(NSPoint) subMinMax:(float*)input :(float*)subfImage
{
	long			i			= height * width;	
	float			*result		= malloc( i * sizeof(float));
	float			r;
	
	vDSP_vsub (subfImage,1,input,1,result,1,i);		//mask - frame
	vDSP_minv (result,1,&r,i);						//black pixel
	subMinMax.x = r;
	vDSP_maxv (result,1,&r,i);						//white pixel
	subMinMax.y = r;
	
	free( result);
	
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
	
	if (result == nil) return input;
	
	float	*firstResultPixel = result + (firstPixelAbs - firstPixel)/2;
	long	lengthToBeCopied = i - firstPixelAbs;
	
	//preparing mask: the following command registers it in function of the pixel shift, and multiplies it by % 
	vDSP_vsmul (firstSourcePixel,1,&subtractedfPercent,firstResultPixel,1,lengthToBeCopied);//result= % mask	
	
	vDSP_vsub (result,1,input,1,result,1,lengthToBeCopied);				//mask - frame
	
	float ratio = fabs(subMinMax.y-subMinMax.x);						//Max difference in subtraction without pixel shift
	if( ratio == 0) ratio = 1;
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
-(void) positionerPrimaryAngle:(NSNumber*)newPositionerPrimaryAngle
{
	if( positionerPrimaryAngle != newPositionerPrimaryAngle)
	{
		[positionerPrimaryAngle release];
		positionerPrimaryAngle = [newPositionerPrimaryAngle retain];
	}
}
-(NSNumber*) positionerPrimaryAngle{return positionerPrimaryAngle;}
-(void) positionerSecondaryAngle:(NSNumber*)newPositionerSecondaryAngle
{
	if( positionerSecondaryAngle != newPositionerSecondaryAngle)
	{
		[positionerSecondaryAngle release];
		positionerSecondaryAngle = [newPositionerSecondaryAngle retain];
	}
}

-(NSNumber*) positionerSecondaryAngle{return positionerSecondaryAngle;}


-(void) DCMPixShutterRect:(long)x:(long)y:(long)w:(long)h;
{
	shutterRect_x = x;
	shutterRect_y = y;
	shutterRect_w = w;
	shutterRect_h = h;
}

-(BOOL) DCMPixShutterOnOff  {return DCMPixShutterOnOff;}
-(void) DCMPixShutterOnOff:(BOOL)newDCMPixShutterOnOff
{
	DCMPixShutterOnOff = newDCMPixShutterOnOff;
	updateToBeApplied = YES;
}

- (void) setBlackIndex:(int) i
{
	blackIndex = i;
}

-(void) applyShutter
{
	if (DCMPixShutterOnOff == NSOnState)
	{
		if( shutterRect_y < 0) shutterRect_y = 0;
		if( shutterRect_x < 0) shutterRect_x = 0;
		
		if( shutterRect_w + shutterRect_x > width) shutterRect_w = width - shutterRect_x;
		if( shutterRect_h + shutterRect_y > height) shutterRect_h = height - shutterRect_y;	
		
		if( isRGB == YES || thickSlabVRActivated == YES)
		{
			char*	tempMem = calloc( 1, height * width * 4 * sizeof(char));
			
			if( tempMem)
			{
				int i = shutterRect_h;
				
				char*	src = baseAddr + ((shutterRect_y * width*4) + shutterRect_x*4);
				char*	dst = tempMem + ((shutterRect_y * width*4) + shutterRect_x*4);
				
				while( i-- > 0)
				{
					memcpy( dst, src, shutterRect_w*4);
					
					dst += width*4;
					src += width*4;
				}
				
				memcpy(baseAddr, tempMem, height * width * 4*sizeof(char));
				
				free( tempMem);
			}
		}
		else
		{
			char*	tempMem = malloc( height * width * sizeof(char));
			
			
			if( tempMem)
			{
				memset( tempMem, blackIndex, height * width * sizeof(char));
			
				int i = shutterRect_h;
				
				char*	src = baseAddr + ((shutterRect_y * width) + shutterRect_x);
				char*	dst = tempMem + ((shutterRect_y * width) + shutterRect_x);
				
				while( i-- > 0)
				{
					memcpy( dst, src, shutterRect_w);
					
					dst += width;
					src += width;
				}
				
				if( shutterCircular_radius)
				{
					erase_outside_circle( tempMem, width, height, shutterCircular_x, shutterCircular_y, shutterCircular_radius, blackIndex);
				}
				
				if( shutterPolygonal)
				{
					int		x, y;
					
					for( y = 0 ; y < height; y++)
					{
						for( x = 0 ; x < width; x++)
						{
							if( pnpoly( shutterPolygonal, shutterPolygonalSize, x, y) == 0)
							{
								tempMem[ x + y*width] = blackIndex;
							}
						}
					}
				}
				
				memcpy(baseAddr, tempMem, height * width * sizeof(char));
				
				free( tempMem);
			}
		}
	}
}

- (float*) applyConvolutionOnImage:(float*) src RGB:(BOOL) color
{
	float	*result = src;
	
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
	long			diff;
	float			*fNext = NULL;
	float			*fResult = malloc( height * width * sizeof(float) );
	long			next;
	float			min, max, iwl, iww;
	
	if( fixed8bitsWLWW)	{
		iww = 256;
		iwl = 127;
	}
	else {
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
			
			if( next < pixArray.count  && next >= 0 )
			{
				fNext = [[pixArray objectAtIndex: next] fImage];
				if( fNext )
				{
#if __ppc__ || __ppc64__
					if( Altivec )
					{
						if( stackMode == 2) vmax8( (vector unsigned char*)fNext, (vector unsigned char*)fImage, (vector unsigned char*)fResult, height * width);
						else vmin8( (vector unsigned char*)fNext, (vector unsigned char*)fImage, (vector unsigned char*)fResult, height * width);
					}
					else NSLog( @"Altivec is REQUIRED");
#else
				{
					if( stackMode == 2) vmax8Intel( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width );
					else vmin8Intel( (vUInt8*) fNext, (vUInt8*) fImage, (vUInt8*) fResult, height * width );
				}
#endif
				}
				
				for( long i = 2; i < stack; i++ )
				{
					long res;
					if( stackDirection) res = pixPos-i;
					else res = pixPos+i;
					
					if( res < pixArray.count )
					{
						long res;
						if( stackDirection) res = pixPos-i;
						else res = pixPos+i;
						
						if( res < pixArray.count && res >= 0 )
						{
							fNext = [[pixArray objectAtIndex: res] fImage];
							if( fNext )	{
#if __ppc__ || __ppc64__
								if( Altivec )
								{
									if( stackMode == 2) vmax8( (vector unsigned char*)fResult, (vector unsigned char*)fNext, (vector unsigned char*)fResult, height * width);
									else vmin8( (vector unsigned char*)fResult, (vector unsigned char*)fNext, (vector unsigned char*)fResult, height * width);
								}
								else NSLog( @"Altivec is REQUIRED");
#else
							{
								if( stackMode == 2) vmax8Intel( (vUInt8*) fResult, (vUInt8*) fNext, (vUInt8*) fResult, height * width );
								else vmin8Intel( (vUInt8*) fResult, (vUInt8*) fNext, (vUInt8*) fResult, height * width );
							}
#endif
							}
						}
					}
				}
			}
			else
			{
				memcpy( fResult, fImage, height * width * sizeof(float) );
			}
			break;			
	} //end of switch
	
	return fResult;
}

- (float*) computeThickSlab
{
	BOOL			flip = NO; // case 5
	long			stacksize;
	unsigned char   *rgbaImage;
	float			min, max, iwl, iww;
	float			*fResult = nil;
	
	if( fixed8bitsWLWW )
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
	
	switch( stackMode )
	{
		case 4:		// Volume Rendering
			flip = YES;
		case 5:		// Volume Rendering
			if( thickSlab )
			{											
				if( stackDirection )
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
				
//				[self setRowBytes: width*4];
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
			
			if( processorsLock == nil )
				processorsLock = [[NSConditionLock alloc] init];
			
			if( minmaxThreads == nil)
			{
				minmaxThreads = [[NSMutableArray array] retain];
				
				for( int i = 0; i < MPProcessors(); i++ )
				{
					[minmaxThreads addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [[[NSConditionLock alloc] initWithCondition: 0] autorelease], @"threadLock", nil]];
					
					[NSThread detachNewThreadSelector: @selector( computeMaxThread:) toTarget: [[PixThread alloc] init] withObject: [minmaxThreads lastObject]];
				}
			}
			
			int numberOfThreadsForCompute = MPProcessors ();
			
			[processorsLock lock];
			[processorsLock unlockWithCondition: numberOfThreadsForCompute];
			
			for( int i = 0; i < numberOfThreadsForCompute; i++ )
			{
				NSMutableDictionary *d = [minmaxThreads objectAtIndex: i];
				
				[d setObject: [NSValue valueWithPointer: fResult] forKey: @"fResult"];
				[d setObject: [NSNumber numberWithInt: i] forKey: @"pos"];
				[d setObject: self forKey: @"self"];
				
				[[d objectForKey: @"threadLock"] lock];
				[[d objectForKey: @"threadLock"] unlockWithCondition: 1];
			}
			
			[processorsLock lockWhenCondition: 0];
			[processorsLock unlock];
			
			if( countstackMean > 1 )
			{
				float   invCount = 1.0f / countstackMean;
				
				vDSP_vsmul( fResult, 1, &invCount, fResult, 1, height * width);
			}
			//-----------------------------------
			break;
	}
	
	return fResult;
}

- (float*)computefImage
{
	float *result;
	
	thickSlabVRActivated = NO;
//	[self setRowBytes: width*4];
	
	// = STACK IMAGES thickslab
	if( stackMode > 0 && stack >= 1 && [pixArray count] > 1)
	{
		result = [self computeThickSlab];
	}
	else result = fImage;
	
	return result;
}

- (void)setTransferFunction:(NSData*) tf
{
	if( transferFunction != tf)
	{
		[transferFunction release];
		transferFunction = [tf retain];
		
		transferFunctionPtr = (float*) [transferFunction bytes];
		
		updateToBeApplied = YES;
	}
}

- (void) compute8bitRepresentation
{
	float			iwl, iww;
	
	if( fixed8bitsWLWW )
	{
		iww = 256;
		iwl = 127;
	}
	else
	{
		iww = ww;
		iwl = wl;
	}
	
	if( baseAddr)
	{
		needToCompute8bitRepresentation = NO;
		
		updateToBeApplied = NO;
		
		float  min, max;
		
        min = iwl - iww / 2; 
        max = iwl + iww / 2;
		
		// ***** ***** ***** ***** ***** 
		// ***** SOURCE IMAGE IS 32 BIT FLOAT
		// ***** ***** ***** ***** *****
		
		if( isRGB == NO) //fImage case
		{
			vImage_Buffer	srcf, dst8;
			
//			float *s = [self computefImage];
//			float v = 0;
//			for( int y = 0; y < height; y++)
//			{
//				for( int x = 0 ; x < width; x++)
//				{
//					*s = v;
//					s++;
//				}
//				v++;
//			}
			
			srcf.data = [self computefImage];
			
			if( srcf.data == nil) return;
			
			// CONVERSION TO 8-BIT for displaying
			
			if( thickSlabVRActivated == NO )
			{
				dst8.height = height;
				dst8.width = width;
				dst8.rowBytes = width;					
				dst8.data = baseAddr;
				
				srcf.height = height;
				srcf.width = width;
				srcf.rowBytes = width*sizeof(float);
				
				if( subtractedfImage )
				{
					if( wl < 2) wl = 2;
					if( ww < 2) ww = 2;
					if( wl > 512) wl = 512;
					if( ww > 512) ww = 512;
					
					iww = ww;
					iwl = wl;
					
					float gamma = 2. * (iww / 256.);
					float zero = 1.6 - 0.8 * (iwl / 128.);
					
					[self setSubSlidersPercent:subtractedfPercent gamma: gamma zero: zero];
					
					srcf.data = [self subtractImages: srcf.data :subtractedfImage];
					
					if( convolution) srcf.data = [self applyConvolutionOnImage: srcf.data RGB: NO];
					
					vImageGamma_PlanarFtoPlanar8 (&srcf, &dst8, subGammaFunction, 0);
				}
				else
				{
					if( convolution) srcf.data = [self applyConvolutionOnImage: srcf.data RGB: NO];
					
					if( transferFunctionPtr == nil)	// LINEAR
					{
						vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, max, min, 0);
					}
					else
					{
						if( processorsLock == nil )
							processorsLock = [[NSConditionLock alloc] init];
						
						if( nonLinearWLWWThreads == nil)
						{
							nonLinearWLWWThreads = [[NSMutableArray array] retain];
							
							for( int i = 0; i < MPProcessors(); i++ )
							{
								[nonLinearWLWWThreads addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [[[NSConditionLock alloc] initWithCondition: 0] autorelease], @"threadLock", nil]];
								[NSThread detachNewThreadSelector: @selector( applyNonLinearWLWWThread:) toTarget:[[PixThread alloc] init] withObject: [nonLinearWLWWThreads lastObject]];
							}
						} 
						
						int numberOfThreadsForCompute = MPProcessors ();
						
						NSValue *srcNSValue = [NSValue valueWithPointer: srcf.data];
						
						int start;
						int end;
						
						[processorsLock lock];
						[processorsLock unlockWithCondition: numberOfThreadsForCompute];
						
						for( int i = 0; i < numberOfThreadsForCompute; i++ )
						{
							start = i * (int) (height / numberOfThreadsForCompute);
							end = (i+1) * (int) (height / numberOfThreadsForCompute);
							
							NSMutableDictionary *d = [nonLinearWLWWThreads objectAtIndex: i];
							
							[d setObject: [NSNumber numberWithInt: start] forKey: @"start"];
							[d setObject: [NSNumber numberWithInt: end] forKey: @"end"];
							[d setObject: self forKey: @"self"];
							[d setObject: srcNSValue forKey: @"src"];
							
							[[d objectForKey: @"threadLock"] lock];
							[[d objectForKey: @"threadLock"] unlockWithCondition: 1];
						}
						
						[processorsLock lockWhenCondition: 0];
						[processorsLock unlock];
					}
					
					#ifdef OSIRIX_VIEWER
					if(isLUT12Bit && [AppController canDisplay12Bit])
					{
						NSInvocation *fill12BitBufferInvocation = [AppController fill12BitBufferInvocation];
						[fill12BitBufferInvocation setArgument:&self atIndex:2];
						NSValue *srcNSValue = [NSValue valueWithPointer: srcf.data];
						[fill12BitBufferInvocation setArgument:&srcNSValue atIndex:3];
						[fill12BitBufferInvocation setArgument:&transferFunctionPtr atIndex:4];
						[fill12BitBufferInvocation invoke];
					}
					#endif
				}
				
				if( srcf.data != fImage) free( srcf.data);
			}
		}	
		
		// ***** ***** ***** ***** ***** 
		// ***** SOURCE IMAGE IS RGBA
		// ***** ***** ***** ***** *****
		
		if( isRGB )
		{
			vImage_Buffer   src, dst;
			Pixel_8			convTable[256];
			long			diff = max - min, val;
			
			if( stackMode > 0 && stack >= 1 && [pixArray count] > 1)
			{
				src.data = [self computeThickSlabRGB];
			}
			else src.data = fImage;
			
			if( convolution) src.data = [self applyConvolutionOnImage: src.data RGB: YES];
			
			// APPLY WINDOW LEVEL TO RGB IMAGE
			
			if( transferFunctionPtr == nil)	// LINEAR
			{
				for( long i = 0; i < 256; i++ )
				{
					val = (((i-min) * 255L) / diff);
					if( val < 0) val = 0;
					else if( val > 255) val = 255;
					convTable[i] = val;
				}
			}
			else
			{
				for( long i = 0; i < 256; i++ )
				{
					val = (((i-min) * 255L) / diff);
					if( val < 0) val = 0;
					else if( val > 255) val = 255;
					
					val = 255.*transferFunctionPtr[ val*16];	// 4096 value table
					if( val < 0) val = 0;
					else if( val > 255) val = 255;
					convTable[i] = val;
				}
			}
			
			src.height = height;
			src.width = width;
			src.rowBytes = width*4;
			
			dst.height = height;
			dst.width = width;
			dst.rowBytes = width*4;
			dst.data = baseAddr;
			
			vImageTableLookUp_ARGB8888 ( &src,  &dst,  convTable,  convTable,  convTable,  convTable,  0);
			
			if( src.data != fImage) free( src.data);
		}
		
		[self applyShutter];		
    }
}

- (void) changeWLWW:(float)newWL :(float)newWW
{
	if( baseAddr == nil )
	{
		[self checkImageAvailble:newWW :newWL];
		return;
	}
	
	[self CheckLoad]; 
	
	if( newWW !=0 || newWL != 0)   // new values to be applied
	{
		if( fullww > 256 )
		{
			if( newWW < 1) newWW = 2;
			
			if( newWL - newWW/2 == 0 )
			{
				//				newWW = (int) newWW;
				//				newWL = (int) newWL;
				
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
	
	// ----------------------------------------------------------- iww, iwl contain computMinPixMax or newWW, newWL
    
    if( baseAddr)
	{
		needToCompute8bitRepresentation = YES;
	}
}

#pragma mark-

- (void) kill8bitsImage
{	 
	if( baseAddr) free( baseAddr);
	baseAddr = nil;
}

- (void)checkImageAvailble: (float)newWW : (float)newWL
{
	[self CheckLoad];
	
	ww = newWW;
	wl = newWL;
	
	if( baseAddr == nil)
		[self allocate8bitRepresentation];
}

- (NSImage*) generateThumbnailImageWithWW: (float)newWW WL: (float)newWL
{
    int destWidth, destHeight;
	NSImage *image = nil;
	float ratio;
	
    [self CheckLoad];
	
	if( (float) width / PREVIEWSIZE > (float) height / PREVIEWSIZE) ratio = (float) width / PREVIEWSIZE;
	else ratio = (float) height / PREVIEWSIZE;
	
	destWidth = (float) width / ratio;
	destHeight = (float) height / ratio;
    
	NSBitmapImageRep *bitmapRep = nil;
	
	if( isRGB )
	{
		bitmapRep = [[[NSBitmapImageRep alloc] 
					 initWithBitmapDataPlanes: nil
					 pixelsWide:destWidth
					 pixelsHigh:destHeight
					 bitsPerSample:8
					 samplesPerPixel:3
					 hasAlpha:NO
					 isPlanar:NO
					 colorSpaceName:NSCalibratedRGBColorSpace
					 bytesPerRow:destWidth*4
					 bitsPerPixel:24
					 ] autorelease];
	}
	else
	{
		bitmapRep = [[[NSBitmapImageRep alloc] 
					 initWithBitmapDataPlanes: nil
					 pixelsWide:destWidth
					 pixelsHigh:destHeight
					 bitsPerSample:8
					 samplesPerPixel:1  // 1-3 // RGB
					 hasAlpha:NO
					 isPlanar:NO
					 colorSpaceName:NSCalibratedWhiteColorSpace
					 bytesPerRow:destWidth
					 bitsPerPixel:8 // 8 - 24 -32
					 ] autorelease];
	}
	
	if( bitmapRep )
	{
		if( newWW == 0 && newWL == 0 )
		{
			if( ww == 0 && wl == 0 )
			{
				[self computePixMinPixMax];
				ww = fullww;
				wl = fullwl;
			}
			newWW = ww;
			newWL = wl;
		}
		
		CreateIconFrom16( fImage, [bitmapRep bitmapData], height, width, destWidth, newWL, newWW, isRGB);
		
		image = [[[NSImage alloc] initWithSize:NSMakeSize(destWidth, destHeight)] autorelease];
		[image addRepresentation:bitmapRep];
	}
	else NSLog(@"Memory error... not enough RAM");
	
    return image;
}

- (void) allocate8bitRepresentation
{
    [self CheckLoad];
	
	if( baseAddr) free( baseAddr);
	baseAddr = nil;
	
	if( isRGB )
		baseAddr = calloc( ((width*4) + 4) * ((height*4) + 4), 1);
	else
		baseAddr = calloc( (width + 4) * (height + 4), 1);
	
	if( baseAddr)
		[self changeWLWW: wl : ww];
}

- (long)ID { return imID; }
- (void)setID: (long)i { imID = i; }

- (long)Tot {
	[self CheckLoad];
    return imTot;
}

-(void)setTot: (long) tot
{
	[self CheckLoad];
	imTot = tot;
}

-(long)pwidth
{
	[self CheckLoad];
    return width;
}

-(long)pheight
{
	[self CheckLoad];
    return height;
}

- (void) setRowBytes:(long) r
{
	NSLog( @"*** DEPRECATED : [DCMPix setRowBytes] is deprecated, use pwidth instead.");
}

- (long) rowBytes
{
	[self CheckLoad];
	
	NSLog( @"*** DEPRECATED : [DCMPix rowBytes] is deprecated, use pwidth instead.");
	
	if( isRGB) return width*4;
	else return width;
}

- (void)setUpdateToApply { updateToBeApplied = YES; }

-(BOOL) updateToApply { return updateToBeApplied;}

- (short) normalization
{
	return normalization;
}

- (short) kernelsize
{
	return kernelsize;
}

- (short*) kernel
{
	return kernel;
}

-(void) setConvolutionKernel:(short*)val :(short) size :(short) norm
{
	
	if( val )
	{
		kernelsize = size;
		convolution = YES;
		normalization = norm;
		for( long i = 0; i < kernelsize*kernelsize; i++ ) kernel[i] = val[i];
	}
	else
	{
		convolution = NO;
	}
	
	updateToBeApplied = YES;
}

- (void)revert
{
	if( fImage == nil ) return;
	
	[checking lock];
	
	SUVConverted = NO;
	fullww = 0;
	fullwl = 0;

	[frameOfReferenceUID release];				frameOfReferenceUID = nil;
	[acquisitionTime release];					acquisitionTime = nil;
	[radiopharmaceuticalStartTime release];		radiopharmaceuticalStartTime = nil;
	[repetitiontime release];					repetitiontime = nil;
	[echotime release];							echotime = nil;
	[flipAngle release];						flipAngle = nil;
	[laterality release];						laterality = nil;
	[protocolName release];						protocolName = nil;
	[viewPosition release];						viewPosition = nil;
	[patientPosition release];					patientPosition = nil;
	[units release];							units = nil;
	[decayCorrection release];					decayCorrection = nil;

	[self clearCachedDCMFrameworkFiles];
	[self clearCachedPapyGroups];
	
	if( fExternalOwnedImage == nil )
	{
		if( fImage != nil )
		{
			free(fImage);
			fImage = nil;
		}
	}
	
	fImage = nil;
	needToCompute8bitRepresentation = YES;
	
	[checking unlock];
	
	[self reloadAnnotations];
}

- (void)dealloc
{
	if( shutterPolygonal) free( shutterPolygonal);
	
	[frameOfReferenceUID release];
	[transferFunction release];
	[positionerPrimaryAngle release];
	[positionerSecondaryAngle release];
	[acquisitionTime release];
	[radiopharmaceuticalStartTime release];
	[repetitiontime release];
	[echotime release];
	[flipAngle release];
	[laterality release];
	[units release];
	[protocolName release];
	[patientPosition release];
	[viewPosition release];
	[decayCorrection release];
	[generatedName release];
	
	if( fExternalOwnedImage == nil)
	{
		if( fImage != nil )
		{
			free(fImage);
			fImage = nil;
		}
	}
	
    
	if( baseAddr)
	{
		free( baseAddr);
		baseAddr = nil;
	}
	[imageObj release];
	
	[checking release];
	checking = nil;
	
	if( oData ) free( oData);
	if( VOILUT_table) free( VOILUT_table);
	
	if( subGammaFunction) vImageDestroyGammaFunction( subGammaFunction);
	
	[annotationsDictionary release];
	
	if(LUT12baseAddr) free(LUT12baseAddr);
	
	[self clearCachedPapyGroups];
	[self clearCachedDCMFrameworkFiles];
	
	[srcFile release];
	
    [super dealloc];
}

// SUV stuff
#pragma mark-
#pragma mark SUV

-(void) copySUVfrom: (DCMPix*)from
{
	self.radiopharmaceuticalStartTime = from.radiopharmaceuticalStartTime;
	self.acquisitionTime = from.acquisitionTime;
	self.radionuclideTotalDose = from.radionuclideTotalDose;
	self.radionuclideTotalDoseCorrected = from.radionuclideTotalDoseCorrected;
	self.patientsWeight = from.patientsWeight;
	self.units = from.units;
	self.displaySUVValue = from.displaySUVValue;
	self.SUVConverted = from.SUVConverted;
	self.decayCorrection = from.decayCorrection;
	self.maxValueOfSeries = from.maxValueOfSeries;
	self.minValueOfSeries = from.minValueOfSeries;
	self.decayFactor = from.decayFactor;
	self.halflife = from.halflife;
	
	[annotationsDictionary release];
	annotationsDictionary = [from.annotationsDictionary retain];
	[self checkSUV];
}

- (void) checkSUV
{
	hasSUV = NO;
	
	if ( ![self.units isEqualToString: @"BQML"] && ![self.units isEqualToString: @"CNTS"] ) return;  // Must be BQ/cc
	
	if( [self.units isEqualToString: @"CNTS"] && philipsFactor == 0.0) return;
	
	if ( self.decayCorrection == nil ) return;
	
	if( decayFactor == 0.0f ) return;
	
	if ( [self.decayCorrection isEqualToString: @"START"] == NO ) return;
	
	if ( self.radionuclideTotalDose <= 0.0 ) return;	
	
	if ( halflife <= 0.0f ) return;
	
	if ( acquisitionTime == nil || radiopharmaceuticalStartTime == nil ) return;
	
	hasSUV = YES;
}


#pragma mark -
#pragma mark Database links

- (NSManagedObject*)seriesObj { return [imageObj valueForKey:@"series"]; }

- (NSString *)description
{
	NSMutableString *description = [NSMutableString string];
	[description appendString:NSStringFromClass([self class])];
	[description appendString:[NSString stringWithFormat: @" source File: %@\n", srcFile]];
	[description appendString:[NSString stringWithFormat: @"core Data Image: %@\n", imageObj]];
	[description appendString:[NSString stringWithFormat: @"width: %d\n", width]];
	[description appendString:[NSString stringWithFormat: @"height: %d\n", height]];
	[description appendString:[NSString stringWithFormat: @"pixelRatio: %f\n", pixelRatio]];
	[description appendString:[NSString stringWithFormat: @"origin X: %f Y: %f  Z: %f\n", originX, originY, originZ]];
	
	return description;
}

#pragma mark -
#pragma mark Image Annotations


#ifdef OSIRIX_VIEWER

+ (BOOL) setAnonymizedAnnotations: (BOOL) v
{
	if( anonymizedAnnotations != v)
	{
		anonymizedAnnotations = v;
		return YES;
	}
	else return NO;
}

- (NSString*)getDICOMFieldValueForGroup:(int)group element:(int)element papyLink:(PapyShort)fileNb;
{
	NSMutableString *field = [NSMutableString string];
	
	SElement *inGrOrModP = 0L;
	
	if( group)
		inGrOrModP = [self getPapyGroup: group];
	
	if( inGrOrModP == nil) // Papyrus failed... unknown group? Try DCM Framework
	{
		DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
		
		return [self getDICOMFieldValueForGroup: group element: element DCMLink: dcmObject];
	}
	else if( inGrOrModP)
	{
		int theEnumGrNb = Papy3ToEnumGroup(group);
		int theMaxElem = gArrGroup [theEnumGrNb].size;
		
		NSCalendarDate *calendarDate;
		
		BOOL elementDefinitionFound = NO;
		
		for ( int j = 0; j < theMaxElem; j++, inGrOrModP++)
		{
			if( inGrOrModP->element == element)
			{
				elementDefinitionFound = YES;
				
				if( inGrOrModP->nb_val > 0)
				{
					UValue_T *theValueP = inGrOrModP->value;
					for ( int k = 0; k < inGrOrModP->nb_val; k++, theValueP++)
					{
						{
#undef UL
#undef IS
#undef SL
#undef SS
#undef SQ
#undef FD
#undef FL
#undef DS
							if(inGrOrModP->vr==DS)	// floating point string
							{
								if( theValueP->a) [field appendString:[NSString stringWithFormat:@"%.6g", atof( theValueP->a)]];
							}
							else if(inGrOrModP->vr==FL)	// floating point string
							{
								[field appendString:[NSString stringWithFormat:@"%.6g", theValueP->fl]];
							}
							else if( inGrOrModP->vr==FD)
							{
								[field appendString:[NSString stringWithFormat:@"%.6g", (float) theValueP->fd]];
							}
							else if(inGrOrModP->vr==UL)
								[field appendString:[NSString stringWithFormat:@"%d", (int) theValueP->ul]];
							else if(inGrOrModP->vr==US || inGrOrModP->vr==USS)
								[field appendString:[NSString stringWithFormat:@"%d", (int) theValueP->us]];
							else if(inGrOrModP->vr==SL)
								[field appendString:[NSString stringWithFormat:@"%d", (int) theValueP->sl]];
							else if(inGrOrModP->vr==SS)
								[field appendString:[NSString stringWithFormat:@"%d", (int) theValueP->ss]];
							else if(inGrOrModP->vr==SQ)
							{
								NSLog(@"group : %d, element : %d", group, element);
								//field = @"";
								//NSLog(@"inGrOrModP->vr==SQ . field = %@", field);
								
								NSMutableString *temp = [NSMutableString string];
								
								// Loop over sequence
								if(theValueP->sq!=NULL)
								{
									Papy_List *dcmList = theValueP->sq->object->item;
									while(dcmList!=NULL)
									{
										SElement *gr = (SElement *)dcmList->object->group;
										
										//if(gr->value)
										[temp appendString:[self getDICOMFieldValueForGroup:gr->group element:gr->element papyLink:fileNb]];
										if(gr->value!=NULL) NSLog(@"++**++   ::    %@", [NSString stringWithCString:gr->value->a encoding:NSASCIIStringEncoding]);
										else NSLog(@"++**++   ::    %@", [NSString stringWithCString:gr->vm encoding:NSASCIIStringEncoding]);
										dcmList = dcmList->next;
									}
								}
								[field appendString:[NSString stringWithString:temp]];
								NSLog(@"SQ field : %@", field);
							}
							else if( theValueP->a)
								[field appendString:[NSString stringWithCString:theValueP->a encoding:NSASCIIStringEncoding]];
							
#undef OB
							if(inGrOrModP->vr==OB)	
								NSLog(@"inGrOrModP->vr==OB . field = %@", field);
							
#undef DA
#undef DT
#undef TM
#undef AS
							
							if(inGrOrModP->vr==DA)
							{
								calendarDate = [DCMCalendarDate dicomDate:field];
								[field setString:[BrowserController DateOfBirthFormat: calendarDate]];
							}
							else if(inGrOrModP->vr==DT)
							{
								calendarDate = [DCMCalendarDate dicomDateTime:field];
								[field setString:[BrowserController DateTimeWithSecondsFormat: calendarDate]];
							}
							else if(inGrOrModP->vr==TM)
							{
								calendarDate = [DCMCalendarDate dicomTime:field];
								[field setString:[BrowserController TimeWithSecondsFormat: calendarDate]];
							}
							else if(inGrOrModP->vr==AS)
							{
								//Age String Format mmmM,dddD,nnnY ie 018Y
								int number = [[field substringWithRange:NSMakeRange(0, 3)] intValue];
								NSString *letter = [field substringWithRange:NSMakeRange(3, 1)];
								[field setString:[NSString stringWithFormat:@"%d %@", number, [letter lowercaseString]]];
							}
							//break;
						}
						if(inGrOrModP->nb_val>1 && k<inGrOrModP->nb_val-1)[field appendString:@" / "];
					}
				}
			}
		}
		
		if( elementDefinitionFound == NO)	// Papyrus doesn't have the definition of all dicom tags.... 2004?
		{
			DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:srcFile decodingPixelData:NO];
			return [self getDICOMFieldValueForGroup: group element: element DCMLink: dcmObject];
		}
	}
	return field;
}

- (NSString*)getDICOMFieldValueForGroup:(int)group element:(int)element DCMLink:(DCMObject*)dcmObject
{
	DCMAttribute *attr = [dcmObject attributeForTag: [DCMAttributeTag tagWithGroup: group element: element]];
	
	if( attr)
	{
		NSMutableString *result = nil;
		
		for( id field in [attr values])
		{	
			if([field isKindOfClass:[NSString class]])
			{
				NSString *vr = [attr vr];
				
				if([vr isEqualToString:@"DS"]) field = [NSString stringWithFormat:@"%.6g", [field floatValue]];
				
				if( result == nil) result = [NSMutableString stringWithString: field];
				else [result appendFormat: @" / %@", field];
			}
			else if([field isKindOfClass:[NSNumber class]])
			{
				NSString *vr = [attr vr];
				
				if([vr isEqualToString:@"FD"]) field = [NSString stringWithFormat:@"%.6g", [field floatValue]];
				if([vr isEqualToString:@"FL"]) field = [NSString stringWithFormat:@"%.6g", [field floatValue]];
				
				if([field isKindOfClass:[NSString class]])
				{
					if( result == nil) result = [NSMutableString stringWithString: field];
					else [result appendFormat: @" / %@", field];
				}
				else
				{
					if( result == nil) result = [NSMutableString stringWithString: [field stringValue]];
					else [result appendFormat: @" / %@", [field stringValue]];
				}
			}
			else if([field isKindOfClass:[NSCalendarDate class]])
			{
				NSString *vr = [attr vr];
				if([vr isEqualToString:@"DA"])
				{
					if( result == nil) result = [NSMutableString stringWithString: [BrowserController DateOfBirthFormat: field]];
					else [result appendFormat: @" / %@", [BrowserController DateOfBirthFormat: field]];
				}
				else if([vr isEqualToString:@"TM"])
				{
					if( result == nil) result = [NSMutableString stringWithString: [BrowserController TimeWithSecondsFormat: field]];
					else [result appendFormat: @" / %@", [BrowserController TimeWithSecondsFormat: field]];
				}
				else
				{
					if( result == nil) result = [NSMutableString stringWithString: [BrowserController DateTimeWithSecondsFormat: field]];
					else [result appendFormat: @" / %@", [BrowserController DateTimeWithSecondsFormat: field]];
				}
			}
		}
		
		return result;
	}
	return nil;
}

- (void)loadCustomImageAnnotationsPapyLink:(int)fileNb DCMLink:(DCMObject*)dcmObject
{
	NSDictionary *annotationsDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CUSTOM_IMAGE_ANNOTATIONS"];
	
	NSString *modality = [imageObj valueForKeyPath:@"series.modality"]; // imageObj = link to database
	NSDictionary *annotationsForModality = [annotationsDict objectForKey:modality];
	
	if(!annotationsForModality) annotationsForModality = [annotationsDict objectForKey:@"Default"];
	if([[annotationsForModality objectForKey:@"sameAsDefault"] intValue]==1) annotationsForModality = [annotationsDict objectForKey:@"Default"];
	
	// image sides (LowerLeft, LowerMiddle, LowerRight, MiddleLeft, MiddleRight, TopLeft, TopMiddle, TopRight) & sameAsDefault
	NSArray *keys = [annotationsForModality allKeys];
	
	for ( NSString *key in keys)
	{
		if(![key isEqualToString:@"sameAsDefault"])
		{
			NSArray *annotations = [annotationsForModality objectForKey: key];
			NSMutableArray *annotationsOUT = [NSMutableArray array];
			
			for ( NSDictionary *annot in annotations)
			{
				NSArray *content = [annot objectForKey:@"fullContent"];
				NSMutableArray *contentOUT = [NSMutableArray array];
				
				BOOL contentForLine = NO;
				for ( int f=0; f<[content count]; f++)
				{
					@try
					{
						NSDictionary *field = [content objectAtIndex:f];
						NSString *type = [field objectForKey:@"type"];
						NSString *value = nil;
						
						if( [type isEqualToString:@"DICOM"])
						{
							if( [[field objectForKey:@"group"] intValue] == 0x0018 && [[field objectForKey:@"element"] intValue] == 0x0080 && repetitiontime != 0L)	// RepetitionTime
							{
								value = [NSString stringWithFormat:@"%.6g", [repetitiontime floatValue]];
							}
							else if( [[field objectForKey:@"group"] intValue] == 0x0018 && [[field objectForKey:@"element"] intValue] == 0x0081 && echotime != 0L)	// Echotime
							{	
								value = [NSString stringWithFormat:@"%.6g", [echotime floatValue]];;
							}
							else if(fileNb>=0)
								value = [self getDICOMFieldValueForGroup:[[field objectForKey:@"group"] intValue] element:[[field objectForKey:@"element"] intValue] papyLink:fileNb];
							else if(dcmObject)
								value = [self getDICOMFieldValueForGroup:[[field objectForKey:@"group"] intValue] element:[[field objectForKey:@"element"] intValue] DCMLink:dcmObject];
							else
								value = nil;
								
							if( anonymizedAnnotations)
							{
								if( [[field objectForKey:@"group"] intValue] == 0x0010 && [[field objectForKey:@"element"] intValue] == 0x0010) value = @" ";
							}
							
							if(value==nil || [value length] == 0) value = @"-";
							else contentForLine = YES;
						}
						else if([type isEqualToString:@"DB"])
						{
							NSString *fieldName = [field objectForKey:@"field"];
							NSString *level = [field objectForKey:@"level"];
							if([level isEqualToString:@"image"])
							{
								value = [imageObj valueForKey:fieldName];
							}
							else if([level isEqualToString:@"series"])
							{
								value = [imageObj valueForKeyPath:[NSString stringWithFormat:@"series.%@", fieldName]];
							}
							else if([level isEqualToString:@"study"])
							{
								value = [imageObj valueForKeyPath:[NSString stringWithFormat:@"series.study.%@", fieldName]];
								
								if( anonymizedAnnotations)
								{
									if( [fieldName isEqualToString:@"name"]) value = @" ";
								}
							}
							
							if(value==nil) value = @"-";
							else contentForLine = YES;
							
							if( [value isKindOfClass: [NSDate class]])
							{
								if([fieldName isEqualToString:@"dateOfBirth"])
									value = [BrowserController DateOfBirthFormat: (NSDate *) value];
								else
									value = [BrowserController DateTimeWithSecondsFormat: (NSDate *) value];
							}
							else
							{
								value = [value description];
								if( [value length] == 0) value = @"-";
							}
						}
						else if([type isEqualToString:@"Special"])
						{
							value = [field objectForKey:@"field"];
							if ([value isEqualToString: NSLocalizedString(@"Patient's Actual Age", nil)] || [value isEqualToString: (@"Patient's Actual Age")])
							{
								NSDate *date = [imageObj valueForKeyPath: @"series.study.dateOfBirth"];
								
								if(date)
								{
									int age = -[date timeIntervalSinceNow]/(60*60*24*365);
									value = [NSString stringWithFormat:@"%d y", age];
								}
								else value = nil;
							}
							
							if ([value isEqualToString: NSLocalizedString(@"Patient's Age At Acquisition", nil)] || [value isEqualToString: (@"Patient's Age At Acquisition")])
							{
								NSDate *date1 = [imageObj valueForKeyPath: @"series.study.dateOfBirth"];
								NSDate *date2 = [imageObj valueForKeyPath: @"series.study.date"];
								
								if(date1 && date2)
								{
									int age = -[date1 timeIntervalSinceDate: date2]/(60*60*24*365);
									value = [NSString stringWithFormat:@"%d y", age];
								}
								else value = nil;
							}
							
							if(value==nil || [value length] == 0) value = @"-";
							else contentForLine = YES;
						}
						else if([type isEqualToString:@"Manual"])
						{
							value = [field objectForKey:@"field"];
							if(value==nil || [value length] == 0) value = @"-";
							
							if(![value isEqualToString:@""]) value = [value stringByAppendingString:@" "];
						}
						
						if( value) [contentOUT addObject:value];
					}
					
					@catch (NSException *e)
					{
						NSLog(@"CustomImageAnnotations Exception: %@", e);
					}
				}
				
				if( contentForLine)
				{
					if( contentOUT)
						[annotationsOUT addObject:contentOUT];
				}
			}
			if( annotationsOUT)
				[annotationsDictionary setObject:annotationsOUT forKey: key];
		}
	}
}
#endif

@end
