/*=========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://www.osirix-viewer.com/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "DCMView.h";
#import "DCMPix.h"
#import "ROI.h"
#import "ViewerController.h"
#import "MSRGSegmentation.h"

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
	int begin,end;//for 3D ROI, FrameMarker ROI start at slice:begin to end 
	NSMutableArray* viewersList;
	
}
- (IBAction)startMSRG:(id)sender;
- (IBAction)frameThicknessChange:(id)sender;
- (IBAction)activateBoundingBox:(id)sender;
- (IBAction)CreateDeleteMarkers:(id)sender;
-(void)setThicknessParameters;
-(void)createFrameMarker;
- (id) initWithMarkerViewer:(ViewerController*) v andViewersList:(NSMutableArray*)list ;
-(BOOL)checkBoundingBoxROIPresentOnCurrentSlice;
-(BOOL)checkBoundingBoxROIPresentOnStack;
-(void)createMarkerROIAtSlice:(int)slice Width:(int)w Height:(int)h PosX:(int)x PosY:(int)y;
-(void) cleanStackFromMarkerFrame;
@end
