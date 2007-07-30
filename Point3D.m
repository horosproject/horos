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




#import "Point3D.h"


@implementation Point3D
-(id) init
{
	self = [super init];
	x = 0;
	y = 0;
	z = 0;
	return self;
}

-(id) initWithValues:(float)x1 :(float)y1 :(float)z1
{
	self = [super init];
	x = x1;
	y = y1;
	z = z1;
	return self;
}

-(id) initWithPoint3D: (Point3D*)p
{
	self = [super init];
	x = [p x];
	y = [p y];
	z = [p z];
	return self;
}

-(float) x
{
	return x;
}

-(float) y
{
	return y;
}

-(float) z
{
	return z;
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
	self = [super init];
	x = [[xml valueForKey:@"x"] floatValue];
	y = [[xml valueForKey:@"y"] floatValue];
	z = [[xml valueForKey:@"z"] floatValue];
	return self;
}

@end
