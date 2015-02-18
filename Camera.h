/*=========================================================================
  Program:   OsiriX

  Copyright(c) OsiriX Team
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

#import <Cocoa/Cocoa.h>
#import "Point3D.h"
#import "N3Geometry.h"

/** \brief Describes a 3D view state
*
* Camera saves the state of a 3D View to manage the vtkCamera, cropping planes
* window width and level, and 4D movie index
*/

@interface Camera : NSObject {
	Point3D *position, *viewUp, *focalPoint;
    NSMutableArray *croppingPlanes;
	float clippingRangeNear, clippingRangeFar, viewAngle, eyeAngle, parallelScale, rollAngle;
	NSImage *previewImage;
	float wl, ww, fusionPercentage, windowCenterX, windowCenterY;
	BOOL is4D;
	long movieIndexIn4D;
	int index;
	float LOD;
	BOOL forceUpdate;
}


@property int index;
@property (readwrite, copy) Point3D *position;
@property (readwrite, copy) Point3D *focalPoint;
@property (readwrite, copy) Point3D *viewUp;
@property (readwrite, copy) NSMutableArray *croppingPlanes;
@property (readwrite, copy) NSImage *previewImage;
@property BOOL is4D, forceUpdate;
@property float viewAngle, rollAngle;
@property float eyeAngle;
@property float parallelScale;
@property float clippingRangeNear;
@property float clippingRangeFar;
@property float ww, LOD, wl;
@property float fusionPercentage;
@property long movieIndexIn4D;
@property float windowCenterX, windowCenterY;

- (id)init;
- (id)initWithCamera:(Camera *)c;

- (void)setClippingRangeFrom:(float)near To:(float)far;

// window level
- (void)setWLWW:(float)newWl :(float)newWw;


- (NSMutableDictionary *)exportToXML;
- (id)initWithDictionary:(NSDictionary *)xml;
@end
