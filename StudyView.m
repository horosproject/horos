/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "StudyView.h"
#import "SeriesView.h"


@implementation StudyView

- (id)initWithFrame:(NSRect)frame {
	return [self initWithFrame:frame seriesRows:1  seriesColumns:1];


}

- (id)initWithFrame:(NSRect)frame seriesRows:(int)rows  seriesColumns:(int)columns{
	 self = [super initWithFrame:frame];
	 if (self) {
		NSLog(@"studyView alloc");
		seriesRows = rows;
		seriesColumns = columns;
		//tag = theTag;
		int i;
		int count = rows * columns;
		seriesViews = [[NSMutableArray array] retain];
		NSRect bounds = [self bounds];
		for (i = 0 ; i < count; i++) {
			float newWidth = bounds.size.width / seriesColumns;
			float newHeight = bounds.size.height / seriesRows;
			float newX = newWidth * (i / seriesColumns);
			float newY = newHeight * (i % seriesColumns);
			NSRect newFrame = NSMakeRect(newX, newY, newWidth, newHeight);
			//SeriesView *seriesView = [[[SeriesView alloc] initWithFrame:newFrame] autorelease];
			SeriesView *seriesView = [[[SeriesView alloc] initWithFrame:newFrame seriesRows:seriesRows  seriesColumns:seriesColumns] autorelease];
			[seriesViews addObject:seriesView];
			[seriesView setTag:i];
			[self addSubview:seriesView];
		}
		
		
    }
    return self;
}

- (void)dealloc{
	//NSLog(@"studyView dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[seriesViews release];
	[super dealloc];
}

/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/

- (void)drawRect:(NSRect)rect {
    NSDrawLightBezel(rect, rect);
}

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
