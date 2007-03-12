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

#import "OrthogonalMPRViewer.h"
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#import "Mailer.h"
#import "DICOMExport.h"
#import "wait.h"

static NSString* 	PETCTToolbarIdentifier					= @"MPROrtho Viewer Toolbar Identifier";
static NSString*	AdjustSplitViewToolbarItemIdentifier	= @"sameSizeSplitView";
static NSString*	TurnSplitViewToolbarItemIdentifier		= @"turnSplitView";
static NSString*	QTExportToolbarItemIdentifier			= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier				= @"iPhoto";
static NSString*	ToolsToolbarItemIdentifier				= @"Tools";
static NSString*	ThickSlabToolbarItemIdentifier			= @"ThickSlab";
static NSString*	WLWWToolbarItemIdentifier				= @"WLWW";
static NSString*	BlendingToolbarItemIdentifier			= @"2DBlending";
static NSString*	MovieToolbarItemIdentifier				= @"Movie";
static NSString*	ExportToolbarItemIdentifier				= @"Export.icns";
static NSString*	MailToolbarItemIdentifier				= @"Mail.icns";
static NSString*	ResetToolbarItemIdentifier				= @"Reset.tiff";
static NSString*	FlipVolumeToolbarItemIdentifier			= @"FlipData.tiff";
static NSString*	VRPanelToolbarItemIdentifier			= @"MIP.tif";



NSString * documentsDirectory();

@implementation OrthogonalMPRViewer

- (void) blendingPropagateOriginal:(OrthogonalMPRView*) sender
{
	[controller blendingPropagateOriginal: sender];
}

- (void) blendingPropagateX:(OrthogonalMPRView*) sender
{
	[controller blendingPropagateX: sender];
}

- (void) blendingPropagateY:(OrthogonalMPRView*) sender
{
	[controller blendingPropagateY: sender];
}

- (void) Display3DPoint:(NSNotification*) note
{
	NSMutableArray	*v = [note object];
	
	if( v == [controller originalDCMPixList])
	{
		OrthogonalMPRView *view = [controller originalView];
		
		[view setCrossPosition: [[[note userInfo] valueForKey:@"x"] intValue] :[[[note userInfo] valueForKey:@"y"] intValue]];
		
		view = [controller xReslicedView];
		
		[view setCrossPosition: [view crossPositionX] :[[controller originalDCMPixList] count] -1 - [[[note userInfo] valueForKey:@"z"] intValue]];
	}
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	ViewerController	*v = [note object];
	
	if( [v pixList] == [controller originalDCMPixList])
	{
		[[self window] performClose: self];
		return;
	}
}

-(NSArray*) pixList
{
	return [viewer pixList];
}

-(id)initWithPixList:(NSMutableArray*)pix :(NSArray*)files :(NSData*)vData :(ViewerController*)vC :(ViewerController*)bC
{
	self = [super initWithWindowNibName:@"OrthogonalMPR"];
	[[self window] setDelegate:self];
	[[self window] setShowsResizeIndicator:YES];
	//[[self window] performZoom:self];
	
	viewer = [vC retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:@"CloseViewerNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Display3DPoint:) name:@"Display3DPoint" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dcmExportTextFieldDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
	
	[splitView setDelegate:self];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"orthogonalMPRVertialNSSplitView"])
		[splitView setVertical:[[NSUserDefaults standardUserDefaults] boolForKey:@"orthogonalMPRVertialNSSplitView"]];
	else
		[splitView setVertical:YES];

	[self updateToolbarItems];
	
	// 4D
	curMovieIndex = 0;
	maxMovieIndex = [viewer maxMovieIndex];
	if( maxMovieIndex <= 1)
	{
		[movieTextSlide setEnabled: NO];
		[movieRateSlider setEnabled: NO];
		[moviePlayStop setEnabled:NO];
		[moviePosSlider setEnabled:NO];
	}
	
	//originalDCMPixList[curMovieIndex] = [pix retain];
	//originalFileList[curMovieIndex] = [files retain];
	
	[moviePosSlider setMaxValue:maxMovieIndex-1];
	[moviePosSlider setNumberOfTickMarks:maxMovieIndex];
	
	// initialisations
	[controller initWithPixList:pix :files :vData :vC :bC :self];
	
	isFullWindow = NO;
	displayResliceAxes = 1;
	
	// thick slab
	[thickSlabTextField setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"stackThicknessOrthoMPR"]];
	[thickSlabSlider setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"stackThicknessOrthoMPR"]];
	[thickSlabSlider setMinValue: 2];
	//NSLog(@"maxValue : %d",[controller maxThickSlab]);
	//[thickSlabSlider setMaxValue:[controller maxThickSlab]];
	//[thickSlabSlider setMaxValue:40];
	
	exportDCM = 0L;
	
	// CLUT Menu
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(UpdateCLUTMenu:) name:@"UpdateCLUTMenu" object:nil];
	[nc postNotificationName:@"UpdateCLUTMenu" object:curCLUTMenu userInfo:0L];

	// WL/WW Menu	
	curWLWWMenu = [NSLocalizedString(@"Other", nil) retain];
	[nc addObserver:self selector:@selector(UpdateWLWWMenu:) name:@"UpdateWLWWMenu" object:nil];
	[nc postNotificationName:@"UpdateWLWWMenu" object:curWLWWMenu userInfo:0L];
	
	return self;
}

- (void) dealloc
{
	NSLog(@"OrthogonalMPRViewer dealloc");
	
	[curWLWWMenu release];
	[curCLUTMenu release];
	[viewer release];
	[toolbar release];
	[exportDCM release];
	[super dealloc];
}

/* nothing to do
- (void)finalize {
}
*/

- (OrthogonalMPRController*) controller
{
	return controller;
}

#pragma mark-
#pragma mark DCMView methods

- (BOOL) is2DViewer
{
	return NO;
}

- (ViewerController*) viewer
{
	return viewer;
}

- (void) ApplyCLUTString:(NSString*) str
{
	[controller ApplyCLUTString: str];
	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
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

	[[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
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

- (void) setWLWW:(float) iwl :(float) iww
{
	[controller setWLWW: iwl : iww];
	[controller setCurWLWWMenu:curWLWWMenu];
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
        [[wlwwPopup menu] addItemWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
   // [[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
   // [[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	//[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector (SetWLWW:) keyEquivalent:@""];
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle: curWLWWMenu];
	
//	[self createDCMViewMenu];
	
}

- (void)applyWLWWForString:(NSString *)menuString
{
	if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)] == YES)
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)] == YES)
	{
		[self setWLWW:[[[[self window] firstResponder] curDCM] savedWL] :[[[[self window] firstResponder] curDCM] savedWW]];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)] == YES)
	{
		[self setWLWW:0 :0];
	}
	else
	{
		NSArray		*value;
		value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey:menuString];
		[self setWLWW:[[value objectAtIndex: 0] floatValue] :[[value objectAtIndex: 1] floatValue]];
	}
	
	if( curWLWWMenu != menuString)
	{
		[curWLWWMenu release];
		curWLWWMenu = [menuString retain];
	}
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:menuString];

	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
}



- (void) ApplyWLWW:(id) sender
{
	NSString	*menuString = [sender title];
	
	if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)] == YES)
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)] == YES)
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)] == YES)
	{
	}
	else
	{
		menuString = [menuString substringFromIndex: 4];
	}
	
	[self applyWLWWForString: menuString];
}

- (void) setCurWLWWMenu: (NSString*) wlww
{
	if( curWLWWMenu != wlww)
	{
		[curWLWWMenu release];
		curWLWWMenu = [wlww retain];
	}
}

- (void) toggleDisplayResliceAxes
{
	if(!isFullWindow)
	{
		displayResliceAxes++;
		if( displayResliceAxes >= 3) displayResliceAxes = 0;
		[controller toggleDisplayResliceAxes:self];
	}
}

- (void) flipVolume
{
	[controller flipVolume];
}

#pragma mark-
#pragma mark Thick Slab

-(IBAction) setThickSlabMode : (id) sender
{
//	NSLog(@"[[sender selectedItem] tag] : %d", [[sender selectedItem] tag]);
	if( [[sender selectedItem] tag] == 0)
	{
		[thickSlabSlider setEnabled:NO];
		[controller setThickSlab: 0];
	}
	else
	{
		[thickSlabSlider setEnabled:YES];
		[controller setThickSlabMode : [[sender selectedItem] tag]];
		[controller setThickSlab: [thickSlabSlider intValue]];
	}
}

-(IBAction) setThickSlab : (id) sender
{
	[thickSlabTextField setStringValue:[NSString stringWithFormat:@"%d",[sender intValue]]];//([sender intValue] * [controller thickSlabDistance]/10.0)]];
	[thickSlabTextField setNeedsDisplay:YES];
	[controller setThickSlab:[sender intValue]];
}

#pragma mark-
#pragma mark NSWindow related methods

- (IBAction) showWindow:(id)sender
{
	[controller showViews:sender];
	[super showWindow:sender];
	
	[controller scaleToFit];
}

- (void) windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[[NSUserDefaults standardUserDefaults] setBool:[splitView isVertical] forKey: @"orthogonalMPRVertialNSSplitView"];
	
	if( movieTimer)
	{
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
	}
	
	[splitView setDelegate: 0L];
    [[self window] setDelegate:nil];
    [self release];
}

- (void) windowDidLoad
{
    [self setupToolbar];
}

-(void) windowDidBecomeKey:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	//[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
}

#pragma mark-
#pragma mark NSSplitView Control

- (void) adjustSplitView
{
	NSSize splitViewSize = [splitView frame].size;
	float w,h;
	if ([splitView isVertical])
	{
		h = splitViewSize.height;
		w = (splitViewSize.width-2.0f*[splitView dividerThickness])/3.0f;
	}
	else
	{
		h = (splitViewSize.height-2.0f*[splitView dividerThickness])/3.0f;
		w = splitViewSize.width;
	}
	NSSize newSubViewSize = NSMakeSize(w,h);
	
	[[controller originalView] setFrameSize: newSubViewSize];
	[[controller xReslicedView] setFrameSize: newSubViewSize];
	[[controller yReslicedView] setFrameSize: newSubViewSize];
	
	//[controller setThickSlab: 18];
	
	[splitView adjustSubviews];
	[splitView setNeedsDisplay:YES];
	[self updateToolbarItems];
}

- (void) turnSplitView
{
	[controller saveScaleValue];
	[splitView setVertical:![splitView isVertical]];
	[[self window] update];
	[self updateToolbarItems];
	[splitView adjustSubviews];
	[splitView setNeedsDisplay:YES];
	[controller restoreScaleValue];
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
			if ([splitView isVertical])
			{
				[item setLabel:NSLocalizedString(@"Horizontal", 0L)];
				[item setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
				[item setToolTip: NSLocalizedString(@"Change View from Vertical to Horizontal",nil)];
				[item setImage:[NSImage imageNamed:@"horizontalSplitView"]];
			}
			else
			{
				[item setLabel:NSLocalizedString(@"Vertical", 0L)];
				[item setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
				[item setToolTip: NSLocalizedString(@"Change View from Horizontal to Vertical",nil)];
				[item setImage:[NSImage imageNamed:@"verticalSplitView"]];
			}
		}
		else if ([[item itemIdentifier] isEqualToString:AdjustSplitViewToolbarItemIdentifier])
		{
			if ([splitView isVertical])
			{
				[item setLabel:NSLocalizedString(@"Same Widths", 0L)];
				[item setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
				[item setToolTip: NSLocalizedString(@"Set the three views to the same width",nil)];
				[item setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];
			}
			else
			{
				[item setLabel:NSLocalizedString(@"Same Heights", 0L)];
				[item setPaletteLabel: NSLocalizedString(@"Same Heights",nil)];
				[item setToolTip: NSLocalizedString(@"Set the three views to the same height",nil)];
				[item setImage:[NSImage imageNamed:@"sameHeightsSplitView"]];
			}
		}
	}
}

- (void) fullWindowView:(int)index
{
	if (isFullWindow)
	{
		[controller restoreViewsFrame];
		if (displayResliceAxes) [controller displayResliceAxes:displayResliceAxes];
		[splitView setNeedsDisplay:YES];
		[controller restoreScaleValue];
		// if current tool is wlww, then set current tool to cross tool
		[self setCurrentTool:tCross];
	}
	else
	{
		[controller saveViewsFrame];
		[controller saveScaleValue];
		[controller displayResliceAxes:NO];
		// if current tool is cross tool, then set current tool to wlww
		[self setCurrentTool:tWL];
		
		NSSize splitViewSize = [splitView frame].size;
		
		float w,h;
		if ([splitView isVertical])
		{
			h = splitViewSize.height;
			w = 0;
		}
		else
		{
			h = 0;
			w = splitViewSize.width;
		}
		
		NSSize newSubViewSize = NSMakeSize(w,h);
		
		if (index==0)
		{
			[[controller xReslicedView] setFrameSize: newSubViewSize];
			[[controller yReslicedView] setFrameSize: newSubViewSize];
			[splitView adjustSubviews];
		//	[controller scaleToFit:[controller originalView]];
			[[self window] makeFirstResponder:[controller originalView]];
			
			[[controller originalView] scaleToFit];
		}
		else if (index==1)
		{
			[[controller originalView] setFrameSize: newSubViewSize];
			[[controller yReslicedView] setFrameSize: newSubViewSize];
			[splitView adjustSubviews];
		//	[controller scaleToFit:[controller xReslicedView]];
			[[self window] makeFirstResponder:[controller xReslicedView]];
			
			[[controller xReslicedView] scaleToFit];
		}
		else if (index==2)
		{
			[[controller originalView] setFrameSize: newSubViewSize];
			[[controller xReslicedView] setFrameSize: newSubViewSize];
			[splitView adjustSubviews];
		//	[controller scaleToFit:[controller yReslicedView]];
			[[self window] makeFirstResponder:[controller yReslicedView]];
			
			[[controller yReslicedView] scaleToFit];
		}
		[splitView setNeedsDisplay:YES];
	}
	isFullWindow = !isFullWindow;
}

#pragma mark-
#pragma mark NSSplitview's delegate methods

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return YES;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	if(offset==0)
	{
		return 150.0;
	}
	else if (![sender isVertical])
	{
		NSRect rect;
		rect = [[[sender subviews] objectAtIndex:0] frame];
		return rect.size.height+150.0;
	}
	else
	{
		NSRect rect;
		rect = [[[sender subviews] objectAtIndex:0] frame];
		return rect.size.width+150.0;
	}
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	NSRect rect1;
	rect1 = [sender frame];
	if (![sender isVertical])
	{
		if(offset==0)
		{
			NSRect rect2;
			rect2 = [[[sender subviews] objectAtIndex:2] frame];
			return rect1.size.height-rect2.size.height-150.0;
		}
		else
		{
			return rect1.size.height-150.0;
		}
	}
	else
	{
		if(offset==0)
		{
			NSRect rect2;
			rect2 = [[[sender subviews] objectAtIndex:2] frame];
			return rect1.size.width-rect2.size.width-150.0;
		}
		else
		{
			return rect1.size.width-150.0;
		}
	}
}

#pragma mark-
#pragma mark Tools Selection

- (IBAction) Panel3D:(id) sender
{
	[viewer Panel3D: sender];
}

- (IBAction) changeTool:(id) sender
{
	int tag = [sender tag];
	if( tag>= 0)
    {
		[self setCurrentTool: [[sender selectedCell] tag]];
    }
}

- (IBAction) resetImage:(id) sender
{
	[controller resetImage];
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
	 else if([itemIdent isEqual: ThickSlabToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: ThickSlabView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]), NSHeight([ThickSlabView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]) + 200, NSHeight([ThickSlabView frame]))];
    }
//	 else if([itemIdent isEqual: BlendingToolbarItemIdentifier]) {
//	// Set up the standard properties 
//	[toolbarItem setLabel: NSLocalizedString(@"Fusion",nil)];
//	[toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
//	[toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage",nil)];
//	
//	// Use a custom view, a text field, for the search item 
//	[toolbarItem setView: BlendingView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
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
	else if ([itemIdent isEqual: AdjustSplitViewToolbarItemIdentifier]) {
		if ([splitView isVertical])
		{
			[toolbarItem setLabel:NSLocalizedString(@"Same Widths", 0L)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Set the three views to the same width",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];
		}
		else
		{
			[toolbarItem setLabel:NSLocalizedString(@"Same Heights", 0L)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Same Heights",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Set the three views to the same height",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"sameHeightsSplitView"]];
		}
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(adjustSplitView)];
    }
	else if ([itemIdent isEqual: TurnSplitViewToolbarItemIdentifier]) {
		if ([splitView isVertical])
		{
			[toolbarItem setLabel:NSLocalizedString(@"Horizontal", 0L)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Change View from Vertical to Horizontal",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"horizontalSplitView"]];
		}
		else
		{
			[toolbarItem setLabel:NSLocalizedString(@"Vertical", 0L)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Change View from Horizontal to Vertical",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"verticalSplitView"]];
		}
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(turnSplitView)];
    }
	else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Reset", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Reset image to original view", nil)];
		[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(resetImage:)];
    }
	else if ([itemIdent isEqual: VRPanelToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"3D Panel", 0L)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Panel",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"3D Panel",nil)];
		[toolbarItem setImage:[NSImage imageNamed:VRPanelToolbarItemIdentifier]];

		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(Panel3D:)];
    }
	else if ([itemIdent isEqualToString: FlipVolumeToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Flip Volume", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Flip Volume", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Flip Volume", nil)];
		[toolbarItem setImage: [NSImage imageNamed: FlipVolumeToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(flipVolume)];
    }
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
	else if([itemIdent isEqualToString: MovieToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"4D Player", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"4D Player", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"4D Series Controller", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: movieView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
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
                                            WLWWToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											ThickSlabToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
                                            NSToolbarFlexibleSpaceItemIdentifier, 
									//		QTExportToolbarItemIdentifier,
											MailToolbarItemIdentifier,
											AdjustSplitViewToolbarItemIdentifier,
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
										WLWWToolbarItemIdentifier,
										BlendingToolbarItemIdentifier,
										ThickSlabToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
										ToolsToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
									//	QTExportToolbarItemIdentifier,
										iPhotoToolbarItemIdentifier,
										MailToolbarItemIdentifier,
										AdjustSplitViewToolbarItemIdentifier,
										TurnSplitViewToolbarItemIdentifier,
										ResetToolbarItemIdentifier,
										FlipVolumeToolbarItemIdentifier,
										VRPanelToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
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
		if ([splitView isVertical])
		{
			[item setLabel:NSLocalizedString(@"Horizontal", 0L)];
			[item setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
			[item setToolTip: NSLocalizedString(@"Change View from Vertical to Horizontal",nil)];
			[item setImage:[NSImage imageNamed:@"horizontalSplitView"]];
		}
		else
		{
			[item setLabel:NSLocalizedString(@"Vertical", 0L)];
			[item setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
			[item setToolTip: NSLocalizedString(@"Change View from Horizontal to Vertical",nil)];
			[item setImage:[NSImage imageNamed:@"verticalSplitView"]];
		}
	}
	else if ([[item itemIdentifier] isEqualToString:AdjustSplitViewToolbarItemIdentifier])
	{
		if ([splitView isVertical])
		{
			[item setLabel:NSLocalizedString(@"Same Widths", 0L)];
			[item setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
			[item setToolTip: NSLocalizedString(@"Set the three views to the same width",nil)];
			[item setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];
		}
		else
		{
			[item setLabel:NSLocalizedString(@"Same Heights", 0L)];
			[item setPaletteLabel: NSLocalizedString(@"Same Heights",nil)];
			[item setToolTip: NSLocalizedString(@"Set the three views to the same height",nil)];
			[item setImage:[NSImage imageNamed:@"sameHeightsSplitView"]];
		}
	}
	
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
  /*if ([[toolbarItem itemIdentifier] isEqual: PlayToolbarItemIdentifier])
    {
        if([fileList count] == 1) enable = NO;
    }*/
    return enable;
}

#pragma mark-
#pragma mark export

- (DCMView*) keyView
{
	return (DCMView*) [[self window] firstResponder];
}

-(void) sendMail:(id) sender
{
	Mailer		*email;
	NSImage		*im = [[self keyView] nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];

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
	BOOL			all = NO;
	long			i;
	NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
	
	long deltaX, deltaY, x, y, oldX, oldY, max;
	OrthogonalMPRView *view;
	
	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:0L file:[[[controller originalDCMFilesList] objectAtIndex:0] valueForKeyPath:@"series.name"]] == NSFileHandlingPanelOKButton)
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
				[splitView display];
				
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
	if ([[[[controller originalDCMFilesList] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] == 1)
		return pixIndex;
	else
		return 0;
}

- (void) exportDICOMFileInt :(BOOL) screenCapture
{
	DCMPix *curPix = [[self keyView] curDCM];

	long	annotCopy		= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"],
			clutBarsCopy	= [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	long	width, height, spp, bpp, err;
	float	cwl, cww;
	float	o[ 9];
	
	[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger: barHide forKey: @"CLUTBARS"];
	
	unsigned char *data = [[self keyView] getRawPixels:&width :&height :&spp :&bpp :screenCapture :NO];
	
	if( data)
	{
		if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
		
		[exportDCM setSourceFile: [[[controller originalDCMFilesList] objectAtIndex:[self indexForPix:[[self keyView] curImage]]] valueForKey:@"completePath"]];
		[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
		
		[[self keyView] getWLWW:&cwl :&cww];
		[exportDCM setDefaultWWWL: cww :cwl];
		
		if( screenCapture)
			[exportDCM setPixelSpacing: [curPix pixelSpacingX] / [[self keyView] scaleValue] :[curPix pixelSpacingX] / [[self keyView] scaleValue]];
		else
			[exportDCM setPixelSpacing: [curPix pixelSpacingX] :[curPix pixelSpacingY]];
			
		[exportDCM setSliceThickness: [curPix sliceThickness]];
		[exportDCM setSlicePosition: [curPix sliceLocation]];
		
		if( screenCapture) [[self keyView] orientationCorrectedToView: o];	// <- Because we do screen capture !!!!! We need to apply the rotation of the image
		else [curPix orientation: o];
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
		if( [[dcmSelection selectedCell] tag] == 0)
		{
			[self exportDICOMFileInt: [[dcmFormat selectedCell] tag]];
		}
		else
		{
			long deltaX, deltaY, x, y, oldX, oldY, max;
			OrthogonalMPRView *view;
			
			curImage = [[self keyView] curImage];
			
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
			[exportDCM setSeriesNumber:5600 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];	//Try to create a unique series number... Do you have a better idea??
			[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
			
			//for( i = 0 ; i < max; i += [dcmInterval intValue])
			for( i = from; i < to; i+=interval)
			{
				NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
				
				[view setCrossPosition:x+i*deltaX :y+i*deltaY];
				[splitView display];
				[view display];
				
				[self exportDICOMFileInt:[[dcmFormat selectedCell] tag] ];
				
				[splash incrementBy: 1];
				
				[pool release];
			}
			
			[view setCrossPosition:oldX :oldY];
			
			[[self keyView] setIndex: curImage];
			
			[[self keyView] display];
			
			[splash close];
			[splash release];
		}
	}
}

- (void) exportDICOMFile:(id) sender
{
	long max, curIndex;
	OrthogonalMPRView *view;
	if ([[self keyView] isEqualTo:[controller originalView]])
	{
		view = [controller xReslicedView];
		max = [[[self keyView] dcmPixList] count];
		curIndex = [[self keyView] curImage];
	}
	else if ([[self keyView] isEqualTo:[controller xReslicedView]])
	{
		view = [controller originalView];
		max = [[view curDCM] pwidth];
		curIndex = [[controller originalView] crossPositionX];
	}
	else if ([[self keyView] isEqualTo:[controller yReslicedView]])
	{
		view = [controller originalView];
		max = [[view curDCM] pheight];
		curIndex = [[controller originalView] crossPositionY];
	}
	
	[dcmFrom setMaxValue:max];
	[dcmTo setMaxValue:max];
	[dcmFrom setNumberOfTickMarks:max];
	[dcmTo setNumberOfTickMarks:max];
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
			
	if ([[self keyView] isEqualTo:[controller originalView]])
	{
		//[self resliceFromX: [[controller xReslicedView] crossPositionX] : [sender intValue] : controller];
		[controller reslice: [[controller xReslicedView] crossPositionX] : [sender intValue] : [controller xReslicedView]];
	}
	else if ([[self keyView] isEqualTo:[controller xReslicedView]])
	{
		//[self resliceFromOriginal: [[controller originalView] crossPositionX] : [sender intValue] : controller];
		[controller reslice: [[controller originalView] crossPositionX] : [sender intValue] : [controller originalView]];
	}
	else if ([[self keyView] isEqualTo:[controller yReslicedView]])
	{
		//[self resliceFromOriginal: [sender intValue]: [[controller originalView] crossPositionY] : controller];
		[controller reslice: [sender intValue]: [[controller originalView] crossPositionY] : [controller originalView]];
	}
}

- (IBAction) setCurrentPosition:(id) sender
{
	long max, curIndex;
	
	if ([[self keyView] isEqualTo:[controller originalView]])
	{
		max = [[[self keyView] dcmPixList] count];
		curIndex = [[self keyView] curImage]+1;
		if( [[controller originalView] flippedData])
		{
			curIndex = max-curIndex;
		}
	}
	else if ([[self keyView] isEqualTo:[controller xReslicedView]])
	{
		max = [[[controller originalView] curDCM] pwidth];
		curIndex = [[controller originalView] crossPositionY]+1;
		if( [[controller originalView] flippedData])
		{
			curIndex = max-curIndex;
		}
	}
	else if ([[self keyView] isEqualTo:[controller yReslicedView]])
	{
		max = [[[controller originalView] curDCM] pheight];
		curIndex = [[controller originalView] crossPositionX]+1;
		if( [[controller originalView] flippedData])
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

- (void)dcmExportTextFieldDidChange:(NSNotification *)note
{
	if([[note object] isEqualTo:dcmIntervalTextField])
	{	
		if([dcmIntervalTextField intValue] > [dcmInterval maxValue])
		{
			[dcmIntervalTextField setIntValue:[dcmInterval maxValue]];
		}
		[dcmInterval takeIntValueFrom:dcmIntervalTextField];
	}
	else if([[note object] isEqualTo:dcmFromTextField])
	{
		if([dcmFromTextField intValue] > [dcmFrom maxValue])
		{
			[dcmFromTextField setIntValue:[dcmFrom maxValue]];
		}
		[dcmFrom takeIntValueFrom:dcmFromTextField];
	}
	else if([[note object] isEqualTo:dcmToTextField])
	{
		if([dcmToTextField intValue] > [dcmTo maxValue])
		{
			[dcmToTextField setIntValue:[dcmTo maxValue]];
		}
		[dcmTo takeIntValueFrom:dcmToTextField];
	}
}

#pragma mark-
#pragma mark ROIs

- (IBAction) roiDeleteAll:(id) sender
{
	[viewer roiDeleteAll:sender];
	[[controller originalView] setNeedsDisplay:YES];
	[controller loadROIonReslicedViews: [[controller originalView] crossPositionX] : [[controller originalView] crossPositionY]];
	[[controller xReslicedView] setNeedsDisplay:YES];
	[[controller yReslicedView] setNeedsDisplay:YES];
}

#pragma mark-
#pragma mark 4D

- (void) MoviePlayStop:(id) sender
{
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
        
		[[controller reslicer] setUseYcache:YES];
			
        [moviePlayStop setTitle: NSLocalizedString(@"Play", nil)];
        
		[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
    }
    else
    {
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
    
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
        
        [moviePlayStop setTitle: NSLocalizedString(@"Stop", nil)];
    }
}

- (void) performMovieAnimation:(id) sender
{
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
//	if( [self isEverythingLoaded] == NO) return;
	
//	if( loadingPercentage < 0.5) return;
	
    if( thisTime - lastMovieTime > 1.0 / [movieRateSlider floatValue])
    {
        val = curMovieIndex;
        val ++;
        
		if( val < 0) val = 0;
		if( val >= maxMovieIndex) val = 0;
		
		curMovieIndex = val;
		
		[self setMovieIndex: val];
//		[self propagateSettings];
		
        lastMovieTime = thisTime;
    }
}

- (void) setMovieIndex: (short) i
{
	int index = [[controller originalView] curImage];
	BOOL wasDataFlipped = [[controller originalView] flippedData];
	
	curMovieIndex = i;
	if( curMovieIndex < 0) curMovieIndex = maxMovieIndex-1;
	if( curMovieIndex >= maxMovieIndex) curMovieIndex = 0;
	
	[moviePosSlider setIntValue:curMovieIndex];
	
	[[controller reslicer] setOriginalDCMPixList:[viewer pixList:i]];
	[[controller reslicer] setUseYcache:NO];
	[[controller originalView] setDCM:[viewer pixList:i] :[viewer fileList:i] :[viewer roiList:i] :0 :'i' :NO];
	
	[controller setFusion];
	
//	[self setWindowTitle: self];
	
//	if( wasDataFlipped) [self flipDataSeries: self];
	
	[[controller originalView] setIndex:index];
	//[[controller originalView] sendSyncMessage:1];
	[controller setFusion];
	
	
	[controller refreshViews];
}

- (void) movieRateSliderAction:(id) sender
{
	[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
}

- (void) moviePosSliderAction:(id) sender
{
	[self setMovieIndex: [moviePosSlider intValue]];
//	[self propagateSettings];
}

- (ViewerController *)viewerController{
	return viewer;
}

- (NSManagedObject *)currentStudy{
	return [viewer currentStudy];
}
- (NSManagedObject *)currentSeries{
	return [viewer currentSeries];
}

- (NSManagedObject *)currentImage{
	return [viewer currentImage];
}

-(float)curWW{
	return [viewer curWW];
}

-(float)curWL{
	return [viewer curWL];
}
- (NSString *)curCLUTMenu{
	return curCLUTMenu;
}

- (void)setCurrentTool:(int)currentTool{
	if (currentTool >= 0) {
		[controller setCurrentTool: currentTool];
		[toolsMatrix selectCellWithTag:currentTool];
	}
}

@end
