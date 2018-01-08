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

#import "OSIGeometry.h"


OSISlab OSISlabMake(N3Plane plane, CGFloat thickness)
{
    OSISlab slab;
    slab.plane = plane;
    slab.thickness = thickness;
    return slab;
}

bool OSISlabEqualTo(OSISlab slab1, OSISlab slab2)
{
    return N3PlaneEqualToPlane(slab1.plane, slab2.plane) && slab1.thickness == slab2.thickness; 
}

bool OSISlabIsCoincidentToSlab(OSISlab slab1, OSISlab slab2)
{
    return N3PlaneIsCoincidentToPlane(slab1.plane, slab2.plane) && slab1.thickness == slab2.thickness; 
}

bool OSISlabContainsVector(OSISlab slab, N3Vector vector)
{
    return N3VectorDistanceToPlane(vector, slab.plane) - slab.thickness/2.0 <= (CGFLOAT_MIN * 1E5);
}

bool OSISlabContainsPlane(OSISlab slab, N3Plane plane)
{
    return N3PlaneIsParallelToPlane(slab.plane, plane) && OSISlabContainsVector(slab, plane.point);
}

OSISlab OSISlabApplyTransform(OSISlab slab, N3AffineTransform transform)
{
    OSISlab transformedSlab;
    N3Vector topPoint;
    N3Vector transformedTopPoint;
    
    topPoint = N3VectorAdd(slab.plane.point, N3VectorScalarMultiply(N3VectorNormalize(slab.plane.normal), slab.thickness));
    transformedTopPoint = N3VectorApplyTransform(topPoint, transform);
    
    transformedSlab.plane = N3PlaneApplyTransform(slab.plane, transform);
    transformedSlab.thickness = N3VectorDistance(transformedSlab.plane.point, transformedTopPoint);

    return transformedSlab;
}

NSString *NSStringFromOSISlab(OSISlab slab)
{
    return [NSString stringWithFormat:@"{%@, %f}", NSStringFromN3Plane(slab.plane), slab.thickness];
}

CFDictionaryRef OSISlabCreateDictionaryRepresentation(OSISlab slab)
{
	CFDictionaryRef planeDict;
    NSNumber *thicknessNumber;
	CFDictionaryRef slabDict;
	
	planeDict = N3PlaneCreateDictionaryRepresentation(slab.plane);
	thicknessNumber = [NSNumber numberWithDouble:slab.thickness];
	slabDict = (CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:(id)planeDict, @"plane", thicknessNumber, @"thickness", nil];
	CFRelease(planeDict);
	return slabDict;
}

bool OSISlabMakeWithDictionaryRepresentation(CFDictionaryRef dict, OSISlab *slab)
{
	OSISlab tempSlab;
	CFDictionaryRef planeDict;
	CFNumberRef thicknessNumber;
	
	if (dict == NULL) {
		return false;
	}
	
	planeDict = CFDictionaryGetValue(dict, @"plane");
	thicknessNumber = CFDictionaryGetValue(dict, @"thickness");
	
	if (planeDict == NULL || CFGetTypeID(planeDict) != CFDictionaryGetTypeID() ||
		thicknessNumber == NULL || CFGetTypeID(thicknessNumber) != CFNumberGetTypeID()) {
		return false;
	}
	
	if (N3PlaneMakeWithDictionaryRepresentation(planeDict, &(tempSlab.plane)) == false) {
		return false;
	}
    
    CFNumberGetValue(thicknessNumber, kCFNumberCGFloatType, &(tempSlab.thickness));
//	if (CFNumberGetValue(thicknessNumber, kCFNumberCGFloatType, &(tempSlab.thickness)) == false) {
//		return false;
//	}
    
	if (slab) {
		*slab = tempSlab;
	}
	return true;
}

@implementation NSValue (OSIGeometryAdditions)

+ (NSValue *)valueWithOSISlab:(OSISlab)slab
{
    return [NSValue valueWithBytes:&slab objCType:@encode(OSISlab)];
}

- (OSISlab)OSISlabValue
{
    OSISlab slab;
    assert(strcmp([self objCType], @encode(OSISlab)) == 0);
    [self getValue:&slab];
    return slab;
}

@end



