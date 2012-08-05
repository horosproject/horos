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




#import "Spline3D.h"

@implementation Spline3D

- (id) init
{
	self = [super init];
	xSpline = vtkCardinalSpline::New();
	ySpline = vtkCardinalSpline::New();
	zSpline = vtkCardinalSpline::New();
	computed = NO;
	return self;
}

- (void) dealloc
{
	xSpline->Delete();
	ySpline->Delete();
	zSpline->Delete();

	[super dealloc];
}

- (void) addPoint: (float) t : (Point3D*) p
{
	float x, y, z;
	x = [p x];
	y = [p y];
	z = [p z];
	xSpline->AddPoint(t, x);
	ySpline->AddPoint(t, y);
	zSpline->AddPoint(t, z);
}

- (void) compute
{
	xSpline->Compute();
	ySpline->Compute();
	zSpline->Compute();
	computed = YES;
}

- (Point3D*) evaluateAt: (float) t
{
	if (!computed)
	{
		[self compute];
	}
	
	float x, y, z;
	x = xSpline->Evaluate(t);
	y = ySpline->Evaluate(t);
	z = zSpline->Evaluate(t);
	return [[[Point3D alloc] initWithValues:x :y :z] autorelease];
}

@end
