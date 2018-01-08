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





