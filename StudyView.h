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



#import <Cocoa/Cocoa.h>


@interface StudyView : NSView {
	int seriesRows;
	int seriesColumns;
	NSMutableArray *seriesViews;
}

- (id)initWithFrame:(NSRect)frame seriesRows:(int)rows  seriesColumns:(int)columns;
- (NSMutableArray *)seriesViews;
- (void)setSeriesViewMatrixForRows:(int)rows  columns:(int)columns;

@end
