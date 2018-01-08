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




#import "StudyView.h"
#import "SeriesView.h"


@implementation StudyView

- (id)initWithFrame:(NSRect)frame {
	return [self initWithFrame:frame seriesRows:1  seriesColumns:1];


}

- (id)initWithFrame:(NSRect)frame seriesRows:(int)rows  seriesColumns:(int)columns
{
	 self = [super initWithFrame:frame];
	 if (self)
	 {
		seriesRows = rows;
		seriesColumns = columns;
		//tag = theTag;
		int i;
		int count = rows * columns;
		seriesViews = [[NSMutableArray array] retain];
		NSRect bounds = [self bounds];
		for (i = 0 ; i < count; i++)
		{
			float newWidth = bounds.size.width / seriesColumns;
			float newHeight = bounds.size.height / seriesRows;
			float newX = newWidth * (i / seriesColumns);
			float newY = newHeight * (i % seriesColumns);
			NSRect newFrame = NSMakeRect(newX, newY, newWidth, newHeight);
			SeriesView *seriesView = [[[SeriesView alloc] initWithFrame:newFrame seriesRows:seriesRows  seriesColumns:seriesColumns] autorelease];
			[seriesViews addObject:seriesView];
			[seriesView setTag:i];
			[self addSubview:seriesView];
		}
		
		
    }
    return self;
}

- (void)dealloc{
	NSLog(@"studyView dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[seriesViews release];
	[super dealloc];
}

//- (void)drawRect:(NSRect)rect {
//    NSDrawLightBezel(rect, rect);
//	NSColor *backgroundColor = [NSColor  colorWithCalibratedRed:1 green:0 blue:0 alpha:1];
//	[backgroundColor setFill];	
//	[NSBezierPath fillRect:rect];
//	[super drawRect:rect];
//}

- (BOOL)acceptsFirstResponder {
    return NO;
}
- (BOOL)isFlipped{
    return YES;
}

- (BOOL)autoresizesSubviews{
    return YES;
}

- (NSMutableArray *)seriesViews{
	return seriesViews;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize{
	[super resizeSubviewsWithOldSize:oldBoundsSize];
}

- (void)setSeriesViewMatrixForRows:(int)rows  columns:(int)columns{
}

@end
