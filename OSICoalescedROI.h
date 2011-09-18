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

@interface OSICoalescedROI : OSIROI {
    NSArray *_sourceROIs;
    OSIFloatVolumeData *_homeFloatVolumeData;
}

- (id)initWithSourceROIs:(NSArray *)rois homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData;

@property (readonly, copy) NSArray *sourceROIs;

@end
