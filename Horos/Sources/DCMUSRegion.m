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

#import "DCMUSRegion.h"

@implementation DCMUSRegion

// Accessors (getters & setters)
@synthesize regionSpatialFormat, regionDataType, regionFlags;

@synthesize regionLocationMinX0, regionLocationMinY0, regionLocationMaxX1, regionLocationMaxY1;

@synthesize referencePixelX0, referencePixelY0;

@synthesize physicalUnitsXDirection, physicalUnitsYDirection;

@synthesize refPixelPhysicalValueX, refPixelPhysicalValueY;

@synthesize physicalDeltaX, physicalDeltaY;

@synthesize dopplerCorrectionAngle;

@synthesize isReferencePixelX0Present, isReferencePixelY0Present;


// Methods
-(NSString*)toString {
    NSMutableString *result = [NSMutableString stringWithCapacity:256];

    [result appendFormat:@"regionSpatialFormat=%@ ", [[NSNumber numberWithInt: regionSpatialFormat] stringValue]];
    [result appendFormat:@"regionDataType=%@ ", [[NSNumber numberWithInt: regionDataType] stringValue]];
    [result appendFormat:@"regionFlags=%@ ", [[NSNumber numberWithInt: regionFlags] stringValue]];
    
    [result appendFormat:@"regionLocationMinX0=%@ ", [[NSNumber numberWithInt: regionLocationMinX0] stringValue]];
    [result appendFormat:@"regionLocationMinY0=%@ ", [[NSNumber numberWithInt: regionLocationMinY0] stringValue]];
    [result appendFormat:@"regionLocationMaxX1=%@ ", [[NSNumber numberWithInt: regionLocationMaxX1] stringValue]];
    [result appendFormat:@"regionLocationMaxY1=%@ ", [[NSNumber numberWithInt: regionLocationMaxY1] stringValue]];
    
    [result appendFormat:@"referencePixelX0=%@ ", [[NSNumber numberWithInt: referencePixelX0] stringValue]];
    [result appendFormat:@"referencePixelY0=%@ ", [[NSNumber numberWithInt: referencePixelY0] stringValue]];

    [result appendFormat:@"physicalUnitsXDirection=%@ ", [[NSNumber numberWithInt: physicalUnitsXDirection] stringValue]];
    [result appendFormat:@"physicalUnitsYDirection=%@ ", [[NSNumber numberWithInt: physicalUnitsYDirection] stringValue]];

    [result appendFormat:@"refPixelPhysicalValueX=%@ ", [[NSNumber numberWithDouble: refPixelPhysicalValueX] stringValue]];
    [result appendFormat:@"refPixelPhysicalValueY=%@ ", [[NSNumber numberWithDouble: refPixelPhysicalValueY] stringValue]];
    
    [result appendFormat:@"physicalDeltaX=%@ ", [[NSNumber numberWithDouble: physicalDeltaX] stringValue]];
    [result appendFormat:@"physicalDeltaY=%@ ", [[NSNumber numberWithDouble: physicalDeltaY] stringValue]];

    [result appendFormat:@"dopplerCorrectionAngle=%@ ", [[NSNumber numberWithDouble: dopplerCorrectionAngle] stringValue]];
    return result;
}

@end
