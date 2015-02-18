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

#import <Cocoa/Cocoa.h>
#import "N3Geometry.h"
#import "CPRVolumeData.h"

@class CPRVolumeData;

// This operation will fill out floatBytes from the given data. FloatBytes is assumed to be tightly packed float image of width "width" and height "height"
// float bytes will be filled in with values at vectors and each successive scan line will be filled with with values at vector+normal*scanlineNumber
@interface CPRHorizontalFillOperation : NSOperation {
    CPRVolumeData *_volumeData;
    
    float *_floatBytes;
    NSUInteger _width;
    NSUInteger _height;
        
    N3VectorArray _vectors;
    N3VectorArray _normals;
    
    CPRInterpolationMode _interpolationMode;
}

// vectors and normals need to be arrays of length width
- (id)initWithVolumeData:(CPRVolumeData *)volumeData interpolationMode:(CPRInterpolationMode)interpolationMode floatBytes:(float *)floatBytes width:(NSUInteger)width height:(NSUInteger)height vectors:(N3VectorArray)vectors normals:(N3VectorArray)normals;

@property (readonly, retain) CPRVolumeData *volumeData;

@property (readonly, assign) float *floatBytes;
@property (readonly, assign) NSUInteger width;
@property (readonly, assign) NSUInteger height;

@property (readonly, assign) N3VectorArray vectors;
@property (readonly, assign) N3VectorArray normals;

@property (readonly, assign) CPRInterpolationMode interpolationMode; // YES by default

@end
