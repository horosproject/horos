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




#import "MPRController.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "NSFullScreenWindow.h"
#import "WaitRendering.h"
#include <Accelerate/Accelerate.h>
#import "iPhoto.h"
#import "MPRView.h"

extern "C"
{
extern NSString * documentsDirectory();
}

static NSString* 	MPRToolbarIdentifier            = @"MPR3D Toolbar Identifier";
static NSString*	QTExportToolbarItemIdentifier 	= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier 	= @"iPhoto.icns";
static NSString*	StereoIdentifier				= @"Stereo.icns";
static NSString*	QTExportVRToolbarItemIdentifier = @"QTExportVR.icns";
static NSString*	ToolsToolbarItemIdentifier		= @"Tools";
static NSString*	AxesToolbarItemIdentifier		= @"Axes";
static NSString*	WLWWToolbarItemIdentifier		= @"WLWW";
static NSString*	BlendingToolbarItemIdentifier   = @"2DBlending";
static NSString*	ThickSlabToolbarItemIdentifier	= @"ThickSlab";
static NSString*	AxToolbarItemIdentifier			= @"Axial.tif";
static NSString*	SaToolbarItemIdentifier			= @"Sag.tif";
static NSString*	CoToolbarItemIdentifier			= @"Cor.tif";
static NSString*	MovieToolbarItemIdentifier		= @"Movie";
static NSString*	MailToolbarItemIdentifier		= @"Mail.icns";




@implementation MPRController

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
    
    [[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Other", nil) action:nil keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Other", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Default WL & WW", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Full dynamic", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[wlwwPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
    [[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    [[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector (SetWLWW:) keyEquivalent:@""];
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:curWLWWMenu];
}




- (void) windowDidLoad
{
    [self setupToolbar];
}

-(ViewerController*) blendingController
{
	return blendingController;
}

- (void) blendingSlider:(id) sender
{
	[view setBlendingFactor: [sender floatValue]];
	
	[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([sender floatValue]+256.) / 5.12]];
}

-(BOOL) is2DViewer {return NO;}

-(void) updateBlendingImage
{
	Pixel_8			*alphaTable, *redTable, *greenTable, *blueTable;
	float			iwl, iww;

	if( blendingController)
	{
		[[blendingController imageView] colorTables:&alphaTable :&redTable :&greenTable :&blueTable];

		[view setBlendingCLUT :redTable :greenTable :blueTable];
		
		[[blendingController imageView] getWLWW: &iwl :&iww];
		[view setBlendingWLWW :iwl :iww];
	}
}

- (void) movieRateSliderAction:(id) sender
{
	[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
}

- (void) moviePosSliderAction:(id) sender
{
	curMovieIndex = [moviePosSlider intValue];
	
	[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes]];
}



- (void) performMovieAnimation:(id) sender
{
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
    if( thisTime - lastMovieTime > 1.0 / [movieRateSlider floatValue])
    {
        val = curMovieIndex;
        val ++;
        
		if( val < 0) val = 0;
		if( val >= maxMovieIndex) val = 0;
		
		curMovieIndex = val;

		[moviePosSlider setIntValue:curMovieIndex];
		
		[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes]];
		
	//	[imageView setDCM:pixList[curMovieIndex] :fileList[curMovieIndex] :0 :'i' :NO];
	//	[imageView setIndex:[imageView curImage]];
		
        lastMovieTime = thisTime;
    }
}

- (void) MoviePlayStop:(id) sender
{
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
        
        [moviePlayStop setTitle: @"Play"];
        
		[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
    }
    else
    {
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
    
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
        
        [moviePlayStop setTitle: @"Stop"];
    }
}

-(void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData
{
	[pix retain];
	pixList[ maxMovieIndex] = pix;
	
	[vData retain];
	volumeData[ maxMovieIndex] = vData;
	
	maxMovieIndex++;
	
	[moviePosSlider setMaxValue:maxMovieIndex-1];
	[moviePosSlider setNumberOfTickMarks:maxMovieIndex];

	[movieRateSlider setEnabled: YES];
	[moviePosSlider setEnabled: YES];
	[moviePlayStop setEnabled: YES];
}

-(NSMutableArray*) pixList {return pixList[0];}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
	
	movieTimer = 0L;
	blendingController = 0L;
	curMovieIndex = 0;
	maxMovieIndex = 1;
	curCLUTMenu = NSLocalizedString(@"No CLUT", nil);
	[curCLUTMenu retain];
	
    DCMPix  *firstObject	= [pix objectAtIndex:0];
    float   sliceThickness  = fabs( [firstObject sliceInterval]);   //fabs( [firstObject sliceLocation] - [[pix objectAtIndex:1] sliceLocation]);
    
    if( sliceThickness == 0)
    {
		sliceThickness = [firstObject sliceThickness];
		
        testInterval = NO;
		
		if( sliceThickness > 0) NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval",nil),  NSLocalizedString(@"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		else
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval/thickness",nil),NSLocalizedString(  @"Problems with slice thickness/interval to do a 3D reconstruction.",nil), NSLocalizedString(@"OK",nil), nil, nil);
			return 0L;
		}
    }
    
    // CHECK IMAGE SIZE
    for( i =0 ; i < [pix count]; i++)
    {
        if( [firstObject pwidth] != [[pix objectAtIndex:i] pwidth]) err = -1;
        if( [firstObject pheight] != [[pix objectAtIndex:i] pheight]) err = -1;
    }
    if( err)
    {
        NSRunCriticalAlertPanel(NSLocalizedString( @"Images size",nil),NSLocalizedString(  @"These images don't have the same height and width to allow a 3D reconstruction...",nil), NSLocalizedString(@"OK",nil), nil, nil);
        return 0L;
    }
    
    // CHECK IMAGE SIZE
//	if( testInterval)
//	{
//		float prevLoc = [firstObject sliceLocation];
//		for( i = 1 ; i < [pix count]; i++)
//		{
//			if( fabs (sliceThickness - fabs( [[pix objectAtIndex:i] sliceLocation] - prevLoc)) > 0.1) err = -1;
//			prevLoc = [[pix objectAtIndex:i] sliceLocation];
//		}
//		if( err)
//		{
//			if( NSRunCriticalAlertPanel( @"Slices location",  @"Slice thickness/interval is not exactly equal for all images. This could distord the 3D reconstruction...", @"Continue", @"Cancel", nil) != NSAlertDefaultReturn) return 0L;
//			err = 0;
//		}
//	}
	
	pixList[0] = pix;
	[pixList[0] retain];
	
	fileList = f;
	[fileList retain];
	
	volumeData[0] = vData;
	[volumeData[0] retain];
    self = [super initWithWindowNibName:@"MPR"];
    
    [[self window] setDelegate:self];
    
	
	WaitRendering *splash = [[WaitRendering alloc] init:@"Rendering..."];
	[splash showWindow:self];

	[Xslider setMaxValue: [firstObject pwidth]-1];
	[Xslider setIntValue: [firstObject pwidth]/2];
	[viewSlider setMaxValue: [firstObject pwidth]-1];
	[viewSlider setNumberOfTickMarks:[firstObject pwidth]];
	[viewSlider setIntValue: [firstObject pwidth]/2];
	[Yslider setMaxValue: [firstObject pheight]-1];
	[Yslider setIntValue: [firstObject pheight]/2];
	[Zslider setMaxValue: [pixList[0] count]-1];
	[Zslider setIntValue: [pixList[0] count]/2];
	
    err = [view setPixSource:pixList[0] :fileList :(float*) [volumeData[0] bytes]];
    if( err != 0)
    {
        [self dealloc];
        return 0L;
    }
    
	[[self window] performZoom:self];

	[movieRateSlider setEnabled: NO];
	[moviePosSlider setEnabled: NO];
	[moviePlayStop setEnabled:NO];
	
	bC = 0L;	// BLENDING DOESNT WORK IN CURRENT VERSION +++
	blendingController = bC;
	if( blendingController) // Blending! Activate image fusion
	{
		[view setBlendingPixSource: blendingController];
		
		[blendingSlider setEnabled:YES];
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
		
		[self updateBlendingImage];
	}

	[splash close];
	[splash release];

	curWLWWMenu = NSLocalizedString(@"Other", 0L);
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];

    [nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	
	[nc addObserver: self
		   selector: @selector(planesMove:)
			   name: @"planesMove"
			 object: nil];
	
	[nc addObserver: self
           selector: @selector(CLUTChanged:)
               name: @"CLUTChanged"
             object: nil];
			 
	[nc	addObserver: self
					selector: @selector(CloseViewerNotification:)
					name: @"CloseViewerNotification"
					object: nil];

    return self;
}

-(void) dealloc
{
	long i;
	
    NSLog(@"Dealloc MPRController");
	
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
	for( i = 0; i < maxMovieIndex; i++)
	{
		[pixList[ i] release];
		[volumeData[ i] release];
	}
	
	[fileList release];
	
	[toolbar setDelegate: 0L];
	[toolbar release];
	
	[super dealloc];
}

- (void) planesMove:(NSNotification*) note
{
	NSDictionary	*dict = [note userInfo];
	long			val1, val2;
	
//	NSLog(@"planesMove");
	
	val1 = [[dict objectForKey:@"X"] longValue];
	val2 = [[dict objectForKey:@"Y"] longValue];
	
	switch( [[selectedPlaneMatrix selectedCell] tag])
	{
		case 0:
			[Yslider setIntValue:val1];
			[Zslider setIntValue:val2];
		break;
		
		case 1:
			[Xslider setIntValue:val1];
			[Zslider setIntValue:val2];
		break;
		
		case 2:
			[Xslider setIntValue:val1];
			[Yslider setIntValue:val2];
		break;
	}
	
	[view movePlanes:[Xslider floatValue] :[Yslider floatValue] :[Zslider floatValue]];
}

-(void) getPlanes:(long*) x :(long*) y
{
	switch( [[selectedPlaneMatrix selectedCell] tag])
	{
		case 0:
			*x = [Yslider intValue];		*y = [Zslider intValue];
		break;
		
		case 1:
			*x = [Xslider intValue];		*y = [Zslider intValue];
		break;
		
		case 2:
			*x = [Xslider intValue];		*y = [Yslider intValue];
		break;
	}
}

-(IBAction) slider2DAction:(id) sender
{
	switch( [[selectedPlaneMatrix selectedCell] tag])
	{
		case 0:
			[view movePlanes:[sender floatValue] :[Yslider floatValue] :[Zslider floatValue]];
			[Xslider setIntValue:[sender intValue]];
		break;
		
		case 1:
			[view movePlanes:[Xslider floatValue] :[sender floatValue] :[Zslider floatValue]];
			[Yslider setIntValue:[sender intValue]];
		break;
			
		case 2:
			[view movePlanes:[Xslider floatValue] :[Yslider floatValue] :[sender floatValue]];
			[Zslider setIntValue:[sender intValue]];
		break;
	}
}

-(IBAction) selectPlane:(id) sender
{
	switch( [[selectedPlaneMatrix selectedCell] tag])
	{
		case 0:
			[viewSlider setMaxValue: [Xslider maxValue]];
			[viewSlider setNumberOfTickMarks:(int) [Xslider maxValue]+1];
			[viewSlider setIntValue: [Xslider intValue]];
		break;
		case 1:
			[viewSlider setMaxValue: [Yslider maxValue]];
			[viewSlider setNumberOfTickMarks:(int) [Yslider maxValue]+1];
			[viewSlider setIntValue: [Yslider intValue]];
		break;
		case 2:
			[viewSlider setMaxValue: [Zslider maxValue]];
			[viewSlider setNumberOfTickMarks:(int) [Zslider maxValue]+1];
			[viewSlider setIntValue: [Zslider intValue]];
		break;
	}

	[view setSelectedPlaneID: [[selectedPlaneMatrix selectedCell] tag]];
	
	[view movePlanes:[Xslider floatValue] :[Yslider floatValue] :[Zslider floatValue]];
}


-(IBAction) nextPlane:(id) sender
{
	long nextTag;
	
	nextTag = [[selectedPlaneMatrix selectedCell] tag];
	nextTag++;
	if( nextTag > 2) nextTag = 0;
	[selectedPlaneMatrix selectCellWithTag: nextTag];
	
	[self selectPlane:[selectedPlaneMatrix selectedCell]];
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];

	 if(c ==  NSRightArrowFunctionKey || c == 'x')
	 {
		[viewSlider setIntValue:[viewSlider intValue]+1];
		[self slider2DAction: viewSlider];
	 }
	 else  if(c ==  NSLeftArrowFunctionKey || c == 'z')
	 {
		[viewSlider setIntValue:[viewSlider intValue]-1];
		[self slider2DAction: viewSlider];
	 }
	 else if( c == 'i' || c  == 'o' || c == 'p')
	 {
		if( c == 'i') [selectedPlaneMatrix selectCellWithTag: 0];
		if( c == 'o') [selectedPlaneMatrix selectCellWithTag: 1];
		if( c == 'p') [selectedPlaneMatrix selectCellWithTag: 2];
		
		[self selectPlane:[selectedPlaneMatrix selectedCell]];
	 }
	 else if( (c >='a' && c <= 'g') || (c >='1' && c <= '7'))
	 {
		float direction;
		
		if( (c >='a' && c <= 'g')) {c -= 'a' -1;	direction = -1;}
		if( (c >='1' && c <= '7')) {c -= '1' -1;	direction = 1;}
		
		float newVal = direction * 256. * ((float) c / 7.);
		
		[blendingSlider setFloatValue: newVal];
		
		[view setBlendingFactor: [blendingSlider floatValue]];
		
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue]+256.) / 5.12]];
	 }
	 else [super keyDown:event];
}


- (void)scrollWheel:(NSEvent *)theEvent
{
	if( [theEvent deltaY] > 0) [viewSlider setIntValue:[viewSlider intValue]+1];
	else [viewSlider setIntValue:[viewSlider intValue]-1];
	
	[self slider2DAction: viewSlider];
}

-(void) sliderAction:(id) sender
{
	if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	{
		[self selectPlane: sender];
	}
	
	if([[selectedPlaneMatrix selectedCell] tag] == [sender tag])
	{
		[viewSlider setIntValue: [sender intValue]];
	}
	
    [view movePlanes:[Xslider floatValue] :[Yslider floatValue] :[Zslider floatValue]];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	long				i;
	ViewerController	*v = [note object];
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		if( [v pixList] == pixList[ i])
		{
			[self offFullScreen];
			[self close];
			return;
		}
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( movieTimer)
	{
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
	}
	
	[view stopRotateTimer];

    [[self window] setDelegate:nil];
    
	[self release];
}

-(void) setDefaultTool:(id) sender
{
    id          theCell = [sender selectedCell];
    
    if( [theCell tag] >= 0)
    {
        [view setCurrentTool: [theCell tag]];
    }
}


- (void) getWLWW:(float*) lwl :(float*) lww
{
	[view getWLWW:lwl :lww];
}

- (void) setWLWW:(float) iwl :(float) iww
{
	[view setWLWW: iwl : iww];
}

- (void) ApplyWLWW:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet(NSLocalizedString( @"Delete a WL/WW preset",nil), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete preset : '%@'?", [sender title]]);
    }
    else
    {
		if( [[sender title] isEqualToString:NSLocalizedString(@"Other", 0L)] == YES)
		{
			//[imageView setWLWW:0 :0];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Default WL & WW", 0L)] == YES)
		{
			[view setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Full dynamic", 0L)] == YES)
		{
			[view setWLWW:0 :0];
		}
		else
		{
			NSArray    *value;
			
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey: [sender title]];
			
			[view setWLWW:[[value objectAtIndex:0] floatValue]: [[value objectAtIndex:1] floatValue]];
		}
		[[[wlwwPopup menu] itemAtIndex:0] setTitle:[sender title]];
    }
	
	curWLWWMenu = [sender title];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
}


- (void) AddCurrentWLWW:(id) sender
{
	float iww, iwl;
    
    [view getWLWW:&iwl :&iww];
    
    [wl setStringValue:[NSString stringWithFormat:@"%0.f", iwl]];
    [ww setStringValue:[NSString stringWithFormat:@"%0.f", iww]];
    
	[newName setStringValue: @"Unnamed"];
	
    [NSApp beginSheet: addWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}



-(void) ApplyCLUTString:(NSString*) str
{
	if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES)
	{
		[view setCLUT: 0L :0L :0L];
		curCLUTMenu = str;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
		
		[[[clutPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		NSDictionary		*aCLUT;
		NSArray				*array;
		long				i;
		unsigned char		red[256], green[256], blue[256];
		
		aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey:str];
		if( aCLUT)
		{
			array = [aCLUT objectForKey:@"Red"];
			for( i = 0; i < 256; i++)
			{
				red[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Green"];
			for( i = 0; i < 256; i++)
			{
				green[i] = [[array objectAtIndex: i] longValue];
			}
			
			array = [aCLUT objectForKey:@"Blue"];
			for( i = 0; i < 256; i++)
			{
				blue[i] = [[array objectAtIndex: i] longValue];
			}
			
			[view setCLUT:red :green: blue];
			curCLUTMenu = str;
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle:str];
			
			
		}
	}
}



// ============================================================
// NSToolbar Related Methods
// ============================================================
#pragma mark-
#pragma mark Toolbar Related Methods

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: MPRToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
    
//    [window makeKeyAndOrderFront:nil];
}

- (IBAction)customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
    if ([itemIdent isEqual: QTExportVRToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export QTVR",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Export QTVR",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime VR file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
    }
	else if ([itemIdent isEqual: StereoIdentifier]) {
		
	[toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Stereo",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Switch Stereo Mode ON/OFF",nil)];
	[toolbarItem setImage: [NSImage imageNamed: StereoIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(SwitchStereoMode:)];
    }
	else if ([itemIdent isEqual: MailToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Email",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Email",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image",nil)];
	[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(sendMail:)];
    }
	else if ([itemIdent isEqual: QTExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export QT",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Export QT",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Export this series in a Quicktime file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else if ([itemIdent isEqual: iPhotoToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"iPhoto",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series to iPhoto",nil)];
	[toolbarItem setImage: [NSImage imageNamed: iPhotoToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(export2iPhoto:)];
    }
    else if([itemIdent isEqual: WLWWToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"WL/WW & CLUT",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Modify WL/WW & CLUT",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: WLWWView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
	else if ([itemIdent isEqual: AxToolbarItemIdentifier]) {
	
	[toolbarItem setLabel:NSLocalizedString( @"Axial",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Axial",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Move to an axial view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: AxToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(axView:)];
    }
	else if ([itemIdent isEqual: SaToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Sagittal",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Sagittal",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Move to an sagittal view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: SaToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(saView:)];
    }
	else if ([itemIdent isEqual: CoToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Coronal",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Coronal",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Move to an coronal view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: CoToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(coView:)];
    }
     else if([itemIdent isEqual: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the mouse function",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]),NSHeight([toolsView frame]))];

    }
	 else if([itemIdent isEqual: BlendingToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Fusion",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: BlendingView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
    }
	 else if([itemIdent isEqual: ThickSlabToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Thick Slab",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Thick Slab",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: ThickSlabView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]), NSHeight([ThickSlabView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame])+200, NSHeight([ThickSlabView frame]))];
    }
	else if([itemIdent isEqual: MovieToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"4D Player",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"4D Player",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: movieView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
    }
	else if([itemIdent isEqual: AxesToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"MPR Axes",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"MPR Axes",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change MPR Axes",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: axesView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([axesView frame]), NSHeight([axesView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([axesView frame]),NSHeight([axesView frame]))];

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
											AxesToolbarItemIdentifier,
											ThickSlabToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
                                            NSToolbarFlexibleSpaceItemIdentifier, 
											QTExportToolbarItemIdentifier,
											QTExportVRToolbarItemIdentifier,
											MailToolbarItemIdentifier,
										//	AxToolbarItemIdentifier,
										//	SaToolbarItemIdentifier,
										//	CoToolbarItemIdentifier,
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
										AxesToolbarItemIdentifier,
										ThickSlabToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
                                        ToolsToolbarItemIdentifier,
										QTExportToolbarItemIdentifier,
										iPhotoToolbarItemIdentifier,
										QTExportVRToolbarItemIdentifier,
										MailToolbarItemIdentifier,
										StereoIdentifier,
										AxToolbarItemIdentifier,
										SaToolbarItemIdentifier,
										CoToolbarItemIdentifier,
                                        nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
//    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
	
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

//--------------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark-

-(void) sendMail:(id) sender
{
	NSImage *im = [view nsimage:NO];
	
	[self sendMailImage: im];
	
	[im release];
}

-(void) export2iPhoto:(id) sender
{
	iPhoto		*ifoto;
	NSImage		*im = [view nsimage:NO];
	
	NSArray		*representations;
	NSData		*bitmapData;
	
	representations = [im representations];
	
	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
	[bitmapData writeToFile:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
	
	[im release];
	
	ifoto = [[iPhoto alloc] init];
	[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
	[ifoto release];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:0L file:@"3D MPR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
		[im release];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
			[ws openFile:[panel filename]];
	}
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"tif"];
	
	if( [panel runModalForDirectory:0L file:@"3D MPR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
		
		[im release];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
			[ws openFile:[panel filename]];
	}
}
@end
