//
//  CPRStretchedView.m
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
#import <objc/runtime.h>

#define _extraWidthFactor 1.2

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
- (void)_buildTransverseVerticalLinesAndPlaneRuns;
- (void)_clearTransversePlanes;

// calls for dealing with intersections with planes



@end

@implementation CPRStretchedView


@synthesize delegate = _delegate;
@synthesize volumeData = _volumeData;
@synthesize curvedPath = _curvedPath;
@synthesize displayInfo = _displayInfo;
@synthesize curvedVolumeData = _curvedVolumeData;
@synthesize clippingRangeMode = _clippingRangeMode;
@synthesize lastRequest = _lastRequest;
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
        _displayCrossLines = YES;
        _displayTransverseLines = YES;
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
    
    [super dealloc];
}

- (id)valueForKey:(NSString *)key
{
    NSString *planeFullName; // full plane name may include Top or Bottom before the plane name
//    NSArray *planeRuns;
//    NSArray *vertialLines;
    
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
		float length = curDCM.pixelSpacingX * curDCM.pwidth;
        
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

- (void)subDrawRect:(NSRect)rect
{
    double pixToSubdrawRectOpenGLTransform[16];
 	CGFloat pixelsPerMm;
    CGFloat pheight_2;
	NSInteger i;
    N3Vector endpoint;
    N3BezierPath *centerline;
    NSString *planeName;
	NSColor *planeColor;

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
 
    if (_displayCrossLines) {
        for (planeName in _planes) {
            planeColor = [self valueForKey:[planeName stringByAppendingString:@"PlaneColor"]];
            
            glLineWidth(2.0);
            // draw planes
            glColor4f ([planeColor redComponent], [planeColor greenComponent], [planeColor blueComponent], [planeColor alphaComponent]);
            [self _drawPlaneRuns:[self valueForKey:[planeName stringByAppendingString:@"PlaneRuns"]]];
            [self _drawVerticalLines:[self valueForKey:[planeName stringByAppendingString:@"VerticalLines"]]];
            
            glLineWidth(1.0);
            [self _drawPlaneRuns:[self valueForKey:[planeName stringByAppendingString:@"TopPlaneRuns"]]];
            [self _drawPlaneRuns:[self valueForKey:[planeName stringByAppendingString:@"BottomPlaneRuns"]]];
            [self _drawVerticalLines:[self valueForKey:[planeName stringByAppendingString:@"TopVerticalLines"]]];
            [self _drawVerticalLines:[self valueForKey:[planeName stringByAppendingString:@"BottomVerticalLines"]]];
        }
    }    
    
    // antoine wrote a horrific version of this, I need to do better
    // bottom line here is that there are planeruns/vertical lines that are not actually planes
    // and might need to managed seperatly, that would give easy freedom when dealing with line
    // thickness and alpha. 
    
    
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
        
		for( int i = 0; i < noOfFrames; i++)
		{
            N3Plane sliceTransversePlane = N3PlaneMake(vectors[i], tangents[i]);
            NSArray *slicePlaneRun;
            NSArray *sliceVerticalSlices;
            
            slicePlaneRun = [self _runsForPlane:sliceTransversePlane verticalLineIndexes:&sliceVerticalSlices];
            
			glLineWidth(2.0);
            [self _drawPlaneRuns:slicePlaneRun];
            [self _drawVerticalLines:sliceVerticalSlices];
		}
        
        free(vectors);
        free(tangents);
	}
	else if(_displayTransverseLines)
	{
        NSString *name;
        
        [self _buildTransverseVerticalLinesAndPlaneRuns];
        
        glColor4d(1.0, 1.0, 0.0, 1.0);
        
        for (name in _transverseVerticalLines) {
            NSArray *transverseVerticalLine = [_transverseVerticalLines objectForKey:name];
            
            if ([name isEqualToString:@"center"]) {
                glLineWidth(2.0);
            } else {
                glLineWidth(1.0);
            }
            
            [self _drawVerticalLines:transverseVerticalLine];
        }
        for (name in _transversePlaneRuns) {
            NSArray *transversePlaneRun = [_transversePlaneRuns objectForKey:name];
            
            if ([name isEqualToString:@"center"]) {
                glLineWidth(2.0);
            } else {
                glLineWidth(1.0);
            }
            
            [self _drawPlaneRuns:transversePlaneRun];
        }
        		
		// --- Text
//		if( stanStringAttrib == nil)
//		{
//			stanStringAttrib = [[NSMutableDictionary dictionary] retain];
//			[stanStringAttrib setObject:[NSFont fontWithName:@"Helvetica" size: 14.0] forKey:NSFontAttributeName];
//			[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
//		}
//		
//		if( stringTexA == nil)
//		{
//			stringTexA = [[StringTexture alloc] initWithString: @"A"
//                                                withAttributes:stanStringAttrib
//                                                 withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
//                                                  withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
//                                               withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
//			[stringTexA setAntiAliasing: YES];
//		}
//		if( stringTexB == nil)
//		{
//			stringTexB = [[StringTexture alloc] initWithString: @"B"
//                                                withAttributes:stanStringAttrib
//                                                 withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
//                                                  withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
//                                               withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
//			[stringTexB setAntiAliasing: YES];
//		}
//		if( stringTexC == nil)
//		{
//			stringTexC = [[StringTexture alloc] initWithString: @"C"
//                                                withAttributes:stanStringAttrib
//                                                 withTextColor:[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
//                                                  withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
//                                               withBorderColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
//			[stringTexC setAntiAliasing: YES];
//		}
//		
//		glEnable (GL_TEXTURE_RECTANGLE_EXT);
//		glEnable(GL_BLEND);
//		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
//		
//		float quarter = -(lineAStart.y - lineAEnd.y)/3.;
//		
//		glColor4f (0, 0, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(lineAStart.x+1 - [stringTexA frameSize].width, quarter+lineAStart.y+1) ratio: 1];
//		glColor4f (1, 1, 0, 1);	[stringTexA drawAtPoint:NSMakePoint(lineAStart.x - [stringTexA frameSize].width, quarter+lineAStart.y) ratio: 1];
//		
//		glColor4f (0, 0, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(lineBStart.x+1 - [stringTexB frameSize].width/2., quarter+lineBStart.y+1) ratio: 1];
//		glColor4f (1, 1, 0, 1);	[stringTexB drawAtPoint:NSMakePoint(lineBStart.x - [stringTexB frameSize].width/2., quarter+lineBStart.y) ratio: 1];
//		
//		glColor4f (0, 0, 0, 1);	[stringTexC drawAtPoint:NSMakePoint(lineCStart.x+1, quarter+lineCStart.y+1) ratio: 1];
//		glColor4f (1, 1, 0, 1);	[stringTexC drawAtPoint:NSMakePoint(lineCStart.x, quarter+lineCStart.y) ratio: 1];
//		
//		glDisable (GL_TEXTURE_RECTANGLE_EXT);
	}
    
    
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
		
        [self _clearAllPlanes];
        [self _clearTransversePlanes];
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
	_CPRStretchedViewPlaneRun *planeRun;
    double pixToSubdrawRectOpenGLTransform[16];
	CGLContextObj cgl_ctx;
    CGFloat pheight_2;
    
    cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];    	
//	pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];
    pixelsPerMm = (CGFloat)curDCM.pwidth/_centerlineProjectedLength;

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
	N3Vector bottom;
	N3Vector top;
	_CPRStretchedViewPlaneRun *planeRun;
	NSRange range;
	NSInteger aboveOrBelow;
	NSInteger prevAboveOrBelow;
    NSInteger pixelsWide;
    N3Vector curveDirection;
    N3Vector baseNormal;
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
	
	mmPerPixel = [_curvedPath.bezierPath length]/(CGFloat)curDCM.pwidth;
	halfHeight = ((CGFloat)curDCM.pheight*mmPerPixel)/2.0;
    
    // figure out how many horizonatal pixels we will have
    pixelsWide = curDCM.pwidth;
    curveDirection = N3VectorSubtract([_curvedPath.bezierPath vectorAtEnd], [_curvedPath.bezierPath vectorAtStart]);
    baseNormal = N3VectorNormalize(N3VectorCrossProduct(_curvedPath.baseDirection, curveDirection));
    projectionNormal = N3VectorApplyTransform(baseNormal, N3AffineTransformMakeRotationAroundVector(_curvedPath.angle, curveDirection));
    projectionNormal = N3VectorNormalize(projectionNormal);
    
    midHeightPoint = N3VectorLerp([_curvedPath.bezierPath topBoundingPlaneForNormal:projectionNormal].point, 
                                  [_curvedPath.bezierPath bottomBoundingPlaneForNormal:projectionNormal].point, 0.5);
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
            // distance from bottom to 
            
            distance = N3VectorDotProduct(N3VectorSubtract(N3LineIntersectionWithPlane(N3LineMakeFromPoints(bottom, top), plane), midHeightPoint), projectionNormal);
//            distance = N3VectorDotProduct(N3VectorSubtract(vectors[i], bottom), projectionNormal);
//			distance = N3VectorDotProduct(N3VectorSubtract(N3LineIntersectionWithPlane(N3LineMakeFromPoints(bottom, top), plane), vectors[i]), projectionNormal);
//			distance = N3VectorDotProduct(N3VectorSubtract(N3LineIntersectionWithPlane(N3LineMakeFromPoints(bottom, top), plane), vectors[i]), projectionNormal);
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
{}

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
//	pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];
    pixelsPerMm = (CGFloat)curDCM.pwidth/_centerlineProjectedLength;

    
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
	_CPRStretchedViewPlaneRun *planeRun;
	N3MutableBezierPath *planeRunBezierPath;
	
	pointVector = N3VectorMakeFromNSPoint(point);
//	pixelsPerMm = (CGFloat)curDCM.pwidth/[_curvedPath.bezierPath length];
    pixelsPerMm = (CGFloat)curDCM.pwidth/_centerlineProjectedLength;

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

- (void)_buildTransverseVerticalLinesAndPlaneRuns
{
    N3Plane transversePlane;
    NSArray *planeRuns;
    NSArray *verticalLines;
    
    transversePlane.point = [_curvedPath.bezierPath vectorAtRelativePosition:[_curvedPath transverseSectionPosition]];
    transversePlane.normal = [_curvedPath.bezierPath tangentAtRelativePosition:[_curvedPath transverseSectionPosition]];
    planeRuns = [self _runsForPlane:transversePlane verticalLineIndexes:&verticalLines];
    [_transverseVerticalLines setObject:verticalLines forKey:@"center"];
    [_transversePlaneRuns setObject:planeRuns forKey:@"center"];
    
    transversePlane.point = [_curvedPath.bezierPath vectorAtRelativePosition:[_curvedPath leftTransverseSectionPosition]];
    transversePlane.normal = [_curvedPath.bezierPath tangentAtRelativePosition:[_curvedPath leftTransverseSectionPosition]];
    planeRuns = [self _runsForPlane:transversePlane verticalLineIndexes:&verticalLines];
    [_transverseVerticalLines setObject:verticalLines forKey:@"left"];
    [_transversePlaneRuns setObject:planeRuns forKey:@"left"];
    
    transversePlane.point = [_curvedPath.bezierPath vectorAtRelativePosition:[_curvedPath rightTransverseSectionPosition]];
    transversePlane.normal = [_curvedPath.bezierPath tangentAtRelativePosition:[_curvedPath rightTransverseSectionPosition]];
    planeRuns = [self _runsForPlane:transversePlane verticalLineIndexes:&verticalLines];
    [_transverseVerticalLines setObject:verticalLines forKey:@"right"];
    [_transversePlaneRuns setObject:planeRuns forKey:@"right"];
}

- (void)_clearTransversePlanes
{
    [_transverseVerticalLines removeAllObjects];
    [_transversePlaneRuns removeAllObjects];
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










