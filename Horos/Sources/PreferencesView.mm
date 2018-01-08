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

#import "PreferencesView.h"
#import "N2Debug.h"
#import "NSImage+N2.h"
#import "N2Operators.h"
#include <algorithm>
#import "PreferencesWindowController.h"

@interface PreferencesViewGroup : NSObject {
	NSTextField* label;
	NSMutableArray* buttons;
}

@property(readonly) NSTextField* label;
@property(readonly) NSMutableArray* buttons;

-(id)initWithName:(NSString*)name;

@end
@implementation PreferencesViewGroup

@synthesize label, buttons;

-(id)initWithName:(NSString*)name {
	self = [super init];
	
	buttons = [[NSMutableArray alloc] init];
	
	label = [[NSTextField alloc] initWithFrame:NSZeroRect];
	[label setStringValue:name];
	[label setEditable:NO];
	[label setDrawsBackground:NO];
	[label setBordered:NO];
	[label setSelectable:NO];
	[label setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]];
	
	return self;
}

-(void)dealloc {
	[label release];
	[buttons release];
	[super dealloc];
}

@end


@interface PreferencesViewButtonCell : NSButtonCell
@end
@implementation PreferencesViewButtonCell

static const NSInteger labelHeight = 38, labelSeparator = 3;

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)controlView {
	[NSGraphicsContext saveGraphicsState];
	
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy:0 yBy:frame.size.height];
	[transform scaleXBy:1 yBy:-1];
	[transform concat];
	
	NSRect imageRect = NSMakeRect(frame.origin.x, frame.origin.y+labelHeight+labelSeparator, frame.size.width, frame.size.height-labelHeight-labelSeparator);
	
	NSImage* image = [self isHighlighted]? self.alternateImage : self.image;
	NSSize imageSize = [image size];
	if (imageSize.width > 32 || imageSize.height > 32) [image setSize:imageSize = NSMakeSize(32,32)];
	[image drawAtPoint:imageRect.origin+NSMakePoint((imageRect.size.width-imageSize.width)/2, 0) fromRect:NSMakeRect(NSZeroPoint, imageSize) operation:NSCompositeSourceOver fraction:1];

	[NSGraphicsContext restoreGraphicsState];
	
	NSRect labelRect = NSMakeRect(frame.origin.x, frame.size.height-labelHeight, frame.size.width, labelHeight);
	
	NSMutableParagraphStyle* style = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setAlignment:NSCenterTextAlignment];
	NSFont* font = [NSFont labelFontOfSize:[NSFont smallSystemFontSize]];
	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									style, NSParagraphStyleAttributeName,
									font, NSFontAttributeName,
								NULL];
	[self.title drawInRect:labelRect withAttributes:attributes];
}

@end


@interface PreferencesView (Private)

-(void)layout;

@end


@implementation PreferencesView

@synthesize buttonActionTarget, buttonActionSelector;

-(id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	groups = [[NSMutableArray alloc] init];
	
	return self;
}

-(void)dealloc {
	[groups release];
	[super dealloc];
}

-(PreferencesViewGroup*)groupWithName:(NSString*)name {
	PreferencesViewGroup* group = NULL;
	for (PreferencesViewGroup* g in groups)
		if ([g.label.stringValue isEqualToString:name])
			group = g;

	if (!group) {
		group = [[[PreferencesViewGroup alloc] initWithName:name] autorelease];
		[self addSubview:group.label];
		[groups addObject:group];
	}
	
	return group;
}

-(void)removeItemWithBundle: (NSBundle*) bundle
{
    for (PreferencesViewGroup* group in groups)
    {
        for( NSButton *button in group.buttons)
        {
            PreferencesWindowContext *context = [[button cell] representedObject];
            
            if( [context parentBundle] == bundle)
            {
                [group.buttons removeObject:button];
                [self layout];
                return;
            }
        }
    }
}

-(void)addItemWithTitle:(NSString*)title image:(NSImage*)image toGroupWithName:(NSString*)groupName context:(id)context {
	PreferencesViewGroup* group = [self groupWithName:groupName];
	
	NSButton* button = [[[NSButton alloc] initWithFrame:NSZeroRect] autorelease];
	[button setCell:[[[PreferencesViewButtonCell alloc] init] autorelease]];
	[button setTitle:title];
	[button setImage:image];
	[button setAlternateImage:[image shadowImage]];
	[button setTarget:self];
	[button setAction:@selector(buttonAction:)];
	[[button cell] setRepresentedObject:context];
	[self addSubview:button];
	
	[group.buttons addObject:button];
	
	[self layout];
}

-(BOOL)isOpaque {
	return NO;
}

-(void)buttonAction:(NSButton*)sender {
    if ([[self buttonActionTarget] respondsToSelector:[self buttonActionSelector]])
        [[self buttonActionTarget] performSelector:[self buttonActionSelector] withObject:[[sender cell] representedObject]];
}

-(NSUInteger)itemsCount {
	NSUInteger count = 0;
	for (PreferencesViewGroup* group in groups)
		count += group.buttons.count;
	return count;
}

-(id)contextForItemAtIndex:(NSUInteger)index {
	NSUInteger count = 0;
	for (NSUInteger r = 0; r < groups.count; ++r) {
		NSArray* buttons = [[groups objectAtIndex:r] buttons];
		if (count+buttons.count > index)
			return [[[buttons objectAtIndex:index-count] cell] representedObject];
		count += buttons.count;
	}
	
	return NULL;
}

-(NSInteger)indexOfItemWithContext:(id)context {
	NSUInteger count = 0;
	for (NSUInteger r = 0; r < groups.count; ++r)
		for (NSButton* button in [[groups objectAtIndex:r] buttons])
			if ([[button cell] representedObject] == context)
				return count;
			else ++count;
	return -1;
}

static const NSUInteger colWidth = 80, colSeparator = 1, rowHeight = 101, titleHeight = 20, titleMargin[2] = {6,3}, padding[4] = {0,16,1,6}; //top,right,bottom,left

-(void)drawRect:(NSRect)dirtyRect {
	[NSGraphicsContext saveGraphicsState];
	
	NSRect frame = [self bounds];
	
//	[[self backgroundColor] setFill];
//	[NSBezierPath fillRect:frame];
	
    [[NSColor colorWithCalibratedWhite:.89 alpha:1] setFill];
    [[NSColor colorWithCalibratedWhite:.80 alpha:1] setStroke];
	[NSBezierPath setDefaultLineWidth:1];
	for (NSUInteger r = 1; r < groups.count; r += 2) {
		NSRect rect = NSMakeRect(0, frame.size.height-rowHeight*r-rowHeight-padding[0], frame.size.width, rowHeight);
		[NSBezierPath fillRect:rect];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y+.5) toPoint:NSMakePoint(rect.origin.x+rect.size.width, rect.origin.y+.5)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y+rect.size.height-.5) toPoint:NSMakePoint(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height-.5)];
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
//	[super drawRect:];
}

@end

@implementation PreferencesView (Private)

-(void)layout {
	NSUInteger colsCount = 0;
	for (PreferencesViewGroup* group in groups)
		colsCount = std::max(colsCount, group.buttons.count);
	
	NSRect frame = [self frame];
	frame = NSMakeRect(frame.origin.x, frame.origin.y, padding[3]+(colWidth+colSeparator)*colsCount-colSeparator+padding[1], padding[2]+rowHeight*groups.count+padding[0]);
	[self setFrame:frame];

	for (NSInteger r = (long)groups.count-1; r >= 0; --r) {
		PreferencesViewGroup* group = [groups objectAtIndex:r];
		NSRect rowRect = NSMakeRect(padding[3], frame.size.height-rowHeight*r-rowHeight-padding[0], frame.size.width-padding[3]-padding[1], rowHeight);
		
		[group.label setFrame:NSMakeRect(rowRect.origin.x+titleMargin[0], rowRect.origin.y+rowRect.size.height-titleHeight-titleMargin[1], rowRect.size.width-titleMargin[0]*2, titleHeight)];
		
		for (NSUInteger i = 0; i < group.buttons.count; ++i) {
			NSButton* button = [group.buttons objectAtIndex:i];
			NSRect rect = NSMakeRect(rowRect.origin.x+(colWidth+colSeparator)*i, rowRect.origin.y, colWidth, rowHeight);
			[button setFrame:rect];
		}
	}
    
    [super layout];
}

@end









