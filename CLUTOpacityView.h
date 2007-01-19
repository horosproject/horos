//
//  CLUTOpacityView.h
//  OsiriX
//
//  Created by joris on 15/01/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>

@interface CLUTOpacityView : NSView {
	NSColor *backgroundColor, *histogramColor, *pointsColor, *pointsBorderColor, *curveColor, *selectedPointColor;
	float histogramOpacity;
	float *volumePointer;
	int voxelCount;
	vImagePixelCount *histogram;
	int histogramSize;
	float HUmin, HUmax; // houndsfield units bounds
	NSPoint selectedPoint;
	int pointDiameter, lineWidth;
	
	NSColorPanel *colorPanel;
	
	NSMutableArray *curves, *pointColors;
}

#pragma mark -
#pragma mark Histogram
- (void)setVolumePointer:(float*)ptr width:(int)width height:(int)height numberOfSlices:(int)n;
- (void)setHUmin:(float)min HUmax:(float)max;
- (void)computeHistogram;
- (void)drawHistogramInRect:(NSRect)rect;

#pragma mark -
#pragma mark Curves
- (void)newCurve;
- (void)fillCurvesInRect:(NSRect)rect;
- (void)drawCurvesInRect:(NSRect)rect;
- (void)removePointAtIndex:(int)ip inCurveAtIndex:(int)ic;
- (void)sendToBackCurveAtIndex:(int)i;
- (void)sendToFrontCurveAtIndex:(int)i;
- (int)selectedCurveIndex;
- (void)selectCurveAtIndex:(int)i;

#pragma mark -
#pragma mark Coordinate to NSView Transform
- (NSAffineTransform*)transform;

#pragma mark -
#pragma mark Global draw method
- (void)updateView;

#pragma mark -
#pragma mark Points selection
- (BOOL)selectPointAtPosition:(NSPoint)position;
- (void)unselectPoints;
- (BOOL)isAnyPointSelected;
- (void)changePointColor:(NSNotification *)notification;
- (NSPoint)legalizePoint:(NSPoint)point inCurve:(NSArray*)aCurve atIndex:(int)j;
- (void)drawPointLabelAtPosition:(NSPoint)pt;

#pragma mark -
#pragma mark Control Point
- (NSPoint)controlPointForCurveAtIndex:(int)i;
- (BOOL)selectControlPointAtPosition:(NSPoint)position;

#pragma mark -
#pragma mark Lines selection
- (BOOL)clickOnLineAtPosition:(NSPoint)position;

#pragma mark -
#pragma mark GUI
- (IBAction)computeHistogram:(id)sender;
- (IBAction)setHistogramOpacity:(id)sender;
- (IBAction)newCurve:(id)sender;
- (IBAction)setLineWidth:(id)sender;
- (IBAction)setPointDiameter:(id)sender;
- (void)niceDisplay;
- (IBAction)niceDisplay:(id)sender;
- (IBAction)sendToBack:(id)sender;

#pragma mark -
#pragma mark Copy / Paste
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;

@end
