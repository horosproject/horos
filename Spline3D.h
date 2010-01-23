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




#import <Cocoa/Cocoa.h>
#import "Interpolation3D.h"

#ifdef __cplusplus
#include <vtkCardinalSpline.h>
#else
typedef char* vtkCardinalSpline;
#endif


/** \brief Spline interpolation for FlyThru
*/


@interface Spline3D : Interpolation3D {
	vtkCardinalSpline	*xSpline, *ySpline, *zSpline;
	BOOL				computed;
}

- (id) init;
- (void) compute;

@end