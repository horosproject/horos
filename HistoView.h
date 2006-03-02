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

@interface HistoView : NSView
{
        float					*dataArray;
		long					dataSize, bin, curMousePosition, pixels, minV, maxV;
        float					maxValue;
		ROI						*curROI;
}
- (void)setData:(float*)array :(long) size :(long) b;
- (void)setMaxValue:(float)value :(long) pixels;
- (void)setCurROI: (ROI*) r;
- (void)setRange:(long) mi :(long) max;
@end
