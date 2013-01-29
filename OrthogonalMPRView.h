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

#import "OrthogonalMPRController.h"

#import "DCMView.h"

//@class OrthogonalMPRController;

/** \brief View for MPRs
*
* This view displays a cross to show where the 2 orthogonal plane are crossing 
*/

@interface OrthogonalMPRView : DCMView {
	float						crossPositionX, crossPositionY; // coordinate x and Y of the cross
	OrthogonalMPRController		*controller;
	long						displayResliceAxes;
	float						savedScaleValue;
	
	long						thickSlabX, thickSlabY;
	NSString					*curWLWWMenu;
	NSString					*curCLUTMenu;
	NSString					*curOpacityMenu;
}

- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files;
- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files :(NSMutableArray*) rois;
- (NSMutableArray*) pixList;
- (void) setController: (OrthogonalMPRController*) newController;
- (OrthogonalMPRController*) controller;

- (void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) location ;
- (void) getCrossPositionDICOMCoords: (float*) location ;
- (void) setCrossPosition: (float) x : (float) y withNotification:(BOOL) doNotifychange;
- (void) setCrossPosition: (float) x : (float) y;
- (void) setCrossPositionX: (float) x;
- (void) setCrossPositionY: (float) y;
- (float) crossPositionX;
- (float) crossPositionY;

- (void) adjustWLWW:(float) wl :(float) ww;

- (void) subDrawRect: (NSRect) aRect;

- (void) toggleDisplayResliceAxes;

- (void) saveScaleValue;
- (void) restoreScaleValue;
- (void) adjustScaleValue:(float) x;
- (void) displayResliceAxes: (long) boo;
- (void) setThickSlabXY : (long) newThickSlabX : (long) newThickSlabY;
- (void) scrollTool: (long) from : (long) to;

- (void) setCurWLWWMenu:(NSString*) str;
- (NSString*) curWLWWMenu;

- (NSString*) curCLUTMenu;
- (void) setCurCLUTMenu: (NSString*) clut;

- (NSString*) curOpacityMenu;
- (void) setCurOpacityMenu: (NSString*) o;

- (void) setCurRoiList: (NSMutableArray*) rois;

@end