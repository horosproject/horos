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




#import "MyPoint.h"

#define NEAR 5.


@implementation MyPoint

+ (MyPoint*) point: (NSPoint) a
{
	return [[[self alloc] initWithPoint: a] autorelease];
}

-(id) copyWithZone: (NSZone*)zone
{
	MyPoint *p = [[[self class] allocWithZone: zone] init];
	
	[p setPoint: [self point]];
	
	return p;
}

- (NSString*) description
{
	return [NSString stringWithFormat: @"%f %f", pt.x, pt.y];
}

- (id) initWithCoder:(NSCoder*) coder
{
	if( self = [super init])
    {
		pt = NSPointFromString( [coder decodeObject]);
	}
	
	return self;
}

- (void) encodeWithCoder:(NSCoder*) coder
{
	[coder encodeObject: NSStringFromPoint( pt)];
}

- (id) initWithPoint:(NSPoint) a
{
	self = [super init];
    if (self)
	{
        pt = a;
    }
    return self;
}

- (void) setPoint:(NSPoint) a
{
	pt = a;
}

- (float) y { return pt.y;}
- (float) x { return pt.x;}

- (void) move:(float) x :(float) y
{
	pt.x += x;
	pt.y += y;
}

- (NSPoint) point { return pt;}

- (BOOL) isEqualToPoint:(NSPoint) a
{
	if( a.x == pt.x && a.y == pt.y) return YES;
	else return NO;
}

- (BOOL) isNearToPoint:(NSPoint) a :(float) scale :(float) ratio
{
	if( a.x >= pt.x - NEAR / scale && a.x <= pt.x + NEAR / scale && a.y >= pt.y - NEAR / (scale * ratio) && a.y <= pt.y + NEAR / (scale * ratio)) return YES;
	else return NO;
}

@end
