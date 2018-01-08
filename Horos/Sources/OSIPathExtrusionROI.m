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
//  OSIPathExtrusionROI.m
//  OsiriX_Lion
//
//  Created by Joël Spaltenstein on 10/4/12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "OSIPathExtrusionROI.h"
#import "OSIFloatVolumeData.h"
#import "OSIROIMask.h"
#include <OpenGL/CGLMacro.h>

@interface OSIPathExtrusionROI ()
@property (nonatomic, readwrite, retain) N3BezierPath *path;
@property (nonatomic, readwrite, assign) OSISlab slab;
@property (nonatomic, readwrite, retain) NSString *name;
@property (nonatomic, readwrite, retain) NSColor *fillColor;
@property (nonatomic, readwrite, retain) NSColor *strokeColor;
@property (nonatomic, readwrite, assign) CGFloat strokeThickness;

//- (NSData *)_maskRunsDataForSlab:(OSISlab)slab dicomToPixTransform:(N3AffineTransform)dicomToPixTransform minCorner:(N3VectorPointer)minCornerPtr;
@end


@implementation OSIPathExtrusionROI

@synthesize path = _path;
@synthesize slab = _slab;
@synthesize name = _name;

@synthesize fillColor = _fillColor;
@synthesize strokeColor = _strokeColor;
@synthesize strokeThickness = _strokeThickness;

- (id)initWith:(N3BezierPath *)path slab:(OSISlab)slab homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData name:(NSString *)name
{
	if ( (self = [super init]) ) {
        [self setHomeFloatVolumeData:floatVolumeData];
        self.path = path;
        self.slab = slab;
        self.name = name;
        self.strokeThickness = 1;
	}
	return self;
}

- (void)dealloc
{
    self.fillColor = nil;
    self.strokeColor = nil;
    self.path = nil;
    self.name = nil;
    [_cachedMaskRunsData release];
    _cachedMaskRunsData = nil;
    
    [super dealloc];
}

- (NSArray *)convexHull
{
	NSMutableArray *convexHull;
	NSUInteger i;
	N3Vector control1;
	N3Vector control2;
	N3Vector endpoint;
	N3BezierPathElement elementType;
    N3Vector halfNormal = N3VectorScalarMultiply(self.slab.plane.normal, .5);
	
	convexHull = [NSMutableArray array];
	
	for (i = 0; i < [self.path elementCount]; i++) {
		elementType = [self.path elementAtIndex:i control1:&control1 control2:&control2 endpoint:&endpoint];
		switch (elementType) {
			case N3MoveToBezierPathElement:
			case N3LineToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(endpoint, halfNormal)]];
				break;
			case N3CurveToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(control1, halfNormal)]];
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(control2, halfNormal)]];
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(endpoint, halfNormal)]];
				break;
			default:
				break;
		}
	}
    
    halfNormal = N3VectorInvert(halfNormal);
	
    for (i = 0; i < [self.path elementCount]; i++) {
		elementType = [self.path elementAtIndex:i control1:&control1 control2:&control2 endpoint:&endpoint];
		switch (elementType) {
			case N3MoveToBezierPathElement:
			case N3LineToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(endpoint, halfNormal)]];
				break;
			case N3CurveToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(control1, halfNormal)]];
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(control2, halfNormal)]];
				[convexHull addObject:[NSValue valueWithN3Vector:N3VectorAdd(endpoint, halfNormal)]];
				break;
			default:
				break;
		}
	}

	return convexHull;
}

- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume// BS Implementation, need to make this work everywhere!
{
	N3MutableBezierPath *volumeBezierPath;
	N3Vector endpoint;
	NSArray	*intersections;
	NSMutableArray *intersectionNumbers;
	NSMutableArray *ROIRuns;
	OSIROIMaskRun maskRun;
	CGFloat minY;
	CGFloat maxY;
	CGFloat z;
	CGFloat minZ;
	CGFloat maxZ;
	BOOL zSet;
	NSValue *vectorValue;
	NSInteger i;
	NSInteger j;
	NSInteger runStart;
	NSInteger runEnd;
	
    OSISlab transformedSlab = OSISlabApplyTransform(self.slab, floatVolume.volumeTransform);
    
    // make sure floatVolume's z direction is perpendicular to the plane
    assert(N3VectorLength(N3VectorCrossProduct(transformedSlab.plane.normal, N3VectorMake(0, 0, 1))) < 0.01);
    
	volumeBezierPath = [[self.path mutableCopy] autorelease];
    [volumeBezierPath applyAffineTransform:N3AffineTransformConcat(floatVolume.volumeTransform, N3AffineTransformMakeTranslation(0, -.5, 0))];
	[volumeBezierPath flatten:N3BezierDefaultFlatness];
	zSet = NO;
	ROIRuns = [NSMutableArray array];
	minY = CGFLOAT_MAX;
	maxY = -CGFLOAT_MAX;
    z = 0;
	
	for (i = 0; i < [volumeBezierPath elementCount]; i++) {
		[volumeBezierPath elementAtIndex:i control1:NULL control2:NULL endpoint:&endpoint];
#if CGFLOAT_IS_DOUBLE
		endpoint.z = round(endpoint.z);
#else
		endpoint.z = roundf(endpoint.z);
#endif
		[volumeBezierPath setVectorsForElementAtIndex:i control1:N3VectorZero control2:N3VectorZero endpoint:endpoint];
		minY = MIN(minY, endpoint.y);
		maxY = MAX(maxY, endpoint.y);
		
		if (zSet == NO) {
			z = endpoint.z;
			zSet = YES;
		}
		
		assert (endpoint.z == z);
	}
	
	minY = floor(minY);
	maxY = ceil(maxY);
    maskRun = OSIROIMaskRunZero;
	maskRun.depthIndex = z;
    
    if (z < 0 || z >= floatVolume.pixelsDeep) {
        return [[[OSIROIMask alloc] initWithMaskRuns:[NSArray array]] autorelease];
    }
	
    NSMutableData *runData = [[NSMutableData alloc] init];

	for (i = minY; i <= maxY; i++) {
        if (i < 0 || i >= floatVolume.pixelsHigh) {
            continue;
        }
        
		maskRun.heightIndex = i;
		intersections = [volumeBezierPath intersectionsWithPlane:N3PlaneMake(N3VectorMake(0, i, 0), N3VectorMake(0, 1, 0))];
		
		intersectionNumbers = [NSMutableArray array];
		for (vectorValue in intersections) {
			[intersectionNumbers addObject:[NSNumber numberWithDouble:[vectorValue N3VectorValue].x]];
		}
		[intersectionNumbers sortUsingSelector:@selector(compare:)];
		for(j = 0; j+1 < [intersectionNumbers count]; j++, j++) {
			runStart = round([[intersectionNumbers objectAtIndex:j] doubleValue]);
			runEnd = round([[intersectionNumbers objectAtIndex:j+1] doubleValue]);
            
            if (runStart == runEnd || runStart >= (NSInteger)floatVolume.pixelsWide || runEnd < 0) {
                continue;
            }
            
            runStart = MAX(runStart, 0);
            runEnd = MIN(runEnd, floatVolume.pixelsWide - 1);
            
			if (runEnd > runStart) {
				maskRun.widthRange = NSMakeRange(runStart, runEnd - runStart);
                OSIROIMaskRun maskRunCopy = maskRun;
                // look extrude out to the slab
#if CGFLOAT_IS_DOUBLE
                minZ = MAX(round(transformedSlab.plane.point.z-transformedSlab.thickness/2.0), 0);
                maxZ = MIN(round(transformedSlab.plane.point.z+transformedSlab.thickness/2.0), floatVolume.pixelsDeep - 1);
#else
                minZ = MAX(roundf(transformedSlab.plane.point.z-transformedSlab.thickness/2.0f), 0);
                maxZ = MIN(roundf(transformedSlab.plane.point.z+transformedSlab.thickness/2.0f), floatVolume.pixelsDeep - 1);
#endif
                for (z = minZ; z <= maxZ; z++) {
                    maskRunCopy.depthIndex = z;
                    [runData appendBytes:&maskRunCopy length:sizeof(OSIROIMaskRun)];
                }
			}
		}
	}           
	
    OSIROIMask *mask = [[[OSIROIMask alloc] initWithMaskRunData:runData] autorelease];
    [runData release];
    
    return mask;
}

- (void)drawSlab:(OSISlab)slab inCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform
{
	double dicomToPixGLTransform[16];
	NSInteger i;
	N3Vector endpoint;
    N3BezierPath *flattenedPath;
    NSColor *deviceStrokeColor = [self.strokeColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    
    if (self.strokeThickness != 0 && self.strokeColor != nil) {
        N3AffineTransformGetOpenGLMatrixd(dicomToPixTransform, dicomToPixGLTransform);
        
        glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
        glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
        glEnable(GL_LINE_SMOOTH);
        glEnable(GL_POLYGON_SMOOTH);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        glLineWidth(self.strokeThickness);
        glColor4f((float)[deviceStrokeColor redComponent], (float)[deviceStrokeColor greenComponent], (float)[deviceStrokeColor blueComponent], (float)[deviceStrokeColor alphaComponent]);

        N3AffineTransformGetOpenGLMatrixd(dicomToPixTransform, dicomToPixGLTransform);
        
        glMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        glMultMatrixd(dicomToPixGLTransform);
        
        glBegin(GL_LINE_STRIP);
        
        flattenedPath = [_path bezierPathByFlattening:N3BezierDefaultFlatness/5.0];
        for (i = 0; i < [flattenedPath elementCount]; i++) {
            [flattenedPath elementAtIndex:i control1:NULL control2:NULL endpoint:&endpoint];
            glVertex3d(endpoint.x, endpoint.y, endpoint.z);
        }
        
        glEnd();
        
        glPopMatrix();
        
        glDisable(GL_LINE_SMOOTH);
        glDisable(GL_POLYGON_SMOOTH);
        glDisable(GL_POINT_SMOOTH);
        glDisable(GL_BLEND);
    }
}

- (N3BezierPath *)bezierPath
{
    return self.path;
}


@end
