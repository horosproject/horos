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

#import "OrthogonalMPRPETCTViewer.h"
#import "OrthogonalMPRPETCTView.h"

//#import "OrthogonalMIPPETViewer.h"
#import "Mailer.h"
#import "DICOMExport.h"
#import "wait.h"
#import "VRController.h"

static NSString* 	PETCTToolbarIdentifier						= @"PETCT Viewer Toolbar Identifier";
static NSString*	SameHeightSplitViewToolbarItemIdentifier	= @"sameHeightSplitView";
static NSString*	SameWidthSplitViewToolbarItemIdentifier		= @"sameWidthSplitView";
static NSString*	TurnSplitViewToolbarItemIdentifier			= @"turnSplitView";
static NSString*	QTExportToolbarItemIdentifier				= @"QTExport.icns";
static NSString*	ToolsToolbarItemIdentifier					= @"Tools";
static NSString*	ThickSlabToolbarItemIdentifier				= @"ThickSlab";
static NSString*	BlendingToolbarItemIdentifier				= @"2DBlending";
static NSString*	MovieToolbarItemIdentifier					= @"Movie";
static NSString*	ExportToolbarItemIdentifier					= @"Export.icns";
static NSString*	MailToolbarItemIdentifier					= @"Mail.icns";
static NSString*	ResetToolbarItemIdentifier					= @"Reset.tiff";
static NSString*	MIPToolbarItemIdentifier					= @"Empty";
static NSString*	FlipVolumeToolbarItemIdentifier				= @"Revert.tiff";
static NSString*	WLWWToolbarItemIdentifier					= @"WLWW";
static NSString*	VRPanelToolbarItemIdentifier				= @"MIP.tif";




NSString * documentsDirectory();

@implementation OrthogonalMPRPETCTViewer

- (void) CloseViewerNotification: (NSNotification*) note
{
	ViewerController	*v = [note object];
	
	if( [[v pixList] containsObject:[[PETController originalDCMPixList] objectAtIndex: 0]])
	{
		[self close];
		return;
	}
	
	if( [[v pixList] containsObject:[[CTController originalDCMPixList] objectAtIndex: 0]])
	{
		[self close];
		return;
	}
}

- (void) Display3DPoint:(NSNotification*) note
{
	NSMutableArray	*v = [note object];
	
	if( [[PETController originalDCMPixList] firstObjectCommonWithArray: v])
	{
		OrthogonalMPRView *view = [PETController originalView];
		
		[view setCrossPosition: [[[note userInfo] valueForKey:@"x"] intValue] :[[[note userInfo] valueForKey:@"y"] intValue]];
		
		view = [PETController xReslicedView];
		
		[view setCrossPosition: [view crossPositionX] :[[PETController originalDCMPixList] count] -1 - ([[[note userInfo] valueForKey:@"z"] intValue] + fistPETSlice)];
	}
	
	if( [[CTController originalDCMPixList] firstObjectCommonWithArray: v])
	{
		OrthogonalMPRView *view = [CTController originalView];
		
		[view setCrossPosition: [[[note userInfo] valueForKey:@"x"] intValue] :[[[note userInfo] valueForKey:@"y"] intValue]];
		
		view = [CTController xReslicedView];
		
		[view setCrossPosition: [view crossPositionX] :[[CTController originalDCMPixList] count] -1 - ([[[note userInfo] valueForKey:@"z"] intValue] + fistCTSlice)];
	}
}

- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC
{
	self = [super initWithWindowNibName:@"PETCT"];
	[[self window] setDelegate:self];
	
	blendingViewerController = [bC retain];
	
	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(CloseViewerNotification:)
											name: @"CloseViewerNotification"
											object: nil];

	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(Display3DPoint:)
											name: @"Display3DPoint"
											object: nil];

	[originalSplitView setDelegate:self];
	[xReslicedSplitView setDelegate:self];
	[yReslicedSplitView setDelegate:self];
	
	[modalitySplitView setDelegate:self];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"orthogonalMPRPETCTVerticalNSSplitView"])
	{
		[self turnModalitySplitView];
	}
	
	// takes the intersection of the CT and the PET stack
	float signCT, signPET;
	signCT = ([[pix objectAtIndex:0] sliceInterval] > 0)? 1.0 : -1.0;
	signPET = ([[[bC pixList] objectAtIndex:0] sliceInterval] > 0)? 1.0 : -1.0;
	
	float firstCTSlice, lastCTSlice, heightCTStack,firstPETSlice, firstPETSliceIndex, heightPETStack;
	firstCTSlice = [[pix objectAtIndex:0] sliceLocation];
	lastCTSlice = [[pix lastObject] sliceLocation];
	heightCTStack = fabs(firstCTSlice-lastCTSlice);
	firstPETSliceIndex = firstCTSlice / [[[bC pixList] objectAtIndex:0] sliceInterval];
	firstPETSlice = [[[bC pixList] objectAtIndex:0] sliceLocation];

	heightPETStack = heightCTStack / [[[bC pixList] objectAtIndex:0] sliceInterval];
	
	float maxCTSlice, minCTSlice, maxPETSlice, minPETSlice;
	if (signCT > 0)
	{
		maxCTSlice = [[pix lastObject] sliceLocation];
		minCTSlice = [[pix objectAtIndex:0] sliceLocation];
	}
	else
	{
		maxCTSlice = [[pix objectAtIndex:0] sliceLocation];
		minCTSlice = [[pix lastObject] sliceLocation];
	}
	
	if (signPET > 0)
	{
		maxPETSlice = [[[bC pixList] lastObject] sliceLocation];
		minPETSlice = [[[bC pixList] objectAtIndex:0] sliceLocation];
	}
	else
	{
		maxPETSlice = [[[bC pixList] objectAtIndex:0] sliceLocation];
		minPETSlice = [[[bC pixList] lastObject] sliceLocation];
	}
	
	float higherCommunSlice, lowerCommunSlice;
	higherCommunSlice = (maxCTSlice < maxPETSlice ) ? maxCTSlice : maxPETSlice ;
	lowerCommunSlice = (minCTSlice > minPETSlice ) ? minCTSlice : minPETSlice ;
	
	long higherCTSliceIndex, lowerCTSliceIndex, higherPETSliceIndex, lowerPETSliceIndex;
	higherCTSliceIndex = (higherCommunSlice - firstCTSlice) / [[pix objectAtIndex:0] sliceInterval];
	lowerCTSliceIndex = (lowerCommunSlice - firstCTSlice) / [[pix objectAtIndex:0] sliceInterval];
	higherPETSliceIndex = (higherCommunSlice - firstPETSlice) / [[[bC pixList] objectAtIndex:0] sliceInterval];
	lowerPETSliceIndex = (lowerCommunSlice - firstPETSlice) / [[[bC pixList] objectAtIndex:0] sliceInterval];
	
	
	fistCTSlice = (higherCTSliceIndex < lowerCTSliceIndex)? higherCTSliceIndex : lowerCTSliceIndex ;
	fistPETSlice = (higherPETSliceIndex < lowerPETSliceIndex)? higherPETSliceIndex : lowerPETSliceIndex ;
	sliceRangeCT = abs(higherCTSliceIndex - lowerCTSliceIndex)+1;
	sliceRangePET = abs(higherPETSliceIndex - lowerPETSliceIndex)+1;
		
	// initialisations
	[CTController initWithPixList: [NSMutableArray arrayWithArray: [pix subarrayWithRange:NSMakeRange(fistCTSlice,sliceRangeCT)]] : [files subarrayWithRange:NSMakeRange(fistCTSlice,sliceRangeCT)] : vData : nil : self];
	[PETController initWithPixList: [NSMutableArray arrayWithArray: [[bC pixList] subarrayWithRange:NSMakeRange(fistPETSlice,sliceRangePET)]] : [[bC fileList] subarrayWithRange:NSMakeRange(fistPETSlice,sliceRangePET)] : vData : nil : self];
	[PETCTController initWithPixList: [NSMutableArray arrayWithArray: [pix subarrayWithRange:NSMakeRange(fistCTSlice,sliceRangeCT)]] : [files subarrayWithRange:NSMakeRange(fistCTSlice,sliceRangeCT)] : vData : bC : self];

	isFullWindow = NO;
	displayResliceAxes = 1;
	minSplitViewsSize = 150.0;
	filesList = files;
	
	// CLUT Menu
	curCLUTMenu = NSLocalizedString(@"No CLUT", nil);
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	[nc postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];

	// WL/WW Menu	
	curWLWWMenu = NSLocalizedString(@"Other", nil);
	[nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	[nc postNotificationName: @"UpdateWLWWMenu" object: curCLUTMenu userInfo: 0L];

	[[self window] setShowsResizeIndicator:YES];
	[[self window] performZoom:self];
//	[[self window] display];
	
	return self;
}

-(NSArray*) pixList
{
	//NSLog(@"pixList");
}

- (void) dealloc
{
	[blendingViewerController release];
	[toolbar release];
	[PETCTController stopBlending];
	[super dealloc];
}

#pragma mark-
#pragma mark DCMView methods

- (BOOL) is2DViewer
{
	return NO;
}

- (void) ApplyCLUTString:(NSString*) str
{
//	if ([[self window] firstResponder])
	if([CTController containsView: [self keyView]])
	{
		[CTController ApplyCLUTString: str];
		[PETCTController ApplyCLUTString: str];
	}
	else if([PETController containsView: [self keyView]] || [PETCTController containsView: [self keyView]])
	{
		[PETController ApplyCLUTString: str];
		// refresh PETCT views
		[[PETCTController originalView] setIndex:[[PETCTController originalView] curImage]];
		[[PETCTController xReslicedView] setIndex:[[PETCTController xReslicedView] curImage]];
		[[PETCTController yReslicedView] setIndex:[[PETCTController yReslicedView] curImage]];
	}
	
	// the PETCT will display the PET CLUT in CLUTpoppuMenu
	[(OrthogonalMPRPETCTView*)[PETCTController originalView] setCurCLUTMenu: [(OrthogonalMPRPETCTView*)[PETController originalView] curCLUTMenu]];
	[(OrthogonalMPRPETCTView*)[PETCTController xReslicedView] setCurCLUTMenu: [(OrthogonalMPRPETCTView*)[PETController xReslicedView] curCLUTMenu]];
	[(OrthogonalMPRPETCTView*)[PETCTController yReslicedView] setCurCLUTMenu: [(OrthogonalMPRPETCTView*)[PETController yReslicedView] curCLUTMenu]];	
	
	curCLUTMenu = str;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];		
	[[[clutPopup menu] itemAtIndex:0] setTitle:str];
}

-(void) UpdateCLUTMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    i = [[clutPopup menu] numberOfItems];
    while(i-- > 0) [[clutPopup menu] removeItemAtIndex:0];
	
	[[clutPopup menu] addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:nil keyEquivalent:@""];
    [[clutPopup menu] addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:@selector(ApplyCLUT:) keyEquivalent:@""];
	[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector(ApplyCLUT:) keyEquivalent:@""];
    }
    //[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
    //[[clutPopup menu] addItemWithTitle: NSLocalizedString(@"Add a CLUT", nil) action:@selector(AddCLUT:) keyEquivalent:@""];

	[[[clutPopup menu] itemAtIndex:0] setTitle:[note object]];
}

- (IBAction) AddCLUT:(id) sender
{
//	[self clutAction:self];
//	[clutName setStringValue: NSLocalizedString(@"Unnamed", nil)];
	
  //  [NSApp beginSheet: addCLUTWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) ApplyCLUT:(id) sender
{
//    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
//    {
//        NSBeginAlertSheet( NSLocalizedString(@"Remove a Color Look Up Table", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteCLUT:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete this CLUT : '%@'", [sender title]]);
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
//	}
//    else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
//    {
//		NSDictionary		*aCLUT;
//		NSArray				*array;
//		long				i;
//		unsigned char		red[256], green[256], blue[256];
//		
//		[self ApplyCLUTString:[sender title]];
//		
//		aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey:curCLUTMenu];
//		if( aCLUT)
//		{
//			if( [aCLUT objectForKey:@"Points"] != 0L)
//			{
//				[self clutAction:self];
//				[clutName setStringValue: [sender title]];
//				
//				NSMutableArray	*pts = [clutView getPoints];
//				NSMutableArray	*cols = [clutView getColors];
//				
//				[pts removeAllObjects];
//				[cols removeAllObjects];
//				
//				[pts addObjectsFromArray: [aCLUT objectForKey:@"Points"]];
//				[cols addObjectsFromArray: [aCLUT objectForKey:@"Colors"]];
//				
//				[NSApp beginSheet: addCLUTWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
//				
//				[clutView setNeedsDisplay:YES];
//			}
//			else
//			{
//				NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Only CLUT created in OsiriX 1.3.1 or higher can be edited...", nil), nil, nil, nil);
//			}
//		}
//	}
//    else
//    {
		[self ApplyCLUTString:[sender title]];
//    }
}

- (void) setWLWW:(float) iwl :(float) iww:(id) sender
{
	if ([sender isEqual: CTController])
	{
		[CTController superSetWLWW: iwl : iww];
		[PETCTController superSetWLWW: iwl : iww];

		[CTController setCurWLWWMenu: curWLWWMenu];
		//[PETCTController setCurWLWWMenu: curWLWWMenu];
	}
	else if ([sender isEqual: PETController])
	{
		[PETController superSetWLWW: iwl : iww];
		
		[[PETCTController originalView] loadTextures];
		[[PETCTController xReslicedView] loadTextures];
		[[PETCTController yReslicedView] loadTextures];
		
		[[PETCTController xReslicedView] setNeedsDisplay:YES];
		[[PETCTController yReslicedView] setNeedsDisplay:YES];
		[[PETCTController originalView] setNeedsDisplay:YES];
		
		[PETController setCurWLWWMenu: curWLWWMenu];
		[PETCTController setCurWLWWMenu: curWLWWMenu];
	}
	else if ([sender isEqual: PETCTController])
	{
//		[CTController superSetWLWW: iwl : iww];
//		[PETCTController superSetWLWW: iwl : iww];
//		
//		[CTController setCurWLWWMenu: curWLWWMenu];
//		[PETCTController setCurWLWWMenu: curWLWWMenu];
	}
}

-(void) UpdateWLWWMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    i = [[wlwwPopup menu] numberOfItems];
    while(i-- > 0) [[wlwwPopup menu] removeItemAtIndex:0];
    
/*    item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"Presets"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[wlwwPopup menu] addItem:item];
    [item release]; */
    
    [[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:nil keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Other", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Full dynamic", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[wlwwPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
    //[[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    //[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	
	//[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector (SetWLWW:) keyEquivalent:@""];
	
	if([CTController containsView: [self keyView]] 
	|| [PETController containsView: [self keyView]]
	|| [PETCTController containsView: [self keyView]])
	{
		[[[wlwwPopup menu] itemAtIndex:0] setTitle:[(OrthogonalMPRView*)[self keyView] curWLWWMenu]];
	}
	
	if ([PETCTController containsView: [self keyView]])
	{
		[wlwwPopup setEnabled:NO];
	}
	else
	{
		[wlwwPopup setEnabled:YES];
	}
}

- (void) ApplyWLWW:(id) sender
{
	curWLWWMenu = [sender title];
	
//    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
//    {
//        NSBeginAlertSheet( NSLocalizedString(@"Remove a WL/WW preset", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete preset : '%@'", [sender title]]);
//    }
//    else
//    {
		if( [[sender title] isEqualToString:NSLocalizedString(@"Other", nil)] == YES)
		{
			//[imageView setWLWW:0 :0];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Default WL & WW", nil)] == YES)
		{
			[self setWLWW:[[[self keyView] curDCM] savedWL] :[[[self keyView] curDCM] savedWW] : [[self keyView] controller]];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Full dynamic", nil)] == YES)
		{
			[self setWLWW:0 :0 : [[self keyView] controller]];
		}
		else
		{
			NSArray		*value;
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey:[sender title]];
			[self setWLWW:[[value objectAtIndex: 0] floatValue] :[[value objectAtIndex: 1] floatValue] : [[self keyView] controller]];
		}
		[[[wlwwPopup menu] itemAtIndex:0] setTitle:[sender title]];
//		[self propagateSettings];
//    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];

	curWLWWMenu = NSLocalizedString(@"Other", 0L);
//	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: imageView userInfo: userInfo];
}

- (void) blendingPropagateOriginal:(OrthogonalMPRPETCTView*) sender
{
	[CTController blendingPropagateOriginal: sender];
	[PETController blendingPropagateOriginal: sender];
	[PETCTController blendingPropagateOriginal: sender];
}

- (void) blendingPropagateX:(OrthogonalMPRPETCTView*) sender
{
	[CTController blendingPropagateX: sender];
	[PETController blendingPropagateX: sender];
	[PETCTController blendingPropagateX: sender];
}

- (void) blendingPropagateY:(OrthogonalMPRPETCTView*) sender
{
	[CTController blendingPropagateY: sender];
	[PETController blendingPropagateY: sender];
	[PETCTController blendingPropagateY: sender];
}

- (void) flipVerticalOriginal: (id) sender
{
	[(OrthogonalMPRPETCTView*)[CTController originalView] superFlipVertical:sender];
	[(OrthogonalMPRPETCTView*)[PETController originalView] superFlipVertical:sender];
	[(OrthogonalMPRPETCTView*)[PETCTController originalView] superFlipVertical:sender];
}

- (void) flipVerticalX: (id) sender
{
	[(OrthogonalMPRPETCTView*)[CTController xReslicedView] superFlipVertical:sender];
	[(OrthogonalMPRPETCTView*)[PETController xReslicedView] superFlipVertical:sender];
	[(OrthogonalMPRPETCTView*)[PETCTController xReslicedView] superFlipVertical:sender];
}
- (void) flipVerticalY: (id) sender
{
	[(OrthogonalMPRPETCTView*)[CTController yReslicedView] superFlipVertical:sender];
	[(OrthogonalMPRPETCTView*)[PETController yReslicedView] superFlipVertical:sender];
	[(OrthogonalMPRPETCTView*)[PETCTController yReslicedView] superFlipVertical:sender];
}

- (void) flipHorizontalOriginal: (id) sender
{
	[(OrthogonalMPRPETCTView*)[CTController originalView] superFlipHorizontal:sender];
	[(OrthogonalMPRPETCTView*)[PETController originalView] superFlipHorizontal:sender];
	[(OrthogonalMPRPETCTView*)[PETCTController originalView] superFlipHorizontal:sender];
}

- (void) flipHorizontalX: (id) sender
{
	[(OrthogonalMPRPETCTView*)[CTController xReslicedView] superFlipHorizontal:sender];
	[(OrthogonalMPRPETCTView*)[PETController xReslicedView] superFlipHorizontal:sender];
	[(OrthogonalMPRPETCTView*)[PETCTController xReslicedView] superFlipHorizontal:sender];
}
- (void) flipHorizontalY: (id) sender
{
	[(OrthogonalMPRPETCTView*)[CTController yReslicedView] superFlipHorizontal:sender];
	[(OrthogonalMPRPETCTView*)[PETController yReslicedView] superFlipHorizontal:sender];
	[(OrthogonalMPRPETCTView*)[PETCTController yReslicedView] superFlipHorizontal:sender];
}

- (void) toggleDisplayResliceAxes
{
//	if(!isFullWindow)
//	{
		displayResliceAxes++;
		if( displayResliceAxes >= 3) displayResliceAxes = 0;
		[CTController toggleDisplayResliceAxes:self];
		[PETController toggleDisplayResliceAxes:self];
		[PETCTController toggleDisplayResliceAxes:self];
//	}
}

- (IBAction) flipVolume
{
	[CTController flipVolume];
	[PETController flipVolume];
	[PETCTController flipVolume];
}

#pragma mark-
#pragma mark reslice

- (void) resliceFromView: (SEL) view : (NSInvocation*) invoc : (long) x: (long) y: (id) sender
{
	x = x - (float)[[[sender performSelector:view] curDCM] pwidth]/2.0f;
	y = y - (float)[[[sender performSelector:view] curDCM] pheight]/2.0f;
	
	NSPoint offset, senderOrigin, destOrigin;
	offset = NSMakePoint(0,0);
	float destWidth, destHeight, senderPixelSpacingX, senderPixelSpacingY, destPixelSpacingX, destPixelSpacingY;
	long newX, newY;
	BOOL isSenderXFlipped, isSenderYFlipped, isDestXFlipped, isDestYFlipped;
	int xSignSender, ySignSender, xSignDest, ySignDest;
	
	senderPixelSpacingX = [[[sender performSelector:view] curDCM] pixelSpacingX];
	senderPixelSpacingY = [[[sender performSelector:view] curDCM] pixelSpacingY];
	senderOrigin = [[sender performSelector:view] origin];
	isSenderXFlipped = [[sender performSelector:view] xFlipped];
	isSenderYFlipped = [[sender performSelector:view] yFlipped];
	xSignSender = (isSenderXFlipped)? 1 : 1 ;
	ySignSender = (isSenderYFlipped)? 1 : 1 ;
	// CT
	destPixelSpacingX = [[[CTController performSelector:view] curDCM] pixelSpacingX];
	destPixelSpacingY = [[[CTController performSelector:view] curDCM] pixelSpacingY];
	destOrigin = [[CTController performSelector:view] origin];
	destWidth = (float)[[[CTController performSelector:view] curDCM] pwidth];
	destHeight = (float)[[[CTController performSelector:view] curDCM] pheight];
	isDestXFlipped = [[CTController performSelector:view] xFlipped];
	isDestYFlipped = [[CTController performSelector:view] yFlipped];
	xSignDest = (isDestXFlipped)? 1 : 1 ;
	ySignDest = (isDestYFlipped)? 1 : 1 ;
	offset.x = (senderOrigin.x - destOrigin.x)/senderPixelSpacingX;
	offset.y = (senderOrigin.y - destOrigin.y)/senderPixelSpacingY;

	newX = xSignDest * (x + offset.x) * senderPixelSpacingX / destPixelSpacingX + destWidth/2.0f;
	newY = ySignDest * (y + offset.y) * senderPixelSpacingY / destPixelSpacingY + destHeight/2.0f;
	newX = (newX < 0)? 0 : newX ;
	newY = (newY < 0)? 0 : newY ;
	newX = (newX > destWidth)? destWidth : newX ;
	newY = (newY > destHeight)? destHeight : newY ;

	[invoc setArgument:&newX atIndex:2];
	[invoc setArgument:&newY atIndex:3];
	[invoc setTarget:CTController];
	[invoc invoke];

	// PET
	destPixelSpacingX = [[[PETController performSelector:view] curDCM] pixelSpacingX];
	destPixelSpacingY = [[[PETController performSelector:view] curDCM] pixelSpacingY];
	destOrigin = [[PETController performSelector:view] origin];
	destWidth = (float)[[[PETController performSelector:view] curDCM] pwidth];
	destHeight = (float)[[[PETController performSelector:view] curDCM] pheight];
	isDestXFlipped = [[PETController performSelector:view] xFlipped];
	isDestYFlipped = [[PETController performSelector:view] yFlipped];
	xSignDest = (isDestXFlipped)? 1 : 1 ;
	ySignDest = (isDestYFlipped)? 1 : 1 ;

	newX = xSignDest * (x + offset.x) * senderPixelSpacingX / destPixelSpacingX + destWidth/2.0f;
	newY = ySignDest * (y + offset.y) * senderPixelSpacingY / destPixelSpacingY + destHeight/2.0f;
	newX = (newX < 0)? 0 : newX ;
	newY = (newY < 0)? 0 : newY ;
	newX = (newX > destWidth)? destWidth : newX ;
	newY = (newY > destHeight)? destHeight : newY ;

	[invoc setArgument:&newX atIndex:2];
	[invoc setArgument:&newY atIndex:3];
	[invoc setTarget:PETController];
	[invoc invoke];

	// PETCT
	destPixelSpacingX = [[[PETCTController performSelector:view] curDCM] pixelSpacingX];
	destPixelSpacingY = [[[PETCTController performSelector:view] curDCM] pixelSpacingY];
	destOrigin = [[PETCTController performSelector:view] origin];
	destWidth = (float)[[[PETCTController performSelector:view] curDCM] pwidth];
	destHeight = (float)[[[PETCTController performSelector:view] curDCM] pheight];
	isDestXFlipped = [[PETCTController performSelector:view] xFlipped];
	isDestYFlipped = [[PETCTController performSelector:view] yFlipped];
	xSignDest = (isDestXFlipped)? 1 : 1 ;
	ySignDest = (isDestYFlipped)? 1 : 1 ;
	offset.x = senderOrigin.x - destOrigin.x * destPixelSpacingX / senderPixelSpacingX;
	offset.y = senderOrigin.y - destOrigin.y * destPixelSpacingX / senderPixelSpacingX;

	newX = xSignDest * (x + offset.x) * senderPixelSpacingX / destPixelSpacingX + destWidth/2.0f;
	newY = ySignDest * (y + offset.y) * senderPixelSpacingY / destPixelSpacingY + destHeight/2.0f;
	newX = (newX < 0)? 0 : newX ;
	newY = (newY < 0)? 0 : newY ;
	newX = (newX > destWidth)? destWidth : newX ;
	newY = (newY > destHeight)? destHeight : newY ;

	[invoc setArgument:&newX atIndex:2];
	[invoc setArgument:&newY atIndex:3];
	[invoc setTarget:PETCTController];
	[invoc invoke];
}

- (void) resliceFromOriginal: (long) x: (long) y: (id) sender
{
	NSInvocation *invoc = [NSInvocation invocationWithMethodSignature: [CTController methodSignatureForSelector: @selector(resliceFromOriginal::)]];
	[invoc setSelector:  @selector(resliceFromOriginal::)];
	
	[self resliceFromView: @selector(originalView) : invoc : x: y: sender];
}

- (void) resliceFromX: (long) x: (long) y: (id) sender
{
	NSInvocation *invoc = [NSInvocation invocationWithMethodSignature: [CTController methodSignatureForSelector: @selector(resliceFromX::)]];
	[invoc setSelector:  @selector(resliceFromX::)];
	
	[self resliceFromView: @selector(xReslicedView) : invoc : x: y: sender];
}

- (void) resliceFromY: (long) x: (long) y: (id) sender
{
	NSInvocation *invoc = [NSInvocation invocationWithMethodSignature: [CTController methodSignatureForSelector: @selector(resliceFromY::)]];
	[invoc setSelector:  @selector(resliceFromY::)];
	
	[self resliceFromView: @selector(yReslicedView) : invoc : x: y: sender];
}

#pragma mark-
#pragma mark accessors

- (OrthogonalMPRPETCTController*) CTController
{
	return CTController;
}

- (OrthogonalMPRPETCTController*) PETCTController
{
	return PETCTController;
}

- (OrthogonalMPRPETCTController*) PETController
{
	return PETController;
}

#pragma mark-
#pragma mark NSWindow related methods

- (IBAction) showWindow:(id)sender
{
	[CTController showViews:sender];
	[PETController showViews:sender];
	[PETCTController showViews:sender];
	
	[super showWindow:sender];
}

- (void) windowWillClose:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setBool:[modalitySplitView isVertical] forKey: @"orthogonalMPRPETCTVerticalNSSplitView"];
	
    [[self window] setDelegate:0L];
	
	[originalSplitView setDelegate:0L];	
	[xReslicedSplitView setDelegate:0L];
	[yReslicedSplitView setDelegate:0L];
	[modalitySplitView setDelegate:0L];
	
	[self release];
}

- (void) windowDidLoad
{
    [self setupToolbar];
}

-(void) windowDidBecomeKey:(NSNotification *)aNotification
{
	if([CTController containsView: [self keyView]] 
	|| [PETController containsView: [self keyView]]
	|| [PETCTController containsView: [self keyView]])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: [(OrthogonalMPRPETCTView*)[self keyView] curCLUTMenu] userInfo: 0L];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [(OrthogonalMPRPETCTView*)[self keyView] curWLWWMenu] userInfo: 0L];
	}
	//[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
}

#pragma mark-
#pragma mark Tools

- (IBAction) Panel3D:(id) sender
{
	[blendingViewerController Panel3D: sender];
}

- (IBAction) changeTool:(id) sender
{
	if( [sender tag] >= 0)
    {
		[toolsMatrix selectCellWithTag: [[sender selectedCell] tag]];
		[CTController setCurrentTool: [[sender selectedCell] tag]];
		[PETCTController setCurrentTool: [[sender selectedCell] tag]];
		[PETController setCurrentTool: [[sender selectedCell] tag]];
    }
}

- (IBAction) changeBlendingFactor:(id) sender
{
	[PETCTController setBlendingFactor:[sender floatValue]];
}

- (void) moveBlendingFactorSlider:(float) f
{
	[blendingSlider setFloatValue:f];
	[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
}

- (IBAction) blendingMode:(id) sender
{
	NSLog(@"[sender tag] : %d", [sender tag]);
	[PETCTController setBlendingMode: [sender tag]];
}

- (IBAction) resetImage:(id) sender
{
	[CTController resetImage];
	[PETController resetImage];
	[PETCTController resetImage];
}

#pragma mark-
#pragma mark NSToolbar Related Methods

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: PETCTToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
   
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
}

- (IBAction) customizeViewerToolBar:(id)sender {
	[self updateToolbarItems];
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
//    if ([itemIdent isEqual: QTExportToolbarItemIdentifier]) {
//        
//	[toolbarItem setLabel: NSLocalizedString(@"Export",nil)];
//	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export",nil)];
//        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file",nil)];
//	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
//	[toolbarItem setTarget: self];
//	[toolbarItem setAction: @selector(exportQuicktime:)];
//    }
//	else if ([itemIdent isEqual: iPhotoToolbarItemIdentifier]) {
//        
//	[toolbarItem setLabel: NSLocalizedString(@"iPhoto",nil)];
//	[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto",nil)];
//	[toolbarItem setToolTip: NSLocalizedString(@"Export this series to iPhoto",nil)];
//	
//	[toolbarItem setView: iPhotoView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
//	[toolbarItem setMaxSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
//    }
	if ([itemIdent isEqual: MailToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Email",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Email",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image",nil)];
	[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(sendMail:)];
    }
	else if ([itemIdent isEqual: ExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"DICOM File",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Save as DICOM",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image in a DICOM file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
	else if([itemIdent isEqual: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setToolTip:NSLocalizedString( @"Change the mouse function",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]),NSHeight([toolsView frame]))];

    }
/*	 else if([itemIdent isEqual: ThickSlabToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: ThickSlabView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]), NSHeight([ThickSlabView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]) + 100, NSHeight([ThickSlabView frame]))];
    }*/
	 else if([itemIdent isEqual: BlendingToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Fusion",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: blendingToolView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([blendingToolView frame]), NSHeight([blendingToolView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([blendingToolView frame]), NSHeight([blendingToolView frame]))];
    }
//	else if([itemIdent isEqual: MovieToolbarItemIdentifier]) {
//	// Set up the standard properties 
//	[toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
//	[toolbarItem setPaletteLabel:NSLocalizedString( @"4D Player",nil)];
//	[toolbarItem setToolTip:NSLocalizedString( @"4D Player",nil)];
//	
//	// Use a custom view, a text field, for the search item 
//	[toolbarItem setView: movieView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
//	[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
//    }
//	else if([itemIdent isEqual: AxesToolbarItemIdentifier]) {
//	// Set up the standard properties 
//	[toolbarItem setLabel: @"MPR Axes"];
//	[toolbarItem setPaletteLabel: @"MPR Axes"];
//	[toolbarItem setToolTip: @"Change MPR Axes"];
//	
//	// Use a custom view, a text field, for the search item 
//	[toolbarItem setView: axesView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([axesView frame]), NSHeight([axesView frame]))];
//	[toolbarItem setMaxSize:NSMakeSize(NSWidth([axesView frame]),NSHeight([axesView frame]))];
//
//    }


else if ([itemIdent isEqual: VRPanelToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"3D Panel", 0L)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Panel",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"3D Panel",nil)];
		[toolbarItem setImage:[NSImage imageNamed:VRPanelToolbarItemIdentifier]];

		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(Panel3D:)];
    }
	else if ([itemIdent isEqual: SameWidthSplitViewToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Same Widths", 0L)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Same widths for the 3 columns",nil)];
		[toolbarItem setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];

		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(adjustWidthSplitView)];
    }
	else if ([itemIdent isEqual: SameHeightSplitViewToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Same Heights", 0L)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Same Heights",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Same heights for the 3 rows",nil)];
		[toolbarItem setImage:[NSImage imageNamed:@"sameHeightsSplitView"]];
		
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(adjustHeightSplitView)];
    }
	else if ([itemIdent isEqual: TurnSplitViewToolbarItemIdentifier]) {
		if (![modalitySplitView isVertical])
		{
			[toolbarItem setLabel:NSLocalizedString(@"Horizontal", 0L)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Modality in row",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"horizontalSplitView"]];
		}
		else
		{
			[toolbarItem setLabel:NSLocalizedString(@"Vertical", 0L)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Modality in column",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"verticalSplitView"]];
		}
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(turnModalitySplitView)];
    }
	else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Reset", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Reset image to original view", nil)];
		[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(resetImage:)];
    }
	else if ([itemIdent isEqualToString: FlipVolumeToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Flip Volume", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Flip Volume", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Flip Volume", nil)];
		[toolbarItem setImage: [NSImage imageNamed: FlipVolumeToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(flipVolume)];
    }
//	else if ([itemIdent isEqualToString: MIPToolbarItemIdentifier]) {
//		[toolbarItem setLabel: NSLocalizedString(@"MIP", nil)];
//		[toolbarItem setPaletteLabel: NSLocalizedString(@"MIP", nil)];
//		[toolbarItem setToolTip: NSLocalizedString(@"MIP on whole PET stack", nil)];
//		[toolbarItem setImage: [NSImage imageNamed: MIPToolbarItemIdentifier]];
//		[toolbarItem setTarget: self];
//		[toolbarItem setAction: @selector(orthogonalMIPPETViewer)];
//    }
	else if([itemIdent isEqualToString: WLWWToolbarItemIdentifier])
	{
		// Set up the standard properties 
		[toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"WL/WW & CLUT", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Modify WL/WW & CLUT", nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: WLWWView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];

		[[wlwwPopup cell] setUsesItemFromMenu:YES];
	}
    else {
	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
	// Returning nil will inform the toolbar this kind of item is not supported 
	toolbarItem = nil;
    }
     return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											ThickSlabToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
                                            NSToolbarFlexibleSpaceItemIdentifier, 
											MailToolbarItemIdentifier,
											SameHeightSplitViewToolbarItemIdentifier,
											SameWidthSplitViewToolbarItemIdentifier,
											WLWWToolbarItemIdentifier,
											VRPanelToolbarItemIdentifier,
											nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										NSToolbarSpaceItemIdentifier,
										NSToolbarSeparatorItemIdentifier,
										BlendingToolbarItemIdentifier,
										ThickSlabToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
										ToolsToolbarItemIdentifier,
										MailToolbarItemIdentifier,
										SameHeightSplitViewToolbarItemIdentifier,
										SameWidthSplitViewToolbarItemIdentifier,
										TurnSplitViewToolbarItemIdentifier,
										ResetToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
										WLWWToolbarItemIdentifier,
										VRPanelToolbarItemIdentifier,
										nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *item = [[notif userInfo] objectForKey: @"item"];
	
	if ([[item itemIdentifier] isEqualToString:TurnSplitViewToolbarItemIdentifier])
	{
		if (![modalitySplitView isVertical])
		{
			[item setLabel:NSLocalizedString(@"Horizontal",nil)];
			[item setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
			[item setToolTip: NSLocalizedString(@"Modality in row",nil)];
			[item setImage:[NSImage imageNamed:@"horizontalSplitView"]];
		}
		else
		{
			[item setLabel:NSLocalizedString(@"Vertical",nil)];
			[item setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
			[item setToolTip: NSLocalizedString(@"Modality in column",nil)];
			[item setImage:[NSImage imageNamed:@"verticalSplitView"]];
		}
	}
//	else if ([[item itemIdentifier] isEqualToString:SameWidthSplitViewToolbarItemIdentifier])
//	{
//		[item setLabel:NSLocalizedString(@"Same Widths", 0L)];
//		[item setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
//		[item setToolTip: NSLocalizedString(@"Set the three views to the same width",nil)];
//		[item setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];
//	}
//	else if ([[item itemIdentifier] isEqualToString:SameHeightSplitViewToolbarItemIdentifier])
//	{
//		[item setLabel:NSLocalizedString(@"Same Heights", 0L)];
//		[item setPaletteLabel: NSLocalizedString(@"Same Heights",nil)];
//		[item setToolTip: NSLocalizedString(@"Set the three views to the same height",nil)];
//		[item setImage:[NSImage imageNamed:@"sameHeightsSplitView"]];
//	}
	
//	[addedItem retain];
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
//	[removedItem retain];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = YES;
	
//	if ([[toolbarItem itemIdentifier] isEqual: SameWidthSplitViewToolbarItemIdentifier])
//    {
//        if(isFullWindow == YES) enable = NO;
//    }
//	else if ([[toolbarItem itemIdentifier] isEqual: SameHeightSplitViewToolbarItemIdentifier])
//    {
//        if(isFullWindow == YES) enable = NO;
//    }
//	else if ([[toolbarItem itemIdentifier] isEqual: TurnSplitViewToolbarItemIdentifier])
//    {
//        if(isFullWindow == YES) enable = NO;
//    }
	
    return enable;
}

//#pragma mark-
//#pragma mark MIP View
//
//-(IBAction) orthogonalMIPPETViewer
//{
//	OrthogonalMIPPETViewer *viewer;
//	viewer = [[OrthogonalMIPPETViewer alloc] initWithPixList:[PETController originalDCMPixList]];
//	[viewer showWindow:self];
//}

#pragma mark-
#pragma mark NSSplitView Control

- (void) adjustHeightSplitView
{
	NSSize splitViewSize = [modalitySplitView frame].size;
	NSSize newSubViewSize;
	float w,h;
	if ([modalitySplitView isVertical])
	{
		h = (splitViewSize.height-2.0f*[originalSplitView dividerThickness])/3.0f;
		w = (splitViewSize.width-2.0f*[modalitySplitView dividerThickness])/3.0f;
		
		newSubViewSize = NSMakeSize(w,h);
		
		int i;
		for (i=0;i<3;i++)
		{
			[[[originalSplitView subviews] objectAtIndex:i] setFrameSize: newSubViewSize];
			[[[xReslicedSplitView subviews] objectAtIndex:i] setFrameSize: newSubViewSize];
			[[[yReslicedSplitView subviews] objectAtIndex:i] setFrameSize: newSubViewSize];
		}
		[originalSplitView adjustSubviews];
		[xReslicedSplitView adjustSubviews];
		[yReslicedSplitView adjustSubviews];
		[originalSplitView kfRecalculateDividerRects];
		[xReslicedSplitView kfRecalculateDividerRects];
		[yReslicedSplitView kfRecalculateDividerRects];
		
		[originalSplitView setNeedsDisplay:YES];
		[xReslicedSplitView setNeedsDisplay:YES];
		[yReslicedSplitView setNeedsDisplay:YES];
	}
	else
	{		
		h = (splitViewSize.height-2.0f*[modalitySplitView dividerThickness])/3.0f;
		w = splitViewSize.width;
		newSubViewSize = NSMakeSize(w,h);
	
		[originalSplitView setFrameSize: newSubViewSize];
		[xReslicedSplitView setFrameSize: newSubViewSize];
		[yReslicedSplitView setFrameSize: newSubViewSize];
	
		[modalitySplitView adjustSubviews];
		[modalitySplitView kfRecalculateDividerRects];
		[modalitySplitView setNeedsDisplay:YES];
	}
}

- (void) adjustWidthSplitView
{
	NSSize splitViewSize = [modalitySplitView frame].size;
	NSSize newSubViewSize;
	float w,h;
	if (![modalitySplitView isVertical])
	{
		h = (splitViewSize.height-2.0f*[modalitySplitView dividerThickness])/3.0f;
		w = (splitViewSize.width-2.0f*[originalSplitView dividerThickness])/3.0f;
		
		newSubViewSize = NSMakeSize(w,h);
		
		int i;
		for (i=0;i<3;i++)
		{
			[[[originalSplitView subviews] objectAtIndex:i] setFrameSize: newSubViewSize];
			[[[xReslicedSplitView subviews] objectAtIndex:i] setFrameSize: newSubViewSize];
			[[[yReslicedSplitView subviews] objectAtIndex:i] setFrameSize: newSubViewSize];
		}
		[originalSplitView adjustSubviews];
		[xReslicedSplitView adjustSubviews];
		[yReslicedSplitView adjustSubviews];
		[originalSplitView kfRecalculateDividerRects];
		[xReslicedSplitView kfRecalculateDividerRects];
		[yReslicedSplitView kfRecalculateDividerRects];
		
		[originalSplitView setNeedsDisplay:YES];
		[xReslicedSplitView setNeedsDisplay:YES];
		[yReslicedSplitView setNeedsDisplay:YES];
	}
	else
	{	
		h = splitViewSize.height;
		w = (splitViewSize.width-2.0f*[modalitySplitView dividerThickness])/3.0f;

		newSubViewSize = NSMakeSize(w,h);
	
		[originalSplitView setFrameSize: newSubViewSize];
		[xReslicedSplitView setFrameSize: newSubViewSize];
		[yReslicedSplitView setFrameSize: newSubViewSize];
		
		[modalitySplitView adjustSubviews];
		[modalitySplitView kfRecalculateDividerRects];
		[modalitySplitView setNeedsDisplay:YES];
	}
}

- (void) turnModalitySplitView
{
	[modalitySplitView setVertical:![modalitySplitView isVertical]];
	[originalSplitView setVertical:![modalitySplitView isVertical]];
	[xReslicedSplitView setVertical:![modalitySplitView isVertical]];
	[yReslicedSplitView setVertical:![modalitySplitView isVertical]];
	
	[[self window] update];
	[modalitySplitView setNeedsDisplay:YES];
	[originalSplitView setNeedsDisplay:YES];
	[xReslicedSplitView setNeedsDisplay:YES];
	[yReslicedSplitView setNeedsDisplay:YES];
	[self updateToolbarItems];
}

- (void) updateToolbarItems
{
	long i;
	NSToolbarItem *item;
	NSArray *toolbarItems = [toolbar items];
	for(i=0;i<[toolbarItems count];i++)
	{
		item = [toolbarItems objectAtIndex:i];
		if ([[item itemIdentifier] isEqualToString:TurnSplitViewToolbarItemIdentifier])
		{
			if (![modalitySplitView isVertical])
			{
				[item setLabel:NSLocalizedString(@"Horizontal",nil)];
				[item setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
				[item setToolTip: NSLocalizedString(@"Modality in row",nil)];
				[item setImage:[NSImage imageNamed:@"horizontalSplitView"]];
			}
			else
			{
				[item setLabel:NSLocalizedString(@"Vertical",nil)];
				[item setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
				[item setToolTip: NSLocalizedString(@"Modality in column",nil)];
				[item setImage:[NSImage imageNamed:@"verticalSplitView"]];
			}
		}
	}
}

- (void) expandAllSplitViews
{
	[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:NO];
	[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:NO];
	[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:NO];
		
	[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:NO];
	[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:NO];
	[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:NO];
		
	[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:NO];
	[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:NO];
	[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:NO];
		
	[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:0] isCollapsed:NO];
	[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:1] isCollapsed:NO];
	[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:2] isCollapsed:NO];
}

- (void) fullWindowPlan:(int)index:(id)sender
{
	[self expandAllSplitViews];
	if (isFullWindow)
	{
		[self adjustHeightSplitView];
		[self adjustWidthSplitView];
		
		[CTController restoreViewsFrame];
		[PETController restoreViewsFrame];
		[PETCTController restoreViewsFrame];
		
		[CTController restoreScaleValue];
		[PETController restoreScaleValue];
		[PETCTController restoreScaleValue];
		
		displayResliceAxes = 1;
		[CTController displayResliceAxes: displayResliceAxes];
		[PETController displayResliceAxes: displayResliceAxes];
		[PETCTController displayResliceAxes: displayResliceAxes];

		// if current tool is wlww, then set current tool to cross tool
		if ([toolsMatrix selectedTag] == 0)
		{
			[CTController setCurrentTool: tCross];
			[PETController setCurrentTool: tCross];
			[PETCTController setCurrentTool: tCross];
			[toolsMatrix selectCellWithTag:8];
		}
		
		isFullWindow = NO;
	}
	else
	{
		[CTController saveViewsFrame];
		[PETController saveViewsFrame];
		[PETCTController saveViewsFrame];
		
		[CTController saveScaleValue];
		[PETController saveScaleValue];
		[PETCTController saveScaleValue];
		
		displayResliceAxes = 0;
		[CTController displayResliceAxes: displayResliceAxes];
		[PETController displayResliceAxes: displayResliceAxes];
		[PETCTController displayResliceAxes: displayResliceAxes];

		// if current tool is cross tool, then set current tool to wlww
		if ([toolsMatrix selectedTag] == 8)
		{
			[CTController setCurrentTool: tWL];
			[PETController setCurrentTool: tWL];
			[PETCTController setCurrentTool: tWL];
			[toolsMatrix selectCellWithTag:0];
		}
		
		if (index==0)
		{
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:2] isCollapsed:YES];
		}
		else if (index==1)
		{
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:2] isCollapsed:YES];
		}
		else if(index==2)
		{
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:1] isCollapsed:YES];
		}
		isFullWindow = YES;
	}
	[originalSplitView resizeSubviewsWithOldSize:[originalSplitView bounds].size];
	[xReslicedSplitView resizeSubviewsWithOldSize:[xReslicedSplitView bounds].size];
	[yReslicedSplitView resizeSubviewsWithOldSize:[yReslicedSplitView bounds].size];
	[modalitySplitView resizeSubviewsWithOldSize:[modalitySplitView bounds].size];
	
	[modalitySplitView setNeedsDisplay:YES];
}

- (void) fullWindowModality:(int)index:(id)sender
{
	[self expandAllSplitViews];
	if (isFullWindow)
	{
		[self adjustHeightSplitView];
		[self adjustWidthSplitView];
		[CTController restoreViewsFrame];
		[PETController restoreViewsFrame];
		[PETCTController restoreViewsFrame];
		[CTController restoreScaleValue];
		[PETController restoreScaleValue];
		[PETCTController restoreScaleValue];
		isFullWindow = NO;
	}
	else
	{
		[CTController saveViewsFrame];
		[PETController saveViewsFrame];
		[PETCTController saveViewsFrame];
		
		[CTController saveScaleValue];
		[PETController saveScaleValue];
		[PETCTController saveScaleValue];

		if ([sender isEqual:CTController])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
		}
		else if ([sender isEqual:PETController])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
		}
		else if ([sender isEqual:PETCTController])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
		}
		isFullWindow = YES;
	}
	[originalSplitView resizeSubviewsWithOldSize:[originalSplitView bounds].size];
	[xReslicedSplitView resizeSubviewsWithOldSize:[xReslicedSplitView bounds].size];
	[yReslicedSplitView resizeSubviewsWithOldSize:[yReslicedSplitView bounds].size];

	[originalSplitView setNeedsDisplay:YES];
	[xReslicedSplitView setNeedsDisplay:YES];
	[yReslicedSplitView setNeedsDisplay:YES];
}

- (void) fullWindowView:(int)index:(id)sender
{
	[self expandAllSplitViews];
	if (isFullWindow)
	{
		[self adjustHeightSplitView];
		[self adjustWidthSplitView];
		[CTController restoreViewsFrame];
		[PETController restoreViewsFrame];
		[PETCTController restoreViewsFrame];
		[CTController restoreScaleValue];
		[PETController restoreScaleValue];
		[PETCTController restoreScaleValue];
		
//		if (displayResliceAxes)
//		{
			displayResliceAxes = 1;
			[CTController displayResliceAxes:displayResliceAxes];
			[PETController displayResliceAxes:displayResliceAxes];
			[PETCTController displayResliceAxes:displayResliceAxes];
//		}
		
		// if current tool is wlww, then set current tool to cross tool
		if ([toolsMatrix selectedTag] == 0)
		{
			[CTController setCurrentTool: tCross];
			[PETController setCurrentTool: tCross];
			[PETCTController setCurrentTool: tCross];
			[toolsMatrix selectCellWithTag:8];
		}
		
		isFullWindow = NO;
	}
	else
	{
		[CTController saveViewsFrame];
		[PETController saveViewsFrame];
		[PETCTController saveViewsFrame];
		
		[CTController saveScaleValue];
		[PETController saveScaleValue];
		[PETCTController saveScaleValue];
		
		displayResliceAxes = 0;
		[CTController displayResliceAxes:displayResliceAxes];
		[PETController displayResliceAxes:displayResliceAxes];
		[PETCTController displayResliceAxes:displayResliceAxes];

		// if current tool is cross tool, then set current tool to wlww
		if ([toolsMatrix selectedTag] == 8)
		{
			[CTController setCurrentTool: tWL];
			[PETController setCurrentTool: tWL];
			[PETCTController setCurrentTool: tWL];
			[toolsMatrix selectCellWithTag:0];
		}
		
		if ([sender isEqual:CTController])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
		}
		else if ([sender isEqual:PETController])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
		}
		else if ([sender isEqual:PETCTController])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
		}
		
		if (index==0)
		{				
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[[self window] makeFirstResponder:[sender originalView]];
		}
		else if (index==1)
		{
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[[self window] makeFirstResponder:[sender xReslicedView]];
		}
		else if (index==2)
		{
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[modalitySplitView setSubview:[[modalitySplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[[self window] makeFirstResponder:[sender yReslicedView]];
		}
	
		[originalSplitView resizeSubviewsWithOldSize:[originalSplitView bounds].size];
		[xReslicedSplitView resizeSubviewsWithOldSize:[xReslicedSplitView bounds].size];
		[yReslicedSplitView resizeSubviewsWithOldSize:[yReslicedSplitView bounds].size];
		[modalitySplitView resizeSubviewsWithOldSize:[modalitySplitView bounds].size];
		
		if (index==0)
		{
			[[sender originalView] scaleToFit];
			if ([sender isEqual:PETCTController]) [[sender originalView] blendingPropagate];
		}
		else if (index==1)
		{
			[[sender xReslicedView] scaleToFit];
			if ([sender isEqual:PETCTController]) [[sender xReslicedView] blendingPropagate];
		}
		else if (index==2)
		{
			[[sender yReslicedView] scaleToFit];
			if ([sender isEqual:PETCTController]) [[sender yReslicedView] blendingPropagate];
		}
		isFullWindow = YES;
	}
	
	[originalSplitView setNeedsDisplay:YES];
	[xReslicedSplitView setNeedsDisplay:YES];
	[yReslicedSplitView setNeedsDisplay:YES];
	[modalitySplitView setNeedsDisplay:YES];
}
		
//- (void) fullWindowView:(int)index:(id)sender
//{
//	if (isFullWindow)
//	{
//		[self adjustHeightSplitView];
//		[self adjustWidthSplitView];
//		[CTController restoreViewsFrame];
//		[PETController restoreViewsFrame];
//		[PETCTController restoreViewsFrame];
//		
//		if (displayResliceAxes)
//		{
//			[CTController displayResliceAxes:YES];
//			[PETController displayResliceAxes:YES];
//			[PETCTController displayResliceAxes:YES];
//		}
//		
//		float w1,w2,w3,h1,h2,h3;
//		
//		w1 = [[CTController originalView] frame].size.width + [[PETController originalView] frame].size.width + [[PETCTController originalView] frame].size.width;
//		w2 = [[CTController xReslicedView] frame].size.width + [[PETController xReslicedView] frame].size.width + [[PETCTController xReslicedView] frame].size.width;
//		w3 = [[CTController yReslicedView] frame].size.width + [[PETController yReslicedView] frame].size.width + [[PETCTController yReslicedView] frame].size.width;
//
//		h1 = [[CTController originalView] frame].size.height + [[PETController originalView] frame].size.height + [[PETCTController originalView] frame].size.height;
//		h2 = [[CTController xReslicedView] frame].size.height + [[PETController xReslicedView] frame].size.height + [[PETCTController xReslicedView] frame].size.height;
//		h3 = [[CTController yReslicedView] frame].size.height + [[PETController yReslicedView] frame].size.height + [[PETCTController yReslicedView] frame].size.height;
//		
//		if ([modalitySplitView isVertical])
//		{
//			h1 = h1/3.0;
//			h2 = h2/3.0;
//			h3 = h3/3.0;
//		}
//		else
//		{
//			w1 = w1/3.0;
//			w2 = w2/3.0;
//			w3 = w3/3.0;
//		}
//		[originalSplitView setFrameSize:NSMakeSize(w1,h1)];
//		[xReslicedSplitView setFrameSize:NSMakeSize(w2,h2)];
//		[yReslicedSplitView setFrameSize:NSMakeSize(w3,h3)];
//				
//		[originalSplitView adjustSubviews];
//		[xReslicedSplitView adjustSubviews];
//		[yReslicedSplitView adjustSubviews];
////		[originalSplitView setNeedsDisplay:YES];
////		[xReslicedSplitView setNeedsDisplay:YES];
////		[yReslicedSplitView setNeedsDisplay:YES];
//		
//		[modalitySplitView adjustSubviews];
//		[modalitySplitView setNeedsDisplay:YES];
//
//		[CTController restoreScaleValue];
//		[PETController restoreScaleValue];
//		[PETCTController restoreScaleValue];
//		isFullWindow = NO;
//	}
//	else
//	{
//		[CTController saveViewsFrame];
//		[PETController saveViewsFrame];
//		[PETCTController saveViewsFrame];
//		
//		[CTController saveScaleValue];
//		[PETController saveScaleValue];
//		[PETCTController saveScaleValue];
//		
//		[CTController displayResliceAxes:NO];
//		[PETController displayResliceAxes:NO];
//		[PETCTController displayResliceAxes:NO];
//		
//		NSSize modalitySplitViewSize = [modalitySplitView frame].size;
//				
//		float w,h, w2,h2, w3,h3;
//		if ([modalitySplitView isVertical])
//		{
//			h = modalitySplitViewSize.height;
//			w = 0;
//			h2 = h - 2 * [[[modalitySplitView subviews] objectAtIndex:0] dividerThickness];
//			w2 = modalitySplitViewSize.width - 2 * [modalitySplitView dividerThickness];
//			w3 = w2;
//			h3 = 0;
//		}
//		else
//		{
//			h = 0;
//			w = modalitySplitViewSize.width;
//			h2 = modalitySplitViewSize.height - 2 * [modalitySplitView dividerThickness];
//			w2 = w - 2 * [[[modalitySplitView subviews] objectAtIndex:0] dividerThickness];
//			w3 = 0;
//			h3 = h2;
//		}
//		
//		NSSize newSubViewSize = NSMakeSize(w,h);
//		NSSize fullWindowSize = NSMakeSize(w2,h2);
//		NSSize zeroSize = NSMakeSize(0,0);
//		
//		if ([sender isEqual:CTController])
//		{
//			if (index==0)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:1] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:2] setFrameSize: newSubViewSize];
//				
//				[[CTController originalView] setFrameSize: fullWindowSize];
//				
//				[[PETController originalView] setFrameSize: NSMakeSize(w3,h3)];
//				[[PETCTController originalView] setFrameSize: NSMakeSize(w3,h3)];
//						
//				[[[modalitySplitView subviews] objectAtIndex:0] adjustSubviews];
//					
//				[CTController scaleToFit:[CTController originalView]];
//				[[self window] makeFirstResponder:[CTController originalView]];
//				[modalitySplitView adjustSubviews];
//			}
//			else if (index==1)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:0] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:2] setFrameSize: newSubViewSize];
//				
//				[[CTController xReslicedView] setFrameSize: fullWindowSize];
//				
//				[[[[[modalitySplitView subviews] objectAtIndex:1] subviews] objectAtIndex:1] setFrameSize: NSMakeSize(w3,h3)];
//				[[[[[modalitySplitView subviews] objectAtIndex:1] subviews] objectAtIndex:2] setFrameSize: NSMakeSize(w3,h3)];
//				
//				[[[modalitySplitView subviews] objectAtIndex:1] adjustSubviews];
//					
//				[CTController scaleToFit:[CTController xReslicedView]];
//				[[self window] makeFirstResponder:[CTController xReslicedView]];
//				[modalitySplitView adjustSubviews];
//			}
//			else if (index==2)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:1] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:0] setFrameSize: newSubViewSize];
//				
//				[[CTController yReslicedView] setFrameSize: fullWindowSize];
//				
//				[[[[[modalitySplitView subviews] objectAtIndex:2] subviews] objectAtIndex:1] setFrameSize: NSMakeSize(w3,h3)];
//				[[[[[modalitySplitView subviews] objectAtIndex:2] subviews] objectAtIndex:2] setFrameSize: NSMakeSize(w3,h3)];
//				
//				[[[modalitySplitView subviews] objectAtIndex:2] adjustSubviews];
//					
//				[CTController scaleToFit:[CTController yReslicedView]];
//				[[self window] makeFirstResponder:[CTController yReslicedView]];
//				[modalitySplitView adjustSubviews];
//			}
//		}
//		else if ([sender isEqual:PETController])
//		{
//			if (index==0)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:1] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:2] setFrameSize: newSubViewSize];
//				
//				[[PETController originalView] setFrameSize: fullWindowSize];
//				
//				[[CTController originalView] setFrameSize: NSMakeSize(w3,h3)];
//				[[PETCTController originalView] setFrameSize: NSMakeSize(w3,h3)];
//						
//				[[[modalitySplitView subviews] objectAtIndex:0] adjustSubviews];
//					
//				[PETController scaleToFit:[PETController originalView]];
//				[[self window] makeFirstResponder:[PETController originalView]];
//				[modalitySplitView adjustSubviews];
//			}
//			else if (index==1)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:0] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:2] setFrameSize: newSubViewSize];
//				
//				[[PETController xReslicedView] setFrameSize: fullWindowSize];
//				
//				[[CTController xReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				[[PETCTController xReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				
//				[[[modalitySplitView subviews] objectAtIndex:1] adjustSubviews];
//					
//				[PETController scaleToFit:[PETController xReslicedView]];
//				[[self window] makeFirstResponder:[PETController xReslicedView]];
//				[modalitySplitView adjustSubviews];
//			}
//			else if (index==2)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:1] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:0] setFrameSize: newSubViewSize];
//				
//				[[PETController yReslicedView] setFrameSize: fullWindowSize];
//				
//				[[CTController yReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				[[PETCTController yReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				
//				[[[modalitySplitView subviews] objectAtIndex:2] adjustSubviews];
//					
//				[PETController scaleToFit:[PETController yReslicedView]];
//				[[self window] makeFirstResponder:[PETController yReslicedView]];
//				[modalitySplitView adjustSubviews];
//			}
//		}
//		else if ([sender isEqual:PETCTController])
//		{
//			if (index==0)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:1] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:2] setFrameSize: newSubViewSize];
//				
//				[[PETCTController originalView] setFrameSize: fullWindowSize];
//				
//				[[CTController originalView] setFrameSize: NSMakeSize(w3,h3)];
//				[[PETController originalView] setFrameSize: NSMakeSize(w3,h3)];
//						
//				[[[modalitySplitView subviews] objectAtIndex:0] adjustSubviews];
//					
//				[PETCTController scaleToFit:[PETCTController originalView]];
//				[[self window] makeFirstResponder:[PETCTController originalView]];
//				[modalitySplitView adjustSubviews];
//			}
//			else if (index==1)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:0] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:2] setFrameSize: newSubViewSize];
//				
//				[[PETCTController xReslicedView] setFrameSize: fullWindowSize];
//				
//				[[CTController xReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				[[PETController xReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				
//				[[[modalitySplitView subviews] objectAtIndex:1] adjustSubviews];
//					
//				[PETCTController scaleToFit:[PETCTController xReslicedView]];
//				[[self window] makeFirstResponder:[PETCTController xReslicedView]];
//				[modalitySplitView adjustSubviews];
//			}
//			else if (index==2)
//			{
//				[[[modalitySplitView subviews] objectAtIndex:1] setFrameSize: newSubViewSize];
//				[[[modalitySplitView subviews] objectAtIndex:0] setFrameSize: newSubViewSize];
//				
//				[[PETCTController yReslicedView] setFrameSize: fullWindowSize];
//				
//				[[CTController yReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				[[PETController yReslicedView] setFrameSize: NSMakeSize(w3,h3)];
//				
//				[[[modalitySplitView subviews] objectAtIndex:2] adjustSubviews];
//					
//				[PETCTController scaleToFit:[PETCTController yReslicedView]];
//				[[self window] makeFirstResponder:[PETCTController yReslicedView]];
//				[modalitySplitView adjustSubviews];
//			}
//		}
//		
//		if (index==0)
//		{
//			[sender scaleToFit: [sender originalView]];
//			if ([sender isEqual:PETCTController]) [[sender originalView] blendingPropagate];
//		}
//		else if (index==1)
//		{
//			[sender scaleToFit: [sender xReslicedView]];
//			if ([sender isEqual:PETCTController]) [[sender xReslicedView] blendingPropagate];
//		}
//		else if (index==2)
//		{
//			[sender scaleToFit: [sender yReslicedView]];
//			if ([sender isEqual:PETCTController]) [[sender yReslicedView] blendingPropagate];
//		}
//		isFullWindow = YES;
//		
//		[originalSplitView kfRecalculateDividerRects];
//		[xReslicedSplitView kfRecalculateDividerRects];
//		[yReslicedSplitView kfRecalculateDividerRects];
//		[originalSplitView setNeedsDisplay:YES];
//		[xReslicedSplitView setNeedsDisplay:YES];
//		[yReslicedSplitView setNeedsDisplay:YES];
//
//	}
//}

#pragma mark-
#pragma mark NSSplitview's delegate methods

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return YES;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	NSRect rect0, rect1, rectTot;
	rect0 = [[[sender subviews] objectAtIndex:0] frame];
	rect1 = [[[sender subviews] objectAtIndex:1] frame];
	rectTot = [sender frame];
	float min;
	if (![sender isVertical])
	{
		if(offset==0)
		{
			min = minSplitViewsSize;
			return min;
		}
		else
		{
			min = rect0.size.height+[sender dividerThickness]+minSplitViewsSize;
			min = ([sender isSubviewCollapsed:[[sender subviews] objectAtIndex:0]])? [sender dividerThickness]+minSplitViewsSize : min ;
			min = ( min>rectTot.size.height-[sender dividerThickness]-minSplitViewsSize ) ? rectTot.size.height-[sender dividerThickness]-minSplitViewsSize : min ;
			return min;
		}
	}
	else
	{
		if(offset==0)
		{
			min = minSplitViewsSize;
			return min;
		}
		else
		{
			min = rect0.size.width+[sender dividerThickness]+minSplitViewsSize;
			min = ([sender isSubviewCollapsed:[[sender subviews] objectAtIndex:0]])? [sender dividerThickness]+minSplitViewsSize : min ;
			min = ( min>rectTot.size.width-[sender dividerThickness]-minSplitViewsSize ) ? rectTot.size.width-[sender dividerThickness]-minSplitViewsSize : min ;
			return min;
		}
	}
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	NSRect rectTot,rect1;
	rectTot = [sender frame];
	rect1 = [[[sender subviews] objectAtIndex:1] frame];
	float max;
	if (![sender isVertical])
	{
		if(offset==0)
		{
			NSRect rect0;
			rect0 = [[[sender subviews] objectAtIndex:0] frame];
			if ([sender isSubviewCollapsed:[[sender subviews] objectAtIndex:1]])
			{
				max = rect0.size.height-minSplitViewsSize;
			}
			else if ([sender isSubviewCollapsed:[[sender subviews] objectAtIndex:0]])
			{
				max = rect1.size.height-minSplitViewsSize;
			}
			else
			{
				max = rect1.size.height+rect0.size.height-minSplitViewsSize;
			}
			max = (max < minSplitViewsSize) ? minSplitViewsSize : max;
			return max;
		}
		else
		{
			NSRect rect2;
			rect2 = [[[sender subviews] objectAtIndex:2] frame];
			max = rectTot.size.height-[sender dividerThickness]-minSplitViewsSize;
			return max;
		}
	}
	else
	{
		if(offset==0)
		{
			NSRect rect0;
			rect0 = [[[sender subviews] objectAtIndex:0] frame];
			
			if ([sender isSubviewCollapsed:[[sender subviews] objectAtIndex:1]])
			{
				max = rect0.size.width-minSplitViewsSize;
			}
			else if ([sender isSubviewCollapsed:[[sender subviews] objectAtIndex:0]])
			{
				max = rect1.size.width-minSplitViewsSize;
			}
			else
			{
				max = rect1.size.width+rect0.size.width-minSplitViewsSize;
			}
			max = (max < minSplitViewsSize) ? minSplitViewsSize : max;
			return max;
		}
		else
		{
			NSRect rect2;
			rect2 = [[[sender subviews] objectAtIndex:2] frame];
			max = rectTot.size.width-[sender dividerThickness]-minSplitViewsSize;
			return max;
		}
	}
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	NSSplitView	*currentSplitView = [aNotification object];
	if(![currentSplitView isEqual:modalitySplitView])
	{
		NSRect	rect1, rect2, rect3, old_rect1, old_rect2, old_rect3;//, new_rect1, new_rect2, new_rect3;

		NSArray	*subviews = [currentSplitView subviews];
		rect1 = [[subviews objectAtIndex:0] frame];
		rect2 = [[subviews objectAtIndex:1] frame];
		rect3 = [[subviews objectAtIndex:2] frame];
//		
//		if([currentSplitView isSubviewCollapsed:[subviews objectAtIndex:0]])
//		{
////			if([currentSplitView isVertical])
////			{
////				rect1.size.width = minSplitViewsSize;
////			}
////			else
////			{
////				rect1.size.height = minSplitViewsSize;
////			}
//			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:YES];
//			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
//			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
//		}
//		else if([currentSplitView isSubviewCollapsed:[subviews objectAtIndex:1]])
//		{
////			if([currentSplitView isVertical])
////			{
////				rect2.size.width = minSplitViewsSize;
////			}
////			else
////			{
////				rect2.size.height = minSplitViewsSize;
////			}
//			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:YES];
//			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
//			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
//		}
//		else if([currentSplitView isSubviewCollapsed:[subviews objectAtIndex:2]])
//		{
////			if([currentSplitView isVertical])
////			{
////				rect3.size.width = minSplitViewsSize;
////			}
////			else
////			{
////				rect3.size.height = minSplitViewsSize;
////			}
//			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:YES];
//			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
//			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
//		}		

		subviews = [originalSplitView subviews];
		old_rect1 = [[subviews objectAtIndex:0] frame];
		old_rect2 = [[subviews objectAtIndex:1] frame];
		old_rect3 = [[subviews objectAtIndex:2] frame];
		
		if([currentSplitView isVertical])
		{
			old_rect1.origin.x = rect1.origin.x;
			old_rect1.size.width = rect1.size.width;
			old_rect2.origin.x = rect2.origin.x;
			old_rect2.size.width = rect2.size.width;
			old_rect3.origin.x = rect3.origin.x;
			old_rect3.size.width = rect3.size.width;
		}
		else
		{
			old_rect1.origin.y = rect1.origin.y;
			old_rect1.size.height = rect1.size.height;
			old_rect2.origin.y = rect2.origin.y;
			old_rect2.size.height = rect2.size.height;
			old_rect3.origin.y = rect3.origin.y;
			old_rect3.size.height = rect3.size.height;
		}		
		[[subviews objectAtIndex:0] setFrame:old_rect1];
		[[subviews objectAtIndex:1] setFrame:old_rect2];
		[[subviews objectAtIndex:2] setFrame:old_rect3];
		
		[originalSplitView kfRecalculateDividerRects];
		[originalSplitView setNeedsDisplay:YES];
			
		subviews = [xReslicedSplitView subviews];
		old_rect1 = [[subviews objectAtIndex:0] frame];
		old_rect2 = [[subviews objectAtIndex:1] frame];
		old_rect3 = [[subviews objectAtIndex:2] frame];
		
		if([currentSplitView isVertical])
		{
			old_rect1.origin.x = rect1.origin.x;
			old_rect1.size.width = rect1.size.width;
			old_rect2.origin.x = rect2.origin.x;
			old_rect2.size.width = rect2.size.width;
			old_rect3.origin.x = rect3.origin.x;
			old_rect3.size.width = rect3.size.width;
		}
		else
		{
			old_rect1.origin.y = rect1.origin.y;
			old_rect1.size.height = rect1.size.height;
			old_rect2.origin.y = rect2.origin.y;
			old_rect2.size.height = rect2.size.height;
			old_rect3.origin.y = rect3.origin.y;
			old_rect3.size.height = rect3.size.height;
		}
		
		[[subviews objectAtIndex:0] setFrame:old_rect1];
		[[subviews objectAtIndex:1] setFrame:old_rect2];
		[[subviews objectAtIndex:2] setFrame:old_rect3];
		
		[xReslicedSplitView kfRecalculateDividerRects];
		[xReslicedSplitView setNeedsDisplay:YES];
		
		subviews = [yReslicedSplitView subviews];
		old_rect1 = [[subviews objectAtIndex:0] frame];
		old_rect2 = [[subviews objectAtIndex:1] frame];
		old_rect3 = [[subviews objectAtIndex:2] frame];
		
		if([currentSplitView isVertical])
		{
			old_rect1.origin.x = rect1.origin.x;
			old_rect1.size.width = rect1.size.width;
			old_rect2.origin.x = rect2.origin.x;
			old_rect2.size.width = rect2.size.width;
			old_rect3.origin.x = rect3.origin.x;
			old_rect3.size.width = rect3.size.width;
		}
		else
		{
			old_rect1.origin.y = rect1.origin.y;
			old_rect1.size.height = rect1.size.height;
			old_rect2.origin.y = rect2.origin.y;
			old_rect2.size.height = rect2.size.height;
			old_rect3.origin.y = rect3.origin.y;
			old_rect3.size.height = rect3.size.height;
		}
				
		[[subviews objectAtIndex:0] setFrame:old_rect1];
		[[subviews objectAtIndex:1] setFrame:old_rect2];
		[[subviews objectAtIndex:2] setFrame:old_rect3];
		
		[yReslicedSplitView kfRecalculateDividerRects];
		[yReslicedSplitView setNeedsDisplay:YES];
	}
}

- (void)splitViewDidCollapseSubview:(NSNotification *)notification
{
	NSSplitView	*currentSplitView = [notification object];
	if(![currentSplitView isEqual:modalitySplitView])
	{
		NSView *collapsededView = [[notification userInfo] objectForKey : @"subview"];
		NSArray	*subviews = [currentSplitView subviews];
		if([collapsededView isEqualTo:[subviews objectAtIndex:0]])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:YES];
		}
		else if([collapsededView isEqualTo:[subviews objectAtIndex:1]])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:YES];
		}
		else if([collapsededView isEqualTo:[subviews objectAtIndex:2]])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:YES];
		}
	}		
}

- (void)splitViewDidExpandSubview:(NSNotification *)notification;
{
	NSSplitView	*currentSplitView = [notification object];
	if(![currentSplitView isEqual:modalitySplitView])
	{	
		NSView *expandedView = [[notification userInfo] objectForKey : @"subview"];
		NSArray	*subviews = [currentSplitView subviews];
		if([expandedView isEqualTo:[subviews objectAtIndex:0]])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:0] isCollapsed:NO];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:0] isCollapsed:NO];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:0] isCollapsed:NO];
		}
		else if([expandedView isEqualTo:[subviews objectAtIndex:1]])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:1] isCollapsed:NO];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:1] isCollapsed:NO];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:1] isCollapsed:NO];
		}
		else if([expandedView isEqualTo:[subviews objectAtIndex:2]])
		{
			[originalSplitView setSubview:[[originalSplitView subviews] objectAtIndex:2] isCollapsed:NO];
			[xReslicedSplitView setSubview:[[xReslicedSplitView subviews] objectAtIndex:2] isCollapsed:NO];
			[yReslicedSplitView setSubview:[[yReslicedSplitView subviews] objectAtIndex:2] isCollapsed:NO];
		}
	}		
}

#pragma mark-
#pragma mark export

- (DCMView*) keyView
{
	return (DCMView*)[[self window] firstResponder];
}

-(void) sendMail:(id) sender
{
	Mailer		*email;
	NSImage		*im = [[self keyView] nsimage:NO];

	NSArray *representations;
	NSData *bitmapData;

	representations = [im representations];

	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];

	[bitmapData writeToFile:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
	
	[im release];
				
	email = [[Mailer alloc] init];
	
	[email sendMail:@"--" to:@"--" subject:@"" isMIME:YES name:@"--" sendNow:NO image: [documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]];
	
	[email release];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
	BOOL			all = YES;
	long			i;
	NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
	
	long deltaX, deltaY, x, y, oldX, oldY, max;
	OrthogonalMPRView *view;
	
	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:0L file:[[filesList objectAtIndex:0] valueForKeyPath:@"series.name"]] == NSFileHandlingPanelOKButton)
	{		
		if( all)
		{
			if ([[self keyView] isEqualTo:[[[self keyView] controller] originalView]])
			{
				deltaX = 0;
				deltaY = 1;
				view = [[[self keyView] controller] xReslicedView];
				x = [view crossPositionX];
				y = 0;
				oldX = [view crossPositionX];
				oldY = [view crossPositionY];
				max = [[view curDCM] pheight];
			}
			else if ([[self keyView] isEqualTo:[[[self keyView] controller] xReslicedView]])
			{
				deltaX = 0;
				deltaY = 1;
				view = [[[self keyView] controller] originalView];
				x = [view crossPositionX];
				y = 0;
				oldX = [view crossPositionX];
				oldY = [view crossPositionY];
				max = [[view curDCM] pheight];
			}
			else if ([[self keyView] isEqualTo:[[[self keyView] controller] yReslicedView]])
			{
				deltaX = 1;
				deltaY = 0;
				view = [[[self keyView] controller] originalView];
				x = 0;
				y = [view crossPositionY];
				oldX = [view crossPositionX];
				oldY = [view crossPositionY];
				max = [[view curDCM] pheight];
			}
			
			for( i = 0; i < max; i++)
			{
				[view setCrossPosition:x+i*deltaX :y+i*deltaY];
				[modalitySplitView display];
				
				NSImage *im = [[self keyView] nsimage:NO];
				
				//[[im TIFFRepresentation] writeToFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.tif", i+1]] atomically:NO];
				
				NSArray *representations;
				NSData *bitmapData;

				representations = [im representations];

				bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];

				[bitmapData writeToFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.jpg", i+1]] atomically:YES];
				
				[im release];
			}
			[view setCrossPosition:oldX :oldY];
			[view setNeedsDisplay:YES];

			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) 
			{
				//[ws openFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.jpg", 1]]];
				[ws openFile:[panel directory]];
			}
		}
		else
		{		
			NSImage *im = [[self keyView] nsimage:NO];
			
			//[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
			
			NSArray *representations;
			NSData *bitmapData;
			
			representations = [im representations];
			
			bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
			
			[bitmapData writeToFile:[panel filename] atomically:YES];
			
			[im release];
			
			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
		}
	}
}

- (long) indexForPix: (long) pixIndex
{
	if ([[[[[[self keyView] controller] originalDCMFilesList] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] == 1)
		return pixIndex;
	else
		return 0;
}

- (void) exportDICOMFileInt :(BOOL) screenCapture
{
	[self exportDICOMFileInt:screenCapture view:[self keyView]];
}

- (void) exportDICOMFileInt :(BOOL) screenCapture view:(DCMView*) curView
{
	DCMPix *curPix = [curView curDCM];
	long	annotCopy		= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"],
			clutBarsCopy	= [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	long	width, height, spp, bpp, err;
	float	cwl, cww;
	float	o[ 9];
	
	[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger: barHide forKey: @"CLUTBARS"];
	
	unsigned char *data = [curView getRawPixels:&width :&height :&spp :&bpp :screenCapture :NO];
	
	if( data)
	{
		if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
		
		[exportDCM setSourceFile: [[[[curView controller] originalDCMFilesList] objectAtIndex:[self indexForPix:[curView curImage]]] valueForKey:@"completePath"]];
		[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
		
		[curView getWLWW:&cwl :&cww];
		[exportDCM setDefaultWWWL: cww :cwl];
		
		if( screenCapture)
			[exportDCM setPixelSpacing: [curPix pixelSpacingX] / [curView scaleValue] :[curPix pixelSpacingX] / [curView scaleValue]];
		else
			[exportDCM setPixelSpacing: [curPix pixelSpacingX] :[curPix pixelSpacingY]];
			
		[exportDCM setSliceThickness: [curPix sliceThickness]];
		[exportDCM setSlicePosition: [curPix sliceLocation]];
		
		[curPix orientation: o];
		[exportDCM setOrientation: o];
		
		o[ 0] = [curPix originX];		o[ 1] = [curPix originY];		o[ 2] = [curPix originZ];
		[exportDCM setPosition: o];
		
		[exportDCM setPixelData: data samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
		
		err = [exportDCM writeDCMFile: 0L];
		if( err)  NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		free( data);
	}

	[[NSUserDefaults standardUserDefaults] setInteger: annotCopy forKey: @"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger: clutBarsCopy forKey: @"CLUTBARS"];
}

-(IBAction) endExportDICOMFileSettings:(id) sender
{
	long i, curImage;
	
    [dcmExportWindow orderOut:sender];
    
    [NSApp endSheet:dcmExportWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		if( [[dcmSelection selectedCell] tag] == 0) // current image only
		{
			if([dcmExport3Modalities state]==NSOffState)
			{
				[self exportDICOMFileInt: YES];//[[dcmFormat selectedCell] tag]];
			}
			else
			{
				long nCT, nPETCT, nPET;
				nCT = 15300 + [[NSCalendarDate date] minuteOfHour];
				nPETCT = 25300 + [[NSCalendarDate date] minuteOfHour];
				nPET = 35300 + [[NSCalendarDate date] minuteOfHour];
				
				if ([[self keyView] isEqualTo:[[[self keyView] controller] originalView]])
				{
					[exportDCM setSeriesNumber:nCT];
					[self exportDICOMFileInt: YES view:[[self CTController] originalView]];
					[exportDCM setSeriesNumber:nPETCT];
					[self exportDICOMFileInt: YES view:[[self PETCTController] originalView]];
					[exportDCM setSeriesNumber:nPET];
					[self exportDICOMFileInt: YES view:[[self PETController] originalView]];
				}
				else if ([[self keyView] isEqualTo:[[[self keyView] controller] xReslicedView]])
				{
					[exportDCM setSeriesNumber:nCT];
					[self exportDICOMFileInt: YES view:[[self CTController] xReslicedView]];
					[exportDCM setSeriesNumber:nPETCT];
					[self exportDICOMFileInt: YES view:[[self PETCTController] xReslicedView]];
					[exportDCM setSeriesNumber:nPET];
					[self exportDICOMFileInt: YES view:[[self PETController] xReslicedView]];
				}
				else if ([[self keyView] isEqualTo:[[[self keyView] controller] yReslicedView]])
				{
					[exportDCM setSeriesNumber:nCT];
					[self exportDICOMFileInt: YES view:[[self CTController] yReslicedView]];
					[exportDCM setSeriesNumber:nPETCT];
					[self exportDICOMFileInt: YES view:[[self PETCTController] yReslicedView]];
					[exportDCM setSeriesNumber:nPET];
					[self exportDICOMFileInt: YES view:[[self PETController] yReslicedView]];
				}
			}
		}
		else	// all images of the series
		{	
			long deltaX, deltaY, x, y, oldX, oldY, max;
			OrthogonalMPRView *view, *viewCT, *viewPETCT, *viewPET;
			
			if ([[self keyView] isEqualTo:[[[self keyView] controller] originalView]])
			{
				deltaX = 0;
				deltaY = 1;
				view = [[[self keyView] controller] xReslicedView];
				x = [view crossPositionX];
				y = 0;
				oldX = [view crossPositionX];
				oldY = [view crossPositionY];
				max = [[view curDCM] pheight];
				
				viewCT = [[self CTController] originalView];
				viewPETCT = [[self PETCTController] originalView];
				viewPET = [[self PETController] originalView];
			}
			else if ([[self keyView] isEqualTo:[[[self keyView] controller] xReslicedView]])
			{
				deltaX = 0;
				deltaY = 1;
				view = [[[self keyView] controller] originalView];
				x = [view crossPositionX];
				y = 0;
				oldX = [view crossPositionX];
				oldY = [view crossPositionY];
				max = [[view curDCM] pheight];
				
				viewCT = [[self CTController] xReslicedView];
				viewPETCT = [[self PETCTController] xReslicedView];
				viewPET = [[self PETController] xReslicedView];
			}
			else if ([[self keyView] isEqualTo:[[[self keyView] controller] yReslicedView]])
			{
				deltaX = 1;
				deltaY = 0;
				view = [[[self keyView] controller] originalView];
				x = 0;
				y = [view crossPositionY];
				oldX = [view crossPositionX];
				oldY = [view crossPositionY];
				max = [[view curDCM] pheight];
				
				viewCT = [[self CTController] yReslicedView];
				viewPETCT = [[self PETCTController] yReslicedView];
				viewPET = [[self PETController] yReslicedView];
			}
			
			long from, to, interval;
			
			from = [dcmFrom intValue]-1;
			to = [dcmTo intValue];
			interval = [dcmInterval intValue];
			
			if( to < from)
			{
				to = [dcmFrom intValue]-1;
				from = [dcmTo intValue];
			}
			
			Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Creating a DICOM series", nil)];
			[splash showWindow:self];
			[[splash progress] setMaxValue:(int)((to-from)/interval)];

			if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
			[exportDCM setSeriesNumber:5300 + [[NSCalendarDate date] minuteOfHour] ];	//Try to create a unique series number... Do you have a better idea??
			[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
			
			if([dcmExport3Modalities state]==NSOffState)
			{
				for( i = from; i < to; i+=interval)
				{
					[view setCrossPosition:x+i*deltaX :y+i*deltaY];
					[modalitySplitView display];
					
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[self exportDICOMFileInt: YES];
					[pool release];
					
					[splash incrementBy: 1];
				}
			}
			else
			{	
				long nCT, nPETCT, nPET;
				nCT = 15300 + [[NSCalendarDate date] minuteOfHour];
				nPETCT = 25300 + [[NSCalendarDate date] minuteOfHour];
				nPET = 35300 + [[NSCalendarDate date] minuteOfHour];

				for( i = from; i < to; i+=interval)
				{
					[view setCrossPosition:x+i*deltaX :y+i*deltaY];
					[modalitySplitView display];
					
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					[exportDCM setSeriesNumber:nCT];
					[self exportDICOMFileInt: YES view:viewCT];
					[exportDCM setSeriesNumber:nPETCT];
					[self exportDICOMFileInt: YES view:viewPETCT];
					[exportDCM setSeriesNumber:nPET];
					[self exportDICOMFileInt: YES view:viewPET];
					[pool release];
					
					[splash incrementBy: 1];
				}
			}
			
			[view setCrossPosition:oldX :oldY];
			[view setNeedsDisplay:YES];
			
			[splash close];
			[splash release];
		}
	}
}

- (void) exportDICOMFile:(id) sender
{
	long max, curIndex;
	OrthogonalMPRView *view;
	if ([[self keyView] isEqualTo:[[[self keyView] controller] originalView]])
	{
		view = [[[self keyView] controller] xReslicedView];
		max = [[[self keyView] dcmPixList] count];
		curIndex = [[self keyView] curImage];
	}
	else if ([[self keyView] isEqualTo:[[[self keyView] controller] xReslicedView]])
	{
		view = [[[self keyView] controller] originalView];
		max = [[view curDCM] pwidth];
		curIndex = [[[[self keyView] controller] originalView] crossPositionX];
	}
	else if ([[self keyView] isEqualTo:[[[self keyView] controller] yReslicedView]])
	{
		view = [[[self keyView] controller] originalView];
		max = [[view curDCM] pheight];
		curIndex = [[[[self keyView] controller] originalView] crossPositionY];
	}
	[dcmFrom setMaxValue:max];
	[dcmTo setMaxValue:max];
	[dcmInterval setMaxValue:90];

	[dcmFrom setIntValue:1];
	[dcmFromTextField setIntValue:1];
	[dcmTo setIntValue:max];
	[dcmToTextField setIntValue:max];
	[dcmInterval setIntValue:1];
	[dcmIntervalTextField setIntValue:1];
	
	[self checkView: dcmBox :([[dcmSelection selectedCell] tag] == 1)];
	
    [NSApp beginSheet: dcmExportWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction) changeFromAndToBounds:(id) sender
{
	if([sender isEqualTo:dcmFrom]){[dcmFromTextField setIntValue:[sender intValue]];[dcmFromTextField display];}
	else if([sender isEqualTo:dcmTo]){[dcmToTextField setIntValue:[sender intValue]];[dcmToTextField display];}
	else if([sender isEqualTo:dcmToTextField]){[dcmTo setIntValue:[sender intValue]];[dcmTo display];}
	else if([sender isEqualTo:dcmFromTextField]){[dcmFrom setIntValue:[sender intValue]];[dcmFrom display];}
			
	if ([[self keyView] isEqualTo:[[[self keyView] controller] originalView]])
	{
		[self resliceFromX: [[[[self keyView] controller] xReslicedView] crossPositionX] : [sender intValue] : [[self keyView] controller]];
	}
	else if ([[self keyView] isEqualTo:[[[self keyView] controller] xReslicedView]])
	{
		[self resliceFromOriginal: [[[[self keyView] controller] originalView] crossPositionX] : [sender intValue] : [[self keyView] controller]];
	}
	else if ([[self keyView] isEqualTo:[[[self keyView] controller] yReslicedView]])
	{
		[self resliceFromOriginal: [sender intValue]: [[[[self keyView] controller] originalView] crossPositionY] : [[self keyView] controller]];
	}
}

- (IBAction) setCurrentPosition:(id) sender
{
	long max, curIndex;
	
	if ([[self keyView] isEqualTo:[[[self keyView] controller] originalView]])
	{
		max = [[[self keyView] dcmPixList] count];
		curIndex = [[self keyView] curImage]+1;
		if( [[[[self keyView] controller] originalView] flippedData])
		{
			curIndex = max-curIndex;
		}
	}
	else if ([[self keyView] isEqualTo:[[[self keyView] controller] xReslicedView]])
	{
		max = [[[[[self keyView] controller] originalView] curDCM] pwidth];
		curIndex = [[[[self keyView] controller] originalView] crossPositionY]+1;
		if( [[[[self keyView] controller] originalView] flippedData])
		{
			curIndex = max-curIndex;
		}
	}
	else if ([[self keyView] isEqualTo:[[[self keyView] controller] yReslicedView]])
	{
		max = [[[[[self keyView] controller] originalView] curDCM] pheight];
		curIndex = [[[[self keyView] controller] originalView] crossPositionX]+1;
		if( [[[[self keyView] controller] originalView] flippedData])
		{
			curIndex = max-curIndex;
		}
	}
	
	if( [sender tag] == 0)
	{
			[dcmFrom setIntValue:curIndex];
			[dcmFromTextField setIntValue:curIndex];
	}
	else
	{
			[dcmTo setIntValue:curIndex];
			[dcmToTextField setIntValue:curIndex];
	}
	
	[dcmInterval display];
	[dcmFrom display];
	[dcmTo display];
	[dcmFromTextField display];
	[dcmToTextField display];
}

- (IBAction) setCurrentdcmExport:(id) sender
{
	if( [[sender selectedCell] tag] == 1) [self checkView: dcmBox :YES];
	else [self checkView: dcmBox :NO];
}

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
  
    if ([aView isKindOfClass: [NSControl class] ])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }
    // Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
}

@end
