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




#import <Cocoa/Cocoa.h>
#import "FlyThru.h"
#import "FlyThruAdapter.h"
#import "Window3DController.h"
#import "QuicktimeExport.h"
#import "FlyThruStepsArrayController.h"

@interface FlyThruController : NSWindowController {

	IBOutlet NSMatrix		*LOD;
	IBOutlet NSBox			*boxPlay;
	IBOutlet NSBox			*boxExport;
	IBOutlet NSBox			*boxCompute;
	
	IBOutlet NSTabView		*tabView;
	IBOutlet NSTableView	*FTview;
	IBOutlet NSTableColumn	*colCamNumber;
	IBOutlet NSTableColumn	*colCamPreview;

	IBOutlet NSMatrix		*methodChooser;
	IBOutlet NSButton		*computeButton;
	
	IBOutlet NSSlider		*framesSlider;
	IBOutlet NSButton		*playButton;

	
	IBOutlet NSTextField	*MatrixSize;
	IBOutlet NSPopUpButton	*MatrixSizePopup;
	
			 NSPoint		boxPlayOrigin;
			 NSRect			windowFrame;
			 
	IBOutlet NSButton		*exportButton;
	IBOutlet FlyThruStepsArrayController *stepsArrayController;
	
	FlyThru					*FT;
	Window3DController		*controller3D;
	FlyThruAdapter			*FTAdapter;			// link between abstract fly thru and concret 3D world (such as VR, SR, ...)
	
	NSTimer					*movieTimer;
	NSTimeInterval			lastMovieTime;
	int						curMovieIndex;
	BOOL					hidePlayBox;
	BOOL					hideComputeBox;
	BOOL					hideExportBox;
	BOOL					enableRenderingType;
	int						exportFormat;
	int						levelOfDetailType;
	int						exportSize;
	
	IBOutlet NSButton		*exportButtonOption;
	NSString				*dcmSeriesName;
	
}

@property (readwrite, retain) FlyThru *flyThru;
@property int currentMovieIndex;
@property BOOL hidePlayBox;
@property BOOL hideComputeBox;
@property BOOL hideExportBox;
@property int  exportFormat;
@property (readwrite, copy) NSString *dcmSeriesName;
@property int	levelOfDetailType;
@property int	exportSize;
@property (readonly) Camera  *currentCamera;
@property (readonly) FlyThru *FT;
@property (readwrite, retain) FlyThruAdapter *FTAdapter;
@property int curMovieIndex;

- (void)setWindow3DController:(Window3DController*) w3Dc;
- (Window3DController*)window3DController;
- (id) initWithFlyThruAdapter:(FlyThruAdapter*)aFlyThruAdapter;
- (void)windowWillClose:(NSNotification *)notification;
- (void) dealloc;
//- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
//- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
//- (int) selectedRow;
//- (void) selectRowAtIndex:(int)index;
//- (void) removeRowAtIndex:(int)index;
//- (IBAction) flyThruButton:(id) sender;
//- (void) setCurrentView;
- (IBAction) flyThruSetCurrentView:(id) sender;
- (IBAction) flyThruCompute:(id) sender;

- (void) flyThruPlayStop:(id) sender;
- (void) performMovieAnimation:(id) sender;
- (IBAction) flyThruQuicktimeExport :(id) sender;
- (NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max;
- (void) updateThumbnails;
//- (void) flyThruTag:(int) x;

// specific optional button for Endoscopy
- (NSButton*) exportButtonOption;
- (int)currentMovieIndex;
- (void)setCurrentMovieIndex:(int)index;

- (Camera *)currentCamera;
- (void)setupController;
@end
