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




#import "MPR2DController.h"
#import "MPR2DView.h"
#import "DCMView.h"
#import "NSFullScreenWindow.h"
#import "WaitRendering.h"
#import "Papyrus3/Papyrus3.h"
#import "BrowserController.h"
#include <Accelerate/Accelerate.h>
#import "QuicktimeExport.h"
#import "iPhoto.h"
#import "DICOMExport.h"
#import "DicomImage.h"

extern "C"
{
extern BrowserController *browserWindow;
extern NSString * documentsDirectory();
extern NSString* convertDICOM( NSString *inputfile);
}

static	BOOL EXPORT2IPHOTO = NO;

static NSString* 	MPRToolbarIdentifier            = @"MPR Toolbar Identifier";
static NSString*	QTExportToolbarItemIdentifier 	= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier 	= @"iPhoto";
static NSString*	ToolsToolbarItemIdentifier		= @"Tools";
static NSString*	ThickSlabToolbarItemIdentifier  = @"ThickSlab";
static NSString*	WLWWToolbarItemIdentifier		= @"WLWW";
static NSString*	BlendingToolbarItemIdentifier   = @"2DBlending";
static NSString*	OrientationToolbarItemIdentifier	= @"Orientation";
//static NSString*	AxToolbarItemIdentifier			= @"Axial.tif";
//static NSString*	SaToolbarItemIdentifier			= @"Sag.tif";
//static NSString*	CoToolbarItemIdentifier			= @"Cor.tif";
static NSString*	MovieToolbarItemIdentifier		= @"Movie";
static NSString*	ExportToolbarItemIdentifier		= @"Export.icns";
static NSString*	MailToolbarItemIdentifier		= @"Mail.icns";

static		float				deg2rad = 3.14159265358979/180.0; 

extern NSString * documentsDirectory();

@implementation MPR2DController

- (IBAction) roiDeleteAll:(id) sender
{
	[viewerController roiDeleteAll: sender];
}

-(NSImage*) image4DForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	long oldValue = curMovieIndex;
	
	if( [cur intValue] != -1)
	{
		curMovieIndex = [cur intValue];
		
		[originalView setDCM: pixList[curMovieIndex] :fileList :0L :0 :'i' :NO];
		[originalView setFlippedData: [[viewerController imageView] flippedData]];
		[originalView setIndex: [originalView curImage]];
		
		[blendingController setMovieIndex: curMovieIndex];
		[viewerController setMovieIndex: curMovieIndex];
		[view movieChangeSource:(float*) [volumeData[ curMovieIndex] bytes]];
	}
	
	curMovieIndex = oldValue;
	
	return [view nsimage: NO];
}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [[quicktimeRotationView selectedCell] tag] == 0)
	{
		[view rotateOriginal: (float) ((float) [[quicktimeRotation selectedCell] tag]) / [max floatValue]];
	}
	else
	{
		[view rotatePerpendicular: (float) ((float) [[quicktimeRotation selectedCell] tag]) / [max floatValue]];
	}
	
	return [view nsimage: NO];
}

-(IBAction) endQuicktime:(id) sender
{
    [quicktimeWindow orderOut:sender];
    
    [NSApp endSheet:quicktimeWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		// ROTATION
		if( [quicktimeMode selectedRow] == 1)
		{
			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :[quicktimeFrames intValue]];
			
			[mov createMovieQTKit: YES  :EXPORT2IPHOTO :[[fileList objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
			
			[mov release];
		}
		
		// 4D
		if( [quicktimeMode selectedRow] == 0)
		{
			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(image4DForFrame: maxFrame:) :maxMovieIndex];
			
			[mov createMovieQTKit: YES  :EXPORT2IPHOTO :[[fileList objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
			
			[mov release];
		}
		
		if( EXPORT2IPHOTO)
		{
			iPhoto *ifoto = [[iPhoto alloc] init];
			[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"]]];
			[ifoto release];
		}
	}
}

- (void) exportQuicktime:(id) sender
{
	short selectItem = -1;
	
	if( [sender tag] == 1) EXPORT2IPHOTO = YES;
	else EXPORT2IPHOTO = NO;
	
	if( maxMovieIndex > 1) [[quicktimeMode cellAtRow:0 column:0] setEnabled:YES];
	else [[quicktimeMode cellAtRow:0 column:0] setEnabled:NO];
	
	[NSApp beginSheet: quicktimeWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(MPR2DView*) MPR2Dview { return view;}

-(NSSlider*) slider
{
	return slider;
}

- (void)adjustSlider
{
	NSLog(@"adjustSlider");
	
	if( [[viewerController imageView] flippedData]) [slider setIntValue: [pixList[ curMovieIndex] count] -1 -[originalView curImage]];
	else [slider setIntValue: [originalView curImage]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

- (void) setSliderValue:(int) i
{
	if( [[viewerController imageView] flippedData]) [slider setIntValue: [pixList[ curMovieIndex] count] -1 -i];
	else [slider setIntValue: i];
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
	
    i = [[OpacityPopup menu] numberOfItems];
    while(i-- > 0) [[OpacityPopup menu] removeItemAtIndex:0];
	
    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
	[[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[OpacityPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyOpacity:) keyEquivalent:@""];
    }
    [[OpacityPopup menu] addItem: [NSMenuItem separatorItem]];
    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Add an Opacity Table", nil) action:@selector (AddOpacity:) keyEquivalent:@""];

	[[[OpacityPopup menu] itemAtIndex:0] setTitle:curOpacityMenu];
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
    
    [[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Other", nil) action:nil keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Other", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Default WL & WW", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Full dynamic", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[wlwwPopup menu] addItemWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector (ApplyWLWW:) keyEquivalent:@""];
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

-(void) updateBlendingImage
{
	Pixel_8			*alphaTable, *redTable, *greenTable, *blueTable;
	float			iwl, iww;

	[[blendingController imageView] colorTables:&alphaTable :&redTable :&greenTable :&blueTable];
	
	[view setBlendingCLUT :redTable :greenTable :blueTable];
	[view setBlendingFactor: [blendingSlider floatValue]];
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
	
	[originalView setDCM:pixList[curMovieIndex] :fileList :0L :0 :'i' :NO];
	[originalView setFlippedData: [[viewerController imageView] flippedData]];
	[originalView setIndex:[originalView curImage]];
	
	[blendingController setMovieIndex: curMovieIndex];
	[viewerController setMovieIndex: curMovieIndex];
	[view movieChangeSource:(float*) [volumeData[ curMovieIndex] bytes]];
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
		
		[moviePosSlider setIntValue: curMovieIndex];
		
		[originalView setDCM:pixList[curMovieIndex] :fileList :0L :0 :'i' :NO];
		[originalView setFlippedData: [[viewerController imageView] flippedData]];
		[originalView setIndex:[originalView curImage]];
		
		[blendingController setMovieIndex: curMovieIndex];
		[viewerController setMovieIndex: curMovieIndex];
		[view movieChangeSource:(float*) [volumeData[ curMovieIndex] bytes]];
		
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

- (BOOL) is2DViewer
{
	return NO;
}

-(NSArray*) pixList { return pixList[0];}

- (void) updateOrientationMatrix
{
	[orientationMatrix selectCellWithTag:[viewerController currentOrientationTool]];
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
	
	movieTimer = 0L;
	blendingController = 0L;
	viewerController = 0L;
	curMovieIndex = 0;
	maxMovieIndex = 1;
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	exportDCM = 0L;
	
    DCMPix  *firstObject	= [pix objectAtIndex:0];
    float   sliceThickness  = fabs( [firstObject sliceInterval]);   //fabs( [firstObject sliceLocation] - [[pix objectAtIndex:1] sliceLocation]);
    
    if( sliceThickness == 0)
    {
		sliceThickness = [firstObject sliceThickness];
		
        testInterval = NO;
		
		if( sliceThickness > 0) NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval",nil), NSLocalizedString( @"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil), NSLocalizedString(@"OK",nil), nil, nil);
		else
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval/thickness",nil),  NSLocalizedString(@"Problems with slice thickness/interval to do a 3D reconstruction.",nil), NSLocalizedString(@"OK",nil), nil, nil);
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
        NSRunCriticalAlertPanel(NSLocalizedString( @"Images size",nil), NSLocalizedString( @"These images don't have the same height and width to allow a 3D reconstruction...",nil),NSLocalizedString( @"OK",nil), nil, nil);
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
	
	viewerController = [vC retain];
	
	fileList = files;
	[fileList retain];
	
	pixList[0] = pix;
	[pixList[0] retain];
	
	volumeData[0] = vData;
	[volumeData[0] retain];
    self = [super initWithWindowNibName:@"MPR2D"];
    
    [[self window] setDelegate:self];
    
	WaitRendering *splash = [[WaitRendering alloc] init:NSLocalizedString(@"Rendering...", nil)];
	[splash showWindow:self];

	[slider setMaxValue:[pixList[0] count]-1];
	[slider setNumberOfTickMarks:[pixList[0] count]];
	[slider setIntValue:[pixList[0] count]/2];
	
	[originalView setDCM:pixList[0] :files :0L :[pixList[0] count]/2 :'i' :YES];
	[originalView setFlippedData: [[viewerController imageView] flippedData]];
	[originalView setStringID:@"Original"];
	
	[view setOrientationVector: [vC orientationVector]];
    err = [view setPixSource:pixList[0] :files :(float*) [volumeData[0] bytes]];
    if( err != 0)
    {
       // [self dealloc];
        return 0L;
    }
	

	
	[movieRateSlider setEnabled: NO];
	[moviePosSlider setEnabled: NO];
	[moviePlayStop setEnabled:NO];
	
	blendingController = bC;
	if( blendingController) // Blending! Activate image fusion
	{
		[view setBlendingPixSource: blendingController];
		
		[blendingSlider setEnabled:YES];
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
		
		[self updateBlendingImage];
		
	//	[originalView setBlending: [blendingController imageView]];
	//	[originalView setIndex:0];
	//	[originalView blendingPropagate];
	}

	[splash close];
	[splash release];
	
	curOpacityMenu = [@"Linear Table" retain];
	
    [[NSNotificationCenter defaultCenter] addObserver: self
           selector: @selector(UpdateOpacityMenu:)
               name: @"UpdateOpacityMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
	
	curWLWWMenu = [NSLocalizedString(@"Other", 0L) retain];
	
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
           selector: @selector(CLUTChanged:)
               name: @"CLUTChanged"
             object: nil];
	
	[nc addObserver: self
			   selector: @selector(OpacityChanged:)
				   name: @"OpacityChanged"
				 object: nil];
	
	[nc	addObserver: self
					selector: @selector(CloseViewerNotification:)
					name: @"CloseViewerNotification"
					object: nil];

	[view axView:self];
//	[originalView axView:self];
//	[perpendicularView axView:self];
	
	[view setCurrentTool: tWL];
	[originalView setCurrentTool: tWL];
	
	[self updateOrientationMatrix];
	
	[[self window] setInitialFirstResponder: originalView];
	
    return self;
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC
{
	return [self initWithPix:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) bC :0L];
}

-(void) save3DState
{
	NSString		*path = [documentsDirectory() stringByAppendingPathComponent:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"MPR2D-%@", [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
	
	NSMutableDictionary *dict = [view get3DStateDictionary];
	[dict setObject:curCLUTMenu forKey:@"CLUTName"];
	[dict writeToFile:str atomically:YES];
}

-(void) load3DState
{
	NSString		*path = [documentsDirectory() stringByAppendingPathComponent:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"MPR2D-%@", [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
	
	[view set3DStateDictionary:dict];
	[self ApplyCLUTString: [dict objectForKey:@"CLUTName"]];
}

- (IBAction) resetImage:(id) sender
{
	[view set3DStateDictionary: 0L];
}

-(void) dealloc
{
	long i;
	
    NSLog(@"Dealloc MPR2DController A");
	[exportDCM release];
	
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
	
	NSLog(@"Dealloc MPR2DController B");
	
	[toolbar setDelegate: 0L];
	[toolbar release];
	
	[viewerController release];
	
	[super dealloc];
	NSLog(@"Dealloc MPR2DController C");
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
			[[self window] close];
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

    [[self window] setDelegate:nil];
    
    [self release];
}

-(DCMView*) originalView { return originalView;}

-(void) setDefaultTool:(id) sender
{
    id          theCell = [sender selectedCell];
    
    if( [theCell tag] >= 0)
    {
        [self setCurrentTool:[theCell tag]];
    }
}

- (void)setCurrentTool:(int)tool{
	if( tool >= 0)
    {
        [view setCurrentTool: tool];
		[originalView setCurrentTool: tool];
		[toolMatrix selectCellWithTag:tool];
    }
}


- (void) setWLWW:(float) iwl :(float) iww
{
	[view adjustWLWW: iwl : iww :@"set"];
}

- (void) getWLWW:(float*) iwl :(float*) iww
{
	[view getWLWW: iwl : iww];
}

- (IBAction) updateImage:(id) sender
{
	float iwl, iww;
	
	[originalView getWLWW: &iwl  :&iww];
	[view adjustWLWW: iwl : iww :@"set"];
}

- (void) ApplyWLWW:(id) sender
{
	NSString *menuString = [sender title];
	
	if( [menuString isEqualToString:NSLocalizedString(@"Other", 0L)] == YES)
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", 0L)] == YES)
	{
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", 0L)] == YES)
	{
	}
	else
	{
		menuString = [menuString substringFromIndex: 4];
	}
	
	[self applyWLWWForString: menuString];
		
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
}

- (void)applyWLWWForString:(NSString *) menuString
{
	if( [menuString isEqualToString:NSLocalizedString(@"Other", 0L)] == YES)
	{
		//[imageView setWLWW:0 :0];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", 0L)] == YES)
	{
		[view adjustWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW] :@"set"];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", 0L)] == YES)
	{
		[view adjustWLWW:0 :0 :@"set"];
	}
	else
	{
		if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
		{
			NSBeginAlertSheet(NSLocalizedString ( @"Delete a WL/WW preset",nil),NSLocalizedString ( @"Delete",nil),NSLocalizedString ( @"Cancel",nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [menuString retain], [NSString stringWithFormat:@"Are you sure you want to delete preset : '%@'?", menuString]);
		}
		else
		{
			NSArray		*value;
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey: menuString];
		
			[view adjustWLWW:[[value objectAtIndex: 0] floatValue] :[[value objectAtIndex: 1] floatValue] : @"set"];
		}
	}
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:menuString];
		
	if( ![menuString isEqualToString: curWLWWMenu])
	{
		[curWLWWMenu release];
		curWLWWMenu = [menuString retain];
	}
}


- (void) AddCurrentWLWW:(id) sender
{
	float iwl, iww;
    
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
		if( curCLUTMenu != str)
		{
			[curCLUTMenu release];
			curCLUTMenu = [str retain];
		}
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
			if( curCLUTMenu != str)
			{
				[curCLUTMenu release];
				curCLUTMenu = [str retain];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle:str];
		}
	}
}

- (void) OpacityChanged: (NSNotification*) note
{
	[view setOpacity:[[note object] getPoints]];
}

-(void) ApplyOpacityString:(NSString*) str
{
	NSDictionary		*aOpacity;
	NSArray				*array;
	long				i;
	
	if( [str isEqualToString:@"Linear Table"])
	{
		[view setOpacity:[NSArray array]];
		
		if( curOpacityMenu != str)
		{
			[curOpacityMenu release];
			curOpacityMenu = [str retain];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if( aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			[view setOpacity:array];
			if( curOpacityMenu != str)
			{
				[curOpacityMenu release];
				curOpacityMenu = [str retain];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
		}
	}
}

- (IBAction) AddOpacity:(id) sender
{
	NSDictionary		*aCLUT;
	NSArray				*array;
	long				i;
	unsigned char		red[256], green[256], blue[256];

	aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: curCLUTMenu];
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
		
		[OpacityView setCurrentCLUT:red :green: blue];
	}
	
	[OpacityName setStringValue: @"Unnamed"];
	
    [NSApp beginSheet: addOpacityWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) scrollWheel:(NSEvent *)theEvent
{
	float		inc;
	
	if( [theEvent deltaY] > 0) inc = 2;
	else inc = -2;
	
	[view scrollWheelInt: (float) inc : (long) 1L];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

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
    
    if ([itemIdent isEqual: QTExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else if ([itemIdent isEqual: iPhotoToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"iPhoto",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Export this series to iPhoto",nil)];
	
	[toolbarItem setView: iPhotoView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
    }
	else if ([itemIdent isEqual: MailToolbarItemIdentifier]) {
        
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
    else if([itemIdent isEqual: WLWWToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"WL/WW & CLUT",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Modify WL/WW & CLUT",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: WLWWView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
//	else if ([itemIdent isEqual: AxToolbarItemIdentifier]) {
//	
//	[toolbarItem setLabel: @"Axial"];
//	[toolbarItem setPaletteLabel: @"Axial"];
//        [toolbarItem setToolTip: @"Move to an axial view"];
//	[toolbarItem setImage: [NSImage imageNamed: AxToolbarItemIdentifier]];
//	[toolbarItem setTarget: view];
//	[toolbarItem setAction: @selector(axView:)];
//    }
//	else if ([itemIdent isEqual: SaToolbarItemIdentifier]) {
//	
//	[toolbarItem setLabel: @"Sagittal"];
//	[toolbarItem setPaletteLabel: @"Sagittal"];
//        [toolbarItem setToolTip: @"Move to an sagittal view"];
//	[toolbarItem setImage: [NSImage imageNamed: SaToolbarItemIdentifier]];
//	[toolbarItem setTarget: view];
//	[toolbarItem setAction: @selector(saView:)];
//    }
//	else if ([itemIdent isEqual: CoToolbarItemIdentifier]) {
//	
//	[toolbarItem setLabel: @"Coronal"];
//	[toolbarItem setPaletteLabel: @"Coronal"];
//        [toolbarItem setToolTip: @"Move to an coronal view"];
//	[toolbarItem setImage: [NSImage imageNamed: CoToolbarItemIdentifier]];
//	[toolbarItem setTarget: view];
//	[toolbarItem setAction: @selector(coView:)];
//    }
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
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]), NSHeight([ThickSlabView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([ThickSlabView frame]) + 100, NSHeight([ThickSlabView frame]))];
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
	else if([itemIdent isEqual: MovieToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"4D Player",nil)];
	[toolbarItem setToolTip:NSLocalizedString( @"4D Player",nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: movieView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
    }
	else if([itemIdent isEqualToString: OrientationToolbarItemIdentifier])
	 {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Orientation", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientation", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Orientation", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: orientationView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([orientationView frame]), NSHeight([orientationView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([orientationView frame]), NSHeight([orientationView frame]))];
	}
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
											OrientationToolbarItemIdentifier,
											BlendingToolbarItemIdentifier,
											ThickSlabToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
                                            NSToolbarFlexibleSpaceItemIdentifier, 
											QTExportToolbarItemIdentifier,
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
										ThickSlabToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
                                        ToolsToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
										QTExportToolbarItemIdentifier,
										iPhotoToolbarItemIdentifier,
										MailToolbarItemIdentifier,
										OrientationToolbarItemIdentifier,
							//			AxToolbarItemIdentifier,
							//			SaToolbarItemIdentifier,
							//			CoToolbarItemIdentifier,
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


- (void) exportDICOMFile:(id) sender
{
	BOOL export4DData = NO;
	
	if( maxMovieIndex > 1)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Export", nil), NSLocalizedString(@"Should I export the temporal series or only the current image?", nil), NSLocalizedString(@"Current Image", nil), NSLocalizedString(@"Temporal Series", nil), 0L) == NSAlertDefaultReturn)
		{
			export4DData = NO;
		}
		else export4DData = YES;
	}
	
	if( export4DData)
	{
		long	annotCopy = [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
		long	i, width, height, spp, bpp, err = 0;
		float	cwl, cww;
		float	o[ 9], pos[ 3];
		
		[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
		[DCMView setDefaults];
		
		DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
		
		[dcmSequence setSeriesNumber:6870 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
		[dcmSequence setSeriesDescription:@"4D MPR - 2D"];
		[dcmSequence setSourceFile: [[fileList objectAtIndex:0] valueForKey:@"completePath"]];
		
		for( i = 0; i < maxMovieIndex; i++)
		{
			NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
			
			curMovieIndex = i;
			
			[originalView setDCM: pixList[curMovieIndex] :fileList :0L :0 :'i' :NO];
			[originalView setFlippedData: [[viewerController imageView] flippedData]];
			[originalView setIndex: [originalView curImage]];
			
			[blendingController setMovieIndex: curMovieIndex];
			[viewerController setMovieIndex: curMovieIndex];
			[view movieChangeSource:(float*) [volumeData[ curMovieIndex] bytes]];
			
			float imOrigin[ 3], imSpacing[ 2];
			unsigned char *data = [[view finalView] getRawPixelsWidth:&width height:&height spp:&spp bpp:&bpp screenCapture:YES force8bits:NO removeGraphical:YES squarePixels:YES allTiles:NO allowSmartCropping:YES origin: imOrigin spacing: imSpacing];
						
			if( data)
			{
				[dcmSequence setPixelData: data samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				[dcmSequence setPixelSpacing: imSpacing[ 0] :imSpacing[ 1]];
				[exportDCM setSliceThickness: imSpacing[ 0]];
				
//				[[view finalView] orientationCorrectedToView: o];	// <- Because we do screen capture !!!!! We need to apply the rotation of the image
//				[exportDCM setOrientation: o];
//				
//				NSPoint tempPt = [[view finalView] ConvertFromUpLeftView2GL: NSMakePoint( 0, 0)];				// <- Because we do screen capture !!!!!
//				[[[view finalView] curDCM] convertPixX: tempPt.x pixY: tempPt.y toDICOMCoords: o pixelCenter: YES];
//				[exportDCM setPosition: o];
				
				if( fabs( o[6]) > fabs(o[7]) && fabs( o[6]) > fabs(o[8])) [exportDCM setSlicePosition: pos[ 0]];
				if( fabs( o[7]) > fabs(o[6]) && fabs( o[7]) > fabs(o[8])) [exportDCM setSlicePosition: pos[ 1]];
				if( fabs( o[8]) > fabs(o[6]) && fabs( o[8]) > fabs(o[7])) [exportDCM setSlicePosition: pos[ 2]];

				[[view finalView] getWLWW:&cwl :&cww];
				[dcmSequence setDefaultWWWL: (long) cww : (long) cwl];
				
				err = [dcmSequence writeDCMFile: 0L];
				free( data);
			}
			
			[pool release];
		}
		
		[dcmSequence release];
		
		if( err)  NSRunCriticalAlertPanel( NSLocalizedString(@"Error", 0L),  NSLocalizedString( @"Error during the creation of the DICOM File!", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
		
		[[NSUserDefaults standardUserDefaults] setInteger: annotCopy forKey: @"ANNOTATIONS"];
	}
	else
	{
		long	annotCopy = [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
		long	width, height, spp, bpp, err;
		float	cwl, cww;
		float	o[ 9], pos[ 3];
				
		
		[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
		[DCMView setDefaults];
		
		if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
		
		float imOrigin[ 3], imSpacing[ 2];
		unsigned char *data = [[view finalView] getRawPixelsWidth:&width height:&height spp:&spp bpp:&bpp screenCapture:YES force8bits:NO removeGraphical:YES squarePixels:YES allTiles:NO allowSmartCropping:YES origin: imOrigin spacing: imSpacing];

		
		if( data)
		{
			if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
			
			[exportDCM setSourceFile: [[fileList objectAtIndex:0] valueForKey:@"completePath"]];
			[exportDCM setSeriesDescription:@"MPR-2D"];
			[exportDCM setSeriesNumber:5400];
			[exportDCM setPixelData: data samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
			[exportDCM setPixelSpacing: imSpacing[ 0] :imSpacing[ 1]];
			[exportDCM setSliceThickness: imSpacing[ 0]];
			
			//[[view finalView] orientationCorrectedToView: o];	// <- Because we do screen capture !!!!! We need to apply the rotation of the image
			//[exportDCM setOrientation: o];
			
			//NSPoint tempPt = [[view finalView] ConvertFromUpLeftView2GL: NSMakePoint( 0, 0)];				// <- Because we do screen capture !!!!!
			//[[[view finalView] curDCM] convertPixX: tempPt.x pixY: tempPt.y toDICOMCoords: o pixelCenter: YES];
			//[exportDCM setPosition: o];
			
			if( fabs( o[6]) > fabs(o[7]) && fabs( o[6]) > fabs(o[8])) [exportDCM setSlicePosition: pos[ 0]];
			if( fabs( o[7]) > fabs(o[6]) && fabs( o[7]) > fabs(o[8])) [exportDCM setSlicePosition: pos[ 1]];
			if( fabs( o[8]) > fabs(o[6]) && fabs( o[8]) > fabs(o[7])) [exportDCM setSlicePosition: pos[ 2]];
			
			[[view finalView] getWLWW:&cwl :&cww];
			[exportDCM setDefaultWWWL: (long) cww : (long) cwl];
			
			err = [exportDCM writeDCMFile: 0L];
			if( err)  NSRunCriticalAlertPanel( NSLocalizedString(@"Error", 0L),  NSLocalizedString( @"Error during the creation of the DICOM File!", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
			
			free( data);
		}
		
		[[NSUserDefaults standardUserDefaults] setInteger: annotCopy forKey: @"ANNOTATIONS"];
	}
}

-(void) sendMail:(id) sender
{
	NSImage *im = [view nsimage:NO];
	
	[self sendMailImage: im];
}

-(IBAction) export2iPhoto:(id) sender
{
	if( [sender tag] == 0)
	{
		iPhoto		*ifoto;
		NSImage		*im = [view nsimage:NO];
		
		NSArray		*representations;
		NSData		*bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
		
		ifoto = [[iPhoto alloc] init];
		[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
		[ifoto release];
	}
	else [self exportQuicktime: sender];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:0L file:@"2D MPR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
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
	
	if( [panel runModalForDirectory:0L file:@"2D MPR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
			[ws openFile:[panel filename]];
	}
}

- (ViewerController *)viewerController{
	return viewerController;
}

- (NSManagedObject *)currentStudy{
	return [viewerController currentStudy];
}
- (NSManagedObject *)currentSeries{
	return [viewerController currentSeries];
}

- (NSManagedObject *)currentImage{
	return [viewerController currentImage];
}

-(float)curWW{
	return [viewerController curWW];
}

-(float)curWL{
	return [viewerController curWL];
}
- (NSString *)curCLUTMenu{
	return curCLUTMenu;
}

- (void)bringToFrontROI:(ROI*)roi;{}
- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;{}

- (IBAction) setOrientationTool:(id)sender;
{
	[self close];
	[viewerController setOrientationToolFrom2DMPR:sender];
}

@end
