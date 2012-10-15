//
//  OSIMaskROI.m
//  OsiriX_Lion
//
//  Created by Joël Spaltenstein on 9/26/12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "OSIMaskROI.h"
#import "CPRGenerator.h"
#import "CPRGeneratorRequest.h"
#import "OSIFloatVolumeData.h"
#include <OpenGL/CGLMacro.h>

@interface OSIMaskROI ()
@property (nonatomic, readwrite, retain) OSIROIMask *mask;
@property (nonatomic, readwrite, retain) NSString *name;
@property (nonatomic, readwrite, retain) NSColor *color;
//- (NSData *)_maskRunsDataForSlab:(OSISlab)slab dicomToPixTransform:(N3AffineTransform)dicomToPixTransform minCorner:(N3VectorPointer)minCornerPtr;
@end

@implementation OSIMaskROI

@synthesize mask = _mask;
@synthesize name = _name;
@synthesize color = _color;

- (id)initWithROIMask:(OSIROIMask *)mask homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData name:(NSString *)name
{
	if ( (self = [super init]) ) {
        [self setHomeFloatVolumeData:floatVolumeData];
        self.mask = mask;
        self.name = name;
	}
	return self;
}

- (void)dealloc
{
    self.mask = nil;
    self.name = nil;
    [_cachedMaskRunsData release];
    _cachedMaskRunsData = nil;

    [super dealloc];
}

- (NSArray *)convexHull
{
    return [self.mask convexHull];
}

- (OSIROIMask *)ROIMaskForFloatVolumeData:(OSIFloatVolumeData *)floatVolume
{
    assert(floatVolume == self.homeFloatVolumeData);
    
    return self.mask;
}

- (void)drawSlab:(OSISlab)slab inCGLContext:(CGLContextObj)cgl_ctx pixelFormat:(CGLPixelFormatObj)pixelFormat dicomToPixTransform:(N3AffineTransform)dicomToPixTransform
{
    if (self.color == nil) {
        return;
    }
    
    double dicomToPixGLTransform[16];
	    
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
    
    glColor4f((float)[self.color redComponent], (float)[self.color greenComponent], (float)[self.color blueComponent], (float)[self.color alphaComponent]);
//    glColor4f(1, 0, 1, .5);
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
//{
//    OSIROIMaskRun maskRun;
//    NSValue *maskRunValue;
//    NSData *maskRunsData;
//    N3Vector minCorner;
//    NSInteger i;
//    NSInteger runsCount;
//    const OSIROIMaskRun *maskRunsBytes;
//    double widthIndex;
//    double maxWidthIndex;
//    double heightIndex;
//    double depthIndex;
//    
//    if (_cachedMaskRunsData && OSISlabEqualTo(slab, _cachedSlab) && N3AffineTransformEqualToTransform(dicomToPixTransform, _cachedDicomToPixTransform)) {
//        maskRunsData = _cachedMaskRunsData;
//        minCorner = _cachedMinCorner;
//    } else {
//        [_cachedMaskRunsData release];
//        _cachedMaskRunsData = [[self _maskRunsDataForSlab:slab dicomToPixTransform:dicomToPixTransform minCorner:&_cachedMinCorner] retain];
//        _cachedSlab = slab;
//        _cachedDicomToPixTransform = dicomToPixTransform;
//        maskRunsData = _cachedMaskRunsData;
//        minCorner = _cachedMinCorner;
//    }
//    
//    
//    glLineWidth(3.0);
//    
//    glColor4f(1, 0, 0, .4);
//    glBegin(GL_QUADS);
//    runsCount = [maskRunsData length] / sizeof(OSIROIMaskRun);
//    maskRunsBytes = [maskRunsData bytes];
//    for (i = 0; i < runsCount; i++) {
//        maskRun = maskRunsBytes[i];
//        widthIndex = (double)maskRun.widthRange.location + minCorner.x;
//        maxWidthIndex = widthIndex + (double)maskRun.widthRange.length;
//        heightIndex = (double)maskRun.heightIndex + minCorner.y;
//        depthIndex = maskRun.depthIndex;
//        
//        glVertex3d(widthIndex, heightIndex, depthIndex);
//        glVertex3d(maxWidthIndex, heightIndex, depthIndex);
//        glVertex3d(maxWidthIndex, heightIndex + 1.0, depthIndex);
//        glVertex3d(widthIndex, heightIndex + 1.0, depthIndex);
//    }
//    glEnd();
//}

//- (NSData *)_maskRunsDataForSlab:(OSISlab)slab dicomToPixTransform:(N3AffineTransform)dicomToPixTransform minCorner:(N3VectorPointer)minCornerPtr;
//{
//    CPRVolumeData *floatVolumeData;
//    float *bytes;
//    N3Vector corner;
//    N3Vector minCorner;
//    N3Vector maxCorner;
//    N3AffineTransform coalescedVolumeMaskToPixTransform;
//    NSInteger width;
//    NSInteger height;
//    CPRObliqueSliceGeneratorRequest *sliceRequest;
//    OSIROIMask *sliceMask;
//    
//    minCorner = N3VectorMake(CGFLOAT_MAX, CGFLOAT_MAX, 0);
//    maxCorner = N3VectorMake(-CGFLOAT_MAX, -CGFLOAT_MAX, 0);
//    coalescedVolumeMaskToPixTransform = N3AffineTransformConcat(N3AffineTransformInvert(self.homeFloatVolumeData.volumeTransform), dicomToPixTransform);
//    
//    // first off figure out where this float volume needs to be
//    corner = N3VectorApplyTransform(N3VectorMake(0,                                          0,                                          0), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    corner = N3VectorApplyTransform(N3VectorMake(self.homeFloatVolumeData.pixelsWide, 0,                                          0), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    corner = N3VectorApplyTransform(N3VectorMake(0,                                          self.homeFloatVolumeData.pixelsHigh, 0), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    corner = N3VectorApplyTransform(N3VectorMake(self.homeFloatVolumeData.pixelsWide, self.homeFloatVolumeData.pixelsHigh, 0), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    corner = N3VectorApplyTransform(N3VectorMake(0,                                          0,                                          self.homeFloatVolumeData.pixelsDeep), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    corner = N3VectorApplyTransform(N3VectorMake(self.homeFloatVolumeData.pixelsWide, 0,                                          self.homeFloatVolumeData.pixelsDeep), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    corner = N3VectorApplyTransform(N3VectorMake(0,                                          self.homeFloatVolumeData.pixelsDeep, self.homeFloatVolumeData.pixelsDeep), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    corner = N3VectorApplyTransform(N3VectorMake(self.homeFloatVolumeData.pixelsWide, self.homeFloatVolumeData.pixelsDeep, self.homeFloatVolumeData.pixelsDeep), coalescedVolumeMaskToPixTransform);
//    minCorner.x = MIN(minCorner.x, corner.x); minCorner.y = MIN(minCorner.y, corner.y);
//    maxCorner.x = MAX(maxCorner.x, corner.x); maxCorner.y = MAX(maxCorner.y, corner.y);
//    
//    minCorner.x = floor(minCorner.x) - 1;
//    minCorner.y = floor(minCorner.y) - 1;
//    maxCorner.x = ceil(maxCorner.x) + 1;
//    maxCorner.y = ceil(maxCorner.y) + 1;
//    
//    
//    width = maxCorner.x - minCorner.x;
//    height = maxCorner.y - minCorner.y;
//    
//    sliceRequest = [[[CPRObliqueSliceGeneratorRequest alloc] init] autorelease];
//    sliceRequest.pixelsWide = width;
//    sliceRequest.pixelsHigh = height;
//    sliceRequest.slabWidth = slab.thickness;
//    sliceRequest.projectionMode = CPRProjectionModeMIP;
//    
//    sliceRequest.sliceToDicomTransform = N3AffineTransformConcat(N3AffineTransformMakeTranslation(minCorner.x, minCorner.y, 0), N3AffineTransformInvert(dicomToPixTransform));
//    
//    floatVolumeData = [CPRGenerator synchronousRequestVolume:sliceRequest volumeData:self.coalescedROIMaskVolumeData];
//    sliceMask = [OSIROIMask ROIMaskFromVolumeData:(OSIFloatVolumeData *)floatVolumeData];
//    
//    if (minCornerPtr) {
//        *minCornerPtr = minCorner;
//    }
//    
//    return [sliceMask maskRunsData];
//}

@end
