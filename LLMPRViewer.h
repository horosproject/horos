//
//  LLMPRViewer.h
//  OsiriX
//
//  Created by Joris Heuberger on 08/05/06.
//  Copyright 2006 HUG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OrthogonalMPRViewer.h"
#import "LLMPRController.h"
#import "DCMView.h"
#import "LLScoutViewer.h"

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

@class LLDCMView;

@interface LLMPRViewer : OrthogonalMPRViewer <Schedulable> {
	IBOutlet LLMPRController	*injectedMPRController;
	IBOutlet LLDCMView			*subtractedOriginalView, *subtractedXReslicedView, *subtractedYReslicedView;
	float						*subtractedOriginalBuffer, *subtractedXReslicedBuffer, *subtractedYReslicedBuffer;
	int							xShift, yShift, zShift;
	ViewerController			*notInjectedViewer;
	short						thickSlabMode, thickSlab;
	NSRange						pixListRange;
	LLScoutViewer				*scoutViewer;
	IBOutlet NSPopUpButton		*thickSlabModePopUp;
	IBOutlet NSPanel			*parametersPanel;
	IBOutlet NSTextField		*injectedMinValueTextField, *injectedMaxValueTextField, *notInjectedMinValueTextField, *notInjectedMaxValueTextField, *subtractionMinValueTextField, *subtractionMaxValueTextField;
	IBOutlet NSSlider			*injectedMinValueSlider, *injectedMaxValueSlider, *notInjectedMinValueSlider, *notInjectedMaxValueSlider, *subtractionMinValueSlider, *subtractionMaxValueSlider;
	int							injectedMinValue, injectedMaxValue, notInjectedMinValue, notInjectedMaxValue, subtractionMinValue, subtractionMaxValue;
	IBOutlet NSTextField		*xShiftTextField, *yShiftTextField, *zShiftTextField;
	IBOutlet NSTextField		*dilatationRadiusTextField, *closingRadiusTextField;
	int							dilatationRadius, closingRadius;
	IBOutlet NSButton			*displayBonesButton;
	BOOL						displayBones;
	IBOutlet NSSlider			*bonesThresholdSlider;
	IBOutlet NSTextField		*bonesThresholdTextField;
	int							bonesThreshold;
}

- (id)initWithPixList:(NSMutableArray*)pix:(NSMutableArray*)pixToSubstract:(NSArray*)files:(NSData*)vData:(ViewerController*)vC:(ViewerController*)bC:(LLScoutViewer*)sV;
- (void)setPixListRange:(NSRange)range;
- (void)resliceFromNotification: (NSNotification*)notification;
- (void)changeWLWW:(NSNotification*)note;
- (void)_setThickSlabMode:(int)mode;
- (void)refreshSubtractedViews;
- (void)shiftSubtractionX:(int)deltaX y:(int)deltaY z:(int)deltaZ;
- (void)applyShiftX:(int)x y:(int)y toBuffer:(float*)buffer withWidth:(int)width height:(int)height;
- (void)removeBonesAtX:(int)x y:(int)y z:(int)z;
- (void)resampleBuffer:(float*)buffer withWidth:(int)width height:(int)height factor:(float)factor inNewBuffer:(float*)newBuffer;
- (void)produceResultData:(NSMutableData**)volumeData pixList:(NSMutableArray*)pix;
- (void)produceResultInMemory:(id)sender;
- (void)produce3DResult:(id)sender;

- (void)blendingPropagate:(LLDCMView*)sender;

- (void)showParametersPanel:(id)sender;
- (IBAction)setParameterValue:(id)sender;
- (IBAction)resetParametersSliders:(id)sender;
- (IBAction)defaultValuesParametersSliders:(id)sender;
- (int)injectedMinValue;
- (int)injectedMaxValue;
- (int)notInjectedMinValue;
- (int)notInjectedMaxValue;
- (int)subtractionMinValue;
- (int)subtractionMaxValue;
- (void)setInjectedMinValue:(int)v;
- (void)setInjectedMaxValue:(int)v;
- (void)setNotInjectedMinValue:(int)v;
- (void)setNotInjectedMaxValue:(int)v;
- (void)setSubtractionMinValue:(int)v;
- (void)setSubtractionMaxValue:(int)v;

- (IBAction)toggleDisplayBones:(id)sender;
- (IBAction)setBonesThreshold:(id)sender;

- (IBAction)setDilatationRadius:(id)sender;
- (IBAction)setClosingRadius:(id)sender;

@end
