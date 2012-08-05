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

#import "IChatTheatreDelegate.h"
#import <InstantMessage/IMService.h>
#import <InstantMessage/IMAVManager.h>
#import <AddressBook/AddressBook.h>
#import "ViewerController.h"
#import "OrthogonalMPRViewer.h"
#import "VRController.h"
#import "EndoscopyViewer.h"
#import "PreviewView.h"
#import "IChatTheatreHelpWindowController.h"
#import "Notifications.h"

#import "VRPresetPreview.h"
#import "VRView.h"

static IChatTheatreDelegate	*iChatDelegate = nil;

@implementation IChatTheatreDelegate

@synthesize web;

+ (void) releaseSharedDelegate
{
	[iChatDelegate release];
	iChatDelegate = nil;
}

+ (IChatTheatreDelegate*) initSharedDelegate
{
    if( [ABAddressBook sharedAddressBook] == nil)
        return nil;
    
    if( iChatDelegate == nil)
        iChatDelegate = [[IChatTheatreDelegate alloc] init];
    
    return iChatDelegate;
}

+ (IChatTheatreDelegate*) sharedDelegate
{
    return iChatDelegate;
}

- (id)init
{
    @try
    {
        if(![super init])
            return nil;
        [[IMService notificationCenter] addObserver:self selector:@selector(_stateChanged:) name:IMAVManagerStateChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowChanged:) name:NSWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusChanged:) name:OsirixDCMViewDidBecomeFirstResponderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusChanged:) name:OsirixVRViewDidBecomeFirstResponderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(focusChanged:) name:OsirixVRCameraDidChangeNotification object:nil];
        
    }
    @catch (NSException *e)
    {
        NSLog( @"********* iChatTheatreDelegate exception: %@", e);
        return nil;
    }
    
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[IMAVManager sharedAVManager] videoDataSource] release];
	[[IMAVManager sharedAVManager] setVideoDataSource:nil];
	[[IMService notificationCenter] removeObserver:self];
	[super dealloc];
}

- (void)_stateChanged:(NSNotification *)aNotification;
{
	NSLog(@"IChatTheatreDelegate _stateChanged !");

	IMAVManager *avManager = [IMAVManager sharedAVManager];
	// Read the state.
    IMAVManagerState state = [avManager state];
	
    if(state == IMAVRequested)
	{	
		//[self setVideoDataSource: [[[NSApplication sharedApplication] orderedWindows] objectAtIndex:0]];
//		NSLog(@"[[NSApplication sharedApplication] keyWindow] :%@", [[NSApplication sharedApplication] keyWindow]);
//		[self setVideoDataSource: [[NSApplication sharedApplication] keyWindow]];
//		[[avManager videoDataSource] release];
//		[avManager setVideoDataSource: [self retain]];
//		[avManager setVideoOptimizationOptions:IMVideoOptimizationStills];
		
//		NSLog(@"_stateChanged : Start iChat Theatre");
//		[avManager start];
	}
	else if(state == IMAVInactive)
	{
		[[avManager videoDataSource] release];
		[avManager setVideoDataSource:nil];
		[avManager stop];
		NSLog(@"_stateChanged: Stop iChat Theatre");
	}
}

- (void)windowChanged:(NSNotification *)aNotification;
{
	if(![self isIChatTheatreRunning]) return;

	if([[aNotification object] isKindOfClass:[VRView class]])
	{
		[[[IMAVManager sharedAVManager] videoDataSource] release];
		[[IMAVManager sharedAVManager] setVideoDataSource: [self retain]];
	}
	else
		[self setVideoDataSource: [[aNotification object] retain]];
	
	[[IMAVManager sharedAVManager] start];
}

- (void)focusChanged:(NSNotification *)aNotification;
{
	if(![self isIChatTheatreRunning]) return;
	if([[aNotification name] isEqualToString:OsirixVRCameraDidChangeNotification])
		if(![[(VRController*)[[aNotification object] controller] style] isEqualToString:@"panel"]) return;
		
	IMAVManager *avManager = [IMAVManager sharedAVManager];
	
	[[avManager videoDataSource] release];
	
	if([[aNotification object] isKindOfClass:[PreviewView class]] || [[aNotification object] isKindOfClass:[VRPresetPreview class]])
		[avManager setVideoDataSource: [self retain]];
	else
		[avManager setVideoDataSource: [[aNotification object] retain]];
	[avManager setVideoOptimizationOptions:IMVideoOptimizationStills];
	
	[[IMAVManager sharedAVManager] start];
}

- (void)setVideoDataSource:(NSWindow*)window;
{
	IMAVManager *avManager = [IMAVManager sharedAVManager];

	[[avManager videoDataSource] release];

	if(!window)
	{
		[avManager setVideoDataSource: [self retain]];
	}
	else if(![window windowController])
	{
		[avManager setVideoDataSource: [self retain]];
	}
	else if([[window windowController] isKindOfClass:[OrthogonalMPRViewer class]])
	{	
		if([[[[window windowController] controller] originalView] isKeyView])
			[avManager setVideoDataSource: [[[[window windowController] controller] originalView] retain]];
		else if([[[[window windowController] controller] xReslicedView] isKeyView])
			[avManager setVideoDataSource: [[[[window windowController] controller] xReslicedView] retain]];
		else if([[[[window windowController] controller] yReslicedView] isKeyView])
			[avManager setVideoDataSource: [[[[window windowController] controller] yReslicedView] retain]];
		else
			[avManager setVideoDataSource: [self retain]];
	}
	else if([[window windowController] isKindOfClass:[ViewerController class]])
	{
		if(![window isKeyWindow])
		{
			[avManager setVideoDataSource: [self retain]];
		}
		else
			[avManager setVideoDataSource: [[[window windowController] imageView] retain]];
	}
	else if ([[window windowController] isKindOfClass:[EndoscopyViewer class]])
	{
		[avManager setVideoDataSource: [[[[window windowController] vrController] view] retain]];
	}
	else if ([[window windowController] isKindOfClass:[VRController class]])
	{
		if([window isKindOfClass:[NSPanel class]])
		{
			[avManager setVideoDataSource: [self retain]];
		}
		else
			[avManager setVideoDataSource: [[[window windowController] view] retain]];
	}
	else
	{
		[avManager setVideoDataSource: [self retain]];
	}
	[avManager setVideoOptimizationOptions:IMVideoOptimizationStills];
}

- (BOOL)isIChatTheatreRunning;
{
    @try
    {
        if([[IMAVManager sharedAVManager] state] == IMAVInactive)
            return NO;
        else
            return YES;
    }
    @catch (NSException *e)
    {
        NSLog( @"**** isIChatTheatreRunning: %@", e);
    }
	
	return NO;
}


// Callback from IMAVManager asking what pixel format we'll be providing frames in.
- (void)getPixelBufferPixelFormat:(OSType *)pixelFormatOut {
//	NSLog(@"getPixelBufferPixelFormat");
    *pixelFormatOut = kCVPixelFormatType_32ARGB;
}

// This callback is called periodically when we're in the IMAVActive state.
// We copy (actually, re-render) what's currently on the screen into the provided 
// CVPixelBufferRef.
//
// Note that this will be called on a non-main thread. 
- (BOOL) renderIntoPixelBuffer:(CVPixelBufferRef)buffer forTime:(CVTimeStamp*)timeStamp
{
//	NSLog(@"renderIntoPixelBuffer");
    // We ignore the timestamp, signifying that we're providing content for 'now'.
	CVReturn err;
	
	// If the image has not changed since we provided the last one return 'NO'.
    // This enables more efficient transmission of the frame when there is no
    // new information.

//	if ([self checkHasChanged] == NO)
//	{
//		return NO;
//	}
	
	
    // Lock the pixel buffer's base address so that we can draw into it.
	if((err = CVPixelBufferLockBaseAddress(buffer, 0)) != kCVReturnSuccess) {
        // This should not happen.  If it does, the safe thing to do is return 
        // 'NO'.
		NSLog(@"Warning, could not lock pixel buffer base address in %s - error %ld", __func__, (long)err);
		return NO;
	}
    @synchronized (self) {
    // Create a CGBitmapContext with the CVPixelBuffer.  Parameters /must/ match 
    // pixel format returned in getPixelBufferPixelFormat:, above, width and
    // height should be read from the provided CVPixelBuffer.
    float iChatWidth = CVPixelBufferGetWidth(buffer); 
    float iChatHeight = CVPixelBufferGetHeight(buffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(buffer),
                                                   iChatWidth, iChatHeight,
                                                   8,
                                                   CVPixelBufferGetBytesPerRow(buffer),
                                                   colorSpace,
                                                   kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    	
    // Derive an NSGraphicsContext, make it current, and ask our SlideshowView 
    // to draw.
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
    [NSGraphicsContext setCurrentContext:context];
	//get NSImage and draw in the rect
    [self drawImage:[[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] bundlePath]] inBounds:NSMakeRect(0.0, 0.0, iChatWidth, iChatHeight)];
    [context flushGraphics];
    
    // Clean up - remember to unlock the pixel buffer's base address (we locked
    // it above so that we could draw into it).
    CGContextRelease(cgContext);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    }
    return YES;
}

- (void)drawImage:(NSImage *)image inBounds:(NSRect)rect
{
//	NSLog(@"drawImage");
    // We synchronise to make sure we're not drawing in two threads
    // simultaneously.
   
		[[NSColor blackColor] set];
		NSRectFill(rect);
		
		if (image != nil) {
			NSRect imageBounds = { NSZeroPoint, [image size] };
			float scaledHeight = NSWidth(rect) * NSHeight(imageBounds);
			float scaledWidth  = NSHeight(rect) * NSWidth(imageBounds);
			
			if (scaledHeight < scaledWidth) {
				// rect is wider than image: fit height
				float horizMargin = NSWidth(rect) - scaledWidth / NSHeight(imageBounds);
				rect.origin.x += horizMargin / 2.0;
				rect.size.width -= horizMargin;
			} else {
				// rect is taller than image: fit width
				float vertMargin = NSHeight(rect) - scaledHeight / NSWidth(imageBounds);
				rect.origin.y += vertMargin / 2.0;
				rect.size.height -= vertMargin;
			}
			
			[image drawInRect:rect fromRect:imageBounds operation:NSCompositeSourceOver fraction:fraction];
		}

	//}
}

// The _hasChanged flag is set to 'NO' after any check (by a client of this 
// class), and 'YES' after a frame is drawn that is not identical to the 
// previous one (in the drawInBounds: method).

// Returns the current state of the flag, and sets it to the passed in value.
- (BOOL)_checkHasChanged:(BOOL)flag {
	//NSLog(@"_checkHasChanged");
    BOOL hasChanged;
    @synchronized (self) {
		hasChanged = _hasChanged;
        _hasChanged = flag;
    }
    return hasChanged;
}

- (BOOL)checkHasChanged {

    // Calling with 'NO' clears _hasChanged after the call (see above).
    return [self _checkHasChanged:NO];
}

- (void)showIChatHelp;
{
	if( ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) == 0)
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"DONT_DISPLAY_ICHAT_HELP"]) return;

	NSArray				*winList = [NSApp windows];
	
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString: @"iChatHelper"])
		{
			[[[loopItem windowController] window] makeKeyAndOrderFront:self];
			return;
		}
	}

	IChatTheatreHelpWindowController *helpWindowController = [[IChatTheatreHelpWindowController alloc] initWithWindowNibName:@"iChatHelper" owner:self];
	[helpWindowController showWindow:self];
}

@end
