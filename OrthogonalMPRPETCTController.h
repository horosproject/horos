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
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRPETCTView.h"

@class OrthogonalMPRPETCTViewer;

@interface OrthogonalMPRPETCTController : OrthogonalMPRController {

	BOOL						isBlending;
}
- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC :(id) newViewer;

- (void) setCrossPosition: (long) x: (long) y: (id) sender;
- (void) resliceFromOriginal: (long) x: (long) y;
- (void) resliceFromX: (long) x: (long) y;
- (void) resliceFromY: (long) x: (long) y;

- (void) superSetWLWW:(float) iwl :(float) iww;

- (void) setBlendingMode:(long) f;
-(void) setBlendingFactor:(float) f;
- (void) stopBlending;
- (void) scaleToFit;

- (BOOL) containsView: (DCMView*) view;

- (void) fullWindowModality: (id) sender;
- (void) fullWindowPlan: (id) sender;
@end