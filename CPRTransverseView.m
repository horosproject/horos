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


#import "N3Geometry.h"
#import "CPRTransverseView.h"
#import "CPRCurvedPath.h"
#import "N3BezierPath.h"
#import "CPRVolumeData.h"
#import "CPRGeneratorRequest.h"
#import "N3BezierCore.h"
#import "N3BezierCoreAdditions.h"
#import "DCMPix.h"
#import "CPRMPRDCMView.h"
#import "CPRController.h"
#import "ROI.h"
#import "Notifications.h"
#import "StringTexture.h"

extern int CLUTBARS, ANNOTATIONS;

@interface CPRTransverseView ()

@property (nonatomic, readwrite, retain) CPRStraightenedGeneratorRequest *lastRequest;
@property (nonatomic, readwrite, retain) CPRVolumeData *generatedVolumeData;

- (CGFloat)_relativeSegmentPosition;

- (N3BezierPath*)_bezierAndInitialNormalForRequest:(N3VectorPointer)initialNormal;

- (void)_setNeedsNewRequest;
- (void)_sendNewRequestIfNeeded;
- (void)_sendNewRequest;

@end


@implementation CPRTransverseView

@synthesize renderingScale = _renderingScale;
@synthesize delegate = _delegate;
@synthesize curvedPath = _curvedPath;
@synthesize sectionType = _sectionType;
@synthesize sectionWidth = _sectionWidth;
@synthesize volumeData = _volumeData;
@synthesize lastRequest = _lastRequest;
@synthesize generatedVolumeData = _generatedVolumeData;
@synthesize displayCrossLines;

- (void) setDisplayCrossLines: (BOOL) b
{
	displayCrossLines = b;
	[[self windowController] updateToolbarItems];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_renderingScale = 1;
		displayCrossLines = YES;
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
    [_generatedVolumeData release];
    _generatedVolumeData = nil;
    [_curvedPath release];
    _curvedPath = nil;
    [_lastRequest release];
    _lastRequest = nil;
    
	[stanStringAttrib release];
	[stringTex release];
	
    [super dealloc];
}

- (void)drawRect:(NSRect)r
{
    _processingRequest = YES;
	[self _sendNewRequestIfNeeded];
    _processingRequest = NO;
    [super drawRect:r];
}

- (void)setNeedsDisplay:(BOOL)flag
{
    if (_processingRequest == NO) {
        [super setNeedsDisplay:flag];
    }
}

- (void) applyNewScaleValue
{
	if( [self scaleValue] != previousScale)
	{
		self.renderingScale /= previousScale / [self scaleValue];
		
		if ([_delegate respondsToSelector:@selector(CPRTransverseViewDidChangeRenderingScale:)])
			[_delegate CPRTransverseViewDidChangeRenderingScale:self];
		
		[self _setNeedsNewRequest];
	}
}

-(void) magnifyWithEvent:(NSEvent *)anEvent
{
	previousScale = [self scaleValue];
	
	[super magnifyWithEvent: anEvent];
	[[self windowController] propagateOriginRotationAndZoomToTransverseViews: self];
	
	[self applyNewScaleValue];
}

-(void) rotateWithEvent:(NSEvent *)anEvent
{
	[super rotateWithEvent: anEvent];
	[[self windowController] propagateOriginRotationAndZoomToTransverseViews: self];
}

- (void)mouseDraggedZoom:(NSEvent *)event
{
	BOOL copyMouseClickZoomCentered = [[NSUserDefaults standardUserDefaults] boolForKey: @"MouseClickZoomCentered"];
	
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"MouseClickZoomCentered"];
	
	[super mouseDraggedZoom: event];
	
	[[NSUserDefaults standardUserDefaults] setBool: copyMouseClickZoomCentered forKey: @"MouseClickZoomCentered"];
	
	[[self windowController] propagateOriginRotationAndZoomToTransverseViews: self];
}

- (void) rightMouseDown:(NSEvent *)event
{
	previousScale = [self scaleValue];
	[super rightMouseDown: event];
}

- (void) mouseDown:(NSEvent *)event
{
	previousScale = [self scaleValue];
	[super mouseDown: event];
}

- (void) rightMouseUp:(NSEvent *)event
{
	[super rightMouseUp: event];
	[self applyNewScaleValue];
}

- (void)mouseUp:(NSEvent *)event
{
	[super mouseUp: event];
	[self applyNewScaleValue];
}

- (void)mouseDraggedTranslate:(NSEvent *)event
{
	[super mouseDraggedTranslate: event];
	[[self windowController] propagateOriginRotationAndZoomToTransverseViews: self];
}

- (void)mouseDraggedRotate:(NSEvent *)event
{
	[super mouseDraggedRotate: event];
	[[self windowController] propagateOriginRotationAndZoomToTransverseViews: self];
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
        if (curvedPath.thickness != _curvedPath.thickness) {
            [self setNeedsDisplay:YES];
        }
        
        [_curvedPath release];
        _curvedPath = [curvedPath copy];
        [self _setNeedsNewRequest];
    }
}


- (void) setRenderingScale:(CGFloat)renderingScale
{
    if (_renderingScale != renderingScale)
	{
//		_sectionWidth = _sectionWidth; / (renderingScale/_renderingScale);
		
		_renderingScale = renderingScale;
		
		[self _setNeedsNewRequest];
    }
}

- (void)setSectionWidth:(CGFloat)sectionWidth
{
    if (_sectionWidth != sectionWidth)
	{
        _sectionWidth = sectionWidth;
        [self _setNeedsNewRequest];
    }
}

- (void)setSectionType:(CPRTransverseViewSection)sectionType
{
    if (_sectionType != sectionType) {
        _sectionType = sectionType;
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

- (void)scrollWheel:(NSEvent *)theEvent
{
	if( [theEvent modifierFlags] & NSCommandKeyMask)
	{
		CGFloat transverseSectionSpacing = MIN(MAX(_curvedPath.transverseSectionSpacing + [theEvent deltaY] * .4, 0.0), 300); 
		
		if ([_delegate respondsToSelector:@selector(CPRViewWillEditCurvedPath:)])
			[_delegate CPRViewWillEditCurvedPath:self];
		
		_curvedPath.transverseSectionSpacing = transverseSectionSpacing;
		
		if ([_delegate respondsToSelector:@selector(CPRViewDidEditCurvedPath:)])
			[_delegate CPRViewDidEditCurvedPath:self];
		
		[self _setNeedsNewRequest];
	}
	else
	{
		CGFloat transverseSectionPosition;
		
		transverseSectionPosition = MIN(MAX(_curvedPath.transverseSectionPosition + [theEvent deltaY] * .002, 0.0), 1.0); 
		
		if ([_delegate respondsToSelector:@selector(CPRViewWillEditCurvedPath:)]) {
			[_delegate CPRViewWillEditCurvedPath:self];
		}
		_curvedPath.transverseSectionPosition = transverseSectionPosition;
		if ([_delegate respondsToSelector:@selector(CPRViewDidEditCurvedPath:)])  {
			[_delegate CPRViewDidEditCurvedPath:self];
		}
		[self _setNeedsNewRequest];
	}
}

- (void) drawRect:(NSRect)aRect withContext:(NSOpenGLContext *)ctx
{
	long clutBars = CLUTBARS, annotations = ANNOTATIONS;
	
	CLUTBARS = barHide;
	
	if( ANNOTATIONS > annotGraphics)
		ANNOTATIONS = annotGraphics;
	
	for( int i = 0; i < curRoiList.count; i++ )
	{
		ROI *r = [curRoiList objectAtIndex:i];
		if( r.type != tMesure)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:r userInfo: nil];
			[curRoiList removeObjectAtIndex:i];
			i--;
		}
		else
			r.displayCMOrPixels = YES; // We don't want the value in pixels
	}
	
	[super drawRect: aRect withContext: ctx];
	
	CLUTBARS = clutBars;
	ANNOTATIONS = annotations;
}

- (void)subDrawRect:(NSRect)rect
{
    N3Vector lineStart;
    N3Vector lineEnd;
    N3Vector cursorVector;
    N3AffineTransform pixToSubDrawRectTransform;
    CGFloat pixelsPerMm;
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    
	if( displayCrossLines)
	{
		pixToSubDrawRectTransform = [self pixToSubDrawRectTransform];
		pixelsPerMm = (CGFloat)curDCM.pwidth/(_sectionWidth / _renderingScale);
		
		glColor4d(0.0, 1.0, 0.0, 1.0);
		lineStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth/2.0, 0, 0), pixToSubDrawRectTransform);
		lineEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth/2.0, curDCM.pheight, 0), pixToSubDrawRectTransform);
		glLineWidth(1.0);
		glBegin(GL_LINE_STRIP);
		glVertex2f(lineStart.x, lineStart.y);
		glVertex2f(lineEnd.x, lineEnd.y);
		glEnd();
		
		if (_curvedPath.thickness > 2.0)
		{
			glLineWidth(1.0);
			glBegin(GL_LINES);
			lineStart = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth+_curvedPath.thickness*pixelsPerMm)/2.0, 0, 0), pixToSubDrawRectTransform);
			lineEnd = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth+_curvedPath.thickness*pixelsPerMm)/2.0, curDCM.pheight, 0), pixToSubDrawRectTransform);
			glVertex2f(lineStart.x, lineStart.y);
			glVertex2f(lineEnd.x, lineEnd.y);
			lineStart = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth-_curvedPath.thickness*pixelsPerMm)/2.0, 0, 0), pixToSubDrawRectTransform);
			lineEnd = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth-_curvedPath.thickness*pixelsPerMm)/2.0, curDCM.pheight, 0), pixToSubDrawRectTransform);
			glVertex2f(lineStart.x, lineStart.y);
			glVertex2f(lineEnd.x, lineEnd.y);
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
		
		glLineWidth(8.0);
		glBegin(GL_LINE_LOOP);
        glVertex2f(  -widthhalf, -heighthalf);
        glVertex2f(  -widthhalf, heighthalf);
        glVertex2f(  widthhalf, heighthalf);
        glVertex2f(  widthhalf, -heighthalf);
		glEnd();
	}
	
	if( stanStringAttrib == nil)
	{
		stanStringAttrib = [[NSMutableDictionary dictionary] retain];
		[stanStringAttrib setObject:[NSFont fontWithName:@"Helvetica" size: 12.0] forKey:NSFontAttributeName];
		[stanStringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	}
	
	if( stringTex == nil)
	{
		NSString *textValue = nil;
		switch( _sectionType)
		{
			case CPRTransverseViewCenterSectionType: textValue = @"B"; break;
			case CPRTransverseViewLeftSectionType: textValue = @"A"; break;
			case CPRTransverseViewRightSectionType: textValue = @"C"; break;
		}
		
		stringTex = [[StringTexture alloc] initWithString: textValue
										   withAttributes: stanStringAttrib
											withTextColor: [NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha:1.0f]
											 withBoxColor: [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]
										  withBorderColor: [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
		[stringTex setAntiAliasing: YES];
	}
	
	glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
	glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale

	glEnable (GL_TEXTURE_RECTANGLE_EXT);
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	NSPoint anchor = NSMakePoint( drawingFrameRect.size.width / -2.0f, drawingFrameRect.size.height /-2.0f);
	
	glColor4f (0, 0, 0, 1);	[stringTex drawAtPoint:NSMakePoint( anchor.x+1, anchor.y+1) ratio: 1];
	glColor4f (1, 1, 0, 1);	[stringTex drawAtPoint:NSMakePoint( anchor.x, anchor.y) ratio: 1];
	
	glDisable (GL_TEXTURE_RECTANGLE_EXT);
}


- (void)generator:(CPRGenerator *)generator didGenerateVolume:(CPRVolumeData *)volume request:(CPRGeneratorRequest *)request
{
	if( [self windowController] == nil)
		return;
	
	NSData *previousROIs = [NSArchiver archivedDataWithRootObject: [self curRoiList]];
	CPRVolumeDataInlineBuffer inlineBuffer;
	DCMPix *newPix;

    [[self.generatedVolumeData retain] autorelease]; // make sure this is around long enough so that it doesn't disapear under the old DCMPix
    self.generatedVolumeData = volume;
    
    NSMutableArray *pixArray = [[NSMutableArray alloc] init];
    
    for( int i = 0; i < self.generatedVolumeData.pixelsDeep; i++)
	{
		if ([self.generatedVolumeData aquireInlineBuffer:&inlineBuffer]) {
			newPix = [[DCMPix alloc] initWithData:(float *)CPRVolumeDataFloatBytes(&inlineBuffer) + (i*self.generatedVolumeData.pixelsWide*self.generatedVolumeData.pixelsHigh) :32 
												 :self.generatedVolumeData.pixelsWide :self.generatedVolumeData.pixelsHigh :self.generatedVolumeData.pixelSpacingX :self.generatedVolumeData.pixelSpacingY
												 :-self.generatedVolumeData.pixelSpacingX*self.generatedVolumeData.pixelsWide/2.
												 :-self.generatedVolumeData.pixelSpacingY*self.generatedVolumeData.pixelsHigh/2.
												 :0
												 :NO];
		} else {
			assert(0);
			newPix = [[DCMPix alloc] init];
		}

		[self.generatedVolumeData releaseInlineBuffer:&inlineBuffer];

		float c[ 6] = {1, 0, 0, 0, 1, 0};
		[newPix setOrientation: c];
		
        [pixArray addObject:newPix];
        [newPix release];
    }
    
	if( pixArray.count)
	{
		for( int i = 0; i < [pixArray count]; i++)
		{
			[[pixArray objectAtIndex: i] setArrayPix:pixArray :i];
		}
		
		[self setPixels:pixArray files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
		[self setScaleValueCentered: 1];
		
		[[self windowController] propagateWLWW: [[self windowController] mprView1]];
		
		NSArray *roiArray = [NSUnarchiver unarchiveObjectWithData: previousROIs];
		for( ROI *r in roiArray)
		{
			r.pix = curDCM;
			[r setOriginAndSpacing :curDCM.pixelSpacingX : curDCM.pixelSpacingY :NSMakePoint( curDCM.originX, curDCM.originY) :NO :NO];
			[r setRoiFont: labelFontListGL :labelFontListGLSize :self];
		}
		
		[[self curRoiList] addObjectsFromArray: roiArray];
	}
    [pixArray release];
    [self setNeedsDisplay:YES];
}

- (void)runMainRunLoopUntilAllRequestsAreFinished
{
	[self _sendNewRequestIfNeeded];
	[_generator runMainRunLoopUntilAllRequestsAreFinished];
}

- (void)_sendNewRequest // since we don't generate these asynchronously anymore, should we really have all this _sendNewRequest business?
{
    CPRStraightenedGeneratorRequest *request;
    N3Vector initialNormal;
    
    if ([_curvedPath.bezierPath elementCount] >= 3)
	{
        request = [[CPRStraightenedGeneratorRequest alloc] init];
		request.pixelsWide = [self bounds].size.width*1.4; // * 1.4 : to full the view area, if the matrix is rotated
		request.pixelsHigh = [self bounds].size.height*1.4;
		request.slabWidth = 0;
        request.slabSampleDistance = 0;
        request.bezierPath = [self _bezierAndInitialNormalForRequest:&initialNormal];
        request.initialNormal = initialNormal;
//        request.vertical = NO;
        
        if ([_lastRequest isEqual:request] == NO) {
			CPRVolumeData *curvedVolume;
			curvedVolume = [CPRGenerator synchronousRequestVolume:request volumeData:_generator.volumeData];
			
			[_generator runMainRunLoopUntilAllRequestsAreFinished];
			[self generator:nil didGenerateVolume:curvedVolume request:request];
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

- (CGFloat)_relativeSegmentPosition
{
    switch (_sectionType) {
        case CPRTransverseViewLeftSectionType:
            return _curvedPath.leftTransverseSectionPosition;
            break;
        case CPRTransverseViewCenterSectionType:
            return _curvedPath.transverseSectionPosition;
            break;
        case CPRTransverseViewRightSectionType:
            return _curvedPath.rightTransverseSectionPosition;
            break;
        default:
            assert(0);
            break;
    }
    return 0;
}

- (N3BezierPath*)_bezierAndInitialNormalForRequest:(N3VectorPointer)initialNormal
{
    N3MutableBezierPath *bezierPath;
    N3MutableBezierPath *subdividedAndFlattenedBezierPath;
    N3Vector vector;
    N3Vector normal;
    N3Vector tangent;
    N3Vector cross;
    
    subdividedAndFlattenedBezierPath = [_curvedPath.bezierPath mutableCopy];
    [subdividedAndFlattenedBezierPath subdivide:N3BezierDefaultSubdivideSegmentLength];
    [subdividedAndFlattenedBezierPath flatten:N3BezierDefaultFlatness];
    vector = [subdividedAndFlattenedBezierPath vectorAtRelativePosition:[self _relativeSegmentPosition]];
    tangent = [subdividedAndFlattenedBezierPath tangentAtRelativePosition:[self _relativeSegmentPosition]];
    normal = [subdividedAndFlattenedBezierPath normalAtRelativePosition:[self _relativeSegmentPosition] initialNormal:_curvedPath.initialNormal];
    [subdividedAndFlattenedBezierPath release];
    
    cross = N3VectorNormalize(N3VectorCrossProduct(normal, tangent));
    
    bezierPath = [N3MutableBezierPath bezierPath];
    [bezierPath moveToVector:N3VectorAdd(vector, N3VectorScalarMultiply(cross, _sectionWidth / _renderingScale / 2))]; 
    [bezierPath lineToVector:N3VectorAdd(vector, N3VectorScalarMultiply(cross, -_sectionWidth / _renderingScale / 2))]; 
    
    if (initialNormal) {
        *initialNormal = normal;
    }
    return bezierPath;
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



@end








