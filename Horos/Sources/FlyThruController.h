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
#import "FlyThru.h"
#import "FlyThruAdapter.h"
#import "Window3DController.h"
#import "QuicktimeExport.h"
#import "FlyThruStepsArrayController.h"

/** \brief Window Controller for FlyThru
*/

@interface FlyThruController : NSWindowController <NSWindowDelegate>
{
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
	IBOutlet NSTextField	*numberOfFramesTextField;
	IBOutlet NSPopUpButton	*MatrixSizePopup;
	
			 NSPoint		boxPlayOrigin;
			 NSRect			windowFrame;
			 
	IBOutlet NSButton		*exportButton;
	IBOutlet FlyThruStepsArrayController *stepsArrayController;
	
	FlyThru					*flyThru;
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
	int				tabIndex;
	
}

@property (readwrite, retain) FlyThru *flyThru;
@property BOOL hidePlayBox;
@property BOOL hideComputeBox;
@property BOOL hideExportBox;
@property int  exportFormat;
@property (readwrite, copy) NSString *dcmSeriesName;
@property int	levelOfDetailType;
@property int	exportSize;
@property (readonly) Camera  *currentCamera;
@property (readonly) FlyThruStepsArrayController *stepsArrayController;
@property (readwrite, retain) FlyThruAdapter *FTAdapter;
@property int curMovieIndex;
@property int tabIndex;

- (void)setWindow3DController:(Window3DController*) w3Dc;
- (Window3DController*)window3DController;
- (id) initWithFlyThruAdapter:(FlyThruAdapter*)aFlyThruAdapter;
- (void)windowWillClose:(NSNotification *)notification;
- (void) dealloc;
- (IBAction) flyThruSetCurrentView:(id) sender;
- (IBAction) flyThruCompute:(id) sender;
- (void) flyThruPlayStop:(id) sender;
- (void) performMovieAnimation:(id) sender;
- (IBAction) flyThruQuicktimeExport :(id) sender;
- (NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max;
- (void) updateThumbnails;
- (NSButton*) exportButtonOption;
- (void)setCurMovieIndex:(int)index;
- (Camera *)currentCamera;
- (void)setupController;
@end
