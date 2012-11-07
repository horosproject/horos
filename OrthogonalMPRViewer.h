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
#import "ViewerController.h"
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"
#import "OrthogonalMPRController.h"
#import "Window3DController.h"

#import "KBPopUpToolbarItem.h"

@class DICOMExport;
@class KBPopUpToolbarItem;

/** \brief  Window Controller for Orthogonal MPR */

typedef enum {SyncSeriesStateOff=0,SyncSeriesStateDisable=1,SyncSeriesStateEnable=2} SyncSeriesState;
typedef enum {SyncSeriesScopeAllSeries=1,SyncSeriesScopeSamePatient=2,SyncSeriesScopeSameStudy=3} SyncSeriesScope;
typedef enum {SyncSeriesBehaviorAbsolutePosWithSameStudy,SyncSeriesBehaviorRelativePos,SyncSeriesBehaviorAbsolutePos} SyncSeriesBehavior;

@interface OrthogonalMPRViewer : Window3DController <NSWindowDelegate, NSSplitViewDelegate, NSToolbarDelegate>
{
    ViewerController					*viewer;

	IBOutlet OrthogonalMPRController	*controller;
	IBOutlet NSSplitView				*splitView;
	
	NSToolbar							*toolbar;
    IBOutlet NSView						*toolsView, *ThickSlabView;
	IBOutlet NSMatrix					*toolsMatrix;
	BOOL								isFullWindow;
    long								displayResliceAxes;

    KBPopUpToolbarItem                  *syncSeriesToolbarItem;
    SyncSeriesState                     syncSeriesState ;
    SyncSeriesBehavior                  syncSeriesBehavior;
    SyncSeriesScope                     syncSeriesScope;
    
	IBOutlet NSTextField				*thickSlabTextField;
	IBOutlet NSSlider					*thickSlabSlider;
	IBOutlet NSButton					*thickSlabActivated;
	IBOutlet NSPopUpButton				*thickSlabPopup;
	
	IBOutlet NSWindow					*dcmExportWindow;
	IBOutlet NSMatrix					*dcmSelection, *dcmFormat;
	IBOutlet NSSlider					*dcmInterval, *dcmFrom, *dcmTo;
	IBOutlet NSTextField				*dcmSeriesName, *dcmFromTextField, *dcmToTextField, *dcmIntervalTextField, *dcmCountTextField;
	IBOutlet NSBox						*dcmBox;
	DICOMExport							*exportDCM;
	
    IBOutlet NSView						*WLWWView;
	NSData								*transferFunction;	//For opacity
	
	// 4D
	IBOutlet NSView						*movieView;
	IBOutlet NSTextField				*movieTextSlide;
	IBOutlet NSButton					*moviePlayStop;
	IBOutlet NSSlider					*movieRateSlider;
	IBOutlet NSSlider					*moviePosSlider;
	short								curMovieIndex, maxMovieIndex;
	NSTimeInterval						lastTime, lastMovieTime;
	NSTimer								*movieTimer;
}

- (id) initWithPixList: (NSMutableArray*) pixList :(NSArray*) filesList :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC;

- (OrthogonalMPRController*) controller;

- (BOOL) is2DViewer;
- (ViewerController*) viewer;

- (short) curMovieIndex;
- (short) maxMovieIndex;
- (void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) iwl :(float) iww;
- (void) setCurWLWWMenu: (NSString*) wlww;
- (void)applyWLWWForString:(NSString *)menuString;
- (void) flipVolume;
- (DCMView*) keyView;

// SyncSeries between MPR viewers
- (void) setSyncSeriesBehavior:(SyncSeriesBehavior) newBehavior withNotification:(bool)doNotify;
- (void) setSyncSeriesScope:(SyncSeriesScope) newScope  withNotification:(bool)doNotify;
- (void) setSyncSeriesState:(SyncSeriesState) newState withNotification:(bool)doNotify;
- (void) syncSeriesNotification:(NSNotification*)notification   ;

- (void) moveToRelativePositionFromNSArray:(NSArray*) relativeLocation;
- (void) moveToRelativePosition:(float*) dcmCoord;
- (void) moveToAbsolutePositionFromNSArray:(NSArray*) newLocation;
- (void) moveToAbsolutePosition:(float*) dcmCoord;

- (void) updateSyncSeriesUI;

+ (NSDictionary*) evaluateSyncSeriesProperties:(id)currentViewer ;

+ (void) validateMPRViewersSyncSeriesState ;
+ (void) evaluteSyncSeriesToolbarItemsActivationWhenInit;
+ (void) evaluteSyncSeriesToolbarItemsActivationBeforeClose;
+ (BOOL) getSyncSeriesToolbarItemsActivation;

+ (NSMutableArray*) sortedOrthoMPRViewerApps;
+ (unsigned int)  orthoMPRViewerNumber;
+ (NSMutableArray*) orthoMPRViewerApps;
+ (NSMutableArray*) orthoMPRViewerApps:(BOOL)syncEnabledOnly;

@property (nonatomic,readwrite) SyncSeriesState syncSeriesState;
@property (nonatomic,readonly) SyncSeriesBehavior syncSeriesBehavior;
@property (nonatomic,readonly) SyncSeriesScope syncSeriesScope;

// Thick Slab
-(IBAction) setThickSlabMode : (id) sender;
-(IBAction) setThickSlab : (id) sender;
-(IBAction) activateThickSlab : (id) sender;

// NSSplitView Control
- (void) adjustSplitView;
//- (void) turnSplitView;
- (void) updateToolbarItems;

// Tools Selection
- (IBAction) resetImage:(id) sender;
- (IBAction) changeTool:(id) sender;

// NSToolbar Related Methods
- (void) setupToolbar;
- (IBAction) customizeViewerToolBar:(id)sender;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
- (void) toolbarWillAddItem: (NSNotification *) notif;
- (void) toolbarDidRemoveItem: (NSNotification *) notif;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;
- (void) fullWindowView:(int)index;

- (void) blendingPropagateOriginal:(OrthogonalMPRView*) sender;
- (void) blendingPropagateX:(OrthogonalMPRView*) sender;
- (void) blendingPropagateY:(OrthogonalMPRView*) sender;

-(void) ApplyOpacityString:(NSString*) str;

//export

-(IBAction) changeFromAndToBounds:(id) sender;
-(IBAction) setCurrentPosition:(id) sender;
-(IBAction) setCurrentdcmExport:(id) sender;

-(void) checkView:(NSView *)aView :(BOOL) OnOff;

-(void) dcmExportTextFieldDidChange:(NSNotification *)note;

// ROIs
- (IBAction) roiDeleteAll:(id) sender;

// 4D
- (void) MoviePlayStop:(id) sender;
- (void) setMovieIndex: (short) i;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;

- (ViewerController *)viewerController;
- (void)setCurrentTool:(int)currentTool;

- (void)bringToFrontROI:(ROI*)roi;
- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;
#ifndef OSIRIX_LIGHT
- (IBAction) endExportDICOMFileSettings:(id) sender;
- (void) exportDICOMFile:(id) sender;
#endif
@end
