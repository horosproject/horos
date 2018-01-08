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
//  KBPopUpToolbarItem.m
//  --------------------
//
//  Created by Keith Blount on 14/05/2006.
//  Copyright 2006 Keith Blount. All rights reserved.
//


#import "KBPopUpToolbarItem.h"

static float backgroundInset = 1.5;

@implementation KBDelayedPopUpButtonCell

@synthesize arrowPath;

-(id)init
{
    if (self = [super init])
        arrowPath =nil;

    return self;
}

-(id)copyWithZone:(NSZone *)zone {
    KBDelayedPopUpButtonCell* copy = [super copyWithZone:zone];
    
    copy->arrowPath = [self.arrowPath copyWithZone:zone];
    
    return copy;
}

-(void)dealloc
{
    [arrowPath release];
    [super dealloc];
}

- (NSPoint)menuPositionForFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSPoint result = [controlView convertPoint:cellFrame.origin toView:nil];
	result.x += 1.0;
	result.y -= cellFrame.size.height + 5.5;
	return result;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [super drawInteriorWithFrame:cellFrame inView:controlView];
    
    if([self menu] && [self isEnabled]){
        
        if(arrowPath == nil){
            NSSize frameSize = cellFrame.size;
            
            NSBezierPath *path = [NSBezierPath bezierPath];
     
            float arrowWidth = [NSFont systemFontSizeForControlSize:[self controlSize]]*0.6;
            float arrowHeight = [NSFont systemFontSizeForControlSize:[self controlSize]]*0.5;
            
            float x=frameSize.width-backgroundInset-arrowWidth+cellFrame.origin.x;
            float y=frameSize.height-backgroundInset-arrowHeight+cellFrame.origin.y;
            
            [path moveToPoint:NSMakePoint(x, y)];
            [path lineToPoint:NSMakePoint(x+arrowWidth, y)];
            [path lineToPoint:NSMakePoint(x+arrowWidth/2.0, y+arrowHeight)];
            [path closePath];
            
            [self setArrowPath:path];
        }

        [[NSColor colorWithCalibratedWhite:0.1 alpha:0.8]set];
        [[self arrowPath] fill];
    }
}

- (void)showMenuForEvent:(NSEvent *)theEvent controlView:(NSView *)controlView cellFrame:(NSRect)cellFrame
{
	NSPoint menuPosition = [self menuPositionForFrame:cellFrame inView:controlView];
	
	// Create event for pop up menu with adjusted mouse position
	NSEvent *menuEvent = [NSEvent mouseEventWithType:[theEvent type]
											location:menuPosition
									   modifierFlags:[theEvent modifierFlags]
										   timestamp:[theEvent timestamp]
										windowNumber:[theEvent windowNumber]
											 context:[theEvent context]
										 eventNumber:[theEvent eventNumber]
										  clickCount:[theEvent clickCount]
											pressure:[theEvent pressure]];
	
	[NSMenu popUpContextMenu:[self menu] withEvent:menuEvent forView:controlView];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
	
	BOOL result = NO;
	NSDate *endDate;
	NSPoint currentPoint = [theEvent locationInWindow];
	BOOL done = NO;

    if ([self menu]) {
        
        NSSize frameSize = cellFrame.size;
        
		// check if mouse is over menu arrow
		NSPoint localPoint = [controlView convertPoint:currentPoint fromView:nil];

        float arrowWidth = [NSFont systemFontSizeForControlSize:[self controlSize]]*0.6;
        float arrowHeight = [NSFont systemFontSizeForControlSize:[self controlSize]]*0.5;
        
        float x=frameSize.width-backgroundInset-arrowWidth;
        float y=frameSize.height-backgroundInset-arrowHeight;

		if (localPoint.x >=x && localPoint.y>= y){
			[self showMenuForEvent:theEvent controlView:controlView cellFrame:cellFrame];
            return YES;
        }
	}
    
	BOOL trackContinously = [self startTrackingAt:currentPoint inView:controlView];
	
	// Catch next mouse-dragged or mouse-up event until timeout
	BOOL mouseIsUp = NO;
	NSEvent *event;
	while (!done)
	{
		NSPoint lastPoint = currentPoint;
		
		// Set up timer for pop-up menu if we have one
		if ([self menu])
			endDate = [NSDate dateWithTimeIntervalSinceNow:0.4];
		else
			endDate = [NSDate distantFuture];
		
		event = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)
								   untilDate:endDate
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];
		
		if (event)	// Mouse event
		{
			currentPoint = [event locationInWindow];
			
			// Send continueTracking.../stopTracking...
			if (trackContinously)
			{
				if (![self continueTracking:lastPoint at:currentPoint inView:controlView])
				{
					done = YES;
					[self stopTracking:lastPoint at:currentPoint inView:controlView mouseIsUp:mouseIsUp];
				}
				if ([self isContinuous])
				{
					[NSApp sendAction:[self action] to:[self target] from:controlView];
				}
			}
			
			mouseIsUp = ([event type] == NSLeftMouseUp);
			done = done || mouseIsUp;
			
			if (untilMouseUp)
			{
				result = mouseIsUp;
			}
			else
			{
				// Check if the mouse left our cell rect
				result = NSPointInRect([controlView convertPoint:currentPoint fromView:nil], cellFrame);
				if (!result)
					done = YES;
			}
			
			if (done && result && ![self isContinuous])
				[NSApp sendAction:[self action] to:[self target] from:controlView];
		
		}
		else	// Show menu
		{
			done = YES;
			result = YES;
			[self showMenuForEvent:theEvent controlView:controlView cellFrame:cellFrame];
		}
	}
	return result;
}

@end

@interface KBDelayedPopUpButton : NSButton
@end

@implementation KBDelayedPopUpButton

- (id)initWithFrame:(NSRect)frameRect
{
	if (self = [super initWithFrame:frameRect])
	{
		if (![[self cell] isKindOfClass:[KBDelayedPopUpButtonCell class]])
		{
			NSString *title = [self title];
			if (title == nil) title = @"";			
			[self setCell:[[[KBDelayedPopUpButtonCell alloc] initTextCell:title] autorelease]];
			[[self cell] setControlSize:NSRegularControlSize];
		}
	}
	return self;
}

@end


@implementation KBPopUpToolbarItem

- (id)initWithItemIdentifier:(NSString *)ident
{
	if (self = [super initWithItemIdentifier:ident])
	{
        button = [[KBDelayedPopUpButton alloc] initWithFrame:NSMakeRect(0,0,42,32)];
		[button setButtonType:NSMomentaryChangeButton];
		[button setBordered:NO];

        [button setImagePosition: NSImageLeft];
        [button setTitle:@""];
		[self setView:button];
		[self setMinSize:NSMakeSize(42,32)];
		[self setMaxSize:NSMakeSize(42,32)];
        
    }
	return self;
}

// Note that we make no assumptions about the retain/release of the toolbar item's view, just to be sure -
// we therefore retain our button view until we are dealloc'd.
- (void)dealloc
{
	[button release];
	[regularImage release];
	[smallImage release];
	[super dealloc];
}

- (KBDelayedPopUpButtonCell *)popupCell
{
	return [(KBDelayedPopUpButton *)[self view] cell];
}

- (void)setMenu:(NSMenu *)menu
{
	[[self popupCell] setMenu:menu];
	
	// Also set menu form representation -
    // This is used in the toolbar overflow menu but also, more importantly, to display a menu in text-only mode.
	NSMenuItem *menuFormRep = [[[NSMenuItem alloc] initWithTitle:[self label] action:nil keyEquivalent:@""] autorelease];
	[menuFormRep setSubmenu:menu];
	[self setMenuFormRepresentation:menuFormRep];
}

- (NSMenu *)menu
{
	return [[self popupCell] menu];
}

- (void)setAction:(SEL)aSelector
{
	[[self popupCell] setAction:aSelector];
}

- (SEL)action
{
	return [[self popupCell] action];
}

- (void)setTarget:(id)anObject
{
	[[self popupCell] setTarget:anObject];
}

- (id)target
{
	return [[self popupCell] target];
}

- (void)setImage:(NSImage *)anImage
{
	[regularImage autorelease];
	[smallImage autorelease];
	
	regularImage = [anImage copy];
    [regularImage setSize:NSMakeSize(32,32)];
    
	smallImage = [anImage copy];
	[smallImage setSize:NSMakeSize(24,24)];

	if ([[self toolbar] sizeMode] == NSToolbarSizeModeSmall)
        anImage = smallImage;

	[[self popupCell] setImage:anImage];
}

- (NSImage *)image
{
	return [[self popupCell] image];
}

- (void)setToolTip:(NSString *)theToolTip
{
	[[self view] setToolTip:theToolTip];
}

- (NSString *)toolTip
{
	return [[self view] toolTip];
}

- (void)validate
{
	// First, make sure the toolbar image size fits the toolbar size mode; there must be a better place to do this!
	NSToolbarSizeMode sizeMode = [[self toolbar] sizeMode];
//	float imgWidth = [[self image] size].width;
	
	if (sizeMode == NSToolbarSizeModeSmall)
	{
		[[self popupCell] setImage:smallImage];
	}
	else if (sizeMode == NSToolbarSizeModeRegular)
	{
		[[self popupCell] setImage:regularImage];
	}
	
	if ([self action])
	{
		if (![self target])
			[self setEnabled:[[[[self view] window] firstResponder] respondsToSelector:[self action]]];
		
		else {
            if ([[self target] respondsToSelector:@selector(validateToolbarItem:)])
                [self setEnabled:[[self target] validateToolbarItem:self]];
            else
                [self setEnabled:[[self target] respondsToSelector:[self action]]];
        }
	}
    else 
    if ([[self toolbar] delegate])
    {
        BOOL enabled = YES;
        
        if ([[[self toolbar] delegate] respondsToSelector:@selector(validateToolbarItem:)])
            enabled = [(id)[[self toolbar] delegate] validateToolbarItem:self];
        
        else if ([[[self toolbar] delegate] respondsToSelector:@selector(validateUserInterfaceItem:)])
            enabled = [(id)[[self toolbar] delegate] validateUserInterfaceItem:self];
        
        [self setEnabled:enabled];
    }
	else
		[super validate];
}

@end
