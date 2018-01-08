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

#import "OSIPlanarPathROI.h"
#import "N3BezierPath.h"
#import "ROI.h"
#import "N3Geometry.h"
#import "MyPoint.h"
#import "DCMView.h"
#import "OSIFloatVolumeData.h"
#import "OSIROIMask.h"
#import "OSIROI.h"
#import "MyPoint.h"

@interface OSIPlanarPathROI ()

@end

@implementation OSIPlanarPathROI (Private)

- (id)initWithOsiriXROI:(ROI *)roi pixToDICOMTransfrom:(N3AffineTransform)pixToDICOMTransfrom homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData
{
	NSPoint point;
	NSArray *pointArray;
	MyPoint *myPoint;
	NSMutableArray *nodes;
    NSMutableArray *tempPointArray;
    NSInteger i;
	
	if ( (self = [super init]) ) {
		_osiriXROI = [roi retain];
		        
		_plane = N3PlaneApplyTransform(N3PlaneZZero, pixToDICOMTransfrom);
        [self setHomeFloatVolumeData:floatVolumeData];
		
		if ([roi type] == tMesure && [[roi points] count] > 1) {
			_bezierPath = [[N3MutableBezierPath alloc] init];
			point = [roi pointAtIndex:0];
			[_bezierPath moveToVector:N3VectorApplyTransform(N3VectorMakeFromNSPoint(point), pixToDICOMTransfrom)];
			point = [roi pointAtIndex:1];
			[_bezierPath lineToVector:N3VectorApplyTransform(N3VectorMakeFromNSPoint(point), pixToDICOMTransfrom)];
		} else if ([roi type] == tOPolygon) {
			pointArray = [roi points];
            
//            if ([pointArray count] <= 1 || [[pointArray objectAtIndex:0] isEqualToPoint:[[pointArray objectAtIndex:1] point]]) {
//                return nil;
//            }
			
			nodes = [[NSMutableArray alloc] init];
			for (myPoint in pointArray) {
				[nodes addObject:[NSValue valueWithN3Vector:N3VectorMakeFromNSPoint([myPoint point])]];
			}
			_bezierPath = [[N3MutableBezierPath alloc] initWithNodeArray:nodes style:N3BezierNodeEndsMeetStyle];
            if ([_bezierPath elementCount]) {
				[_bezierPath close];
			}
            [_bezierPath applyAffineTransform:pixToDICOMTransfrom];
			[nodes release];
		} else if ([roi type] == tCPolygon || [roi type] == tOval || [roi type] == tPencil) {
			pointArray = [roi points];
            
            if ([roi type] == tOval && [pointArray count] >= 2 && [[pointArray objectAtIndex:0] isEqualToPoint:[[pointArray objectAtIndex:1] point]]) {
                tempPointArray = [NSMutableArray array];
                point = [[pointArray objectAtIndex:0] point];
                [tempPointArray addObject:[MyPoint point:point]];
                point.x += 1;
                [tempPointArray addObject:[MyPoint point:point]];
                point.y += 1;
                [tempPointArray addObject:[MyPoint point:point]];
                point.x -= 1;
                [tempPointArray addObject:[MyPoint point:point]];
                pointArray = tempPointArray;
            }
            
//            if ([pointArray count] <= 1 || [[pointArray objectAtIndex:0] isEqualToPoint:[[pointArray objectAtIndex:1] point]]) {
//                return nil;
//            }
			
			nodes = [[NSMutableArray alloc] init];
			for (myPoint in pointArray) {
				[nodes addObject:[NSValue valueWithN3Vector:N3VectorMakeFromNSPoint([myPoint point])]];
			}
            if ([pointArray count] > 1) {
                [nodes addObject:[nodes objectAtIndex:0]];
            }
			_bezierPath = [[N3MutableBezierPath alloc] initWithNodeArray:nodes style:N3BezierNodeEndsMeetStyle];
			if ([_bezierPath elementCount]) {
				[_bezierPath close];
			}
            [_bezierPath applyAffineTransform:pixToDICOMTransfrom];
			[nodes release];
        } else if ([roi type] == tROI) {
			pointArray = [roi points];
        
            if ([pointArray count] == 0) {
                [self autorelease];
                return nil;
            }
            
            _bezierPath = [[N3MutableBezierPath alloc] init];
            [_bezierPath moveToVector:N3VectorMakeFromNSPoint([[pointArray objectAtIndex:0] point])];
            
            for (i = 1; i < [pointArray count]; i++) {
                [_bezierPath lineToVector:N3VectorMakeFromNSPoint([[pointArray objectAtIndex:i] point])];
            }
            
            if ([_bezierPath elementCount]) {
                [_bezierPath close];
            }
            [_bezierPath applyAffineTransform:pixToDICOMTransfrom];
		} else {
			[self autorelease];
			self = nil;
		}
	}
	return self;
}

@end


@implementation OSIPlanarPathROI


- (void)dealloc
{
	[_bezierPath release];
	_bezierPath = nil;
	
	[_osiriXROI release];
	_osiriXROI = nil;
	
	[super dealloc];
}

- (NSString *)name
{
	return [_osiriXROI name];
}

- (NSArray *)convexHull
{
	NSMutableArray *convexHull;
	NSUInteger i;
	N3Vector control1;
	N3Vector control2;
	N3Vector endpoint;
	N3BezierPathElement elementType;
	
	convexHull = [NSMutableArray array];
	
	for (i = 0; i < [_bezierPath elementCount]; i++) {
		elementType = [_bezierPath elementAtIndex:i control1:&control1 control2:&control2 endpoint:&endpoint];
		switch (elementType) {
			case N3MoveToBezierPathElement:
			case N3LineToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:endpoint]];
				break;
			case N3CurveToBezierPathElement:
				[convexHull addObject:[NSValue valueWithN3Vector:control1]];
				[convexHull addObject:[NSValue valueWithN3Vector:control2]];
				[convexHull addObject:[NSValue valueWithN3Vector:endpoint]];
				break;
			default:
				break;
		}
	}
	
	return convexHull;
}

- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume
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
	BOOL zSet;
	NSValue *vectorValue;
	NSInteger i;
	NSInteger j;
	NSInteger runStart;
	NSInteger runEnd;
	
    // make sure floatVolume's z direction is perpendicular to the plane
    assert(N3VectorLength(N3VectorCrossProduct(N3VectorApplyTransformToDirectionalVector(_plane.normal, floatVolume.volumeTransform), N3VectorMake(0, 0, 1))) < 0.0001);
        
	volumeBezierPath = [[_bezierPath mutableCopy] autorelease];
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
                [ROIRuns addObject:[NSValue valueWithOSIROIMaskRun:maskRun]];
			}
//			j++;
		}
	}
	
    return [[[OSIROIMask alloc] initWithMaskRuns:ROIRuns] autorelease];

//	if ([ROIRuns count] > 0) {
//		return [[[OSIROIMask alloc] initWithMaskRuns:ROIRuns] autorelease];
//	} else {
//		return nil;
//	}
}

- (N3BezierPath *)bezierPath
{
    return _bezierPath;
}

- (NSSet *)osiriXROIs
{
	return [NSSet setWithObject:_osiriXROI];
}

- (void)drawSlab:(OSISlab)slab inCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform
{
	double dicomToPixGLTransform[16];
	NSInteger i;
	N3Vector endpoint;
    N3BezierPath *flattenedPath;
	
	if (OSISlabContainsPlane(slab, _plane) == NO) {
		return; // this ROI does not live on this slice
	}

    N3AffineTransformGetOpenGLMatrixd(dicomToPixTransform, dicomToPixGLTransform);
	
    flattenedPath = [_bezierPath bezierPathByFlattening:N3BezierDefaultFlatness/5.0];
    
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glMultMatrixd(dicomToPixGLTransform);
    
    glLineWidth(3.0);
    glColor3f(1, 0, 0);
    glBegin(GL_LINE_STRIP);
    for (i = 0; i < [flattenedPath elementCount]; i++) {
        [flattenedPath elementAtIndex:i control1:NULL control2:NULL endpoint:&endpoint];
        glVertex3d(endpoint.x, endpoint.y, endpoint.z);
    }   
    glEnd();
    
    
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

@end




















