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

#import "ThreadCell.h"
#import "ThreadsManager.h"
#import "BrowserController.h"
#import "NSString+N2.h"
#import "NSThread+N2.h"
#import "N2Debug.h"
#import "N2Operators.h"
#import "AppController.h"

@implementation ThreadCell

@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize thread = _thread;
@synthesize manager = _manager;
@synthesize view = _view;

-(id)initWithThread:(NSThread*)thread manager:(ThreadsManager*)manager view:(NSTableView*)view {
	self = [super init];
    
	_view = view;
	_manager = manager;
	
	_progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
	[_progressIndicator setUsesThreadedAnimation:YES];
	[_progressIndicator setMinValue:0];
	[_progressIndicator setMaxValue:1];
	
	_cancelButton = [[NSButton alloc] initWithFrame:NSZeroRect];
	[_cancelButton setImage:[NSImage imageNamed:@"Activity_Stop"]];
	[_cancelButton setAlternateImage:[NSImage imageNamed:@"Activity_StopPressed"]];
	[_cancelButton setBordered:NO];
	[_cancelButton setButtonType:NSMomentaryChangeButton];
	_cancelButton.target = self;
	_cancelButton.action = @selector(cancelThreadAction:);
    
    _lastDisplayedProgress = -1;
    
    self.thread = thread;
    
	return self;
}

-(void)cleanup
{
    if( _progressIndicator == nil && _cancelButton == nil && KVOObserving == NO)
        return;
    
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"We shoud be on MAIN thread");
    
    @synchronized( _thread)
    {
        [_progressIndicator removeFromSuperview];
        [_progressIndicator autorelease]; _progressIndicator = nil;
        
        _cancelButton.target = nil;
        _cancelButton.action = nil;
        [_cancelButton removeFromSuperview];
        [_cancelButton autorelease]; _cancelButton = nil;
        
        [self.view reloadData];
        [self.view setNeedsDisplay: YES];
        
        if( KVOObserving)
        {
            [_thread removeObserver:self forKeyPath:NSThreadSupportsCancelKey];
            [_thread removeObserver:self forKeyPath:NSThreadProgressKey];
            [_thread removeObserver:self forKeyPath:NSThreadStatusKey];
            [_thread removeObserver:self forKeyPath:NSThreadIsCancelledKey];
            KVOObserving = NO;
        }
    }
}

-(void)dealloc
{
	[self cleanup];
    
    [_thread autorelease];
    [_retainedThreadDictionary autorelease];
    
	[super dealloc];
}

-(void)setThread:(NSThread*)thread {
    
    @synchronized( _thread)
    {
        @try
        {
            if( KVOObserving)
            {
                [_thread removeObserver:self forKeyPath:NSThreadSupportsCancelKey];
                [_thread removeObserver:self forKeyPath:NSThreadProgressKey];
                [_thread removeObserver:self forKeyPath:NSThreadStatusKey];
                [_thread removeObserver:self forKeyPath:NSThreadIsCancelledKey];
                KVOObserving = NO;
            }
        }
        @catch ( NSException *e)
        {
            N2LogException( e);
        }
        
        [_thread autorelease];
        [_retainedThreadDictionary autorelease];
        
        _thread = [thread retain];
        
        @synchronized( _thread)
        {
            _retainedThreadDictionary = [_thread.threadDictionary retain];
            
            if( _retainedThreadDictionary)
            {
                [_thread addObserver:self forKeyPath:NSThreadIsCancelledKey options:NSKeyValueObservingOptionInitial context:NULL];
                [_thread addObserver:self forKeyPath:NSThreadStatusKey options:NSKeyValueObservingOptionInitial context:NULL];
                [_thread addObserver:self forKeyPath:NSThreadProgressKey options:NSKeyValueObservingOptionInitial context:NULL];
                [_thread addObserver:self forKeyPath:NSThreadSupportsCancelKey options:NSKeyValueObservingOptionInitial context:NULL];
                
                KVOObserving = YES;
            }
        }
    }
}

-(void)_observeValueForKeyPathOfObjectChangeContext:(NSArray*)args {
	[self observeValueForKeyPath:[args objectAtIndex:0] ofObject:[args objectAtIndex:1] change:[args objectAtIndex:2] context:[[args objectAtIndex:3] pointerValue]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(NSThread*)obj change:(NSDictionary*)change context:(void*)context
{
    if (obj == _thread)
    {
        @synchronized( _thread)
        {
            if( _thread.isFinished)
                return;
            
            if( _retainedThreadDictionary != _thread.threadDictionary)
                return;
        }
        
        if (![NSThread isMainThread]) {
            [self performSelectorOnMainThread:@selector(_observeValueForKeyPathOfObjectChangeContext:) withObject:[NSArray arrayWithObjects: keyPath, obj, change, [NSValue valueWithPointer:context], NULL] waitUntilDone:NO];
            return;
        }
        
        if ([keyPath isEqualToString:NSThreadStatusKey]) {
            [self.view setNeedsDisplayInRect: [self.view rectOfRow:[self.manager.threads indexOfObject:self.thread]]];
            return;
        } else if ([keyPath isEqualToString:NSThreadProgressKey]) {
            [self.progressIndicator setDoubleValue:self.thread.subthreadsAwareProgress];
            [self.progressIndicator setIndeterminate: self.thread.progress < 0];
            if (self.thread.progress < 0) [self.progressIndicator startAnimation:self];
            if (fabs(_lastDisplayedProgress-obj.progress) > 1.0/self.progressIndicator.frame.size.width) {
                _lastDisplayedProgress = obj.progress;
                [self.progressIndicator setNeedsDisplay: YES];
            }
            return;
        } else if ([keyPath isEqualToString:NSThreadSupportsCancelKey] || [keyPath isEqualToString:NSThreadIsCancelledKey]) {
            [self.cancelButton setHidden:(!self.thread.supportsCancel)||self.thread.isCancelled];
            [self.cancelButton setEnabled:self.thread.supportsCancel];
            return;
        }
    }
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)cancelThreadAction:(id)source
{
    @synchronized( _thread)
    {
        if( [self.thread isFinished] == NO)
        {
            _thread.status = NSLocalizedString( @"Cancelling...", nil);
            [_thread setIsCancelled:YES];
        }
    }
}


-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view {
    
    @synchronized( _thread)
    {
        if ([_thread isFinished])
            return;
	}
    
	NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSMutableDictionary* textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: [self textColor], NSForegroundColorAttributeName, [NSFont labelFontOfSize:[[BrowserController currentBrowser] fontSize: @"threadNameSize"]], NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, NULL];

	[NSGraphicsContext saveGraphicsState];
	
    NSString* tempName;
    NSString* tempStatus;
    @synchronized (_thread) {
        tempName = [[_thread.name retain] autorelease];
        tempStatus = [[_thread.status retain] autorelease];
    }
    
	NSRect nameFrame = NSMakeRect(frame.origin.x+3, frame.origin.y-1, frame.size.width-23, frame.size.height);
	if (!tempName) tempName = NSLocalizedString(@"Unspecified Task", nil);
	[tempName drawWithRect:nameFrame options:NSStringDrawingUsesLineFragmentOrigin+NSStringDrawingTruncatesLastVisibleLine attributes:textAttributes];
    
	NSRect statusFrame = [self statusFrame];
	[textAttributes setObject:[NSFont labelFontOfSize: [[BrowserController currentBrowser] fontSize: @"threadNameStatus"]] forKey:NSFontAttributeName];
	if (!tempStatus) tempStatus = @"";
    [tempStatus drawWithRect:statusFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
	
	if (![self.progressIndicator superview]) {
		[view addSubview:self.progressIndicator];
        [self.progressIndicator setIndeterminate:YES];
		[self.progressIndicator startAnimation:self];
	}
    
    NSRect progressFrame = NSMakeRect(frame.origin.x+3, frame.origin.y + (frame.size.height - 12), frame.size.width-6, 10);
    
	if (!NSEqualRects(self.progressIndicator.frame, progressFrame))
        [self.progressIndicator setFrame:progressFrame];
	
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view {
//	{ // for debug
//		[NSGraphicsContext saveGraphicsState];
//		
//		[[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.25] setFill];
//		[NSBezierPath fillRect:frame];
//		
//		[NSGraphicsContext restoreGraphicsState];
//	}
    
	[self drawInteriorWithFrame:frame inView:view];
	
	[NSGraphicsContext saveGraphicsState];
	
	[[[NSColor grayColor] colorWithAlphaComponent:0.5] set];
	[NSBezierPath strokeLineFromPoint:frame.origin+NSMakeSize(-2, frame.size.height) toPoint:frame.origin+frame.size+NSMakeSize(2,0)];
	
	[NSGraphicsContext restoreGraphicsState];
}

-(NSRect)statusFrame
{
    NSRect frame = [self.view rectOfRow:[self.manager.threads indexOfObject:self.thread]];

    return NSMakeRect(frame.origin.x+3, frame.origin.y + [[BrowserController currentBrowser] fontSize: @"threadCellLineSpace"], frame.size.width-22, frame.size.height- (frame.origin.y + [[BrowserController currentBrowser] fontSize: @"threadCellLineSpace"]));
}

@end
