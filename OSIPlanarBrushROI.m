//
//  OSIPlanarBrushROI.m
//  OsiriX_Lion
//
//  Created by Joël Spaltenstein on 9/26/11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "OSIPlanarBrushROI.h"
#import "OSIROI+Private.h"
#import "OSIROIMask.h"
#import "ROI.h"
#import "DCMView.h"
#import "OSIGeometry.h"

@interface OSIPlanarBrushROI ()

- (void)_rebuildMask;

@end

@implementation OSIPlanarBrushROI (Private)

- (id)initWithOsiriXROI:(ROI *)roi pixToDICOMTransfrom:(N3AffineTransform)pixToDICOMTransfrom homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
	NSMutableArray *hullPoints;
	
	if ( (self = [super init]) ) {
		_osiriXROI = [roi retain];
		
		_plane = N3PlaneApplyTransform(N3PlaneZZero, pixToDICOMTransfrom);
		_homeFloatVolumeData = [floatVolumeData retain];
		
		if ([roi type] == tPlain) {
            hullPoints = [[NSMutableArray alloc] init];
            
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureUpLeftCornerX, roi.textureUpLeftCornerY, 0), pixToDICOMTransfrom)]];
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureUpLeftCornerX, roi.textureDownRightCornerY, 0), pixToDICOMTransfrom)]];
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureDownRightCornerX, roi.textureUpLeftCornerY, 0), pixToDICOMTransfrom)]];
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureDownRightCornerX, roi.textureDownRightCornerY, 0), pixToDICOMTransfrom)]];
            _convexHull = hullPoints;
        } else {
			[self release];
			self = nil;
		}
	}
	return self;
}

//if (type == tPlain)
//{
//    textureWidth = [[coder decodeObject] intValue];
//    [[coder decodeObject] intValue];	// Keep it for backward compatibility & compatibility with encoder
//    textureHeight = [[coder decodeObject] intValue];
//    [[coder decodeObject] intValue];	// Keep it for backward compatibility & compatibility with encoder
//    
//    textureUpLeftCornerX = [[coder decodeObject] intValue];
//    textureUpLeftCornerY = [[coder decodeObject] intValue];
//    textureDownRightCornerX = [[coder decodeObject] intValue];
//    textureDownRightCornerY = [[coder decodeObject] intValue];
//    
//    textureBuffer=(unsigned char*)malloc(textureWidth*textureHeight*sizeof(unsigned char));
//    
//    @try
//    {
//        unsigned char* pointerBuff=(unsigned char*)[[coder decodeObject] bytes];
//        
//        for( int j=0; j<textureHeight; j++ )
//        {
//            for( int i=0; i<textureWidth; i++ )
//                textureBuffer[i+j*textureWidth]=pointerBuff[i+j*textureWidth];
//        }
//    }
//    @catch (NSException * e)
//    {
//    }
//}
//


@end


@implementation OSIPlanarBrushROI

- (NSArray *)convexHull
{
    return _convexHull;
}

- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume
{
    if (_roiMask == nil) {
        [self _rebuildMask];
    }
    return _roiMask;
}

- (void)_rebuildMask
{
//    assert(_roiMask) 
}

@end




















