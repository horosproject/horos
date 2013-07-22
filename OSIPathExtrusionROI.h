//
//  OSIPathExtrusionROI.h
//  OsiriX_Lion
//
//  Created by Joël Spaltenstein on 10/4/12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "OSIROI.h"
#import "N3BezierPath.h"
#import "OSIGeometry.h"

@interface OSIPathExtrusionROI : OSIROI
{
    N3BezierPath *_path;
    OSISlab _slab;
    NSString *_name;
    
    NSColor *_fillColor;
    NSColor *_strokeColor;
    CGFloat _strokeThickness;
    
    OSISlab _cachedSlab;
    N3AffineTransform _cachedDicomToPixTransform;
    N3Vector _cachedMinCorner;
    NSData *_cachedMaskRunsData;
}

- (id)initWith:(N3BezierPath *)path slab:(OSISlab)slab homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData name:(NSString *)name;

@property (nonatomic, readonly, retain) N3BezierPath *bezierPath;

@end
