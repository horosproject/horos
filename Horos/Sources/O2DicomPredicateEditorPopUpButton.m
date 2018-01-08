/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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

#import "O2DicomPredicateEditorPopUpButton.h"
#import "N2PopUpMenu.h"


@interface O2DicomPredicateEditorPopUpButtonCell : NSPopUpButtonCell {
    
}

@end


@implementation O2DicomPredicateEditorPopUpButton

@synthesize contextualMenu = _contextualMenu;
@synthesize noSelectionLabel = _noSelectionLabel;
@synthesize n2mode = _n2mode;

- (id)initWithFrame:(NSRect)frame pullsDown:(BOOL)flag {
    if ((self = [super initWithFrame:frame pullsDown:flag])) {
        self.cell = [[[O2DicomPredicateEditorPopUpButtonCell alloc] init] autorelease];
    }
    
    return self;
}

- (void)rightMouseDown:(NSEvent*)event {
    [NSMenu popUpContextMenu:self.contextualMenu withEvent:event forView:self withFont:self.font];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    self.contextualMenu = nil;
    self.noSelectionLabel = nil;
    [super dealloc];
}

- (void)sizeToFit {
    NSSize size = self.frame.size;
    NSString* str = !self.selectedItem.title.length? self.noSelectionLabel : self.selectedItem.title;
    size.width = [str sizeWithAttributes:[NSDictionary dictionaryWithObject:self.font forKey:NSFontAttributeName]].width + 22;
    [self setFrameSize:size];
}

- (NSString*)noSelectionLabel {
    if (_noSelectionLabel)
        return _noSelectionLabel;
    return @"null";
}

- (void)mouseDown:(NSEvent*)event {
    if (_n2mode) {
        [NSNotificationCenter.defaultCenter postNotificationName:NSPopUpButtonWillPopUpNotification object:self];

        NSMenu* menu = [[self.menu copy] autorelease];
        for (NSMenuItem* mi in menu.itemArray)
            if (!mi.title.length)
                [menu removeItem:mi];
        
        _menuWindow = [N2PopUpMenu popUpContextMenu:menu withEvent:event forView:self withFont:self.font];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeMenuWindowWillCloseNotification:) name:NSWindowWillCloseNotification object:_menuWindow];
    } else
        [super mouseDown:event];
}

- (void)observeMenuWindowWillCloseNotification:(NSNotification*)notification {
    _menuWindow = nil;
}

- (void)mouseDragged:(NSEvent*)event {
    if (_menuWindow) {
        NSRect r = {event.locationInWindow,NSZeroSize};
        [_menuWindow sendEvent:[NSEvent mouseEventWithType:NSLeftMouseDragged location:[_menuWindow convertRectFromScreen:[event.window convertRectToScreen:r]].origin modifierFlags:event.modifierFlags timestamp:event.timestamp windowNumber:_menuWindow.windowNumber context:event.context eventNumber:event.eventNumber clickCount:event.clickCount pressure:event.pressure]];
    }
    else [super mouseDragged:event];
}

- (void)mouseUp:(NSEvent*)event {
    if (_menuWindow) {
        NSRect r = {event.locationInWindow,NSZeroSize};
        [_menuWindow sendEvent:[NSEvent mouseEventWithType:NSLeftMouseUp location:[_menuWindow convertRectFromScreen:[event.window convertRectToScreen:r]].origin modifierFlags:event.modifierFlags timestamp:event.timestamp windowNumber:_menuWindow.windowNumber context:event.context eventNumber:event.eventNumber clickCount:event.clickCount pressure:event.pressure]];
    }
    else [super mouseUp:event];
}

- (void)keyDown:(NSEvent*)event {
    if (event.keyCode == 48) // tab
        return [super keyDown:event];
    [self mouseDown:event];
}

/*- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
    [super bind:binding toObject:observable withKeyPath:keyPath options:options];

    if ([binding isEqualToString:@"selectedTag"]) {
        NSInteger i = [self indexOfSelectedItem];
        if (i != -1) {
            NSMenuItem* mi = [self.menu itemAtIndex:i];
            if (!mi.title.length)
                [self.menu removeItemAtIndex:i];
        }
    }
}*/

/*- (NSInteger)selectedTag {
    NSInteger t = [super selectedTag];
    return t;
}*/

@end


@implementation O2DicomPredicateEditorPopUpButtonCell

- (void)drawInteriorWithFrame:(NSRect)frame inView:(O2DicomPredicateEditorPopUpButton*)view {
    [super drawInteriorWithFrame:frame inView:view];
    if (!self.title.length) {
        NSAttributedString* t = [[NSAttributedString alloc] initWithString:view.noSelectionLabel attributes:[NSDictionary dictionaryWithObject:self.font forKey:NSFontAttributeName]];
        frame.origin.y += 1;
        [self drawTitle:t withFrame:[self titleRectForBounds:frame] inView:view];
    }
}

@end
