/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/
//
// KFSplitView.h
// KFSplitView v. 1.3, 11/27/2004
//
// Copyright (c) 2003-2004 Ken Ferry. Some rights reserved.
// http://homepage.mac.com/kenferry/software.html
//
// This work is licensed under a Creative Commons license:
// http://creativecommons.org/licenses/by-nc/1.0/
//
// Send me an email if you have any problems (after you've read what there is to read).
//
// You can reach me at kenferry at the domain mac.com.

#import <AppKit/AppKit.h>

@interface KFSplitView:NSSplitView
{
    // retained
    NSMutableSet *kfCollapsedSubviews;
    NSMutableArray *kfDividerRects;
    NSString *kfPositionAutosaveName;
    NSCursor *kfIsVerticalResizeCursor;
    NSCursor *kfNotIsVerticalResizeCursor;

    // not retained
    NSCursor *kfCurrentResizeCursor;
    NSUserDefaults *kfDefaults;
    NSNotificationCenter *kfNotificationCenter;
    BOOL kfIsVertical;
    id kfDelegate;
}

// sets the collapse-state of a subview, which is completely independent
// of that subview's frame (as in NSSplitView).  (Sometime) after calling this
// you'll need to tell the splitview to resize its subviews.
// Normally, that would be this call:
//    [kfSplitView resizeSubviewsWithOldSize:[kfSplitView bounds].size];
- (void)setSubview:(NSView *)subview isCollapsed:(BOOL)flag;

// To find documentation for these methods refer to Apple's NSWindow
// documentation for the corresponding methods (e.g. -setFrameAutosaveName:).
// To use an autosave name, call -setPositionAutosaveName: from the -awakeFromNib
// method of a controller.
+ (void)removePositionUsingName:(NSString *)name;
- (void)savePositionUsingName:(NSString *)name;
- (BOOL)setPositionUsingName:(NSString *)name;
- (BOOL)setPositionAutosaveName:(NSString *)name;
- (NSString *)positionAutosaveName;
- (void)setPositionFromPlistObject:(id)string;
- (id)plistObjectWithSavedPosition;
- (void)kfRecalculateDividerRects;

@end

@interface NSObject(KFSplitViewDelegate)

// in notification argument 'object' will be sender, 'userInfo' will have key @"subview"
- (void)splitViewDidCollapseSubview:(NSNotification *)notification;
- (void)splitViewDidExpandSubview:(NSNotification *)notification;

- (void)splitView:(id)sender didDoubleClickInDivider:(int)index;
- (void)splitView:(id)sender didFinishDragInDivider:(int)index;

@end

// notifications: 'object' will be sender, 'userInfo' will have key @"subview".
// The delegate is automatically registered to receive these notifications.
extern NSString* const KFSplitViewDidCollapseSubviewNotification;
extern NSString* const KFSplitViewDidExpandSubviewNotification;

