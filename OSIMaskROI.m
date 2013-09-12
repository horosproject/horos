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
@property (nonatomic, readwrite, retain) NSColor *fillColor;
//- (NSData *)_maskRunsDataForSlab:(OSISlab)slab dicomToPixTransform:(N3AffineTransform)dicomToPixTransform minCorner:(N3VectorPointer)minCornerPtr;
@end

@implementation OSIMaskROI

@synthesize mask = _mask;
@synthesize name = _name;
@synthesize fillColor = _fillColor;

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
    self.fillColor = nil;
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
    if (self.fillColor == nil) {
        return;
    }
    
    NSColor *deviceColor = [self.fillColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    
    double dicomToPixGLTransform[16];
	    
    N3AffineTransformGetOpenGLMatrixd(dicomToPixTransform, dicomToPixGLTransform);
	
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
    glEnable(GL_POINT_SMOOTH);
    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_POLYGON_SMOOTH);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
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
    N3Vector quad1;
    N3Vector quad2;
    N3Vector quad3;
    N3Vector quad4;
    
    inverseVolumeTransform = N3AffineTransformInvert([[self homeFloatVolumeData] volumeTransform]);
    mask = [self ROIMaskForFloatVolumeData:[self homeFloatVolumeData]];
    maskRuns = [mask maskRuns];
    
    glColor4f((float)[deviceColor redComponent], (float)[deviceColor greenComponent], (float)[deviceColor blueComponent], (float)[deviceColor alphaComponent]);
//    glColor4f(1, 0, 1, .5);
    for (maskRunValue in maskRuns) {

        maskRun = [maskRunValue OSIROIMaskRunValue];
        
        quad1 = N3VectorMake(maskRun.widthRange.location, maskRun.heightIndex, maskRun.depthIndex);
        quad2 = N3VectorMake(maskRun.widthRange.location, maskRun.heightIndex + 1.0, maskRun.depthIndex);
        quad3 = N3VectorMake(NSMaxRange(maskRun.widthRange), maskRun.heightIndex, maskRun.depthIndex);
        quad4 = N3VectorMake(NSMaxRange(maskRun.widthRange), maskRun.heightIndex + 1.0, maskRun.depthIndex);
        
        quad1 = N3VectorApplyTransform(quad1, inverseVolumeTransform);
        quad2 = N3VectorApplyTransform(quad2, inverseVolumeTransform);
        quad3 = N3VectorApplyTransform(quad3, inverseVolumeTransform);
        quad4 = N3VectorApplyTransform(quad4, inverseVolumeTransform);
        
        glBegin(GL_TRIANGLE_STRIP);
        glVertex3d(quad1.x, quad1.y, quad1.z);
        glVertex3d(quad2.x, quad2.y, quad2.z);
        glVertex3d(quad3.x, quad3.y, quad3.z);
        glVertex3d(quad4.x, quad4.y, quad4.z);
        glEnd();
    }
    
    glPopMatrix();
    
    glDisable(GL_LINE_SMOOTH);
    glDisable(GL_POLYGON_SMOOTH);
    glDisable(GL_POINT_SMOOTH);
    glDisable(GL_BLEND);

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
