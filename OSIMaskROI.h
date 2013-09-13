//
//  OSIMaskROI.h
//  OsiriX_Lion
//
//  Created by Joël Spaltenstein on 9/26/12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "OSIROI.h"
#import "OSIROIMask.h"

@interface OSIMaskROI : OSIROI
{
    OSIROIMask *_mask;
    NSString *_name;
    NSColor *_fillColor;
    
    OSISlab _cachedSlab;
    N3AffineTransform _cachedDicomToPixTransform;
    N3Vector _cachedMinCorner;
    NSData *_cachedMaskRunsData;
}

- (id)initWithROIMask:(OSIROIMask *)mask homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData name:(NSString *)name;

@property (nonatomic, readonly, retain) OSIROIMask *mask;

@end
