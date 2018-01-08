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

#import "SRController.h"
#import "DCMView.h"
#import "Photos.h"
#import "SRView.h"
#import "SRFlyThruAdapter.h"
#import "ROI.h"
#import "ROIVolumeManagerController.h"
#import "ROIVolume.h"
#import "BrowserController.h"
#import "Notifications.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "PluginManager.h"
#import "N2Debug.h"
#import "DicomDatabase.h"

static NSString* 	MIPToolbarIdentifier				= @"SR Toolbar Identifier";
static NSString*	QTExportToolbarItemIdentifier		= @"QTExport.pdf";
static NSString*	PhotosToolbarItemIdentifier			= @"iPhoto.icns";
static NSString*	StereoIdentifier					= @"Stereo.icns";
//static NSString*	QTExportVRToolbarItemIdentifier		= @"QTExportVR.icns";
static NSString*	SRSettingsToolbarItemIdentifier		= @"SRSettings.tif";
static NSString*	BSRSettingsToolbarItemIdentifier	= @"BSRSettings.tif";
static NSString*	ToolsToolbarItemIdentifier			= @"Tools";
static NSString*	Export3DFileFormat					= @"3DExportFileFormat";
static NSString*	FlyThruToolbarItemIdentifier		= @"FlyThru.pdf";
static NSString*	OrientationToolbarItemIdentifier	= @"OrientationWidget.tif";
static NSString*	ToggleDisplay3DpointsItemIdentifier	= @"Point.tif";
static NSString*	PerspectiveToolbarItemIdentifier	= @"Perspective";
static NSString*	ResetToolbarItemIdentifier			= @"Reset.pdf";
static NSString*	ROIManagerToolbarItemIdentifier		= @"ROIManager.pdf";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	OrientationsViewToolbarItemIdentifier		= @"OrientationsView";
static NSString*	BackgroundColorViewToolbarItemIdentifier		= @"BackgroundColorView";

@interface SRController (Dummy)

- (void)exportQuicktime3DVR:(id)dummy;
- (void)sendMail:(id)dummy;

@end

@implementation SRController

@synthesize firstSurface = _firstSurface, secondSurface = _secondSurface, resolution = _resolution, firstTransparency = _firstTransparency, secondTransparency = _secondTransparency, decimate = _decimate;
@synthesize smooth = _smooth;
@synthesize firstColor = _firstColor, secondColor = _secondColor;
@synthesize shouldDecimate = _shouldDecimate, shouldSmooth = _shouldSmooth, useFirstSurface = _useFirstSurface, useSecondSurface = _useSecondSurface, shouldRenderFusion = _shouldRenderFusion;


@synthesize fusionFirstSurface,  fusionSecondSurface, fusionResolution, fusionFirstTransparency, fusionSecondTransparency, fusionDecimate, fusionSmooth, fusionFirstColor, fusionSecondColor, fusionShouldDecimate, fusionShouldSmooth, fusionUseFirstSurface, fusionUseSecondSurface;


- (ViewerController*) viewer
{
	return viewer2D;
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

- (void) windowDidLoad
{
    settings = [NSMutableDictionary new];
    blendingSettings = [NSMutableDictionary new];
    
    [settings setObject: @0.5 forKey: @"resolution"];
    [settings setObject: @YES forKey: @"shouldDecimate"];
    [settings setObject: @YES forKey: @"shouldSmooth"];
    [settings setObject: @300 forKey: @"firstSurface"];
    [settings setObject: @-500 forKey: @"secondSurface"];
    [settings setObject: @1.0 forKey: @"firstTransparency"];
    [settings setObject: @1.0 forKey: @"secondTransparency"];
    [settings setObject: @0.5 forKey: @"decimate"];
    [settings setObject: @20 forKey: @"smooth"];
    [settings setObject: [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0] forKey: @"firstColor"];
    [settings setObject: [NSColor colorWithCalibratedRed:1.0 green:0.592 blue:0.608 alpha:1.0] forKey: @"secondColor"];
    [settings setObject: @YES forKey: @"useFirstSurface"];
    [settings setObject: @NO forKey: @"useSecondSurface"];
    
    [blendingSettings addEntriesFromDictionary: settings];
    
	self.shouldRenderFusion = NO;
}

-(ViewerController*) blendingController
{
	return blendingController;
}

-(NSArray*) pixList { return pixList;}

- (NSArray*) fileList
{
	return fileList;
}

-(id) initWithPix:(NSMutableArray*) pix :(NSArray*) f :(NSData*) vData :(ViewerController*) bC :(ViewerController*) vC
{
    unsigned long   i;
    short           err = 0;
	BOOL			testInterval = YES;
	
    @try
    {
        pixList = pix;
        volumeData = vData;

        DCMPix  *firstObject = [pixList objectAtIndex:0];
        float sliceThickness = fabs( [firstObject sliceInterval]);  //fabs( [firstObject sliceLocation] - [[pixList objectAtIndex:1] sliceLocation]);
        
        if( sliceThickness == 0)
        {
            sliceThickness = [firstObject sliceThickness];
            
            testInterval = NO;
            
            if( sliceThickness > 0) NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval",nil),  NSLocalizedString(@"I'm not able to find the slice interval. Slice interval will be equal to slice thickness.",nil),NSLocalizedString( @"OK",nil), nil, nil);
            else
            {
                NSRunCriticalAlertPanel(NSLocalizedString( @"Slice interval/thickness",nil), NSLocalizedString( @"Problems with slice thickness/interval to do a 3D reconstruction.",nil), NSLocalizedString(@"OK",nil), nil, nil);
                [self autorelease];
                return nil;
            }
        }
        
        err = 0;
        // CHECK IMAGE SIZE
        for( i =0 ; i < [pixList count]; i++)
        {
            if( [firstObject pwidth] != [[pixList objectAtIndex:i] pwidth]) err = -1;
            if( [firstObject pheight] != [[pixList objectAtIndex:i] pheight]) err = -1;
        }
        if( err)
        {
            NSRunCriticalAlertPanel( NSLocalizedString(@"Images size",nil),  NSLocalizedString(@"These images don't have the same height and width to allow a 3D reconstruction...",nil), NSLocalizedString(@"OK",nil), nil, nil);
            [self autorelease];
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
        fileList = f;
        [fileList retain];
        
        [pixList retain];
        [volumeData retain];
        self = [super initWithWindowNibName:@"SR"];
        
        [[self window] setDelegate:self];
        
        err = [view setPixSource:pixList :(float*) [volumeData bytes]];
        if( err != 0)
        {
            [self autorelease];
            return nil;
        }
        
        blendingController = bC;
        if( blendingController) // Blending! Activate image fusion
        {
            [view setBlendingPixSource: blendingController];
        }

        roi2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        sliceNumber2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        x2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        y2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];
        z2DPointsArray = [[NSMutableArray alloc] initWithCapacity:0];

        viewer2D = [vC retain];
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
                        
                        x =location[ 0 ];
                        y =location[ 1 ];
                        z =location[ 2 ];

                        // add the 3D Point to the SR view
                        [[self view] add3DPoint:  x : y : z];
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
        [nc	addObserver: self
                        selector: @selector(CloseViewerNotification:)
                        name: OsirixCloseViewerNotification
                        object: nil];
    //	curWLWWMenu = @"Other";
    //	
    //	NSNotificationCenter *nc;
    //    nc = [NSNotificationCenter defaultCenter];
    //    [nc addObserver: self
    //           selector: @selector(UpdateWLWWMenu:)
    //               name: OsirixUpdateWLWWMenuNotification
    //             object: nil];
    //	
    //	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
    //	
    //	curCLUTMenu = NSLocalizedString(@"No CLUT", nil);
    //	
    //    [nc addObserver: self
    //           selector: @selector(UpdateCLUTMenu:)
    //               name: OsirixUpdateCLUTMenuNotification
    //             object: nil];
    //	
    //	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
        
        roiVolumes = [[NSMutableArray alloc] initWithCapacity:0];
    #ifdef roi3Dvolume
        [self computeROIVolumes];
        [self displayROIVolumes];
    #endif
        //[[self window] performZoom:self];
        
        [self setupToolbar];
        
        return self;
    }
    @catch ( NSException *e)
    {
        N2LogException( e);
        [self autorelease];
    }
    return nil;
}

-(void) dealloc
{
    NSLog(@"Dealloc SRController");
	
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver: self];
    
	[fileList release];
    [pixList release];
	[volumeData release];
	
	[toolbar setDelegate: nil];
	[toolbar release];

	[roi2DPointsArray release];
	[sliceNumber2DPointsArray release];
	[x2DPointsArray release];
	[y2DPointsArray release];
	[z2DPointsArray release];
	[viewer2D release];
	[roiVolumes release];
    
    [_firstColor release];
    [_secondColor release];
    
    [settings release];
    [blendingSettings release];
    
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

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixWindow3dCloseNotification object: self userInfo: 0];
	
    [[self window] setDelegate:nil];
    
    [self autorelease];
}

//-(NSMatrix*) toolsMatrix
//{
//	return toolsMatrix;
//}

-(void) setDefaultTool:(id) sender
{
    id theCell = [sender selectedCell];
    
    if( [theCell tag] >= 0)
        [view setCurrentTool: (ToolMode)[theCell tag]];
}

-(IBAction) SettingsPopup:(id) sender
{
    switch( [sender tag])
    {
        case 1: self.firstSurface = -500.0; break;
        case 11: self.secondSurface = -500.; break;
            
        case 2: self.firstSurface = 500.0;  break;
        case 12: self.secondSurface = 500.0; break;
        
        case 3: self.firstSurface = 2000.0; break;
        case 13: self.secondSurface = 2000.0;break;
    }
}

-(IBAction) ApplySettings:(id) sender
{
    [SRSettingsWindow orderOut:sender];
    
    [NSApp endSheet:SRSettingsWindow returnCode:[sender tag]];
    
    if( [sender tag])
    {
        NSMutableDictionary * d = nil;
        
        if( fusionSettingsWindow)
        {
            d = blendingSettings;
            
            [self setShouldRenderFusion:YES];
            [self renderFusionSurfaces];
        }
        else
        {
            d = settings;
            [self renderSurfaces];
        }
        
        [d setObject: @(self.resolution) forKey: @"resolution"];
        [d setObject: @(self.shouldDecimate) forKey: @"shouldDecimate"];
        [d setObject: @(self.shouldSmooth) forKey: @"shouldSmooth"];
        [d setObject: @(self.firstSurface) forKey: @"firstSurface"];
        [d setObject: @(self.secondSurface) forKey: @"secondSurface"];
        [d setObject: @(self.firstTransparency) forKey: @"firstTransparency"];
        [d setObject: @(self.secondTransparency) forKey: @"secondTransparency"];
        [d setObject: @(self.decimate) forKey: @"decimate"];
        [d setObject: @(self.smooth) forKey: @"smooth"];
        [d setObject: self.firstColor forKey: @"firstColor"];
        [d setObject: self.secondColor forKey: @"secondColor"];
        [d setObject: @(self.useFirstSurface) forKey: @"useFirstSurface"];
        [d setObject: @(self.useSecondSurface) forKey: @"useSecondSurface"];
    }
}

- (void)renderSurfaces
{
	WaitRendering *www = [[WaitRendering alloc] init: NSLocalizedString( @"Preparing 3D Iso Surface...", nil)];
	[www start];
    
    NSColor *color = [_firstColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
    NSColor *sColor = [_secondColor colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
    
	// FIRST SURFACE
	if( _useFirstSurface)
			[view changeActor   :(long) 0
								:_resolution
								:_firstTransparency
								:[color redComponent]
								:[color greenComponent]
								:[color blueComponent]		
								:_firstSurface
								:_shouldDecimate
								:_decimate
								:_shouldSmooth
								:_smooth];
		else
			[view deleteActor: (long) 0];
		
		// SECOND SURFACE
		if( _useSecondSurface)	
			[view changeActor   :(long) 1
								:_resolution
								:_secondTransparency
								:[sColor redComponent]
								:[sColor greenComponent]
								:[sColor blueComponent]
								:_secondSurface
								:_shouldDecimate
								:_decimate
								:_shouldDecimate
								:_smooth];
		else
			[view deleteActor: (long) 1];
  
	
	[www end];
	[www close];
	[www autorelease];

}

- (void) ChangeSettings:(id) sender
{
    fusionSettingsWindow = NO;
    
    self.resolution = [[settings objectForKey: @"resolution"] floatValue];
    self.shouldDecimate = [[settings objectForKey: @"shouldDecimate"] boolValue];
    self.shouldSmooth = [[settings objectForKey: @"shouldSmooth"] boolValue];
    self.firstSurface = [[settings objectForKey: @"firstSurface"] floatValue];
    self.secondSurface = [[settings objectForKey: @"secondSurface"] floatValue];
    self.firstTransparency = [[settings objectForKey: @"firstTransparency"] floatValue];
    self.secondTransparency = [[settings objectForKey: @"secondTransparency"] floatValue];
    self.decimate = [[settings objectForKey: @"decimate"] floatValue];
    self.smooth = [[settings objectForKey: @"smooth"] floatValue];
    self.firstColor = [settings objectForKey: @"firstColor"];
    self.secondColor = [settings objectForKey: @"secondColor"];
    self.useFirstSurface = [[settings objectForKey: @"useFirstSurface"] boolValue];
    self.useSecondSurface = [[settings objectForKey: @"useSecondSurface"] boolValue];

    [NSApp beginSheet: SRSettingsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)renderFusionSurfaces
{
	if( _useFirstSurface)
		
		[view BchangeActor   :(long) 0
								: _resolution
								: _firstTransparency
								:[_firstColor redComponent]
								:[_firstColor greenComponent]
								:[_firstColor blueComponent]
								: _firstSurface
								: _shouldDecimate
								: _decimate
								: _shouldSmooth
								: _smooth];
	else
			[view BdeleteActor: (long) 0];
		
		// SECOND SURFACE
	if(_useSecondSurface)
	
		[view BchangeActor  :(long) 1
								: _resolution
								: _secondTransparency
								:[_secondColor redComponent]
								:[_secondColor greenComponent]
								:[_secondColor blueComponent]
								: _secondSurface
								: _shouldDecimate
								: _decimate
								: _shouldSmooth
								: _smooth];
	else
		[view BdeleteActor: (long) 1];

}

- (void) BChangeSettings:(id) sender
{
    fusionSettingsWindow = YES;
    
    self.resolution = [[blendingSettings objectForKey: @"resolution"] floatValue];
    self.shouldDecimate = [[blendingSettings objectForKey: @"shouldDecimate"] boolValue];
    self.shouldSmooth = [[blendingSettings objectForKey: @"shouldSmooth"] boolValue];
    self.firstSurface = [[blendingSettings objectForKey: @"firstSurface"] floatValue];
    self.secondSurface = [[blendingSettings objectForKey: @"secondSurface"] floatValue];
    self.firstTransparency = [[blendingSettings objectForKey: @"firstTransparency"] floatValue];
    self.secondTransparency = [[blendingSettings objectForKey: @"secondTransparency"] floatValue];
    self.decimate = [[blendingSettings objectForKey: @"decimate"] floatValue];
    self.smooth = [[blendingSettings objectForKey: @"smooth"] floatValue];
    self.firstColor = [blendingSettings objectForKey: @"firstColor"];
    self.secondColor = [blendingSettings objectForKey: @"secondColor"];
    self.useFirstSurface = [[blendingSettings objectForKey: @"useFirstSurface"] boolValue];
    self.useSecondSurface = [[blendingSettings objectForKey: @"useSecondSurface"] boolValue];
    
    [NSApp beginSheet: SRSettingsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo: nil];
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

- (IBAction)customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
//	if ([itemIdent isEqualToString: QTExportVRToolbarItemIdentifier]) {
//        
//	[toolbarItem setLabel: NSLocalizedString(@"Export QTVR",nil)];
//	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export QTVR",nil)];
//        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime VR file",nil)];
//	[toolbarItem setImage: [NSImage imageNamed: QTExportVRToolbarItemIdentifier]];
//	[toolbarItem setTarget: view];
//	[toolbarItem setAction: @selector(exportQuicktime3DVR:)];
//    }	
//	else
        if ([itemIdent isEqualToString: StereoIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Stereo",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Stereo",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Switch Stereo Mode ON/OFF",nil)];
	[toolbarItem setImage: [NSImage imageNamed: StereoIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(SwitchStereoMode:)];
    }
	else if ([itemIdent isEqualToString: QTExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else if ([itemIdent isEqualToString: PhotosToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Photos",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Photos",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series to Photos",nil)];
	[toolbarItem setImage: [NSImage imageNamed:@"Photos"]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(export2iPhoto:)];
    }
	else if ([itemIdent isEqualToString: Export3DFileFormat]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export 3D-SR",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Export 3D-SR",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a 3D file format",nil)];
	[toolbarItem setView: export3DView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([export3DView frame]), NSHeight([export3DView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([export3DView frame]), NSHeight([export3DView frame]))];
    }
	else if ([itemIdent isEqualToString: SRSettingsToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Surface Settings",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Surface Settings",nil)];
        [toolbarItem setToolTip:NSLocalizedString( @"change Surface Settings",nil)];
	[toolbarItem setImage: [NSImage imageNamed: SRSettingsToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(ChangeSettings:)];
    }
	else if ([itemIdent isEqualToString: BSRSettingsToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Fusion Surface Settings",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Fusion Surface Settings",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"change Fusion Surface Settings",nil)];
	[toolbarItem setImage: [NSImage imageNamed: BSRSettingsToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(BChangeSettings:)];
    }
	else if ([itemIdent isEqualToString: OrientationToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Orientation",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Orientation Cube",nil)];
	[toolbarItem setToolTip:NSLocalizedString(@"Show orientation cube",nil)];
	[toolbarItem setImage: [NSImage imageNamed: OrientationToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(switchOrientationWidget:)];
    }
     else if([itemIdent isEqualToString: ToolsToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel:NSLocalizedString( @"Mouse button function",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString( @"Mouse button function",nil)];
	
	[toolbarItem setView: toolsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
    }
	else if([itemIdent isEqualToString: FlyThruToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Fly Thru",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Fly Thru Set up",nil)];
	
	[toolbarItem setImage: [NSImage imageNamed: FlyThruToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(flyThruControllerInit:)];
	
    }
	else if([itemIdent isEqualToString: ToggleDisplay3DpointsItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Show/Hide",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Show/Hide 3D points",nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Show/Hide 3D points",nil)];
	
	[toolbarItem setImage: [NSImage imageNamed: ToggleDisplay3DpointsItemIdentifier]];
	[toolbarItem setTarget: [self view]];
	[toolbarItem setAction: @selector(toggleDisplay3DPoints)];
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
	else if ([itemIdent isEqualToString: ROIManagerToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"ROI Manager",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"ROI Manager",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"ROI Manager",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ROIManagerToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(roiGetManager:)];
    }
	else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Reset",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Reset to initial 3D view",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(resetImage:)];
    }
	else if([itemIdent isEqualToString: BackgroundColorViewToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Color", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Color", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Background Color", nil)];
	
	[toolbarItem setView: BackgroundColorView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([BackgroundColorView frame]), NSHeight([BackgroundColorView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([BackgroundColorView frame]), NSHeight([BackgroundColorView frame]))];
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
	else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel:NSLocalizedString( @"DICOM File",nil)];
	[toolbarItem setPaletteLabel:NSLocalizedString(@"Save as DICOM",nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image in a DICOM file",nil)];
	[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
	[toolbarItem setTarget: view];
	[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
	else
    {
        toolbarItem = nil;
    }
    
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
											SRSettingsToolbarItemIdentifier,
											BSRSettingsToolbarItemIdentifier,
											StereoIdentifier,
											OrientationToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											ROIManagerToolbarItemIdentifier,
											QTExportToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											Export3DFileFormat,
											OrientationsViewToolbarItemIdentifier,
											FlyThruToolbarItemIdentifier,
											BackgroundColorViewToolbarItemIdentifier,
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
                                        //WLWWToolbarItemIdentifier,
										//LODToolbarItemIdentifier,
										//CaptureToolbarItemIdentifier,
										//CroppingToolbarItemIdentifier,
										SRSettingsToolbarItemIdentifier,
										BSRSettingsToolbarItemIdentifier,
										StereoIdentifier,
										OrientationToolbarItemIdentifier,
										QTExportToolbarItemIdentifier,
										PhotosToolbarItemIdentifier,
										Export3DFileFormat,
										OrientationsViewToolbarItemIdentifier,
                                        ToolsToolbarItemIdentifier,
										ROIManagerToolbarItemIdentifier,
										FlyThruToolbarItemIdentifier,
										ToggleDisplay3DpointsItemIdentifier,
										PerspectiveToolbarItemIdentifier,
										ResetToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
										BackgroundColorViewToolbarItemIdentifier,
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
#ifdef EXPORTTOOLBARITEM
return YES;
#endif

    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = YES;
	if ([[toolbarItem itemIdentifier] isEqualToString: BSRSettingsToolbarItemIdentifier])
    {
        if(blendingController == nil) enable = NO;
    }
    return enable;
}


-(void) export2iPhoto:(id) sender
{
	Photos		*ifoto;
	NSImage		*im = [view nsimage:NO];
	
	NSArray		*representations;
	NSData		*bitmapData;
	
	representations = [im representations];
	
	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
    NSString *path = [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"Horos.jpg"];
	[bitmapData writeToFile:path atomically:YES];
	
	ifoto = [[Photos alloc] init];
	[ifoto importInPhotos:@[path]];
	[ifoto release];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setAllowedFileTypes:@[@"jpg"]];
    panel.nameFieldStringValue = NSLocalizedString(@"3D SR Image", nil);
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
    
		NSImage *im = [view nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:panel.URL.path atomically:YES];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
            [[NSWorkspace sharedWorkspace] openURL:panel.URL];
    }];
}

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
    [panel setAllowedFileTypes:@[@"tif"]];
    panel.nameFieldStringValue = NSLocalizedString(@"3D SR Image", nil);
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
		NSImage *im = [view nsimage:NO];
		
		[[im TIFFRepresentation] writeToFile:panel.URL.path atomically:NO];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
            [[NSWorkspace sharedWorkspace] openURL:panel.URL];
    }];
}

// Fly Thru

- (SRView*) view
{	
	return view;
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

- (IBAction) flyThruButtonMenu:(id) sender
{
	[self flyThruControllerInit: self];

	[[self flyThruController].stepsArrayController flyThruTag: [sender tag]];
}

- (IBAction) flyThruControllerInit:(id) sender
{
	//Only open 1 fly through controller
	if( [self flyThruController]) return;

	//flythru = [[FlyThru alloc] init];
	FTAdapter = [[SRFlyThruAdapter alloc] initWithSRController: self];
	FlyThruController *flyThruController = [[FlyThruController alloc] initWithFlyThruAdapter:FTAdapter];
	[FTAdapter release];
	[flyThruController loadWindow];
	[[flyThruController window] makeKeyAndOrderFront :sender];
	[flyThruController setWindow3DController: self];
}

- (void)recordFlyThru;
{
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if(now-flyThruRecordingTimeFrame<1.0) return;
	
	flyThruRecordingTimeFrame = now;
	[self flyThruControllerInit:self];
	[[self flyThruController].stepsArrayController flyThruTag:0];
}

- (void) add2DPoint: (float) x : (float) y : (float) z
{
	if (viewer2D && [[viewer2D pixList] count] > 1)
	{
		DCMPix *firstDCMPix = [[viewer2D pixList] objectAtIndex: 0];
		// compute 2D Coordinates
		double dc[3], sc[3];
		dc[0] = x;
		dc[1] = y;
		dc[2] = z;
		[view convert3Dto2Dpoint:dc :sc];
		
		// find the slice where we want to introduce the point
		long sliceNumber = sc[2]+0.5;
		
		if (sliceNumber>=0 && sliceNumber<[[viewer2D pixList] count])
		{
			// Create the new 2D Point ROI
			ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[firstDCMPix pixelSpacingX] :[firstDCMPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: firstDCMPix]] autorelease];
			NSRect irect;
			irect.origin.x = sc[0];
			irect.origin.y = sc[1];
			irect.size.width = irect.size.height = 0;
			[new2DPointROI setROIRect:irect];
			[[viewer2D imageView] roiSet:new2DPointROI];
			// add the 2D Point ROI to the ROI list
			[[[viewer2D roiList] objectAtIndex: sliceNumber] addObject: new2DPointROI];
			// add the ROI to our list
			[roi2DPointsArray addObject:new2DPointROI];
			[sliceNumber2DPointsArray addObject:[NSNumber numberWithLong:sliceNumber]];
			[x2DPointsArray addObject:[NSNumber numberWithFloat:x]];
			[y2DPointsArray addObject:[NSNumber numberWithFloat:y]];
			[z2DPointsArray addObject:[NSNumber numberWithFloat:z]];
			// notify the change
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object: new2DPointROI userInfo: nil];
		}
	}
}

- (void) remove2DPoint: (float) x : (float) y : (float) z
{
	if (viewer2D)
	{
		long cur2DPointIndex = 0;
		BOOL found = NO;

		while(!found && cur2DPointIndex<[roi2DPointsArray count])
		{
			if(	[[x2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==x 
				&& [[y2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==y
				&& [[z2DPointsArray objectAtIndex:cur2DPointIndex] floatValue]==z)
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
					[[self view] add3DPoint: x : y : z];
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
		[[self view] add3DPoint: x : y : z];
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

- (void)createContextualMenu
{
	NSMenu *contextual =  [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)] autorelease];
	NSMenuItem *item, *subItem;
	
	//tools
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", nil) action: nil  keyEquivalent:@""] autorelease];
	[contextual addItem:item];
	NSMenu *toolsSubmenu =  [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)] autorelease];
	[item setSubmenu:toolsSubmenu];
	
	
	NSArray *titles = [NSArray arrayWithObjects: 
					NSLocalizedString(@"Move", nil), 
					NSLocalizedString(@"Magnify", nil), 
					NSLocalizedString(@"Rotate", nil), 
					NSLocalizedString(@"Control Model", nil), 
					NSLocalizedString(@"Point", nil), 
					nil];

						
	NSArray *images = [NSArray arrayWithObjects: 
					@"Move",
					@"Zoom", 
					@"Rotate", 
					@"3DRotate",
					@"Point", 
					nil];
					  
	NSArray *tags = [NSArray arrayWithObjects: 
					[NSNumber numberWithInt:1], 
					[NSNumber numberWithInt:2], 
					[NSNumber numberWithInt:3],
					[NSNumber numberWithInt:7],
					[NSNumber numberWithInt:15],  
					nil];
	
	
	NSEnumerator *titleEnumerator = [titles objectEnumerator];
	NSEnumerator *imageEnumerator = [images objectEnumerator];
	NSEnumerator *tagEnumerator = [tags objectEnumerator];
	NSString *title;
	while (title = [titleEnumerator nextObject])
    {
		subItem = [[[NSMenuItem alloc] initWithTitle:title action: @selector(setDefaultTool:) keyEquivalent:@""] autorelease];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setImage:[NSImage imageNamed:[imageEnumerator nextObject]]];
        [[subItem image] setSize:ToolsMenuIconSize];
		[subItem setTarget:self];
		[toolsSubmenu addItem:subItem];
	}
	
	//View
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"View", nil) action: nil  keyEquivalent:@""] autorelease];
	[contextual addItem:item];
	NSMenu *viewSubmenu =  [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"View", nil)] autorelease];
	[item setSubmenu:viewSubmenu];
	
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Axial", nil) action: @selector(axView:) keyEquivalent:@""] autorelease];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Right", nil) action: @selector(saView:) keyEquivalent:@""] autorelease];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Sagittal Left", nil) action: @selector(saViewOpposite:) keyEquivalent:@""] autorelease];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Coronal", nil) action: @selector(coView:) keyEquivalent:@""] autorelease];
		[subItem setTag:[[tagEnumerator nextObject] intValue]];
		[subItem setTarget:view];
		[viewSubmenu addItem:subItem];
		
	//Export
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", nil) action: nil  keyEquivalent:@""] autorelease];
	[contextual addItem:item];
	NSMenu *exportSubmenu =  [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Export", nil)] autorelease];
	[item setSubmenu:exportSubmenu];
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime", nil)  action:@selector(exportQuicktime:) keyEquivalent:@""] autorelease];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime VR", nil)  action:@selector(exportQuicktime3DVR:) keyEquivalent:@""] autorelease];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DICOM", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""] autorelease];
		[subItem setTarget:view];
		[exportSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Email", nil)  action:@selector(sendMail:) keyEquivalent:@""] autorelease];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Photos", nil)  action:@selector(export2iPhoto:) keyEquivalent:@""] autorelease];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"JPEG", nil)  action:@selector(exportJPEG:) keyEquivalent:@""] autorelease];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
		
		subItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"TIFF", nil)  action:@selector(exportTIFF:) keyEquivalent:@""] autorelease];
		[subItem setTarget:self];
		[exportSubmenu addItem:subItem];
    
	[view setMenu:contextual];								
}

// ROIs Volumes
#ifdef roi3Dvolume
- (void) computeROIVolumes
{
	int i;
	NSArray *roiNames = [viewer2D roiNames];
	[roiVolumes removeAllObjects];
	
	for(i=0; i<[roiNames count]; i++)
	{
		NSArray *roisWithCurrentName = [viewer2D roisWithName:[roiNames objectAtIndex:i]];
		ROIVolume *volume = [[[ROIVolume alloc] initWithViewer: viewer2D] autorelease];
		[volume setROIList:roisWithCurrentName];
		if ([volume isVolume])
			[roiVolumes addObject:volume];
	}
}

- (NSMutableArray*) roiVolumes
{
	return roiVolumes;
}

//- (void) displayROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	viewRenderer->AddActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}

- (void) displayROIVolume: (ROIVolume*) v
{
	vtkRenderer *viewRenderer = [view renderer];
	viewRenderer->AddActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}

//- (void) hideROIVolumeAtIndex: (int) index
//{
//	vtkRenderer *viewRenderer = [view renderer];
//	viewRenderer->RemoveActor((vtkActor*)[[[roiVolumes objectAtIndex:index] roiVolumeActor] pointerValue]);
//}

- (void) hideROIVolume: (ROIVolume*) v
{
	vtkRenderer *viewRenderer = [view renderer];
	viewRenderer->RemoveActor((vtkActor*)[[v roiVolumeActor] pointerValue]);
}

- (void) displayROIVolumes
{
	int i;
	for(i=0; i<[roiVolumes count]; i++)
	{
		if([[roiVolumes objectAtIndex:i] visible])
		{
			[self displayROIVolume:[roiVolumes objectAtIndex:i]];
		}
	}
}

- (IBAction) roiGetManager:(id) sender
{
	BOOL	found = NO;
	NSArray *winList = [NSApp windows];
	long i;
	
	for(i = 0; i < [winList count]; i++)
	{
		if([[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROIVolumeManager"])
		{
			found = YES;
			NSLog(@"FOUND!!");
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



#endif

- (void) showWindow:(id) sender
{
	[super showWindow: sender];
	
	[view squareView: self];
}

- (ViewerController *) viewer2D
{
	return viewer2D;
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

@end
