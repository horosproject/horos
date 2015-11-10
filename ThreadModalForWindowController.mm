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


#import "ThreadModalForWindowController.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "N2Debug.h"
#import "NSTextView+N2.h"


NSString* const NSThreadModalForWindowControllerKey = @"ThreadModalForWindowController";


@implementation ThreadModalForWindowController

@synthesize thread = _thread;
@synthesize docWindow = _docWindow;
@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize backgroundButton = _backgroundButton;
@synthesize titleField = _titleField;
@synthesize statusField = _statusField;
@synthesize statusFieldScroll = _statusFieldScroll;
@synthesize progressDetailsField = _progressDetailsField;

-(id)initWithThread:(NSThread*)thread window:(NSWindow*)docWindow {
	self = [super initWithWindowNibName:@"ThreadModalForWindow"];
	
	_docWindow = [docWindow retain];
	_thread = [thread retain];
    _isValid = YES;
    _lastDisplayedProgress = -1;
    _retainedThreadDictionary = [thread.threadDictionary retain];
    
    self.cancelButton.title = NSLocalizedString( @"Cancel", nil);
    self.backgroundButton.title = NSLocalizedString( @"Background", nil);
    
	[thread.threadDictionary setObject:self forKey:NSThreadModalForWindowControllerKey];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExitNotification:) name:NSThreadWillExitNotification object:_thread];

	[NSApp beginSheet:self.window modalForWindow:self.docWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    
	[self retain];

	return self;	
}

static NSString* ThreadModalForWindowControllerObservationContext = @"ThreadModalForWindowControllerObservationContext";

-(void)awakeFromNib {
	[self.progressIndicator setMinValue:0];
	[self.progressIndicator setMaxValue:1];
	[self.progressIndicator setUsesThreadedAnimation:YES];
    [self.progressIndicator setIndeterminate:YES];
	[self.progressIndicator startAnimation:self];
	
//  [self.titleField bind:@"value" toObject:self.thread withKeyPath:NSThreadNameKey options:NULL];
//  [self.window bind:@"title" toObject:self.thread withKeyPath:NSThreadNameKey options:NULL];
//    [self.statusField bind:@"string" toObject:self.thread withKeyPath:NSThreadStatusKey options:NULL];
//    [self.progressDetailsField bind:@"value" toObject:self.thread withKeyPath:NSThreadProgressDetailsKey options:NULL];
//    [self.cancelButton bind:@"hidden" toObject:self.thread withKeyPath:NSThreadSupportsCancelKey options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
//	[self.cancelButton bind:@"hidden2" toObject:self.thread withKeyPath:NSThreadIsCancelledKey options:NULL];
//	[self.backgroundButton bind:@"hidden" toObject:self.thread withKeyPath:NSThreadSupportsBackgroundingKey options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
	
	[self.thread addObserver:self forKeyPath:NSThreadProgressKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadNameKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadStatusKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadProgressDetailsKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadSupportsCancelKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadIsCancelledKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadSupportsBackgroundingKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
    
    if (!self.docWindow && [NSThread isMainThread]) {
        [self.window center];
        [NSApp activateIgnoringOtherApps:YES];
        [self.window makeKeyAndOrderFront:self];
    }
}

-(void)sheetDidEndOnMainThread:(NSWindow*)sheet
{
	[sheet orderOut:self];
//	[NSApp endSheet:sheet];
	[self autorelease];
}

-(void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[self performSelectorOnMainThread:@selector(sheetDidEndOnMainThread:) withObject:sheet waitUntilDone:NO];
}

-(void)dealloc {
	DLog(@"[ThreadModalForWindowController dealloc]");
	
    [_lastPositionedStatus release];
    
	[self.thread removeObserver:self forKeyPath:NSThreadProgressKey];
	[self.thread removeObserver:self forKeyPath:NSThreadNameKey];
	[self.thread removeObserver:self forKeyPath:NSThreadStatusKey];
	[self.thread removeObserver:self forKeyPath:NSThreadProgressDetailsKey];
	[self.thread removeObserver:self forKeyPath:NSThreadSupportsCancelKey];
	[self.thread removeObserver:self forKeyPath:NSThreadIsCancelledKey];
    [self.thread removeObserver:self forKeyPath:NSThreadSupportsBackgroundingKey];
	
    [_retainedThreadDictionary release]; _retainedThreadDictionary = nil;
	[_thread release];
	[_docWindow release];
	
	[super dealloc]; 
}

-(void)repositionViews {
    CGFloat p = 0;
    NSRect frame, oframe;
    
    /* position buttons horizontally */ {
        CGFloat p = 14, w = self.window.frame.size.width;
        for (NSButton* button in [NSArray arrayWithObjects: self.backgroundButton, self.cancelButton, nil]) {
            if (![button isHidden]) {
                oframe = frame = button.frame;
                p += frame.size.width;
                frame.origin.x = w-p;
                if (!NSEqualRects(frame, oframe)) [button setFrame:frame];
                p += 6;
            }
        }
    }
    
    if (!self.cancelButton.isHidden || !self.backgroundButton.isHidden) {
        p += 12;
        
        oframe = frame = self.cancelButton.frame;
        frame.origin.y = p;
        if (!NSEqualRects(frame, oframe)) [self.cancelButton setFrame:frame];

        oframe = frame = self.backgroundButton.frame;
        frame.origin.y = p;
        if (!NSEqualRects(frame, oframe)) [self.backgroundButton setFrame:frame];

        p += frame.size.height;
    }
    
    p += 12;
    oframe = frame = self.progressIndicator.frame;
    frame.origin.y = p;
    if (!NSEqualRects(frame, oframe)) [self.progressIndicator setFrame:frame];
    p += frame.size.height;
    
    if (self.statusField.string.length) {
        p += 10;
        oframe = frame = self.statusFieldScroll.frame;
        if (![_lastPositionedStatus isEqualToString:self.statusField.string] && _lastPositionedStatus.length != self.statusField.string.length) {
            [_lastPositionedStatus release]; _lastPositionedStatus = [self.statusField.string retain];
            frame.size.height = [self.statusField optimalSizeForWidth:frame.size.width].height;
        }
        frame.origin.y = p;
        if (!NSEqualRects(frame, oframe)) [self.statusFieldScroll setFrame:frame];
        p += frame.size.height;
    }
    
    if (_docWindow && self.titleField.stringValue.length && ![self.thread isMainThread]) {
        p += 8;
        oframe = frame = self.titleField.frame;
        frame.origin.y = p;
        if (!NSEqualRects(frame, oframe)) [self.titleField setFrame:frame];
        [self.titleField setHidden:NO];
        p += frame.size.height;
    } else
        [self.titleField setHidden:YES];

    p += 18;
    
    oframe = frame = [self.window frame];
    NSRect contentRect = [self.window contentRectForFrameRect:frame];
    contentRect.origin.y += contentRect.size.height-p;
    contentRect.size.height = p;
    frame = [self.window frameRectForContentRect:contentRect];
    if (!NSEqualRects(frame, oframe))
        [self.window setFrame:frame display:YES];
}

-(void)_observeValueForKeyPathOfObjectChangeContext:(NSArray*)args {
    if (_isValid)
        [self observeValueForKeyPath:[args objectAtIndex:0] ofObject:[args objectAtIndex:1] change:[args objectAtIndex:2] context:[[args objectAtIndex:3] pointerValue]];
}

-(NSFont*)smallSystemFont {
    return [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(NSThread*)obj change:(NSDictionary*)change context:(void*)context {
	if (context == ThreadModalForWindowControllerObservationContext) {
		if (![NSThread isMainThread])
            [self performSelectorOnMainThread:@selector(_observeValueForKeyPathOfObjectChangeContext:) withObject:[NSArray arrayWithObjects: keyPath, obj, change, [NSValue valueWithPointer:context], nil] waitUntilDone:NO];
        else if( obj == self.thread) {
            @synchronized (obj) {
                
                if( obj.threadDictionary == _retainedThreadDictionary)
                {
                    if ([keyPath isEqualToString:NSThreadProgressKey])
                    {
                        // display
                        if( [NSDate timeIntervalSinceReferenceDate] - lastGUIUpdate > 0.1)
                        {
                            [self.progressIndicator setDoubleValue:self.thread.subthreadsAwareProgress];
                            [self.progressIndicator setIndeterminate: self.thread.progress < 0];
                            if (self.thread.progress < 0) [self.progressIndicator startAnimation:self];
                            _lastDisplayedProgress = obj.progress;
                            [self.progressIndicator displayIfNeeded];
                            lastGUIUpdate = [NSDate timeIntervalSinceReferenceDate];
                        }
                    }
                    
                    if ([keyPath isEqualToString:NSThreadNameKey]) {
                        self.window.title = obj.name? obj.name : NSLocalizedString(@"Task Progress", nil);
                        self.titleField.stringValue = obj.name? obj.name : @"";
                        /* if ([obj isMainThread]) */ [self.titleField displayIfNeeded];
                    }
                    if ([keyPath isEqualToString:NSThreadStatusKey]) {
                        self.statusField.string = obj.status? obj.status : @"";
                        /* if ([obj isMainThread]) */ [self.statusField displayIfNeeded];
                    }
                    if ([keyPath isEqualToString:NSThreadProgressDetailsKey]) {
                        self.progressDetailsField.stringValue = obj.progressDetails? obj.progressDetails : @"";
                        /* if ([obj isMainThread]) */ [self.progressDetailsField displayIfNeeded];
                    }
                    if ([keyPath isEqualToString:NSThreadSupportsCancelKey] || [keyPath isEqualToString:NSThreadIsCancelledKey]) {
                        [self.cancelButton setHidden: !obj.supportsCancel && !obj.isCancelled];
                       /* if ([obj isMainThread]) */ [self.cancelButton displayIfNeeded];
                    }
                    if ([keyPath isEqualToString:NSThreadSupportsBackgroundingKey]) {
                        [self.backgroundButton setHidden: !obj.supportsBackgrounding];
                        /* if ([obj isMainThread]) */ [self.backgroundButton displayIfNeeded];
                    }
                }
            }
        
            [self repositionViews];
        }
    
        return;
	}
    
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)invalidate {
    if (![NSThread isMainThread])
        return [self performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:NO];
    
	DLog(@"[ThreadModalForWindowController invalidate]");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:_thread];
    
    [self.progressIndicator setDoubleValue:self.thread.subthreadsAwareProgress];
    [self.progressIndicator setIndeterminate: self.thread.progress < 0];
    if (self.thread.progress < 0) [self.progressIndicator startAnimation:self];
    [self.progressIndicator displayIfNeeded];
    lastGUIUpdate = [NSDate timeIntervalSinceReferenceDate];
    
    @synchronized( self.thread)
    {
        [self.thread.threadDictionary removeObjectForKey:NSThreadModalForWindowControllerKey];
    }
    
    _isValid = NO;
    
	if ([NSThread isMainThread]) 
		[NSApp endSheet:self.window];
	else [NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:self.window waitUntilDone:NO];
//    if (![self.window isSheet]) {
//        if ([NSThread isMainThread]) 
//            [self.window orderOut:self];
//        else [self.window performSelectorOnMainThread:@selector(orderOut:) withObject:self waitUntilDone:NO];
//    }
    
}

-(void)threadWillExitNotification:(NSNotification*)notification {
	[self invalidate];
}

-(void)cancelAction:(id)source {
	[self.thread setIsCancelled:YES];
}

-(void)backgroundAction:(id)source {
	[self invalidate];
}

@end

@implementation NSThread (ModalForWindow)

-(ThreadModalForWindowController*)startModalForWindow:(NSWindow*)window {
//	if ([[self threadDictionary] objectForKey:ThreadIsCurrentlyModal])
//		return nil;
//	[[self threadDictionary] setObject:[NSNumber numberWithBool:YES] forKey:ThreadIsCurrentlyModal];
	if ([NSThread isMainThread]) {
		if (![self isFinished])
			return [[[ThreadModalForWindowController alloc] initWithThread:self window:window] autorelease];
	} else [self performSelectorOnMainThread:@selector(startModalForWindow:) withObject:window waitUntilDone:NO];
	return nil;
}

-(ThreadModalForWindowController*)modalForWindowController {
    @synchronized( self)
    {
        return [self.threadDictionary objectForKey:NSThreadModalForWindowControllerKey];
    }
    return nil;
}

@end



@interface MainThreadActiveWindow : NSWindow

@end

@implementation MainThreadActiveWindow

/*-(BOOL)isKeyWindow {
    BOOL cond = [[(ThreadModalForWindowController*)self.windowController thread] isMainThread] ;//&& [NSApp isActive];
    return cond? YES : [super isKeyWindow];
}*/

@end
