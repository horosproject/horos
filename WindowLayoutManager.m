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
#import "Window3DController.h"
#import "browserController.h"
#import "VRController.h"
#import "VRControllerVPRO.h"
#import "MPR2DController.h"
#import "OrthogonalMPRViewer.h"
#import "SRController.h"
#import "EndoscopyViewer.h"



WindowLayoutManager *sharedLayoutManager;

@implementation WindowLayoutManager

+ (id)sharedWindowLayoutManager{
	if (!sharedLayoutManager)
		sharedLayoutManager = [[WindowLayoutManager alloc] init];
	return sharedLayoutManager;
}

- (id)init{
	if (self = [super init]) {
		_windowControllers = [[NSMutableArray alloc] init];
		_hangingProtocolInUse = NO;
		_seriesSetIndex = 0;
	}
	return self;
}


#pragma mark-
#pragma mark WindowController registration
- (void)registerWindowController:(OSIWindowController *)controller{
		//NSLog(@"registerWindowController: %@", [controller description]);
	if (![_windowControllers containsObject:controller]){
		//NSLog(@"Add Controller");
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

	//NSLog(@"tile Windows");
	
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
		//NSLog(@"NO tiling");
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
	return _currentHangingProtocol;
}


#pragma mark-
#pragma mark Advanced Hanging
-(BOOL)hangStudy:(id)study{
	// clear current Hanging Protocol;

	if ([[[study entity] name] isEqualToString:@"Study"]) {
		[self setCurrentHangingProtocolForModality:nil description: nil];
		_currentStudy = study;
		
			// DICOM & others
			/* Need to improve Hanging Protocols	
				Things Advanced Hanging Protocol needs to do.
				For Advanced Hanging Protocols Need to Search for Comparisons
				Arrange Series in a Particular order by either series description or series number
				Could have preset ww/wl and CLUT
				Series Fusion at start
				Could have a 3D ViewerController instead of a 2D ViewerController
					If 2D viewer need to set starting orientation, wwwl, CLUT, if SR preset surfaces.
					Preprocess Volume - extract heart, Get Center line for vessel Colon, etc
					
				Root object is NSArray we can search through with predicates to get a filteredArray
			*/
			
		BrowserController *browserController = [BrowserController currentBrowser];
		NSArray *advancedHangingProtocols = [[NSUserDefaults standardUserDefaults] objectForKey: @"ADVANCEDHANGINGPROTOCOLS"];
		NSPredicate *modalityPredicate = [NSPredicate predicateWithFormat:@"modality like[cd] %@", [study valueForKey:@"modality"]];
		NSPredicate *studyDescriptionPredicate = [NSPredicate predicateWithFormat:@"studyDescription like[cd] %@", [study valueForKey:@"studyName"]];
		NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:modalityPredicate, studyDescriptionPredicate, nil]];
		NSArray *filteredHangingProtocols = [advancedHangingProtocols filteredArrayUsingPredicate:compoundPredicate];
		
		// get comparisons
		//[self setRelatedStudies:[browserController relatedStudiesForStudy:_currentStudy]];
		//NSLog(@"comparison: %@", [self comparionStudy]);

		if ([filteredHangingProtocols count] > 0) {
			// ? Add'l Filter for institution  or add'l attributes here ?
			// Possible to have more than one Protocol.  Give user option to pick which one.
			// How to handle comparisons. Would like to a bodyRegion Attribute to study Ideally handle comparisons differently depending on comparison's Modality
			// For now just use the first one
			
			NSDictionary *hangingProtocol = [filteredHangingProtocols objectAtIndex:0];
			// Have a sequence of an arrangement of sets. Could loop through using the next and previous series buttons
			_seriesSets = [hangingProtocol objectForKey:@"seriesSets"];
			NSArray *firstSet = [_seriesSets objectAtIndex:0];
			
			//rearrange Children based on SeriesDescription or Number then pass to viewerDICOMInt. At this time cannot control window size or arrangement
			[self hangSet:firstSet];
					
			[_advancedHangingProtocol release];
			_advancedHangingProtocol = [hangingProtocol copy];
			_hangingProtocolInUse = YES;
			return YES;
		}
		else {
			_hangingProtocolInUse = NO;
			return NO;		
		}
	}
	else {
		_hangingProtocolInUse = NO;
		return NO;	
	}
}

#pragma mark-
#pragma mark Moving Through Series Sets
- (void)nextSeriesSet{
	_seriesSetIndex++;
	if (_seriesSetIndex >= [_seriesSets count])
		_seriesSetIndex = 0;
	NSArray *array = [_seriesSets objectAtIndex:_seriesSetIndex];
	[self hangSet:array];
}


- (void)previousSeriesSet{
	_seriesSetIndex--;
	if (_seriesSetIndex < 0 )
		_seriesSetIndex = [_seriesSets count] - 1;
	NSArray *array = [_seriesSets objectAtIndex:_seriesSetIndex];
	[self hangSet:array];
}

- (void)hangSet:(NSArray *)seriesSet{
	//rearrange Children based on SeriesDescription or Number then pass to viewerDICOMInt. At this time cannot control window size or arrangement
	NSDictionary *seriesInfo;
	NSEnumerator *enumerator = [seriesSet objectEnumerator];
	NSMutableArray *children =  [NSMutableArray array];
	BrowserController *browserController = [BrowserController currentBrowser];
	int count = [[browserController childrenArray: _currentStudy] count];
	NSMutableArray *usableViewers = [NSMutableArray arrayWithArray:[self viewers2D]];
	while (seriesInfo = [enumerator nextObject]){
		// only load ViewerControllers first

		if ( [[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([ViewerController class])] ){
			int i;	
			id seriesToOpen = nil;	
			BOOL openViewer = NO;					
			for (i = 0; i < count; i++) {				
				id child = [[browserController childrenArray: _currentStudy] objectAtIndex:i];
				// if series description is unnamed used series number
				if ([[seriesInfo objectForKey:@"seriesDescription"] isEqualToString:@"unnamed"]){
					if ([[child valueForKey:@"id"] intValue] == [[seriesInfo objectForKey:@"seriesNumber"] intValue]) {
						[children addObject:child];
						seriesToOpen = child;
						openViewer = YES;
						break;
					}
				}
				else {
					if ([[child valueForKey:@"name"] isEqualToString:[seriesInfo objectForKey:@"seriesDescription"]]) {
						[children addObject:child];
						seriesToOpen = child;
						openViewer = YES;
						break;
					}
				}
			}
			// Reuse Viewer if Series Already open
			if (openViewer == YES) {							
				ViewerController *viewer = nil;
				ViewerController *viewerForSeries = nil;
				NSEnumerator *viewerEnumerator = [usableViewers objectEnumerator];
				
				while (viewer = [viewerEnumerator nextObject]) {
					if ([[viewer currentSeries] isEqual:seriesToOpen]) {
						viewerForSeries = viewer;
						break;
					}
				}
				
				if (viewerForSeries)
					// save viewer
					[usableViewers removeObject:viewerForSeries];
				else	
					// new Viewer
					[browserController loadSeries:seriesToOpen :nil :NO keyImagesOnly:NO];
			}
			
			
		}
	}
	
	//resizeWindows
	// A new hanging protocol should start with a fresh set of WindowControllers that should match the 2D Viewers
	//Close unused Viewers	
	ViewerController *viewer = nil;
	NSEnumerator *viewerEnumerator = [usableViewers objectEnumerator];
	while (viewer = [viewerEnumerator nextObject])
		[viewer close];
	
	//go through a second time for 2d viewers to adjust window frame, zoom, wwwl, rotation, etc
	// need to make this more efficient
	enumerator = [seriesSet objectEnumerator];
	NSEnumerator *windowEnumerator = [_windowControllers objectEnumerator];
	ViewerController *controller;
	while (seriesInfo = [enumerator nextObject]){
		if ( [[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([ViewerController class])] ){
			controller = [windowEnumerator nextObject];
			[[controller window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];
			[controller setRotation:[[seriesInfo objectForKey:@"rotation"] floatValue]];
			[controller setScaleValue:[[seriesInfo objectForKey:@"zoom"] floatValue]];
			
			if ([[seriesInfo objectForKey:@"wwwlMenuItem"] isEqualToString:NSLocalizedString(@"Other", nil)])
				[controller setWL:[[seriesInfo objectForKey:@"wl"] floatValue] WW:[[seriesInfo objectForKey:@"wl"] floatValue]];
			else {
				[controller setCurWLWWMenu:[seriesInfo objectForKey:@"wwwlMenuItem"]];
			}
			
			[controller ApplyCLUTString:[seriesInfo objectForKey:@"CLUTName"]];
			
			NSString *blendingSeriesDescription = nil;
			if (blendingSeriesDescription = [seriesInfo objectForKey:@"blendingSeriesDescription"]){
				//find blendingViewer
				NSEnumerator *blendingEnumerator = [_windowControllers objectEnumerator];
				ViewerController *blendingController;
				int blendingType = [[seriesInfo objectForKey:@"blendingType"] intValue];
				while (blendingController = [blendingEnumerator nextObject]){
					if ([blendingSeriesDescription isEqualToString:@"unnamed"]){
					//use Series Number
						if ([[[blendingController currentSeries] valueForKey:@"id"] intValue] ==  [[seriesInfo objectForKey:@"blendingSeriesNumber"] intValue])
							//[controller ActivateBlending:blendingController]; //This is fusion. Don't have other blendings yet
							[controller blendWithViewer:blendingController blendingType:blendingType];
					}
					else {
					//use Series Description
						if ([[[blendingController currentSeries] valueForKey:@"name"] isEqualToString:blendingSeriesDescription])
							//[controller ActivateBlending:blendingController]; //This is fusion. Don't have other blendings yet
							[controller blendWithViewer:blendingController blendingType:blendingType];
					}
				}
			}
			if ([[seriesInfo objectForKey:@"isKeyWindow"] boolValue])
				[[controller window] makeKeyAndOrderFront:self];
		}
	}
	// Need to do fusion/ Subtration/ open 3D Windows
	// Once we have 2D windows opened and fused can look for 3D windows to open  
	[NSApp sendAction: @selector(checkAllWindowsAreVisible:) to:0L from: self];
	enumerator = [seriesSet objectEnumerator];
	
	//ViewerController *controller;
	while (seriesInfo = [enumerator nextObject]){
		// have a 3D Viewer
		//NSLog(@"look for 3D Viewer: %@", [seriesInfo objectForKey:@"Viewer Class"]);
		if ( ![[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([ViewerController class])] ){
			//NSLog(@"have 3D Viewer");
			windowEnumerator = [[self viewers2D] objectEnumerator];
			id viewer2D;
			id selectedViewer2D = nil;
			// find the right 2D viewer based on Series Description and number
			//NSLog(@"Look for 2D viewer");
			while (viewer2D = [windowEnumerator nextObject]) {
				id viewerSeries = [viewer2D currentSeries];
				if ([[seriesInfo objectForKey:@"seriesDescription"] isEqualToString:@"unnamed"]){
					if ([[viewerSeries valueForKey:@"id"] intValue] == [[seriesInfo objectForKey:@"seriesNumber"] intValue]) {
						selectedViewer2D = viewer2D;
						break;
					}
				}
				else {
					if ([[viewerSeries valueForKey:@"name"] isEqualToString:[seriesInfo objectForKey:@"seriesDescription"]]) {
						selectedViewer2D = viewer2D;
						break;
					}
				}
			}
			// if we found a 2D Viewer, open the 3D viewer based on the Class Name
			if (selectedViewer2D) {
				//NSLog(@"Have 2D viewer: %@", [selectedViewer2D description]);
				id viewer3D;
				if ( [[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([VRController class])] ) {
					//NSLog(@"3D viewer: %@", [seriesInfo objectForKey:@"Viewer Class"]);
					NSString *mode = @"VR";
					viewer3D = [selectedViewer2D openVRViewerForMode:(NSString *)mode];
					[viewer3D  ApplyCLUTString:[seriesInfo objectForKey:@"CLUTName"]];
					//float   iwl, iww;
					//[[selectedViewer2D imageView] getWLWW:&iwl :&iww];
					[viewer3D setWLWW:[[seriesInfo objectForKey:@"wl"] floatValue] :[[seriesInfo objectForKey:@"ww"] floatValue]];
					[viewer3D load3DState];
					[viewer3D showWindow:self];
					[[viewer3D window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];
					//[[viewer3D window] makeKeyAndOrderFront:self];
					[[viewer3D window] display];
					if (![[[viewer3D window] title] hasSuffix:[[selectedViewer2D window] title]])
						[[viewer3D window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer3D window] title], [[selectedViewer2D window] title]]];
				}
				else if ( [[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([VRPROController class])] ) {
					//NSLog(@"3D viewer: %@", [seriesInfo objectForKey:@"Viewer Class"]);
					NSString *mode = @"VR";
					viewer3D = [selectedViewer2D openVRVPROViewerForMode:(NSString *)mode];
					[viewer3D  ApplyCLUTString:[seriesInfo objectForKey:@"CLUTName"]];
					//float   iwl, iww;
					//[[selectedViewer2D imageView] getWLWW:&iwl :&iww];
					[viewer3D setWLWW:[[seriesInfo objectForKey:@"wl"] floatValue] :[[seriesInfo objectForKey:@"ww"] floatValue]];
					[viewer3D load3DState];
					[viewer3D showWindow:self];
					[[viewer3D window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];
					//[[viewer3D window] makeKeyAndOrderFront:self];
					[[viewer3D window] display];
					if (![[[viewer3D window] title] hasSuffix:[[selectedViewer2D window] title]])
						[[viewer3D window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer3D window] title], [[selectedViewer2D window] title]]];
				}
				else if ([[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([EndoscopyViewer class])] ) { 
					viewer3D = [selectedViewer2D openEndoscopyViewer];
					[viewer3D showWindow:self];
					[[viewer3D window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];
					[[viewer3D window] display];
					if (![[[viewer3D window] title] hasSuffix:[[selectedViewer2D window] title]])
						[[viewer3D window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer3D window] title], [[selectedViewer2D window] title]]];
				}
				else if ( [[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([MPR2DController class])] ) { 
					viewer3D = [selectedViewer2D openMPR2DViewer];
					[viewer3D ApplyCLUTString:[seriesInfo objectForKey:@"CLUTName"]];
					//float   iwl, iww;
					//[imageView getWLWW:&iwl :&iww];
					[viewer3D setWLWW:[[seriesInfo objectForKey:@"wl"] floatValue] :[[seriesInfo objectForKey:@"ww"] floatValue]];
					[viewer3D  ApplyCLUTString:[seriesInfo objectForKey:@"CLUTName"]];
					[viewer3D load3DState];
					[viewer3D showWindow:self];
					[[viewer3D window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];
					if (![[[viewer3D window] title] hasSuffix:[[selectedViewer2D window] title]])
						[[viewer3D window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer3D window] title], [[selectedViewer2D window] title]]];
				}
				else if ([[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([OrthogonalMPRViewer class])] ) { 				
					viewer3D = [selectedViewer2D openOrthogonalMPRViewer];
					[viewer3D setWLWW:[[seriesInfo objectForKey:@"wl"] floatValue] :[[seriesInfo objectForKey:@"ww"] floatValue]];
					[viewer3D  ApplyCLUTString:[seriesInfo objectForKey:@"CLUTName"]];
					[viewer3D showWindow:self];
					[[viewer3D window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];					
					//float   iwl, iww;
					//[imageView getWLWW:&iwl :&iww];
					//[viewer3D setWLWW:iwl :iww];
					if (![[[viewer3D window] title] hasSuffix:[[selectedViewer2D window] title]])
						[[viewer3D window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer3D window] title], [[selectedViewer2D window] title]]];
				}
				else if ([[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([OrthogonalMPRPETCTViewer class])] ) { 				
					viewer3D = [selectedViewer2D openOrthogonalMPRPETCTViewer];
					[[viewer3D window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];
					[viewer3D showWindow:self];	
				}
				else if ([[seriesInfo objectForKey:@"Viewer Class"] isEqualToString:NSStringFromClass([SRController class])] ) { 	
					viewer3D = [selectedViewer2D openSRViewer];
					[[viewer3D window] setFrameFromString:[seriesInfo objectForKey:@"windowFrame"]];
					[viewer3D showWindow:self];					
					if (![[[viewer3D window] title] hasSuffix:[[selectedViewer2D window] title]])
						[[viewer3D window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer3D window] title], [[selectedViewer2D window] title]]];
					[viewer3D setFirstSurface:[[seriesInfo objectForKey:@"firstSurface"] floatValue]];
					[viewer3D setSecondSurface:[[seriesInfo objectForKey:@"secondSurface"] floatValue]];
					[viewer3D setResolution:[[seriesInfo objectForKey:@"resolution"] floatValue]];
					[viewer3D setFirstTransparency:[[seriesInfo objectForKey:@"firstTransparency"] floatValue]];
					[viewer3D setSecondTransparency:[[seriesInfo objectForKey:@"secondTransparency"] floatValue]];
					[viewer3D setDecimate:[[seriesInfo objectForKey:@"decimate"] floatValue]];
					[viewer3D setSmooth:[[seriesInfo objectForKey:@"smooth"] intValue]];
					[viewer3D setShouldDecimate:[[seriesInfo objectForKey:@"shouldDecimate"] boolValue]];
					[viewer3D setShouldSmooth:[[seriesInfo objectForKey:@"shouldSmooth"] boolValue]];
					[viewer3D setUseFirstSurface:[[seriesInfo objectForKey:@"useFirstSurface"] boolValue]];
					[viewer3D setUseSecondSurface:[[seriesInfo objectForKey:@"useSecondSurface"] boolValue]];
					NSData *firstColor = [seriesInfo objectForKey:@"firstColor"];
					if (firstColor)
						[viewer3D setFirstColor:[NSUnarchiver unarchiveObjectWithData:firstColor]];
					else
						[viewer3D setFirstColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
						
					NSData *secondColor = [seriesInfo objectForKey:@"secondColor"];
					if (secondColor)	
						[viewer3D setSecondColor:[NSUnarchiver unarchiveObjectWithData:secondColor]];
					else
						[viewer3D setSecondColor:[NSColor colorWithCalibratedRed:1.0 green:0.592 blue:0.608 alpha:1.0]];
					[(SRController *)viewer3D renderSurfaces];
					
					[viewer3D setShouldRenderFusion:[[seriesInfo objectForKey:@"shouldRenderFusion"] boolValue]];
					if ([[seriesInfo objectForKey:@"shouldRenderFusion"] boolValue]){
						[viewer3D setFusionFirstSurface:[[seriesInfo objectForKey:@"fusionFirstSurface"] floatValue]];
						[viewer3D setFusionSecondSurface:[[seriesInfo objectForKey:@"fusionSecondSurface"] floatValue]];
						[viewer3D setFusionResolution:[[seriesInfo objectForKey:@"fusionResolution"] floatValue]];
						[viewer3D setFusionFirstTransparency:[[seriesInfo objectForKey:@"fusionFirstTransparency"] floatValue]];
						[viewer3D setFusionSecondTransparency:[[seriesInfo objectForKey:@"fusionSecondTransparency"] floatValue]];
						[viewer3D setFusionDecimate:[[seriesInfo objectForKey:@"fusionDecimate"] floatValue]];
						[viewer3D setFusionSmooth:[[seriesInfo objectForKey:@"fusionSmooth"] intValue]];
						[viewer3D setFusionShouldDecimate:[[seriesInfo objectForKey:@"fusionShouldDecimate"] boolValue]];
						[viewer3D setFusionShouldSmooth:[[seriesInfo objectForKey:@"fusionShouldSmooth"] boolValue]];
						[viewer3D setFusionUseFirstSurface:[[seriesInfo objectForKey:@"fusionUseFirstSurface"] boolValue]];
						[viewer3D setFusionUseSecondSurface:[[seriesInfo objectForKey:@"fusionUseSecondSurface"] boolValue]];
						NSData *fusionFirstColor = [seriesInfo objectForKey:@"fusionFirstColor"];
						if (fusionFirstColor)
							[viewer3D setFusionFirstColor:[NSUnarchiver unarchiveObjectWithData:fusionFirstColor]];
						else
							[viewer3D setFusionFirstColor:[NSColor colorWithCalibratedRed:1.0 green:0.285 blue:0.0 alpha:1.0]];
							
						NSData *fusionSecondColor = [seriesInfo objectForKey:@"fusionSecondColor"];
						if (fusionSecondColor)	
							[viewer3D setFusionSecondColor:[NSUnarchiver unarchiveObjectWithData:fusionSecondColor]];
						else
							[viewer3D setFusionSecondColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.0 alpha:1.0]];
						[(SRController *)viewer3D renderFusionSurfaces];
						
					}
				
				}
				
				
				if ([[seriesInfo objectForKey:@"isKeyWindow"] boolValue])
					[[viewer3D  window] makeKeyAndOrderFront:self];
			}
		}
	}
	
	
	if (![_windowControllers containsObject:[[NSApp keyWindow] windowController]])
		[[[_windowControllers objectAtIndex:0] window] makeKeyAndOrderFront:self];
}

- (BOOL)hangingProtocolInUse{
	return _hangingProtocolInUse;
}

#pragma mark-
#pragma mark Subarrays of Window Controllers
- (NSArray *)viewers2D{
	NSEnumerator *enumerator = [_windowControllers objectEnumerator];
	OSIWindowController *controller;
	NSMutableArray *array = [NSMutableArray array];
	while (controller = [enumerator nextObject]){
		if ([controller isKindOfClass:[ViewerController class]])
			[array addObject:controller];
	}
	return array;
}

- (NSArray *)viewers3D{
	NSEnumerator *enumerator = [_windowControllers objectEnumerator];
	OSIWindowController *controller;
	NSMutableArray *array = [NSMutableArray array];
	while (controller = [enumerator nextObject]){
		if ([controller isKindOfClass:[Window3DController class]])
			[array addObject:controller];
	}
	return array;
}

- (NSArray *)viewers{
	return _windowControllers;
}

-(NSArray *)viewers2DForSeries:(id)series{
}

#pragma mark-
#pragma mark Comparisons
- (NSArray *)relatedStudies{
	return _relatedStudies;
}

- (void)setRelatedStudies:(NSArray *)relatedStudies{
	[_relatedStudies release];
	_relatedStudies = [relatedStudies retain];
}

- (id)comparionStudy{
	if ([[self comparisonStudies] count] > 0)
		return [[self comparisonStudies] objectAtIndex:0];
	return nil;
}

- (NSArray *)comparisonStudies{
	NSMutableArray *comparisonStudies = [NSMutableArray array];
	
		NSArray *bodyRegions = [[NSUserDefaults standardUserDefaults] objectForKey:@"bodyRegions"];
	NSEnumerator  *enumerator = [bodyRegions objectEnumerator];
	NSDictionary *region;
	NSDictionary *bodyRegion = nil;
	NSString *studyDescription = [_currentStudy valueForKey:@"studyName"];
	// find body Region
	while ((region = [enumerator nextObject]) && bodyRegion == nil){
		NSEnumerator *keywordEnumerator = [[region objectForKey:@"keywords"] objectEnumerator];
		NSDictionary *keywordDict;
		while (keywordDict = [keywordEnumerator  nextObject]){
			NSString *keyword = [keywordDict valueForKey: @"region"];
			if ([studyDescription rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound) {
				bodyRegion =  region;
			}
		}
	}
	
	// if we found a match for body region look for a match in between a keyword and the potential comparions study Name (description)
	if (bodyRegion) {
		id comparisonStudy = nil;
		NSEnumerator *comparisonEnumerator = [_relatedStudies objectEnumerator];
		while (comparisonStudy  = [comparisonEnumerator nextObject]) {
			NSEnumerator *keywordEnumerator = [[bodyRegion objectForKey:@"keywords"] objectEnumerator];
			NSDictionary *keywordDict;
			while (keywordDict = [keywordEnumerator  nextObject]){
				NSString *keyword = [keywordDict valueForKey: @"region"];
				if ([[comparisonStudy valueForKey:@"studyName"] rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound)
					[comparisonStudies addObject: comparisonStudy];
			}
		}
	}
	return comparisonStudies;
}
	




	

@end
