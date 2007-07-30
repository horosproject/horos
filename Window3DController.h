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




#import <Foundation/Foundation.h>
#import "ColorTransferView.h"
#import "OpacityTransferView.h"
#import "NSFullScreenWindow.h"
#import "OSIWindowController.h"


#define DATABASEPATH				@"/DATABASE/"
#define STATEDATABASE				@"/3DSTATE/"



@class ViewerController;
@class DCMPix;
@class VTKView;

@interface Window3DController : OSIWindowController
{
	IBOutlet NSWindow				*setWLWWWindow;
    IBOutlet NSTextField			*wlset, *fromset;
    IBOutlet NSTextField			*wwset, *toset;	
    IBOutlet NSWindow				*addWLWWWindow;
    IBOutlet NSTextField			*newName;
    IBOutlet NSTextField			*wl;
    IBOutlet NSTextField			*ww;
    IBOutlet NSPopUpButton			*wlwwPopup;
    NSString						*curWLWWMenu;

	IBOutlet NSWindow				*addCLUTWindow;
	IBOutlet ColorTransferView		*clutView;
	IBOutlet NSTextField			*clutName;
	IBOutlet NSPopUpButton			*clutPopup;
	NSString						*curCLUTMenu;

	IBOutlet NSWindow				*addOpacityWindow;
	IBOutlet NSTextField			*OpacityName;
	IBOutlet OpacityTransferView	*OpacityView;
	IBOutlet NSPopUpButton			*OpacityPopup;
    NSString						*curOpacityMenu;

    BOOL							FullScreenOn;
	NSWindow						*FullScreenWindow;
	NSWindow						*StartingWindow;
	NSView							*contentView;

}

- (void) sendMailImage: (NSImage*) im;
- (ViewerController*) blendingController;
- (id) view;

- (void) setWLWW: (float) wl : (float) ww;
- (void) getWLWW: (float*) wl : (float*) ww;
- (IBAction) endSetWLWW: (id) sender;
- (IBAction) SetWLWW: (id) sender;
- (IBAction) endNameWLWW: (id) sender;
- (IBAction) updateSetWLWW: (id) sender;
- (void) deleteWLWW: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo;
- (NSPopUpButton*) wlwwPopup;

- (IBAction) AddCLUT: (id) sender;
- (IBAction) clutAction: (id) sender;
- (IBAction) endCLUT: (id) sender;
- (void) ApplyCLUT: (id) sender;
- (void) ApplyCLUTString: (NSString*) str;			// Overridden in children for now.
- (void) deleteCLUT: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo;
- (void) UpdateCLUTMenu: (NSNotification*) note;
- (void) CLUTChanged: (NSNotification*) note;
- (NSPopUpButton*) clutPopup;

- (void) ApplyOpacity: (id) sender;
- (IBAction) endOpacity: (id) sender;
- (void) deleteOpacity: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo;
- (NSPopUpButton*) OpacityPopup;

- (void) offFullScreen;
- (IBAction) fullScreenMenu: (id) sender;
- (long) movieFrames;
- (void) setMovieFrame: (long) l;

- (void) print:(id) sender;
- (BOOL)is4D;

- (NSArray*) pixList;
- (NSArray*) fileList;

@end
