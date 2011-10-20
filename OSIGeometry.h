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

