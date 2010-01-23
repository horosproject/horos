
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

@class Point3D;

/** \brief Represents a Voxel
*
*  Represents a Voxel
*  Has x, y, and z positions as float
*/


@interface OSIVoxel : NSObject {
	float _x;
	float _y;
	float _z;
	NSNumber *_value;
	float _voxelWidth;
	float _voxelHeight;
	float _voxelDepth;	
	id  _userInfo;
}

@property float voxelWidth;
@property float voxelHeight;
@property float voxelDepth;
@property float x;
@property float y;
@property float z;
@property (copy, readwrite) NSNumber *value;
@property (retain, readwrite) id userInfo;





/** set the x, y, z position */
- (void) setX:(float)x y:(float)y z:(float)z;


/** init with x, y, and z position and pixel value */
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
/**  init with image point and the slice */
- (id)initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;
/** init with Point3D */
- (id)initWithPoint3D:(Point3D *)point3D;

/**  Class init with x, y, and z position and pixel value */
+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
/**  Class init with image point and the slice */
+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;
/** Class init with Point3D */
+ (id)pointWithPoint3D:(Point3D *)point3D;

/** export to xml */
-(NSMutableDictionary*) exportToXML;
/** init with xml dictonary */
-(id) initWithDictionary: (NSDictionary*) xml;






@end
