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
