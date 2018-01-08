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
//  CPRStretchedView.m
//  OsiriX
//
//  Created by Joël Spaltenstein on 6/4/11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "options.h"

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
#import <objc/runtime.h>

static float deg2rad = M_PI / 180.0f; 

#define _extraWidthFactor 1.2

extern BOOL frameZoomed;
extern int splitPosition[ 3];

@interface _CPRStretchedViewPlaneRun : NSObject
{
    NSRange _range;
    NSMutableArray *_distances;
}

@property (nonatomic, readwrite, assign) NSRange range;
@property (nonatomic, readwrite, retain) NSMutableArray *distances;

@end

@interface N3BezierPath (CPRStretchedViewPlaneRunAdditions)
- (id)initWithCPRStretchedViewPlaneRun:(_CPRStretchedViewPlaneRun *)planeRun heightPixelsPerMm:(CGFloat)pixelsPerMm;
@end

@implementation _CPRStretchedViewPlaneRun

@synthesize range = _range;
@synthesize distances = _distances;

- (id)init
{
    if ( (self = [super init]) ) {
		_distances = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_distances release];
    _distances = nil;
    [super dealloc];
}

@end


@interface CPRStretchedView ()

@property (nonatomic, readwrite, retain) CPRVolumeData *curvedVolumeData; // the volume data that was generated
@property (nonatomic, readwrite, retain) CPRStretchedGeneratorRequest *lastRequest;
@property (nonatomic, readwrite, assign) BOOL drawAllNodes;
@property (nonatomic, readwrite, retain) N3BezierPath *centerlinePath;

+ (NSInteger)_fusionModeForCPRViewClippingRangeMode:(CPRViewClippingRangeMode)clippingRangeMode;

- (void)_sendNewRequestIfNeeded;
- (void)_sendNewRequest;

- (void)_sendWillEditCurvedPath;
- (void)_sendDidUpdateCurvedPath;
- (void)_sendDidEditCurvedPath;

- (void)_sendWillEditDisplayInfo;
- (void)_sendDidEditDisplayInfo;

- (void)_updateGeneratedHeight;

- (N3BezierPath *)_projectedBezierPathFromStretchedGeneratorRequest:(CPRStretchedGeneratorRequest *)generatorRequest;

- (void)_drawVerticalLines:(NSArray *)verticalLines;
- (void)_drawVerticalLines:(NSArray *)verticalLines length:(CGFloat)length;

- (void)_updateMousePlanePointsForViewPoint:(NSPoint)point; // this will modify _mousePlanePointsInPix and _displayInfo
- (CGFloat)_distanceToPoint:(NSPoint)point onVerticalLines:(NSArray *)verticalLines pixVector:(N3VectorPointer)closestPixVectorPtr volumeVector:(N3VectorPointer)volumeVectorPtr;
- (CGFloat)_distanceToPoint:(NSPoint)point onPlaneRuns:(NSArray *)planeRuns pixVector:(N3VectorPointer)closestPixVectorPtr volumeVector:(N3VectorPointer)volumeVectorPtr;

- (void)_drawPlaneRuns:(NSArray*)planeRuns;
- (NSArray *)_runsForPlane:(N3Plane)plane verticalLineIndexes:(NSArray **)verticalLinesHandle;
- (void)_buildVerticalLinesAndPlaneRunsForPlaneFullName:(NSString *)planeFullName;
- (void)_clearAllPlanes;
- (void)_planeSetter:(N3Plane)plane;
- (N3Plane)_planeGetter;
- (void)_slabThicknessSetter:(CGFloat)thickness;
- (CGFloat)_slabThicknessGetter;
- (void)_planeColorSetter:(NSColor *)color;
- (NSColor *)_planeColorGetter;
- (void)_buildTransverseVerticalLinesAndPlaneRuns;
- (void)_clearTransversePlanes;
- (N3Vector)_centerlinePixVectorForRelativePosition:(CGFloat)relativePosition;
- (CGFloat)_relativePositionForPixPoint:(NSPoint)pixPoint;
- (CGFloat)_relativePositionForIndex:(NSInteger)index;
- (N3Vector)_vectorForPixPoint:(NSPoint)pixPoint;
- (_CPRStretchedViewPlaneRun *)_limitedRunForRelativePosition:(CGFloat)relativePosition verticalLineIndex:(NSUInteger *)verticalLinePointer lengthFromCenterline:(CGFloat)length;

// calls for dealing with intersections with planes

- (void)_pushBezierPath:(CGFloat)distance;

- (void)_osirixUpdateVolumeDataNotification:(NSNotification *)notification;

@end

@implementation CPRStretchedView

@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;
@synthesize curvedPath = _curvedPath;
@synthesize displayInfo = _displayInfo;
@synthesize curvedVolumeData = _curvedVolumeData;
@synthesize clippingRangeMode = _clippingRangeMode;
@synthesize lastRequest = _lastRequest;
@synthesize drawAllNodes = _drawAllNodes;
@dynamic orangePlane;
@dynamic purplePlane;
@dynamic bluePlane;
@dynamic orangeSlabThickness;
@dynamic purpleSlabThickness;
@dynamic blueSlabThickness;
@dynamic orangePlaneColor;
@dynamic purplePlaneColor;
@dynamic bluePlaneColor;
@synthesize displayTransverseLines = _displayTransverseLines;
@synthesize displayCrossLines = _displayCrossLines;
@synthesize centerlinePath = _centerlinePath;

+ (BOOL)resolveInstanceMethod:(SEL)selector
{
    NSString *methodName;
    IMP imp;
    const char* typeEncoding;
    SEL proxySelector;
    
    methodName = NSStringFromSelector(selector);
    proxySelector = NULL;
    
    if ([methodName hasPrefix:@"get"] == NO && [methodName hasPrefix:@"set"] == NO) {
        if ([methodName hasSuffix:@"Plane"]) {
            proxySelector = @selector(_planeGetter);
        } else if ([methodName hasSuffix:@"SlabThickness"]) {
            proxySelector = @selector(_slabThicknessGetter);
        } else if ([methodName hasSuffix:@"PlaneColor"]) {
            proxySelector = @selector(_planeColorGetter);
        }
    } else if ([methodName hasPrefix:@"set"]) {
        if ([methodName hasSuffix:@"Plane:"]) {
            proxySelector = @selector(_planeSetter:);
        } else if ([methodName hasSuffix:@"SlabThickness:"]) {
            proxySelector = @selector(_slabThicknessSetter:);
        } else if ([methodName hasSuffix:@"PlaneColor:"]) {
            proxySelector = @selector(_planeColorSetter:);
        }
    }
    
    if (proxySelector) {
        imp = class_getMethodImplementation([self class], proxySelector);
        typeEncoding = method_getTypeEncoding(class_getInstanceMethod([self class], proxySelector));
        return class_addMethod([self class], selector, imp, typeEncoding);
    }
    
    return [super resolveInstanceMethod:selector];
}

- (void)setDisplayCrossLines:(BOOL)displayCrossLines
{
	if (displayCrossLines != _displayCrossLines) {
        _displayCrossLines = displayCrossLines;
        if (_displayCrossLines == NO) {
            [self _clearAllPlanes];
        }
        
        [self setNeedsDisplay:YES];
        [[self windowController] updateToolbarItems];
    }
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _planes = [[NSMutableDictionary alloc] init];
        _slabThicknesses = [[NSMutableDictionary alloc] init];
        _verticalLines = [[NSMutableDictionary alloc] init];
        _planeRuns = [[NSMutableDictionary alloc] init];
        _planeColors = [[NSMutableDictionary alloc] init];
		_mousePlanePointsInPix = [[NSMutableDictionary alloc] init];
        _transverseVerticalLines = [[NSMutableDictionary alloc] init];
		_transversePlaneRuns = [[NSMutableDictionary alloc] init];
        _displayCrossLines = NO;
        _displayTransverseLines = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_osirixUpdateVolumeDataNotification:) name:OsirixUpdateVolumeDataNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

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
    [_planes release];
    _planes = nil;
    [_slabThicknesses release];
    _slabThicknesses = nil;
    [_verticalLines release];
    _verticalLines = nil;
    [_planeRuns release];
    _planeRuns = nil;
    [_planeColors release];
    _planeColors = nil;
    [_transverseVerticalLines release];
    _transverseVerticalLines = nil;
    [_transversePlaneRuns release];
    _transversePlaneRuns = nil;
    
	[self _clearAllPlanes];
	
	[_mousePlanePointsInPix release];
	_mousePlanePointsInPix = nil;
    
    [stanStringAttrib release];
	[stringTexA release];
	[stringTexB release];
	[stringTexC release];
	    
    [super dealloc];
}

- (id)valueForKey:(NSString *)key
{
    NSString *planeFullName; // full plane name may include Top or Bottom before the plane name
     
    if ([key hasSuffix:@"VerticalLines"]) {
        planeFullName = [key substringToIndex:[key length] - 13];
        if ([_verticalLines valueForKey:planeFullName] == nil) {
            [self _buildVerticalLinesAndPlaneRunsForPlaneFullName:planeFullName];
        }
        return [_verticalLines objectForKey:planeFullName];    
    } else if ([key hasSuffix:@"PlaneRuns"]) {
        planeFullName = [key substringToIndex:[key length] - 9];
        if ([_planeRuns valueForKey:planeFullName] == nil) {
            [self _buildVerticalLinesAndPlaneRunsForPlaneFullName:planeFullName];
        }
        return [_planeRuns valueForKey:planeFullName];
    } else {
        return [super valueForKey:key];
    }
}

- (void)mouseDraggedWindowLevel:(NSEvent *)event
{
	[super mouseDraggedWindowLevel: event];
	
	[[self windowController] propagateWLWW: self];
}

- (void)setDrawAllNodes:(BOOL)drawAllNodes
{
    if (drawAllNodes != _drawAllNodes) {
        _drawAllNodes = drawAllNodes;
        [self setNeedsDisplay:YES];
    }
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
        [self _clearTransversePlanes];
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

- (void) drawTextualData:(NSRect) size :(long) annotations
{
	if(_displayTransverseLines)
	{
		float length = [_curvedPath.bezierPath length];
        
		NSMutableArray *topLeft = [curDCM.annotationsDictionary objectForKey: @"TopLeft"];
		
		length *= 0.1; // We want cm
		
		[topLeft addObject: [NSArray arrayWithObject: [NSString stringWithFormat: NSLocalizedString( @"A-B : %2.2f cm", nil), length*fabs( _curvedPath.transverseSectionPosition - _curvedPath.leftTransverseSectionPosition)]]];
		[topLeft addObject: [NSArray arrayWithObject: [NSString stringWithFormat: NSLocalizedString( @"B-C : %2.2f cm", nil), length*fabs( _curvedPath.transverseSectionPosition - _curvedPath.rightTransverseSectionPosition)]]];
		[topLeft addObject: [NSArray arrayWithObject: [NSString stringWithFormat: NSLocalizedString( @"A-C : %2.2f cm", nil), length*fabs( _curvedPath.leftTransverseSectionPosition - _curvedPath.rightTransverseSectionPosition)]]];
		
		[super drawTextualData: size :annotations];
		
		[topLeft removeLastObject];
		[topLeft removeLastObject];
		[topLeft removeLastObject];
	}
	else [super drawTextualData: size :annotations];
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

- (NSPoint) positionWithoutRotation: (NSPoint) tPt
{
    NSRect unrotatedRect = NSMakeRect( tPt.x/scaleValue, tPt.y/scaleValue, 1, 1);
    NSRect centeredRect = unrotatedRect;
    
    float ratio = 1;
    
    if( self.pixelSpacingX != 0 && self.pixelSpacingY != 0)
        ratio = self.pixelSpacingX / self.pixelSpacingY;
    
    centeredRect.origin.y -= [self origin].y*ratio/scaleValue;
    centeredRect.origin.x -= - [self origin].x/scaleValue;
    
    unrotatedRect.origin.x = centeredRect.origin.x*cos( -self.rotation*deg2rad) + centeredRect.origin.y*sin( -self.rotation*deg2rad)/ratio;
    unrotatedRect.origin.y = -centeredRect.origin.x*sin( -self.rotation*deg2rad) + centeredRect.origin.y*cos( -self.rotation*deg2rad)/ratio;
    
    unrotatedRect.origin.y *= ratio;
    
    unrotatedRect.origin.y += [self origin].y*ratio/scaleValue;
    unrotatedRect.origin.x += - [self origin].x/scaleValue;
    
    tPt = NSMakePoint( unrotatedRect.origin.x, unrotatedRect.origin.y);
    tPt.x = (tPt.x)*scaleValue - unrotatedRect.size.width/2;
    tPt.y = (tPt.y)/ratio*scaleValue - unrotatedRect.size.height/2/ratio;
    
    return tPt;
}

- (void)subDrawRect:(NSRect)rect
{
    double pixToSubdrawRectOpenGLTransform[16];
	NSInteger i;
    N3Vector endpoint;
    N3BezierPath *centerline;
    NSString *planeName;
	NSColor *planeColor;
    N3AffineTransform pixToSubDrawRectTransform;
    N3Vector cursorVector;
    CGFloat relativePosition;

    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
	glEnable(GL_BLEND);
	glEnable(GL_POLYGON_SMOOTH);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
    if ([curDCM pixelSpacingX] == 0) {
        return;
    }
    
    centerline = [self centerlinePath];
    pixToSubDrawRectTransform = [self pixToSubDrawRectTransform];

    
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    N3AffineTransformGetOpenGLMatrixd([self pixToSubDrawRectTransform], pixToSubdrawRectOpenGLTransform);
    glMultMatrixd(pixToSubdrawRectOpenGLTransform);    
    // draw the centerline.
    
    glColor3f(0, 1, 0);
    glLineWidth(1.0 * self.window.backingScaleFactor);
    glBegin(GL_LINE_STRIP);
    for (i = 0; i < [centerline elementCount]; i++) {
        [centerline elementAtIndex:i control1:NULL control2:NULL endpoint:&endpoint];
        glVertex2d(endpoint.x, endpoint.y);
    }
    glEnd();
    
    
    glColor4d(0.0, 1.0, 0.0, 0.8);
    
    if ( [[self windowController] displayMousePosition] == YES && _displayInfo.mouseCursorHidden == NO)
	{
        cursorVector = [self _centerlinePixVectorForRelativePosition:_displayInfo.mouseCursorPosition];
        
        glEnable(GL_POINT_SMOOTH);
        glPointSize(8 * self.window.backingScaleFactor);
        
        glBegin(GL_POINTS);
        glVertex2f(cursorVector.x, cursorVector.y);
        glEnd();
        glDisable(GL_POINT_SMOOTH);
    }
    
    
    glPopMatrix();
 
    if (_displayCrossLines) {
        for (planeName in _planes) {
            planeColor = [self valueForKey:[planeName stringByAppendingString:@"PlaneColor"]];
            
            glLineWidth(2.0 * self.window.backingScaleFactor);
            // draw planes
            glColor4f ([planeColor redComponent], [planeColor greenComponent], [planeColor blueComponent], [planeColor alphaComponent]);
            [self _drawPlaneRuns:[self valueForKey:[planeName stringByAppendingString:@"PlaneRuns"]]];
            [self _drawVerticalLines:[self valueForKey:[planeName stringByAppendingString:@"VerticalLines"]]];
            
            glLineWidth(1.0 * self.window.backingScaleFactor);
            [self _drawPlaneRuns:[self valueForKey:[planeName stringByAppendingString:@"TopPlaneRuns"]]];
            [self _drawPlaneRuns:[self valueForKey:[planeName stringByAppendingString:@"BottomPlaneRuns"]]];
            [self _drawVerticalLines:[self valueForKey:[planeName stringByAppendingString:@"TopVerticalLines"]]];
            [self _drawVerticalLines:[self valueForKey:[planeName stringByAppendingString:@"BottomVerticalLines"]]];
        }
    }    
    
    float exportTransverseSliceInterval = 0;
	
	if( [[self windowController] exportSequenceType] == CPRSeriesExportSequenceType && [[self windowController] exportSeriesType] == CPRTransverseViewsExportSeriesType)
        exportTransverseSliceInterval = [[self windowController] exportTransverseSliceInterval];
    
    
    if( exportTransverseSliceInterval > 0)
	{
		glColor4d(1.0, 1.0, 0.0, 1.0);
		
		N3MutableBezierPath *flattenedPath = [[_curvedPath.bezierPath mutableCopy] autorelease];
		[flattenedPath subdivide:N3BezierDefaultSubdivideSegmentLength];
		[flattenedPath flatten:N3BezierDefaultFlatness];
		
		float curveLength = [flattenedPath length];
		int noOfFrames = ( curveLength / exportTransverseSliceInterval);
		noOfFrames++;
		
		float startingDistance = curveLength - (noOfFrames-1) * exportTransverseSliceInterval;
		startingDistance /= 2;
		
        // we need to find the tangents to the curve at
        N3VectorArray vectors;
        N3VectorArray tangents;
        
        vectors = malloc(noOfFrames * sizeof(N3Vector));
        tangents = malloc(noOfFrames * sizeof(N3Vector));
        noOfFrames = N3BezierCoreGetVectorInfo([_curvedPath.bezierPath N3BezierCore], exportTransverseSliceInterval, startingDistance, N3VectorZero, vectors, tangents, NULL, noOfFrames);
        
        CPRTransverseView *t = [[self windowController] middleTransverseView];
        CGFloat transverseWidth = (float)t.curDCM.pwidth/t.pixelsPerMm;
        transverseWidth /= self.pixelSpacingY;
        
		for( int i = 0; i < noOfFrames; i++)
		{
            _CPRStretchedViewPlaneRun *transverseRun;
            NSUInteger transverseIndex;
            
            relativePosition = (startingDistance + (exportTransverseSliceInterval * (CGFloat)i)) / curveLength;
            transverseRun = [self _limitedRunForRelativePosition:relativePosition verticalLineIndex:&transverseIndex lengthFromCenterline: transverseWidth];
            
            glLineWidth(2.0 * self.window.backingScaleFactor);

            if (transverseRun) {
                [self _drawPlaneRuns:[NSArray arrayWithObject:transverseRun]];
            } else {
                [self _drawVerticalLines:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:transverseIndex]] length: transverseWidth];
            }
		}
	}
	else if(_displayTransverseLines)
	{
        NSString *name;
        
        if ([_transverseVerticalLines count] == 0) {
            [self _buildTransverseVerticalLinesAndPlaneRuns];
        }
        
        glColor4d(1.0, 1.0, 0.0, 1.0);
        
        for (name in _transverseVerticalLines) {
            NSArray *transverseVerticalLine = [_transverseVerticalLines objectForKey:name];
            
            if ([name isEqualToString:@"center"]) {
                glLineWidth(2.0 * self.window.backingScaleFactor);
            } else {
                glLineWidth(1.0 * self.window.backingScaleFactor);
            }
            
            [self _drawVerticalLines:transverseVerticalLine length:curDCM.pheight/3.0];
        }
        for (name in _transversePlaneRuns) {
            NSArray *transversePlaneRun = [_transversePlaneRuns objectForKey:name];
            
            if ([name isEqualToString:@"center"]) {
                glLineWidth(2.0 * self.window.backingScaleFactor);
            } else {
                glLineWidth(1.0 * self.window.backingScaleFactor);
            }
            
            [self _drawPlaneRuns:transversePlaneRun];
        }
        
        N3Vector transverseIntersectionA = [self _centerlinePixVectorForRelativePosition:[_curvedPath leftTransverseSectionPosition]];
        N3Vector transverseIntersectionB = [self _centerlinePixVectorForRelativePosition:[_curvedPath transverseSectionPosition]];
        N3Vector transverseIntersectionC = [self _centerlinePixVectorForRelativePosition:[_curvedPath rightTransverseSectionPosition]];
        
        transverseIntersectionA = N3VectorApplyTransform(transverseIntersectionA, pixToSubDrawRectTransform);
        transverseIntersectionB = N3VectorApplyTransform(transverseIntersectionB, pixToSubDrawRectTransform);
        transverseIntersectionC = N3VectorApplyTransform(transverseIntersectionC, pixToSubDrawRectTransform);

        
		// --- Text
		if( stanStringAttrib == nil)
		{
			stanStringAttrib = [[NSMutableDictionary dictionary] retain];
			[stanStringAttrib setObject:[NSFont fontWithName:@"Helvetica" size: 14.0] forKey:NSFontAttributeName];
			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		}
		
		if( stringTexA == nil)
		{
			stringTexA = [[StringTexture alloc] initWithString: @"A"
                                                withAttributes:stanStringAttrib
                                                 withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
                                                  withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
                                               withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
			[stringTexA setAntiAliasing: YES];
		}
		if( stringTexB == nil)
		{
			stringTexB = [[StringTexture alloc] initWithString: @"B"
                                                withAttributes:stanStringAttrib
                                                 withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
                                                  withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
                                               withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
			[stringTexB setAntiAliasing: YES];
		}
		if( stringTexC == nil)
		{
			stringTexC = [[StringTexture alloc] initWithString: @"C"
                                                withAttributes:stanStringAttrib
                                                 withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
                                                  withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
                                               withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
			[stringTexC setAntiAliasing: YES];
		}
		
		glEnable (GL_TEXTURE_RECTANGLE_EXT);
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		
        {
            glPushMatrix();
            
            float ratio = 1;
            
            if( self.pixelSpacingX != 0 && self.pixelSpacingY != 0)
                ratio = self.pixelSpacingX / self.pixelSpacingY;
            
            glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
            glScalef (2.0f /([self xFlipped] ? -([self drawingFrameRect].size.width) : [self drawingFrameRect].size.width), -2.0f / ([self yFlipped] ? -([self drawingFrameRect].size.height) : [self drawingFrameRect].size.height), 1.0f); // scale to port per pixel scale
            glTranslatef( [self origin].x, -[self origin].y, 0.0f);
            
            [stringTexA setFlippedX: [self xFlipped] Y:[self yFlipped]];
            [stringTexB setFlippedX: [self xFlipped] Y:[self yFlipped]];
            [stringTexC setFlippedX: [self xFlipped] Y:[self yFlipped]];
            
            NSPoint tPt;
            
            tPt = [self positionWithoutRotation: NSMakePoint( transverseIntersectionA.x, transverseIntersectionA.y)];
            glColor4f (0, 0, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+1) ratio: 1];
            glColor4f (1, 1, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(tPt.x, tPt.y) ratio: 1];
            
            tPt = [self positionWithoutRotation: NSMakePoint( transverseIntersectionB.x, transverseIntersectionB.y)];
            glColor4f (0, 0, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+1) ratio: 1];
            glColor4f (1, 1, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(tPt.x, tPt.y) ratio: 1];
            
            tPt = [self positionWithoutRotation: NSMakePoint( transverseIntersectionC.x, transverseIntersectionC.y)];
            glColor4f (0, 0, 0, 1);	[stringTexC drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+1) ratio: 1];
            glColor4f (1, 1, 0, 1);	[stringTexC drawAtPoint:NSMakePoint(tPt.x, tPt.y) ratio: 1];
            
            glPopMatrix();
        }
				
		glDisable (GL_TEXTURE_RECTANGLE_EXT);
	}
    
    if( [[self windowController] displayMousePosition] == YES)
	{
		// draw the point on the plane lines
		for (planeName in _mousePlanePointsInPix) 
		{
			planeColor = [self valueForKey:[NSString stringWithFormat:@"%@PlaneColor", planeName]];
			glColor4f ([planeColor redComponent], [planeColor greenComponent], [planeColor blueComponent], [planeColor alphaComponent]);
			glEnable(GL_POINT_SMOOTH);
			glPointSize(8 * self.window.backingScaleFactor);
			cursorVector = N3VectorApplyTransform([[_mousePlanePointsInPix objectForKey:planeName] N3VectorValue], pixToSubDrawRectTransform);
			glBegin(GL_POINTS);
			glVertex2f(cursorVector.x, cursorVector.y);
			glEnd();	
		}
        
//        if (_displayInfo.mouseTransverseSection != CPRTransverseViewNoneSectionType) {
//            switch (_displayInfo.mouseTransverseSection) {
//                case CPRTransverseViewLeftSectionType:
//                    relativePosition = _curvedPath.leftTransverseSectionPosition;
//                    break;
//                case CPRTransverseViewCenterSectionType:
//                    relativePosition = _curvedPath.transverseSectionPosition;
//                    break;
//                case CPRTransverseViewRightSectionType:
//                    relativePosition = _curvedPath.rightTransverseSectionPosition;
//                    break;
//                default:
//                    relativePosition = 0;
//                    break;
//            }
//            
//            cursorVector = N3VectorMake((CGFloat)curDCM.pwidth*relativePosition, ((CGFloat)curDCM.pheight/2.0)+(_displayInfo.mouseTransverseSectionDistance*pixelsPerMm), 0);
//            cursorVector = N3VectorApplyTransform(cursorVector, pixToSubDrawRectTransform);
//            
//            glColor4d(1.0, 1.0, 0.0, 1.0);
//            glEnable(GL_POINT_SMOOTH);
//            glPointSize(8 * self.window.backingScaleFactor);
//            glBegin(GL_POINTS);
//            glVertex2f(cursorVector.x, cursorVector.y);
//            glEnd();
//        }
    }
    
    if (_drawAllNodes)
	{
        for (i = 0; i < [_curvedPath.nodes count]; i++)
		{
            relativePosition = [_curvedPath relativePositionForNodeAtIndex:i];
            cursorVector = [self _centerlinePixVectorForRelativePosition:relativePosition];
//            cursorVector = N3VectorMake(curDCM.pwidth * relativePosition, (CGFloat)curDCM.pheight/2.0, 0);
            cursorVector = N3VectorApplyTransform(cursorVector, pixToSubDrawRectTransform);
            
            if (_displayInfo.hoverNodeHidden == NO && _displayInfo.hoverNodeIndex == i)
			{
                glColor4d(1.0, 0.5, 0.0, 1.0);
            } else {
                glColor4d(1.0, 0.0, 0.0, 1.0);
            }
            
            
            glEnable(GL_POINT_SMOOTH);
            glPointSize(8 * self.window.backingScaleFactor);
            
            glBegin(GL_POINTS);
            glVertex2f(cursorVector.x, cursorVector.y);
            glEnd();
        }
    }


    
	// Red Square
	if( [[self window] firstResponder] == self && stringID == nil)
	{
		glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
		glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
		
		glColor4d(1.0, 0, 0.0, 1.0);
		
		float heighthalf = drawingFrameRect.size.height/2;
		float widthhalf = drawingFrameRect.size.width/2;
		
		glLineWidth(8.0 * self.window.backingScaleFactor);
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

- (void) updatePresentationStateFromSeriesOnlyImageLevel: (BOOL) onlyImage
{
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
    self.centerlinePath = nil;
    _midHeightPoint = N3VectorZero;
    _projectionNormal = N3VectorZero;
    
    for (i = 0; i < self.curvedVolumeData.pixelsDeep; i++)
	{
		if ([self.curvedVolumeData aquireInlineBuffer:&inlineBuffer]) {
			newPix = [[DCMPix alloc] initWithData:(float *)CPRVolumeDataFloatBytes(&inlineBuffer) + (i*self.curvedVolumeData.pixelsWide*self.curvedVolumeData.pixelsHigh) :32 
												 :self.curvedVolumeData.pixelsWide :self.curvedVolumeData.pixelsHigh :self.curvedVolumeData.pixelSpacingX :self.curvedVolumeData.pixelSpacingY
												 :0.0 :0.0 :0.0 :NO];
		} else {
			assert(0);
			newPix = [[DCMPix alloc] init];
		}
		[self.curvedVolumeData releaseInlineBuffer:&inlineBuffer];
        
		[newPix setImageObjectID: [[[self windowController] originalPix] imageObjectID]];
		[newPix setSrcFile: [[[self windowController] originalPix] srcFile]];
		[newPix setAnnotationsDictionary: [[[self windowController] originalPix] annotationsDictionary]];
		
		
		[pixArray addObject:newPix];
        [newPix release];
    }
	
	if( [pixArray count])
	{
        [self _clearAllPlanes];
        [self _clearTransversePlanes];
        self.centerlinePath = [self _projectedBezierPathFromStretchedGeneratorRequest:(CPRStretchedGeneratorRequest*)request];
        _midHeightPoint = [(CPRStretchedGeneratorRequest*)request midHeightPoint];
        _projectionNormal = [(CPRStretchedGeneratorRequest*)request projectionNormal];

		for( i = 0; i < [pixArray count]; i++)
			[[pixArray objectAtIndex: i] setArrayPix:pixArray :i];
		
		[self setPixels:pixArray files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
		[self setScaleValueCentered: 0.8 * self.window.backingScaleFactor];
		
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
			[r setCurView:self];
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

- (void)mouseEntered:(NSEvent *)theEvent
{
	[self _sendWillEditDisplayInfo];
    _displayInfo.mouseCursorHidden = NO;
	[self _sendDidEditDisplayInfo];
    [super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self _sendWillEditDisplayInfo];
    _displayInfo.mouseCursorHidden = YES;
	[_displayInfo clearAllMouseVectors];
    _displayInfo.mouseTransverseSection = CPRTransverseViewNoneSectionType;
    _displayInfo.mouseTransverseSectionDistance = 0;
	[self _sendDidEditDisplayInfo];
    [_mousePlanePointsInPix removeAllObjects];
	
    self.drawAllNodes = NO;
    
    [self setNeedsDisplay:YES];
    
    [super mouseExited:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
	
	if( view == self)
	{
		NSPoint viewPoint;
		N3Vector pixVector;
		NSInteger i;
		BOOL overNode;
		NSInteger hoverNodeIndex;
		CGFloat relativePosition;
		N3Vector vector;
        CGFloat distanceFromCenterline;
		
		viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		if( NSPointInRect( viewPoint, [self bounds]) == NO)
			return;
		
		pixVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(viewPoint), [self viewToPixTransform]);
		
		if (NSPointInRect(viewPoint, self.bounds) && curDCM.pwidth > 0) {
			[self _sendWillEditDisplayInfo];
			_displayInfo.mouseCursorPosition = [self _relativePositionForPixPoint:NSPointFromN3Vector(pixVector)];
//			_displayInfo.mouseCursorPosition = MIN(MAX(pixVector.x/(CGFloat)curDCM.pwidth, 0.0), 1.0);
			[self setNeedsDisplay:YES];
            
			[self _updateMousePlanePointsForViewPoint:viewPoint];  // this will modify _mousePlanePointsInPix and _displayInfo
			
            // test to see if the mouse is near a trasverse line
//            _displayInfo.mouseTransverseSection = CPRTransverseViewNoneSectionType;
//            _displayInfo.mouseTransverseSectionDistance = 0.0;
//            if (_displayTransverseLines) {
//                distance = ABS(pixVector.x - _curvedPath.leftTransverseSectionPosition*(CGFloat)curDCM.pwidth);
//                minDistance = distance;
//                if (distance < 20.0) {
//                    _displayInfo.mouseTransverseSection = CPRTransverseViewLeftSectionType;
//                    _displayInfo.mouseTransverseSectionDistance = (pixVector.y - ((CGFloat)curDCM.pheight/2.0))*([_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth);
//                }
//                distance = ABS(pixVector.x - _curvedPath.rightTransverseSectionPosition*(CGFloat)curDCM.pwidth);
//                if (distance < 20.0 && distance < minDistance) {
//                    _displayInfo.mouseTransverseSection = CPRTransverseViewRightSectionType;
//                    _displayInfo.mouseTransverseSectionDistance = (pixVector.y - ((CGFloat)curDCM.pheight/2.0))*([_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth);
//                    minDistance = distance;
//                }
//                distance = ABS(pixVector.x - _curvedPath.transverseSectionPosition*(CGFloat)curDCM.pwidth);
//                if (distance < 20.0 && distance < minDistance) {
//                    _displayInfo.mouseTransverseSection = CPRTransverseViewCenterSectionType;
//                    _displayInfo.mouseTransverseSectionDistance = (pixVector.y - ((CGFloat)curDCM.pheight/2.0))*([_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth);
//                }
//            }            
            
//			line = N3LineMake(N3VectorMake(0, (CGFloat)curDCM.pheight / 2.0, 0), N3VectorMake(1, 0, 0));
//			line = N3LineApplyTransform(line, N3AffineTransformInvert([self viewToPixTransform]));
//			
            
            [_centerlinePath relativePositionClosestToLine:N3LineMake(pixVector, N3VectorMake(0, 0, 1)) closestVector:&vector];
            distanceFromCenterline = N3VectorDistanceToLine(vector, N3LineMake(pixVector, N3VectorMake(0, 0, 1)));
			if (distanceFromCenterline < 20.0) {
				self.drawAllNodes = YES;
			} else {
				self.drawAllNodes = NO;
			}
            			
			overNode = NO;
			hoverNodeIndex = 0;
			if (self.drawAllNodes) {
				for (i = 0; i < [_curvedPath.nodes count]; i++) {
					relativePosition = [_curvedPath relativePositionForNodeAtIndex:i];
					
                    
                    if (N3VectorDistance(pixVector, [self _centerlinePixVectorForRelativePosition:relativePosition]) < 10) {
						overNode = YES;
						hoverNodeIndex = i;
						break;
					}
				}
				
				if (overNode) {
					if (_displayInfo.hoverNodeHidden == YES || _displayInfo.hoverNodeIndex != hoverNodeIndex) {
						_displayInfo.hoverNodeHidden = NO;
						_displayInfo.hoverNodeIndex = hoverNodeIndex;
					}
				} else {
					if (_displayInfo.hoverNodeHidden == NO) {
						_displayInfo.hoverNodeHidden = YES;
						_displayInfo.hoverNodeIndex = 0;
					}
				}
			}
			
			[self _sendDidEditDisplayInfo];
		}
		
		float exportTransverseSliceInterval = 0;
        NSMutableArray *allTransverseVerticalLines;
        NSMutableArray *allTransverseRuns;
        CGFloat transverseLineDistance;
        CGFloat transverseRunDistance;
        
		if( [[self windowController] exportSequenceType] == CPRSeriesExportSequenceType && [[self windowController] exportSeriesType] == CPRTransverseViewsExportSeriesType)
			exportTransverseSliceInterval = [[self windowController] exportTransverseSliceInterval];
		
        allTransverseVerticalLines = [NSMutableArray array];
        allTransverseRuns = [NSMutableArray array];
        
        for (NSArray *values in [_transverseVerticalLines allValues]) {
            [allTransverseVerticalLines addObjectsFromArray:values];
        }
        for (NSArray *values in [_transversePlaneRuns allValues]) {
            [allTransverseRuns addObjectsFromArray:values];
        }
        
        transverseLineDistance = [self _distanceToPoint:viewPoint onVerticalLines:allTransverseVerticalLines pixVector:NULL volumeVector:NULL];
        transverseRunDistance = [self _distanceToPoint:viewPoint onPlaneRuns:allTransverseRuns pixVector:NULL volumeVector:NULL];

		if( curDCM.pwidth != 0 && exportTransverseSliceInterval == 0 && _displayTransverseLines && (transverseLineDistance < 5.0 || transverseRunDistance < 5.0))
		{
			if( [theEvent type] == NSLeftMouseDragged || [theEvent type] == NSLeftMouseDown)
				[[NSCursor closedHandCursor] set];
			else
				[[NSCursor openHandCursor] set];
		}
		else
		{
			[cursor set];
			
			[super mouseMoved:theEvent];
		}
	}
	else
	{
		[view mouseMoved:theEvent];
	}
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint viewPoint;
    N3Vector pixVector;
    N3Vector vector;
    CGFloat pixWidth;
    CGFloat relativePosition;
    CGFloat distanceFromCenterline;
    NSInteger i;
    
    viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    pixVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(viewPoint), [self viewToPixTransform]);
    pixWidth = curDCM.pwidth;
    
    if (pixWidth == 0.0) {
        [super mouseDown:event];
        return;
    }
	
	float exportTransverseSliceInterval = 0;
    NSMutableArray *outsideTransverseVerticalLines;
    NSMutableArray *outsideTransverseRuns;
    CGFloat outsideTransverseLineDistance;
    CGFloat outsideTransverseRunDistance;
    CGFloat centerTransverseLineDistance;
    CGFloat centerTransverseRunDistance;
    
    outsideTransverseVerticalLines = [NSMutableArray array];
    outsideTransverseRuns = [NSMutableArray array];
    
    for (NSString *key in _transverseVerticalLines ) {
        if ([key isEqualToString:@"center"] == NO) {
            [outsideTransverseVerticalLines addObjectsFromArray:[_transverseVerticalLines objectForKey:key]];
        }
    }
    for (NSString *key in _transversePlaneRuns ) {
        if ([key isEqualToString:@"center"] == NO) {
            [outsideTransverseRuns addObjectsFromArray:[_transversePlaneRuns objectForKey:key]];
        }
    }
    
    outsideTransverseLineDistance = [self _distanceToPoint:viewPoint onVerticalLines:outsideTransverseVerticalLines pixVector:NULL volumeVector:NULL];
    outsideTransverseRunDistance = [self _distanceToPoint:viewPoint onPlaneRuns:outsideTransverseRuns pixVector:NULL volumeVector:NULL];
    centerTransverseLineDistance = [self _distanceToPoint:viewPoint onVerticalLines:[_transverseVerticalLines objectForKey:@"center"] pixVector:NULL volumeVector:NULL];
    centerTransverseRunDistance = [self _distanceToPoint:viewPoint onPlaneRuns:[_transversePlaneRuns objectForKey:@"center"] pixVector:NULL volumeVector:NULL];
    
	if( [[self windowController] exportSequenceType] == CPRSeriesExportSequenceType && [[self windowController] exportSeriesType] == CPRTransverseViewsExportSeriesType)
		exportTransverseSliceInterval = [[self windowController] exportTransverseSliceInterval];
	
    if( exportTransverseSliceInterval == 0 && _displayTransverseLines && MIN(centerTransverseLineDistance, centerTransverseRunDistance) < 5.0)
	{
		[self _sendWillEditCurvedPath];
        _draggingTransverse = YES;
		[self mouseMoved: event];
    }
	else if( exportTransverseSliceInterval == 0 && _displayTransverseLines && MIN(outsideTransverseLineDistance, outsideTransverseRunDistance) < 10.0)
	{
		[self _sendWillEditCurvedPath];
        _draggingTransverseSpacing = YES;
		[self mouseMoved: event];
    }
	else
	{
        for (i = 0; i < [_curvedPath.nodes count]; i++)
		{
            relativePosition = [_curvedPath relativePositionForNodeAtIndex:i];
            if (N3VectorDistance(pixVector, [self _centerlinePixVectorForRelativePosition:relativePosition]) < 10) {
                if (i == 0 || i == [_curvedPath.nodes count] - 1) {
                    if ([_delegate respondsToSelector:@selector(CPRView:setCrossCenter:)]) {
                        [_delegate CPRView: [[self windowController] mprView1] setCrossCenter:[[_curvedPath.nodes objectAtIndex:i] N3VectorValue]];
                    }
                    _draggedNode = -1;
                    _isDraggingNode = YES;
                    break;
                } else {
                    _draggedNode = i;
                    _isDraggingNode = YES;
                    [self _sendWillEditCurvedPath];
                    
                    break;
                }
            }
        }
        
        if (_isDraggingNode == NO) {
            relativePosition = [_centerlinePath relativePositionClosestToLine:N3LineMake(pixVector, N3VectorMake(0, 0, 1)) closestVector:&vector];
            distanceFromCenterline = N3VectorDistanceToLine(vector, N3LineMake(pixVector, N3VectorMake(0, 0, 1)));
            if (distanceFromCenterline < 5.0) {
                _isDraggingNode = YES;
                [self _sendWillEditCurvedPath];
                _draggedNode = [_curvedPath insertNodeAtRelativePosition:relativePosition];
                
                _isDraggingNode = YES;
                [self setNeedsDisplay:YES];
                [self _setNeedsNewRequest];
            }
        }
        
        if (_isDraggingNode == NO)
		{
			int clickCount = 1;
            
			@try
			{
				if( [event type] ==	NSLeftMouseDown || [event type] ==	NSRightMouseDown || [event type] ==	NSLeftMouseUp || [event type] == NSRightMouseUp)
					clickCount = [event clickCount];
			}
			@catch (NSException * e)
			{
				clickCount = 1;
			}
			
			if( clickCount == 2)
			{
				NSPoint tempPt = [self convertPoint: [event locationInWindow] fromView: nil];
				tempPt = [self ConvertFromNSView2GL:tempPt];
				
				CPRController *windowController = [self windowController];
				
				ToolMode tool = [self getTool: event];
				
				if( [self roiTool: tool] && [self clickInROI: tempPt])
				{
					[[self windowController] roiGetInfo: self];
				}
				else if( frameZoomed == NO)
				{
					splitPosition[0] = [[windowController mprView1] frame].origin.x + [[windowController mprView1] frame].size.width;	// vert
					splitPosition[1] = [[windowController mprView1] frame].origin.y + [[windowController mprView1] frame].size.height;	// hori12
					splitPosition[2] = [[windowController mprView3] frame].origin.y + [[windowController mprView3] frame].size.height;	// horiz2
					
					frameZoomed = YES;
					
					[windowController.verticalSplit setPosition: [windowController.verticalSplit minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
					[windowController.horizontalSplit1 setPosition: [windowController.horizontalSplit1 minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
					[windowController.horizontalSplit2 setPosition: [windowController.horizontalSplit2 minPossiblePositionOfDividerAtIndex: 0] ofDividerAtIndex: 0];
				}
				else
				{
					frameZoomed = NO;
					[windowController.verticalSplit setPosition: splitPosition[ 0] ofDividerAtIndex: 0];
					[windowController.horizontalSplit1 setPosition: splitPosition[ 1] ofDividerAtIndex: 0];
					[windowController.horizontalSplit2 setPosition: splitPosition[ 2] ofDividerAtIndex: 0];
                    
                    [windowController.mprView1 restoreCamera];
                    windowController.mprView1.camera.forceUpdate = YES;
                    [windowController.mprView1 updateViewMPR];
                    
                    [windowController.mprView2 restoreCamera];
                    windowController.mprView2.camera.forceUpdate = YES;
                    [windowController.mprView2 updateViewMPR];
                    
                    [windowController.mprView3 restoreCamera];
                    windowController.mprView3.camera.forceUpdate = YES;
                    [windowController.mprView3 updateViewMPR];
				}
			}
			else
			{
				if( [self roiTool: currentTool])
				{
//					if( currentTool != tText && currentTool != tArrow)
//						currentTool = tMesure;
				}
				
				[super mouseDown:event];
			}
        }
    }
}

- (void)mouseDragged:(NSEvent *)event
{
    NSPoint viewPoint;
    N3Vector pixVector;
    CGFloat relativePosition;
    CGFloat pixWidth;
    	
    viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    pixVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(viewPoint), [self viewToPixTransform]);
    pixWidth = curDCM.pwidth;
    
    if (pixWidth == 0.0) {
        [super mouseDragged:event];
        return;
    }
    
    if (_isDraggingNode) {
        if (_draggedNode >= 0) {
            [_curvedPath moveNodeAtIndex:_draggedNode toVector:[self _vectorForPixPoint:NSPointFromN3Vector(pixVector)]];
        }
        [self _sendDidUpdateCurvedPath];
        [self _setNeedsNewRequest];
        [self display];
        [self mouseMoved: event];
    }
    else if (_draggingTransverse)
	{
        relativePosition = [self _relativePositionForPixPoint:NSPointFromN3Vector(pixVector)];
        _curvedPath.transverseSectionPosition = MAX(MIN(relativePosition, 1.0), 0.0);
		[self _sendDidUpdateCurvedPath];
        
		[self _sendWillEditDisplayInfo];
        _displayInfo.mouseCursorPosition = pixVector.x/pixWidth;
		[self _sendDidEditDisplayInfo];
        
		[self setNeedsDisplay:YES];
		[self mouseMoved: event];
    }
	else if (_draggingTransverseSpacing)
	{
        _curvedPath.transverseSectionSpacing = ABS([self _relativePositionForPixPoint:NSPointFromN3Vector(pixVector)]-_curvedPath.transverseSectionPosition)*[_curvedPath.bezierPath length];
		[self _sendDidUpdateCurvedPath];
        
		[self _sendWillEditDisplayInfo];
        _displayInfo.mouseCursorPosition = [self _relativePositionForPixPoint:NSPointFromN3Vector(pixVector)];
		[self _sendDidEditDisplayInfo];
        [self setNeedsDisplay:YES];
		[self mouseMoved: event];
    }
	else
	{
		[self _sendWillEditDisplayInfo];
        _displayInfo.mouseCursorPosition = [self _relativePositionForPixPoint:NSPointFromN3Vector(pixVector)];
		[self _sendDidEditDisplayInfo];
        
        [super mouseDragged:event];
    }
}

- (void)mouseUp:(NSEvent *)event
{
    if (_isDraggingNode) {
//        [_draggingCenterlinePath release];
//        _draggingCenterlinePath = nil;
//        _draggingMidHeightPoint = N3VectorZero;
//        _draggingProjectionNormal = N3VectorZero;
        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixUpdateCurvedPathCostNotification object:nil];
        [self _sendDidEditCurvedPath];
        
        if (_draggedNode >= 0) {
            if ([_delegate respondsToSelector:@selector(CPRView:setCrossCenter:)]) {
                [_delegate CPRView: [[self windowController] mprView1] setCrossCenter:[[_curvedPath.nodes objectAtIndex:_draggedNode] N3VectorValue]];
            }
        }
    }
    _draggedNode = 0;
    _isDraggingNode = NO;

	if (_draggingTransverse) {
		_draggingTransverse = NO;
		[self _sendDidEditCurvedPath];
	} else if (_draggingTransverseSpacing) {
		_draggingTransverseSpacing = NO;
		[self _sendDidEditCurvedPath];
	}
    
    [super mouseUp:event];
}

- (void)keyDown:(NSEvent *)theEvent
{
    if( [[theEvent characters] length] == 0) return;
    
    unichar c = [[theEvent characters] characterAtIndex:0];
    
    if(( c == NSDeleteCharacter || c == NSDeleteFunctionKey) && _isDraggingNode && _draggedNode != -1)
	{
		// Delete node
        [_curvedPath removeNodeAtIndex:_draggedNode];
        _draggedNode = -1;
        [self setNeedsDisplay:YES];
        [self _setNeedsNewRequest];
        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixUpdateCurvedPathCostNotification object:nil];
    }
    else
        [super keyDown:theEvent];
}
- (void)scrollWheel:(NSEvent *)theEvent
{
	// Scroll/Move transverse lines
	if( [theEvent modifierFlags] & NSAlternateKeyMask)
	{
		CGFloat transverseSectionPosition = MIN(MAX(_curvedPath.transverseSectionPosition + [theEvent deltaY] * .002, 0.0), 1.0); 
		
		[self _sendWillEditCurvedPath];
		_curvedPath.transverseSectionPosition = transverseSectionPosition;
		[self _sendDidEditCurvedPath];
		
		[self _setNeedsNewRequest];
		[self setNeedsDisplay: YES];
	}
	
	// Scroll/Move transverse lines
	else if( [theEvent modifierFlags] & NSCommandKeyMask)
	{
        float factor = 0.4;
        
        if( curDCM.pixelSpacingX)
            factor = curDCM.pixelSpacingX;
        
		CGFloat transverseSectionSpacing = MIN(MAX(_curvedPath.transverseSectionSpacing + [theEvent deltaY] * factor, 0.0), 300);
		
		[self _sendWillEditCurvedPath];
		_curvedPath.transverseSectionSpacing = transverseSectionSpacing;
		[self _sendDidEditCurvedPath];
		
		[self _setNeedsNewRequest];
		[self setNeedsDisplay: YES];
	}
    
    // Scroll/push the curve in and out
	else if( [theEvent modifierFlags] & NSControlKeyMask) {
        [self _pushBezierPath:[theEvent deltaY] * .4];
    }
    
	else
	{
		N3Vector initialNormal;
		CGFloat angle;
		
		angle = [theEvent deltaY] * (M_PI/180);
		
		initialNormal = _curvedPath.initialNormal;
		initialNormal = N3VectorApplyTransform(initialNormal, N3AffineTransformMakeRotationAroundVector(angle, [_curvedPath.bezierPath tangentAtStart]));
        
		[self _sendWillEditCurvedPath];
		_curvedPath.initialNormal = initialNormal;
		[self _sendDidEditCurvedPath];
		[self _setNeedsNewRequest];
	}
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
            NSLog(@"%s asking for invalid clipping range mode: %d", __func__, (int) clippingRangeMode);
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
//    N3Vector curveDirection;
//    N3Vector baseNormal;
    
    if ([_curvedPath.bezierPath elementCount] >= 3)
	{
        request = [[CPRStretchedGeneratorRequest alloc] init];
        
        request.interpolationMode = [[self windowController] selectedInterpolationMode];
        
        if( [[self windowController] viewsPosition] == VerticalPosition)
        {
            request.pixelsWide = [self bounds].size.height*_extraWidthFactor;
            request.pixelsHigh = [self bounds].size.width*_extraWidthFactor;
		}
        else
        {
            request.pixelsWide = [self bounds].size.width*_extraWidthFactor;
            request.pixelsHigh = [self bounds].size.height*_extraWidthFactor;
		}
        
        request.slabWidth = _curvedPath.thickness;
        
        request.slabSampleDistance = 0;
        request.bezierPath = _curvedPath.bezierPath;
        request.projectionMode = _clippingRangeMode;
        request.projectionNormal = [_curvedPath stretchedProjectionNormal];
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

- (N3BezierPath *)_projectedBezierPathFromStretchedGeneratorRequest:(CPRStretchedGeneratorRequest *)generatorRequest
{
    NSInteger pixelsWide;
    NSInteger pixelsHigh;
    NSUInteger numVectors;
    N3Vector midHeightPoint;
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
    pixelsWide = [generatorRequest pixelsWide];
    pixelsHigh = [generatorRequest pixelsHigh];
    projectionNormal = N3VectorNormalize(generatorRequest.projectionNormal);
    midHeightPoint = generatorRequest.midHeightPoint;
    
    flattenedBezierCore = N3BezierCoreCreateFlattenedCopy([generatorRequest.bezierPath N3BezierCore], N3BezierDefaultFlatness);
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
        //        newPoint.y = N3VectorLength(N3VectorProject(N3VectorSubtract(vectors[0], midHeightPoint), projectionNormal));
        newPoint.y = N3VectorDotProduct(N3VectorSubtract(vectors[0], midHeightPoint), projectionNormal);
        newPoint.y /= sampleSpacing;
        newPoint.y += (CGFloat)pixelsHigh/2.0;
        newPoint.z = relativePositions[0];
        
        [centerlinePath moveToVector:newPoint];
    }
    
    for (i = 1; i < numVectors; i++) {
        newPoint.x = i;
        newPoint.y = N3VectorDotProduct(N3VectorSubtract(vectors[i], midHeightPoint), projectionNormal);
        newPoint.y /= sampleSpacing;
        newPoint.y += (CGFloat)pixelsHigh/2.0;
        newPoint.z = relativePositions[i];
        
        [centerlinePath lineToVector:newPoint];
    }
    
    N3BezierCoreRelease(flattenedBezierCore);
    N3BezierCoreRelease(projectedBezierCore);
    free(vectors);
    free(relativePositions);
        
    return centerlinePath;    
}

- (void)_drawVerticalLines:(NSArray *)verticalLines
{
	NSNumber *indexNumber;
	N3Vector lineStart;
	N3Vector lineEnd;
    double pixToSubdrawRectOpenGLTransform[16];
	CGLContextObj cgl_ctx;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];    	
    if( cgl_ctx == nil)
        return;
    
    N3AffineTransformGetOpenGLMatrixd([self pixToSubDrawRectTransform], pixToSubdrawRectOpenGLTransform);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glMultMatrixd(pixToSubdrawRectOpenGLTransform);    
	for (indexNumber in verticalLines) {
		lineStart = N3VectorMake([indexNumber doubleValue], 0, 0);
        lineEnd = N3VectorMake([indexNumber doubleValue], curDCM.pheight, 0);
        glBegin(GL_LINE_STRIP);
        glVertex2d(lineStart.x, lineStart.y);
        glVertex2d(lineEnd.x, lineEnd.y);
        glEnd();
	}
    glPopMatrix();
}

- (void)_drawVerticalLines:(NSArray *)verticalLines length:(CGFloat)length;
{
	NSNumber *indexNumber;
    CGFloat relativePostion;
    N3Vector centerlineVector;
	N3Vector lineStart;
	N3Vector lineEnd;
    double pixToSubdrawRectOpenGLTransform[16];
	CGLContextObj cgl_ctx;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];    	
    if( cgl_ctx == nil)
        return;
    
    N3AffineTransformGetOpenGLMatrixd([self pixToSubDrawRectTransform], pixToSubdrawRectOpenGLTransform);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glMultMatrixd(pixToSubdrawRectOpenGLTransform);    
	for (indexNumber in verticalLines) {
        relativePostion = [self _relativePositionForIndex:[indexNumber integerValue]]; // this is dumb, just do one iteration! and do it in log(n) time while your at it to!
        centerlineVector = [self _centerlinePixVectorForRelativePosition:relativePostion];
        
		lineStart = N3VectorMake([indexNumber doubleValue], centerlineVector.y - length/2.0, 0);
        lineEnd = N3VectorMake([indexNumber doubleValue], centerlineVector.y + length/2.0, 0);
        glBegin(GL_LINE_STRIP);
        glVertex2d(lineStart.x, lineStart.y);
        glVertex2d(lineEnd.x, lineEnd.y);
        glEnd();
	}
    glPopMatrix();
}

- (void)_drawPlaneRuns:(NSArray*)planeRuns
{
	CGFloat pixelsPerMm;
	NSInteger i;
	N3Vector planePointVector;
	_CPRStretchedViewPlaneRun *planeRun;
    double pixToSubdrawRectOpenGLTransform[16];
	CGLContextObj cgl_ctx;
    CGFloat pheight_2;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
  	if( cgl_ctx == nil)
        return;
    
    if ([curDCM pixelSpacingX] == 0) {
        return;
    }
    
    pixelsPerMm = 1.0/[curDCM pixelSpacingX];

    pheight_2 = (CGFloat)curDCM.pheight/2.0;
    
    N3AffineTransformGetOpenGLMatrixd([self pixToSubDrawRectTransform], pixToSubdrawRectOpenGLTransform);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glMultMatrixd(pixToSubdrawRectOpenGLTransform);    
	for (planeRun in planeRuns) {
		glBegin(GL_LINE_STRIP);
		for (i = 0; i < planeRun.range.length; i++) {
			planePointVector = N3VectorMake(planeRun.range.location + i, ([[planeRun.distances objectAtIndex:i] doubleValue] * pixelsPerMm) + pheight_2, 0);
			glVertex2d(planePointVector.x, planePointVector.y);
		}
		glEnd();
	}
    glPopMatrix();
}

- (_CPRStretchedViewPlaneRun *)_limitedRunForRelativePosition:(CGFloat)relativePosition verticalLineIndex:(NSUInteger *)verticalLinePointer lengthFromCenterline:(CGFloat)length
{
    N3Plane transversePlane;
    CGFloat mmPerPixel;
	CGFloat halfHeight;
    NSInteger pixelsWide;
    N3Vector projectionNormal;
    N3Plane topPlane;
    N3Plane bottomPlane;
    N3Vector midHeightPoint;
    N3BezierCoreRef flattenedBezierCore;
    N3BezierCoreRef projectedBezierCore;
    CGFloat projectedBezierLength;
    CGFloat sampleSpacing;
    N3VectorArray vectors;
    CGFloat *relativePositions;
    NSInteger i;
    NSInteger relativePositionIndex;
    N3Vector top;
    N3Vector bottom;
    BOOL topPointAbove;
    BOOL bottomPointAbove;
    BOOL prevBottomPointAbove;
    _CPRStretchedViewPlaneRun *planeRun;
    NSRange range;
    CGFloat distance;
    CGFloat traveledDistance;
    N3Vector distanceVector;
    N3Vector lastDistanceVector;
    NSInteger numVectors;
    
    transversePlane.point = [_curvedPath.bezierPath vectorAtRelativePosition:relativePosition];
    transversePlane.normal = [_curvedPath.bezierPath tangentAtRelativePosition:relativePosition];
    
    mmPerPixel = [curDCM pixelSpacingX];
	halfHeight = ((CGFloat)curDCM.pheight*mmPerPixel)/2.0;
    length /= 2.0; // because the rest of the code uses the length from the centerline 
    
    // figure out how many horizonatal pixels we will have
    pixelsWide = curDCM.pwidth;
    projectionNormal = _projectionNormal;
    
    midHeightPoint = _midHeightPoint;
    topPlane = N3PlaneMake(N3VectorAdd(midHeightPoint, N3VectorScalarMultiply(projectionNormal, halfHeight*1e2)), projectionNormal); // make the virtual top and bottom of the world be real far away
    bottomPlane = N3PlaneMake(N3VectorAdd(midHeightPoint, N3VectorScalarMultiply(projectionNormal, -halfHeight*1e2)), projectionNormal);
    
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
    } else { // there are no vectors, bail!
        free(vectors);
        free(relativePositions);
        return [[[_CPRStretchedViewPlaneRun alloc] init] autorelease];
    }
    
    for (i = 0; i < numVectors; i++) {
        if (relativePositions[i] > relativePosition) {
            break;
        }
    }
    relativePositionIndex = MAX(0, i-1);
    
    if (numVectors >= 2 && relativePositionIndex < numVectors - 1) { // it only makes sense to check for a vertical line if numVec is at least 2 and there i is not on the last line
        bottom = N3LineIntersectionWithPlane(N3LineMake(vectors[relativePositionIndex], projectionNormal), bottomPlane);
        top = N3LineIntersectionWithPlane(N3LineMake(vectors[relativePositionIndex], projectionNormal), topPlane);
        
        bottomPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(bottom, transversePlane.point)) > 0.0;
		topPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(top, transversePlane.point)) > 0.0;
        
        if (bottomPointAbove == topPointAbove) {
            if (verticalLinePointer) {
                *verticalLinePointer = relativePositionIndex;
            }
            free(vectors);
            free(relativePositions);
            return nil;
        }
    }
    
    // now know that this is not vertical line, and so we have to make a plane run    
    planeRun = [[[_CPRStretchedViewPlaneRun alloc] init] autorelease];
        
    // it is easier to extend the curve than to start it, so we will put th first point checking all the edge cases, and then we will worry about extending it
    bottom = N3LineIntersectionWithPlane(N3LineMake(vectors[relativePositionIndex], projectionNormal), bottomPlane); // isn't this already set?
    bottomPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(bottom, transversePlane.point)) > 0.0;
    prevBottomPointAbove = bottomPointAbove;
        
    distance = N3VectorDotProduct(N3VectorSubtract(vectors[relativePositionIndex], midHeightPoint), projectionNormal);
    [planeRun.distances addObject:[NSNumber numberWithDouble:distance]];
    planeRun.range = NSMakeRange(relativePositionIndex, 1);
    lastDistanceVector = N3VectorMake(relativePositionIndex, distance/mmPerPixel, 0);
    
    // start walking forwards
    traveledDistance = 0;
    for (i = relativePositionIndex + 1; i < numVectors; i++) {
        bottom = N3LineIntersectionWithPlane(N3LineMake(vectors[i], projectionNormal), bottomPlane);
        top = N3LineIntersectionWithPlane(N3LineMake(vectors[i], projectionNormal), topPlane);
        bottomPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(bottom, transversePlane.point)) > 0.0;
        topPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(top, transversePlane.point)) > 0.0;

        // if we just walked off the projection
        if (bottomPointAbove == topPointAbove) {
            // figure out if we just walked up or down
            if (prevBottomPointAbove != bottomPointAbove) {
                distance = -(halfHeight*1e10);
            } else {
                distance = halfHeight*1e10;
            }
        } else {
            distance = N3VectorDotProduct(N3VectorSubtract(N3LineIntersectionWithPlane(N3LineMakeFromPoints(bottom, top), transversePlane), midHeightPoint), projectionNormal);
        }
        
        distanceVector = N3VectorMake(i, distance/mmPerPixel, 0);
        if (N3VectorDistance(distanceVector, lastDistanceVector) + traveledDistance > length) { // we can't make the whole segment
            distanceVector = N3VectorAdd(lastDistanceVector, N3VectorScalarMultiply(N3VectorNormalize(N3VectorSubtract(distanceVector, lastDistanceVector)), length - traveledDistance));
            traveledDistance = length;
        } else {
            traveledDistance += N3VectorDistance(distanceVector, lastDistanceVector);
        }
        
        [planeRun.distances addObject:[NSNumber numberWithDouble:distanceVector.y*mmPerPixel]];
        lastDistanceVector = distanceVector;
        
        // and now update the range
        range = planeRun.range;
        range.length++;
        planeRun.range = range;
        
        if (traveledDistance == length) {
            break;
        }
        
        prevBottomPointAbove = bottomPointAbove;
    }
    
    // and walk back
    bottom = N3LineIntersectionWithPlane(N3LineMake(vectors[relativePositionIndex], projectionNormal), bottomPlane); // isn't this already set?
    prevBottomPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(bottom, transversePlane.point)) > 0.0;
        
    distance = N3VectorDotProduct(N3VectorSubtract(vectors[relativePositionIndex], midHeightPoint), projectionNormal);
    lastDistanceVector = N3VectorMake(relativePositionIndex, distance/mmPerPixel, 0);
    traveledDistance = 0;
    for (i = relativePositionIndex - 1; i >= 0; i--) {
        bottom = N3LineIntersectionWithPlane(N3LineMake(vectors[i], projectionNormal), bottomPlane);
        top = N3LineIntersectionWithPlane(N3LineMake(vectors[i], projectionNormal), topPlane);
        bottomPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(bottom, transversePlane.point)) > 0.0;
        topPointAbove = N3VectorDotProduct(transversePlane.normal, N3VectorSubtract(top, transversePlane.point)) > 0.0;
        
        // if we just walked off the projection
        if (bottomPointAbove == topPointAbove) {
            // figure out if we just walked up or down
            if (prevBottomPointAbove != bottomPointAbove) {
                distance = -(halfHeight*1e10);
            } else {
                distance = halfHeight*1e10;
            }
        } else {
            distance = N3VectorDotProduct(N3VectorSubtract(N3LineIntersectionWithPlane(N3LineMakeFromPoints(bottom, top), transversePlane), midHeightPoint), projectionNormal);
        }
        
        distanceVector = N3VectorMake(i, distance/mmPerPixel, 0);
        if (N3VectorDistance(distanceVector, lastDistanceVector) + traveledDistance > length) { // we can't make the whole segment
            distanceVector = N3VectorAdd(lastDistanceVector, N3VectorScalarMultiply(N3VectorNormalize(N3VectorSubtract(distanceVector, lastDistanceVector)), length - traveledDistance));
            traveledDistance = length;
        } else {
            traveledDistance += N3VectorDistance(distanceVector, lastDistanceVector);
        }
        
        [planeRun.distances insertObject:[NSNumber numberWithDouble:distanceVector.y*mmPerPixel] atIndex:0];
        lastDistanceVector = distanceVector;
        
        // and now update the range
        range = planeRun.range;
        range.location--;
        range.length++;
        planeRun.range = range;
        
        if (traveledDistance == length) {
            break;
        }
        
        prevBottomPointAbove = bottomPointAbove;
    }

    free(vectors);
    free(relativePositions);
    return planeRun;
}


- (NSArray *)_runsForPlane:(N3Plane)plane verticalLineIndexes:(NSArray **)verticalLinesHandle
{
	NSInteger numVectors;
	NSInteger i;
	BOOL topPointAbove;
	BOOL bottomPointAbove;
	BOOL prevBottomPointAbove;
	NSMutableArray *runs;
	NSMutableArray *verticalLines;
	CGFloat mmPerPixel;
	CGFloat halfHeight;
	CGFloat distance;
	N3Vector bottom;
	N3Vector top;
	_CPRStretchedViewPlaneRun *planeRun;
	NSRange range;
	NSInteger aboveOrBelow;
	NSInteger prevAboveOrBelow;
    NSInteger pixelsWide;
    N3Vector projectionNormal;
    N3BezierCoreRef flattenedBezierCore;
    N3BezierCoreRef projectedBezierCore;
    CGFloat projectedBezierLength;
    CGFloat sampleSpacing;
    N3VectorArray vectors;
    N3Plane topPlane;
    N3Plane bottomPlane;
    N3Vector midHeightPoint;
    
	runs = [NSMutableArray array];
	planeRun = nil;
    
	if (verticalLinesHandle) {
		verticalLines = [NSMutableArray array];
		*verticalLinesHandle = verticalLines;
	} else {
		verticalLines = nil;
	}
	
    mmPerPixel = [curDCM pixelSpacingX];
	halfHeight = ((CGFloat)curDCM.pheight*mmPerPixel)/2.0;
    
    // figure out how many horizonatal pixels we will have
    pixelsWide = curDCM.pwidth;
    projectionNormal = _projectionNormal;
    
    midHeightPoint = _midHeightPoint;
    topPlane = N3PlaneMake(N3VectorAdd(midHeightPoint, N3VectorScalarMultiply(projectionNormal, halfHeight)), projectionNormal);
    bottomPlane = N3PlaneMake(N3VectorAdd(midHeightPoint, N3VectorScalarMultiply(projectionNormal, -halfHeight)), projectionNormal);

    flattenedBezierCore = N3BezierCoreCreateFlattenedCopy([_curvedPath.bezierPath N3BezierCore], N3BezierDefaultFlatness);
    projectedBezierCore = N3BezierCoreCreateCopyProjectedToPlane(flattenedBezierCore, N3PlaneMake(N3VectorZero, projectionNormal));
    projectedBezierLength = N3BezierCoreLength(projectedBezierCore);
    sampleSpacing = projectedBezierLength / (CGFloat)pixelsWide;
    
    vectors = malloc(sizeof(N3Vector) * pixelsWide);
    
    numVectors = N3BezierCoreGetProjectedVectorInfo(flattenedBezierCore, sampleSpacing, 0, projectionNormal, vectors, NULL, NULL, NULL, pixelsWide);
    
    if (numVectors > 0) {
        while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
            vectors[numVectors] = vectors[numVectors - 1];
            numVectors++;
        }
    } else { // there are no vectors at all to copy from, so just zero out everthing
        while (numVectors < pixelsWide) { // make sure that the full array is filled and that there is not a vector that did not get filled due to roundoff error
            vectors[numVectors] = N3VectorZero;
            numVectors++;
        }
    }

	for (i = 0; i < numVectors; i++) {
        bottom = N3LineIntersectionWithPlane(N3LineMake(vectors[i], projectionNormal), bottomPlane);
        top = N3LineIntersectionWithPlane(N3LineMake(vectors[i], projectionNormal), topPlane);
		
		bottomPointAbove = N3VectorDotProduct(plane.normal, N3VectorSubtract(bottom, plane.point)) > 0.0;
		topPointAbove = N3VectorDotProduct(plane.normal, N3VectorSubtract(top, plane.point)) > 0.0;
        
		if (!bottomPointAbove && !topPointAbove) {
			aboveOrBelow = -1;
		} else if (bottomPointAbove && topPointAbove) {
			aboveOrBelow = 1;
		} else {
			aboveOrBelow = 0;
		}
		
		if (i == 0) {
			prevAboveOrBelow = aboveOrBelow;
		}
		
		if (bottomPointAbove != topPointAbove) {
			if (planeRun == nil) { //start a new run
				planeRun = [[_CPRStretchedViewPlaneRun alloc] init];
				range = planeRun.range;
				if (i != 0) {
					range.location = i-1;
					range.length = 1;
					if (prevBottomPointAbove != bottomPointAbove) {
						[planeRun.distances addObject:[NSNumber numberWithDouble:-halfHeight]];
					} else {
						[planeRun.distances addObject:[NSNumber numberWithDouble:halfHeight]];
					}
				}
			}            

            distance = N3VectorDotProduct(N3VectorSubtract(N3LineIntersectionWithPlane(N3LineMakeFromPoints(bottom, top), plane), midHeightPoint), projectionNormal);
			[planeRun.distances addObject:[NSNumber numberWithDouble:distance]];
			range.length++;
		} else {
			if (planeRun != nil) { // finish up and save the last run
				if (NSMaxRange(range) < numVectors) {
					range.length++;
					if (prevBottomPointAbove != bottomPointAbove) {
						[planeRun.distances addObject:[NSNumber numberWithDouble:-halfHeight]];
					} else {
						[planeRun.distances addObject:[NSNumber numberWithDouble:halfHeight]];
					}
				}
				planeRun.range = range;
				[runs addObject:planeRun];
				[planeRun release];
				planeRun = nil;
			} else if (ABS(prevAboveOrBelow - aboveOrBelow) == 2) { // if we switched sides without ever getting any points, put in a vertical line
				[verticalLines addObject:[NSNumber numberWithInteger:i]];
			}
		}
		
		prevAboveOrBelow = aboveOrBelow;
		prevBottomPointAbove =bottomPointAbove;
	}
	
	if (planeRun) {
		planeRun.range = range;
		[runs addObject:planeRun];
		[planeRun release];
		planeRun = nil;	
	}
	
	free(vectors);
	
	return runs;	
}


- (void)_updateMousePlanePointsForViewPoint:(NSPoint)point // this will modify _mousePlanePointsInPix and _displayInfo
{
	CGFloat lineDistance;
	CGFloat runDistance;
	N3Vector linePixVector;
	N3Vector lineVolumeVector;
	N3Vector runPixVector;
	N3Vector runVolumeVector;
    NSString *planeName;
    NSArray *verticalLines;
    NSArray *planeRuns;
	
	linePixVector = N3VectorZero;
	lineVolumeVector = N3VectorZero;
	runPixVector = N3VectorZero;
	runVolumeVector = N3VectorZero;
	
	[_displayInfo clearAllMouseVectors];
	[_mousePlanePointsInPix removeAllObjects];
	
    for (planeName in _planes) {
        verticalLines = [self valueForKey:[planeName stringByAppendingString:@"VerticalLines"]];
        planeRuns = [self valueForKey:[planeName stringByAppendingString:@"PlaneRuns"]];
        lineDistance = [self _distanceToPoint:point onVerticalLines:verticalLines pixVector:&linePixVector volumeVector:&lineVolumeVector];
        runDistance = [self _distanceToPoint:point onPlaneRuns:planeRuns pixVector:&runPixVector volumeVector:&runVolumeVector];
        if (MIN(lineDistance, runDistance) < 30) {
            if (lineDistance < runDistance) {
                [_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:linePixVector] forKey:planeName];
                [_displayInfo setMouseVector:lineVolumeVector forPlane:planeName];
            } else {
                [_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:runPixVector] forKey:planeName];
                [_displayInfo setMouseVector:runVolumeVector forPlane:planeName];
            }
        }
    }    
}

// point and distance are in view coordinates, vector is in patient coordinates closestPoint is in pixCoordinates
- (CGFloat)_distanceToPoint:(NSPoint)point onVerticalLines:(NSArray *)verticalLines pixVector:(N3VectorPointer)closestPixVectorPtr volumeVector:(N3VectorPointer)volumeVectorPtr;
{
	N3AffineTransform pixToViewTransform;
	NSNumber *indexNumber;
	N3Vector pixPointVector;
	N3Vector pixVector;
	N3Vector lineStart;
	N3Vector lineEnd;
//	CGFloat height;
	CGFloat distance;
	CGFloat minDistance;
    
    if ([curDCM pixelSpacingX] == 0 || [verticalLines count] == 0) {
        return CGFLOAT_MAX;
    }
    
	pixToViewTransform = N3AffineTransformInvert([self viewToPixTransform]);
	minDistance = CGFLOAT_MAX;
	pixPointVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(point), [self viewToPixTransform]);
    
	for (indexNumber in verticalLines) {
		lineStart = N3VectorMake([indexNumber doubleValue], 0, 0);
        lineEnd = N3VectorMake([indexNumber doubleValue], curDCM.pheight, 0);
		
		distance = N3VectorDistanceToLine(N3VectorMakeFromNSPoint(point), N3LineApplyTransform(N3LineMakeFromPoints(lineStart, lineEnd), pixToViewTransform));
		if (distance < minDistance) {
			minDistance = distance;
            pixVector = N3VectorMake([indexNumber doubleValue], pixPointVector.y, 0);
			if (closestPixVectorPtr) {
				*closestPixVectorPtr = pixVector;
			}
			
			if (volumeVectorPtr) {
                *volumeVectorPtr = [self _vectorForPixPoint:NSPointFromN3Vector(pixVector)];
			}
		}
	}
	return minDistance;
}

// point and distance are in view coordinates, vector is in patient coordinates closestPoint is in pixCoordinates
- (CGFloat)_distanceToPoint:(NSPoint)point onPlaneRuns:(NSArray *)planeRuns pixVector:(N3VectorPointer)closestPixVectorPtr volumeVector:(N3VectorPointer)volumeVectorPtr;
{
	CGFloat pixelsPerMm;
	N3Vector closeVector;
	N3Vector closestVector;
	N3Vector pointVector;
	CGFloat distance;
	CGFloat minDistance;
	_CPRStretchedViewPlaneRun *planeRun;
	N3MutableBezierPath *planeRunBezierPath;
	
    if ([curDCM pixelSpacingX] == 0 || [planeRuns count] == 0) {
        return CGFLOAT_MAX;
    }
    
	pointVector = N3VectorMakeFromNSPoint(point);
    pixelsPerMm = 1.0/[curDCM pixelSpacingX];

	minDistance = CGFLOAT_MAX;
	closestVector = N3VectorZero;
    
	for (planeRun in planeRuns) {
		planeRunBezierPath = [[N3MutableBezierPath alloc] initWithCPRStretchedViewPlaneRun:planeRun heightPixelsPerMm:pixelsPerMm];
		[planeRunBezierPath applyAffineTransform:N3AffineTransformMakeTranslation(0, (CGFloat)curDCM.pheight/2.0, 0)];
		[planeRunBezierPath applyAffineTransform:N3AffineTransformInvert([self viewToPixTransform])];
		
		N3BezierCoreRelativePositionClosestToVector([planeRunBezierPath N3BezierCore], pointVector, &closeVector, &distance);
		if (distance < minDistance) {
			minDistance = distance;
			closestVector = N3VectorApplyTransform(closeVector, [self viewToPixTransform]);
		}
		[planeRunBezierPath release];
		planeRunBezierPath = nil;
	}
	
	if (closestPixVectorPtr) {
		*closestPixVectorPtr = N3VectorMake(closestVector.x, closestVector.y, 0);
	}
	if (volumeVectorPtr) {
        *volumeVectorPtr = [self _vectorForPixPoint:NSPointFromN3Vector(closestVector)];
	}
    
	return minDistance;
}

- (void)_buildVerticalLinesAndPlaneRunsForPlaneFullName:(NSString *)planeFullName
{
    NSString *planeName;
    N3Plane plane;
    CGFloat slabThickness;
    NSArray *planeRuns;
    NSArray *vertialLines;
    
    if ([planeFullName hasSuffix:@"Top"]) {
        planeName = [planeFullName substringToIndex:[planeFullName length] - 3];
        slabThickness = [[self valueForKey:[planeName stringByAppendingString:@"SlabThickness"]] doubleValue];
        if (slabThickness == 0) {
            return;
        }
    } else if ([planeFullName hasSuffix:@"Bottom"]) {
        planeName = [planeFullName substringToIndex:[planeFullName length] - 6];
        slabThickness = -[[self valueForKey:[planeName stringByAppendingString:@"SlabThickness"]] doubleValue];
        if (slabThickness == 0) {
            return;
        }        
    } else {
        planeName = planeFullName;
        slabThickness = 0;
    }
    
    plane = [[self valueForKey:[planeName stringByAppendingString:@"Plane"]] N3PlaneValue];
    if (N3PlaneIsValid(plane)) {
        plane.normal = N3VectorNormalize(plane.normal);
        plane.point = N3VectorAdd(plane.point, N3VectorScalarMultiply(plane.normal, slabThickness/2.0));
        planeRuns = [self _runsForPlane:plane verticalLineIndexes:&vertialLines];
        [_verticalLines setValue:vertialLines forKey:planeFullName];
        [_planeRuns setValue:planeRuns forKey:planeFullName];
    }
}

- (void)_clearAllPlanes
{
    [_verticalLines removeAllObjects];
    [_planeRuns removeAllObjects];
}

- (void)_planeSetter:(N3Plane)plane
{
    NSString *selectorName;
    NSString *planeName;
    
    selectorName = NSStringFromSelector(_cmd);
    planeName = [selectorName stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:[[selectorName substringWithRange:NSMakeRange(3, 1)] lowercaseString]];
    planeName = [planeName substringToIndex:[planeName length] - 6];
    [_verticalLines removeObjectForKey:planeName];
    [_verticalLines removeObjectForKey:[planeName stringByAppendingString:@"Top"]];
    [_verticalLines removeObjectForKey:[planeName stringByAppendingString:@"Bottom"]];
    [_planeRuns removeObjectForKey:planeName];
    [_planeRuns removeObjectForKey:[planeName stringByAppendingString:@"Top"]];
    [_planeRuns removeObjectForKey:[planeName stringByAppendingString:@"Bottom"]];
    
    [_planes setValue:[NSValue valueWithN3Plane:plane] forKey:planeName];
    [self setNeedsDisplay:YES];
}

- (N3Plane)_planeGetter
{
    NSString *selectorName;
    NSString *planeName;
    
    selectorName = NSStringFromSelector(_cmd);
    planeName = [selectorName substringToIndex:[selectorName length] - 5];    
    return [[_planes valueForKey:planeName] N3PlaneValue];
}

- (void)_slabThicknessSetter:(CGFloat)thickness
{
    NSString *selectorName;
    NSString *planeName;
    
    selectorName = NSStringFromSelector(_cmd);
    planeName = [selectorName stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:[[selectorName substringWithRange:NSMakeRange(3, 1)] lowercaseString]];
    planeName = [planeName substringToIndex:[planeName length] - 14];
    [_verticalLines removeObjectForKey:planeName];
    [_planeRuns removeObjectForKey:planeName];
    [_slabThicknesses setValue:[NSNumber numberWithDouble:thickness] forKey:planeName];    
    [self setNeedsDisplay:YES];
}

- (CGFloat)_slabThicknessGetter
{
    NSString *selectorName;
    NSString *planeName;
    
    selectorName = NSStringFromSelector(_cmd);
    planeName = [selectorName substringToIndex:[selectorName length] - 13];    
    return [[_slabThicknesses valueForKey:planeName] doubleValue];
}

- (void)_planeColorSetter:(NSColor *)color
{
    NSString *selectorName;
    NSString *planeName;
    
    selectorName = NSStringFromSelector(_cmd);
    planeName = [selectorName stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:[[selectorName substringWithRange:NSMakeRange(3, 1)] lowercaseString]];
    planeName = [planeName substringToIndex:[planeName length] - 11];
    [_planeColors setValue:color forKey:planeName];
    [self setNeedsDisplay:YES];
}

- (NSColor *)_planeColorGetter
{
    NSString *selectorName;
    NSString *planeName;
    
    selectorName = NSStringFromSelector(_cmd);
    planeName = [selectorName substringToIndex:[selectorName length] - 10];  
    if ([_planeColors valueForKey:planeName] == nil) {
        [_planeColors setValue:[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1] forKey:planeName];
    }
    return [_planeColors valueForKey:planeName];
}

- (void)_buildTransverseVerticalLinesAndPlaneRuns
{
    NSUInteger verticalLine;
    _CPRStretchedViewPlaneRun *planeRun;
    
    CPRTransverseView *t = [[self windowController] middleTransverseView];
    CGFloat transverseWidth = (float)t.curDCM.pwidth/t.pixelsPerMm;
    transverseWidth /= self.pixelSpacingY;
    
    planeRun = [self _limitedRunForRelativePosition:[_curvedPath transverseSectionPosition] verticalLineIndex:&verticalLine lengthFromCenterline: transverseWidth];
    if (planeRun) {
        [_transversePlaneRuns setObject:[NSArray arrayWithObject:planeRun] forKey:@"center"];
    } else {
        [_transverseVerticalLines setObject:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:verticalLine]] forKey:@"center"];
    }
    
    planeRun = [self _limitedRunForRelativePosition:[_curvedPath leftTransverseSectionPosition] verticalLineIndex:&verticalLine lengthFromCenterline: transverseWidth];
    if (planeRun) {
        [_transversePlaneRuns setObject:[NSArray arrayWithObject:planeRun] forKey:@"left"];
    } else {
        [_transverseVerticalLines setObject:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:verticalLine]] forKey:@"left"];
    }
    
    planeRun = [self _limitedRunForRelativePosition:[_curvedPath rightTransverseSectionPosition] verticalLineIndex:&verticalLine lengthFromCenterline: transverseWidth];
    if (planeRun) {
        [_transversePlaneRuns setObject:[NSArray arrayWithObject:planeRun] forKey:@"right"];
    } else {
        [_transverseVerticalLines setObject:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:verticalLine]] forKey:@"right"];
    }
    
    
//    
//    _CPRStretchedViewPlaneRun *)_limitedRunForRelativePosition
//    N3Plane transversePlane;
//    NSArray *planeRuns;
//    NSArray *verticalLines;
//    
//    transversePlane.point = [_curvedPath.bezierPath vectorAtRelativePosition:[_curvedPath transverseSectionPosition]];
//    transversePlane.normal = [_curvedPath.bezierPath tangentAtRelativePosition:[_curvedPath transverseSectionPosition]];
//    planeRuns = [self _runsForPlane:transversePlane verticalLineIndexes:&verticalLines];
//    [_transverseVerticalLines setObject:verticalLines forKey:@"center"];
//    [_transversePlaneRuns setObject:planeRuns forKey:@"center"];
//    
//    transversePlane.point = [_curvedPath.bezierPath vectorAtRelativePosition:[_curvedPath leftTransverseSectionPosition]];
//    transversePlane.normal = [_curvedPath.bezierPath tangentAtRelativePosition:[_curvedPath leftTransverseSectionPosition]];
//    planeRuns = [self _runsForPlane:transversePlane verticalLineIndexes:&verticalLines];
//    [_transverseVerticalLines setObject:verticalLines forKey:@"left"];
//    [_transversePlaneRuns setObject:planeRuns forKey:@"left"];
//    
//    transversePlane.point = [_curvedPath.bezierPath vectorAtRelativePosition:[_curvedPath rightTransverseSectionPosition]];
//    transversePlane.normal = [_curvedPath.bezierPath tangentAtRelativePosition:[_curvedPath rightTransverseSectionPosition]];
//    planeRuns = [self _runsForPlane:transversePlane verticalLineIndexes:&verticalLines];
//    [_transverseVerticalLines setObject:verticalLines forKey:@"right"];
//    [_transversePlaneRuns setObject:planeRuns forKey:@"right"];
}

- (void)_clearTransversePlanes
{
    [_transverseVerticalLines removeAllObjects];
    [_transversePlaneRuns removeAllObjects];
}

- (N3Vector)_centerlinePixVectorForRelativePosition:(CGFloat)relativePosition
{
    N3Plane relativePositionPlane;
    NSArray *intersections;
    N3Vector relativePositionIntersection;
    
    if ([curDCM pixelSpacingX] == 0) {
        return N3VectorZero;
    }
    
    if (relativePosition == 0) {
        relativePositionIntersection = [self.centerlinePath vectorAtStart];
    } else if (relativePosition == 1) {
        relativePositionIntersection = [self.centerlinePath vectorAtEnd];
    } else {
        relativePositionPlane = N3PlaneMake(N3VectorMake(0, 0, relativePosition), N3VectorMake(0, 0, 1));
        intersections = [self.centerlinePath intersectionsWithPlane:relativePositionPlane]; // TODO make this O(log(n)) not O(n)
        
        if ([intersections count] == 0) {
            return N3VectorZero;
        } 
        
        relativePositionIntersection = [[intersections objectAtIndex:0] N3VectorValue];
    }
    
    return relativePositionIntersection;
}

- (CGFloat)_relativePositionForIndex:(NSInteger)index
{
    N3Plane plane;
    NSArray *intersections;
    
    plane = N3PlaneMake(N3VectorMake((CGFloat)index, 0, 0), N3VectorMake(1, 0, 0));
    
    intersections = [_centerlinePath intersectionsWithPlane:plane]; // TODO make this O(log(n)) not O(n) 
    if ([intersections count] == 0) {
        return 0;
    }
    
    return [[intersections objectAtIndex:0] N3VectorValue].z;
}

- (CGFloat)_relativePositionForPixPoint:(NSPoint)pixPoint
{
    N3Line pixLine;
    N3Vector closestVector;
    
    if (_centerlinePath == nil) {
        return 0;
    }
    
    closestVector = N3VectorZero;
    pixLine.point = N3VectorMakeFromNSPoint(pixPoint);
    pixLine.vector = N3VectorMake(0, 0, 1.0);
    
    [_centerlinePath relativePositionClosestToLine:pixLine closestVector:&closestVector];
    
    return MIN(MAX(closestVector.z, 0.0), 1.0);
}

- (N3Vector)_vectorForPixPoint:(NSPoint)pixPoint
{
    N3Plane intersectionPlane;
    NSArray *intersections;
    N3Vector intersectionVector;
    N3Vector vector;
    CGFloat relativePosition;
    CGFloat mmPerPixel;
    CGFloat pixDistance;
    CGFloat mmDistance;
    N3Vector projectionNormal;
        
    projectionNormal = _projectionNormal;
    mmPerPixel = [curDCM pixelSpacingX];
    intersectionPlane = N3PlaneMake(N3VectorMakeFromNSPoint(pixPoint), N3VectorMake(1.0, 0, 0));
    intersections = [_centerlinePath intersectionsWithPlane:intersectionPlane];
    if ([intersections count] == 0) {
        return N3VectorZero;
    }
    intersectionVector = [[intersections objectAtIndex:0] N3VectorValue];
    relativePosition = intersectionVector.z;
    vector = [_curvedPath.bezierPath vectorAtRelativePosition:relativePosition];
    pixDistance = pixPoint.y - intersectionVector.y;
    mmDistance = pixDistance * mmPerPixel;
    
    return N3VectorAdd(vector, N3VectorScalarMultiply(projectionNormal, mmDistance));
}

- (void)_pushBezierPath:(CGFloat)distance
{
    NSInteger i;
    CGFloat relativePosition;
    N3Vector tangent;
    N3Vector normal;
    N3Vector newNode;
    
    [self _sendWillEditCurvedPath];
    for (i = 0; i < [[_curvedPath nodes] count]; i++) {
        relativePosition = [_curvedPath relativePositionForNodeAtIndex:i];
        
        tangent = [_curvedPath.bezierPath tangentAtRelativePosition:relativePosition];
        normal = N3VectorNormalize(N3VectorCrossProduct(_projectionNormal, tangent));
        
        newNode = N3VectorAdd([[[_curvedPath nodes] objectAtIndex:i] N3VectorValue], N3VectorScalarMultiply(normal, distance));
        [_curvedPath moveNodeAtIndex:i toVector:newNode];
    }
    [self _sendDidEditCurvedPath];
}

- (void)_osirixUpdateVolumeDataNotification:(NSNotification *)notification
{
    self.lastRequest = nil;
    [self _setNeedsNewRequest];
}

@end

@implementation N3BezierPath (CPRStretchedViewPlaneRunAdditions)

- (id)initWithCPRStretchedViewPlaneRun:(_CPRStretchedViewPlaneRun *)planeRun heightPixelsPerMm:(CGFloat)pixelsPerMm
{
	NSInteger i;
	N3MutableBezierPath *mutableBezierPath;
	
	mutableBezierPath = [[N3MutableBezierPath alloc] init];
	for (i = planeRun.range.location; i < NSMaxRange(planeRun.range); i++) {
		if (i == planeRun.range.location) {
			[mutableBezierPath moveToVector:N3VectorMake(i, [[planeRun.distances objectAtIndex:i - planeRun.range.location] doubleValue] * pixelsPerMm, 0)];
		} else {
			[mutableBezierPath lineToVector:N3VectorMake(i, [[planeRun.distances objectAtIndex:i - planeRun.range.location] doubleValue] * pixelsPerMm, 0)];
		}
	}
	
	[self autorelease];
	self = mutableBezierPath;
	return self;
}

@end










