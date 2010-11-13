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




#import "MyPoint.h"

#define NEAR 5.


@implementation MyPoint
@synthesize point = pt;

+(MyPoint*)point:(NSPoint)a
{
	return [[[self alloc] initWithPoint:a] autorelease];
}

- (id)initWithPoint:(NSPoint)a
{
	self = [super init];
	
    pt = a;
	
	return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
	self = [super init];
	
    pt = NSPointFromString([coder decodeObject]);
	
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
	[coder encodeObject:NSStringFromPoint(pt)];
}

- (id)copyWithZone:(NSZone*)zone
{
	MyPoint* p = [[[self class] allocWithZone: zone] init];
	if( p == nil) return nil;
	p->pt = pt;
	
	return p;
}

- (float)y
{
	return pt.y;
}

- (float)x
{
	return pt.x;
}

- (void)move:(float)x :(float)y
{
	pt.x += x;
	pt.y += y;
}

- (BOOL)isEqualToPoint:(NSPoint)a
{
	if (a.x != pt.x) return NO;
	if (a.y != pt.y) return NO;
	return YES;
}

- (BOOL)isNearToPoint:(NSPoint)a :(float)scale :(float)ratio
{
	if (a.x >= pt.x - NEAR/scale && a.x <= pt.x + NEAR/scale && a.y >= pt.y - NEAR/(scale*ratio) && a.y <= pt.y + NEAR/(scale*ratio))
		return YES;
	return NO;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"[%f,%f]", pt.x, pt.y];
}

@end
