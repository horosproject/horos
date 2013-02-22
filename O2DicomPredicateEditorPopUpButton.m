//
//  O2DicomPredicateEditorPopUpButtonCell.m
//  Predicator
//
//  Created by Alessandro Volz on 13.12.12.
//  Copyright (c) 2012 Alessandro Volz. All rights reserved.
//

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
        _menuWindow = [N2PopUpMenu popUpContextMenu:self.menu withEvent:event forView:self withFont:self.font];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeMenuWindowWillCloseNotification:) name:NSWindowWillCloseNotification object:_menuWindow];
    } else
        [super mouseDown:event];
}

- (void)observeMenuWindowWillCloseNotification:(NSNotification*)notification {
    _menuWindow = nil;
}

- (void)mouseDragged:(NSEvent*)event {
    if (_menuWindow)
        [_menuWindow sendEvent:[NSEvent mouseEventWithType:NSLeftMouseDragged location:[_menuWindow convertScreenToBase:[event.window convertBaseToScreen:event.locationInWindow]] modifierFlags:event.modifierFlags timestamp:event.timestamp windowNumber:_menuWindow.windowNumber context:event.context eventNumber:event.eventNumber clickCount:event.clickCount pressure:event.pressure]];
    else [super mouseDragged:event];
}

- (void)mouseUp:(NSEvent*)event {
    if (_menuWindow)
        [_menuWindow sendEvent:[NSEvent mouseEventWithType:NSLeftMouseUp location:[_menuWindow convertScreenToBase:[event.window convertBaseToScreen:event.locationInWindow]] modifierFlags:event.modifierFlags timestamp:event.timestamp windowNumber:_menuWindow.windowNumber context:event.context eventNumber:event.eventNumber clickCount:event.clickCount pressure:event.pressure]];
    else [super mouseUp:event];
}

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
