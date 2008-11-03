/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "OSIWindowController.h"
#import "ToolbarPanel.h"
#import "NavigatorView.h"
#import "NavigatorWindowController.h"
#import "AppController.h"
#import "ViewerController.h"
#import "BrowserController.h"

static	BOOL dontEnterMagneticFunctions = NO;
extern  BOOL USETOOLBARPANEL;
extern  ToolbarPanelController  *toolbarPanel[ 10];

@implementation OSIWindowController

#pragma mark-
#pragma mark Magnetic Windows

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

- (void) windowDidResize:(NSNotification *)aNotification
{
	if( magneticWindowActivated)
	{
		if( dontEnterMagneticFunctions == NO && Button() != 0)
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"MagneticWindows"])
			{
				NSEnumerator	*e;
				NSWindow		*theWindow, *window;
				NSScreen		*screen;
				NSValue			*value;
				NSRect			frame, myFrame;
				BOOL			hDidChange = NO, vDidChange = NO;
				
				theWindow = [aNotification object];
				myFrame = [theWindow frame];
				
				float gravityX = 30;
				float gravityY = 30;
				
				if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) return;
				
				NSMutableArray	*rects = [NSMutableArray array];
				
				// Add the viewers
				e = [[NSApp windows] objectEnumerator];
				while (window = [e nextObject])
				{
					if (window != theWindow && [window isVisible] && [[window windowController] isKindOfClass: [OSIWindowController class]])
					{
						if( [[window windowController] magnetic])
							[rects addObject: [NSValue valueWithRect: [window frame]]];
					}
				}
				
				// Add the current screen ONLY
	//			e = [[NSScreen screens] objectEnumerator];
	//			while (screen = [e nextObject])
				{
					NSRect frame = [[[self window] screen] visibleFrame];
					if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
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
					[(ViewerController*) self matrixPreviewSelectCurrentSeries];
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
			
			if( USETOOLBARPANEL)
			{
				if( dstFrame.size.height >= [[[self window] screen] visibleFrame].size.height - [ToolbarPanelController fixedHeight])
				{
					dstFrame.size.height = [[[self window] screen] visibleFrame].size.height - [ToolbarPanelController fixedHeight];
				}
			}
			
			if( dstFrame.size.height < [[self window] contentMinSize].height) dstFrame.size.height = [[self window] contentMinSize].height;
			if( dstFrame.size.width < [[self window] contentMinSize].width) dstFrame.size.width = [[self window] contentMinSize].width;
			
			
			dstFrame = [NavigatorView adjustIfScreenAreaIf4DNavigator: dstFrame];
			
			if( NSEqualRects( dstFrame, [[self window] frame]) == NO)
				[[self window] setFrame: dstFrame display:YES];
		}
		
		if( [self isKindOfClass: [ViewerController class]])
		{
			[(ViewerController*)self showCurrentThumbnail: self];
		}
	}
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
		if( windowIsMovedByTheUserO == YES && dontEnterMagneticFunctions == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"MagneticWindows"] && NSIsEmptyRect( savedWindowsFrameO) == NO)
		{
			if( Button() == 0) windowIsMovedByTheUserO = NO;
			
			NSEnumerator	*e;
			NSWindow		*theWindow, *window;
			NSRect			frame, myFrame, dstFrame;
			BOOL			hDidChange = NO, vDidChange = NO;
			NSScreen		*screen;
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
				if (window != theWindow && [window isVisible] && [[window windowController] isKindOfClass: [OSIWindowController class]])
				{
					if( [[window windowController] magnetic])
						[rects addObject: [NSValue valueWithRect: [window frame]]];
				}
			}
			
			// Add the current screen ONLY
	//		e = [[NSScreen screens] objectEnumerator];
	//		while (screen = [e nextObject])
			{
				NSRect frame = [[[self window] screen] visibleFrame];
				if( USETOOLBARPANEL) frame.size.height -= [ToolbarPanelController fixedHeight];
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
						
						if( fabs( frame.origin.x - myFrame.origin.x) < 3 && fabs( NSMaxY( frame) - NSMaxY( myFrame)) < 3)
						{
							dontEnterMagneticFunctions = YES;
							
							[window orderWindow: NSWindowBelow relativeTo: [theWindow windowNumber]];
							[AppController resizeWindowWithAnimation: window newSize: savedWindowsFrameO];
							
							savedWindowsFrameO = frame;
							
							[AppController resizeWindowWithAnimation: theWindow newSize: frame];
							
							dontEnterMagneticFunctions = NO;
							
		//					[window makeKeyAndOrderFront: self];
		//					[theWindow makeKeyAndOrderFront: self];
		//					[self refreshToolbar];
							
							return;
						}
					}
				}
			}
		}
	}
}

#pragma mark-
#pragma mark Misc

- (IBAction)querySelectedStudy: (id)sender
{
	[[BrowserController currentBrowser] querySelectedStudy: self];
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if (self = [super initWithWindowNibName:(NSString *)windowNibName])
	{
	}
	return self;
}

 - (BOOL) FullScreenON
 {
	return NO;
 }

- (void)dealloc
{
	[super dealloc];
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

#pragma mark-
#pragma mark current Core Data Objects

- (NSManagedObject *)currentStudy{
	return nil;
}
- (NSManagedObject *)currentSeries{
	return nil;
}
- (NSManagedObject *)currentImage{
	return nil;
}

-(float)curWW{
	return 0.0;
}

-(float)curWL{
	return 0.0;
}
	

@end
