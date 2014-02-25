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

#import "O2ScreensPrefsView.h"
#import "NSUserDefaults+OsiriX.h"
#import "N2Operators.h"
#import "NSScreen+N2.h"

@interface _O2ScreensPrefsViewScreenRecord : NSObject {
    NSRect _frame;
    NSScreen* _screen;
}

@property NSRect frame;
@property(retain) NSScreen* screen;

@end

@implementation O2ScreensPrefsView

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _records = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeAppDidChangeScreenParamsNotification:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_records release];
    [super dealloc];
}

-(void)observeAppDidChangeScreenParamsNotification:(NSNotification*)n {
    [_records removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)refreshframe {
    [[NSGraphicsContext currentContext] saveGraphicsState];

    if (!_records.count) {
        NSArray* screens = [NSScreen screens];
        
        NSRect desktopBounds = [[screens objectAtIndex:0] frame];
        for (NSUInteger i = 1; i < screens.count; ++i)
            desktopBounds = NSUnionRect(desktopBounds, [[screens objectAtIndex:i] frame]);
        
        NSRect bounds = [self bounds];
        bounds.size.width -= 1; bounds.size.height -= 1;
        bounds.size = N2ProportionallyScaleSize(desktopBounds.size, bounds.size);

        NSInteger width = bounds.size.width, height = bounds.size.height;

        [[NSColor blackColor] setStroke];
        
        for (NSScreen* screen in screens) {
            NSRect screenFrame = [screen frame];
            NSRect frame = NSIntegralRect(NSMakeRect(bounds.origin.x+(screenFrame.origin.x-desktopBounds.origin.x)/desktopBounds.size.width*width, bounds.origin.y+(screenFrame.origin.y-desktopBounds.origin.y)/desktopBounds.size.height*height, screenFrame.size.width/desktopBounds.size.width*width, screenFrame.size.height/desktopBounds.size.height*height));
            frame.origin.x += 0.5; frame.origin.y += 0.5; frame.size.width -= 1; frame.size.height -= 1;
            
            if (self.isFlipped)
                frame = N2FlipRect(frame, bounds);
            
            _O2ScreensPrefsViewScreenRecord* record = [[_O2ScreensPrefsViewScreenRecord new] autorelease];
            record.screen = screen;
            record.frame = frame;
            
            [_records addObject:record];
        }
    }
    
    [[NSGraphicsContext currentContext] setShouldAntialias:YES];
    
    NSArray* viewerScreens = [[NSUserDefaults standardUserDefaults] screensUsedForViewers];
    NSArray* screens = [NSScreen screens];
    for (int phase = 0; phase < 2; ++phase)
        for (_O2ScreensPrefsViewScreenRecord* record in _records) {
            if (phase == 0 && [viewerScreens containsObject:record.screen])
                continue;
            if (phase == 1 && ![viewerScreens containsObject:record.screen])
                continue;
            
            [[NSColor blackColor] setStroke];
            
            if (!viewerScreens.count)
                if ([self isEnabled])
                    [[NSColor colorWithDeviceRed:113./255 green:142./255 blue:170.5/255 alpha:1] setFill];
                else [[NSColor colorWithDeviceWhite:141.83/255 alpha:1] setFill];
            else if ([viewerScreens containsObject:record.screen])
                if ([self isEnabled])
                    [[NSColor colorWithDeviceRed:99./255 green:157./255 blue:214./255 alpha:1] setFill];
                else [[NSColor colorWithDeviceWhite:156.67/255 alpha:1] setFill];
            else [[NSColor lightGrayColor] setFill];
            
            NSRect frame = record.frame;

            NSBezierPath* path = [NSBezierPath bezierPathWithRect:frame];
            [path fill]; [path stroke];
            
            if (record.screen == [screens objectAtIndex:0]) {
                NSRect menuFrame;
                NSDivideRect(frame, &menuFrame, &frame, 4, self.isFlipped? NSMinYEdge : NSMaxYEdge);
                path = [NSBezierPath bezierPathWithRect:menuFrame];
                [[NSColor whiteColor] setFill];
                [path fill]; [path stroke];
            }
            
            if (record == _activeRecord) {
                frame.origin.x += 1.5; frame.origin.y += 1.5; frame.size.width -= 3; frame.size.height -= 3;
                path = [NSBezierPath bezierPathWithRect:frame];
                [[NSColor grayColor] setStroke];
                [path stroke];
            }
        }

    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

-(_O2ScreensPrefsViewScreenRecord*)recordAtPoint:(NSPoint)p {
    NSMutableArray* t = [NSMutableArray array];
    for (_O2ScreensPrefsViewScreenRecord* record in _records)
        if (NSPointInRect(p, record.frame))
            [t addObject:record];
    
    for (_O2ScreensPrefsViewScreenRecord* s in t)
        if ([[NSUserDefaults standardUserDefaults] screenIsUsedForViewers:s.screen])
            return s;
    
    if (t.count)
        return [t objectAtIndex:0];
    
    return nil;
}

-(BOOL)prefersTrackingUntilMouseUp {
    return YES;
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    [self mouseDown:theEvent];
}

- (void)mouseDown:(NSEvent*)theEvent
{
    if (![self isEnabled])
        return;
    
	NSPoint currentPoint = [theEvent locationInWindow];
//	BOOL trackContinously = [self startTrackingAt:currentPoint inView:controlView];
	
    _O2ScreensPrefsViewScreenRecord* record = [self recordAtPoint:[self convertPoint:currentPoint fromView:nil]];
    if (!record)
        return;
    
    _activeRecord = record;
    [self display];

    NSArray* viewerScreens = [[NSUserDefaults standardUserDefaults] screensUsedForViewers];

    NSMenu* menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    NSMenuItem* mi;
    
    [menu addItemWithTitle:[record.screen displayName] action:nil keyEquivalent:@""];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    mi = [menu addItemWithTitle:NSLocalizedString(@"Use this screen for viewers", nil) action:@selector(_toggleViewersOnScreen:) keyEquivalent:@""];
    mi.state = [viewerScreens containsObject:record.screen]? NSOnState : NSOffState;
    mi.representedObject = record;
    mi.target = self;
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSArray* screens = [NSScreen screens];
    
    if (!(viewerScreens.count == [screens count])) {
        mi = [menu addItemWithTitle:NSLocalizedString(@"Use all screens for viewers", nil) action:@selector(_useAllScreensForViewers:) keyEquivalent:@""];
        mi.target = self;
    }
    
    if (!(viewerScreens.count == 1 && [viewerScreens objectAtIndex:0] == [screens objectAtIndex:0])) {
        mi = [menu addItemWithTitle:NSLocalizedString(@"Only use the current main screen for viewers", nil) action:@selector(_useMainScreenForViewers:) keyEquivalent:@""];
        mi.target = self;
    }
    
    [NSMenu popUpContextMenu:menu withEvent:theEvent forView:self];
    
    _activeRecord = nil;
    [self display];
}

//-(NSString*)toolTip {
//    return NSLocalizedString(@"Click on every screen's thumbnail to enable or disable its usage", nil);
//}

-(void)_toggleViewersOnScreen:(NSMenuItem*)mi {
    _O2ScreensPrefsViewScreenRecord* record = mi.representedObject;
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud screen:record.screen setIsUsedForViewers:![ud screenIsUsedForViewers:record.screen]];
}

-(void)_useAllScreensForViewers:(NSMenuItem*)mi {
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:O2NonViewerScreensDefaultsKey];
}

-(void)_useMainScreenForViewers:(NSMenuItem*)mi {
    NSArray* screens = [NSScreen screens];
    for (NSScreen* screen in screens)
        [[NSUserDefaults standardUserDefaults] screen:screen setIsUsedForViewers:(screen == [screens objectAtIndex:0])];
}

@end

@implementation _O2ScreensPrefsViewScreenRecord

@synthesize frame = _frame;
@synthesize screen = _screen;

-(void)dealloc {
    [_screen release];
    [super dealloc];
}

@end