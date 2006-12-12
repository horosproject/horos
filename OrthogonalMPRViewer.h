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
#import "ViewerController.h"
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"
#import "OSIWindowController.h"

@class DICOMExport;

@interface OrthogonalMPRViewer : OSIWindowController
{
	ViewerController					*viewer;

	IBOutlet OrthogonalMPRController	*controller;
	IBOutlet NSSplitView				*splitView;
	
	NSToolbar							*toolbar;
    IBOutlet NSView						*toolsView, *ThickSlabView;
	IBOutlet NSMatrix					*toolsMatrix;
	BOOL								isFullWindow;
	long								displayResliceAxes;

	IBOutlet NSTextField				*thickSlabTextField;
	IBOutlet NSSlider					*thickSlabSlider;
	
	IBOutlet NSWindow					*dcmExportWindow;
	IBOutlet NSMatrix					*dcmSelection, *dcmFormat;
	IBOutlet NSSlider					*dcmInterval, *dcmFrom, *dcmTo;
	IBOutlet NSTextField				*dcmSeriesName, *dcmFromTextField, *dcmToTextField, *dcmIntervalTextField;
	IBOutlet NSBox						*dcmBox;
	DICOMExport							*exportDCM;
	
    IBOutlet NSView						*WLWWView;
    IBOutlet NSPopUpButton				*wlwwPopup;
	IBOutlet NSPopUpButton				*clutPopup;
	IBOutlet NSPopUpButton				*OpacityPopup;

	NSString							*curWLWWMenu, *curCLUTMenu;//, *curOpacityMenu, *curConvMenu;
}

- (id) initWithPixList: (NSMutableArray*) pixList :(NSArray*) filesList :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC;

- (OrthogonalMPRController*) controller;

- (BOOL) is2DViewer;
- (ViewerController*) viewer;

- (void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) iwl :(float) iww;
- (void) setCurWLWWMenu: (NSString*) wlww;
- (void) flipVolume;
- (DCMView*) keyView;

// Thick Slab
-(IBAction) setThickSlabMode : (id) sender;
-(IBAction) setThickSlab : (id) sender;

// NSSplitView Control
- (void) adjustSplitView;
- (void) turnSplitView;
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

//export
-(IBAction) endExportDICOMFileSettings:(id) sender;
-(IBAction) changeFromAndToBounds:(id) sender;
-(IBAction) setCurrentPosition:(id) sender;
-(IBAction) setCurrentdcmExport:(id) sender;

-(void) checkView:(NSView *)aView :(BOOL) OnOff;

-(void) dcmExportTextFieldDidChange:(NSNotification *)note;

// ROIs
- (IBAction) roiDeleteAll:(id) sender;

@end
