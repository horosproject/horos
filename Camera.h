/*=========================================================================
  Program:   OsiriX

  Copyright(c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>
#import "Point3D.h"

@interface Camera : NSObject {
	Point3D *position, *viewUp, *focalPoint, *minCroppingPlanes, *maxCroppingPlanes;
	float clippingRangeNear, clippingRangeFar, viewAngle, eyeAngle, parallelScale;
	NSImage *previewImage;
	float wl, ww, fusionPercentage;
	BOOL is4D;
	long movieIndexIn4D;
}

- (id)init;
- (id)initWithCamera:(Camera *)c;
- (void)setPosition:(Point3D *)p;
- (Point3D *)position;
- (void)setViewUp:(Point3D *)p;
- (Point3D *)viewUp;
- (void)setFocalPoint:(Point3D *)p;
- (Point3D *)focalPoint;
- (void)setClippingRangeFrom:(float)near To:(float)far;
- (float)clippingRangeNear;
- (float)clippingRangeFar;
- (void)setViewAngle:(float)angle;
- (float)viewAngle;
- (void)setEyeAngle:(float)angle;
- (float)eyeAngle;
- (void)setParallelScale:(float)scale;
- (float)parallelScale;
// window level
- (void)setWLWW:(float)newWl :(float)newWw;
- (float)wl;
- (float)ww;
// cropping planes
- (void)setMinCroppingPlanes:(Point3D *)p;
- (Point3D *)minCroppingPlanes;
- (void)setMaxCroppingPlanes:(Point3D *)p;
- (Point3D *)maxCroppingPlanes;
// fusion
- (void)setFusionPercentage:(float)f;
- (float)fusionPercentage;
// 4D
- (void)setIs4D:(BOOL)boo;
- (BOOL)is4D;
- (void)setMovieIndexIn4D:(long)i;
- (long)movieIndexIn4D;

- (void)setPreviewImage:(NSImage *)im;
- (NSImage *)previewImage;

- (NSMutableDictionary *)exportToXML;
- (id)initWithDictionary:(NSDictionary *)xml;
@end
