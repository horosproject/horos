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

#import "LLDCMView.h"
#import "ROI.h"

@implementation LLDCMView

- (void) keyDown:(NSEvent *)event
{
	[super keyDown:event];
	[self blendingPropagate];
}


- (IBAction)scaleToFit:(id)sender
{
	[super scaleToFit: sender];
	[self blendingPropagate];
}

- (IBAction)actualSize:(id)sender
{
	[super actualSize: sender];
	[self blendingPropagate];
}

- (void)mouseDragged:(NSEvent *)event
{
	[super mouseDragged: event];
	[self blendingPropagate];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	float reverseScrollWheel;
	
	if( curImage < 0) return;
	if( !drawing) return;
	if( [[self window] isVisible] == NO) return;
	if( [self is2DViewer] == YES)
	{
		if( [[self windowController] windowWillClose]) return;
	}
	
	if( isKeyView == NO)
		[[self window] makeFirstResponder: self];
	
	BOOL SelectWindowScrollWheel = [[NSUserDefaults standardUserDefaults] boolForKey: @"SelectWindowScrollWheel"];
	
	if( [theEvent modifierFlags] & NSAlphaShiftKeyMask) // Caps Lock
		SelectWindowScrollWheel = !SelectWindowScrollWheel;
	
	if( SelectWindowScrollWheel)
	{
		if( [[self window] isMainWindow] == NO)
			[[self window] makeKeyAndOrderFront: self];
	}
	
	float deltaX = [theEvent deltaX];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ZoomWithHorizonScroll"] == NO) deltaX = 0;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Scroll Wheel Reversed"])
		reverseScrollWheel = -1.0;
	else
		reverseScrollWheel = 1.0;
	
	if( flippedData) reverseScrollWheel *= -1.0;
	
    if( dcmPixList)
	{
        short inc;
        
		[[self controller] saveCrossPositions];
		float change;
		
		if( fabs( [theEvent deltaY]) > fabs( deltaX) && [theEvent deltaY] != 0)
		{
			
			if( [theEvent modifierFlags]  & NSCommandKeyMask)
			{
				if( blendingView)
				{
					float change = [theEvent deltaY] / -0.2f;
					blendingFactor += change;
					
					[self setBlendingFactor: blendingFactor];
				}
			}
			else if( [theEvent modifierFlags]  & NSAlternateKeyMask)
			{
				// 4D Direction scroll - Cardiac CT eg	
				float change = [theEvent deltaY] / -2.5f;
				
				if( change > 0)
				{
					change = ceil( change);
					if( change < 1) change = 1;
					
					change += [[self windowController] curMovieIndex];
					while( change >= [[self windowController] maxMovieIndex]) change -= [[self windowController] maxMovieIndex];
				}
				else
				{
					change = floor( change);
					if( change > -1) change = -1;
					
					change += [[self windowController] curMovieIndex];
					while( change < 0) change += [[self windowController] maxMovieIndex];
				}
				
				[[self windowController] setMovieIndex: change];
			}
			else
			{
				change = reverseScrollWheel * [theEvent deltaY];
				if( change > 0)
				{
					change = ceil( change);
					if( change < 1) change = 1;
				}
				else
				{
					change = floor( change);
					if( change > -1) change = -1;		
				}
				
				if ( [self isKindOfClass: [OrthogonalMPRView class]] )
				{
					[(OrthogonalMPRView*)self scrollTool: 0 : (long)change];
				}
			}
		}
		else if( deltaX != 0)
		{
			change = reverseScrollWheel * deltaX;
			if( change >= 0)
			{
				change = ceil( change);
				if( change < 1) change = 1;
			}
			else
			{
				change = floor( change);
				if( change > -1) change = -1;		
			}
			
			if ( [self isKindOfClass: [OrthogonalMPRView class]] )
			{
				[(OrthogonalMPRView*)self scrollTool: 0 : (long)change];
			}
		}
		
		[self mouseMoved: [[NSApplication sharedApplication] currentEvent]];
	}
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	return self;
}

- (void) blendingPropagate
{
	[viewer blendingPropagate:self];
}

- (void) setIndexWithReset:(short) index :(BOOL) sizeToFit
{
	if( dcmPixList && index != -1)
    {
		[[self window] setAcceptsMouseMovedEvents: YES];

		curROI = nil;
		
		origin.x = origin.y = 0;
		curImage = index; 
		if( curImage >= [dcmPixList count]) curImage = (long)[dcmPixList count] -1;
		curDCM = [dcmPixList objectAtIndex: curImage];
		
		[curRoiList release];
		
		if( dcmRoiList) curRoiList = [[dcmRoiList objectAtIndex: curImage] retain];
		else
		{
			curRoiList = [[NSMutableArray alloc] initWithCapacity:0];
		}
		
		for( id loopItem in curRoiList)
		{
			[loopItem setRoiView :self];
			[loopItem recompute];
			// Unselect previous ROIs
			[loopItem setROIMode : ROI_sleep];
		}
		
		curWW = [curDCM ww];
		curWL = [curDCM wl];
		
		rotation = 0;
		
		//get Presentation State info from series Object
		[self updatePresentationStateFromSeries];
		
		[curDCM checkImageAvailble :curWW :curWL];
		
//		NSSize  sizeView = [[self enclosingScrollView] contentSize];
//		[self setFrameSize:sizeView];
		
		if( sizeToFit || [[[self window] windowController] is2DViewer] == NO) {
			[self scaleToFit];
		}
		
		if( [[[self window] windowController] is2DViewer] == YES)
		{
			if( [curDCM sourceFile])
			{
				if( [[[self window] windowController] is2DViewer] == YES) [[self window] setRepresentedFilename: [curDCM sourceFile]];
			}
		}
		
		[self loadTextures];
		[self setNeedsDisplay:YES];
		
		[yearOld release];
		yearOld = [[[dcmFilesList objectAtIndex: curImage] valueForKeyPath:@"series.study.yearOld"] retain];
	}
}

@end
