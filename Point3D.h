/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>
#import "N3Geometry.h"

/** \brief  Represents a 3D Point
*
*  Represents a 3D Point
*  Has x, y, and z positions as float
*/


@interface Point3D : NSObject {
	float x, y, z;
}

@property float x;
@property float y;
@property float z;

+ (id)point;
+ (id) pointWithX:(float)x1 y:(float)y1 z:(float)z1;

-(id) init; // initiatize to origin
-(id) initWithValues:(float)x :(float)y :(float)z;
-(id) initWithPoint3D: (Point3D*)p;
-(id) initWithX:(float)x  y:(float)y  z:(float)z;
- (id)copyWithZone:(NSZone *)zone;

-(void) setPoint3D: (Point3D*)p;

-(void) add: (Point3D*)p;
-(void) subtract: (Point3D*)p;
-(void) multiply: (float)a;

-(NSMutableDictionary*) exportToXML;
-(id) initWithDictionary: (NSDictionary*)xml;

@end

@interface Point3D (N3GeometryAdditions)

+ (id)pointWithN3Vector:(N3Vector)vector;
- (id)initWithN3Vector:(N3Vector)vector;
- (N3Vector)N3VectorValue;

@end
