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




#import <Cocoa/Cocoa.h>

@class ROI;
@class ViewerController;

@interface CurvedMPR : NSObject {

    NSMutableArray			*pixList;
	NSArray					*fileList;
	NSData					*volumeData;
	ROI						*selectedROI;
	short					curMovieIndex, maxMovieIndex;
	long					thickSlab;
	ViewerController		*viewerController, *roiViewer;
	
	NSMutableArray			*newDcmList, *newPixList;
	NSMutableArray			*newDcmListPer, *newPixListPer;
	
	long					perSize, perInterval;

	BOOL					firstTime, perPendicular;
}

- (ROI*) roi;
- (void) compute;
- (void) recompute;
- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t;
- (id) initWithObjectsPer:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) i :(long) s;
@end
