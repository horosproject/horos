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

#import "N2PopUpMenu.h"
#import "NSString+N2.h"


@interface N2PopUpMenuWindowView : NSView

@end

@interface N2PopUpMatrix : NSMatrix {
    CGFloat _itemHeight, _minItemWidth;
    NSInteger _highlightedCellRow;
    BOOL _highlighting;
}

@property CGFloat itemHeight;
@property (nonatomic) NSInteger highlightedCellRow;

- (void)mouseMovedToWindowLocation:(NSPoint)windowLocation;
- (void)highlightItemAtRow:(NSInteger)row scroll:(BOOL)scroll;

@end

@interface N2PopUpMatrixCell : NSCell {
    NSInteger _tag;
}

@property NSInteger tag;

@end

@interface N2PopUpScrollView : NSControl {
    NSTimer* _timer;
    BOOL _bottom;
    id _target;
    SEL _action;
}

@property(assign) id target;
@property SEL action;

- (void)setTop;
- (void)setBottom;

@end

@interface N2PopUpMenuWindow : NSWindow

@end

@interface N2PopUpMenuWindowController : NSWindowController<NSWindowDelegate, NSTextFieldDelegate> {
    N2PopUpMenuWindowView* _bgView;
    N2PopUpMatrix* _puView;
    NSScrollView* _sView;
    N2PopUpScrollView* _topScrollButton;
    N2PopUpScrollView* _bottomScrollButton;
    NSTextField* _filterField;
    NSView* _view;
    NSMenu* _menu;
    BOOL _centerOnNextRefresh, _refreshing;
    NSUInteger _noMouseMovedToWindowLocationOnNextRefresh;
    NSTimeInterval _startTime;
}

@property(readonly) N2PopUpMatrix* puView;
@property(readonly) NSTimeInterval startTime;

- (void)startTrackingMenu:(NSMenu*)menu withEvent:(NSEvent*)event forView:(NSView*)view withFont:(NSFont*)font;

- (void)incNoMouseMovedToWindowLocationOnNextRefresh;

@end

@implementation N2PopUpMenu

+ (NSWindow*)popUpContextMenu:(NSMenu*)menu withEvent:(NSEvent*)event forView:(NSView*)view withFont:(NSFont*)font {
    N2PopUpMenuWindowController* wc = [[N2PopUpMenuWindowController alloc] init];
    
    [wc startTrackingMenu:menu withEvent:event forView:view withFont:font];
    
    return wc.window;
}

@end

@implementation N2PopUpMenuWindowController

@synthesize puView = _puView;
@synthesize startTime = _startTime;

- (void)incNoMouseMovedToWindowLocationOnNextRefresh {
    ++_noMouseMovedToWindowLocationOnNextRefresh;
}

static const NSSize FilterFieldBorder = NSMakeSize(20,4);
static const NSSize PopUpWindowBorder = NSMakeSize(10,4);

- (id)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification*)notification {
    [self autorelease];
}

- (void)startTrackingMenu:(NSMenu*)menu withEvent:(NSEvent*)event forView:(NSView*)view withFont:(NSFont*)font {
//    NSLog(@"%@", menu.itemArray);
    
    _startTime = event.timestamp;
    
    _view = [view retain];
    _menu = [menu retain];
    
    CGFloat itemHeight = _puView.itemHeight;

    NSRect viewFrame = [view.window convertRectToScreen:[view convertRect:view.bounds toView:nil]];

    self.window = [[N2PopUpMenuWindow alloc] initWithContentRect:viewFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [self.window setLevel:NSMainMenuWindowLevel];
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[[NSColor whiteColor] colorWithAlphaComponent:0]];
    [self.window setHasShadow:YES];
    [self.window setAcceptsMouseMovedEvents:YES];
    [self.window setReleasedWhenClosed:YES];
    
    self.window.menu = menu;
    
    _bgView = [[N2PopUpMenuWindowView alloc] initWithFrame:NSZeroRect];
    _puView = [[N2PopUpMatrix alloc] initWithFrame:NSZeroRect];
    _sView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    
    [_sView setDrawsBackground:NO];
    [_sView setBorderType:NSNoBorder];

    [_sView setHasHorizontalScroller:NO];
    [_sView setHasVerticalScroller:YES];
    [_sView setHasHorizontalRuler:NO];
    [_sView setHasVerticalRuler:NO];
    
    [_sView setVerticalScrollElasticity:NSScrollElasticityNone];
    
    [_sView setLineScroll:itemHeight];
    
    _topScrollButton = [[N2PopUpScrollView alloc] initWithFrame:NSZeroRect];
    [_topScrollButton setTop];
    [_topScrollButton setAction:@selector(scrollLineUp:)];
    [_topScrollButton setTarget:_puView];
    
    _bottomScrollButton = [[N2PopUpScrollView alloc] initWithFrame:NSZeroRect];
    [_bottomScrollButton setBottom];
    [_bottomScrollButton setAction:@selector(scrollLineDown:)];
    [_bottomScrollButton setTarget:_puView];
    
    _filterField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    _filterField.delegate = self;
    
    [_filterField.cell setControlSize:NSSmallControlSize];
    _filterField.font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
    _filterField.bezelStyle = NSTextFieldRoundedBezel;//NSRoundedBezelStyle;
    [_filterField sizeToFit];
    [_filterField setFocusRingType:NSFocusRingTypeNone];
    
    [self.window.contentView addSubview:_bgView];
    [_bgView addSubview:_sView];
    [_sView setDocumentView:_puView];

    [self.window setDelegate:self];
    [_sView.contentView setPostsBoundsChangedNotifications:YES];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeScrollViewContentViewBoundsDidChangeNotification:) name:NSViewBoundsDidChangeNotification object:_sView.contentView];
    
    _puView.font = font;
    
    NSInteger highlight = NSNotFound;
    if ([view isKindOfClass:[NSPopUpButton class]])
        highlight = [[[menu.itemArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isHidden = NO"]] valueForKeyPath:@"representedObject"] indexOfObject:[[(NSPopUpButton*)view selectedItem] representedObject]];
    [_puView highlightItemAtRow:highlight scroll:YES];

    [self filter:YES];
    
    [_view.window sendEvent:[NSEvent mouseEventWithType:NSLeftMouseUp location:event.locationInWindow modifierFlags:event.modifierFlags timestamp:event.timestamp windowNumber:event.windowNumber context:event.context eventNumber:event.eventNumber+1 clickCount:event.clickCount pressure:0]];
}

- (void)windowDidResignKey:(NSNotification*)notification {
    
    [self.window close];
}

- (void)dealloc {
    [_view release];
    [_menu release];
    [_bgView release];
    [_puView release];
    [_sView release];
    [_topScrollButton release];
    [_bottomScrollButton release];
    [_filterField release];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [super dealloc];
}

- (void)update:(BOOL)center { // changes window size
    if (center)
        _centerOnNextRefresh = YES;
    
    CGFloat itemHeight = _puView.itemHeight;

    [_puView sizeToCells];
    
    NSSize totContentSize = _puView.frame.size;
    
    CGFloat extraH = 0;
    if (_filterField.superview)
        extraH += _filterField.frame.size.height+FilterFieldBorder.height*2;
    
    NSRect screenFrame = [_view.window.screen visibleFrame];
    screenFrame = NSInsetRect(screenFrame, 2, 2); // stay away from screen top & bottom
    
//    NSRect fo = [self.window frame];
    
    NSSize availableSize = screenFrame.size;
    availableSize.height -= PopUpWindowBorder.height*2; // 4 external
    availableSize.height = ((int)(availableSize.height/itemHeight))*itemHeight;
    
    NSRect viewFrame = [_view.window convertRectToScreen:[_view convertRect:_view.bounds toView:nil]];

    NSRect f = NSMakeRect(viewFrame.origin.x, viewFrame.origin.y, totContentSize.width, MIN(availableSize.height, totContentSize.height)+PopUpWindowBorder.height*2+extraH);
    if (f.origin.y+f.size.height > screenFrame.origin.y+screenFrame.size.height) f.origin.y += (screenFrame.origin.y+screenFrame.size.height)-(f.origin.y+f.size.height);
    if (f.origin.y < screenFrame.origin.y) f.origin.y = screenFrame.origin.y;

    // try keeping the same top origin
    /*if (!NSEqualRects(fo, NSZeroRect))
        if (f.origin.y+f.size.height != fo.origin.y+fo.size.height)
            f.origin.y -= (fo.origin.y+fo.size.height)-(f.origin.y+f.size.height);*/
    
    // make sure the menu is aligned with the popup button
    if ([_view isKindOfClass:[NSPopUpButton class]]) {
        NSPoint p = NSMakePoint(viewFrame.origin.x+viewFrame.size.width/2, viewFrame.origin.y+viewFrame.size.height/2);
        NSInteger d = (f.origin.y+itemHeight/2)-p.y;
        d = ABS(d);
        d = d%(int)itemHeight-PopUpWindowBorder.height;
        if (d) f.origin.y += d;
        f.origin.x -= (PopUpWindowBorder.width-6);
    }
    
    while (f.origin.y < screenFrame.origin.y)
        f.origin.y += itemHeight;
    while (f.origin.y+f.size.height > screenFrame.origin.y+screenFrame.size.height)
        f.size.height -= itemHeight;
    
    
    if (!NSEqualRects(self.window.frame, f))
        [self.window setFrame:f display:NO];
    else [self refresh];
    
    // evtl set sview frame to zerorect

    
    [self.window makeKeyAndOrderFront:self];
}

- (void)windowDidResize:(NSNotification*)notification {
    [_bgView setFrame:[_bgView.superview bounds]];
    
    [self refresh];
}

- (void)observeScrollViewContentViewBoundsDidChangeNotification:(NSNotification*)n {
    [self refresh];
}

- (void)refresh {
    if (_refreshing)
        return;
    _refreshing = YES;
    
    BOOL center = _centerOnNextRefresh;
    _centerOnNextRefresh = NO;

    
    CGFloat itemHeight = _puView.itemHeight;
    
    NSRect wf = [self.window frame];

    NSRect vf = [_bgView bounds];
    vf.origin.y += PopUpWindowBorder.height;
    vf.size.height -= PopUpWindowBorder.height*2;
    
    if (_filterField.superview) {
        vf.size.height -= _filterField.frame.size.height+FilterFieldBorder.height*2;
    }
    
    if (NSEqualRects(NSZeroRect, _sView.frame)) // initial
        [_sView setFrame:vf];

//    NSLog(@"refresh %d", _centerOnNextRefresh);

    NSRect screenFrame = [_view.window.screen visibleFrame];
    screenFrame = NSInsetRect(screenFrame, 2, 2); // stay away from screen top & bottom

    NSRect puvf = [_view.window convertRectToScreen:[_view convertRect:_view.bounds toView:nil]];
    puvf.origin.y += PopUpWindowBorder.height/2; // not sure about this... but it works...

    if (center) {
        if (_puView.highlightedCellRow >= 0 && _puView.highlightedCellRow < _puView.numberOfRows) {
//            NSLog(@"piphpih %d, %@", _puView.numberOfRows, _puView.window.menu.itemArray);
            
            NSRect r = [self.window convertRectToScreen:[_puView convertRect:[_puView cellFrameAtRow:_puView.highlightedCellRow column:0] toView:nil]];
            
            NSPoint p = _sView.contentView.bounds.origin;
            p.y += puvf.origin.y - r.origin.y;
            
            if (p.y < 0) p.y = 0;
            
            [_sView.contentView scrollToPoint:p];
            [_sView reflectScrolledClipView:_sView.contentView];
            
            // still not aligned? move the window!
            
            r = [self.window convertRectToScreen:[_puView convertRect:[_puView cellFrameAtRow:_puView.highlightedCellRow column:0] toView:nil]];
            
            CGFloat d = r.origin.y - puvf.origin.y;
            if (d) {
                wf.origin.y -= d;
                [self.window setFrame:wf display:NO];
                [_sView setFrame:vf];
            }
            
            // scrolled to white? fix it!
            
            d = (_sView.documentVisibleRect.origin.y+_sView.documentVisibleRect.size.height)-(_sView.contentView.documentRect.origin.y+_sView.contentView.documentRect.size.height);
            if (d > 0) {
                wf.origin.y += d;
                wf.size.height -= d;
                vf.size.height -= d;
                [self.window setFrame:wf display:NO];
                [_sView setFrame:vf];
            }
            d = _sView.documentVisibleRect.origin.y - _sView.contentView.documentRect.origin.y;
            if (d < 0) {
                wf.origin.y += d;
                wf.size.height -= d;
                vf.size.height -= d;
                [self.window setFrame:wf display:NO];
                [_sView setFrame:vf];
            }
        }
    }

    // make sure the window is next to the view
    
    while (wf.origin.y+wf.size.height < puvf.origin.y+puvf.size.height)
        wf.origin.y += itemHeight;
    while (wf.origin.y > puvf.origin.y)
        wf.origin.y -= itemHeight;
    
    // make sure the window hasn't grown out of the screen bounds
    
    while (wf.origin.y < screenFrame.origin.y) {
        wf.origin.y += itemHeight;
        wf.size.height -= itemHeight;
        vf.size.height -= itemHeight;
    }
    while (wf.origin.y+wf.size.height > screenFrame.origin.y+screenFrame.size.height) {
        wf.size.height -= itemHeight;
        vf.size.height -= itemHeight;
    }

    [self.window setFrame:wf display:NO];
    [_sView setFrame:vf];
    
    // are there any hidden menu items, and enough space to show them? grow out!
    
    NSRect sViewDVR = _sView.documentVisibleRect;
    CGFloat scroll = 0;
    while (true) {
        BOOL isShowingTop = (sViewDVR.origin.y <= _sView.contentView.documentRect.origin.y);
        if (!isShowingTop && wf.origin.y+wf.size.height < screenFrame.origin.y+screenFrame.size.height-itemHeight) {
            wf.size.height += itemHeight;
            vf.size.height += itemHeight;
            sViewDVR.size.height += itemHeight;
            sViewDVR.origin.y -= itemHeight;
            scroll -= itemHeight;
        } else {
            BOOL isShowingBottom = (sViewDVR.origin.y+sViewDVR.size.height >= _sView.contentView.documentRect.origin.y+_sView.contentView.documentRect.size.height);
            if (!isShowingBottom && wf.origin.y > screenFrame.origin.y+itemHeight) {
                wf.size.height += itemHeight;
                wf.origin.y -= itemHeight;
                vf.size.height += itemHeight;
                sViewDVR.size.height += itemHeight;
            } else break;
        }
    }
    
    [self.window setFrame:wf display:NO];
    [_sView setFrame:vf];
    if (scroll) {
        NSPoint p = _sView.contentView.bounds.origin;
        p.y += scroll;
        [_sView.contentView scrollToPoint:p];
        [_sView reflectScrolledClipView:_sView.contentView];
    }

    
    
//    {
//        BOOL isShowingBottom = (_sView.documentVisibleRect.origin.y+_sView.documentVisibleRect.size.height >= _sView.contentView.documentRect.origin.y+_sView.contentView.documentRect.size.height);
//        BOOL isShowingTop = (!_topScrollButton.superview && _sView.documentVisibleRect.origin.y <= _sView.contentView.documentRect.origin.y) || (_topScrollButton.superview && _sView.documentVisibleRect.origin.y <= _sView.contentView.documentRect.origin.y+itemHeight);
//        NSLog(@"%@ --- %@ --- %d %d --- %@", NSStringFromRect(_sView.documentVisibleRect), NSStringFromRect(_sView.contentView.documentRect), isShowingTop, isShowingBottom, NSStringFromRect(sViewDVR));
//    }
    
    
//    scroll = 0;
    
    BOOL isShowingBottom = (_sView.documentVisibleRect.origin.y+_sView.documentVisibleRect.size.height >= _sView.contentView.documentRect.origin.y+_sView.contentView.documentRect.size.height);
    if (!isShowingBottom) {
        if (!_bottomScrollButton.superview) {
            [_bgView addSubview:_bottomScrollButton];
//            scroll += itemHeight;
        }
        [_bottomScrollButton setFrame:NSMakeRect(vf.origin.x, vf.origin.y, vf.size.width, itemHeight)];
        vf.origin.y += itemHeight;
        vf.size.height -= itemHeight;
    } else {
        if (_bottomScrollButton.superview) {
            [_bottomScrollButton removeFromSuperview];
//            scroll += itemHeight;
        }
    }
    
    BOOL isShowingTop = (!_topScrollButton.superview && _sView.documentVisibleRect.origin.y <= _sView.contentView.documentRect.origin.y) || (_topScrollButton.superview && _sView.documentVisibleRect.origin.y <= _sView.contentView.documentRect.origin.y+itemHeight);
    if (!isShowingTop) {
        if (!_topScrollButton.superview) {
            [_bgView addSubview:_topScrollButton];
//            scroll += itemHeight;
        }
        [_topScrollButton setFrame:NSMakeRect(vf.origin.x, vf.origin.y+vf.size.height-itemHeight, vf.size.width, itemHeight)];
        vf.size.height -= itemHeight;
    } else {
        if (_topScrollButton.superview) {
            [_topScrollButton removeFromSuperview];
        }
    }
    
    [_sView setFrame:vf];
//    [_sView setNeedsDisplay:YES];
    
//    NSLog(@"%@ --- %@ --- %d %d --- %@", NSStringFromRect(_sView.documentVisibleRect), NSStringFromRect(_sView.contentView.documentRect), isShowingTop, isShowingBottom, NSStringFromRect(vf));

    
//    if (scroll) {
//        NSPoint p = _sView.contentView.bounds.origin;
//        p.y += scroll;
//        [_sView.contentView scrollToPoint:p];
//        [_sView reflectScrolledClipView:_sView.contentView];
//    }
    
    if (center) {
        if (_puView.highlightedCellRow != NSNotFound) {
            NSRect r = [self.window convertRectToScreen:[_puView convertRect:[_puView cellFrameAtRow:_puView.highlightedCellRow column:0] toView:nil]];
            
            NSPoint p = _sView.contentView.bounds.origin;
            p.y += puvf.origin.y - r.origin.y;
            
            if (p.y < 0) p.y = 0;
            
            [_sView.contentView scrollToPoint:p];
            [_sView reflectScrolledClipView:_sView.contentView];
        }
    }
    
//    NSLog(@"%@ --- %@ --- %d %d --- %@", NSStringFromRect(_sView.documentVisibleRect), NSStringFromRect(_sView.contentView.documentRect), isShowingTop, isShowingBottom, NSStringFromRect(vf));
    
    
    
    if (_filterField.superview) {
        [_filterField setFrame:NSMakeRect(vf.origin.x+FilterFieldBorder.width, wf.size.height-PopUpWindowBorder.height-_filterField.frame.size.height-FilterFieldBorder.height, vf.size.width-FilterFieldBorder.width*2, _filterField.frame.size.height)];
    }

    
//    if (!_noMouseMovedToWindowLocationOnNextRefresh)
        NSRect r = {[NSEvent mouseLocation], NSZeroSize};
        [_puView mouseMovedToWindowLocation:[self.window convertRectFromScreen:r].origin];
//    --_noMouseMovedToWindowLocationOnNextRefresh;
  
    _refreshing = NO;
//    NSLog(@"%@ --- %@", NSStringFromRect(_sView.documentVisibleRect), NSStringFromRect(_sView.contentView.documentRect));
}

- (BOOL)interceptEvent:(NSEvent*)event {
    if (_filterField.superview)
        return NO;
    
//    NSLog(@"event %d", event.type);

    if (event.type == NSKeyDown) {
        [self keyDown:event];
        return YES;
    }
    
    if (event.type == NSLeftMouseDragged) {
        [_puView mouseDragged:event];
        return YES;
    }
    
    if (event.type == NSLeftMouseUp) {
        [_puView mouseUp:event];
        return YES;
    }
    
    return NO;
}

- (void)keyDown:(NSEvent*)event {
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (BOOL)maybeDoCommandBySelector:(SEL)command {
//    NSLog(@"doCommandBySelector: %@", NSStringFromSelector(command));

    if ([self respondsToSelector:command]) {
        [self performSelector:command withObject:self];
        return YES;
    } else if ([[self.window.windowController puView] respondsToSelector:command]) {
        [[self.window.windowController puView] performSelector:command withObject:self];
        return YES;
    }
  
    return NO;
}

- (void)doCommandBySelector:(SEL)command {
    [self maybeDoCommandBySelector:command];
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)command {
    if (command == @selector(moveRight:) || command == @selector(moveLeft:))
        return NO;
    return [self maybeDoCommandBySelector:command];
}

- (void)insertText:(NSString*)str {
    _filterField.stringValue = str;
    
    if (!_filterField.superview) {
        [_bgView addSubview:_filterField];
        [self update:NO];
    }
    
    [self.window makeFirstResponder:_filterField];
    [[self.window fieldEditor:YES forObject:_filterField] setSelectedRange:NSMakeRange(str.length, 0)];
}

- (void)cancelOperation:(id)sender {
    if (_filterField.superview) {
        _filterField.stringValue = @"";
        [_filterField removeFromSuperview];
        [self update:NO];
        [self filter];
    } else {
        [self.window close];
    }
}

- (void)insertNewline:(id)sender {
    [self selectHighlighted];
}

- (void)selectHighlighted {
    if (_puView.highlightedCellRow != NSNotFound) {
        NSInteger tag = [[_puView.cells objectAtIndex:_puView.highlightedCellRow] tag];
        
//        NSLog(@"selectHighlighted -> tag is %08x", tag);
        
        if ([_view isKindOfClass:[NSPopUpButton class]]) {
            [_view willChangeValueForKey:@"selectedTag"];
            [(NSPopUpButton*)_view selectItemWithTag:tag];
            [_view didChangeValueForKey:@"selectedTag"];
        }
        
        NSMenuItem* mi = [_menu itemWithTag:tag];
        [mi.target performSelector:mi.action withObject:mi];
    }
    
    [self.window close];
}

- (void)controlTextDidChange:(NSNotification*)notification {
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(filter) withObject:nil afterDelay:(notification? 0.1 : 0) inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]]; // TODO: get system key delay preference
    if (!notification)
        [[self.window fieldEditor:YES forObject:_filterField] setSelectedRange:NSMakeRange(0, _filterField.stringValue.length)];
}

- (void)filter {
    [self filter:NO];
}

- (void)filter:(BOOL)center {
    NSArray* words = nil;
    if (_filterField.superview)
        words = [_filterField.stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
//    NSLog(@"Words: %@", words);
    
    NSMutableArray* lcwords = [NSMutableArray array];
    for (NSString* word in words)
        if (word.length)
            [lcwords addObject:word.lowercaseString];
    
    BOOL somethingIsAvailable = NO;
    for (NSMenuItem* mi in _menu.itemArray) {
        NSString* lctitle = mi.title.lowercaseString;
        BOOL matchedAllWords = YES;
        for (NSString* word in lcwords)
            if (word.length) {
                if (![lctitle contains:word])
                    matchedAllWords = NO;
            }
        
        mi.hidden = !matchedAllWords;
        
        if (matchedAllWords)
            somethingIsAvailable = YES;
    }
    
    if (!somethingIsAvailable)
        [[self.window fieldEditor:YES forObject:_filterField] setSelectedRange:NSMakeRange(0, _filterField.stringValue.length)];
    
    [self update:center];
}

@end


@implementation N2PopUpMatrixCell

@synthesize tag = _tag;

- (void)drawWithFrame:(NSRect)cellFrame inView:(N2PopUpMatrix*)controlView {
    [NSGraphicsContext.currentContext saveGraphicsState];
    
    NSDictionary* attributes = nil;
    if (self.isHighlighted) {
        [[[NSColor selectedMenuItemColor] colorWithAlphaComponent:1] setFill];
        [NSBezierPath fillRect:NSInsetRect(cellFrame, -1, 0)];
        attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor selectedMenuItemTextColor], NSForegroundColorAttributeName, controlView.font, NSFontAttributeName, nil];
    } else {
        attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor controlTextColor], NSForegroundColorAttributeName, controlView.font, NSFontAttributeName, nil];
    }

    [self setAttributedStringValue:[[NSAttributedString alloc] initWithString:self.title attributes:attributes]];

    cellFrame.origin.y += 1;

    if (self.state) {
        NSRect cmrect = cellFrame; cmrect.origin.x += 5;
        [[[NSAttributedString alloc] initWithString:@"✓" attributes:attributes] drawInRect:cmrect];
    }
    
    cellFrame.origin.x += 9;

    cellFrame.size.width += PopUpWindowBorder.width; // see insetrect in next line...
    [super drawWithFrame:NSInsetRect(cellFrame, PopUpWindowBorder.width, 0) inView:controlView];
    
    [NSGraphicsContext.currentContext restoreGraphicsState];
}

@end


@implementation N2PopUpMatrix

@synthesize itemHeight = _itemHeight;
@synthesize highlightedCellRow = _highlightedCellRow;

- (void)setHighlightedCellRow:(NSInteger)highlightedCellRow {
    _highlightedCellRow = highlightedCellRow;
}

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self addTrackingArea:[[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingAssumeInside|NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingActiveAlways|NSTrackingInVisibleRect|NSTrackingEnabledDuringMouseDrag owner:self userInfo:nil] autorelease]];
        _itemHeight = 16;
        _minItemWidth = 120;
        _highlightedCellRow = NSNotFound;
        self.cellClass = [N2PopUpMatrixCell class];
        self.intercellSpacing = NSMakeSize(0,0);
        [self setDrawsBackground:NO];
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)sizeToCells {
    NSArray* mis = [[self.window.menu itemArray] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isHidden = NO"]];
    
    NSDictionary* attributes = [NSDictionary dictionaryWithObject:self.font forKey:NSFontAttributeName];
    
    [self renewRows:mis.count columns:1]; // +1 ??? wtf??? but if we don't, the last cell is never displayed..
    CGFloat maxw = _minItemWidth;
    for (size_t i = 0; i < mis.count; ++i) {
        NSMenuItem* mi = [mis objectAtIndex:i];
        NSCell* cell = [self cellAtRow:i column:0];
        
        [cell setTitle:mi.title];
        [cell setRepresentedObject:mi.representedObject];
        [cell setTag:mi.tag];
        [cell setState:mi.state];
        
        maxw = MAX(maxw, [mi.title sizeWithAttributes:attributes].width);
    }
    
    self.cellSize = NSMakeSize(maxw+PopUpWindowBorder.width*2+9, _itemHeight); // 9 for the checkmarks
    
    [super sizeToCells];
}

- (NSRect)adjustScroll:(NSRect)rect {
//    if (rect.origin.y < _itemHeight*2)
//        if (rect.origin.y > _itemHeight)
//            rect.origin.y = _itemHeight*2;
//        else rect.origin.y = 0;
    rect.origin.y = ((int)(rect.origin.y/_itemHeight))*_itemHeight;
    return rect;
}

- (BOOL)acceptsFirstMouse {
    return YES;
}

- (void)mouseMoved:(NSEvent*)event {
    [self mouseMovedToWindowLocation:[event locationInWindow]];
}

- (void)mouseDragged:(NSEvent*)event {
    [self mouseMovedToWindowLocation:[event locationInWindow]];
}

- (void)mouseMovedToWindowLocation:(NSPoint)windowLocation {
    NSInteger row, col;
    
    if (![self getRow:&row column:&col forPoint:[self convertPoint:windowLocation fromView:nil]])
        row = NSNotFound;
    
    [self highlightItemAtRow:row scroll:NO];
}

- (void)highlightItemAtRow:(NSInteger)row scroll:(BOOL)scroll {
//    if (row == _highlightedCellRow)
//        return;
    
    if (_highlighting)
        return;
    _highlighting = YES;
    
//    NSLog(@"hilite %d (%d)", row, self.numberOfRows);
    
    if (_highlightedCellRow != NSNotFound) {
        [self highlightCell:NO atRow:_highlightedCellRow column:0];
    }
    
    if (row != NSNotFound) {
        if (scroll) {
            [self.window.windowController incNoMouseMovedToWindowLocationOnNextRefresh];
            [self scrollCellToVisibleAtRow:row column:0];
        }
        [self highlightCell:YES atRow:row column:0];
        if (scroll) {
            [self scrollCellToVisibleAtRow:row column:0];
        }
    }
    
    for (NSInteger r = 0; r < self.numberOfRows; ++r) // this should not be necessary, however...
        [self highlightCell:(r == row) atRow:r column:0];
    
    _highlightedCellRow = row;
    
    _highlighting = NO;
}

- (void)mouseEntered:(NSEvent*)event {
    [self mouseMoved:event];
}

- (void)mouseExited:(NSEvent*)event {
    [self mouseMoved:event];
}

- (void)mouseDown:(NSEvent*)event {
//    if ([[self cellAtRow:_highlightedCellRow column:0] trackMouse:event inRect:[self cellFrameAtRow:_highlightedCellRow column:0] ofView:self untilMouseUp:YES])
//        if (NSPointInRect([NSEvent mouseLocation], [self.window convertRectToScreen:[self convertRect:[self cellFrameAtRow:_highlightedCellRow column:0] toView:nil]]))
//            [self.window.windowController selectHighlighted];
}

- (void)mouseUp:(NSEvent*)event {
    if (event.timestamp - [self.window.windowController startTime] > 0.1666)
        if (_highlightedCellRow != NSNotFound)
            [self.window.windowController selectHighlighted];
}

- (NSScrollView*)containingScrollView {
    for (NSView* v = self; v; v = v.superview)
        if ([v isKindOfClass:[NSScrollView class]])
            return (NSScrollView*)v;
    return nil;
}

- (void)scrollLineUp:(id)sender {
//    NSLog(@"scrollLineUp");
    NSPoint p = self.containingScrollView.contentView.bounds.origin;
    p.y -= _itemHeight;
    [self.containingScrollView.contentView scrollToPoint:p];
    [self.containingScrollView reflectScrolledClipView:self.containingScrollView.contentView];
//    [self.window.windowController refresh];
}

- (void)scrollLineDown:(id)sender {
//    NSLog(@"scrollLineDown");
    NSPoint p = self.containingScrollView.contentView.bounds.origin;
    p.y += _itemHeight;
    [self.containingScrollView.contentView scrollToPoint:p];
    [self.containingScrollView reflectScrolledClipView:self.containingScrollView.contentView];
  //  [self.window.windowController refresh];
}

- (void)scrollPageUp:(id)sender {
    NSView* puView = [self.window.windowController puView];
    NSRect b = self.containingScrollView.contentView.bounds;
    NSPoint p = b.origin, po = p;
    p.y -= b.size.height-_itemHeight;
    if (po.y+b.size.height+_itemHeight == puView.frame.size.height)
        p.y += _itemHeight;
    if (p.y == _itemHeight)
        p.y -= _itemHeight;
    if (p.y < 0)
        p.y = 0;
    [self.containingScrollView.contentView scrollToPoint:p];
    [self.containingScrollView reflectScrolledClipView:self.containingScrollView.contentView];// TODO: grow window to max height, then scroll
//    [self.window.windowController refresh];
}

- (void)scrollPageDown:(id)sender {
    NSView* puView = [self.window.windowController puView];
    NSRect b = self.containingScrollView.contentView.bounds;
    NSPoint p = b.origin;
    p.y += b.size.height-_itemHeight;
//    if (p.y+b.size.height == puView.frame.size.height-_itemHeight)
//        p.y += _itemHeight;
    if (p.y+b.size.height > puView.frame.size.height)
        p.y = puView.frame.size.height - b.size.height;
    [self.containingScrollView.contentView scrollToPoint:p];
    [self.containingScrollView reflectScrolledClipView:self.containingScrollView.contentView];// TODO: grow window to max height, then scroll
//    [self.window.windowController refresh];
}

- (void)scrollToBeginningOfDocument:(id)sender {
    [self.containingScrollView.contentView scrollToPoint:NSMakePoint(0,0)];
    [self.containingScrollView reflectScrolledClipView:self.containingScrollView.contentView]; // TODO: grow window to max height, then scroll
//    [self.window.windowController refresh];
}

- (void)scrollToEndOfDocument:(id)sender {
    NSView* puView = [self.window.windowController puView];
    NSRect b = self.containingScrollView.contentView.bounds;
    NSPoint p = NSMakePoint(0, puView.frame.size.height);
    if (p.y+b.size.height > puView.frame.size.height)
        p.y = puView.frame.size.height - b.size.height;
    [self.containingScrollView.contentView scrollToPoint:p];
    [self.containingScrollView reflectScrolledClipView:self.containingScrollView.contentView]; // TODO: grow window to max height, then scroll
//    [self.window.windowController refresh];
    if (sender)
        [self scrollToEndOfDocument:nil]; // this is ugly...
}

- (void)moveUp:(id)sender {
    NSInteger row = _highlightedCellRow;
    if (row == NSNotFound)
        row = self.numberOfRows-1;
    else if (row == 0)
        return;
    else --row;
    [self highlightItemAtRow:row scroll:YES];
    
}

- (void)moveDown:(id)sender {
    NSInteger row = _highlightedCellRow;
    if (row == NSNotFound)
        row = 0;
    else if (row == self.numberOfRows-1)
        return;
    else ++row;
    [self highlightItemAtRow:row scroll:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

@end


@implementation N2PopUpScrollView

@synthesize target = _target;
@synthesize action = _action;

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self addTrackingArea:[[[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited|NSTrackingActiveAlways|NSTrackingInVisibleRect|NSTrackingEnabledDuringMouseDrag owner:self userInfo:nil] autorelease]];
    }
    
    return self;
}

- (void)dealloc {
    [_timer invalidate];
    [super dealloc];
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
}

- (void)setTop {
    _bottom = NO;
}

- (void)setBottom {
    _bottom = YES;
}

- (void)mouseEntered:(NSEvent*)event {
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES]; // 0.05
}

- (void)mouseExited:(NSEvent*)event {
    [_timer invalidate];
    _timer = nil;
}

- (void)timerFire:(NSTimer*)timer {
    [self sendAction:self.action to:self.target];
    if (!self.superview)
        [self mouseExited:[NSApp currentEvent]];
}

- (void)drawRect:(NSRect)dirtyRect {
    [NSGraphicsContext.currentContext saveGraphicsState];
    
    NSRect r = [self bounds];
    CGFloat mins = MIN(r.size.width, r.size.height)*0.45, minw = mins*sqrt(2);
    r = NSMakeRect(r.origin.x+(r.size.width-minw)/2, r.origin.y+(r.size.height-mins)/2, minw, mins);
    
    NSBezierPath* path = [NSBezierPath bezierPath];
    if (_bottom) {
        r.origin.y -= 2;
        [path moveToPoint:NSMakePoint(r.origin.x, r.origin.y+r.size.height)];
        [path lineToPoint:NSMakePoint(r.origin.x+r.size.width, r.origin.y+r.size.height)];
        [path lineToPoint:NSMakePoint(r.origin.x+r.size.width/2, r.origin.y)];
    } else {
        r.origin.y += 2;
        [path moveToPoint:r.origin];
        [path lineToPoint:NSMakePoint(r.origin.x+r.size.width, r.origin.y)];
        [path lineToPoint:NSMakePoint(r.origin.x+r.size.width/2, r.origin.y+r.size.height)];
    }
    
    [path closePath];
    
    [[NSColor controlTextColor] setFill];
    [path fill];

    [NSGraphicsContext.currentContext restoreGraphicsState];
}

@end

@implementation N2PopUpMenuWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (void)sendEvent:(NSEvent*)event {
    if (![self.windowController interceptEvent:event])
        [super sendEvent:event];
}

@end


@implementation N2PopUpMenuWindowView

- (void)drawRect:(NSRect)dirtyRect {
    [NSGraphicsContext saveGraphicsState];
    
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:4 yRadius:4];
    [[[NSColor whiteColor] colorWithAlphaComponent:0.99] setFill];
    [path fill];
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
