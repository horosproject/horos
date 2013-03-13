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


#import "OrthogonalMPRController.h"
#import "LLScoutView.h"
#import "DCMPix.h"
#import "OrthogonalMPRController.h"

#import "LLScoutViewer.h"

@implementation LLScoutView

-(void)setTopLimit:(int)newLimit
{
	topLimit = newLimit;
}

-(void)setBottomLimit:(int)newLimit;
{
	bottomLimit = newLimit;
}

-(void)setIsFlipped:(BOOL)boo;
{
	isFlipped = boo;
}

- (void)subDrawRect:(NSRect)aRect
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);

	float positions[3];
	[self getOpenGLLimitPosition:positions];
	
	NSRect viewFrame = [self frame];
	float halfViewFrameWidth = viewFrame.size.width/2.0;
	
	glColor3f(0.0f, 1.0f, 0.0f);
	glLineWidth(1.0 * self.window.backingScaleFactor);

	glTranslatef( -origin.x, 0.0f, 0.0f);

	glBegin(GL_LINES);
		glVertex2f(-halfViewFrameWidth, positions[0]);
		glVertex2f(halfViewFrameWidth, positions[0]);
		glVertex2f(-halfViewFrameWidth, positions[1]);
		glVertex2f(halfViewFrameWidth, positions[1]);
	glEnd();
	
	[self drawArrowButtonAtPosition: positions[0]];
	[self drawArrowButtonAtPosition: positions[1]];
	[self drawArrowButtonAtPosition: positions[2]];

	glTranslatef(origin.x, 0.0f, 0.0f);
	
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glDisable(GL_BLEND);
}

- (void)getOpenGLLimitPosition:(float*)positions;
{
	float topLimitPosition, bottomLimitPosition;
	
	if (isFlipped)
	{
		topLimitPosition = (float)[[controller originalDCMPixList] count] - (float)topLimit - 1.0;
		bottomLimitPosition = (float)[[controller originalDCMPixList] count] - (float)bottomLimit - 1.0;
	}
	else
	{
		topLimitPosition = (float)topLimit;
		bottomLimitPosition = (float)bottomLimit;
	}
		
	topLimitPosition = (topLimitPosition - [[self curDCM] pheight]/2.0) * scaleValue;
	bottomLimitPosition = (bottomLimitPosition - [[self curDCM] pheight]/2.0) * scaleValue;

	positions[0] = topLimitPosition;
	positions[1] = bottomLimitPosition;
	positions[2] = (float)[[self curDCM] pheight]/2.0 * scaleValue;
}

const float ArrowButtonBottomMargin = 7.0, ArrowButtonRightMargin = 6.0, ArrowButtonTriangleHeight = 10.0, ArrowButtonTriangleHalfBasis = 5.0;

- (void)drawArrowButtonAtPosition:(float)position;
{
	NSRect viewFrame = [self frame];

	float ArrowButtonRightSide = viewFrame.size.width/2.0 - ArrowButtonRightMargin;
	float ArrowButtonLeftSide = ArrowButtonRightSide - ArrowButtonTriangleHeight;
	
	float centerX, centerY;
	centerX = (2.0*ArrowButtonLeftSide+ArrowButtonRightSide)/3.0;
	centerY = position-(ArrowButtonBottomMargin+ArrowButtonTriangleHalfBasis)*[curDCM pixelSpacingX]/[curDCM pixelSpacingY];
	
	float radius = ArrowButtonRightSide - centerX + 2.0;
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	// circle border
	glColor3f(0.6f, 0.6f, 0.733f);
	glPointSize((radius+1.0)*2.0);
	glBegin(GL_POINTS);
		glVertex2f(centerX, centerY);
	glEnd();
	// circle
	glColor3f(0.4f, 0.4f, 0.6f);
	glPointSize(radius*2.0);
	glBegin(GL_POINTS);
		glVertex2f(centerX, centerY);
	glEnd();
		
	// triangle
	glLineWidth(1.0 * self.window.backingScaleFactor);
	glColor3f(1.0f, 1.0f, 1.0f);
	glBegin(GL_TRIANGLES);
		glVertex2f(ArrowButtonLeftSide,position-ArrowButtonBottomMargin*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
		glVertex2f(ArrowButtonLeftSide,position-(ArrowButtonBottomMargin+2*ArrowButtonTriangleHalfBasis)*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
		glVertex2f(ArrowButtonRightSide,position-(ArrowButtonBottomMargin+ArrowButtonTriangleHalfBasis)*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
	glEnd();
}

- (NSRect)rectForArrowButtonAtIndex:(int)index;
{
	float positions[3];
	[self getOpenGLLimitPosition:positions];
	NSRect viewFrame = [self frame];
	float ArrowButtonRightSide = viewFrame.size.width/2.0 - ArrowButtonRightMargin;
	float ArrowButtonLeftSide = ArrowButtonRightSide - ArrowButtonTriangleHeight;
	float centerX = (2.0*ArrowButtonLeftSide+ArrowButtonRightSide)/3.0;
	float centerY = positions[index]-(ArrowButtonBottomMargin+ArrowButtonTriangleHalfBasis)*[curDCM pixelSpacingX]/[curDCM pixelSpacingY];
	float radius = ArrowButtonRightSide - centerX + 2.0;
	float diameter = 2.0 * radius;
	
	NSRect rectForArrowButton = NSMakeRect(centerX-radius-origin.x, centerY-radius*[curDCM pixelSpacingX]/[curDCM pixelSpacingY], diameter, diameter*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
	return rectForArrowButton;
}

- (NSRect)rectForLimitAtIndex:(int)index;
{
	float positions[3];
	[self getOpenGLLimitPosition:positions];
	NSRect viewFrame = [self frame];
	float halfHeight = 5;
	
	NSRect rectForArrowButton = NSMakeRect(-viewFrame.size.width/2.0-origin.x, positions[index]-halfHeight*[curDCM pixelSpacingX]/[curDCM pixelSpacingY], viewFrame.size.width, halfHeight*2.0*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
	return rectForArrowButton;
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint eventLocation = [event locationInWindow];
	NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
	
	tempPt = [self ConvertFromNSView2GL:tempPt];
	
	tempPt.x = (tempPt.x - [[self curDCM] pwidth]/2.0) * scaleValue;
	tempPt.y = (tempPt.y - [[self curDCM] pheight]/2.0) * scaleValue;
	
	NSRect rect1 = [self rectForArrowButtonAtIndex:0];
	NSRect rect2 = [self rectForArrowButtonAtIndex:1];
	NSRect rect3 = [self rectForArrowButtonAtIndex:2];
	
	NSRect rectTopLimit = [self rectForLimitAtIndex:0];
	NSRect rectBottomLimit = [self rectForLimitAtIndex:1];
	
	start = tempPt;
	
	if(NSPointInRect(tempPt, rect1))
	{
		[(LLScoutViewer*)[controller viewer] displayMPR:0];
	}
	else if(NSPointInRect(tempPt, rect2))
	{
		[(LLScoutViewer*)[controller viewer] displayMPR:1];
	}
	else if(NSPointInRect(tempPt, rect3))
	{
		[(LLScoutViewer*)[controller viewer] displayMPR:2];
	}
	else if(NSPointInRect(tempPt, rectTopLimit))
	{
		draggingTopLimit = YES;
	}
	else if(NSPointInRect(tempPt, rectBottomLimit))
	{
		draggingBottomLimit = YES;
	}
	else
	{
		[super mouseDown:event];
	}
}

-(void) mouseMoved: (NSEvent*) event
{
	if( ![[self window] isVisible])
		return;
	
//NSLog(@"mouseMoved");
	NSPoint eventLocation = [event locationInWindow];
	NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
	
	tempPt = [self ConvertFromNSView2GL:tempPt];
	
	tempPt.x = (tempPt.x - [[self curDCM] pwidth]/2.0) * scaleValue;
	tempPt.y = (tempPt.y - [[self curDCM] pheight]/2.0) * scaleValue;

	NSRect rect1 = [self rectForArrowButtonAtIndex:0];
	NSRect rect2 = [self rectForArrowButtonAtIndex:1];
	NSRect rect3 = [self rectForArrowButtonAtIndex:2];
		
	NSRect rectTopLimit = [self rectForLimitAtIndex:0];
	NSRect rectBottomLimit = [self rectForLimitAtIndex:1];

	if(NSPointInRect(tempPt, rect1) || NSPointInRect(tempPt, rect2) || NSPointInRect(tempPt, rect3))
	{
		[[NSCursor pointingHandCursor] set];
	}
	else if(NSPointInRect(tempPt, rectTopLimit) || NSPointInRect(tempPt, rectBottomLimit))
	{
		[[NSCursor resizeUpDownCursor] set];
		previous = tempPt;
	}
	else
	{
		[super mouseMoved:event];
		[cursor set];
	}
}

- (void)mouseDragged:(NSEvent *)event
{
//NSLog(@"mouseDragged");
	NSRect rectTopLimit = [self rectForLimitAtIndex:0];
	NSRect rectBottomLimit = [self rectForLimitAtIndex:1];
	
	NSRect rect1 = [self rectForArrowButtonAtIndex:0];
	NSRect rect2 = [self rectForArrowButtonAtIndex:1];
	NSRect rect3 = [self rectForArrowButtonAtIndex:2];
	
	if(draggingTopLimit || draggingBottomLimit)
	{
		NSPoint eventLocation = [event locationInWindow];
		NSPoint tempPt = [self convertPoint:eventLocation fromView: nil];
		
		tempPt = [self ConvertFromNSView2GL:tempPt];
		
		tempPt.x = (tempPt.x - [[self curDCM] pwidth]/2.0) * scaleValue;
		tempPt.y = (tempPt.y - [[self curDCM] pheight]/2.0) * scaleValue;
		
		int top, bottom;
		if(draggingTopLimit)
		{
			top = (tempPt.y/scaleValue)+[[self curDCM] pheight]/2.0;
			top = (isFlipped) ? (float)[[controller originalDCMPixList] count] - (float)top - 1.0 : top ;
			bottom = bottomLimit;
		}
		else
		{
			top = topLimit;
			bottom = (tempPt.y/scaleValue)+[[self curDCM] pheight]/2.0;
			bottom = (isFlipped) ? (float)[[controller originalDCMPixList] count] - (float)bottom - 1.0 : bottom ;
		}
			
		if(top-bottom < 10)
		{
			if(draggingTopLimit)
			{
				bottom -= 10-(top-bottom);
			}
			if(draggingBottomLimit)
			{
				top += 10-(top-bottom);
			}
		}
		
		if(bottom <= 10)
		{
			bottom = 10;
			if(draggingTopLimit && top <= 20)
				top = 20;
		}
		if(top >= (long)[[controller originalDCMPixList] count]-10)
		{
			top = (long)[[controller originalDCMPixList] count]-10;
			if(draggingBottomLimit && bottom >= [[controller originalDCMPixList] count]-20)
				bottom = [[controller originalDCMPixList] count]-20;
		}
		
		[(LLScoutViewer*)[controller viewer] setTopLimit:top bottomLimit:bottom];
	}
	else if(NSPointInRect(start, rect1) || NSPointInRect(start, rect2) || NSPointInRect(start, rect3) || NSPointInRect(start, rectTopLimit) || NSPointInRect(start, rectBottomLimit))
	{
		//NSLog(@"mouseDraged from a arrow button");
	}
	else
	{
		[super mouseDragged:event];
	}
}

- (void)mouseUp:(NSEvent *)event 
{
//NSLog(@"mouseUp");
	draggingTopLimit = NO;
	draggingBottomLimit = NO;
	[super mouseUp:event];
}

- (void) dealloc {
	NSLog(@"Scout View dealloc");
	[super dealloc];
}

@end
