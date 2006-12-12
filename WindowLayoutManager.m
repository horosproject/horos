//
//  WindowLayoutManager.m
//  OsiriX
//
//  Created by Lance Pysher on 12/11/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "WindowLayoutManager.h"
#import "ViewerController.h"
#import "AppController.h"
#import "ToolbarPanel.h"
#import "OSIWindowController.h"



WindowLayoutManager *sharedLayoutManager;

@implementation WindowLayoutManager

+ (id)sharedWindowLayoutManager{
	if (!sharedLayoutManager)
		sharedLayoutManager = [[WindowLayoutManager alloc] init];
	return sharedLayoutManager;
}

- (id)init{
	if (self = [super init])
		_windowControllers = [[NSMutableArray alloc] init];
	return self;
}


#pragma mark-
#pragma mark WindowController registration
- (void)registerWindowController:(OSIWindowController *)controller{
	if (![_windowControllers containsObject:controller]){
		[_windowControllers addObject:controller];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object:[controller window]];
	}
}

- (void)unregisterWindowController:(OSIWindowController *)controller{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[controller window]];
	[_windowControllers removeObject:controller];
}

- (void)windowWillClose:(NSNotification *)notification{
	NSWindowController *controller = [[notification  object] windowController];
	if ([controller isKindOfClass:[OSIWindowController class]])
		[self unregisterWindowController:(OSIWindowController *)controller];
}


- (id) findViewerWithNibNamed:(NSString*) nib andPixList:(NSMutableArray*) pixList
{

	NSEnumerator		*enumerator = [_windowControllers objectEnumerator];
	OSIWindowController			*windowController;
	while (windowController = [enumerator nextObject])
	{
		if( [[windowController windowNibName] isEqualToString: nib])
		{
			if( [[windowController pixList] isEqual: pixList])
				return windowController;
		}
	}
	
	return 0L;
}

- (NSArray*) findRelatedViewersForPixList:(NSMutableArray*) pixList
{
	NSEnumerator		*enumerator = [_windowControllers objectEnumerator];
	OSIWindowController			*windowController;
	
	NSMutableArray		*viewersList = [NSMutableArray array];
	
	while (windowController = [enumerator nextObject])
	{
		if( [ windowController respondsToSelector:@selector( pixList)])
		{
			if( [[windowController pixList] isEqual: pixList])
			{
				[viewersList addObject: windowController];
			}
		}
	}
	
	return viewersList;
}



- (NSRect) resizeWindow:(NSWindow*) win	withInRect:(NSRect) destRect
{
	NSRect	returnRect = [win frame];
	
	switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"WINDOWSIZEVIEWER"])
	{
		case 0:
			returnRect = destRect;
		break;
		
		default:
			if( returnRect.size.width > destRect.size.width) returnRect.size.width = destRect.size.width;
			if( returnRect.size.height > destRect.size.height) returnRect.size.height = destRect.size.height;
			
			// Center
			
			returnRect.origin.x = destRect.origin.x + destRect.size.width/2 - returnRect.size.width/2;
			returnRect.origin.y = destRect.origin.y + destRect.size.height/2 - returnRect.size.height/2;
		break;
	}
	
	return returnRect;
}

- (void) checkAllWindowsAreVisible:(id) sender
{
	NSEnumerator		*enumerator = [_windowControllers objectEnumerator];
	OSIWindowController			*windowController;
	
	while (windowController = [enumerator nextObject])
	{
		if( [ windowController isKindOfClass:[ViewerController class]])
				[[windowController window] orderFront:self];
	}
}

- (void) tileWindows:(id)sender
{
	long				i, j, k;
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	BOOL				tileDone = NO, origCopySettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYSETTINGS"];
	NSRect				screenRect =  screenFrame();
	
	int					keyWindow = 0, numberOfMonitors = [[[AppController sharedAppController] viewerScreens] count];	

	NSLog(@"tile Windows");
	
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"COPYSETTINGS"];
	
	//get 2D viewer windows
	for( i = 0; i < [winList count]; i++)
	{
		if(	[[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
		{
			[viewersList addObject: [[winList objectAtIndex:i] windowController]];
			
			if( [[winList objectAtIndex:i] isKeyWindow]) keyWindow = [viewersList count]-1;
		}
	}
	
	// get viewer count
	int viewerCount = [viewersList count];
	
	NSArray *screens = [[AppController sharedAppController] viewerScreens];
	
	//NSLog(@"viewers: %d, screens: %d", viewerCount, numberOfMonitors);
	
	screenRect = [[screens objectAtIndex:0] visibleFrame];
	BOOL landscape = (screenRect.size.width/screenRect.size.height > 1) ? YES : NO;
	if (landscape)
		NSLog(@"Landscape");
	else
		NSLog(@"portrait");

	tileDone = YES;
		
	int rows = [[_currentHangingProtocol objectForKey:@"Rows"] intValue];
	int columns = [[_currentHangingProtocol objectForKey:@"Columns"] intValue];
	
	if (!_currentHangingProtocol)
	{
		if (landscape) {
			columns = 2 * numberOfMonitors;
			rows = 1;
		}
		else {
			columns = numberOfMonitors;
			rows = 2;
		}
	}
	
	//excess viewers. Need to add spaces to accept
	while (viewerCount > (rows * columns)){
		float ratio = ((float)columns/(float)rows)/numberOfMonitors;
		//NSLog(@"ratio: %f", ratio);
		if (ratio > 1.5 && landscape)
			rows ++;
		else 
			columns ++;
	}
	
	
	// set image tiling to 1 row and columns
	if (![[NSUserDefaults standardUserDefaults] integerForKey: @"IMAGEROWS"])
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGEROWS"];
	if (![[NSUserDefaults standardUserDefaults] integerForKey: @"IMAGECOLUMNS"])
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGECOLUMNS"];
	//I will generalize the options once I get a handle on the issues. LP
	// if monitor count is greater than or equal to viewers. One viewer per window
	if (viewerCount <= numberOfMonitors) {
		int count = [viewersList count];
		int skipScreen = 0;
		
		for( i = 0; i < count; i++) {
			NSScreen *screen = [screens objectAtIndex:i];
			NSRect frame = [screen visibleFrame];
			if(_useToolbarPanel) frame.size.height -= [ToolbarPanelController fixedHeight];
			
			[[viewersList objectAtIndex:i] setWindowFrame: [self resizeWindow: [[viewersList objectAtIndex:i] window] withInRect: frame]];				

		}
	} 
	/* 
	Will have columns but no rows. 
	There are more columns than monitors. 
	 Need to separate columns among the window evenly
	 */
	else if((viewerCount <= columns) &&  (viewerCount % numberOfMonitors == 0)){
		int viewersPerScreen = viewerCount / numberOfMonitors;
		for( i = 0; i < viewerCount; i++) {
			int index = (int) i/viewersPerScreen;
			int viewerPosition = i % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:index];
			NSRect frame = [screen visibleFrame];
			
			if(_useToolbarPanel) frame.size.height -= [ToolbarPanelController fixedHeight];
			frame.size.width /= viewersPerScreen;
			frame.origin.x += (frame.size.width * viewerPosition);
			
			[[viewersList objectAtIndex:i] setWindowFrame: frame];
		}		
	} 
	//have different number of columns in each window
	else if( viewerCount <= columns) 
	{
		int viewersPerScreen = ceil(((float) columns / numberOfMonitors));

		int extraViewers = viewerCount % numberOfMonitors;
		for( i = 0; i < viewerCount; i++) {
			int monitorIndex = (int) i /viewersPerScreen;
			int viewerPosition = i % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:monitorIndex];
			NSRect frame = [screen visibleFrame];
			
			if(_useToolbarPanel) frame.size.height -= [ToolbarPanelController fixedHeight];
			if (monitorIndex < extraViewers) 
				frame.size.width /= viewersPerScreen;
			else
				frame.size.width /= (viewersPerScreen - 1);
				
			frame.origin.x += (frame.size.width * viewerPosition);
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame];
		}
	}
	//adjust for actual number of rows needed
	else if (viewerCount <=  columns * rows)  
	{
		int viewersPerScreen = ceil(((float) columns / numberOfMonitors));
		int extraViewers = columns % numberOfMonitors;
		for( i = 0; i < viewerCount; i++) {
			int row = i/columns;
			int columnIndex = (i - (row * columns));
			int monitorIndex =  columnIndex /viewersPerScreen;
			int viewerPosition = columnIndex % viewersPerScreen;
			NSScreen *screen = [screens objectAtIndex:monitorIndex];
			NSRect frame = [screen visibleFrame];

			if(_useToolbarPanel) frame.size.height -= [ToolbarPanelController fixedHeight];
			
			if (monitorIndex < extraViewers || extraViewers == 0) 
				frame.size.width /= viewersPerScreen;
			else
				frame.size.width /= (viewersPerScreen - 1);
			
			frame.origin.x += (frame.size.width * viewerPosition);
			if( i == viewerCount-1)
			{
				frame.size.width = [screen visibleFrame].size.width - (frame.origin.x - [screen visibleFrame].origin.x);
			}
			
			frame.size.height /= rows;
			frame.origin.y += frame.size.height * ((rows - 1) - row);
			
			[[viewersList objectAtIndex:i] setWindowFrame:frame];
		}
	}
	else
	{
		NSLog(@"NO tiling");
		tileDone = NO;
	}
	
	[[NSUserDefaults standardUserDefaults] setBool: origCopySettings forKey: @"COPYSETTINGS"];
	
	if( [viewersList count] > 0)
	{
		[[[viewersList objectAtIndex: keyWindow] window] makeKeyAndOrderFront:self];
		[[viewersList objectAtIndex: keyWindow] propagateSettings];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"])
		{
			for( i = 0; i < [viewersList count]; i++)
			{
				[[viewersList objectAtIndex: i] autoHideMatrix];
			}
		}
		
		[[[viewersList objectAtIndex: keyWindow] imageView] becomeMainWindow];
	}
	
	[viewersList release];
}


#pragma mark-
#pragma mark hanging protocol setters and getters
- (void) setCurrentHangingProtocolForModality: (NSString *) modality description: (NSString *) description
{
	NSLog(@"setCurrentHangingProtocol modality: %@ description: %@", modality,  description);
	// if no modality set to 1 row and 1 column
	if (!modality )
	{
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGEROWS"];
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"IMAGECOLUMNS"];

	}
	else
	{
		//Search for a hanging Protocol for the study description in the modality array
		NSArray *hangingProtocolArray = [[[NSUserDefaults standardUserDefaults] objectForKey: @"HANGINGPROTOCOLS"] objectForKey: modality];
		if ([hangingProtocolArray count] > 0) {
			NSEnumerator *enumerator = [hangingProtocolArray objectEnumerator];

			[_currentHangingProtocol release];
			_currentHangingProtocol = nil;
			_currentHangingProtocol = [hangingProtocolArray objectAtIndex:0];

			[[NSUserDefaults standardUserDefaults] setInteger: [[_currentHangingProtocol objectForKey: @"Image Rows"] intValue] forKey: @"IMAGEROWS"];
			[[NSUserDefaults standardUserDefaults] setInteger: [[_currentHangingProtocol objectForKey: @"Image Columns"] intValue] forKey: @"IMAGECOLUMNS"];
			
			NSMutableDictionary *protocol;
			while (protocol = [enumerator nextObject]) {
				NSRange searchRange = [description rangeOfString:[protocol objectForKey: @"Study Description"] options: NSCaseInsensitiveSearch | NSLiteralSearch];
				if (searchRange.location != NSNotFound) {
					_currentHangingProtocol = protocol;

					[[NSUserDefaults standardUserDefaults] setInteger: [[_currentHangingProtocol objectForKey: @"Image Rows"] intValue] forKey: @"IMAGEROWS"];
					[[NSUserDefaults standardUserDefaults] setInteger: [[_currentHangingProtocol objectForKey: @"Image Columns"] intValue] forKey: @"IMAGECOLUMNS"];

					break;
				}
			}
			
			[_currentHangingProtocol retain];
		}
	}
	
}


- (NSDictionary *) currentHangingProtocol
{
	NSLog(@"CurrentHangingProtocol: %@", [_currentHangingProtocol description]);
	return _currentHangingProtocol;
}




	

@end
