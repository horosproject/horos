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
#import "FlyThru.h"
#import "FlyThruAdapter.h"
#import "Window3DController.h"
#import "QuicktimeExport.h"

@interface FlyThruController : NSWindowController {

	IBOutlet NSMatrix		*LOD;
	IBOutlet NSMatrix		*exportFormat;
	
	IBOutlet NSTabView		*tabView;
	IBOutlet NSTableView	*FTview;
	IBOutlet NSTableColumn	*colCamNumber;
	IBOutlet NSTableColumn	*colCamPreview;

	IBOutlet NSBox			*boxCompute;
	IBOutlet NSTextField	*nbFramesTextField;
	IBOutlet NSMatrix		*methodChooser;
	IBOutlet NSButton		*computeButton;
	
	IBOutlet NSBox			*boxPlay;
	IBOutlet NSSlider		*framesSlider;
	IBOutlet NSButton		*playButton;
	IBOutlet NSTextField	*dcmSeriesName;
	
			 NSPoint		boxPlayOrigin;
			 NSRect			windowFrame;
			 
	IBOutlet NSBox			*boxExport;
	IBOutlet NSButton		*exportButton;
	
	FlyThru					*FT;
	Window3DController		*controller3D;
	FlyThruAdapter			*FTAdapter;			// link between abstract fly thru and concret 3D world (such as VR, SR, ...)
	
	NSTimer					*movieTimer;
	NSTimeInterval			lastMovieTime;
	int						curMovieIndex;
	
	IBOutlet NSButton		*exportButtonOption;
}

- (void)setWindow3DController:(Window3DController*) w3Dc;
- (Window3DController*)window3DController;
- (id) initWithFlyThruAdapter:(FlyThruAdapter*)aFlyThruAdapter;
- (void)windowWillClose:(NSNotification *)notification;
- (void) dealloc;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int) selectedRow;
- (void) selectRowAtIndex:(int)index;
- (void) removeRowAtIndex:(int)index;
- (IBAction) flyThruButton:(id) sender;
- (void) setCurrentView;
- (IBAction) flyThruSetCurrentView:(id) sender;
- (void) flyThruSetNumberOfFrames;
- (IBAction) flyThruSetNumberOfFrames:(id) sender;
- (IBAction) flyThruCompute:(id) sender;
- (IBAction) flyThruSetCurrentViewToSliderPosition:(id) sender;
- (void) flyThruPlayStop:(id) sender;
- (void) performMovieAnimation:(id) sender;
- (IBAction) flyThruQuicktimeExport :(id) sender;
- (NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max;
- (IBAction) flyThruChangeInterpolationMethod :(id) sender;
- (IBAction) flyThruLoop :(id) sender;
- (void) updateThumbnails;
- (void) flyThruTag:(int) x;

// specific optional button for Endoscopy
- (NSButton*) exportButtonOption;

@end
