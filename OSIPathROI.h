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
#import "OSIROI.h"

@class ROI;
@class N3MutableBezierPath;

// for now implement closed poly first

@interface OSIPathROI : OSIROI {
	ROI *_osiriXROI;
	
	N3MutableBezierPath *_bezierPath;
}

- (id)initWithOsiriXROI:(ROI *)roi pixToDICOMTransfrom:(N3AffineTransform)pixToDICOMTransfrom;

@end
