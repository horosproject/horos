/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/




#import "OpacityTransferView.h"
#import "AppKit/NSColor.h"
#import "Notifications.h"

@implementation OpacityTransferView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		long i;
		
        curIndex = -1;
		points =  [[NSMutableArray array] retain];
		
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

+ (NSData*) tableWith4096Entries: (NSArray*) pointsArray
{
	int		x, cur, last = 0;
	float	entries256[ 4097];
	NSPoint prevPoint = NSMakePoint( 1000, 0.0);
	
	for( id loopItem1 in pointsArray)
	{
		NSPoint curPoint = NSPointFromString( loopItem1);
		
		curPoint.x -= 1000;
		
		cur = curPoint.x;
		
		cur *= 16;
		
		for( x = 0; x < cur-last; x++)
		{
			entries256[ last + x] = (prevPoint.y + ((curPoint.y - prevPoint.y) * x / (cur-last)));
		}
		
		prevPoint = curPoint;
		last = cur;
	}
	
	cur = 4096;
	NSPoint curPoint = NSMakePoint( 1256, 1.0);
	for( x = 0; x < cur-last; x++)
	{
		entries256[ last + x] = (prevPoint.y + ((curPoint.y - prevPoint.y) * x / (cur-last)));
	}
	
	return [NSData dataWithBytes: entries256 length: 4096 * sizeof(float)];
}

+ (NSData*) tableWith256Entries: (NSArray*) pointsArray
{
	int		x, cur, last = 0;
	float	entries256[ 256];
	NSPoint prevPoint = NSMakePoint( 1000, 0.0);
	
    for( NSString *loopItem in pointsArray)
    {
        NSPoint curPoint = NSPointFromString( loopItem);
        
        curPoint.x -= 1000;
        
        cur = curPoint.x;
        
        for( x = 0; x < cur-last; x++)
        {
            entries256[ last + x] = (prevPoint.y + ((curPoint.y - prevPoint.y) * x / (cur-last)));
        }
        
        prevPoint = curPoint;
        last = cur;
    }
	
	for( x = 0; x < 256-last; x++)
	{
		entries256[ last + x] = 1.0;
	}
	
//	for( i = 0 ; i < 256; i++)
//	{
//		NSLog( @"%d : %f", i, entries256[ i]);
//	}
	
	return [NSData dataWithBytes: entries256 length: 256 * sizeof(float)];
}

- (IBAction) renderButton:(id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixOpacityChangedNotification object: self userInfo: nil];
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

	long		i;
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
