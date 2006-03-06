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


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "DCMView.h";
#import "DCMPix.h"
#include <math.h>
@class MSRGSegmentation;
@class ViewerController;
@class ROI;
@interface MSRGWindowController : NSWindowController
{

    IBOutlet NSButton *ActivateBoundingBoxButton;
    IBOutlet NSButton *AddMarkerFrameButton;
    IBOutlet NSSlider *SliderThickness;
    IBOutlet NSButton *StartButton;
	IBOutlet NSMatrix *RadioMatrix;
	IBOutlet NSTextField *startEndText;
	

	MSRGSegmentation *msrgSeg;
	ViewerController *viewer;
	ROI* BoundingROIStart;
	ROI* BoundingROIEnd;
	
}
- (IBAction)startMSRG:(id)sender;
- (IBAction)frameThicknessChange:(id)sender;
- (IBAction)activateBoundingBox:(id)sender;
- (IBAction)CreateDeleteMarkers:(id)sender;

- (id) initWithMarkerViewer:(ViewerController*) v andViewersList:(NSMutableArray*)list ;
-(BOOL)checkBoundingBoxROIPresentOnCurrentSlice;
-(void)createMarkerROIWithWidth:(int)w andHeight:(int)h atPosX:(int)x andY:(int)y;
-(void) cleanStackFromMarkerFrame;
@end
