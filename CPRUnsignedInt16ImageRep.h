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

@interface CPRUnsignedInt16ImageRep : NSImageRep {
    uint16_t *_unsignedInt16Data;
    
    CGFloat _offset;
    CGFloat _slope;
    
    CGFloat _windowWidth;
    CGFloat _windowLevel;
    CGFloat _pixelSpacingX;
    CGFloat _pixelSpacingY;
    CGFloat _sliceThickness;
    
    N3AffineTransform _imageToDicomTransform;
    
    BOOL _freeWhenDone;
}

@property (nonatomic, readwrite, assign) CGFloat windowWidth; // these will affect how this rep will draw when part of an NSImage
@property (nonatomic, readwrite, assign) CGFloat windowLevel;


- (id)initWithData:(uint16_t *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;

- (uint16_t *)unsignedInt16Data;
@property (nonatomic, readwrite, assign) CGFloat offset;
@property (nonatomic, readwrite, assign) CGFloat slope;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingX;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingY;
@property (nonatomic, readwrite, assign) CGFloat sliceThickness;

@property (nonatomic, readwrite, assign) N3AffineTransform imageToDicomTransform;

@end

@interface CPRUnsignedInt16ImageRep (DCMPixAndVolume)

- (void)getOrientation:(float[6])orientation;
- (void)getOrientationDouble:(double[6])orientation;

@property (readonly) float originX;
@property (readonly) float originY;
@property (readonly) float originZ;

@end


