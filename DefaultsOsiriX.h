/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import <Cocoa/Cocoa.h>
#import "options.h"

// WARNING: If you add or modify this list, check ViewerController.m, DCMView.h and HotKey Pref Pane

enum HotKeyActions {DefaultWWWLHotKeyAction = 0, FullDynamicWWWLHotKeyAction, 
	Preset1WWWLHotKeyAction, Preset2WWWLHotKeyAction, Preset3WWWLHotKeyAction, 
	Preset4WWWLHotKeyAction, Preset5WWWLHotKeyAction, Preset6WWWLHotKeyAction, 
	Preset7WWWLHotKeyAction, Preset8WWWLHotKeyAction, Preset9WWWLHotKeyAction,
	FlipVerticalHotKeyAction, FlipHorizontalHotKeyAction,
	WWWLToolHotKeyAction, MoveHotKeyAction, ZoomHotKeyAction, RotateHotKeyAction,
	ScrollHotKeyAction, LengthHotKeyAction, AngleHotKeyAction, RectangleHotKeyAction,
	OvalHotKeyAction, TextHotKeyAction, ArrowHotKeyAction, OpenPolygonHotKeyAction,
	ClosedPolygonHotKeyAction, PencilHotKeyAction, ThreeDPointHotKeyAction, PlainToolHotKeyAction,
	BoneRemovalHotKeyAction, Rotate3DHotKeyAction, Camera3DotKeyAction, scissors3DHotKeyAction, RepulsorHotKeyAction, SelectorHotKeyAction, EmptyHotKeyAction, UnreadHotKeyAction, ReviewedHotKeyAction, DictatedHotKeyAction, ValidatedHotKeyAction, OrthoMPRCrossHotKeyAction, Preset1OpacityHotKeyAction, Preset2OpacityHotKeyAction, Preset3OpacityHotKeyAction, Preset4OpacityHotKeyAction, Preset5OpacityHotKeyAction, Preset6OpacityHotKeyAction, Preset7OpacityHotKeyAction, Preset8OpacityHotKeyAction, Preset9OpacityHotKeyAction, FullScreenAction, Sync3DAction, SetKeyImageAction};


/** \brief Sets up user defaults */
@interface DefaultsOsiriX : NSObject {

}

//+ (BOOL) isHUG;
//+ (BOOL) isUniGE;
//+ (BOOL) isLAVIM;
+ (NSMutableDictionary*) getDefaults;
//+ (NSString*) hostName;
+ (NSHost*) currentHost;

+ (mach_vm_size_t) GPUModelVRAMInfo;
+ (long) vramSize;

@end
