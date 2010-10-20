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




#import <Cocoa/Cocoa.h>

@class ROI;
@class ViewerController;


/** \brief  Curved MPR */
@interface CurvedMPR : NSObject {

    NSMutableArray			*pixList;
	NSMutableArray			*fileList;
	NSData					*volumeData;
	ROI						*selectedROI;
	short					curMovieIndex, maxMovieIndex;
	long					thickSlab;
	ViewerController		*viewerController, *roiViewer;
		
	long					perSize, perInterval;

	BOOL					firstTime, perPendicular;
}

- (ROI*) roi;
//- (void) compute;
- (void) computeForView:(short)view;
- (void) recompute;
- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t;
- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t forView:(short)view;
- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t forAxial:(BOOL)axial forCoronal:(BOOL)coronal forSagittal:(BOOL)sagittal;
- (id) initWithObjectsPer:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) i :(long) s;

@end
