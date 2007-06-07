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
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	if (self = [super init]) {
		_x = x;
		_y = y;
		_z = z;
		_value = [value retain];
		_connections = [[NSMutableSet set] retain];
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
		_connections = [[NSMutableSet set] retain];
	}
	return self;
}

+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	return [[[OSIPoint3D alloc] initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value] autorelease];
}


+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value{
	return [[[OSIPoint3D alloc] initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value] autorelease];
}

- (NSNumber *)value {
	return _value;
}

- (void)setValue:(NSNumber *)value{
	[_value release];
	_value = [value retain];
}

- (void)dealloc{
	[_value release];
	[_connections release];
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"OSIPoint\nx = %2.1f y = %2.1f z = %2.1f value: %@", _x, _y, _z, _value];
}


- (NSMutableSet *)connections{
	return _connections;
}

- (void)setConnections:(NSMutableSet *)connections{
	[_connections release];
	_connections = [connections retain];
}
- (void)addConnection:(OSIPoint3D *)connection{
	[_connections addObject:connection];
}
- (void)removeConnection:(OSIPoint3D *)connection{
	[_connections removeObject:connection];
}

- (BOOL)isEndNode{
	if ([_connections count] < 2)
		return YES;
	return NO;
}

- (BOOL)isBranchNode {
		if ([_connections count] > 2)
		return YES;
	return NO;
}
	



@end
