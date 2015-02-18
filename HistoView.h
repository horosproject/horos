/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/




#import <AppKit/AppKit.h>

@class ROI;

/** \brief  View for histogram display */

@interface HistoView : NSView
{
        float					*dataArray;
		long					dataSize, bin, curMousePosition, pixels, minV, maxV;
        float					maxValue;
		ROI						*curROI;
		NSColor					*backgroundColor, *binColor, *selectedBinColor, *textColor, *borderColor;
}
- (void)setData:(float*)array :(long) size :(long) b;
- (void)setMaxValue:(float)value :(long) pixels;
- (void)setCurROI: (ROI*) r;
- (void)setRange:(long) mi :(long) max;

- (NSColor*)backgroundColor;
- (NSColor*)binColor;
- (NSColor*)selectedBinColor;
- (NSColor*)textColor;
- (NSColor*)borderColor;

- (void)setBackgroundColor:(NSColor*)aColor;
- (void)setBinColor:(NSColor*)aColor;
- (void)setSelectedBinColor:(NSColor*)aColor;
- (void)setTextColor:(NSColor*)aColor;
- (void)setBorderColor:(NSColor*)aColor;

@end
