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

#import "DCMAbstractSyntaxUID.h"
#import "DCMView.h"
#import "StringTexture.h"
#import "DCMPix.h"
#import "ROI.h"
#import "NSFont_OpenGL.h"
#import "DCMCursor.h"
#import "GLString.h"
#import "DICOMExport.h"
#import "SeriesView.h"
#import "ViewerController.h"
#import "ThickSlabController.h"
#import "BrowserController.h"
#import "AppController.h"
#import "MPR2DController.h"
#import "MPR2DView.h"
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"
#import "OrthogonalMPRPETCTView.h"
#import "ROIWindow.h"
#import "ToolbarPanel.h"
#import "ThumbnailsListPanel.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#include <OpenGL/CGLMacro.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#import <CoreVideo/CoreVideo.h>
#import "DefaultsOsiriX.h"
#include "NSFont_OpenGL.h"
#import "Notifications.h"
#import "PluginManager.h"
#import "N2Debug.h"
#import "OSIEnvironment.h"
#import "OSIEnvironment+Private.h"
#import "DCMWaveform.h"
#import "DicomDatabase.h"
#import "NSFileManager+N2.h"
#import <QuartzCore/QuartzCore.h>

// kvImageHighQualityResampling
#define QUALITY kvImageNoFlags

#define BS 10.
//#define new_loupe

short						syncro = syncroLOC;
static		double						deg2rad = M_PI / 180.0;
static		unsigned char				*PETredTable = nil, *PETgreenTable = nil, *PETblueTable = nil;
static		BOOL						NOINTERPOLATION = NO, SOFTWAREINTERPOLATION = NO, IndependentCRWLWW, pluginOverridesMouse = NO;  // Allows plugins to override mouse click actions.
BOOL						FULL32BITPIPELINE = NO, gDontListenToSyncMessage = NO;
BOOL                        OVERFLOWLINES = NO;
int							CLUTBARS, MAXNUMBEROF32BITVIEWERS = 4, SOFTWAREINTERPOLATION_MAX, DISPLAYCROSSREFERENCELINES = YES;
static		BOOL						gClickCountSet = NO, avoidSetWLWWRentry = NO, gInvertColors = NO;
static		NSDictionary				*_hotKeyDictionary = nil, *_hotKeyModifiersDictionary = nil;
static		NSRecursiveLock				*drawLock = nil;
static		NSMutableArray				*globalStringTextureCache = nil;

NSString * const HorosPasteboardType = @"com.opensource.horos";
NSString * const HorosPasteboardTypePlugin = @"com.opensource.horos.plugin";

NSString * const pasteBoardOsiriX = @"OsiriX pasteboard"; // deprecated
NSString * const pasteBoardOsiriXPlugin = @"OsiriXPluginDataType"; // deprecated
NSString * const OsirixPluginPboardUTI = @"com.opensource.osirix.plugin.uti"; // deprecated
NSString * const pasteBoardHoros = @"Horos pasteboard"; // deprecated
NSString * const HorosPboardUTI = @"com.opensource.horos.uti"; // deprecated
NSString * const pasteBoardHorosPlugin = @"HorosPluginDataType"; // deprecated
NSString * const HorosPluginPboardUTI = @"com.opensource.horos.plugin.uti"; // deprecated

// intersect3D_SegmentPlane(): intersect a segment and a plane
//    Input:  S = a segment, and Pn = a plane = {Point V0; Vector n;}
//    Output: *I0 = the intersect point (when it exists)
//    Return: 0 = disjoint (no intersection)
//            1 = intersection in the unique point *I0
//            2 = the segment lies in the plane

#define SMALL_NUM  0.00000001 // anything that avoids division overflow
#define DOT(v1,v2) (v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2])

int intersect3D_SegmentPlane( float *P0, float *P1, float *Pnormal, float *Ppoint, float* resultPt )
{
    float    u[ 3];
    float    w[ 3];
    
    u[ 0]  = P1[ 0] - P0[ 0];
    u[ 1]  = P1[ 1] - P0[ 1];
    u[ 2]  = P1[ 2] - P0[ 2];
    
    w[ 0] =  P0[ 0] - Ppoint[ 0];
    w[ 1] =  P0[ 1] - Ppoint[ 1];
    w[ 2] =  P0[ 2] - Ppoint[ 2];
    
    float     D = DOT(Pnormal, u);
    float     N = -DOT(Pnormal, w);
    
    if (fabs(D) < SMALL_NUM) {          // segment is parallel to plane
        if (N == 0)                     // segment lies in plane
            return 0;
        else
            return 0;                   // no intersection
    }
    
    // they are not parallel
    // compute intersect param
    
    float sI = N / D;
    if (sI < 0 || sI > 1)
        return 0;						// no intersection
    
    resultPt[ 0] = P0[ 0] + sI * u[ 0];		// compute segment intersect point
    resultPt[ 1] = P0[ 1] + sI * u[ 1];
    resultPt[ 2] = P0[ 2] + sI * u[ 2];
    
    if( D > 0) return 1;
    else return 2;
}


#define CROSS(dest,v1,v2) \
dest[0]=v1[1]*v2[2]-v1[2]*v2[1]; \
dest[1]=v1[2]*v2[0]-v1[0]*v2[2]; \
dest[2]=v1[0]*v2[1]-v1[1]*v2[0];

#define DOT(v1,v2) (v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2])

#define SUB(dest,v1,v2) dest[0]=v1[0]-v2[0]; \
dest[1]=v1[1]-v2[1]; \
dest[2]=v1[2]-v2[2];

void Normalise(XYZ *p)
{
    double length;
    
    length = sqrt(p->x * p->x + p->y * p->y + p->z * p->z);
    if (length != 0) {
        p->x /= length;
        p->y /= length;
        p->z /= length;
    } else {
        p->x = 0;
        p->y = 0;
        p->z = 0;
    }
}

XYZ ArbitraryRotate(XYZ p,double theta,XYZ r)
{
    XYZ q = {0.0,0.0,0.0};
    double costheta,sintheta;
    
    Normalise(&r);
    
    costheta = cos(theta);
    sintheta = sin(theta);
    
    q.x += (costheta + (1.0 - costheta) * r.x * r.x) * p.x;
    q.x += ((1.0 - costheta) * r.x * r.y - r.z * sintheta) * p.y;
    q.x += ((1.0 - costheta) * r.x * r.z + r.y * sintheta) * p.z;
    
    q.y += ((1.0 - costheta) * r.x * r.y + r.z * sintheta) * p.x;
    q.y += (costheta + (1.0 - costheta) * r.y * r.y) * p.y;
    q.y += ((1.0 - costheta) * r.y * r.z - r.x * sintheta) * p.z;
    
    q.z += ((1.0 - costheta) * r.x * r.z - r.y * sintheta) * p.x;
    q.z += ((1.0 - costheta) * r.y * r.z + r.x * sintheta) * p.y;
    q.z += (costheta + (1.0 - costheta) * r.z * r.z) * p.z;
    
    return(q);
}

short intersect3D_2Planes( float *Pn1, float *Pv1, float *Pn2, float *Pv2, float *u, float *iP)
{
    CROSS(u, Pn1, Pn2);         // cross product -> perpendicular vector
    
    float    ax = (u[0] >= 0 ? u[0] : -u[0]);
    float    ay = (u[1] >= 0 ? u[1] : -u[1]);
    float    az = (u[2] >= 0 ? u[2] : -u[2]);
    
    
    if( [DCMView angleBetweenVector: Pn1 andVector:Pn2] < [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"])
        return -1;
    
    // Pn1 and Pn2 intersect in a line
    // first determine max abs coordinate of cross product
    int maxc;                      // max coordinate
    if (ax > ay)
    {
        if (ax > az)
            maxc = 1;
        else
            maxc = 3;
    }
    else
    {
        if (ay > az)
            maxc = 2;
        else
            maxc = 3;
    }
    
    // next, to get a point on the intersect line
    // zero the max coord, and solve for the other two
    
    float    d1, d2;            // the constants in the 2 plane equations
    d1 = -DOT(Pn1, Pv1); 		// note: could be pre-stored with plane
    d2 = -DOT(Pn2, Pv2); 		// ditto
    
    switch (maxc)
    {            // select max coordinate
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
    
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
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
    
    if( rect.size.width == 0 || rect.size.height == 0) return NO;
    
    CGFloat width = fabs(lineStarts.x - lineEnds.x);
    CGFloat height = fabs(lineStarts.y - lineEnds.y);
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

NSInteger studyCompare(ViewerController *v1, ViewerController *v2, void *context)
{
    NSDate *d1 = [[v1 currentStudy] valueForKey:@"date"];
    NSDate *d2 = [[v2 currentStudy] valueForKey:@"date"];
    
    if( d1 == nil || d2 == nil)
    {
        NSLog( @"d1 == nil || d2 == nil : studyCompare");
        
        return NSOrderedSame;
    }
    
    return [d2 compare: d1];
}

@implementation DCMExportPlugin
- (void) finalize:(DCMObject*) dcmDst withSourceObject:(DCMObject*) dcmObject
{
    
}

- (NSString*) seriesName
{
    return nil;
}
@end

@interface DCMView (Dummy)

- (void)setFontColor:(id)dummy;

@end

@implementation DCMView

@synthesize showDescriptionInLarge, curRoiList;
@synthesize drawingFrameRect;
@synthesize rectArray, studyColorR, studyColorG, studyColorB, studyDateIndex;
@synthesize flippedData, whiteBackground, timeIntervalForDrag;
@synthesize dcmPixList;
@synthesize dcmFilesList;
@synthesize dcmRoiList;
@synthesize syncSeriesIndex;
@synthesize syncRelativeDiff;
@synthesize blendingMode, blendingView, blendingFactor;
@synthesize xFlipped, yFlipped;
@synthesize stringID;
@synthesize currentTool, currentToolRight;
@synthesize curImage;
@synthesize theMatrix = matrix;
@synthesize suppressLabels = suppress_labels;
@synthesize scaleValue, rotation;
@synthesize origin;
@synthesize curDCM;
@synthesize dcmExportPlugin;
@synthesize mouseXPos, mouseYPos;
@synthesize contextualMenuInWindowPosX, contextualMenuInWindowPosY;
@synthesize fontListGL, fontGL;
@synthesize tag = _tag;
@synthesize curWW, curWL;
@synthesize rows = _imageRows, columns = _imageColumns;
@synthesize cursor;
@synthesize eraserFlag;
@synthesize drawing;
@synthesize volumicSeries;
@synthesize isKeyView, mouseDragging;
@synthesize annotationType;

- (BOOL) eventToPlugins: (NSEvent*) event
{
    BOOL used = NO;
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(handleEvent:forViewer:)])
            if ([[[PluginManager plugins] objectForKey:key] handleEvent:event forViewer:[self windowController]])
                used = YES;
    }
    
    return used;
}

+ (void) setDontListenToSyncMessage: (BOOL) v
{
    gDontListenToSyncMessage = v;
    
    if( gDontListenToSyncMessage == NO)
        [[[ViewerController frontMostDisplayed2DViewer] imageView] sendSyncMessage: 0];
}

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
    NSDictionary *wlwwPresets = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
    
    for( NSString *key in [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"])
    {
        NSArray *value = [wlwwPresets objectForKey: key];
        
        if( [[value objectAtIndex: 0] floatValue] == wl && [[value objectAtIndex: 1] floatValue] == ww)
            return key;
    }
    
    if( pix)
    {
        if( wl == pix.fullwl && ww == pix.fullww) return NSLocalizedString( @"Full dynamic", nil);
        if( wl == pix.savedWL && ww == pix.savedWW) return NSLocalizedString(@"Default WL & WW", nil);
    }
    
    return NSLocalizedString( @"Other", nil);
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
    
    //	[_hotKeyModifiersDictionary release];
    //	_hotKeyModifiersDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYSMODIFIERS"] retain];
    
    [_hotKeyDictionary release];
    _hotKeyDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYS"] retain];
    
    NOINTERPOLATION = [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"];
    FULL32BITPIPELINE = [[NSUserDefaults standardUserDefaults] boolForKey:@"FULL32BITPIPELINE"];
    MAXNUMBEROF32BITVIEWERS = [[NSUserDefaults standardUserDefaults] integerForKey: @"MAXNUMBEROF32BITVIEWERS"];
    OVERFLOWLINES = [[NSUserDefaults standardUserDefaults] boolForKey:@"OVERFLOWLINES"];
    
    SOFTWAREINTERPOLATION = [[NSUserDefaults standardUserDefaults] boolForKey:@"SOFTWAREINTERPOLATION"];
    SOFTWAREINTERPOLATION_MAX = [[NSUserDefaults standardUserDefaults] integerForKey:@"SOFTWAREINTERPOLATION_MAX"];
    DISPLAYCROSSREFERENCELINES = [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayCrossReferenceLines"];
    
    IndependentCRWLWW = [[NSUserDefaults standardUserDefaults] boolForKey:@"IndependentCRWLWW"];
    CLUTBARS = [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
    
    //	int previousANNOTATIONS = ANNOTATIONS;
    //	ANNOTATIONS = [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
    //
    //	BOOL reload = NO;
    //
    //	if( previousANNOTATIONS != ANNOTATIONS)
    //	{
    //		for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    //		{
    //			[v refresh];
    //
    //			NSArray	*relatedViewers = [[AppController sharedAppController] FindRelatedViewers: [v pixList]];
    //			for( NSWindowController *r in relatedViewers)
    //				[[r window] display];
    //		}
    //
    //		if( reload) [[BrowserController currentBrowser] refreshMatrix: self];		// This will refresh the DCMView of the BrowserController
    //	}
    //	else
    //	{
    //		for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    //		{
    //			[[[v window] contentView] setNeedsDisplay: YES];
    //		}
    //	}
}

+(void) setCLUTBARS:(int) c ANNOTATIONS:(int) a
{
    CLUTBARS = c;
    
    NSArray *viewers = [ViewerController getDisplayed2DViewers];
    
    for( ViewerController *v in viewers)
    {
        for( DCMView *vi in v.imageViews)
            vi.annotationType = a;
        
        [v refresh];
    }
}

+ (BOOL) noPropagateSettingsInSeriesForModality: (NSString*) m
{
    if( IndependentCRWLWW &&
       [[NSUserDefaults standardUserDefaults] boolForKey: [NSString stringWithFormat: @"noPropagateInSeriesFor%@", m]])
        return YES;
    else
        return NO;
}

+ (NSSize) sizeOfString:(NSString *)string forFont:(NSFont *)font
{
    if( string == nil) string = @"";
    
    NSDictionary *attr = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:string attributes:attr] autorelease];
    return [attrString size];
}

//+ (void) hideOverlayWindows
//{
//	[overlayWindows removeAllObjects];
//}
//
//+ (void) showOverlayWindows
//{
//	if( overlayWindows == nil) overlayWindows = [[NSMutableArray array] retain];
//
//	if( [overlayWindows count] == 0)
//	{
//		NSMutableArray *screens = [NSMutableArray array];
//
//		for( ViewerController *v in [ViewerController getDisplayed2DViewers])
//		{
//			if( [screens containsObject: [[v window] screen]] == NO)
//				[screens addObject: [[v window] screen]];
//		}
//
//		for( NSScreen *s in screens)
//		{
//			NSWindow *newWindow = [[[NSWindow alloc] initWithContentRect: [s visibleFrame]
//															  styleMask: NSBorderlessWindowMask
//																backing: NSBackingStoreBuffered
//																  defer: NO
//																 screen: s] autorelease];
//			// Define new window
//			[newWindow setBackgroundColor:[NSColor blackColor]];
//			[newWindow setAlphaValue:0.2];
//			[newWindow setLevel:NSScreenSaverWindowLevel-2];
//			[newWindow makeKeyAndOrderFront:nil];
//
//			[overlayWindows addObject: newWindow];
//		}
//	}
//}

- (void) computeColor
{
    if( [self is2DViewer] == NO)
        return;
    
    @try
    {
        NSArray *viewers = [[ViewerController getDisplayed2DViewers] sortedArrayUsingFunction: studyCompare context: nil];
        
        NSMutableArray *studiesArray = [NSMutableArray array];
        NSMutableDictionary *colorsStudy = [NSMutableDictionary dictionary];
        
        for( ViewerController *v in viewers)
        {
            if( [v currentStudy] && [v currentSeries])
                [studiesArray addObject: [v currentStudy]];
            
            for( DCMView *view in v.imageViews)
            {
                view.studyColorR = view.studyColorG = view.studyColorB = 0;
                view.studyDateIndex = NSNotFound;
                [view setNeedsDisplay: YES];
            }
        }
        
        if( studiesArray.count)
        {
            DicomStudy *study = [self studyObj];
            NSArray *allStudiesArray = nil;
            
            // Use the 'history' array of the browser controller, if available (with the distant studies)
            if( [[[BrowserController currentBrowser] comparativePatientUID] compare: [study patientUID] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame && [[BrowserController currentBrowser] comparativeStudies] != nil)
                allStudiesArray = [BrowserController currentBrowser].comparativeStudies;
            else
            {
                DicomDatabase *db = [[BrowserController currentBrowser] database];
                NSPredicate *predicate = nil;
                
                // FIND ALL STUDIES of this patient
                NSString *searchString = [study valueForKey:@"patientUID"];
                
                if( [searchString length] == 0 || [searchString isEqualToString:@"0"])
                {
                    searchString = [study valueForKey:@"name"];
                    predicate = [NSPredicate predicateWithFormat: @"(name == %@)", searchString];
                }
                else predicate = [NSPredicate predicateWithFormat: @"(patientUID BEGINSWITH[cd] %@)", searchString];
                
                allStudiesArray = [db objectsForEntity:db.studyEntity predicate:predicate];
                allStudiesArray = [allStudiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"date" ascending: NO]]];
            }
            
            allStudiesArray = [allStudiesArray valueForKey: @"studyInstanceUID"];
            NSArray *colors = ViewerController.studyColors;
            // Give a different color for each study/patient
            
            for( id study in studiesArray)
            {
                NSString *studyUID = [study valueForKey:@"studyInstanceUID"];
                
                if( [colorsStudy objectForKey: studyUID] == nil)
                {
                    NSUInteger color = [allStudiesArray indexOfObject: studyUID];
                    
                    if( color != NSNotFound)
                    {
                        if( color >= colors.count) color = colors.count-1;
                        [colorsStudy setObject: [colors objectAtIndex: color] forKey: studyUID];
                    }
                }
                
            }
            
            if( allStudiesArray.count > 1)
            {
                for( ViewerController *v in viewers)
                {
                    NSColor *boxColor = [colorsStudy objectForKey: [v studyInstanceUID]];
                    
                    for( DCMView *view in v.imageViews)
                    {
                        view.studyColorR = [boxColor redComponent];
                        view.studyColorG = [boxColor greenComponent];
                        view.studyColorB = [boxColor blueComponent];
                        view.studyDateIndex = [allStudiesArray indexOfObject: [v studyInstanceUID]];
                        [view setNeedsDisplay: YES];
                    }
                }
            }
        }
    }
    
    @catch (NSException *e)
    {
        NSLog( @"**** computeColor exception: %@", e);
    }
}

- (void) reapplyWindowLevel
{
    if( curWL != 0 && curWW != 0 && curWLWWSUVConverted != curDCM.SUVConverted)
    {
        if( curWLWWSUVFactor > 0)
        {
            if( curWLWWSUVConverted)
            {
                curWL /= curWLWWSUVFactor;
                curWW /= curWLWWSUVFactor;
            }
            else
            {
                curWLWWSUVFactor = 1.0;
                if( curWLWWSUVConverted && [self is2DViewer])
                    curWLWWSUVFactor = [[self windowController] factorPET2SUV];
                
                curWL *= curWLWWSUVFactor;
                curWW *= curWLWWSUVFactor;
            }
        }
        
        curWLWWSUVConverted = curDCM.SUVConverted;
        curWLWWSUVFactor = 1.0;
        if( curWLWWSUVConverted && [self is2DViewer])
            curWLWWSUVFactor = [[self windowController] factorPET2SUV];
    }
    
    [curDCM changeWLWW :curWL :curWW];
}

- (BOOL) isKeyImage
{
    BOOL result = NO;
    
    if( [[self windowController] isMemberOfClass:[ViewerController class]])
        result = [[self windowController] isKeyImage:curImage];
    
    return result;
}

- (void) updateTilingViews
{
    if( [self is2DViewer] && [[self window] isVisible])
    {
        if( [[self windowController] updateTilingViewsValue] == NO)
        {
            [[self windowController] setUpdateTilingViewsValue: YES];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:curImage]  forKey:@"curImage"];
            [[NSNotificationCenter defaultCenter]  postNotificationName: OsirixDCMUpdateCurrentImageNotification object: self userInfo: userInfo];
            
            [[self windowController] setUpdateTilingViewsValue : NO];
        }
    }
}

- (DCMPix*) mergeFused
{
    float oScale = 1.0; // The back image is at full resolution
    float scaleRatio = 1.0 / [self scaleValue];
    float blendingScale = [blendingView scaleValue] * scaleRatio;
    
    DCMPix *fusedPix = [[blendingView curDCM] renderWithRotation: [blendingView rotation] scale: blendingScale xFlipped: [blendingView xFlipped] yFlipped: [blendingView yFlipped]];
    DCMPix *originalPix = [curDCM renderWithRotation: [self rotation] scale: oScale xFlipped: [self xFlipped] yFlipped: [self yFlipped]];
    
    NSPoint oo = [blendingView origin];
    oo.x *= scaleRatio;
    oo.y *= scaleRatio;
    
    if( [blendingView xFlipped]) oo.x = - oo.x;
    if( [blendingView yFlipped]) oo.y = - oo.y;
    oo = [DCMPix rotatePoint: oo aroundPoint:NSMakePoint( 0, 0) angle: -[blendingView rotation]*deg2rad];
    
    NSPoint cc = [self origin];
    cc.x *= scaleRatio;
    cc.y *= scaleRatio;
    
    if( [self xFlipped]) cc.x = - cc.x;
    if( [self yFlipped]) cc.y = - cc.y;
    cc = [DCMPix rotatePoint: cc aroundPoint:NSMakePoint( 0, 0) angle: -[self rotation]*deg2rad];
    
    oo.x -= cc.x;
    oo.y -= cc.y;
    oo.y = -oo.y;
    
    DCMPix *newPix = [originalPix mergeWithDCMPix: fusedPix offset: oo];
    
    return newPix;
}

- (IBAction) mergeFusedImages:(id)sender
{
    BOOL applyToEntireSeries = NO;
    
    if( [blendingView volumicSeries] && [self volumicSeries]) applyToEntireSeries = YES;
    
    NSMutableArray *pixA = [NSMutableArray array];
    NSMutableArray *objA = [NSMutableArray array];
    
    NSMutableData	*newData = nil;
    
    if( applyToEntireSeries)
    {
        newData = [NSMutableData data];
        
        for( int i = 0 ; i < [dcmPixList count]; i++)
        {
            [self setIndex: i];
            [self sendSyncMessage: 1];
            [[self windowController] propagateSettings];
            
            [pixA addObject:  [self mergeFused]];
            [objA addObject: [[pixA lastObject] imageObj]];
            
            [newData appendBytes: [[pixA lastObject] fImage] length: [[pixA lastObject] pheight] * [[pixA lastObject] pwidth]*sizeof(float)];
        }
        
        for( int i = 0 ; i < [dcmPixList count]; i++)
        {
            [[pixA objectAtIndex: i] setfImage: (float*) ([newData bytes] + [[pixA lastObject] pheight] * [[pixA lastObject] pwidth]*sizeof(float) * i)];
            [[pixA objectAtIndex: i] freefImageWhenDone: NO];
        }
    }
    else
    {
        [pixA addObject:  [self mergeFused]];
        [objA addObject: [[pixA lastObject] imageObj]];
        
        newData = [NSMutableData dataWithBytes: [[pixA lastObject] fImage] length: [[pixA lastObject] pheight] * [[pixA lastObject] pwidth]*sizeof(float)];
        
        [[pixA lastObject] setfImage: (float*) [newData bytes]];
        [[pixA lastObject] freefImageWhenDone: NO];
    }
    
    [[self windowController] close];
    
    [ViewerController newWindow
     : pixA
     : objA
     : newData];
}

- (IBAction) print:(id)sender
{
    if ([self is2DViewer] == YES)
    {
        [[self windowController] print: self];
    }
    else
    {
        NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
        
        NSLog(@"Orientation %d", (int) [printInfo orientation]);
        
        NSImage *im = [self nsimage: NO];
        
        NSLog( @"w:%f, h:%f", [im size].width, [im size].height);
        
        if ([im size].height < [im size].width)
            [printInfo setOrientation: NSPaperOrientationLandscape];
        else
            [printInfo setOrientation: NSPaperOrientationPortrait];
        
        //NSRect	r = NSMakeRect( 0, 0, [printInfo paperSize].width, [printInfo paperSize].height);
        
        NSRect	r = NSMakeRect( 0, 0, [im size].width/2, [im size].height/2);
        
        NSImageView *imageView = [[NSImageView alloc] initWithFrame: r];
        
        //	r = NSMakeRect( 0, 0, [im size].width, [im size].height);
        
        //	NSWindow	*pwindow = [[NSWindow alloc]  initWithContentRect: r styleMask: NSBorderlessWindowMask backing: NSBackingStoreNonretained defer: NO];
        
        //	[pwindow setContentView: imageView];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [im setScalesWhenResized:YES];
#pragma clang diagnostic pop

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
        if( display2DPointIndex == curImage)
        {
            CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
            if( cgl_ctx == nil)
                return;
            
            glColor3f (0.0f, 0.5f, 1.0f);
            glLineWidth(2.0 * self.window.backingScaleFactor);
            glBegin(GL_LINES);
            
            float crossx, crossy;
            
            crossx = display2DPoint.x - curDCM.pwidth/2.;
            crossy = display2DPoint.y - curDCM.pheight/2.;
            
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
        else
        {
            display2DPoint.x = 0;
            display2DPoint.y = 0;
        }
    }
}

- (void)drawRepulsorToolArea;
{
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
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
    
    NSPoint pt = repulsorPosition;
    pt = [self convertPointToBacking: pt];
    
    pt.y = [self drawingFrameRect].size.height - pt.y;		// inverse Y scaling system
    
    glBegin(GL_POLYGON);
    for(i = 0; i < circleRes ; i++)
    {
        // M_PI defined in cmath.h
        float alpha = i * 2 * M_PI /circleRes;
        glVertex2f( pt.x + repulsorRadius*cos(alpha)*scaleValue, pt.y + repulsorRadius*sin(alpha)*scaleValue);//*curDCM.pixelSpacingY/curDCM.pixelSpacingX
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
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
    glEnable(GL_BLEND);
    glDisable(GL_POLYGON_SMOOTH);
    glDisable(GL_POINT_SMOOTH);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glLineWidth( 1 * self.window.backingScaleFactor);
    
#define ROISELECTORREGION_R 0.8
#define ROISELECTORREGION_G 0.8
#define ROISELECTORREGION_B 1.0
    
    NSPoint startPt = ROISelectorStartPoint, endPt = ROISelectorEndPoint;
    
    startPt = [self convertPointToBacking: startPt];
    endPt = [self convertPointToBacking: endPt];
    
    // inside: fill
    glColor4f(ROISELECTORREGION_R, ROISELECTORREGION_G, ROISELECTORREGION_B, 0.3);
    glBegin(GL_POLYGON);
    glVertex2f(startPt.x, startPt.y);
    glVertex2f(startPt.x, endPt.y);
    glVertex2f(endPt.x, endPt.y);
    glVertex2f(endPt.x, startPt.y);
    glEnd();
    
    // border
    glColor4f(ROISELECTORREGION_R, ROISELECTORREGION_G, ROISELECTORREGION_B, 0.75);
    glBegin(GL_LINE_LOOP);
    glVertex2f(startPt.x, startPt.y);
    glVertex2f(startPt.x, endPt.y);
    glVertex2f(endPt.x, endPt.y);
    glVertex2f(endPt.x, startPt.y);
    glEnd();
    
    glDisable(GL_BLEND);
}

- (void) Display3DPoint:(NSNotification*) note
{
    if( stringID == nil)
    {
        NSMutableArray	*v = [note object];
        
        if( v == dcmPixList)
        {
            display2DPoint.x = [[[note userInfo] valueForKey:@"x"] intValue];
            display2DPoint.y = [[[note userInfo] valueForKey:@"y"] intValue];
            display2DPointIndex = [[[note userInfo] valueForKey:@"z"] intValue];
            
            [self setIndex: [[[note userInfo] valueForKey:@"z"] intValue]];
            
            [self sendSyncMessage: 0];
            [self setNeedsDisplay: YES];
        }
    }
}

-(OrthogonalMPRController*) controller
{
    return nil;	// Only defined in herited classes
}

- (void) stopROIEditingForce:(BOOL) force
{
    long no;
    
    drawingROI = NO;
    for( ROI *r in curRoiList)
    {
        if( curROI != r )
        {
            if( [r ROImode] == ROI_selectedModify || [r ROImode] == ROI_drawing)
                [r setROIMode: ROI_selected];
        }
    }
    
    if( curROI )
    {
        if( [curROI ROImode] == ROI_selectedModify || [curROI ROImode] == ROI_drawing)
        {
            no = 0;
            
            // Does this ROI have alias in other views?
            for( NSArray *r in dcmRoiList)
            {
                if( [r containsObject: curROI]) no++;
            }
            
            if( no <= 1 || force == YES)
            {
                curROI.ROImode = ROI_selected;
                
                if( [curROI valid] == NO)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object: curROI userInfo: nil];
                    
                    @try
                    {
                        [curRoiList removeObject: curROI];
                    }
                    @catch (NSException * e) {}
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIRemovedFromArrayNotification object:NULL userInfo:NULL];
                }
                
                [curROI autorelease];
                curROI = nil;
            }
        }
        else
        {
            curROI.ROImode = ROI_selected;
            [curROI autorelease];
            curROI = nil;
        }
    }
    
    if( showDescriptionInLarge)
    {
        showDescriptionInLarge = NO;
        [self switchShowDescriptionInLarge];
    }
}

- (void) stopROIEditing
{
    [self stopROIEditingForce: NO];
}

- (void) blendingPropagate
{
    if( blendingView)
    {
        blendingView.scaleValue = scaleValue;
        
        blendingView.rotation = rotation;
        [blendingView setOrigin: origin];
    }
}

- (void) roiLoadFromFilesArray: (NSArray*) filenames
{
    // Unselect all ROIs
    for( ROI *r in curRoiList) [r setROIMode: ROI_sleep];
    
    for( NSString *path in filenames)
    {
        NSMutableArray*    roiArray = [NSUnarchiver unarchiveObjectWithFile: path];
        
        for( id loopItem1 in roiArray)
        {
            [loopItem1 setOriginAndSpacing:curDCM.pixelSpacingX :curDCM.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: curDCM]];
            [loopItem1 setROIMode:ROI_selected];
            [loopItem1 setCurView:self];
            
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object: loopItem1 userInfo: nil];
        }
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"markROIImageAsKeyImage"])
        {
            if( [self is2DViewer] == YES && [self isKeyImage] == NO && [[self windowController] isPostprocessed] == NO)
                [[self windowController] setKeyImage: self];
        }
        
        [curRoiList addObjectsFromArray: roiArray];
    }
    
    [self setNeedsDisplay:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    BOOL valid = NO;
    
    if ([item action] == @selector(roiSaveSelected:) || [item action] == @selector(increaseThickness:) || [item action] == @selector(decreaseThickness:))
    {
        for( ROI *r in curRoiList)
        {
            if( [r ROImode] == ROI_selected) valid = YES;
        }
    }
    else if( [item action] == @selector(copy:) && [item tag] == 1) // copy all viewers
    {
        if( [ViewerController numberOf2DViewer] > 1)
            valid = YES;
    }
    else if( [item action] == @selector(switchCopySettingsInSeries:))
    {
        valid = YES;
        [item setState: COPYSETTINGSINSERIES];
    }
    else if( [item action] == @selector(flipHorizontal:))
    {
        valid = YES;
        [item setState: xFlipped];
    }
    else if( [item action] == @selector(flipVertical:))
    {
        valid = YES;
        [item setState: yFlipped];
    }
    else if( [item action] == @selector(syncronize:))
    {
        valid = YES;
        if( [item tag] == syncro) [item setState: NSOnState];
        else [item setState: NSOffState];
    }
    else if( [item action] == @selector(mergeFusedImages:))
    {
        if( blendingView) valid = YES;
    }
    else if( [item action] == @selector(annotMenu:))
    {
        valid = YES;
        if( [item tag] == [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"]) [item setState: NSOnState];
        else [item setState: NSOffState];
    }
    else if( [item action] == @selector(barMenu:))
    {
        valid = YES;
        if( [item tag] == [[NSUserDefaults standardUserDefaults] integerForKey:@"CLUTBARS"]) [item setState: NSOnState];
        else [item setState: NSOffState];
    }
    else valid = YES;
    
    if( showDescriptionInLarge)
    {
        showDescriptionInLarge = NO;
        [self switchShowDescriptionInLarge];
    }
    
    return valid;
}

- (IBAction) roiSaveSelected: (id) sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    NSMutableArray *selectedROIs = [NSMutableArray  array];
    
    for (ROI *r in curRoiList)
    {
        if ([r ROImode] == ROI_selected)
            [selectedROIs addObject:r];
    }
    
    if ([selectedROIs count] > 0)
    {
        [panel setCanSelectHiddenExtension:NO];
        panel.allowedFileTypes = @[@"roi"];
        panel.nameFieldStringValue = [[selectedROIs objectAtIndex:0] name];
        
        [panel beginWithCompletionHandler:^(NSInteger result) {
            if (result != NSFileHandlingPanelOKButton)
                return;
            
            [NSArchiver archiveRootObject:selectedROIs toFile:panel.URL.path];
        }];
    }
    else
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Save Error",nil), NSLocalizedString(@"No ROI(s) selected to save!",nil) , NSLocalizedString(@"OK",nil), nil, nil);
}

- (void) roiLoadFromXML: (NSDictionary *) xml
{
    // Single ROI
    
    if( [xml valueForKey: @"Slice"])
    {
        [self setIndex: [[xml valueForKey: @"Slice"] intValue] - 1];
        
        if( [self is2DViewer] == YES)
            [[self windowController] adjustSlider];
        
        // SYNCRO
        [self sendSyncMessage: 0];
        
        [self setNeedsDisplay:YES];
    }
    
    NSArray *pointsStringArray = [xml objectForKey: @"ROIPoints"];
    
    ToolMode type = tCPolygon;
    if( [pointsStringArray count] == 2) type = tMesure;
    if( [pointsStringArray count] == 1) type = t2DPoint;
    
    ROI *roi = [[[ROI alloc] initWithType: type :curDCM.pixelSpacingX :curDCM.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: curDCM]] autorelease];
    roi.name = [xml objectForKey: @"Name"];
    roi.comments = [xml objectForKey: @"Comments"];
    
    NSMutableArray *pointsArray = [NSMutableArray array];
    
    if( type == t2DPoint)
    {
        NSRect irect;
        irect.origin.x = NSPointFromString( [pointsStringArray objectAtIndex: 0] ).x;
        irect.origin.y = NSPointFromString( [pointsStringArray objectAtIndex: 0] ).y;
        [roi setROIRect:irect];
    }
    
    if( [pointsStringArray count] > 0 )
    {
        for ( int j = 0; j < [pointsStringArray count]; j++ )
        {
            MyPoint *pt = [MyPoint point: NSPointFromString( [pointsStringArray objectAtIndex: j] )];
            [pointsArray addObject: pt];
        }
        
        roi.points = pointsArray;
        roi.ROImode = ROI_selected;
        [roi setCurView:self];
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"markROIImageAsKeyImage"])
        {
            if( [self is2DViewer] == YES && [self isKeyImage] == NO && [[self windowController] isPostprocessed] == NO)
                [[self windowController] setKeyImage: self];
        }
        
        [curRoiList addObject: roi];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object: roi userInfo: nil];
    }
}

- (IBAction) roiLoadFromXMLFiles: (NSArray*) filenames
{
    int	i;
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotNone)
    {
        [[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
        [DCMView setDefaults];
    }
    
    // Unselect all ROIs
    for( ROI *r in curRoiList) [r setROIMode: ROI_sleep];
    
    for( i = 0; i < [filenames count]; i++)
    {
        NSDictionary *xml = [NSDictionary dictionaryWithContentsOfFile: [filenames objectAtIndex:i]];
        NSArray* roiArray = [xml objectForKey: @"ROI array"];
        
        if( roiArray)
        {
            for( NSDictionary *x in roiArray)
                [self roiLoadFromXML: x];
        }
        else
            [self roiLoadFromXML: xml];
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

#ifndef OSIRIX_LIGHT
- (void)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSData *archived_data = [pb dataForType:@"ROIObject"];
    
    if( archived_data)
    {
        [[self windowController] addToUndoQueue:@"roi"];
        
        NSMutableArray*	roiArray = [NSUnarchiver unarchiveObjectWithData: archived_data];
        
        // Unselect all ROIs
        for( ROI *r in curRoiList) [r setROIMode: ROI_sleep];
        
        for( ROI *r in roiArray)
        {
            r.isAliased = NO;
            
            //Correct the origin only if the orientation is the same
            r.pix = curDCM;
            [r setOriginAndSpacing :curDCM.pixelSpacingX : curDCM.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: curDCM]];
            
            [r setROIMode: ROI_selected];
            [r setCurView:self];
        }
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"markROIImageAsKeyImage"])
        {
            if( [self is2DViewer] == YES && [self isKeyImage] == NO && [[self windowController] isPostprocessed] == NO)
                [[self windowController] setKeyImage: self];
        }
        
        [curRoiList addObjectsFromArray: roiArray];
        
        for( long i = 0 ; i < [roiArray count] ; i++) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[roiArray objectAtIndex: i], @"ROI",
                                      [NSNumber numberWithInt:curImage],	@"sliceNumber",
                                      //xx, @"x", yy, @"y", zz, @"z",
                                      nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixAddROINotification object: self userInfo:userInfo];
        }
        
        
        for( long i = 0 ; i < [roiArray count] ; i++)
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object: [roiArray objectAtIndex: i] userInfo: nil];
        
        [self setNeedsDisplay:YES];
    }
    
    id winCtrl = self.windowController;
    if ([winCtrl respondsToSelector:@selector(paste:)])
        [winCtrl paste: sender];
}
#endif

-(IBAction) copy:(id) sender
{
    NSPasteboard	*pb = [NSPasteboard generalPasteboard];
    BOOL			roiSelected = NO;
    NSMutableArray  *roiSelectedArray = [NSMutableArray array];
    
    for( ROI *r in curRoiList)
    {
        if( [r ROImode] == ROI_selected)
        {
            roiSelected = YES;
            
            [roiSelectedArray addObject: r];
        }
    }
    
    if( roiSelected == NO || [sender tag])
    {
        NSImage *im;
        
        [pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeTIFF] owner:self];
        
        im = [self nsimage: NO allViewers: [sender tag]];
        
        [pb setData: [[NSBitmapImageRep imageRepWithData: [im TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] forType:NSPasteboardTypeTIFF];
    }
    else
    {
        [pb declareTypes:[NSArray arrayWithObjects:@"ROIObject", NSPasteboardTypeString, nil] owner:nil];
        [pb setData: [NSArchiver archivedDataWithRootObject: roiSelectedArray] forType:@"ROIObject"];
        
        NSMutableString *r = [NSMutableString string];
        
        for( long i = 0 ; i < [roiSelectedArray count] ; i++ )
        {
            [r appendString: [[roiSelectedArray objectAtIndex: i] description]];
            
            if( i != (long)[roiSelectedArray count]-1)
                [r appendString:@"\r"];
        }
        
        [pb setString: r  forType:NSPasteboardTypeString];
    }
}

-(IBAction) cut:(id) sender
{
    [self copy:sender];
    
    long	i;
    NSTimeInterval groupID;
    
    [[self windowController] addToUndoQueue:@"roi"];
    
    [drawLock lock];
    
    NSMutableArray *rArray = curRoiList;
    
    [rArray retain];
    
    @try
    {
        for( i = 0; i < [rArray count]; i++)
        {
            ROI *r = [rArray objectAtIndex:i];
            if( [r ROImode] == ROI_selected && r.locked == NO)
            {
                groupID = [r groupID];
                [[NSNotificationCenter defaultCenter] postNotificationName:OsirixRemoveROINotification object:r userInfo: nil];
                [rArray removeObjectAtIndex:i];
                i--;
                if(groupID!=0.0)
                    [self deleteROIGroupID:groupID];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIRemovedFromArrayNotification object: nil userInfo: nil];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [rArray autorelease];
    
    [drawLock unlock];
    
    [self setNeedsDisplay:YES];
}

- (void) setYFlipped:(BOOL) v
{
    yFlipped = v;
    
    if( [self is2DViewer] && [[self windowController] isPostprocessed] == NO)
    {
        @try {
            // Series Level
            [self.seriesObj  setValue:[NSNumber numberWithBool:yFlipped] forKey:@"yFlipped"];
            
            // Image Level
            if( (curImage >= 0 && dcmFilesList.count > curImage) && COPYSETTINGSINSERIES == NO)
                [self.imageObj setValue:[NSNumber numberWithBool:yFlipped] forKey:@"yFlipped"];
            else
                [self.imageObj setValue: nil forKey:@"yFlipped"];
        }
        @catch ( NSException *e) {
            N2LogException( e);
        }
    }
    
    [self updateTilingViews];
    
    [self setNeedsDisplay:YES];
}

- (void) setXFlipped:(BOOL) v
{
    xFlipped = v;
    
    if( [self is2DViewer] && [[self windowController] isPostprocessed] == NO)
    {
        @try {
            [self.seriesObj setValue:[NSNumber numberWithBool:xFlipped] forKey:@"xFlipped"];
            
            // Image Level
            if( (curImage >= 0 && dcmFilesList.count > curImage) && COPYSETTINGSINSERIES == NO)
                [self.imageObj setValue:[NSNumber numberWithBool:xFlipped] forKey:@"xFlipped"];
            else
                [self.imageObj setValue: nil forKey:@"xFlipped"];
        }
        @catch ( NSException *e) {
            N2LogException( e);
        }
    }
    
    [self updateTilingViews];
    
    [self setNeedsDisplay:YES];
}

- (void)flipVertical: (id)sender
{
    self.yFlipped = !yFlipped;
}

- (void)flipHorizontal: (id)sender
{
    self.xFlipped = !xFlipped;
}

- (void) DrawNSStringGL:(NSString*)str :(GLuint)fontL :(long)x :(long)y rightAlignment:(BOOL)right useStringTexture:(BOOL)stringTex
{
    if(right)
        [self DrawNSStringGL:str :fontL :x :y align:DCMViewTextAlignRight useStringTexture:stringTex];
    else
        [self DrawNSStringGL:str :fontL :x :y align:DCMViewTextAlignLeft useStringTexture:stringTex];
}

+ (void) purgeStringTextureCache
{
    @synchronized( globalStringTextureCache)
    {
        for( NSMutableDictionary *s in globalStringTextureCache)
            [s removeAllObjects];
    }
}

- (void)DrawNSStringGL:(NSString*)str :(GLuint)fontL :(long)x :(long)y align:(DCMViewTextAlign)align useStringTexture:(BOOL)stringTex;
{
    //    stringTex = YES;
    
    if( stringTex)
    {
#define STRCAPACITY 800
        
        if( stringTextureCache == nil)
        {
            stringTextureCache = [[NSMutableDictionary alloc] initWithCapacity: STRCAPACITY];
            
            if( globalStringTextureCache == nil) globalStringTextureCache = [[NSMutableArray alloc] init];
            
            @synchronized( globalStringTextureCache)
            {
                [globalStringTextureCache addObject: stringTextureCache];
            }
        }
        
        StringTexture *stringTex = [stringTextureCache objectForKey: str];
        if( stringTex == nil)
        {
            if( [stringTextureCache count] > STRCAPACITY)
            {
                [stringTextureCache removeAllObjects];
                NSLog(@"String texture cache purged.");
            }
            NSMutableDictionary *stanStringAttrib = [NSMutableDictionary dictionary];
            
            if( fontL == labelFontListGL) [stanStringAttrib setObject:labelFont forKey:NSFontAttributeName];
            //			else if( fontL == iChatFontListGL) [stanStringAttrib setObject:iChatFontGL forKey:NSFontAttributeName];
            else [stanStringAttrib setObject:fontGL forKey:NSFontAttributeName];
            [stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
            
            stringTex = [[StringTexture alloc] initWithString:str withAttributes:stanStringAttrib];
            [stringTex genTextureWithBackingScaleFactor:self.window.backingScaleFactor];
            [stringTextureCache setObject:stringTex forKey:str];
            [stringTex release];
        }
        
        if(align==DCMViewTextAlignRight) x -= [stringTex texSize].width;
        else if(align==DCMViewTextAlignCenter) x -= [stringTex texSize].width/2.0;
        else x -= 5 * self.window.backingScaleFactor;
        
        CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx)
        {
            glEnable (GL_TEXTURE_RECTANGLE_EXT);
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            
            long xc, yc;
            xc = x+2;
            yc = y+1-[stringTex texSize].height;
            
            if( whiteBackground)
                glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
            else
                glColor4f (0.0f, 0.0f, 0.0f, 1.0f);
            
            [stringTex drawWithBounds: NSMakeRect( xc+1, yc+1, [stringTex texSize].width, [stringTex texSize].height)];
            
            if( whiteBackground)
                glColor4f (0.0f, 0.0f, 0.0f, 1.0f);
            else
                glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
            [stringTex drawWithBounds: NSMakeRect( xc, yc, [stringTex texSize].width, [stringTex texSize].height)];
            
            glDisable(GL_BLEND);
            glDisable (GL_TEXTURE_RECTANGLE_EXT);
        }
    }
    else
    {
        char *cstrOut = (char*) [str UTF8String];
        if(align==DCMViewTextAlignRight)
        {
            if( fontL == labelFontListGL) x -= [DCMView lengthOfString:cstrOut forFont:labelFontListGLSize] + 2*self.window.backingScaleFactor;
            //			else if( fontL == iChatFontListGL) x -= [DCMView lengthOfString:cstrOut forFont:iChatFontListGLSize] + 2*self.window.backingScaleFactor;
            else x -= [DCMView lengthOfString:cstrOut forFont:fontListGLSize] + 2;
        }
        else if(align==DCMViewTextAlignCenter)
        {
            if( fontL == labelFontListGL) x -= [DCMView lengthOfString:cstrOut forFont:labelFontListGLSize]/2.0 + 2*self.window.backingScaleFactor;
            //			else if( fontL == iChatFontListGL) x -= [DCMView lengthOfString:cstrOut forFont:iChatFontListGLSize]/2.0 + 2*self.window.backingScaleFactor;
            else x -= [DCMView lengthOfString:cstrOut forFont:fontListGLSize]/2.0 + 2*self.window.backingScaleFactor;
        }
        
        unsigned char	*lstr = (unsigned char*) cstrOut;
        
        CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx)
        {
            if (fontColor)
                glColor4f([fontColor redComponent], [fontColor greenComponent], [fontColor blueComponent], [fontColor alphaComponent]);
            else
            {
                if( whiteBackground)
                    glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
                else
                    glColor4f (0.0, 0.0, 0.0, 1.0);
            }
            
            glRasterPos3d (x+1, y+1, 0);
            
            GLint i = 0;
            while (lstr [i])
            {
                long val = lstr[i++] - ' ';
                if( val < 150 && val >= 0) glCallList (fontL+val);
            }
            
            if( whiteBackground)
                glColor4f (0.0, 0.0, 0.0, 1.0);
            else
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
}

- (void)DrawCStringGL:(char*)cstrOut :(GLuint)fontL :(long)x :(long)y rightAlignment:(BOOL)right useStringTexture:(BOOL)stringTex
{
    if(right)
        [self DrawCStringGL:cstrOut :fontL :x :y align:DCMViewTextAlignRight useStringTexture:stringTex];
    else
        [self DrawCStringGL:cstrOut :fontL :x :y align:DCMViewTextAlignLeft useStringTexture:stringTex];
}

- (void)DrawCStringGL:(char*)cstrOut :(GLuint)fontL :(long)x :(long)y align:(DCMViewTextAlign)align useStringTexture:(BOOL)stringTex;
{
    [self DrawNSStringGL:[NSString stringWithUTF8String:cstrOut] :fontL :x :y align:align useStringTexture:stringTex];
}

- (void) DrawCStringGL: (char *) cstrOut :(GLuint) fontL :(long) x :(long) y
{
    [self DrawCStringGL: (char *) cstrOut :(GLuint) fontL :(long) x :(long) y rightAlignment: NO useStringTexture: NO];
}

- (void) DrawNSStringGL: (NSString*) cstrOut :(GLuint) fontL :(long) x :(long) y
{
    [self DrawNSStringGL: (NSString*) cstrOut :(GLuint) fontL :(long) x :(long) y rightAlignment: NO useStringTexture: NO];
}

- (ToolMode) currentToolRight
{
    return currentToolRight;
}

-(void) setRightTool:(ToolMode) i
{
    currentToolRight = i;
    
    if( [self is2DViewer])
        [[NSUserDefaults standardUserDefaults] setInteger:currentToolRight forKey: @"DEFAULTRIGHTTOOL"];
}

-(void) setCurrentTool:(ToolMode) i
{
    BOOL keepROITool = (i == tROISelector || i == tRepulsor || currentTool == tROISelector || currentTool == tRepulsor);
    
    keepROITool = keepROITool || [self roiTool:currentTool] || [self roiTool:i];
    currentTool = i;
    
    if( [self is2DViewer])
        [[NSUserDefaults standardUserDefaults] setInteger:currentTool forKey: @"DEFAULTLEFTTOOL"];
    
    [self stopROIEditingForce: YES];
    
    mesureA.x = mesureA.y = mesureB.x = mesureB.y = 0;
    roiRect.origin.x = roiRect.origin.y = roiRect.size.width = roiRect.size.height = 0;
    
    if( keepROITool == NO)
    {
        // Unselect previous ROIs
        for( ROI *r in curRoiList) [r setROIMode : ROI_sleep];
    }
    
    NSEvent *event = [[NSApplication sharedApplication] currentEvent];
    
    int clickCount = 1;
    @try
    {
        if( [event type] ==	NSLeftMouseDown || [event type] ==	NSRightMouseDown || [event type] ==	NSLeftMouseUp || [event type] == NSRightMouseUp)
            clickCount = [event clickCount];
    }
    @catch (NSException * e)
    {
        clickCount = 1;
    }
    
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
                if( clickCount == 2)
                {
                    [self setOriginX: 0 Y: 0];
                    self.rotation = 0.0f;
                    [self scaleToFit];
                }
                
                if( clickCount == 3)
                {
                    [self setOriginX: 0 Y: 0];
                    self.rotation = 0.0f;
                    self.scaleValue = 1.0f;
                }
            }
            break;
            
        case tRotate:
            if( [event type] != NSKeyDown)
            {
                if( clickCount == 2 && gClickCountSet == NO && isKeyView == YES && [[self window] isKeyWindow] == YES)
                {
                    gClickCountSet = YES;
                    
                    float rot = [self rotation];
                    
                    if ([event modifierFlags] & NSAlternateKeyMask) rot -= 180;		// -> 180
                    else if ([event modifierFlags] & NSShiftKeyMask) rot -= 90;	// -> 90
                    else rot += 90;	// -> 90
                    
                    self.rotation = rot;
                    
                    if( [self is2DViewer] == YES)
                        [[self windowController] propagateSettings];
                }
            }
            break;
        default:;
    }
    
    [self setCursorForView : currentTool];
    [self checkCursor];
    [self setNeedsDisplay:YES];
}

- (void) gClickCountSetReset
{
    gClickCountSet = NO;
}

- (BOOL) isScaledFit
{
    float s = [self scaleToFitForDCMPix: curDCM];
    
    if( origin.x != 0 && origin.y != 0)
        return NO;
    
    if( fabs( s - self.scaleValue) < 0.1)
        return YES;
    else
        return NO;
}

- (float) scaleToFitForDCMPix: (DCMPix*) d
{
    NSRect  sizeView = [self convertRectToBacking: [self bounds]]; // Retina
    
    int w = d.pwidth;
    int h = d.pheight;
    
    if( d.shutterEnabled)
    {
        w = d.shutterRect.size.width;
        h = d.shutterRect.size.height;
    }
    
    if( sizeView.size.width / w < sizeView.size.height / h / d.pixelRatio )
        return sizeView.size.width / w;
    else
        return sizeView.size.height / h / d.pixelRatio;
}

- (void) scaleToFit
{
    if( scaleToFitNoReentry) return;
    scaleToFitNoReentry = YES;
    
    self.scaleValue = [self scaleToFitForDCMPix: curDCM];
    
    if( curDCM.shutterEnabled)
    {
        origin.x = ((curDCM.pwidth  * 0.5f ) - ( curDCM.shutterRect.origin.x + ( curDCM.shutterRect.size.width  * 0.5f ))) * scaleValue;
        origin.y = -((curDCM.pheight * 0.5f ) - ( curDCM.shutterRect.origin.y + ( curDCM.shutterRect.size.height * 0.5f ))) * scaleValue;
    }
    else
        origin.x = origin.y = 0;
    
    [self setNeedsDisplay:YES];
    
    scaleToFitNoReentry = NO;
}

- (void) setIndexWithReset:(short) index :(BOOL) sizeToFit
{
    TextureComputed32bitPipeline = NO;
    
    if( dcmPixList && index >= 0)
    {
        [[self window] setAcceptsMouseMovedEvents: YES];
        
        [curROI autorelease];
        curROI = nil;
        
        curImage = index;
        if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count] -1;
        if( curImage < 0) curImage = 0;
        
        [curDCM release];
        curDCM = [[dcmPixList objectAtIndex: curImage] retain];
        
        [curRoiList autorelease];
        
        if( dcmRoiList) curRoiList = [[dcmRoiList objectAtIndex: curImage] retain];
        else 			curRoiList = [[NSMutableArray alloc] initWithCapacity:0];
        
        for( ROI *r in curRoiList)
        {
            [r setCurView:self];
            [r recompute];
            // Unselect previous ROIs
            [r setROIMode : ROI_sleep];
        }
        
        curWL = curDCM.wl;
        curWW = curDCM.ww;
        curWLWWSUVConverted = curDCM.SUVConverted;
        curWLWWSUVFactor = 1.0;
        if( curWLWWSUVConverted && [self is2DViewer])
            curWLWWSUVFactor = [[self windowController] factorPET2SUV];
        
        origin.x = origin.y = 0;
        scaleValue = 1;
        
        //get Presentation State info from series Object
        [self updatePresentationStateFromSeries];
        
        [curDCM checkImageAvailble :curWW :curWL];
        
        if( sizeToFit && [self is2DViewer] == NO)
        {
            [self scaleToFit];
        }
        
        [self loadTextures];
        [self setNeedsDisplay:YES];
        
        [yearOld release];
        
        
        if( [[[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOld"] isEqualToString: [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOldAcquisition"]])
            yearOld = [[[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOld"] retain];
        else
            yearOld = [[NSString stringWithFormat:@"%@ / %@", [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOld"], [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOldAcquisition"]] retain];
        
        
        if( self.is2DViewer)
        {
            [self.windowController willChangeValueForKey: @"thicknessInMm"];
            [self.windowController didChangeValueForKey: @"thicknessInMm"];
        }
    }
    else
    {
        [curDCM release];
        curDCM = nil;
        curImage = -1;
        [curRoiList autorelease];
        curRoiList = nil;
        
        [curROI autorelease];
        curROI = nil;
        [self loadTextures];
    }
}

- (void) setPixels: (NSMutableArray*) pixels files: (NSArray*) files rois: (NSMutableArray*) rois firstImage: (short) firstImage level: (char) level reset: (BOOL) reset
{
    [drawLock lock];
    
    @try
    {
        if( [self is2DViewer])
        {
            currentToolRight = [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTRIGHTTOOL"];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"RestoreLeftMouseTool"])
                currentTool =  [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTLEFTTOOL"];
        }
        
        [curDCM release];
        curDCM = nil;
        
        volumicData = -1;
        
        [cleanedOutDcmPixArray release];
        cleanedOutDcmPixArray = nil;
        
        if( dcmPixList != pixels)
        {
            [dcmPixList release];
            dcmPixList = [pixels retain];
            
            volumicSeries = YES;
            
            if( [files count] > 0)
            {
                id sopclassuid = [[files objectAtIndex: 0] valueForKeyPath:@"series.seriesSOPClassUID"];
                if ([DCMAbstractSyntaxUID isImageStorage: sopclassuid] || [DCMAbstractSyntaxUID isRadiotherapy: sopclassuid] || [DCMAbstractSyntaxUID isStructuredReport: sopclassuid] || sopclassuid == nil)
                {
                    
                }
                else NSLog( @"*** DCMView ! ****** It's not a DICOM image ? SOP Class UID: %@", sopclassuid);
            }
            
            if( [stringID isEqualToString:@"previewDatabase"] == NO)
            {
                if( [dcmPixList count] > 1)
                {
                    if( [(DCMPix*)[dcmPixList objectAtIndex: 0] sliceLocation] == [(DCMPix*)[dcmPixList lastObject] sliceLocation]) volumicSeries = NO;
                }
                else volumicSeries = NO;
            }
        }
        
        if( dcmFilesList != files)
        {
            [dcmFilesList release];
            dcmFilesList = [files retain];
        }
        
        flippedData = NO;
        
        if( dcmRoiList != rois)
        {
            [dcmRoiList autorelease];
            dcmRoiList = [rois retain];
        }
        
        listType = level;
        
        if( dcmPixList)
        {
            if( reset)
            {
                [self setIndexWithReset: firstImage :YES];
                [self updatePresentationStateFromSeries];
            }
        }
        
        [self setNeedsDisplay:true];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [drawLock unlock];
}

- (void) setDCM:(NSMutableArray*) c :(NSArray*)d :(NSMutableArray*)e :(short) firstImage :(char) type :(BOOL) reset
{
    [self setPixels: c files: d rois: e firstImage: firstImage level: type reset: reset];
}

- (void) dealloc
{
    NSLog(@"DCMView released");
    
    
    @try
    {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ANNOTATIONS"];
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"LabelFONTNAME"];
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"LabelFONTSIZE"];
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    [self prepareToRelease];
    
    [self deleteMouseDownTimer];
    
    [matrix release];
    matrix = nil;
    
    [cursorTracking release];
    cursorTracking = nil;
    
    [drawLock lock];
    [drawLock unlock];
    
    for( ROI*r in curRoiList)
        [r prepareForRelease]; // We need to unlink the links related to OpenGLContext
    
    [curRoiList autorelease];
    curRoiList = nil;
    
    [dcmRoiList release];
    dcmRoiList = nil;
    
    @synchronized( self)
    {
        [dcmFilesList release];
        dcmFilesList = nil;
        
        [dcmPixList release];
        dcmPixList = nil;
    }
    
    [curDCM release];
    curDCM = nil;
    
    [dcmExportPlugin release];
    dcmExportPlugin = nil;
    
    [stringID release];
    stringID = nil;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    @try
    {
        [[self openGLContext] makeCurrentContext];
        
        CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx)
        {
            if( fontListGL) glDeleteLists (fontListGL, 150);
            fontListGL = 0;
            
            if( labelFontListGL) glDeleteLists(labelFontListGL, 150);
            labelFontListGL = 0;
            
            if( loupeTextureID) glDeleteTextures( 1, &loupeTextureID);
            loupeTextureID = 0;
            
            if( loupeMaskTextureID) glDeleteTextures( 1, &loupeMaskTextureID);
            loupeMaskTextureID = 0;
            
            if( pTextureName)
            {
                glDeleteTextures (textureX * textureY, pTextureName);
                free( (Ptr) pTextureName);
                pTextureName = nil;
            }
            if( blendingTextureName)
            {
                glDeleteTextures ( blendingTextureX * blendingTextureY, blendingTextureName);
                free( (Ptr) blendingTextureName);
                blendingTextureName = nil;
            }
        }
        
        if( colorBuf) free( colorBuf);
        colorBuf = nil;
        
        if( blendingColorBuf) free( blendingColorBuf);
        blendingColorBuf = nil;
        
        [fontColor release]; fontColor = nil;
        [fontGL release]; fontGL = nil;
        [labelFont release]; labelFont = nil;
        [yearOld release]; yearOld = nil;
        
        [cursor release]; cursor = nil;
        
        @synchronized( globalStringTextureCache)
        {
            [globalStringTextureCache removeObject: stringTextureCache];
        }
        [stringTextureCache release];
        stringTextureCache = 0L;
        
        [_mouseDownTimer invalidate];
        [_mouseDownTimer release];
        _mouseDownTimer = nil;
        
        [destinationImage release];
        destinationImage = nil;
        
        if(repulsorColorTimer)
        {
            [repulsorColorTimer invalidate];
            [repulsorColorTimer release];
            repulsorColorTimer = nil;
        }
        
        if( resampledBaseAddr) free( resampledBaseAddr);
        resampledBaseAddr = nil;
        
        if( blendingResampledBaseAddr) free( blendingResampledBaseAddr);
        blendingResampledBaseAddr = nil;
        
        [showDescriptionInLargeText release];
        showDescriptionInLargeText = nil;
        

        
        [blendingView release];
        blendingView = nil;
        
        [self deleteLens];
        
        [loupeImage release];
        loupeImage = nil;
        
        [loupeMaskImage release];
        loupeMaskImage = nil;
        
        [studyDateBox release];
        studyDateBox = nil;
        
        [cleanedOutDcmPixArray release];
        cleanedOutDcmPixArray = nil;
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [pool release];
    
    [super dealloc];
}

- (BOOL) COPYSETTINGSINSERIES
{
    return COPYSETTINGSINSERIES;
}

- (void) setCOPYSETTINGSINSERIESdirectly: (BOOL) b
{
    COPYSETTINGSINSERIES = b;
}

- (void) setCOPYSETTINGSINSERIES: (BOOL) b
{
    ViewerController *v = [self windowController];
    
    COPYSETTINGSINSERIES = b;
    
    for( int i = 0 ; i < [v  maxMovieIndex]; i++)
    {
        for( DCMPix *pix in [v pixList: i])
        {
            if( pix.isLoaded)
                [pix changeWLWW :curWL :curWW];
            
            if( COPYSETTINGSINSERIES)
            {
                DicomImage *im = pix.imageObj;
                
                [im setValue: nil forKey:@"windowWidth"];
                [im setValue: nil forKey:@"windowLevel"];
                [im setValue: nil forKey:@"scale"];
                [im setValue: nil forKey:@"rotationAngle"];
                [im setValue: nil forKey:@"yFlipped"];
                [im setValue: nil forKey:@"xFlipped"];
                [im setValue: nil forKey:@"xOffset"];
                [im setValue: nil forKey:@"yOffset"];
            }
            else
            {
                DicomImage *im = pix.imageObj;
                
                [im setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
                [im setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
                if( [self isScaledFit] == NO)
                    [im setValue:[NSNumber numberWithFloat:scaleValue] forKey:@"scale"];
                else
                    [im setValue:nil forKey:@"scale"];
                [im setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
                [im setValue:[NSNumber numberWithBool:yFlipped] forKey:@"yFlipped"];
                [im setValue:[NSNumber numberWithBool:yFlipped] forKey:@"xFlipped"];
                [im setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
                [im setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
            }
        }
    }
}

- (void) switchCopySettingsInSeries:(id) sender
{
    COPYSETTINGSINSERIES = !COPYSETTINGSINSERIES;
    
    @try
    {
        ViewerController *v = self.windowController;
        
        for( DCMView *imageView in [v imageViews])
        {
            if( [imageView seriesObj] == self.seriesObj)
            {
                imageView.COPYSETTINGSINSERIES = COPYSETTINGSINSERIES;
                
                for( int i = 0 ; i < [v  maxMovieIndex]; i++)
                {
                    for( DCMPix *pix in [v pixList: i])
                    {
                        [pix changeWLWW :curWL :curWW];
                        
                        if( COPYSETTINGSINSERIES)
                        {
                            [pix.imageObj setValue: nil forKey:@"windowWidth"];
                            [pix.imageObj setValue: nil forKey:@"windowLevel"];
                            [pix.imageObj setValue: nil forKey:@"scale"];
                            [pix.imageObj setValue: nil forKey:@"rotationAngle"];
                            [pix.imageObj setValue: nil forKey:@"yFlipped"];
                            [pix.imageObj setValue: nil forKey:@"xFlipped"];
                            [pix.imageObj setValue: nil forKey:@"xOffset"];
                            [pix.imageObj setValue: nil forKey:@"yOffset"];
                        }
                        else
                        {
                            [pix.imageObj setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
                            [pix.imageObj setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
                            if( [self isScaledFit] == NO)
                                [pix.imageObj setValue:[NSNumber numberWithFloat:scaleValue] forKey:@"scale"];
                            else
                                [pix.imageObj setValue:nil forKey:@"scale"];
                            [pix.imageObj setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
                            [pix.imageObj setValue:[NSNumber numberWithBool:yFlipped] forKey:@"yFlipped"];
                            [pix.imageObj setValue:[NSNumber numberWithBool:yFlipped] forKey:@"xFlipped"];
                            [pix.imageObj setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
                            [pix.imageObj setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
                        }
                    }
                }
            }
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
}

- (void) setIndex:(short) index
{
    [drawLock lock];
    
    @try
    {
        TextureComputed32bitPipeline = NO;
        
        BOOL	keepIt;
        
        [self stopROIEditing];
        
        [[self window] setAcceptsMouseMovedEvents: YES];
        
        if( dcmPixList && index > -1 && [dcmPixList count] > 0)
        {
            if( [[[[dcmFilesList objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"])
                noScale = YES;
            else
                noScale = NO;
            
            curImage = index;
            if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count] -1;
            if( curImage < 0) curImage = 0;
            
            DCMPix *pix2beReleased = curDCM;
            curDCM = [[dcmPixList objectAtIndex:curImage] retain];
            
            [curDCM CheckLoad];
            
            [pix2beReleased release]; // This will allow us to keep the cached group for a multi frame image
            
            [curRoiList autorelease];
            
            if( dcmRoiList) curRoiList = [[dcmRoiList objectAtIndex: curImage] retain];
            else
                curRoiList = [[NSMutableArray alloc] initWithCapacity:0];
            
            keepIt = NO;
            for( ROI *r in curRoiList)
            {
                [r setCurView:self];
                [r recompute];
                if( curROI == r) keepIt = YES;
            }
            
            if( keepIt == NO)
            {
                [curROI autorelease];
                curROI = nil;
            }
            
            BOOL done = NO;
            
            if( [self is2DViewer] == YES)
            {
                if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
                {
                    if( curWW != curDCM.ww || curWL != curDCM.wl || [curDCM updateToApply] == YES)
                    {
                        [self reapplyWindowLevel];
                    }
                    else [curDCM checkImageAvailble :curWW :curWL];
                    
                    [self updatePresentationStateFromSeriesOnlyImageLevel: YES];
                    
                    done = YES;
                }
                
                [self.windowController willChangeValueForKey: @"thicknessInMm"];
                [self.windowController didChangeValueForKey: @"thicknessInMm"];
            }
            
            if( done == NO)
            {
                if( curWW != curDCM.ww || curWL != curDCM.wl || [curDCM updateToApply] == YES)
                {
                    [self reapplyWindowLevel];
                }
                else [curDCM checkImageAvailble :curWW :curWL];
            }
            
            [self loadTextures];
            
            [yearOld release];
            
            if( [[[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOld"] isEqualToString: [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOldAcquisition"]])
                yearOld = [[[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOld"] retain];
            else
                yearOld = [[NSString stringWithFormat:@"%@ / %@", [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOld"], [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOldAcquisition"]] retain];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:OsirixDCMViewIndexChangedNotification object:self];
        }
        else
        {
            [curDCM release];
            curDCM = nil;
            curImage = -1;
            [curRoiList autorelease];
            curRoiList = nil;
            
            [curROI autorelease];
            curROI = nil;
            [self loadTextures];
        }
        
        NSEvent *event = [[NSApplication sharedApplication] currentEvent];
        
        [self mouseMoved: event];
        [self setNeedsDisplay:YES];
        
        [self updateTilingViews];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [drawLock unlock];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
    if (currentTool >= 5) return NO;  // A ROI TOOL !
    else return YES;
}

- (BOOL)acceptsFirstResponder
{
    if( curDCM == nil) return NO;
    
    return YES;
}

- (BOOL) containsScrollThroughModality
{
    for( NSString *m in [self.studyObj.modalities componentsSeparatedByString:@"\\"])
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: [NSString stringWithFormat: @"scrollThroughSeriesFor%@", m]])
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) scrollThroughSeriesIfNecessary: (int) i
{
    BOOL switchSeries = NO;
    
    if( [self is2DViewer] && [[NSUserDefaults standardUserDefaults] boolForKey:@"scrollThroughSeries"] && [self containsScrollThroughModality])
    {
        int imIndex = curImage;
        
        if( flippedData)
            imIndex = (long)[dcmPixList count]-1-imIndex;
        
        if( imIndex < 0)
        {
            NSArray *seriesArray = [[BrowserController currentBrowser] childrenArray: [self.seriesObj valueForKey: @"study"]];
            NSInteger index = [seriesArray indexOfObject: self.seriesObj];
            
            if( index != NSNotFound)
            {
                if( index > 0)
                {
                    [NSObject cancelPreviousPerformRequestsWithTarget: [self windowController] selector: @selector(loadSeriesDown) object: nil];
                    [[self windowController] performSelector: @selector(loadSeriesDown) withObject: nil afterDelay: 0.01];
                    switchSeries = YES;
                }
            }
        }
        else if( imIndex >= [dcmPixList count])
        {
            NSArray *seriesArray = [[BrowserController currentBrowser] childrenArray: [self.seriesObj valueForKey: @"study"]];
            NSInteger index = [seriesArray indexOfObject: self.seriesObj];
            
            if( index != NSNotFound)
            {
                if( index + 1 < [seriesArray count])
                {
                    [NSObject cancelPreviousPerformRequestsWithTarget: [self windowController] selector: @selector(loadSeriesUp) object: nil];
                    [[self windowController] performSelector: @selector(loadSeriesUp) withObject: nil afterDelay: 0.01];
                    switchSeries = YES;
                }
            }
        }
        
        if( curImage < 0) curImage = 0;
        if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count]-1;
    }
    
    return switchSeries;
}

- (void) keyDown:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
    if( [[event characters] length] == 0) return;
    
    unichar		c = [[event characters] characterAtIndex:0];
    long		xMove = 0, yMove = 0, val;
    BOOL		Jog = NO;
    
    if( [self windowController]  == [BrowserController currentBrowser])
    {
        [super keyDown:event];
        return;
    }
    
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
        
        if( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
        {
            [[self windowController] addToUndoQueue:@"roi"];
            
            // NE PAS OUBLIER DE CHANGER EGALEMENT LE CUT !
            long	i;
            NSTimeInterval groupID;
            
            [drawLock lock];
            
            
            NSMutableArray *rArray = curRoiList;
            
            [rArray retain];
            
            @try
            {
                for( i = 0; i < [rArray count]; i++)
                {
                    ROI *r = [rArray objectAtIndex:i];
                    
                    if( [r ROImode] == ROI_selectedModify || [r ROImode] == ROI_drawing)
                    {
                        if( [r deleteSelectedPoint] == NO && r.locked == NO)
                        {
                            groupID = [r groupID];
                            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:r userInfo: nil];
                            [rArray removeObjectAtIndex:i];
                            i--;
                            if( groupID != 0.0)
                                [self deleteROIGroupID:groupID];
                        }
                    }
                }
                
                for( i = 0; i < [rArray count]; i++)
                {
                    ROI *r = [rArray objectAtIndex:i];
                    
                    if( [r ROImode] == ROI_selected  && r.locked == NO && r.hidden == NO)
                    {
                        groupID = [r groupID];
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:r userInfo: nil];
                        [rArray removeObjectAtIndex:i];
                        i--;
                        if( groupID != 0.0)
                            [self deleteROIGroupID:groupID];
                    }
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIRemovedFromArrayNotification object: nil userInfo: nil];
            }
            @catch (NSException * e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            
            [rArray autorelease];
            
            [drawLock unlock];
            
            [self setNeedsDisplay: YES];
        }
        else if( (c == 13 || c == 3 || c == ' ') && [self is2DViewer] == YES)	// Return - Enter - Space
        {
            [[self windowController] PlayStop:[[self windowController] findPlayStopButton]];
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
                    inc = - curDCM.stack;
                    curImage += inc;
                    
                    [self scrollThroughSeriesIfNecessary: curImage];
                    
                    if( curImage < 0) curImage = 0;
                }
                else
                {
                    if( [event modifierFlags]  & NSAlternateKeyMask) [[self windowController] setKeyImage:self];
                    inc = -_imageRows * _imageColumns;
                    curImage -= _imageRows * _imageColumns;
                    
                    [self scrollThroughSeriesIfNecessary: curImage];
                    
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
                    inc = curDCM.stack;
                    curImage += inc;
                    
                    [self scrollThroughSeriesIfNecessary: curImage];
                    
                    if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count]-1;
                }
                else
                {
                    if( [event modifierFlags]  & NSAlternateKeyMask) [[self windowController] setKeyImage:self];
                    inc = _imageRows * _imageColumns;
                    curImage += _imageRows * _imageColumns;
                    
                    [self scrollThroughSeriesIfNecessary: curImage];
                    
                    if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count]-1;
                }
            }
        }
        else if (c == NSUpArrowFunctionKey)
        {
            if( [self is2DViewer] == YES && [[self windowController] maxMovieIndex] > 1) [super keyDown:event];
            else
            {
                [self setScaleValue:(scaleValue+1./50.)];
                
                [self setNeedsDisplay:YES];
            }
        }
        else if(c == NSDownArrowFunctionKey)
        {
            if( [[self windowController] maxMovieIndex] > 1 && [[self windowController] maxMovieIndex] > 1) [super keyDown:event];
            else
            {
                self.scaleValue = scaleValue -1.0f/50.0f;
                
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
            if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count]-1;
        }
        else if (c == NSHomeFunctionKey)
            curImage = 0;
        else if (c == NSEndFunctionKey)
            curImage = (long)[dcmPixList count]-1;
        else if (c == 9)	// Tab key
        {
            int a = annotationType + 1;
            if( a > annotFull) a = 0;
            
            //			switch( a)
            //			{
            //				case annotNone:
            //					[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Annotations", nil) description: NSLocalizedString(@"Turn Off Annotations", nil) name:@"result"];
            //				break;
            //
            //				case annotGraphics:
            //					[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Annotations", nil) description: NSLocalizedString(@"Switch to Graphic Only", nil) name:@"result"];
            //				break;
            //
            //				case annotBase:
            //					[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Annotations", nil) description: NSLocalizedString(@"Switch to Full without names", nil) name:@"result"];
            //				break;
            //
            //				case annotFull:
            //					[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Annotations", nil) description: NSLocalizedString(@"Switch to Full", nil) name:@"result"];
            //				break;
            //			}
            
            [[NSUserDefaults standardUserDefaults] setInteger: a forKey: @"ANNOTATIONS"];
            [DCMView setDefaults];
            annotationType = a;
            //            ANNOTATIONS = a;
            
            NSNotificationCenter *nc;
            nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName: OsirixUpdateViewNotification object: self userInfo: nil];
            
            for( ViewerController *v in [ViewerController getDisplayed2DViewers])
                [v setWindowTitle: self];
        }
        else
        {
            NSLog( @"Keydown: %d", c);
            
            if( [self actionForHotKey:[event characters]] == NO) [super keyDown:event];
        }
        
        if( Jog == YES)
        {
            if (currentTool == tZoom)
            {
                if( yMove) val = yMove;
                else val = xMove;
                
                self.scaleValue = scaleValue + val / 10.0f;
            }
            
            if (currentTool == tTranslate)
            {
                float xmove, ymove, xx, yy;
                //	GLfloat deg2rad = M_PI/180.0;
                
                xmove = xMove*10;
                ymove = yMove*10;
                
                if( xFlipped) xmove = -xmove;
                if( yFlipped) ymove = -ymove;
                
                xx = xmove*cos(rotation*deg2rad) + ymove*sin(rotation*deg2rad);
                yy = xmove*sin(rotation*deg2rad) - ymove*cos(rotation*deg2rad);
                
                [self setOriginX: origin.x + xx Y: origin.y + yy];
            }
            
            if (currentTool == tRotate)
            {
                if( yMove) val = yMove * 3;
                else val = xMove * 3;
                
                float rot = self.rotation;
                
                rot += val;
                
                if( rot < 0) rot += 360;
                if( rot > 360) rot -= 360;
                
                self.rotation =rot;
            }
            
            if (currentTool == tNext)
            {
                short   inc, previmage;
                
                if( yMove) val = yMove/labs(yMove);
                else val = xMove/labs(xMove);
                
                previmage = curImage;
                
                if( val < 0)
                {
                    inc = -1;
                    curImage--;
                    if( curImage < 0) curImage = (long)[dcmPixList count]-1;
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
                [self setWLWW:curDCM.wl +yMove*10 :curDCM.ww +xMove*10 ];
            }
            
            [self setNeedsDisplay:YES];
        }
        
        if( previmage != curImage)
        {
            if( listType == 'i') [self setIndex:curImage];
            else [self setIndexWithReset:curImage :YES];
            
            if( matrix ) {
                NSInteger rows, cols; [matrix getNumberOfRows:&rows columns:&cols];  if( cols < 1) cols = 1;
                [matrix selectCellAtRow:curImage/cols column:curImage%cols];
            }
            
            if( [self is2DViewer] == YES)
                [[self windowController] adjustSlider];
            
            // SYNCRO
            [self sendSyncMessage:inc];
            
            [self setNeedsDisplay:YES];
        }
        
        if( [self is2DViewer] == YES)
            [[self windowController] propagateSettings];
    }
}

- (BOOL) shouldPropagate
{
    //	if( curImage >= 0 && [DCMView noPropagateSettingsInSeriesForModality: [[dcmFilesList objectAtIndex:0] valueForKey:@"modality"]] || COPYSETTINGSINSERIES == NO)
    //		return NO;
    //	else
    return YES;
}

- (void)deleteROIGroupID:(NSTimeInterval)groupID
{
    [drawLock lock];
    
    NSMutableArray *rArray = curRoiList;
    
    [rArray retain];
    
    @try
    {
        for( int i=0; i<[rArray count]; i++ )
        {
            if([[rArray objectAtIndex:i] groupID] == groupID)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:OsirixRemoveROINotification object:[rArray objectAtIndex:i] userInfo:nil];
                [rArray removeObjectAtIndex:i];
                i--;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIRemovedFromArrayNotification object:NULL userInfo:NULL];
            }
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [rArray autorelease];
    
    [drawLock unlock];
}

- (BOOL) allIdenticalValues:(NSString*) v inArray:(NSArray*) a
{
    if( [a count])
    {
        NSString *s = [[a objectAtIndex: 0] valueForKey: v];
        for( id i in a)
        {
            if( [s isEqualToString: [i valueForKey: v]] == NO) return NO;
        }
        
        return YES;
    }
    return NO;
}

- (void) computeDescriptionInLarge
{
    [drawLock lock];
    
    @try
    {
        id curSeries = self.seriesObj;
        id curStudy = [curSeries valueForKey:@"study"];
        
        NSArray *viewers = [[ViewerController getDisplayed2DViewers] sortedArrayUsingFunction: studyCompare context: nil];
        
        NSMutableArray *studiesArray = [NSMutableArray array];
        NSMutableArray *seriesArray = [NSMutableArray array];
        
        for( ViewerController *v in viewers)
        {
            if( [v currentStudy] && [v currentSeries])
            {
                [studiesArray addObject: [v currentStudy]];
                [seriesArray addObject: [v currentSeries]];
            }
        }
        
        NSMutableString *description = [NSMutableString stringWithString:@""];
        // same patients?
        if( [self allIdenticalValues: @"name" inArray: studiesArray] == NO)
        {
            if( [curStudy valueForKey: @"name"])
            {
                if( [description length]) [description appendString:@"\r"];
                if( [curStudy valueForKey: @"name"]) [description appendString: [curStudy valueForKey: @"name"]];
            }
        }
        
        if( [description length]) [description appendString:@"\r"];
        
        if( [NSUserDefaults formatDateTime: [curSeries valueForKey:@"date"]])
            [description appendString: [NSUserDefaults formatDateTime: [curSeries valueForKey:@"date"]]];
        
        if( [self allIdenticalValues: @"studyName" inArray: studiesArray] == NO)
        {
            if( [curStudy valueForKey: @"studyName"])
            {
                if( [description length]) [description appendString:@"\r"];
                if( [curStudy valueForKey: @"studyName"])
                    [description appendString: [curStudy valueForKey: @"studyName"]];
            }
        }
        
        if( [curSeries valueForKey:@"name"])
        {
            if( [description length]) [description appendString:@"\r"];
            if( [curSeries valueForKey:@"name"])
                [description appendString: [curSeries valueForKey:@"name"]];
        }
        
        NSMutableDictionary *stanStringAttrib = [NSMutableDictionary dictionary];
        [stanStringAttrib setObject: [NSFont fontWithName:@"Helvetica-Bold" size:30] forKey:NSFontAttributeName];
        
        if( description == nil)
            description = [NSMutableString stringWithString:@""];
        
        NSAttributedString *text = [[[NSAttributedString alloc] initWithString: description attributes: stanStringAttrib] autorelease];
        
        [self computeColor];
        
        NSColor *boxColor = [ViewerController.studyColors objectAtIndex: 0];
        if( studyColorR != 0 || studyColorG != 0 || studyColorB != 0)
            boxColor = [NSColor colorWithCalibratedRed: studyColorR green: studyColorG blue: studyColorB alpha: 0.7];
        NSColor *frameColor = [NSColor colorWithDeviceRed: [boxColor redComponent] green:[boxColor greenComponent] blue:[boxColor blueComponent] alpha:1];
        
        if( showDescriptionInLargeText == nil)
            showDescriptionInLargeText = [[GLString alloc] initWithAttributedString: text withBoxColor: boxColor withBorderColor:frameColor];
        else
        {
            [showDescriptionInLargeText setString: text];
            [showDescriptionInLargeText setBoxColor: boxColor];
            [showDescriptionInLargeText setBorderColor: frameColor];
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [drawLock unlock];
}

- (void) switchShowDescriptionInLarge
{
    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    {
        for( DCMView *m in [v imageViews])
        {
            m.showDescriptionInLarge = showDescriptionInLarge;
            
            if( showDescriptionInLarge)
                [m computeDescriptionInLarge];
            [m setNeedsDisplay: YES];
        }
    }
}

- (void)flagsChanged {
    NSEvent *e = nil;
    [self flagsChanged:e];
}

- (void) flagsChanged:(NSEvent *)event
{
    [self deleteLens];
    //	if(loupeController) [loupeController close];
    
    if( [self is2DViewer] == YES)
    {
        NSUInteger modifiers = [event modifierFlags];
        BOOL update = NO;
        
        if ((modifiers & (NSCommandKeyMask | NSShiftKeyMask)) == (NSCommandKeyMask | NSShiftKeyMask))
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
        
        BOOL cLarge = showDescriptionInLarge;
        showDescriptionInLarge = NO;
        if( modifiers & NSControlKeyMask)
        {
            if(modifiers & NSCommandKeyMask) {}
            else if(modifiers & NSShiftKeyMask) {}
            else if(modifiers & NSAlternateKeyMask) {}
            else
                showDescriptionInLarge = YES;
        }
        
        if( showDescriptionInLarge != cLarge)
        {
            [self switchShowDescriptionInLarge];
            [[self windowController] showCurrentThumbnail: self];
        }
        
        //		if( (modifiers & NSControlKeyMask) && (modifiers & NSAlternateKeyMask) && (modifiers & NSCommandKeyMask))
        //		{
        //			for( ViewerController *v in [ViewerController get2DViewers])
        //			{
        //				for( DCMView *view in [v imageViews])
        //					[view setNeedsDisplay: YES];
        //			}
        //		}
    }
    
    BOOL roiHit = NO;
    
    if( [self roiTool: currentTool])
    {
        NSPoint tempPt = [self convertPoint: [event locationInWindow] fromView: nil];
        tempPt = [self ConvertFromNSView2GL:tempPt];
        if( [self clickInROI: tempPt])
            roiHit = YES;
    }
    else if( ( [event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSAlternateKeyMask)  && !([event modifierFlags] & NSCommandKeyMask)  && !([event modifierFlags] & NSControlKeyMask) && mouseDragging == NO)
    {
        if( [event type] != NSLeftMouseDragged && [event type] != NSLeftMouseDown)
        {
            [self computeMagnifyLens: NSMakePoint( mouseXPos, mouseYPos)];
#ifdef new_loupe
            [self displayLoupeWithCenter:NSMakePoint([[self window] frame].origin.x+[event locationInWindow].x, [[self window] frame].origin.y+[event locationInWindow].y)];
#endif
        }
    }
    
    if( roiHit == NO)
        [self setCursorForView: [self getTool: event]];
    else
        [self setCursorForView: currentTool];
    
    if( cursorSet) [cursor set];
    
    [super flagsChanged:event];
}

- (void)mouseUp:(NSEvent *)event
{
    if( CGCursorIsVisible() == NO && lensTexture == nil) return; //For Synergy compatibility
    if ([self eventToPlugins:event]) return;
    
    mouseDragging = NO;
    
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
    if ([event modifierFlags] & NSAlphaShiftKeyMask)
        modifyImageOnly = YES;
    
    if( dcmPixList)
    {
        if ( pluginOverridesMouse && ( [event modifierFlags] & NSControlKeyMask ) )
        {  // Simulate Right Mouse Button action
            [nc postNotificationName: OsirixRightMouseUpNotification object: self userInfo: userInfo];
            return;
        }
        
        [drawLock lock];
        
        @try
        {
            [self mouseMoved: event];	// Update some variables...
            
            if( curImage != startImage && (matrix && [BrowserController currentBrowser]))
            {
                NSInteger rows, cols; [matrix getNumberOfRows:&rows columns:&cols];  if( cols < 1) cols = 1;
                NSButtonCell *cell = [matrix cellAtRow:curImage/cols column:curImage%cols];
                [cell performClick:nil];
                [matrix selectCellAtRow :curImage/cols column:curImage%cols];
            }
            
            ToolMode tool = currentMouseEventTool;
            
            if( crossMove >= 0) tool = tCross;
            
            if( tool == tWL || tool == tWLBlended)
            {
                if( [self is2DViewer] == YES)
                {
                    [[[self windowController] thickSlabController] setLowQuality: NO];
                    [self reapplyWindowLevel];
                    [self loadTextures];
                    [self setNeedsDisplay:YES];
                }
            }
            
            if( [self roiTool: tool] )
            {
                NSPoint     eventLocation = [event locationInWindow];
                NSPoint		tempPt = [self convertPoint:eventLocation fromView: nil];
                
                tempPt = [self ConvertFromNSView2GL:tempPt];
                
                for( ROI *r in curRoiList)
                {
                    [r mouseRoiUp: tempPt scaleValue: (float) scaleValue];
                    
                    if( [r ROImode] == ROI_selected)
                    {
                        [nc postNotificationName: OsirixROISelectedNotification object: r userInfo: nil];
                        break;
                    }
                }
                
                [self deleteInvalidROIs];
                
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
                ROISelectorSelectedROIList = nil;
                
                NSRect rect = NSMakeRect(ROISelectorStartPoint.x-1, ROISelectorStartPoint.y-1, fabs(ROISelectorEndPoint.x-ROISelectorStartPoint.x)+2, fabs(ROISelectorEndPoint.y-ROISelectorStartPoint.y)+2);
                ROISelectorStartPoint = NSMakePoint(0.0, 0.0);
                ROISelectorEndPoint = NSMakePoint(0.0, 0.0);
                [self drawRect:rect];
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: [DCMView findWLWWPreset: curWL :curWW :curDCM] userInfo: nil];
        
        [drawLock unlock];
    }
}

-(void) roiSet:(ROI*) aRoi
{
    [aRoi setCurView:self];
}

-(void) roiSet
{
    for( ROI *c in curRoiList)
        [c setCurView:self];
}

// checks to see if tool is a valid ID for ROIs
// A better name might be  - (BOOL)isToolforROIs:(long)tool;

-(BOOL) roiTool:(ToolMode) tool
{
    switch( tool)
    {
        case tMesure:
        case tROI:
        case tOval:
        case tOPolygon:
        case tCPolygon:
        case tDynAngle:
        case tAxis:
        case tAngle:
        case tArrow:
        case tText:
        case tPencil:
        case tPlain:
        case t2DPoint:
        case tTAGT:
            return YES;
        default:;
    }
    
    return NO;
}

- (IBAction) selectAll: (id) sender
{
    for( ROI *r in curRoiList)
    {
        [r setROIMode: ROI_selected];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object: r userInfo: nil];
    }
    
    [self setNeedsDisplay:YES];
}

-(void) deleteLens
{
    if( lensTexture)
    {
        free( lensTexture);
        lensTexture = nil;
        [self setNeedsDisplay: YES];
        
        if( cursorhidden)
        {
            [NSCursor unhide];
            cursorhidden = NO;
        }
    }
}

-(void) computeMagnifyLens:(NSPoint) p
{
    if( p.x == 0 && p.y == 0)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"magnifyingLens"] == NO)
        return;
    
    if( isKeyView == NO)
        [[self window] makeFirstResponder: self];
    
    if( needToLoadTexture)
        [self loadTexturesCompute];
    
    LENSSIZE = 100 / scaleValue;
    
    [self deleteLens];
    
    char *src = [curDCM baseAddr];
    int dcmWidth = [curDCM pwidth];
    
    if( curDCM.isLUT12Bit)
        src = (char*) curDCM.LUT12baseAddr;
    
    if( colorTransfer)
        src = (char*) colorBuf;
    
    if( zoomIsSoftwareInterpolated == YES && FULL32BITPIPELINE == NO)
    {
        src = resampledBaseAddr;
        dcmWidth = textureWidth;
        
        LENSRATIO = (float) textureWidth / (float) [curDCM pwidth];
        LENSSIZE *= LENSRATIO;
    }
    else LENSRATIO = 1;
    
    if( LENSSIZE < textureWidth)
    {
        lensTexture = calloc( LENSSIZE * LENSSIZE, 4);
        
        if( lensTexture && src)
        {
            NSRect l = NSMakeRect( p.x*LENSRATIO - (LENSSIZE/2), p.y*LENSRATIO - (LENSSIZE/2), LENSSIZE, LENSSIZE);
            
            int sx = l.origin.x, sy = l.origin.y;
            int ex = l.size.width, ey = l.size.height;
            
            if( ex+sx> textureWidth) ex = textureWidth-sx;
            if( ey+sy> textureHeight) ey = textureHeight-sy;
            
            int sxx = 0, syy = 0;
            
            if( sx < 0)
            {
                sxx = -sx;
                ex -= sxx;
                sx = 0;
            }
            
            if( sy < 0)
            {
                syy = -sy;
                ey -= syy;
                sy = 0;
            }
            
            if( curDCM.isRGB == YES || [curDCM thickSlabVRActivated] == YES || curDCM.isLUT12Bit == YES || (colorTransfer == YES))
            {
                for( int y = sy ; y < sy+ey ; y++)
                {
                    char *sr = &src[ sx*4 +y*dcmWidth*4];
                    char *dr = &lensTexture[ sxx*4 + (y-sy+syy)*LENSSIZE*4];
                    
                    int x = ex;
                    while( x-- > 0)
                    {
                        sr++;
                        *dr++ = 0;
                        *dr++ = *sr++;
                        *dr++ = *sr++;
                        *dr++ = *sr++;
                        
                    }
                }
            }
            else
            {
                for( int y = sy ; y < sy+ey ; y++)
                {
                    char *sr = &src[ sx +y*dcmWidth];
                    char *dr = &lensTexture[ sxx*4 + (y-sy+syy)*LENSSIZE*4];
                    
                    int x = ex;
                    while( x-- > 0)
                    {
                        *dr++ = 0;
                        *dr++ = *sr;
                        *dr++ = *sr;
                        *dr++ = *sr;
                        sr++;
                    }
                }
            }
            
            if( curDCM.pixelRatio != 1.0)
            {
                vImage_Buffer src;
                vImage_Buffer dst;
                
                src.height = LENSSIZE;
                src.width = LENSSIZE;
                src.rowBytes = src.width * 4;
                src.data = lensTexture;
                
                dst.height = LENSSIZE * curDCM.pixelRatio;
                dst.width = LENSSIZE;
                dst.rowBytes = dst.width * 4;
                dst.data = calloc( dst.height * dst.rowBytes, 1);
                if( dst.data)
                {
                    vImageScale_ARGB8888( &src, &dst, nil, kvImageHighQualityResampling);
                    
                    if( curDCM.pixelRatio > 1.0)
                        memcpy( lensTexture, dst.data + dst.rowBytes*((dst.height-src.height)/2), LENSSIZE*LENSSIZE*4);
                    else
                    {
                        memset( lensTexture, 0, LENSSIZE*LENSSIZE*4);
                        memcpy( lensTexture + src.rowBytes*((src.height-dst.height)/2), dst.data, LENSSIZE*dst.height*4);
                    }
                    free( dst.data);
                }
            }
            
            // Apply the circle
            {
                int		x,y;
                int		xsqr;
                int		rad = LENSSIZE/2;
                
                x = rad;
                while( x-- > 0)
                {
                    xsqr = x*x;
                    y = rad;
                    while( y-- > 0)
                    {
                        //						if( (xsqr + y*y) < radsqr)
                        {
                            lensTexture[ (rad+x)*4 + (rad+y)*LENSSIZE*4] = 0xff;
                            lensTexture[ (rad-x)*4 + (rad+y)*LENSSIZE*4] = 0xff;
                            lensTexture[ (rad+x)*4 + (rad-y)*LENSSIZE*4] = 0xff;
                            lensTexture[ (rad-x)*4 + (rad-y)*LENSSIZE*4] = 0xff;
                        }
                    }
                }
            }
            
            if( cursorhidden == NO)
            {
                cursorhidden = YES;
                [NSCursor hide];
            }
        }
    }
    
    [self setNeedsDisplay: YES];
}

- (void)makeTextureFromImage:(NSImage*)image forTexture:(GLuint*)texName buffer:(GLubyte*)buffer textureUnit:(GLuint)textureUnit;
{
    NSSize imageSize = [image size];
    
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    
    buffer = malloc([bitmap bytesPerRow] * imageSize.height);
    memcpy(buffer, [bitmap bitmapData], [bitmap bytesPerRow] * imageSize.height);
    
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
    if( cgl_ctx)
    {
        glGenTextures(1, texName);
        glActiveTexture(textureUnit);
        glBindTexture(GL_TEXTURE_RECTANGLE_EXT, *texName);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/[bitmap samplesPerPixel]);
        glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
        glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
        
        glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, ([bitmap samplesPerPixel]==4)?GL_RGBA:GL_RGB, imageSize.width, imageSize.height, 0, ([bitmap samplesPerPixel]==4)?GL_RGBA:GL_RGB, GL_UNSIGNED_BYTE, buffer);
    }
    
    [bitmap release];
}

-(void) mouseMovedInView: (NSPoint) eventLocationInWindow
{
    NSUInteger modifierFlags = [[[NSApplication sharedApplication] currentEvent] modifierFlags];
    NSPoint eventLocationInView = [self convertPoint: eventLocationInWindow fromView: nil];
    
    @try
    {
        [self deleteLens];
        
        [BrowserController updateActivity];
        
        float	cpixelMouseValueR = pixelMouseValueR;
        float	cpixelMouseValueG = pixelMouseValueG;
        float	cpixelMouseValueB = pixelMouseValueB;
        float	cmouseXPos = mouseXPos;
        float	cmouseYPos = mouseYPos;
        float	cpixelMouseValue = pixelMouseValue;
        
        pixelMouseValueR = 0;
        pixelMouseValueG = 0;
        pixelMouseValueB = 0;
        mouseXPos = 0;
        mouseYPos = 0;
        pixelMouseValue = 0;
        
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
        
        BOOL needUpdate = NO;
        
        [drawLock lock];
        
        @try
        {
            [[self openGLContext] makeCurrentContext];	// Important for iChat compatibility
            
            BOOL mouseOnImage = NO;
            
            NSPoint imageLocation = [self ConvertFromNSView2GL: eventLocationInView];
            
            mouseXPos = imageLocation.x;
            mouseYPos = imageLocation.y;
            
            if( imageLocation.x >= 0 && imageLocation.x < curDCM.pwidth)	//&& NSPointInRect( eventLocation, size)) <- this doesn't work in MPR Ortho
            {
                if( imageLocation.y >= 0 && imageLocation.y < curDCM.pheight)
                {
                    mouseOnImage = YES;
                    
                    if( (modifierFlags & NSShiftKeyMask) && (modifierFlags & NSControlKeyMask) && mouseDragging == NO)
                    {
                        [self sync3DPosition];
                    }
                    else if( (modifierFlags & (NSShiftKeyMask|NSCommandKeyMask|NSControlKeyMask|NSAlternateKeyMask)) == NSShiftKeyMask && mouseDragging == NO)
                    {
                        if( [self roiTool: currentTool] == NO)
                        {
                            [self computeMagnifyLens: imageLocation];
#ifdef new_loupe
                            [self displayLoupeWithCenter:NSMakePoint([[self window] frame].origin.x+[theEvent locationInWindow].x, [[self window] frame].origin.y+[theEvent locationInWindow].y)];
#endif
                        }
                    }
                    
                    int
                    xPos = (int)mouseXPos,
                    yPos = (int)mouseYPos;
                    
                    if( curDCM.isRGB )
                    {
                        pixelMouseValueR = ((unsigned char*) curDCM.fImage)[ 4 * (xPos + yPos * curDCM.pwidth) +1];
                        pixelMouseValueG = ((unsigned char*) curDCM.fImage)[ 4 * (xPos + yPos * curDCM.pwidth) +2];
                        pixelMouseValueB = ((unsigned char*) curDCM.fImage)[ 4 * (xPos + yPos * curDCM.pwidth) +3];
                    }
                    else pixelMouseValue = [curDCM getPixelValueX: xPos Y:yPos];
                }
            }
            
            // Blended view
            if( blendingView)
            {
                NSPoint blendedLocation = [blendingView ConvertFromNSView2GL: eventLocationInView];
                
                if( blendedLocation.x >= 0 && blendedLocation.x < [[blendingView curDCM] pwidth])
                {
                    if( blendedLocation.y >= 0 && blendedLocation.y < [[blendingView curDCM] pheight])
                    {
                        blendingMouseXPos = blendedLocation.x;
                        blendingMouseYPos = blendedLocation.y;
                        
                        int xPos = (int)blendingMouseXPos,
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
            
            // Are we near a ROI point?
            if( [self roiTool: currentTool])
            {
                NSPoint pt = [self convertPoint: eventLocationInWindow fromView:nil];
                pt = [self ConvertFromNSView2GL: pt];
                
                for( ROI *r in curRoiList)
                    [r displayPointUnderMouse :pt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue];
                
                if( [[[NSApplication sharedApplication] currentEvent] type] == NSMouseMoved)
                {
                    // Should we change the mouse cursor?
                    if( (modifierFlags & NSDeviceIndependentModifierFlagsMask)) [self flagsChanged: [[NSApplication sharedApplication] currentEvent]];
                }
            }
            
            if( [NSUserDefaults.standardUserDefaults boolForKey: @"ROITextIfMouseIsOver"] && [NSUserDefaults.standardUserDefaults boolForKey:@"ROITEXTIFSELECTED"])
            {
                if( mouseDragging == NO)
                {
                    NSPoint pt = [self convertPoint: eventLocationInWindow fromView:nil];
                    pt = [self ConvertFromNSView2GL: pt];
                    
                    for( ROI *r in curRoiList)
                    {
                        BOOL c = r.clickInTextBox;
                        
                        if( [r clickInROI:pt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :NO])
                        {
                            if( !r.mouseOverROI)
                            {
                                r.mouseOverROI = YES;
                                [self setNeedsDisplay: YES];
                            }
                        }
                        else if( r.mouseOverROI)
                        {
                            r.mouseOverROI = NO;
                            [self setNeedsDisplay: YES];
                        }
                        r.clickInTextBox = c;
                    }
                }
            }
            
            if(!mouseOnImage)
            {
#ifdef new_loupe
                [self hideLoupe];
#endif
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        [drawLock unlock];
        
        if(	cpixelMouseValueR != pixelMouseValueR)	needUpdate = YES;
        if(	cpixelMouseValueG != pixelMouseValueG)	needUpdate = YES;
        if(	cpixelMouseValueB != pixelMouseValueB)	needUpdate = YES;
        if(	cmouseXPos != mouseXPos)	needUpdate = YES;
        if(	cmouseYPos != mouseYPos)	needUpdate = YES;
        if(	cpixelMouseValue != pixelMouseValue)	needUpdate = YES;
        if( cblendingMouseXPos != blendingMouseXPos) needUpdate = YES;
        if( cblendingMouseYPos != blendingMouseYPos) needUpdate = YES;
        if( cblendingPixelMouseValue != blendingPixelMouseValue) needUpdate = YES;
        if( cblendingPixelMouseValueR != blendingPixelMouseValueR) needUpdate = YES;
        if( cblendingPixelMouseValueG != blendingPixelMouseValueG) needUpdate = YES;
        if( cblendingPixelMouseValueB != blendingPixelMouseValueB) needUpdate = YES;
        
        if( needUpdate)
        {
            [self setNeedsDisplay: YES];
            [[NSNotificationCenter defaultCenter] postNotificationName: @"DCMViewMouseMovedUpdated" object: self];
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
}

- (void) DCMViewMouseMovedUpdated: (NSNotification*) n
{
    if( n.object != self)
    {
        float	cpixelMouseValueR = pixelMouseValueR, cpixelMouseValueG = pixelMouseValueG, cpixelMouseValueB = pixelMouseValueB;
        float	cmouseXPos = mouseXPos, cmouseYPos = mouseYPos;
        float	cpixelMouseValue = pixelMouseValue;
        
        pixelMouseValueR =  pixelMouseValueG =  pixelMouseValueB =  mouseXPos =  mouseYPos =  pixelMouseValue = 0;
        
        float	cblendingMouseXPos = blendingMouseXPos, cblendingMouseYPos = blendingMouseYPos;
        float	cblendingPixelMouseValue = blendingPixelMouseValue, cblendingPixelMouseValueR = blendingPixelMouseValueR, cblendingPixelMouseValueG = blendingPixelMouseValueG, cblendingPixelMouseValueB = blendingPixelMouseValueB;
        
        blendingMouseXPos =  blendingMouseYPos =  blendingPixelMouseValue =  blendingPixelMouseValueR =  blendingPixelMouseValueG =  blendingPixelMouseValueB = 0;
        
        BOOL needUpdate = NO;
        
        if(	cpixelMouseValueR != pixelMouseValueR) needUpdate = YES;
        if(	cpixelMouseValueG != pixelMouseValueG) needUpdate = YES;
        if(	cpixelMouseValueB != pixelMouseValueB) needUpdate = YES;
        if(	cmouseXPos != mouseXPos) needUpdate = YES;
        if(	cmouseYPos != mouseYPos) needUpdate = YES;
        if(	cpixelMouseValue != pixelMouseValue) needUpdate = YES;
        if( cblendingMouseXPos != blendingMouseXPos) needUpdate = YES;
        if( cblendingMouseYPos != blendingMouseYPos) needUpdate = YES;
        if( cblendingPixelMouseValue != blendingPixelMouseValue) needUpdate = YES;
        if( cblendingPixelMouseValueR != blendingPixelMouseValueR) needUpdate = YES;
        if( cblendingPixelMouseValueG != blendingPixelMouseValueG) needUpdate = YES;
        if( cblendingPixelMouseValueB != blendingPixelMouseValueB) needUpdate = YES;
        
        if( needUpdate)
            [self setNeedsDisplay: YES];
    }
}

-(void) mouseMoved: (NSEvent*) theEvent
{
    if( CGCursorIsVisible() == NO && lensTexture == nil) return; //For Synergy compatibility
    if( ![[self window] isVisible])
    {
        if( [self is2DViewer] && [[self windowController] FullScreenON])
        {
            
        }
        else
            return;
    }
    
    if ([self eventToPlugins:theEvent]) return;
    
    if( !drawing) return;
    
    if( [self is2DViewer] == YES)
    {
        if( [[self windowController] windowWillClose]) return;
    }
    
    if( curDCM == nil) return;
    
    if( dcmPixList == nil) return;
    
    if( avoidMouseMovedRecursive)
        return;
    
    avoidMouseMovedRecursive = YES;
    
    NSPoint eventLocation = [[self window] mouseLocationOutsideOfEventStream];
    
    if( [[self window] isVisible])
    {
        id view = [self.window.contentView hitTest: eventLocation];
        
        if( [view isKindOfClass: [DCMView class]])
            [view mouseMovedInView: eventLocation];
        
        if ([self is2DViewer] == YES && [self.window isKeyWindow])
            [[self windowController] autoHideMatrix];
    }
    
    avoidMouseMovedRecursive = NO;
}

- (ToolMode) getTool: (NSEvent*) event
{
    ToolMode tool;
    
    if( [event type] == NSRightMouseDown || [event type] == NSRightMouseDragged) tool = currentToolRight;
    else if( [event type] == NSOtherMouseDown || [event type] == NSOtherMouseDragged) tool = tTranslate;
    else tool = currentTool;
    
    if (([event modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
    if (([event modifierFlags] & (NSShiftKeyMask|NSAlternateKeyMask)) == NSAlternateKeyMask)  tool = tWL;
    if (([event modifierFlags] & NSControlKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))
    {
        if( blendingView) tool = tWLBlended;
        else tool = tWL;
    }
    
    if( [self roiTool:currentTool] != YES && currentTool != tROISelector)   // Not a ROI TOOL !
    {
        if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))  tool = tRotate;
        if (([event modifierFlags] & NSShiftKeyMask))  tool = tZoom;
    }
    else
    {
        if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))  tool = tRotate;
        // 		if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask)) tool = currentTool;
        //		if (([event modifierFlags] & NSCommandKeyMask)) tool = currentTool;
    }
    
    return tool;
}

- (void) setStartWLWW
{
    startWW = curDCM.ww;
    startWL = curDCM.wl;
    startMin = curDCM.wl - curDCM.ww/2;
    startMax = curDCM.wl + curDCM.ww/2;
    
    bdstartWW = [[blendingView curDCM] ww];
    bdstartWL = [[blendingView curDCM] wl];
    bdstartMin = [[blendingView curDCM] wl] - [[blendingView curDCM] ww]/2;
    bdstartMax = [[blendingView curDCM] wl] + [[blendingView curDCM] ww]/2;
}

- (ROI*) clickInROI: (NSPoint) tempPt
{
    for( ROI * r in curRoiList)
    {
        if([r clickInROI:tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :NO])
            return r;
    }
    
    return nil;
}

- (void) sync3DPosition
{
    float location[ 3];
    
    [curDCM convertPixX: mouseXPos pixY: mouseYPos toDICOMCoords: location pixelCenter: YES];
    
    DCMPix	*thickDCM;
    
    if( curDCM.stack > 1)
    {
        long maxVal = curImage+(curDCM.stack-1);
        if( maxVal < 0) maxVal = 0;
        if( maxVal >= [dcmPixList count]) maxVal = (long)[dcmPixList count]-1;
        
        thickDCM = [dcmPixList objectAtIndex: maxVal];
    }
    else thickDCM = nil;
    
    int pos = flippedData? (long)[dcmPixList count] -1 -curImage : curImage;
    
    NSMutableDictionary *instructions = [NSMutableDictionary dictionary];
    
    [instructions setObject: self forKey: @"view"];
    [instructions setObject: [NSNumber numberWithLong: pos] forKey: @"Pos"];
    [instructions setObject: [NSNumber numberWithFloat:[(DCMPix*)[dcmPixList objectAtIndex:curImage] sliceLocation]] forKey: @"Location"];
    
    if( [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.studyInstanceUID"])
        [instructions setObject: [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.studyInstanceUID"] forKey: @"studyID"];
    
    if( curDCM)
        [instructions setObject: curDCM forKey: @"DCMPix"];
    
    if( curDCM.frameofReferenceUID)
        [instructions setObject: curDCM.frameofReferenceUID forKey: @"frameofReferenceUID"];
    
    [instructions setObject: [NSNumber numberWithFloat: syncRelativeDiff] forKey: @"offsetsync"];
    [instructions setObject: [NSNumber numberWithFloat: location[0]] forKey: @"point3DX"];
    [instructions setObject: [NSNumber numberWithFloat: location[1]] forKey: @"point3DY"];
    [instructions setObject: [NSNumber numberWithFloat: location[2]] forKey: @"point3DZ"];
    
    if( thickDCM)
        [instructions setObject: thickDCM forKey: @"DCMPix2"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixSyncNotification object: self userInfo: instructions];
}

// TrackPad support

//- (void)touchesBeganWithEvent:(NSEvent *)event
//{
//    NSSet *touches = [event touchesMatchingPhase: NSTouchPhaseTouching inView: self];
//
//    if (touches.count == 2)
//	{
//		NSPoint initialPoint = [self convertPointFromBase: [event locationInWindow]];
//        NSArray *array = [touches allObjects];
//
//		NSLog( @"%@", array);
//    }
//	else if (touches.count == 3)
//	{
//
//    }
//}
//
//- (void)touchesMovedWithEvent:(NSEvent *)event
//{
//    self.modifiers = [event modifierFlags];
//    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView: self];
//
//    if (touches.count == 2 && _initialTouches[0])
//	{
//        NSArray *array = [touches allObjects];
//
//        NSLog( @"%@", array);
//    }
//}
//
//- (void)touchesEndedWithEvent:(NSEvent *)event
//{
//
//}
//
//- (void)touchesCancelledWithEvent:(NSEvent *)event
//{
//
//}

-(void) magnifyWithEvent:(NSEvent *)anEvent
{
    [self setScaleValue: scaleValue + anEvent.deltaZ / 60.];
    
    [self setNeedsDisplay:YES];
}

-(void) rotateWithEvent:(NSEvent *)anEvent
{
    [self setRotation: rotation - anEvent.rotation * 1.5];
    
    [self setNeedsDisplay:YES];
}

-(void) swipeWithEvent:(NSEvent *)anEvent
{
    if( [self is2DViewer])
    {
        ViewerController *v = [self windowController];
        
        if( anEvent.deltaX < -0.5)
            [v loadSeriesUp];
        
        if( anEvent.deltaX > 0.5)
            [v loadSeriesDown];
        
        if( anEvent.deltaY < -0.5)
            [v loadSeriesUp];
        
        if( anEvent.deltaY > 0.5)
            [v loadSeriesDown];
    }
}

- (void) deleteInvalidROIsForArray: (NSMutableArray*) r
{
    [r retain]; //OsirixRemoveROINotification or OsirixROIRemovedFromArrayNotification can change/delete the NSArray !
    
    @try {
        for( int i = 0; i < [r count]; i++)
        {
            if( [[r objectAtIndex: i] valid] == NO)
            {
                if( curROI == [r objectAtIndex: i])
                {
                    [curROI autorelease];
                    curROI = nil;
                    drawingROI = NO;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object: [r objectAtIndex: i] userInfo: nil];
                [r removeObjectAtIndex: i];
                i--;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIRemovedFromArrayNotification object:NULL userInfo:NULL];
            }
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    [r autorelease];
}

- (void) deleteInvalidROIs
{
    if( dcmRoiList == nil) // For sub-classes, such as MPR, Curved-MPR, ... they don't have the dcmRoiList array
        [self deleteInvalidROIsForArray: curRoiList];
    else
    {
        for( NSMutableArray *r in dcmRoiList)
            [self deleteInvalidROIsForArray: r];
    }
}

- (void) mouseDown:(NSEvent *)event
{
    if( CGCursorIsVisible() == NO && lensTexture == nil) return; //For Synergy compatibility
    if ([self eventToPlugins:event]) return;
    
    currentMouseEventTool = -1;
    
    if( !drawing) return;
    if( [[self window] isVisible] == NO) return;
    if( curDCM == nil) return;
    if( curImage < 0) return;
    if( [self is2DViewer] == YES)
    {
        if( [[self windowController] windowWillClose]) return;
    }
    
    if( [self is2DViewer] == YES && [event type] == NSLeftMouseDown)
    {
        if( ([event modifierFlags] & NSShiftKeyMask) == 0 && ([event modifierFlags] & NSControlKeyMask) == 0 && ([event modifierFlags] & NSAlternateKeyMask) == 0 && ([event modifierFlags] & NSCommandKeyMask) == 0)
        {
            NSPoint tempPt = [[[event window] contentView] convertPoint: [event locationInWindow] toView:self];
            tempPt = [self ConvertFromNSView2GL:tempPt];
            
            NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:tempPt.y], @"Y", [NSNumber numberWithLong:tempPt.x],@"X", [NSNumber numberWithBool: NO], @"stopMouseDown", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixMouseDownNotification object: [self windowController] userInfo: dict];
            
            if( [[dict valueForKey:@"stopMouseDown"] boolValue]) return;
        }
    }
    
    if (_mouseDownTimer)
        [self deleteMouseDownTimer];
    
    if ([event type] == NSLeftMouseDown)
        _mouseDownTimer = [[NSTimer scheduledTimerWithTimeInterval: self.timeIntervalForDrag target:self selector:@selector(startDrag:) userInfo: event  repeats:NO] retain];
    
    if( dcmPixList)
    {
        [drawLock lock];
        
        @try
        {
            [self deleteLens];
            
            [self erase2DPointMarker];
            if( blendingView) [blendingView erase2DPointMarker];
            
            NSPoint     eventLocation = [event locationInWindow];
            NSRect      size = [self frame];
            ToolMode	tool;
            
            [self mouseMoved: event];	// Update some variables...
            
            start = previous = [self convertPoint:eventLocation fromView: nil];
            
            BOOL roiHit = NO;
            
            if( [self roiTool: currentTool] || currentTool == tRepulsor || currentTool == tROISelector)
            {
                NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
                tempPt = [self ConvertFromNSView2GL:tempPt];
                if( [self clickInROI: tempPt]) roiHit = YES;
            }
            
            if( roiHit == NO)
                tool = [self getTool: event];
            else
                tool = currentTool;
            
            startImage = curImage;
            [self setStartWLWW];
            startScaleValue = scaleValue;
            rotationStart = rotation;
            blendingFactorStart = blendingFactor;
            scrollMode = 0;
            resizeTotal = 1;
            
            originStart = origin;
            
            mesureB = mesureA = [self convertPoint:eventLocation fromView: nil];
            mesureB.y = mesureA.y = size.size.height - mesureA.y ;
            
            roiRect.origin = [self convertPoint:eventLocation fromView: nil];
            roiRect.origin.y = size.size.height - roiRect.origin.y;
            
            int clickCount = 1;
            @try
            {
                if( [event type] ==	NSLeftMouseDown || [event type] ==	NSRightMouseDown || [event type] ==	NSLeftMouseUp || [event type] == NSRightMouseUp)
                    clickCount = [event clickCount];
            }
            @catch (NSException * e)
            {
                clickCount = 1;
            }
            
            if( clickCount > 1 && _mouseDownTimer)
                [self deleteMouseDownTimer];
            
            if( clickCount == 2 && [self window] == [[BrowserController currentBrowser] window])
            {
                [[BrowserController currentBrowser] matrixDoublePressed:nil];
            }
            else if( clickCount == 2 && roiHit == NO && ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSCommandKeyMask) && [self actionForHotKey: @"dbl-click + cmd"])
            {
                return;
            }
            else if( clickCount == 2 && roiHit == NO && ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask) && [self actionForHotKey: @"dbl-click + alt"])
            {
                return;
            }
            else if( clickCount == 2 && roiHit == NO && stringID == nil && [self actionForHotKey: @"dbl-click"])
            {
                return;
            }
            
            crossMove = -1;
            
            if( tool == tRotate)
            {
                NSPoint current = [self currentPointInView:event];
                
                current.x -= [self frame].size.width/2.;
                current.y -= [self frame].size.height/2.;
                
                float sign = 1;
                
                if( xFlipped) sign = -sign;
                if( yFlipped) sign = -sign;
                
                rotationStart -= sign*atan2( current.x, current.y) / deg2rad;
            }
            
            if(tool == tRepulsor)
            {
                [self deleteMouseDownTimer];
                
                [[self windowController] addToUndoQueue:@"roi"];
                
                NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
                tempPt = [self ConvertFromNSView2GL:tempPt];
                
                BOOL clickInROI = NO;
                for( ROI *r in curRoiList)
                {
                    if([r clickInROI:tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :YES])
                    {
                        clickInROI = YES;
                    }
                }
                
                if(!clickInROI)
                {
                    for( ROI *r in curRoiList)
                    {
                        if([r clickInROI:tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :NO])
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
                    repulsorColorTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setAlphaRepulsor:) userInfo:event repeats:YES] retain];
                    repulsorAlpha = 0.1;
                    repulsorAlphaSign = 1.0;
                    repulsorRadius = 0;
                    
                    float pixSpacingRatio = 1.0;
                    if ( self.pixelSpacingY != 0 && self.pixelSpacingX != 0 )
                        pixSpacingRatio = self.pixelSpacingY / self.pixelSpacingX;
                    
                    NSArray *roiArray = [self selectedROIs];
                    if( [roiArray count] == 0) roiArray = curRoiList;
                    
                    float distance = 0;
                    if( [roiArray count]>0)
                    {
                        ROI *r = [roiArray objectAtIndex:0];
                        if( r.type != tPlain && r.type != tArrow && r.type != tAngle && r.type != tAxis && r.type != tDynAngle && r.type != tTAGT)
                        {
                            NSPoint pt = [[[[roiArray objectAtIndex:0] points] objectAtIndex:0] point];
                            float dx = (pt.x-tempPt.x);
                            float dx2 = dx * dx;
                            float dy = (pt.y-tempPt.y)*pixSpacingRatio;
                            float dy2 = dy * dy;
                            distance = sqrt(dx2 + dy2);
                        }
                    }
                    
                    NSMutableArray *points;
                    for( int i = 0; i < [roiArray count]; i++ )
                    {
                        ROI *r = [roiArray objectAtIndex: i];
                        if( r.type != tPlain && r.type != tArrow && r.type != tAngle && r.type != tAxis && r.type != tDynAngle && r.type != tTAGT)
                        {
                            points = [r points];
                            
                            for( int j = 0; j < [points count]; j++ )
                            {
                                NSPoint pt = [[points objectAtIndex:j] point];
                                float dx = (pt.x-tempPt.x);
                                float dx2 = dx * dx;
                                float dy = (pt.y-tempPt.y) *pixSpacingRatio;
                                float dy2 = dy * dy;
                                float d = sqrt(dx2 + dy2);
                                distance = (d < distance) ? d : distance ;
                            }
                        }
                    }
                    repulsorRadius = (int) ((distance + 0.5) * 0.8);
                    if(repulsorRadius < 2) repulsorRadius = 2;
                    if(repulsorRadius>curDCM.pwidth/2) repulsorRadius = curDCM.pwidth/2;
                    
                    if( [roiArray count] == 0 || distance == 0)
                    {
                        NSRunCriticalAlertPanel(NSLocalizedString(@"Repulsor",nil),NSLocalizedString(@"The Repulsor tool works only if ROIs (Length ROI, Opened and Closed Polygon ROI and Pencil ROI) are on the image.",nil), NSLocalizedString(@"OK",nil), nil,nil);
                    }
                }
            }
            
            if(tool == tROISelector)
            {
                ROISelectorSelectedROIList = [[NSMutableArray array] retain];
                
                // if shift key is pressed, we need to keep track of the ROIs that were selected before the click
                if([event modifierFlags] & NSShiftKeyMask)
                {
                    for( ROI *r in curRoiList)
                    {
                        if([r ROImode]==ROI_selected)
                            [ROISelectorSelectedROIList addObject: r];
                    }
                }
                
                NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
                
                ROISelectorStartPoint = tempPt;
                ROISelectorEndPoint = tempPt;
                
                ROISelectorStartPoint.y = [self frame].size.height - ROISelectorStartPoint.y;
                ROISelectorEndPoint.y = [self frame].size.height - ROISelectorEndPoint.y;
                
                [self deleteMouseDownTimer];
                
                tempPt = [self ConvertFromNSView2GL:tempPt];
                
                BOOL clickInROI = NO;
                for( ROI *r in curRoiList)
                {
                    if([r clickInROI:tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :YES])
                    {
                        clickInROI = YES;
                    }
                }
                
                if(!clickInROI)
                {
                    for( ROI *r in curRoiList)
                    {
                        if([r clickInROI:tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :NO])
                        {
                            clickInROI = YES;
                        }
                    }
                }
                
                if( clickInROI)
                {
                    currentTool = tPencil;
                    tool = tPencil;
                    selectorROIEdition = YES;
                }
            }
            
            // ROI TOOLS
            if( [self roiTool:tool] == YES && crossMove == -1 )
            {
                mouseDraggedForROIUndo = NO;
                
                if( !mouseDraggedForROIUndo) {
                    mouseDraggedForROIUndo = YES;
                    [[self windowController] addToUndoQueue:@"roi"];
                }
                
                @try
                {
                    [self deleteMouseDownTimer];
                    
                    BOOL		DoNothing = NO;
                    NSInteger	selected = -1;
                    NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
                    tempPt = [self ConvertFromNSView2GL:tempPt];
                    
                    if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotNone)
                    {
                        [[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
                        [DCMView setDefaults];
                    }
                    
                    BOOL roiFound = NO;
                    
                    if (!(([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSShiftKeyMask)))
                    {
                        for( ROI *r in curRoiList)
                        {
                            if( [r clickInROI: tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :YES])
                            {
                                selected = [curRoiList indexOfObject: r];
                                roiFound = YES;
                                break;
                            }
                        }
                    }
                    
                    //		if (roiFound)
                    //			if (curROI == [curRoiList objectAtIndex: selected])
                    //				DoNothing = YES;
                    
                    if( roiFound == NO)
                    {
                        for( ROI *r in curRoiList)
                        {
                            if( [r clickInROI: tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :NO])
                            {
                                selected = [curRoiList indexOfObject: r];
                                break;
                            }
                        }
                    }
                    
                    if (([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSCommandKeyMask) )
                    {
                        if( selected != -1 )
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
                            for( ROI *r in curRoiList) [r setROIMode : ROI_sleep];
                        }
                    }
                    
                    if( DoNothing == NO)
                    {
                        if( selected >= 0 && drawingROI == NO)
                        {
                            [curROI autorelease];
                            curROI = nil;
                            
                            // Bring the selected ROI to the first position in array
                            ROI *roi = [curRoiList objectAtIndex: selected];
                            
                            [[self windowController] bringToFrontROI: roi];
                            
                            selected = [curRoiList indexOfObject: roi];
                            
                            long roiVal = [roi clickInROI: tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :YES];
                            if( roiVal == ROI_sleep)
                                roiVal = [roi clickInROI: tempPt :curDCM.pwidth/2. :curDCM.pheight/2. :scaleValue :NO];
                            
                            if( [self is2DViewer])
                                [[self windowController] setMode:roiVal toROIGroupWithID:[roi groupID]]; // change the mode to the whole group before the selected ROI!
                            
                            [roi setROIMode: roiVal];
                            
                            NSArray *winList = [[NSApplication sharedApplication] windows];
                            BOOL	found = NO;
                            
                            if( [self is2DViewer])
                            {
                                for( int i = 0; i < [winList count]; i++)
                                {
                                    if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROI"])
                                    {
                                        found = YES;
                                        
                                        [[[winList objectAtIndex:i] windowController] setROI: roi :[self windowController]];
                                        if( clickCount > 1)
                                            [[winList objectAtIndex:i] makeKeyAndOrderFront: self];
                                    }
                                }
                                
                                if( clickCount > 1)
                                {
                                    if( found == NO)
                                    {
                                        ROIWindow* roiWin = [[ROIWindow alloc] initWithROI: roi :[self windowController]];
                                        [roiWin showWindow:self];
                                    }
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
                                    [curROI autorelease];
                                    curROI = nil;
                                }
                                
                                if( [curROI ROImode] == ROI_selected)
                                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object: curROI userInfo: nil];
                            }
                            else
                            {
                                // Unselect previous ROIs
                                for( ROI *r in curRoiList) [r setROIMode : ROI_sleep];
                                
                                ROI*		aNewROI;
                                NSString	*roiName = nil, *finalName;
                                long		counter;
                                BOOL		existsAlready;
                                
                                drawingROI = NO;
                                
                                [curROI autorelease];
                                curROI = aNewROI = [[[ROI alloc] initWithType: tool : curDCM.pixelSpacingX :curDCM.pixelSpacingY : [DCMPix originCorrectedAccordingToOrientation: curDCM]] autorelease];	//NSMakePoint( curDCM.originX, curDCM.originY)];
                                [curROI retain];
                                
                                if ( [ROI defaultName] != nil )
                                {
                                    [aNewROI setName: [ROI defaultName]];
                                }
                                else
                                {
                                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"EmptyNameForNewROIs"] == NO || tool == t2DPoint)
                                    {
                                        switch( tool)
                                        {
                                            case  tOval:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Oval ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tDynAngle:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Dynamic Angle ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tTAGT:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Perpendicular Distance ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tAxis:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Bone Axis ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tOPolygon:
                                            case tCPolygon:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Polygon ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tAngle:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Angle ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tArrow:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Arrow ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tPlain:
                                            case tPencil:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"ROI ", @"ROI = Region of Interest, keep the space at the end of the string")];
                                                break;
                                                
                                            case tMesure:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Measurement ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case tROI:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Rectangle ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            case t2DPoint:
                                                roiName = [NSString stringWithString: NSLocalizedString( @"Point ", @"keep the space at the end of the string")];
                                                break;
                                                
                                            default:;
                                        }
                                        
                                        if( roiName )
                                        {
                                            counter = 1;
                                            do
                                            {
                                                existsAlready = NO;
                                                
                                                finalName = [roiName stringByAppendingFormat:@"%d", (int) counter++];
                                                
                                                for( int i = 0; i < [dcmRoiList count]; i++)
                                                {
                                                    for( int x = 0; x < [[dcmRoiList objectAtIndex: i] count]; x++)
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
                                }
                                
                                // Create aliases of current ROI to the entire series
                                if (([event modifierFlags] & NSShiftKeyMask) && !([event modifierFlags] & NSCommandKeyMask))
                                {
                                    for( int i = 0; i < [dcmRoiList count]; i++)
                                    {
                                        [[dcmRoiList objectAtIndex: i] addObject: aNewROI];
                                    }
                                    
                                    aNewROI.originalIndexForAlias = curImage;
                                    aNewROI.isAliased = YES;
                                }
                                else [curRoiList addObject: aNewROI];
                                
                                [aNewROI setCurView:self];
                                
                                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"markROIImageAsKeyImage"])
                                {
                                    if( [self is2DViewer] == YES && [self isKeyImage] == NO && [[self windowController] isPostprocessed] == NO)
                                        [[self windowController] setKeyImage: self];
                                }
                                
                                [[self windowController] bringToFrontROI: aNewROI];
                                
                                drawingROI = [aNewROI mouseRoiDown: tempPt :scaleValue];
                                
                                if( drawingROI == NO)
                                {
                                    [curROI autorelease];
                                    curROI = nil;
                                }
                                
                                //								NSNumber *xx = nil, *yy = nil, *zz = nil;
                                //								if( [aNewROI type] == t2DPoint)
                                //								{
                                //									float location[ 3];
                                //
                                //									[curDCM convertPixX: [[[aNewROI points] objectAtIndex:0] x] pixY: [[[aNewROI points] objectAtIndex:0] y] toDICOMCoords: location pixelCenter: YES];
                                //
                                //									xx = [NSNumber numberWithFloat: location[ 0]];
                                //									yy = [NSNumber numberWithFloat: location[ 1]];
                                //									zz = [NSNumber numberWithFloat: location[ 2]];
                                //								}
                                
                                if( [aNewROI ROImode] == ROI_selected)
                                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object: aNewROI userInfo: nil];
                                
                                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	aNewROI,							@"ROI",
                                                          [NSNumber numberWithInt:curImage],	@"sliceNumber",
                                                          //xx, @"x", yy, @"y", zz, @"z",
                                                          nil];
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixAddROINotification object: self userInfo:userInfo];
                            }
                        }
                    }
                    
                    [self deleteInvalidROIs];
                }
                @catch (NSException * e)
                {
                    NSLog( @"**** mouseDown ROI : %@", e);
                }
            }
            
            currentMouseEventTool = tool;
            
            [self mouseDragged:event];
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        [drawLock unlock];
    }
    
    //	float pixPosition[ 3];
    //	float slicePosition[ 3];
    //	float dcmPosition[ 3];
    //
    //	pixPosition[ 0] = 256;
    //	pixPosition[ 1] = 256;
    //	pixPosition[ 2] = curImage;
    //
    //	NSLog( @"IN - Pixel coordinates in slice: %f %f slice index: %d", pixPosition[ 0], pixPosition[ 1], (int) pixPosition[ 2]);
    //
    //	[[dcmPixList objectAtIndex: curImage] convertPixX: pixPosition[ 0] pixY: pixPosition[ 1] toDICOMCoords: dcmPosition pixelCenter: YES];
    //
    //	NSLog( @"DICOM coordinates in mm : %f %f %f", dcmPosition[ 0], dcmPosition[ 1], dcmPosition[ 2]);
    //
    //	[[dcmPixList objectAtIndex: 0] convertDICOMCoords: dcmPosition toSliceCoords: slicePosition pixelCenter: YES];
    //
    //	slicePosition[ 0] /= [curDCM pixelSpacingX];
    //	slicePosition[ 1] /= [curDCM pixelSpacingY];
    //	slicePosition[ 2] /= [curDCM sliceInterval];
    //
    //	NSLog( @"OUT - Pixel coordinates in slice: %f %f slice index: %d", slicePosition[ 0], slicePosition[ 1], (int) slicePosition[ 2]);
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    float reverseScrollWheel;
    
    float deltaX = [theEvent deltaX];
    float deltaY = [theEvent deltaY];
    
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_7
    if (![theEvent hasPreciseScrollingDeltas])
    {
        deltaX = [theEvent scrollingDeltaX];
        deltaY = [theEvent scrollingDeltaY];
    }
#endif
    
    if( [NSEvent pressedMouseButtons])
        return;
    
    
    if( curImage < 0) return;
    if( !drawing) return;
    if( [[self window] isVisible] == NO) return;
    if( [self is2DViewer] == YES)
    {
        if( [[self windowController] windowWillClose]) return;
    }
    
    BOOL SelectWindowScrollWheel = [[NSUserDefaults standardUserDefaults] boolForKey: @"SelectWindowScrollWheel"];
    
    if( [theEvent modifierFlags] & NSAlphaShiftKeyMask) // Caps Lock
        SelectWindowScrollWheel = !SelectWindowScrollWheel;
    
    if( SelectWindowScrollWheel)
    {
        if( [self is2DViewer])
        {
            if( [ViewerController isFrontMost2DViewer: self.window] == NO)
            {
                [[self window] makeKeyAndOrderFront: self];
                [self.windowController windowDidBecomeMain:[NSNotification notificationWithName:NSWindowDidBecomeMainNotification object:self.window]]; //If the application is in background, it will not automatically called.
            }
        }
        else if( [[self window] isMainWindow] == NO)
            [[self window] makeKeyAndOrderFront: self];
    }
    
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ZoomWithHorizonScroll"] == NO) deltaX = 0;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Scroll Wheel Reversed"])
        reverseScrollWheel = -1.0;
    else
        reverseScrollWheel = 1.0;
    
    if( flippedData) reverseScrollWheel *= -1.0;
    
    if( dcmPixList)
    {
        short inc = 0;
        
        if( [stringID isEqualToString:@"previewDatabase"])
        {
            [super scrollWheel: theEvent];
        }
        else
        {
            //NSLog(@"DeltaY = %f , DeltaX = %f",deltaY,deltaX);
            
            if( fabs(deltaY) * 2.0f >  fabs( deltaX) )
            {
                if( [theEvent modifierFlags]  & NSCommandKeyMask)
                {
                    if( [self is2DViewer] && blendingView)
                    {
                        float change = deltaY / -0.2f;
                        
                        blendingFactor += change;
                        [self setBlendingFactor: blendingFactor];
                    }
                }
                else if( [theEvent modifierFlags]  & NSAlternateKeyMask)
                {
                    if( [self is2DViewer] && [[self windowController] maxMovieIndex] > 1)
                    {
                        // 4D Direction scroll - Cardiac CT eg
                        float change = deltaY / -2.5f;
                        
                        if( change >= 0)
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
                    float change = reverseScrollWheel * deltaY / 2.5f;
                    
                    if( change >= 0)
                    {
                        change = ceil( change);
                        if( change < 1) change = 1;
                        
                        inc = curDCM.stack * change;
                        curImage += inc;
                    }
                    else
                    {
                        change = floor( change);
                        if( change > -1) change = -1;
                        
                        inc = curDCM.stack * change;
                        curImage += inc;
                    }
                }
                else
                {
                    float change = reverseScrollWheel * deltaY / 2.5f;
                    
                    if( change > 0)
                    {
                        if( [PluginManager isComPACS])
                            change = 1;
                        else if( change < 1)
                            change = 1;
                        
                        inc = _imageRows * _imageColumns * change;
                        curImage += inc;
                    }
                    else
                    {
                        if( [PluginManager isComPACS])
                            change = -1;
                        else if( change > -1)
                            change = -1;
                        
                        inc = _imageRows * _imageColumns * change;
                        curImage += inc;
                    }
                }
            }
            else if( fabs( deltaX) > 0.7 )
            {
                [self mouseMoved: theEvent];	// Update some variables...
                
                float sScaleValue = scaleValue;
                
                [self setScaleValue:sScaleValue + deltaX * scaleValue / 10];
                [self setOriginX: ((origin.x * scaleValue) / sScaleValue) Y: ((origin.y * scaleValue) / sScaleValue)];
                
                if( [self is2DViewer] == YES)
                    [[self windowController] propagateSettings];
                
                [self setNeedsDisplay:YES];
            }
            
            if( [self scrollThroughSeriesIfNecessary: curImage])
            {
            }
            else if( [dcmPixList count] > 3 && [[NSUserDefaults standardUserDefaults] boolForKey:@"loopScrollWheel"])
            {
                if( curImage < 0) curImage = (long)[dcmPixList count]-1;
                if( curImage >= [dcmPixList count]) curImage = 0;
            }
            else
            {
                if( curImage < 0) curImage = 0;
                if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count]-1;
            }
            
            if( listType == 'i') [self setIndex:curImage];
            else [self setIndexWithReset:curImage :YES];
            
            if( matrix ) {
                NSInteger rows, cols; [matrix getNumberOfRows:&rows columns:&cols];  if( cols < 1) cols = 1;
                [matrix selectCellAtRow :curImage/cols column:curImage%cols];
            }
            
            if( [self is2DViewer] == YES)
                [[self windowController] adjustSlider];    //mouseDown:theEvent];
            
            // SYNCRO
            [self sendSyncMessage:inc];
            
            if( [self is2DViewer] == YES)
                [[self windowController] propagateSettings];
            
            [self setNeedsDisplay:YES];
            
            [self displayIfNeeded];
        }
    }
}

- (void) otherMouseDown:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
    
    if( curImage < 0) return;
    
    [[self window] makeKeyAndOrderFront: self];
    [[self window] makeFirstResponder: self];
    [self sendSyncMessage: 0];
    
    [self mouseDown: event];
}

- (void) rightMouseDown:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
    
    if( curImage < 0) return;
    
    [[self window] makeKeyAndOrderFront: self];
    [[self window] makeFirstResponder: self];
    [self sendSyncMessage: 0];
    
    if( pluginOverridesMouse)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: curImage], @"curImage", event, @"event", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRightMouseDownNotification object: self userInfo: userInfo];
        return;
    }
    
    [self mouseDown: event];
}


- (void) rightMouseUp:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
    
    mouseDragging = NO;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:  [NSNumber numberWithInt:curImage], @"curImage", event, @"event", nil];
    
    if( pluginOverridesMouse)
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRightMouseUpNotification object: self userInfo: userInfo];
    else
    {
        int clickCount = 0;
        
        @try
        {
            if( [event type] ==	NSLeftMouseDown || [event type] ==	NSRightMouseDown || [event type] ==	NSLeftMouseUp || [event type] == NSRightMouseUp)
                clickCount = [event clickCount];
        }
        @catch (NSException * e)
        {
            clickCount = 1;
        }
        
        if (clickCount == 1)
        {
            if ([self is2DViewer])
            {
                ROI* roi = [self clickInROI:[self ConvertFromNSView2GL:[self convertPoint:[event locationInWindow] fromView:NULL]]];
                if (roi)
                    [[self windowController] computeContextualMenuForROI:roi];
                else [[self windowController] computeContextualMenu];
            }
            
            [NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: [DCMView findWLWWPreset: curWL :curWW :curDCM] userInfo: nil];
}

- (void)otherMouseDragged:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
    [self mouseDragged:(NSEvent *)event];
}

-(void)otherMouseUp:(NSEvent*)event {
    [self eventToPlugins:event];
}

- (void)rightMouseDragged:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
    
    if ( pluginOverridesMouse )
    {
        [self mouseMoved: event];	// Update some variables...
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:curImage], @"curImage", event, @"event", nil];
        [nc postNotificationName: OsirixRightMouseDraggedNotification object: self userInfo: userInfo];
        return;
    }
    
    [self mouseDragged:(NSEvent *)event];
}

-(NSMenu*) menuForEvent:(NSEvent *)theEvent
{
    if ( pluginOverridesMouse ) return nil;
    NSPoint contextualMenuWhere = [theEvent locationInWindow]; 	//JF20070103 WindowAnchored ctrl-clickPoint registered
    contextualMenuInWindowPosX = contextualMenuWhere.x;
    contextualMenuInWindowPosY = contextualMenuWhere.y;
    if (([theEvent modifierFlags] & NSControlKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) return nil;
    return [self menu];
}

- (IBAction) decreaseThickness: (id) sender
{
    for( ROI *r in curRoiList)
    {
        if( [r ROImode] == ROI_selected)
        {
            [r setThickness: [r thickness]-1];
        }
    }
    
    [self display];
}

- (IBAction) increaseThickness: (id) sender
{
    for( ROI *r in curRoiList)
    {
        if( [r ROImode] == ROI_selected)
        {
            [r setThickness: [r thickness]+1];
        }
    }
    
    [self display];
}

#pragma mark-
#pragma mark Mouse dragging methods
- (void)mouseDragged:(NSEvent *)event
{
    if( curImage < 0)
        return;
    
    if( CGCursorIsVisible() == NO && lensTexture == nil) return; //For Synergy compatibility
    
    if ([self eventToPlugins:event]) return;
    
    [self deleteLens];
    
    mouseDragging = YES;
    
    // if window is not visible do nothing
    if( [[self window] isVisible] == NO) return;
    
    // if window will close do nothing
    if( [self is2DViewer] == YES)
    {
        if( [[self windowController] windowWillClose]) return;
    }
    
    // We have dragged before timer went off turn off timer and contine with drag
    if (_dragInProgress == NO && ([event deltaX] != 0 || [event deltaY] != 0))
        [self deleteMouseDownTimer];
    
    // we are dragging don't do anything
    if (_dragInProgress == YES) return;
    
    // if we have images do drag
    if( dcmPixList)
    {
        [drawLock lock];
        
        @try
        {
            NSPoint     eventLocation = [event locationInWindow];
            NSPoint     current = [self convertPoint:eventLocation fromView: nil];
            ToolMode    tool = currentMouseEventTool;
            
            [self mouseMoved: event];	// Update some variables...
            
            if( crossMove >= 0) tool = tCross;
            
            // if ROI tool is valid continue with drag
            /**************** ROI actions *********************************/
            if( [self roiTool: tool])
            {
                BOOL	action = NO;
                
                NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
                
                // get point in Open GL
                tempPt = [self ConvertFromNSView2GL:tempPt];
                
                // check rois for hit Test.
                action = [self checkROIsForHitAtPoint:tempPt forEvent:event];
                
                // if we have action the ROI is being drawn. Don't move and rotate ROI
                if( action == NO) // Is there a selected ROI -> rotate or move it
                    action = [self mouseDraggedForROIs: event];
            }
            
            /********** Actions for Various Tools *********************/
            else
            {
                switch (tool)
                {
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
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        [drawLock unlock];
    }
}


// get current Point for Event in the local view Coordinates
- (NSPoint)currentPointInView:(NSEvent *)event
{
    NSPoint eventLocation = [event locationInWindow];
    return [self convertPoint: eventLocation fromView: nil];
}

// Check to see if an roi is selected at the Open GL point
- (BOOL)checkROIsForHitAtPoint:(NSPoint)point  forEvent:(NSEvent *)event
{
    BOOL haveHit = NO;
    
    for( ROI *r in [NSArray arrayWithArray: curRoiList])
    {
        if( r.locked == NO)
        {
            if( !mouseDraggedForROIUndo) {
                mouseDraggedForROIUndo = YES;
                [[self windowController] addToUndoQueue:@"roi"];
            }
            
            if( [r mouseRoiDragged: point :[event modifierFlags] :scaleValue] != NO)
                haveHit = YES;
        }
    }
    return haveHit;
}

// Modifies the Selected ROIs for the drag. Can rotate, scalem move the ROI or the Text Box.
- (BOOL) mouseDraggedForROIs:(NSEvent *)event
{
    BOOL action = NO;
    
    @try
    {
        NSPoint current = [self currentPointInView:event];
        
        // Command and Alternate rotate ROI
        if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))
        {
            if( !mouseDraggedForROIUndo) {
                mouseDraggedForROIUndo = YES;
                [[self windowController] addToUndoQueue:@"roi"];
            }
            
            NSPoint rotatePoint = [self ConvertFromNSView2GL: start];
            
            NSPoint offset;
            
            offset.x = - (previous.x - current.x) / scaleValue;
            offset.y =  (previous.y - current.y) / scaleValue;
            
            for( ROI *r in curRoiList)
            {
                if( [r ROImode] == ROI_selected)
                {
                    action = YES;
                    [r rotate: offset.x :rotatePoint];
                }
            }
        }
        // Command and Shift scale
        else if (([event modifierFlags] & NSCommandKeyMask) && !([event modifierFlags] & NSShiftKeyMask))
        {
            if( !mouseDraggedForROIUndo) {
                mouseDraggedForROIUndo = YES;
                [[self windowController] addToUndoQueue:@"roi"];
            }
            
            NSPoint rotatePoint = [self ConvertFromNSView2GL: start];
            
            double ss = 1.0 - (previous.x - current.x)/200.;
            
            if( resizeTotal*ss < 0.2) ss = 0.2 / resizeTotal;
            if( resizeTotal*ss > 5.) ss = 5. / resizeTotal;
            
            resizeTotal *= ss;
            
            for( ROI *r in curRoiList)
            {
                if( [r ROImode] == ROI_selected)
                {
                    action = YES;
                    [r resize: ss :rotatePoint];
                }
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
            
            offset.x *= self.window.backingScaleFactor;
            offset.y *= self.window.backingScaleFactor;
            
            if( xFlipped) offset.x = -offset.x;
            if( yFlipped) offset.y = -offset.y;
            
            xx = offset.x;		yy = offset.y;
            
            offset.x = xx*cos(rotation*deg2rad) + yy*sin(rotation*deg2rad);
            offset.y = -xx*sin(rotation*deg2rad) + yy*cos(rotation*deg2rad);
            
            offset.y /=  curDCM.pixelRatio;
            // hit test for text box
            for( ROI *r in curRoiList)
            {
                if( [r ROImode] == ROI_selected)
                {
                    if( [r clickInTextBox]) textBoxMove = YES;
                }
            }
            // Move text Box
            if( textBoxMove)
            {
                for( ROI *r in curRoiList)
                {
                    if( [r ROImode] == ROI_selected)
                    {
                        if( !mouseDraggedForROIUndo) {
                            mouseDraggedForROIUndo = YES;
                            [[self windowController] addToUndoQueue:@"roi"];
                        }
                        
                        action = YES;
                        [r setTextBoxOffset: offset];
                    }
                }
            }
            // move ROI
            else
            {
                for( ROI *r in curRoiList)
                {
                    if( [r ROImode] == ROI_selected && [r locked] == NO && [r type] != tPlain)
                    {
                        if( !mouseDraggedForROIUndo) {
                            mouseDraggedForROIUndo = YES;
                            [[self windowController] addToUndoQueue:@"roi"];
                        }
                        
                        action = YES;
                        [r roiMove: offset];
                    }
                }
            }
        }
    }
    @catch ( NSException *e)
    {
        NSLog( @"****** mouseDraggedForROIs: %@", e);
    }
    return action;
}


// Method for mouse dragging while 3D rotate. Does nothing
- (void)mouseDragged3DRotate:(NSEvent *)event
{
}

- (void)mouseDraggedCrosshair:(NSEvent *)event
{
}

// Methods for Zooming with mouse Drag
- (void)mouseDraggedZoom:(NSEvent *)event
{
    NSPoint current = [self currentPointInView:event];
    
    [self setScaleValue: (startScaleValue + (current.y - start.y) / (80. * [curDCM pwidth] / 512.))];
    
    NSPoint o = NSMakePoint( 0, 0);
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"MouseClickZoomCentered"])
    {
        NSPoint oo = [self convertPointToBacking: start];
        
        oo.x = (oo.x - drawingFrameRect.size.width/2.) - (((oo.x - drawingFrameRect.size.width/2.)* scaleValue) / startScaleValue);
        oo.y = (oo.y - drawingFrameRect.size.height/2.) - (((oo.y -drawingFrameRect.size.height/2.)* scaleValue) / startScaleValue);
        
        oo.y = -oo.y;
        
        if( xFlipped) oo.x = -oo.x;
        if( yFlipped) oo.y = -oo.y;
        
        o.x = oo.x*cos((rotation)*deg2rad) + oo.y*sin((rotation)*deg2rad);
        o.y = oo.x*sin((rotation)*deg2rad) - oo.y*cos((rotation)*deg2rad);
    }
    
    [self setOriginX: (((originStart.x ) * scaleValue) / startScaleValue) + o.x
                   Y: (((originStart.y ) * scaleValue) / startScaleValue) + o.y];
}

// Method for translating the image while dragging
- (void)mouseDraggedTranslate:(NSEvent *)event
{
    NSPoint current = [self currentPointInView:event];
    float xmove, ymove, xx, yy;
    
    xmove = (current.x - start.x);
    ymove = -(current.y - start.y);
    
    xmove *= [self.window backingScaleFactor];
    ymove *= [self.window backingScaleFactor];
    
    if( xFlipped) xmove = -xmove;
    if( yFlipped) ymove = -ymove;
    
    xx = xmove*cos((rotation)*deg2rad) + ymove*sin((rotation)*deg2rad);
    yy = xmove*sin((rotation)*deg2rad) - ymove*cos((rotation)*deg2rad);
    
    [self setOriginX: originStart.x + xx Y: originStart.y + yy];
    
    //set value for Series Object Presentation State
    if( [self is2DViewer] == YES && [[self windowController] isPostprocessed] == NO)
    {
        @try {
            [self.seriesObj setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
            [self.seriesObj setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
        }
        @catch ( NSException *e) {
            N2LogException( e);
        }
    }
}

//Method for rotating
- (void)mouseDraggedRotate:(NSEvent *)event
{
    NSPoint current = [self currentPointInView:event];
    
    current.x -= [self frame].size.width/2.;
    current.y -= [self frame].size.height/2.;
    
    float sign = 1;
    
    if( xFlipped) sign = -sign;
    if( yFlipped) sign = -sign;
    
    float rot = rotationStart + sign * atan2( current.x, current.y) / deg2rad;
    
    while( rot < 0) rot += 360;
    while( rot > 360) rot -= 360;
    
    self.rotation = rot;
}

//Scrolling through images with Mouse
// could be cleaned up by subclassing DCMView
- (void)mouseDraggedImageScroll:(NSEvent *)event
{
    short   previmage;
    BOOL	movie4Dmove = NO;
    NSPoint current = [self currentPointInView:event];
    if( scrollMode == 0)
    {
        if( fabs( start.x - current.x) < fabs( start.y - current.y))
        {
            if( fabs( start.y - current.y) > 3) scrollMode = 1;
        }
        else if( fabs( start.x - current.x) >= fabs( start.y - current.y))
        {
            if( fabs( start.x - current.x) > 3) scrollMode = 2;
        }
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
        if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count] -1;
        
        if(previmage != curImage)
        {
            if( listType == 'i') [self setIndex:curImage];
            else [self setIndexWithReset:curImage :YES];
            
            if (matrix) {
                NSInteger rows, cols; [matrix getNumberOfRows:&rows columns:&cols];  if( cols < 1) cols = 1;
                [matrix selectCellAtRow :curImage/cols column:curImage%cols];
            }
            
            if( [self is2DViewer] == YES)
                [[self windowController] adjustSlider];
            
            if( stringID) [[self windowController] adjustSlider];
            
            // SYNCRO
            [self sendSyncMessage: curImage - previmage];
        }
    }
}

- (void)mouseDraggedBlending:(NSEvent *)event
{
    float WWAdapter = bdstartWW / 100.0;
    NSPoint current = [self currentPointInView:event];
    
    if( WWAdapter < 0.001 * curDCM.slope) WWAdapter = 0.001 * curDCM.slope;
    
    if( [self is2DViewer] == YES)
    {
        [[[self windowController] thickSlabController] setLowQuality: YES];
    }
    
    if( [[[[blendingView dcmFilesList] objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[[blendingView dcmFilesList] objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"NM"]))
    {
        float startlevel;
        float endlevel;
        
        float eWW, eWL;
        
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
    
    [blendingView loadTextures];
    [self loadTextures];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixChangeWLWWNotification object: blendingView userInfo:nil];
    
}

- (void)mouseDraggedWindowLevel:(NSEvent *)event
{
    NSPoint current = [self currentPointInView:event];
    // Not blending
    //if( !(blendingView != nil))
    {
        float WWAdapter = startWW / 80.00;
        
        if( WWAdapter < 0.001 * curDCM.slope) WWAdapter = 0.001 * curDCM.slope;
        
        if( [self is2DViewer] == YES)
        {
            [[[self windowController] thickSlabController] setLowQuality: YES];
        }
        
        if( [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"NM"]))
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
        
        curWW = curDCM.ww;
        curWL = curDCM.wl;
        
        if( [self is2DViewer] == YES)
        {
            [[self windowController] setCurWLWWMenu: [DCMView findWLWWPreset: curWL :curWW :curDCM]];
        }
        
        [self setWLWW:curWL :curWW];
    }
}

- (NSMutableArray*) selectedROIs
{
    NSMutableArray *selectedRois = [NSMutableArray array];
    for( ROI *r in curRoiList)
    {
        long mode = [r ROImode];
        
        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
        {
            [selectedRois addObject: r];
        }
    }
    
    return selectedRois;
}

- (void)mouseDraggedRepulsor:(NSEvent *)event
{
    NSPoint eventLocation = [event locationInWindow];
    NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
    
    repulsorPosition = tempPt;
    tempPt = [self ConvertFromNSView2GL:tempPt];
    
    
    float pixSpacingRatio = 1.0;
    if( self.pixelSpacingY != 0 && self.pixelSpacingX !=0 )
        pixSpacingRatio = self.pixelSpacingY / self.pixelSpacingX;
    
    float minD = 10.0 / scaleValue;
    float maxD = 50.0 / scaleValue;
    float maxN = 10.0 * scaleValue;
    
    NSMutableArray *points;
    
    NSRect repulsorRect = NSMakeRect(tempPt.x-repulsorRadius, tempPt.y-repulsorRadius, repulsorRadius*2.0 , repulsorRadius*2.0);
    
    NSArray *roiArray = [self selectedROIs];
    if( [roiArray count] == 0) roiArray = curRoiList;
    
    for( int i=0; i<[roiArray count]; i++ )
    {
        ROI *r = [roiArray objectAtIndex:i];
        
        if([r type] != tAxis && [r type] != tAngle && [r type] != tArrow && [r type] != tDynAngle && [r type] != tTAGT && [r type] != tPlain && r.locked == NO)
        {
            points = [r points];
            int n = 0;
            for( int j=0; j<[points count]; j++ )
            {
                NSPoint pt = [[points objectAtIndex:j] point];
                if( NSPointInRect(pt, repulsorRect) )
                {
                    float dx = (pt.x-tempPt.x);
                    float dx2 = dx * dx;
                    float dy = (pt.y-tempPt.y)*pixSpacingRatio;
                    float dy2 = dy * dy;
                    float d = sqrt(dx2 + dy2);
                    
                    if( d < repulsorRadius )
                    {
                        if([r type] == t2DPoint)
                            [r setROIRect:NSOffsetRect([r rect],dx/d*repulsorRadius-dx,dy/d*repulsorRadius-dy)];
                        else
                            [[points objectAtIndex:j] move:dx/d*repulsorRadius-dx :dy/d*repulsorRadius-dy];
                        
                        pt.x += dx/d*repulsorRadius-dx;
                        pt.y += dy/d*repulsorRadius-dy;
                        
                        for( int delta = -1; delta <= 1; delta++ )
                        {
                            int k = j+delta;
                            if([r type] == tCPolygon || [r type] == tPencil)
                            {
                                if(k==-1)
                                    k = (long)[points count]-1;
                                else if(k==[points count])
                                    k = 0;
                            }
                            
                            if(k!=j && k>=0 && k<[points count])
                            {
                                NSPoint pt2 = [[points objectAtIndex:k] point];
                                float dx = (pt2.x-pt.x);
                                float dx2 = dx * dx;
                                float dy = (pt2.y-pt.y)*pixSpacingRatio;
                                float dy2 = dy * dy;
                                float d = sqrt(dx2 + dy2);
                                
                                if( d<=minD && d<repulsorRadius )
                                {
                                    [points removeObjectAtIndex:k];
                                    if(delta==-1) j--;
                                }
                                else if((d>=maxD || d>=repulsorRadius) && n<maxN)
                                {
                                    NSPoint pt3;
                                    pt3.x = (pt2.x+pt.x)/2.0;
                                    pt3.y = (pt2.y+pt.y)/2.0;
                                    MyPoint *p = [[[MyPoint alloc] initWithPoint:pt3] autorelease];
                                    int index = (delta==-1)? j : j+1 ;
                                    if(delta==-1) j++;
                                    [points insertObject:p atIndex:index];
                                    n++;
                                }
                            }
                        }
                        
                        if( r.type == tMesure)
                            r.type = tOPolygon;
                        
                        [r recompute];
                        
                        if( [[r comments] isEqualToString: @"morphing generated"])
                            [r setComments:@""];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:r userInfo: nil];
                    }
                }
            }
        }
    }
}

- (void)mouseDraggedROISelector:(NSEvent *)event
{
    NSMutableArray *points;
    
    // deselect all ROIs
    for( ROI *r in curRoiList)
    {
        // ROISelectorSelectedROIList contains ROIs that were selected _before_ the click
        if([ROISelectorSelectedROIList containsObject: r])// this will be possible only if shift key is pressed
            [r setROIMode:ROI_selected];
        else
            [r setROIMode:ROI_sleep];
    }
    
    NSRect frame = [self frame];
    NSPoint eventLocation = [event locationInWindow];
    NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
    tempPt.y = frame.size.height - tempPt.y ;
    ROISelectorEndPoint = tempPt;
    
    NSPoint	polyRect[ 4];
    
    NSRect rect;
    
    if( rotation == 0)
    {
        NSPoint tempStartPoint = [self ConvertFromUpLeftView2GL: [self convertPointToBacking: ROISelectorStartPoint]];
        NSPoint tempEndPoint = [self ConvertFromUpLeftView2GL: [self convertPointToBacking: ROISelectorEndPoint]];
        
        rect = NSMakeRect(min(tempStartPoint.x, tempEndPoint.x), min(tempStartPoint.y, tempEndPoint.y), fabs(tempStartPoint.x - tempEndPoint.x), fabs(tempStartPoint.y - tempEndPoint.y));
        
        if(rect.size.width<1)rect.size.width=1;
        if(rect.size.height<1)rect.size.height=1;
    }
    else
    {
        NSPoint tempStartPoint = [self convertPointToBacking: ROISelectorStartPoint];
        NSPoint tempEndPoint = [self convertPointToBacking: ROISelectorEndPoint];
        
        polyRect[ 0] = [self ConvertFromUpLeftView2GL:tempStartPoint];
        polyRect[ 1] = [self ConvertFromUpLeftView2GL:NSMakePoint(tempStartPoint.x,tempStartPoint.y - (tempStartPoint.y-tempEndPoint.y))];
        polyRect[ 2] = [self ConvertFromUpLeftView2GL:tempEndPoint];
        polyRect[ 3] = [self ConvertFromUpLeftView2GL:NSMakePoint(tempStartPoint.x - (tempStartPoint.x-tempEndPoint.x),tempStartPoint.y)];
    }
    
    // select ROIs in the selection rectangle
    for( ROI *roi in [NSArray arrayWithArray: curRoiList])
    {
        BOOL intersected = NO;
        ToolMode roiType = [roi type];
        
        if( rotation == 0)
        {
            if( roiType == tText)
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
                points = [roi splinePoints];
                
                if( points.count)
                {
                    NSPoint p1, p2;
                    for( int j=0; j<(long)[points count]-1 && !intersected; j++ )
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
        }
        else
        {
            if(roiType==tText)
            {
                float w = roi.rect.size.width/scaleValue;
                float h = roi.rect.size.height/scaleValue;
                NSPoint o = roi.rect.origin;
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
                points = [roi splinePoints];
                for( int j=0; j<[points count] && !intersected; j++ )
                {
                    intersected = [DCMPix IsPoint: [[points objectAtIndex:j] point] inPolygon:polyRect size:4];
                }
                
                if( !intersected)
                {
                    NSPoint	*p = malloc( sizeof( NSPoint) * [points count]);
                    for( int j=0; j<[points count]; j++)  p[ j] = [[points objectAtIndex:j] point];
                    for( int j=0; j<4 && !intersected; j++ )
                        intersected = [DCMPix IsPoint: polyRect[j] inPolygon:p size:[points count]];
                    free(p);
                }
                
                if( !intersected)
                {
                    points = [roi splinePoints];
                    if( points.count)
                    {
                        NSPoint p1, p2;
                        for( int j=0; j<(long)[points count]-1 && !intersected; j++)
                        {
                            p1 = [[points objectAtIndex:j] point];
                            p2 = [[points objectAtIndex:j+1] point];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[0] B2:polyRect[1] result: nil];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[1] B2:polyRect[2] result: nil];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[2] B2:polyRect[3] result: nil];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[3] B2:polyRect[0] result: nil];
                        }
                        
                        // last segment: between last point and first one
                        if(!intersected && roiType!=tMesure && roiType!=tAngle && roiType!=t2DPoint && roiType!=tOPolygon && roiType!=tArrow)
                        {
                            p1 = [[points lastObject] point];
                            p2 = [[points objectAtIndex:0] point];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[0] B2:polyRect[1] result: nil];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[1] B2:polyRect[2] result: nil];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[2] B2:polyRect[3] result: nil];
                            if( !intersected) intersected = [DCMView intersectionBetweenTwoLinesA1:p1 A2:p2 B1:polyRect[3] B2:polyRect[0] result: nil];
                        }
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
            else {
                [[self windowController] selectROI:roi deselectingOther:NO];
            }
        }
    }
}

#pragma mark-
#pragma mark ww/wl

- (void) getWLWW:(float*) wl :(float*) ww
{
    if( curDCM == nil)
    {
        if(wl) *wl = 0;
        if(ww) *ww = 0;
    }
    else
    {
        if(wl) *wl = curDCM.wl;
        if(ww) *ww = curDCM.ww;
    }
}

- (void) changeWLWW: (NSNotification*) note
{
    DCMPix	*otherPix = [note object];
    
    if( curImage < 0 || COPYSETTINGSINSERIES == NO)
        return;
    
    if( otherPix == curDCM)
        return;
    
    if( otherPix.isRGB != curDCM.isRGB)
    {
        if( otherPix.fullww > 250 && otherPix.fullww < 256 && curDCM.fullww > 250 && curDCM.fullww < 256)
        {
            
        }
        else
            return;
    }
    
    if( avoidChangeWLWWRecursive == NO)
    {
        avoidChangeWLWWRecursive = YES;
        
        BOOL updateMenu = NO;
        
        if( [dcmPixList containsObject: otherPix])
        {
            float iwl, iww;
            
            iww = otherPix.ww;
            iwl = otherPix.wl;
            
            if( iww != curDCM.ww || iwl != curDCM.wl)
            {
                [self setWLWW: iwl :iww];
                if( [self is2DViewer])
                    updateMenu = YES;
            }
        }
        
        if( blendingView)
        {
            if( [[blendingView dcmPixList] containsObject: otherPix])
            {
                float iwl, iww;
                
                iww = otherPix.ww;
                iwl = otherPix.wl;
                
                if( iww != [[blendingView curDCM] ww] || iwl != [[blendingView curDCM] wl])
                {
                    [blendingView setWLWW: iwl :iww];
                    [self loadTextures];
                    [self setNeedsDisplay:YES];
                }
            }
        }
        
        if( updateMenu || (otherPix == curDCM && [self is2DViewer] == YES))
            [[self windowController] setCurWLWWMenu: [DCMView findWLWWPreset: curWL :curWW :curDCM]];
        
        avoidChangeWLWWRecursive = NO;
    }
}

- (void) setWLWW:(float) wl :(float) ww
{
    [curDCM changeWLWW :wl : ww];
    
    if( curDCM)
    {
        curWW = curDCM.ww;
        curWL = curDCM.wl;
        curWLWWSUVConverted = curDCM.SUVConverted;
        curWLWWSUVFactor = 1.0;
        if( curWLWWSUVConverted && [self is2DViewer])
            curWLWWSUVFactor = [[self windowController] factorPET2SUV];
    }
    else
    {
        curWW = ww;
        curWL = wl;
        curWLWWSUVConverted = NO;
    }
    
    [self loadTextures];
    [self setNeedsDisplay:YES];
    
    if( avoidSetWLWWRentry == NO)
    {
        avoidSetWLWWRentry = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixChangeWLWWNotification object: curDCM userInfo:nil];
        avoidSetWLWWRentry = NO;
    }
    
    if( [self is2DViewer])
    {
        @try
        {
            //set value for Series Object Presentation State
            if( curDCM.SUVConverted == NO)
            {
                [self.seriesObj setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
                [self.seriesObj setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
                
                // Image Level
                if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
                {
                    [self.imageObj setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
                    [self.imageObj setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
                }
                else
                {
                    [self.imageObj setValue: nil forKey:@"windowWidth"];
                    [self.imageObj setValue: nil forKey:@"windowLevel"];
                }
            }
            else
            {
                if( [self is2DViewer] == YES)
                {
                    [self.seriesObj setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
                    [self.seriesObj setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
                    
                    // Image Level
                    if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
                    {
                        [self.imageObj setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
                        [self.imageObj setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
                    }
                    else
                    {
                        [self.imageObj setValue: nil forKey:@"windowWidth"];
                        [self.imageObj setValue: nil forKey:@"windowLevel"];
                    }
                }
            }
        }
        @catch (NSException *e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
        }
    }
}

- (void)discretelySetWLWW:(float)wl :(float)ww
{
    [curDCM changeWLWW :wl : ww];
    
    curWW = curDCM.ww;
    curWL = curDCM.wl;
    curWLWWSUVConverted = curDCM.SUVConverted;
    curWLWWSUVFactor = 1.0;
    if( curWLWWSUVConverted && [self is2DViewer])
        curWLWWSUVFactor = [[self windowController] factorPET2SUV];
    
    [self loadTextures];
    [self setNeedsDisplay:YES];
    
    if( [self is2DViewer])
    {
        @try {
            //set value for Series Object Presentation State
            if( curDCM.SUVConverted == NO)
            {
                [self.seriesObj setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
                [self.seriesObj setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
                
                // Image Level
                if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
                {
                    [self.imageObj setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
                    [self.imageObj setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
                }
                else
                {
                    [self.imageObj setValue: nil forKey:@"windowWidth"];
                    [self.imageObj setValue: nil forKey:@"windowLevel"];
                }
            }
            else
            {
                if( [self is2DViewer] == YES)
                {
                    [self.seriesObj setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
                    [self.seriesObj setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
                    
                    // Image Level
                    if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
                    {
                        [self.imageObj setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
                        [self.imageObj setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
                    }
                    else
                    {
                        [self.imageObj setValue: nil forKey:@"windowWidth"];
                        [self.imageObj setValue: nil forKey:@"windowLevel"];
                    }
                }
            }
        }
        @catch ( NSException *e) {
            N2LogException( e);
        }
    }
}

-(void) setFusion:(short) mode :(short) stacks
{
    thickSlabMode = mode;
    thickSlabStacks = stacks;
    
    for ( int i = 0; i < [dcmPixList count]; i++ )
    {
        [[dcmPixList objectAtIndex:i] setFusion:mode :stacks :flippedData];
    }
    
    if( [self is2DViewer])
    {
        NSArray		*views = [[[self windowController] seriesView] imageViews];
        
        for ( int i = 0; i < [views count]; i ++)
            [[views objectAtIndex: i] updateImage];
    }
    
    resampledBaseAddrSize = 0;
    [curDCM compute8bitRepresentation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRecomputeROINotification object:self userInfo: nil];
    
    [self setIndex: curImage];
}

-(void) multiply:(DCMView*) bV
{
    [curDCM imageArithmeticMultiplication: [bV curDCM]];
    
    [self reapplyWindowLevel];
    [self loadTextures];
    [self setNeedsDisplay: YES];
}

-(void) subtract:(DCMView*) bV
{
    [self subtract: bV absolute: NO];
}

- (void) subtract:(DCMView*) bV absolute:(BOOL) abs
{
    [curDCM imageArithmeticSubtraction: [bV curDCM] absolute: abs];
    
    [self reapplyWindowLevel];
    [self loadTextures];
    [self setNeedsDisplay: YES];
}

-(void) getCLUT:( unsigned char**) r : (unsigned char**) g : (unsigned char**) b
{
    *r = redTable;
    *g = greenTable;
    *b = blueTable;
}

- (void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
    [drawLock lock];
    
    BOOL needUpdate = YES;
    
    if( r == 0)	// -> BW
    {
        if( colorBuf == nil && colorTransfer == NO) needUpdate = NO;	// -> We are already in BW
    }
    else if( memcmp( redTable, r, 256) == 0 && memcmp( greenTable, g, 256) == 0 && memcmp( blueTable, b, 256) == 0) needUpdate = NO;
    
    if( needUpdate)
    {
        if( r )
        {
            BOOL BWCLUT = YES;
            
            for( int i = 0; i < 256; i++)
            {
                redTable[i] = r[i];
                greenTable[i] = g[i];
                blueTable[i] = b[i];
                
                if( redTable[i] != i || greenTable[i] != i || blueTable[i] != i) BWCLUT = NO;
            }
            
            if( BWCLUT)
            {
                colorTransfer = NO;
                if( colorBuf) free(colorBuf);
                colorBuf = nil;
            }
            else
            {
                colorTransfer = YES;
            }
        }
        else {
            colorTransfer = NO;
            if( colorBuf) free(colorBuf);
            colorBuf = nil;
            
            for( int i = 0; i < 256; i++ )
            {
                redTable[i] = i;
                greenTable[i] = i;
                blueTable[i] = i;
            }
        }
    }
    
    [drawLock unlock];
    
    [self loadTextures];
    [self updateTilingViews];
}

- (void) prepareOpenGL
{
    
}

+ (void) computePETBlendingCLUT
{
    if( PETredTable != nil) free( PETredTable);
    if( PETgreenTable != nil) free( PETgreenTable);
    if( PETblueTable != nil) free( PETblueTable);
    
    PETredTable = nil;
    PETgreenTable = nil;
    PETblueTable = nil;
    
    NSDictionary *aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Blending CLUT"]];
    if( aCLUT)
    {
        int i;
        NSArray *array;
        
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
    else
    {
        PETredTable = malloc( 256);
        PETgreenTable = malloc( 256);
        PETblueTable = malloc( 256);
        
        for(int i = 0; i < 256; i++)
        {
            PETredTable[i] = i;
            PETgreenTable[i] = i;
            PETblueTable[i] = i;
        }
    }
}

- (id)initWithFrameInt:(NSRect)frameRect
{
    if( PETredTable == nil)
        [DCMView computePETBlendingCLUT];
    
    yearOld = nil;
    syncSeriesIndex = -1;
    mouseXPos = mouseYPos = 0;
    pixelMouseValue = 0;
    curDCM = nil;
    curRoiList = nil;
    blendingMode = 0;
    display2DPoint = NSMakePoint(0,0);
    colorBuf = nil;
    blendingColorBuf = nil;
    stringID = nil;
    mprVector[ 0] = 0;
    mprVector[ 1] = 0;
    crossMove = -1;
    
    cursor = [[NSCursor contrastCursor] retain];
    syncRelativeDiff = 0;
    volumicSeries = YES;
    
    currentToolRight = tZoom;
    
    thickSlabMode = 0;
    thickSlabStacks = 0;
    COPYSETTINGSINSERIES = YES;
    suppress_labels = NO;
    previousViewSize = frameRect.size;
    
    annotationType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"ANNOTATIONS" options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"LabelFONTNAME" options:NSKeyValueObservingOptionNew context:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"LabelFONTSIZE" options:NSKeyValueObservingOptionNew context:nil];
    
    //	NSOpenGLPixelFormatAttribute attrs[] =
    //    {
    //			NSOpenGLPFAAccelerated,
    //			NSOpenGLPFANoRecovery,
    //            NSOpenGLPFADoubleBuffer,
    //			NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32,
    //			0
    //	};
    
    
    // Get pixel format from OpenGL
    //	NSOpenGLPixelFormatAttribute attrs[] = { NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, NSOpenGLPFASampleBuffers, 1, NSOpenGLPFASamples, 4, NSOpenGLPFANoRecovery, 0};
    
    NSOpenGLPixelFormatAttribute attrs[] = { NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, NSOpenGLPFANoRecovery, 0};
    
    NSOpenGLPixelFormat* pixFmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
    if ( !pixFmt )
    {
        //        NSRunCriticalAlertPanel(NSLocalizedString(@"OPENGL ERROR",nil), NSLocalizedString(@"Not able to run Quartz Extreme: OpenGL+Quartz. Update your video hardware!",nil), NSLocalizedString(@"OK",nil), nil, nil);
        //		exit(1);
    }
    self = [super initWithFrame:frameRect pixelFormat:pixFmt];
    
    [self setWantsBestResolutionOpenGLSurface:YES]; // Retina https://developer.apple.com/library/mac/#documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/CapturingScreenContents/CapturingScreenContents.html#//apple_ref/doc/uid/TP40012302-CH10-SW1
    
    drawingFrameRect = [self convertRectToBacking: [self frame]]; //retina
    
    cursorTracking = [[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil];
    [self addTrackingArea: cursorTracking];
    
    blendingView = nil;
    pTextureName = nil;
    blendingTextureName = nil;
    
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(sync:)
               name: OsirixSyncNotification
             object: nil];
    
    [nc	addObserver: self
           selector: @selector(Display3DPoint:)
               name: OsirixDisplay3dPointNotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(roiChange:)
               name: OsirixROIChangeNotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(roiRemoved:)
               name: OsirixRemoveROINotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(roiSelected:)
               name: OsirixROISelectedNotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(updateView:)
               name: OsirixUpdateViewNotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(setFontColor:)
               name:  @"DCMNewFontColor"
             object: nil];
			 
    [nc addObserver: self
           selector: @selector(changeGLFontNotification:)
               name:  OsirixGLFontChangeNotification
             object: nil];
    
    [nc addObserver: self
           selector: @selector(changeLabelGLFontNotification:)
               name:  OsirixLabelGLFontChangeNotification
             object: nil];
    
    [nc	addObserver: self
           selector: @selector(changeWLWW:)
               name: OsirixChangeWLWWNotification
             object: nil];
    
    [nc addObserver: self selector: @selector( DCMViewMouseMovedUpdated:) name: @"DCMViewMouseMovedUpdated" object: nil];
    
    colorTransfer = NO;
    
    for ( unsigned int i = 0; i < 256; i++ )
    {
        alphaTable[i] = 0xFF;
        opaqueTable[i] = 0xFF;
        redTable[i] = i;
        greenTable[i] = i;
        blueTable[i] = i;
    }
    
    redFactor = 1.0;
    greenFactor = 1.0;
    blueFactor = 1.0;
    
    dcmPixList = nil;
    dcmFilesList = nil;
    
    [[self openGLContext] makeCurrentContext];	// Important for iChat compatibility
    
    blendingFactor = 0.5;
    
    GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
    [[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
    
    [self FindMinimumOpenGLCapabilities];
    
    //    glEnable (GL_MULTISAMPLE_ARB);
    //    glHint (GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
    
    //	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx)
    {
        // This hint is for antialiasing
        glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
        
        // Setup some basic OpenGL stuff
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        fontColor = nil;
    }
    
    //	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixLabelGLFontChangeNotification object: self];
    //	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixGLFontChangeNotification object: self];
    
    currentTool = tWL;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: nil];
    
    //	_alternateContext = [[NSOpenGLContext alloc] initWithFormat:pixFmt shareContext:[self openGLContext]];
    
    repulsorRadius = 0;
    
    //    if( [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue])
    //    {
    //        [self setWantsLayer: YES];
    //        CIFilter *CIColorInvert = [CIFilter filterWithName:@"CIColorInvert"];
    //        [CIColorInvert setDefaults];
    //        self.contentFilters = [NSArray arrayWithObject:CIColorInvert];
    //    }
    
    gInvertColors = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue];
    
    return self;
}

- (void) prepareToRelease
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if( [notification object] == [self window])
    {
        [[self window] setAcceptsMouseMovedEvents: NO];
        
        [self prepareToRelease];
        
        [self computeColor];
    }
}

- (NSDictionary*) syncMessage:(short) inc
{
    DCMPix *thickDCM = nil;
    
    if( curImage < 0)
        return nil;
    
    if( curDCM.stack > 1)
    {
        long maxVal = flippedData? curImage-(curDCM.stack-1) : curImage+curDCM.stack-1;
        if( maxVal < 0) maxVal = 0;
        if( maxVal >= [dcmPixList count]) maxVal = (long)[dcmPixList count]-1;
        
        thickDCM = [dcmPixList objectAtIndex: maxVal];
    }
    else thickDCM = nil;
    
    int pos = flippedData? (long)[dcmPixList count] -1 -curImage : curImage;
    
    if( flippedData) inc = -inc;
    
    NSMutableDictionary *instructions = [NSMutableDictionary dictionary];
    
    DCMPix *p = [dcmPixList objectAtIndex: curImage];
    
    [instructions setObject: self forKey: @"view"];
    [instructions setObject: [NSNumber numberWithInt: pos] forKey: @"Pos"];
    [instructions setObject: [NSNumber numberWithInt: inc] forKey: @"Direction"];
    [instructions setObject: [NSNumber numberWithFloat: [p sliceLocation]] forKey: @"Location"];
    [instructions setObject: [NSNumber numberWithFloat: syncRelativeDiff] forKey: @"offsetsync"];
    
    /*    float location[3];
     [curDCM convertPixX:mouseXPos pixY:mouseYPos toDICOMCoords:location pixelCenter:YES];
     [instructions setObject: [NSNumber numberWithFloat:location[0]] forKey: @"point3DX"];
     [instructions setObject: [NSNumber numberWithFloat:location[1]] forKey: @"point3DY"];
     [instructions setObject: [NSNumber numberWithFloat:location[2]] forKey: @"point3DZ"];*/
    
    if( p.frameofReferenceUID)
        [instructions setObject: p.frameofReferenceUID forKey: @"frameofReferenceUID"];
    
    if( [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.studyInstanceUID"])
        [instructions setObject: [[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.studyInstanceUID"] forKey: @"studyID"];
    
    if( curDCM)
        [instructions setObject: curDCM forKey: @"DCMPix"];
    
    if( thickDCM)
        [instructions setObject: thickDCM forKey: @"DCMPix2"]; // WARNING thickDCM can be nil!! nothing after this one...
    
    return instructions;
}

-(void) sendSyncMessage:(short) inc
{
    if( dcmPixList == nil) return;
    
    if( [ViewerController numberOf2DViewer] > 1 && isKeyView && [self is2DViewer])
    {
        NSDictionary *instructions = [self syncMessage: inc];
        
        if( instructions)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixSyncNotification object: self userInfo: instructions];
            
            // most subclasses just need this. NO sync notification for subclasses.
            if( blendingView) // We have to reload the blending image..
            {
                [self loadTextures];
                [self setNeedsDisplay: YES];
            }
        }
    }
}

- (void) computeSliceIntersection: (DCMPix*) oPix sliceFromTo: (float[2][3]) sft vector: (float*) vectorB origin: (float*) originB
{
    // Compute Slice From To Points
    
    float c1[ 3], c2[ 3], r[ 3], sc[ 3];
    int order[ 2];
    
    originB[ 0] += [oPix pixelSpacingX] / 2.;
    originB[ 1] += [oPix pixelSpacingY] / 2.;
    
    sft[ 0][ 0] = HUGE_VALF; sft[ 0][ 1] = HUGE_VALF; sft[ 0][ 2] = HUGE_VALF;
    sft[ 1][ 0] = HUGE_VALF; sft[ 1][ 1] = HUGE_VALF; sft[ 1][ 2] = HUGE_VALF;
    
    [oPix convertPixX: 0 pixY: 0 toDICOMCoords: c1 pixelCenter: YES];
    [oPix convertPixX: [oPix pwidth] pixY: 0 toDICOMCoords: c2 pixelCenter: YES];
    
    int x = 0, v;
    
    v = intersect3D_SegmentPlane( c1, c2, vectorB+6, originB, r);
    if( x < 2 && v != 0)
    {
        order[ x] = v;
        [curDCM convertDICOMCoords: r toSliceCoords: sc pixelCenter: YES];
        sft[ x][ 0] = sc[ 0]; sft[ x][ 1] = sc[ 1]; sft[ x][ 2] = sc[ 2];
        x++;
    }
    
    [oPix convertPixX: 0 pixY: [oPix pheight] toDICOMCoords: c1 pixelCenter: YES];
    [oPix convertPixX: 0 pixY: 0 toDICOMCoords: c2 pixelCenter: YES];
    
    v = intersect3D_SegmentPlane( c1, c2, vectorB+6, originB, r);
    if( x < 2 && v != 0)
    {
        order[ x] = v;
        [curDCM convertDICOMCoords: r toSliceCoords: sc pixelCenter: YES];
        sft[ x][ 0] = sc[ 0]; sft[ x][ 1] = sc[ 1]; sft[ x][ 2] = sc[ 2];
        x++;
    }
    
    [oPix convertPixX: [oPix pwidth] pixY: [oPix pheight] toDICOMCoords: c1 pixelCenter: YES];
    [oPix convertPixX: 0 pixY: [oPix pheight] toDICOMCoords: c2 pixelCenter: YES];
    
    v = intersect3D_SegmentPlane( c1, c2, vectorB+6, originB, r);
    if( x < 2 && v != 0)
    {
        order[ x] = v;
        [curDCM convertDICOMCoords: r toSliceCoords: sc pixelCenter: YES];
        sft[ x][ 0] = sc[ 0]; sft[ x][ 1] = sc[ 1]; sft[ x][ 2] = sc[ 2];
        x++;
    }
    
    [oPix convertPixX: [oPix pwidth] pixY: 0 toDICOMCoords: c1 pixelCenter: YES];
    [oPix convertPixX: [oPix pwidth] pixY: [oPix pheight] toDICOMCoords: c2 pixelCenter: YES];
    
    v = intersect3D_SegmentPlane( c1, c2, vectorB+6, originB, r);
    if( x < 2 && v != 0)
    {
        order[ x] = v;
        [curDCM convertDICOMCoords: r toSliceCoords: sc pixelCenter: YES];
        sft[ x][ 0] = sc[ 0]; sft[ x][ 1] = sc[ 1]; sft[ x][ 2] = sc[ 2];
        x++;
    }
    
    if( x != 2)
    {
        sft[ 0][ 0] = HUGE_VALF; sft[ 0][ 1] = HUGE_VALF; sft[ 0][ 2] = HUGE_VALF;
        sft[ 1][ 0] = HUGE_VALF; sft[ 1][ 1] = HUGE_VALF; sft[ 1][ 2] = HUGE_VALF;
    }
    else
    {
        if( order[ 0] == 1 && order[ 1] == 2)
        {
            sc[ 0] = sft[ 0][ 0];	sc[ 1] = sft[ 0][ 1];	sc[ 2] = sft[ 0][ 2];
            sft[ 0][ 0] = sft[ 1][ 0]; sft[ 0][ 1] = sft[ 1][ 1]; sft[ 0][ 2] = sft[ 1][ 2];
            sft[ 1][ 0] = sc[ 0]; sft[ 1][ 1] = sc[ 1]; sft[ 1][ 2] = sc[ 2];
        }
    }
}

- (BOOL) computeSlice:(DCMPix*) oPix :(DCMPix*) oPix2
{
    float vectorA[ 9], vectorA2[ 9], vectorB[ 9];
    float originA[ 3], originA2[ 3], originB[ 3];
    BOOL changed = NO;
    
    // Copy to test for change
    float csliceFromTo[ 2][ 3], csliceFromToS[ 2][ 3], csliceFromToE[ 2][ 3], csliceFromTo2[ 2][ 3], csliceFromToThickness;
    float csliceVector[ 3];
    
    csliceFromToThickness = sliceFromToThickness;
    for( int y = 0; y < 3; y++)
    {
        for( int x = 0; x < 2; x++)
        {
            csliceFromTo[x][y] = sliceFromTo[x][y];
            csliceFromToS[x][y] = sliceFromToS[x][y];
            csliceFromToE[x][y] = sliceFromToE[x][y];
            csliceFromTo2[x][y] = sliceFromTo2[x][y];
        }
        csliceVector[ y] = sliceVector[y];
    }
    
    originA[ 0] = oPix.originX; originA[ 1 ] = oPix.originY; originA[ 2 ] = oPix.originZ;
    if( oPix2)
    {
        originA2[ 0 ] = oPix2.originX; originA2[ 1 ] = oPix2.originY; originA2[ 2 ] = oPix2.originZ;
    }
    originB[ 0] = curDCM.originX; originB[ 1] = curDCM.originY; originB[ 2] = curDCM.originZ;
    
    [oPix orientation: vectorA];		//vectorA[0] = vectorA[6];	vectorA[1] = vectorA[7];	vectorA[2] = vectorA[8];
    if( oPix2) [oPix2 orientation: vectorA2];
    [curDCM orientation: vectorB];		//vectorB[0] = vectorB[6];	vectorB[1] = vectorB[7];	vectorB[2] = vectorB[8];
    
    float slicePoint[ 3];
    
    if( intersect3D_2Planes( vectorA+6, originA, vectorB+6, originB, sliceVector, slicePoint) == noErr)
    {
        [self computeSliceIntersection: oPix sliceFromTo: sliceFromTo vector: vectorB origin: originB];
        sliceFromToThickness = [oPix sliceThickness];
        
        if( [[[oPix pixArray] objectAtIndex: 0] identicalOrientationTo: oPix] && [[[oPix pixArray] lastObject] identicalOrientationTo: oPix])
        {
            [self computeSliceIntersection: [[oPix pixArray] objectAtIndex: 0] sliceFromTo: sliceFromToS vector: vectorB origin: originB];
            [self computeSliceIntersection: [[oPix pixArray] lastObject] sliceFromTo: sliceFromToE vector: vectorB origin: originB];
        }
        else
        {
            sliceFromToS[ 0][ 0] = HUGE_VALF;
            sliceFromToE[ 0][ 0] = HUGE_VALF;
        }
        
        if( oPix2)
            [self computeSliceIntersection: oPix2 sliceFromTo: sliceFromTo2 vector: vectorB origin: originB];
        else
            sliceFromTo2[ 0][ 0] = HUGE_VALF;
    }
    else
    {
        sliceVector[0] = sliceVector[1] = sliceVector[2] = 0;
        sliceFromTo[ 0][ 0] = HUGE_VALF;
        sliceFromTo2[ 0][ 0] = HUGE_VALF;
        sliceFromToS[ 0][ 0] = HUGE_VALF;
        sliceFromToE[ 0][ 0] = HUGE_VALF;
    }
    
    if( csliceFromToThickness != sliceFromToThickness) changed = YES;
    for( int y = 0; y < 3; y++)
    {
        for( int x = 0; x < 2; x++)
        {
            if( csliceFromTo[x][y] != sliceFromTo[x][y]) changed = YES;
            if( csliceFromToS[x][y] != sliceFromToS[x][y]) changed = YES;
            if( csliceFromToE[x][y] != sliceFromToE[x][y]) changed = YES;
            if( csliceFromTo2[x][y] != sliceFromTo2[x][y]) changed = YES;
        }
        if( csliceVector[ y] != sliceVector[y]) changed = YES;
    }
    
    return changed;
}

- (IBAction) alwaysSyncMenu:(id) sender
{
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"SAMESTUDY"] == NSOnState)
        [[NSUserDefaults standardUserDefaults] setInteger: NSOnState forKey:@"SAMESTUDY"];
    else [[NSUserDefaults standardUserDefaults] setInteger: NSOffState forKey:@"SAMESTUDY"];
}

-(void) setSyncOnLocationImpossible:(BOOL) v
{
    syncOnLocationImpossible = v;
}

-(void) sync:(NSNotification*)note
{
    if( gDontListenToSyncMessage)
        return;
    
    //    NSLog( @"%ld %@", (long) note, self.superview);
    
    if( ![[[note object] superview] isEqual:[self superview]] && [self is2DViewer])
    {
        int prevImage = curImage;
        int newImage = curImage;
        
        if( [[self windowController] windowWillClose])
            return;
        
        if( avoidRecursiveSync > 1) return; // Keep this number, to have cross reference correctly displayed
        avoidRecursiveSync++;
        
        if( [note object] != self && isKeyView == YES && matrix == 0 && newImage > -1)
        {
            NSDictionary *instructions = [note userInfo];
            
            int			diff = [[instructions valueForKey: @"Direction"] intValue];
            int			pos = [[instructions valueForKey: @"Pos"] intValue];
            float		loc = [[instructions valueForKey: @"Location"] floatValue];
            NSString	*oStudyId = [instructions valueForKey: @"studyID"];
            NSString	*oFrameofReferenceUID = [instructions valueForKey: @"frameofReferenceUID"];
            DCMPix		*oPix = [instructions valueForKey: @"DCMPix"];
            DCMPix		*oPix2 = [instructions valueForKey: @"DCMPix2"];
            DCMView		*otherView = [instructions valueForKey: @"view"];
            float		destPoint3D[ 3];
            BOOL		point3D = NO;
            BOOL		same3DReferenceWorld = NO;
            
            if( otherView == blendingView || self == [otherView blendingView])
            {
                syncOnLocationImpossible = NO;
                [otherView setSyncOnLocationImpossible: NO];
            }
            
            if( [instructions valueForKey: @"offsetsync"] == nil)
            {
                NSLog(@"***** err offsetsync");
                avoidRecursiveSync--;
                return;
            }
            
            if( [instructions valueForKey: @"view"] == nil)
            {
                NSLog(@"****** err view");
                avoidRecursiveSync--;
                return;
            }
            
            if( [instructions valueForKey: @"point3DX"])
            {
                destPoint3D[ 0] = [[instructions valueForKey: @"point3DX"] floatValue];
                destPoint3D[ 1] = [[instructions valueForKey: @"point3DY"] floatValue];
                destPoint3D[ 2] = [[instructions valueForKey: @"point3DZ"] floatValue];
                
                point3D = YES;
            }
            
            if( [oStudyId isEqualToString:[[dcmFilesList objectAtIndex: newImage] valueForKeyPath:@"series.study.studyInstanceUID"]])
            {
                if( curDCM.frameofReferenceUID && oFrameofReferenceUID && [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFrameofReferenceUID"])
                {
                    if( oFrameofReferenceUID == nil || curDCM.frameofReferenceUID == nil || [oFrameofReferenceUID isEqualToString: curDCM.frameofReferenceUID])
                        same3DReferenceWorld = YES;
                    else
                        NSLog( @"-- same studyInstanceUID, but different frameofReferenceUID : NO cross reference lines displayed:\r%@\r%@",oFrameofReferenceUID,curDCM.frameofReferenceUID);
                }
                else
                    same3DReferenceWorld = YES;
            }
            
            BOOL registeredViewer = NO;
            
            if( [[self windowController] registeredViewer] == [otherView windowController] || [[otherView windowController] registeredViewer] == [self windowController])
                registeredViewer = YES;
            
            if( same3DReferenceWorld || registeredViewer || [[NSUserDefaults standardUserDefaults] boolForKey:@"SAMESTUDY"] == NO || syncSeriesIndex != -1)  // We received a message from the keyWindow -> display the slice cut to our window!
            {
                if( same3DReferenceWorld || registeredViewer)
                {
                    // Double-Click -> find the nearest point on our plane, go to this plane and draw the intersection!
                    if( point3D)
                    {
                        float resultPoint[ 3];
                        
                        int newIndex = [self findPlaneAndPoint: destPoint3D :resultPoint];
                        
                        if( newIndex != -1)
                        {
                            newImage = newIndex;
                            
                            [curDCM convertDICOMCoords: resultPoint toSliceCoords: slicePoint3D];
                            [self setNeedsDisplay:YES];
                        }
                        else
                        {
                            if( slicePoint3D[ 0] != HUGE_VALF)
                            {
                                slicePoint3D[ 0] = HUGE_VALF;
                                [self setNeedsDisplay:YES];
                            }
                        }
                    }
                    else
                    {
                        if( slicePoint3D[ 0] != HUGE_VALF)
                        {
                            slicePoint3D[ 0] = HUGE_VALF;
                            [self setNeedsDisplay:YES];
                        }
                    }
                }
                
                // Absolute Vodka
                if( syncro == syncroABS && point3D == NO && syncSeriesIndex == -1)
                {
                    if( flippedData) newImage = (long)[dcmPixList count] -1 -pos;
                    else newImage = pos;
                    
                    if( newImage >= [dcmPixList count]) newImage = [dcmPixList count] - 1;
                    if( newImage < 0) newImage = 0;
                }
                
                // Absolute Ratio
                if( syncro == syncroRatio && point3D == NO && syncSeriesIndex == -1)
                {
                    float ratio = (float) pos / (float) [[otherView dcmPixList] count];
                    
                    int ratioPos = round( ratio * (float) [dcmPixList count]);
                    
                    if( flippedData) newImage = (long)[dcmPixList count] -1 -ratioPos;
                    else newImage = ratioPos;
                    
                    if( newImage >= [dcmPixList count]) newImage = [dcmPixList count] - 1;
                    if( newImage < 0) newImage = 0;
                }
                
                // Based on Location
                if( (syncro == syncroLOC && point3D == NO) || syncSeriesIndex != -1)
                {
                    if( volumicSeries == YES && [otherView volumicSeries] == YES)
                    {
                        float orientA[9], orientB[9];
                        
                        [[self curDCM] orientation:orientA];
                        [[otherView curDCM] orientation:orientB];
                        
                        float planeTolerance = [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE-Sync"]; //We don't need to be very strict :
                        
                        if( syncSeriesIndex != -1) // Manual Sync !
                            planeTolerance = 0.78; // 0.78 is about 45 degrees
                        
                        if( [DCMView angleBetweenVector: orientA+6 andVector:orientB+6] < planeTolerance)
                        {
                            // we need to avoid the situations where a localizer blocks two series from synchronizing
                            // if( (sliceVector[0] == 0 && sliceVector[1] == 0 && sliceVector[2] == 0) || syncSeriesIndex != -1)  // Planes are parallel !
                            {
                                BOOL	noSlicePosition = NO, everythingLoaded = YES;
                                //								float   firstSliceLocation;
                                int		index = -1, i;
                                float   smallestdiff = -1, fdiff, slicePosition;
                                
                                if( [[self windowController] isEverythingLoaded] && [[otherView windowController] isEverythingLoaded] && (syncSeriesIndex == -1 || [otherView syncSeriesIndex] == -1))
                                {
                                    float centerPix[ 3];
                                    [oPix convertPixX: oPix.pwidth/2 pixY: oPix.pheight/2 toDICOMCoords: centerPix];
                                    
                                    float oPixOrientation[9]; [oPix orientation:oPixOrientation];
                                    index = [self findPlaneForPoint: centerPix preferParallelTo:oPixOrientation localPoint: nil distanceWithPlane: &smallestdiff];
                                }
                                else
                                {
                                    //									firstSliceLocation = [[[dcmFilesList objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue];
                                    
                                    for( i = 0; i < [dcmFilesList count]; i++)
                                    {
                                        everythingLoaded = [[dcmPixList objectAtIndex: i] isLoaded];
                                        if( everythingLoaded)
                                            slicePosition = [(DCMPix*)[dcmPixList objectAtIndex: i] sliceLocation];
                                        else
                                            slicePosition = [[[dcmFilesList objectAtIndex: i] valueForKey:@"sliceLocation"] floatValue];
                                        
                                        fdiff = slicePosition - loc;
                                        
                                        if( registeredViewer == NO)
                                        {
                                            // Manual sync
                                            if( same3DReferenceWorld == NO)
                                            {
                                                if( [otherView syncSeriesIndex] != -1 && syncSeriesIndex != -1)
                                                {
                                                    slicePosition -= (syncRelativeDiff - otherView.syncRelativeDiff);
                                                    
                                                    fdiff = slicePosition - loc;
                                                }
                                                else if( [[NSUserDefaults standardUserDefaults] boolForKey:@"SAMESTUDY"]) noSlicePosition = YES;
                                            }
                                        }
                                        
                                        if( fdiff < 0) fdiff = -fdiff;
                                        
                                        if( fdiff < smallestdiff || smallestdiff == -1)
                                        {
                                            smallestdiff = fdiff;
                                            index = i;
                                        }
                                    }
                                }
                                
                                if( noSlicePosition == NO)
                                {
                                    if( index >= 0)
                                        newImage = index;
                                    
                                    if( [dcmPixList count] > 1)
                                    {
                                        float sliceDistance;
                                        
                                        if( [[dcmPixList objectAtIndex: 1] isLoaded] && [[dcmPixList objectAtIndex: 0] isLoaded]) everythingLoaded = YES;
                                        else everythingLoaded = NO;
                                        
                                        if( everythingLoaded) sliceDistance = fabs( [(DCMPix*)[dcmPixList objectAtIndex: 1] sliceLocation] - [(DCMPix*)[dcmPixList objectAtIndex: 0] sliceLocation]);
                                        else sliceDistance = fabs( [[[dcmFilesList objectAtIndex: 1] valueForKey:@"sliceLocation"] floatValue] - [[[dcmFilesList objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue]);
                                        
                                        if( fabs( smallestdiff) > sliceDistance * 2)
                                        {
                                            if( otherView == blendingView || self == [otherView blendingView])
                                            {
                                                syncOnLocationImpossible = YES;
                                                [otherView setSyncOnLocationImpossible: YES];
                                            }
                                        }
                                    }
                                    
                                    if( newImage >= [dcmFilesList count]) newImage = (long)[dcmFilesList count]-1;
                                    if( newImage < 0) newImage = 0;
                                }
                            }
                        }
                    }
                    else if( volumicSeries == NO && [otherView volumicSeries] == NO)	// For example time or functional series
                    {
                        if( [[NSUserDefaults standardUserDefaults] integerForKey: @"DefaultModeForNonVolumicSeries"] == syncroRatio)
                        {
                            float ratio = (float) pos / (float) [[otherView dcmPixList] count];
                            int ratioPos = round( ratio * (float) [dcmPixList count]);
                            
                            if( flippedData) newImage = (long)[dcmPixList count] -1 -ratioPos;
                            else newImage = ratioPos;
                        }
                        else if( [[NSUserDefaults standardUserDefaults] integerForKey: @"DefaultModeForNonVolumicSeries"] == syncroABS)
                        {
                            if( flippedData) newImage = (long)[dcmPixList count] -1 -pos;
                            else newImage = pos;
                        }
                        
                        if( newImage >= [dcmPixList count]) newImage = [dcmPixList count] - 1;
                        if( newImage < 0) newImage = 0;
                    }
                }
                
                // Relative
                if( syncro == syncroREL && point3D == NO && syncSeriesIndex == -1)
                {
                    if( flippedData) newImage -= diff;
                    else newImage += diff;
                    
                    if( newImage < 0) newImage += [dcmPixList count];
                    if( newImage >= [dcmPixList count]) newImage -= [dcmPixList count];
                }
                
                // Relatif
                ViewerController *frontMostViewer = [ViewerController frontMostDisplayed2DViewer];
                ViewerController *selfViewer = self.window.windowController;
                ViewerController *otherViewer = otherView.window.windowController;
                if( newImage != prevImage)
                {
                    if( avoidRecursiveSync <= 1)
                    {
                        if((selfViewer != frontMostViewer && otherViewer == frontMostViewer) || otherViewer.timer)
                        {
                            if( listType == 'i') [self setIndex:newImage];
                            else [self setIndexWithReset:newImage :YES];
                            [[self windowController] adjustSlider];
                        }
                    }
                }
                
                if( same3DReferenceWorld || registeredViewer)
                {
                    if( (selfViewer != frontMostViewer && otherViewer == frontMostViewer) || [otherView.windowController FullScreenON])
                    {
                        if( same3DReferenceWorld || registeredViewer)
                        {
                            if( [self computeSlice: oPix :oPix2])
                                [self setNeedsDisplay:YES];
                        }
                        else
                        {
                            if( sliceFromTo[ 0][ 0] != HUGE_VALF && (sliceVector[ 0] != 0 || sliceVector[ 1] != 0  || sliceVector[ 2] != 0))
                            {
                                sliceFromTo[ 0][ 0] = HUGE_VALF;
                                sliceFromTo2[ 0][ 0] = HUGE_VALF;
                                sliceFromToS[ 0][ 0] = HUGE_VALF;
                                sliceFromToE[ 0][ 0] = HUGE_VALF;
                                sliceVector[0] = sliceVector[1] = sliceVector[2] = 0;
                                [self setNeedsDisplay:YES];
                            }
                        }
                    }
                    else
                    {
                        if( sliceFromTo[ 0][ 0] != HUGE_VALF && (sliceVector[ 0] != 0 || sliceVector[ 1] != 0  || sliceVector[ 2] != 0))
                        {
                            sliceFromTo[ 0][ 0] = HUGE_VALF;
                            sliceFromTo2[ 0][ 0] = HUGE_VALF;
                            sliceFromToS[ 0][ 0] = HUGE_VALF;
                            sliceFromToE[ 0][ 0] = HUGE_VALF;
                            sliceVector[0] = sliceVector[1] = sliceVector[2] = 0;
                            [self setNeedsDisplay:YES];
                        }
                    }
                }
            }
            else
            {
                if( sliceFromTo[ 0][ 0] != HUGE_VALF && (sliceVector[ 0] != 0 || sliceVector[ 1] != 0  || sliceVector[ 2] != 0))
                {
                    sliceFromTo[ 0][ 0] = HUGE_VALF;
                    sliceFromTo2[ 0][ 0] = HUGE_VALF;
                    sliceFromToS[ 0][ 0] = HUGE_VALF;
                    sliceFromToE[ 0][ 0] = HUGE_VALF;
                    sliceVector[0] = sliceVector[1] = sliceVector[2] = 0;
                    [self setNeedsDisplay:YES];
                }
            }
        }
        
        //		if( [[self window] isMainWindow])
        //			[self sendSyncMessage: 0];
        
        if( blendingView && [note object] != blendingView)
            [blendingView sync: [NSNotification notificationWithName: OsirixSyncNotification object: self userInfo: [self syncMessage: 0]]];
        
        avoidRecursiveSync --;
        
        //        if( avoidRecursiveSync == 0)
        //            [self displayIfNeeded];
    }
}

-(void) roiSelected:(NSNotification*) note
{
    NSArray *winList = [[NSApplication sharedApplication] windows];
    
    for( id loopItem in winList)
    {
        if( [[[loopItem windowController] windowNibName] isEqualToString:@"ROI"])
        {
            if( [self is2DViewer])
                [[loopItem windowController] setROI: [note object] :[self windowController]];
        }
    }
}

-(void) roiRemoved:(NSNotification*)note
{
    if( [self needsDisplay]) return;
    
    // A ROI has been removed... do we display it? If yes, update!
    if( [curRoiList indexOfObjectIdenticalTo: [note object]] != NSNotFound)
    {
        [self setNeedsDisplay:YES];
    }
}

-(void) roiChange:(NSNotification*)note
{
    if( [self needsDisplay]) return;
    
    // A ROI changed... do we display it? If yes, update!
    if( [curRoiList indexOfObjectIdenticalTo: [note object]] != NSNotFound)
    {
        [self setNeedsDisplay:YES];
    }
}

-(void) updateView:(NSNotification*)note
{
    [self setNeedsDisplay:YES];
}

-(void) updateImage {
    float wl, ww;
    
    [self getWLWW: &wl :&ww];
    
    if( ww)
        [self setWLWW: wl :ww];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"ANNOTATIONS"])
    {
        int newValue = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
        if (newValue != annotationType)
        {
            self.annotationType = newValue;
            [self setNeedsDisplay:YES];
        }
    }
    
    if( [keyPath isEqualToString:@"LabelFONTNAME"] || [keyPath isEqualToString:@"LabelFONTSIZE"])
    {
        for( NSArray *rois in dcmRoiList)
        {
            for( ROI *r in rois)
                [r updateLabelFont];
        }
    }
}

-(void) barMenu:(id) sender
{
    [[NSUserDefaults standardUserDefaults] setInteger: [sender tag] forKey: @"CLUTBARS"];
    
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: OsirixUpdateViewNotification object: self userInfo: nil];
}

-(void) annotMenu:(id) sender
{
    short chosenLine = [sender tag];
    
    [[NSUserDefaults standardUserDefaults] setInteger: chosenLine forKey: @"ANNOTATIONS"];
    [DCMView setDefaults];
    
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: OsirixUpdateViewNotification object: self userInfo: nil];
    
    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
        [v setWindowTitle: self];
}

-(void) syncronize:(id) sender
{
    [self setSyncro: [sender tag]];
}

- (short)syncro { return syncro; }
+ (short)syncro { return syncro; }

+ (void)setSyncro:(short) s
{
    syncro = s;
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixSyncSeriesNotification object:nil userInfo: nil];
}
- (void)setSyncro:(short) s
{
    syncro = s;
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixSyncSeriesNotification object:nil userInfo: nil];
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
    
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx)
    {
        // get strings
        enum { kShortVersionLength = 32 };
        const GLubyte * strVersion = glGetString (GL_VERSION); // get version string
        const GLubyte * strExtension = glGetString (GL_EXTENSIONS);	// get extension string
        
        // get just the non-vendor specific part of version string
        GLubyte strShortVersion [kShortVersionLength];
        short i = 0;
        while ((((strVersion[i] <= '9') && (strVersion[i] >= '0')) || (strVersion[i] == '.')) && (i < kShortVersionLength)) // get only basic version info (until first space)
        {
            strShortVersion[i] = strVersion[i];
            i++;
        }
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
}

//- (NSPoint) convertFromNSView2iChat: (NSPoint) a
//{
//	//inverse Y scaling system
//	a.y = [self drawingFrameRect].size.height - a.y;		// inverse Y scaling system
//
//	return a;
//}

//- (NSPoint) convertFromView2iChat: (NSPoint) a
//{
//	if( [NSOpenGLContext currentContext] == _alternateContext)
//	{
////		NSRect	iChat = [[[NSOpenGLContext currentContext] view] frame];
//		NSRect	windowRect = [self frame];
//
//		return NSMakePoint( a.x - (windowRect.size.width - iChatWidth)/2.0, a.y - (windowRect.size.height - iChatHeight)/2.0);
//	}
//	else return a;
//}

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
    
    a.x -= (origin.x);
    a.y += (origin.y);
    
    a.x += curDCM.pwidth/2.;
    a.y += curDCM.pheight/2.;
    
    return a;
}

-(NSPoint) ConvertFromGL2GL:(NSPoint) a toView:(DCMView*) otherView
{
    a = [self ConvertFromGL2View: a];
    a = [otherView ConvertFromView2GL: a];
    
    return a;
}

-(NSPoint) ConvertFromGL2View:(NSPoint) a
{
    NSRect size = drawingFrameRect;
    
    if( curDCM)
    {
        a.y *= curDCM.pixelRatio;
        a.y -= curDCM.pheight * curDCM.pixelRatio * 0.5f;
        a.x -= curDCM.pwidth * 0.5f;
    }
    
    a.y -= (origin.y)/scaleValue;
    a.x += (origin.x)/scaleValue;
    
    float xx = a.x*cos(-rotation*deg2rad) + a.y*sin(-rotation*deg2rad);
    float yy = -a.x*sin(-rotation*deg2rad) + a.y*cos(-rotation*deg2rad);
    
    a.y = yy;
    a.x = xx;
    
    a.y *= scaleValue;
    a.y += size.size.height/2.;
    
    a.x *= scaleValue;
    a.x += size.size.width/2.;
    
    if( xFlipped) a.x = size.size.width - a.x;
    if( yFlipped) a.y = size.size.height - a.y;
    
    a.x -= size.size.width/2.;
    a.y -= size.size.height/2.;
    
    return a;
}

-(NSPoint) ConvertFromGL2NSView:(NSPoint) a
{
    a = [self ConvertFromGL2View: a];
    
    a.y = [self drawingFrameRect].size.height - a.y;		// inverse Y scaling system
    a.y -= [self drawingFrameRect].size.height/2.;			// Our viewing zero is centered in the view, NSView has the zero in left/bottom
    a.x += [self drawingFrameRect].size.width/2.;
    
    a = [self convertPointFromBacking: a]; //retina
    
    return a;
}

-(NSPoint) ConvertFromGL2Screen:(NSPoint) a
{
    a = [self ConvertFromGL2NSView: a];
    a = [self convertPointToBacking:a];
    a = [self.window convertRectToScreen:NSMakeRect(a.x, a.y, 0, 0)].origin;
    return a;
}

-(NSPoint) ConvertFromNSView2GL:(NSPoint) a
{
    a = [self convertPointToBacking: a]; //retina
    
    //inverse Y scaling system
    a.y = [self drawingFrameRect].size.height - a.y ;		// inverse Y scaling system
    
    return [self ConvertFromUpLeftView2GL: a];
}

- (NSPoint) ConvertFromView2GL:(NSPoint) a;
{
    a.x += [self drawingFrameRect].size.width/2.;
    a.y += [self drawingFrameRect].size.height/2.;
    
    return [self ConvertFromUpLeftView2GL: a];
}

- (NSPoint) ConvertFromUpLeftView2GL:(NSPoint) a
{
    NSRect size = drawingFrameRect;
    
    if( xFlipped) a.x = size.size.width - a.x;
    if( yFlipped) a.y = size.size.height - a.y;
    
    a.x -= size.size.width/2;
    a.x /= scaleValue;
    
    a.y -= size.size.height/2;
    a.y /= scaleValue;
    
    float xx = a.x*cos(rotation*deg2rad) + a.y*sin(rotation*deg2rad);
    float yy = -a.x*sin(rotation*deg2rad) + a.y*cos(rotation*deg2rad);
    
    a.y = yy;
    a.x = xx;
    
    a.x -= (origin.x)/scaleValue;
    a.y += (origin.y)/scaleValue;
    
    if( curDCM)
    {
        a.x += curDCM.pwidth * 0.5f;
        a.y += curDCM.pheight * curDCM.pixelRatio * 0.5f;
        a.y /= curDCM.pixelRatio;
    }
    return a;
}

- (void) drawRectIn:(NSRect) size
                   :(GLuint *) texture
                   :(NSPoint) offset
                   :(long) tX :(long) tY :(long) tW :(long) tH
{
    if( texture == nil)
        return;
    
    long effectiveTextureMod = 0; // texture size modification (inset) to account for borders
    long x, y, k = 0, offsetY, offsetX = 0, currTextureWidth, currTextureHeight;
    
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity ();
    
    glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f); // scale to port per pixel scale
    glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
    glTranslatef( origin.x - offset.x , -origin.y - offset.y, 0.0f);
    
    if( curDCM.pixelRatio != 1.0) glScalef( 1.f, curDCM.pixelRatio, 1.f);
    
    effectiveTextureMod = 0;	//2;	//OVERLAP
    
    glEnable (TEXTRECTMODE); // enable texturing
    glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
    
    //    float sf = self.window.backingScaleFactor;
    
    for (x = 0; x < tX; x++) // for all horizontal textures
    {
        // use remaining to determine next texture size
        currTextureWidth = GetNextTextureSize (tW - offsetX, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // current effective texture width for drawing
        offsetY = 0; // start at top
        for (y = 0; y < tY; y++) // for a complete column
        {
            // use remaining to determine next texture size
            currTextureHeight = GetNextTextureSize (tH - offsetY, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // effective texture height for drawing
            
            glBindTexture(TEXTRECTMODE, texture[k++]); // work through textures in same order as stored, setting each texture name as current in turn
            
            DrawGLImageTile (GL_TRIANGLE_STRIP, curDCM.pwidth, curDCM.pheight, scaleValue,		//
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

- (NSPoint) positionWithoutRotation: (NSPoint) tPt
{
    NSRect unrotatedRect = NSMakeRect( tPt.x/scaleValue, tPt.y/scaleValue, 1, 1);
    NSRect centeredRect = unrotatedRect;
    
    float ratio = 1;
    
    if( self.pixelSpacingX != 0 && self.pixelSpacingY != 0)
        ratio = self.pixelSpacingX / self.pixelSpacingY;
    
    centeredRect.origin.y -= [self origin].y*ratio/scaleValue;
    centeredRect.origin.x -= - [self origin].x/scaleValue;
    
    unrotatedRect.origin.x = centeredRect.origin.x*cos( -self.rotation*deg2rad) + centeredRect.origin.y*sin( -self.rotation*deg2rad)/ratio;
    unrotatedRect.origin.y = -centeredRect.origin.x*sin( -self.rotation*deg2rad) + centeredRect.origin.y*cos( -self.rotation*deg2rad)/ratio;
    
    unrotatedRect.origin.y *= ratio;
    
    unrotatedRect.origin.y += [self origin].y*ratio/scaleValue;
    unrotatedRect.origin.x += - [self origin].x/scaleValue;
    
    tPt = NSMakePoint( unrotatedRect.origin.x, unrotatedRect.origin.y);
    tPt.x = (tPt.x)*scaleValue - unrotatedRect.size.width/2;
    tPt.y = (tPt.y)/ratio*scaleValue - unrotatedRect.size.height/2/ratio;
    
    return tPt;
}

- (double)pixelSpacing { return curDCM.pixelSpacingX; }
- (double)pixelSpacingX { return curDCM.pixelSpacingX; }
- (double)pixelSpacingY { return curDCM.pixelSpacingY; }

- (void)getOrientationText:(char *) orientation : (float *) vector :(BOOL) inv
{
    orientation[ 0] = 0;
    
    NSString *orientationX;
    NSString *orientationY;
    NSString *orientationZ;
    
    NSMutableString *optr = [NSMutableString string];
    
    if( inv)
    {
        orientationX = -vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
        orientationY = -vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
        orientationZ = -vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
    }
    else
    {
        orientationX = vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
        orientationY = vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
        orientationZ = vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
    }
    
    float absX = fabs( vector[ 0]);
    float absY = fabs( vector[ 1]);
    float absZ = fabs( vector[ 2]);
    
    // get first 3 AXIS
    for ( int i=0; i < 3; ++i)
    {
        if (absX>.2 && absX>=absY && absX>=absZ)
        {
            [optr appendString: orientationX]; absX=0;
        }
        else if (absY>.2 && absY>=absX && absY>=absZ)
        {
            [optr appendString: orientationY]; absY=0;
        }
        else if (absZ>.2 && absZ>=absX && absZ>=absY)
        {
            [optr appendString: orientationZ]; absZ=0;
        }
        else break;
    }
    
    strcpy( orientation, [optr UTF8String]);
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

+ (float) pbase_Plane: (float*) point :(float*) planeOrigin :(float*) planeVector :(float*) pointProjection
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

+ (float) angleBetweenVector: (float*) v1 andVector: (float*) v2
{
    if( v1[ 0] == 0 && v1[ 1] == 0 && v1[ 2] == 0 && v2[ 0] == 0 && v2[ 1] == 0 && v2[ 2] == 0)
        return 0;
    
    if( v1[ 0] == 0 && v1[ 1] == 0 && v1[ 2] == 0)
        return deg2rad* 180;
    
    if( v2[ 0] == 0 && v2[ 1] == 0 && v2[ 2] == 0)
        return deg2rad* 180;
    
    float cosTheta = dot( v1, v2) / (norm( v1)*norm( v2));
    
    return acosf( cosTheta);
}

+ (double) angleBetweenVectorD: (double*) v1 andVectorD: (double*) v2
{
    if( v1[ 0] == 0 && v1[ 1] == 0 && v1[ 2] == 0 && v2[ 0] == 0 && v2[ 1] == 0 && v2[ 2] == 0)
        return 0;
    
    if( v1[ 0] == 0 && v1[ 1] == 0 && v1[ 2] == 0)
        return deg2rad* 180;
    
    if( v2[ 0] == 0 && v2[ 1] == 0 && v2[ 2] == 0)
        return deg2rad* 180;
    
    double cosTheta = dot( v1, v2) / (norm( v1)*norm( v2));
    
    return acos( cosTheta);
}

//===================================================================

- (int) findPlaneAndPoint:(float*) pt :(float*) location
{
    return [self findPlaneForPoint: pt localPoint: location distanceWithPlane: nil];
}

+ (NSArray*)cleanedOutDcmPixArray:(NSArray*)input
{
    @try
    {
        // separate DCMPix into different arrays with common imageType
        NSMutableDictionary* dcmPixByImageType = [NSMutableDictionary dictionary];
        for (DCMPix* pix in input)
        {
            NSString* pixImageType = [pix imageType];
            if (!pixImageType) pixImageType = @""; // to avoid inserting nil keys in the dictionary
            NSMutableArray* dcmPixByImageTypeArray = [dcmPixByImageType objectForKey:pixImageType];
            if (!dcmPixByImageTypeArray)
                [dcmPixByImageType setObject:(dcmPixByImageTypeArray = [NSMutableArray array]) forKey:pixImageType];
            [dcmPixByImageTypeArray addObject:pix];
        }
        
        // is there more than one imageType?
        if (dcmPixByImageType.count > 1)
        {
            // yes, find the most common one
            NSInteger maxCountIndex = 0;
            NSArray* dcmPixByImageTypeArrays = [dcmPixByImageType allValues];
            for (NSInteger i = 1; i < dcmPixByImageType.count; ++i)
                if ([[dcmPixByImageTypeArrays objectAtIndex:i] count] > [[dcmPixByImageTypeArrays objectAtIndex:maxCountIndex] count])
                    maxCountIndex = i;
            
            // how many DCMPix have the most common imageType?
            NSInteger maxCount = [[dcmPixByImageTypeArrays objectAtIndex:maxCountIndex] count];
            
            // retain all DCMPix from groups with at least half the number of images with the most common imageType
            NSMutableArray* r = [NSMutableArray array];
            for (NSArray* group in dcmPixByImageTypeArrays)
                if (group.count >= maxCount/2)
                    [r addObjectsFromArray:group];
            
            return r;
        }
    }
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    return input;
}

- (int) findPlaneForPoint:(float*) pt preferParallelTo:(float*)parto localPoint:(float*) location distanceWithPlane: (float*) distanceResult
{
    int		ii = -1;
    float	vectors[ 9], orig[ 3], locationTemp[ 3];
    float	distance = 999999, tempDistance;
    
    BOOL vParallel = NO;
    
    if( cleanedOutDcmPixArray == nil)
        cleanedOutDcmPixArray = [[DCMView cleanedOutDcmPixArray:dcmPixList] retain];
    
    BOOL currParallel = NO;
    if( volumicData == 1) // All planes have the same orientation : we can compute currParallel only once !
    {
        [[cleanedOutDcmPixArray lastObject] orientation: vectors];
        if (parto && [DCMView angleBetweenVector: parto+6 andVector:vectors+6] < [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"]) // are parallel!
            currParallel = YES;
    }
    
    int i = 0;
    for( DCMPix* pix in cleanedOutDcmPixArray)
    {
        if( volumicData != 1)
        {
            [pix orientation: vectors];
            
            if (parto && [DCMView angleBetweenVector: parto+6 andVector:vectors+6] < [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"]) // are parallel!
                currParallel = YES;
            else
                currParallel = NO;
        }
        
        [pix origin: orig];
        tempDistance = [DCMView pbase_Plane: pt :orig :&(vectors[ 6]) :locationTemp];
        
        if ((!vParallel && currParallel) || (currParallel == vParallel && tempDistance < distance))
        {
            vParallel = currParallel;
            
            if( location)
            {
                location[ 0] = locationTemp[ 0];
                location[ 1] = locationTemp[ 1];
                location[ 2] = locationTemp[ 2];
            }
            
            distance = tempDistance;
            ii = i;
        }
        
        i++;
    }
    
    if( ii != -1 )
    {
        if( curDCM.sliceThickness != 0 && distance > curDCM.sliceThickness * 2) ii = -1;
    }
    
    if( distanceResult)
        *distanceResult = distance;
    
    return ii;
}

- (int) findPlaneForPoint:(float*) pt localPoint:(float*) location distanceWithPlane: (float*) distanceResult {
    return [self findPlaneForPoint:pt preferParallelTo:nil localPoint:location distanceWithPlane:distanceResult];
}

- (void) drawOrientation:(NSRect) size
{
    if( NSIsEmptyRect( screenCaptureRect) == NO)
        size = screenCaptureRect;
    else
        size.origin = NSMakePoint( 0, 0);
    
    // Determine Anterior, Posterior, Left, Right, Head, Foot
    char	string[ 10];
    float   vectors[ 9];
    
    [self orientationCorrectedToView: vectors];
    
    // Left
    [self getOrientationText:string :vectors :YES];
    [self DrawCStringGL: string : fontListGL :size.origin.x + 6 :size.origin.y + 2+size.size.height/2 rightAlignment: NO useStringTexture: YES];
    
    // Right
    [self getOrientationText:string :vectors :NO];
    [self DrawCStringGL: string : fontListGL :size.origin.x + size.size.width - (2 + stringSize.width * strlen(string)) :size.origin.y +2+size.size.height/2 rightAlignment: NO useStringTexture: YES];
    
    //Top
    float yPosition = size.origin.y + stringSize.height + 3;
    [self getOrientationText:string :vectors+3 :YES];
    
    if( strlen(string))
    {
        [self DrawCStringGL: string : fontListGL :size.origin.x + size.size.width/2 - (stringSize.width * strlen(string)/2) :yPosition rightAlignment: NO useStringTexture: YES];
        yPosition += stringSize.height + 3;
    }
    
    if( curDCM.laterality)
    {
        [self DrawNSStringGL: curDCM.laterality : fontListGL :size.origin.x + size.size.width/2 :yPosition align:DCMViewTextAlignCenter useStringTexture: YES];
        yPosition += stringSize.height + 3;
    }
    
    if( [self is2DViewer] && (xFlipped || yFlipped))
    {
        NSString *flippedString = nil;
        
        if( xFlipped && yFlipped)
            flippedString = NSLocalizedString( @"Horizontally & Vertically Flipped", nil);
        
        else if( xFlipped)
            flippedString = NSLocalizedString( @"Horizontally Flipped", nil);
        
        else if( yFlipped)
            flippedString = NSLocalizedString( @"Vertically Flipped", nil);
        
        if( flippedString)
        {
            [self DrawNSStringGL: flippedString : fontListGL :size.origin.x + size.size.width/2 :yPosition align:DCMViewTextAlignCenter useStringTexture: YES];
            yPosition += stringSize.height + 3;
        }
    }
    
    if( [self is2DViewer] && curDCM.VOILUTApplied)
    {
        [self DrawNSStringGL: @"VOI LUT Applied" : fontListGL :size.origin.x + size.size.width/2 :yPosition align:DCMViewTextAlignCenter useStringTexture: YES];
        yPosition += stringSize.height + 3;
    }
    
    //Bottom
    [self getOrientationText:string :vectors+3 :NO];
    [self DrawCStringGL: string : fontListGL :size.origin.x + size.size.width/2 :size.origin.y + 2+size.size.height - 6 rightAlignment: NO useStringTexture: YES];
}

-(void) getThickSlabThickness:(float*) thickness location:(float*) location
{
    *thickness = curDCM.sliceThickness;
    *location = curDCM.sliceLocation;
    
    if( curDCM.sliceThickness != 0 && curDCM.sliceLocation != 0)
    {
        if( curDCM.stack > 1)
        {
            long maxVal = flippedData? maxVal = curImage-curDCM.stack : curImage+curDCM.stack;
            
            if( maxVal < 0) maxVal = curImage;
            else if( maxVal > [dcmPixList count]) maxVal = [dcmPixList count] - curImage;
            else maxVal = curDCM.stack;
            
            float vv = fabs( (maxVal-1) * [[dcmPixList objectAtIndex:0] sliceInterval]);
            
            vv += curDCM.sliceThickness;
            
            float pp;
            
            if( flippedData)
                pp = ([(DCMPix*)[dcmPixList objectAtIndex: curImage] sliceLocation] + [(DCMPix*)[dcmPixList objectAtIndex: curImage - maxVal+1] sliceLocation])/2.;
            else
                pp = ([(DCMPix*)[dcmPixList objectAtIndex: curImage] sliceLocation] + [(DCMPix*)[dcmPixList objectAtIndex: curImage + maxVal-1] sliceLocation])/2.;
            
            *thickness = vv;
            *location = pp;
        }
    }
}

- (float) displayedScaleValue
{
    return scaleValue;
}

- (float) displayedRotation
{
    return rotation;
}

- (void) setStudyDateIndex:(NSUInteger)s
{
    [studyDateBox release];
    studyDateBox = nil;
    
    studyDateIndex = s;
}

- (void) drawTextualData:(NSRect) size annotationsLevel:(long) annotations fullText: (BOOL) fullText onlyOrientation: (BOOL) onlyOrientation
{
    float sf = [self.window backingScaleFactor]; //retina
    
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
    //** TEXT INFORMATION
    glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
    glScalef (2.0f / size.size.width, -2.0f /  size.size.height, 1.0f); // scale to port per pixel scale
    glTranslatef (-(size.size.width) / 2.0f, -(size.size.height) / 2.0f, 0.0f); // translate center to upper left
    
    //draw line around edge for key Images only in 2D Viewer
    
    if ([self isKeyImage] && stringID == nil)
    {
        glLineWidth(8.0 * self.window.backingScaleFactor);
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
    glLineWidth(1.0 * self.window.backingScaleFactor);
    
    //	#ifndef OSIRIX_LIGHT
    //	if( iChatRunning && cgl_ctx==[_alternateContext CGLContextObj])
    //	{
    //		if(!iChatFontListGL) iChatFontListGL = glGenLists(150);
    //		iChatFontGL = [NSFont systemFontOfSize: 12];
    //		[iChatFontGL makeGLDisplayListFirst:' ' count:150 base:iChatFontListGL :iChatFontListGLSize :1];
    //		iChatStringSize = [DCMView sizeOfString:@"B" forFont:iChatFontGL];
    //	}
    //	#endif
    
    GLuint fontList;
    NSSize _stringSize;
    //	if(cgl_ctx==[_alternateContext CGLContextObj])
    //	{
    //		fontList = iChatFontListGL;
    //		_stringSize = iChatStringSize;
    //	}
    //	else
    //	{
    fontList = fontListGL;
    _stringSize = stringSize;
    //	}
    
    if (annotations == 4)
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDrawTextInfoNotification object: self];
    else if( annotations > annotGraphics)
    {
        if( NSIsEmptyRect( screenCaptureRect) == NO)
            size = screenCaptureRect;
        else
            size.origin = NSMakePoint( 0, 0);
        
        NSMutableString *tempString, *tempString2, *tempString3, *tempString4;
        long yRaster = 1, xRaster;
        
        if( onlyOrientation)
        {
            [self drawOrientation:size];
            return;
        }
        
        int colorBoxSize = 0;
        
        if( studyColorR != 0 || studyColorG != 0 || studyColorB != 0)
            colorBoxSize = 30*sf;
        
        if( colorBoxSize && stringID == nil && [self is2DViewer] == YES)
        {
            if( studyDateBox == nil && studyDateIndex != NSNotFound)
            {
                NSColor *boxColor = [NSColor colorWithCalibratedRed: studyColorR green: studyColorG blue: studyColorB alpha: 1.0];
                
                NSMutableDictionary *stanStringAttrib = [NSMutableDictionary dictionary];
                [stanStringAttrib setObject: [NSFont fontWithName:@"Helvetica" size: 20] forKey: NSFontAttributeName];
                if( studyDateIndex+1 < 10)
                    studyDateBox = [[GLString alloc] initWithAttributedString: [[[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @" %d ", (int) studyDateIndex+1] attributes: stanStringAttrib] autorelease] withBoxColor: boxColor withBorderColor:boxColor];
                else
                    studyDateBox = [[GLString alloc] initWithAttributedString: [[[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%d", (int) studyDateIndex+1] attributes: stanStringAttrib] autorelease] withBoxColor: boxColor withBorderColor:boxColor];
            }
            
            if( studyDateBox)
            {
                glColor4f( 1.0, 1.0, 1.0, 1.0);
                [studyDateBox drawAtPoint: NSMakePoint( size.origin.x + 5*sf, size.origin.y + 4*sf) view: self];
            }
        }
        else colorBoxSize = 0;
        
        NSDictionary *annotationsDictionary = curDCM.annotationsDictionary;
        
        NSMutableDictionary *xRasterInit = [NSMutableDictionary dictionary];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + 6*sf] forKey:@"TopLeft"];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + 6*sf] forKey:@"MiddleLeft"];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + 6*sf] forKey:@"LowerLeft"];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + size.size.width-2*sf] forKey:@"TopRight"];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + size.size.width-2*sf] forKey:@"MiddleRight"];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + size.size.width-2*sf] forKey:@"LowerRight"];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + size.size.width/2] forKey:@"TopMiddle"];
        [xRasterInit setObject:[NSNumber numberWithInt:size.origin.x + size.size.width/2] forKey:@"LowerMiddle"];
        
        NSMutableDictionary *align = [NSMutableDictionary dictionary];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignLeft] forKey:@"TopLeft"];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignLeft] forKey:@"MiddleLeft"];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignLeft] forKey:@"LowerLeft"];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignRight] forKey:@"TopRight"];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignRight] forKey:@"MiddleRight"];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignRight] forKey:@"LowerRight"];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignCenter] forKey:@"TopMiddle"];
        [align setObject:[NSNumber numberWithInt:DCMViewTextAlignCenter] forKey:@"LowerMiddle"];
        
        NSMutableDictionary *yRasterInit = [NSMutableDictionary dictionary];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + _stringSize.height+2*sf] forKey:@"TopLeft"];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + _stringSize.height] forKey:@"TopMiddle"];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + _stringSize.height+2*sf] forKey:@"TopRight"];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + size.size.height/2] forKey:@"MiddleLeft"];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + size.size.height/2] forKey:@"MiddleRight"];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + size.size.height-2*sf] forKey:@"LowerLeft"];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + size.size.height-2*sf-_stringSize.height] forKey:@"LowerRight"];
        [yRasterInit setObject:[NSNumber numberWithInt:size.origin.y + size.size.height-2*sf] forKey:@"LowerMiddle"];
        
        NSMutableDictionary *yRasterIncrement = [NSMutableDictionary dictionary];
        [yRasterIncrement setObject:[NSNumber numberWithInt:_stringSize.height] forKey:@"TopLeft"];
        [yRasterIncrement setObject:[NSNumber numberWithInt:_stringSize.height] forKey:@"TopMiddle"];
        [yRasterIncrement setObject:[NSNumber numberWithInt:_stringSize.height] forKey:@"TopRight"];
        [yRasterIncrement setObject:[NSNumber numberWithInt:_stringSize.height] forKey:@"MiddleLeft"];
        [yRasterIncrement setObject:[NSNumber numberWithInt:_stringSize.height] forKey:@"MiddleRight"];
        [yRasterIncrement setObject:[NSNumber numberWithInt:-_stringSize.height] forKey:@"LowerLeft"];
        [yRasterIncrement setObject:[NSNumber numberWithInt:-_stringSize.height] forKey:@"LowerRight"];
        [yRasterIncrement setObject:[NSNumber numberWithInt:-_stringSize.height] forKey:@"LowerMiddle"];
        
        
        int j, k, increment;
        NSArray *orientationPositionKeys = [NSArray arrayWithObjects:@"TopMiddle", @"MiddleLeft", @"MiddleRight", @"LowerMiddle", nil];
        BOOL orientationDrawn = NO;
        {
            id annot;
            NSEnumerator *enumerator;
            
            for (k=0; k<[orientationPositionKeys count]; k++)
            {
                NSArray *annotations = [annotationsDictionary objectForKey:[orientationPositionKeys objectAtIndex:k]];
                xRaster = [[xRasterInit objectForKey:[orientationPositionKeys objectAtIndex:k]] intValue];
                yRaster = [[yRasterInit objectForKey:[orientationPositionKeys objectAtIndex:k]] intValue];
                increment = [[yRasterIncrement objectForKey:[orientationPositionKeys objectAtIndex:k]] intValue];
                
                if([[orientationPositionKeys objectAtIndex:k] hasPrefix:@"Lower"])
                    enumerator = [annotations reverseObjectEnumerator];
                else
                    enumerator = [annotations objectEnumerator];
                
                while ((annot = [enumerator nextObject]))
                {
                    for (j=0; j<[annot count]; j++)
                    {
                        if([[annot objectAtIndex:j] isEqualToString:@"Orientation"])
                        {
                            if(!orientationDrawn)
                            {
                                [self drawOrientation: size];
                            }
                            orientationDrawn = YES;
                        }
                    }
                }
            }
        }
        
        if(orientationDrawn)
        {
            [yRasterInit setObject:[NSNumber numberWithInt:[[yRasterInit objectForKey:@"TopMiddle"] intValue]+[[yRasterIncrement objectForKey:@"TopMiddle"] intValue]] forKey:@"TopMiddle"];
            [yRasterInit setObject:[NSNumber numberWithInt:[[yRasterInit objectForKey:@"MiddleLeft"] intValue]+[[yRasterIncrement objectForKey:@"MiddleLeft"] intValue]] forKey:@"MiddleLeft"];
            [yRasterInit setObject:[NSNumber numberWithInt:[[yRasterInit objectForKey:@"MiddleRight"] intValue]+[[yRasterIncrement objectForKey:@"MiddleRight"] intValue]] forKey:@"MiddleRight"];
            [yRasterInit setObject:[NSNumber numberWithInt:[[yRasterInit objectForKey:@"LowerMiddle"] intValue]+[[yRasterIncrement objectForKey:@"LowerMiddle"] intValue]] forKey:@"LowerMiddle"];
        }
        
        NSArray *keys = [annotationsDictionary allKeys];
        
        for (k=0; k<[keys count]; k++)
        {
            NSString *key = [keys objectAtIndex:k];
            
            NSArray *annotations = [annotationsDictionary objectForKey:key];
            xRaster = [[xRasterInit objectForKey:key] intValue]; //* [self.window backingScaleFactor]; //Retina
            yRaster = [[yRasterInit objectForKey:key] intValue]; //* [self.window backingScaleFactor]; //Retina
            increment = [[yRasterIncrement objectForKey:key] intValue]; // * [self.window backingScaleFactor]; //retina
            
            NSEnumerator *enumerator;
            if([key hasPrefix:@"Lower"])
                enumerator = [annotations reverseObjectEnumerator];
            else
                enumerator = [annotations objectEnumerator];
            id annot;
            
            BOOL useStringTexture;
            
            if([key hasPrefix:@"Lower"])
                enumerator = [annotations reverseObjectEnumerator];
            else
                enumerator = [annotations objectEnumerator];
            
            while ((annot = [enumerator nextObject]))
            {
                @try
                {
                    tempString = [NSMutableString stringWithString:@""];
                    tempString2 = [NSMutableString stringWithString:@""];
                    tempString3 = [NSMutableString stringWithString:@""];
                    tempString4 = [NSMutableString stringWithString:@""];
                    for (j=0; j<[annot count]; j++)
                    {
                        if([[annot objectAtIndex:j] isEqualToString:@"Image Size"] && fullText)
                        {
                            [tempString appendFormat: NSLocalizedString( @"Image size: %ld x %ld", nil), (long) curDCM.pwidth, (long) curDCM.pheight];
                            useStringTexture = YES;
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"View Size"] && fullText)
                        {
                            [tempString appendFormat: NSLocalizedString( @"View size: %ld x %ld", nil), (long) size.size.width, (long) size.size.height];
                            useStringTexture = YES;
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"Mouse Position (px)"])
                        {
                            useStringTexture = NO;
                            
                            if( stringID.length == 0 || [stringID isEqualToString: @"previewDatabase"])
                            {
                                //                                if(mouseXPos!=0 || mouseYPos!=0)
                                {
                                    NSString *pixelUnit = @"";
                                    
                                    if( curDCM.SUVConverted)
                                        pixelUnit = @"SUV";
                                    
                                    if( curDCM.isRGB ) [tempString appendFormat: NSLocalizedString( @"X: %d px Y: %d px Value: R:%ld G:%ld B:%ld", @"No special characters for this string, only ASCII characters."), (int)mouseXPos, (int)mouseYPos, pixelMouseValueR, pixelMouseValueG, pixelMouseValueB];
                                    else [tempString appendFormat: NSLocalizedString( @"X: %d px Y: %d px Value: %2.2f %@", @"No special characters for this string, only ASCII characters."), (int)mouseXPos, (int)mouseYPos, pixelMouseValue, pixelUnit];
                                    
                                    if( blendingView)
                                    {
                                        if( [blendingView curDCM].SUVConverted)
                                            pixelUnit = @"SUV";
                                        
                                        if( [blendingView curDCM].isRGB )
                                            [tempString2 appendFormat: NSLocalizedString( @"Fused Image : X: %d px Y: %d px Value: R:%ld G:%ld B:%ld", @"No special characters for this string, only ASCII characters."), (int)blendingMouseXPos, (int)blendingMouseYPos, blendingPixelMouseValueR, blendingPixelMouseValueG, blendingPixelMouseValueB];
                                        else [tempString2 appendFormat: NSLocalizedString( @"Fused Image : X: %d px Y: %d px Value: %2.2f %@", @"No special characters for this string, only ASCII characters."), (int)blendingMouseXPos, (int)blendingMouseYPos, blendingPixelMouseValue, pixelUnit];
                                    }
                                    
                                    if( curDCM.displaySUVValue )
                                    {
                                        if( [curDCM hasSUV] == YES && curDCM.SUVConverted == NO)
                                        {
                                            [tempString3 appendFormat: NSLocalizedString( @"SUV: %.2f", @"SUV: Standard Uptake Value - No special characters for this string, only ASCII characters."), [self getSUV]];
                                        }
                                    }
                                    
                                    if( blendingView )
                                    {
                                        if( [[blendingView curDCM] displaySUVValue] && [[blendingView curDCM] hasSUV] && [[blendingView curDCM] SUVConverted] == NO)
                                        {
                                            [tempString4 appendFormat: NSLocalizedString( @"SUV (fused image): %.2f", @"SUV: Standard Uptake Value - No special characters for this string, only ASCII characters."), [self getBlendedSUV]];
                                        }
                                    }
                                }
                            }
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"Zoom"] && fullText)
                        {
                            [tempString appendFormat: NSLocalizedString( @"Zoom: %0.0f%%", @"No special characters for this string, only ASCII characters."), (float) [self displayedScaleValue]*100.0];
                            useStringTexture = NO;
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"Rotation Angle"] && fullText)
                        {
                            [tempString appendFormat: NSLocalizedString( @" Angle: %0.0f", @"No special characters for this string, only ASCII characters."), (float) ((long) [self displayedRotation] % 360)];
                            useStringTexture = NO;
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"Image Position"] && fullText)
                        {
                            NSString *orientationStack = @"";
                            if( [self is2DViewer] && [[self windowController] isEverythingLoaded] == YES)
                            {
                                if( volumicData == -1)
                                    volumicData = [[self windowController] isDataVolumicIn4D: YES checkEverythingLoaded: YES tryToCorrect: NO];
                                
                                if( volumicSeries == YES && [dcmPixList count] > 2 && volumicData == 1)
                                {
                                    double interval3d;
                                    double xd = [[dcmPixList objectAtIndex: 2] originX] - [[dcmPixList objectAtIndex: 1] originX]; // To avoid the problem with 1st scout image
                                    double yd = [[dcmPixList objectAtIndex: 2] originY] - [[dcmPixList objectAtIndex: 1] originY];
                                    double zd = [[dcmPixList objectAtIndex: 2] originZ] - [[dcmPixList objectAtIndex: 1] originZ];
                                    
                                    interval3d = sqrt(xd*xd + yd*yd + zd*zd);
                                    xd /= interval3d;	yd /= interval3d;	zd /= interval3d;
                                    
                                    float v[ 3] = { xd, yd, zd};
                                    char stackOrientationStart[ 10], stackOrientationEnd[ 10];
                                    if( flippedData == NO)
                                    {
                                        [self getOrientationText: stackOrientationStart : v : YES];
                                        [self getOrientationText: stackOrientationEnd : v : NO];
                                    }
                                    else
                                    {
                                        [self getOrientationText: stackOrientationStart : v : NO];
                                        [self getOrientationText: stackOrientationEnd : v : YES];
                                    }
                                    
                                    if( stackOrientationStart[ 0] != 0 && stackOrientationEnd[ 0] != 0)
                                    {
                                        float pos;
                                        
                                        if( flippedData) pos = (float) ([dcmPixList count] - curImage) / (float) [dcmPixList count];
                                        else pos = (float) curImage / (float) [dcmPixList count];
                                        
                                        if( pos < 0.4)
                                            orientationStack = [NSString stringWithFormat: @" %c (%c -> %c)", stackOrientationStart[ 0], stackOrientationStart[ 0], stackOrientationEnd[ 0]];
                                        else if( pos > 0.6)
                                            orientationStack = [NSString stringWithFormat: @" %c (%c -> %c)", stackOrientationEnd[ 0], stackOrientationStart[ 0], stackOrientationEnd[ 0]];
                                        else
                                            orientationStack = [NSString stringWithFormat: @" (%c -> %c)", stackOrientationStart[ 0], stackOrientationEnd[ 0]];
                                    }
                                }
                            }
                            
                            if( curDCM.stack > 1)
                            {
                                long maxVal;
                                
                                if(flippedData) maxVal = curImage-curDCM.stack+1;
                                else maxVal = curImage+curDCM.stack;
                                
                                if(maxVal < 0) maxVal = 0;
                                if(maxVal > [dcmPixList count]) maxVal = [dcmPixList count];
                                
                                if( flippedData) [tempString appendFormat: NSLocalizedString( @"Im: %ld-%ld/%ld %@", @"No special characters for this string, only ASCII characters."), (long) [dcmPixList count] - curImage, [dcmPixList count] - maxVal, (long) [dcmPixList count], orientationStack];
                                else [tempString appendFormat: NSLocalizedString( @"Im: %ld-%ld/%ld %@", @"No special characters for this string, only ASCII characters."), (long) curImage+1, maxVal, (long) [dcmPixList count], orientationStack];
                            }
                            else if( fullText)
                            {
                                if( flippedData) [tempString appendFormat: NSLocalizedString( @"Im: %ld/%ld %@", @"No special characters for this string, only ASCII characters."), (long) [dcmPixList count] - curImage, (long) [dcmPixList count], orientationStack];
                                else [tempString appendFormat: NSLocalizedString( @"Im: %ld/%ld %@", @"No special characters for this string, only ASCII characters."), (long) curImage+1, (long) [dcmPixList count], orientationStack];
                            }
                            
                            useStringTexture = NO;
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"Mouse Position (mm)"])
                        {
                            useStringTexture = NO;
                            
                            if( stringID == nil)
                            {
                                //								if( mouseXPos != 0 || mouseYPos != 0)
                                {
                                    float location[ 3 ];
                                    
                                    if( curDCM.stack > 1) {
                                        long maxVal;
                                        
                                        if( flippedData) maxVal = curImage-(curDCM.stack-1)/2;
                                        else maxVal = curImage+(curDCM.stack-1)/2;
                                        
                                        if( maxVal < 0) maxVal = 0;
                                        if( maxVal >= [dcmPixList count]) maxVal = (long)[dcmPixList count]-1;
                                        
                                        [[dcmPixList objectAtIndex: maxVal] convertPixX: mouseXPos pixY: mouseYPos toDICOMCoords: location pixelCenter: YES];
                                    }
                                    else {
                                        [curDCM convertPixX: mouseXPos pixY: mouseYPos toDICOMCoords: location pixelCenter: YES];
                                    }
                                    
                                    if( curDCM.is3DPlane)
                                    {
                                        if(fabs(location[0]) < 1.0 && location[0] != 0.0 && curDCM.pixelSpacingX < 0.2)
                                            [tempString appendFormat: @"X: %2.2f %cm Y: %2.2f %cm Z: %2.2f %cm", location[0] * 1000.0, 0xB5, location[1] * 1000.0, 0xB5, location[2] * 1000.0, 0xB5];
                                        else
                                            [tempString appendFormat: @"X: %2.2f mm Y: %2.2f mm Z: %2.2f mm", location[0], location[1], location[2]];
                                    }
                                    else
                                    {
                                        if(fabs(location[0]) < 1.0 && location[0] != 0.0 && curDCM.pixelSpacingX < 0.2)
                                            [tempString appendFormat: @"X: %2.2f %cm Y: %2.2f %cm", location[0] * 1000.0, 0xB5, location[1] * 1000.0, 0xB5];
                                        else
                                            [tempString appendFormat: @"X: %2.2f mm Y: %2.2f mm", location[0], location[1]];
                                    }
                                }
                            }
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"Window Level / Window Width"])
                        {
                            useStringTexture = NO;
                            
                            float lwl = curDCM.wl;
                            float lww = curDCM.ww;
                            
                            int iwl = lwl;
                            int iww = lww;
                            
                            if(lww < 50 && (lwl !=  iwl || lww != iww))
                            {
                                [tempString appendFormat: NSLocalizedString( @"WL: %0.4f WW: %0.4f", @"WW: window width, WL: window level"), lwl, lww];
                            }
                            else
                                [tempString appendFormat: NSLocalizedString( @"WL: %d WW: %d", @"WW: window width, WL: window level"), (int) lwl, (int) lww];
                            
                            if( [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] && [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"NM"]))
                            {
                                if( curDCM.maxValueOfSeries)
                                {
                                    float min = lwl - lww/2, max = lwl + lww/2;
                                    
                                    [tempString2 appendFormat: NSLocalizedString( @"From: %d %% (%0.2f) to: %d %% (%0.2f)", @"No special characters for this string, only ASCII characters."), (long) (min * 100. / curDCM.maxValueOfSeries), lwl - lww/2, (long) (max * 100. / curDCM.maxValueOfSeries), lwl + lww/2];
                                }
                            }
                        }
                        else if( [[annot objectAtIndex:j] isEqualToString:@"Plugin"] )
                        {
                            
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSNumber numberWithFloat: yRaster], @"yRaster",
                                                      [NSNumber numberWithFloat: xRaster], @"xRaster",
                                                      [NSNumber numberWithInt: [[align objectForKey:key] intValue]], @"alignment",
                                                      nil];
                            
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDrawTextInfoNotification
                                                                                object: self
                                                                              userInfo: userInfo];
                            yRaster += increment;
                        }
                        
                        else if([[annot objectAtIndex:j] isEqualToString:@"Orientation"])
                        {
                            if(!orientationDrawn) [self drawOrientation: size];
                            orientationDrawn = YES;
                            useStringTexture = YES;
                        }
                        else if([[annot objectAtIndex:j] isEqualToString:@"Thickness / Location / Position"])
                        {
                            useStringTexture = YES;
                            
                            if( curDCM.sliceThickness != 0 && curDCM.sliceLocation != 0)
                            {
                                if( curDCM.stack > 1)
                                {
                                    float vv, pp;
                                    
                                    [self getThickSlabThickness: &vv location: &pp];
                                    
                                    if( vv < 1.0 && vv != 0.0)
                                    {
                                        if( fabs( pp) < 1.0 && pp != 0.0)
                                            [tempString appendFormat: NSLocalizedString( @"Thickness: %0.2f %cm Location: %0.2f %cm", nil), fabs( vv * 1000.0), 0xB5, pp * 1000.0, 0xB5];
                                        else
                                            [tempString appendFormat: NSLocalizedString( @"Thickness: %0.2f %cm Location: %0.2f mm", nil), fabs( vv * 1000.0), 0xB5, pp];
                                    }
                                    else
                                        [tempString appendFormat: NSLocalizedString( @"Thickness: %0.2f mm Location: %0.2f mm", nil), fabs( vv), pp];
                                }
                                else if( fullText)
                                {
                                    if (curDCM.sliceThickness < 1.0 && curDCM.sliceThickness != 0.0)
                                    {
                                        if( fabs( curDCM.sliceLocation) < 1.0 && curDCM.sliceLocation != 0.0)
                                            [tempString appendFormat: NSLocalizedString( @"Thickness: %0.2f %cm Location: %0.2f %cm", nil), curDCM.sliceThickness * 1000.0, 0xB5, curDCM.sliceLocation * 1000.0, 0xB5];
                                        else
                                            [tempString appendFormat: NSLocalizedString( @"Thickness: %0.2f %cm Location: %0.2f mm", nil), curDCM.sliceThickness * 1000.0, 0xB5, curDCM.sliceLocation];
                                    }
                                    else
                                        [tempString appendFormat: NSLocalizedString( @"Thickness: %0.2f mm Location: %0.2f mm", nil), curDCM.sliceThickness, curDCM.sliceLocation];
                                }
                            }
                            else if( curDCM.viewPosition || curDCM.patientPosition)
                            {
                                if ( curDCM.viewPosition ) [tempString appendFormat: NSLocalizedString( @"Position: %@ ", nil), curDCM.viewPosition];
                                if ( curDCM.patientPosition )
                                {
                                    if(curDCM.viewPosition) [tempString appendString: curDCM.patientPosition];
                                    else [tempString appendFormat: NSLocalizedString( @"Position: %@ ", nil), curDCM.patientPosition];
                                }
                            }
                        }
                        else if( [[annot objectAtIndex:j] isEqualToString: @"PatientName"])
                        {
                            if( annotFull == annotationType && [[dcmFilesList objectAtIndex: 0] valueForKeyPath:@"series.study.name"])
                                [tempString appendString: [[dcmFilesList objectAtIndex: 0] valueForKeyPath:@"series.study.name"]];
                        }
                        else if( fullText)
                        {
                            [tempString appendFormat:@" %@", [annot objectAtIndex:j]];
                            useStringTexture = YES;
                        }
                    }
                    
                    [tempString setString:[tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    [tempString2 setString:[tempString2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    [tempString3 setString:[tempString3 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    [tempString4 setString:[tempString4 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    
                    if(![tempString isEqualToString:@""])
                    {
                        long xAdd = 0;
                        if( [key isEqualToString: @"TopLeft"] && yRaster-increment < colorBoxSize+2*sf)
                            xAdd = colorBoxSize;
                        
                        [self DrawNSStringGL:tempString :fontList :xRaster+xAdd :yRaster align:[[align objectForKey:key] intValue] useStringTexture:useStringTexture];
                        yRaster += increment;
                    }
                    if(![tempString2 isEqualToString:@""])
                    {
                        long xAdd = 0;
                        if( [key isEqualToString: @"TopLeft"] && yRaster-increment < colorBoxSize+2*sf)
                            xAdd = colorBoxSize;
                        
                        [self DrawNSStringGL:tempString2 :fontList :xRaster+xAdd :yRaster align:[[align objectForKey:key] intValue] useStringTexture:useStringTexture];
                        yRaster += increment;
                    }
                    if(![tempString3 isEqualToString:@""])
                    {
                        long xAdd = 0;
                        if( [key isEqualToString: @"TopLeft"] && yRaster-increment < colorBoxSize+2*sf)
                            xAdd = colorBoxSize;
                        
                        [self DrawNSStringGL:tempString3 :fontList :xRaster+xAdd :yRaster align:[[align objectForKey:key] intValue] useStringTexture:useStringTexture];
                        yRaster += increment;
                    }
                    if(![tempString4 isEqualToString:@""])
                    {
                        long xAdd = 0;
                        if( [key isEqualToString: @"TopLeft"] && yRaster-increment < colorBoxSize+2*sf)
                            xAdd = colorBoxSize;
                        
                        [self DrawNSStringGL:tempString4 :fontList :xRaster+xAdd :yRaster align:[[align objectForKey:key] intValue] useStringTexture:useStringTexture];
                        yRaster += increment;
                    }
                }
                @catch (NSException *e)
                {
                    if( exceptionDisplayed == NO)
                    {
                        NSRunCriticalAlertPanel(NSLocalizedString(@"Annotations Error",nil), @"%@\r\r%@", NSLocalizedString(@"OK",nil), nil, nil, e, annot);
                        
                        NSLog( @"draw custom annotation exception: %@\r\r%@", e, annot);
                        
                        exceptionDisplayed = YES;
                    }
                }
            }// while
        } // for k
        
        yRaster = size.origin.y + size.size.height-2;
        xRaster = size.origin.x + size.size.width-2;
        if( fullText)
            [self DrawNSStringGL: @"Made In Horos" :fontList :xRaster :yRaster rightAlignment:YES useStringTexture:YES];
    }
    
   
}

- (void) drawTextualData:(NSRect) size :(long) annotations
{
    [self drawTextualData: size annotationsLevel: annotations fullText: YES onlyOrientation: NO];
}

#pragma mark-
#pragma mark image transformation


- (void) applyImageTransformation
{
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
    glLoadIdentity ();
    glViewport(0, 0, drawingFrameRect.size.width, drawingFrameRect.size.height);
    
    glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f);
    glRotatef (rotation, 0.0f, 0.0f, 1.0f);
    glTranslatef( origin.x, -origin.y, 0.0f);
    glScalef( 1.f, curDCM.pixelRatio, 1.f);
}

- (void) drawRect:(NSRect) r
{
    if( drawing == NO) return;
    
    @synchronized (self)
    {
        NSRect backingBounds = [self convertRectToBacking: [self frame]]; // Retina
        
        if( previousScalingFactor != self.window.backingScaleFactor && self.window.backingScaleFactor != 0)
        {
            if( previousScalingFactor)
            {
                scaleValue *= self.window.backingScaleFactor / previousScalingFactor;
                origin.x *= self.window.backingScaleFactor / previousScalingFactor;
                origin.y *= self.window.backingScaleFactor / previousScalingFactor;
            }
            previousScalingFactor = self.window.backingScaleFactor;
            

            [DCMView purgeStringTextureCache];
            
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixLabelGLFontChangeNotification object: self];
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixGLFontChangeNotification object: self];
            
            for( ROI *r in curRoiList)
                [r setCurView:self];
        }
        
        [self drawRect: backingBounds withContext: [self openGLContext]];
    }
}

- (void) drawCrossLines:(float[2][3]) sft ctx: (CGLContextObj) cgl_ctx
{
    return [self drawCrossLines: sft ctx:  cgl_ctx perpendicular: NO withShift: 0];
}

- (void) drawCrossLines:(float[2][3]) sft ctx: (CGLContextObj) cgl_ctx withShift: (double) shift
{
    return [self drawCrossLines: sft ctx:  cgl_ctx perpendicular: NO withShift: shift];
}

- (void) drawCrossLines:(float[2][3]) sft ctx: (CGLContextObj) cgl_ctx withShift: (double) shift showPoint: (BOOL) showPoint
{
    return [self drawCrossLines: sft ctx:  cgl_ctx perpendicular: NO withShift: shift half: NO showPoint: showPoint];
}

- (void) drawCrossLines:(float[2][3]) sft ctx: (CGLContextObj) cgl_ctx perpendicular: (BOOL) perpendicular
{
    return [self drawCrossLines: sft ctx:  cgl_ctx perpendicular: perpendicular withShift: 0];
}

- (void) drawCrossLines:(float[2][3]) sft ctx: (CGLContextObj) cgl_ctx perpendicular:(BOOL) perpendicular withShift:(double) shift
{
    return [self drawCrossLines: sft ctx:  cgl_ctx perpendicular: perpendicular withShift: shift half: NO];
}

- (void) drawCrossLines:(float[2][3]) sft ctx: (CGLContextObj) cgl_ctx perpendicular:(BOOL) perpendicular withShift:(double) shift half:(BOOL) half
{
    return [self drawCrossLines: sft ctx:  cgl_ctx perpendicular: perpendicular withShift: shift half: half showPoint: NO];
}

- (void) drawCrossLines:(float[2][3]) sft ctx: (CGLContextObj) cgl_ctx perpendicular:(BOOL) perpendicular withShift:(double) shift half:(BOOL) half showPoint:(BOOL) showPoint
{
    float a[ 2] = {0, 0};	// perpendicular vector
    float c[2][3];
    
    for( int i = 0; i < 2; i++)
        for( int x = 0; x < 3; x++)
            c[i][x] = sft[i][x];
    
    if( perpendicular || shift != 0)
    {
        a[ 1] = c[ 0][ 0] - c[ 1][ 0];
        a[ 0] = c[ 0][ 1] - c[ 1][ 1];
        
        double t = a[ 1]*a[ 1] + a[ 0]*a[ 0];
        t = sqrt(t);
        a[0] = a[0]/t;
        a[1] = a[1]/t;
        
        c[ 0][ 0] += a[0]*shift;	c[ 0][ 1] -= a[1]*shift;
        c[ 1][ 0] += a[0]*shift;	c[ 1][ 1] -= a[1]*shift;
    }
    
    if( showPoint)
    {
        glEnable(GL_POINT_SMOOTH);
        glPointSize( 12 * self.window.backingScaleFactor);
        
        glBegin( GL_POINTS);
        float mx = (c[ 0][ 0] + c[ 1][ 0]) / 2.;
        float my = (c[ 0][ 1] + c[ 1][ 1]) / 2.;
        
        glVertex2f( scaleValue*(mx/curDCM.pixelSpacingX-curDCM.pwidth/2.), scaleValue*( my/curDCM.pixelSpacingY - curDCM.pheight /2.));
        glEnd();
    }
    else
    {
        glEnable(GL_LINE_SMOOTH);
        glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
        glEnable(GL_BLEND);
        glBegin(GL_LINES);
        glVertex2f( scaleValue*(c[ 0][ 0]/curDCM.pixelSpacingX-curDCM.pwidth/2.), scaleValue*(c[ 0][ 1]/curDCM.pixelSpacingY - curDCM.pheight /2.));
        
        if( half)
            glVertex2f( 0, 0);
        else
            glVertex2f( scaleValue*(c[ 1][ 0]/curDCM.pixelSpacingX-curDCM.pwidth/2.), scaleValue*(c[ 1][ 1]/curDCM.pixelSpacingY - curDCM.pheight /2.));
        glEnd();
    }
    
    
    if( perpendicular)
    {
        glLineWidth(1.0 * self.window.backingScaleFactor);
        glBegin(GL_LINES);
        glVertex2f( scaleValue*((c[ 0][ 0]+a[0]*sliceFromToThickness/2.)/curDCM.pixelSpacingX-curDCM.pwidth/2.), scaleValue*((c[ 0][ 1]-a[1]*sliceFromToThickness/2.)/curDCM.pixelSpacingY - curDCM.pheight /2.));
        glVertex2f( scaleValue*((c[ 1][ 0]+a[0]*sliceFromToThickness/2.)/curDCM.pixelSpacingX-curDCM.pwidth/2.), scaleValue*((c[ 1][ 1]-a[1]*sliceFromToThickness/2.)/curDCM.pixelSpacingY - curDCM.pheight /2.));
        glEnd();
        
        glBegin(GL_LINES);
        glVertex2f( scaleValue*((c[ 0][ 0]-a[0]*sliceFromToThickness/2.)/curDCM.pixelSpacingX-curDCM.pwidth/2.), scaleValue*((c[ 0][ 1]+a[1]*sliceFromToThickness/2.)/curDCM.pixelSpacingY - curDCM.pheight /2.));
        glVertex2f( scaleValue*((c[ 1][ 0]-a[0]*sliceFromToThickness/2.)/curDCM.pixelSpacingX-curDCM.pwidth/2.), scaleValue*((c[ 1][ 1]+a[1]*sliceFromToThickness/2.)/curDCM.pixelSpacingY - curDCM.pheight /2.));
        glEnd();
    }
}

//- (NSOpenGLContext*) offscreenDisplay: (NSRect) r
//{
//	NSOpenGLPixelFormatAttribute attrs[] = { NSOpenGLPFAOffScreen, NSOpenGLPFADoubleBuffer, NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32, 0};
//    NSOpenGLPixelFormat* pixFmt = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
//
//	NSOpenGLContext * c = [[[NSOpenGLContext alloc] initWithFormat: pixFmt shareContext: nil] autorelease];
//
//	void* memBuffer = (void *) malloc (drawingFrameRect.size.width * drawingFrameRect.size.height * 4);
//	[c setOffScreen: memBuffer width: drawingFrameRect.size.width height: drawingFrameRect.size.height rowbytes: drawingFrameRect.size.width*4];
//
////	NSOpenGLContext * c = [self openGLContext];
//
//	[c makeCurrentContext];
////	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
//
////	GLuint framebuffer, renderbuffer;
////	GLenum status;
////	// Set the width and height appropriately for you image
////	GLuint texWidth = r.size.width,
////		   texHeight = r.size.height;
////
////	//Set up a FBO with one renderbuffer attachment
////	glGenFramebuffersEXT(1, &framebuffer);
////	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer);
////	glGenRenderbuffersEXT(1, &renderbuffer);
////	glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, renderbuffer);
////	glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_RGBA8, texWidth, texHeight);
////	glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
////					 GL_RENDERBUFFER_EXT, renderbuffer);
////	status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
//////	if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
////					// Handle errors
//
//	[self drawRect: r withContext: c];
//
//	// Make the window the target
////	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
//	//Your code to use the contents
//	// ...
//	// Delete the renderbuffer attachment
////	glDeleteRenderbuffersEXT(1, &renderbuffer);
//
//
//
//	return c;
//}

- (void)drawWaveform {
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity ();
    NSSize size = drawingFrameRect.size;
    glScalef (2.0f /(xFlipped ? -(size.width) : size.width), -2.0f / (yFlipped ? -(size.height) : size.height), 1.0f); // scale to port per pixel scale
    //	glRotatef (rotation, 0.0f, 0.0f, 1.0f); // no rotation for waveform
    glTranslatef(origin.x , -origin.y, 0.0f);
    if (curDCM.pixelRatio != 1.0) glScalef( 1.f, curDCM.pixelRatio, 1.f); // this is done for
    glScalef(scaleValue/2*curDCM.pwidth, scaleValue/2*curDCM.pheight, 1.f); // scaleValue/2*curDCM.pheight
    // the scene is now in sync with the standard OsiriX DICOM viewer: the drawn pix would be in the rectangle at (-1,-1) with size (2,2)... since this is a waveform, we assume the dcmpix is square
    float m = MIN(size.height, size.width);
    glScalef(size.width/m, size.height/m, 1); // use the whole window, not just the part covered by the undrawn DCMPix... // TODO: check that this can be used if we use regions...
    glTranslatef(-1, -1, 0);
    glScalef(2, 2, 1);
    // (0,0,1,1) now covers the whole view, (0,0) is the top left
    
    // ooook.... what is the current viewable range? so we can avoid drawing useless data...
    GLint viewport[4];
    GLdouble mvmatrix[16], projmatrix[16];
    glGetIntegerv(GL_VIEWPORT, viewport);
    glGetDoublev(GL_MODELVIEW_MATRIX, mvmatrix);
    glGetDoublev(GL_PROJECTION_MATRIX, projmatrix);
    /*  note viewport[3] is height of window in pixels  */
    GLdouble p0[3], p1[3];  /*  returned world x, y, z coords  */
    gluUnProject(viewport[0], viewport[1], 0, mvmatrix, projmatrix, viewport, &p0[0], &p0[1], &p0[2]);
    gluUnProject(viewport[0]+viewport[2], viewport[1]+viewport[3], 0, mvmatrix, projmatrix, viewport, &p1[0], &p1[1], &p1[2]);
    // NSLog(@"X Range: %f -> %f = %f", p0[0], p1[0], p1[0]-p0[0]);
    
    DCMWaveformSequence* ws = [[curDCM.waveform sequences] objectAtIndex:0];
    
    NSUInteger valuesCount;
    CGFloat* values = [ws getValues:&valuesCount];
    size_t numberOfChannels = ws.numberOfWaveformChannels;
    NSUInteger numberOfSamples = ws.numberOfWaveformSamples;
    
    glEnable(GL_LINE_SMOOTH);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    CGFloat h = 1./numberOfChannels;
    
    for (size_t i = 1; i < numberOfChannels; ++i) {
        glBegin(GL_LINE);
        glVertex2f(0,h*i);
        glVertex2f(1,h*i);
        glEnd();
    }
    
//    size_t step = sizeof(CGFloat)*numberOfChannels;
    for (size_t i = 0; i < numberOfChannels; ++i) {
        DCMWaveformChannelDefinition* cd = [ws.channelDefinitions objectAtIndex:i];
        CGFloat min, max; [cd getValuesMin:&min max:&max];
        CGFloat mm = MAX(fabs(min), fabs(max));
        CGFloat* v = &values[i];
        glBegin(GL_LINE_STRIP);
        for (NSUInteger x = 0; x < numberOfSamples; ++x, v += numberOfChannels)
            glVertex2d(1./numberOfSamples*x, h*(0.5+i)+(*v/mm/2)*h);
        glEnd();
    }
    
    // this is the test pattern.... a centered spiral...
    
    /*glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
     glEnable(GL_BLEND);
     glColor4f(249./255., 240./255., 140./255., 1);
     
     glBegin(GL_LINE_STRIP);
     glVertex2f(0.5,0.5);
     glVertex2f(0.5,1);
     glVertex2f(1,1);
     glVertex2f(1,0);
     glVertex2f(0,0);
     glVertex2f(0,1);
     glEnd();*/
}

- (void) drawRect:(NSRect)aRect withContext:(NSOpenGLContext *)ctx
{
    long clutBars = CLUTBARS, annotations = annotationType;
    BOOL frontMost = NO, is2DViewer = [self is2DViewer];
    float sf = self.window.backingScaleFactor;
    
    //	#ifndef OSIRIX_LIGHT
    //    iChatRunning = NO;
    //    if( is2DViewer)
    //        iChatRunning = [[IChatTheatreDelegate sharedDelegate] isIChatTheatreRunning];
    //	#else
    //    iChatRunning = NO;
    //	#endif
    
    if( is2DViewer)
        frontMost = self.window.isKeyWindow;    //[ViewerController isFrontMost2DViewer: [self window]];
    
    if( firstTimeDisplay == NO && is2DViewer)
    {
        firstTimeDisplay = YES;
        [self updatePresentationStateFromSeries];
    }
    
    //	if( iChatRunning)
    //	{
    //		if( drawLock == nil) drawLock = [[NSRecursiveLock alloc] init];
    //		[drawLock lock];
    //	}
    //	else
    {
        [drawLock release];
        drawLock = nil;
    }
    
    [ctx makeCurrentContext];
    if( ctx == nil)
        return;
    
    @try
    {
        if( needToLoadTexture)// || iChatRunning)
            [self loadTexturesCompute];
        
        if( noScale)
        {
            self.scaleValue = 1.0f;
            [self setOriginX: 0 Y: 0];
        }
        
        NSPoint offset = { 0.0f, 0.0f };
        
        if( NSEqualRects( drawingFrameRect, aRect) == NO)
        {
            [[self openGLContext] clearDrawable];
            [[self openGLContext] setView: self];
        }
        
        //		if( ctx == _alternateContext)
        //			savedDrawingFrameRect = drawingFrameRect;
        
        drawingFrameRect = aRect;
        
        CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx == nil)
            return;
        
        glViewport (0, 0, drawingFrameRect.size.width, drawingFrameRect.size.height); // set the viewport to cover entire window
        
        if( whiteBackground)
            glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
        else
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        
        glClear (GL_COLOR_BUFFER_BIT);
        
        if( dcmPixList && curImage > -1)
        {
            if( blendingView != nil && syncOnLocationImpossible == NO)// && ctx!=_alternateContext)
            {
                glBlendFunc(GL_ONE, GL_ONE);
                glEnable( GL_BLEND);
            }
            else
            {
                glBlendFunc(GL_ONE, GL_ONE);
                glDisable( GL_BLEND);
            }
            
            //			if (curDCM.waveform) // [DCMAbstractSyntaxUID isWaveform:curDCM.SOPClassUID]
            //                [self drawWaveform];
            //            else
            [self drawRectIn:drawingFrameRect :pTextureName :offset :textureX :textureY :textureWidth :textureHeight];
            
            BOOL noBlending = NO;
            
            if( is2DViewer == YES)
            {
                if( isKeyView == NO) noBlending = YES;
            }
            
            if( blendingView != nil && syncOnLocationImpossible == NO && noBlending == NO )
            {
                glBlendEquation(GL_FUNC_ADD);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                if( blendingTextureName)
                    [blendingView drawRectIn:drawingFrameRect :blendingTextureName :offset :blendingTextureX :blendingTextureY :blendingTextureWidth :blendingTextureHeight];
                else
                    NSLog( @"blendingTextureName == nil");
                
                glDisable( GL_BLEND);
            }
            
            if( is2DViewer)
            {
                if( [[self windowController] highLighted] > 0)
                {
                    glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
                    glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
                    glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
                    
                    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    glEnable(GL_BLEND);
                    
                    if( gInvertColors)
                        glColor4f ( 0, 0, 0, [[self windowController] highLighted]);
                    else
                        glColor4f (249./255., 240./255., 140./255., [[self windowController] highLighted]);
                    glLineWidth(1.0 * sf);
                    glBegin(GL_QUADS);
                    glVertex2f(0.0, 0.0);
                    glVertex2f(0.0, drawingFrameRect.size.height);
                    glVertex2f(drawingFrameRect.size.width, drawingFrameRect.size.height);
                    glVertex2f(drawingFrameRect.size.width, 0);
                    glEnd();
                    glDisable(GL_BLEND);
                }
            }
            
            // highlight the visible part of the view (the part visible through iChat)
            //			#ifndef OSIRIX_LIGHT
            //			if( iChatRunning && ctx!=_alternateContext && [[self window] isMainWindow] && isKeyView && iChatWidth>0 && iChatHeight>0)
            //			{
            //				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
            //				glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
            //				glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
            //				NSPoint topLeft;
            //				topLeft.x = drawingFrameRect.size.width/2 - iChatWidth/2.0;
            //				topLeft.y = drawingFrameRect.size.height/2 - iChatHeight/2.0;
            //
            //				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            //				glEnable(GL_BLEND);
            //
            //				glColor4f (0.0f, 0.0f, 0.0f, 0.7f);
            //				glLineWidth(1.0 * sf);
            //				glBegin(GL_QUADS);
            //					glVertex2f(0.0, 0.0);
            //					glVertex2f(0.0, topLeft.y);
            //					glVertex2f(drawingFrameRect.size.width, topLeft.y);
            //					glVertex2f(drawingFrameRect.size.width, 0.0);
            //				glEnd();
            //
            //				glBegin(GL_QUADS);
            //					glVertex2f(0.0, topLeft.y);
            //					glVertex2f(topLeft.x, topLeft.y);
            //					glVertex2f(topLeft.x, topLeft.y+iChatHeight);
            //					glVertex2f(0.0, topLeft.y+iChatHeight);
            //				glEnd();
            //
            //				glBegin(GL_QUADS);
            //					glVertex2f(topLeft.x+iChatWidth, topLeft.y);
            //					glVertex2f(drawingFrameRect.size.width, topLeft.y);
            //					glVertex2f(drawingFrameRect.size.width, topLeft.y+iChatHeight);
            //					glVertex2f(topLeft.x+iChatWidth, topLeft.y+iChatHeight);
            //				glEnd();
            //
            //				glBegin(GL_QUADS);
            //					glVertex2f(0.0, topLeft.y+iChatHeight);
            //					glVertex2f(drawingFrameRect.size.width, topLeft.y+iChatHeight);
            //					glVertex2f(drawingFrameRect.size.width, drawingFrameRect.size.height);
            //					glVertex2f(0.0, drawingFrameRect.size.height);
            //				glEnd();
            //
            //				glColor4f (1.0f, 1.0f, 1.0f, 0.8f);
            //				glBegin(GL_LINE_LOOP);
            //					glVertex2f(topLeft.x, topLeft.y);
            //					glVertex2f(topLeft.x, topLeft.y+iChatHeight);
            //					glVertex2f(topLeft.x+iChatWidth, topLeft.y+iChatHeight);
            //					glVertex2f(topLeft.x+iChatWidth, topLeft.y);
            //				glEnd();
            //
            //				glLineWidth(1.0 * sf);
            //				glDisable(GL_BLEND);
            //
            //				// label
            //				NSPoint iChatTheatreSharedViewLabelPosition;
            //				iChatTheatreSharedViewLabelPosition.x = drawingFrameRect.size.width/2.0;
            //				iChatTheatreSharedViewLabelPosition.y = topLeft.y;
            //
            //				[self DrawNSStringGL:NSLocalizedString(@"iChat Theatre shared view", nil) :fontListGL :iChatTheatreSharedViewLabelPosition.x :iChatTheatreSharedViewLabelPosition.y align:DCMViewTextAlignCenter useStringTexture:YES];
            //			}
            //			#endif
            // ***********************
            // DRAW CLUT BARS ********
            
            if( is2DViewer == YES && annotations != annotNone) // && ctx!=_alternateContext)
            {
                glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
                glScalef (2.0f /(drawingFrameRect.size.width), -2.0f / (drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
                
                if( clutBars == barOrigin || clutBars == barBoth)
                {
                    float			heighthalf = drawingFrameRect.size.height/2 - 1;
                    float			widthhalf = drawingFrameRect.size.width/2 - 1;
                    NSString		*tempString = nil;
                    
                    //#define BARPOSX1 50.f
                    //#define BARPOSX2 20.f
                    
#define BARPOSX1 62.f
#define BARPOSX2 32.f
                    
                    heighthalf = 0;
                    
                    //					glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
                    //					glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f);
                    
                    glLineWidth(1.0 * sf);
                    glBegin(GL_LINES);
                    for( int i = 0; i < 256; i++ )
                    {
                        glColor3ub ( redTable[ i], greenTable[ i], blueTable[ i]);
                        
                        glVertex2f(  widthhalf - BARPOSX1*sf, heighthalf - (-128.f*sf + i*sf));
                        glVertex2f(  widthhalf - BARPOSX2*sf, heighthalf - (-128.f*sf + i*sf));
                    }
                    glColor3ub ( 128, 128, 128);
                    glVertex2f(  widthhalf - BARPOSX1*sf, heighthalf - -128.f*sf);		glVertex2f(  widthhalf - BARPOSX2*sf , heighthalf - -128.f*sf);
                    glVertex2f(  widthhalf - BARPOSX1*sf, heighthalf - 127.f*sf);			glVertex2f(  widthhalf - BARPOSX2*sf , heighthalf - 127.f*sf);
                    glVertex2f(  widthhalf - BARPOSX1*sf, heighthalf - -128.f*sf);		glVertex2f(  widthhalf - BARPOSX1*sf, heighthalf - 127.f*sf);
                    glVertex2f(  widthhalf - BARPOSX2*sf ,heighthalf -  -128.f*sf);		glVertex2f(  widthhalf - BARPOSX2*sf, heighthalf - 127.f*sf);
                    glEnd();
                    
                    if( curWW < 50 )
                    {
                        tempString = [NSString stringWithFormat: @"%0.4f", curWL - curWW/2];
                        [self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1*sf: heighthalf - -133*sf rightAlignment: YES useStringTexture: NO];
                        
                        tempString = [NSString stringWithFormat: @"%0.4f", curWL];
                        [self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1*sf: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
                        
                        tempString = [NSString stringWithFormat: @"%0.4f", curWL + curWW/2];
                        [self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1*sf: heighthalf - 120*sf rightAlignment: YES useStringTexture: NO];
                    }
                    else
                    {
                        tempString = [NSString stringWithFormat: @"%0.0f", curWL - curWW/2];
                        [self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1*sf: heighthalf - -133*sf rightAlignment: YES useStringTexture: NO];
                        
                        tempString = [NSString stringWithFormat: @"%0.0f", curWL];
                        [self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1*sf: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
                        
                        tempString = [NSString stringWithFormat: @"%0.0f", curWL + curWW/2];
                        [self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1*sf: heighthalf - 120*sf rightAlignment: YES useStringTexture: NO];
                    }
                } //clutBars == barOrigin || clutBars == barBoth
                
                if( blendingView )
                {
                    if( clutBars == barFused || clutBars == barBoth)
                    {
                        unsigned char	*bred = nil, *bgreen = nil, *bblue = nil;
                        float			heighthalf = drawingFrameRect.size.height/2 - 1;
                        float			widthhalf = drawingFrameRect.size.width/2 - 1;
                        float			bwl, bww;
                        NSString		*tempString = nil;
                        
                        if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                        {
                            if( PETredTable == nil)
                                [DCMView computePETBlendingCLUT];
                            
                            bred = PETredTable;
                            bgreen = PETgreenTable;
                            bblue = PETblueTable;
                        }
                        else [blendingView getCLUT:&bred :&bgreen :&bblue];
                        
#define BBARPOSX1 55.f
#define BBARPOSX2 25.f
                        
                        heighthalf = 0;
                        
                        glLineWidth(1.0 * sf);
                        glBegin(GL_LINES);
                        
                        if( bred)
                        {
                            for( int i = 0; i < 256; i++ )
                            {
                                glColor3ub ( bred[ i], bgreen[ i], bblue[ i]);
                                
                                glVertex2f(  -widthhalf + BBARPOSX1*sf, heighthalf - (-128.f*sf + i*sf));
                                glVertex2f(  -widthhalf + BBARPOSX2*sf, heighthalf - (-128.f*sf + i*sf));
                            }
                        }
                        else
                            NSLog( @"bred == nil");
                        
                        glColor3ub ( 128, 128, 128);
                        glVertex2f(  -widthhalf + BBARPOSX1*sf, heighthalf - -128.f*sf);		glVertex2f(  -widthhalf + BBARPOSX2*sf , heighthalf - -128.f*sf);
                        glVertex2f(  -widthhalf + BBARPOSX1*sf, heighthalf - 127.f*sf);         glVertex2f(  -widthhalf + BBARPOSX2*sf , heighthalf - 127.f*sf);
                        glVertex2f(  -widthhalf + BBARPOSX1*sf, heighthalf - -128.f*sf);		glVertex2f(  -widthhalf + BBARPOSX1*sf, heighthalf - 127.f*sf);
                        glVertex2f(  -widthhalf + BBARPOSX2*sf ,heighthalf -  -128.f*sf);		glVertex2f(  -widthhalf + BBARPOSX2*sf, heighthalf - 127.f*sf);
                        glEnd();
                        
                        [blendingView getWLWW: &bwl :&bww];
                        
                        if( curWW < 50)
                        {
                            tempString = [NSString stringWithFormat: @"%0.4f", bwl - bww/2];
                            [self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1*sf + 4*sf: heighthalf - -133*sf];
                            
                            tempString = [NSString stringWithFormat: @"%0.4f", bwl];
                            [self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1*sf + 4*sf: heighthalf - 0];
                            
                            tempString = [NSString stringWithFormat: @"%0.4f", bwl + bww/2];
                            [self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1*sf + 4*sf: heighthalf - 120*sf];
                        }
                        else
                        {
                            tempString = [NSString stringWithFormat: @"%0.0f", bwl - bww/2];
                            [self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1*sf + 4*sf: heighthalf - -133*sf];
                            
                            tempString = [NSString stringWithFormat: @"%0.0f", bwl];
                            [self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1*sf + 4*sf: heighthalf - 0];
                            
                            tempString = [NSString stringWithFormat: @"%0.0f", bwl + bww/2];
                            [self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1*sf + 4*sf: heighthalf - 120*sf];
                        }
                    }
                } //blendingView
            } //is2DViewer == YES
            
            if (annotations != annotNone)
            {
                glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
                glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
                
                //FRAME RECT IF MORE THAN 1 WINDOW and IF THIS WINDOW IS THE FRONTMOST : BORDER AROUND THE IMAGE
                
                if( [ViewerController numberOf2DViewer] > 1 && is2DViewer == YES && stringID == nil)
                {
                    // draw line around key View - RED BOX
                    
                    if( isKeyView && (frontMost || [ViewerController frontMostDisplayed2DViewerForScreen: self.window.screen] == self.windowController))
                    {
                        if( [[self windowController] FullScreenON] == FALSE)
                        {
                            float heighthalf = drawingFrameRect.size.height/2;
                            float widthhalf = drawingFrameRect.size.width/2;
                            
                            // red square
                            
                            //					glEnable(GL_BLEND);
                            glColor4f (1.0f, 0.0f, 0.0f, 0.8f);
                            glLineWidth(8.0 * sf);
                            glBegin(GL_LINE_LOOP);
                            glVertex2f(  -widthhalf, -heighthalf);
                            glVertex2f(  -widthhalf, heighthalf);
                            glVertex2f(  widthhalf, heighthalf);
                            glVertex2f(  widthhalf, -heighthalf);
                            glEnd();
                            glLineWidth(1.0 * sf);
                            //					glDisable(GL_BLEND);
                        }
                    }
                }  //drawLines for ImageView Frames
                
                // Draw a dot line if the raw data overflows the displayed view
                if( OVERFLOWLINES && is2DViewer && stringID == nil)
                {
                    float heighthalf = drawingFrameRect.size.height/2;
                    float widthhalf = drawingFrameRect.size.width/2;
                    float offset = 4 * sf;
                    
                    NSRect dstRect = [curDCM usefulRectWithRotation: rotation scale: scaleValue xFlipped: xFlipped yFlipped: yFlipped];
                    NSPoint oo = [DCMPix rotatePoint: [self origin] aroundPoint:NSMakePoint( 0, 0) angle: -rotation*deg2rad];
                    dstRect.origin = NSMakePoint( drawingFrameRect.size.width/2 + oo.x - dstRect.size.width/2, drawingFrameRect.size.height/2 - oo.y - dstRect.size.height/2);
                    
                    glColor4f (0, 1, 0.0f, 0.8f);
                    glLineWidth( 3.0 * sf);
                    
                    glPushAttrib( GL_ENABLE_BIT);
                    glLineStipple( 4 * sf, 0xAAAA);
                    glEnable(GL_LINE_STIPPLE);
                    
                    // Left
                    if( dstRect.origin.x <= -5)
                    {
                        glBegin(GL_LINES);
                        glVertex2f( -widthhalf +offset, dstRect.origin.y -heighthalf);
                        glVertex2f( -widthhalf +offset, dstRect.origin.y +dstRect.size.height -heighthalf);
                        glEnd();
                    }
                    
                    // Top
                    if( dstRect.origin.y <= -5)
                    {
                        glBegin(GL_LINES);
                        glVertex2f( dstRect.origin.x -widthhalf, -heighthalf +offset);
                        glVertex2f( dstRect.origin.x +dstRect.size.width -widthhalf, -heighthalf +offset);
                        glEnd();
                    }
                    
                    // Right
                    if( dstRect.origin.x + dstRect.size.width >= drawingFrameRect.size.width+5)
                    {
                        glBegin(GL_LINES);
                        glVertex2f( widthhalf -offset, dstRect.origin.y -heighthalf);
                        glVertex2f( widthhalf -offset, dstRect.origin.y +dstRect.size.height -heighthalf);
                        glEnd();
                    }
                    
                    // Bottom
                    if( dstRect.origin.y + dstRect.size.height >= drawingFrameRect.size.height+5)
                    {
                        glBegin(GL_LINES);
                        glVertex2f( dstRect.origin.x -widthhalf, heighthalf -offset);
                        glVertex2f( dstRect.origin.x +dstRect.size.width -widthhalf, heighthalf -offset);
                        glEnd();
                    }
                    
                    glLineWidth(1.0 * sf);
                    glPopAttrib();
                }
                
                if ((_imageColumns > 1 || _imageRows > 1) && is2DViewer == YES && stringID == nil )
                {
                    float heighthalf = drawingFrameRect.size.height/2 - 1;
                    float widthhalf = drawingFrameRect.size.width/2 - 1;
                    
                    glColor3f (0.5f, 0.5f, 0.5f);
                    glLineWidth(1.0 * sf);
                    glBegin(GL_LINE_LOOP);
                    glVertex2f(  -widthhalf, -heighthalf);
                    glVertex2f(  -widthhalf, heighthalf);
                    glVertex2f(  widthhalf, heighthalf);
                    glVertex2f(  widthhalf, -heighthalf);
                    glEnd();
                    glLineWidth(1.0 * sf);
                    
                    // KEY VIEW - RED BOX
                    
                    if( isKeyView && (frontMost || [ViewerController frontMostDisplayed2DViewerForScreen: self.window.screen] == self.windowController))
                    {
                        float heighthalf = drawingFrameRect.size.height/2 - 1;
                        float widthhalf = drawingFrameRect.size.width/2 - 1;
                        
                        glColor3f (1.0f, 0.0f, 0.0f);
                        glLineWidth(2.0 * sf);
                        glBegin(GL_LINE_LOOP);
                        glVertex2f(  -widthhalf, -heighthalf);
                        glVertex2f(  -widthhalf, heighthalf);
                        glVertex2f(  widthhalf, heighthalf);
                        glVertex2f(  widthhalf, -heighthalf);
                        glEnd();
                        glLineWidth(1.0 * sf);
                    }
                }
                
                glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
                glTranslatef( origin.x, -origin.y, 0.0f);
                glScalef( 1.f, curDCM.pixelRatio, 1.f);
                
                // Draw ROIs
                BOOL drawROI = NO;
                
                if( is2DViewer == YES) drawROI = [[[self windowController] roiLock] tryLock];
                else drawROI = YES;
                
                if( drawROI )
                {
                    BOOL resetData = NO;
                    if(_imageColumns > 1 || _imageRows > 1) resetData = YES;	//For alias ROIs
                    
                    NSSortDescriptor * roiSorting = [[[NSSortDescriptor alloc] initWithKey:@"uniqueID" ascending:NO] autorelease];
                    
                    rectArray = [[NSMutableArray alloc] initWithCapacity: [curRoiList count]];
                    
                    for( int i = (long)[curRoiList count]-1; i >= 0; i--)
                    {
                        ROI *r = [[curRoiList objectAtIndex:i] retain];	// If we are not in the main thread (iChat), we want to be sure to keep our ROIs
                        
                        if( resetData) [r recompute];
                        [r setCurView:self];
                        [r drawROI: scaleValue : curDCM.pwidth / 2. : curDCM.pheight / 2. : curDCM.pixelSpacingX : curDCM.pixelSpacingY];
                        
                        [r release];
                    }
                    
                    // let the pluginSDK draw anything it needs to draw, we use a notification for now, but that is nasty style, we really should be calling a method
#ifndef OSIRIX_LIGHT
                    [[OSIEnvironment sharedEnvironment] drawDCMView:self];
#endif
                    
                    if ( !suppress_labels)
                    {
                        NSArray	*sortedROIs = [curRoiList sortedArrayUsingDescriptors: [NSArray arrayWithObject: roiSorting]];
                        
                        BOOL drawingRoiMode = NO;
                        for( ROI *r in sortedROIs)
                        {
                            if( r.ROImode == ROI_drawing)
                                drawingRoiMode = YES;
                        }
                        
                        if( drawingRoiMode == NO)
                        {
                            for( int i = (long)[sortedROIs count]-1; i>=0; i--)
                            {
                                ROI *r = [[sortedROIs objectAtIndex:i] retain];
                                
                                @try
                                {
                                    [r drawTextualData];
                                }
                                @catch (NSException * e)
                                {
                                    NSLog( @"drawTextualData ROI Exception : %@", e);
                                }
                                
                                [r release];
                            }
                        }
                    }
                    
                    [rectArray release];
                    rectArray = nil;
                }
                
                if( drawROI && is2DViewer == YES) [[[self windowController] roiLock] unlock];
                
                // Draw 2D point cross (used when double-click in 3D panel)
                // BLUE CROSS
                if( is2DViewer)
                {
                    [self draw2DPointMarker];
                    if( blendingView) [blendingView draw2DPointMarker];
                }
                // Draw any Plugin objects
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithFloat: scaleValue], @"scaleValue",
                                          [NSNumber numberWithFloat: curDCM.pwidth /2. ], @"offsetx",
                                          [NSNumber numberWithFloat: curDCM.pheight /2.], @"offsety",
                                          [NSNumber numberWithFloat: curDCM.pixelSpacingX], @"spacingX",
                                          [NSNumber numberWithFloat: curDCM.pixelSpacingY], @"spacingY",
                                          nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDrawObjectsNotification object: self userInfo: userInfo];
                
                [self subDrawRect: aRect];
                self.scaleValue = scaleValue;
                
                //** SLICE CUT BETWEEN SERIES - CROSS REFERENCES LINES
                
                if( is2DViewer && (stringID == nil || [stringID isEqualToString:@"export"]) && frontMost == NO)
                {
                    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
                    glEnable(GL_BLEND);
                    glEnable(GL_POINT_SMOOTH);
                    glEnable(GL_LINE_SMOOTH);
                    glEnable(GL_POLYGON_SMOOTH);
                    
                    if( DISPLAYCROSSREFERENCELINES)
                    {
                        //						NSUInteger modifiers = [NSEvent modifierFlags];
                        //						if( (modifiers & NSControlKeyMask) && (modifiers & NSAlternateKeyMask) && (modifiers & NSCommandKeyMask)) // Display all references lines for all images
                        //						{
                        //							for( DCMPix *o in [[ViewerController frontMostDisplayed2DViewer] pixList])
                        //							{
                        //								[self computeSlice: o :curDCM];
                        //
                        //								if( sliceFromTo[ 0][ 0] != HUGE_VALF)
                        //								{
                        //									glColor3f (0.0f, 0.6f, 0.0f);
                        //									glLineWidth(2.0 * sf);
                        //									[self drawCrossLines: sliceFromTo ctx: cgl_ctx perpendicular: YES];
                        //
                        //									if( sliceFromTo2[ 0][ 0] != HUGE_VALF)
                        //									{
                        //										glLineWidth(2.0 * sf);
                        //										[self drawCrossLines: sliceFromTo2 ctx: cgl_ctx perpendicular: YES];
                        //									}
                        //								}
                        //							}
                        //						}
                        //						else
                        {
                            if( sliceFromTo[ 0][ 0] != HUGE_VALF)
                            {
                                if( sliceFromToS[ 0][ 0] != HUGE_VALF)
                                {
                                    glColor3f (1.0f, 0.6f, 0.0f);
                                    
                                    glLineWidth(2.0 * sf);
                                    [self drawCrossLines: sliceFromToS ctx: cgl_ctx perpendicular: NO];
                                    
                                    glLineWidth(2.0 * sf);
                                    [self drawCrossLines: sliceFromToE ctx: cgl_ctx perpendicular: NO];
                                }
                                
                                glColor3f (0.0f, 0.6f, 0.0f);
                                glLineWidth(2.0 * sf);
                                [self drawCrossLines: sliceFromTo ctx: cgl_ctx perpendicular: YES];
                                
                                if( sliceFromTo2[ 0][ 0] != HUGE_VALF)
                                {
                                    glLineWidth(2.0 * sf);
                                    [self drawCrossLines: sliceFromTo2 ctx: cgl_ctx perpendicular: YES];
                                }
                            }
                        }
                    }
                    
                    if( slicePoint3D[ 0] != HUGE_VALF)
                    {
                        float tempPoint3D[ 2];
                        
                        glLineWidth(2.0 * sf);
                        
                        tempPoint3D[0] = slicePoint3D[ 0] / curDCM.pixelSpacingX;
                        tempPoint3D[1] = slicePoint3D[ 1] / curDCM.pixelSpacingY;
                        
                        tempPoint3D[0] -= curDCM.pwidth * 0.5f;
                        tempPoint3D[1] -= curDCM.pheight * 0.5f;
                        
                        glColor3f (0.0f, 0.6f, 0.0f);
                        glLineWidth(2.0 * sf);
                        
                        if( sliceFromTo[ 0][ 0] != HUGE_VALF && (sliceVector[ 0] != 0 || sliceVector[ 1] != 0  || sliceVector[ 2] != 0))
                        {
                            float a[ 2];
                            // perpendicular vector
                            
                            a[ 1] = sliceFromTo[ 0][ 0] - sliceFromTo[ 1][ 0];
                            a[ 0] = sliceFromTo[ 0][ 1] - sliceFromTo[ 1][ 1];
                            
                            // normalize
                            double t = a[ 1]*a[ 1] + a[ 0]*a[ 0];
                            t = sqrt(t);
                            a[0] = a[0]/t;
                            a[1] = a[1]/t;
                            
#define LINELENGTH 15
                            
                            glBegin(GL_LINES);
                            glVertex2f( scaleValue*(tempPoint3D[ 0]-LINELENGTH/curDCM.pixelSpacingX * a[ 0]), scaleValue*(tempPoint3D[ 1]+LINELENGTH/curDCM.pixelSpacingY*(a[ 1])));
                            glVertex2f( scaleValue*(tempPoint3D[ 0]+LINELENGTH/curDCM.pixelSpacingX * a[ 0]), scaleValue*(tempPoint3D[ 1]-LINELENGTH/curDCM.pixelSpacingY*(a[ 1])));
                            glEnd();
                        }
                        else
                        {
                            glBegin(GL_LINES);
                            
                            float crossx = tempPoint3D[0], crossy = tempPoint3D[1];
                            
                            glVertex2f( scaleValue * (crossx - LINELENGTH/curDCM.pixelSpacingX), scaleValue*(crossy));
                            glVertex2f( scaleValue * (crossx - 5/curDCM.pixelSpacingX), scaleValue*(crossy));
                            glVertex2f( scaleValue * (crossx + LINELENGTH/curDCM.pixelSpacingX), scaleValue*(crossy));
                            glVertex2f( scaleValue * (crossx + 5/curDCM.pixelSpacingX), scaleValue*(crossy));
                            
                            glVertex2f( scaleValue * (crossx), scaleValue*(crossy-LINELENGTH/curDCM.pixelSpacingX));
                            glVertex2f( scaleValue * (crossx), scaleValue*(crossy-5/curDCM.pixelSpacingX));
                            glVertex2f( scaleValue * (crossx), scaleValue*(crossy+5/curDCM.pixelSpacingX));
                            glVertex2f( scaleValue * (crossx), scaleValue*(crossy+LINELENGTH/curDCM.pixelSpacingX));
                            
                            glEnd();
                        }
                        glLineWidth(1.0 * sf);
                    }
                    
                    glDisable(GL_LINE_SMOOTH);
                    glDisable(GL_POLYGON_SMOOTH);
                    glDisable(GL_POINT_SMOOTH);
                    glDisable(GL_BLEND);
                }
                
                glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
                glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
                
                glColor3f (0.0f, 1.0f, 0.0f);
                
                if( annotations >= annotBase)
                {
                    //** PIXELSPACING LINES - RULER
                    float yOffset = 24*sf;
                    float xOffset = 32*sf;
                    glLineWidth( 1.0 * sf);
                    glBegin(GL_LINES);
                    
                    NSRect rr = drawingFrameRect;
                    
                    if( NSIsEmptyRect( screenCaptureRect) == NO)
                    {
                        rr = screenCaptureRect;
                        
                        // We didn't used glTranslate, after glScalef...
                        rr.origin.x -= drawingFrameRect.size.width/2.;
                        rr.origin.y -= drawingFrameRect.size.height/2.;
                        
                        rr.origin.x += rr.size.width/2.;
                        rr.origin.y += rr.size.height/2.;
                    }
                    else
                        rr.origin = NSMakePoint( 0, 0);
                    
                    if( curDCM.pixelSpacingX != 0 && curDCM.pixelSpacingX * 1000.0 < 1)
                    {
                        glVertex2f( rr.origin.x + scaleValue  * (-0.02/curDCM.pixelSpacingX), rr.origin.y + rr.size.height/2 - yOffset);
                        glVertex2f( rr.origin.x + scaleValue  * (0.02/curDCM.pixelSpacingX), rr.origin.y + rr.size.height/2 - yOffset);
                        
                        glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset , rr.origin.y + scaleValue  * (-0.02/curDCM.pixelSpacingY*curDCM.pixelRatio));
                        glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset , rr.origin.y + scaleValue  * (0.02/curDCM.pixelSpacingY*curDCM.pixelRatio));
                        
                        for ( short i = -20; i<=20; i++ )
                        {
                            short length = ( i % 10 == 0 )? 10 : 5;
                            
                            length *= sf;
                            
                            glVertex2f( rr.origin.x + i*scaleValue *0.001/curDCM.pixelSpacingX, rr.origin.y + rr.size.height/2 - yOffset);
                            glVertex2f( rr.origin.x + i*scaleValue *0.001/curDCM.pixelSpacingX, rr.origin.y + rr.size.height/2 - yOffset - length);
                            
                            glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset + length, rr.origin.y + i* scaleValue *0.001/curDCM.pixelSpacingY*curDCM.pixelRatio);
                            glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset, rr.origin.y + i* scaleValue * 0.001/curDCM.pixelSpacingY*curDCM.pixelRatio);
                        }
                    }
                    else if( curDCM.pixelSpacingX != 0 && curDCM.pixelSpacingY != 0)
                    {
                        glVertex2f( rr.origin.x + scaleValue  * (-50/curDCM.pixelSpacingX), rr.origin.y + rr.size.height/2 - yOffset);
                        glVertex2f( rr.origin.x + scaleValue  * (50/curDCM.pixelSpacingX), rr.origin.y + rr.size.height/2 - yOffset);
                        
                        glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset , rr.origin.y + scaleValue  * (-50/curDCM.pixelSpacingY*curDCM.pixelRatio));
                        glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset , rr.origin.y + scaleValue  * (50/curDCM.pixelSpacingY*curDCM.pixelRatio));
                        
                        for ( short i = -5; i<=5; i++ )
                        {
                            short length = (i % 5 == 0) ? 10 : 5;
                            
                            length *= sf;
                            
                            glVertex2f( rr.origin.x + i*scaleValue *10/curDCM.pixelSpacingX, rr.origin.y + rr.size.height/2 - yOffset);
                            glVertex2f( rr.origin.x + i*scaleValue *10/curDCM.pixelSpacingX, rr.origin.y + rr.size.height/2 - yOffset - length);
                            
                            glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset + length,  rr.origin.y + i* scaleValue *10/curDCM.pixelSpacingY*curDCM.pixelRatio);
                            glVertex2f( rr.origin.x + -rr.size.width/2 + xOffset,  rr.origin.y + i* scaleValue * 10/curDCM.pixelSpacingY*curDCM.pixelRatio);
                        }
                    }
                    glEnd();
                }
                
            } //Annotation  != None
            
            @try
            {
                [self drawTextualData: drawingFrameRect :annotations];
            }
            
            @catch (NSException * e)
            {
                NSLog( @"drawTextualData Annotations Exception : %@", e);
            }
            
            if(repulsorRadius != 0)
            {
                glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
                glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
                glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
                
                [self drawRepulsorToolArea];
            }
            
            if(ROISelectorStartPoint.x!=ROISelectorEndPoint.x || ROISelectorStartPoint.y!=ROISelectorEndPoint.y)
            {
                glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
                glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
                glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
                
                [self drawROISelectorRegion];
            }
            
            //			if(ctx == _alternateContext && [[NSApplication sharedApplication] isActive]) // iChat Theatre context
            //			{
            //				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
            //				glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
            //				glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
            //
            //				NSPoint eventLocation = [[self window] convertScreenToBase: [NSEvent mouseLocation]];
            //
            //				// location of the mouse in the OsiriX View
            //				eventLocation = [self convertPoint:eventLocation fromView:nil];
            //				eventLocation.y = [self frame].size.height - eventLocation.y;
            //
            //				// generate iChat cursor Texture Buffer (only once)
            //				if(!iChatCursorTextureBuffer)
            //				{
            //					NSLog(@"generate iChatCursor Texture Buffer");
            //					NSImage *iChatCursorImage;
            //					if ((iChatCursorImage = [[NSCursor pointingHandCursor] image]))
            //					{
            //						iChatCursorHotSpot = [[NSCursor pointingHandCursor] hotSpot];
            //						iChatCursorImageSize = [iChatCursorImage size];
            //
            //						NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[iChatCursorImage TIFFRepresentation]]; // [NSBitmapImageRep imageRepWithData: [iChatCursorImage TIFFRepresentation]]
            //
            //						iChatCursorTextureBuffer = malloc([bitmap bytesPerRow] * iChatCursorImageSize.height);
            //						memcpy(iChatCursorTextureBuffer, [bitmap bitmapData], [bitmap bytesPerRow] * iChatCursorImageSize.height);
            //
            //						[bitmap release];
            //
            //						iChatCursorTextureName = 0;
            //						glGenTextures(1, &iChatCursorTextureName);
            //						glBindTexture(GL_TEXTURE_RECTANGLE_EXT, iChatCursorTextureName);
            //						glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/4);
            //						glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
            //						glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
            //
            //						glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, iChatCursorImageSize.width, iChatCursorImageSize.height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, iChatCursorTextureBuffer);
            //					}
            //				}
            //
            //				// draw the cursor in the iChat Theatre View
            //				if(iChatCursorTextureBuffer)
            //				{
            //					eventLocation.x -= iChatCursorHotSpot.x;
            //					eventLocation.y -= iChatCursorHotSpot.y;
            //
            //					glEnable(GL_TEXTURE_RECTANGLE_EXT);
            //
            //					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, iChatCursorTextureName);
            //					glBlendEquation(GL_FUNC_ADD);
            //					glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            //					glEnable(GL_BLEND);
            //
            //					glColor4f(1.0, 1.0, 1.0, 1.0);
            //					glBegin(GL_QUAD_STRIP);
            //						glTexCoord2f(0, 0);
            //						glVertex2f(eventLocation.x, eventLocation.y);
            //
            //						glTexCoord2f(iChatCursorImageSize.width, 0);
            //						glVertex2f(eventLocation.x + iChatCursorImageSize.width, eventLocation.y);
            //
            //						glTexCoord2f(0, iChatCursorImageSize.height);
            //						glVertex2f(eventLocation.x, eventLocation.y + iChatCursorImageSize.height);
            //
            //						glTexCoord2f(iChatCursorImageSize.width, iChatCursorImageSize.height);
            //						glVertex2f(eventLocation.x + iChatCursorImageSize.width, eventLocation.y + iChatCursorImageSize.height);
            //
            //						glEnd();
            //					glDisable(GL_BLEND);
            //
            //					glDisable(GL_TEXTURE_RECTANGLE_EXT);
            //				}
            //			} // end iChat Theatre context
            
            if( showDescriptionInLarge)
            {
                glMatrixMode (GL_PROJECTION);
                glPushMatrix();
                glLoadIdentity ();
                glMatrixMode (GL_MODELVIEW);
                glPushMatrix();
                glLoadIdentity ();
                glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f);
                glTranslatef (-drawingFrameRect.size.width / 2.0f, -drawingFrameRect.size.height / 2.0f, 0.0f);
                
                glColor4f( 1.0, 1.0, 1.0, 1.0);
                
                NSRect r = NSMakeRect( drawingFrameRect.size.width/2 - [self convertSizeToBacking: [showDescriptionInLargeText frameSize]].width/2, drawingFrameRect.size.height/2 - [self convertSizeToBacking: [showDescriptionInLargeText frameSize]].height/2, [self convertSizeToBacking: [showDescriptionInLargeText frameSize]].width, [self convertSizeToBacking: [showDescriptionInLargeText frameSize]].height);
                
                [showDescriptionInLargeText drawWithBounds: r];
                
                glPopMatrix(); // GL_MODELVIEW
                glMatrixMode (GL_PROJECTION);
                glPopMatrix();
            }
        }
        else
        {
            //no valid image  ie curImage = -1
            //NSLog(@"****** No Image");
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear (GL_COLOR_BUFFER_BIT);
        }
        
#ifndef new_loupe
        if( lensTexture)
        {
            /* creating Loupe textures (mask and border) */
            
            NSBundle *bundle = [NSBundle bundleForClass:[DCMView class]];
            if(!loupeImage)
            {
                loupeImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"loupe.png"]];
                loupeTextureWidth = [loupeImage size].width;
                loupeTextureHeight = [loupeImage size].height;
            }
            if(!loupeMaskImage)
            {
                loupeMaskImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"loupeMask.png"]];
                loupeMaskTextureWidth = [loupeMaskImage size].width;
                loupeMaskTextureHeight = [loupeMaskImage size].height;
            }
            
            if(loupeTextureID==0)
                [self makeTextureFromImage:loupeImage forTexture:&loupeTextureID buffer:loupeTextureBuffer textureUnit:GL_TEXTURE3];
            
            if(loupeMaskTextureID==0)
                [self makeTextureFromImage:loupeMaskImage forTexture:&loupeMaskTextureID buffer:loupeMaskTextureBuffer textureUnit:GL_TEXTURE0];
            
            /* mouse position */
            
            NSRect mlr = {[NSEvent mouseLocation], NSZeroSize};
            NSPoint eventLocation = [[self window] convertRectFromScreen:mlr].origin;
            eventLocation = [self convertPointToBacking: [self convertPoint:eventLocation fromView:nil]];
            
            if( xFlipped)
            {
                eventLocation.x = drawingFrameRect.size.width - eventLocation.x;
            }
            
            if( yFlipped)
            {
                eventLocation.y = drawingFrameRect.size.height - eventLocation.y;
            }
            
            eventLocation.y = drawingFrameRect.size.height - eventLocation.y;
            eventLocation.y -= drawingFrameRect.size.height/2;
            eventLocation.x -= drawingFrameRect.size.width/2;
            
            float xx = eventLocation.x*cos(rotation*deg2rad) + eventLocation.y*sin(rotation*deg2rad);
            float yy = -eventLocation.x*sin(rotation*deg2rad) + eventLocation.y*cos(rotation*deg2rad);
            
            eventLocation.x = xx;
            eventLocation.y = yy;
            
            eventLocation.x -= LENSSIZE*2*scaleValue/LENSRATIO;
            eventLocation.y -= LENSSIZE*2*scaleValue/LENSRATIO;
            
            glMatrixMode (GL_MODELVIEW);
            glLoadIdentity ();
            
            glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
            glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
            
            /* binding lensTexture */
            
            GLuint textID;
            
            glEnable(TEXTRECTMODE);
            glPixelStorei(GL_UNPACK_ROW_LENGTH, LENSSIZE);
            glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
            glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
            
            glGenTextures(1, &textID);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(TEXTRECTMODE, textID);
            
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
            
            glColor4f( 1, 1, 1, 1);
#if __BIG_ENDIAN__
            glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, LENSSIZE, LENSSIZE, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, lensTexture);
#else
            glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, LENSSIZE, LENSSIZE, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, lensTexture);
#endif
            
            glEnable(GL_BLEND);
            glBlendEquation(GL_FUNC_ADD);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            /* multitexturing starts */
            
            glPushAttrib( GL_TEXTURE_BIT);
            
            glActiveTexture(GL_TEXTURE0);
            glEnable(loupeMaskTextureID);
            glBindTexture(TEXTRECTMODE, loupeMaskTextureID);
            glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
            glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
            glTexEnvf(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_TEXTURE0);
            glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
            
            glActiveTexture(GL_TEXTURE1);
            glEnable(textID);
            glBindTexture(TEXTRECTMODE, textID);
            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
            glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);
            glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_TEXTURE1);
            glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
            glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
            glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
            glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
            
            glActiveTexture(GL_TEXTURE0);
            glEnable(TEXTRECTMODE);
            glActiveTexture(GL_TEXTURE1);
            glEnable(TEXTRECTMODE);
            
            glBegin (GL_QUAD_STRIP);
            glMultiTexCoord2f (GL_TEXTURE1, 0, 0); // lensTexture : upper left in texture coordinates
            glMultiTexCoord2f (GL_TEXTURE0, 0, 0); // mask texture : upper left in texture coordinates
            glVertex3d (eventLocation.x, eventLocation.y, 0.0);
            
            glMultiTexCoord2f (GL_TEXTURE1, LENSSIZE, 0); // lensTexture : lower left in texture coordinates
            glMultiTexCoord2f (GL_TEXTURE0, loupeMaskTextureWidth, 0); // mask texture : lower left in texture coordinates
            glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y, 0.0);
            
            glMultiTexCoord2f (GL_TEXTURE1, 0, LENSSIZE); // lensTexture : upper right in texture coordinates
            glMultiTexCoord2f (GL_TEXTURE0, 0, loupeMaskTextureHeight); // mask texture : upper right in texture coordinates
            glVertex3d (eventLocation.x, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
            
            glMultiTexCoord2f (GL_TEXTURE1, LENSSIZE, LENSSIZE); // lensTexture : lower right in texture coordinates
            glMultiTexCoord2f (GL_TEXTURE0, loupeMaskTextureWidth, loupeMaskTextureHeight); // mask texture : lower right in texture coordinates
            glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
            glEnd();
            
            glActiveTexture(GL_TEXTURE1); // deactivate multitexturing
            glDisable(TEXTRECTMODE);
            glDeleteTextures( 1, &textID);
            
            /* multitexturing ends */
            
            // back to single texturing mode:
            glActiveTexture(GL_TEXTURE0); // activate single texture unit
            glDisable(TEXTRECTMODE);
            
            /* drawing loupe border */
            BOOL drawLoupeBorder = YES;
            if(loupeTextureID && drawLoupeBorder)
            {
                glEnable(GL_TEXTURE_RECTANGLE_EXT);
                
                glBindTexture(GL_TEXTURE_RECTANGLE_EXT, loupeTextureID);
                
                glColor4f(1.0, 1.0, 1.0, 1.0);
                
                glBegin(GL_QUAD_STRIP);
                glTexCoord2f(0, 0);
                glVertex3d (eventLocation.x, eventLocation.y, 0.0);
                glTexCoord2f(loupeTextureWidth, 0);
                glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y, 0.0);
                glTexCoord2f(0, loupeTextureHeight);
                glVertex3d (eventLocation.x, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
                glTexCoord2f(loupeTextureWidth, loupeTextureHeight);
                glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
                glEnd();
                
                glDisable(GL_TEXTURE_RECTANGLE_EXT);
            }
            
            glDisable(GL_BLEND);
            
            glPopAttrib();
            
            
            //		glColor4f ( 0, 0, 0 , 0.8);
            //		glLineWidth( 3 * sf);
            //
            //		int resol = LENSSIZE*4*scaleValue;
            //
            //		eventLocation.x += (0.5+LENSSIZE)*2*scaleValue/LENSRATIO;
            //		eventLocation.y += (0.5+LENSSIZE)*2*scaleValue/LENSRATIO;
            //
            //		glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
            //		glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
            //		glEnable(GL_POINT_SMOOTH);
            //		glEnable(GL_LINE_SMOOTH);
            //		glEnable(GL_POLYGON_SMOOTH);
            //
            //		float f = ((LENSSIZE-1)*scaleValue*2/LENSRATIO);
            //
            //		glBegin(GL_LINE_LOOP);
            //		for( int i = 0; i < resol ; i++ )
            //		{
            //			float angle = i * 2 * M_PI /resol;
            //			glVertex2f( eventLocation.x + f *cos(angle), eventLocation.y + f *sin(angle));
            //		}
            //		glEnd();
            //		glPointSize( 3 * sf);
            //		glBegin( GL_POINTS);
            //		for( int i = 0; i < resol ; i++ )
            //		{
            //			float angle = i * 2 * M_PI /resol;
            //
            //			glVertex2f( eventLocation.x + f *cos(angle), eventLocation.y + f *sin(angle));
            //		}
            //		glEnd();
            //		glDisable(GL_LINE_SMOOTH);
            //		glDisable(GL_POLYGON_SMOOTH);
            //		glDisable(GL_POINT_SMOOTH);
            
            
        }
#endif
        
        [self drawRectAnyway:aRect];
        
        if( gInvertColors && [stringID isEqualToString: @"export"] == NO)
        {
            glMatrixMode (GL_MODELVIEW);
            glLoadIdentity ();
            glBlendFunc(GL_ONE_MINUS_DST_COLOR, GL_ZERO);
            glColor4f( 1.0f, 1.0f, 1.0f, 1.0f );
            glEnable(GL_BLEND);
            glRectf( -1.0f, -1.0f, 1.0f, 1.0f );
            glDisable(GL_BLEND);
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    // Swap buffer to screen
    [ctx flushBuffer];
    
    //	[NSOpenGLContext clearCurrentContext];
    
    drawingFrameRect = [self convertRectToBacking: [self frame]];
    
    //	if( ctx == _alternateContext)
    //		drawingFrameRect = savedDrawingFrameRect;
    
    //	if(iChatRunning) [drawLock unlock];
    
    (void) [self _checkHasChanged:YES];
    
}

- (void) setFrame:(NSRect)frameRect
{
    [super setFrame: frameRect];
    
    previousViewSize = frameRect.size;
}

- (void) reshape	// scrolled, moved or resized
{
    if( dcmPixList)
    {
        BOOL is2DViewer = [self is2DViewer];
        
        [[self openGLContext] makeCurrentContext];
        
        NSRect rect = [self frame];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AlwaysScaleToFit"] && is2DViewer)
        {
            if( NSEqualSizes( previousViewSize, rect.size) == NO)
            {
                if( is2DViewer)
                    [[self windowController] setUpdateTilingViewsValue: YES];
                
                [self scaleToFit];
                
                if( is2DViewer == YES)
                {
                    if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
                    {
                        ViewerController *v = [self windowController];
                        
                        for( int i = 0 ; i < [v  maxMovieIndex]; i++)
                        {
                            for( DCMPix *pix in [v pixList: i])
                            {
                                if( pix != curDCM)
                                {
                                    [pix.imageObj setValue: nil forKey: @"scale"];
                                    
                                    
                                    NSPoint o = NSMakePoint( 0, 0);
                                    if( pix.shutterEnabled)
                                    {
                                        o.x = ((curDCM.pwidth  * 0.5f ) - ( curDCM.shutterRect.origin.x + ( curDCM.shutterRect.size.width  * 0.5f ))) * scaleValue;
                                        o.y = -((curDCM.pheight * 0.5f ) - ( curDCM.shutterRect.origin.y + ( curDCM.shutterRect.size.height * 0.5f ))) * scaleValue;
                                    }
                                    
                                    [pix.imageObj setValue: [NSNumber numberWithFloat: o.x] forKey:@"xOffset"];
                                    [pix.imageObj setValue: [NSNumber numberWithFloat: o.y] forKey:@"yOffset"];
                                }
                            }
                        }
                    }
                    
                    [[self windowController] setUpdateTilingViewsValue: NO];
                    
                    if( [[self window] isMainWindow])
                        [[self windowController] propagateSettings];
                }
            }
        }
        else
        {
            if( previousViewSize.width != 0 && previousViewSize.height != 0)
            {
                float yChanged = sqrt( (rect.size.height / previousViewSize.height) * (rect.size.width / previousViewSize.width));
                
                if( yChanged > 0.01 && yChanged < 1000) yChanged = yChanged;
                else yChanged = 0.01;
                
                if( is2DViewer)
                {
                    [[self windowController] setUpdateTilingViewsValue: YES];
                    
                    if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
                    {
                        ViewerController *v = [self windowController];
                        
                        if( [[v imageViews] objectAtIndex: 0] == self)
                        {
                            for( int i = 0 ; i < [v  maxMovieIndex]; i++)
                            {
                                for( DCMPix *pix in [v pixList: i])
                                {
                                    if( pix !=  curDCM)
                                    {
                                        float s = [[pix.imageObj valueForKey: @"scale"] floatValue];
                                        
                                        if( s)
                                            [pix.imageObj setValue: [NSNumber numberWithFloat: s * yChanged] forKey: @"scale"];
                                        else
                                            [pix.imageObj setValue: nil forKeyPath: @"scale"];
                                    }
                                }
                            }
                        }
                    }
                }
                
                self.scaleValue = scaleValue * yChanged;
                
                if( is2DViewer)
                    [[self windowController] setUpdateTilingViewsValue: NO];
                
                origin.x *= yChanged;
                origin.y *= yChanged;
                
                if( is2DViewer == YES)
                {
                    if( [[self window] isMainWindow])
                        [[self windowController] propagateSettings];
                }
            }
        }
    }
    
    [super reshape];
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
    return [self getRawPixelsWidth:width height:height spp:spp bpp:bpp screenCapture:screenCapture force8bits:force8bits removeGraphical:YES squarePixels:NO allTiles:[[NSUserDefaults standardUserDefaults] boolForKey:@"includeAllTiledViews"] allowSmartCropping:NO origin: nil spacing: nil];
}

- (unsigned char*) getRawPixelsWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allTiles:(BOOL) allTiles allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing
{
    return [self getRawPixelsWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allTiles:(BOOL) allTiles allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing offset:(int*) nil isSigned:(BOOL*) nil];
}

- (unsigned char*) getRawPixelsWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allTiles:(BOOL) allTiles allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing offset:(int*) offset isSigned:(BOOL*) isSigned
{
    if( allTiles && [self is2DViewer] && (_imageRows != 1 || _imageColumns != 1))
    {
        NSArray		*views = [[[self windowController] seriesView] imageViews];
        
        // Create a large buffer for all views
        // All views are identical
        
        unsigned char	*firstView = [[views objectAtIndex: 0] getRawPixelsViewWidth:width height:height spp:spp bpp:bpp screenCapture:screenCapture force8bits: force8bits removeGraphical:removeGraphical squarePixels:squarePixels allowSmartCropping:NO origin: imOrigin spacing: imSpacing offset: offset isSigned: isSigned];
        unsigned char	*globalView = nil;
        
        long viewSize =  *bpp * *spp * (*width+4) * (*height+4) / 8;
        int	globalWidth = *width * _imageColumns;
        int globalHeight = *height * _imageRows;
        
        if( firstView)
        {
            globalView = malloc( viewSize * (_imageColumns) * (_imageRows));
            
            free( firstView);
            
            if( globalView)
            {
                for( int x = 0; x < _imageColumns; x++ )
                {
                    for( int y = 0; y < _imageRows; y++)
                    {
                        unsigned char	*aView = [[views objectAtIndex: x + y*_imageColumns] getRawPixelsViewWidth:width height:height spp:spp bpp:bpp screenCapture:screenCapture force8bits: force8bits removeGraphical:removeGraphical squarePixels:squarePixels allowSmartCropping:NO origin: imOrigin spacing: imSpacing offset: offset isSigned: isSigned];
                        
                        if( aView)
                        {
                            unsigned char	*o = globalView + *spp*globalWidth*y**height**bpp/8 +  x**width**spp**bpp/8;
                            
                            for( int yy = 0 ; yy < *height; yy++)
                            {
                                memcpy( o + yy**spp*globalWidth**bpp/8, aView + yy**spp**width**bpp/8, *spp**width**bpp/8);
                            }
                            
                            free( aView);
                        }
                    }
                }
                
                *width = globalWidth;
                *height = globalHeight;
            }
        }
        
        return globalView;
    }
    else return [self getRawPixelsViewWidth:width height:height spp:spp bpp:bpp screenCapture:screenCapture force8bits: force8bits removeGraphical:removeGraphical squarePixels:squarePixels allowSmartCropping:allowSmartCropping origin: imOrigin spacing: imSpacing offset: offset isSigned: isSigned];
}

- (unsigned char*) getRawPixelsWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allTiles:(BOOL) allTiles allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing offset:(int*) offset isSigned:(BOOL*) isSigned views: (NSArray*) views viewsRect: (NSArray*) rects
{
    NSMutableArray *viewsRect = [NSMutableArray arrayWithArray: rects];
    
    if( [views count] > 1 && [views count] == [viewsRect count])
    {
        unsigned char	*tempData = nil;
        
        NSRect unionRect = [[viewsRect objectAtIndex: 0] rectValue];
        for( NSValue *rect in viewsRect)
            unionRect = NSUnionRect( [rect rectValue], unionRect);
        
        for( int i = 0; i < [views count]; i++ )
        {
            NSRect curRect = [[viewsRect objectAtIndex: i] rectValue];
            BOOL intersect;
            
            // X move
            do
            {
                intersect = NO;
                
                for( int x = 0 ; x < [views count]; x++)
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
        
        for( int i = 0; i < [views count]; i++)
        {
            NSRect curRect = [[viewsRect objectAtIndex: i] rectValue];
            BOOL intersect;
            
            // Y move
            do {
                intersect = NO;
                
                for( int x = 0 ; x < [views count]; x++)
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
        for( int i = 0; i < [views count]; i++)
        {
            unionRect = NSUnionRect( [[viewsRect objectAtIndex: i] rectValue], unionRect);
        }
        
        *width = unionRect.size.width;
        if( *width % 4 != 0) *width += 4;
        *width /= 4;
        *width *= 4;
        *height = unionRect.size.height;
        
        unsigned char * data = nil;
        long dataSize = 0;
        
        for( int i = 0; i < [views count]; i++)
        {
            long iwidth, iheight, ispp, ibpp;
            float iimSpacing[ 2];
            BOOL iisSigned;
            int ioffset;
            
            tempData = [[views objectAtIndex: i] getRawPixelsWidth: &iwidth
                                                            height: &iheight
                                                               spp: &ispp
                                                               bpp: &ibpp
                                                     screenCapture: screenCapture
                                                        force8bits: force8bits
                                                   removeGraphical: removeGraphical
                                                      squarePixels: squarePixels
                                                          allTiles: allTiles
                                                allowSmartCropping: allowSmartCropping
                                                            origin: nil
                                                           spacing: iimSpacing
                                                            offset: &ioffset
                                                          isSigned: &iisSigned];
            
            if( tempData)
            {
                if( i == 0)
                {
                    if( imSpacing)
                    {
                        imSpacing[ 0] = iimSpacing[ 0];
                        imSpacing[ 1] = iimSpacing[ 1];
                    }
                    
                    if( imOrigin)
                    {
                        imOrigin[ 0] = 0;
                        imOrigin[ 1] = 0;
                        imOrigin[ 2] = 0;
                    }
                    
                    *spp = ispp;
                    *bpp = ibpp;
                    if( offset) *offset = ioffset;
                    if( isSigned) *isSigned = iisSigned;
                    
                    dataSize = (4+*width) * (4+*height) * *spp * *bpp/8;
                    data = calloc( 1, dataSize);
                }
                else
                {
                    if( imSpacing)
                    {
                        if( fabs( imSpacing[ 0] - iimSpacing[ 0]) > 0.005 || fabs( imSpacing[ 1] - iimSpacing[ 1]) > 0.005)
                        {
                            imSpacing[ 0] = 0;
                            imSpacing[ 1] = 0;
                        }
                    }
                }
                
                
                NSRect	bounds = [[viewsRect objectAtIndex: i] rectValue];	//[views bounds];
                
                bounds.origin.x -= unionRect.origin.x;
                bounds.origin.y -= unionRect.origin.y;
                
                if( data)
                {
                    unsigned char *o = data + (*bpp/8) * *spp * *width * (long) (*height - bounds.origin.y - iheight) + (long) bounds.origin.x * *spp * (*bpp/8);
                    
                    if( o >= data)
                    {
                        for( long y = 0 ; y < iheight; y++)
                        {
                            long size = (*bpp/8) * ispp * iwidth;
                            long ooffset = (*bpp/8) * y * *spp * *width;
                            
                            if( o + ooffset + size < data + dataSize)
                                memcpy( o + ooffset, tempData + (*bpp/8) * y *ispp * iwidth, size);
                            else
                                N2LogStackTrace( @"**** o + ooffset + size< data + dataSize");
                        }
                    }
                }
                free( tempData);
            }
        }
        
        return data;
    }
    else
    {
        return [self getRawPixelsWidth: width
                                height: height
                                   spp: spp
                                   bpp: bpp
                         screenCapture: screenCapture
                            force8bits: force8bits
                       removeGraphical: removeGraphical
                          squarePixels: squarePixels
                              allTiles: allTiles
                    allowSmartCropping: allowSmartCropping
                                origin: imOrigin
                               spacing: imSpacing
                                offset: offset
                              isSigned: isSigned];
    }
}

- (NSRect) smartCrop: (NSPoint*) ori
{
    NSPoint oo = [self origin];
    
    NSRect usefulRect = [curDCM usefulRectWithRotation: rotation scale: scaleValue xFlipped: xFlipped yFlipped: yFlipped];
    
    NSSize rectSize = drawingFrameRect.size;
    
    if( xFlipped) oo.x = - oo.x;
    if( yFlipped) oo.y = - oo.y;
    
    oo = [DCMPix rotatePoint: oo aroundPoint:NSMakePoint( 0, 0) angle: -rotation*deg2rad];
    
    NSPoint cov = NSMakePoint( rectSize.width/2 + oo.x - usefulRect.size.width/2, rectSize.height/2 - oo.y - usefulRect.size.height/2);
    
    usefulRect.origin = cov;
    
    NSRect frameRect;
    
    frameRect.size = rectSize;
    frameRect.origin.x = frameRect.origin.y = 0;
    
    if( usefulRect.size.width < 256)
    {
        usefulRect.origin.x -= (int) ((256 - usefulRect.size.width) / 2);
        usefulRect.size.width = 256;
    }
    
    if( usefulRect.size.height < 256)
    {
        usefulRect.origin.y -= (int) ((256 - usefulRect.size.height) / 2);
        usefulRect.size.height = 256;
    }
    
    NSRect smartRect = NSIntersectionRect( frameRect, usefulRect);
    
    if( ori)
    {
        ori->x = ori->y = 0;
        if( NSEqualRects( usefulRect, smartRect) == NO)
        {
            ori->x = (usefulRect.origin.x - smartRect.origin.x) / 2 + (usefulRect.origin.x+usefulRect.size.width - (smartRect.origin.x+smartRect.size.width)) / 2;
            ori->y = - ((usefulRect.origin.y - smartRect.origin.y) / 2 + (usefulRect.origin.y+usefulRect.size.height - (smartRect.origin.y+smartRect.size.height)) / 2);
            
            *ori = [DCMPix rotatePoint: *ori aroundPoint:NSMakePoint( 0, 0) angle: rotation*deg2rad];
        }
    }
    
    smartRect.origin.x = (int) smartRect.origin.x;
    smartRect.origin.y = (int) smartRect.origin.y;
    smartRect.size.width = (int) smartRect.size.width;
    smartRect.size.height = (int) smartRect.size.height;
    
    return smartRect;
}

- (NSRect) smartCrop
{
    return [self smartCrop: nil];
}

-(unsigned char*) getRawPixelsViewWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing
{
    return [self getRawPixelsViewWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing offset:(int*) nil isSigned:(BOOL*) nil];
}

-(unsigned char*) getRawPixelsViewWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing offset:(int*) offset isSigned:(BOOL*) isSigned
{
    unsigned char	*buf = nil;
    
    if( isSigned) *isSigned = NO;
    if( offset) *offset = 0;
    
    if(
#ifndef OSIRIX_LIGHT
       [self class] == [OrthogonalMPRPETCTView class] ||
#endif
       [self class] == [OrthogonalMPRView class]) allowSmartCropping = NO;	// <- MPR 2D, Ortho MPR
    
    if( screenCapture)	// Pixels displayed in current window
    {
        for( ROI *r in curRoiList)	[r setROIMode: ROI_sleep];
        
        if( force8bits == YES || curDCM.isRGB == YES || blendingView != nil)		// Screen Capture in RGB - 8 bit
        {
            NSPoint shiftOrigin;
            BOOL smartCropped = NO;
            NSRect smartCroppedRect;
            
            if( allowSmartCropping && [[NSUserDefaults standardUserDefaults] boolForKey: @"ScreenCaptureSmartCropping"])
            {
                smartCroppedRect = [self smartCrop: &shiftOrigin];
                
                if( smartCroppedRect.size.width == drawingFrameRect.size.width && smartCroppedRect.size.height == drawingFrameRect.size.height)
                    smartCropped = NO;
                else
                {
                    *width = smartCroppedRect.size.width;
                    *height = smartCroppedRect.size.height;
                    smartCropped = YES;
                }
                
                //                if( self.blendingView)
                //                {
                //                    blendedViewRect = [self.blendingView smartCrop: &blendedShiftOrigin];
                //                    NSRect unionRect = NSUnionRect( blendedViewRect, smartCroppedRect);;
                //
                //                    #define NSRectCenterX(r) (r.origin.x+r.size.width/2.)
                //                    #define NSRectCenterY(r) (r.origin.y+r.size.height/2.)
                //
                //                    NSPoint oo = NSMakePoint( NSRectCenterX(smartCroppedRect) - NSRectCenterX(unionRect), NSRectCenterY(smartCroppedRect) - NSRectCenterY(unionRect));
                //
                //                    if( xFlipped) {oo.x = -oo.x; shiftOrigin.x *=-1;}
                //                    if( yFlipped) {oo.y = -oo.y; shiftOrigin.y *=-1;}
                //
                //                    shiftOrigin.x = oo.x*cos((rotation)*deg2rad) + oo.y*sin((rotation)*deg2rad) + shiftOrigin.x;
                //                    shiftOrigin.y = oo.x*sin((rotation)*deg2rad) - oo.y*cos((rotation)*deg2rad) + shiftOrigin.y;
                //
                //                    oo = NSMakePoint( NSRectCenterX(blendedViewRect) - NSRectCenterX(unionRect), NSRectCenterY(blendedViewRect) - NSRectCenterY(unionRect));
                //
                //                    if( blendingView.xFlipped) {oo.x = -oo.x; blendedShiftOrigin.x *= -1.;}
                //                    if( blendingView.yFlipped) {oo.y = -oo.y; blendedShiftOrigin.y *= -1.;}
                //
                //                    blendedShiftOrigin.x = oo.x*cos((blendingView.rotation)*deg2rad) + oo.y*sin((blendingView.rotation)*deg2rad) + blendedShiftOrigin.x;
                //                    blendedShiftOrigin.y = oo.x*sin((blendingView.rotation)*deg2rad) - oo.y*cos((blendingView.rotation)*deg2rad) + blendedShiftOrigin.y;
                //
                //                    smartCroppedRect = unionRect;
                //
                //                    if( smartCroppedRect.size.width == drawingFrameRect.size.width && smartCroppedRect.size.height == drawingFrameRect.size.height)
                //                        smartCropped = NO;
                //                    else
                //                    {
                //                        *width = smartCroppedRect.size.width;
                //                        *height = smartCroppedRect.size.height;
                //                        smartCropped = YES;
                //                    }
                //                }
            }
            else smartCroppedRect = NSMakeRect( 0, 0, drawingFrameRect.size.width, drawingFrameRect.size.height);
            
            if( imOrigin)
            {
                NSPoint tempPt = [self ConvertFromUpLeftView2GL: smartCroppedRect.origin];
                [curDCM convertPixX: tempPt.x pixY: tempPt.y toDICOMCoords: imOrigin pixelCenter: YES];
            }
            
            if( imSpacing)
            {
                imSpacing[ 0] = [curDCM pixelSpacingX] / scaleValue;
                imSpacing[ 1] = [curDCM pixelSpacingX] / scaleValue;
            }
            
            *width = smartCroppedRect.size.width;
            *height = smartCroppedRect.size.height;
            *spp = 3;
            *bpp = 8;
            
            buf = calloc( 1, 10 + *width * *height * 4 * *bpp/8);
            if( buf)
            {
                NSOpenGLContext *c = [self openGLContext];
                
                if( c)
                {
                    [c makeCurrentContext];
                    CGLContextObj cgl_ctx = [c CGLContextObj];
                    
                    NSString *str = nil;
                    
                    if( removeGraphical)
                    {
                        str = [[self stringID] retain];
                        [self setStringID: @"export"];
                    }
                    
                    if( smartCropped)
                        screenCaptureRect = smartCroppedRect;
                    
                    [self display];
                    [self.blendingView display];
                    
                    glReadBuffer(GL_FRONT);
                    
#if __BIG_ENDIAN__
                    glReadPixels( smartCroppedRect.origin.x, drawingFrameRect.size.height-smartCroppedRect.origin.y-smartCroppedRect.size.height, smartCroppedRect.size.width, smartCroppedRect.size.height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, buf);		//GL_ABGR_EXT
                    
                    int ii = *width * *height;
                    unsigned char	*t_argb = buf;
                    unsigned char	*t_rgb = buf;
                    while( ii-->0)
                    {
                        *((int*) t_rgb) = *((int*) t_argb);
                        t_argb+=4;
                        t_rgb+=3;
                    }
#else
                    glReadPixels(  smartCroppedRect.origin.x, drawingFrameRect.size.height-smartCroppedRect.origin.y-smartCroppedRect.size.height, smartCroppedRect.size.width, smartCroppedRect.size.height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, buf);		//GL_ABGR_EXT
                    
                    int ii = *width * *height;
                    unsigned char	*t_argb = buf;
                    unsigned char	*t_rgb = buf;
                    while( ii-->0 ) {
                        *((int*) t_rgb) = *((int*) t_argb);
                        t_argb+=4;
                        t_rgb+=3;
                    }
#endif
                    
                    screenCaptureRect = NSMakeRect(0, 0, 0, 0);
                    
                    if( str)
                    {
                        [self setStringID: str];
                        [str release];
                    }
                    
                    [self setNeedsDisplay: YES];	// for refresh, later
                }
                
                long rowBytes = *width**spp**bpp/8;
                
                unsigned char *tempBuf = malloc( rowBytes);
                
                if( tempBuf)
                {
                    for( long i = 0; i < *height/2; i++ )
                    {
                        memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
                        memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
                        memcpy( buf + i*rowBytes, tempBuf, rowBytes);
                    }
                    
                    free( tempBuf);
                }
            }
        }
        else // Screen Capture in 16 bit BW
        {
            float s = [self scaleValue];
            NSPoint o = [self origin];
            
            NSSize destRectSize = drawingFrameRect.size;
            
            // We want the full resolution, not less, not more
            destRectSize.width /= s;
            destRectSize.height /= s;
            o.x /= s;
            o.y /= s;
            s = 1;
            
            DCMPix *im = [curDCM renderInRectSize: destRectSize atPosition:o rotation: [self rotation] scale: s xFlipped: xFlipped yFlipped: yFlipped smartCrop: YES];
            
            if( im)
            {
                if( imSpacing)
                {
                    imSpacing[ 0] = [im pixelSpacingX];
                    imSpacing[ 1] = [im pixelSpacingX];
                }
                
                if( imOrigin)
                {
                    imOrigin[ 0] = [im originX];
                    imOrigin[ 1] = [im originY];
                    imOrigin[ 2] = [im originZ];
                }
                
                *width = [im pwidth];
                *height = [im pheight];
                *spp = 1;
                *bpp = 16;
                
                vImage_Buffer srcf, dst8;
                
                srcf.height = *height;
                srcf.width = *width;
                srcf.rowBytes = *width * sizeof( float);
                
                dst8.height =  *height;
                dst8.width = *width;
                dst8.rowBytes = *width * sizeof( short);
                
                buf = malloc( *width * *height * *spp * *bpp/8);
                
                srcf.data = [im fImage];
                dst8.data = buf;
                
                float slope = 1;
                
                if( [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"PT"])
                    slope = im.appliedFactorPET2SUV * im.slope;
                
                if( buf)
                {
                    if( [curDCM minValueOfSeries] < -1024)
                    {
                        if( isSigned) *isSigned = YES;
                        if( offset) *offset = 0;
                        
                        vImageConvert_FTo16S( &srcf, &dst8, 0,  slope, 0);
                    }
                    else
                    {
                        if( isSigned) *isSigned = NO;
                        
                        if( [curDCM minValueOfSeries] >= 0)
                        {
                            if( offset) *offset = 0;
                            vImageConvert_FTo16U( &srcf, &dst8, 0,  slope, 0);
                        }
                        else
                        {
                            if( offset) *offset = -1024;
                            vImageConvert_FTo16U( &srcf, &dst8, -1024,  slope, 0);
                        }
                    }
                }
            }
        }
    }
    else // Pixels contained in memory  -> only RGB or 16 bits data
    {
        DCMPix *dcm = curDCM;
        
        if( [self xFlipped] || [self yFlipped] || [self rotation] != 0)
            dcm = [curDCM renderWithRotation: [self rotation] scale: 1.0 xFlipped: [self xFlipped] yFlipped: [self yFlipped] backgroundOffset: 0];
        
        if( dcm)
        {
            if( imOrigin)
            {
                imOrigin[ 0] = [dcm originX];
                imOrigin[ 1] = [dcm originY];
                imOrigin[ 2] = [dcm originZ];
            }
            
            if( imSpacing)
            {
                imSpacing[ 0] = [dcm pixelSpacingX];
                imSpacing[ 1] = [dcm pixelSpacingY];
            }
            
            BOOL isRGB = dcm.isRGB;
            
            *width = dcm.pwidth;
            *height = dcm.pheight;
            
            if( [dcm thickSlabVRActivated])
            {
                force8bits = YES;
                
                if( dcm.stackMode == 4 || dcm.stackMode == 5) isRGB = YES;
            }
            
            if( isRGB == YES)
            {
                [self display];
                
                *spp = 3;
                *bpp = 8;
                
                long i = *width * *height * *spp * *bpp / 8;
                buf = malloc( i );
                if( buf )
                {
                    unsigned char *dst = buf, *src = (unsigned char*) dcm.baseAddr;
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
            //		else if( colorBuf != nil)		// A CLUT is applied
            //		{
            ////			BOOL BWInverse = YES;
            ////
            ////			// Is it inverse BW? We consider an inverse BW as a mono-channel image.
            ////			for( int i = 0; i < 256 && BWInverse == YES; i++)
            ////			{
            ////				if( redTable[i] != 255-i || greenTable[i] != 255 -i || blueTable[i] != 255-i) BWInverse = NO;
            ////			}
            ////
            ////			if( BWInverse == NO)
            ////			{
            //				[self display];
            //
            //				*spp = 3;
            //				*bpp = 8;
            //
            //				long i = *width * *height * *spp * *bpp / 8;
            //				buf = malloc( i );
            //				if( buf)
            //				{
            //					unsigned char *dst = buf, *src = colorBuf;
            //					i = *width * *height;
            //
            //					// CONVERT ARGB TO RGB
            //					while( i-- > 0)
            //					{
            //						src++;
            //						*dst++ = *src++;
            //						*dst++ = *src++;
            //						*dst++ = *src++;
            //					}
            //				}
            ////			}
            ////			else processed = NO;
            //		}
            else
            {
                if( force8bits)	// I don't want 16 bits data, only 8 bits data
                {
                    [self display];
                    
                    *spp = 1;
                    *bpp = 8;
                    
                    long i = *width * *height * *spp * *bpp / 8;
                    buf = malloc( i);
                    if( buf ) memcpy( buf, dcm.baseAddr, *width**height);
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
                    
                    srcf.data = [dcm computefImage];
                    
                    float slope = 1;
                    
                    if( [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"PT"])
                        slope = dcm.appliedFactorPET2SUV * dcm.slope;
                    
                    long i = *width * *height * *spp * *bpp / 8;
                    buf = malloc( i);
                    if( buf)
                    {
                        dst8.data = buf;
                        
                        if( [dcm minValueOfSeries] < -1024)
                        {
                            if( isSigned) *isSigned = YES;
                            if( offset) *offset = 0;
                            
                            vImageConvert_FTo16S( &srcf, &dst8, 0,  slope, 0);
                        }
                        else
                        {
                            if( isSigned) *isSigned = NO;
                            
                            if( [dcm minValueOfSeries] >= 0)
                            {
                                if( offset) *offset = 0;
                                vImageConvert_FTo16U( &srcf, &dst8, 0,  slope, 0);
                            }
                            else
                            {
                                if( offset) *offset = -1024;
                                vImageConvert_FTo16U( &srcf, &dst8, -1024,  slope, 0);
                            }
                        }
                    }
                    
                    if( srcf.data != dcm.fImage ) free( srcf.data );
                }
            }
            
            // IF 8 bits or RGB, IF non-square pixels -> square pixels
            
            if( squarePixels == YES && *bpp == 8 && self.pixelSpacingX != self.pixelSpacingY)
            {
                vImage_Buffer	srcVimage, dstVimage;
                
                srcVimage.data = buf;
                srcVimage.height = *height;
                srcVimage.width = *width;
                srcVimage.rowBytes = *width * (*bpp/8) * *spp;
                
                dstVimage.height =  (int) ((float) *height * self.pixelSpacingY / self.pixelSpacingX);
                dstVimage.width = *width;
                dstVimage.rowBytes = *width * (*bpp/8) * *spp;
                dstVimage.data = malloc( dstVimage.rowBytes * dstVimage.height);
                
                if( *spp == 3)
                {
                    vImage_Buffer	argbsrcVimage, argbdstVimage;
                    
                    argbsrcVimage = srcVimage;
                    argbsrcVimage.rowBytes =  *width * 4;
                    argbsrcVimage.data = calloc( argbsrcVimage.rowBytes * argbsrcVimage.height, 1);
                    
                    argbdstVimage = dstVimage;
                    argbdstVimage.rowBytes =  *width * 4;
                    argbdstVimage.data = calloc( argbdstVimage.rowBytes * argbdstVimage.height, 1);
                    
                    if( dstVimage.data && argbsrcVimage.data && argbdstVimage.data)
                    {
                        vImageConvert_RGB888toARGB8888( &srcVimage, nil, 0, &argbsrcVimage, 0, 0);
                        vImageScale_ARGB8888( &argbsrcVimage, &argbdstVimage, nil, kvImageHighQualityResampling);
                        vImageConvert_ARGB8888toRGB888( &argbdstVimage, &dstVimage, 0);
                        
                        free( argbsrcVimage.data);
                        free( argbdstVimage.data);
                    }
                }
                else
                {
                    if( dstVimage.data)
                        vImageScale_Planar8( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
                }
                
                free( buf);
                
                if( imSpacing)
                    imSpacing[ 1] = imSpacing[ 0];
                
                buf = dstVimage.data;
                *height = dstVimage.height;
            }
        }
    }
    
    return buf;
}

- (NSImage*) exportNSImageCurrentImageWithSize:(int) size
{
    float imOrigin[ 3], imSpacing[ 2];
    long width, height, spp, bpp;
    //	NSRect savedFrame = drawingFrameRect;
    
    unsigned char *data = [self getRawPixelsViewWidth: &width height: &height spp: &spp bpp: &bpp screenCapture: YES force8bits: YES removeGraphical: YES squarePixels: YES allowSmartCropping: NO origin: imOrigin spacing: imSpacing offset: nil isSigned: nil];
    
    if( data)
    {
        if( size)
        {
            if( spp != 3)
                NSLog( @"********* spp != 3 I'll NOT resize");
            else
            {
                unsigned char *cropData;
                int cropHeight, cropWidth;
                //				float rescale = 0;
                //				NSPoint croppedOrigin;
                
                if( width > height)
                {
                    //					rescale = (float) size / (float) height;
                    cropHeight = height;
                    cropWidth = height;
                }
                else
                {
                    //					rescale = (float) size / (float) width;
                    cropHeight = width;
                    cropWidth = width;
                }
                
                //				croppedOrigin = NSMakePoint( ((width-cropWidth)/2.), ((height - cropHeight)/2.));
                
                cropData = data + spp*((width-cropWidth)/2) + spp*((height - cropHeight)/2)*width;
                
                // resize the data
                
                vImage_Buffer src, dest;
                
                src.data = cropData;
                src.rowBytes = width * spp;
                src.height = cropHeight;
                src.width = cropWidth;
                
                dest.data = malloc( size*size*spp);
                dest.rowBytes = size*spp;
                dest.width = dest.height = size;
                
                if( dest.data)
                {
                    vImage_Buffer	argbsrcVimage, argbdstVimage;
                    
                    argbsrcVimage = src;
                    argbsrcVimage.rowBytes =  src.width * 4;
                    argbsrcVimage.data = calloc( argbsrcVimage.rowBytes * argbsrcVimage.height, 1);
                    
                    argbdstVimage = dest;
                    argbdstVimage.rowBytes =  dest.width * 4;
                    argbdstVimage.data = calloc( argbdstVimage.rowBytes * argbdstVimage.height, 1);
                    
                    vImageConvert_RGB888toARGB8888( &src, nil, 0, &argbsrcVimage, 0, 0);
                    vImageScale_ARGB8888( &argbsrcVimage, &argbdstVimage, nil, kvImageHighQualityResampling);
                    vImageConvert_ARGB8888toRGB888( &argbdstVimage, &dest, 0);
                    
                    free( argbsrcVimage.data);
                    free( argbdstVimage.data);
                    
                    free( data);
                    
                    data = dest.data;
                    width = size;
                    height = size;
                }
            }
        }
        
        NSBitmapImageRep *rep;
        
        rep = [[[NSBitmapImageRep alloc]
                initWithBitmapDataPlanes:nil
                pixelsWide:width
                pixelsHigh:height
                bitsPerSample:bpp
                samplesPerPixel:spp
                hasAlpha:NO
                isPlanar:NO
                colorSpaceName:NSCalibratedRGBColorSpace
                bytesPerRow:width*bpp*spp/8
                bitsPerPixel:bpp*spp] autorelease];
        
        memcpy( [rep bitmapData], data, height*width*bpp*spp/8);
        
        NSImage *image = [[[NSImage alloc] init] autorelease];
        [image addRepresentation:rep];
        
        free( data);
        
        return image;
    }
    
    return [NSImage imageNamed: @"Empty.tif"];
}

- (NSDictionary*) exportDCMCurrentImage: (DICOMExport*) exportDCM size:(int) size
{
    return [self exportDCMCurrentImage: exportDCM size: size views: nil viewsRect: nil];
}

- (NSDictionary*) exportDCMCurrentImage: (DICOMExport*) exportDCM size:(int) size  views: (NSArray*) views viewsRect: (NSArray*) viewsRect
{
    return [self exportDCMCurrentImage: exportDCM size: size views: views viewsRect: viewsRect exportSpacingAndOrigin: YES];
}

- (NSDictionary*) exportDCMCurrentImage: (DICOMExport*) exportDCM size:(int) size  views: (NSArray*) views viewsRect: (NSArray*) viewsRect exportSpacingAndOrigin: (BOOL) exportSpacingAndOrigin
{
    NSString *f = nil;
    float o[ 9], imOrigin[ 3], imSpacing[ 2];
    long width, height, spp, bpp;
    
    long annotCopy = [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
    long clutBarsCopy = [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"keepCLUTBarsForSecondaryCapture"])
        [DCMView setCLUTBARS: clutBarsCopy ANNOTATIONS: annotGraphics];
    else
        [DCMView setCLUTBARS: barHide ANNOTATIONS: annotGraphics];
    
    unsigned char *data = nil;
    
    if( [views count] > 1 && [views count] == [viewsRect count])
    {
        data = [self getRawPixelsWidth: &width
                                height: &height
                                   spp: &spp
                                   bpp: &bpp
                         screenCapture: YES
                            force8bits: YES
                       removeGraphical: YES
                          squarePixels: YES
                              allTiles: NO
                    allowSmartCropping: NO
                                origin: imOrigin
                               spacing: imSpacing
                                offset: nil
                              isSigned: nil
                                 views: views
                             viewsRect: viewsRect];
    }
    else
    {
        data = [self getRawPixelsViewWidth: &width
                                    height: &height
                                       spp: &spp
                                       bpp: &bpp
                             screenCapture: YES
                                force8bits: YES
                           removeGraphical: YES
                              squarePixels: YES
                        allowSmartCropping: NO
                                    origin: imOrigin
                                   spacing: imSpacing
                                    offset: nil
                                  isSigned: nil];
    }
    
    if( data)
    {
        if( size)
        {
            if( spp != 3)
                NSLog( @"********* spp != 3 I'll NOT resize");
            else
            {
                unsigned char *cropData;
                int cropHeight, cropWidth;
                float rescale = 0;
                NSPoint croppedOrigin;
                
                if( width > height)
                {
                    rescale = (float) size / (float) height;
                    cropHeight = height;
                    cropWidth = height;
                }
                else
                {
                    rescale = (float) size / (float) width;
                    cropHeight = width;
                    cropWidth = width;
                }
                
                croppedOrigin = NSMakePoint( ((width-cropWidth)/2.), ((height - cropHeight)/2.));
                
                cropData = data + spp*((width-cropWidth)/2) + spp*((height - cropHeight)/2)*width;
                
                // resize the data
                
                vImage_Buffer src, dest;
                
                src.data = cropData;
                src.rowBytes = width * spp;
                src.height = cropHeight;
                src.width = cropWidth;
                
                dest.data = calloc( size*size*spp, 1);
                dest.rowBytes = size*spp;
                dest.width = dest.height = size;
                
                if( dest.data)
                {
                    vImage_Buffer	argbsrcVimage, argbdstVimage;
                    
                    argbsrcVimage = src;
                    argbsrcVimage.rowBytes =  src.width * 4;
                    argbsrcVimage.data = calloc( argbsrcVimage.rowBytes * argbsrcVimage.height, 1);
                    
                    argbdstVimage = dest;
                    argbdstVimage.rowBytes =  dest.width * 4;
                    argbdstVimage.data = calloc( argbdstVimage.rowBytes * argbdstVimage.height, 1);
                    
                    vImageConvert_RGB888toARGB8888( &src, nil, 0, &argbsrcVimage, 0, 0);
                    vImageScale_ARGB8888( &argbsrcVimage, &argbdstVimage, nil, kvImageHighQualityResampling);
                    vImageConvert_ARGB8888toRGB888( &argbdstVimage, &dest, 0);
                    
                    free( argbsrcVimage.data);
                    free( argbdstVimage.data);
                    
                    free( data);
                    
                    data = dest.data;
                    width = size;
                    height = size;
                    
                    // correct the spacing & origin
                    
//                    if( imOrigin)
                    {
                        NSPoint tempPt = [self ConvertFromUpLeftView2GL: croppedOrigin];
                        [curDCM convertPixX: tempPt.x pixY: tempPt.y toDICOMCoords: imOrigin pixelCenter: YES];
                    }
                    
//                    if( imSpacing)
                    {
                        imSpacing[ 0] /= rescale;
                        imSpacing[ 1] /= rescale;
                    }
                }
            }
        }
        
        [exportDCM setSourceFile: [self.imageObj valueForKey:@"completePath"]];
        
        float thickness, location;
        
        [self getThickSlabThickness:&thickness location:&location];
        [exportDCM setSliceThickness: thickness];
        [exportDCM setSlicePosition: location];
        
        if( [views count] <= 1)
        {
            [self orientationCorrectedToView: o];
            [exportDCM setOrientation: o];
        }
        
        if( exportSpacingAndOrigin && (imSpacing[ 0] != 0 || imSpacing[ 1] != 0 || imOrigin[ 0] != 0 || imOrigin[ 0] != 1 || imOrigin[ 0] != 2))
        {
            [exportDCM setPosition: imOrigin];
            [exportDCM setPixelSpacing: imSpacing[ 0] :imSpacing[ 1]];
        }
        [exportDCM setPixelData: data samplesPerPixel:spp bitsPerSample:bpp width: width height: height];
        [exportDCM setModalityAsSource: NO];
        
        f = [exportDCM writeDCMFile: nil withExportDCM: dcmExportPlugin];
        if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
        
        free( data);
    }
    
    [DCMView setCLUTBARS: clutBarsCopy ANNOTATIONS: annotCopy];
    
    return [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil];
}

- (NSImage*) nsimage
{
    return [self nsimage: NO allViewers: NO];
}

- (NSImage*) nsimage:(BOOL) originalSize
{
    return [self nsimage: originalSize allViewers: NO];
}

- (NSImage*) nsimage:(BOOL) originalSize allViewers:(BOOL) allViewers
{
    NSBitmapImageRep	*rep;
    long				width, height, spp, bpp;
    NSString			*colorSpace;
    unsigned char		*data;
    
    NSDisableScreenUpdates();
    
    if( stringID == nil && originalSize == NO)
    {
        //		if( [ViewerController numberOf2DViewer] > 1 || _imageColumns != 1 || _imageRows != 1 || [self isKeyImage] == YES)
        {
            if( [self is2DViewer] && (_imageColumns != 1 || _imageRows != 1))
            {
                NSArray	*vs = [[self windowController] imageViews];
                
                [vs makeObjectsPerformSelector: @selector(setStringID:) withObject: @"copy"];
                [vs makeObjectsPerformSelector: @selector(display)];
            }
            else
            {
                stringID = [@"copy" retain];	// to remove the red square around the image
                [self display];
            }
        }
    }
    
    if( [self is2DViewer] == NO) allViewers = NO;
    
    if( allViewers && [ViewerController numberOf2DViewer] > 1)
    {
        NSArray	*viewers = [ViewerController getDisplayed2DViewers];
        
        //order windows from left-top to right-bottom
        NSMutableArray	*cWindows = [NSMutableArray arrayWithArray: viewers];
        NSMutableArray	*cResult = [NSMutableArray array];
        int wCount = [cWindows count];
        
        for( int i = 0; i < wCount; i++)
        {
            int index = 0;
            float minY = [[[cWindows objectAtIndex: 0] window] frame].origin.y;
            
            for( int x = 0; x < [cWindows count]; x++)
            {
                if( [[[cWindows objectAtIndex: x] window] frame].origin.y > minY)
                {
                    minY  = [[[cWindows objectAtIndex: x] window] frame].origin.y;
                    index = x;
                }
            }
            
            float minX = [[[cWindows objectAtIndex: index] window] frame].origin.x;
            
            for( int x = 0; x < [cWindows count]; x++)
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
        for( ViewerController *v in viewers)
        {
            [[v seriesView] selectFirstTilingView];
            
            NSRect	bounds = [[v imageView] bounds];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey:@"includeAllTiledViews"])
            {
                bounds.size.width *= [[v seriesView] imageColumns];
                bounds.size.height *= [[v seriesView] imageRows];
            }
            
            NSRect or = {[v.imageView convertPoint:bounds.origin toView:nil], NSZeroSize};
            bounds.origin = [v.window convertRectToScreen:or].origin;
            
            bounds = NSIntegralRect(bounds);
            
            bounds.origin.x *= v.window.backingScaleFactor;
            bounds.origin.y *= v.window.backingScaleFactor;
            
            bounds.size.width *= v.window.backingScaleFactor;
            bounds.size.height *= v.window.backingScaleFactor;
            
            [viewsRect addObject: [NSValue valueWithRect: bounds]];
        }
        
        data = [self getRawPixelsWidth:  &width
                                height: &height
                                   spp: &spp
                                   bpp: &bpp
                         screenCapture: YES
                            force8bits: YES
                       removeGraphical: NO
                          squarePixels: YES
                              allTiles: [[NSUserDefaults standardUserDefaults] boolForKey: @"includeAllTiledViews"]
                    allowSmartCropping: NO //[[NSUserDefaults standardUserDefaults] boolForKey: @"allowSmartCropping"]
                                origin: nil
                               spacing: nil
                                offset: nil
                              isSigned: nil
                                 views: [viewers valueForKey: @"imageView"]
                             viewsRect: viewsRect];
    }
    else data = [self getRawPixelsWidth :&width height:&height spp:&spp bpp:&bpp screenCapture:!originalSize force8bits: YES removeGraphical:NO squarePixels:YES allTiles: [[NSUserDefaults standardUserDefaults] boolForKey:@"includeAllTiledViews"] allowSmartCropping: [[NSUserDefaults standardUserDefaults] boolForKey: @"allowSmartCropping"] origin: nil spacing: nil];
    
    if( [stringID isEqualToString:@"copy"])
    {
        if( [self is2DViewer] && (_imageColumns != 1 || _imageRows != 1))
        {
            NSArray	*vs = [[self windowController] imageViews];
            
            [vs makeObjectsPerformSelector: @selector(setStringID:) withObject: nil];
            [vs makeObjectsPerformSelector: @selector(display)];
        }
        else
        {
            [stringID release];
            stringID = nil;
            
            [self setNeedsDisplay: YES];
        }
    }
    
    if( spp == 3) colorSpace = NSCalibratedRGBColorSpace;
    else colorSpace = NSCalibratedWhiteColorSpace;
    
    rep = [[[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes: nil
            pixelsWide: width
            pixelsHigh: height
            bitsPerSample: bpp
            samplesPerPixel: spp
            hasAlpha: NO
            isPlanar: NO
            colorSpaceName: colorSpace
            bytesPerRow: width*bpp*spp/8
            bitsPerPixel: bpp*spp] autorelease];
    
    if( data)
        memcpy( [rep bitmapData], data, height*width*bpp*spp/8);
    
    NSImage *image = [[[NSImage alloc] init] autorelease];
    [image addRepresentation:rep];
    
    free( data);
    
    NSEnableScreenUpdates();
    
    return image;
}

- (BOOL) zoomIsSoftwareInterpolated
{
    return zoomIsSoftwareInterpolated;
}

-(void) setScaleValueCentered:(float) x
{
    if( x < 0.01 ) return;
    if( x > 100) return;
    if( isnan( x)) return;
    if( curImage < 0) return;
    
    if( x != scaleValue)
    {
        if( scaleValue)
        {
            [self setOriginX:((origin.x * x) / scaleValue) Y:((origin.y * x) / scaleValue)];
        }
        
        scaleValue = x;
        
        if( scaleValue < 0.01) scaleValue = 0.01;
        if( scaleValue > 100) scaleValue = 100;
        if( isnan( scaleValue)) scaleValue = 100;
        
        if( [self softwareInterpolation] || [blendingView softwareInterpolation])
            [self loadTextures];
        else if( zoomIsSoftwareInterpolated || [blendingView zoomIsSoftwareInterpolated])
            [self loadTextures];
        
        if( [self is2DViewer])
        {
            // Series Level
            if( [self isScaledFit] == NO)
                [self.seriesObj setValue:[NSNumber numberWithFloat: scaleValue / sqrt( [self frame].size.height * [self frame].size.width)] forKey:@"scale"];
            else
                [self.seriesObj setValue: nil forKeyPath: @"scale"];
            [self.seriesObj setValue:[NSNumber numberWithInt: 3] forKey: @"displayStyle"];
            
            // Image Level
            if( curImage >= 0 && COPYSETTINGSINSERIES == NO && [self isScaledFit] == NO)
                [self.imageObj setValue:[NSNumber numberWithFloat:scaleValue] forKey:@"scale"];
            else
                [self.imageObj setValue: nil forKey:@"scale"];
        }
        
        [self updateTilingViews];
        
        [self setNeedsDisplay:YES];
    }
}


- (void) setScaleValue:(float) x
{
    if( isnan( x)) return;
    if( curImage < 0) return;
    if( curDCM == nil) return;
    if( x < 0.01) x = 0.01;
    if( x > 100) x = 100;
    
    if( scaleValue != x )
    {
        scaleValue = x;
        
        if( [self softwareInterpolation] || [blendingView softwareInterpolation])
            [self loadTextures];
        else if( zoomIsSoftwareInterpolated || [blendingView zoomIsSoftwareInterpolated])
            [self loadTextures];
        
        if( [self is2DViewer] && firstTimeDisplay)
        {
            if( [[self windowController] isPostprocessed] == NO)
            {
                @try {
                    // Series Level
                    if( [self isScaledFit] == NO)
                        [self.seriesObj setValue:[NSNumber numberWithFloat: scaleValue / sqrt( [self frame].size.height * [self frame].size.width)] forKey:@"scale"];
                    else
                        [self.seriesObj setValue: nil forKey:@"scale"];
                    
                    [self.seriesObj setValue:[NSNumber numberWithInt: 3] forKey: @"displayStyle"];
                    
                    // Image Level
                    if( curImage >= 0 && COPYSETTINGSINSERIES == NO && [self isScaledFit] == NO)
                        [self.imageObj setValue:[NSNumber numberWithFloat:scaleValue] forKey:@"scale"];
                    else
                        [self.imageObj setValue: nil forKey:@"scale"];
                }
                @catch ( NSException *e) {
                    N2LogException( e);
                }
            }
        }
        
        [self updateTilingViews];
        
        [self setNeedsDisplay:YES];
    }
}

-(void) setAlpha:(float) a
{
    float   val, ii;
    float   src[ 256];
    long i;
    
    switch( blendingMode )
    {
        case 0:				// LINEAR FUSION
            for( i = 0; i < 256; i++ ) src[ i] = i;
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
    
    if( blendingFactor < -256) blendingFactor = -256;
    if( blendingFactor > 256) blendingFactor = 256;
    
    [blendingView setAlpha: blendingFactor];
    [self loadTextures];
    [self setNeedsDisplay: YES];
    
    if( [self is2DViewer])
    {
        if( blendingFactor != [[[self windowController] blendingSlider] floatValue])
        {
            [[[self windowController] blendingSlider] setFloatValue: blendingFactor];
            [[self windowController] blendingSlider: [[self windowController] blendingSlider]];
        }
    }
}

-(void) setBlendingMode:(long) f
{
    blendingMode = f;
    
    if( [blendingView blendingMode] != blendingMode)
        [blendingView setBlendingMode: blendingMode];
    
    [blendingView setAlpha: blendingFactor];
    
    [self loadTextures];
    [self setNeedsDisplay: YES];
}

-(void) setRotation:(float) x
{
    if( rotation != x )
    {
        rotation = x;
        
        if( rotation < 0) rotation += 360;
        if( rotation > 360) rotation -= 360;
        
        [self.seriesObj setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
        
        // Image Level
        if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
            [self.imageObj setValue:[NSNumber numberWithFloat:rotation] forKey:@"rotationAngle"];
        else
            [self.imageObj setValue: nil forKey:@"rotationAngle"];
        
        [self updateTilingViews];
        
        [self setNeedsDisplay: YES];
    }
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
    
    double length = sqrt(o[ 0]*o[ 0] + o[ 1]*o[ 1] + o[ 2]*o[ 2]);
    if( length)	{	o[0] = o[ 0] / length;	o[1] = o[ 1] / length;	o[ 2] = o[ 2] / length;	}
    
    length = sqrt(o[ 3]*o[ 3] + o[ 4]*o[ 4] + o[ 5]*o[ 5]);
    if( length)	{	o[ 3] = o[ 3] / length;	o[ 4] = o[ 4] / length;	o[ 5] = o[ 5] / length;	}
    
    length = sqrt(o[ 6]*o[ 6] + o[ 7]*o[ 7] + o[ 8]*o[ 8]);
    if( length)	{	o[6] = o[ 6] / length;	o[ 7] = o[ 7] / length;	o[ 8] = o[ 8] / length;	}
    
    memcpy( correctedOrientation, o, sizeof o );
}

#ifndef OSIRIX_LIGHT
- (N3AffineTransform)pixToSubDrawRectTransform // converst points in DCMPix "Slice Coordinates" to coordinates that need to be passed to GL in subDrawRect
{
    N3AffineTransform pixToSubDrawRectTransform;
    
#ifndef NDEBUG
    if( isnan( curDCM.pixelSpacingX) || isnan( curDCM.pixelSpacingY) || curDCM.pixelSpacingX <= 0 || curDCM.pixelSpacingY <= 0 || curDCM.pixelSpacingX > 1000 || curDCM.pixelSpacingY > 1000)
        NSLog( @"******* CPR pixel spacing incorrect for pixToSubDrawRectTransform");
#endif
    
    pixToSubDrawRectTransform = N3AffineTransformIdentity;
    //    pixToSubDrawRectTransform = N3AffineTransformConcat(pixToSubDrawRectTransform, N3AffineTransformMakeScale(1.0/curDCM.pixelSpacingX, 1.0/curDCM.pixelSpacingY, 1));
    pixToSubDrawRectTransform = N3AffineTransformConcat(pixToSubDrawRectTransform, N3AffineTransformMakeTranslation(curDCM.pwidth * -0.5, curDCM.pheight * -0.5, 0));
    pixToSubDrawRectTransform = N3AffineTransformConcat(pixToSubDrawRectTransform, N3AffineTransformMakeScale(scaleValue, scaleValue, 1));
    
    pixToSubDrawRectTransform.m14 = 0.0;
    pixToSubDrawRectTransform.m24 = 0.0;
    pixToSubDrawRectTransform.m34 = 0.0;
    pixToSubDrawRectTransform.m44 = 1.0;
    
    return pixToSubDrawRectTransform;
}
#endif

-(void) setOriginWithRotationX:(float) x Y:(float) y
{
    x = x*cos(rotation*deg2rad) + y*sin(rotation*deg2rad);
    y = x*sin(rotation*deg2rad) - y*cos(rotation*deg2rad);
    
    [self setOriginX: x Y: y];
}

-(void) setOrigin:(NSPoint) x
{
    [self setOriginX: x.x Y: x.y];
}

-(void) setOriginX:(float) x Y:(float) y
{
    if( curImage < 0) return;
    if( curDCM == nil) return;
    
    if( x > -100000 && x < 100000) x = x;
    else x = 0;
    
    if( y > -100000 && y < 100000) y = y;
    else y = 0;
    
    if( origin.x != x || origin.y != y)
    {
        origin.x = x;
        origin.y = y;
        [self updateTilingViews];
        
        [self setNeedsDisplay:YES];
        
        if( [self is2DViewer] == YES && [[self windowController] isPostprocessed] == NO)
        {
            // Series Level
            [self.seriesObj setValue:[NSNumber numberWithFloat:x] forKey:@"xOffset"];
            [self.seriesObj setValue:[NSNumber numberWithFloat:y] forKey:@"yOffset"];
            
            // Image Level
            if( curImage >= 0 && COPYSETTINGSINSERIES == NO)
            {
                [self.imageObj setValue:[NSNumber numberWithFloat:x] forKey:@"xOffset"];
                [self.imageObj setValue:[NSNumber numberWithFloat:y] forKey:@"yOffset"];
            }
            else
            {
                [self.imageObj setValue: nil forKey:@"xOffset"];
                [self.imageObj setValue: nil forKey:@"yOffset"];
            }
        }
    }
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

- (BOOL) softwareInterpolation
{
    if(	scaleValue > 2 && NOINTERPOLATION == NO && 
       SOFTWAREINTERPOLATION == YES && curDCM.pwidth <= SOFTWAREINTERPOLATION_MAX)
    {
        return YES;
    }
    return NO;
}

- (GLuint *) loadTextureIn:(GLuint *) texture blending:(BOOL) blending colorBuf: (unsigned char**) colorBufPtr textureX:(long*) tX textureY:(long*) tY redTable:(unsigned char*) rT greenTable:(unsigned char*) gT blueTable:(unsigned char*) bT textureWidth: (long*) tW textureHeight:(long*) tH resampledBaseAddr:(char**) rAddr resampledBaseAddrSize:(int*) rBAddrSize
{
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return nil;
    
    unsigned char* currentAlphaTable = alphaTable;
    
    BOOL modifiedSourceImage = curDCM.needToCompute8bitRepresentation;
    BOOL intFULL32BITPIPELINE = FULL32BITPIPELINE;
    BOOL localColorTransfer = colorTransfer;
    
    if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
        localColorTransfer = YES;
    
    if( [ViewerController numberOf2DViewer] > MAXNUMBEROF32BITVIEWERS)
        intFULL32BITPIPELINE = NO;
    
    if( curDCM.pheight >= maxTextureSize) 
        intFULL32BITPIPELINE = NO;
    
    if( curDCM.subtractedfImage) 
        intFULL32BITPIPELINE = NO;
    if( curDCM.shutterEnabled) 
        intFULL32BITPIPELINE = NO;
    if( curDCM.pwidth >= maxTextureSize)
        intFULL32BITPIPELINE = NO;
    
    if( blending == NO) currentAlphaTable = opaqueTable;
    
    if(  rT == nil)
    {
        rT = redTable;
        gT = greenTable;
        bT = blueTable;
    }
    
    if( noScale == YES)
    {
        [curDCM changeWLWW :127 : 256];
    }
    
    if( texture)
    {
        glDeleteTextures( *tX * *tY, texture);
        free( (char*) texture);
        texture = nil;
    }
    
    if( curDCM == nil)	// No image
    {
        return texture;		// == nil
    }
    
    BOOL isRGB = curDCM.isRGB;
    
    if( [curDCM transferFunctionPtr])
        intFULL32BITPIPELINE = NO;
    
    if( [curDCM stack] > 1)
    {
        if( curDCM.stackMode == 4 || curDCM.stackMode == 5)
            intFULL32BITPIPELINE = NO;
    }
    
    if( curDCM.isLUT12Bit) isRGB = YES;
    
    if( isRGB)
        intFULL32BITPIPELINE = NO;
    
    if( (localColorTransfer == YES) || (blending == YES))
        intFULL32BITPIPELINE = NO;
    
    if( curDCM.needToCompute8bitRepresentation == YES && intFULL32BITPIPELINE == NO)
        [curDCM compute8bitRepresentation];
    
    if( isRGB == YES)
    {
        if( curDCM.isLUT12Bit)
        {
        }
        else if((localColorTransfer == YES) || (blending == YES))
        {
            vImage_Buffer src, dest;
            
            [self reapplyWindowLevel];
            
            src.height = curDCM.pheight;
            src.width = curDCM.pwidth;
            src.rowBytes = src.width*4;
            src.data = curDCM.baseAddr;
            
            dest.height = curDCM.pheight;
            dest.width = curDCM.pwidth;
            dest.rowBytes = dest.width*4;
            dest.data = curDCM.baseAddr;
            
            if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
            {
                unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
                
                for( long i = 0; i < 256; i++)
                {
                    credTable[ i] = rT[ i] * redFactor;
                    cgreenTable[ i] = gT[ i] * greenFactor;
                    cblueTable[ i] = bT[ i] * blueFactor;
                }
                //#if __BIG_ENDIAN__
                vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) currentAlphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
                //#else
                //vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &cblueTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &credTable, (Pixel_8*) currentAlphaTable, 0);
                //#endif
            }
            else
            {
                //#if __BIG_ENDIAN__
                vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) currentAlphaTable, (Pixel_8*) rT, (Pixel_8*) gT, (Pixel_8*) bT, 0);
                //#else
                //vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) bT, (Pixel_8*) gT, (Pixel_8*) rT, (Pixel_8*) currentAlphaTable, 0);
                //#endif
            }
        }
        else if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
        {
            unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
            
            vImage_Buffer src, dest;
            
            [self reapplyWindowLevel];
            
            src.height = curDCM.pheight;
            src.width = curDCM.pwidth;
            src.rowBytes = src.width*4;
            src.data = curDCM.baseAddr;
            
            dest.height = curDCM.pheight;
            dest.width = curDCM.pwidth;
            dest.rowBytes = dest.width*4;
            dest.data = curDCM.baseAddr;
            
            for( long i = 0; i < 256; i++ )
            {
                credTable[ i] = rT[ i] * redFactor;
                cgreenTable[ i] = gT[ i] * greenFactor;
                cblueTable[ i] = bT[ i] * blueFactor;
            }
            //#if __BIG_ENDIAN__
            vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) currentAlphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
            //#else
            //vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &cblueTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &credTable, (Pixel_8*) currentAlphaTable, 0);
            //#endif
            
        }
    }
    else if( (localColorTransfer == YES) || (blending == YES))
    {
        if( *colorBufPtr) free( *colorBufPtr);
        
        *colorBufPtr = malloc( 4 * curDCM.pwidth * curDCM.pheight);
        
        vImage_Buffer src8, dest8;
        
        src8.height = curDCM.pheight;
        src8.width = curDCM.pwidth;
        src8.rowBytes = src8.width;
        src8.data = curDCM.baseAddr;
        
        dest8.height = curDCM.pheight;
        dest8.width = curDCM.pwidth;
        dest8.rowBytes = dest8.width*4;
        dest8.data = *colorBufPtr;
        
        vImageConvert_Planar8toARGB8888(&src8, &src8, &src8, &src8, &dest8, 0);
        
        if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
        {
            unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
            
            for( long i = 0; i < 256; i++ )
            {
                credTable[ i] = rT[ i] * redFactor;
                cgreenTable[ i] = gT[ i] * greenFactor;
                cblueTable[ i] = bT[ i] * blueFactor;
            }
            vImageTableLookUp_ARGB8888( &dest8, &dest8, (Pixel_8*) currentAlphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
        }
        else vImageTableLookUp_ARGB8888( &dest8, &dest8, (Pixel_8*) currentAlphaTable, (Pixel_8*) rT, (Pixel_8*) gT, (Pixel_8*) bT, 0);
    }
    
    glEnable(TEXTRECTMODE);
    
    float *computedfImage = nil;
    char *baseAddr = nil;
    int rowBytes = 0;
    
    *tH = curDCM.pheight;
    
    zoomIsSoftwareInterpolated = NO;
    
    if( [self softwareInterpolation])
    {
        zoomIsSoftwareInterpolated = YES;
        
        float resampledScale;
        if( curDCM.pwidth <= 256) resampledScale = 3;
        else resampledScale = 2;
        
        *tW = curDCM.pwidth * resampledScale;
        *tH = curDCM.pheight * resampledScale;
        
        if( *tW >= maxTextureSize) 
            intFULL32BITPIPELINE = NO;
        
        if( *tH >= maxTextureSize) 
            intFULL32BITPIPELINE = NO;
        
        vImage_Buffer src, dst;
        
        src.width = curDCM.pwidth;
        src.height = curDCM.pheight;
        
        if( modifiedSourceImage == YES)
            TextureComputed32bitPipeline = NO;
        
        if( (isRGB == YES) || ([curDCM thickSlabVRActivated] == YES))
        {
            src.rowBytes = curDCM.pwidth*4;
            src.data = curDCM.baseAddr;
            
            rowBytes = *tW * 4;
            dst.rowBytes = rowBytes;
            
            if( curDCM.isLUT12Bit)
                src.data = (char*) curDCM.LUT12baseAddr;
        }
        else if( (localColorTransfer == YES) || (blending == YES))
        {
            rowBytes = *tW * 4;
            
            src.data = *colorBufPtr;
            src.rowBytes = curDCM.pwidth*4;
            dst.rowBytes = rowBytes;
        }
        else
        {
            if( intFULL32BITPIPELINE == YES && TextureComputed32bitPipeline == NO)
            {
                rowBytes = *tW * 4;
                computedfImage = [curDCM computefImage];
                src.data = computedfImage;
                src.rowBytes = curDCM.pwidth*4;
                dst.rowBytes = rowBytes;
            }
            else
            {
                rowBytes = *tW;
                src.data = curDCM.baseAddr;
                src.rowBytes = curDCM.pwidth;
                dst.rowBytes = rowBytes;
            }
        }
        
        dst.width = *tW;
        dst.height = *tH;
        
        if( *rBAddrSize < rowBytes * *tH )
        {
            if( *rAddr) free( *rAddr);
            *rAddr = malloc( rowBytes * *tH);
            *rBAddrSize = rowBytes * *tH;
            
            TextureComputed32bitPipeline = NO;
        }
        
        if( *rAddr) 
        {
            baseAddr = *rAddr;
            dst.data = baseAddr;
            
            if( (localColorTransfer == YES) || (blending == YES) || (isRGB == YES) || ([curDCM thickSlabVRActivated] == YES))
                vImageScale_ARGB8888( &src, &dst, nil, QUALITY);	
            else
            {
                if( intFULL32BITPIPELINE)
                {
                    if( TextureComputed32bitPipeline == NO)
                        vImageScale_PlanarF( &src, &dst, nil, QUALITY);
                    TextureComputed32bitPipeline = YES;
                }
                else
                    vImageScale_Planar8( &src, &dst, nil, QUALITY);
            }
        }
        else
        {
            if( (localColorTransfer == YES) || (blending == YES))
            {
                *tW = curDCM.pwidth;
                rowBytes = curDCM.pwidth;
                baseAddr = (char*) *colorBufPtr;
            }
            else
            {
                *tW = curDCM.pwidth;
                rowBytes = curDCM.pwidth;
                baseAddr = curDCM.baseAddr;
            }
        }
    }
    else if( intFULL32BITPIPELINE)
    {
        *tW = curDCM.pwidth;
        rowBytes = curDCM.pwidth*4;
        computedfImage = [curDCM computefImage];
        baseAddr = (char*) computedfImage;
    }
    else
    {
        if( isRGB == YES || [curDCM thickSlabVRActivated] == YES)
        {
            *tW = curDCM.pwidth;
            rowBytes = curDCM.pwidth*4;
            baseAddr = curDCM.baseAddr;
            
            if( curDCM.isLUT12Bit)
            {
                baseAddr = (char*) curDCM.LUT12baseAddr;
                rowBytes = curDCM.pwidth*4;
                *tW = curDCM.pwidth;
            }
        }
        else if( (localColorTransfer == YES) || (blending == YES))
        {
            *tW = curDCM.pwidth;
            rowBytes = curDCM.pwidth;
            baseAddr = (char*) *colorBufPtr;
        }
        else
        {
            *tW = curDCM.pwidth;
            rowBytes = curDCM.pwidth;
            baseAddr = curDCM.baseAddr;
        }
    }
    
    if( intFULL32BITPIPELINE == NO)
        TextureComputed32bitPipeline = NO;
    
    glPixelStorei (GL_UNPACK_ROW_LENGTH, *tW);
    
    *tX = GetTextureNumFromTextureDim (*tW, maxTextureSize, false, f_ext_texture_rectangle);
    *tY = GetTextureNumFromTextureDim (*tH, maxTextureSize, false, f_ext_texture_rectangle);
    
    if( *tX * *tY == 0)
        NSLog(@"****** *tX * *tY == 0");
    
    texture = (GLuint *) malloc (sizeof (GLuint) * *tX * *tY);
    
    //	if( *tX * *tY > 1) NSLog(@"NoOfTextures: %d", *tX * *tY);
    
    glTextureRangeAPPLE(TEXTRECTMODE, *tW * *tH * 4, baseAddr);
    glGenTextures (*tX * *tY, texture);
    {
        int k = 0, offsetX = 0, currWidth, currHeight;
        for ( int x = 0; x < *tX; x++)
        {
            currWidth = GetNextTextureSize (*tW - offsetX, maxTextureSize, f_ext_texture_rectangle);
            
            int offsetY = 0;
            for ( int y = 0; y < *tY; y++)
            {
                unsigned char *pBuffer;
                
                if( isRGB == YES || [curDCM thickSlabVRActivated] == YES)
                {
                    pBuffer =   (unsigned char*) baseAddr +
                    offsetY * rowBytes +
                    offsetX * 4;
                }
                else if( (localColorTransfer == YES) || (blending == YES))
                    pBuffer =   (unsigned char*) baseAddr +
                    offsetY * rowBytes * 4 +
                    offsetX * 4;
                else
                {
                    if( intFULL32BITPIPELINE )
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
                currHeight = GetNextTextureSize (*tH - offsetY, maxTextureSize, f_ext_texture_rectangle); // use remaining to determine next texture size
                
                glBindTexture (TEXTRECTMODE, texture[k++]);
                
#ifndef NDEBUG
                {
                    GLenum glLocalError = GL_NO_ERROR;
                    glLocalError = glGetError();
                    if( glLocalError != GL_NO_ERROR)
                        NSLog( @"OpenGL error 0x%04X", glLocalError);
                }
#endif
                
                glTexParameterf (TEXTRECTMODE, GL_TEXTURE_PRIORITY, 1.0f);
                
                if (f_ext_client_storage)
                    glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
                else 
                    glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 0);
                
                if (f_arb_texture_rectangle && f_ext_texture_rectangle)
                {
                    //					if( *tW >= 1024 && *tH >= 1024 || [self class] == [OrthogonalMPRPETCTView class] || [self class] == [OrthogonalMPRView class])
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
                
                if( currWidth > 0 && currHeight > 0)
                {
                    if( intFULL32BITPIPELINE )
                    {					
#if __BIG_ENDIAN__
                        if( isRGB == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
#else
                        if( isRGB == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, pBuffer);
#endif
                        else if( (localColorTransfer == YES) || (blending == YES)) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, pBuffer);
                        else
                        {
                            float min = curWL - curWW / 2;
                            float max = curWL + curWW / 2;
                            
                            if( max-min == 0)
                            {
                                min = [curDCM fullwl] - [curDCM fullww] / 2;
                                max = [curDCM fullwl] + [curDCM fullww] / 2;
                            }
                            
                            glPixelTransferf( GL_RED_BIAS, -min/(max-min));
                            glPixelTransferf( GL_RED_SCALE, 1./(max-min));
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
                        if( isRGB == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
                        else if( (localColorTransfer == YES) || (blending == YES)) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
#else
                        if( isRGB == YES || [curDCM thickSlabVRActivated] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, pBuffer);
                        else if( (localColorTransfer == YES) || (blending == YES)) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, pBuffer);
#endif
                        else glTexImage2D (TEXTRECTMODE, 0, GL_INTENSITY8, currWidth, currHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pBuffer);
                    }
                }
                
#ifndef NDEBUG
                {
                    GLenum glLocalError = GL_NO_ERROR;
                    glLocalError = glGetError();
                    if( glLocalError != GL_NO_ERROR)
                        NSLog( @"OpenGL error 0x%04X", glLocalError);
                }
#endif
                
                offsetY += currHeight;
            }
            offsetX += currWidth;
        }
    }
    glDisable (TEXTRECTMODE);
    
    if( computedfImage)
    {
        if( computedfImage != curDCM.fImage)
            free( computedfImage);
    }
    
    return texture;
}

- (IBAction) sliderRGBFactor:(id) sender
{
    switch( [sender tag])
    {
        case 0: redFactor = [sender floatValue];  break;
        case 1: greenFactor = [sender floatValue];  break;
        case 2: blueFactor = [sender floatValue];  break;
    }
    
    [self reapplyWindowLevel];
    
    [self loadTextures];
    [self setNeedsDisplay:YES];
}

- (void) sliderAction:(id) sender
{
    long	x = curImage;//x = curImage before sliderAction
    
    if( flippedData) curImage = (long)[dcmPixList count] -1 -[sender intValue];
    else curImage = [sender intValue];
    
    [self setIndex:curImage];
    
    [self sendSyncMessage:curImage - x];
    
    if( [self is2DViewer] == YES)
    {
        [[self windowController] propagateSettings];
        [[self windowController] adjustKeyImage];
    }
}

- (void) increaseFontSize:(id) sender
{
    if( [[NSUserDefaults standardUserDefaults] floatForKey: @"LabelFONTSIZE"] < 60)
    {
        [[NSUserDefaults standardUserDefaults] setFloat: [[NSUserDefaults standardUserDefaults] floatForKey: @"LabelFONTSIZE"] + 1 forKey: @"LabelFONTSIZE"];
        [NSFont resetFont: 2];
        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixLabelGLFontChangeNotification object: sender];
    }
}

- (void) decreaseFontSize:(id) sender
{
    if( [[NSUserDefaults standardUserDefaults] floatForKey: @"LabelFONTSIZE"] > 6)
    {
        [[NSUserDefaults standardUserDefaults] setFloat: [[NSUserDefaults standardUserDefaults] floatForKey: @"LabelFONTSIZE"] - 1 forKey: @"LabelFONTSIZE"];
        [NSFont resetFont: 2];
        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixLabelGLFontChangeNotification object: sender];
    }
}

- (void) changeLabelGLFontNotification:(NSNotification*) note
{
    if( self.window.backingScaleFactor != 0)
    {
        [[self openGLContext] makeCurrentContext];
        
        CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx == nil)
            return;
        
        if( labelFontListGL)
            glDeleteLists (labelFontListGL, 150);
        
        labelFontListGL = glGenLists (150);
        
        [labelFont release];
        
        labelFont = [[NSFont fontWithName: [[NSUserDefaults standardUserDefaults] stringForKey:@"LabelFONTNAME"] size: [[NSUserDefaults standardUserDefaults] floatForKey: @"LabelFONTSIZE"]] retain];
        if( labelFont == nil) labelFont = [[NSFont fontWithName:@"Monaco" size:12] retain];
        
        [labelFont makeGLDisplayListFirst:' ' count:150 base: labelFontListGL :labelFontListGLSize :2 :self.window.backingScaleFactor];
        [ROI setFontHeight: [DCMView sizeOfString: @"B" forFont: labelFont].height];
        
        [self setNeedsDisplay:YES];
    }
}

- (void) changeGLFontNotification:(NSNotification*) note
{
    if( self.window.backingScaleFactor != 0)
    {
        [[self openGLContext] makeCurrentContext];
        
        CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx == nil)
            return;
        
        if( fontListGL)
            glDeleteLists (fontListGL, 150);
        fontListGL = glGenLists (150);
        
        [fontGL release];
        
        fontGL = [[NSFont fontWithName: [[NSUserDefaults standardUserDefaults] stringForKey:@"FONTNAME"] size: [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"]] retain];
        if( fontGL == nil) fontGL = [[NSFont fontWithName:@"Geneva" size:14] retain];
        
        [fontGL makeGLDisplayListFirst:' ' count:150 base: fontListGL :fontListGLSize :0 :self.window.backingScaleFactor];
        stringSize = [self convertSizeToBacking: [DCMView sizeOfString:@"B" forFont:fontGL]];
        
        @synchronized( globalStringTextureCache)
        {
            [globalStringTextureCache removeObject: stringTextureCache];
        }
        [stringTextureCache release];
        stringTextureCache = nil;
        
        [self setNeedsDisplay:YES];
    }
}

- (void)changeFont:(id)sender
{
    NSFont *oldFont = fontGL;
    NSFont *newFont = [sender convertFont:oldFont];
    
    [[NSUserDefaults standardUserDefaults] setObject: [newFont fontName] forKey: @"FONTNAME"];
    [[NSUserDefaults standardUserDefaults] setFloat: [newFont pointSize] forKey: @"FONTSIZE"];
    [NSFont resetFont: 0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixGLFontChangeNotification object: sender];
}

- (void)loadTexturesCompute
{
    [drawLock lock];
    
    @try 
    {
        pTextureName = [self loadTextureIn:pTextureName blending:NO colorBuf:&colorBuf textureX:&textureX textureY:&textureY redTable: redTable greenTable:greenTable blueTable:blueTable textureWidth:&textureWidth textureHeight:&textureHeight resampledBaseAddr:&resampledBaseAddr resampledBaseAddrSize:&resampledBaseAddrSize];
        
        if( blendingView)
        {
            if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                blendingTextureName = [blendingView loadTextureIn:blendingTextureName blending:YES colorBuf:&blendingColorBuf textureX:&blendingTextureX textureY:&blendingTextureY redTable: PETredTable greenTable:PETgreenTable blueTable:PETblueTable textureWidth:&blendingTextureWidth textureHeight:&blendingTextureHeight resampledBaseAddr:&blendingResampledBaseAddr resampledBaseAddrSize:&blendingResampledBaseAddrSize];
            else
                blendingTextureName = [blendingView loadTextureIn:blendingTextureName blending:YES colorBuf:&blendingColorBuf textureX:&blendingTextureX textureY:&blendingTextureY redTable:nil greenTable:nil blueTable:nil textureWidth:&blendingTextureWidth textureHeight:&blendingTextureHeight resampledBaseAddr:&blendingResampledBaseAddr resampledBaseAddrSize:&blendingResampledBaseAddrSize];
        }
        
        needToLoadTexture = NO;
    }
    @catch (NSException * e) 
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [drawLock unlock];
}

- (void) loadTextures
{
    needToLoadTexture = YES;
}

-(void) becomeMainWindow
{
    [self updateTilingViews];
    
    sliceFromTo[ 0][ 0] = HUGE_VALF;
    sliceFromTo2[ 0][ 0] = HUGE_VALF;
    sliceFromToS[ 0][ 0] = HUGE_VALF;
    sliceFromToE[ 0][ 0] = HUGE_VALF;
    sliceVector[ 0] = sliceVector[ 1] = sliceVector[ 2] = 0;
    slicePoint3D[ 0] = HUGE_VALF;
    
    [self sendSyncMessage: 0];
    [self computeColor];
    [self setNeedsDisplay:YES];
}

-(void) becomeKeyWindow
{
    sliceFromTo[ 0][ 0] = HUGE_VALF;
    sliceFromTo2[ 0][ 0] = HUGE_VALF;
    sliceFromToS[ 0][ 0] = HUGE_VALF;
    sliceFromToE[ 0][ 0] = HUGE_VALF;
    sliceVector[ 0] = sliceVector[ 1] = sliceVector[ 2] = 0;
    slicePoint3D[ 0] = HUGE_VALF;
    
    [self erase2DPointMarker];
    if( blendingView) [blendingView erase2DPointMarker];
    
    [self sendSyncMessage: 0];
    
    [self flagsChanged: [[NSApplication sharedApplication] currentEvent]];
    
    [self setNeedsDisplay:YES];
}

- (BOOL)becomeFirstResponder
{
    isKeyView = YES;
    
    [self updateTilingViews];
    
    if (curImage < 0)
    {
        if( flippedData)
        {
            if( listType == 'i') [self setIndex: (long)[dcmPixList count] -1 ];
            else [self setIndexWithReset:(long)[dcmPixList count] -1  :YES];
        }
        else
        {
            if( listType == 'i') [self setIndex: 0];
            else [self setIndexWithReset:0 :YES];
        }
        
        [self updateTilingViews];
    }
    
    [self becomeKeyWindow];
    [self setNeedsDisplay:YES];
    
    if( [self is2DViewer])
    {
        [[self windowController] adjustSlider];
        [[self windowController] propagateSettings];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixDCMViewDidBecomeFirstResponderNotification object:self];
    
    [self flagsChanged: [[NSApplication sharedApplication] currentEvent]];
    
    return YES;
}

// ** TILING SUPPORT

- (id)initWithFrame:(NSRect)frame
{
    [AppController initialize];
    
    [DCMView setDefaults];
    
    return [self initWithFrame:frame imageRows:1  imageColumns:1];
    
}

- (id)initWithFrame:(NSRect)frame imageRows:(int)rows  imageColumns:(int)columns
{
    self = [self initWithFrameInt:frame];
    if (self)
    {
        drawing = YES;
        _tag = 0;
        _imageRows = rows;
        _imageColumns = columns;
        isKeyView = NO;
        timeIntervalForDrag = 1.0;
        annotationType = [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"];
        
        [self setAutoresizingMask:NSViewMinXMargin];
        
        noScale = NO;
        flippedData = NO;
        
        //notifications
        NSNotificationCenter *nc;
        nc = [NSNotificationCenter defaultCenter];
        [nc addObserver: self
               selector: @selector(updateCurrentImage:)
                   name: OsirixDCMUpdateCurrentImageNotification
                 object: nil];
        
        [self.window makeFirstResponder: self];
    }
    return self;
    
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSiz
{
    if( [self is2DViewer] != YES)
    {
        [super resizeWithOldSuperviewSize:oldBoundsSiz];
        return;
    }
    
    NSRect superFrame = [[self superview] bounds];
    
    int newWidth = superFrame.size.width / _imageColumns;
    int newHeight = superFrame.size.height / _imageRows;
    int newY = newHeight * (int)(_tag / _imageColumns);
    int newX = newWidth * (int)(_tag % _imageColumns);
    NSRect newFrame = NSMakeRect(newX, newY, newWidth, newHeight);
    
    BOOL wasScaledToFit = [self isScaledFit];
    
    [self setFrame:newFrame];
    
    if( wasScaledToFit)
        [self scaleToFit];
    
    [self setNeedsDisplay:YES];
}

-(void)keyUp:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    [super keyUp:theEvent];
}

-(void) setRows:(int)rows columns:(int)columns
{
    if( _imageRows == 1 && _imageColumns == 1 && rows == 1 && columns == 1)
    {
        //		NSLog(@"No Resize");
        return;
    }
    _imageRows = rows;
    _imageColumns = columns;
    
    NSRect rect = [[self superview] bounds];
    [self resizeWithOldSuperviewSize:rect.size];
    [self setNeedsDisplay:YES];
}

-(void)setImageParamatersFromView:(DCMView *)aView
{
    if (aView != self && dcmPixList != nil)
    {
        int offset = [self tag] - [aView tag];
        int prevCurImage = [self curImage];
        
        if( flippedData)
            offset = -offset;
        
        curImage = [aView curImage] + offset;
        
        if (curImage < 0)
        {
            curImage = -1;
            
            if( flippedData == NO)
            {
                if( [self is2DViewer])
                {
                    [NSObject cancelPreviousPerformRequestsWithTarget:[self windowController] selector: @selector(selectFirstTilingView) object: nil];
                    [[self windowController] performSelector:@selector(selectFirstTilingView) withObject:nil afterDelay:0];
                }
            }
        }
        else if (curImage >= [dcmPixList count])
        {
            curImage = -1;
            
            if( flippedData)
            {
                if( [self is2DViewer])
                {
                    [NSObject cancelPreviousPerformRequestsWithTarget:[self windowController] selector: @selector(selectFirstTilingView) object: nil];
                    [[self windowController] performSelector:@selector(selectFirstTilingView) withObject:nil afterDelay:0];
                }
            }
        }
        
        if( [aView curDCM])
        {
            [self setCOPYSETTINGSINSERIESdirectly: aView.COPYSETTINGSINSERIES];
            
            if( curImage < 0)
            {
                
            }
            else if( COPYSETTINGSINSERIES)
            {
                if( [aView curWL] != 0 && [aView curWW] != 0)
                {
                    if( curWL != [aView curWL] || curWW != [aView curWW])
                        [self setWLWW:[aView curWL] :[aView curWW]];
                }	
                self.scaleValue = aView.scaleValue;
                self.rotation = aView.rotation;
                [self setOrigin: [aView origin]];
                
                self.xFlipped = aView.xFlipped;
                self.yFlipped = aView.yFlipped;
                
                // Blending
                if (blendingView != aView.blendingView)
                    self.blendingView = aView.blendingView;
                if (blendingFactor != aView.blendingFactor)
                    self.blendingFactor = aView.blendingFactor;
                if (blendingMode != aView.blendingMode)
                    self.blendingMode = aView.blendingMode;
                
                // CLUT
                unsigned char *aR, *aG, *aB;
                [aView getCLUT: &aR :&aG :&aB];
                [self setCLUT:aR :aG: aB];
            }
        }
        
        self.flippedData = aView.flippedData;
        [self setMenu: [aView menu]];
        
        if( prevCurImage != [self curImage])
            [self setIndex:[self curImage]];
    }
}

- (BOOL)resignFirstResponder
{
    isKeyView = NO;
    [self setNeedsDisplay:YES];
    [self sendSyncMessage: 0];
    
    return [super resignFirstResponder];
}

-(void) updateCurrentImage: (NSNotification*) note
{
    if( stringID == nil)
    {
        DCMView *otherView = [note object];
        
        if ([[[note object] superview] isEqual:[self superview]] && ![otherView isEqual: self]) 
            [self setImageParamatersFromView: otherView];
    }
}

-(void)newImageViewisKey:(NSNotification *)note
{
    if ([note object] != self)
        isKeyView = NO;
}

//cursor methods

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self eventToPlugins:theEvent];
    cursorSet = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self eventToPlugins: theEvent];
    
    [self mouseMoved: theEvent];
    
    [self deleteLens];
#ifdef new_loupe
    [self hideLoupe];
#endif
    mouseXPos = 0;
    mouseYPos = 0;
    
    cursorSet = NO;
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    [self flagsChanged: theEvent];
    [cursor set];
    cursorSet = YES;
}

- (void) checkCursor
{
    if(cursorSet == YES && [[self window] isKeyWindow] == YES)
    {
        [cursor set];
    }
}

-(void) setCursorForView: (ToolMode) tool
{
    NSCursor	*c;
    
    if( [self roiTool:tool])
    {
        c = [NSCursor crossCursor];
        //		else c = [NSCursor crosshairCursor];		//crossCursor
    }
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
    else if (tool == tCamera3D)
        c = [NSCursor rotate3DCameraCursor];
    else	
        c = [NSCursor arrowCursor];
    
    if( c != cursor)
    {
        [cursor release];
        cursor = [c retain];
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
    return blendingPixelMouseValue * [[blendingView curDCM] patientsWeight] * 1000. / ([[blendingView curDCM] radionuclideTotalDoseCorrected] * [curDCM decayFactor]);
}

- (float)getSUV
{
    if( curDCM.SUVConverted) return pixelMouseValue;
    
    if( [curDCM.units isEqualToString:@"CNTS"]) return pixelMouseValue * curDCM.philipsFactor;
    else return pixelMouseValue * curDCM.patientsWeight * 1000.0f / (curDCM.radionuclideTotalDoseCorrected * [curDCM decayFactor]);
}


+ (void)setPluginOverridesMouse: (BOOL)override { // is deprecated in @interface
    pluginOverridesMouse = override;
}

- (IBAction) realSize:(id)sender
{
    if( curDCM.pixelSpacingX == 0 || curDCM.pixelSpacingY == 0)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Actual Size Error",nil), NSLocalizedString(@"This image is not calibrated.",nil) , NSLocalizedString( @"OK",nil), nil, nil);
    }
    else
    {
        CGSize f = CGDisplayScreenSize( [[[[[self window] screen] deviceDescription] valueForKey: @"NSScreenNumber"] intValue]);
        CGRect r = CGDisplayBounds( [[[[[self window] screen] deviceDescription] valueForKey: @"NSScreenNumber"] intValue]); 
        
        if( f.width != 0 && f.height != 0)
        {
            NSLog( @"screen pixel ratio: %f", fabs( (f.width/r.size.width) - (f.height/r.size.height)));
            if( fabs( (f.width/r.size.width) - (f.height/r.size.height)) < 0.01)
            {
                [self setScaleValue: curDCM.pixelSpacingX / (f.width/r.size.width)];
            }
            else
            {
                NSRunCriticalAlertPanel(NSLocalizedString(@"Actual Size Error",nil), NSLocalizedString(@"Displayed pixels are non-squared pixel. Images cannot be displayed at actual size.",nil) , NSLocalizedString( @"OK",nil), nil, nil);
            }
        }
        else
            NSRunCriticalAlertPanel(NSLocalizedString(@"Actual Size Error",nil), NSLocalizedString(@"This screen doesn't support this function.",nil) , NSLocalizedString( @"OK",nil), nil, nil);
    }
}

- (IBAction)actualSize:(id)sender
{
    [self setOriginX: 0 Y: 0];
    self.rotation = 0.0f;
    self.scaleValue = 1.0f;
    
    if( [self is2DViewer] == YES)
    {
        if( [[self window] isMainWindow])
            [[self windowController] propagateSettings];
    }
}

- (IBAction)scaleToFit:(id)sender
{
    [self setOriginX: 0 Y: 0];
    self.rotation = 0.0f;
    [self scaleToFit];
    
    if( [self is2DViewer] == YES)
    {
        if( [[self window] isMainWindow])
            [[self windowController] propagateSettings];
    }
}

//Database links
- (DicomImage *)imageObj
{
    //	if( stringID == nil || [stringID isEqualToString: @"previewDatabase"])  <- this will break the DICOM export function: no sourceFilePath in DICOMExport
    {
#ifdef NDEBUG
#else
        if( [NSThread isMainThread] == NO)
            NSLog( @"******************* warning this object should be used only on the main thread. Create your own Context !");
#endif
        if( curImage >= 0 && curImage < dcmFilesList.count)
            return [dcmFilesList objectAtIndex: curImage];
        
        else if( [dcmPixList indexOfObject: curDCM] != NSNotFound && dcmFilesList.count == dcmPixList.count)
            return [dcmFilesList objectAtIndex: [dcmPixList indexOfObject: curDCM]];
        
        else
            return [curDCM imageObj];
    }
    
    return nil;
}

- (DicomSeries *)seriesObj
{
    //	if( stringID == nil || [stringID isEqualToString:@"previewDatabase"]) <- this will break the DICOM export function: no sourceFilePath in DICOMExport
    {
#ifdef NDEBUG
#else
        if( [NSThread isMainThread] == NO)
            NSLog( @"******************* warning this object should be used only on the main thread. Create your own Context !");
#endif
        if( curImage >= 0 && curImage < dcmFilesList.count)
            return [[dcmFilesList objectAtIndex: curImage] valueForKey: @"series"];
        else if( [dcmPixList indexOfObject: curDCM] != NSNotFound)
            return [[dcmFilesList objectAtIndex: [dcmPixList indexOfObject: curDCM]] valueForKey: @"series"];
        else return [curDCM seriesObj];
    }
    
    return nil;
}

- (DicomStudy *)studyObj
{
    //	if( stringID == nil || [stringID isEqualToString:@"previewDatabase"]) <- this will break the DICOM export function: no sourceFilePath in DICOMExport
    {
#ifdef NDEBUG
#else
        if( [NSThread isMainThread] == NO)
            NSLog( @"******************* warning this object should be used only on the main thread. Create your own Context !");
#endif
        if( curImage >= 0 && curImage < dcmFilesList.count)
            return [[dcmFilesList objectAtIndex: curImage] valueForKeyPath: @"series.study"];
        else if( [dcmPixList indexOfObject: curDCM] != NSNotFound)
            return [[dcmFilesList objectAtIndex: [dcmPixList indexOfObject: curDCM]] valueForKeyPath: @"series.study"];
        else return [curDCM studyObj];
    }
    
    return nil;
}

- (void) updatePresentationStateFromSeriesOnlyImageLevel: (BOOL) onlyImage
{
    return [self updatePresentationStateFromSeriesOnlyImageLevel: onlyImage scale: firstTimeDisplay offset: [self is2DViewer]];
}

- (void) updatePresentationStateFromSeriesOnlyImageLevel: (BOOL) onlyImage scale: (BOOL) scale offset: (BOOL) offset
{
    NSManagedObject *series = self.seriesObj;
    NSManagedObject *image = self.imageObj;
    
    if( series)
    {
        if( [image valueForKey:@"xFlipped"])
            self.xFlipped = [[image valueForKey:@"xFlipped"] boolValue];
        else if( !onlyImage)
            self.xFlipped = [[series valueForKey:@"xFlipped"] boolValue];
        else
            self.xFlipped = NO;
        
        if( [image valueForKey:@"yFlipped"])
            self.yFlipped = [[image valueForKey:@"yFlipped"] boolValue];
        else if( !onlyImage)
            self.yFlipped = [[series valueForKey:@"yFlipped"] boolValue];
        else
            self.yFlipped = NO;
        
        if( [stringID isEqualToString:@"previewDatabase"] == NO)
        {
            if((scale && [[NSUserDefaults standardUserDefaults] boolForKey:@"AlwaysScaleToFit"] == NO) || COPYSETTINGSINSERIES == NO)
            {
                if( [image valueForKey:@"scale"])
                {
                    if( [[image valueForKey:@"scale"] floatValue] != 0)
                        [self setScaleValue: [[image valueForKey:@"scale"] floatValue]];
                    else
                        [self scaleToFit];
                }
                else if( !onlyImage)
                {
                    if( [series valueForKey:@"scale"])
                    {
                        if( [[series valueForKey:@"scale"] floatValue] != 0)
                        {
                            if( [[series valueForKey:@"displayStyle"] intValue] == 3)
                                [self setScaleValue: [[series valueForKey:@"scale"] floatValue] * sqrt( [self frame].size.height * [self frame].size.width)];
                            else if( [[series valueForKey:@"displayStyle"] intValue] == 2)
                                [self setScaleValue: [[series valueForKey:@"scale"] floatValue] * [self frame].size.width];
                            else
                                [self setScaleValue: [[series valueForKey:@"scale"] floatValue]];
                        }
                        else
                            [self scaleToFit];
                    }
                    else
                        [self scaleToFit];
                }
                else 
                    [self scaleToFit];
            }
            else
                [self scaleToFit];
        }
        else
            [self scaleToFit];
        
        if( [image valueForKey:@"rotationAngle"])
            [self setRotation: [[image valueForKey:@"rotationAngle"] floatValue]];
        else if( !onlyImage)
            [self setRotation:  [[series valueForKey:@"rotationAngle"] floatValue]];
        else
            [self setRotation: 0];
        
        if( [stringID isEqualToString:@"previewDatabase"] == NO)
        {
            if( (offset && [[NSUserDefaults standardUserDefaults] boolForKey:@"AlwaysScaleToFit"] == NO) || COPYSETTINGSINSERIES == NO)
            {
                NSPoint o = NSMakePoint( HUGE_VALF, HUGE_VALF);
                
                if( [image valueForKey:@"xOffset"])  o.x = [[image valueForKey:@"xOffset"] floatValue];
                else if( !onlyImage) o.x = [[series valueForKey:@"xOffset"] floatValue];
                
                if( [image valueForKey:@"yOffset"])  o.y = [[image valueForKey:@"yOffset"] floatValue];
                else if( !onlyImage) o.y = [[series valueForKey:@"yOffset"] floatValue];
                
                if( o.x != HUGE_VALF && o.y != HUGE_VALF)
                    [self setOrigin: o];
            }
        }
        
        float ww = 0, wl = 0;
        
        if( [image valueForKey:@"windowWidth"]) ww = [[image valueForKey:@"windowWidth"] floatValue];
        else if( !onlyImage && [series valueForKey:@"windowWidth"]) ww = [[series valueForKey:@"windowWidth"] floatValue];
        else if( ![self is2DViewer])
            ww = curWW;
        
        if( [image valueForKey:@"windowLevel"]) wl = [[image valueForKey:@"windowLevel"] floatValue];
        else if( !onlyImage && [series valueForKey:@"windowLevel"]) wl= [[series valueForKey:@"windowLevel"] floatValue];
        else if( ![self is2DViewer])
            wl = curWL;
        
        if( ww == 0)
        {
            if( (curImage >= 0) || COPYSETTINGSINSERIES == NO || [self is2DViewer] == NO)
            {
                ww = curDCM.savedWW;
                wl = curDCM.savedWL;
            }
            else
            {
                ww = [[dcmPixList objectAtIndex: [dcmPixList count]/2] savedWW];
                wl = [[dcmPixList objectAtIndex: [dcmPixList count]/2] savedWL];
            }
        }
        
        if( ww != 0 || wl != 0)
        {
            if( ww != 0.0)
            {
                if( [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"NM"]))
                {
                    float from, to;
                    
                    switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"DEFAULTPETWLWW"])
                    {
                        case 0:
                            if( curDCM.SUVConverted == NO)
                            {
                                curWW = ww;
                                curWL = wl;
                            }
                            else
                            {
                                if( [self is2DViewer] == YES)
                                {
                                    curWW = ww * [[self windowController] factorPET2SUV];
                                    curWL = wl * [[self windowController] factorPET2SUV];
                                }
                            }
                            break;
                            
                        case 1:
                            from = curDCM.maxValueOfSeries * [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWFROM"] / 100.;
                            to = curDCM.maxValueOfSeries * [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWTO"] / 100.;
                            
                            if( to - from != 0)
                            {
                                curWW = to - from;
                                curWL = from + (curWW/2.);
                            }
                            break;
                            
                        case 2:
                            if( curDCM.SUVConverted)
                            {
                                from = [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWFROMSUV"];
                                to = [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWTOSUV"];
                                
                                if( to - from != 0)
                                {
                                    curWW = to - from;
                                    curWL = from + (curWW/2.);
                                }
                            }
                            else
                            {
                                curWW = ww;
                                curWL = wl;
                            }
                            break;
                    }
                }
                else
                {
                    curWW = ww;
                    curWL = wl;
                }
                
                [self setWLWW:curWL :curWW];
            }
        }
        else if( onlyImage == NO)
        {
            if( [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[dcmFilesList objectAtIndex: curImage] valueForKey:@"modality"] isEqualToString:@"NM"]))
            {
                float from, to;
                
                curWW = ww;
                curWL = wl;
                
                switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"DEFAULTPETWLWW"])
                {
                    case 0:
                        // Do nothing
                        break;
                        
                    case 1:
                        from = curDCM.maxValueOfSeries * [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWFROM"] / 100.;
                        to = curDCM.maxValueOfSeries * [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWTO"] / 100.;
                        
                        curWW = to - from;
                        curWL = from + (curWW/2.);
                        break;
                        
                    case 2:
                        if( curDCM.SUVConverted)
                        {
                            from = [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWFROMSUV"];
                            to = [[NSUserDefaults standardUserDefaults] floatForKey:@"PETWLWWTOSUV"];
                            
                            curWW = to - from;
                            curWL = from + (curWW/2.);
                        }
                        else
                        {
                            curWW = ww;
                            curWL = wl;
                        }
                        break;
                }
                
                [self setWLWW:curWL :curWW];
            }
        }
    }
}

- (void) updatePresentationStateFromSeries
{
    [self updatePresentationStateFromSeriesOnlyImageLevel: NO];
}

//resize Window to a scale of Image Size
-(void)resizeWindowToScale:(float)resizeScale
{
    NSRect frame =  [self frame]; 
    float curImageWidth = curDCM.pwidth * resizeScale;
    float curImageHeight = curDCM.pheight* resizeScale;
    float frameWidth = frame.size.width;
    float frameHeight = frame.size.height;
    NSWindow *window = [self window];
    NSRect windowFrame = [window frame];
    float newWidth = windowFrame.size.width - (frameWidth - curImageWidth) * _imageColumns;
    float newHeight = windowFrame.size.height - (frameHeight - curImageHeight) * _imageRows;
    NSPoint center;
    center.x = windowFrame.origin.x + windowFrame.size.width/2.0;
    center.y = windowFrame.origin.y + windowFrame.size.height/2.0;
    
    NSArray *screens = [NSScreen screens];
    
    for(NSScreen* loopItem in screens)
    {
        if( NSPointInRect( center, [loopItem frame]))
        {
            NSRect screenFrame = [AppController usefullRectForScreen: loopItem];
            
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
    
    if( [self is2DViewer])
        [[self windowController] setWindowFrame: windowFrame];
    else
        [window setFrame:windowFrame display:YES];
    [self setNeedsDisplay:YES];
}

- (IBAction)resizeWindow:(id)sender
{
    if([[self windowController] FullScreenON] == FALSE)
    {
        float resizeScale = 1.0;
        float curImageWidth = curDCM.pwidth;
        float curImageHeight = curDCM.pheight;
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

- (void)subDrawRect: (NSRect)aRect   // Subclassable, default does nothing.
{
    return;
}

- (void)drawRectAnyway:(NSRect)aRect // Subclassable, default does nothing.
{
    return;
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

static NSString * const O2PasteboardTypeEventModifierFlags = @"com.opensource.osirix.eventmodifierflags";

- (void) startDrag:(NSTimer*)theTimer
{
    @try {
        _dragInProgress = YES;
        NSEvent *event = [theTimer userInfo];
        
        NSImage *image = [self nsimage:(event.modifierFlags&NSShiftKeyMask)];
        
        NSSize originalSize = [image size];
        float ratio = originalSize.width / originalSize.height;
        NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize(100, 100/ratio)] autorelease];
        if( [thumbnail size].width > 0 && [thumbnail size].height > 0) {
            [thumbnail lockFocus];
            [image drawInRect: NSMakeRect(0, 0, 100, 100/ratio) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
            [thumbnail unlockFocus];
        }
        
        NSPasteboardItem* pbi = [[[NSPasteboardItem alloc] init] autorelease];
        for (NSString *pasteboardType in DCMView.PasteboardTypes)
            if ([pasteboardType containsString:@"."])
                [pbi setData:[NSData dataWithBytes:&self length:sizeof(DCMView *)] forType:pasteboardType];
        [pbi setData:image.TIFFRepresentation forType:NSPasteboardTypeTIFF];
        NSEventModifierFlags mf = event.modifierFlags;
        [pbi setData:[NSData dataWithBytes:&mf length:sizeof(NSEventModifierFlags)] forType:O2PasteboardTypeEventModifierFlags];
        [pbi setDataProvider:self forTypes:@[NSPasteboardTypeString, (NSString *)kPasteboardTypeFileURLPromise]];
        [pbi setString:(id)kUTTypeImage forType:(id)kPasteboardTypeFilePromiseContent];

        NSDraggingItem* di = [[[NSDraggingItem alloc] initWithPasteboardWriter:pbi] autorelease];
        NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
        [di setDraggingFrame:NSMakeRect(p.x-thumbnail.size.width/2, p.y-thumbnail.size.height/2, thumbnail.size.width, thumbnail.size.height) contents:thumbnail];
        
        NSDraggingSession* session = [self beginDraggingSessionWithItems:@[di] event:event source:self];
        session.animatesToStartingPositionsOnCancelOrFail = YES;
    }
    @catch( NSException *localException) {
        NSLog(@"Exception while dragging: %@", [localException description]);
    }
    
    _dragInProgress = NO;
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return NSDragOperationGeneric;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    if ([type isEqualToString:(id)kPasteboardTypeFileURLPromise]) {
        PasteboardRef pboardRef = NULL;
        PasteboardCreate((__bridge CFStringRef)[pasteboard name], &pboardRef);
        if (!pboardRef)
            return;

        PasteboardSynchronize(pboardRef);
        
        CFURLRef urlRef = NULL;
        PasteboardCopyPasteLocation(pboardRef, &urlRef);
        
        if (urlRef) {
            NSString *description = self.dicomImage.series.name;
            if (!description.length)
                description = self.dicomImage.series.seriesDescription;

            NSString *name = self.dicomImage.series.study.name;
            if (description.length)
                name = [name stringByAppendingFormat:@" - %@", description];
            
            if (!name.length)
                name = @"Horos";

            NSURL *url = [(NSURL *)urlRef URLByAppendingPathComponent:[name stringByAppendingPathExtension:@"jpg"]];
            size_t i = 0;
            while ([url checkResourceIsReachableAndReturnError:NULL])
                url = [(NSURL *)urlRef URLByAppendingPathComponent:[name stringByAppendingFormat:@" (%lu).jpg", ++i]];

            NSEventModifierFlags mf; [[item dataForType:O2PasteboardTypeEventModifierFlags] getBytes:&mf];
            NSImage *image = [self nsimage:(mf&NSShiftKeyMask)];
            
            NSData *idata = [[NSBitmapImageRep imageRepWithData:image.TIFFRepresentation] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
            [idata writeToURL:url atomically:YES];

            [item setString:[url absoluteString] forType:type];

            CFRelease(urlRef);
        }
        
        CFRelease(pboardRef);
    }
}

- (void)deleteMouseDownTimer
{
    [_mouseDownTimer invalidate];
    [_mouseDownTimer release];
    _mouseDownTimer = nil;
    _dragInProgress = NO;
}

//part of Dragging Source Protocol
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
    return NSDragOperationEvery;
}

- (DicomImage *)dicomImage{
    return [dcmFilesList objectAtIndex: curImage];
}

#pragma mark -
#pragma mark Hot Keys

+(NSDictionary*) hotKeyModifiersDictionary
{
    return _hotKeyModifiersDictionary;
}

+(NSDictionary*) hotKeyDictionary
{
    return _hotKeyDictionary;
}

//Hot key action
-(BOOL)actionForHotKey:(NSString *)hotKey
{
    BOOL returnedVal = YES;
    
    if ([hotKey length] > 0)
    {
        NSDictionary *userInfo = nil;
        NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
        NSArray *wwwlValues = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        NSDictionary *opacityDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"];
        NSArray *opacityValues = [[opacityDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        NSArray *wwwl = nil;
        hotKey = [hotKey lowercaseString];
        
        if( [[DCMView hotKeyDictionary] objectForKey:hotKey])
        {
            unichar key = [[[DCMView hotKeyDictionary] objectForKey:hotKey] intValue];
            
            switch (key)
            {
                case DefaultWWWLHotKeyAction:
                    [self setWLWW:[[self curDCM] savedWL] :[[self curDCM] savedWW]];	// default WW/WL
                    break;
                    
                case FullDynamicWWWLHotKeyAction:
                    [self setWLWW:0 :0];											// full dynamic WW/WL
                    break;
                    
                case Preset1OpacityHotKeyAction:																	// 1 - 9 will be presets WW/WL
                case Preset2OpacityHotKeyAction:
                case Preset3OpacityHotKeyAction:
                case Preset4OpacityHotKeyAction:
                case Preset5OpacityHotKeyAction:
                case Preset6OpacityHotKeyAction:
                case Preset7OpacityHotKeyAction:
                case Preset8OpacityHotKeyAction:
                case Preset9OpacityHotKeyAction:
                    if([opacityValues count] >= key-Preset1OpacityHotKeyAction)
                    {
                        // First is always linear
                        int index = key-Preset1OpacityHotKeyAction-1;
                        
                        if( index < 0)
                            [[self windowController] ApplyOpacityString: NSLocalizedString(@"Linear Table", nil)];
                        else
                            [[self windowController] ApplyOpacityString: [opacityValues objectAtIndex: index]];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: [opacityValues objectAtIndex: index] userInfo: nil];
                    }
                    break;
                    
                case Preset1WWWLHotKeyAction:																	// 1 - 9 will be presets WW/WL
                case Preset2WWWLHotKeyAction:
                case Preset3WWWLHotKeyAction:
                case Preset4WWWLHotKeyAction:
                case Preset5WWWLHotKeyAction:
                case Preset6WWWLHotKeyAction:
                case Preset7WWWLHotKeyAction:
                case Preset8WWWLHotKeyAction:
                case Preset9WWWLHotKeyAction:
                    if([wwwlValues count] > key-Preset1WWWLHotKeyAction)
                    {
                        wwwl = [wlwwDict objectForKey: [wwwlValues objectAtIndex: key-Preset1WWWLHotKeyAction]];
                        [self setWLWW:[[wwwl objectAtIndex:0] floatValue] :[[wwwl objectAtIndex:1] floatValue]];
                        
                        if( [self is2DViewer] == YES) [[self windowController] setCurWLWWMenu: [wwwlValues objectAtIndex: key-Preset1WWWLHotKeyAction]];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: [wwwlValues objectAtIndex: key-Preset1WWWLHotKeyAction] userInfo: nil];
                    }	
                    break;
                    
                    // Flip
                case FlipVerticalHotKeyAction: [self flipVertical:nil];
                    break;
                    
                case  FlipHorizontalHotKeyAction: [self flipHorizontal:nil];
                    break;
                    
                    // mouse functions
                case WWWLToolHotKeyAction:
                case MoveHotKeyAction:
                case ZoomHotKeyAction:
                case RotateHotKeyAction:
                case ScrollHotKeyAction:
                case LengthHotKeyAction:
                case AngleHotKeyAction:
                case RectangleHotKeyAction:
                case OvalHotKeyAction:
                case TextHotKeyAction:
                case ArrowHotKeyAction:
                case OpenPolygonHotKeyAction:
                case ClosedPolygonHotKeyAction:
                case PencilHotKeyAction:
                case ThreeDPointHotKeyAction:
                case PlainToolHotKeyAction:
                case RepulsorHotKeyAction:
                case SelectorHotKeyAction:
                    if( [ViewerController getToolEquivalentToHotKey: key] >= 0)
                    {
                        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[ViewerController getToolEquivalentToHotKey: key]], @"toolIndex", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDefaultToolModifiedNotification object:nil userInfo: userInfo];
                    }
                    break;
                case EmptyHotKeyAction:
                case UnreadHotKeyAction:
                case ReviewedHotKeyAction:
                case DictatedHotKeyAction:
                case ValidatedHotKeyAction:
                    if( [self is2DViewer] == YES)
                        [[self windowController] setStatusValue: key - EmptyHotKeyAction];
                    break;
                case FullScreenAction:
                    if( [self is2DViewer] == YES) {
                        [[self windowController] showCurrentThumbnail: self];
                        
                        [self deleteInvalidROIs];
                        
                        if( drawingROI == NO)
                        {
                            if( drawingROI == NO)
                            {
                                [[self windowController] fullScreenMenu: self];
                            }
                        }
                    }
                    break;
                case Sync3DAction:
                    if( stringID == nil) {
                        if( [self is2DViewer] == YES)
                            [[self windowController] showCurrentThumbnail: self];
                        
                        [self deleteInvalidROIs];
                        
                        if( drawingROI == NO)
                            [self sync3DPosition];
                    }
                    break;
                case SetKeyImageAction:
                    if( [self is2DViewer] == YES)
                        [[self windowController] setKeyImage: self];
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

//#pragma mark -
//#pragma mark IMAVManager delegate methods.
//// The IMAVManager will call this to ask for the context we'll be providing frames with.
//- (void)getOpenGLBufferContext:(CGLContextObj *)contextOut pixelFormat:(CGLPixelFormatObj *)pixelFormatOut
//{
//
//    *contextOut = [_alternateContext CGLContextObj];
//    *pixelFormatOut = [[self pixelFormat] CGLPixelFormatObj];
//}
//
//// The IMAVManager will call this when it wants a frame.
//// Note that this will be called on a non-main thread.
//
//- (BOOL)renderIntoOpenGLBuffer:(CVOpenGLBufferRef)buffer onScreen:(int *)screenInOut forTime:(CVTimeStamp*)timeStamp
//{
//	// We ignore the timestamp, signifying that we're providing content for 'now'.	
//	if(!_hasChanged)
//		return NO;
//	
//	if( [[self window] isVisible] == NO)
//		return NO;
//	
//	if( [self is2DViewer])
//	{
//		if( [[self windowController] windowWillClose])
//			return NO;
//	}
//	
//	// Make sure we agree on the screen ID.
// 	CGLContextObj cgl_ctx = [_alternateContext CGLContextObj];
//	CGLGetVirtualScreen(cgl_ctx, screenInOut);
//	
//	//CGLContextObj CGL_MACRO_CONTEXT = [_alternateContext CGLContextObj];
//	//CGLGetVirtualScreen(CGL_MACRO_CONTEXT, screenInOut);
//	
//	// Attach the OpenGLBuffer and render into the _alternateContext.
//
////	if (CVOpenGLBufferAttach(buffer, [_alternateContext CGLContextObj], 0, 0, *screenInOut) == kCVReturnSuccess) {
//	if (CVOpenGLBufferAttach(buffer, cgl_ctx, 0, 0, *screenInOut) == kCVReturnSuccess)
//	{
//        // In case the buffers have changed in size, reset the viewport.
//        NSDictionary *attributes = (NSDictionary *)CVOpenGLBufferGetAttributes(buffer);
//        GLfloat width = [[attributes objectForKey:(NSString *)kCVOpenGLBufferWidth] floatValue];
//        GLfloat height = [[attributes objectForKey:(NSString *)kCVOpenGLBufferHeight] floatValue];
//		iChatWidth = width;
//		iChatHeight = height;
//		
//		// Render!
//		iChatDrawing = YES;
//        [self drawRect:NSMakeRect(0,0,width,height) withContext:_alternateContext];
//		iChatDrawing = NO;
//        return YES;
//    }
//	else
//	{
//        // This should never happen.  The safest thing to do if it does it return
//        // 'NO' (signifying that the frame has not changed).
//        return NO;
//    }
//}
//
//// Callback from IMAVManager asking what pixel format we'll be providing frames in.
//- (void)getPixelBufferPixelFormat:(OSType *)pixelFormatOut
//{
//    *pixelFormatOut = kCVPixelFormatType_32ARGB;
//}
//
//// This callback is called periodically when we're in the IMAVActive state.
//// We copy (actually, re-render) what's currently on the screen into the provided 
//// CVPixelBufferRef.
////
//// Note that this will be called on a non-main thread. 
//- (BOOL) renderIntoPixelBuffer:(CVPixelBufferRef)buffer forTime:(CVTimeStamp*)timeStamp
//{
//    // We ignore the timestamp, signifying that we're providing content for 'now'.
//	CVReturn err;
//	
//	// If the image has not changed since we provided the last one return 'NO'.
//    // This enables more efficient transmission of the frame when there is no
//    // new information.
//	if ([self checkHasChanged])
//		return NO;
//	
//    // Lock the pixel buffer's base address so that we can draw into it.
//	if((err = CVPixelBufferLockBaseAddress(buffer, 0)) != kCVReturnSuccess) {
//        // This should not happen.  If it does, the safe thing to do is return 
//        // 'NO'.
//		NSLog(@"Warning, could not lock pixel buffer base address in %s - error %ld", __func__, (long)err);
//		return NO;
//	}
//    @synchronized (self)
//	{
//		// Create a CGBitmapContext with the CVPixelBuffer.  Parameters /must/ match 
//		// pixel format returned in getPixelBufferPixelFormat:, above, width and
//		// height should be read from the provided CVPixelBuffer.
//		size_t width = CVPixelBufferGetWidth(buffer); 
//		size_t height = CVPixelBufferGetHeight(buffer);
//		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//		CGContextRef cgContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(buffer),
//													   width, height,
//													   8,
//													   CVPixelBufferGetBytesPerRow(buffer),
//													   colorSpace,
//													   kCGImageAlphaPremultipliedFirst);
//		CGColorSpaceRelease(colorSpace);
//		
//		// Derive an NSGraphicsContext, make it current, and ask our SlideshowView 
//		// to draw.
//		NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
//		[NSGraphicsContext setCurrentContext:context];
//		//get NSImage and draw in the rect
//		
//		[self drawImage: [self nsimage:NO] inBounds:NSMakeRect(0.0, 0.0, width, height)];
//		[context flushGraphics];
//		
//		// Clean up - remember to unlock the pixel buffer's base address (we locked
//		// it above so that we could draw into it).
//		CGContextRelease(cgContext);
//		CVPixelBufferUnlockBaseAddress(buffer, 0);
//	}
//    return YES;
//}

- (void) drawImage:(NSImage *)image inBounds:(NSRect)rect
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

// The _hasChanged flag is set to 'NO' after any check (by a client of this 
// class), and 'YES' after a frame is drawn that is not identical to the 
// previous one (in the drawInBounds: method).

// Returns the current state of the flag, and sets it to the passed in value.
- (BOOL)_checkHasChanged:(BOOL)flag
{
    BOOL hasChanged;
    @synchronized (self)
    {
        hasChanged = _hasChanged;
        _hasChanged = flag;
    }
    return hasChanged;
}

- (BOOL)checkHasChanged
{
    // Calling with 'NO' clears _hasChanged after the call (see above).
    return [self _checkHasChanged:NO];
}

#pragma mark -
#pragma mark Window Controler methods.
- (id) windowController
{
    return [[self window] windowController];
}

- (BOOL) is2DViewer
{
    if( is2DViewerCached)
        return is2DViewerValue;
    
    if( [self window])
    {
        is2DViewerCached = YES;
        is2DViewerValue = [[self windowController] is2DViewer];
    }
    //	else NSLog( @"**** NO Window defined");
    
    return is2DViewerValue;
}

#pragma mark -
#pragma mark 12 bit
- (void)setIsLUT12Bit:(BOOL)boo;
{
    for (DCMPix* pix in dcmPixList)
    {
        pix.isLUT12Bit = boo;
    }
}

- (BOOL)isLUT12Bit;
{
    BOOL is12Bit = YES;
    for (DCMPix* pix in dcmPixList)
    {
        is12Bit = is12Bit && pix.isLUT12Bit;
    }
    return is12Bit;
}

#pragma mark -
#pragma mark Loupe
//
//- (void)displayLoupeWithCenter:(NSPoint)center;
//{
//	if(!loupeController)
//		loupeController = [[LoupeController alloc] init];
//
//	if(!lensTexture)
//	{
//		[self hideLoupe];
//		return;
//	}
//	
//	if(![[loupeController window] isVisible])
//		[loupeController showWindow:nil];
//		
//	[loupeController setTexture:lensTexture withSize:NSMakeSize(LENSSIZE, LENSSIZE) bytesPerRow:LENSSIZE rotation:self.rotation];
//	[loupeController setWindowCenter:center];
//	[loupeController drawLoupeBorder:YES];
//}
//
//- (void)hideLoupe;
//{
//	if([[loupeController window] isVisible])
//		[[loupeController window] orderOut:self];
//}

+ (NSArray<NSString *> *)PasteboardTypes {
    return @[HorosPasteboardType,
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
             HorosPboardUTI, pasteBoardHoros, pasteBoardOsiriX
#pragma clang diagnostic pop
             ];
}

+ (NSArray<NSString *> *)PluginPasteboardTypes {
    return @[HorosPasteboardTypePlugin,
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
             HorosPluginPboardUTI, pasteBoardHorosPlugin, OsirixPluginPboardUTI, pasteBoardOsiriXPlugin
#pragma clang diagnostic pop
             ];
}

@end
