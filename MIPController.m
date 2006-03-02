/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "MIPController.h"
#import "DCMView.h"
#import "NSFullScreenWindow.h"
#import "dicomFile.h"
#import "Papyrus3/Papyrus3.h"
#import "BrowserController.h"
#include <Accelerate/Accelerate.h>
#import "iPhoto.h"

extern BrowserController *browserWindow;
extern NSString * documentsDirectory();
extern NSString* convertDICOM( NSString *inputfile);

extern long DatabaseIndex;
extern BOOL DICOMFILEINDATABASE, OPENVIEWER;

static NSString* 	MIPToolbarIdentifier            = @"MIP Toolbar Identifier";
static NSString*	QTExportToolbarItemIdentifier 	= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier 	= @"iPhoto.icns";
static NSString*	QTExportVRToolbarItemIdentifier = @"QTExportVR.icns";
static NSString*	StereoIdentifier				= @"Stereo.icns";
static NSString*	CaptureToolbarItemIdentifier 	= @"Capture.icns";
static NSString*	CroppingToolbarItemIdentifier 	= @"Cropping.icns";
static NSString*	AxToolbarItemIdentifier			= @"Axial.tif";
static NSString*	SaToolbarItemIdentifier			= @"Sag.tif";
static NSString*	CoToolbarItemIdentifier			= @"Cor.tif";
static NSString*	ToolsToolbarItemIdentifier		= @"Tools";
static NSString*	WLWWToolbarItemIdentifier		= @"WLWW";
static NSString*	LODToolbarItemIdentifier		= @"LOD";
static NSString*	BlendingToolbarItemIdentifier   = @"2DBlending";
static NSString*	ExportToolbarItemIdentifier		= @"Export.icns";
static NSString*	MailToolbarItemIdentifier		= @"Mail.icns";
static NSString*	PerspectiveToolbarItemIdentifier= @"Perspective";
static NSString*	ResetToolbarItemIdentifier		= @"Reset.tiff";
static NSString*	MovieToolbarItemIdentifier		= @"Movie";
static NSString*	RevertToolbarItemIdentifier		= @"Revert.tiff";

extern  NSMutableDictionary     *presetsDict;
extern  NSMutableDictionary     *clutDict;

@implementation MIPController

-(void) revertSeries:(id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"revertSeriesNotification" object: pixList[ curMovieIndex] userInfo: 0L];
}

-(void) UpdateCLUTMenu: (NSNotification*) note
{
    //*** Build the menu
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [clutDict allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    i = [[clutPopup menu] numberOfItems];
    while(i-- > 0) [[clutPopup menu] removeItemAtIndex:0];
	
	[[clutPopup menu] addItemWithTitle:@"No CLUT" action:nil keyEquivalent:@""];
    [[clutPopup menu] addItemWithTitle:@"No CLUT" action:@selector (ApplyCLUT:) keyEquivalent:@""];
	[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
    }
    [[clutPopup menu] addItem: [NSMenuItem separatorItem]];
    [[clutPopup menu] addItemWithTitle:@"Add a CLUT" action:@selector (AddCLUT:) keyEquivalent:@""];

	[[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
}

-(void) UpdateWLWWMenu: (NSNotification*) note
{
    //*** Build the menu

    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;

    // Presets VIEWER Menu
	
	keys = [presetsDict allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    i = [[wlwwPopup menu] numberOfItems];
    while(i-- > 0) [[wlwwPopup menu] removeItemAtIndex:0];
    
/*    item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"Presets"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[wlwwPopup menu] addItem:item];
    [item release]; */
    
    [[wlwwPopup menu] addItemWithTitle:@"Other" action:nil keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:@"Other" action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:@"Default WL & WW" action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:@"Full dynamic" action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[wlwwPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
    [[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    [[wlwwPopup menu] addItemWithTitle:@"Add Current WL/WW" action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:@"Set WL/WW Manually" action:@selector (SetWLWW:) keyEquivalent:@""];
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:curWLWWMenu];
}

-(IBAction) fullScreenMenu:(id) sender
{
    if( FullScreenOn == YES ) // we need to go back to non-full screen
    {
        [StartingWindow setContentView: contentView];
    //    [FullScreenWindow setContentView: nil];
    
        [FullScreenWindow setDelegate:nil];
        [FullScreenWindow close];
        
        
   //     [contentView release];
        
        [StartingWindow makeKeyAndOrderFront: self];
   //     [StartingWindow makeFirstResponder: self];
        FullScreenOn = NO;
    }
    else // FullScreenOn == false
    {
        unsigned int windowStyle;
        NSRect       contentRect;
        
        
        StartingWindow = [NSApp keyWindow];
        windowStyle    = NSBorderlessWindowMask; 
        contentRect    = [[NSScreen mainScreen] frame];
        FullScreenWindow = [[NSFullScreenWindow alloc] initWithContentRect:contentRect styleMask: windowStyle backing:NSBackingStoreBuffered defer: NO];
        if(FullScreenWindow != nil)
        {
            NSLog(@"Window was created");			
            [FullScreenWindow setTitle: @"myWindow"];			
            [FullScreenWindow setReleasedWhenClosed: YES];   // was YES....
            [FullScreenWindow setLevel: NSScreenSaverWindowLevel - 1]; //];
            [FullScreenWindow setBackgroundColor:[NSColor blackColor]];
            
            
            
            contentView = [[self window] contentView];
            [FullScreenWindow setContentView: contentView];
            
            [FullScreenWindow makeKeyAndOrderFront:self ];
            [FullScreenWindow makeFirstResponder:view];
            
            [FullScreenWindow setDelegate:self];
            [FullScreenWindow setWindowController: self];
            
            FullScreenOn = YES;
        }
    }
}

-(void) offFullscren
{
	if( FullScreenOn == YES ) [self fullScreenMenu:self];
}

-(void) LODsliderAction:(id) sender
{
    [view setLOD:[sender floatValue]];
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

-(void) updateVolumeData: (NSNotification*) note
{
	long i;
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		if( [note object] == pixList[ i])
		{
			[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes]];
		}
	}
}

-(void) updateBlendingImage
{
	Pixel_8			*alphaTable, *redTable, *greenTable, *blueTable;
	long			iwl, iww;

	[[blendingController imageView] colorTables:&alphaTable :&redTable :&greenTable :&blueTable];
	
	[view setBlendingCLUT :redTable :greenTable :blueTable];
	
	[[blendingController imageView] getWLWW: &iwl :&iww];
	[view setBlendingWLWW :iwl :iww];
}

- (void) movieRateSliderAction:(id) sender
{
	[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
}

- (void) moviePosSliderAction:(id) sender
{
	curMovieIndex = [moviePosSlider intValue];
	
	[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes]];
	[view movieBlendingChangeSource: curMovieIndex];
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
		[view movieBlendingChangeSource: curMovieIndex];
		
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

-(NSMutableArray*) pixList { return pixList[0];}

-(id) initWithPix:(NSMutableArray*) pix :(NSMutableArray*) f :(NSData*) vData :(ViewerController*) bC
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
	
	for( i = 0; i < 50; i++) undodata[ i] = 0L;
	
	curMovieIndex = 0;
	maxMovieIndex = 1;
	
    pixList[0] = pix;
	fileList  = f;
	volumeData[0] = vData;
	
	[fileList retain];
	
    DCMPix  *firstObject = [pixList[0] objectAtIndex:0];
    float sliceThickness = fabs( [firstObject sliceInterval]);  //fabs( [firstObject sliceLocation] - [[pixList objectAtIndex:1] sliceLocation]);
    
    if( sliceThickness == 0)
    {
		sliceThickness = [firstObject sliceThickness];
		
		testInterval = NO;
		
		if( sliceThickness > 0) NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval",nil),  NSLocalizedString(@"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		else
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval/thickness",nil), NSLocalizedString( @"Problems with slice thickness/interval to do a 3D reconstruction.",nil),NSLocalizedString( @"OK",nil), nil, nil);
			return 0L;
		}
    }
    
    // CHECK IMAGE SIZE
    for( i =0 ; i < [pixList[0] count]; i++)
    {
        if( [firstObject pwidth] != [[pixList[0] objectAtIndex:i] pwidth]) err = -1;
        if( [firstObject pheight] != [[pixList[0] objectAtIndex:i] pheight]) err = -1;
    }
    if( err)
    {
        NSRunCriticalAlertPanel( NSLocalizedString(@"Images size",nil), NSLocalizedString( @"These images don't have the same height and width to allow a 3D reconstruction...",nil), NSLocalizedString(@"OK",nil), nil, nil);
        return 0L;
    }
    
    // CHECK IMAGE SIZE
//	if( testInterval)
//	{
//		float prevLoc = [firstObject sliceLocation];
//		for( i = 1 ; i < [pixList count]; i++)
//		{
//			if( fabs( sliceThickness - fabs( [[pixList objectAtIndex:i] sliceLocation] - prevLoc)) > 0.1) err = -1;
//			prevLoc = [[pixList objectAtIndex:i] sliceLocation];
//		}
//		if( err)
//		{
//			if( NSRunCriticalAlertPanel( @"Slices location",  @"Slice thickness/interval is not exactly equal for all images. This could distord the 3D reconstruction...", @"Continue", @"Cancel", nil) != NSAlertDefaultReturn) return 0L;
//			err = 0;
//		}
//	}

	[pixList[0] retain];
	[volumeData[0] retain];
    self = [super initWithWindowNibName:@"MIP"];
    
    [[self window] setDelegate:self];
    
    err = [view setPixSource:pixList[0]: (float*)[volumeData[0] bytes]];
    if( err != 0)
    {
        [self dealloc];
        return 0L;
    }
    
	blendingController = bC;
	if( blendingController) // Blending! Activate image fusion
	{
		[view setBlendingPixSource: blendingController];
		
		[blendingSlider setEnabled:YES];
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
		
		[self updateBlendingImage];
	}
	
	curWLWWMenu = @"Other";
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(updateVolumeData:)
               name: @"updateVolumeData"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	curCLUTMenu = @"No CLUT";
	[curCLUTMenu retain];
	
    [nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	
	[nc addObserver: self
           selector: @selector(CLUTChanged:)
               name: @"CLUTChanged"
             object: nil];
	
	
	
	[[self window] performZoom:self];
	
    return self;
}

#define STATEDATABASE @"/3DSTATE/"

-(void) save3DState
{
	NSString		*path = [documentsDirectory() stringByAppendingString:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingFormat: @"MIP-%@", [[fileList objectAtIndex:0] stringForSorting]];
	
	NSMutableDictionary *dict = [view get3DStateDictionary];
	[dict setObject:curCLUTMenu forKey:@"CLUTName"];
	[dict writeToFile:str atomically:YES];
}

-(void) load3DState
{
	NSString		*path = [documentsDirectory() stringByAppendingString:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingFormat: @"MIP-%@", [[fileList objectAtIndex:0] stringForSorting]];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
	[view set3DStateDictionary:dict];
	[self ApplyCLUTString:[dict objectForKey:@"CLUTName"]];
}

- (void) applyScissor : (NSArray*) object
{
	long		x, i				= [[object objectAtIndex: 0] intValue];
	long		stackOrientation	= [[object objectAtIndex: 1] intValue];
	long		c					= [[object objectAtIndex: 2] intValue];
	ROI*		roi					= [object objectAtIndex: 3];
	
	for( x = 0; x < maxMovieIndex; x++)
	{
		switch( stackOrientation)
		{
			case 2:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: i] fillROI: roi :-1000 :-999999 :999999 :YES :2 :i];
				else [[pixList[ x] objectAtIndex: i] fillROI: roi :-1000 :-999999 :999999 :NO :2 :i];
			break;
			
			case 1:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: 0] fillROI: roi :-1000 :-999999 :999999 :YES :1 :i];
				else [[pixList[ x] objectAtIndex: 0] fillROI: roi :-1000 :-999999 :999999 :NO :1 :i];
			break;
			
			case 0:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: 0] fillROI: roi :-1000 :-999999 :999999 :YES :0 : i];
				else [[pixList[ x] objectAtIndex: 0] fillROI: roi :-1000 :-999999 :999999 :NO :0 :i];
			break;
		}
	}
}

- (void) prepareUndo
{
	long i;
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
		float*	data = (float*) [volumeData[ i] bytes];
		long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( float);
		
		if( undodata[ i] == 0L)
		{
			undodata[ i] = (float*) malloc( memSize);
		}
		
		if( undodata[ i])
		{
			BlockMoveData( data, undodata[ i], memSize);
		}
		else NSLog(@"Undo failed... not enough memory");
	}
}

- (IBAction) undo:(id) sender
{
	long i;
	
	NSLog(@"undo");
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		if( undodata[ i])
		{
			DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
			float*	data = (float*) [volumeData[ i] bytes];
			long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( float);
			float*	cpy = data;
			
			BlockMoveData( undodata[ i], data, memSize);
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ i] userInfo: 0];
	}
}

-(void) dealloc
{
	long i;
	
    NSLog(@"Dealloc MIPController");
	
	// Release Undo system
	for( i = 0; i < maxMovieIndex; i++)
	{
		DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
		
		if( undodata[ i])
		{
			free( undodata[ i]);
		}
	}
	
	[self save3DState];
	
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
	[fileList release];
	for( i = 0; i < maxMovieIndex; i++)
	{
		[pixList[ i] release];
		[volumeData[ i] release];
	}
	[curCLUTMenu release];
	
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{	
    [[self window] setDelegate:nil];
    
    [self release];
}

-(NSMatrix*) toolsMatrix
{
	return toolsMatrix;
}

-(void) setDefaultTool:(id) sender
{
    id          theCell = [sender selectedCell];
    
    if( [theCell tag] >= 0)
    {
        [view setCurrentTool: [theCell tag]];
    }
}

- (void)deleteWLWW:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if( returnCode == 1)
    {
        [presetsDict removeObjectForKey:contextInfo];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
    }
}

- (void) setWLWW:(long) iwl :(long) iww
{
	[view setWLWW: iwl : iww];
}

- (void) getWLWW:(long*) iwl :(long*) iww
{
	[view getWLWW: iwl : iww];
}

- (void) ApplyWLWW:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet(NSLocalizedString (@"Delete a WL/WW preset",nil),NSLocalizedString( @"Delete",nil),NSLocalizedString( @"Cancel",nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete preset : '%@'", [sender title]]);
    }
    else
    {
		if( [[sender title] isEqualToString:@"Other"] == YES)
		{
			//[imageView setWLWW:0 :0];
		}
		else if( [[sender title] isEqualToString:@"Default WL & WW"] == YES)
		{
			[view setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		}
		else if( [[sender title] isEqualToString:@"Full dynamic"] == YES)
		{
			[view setWLWW:0 :0];
		}
		else
		{
			long long   wlwwlong;
			long       *wlww = (long*) &wlwwlong;
			NSNumber    *value;
			
			value = [presetsDict objectForKey:[sender title]];
			wlwwlong = [value longLongValue];
			
			[view setWLWW:wlww[0] :wlww[1]];
		}
		[[[wlwwPopup menu] itemAtIndex:0] setTitle:[sender title]];
    }
	
	curWLWWMenu = [sender title];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
}

-(IBAction) endNameWLWW:(id) sender
{
    long   *wlww;
    long long    wlwwlong;

    NSLog(@"endNameWLWW");
    
    wlww = (long*) &wlwwlong;
    wlww[0] = [wl intValue];
    wlww[1] = [ww intValue];
    if( wlww[1] == 0) wlww[1] = 1;

    [addWLWWWindow orderOut:sender];
    
    [NSApp endSheet:addWLWWWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
    //    wlww = &wlwwlong;
    //    [imageView getWLWW:&wlww[0] :&wlww[1]];
        
        [presetsDict setObject:[NSNumber numberWithLongLong:wlwwlong] forKey:[newName stringValue]];
		
		curWLWWMenu = [newName stringValue];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
    }
}

- (void) AddCurrentWLWW:(id) sender
{
    long   *wlww;
    long long    wlwwlong;
    
    wlww = (long*) &wlwwlong;
    [view getWLWW:&wlww[0] :&wlww[1]];
    
    [wl setStringValue:[NSString stringWithFormat:@"%d", wlww[0] ]];
    [ww setStringValue:[NSString stringWithFormat:@"%d", wlww[1] ]];
    
	[newName setStringValue: @"Unnamed"];
	
    [NSApp beginSheet: addWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)deleteCLUT:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if( returnCode == 1)
    {
		[clutDict removeObjectForKey:contextInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
    }
}

- (void) CLUTChanged: (NSNotification*) note
{
	unsigned char   r[256], g[256], b[256];
	
	[[note object] ConvertCLUT: r :g :b];

	[view setCLUT:r :g: b];
}

-(void) ApplyCLUTString:(NSString*) str
{
	if( str == 0L) return;

	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
	
	if( [str isEqualToString:@"No CLUT"] == YES)
	{
		[view setCLUT: 0L :0L :0L];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
		
		[[[clutPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		NSDictionary		*aCLUT;
		NSArray				*array;
		long				i;
		unsigned char		red[256], green[256], blue[256];
		
		aCLUT = [clutDict objectForKey:str];
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
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle: curCLUTMenu];
		}
	}
}

- (void) ApplyCLUT:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString (@"Remove a Color Look Up Table",nil), NSLocalizedString (@"Delete",nil), NSLocalizedString (@"Cancel",nil), nil, [self window], self, @selector(deleteCLUT:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete this CLUT : '%@'", [sender title]]);
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	}
	else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
    {
		NSDictionary		*aCLUT;
		NSArray				*array;
		long				i;
		unsigned char		red[256], green[256], blue[256];
		
		[self ApplyCLUTString:[sender title]];
		
		aCLUT = [clutDict objectForKey:curCLUTMenu];
		if( aCLUT)
		{
			if( [aCLUT objectForKey:@"Points"] != 0L)
			{
				[self clutAction:self];
				[clutName setStringValue: [sender title]];
				
				NSMutableArray	*pts = [clutView getPoints];
				NSMutableArray	*cols = [clutView getColors];
				
				[pts removeAllObjects];
				[cols removeAllObjects];
				
				[pts addObjectsFromArray: [aCLUT objectForKey:@"Points"]];
				[cols addObjectsFromArray: [aCLUT objectForKey:@"Colors"]];
				
				[NSApp beginSheet: addCLUTWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
				
				[clutView setNeedsDisplay:YES];
			}
			else
			{
				NSRunAlertPanel(NSLocalizedString(@"Error",nil),NSLocalizedString( @"Only CLUT created in OsiriX 1.3.1 or higher can be edited...",nil), nil, nil, nil);
			}
		}
	}
    else
    {
		[self ApplyCLUTString:[sender title]];
    }
}

-(IBAction) endCLUT:(id) sender
{
    [addCLUTWindow orderOut:sender];
    
    [NSApp endSheet:addCLUTWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		NSMutableDictionary *aCLUTFilter = [NSMutableDictionary dictionary];
		unsigned char		red[256], green[256], blue[256];
		long				i;
		
		[clutView ConvertCLUT: red: green: blue];
		
		NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < 256; i++) [rArray addObject: [NSNumber numberWithLong: red[ i]]];
		for( i = 0; i < 256; i++) [gArray addObject: [NSNumber numberWithLong: green[ i]]];
		for( i = 0; i < 256; i++) [bArray addObject: [NSNumber numberWithLong: blue[ i]]];
		
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];

		[aCLUTFilter setObject:[NSArray arrayWithArray:[[clutView getPoints] copy]] forKey:@"Points"];
		[aCLUTFilter setObject:[NSArray arrayWithArray:[[clutView getColors] copy]] forKey:@"Colors"];

		[clutDict setObject:aCLUTFilter forKey:[clutName stringValue]];
		
		// Apply it!
		
		[self ApplyCLUTString:[clutName stringValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
    }
	else
	{
		[self ApplyCLUTString:curCLUTMenu];
	}
}

- (IBAction) clutAction:(id)sender
{
long				i;
NSMutableArray		*array;

//	[view setCLUT:matrix :[[sizeMatrix selectedCell] tag] :[matrixNorm intValue]];
//	[imageView setIndex:[imageView curImage]];
}

- (IBAction) AddCLUT:(id) sender
{
	[self clutAction:self];
	[clutName setStringValue: @"Unnamed"];
	
    [NSApp beginSheet: addCLUTWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: MIPToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
    
//    [window makeKeyAndOrderFront:nil];
}

- (IBAction)customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];// autorelease];
    
    if ([itemIdent isEqual: QTExportVRToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export VR",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export VR",nil)];
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
        
	[toolbarItem setLabel:NSLocalizedString( @"Email",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Email",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Email this image",nil)];
	[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(sendMail:)];
    }
	else if ([itemIdent isEqual: QTExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel:NSLocalizedString( @"Export",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Export",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Export this series in a Quicktime file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime3D:)];
    }
	else if ([itemIdent isEqual: PerspectiveToolbarItemIdentifier]) {
     // Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Perspective",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Perspective",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Perspective Properties",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: perspectiveView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([perspectiveView frame]), NSHeight([perspectiveView frame]))];
    }
	else if ([itemIdent isEqual: ResetToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Reset to initial 3D view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(resetImage:)];
    }
	else if ([itemIdent isEqual: RevertToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Revert",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Revert",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Revert series by re-loading images from disk",nil)];
		[toolbarItem setImage: [NSImage imageNamed: RevertToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(revertSeries:)];
	}
	else if ([itemIdent isEqual: iPhotoToolbarItemIdentifier]) {
        
	[toolbarItem setLabel:NSLocalizedString( @"iPhoto",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"iPhoto",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series to iPhoto",nil)];
	[toolbarItem setImage: [NSImage imageNamed: iPhotoToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(export2iPhoto:)];
    }
	else if ([itemIdent isEqual: ExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"DICOM File",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Save as DICOM",nil)];
	[toolbarItem setToolTip:NSLocalizedString( @"Export this image in a DICOM file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportDICOM:)];
    }
	else if ([itemIdent isEqual: CroppingToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Crop",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Cropping Cube",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Show and manipulate cropping cube",nil)];
	[toolbarItem setImage: [NSImage imageNamed: CroppingToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(showCropCube:)];
    }
	else if ([itemIdent isEqual: AxToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Axial",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Axial",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Move to an axial view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: AxToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(axView:)];
    }
	else if ([itemIdent isEqual: SaToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Sagittal",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Sagittal",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Move to an sagittal view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: SaToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(saView:)];
    }
	else if ([itemIdent isEqual: CoToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Coronal",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Coronal",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Move to an coronal view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: CoToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(coView:)];
    }
	else if ([itemIdent isEqual: CaptureToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Best",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Best Rendering",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Render this image at the best resolution",nil)];
	[toolbarItem setImage: [NSImage imageNamed: CaptureToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(bestRendering:)];
    }
	else if([itemIdent isEqual: MovieToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Movie",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Movie",nil)];
	[toolbarItem setToolTip:NSLocalizedString( @"Movie Controller",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: movieView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
    }
    else if([itemIdent isEqual: WLWWToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"WL/WW Presets",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"WL/WW Presets",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the WL/WW to a preset value",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: WLWWView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
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
	else if([itemIdent isEqual: LODToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Level of Detail",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Level of Detail",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change Level of Detail",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: LODView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([LODView frame]), NSHeight([LODView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([LODView frame]), NSHeight([LODView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
     else if([itemIdent isEqual: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
	[toolbarItem setToolTip:NSLocalizedString( @"Change the mouse function",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
	else {
	// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
	// Returning nil will inform the toolbar this kind of item is not supported 
	toolbarItem = nil;
    }
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
                                            WLWWToolbarItemIdentifier,
											LODToolbarItemIdentifier,
											CaptureToolbarItemIdentifier,
											CroppingToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											PerspectiveToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											QTExportToolbarItemIdentifier,
											QTExportVRToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											MailToolbarItemIdentifier,
											ResetToolbarItemIdentifier,
											RevertToolbarItemIdentifier,
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
										LODToolbarItemIdentifier,
										CaptureToolbarItemIdentifier,
										CroppingToolbarItemIdentifier,
										QTExportToolbarItemIdentifier,
										PerspectiveToolbarItemIdentifier,
										iPhotoToolbarItemIdentifier,
										QTExportVRToolbarItemIdentifier,
										MailToolbarItemIdentifier,
										AxToolbarItemIdentifier,
										CoToolbarItemIdentifier,
										SaToolbarItemIdentifier,
										StereoIdentifier,
                                        ToolsToolbarItemIdentifier,
										BlendingToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
										ResetToolbarItemIdentifier,
										RevertToolbarItemIdentifier,
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
	
	if ([[toolbarItem itemIdentifier] isEqual: MovieToolbarItemIdentifier])
    {
        if(maxMovieIndex == 1) enable = NO;
    }
	
    return enable;
}

-(void) sendMail:(id) sender
{
	NSImage *im = [view nsimage:NO];
	
	[self sendMailImage: im];
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
	
	if( [panel runModalForDirectory:0L file:@"3D MIP Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
		[im release];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if( OPENVIEWER) [ws openFile:[panel filename]];
	}
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"tif"];
	
	if( [panel runModalForDirectory:0L file:@"3D MIP Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
		
		[im release];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if( OPENVIEWER) [ws openFile:[panel filename]];
	}
}

@end
