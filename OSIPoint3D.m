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
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "OSIPoint3D.h"


@implementation OSIPoint3D

- (float)x{
	return _x;
}

- (float)y{
	return _y;
}
- (float)z{
	return _z;
}

- (void)setX:(float)x{
	_x = x;
}

- (void)setY:(float)y{
	_y = y;
}

- (void)setZ:(float)z{
	_z = z;
}

// init with x, y, and z
- (id)initWithX:(float)x  y:(float)y  z:(float)z{
	if (self = [super init]) {
		_x = x;
		_y = y;
		_z = z;
	}
	return self;
}


// init with the point and the slice
- (id)initWithPoint:(NSPoint)point  slice:(long)slice{
	if (self = [super init]) {
		_x = point.x;
		_y = point.y;
		_z = (float)slice;
	}
	return self;
}

+ (id)pointWithX:(float)x  y:(float)y  z:(float)z{
	return [[[OSIPoint3D alloc] initWithX:(float)x  y:(float)y  z:(float)z] autorelease];
}


+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice{
	return [[[OSIPoint3D alloc] initWithPoint:(NSPoint)point  slice:(long)slice] autorelease];
}

@end
