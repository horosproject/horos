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
#import "OSIFloatVolumeData.h"
#import "CPRGenerator.h"
#import "CPRGeneratorRequest.h"
#import "CPRVolumeData.h"

@interface OSIPlanarBrushROI ()

@end

@implementation OSIPlanarBrushROI (Private)

- (id)initWithOsiriXROI:(ROI *)roi pixToDICOMTransfrom:(N3AffineTransform)pixToDICOMTransfrom homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
	NSMutableArray *hullPoints;
    NSInteger i;
    NSInteger j;
    N3AffineTransform volumeTransform;
    float* mask;
	
	if ( (self = [super init]) ) {
		_osiriXROI = [roi retain];
		
		_plane = N3PlaneApplyTransform(N3PlaneZZero, pixToDICOMTransfrom);
        [self setHomeFloatVolumeData:floatVolumeData];
		
		if ([roi type] == tPlain) {
            hullPoints = [[NSMutableArray alloc] init];
            
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureUpLeftCornerX, roi.textureUpLeftCornerY, 0), pixToDICOMTransfrom)]];
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureUpLeftCornerX, roi.textureDownRightCornerY, 0), pixToDICOMTransfrom)]];
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureDownRightCornerX, roi.textureUpLeftCornerY, 0), pixToDICOMTransfrom)]];
            [hullPoints addObject:[NSValue valueWithN3Vector:N3VectorApplyTransform(N3VectorMake(roi.textureDownRightCornerX, roi.textureDownRightCornerY, 0), pixToDICOMTransfrom)]];
            _convexHull = hullPoints;
            
            mask = malloc(roi.textureWidth * roi.textureHeight * sizeof(float));
            memset(mask, 0, roi.textureWidth * roi.textureHeight * sizeof(float));
            
            for (j = 0; j < roi.textureHeight; j++) {
                for (i = 0; i < roi.textureWidth; i++) {
                    mask[j*roi.textureWidth + i] = ((float)roi.textureBuffer[j*roi.textureWidth + i])/255.0;
                }
            }
            volumeTransform = N3AffineTransformConcat(N3AffineTransformInvert(pixToDICOMTransfrom), N3AffineTransformMakeTranslation(-roi.textureUpLeftCornerX, -roi.textureUpLeftCornerY, 0));
            _brushMask = [[OSIFloatVolumeData alloc] initWithFloatBytesNoCopy:mask pixelsWide:roi.textureWidth pixelsHigh:roi.textureHeight pixelsDeep:1 volumeTransform:volumeTransform outOfBoundsValue:0 freeWhenDone:YES];
        } else {
			[self autorelease];
			self = nil;
		}
	}
	return self;
}


@end


@implementation OSIPlanarBrushROI

- (void)dealloc
{
    [_osiriXROI release];
    _osiriXROI = nil;
    [_brushMask release];
    _brushMask = nil;
    [_convexHull release];
    _convexHull = nil;
    
    [super dealloc];
}

- (NSString *)name
{
	return [_osiriXROI name];
}

- (NSArray *)convexHull
{
    return _convexHull;
}

- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume
{
    CPRObliqueSliceGeneratorRequest *request;
    CPRVolumeData *volume;
    OSIROIMask *roiMask;
    N3AffineTransform sliceToDicomTransform;
    N3Vector planePixelPoint;
    
    // make sure floatVolume's z direction is perpendicular to the plane
    assert(N3VectorLength(N3VectorCrossProduct(N3VectorApplyTransformToDirectionalVector(_plane.normal, floatVolume.volumeTransform), N3VectorMake(0, 0, 1))) < 0.0001);
    
    planePixelPoint = N3VectorApplyTransform(_plane.point, floatVolume.volumeTransform);
    sliceToDicomTransform = N3AffineTransformInvert(N3AffineTransformConcat([floatVolume volumeTransform], N3AffineTransformMakeTranslation(0, 0, -planePixelPoint.z)));
    
    request = [[[CPRObliqueSliceGeneratorRequest alloc] init] autorelease];
    request.sliceToDicomTransform = sliceToDicomTransform;
    request.pixelsWide = floatVolume.pixelsWide;
    request.pixelsHigh = floatVolume.pixelsHigh;
    request.interpolationMode = CPRInterpolationModeNearestNeighbor;
    
    volume = [CPRGenerator synchronousRequestVolume:request volumeData:_brushMask];    
    roiMask = [OSIROIMask ROIMaskFromVolumeData:(OSIFloatVolumeData *)volume];
    
#if CGFLOAT_IS_DOUBLE
    return [roiMask ROIMaskByTranslatingByX:0 Y:0 Z:round(planePixelPoint.z)];
#else
    return [roiMask ROIMaskByTranslatingByX:0 Y:0 Z:roundf(planePixelPoint.z)];
#endif

}

- (void)drawSlab:(OSISlab)slab inCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform
{
	double dicomToPixGLTransform[16];
	
	if (OSISlabContainsPlane(slab, _plane) == NO) {
		return; // this ROI does not live on this slice
	}
    
    N3AffineTransformGetOpenGLMatrixd(dicomToPixTransform, dicomToPixGLTransform);
	
    
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glMultMatrixd(dicomToPixGLTransform);
    
    glLineWidth(3.0);    
    
    // let's try drawing some the mask
    OSIROIMask *mask;
    NSArray *maskRuns;
    OSIROIMaskRun maskRun;
    NSValue *maskRunValue;
    N3AffineTransform inverseVolumeTransform;
    N3Vector lineStart;
    N3Vector lineEnd;
    
    inverseVolumeTransform = N3AffineTransformInvert([[self homeFloatVolumeData] volumeTransform]);
    mask = [self ROIMaskForFloatVolumeData:[self homeFloatVolumeData]];
    maskRuns = [mask maskRuns];
    
    glColor3f(1, 0, 1);
    glBegin(GL_LINES);
    for (maskRunValue in maskRuns) {
        maskRun = [maskRunValue OSIROIMaskRunValue];
        
        lineStart = N3VectorMake(maskRun.widthRange.location, maskRun.heightIndex + 0.5, maskRun.depthIndex);
        lineEnd = N3VectorMake(NSMaxRange(maskRun.widthRange), maskRun.heightIndex + 0.5, maskRun.depthIndex);
        
        lineStart = N3VectorApplyTransform(lineStart, inverseVolumeTransform);
        lineEnd = N3VectorApplyTransform(lineEnd, inverseVolumeTransform);
        
        glVertex3d(lineStart.x, lineStart.y, lineStart.z);
        glVertex3d(lineEnd.x, lineEnd.y, lineEnd.z);
    }
    glEnd();
    
    glPopMatrix();
}


- (NSSet *)osiriXROIs
{
	return [NSSet setWithObject:_osiriXROI];
}



@end




















