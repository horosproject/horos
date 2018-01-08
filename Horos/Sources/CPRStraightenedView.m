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

#import "options.h"

#import "CPRStraightenedView.h"
#import "CPRGenerator.h"
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

extern BOOL frameZoomed;
extern int splitPosition[ 3];

@interface _CPRStraightenedViewPlaneRun : NSObject
{
    NSRange _range;
    NSMutableArray *_distances;
}

@property (nonatomic, readwrite, assign) NSRange range;
@property (nonatomic, readwrite, retain) NSMutableArray *distances;

@end

@interface N3BezierPath (CPRStraightenedViewPlaneRunAdditions)
- (id)initWithCPRStraightenedViewPlaneRun:(_CPRStraightenedViewPlaneRun *)planeRun heightPixelsPerMm:(CGFloat)pixelsPerMm;
@end


@implementation _CPRStraightenedViewPlaneRun

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


@interface CPRStraightenedView ()

@property (nonatomic, readwrite, retain) CPRVolumeData *curvedVolumeData; // the volume data that was generated
@property (nonatomic, readwrite, retain) CPRStraightenedGeneratorRequest *lastRequest;
@property (nonatomic, readwrite, assign) BOOL drawAllNodes;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mousePlanePointsInPix;

+ (NSInteger)_fusionModeForCPRViewClippingRangeMode:(CPRViewClippingRangeMode)clippingRangeMode;

- (void)_sendNewRequestIfNeeded;
- (void)_sendNewRequest;

- (void)_sendWillEditCurvedPath;
- (void)_sendDidUpdateCurvedPath;
- (void)_sendDidEditCurvedPath;

- (void)_sendWillEditDisplayInfo;
- (void)_sendDidEditDisplayInfo;

- (void)_updateGeneratedHeight;
- (void)_adjustROIs;

- (void)_drawVerticalLines:(NSArray *)verticalLines;

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

- (void)_osirixUpdateVolumeDataNotification:(NSNotification *)notification;

@end


@implementation CPRStraightenedView

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
@synthesize mousePlanePointsInPix = _mousePlanePointsInPix;
@synthesize displayTransverseLines = _displayTransverseLines;
@synthesize displayCrossLines = _displayCrossLines;

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

- (void) drawRect:(NSRect)rect
{
	if( rect.size.width > 10)
	{
		_processingRequest = YES;
		[self _sendNewRequestIfNeeded];
		_processingRequest = NO;    
		
		[self _adjustROIs];
		
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
    N3Vector lineStart;
    N3Vector lineEnd;
    N3Vector cursorVector;
    N3AffineTransform pixToSubDrawRectTransform;
    CGFloat relativePosition;
    CGFloat draggedPosition;
    CGFloat transverseSectionPosition;
    CGFloat leftTransverseSectionPosition;
    CGFloat rightTransverseSectionPosition;
    CGFloat pixelsPerMm;
	NSColor *planeColor;
    NSInteger i;
	NSString *planeName;
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable(GL_BLEND);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glPointSize( 12 * self.window.backingScaleFactor);
	
    pixToSubDrawRectTransform = [self pixToSubDrawRectTransform];
    pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];

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
	
	lineStart = N3VectorMake(0, (CGFloat)curDCM.pheight/2.0, 0);
    lineEnd = N3VectorMake(curDCM.pwidth, (CGFloat)curDCM.pheight/2.0, 0);
    
    lineStart = N3VectorApplyTransform(lineStart, pixToSubDrawRectTransform);
    lineEnd = N3VectorApplyTransform(lineEnd, pixToSubDrawRectTransform);
    
	glLineWidth(2.0 * self.window.backingScaleFactor);
    glBegin(GL_LINES);
    glColor4d(0.0, 1.0, 0.0, 0.2);
    glVertex2d(lineStart.x, lineStart.y);
    glVertex2d(lineEnd.x, lineEnd.y);
    glEnd();
	
	glColor4d(0.0, 1.0, 0.0, 0.8);
    
    if ( [[self windowController] displayMousePosition] == YES && _displayInfo.mouseCursorHidden == NO)
	{
        cursorVector = N3VectorMake(curDCM.pwidth * _displayInfo.mouseCursorPosition, (CGFloat)curDCM.pheight/2.0, 0);
        cursorVector = N3VectorApplyTransform(cursorVector, pixToSubDrawRectTransform);
        
        glEnable(GL_POINT_SMOOTH);
        glPointSize(8 * self.window.backingScaleFactor);
        
        glBegin(GL_POINTS);
        glVertex2f(cursorVector.x, cursorVector.y);
        glEnd();
    }
    
    if (_displayInfo.draggedPositionHidden == NO)
	{
        glColor4d(1.0, 0.0, 0.0, 1.0);
        draggedPosition = _displayInfo.draggedPosition;
        lineStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*draggedPosition, 0, 0), pixToSubDrawRectTransform);
        lineEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*draggedPosition, curDCM.pheight, 0), pixToSubDrawRectTransform);
        glLineWidth(2.0 * self.window.backingScaleFactor);
        glBegin(GL_LINE_STRIP);
        glVertex2f(lineStart.x, lineStart.y);
        glVertex2f(lineEnd.x, lineEnd.y);
        glEnd();
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
		
        CPRTransverseView *t = [[self windowController] middleTransverseView];
        CGFloat transverseWidth = (float)t.curDCM.pwidth/t.pixelsPerMm;
        transverseWidth /= self.pixelSpacingY;
        
		for( int i = 0; i < noOfFrames; i++)
		{
			transverseSectionPosition = (startingDistance + ((float) i * exportTransverseSliceInterval)) / (float) _curvedPath.bezierPath.length;
			lineStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, curDCM.pheight/2. - transverseWidth/2., 0), pixToSubDrawRectTransform);
			lineEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, curDCM.pheight/2. + transverseWidth/2., 0), pixToSubDrawRectTransform);
			glLineWidth(2.0 * self.window.backingScaleFactor);
			glBegin(GL_LINE_STRIP);
			glVertex2f(lineStart.x, lineStart.y);
			glVertex2f(lineEnd.x, lineEnd.y);
			glEnd();
		}
	}
	else if(_displayTransverseLines)
	{
		N3Vector lineAStart, lineAEnd, lineBStart, lineBEnd, lineCStart, lineCEnd;
		
        CPRTransverseView *t = [[self windowController] middleTransverseView];
        CGFloat transverseWidth = (float)t.curDCM.pwidth/t.pixelsPerMm;
        transverseWidth /= self.pixelSpacingY;
        
		// draw the transverse section lines
		glColor4d(1.0, 1.0, 0.0, 1.0);
		transverseSectionPosition = _curvedPath.transverseSectionPosition;
		lineBStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, curDCM.pheight/2. - transverseWidth/2., 0), pixToSubDrawRectTransform);
		lineBEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, curDCM.pheight/2. + transverseWidth/2., 0), pixToSubDrawRectTransform);
		glLineWidth(2.0 * self.window.backingScaleFactor);
		glBegin(GL_LINE_STRIP);
		glVertex2f(lineBStart.x, lineBStart.y);
		glVertex2f(lineBEnd.x, lineBEnd.y);
		glEnd();
				
		leftTransverseSectionPosition = _curvedPath.leftTransverseSectionPosition;
		lineAStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*leftTransverseSectionPosition, curDCM.pheight/2. - transverseWidth/2., 0), pixToSubDrawRectTransform);
		lineAEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*leftTransverseSectionPosition, curDCM.pheight/2. + transverseWidth/2., 0), pixToSubDrawRectTransform);
		glLineWidth(1.0 * self.window.backingScaleFactor);
		glBegin(GL_LINE_STRIP);
		glVertex2f(lineAStart.x, lineAStart.y);
		glVertex2f(lineAEnd.x, lineAEnd.y);
		glEnd();
		
		rightTransverseSectionPosition = _curvedPath.rightTransverseSectionPosition;
		lineCStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*rightTransverseSectionPosition, curDCM.pheight/2. - transverseWidth/2., 0), pixToSubDrawRectTransform);
		lineCEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*rightTransverseSectionPosition, curDCM.pheight/2. + transverseWidth/2., 0), pixToSubDrawRectTransform);
		glBegin(GL_LINE_STRIP);
		glVertex2f(lineCStart.x, lineCStart.y);
		glVertex2f(lineCEnd.x, lineCEnd.y);
		glEnd();
		
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
            
            
            float quarter = -(lineAStart.y - lineAEnd.y)/3.;
            
            NSPoint tPt;
            
            tPt = [self positionWithoutRotation: NSMakePoint( lineAStart.x - [stringTexA frameSize].width, quarter+lineAStart.y)];
            glColor4f (0, 0, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+1) ratio: 1];
            glColor4f (1, 1, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(tPt.x, tPt.y) ratio: 1];
            
            tPt = [self positionWithoutRotation: NSMakePoint( lineBStart.x - [stringTexB frameSize].width, quarter+lineBStart.y)];
            glColor4f (0, 0, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(tPt.x+1, tPt.y+1) ratio: 1];
            glColor4f (1, 1, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(tPt.x, tPt.y) ratio: 1];
            
            tPt = [self positionWithoutRotation: NSMakePoint( lineCStart.x - [stringTexC frameSize].width, quarter+lineCStart.y)];
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
        
        if (_displayInfo.mouseTransverseSection != CPRTransverseViewNoneSectionType) {
            switch (_displayInfo.mouseTransverseSection) {
                case CPRTransverseViewLeftSectionType:
                    relativePosition = _curvedPath.leftTransverseSectionPosition;
                    break;
                case CPRTransverseViewCenterSectionType:
                    relativePosition = _curvedPath.transverseSectionPosition;
                    break;
                case CPRTransverseViewRightSectionType:
                    relativePosition = _curvedPath.rightTransverseSectionPosition;
                    break;
                default:
                    relativePosition = 0;
                    break;
            }
            
            cursorVector = N3VectorMake((CGFloat)curDCM.pwidth*relativePosition, ((CGFloat)curDCM.pheight/2.0)+(_displayInfo.mouseTransverseSectionDistance*pixelsPerMm), 0);
            cursorVector = N3VectorApplyTransform(cursorVector, pixToSubDrawRectTransform);
            
            glColor4d(1.0, 1.0, 0.0, 1.0);
            glEnable(GL_POINT_SMOOTH);
            glPointSize(8 * self.window.backingScaleFactor);
            glBegin(GL_POINTS);
            glVertex2f(cursorVector.x, cursorVector.y);
            glEnd();
        }
    }
	
    if (_drawAllNodes)
	{
        for (i = 0; i < [_curvedPath.nodes count]; i++)
		{
            relativePosition = [_curvedPath relativePositionForNodeAtIndex:i];
            cursorVector = N3VectorMake(curDCM.pwidth * relativePosition, (CGFloat)curDCM.pheight/2.0, 0);
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
    
	glLineWidth(1.0 * self.window.backingScaleFactor);
	
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
		N3Line line;
		NSInteger i;
		BOOL overNode;
		NSInteger hoverNodeIndex;
		CGFloat relativePosition;
        CGFloat distance;
        CGFloat minDistance;
		
		viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		if( NSPointInRect( viewPoint, [self bounds]) == NO)
			return;
		
		pixVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(viewPoint), [self viewToPixTransform]);
		
		if (NSPointInRect(viewPoint, self.bounds) && curDCM.pwidth > 0) {
			[self _sendWillEditDisplayInfo];
			_displayInfo.mouseCursorPosition = MIN(MAX(pixVector.x/(CGFloat)curDCM.pwidth, 0.0), 1.0);
			[self setNeedsDisplay:YES];
		
			[self _updateMousePlanePointsForViewPoint:viewPoint];  // this will modify _mousePlanePointsInPix and _displayInfo
			
            // test to see if the mouse is near a trasverse line
            _displayInfo.mouseTransverseSection = CPRTransverseViewNoneSectionType;
            _displayInfo.mouseTransverseSectionDistance = 0.0;
            if (_displayTransverseLines) {
                distance = ABS(pixVector.x - _curvedPath.leftTransverseSectionPosition*(CGFloat)curDCM.pwidth);
                minDistance = distance;
                if (distance < 20.0) {
                    _displayInfo.mouseTransverseSection = CPRTransverseViewLeftSectionType;
                    _displayInfo.mouseTransverseSectionDistance = (pixVector.y - ((CGFloat)curDCM.pheight/2.0))*([_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth);
                }
                distance = ABS(pixVector.x - _curvedPath.rightTransverseSectionPosition*(CGFloat)curDCM.pwidth);
                if (distance < 20.0 && distance < minDistance) {
                    _displayInfo.mouseTransverseSection = CPRTransverseViewRightSectionType;
                    _displayInfo.mouseTransverseSectionDistance = (pixVector.y - ((CGFloat)curDCM.pheight/2.0))*([_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth);
                    minDistance = distance;
                }
                distance = ABS(pixVector.x - _curvedPath.transverseSectionPosition*(CGFloat)curDCM.pwidth);
                if (distance < 20.0 && distance < minDistance) {
                    _displayInfo.mouseTransverseSection = CPRTransverseViewCenterSectionType;
                    _displayInfo.mouseTransverseSectionDistance = (pixVector.y - ((CGFloat)curDCM.pheight/2.0))*([_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth);
                }
            }            
            
			line = N3LineMake(N3VectorMake(0, (CGFloat)curDCM.pheight / 2.0, 0), N3VectorMake(1, 0, 0));
			line = N3LineApplyTransform(line, N3AffineTransformInvert([self viewToPixTransform]));
			
			if (N3VectorDistanceToLine(N3VectorMakeFromNSPoint(viewPoint), line) < 20.0) {
				self.drawAllNodes = YES;
			} else {
				self.drawAllNodes = NO;
			}
			
			overNode = NO;
			hoverNodeIndex = 0;
			if (self.drawAllNodes) {
				for (i = 0; i < [_curvedPath.nodes count]; i++) {
					relativePosition = [_curvedPath relativePositionForNodeAtIndex:i];
					
					if (N3VectorDistance(N3VectorMakeFromNSPoint(viewPoint),
										  N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*relativePosition, (CGFloat)curDCM.pheight/2.0, 0), N3AffineTransformInvert([self viewToPixTransform]))) < 10.0) {
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
		
		if( [[self windowController] exportSequenceType] == CPRSeriesExportSequenceType && [[self windowController] exportSeriesType] == CPRTransverseViewsExportSeriesType)
			exportTransverseSliceInterval = [[self windowController] exportTransverseSliceInterval];
		
		
		if( curDCM.pwidth != 0 && exportTransverseSliceInterval == 0 && _displayTransverseLines && ((ABS((pixVector.x/curDCM.pwidth) - _curvedPath.transverseSectionPosition)*curDCM.pwidth < 5.0) || (ABS((pixVector.x/curDCM.pwidth) - _curvedPath.leftTransverseSectionPosition)*curDCM.pwidth < 10.0) || (ABS((pixVector.x/curDCM.pwidth) - _curvedPath.rightTransverseSectionPosition)*curDCM.pwidth < 10.0)))
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
    CGFloat pixWidth;
    CGFloat relativePosition;
    NSInteger i;
    
    viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    pixVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(viewPoint), [self viewToPixTransform]);
    pixWidth = curDCM.pwidth;
    _clickedNode = NO;
    
    if (pixWidth == 0.0) {
        [super mouseDown:event];
        return;
    }
	
	float exportTransverseSliceInterval = 0;
	
	if( [[self windowController] exportSequenceType] == CPRSeriesExportSequenceType && [[self windowController] exportSeriesType] == CPRTransverseViewsExportSeriesType)
		exportTransverseSliceInterval = [[self windowController] exportTransverseSliceInterval];
	
    if( exportTransverseSliceInterval == 0 && _displayTransverseLines && (ABS((pixVector.x/pixWidth) - _curvedPath.transverseSectionPosition)*pixWidth < 5.0))
	{
		[self _sendWillEditCurvedPath];
        _draggingTransverse = YES;
		[self mouseMoved: event];
    }
	else if( exportTransverseSliceInterval == 0 && _displayTransverseLines && ((ABS((pixVector.x/pixWidth) - _curvedPath.leftTransverseSectionPosition)*pixWidth < 10.0) ||  (ABS((pixVector.x/pixWidth) - _curvedPath.rightTransverseSectionPosition)*pixWidth < 10.0)))
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
            
            if (N3VectorDistance(N3VectorMakeFromNSPoint(viewPoint),
                                  N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*relativePosition, (CGFloat)curDCM.pheight/2.0, 0), N3AffineTransformInvert([self viewToPixTransform]))) < 10.0) {
                if ([_delegate respondsToSelector:@selector(CPRView:setCrossCenter:)]) {
                    [_delegate CPRView: [[self windowController] mprView1] setCrossCenter:[[_curvedPath.nodes objectAtIndex:i] N3VectorValue]];
                }
                _clickedNode = YES;
                break;
            }
        }
        if (_clickedNode == NO)
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
					if( currentTool != tText && currentTool != tArrow)
						currentTool = tMesure;
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
    
	if( _clickedNode)
		return;
	
    viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    pixVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(viewPoint), [self viewToPixTransform]);
    pixWidth = curDCM.pwidth;
    
    if (pixWidth == 0.0) {
        [super mouseDragged:event];
        return;
    }
    
    if (_draggingTransverse)
	{
        relativePosition = pixVector.x/pixWidth;
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
        _curvedPath.transverseSectionSpacing = ABS(pixVector.x/pixWidth-_curvedPath.transverseSectionPosition)*[_curvedPath.bezierPath length];
		[self _sendDidUpdateCurvedPath];

		[self _sendWillEditDisplayInfo];
        _displayInfo.mouseCursorPosition = pixVector.x/pixWidth;
		[self _sendDidEditDisplayInfo];
        [self setNeedsDisplay:YES];
		[self mouseMoved: event];
    }
	else
	{
		[self _sendWillEditDisplayInfo];
        _displayInfo.mouseCursorPosition = pixVector.x/pixWidth;
		[self _sendDidEditDisplayInfo];

        [super mouseDragged:event];
    }
}

- (void)mouseUp:(NSEvent *)event
{
	if (_draggingTransverse) {
		_draggingTransverse = NO;
		[self _sendDidEditCurvedPath];
	} else if (_draggingTransverseSpacing) {
		_draggingTransverseSpacing = NO;
		[self _sendDidEditCurvedPath];
	}
    
    [super mouseUp:event];
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

- (void) updatePresentationStateFromSeriesOnlyImageLevel: (BOOL) onlyImage
{
}

- (void)generator:(CPRGenerator *)generator didGenerateVolume:(CPRVolumeData *)volume request:(CPRGeneratorRequest *)request
{
	if( [self windowController] == nil)
		return;
		
//    static NSDate *lastDate = nil;
//    if (lastDate == nil) {
//        lastDate = [[NSDate date] retain];
//    }
//    
//    [lastDate release];
//    lastDate = [[NSDate date] retain];
    
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
		
		[self _clearAllPlanes];
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
            NSLog(@"%s asking for invalid clipping range mode: %d", __func__,  (int) clippingRangeMode);
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
    CPRStraightenedGeneratorRequest *request;
    
    if ([_curvedPath.bezierPath elementCount] >= 3)
	{
        request = [[CPRStraightenedGeneratorRequest alloc] init];
        
        request.interpolationMode = [[self windowController] selectedInterpolationMode];
        
        if( [[self windowController] viewsPosition] == VerticalPosition)
        {
            request.pixelsWide = [self bounds].size.height*1.2;
            request.pixelsHigh = [self bounds].size.width*1.2;
		}
        else
        {
            request.pixelsWide = [self bounds].size.width*1.2;
            request.pixelsHigh = [self bounds].size.height*1.2;
		}
        request.slabWidth = _curvedPath.thickness;

        request.slabSampleDistance = 0;
        request.bezierPath = _curvedPath.bezierPath;
        request.initialNormal = _curvedPath.initialNormal;
        request.projectionMode = _clippingRangeMode;
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

- (void)_adjustROIs
{
	if([self.curvedPath isPlaneMeasurable] == NO)
	{
		for( int i = 0; i < curRoiList.count; i++ )
		{
			ROI *r = [curRoiList objectAtIndex:i];
			if( r.type != tMesure && r.type != tText && r.type != tArrow)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:r userInfo: nil];
				[curRoiList removeObjectAtIndex:i];
				i--;
			}
			else
				r.displayCMOrPixels = YES; // We don't want the value in pixels
		}
		
		for( ROI *c in curRoiList)
		{
			if( c.type == tMesure)
			{
				NSMutableArray *points = c.points;
				
				NSPoint A = [[points objectAtIndex: 0] point];
				NSPoint B = [[points objectAtIndex: 1] point];
				
				if( fabs( A.x - B.x) > 4 || fabs( A.y - B.y) > 4)
				{
					if( fabs( A.x - B.x) > fabs( A.y - B.y) || A.y == [curDCM pheight] / 2)
					{
						// Horizontal length -> centered in y, and horizontal
						
						A.y = [curDCM pheight] / 2;
						B.y = [curDCM pheight] / 2;
						
						[[points objectAtIndex: 0] setPoint: A];
						[[points objectAtIndex: 1] setPoint: B];
					}
					else
					{
						// Vectical length -> vertical
						
						A.x = B.x;
						
						[[points objectAtIndex: 0] setPoint: A];
						[[points objectAtIndex: 1] setPoint: B];
					}
				}
			}
		}
	}
	else
	{
		for( ROI *r in curRoiList)
			r.displayCMOrPixels = YES;
	}
	
	[self setNeedsDisplay: YES];
}

- (void)_drawVerticalLines:(NSArray *)verticalLines
{
	NSNumber *indexNumber;
	N3Vector lineStart;
	N3Vector lineEnd;
    double pixToSubdrawRectOpenGLTransform[16];
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
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

- (void)_drawPlaneRuns:(NSArray*)planeRuns
{
	CGFloat pixelsPerMm;
	NSInteger i;
	N3Vector planePointVector;
	_CPRStraightenedViewPlaneRun *planeRun;
    double pixToSubdrawRectOpenGLTransform[16];
    CGFloat pheight_2;
    
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	if( cgl_ctx == nil)
        return;
    
	pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];
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
	N3VectorArray normals;
	N3VectorArray points;
	N3Vector bottom;
	N3Vector top;
	_CPRStraightenedViewPlaneRun *planeRun;
	NSRange range;
	NSInteger aboveOrBelow;
	NSInteger prevAboveOrBelow;


	points = malloc(curDCM.pwidth * sizeof(N3Vector));
	normals = malloc(curDCM.pwidth * sizeof(N3Vector));
	runs = [NSMutableArray array];
	planeRun = nil;

	if (verticalLinesHandle) {
		verticalLines = [NSMutableArray array];
		*verticalLinesHandle = verticalLines;
	} else {
		verticalLines = nil;
	}
	
	mmPerPixel = [_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth;
	halfHeight = ((CGFloat)curDCM.pheight*mmPerPixel)/2.0;
	numVectors = N3BezierCoreGetVectorInfo([_curvedPath.bezierPath N3BezierCore], [_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth, 0, _curvedPath.initialNormal, points, NULL, normals, curDCM.pwidth);
	
	for (i = 0; i < numVectors; i++) {
		bottom = N3VectorAdd(points[i], N3VectorScalarMultiply(normals[i], -halfHeight));
		top = N3VectorAdd(points[i], N3VectorScalarMultiply(normals[i], halfHeight));
		
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
				planeRun = [[_CPRStraightenedViewPlaneRun alloc] init];
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
			distance = N3VectorDotProduct(N3VectorSubtract(N3LineIntersectionWithPlane(N3LineMakeFromPoints(bottom, top), plane), points[i]), normals[i]);
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
	
	free(points);
	free(normals);
	
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
	CGFloat pixelsPerMm;
	NSNumber *indexNumber;
	N3Vector pixPointVector;
	N3Vector pixVector;
	N3Vector lineStart;
	N3Vector lineEnd;
	CGFloat relativePosition;
	CGFloat distance;
	CGFloat minDistance;
	N3Vector normalVector;
    
	pixToViewTransform = N3AffineTransformInvert([self viewToPixTransform]);
	minDistance = CGFLOAT_MAX;
	pixPointVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(point), [self viewToPixTransform]);
	pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];

	for (indexNumber in verticalLines) {
		lineStart = N3VectorMake([indexNumber doubleValue], 0, 0);
        lineEnd = N3VectorMake([indexNumber doubleValue], curDCM.pheight, 0);
		
		distance = N3VectorDistanceToLine(N3VectorMakeFromNSPoint(point), N3LineApplyTransform(N3LineMakeFromPoints(lineStart, lineEnd), pixToViewTransform));
		if (distance < minDistance) {
			minDistance = distance;
			if (closestPixVectorPtr) {
				pixVector = N3VectorMake([indexNumber doubleValue], pixPointVector.y, 0);
				*closestPixVectorPtr = pixVector;
			}
			
			if (volumeVectorPtr) {
				relativePosition = [indexNumber doubleValue]/(CGFloat)curDCM.pwidth;
				normalVector = [_curvedPath.bezierPath normalAtRelativePosition:relativePosition initialNormal:_curvedPath.initialNormal];
				*volumeVectorPtr = N3VectorAdd([_curvedPath.bezierPath vectorAtRelativePosition:relativePosition], N3VectorScalarMultiply(normalVector, (pixPointVector.y - (CGFloat)curDCM.pheight/2.0)/ pixelsPerMm));
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
	N3Vector normalVector;
	CGFloat distance;
	CGFloat minDistance;
	CGFloat relativePosition;
	_CPRStraightenedViewPlaneRun *planeRun;
	N3MutableBezierPath *planeRunBezierPath;
	
	pointVector = N3VectorMakeFromNSPoint(point);
	pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];
	minDistance = CGFLOAT_MAX;
	closestVector = N3VectorZero;
    
	for (planeRun in planeRuns) {
		planeRunBezierPath = [[N3MutableBezierPath alloc] initWithCPRStraightenedViewPlaneRun:planeRun heightPixelsPerMm:pixelsPerMm];
		[planeRunBezierPath applyAffineTransform:N3AffineTransformMakeTranslation(0, (CGFloat)curDCM.pheight/2.0, 0)];
		[planeRunBezierPath applyAffineTransform:N3AffineTransformInvert([self viewToPixTransform])];
		
		N3BezierCoreRelativePositionClosestToVector([planeRunBezierPath N3BezierCore], pointVector, &closeVector, &distance);
		if (distance < minDistance) {
			minDistance = distance;
			closestVector = N3VectorApplyTransform(closeVector, [self viewToPixTransform]);
			closestVector.y -= (CGFloat)curDCM.pheight/2.0;
		}
		[planeRunBezierPath release];
		planeRunBezierPath = nil;
	}
	
	if (closestPixVectorPtr) {
		*closestPixVectorPtr = N3VectorMake(closestVector.x, closestVector.y + (CGFloat)curDCM.pheight/2.0, 0);
	}
	if (volumeVectorPtr) {
		relativePosition = closestVector.x/(CGFloat)curDCM.pwidth;
		normalVector = [_curvedPath.bezierPath normalAtRelativePosition:relativePosition initialNormal:_curvedPath.initialNormal];
		*volumeVectorPtr = N3VectorAdd([_curvedPath.bezierPath vectorAtRelativePosition:relativePosition], N3VectorScalarMultiply(normalVector, closestVector.y / pixelsPerMm));
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

- (void)_osirixUpdateVolumeDataNotification:(NSNotification *)notification
{
    self.lastRequest = nil;
    [self _setNeedsNewRequest];
}

@end

@implementation N3BezierPath (CPRViewPlaneRunAdditions)

- (id)initWithCPRStraightenedViewPlaneRun:(_CPRStraightenedViewPlaneRun *)planeRun heightPixelsPerMm:(CGFloat)pixelsPerMm
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
				  
				  
				  
				  
				  
				  
				  
				  
				  
				  
				  













