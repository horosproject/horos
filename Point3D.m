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




#import "Point3D.h"


@implementation Point3D

@synthesize x, y, z;

+ (id)point{
	return [[[Point3D alloc] init] autorelease];
}

+ (id) pointWithX:(float)x1 y:(float)y1 z:(float)z1{
	return [[[Point3D alloc] initWithX:(float)x1 y:(float)y1 z:(float)z1] autorelease];
}

-(id) init
{
	return [self initWithX:0.0  y:0.0  z:0.0];
}

-(id) initWithValues:(float)x1 :(float)y1 :(float)z1
{
	return [self initWithX:x1  y:y1  z:z1];	
}

-(id) initWithPoint3D: (Point3D*)p
{
	return [self initWithX:p.x  y:p.y  z:p.z];
}

-(id) initWithX:(float)x1  y:(float)y1  z:(float)z1{
	if (self = [super init]) {
		x = x1;
		y = y1;
		z = z1;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone{
	return [[Point3D alloc] initWithPoint3D:self];
}



-(void) setPoint3D: (Point3D*)p
{
	x = [p x];
	y = [p y];
	z = [p z];
}

-(void) add: (Point3D*)p
{
	x = x + [p x];
	y = y + [p y];
	z = z + [p z];
}

-(void) subtract: (Point3D*)p
{
	x = x - [p x];
	y = y - [p y];
	z = z - [p z];
}

-(void) multiply: (float)a
{
	x = x * a;
	y = y * a;
	z = z * a;
}

-(NSString*) description
{
	NSMutableString *desc = [NSMutableString stringWithCapacity:0];
	[desc appendString:@"Point3D ("];
	[desc appendString:[NSString stringWithFormat:@" %f,",[self x]]];
	[desc appendString:[NSString stringWithFormat:@" %f,",[self y]]];
	[desc appendString:[NSString stringWithFormat:@" %f )",[self z]]];
	return desc;
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

	x = [[xml valueForKey:@"x"] floatValue];
	y = [[xml valueForKey:@"y"] floatValue];
	z = [[xml valueForKey:@"z"] floatValue];
	return [self initWithX:x  y:y  z:z];
}

@end

@implementation Point3D (N3GeometryAdditions)

+ (id)pointWithN3Vector:(N3Vector)vector
{
	return [[[Point3D alloc] initWithN3Vector:vector] autorelease];
}

- (id)initWithN3Vector:(N3Vector)vector
{
	if ( (self = [super init]) ) {
		self.x = vector.x;
		self.y = vector.y;
		self.z = vector.z;
	}
	return self;
}

- (N3Vector)N3VectorValue
{
	N3Vector vector;
	vector.x = self.x;
	vector.y = self.y;
	vector.z = self.z;
	return vector;
}

@end

