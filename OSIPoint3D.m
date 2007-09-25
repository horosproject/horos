//
//  OSIPoint3D.m
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

#import "OSIPoint3D.h"


@implementation OSIPoint3D

@synthesize voxelWidth = _voxelWidth, voxelDepth = _voxelDepth, voxelHeight = _voxelHeight, x = _x, y = _y, z = _z, value = _value, userInfo = _userInfo;



- (void) setX:(float)x y:(float)y z:(float)z{
	_x = x;
	_y = y;
	_z = z;
}

// init with x, y, and z
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	if (self = [super init]) {
		_x = x;
		_y = y;
		_z = z;
		_value = [value retain];
	}
	return self;
}


// init with the point and the slice
- (id)initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value{
	if (self = [super init]) {
		_x = point.x;
		_y = point.y;
		_z = (float)slice;
		_value = [value retain];
	}
	return self;
}

+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	return [[[OSIPoint3D alloc] initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value] autorelease];
}


+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value{
	return [[[OSIPoint3D alloc] initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value] autorelease];
}


- (void)dealloc{
	[_value release];
	[_userInfo release];
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"OSIPoint\nx = %2.1f y = %2.1f z = %2.1f value: %@", _x, _y, _z, _value];
}




- (id)copyWithZone:(NSZone *)zone{
	OSIPoint3D *newPoint = [[OSIPoint3D pointWithX:_x y:_y z:_z value:_value] retain];
	newPoint.voxelWidth = _voxelWidth;
	newPoint.voxelHeight = _voxelHeight;
	newPoint.voxelDepth = _voxelDepth;
	newPoint.userInfo = _userInfo;
	return newPoint;
}

	



@end
