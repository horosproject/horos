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



#import <Cocoa/Cocoa.h>
#import "Point3D.h"

@interface Camera : NSObject {
	Point3D *position, *viewUp, *focalPoint, *minCroppingPlanes, *maxCroppingPlanes;
	float clippingRangeNear, clippingRangeFar, viewAngle, eyeAngle, parallelScale;
	NSImage *previewImage;
	float wl, ww;
}

-(id) init;
-(id) initWithCamera: (Camera*)c;
-(void) setPosition: (Point3D*)p;
-(Point3D*) position;
-(void) setViewUp: (Point3D*)p;
-(Point3D*) viewUp;
-(void) setFocalPoint: (Point3D*)p;
-(Point3D*) focalPoint;
-(void) setClippingRangeFrom: (float)near To: (float)far;
-(float) clippingRangeNear;
-(float) clippingRangeFar;
-(void) setViewAngle: (float)angle;
-(float) viewAngle;
-(void) setEyeAngle: (float)angle;
-(float) eyeAngle;
-(void) setParallelScale: (float)scale;
-(float) parallelScale;
// window level
-(void) setWLWW: (float) newWl : (float) newWw;
-(float) wl;
-(float) ww;
// cropping planes
-(void) setMinCroppingPlanes: (Point3D*)p;
-(Point3D*) minCroppingPlanes;
-(void) setMaxCroppingPlanes: (Point3D*)p;
-(Point3D*) maxCroppingPlanes;

-(void) setPreviewImage: (NSImage*)im;
-(NSImage*) previewImage;

-(NSMutableDictionary*) exportToXML;
-(id) initWithDictionary: (NSDictionary*) xml;
@end
