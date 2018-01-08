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
#import "OrthogonalMPRPETCTController.h"
#import "KFSplitView.h"
#import "Window3DController.h"
#import "OrthogonalMPRViewer.h"

@class KBPopUpToolbarItem;

/** \brief Window Controller for PET-CT fusion display */

@interface OrthogonalMPRPETCTViewer : Window3DController <NSWindowDelegate, NSSplitViewDelegate, NSToolbarDelegate>
{
	ViewerController							*viewer, *blendingViewerController;
	
	IBOutlet OrthogonalMPRPETCTController		*CTController, *PETCTController, *PETController;
	
//	IBOutlet NSSplitView						*originalSplitView, *xReslicedSplitView, *yReslicedSplitView, *modalitySplitView;
	IBOutlet KFSplitView						*originalSplitView, *xReslicedSplitView, *yReslicedSplitView, *modalitySplitView;
//	IBOutlet NSSplitView						*modalitySplitView;
	float										minSplitViewsSize;
	
	NSToolbar								*toolbar;
    IBOutlet NSView							*toolsView;
	IBOutlet NSMatrix						*toolsMatrix;
	IBOutlet NSView							*blendingToolView;
	IBOutlet NSTextField					*blendingPercentage;
	IBOutlet NSSlider						*blendingSlider;
		
	BOOL									isFullWindow;
	long									displayResliceAxes;
	
	NSArray									*filesList;
	NSMutableArray							*pixList;
	
	IBOutlet NSWindow						*dcmExportWindow;
	IBOutlet NSMatrix						*dcmSelection, *dcmFormat;
	IBOutlet NSSlider						*dcmInterval, *dcmFrom, *dcmTo;
	IBOutlet NSTextField					*dcmSeriesName, *dcmFromTextField, *dcmToTextField, *dcmIntervalTextField, *dcmCountTextField;
	IBOutlet NSBox							*dcmBox;
	DICOMExport								*exportDCM;
	
    IBOutlet NSView							*WLWWView;
	IBOutlet NSPopUpButton					*blendingModePopup;
	
	NSData									*transferFunction;	//For opacity
	
	long									fistCTSlice, fistPETSlice, sliceRangeCT, sliceRangePET;
	
	// 4D
	IBOutlet NSView						*movieView;
	IBOutlet NSTextField				*movieTextSlide;
	IBOutlet NSButton					*moviePlayStop;
	IBOutlet NSSlider					*movieRateSlider;
	IBOutlet NSSlider					*moviePosSlider;
	short								curMovieIndex, maxMovieIndex;
	NSTimeInterval						lastTime, lastMovieTime;
	NSTimer								*movieTimer;
    
    // SyncSeries
    KBPopUpToolbarItem                  *syncSeriesToolbarItem;
    SyncSeriesState                     syncSeriesState ;
    SyncSeriesBehavior                  syncSeriesBehavior;
    
    float                               syncOriginPosition[3];
}

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC;

- (DCMView*) keyView;
- (BOOL) is2DViewer;
- (void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) iwl :(float) iww :(id) sender;
- (IBAction) flipVolume;
- (ViewerController*) viewerController;

- (void) resliceFromOriginal: (float) x : (float) y : (id) sender;
- (void) resliceFromX: (float) x : (float) y : (id) sender;
- (void) resliceFromY: (float) x : (float) y : (id) sender;

- (void) blendingPropagateOriginal:(OrthogonalMPRPETCTView*) sender;
- (void) blendingPropagateX:(OrthogonalMPRPETCTView*) sender;
- (void) blendingPropagateY:(OrthogonalMPRPETCTView*) sender;

- (OrthogonalMPRPETCTController*) CTController;
- (OrthogonalMPRPETCTController*) PETCTController;
- (OrthogonalMPRPETCTController*) PETController;

- (OrthogonalMPRController*) controller;

// SyncSeries between MPR viewers
- (void) syncSeriesScopeAction:(id) sender;
- (void) syncSeriesBehaviorAction:(id) sender;
- (void) syncSeriesStateAction:(id) sender;
- (void) syncSeriesAction:(id) sender;

@property (nonatomic,retain) KBPopUpToolbarItem *syncSeriesToolbarItem;
@property (nonatomic,assign) SyncSeriesState syncSeriesState;
@property (nonatomic,assign) SyncSeriesBehavior syncSeriesBehavior;

- (float*) syncOriginPosition;
- (void) syncSeriesNotification:(NSNotification*)notification;
- (void) posChangeNotification:(NSNotification*)notification;

// Tools
- (IBAction) changeTool:(id) sender;
- (IBAction) changeBlendingFactor:(id) sender;
- (void) moveBlendingFactorSlider:(float) f;
- (IBAction) blendingMode:(id) sender;
- (void) setBlendingMode: (long) m;
- (void) realignDataSet:(id) sender;

// NSToolbar
- (void) setupToolbar;
- (IBAction) customizeViewerToolBar:(id)sender;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
- (void) toolbarWillAddItem: (NSNotification *) notif;
- (void) toolbarDidRemoveItem: (NSNotification *) notif;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;

// NSSplitViews' delegate
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;

// NSSplitView Control
- (void) adjustHeightSplitView;
//- (void) turnModalitySplitView;
- (void) updateToolbarItems;

- (void) fullWindowView:(int)index :(id)sender;

- (void) fullWindowPlan:(int)index :(id)sender;

- (void) flipVerticalOriginal: (id) sender;
- (void) flipVerticalX: (id) sender;
- (void) flipVerticalY: (id) sender;

- (void) flipHorizontalOriginal: (id) sender;
- (void) flipHorizontalX: (id) sender;
- (void) flipHorizontalY: (id) sender;

- (void) fullWindowModality:(int)index :(id)sender;

//export
-(IBAction) endExportDICOMFileSettings:(id) sender;
- (NSDictionary*) exportDICOMFileInt :(BOOL) screenCapture view:(DCMView*) curView;
- (IBAction) changeFromAndToBounds:(id) sender;
- (IBAction) setCurrentPosition:(id) sender;
- (IBAction) setCurrentdcmExport:(id) sender;
- (void)checkView:(NSView *)aView :(BOOL) OnOff;
- (void)dcmExportTextFieldDidChange:(NSNotification *)note;

// 4D
- (void) MoviePlayStop:(id) sender;
- (short) curMovieIndex;
- (short) maxMovieIndex;
- (void) setMovieIndex: (short) i;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;

- (void)bringToFrontROI:(ROI*)roi;
- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;

@end
