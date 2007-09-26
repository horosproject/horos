//
//  Centerline.h
//  OsiriX
//
//  Created by Lance Pysher on 9/17/07.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
	 
	 
	Centerline extracts the centerline from a volume using thinning
	Use either Volume and extract region or use pointArray
=========================================================================*/

#import <Cocoa/Cocoa.h>


#define id Id
#include "vtkPolyData.h"
#undef id


@class OSIVoxel;
@class WaitRendering;
@interface Centerline : NSObject {
	WaitRendering *_wait;

}

@property (readwrite, retain) WaitRendering *wait;

/// Creates the centerline from a marchingCubes created polygon.
- (NSArray *)generateCenterline:(vtkPolyData *)polyData startingPoint:(OSIVoxel *)start endingPoint:(OSIVoxel *)end;
///Creates a set of all neighbors
- (NSMutableSet *)connectedPointsForPoint:(vtkIdType)pt fromPolyData:(vtkPolyData *)data;

@end
