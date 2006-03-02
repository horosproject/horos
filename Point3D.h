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


@interface Point3D : NSObject {
	float x, y, z;
}

-(id) init; // initiatize to origin
-(id) initWithValues:(float)x :(float)y :(float)z;
-(id) initWithPoint3D: (Point3D*)p;

-(float) x;
-(float) y;
-(float) z;

-(void) setPoint3D: (Point3D*)p;

-(void) add: (Point3D*)p;
-(void) subtract: (Point3D*)p;
-(void) multiply: (float)a;

-(NSMutableDictionary*) exportToXML;
-(id) initWithDictionary: (NSDictionary*)xml;

@end
