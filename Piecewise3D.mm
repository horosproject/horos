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




#import "Piecewise3D.h"


@implementation Piecewise3D

- (id) init
{
	[super init];
	xPiecewise = vtkPiecewiseFunction::New();
	yPiecewise = vtkPiecewiseFunction::New();
	zPiecewise = vtkPiecewiseFunction::New();
	return self;
}

- (void) dealloc
{
	xPiecewise->Delete();
	yPiecewise->Delete();
	zPiecewise->Delete();
	
	[super dealloc];
}


- (void)finalize {
	xPiecewise->Delete();
	yPiecewise->Delete();
	zPiecewise->Delete();	
	[super finalize];
}


- (void) addPoint: (float) t : (Point3D*) p
{
	float x, y, z;
	x = [p x];
	y = [p y];
	z = [p z];
	xPiecewise->AddPoint(t, x);
	yPiecewise->AddPoint(t, y);
	zPiecewise->AddPoint(t, z);
}

- (Point3D*) evaluateAt: (float) t
{
	float x, y, z;
	x = xPiecewise->GetValue(t);
	y = yPiecewise->GetValue(t);
	z = zPiecewise->GetValue(t);
	return [[[Point3D alloc] initWithValues:x :y :z] autorelease];
}

@end
