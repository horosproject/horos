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
#import "OrthogonalMPRPETCTController.h"
#import "KFSplitView.h"

@interface OrthogonalMPRPETCTViewer : NSWindowController
{
	ViewerController							*blendingViewerController;
	
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
	
	IBOutlet NSWindow						*dcmExportWindow;
	IBOutlet NSMatrix						*dcmSelection, *dcmFormat;
	IBOutlet NSSlider						*dcmInterval, *dcmFrom, *dcmTo;
	IBOutlet NSTextField					*dcmSeriesName, *dcmFromTextField, *dcmToTextField, *dcmIntervalTextField;
	IBOutlet NSButton						*dcmExport3Modalities;
	DICOMExport								*exportDCM;
	
    IBOutlet NSView							*WLWWView;
    IBOutlet NSPopUpButton					*wlwwPopup;
    IBOutlet NSPopUpButton					*clutPopup;
	IBOutlet NSPopUpButton					*OpacityPopup;

	NSString								*curWLWWMenu, *curCLUTMenu;//, *curOpacityMenu, *curConvMenu;
	
	long									fistCTSlice, fistPETSlice, sliceRangeCT, sliceRangePET;
}

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC;

- (DCMView*) keyView;
- (BOOL) is2DViewer;
- (void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) iwl :(float) iww:(id) sender;
- (IBAction) flipVolume;

- (void) resliceFromOriginal: (long) x: (long) y: (id) sender;
- (void) resliceFromX: (long) x: (long) y: (id) sender;
- (void) resliceFromY: (long) x: (long) y: (id) sender;

- (void) blendingPropagateOriginal:(OrthogonalMPRPETCTView*) sender;
- (void) blendingPropagateX:(OrthogonalMPRPETCTView*) sender;
- (void) blendingPropagateY:(OrthogonalMPRPETCTView*) sender;

- (OrthogonalMPRPETCTController*) CTController;
- (OrthogonalMPRPETCTController*) PETCTController;
- (OrthogonalMPRPETCTController*) PETController;

// Tools
- (IBAction) changeTool:(id) sender;
- (IBAction) changeBlendingFactor:(id) sender;
- (void) moveBlendingFactorSlider:(float) f;
- (IBAction) blendingMode:(id) sender;

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
- (void) turnModalitySplitView;
- (void) updateToolbarItems;

- (void) fullWindowView:(int)index:(id)sender;

- (void) fullWindowPlan:(int)index:(id)sender;

- (void) flipVerticalOriginal: (id) sender;
- (void) flipVerticalX: (id) sender;
- (void) flipVerticalY: (id) sender;

- (void) flipHorizontalOriginal: (id) sender;
- (void) flipHorizontalX: (id) sender;
- (void) flipHorizontalY: (id) sender;

- (void) fullWindowModality:(int)index:(id)sender;

//export
-(IBAction) endExportDICOMFileSettings:(id) sender;
- (void) exportDICOMFileInt :(BOOL) screenCapture view:(DCMView*) curView;
- (IBAction) changeFromAndToBounds:(id) sender;
@end
