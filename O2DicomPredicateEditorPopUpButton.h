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

@interface O2DicomPredicateEditorPopUpButton : NSPopUpButton {
    NSMenu* _contextualMenu;
	NSString* _noSelectionLabel;
    NSWindow* _menuWindow;
    BOOL _n2mode;
}

@property(retain) NSMenu* contextualMenu;
@property(retain,nonatomic) NSString* noSelectionLabel;
@property BOOL n2mode;

@end
