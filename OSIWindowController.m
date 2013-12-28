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

#import "OSIWindowController.h"
#import "ToolbarPanel.h"
#import "ThumbnailsListPanel.h"
#import "NavigatorView.h"
#import "NavigatorWindowController.h"
#import "AppController.h"
#import "ViewerController.h"
#import "BrowserController.h"
#import "Notifications.h"
#import <Carbon/Carbon.h>
#import "DCMPix.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DicomDatabase.h"
#import "N2Debug.h"

static	BOOL dontEnterMagneticFunctions = NO;
static	BOOL dontWindowDidChangeScreen = NO;
extern  BOOL USETOOLBARPANEL;
extern  ToolbarPanelController  *toolbarPanel[10];
extern int delayedTileWindows;

static BOOL protectedReentryWindowDidResize = NO;

@implementation OSIWindowController

@synthesize database = _database;

-(void)setDatabase:(DicomDatabase*)database {
	if (database != _database) {
		if (_database) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixAddToDBNotification object:_database];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixDatabaseObjectsMayBecomeUnavailableNotification object:_database];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:_database.managedObjectContext];
            
            [_database release];
            _database = nil;
		}
		
		_database = [database retain];
		
		if (_database) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeDatabaseAddNotification:) name:OsirixAddToDBNotification object:_database];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeDatabaseObjectsMayFaultNotification:) name:OsirixDatabaseObjectsMayBecomeUnavailableNotification object:_database];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeManagedObjectContextObjectsDidChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:_database.managedObjectContext];
		}
	}
}

-(void)refreshDatabase:(NSArray*)newImages {
}

-(void)observeDatabaseAddNotification:(NSNotification*)notification {
	[self refreshDatabase:[[notification userInfo] objectForKey:OsirixAddToDBCompleteNotificationImagesArray]];
}

-(void)observeManagedObjectContextObjectsDidChangeNotification:(NSNotification*)notification {
}

-(void)observeDatabaseObjectsMayFaultNotification:(NSNotification*)notification {
	[self close];
}

#pragma mark-
#pragma mark Magnetic Windows & Tiling

#ifndef OSIRIX_LIGHT
- (IBAction) paste:(id) sender;
{
	if( [[self pixList] count])
	{
		DCMPix *pix = [[self pixList] lastObject];
		
		if( [pix seriesObj])
			[[BrowserController currentBrowser] selectThisStudy: [[pix seriesObj] valueForKey: @"study"]];
		
		[[BrowserController currentBrowser] pasteImageForSourceFile: [pix sourceFile]];
	}
}
#endif

- (void) setMagnetic:(BOOL) a
{
	magneticWindowActivated = a;
}

- (BOOL) magnetic
{
	return magneticWindowActivated;
}

+ (void) setDontEnterMagneticFunctions:(BOOL) a
{
	dontEnterMagneticFunctions = a;
}

+ (BOOL) dontWindowDidChangeScreen
{
	return dontWindowDidChangeScreen;
}

+ (void) setDontEnterWindowDidChangeScreen:(BOOL) a
{
	dontWindowDidChangeScreen = a;
}

- (void) windowDidResize:(NSNotification *)aNotification
{
	if( protectedReentryWindowDidResize) return;
	
	protectedReentryWindowDidResize = YES;
	if( magneticWindowActivated)
	{
		if( dontEnterMagneticFunctions == NO && Button() != 0)
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"MagneticWindows"])
			{
				NSEnumerator	*e;
				NSWindow		*theWindow, *window;
				NSValue			*value;
				NSRect			frame, myFrame;
				
				theWindow = [aNotification object];
				myFrame = [theWindow frame];
				
				float gravityX = 30;
				float gravityY = 30;
				
				if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
				{
					protectedReentryWindowDidResize = NO;
					return;
				}
				
				NSMutableArray	*rects = [NSMutableArray array];
				
				// Add the viewers
				e = [[NSApp windows] objectEnumerator];
				while (window = [e nextObject])
				{
					if (window != theWindow && [window isVisible] && [[window windowController] isKindOfClass: [OSIWindowController class]] && [window.screen isEqualTo: theWindow.screen])
					{
						if( [[window windowController] magnetic])
							[rects addObject: [NSValue valueWithRect: [window frame]]];
					}
				}
				
				// Add the current screen ONLY
	//			e = [[NSScreen screens] objectEnumerator];
	//			while (screen = [e nextObject])
				{
					NSRect frame = [AppController usefullRectForScreen: [[self window] screen]];
                    
					frame = [NavigatorView adjustIfScreenAreaIf4DNavigator: frame];
					[rects addObject: [NSValue valueWithRect: frame]];
				}
				
				NSRect	dstFrame = myFrame;
				
				for (value in rects)
				{
					frame = [value rectValue];
					
					/* horizontal magnet */
					if (fabs(NSMinX(frame) - NSMaxX(myFrame)) <= gravityX)	// LEFT
					{
						gravityX = fabs(NSMinX(frame) - NSMaxX(myFrame));
						dstFrame.size.width = frame.origin.x - myFrame.origin.x;
					}
					
					/* vertical magnet */
					if (fabs(NSMinY(frame) - NSMinY(myFrame)) <= gravityY)	//TOP
					{
						gravityY = fabs(NSMinY(frame) - NSMinY(myFrame));
						
						NSRect	previous = dstFrame;
						dstFrame.origin.y = frame.origin.y;
						dstFrame.size.height = dstFrame.size.height - (dstFrame.origin.y - previous.origin.y);
					}
				}
				
				for (value in rects)
				{
					if (fabs(NSMaxX(frame) - NSMaxX(myFrame)) <= gravityX)	//RIGHT
					{
						gravityX = fabs(NSMaxX(frame) - NSMaxX(myFrame));
						dstFrame.size.width = frame.origin.x + frame.size.width - myFrame.origin.x;
					}
				
					if (fabs(NSMaxY(frame) - NSMinY(myFrame)) <= gravityY)	// BOTTOM
					{
						gravityY = fabs(NSMaxY(frame) - NSMinY(myFrame));
						
						NSRect	previous = dstFrame;
						dstFrame.origin.y = frame.origin.y + frame.size.height;
						dstFrame.size.height = dstFrame.size.height - (dstFrame.origin.y - previous.origin.y);
					}
				}
				
				dontEnterMagneticFunctions = YES;
				[theWindow setFrame:dstFrame display:YES];
				dontEnterMagneticFunctions = NO;
			}
			
			if( [self isKindOfClass: [ViewerController class]])
			{
				if( [aNotification object] == [self window])
				{
                    ViewerController *vv = (ViewerController*) self;
					[vv showCurrentThumbnail: self];
				}
			}
			
			if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
			{
				// Apply the same size to all displayed windows
				
				NSArray	*viewers = [ViewerController getDisplayed2DViewers];
				
				for( id loopItem in viewers)
				{
					if( loopItem != self)
					{
						NSWindow *theWindow = [loopItem window];
						
						NSRect dstFrame = [theWindow frame];
						
						dstFrame.size = [[self window] frame].size;
						
						dstFrame.origin.y -= dstFrame.size.height - [theWindow frame].size.height;
						
						dontEnterMagneticFunctions = YES;
						[theWindow setFrame: dstFrame display:YES];
						dontEnterMagneticFunctions = NO;
					}
				}
			}
		}
		else
		{
			NSRect dstFrame = [[self window] frame];
			NSRect visibleRect = [AppController usefullRectForScreen: self.window.screen];
            
            if( dstFrame.size.height >= visibleRect.size.height)
                dstFrame.size.height = visibleRect.size.height;
            
            if( dstFrame.size.width >= visibleRect.size.width)
                dstFrame.size.width = visibleRect.size.width;
			
			if( dstFrame.size.height < [[self window] contentMinSize].height) dstFrame.size.height = [[self window] contentMinSize].height;
			if( dstFrame.size.width < [[self window] contentMinSize].width) dstFrame.size.width = [[self window] contentMinSize].width;
			
			
			dstFrame = [NavigatorView adjustIfScreenAreaIf4DNavigator: dstFrame];
			
			if( NSEqualRects( dstFrame, [[self window] frame]) == NO)
				[[self window] setFrame: dstFrame display:YES];
		}
		
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
        {
            if( [self isKindOfClass: [ViewerController class]])
                [(ViewerController*)self showCurrentThumbnail: self];
        }
	}
	
	protectedReentryWindowDidResize = NO;
}

- (void) autoHideMatrix
{
}

- (void) syncThumbnails
{
}

- (void) refreshToolbar
{
}

- (id) imageView
{
	return nil;
}

- (void) propagateSettings
{
}

- (NSArray*) fileList
{
	return nil;
}

- (void)setWindowFrame:(NSRect)rect showWindow:(BOOL) showWindow animate: (BOOL) animate
{
	[[self window] setFrame: rect display: NO];
}

- (BOOL) windowWillClose
{
	return NO;
}

- (void)windowWillMove:(NSNotification *)notification
{
	if( magneticWindowActivated)
	{
		windowIsMovedByTheUserO = NO;
		
		if( dontEnterMagneticFunctions == NO)
		{
			savedWindowsFrameO = [[self window] frame];
			
			if( Button()) windowIsMovedByTheUserO = YES;
		}
	}
}

- (void)windowDidMove:(NSNotification *)notification
{
	if( magneticWindowActivated)
	{
		if(/*!Button() && */windowIsMovedByTheUserO == YES && dontEnterMagneticFunctions == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"MagneticWindows"] && NSIsEmptyRect( savedWindowsFrameO) == NO)
		{
			if( Button() == 0) windowIsMovedByTheUserO = NO;
			
			NSEnumerator	*e;
			NSWindow		*theWindow, *window;
			NSRect			frame, myFrame, dstFrame;
			NSValue			*value;
			
			theWindow = [self window];
			myFrame = [theWindow frame];
			
			float gravityX = myFrame.size.width/4;
			float gravityY = myFrame.size.height/4;
			
			if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) return;
			
			NSMutableArray	*rects = [NSMutableArray array];
			
			// Add the viewers
			e = [[NSApp windows] objectEnumerator];
			while (window = [e nextObject])
			{
				if (window != theWindow && [window isVisible] && [[window windowController] isKindOfClass: [OSIWindowController class]] && [window.screen isEqualTo: theWindow.screen])
				{
					if( [[window windowController] magnetic])
						[rects addObject: [NSValue valueWithRect: [window frame]]];
				}
			}
			
			// Add the current screen ONLY
	//		e = [[NSScreen screens] objectEnumerator];
	//		while (screen = [e nextObject])
			{
				NSRect frame = [AppController usefullRectForScreen: [[self window] screen]];
                
				frame = [NavigatorView adjustIfScreenAreaIf4DNavigator: frame];
				
				[rects addObject: [NSValue valueWithRect: frame]];
			}
			
			dstFrame = myFrame;
			
			for (value in rects)
			{
				frame = [value rectValue];
				
				/* horizontal magnet */
				if (fabs(NSMinX(frame) - NSMinX(myFrame)) <= gravityX)
				{
					gravityX = fabs(NSMinX(frame) - NSMinX(myFrame));
					dstFrame.origin.x = frame.origin.x;
				}
				if (fabs(NSMinX(frame) - NSMaxX(myFrame)) <= gravityX)
				{
					gravityX = fabs(NSMinX(frame) - NSMaxX(myFrame));
					dstFrame.origin.x = myFrame.origin.x + NSMinX(frame) - NSMaxX(myFrame);
				}
				if (fabs(NSMaxX(frame) - NSMinX(myFrame)) <= gravityX)
				{
					gravityX = fabs(NSMaxX(frame) - NSMinX(myFrame));
					dstFrame.origin.x = NSMaxX(frame);
				}
				if (fabs(NSMaxX(frame) - NSMaxX(myFrame)) <= gravityX)
				{
					gravityX = fabs(NSMaxX(frame) - NSMaxX(myFrame));
					dstFrame.origin.x = myFrame.origin.x + NSMaxX(frame) - NSMaxX(myFrame);
				}
				
				/* vertical magnet */
				if (fabs(NSMinY(frame) - NSMinY(myFrame)) <= gravityY)
				{
					gravityY = fabs(NSMinY(frame) - NSMinY(myFrame));
					dstFrame.origin.y = frame.origin.y;
				}
				if (fabs(NSMinY(frame) - NSMaxY(myFrame)) <= gravityY)
				{
					gravityY = fabs(NSMinY(frame) - NSMaxY(myFrame));
					dstFrame.origin.y = myFrame.origin.y + NSMinY(frame) - NSMaxY(myFrame);
				}
				if (fabs(NSMaxY(frame) - NSMinY(myFrame)) <= gravityY)
				{
					gravityY = fabs(NSMaxY(frame) - NSMinY(myFrame));
					dstFrame.origin.y = NSMaxY(frame);
				}
				if (fabs(NSMaxY(frame) - NSMaxY(myFrame)) <= gravityY)
				{
					gravityY = fabs(NSMaxY(frame) - NSMaxY(myFrame));
					dstFrame.origin.y = myFrame.origin.y + NSMaxY(frame) - NSMaxY(myFrame);
				}
			}
			myFrame = dstFrame;
			
			dontEnterMagneticFunctions = YES;
			[AppController resizeWindowWithAnimation: theWindow newSize: myFrame];
			dontEnterMagneticFunctions = NO;
			
			if( [self isKindOfClass: [ViewerController class]])
				[(ViewerController*) self updateNavigator];
			
			// Is the Origin identical? If yes, switch both windows
			e = [[NSApp windows] objectEnumerator];
			while (window = [e nextObject])
			{
				if (window != theWindow && [window isVisible] && [[window windowController] isKindOfClass: [OSIWindowController class]])
				{
					if( [[window windowController] magnetic])
					{
						frame = [window frame];
						
						if( fabs( frame.origin.x - myFrame.origin.x) < 30 && fabs( NSMaxY( frame) - NSMaxY( myFrame)) < 30)
						{
							dontEnterMagneticFunctions = YES;
							
							[window orderWindow: NSWindowBelow relativeTo: [theWindow windowNumber]];
							[AppController resizeWindowWithAnimation: window newSize: savedWindowsFrameO];
							
							savedWindowsFrameO = frame;
							
							[AppController resizeWindowWithAnimation: theWindow newSize: frame];
							
							dontEnterMagneticFunctions = NO;
							
                            if( [self isKindOfClass: [ViewerController class]])
                                [theWindow.windowController windowDidChangeScreen:nil];
                            
		//					[window makeKeyAndOrderFront: self];
		//					[theWindow makeKeyAndOrderFront: self];
                            
							return;
						}
					}
				}
			}
		}
	}
}

- (void) dealloc
{
    NSLog(@"OSIWindowController released");
    
    self.database = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
	[super dealloc];
}

- (void) windowWillCloseNotification: (NSNotification*) notification
{
	if( [notification object] == [self window] && [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"] == YES && magneticWindowActivated == YES)
	{
		if( delayedTileWindows)
			[NSObject cancelPreviousPerformRequestsWithTarget: [AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
		delayedTileWindows = YES;
		[[AppController sharedAppController] performSelector: @selector(tileWindows:) withObject:nil afterDelay: 0.3];
	}
}

#pragma mark-
#pragma mark Misc

- (short) orthogonalOrientation
{
	return 0;
}

- (BOOL) isEverythingLoaded
{
	return YES;
}

- (void) updateAutoAdjustPrinting: (id) sender
{

}

- (ViewerController*) registeredViewer
{
	return nil;
}

#ifndef OSIRIX_LIGHT
- (IBAction)querySelectedStudy: (id)sender
{
	[[BrowserController currentBrowser] querySelectedStudy: self];
}
#endif

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if (self = [super initWithWindowNibName:(NSString *)windowNibName])
	{
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowWillCloseNotification:) name: NSWindowWillCloseNotification object: nil];
	}
	return self;
}

- (BOOL) FullScreenON
{
	return NO;
}

- (void) removeLastItemFromUndoQueue
{
	NSLog( @"OSIWindowController removeLastItemFromUndoQueue CALL SUPER ??");
}

- (void) addToUndoQueue:(NSString*) what
{
	NSLog( @"OSIWindowController addToUndoQueue CALL SUPER ??");
}

- (IBAction) redo:(id) sender
{
	NSLog( @"OSIWindowController redo CALL SUPER ??");
}

- (IBAction) undo:(id) sender
{
	NSLog( @"OSIWindowController undo CALL SUPER ??");
}

- (NSMutableArray*) pixList
{
	// let subclasses handle it for now
	return nil;
}

- (int)blendingType{
	return _blendingType;
}

- (void) applyShading:(id) sender
{
	NSLog( @"OSIWindowController applyShading - CALL SUPER ??");
}

- (void) ApplyOpacityString: (NSString*) s
{
    N2LogStackTrace( @"ApplyOpacityString - CALL SUPER ??");
}

#pragma mark-
#pragma mark current Core Data Objects

- (DicomStudy *)currentStudy
{
	return nil;
}
- (DicomSeries *)currentSeries
{
	return nil;
}
- (DicomImage *)currentImage
{
	return nil;
}

-(float)curWW{
	return 0.0;
}

-(float)curWL{
	return 0.0;
}
	

@end
