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

#import "OSICoalescedPlanarROI.h"
#import "OSIROIMask.h"

@implementation OSICoalescedPlanarROI

@synthesize sourceROIs = _sourceROIs;

- (id)initWithSourceROIs:(NSArray *)rois homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
    if ( (self = [super init]) ) {
        _sourceROIs = [rois copy];
        [self setHomeFloatVolumeData:floatVolumeData];
    }
    
    return self;
}

- (void)dealloc
{
    [_sourceROIs release];
    _sourceROIs = nil;
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

- (NSSet *)osiriXROIs
{
    OSIROI *roi;
    NSMutableSet *osirixROIs;
    
    osirixROIs = [NSMutableSet setWithCapacity:[_sourceROIs count]];
    
    for (roi in _sourceROIs) {
        [osirixROIs unionSet:[roi osiriXROIs]];
    }
    
    return osirixROIs;
}

- (void)setHomeFloatVolumeData:(OSIFloatVolumeData *)homeFloatVolumeData
{
    OSIROI *roi;

    for (roi in _sourceROIs) {
        [roi setHomeFloatVolumeData:homeFloatVolumeData];
    }
    [super setHomeFloatVolumeData:homeFloatVolumeData];
}

//- (void)drawPlane:(N3Plane)plane inCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform


@end
