/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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
#import <Cocoa/Cocoa.h>
#import "N3Geometry.h"


#ifndef _OSIGEOMETRY_H_
#define _OSIGEOMETRY_H_

#ifdef __OBJC__
#import <Foundation/NSValue.h>
@class NSString;
#endif

CF_EXTERN_C_BEGIN

struct OSISlab {
    N3Plane plane;
    CGFloat thickness;
};
typedef struct OSISlab OSISlab;
 
OSISlab OSISlabMake(N3Plane plane, CGFloat thickness);
bool OSISlabEqualTo(OSISlab slab1, OSISlab slab2);
bool OSISlabIsCoincidentToSlab(OSISlab slab1, OSISlab slab2);
bool OSISlabContainsVector(OSISlab slab, N3Vector vector);
bool OSISlabContainsPlane(OSISlab slab, N3Plane plane);
OSISlab OSISlabApplyTransform(OSISlab slab, N3AffineTransform transform);

CFDictionaryRef OSISlabCreateDictionaryRepresentation(OSISlab slab);
bool OSISlabMakeWithDictionaryRepresentation(CFDictionaryRef dict, OSISlab *slab);

CF_EXTERN_C_END

#ifdef __OBJC__

NSString *NSStringFromOSISlab(OSISlab slab);

/** NSValue support. **/

@interface NSValue (OSIGeometryAdditions)

+ (NSValue *)valueWithOSISlab:(OSISlab)slab;
- (OSISlab)OSISlabValue;

@end

#endif /* __OBJC__ */

#endif /* SIGEOMETRY_H_ */

