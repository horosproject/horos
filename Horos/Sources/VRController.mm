/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "options.h"

#import "AppController.h"
#import "VRController.h"
#import "DCMView.h"
#import "DicomFile.h"
#import "NSFullScreenWindow.h"
#import "BrowserController.h"
#include <Accelerate/Accelerate.h>
#import "Photos.h"
#import "DICOMExport.h"
#import "VRFlyThruAdapter.h"
#import "DicomImage.h"
#import "VRView.h"
#import "ROI.h"
#import "ROIVolume.h"
#import "ROIVolumeManagerController.h"
#import "CLUTOpacityView.h"
#import "VRPresetPreview.h"
#import "Notifications.h"
#import "OSIWindow.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "N2Debug.h"
#import "PluginManager.h"
#import "DicomDatabase.h"

static NSString* 	VRStandardToolbarIdentifier = @"VR Toolbar Identifier";
static NSString* 	VRPanelToolbarIdentifier = @"VRPanel Toolbar Identifier";

static NSString*	QTExportToolbarItemIdentifier = @"QTExport.pdf";
static NSString*	PhotosToolbarItemIdentifier = @"iPhoto.icns";
//static NSString*	QTExportVRToolbarItemIdentifier = @"QTExportVR.icns";
static NSString*	StereoIdentifier = @"Stereo.icns";
static NSString*	CaptureToolbarItemIdentifier = @"BestRendering.pdf";
static NSString*	CroppingToolbarItemIdentifier = @"Cropping.pdf";
static NSString*	OrientationToolbarItemIdentifier= @"OrientationWidget.tif";
static NSString*	ToolsToolbarItemIdentifier = @"Tools";
static NSString*	WLWWToolbarItemIdentifier = @"WLWW";
static NSString*	LODToolbarItemIdentifier = @"LOD";
static NSString*	BlendingToolbarItemIdentifier = @"2DBlending";
static NSString*	MovieToolbarItemIdentifier = @"Movie";
static NSString*	ExportToolbarItemIdentifier = @"Export.icns";
static NSString*	MailToolbarItemIdentifier = @"Mail.icns";
static NSString*	ShadingToolbarItemIdentifier	= @"Shading";
static NSString*	EngineToolbarItemIdentifier = @"Engine";
static NSString*	PerspectiveToolbarItemIdentifier= @"Perspective";
static NSString*	ResetToolbarItemIdentifier = @"Reset.pdf";
static NSString*	RevertToolbarItemIdentifier = @"Revert.tif";
static NSString*	ModeToolbarItemIdentifier = @"Mode";
static NSString*	FlyThruToolbarItemIdentifier	= @"FlyThru.pdf";
static NSString*	ScissorStateToolbarItemIdentifier	= @"ScissorState";
static NSString*	ROIManagerToolbarItemIdentifier = @"ROIManager.pdf";
static NSString*	OrientationsViewToolbarItemIdentifier = @"OrientationsView";
static NSString*	ConvolutionViewToolbarItemIdentifier = @"ConvolutionView";
static NSString*	BackgroundColorViewToolbarItemIdentifier = @"BackgroundColorView";
static NSString*	PresetsPanelToolbarItemIdentifier = @"3DPresetsPanel.tif";
static NSString*	ClippingRangeViewToolbarItemIdentifier = @"ClippingRange";
static NSString*	CLUTEditorsViewToolbarItemIdentifier = @"CLUTEditors";

@interface VRController (Dummy)

- (void)SwitchStereoMode:(id)dummy;
- (void)noAction:(id)dummy;

@end

@implementation VRController

@synthesize deleteValue;

- (void) endShadingEditing:(id) sender
{
    
}

- (void) resetShading:(id) sender
{
    
}

- (IBAction) roiDeleteAll:(id) sender
{
    [viewer2D roiDeleteAll: sender];
}

- (IBAction) setOrientation:(id) sender
{
    switch( [[sender selectedCell] tag])
    {
        case 0:
            [view axView: self];
            break;
            
        case 1:
            [view coView: self];
            break;
            
        case 2:
            [view saView: self];
            break;
            
        case 3:
            [view saViewOpposite: self];
            break;
    }
}

-(void) revertSeries:(id) sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRevertSeriesNotification object: pixList[ curMovieIndex] userInfo: nil];
    [appliedConvolutionFilters removeAllObjects];
    if([presetsPanel isVisible])
        [self displayPresetsForSelectedGroup];
    
    //	[view resetCroppingBox];
}

-(void) UpdateOpacityMenu: (NSNotification*) note
{
    //*** Build the menu
    NSUInteger  i;
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
    [[OpacityPopup menu] addItem: [NSMenuItem separatorItem]];
    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Add an Opacity Table", nil) action:@selector (AddOpacity:) keyEquivalent:@""];
    
    [[[OpacityPopup menu] itemAtIndex:0] setTitle:curOpacityMenu];
}


-(void) UpdateWLWWMenu: (NSNotification*) note
{
    //*** Build the menu
    NSUInteger i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
    // Presets VIEWER Menu
    
    keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [[wlwwPopup menu] removeAllItems];
    
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
        [[wlwwPopup menu] addItemWithTitle:[NSString stringWithFormat:@"%d - %@", (int) i+1, [sortedKeys objectAtIndex:i]] action:@selector (ApplyWLWW:) keyEquivalent:@""];
    }
    [[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    [[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
    [[wlwwPopup menu] addItemWithTitle:NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector (SetWLWW:) keyEquivalent:@""];
    
    [[[wlwwPopup menu] itemAtIndex:0] setTitle:curWLWWMenu];
}

-(ViewerController*) blendingController
{
    return blendingController;
}

- (void) blendingSlider:(id) sender
{
    [view setBlendingFactor: [sender floatValue]];
    
    [blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) 100.0*([sender floatValue]) / 256.0]];	//(float) ([sender floatValue]+256.) / 5.12]];
}

-(void) updateBlendingImage
{
    Pixel_8			*alphaTable, *redTable, *greenTable, *blueTable;
    float			iwl, iww;
    
    [[viewer2D imageView] blendingColorTables:&alphaTable :&redTable :&greenTable :&blueTable];
    
    [view setBlendingCLUT :redTable :greenTable :blueTable];
    
    [[blendingController imageView] getWLWW: &iwl :&iww];
    [view setBlendingWLWW :iwl :iww];
}

- (IBAction) applyConvolution:(id) sender
{
    [self prepareUndo];
    [viewer2D ApplyConvString: [sender title]];
    [viewer2D applyConvolutionOnSource: self];
    [appliedConvolutionFilters addObject:[sender title]];
}

-(void) UpdateConvolutionMenu: (NSNotification*) note
{
    //*** Build the menu
    NSUInteger   i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
    keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    // Popup Menu
    
    [[convolutionMenu menu] removeAllItems];
    
    [[convolutionMenu menu] addItemWithTitle: NSLocalizedString( @"Apply a filter", nil) action:nil keyEquivalent:@""];
    
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[convolutionMenu menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (applyConvolution:) keyEquivalent:@""];
    }
}


-(long) movieFrames { return maxMovieIndex;}

- (void) setMovieFrame: (long) l
{
    curMovieIndex = l;
    [moviePosSlider setIntValue: curMovieIndex];
    
    [view movieChangeSource: (float*) [volumeData[ curMovieIndex] bytes] showWait: NO];
    [self displayROIVolumes];
}

-(void) updateVolumeData: (NSNotification*) note
{
    long i;
    
    if( [[note userInfo] objectForKey: @"sender"] == view)
        return;
    
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
    [movieTextSlide setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.0f im/s", @"im/s = images per second"), (float) [movieRateSlider floatValue]]];
}

- (void) moviePosSliderAction:(id) sender
{
    [self setMovieFrame:  [moviePosSlider intValue] ];
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
        
        [self setMovieFrame: val];
        
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
        
        [movieTextSlide setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.0f im/s", @"im/s = images per second"), (float) [movieRateSlider floatValue]]];
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
    
    [self computeMinMax];
    
    roiVolumes[maxMovieIndex-1] = [[NSMutableArray alloc] initWithCapacity:0];
    [self computeROIVolumes];
}

- (float) blendingMinimumValue;
{
    return blendingMinimumValue;
}

- (float) blendingMaximumValue;
{
    return blendingMaximumValue;
}

- (float) minimumValue;
{
    return minimumValue;
}

- (float) maximumValue;
{
    return maximumValue;
}

- (short)curMovieIndex;
{
    return curMovieIndex;
}

- (BOOL)is4D;
{
    return (maxMovieIndex > 1);
}

-(NSMutableArray*) pixList { return pixList[0];}

-(NSMutableArray*) curPixList { return pixList[ curMovieIndex];}

- (NSString*) style
{
    return style;
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC
{
    return [self initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC style:@"standard" mode:@"VR"];
}

- (void) computeMinMax
{
    static int computeMinMaxDepth = 0;
    
    if( computeMinMaxDepth > 2)
        return;
    
    computeMinMaxDepth++;
    
    maximumValue = minimumValue = [[pixList[ 0] objectAtIndex: 0] maxValueOfSeries];
    
    blendingMinimumValue = [[blendingPixList objectAtIndex: 0] minValueOfSeries];
    blendingMaximumValue = [[blendingPixList objectAtIndex: 0] maxValueOfSeries];
    
    int i;
    for( i = 0; i < maxMovieIndex; i++)
    {
        if( maximumValue < [[pixList[ i] objectAtIndex: 0] maxValueOfSeries]) maximumValue = [[pixList[ i] objectAtIndex: 0] maxValueOfSeries];
        if( minimumValue > [[pixList[ i] objectAtIndex: 0] minValueOfSeries]) minimumValue = [[pixList[ i] objectAtIndex: 0] minValueOfSeries];
    }
    
    if( maximumValue - minimumValue < 1)
        maximumValue = minimumValue + 1;
    
    [clutOpacityView setHUmin:minimumValue HUmax:maximumValue];
    
    self.deleteValue = minimumValue;
    
    if( [[viewer2D modality] isEqualToString: @"CT"] && maximumValue - minimumValue > 8192 && computeMinMaxDepth == 1)
    {
        NSInteger result = NSRunCriticalAlertPanel( NSLocalizedString( @"High Dynamic Values", nil), NSLocalizedString( @"Voxel values have a very high dynamic range (>8192). Two options are available to use the 3D engine: clip values above 7168 and below -1024 or resample the values.", nil), NSLocalizedString( @"Clip", nil), NSLocalizedString( @"Resample", nil), nil);
        
        if( result == NSAlertDefaultReturn)
        {
            NSLog( @"-- modality is CT && pixel dynamic > 8192 -> clip values to -1024 && +7168");
            
            NSLog( @"-- current maxValueOfSeries = %f", maximumValue);
            NSLog( @"-- current minValueOfSeries = %f", minimumValue);
            
            for( int x = 0; x < maxMovieIndex; x++)
            {
                vImage_Buffer srcf;
                
                DCMPix *firstObject = [pixList[ x] objectAtIndex: 0];
                
                srcf.height = [firstObject pheight] * [pixList[ x] count];
                srcf.width = [firstObject pwidth];
                srcf.rowBytes = [firstObject pwidth] * sizeof(float);
                srcf.data = (void*) [volumeData[ x] bytes];
                
                vImageClip_PlanarF( &srcf, &srcf, 7168, -1024, 0); // 7168
            }
            
            [viewer2D recomputePixMinMax];
            
            [self computeMinMax];
            
            NSLog( @"-- new maxValueOfSeries = %f", maximumValue);
            NSLog( @"-- new minValueOfSeries = %f", minimumValue);
        }
    }
    
    computeMinMaxDepth--;
}

-(id) initWithPix:(NSMutableArray*) pix
                 :(NSArray*) f
                 :(NSData*) vData
                 :(ViewerController*) bC
                 :(ViewerController*) vC
            style:(NSString*) m
             mode:(NSString*) renderingMode
{
    unsigned long   i;
    short           err = 0;
    BOOL			testInterval = YES;
    DCMPix			*firstObject = [pix objectAtIndex: 0];
    
    @try
    {
        // MEMORY TEST: The renderer needs to have the volume in short
        {
            unsigned long sizeofshort = sizeof( short) + 1;	//extra space for gradients computation
            char	*testPtr = (char*) malloc( [firstObject pwidth] * [firstObject pheight] * [pix count] * sizeofshort);
            if( testPtr == nil)
            {
                if( NSRunAlertPanel( NSLocalizedString(@"32-bit",nil), NSLocalizedString( @"Cannot use the 3D engine.\r\rUpgrade to OsiriX 64-bit or OsiriX MD to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
                    [[AppController sharedAppController] osirix64bit: self];
                
                return nil;
            }
            else free( testPtr);
        }
        
        [[NSUserDefaults standardUserDefaults] setFloat: 1125 forKey: @"VRGrowingRegionValue"];
        [[NSUserDefaults standardUserDefaults] setFloat: 1750 forKey: @"VRGrowingRegionInterval"];
        
        //	// ** RESAMPLE START
        //
        
        //	WaitRendering *www = [[WaitRendering alloc] init: NSLocalizedString( @"Resampling 3D data...", nil)];
        //	[www start];
        //
        //	NSMutableArray		*newPix = [NSMutableArray array], *newFiles = [NSMutableArray array];
        //	NSData				*newData = nil;
        //
        //	if( [ViewerController resampleDataFromPixArray:pix fileArray:f inPixArray:newPix fileArray:newFiles data:&newData withXFactor:2 yFactor:2 zFactor:2] == NO)
        //	{
        //		NSRunCriticalAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.",nil), NSLocalizedString(@"OK",nil), nil, nil);
        //		return nil;
        //	}
        //	else
        //	{
        //		pix = newPix;
        //		f = newFiles;
        //		vData = newData;
        //
        //		firstObject = [pix objectAtIndex: 0];
        //	}
        //
        //	[www end];
        //	[www close];
        //	[www release];
        //
        //	// ** RESAMPLE END
        
        style = [m retain];
        _renderingMode = [renderingMode retain];
        
        for( i = 0; i < 100; i++) undodata[ i] = nil;
        
        curMovieIndex = 0;
        maxMovieIndex = 1;
        
        fileList = f;
        [fileList retain];
        
        pixList[0] = pix;
        volumeData[0] = vData;
        
        float sliceThickness = fabs( [firstObject sliceInterval]);
        
        //fabs( [firstObject sliceLocation] - [[pixList objectAtIndex:1] sliceLocation]);
        
        if( sliceThickness == 0)
        {
            sliceThickness = [firstObject sliceThickness];
            
            testInterval = NO;
            
            if( sliceThickness > 0) NSRunCriticalAlertPanel( NSLocalizedString(@"Slice interval",nil), NSLocalizedString( @"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil), NSLocalizedString(@"OK",nil), nil, nil);
            else
            {
                NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval/thickness",nil), NSLocalizedString( @"Problems with slice thickness/interval to do a 3D reconstruction.",nil),NSLocalizedString( @"OK",nil), nil, nil);
                return nil;
            }
        }
        
        err = 0;
        // CHECK IMAGE SIZE
        for( i =0 ; i < [pixList[0] count]; i++)
        {
            if( [firstObject pwidth] != [[pixList[0] objectAtIndex:i] pwidth]) err = -1;
            if( [firstObject pheight] != [[pixList[0] objectAtIndex:i] pheight]) err = -1;
        }
        if( err)
        {
            NSRunCriticalAlertPanel(NSLocalizedString( @"Images size",nil),  NSLocalizedString(@"These images don't have the same height and width to allow a 3D reconstruction...",nil),NSLocalizedString( @"OK",nil), nil, nil);
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
        viewer2D = [vC retain];
        
        blendingController = bC;
        if( blendingController) blendingPixList = [blendingController pixList];
        
        // Find Minimum Value
        if( [firstObject isRGB] == NO) [self computeMinMax];
        else minimumValue = self.deleteValue = 0;
        
        self = [super initWithWindowNibName:@"VR"];
        
        //        if( [style isEqualToString:@"standard"] || [style isEqualToString: @"panel"])
        //            self = [super initWithWindowNibName:@"VR"];
        //        else if( [style isEqualToString:@"noNib"])
        //            self = [super initWithWindowNibName:@"VREmpty"];
        
        [[self window] setDelegate:self];
        
        if( [style isEqualToString: @"panel"])
            [self.window setLevel: NSFloatingWindowLevel];
        
        err = [view setPixSource:pixList[0] :(float*) [volumeData[0] bytes]];
        if( err != 0)
        {
            if( NSRunAlertPanel( NSLocalizedString(@"32-bit",nil), NSLocalizedString( @"Cannot use the 3D engine.\r\rUpgrade to OsiriX 64-bit or OsiriX MD to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
                [[AppController sharedAppController] osirix64bit: self];
            [self autorelease];
            return nil;
        }
        
        if( blendingController) // Blending! Activate image fusion
        {
            [view setBlendingPixSource: blendingController];
            
            [blendingSlider setEnabled:YES];
            [blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) 100.*([blendingSlider floatValue]) / 256.]];
            
            [self updateBlendingImage];
        }
        
        curWLWWMenu = [NSLocalizedString(@"Other", nil) retain];
        
        roi2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        sliceNumber2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        x2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        y2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        z2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        
        if (viewer2D)
        {
            long i, j;
            float x, y, z;
            NSMutableArray	*curRoiList;
            ROI	*curROI;
            
            for(i=0; i<[[[viewer2D imageView] dcmPixList] count]; i++)
            {
                curRoiList = [[viewer2D roiList] objectAtIndex: i];
                for(j=0; j<[curRoiList count];j++)
                {
                    curROI = [curRoiList objectAtIndex:j];
                    if ([curROI type] == t2DPoint)
                    {
                        float location[ 3 ];
                        
                        [[[viewer2D pixList] objectAtIndex: i] convertPixX: [[[curROI points] objectAtIndex:0] x] pixY: [[[curROI points] objectAtIndex:0] y] toDICOMCoords: location pixelCenter: YES];
                        
                        x = location[ 0 ];
                        y = location[ 1 ];
                        z = location[ 2 ];
                        
                        // add the 3D Point to the SR view
                        [[self view] add3DPoint:  x : y : z : curROI.thickness :curROI.rgbcolor.red/65535. :curROI.rgbcolor.green/65535. :curROI.rgbcolor.blue/65535.];
                        // add the 2D Point to our list
                        [roi2DPointsArray addObject:curROI];
                        [sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:i]];
                        [x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
                        [y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
                        [z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
                    }
                }
            }
        }
        
        NSNotificationCenter *nc;
        nc = [NSNotificationCenter defaultCenter];
        
        [nc addObserver: self
               selector: @selector(remove3DPoint:)
                   name: OsirixRemoveROINotification
                 object: nil];
        [nc addObserver: self
               selector: @selector(add3DPoint:)
         //name: OsirixROIChangeNotification
                   name: OsirixROISelectedNotification //OsirixROISelectedNotification
                 object: nil];
        
        [nc addObserver: self
               selector: @selector(UpdateWLWWMenu:)
                   name: OsirixUpdateWLWWMenuNotification
                 object: nil];
        
        [nc addObserver: self
               selector: @selector(updateVolumeData:)
                   name: OsirixUpdateVolumeDataNotification
                 object: nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
        
        curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
        
        [nc addObserver: self
               selector: @selector(UpdateCLUTMenu:)
                   name: OsirixUpdateCLUTMenuNotification
                 object: nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
        
        curOpacityMenu = [NSLocalizedString(@"Linear Table", nil) retain];
        
        [nc addObserver: self
               selector: @selector(UpdateOpacityMenu:)
                   name: OsirixUpdateOpacityMenuNotification
                 object: nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
        
        [nc addObserver: self
               selector: @selector(CLUTChanged:)
                   name: OsirixCLUTChangedNotification
                 object: nil];
        
        [nc addObserver: self
               selector: @selector(UpdateConvolutionMenu:)
                   name: OsirixUpdateConvolutionMenuNotification
                 object: nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: NSLocalizedString( @"No Filter", nil) userInfo: nil];
        
        [nc addObserver: self
               selector: @selector(CloseViewerNotification:)
                   name: OsirixCloseViewerNotification
                 object: nil];
        
        //should we always zoom the Window?
        //if( [style isEqualToString:@"standard"])
        //	[[self window] performZoom:self];
        
        [movieRateSlider setEnabled: NO];
        [moviePosSlider setEnabled: NO];
        [moviePlayStop setEnabled: NO];
        
        [view updateScissorStateButtons];
        
        for(int m=0; m<maxMovieIndex; m++)
        {
            roiVolumes[m] = [[NSMutableArray alloc] initWithCapacity:0];
        }
#ifdef roi3Dvolume
        [self computeROIVolumes];
        [self displayROIVolumes];
        [nc addObserver:self selector:@selector(updateROIVolume:) name:OsirixROIVolumePropertiesChangedNotification object:nil];
#endif
        
        //	// allow bones removal only for CT or SC scans
        //	if( [[viewer2D modality] isEqualToString:@"CT"] == NO && [[viewer2D modality] isEqualToString:@"SC"])
        //	{
        //		[[toolsMatrix cellWithTag:21] setEnabled:NO];
        //	}
        //	else
        //	{
        //		[[toolsMatrix cellWithTag:21] setEnabled:YES];
        //	}
        
        if( [renderingMode isEqualToString:@"MIP"])
            [self setModeIndex: 1];
        
        if( [style isEqualToString:@"panel"])
        {
            [view setRotate: YES];
            [view setLOD: 1.0];
        }
        
        appliedConvolutionFilters = [[NSMutableArray alloc] initWithCapacity:0];
        
        if( [style isEqualToString: @"noNib"] == NO)
        {
            NSLog( @"presets start");
            presetPreviewArray = [[NSMutableArray alloc] initWithCapacity:0];
            if(presetPreview1) [presetPreviewArray addObject:presetPreview1];
            if(presetPreview2) [presetPreviewArray addObject:presetPreview2];
            if(presetPreview3) [presetPreviewArray addObject:presetPreview3];
            if(presetPreview4) [presetPreviewArray addObject:presetPreview4];
            if(presetPreview5) [presetPreviewArray addObject:presetPreview5];
            if(presetPreview6) [presetPreviewArray addObject:presetPreview6];
            if(presetPreview7) [presetPreviewArray addObject:presetPreview7];
            if(presetPreview8) [presetPreviewArray addObject:presetPreview8];
            if(presetPreview9) [presetPreviewArray addObject:presetPreview9];
            
            
            presetNameArray = [[NSMutableArray alloc] initWithCapacity:0];
            if(presetName1) [presetNameArray addObject:presetName1];
            if(presetName2) [presetNameArray addObject:presetName2];
            if(presetName3) [presetNameArray addObject:presetName3];
            if(presetName4) [presetNameArray addObject:presetName4];
            if(presetName5) [presetNameArray addObject:presetName5];
            if(presetName6) [presetNameArray addObject:presetName6];
            if(presetName7) [presetNameArray addObject:presetName7];
            if(presetName8) [presetNameArray addObject:presetName8];
            if(presetName9) [presetNameArray addObject:presetName9];
            
            NSLog( @"presets end");
        }
        [nc addObserver:self selector:@selector(windowWillCloseNotification:) name:NSWindowWillCloseNotification object:nil];
        [nc addObserver:self selector:@selector(windowWillMoveNotification:) name:NSWindowWillMoveNotification object:nil];
        //[nc addObserver:self selector:@selector(windowWillMoveNotification:) name:NSWindowWillMoveNotification object:nil];
        
        if( [style isEqualToString:@"panel"])
        {
            [self setShouldCascadeWindows: NO];
            [[self window] setFrameAutosaveName:@"3D Panel"];
            [[self window] setFrameUsingName:@"3D Panel"];
        }
        
//        [shadingsPresetsController setWindowController: self];
        [shadingsPresetsController addObserver:self forKeyPath:@"selectedObjects" options:0 context:VRController.class];
        
        [self setupToolbar];
    }
    @catch ( NSException *e) {
        N2LogException( e);
        
        [self autorelease];
        return nil;
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == VRController.class && object == shadingsPresetsController && [keyPath isEqualToString:@"selectedObjects"]) {
        [self applyShading:self];
        return;
    }
}

+ (NSString*) getUniqueFilenameScissorStateFor:(NSManagedObject*) obj
{
    NSString *path = [[[BrowserController currentBrowser] database] statesDirPath];
    BOOL isDir = YES;
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    
    DicomSeries *series = nil;
    
    if( [obj isKindOfClass: [DicomSeries class]])
        series = (DicomSeries*) obj;
    
    else  if( [obj isKindOfClass: [DicomImage class]])
        series = [obj valueForKey: @"series"];
    
    else
        NSLog( @"******** UNKNOWN class for getUniqueFilenameScissorStateFor");
    
    return [path stringByAppendingPathComponent: [NSString stringWithFormat:@"VR3DScissor-%@", series.uniqueFilename]];
}

-(void) save3DState
{
    NSString *path = [[[BrowserController currentBrowser] database] statesDirPath];
    BOOL isDir = YES;
    
    if( ![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSString *str;
    
    if( [style isEqualToString:@"noNib"])
        str = nil;
    else
        str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"VRMIP-%d-%@", (int) [view mode], [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
    
    if( str)
    {
        NSMutableDictionary *dict = [view get3DStateDictionary];
        [dict setObject:curCLUTMenu forKey:@"CLUTName"];
        [dict setObject:[NSNumber numberWithBool:[view advancedCLUT]] forKey:@"isAdvancedCLUT"];
        if(![view advancedCLUT])[dict setObject:curOpacityMenu forKey:@"OpacityName"];
        
        if([curCLUTMenu isEqualToString:NSLocalizedString(@"16-bit CLUT", nil)] || [curCLUTMenu isEqualToString: @"16-bit CLUT"])
        {
            NSArray *curves = [clutOpacityView convertCurvesForPlist];
            NSArray *colors = [clutOpacityView convertPointColorsForPlist];
            [dict setObject:curves forKey:@"16bitClutCurves"];
            [dict setObject:colors forKey:@"16bitClutColors"];
        }
        
        if( [viewer2D postprocessed] == NO)
            [dict writeToFile:str atomically:YES];
    }
}

-(void) load3DState
{
    @try {
        NSString *path = [[[BrowserController currentBrowser] database] statesDirPath];
        BOOL isDir = YES;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        NSString *str;
        
        if( [style isEqualToString:@"noNib"])
            str = nil;
        else
            str = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"VRMIP-%d-%@", (int) [view mode], [[fileList objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
        
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
        
        if( [viewer2D postprocessed]) dict = nil;
        
        [view set3DStateDictionary:dict];
        
        BOOL has16bitCLUT = NO;
        
        if( [dict objectForKey:@"CLUTName"])
        {
            if([dict objectForKey:@"isAdvancedCLUT"])
            {
                if([[dict objectForKey:@"isAdvancedCLUT"] boolValue])
                {
                    [[[clutPopup menu] itemAtIndex:0] setTitle:[dict objectForKey:@"CLUTName"]];
                    [self setCurCLUTMenu:[dict objectForKey:@"CLUTName"]];
                    if([[dict objectForKey:@"CLUTName"] isEqualToString:NSLocalizedString(@"16-bit CLUT", nil)]  || [[dict objectForKey:@"CLUTName"] isEqualToString: @"16-bit CLUT"])
                    {
                        NSMutableArray *curves = [CLUTOpacityView convertCurvesFromPlist:[dict objectForKey:@"16bitClutCurves"]];
                        NSMutableArray *colors = [CLUTOpacityView convertPointColorsFromPlist:[dict objectForKey:@"16bitClutColors"]];
                        
                        NSMutableDictionary *clut = [NSMutableDictionary dictionaryWithCapacity:2];
                        [clut setObject:curves forKey:@"curves"];
                        [clut setObject:colors forKey:@"colors"];
                        
                        [clutOpacityView setCurves:curves];
                        [clutOpacityView setPointColors:colors];
                        
                        [view setAdvancedCLUT:clut lowResolution:NO];
                    }
                    else
                    {
                        [self loadAdvancedCLUTOpacity:clutPopup];
                    }
                    has16bitCLUT = YES;
                }
                else
                    [self ApplyCLUTString:[dict objectForKey:@"CLUTName"]];
            }
            else
                [self ApplyCLUTString:[dict objectForKey:@"CLUTName"]];
        }
        else if([view mode] == 0 && [[pixList[ 0] objectAtIndex:0] isRGB] == NO) [self ApplyCLUTString:@"VR Muscles-Bones"];	//For VR mode only
        
        if(!has16bitCLUT)
        {
            if( [dict objectForKey:@"OpacityName"]) [self ApplyOpacityString:[dict objectForKey:@"OpacityName"]];
            else if([view mode] == 0 && [[pixList[ 0] objectAtIndex:0] isRGB] == NO) [self ApplyOpacityString:NSLocalizedString(@"Logarithmic Inverse Table", nil)];		//For VR mode only
        }
        
        if( [view shading]) [shadingCheck setState: NSOnState];
        else [shadingCheck setState: NSOffState];
        
        float ambient, diffuse, specular, specularpower;
        
        [view getShadingValues: &ambient :&diffuse :&specular :&specularpower];
        [shadingValues setStringValue: [NSString stringWithFormat: NSLocalizedString( @"Ambient: %2.1f\nDiffuse: %2.1f\nSpecular :%2.1f-%2.1f", nil), ambient, diffuse, specular, specularpower]];
        
        //	if(!dict && [_renderingMode isEqualToString:@"VR"])
        //	{
        //		firstTimeDisplayed = YES;
        //		[self centerPresetsPanel];
        //		[self showPresetsPanel];
        //	}
        
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
}

- (void) applyScissor : (NSArray*) object
{
    int			i                   = [[object objectAtIndex: 0] intValue];
    int			stackOrientation	= [[object objectAtIndex: 1] intValue];
    int			c					= [[object objectAtIndex: 2] intValue];
    ROI*		roi					= [object objectAtIndex: 3];
    BOOL		blendedSeries		= [[object objectAtIndex: 4] intValue];
    BOOL		addition			= [[object objectAtIndex: 5] intValue];
    float		newVal				= [[object objectAtIndex: 6] intValue];
    NSPoint     minClip             = [[object objectAtIndex: 7] pointValue];
    NSPoint     maxClip             = [[object objectAtIndex: 8] pointValue];
    
    int			index;
    
    switch( stackOrientation)
    {
        case 2:
            index = i;
            break;
            
        case 1:
        case 0:
            index = 0;
            break;
    }
    
    BOOL outside = NO;
    BOOL restore = NO;
    
    if( c == NSCarriageReturnCharacter || c == NSEnterCharacter) outside = YES;
    else if( c == NSTabCharacter) restore = YES;
    
    if( addition == NO) newVal = self.deleteValue;
    
    if( blendedSeries)
    {
        [[blendingPixList objectAtIndex: index] fillROI:roi newVal:newVal minValue: -FLT_MAX maxValue: FLT_MAX outside:outside orientationStack:stackOrientation stackNo:i restore:restore addition:addition spline: NO clipMin: minClip clipMax: maxClip];
    }
    else
    {
        [[pixList[ curMovieIndex] objectAtIndex: index] fillROI:roi newVal:newVal minValue: -FLT_MAX maxValue: FLT_MAX outside:outside orientationStack:stackOrientation stackNo:i restore:restore addition:addition spline: NO clipMin: minClip clipMax: maxClip];
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
            undodata[ i] = (float*) malloc( memSize);
        
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
            
            [BrowserController multiThreadedImageConvert: @"FTo16U" :&srcf :&dst16 :-[view offset] :1./[view valueFactor]];
            
            //			vImageConvert_FTo16U( &srcf, &dst16, -[view offset], 1./[view valueFactor], 0);
            
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
            
            [BrowserController multiThreadedImageConvert: @"16UToF" :&src16 :&dstf :-[view offset] :1./[view valueFactor]];
            
            //			vImageConvert_16UToF( &src16, &dstf, -[view offset], 1./[view valueFactor], 0);
            //BlockMoveData( undodata[ i], data, memSize);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList[ i] userInfo: 0];
    }
}

- (NSArray*) fileList
{
    return fileList;
}

-(void) dealloc
{
    NSLog(@"Dealloc VRController");
    
    [shadingsPresetsController removeObserver:self forKeyPath:@"selectedObjects" context:VRController.class];
    
    [style release];
    
    // Release Undo system
    for( int i = 0; i < maxMovieIndex; i++)
    {
        
        if( undodata[ i])
        {
            free( undodata[ i]);
        }
    }
    
    [self save3DState];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
    for( int i = 0; i < maxMovieIndex; i++)
    {
        [pixList[ i] release];
        [volumeData[ i] release];
    }
    [fileList release];
    [toolbar setDelegate: nil];
    [toolbar release];
    
    // 3D Points
    [roi2DPointsArray release];
    [sliceNumber2DPointsArray release];
    [x2DPointsArray release];
    [y2DPointsArray release];
    [z2DPointsArray release];
    [viewer2D release];
    for(int m=0; m<maxMovieIndex; m++) [roiVolumes[m] release];
    [_renderingMode release];
    
    [appliedConvolutionFilters release];
    [presetPreviewArray release];
    [presetNameArray release];
    
    [view prepareForRelease];
    
    [presetPreview1 prepareForRelease];
    [presetPreview2 prepareForRelease];
    [presetPreview3 prepareForRelease];
    [presetPreview4 prepareForRelease];
    [presetPreview5 prepareForRelease];
    [presetPreview6 prepareForRelease];
    [presetPreview7 prepareForRelease];
    [presetPreview8 prepareForRelease];
    [presetPreview9 prepareForRelease];
    [selectedPresetPreview prepareForRelease];
    
    [super dealloc];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
    if([note object] == viewer2D)
    {
        [self offFullScreen];
        [[self window] close];
    }
}

#pragma mark - NSWindowDelegate notifications

- (void)windowDidResize:(NSNotification *)aNotification
{
    if( [style isEqualToString:@"panel"] == NO) [view squareView: self];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if( [notification object] == [self window])
    {
        windowWillClose = YES;
        [[self window] setAcceptsMouseMovedEvents: NO];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixWindow3dCloseNotification object: self userInfo: 0];
        
        if( movieTimer)
        {
            [movieTimer invalidate];
            [movieTimer release];
            movieTimer = nil;
        }
        
        [presetsPanel close];
        [presetsInfoPanel close];
        
        [[self window] setDelegate:nil];
        
        [self autorelease];
    }
}

#pragma mark -

-(NSMatrix*) toolsMatrix
{
    return toolsMatrix;
}


- (BOOL)validateMenuItem:(NSMenuItem *)item
{
#ifdef EXPORTTOOLBARITEM
    return YES;
#endif
    
    BOOL valid = NO;
    
    if( [item action] == @selector(setDefaultTool:))
    {
        valid = YES;
        
        if( [item tag] == [view currentTool]) [item setState:NSOnState];
        else [item setState:NSOffState];
    }
    else valid = YES;
    
    return valid;
}

-(void) setDefaultTool:(id) sender
{
    NSInteger tag;
    if ([sender isKindOfClass:[NSMatrix class]])
        tag = [[sender selectedCell] tag];
    else
        tag = [sender tag];
    
    if( tag >= 0)
    {
        [self setCurrentTool:(ToolMode)tag];
    }
}

- (void) setCurrentTool:(ToolMode) newTool
{
    if( newTool == tBonesRemoval)
    {
        if( ([[viewer2D modality] isEqualToString:@"CT"] == NO && growingSet == NO) || ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask))
        {
            [self editGrowingRegion: self];
            growingSet = YES;
        }
    }
    
    if( newTool == t3DCut)
    {
        if( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
        {
            float copyValue = self.deleteValue;
            
            [NSApp beginSheet: editDeleteValue
               modalForWindow: self.window
                modalDelegate: nil
               didEndSelector: nil
                  contextInfo: nil];
            
            int result = [NSApp runModalForWindow: editDeleteValue];
            [editDeleteValue makeFirstResponder: nil];
            
            [NSApp endSheet: editDeleteValue];
            [editDeleteValue orderOut: self];
            
            if( result == NSRunStoppedResponse)
                NSLog( @"deleteValue for 3DCut changed : %f", self.deleteValue);
            else self.deleteValue = copyValue;
        }
    }
    
    [view setCurrentTool: newTool];
    [toolsMatrix selectCellWithTag:newTool];
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
    NSString	*menuString = [sender title];
    
    if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)])
    {
    }
    else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)])
    {
    }
    else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)])
    {
    }
    else
    {
        menuString = [menuString substringFromIndex: 4];
    }
    
    [self applyWLWWForString: menuString];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
}

- (void)applyWLWWForString:(NSString *)menuString
{
    if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)])
    {
        //[imageView setWLWW:0 :0];
    }
    else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)])
    {
        [view setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
    }
    else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)])
    {
        [view setWLWW:0 :0];
    }
    else
    {
        if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
        {
            NSBeginAlertSheet( NSLocalizedString(@"Delete a WL/WW preset",nil), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [menuString retain], NSLocalizedString (@"Are you sure you want to delete preset : '%@'?", nil), menuString);
        }
        else
        {
            NSArray    *value;
            
            value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] objectForKey:menuString];
            
            [view setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
        }
    }
    
    [[[wlwwPopup menu] itemAtIndex:0] setTitle:menuString];
    
    if( curWLWWMenu != menuString)
    {
        [curWLWWMenu release];
        curWLWWMenu = [menuString retain];
    }
    
}

- (IBAction) applyShading:(id) sender
{
    NSDictionary *dict = [shadingsPresetsController.selectedObjects lastObject];
    
    if (!dict)
        return;
    
    float ambient, diffuse, specular, specularpower;
    
    ambient = [[dict valueForKey:@"ambient"] floatValue];
    diffuse = [[dict valueForKey:@"diffuse"] floatValue];
    specular = [[dict valueForKey:@"specular"] floatValue];
    specularpower = [[dict valueForKey:@"specularPower"] floatValue];
    
    float sambient, sdiffuse, sspecular, sspecularpower;
    [view getShadingValues: &sambient :&sdiffuse :&sspecular :&sspecularpower];
    
    if( sambient != ambient || sdiffuse != diffuse || sspecular != specular || sspecularpower != specularpower)
    {
        [view setShadingValues: ambient :diffuse :specular :specularpower];
        [shadingValues setStringValue: [NSString stringWithFormat: NSLocalizedString( @"Ambient: %2.2f\nDiffuse: %2.2f\nSpecular :%2.2f, %2.2f", nil), ambient, diffuse, specular, specularpower]];
        
        [view setNeedsDisplay: YES];
    }
}

- (void) findShadingPreset:(id) sender
{
    float ambient, diffuse, specular, specularpower;
    
    [view getShadingValues: &ambient :&diffuse :&specular :&specularpower];
    
    NSArray	*shadings = [shadingsPresetsController arrangedObjects];
    int i;
    for( i = 0; i < [shadings count]; i++)
    {
        NSDictionary	*dict = [shadings objectAtIndex: i];
        if( ambient == [[dict valueForKey:@"ambient"] floatValue] && diffuse == [[dict valueForKey:@"diffuse"] floatValue] && specular == [[dict valueForKey:@"specular"] floatValue] && specularpower == [[dict valueForKey:@"specularPower"] floatValue])
        {
            [shadingsPresetsController setSelectedObjects: [NSArray arrayWithObject: dict]];
            break;
        }
    }
    // shading already applied
    //[self applyShading: self];
}

- (IBAction) editShadingValues:(id) sender
{
    [shadingPanel makeKeyAndOrderFront: self];
    [self findShadingPreset: self];
}

- (void) AddCurrentWLWW:(id) sender
{
    float iww, iwl;
    
    [view getWLWW:&iwl :&iww];
    
    [wl setStringValue:[NSString stringWithFormat:@"%0.f", iwl]];
    [ww setStringValue:[NSString stringWithFormat:@"%0.f", iww]];
    
    [newName setStringValue: NSLocalizedString( @"Unnamed", nil)];
    
    [NSApp beginSheet: addWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


-(void) ApplyCLUTString:(NSString*) str
{
    NSString	*previousColorName = [NSString stringWithString: curCLUTMenu];
    
    if( str == nil) return;
    
    [OpacityPopup setEnabled:YES];
    [clutOpacityView cleanup];
    if([clutOpacityDrawer state]==NSDrawerOpenState)
    {
        [clutOpacityDrawer close];
    }
    
    [self ApplyOpacityString:curOpacityMenu];
    
    if( [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str] == nil)
        str = NSLocalizedString(@"No CLUT", nil);
    
    if( curCLUTMenu != str)
    {
        [curCLUTMenu release];
        curCLUTMenu = [str retain];
    }
    
    if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)])
    {
        [view setCLUT: nil :nil :nil];
        
        if( [previousColorName isEqualToString: NSLocalizedString( @"B/W Inverse", nil)] || [previousColorName isEqualToString:( @"B/W Inverse")])
            [view changeColorWith: [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
        
        [[[clutPopup menu] itemAtIndex:0] setTitle:str];
    }
    else
    {
        NSDictionary		*aCLUT;
        NSArray				*array;
        long				i;
        unsigned char		red[256], green[256], blue[256];
        
        aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str];
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
            {
                if( [previousColorName isEqualToString: NSLocalizedString( @"B/W Inverse", nil)] || [previousColorName isEqualToString:( @"B/W Inverse")])
                    [view changeColorWith: [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
            
            [[[clutPopup menu] itemAtIndex:0] setTitle: curCLUTMenu];
        }
        
    }
}

-(void) ApplyOpacityString:(NSString*) str
{
    NSDictionary		*aOpacity;
    NSArray				*array;
    
    if( str == nil) return;
    
    if( curOpacityMenu != str)
    {
        [curOpacityMenu release];
        curOpacityMenu = [str retain];
    }
    
    if( [str isEqualToString: NSLocalizedString(@"Linear Table", nil)])
    {
        [view setOpacity:[NSArray array]];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
        
        [[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
    }
    else
    {
        aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
        if( aOpacity)
        {
            array = [aOpacity objectForKey:@"Points"];
            
            [view setOpacity:array];
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
            
            [[[OpacityPopup menu] itemAtIndex:0] setTitle: curOpacityMenu];
        }
    }
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

- (IBAction) setModeIndex:(long) val
{
    [modeMatrix selectCellWithTag: val];
    [self setMode: modeMatrix];
}

- (IBAction) setMode:(id) sender
{
    int tag;
    if ([sender isKindOfClass:[NSMatrix class]])
        tag = [[sender selectedCell] tag];
    else {
        tag = [sender tag];
        [modeMatrix setState:1 atRow:tag column:0];
    }
    [view setMode: tag];
    [view setBlendingMode: tag];
    
    if( tag == 1)
    {
        [_renderingMode release];
        _renderingMode = [@"MIP" retain];
        [shadingCheck setEnabled : NO];
    }
    else
    {
        [_renderingMode release];
        _renderingMode = [@"VR" retain];
        [shadingCheck setEnabled : YES];
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
    
    [OpacityName setStringValue: NSLocalizedString(@"Unnamed", nil)];
    
    [NSApp beginSheet: addOpacityWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(void) bestRendering:(id) sender
{
    //	if( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
    //	{
    //		[OSIWindow setDontConstrainWindow: YES];
    //		[[self window] setFrame: NSMakeRect(0, [[[self window] screen] visibleFrame].origin.y - (3000-[[[self window] screen] visibleFrame].size.height), 3000, 3000) display: NO];
    //		[OSIWindow setDontConstrainWindow: NO];
    //	}
    //	else
    [view bestRendering: sender];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window
    
    if( [style isEqualToString:@"standard"]) toolbar = [[NSToolbar alloc] initWithIdentifier: VRStandardToolbarIdentifier];
    else toolbar = [[NSToolbar alloc] initWithIdentifier: VRPanelToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    //    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window
    [[self window] setToolbar: toolbar];
    [[self window] setShowsToolbarButton: [style isEqualToString:@"panel"]];
    [[[self window] toolbar] setVisible: [style isEqualToString:@"standard"]];
    
    //    [window makeKeyAndOrderFront:nil];
    
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

- (IBAction)customizeViewerToolBar:(id)sender
{
    [toolbar runCustomizationPalette:sender];
}

#pragma mark - NSToolbarDelegate

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSString *) itemIdent
  willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    //	if ([itemIdent isEqualToString: QTExportVRToolbarItemIdentifier])
    //	{
    //		[toolbarItem setLabel: NSLocalizedString(@"Export QTVR",nil)];
    //		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export QTVR",nil)];
    //		[toolbarItem setToolTip: NSLocalizedString(@"Export this image in a Quicktime VR file",nil)];
    //		[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
    //		[toolbarItem setTarget: view];
    //		[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
    //    }
    //	else
    if ([itemIdent isEqualToString: StereoIdentifier])
    {
        
        [toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Stereo",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Switch Stereo Mode ON/OFF",nil)];
        [toolbarItem setImage: [NSImage imageNamed: StereoIdentifier]];
        [toolbarItem setTarget: view];
        [toolbarItem setAction: @selector(SwitchStereoMode:)];
    }
    else if ([itemIdent isEqualToString: MailToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Email",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Email",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image",nil)];
        [toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(sendMail:)];
    }
    else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Reset",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Reset to initial 3D view",nil)];
        [toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
        [toolbarItem setTarget: view];
        [toolbarItem setAction: @selector(resetImage:)];
    }
    else if ([itemIdent isEqualToString: RevertToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Revert",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Revert",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Revert series by re-loading images from disk",nil)];
        [toolbarItem setImage: [NSImage imageNamed: RevertToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(revertSeries:)];
    }
    else if ([itemIdent isEqualToString: ShadingToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Shading",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Shading",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Shading Properties",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: shadingView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([shadingView frame]), NSHeight([shadingView frame]))];
    }
    else if ([itemIdent isEqualToString: EngineToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Engine",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Engine",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Engine",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: engineView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([engineView frame]), NSHeight([engineView frame]))];
    }
    else if ([itemIdent isEqualToString: PerspectiveToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Perspective",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Perspective",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Perspective Properties",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: perspectiveView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([perspectiveView frame]), NSHeight([perspectiveView frame]))];
    }
    else if ([itemIdent isEqualToString: QTExportToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Movie Export",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image in a Movie file",nil)];
        [toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
        [toolbarItem setTarget: view];
        [toolbarItem setAction: @selector(exportQuicktime:)];
    }
    else if ([itemIdent isEqualToString: PhotosToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Photos",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Photos",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image to Photos",nil)];
        [toolbarItem setImage: [NSImage imageNamed:@"Photos"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(export2iPhoto:)];
    }
    else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
        [toolbarItem setLabel:NSLocalizedString( @"DICOM File",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"DICOM",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image in a DICOM file",nil)];
        [toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(exportDICOMFile:)];
    }
    //	else if ([itemIdent isEqualToString: SendToolbarItemIdentifier]) {
    //
    //	[toolbarItem setLabel: @"Send DICOM"];
    //	[toolbarItem setPaletteLabel: @"Send DICOM"];
    //        [toolbarItem setToolTip: @"Send this image to a DICOM node"];
    //	[toolbarItem setImage: [NSImage imageNamed: SendToolbarItemIdentifier]];
    //	[toolbarItem setTarget: self];
    //	[toolbarItem setAction: @selector(exportDICOMPACS:)];
    //    }
    else if ([itemIdent isEqualToString: CroppingToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Crop",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Cropping Cube",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Show and manipulate cropping cube",nil)];
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
    else if ([itemIdent isEqualToString: CaptureToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Best",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Best Rendering",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Render this image at the best resolution",nil)];
        [toolbarItem setImage: [NSImage imageNamed: CaptureToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(bestRendering:)];
    }
    else if([itemIdent isEqualToString: WLWWToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT & Opacity",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"WL/WW & CLUT & Opacity",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Change the WL/WW & CLUT & Opacity",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: WLWWView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
    else if([itemIdent isEqualToString: MovieToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"4D Player",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"4D Player",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: movieView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([movieView frame]), NSHeight([movieView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([movieView frame]),NSHeight([movieView frame]))];
    }
    else if([itemIdent isEqualToString: OrientationsViewToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Orientations", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Orientations", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Orientations", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: OrientationsView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([OrientationsView frame]), NSHeight([OrientationsView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([OrientationsView frame]), NSHeight([OrientationsView frame]))];
    }
    else if([itemIdent isEqualToString: ConvolutionViewToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Filters", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Filters", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Filters", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: convolutionView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([convolutionView frame]), NSHeight([convolutionView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([convolutionView frame]), NSHeight([convolutionView frame]))];
    }
    else if([itemIdent isEqualToString: BackgroundColorViewToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Background", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Background", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Background Color", nil)];
        
        [toolbarItem setView: BackgroundColorView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([BackgroundColorView frame]), NSHeight([BackgroundColorView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([BackgroundColorView frame]), NSHeight([BackgroundColorView frame]))];
    }
    else if([itemIdent isEqualToString: ScissorStateToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Scissor State", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Scissor State", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: scissorStateView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([scissorStateView frame]), NSHeight([scissorStateView frame]))];
    }
    else if([itemIdent isEqualToString: BlendingToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel:NSLocalizedString( @"Fusion",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: BlendingView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
    }
    else if([itemIdent isEqualToString: ModeToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel:NSLocalizedString( @"Mode",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"Mode",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Mode",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: modeView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([modeView frame]), NSHeight([modeView frame]))];
    }
    else if([itemIdent isEqualToString: LODToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Level of Detail",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"Level of Detail",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"Change Level of Detail",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: LODView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([LODView frame]), NSHeight([LODView frame]))];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
    }
    else if([itemIdent isEqualToString: ToolsToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Mouse button function",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function",nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: toolsView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
    else if([itemIdent isEqualToString: FlyThruToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Fly Thru",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Fly Thru",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Fly Thru Set up",nil)];
        
        [toolbarItem setImage: [NSImage imageNamed: FlyThruToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(flyThruControllerInit:)];
    }
    else if ([itemIdent isEqualToString: ROIManagerToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"ROI Manager",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"ROI Manager",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"ROI Manager",nil)];
        [toolbarItem setImage: [NSImage imageNamed: ROIManagerToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(roiGetManager:)];
    }
    else if ([itemIdent isEqualToString: PresetsPanelToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"3D Presets",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"3D Presets",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Show 3D Presets Panel",nil)];
        [toolbarItem setImage: [NSImage imageNamed: PresetsPanelToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(load3DSettings:)];
    }
    else if( [itemIdent isEqualToString: ClippingRangeViewToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Clipping",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"Clipping",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Clipping",nil)];
        
        [toolbarItem setView: ClippingRangeView];
        [toolbarItem setMinSize: NSMakeSize(NSWidth([ClippingRangeView frame]), NSHeight([ClippingRangeView frame]))];
    }
    else if( [itemIdent isEqualToString: CLUTEditorsViewToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"CLUT Editor",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"CLUT Editor",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"CLUT Editor",nil)];
        
        [toolbarItem setView: CLUTEditorsView];
        [toolbarItem setMinSize: NSMakeSize(NSWidth([CLUTEditorsView frame]), NSHeight([CLUTEditorsView frame]))];
    }
    else
        toolbarItem = nil;
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarItemForItemIdentifier:forVRViewer:)])
        {
            NSToolbarItem *item = [[[PluginManager plugins] objectForKey:key] toolbarItemForItemIdentifier: itemIdent forVRViewer: self];
            
            if( item)
                toolbarItem = item;
        }
    }
    
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    if( [style isEqualToString:@"standard"])
        return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
                WLWWToolbarItemIdentifier,
                CLUTEditorsViewToolbarItemIdentifier,
                PresetsPanelToolbarItemIdentifier,
                LODToolbarItemIdentifier,
                CaptureToolbarItemIdentifier,
                EngineToolbarItemIdentifier,
                CroppingToolbarItemIdentifier,
                OrientationToolbarItemIdentifier,
                ShadingToolbarItemIdentifier,
                PerspectiveToolbarItemIdentifier,
                ConvolutionViewToolbarItemIdentifier,
                ClippingRangeViewToolbarItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                QTExportToolbarItemIdentifier,
                //												QTExportVRToolbarItemIdentifier,
                OrientationsViewToolbarItemIdentifier,
                ResetToolbarItemIdentifier,
                RevertToolbarItemIdentifier,
                ExportToolbarItemIdentifier,
                FlyThruToolbarItemIdentifier,
                nil];
    else
        return [NSArray arrayWithObjects:       ToolsToolbarItemIdentifier,
                ModeToolbarItemIdentifier,
                WLWWToolbarItemIdentifier,
                LODToolbarItemIdentifier,
                CaptureToolbarItemIdentifier,
                BlendingToolbarItemIdentifier,
                CroppingToolbarItemIdentifier,
                OrientationToolbarItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                QTExportToolbarItemIdentifier,
                OrientationsViewToolbarItemIdentifier,
                ResetToolbarItemIdentifier,
                ExportToolbarItemIdentifier,
                nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    if( [style isEqualToString:@"standard"])
    {
        NSMutableArray * a = [NSMutableArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
                              NSToolbarFlexibleSpaceItemIdentifier,
                              NSToolbarSpaceItemIdentifier,
                              NSToolbarSeparatorItemIdentifier,
                              WLWWToolbarItemIdentifier,
                              CLUTEditorsViewToolbarItemIdentifier,
                              PresetsPanelToolbarItemIdentifier,
                              LODToolbarItemIdentifier,
                              CaptureToolbarItemIdentifier,
                              CroppingToolbarItemIdentifier,
                              OrientationToolbarItemIdentifier,
                              ShadingToolbarItemIdentifier,
                              PerspectiveToolbarItemIdentifier,
                              OrientationsViewToolbarItemIdentifier,
                              ToolsToolbarItemIdentifier,
                              ModeToolbarItemIdentifier,
                              BlendingToolbarItemIdentifier,
                              MovieToolbarItemIdentifier,
                              StereoIdentifier,
                              QTExportToolbarItemIdentifier,
                              PhotosToolbarItemIdentifier,
                              //											QTExportVRToolbarItemIdentifier,
                              MailToolbarItemIdentifier,
                              ResetToolbarItemIdentifier,
                              RevertToolbarItemIdentifier,
                              ExportToolbarItemIdentifier,
                              FlyThruToolbarItemIdentifier,
                              ScissorStateToolbarItemIdentifier,
                              ROIManagerToolbarItemIdentifier,
                              ConvolutionViewToolbarItemIdentifier,
                              BackgroundColorViewToolbarItemIdentifier,
                              ClippingRangeViewToolbarItemIdentifier,
                              EngineToolbarItemIdentifier,
                              nil];
        
        
        
        for (id key in [PluginManager plugins])
        {
            if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarAllowedIdentifiersForVRViewer:)])
                [a addObjectsFromArray: [[[PluginManager plugins] objectForKey:key] toolbarAllowedIdentifiersForVRViewer: self]];
        }
        
        return a;
    }
    else
        return [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                NSToolbarSpaceItemIdentifier,
                NSToolbarSeparatorItemIdentifier,
                WLWWToolbarItemIdentifier,
                CLUTEditorsViewToolbarItemIdentifier,
                LODToolbarItemIdentifier,
                CaptureToolbarItemIdentifier,
                CroppingToolbarItemIdentifier,
                OrientationToolbarItemIdentifier,
                OrientationsViewToolbarItemIdentifier,
                QTExportToolbarItemIdentifier,
                PhotosToolbarItemIdentifier,
                MailToolbarItemIdentifier,
                ResetToolbarItemIdentifier,
                RevertToolbarItemIdentifier,
                ExportToolbarItemIdentifier,
                BlendingToolbarItemIdentifier,
                EngineToolbarItemIdentifier,
                nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif
{
}

- (void) toolbarDidRemoveItem: (NSNotification *) notif
{
}

#pragma mark -

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
#ifdef EXPORTTOOLBARITEM
    return YES;
#endif
    
    BOOL enable = YES;
    
    if ([[toolbarItem itemIdentifier] isEqualToString: MovieToolbarItemIdentifier])
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
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSImage *im = [view nsimage:NO];
    
    [panel setCanSelectHiddenExtension:YES];
    [panel setAllowedFileTypes:@[@"jpg"]];
    
    panel.nameFieldStringValue = NSLocalizedString( @"3D VR Image", nil);
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSArray *representations;
        NSData *bitmapData;
        
        representations = [im representations];
        
        bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
        
        [bitmapData writeToURL:panel.URL atomically:YES];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
            [[NSWorkspace sharedWorkspace] openURL:panel.URL];
    }];
}


-(void) export2iPhoto:(id) sender
{
    Photos *ifoto;
    NSImage *im = [view nsimage:NO];
    
    NSArray *representations;
    NSData *bitmapData;
    
    representations = [im representations];
    
    bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
    
    NSString *path = [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"Horos.jpg"];
    [bitmapData writeToFile:path atomically:YES];
    
    ifoto = [[Photos alloc] init];
    [ifoto importInPhotos:@[path]];
    [ifoto release];
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSImage *im = [view nsimage:NO];
    
    [panel setCanSelectHiddenExtension:YES];
    [panel setAllowedFileTypes:@[@"tif"]];
    panel.nameFieldStringValue = NSLocalizedString( @"3D VR Image", nil);
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [[im TIFFRepresentation] writeToURL:panel.URL atomically:NO];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [[NSWorkspace sharedWorkspace] openURL:panel.URL];
    }];
}

- (void) exportDICOMFile:(id) sender
{
    [view exportDICOM];
}

// Fly Thru

- (VRView*) view
{
    return view;
}

- (IBAction) flyThruButtonMenu:(id) sender
{
    [self flyThruControllerInit: self];
    
    [[self flyThruController].stepsArrayController flyThruTag: [sender tag]];
}

- (IBAction) flyThruControllerInit:(id) sender
{
    //Only open 1 fly through controller
    if( [self flyThruController]) return;
    
    FTAdapter = [[VRFlyThruAdapter alloc] initWithVRController: self];
    FlyThruController *flyThruController = [[FlyThruController alloc] initWithFlyThruAdapter:FTAdapter];
    [FTAdapter release];
    [flyThruController loadWindow];
    [[flyThruController window] makeKeyAndOrderFront :sender];
    [flyThruController setWindow3DController: self];
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

- (void)recordFlyThru;
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if(now-flyThruRecordingTimeFrame<1.0) return;
    
    flyThruRecordingTimeFrame = now;
    [self flyThruControllerInit:self];
    [[self flyThruController].stepsArrayController flyThruTag:0];
}

// 3D points
- (void) add2DPoint: (float) x : (float) y : (float) z :(float*) mm
{
    RGBColor rgb;
    
    rgb.red = 0;
    rgb.green = 1;
    rgb.blue = 2;
    
    [self add2DPoint:x :y :z :mm :rgb];
}

- (void) add2DPoint: (float) x : (float) y : (float) z :(float*) mm :(RGBColor) rgb
{
    if (viewer2D)
    {
        DCMPix *firstDCMPix = [[viewer2D pixList] objectAtIndex: 0];
        
        // find the slice where we want to add the point
        long sliceNumber = (long) (z+0.5);
        
        if (sliceNumber>=0 && sliceNumber<[[viewer2D pixList] count])
        {
            // Create the new 2D Point ROI
            ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[firstDCMPix pixelSpacingX] :[firstDCMPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: firstDCMPix]] autorelease];
            
            if( rgb.red != 0 && rgb.green != 1 && rgb.blue != 2)
                new2DPointROI.rgbcolor = rgb;
            
            NSRect irect;
            irect.origin.x = x;
            irect.origin.y = y;
            irect.size.width = irect.size.height = 0;
            [new2DPointROI setROIRect:irect];
            [[viewer2D imageView] roiSet:new2DPointROI];
            // add the 2D Point ROI to the ROI list
            [[[viewer2D roiList] objectAtIndex: sliceNumber] addObject: new2DPointROI];
            // add the ROI to our list
            [roi2DPointsArray addObject:new2DPointROI];
            [sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:sliceNumber]];
            
            [x2DPointsArray addObject:[NSNumber numberWithFloat:mm[ 0]]];
            [y2DPointsArray addObject:[NSNumber numberWithFloat:mm[ 1]]];
            [z2DPointsArray addObject:[NSNumber numberWithFloat:mm[ 2]]];
            
            // notify the change
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object: new2DPointROI userInfo: nil];
        }
    }
}

- (ViewerController*) viewer
{
    return viewer2D;
}

- (void) remove2DPoint: (float) x : (float) y : (float) z
{
    if (viewer2D)
    {
        long cur2DPointIndex = 0;
        BOOL found = NO;
        DCMPix *firstDCMPix = [[viewer2D pixList] objectAtIndex: 0];
        
        x /= [self factor];
        y /= [self factor];
        z /= [self factor];
        
        NSLog( @"%f %f %f", x, y, z);
        
        while(!found && cur2DPointIndex<[roi2DPointsArray count])
        {
            float sx = [[x2DPointsArray objectAtIndex:cur2DPointIndex] floatValue];
            float sy = [[y2DPointsArray objectAtIndex:cur2DPointIndex] floatValue];
            float sz = [[z2DPointsArray objectAtIndex:cur2DPointIndex] floatValue];
            
            NSLog( @"%f %f %f", sx, sy, sz);
            
            if(	(x < sx + [firstDCMPix pixelSpacingX] && x > sx - [firstDCMPix pixelSpacingX]) &&
               (y < sy + [firstDCMPix pixelSpacingY] && y > sy - [firstDCMPix pixelSpacingY]) &&
               (z < sz + [firstDCMPix sliceInterval] && z > sz - [firstDCMPix sliceInterval]))
            {
                found = YES;
            }
            else
            {
                cur2DPointIndex++;
            }
        }
        if (found && cur2DPointIndex<[roi2DPointsArray count])
        {
            // the 2D Point ROI object
            ROI * cur2DPoint;
            cur2DPoint = [roi2DPointsArray objectAtIndex:cur2DPointIndex];
            // remove 2D Point on 2D viewer2D
            [[[viewer2D roiList] objectAtIndex: [[sliceNumber2DPointsArray objectAtIndex:cur2DPointIndex] longValue]] removeObject:cur2DPoint];
            //notify
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:cur2DPoint userInfo: nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateViewNotification object:nil userInfo: nil];
            
            // remove 2D point in our list
            // done by remove3DPoint (through notification)
        }
    }
}

- (void) refresh3DPoints
{
    // First remove all non-available points
    NSMutableArray *roisToBeRemoved = [NSMutableArray array];
    for( ROI *r in roi2DPointsArray)
    {
        BOOL found = NO;
        
        for( NSArray *a in [viewer2D roiList])
        {
            if( [a containsObject: r])
            {
                found = YES;
                break;
            }
        }
        
        if( found == NO)
            [roisToBeRemoved addObject: r];
    }
    for( ROI *r in roisToBeRemoved)
        [self remove3DPointROI: r];
    
    // Add all non-displayed points
    for( NSArray *a in [viewer2D roiList])
    {
        for( ROI *r in a)
        {
            if( [r type] == t2DPoint)
            {
                if( [roi2DPointsArray containsObject: r] == NO)
                {
                    float location[ 3];
                    double x, y, z;
                    
                    DCMPix *pix = [r pix];
                    
                    if( pix == nil)
                        pix = [[viewer2D pixList] objectAtIndex: [[viewer2D imageView] curImage]];
                    
                    [pix convertPixX: [[[r points] objectAtIndex:0] x] pixY: [[[r points] objectAtIndex:0] y] toDICOMCoords: location pixelCenter: YES];
                    
                    x = location[ 0];
                    y = location[ 1];
                    z = location[ 2];
                    
                    // add the 3D Point to the view
                    [[self view] add3DPoint:  x : y : z : r.thickness :r.rgbcolor.red/65535. :r.rgbcolor.green/65535. :r.rgbcolor.blue/65535.];
                    [[self view] setNeedsDisplay:YES];
                    
                    // add the 2D Point to our list
                    [roi2DPointsArray addObject: r];
                    [sliceNumber2DPointsArray addObject: [NSNumber numberWithLong:[[viewer2D imageView] curImage]]];
                    [x2DPointsArray addObject: [NSNumber numberWithFloat:x]];
                    [y2DPointsArray addObject: [NSNumber numberWithFloat:y]];
                    [z2DPointsArray addObject: [NSNumber numberWithFloat:z]];
                }
            }
        }
    }
}

- (void) add3DPoint: (NSNotification*) note
{
    [self refresh3DPoints];
    
    // Add the new ROI
    ROI	*addedROI = [note object];
    
    if( [roi2DPointsArray containsObject: addedROI])
        [self remove3DPoint: note];
    
    if ([addedROI type] == t2DPoint)
    {
        float location[ 3];
        double x, y, z;
        
        DCMPix *pix = [addedROI pix];
        
        if( pix == nil)
            pix = [[viewer2D pixList] objectAtIndex: [[viewer2D imageView] curImage]];
        
        [pix convertPixX: [[[addedROI points] objectAtIndex:0] x] pixY: [[[addedROI points] objectAtIndex:0] y] toDICOMCoords: location pixelCenter: YES];
        
        x = location[ 0];
        y = location[ 1];
        z = location[ 2];
        
        // add the 3D Point to the view
        [[self view] add3DPoint:  x : y : z : addedROI.thickness :addedROI.rgbcolor.red/65535. :addedROI.rgbcolor.green/65535. :addedROI.rgbcolor.blue/65535.];
        [[self view] setNeedsDisplay:YES];
        
        // add the 2D Point to our list
        [roi2DPointsArray addObject:addedROI];
        [sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:[[viewer2D imageView] curImage]]];
        [x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
        [y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
        [z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
    }
}

- (void) remove3DPointROI: (ROI*) removedROI
{
    long cur2DPointIndex = 0;
    BOOL found = NO;
    
    while(!found && cur2DPointIndex<[roi2DPointsArray count])
    {
        if(	[roi2DPointsArray objectAtIndex:cur2DPointIndex]==removedROI)
        {
            found = YES;
        }
        else
        {
            cur2DPointIndex++;
        }
    }
    
    if (found && cur2DPointIndex<[roi2DPointsArray count])
    {
        // remove the 3D Point in the SR view
        [[self view] remove3DPointAtIndex: cur2DPointIndex];
        [[self view] setNeedsDisplay:YES];
        // remove 2D point in our list
        [roi2DPointsArray removeObjectAtIndex:cur2DPointIndex];
        [sliceNumber2DPointsArray removeObjectAtIndex:cur2DPointIndex];
        [x2DPointsArray removeObjectAtIndex:cur2DPointIndex];
        [y2DPointsArray removeObjectAtIndex:cur2DPointIndex];
        [z2DPointsArray removeObjectAtIndex:cur2DPointIndex];
    }
}

- (void) remove3DPoint: (NSNotification*) note
{
    ROI	*removedROI = [note object];
    
    if ([removedROI type] == t2DPoint) // 2D Points
    {
        [self remove3DPointROI: removedROI];
    }
}

- (NSMutableArray*) roi2DPointsArray
{
    return roi2DPointsArray;
}

- (NSMutableArray*) sliceNumber2DPointsArray
{
    return sliceNumber2DPointsArray;
}

- (float) factor
{
    return [view factor];
}

// ROIs Volumes
#ifdef roi3Dvolume
- (void) computeROIVolumes
{
    NSArray *roiNames = [viewer2D roiNames];
    
    for(int m=0; m<maxMovieIndex; m++)
    {
        [roiVolumes[m] removeAllObjects];
        
        for(NSUInteger i=0; i<[roiNames count]; i++)
        {
            NSArray *roisWithCurrentName = [viewer2D roisWithName:[roiNames objectAtIndex:i] forMovieIndex:m];
            ROIVolume *volume = [[[ROIVolume alloc] initWithViewer: viewer2D] autorelease];
            [volume setFactor:[self factor]];
            [volume setROIList:roisWithCurrentName];
            if ([volume isVolume])
            {
                [roiVolumes[m] addObject:volume];
            }
        }
    }
}

- (NSMutableArray*) roiVolumes
{
    return roiVolumes[curMovieIndex];
}

//- (void) displayROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	//NSLog(@"[[roiVolumes objectAtIndex:index] name] : %@", [[roiVolumes objectAtIndex:index] name]);
//	viewRenderer->AddActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}
//
//- (void) hideROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	viewRenderer->RemoveActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}

- (void) displayROIVolume: (ROIVolume*) v
{
    vtkRenderer *viewRenderer = [view renderer];
    viewRenderer->AddActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}
- (void) hideROIVolume: (ROIVolume*) v
{
    vtkRenderer *viewRenderer = [view renderer];
    if( [v isRoiVolumeActorComputed])
        viewRenderer->RemoveActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}

- (void) displayROIVolumes
{
    for(int m=0; m<maxMovieIndex; m++)
    {
        for(NSUInteger i=0; i<[roiVolumes[m] count]; i++)
        {
            [self hideROIVolume:[roiVolumes[m] objectAtIndex:i]];
        }
    }
    
    for(NSUInteger i=0; i<[roiVolumes[curMovieIndex] count]; i++)
    {
        if([[roiVolumes[curMovieIndex] objectAtIndex:i] visible])
        {
            [self displayROIVolume:[roiVolumes[curMovieIndex] objectAtIndex:i]];
        }
    }
}

- (IBAction) roiGetManager:(id) sender
{
    //NSLog(@"roiGetManager");
    //NSLog(@"-[roiVolumes count] : %d", [roiVolumes count]);
    BOOL	found = NO;
    NSArray *winList = [NSApp windows];
    
    for(NSUInteger i = 0; i < [winList count]; i++)
    {
        if([[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROIVolumeManager"])
        {
            found = YES;
        }
    }
    if(!found)
    {
        ROIVolumeManagerController *manager = [[ROIVolumeManagerController alloc] initWithViewer: self];
        if(manager)
        {
            [manager showWindow:self];
            [[manager window] makeKeyAndOrderFront:self];
        }
    }
}

- (void)updateROIVolume:(NSNotification*)notification;
{
    ROIVolume* changedROIVolume = [notification object];
    for(int m=0; m<maxMovieIndex; m++)
    {
        BOOL found = NO;
        int index;
        for(NSUInteger i=0; i<[roiVolumes[m] count] && !found; i++)
        {
            found = changedROIVolume==[roiVolumes[m] objectAtIndex:i];
            index = i;
        }
        
        if(found)
        {
            for(int n=0; n<maxMovieIndex; n++)
            {
                if(![[[[roiVolumes[n] objectAtIndex:index] displayProperties] objectForKey:[[notification userInfo] objectForKey:@"key"]] isEqualTo:[[changedROIVolume displayProperties] objectForKey:[[notification userInfo] objectForKey:@"key"]]])
                {
                    [(ROIVolume*)[roiVolumes[n] objectAtIndex:index] setDisplayProperties:[changedROIVolume displayProperties]];
                }
            }
        }
    }
}

#endif

- (ViewerController*) viewer2D {return viewer2D;}

- (void) showWindow:(id) sender
{
    [super showWindow: sender];
    
    if( [style isEqualToString:@"panel"] == NO) [view squareView: self];
}

- (DicomStudy *)currentStudy
{
    return [viewer2D currentStudy];
}
- (DicomSeries *)currentSeries
{
    return [viewer2D currentSeries];
}

- (DicomImage *)currentImage
{
    return [viewer2D currentImage];
}

-(float)curWW
{
    return [viewer2D curWW];
}

-(float)curWL
{
    return [viewer2D curWL];
}

- (NSString *)curCLUTMenu
{
    return curCLUTMenu;
}

- (void)setCurCLUTMenu:(NSString*)clut;
{
    if(curCLUTMenu) [curCLUTMenu release];
    curCLUTMenu = clut;
    [curCLUTMenu retain];
    [[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
}

- (NSDrawer*)clutOpacityDrawer;
{
    return clutOpacityDrawer;
}

- (void)showCLUTOpacityPanel:(id)sender;
{
    [clutOpacityView setVolumePointer:[[pixList[0] objectAtIndex: 0] fImage] width:[[pixList[0] objectAtIndex: 0] pwidth] height:[[pixList[0] objectAtIndex: 0] pheight] numberOfSlices:[pixList[0] count]];
    [self computeMinMax];
    [clutOpacityView setHUmin:minimumValue HUmax:maximumValue];
    
    [[clutOpacityView window] setBackgroundColor:[NSColor blackColor]];
    [clutOpacityDrawer setTrailingOffset:[clutOpacityDrawer leadingOffset]];
    if([clutOpacityDrawer state]==NSDrawerClosedState)
        [clutOpacityDrawer openOnEdge:NSMinYEdge];
    else
        [clutOpacityDrawer close];
    [clutOpacityView callComputeHistogram];
    [clutOpacityView addCurveIfNeeded];
    [clutOpacityView updateView];
    [clutOpacityView setCLUTtoVRView:NO];
    if(![view advancedCLUT])[self setCurCLUTMenu:NSLocalizedString(@"16-bit CLUT", nil)];
    [OpacityPopup setEnabled:NO];
}

- (void)loadAdvancedCLUTOpacity:(id)sender;
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask)
    {
        NSBeginAlertSheet(NSLocalizedString(@"Remove a Color Look Up Table", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window],
                          self, @selector(delete16BitCLUT:returnCode:contextInfo:), NULL, [sender title], NSLocalizedString( @"Are you sure you want to delete this CLUT : '%@'", nil), [sender title]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
    }
    else
    {
        [clutOpacityView loadFromFileWithName:[sender title]];
        if(curCLUTMenu) [curCLUTMenu release];
        curCLUTMenu = [[sender title] retain];
        [clutOpacityView setCLUTtoVRView:NO];
        [clutOpacityView updateView];
        //		[[[clutPopup menu] itemAtIndex:0] setTitle:[sender title]];
        [self setCurCLUTMenu:[sender title]];
        [OpacityPopup setEnabled:NO];
    }
}

- (void)UpdateCLUTMenu:(NSNotification*)note
{
    [super UpdateCLUTMenu:note];
    
    // path 1 : /Horos Data/CLUTs/
    NSString *path = [[[BrowserController currentBrowser] database] clutsDirPath];
    // path 2 : /resources_bundle_path/CLUTs/
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path.lastPathComponent];
    
    NSMutableArray *paths = [NSMutableArray arrayWithObjects:path, bundlePath, nil];
    
    NSMutableArray *clutArray = [NSMutableArray array];
    BOOL isDir;
    
    for (NSUInteger j=0; j<[paths count]; j++)
    {
        if([[NSFileManager defaultManager] fileExistsAtPath:[paths objectAtIndex:j] isDirectory:&isDir] && isDir)
        {
            NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[paths objectAtIndex:j] error:NULL];
            for (NSUInteger i=0; i<[content count]; i++)
            {
                if( [[content objectAtIndex:i] length] > 0)
                {
                    if( [[content objectAtIndex:i] characterAtIndex: 0] != '.')
                    {
                        NSDictionary* clut = [CLUTOpacityView presetFromFileWithName:[[content objectAtIndex:i] stringByDeletingPathExtension]];
                        if(clut)
                        {
                            [clutArray addObject:[[content objectAtIndex:i] stringByDeletingPathExtension]];
                        }
                    }
                }
            }
        }
    }
    
    [clutArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMenuItem *item;
    item = [[clutPopup menu] insertItemWithTitle: NSLocalizedString(@"8-bit CLUTs", nil) action:@selector(noAction:) keyEquivalent:@"" atIndex:3];
    
    if( [clutArray count])
    {
        [[clutPopup menu] insertItem:[NSMenuItem separatorItem] atIndex:[[clutPopup menu] numberOfItems]-2];
        
        item = [[clutPopup menu] insertItemWithTitle: NSLocalizedString(@"16-bit CLUTs", nil) action:@selector(noAction:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
        
        for (NSUInteger i=0; i<[clutArray count]; i++)
        {
            item = [[clutPopup menu] insertItemWithTitle:[clutArray objectAtIndex:i] action:@selector(loadAdvancedCLUTOpacity:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
            if([view isRGB])
                [item setEnabled:NO];
        }
    }
    
    item = [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"16-bit CLUT Editor", nil) action:@selector(showCLUTOpacityPanel:) keyEquivalent:@""];
    if([[pixList[ 0] objectAtIndex:0] isRGB])
        [item setEnabled:NO];
}

- (void)delete16BitCLUT:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
{
    if (returnCode==1 && ![view isRGB])
    {
        NSMutableString *path = [NSMutableString stringWithString:[[[BrowserController currentBrowser] database] clutsDirPath]];
        [path appendString:(id)contextInfo];
        [path appendString:@".plist"];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path])
            [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
        else
            NSLog( @"**** Error: CLUT plist not found!");
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object:curCLUTMenu userInfo: nil];
    }
}

- (void)drawerDidClose:(NSNotification *)sender
{
    [[self window] zoom:self];
}

- (void)drawerDidOpen:(NSNotification *)sender
{
    [[self window] zoom:self];
}

-(IBAction) endEditGrowingRegion:(id) sender
{
    [growingRegionWindow orderOut: sender];
    
    [NSApp endSheet: growingRegionWindow returnCode: [sender tag]];
    
    if( [sender tag])
    {
        
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setFloat: 1125 forKey: @"VRGrowingRegionValue"];
        [[NSUserDefaults standardUserDefaults] setFloat: 1750 forKey: @"VRGrowingRegionInterval"];
    }
}

- (IBAction) editGrowingRegion:(id) sender
{
    [[NSUserDefaults standardUserDefaults] setFloat: [[pixList[ 0] objectAtIndex: 0] minValueOfSeries] forKey: @"VRGrowingRegionMin"];
    [[NSUserDefaults standardUserDefaults] setFloat: [[pixList[ 0] objectAtIndex: 0] maxValueOfSeries] forKey: @"VRGrowingRegionMax"];
    
    [NSApp beginSheet: growingRegionWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

#pragma mark-
#pragma mark 3D presets

#pragma mark save current

- (NSMutableDictionary*)getCurrent3DSettings;
{
    //window level & width
    float iwl, iww;
    [view getWLWW:&iwl :&iww];
    //background color
    NSColor *backgroundColor = [view backgroundColor];
    //shading
    NSDictionary *shading = [[shadingsPresetsController selectedObjects] lastObject];
    NSString *shadingPresetName = [shading valueForKey:@"name"];
    //CLUT
    BOOL isAdvancedCLUT = [view advancedCLUT];
    NSString *clut = curCLUTMenu;
    //projection
    int projection = [[view valueForKey:@"projectionMode"] intValue];
    
    NSMutableDictionary *presetDictionary = [NSMutableDictionary dictionaryWithCapacity:6];
    [presetDictionary setObject:[NSNumber numberWithFloat:iwl] forKey:@"wl"];
    [presetDictionary setObject:[NSNumber numberWithFloat:iww] forKey:@"ww"];
    
    NSColor *color = [backgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [presetDictionary setObject:[NSNumber numberWithFloat:[color redComponent]] forKey:@"backgroundColorRedComponent"];
    [presetDictionary setObject:[NSNumber numberWithFloat:[color greenComponent]] forKey:@"backgroundColorGreenComponent"];
    [presetDictionary setObject:[NSNumber numberWithFloat:[color blueComponent]] forKey:@"backgroundColorBlueComponent"];
    
    [presetDictionary setObject:[NSNumber numberWithBool:[shadingCheck state]] forKey:@"useShading"];
    [presetDictionary setObject:shadingPresetName forKey:@"shading"];
    [presetDictionary setObject:[NSNumber numberWithBool:isAdvancedCLUT] forKey:@"advancedCLUT"];
    [presetDictionary setObject:clut forKey:@"CLUT"];
    if([clut isEqualToString:NSLocalizedString(@"16-bit CLUT", nil)] || [clut isEqualToString: @"16-bit CLUT"])
    {
        NSArray *curves = [clutOpacityView convertCurvesForPlist];
        NSArray *colors = [clutOpacityView convertPointColorsForPlist];
        [presetDictionary setObject:curves forKey:@"16bitClutCurves"];
        [presetDictionary setObject:colors forKey:@"16bitClutColors"];
    }
    if( appliedConvolutionFilters)
        [presetDictionary setObject:appliedConvolutionFilters forKey:@"convolutionFilters"];
    
    [presetDictionary setObject:[NSNumber numberWithInt:projection] forKey:@"projection"];
    [presetDictionary setObject:curOpacityMenu forKey:@"opacity"];
    
    return presetDictionary;
}

- (IBAction)save3DSettings:(id)sender;
{
    if( panelInstantiated == NO)
        [self showPresetsPanel];
    
    if( save3DSettingsWindow == nil)
        return;
    
    NSMutableDictionary *presetDictionary = [self getCurrent3DSettings];
    
    if([[sender className] isEqualToString:@"NSMenuItem"])
    {
        if([[presetDictionary objectForKey:@"advancedCLUT"] boolValue])
        {
            [settingsCLUTTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"CLUT: %@ (16-bit)", nil), [presetDictionary objectForKey:@"CLUT"]]];
            [settingsOpacityTextField setStringValue:NSLocalizedString(@"Opacity: (defined in the CLUT)", nil)];
        }
        else
        {
            [settingsCLUTTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"CLUT: %@ (8-bit)", nil), [presetDictionary objectForKey:@"CLUT"]]];
            [settingsOpacityTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Opacity: %@", nil), [presetDictionary objectForKey:@"opacity"]]];
        }
        
        if(![[presetDictionary objectForKey:@"useShading"] boolValue])
            [settingsShadingsTextField setStringValue:NSLocalizedString(@"Shadings: Off", nil)];
        else
            [settingsShadingsTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Shadings: %@", nil), [presetDictionary objectForKey:@"shading"]]];
        
        [settingsWLWWTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"WL: %.0f WW: %.0f", nil), [[presetDictionary objectForKey:@"wl"] floatValue], [[presetDictionary objectForKey:@"ww"] floatValue]]];
        
        NSMutableString *convolutionFiltersString = [NSMutableString stringWithString:@""];
        NSArray *filters = [presetDictionary objectForKey:@"convolutionFilters"];
        if([filters count]>1) [convolutionFiltersString appendString:NSLocalizedString(@"Filters", nil)];
        else [convolutionFiltersString appendString:NSLocalizedString(@"Filter", nil)];
        [convolutionFiltersString appendString:@": "];
        
        if([filters count]>0)
        {
            for(NSUInteger i=0; i<(long)[filters count]-1; i++)
            {
                [convolutionFiltersString appendString:[filters objectAtIndex:i]];
                [convolutionFiltersString appendString:@", "];
            }
            
            [convolutionFiltersString appendString:[filters objectAtIndex:(long)[filters count]-1]];
            [convolutionFiltersString appendString:@"."];
        }
        else
        {
            [convolutionFiltersString appendString:NSLocalizedString(@"(none).", nil)];
        }
        [settingsConvolutionFilterTextField setStringValue:convolutionFiltersString];
        
        [settingsBackgroundColorTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Background: red:%.0f%%, green:%.0f%%, blue:%.0f%%", nil), 100*[[presetDictionary objectForKey:@"backgroundColorRedComponent"] floatValue], 100*[[presetDictionary objectForKey:@"backgroundColorGreenComponent"] floatValue], 100*[[presetDictionary objectForKey:@"backgroundColorBlueComponent"] floatValue]]];
        
        int proj = [[presetDictionary objectForKey:@"projection"] intValue];
        NSString *projectionName = nil;
        if(proj==0)
            projectionName = NSLocalizedString(@"Perspective", nil);
        else if(proj==1)
            projectionName = NSLocalizedString(@"Parallel", nil);
        else if(proj==2)
            projectionName = NSLocalizedString(@"Endoscopy", nil);
        [settingsProjectionTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Projection: %@", nil), projectionName]];
        
        [settingsGroupPopUpButton removeAllItems];
        
        NSArray *groups = [self find3DSettingsGroups];
        for(NSUInteger i=0; i<[groups count]; i++)
        {
            [settingsGroupPopUpButton addItemWithTitle:[groups objectAtIndex:i]];
        }
        if([groups count]>0)
            [[settingsGroupPopUpButton menu] addItem:[NSMenuItem separatorItem]];
        [settingsGroupPopUpButton addItemWithTitle:NSLocalizedString(@"New group", nil)];
        
        if([presetsPanel isVisible])
            [settingsGroupPopUpButton selectItemWithTitle:[[presetsGroupPopUpButton selectedItem] title]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:NSControlTextDidChangeNotification object:nil];
        
        [self show3DSettingsNewGroupTextField:[settingsGroupPopUpButton selectedItem]];
        
        [NSApp beginSheet:save3DSettingsWindow modalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    else if([[sender className] isEqualToString:@"NSButton"])
    {
        [self close3DSettingsSavePanel:sender];
        NSString *settingsName = [settingsNameTextField stringValue];
        NSString *groupName;
        if(![settingsNewGroupNameTextField isHidden]) groupName = [settingsNewGroupNameTextField stringValue];
        else groupName = [[settingsGroupPopUpButton selectedItem] title];
        
        [self save3DSettings:presetDictionary WithName:settingsName group:groupName];
        [self updatePresetsGroupPopUpButtonSelectingGroupWithName:groupName];
    }
}

- (IBAction)enable3DSettingsSaveButton:(id)sender;
{
    BOOL condition = [[settingsNameTextField stringValue] length] > 0;
    if(![settingsNewGroupNameTextField isHidden]) condition &= [[settingsNewGroupNameTextField stringValue] length] > 0;
    
    if(condition)
        [settingsSaveButton setEnabled:YES];
    else
        [settingsSaveButton setEnabled:NO];
}

- (void)controlTextDidChange:(NSNotification*)notification;
{
    if([[notification object] isEqualTo:settingsNameTextField] || [[notification object] isEqualTo:settingsNewGroupNameTextField])
        [self enable3DSettingsSaveButton:self];
}

- (IBAction)show3DSettingsNewGroupTextField:(id)sender;
{
    if([[sender title] isEqualToString:NSLocalizedString(@"New group", nil)])
    {
        [settingsNewGroupNameTextField setHidden:NO];
        [settingsNewGroupNameLabelTextField setHidden:NO];
    }
    else
    {
        [settingsNewGroupNameTextField setHidden:YES];
        [settingsNewGroupNameLabelTextField setHidden:YES];
    }
    [self enable3DSettingsSaveButton:self];
}

- (IBAction)close3DSettingsSavePanel:(id)sender;
{
    [save3DSettingsWindow orderOut:sender];
    [NSApp endSheet:save3DSettingsWindow];
}

- (void)save3DSettings:(NSMutableDictionary*)settings WithName:(NSString*)name group:(NSString*)groupName;
{
    [settings setObject:name forKey:@"name"];
    [settings setObject:groupName forKey:@"groupName"];
    
    NSString *path = [[[BrowserController currentBrowser] database] presetsDirPath];
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    
    path = [path stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"plist"]];
    [settings writeToFile:path atomically:YES];
}

#pragma mark presets generic methods

- (NSArray*)find3DSettingsGroups;
{
    // path 1 : /OsirirX Data/CLUTs/
    NSString *path1 = [[[BrowserController currentBrowser] database] presetsDirPath];
    // path 2 : /resources_bundle_path/CLUTs/
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path1.lastPathComponent];
    
    NSArray *paths = @[path1, bundlePath];
    
    NSMutableArray *settingsGroups = [NSMutableArray array];
    
    BOOL isDir = YES;
    
    for (NSUInteger j=0; j<[paths count]; j++)
    {
        NSString *path = [paths objectAtIndex:j];
        if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
            NSArray *settingsFiles = [[NSFileManager defaultManager] subpathsAtPath:path];
            
            for(NSUInteger i=0; i<[settingsFiles count]; i++)
            {
                NSString *filePath = [path stringByAppendingPathComponent:[settingsFiles objectAtIndex:i]];
                if([[filePath pathExtension] isEqualToString:@"plist"])
                {
                    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:[settingsFiles objectAtIndex:i]]];
                    if(settings)
                    {
                        if([[settings allKeys] containsObject:@"groupName"])
                        {
                            if(![settingsGroups containsObject:[settings objectForKey:@"groupName"]])
                                [settingsGroups addObject:[settings objectForKey:@"groupName"]];
                        }
                        [settings release];
                    }
                }
            }
        }
    }
    return [settingsGroups sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];;
}
NSInteger sort3DSettingsDict(id preset1, id preset2, void *context)
{
    NSString *name1 = [preset1 objectForKey:@"name"];
    NSString *name2 = [preset2 objectForKey:@"name"];
    return [name1 caseInsensitiveCompare:name2];
}

- (NSArray*)find3DSettingsForGroupName:(NSString*)groupName;
{
    // path 1 : /OsirirX Data/CLUTs/
    NSString *path1 = [[[BrowserController currentBrowser] database] presetsDirPath];
    // path 2 : /resources_bundle_path/CLUTs/
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path1.lastPathComponent];
    
    NSArray *paths = @[path1, bundlePath];
    
    NSMutableArray *settingsList = [NSMutableArray array];
    
    BOOL isDir = YES;
    int j;
    
    for (j=0; j<[paths count]; j++)
    {
        NSString *path = [paths objectAtIndex:j];
        if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
            NSArray *settingsFiles = [[NSFileManager defaultManager] subpathsAtPath:path];
            int i;
            for(i=0; i<[settingsFiles count]; i++)
            {
                NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:[settingsFiles objectAtIndex:i]]];
                if(settings)
                {
                    if([[settings allKeys] containsObject:@"groupName"])
                    {
                        if([[settings objectForKey:@"groupName"] isEqualToString:groupName])
                        {
                            [settingsList addObject:settings];
                        }
                    }
                    [settings release];
                }
            }
        }
    }
    
    presetPageMax = ((long)[settingsList count]-1) / [presetPreviewArray count];
    [self enablePresetPageButtons];
    
    return [settingsList sortedArrayUsingFunction:sort3DSettingsDict context:NULL];
}

#pragma mark load preset

- (void)updatePresetsGroupPopUpButton;
{
    [self updatePresetsGroupPopUpButtonSelectingGroupWithName:@""];
}

- (void)updatePresetsGroupPopUpButtonSelectingGroupWithName:(NSString*)groupName;
{
    [presetsGroupPopUpButton setEnabled:YES];
    
    [presetsGroupPopUpButton removeAllItems];
    NSArray *groups = [self find3DSettingsGroups];
    
    for(NSUInteger i=0; i<[groups count]; i++)
        [presetsGroupPopUpButton addItemWithTitle:[groups objectAtIndex:i]];
    
    if([presetsGroupPopUpButton numberOfItems]<1)
    {
        [presetsGroupPopUpButton addItemWithTitle:NSLocalizedString(@"No Groups", nil)];
        [presetsGroupPopUpButton setEnabled:NO];
    }
    
    if(![groupName isEqualToString:@""])
        [presetsGroupPopUpButton selectItemWithTitle:groupName];
    
    [self displayPresetsForSelectedGroup:presetsGroupPopUpButton];
}

- (void)load3DSettings;
{
    [self load3DSettings:self];
}

- (IBAction)load3DSettings:(id)sender;
{
    [[NSUserDefaults standardUserDefaults] setObject:[presetsGroupPopUpButton titleOfSelectedItem] forKey:@"LAST_3D_PRESET"];
    
    if([[sender className] isEqualToString:@"NSMenuItem"] || [[sender className] isEqualToString:@"NSToolbarItem"])
    {
        [self showPresetsPanel];
    }
    else if([sender isEqualTo:presetsApplyButton])
    {
        if([presetsPanel isVisible])
            [presetsPanel close];
        
        [self load3DSettings];
    }
    else if([sender isEqualTo:self])
    {
        if( firstTimeDisplayed)
            [presetsPanel close];
        
        firstTimeDisplayed = NO;
        
        WaitRendering *www = [[WaitRendering alloc] init:NSLocalizedString(@"Applying 3D Preset...", nil)];
        [www start];
        
        @try
        {
            if( [selectedPresetPreview index] < 0) NSLog( @" ******** if( [selectedPresetPreview index] < 0)");
            
            NSDictionary *preset = [[self find3DSettingsForGroupName:[presetsGroupPopUpButton titleOfSelectedItem]] objectAtIndex:[selectedPresetPreview index]];
            
            // CLUT
            NSString *clut = [preset objectForKey:@"CLUT"];
            
            BOOL advancedCLUT = [[preset objectForKey:@"advancedCLUT"] boolValue];
            if(!advancedCLUT)
            {
                [self ApplyCLUTString:clut];
                
                // opacity
                [self ApplyOpacityString:[preset objectForKey:@"opacity"]];
                
                // window level/width
                float iwl = [[preset objectForKey:@"wl"] floatValue];
                float iww = [[preset objectForKey:@"ww"] floatValue];
                [self setWLWW:iwl :iww];
                
            }
            else
            {
                if([clut isEqualToString:NSLocalizedString(@"16-bit CLUT", nil)] || [clut isEqualToString: @"16-bit CLUT"])
                {
                    NSMutableArray *curves = [CLUTOpacityView convertCurvesFromPlist:[preset objectForKey:@"16bitClutCurves"]];
                    NSMutableArray *colors = [CLUTOpacityView convertPointColorsFromPlist:[preset objectForKey:@"16bitClutColors"]];
                    
                    NSMutableDictionary *clutDict = [NSMutableDictionary dictionaryWithCapacity:2];
                    [clutDict setObject:curves forKey:@"curves"];
                    [clutDict setObject:colors forKey:@"colors"];
                    
                    [clutOpacityView setCurves:curves];
                    [clutOpacityView setPointColors:colors];
                    
                    [view setAdvancedCLUT:clutDict lowResolution:NO];
                }
                else
                {
                    [clutOpacityView loadFromFileWithName:clut];
                    [clutOpacityView setCLUTtoVRView:NO];
                    [clutOpacityView updateView];
                    if(curCLUTMenu) [curCLUTMenu release];
                    curCLUTMenu = [clut retain];
                    [[[clutPopup menu] itemAtIndex:0] setTitle:clut];
                    [OpacityPopup setEnabled:NO];
                }
                
                if([clutOpacityDrawer state] == NSDrawerClosedState)
                {
                    [self showCLUTOpacityPanel: self];
                }
                
                [clutOpacityView selectCurveAtIndex:0];
                [clutOpacityView updateView];
            }
            
            // shadings
            if([[preset objectForKey:@"useShading"] boolValue])
            {
                NSString *shadingName = [preset objectForKey:@"shading"];
                NSArray	*shadings = [shadingsPresetsController arrangedObjects];
                int i;
                for( i = 0; i < [shadings count]; i++)
                {
                    NSDictionary *dict = [shadings objectAtIndex:i];
                    if([[dict valueForKey:@"name"] isEqualToString:shadingName])
                    {
                        [shadingsPresetsController setSelectedObjects:[NSArray arrayWithObject:dict]];
                        break;
                    }
                }
                [self applyShading:self];
                if([shadingCheck state]==NSOffState)
                {
                    [shadingCheck setState:NSOnState];
                    [view switchShading:shadingCheck];
                }
            }
            else
            {
                if([shadingCheck state]==NSOnState)
                {
                    [shadingCheck setState:NSOffState];
                    [view switchShading:shadingCheck];
                }
            }
            
            // projection
            int projection = [[preset objectForKey:@"projection"] intValue];
            view.projectionMode = projection;
            
            // background color
            float red = [[preset objectForKey:@"backgroundColorRedComponent"] floatValue];
            float green = [[preset objectForKey:@"backgroundColorGreenComponent"] floatValue];
            float blue = [[preset objectForKey:@"backgroundColorBlueComponent"] floatValue];
            [view changeColorWith:[NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0]];
            
            // convolution filter
            if([appliedConvolutionFilters count]==0)
            {
                NSArray *convolutionFilters = [preset objectForKey:@"convolutionFilters"];
                if([convolutionFilters count]>0)
                {
                    int i;
                    for(i=0; i<[convolutionFilters count]; i++)
                    {
                        //					[self prepareUndo];
                        [viewer2D ApplyConvString:[convolutionFilters objectAtIndex:i]];
                        [viewer2D applyConvolutionOnSource:self];
                        [appliedConvolutionFilters addObject:[convolutionFilters objectAtIndex:i]];
                    }
                    [self displayPresetsForSelectedGroup];
                }
            }
        }
        @catch (NSException *e)
        {
            NSLog( @"Applying 3d preset exception: %@", e);
        }
        [www end];
        [www close];
        [www autorelease];
    }
}

- (IBAction)displayPresetsForSelectedGroup:(id)sender;
{
    presetPageNumber = 0;
    [self displayPresetsForSelectedGroup];
}

- (void)displayPresetsForSelectedGroup;
{
    if([presetsGroupPopUpButton numberOfItems]<1) return;
    NSArray *settingsList = [self find3DSettingsForGroupName:[presetsGroupPopUpButton titleOfSelectedItem]];
    
    [numberOfPresetInGroupTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Number of Presets: %d", nil), [settingsList count]]];
    
    int i, n;
    
    // fill the thumbnails
    n = 0;
    for(i=0; i<[presetPreviewArray count] && n<[settingsList count]; i++)
    {
        n = presetPageNumber*[presetPreviewArray count] + i;
        if(n<[settingsList count])
        {
            [(NSTextField*)[presetNameArray objectAtIndex:i] setStringValue:[NSString stringWithFormat:@"%d. %@", n+1,[[settingsList objectAtIndex:n] objectForKey:@"name"]]];
            [(VRPresetPreview*)[presetPreviewArray objectAtIndex:i] setIsEmpty:NO];
            
            [(VRPresetPreview*)[presetPreviewArray objectAtIndex:i] setVtkCamera: [view vtkCamera]];
            
            //			double a[ 6];
            //			if( [view croppingBox: a])
            //				[(VRPresetPreview*)[presetPreviewArray objectAtIndex:i] setCroppingBox: a];
            
            [self load3DSettingsDictionary:[settingsList objectAtIndex:n] forPreview:[presetPreviewArray objectAtIndex:i]];
            
            [(VRPresetPreview*)[presetPreviewArray objectAtIndex:i] setIndex:n];
            [(VRPresetPreview*)[presetPreviewArray objectAtIndex:i] setLOD:1.0];
        }
    }
    
    // the others will be black
    
    if(n>=[settingsList count]) i--;
    
    while(i<[presetPreviewArray count])
    {
        [(NSTextField*)[presetNameArray objectAtIndex:i] setStringValue:@""];
        [(VRPresetPreview*)[presetPreviewArray objectAtIndex:i] setIsEmpty:YES];
        i++;
    }
    
    if([presetPreviewArray count]) [(VRPresetPreview*)[presetPreviewArray objectAtIndex:0] setSelected];
}

- (void)load3DSettingsDictionary:(NSDictionary*)preset forPreview:(VRPresetPreview*)preview;
{
    // CLUT
    NSString *aClutName = [preset objectForKey:@"CLUT"];
    BOOL advancedCLUT = [[preset objectForKey:@"advancedCLUT"] boolValue];
    if(!advancedCLUT)
    {
        NSDictionary *aCLUT;
        NSArray *array;
        unsigned char red[256], green[256], blue[256];
        
        aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey:aClutName];
        if(aCLUT)
        {
            array = [aCLUT objectForKey:@"Red"];
            for( NSUInteger i = 0; i < 256; i++)
            {
                red[i] = [[array objectAtIndex: i] longValue];
            }
            
            array = [aCLUT objectForKey:@"Green"];
            for( NSUInteger i = 0; i < 256; i++)
            {
                green[i] = [[array objectAtIndex: i] longValue];
            }
            
            array = [aCLUT objectForKey:@"Blue"];
            for( NSUInteger i = 0; i < 256; i++)
            {
                blue[i] = [[array objectAtIndex: i] longValue];
            }
            
            [preview setCLUT:red :green: blue];
        }
        else [preview setCLUT: nil :nil :nil];
        
        // opacity
        NSDictionary *aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey:[preset objectForKey:@"opacity"]];
        if(aOpacity)
        {
            array = [aOpacity objectForKey:@"Points"];
            [preview setOpacity:array];
        }
        
        // window level/width
        float iwl = [[preset objectForKey:@"wl"] floatValue];
        float iww = [[preset objectForKey:@"ww"] floatValue];
        [preview setWLWW: iwl :iww];
        
    }
    else
    {
        // read the 16-bit CLUT in the file
        NSString *CLUTsPath = [[[BrowserController currentBrowser] database] clutsDirPath];
        NSString *path = [CLUTsPath stringByAppendingPathComponent:aClutName];
        
        NSMutableArray *curves = nil, *pointColors = nil;
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            if([[path pathExtension] isEqualToString:@""])
            {
                NSMutableDictionary *clut = [NSUnarchiver unarchiveObjectWithFile:path];
                curves = [clut objectForKey:@"curves"];
                pointColors = [clut objectForKey:@"colors"];
            }
        }
        else
        {
            path = [path stringByAppendingPathExtension:@"plist"];
            if([[NSFileManager defaultManager] fileExistsAtPath:path])
            {
                NSDictionary *clut = [NSDictionary dictionaryWithContentsOfFile:path];
                curves = [CLUTOpacityView convertCurvesFromPlist:[clut objectForKey:@"curves"]];
                pointColors = [CLUTOpacityView convertPointColorsFromPlist:[clut objectForKey:@"colors"]];
            }
            else if([aClutName isEqualToString:NSLocalizedString(@"16-bit CLUT", nil)] || [aClutName isEqualToString: @"16-bit CLUT"])
            {
                curves = [CLUTOpacityView convertCurvesFromPlist:[preset objectForKey:@"16bitClutCurves"]];
                pointColors = [CLUTOpacityView convertPointColorsFromPlist:[preset objectForKey:@"16bitClutColors"]];
            }
            else
            {
                // look in the resources bundle path
                NSString *bpath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:CLUTsPath.lastPathComponent];
                path = [bpath stringByAppendingPathComponent:[aClutName stringByAppendingPathExtension:@"plist"]];
                if([[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    NSDictionary *clut = [NSDictionary dictionaryWithContentsOfFile:path];
                    curves = [CLUTOpacityView convertCurvesFromPlist:[clut objectForKey:@"curves"]];
                    pointColors = [CLUTOpacityView convertPointColorsFromPlist:[clut objectForKey:@"colors"]];
                }
            }
        }
        
        NSMutableDictionary *clut2 = [NSMutableDictionary dictionaryWithCapacity:2];
        if(curves) [clut2 setObject:curves forKey:@"curves"];
        if(pointColors) [clut2 setObject:pointColors forKey:@"colors"];
        
        [preview setAdvancedCLUT:clut2 lowResolution:NO];
        
        // wl / ww for advanced CLUT
        //		int curveIndex = [self selectedCurveIndex];
        //		if(curveIndex<0) curveIndex = 0;
        //		NSMutableArray *theCurve = [curves objectAtIndex:curveIndex];
        //		NSPoint firstPoint = [[theCurve objectAtIndex:0] pointValue];
        //		NSPoint lastPoint = [[theCurve lastObject] pointValue];
        //		float iww = (lastPoint.x - firstPoint.x);
        //		float iwl = (lastPoint.x + firstPoint.x) / 2.0;
        //		
        //		float savedWl, savedWw;
        //		[view getWLWW: &savedWl :&savedWw];
        //		
        //		if( savedWl != iwl || savedWw != iww)
        //			[view setWLWW: iwl : iww];
    }
    
    // shadings
    if([[preset objectForKey:@"useShading"] boolValue])
    {
        NSString *shadingName = [preset objectForKey:@"shading"];
        NSArray *shadings = [[NSUserDefaults standardUserDefaults] arrayForKey:@"shadingsPresets"];
        NSDictionary *selectedShading = nil;
        for (NSUInteger i=0; i<[shadings count]; i++)
        {
            if([[[shadings objectAtIndex:i] objectForKey:@"name"] isEqualToString:shadingName])
            {
                selectedShading = [shadings objectAtIndex:i];
            }
        }
        
        float ambient, diffuse, specular, specularpower;
        
        if( selectedShading)
        {
            ambient = [[selectedShading valueForKey:@"ambient"] floatValue];
            diffuse = [[selectedShading valueForKey:@"diffuse"] floatValue];
            specular = [[selectedShading valueForKey:@"specular"] floatValue];
            specularpower = [[selectedShading valueForKey:@"specularPower"] floatValue];
            
            float sambient, sdiffuse, sspecular, sspecularpower;	
            [preview getShadingValues: &sambient :&sdiffuse :&sspecular :&sspecularpower];
            
            if( sambient != ambient || sdiffuse != diffuse || sspecular != specular || sspecularpower != specularpower)
            {
                [preview setShadingValues: ambient :diffuse :specular :specularpower];
                [preview setNeedsDisplay: YES];
            }
            
            if(![preview shading])
                [preview activateShading:YES];
        }
    }
    else
    {
        if([preview shading])
            [preview activateShading:NO];
    }
    
    // projection
    //	int projection = [[preset objectForKey:@"projection"] intValue];
    //	[view switchProjection:perspectiveMatrix];
				
    // background color
    float red = [[preset objectForKey:@"backgroundColorRedComponent"] floatValue];
    float green = [[preset objectForKey:@"backgroundColorGreenComponent"] floatValue];
    float blue = [[preset objectForKey:@"backgroundColorBlueComponent"] floatValue];
    [preview changeColorWith:[NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0]];
    
    // convolution filter
    //	if([appliedConvolutionFilters count]==0)
    //	{
    //		NSArray *convolutionFilters = [preset objectForKey:@"convolutionFilters"];
    //		if([convolutionFilters count]>0)
    //		{			
    //			for(i=0; i<[convolutionFilters count]; i++)
    //			{
    //				[self prepareUndo];
    //				[viewer2D ApplyConvString:[convolutionFilters objectAtIndex:i]];
    //				[viewer2D applyConvolutionOnSource:self];
    //				[appliedConvolutionFilters addObject:[convolutionFilters objectAtIndex:i]];
    //			}
    //		}
    //	}
}

- (void)setSelectedPresetPreview:(VRPresetPreview*)aPresetPreview;
{
    selectedPresetPreview = aPresetPreview;
    [self updatePresetInfoPanel];
}

- (void)selectGroupWithName:(NSString*)name;
{
    presetPageNumber = 0;
    
    if( [presetsGroupPopUpButton indexOfItemWithTitle: name] < 0) return;
    
    [settingsGroupPopUpButton selectItemWithTitle:name];
    [presetsGroupPopUpButton selectItemWithTitle:name];
    [self displayPresetsForSelectedGroup:presetsGroupPopUpButton];
}

- (IBAction)nextPresetPage:(id)sender;
{
    presetPageNumber++;
    presetPageNumber %= (presetPageMax+1);
    [self displayPresetsForSelectedGroup];
}

- (IBAction)previousPresetPage:(id)sender;
{
    presetPageNumber--;
    if(presetPageNumber<0) presetPageNumber += presetPageMax+1;
    [self displayPresetsForSelectedGroup];
}

- (void)enablePresetPageButtons;
{
    if(presetPageMax==0)
    {
        [nextPresetPageButton setHidden:YES];
        [previousPresetPageButton setHidden:YES];
    }
    else
    {
        [nextPresetPageButton setHidden:NO];
        [previousPresetPageButton setHidden:NO];
    }
}

- (void)showPresetsPanel;
{
    if( panelInstantiated == NO)
    {
        panelInstantiated = YES;
        
        for( id presetPreview in presetPreviewArray)
        {
            [presetPreview setPixSource:pixList[0] :(float*) [volumeData[0] bytes]];
            [presetPreview setData8: [view data8]];
            [presetPreview setMapper: [view mapper]];
        }
    }
    
    presetPageNumber = 0;
    [self updatePresetsGroupPopUpButton];
    
    [self selectGroupWithName: [[NSUserDefaults standardUserDefaults] stringForKey:@"LAST_3D_PRESET"]];
    
    [presetsPanel orderFront:self];
}

- (void)centerPresetsPanel;
{
    NSRect viewer3DFrame = [[[self window] screen] frame];
    
    NSRect presetsPanelFrame = [presetsPanel frame];
    
    NSPoint centerPoint;
    centerPoint.x = viewer3DFrame.origin.x + viewer3DFrame.size.width * 0.5;
    centerPoint.y = viewer3DFrame.origin.y + viewer3DFrame.size.height * 0.5;
    NSPoint newPresetsPanelOrigin;
    newPresetsPanelOrigin.x = centerPoint.x - presetsPanelFrame.size.width * 0.5;
    newPresetsPanelOrigin.y = centerPoint.y - presetsPanelFrame.size.height * 0.5;
    [presetsPanel setFrameOrigin:newPresetsPanelOrigin];
    
    presetsPanelUserDefinedOrigin = presetsPanelFrame.origin; // needed to restore the user defined position of the window;
    needToMovePresetsPanelToUserDefinedPosition = YES;
}

#pragma mark info preset

- (void)updatePresetInfoPanel;
{	
    if( [selectedPresetPreview index] < 0) NSLog( @" ******** [selectedPresetPreview index] < 0");
    if( selectedPresetPreview == nil) return;
    
    NSDictionary *presetDictionary = [[self find3DSettingsForGroupName:[presetsGroupPopUpButton titleOfSelectedItem]] objectAtIndex:[selectedPresetPreview index]];
    
    [infoNameTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Name: %@", nil), [presetDictionary objectForKey:@"name"]]];
    
    if([[presetDictionary objectForKey:@"advancedCLUT"] boolValue])
    {
        [infoCLUTTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"CLUT: %@ (16-bit)", nil), [presetDictionary objectForKey:@"CLUT"]]];
        [infoOpacityTextField setStringValue:NSLocalizedString(@"Opacity: (defined in the CLUT)", nil)];
    }
    else
    {
        [infoCLUTTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"CLUT: %@ (8-bit)", nil), [presetDictionary objectForKey:@"CLUT"]]];
        [infoOpacityTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Opacity: %@", nil), [presetDictionary objectForKey:@"opacity"]]];
    }
    
    if(![[presetDictionary objectForKey:@"useShading"] boolValue])
        [infoShadingsTextField setStringValue:NSLocalizedString(@"Shadings: Off", nil)];
    else
        [infoShadingsTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Shadings: %@", nil), [presetDictionary objectForKey:@"shading"]]];
    
    [infoWLWWTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"WL: %.0f WW: %.0f", nil), [[presetDictionary objectForKey:@"wl"] floatValue], [[presetDictionary objectForKey:@"ww"] floatValue]]];
    
    NSMutableString *convolutionFiltersString = [NSMutableString stringWithString:@""];
    NSArray *filters = [presetDictionary objectForKey:@"convolutionFilters"];
    if([filters count]>1) [convolutionFiltersString appendString:NSLocalizedString(@"Filters", nil)];
    else [convolutionFiltersString appendString:NSLocalizedString(@"Filter", nil)];
    [convolutionFiltersString appendString:@": "];
    
    if([filters count]>0)
    {
        for(NSUInteger i=0; i<(long)[filters count]-1; i++)
        {
            [convolutionFiltersString appendString:[filters objectAtIndex:i]];
            [convolutionFiltersString appendString:@", "];
        }
        [convolutionFiltersString appendString:[filters objectAtIndex:(long)[filters count]-1]];
        [convolutionFiltersString appendString:@"."];
    }
    else
    {
        [convolutionFiltersString appendString:NSLocalizedString(@"(none).", nil)];
    }
    [infoConvolutionFilterTextField setStringValue:convolutionFiltersString];
    
    [infoBackgroundColorTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"r:%.0f%%, g:%.0f%%, b:%.0f%%", nil), 100*[[presetDictionary objectForKey:@"backgroundColorRedComponent"] floatValue], 100*[[presetDictionary objectForKey:@"backgroundColorGreenComponent"] floatValue], 100*[[presetDictionary objectForKey:@"backgroundColorBlueComponent"] floatValue]]];
    
    [infoBackgroundColorView setColor:[NSColor colorWithDeviceRed:[[presetDictionary objectForKey:@"backgroundColorRedComponent"] floatValue] green:[[presetDictionary objectForKey:@"backgroundColorGreenComponent"] floatValue] blue:[[presetDictionary objectForKey:@"backgroundColorBlueComponent"] floatValue] alpha:1.0]];
    
    [infoBackgroundColorView setNeedsDisplay:YES];
    
    //	if([presetsInfoPanel isVisible])
    //		[infoBackgroundColorView display];
    
    int proj = [[presetDictionary objectForKey:@"projection"] intValue];
    NSString *projectionName = nil;
    if(proj==0)
        projectionName = NSLocalizedString(@"Perspective", nil);
    else if(proj==1)
        projectionName = NSLocalizedString(@"Parallel", nil);
    else if(proj==2)
        projectionName = NSLocalizedString(@"Endoscopy", nil);
    [infoProjectionTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Projection: %@", nil), projectionName]];
}

- (IBAction)showPresetInfoPanel:(id)sender;
{
    [self updatePresetInfoPanel];
    [presetsInfoPanel orderFront:self];
}

#pragma mark NSWindow Notifications action

- (void)windowWillCloseNotification:(NSNotification*)notification;
{
    if( [notification object] == presetsPanel)
    {
        [presetsInfoPanel close];
        if(needToMovePresetsPanelToUserDefinedPosition)
        {
            NSRect frame = [presetsPanel frame];
            frame.origin = presetsPanelUserDefinedOrigin;
            [presetsPanel setFrame:frame display:NO];
        }
    }
}

- (void)windowWillMoveNotification:(NSNotification*)notification;
{
    if( [notification object] == presetsPanel)
    {
        if(needToMovePresetsPanelToUserDefinedPosition)
        {
            needToMovePresetsPanelToUserDefinedPosition = NO;
        }
    }
}

- (void)setVtkCameraForAllPresetPreview:(void*)aCamera;
{
    [presetPreview1 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview2 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview3 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview4 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview5 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview6 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview7 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview8 setVtkCamera:(vtkCamera*)aCamera];
    [presetPreview9 setVtkCamera:(vtkCamera*)aCamera];
}

@end
