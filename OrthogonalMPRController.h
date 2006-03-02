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
#import "ViewerController.h"
#import "OrthogonalReslice.h"
#import "OrthogonalMPRView.h"
//@class OrthogonalMPRViewer;

@interface OrthogonalMPRController : NSObject { //NSWindowController {
	NSMutableArray				*originalDCMPixList, *xReslicedDCMPixList, *yReslicedDCMPixList, *originalDCMFilesList;
	OrthogonalReslice			*reslicer;
	float						sign;
	
	long						originalCrossPositionX, originalCrossPositionY, xReslicedCrossPositionX, xReslicedCrossPositionY, yReslicedCrossPositionX, yReslicedCrossPositionY;
	
	IBOutlet OrthogonalMPRView	*originalView, *xReslicedView, *yReslicedView;

	id							viewer;
	NSRect						originalViewFrame, xReslicedViewFrame, yReslicedViewFrame;
	
	short						thickSlabMode, thickSlab;
}

- (id) initWithPixList: (NSMutableArray*) pixList :(NSArray*) filesList :(NSData*) vData :(ViewerController*) bC:(id) newViewer;

- (void) reslice: (long) x: (long) y: (OrthogonalMPRView*) sender;
- (void) flipVolume;

- (void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) iwl :(float) iww;

-(short) thickSlabMode;
-(void) setThickSlabMode : (short) newThickSlabMode;
-(short) thickSlab;
-(long) maxThickSlab;
-(float) thickSlabDistance;
-(void) setThickSlab : (short) newThickSlab;

- (void) showViews:(id)sender;

// accessors
- (OrthogonalMPRView*) originalView;
- (OrthogonalMPRView*) xReslicedView;
- (OrthogonalMPRView*) yReslicedView;
- (NSMutableArray*) originalDCMFilesList;
- (id) viewer;
- (float) sign;

// Tools Selection
- (void) setCurrentTool:(short) newTool;

- (void) saveViewsFrame;
- (void) saveScaleValue;
- (void) displayResliceAxes: (long) boo;
- (void) restoreScaleValue;
- (void) restoreViewsFrame;
- (void) toggleDisplayResliceAxes: (id) sender;
- (void) resetImage;

- (NSMutableArray*) originalDCMPixList;
- (void) scaleToFit : (id) destination;
- (void) scaleToFit;
- (void) setScaleValue:(float) x;
- (void) fullWindowView: (id) sender;
- (void) saveCrossPositions;
- (void) restoreCrossPositions;
- (void) scrollTool: (long) from : (long) to : (id) sender;
- (void) doubleClick:(NSEvent *)event:(id) sender;

- (void) blendingPropagateOriginal:(OrthogonalMPRView*) sender;
- (void) blendingPropagateX:(OrthogonalMPRView*) sender;
- (void) blendingPropagateY:(OrthogonalMPRView*) sender;
- (void) blendingPropagate:(OrthogonalMPRView*) sender;

@end
