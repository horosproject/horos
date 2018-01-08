/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/


#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>
#import "VRController.h"
#import "VRView.h"


@interface CLUTOpacityView : NSView
{
	NSColor *backgroundColor, *histogramColor, *pointsColor, *pointsBorderColor, *curveColor, *selectedPointColor, *textLabelColor;
	float histogramOpacity;
	float *volumePointer;
	int voxelCount;
	int protectionAgainstReentry;
	vImagePixelCount *histogram;
	int histogramSize;
	float HUmin, HUmax; // houndsfield units bounds
	NSPoint selectedPoint;
	int selectedCurveIndex;
	int pointDiameter, lineWidth, pointBorder;
	
	NSMutableArray *curves, *pointColors;
	
	NSMenu *contextualMenu;
	
	NSUndoManager *undoManager;
	BOOL nothingChanged;
	BOOL clutChanged;
	
	float zoomFactor;
	float zoomFixedPoint;
	
	IBOutlet NSWindow *chooseNameAndSaveWindow;
	IBOutlet NSTextField *clutSavedName;
	
    NSWindow *vrViewWindow;
	IBOutlet VRView *vrView;
	BOOL vrViewLowResolution;
	BOOL didResizeVRVIew;
	
	float mousePositionX;
	
	NSRect drawingRect, sideBarRect;
	NSRect addCurveButtonRect, removeSelectedCurveButtonRect, saveButtonRect, closeButtonRect;
	BOOL isAddCurveButtonHighlighted, isRemoveSelectedCurveButtonHighlighted, isSaveButtonHighlighted, isCloseButtonHighlighted;
	
	NSPoint mouseDraggingStartPoint;
	BOOL updateView, setCLUTtoVRView, windowWillClose;
}

- (void)cleanup;
- (void)createContextualMenu;

#pragma mark -
#pragma mark Histogram
- (void)setVolumePointer:(float*)ptr width:(int)width height:(int)height numberOfSlices:(int)n;
- (void)setHUmin:(float)min HUmax:(float)max;
- (void)computeHistogram;
- (void)callComputeHistogram;
- (void)drawHistogramInRect:(NSRect)rect;

#pragma mark -
#pragma mark Curves
- (void)newCurve;
- (void)fillCurvesInRect:(NSRect)rect;
- (void)drawCurvesInRect:(NSRect)rect;
- (void)addCurveAtindex:(int)curveIndex withPoints:(NSArray*)pointsArray colors:(NSArray*)colorsArray;
- (void)deleteCurveAtIndex:(int)i;
- (void)sendToBackCurveAtIndex:(int)i;
- (void)sendToFrontCurveAtIndex:(int)i;
- (int)selectedCurveIndex;
- (void)selectCurveAtIndex:(int)i;
- (void)setColor:(NSColor*)color forCurveAtIndex:(int)curveIndex;
- (void)setColors:(NSArray*)colors forCurveAtIndex:(int)curveIndex;

- (void)setCurves:(NSMutableArray*)newCurves;
- (void)setPointColors:(NSMutableArray*)newPointColors;

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
- (void)setColor:(NSColor*)color forPointAtIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex;
- (NSPoint)legalizePoint:(NSPoint)point inCurve:(NSArray*)aCurve atIndex:(int)j;
- (void)drawPointLabelAtPosition:(NSPoint)pt;
- (void)addPoint:(NSPoint)point atIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex withColor:(NSColor *)color;
- (void)removePointAtIndex:(int)ip inCurveAtIndex:(int)ic;
- (void)replacePointAtIndex:(int)ip inCurveAtIndex:(int)ic withPoint:(NSPoint)point;

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
- (IBAction)setZoomFator:(id)sender;
- (IBAction)scroll:(id)sender;
- (IBAction)removeAllCurves:(id)sender;
- (void)addCurveIfNeeded;
#pragma mark Custom GUI
- (void)drawSideBar:(NSRect)rect;
- (void)drawAddCurveButton:(NSRect)rect;
- (void)drawCloseButton:(NSRect)rect;
- (void)drawRemoveSelectedCurveButton:(NSRect)rect;
- (void)drawSaveButton:(NSRect)rect;
- (BOOL)clickInSideBarAtPosition:(NSPoint)position;
- (BOOL)clickInAddCurveButtonAtPosition:(NSPoint)position;
- (BOOL)clickInRemoveSelectedCurveButtonAtPosition:(NSPoint)position;
- (BOOL)clickInSaveButtonAtPosition:(NSPoint)position;
- (BOOL)clickInCloseButtonAtPosition:(NSPoint)position;
- (void)simplifyHistogram;

#pragma mark -
#pragma mark Copy / Paste
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;

#pragma mark -
#pragma mark Saving (as plist)
- (void)chooseNameAndSave:(id)sender;
- (IBAction)save:(id)sender;
- (void)saveWithName:(NSString*)name;
+ (NSDictionary*)presetFromFileWithName:(NSString*)name;
- (void)loadFromFileWithName:(NSString*)name;
#pragma mark conversion to plist-compatible types
- (NSArray*)convertPointColorsForPlist;
- (NSArray*)convertCurvesForPlist;
- (NSDictionary*)convertColorToDict:(NSColor*)color;
- (NSDictionary*)convertPointToDict:(NSPoint)point;
#pragma mark conversion from plist
+ (NSMutableArray*)convertPointColorsFromPlist:(NSArray*)plistPointColor;
+ (NSMutableArray*)convertCurvesFromPlist:(NSArray*)plistCurves;

#pragma mark -
#pragma mark Connection to VRView
- (void)setCLUTtoVRView;
- (void)setCLUTtoVRView:(BOOL)lowRes;
- (void)setWL:(float)wl ww:(float)ww;

#pragma mark -
#pragma mark Cursor
- (void)setCursorLabelWithText:(NSString*)text;

@end
