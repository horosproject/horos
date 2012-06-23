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

#import "OSIVoxel.h"
#import "Point3D.h"

@implementation OSIVoxel

@synthesize voxelWidth = _voxelWidth, voxelDepth = _voxelDepth, voxelHeight = _voxelHeight, x = _x, y = _y, z = _z, value = _value, userInfo = _userInfo;



- (void) setX:(float)x y:(float)y z:(float)z{
	_x = x;
	_y = y;
	_z = z;
}

- (id)init {
	return [self initWithX:0  y:0  z:0 value:nil];
}

// init with x, y, and z
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	if (self = [super init]) {
		_x = x;
		_y = y;
		_z = z;
		_value = [value retain];
		_voxelWidth = 1.0;
		_voxelHeight = 1.0;
		_voxelDepth = 1.0;
		_userInfo = nil;
	}
	return self;
}


// init with the point and the slice
- (id)initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value{
	return [self initWithX:point.x  y:point.y  z:(float)slice value:nil];
}

+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	return [[[OSIVoxel alloc] initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value] autorelease];
}


+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value{
	return [[[OSIVoxel alloc] initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value] autorelease];
}

+ (id)pointWithPoint3D:(Point3D *)point3D{
	return [[[OSIVoxel alloc] initWithPoint3D:point3D] autorelease];
}

- (id)initWithPoint3D:(Point3D *)point3D{
	return [self initWithX:point3D.x y:point3D.y  z:point3D.z value:nil];
}


- (void)dealloc{
	[_value release];
	[_userInfo release];
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"OSIVoxel: x = %2.1f y = %2.1f z = %2.1f value: %@", _x, _y, _z, _value];
}




- (id)copyWithZone:(NSZone *)zone{
	OSIVoxel *newPoint = [[OSIVoxel pointWithX:_x y:_y z:_z value:_value] retain];
	if( newPoint == nil) return nil;
	newPoint.voxelWidth = _voxelWidth;
	newPoint.voxelHeight = _voxelHeight;
	newPoint.voxelDepth = _voxelDepth;
	newPoint.userInfo = _userInfo;
	return newPoint;
}


-(NSMutableDictionary*) exportToXML
{
	NSMutableDictionary *xml;
	xml = [[NSMutableDictionary alloc] init];
	[xml setObject: [NSString stringWithFormat:@"%f",[self x]] forKey:@"x"];
	[xml setObject: [NSString stringWithFormat:@"%f",[self y]] forKey:@"y"];
	[xml setObject: [NSString stringWithFormat:@"%f",[self z]] forKey:@"z"];
	return [xml autorelease];
}

-(id) initWithDictionary: (NSDictionary*) xml
{	
	float x1 = [[xml valueForKey:@"x"] floatValue];
	float y1 = [[xml valueForKey:@"y"] floatValue];
	float z1 = [[xml valueForKey:@"z"] floatValue];
	return [self initWithX:x1  y:y1  z:z1 value:nil];
}
	



@end
