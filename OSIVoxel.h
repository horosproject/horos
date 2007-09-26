//
//  OSIVoxel.h
//  OsiriX
//
//  Created by Lance Pysher on 4/26/07.
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

// This class represents a 3D Voxel;

#import <Cocoa/Cocoa.h>


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






- (void) setX:(float)x y:(float)y z:(float)z;


// init with x, y, and z
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
// init with the point and the slice
- (id)initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;;

+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;





@end
