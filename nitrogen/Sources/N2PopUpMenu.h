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

#import <Foundation/Foundation.h>

@interface N2PopUpMenu : NSObject

// when popping up menus using this method, you should make sure the clicked vied forwards mouseup and mousedragged events to the returned NSWindow, as done in O2DicomPredicateEditorPopUpButton.m
+ (NSWindow*)popUpContextMenu:(NSMenu*)menu withEvent:(NSEvent*)event forView:(NSPopUpButton*)view withFont:(NSFont*)font;

@end
