/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "OpacityTransferView.h"
#import "AppKit/NSColor.h"

@implementation OpacityTransferView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		long i;
		
        curIndex = -1;
		points =  [[NSMutableArray arrayWithCapacity:0] retain];
		
		for( i = 0; i < 256; i++)
		{
			red[ i] = i;
			green[ i] = i;
			blue[ i] = i;
		}
    }
    return self;
}

-(void) dealloc
{
	[points release];
	
	[super dealloc];
}

- (void)mouseDragged:(NSEvent *)event
{
    NSPoint		eventLocation = [event locationInWindow];
	NSPoint		center;
	
	if( curIndex >= 0)
	{
		center = [self convertPoint:eventLocation fromView:nil];
				
		if( center.y < 0 || center.y > [self bounds].size.height)
		{
			[points removeObjectAtIndex: curIndex];
			curIndex = -1;
			
			[position setStringValue: @""];
		}
		else
		{
			if( center.x < 0) center.x = 0;
			if( center.x > 512) center.x = 512;
			
			if( center.y < 0) center.y = 0;
			if( center.y > 100) center.y = 100;
			
			NSPoint	curPt = NSMakePoint(1000 + center.x/2., center.y/100.);
			NSString	*ptString = NSStringFromPoint( curPt);
			
			[points replaceObjectAtIndex: curIndex withObject: ptString];
			[points sortUsingSelector:@selector(compare:)];
			curIndex = [points indexOfObject:ptString];
			
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
		NSPoint  curPt = NSPointFromString( [points objectAtIndex: i]);
		
		curPt.x -=1000;
		
		if( center.x/2 >= curPt.x-2 && center.x/2 <= curPt.x+2) // We found a point!
		{
			found = YES;
			curIndex = i;
			
			break;
		}
	}
	
	if( found == NO)
	{
		NSPoint		newPt = NSMakePoint( center.x/2., center.y/100.);
		NSString	*newPtString;
		
		if( newPt.x < 0) newPt.x = 0;
		if( newPt.x > 256) newPt.x = 256;		
		if( newPt.y < 0) newPt.y = 0;
		if( newPt.y > 1.0) newPt.y = 1.0;
		newPt.x += 1000;
		
		newPtString = NSStringFromPoint( newPt);
		
		[points addObject:newPtString];
		[points sortUsingSelector:@selector(compare:)];
		curIndex = [points indexOfObject:newPtString];
	}
	
	[position setIntValue: center.x/2];
	
    [self setNeedsDisplay:YES];
}

-(NSMutableArray*) getPoints
{
	return points;
}

- (IBAction) renderButton:(id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"OpacityChanged" object: self userInfo: 0L];
}

- (void) setCurrentCLUT :( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long i;
	
	for( i = 0; i < 256; i++)
	{
		red[ i] = r[i];
		green[ i] = g[i];
		blue[ i] = b[i];
	}
}

- (void) drawRect:(NSRect)rect
{
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);   // Equiv to [[NSBezierPath bezierPathWithRect:[self bounds]] fill]

	long		i, x, cur, last = 0;
	NSRect		crect;
	NSPoint		curPoint;
	
	NSBezierPath *courbe = [NSBezierPath bezierPath];
	
	
	for( i = 0; i < 256; i++)
	{
		crect = NSMakeRect( i*2, 100, 2, 10);
		[[NSColor colorWithCalibratedRed:red[i]/255. green:green[i]/255. blue:blue[i]/255. alpha:1.0] set];
		NSRectFill( crect);
	}
	
	[courbe moveToPoint: NSMakePoint(0, 0)];
	
	NSLog(@"Points : %d", [points count]);
	
	for( i = 0; i < [points count]; i++)
	{
		curPoint = NSPointFromString([points objectAtIndex: i]);
		
		curPoint.x -= 1000;
		curPoint.x *= 2.;
		curPoint.y *= 100.;
		
		if( i == 0)
		{
			if( curPoint.x == 0)
			{
				[courbe moveToPoint: curPoint];
			//	NSLog(@"zero point");
			}
			else [courbe moveToPoint: NSMakePoint(0, 0)];
		}
		
		[courbe lineToPoint: curPoint];
		
		crect = NSMakeRect( curPoint.x-3, curPoint.y-3, 6, 6);
		[[NSColor redColor] set];
		NSRectFill( crect);
	}
	
	if( curPoint.x != 512 || [points count] == 0) [courbe lineToPoint:NSMakePoint( 512, 100)];
//	else NSLog(@"end point");
	
	[[NSColor blackColor] set];
	[courbe setLineWidth: 2];
	[courbe stroke];
	
    [[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];
}
@end
