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

#import "OSICoalescedROI.h"
#import "OSIROIMask.h"

@implementation OSICoalescedROI

@synthesize sourceROIs = _sourceROIs;

- (id)initWithSourceROIs:(NSArray *)rois homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
    if ( (self = [super init]) ) {
        _sourceROIs = [rois copy];
        _homeFloatVolumeData = [floatVolumeData retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_sourceROIs release];
    _sourceROIs = nil;
    [_homeFloatVolumeData release];
    _homeFloatVolumeData = nil;
    [super dealloc];
}

- (NSString *)name
{
    if ([_sourceROIs count] > 0) {
        return [[_sourceROIs objectAtIndex:0] name];
    }
    return nil;
}

- (NSArray *)convexHull
{
    NSMutableArray *hull;
    OSIROI *roi;
    
    hull = [NSMutableArray array];
    
    for (roi in _sourceROIs) {
        [hull addObjectsFromArray:[roi convexHull]];
    }
    
    return hull;
}

- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume
{
    NSMutableArray *maskRuns;
    OSIROI *roi;
    
    maskRuns = [NSMutableArray array];
    
    for (roi in _sourceROIs) {
        [maskRuns addObjectsFromArray:[[roi ROIMaskForFloatVolumeData:floatVolume] maskRuns]];
    }
    
    return [[[OSIROIMask alloc] initWithMaskRuns:maskRuns] autorelease];
}

- (NSArray *)osiriXROIs
{
    NSMutableArray *rois;
    OSIROI *roi;
    
    rois = [NSMutableArray array];
    
    for (roi in _sourceROIs) {
        [rois addObjectsFromArray:[roi osiriXROIs]];
    }
    
    return rois;
}

- (OSIFloatVolumeData *)homeFloatVolumeData // the volume data on which the ROI was drawn
{
	return _homeFloatVolumeData;
}

//- (void)drawPlane:(N3Plane)plane inCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform


@end
