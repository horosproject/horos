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

/** \brief Series View for ViewerControllerr */


#import <Cocoa/Cocoa.h>

@class DCMView;
@class DCMPix;
@class ViewerController;
@interface SeriesView : NSView {
	int seriesRows;
	int seriesColumns;
	int tag;
	int imageRows;
	int imageColumns;
	NSMutableArray *imageViews;
	
	NSMutableArray  *dcmPixList;
    NSArray			*dcmFilesList;
	NSMutableArray  *dcmRoiList, *curRoiList;
	char            listType;    
    short           curImage, startImage;
	
	NSTimeInterval			lastTime, lastTimeFrame;
	NSTimeInterval			lastMovieTime;
	//int curMovieIndex;
	//int maxMovieIndex;

}

- (id)initWithFrame:(NSRect)frame seriesRows:(int)rows  seriesColumns:(int)columns;

- (NSInteger)tag;
- (void)setTag:(NSInteger)theTag;
- (NSMutableArray *)imageViews;
- (DCMView *)firstView;
- (void)setImageViewMatrixForRows:(int)rows  columns:(int)columns;
- (void)setImageViewMatrixForRows:(int)rows  columns:(int)columns rescale: (BOOL) rescale;
- (void)updateImageTiling:(NSNotification *)note;
- (void) setDCM:(NSMutableArray*) c :(NSArray*)d :(NSMutableArray*)e :(short) firstImage :(char) type :(BOOL) reset;
- (void) setPixels: (NSMutableArray*) pixels files: (NSArray*) files rois: (NSMutableArray*) rois firstImage: (short) firstImage level: (char) level reset: (BOOL) reset;
- (void) setBlendingFactor:(float) value;
- (void) setBlendingMode:(int) value;
- (void) setFlippedData:(BOOL) value;
- (void) ActivateBlending:(ViewerController*) bC blendingFactor:(float)blendingFactor;
- (int)imageRows;
- (int)imageColumns;
- (void) selectFirstTilingView;

@end
