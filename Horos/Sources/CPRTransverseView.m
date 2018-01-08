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
#import "CPRGenerator.h"
#import "CPRDisplayInfo.h"

extern int CLUTBARS;//, ANNOTATIONS;
extern BOOL frameZoomed;
extern int splitPosition[ 3];

@interface CPRTransverseView ()

@property (nonatomic, readwrite, retain) CPRObliqueSliceGeneratorRequest *lastRequest;
@property (nonatomic, readwrite, retain) CPRVolumeData *generatedVolumeData;

- (CGFloat)_relativeSegmentPosition;

- (void)_sendNewRequestIfNeeded;
- (void)_sendNewRequest;

@end


@implementation CPRTransverseView

@synthesize renderingScale = _renderingScale;
@synthesize delegate = _delegate;
@synthesize curvedPath = _curvedPath;
@synthesize displayInfo = _displayInfo;
@synthesize sectionType = _sectionType;
@synthesize sectionWidth = _sectionWidth;
@synthesize volumeData = _volumeData;
@synthesize lastRequest = _lastRequest;
@synthesize generatedVolumeData = _generatedVolumeData;
@synthesize reformationDisplayStyle = _reformationDisplayStyle;
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
    [_volumeData release];
    _volumeData = nil;
    [_generatedVolumeData release];
    _generatedVolumeData = nil;
    [_curvedPath release];
    _curvedPath = nil;
    [_displayInfo release];
    _displayInfo = nil;
    [_lastRequest release];
    _lastRequest = nil;
    
	[stanStringAttrib release];
	[stringTex release];
	
    [super dealloc];
}

- (void)setDisplayInfo:(CPRDisplayInfo *)displayInfo
{
    if (displayInfo != _displayInfo) {
        if (displayInfo.mouseTransverseSection != _displayInfo.mouseTransverseSection ||
            displayInfo.mouseTransverseSectionDistance != _displayInfo.mouseTransverseSectionDistance) {
            [self setNeedsDisplay:YES];
        }
        [_displayInfo release];
        _displayInfo = [displayInfo retain];
    }
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
		}
	}
	else [super mouseDown: event];
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

- (float) pixelsPerMm
{
    return (CGFloat)curDCM.pwidth/(_sectionWidth / _renderingScale);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
    NSPoint viewPoint;
    N3Vector pixVector;
    N3Line line;
	CPRTransverseViewSection newMouseTransverseSectionType;
    CGFloat newMouseTransverseSectionDistance;
    CGFloat pixelsPerMm;
    
	if( view == self)
	{
		viewPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		if (NSPointInRect(viewPoint, self.bounds) && curDCM.pwidth > 0)
		{
			pixVector = N3VectorApplyTransform(N3VectorMakeFromNSPoint(viewPoint), [self viewToPixTransform]);
			pixelsPerMm = self.pixelsPerMm;
		
			line = N3LineMake(N3VectorMake((CGFloat)curDCM.pwidth / 2.0, 0, 0), N3VectorMake(0, 1, 0));
			line = N3LineApplyTransform(line, N3AffineTransformInvert([self viewToPixTransform]));
			
			if (N3VectorDistanceToLine(N3VectorMakeFromNSPoint(viewPoint), line) < 20.0) {
				newMouseTransverseSectionType = _sectionType;
				newMouseTransverseSectionDistance = (pixVector.y - (CGFloat)curDCM.pheight/2.0) / pixelsPerMm;
			} else {
				newMouseTransverseSectionType = CPRTransverseViewNoneSectionType;
				newMouseTransverseSectionDistance = 0;
			}
			
			if (_displayInfo.mouseTransverseSection != newMouseTransverseSectionType ||
				_displayInfo.mouseTransverseSectionDistance != newMouseTransverseSectionDistance) {
				if ([_delegate respondsToSelector:@selector(CPRViewWillEditDisplayInfo:)]) {
					[_delegate CPRViewWillEditDisplayInfo:self];
				}
				_displayInfo.mouseTransverseSection = newMouseTransverseSectionType;
				_displayInfo.mouseTransverseSectionDistance = newMouseTransverseSectionDistance;
				if ([_delegate respondsToSelector:@selector(CPRViewDidEditDisplayInfo:)]) {
					[_delegate CPRViewDidEditDisplayInfo:self];
				}            
			}
		}
		
		[super mouseMoved:theEvent];
	} else
		[view mouseMoved:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if ([_delegate respondsToSelector:@selector(CPRViewWillEditDisplayInfo:)]) {
        [_delegate CPRViewWillEditDisplayInfo:self];
    }
    _displayInfo.mouseTransverseSection = CPRTransverseViewNoneSectionType;
    _displayInfo.mouseTransverseSectionDistance = 0;
    if ([_delegate respondsToSelector:@selector(CPRViewDidEditDisplayInfo:)]) {
        [_delegate CPRViewDidEditDisplayInfo:self];
    }            
    [self setNeedsDisplay:YES];
    
    [super mouseExited:theEvent];
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
        [_volumeData release];
        _volumeData = [volumeData retain];
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

- (void)setReformationDisplayStyle:(CPRTransverseViewReformationDisplayStyle)displayStyle
{
    if (displayStyle != _reformationDisplayStyle) {
        _reformationDisplayStyle = displayStyle;
        [self setNeedsDisplay:YES];
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
	long clutBars = CLUTBARS, annotations = annotationType;
	
	CLUTBARS = barHide;
	
	if( annotationType > annotGraphics)
		annotationType = annotGraphics;
	
    NSMutableArray *rArray = curRoiList;
    
    [rArray retain];
    
	for( int i = 0; i < rArray.count; i++ )
	{
		ROI *r = [rArray objectAtIndex:i];
		
		r.displayCMOrPixels = YES; // We don't want the value in pixels
		r.imageOrigin = NSMakePoint( curDCM.originX, curDCM.originY);
		
		if( r.type == t3Dpoint || r.type == t2DPoint)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:r userInfo: nil];
			[rArray removeObjectAtIndex: i];
            i--;
		}
	}
    
    [rArray autorelease];
	
	[super drawRect: aRect withContext: ctx];
	
	CLUTBARS = clutBars;
	annotationType = annotations;
}

- (void)subDrawRect:(NSRect)rect
{
    N3Vector cursorVector;
    N3AffineTransform pixToSubDrawRectTransform;
    CGFloat pixelsPerMm;
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    if( cgl_ctx == nil)
        return;
    
    pixelsPerMm = self.pixelsPerMm;
    pixToSubDrawRectTransform = [self pixToSubDrawRectTransform];

    // Dont display cross lines on transverse views, to keep coherence with streched mode
//	if( displayCrossLines && _reformationDisplayStyle == CPRTransverseViewStraightenedReformationDisplayStyle)
//	{
//		glColor4d(1.0, 1.0, 0.0, 1.0);
//		lineStart = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth/2.0, 0, 0), pixToSubDrawRectTransform);
//		lineEnd = N3VectorApplyTransform(N3VectorMake((CGFloat)curDCM.pwidth/2.0, curDCM.pheight, 0), pixToSubDrawRectTransform);
//		glLineWidth(1.0 * self.window.backingScaleFactor);
//		glBegin(GL_LINE_STRIP);
//		glVertex2f(lineStart.x, lineStart.y);
//		glVertex2f(lineEnd.x, lineEnd.y);
//		glEnd();
//		
//		if (_curvedPath.thickness > 2.0)
//		{
//			glLineWidth(1.0 * self.window.backingScaleFactor);
//			glBegin(GL_LINES);
//			lineStart = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth+_curvedPath.thickness*pixelsPerMm)/2.0, 0, 0), pixToSubDrawRectTransform);
//			lineEnd = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth+_curvedPath.thickness*pixelsPerMm)/2.0, curDCM.pheight, 0), pixToSubDrawRectTransform);
//			glVertex2f(lineStart.x, lineStart.y);
//			glVertex2f(lineEnd.x, lineEnd.y);
//			lineStart = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth-_curvedPath.thickness*pixelsPerMm)/2.0, 0, 0), pixToSubDrawRectTransform);
//			lineEnd = N3VectorApplyTransform(N3VectorMake(((CGFloat)curDCM.pwidth-_curvedPath.thickness*pixelsPerMm)/2.0, curDCM.pheight, 0), pixToSubDrawRectTransform);
//			glVertex2f(lineStart.x, lineStart.y);
//			glVertex2f(lineEnd.x, lineEnd.y);
//			glEnd();
//		}
//	}
    
    if( [[self windowController] displayMousePosition] == YES && _displayInfo.mouseTransverseSection == _sectionType) {
        cursorVector = N3VectorMake(((CGFloat)curDCM.pwidth)/2.0, ((CGFloat)curDCM.pheight/2.0)+(_displayInfo.mouseTransverseSectionDistance*pixelsPerMm), 0);
        cursorVector = N3VectorApplyTransform(cursorVector, pixToSubDrawRectTransform);
        
        glColor4d(1.0, 1.0, 0.0, 1.0);
        glEnable(GL_POINT_SMOOTH);
        glPointSize(8 * self.window.backingScaleFactor);
        glBegin(GL_POINTS);
        glVertex2f(cursorVector.x, cursorVector.y);
        glEnd();
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
	
	if( stanStringAttrib == nil)
	{
		stanStringAttrib = [[NSMutableDictionary dictionary] retain];
		[stanStringAttrib setObject:[NSFont fontWithName:@"Helvetica" size: 14.0] forKey:NSFontAttributeName];
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
	
	if( annotationType != annotNone)
	{
		glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
		glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
		glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
		
		[self drawOrientation: drawingFrameRect];
	}
	glDisable (GL_TEXTURE_RECTANGLE_EXT);
}

// in case we want to go back to using an async-generator for some reason, we will keep this function around like this
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
		if ([self.generatedVolumeData aquireInlineBuffer:&inlineBuffer])
		{
			newPix = [[DCMPix alloc] initWithData:(float *)CPRVolumeDataFloatBytes(&inlineBuffer) + (i*self.generatedVolumeData.pixelsWide*self.generatedVolumeData.pixelsHigh) :32 
												 :self.generatedVolumeData.pixelsWide :self.generatedVolumeData.pixelsHigh :self.generatedVolumeData.pixelSpacingX :self.generatedVolumeData.pixelSpacingY
												 : -self.generatedVolumeData.pixelSpacingX*self.generatedVolumeData.pixelsWide/2.
												 : -self.generatedVolumeData.pixelSpacingY*self.generatedVolumeData.pixelsHigh/2.
												 : 0
												 :NO];
		}
		else
		{
			assert(0);
			newPix = [[DCMPix alloc] init];
		}

		[self.generatedVolumeData releaseInlineBuffer:&inlineBuffer];

		float orientation[ 6];
        [self.generatedVolumeData getOrientation:orientation];
        [newPix setOrientation:orientation];
		
        [pixArray addObject:newPix];
        [newPix release];
    }
    
	if( pixArray.count)
	{
		for( int i = 0; i < [pixArray count]; i++)
			[[pixArray objectAtIndex: i] setArrayPix:pixArray :i];
		
		[self setPixels:pixArray files:NULL rois:NULL firstImage:0 level:'i' reset:YES];
		[self setScaleValueCentered: 1];
		
		[[self windowController] propagateWLWW: [[self windowController] mprView1]];
		
		NSArray *roiArray = [NSUnarchiver unarchiveObjectWithData: previousROIs];
		for( ROI *r in roiArray)
		{
			r.pix = curDCM;
			[r setOriginAndSpacing :curDCM.pixelSpacingX : curDCM.pixelSpacingY :NSMakePoint( curDCM.originX, curDCM.originY) :NO :NO];
			[r setCurView:self];
		}
		
		[[self curRoiList] addObjectsFromArray: roiArray];
	}
    [pixArray release];
    [self setNeedsDisplay:YES];
}

- (void)_sendNewRequest // since we don't generate these asynchronously anymore, should we really have all this _sendNewRequest business?
{
    CPRObliqueSliceGeneratorRequest *request;
    N3MutableBezierPath *subdividedAndFlattenedBezierPath;
    N3Vector vector;
    N3Vector normal;
    N3Vector tangent;
    N3Vector cross;
    CGFloat mmPerPixel;
    
    if ([_curvedPath.bezierPath elementCount] >= 3)
	{
        subdividedAndFlattenedBezierPath = [_curvedPath.bezierPath mutableCopy];
        [subdividedAndFlattenedBezierPath subdivide:N3BezierDefaultSubdivideSegmentLength];
        [subdividedAndFlattenedBezierPath flatten:N3BezierDefaultFlatness];
        vector = [subdividedAndFlattenedBezierPath vectorAtRelativePosition:[self _relativeSegmentPosition]];
        tangent = [subdividedAndFlattenedBezierPath tangentAtRelativePosition:[self _relativeSegmentPosition]];
        normal = [subdividedAndFlattenedBezierPath normalAtRelativePosition:[self _relativeSegmentPosition] initialNormal:_curvedPath.initialNormal];
        [subdividedAndFlattenedBezierPath release];
        
        cross = N3VectorNormalize(N3VectorCrossProduct(tangent, normal));

        // * 1.4 : to full the view area, if the matrix is rotated
        mmPerPixel = (_sectionWidth / _renderingScale)/([self convertSizeToBacking:[self bounds].size].width*1.4);
        
        request = [[CPRObliqueSliceGeneratorRequest alloc] initWithCenter:vector pixelsWide: [self convertSizeToBacking:[self bounds].size].width*1.4 pixelsHigh: [self convertSizeToBacking:[self bounds].size].height*1.4 xBasis:N3VectorScalarMultiply(cross, mmPerPixel) yBasis:N3VectorScalarMultiply(normal, mmPerPixel)];
        
        request.interpolationMode = [[self windowController] selectedInterpolationMode];
		
        if ([_lastRequest isEqual:request] == NO) {
			CPRVolumeData *curvedVolume;
			curvedVolume = [CPRGenerator synchronousRequestVolume:request volumeData:_volumeData];
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








