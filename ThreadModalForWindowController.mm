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
@synthesize titleField = _titleField;
@synthesize statusField = _statusField;
@synthesize statusFieldScroll = _statusFieldScroll;
@synthesize progressDetailsField = _progressDetailsField;

-(id)initWithThread:(NSThread*)thread window:(NSWindow*)docWindow {
	self = [super initWithWindowNibName:@"ThreadModalForWindow"];
	
	_docWindow = [docWindow retain];
	_thread = [thread retain];
    [(_retainedThreadDictionary = thread.threadDictionary) retain];
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
	[self.progressIndicator setUsesThreadedAnimation:NO];
	[self.progressIndicator startAnimation:self];
	
    [self.titleField bind:@"value" toObject:self.thread withKeyPath:NSThreadNameKey options:NULL];
//  [self.window bind:@"title" toObject:self.thread withKeyPath:NSThreadNameKey options:NULL];
    [self.statusField bind:@"string" toObject:self.thread withKeyPath:NSThreadStatusKey options:NULL];
    [self.progressDetailsField bind:@"value" toObject:self.thread withKeyPath:NSThreadProgressDetailsKey options:NULL];
    [self.cancelButton bind:@"hidden" toObject:self.thread withKeyPath:NSThreadSupportsCancelKey options:[NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:NSValueTransformerNameBindingOption]];
	[self.cancelButton bind:@"hidden2" toObject:self.thread withKeyPath:NSThreadIsCancelledKey options:NULL];
	
	[self.thread addObserver:self forKeyPath:NSThreadProgressKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadNameKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadStatusKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadProgressDetailsKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadSupportsCancelKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
	[self.thread addObserver:self forKeyPath:NSThreadIsCancelledKey options:NSKeyValueObservingOptionInitial context:ThreadModalForWindowControllerObservationContext];
    
    if (!self.docWindow)
        [NSApp activateIgnoringOtherApps:YES];
}

-(void)sheetDidEndOnMainThread:(NSWindow*)sheet
{
	[sheet orderOut:self];
//	[NSApp endSheet:sheet];
	[self release];
}

-(void)sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[self performSelectorOnMainThread:@selector(sheetDidEndOnMainThread:) withObject:sheet waitUntilDone:NO];
}

-(void)dealloc {
	DLog(@"[ThreadModalForWindowController dealloc]");
	
	[self.thread removeObserver:self forKeyPath:NSThreadProgressKey];
	[self.thread removeObserver:self forKeyPath:NSThreadNameKey];
	[self.thread removeObserver:self forKeyPath:NSThreadStatusKey];
	[self.thread removeObserver:self forKeyPath:NSThreadProgressDetailsKey];
	[self.thread removeObserver:self forKeyPath:NSThreadSupportsCancelKey];
	[self.thread removeObserver:self forKeyPath:NSThreadIsCancelledKey];
	
    [_retainedThreadDictionary release]; _retainedThreadDictionary = nil;
	[_thread release];
	[_docWindow release];
	
	[super dealloc]; 
}

/*-(void)_observeValueForKeyPathOfObjectChangeContext:(NSArray*)args {
    [self observeValueForKeyPath:[args objectAtIndex:0] ofObject:[args objectAtIndex:1] change:[args objectAtIndex:2] context:[[args objectAtIndex:3] pointerValue]];
}*/

-(void)repositionViews {
    CGFloat p = 0;
    NSRect frame;
    
    if (!self.cancelButton.isHidden) {
        p += 20;
        frame = self.cancelButton.frame;
        frame.origin.y = p;
        [self.cancelButton setFrame:frame];
        p += frame.size.height;
    }
    
    p += 20;
    frame = self.progressIndicator.frame;
    frame.origin.y = p;
    [self.progressIndicator setFrame:frame];
    p += frame.size.height;
    
    if (self.statusField.string.length) {
        p += 10;
        frame = self.statusFieldScroll.frame;
        frame.size.height = [self.statusField optimalSizeForWidth:frame.size.width].height;
        frame.origin.y = p;
        [self.statusFieldScroll setFrame:frame];
        p += frame.size.height;
    }
    
    if (self.titleField.stringValue.length) {
        p += 8;
        frame = self.titleField.frame;
        frame.origin.y = p;
        [self.titleField setFrame:frame];
        p += frame.size.height;
    }

    p += 20;
    
    frame = [self.window frame];
    NSRect contentRect = [self.window contentRectForFrameRect:frame];
    contentRect.origin.y += contentRect.size.height-p;
    contentRect.size.height = p;
    frame = [self.window frameRectForContentRect:contentRect];
    [self.window setFrame:frame display:YES animate:YES];
}

-(NSFont*)smallSystemFont {
    return [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(NSThread*)obj change:(NSDictionary*)change context:(void*)context {
	if (context == ThreadModalForWindowControllerObservationContext) {
		/*if (![NSThread isMainThread])
            [self performSelectorOnMainThread:@selector(_observeValueForKeyPathOfObjectChangeContext:) withObject:[NSArray arrayWithObjects: keyPath, obj, change, [NSValue valueWithPointer:context], nil] waitUntilDone:NO];
        else {*/
            if ([keyPath isEqual:NSThreadProgressKey]) {
                [self.progressIndicator setIndeterminate: self.thread.progress < 0];	
                if (self.thread.progress >= 0)
                    [self.progressIndicator setDoubleValue:self.thread.subthreadsAwareProgress];
            }
            
            if ([NSThread isMainThread]) {
                if ([keyPath isEqual:NSThreadProgressKey])
                    [self.progressIndicator display];
                if ([keyPath isEqual:NSThreadNameKey]) {
                    self.titleField.stringValue = obj.name? obj.name : @"";
                    [self.titleField display];
                }
                if ([keyPath isEqual:NSThreadStatusKey]) {
                    self.statusField.string = obj.status? obj.status : @"";
                    [self.statusField display];
                }
                if ([keyPath isEqual:NSThreadProgressDetailsKey]) {
                    self.progressDetailsField.stringValue = obj.progressDetails? obj.progressDetails : @"";
                    [self.progressDetailsField display];
                }
                if ([keyPath isEqual:NSThreadSupportsCancelKey] && [keyPath isEqual:NSThreadIsCancelledKey]) {
                    [self.cancelButton setHidden: obj.supportsCancel && !obj.isCancelled];
                    [self.cancelButton display];
                }
                
                [self repositionViews];
            }
        
        /*}*/ return;
	}
    
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)invalidate {
	DLog(@"[ThreadModalForWindowController invalidate]");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:_thread];
	[self.thread.threadDictionary removeObjectForKey:NSThreadModalForWindowControllerKey];
    
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
	return [self.threadDictionary objectForKey:NSThreadModalForWindowControllerKey];
}

@end


