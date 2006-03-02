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




#import <AppKit/AppKit.h>

@class ROI;

@interface PlotView : NSView
{
			float					*dataArray;
			long					dataSize;
			long					curMousePosition;
			ROI						*curROI;
}
- (void)setData:(float*)array :(long) size;
- (void)setCurROI: (ROI*) r;
@end
