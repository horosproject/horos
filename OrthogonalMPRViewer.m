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

#import "OrthogonalMPRViewer.h"
#import "OrthogonalMPRPETCTViewer.h"
#import "OpacityTransferView.h"
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#import "Mailer.h"
#import "DICOMExport.h"
#import "wait.h"
#import "BrowserController.h"
#import "Notifications.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "N2Debug.h"
#import "N2OpenGLViewWithSplitsWindow.h"
#import "DicomDatabase.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "PluginManager.h"

static NSString* 	MPROrthoToolbarIdentifier				= @"MPROrtho Viewer Toolbar Identifier";
static NSString*	AdjustSplitViewToolbarItemIdentifier	= @"sameSizeSplitView";
//static NSString*	TurnSplitViewToolbarItemIdentifier		= @"turnSplitView";
static NSString*	iPhotoToolbarItemIdentifier				= @"iPhoto";
static NSString*	ToolsToolbarItemIdentifier				= @"Tools";
static NSString*	ThickSlabToolbarItemIdentifier			= @"ThickSlab";
static NSString*	WLWWToolbarItemIdentifier				= @"WLWW";
static NSString*	BlendingToolbarItemIdentifier			= @"2DBlending";
static NSString*	MovieToolbarItemIdentifier				= @"Movie";
static NSString*	ExportToolbarItemIdentifier				= @"Export.icns";
static NSString*	SyncSeriesToolbarItemIdentifier         = @"Sync";
static NSString*	MailToolbarItemIdentifier				= @"Mail.icns";
static NSString*	ResetToolbarItemIdentifier				= @"Reset.pdf";
static NSString*	FlipVolumeToolbarItemIdentifier			= @"FlipData.tif";
static NSString*	VRPanelToolbarItemIdentifier			= @"MIP.tif";
static NSString*	SyncSeriesImageName                     = @"Sync.pdf";
static NSString*	SyncLockSeriesImageName                 = @"SyncLock.pdf";

static BOOL activateSyncSeriesToolbarItem ;
static SyncSeriesScope globalSyncSeriesScope;

@implementation OrthogonalMPRViewer

@synthesize syncSeriesToolbarItem;
@synthesize syncSeriesState;
@synthesize syncSeriesBehavior;

+ (void) initialize{
    activateSyncSeriesToolbarItem = FALSE;
    globalSyncSeriesScope = SyncSeriesScopeSamePatient;
//    globalSyncSeriesScope = [[NSUserDefaults standardUserDefaults] integerForKey:@"globalMPRSyncSeriesScope"] ;
}

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
	
	if( v == [viewer pixList])
	{
		OrthogonalMPRView *view = [controller originalView];
		
		[view setCrossPosition: [[[note userInfo] valueForKey:@"x"] intValue]+0.5 :[[[note userInfo] valueForKey:@"y"] intValue]+0.5];
		
		view = [controller xReslicedView];
		
		[view setCrossPosition: [view crossPositionX]+0.5 :(long)[[controller originalDCMPixList] count] -1 - [[[note userInfo] valueForKey:@"z"] intValue]+0.5];
	}
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	ViewerController	*v = [note object];
	
	if( v == viewer)
	{
		[[self window] performClose: self];
		return;
	}
}

-(NSArray*) pixList
{
	return [viewer pixList];
}

- (void) awakeFromNib
{
	NSScreen *s = [viewer get3DViewerScreen: viewer];
	
	if( [s frame].size.height > [s frame].size.width)
		[splitView setVertical: NO];
	else
		[splitView setVertical: YES];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
															  forKeyPath: @"values.exportDCMIncludeAllViews"
																 options: NSKeyValueObservingOptionNew
																 context: NULL];
}

-(id)initWithPixList:(NSMutableArray*)pix :(NSArray*)files :(NSData*)vData :(ViewerController*)vC :(ViewerController*)bC
{
	viewer = [vC retain];
	
	self = [super initWithWindowNibName:@"OrthogonalMPR"];
    
	[[self window] setDelegate:self];
	[[self window] setShowsResizeIndicator:YES];
	//[[self window] performZoom:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:OsirixCloseViewerNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Display3DPoint:) name:OsirixDisplay3dPointNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dcmExportTextFieldDidChange:) name:NSControlTextDidChangeNotification object:nil];
	
	[splitView setDelegate:self];
	
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
	
	exportDCM = nil;
	
	// CLUT Menu
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(UpdateCLUTMenu:) name:OsirixUpdateCLUTMenuNotification object:nil];
	[nc postNotificationName:OsirixUpdateCLUTMenuNotification object:curCLUTMenu userInfo:nil];

	// WL/WW Menu
	curWLWWMenu = [NSLocalizedString(@"Other", nil) retain];
	[nc addObserver:self selector:@selector(UpdateWLWWMenu:) name:OsirixUpdateWLWWMenuNotification object:nil];
	[nc postNotificationName:OsirixUpdateWLWWMenuNotification object:curWLWWMenu userInfo:nil];

	// Opacity Menu
	curOpacityMenu = [NSLocalizedString(@"Linear Table", nil) retain];
	[nc addObserver:self selector:@selector(UpdateOpacityMenu:) name:OsirixUpdateOpacityMenuNotification object:nil];
	[nc postNotificationName:OsirixUpdateOpacityMenuNotification object:curOpacityMenu userInfo:nil];

    // Series Synchronisation 
    [nc addObserver:self selector:@selector(syncSeriesNotification:) name:OsirixOrthoMPRSyncSeriesNotification object:nil];
    [nc addObserver:self selector:@selector(posChangeNotification:) name:OsirixOrthoMPRPosChangeNotification object:nil];

    [OrthogonalMPRViewer initSyncSeriesProperties:self];
    [OrthogonalMPRViewer evaluteSyncSeriesToolbarItemActivationWhenInit:self];
    
	[self addObserver: self forKeyPath:@"syncSeriesState" options:0 context: NULL];

	[self setupToolbar];

	return self;
}

- (void) dealloc
{
	NSLog(@"OrthogonalMPRViewer dealloc");
	
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: @"values.exportDCMIncludeAllViews"];
	[[NSUserDefaults standardUserDefaults] setInteger:[thickSlabSlider intValue] forKey: @"stackThicknessOrthoMPR"];

    [self removeObserver:self forKeyPath:@"syncSeriesState" ];

	[viewer release];
	[toolbar release];
	[exportDCM release];
    [syncSeriesToolbarItem release];
    
	[super dealloc];
}

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

- (void) addToUndoQueue:(NSString*) what
{
	[viewer addToUndoQueue: what];
}

- (IBAction) redo:(id) sender
{
	[viewer redo: sender];
	
	[[controller originalView] setIndex: [[controller originalView] curImage]];
	[[controller originalView] setNeedsDisplay:YES];
	[controller loadROIonReslicedViews: [[controller originalView] crossPositionX] : [[controller originalView] crossPositionY]];
	[[controller xReslicedView] setNeedsDisplay:YES];
	[[controller yReslicedView] setNeedsDisplay:YES];
}

- (IBAction) undo:(id) sender
{
	[viewer undo: sender];
	
	[[controller originalView] setIndex: [[controller originalView] curImage]];
	[[controller originalView] setNeedsDisplay:YES];
	[controller loadROIonReslicedViews: [[controller originalView] crossPositionX] : [[controller originalView] crossPositionY]];
	[[controller xReslicedView] setNeedsDisplay:YES];
	[[controller yReslicedView] setNeedsDisplay:YES];
}

- (void) ApplyCLUTString:(NSString*) str
{
	[controller ApplyCLUTString: str];
	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];		
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
	
    [[clutPopup menu] removeAllItems];
	
	[[clutPopup menu] addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:nil keyEquivalent:@""];
    [[clutPopup menu] addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:@selector(ApplyCLUT:) keyEquivalent:@""];
	[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector(ApplyCLUT:) keyEquivalent:@""];
    }
	
	[[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
}

- (IBAction) AddCLUT:(id) sender
{
}

- (void) ApplyCLUT:(id) sender
{
	[self ApplyCLUTString:[sender title]];
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
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    [[wlwwPopup menu] removeAllItems];

    [[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:nil keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Other", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Full dynamic", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[wlwwPopup menu] addItemWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle: curWLWWMenu];
}

- (void)applyWLWWForString:(NSString *)menuString
{
	if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)] == YES)
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)] == YES)
	{
		id firstResponder = [[self window] firstResponder];
		[self setWLWW:[[firstResponder curDCM] savedWL] :[[firstResponder curDCM] savedWW]];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)] == YES)
	{
		[self setWLWW:0 :0];
	}
	else
	{
		NSArray		*value;
		value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] objectForKey:menuString];
		[self setWLWW:[[value objectAtIndex: 0] floatValue] :[[value objectAtIndex: 1] floatValue]];
	}
	
	if( curWLWWMenu != menuString)
	{
		[curWLWWMenu release];
		curWLWWMenu = [menuString retain];
	}
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:menuString];

	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
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

- (void) OpacityChanged: (NSNotification*) note
{
	[controller refreshViews];
}

-(void) UpdateOpacityMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    [[OpacityPopup menu] removeAllItems];
	
    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
	[[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[OpacityPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyOpacity:) keyEquivalent:@""];
    }
	
	[[[OpacityPopup menu] itemAtIndex:0] setTitle:curOpacityMenu];
}

-(void) ApplyOpacityString:(NSString*) str
{
	NSDictionary		*aOpacity;
//	NSArray				*array;
	
	if( [str isEqualToString:NSLocalizedString(@"Linear Table", nil)])
	{
		if( curOpacityMenu != str)
		{
			[curOpacityMenu release];
			curOpacityMenu = [str retain];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
		
		[controller setTransferFunction: nil];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if (aOpacity)
		{
//			array = [aOpacity objectForKey:@"Points"];
			
			if( curOpacityMenu != str)
			{
				[curOpacityMenu release];
				curOpacityMenu = [str retain];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
			
			[controller setTransferFunction: [OpacityTransferView tableWith4096Entries: [aOpacity objectForKey:@"Points"]]];
		}
	}
	
	[controller refreshViews];
}

- (void) ApplyOpacity: (id) sender
{
	[self ApplyOpacityString:[sender title]];
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

- (IBAction) activateThickSlab : (id) sender
{
	if( [thickSlabActivated state] == NSOnState)
	{
		[self setThickSlabMode: thickSlabPopup];
	}
	else
	{
		[self setThickSlabMode: thickSlabPopup];
	}
}

-(IBAction) setThickSlabMode : (id) sender
{
	if( [thickSlabActivated state] == NSOffState)
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
    
    [OrthogonalMPRViewer synchronizeViewer:self];
    
    [self adjustSplitView];
}

- (void) windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	if( movieTimer)
	{
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
	}
	
	[splitView setDelegate: nil];
    [[self window] setDelegate:nil];
    
    [self setSyncSeriesState: SyncSeriesStateDisable];
    [OrthogonalMPRViewer validateViewersSyncSeriesState];
    [OrthogonalMPRViewer evaluteSyncSeriesToolbarItemActivationBeforeClose:self];
    
    [self autorelease];
}

-(void) windowDidBecomeKey:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
	//[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: curConvMenu userInfo: nil];
}

#pragma mark-
#pragma mark NSSplitView Control

-(void)splitViewWillResizeSubviews:(NSNotification *)notification
{
    N2OpenGLViewWithSplitsWindow *window = (N2OpenGLViewWithSplitsWindow*)self.window;
	
	if( [window respondsToSelector:@selector(disableUpdatesUntilFlush)])
		[window disableUpdatesUntilFlush];
}

- (void) adjustSplitView
{
    NSDisableScreenUpdates();
    
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
	
    [controller originalView].translatesAutoresizingMaskIntoConstraints = YES;
    [controller xReslicedView].translatesAutoresizingMaskIntoConstraints = YES;
    [controller yReslicedView].translatesAutoresizingMaskIntoConstraints = YES;
    
	[[controller originalView] setFrameSize: newSubViewSize];
	[[controller xReslicedView] setFrameSize: newSubViewSize];
	[[controller yReslicedView] setFrameSize: newSubViewSize];
	
	//[controller setThickSlab: 18];
	
	[splitView adjustSubviews];
	[splitView setNeedsDisplay:YES];
	[self updateToolbarItems];
    
    NSEnableScreenUpdates();
}

//- (void) turnSplitView
//{
//	[controller saveScaleValue];
//	[splitView setVertical:![splitView isVertical]];
//	[[self window] update];
//	[self updateToolbarItems];
//	[splitView adjustSubviews];
//	[splitView setNeedsDisplay:YES];
//	[controller restoreScaleValue];
//}

- (void) updateToolbarItems
{
	NSToolbarItem *item;
	NSArray *toolbarItems = [toolbar items];
	for(item in toolbarItems)
	{
//		if ([[item itemIdentifier] isEqualToString:TurnSplitViewToolbarItemIdentifier])
//		{
//			if ([splitView isVertical])
//			{
//				[item setLabel:NSLocalizedString(@"Horizontal", nil)];
//				[item setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
//				[item setToolTip: NSLocalizedString(@"Change View from Vertical to Horizontal",nil)];
//				[item setImage:[NSImage imageNamed:@"horizontalSplitView"]];
//			}
//			else
//			{
//				[item setLabel:NSLocalizedString(@"Vertical", nil)];
//				[item setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
//				[item setToolTip: NSLocalizedString(@"Change View from Horizontal to Vertical",nil)];
//				[item setImage:[NSImage imageNamed:@"verticalSplitView"]];
//			}
//		}
//		else
		if ([[item itemIdentifier] isEqualToString:AdjustSplitViewToolbarItemIdentifier])
		{
			if ([splitView isVertical])
			{
				[item setLabel:NSLocalizedString(@"Same Widths", nil)];
				[item setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
				[item setToolTip: NSLocalizedString(@"Set the three views to the same width",nil)];
				[item setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];
			}
			else
			{
				[item setLabel:NSLocalizedString(@"Same Heights", nil)];
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

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
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

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
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

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
#ifdef EXPORTTOOLBARITEM
return YES;
#endif

	BOOL valid = NO;
		
	if( [item action] == @selector(changeTool:))
	{
		valid = YES;
		if( [item tag] == [controller currentTool]) [item setState: NSOnState];
		else [item setState: NSOffState];
	}
	else if( [item action] == @selector(ApplyCLUT:))
	{
		valid = YES;
		
		if( [[item title] isEqualToString: curCLUTMenu]) [item setState:NSOnState];
		else [item setState:NSOffState];
	}
//	else if( [item action] == @selector(ApplyConv:))
//	{
//		valid = YES;
//		
//		if( [[item title] isEqualToString: curConvMenu]) [item setState:NSOnState];
//		else [item setState:NSOffState];
//	}
	else if( [item action] == @selector(ApplyOpacity:))
	{
		valid = YES;
		
		if( [[item title] isEqualToString: curOpacityMenu]) [item setState:NSOnState];
		else [item setState:NSOffState];
	}
	else if( [item action] == @selector(ApplyWLWW:))
	{
		valid = YES;
		
		NSString	*str = nil;
		
		@try
		{
			str = [[item title] substringFromIndex: 4];
		}
		
		@catch (NSException * e) {}
		
		if( [str isEqualToString: curWLWWMenu] || [[item title] isEqualToString: curWLWWMenu]) [item setState:NSOnState];
		else [item setState:NSOffState];
	}
    else if( [item action] == @selector(syncSeriesScopeAction:))    {
        valid = YES;
        [item setState: (globalSyncSeriesScope == [item tag] ? NSOnState : NSOffState)];
    }
    else if( [item action] == @selector(syncSeriesBehaviorAction:))   {
        valid = YES;
        [item setState: (syncSeriesBehavior == [item tag] ? NSOnState : NSOffState)];
    }
    else if( [item action] == @selector(syncSeriesStateAction:))   {
        valid = YES;
        [item setState: (syncSeriesState == [item tag] ? NSOnState : NSOffState)];
    }
    else valid = YES;
	
    return valid;
}

#ifndef OSIRIX_LIGHT
- (IBAction) Panel3D:(id) sender
{
	[viewer Panel3D: sender];
}
#endif

- (IBAction) changeTool:(id) sender
{
	int tag = [sender tag];
	if( tag >= 0)
    {
		if( [sender isMemberOfClass: [NSMatrix class]]) [self setCurrentTool: [[sender selectedCell] tag]];
		else [self setCurrentTool: tag];
    }
}

- (IBAction) resetImage:(id) sender
{
	[controller resetImage];
}

#pragma mark-
#pragma mark NSToolbar Related Methods

- (void) setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: MPROrthoToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
   
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
	
	#ifdef EXPORTTOOLBARITEM
	NSLog(@"************** WARNING EXPORTTOOLBARITEM ACTIVATED");
	for( id s in [self toolbarAllowedItemIdentifiers: toolbar])
	{
		@try
		{
			id item = [self toolbar: toolbar itemForItemIdentifier: s willBeInsertedIntoToolbar: YES];
			
			
			NSImage *im = [item image];
			
			if( im == nil)
			{
				@try
				{
					if( [item respondsToSelector:@selector(setRecursiveEnabled:)])
						[item setRecursiveEnabled: YES];
					else if( [[item view] respondsToSelector:@selector(setRecursiveEnabled:)])
						[[item view] setRecursiveEnabled: YES];
					else if( item)
						NSLog( @"%@", item);
						
					im = [[item view] screenshotByCreatingPDF];
				}
				@catch (NSException * e)
				{
					NSLog( @"a");
				}
			}
			
			if( im)
			{
				NSBitmapImageRep *bits = [[[NSBitmapImageRep alloc] initWithData:[im TIFFRepresentation]] autorelease];
				
				NSString *path = [NSString stringWithFormat: @"/tmp/sc/%@.png", [[[[item label] stringByReplacingOccurrencesOfString: @"&" withString:@"And"] stringByReplacingOccurrencesOfString: @" " withString:@""] stringByReplacingOccurrencesOfString: @"/" withString:@"-"]];
				[[bits representationUsingType: NSPNGFileType properties: nil] writeToFile:path  atomically: NO];
			}
		}
		@catch (NSException * e)
		{
			NSLog( @"b");
		}
	}
	#endif
}

- (IBAction) customizeViewerToolBar:(id)sender {
	[self updateToolbarItems];
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
     
    NSToolbarItem *toolbarItem =nil;
    
    if ([itemIdent isEqualToString: SyncSeriesToolbarItemIdentifier]) {
        toolbarItem = [[[KBPopUpToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    }else{
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    }
    
//    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
    
//    if ([itemIdent isEqualToString: QTExportToolbarItemIdentifier]) {
//        
//	[toolbarItem setLabel: NSLocalizedString(@"Export",nil)];
//	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export",nil)];
//        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file",nil)];
//	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
//	[toolbarItem setTarget: self];
//	[toolbarItem setAction: @selector(exportQuicktime:)];
//    }
//	else if ([itemIdent isEqualToString: iPhotoToolbarItemIdentifier]) {
//        
//	[toolbarItem setLabel: NSLocalizedString(@"iPhoto",nil)];
//	[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto",nil)];
//	[toolbarItem setToolTip: NSLocalizedString(@"Export this series to iPhoto",nil)];
//	
//	[toolbarItem setView: iPhotoView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
//	[toolbarItem setMaxSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
//    }
    if ([itemIdent isEqualToString: MailToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Email",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Email",nil)];
    [toolbarItem setToolTip: NSLocalizedString(@"Email this image",nil)];
	[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(sendMail:)];
    }
	else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"DICOM File",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Save as DICOM",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Export this image in a DICOM file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
	else if([itemIdent isEqualToString: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]),NSHeight([toolsView frame]))];

    }
	 else if([itemIdent isEqualToString: ThickSlabToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Thick Slab", @"Thick Slab")];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: ThickSlabView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]), NSHeight([ThickSlabView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]) + 200, NSHeight([ThickSlabView frame]))];
    }
//	 else if([itemIdent isEqualToString: BlendingToolbarItemIdentifier]) {
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
//	else if([itemIdent isEqualToString: AxesToolbarItemIdentifier]) {
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
	else if ([itemIdent isEqualToString: AdjustSplitViewToolbarItemIdentifier]) {
		if ([splitView isVertical])
		{
			[toolbarItem setLabel:NSLocalizedString(@"Same Widths", nil)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Set the three views to the same width",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];
		}
		else
		{
			[toolbarItem setLabel:NSLocalizedString(@"Same Heights", nil)];
			[toolbarItem setPaletteLabel: NSLocalizedString(@"Same Heights",nil)];
			[toolbarItem setToolTip: NSLocalizedString(@"Set the three views to the same height",nil)];
			[toolbarItem setImage:[NSImage imageNamed:@"sameHeightsSplitView"]];
		}
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(adjustSplitView)];
    }
//	else if ([itemIdent isEqualToString: TurnSplitViewToolbarItemIdentifier])
//	{
//		if ([splitView isVertical])
//		{
//			[toolbarItem setLabel:NSLocalizedString(@"Horizontal", nil)];
//			[toolbarItem setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
//			[toolbarItem setToolTip: NSLocalizedString(@"Change View from Vertical to Horizontal",nil)];
//			[toolbarItem setImage:[NSImage imageNamed:@"horizontalSplitView"]];
//		}
//		else
//		{
//			[toolbarItem setLabel:NSLocalizedString(@"Vertical", nil)];
//			[toolbarItem setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
//			[toolbarItem setToolTip: NSLocalizedString(@"Change View from Horizontal to Vertical",nil)];
//			[toolbarItem setImage:[NSImage imageNamed:@"verticalSplitView"]];
//		}
//		[toolbarItem setTarget: self];
//		[toolbarItem setAction: @selector(turnSplitView)];
//    }
	else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Reset", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Reset image to original view", nil)];
		[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(resetImage:)];
    }
	else if ([itemIdent isEqualToString: VRPanelToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"3D Panel", nil)];
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
    else if ([itemIdent isEqualToString: SyncSeriesToolbarItemIdentifier])
    {
        [OrthogonalMPRViewer initSyncSeriesToolbarItem:self : toolbarItem];
    }
    else
        toolbarItem = nil;
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarItemForItemIdentifier:forViewer:)])
        {
            NSToolbarItem *item = [[[PluginManager plugins] objectForKey:key] toolbarItemForItemIdentifier: itemIdent forViewer: self];
            
            if( item)
                toolbarItem = item;
        }
    }
    
    return toolbarItem;
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
                                            SyncSeriesToolbarItemIdentifier,
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
    NSMutableArray *array = [NSMutableArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										NSToolbarSpaceItemIdentifier,
										NSToolbarSeparatorItemIdentifier,
										WLWWToolbarItemIdentifier,
										BlendingToolbarItemIdentifier,
										ThickSlabToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
										ToolsToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
                                        SyncSeriesToolbarItemIdentifier,
										iPhotoToolbarItemIdentifier,
										MailToolbarItemIdentifier,
										AdjustSplitViewToolbarItemIdentifier,
//										TurnSplitViewToolbarItemIdentifier,
										ResetToolbarItemIdentifier,
										FlipVolumeToolbarItemIdentifier,
										VRPanelToolbarItemIdentifier,
										nil];
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarAllowedIdentifiersForViewer:)])
            [array addObjectsFromArray: [[[PluginManager plugins] objectForKey:key] toolbarAllowedIdentifiersForViewer: self]];
    }
    
    return array;
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *item = [[notif userInfo] objectForKey: @"item"];
	
//	if ([[item itemIdentifier] isEqualToString:TurnSplitViewToolbarItemIdentifier])
//	{
//		if ([splitView isVertical])
//		{
//			[item setLabel:NSLocalizedString(@"Horizontal", nil)];
//			[item setPaletteLabel: NSLocalizedString(@"Horizontal",nil)];
//			[item setToolTip: NSLocalizedString(@"Change View from Vertical to Horizontal",nil)];
//			[item setImage:[NSImage imageNamed:@"horizontalSplitView"]];
//		}
//		else
//		{
//			[item setLabel:NSLocalizedString(@"Vertical", nil)];
//			[item setPaletteLabel: NSLocalizedString(@"Vertical",nil)];
//			[item setToolTip: NSLocalizedString(@"Change View from Horizontal to Vertical",nil)];
//			[item setImage:[NSImage imageNamed:@"verticalSplitView"]];
//		}
//	}
//	else
    
	if ([[item itemIdentifier] isEqualToString:AdjustSplitViewToolbarItemIdentifier])
	{
		if ([splitView isVertical])
		{
			[item setLabel:NSLocalizedString(@"Same Widths", nil)];
			[item setPaletteLabel: NSLocalizedString(@"Same Widths",nil)];
			[item setToolTip: NSLocalizedString(@"Set the three views to the same width",nil)];
			[item setImage:[NSImage imageNamed:@"sameWidthsSplitView"]];
		}
		else
		{
			[item setLabel:NSLocalizedString(@"Same Heights", nil)];
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
#ifdef EXPORTTOOLBARITEM
return YES;
#endif

    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = YES;
  /*if ([[toolbarItem itemIdentifier] isEqualToString: PlayToolbarItemIdentifier])
    {
        if([fileList count] == 1) enable = NO;
    }*/
    if ([[toolbarItem itemIdentifier] isEqualToString: SyncSeriesToolbarItemIdentifier])
        if(![OrthogonalMPRViewer getSyncSeriesToolbarItemActivation])
            enable = NO;
    
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
	NSImage		*im = [[self keyView] nsimage: NO];

	NSArray *representations;
	NSData *bitmapData;

	representations = [im representations];

	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];

	[bitmapData writeToFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/OsiriX.jpg"] atomically:YES];
				
	email = [[Mailer alloc] init];
	
	[email sendMail:@"--" to:@"--" subject:@"" isMIME:YES name:@"--" sendNow:NO image: [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/OsiriX.jpg"]];
	
	[email release];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
	BOOL			all = NO;
	int             i;
	NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
	
	long deltaX, deltaY, x, y, oldX, oldY, max;
	OrthogonalMPRView *view;
	
    deltaX = deltaY = x = y = oldX = oldY = max = 0;
    
	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:nil file:[[[controller originalDCMFilesList] objectAtIndex:0] valueForKeyPath:@"series.name"]] == NSFileHandlingPanelOKButton)
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
				NSDisableScreenUpdates();
				[view setCrossPosition:x+i*deltaX+0.5 :y+i*deltaY+0.5];
				[splitView display];
				
				NSImage *im = [[self keyView] nsimage:NO];
				NSEnableScreenUpdates();
				
				//[[im TIFFRepresentation] writeToFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.tif", i+1]] atomically:NO];
				
				NSArray *representations;
				NSData *bitmapData;
				
				representations = [im representations];
				
				bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
				
				[bitmapData writeToFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.jpg", i+1]] atomically:YES];
			}
			[view setCrossPosition:oldX+0.5 :oldY+0.5];
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
			
			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
		}
	}
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context
{
	if( [keyPath isEqualToString: @"values.exportDCMIncludeAllViews"])
		[dcmFormat selectCellWithTag: 1]; // Screen capture
    else if([keyPath isEqualToString: @"syncSeriesState"])
        [OrthogonalMPRViewer updateSyncSeriesToolbarItemUI:self];
}

#ifndef OSIRIX_LIGHT
- (NSDictionary*) exportDICOMFileInt :(BOOL) screenCapture
{
	DCMPix *curPix = [[self keyView] curDCM];

	int		annotCopy		= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"],
			clutBarsCopy	= [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	long	width, height, spp, bpp;
	float	cwl, cww;
	float	o[ 9];
	float	imOrigin[ 3], imSpacing[ 2];
	int		offset;
	BOOL	isSigned;
	NSString *f = nil;
	
	[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger: barHide forKey: @"CLUTBARS"];
	[DCMView setDefaults];
	
	unsigned char *data = nil;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportDCMIncludeAllViews"])
	{
		NSMutableArray *views = [NSMutableArray array], *viewsRect = [NSMutableArray array];
		
		[views addObject: [controller originalView]];
		[views addObject: [controller xReslicedView]];
		[views addObject: [controller yReslicedView]];
		
		for( int i = (long)views.count-1; i >= 0; i--)
		{
			if( NSEqualRects( [[views objectAtIndex: i] visibleRect], NSZeroRect))
				[views removeObjectAtIndex: i];
		}
		
		for( NSView *v in views)
		{
			NSRect bounds = [v bounds];
			NSPoint or = [v convertPoint: bounds.origin toView: nil];
			bounds.origin = [[self window] convertBaseToScreen: or];
            
            bounds.origin.x *= v.window.backingScaleFactor;
            bounds.origin.y *= v.window.backingScaleFactor;
            
            bounds.size.width *= v.window.backingScaleFactor;
            bounds.size.height *= v.window.backingScaleFactor;
            
			[viewsRect addObject: [NSValue valueWithRect: bounds]];
		}
		
		data = [[self keyView]     getRawPixelsWidth: &width
											  height: &height
												 spp: &spp
												 bpp: &bpp
									   screenCapture: YES
										  force8bits: YES
									 removeGraphical: YES
										squarePixels: YES
											allTiles: NO
								  allowSmartCropping: YES
											  origin: imOrigin
											 spacing: imSpacing
											  offset: &offset
											isSigned: &isSigned
											   views: views
										   viewsRect: viewsRect];
	}
	else
	{
		data = [[self keyView] getRawPixelsViewWidth: &width
											  height: &height
												 spp: &spp
												 bpp: &bpp
									   screenCapture: screenCapture
										  force8bits: NO
									 removeGraphical: YES
										squarePixels: YES
								  allowSmartCropping: YES
											  origin: imOrigin
											 spacing: imSpacing
											  offset: &offset
											isSigned: &isSigned];
	}
	
	if( data)
	{
		if( exportDCM == nil) exportDCM = [[DICOMExport alloc] init];
		
		[exportDCM setSourceFile: [[[controller originalDCMFilesList] objectAtIndex: [[self keyView] curImage]] valueForKey:@"completePath"]];
		[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
		
		[[self keyView] getWLWW:&cwl :&cww];
		
		if( [[viewer modality] isEqualToString: @"PT"] == YES)
		{
			float slope = [[viewer imageView] curDCM].appliedFactorPET2SUV * [[viewer imageView] curDCM].slope;
			[exportDCM setSlope: slope];
		}
		[exportDCM setDefaultWWWL: cww :cwl];
		
		[exportDCM setPixelSpacing: imSpacing[ 0] :imSpacing[ 1]];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportDCMIncludeAllViews"] == NO)
		{
			[exportDCM setSliceThickness: [curPix sliceThickness]];
			[exportDCM setSlicePosition: [curPix sliceLocation]];
			
			[[self keyView] orientationCorrectedToView: o];
			
	//		if( screenCapture)
	//			[[self keyView] orientationCorrectedToView: o];	// <- Because we do screen capture !!!!! We need to apply the rotation of the image
	//		else
	//			[curPix orientation: o];
				
			[exportDCM setOrientation: o];
			
			[exportDCM setPosition: imOrigin];
		}
		
		[exportDCM setPixelData: data samplesPerPixel:spp bitsPerSample:bpp width: width height: height];
		[exportDCM setSigned: isSigned];
		[exportDCM setOffset: offset];
		[exportDCM setModalityAsSource: YES];
		
		f = [exportDCM writeDCMFile: nil];
		if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		free( data);
	}
	[[NSUserDefaults standardUserDefaults] setInteger: annotCopy forKey: @"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger: clutBarsCopy forKey: @"CLUTBARS"];
	[DCMView setDefaults];
	
	if( f)
		return [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil];
	else
		return nil;
}

-(IBAction) endExportDICOMFileSettings:(id) sender
{
	long i, curImage;
	
	[dcmExportWindow makeFirstResponder: nil];	// To force nstextfield validation.
    [dcmExportWindow orderOut:sender];
    
    [NSApp endSheet:dcmExportWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		NSMutableArray *producedFiles = [NSMutableArray array];
	
		if( [[dcmSelection selectedCell] tag] == 0)
		{
			[producedFiles addObject: [self exportDICOMFileInt: [[dcmFormat selectedCell] tag]]];
		}
		else if( [[dcmSelection selectedCell] tag] == 2) // 4th Dimension
		{
			if( exportDCM == nil) exportDCM = [[DICOMExport alloc] init];
			[exportDCM setSeriesNumber:5600 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];	//Try to create a unique series number... Do you have a better idea??
			
			for( int i = 0; i < maxMovieIndex; i ++)
			{
				[self setMovieIndex: i];
				
				[producedFiles addObject: [self exportDICOMFileInt: [[dcmFormat selectedCell] tag]]];
			}
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
			[splash setCancel: YES];
			[splash showWindow: self];
			[[splash progress] setMaxValue:(int)((to-from)/interval)];
			
			@try
			{
				if( exportDCM == nil) exportDCM = [[DICOMExport alloc] init];
				[exportDCM setSeriesNumber:5600 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];	//Try to create a unique series number... Do you have a better idea??
				
				for( i = from; i < to; i+=interval)
				{
                    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					@try 
					{
						NSDisableScreenUpdates();
						[view setCrossPosition:x+i*deltaX+0.5 :y+i*deltaY+0.5];
						[splitView display];
						[view display];
						
						[producedFiles addObject: [self exportDICOMFileInt:[[dcmFormat selectedCell] tag]]];
						NSEnableScreenUpdates();
						
						NSEnableScreenUpdates();
						
						[splash incrementBy: 1];
						
						if( [splash aborted])
							break;
					}
					@catch (NSException * e) 
					{
                        N2LogExceptionWithStackTrace(e);
					}
                    @finally {
                        [pool release];
                    }
				}
				
				[view setCrossPosition:oldX+0.5 :oldY+0.5];
				
				[[self keyView] setIndex: curImage];
				
				[[self keyView] display];
			}
			@catch( NSException *e)
			{
				NSLog( @"***** Exception Creating a DICOM series: %@", e);
			}
			[splash close];
			[splash autorelease];
		}
		
		if( [producedFiles count])
		{
			NSArray *objects = [BrowserController.currentBrowser.database addFilesAtPaths: [producedFiles valueForKey: @"file"]
                                                                        postNotifications: YES
                                                                                dicomOnly: YES
                                                                      rereadExistingItems: YES
                                                                        generatedByOsiriX: YES];
			
            objects = [BrowserController.currentBrowser.database objectsWithIDs: objects];
            
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"])
				[[BrowserController currentBrowser] selectServer: objects];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"])
			{
				for( NSManagedObject *im in objects)
					[im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
			}
		}
	}
}

- (void) exportDICOMFile:(id) sender
{
    if( dcmExportWindow == nil)
    {
        NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"DICOM Files Export not supported", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
	long max = 0, curIndex = 0;
	OrthogonalMPRView *view = nil;
    
	if ([[self keyView] isEqualTo:[controller originalView]])
	{
		view = [controller xReslicedView];
		max = [[[self keyView] dcmPixList] count];
		curIndex = [[self keyView] curImage];
	}
	else if ([[self keyView] isEqualTo:[controller xReslicedView]])
	{
		view = [controller originalView];
		max = [[view curDCM] pheight];
		curIndex = [[controller originalView] crossPositionX];
	}
	else if ([[self keyView] isEqualTo:[controller yReslicedView]])
	{
		view = [controller originalView];
		max = [[view curDCM] pwidth];
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

	int count = fabs( [dcmFromTextField intValue] - [dcmToTextField intValue]);
	count++;
    if( [dcmIntervalTextField intValue])
        count /= [dcmIntervalTextField intValue];
	[dcmCountTextField setStringValue: [NSString stringWithFormat:@"%d images", count]];
	
	if( maxMovieIndex > 1)
		[[dcmSelection cellWithTag: 2] setEnabled: YES];
	else
		[[dcmSelection cellWithTag: 2] setEnabled: NO];
	
	if( [[dcmSelection selectedCell] isEnabled] == NO)
		[dcmSelection selectCellWithTag: 0];
	
	[self checkView: dcmBox :([[dcmSelection selectedCell] tag] == 1)];
	
    [NSApp beginSheet: dcmExportWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}
#endif

- (IBAction) changeFromAndToBounds:(id) sender
{
	if([sender isEqualTo:dcmFrom]){[dcmFromTextField setIntValue:[sender intValue]];[dcmFromTextField display];}
	else if([sender isEqualTo:dcmTo]){[dcmToTextField setIntValue:[sender intValue]];[dcmToTextField display];}
	else if([sender isEqualTo:dcmToTextField]){[dcmTo setIntValue:[sender intValue]];[dcmTo display];}
	else if([sender isEqualTo:dcmFromTextField]){[dcmFrom setIntValue:[sender intValue]];[dcmFrom display];}
	else if([sender isEqualTo:dcmIntervalTextField]){[dcmInterval setIntValue:[sender intValue]];[dcmInterval display];}
	else if([sender isEqualTo:dcmInterval]){[dcmIntervalTextField setIntValue:[sender intValue]];[dcmIntervalTextField display];}
	
	int count = fabs( [dcmFromTextField intValue] - [dcmToTextField intValue]);
	count++;
	count /= [dcmIntervalTextField intValue];
	[dcmCountTextField setStringValue: [NSString stringWithFormat:@"%d images", count]];
	
	if( sender == dcmIntervalTextField || sender == dcmInterval)
	{
		
	}
	else if ([[self keyView] isEqualTo:[controller originalView]])
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
#pragma mark Multi MPR viewport synchronization

// Actions linked to popupToolbarMenuItems linked to SyncSeriesToolbarItemIdentifier
- (void) syncSeriesScopeAction:(id) sender
{
    [OrthogonalMPRViewer syncSeriesScopeAction:sender :self] ;
}

- (void) syncSeriesBehaviorAction:(id) sender
{
    [OrthogonalMPRViewer syncSeriesBehaviorAction:sender :self] ;
}

- (void) syncSeriesStateAction:(id) sender
{
    [OrthogonalMPRViewer syncSeriesStateAction:sender :self] ;
}

// Action linked to SyncSeriesToolbarItemIdentifier
- (void) syncSeriesAction:(id) sender
{
    [OrthogonalMPRViewer syncSeriesAction:sender :self] ;
}

#pragma mark-


- (float*) syncOriginPosition
{
    return syncOriginPosition;
}

- (void) syncSeriesNotification:(NSNotification*)notification   // Observe OsirixOrthoMPRSyncSeriesNotification
{
    [OrthogonalMPRViewer syncSeriesNotification:self :notification ];
}

- (void) posChangeNotification:(NSNotification*)notification // Observe OsirixOrthoMPRPosChangeNotification
{
    [OrthogonalMPRViewer posChangeNotification:self :notification];
}

#pragma mark-

+ (SyncSeriesScope) syncSeriesScope{
    return globalSyncSeriesScope;
}

+ (void) getDICOMCoords:(id)viewer :(float*) location
{
    [[[viewer controller]xReslicedView] getCrossPositionDICOMCoords:location];
}

+ (void) resetSyncOriginPosition:(id)viewer
{
    [OrthogonalMPRViewer getDICOMCoords:viewer :[viewer syncOriginPosition]];
}

+ (void) initSyncSeriesProperties:(id)viewer
{
    // Set default values for syncSeries mechanism
    [viewer setSyncSeriesState: SyncSeriesStateDisable] ;
    [viewer setSyncSeriesBehavior: SyncSeriesBehaviorAbsolutePosWithSameStudy];
}

#pragma mark-

+ (void) syncSeriesScopeAction:(id) sender :(id)viewer
{
    if([sender isKindOfClass: [NSMenuItem class]]  )
        [OrthogonalMPRViewer updateSyncSeriesScope:viewer :[sender tag]] ;
}

+ (void) syncSeriesBehaviorAction:(id) sender :(id) viewer
{
    if([sender isKindOfClass: [NSMenuItem class]]  ){
        [OrthogonalMPRViewer updateSyncSeriesBehavior:viewer :[sender tag] ] ;
    }
}

+ (void) syncSeriesStateAction:(id) sender :(id) viewer
{
    if([sender isKindOfClass: [NSMenuItem class]] )
        [OrthogonalMPRViewer updateSyncSeriesState:viewer :[sender tag] ] ;
}

+ (void) syncSeriesAction:(id) sender :(id)viewer
{
    // Invert syncSeriesState or turn on Enable when viewer was SyncSeriesStateOff
    SyncSeriesState newState = ([viewer syncSeriesState] == SyncSeriesStateEnable)? SyncSeriesStateDisable : SyncSeriesStateEnable ;
    
    // Overrides current behavior when using modifier Keys during action
    SyncSeriesBehavior newBehavior = [viewer syncSeriesBehavior];
    NSUInteger modifierFlags = [[[NSApplication sharedApplication] currentEvent] modifierFlags] ;
    
    if( modifierFlags & NSAlternateKeyMask)
        newBehavior = SyncSeriesBehaviorAbsolutePos;
    else if( modifierFlags & NSShiftKeyMask)
        newBehavior = SyncSeriesBehaviorRelativePos;
    
    [OrthogonalMPRViewer updateSyncSeriesProperties:viewer :newState :globalSyncSeriesScope :newBehavior ];
}

#pragma mark-

+ (void) updateSyncSeriesState:(id)viewer :(SyncSeriesState) newState
{
    if([viewer syncSeriesState] != newState)
        [OrthogonalMPRViewer updateSyncSeriesProperties:viewer :newState :globalSyncSeriesScope :[viewer syncSeriesBehavior] ];
}

+ (void) updateSyncSeriesScope:(id)viewer :(SyncSeriesScope) newScope {
    
    if(globalSyncSeriesScope != newScope)
        [OrthogonalMPRViewer updateSyncSeriesProperties:viewer :[viewer syncSeriesState] :newScope :[viewer syncSeriesBehavior] ];
}

+ (void) updateSyncSeriesBehavior:(id)viewer :(SyncSeriesBehavior) newBehavior
{
    if([viewer syncSeriesBehavior] != newBehavior)
        [OrthogonalMPRViewer updateSyncSeriesProperties:viewer :[viewer syncSeriesState] :globalSyncSeriesScope :newBehavior ];
}

+ (void) updateSyncSeriesProperties:(id)viewer :(SyncSeriesState) newState :(SyncSeriesScope) newScope :(SyncSeriesBehavior) newBehavior  {
    
    if([viewer syncSeriesState] == newState && [viewer syncSeriesBehavior] == newBehavior && globalSyncSeriesScope == newScope )
        return;
    
    NSNotification *syncSeriesNotification =nil;

    DicomStudy *currentStudy = [viewer currentStudy];
    
    // Populate required info associated with this change
    NSDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:newState],@"syncState",
                              [NSNumber numberWithInt:newBehavior],@"syncBehavior",
                              nil ];
    
    if(newScope != SyncSeriesScopeAllSeries){     // Scope is at least same patient
        [userInfo setValue: [currentStudy valueForKey:@"patientID"] forKey:@"patientID"];       //  NSString
        [userInfo setValue: [currentStudy valueForKey:@"dateOfBirth"] forKey:@"dateOfBirth"];   //  NSDate
    }
    
    if (newScope == SyncSeriesScopeSameStudy || newBehavior == SyncSeriesBehaviorAbsolutePosWithSameStudy)
        [userInfo setValue: [currentStudy valueForKey:@"studyInstanceUID"] forKey:@"studyInstanceUID"]; //  NSString
    
    if(newState == SyncSeriesStateEnable){
        float currentDicomLocation[3] ;
        [OrthogonalMPRViewer getDICOMCoords:viewer :currentDicomLocation];
        
        NSArray* dicomCoords = [NSArray arrayWithObjects:
                                [NSNumber numberWithFloat:currentDicomLocation[0]],
                                [NSNumber numberWithFloat:currentDicomLocation[1]],
                                [NSNumber numberWithFloat:currentDicomLocation[2]],nil];
        
        [userInfo setValue: dicomCoords forKey:@"dicomCoords"];   //  NSArray*
    }

    syncSeriesNotification = [NSNotification notificationWithName:OsirixOrthoMPRSyncSeriesNotification object:viewer userInfo:userInfo];
    
    dispatch_block_t syncSeriesBlockOnMainThread = ^{
        globalSyncSeriesScope = newScope;
        [viewer setSyncSeriesState: newState];
        [viewer setSyncSeriesBehavior:  newBehavior];

        //        [[NSUserDefaults standardUserDefaults] setInteger:globalSyncSeriesScope forKey:@"globalMPRSyncSeriesScope"];
        
        [[NSNotificationCenter defaultCenter] postNotification: syncSeriesNotification];
        
        // Following messages need to be excuted sequentialy with postNotification in the main thread in order to keep in sync and propagate appropriate state values
        [OrthogonalMPRViewer validateViewersSyncSeriesState];
        [OrthogonalMPRViewer synchronizeViewersPosition:nil];

    };
    
    // Fire this event change on the MainThread
    if (dispatch_get_current_queue() == dispatch_get_main_queue()) { // avoid deadlocks when using dispatch_sync, same as => if(![NSThread isMainThread])
        syncSeriesBlockOnMainThread();
    } else {
        dispatch_async(dispatch_get_main_queue(), syncSeriesBlockOnMainThread);
    }
}

+ (void) positionChange:(id) viewer :(NSArray*) relativePositionChange{
    if([viewer syncSeriesState] != SyncSeriesStateEnable)
        return;

    DicomStudy *currentStudy = [viewer currentStudy];
    
    NSDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              relativePositionChange,@"positionChange",
                               nil ];
    
    if(globalSyncSeriesScope != SyncSeriesScopeAllSeries){     // Scope is at least same patient
        [userInfo setValue: [currentStudy valueForKey:@"patientID"] forKey:@"patientID"];       //  NSString
        [userInfo setValue: [currentStudy valueForKey:@"dateOfBirth"] forKey:@"dateOfBirth"];   //  NSDate
    }
    
    if (globalSyncSeriesScope == SyncSeriesScopeSameStudy || [viewer syncSeriesBehavior] == SyncSeriesBehaviorAbsolutePosWithSameStudy)
        [userInfo setValue: [currentStudy valueForKey:@"studyInstanceUID"] forKey:@"studyInstanceUID"]; //  NSString
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixOrthoMPRPosChangeNotification object:viewer  userInfo: userInfo];
}

#pragma mark-

+ (void) syncSeriesNotification:(id)viewer :(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    [OrthogonalMPRViewer resetSyncOriginPosition:viewer];     // Reset actual position as origin anytime a syncSeries change notification is send anywhere
    
    if([viewer isEqualTo:[notification object]]  )
        return;
    
    DicomStudy *currentStudy = [viewer currentStudy];

    NSString *senderStudyInstanceUID = [userInfo valueForKey:@"studyInstanceUID"];
    NSString *currentStudyInstanceUID = [currentStudy valueForKey:@"studyInstanceUID"];

    // Test if the sync change notification is within the current scope
    if(globalSyncSeriesScope != SyncSeriesScopeAllSeries){
        
        NSString *senderPatientID = [userInfo valueForKey:@"patientID"];
        NSString *currentPatientID = [currentStudy valueForKey:@"patientID"];
        
        NSDate *senderDateOfBirth = [userInfo valueForKey:@"dateOfBirth"];
        NSDate *currentDateOfBirth = [currentStudy valueForKey:@"dateOfBirth"];
        
        if([senderPatientID isNotEqualTo: currentPatientID] || [senderDateOfBirth isNotEqualTo: currentDateOfBirth] ) // Not Same patient ??
            return;
        
        if((globalSyncSeriesScope == SyncSeriesScopeSameStudy) && [senderStudyInstanceUID isNotEqualTo:currentStudyInstanceUID] ) // Not Same Study ??
            return;
    }
    
    // Propagate syncProperties (syncSeriesState and syncSeriesBehavior) and optionnaly move to a new location according to syncBehavior 
    
    [viewer setSyncSeriesBehavior :[[userInfo valueForKey:@"syncBehavior"]intValue]];
    
    if([viewer syncSeriesState] != SyncSeriesStateOff){ // state is not updated when current is off
        
        SyncSeriesState newState = [[userInfo valueForKey:@"syncState"]intValue];
        
        if(newState != SyncSeriesStateOff){ // syncOff value state is not propagated
            [viewer setSyncSeriesState: newState];
            
            if( [viewer syncSeriesState] == SyncSeriesStateEnable) {
                
                if(([viewer syncSeriesBehavior] == SyncSeriesBehaviorAbsolutePos) ||
                   (([viewer syncSeriesBehavior] == SyncSeriesBehaviorAbsolutePosWithSameStudy) && [senderStudyInstanceUID isEqualTo:currentStudyInstanceUID ])){
                    
                    NSArray* dicomCoords = [userInfo valueForKey:@"dicomCoords"];
                    [[viewer controller]  moveToAbsolutePosition:dicomCoords];
                    [OrthogonalMPRViewer resetSyncOriginPosition:viewer];
                }
            }
        }
    }
}

+ (void) posChangeNotification:(id)viewer :(NSNotification*)notification
{
    if([viewer isEqual:[notification object]] || [viewer syncSeriesState] != SyncSeriesStateEnable )
        return;
    
     NSDictionary *userInfo = [notification userInfo];
    
    // Test if the pos change notification is within the current scope
    if(globalSyncSeriesScope != SyncSeriesScopeAllSeries){
    
        DicomStudy *currentStudy = [viewer currentStudy];
        
        NSString *senderPatientID = [userInfo valueForKey:@"patientID"];
        NSString *currentPatientID = [currentStudy valueForKey:@"patientID"];
        
        NSDate *senderDateOfBirth = [userInfo valueForKey:@"dateOfBirth"];
        NSDate *currentDateOfBirth = [currentStudy valueForKey:@"dateOfBirth"];
        
        if([senderPatientID isNotEqualTo: currentPatientID] || [senderDateOfBirth isNotEqualTo: currentDateOfBirth] ) // Not Same patient ??
            return;

        NSString *senderStudyInstanceUID = [userInfo valueForKey:@"studyInstanceUID"];
        NSString *currentStudyInstanceUID = [currentStudy valueForKey:@"studyInstanceUID"];
        
        if((globalSyncSeriesScope == SyncSeriesScopeSameStudy) && [senderStudyInstanceUID isNotEqualTo:currentStudyInstanceUID] ) // 2 Same Study ??
            return;
    }

    [[viewer controller] moveToRelativePosition:[userInfo valueForKey:@"positionChange"]];
}

#pragma mark-

+ (void) synchronizeViewer:(id)currentViewer {
    
    // Evaluate all opened MPRviewers and update currentViewer's syncSeries Properties according to them
    // It will be updated to values matching thoses for which another MPRviewer has the currentViewer within its scope
    
    // Note that currentViewer's position may be changed in order to be in sync with other enabled viewers within the same scope when position change is in absolute mode
    
    // This message should be called just after the first image is displayed and positioned
    
    if (![NSThread isMainThread]){
        dispatch_sync(dispatch_get_main_queue(),^{ [OrthogonalMPRViewer synchronizeViewer:currentViewer]; });
        return;
    }

    [OrthogonalMPRViewer resetSyncOriginPosition:currentViewer]; // reset sync origin position, generally done the first time a viewer is loaded

    NSMutableArray* sortedViewers = [OrthogonalMPRViewer MPRViewersWithout:currentViewer];
    
    [sortedViewers sortUsingComparator: ^NSComparisonResult(id obj1, id obj2) { // sort is syncSeriesState == SyncSeriesStateEnable first
        if([obj1 syncSeriesState] > [obj2 syncSeriesState] )
            return NSOrderedAscending;
        else if([obj1 syncSeriesState] < [obj2 syncSeriesState] )
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    if([sortedViewers count] > 0){
        
        DicomStudy *currentStudy = [currentViewer currentStudy];
        NSString *currentPatientID = [currentStudy valueForKey:@"patientID"];
        NSDate *currentDateOfBirth = [currentStudy valueForKey:@"dateOfBirth"];
        NSString *currentStudyInstanceUID = [currentStudy valueForKey:@"studyInstanceUID"];

        BOOL isViewerSynchronized = NO;
        
        // Test if it's within the scope of any other viewer
        for(id anotherViewer in sortedViewers) {
            
            if(!isViewerSynchronized){

                if(globalSyncSeriesScope != SyncSeriesScopeAllSeries){
                    DicomStudy *anotherStudy = [anotherViewer currentStudy];
                    
                    // Same patient ??
                    if([currentPatientID isNotEqualTo: [anotherStudy valueForKey:@"patientID"]] ||
                       [currentDateOfBirth isNotEqualTo: [anotherStudy valueForKey:@"dateOfBirth"]]  )
                        continue;
                    
                    // Same Study ??
                    if((globalSyncSeriesScope == SyncSeriesScopeSameStudy) && [currentStudyInstanceUID isNotEqualTo:[anotherStudy valueForKey:@"studyInstanceUID"]] )
                        continue;
                }
                
                // Override default values to those of this first viewer that meets scope requirement
                SyncSeriesState newState = ([anotherViewer syncSeriesState] != SyncSeriesStateOff)?[anotherViewer syncSeriesState]:SyncSeriesStateDisable;
                SyncSeriesBehavior newBehavior = [anotherViewer syncSeriesBehavior];
                
                [currentViewer setSyncSeriesState: newState] ;
                [currentViewer setSyncSeriesBehavior: newBehavior];
                
                if(newState == SyncSeriesStateEnable)
                    [OrthogonalMPRViewer synchronizeViewersPosition:currentViewer];
                
                isViewerSynchronized = YES; // OK - within the scope of some viewer, no neeed to iterate more
            }

            [OrthogonalMPRViewer resetSyncOriginPosition:anotherViewer];     // Reset actual position as origin anytime a new viewer is synchronized anywhere
        }
    }
 }

+ (void) synchronizeViewersPosition:(id) onlyViewerToBeSynchronized{
    
    // Validate that absolute position of all enabled viewers are identical when it's required :
    // - for viewers with same study when behavior is set to SyncSeriesBehaviorAbsolutePosWithSameStudy
    // - for all viewers when behavior is set to SyncSeriesBehaviorAbsolutePos
    
    // Note if onlyViewerToBeSynchronized is not null (optionnal parameter), only this viewer's position will be re-synchronized with others
    
    if (![NSThread isMainThread]){
        dispatch_sync(dispatch_get_main_queue(),^{ [OrthogonalMPRViewer synchronizeViewersPosition:onlyViewerToBeSynchronized]; });
        return;
    }
    
    NSArray* syncEnabledViewers = [OrthogonalMPRViewer MPRViewersWithout:nil andSyncEnabled:TRUE];
    
    for(id currentViewer in syncEnabledViewers) {
        
        if([onlyViewerToBeSynchronized isEqualTo:currentViewer])
            continue;
        
        if([currentViewer syncSeriesBehavior] == SyncSeriesBehaviorRelativePos )
            continue;
        
        DicomStudy *currentStudy = [currentViewer currentStudy];
        NSString *currentPatientID = [currentStudy valueForKey:@"patientID"];
        NSDate *currentDateOfBirth = [currentStudy valueForKey:@"dateOfBirth"];
        NSString *currentStudyInstanceUID = [currentStudy valueForKey:@"studyInstanceUID"];
        
        // Test if another enabled syncState viewer is within current viewer's scope and behavior is somehow absolute related
        for(id anotherViewer in syncEnabledViewers) {
            
            if([currentViewer isEqualTo:anotherViewer] || (onlyViewerToBeSynchronized != nil && [onlyViewerToBeSynchronized isNotEqualTo:anotherViewer]))
                continue;
            
            if([anotherViewer syncSeriesBehavior]== SyncSeriesBehaviorRelativePos)
                continue;
            
            DicomStudy *anotherStudy = [anotherViewer currentStudy];
            
            if(globalSyncSeriesScope != SyncSeriesScopeAllSeries){
                // Same patient ??
                if([currentPatientID isNotEqualTo: [anotherStudy valueForKey:@"patientID"]] ||
                   [currentDateOfBirth isNotEqualTo: [anotherStudy valueForKey:@"dateOfBirth"]]  )
                    continue;
                
                // Same Study ??
                if((globalSyncSeriesScope == SyncSeriesScopeSameStudy) && [currentStudyInstanceUID isNotEqualTo:[anotherStudy valueForKey:@"studyInstanceUID"]] )
                    continue;
            }
            
            // Note that behavior is supposed to be the same for two viewers within the same scope
            if([anotherViewer syncSeriesBehavior]== SyncSeriesBehaviorAbsolutePosWithSameStudy && [currentStudyInstanceUID isNotEqualTo:[anotherStudy valueForKey:@"studyInstanceUID"]])
                continue;
            
            // Beeing there involves that the two viewers should have the same absolute position
            float anotherDicomLocation[3] ;
            [OrthogonalMPRViewer getDICOMCoords:anotherViewer :anotherDicomLocation];
          
            float currentDicomLocation[3] ;	
            [OrthogonalMPRViewer getDICOMCoords:currentViewer :currentDicomLocation];
            
            if( (currentDicomLocation[0]!=anotherDicomLocation[0]) || (currentDicomLocation[1]!=anotherDicomLocation[1]) || (currentDicomLocation[2]!=anotherDicomLocation[2])){

                NSArray* dicomCoords = [NSArray arrayWithObjects:
                                        [NSNumber numberWithFloat:currentDicomLocation[0]],
                                        [NSNumber numberWithFloat:currentDicomLocation[1]],
                                        [NSNumber numberWithFloat:currentDicomLocation[2]],nil];

                [[anotherViewer controller] moveToAbsolutePosition:dicomCoords];
                [OrthogonalMPRViewer resetSyncOriginPosition:anotherViewer];
            }
            
            if([onlyViewerToBeSynchronized isEqualTo:anotherViewer])
                return;
        }
    }
}

+ (void) validateViewersSyncSeriesState
{
    // Validate the enable syncState of all MPRviewers and force to disable if it's not within the scope of any other enabled syncState MPRviewer
    
    if (![NSThread isMainThread]){
        dispatch_sync(dispatch_get_main_queue(),^{ [OrthogonalMPRViewer validateViewersSyncSeriesState]; });
        return;
    }
    
    NSArray* syncEnabledViewers = [OrthogonalMPRViewer MPRViewersWithout:nil andSyncEnabled:TRUE];
    
    for(id currentViewer in syncEnabledViewers) {
        
        bool currentViewerEnableStateIsValid = false;
        
        DicomStudy *currentStudy = [currentViewer currentStudy];
        NSString *currentPatientID = [currentStudy valueForKey:@"patientID"];
        NSDate *currentDateOfBirth = [currentStudy valueForKey:@"dateOfBirth"];
        NSString *currentStudyInstanceUID = [currentStudy valueForKey:@"studyInstanceUID"];
        
        // Test if another enabled syncState MPRviewer is within current SyncScope
        for(id anotherViewer in syncEnabledViewers) {
            
            if([currentViewer isEqualTo:anotherViewer] )
                continue;
            
            DicomStudy *anotherStudy = [anotherViewer currentStudy];
            
            if(globalSyncSeriesScope != SyncSeriesScopeAllSeries){
                // Same patient ??
                if([currentPatientID isNotEqualTo: [anotherStudy valueForKey:@"patientID"]] ||
                   [currentDateOfBirth isNotEqualTo: [anotherStudy valueForKey:@"dateOfBirth"]]  )
                    continue;
                
                // Same Study ??
                if((globalSyncSeriesScope == SyncSeriesScopeSameStudy) && [currentStudyInstanceUID isNotEqualTo:[anotherStudy valueForKey:@"studyInstanceUID"]] )
                    continue;
            }
            
            currentViewerEnableStateIsValid = true;
            break;
        }
        
        if(currentViewerEnableStateIsValid == false){
            [currentViewer setSyncSeriesState:SyncSeriesStateDisable];    // no need to send notification since there is abviously no observer
        }
    }
}

#pragma mark-

+ (void) initSyncSeriesToolbarItem:(id)viewer :(NSToolbarItem*) toolbarItem
{
    if(![toolbarItem  isMemberOfClass:[KBPopUpToolbarItem class]]){
        NSLog(@"WARN - initSyncSeriesToolbarItem cannot be initialized");
        return;
    }
    
    [viewer setSyncSeriesToolbarItem:(KBPopUpToolbarItem*) toolbarItem];

    [toolbarItem setTarget: viewer];
    [toolbarItem setAction: @selector(syncSeriesAction:)];
    [toolbarItem setToolTip: NSLocalizedString(@"Synchronize 3D position", nil)];
    
    [toolbarItem setLabel: NSLocalizedString(@"Sync", nil)];
    [toolbarItem setPaletteLabel: NSLocalizedString(@"Sync", nil)];
    
    KBPopUpToolbarItem* popupToolbarItem = (KBPopUpToolbarItem*)toolbarItem;
    
    popupToolbarItem.menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    NSMenuItem* menuItem;

    menuItem = [popupToolbarItem.menu addItemWithTitle:NSLocalizedString(@"All", nil) action:@selector(syncSeriesScopeAction:) keyEquivalent:@""];
    menuItem.target = viewer;
    menuItem.tag=SyncSeriesScopeAllSeries;
    menuItem = [popupToolbarItem.menu addItemWithTitle:NSLocalizedString(@"Same Patient", nil) action:@selector(syncSeriesScopeAction:) keyEquivalent:@""];
    menuItem.target = viewer;
    menuItem.tag=SyncSeriesScopeSamePatient;
    menuItem = [popupToolbarItem.menu addItemWithTitle:NSLocalizedString(@"Same Study", nil) action:@selector(syncSeriesScopeAction:) keyEquivalent:@"" ];
    menuItem.target = viewer;
    menuItem.tag=SyncSeriesScopeSameStudy;
    
    [[popupToolbarItem menu] addItem:[NSMenuItem separatorItem]];
    
    menuItem = [popupToolbarItem.menu addItemWithTitle:NSLocalizedString(@"Force absolute positioning", nil) action:@selector(syncSeriesBehaviorAction:) keyEquivalent:@""];
    menuItem.target = viewer;
    menuItem.tag=SyncSeriesBehaviorAbsolutePos;
    menuItem = [popupToolbarItem.menu addItemWithTitle:NSLocalizedString(@"Force relative positioning", nil) action:@selector(syncSeriesBehaviorAction:) keyEquivalent:@""];
    menuItem.target = viewer;
    menuItem.tag=SyncSeriesBehaviorRelativePos;
    menuItem = [popupToolbarItem.menu addItemWithTitle:NSLocalizedString(@"Absolute positioning for same study", nil) action:@selector(syncSeriesBehaviorAction:) keyEquivalent:@""];
    menuItem.target = viewer;
    menuItem.tag=SyncSeriesBehaviorAbsolutePosWithSameStudy;
    
    [[popupToolbarItem menu] addItem:[NSMenuItem separatorItem]];
    
    menuItem = [[popupToolbarItem menu] addItemWithTitle:NSLocalizedString(@"No synchronization for this window", nil) action:@selector(syncSeriesStateAction:) keyEquivalent:@""];
    menuItem.target = viewer;
    menuItem.tag=SyncSeriesStateOff;
    
    [OrthogonalMPRViewer updateSyncSeriesToolbarItemUI:viewer];
}

+ (void) updateSyncSeriesToolbarItemUI:(id) viewer{

    if (![NSThread isMainThread]){
        dispatch_sync(dispatch_get_main_queue(),^{ [OrthogonalMPRViewer updateSyncSeriesToolbarItemUI:viewer]; });
        return;
    }
    [[viewer syncSeriesToolbarItem] setImage: ([viewer syncSeriesState] == SyncSeriesStateEnable)?[NSImage imageNamed: SyncLockSeriesImageName]:[NSImage imageNamed: SyncSeriesImageName]];
}

+ (void) evaluteSyncSeriesToolbarItemActivationWhenInit:(id)currentViewer;
{
    activateSyncSeriesToolbarItem =  [[OrthogonalMPRViewer MPRViewersWithout:currentViewer] count] > 0 ;
}

+ (void) evaluteSyncSeriesToolbarItemActivationBeforeClose:(id)currentViewer;
{
    activateSyncSeriesToolbarItem =  [[OrthogonalMPRViewer MPRViewersWithout:currentViewer] count] > 1 ;
}

+ (BOOL) getSyncSeriesToolbarItemActivation
{
    return activateSyncSeriesToolbarItem;
}

#pragma mark-

+ (NSMutableArray*) MPRViewersWithout:(id) currentViewer
{
    return [OrthogonalMPRViewer MPRViewersWithout:currentViewer andSyncEnabled:FALSE];
}

+ (NSMutableArray*) MPRViewersWithout:(id)currentViewer andSyncEnabled:(BOOL)syncEnabledOnly
{
    NSArray *windowsApps = [NSApp windows];
    NSMutableArray *viewerApps = [NSMutableArray array];
    
    for(id windowItem in windowsApps) {
        id windowController = [windowItem windowController];
        
        if(![OrthogonalMPRViewer isMPRViewer:windowController] ||
           (currentViewer !=nil && [currentViewer isEqualTo:windowController]) ||
           (syncEnabledOnly && [windowController syncSeriesState] != SyncSeriesStateEnable ))
            continue;

        [viewerApps addObject:windowController];
    }
    return viewerApps;
}

+ (bool) isMPRViewer:(id) viewer{
    
    return [viewer isKindOfClass:[OrthogonalMPRViewer class]]
#ifndef OSIRIX_LIGHT
    || [viewer isKindOfClass:[OrthogonalMPRPETCTViewer class]]
#endif
    ;
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
        
		[movieTextSlide setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.0f im/s", @"im/s = images per second"), (float) [movieRateSlider floatValue]]];
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

- (short) curMovieIndex { return curMovieIndex;}
- (short) maxMovieIndex { return maxMovieIndex;}

- (void) setMovieIndex: (short) i
{
	int index = [[controller originalView] curImage];
	
	
	curMovieIndex = i;
	if( curMovieIndex < 0) curMovieIndex = maxMovieIndex-1;
	if( curMovieIndex >= maxMovieIndex) curMovieIndex = 0;
	
	[moviePosSlider setIntValue:curMovieIndex];
	
	[[controller reslicer] setOriginalDCMPixList:[viewer pixList:i]];
	[[controller reslicer] setUseYcache:NO];
	[[controller originalView] setPixels:[viewer pixList:i] files:[viewer fileList:i] rois:[viewer roiList:i] firstImage:0 level:'i' reset:NO];
	
	[controller setFusion];
	
//	[self setWindowTitle: self];
	
//	if( wasDataFlipped) [self flipDataSeries: self];
	
	[[controller originalView] setIndex:index];
	//[[controller originalView] sendSyncMessage: 0];
	[controller setFusion];
	
	[controller refreshViews];
}

- (void) movieRateSliderAction:(id) sender
{
	[movieTextSlide setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.0f im/s", @"im/s = images per second"), (float) [movieRateSlider floatValue]]];
}

- (void) moviePosSliderAction:(id) sender
{
	[self setMovieIndex: [moviePosSlider intValue]];
//	[self propagateSettings];
}

- (ViewerController *)viewerController{
	return viewer;
}

- (DicomStudy*) currentStudy
{
	return [viewer currentStudy];
}
- (DicomSeries*) currentSeries
{
	return [viewer currentSeries];
}

- (DicomImage*) currentImage
{
	return [viewer currentImage];
}

-(float)curWW
{
	return [viewer curWW];
}

-(float)curWL
{
	return [viewer curWL];
}
- (NSString *)curCLUTMenu
{
	return curCLUTMenu;
}
- (NSString *)curOpacityMenu
{
	return curOpacityMenu;
}

- (void)setCurrentTool:(ToolMode)currentTool
{
	if (currentTool >= 0)
    {
		[controller setCurrentTool: currentTool];
		[toolsMatrix selectCellWithTag:currentTool];
	}
}

- (void)bringToFrontROI:(ROI*)roi;{}
- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;{}

@end
