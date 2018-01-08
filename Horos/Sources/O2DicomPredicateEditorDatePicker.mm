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

#import "O2DicomPredicateEditorDatePicker.h"
#import "N2Operators.h"


@implementation O2DicomPredicateEditorDatePicker

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.datePickerStyle = NSTextFieldAndStepperDatePickerStyle;
        self.backgroundColor = [NSColor whiteColor];
        self.drawsBackground = YES;
        self.bezeled = YES;
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_helperWindow release];
    [super dealloc];
}

- (NSWindow*)helperWindow {
    if (_helperWindow)
        return _helperWindow;
    
    NSDatePicker* dp = [[[NSDatePicker alloc] initWithFrame:NSZeroRect] autorelease];
    [dp.cell setControlSize:[self.cell controlSize]];
    dp.font = self.font;
    dp.datePickerElements = self.datePickerElements;
    dp.datePickerStyle = NSClockAndCalendarDatePickerStyle;
    //dp.backgroundColor = [NSColor grayColor];
    //dp.drawsBackground = YES;
    dp.bezeled = NO;
    
    NSDictionary* binding = [self infoForBinding:@"value"];
    [dp bind:@"value" toObject:[binding objectForKey:NSObservedObjectKey] withKeyPath:[binding objectForKey:NSObservedKeyPathKey] options:[binding objectForKey:NSOptionsKey]];
    
    static const CGFloat kBorderThicknessX = 5, kBorderThicknessY = 2;
    [dp sizeToFit];
    [dp setFrameOrigin:NSMakePoint(kBorderThicknessX, kBorderThicknessY)];
    
    NSRect cwr = NSMakeRect(0, 0, dp.frame.size.width+kBorderThicknessX*2, dp.frame.size.height+kBorderThicknessY*2);
    
    _helperWindow = [[NSWindow alloc] initWithContentRect:cwr styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [_helperWindow.contentView addSubview:dp];
    _helperWindow.backgroundColor = [NSColor grayColor];//[NSColor whiteColor];
    _helperWindow.hasShadow = YES;
  //  _helperWindow.isOpaque = NO;
    
    return _helperWindow;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if (!self.window) {
        [self hideHelper];
        [NSNotificationCenter.defaultCenter removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
    } else {
        for (NSView* view = self; view; view = view.superview) {
            [view setPostsFrameChangedNotifications:YES];
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeViewRectDidChangeNotification:) name:NSViewFrameDidChangeNotification object:view];
            [view setPostsBoundsChangedNotifications:YES];
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeViewRectDidChangeNotification:) name:NSViewBoundsDidChangeNotification object:view];
        }
    }
}

- (void)showHelper {
    NSWindow* cw = self.helperWindow;
    
    NSRect tfr = [self convertRect:self.bounds toView:nil];
    tfr.origin += self.window.frame.origin;
    tfr.origin.x += (self.frame.size.width-cw.frame.size.width)/2;
    tfr.origin.y -= cw.frame.size.height;
    
    if (cw.parentWindow)
        [cw.parentWindow removeChildWindow:cw];
    
    [cw setFrameOrigin:tfr.origin];
    
    if (![cw isVisible])
        [cw orderFront:self];
    
    [self.window addChildWindow:cw ordered:NSWindowAbove];
}

- (void)hideHelper {
    NSWindow* cw = self.helperWindow;

    if ([cw isVisible]) {
        [self.window removeChildWindow:cw];
        [cw orderOut:self];
    }
}

- (BOOL)becomeFirstResponder {
    BOOL r = [super becomeFirstResponder];
    if (r)
        [self showHelper];
    return r;
}

- (BOOL)resignFirstResponder {
    BOOL r = [super resignFirstResponder];
    if (r)
        [self hideHelper];
    return r;
}

- (void)keyDown:(NSEvent*)e {
    if (e.keyCode == 49 || e.keyCode == 53 || e.keyCode == 76 || e.keyCode == 36) { // esc,return,space,enter
        if (self.helperWindow.isVisible)
            [self hideHelper];
        else [self showHelper];
    }
    
    [super keyDown:e];
}

- (void)mouseDown:(NSEvent*)e {
    if (e.clickCount == 2) {
        if (self.helperWindow.isVisible)
            [self hideHelper];
        else [self showHelper];
    }
    
    [super mouseDown:e];
}

- (void)observeViewRectDidChangeNotification:(NSNotification*)notification {
    if (self.helperWindow.isVisible)
        [self showHelper];
}

@end
