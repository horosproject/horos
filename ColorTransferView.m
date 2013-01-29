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




#import "ColorTransferView.h"
#import "AppKit/NSColor.h"
#import "Notifications.h"

@implementation ColorTransferView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
        curIndex = -1;
		points =  [[NSMutableArray array] retain];
		colors =  [[NSMutableArray array] retain];
    }
    return self;
}

-(void) dealloc
{
	[points release];
	[colors release];
	
	[super dealloc];
}

- (IBAction) renderButton:(id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixCLUTChangedNotification object: self userInfo: nil];
}

-(void) selectPicker:(id) sender
{
	if( curIndex >= 0)
	{
		NSColor *newColor = [[pick color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
		
		[colors replaceObjectAtIndex: curIndex withObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: [newColor redComponent]], [NSNumber numberWithFloat: [newColor greenComponent]], [NSNumber numberWithFloat: [newColor blueComponent]],nil]]; 
	//	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixCLUTChangedNotification object: self userInfo: nil];
		[self setNeedsDisplay:YES];
	}
}

-(void) deleteCurrent
{
	[points removeObjectAtIndex: curIndex];
	[colors removeObjectAtIndex: curIndex];
	curIndex = -1;
	
	[position setStringValue: @""];
	
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)event
{
    NSPoint		eventLocation = [event locationInWindow];
	
		NSPoint		center;
	
	if( curIndex >= 0)
	{
		center = [self convertPoint:eventLocation fromView:nil];
		
		if( center.x < 0) center.x = 0;
		if( center.x > 512) center.x = 512;
		
		NSNumber	*curPt = [NSNumber numberWithLong: center.x/2];
		
		if( center.y < 0 || center.y > [self bounds].size.height)
		{
			[self deleteCurrent];
		}
		else
		{
			[points replaceObjectAtIndex: curIndex withObject: curPt];
			[points sortUsingSelector:@selector(compare:)];
			curIndex = [points indexOfObject:curPt];
			
			[position setIntValue: center.x/2];
		}
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseDown:(NSEvent *) event
{
    NSPoint		eventLocation = [event locationInWindow];
	NSPoint		center;
	BOOL		found = NO;
	long		i;
	
    center = [self convertPoint:eventLocation fromView:nil];
	
	for( i = 0; i < [ points count]; i++)
	{
		NSNumber *curPt = [points objectAtIndex: i];
		
		if( center.x/2 >= [curPt longValue]-2 && center.x/2 <= [curPt longValue]+2) // We found a point!
		{
			NSArray	*color;
			
			found = YES;
			curIndex = i;
			
			color = [colors objectAtIndex: curIndex];
			
			[pick setColor: [NSColor colorWithCalibratedRed: [[color objectAtIndex: 0] floatValue] green:[[color objectAtIndex: 1] floatValue] blue:[[color objectAtIndex: 2] floatValue] alpha: 1.0]];
			
			break;
		}
	}
	
	if( found == NO)
	{
		NSNumber  *newPt = [NSNumber numberWithLong:center.x/2];
		
		[points addObject:newPt];
		
		[points sortUsingSelector:@selector(compare:)];
		
		curIndex = [points indexOfObject:newPt];
		
		NSColor *newColor = [[pick color]  colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
		
		[colors insertObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: [newColor redComponent]], [NSNumber numberWithFloat: [newColor greenComponent]], [NSNumber numberWithFloat: [newColor blueComponent]],nil ] atIndex:curIndex];
	}
	
	[position setIntValue: center.x/2];
	
//	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixCLUTChangedNotification object: self userInfo: nil];
	
    [self setNeedsDisplay:YES];
}

-(NSMutableArray*) getPoints
{
	return points;
}

-(NSMutableArray*) getColors
{
	return colors;
}

-(void) ConvertCLUT:(unsigned char*) red : (unsigned char*) green : (unsigned char*) blue
{
	long		i, x, cur, last = 0;
	NSColor		*curColor = nil, *prevColor = [NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 1.0];
	
	for( i = 0; i < [points count]; i++)
	{
		NSArray	*color = [colors objectAtIndex: i];
		curColor = [NSColor colorWithCalibratedRed: [[color objectAtIndex: 0] floatValue] green:[[color objectAtIndex: 1] floatValue] blue:[[color objectAtIndex: 2] floatValue] alpha: 1.0];
		cur = [[points objectAtIndex: i] longValue];
		
		for( x = 0; x < cur-last; x++)
		{
			red[ last + x] = 255. * ([prevColor redComponent] + (([curColor redComponent] - [prevColor redComponent]) * x / (cur-last)));
			green[ last + x] = 255. * ([prevColor greenComponent] + (([curColor greenComponent] - [prevColor greenComponent]) * x / (cur-last)));
			blue[ last + x] = 255. * ([prevColor blueComponent] + (([curColor blueComponent] - [prevColor blueComponent]) * x / (cur-last)));
		}
		
		prevColor = curColor;
		last = cur;
	}
	
	cur = 256;
	curColor = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 1.0];
	for( x = 0; x < cur-last; x++)
	{
		red[ last + x] = 255. *([prevColor redComponent] + (([curColor redComponent] - [prevColor redComponent]) * x / (cur-last)));
		green[ last + x] = 255. *([prevColor greenComponent] + (([curColor greenComponent] - [prevColor greenComponent]) * x / (cur-last)));
		blue[ last + x] = 255. *([prevColor blueComponent] + (([curColor blueComponent] - [prevColor blueComponent]) * x / (cur-last)));
	}
}

- (void) drawRect:(NSRect)rect
{
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);   // Equiv to [[NSBezierPath bezierPathWithRect:[self bounds]] fill]

	long		i, x, cur, last = 0;
	NSColor		*curColor = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 1.0], *prevColor = [NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 1.0];
	NSRect		crect = NSZeroRect;
	
	if( curIndex >= [points count]) curIndex = -1;
	
	for( i = 0; i < [points count]; i++)
	{
		NSArray	*color = [colors objectAtIndex: i];
		curColor = [NSColor colorWithCalibratedRed: [[color objectAtIndex: 0] floatValue] green:[[color objectAtIndex: 1] floatValue] blue:[[color objectAtIndex: 2] floatValue] alpha: 1.0];
		cur = [[points objectAtIndex: i] longValue];
		
		for( x = 0; x < cur-last; x++)
		{
			NSColor *col = [NSColor colorWithCalibratedRed:  [prevColor redComponent] + (([curColor redComponent] - [prevColor redComponent]) * x / (cur-last))
													green:  [prevColor greenComponent] + (([curColor greenComponent] - [prevColor greenComponent]) * x / (cur-last))
													blue:   [prevColor blueComponent] + (([curColor blueComponent] - [prevColor blueComponent]) * x / (cur-last))
													alpha: 1.0];
													
			crect.origin.x = (last + x)*2;
			crect.origin.y = [self bounds].origin.y;
			crect.size.width = 2;
			crect.size.height = [self bounds].size.height;
			
			[col set];
			NSRectFill( crect);
		}
		
		if( i == curIndex) [[NSColor whiteColor] set];
		else [[NSColor blackColor] set];
			
		NSRectFill( crect);
		
		prevColor = curColor;
		last = cur;
	}
	
	cur = 256;
	curColor = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 1.0];
	for( x = 0; x < cur-last; x++)
	{
		NSColor *col = [NSColor colorWithCalibratedRed:  [prevColor redComponent] + (([curColor redComponent] - [prevColor redComponent]) * x / (cur-last))
												green:  [prevColor greenComponent] + (([curColor greenComponent] - [prevColor greenComponent]) * x / (cur-last))
												blue:   [prevColor blueComponent] + (([curColor blueComponent] - [prevColor blueComponent]) * x / (cur-last))
												alpha: 1.0];
												
		crect.origin.x = (last + x)*2;
		crect.origin.y = [self bounds].origin.y;
		crect.size.width = 2;
		crect.size.height = [self bounds].size.height;
		
		[col set];
		NSRectFill( crect);
	}
	
    [[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];
}
@end
