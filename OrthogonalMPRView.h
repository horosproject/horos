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
#import "DCMView.h"

@class OrthogonalMPRController;

// this view displays a cross to show where the 2 orthogonal plane are crossing

@interface OrthogonalMPRView : DCMView {
	long						crossPositionX, crossPositionY; // coordinate x and Y of the cross
	OrthogonalMPRController		*controller;
	long						displayResliceAxes;
	float						savedScaleValue;
	
	long						thickSlabX, thickSlabY;
	NSString					*curWLWWMenu;
}

- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files;
//- (void) setPixList: (NSMutableArray*) pix;
- (NSMutableArray*) pixList;
- (void) setController: (OrthogonalMPRController*) newController;
- (OrthogonalMPRController*) controller;

- (void) setCrossPosition: (long) x: (long) y;
- (void) setCrossPositionX: (long) x;
- (void) setCrossPositionY: (long) y;
- (long) crossPositionX;
- (long) crossPositionY;

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

@end