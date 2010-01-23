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




#import "Interpolation3D.h"

// abstract class
@implementation Interpolation3D

- (void) addPoint: (float) t : (Point3D*) p {}
- (Point3D*) evaluateAt: (float) t { return nil;}

@end
