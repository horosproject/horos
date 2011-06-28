//
//  CPRStraightenedView.m
//  OsiriX
//
//  Created by Joël Spaltenstein on 6/4/11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "CPRStretchedView.h"
#import "CPRGeneratorRequest.h"
#import "CPRVolumeData.h"
#import "DCMPix.h"
#import "CPRCurvedPath.h"
#import "CPRDisplayInfo.h"
#import "N3BezierPath.h"
#import "CPRMPRDCMView.h"
#import "N3Geometry.h"
#import "N3BezierCoreAdditions.h"
#import "CPRController.h"
#import "ROI.h"
#import "Notifications.h"
#import "StringTexture.h"
#import "NSColor+N2.h"

#define _extraWidthFactor 1.2

@interface CPRStretchedView ()

@property (nonatomic, readwrite, retain) CPRVolumeData *curvedVolumeData; // the volume data that was generated
@property (nonatomic, readwrite, retain) CPRStretchedGeneratorRequest *lastRequest;
@property (nonatomic, readonly) N3BezierPath *centerlinePath;

+ (NSInteger)_fusionModeForCPRViewClippingRangeMode:(CPRViewClippingRangeMode)clippingRangeMode;

- (void)_setNeedsNewRequest;
- (void)_sendNewRequestIfNeeded;
- (void)_sendNewRequest;

- (void)_sendWillEditCurvedPath;
- (void)_sendDidUpdateCurvedPath;
- (void)_sendDidEditCurvedPath;

- (void)_sendWillEditDisplayInfo;
- (void)_sendDidEditDisplayInfo;

- (void)_updateGeneratedHeight;

- (N3BezierPath *)_generateCenterlinePathAndProjectedLength:(CGFloat *)projectedLength;

@end


@implementation CPRStretchedView


@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;
@synthesize curvedPath = _curvedPath;
@synthesize displayInfo = _displayInfo;
@synthesize curvedVolumeData = _curvedVolumeData;
@synthesize clippingRangeMode = _clippingRangeMode;
@synthesize lastRequest = _lastRequest;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    _generator.delegate = nil;
    [_generator release];
    _generator = nil;
    [_volumeData release];
    _volumeData = nil;
    [_curvedVolumeData release];
    _curvedVolumeData = nil;
    [_curvedPath release];
    _curvedPath = nil;
    [_displayInfo release];
    _displayInfo = nil;
    [_lastRequest release];
    _lastRequest = nil;
    [_centerlinePath release];
    _centerlinePath = nil;
    
    [super dealloc];
}

- (void)mouseDraggedWindowLevel:(NSEvent *)event
{
	[super mouseDraggedWindowLevel: event];
	
	[[self windowController] propagateWLWW: self];
}

- (void)setVolumeData:(CPRVolumeData *)volumeData
{
    if (volumeData != _volumeData) {
        _generator.delegate = nil;
        [_generator release];
        [_volumeData release];
        _volumeData = [volumeData retain];
        _generator = [[CPRGenerator alloc] initWithVolumeData:_volumeData];
        _generator.delegate = self;
        [self _setNeedsNewRequest];
    }
}

- (void)setCurvedPath:(CPRCurvedPath *)curvedPath
{
    if (curvedPath != _curvedPath) {
        [_curvedPath release];
        _curvedPath = [curvedPath copy];
        [self _setNeedsNewRequest];
        [self setNeedsDisplay:YES];
    }
}

- (void)setDisplayInfo:(CPRDisplayInfo *)dispalyInfo
{
	assert(dispalyInfo); // doesn't really need to be the case, but for debugging 
    if (dispalyInfo != _displayInfo) {
        [_displayInfo release];
        _displayInfo = [dispalyInfo copy];
        [self setNeedsDisplay:YES];
    }
}

- (void)setClippingRangeMode:(CPRViewClippingRangeMode)mode
{
    if (mode != _clippingRangeMode) {
        _clippingRangeMode = mode;
        
        if (curDCM) {
            [self setFusion:[[self class] _fusionModeForCPRViewClippingRangeMode:_clippingRangeMode] :self.curvedVolumeData.pixelsDeep];
        }
        [self _setNeedsNewRequest];
    }
}

- (void)setFrame:(NSRect)frameRect
{
    BOOL needsUpdate;
    
    needsUpdate = NO;
	if( NSEqualRects( frameRect, [self frame]) == NO) {
        needsUpdate = YES;
    }
    
    [super setFrame: frameRect];
    
    if (needsUpdate) {
        [self _setNeedsNewRequest];
	}
}

- (CGFloat)generatedHeight
{
    return _generatedHeight;
}


- (void)drawRect:(NSRect)rect
{
	if( rect.size.width > 10)
	{
		_processingRequest = YES;
		[self _sendNewRequestIfNeeded];
		_processingRequest = NO;    
		
//		[self _adjustROIs];
		
		[super drawRect: rect];
	}
}

- (void)setNeedsDisplay:(BOOL)flag
{
    if (_processingRequest == NO) {
        [super setNeedsDisplay:flag];
    }
}

- (void)subDrawRect:(NSRect)rect
{
    double pixToSubdrawRectOpenGLTransform[16];
 	CGFloat pixelsPerMm;
    CGFloat pheight_2;
	NSInteger i;
    N3Vector endpoint;
    N3BezierPath *centerline;
    CGLContextObj cgl_ctx;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];    
	glEnable(GL_BLEND);
	glEnable(GL_POLYGON_SMOOTH);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
    
    centerline = [self centerlinePath];
    pixelsPerMm = (CGFloat)curDCM.pwidth/_centerlineProjectedLength;
    pheight_2 = (CGFloat)curDCM.pheight/2.0;
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    N3AffineTransformGetOpenGLMatrixd([self pixToSubDrawRectTransform], pixToSubdrawRectOpenGLTransform);
    glMultMatrixd(pixToSubdrawRectOpenGLTransform);    
    // draw the centerline.
    
    glColor3f(0, 1, 0);
    glBegin(GL_LINE_STRIP);
    for (i = 0; i < [centerline elementCount]; i++) {
        [centerline elementAtIndex:i control1:NULL control2:NULL endpoint:&endpoint];
        endpoint.y *= pixelsPerMm;
        endpoint.y += pheight_2;
        glVertex2d(endpoint.x, endpoint.y);
    }
    glEnd();
    
    glPopMatrix();
 
    // the centerline is a series of point, maybe even ideally saved as a CPRBezierPath
    
    
	// Red Square
	if( [[self window] firstResponder] == self && stringID == nil)
	{
		glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
		glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
		
		glColor4d(1.0, 0, 0.0, 1.0);
		
		float heighthalf = drawingFrameRect.size.height/2;
		float widthhalf = drawingFrameRect.size.width/2;
		
		glLineWidth(8.0);
		glBegin(GL_LINE_LOOP);
        glVertex2f(  -widthhalf, -heighthalf);
        glVertex2f(  -widthhalf, heighthalf);
        glVertex2f(  widthhalf, heighthalf);
        glVertex2f(  widthhalf, -heighthalf);
		glEnd();
	}
	
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);	
}


- (void)generator:(CPRGenerator *)generator didGenerateVolume:(CPRVolumeData *)volume request:(CPRGeneratorRequest *)request
{
	if( [self windowController] == nil)
		return;
    
    NSUInteger i;
    NSMutableArray *pixArray;
    DCMPix *newPix;
	CPRVolumeDataInlineBuffer inlineBuffer;
    
    [self _updateGeneratedHeight];
	
	NSPoint previousOrigin = [self origin];
	float previousScale = [self scaleValue];
	float previousRotation = [self rotation];
	int previousHeight = [curDCM pheight], previousWidth = [curDCM pwidth];
	NSData *previousROIs = [NSArchiver archivedDataWithRootObject: [self curRoiList]];
	
	[[self.curvedVolumeData retain] autorelease]; // make sure this is around long enough so that it doesn't disapear under the old DCMPix
    self.curvedVolumeData = volume;
    
    pixArray = [[NSMutableArray alloc] init];
    
    // blow away local caches of overlay lines
    [_centerlinePath release];
    _centerlinePath = nil;
    _centerlinePath = 0;
    
    for (i = 0; i < self.curvedVolumeData.pixelsDeep; i++)
	{
		if ([self.curvedVolumeData aquireInlineBuffer:&inlineBuffer]) {
			newPix = [[DCMPix alloc] initWithData:(float *)CPRVolumeDataFloatBytes(&inlineBuffer) + (i*self.curvedVolumeData.pixelsWide*self.curvedVolumeData.pixelsHigh) :32 
												 :self.curvedVolumeData.pixelsWide :self.curvedVolumeData.pixelsHigh :self.curvedVolumeData.pixelSpacingX :self.curvedVolumeData.pixelSpacingY
												 :0.0 :0.0 :0.0 :NO];
		} else {
			assert(0);
			newPix = [[DCMView alloc] init];
		}
		[self.curvedVolumeData releaseInlineBuffer:&inlineBuffer];
        
		[newPix setImageObj: [[[self windowController] originalPix] imageObj]];
		[newPix setSrcFile: [[[self windowController] originalPix] srcFile]];
		[newPix setAnnotationsDictionary: [[[self windowController] originalPix] annotationsDictionary]];
		
		
		[pixArray addObject:newPix];
        [newPix release];
    }
	
	if( [pixArray count])
	{
		for( i = 0; i < [pixArray count]; i++)
			[[pixArray objectAtIndex: i] setArrayPix:pixArray :i];
		
		[self setPixels:pixArray files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
		[self setScaleValueCentered: 0.8];
		
		//[self setWLWW:wl :ww];
		[[self windowController] propagateWLWW: [[self windowController] mprView1]];
		
		[self setFusion:[[self class] _fusionModeForCPRViewClippingRangeMode:_clippingRangeMode] :self.curvedVolumeData.pixelsDeep];
		
		if( previousWidth == [curDCM pwidth] && previousHeight == [curDCM pheight])
		{
			[self setOrigin:previousOrigin];
			[self setScaleValue: previousScale];
			[self setRotation: previousRotation];
		}
		
		NSArray *roiArray = [NSUnarchiver unarchiveObjectWithData: previousROIs];
		for( ROI *r in roiArray)
		{
			r.pix = curDCM;
			[r setOriginAndSpacing :curDCM.pixelSpacingX : curDCM.pixelSpacingY :NSMakePoint( curDCM.originX, curDCM.originY) :NO :NO];
			[r setRoiFont: labelFontListGL :labelFontListGLSize :self];
		}
		
		[[self curRoiList] addObjectsFromArray: roiArray];
		
		[self setNeedsDisplay:YES];
	}
	[pixArray release];
}

- (void)generator:(CPRGenerator *)generator didAbandonRequest:(CPRGeneratorRequest *)request
{
}

- (void)waitUntilPixUpdate
{
	[self _sendNewRequestIfNeeded];
	[_generator runUntilAllRequestsAreFinished];
}

- (N3BezierPath*)centerlinePath
{
    if (_centerlinePath == nil) {
        _centerlinePath = [[self _generateCenterlinePathAndProjectedLength:&_centerlineProjectedLength] retain];
    }
    
    return _centerlinePath;
}

+ (NSInteger)_fusionModeForCPRViewClippingRangeMode:(CPRViewClippingRangeMode)clippingRangeMode
{
    switch (clippingRangeMode) {
        case CPRViewClippingRangeVRMode:
            return 0; // not supported
            break;
        case CPRViewClippingRangeMIPMode:
            return 2;
            break;
        case CPRViewClippingRangeMinIPMode:
            return 3;
            break;
        case CPRViewClippingRangeMeanMode:
            return 1;
            break;
        default:
            NSLog(@"%s asking for invalid clipping range mode: %d", __func__,  clippingRangeMode);
            return 0;
            break;
    }
}

- (void)_sendWillEditCurvedPath
{
	if (_editingCurvedPathCount == 0) {
		if ([_delegate respondsToSelector:@selector(CPRViewWillEditCurvedPath:)]) {
			[_delegate CPRViewWillEditCurvedPath:self];
		}
	}
	_editingCurvedPathCount++;
}

- (void)_sendDidUpdateCurvedPath
{
	if ([_delegate respondsToSelector:@selector(CPRViewDidUpdateCurvedPath:)]) {
		[_delegate CPRViewDidUpdateCurvedPath:self];
	}
}

- (void)_sendDidEditCurvedPath
{
	_editingCurvedPathCount--;
	if (_editingCurvedPathCount == 0) {
		if ([_delegate respondsToSelector:@selector(CPRViewDidEditCurvedPath:)]) {
			[_delegate CPRViewDidEditCurvedPath:self];
		}
	}
}

- (void)_sendWillEditDisplayInfo
{
	if ([_delegate respondsToSelector:@selector(CPRViewWillEditDisplayInfo:)]) {
		[_delegate CPRViewWillEditDisplayInfo:self];
	}
}

- (void)_sendDidEditDisplayInfo
{
	if ([_delegate respondsToSelector:@selector(CPRViewDidEditDisplayInfo:)]) {
		[_delegate CPRViewDidEditDisplayInfo:self];
	}
}

- (void)_sendNewRequest
{
    CPRStretchedGeneratorRequest *request;
    N3Vector curveDirection;
    N3Vector baseNormal;
    
    if ([_curvedPath.bezierPath elementCount] >= 3)
	{
        request = [[CPRStretchedGeneratorRequest alloc] init];
        
        request.pixelsWide = [self bounds].size.width*_extraWidthFactor;
        request.pixelsHigh = [self bounds].size.height*_extraWidthFactor;
		request.slabWidth = _curvedPath.thickness;
        
        request.slabSampleDistance = 0;
        request.bezierPath = _curvedPath.bezierPath;
        request.projectionMode = _clippingRangeMode;
        curveDirection = N3VectorSubtract([_curvedPath.bezierPath vectorAtEnd], [_curvedPath.bezierPath vectorAtStart]);
        baseNormal = N3VectorNormalize(N3VectorCrossProduct(_curvedPath.baseDirection, curveDirection));
        request.projectionNormal = N3VectorApplyTransform(baseNormal, N3AffineTransformMakeRotationAroundVector(_curvedPath.angle, curveDirection));
        request.midHeightPoint = N3VectorLerp([_curvedPath.bezierPath topBoundingPlaneForNormal:request.projectionNormal].point, 
                                              [_curvedPath.bezierPath bottomBoundingPlaneForNormal:request.projectionNormal].point, 0.5);
        //        request.vertical = NO;
        
        if ([_lastRequest isEqual:request] == NO) {
			if (request.slabWidth < 2) {
				CPRVolumeData *curvedVolume;
				curvedVolume = [CPRGenerator synchronousRequestVolume:request volumeData:_generator.volumeData];
				
				[_generator runUntilAllRequestsAreFinished];
				[self generator:nil didGenerateVolume:curvedVolume request:request];
			} else {
				[_generator requestVolume:request];
			}
			self.lastRequest = request;
        }
        
        [request release];
    }
	else
	{
		[self setPixels: nil files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
	}
	
    _needsNewRequest = NO;
}

- (void)_setNeedsNewRequest
{
    _needsNewRequest = YES;
    [self setNeedsDisplay:YES];
    //	if (_needsNewRequest == NO) {
    //		[self performSelector:@selector(_sendNewRequestIfNeeded) withObject:nil afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    //	}
    //    _needsNewRequest = YES;
}

- (void)_sendNewRequestIfNeeded
{
    if (_needsNewRequest) {
        [self _sendNewRequest];
    }
}

- (void)_updateGeneratedHeight
{
    CGFloat newGeneratedHeight;
    
    newGeneratedHeight = ([_curvedPath.bezierPath length] / NSWidth(self.bounds)) * NSHeight(self.bounds);
    
    if (newGeneratedHeight != _generatedHeight) {
        _generatedHeight = newGeneratedHeight;
        if ([_delegate respondsToSelector:@selector(CPRViewDidChangeGeneratedHeight:)]) {
            [_delegate CPRViewDidChangeGeneratedHeight:self];
        }        
    }
}

// the ditances in the centerline point will corespond to, x - pixels generated horizonatally, y - distance from the midline in mm, z - relative distance along the original bezier path
- (N3BezierPath *)_generateCenterlinePathAndProjectedLength:(CGFloat *)projectedLength;
{
    NSInteger pixelsWide;
    NSUInteger numVectors;
    N3Vector midHeightPoint;
    N3Vector curveDirection;
    N3Vector baseNormal;
    N3Vector projectionNormal;
    N3BezierCoreRef flattenedBezierCore;
    N3BezierCoreRef projectedBezierCore;
    CGFloat projectedBezierLength;
    CGFloat sampleSpacing;
    N3VectorArray vectors;
    CGFloat *relativePositions;
    N3MutableBezierPath *centerlinePath;
    N3Vector newPoint;
    NSInteger i;

    // figure out how many horizonatal pixels we will have
    pixelsWide = [self bounds].size.width*_extraWidthFactor;
    curveDirection = N3VectorSubtract([_curvedPath.bezierPath vectorAtEnd], [_curvedPath.bezierPath vectorAtStart]);
    baseNormal = N3VectorNormalize(N3VectorCrossProduct(_curvedPath.baseDirection, curveDirection));
    projectionNormal = N3VectorApplyTransform(baseNormal, N3AffineTransformMakeRotationAroundVector(_curvedPath.angle, curveDirection));
    projectionNormal = N3VectorNormalize(projectionNormal);
    midHeightPoint = N3VectorLerp([_curvedPath.bezierPath topBoundingPlaneForNormal:projectionNormal].point, 
                                  [_curvedPath.bezierPath bottomBoundingPlaneForNormal:projectionNormal].point, 0.5);
    
    flattenedBezierCore = N3BezierCoreCreateFlattenedCopy([_curvedPath.bezierPath N3BezierCore], N3BezierDefaultFlatness);
    projectedBezierCore = N3BezierCoreCreateCopyProjectedToPlane(flattenedBezierCore, N3PlaneMake(N3VectorZero, projectionNormal));
    projectedBezierLength = N3BezierCoreLength(projectedBezierCore);
    sampleSpacing = projectedBezierLength / (CGFloat)pixelsWide;

    vectors = malloc(sizeof(N3Vector) * pixelsWide);
    relativePositions = malloc(sizeof(CGFloat) * pixelsWide);
    
    numVectors = N3BezierCoreGetProjectedVectorInfo(flattenedBezierCore, sampleSpacing, 0, projectionNormal, vectors, NULL, NULL, relativePositions, pixelsWide);
    
    if (numVectors > 0) {
        while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
            vectors[numVectors] = vectors[numVectors - 1];
            relativePositions[numVectors] = relativePositions[numVectors - 1];
            numVectors++;
        }
    } else { // there are no vectors at all to copy from, so just zero out everthing
        while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
            vectors[numVectors] = N3VectorZero;
            relativePositions[numVectors] = 0;
            numVectors++;
        }
    }
    
    
    centerlinePath = [N3MutableBezierPath bezierPath];
    
    if (numVectors) {
        newPoint.x = 0;
        newPoint.y = N3VectorDotProduct(N3VectorSubtract(vectors[0], midHeightPoint), projectionNormal);
        newPoint.y = N3VectorLength(N3VectorProject(N3VectorSubtract(vectors[0], midHeightPoint), projectionNormal));
        newPoint.z = relativePositions[0];
        
        [centerlinePath moveToVector:newPoint];
    }
    
    for (i = 1; i < numVectors; i++) {
        newPoint.x = i;
        newPoint.y = N3VectorDotProduct(N3VectorSubtract(vectors[i], midHeightPoint), projectionNormal);
        newPoint.z = relativePositions[i];
        
        [centerlinePath lineToVector:newPoint];
    }
    
    N3BezierCoreRelease(flattenedBezierCore);
    N3BezierCoreRelease(projectedBezierCore);
    free(vectors);
    free(relativePositions);
    
    if (projectedLength) {
        *projectedLength = projectedBezierLength;
    }
    
    return centerlinePath;
}


@end










