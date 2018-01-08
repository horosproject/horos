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
//  PRHOnOffButtonCell.m
//  PRHOnOffButton
//
//  Created by Peter Hosey on 2010-01-10.
//  Copyright 2010 Peter Hosey. All rights reserved.
//
//  Extended by Dain Kaplan on 2012-01-31.
//  Copyright 2012 Dain Kaplan. All rights reserved.
//

#import "OnOffSwitchControlCell.h"

#include <Carbon/Carbon.h>

// NOTE(dk): New defines for changing appearance
#define USE_COLORED_GRADIENTS true
#define SHOW_ONOFF_LABELS true

#define ONE_THIRD  (1.0 / 3.0)
#define ONE_HALF   (1.0 / 2.0)
#define TWO_THIRDS (2.0 / 3.0)

#define THUMB_WIDTH_FRACTION 0.45f
#define THUMB_CORNER_RADIUS 2.5f
#define FRAME_CORNER_RADIUS 2.5f

#define THUMB_GRADIENT_MAX_Y_WHITE 1.0f
#define THUMB_GRADIENT_MIN_Y_WHITE 0.9f
#define BACKGROUND_GRADIENT_MAX_Y_WHITE 0.5f
#define BACKGROUND_GRADIENT_MIN_Y_WHITE TWO_THIRDS
#define BACKGROUND_SHADOW_GRADIENT_WHITE 0.0f
#define BACKGROUND_SHADOW_GRADIENT_MAX_Y_ALPHA 0.35f
#define BACKGROUND_SHADOW_GRADIENT_MIN_Y_ALPHA 0.0f
#define BACKGROUND_SHADOW_GRADIENT_HEIGHT 4.0f
#define BORDER_WHITE 0.125f

#define THUMB_SHADOW_WHITE 0.0f
#define THUMB_SHADOW_ALPHA 0.5f
#define THUMB_SHADOW_BLUR 3.0f

#define DISABLED_OVERLAY_GRAY  1.0f
#define DISABLED_OVERLAY_ALPHA TWO_THIRDS

#define DOWNWARD_ANGLE_IN_DEGREES_FOR_VIEW(view) ([view isFlipped] ? 90.0f : 270.0f)

struct PRHOOBCStuffYouWouldNeedToIncludeCarbonHeadersFor {
	EventTime clickTimeout;
	HISize clickMaxDistance;
};

@interface  OnOffSwitchControlCell() 

@property (readwrite, retain) NSColor *customOnColor;
@property (readwrite, retain) NSColor *customOffColor;

- (CGFloat)centerXForThumbWithFrame:(NSRect)cellFrame;
- (void)drawText:(NSString *)text withFrame:(NSRect)textFrame;
- (void)tintBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end

// NOTE(dk): start additions

// NOTE(dk): Mostly taken from: http://cocoaheads.org/peg-narrative/basic-drawing.html
NSRect DKCenterRect(NSRect smallRect, NSRect bigRect)
{
    NSRect centerRect;
    centerRect.size = smallRect.size;
    centerRect.origin.x = bigRect.origin.x + (bigRect.size.width - smallRect.size.width) / 2.0;
    centerRect.origin.y = bigRect.origin.y + (bigRect.size.height - smallRect.size.height) / 2.0;
    return (centerRect);
}
// NOTE(dk): end additions

@implementation OnOffSwitchControlCell

@synthesize showsOnOffLabels;
@synthesize onOffSwitchControlColors;
@synthesize customOffColor;
@synthesize customOnColor;
@synthesize onSwitchLabel;
@synthesize offSwitchLabel;

+ (BOOL) prefersTrackingUntilMouseUp {
	return /*YES, YES, a thousand times*/ YES;
}

+ (NSFocusRingType) defaultFocusRingType {
	return NSFocusRingTypeExterior;
}

- (void) furtherInit {
	[self setFocusRingType:[[self class] defaultFocusRingType]];
	stuff = NSZoneMalloc([self zone], sizeof(struct PRHOOBCStuffYouWouldNeedToIncludeCarbonHeadersFor));
	OSStatus err = HIMouseTrackingGetParameters(kMouseParamsSticky, &(stuff->clickTimeout), &(stuff->clickMaxDistance));
	if (err != noErr) {
		//Values returned by the above function call as of 10.6.3.
		stuff->clickTimeout = ONE_THIRD * kEventDurationSecond;
		stuff->clickMaxDistance = (HISize){ 6.0f, 6.0f };
	}
	// NOTE(dk): start additions 
	self.showsOnOffLabels = YES;
	self.onOffSwitchControlColors = OnOffSwitchControlBlueGreyColors;
	self.onSwitchLabel = @"ON";
	self.offSwitchLabel = @"OFF";
	// NOTE(dk): end additions
}

- (id) initImageCell:(NSImage *)image {
	if ((self = [super initImageCell:image])) {
		[self furtherInit];
	}
	return self;
}
- (id) initTextCell:(NSString *)str {
	if ((self = [super initTextCell:str])) {
		[self furtherInit];
	}
	return self;
}
//HAX: IB (I guess?) sets our focus ring type to None for some reason. Nobody asks defaultFocusRingType unless we do it (in furtherInit).
- (id) initWithCoder:(NSCoder *)decoder {
	if ((self = [super initWithCoder:decoder])) {
		[self furtherInit];
	}
	return self;
}

- (NSRect) thumbRectInFrame:(NSRect)cellFrame {
	cellFrame.size.width -= 2.0f;
	cellFrame.size.height -= 2.0f;
	cellFrame.origin.x += 1.0f;
	cellFrame.origin.y += 1.0f;

	NSRect thumbFrame = cellFrame;
	thumbFrame.size.width *= THUMB_WIDTH_FRACTION;

	NSCellStateValue state = [self state];
	switch (state) {
		case NSOffState:
			//Far left. We're already there; don't do anything.
			break;
		case NSOnState:
			//Far right.
			thumbFrame.origin.x += (cellFrame.size.width - thumbFrame.size.width);
			break;
		case NSMixedState:
			//Middle.
			thumbFrame.origin.x = (cellFrame.size.width / 2.0f) - (thumbFrame.size.width / 2.0f);
			break;
	}

	return thumbFrame;
}

// NOTE(dk): start additions

- (void) setOnOffSwitchCustomOnColor:(NSColor *)onColor offColor:(NSColor *)offColor
{
	self.customOffColor = offColor;
	self.customOnColor = onColor;
}

// NOTE(dk): Split this out so we can call it elsewhere.
- (CGFloat)centerXForThumbWithFrame:(NSRect)cellFrame
{
	NSRect thumbFrame = [self thumbRectInFrame:cellFrame];
	if (tracking) {
		thumbFrame.origin.x += trackingPoint.x - initialTrackingPoint.x;
		
		//Clamp.
		CGFloat minOrigin = cellFrame.origin.x + 1;
		CGFloat maxOrigin = cellFrame.origin.x + (cellFrame.size.width - thumbFrame.size.width - 1);
		if (thumbFrame.origin.x < minOrigin)
			thumbFrame.origin.x = minOrigin;
		else if (thumbFrame.origin.x > maxOrigin)
			thumbFrame.origin.x = maxOrigin;
	}
	return NSMidX(thumbFrame);
}

// NOTE(dk): Center the text (as able) in the provided frame and draw it.
- (void)drawText:(NSString *)text withFrame:(NSRect)textFrame {
	CGFloat fontSize = [NSFont systemFontSizeForControlSize:[self controlSize]];
	//[NSFont fontWithName: @"HelveticaNeue-Bold" size:fontSize];
	NSFont *sysFont = [NSFont boldSystemFontOfSize:fontSize];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								sysFont, NSFontAttributeName, 
								[NSColor whiteColor], NSForegroundColorAttributeName, nil];
	NSSize textSize = [text sizeWithAttributes:attributes];
	NSRect textBounds = DKCenterRect(NSMakeRect(0, 0, textSize.width, textSize.height), textFrame);
	[text drawInRect: textBounds withAttributes:attributes];
}

// Applies tints to the background to show the on/off state.
- (void)tintBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	[[NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:FRAME_CORNER_RADIUS yRadius:FRAME_CORNER_RADIUS] addClip];
	
	// NOTE(dk): Make everything to the left of the thumb one color, and to the right another.
	NSRect thumbFrame = [self thumbRectInFrame:cellFrame];
	CGFloat thumbCenterX = [self centerXForThumbWithFrame:cellFrame];
	NSRect leftFrame;
	NSRect rightFrame;
	CGFloat offsetWidth = thumbCenterX;
	NSDivideRect(cellFrame, &leftFrame, &rightFrame, offsetWidth - cellFrame.origin.x, NSMinXEdge);
	//NSLog(@"OffsetWidth is: %f / %f; left: %f; right: %f", offsetWidth, cellFrame.origin.x, leftFrame.size.width, rightFrame.size.width);
	
	NSColor *onStartColor;
	NSColor *onEndColor;
	NSColor *offStartColor;
	NSColor *offEndColor;

	NSColor *_blueColor = [NSColor colorWithCalibratedRed:0.0 green:0.3 blue:1.0 alpha:0.6f];
	NSColor *_greyColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.0f];
	NSColor *_greenColor = [NSColor colorWithCalibratedRed:0.0 green:0.7 blue:0.0 alpha:0.6f];
	NSColor *_redColor = [NSColor colorWithCalibratedRed:0.7 green:0.0 blue:0.0 alpha:0.6f];
		
	switch (self.onOffSwitchControlColors) {
		case OnOffSwitchControlBlueGreyColors:
			onStartColor = onEndColor = _blueColor;
			offStartColor = offEndColor = _greyColor;
			break;
		case OnOffSwitchControlGreenRedColors:
			onStartColor = onEndColor = _greenColor;
			offStartColor = offEndColor = _redColor;
			break;
		case OnOffSwitchControlBlueRedColors:
			onStartColor = onEndColor = _blueColor;
			offStartColor = offEndColor = _redColor;
			break;
		case OnOffSwitchControlCustomColors:
			onStartColor = onEndColor = self.customOnColor;
			offStartColor = offEndColor = self.customOffColor;
			break;
		case OnOffSwitchControlDefaultColors:
		default:
			onStartColor = onEndColor = nil;
			offStartColor = offEndColor = nil;
	}
	
	if (onStartColor != nil && offStartColor != nil) {
		NSGradient *leftBackground = [[NSGradient alloc] initWithStartingColor:onStartColor 
																	endingColor:onEndColor];
		NSGradient *rightBackground = [[NSGradient alloc] initWithStartingColor:offStartColor 
																	 endingColor:offEndColor];
		[leftBackground drawInRect:NSInsetRect(leftFrame, 1.0f, 1.0f) angle:DOWNWARD_ANGLE_IN_DEGREES_FOR_VIEW(controlView)];
		[rightBackground drawInRect:NSInsetRect(rightFrame, 1.0f, 1.0f) angle:DOWNWARD_ANGLE_IN_DEGREES_FOR_VIEW(controlView)];
		[leftBackground release];
		[rightBackground release];
	}
	[context restoreGraphicsState];
	
	if (self.showsOnOffLabels) {
		// Left label
		NSRect leftSizeFrame;
		leftSizeFrame.origin.x = (tracking ? thumbCenterX-(thumbFrame.size.width/2) : thumbFrame.origin.x) - (cellFrame.size.width - thumbFrame.size.width) + 2;
		leftSizeFrame.origin.y = cellFrame.origin.y;
		leftSizeFrame.size.width = cellFrame.size.width - thumbFrame.size.width - 2;
		leftSizeFrame.size.height = cellFrame.size.height;
		[self drawText:self.onSwitchLabel withFrame:leftSizeFrame];
		
		// Right label
		NSRect rightSizeFrame = leftSizeFrame;
		rightSizeFrame.origin.x = (tracking ? thumbCenterX+(thumbFrame.size.width/2): thumbFrame.origin.x + thumbFrame.size.width) + 1;
		rightSizeFrame.origin.y = cellFrame.origin.y;
		[self drawText:self.offSwitchLabel withFrame:rightSizeFrame];
	}
}
// NOTE(dk): end additions

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if (tracking)
		trackingCellFrame = cellFrame;

	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	CGContextRef quartzContext = [context graphicsPort];
	CGContextBeginTransparencyLayer(quartzContext, /*auxInfo*/ NULL);

	//Draw the background, then the frame.
	NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 1.0f, 1.0f) xRadius:FRAME_CORNER_RADIUS yRadius:FRAME_CORNER_RADIUS];

	[[NSColor colorWithCalibratedWhite:BORDER_WHITE alpha:1.0f] setStroke];
	[borderPath stroke];
	
	NSColor *startColor = [NSColor colorWithCalibratedWhite:BACKGROUND_GRADIENT_MAX_Y_WHITE alpha:1.0f];
	NSColor *endColor = [NSColor colorWithCalibratedWhite:BACKGROUND_GRADIENT_MIN_Y_WHITE alpha:1.0f];
	NSGradient *background = [[[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor] autorelease];
	[background drawInBezierPath:borderPath angle:DOWNWARD_ANGLE_IN_DEGREES_FOR_VIEW(controlView)];

	[context saveGraphicsState];
	
	[[NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:FRAME_CORNER_RADIUS yRadius:FRAME_CORNER_RADIUS] addClip];
	
	// NOTE(dk): start additions
	if (USE_COLORED_GRADIENTS && ![self allowsMixedState]) {
		[self tintBackgroundWithFrame:cellFrame inView:controlView];
	}
	// NOTE(dk): end additions
	
	NSGradient *backgroundShadow = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:BACKGROUND_SHADOW_GRADIENT_WHITE alpha:BACKGROUND_SHADOW_GRADIENT_MAX_Y_ALPHA] endingColor:[NSColor colorWithCalibratedWhite:BACKGROUND_SHADOW_GRADIENT_WHITE alpha:BACKGROUND_SHADOW_GRADIENT_MIN_Y_ALPHA]] autorelease];
	NSRect backgroundShadowRect = cellFrame;
	if (![controlView isFlipped])
		backgroundShadowRect.origin.y += backgroundShadowRect.size.height - BACKGROUND_SHADOW_GRADIENT_HEIGHT;
	backgroundShadowRect.size.height = BACKGROUND_SHADOW_GRADIENT_HEIGHT;
	[backgroundShadow drawInRect:backgroundShadowRect angle:DOWNWARD_ANGLE_IN_DEGREES_FOR_VIEW(controlView)];

	[context restoreGraphicsState];

	[self drawInteriorWithFrame:cellFrame inView:controlView];

	if (![self isEnabled]) {
		CGColorRef color = CGColorCreateGenericGray(DISABLED_OVERLAY_GRAY, DISABLED_OVERLAY_ALPHA);
		if (color) {
			CGContextSetBlendMode(quartzContext, kCGBlendModeLighten);
			CGContextSetFillColorWithColor(quartzContext, color);
			CGContextFillRect(quartzContext, NSRectToCGRect(cellFrame));

			CFRelease(color);
		}
	}
	CGContextEndTransparencyLayer(quartzContext);
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	//Draw the thumb.
	NSRect thumbFrame = [self thumbRectInFrame:cellFrame];
	
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];

	cellFrame.size.width -= 2.0f;
	cellFrame.size.height -= 2.0f;
	cellFrame.origin.x += 1.0f;
	cellFrame.origin.y += 1.0f;
	NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:THUMB_CORNER_RADIUS yRadius:THUMB_CORNER_RADIUS];
	[clipPath addClip];

	if (tracking) {
		thumbFrame.origin.x += trackingPoint.x - initialTrackingPoint.x;

		//Clamp.
		CGFloat minOrigin = cellFrame.origin.x;
		CGFloat maxOrigin = cellFrame.origin.x + (cellFrame.size.width - thumbFrame.size.width);
		if (thumbFrame.origin.x < minOrigin)
			thumbFrame.origin.x = minOrigin;
		else if (thumbFrame.origin.x > maxOrigin)
			thumbFrame.origin.x = maxOrigin;

		trackingThumbCenterX = [self centerXForThumbWithFrame:cellFrame];
	}

	NSBezierPath *thumbPath = [NSBezierPath bezierPathWithRoundedRect:thumbFrame xRadius:THUMB_CORNER_RADIUS yRadius:THUMB_CORNER_RADIUS];
	NSShadow *thumbShadow = [[[NSShadow alloc] init] autorelease];
	[thumbShadow setShadowColor:[NSColor colorWithCalibratedWhite:THUMB_SHADOW_WHITE alpha:THUMB_SHADOW_ALPHA]];
	[thumbShadow setShadowBlurRadius:THUMB_SHADOW_BLUR];
	[thumbShadow setShadowOffset:NSZeroSize];
	[thumbShadow set];
	[[NSColor whiteColor] setFill];
	if ([self showsFirstResponder] && ([self focusRingType] != NSFocusRingTypeNone))
		NSSetFocusRingStyle(NSFocusRingBelow);
	[thumbPath fill];
	NSGradient *thumbGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:THUMB_GRADIENT_MAX_Y_WHITE alpha:1.0f] endingColor:[NSColor colorWithCalibratedWhite:THUMB_GRADIENT_MIN_Y_WHITE alpha:1.0f]] autorelease];
	[thumbGradient drawInBezierPath:thumbPath angle:DOWNWARD_ANGLE_IN_DEGREES_FOR_VIEW(controlView)];

	[context restoreGraphicsState];

	if (tracking && (getenv("PRHOnOffButtonCellDebug") != NULL)) {
		NSBezierPath *thumbCenterLine = [NSBezierPath bezierPath];
		[thumbCenterLine moveToPoint:(NSPoint){ NSMidX(thumbFrame), thumbFrame.origin.y +thumbFrame.size.height * ONE_THIRD }];
		[thumbCenterLine lineToPoint:(NSPoint){ NSMidX(thumbFrame), thumbFrame.origin.y +thumbFrame.size.height * TWO_THIRDS }];
		[thumbCenterLine stroke];

		NSBezierPath *sectionLines = [NSBezierPath bezierPath];
		if ([self allowsMixedState]) {
			[sectionLines moveToPoint:(NSPoint){ cellFrame.origin.x + cellFrame.size.width * ONE_THIRD, NSMinY(cellFrame) }];
			[sectionLines lineToPoint:(NSPoint){ cellFrame.origin.x + cellFrame.size.width * ONE_THIRD, NSMaxY(cellFrame) }];
			[sectionLines moveToPoint:(NSPoint){ cellFrame.origin.x + cellFrame.size.width * TWO_THIRDS, NSMinY(cellFrame) }];
			[sectionLines lineToPoint:(NSPoint){ cellFrame.origin.x + cellFrame.size.width * TWO_THIRDS, NSMaxY(cellFrame) }];
		} else {
			[sectionLines moveToPoint:(NSPoint){ cellFrame.origin.x + cellFrame.size.width * ONE_HALF, NSMinY(cellFrame) }];
			[sectionLines lineToPoint:(NSPoint){ cellFrame.origin.x + cellFrame.size.width * ONE_HALF, NSMaxY(cellFrame) }];
		}
		[sectionLines stroke];
	}
}

- (NSCellHitResult)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
	NSPoint mouseLocation = [controlView convertPoint:[event locationInWindow] fromView:nil];
	return NSPointInRect(mouseLocation, cellFrame) ? (NSCellHitContentArea | NSCellHitTrackableArea) : NSCellHitNone;
}

- (BOOL) startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
	//We rely on NSControl behavior, so only start tracking if this is a control.
	tracking = YES;
	trackingPoint = initialTrackingPoint = startPoint;
	trackingTime = initialTrackingTime = [NSDate timeIntervalSinceReferenceDate];
	return [controlView isKindOfClass:[NSControl class]];
}
- (BOOL) continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
	NSControl *control = [controlView isKindOfClass:[NSControl class]] ? (NSControl *)controlView : nil;
	if (control) {
		trackingPoint = currentPoint;
		//No need to update the time here as long as nothing cares about it.
		trackingTime = initialTrackingTime = [NSDate timeIntervalSinceReferenceDate];
		[control drawCell:self];
		return YES;
	}
	tracking = NO;
	return NO;
}
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
	tracking = NO;
	trackingTime = [NSDate timeIntervalSinceReferenceDate];

	NSControl *control = [controlView isKindOfClass:[NSControl class]] ? (NSControl *)controlView : nil;
	if (control) {
		CGFloat xFraction = trackingThumbCenterX / trackingCellFrame.size.width;

		BOOL isClickNotDragByTime = (trackingTime - initialTrackingTime) < stuff->clickTimeout;
		BOOL isClickNotDragBySpaceX = (stopPoint.x - initialTrackingPoint.x) < stuff->clickMaxDistance.width;
		BOOL isClickNotDragBySpaceY = (stopPoint.y - initialTrackingPoint.y) < stuff->clickMaxDistance.height;
		BOOL isClickNotDrag = isClickNotDragByTime && isClickNotDragBySpaceX && isClickNotDragBySpaceY;

		if (!isClickNotDrag) {
			NSCellStateValue desiredState;

			if ([self allowsMixedState]) {
				if (xFraction < ONE_THIRD)
					desiredState = NSOffState;
				else if (xFraction >= TWO_THIRDS)
					desiredState = NSOnState;
				else
					desiredState = NSMixedState;
			} else {
				if (xFraction < ONE_HALF)
					desiredState = NSOffState;
				else
					desiredState = NSOnState;
			}

			//We actually need to set the state to the one *before* the one we want, because NSCell will advance it. I'm not sure how to thwart that without breaking -setNextState, which breaks AXPress and the space bar.
			NSCellStateValue stateBeforeDesiredState;
			switch (desiredState) {
				case NSOnState:
					if ([self allowsMixedState]) {
						stateBeforeDesiredState = NSMixedState;
						break;
					}
					//Fall through.
				case NSMixedState:
					stateBeforeDesiredState = NSOffState;
					break;
				case NSOffState:
					stateBeforeDesiredState = NSOnState;
					break;
			}

			[self setState:stateBeforeDesiredState];
		}
	}
}

@end
