/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/




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

