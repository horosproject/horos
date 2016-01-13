/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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

#import "OSIPathROI.h"
#import "N3BezierPath.h"
#import "ROI.h"
#import "N3Geometry.h"
#import "MyPoint.h"
#import "DCMView.h"

@implementation OSIPathROI

- (id)initWithOsiriXROI:(ROI *)roi pixToDICOMTransfrom:(N3AffineTransform)pixToDICOMTransfrom
{
	NSPoint point;
	NSArray *pointArray;
	MyPoint *myPoint;
	NSMutableArray *nodes;
	
	if ( (self = [super init]) ) {
		_osiriXROI = [roi retain];
		
		if ([roi type] == tMesure) {
			_bezierPath = [[N3MutableBezierPath alloc] init];
			point = [roi pointAtIndex:0];
			[_bezierPath moveToVector:N3VectorApplyTransform(N3VectorMakeFromNSPoint(point), pixToDICOMTransfrom)];
			point = [roi pointAtIndex:1];
			[_bezierPath lineToVector:N3VectorApplyTransform(N3VectorMakeFromNSPoint(point), pixToDICOMTransfrom)];
		} else if ([roi type] == tOPolygon) {
			pointArray = [roi points];
			
			nodes = [[NSMutableArray alloc] init];
			for (myPoint in pointArray) {
				[nodes addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMakeFromNSPoint([myPoint point]), pixToDICOMTransfrom)]];
			}
			_bezierPath = [[N3MutableBezierPath alloc] initWithNodeArray:nodes style:N3BezierNodeOpenEndsStyle];
			[nodes release];
		} else if ([roi type] == tCPolygon) {
			pointArray = [roi points];
			
			nodes = [[NSMutableArray alloc] init];
			for (myPoint in pointArray) {
				[nodes addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMakeFromNSPoint([myPoint point]), pixToDICOMTransfrom)]];
			}
			_bezierPath = [[N3MutableBezierPath alloc] initWithNodeArray:nodes style:N3BezierNodeOpenEndsStyle];
			[_bezierPath close];
			[nodes release];
		} else {
			[self autorelease];
			self = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[_bezierPath release];
	_bezierPath = nil;
	
	[_osiriXROI release];
	_osiriXROI = nil;
	
	[super dealloc];
}

- (NSString *)name
{
	return [_osiriXROI name];
}

- (NSArray *)convexHull
{
	NSMutableArray *convexHull;
	NSUInteger i;
	N3Vector control1;
	N3Vector control2;
	N3Vector endpoint;
	N3BezierPathElement elementType;
	
	convexHull = [NSMutableArray array];
	
	for (i = 0; i < [_bezierPath elementCount]; i++) {
		elementType = [_bezierPath elementAtIndex:i control1:&control1 control2:&control2 endpoint:&endpoint];
		switch (elementType) {
			case N3MoveToBezierPathElement:
			case N3LineToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:endpoint]];
				break;
			case N3CurveToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:control1]];
				[convexHull addObject:[NSValue valueWithN3Vector:control2]];
				[convexHull addObject:[NSValue valueWithN3Vector:endpoint]];
				break;
			default:
				break;
		}
	}
	
	return convexHull;
}

@end






















