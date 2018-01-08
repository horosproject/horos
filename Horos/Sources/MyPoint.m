/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/




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
