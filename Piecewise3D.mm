/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/




#import "Piecewise3D.h"


@implementation Piecewise3D

- (id) init
{
	self = [super init];
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
