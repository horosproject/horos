/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "VRControllerVPRO.h"
#import "DCMView.h"
#import "dicomFile.h"
#import "NSFullScreenWindow.h"
#import "Papyrus3/Papyrus3.h"
#import "BrowserController.h"
#import "Accelerate.h"
#import "iPhoto.h"
#import "VRViewVPRO.h"

static NSString* 	MIPToolbarIdentifier				= @"VRPRO Toolbar Identifier";
static NSString*	QTExportToolbarItemIdentifier		= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier			= @"iPhoto.icns";
static NSString*	QTExportVRToolbarItemIdentifier		= @"QTExportVR.icns";
//static NSString*	StereoIdentifier					= @"Stereo.icns";
static NSString*	CaptureToolbarItemIdentifier		= @"Capture.icns";
static NSString*	CroppingToolbarItemIdentifier		= @"Cropping.icns";
static NSString*	OrientationToolbarItemIdentifier	= @"OrientationWidget.tiff";
static NSString*	AxToolbarItemIdentifier				= @"Axial.tif";
static NSString*	SaToolbarItemIdentifier				= @"Sag.tif";
static NSString*	SaOppositeToolbarItemIdentifier	= @"SagOpposite.tif";
static NSString*	CoToolbarItemIdentifier				= @"Cor.tif";
static NSString*	ToolsToolbarItemIdentifier			= @"Tools";
static NSString*	WLWWToolbarItemIdentifier			= @"WLWW";
//static NSString*	LODToolbarItemIdentifier			= @"LOD";
static NSString*	BlendingToolbarItemIdentifier		= @"2DBlending";
static NSString*	MovieToolbarItemIdentifier			= @"Movie";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	MailToolbarItemIdentifier			= @"Mail.icns";
static NSString*	ShadingToolbarItemIdentifier		= @"Shading";
static NSString*	EngineToolbarItemIdentifier			= @"Engine";
static NSString*	PerspectiveToolbarItemIdentifier	= @"Perspective";
static NSString*	ResetToolbarItemIdentifier			= @"Reset.tiff";
static NSString*	RevertToolbarItemIdentifier			= @"Revert.tiff";
static NSString*	FlyThruToolbarItemIdentifier		= @"FlyThru.tif";
static NSString*	ScissorStateToolbarItemIdentifier	= @"ScissorState";
static NSString*	ModeToolbarItemIdentifier			= @"Mode";


@implementation VRPROController

- (BOOL)is4D;
{
	return (maxMovieIndex > 1);
}

-(void) revertSeries:(id) sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"revertSeriesNotification" object: pixList[ curMovieIndex] userInfo: nil];
}

+(BOOL) available
{
	return YES;
}

+(BOOL) hardwareCheck
{
		// *****************************
	
	VLIStatus       status;
	
	status = VLIOpen();
	if ( status != kVLIOK )
	{
		NSRunCriticalAlertPanel( NSLocalizedString(@"VolumePRO Error", nil),  NSLocalizedString(@"This function requires a VolumePRO board, the VLI.framework, and the VolumePRO.kext files", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return NO;
	}
	VLIClose();
	
	// *****************************
	return YES;
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



-(void) LODsliderAction:(id) sender
{
    [view setLOD:[sender floatValue]];
}

- (void) windowDidLoad
{
    [self setupToolbar];
//	[self createContextualMenu];
}

-(ViewerController*) blendingController
{
	return blendingController;
}

-(ViewerController*) viewer2D
{
	return viewer2D;
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
	
	[[blendingController imageView] getWLWW: &iwl :&iww];
	[view setBlendingWLWW :iwl :iww];
}

-(long) movieFrames { return maxMovieIndex;}

- (void) setMovieFrame: (long) l
{
	curMovieIndex = l;
	
	[view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes]];
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

- (NSMutableArray*) pixList { return pixList[0];}
- (NSArray*) fileList { return fileList;}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC
{
	[self initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC mode:@"VR"];
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC mode:(NSString*) renderingMode
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
    DCMPix			*firstObject = [pix objectAtIndex:0];
	
	// MEMORY TEST: The renderer needs to have the volume in short
	{
		char	*testPtr = (char*) malloc( [firstObject pwidth] * [firstObject pheight] * [pix count] * sizeof( short) + 4UL * 1024UL * 1024UL);
		if( testPtr == nil)
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.",nil), NSLocalizedString(@"OK",nil), nil, nil);
			return nil;
		}
		else
		{
			free( testPtr);
		}
	}
	
	for( i = 0; i < 100; i++) undodata[ i] = nil;
	
	curMovieIndex = 0;
	maxMovieIndex = 1;
	
	fileList = f;
	[fileList retain];
	
	pixList[0] = pix;
	volumeData[0] = vData;
	
	_renderingMode = [renderingMode retain];
	
    float sliceThickness = fabs( [firstObject sliceInterval]);
	
	  //fabs( [firstObject sliceLocation] - [[pixList objectAtIndex:1] sliceLocation]);
    
    if( sliceThickness == 0)
    {
		sliceThickness = [firstObject sliceThickness];
		
		testInterval = NO;
		
		if( sliceThickness > 0) NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval", nil),  NSLocalizedString(@"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		else
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval/thickness", nil),  NSLocalizedString(@"Problems with slice thickness/interval to do a 3D reconstruction.", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return nil;
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
        NSRunCriticalAlertPanel( NSLocalizedString(@"Images size", nil),  NSLocalizedString(@"These images don't have the same height and width to allow a 3D reconstruction...", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return nil;
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
//			if( NSRunCriticalAlertPanel( @"Slices location",  @"Slice thickness/interval is not exactly equal for all images. This could distord the 3D reconstruction...", @"Continue", @"Cancel", nil) != NSAlertDefaultReturn) return nil;
//			err = 0;
//		}
//	}

	[pixList[0] retain];
	[volumeData[0] retain];
    self = [super initWithWindowNibName:@"VRVPRO"];
    
    [[self window] setDelegate:self];
    
    err = [view setPixSource:pixList[0] : (float*) [volumeData[0] bytes]];
    if( err != 0)
    {
        //[self dealloc];
        return nil;
    }
	
	blendingController = bC;
	blendingController = nil;	//BLENDING IS NOT AVAILABLE IN THIS VERSION - ANR
	if( blendingController) // Blending! Activate image fusion
	{
		[view setBlendingPixSource: blendingController];
		
		[blendingSlider setEnabled:YES];
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
		[self updateBlendingImage];
	}
	
	viewer2D = vC;
	
	curWLWWMenu = [NSLocalizedString(@"Other", nil) retain];
	
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
	
	[nc	addObserver: self
					selector: @selector(CloseViewerNotification:)
					name: @"CloseViewerNotification"
					object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: nil];
	
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	
    [nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: nil];
	
	curOpacityMenu = [NSLocalizedString(@"Linear Table", nil) retain];
	
    [nc addObserver: self
           selector: @selector(UpdateOpacityMenu:)
               name: @"UpdateOpacityMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
	
	[nc addObserver: self
           selector: @selector(CLUTChanged:)
               name: @"CLUTChanged"
             object: nil];
	
	//[[self window] performZoom:self];

	[movieRateSlider setEnabled: NO];
	[moviePosSlider setEnabled: NO];
	[moviePlayStop setEnabled: NO];
	
	
	[[enginePopup menu] setAutoenablesItems : NO];
//	[[[enginePopup menu] itemAtIndex: 3] setEnabled: NO];
	[[[enginePopup menu] itemAtIndex: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]+1] setState:NSOnState];
	
	[self updateEngine];
	
	[view updateScissorStateButtons];
	
	if( [renderingMode isEqualToString:@"MIP"])
		[self setModeIndex: 1];
	
    return self;
}

- (IBAction) roiDeleteAll:(id) sender
{
	[viewer2D roiDeleteAll: sender];
}

-(void) save3DState
{
	NSString		*path = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"VRVP-%@", [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
	
	NSMutableDictionary *dict = [view get3DStateDictionary];
	[dict setObject:curCLUTMenu forKey:@"CLUTName"];
	[dict setObject:curOpacityMenu forKey:@"OpacityName"];
	
	if( [viewer2D postprocessed] == NO)
		[dict writeToFile:str atomically:YES];
}

-(void) load3DState
{
	NSString		*path = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:STATEDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	NSString	*str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"VRVP-%@", [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
	
	if( [viewer2D postprocessed]) dict = nil;
	
	[view set3DStateDictionary:dict];
	
	if( [dict objectForKey:@"CLUTName"]) [self ApplyCLUTString:[dict objectForKey:@"CLUTName"]];
	else [self ApplyCLUTString:@"VR Muscles-Bones"];
	
	if( [dict objectForKey:@"CLUTName"]) [self ApplyOpacityString:[dict objectForKey:@"OpacityName"]];
	else [self ApplyOpacityString:NSLocalizedString(@"Logarithmic Inverse Table", nil)];
	
	if( [view shading]) [shadingCheck setState: NSOnState];
	else [shadingCheck setState: NSOffState];
	
	float ambient, diffuse, specular, specularpower;
	
	[view getShadingValues: &ambient :&diffuse :&specular :&specularpower];
	[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.1f\nDiffuse: %2.1f\nSpecular :%2.1f-%2.1f", ambient, diffuse, specular, specularpower]];
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
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: i] fillROI: roi newVal :-3000 minValue :-999999 maxValue :999999 outside :YES orientationStack :2 stackNo :i restore:NO addition:NO spline: NO];
				else [[pixList[ x] objectAtIndex: i] fillROI: roi newVal :-3000 minValue :-999999 maxValue :999999 outside :NO orientationStack :2 stackNo :i restore:NO addition:NO spline: NO];
				break;
				
			case 1:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: 0] fillROI: roi newVal :-3000 minValue :-999999 maxValue :999999 outside :YES orientationStack :1 stackNo :i restore:NO addition:NO spline: NO];
				else [[pixList[ x] objectAtIndex: 0] fillROI: roi newVal :-3000 minValue :-999999 maxValue :999999 outside :NO orientationStack :1 stackNo :i restore:NO addition:NO spline: NO];
				break;
				
			case 0:
				if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) [[pixList[ x] objectAtIndex: 0] fillROI: roi newVal :-3000 minValue :-999999 maxValue :999999 outside :YES orientationStack :0 stackNo :i restore:NO addition:NO spline: NO];
				else [[pixList[ x] objectAtIndex: 0] fillROI: roi newVal :-3000 minValue :-999999 maxValue :999999 outside :NO orientationStack :0 stackNo :i restore:NO addition:NO spline: NO];
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
		long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( short);
		
		if( undodata[ i] == nil)
		{
			undodata[ i] = (float*) malloc( memSize);
		}
		
		if( undodata[ i])
		{
			vImage_Buffer srcf, dst16;
			
			srcf.height = [firstObject pheight] * [pixList[ i] count];
			srcf.width = [firstObject pwidth];
			srcf.rowBytes = [firstObject pwidth] * sizeof(float);
			
			dst16.height = [firstObject pheight] * [pixList[ i] count];
			dst16.width = [firstObject pwidth];
			dst16.rowBytes = [firstObject pwidth] * sizeof(short);
			
			dst16.data = undodata[ i];
			srcf.data = data;
			
			vImageConvert_FTo16U( &srcf, &dst16, -[view offset], 1./[view valueFactor], 0);
			
//			memcpy( undodata[ i], data, memSize);
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
//			long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( float);
//			float*	cpy = data;
			
			vImage_Buffer src16, dstf;
			
			src16.height = [firstObject pheight] * [pixList[ i] count];
			src16.width = [firstObject pwidth];
			src16.rowBytes = [firstObject pwidth] * sizeof(short);
			
			dstf.height = [firstObject pheight] * [pixList[ i] count];
			dstf.width = [firstObject pwidth];
			dstf.rowBytes = [firstObject pwidth] * sizeof(float);
			
			dstf.data = data;
			src16.data = undodata[ i];
			
			vImageConvert_16UToF( &src16, &dstf, -[view offset], 1./[view valueFactor], 0);
			
			//BlockMoveData( undodata[ i], data, memSize);
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ i] userInfo: 0];
	}
}

//- (void) prepareUndo
//{
//	long i;
//	
//	for( i = 0; i < maxMovieIndex; i++)
//	{
//		DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
//		float*	data = (float*) [volumeData[ i] bytes];
//		long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( float);
//		
//		if( undodata[ i] == nil)
//		{
//			undodata[ i] = (float*) malloc( memSize);
//		}
//		
//		if( undodata[ i])
//		{
//			memcpy( undodata[ i], data, memSize);
//		}
//		else NSLog(@"Undo failed... not enough memory");
//	}
//}
//
//- (IBAction) undo:(id) sender
//{
//	long i;
//	
//	NSLog(@"undo");
//	
//	for( i = 0; i < maxMovieIndex; i++)
//	{
//		if( undodata[ i])
//		{
//			DCMPix  *firstObject = [pixList[ i] objectAtIndex:0];
//			float*	data = (float*) [volumeData[ i] bytes];
//			long	memSize = [firstObject pwidth] * [firstObject pheight] * [pixList[ i] count] * sizeof( float);
//			float*	cpy = data;
//			
//			BlockMoveData( undodata[ i], data, memSize);
//		}
//		
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ i] userInfo: 0];
//	}
//}

-(void) dealloc
{
	long i;
	
    NSLog(@"Dealloc VRController");
	
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
    
	for( i = 0; i < maxMovieIndex; i++)
	{
		[pixList[ i] release];
		[volumeData[ i] release];
	}
	[fileList release];
	
	[toolbar setDelegate: nil];
	[toolbar release];
	[_renderingMode release];
	
	[view prepareForRelease];
	
	[super dealloc];
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
	[[NSNotificationCenter defaultCenter] postNotificationName: @"Window3DClose" object: self userInfo: 0];
	
	if( movieTimer)
	{
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
	}
	
    [[self window] setDelegate:nil];
    
    [self autorelease];
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


- (void) setWLWW:(float) iwl :(float) iww
{
	[view setWLWW: iwl : iww];
}

- (void) getWLWW:(float*) iwl :(float*) iww
{
	[view getWLWW: iwl : iww];
}

- (void) ApplyWLWW:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Delete a WL/WW preset", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [[sender title] retain], [NSString stringWithFormat: NSLocalizedString( @"Are you sure you want to delete preset : '%@'?", nil), [sender title]]);
    }
    else
    {
		if( [[sender title] isEqualToString:NSLocalizedString(@"Other", nil)] == YES)
		{
			//[imageView setWLWW:0 :0];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Default WL & WW", nil)] == YES)
		{
			[view setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Full dynamic", nil)] == YES)
		{
			[view setWLWW:0 :0];
		}
		else
		{
			NSArray    *value;
			
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey: [sender title]];
			
			[view setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
		}
		[[[wlwwPopup menu] itemAtIndex:0] setTitle:[sender title]];
    }
	
	if( curWLWWMenu != [sender title])
	{
		[curWLWWMenu release];
		curWLWWMenu = [[sender title] retain];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: nil];
}

static float	savedambient, saveddiffuse, savedspecular, savedspecularpower;

- (IBAction) resetShading:(id) sender
{
	float ambient, diffuse, specular, specularpower;
	
	ambient = 0.2;
	diffuse = 0.8;
	specular = 0.6;
	specularpower = 10;
	
	[[shadingForm cellAtIndex: 0] setFloatValue: ambient];
	[[shadingForm cellAtIndex: 1] setFloatValue: diffuse];
	[[shadingForm cellAtIndex: 2] setFloatValue: specular];
	[[shadingForm cellAtIndex: 3] setFloatValue: specularpower];
	
	[self endShadingEditing: sender];
}

-(IBAction) endShadingEditing:(id) sender
{
    if( [sender tag])   //User clicks OK Button
    {
		float ambient, diffuse, specular, specularpower;

		ambient = [[shadingForm cellAtIndex: 0] floatValue];
		diffuse = [[shadingForm cellAtIndex: 1] floatValue];
		specular = [[shadingForm cellAtIndex: 2] floatValue];
		specularpower = [[shadingForm cellAtIndex: 3] floatValue];
		
		[view setShadingValues: ambient :diffuse :specular :specularpower];
		[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.2f\nDiffuse: %2.2f\nSpecular :%2.2f, %2.2f", ambient, diffuse, specular, specularpower]];
    }
	
	if( [sender tag] == 0)
	{
		[view setShadingValues: savedambient :saveddiffuse :savedspecular :savedspecularpower];
		[shadingValues setStringValue: [NSString stringWithFormat:@"Ambient: %2.2f\nDiffuse: %2.2f\nSpecular :%2.2f, %2.2f", savedambient, saveddiffuse, savedspecular, savedspecularpower]];
	}
	
	[view setNeedsDisplay: YES];
	
	if( [sender tag] == 2) return;
	
    [shadingEditWindow orderOut:sender];
    
    [NSApp endSheet:shadingEditWindow returnCode:[sender tag]];

}

- (IBAction) editShadingValues:(id) sender
{
	[view getShadingValues: &savedambient :&saveddiffuse :&savedspecular :&savedspecularpower];
	
//	[[shadingForm cellAtIndex: 0] setStringValue: [NSString stringWithFormat:@"%2.2f", savedambient]];
//	[[shadingForm cellAtIndex: 1] setStringValue: [NSString stringWithFormat:@"%2.2f", saveddiffuse]];
//	[[shadingForm cellAtIndex: 2] setStringValue: [NSString stringWithFormat:@"%2.2f", savedspecular]];
//	[[shadingForm cellAtIndex: 3] setStringValue: [NSString stringWithFormat:@"%2.2f", savedspecularpower]];

	[[shadingForm cellAtIndex: 0] setFloatValue: savedambient]; //[NSString stringWithFormat:@"%2.2f", savedambient]];
	[[shadingForm cellAtIndex: 1] setFloatValue: saveddiffuse]; //[NSString stringWithFormat:@"%2.2f", saveddiffuse]];
	[[shadingForm cellAtIndex: 2] setFloatValue: savedspecular]; //[NSString stringWithFormat:@"%2.2f", savedspecular]];
	[[shadingForm cellAtIndex: 3] setFloatValue: savedspecularpower];	//[NSString stringWithFormat:@"%2.2f", savedspecularpower]];
	
    [NSApp beginSheet: shadingEditWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (void) AddCurrentWLWW:(id) sender
{
	float iwl, iww;
	
    [view getWLWW:&iwl :&iww];
    
    [wl setStringValue:[NSString stringWithFormat:@"%.0f", iwl ]];
    [ww setStringValue:[NSString stringWithFormat:@"%.0f", iww ]];
    
	[newName setStringValue: NSLocalizedString(@"Unnamed", nil)];
	
    [NSApp beginSheet: addWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


-(void) ApplyCLUTString:(NSString*) str
{
	if( str == nil) return;
	
	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
	
	if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES)
	{
		[view setCLUT: nil :nil :nil];
		[view changeColorWith: [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: nil];
		
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
			
			if( [curCLUTMenu isEqualToString: NSLocalizedString( @"B/W Inverse", nil)] || [curCLUTMenu isEqualToString:( @"B/W Inverse")])
				[view changeColorWith: [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
			else 
				[view changeColorWith: [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
				
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: nil];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle: curCLUTMenu];
		}
	}
}




-(void) ApplyOpacityString:(NSString*) str
{
	NSDictionary		*aOpacity;
	NSArray				*array;
	long				i;
	
	if( str == nil) return;
	
	if( curOpacityMenu != str)
	{
		[curOpacityMenu release];
		curOpacityMenu = [str retain];
	}
	
	if( [str isEqualToString:@"Linear Table"])
	{
		[view setOpacity:[NSArray array]];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if( aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			[view setOpacity:array];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: nil];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle: curOpacityMenu];
		}
	}
}



- (void) updateEngine
{
	switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"])
	{
		case 0:	// RAY CAST
			[LODSlider setEnabled: YES];
		break;
		
		case 1:	// TEXTURE
			[LODSlider setEnabled: NO];
		break;
		
		case 2:
		
		break;
	}
}

- (IBAction) setModeIndex:(long) val
{
	[modeMatrix selectCellWithTag: val];
	[self setMode: modeMatrix];
}

- (IBAction) setMode:(id) sender
{
	[view setMode: [[sender selectedCell] tag]];
	
	if( [[sender selectedCell] tag] == 1)
	{
		[shadingCheck setEnabled : NO];
				[_renderingMode release];
		_renderingMode = [@"MIP" retain];
	}
	else
	{
		[_renderingMode release];
		_renderingMode = [@"VR" retain];
		[shadingCheck setEnabled : YES];
		[view switchShading: shadingCheck];
	}
}

- (IBAction) setEngine:(id) sender
{
	long i;
	
	for( i = 0 ; i < [[enginePopup menu] numberOfItems]; i++)
	{
		[[[enginePopup menu] itemAtIndex: i] setState: NSOffState];
	}
	
	[[enginePopup selectedItem] setState: NSOnState];

	[view setEngine: [[enginePopup selectedItem] tag]];
	[view setBlendingEngine: [[enginePopup selectedItem] tag]];
	
	[[NSUserDefaults standardUserDefaults] setInteger:[[enginePopup selectedItem] tag] forKey: @"MAPPERMODEVR"];
	
	[self updateEngine];
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
	
	[OpacityName setStringValue: NSLocalizedString(@"Unnamed", nil)];
	
    [NSApp beginSheet: addOpacityWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
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
	
	[toolbarItem setLabel: NSLocalizedString(@"Export VR", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export VR", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image in a Quicktime VR file", nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
    }
//	else if ([itemIdent isEqual: StereoIdentifier]) {
//        
//	[toolbarItem setLabel: @"Stereo"];
//	[toolbarItem setPaletteLabel: @"Stereo"];
//        [toolbarItem setToolTip: @"Switch Stereo Mode ON/OFF"];
//	[toolbarItem setImage: [NSImage imageNamed: StereoIdentifier]];
//	[toolbarItem setTarget: view];
//	[toolbarItem setAction: @selector(SwitchStereoMode:)];
//    }
	else if ([itemIdent isEqual: MailToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Email", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Email", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image", nil)];
	[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(sendMail:)];
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
	else if ([itemIdent isEqual: ShadingToolbarItemIdentifier]) {
     // Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Shading", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Shading", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Shading Properties", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: shadingView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([shadingView frame]), NSHeight([shadingView frame]))];
    }
	else if ([itemIdent isEqual: EngineToolbarItemIdentifier]) {
     // Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Engine", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Engine", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Engine Properties", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: engineView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
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
	else if ([itemIdent isEqual: QTExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Movie Export", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image in a Quicktime file", nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else if ([itemIdent isEqual: iPhotoToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"iPhoto", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image to iPhoto", nil)];
	[toolbarItem setImage: [NSImage imageNamed: iPhotoToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(export2iPhoto:)];
    }
	else if ([itemIdent isEqual: ExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"DICOM File", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Save as DICOM", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image in a DICOM file", nil)];
	[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
//	else if ([itemIdent isEqual: SendToolbarItemIdentifier]) {
//        
//	[toolbarItem setLabel: @"Send DICOM"];
//	[toolbarItem setPaletteLabel: @"Send DICOM"];
//        [toolbarItem setToolTip: @"Send this image to a DICOM node"];
//	[toolbarItem setImage: [NSImage imageNamed: SendToolbarItemIdentifier]];
//	[toolbarItem setTarget: self];
//	[toolbarItem setAction: @selector(exportDICOMPACS:)];
//    }
	else if ([itemIdent isEqual: CroppingToolbarItemIdentifier]) {
	
	[toolbarItem setLabel:NSLocalizedString( @"Crop", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Cropping Cube", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Show and manipulate cropping cube", nil)];
	[toolbarItem setImage: [NSImage imageNamed: CroppingToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(showCropCube:)];
    }
	else if ([itemIdent isEqualToString: OrientationToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Orientation",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientation Cube",nil)];
	[toolbarItem setToolTip:NSLocalizedString(@"Show orientation cube",nil)];
	[toolbarItem setImage: [NSImage imageNamed: OrientationToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(switchOrientationWidget:)];
    }
	else if ([itemIdent isEqual: AxToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Axial", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Axial", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Move to an axial view", nil)];
	[toolbarItem setImage: [NSImage imageNamed: AxToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(axView:)];
    }
	else if ([itemIdent isEqual: SaToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Sagittal", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Sagittal", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Move to an sagittal view", nil)];
	[toolbarItem setImage: [NSImage imageNamed: SaToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(saView:)];
    }
	else if ([itemIdent isEqual: SaOppositeToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Sagittal",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Sagittal",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Move to an sagittal view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: SaOppositeToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(saViewOpposite:)];
    }
	else if ([itemIdent isEqual: CoToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Coronal", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Coronal", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Move to an coronal view", nil)];
	[toolbarItem setImage: [NSImage imageNamed: CoToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(coView:)];
    }
	else if ([itemIdent isEqual: CaptureToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Best", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Best Rendering", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Render this image at the best resolution", nil)];
	[toolbarItem setImage: [NSImage imageNamed: CaptureToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(bestRendering:)];
    }
    else if([itemIdent isEqual: WLWWToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT & Opacity", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"WL/WW & CLUT & Opacity", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the WL/WW & CLUT & Opacity", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: WLWWView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
	else if([itemIdent isEqual: MovieToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"4D Player", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"4D Player", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"4D Player", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: movieView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
    }
	else if([itemIdent isEqual: ScissorStateToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"3D Scissor State", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Scissor State", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"3D Scissor State", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: scissorStateView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
    }
	else if([itemIdent isEqual: BlendingToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Fusion", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Fusion", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: BlendingView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
    }
	else if([itemIdent isEqualToString: ModeToolbarItemIdentifier]) {
		 // Set up the standard properties 
		 [toolbarItem setLabel:NSLocalizedString( @"Rendering Mode",nil)];
		 [toolbarItem setPaletteLabel:NSLocalizedString( @"Rendering Mode",nil)];
		 [toolbarItem setToolTip: NSLocalizedString(@"Rendering Mode",nil)];
		 
		 // Use a custom view, a text field, for the search item 
		 [toolbarItem setView: modeView];
		 [toolbarItem setMinSize:NSMakeSize(NSWidth([modeView frame]), NSHeight([modeView frame]))];
	 }
	 else if([itemIdent isEqual: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Mouse button function", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Change the mouse function", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
	else if([itemIdent isEqual: FlyThruToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fly Thru Set up",nil)];
	
	[toolbarItem setImage: [NSImage imageNamed: FlyThruToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(flyThruControllerInit:)];
	
    }
	else
		{
			[toolbarItem release];
			toolbarItem = nil;
		}
     return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
											ModeToolbarItemIdentifier,
                                            WLWWToolbarItemIdentifier,
								//			LODToolbarItemIdentifier,
								//			CaptureToolbarItemIdentifier,
											CroppingToolbarItemIdentifier,
											OrientationToolbarItemIdentifier,
											ShadingToolbarItemIdentifier,
											PerspectiveToolbarItemIdentifier,
								//			EngineToolbarItemIdentifier,
											
								//			BlendingToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											QTExportToolbarItemIdentifier,
											QTExportVRToolbarItemIdentifier,
											MailToolbarItemIdentifier,
											ResetToolbarItemIdentifier,
											RevertToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											FlyThruToolbarItemIdentifier,
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
								//		LODToolbarItemIdentifier,
								//		CaptureToolbarItemIdentifier,
										CroppingToolbarItemIdentifier,
										OrientationToolbarItemIdentifier,
										ShadingToolbarItemIdentifier,
										PerspectiveToolbarItemIdentifier,
								//		EngineToolbarItemIdentifier,
										AxToolbarItemIdentifier,
										CoToolbarItemIdentifier,
										SaToolbarItemIdentifier,
										SaOppositeToolbarItemIdentifier,
                                        ToolsToolbarItemIdentifier,
										ModeToolbarItemIdentifier,
								//		BlendingToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
								//		StereoIdentifier,
										QTExportToolbarItemIdentifier,
										iPhotoToolbarItemIdentifier,
										QTExportVRToolbarItemIdentifier,
										MailToolbarItemIdentifier,
										ResetToolbarItemIdentifier,
										RevertToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
										FlyThruToolbarItemIdentifier,
										ScissorStateToolbarItemIdentifier,
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
	
	if ([[toolbarItem itemIdentifier] isEqual: CaptureToolbarItemIdentifier])
    {
		enable=([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]==0);
    }
	
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

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:nil file:@"3D VR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}


-(void) export2iPhoto:(id) sender
{
	iPhoto		*ifoto;
	NSImage		*im = [view nsimage:NO];
	
	NSArray		*representations;
	NSData		*bitmapData;
	
	representations = [im representations];
	
	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
	[bitmapData writeToFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
	
	ifoto = [[iPhoto alloc] init];
	[ifoto importIniPhoto: [NSArray arrayWithObject:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
	[ifoto release];
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"tif"];
	
	if( [panel runModalForDirectory:nil file:@"3D VR Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [view nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:[panel filename] atomically:NO];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

// Fly Thru

- (VRPROView*) view
{	
	return view;
}

- (IBAction) flyThruButtonMenu:(id) sender
{
	[self flyThruControllerInit: self];

	[[self flyThruController].stepsArrayController flyThruTag: [sender tag]];
}

- (FlyThruController *) flyThruController
{
	for( NSWindow *w in [NSApp windows])
	{
		if( [[[w windowController] windowNibName] isEqualToString:@"FlyThru"] && self == [[w windowController] window3DController])
			return [w windowController];
	}
	
	return nil;
}

- (IBAction) flyThruControllerInit:(id) sender
{
	NSLog(@"flyThruControllerInit-->");
	
	//Only open 1 fly through controller
	if( [self flyThruController]) return;
	
	FTAdapter = [[VRPROFlyThruAdapter alloc] initWithVRController: self];
	FlyThruController *flyThruController = [[FlyThruController alloc] initWithFlyThruAdapter:FTAdapter];
	[FTAdapter release];
	[flyThruController loadWindow];
	[[flyThruController window] makeKeyAndOrderFront :sender];
	[flyThruController setWindow3DController: self];
	
	NSLog(@"<--flyThruControllerInit");
}

//added 12/5/05 Can't test. Don't have VP card LP
- (void)createContextualMenu{
	NSMenu *contextual =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	NSMenu *submenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Mode", nil)];
	NSMenuItem *item, *subItem;
	int i = 0;
	
	//Reset Item
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reset", nil) action: @selector(resetImage:)  keyEquivalent:@""];
	[item setTag:i++];
	[item setTarget:view];
	[contextual addItem:item];
	[item release];
	
	//Revert
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Revert", nil) action: @selector(resetShading:)  keyEquivalent:@""];
	[item setTag:i++];
	[item setTarget:self];
	[contextual addItem:item];
	[item release];
	
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Render Mode", nil) action: nil keyEquivalent:@""];
	[contextual addItem:item];
	//add submenu
	[item setSubmenu:submenu];
		//Volume Render		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Volume Render", nil) action: @selector(setMode:) keyEquivalent:@""];
		[subItem setTag:0];
		[subItem setTarget:self];
		[submenu addItem:subItem];
		[subItem release];
		//MIP
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"MIP", nil) action: @selector(setMode:) keyEquivalent:@""];
		[subItem setTag:1];
		[subItem setTarget:self];
		[submenu addItem:subItem];
		[subItem release];
	[submenu release];
	[item release];
	
	
	//crop
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Crop", nil) action: @selector(showCropCube:)  keyEquivalent:@""];
	//[item setImage: [NSImage imageNamed: CroppingToolbarItemIdentifier]];
	[item setTarget:view];
	[item setTag:i++];
	[contextual addItem:item];
	[item release];

	
	[contextual addItem:[NSMenuItem separatorItem]];
	
	NSMenu *mainMenu = [NSApp mainMenu];
    NSMenu *viewerMenu = [[mainMenu itemWithTitle:NSLocalizedString(@"2D Viewer", nil)] submenu];
    NSMenu *presetsMenu = [[viewerMenu itemWithTitle:NSLocalizedString(@"Window Width & Level", nil)] submenu];
	NSMenu *menu = [presetsMenu copy];
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Window Width & Level", nil) action: nil keyEquivalent:@""];
	[item setSubmenu:menu];
	[contextual addItem:item];
	[item release];
	[menu release];
	
	[contextual addItem:[NSMenuItem separatorItem]];
	//tools
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *toolsSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	[item setSubmenu:toolsSubmenu];
	
	
	NSArray *titles = [NSArray arrayWithObjects:NSLocalizedString(@"Contrast", nil), 
					NSLocalizedString(@"Move", nil), 
					NSLocalizedString(@"Magnify", nil), 
					NSLocalizedString(@"Rotate", nil), 
					NSLocalizedString(@"Control Model", nil), 
					NSLocalizedString(@"Control Camera", nil),
					NSLocalizedString(@"ROI", nil), nil];
						
	NSArray *images = [NSArray arrayWithObjects: NSLocalizedString(@"WLWW", nil), 
					NSLocalizedString(@"Move", nil),
					NSLocalizedString(@"Zoom", nil), 
					NSLocalizedString(@"Rotate", nil), 
					NSLocalizedString(@"3DRotate", nil),
					NSLocalizedString(@"3DRotateCamera", nil),					
					NSLocalizedString(@"Length", nil),
					NSLocalizedString(@"3DCut", nil),
					  nil];
					  
	NSArray *tags = [NSArray arrayWithObjects:[NSNumber numberWithInt:0], 
					[NSNumber numberWithInt:1], 
					[NSNumber numberWithInt:2], 
					[NSNumber numberWithInt:3],
					[NSNumber numberWithInt:7], 
					[NSNumber numberWithInt:18], 
					[NSNumber numberWithInt:5], 
					[NSNumber numberWithInt:17],
					nil];
	
	
	NSEnumerator *titleEnumerator = [titles objectEnumerator];
	NSEnumerator *imageEnumerator = [images objectEnumerator];
	NSEnumerator *tagEnumerator = [tags objectEnumerator];
	NSString *title;
	while (title = [titleEnumerator nextObject]) {
		subItem = [[NSMenuItem alloc] initWithTitle:title action: @selector(setDefaultTool:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setImage:[NSImage imageNamed:[imageEnumerator nextObject]]];
		[subItem setTarget:self];
		[toolsSubmenu addItem:subItem];
		[subItem release];
	}
	[toolsSubmenu release];
	[item release];
	
	//View	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *viewSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"View", nil)];
	[item setSubmenu:viewSubmenu];
	
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Axial", nil) action: @selector(axView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: AxToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Right", nil) action: @selector(saView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: SaToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Left", nil) action: @selector(saViewOpposite:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: SaOppositeToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Coronal", nil) action: @selector(coView:) keyEquivalent:@""];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		//[subItem setImage:[NSImage imageNamed: CoToolbarItemIdentifier]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		[subItem release];
		
	[viewSubmenu release];
	[item release];
	
	//Export
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *exportSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Export", nil)];
	[item setSubmenu:exportSubmenu];
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime", nil)  action:@selector(exportQuicktime:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime VR", nil)  action:@selector(exportQuicktime3DVR:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DICOM", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Email", nil)  action:@selector(sendMail:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"iPhoto", nil)  action:@selector(export2iPhoto:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"JPEG", nil)  action:@selector(exportJPEG:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		subItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"TIFF", nil)  action:@selector(exportTIFF:) keyEquivalent:@""];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		[subItem release];
		
		
	
	[exportSubmenu release];
	[item release];
	
	
	[view setMenu:contextual];
	[contextual release];
												
}

- (void) showWindow:(id) sender
{
	[super showWindow: sender];
	
	[view squareView: self];
}


- (NSManagedObject *)currentStudy{
	return [viewer2D currentStudy];
}
- (NSManagedObject *)currentSeries{
	return [viewer2D currentSeries];
}

- (NSManagedObject *)currentImage{
	return [viewer2D currentImage];
}

-(float)curWW{
	return [viewer2D curWW];
}

-(float)curWL{
	return [viewer2D curWL];
}
- (NSString *)curCLUTMenu{
	return curCLUTMenu;
}

- (NSString *)renderingMode{
	return _renderingMode;
}

- (void)setRenderingMode:(NSString *)renderingMode{
	if ([renderingMode isEqualToString:@"VR"] || [renderingMode isEqualToString:@"MIP"]) {
		if ([renderingMode isEqualToString:@"MIP"])
			[self setModeIndex:1];
		else if ([renderingMode isEqualToString:@"VR"])
			[self setModeIndex:0];
	}
}





@end
