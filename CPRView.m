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

#import "CPRView.h"
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

extern BOOL frameZoomed;
extern int splitPosition[ 3];

@interface _CPRViewPlaneRun : NSObject
{
    NSRange _range;
    NSMutableArray *_distances;
}

@property (nonatomic, readwrite, assign) NSRange range;
@property (nonatomic, readwrite, retain) NSMutableArray *distances;

@end

@interface N3BezierPath (CPRViewPlaneRunAdditions)
- (id)initWithCPRViewPlaneRun:(_CPRViewPlaneRun *)planeRun heightPixelsPerMm:(CGFloat)pixelsPerMm;
@end


@implementation _CPRViewPlaneRun

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


@interface CPRView ()

@property (nonatomic, readwrite, retain) CPRVolumeData *curvedVolumeData; // the volume data that was generated
@property (nonatomic, readwrite, retain) CPRStraightenedGeneratorRequest *lastRequest;
@property (nonatomic, readwrite, assign) BOOL drawAllNodes;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mousePlanePointsInPix;

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

- (void)_drawVerticalLines:(NSArray *)verticalLines;

- (void)_updateMousePlanePointsForViewPoint:(NSPoint)point; // this will modify _mousePlanePointsInPix and _displayInfo
- (CGFloat)_distanceToPoint:(NSPoint)point onVerticalLines:(NSArray *)verticalLines pixVector:(N3VectorPointer)closestPixVectorPtr volumeVector:(N3VectorPointer)volumeVectorPtr;
- (CGFloat)_distanceToPoint:(NSPoint)point onPlaneRuns:(NSArray *)planeRuns pixVector:(N3VectorPointer)closestPixVectorPtr volumeVector:(N3VectorPointer)volumeVectorPtr;

- (void)_drawPlaneRuns:(NSArray*)planeRuns;
- (NSArray *)_runsForPlane:(N3Plane)plane verticalLineIndexes:(NSArray **)verticalLinesHandle;
- (NSArray *)_orangePlaneRuns;
- (NSArray *)_purplePlaneRuns;
- (NSArray *)_bluePlaneRuns;
- (NSArray *)_orangeTopPlaneRuns;
- (NSArray *)_purpleTopPlaneRuns;
- (NSArray *)_blueTopPlaneRuns;
- (NSArray *)_orangeBottomPlaneRuns;
- (NSArray *)_purpleBottomPlaneRuns;
- (NSArray *)_blueBottomPlaneRuns;
- (NSArray *)_orangeVerticalLines;
- (NSArray *)_purpleVerticalLines;
- (NSArray *)_blueVerticalLines;
- (NSArray *)_orangeTopVerticalLines;
- (NSArray *)_purpleTopVerticalLines;
- (NSArray *)_blueTopVerticalLines;
- (NSArray *)_orangeBottomVerticalLines;
- (NSArray *)_purpleBottomVerticalLines;
- (NSArray *)_blueBottomVerticalLines;
- (void)_clearAllPlanes;


@end


@implementation CPRView

@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;
@synthesize curvedPath = _curvedPath;
@synthesize displayInfo = _displayInfo;
@synthesize curvedVolumeData = _curvedVolumeData;
@synthesize clippingRangeMode = _clippingRangeMode;
@synthesize lastRequest = _lastRequest;
@synthesize drawAllNodes = _drawAllNodes;
@synthesize orangePlane = _orangePlane;
@synthesize purplePlane = _purplePlane;
@synthesize bluePlane = _bluePlane;
@synthesize orangeSlabThickness = _orangeSlabThickness;
@synthesize purpleSlabThickness = _purpleSlabThickness;
@synthesize blueSlabThickness = _blueSlabThickness;
@synthesize orangePlaneColor = _orangePlaneColor;
@synthesize purplePlaneColor = _purplePlaneColor;
@synthesize bluePlaneColor = _bluePlaneColor;
@synthesize mousePlanePointsInPix = _mousePlanePointsInPix;
@synthesize displayTransverseLines;
@synthesize displayCrossLines = _displayCrossLines;

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
		_orangePlaneColor = [[NSColor orangeColor] retain];
		_purplePlaneColor = [[NSColor purpleColor] retain];
		_bluePlaneColor = [[NSColor blueColor] retain];
		_mousePlanePointsInPix = [[NSMutableDictionary alloc] init];
		_displayCrossLines = YES;
		displayTransverseLines = YES;
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

	[self _clearAllPlanes];
	
	[_orangePlaneColor release];
	_orangePlaneColor = nil;
	[_purplePlaneColor release];
	_purplePlaneColor = nil;
	[_bluePlaneColor release];
	_bluePlaneColor = nil;
    
	[_mousePlanePointsInPix release];
	_mousePlanePointsInPix = nil;
	
	[stanStringAttrib release];
	[stringTexA release];
	[stringTexB release];
	[stringTexC release];
	
    [super dealloc];
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

- (void)setOrangePlaneColor:(NSColor *)color
{
    if (_orangePlaneColor != color) {
        [_orangePlaneColor release];
        _orangePlaneColor = [color retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setPurplePlaneColor:(NSColor *)color
{
    if (_purplePlaneColor != color) {
        [_purplePlaneColor release];
        _purplePlaneColor = [color retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setBluePlaneColor:(NSColor *)color
{
    if (_bluePlaneColor != color) {
        [_bluePlaneColor release];
        _bluePlaneColor = [color retain];
        [self setNeedsDisplay:YES];
    }
}

- (void)setOrangePlane:(N3Plane)orangePlane;
{
	if (N3PlaneEqualToPlane(orangePlane, _orangePlane) == NO) {
		_orangePlane = orangePlane;
		[_orangeVericalLines release];
		_orangeVericalLines = nil;
		[_orangePlaneRuns release];
		_orangePlaneRuns = nil;
		
		[_orangeTopVericalLines release];
		_orangeTopVericalLines = nil;
		[_orangeTopPlaneRuns release];
		_orangeTopPlaneRuns = nil;
		
		[_orangeBottomVericalLines release];
		_orangeBottomVericalLines = nil;
		[_orangeBottomPlaneRuns release];
		_orangeBottomPlaneRuns = nil;
		[self setNeedsDisplay:YES];
	}
}

- (void)setPurplePlane:(N3Plane)purplePlane;
{
	if (N3PlaneEqualToPlane(purplePlane, _purplePlane) == NO) {
		_purplePlane = purplePlane;
		[_purpleVericalLines release];
		_purpleVericalLines = nil;
		[_purplePlaneRuns release];
		_purplePlaneRuns = nil;
		
		[_purpleTopVericalLines release];
		_purpleTopVericalLines = nil;
		[_purpleTopPlaneRuns release];
		_purpleTopPlaneRuns = nil;
		
		[_purpleBottomVericalLines release];
		_purpleBottomVericalLines = nil;
		[_purpleBottomPlaneRuns release];
		_purpleBottomPlaneRuns = nil;
		[self setNeedsDisplay:YES];
	}
}

- (void)setBluePlane:(N3Plane)bluePlane;
{
	if (N3PlaneEqualToPlane(bluePlane, _bluePlane) == NO) {
		_bluePlane = bluePlane;
		[_blueVericalLines release];
		_blueVericalLines = nil;
		[_bluePlaneRuns release];
		_bluePlaneRuns = nil;

		[_blueTopVericalLines release];
		_blueTopVericalLines = nil;
		[_blueTopPlaneRuns release];
		_blueTopPlaneRuns = nil;

		[_blueBottomVericalLines release];
		_blueBottomVericalLines = nil;
		[_blueBottomPlaneRuns release];
		_blueBottomPlaneRuns = nil;
		[self setNeedsDisplay:YES];
	}
}

- (void)setOrangeSlabThickness:(CGFloat)slabThickness
{
	if (slabThickness != _orangeSlabThickness) {
		_orangeSlabThickness = slabThickness;
		[_orangeTopVericalLines release];
		_orangeTopVericalLines = nil;
		[_orangeTopPlaneRuns release];
		_orangeTopPlaneRuns = nil;
		[_orangeBottomVericalLines release];
		_orangeBottomVericalLines = nil;
		[_orangeBottomPlaneRuns release];
		_orangeBottomPlaneRuns = nil;
	}
}

- (void)setPurpleSlabThickness:(CGFloat)slabThickness
{
	if (slabThickness != _purpleSlabThickness) {
		_purpleSlabThickness = slabThickness;
		[_purpleTopVericalLines release];
		_purpleTopVericalLines = nil;
		[_purpleTopPlaneRuns release];
		_purpleTopPlaneRuns = nil;
		[_purpleBottomVericalLines release];
		_purpleBottomVericalLines = nil;
		[_purpleBottomPlaneRuns release];
		_purpleBottomPlaneRuns = nil;
	}
}

- (void)setBlueSlabThickness:(CGFloat)slabThickness
{
	if (slabThickness != _blueSlabThickness) {
		_blueSlabThickness = slabThickness;
		[_blueTopVericalLines release];
		_blueTopVericalLines = nil;
		[_blueTopPlaneRuns release];
		_blueTopPlaneRuns = nil;
		[_blueBottomVericalLines release];
		_blueBottomVericalLines = nil;
		[_blueBottomPlaneRuns release];
		_blueBottomPlaneRuns = nil;
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

- (void) drawRect:(NSRect)rect
{
	if( rect.size.width > 10)
	{
		_processingRequest = YES;
		[self _sendNewRequestIfNeeded];
		_processingRequest = NO;    
		
		[self adjustROIsForCPRView];
		
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
	N3Vector planePointVector;
    N3AffineTransform pixToSubDrawRectTransform;
    CGFloat relativePosition;
    CGFloat draggedPosition;
    CGFloat transverseSectionPosition;
    CGFloat leftTransverseSectionPosition;
    CGFloat rightTransverseSectionPosition;
    CGFloat pixelsPerMm;
	NSColor *planeColor;
    NSInteger i;
	NSArray *planeRuns;
	NSArray *verticalLines;
	NSNumber *indexNumber;
	NSString *planeName;
	_CPRViewPlaneRun *planeRun;
    CGLContextObj cgl_ctx;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];    
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable(GL_BLEND);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glPointSize( 12);
	
    pixToSubDrawRectTransform = [self pixToSubDrawRectTransform];
    pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];

    glLineWidth(2.0);
    // draw planes
    glColor4f ([_orangePlaneColor redComponent], [_orangePlaneColor greenComponent], [_orangePlaneColor blueComponent], [_orangePlaneColor alphaComponent]);
    [self _drawPlaneRuns:[self _orangePlaneRuns]];
    [self _drawVerticalLines:[self _orangeVerticalLines]];
    glLineWidth(1.0);
    [self _drawPlaneRuns:[self _orangeTopPlaneRuns]];
    [self _drawPlaneRuns:[self _orangeBottomPlaneRuns]];
    [self _drawVerticalLines:[self _orangeTopVerticalLines]];
    [self _drawVerticalLines:[self _orangeBottomVerticalLines]];
    
    glLineWidth(2.0);
    // draw planes
    glColor4f ([_purplePlaneColor redComponent], [_purplePlaneColor greenComponent], [_purplePlaneColor blueComponent], [_purplePlaneColor alphaComponent]);
    [self _drawPlaneRuns:[self _purplePlaneRuns]];
    [self _drawVerticalLines:[self _purpleVerticalLines]];
    glLineWidth(1.0);
    [self _drawPlaneRuns:[self _purpleTopPlaneRuns]];
    [self _drawPlaneRuns:[self _purpleBottomPlaneRuns]];
    [self _drawVerticalLines:[self _purpleTopVerticalLines]];
    [self _drawVerticalLines:[self _purpleBottomVerticalLines]];
    
    glLineWidth(2.0);
    // draw planes
    glColor4f ([_bluePlaneColor redComponent], [_bluePlaneColor greenComponent], [_bluePlaneColor blueComponent], [_bluePlaneColor alphaComponent]);
    [self _drawPlaneRuns:[self _bluePlaneRuns]];
    [self _drawVerticalLines:[self _blueVerticalLines]];
    glLineWidth(1.0);
    [self _drawPlaneRuns:[self _blueTopPlaneRuns]];
    [self _drawPlaneRuns:[self _blueBottomPlaneRuns]];
    [self _drawVerticalLines:[self _blueTopVerticalLines]];
    [self _drawVerticalLines:[self _blueBottomVerticalLines]];
	
	lineStart = N3VectorMake(0, (CGFloat)curDCM.pheight/2.0, 0);
    lineEnd = N3VectorMake(curDCM.pwidth, (CGFloat)curDCM.pheight/2.0, 0);
    
    lineStart = N3VectorApplyTransform(lineStart, pixToSubDrawRectTransform);
    lineEnd = N3VectorApplyTransform(lineEnd, pixToSubDrawRectTransform);
    
	glLineWidth(2.0);
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
        glPointSize(8);
        
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
        glLineWidth(2.0);
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
		
		for( int i = 0; i < noOfFrames; i++)
		{
			transverseSectionPosition = (startingDistance + ((float) i * exportTransverseSliceInterval)) / (float) _curvedPath.bezierPath.length;
			lineStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, 0, 0), pixToSubDrawRectTransform);
			lineEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, curDCM.pheight, 0), pixToSubDrawRectTransform);
			glLineWidth(2.0);
			glBegin(GL_LINE_STRIP);
			glVertex2f(lineStart.x, lineStart.y);
			glVertex2f(lineEnd.x, lineEnd.y);
			glEnd();
		}
	}
	else if( displayTransverseLines)
	{
		N3Vector lineAStart, lineAEnd, lineBStart, lineBEnd, lineCStart, lineCEnd;
		
		// draw the transverse section lines
		glColor4d(1.0, 1.0, 0.0, 1.0);
		transverseSectionPosition = _curvedPath.transverseSectionPosition;
		lineBStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, 0, 0), pixToSubDrawRectTransform);
		lineBEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*transverseSectionPosition, curDCM.pheight, 0), pixToSubDrawRectTransform);
		glLineWidth(2.0);
		glBegin(GL_LINE_STRIP);
		glVertex2f(lineBStart.x, lineBStart.y);
		glVertex2f(lineBEnd.x, lineBEnd.y);
		glEnd();
				
		leftTransverseSectionPosition = _curvedPath.leftTransverseSectionPosition;
		lineAStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*leftTransverseSectionPosition, 0, 0), pixToSubDrawRectTransform);
		lineAEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*leftTransverseSectionPosition, curDCM.pheight, 0), pixToSubDrawRectTransform);
		glLineWidth(1.0);
		glBegin(GL_LINE_STRIP);
		glVertex2f(lineAStart.x, lineAStart.y);
		glVertex2f(lineAEnd.x, lineAEnd.y);
		glEnd();
		
		rightTransverseSectionPosition = _curvedPath.rightTransverseSectionPosition;
		lineCStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*rightTransverseSectionPosition, 0, 0), pixToSubDrawRectTransform);
		lineCEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth*rightTransverseSectionPosition, curDCM.pheight, 0), pixToSubDrawRectTransform);
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
		
		float quarter = -(lineAStart.y - lineAEnd.y)/3.;
		
		glColor4f (0, 0, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(lineAStart.x+1 - [stringTexA frameSize].width, quarter+lineAStart.y+1) ratio: 1];
		glColor4f (1, 1, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(lineAStart.x - [stringTexA frameSize].width, quarter+lineAStart.y) ratio: 1];
		
		glColor4f (0, 0, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(lineBStart.x+1 - [stringTexB frameSize].width/2., quarter+lineBStart.y+1) ratio: 1];
		glColor4f (1, 1, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(lineBStart.x - [stringTexB frameSize].width/2., quarter+lineBStart.y) ratio: 1];
		
		glColor4f (0, 0, 0, 1);	[stringTexC drawAtPoint:NSMakePoint(lineCStart.x+1, quarter+lineCStart.y+1) ratio: 1];
		glColor4f (1, 1, 0, 1);	[stringTexC drawAtPoint:NSMakePoint(lineCStart.x, quarter+lineCStart.y) ratio: 1];
		
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
			glPointSize(8);
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
            glPointSize(8);
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
            glPointSize(8);
            
            glBegin(GL_POINTS);
            glVertex2f(cursorVector.x, cursorVector.y);
            glEnd();
        }
    }
    
	glLineWidth(1.0);
	
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
		NSPoint planePoint;
		N3Vector pixVector;
		N3Line line;
		NSInteger i;
		BOOL overNode;
		NSInteger hoverNodeIndex;
		CGFloat relativePosition;
        CGFloat distance;
        CGFloat minDistance;
		BOOL didChangeHover;
		NSString *planeName;
		N3Vector vector;
		
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
            if (displayTransverseLines) {
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
		
		
		if( curDCM.pwidth != 0 && exportTransverseSliceInterval == 0 && displayTransverseLines && ((ABS((pixVector.x/curDCM.pwidth) - _curvedPath.transverseSectionPosition)*curDCM.pwidth < 5.0) || (ABS((pixVector.x/curDCM.pwidth) - _curvedPath.leftTransverseSectionPosition)*curDCM.pwidth < 10.0) || (ABS((pixVector.x/curDCM.pwidth) - _curvedPath.rightTransverseSectionPosition)*curDCM.pwidth < 10.0)))
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

- (void) adjustROIsForCPRView
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
	
	[self setNeedsDisplay: YES];
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
	
    if( exportTransverseSliceInterval == 0 && displayTransverseLines && (ABS((pixVector.x/pixWidth) - _curvedPath.transverseSectionPosition)*pixWidth < 5.0))
	{
		[self _sendWillEditCurvedPath];
        _draggingTransverse = YES;
		[self mouseMoved: event];
    }
	else if( exportTransverseSliceInterval == 0 && displayTransverseLines && ((ABS((pixVector.x/pixWidth) - _curvedPath.leftTransverseSectionPosition)*pixWidth < 10.0) ||  (ABS((pixVector.x/pixWidth) - _curvedPath.rightTransverseSectionPosition)*pixWidth < 10.0)))
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
				
				long tool = [self getTool: event];
				
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
    
	
	
    if (_draggingTransverse) {
        relativePosition = pixVector.x/pixWidth;
        _curvedPath.transverseSectionPosition = MAX(MIN(relativePosition, 1.0), 0.0);
		[self _sendDidUpdateCurvedPath];

		[self _sendWillEditDisplayInfo];
        _displayInfo.mouseCursorPosition = pixVector.x/pixWidth;
		[self _sendDidEditDisplayInfo];

		[self setNeedsDisplay:YES];
		[self mouseMoved: event];
    } else if (_draggingTransverseSpacing) {
        _curvedPath.transverseSectionSpacing = ABS(pixVector.x/pixWidth-_curvedPath.transverseSectionPosition)*[_curvedPath.bezierPath length];
		[self _sendDidUpdateCurvedPath];

		[self _sendWillEditDisplayInfo];
        _displayInfo.mouseCursorPosition = pixVector.x/pixWidth;
		[self _sendDidEditDisplayInfo];
        [self setNeedsDisplay:YES];
		[self mouseMoved: event];
    } else {
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
		CGFloat transverseSectionSpacing = MIN(MAX(_curvedPath.transverseSectionSpacing + [theEvent deltaY] * .4, 0.0), 300); 
		
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
		
		[self _clearAllPlanes];
		[self setNeedsDisplay:YES];
	}
	[pixArray release];
}

- (void)generator:(CPRGenerator *)generator didAbandonRequest:(CPRGeneratorRequest *)request
{
}

- (void) runMainRunLoopUntilAllRequestsAreFinished
{
	[self _sendNewRequestIfNeeded];
	[_generator runMainRunLoopUntilAllRequestsAreFinished];
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
    CPRStraightenedGeneratorRequest *request;
    
    if ([_curvedPath.bezierPath elementCount] >= 3)
	{
        request = [[CPRStraightenedGeneratorRequest alloc] init];
        
        request.pixelsWide = [self bounds].size.width*1.2;
        request.pixelsHigh = [self bounds].size.height*1.2;
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
				
				[_generator runMainRunLoopUntilAllRequestsAreFinished];
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

- (void)_drawVerticalLines:(NSArray *)verticalLines
{
	NSNumber *indexNumber;
	N3Vector lineStart;
	N3Vector lineEnd;
    double pixToSubdrawRectOpenGLTransform[16];
	CGLContextObj cgl_ctx;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];    	
    
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
	_CPRViewPlaneRun *planeRun;
    double pixToSubdrawRectOpenGLTransform[16];
	CGLContextObj cgl_ctx;
    CGFloat pheight_2;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];    	
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
	_CPRViewPlaneRun *planeRun;
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
				planeRun = [[_CPRViewPlaneRun alloc] init];
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
	
	linePixVector = N3VectorZero;
	lineVolumeVector = N3VectorZero;
	runPixVector = N3VectorZero;
	runVolumeVector = N3VectorZero;
	
	[_displayInfo clearAllMouseVectors];
	[_mousePlanePointsInPix removeAllObjects];
	
	lineDistance = [self _distanceToPoint:point onVerticalLines:[self _orangeVerticalLines] pixVector:&linePixVector volumeVector:&lineVolumeVector];
	runDistance = [self _distanceToPoint:point onPlaneRuns:[self _orangePlaneRuns] pixVector:&runPixVector volumeVector:&runVolumeVector];
	if (MIN(lineDistance, runDistance) < 30) {
		if (lineDistance < runDistance) {
			[_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:linePixVector] forKey:@"orange"];
			[_displayInfo setMouseVector:lineVolumeVector forPlane:@"orange"];
		} else {
			[_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:runPixVector] forKey:@"orange"];
			[_displayInfo setMouseVector:runVolumeVector forPlane:@"orange"];
		}
	}
	
	lineDistance = [self _distanceToPoint:point onVerticalLines:[self _purpleVerticalLines] pixVector:&linePixVector volumeVector:&lineVolumeVector];
	runDistance = [self _distanceToPoint:point onPlaneRuns:[self _purplePlaneRuns] pixVector:&runPixVector volumeVector:&runVolumeVector];
	if (MIN(lineDistance, runDistance) < 30) {
		if (lineDistance < runDistance) {
			[_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:linePixVector] forKey:@"purple"];
			[_displayInfo setMouseVector:lineVolumeVector forPlane:@"purple"];
		} else {
			[_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:runPixVector] forKey:@"purple"];
			[_displayInfo setMouseVector:runVolumeVector forPlane:@"purple"];
		}
	}
	
	lineDistance = [self _distanceToPoint:point onVerticalLines:[self _blueVerticalLines] pixVector:&linePixVector volumeVector:&lineVolumeVector];
	runDistance = [self _distanceToPoint:point onPlaneRuns:[self _bluePlaneRuns] pixVector:&runPixVector volumeVector:&runVolumeVector];
	if (MIN(lineDistance, runDistance) < 30) {
		if (lineDistance < runDistance) {
			[_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:linePixVector] forKey:@"blue"];
			[_displayInfo setMouseVector:lineVolumeVector forPlane:@"blue"];
		} else {
			[_mousePlanePointsInPix setObject:[NSValue valueWithN3Vector:runPixVector] forKey:@"blue"];
			[_displayInfo setMouseVector:runVolumeVector forPlane:@"blue"];
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
	CGFloat height;
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
	_CPRViewPlaneRun *planeRun;
	N3MutableBezierPath *planeRunBezierPath;
	
	pointVector = N3VectorMakeFromNSPoint(point);
	pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];
	minDistance = CGFLOAT_MAX;
	closestVector = N3VectorZero;
    
	for (planeRun in planeRuns) {
		planeRunBezierPath = [[N3MutableBezierPath alloc] initWithCPRViewPlaneRun:planeRun heightPixelsPerMm:pixelsPerMm];
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

- (NSArray *)_orangePlaneRuns
{
	if (_orangePlaneRuns == nil && N3PlaneIsValid(_orangePlane) && _displayCrossLines) {
		[_orangeVericalLines release];
		_orangePlaneRuns = [self _runsForPlane:_orangePlane verticalLineIndexes:&_orangeVericalLines];
		[_orangeVericalLines retain];
		[_orangePlaneRuns retain];
	}
	return _orangePlaneRuns;
}

- (NSArray *)_purplePlaneRuns
{
	if (_purplePlaneRuns == nil && N3PlaneIsValid(_purplePlane) && _displayCrossLines) {
		[_purpleVericalLines release];
		_purplePlaneRuns = [self _runsForPlane:_purplePlane verticalLineIndexes:&_purpleVericalLines];
		[_purpleVericalLines retain];
		[_purplePlaneRuns retain];
	}
	return _purplePlaneRuns;
}

- (NSArray *)_bluePlaneRuns
{
	if (_bluePlaneRuns == nil && N3PlaneIsValid(_bluePlane) && _displayCrossLines) {
		[_blueVericalLines release];
		_bluePlaneRuns = [self _runsForPlane:_bluePlane verticalLineIndexes:&_blueVericalLines];
		[_blueVericalLines retain];
		[_bluePlaneRuns retain];
	}
	return _bluePlaneRuns;
}

- (NSArray *)_orangeTopPlaneRuns
{
	N3Plane plane;
	if (_orangeTopPlaneRuns == nil && N3PlaneIsValid(_orangePlane) && _orangeSlabThickness != 0.0 && _displayCrossLines) {
		[_orangeTopVericalLines release];
		plane.normal = N3VectorNormalize(_orangePlane.normal);
		plane.point = N3VectorAdd(_orangePlane.point, N3VectorScalarMultiply(plane.normal, _orangeSlabThickness/2.0));
		_orangeTopPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_orangeTopVericalLines];
		[_orangeTopVericalLines retain];
		[_orangeTopPlaneRuns retain];
	}
	return _orangeTopPlaneRuns;	
}

- (NSArray *)_purpleTopPlaneRuns
{
	N3Plane plane;
	if (_purpleTopPlaneRuns == nil && N3PlaneIsValid(_purplePlane) && _purpleSlabThickness != 0.0 && _displayCrossLines) {
		[_purpleTopVericalLines release];
		plane.normal = N3VectorNormalize(_purplePlane.normal);
		plane.point = N3VectorAdd(_purplePlane.point, N3VectorScalarMultiply(plane.normal, _purpleSlabThickness/2.0));
		_purpleTopPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_purpleTopVericalLines];
		[_purpleTopVericalLines retain];
		[_purpleTopPlaneRuns retain];
	}
	return _purpleTopPlaneRuns;	
}

- (NSArray *)_blueTopPlaneRuns
{
	N3Plane plane;
	if (_blueTopPlaneRuns == nil && N3PlaneIsValid(_bluePlane) && _blueSlabThickness != 0.0 && _displayCrossLines) {
		[_blueTopVericalLines release];
		plane.normal = N3VectorNormalize(_bluePlane.normal);
		plane.point = N3VectorAdd(_bluePlane.point, N3VectorScalarMultiply(plane.normal, _blueSlabThickness/2.0));
		_blueTopPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_blueTopVericalLines];
		[_blueTopVericalLines retain];
		[_blueTopPlaneRuns retain];
	}
	return _blueTopPlaneRuns;	
}

- (NSArray *)_orangeBottomPlaneRuns
{
	N3Plane plane;
	if (_orangeBottomPlaneRuns == nil && N3PlaneIsValid(_orangePlane) && _orangeSlabThickness != 0.0 && _displayCrossLines) {
		[_orangeBottomVericalLines release];
		plane.normal = N3VectorNormalize(_orangePlane.normal);
		plane.point = N3VectorAdd(_orangePlane.point, N3VectorScalarMultiply(plane.normal, -_orangeSlabThickness/2.0));
		_orangeBottomPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_orangeBottomVericalLines];
		[_orangeBottomVericalLines retain];
		[_orangeBottomPlaneRuns retain];
	}
	return _orangeBottomPlaneRuns;	
}

- (NSArray *)_purpleBottomPlaneRuns
{
	N3Plane plane;
	if (_purpleBottomPlaneRuns == nil && N3PlaneIsValid(_purplePlane) && _purpleSlabThickness != 0.0 && _displayCrossLines) {
		[_purpleBottomVericalLines release];
		plane.normal = N3VectorNormalize(_purplePlane.normal);
		plane.point = N3VectorAdd(_purplePlane.point, N3VectorScalarMultiply(plane.normal, -_purpleSlabThickness/2.0));
		_purpleBottomPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_purpleBottomVericalLines];
		[_purpleBottomVericalLines retain];
		[_purpleBottomPlaneRuns retain];
	}
	return _purpleBottomPlaneRuns;	
}

- (NSArray *)_blueBottomPlaneRuns
{
	N3Plane plane;
	if (_blueBottomPlaneRuns == nil && N3PlaneIsValid(_bluePlane) && _blueSlabThickness != 0.0 && _displayCrossLines) {
		[_blueBottomVericalLines release];
		plane.normal = N3VectorNormalize(_bluePlane.normal);
		plane.point = N3VectorAdd(_bluePlane.point, N3VectorScalarMultiply(plane.normal, -_blueSlabThickness/2.0));
		_blueBottomPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_blueBottomVericalLines];
		[_blueBottomVericalLines retain];
		[_blueBottomPlaneRuns retain];
	}
	return _blueBottomPlaneRuns;	
}

- (NSArray *)_orangeVerticalLines
{
	if (_orangeVericalLines == nil && N3PlaneIsValid(_orangePlane) && _displayCrossLines) {
		[_orangePlaneRuns release];
		_orangePlaneRuns = [self _runsForPlane:_orangePlane verticalLineIndexes:&_orangeVericalLines];
		[_orangeVericalLines retain];
		[_orangePlaneRuns retain];		
	}
	return _orangeVericalLines;
}

- (NSArray *)_purpleVerticalLines
{
	if (_purpleVericalLines == nil && N3PlaneIsValid(_purplePlane) && _displayCrossLines) {
		[_purplePlaneRuns release];
		_purplePlaneRuns = [self _runsForPlane:_purplePlane verticalLineIndexes:&_purpleVericalLines];
		[_purpleVericalLines retain];
		[_purplePlaneRuns retain];		
	}
	return _purpleVericalLines;
}

- (NSArray *)_blueVerticalLines
{
	if (_blueVericalLines == nil && N3PlaneIsValid(_bluePlane) && _displayCrossLines) {
		[_bluePlaneRuns release];
		_bluePlaneRuns = [self _runsForPlane:_bluePlane verticalLineIndexes:&_blueVericalLines];
		[_blueVericalLines retain];
		[_bluePlaneRuns retain];		
	}
	return _blueVericalLines;
}

- (NSArray *)_orangeTopVerticalLines
{
	N3Plane plane;
	if (_orangeTopVericalLines == nil && N3PlaneIsValid(_orangePlane) && _orangeSlabThickness != 0.0 && _displayCrossLines) {
		[_orangeTopPlaneRuns release];
		plane.normal = N3VectorNormalize(_orangePlane.normal);
		plane.point = N3VectorAdd(_orangePlane.point, N3VectorScalarMultiply(plane.normal, _orangeSlabThickness/2.0));
		_orangeTopPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_orangeTopVericalLines];
		[_orangeTopVericalLines retain];
		[_orangeTopPlaneRuns retain];		
	}
	return _orangeTopVericalLines;
}

- (NSArray *)_purpleTopVerticalLines
{
	N3Plane plane;
	if (_purpleTopVericalLines == nil && N3PlaneIsValid(_purplePlane) && _purpleSlabThickness != 0.0 && _displayCrossLines) {
		[_purpleTopPlaneRuns release];
		plane.normal = N3VectorNormalize(_purplePlane.normal);
		plane.point = N3VectorAdd(_purplePlane.point, N3VectorScalarMultiply(plane.normal, _purpleSlabThickness/2.0));
		_purpleTopPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_purpleTopVericalLines];
		[_purpleTopVericalLines retain];
		[_purpleTopPlaneRuns retain];		
	}
	return _purpleTopVericalLines;
}

- (NSArray *)_blueTopVerticalLines
{
	N3Plane plane;
	if (_blueTopVericalLines == nil && N3PlaneIsValid(_bluePlane) && _blueSlabThickness != 0.0 && _displayCrossLines) {
		[_blueTopPlaneRuns release];
		plane.normal = N3VectorNormalize(_bluePlane.normal);
		plane.point = N3VectorAdd(_bluePlane.point, N3VectorScalarMultiply(plane.normal, _blueSlabThickness/2.0));
		_blueTopPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_blueTopVericalLines];
		[_blueTopVericalLines retain];
		[_blueTopPlaneRuns retain];		
	}
	return _blueTopVericalLines;
}

- (NSArray *)_orangeBottomVerticalLines
{
	N3Plane plane;
	if (_orangeBottomVericalLines == nil && N3PlaneIsValid(_orangePlane) && _orangeSlabThickness != 0.0 && _displayCrossLines) {
		[_orangeBottomPlaneRuns release];
		plane.normal = N3VectorNormalize(_orangePlane.normal);
		plane.point = N3VectorAdd(_orangePlane.point, N3VectorScalarMultiply(plane.normal, _orangeSlabThickness/2.0));
		_orangeBottomPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_orangeBottomVericalLines];
		[_orangeBottomVericalLines retain];
		[_orangeBottomPlaneRuns retain];		
	}
	return _orangeBottomVericalLines;
}

- (NSArray *)_purpleBottomVerticalLines
{
	N3Plane plane;
	if (_purpleBottomVericalLines == nil && N3PlaneIsValid(_purplePlane) && _purpleSlabThickness != 0.0 && _displayCrossLines) {
		[_purpleBottomPlaneRuns release];
		plane.normal = N3VectorNormalize(_purplePlane.normal);
		plane.point = N3VectorAdd(_purplePlane.point, N3VectorScalarMultiply(plane.normal, _purpleSlabThickness/2.0));
		_purpleBottomPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_purpleBottomVericalLines];
		[_purpleBottomVericalLines retain];
		[_purpleBottomPlaneRuns retain];		
	}
	return _purpleBottomVericalLines;
}

- (NSArray *)_blueBottomVerticalLines
{
	N3Plane plane;
	if (_blueBottomVericalLines == nil && N3PlaneIsValid(_bluePlane) && _blueSlabThickness != 0.0 && _displayCrossLines) {
		[_blueBottomPlaneRuns release];
		plane.normal = N3VectorNormalize(_bluePlane.normal);
		plane.point = N3VectorAdd(_bluePlane.point, N3VectorScalarMultiply(plane.normal, _blueSlabThickness/2.0));
		_blueBottomPlaneRuns = [self _runsForPlane:plane verticalLineIndexes:&_blueBottomVericalLines];
		[_blueBottomVericalLines retain];
		[_blueBottomPlaneRuns retain];		
	}
	return _blueBottomVericalLines;
}

- (void)_clearAllPlanes
{
	[_orangeVericalLines release];
	_orangeVericalLines = nil;
	[_orangePlaneRuns release];
	_orangePlaneRuns = nil;
	[_purpleVericalLines release];
	_purpleVericalLines = nil;
	[_purplePlaneRuns release];
	_purplePlaneRuns = nil;
	[_blueVericalLines release];
	_blueVericalLines = nil;
	[_bluePlaneRuns release];
	_bluePlaneRuns = nil;
	
	[_orangeTopVericalLines release];
    _orangeTopVericalLines = nil;
    [_orangeTopPlaneRuns release];
    _orangeTopPlaneRuns = nil;
    [_purpleTopVericalLines release];
    _purpleTopVericalLines = nil;
    [_purpleTopPlaneRuns release];
    _purpleTopPlaneRuns = nil;
    [_blueTopVericalLines release];
    _blueTopVericalLines = nil;
    [_blueTopPlaneRuns release];
    _blueTopPlaneRuns = nil;
	
	[_orangeBottomVericalLines release];
    _orangeBottomVericalLines = nil;
    [_orangeBottomPlaneRuns release];
    _orangeBottomPlaneRuns = nil;
    [_purpleBottomVericalLines release];
    _purpleBottomVericalLines = nil;
    [_purpleBottomPlaneRuns release];
    _purpleBottomPlaneRuns = nil;
    [_blueBottomVericalLines release];
    _blueBottomVericalLines = nil;
    [_blueBottomPlaneRuns release];
    _blueBottomPlaneRuns = nil;
	
}




@end

@implementation N3BezierPath (CPRViewPlaneRunAdditions)

- (id)initWithCPRViewPlaneRun:(_CPRViewPlaneRun *)planeRun heightPixelsPerMm:(CGFloat)pixelsPerMm
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
				  
				  
				  
				  
				  
				  
				  
				  
				  
				  
				  













