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
#import "OrthogonalMPRController.h"
#import "VRController.h"
#import "EndoscopyVRController.h"
#import "Camera.h"
#import "OSIWindowController.h"

@class OSIVoxel;

/** \brief   Window Controller for Endoscopy
*/


@interface EndoscopyViewer : OSIWindowController
{
	IBOutlet OrthogonalMPRController	*mprController;
	IBOutlet EndoscopyVRController		*vrController;
	NSMutableArray						*pixList;
	
	IBOutlet NSSplitView				*topSplitView, *bottomSplitView;
	
	NSToolbar							*toolbar;
    IBOutlet NSView						*tools3DView, *tools2DView, *engineView, *shadingView, *LODView;
	IBOutlet NSMatrix					*tools3DMatrix, *tools2DMatrix;
	
	IBOutlet NSView						*WLWW3DView, *WLWW2DView;
	IBOutlet NSPopUpButton				*wlww2DPopup, *clut2DPopup;
	
	NSString							*cur2DWLWWMenu, *cur2DCLUTMenu;
	
	IBOutlet NSWindow					*exportDCMWindow;
	IBOutlet NSMatrix					*exportDCMViewsChoice;
	IBOutlet NSTextField				*exportDCMSeriesName;
	
	BOOL								exportAllViews;
}


@property(readonly) EndoscopyVRController *vrController;

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC : (ViewerController*) vC;
- (BOOL) is2DViewer;
- (NSMutableArray*) pixList;
//- (IBAction) centerline: (id) sender;
- (void) setCameraRepresentation: (NSNotification*) note;
- (void) setCameraRepresentation;
- (void) setCameraPositionRepresentation: (Camera*) aCamera;
- (void) setCameraFocalPointRepresentation: (Camera*) aCamera;
- (void) setCameraViewUpRepresentation: (Camera*) aCamera;
- (void) setCamera;
- (void) setupToolbar;
- (void) Apply2DCLUT:(id) sender;
- (void) setCameraPosition:(OSIVoxel *)position  focalPoint:(OSIVoxel *)focalPoint;


#pragma mark-
#pragma mark VR Viewer methods
- (void) ApplyWLWW:(id) sender;

#pragma mark-
#pragma mark Tools Selection
- (IBAction) change2DTool:(id) sender;
- (IBAction) change3DTool:(id) sender;
#pragma mark-
#pragma mark NSSplitview's delegate methods
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;

#pragma mark-
#pragma mark export
- (IBAction) setExportAllViews: (id) sender;
- (BOOL) exportAllViews;
- (void) exportDICOMFile:(id) sender;
- (IBAction) endDCMExportSettings:(id) sender;
- (unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp;
@end
