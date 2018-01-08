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

/** \brief  SuperClass for 3D WindowControllers
*/


#import <Foundation/Foundation.h>
#import "ColorTransferView.h"
#import "OpacityTransferView.h"
#import "NSFullScreenWindow.h"
#import "OSIWindowController.h"


@class ROIVolume;
@class ViewerController;
@class DCMPix;
@class VTKView;


/** \brief Base Window Controller for 3D viewers */

@interface Window3DController : OSIWindowController <NSWindowDelegate>
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
	
#ifdef _STEREO_VISION_
    short							FullScreenOn;
#else
	BOOL							FullScreenOn;
#endif
	
	NSWindow						*FullScreenWindow;
	NSWindow						*StartingWindow;
	NSView							*contentView;
	
	BOOL							windowWillClose;

}

- (BOOL) windowWillClose;
- (void) sendMailImage: (NSImage*) im;
- (ViewerController*) blendingController;
- (id) view;
- (ViewerController*) viewer;

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

- (void) ApplyOpacityString: (NSString*) str;
- (void) load3DState;

- (NSArray*) roiVolumes;
- (void) hideROIVolume: (ROIVolume*) v;
- (void) displayROIVolume: (ROIVolume*) v;
@end
