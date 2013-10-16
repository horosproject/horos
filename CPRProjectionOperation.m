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

#import "CPRProjectionOperation.h"
#include <Accelerate/Accelerate.h>
#import "CPRVolumeData.h"

@implementation CPRProjectionOperation

@synthesize volumeData = _volumeData;
@synthesize generatedVolume = _generatedVolume;
@synthesize projectionMode = _projectionMode;

- (id)init
{
    if ( (self = [super init]) ) {
        _projectionMode = CPRProjectionModeNone;
    }
    return self;
}

- (void)dealloc
{
    [_volumeData release];
    _volumeData = nil;
    [_generatedVolume release];
    _generatedVolume = nil;
    [super dealloc];
}

- (void)main
{
    float *floatBytes;
    NSInteger i;
    float floati;
    NSInteger pixelsPerPlane;
	N3AffineTransform volumeTransform;
	CPRVolumeDataInlineBuffer inlineBuffer;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        if ([self isCancelled]) {
            return;
        }
        
		if (_projectionMode == CPRProjectionModeNone) {
			_generatedVolume = [_volumeData retain];
			return;
		}
		
		pixelsPerPlane = _volumeData.pixelsWide * _volumeData.pixelsHigh;
		floatBytes = malloc(sizeof(float) * pixelsPerPlane);
				
		if ([_volumeData aquireInlineBuffer:&inlineBuffer]) {
			memcpy(floatBytes, CPRVolumeDataFloatBytes(&inlineBuffer), sizeof(float) * pixelsPerPlane);
			switch (_projectionMode) {
				case CPRProjectionModeMIP:
					for (i = 1; i < _volumeData.pixelsDeep; i++) {
						if ([self isCancelled]) {
							break;
						}
						vDSP_vmax(floatBytes, 1, (float *)CPRVolumeDataFloatBytes(&inlineBuffer) + (i * pixelsPerPlane), 1, floatBytes, 1, pixelsPerPlane);
					}
					break;
				case CPRProjectionModeMinIP:
					for (i = 1; i < _volumeData.pixelsDeep; i++) {
						if ([self isCancelled]) {
							break;
						}					
						vDSP_vmin(floatBytes, 1, (float *)CPRVolumeDataFloatBytes(&inlineBuffer) + (i * pixelsPerPlane), 1, floatBytes, 1, pixelsPerPlane);
					}
					break;
				case CPRProjectionModeMean:
					for (i = 1; i < _volumeData.pixelsDeep; i++) {
						if ([self isCancelled]) {
							break;
						}					
						floati = i;
						vDSP_vavlin((float *)CPRVolumeDataFloatBytes(&inlineBuffer) + (i * pixelsPerPlane), 1, &floati, floatBytes, 1, pixelsPerPlane);
					}
					break;
				default:
					break;
			}
		}
		[_volumeData releaseInlineBuffer:&inlineBuffer];
        
		volumeTransform = N3AffineTransformConcat(_volumeData.volumeTransform, N3AffineTransformMakeScale(1.0, 1.0, 1.0/(CGFloat)_volumeData.pixelsDeep));
        _generatedVolume = [[CPRVolumeData alloc] initWithFloatBytesNoCopy:floatBytes pixelsWide:_volumeData.pixelsWide pixelsHigh:_volumeData.pixelsHigh pixelsDeep:1
                                                           volumeTransform:volumeTransform outOfBoundsValue:_volumeData.outOfBoundsValue freeWhenDone:YES];
    }
    @catch (...) {
    }
    @finally {
        [pool release];
    }
}

@end





