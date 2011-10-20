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

#import "OSIROI.h"
#import "OSIGeometry.h"

@class OSIVolumeData;
@class ROI;

@interface OSIPlanarBrushROI : OSIROI
{
    ROI *_osiriXROI;
    
    OSIFloatVolumeData *_brushMask;
    N3Plane _plane;
    NSArray *_convexHull;
}
@end
