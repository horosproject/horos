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


#import "MatrixContextual.h"

@implementation MatrixContextual

- (void) rightMouseDown:(NSEvent *)theEvent
 {
	#if !__LP64__
	int row, column;
	#else
	long row, column;
	#endif
 
	if( [self getRow: &row column: &column forPoint: [self convertPoint:[theEvent locationInWindow] fromView:nil]])
	{
		if( [theEvent modifierFlags] & NSShiftKeyMask )
		{
			int start = [[self cells] indexOfObject: [[self selectedCells] objectAtIndex: 0]];
			int end = [[self cells] indexOfObject: [self cellAtRow:row column:column]];
			
			[self setSelectionFrom:start to:end anchor:start highlight: YES];
			
		}
		else if( [theEvent modifierFlags] & NSCommandKeyMask )
		{
			int start = [[self cells] indexOfObject: [[self selectedCells] objectAtIndex: 0]];
			int end = [[self cells] indexOfObject: [self cellAtRow:row column:column]];
			
			if( [[self selectedCells] containsObject:[self cellAtRow:row column:column]])
				[self setSelectionFrom:end to:end anchor:end highlight: NO];
			else
				[self setSelectionFrom:end to:end anchor:end highlight: YES];

		}
		else
		{
			if( [[self cellAtRow:row column:column] isHighlighted] == NO) [self selectCellAtRow: row column:column];
		}
	}
 
	[super rightMouseDown: theEvent];
 }
@end
