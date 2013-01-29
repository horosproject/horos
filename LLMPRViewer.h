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
#import "OrthogonalMPRViewer.h"
#import "LLMPRController.h"
#import "DCMView.h"
#import "LLScoutViewer.h"

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

@class LLDCMView;

@interface LLMPRViewer : OrthogonalMPRViewer <Schedulable, NSWindowDelegate, NSToolbarDelegate, NSSplitViewDelegate>
{
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
	IBOutlet NSSlider			*injectedMinValueSlider, *injectedMaxValueSlider, *notInjectedMinValueSlider, *notInjectedMaxValueSlider, *subtractionMinValueSlider, *subtractionMaxValueSlider, *dilatationRadiusSlider, *closingRadiusSlider, *lowPassFilterSizeSlider;
	int							injectedMinValue, injectedMaxValue, notInjectedMinValue, notInjectedMaxValue, subtractionMinValue, subtractionMaxValue;
	IBOutlet NSTextField		*xShiftTextField, *yShiftTextField, *zShiftTextField;
	IBOutlet NSTextField		*dilatationRadiusTextField, *closingRadiusTextField, *lowPassFilterSizeTextField;
	int							dilatationRadius, closingRadius, lowPassFilterSize;
	
	IBOutlet NSButton			*displayBonesButton;
	BOOL						displayBones;
	IBOutlet NSSlider			*bonesThresholdSlider;
	IBOutlet NSTextField		*bonesThresholdTextField;
	int							bonesThreshold;
	
	IBOutlet NSPopUpButton		*settingsPopup;
	NSString					*settingsName;
	IBOutlet NSWindow			*settingsNameSheetWindow;
	IBOutlet NSTextField		*settingsNameTextField;
	
	IBOutlet NSPopUpButton		*convolutionsPopup;
	BOOL						applyConvolution;
	float						convolutionKernel[25];
	NSString					*convolutionName;
}

- (id)initWithPixList:(NSArray*)pix :(NSArray*)pixToSubstract :(NSArray*)files :(NSData*)vData :(ViewerController*)vC :(ViewerController*)bC :(LLScoutViewer*)sV;
- (void)setPixListRange:(NSRange)range;
- (void)resliceFromNotification: (NSNotification*)notification;
- (void)changeWLWW:(NSNotification*)note;
- (void)_setThickSlabMode:(int)mode;
- (void)refreshSubtractedViews;
- (void)shiftSubtractionX:(int)deltaX y:(int)deltaY z:(int)deltaZ;
- (IBAction)resetShift:(id)sender;
- (void)resetShift;
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
//- (IBAction)defaultValuesParametersSliders:(id)sender;
//- (IBAction)saveParametersValuesAsDefault:(id)sender;
//- (void)setInitialDefaultParametersValues;
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

- (IBAction)setLowPassFilterSize:(id)sender;
- (IBAction)applyConvolutionFilter:(id)sender;
- (void)applyConvolutionWithName:(NSString*)name;
- (void)buildConvolutionsMenu;

- (void)initialDefaultSettings;
- (void)addCurrentSettings:(id)sender;
- (IBAction)cancelAddSettings:(id)sender;
- (IBAction)saveSettings:(id)sender;
- (void)saveSettingsAs:(NSString*)title;
- (IBAction)removeCurrentSettings:(id)sender;
- (void)removeSettingsWithTitle:(NSString*)title;
- (NSDictionary*)settingsForTitle:(NSString*)title;
- (void)applySettingsForTitle:(NSString*)title;
- (IBAction)applySettings:(id)sender;
- (void)buildSettingsMenu;

@end
