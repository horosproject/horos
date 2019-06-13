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
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#include "options.h"

#import "NSImage+N2.h"
#import "DefaultsOsiriX.h"
#import "NSAppleScript+HandlerCalls.h"
#import "AYDicomPrintWindowController.h"
#import "MyOutlineView.h"
#import "PluginFilter.h"
#import "DCMPix.h"
#import "DicomImage.h"
#import "VRController.h"
#import "VRControllerVPRO.h"
#import "NSSplitViewSave.h"
#import "SRController.h"
#import "OsiriXToolbar.h"
#import "MPR2DController.h"
#import "NSFullScreenWindow.h"
#import "ViewerController.h"
#import "BrowserController.h"
#import "Wait.h"
#import "XMLController.h"
#include <Accelerate/Accelerate.h>
#import "WaitRendering.h"
#import "HistogramWindow.h"
#import "ROIWindow.h"
#import "ROIDefaultsWindow.h"
#import <ScreenSaver/ScreenSaverView.h>
#import "AppController.h"
#import "ToolbarPanel.h"
#import "ThumbnailsListPanel.h"
#import "DCMView.h"
#import "StudyView.h"
#import "ColorTransferView.h"
#import "ThickSlabController.h"
#import "Mailer.h"
#import "ITKSegmentation3DController.h"
#import "ITKSegmentation3D.h"
#import "OSIWindow.h"
#import "Photos.h"
#import "CurvedMPR.h"
#import "SeriesView.h"
#import "DICOMExport.h"
#import "ROIVolumeController.h"
#import "OrthogonalMPRViewer.h"
#import "OrthogonalMPRPETCTViewer.h"
#import "OrthogonalMPRPETCTController.h"
#import "EndoscopyViewer.h"
#import "PaletteController.h"
#import "ROIManagerController.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "ITKBrushROIFilter.h"
#import "DCMAbstractSyntaxUID.h"
#import "printView.h"
#import "ITKTransform.h"
#import "NSManagedObject+N2.h"
#import "DicomStudy.h"
#import "KeyObjectController.h"
#import "KeyObjectPopupController.h"
#import "JPEGExif.h"
#import "NSFont_OpenGL.h"
#import "Reports.h"
#import "SRAnnotation.h"
#import "CalciumScoringWindowController.h"
#import "EndoscopySegmentationController.h"
#import "HornRegistration.h"
#import "N2Stuff.h"
#import "BonjourBrowser.h"
#import "PluginManager.h"
#import "DCMObject.h"
#import "DCMAttributeTag.h"
#import "NavigatorWindowController.h"
#import "ThreeDPositionController.h"
#import "ThumbnailCell.h"
#import "DicomSeries.h"
#import "DicomFile.h"
#import "MPRController.h"
#import "CPRController.h"
#import "Notifications.h"
#import "DicomDatabase.h"
#import "N2Debug.h"
#import "OSIEnvironment+Private.h"
#import "NSString+N2.h"
#import "WindowLayoutManager.h"
#import "DCMTKQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import "O2ViewerThumbnailsMatrix.h"
#import "ToolBarNSWindow.h"
#import "RemoteDicomDatabase.h"

#import "homephone/HorosHomePhone.h"

int delayedTileWindows = NO;

#define MAXSCREENS 10

extern ThumbnailsListPanel *thumbnailsListPanel[ MAXSCREENS];

extern BOOL FULL32BITPIPELINE;

static	BOOL SYNCSERIES = NO, ViewBoundsDidChangeProtect = NO, recursiveCloseWindowsProtected = NO;

static NSString* ViewerToolbarIdentifier				= @"Viewer Toolbar Identifier";
static NSString*	QTSaveToolbarItemIdentifier			= @"QTExport.pdf";
static NSString*	PhotosToolbarItemIdentifier			= @"iPhoto2";
static NSString*	PlayToolbarItemIdentifier			= @"Play.pdf";
static NSString*	PauseToolbarItemIdentifier			= @"Pause.pdf";
static NSString*	XMLToolbarItemIdentifier			= @"XML.icns";
static NSString*	SpeedToolbarItemIdentifier			= @"Speed";
static NSString*	ToolsToolbarItemIdentifier			= @"Tools";
static NSString*	WLWWToolbarItemIdentifier			= @"WLWW";
static NSString*	FusionToolbarItemIdentifier			= @"Fusion";
static NSString*	FilterToolbarItemIdentifier			= @"Filters";
static NSString*	BlendingToolbarItemIdentifier		= @"2DBlending";
static NSString*	MovieToolbarItemIdentifier			= @"Movie";
static NSString*	SerieToolbarItemIdentifier			= @"Series";
static NSString*	PatientToolbarItemIdentifier		= @"Patient";
static NSString*	SubtractionToolbarItemIdentifier	= @"Subtraction";
static NSString*	Send2PACSToolbarItemIdentifier		= @"Send.icns";
static NSString*	ReconstructionToolbarItemIdentifier = @"Reconstruction";
static NSString*	RGBFactorToolbarItemIdentifier		= @"RGB";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	MailToolbarItemIdentifier			= @"Mail.icns";
//static NSString*	iChatBroadCastToolbarItemIdentifier = @"iChat.icns";
static NSString*	StatusToolbarItemIdentifier			= @"status";
static NSString*	SyncSeriesToolbarItemIdentifier		= @"Sync.pdf";
static NSString*	ResetToolbarItemIdentifier			= @"Reset.pdf";
static NSString*	RevertToolbarItemIdentifier			= @"Revert.tif";
static NSString*	FlipDataToolbarItemIdentifier		= @"FlipData.tif";
static NSString*	DatabaseWindowToolbarItemIdentifier = @"DatabaseWindow.icns";
static NSString*	KeyImagesToolbarItemIdentifier		= @"keyImages";
static NSString*	TileWindowsToolbarItemIdentifier	= @"windows.tif";
static NSString*	SUVToolbarItemIdentifier			= @"SUV.tif";
static NSString*	ROIManagerToolbarItemIdentifier		= @"ROIManager.pdf";
static NSString*	ReportToolbarItemIdentifier			= @"Report.icns";
static NSString*	FlipVerticalToolbarItemIdentifier	= @"FlipVertical.pdf";
static NSString*	FlipHorizontalToolbarItemIdentifier	= @"FlipHorizontal.pdf";
static NSString*	VRPanelToolbarItemIdentifier		= @"MIP.tif";
static NSString*	ShutterToolbarItemIdentifier		= @"Shutter";
static NSString*	PropagateSettingsToolbarItemIdentifier		= @"PropagateSettings";
static NSString*	OrientationToolbarItemIdentifier	= @"Orientation";
static NSString* WindowsTilingToolbarItemIdentifier   = @"WindowsTiling";
static NSString* SeriesPopupToolbarItemIdentifier   = @"SeriesPopup";
static NSString* AnnotationsToolbarItemIdentifier   = @"Annotations";
static NSString*	PrintToolbarItemIdentifier			= @"Print.tiff";
static NSString*	LUT12BitToolbarItemIdentifier		= @"LUT12Bit";
static NSString*	NavigatorToolbarItemIdentifier		= @"Navigator";
static NSString*	ThreeDPositionToolbarItemIdentifier	= @"3DPosition";
static NSString*	CobbAngleToolbarItemIdentifier		= @"CobbAngle";
static NSString*	SetPixelValueItemIdentifier			= @"SetPixelValue.pdf";
static NSString*	GrowingRegionItemIdentifier			= @"GrowingRegion.png";

static NSArray*		DefaultROINames = nil;

static	float deg2rad									= M_PI/180.0;

static NSMenu *wlwwPresetsMenu = nil;
static NSMenu *contextualMenu = nil;
static NSMenu *clutPresetsMenu = nil;
static NSMenu *convolutionPresetsMenu = nil;
static NSMenu *opacityPresetsMenu = nil;
static NSImage* retrieveImage = nil;

static int numberOf2DViewer = 0;
static NSMutableArray *arrayOf2DViewers = nil;
static BOOL DisplayUseInvertedPolarity = NO;

BOOL SyncButtonBehaviorIsBetweenStudies = NO;

// compares the names of 2 ROIs.
// using the option NSNumericSearch => "Point 1" < "Point 5" < "Point 21".
// use it with sortUsingFunction:context: to order an array of ROIs
NSInteger sortROIByName(id roi1, id roi2, void *context)
{
    NSString *n1 = [roi1 name];
    NSString *n2 = [roi2 name];
    return [n1 compare:n2 options:NSNumericSearch];
}

@interface ViewerControllerOperation: NSOperation
{
    ViewerController *ctrl;
    NSDictionary *dict;
}

- (id) initWithController:(ViewerController*) c dict: (NSDictionary*) d;

@end

@implementation ViewerControllerOperation

- (id) initWithController:(ViewerController*) c dict: (NSDictionary*) d;
{
    self = [super init];
    
    ctrl = [c retain];
    dict = [d retain];
    
    return self;
}

- (void) main
{
    @autoreleasepool
    {
#ifndef OSIRIX_LIGHT
        // ** Set Pixels
        
        if( [[dict valueForKey:@"action"] isEqualToString:@"setPixel"])
        {
            [[dict objectForKey:@"curPix"]	fillROI:		nil
                                            newVal:			[[dict objectForKey:@"newValue"] floatValue]
                                          minValue:		[[dict objectForKey:@"minValue"] floatValue]
                                          maxValue:		[[dict objectForKey:@"maxValue"] floatValue]
                                           outside:		[[dict objectForKey:@"outside"] boolValue]
                                  orientationStack:2
                                           stackNo:		[[dict objectForKey:@"stackNo"] intValue]
                                           restore:		[[dict objectForKey:@"revert"] boolValue]
                                          addition:		[[dict objectForKey:@"addition"] boolValue]];
        }
        
        if( [[dict valueForKey:@"action"] isEqualToString:@"setPixelRoi"])
        {
            [[dict objectForKey:@"curPix"]	fillROI:			[dict objectForKey:@"roi"]
                                            newVal:				[[dict objectForKey:@"newValue"] floatValue]
                                          minValue:			[[dict objectForKey:@"minValue"] floatValue]
                                          maxValue:			[[dict objectForKey:@"maxValue"] floatValue]
                                           outside:			[[dict objectForKey:@"outside"] boolValue]
                                  orientationStack:	2
                                           stackNo:			[[dict objectForKey:@"stackNo"] intValue]
                                           restore:			[[dict objectForKey:@"revert"] boolValue]
                                          addition:			[[dict objectForKey:@"addition"] boolValue]];
        }
        // ** Math Morphology
        
        if( [[dict valueForKey:@"action"] isEqualToString:@"close"])
            [[dict objectForKey:@"filter"] close: [dict objectForKey:@"roi"] withStructuringElementRadius: [[dict objectForKey:@"radius"] intValue]];
        
        if( [[dict valueForKey:@"action"] isEqualToString:@"open"])
            [[dict objectForKey:@"filter"] open: [dict objectForKey:@"roi"] withStructuringElementRadius: [[dict objectForKey:@"radius"] intValue]];
        
        if( [[dict valueForKey:@"action"] isEqualToString:@"dilate"])
            [[dict objectForKey:@"filter"] dilate: [dict objectForKey:@"roi"] withStructuringElementRadius: [[dict objectForKey:@"radius"] intValue]];
        
        if( [[dict valueForKey:@"action"] isEqualToString:@"erode"])
            [[dict objectForKey:@"filter"] erode: [dict objectForKey:@"roi"] withStructuringElementRadius: [[dict objectForKey:@"radius"] intValue]];
#endif
        
    }
}

- (void) dealloc
{
    [ctrl release];
    [dict release];
    [super dealloc];
}

@end


@interface ViewerController (Private)

-(NSMenu*)contextualMenu;
-(NSMenu*)contextualMenuForROI:(ROI*)roi;

- (void)sendWillFreeVolumeDataNotificationWithVolumeData:(NSData *)volumeData movieIndex:(NSInteger)movieIndex;
- (void)sendDidAllocateVolumeDataNotificationWithVolumeData:(NSData *)volumeData movieIndex:(NSInteger)movieIndex;

@end

@interface ViewerController (Dummy)

- (void)resizeWindow:(id)dummy;

@end

enum
{
    NSTruncateStart,
    NSTruncateMiddle,
    NSTruncateEnd
};

@interface NSString (Truncate)

- (NSString *)stringWithTruncatingToLength:(unsigned)length;
- (NSString *)stringTruncatedToLength:(unsigned int)length direction:(unsigned)truncateFrom;
- (NSString *)stringTruncatedToLength:(unsigned int)length direction:(unsigned)truncateFrom withEllipsisString:(NSString *)ellipsis;

@end


@implementation NSString (Truncate)

- (NSString *)stringTruncatedToLength:(unsigned int)length direction:(unsigned)truncateFrom withEllipsisString:(NSString *)ellipsis{
    NSMutableString *result = [[[NSMutableString alloc] initWithString:self] autorelease];
    NSString *immutableResult;
    
    if([result length] <= length) {
        return self; // no truncation, foolios
    }
    
    unsigned int charactersEachSide = length / 2;
    
    NSString *first;
    NSString *last;
    
    switch(truncateFrom) {
        case NSTruncateStart:
            [result insertString:ellipsis atIndex:length - [ellipsis length]];
            immutableResult  = [[result substringToIndex:length] copy];
            return [immutableResult autorelease];
            break;
        case NSTruncateMiddle:
            first = [result substringToIndex:charactersEachSide - [ellipsis length]+1];
            last = [result substringFromIndex:[result length] - charactersEachSide];
            immutableResult = [[[NSArray arrayWithObjects:first, last, NULL] componentsJoinedByString:ellipsis] copy];
            return [immutableResult autorelease];
            break;
        case NSTruncateEnd:
            [result insertString:ellipsis atIndex:[result length] - length + [ellipsis length] ];
            immutableResult  = [[result substringFromIndex:[result length] - length] copy];
            return [immutableResult autorelease];
    }
    
    return @"";
}


- (NSString *)stringWithTruncatingToLength:(unsigned)length {
    return [self stringTruncatedToLength:length direction:NSTruncateMiddle];
}

- (NSString *)stringTruncatedToLength:(unsigned int)length direction:(unsigned)truncateFrom {
    return [self stringTruncatedToLength:length direction:truncateFrom withEllipsisString:@"…"];
}

@end

#pragma mark-

@interface ViewerController ()

-(void)observeScrollerStyleDidChangeNotification:(NSNotification*)n;
+ (NSColor*)_selectedItemColor;
+ (NSColor*)_fusionedItemColor;
+ (NSColor*)_openItemColor;
@end

@implementation ViewerController

@synthesize currentOrientationTool, speedSlider, speedText, toolbarPanel;
@synthesize timer, keyImageCheck, injectionDateTime, blendedWindow;
@synthesize blendingTypeWindow, blendingTypeMultiply, blendingTypeSubtract, blendingTypeRGB, blendingPlugins, blendingResample;
@synthesize flagListPODComparatives, windowsStateName, titledGantry;
@synthesize movieRateSlider = movieRateSlider, movieTextSlide = movieTextSlide;

// WARNING: If you add or modify this list, check ViewerController.m, DCMView.h and HotKey Pref Pane
static int hotKeyToolCrossTable[] =
{
    WWWLToolHotKeyAction,		//tWL				0
    MoveHotKeyAction,			//tTranslate		1
    ZoomHotKeyAction,			//tZoom				2
    RotateHotKeyAction,			//tRotate			3
    ScrollHotKeyAction,			//tNext				4
    LengthHotKeyAction,			//tMesure			5
    RectangleHotKeyAction,		//tROI				6
    Rotate3DHotKeyAction,		//t3DRotate			7
    OrthoMPRCrossHotKeyAction,	//tCross			8
    OvalHotKeyAction,			//tOval				9
    OpenPolygonHotKeyAction,	//tOPolygon			10
    ClosedPolygonHotKeyAction, //tCPolygon			11
    AngleHotKeyAction,			//tAngle			12
    TextHotKeyAction,			//tText				13
    ArrowHotKeyAction,			//tArrow			14
    PencilHotKeyAction,			//tPencil			15
    -1,                         //t3Dpoint			16
    scissors3DHotKeyAction,		//t3DCut			17
    Camera3DotKeyAction,		//tCamera3D			18
    ThreeDPointHotKeyAction,    //t2DPoint			19
    PlainToolHotKeyAction,		//tPlain			20
    BoneRemovalHotKeyAction,	//tBonesRemoval		21
    -1,							//tWLBlended		22
    RepulsorHotKeyAction,		//tRepulsor			23
    -1,							//tLayerROI			24
    SelectorHotKeyAction,		//tROISelector		25
    -1,							//tAxis				26
    -1,							//tDynAngle			27
    -1,                         //tCurvedROI        28
    -1,                         //tTAGT             29
};

+ (ToolMode) getToolEquivalentToHotKey :(int) h
{
    int m = sizeof( hotKeyToolCrossTable) / sizeof( hotKeyToolCrossTable[ 0]);
    
    for( int i = 0; i < m; i++)
        if( hotKeyToolCrossTable[ i] == h) return i;
    
    return -1;
}

+ (int) getHotKeyEquivalentToTool:(ToolMode) h
{
    if( h <= sizeof( hotKeyToolCrossTable) / sizeof( hotKeyToolCrossTable[ 0]))
    {
        return hotKeyToolCrossTable[ h];
    }
    
    return -1;
}

+ (NSArray*) displayed2DViewerForScreen: (NSScreen*) screen
{
    NSMutableArray *array = [NSMutableArray array];
    
    for( NSWindow *w in [NSApp orderedWindows])
    {
        if( [[w windowController] isKindOfClass:[ViewerController class]] && w.isVisible)
        {
            if( screen == nil || [w.screen isEqual: screen])
            {
                ViewerController *v = w.windowController;
                
                if( v.windowWillClose == NO)
                    [array addObject: v];
            }
        }
    }
    
    return array;
}

static NSMutableDictionary *cachedFrontMostDisplayed2DViewerForScreen = nil;

+ (void) clearFrontMost2DViewerCache
{
    cachedFrontMostDisplayed2DViewer = nil;
    [cachedFrontMostDisplayed2DViewerForScreen removeAllObjects];
    
#ifdef NDEBUG
#else
    NSLog( @"clearFrontMost2DViewerCache");
#endif
}

+ (ViewerController*) frontMostDisplayed2DViewerForScreen: (NSScreen*) screen
{
    if( cachedFrontMostDisplayed2DViewerForScreen == nil)
        cachedFrontMostDisplayed2DViewerForScreen = [NSMutableDictionary new];
    
    NSString *adress = [NSString stringWithFormat: @"%ld", (unsigned long) screen];
    id a = [cachedFrontMostDisplayed2DViewerForScreen objectForKey: adress];
    if( a)
        return a;
    
    for( NSWindow *w in [NSApp orderedWindows])
    {
        if( [[w windowController] isKindOfClass:[ViewerController class]] && w.isVisible)
        {
            if( screen == nil || [w.screen isEqual: screen])
            {
                ViewerController *v = w.windowController;
                
                if( v.windowWillClose == NO)
                {
                    [cachedFrontMostDisplayed2DViewerForScreen setObject: v forKey: adress];
                    return v;
                }
            }
        }
    }
    
    return nil;
}

static ViewerController *cachedFrontMostDisplayed2DViewer = nil;

+ (ViewerController*) frontMostDisplayed2DViewer
{
    if( cachedFrontMostDisplayed2DViewer)
        return cachedFrontMostDisplayed2DViewer;
    
    for( NSWindow *w in [NSApp orderedWindows])
    {
        if( [[w windowController] isKindOfClass:[ViewerController class]] && w.isVisible)
        {
            cachedFrontMostDisplayed2DViewer = w.windowController;
            
            return cachedFrontMostDisplayed2DViewer;
        }
    }
    
    return nil;
}

+ (BOOL) isFrontMost2DViewer: (NSWindow*) ww
{
    if( cachedFrontMostDisplayed2DViewer)
    {
        if( ww == cachedFrontMostDisplayed2DViewer.window)
            return YES;
    }
    
    if( [[ViewerController frontMostDisplayed2DViewer] window] == ww)
        return YES;
    
    return NO;
}

+ (NSMutableArray*) get2DViewers // on screen and off screen
{
    @synchronized( arrayOf2DViewers)
    {
        return [[arrayOf2DViewers copy] autorelease];
    }
    
    return nil;
}

+ (NSMutableArray*) getDisplayed2DViewers
{
    NSMutableArray *viewersList = [NSMutableArray array];
    
    for( ViewerController *w in [ViewerController get2DViewers])
    {
        if( [[w window] isKindOfClass: [NSFullScreenWindow class]])
        {
        }
        else if( [w isKindOfClass:[ViewerController class]])
        {
            if( [w windowWillClose] == NO)
                [viewersList addObject: w];
        }
    }
    
    return viewersList;
}

+ (NSArray*) getDisplayedStudies
{
    NSArray				*displayedViewers = [ViewerController getDisplayed2DViewers];
    NSMutableArray		*studiesArray = [NSMutableArray array];
    
    for( ViewerController *win in displayedViewers)
    {
        if( [[[win imageView] seriesObj] valueForKey:@"study"])
        {
            if( [studiesArray containsObject: [[[win imageView] seriesObj] valueForKey:@"study"]] == NO)
                [studiesArray addObject: [[[win imageView] seriesObj] valueForKey:@"study"]];
        }
    }
    
    return studiesArray;
}

+ (NSArray*) getDisplayedSeries
{
    NSArray				*displayedViewers = [ViewerController getDisplayed2DViewers];
    NSMutableArray		*seriesArray = [NSMutableArray array];
    
    for( ViewerController *win in displayedViewers)
    {
        if( [[win imageView] seriesObj])
        {
            if( [seriesArray containsObject: [[win imageView] seriesObj]] == NO)
                [seriesArray addObject: [[win imageView] seriesObj]];
        }
    }
    
    return seriesArray;
}

+ (NSArray*) studyColors
{
    static NSArray *gStudyColors = nil;
    
    if( gStudyColors == nil)
        gStudyColors = [[NSArray alloc] initWithObjects:
                        [NSColor colorWithDeviceRed:0.4f green:0.4f blue:0.0f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.4f green:0.0f blue:0.4f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.0f green:0.4f blue:0.4f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.4f green:0.0f blue:0.0f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.0f green:0.4f blue:0.0f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.4f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.3f green:0.5f blue:0.0f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.3f green:0.0f blue:0.6f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.0f green:0.5f blue:0.6f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.3f green:0.0f blue:0.0f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.0f green:0.5f blue:0.0f alpha:1.0f],
                        [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.6 alpha:1.0f],
                        nil];
    
    return gStudyColors;
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"ViewerController: %@, %@", self.studyInstanceUID, imageView.studyObj.date];
}

- (long) indexForPix: (long) pixIndex	// for backward compatibility
{
    return pixIndex;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
#ifdef EXPORTTOOLBARITEM
    return YES;
#endif
    BOOL valid = NO;
    
    if( windowWillClose)
        return NO;
    
    if( [[fileList[ 0] lastObject] isKindOfClass:[NSManagedObject class]] == NO)
        return NO;
    
    if( [item action] == @selector( seriesPopupSelect:))
    {
        [self buildSeriesPopup];
        valid = YES;
    }
    else if( [item action] == @selector( displaySUV:))
    {
        if( [[imageView curDCM] hasSUV])
            valid = YES;
    }
    else if( [item action] == @selector( flipDataSeries:))
    {
        if( pixList[ curMovieIndex].count > 1)
            valid = YES;
    }
    else if( [item action] == @selector( navigator:))
    {
        if( [[[self imageView] curDCM] isRGB] && [self isDataVolumicIn4D: YES])
            valid = YES;
    }
    else if( [item action] == @selector( threeDPanel:))
    {
        if( [self isDataVolumicIn4D: YES])
            valid = YES;
    }
    else if( [item action] == @selector( useVOILUT:))
    {
        if( imageView.curDCM.VOILUTApplied)
            [item setState: NSOnState];
        else
            [item setState: [[NSUserDefaults standardUserDefaults] boolForKey: @"UseVOILUT"]];
        
        if( imageView.curDCM.VOILUT_table)
            valid = YES;
    }
    else if( [item action] == @selector(resetWindowsState:))
    {
        NSArray				*studiesArray = [ViewerController getDisplayedStudies];
        for( id loopItem in studiesArray)
        {
            if( [loopItem valueForKey:@"windowsState"]) valid = YES;
        }
    }
    else if( [item action] == @selector(setAllKeyImages:))
    {
        if( postprocessed == NO)
        {
            for( int x = 0 ; x < maxMovieIndex ; x++)
            {
                for( NSManagedObject *o in fileList[ x])
                {
                    if( [[o valueForKey: @"isKeyImage"] boolValue] == NO)
                    {
                        valid = YES;
                        break;
                    }
                }
            }
        }
    }
    else if( [item action] == @selector(setAllNonKeyImages:))
    {
        if( postprocessed == NO)
        {
            for( int x = 0 ; x < maxMovieIndex ; x++)
            {
                for( NSManagedObject *o in fileList[ x])
                {
                    if( [[o valueForKey: @"isKeyImage"] boolValue] == YES)
                    {
                        valid = YES;
                        break;
                    }
                }
            }
        }
    }
    else if( [item action] == @selector(findNextPreviousKeyImage:))
    {
        if( postprocessed == NO)
        {
            DicomStudy *s = [[imageView seriesObj] valueForKey:@"study"];
            
            if( [[s keyImages] count])
                valid = YES;
        }
    }
    else if( [item action] == @selector(loadWindowsState:))
    {
        if( [imageView.studyObj valueForKey:@"windowsState"]) valid = YES;
    }
    else if( [item action] == @selector(roiDeleteAllROIsWithSameName:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(blendWindows:))
    {
        if( numberOf2DViewer > 1) valid = YES;
    }
    else if( [item action] == @selector(roiGetInfo:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(roiHistogram:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(roiVolume:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(roiVolumeEraseRestore:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(createLayerROIFromSelectedROI:))
    {
        if( [self selectedROI])
        {
            valid = YES;
            
            ROI *r = [self selectedROI];
            
            if( r.type == tText) valid = NO;
            if( r.type == tMesure) valid = NO;
            if( r.type == t2DPoint) valid = NO;
            if( r.type == tArrow) valid = NO;
        }
    }
    else if( [item action] == @selector(groupSelectedROIs:))
    {
        if( [[self selectedROIs] count] > 1) valid = YES;
    }
    else if( [item action] == @selector(ungroupSelectedROIs:))
    {
        for( ROI *r in [roiList[curMovieIndex] objectAtIndex: [imageView curImage]])
        {
            if( r.groupID)
            {
                valid = YES;
                break;
            }
        }
    }
    else if( [item action] == @selector(lockSelectedROIs:))
    {
        for( ROI *r in [roiList[ curMovieIndex] objectAtIndex: [imageView curImage]])
        {
            if( r.locked == NO)
            {
                valid = YES;
                break;
            }
        }
    }
    else if( [item action] == @selector(unlockSelectedROIs:))
    {
        for( ROI *r in [roiList[ curMovieIndex] objectAtIndex: [imageView curImage]])
        {
            if( r.locked == YES)
            {
                valid = YES;
                break;
            }
        }
    }
    else if( [item action] == @selector(makeSelectedROIsUnselectable:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(makeAllROIsSelectable:))
    {
        for( ROI *r in [roiList[ curMovieIndex] objectAtIndex: [imageView curImage]])
        {
            if( r.selectable == NO)
            {
                valid = YES;
                break;
            }
        }
    }
    else if( [item action] == @selector(morphoSelectedBrushROI:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(convertBrushPolygon:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(mergeBrushROI:))
    {
        if( [[self selectedROIs] count] > 0)
        {
            for( ROI *i in [self selectedROIs])
            {
                if( i.type == tPlain)
                    valid = YES;
                else
                    valid = NO;
            }
        }
    }
    else if( [item action] == @selector(roiPropagateSetup:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(roiDeleteGeneratedROIs:))
    {
        for( int y = 0; y < maxMovieIndex; y++)
        {
            for( int x = 0; x < [pixList[ y] count]; x++)
            {
                for( int i = 0; i < [[roiList[ y] objectAtIndex: x] count]; i++)
                {
                    ROI *r = [[roiList[ y] objectAtIndex: x] objectAtIndex: i];
                    
                    if( [[r comments] isEqualToString: @"morphing generated"])
                    {
                        valid = YES;
                        break;
                    }
                }
            }
        }
    }
    else if( [item action] == @selector(roiSaveSeries:) || [item action] == @selector(roiSelectDeselectAll:) || [item action] == @selector(roiDeleteAll:) || [item action] == @selector(roiRename:) || [item action] == @selector(setROIsImagesKeyImages:))
    {
        for( int y = 0; y < maxMovieIndex; y++)
        {
            for( int x = 0; x < [pixList[ y] count]; x++)
            {
                for( int i = 0; i < [[roiList[ y] objectAtIndex: x] count]; i++)
                {
                    valid = YES;
                    break;
                }
            }
        }
    }
    else if( [item action] == @selector(roiPropagateSlab:))
    {
        if( [self selectedROI]) valid = YES;
    }
    else if( [item action] == @selector(applyConvolutionOnSource:))
    {
        if( [curConvMenu isEqualToString:NSLocalizedString(@"No Filter", nil)] == NO) valid = YES;
    }
    else if( [item action] == @selector(ConvertToBWMenu:))
    {
        if( [[pixList[ curMovieIndex] objectAtIndex: 0] isRGB] == YES) valid = YES;
    }
    else if( [item action] == @selector(ConvertToRGBMenu:))
    {
        if( [[pixList[ curMovieIndex] objectAtIndex: 0] isRGB] == NO) valid = YES;
    }
    else if( [item action] == @selector(setImageTiling:))
    {
        valid = YES;
        
        int rows = [imageView rows];
        int columns = [imageView columns];
        int tag =  ((rows - 1) * 4) + (columns - 1);
        
        if( [item tag] == tag) [item setState:NSOnState];
        else [item setState:NSOffState];
    }
    else if( [item action] == @selector(SyncSeries:))
    {
        valid = YES;
        [item setState: SYNCSERIES];
    }
    else if( [item action] == @selector(setKeyImage:))
    {
        valid = YES;
        [item setState: [keyImageCheck state]];
    }
    else if( [item action] == @selector(setROITool:) || [item action] == @selector(setDefaultTool:) || [item action] == @selector(setDefaultToolMenu:))
    {
        valid = YES;
        
        NSArray *allKeys = [[DCMView hotKeyDictionary] allKeys];
        
        [item setKeyEquivalentModifierMask: 0];
        [item setKeyEquivalent: @""];
        
        for( NSString *k in allKeys)
        {
            if( [ViewerController getHotKeyEquivalentToTool: [item tag]] >= 0)
            {
                if( [[[DCMView hotKeyDictionary] objectForKey: k] intValue] == [ViewerController getHotKeyEquivalentToTool: [item tag]])
                {
                    [item setKeyEquivalentModifierMask: 0];
                    [item setKeyEquivalent: k];
                }
            }
        }
        
        if( [item tag] == [imageView currentTool]) [item setState:NSOnState];
        else [item setState:NSOffState];
        
        if( [item image] == nil)
        {
            [item setImage: [self imageForROI: [item tag]]];
            [[item image] setSize:ToolsMenuIconSize];
        }
    }
    else if( [item action] == @selector(ApplyCLUT:))
    {
        valid = YES;
        
        if( [[item title] isEqualToString: curCLUTMenu]) [item setState:NSOnState];
        else [item setState:NSOffState];
    }
    else if( [item action] == @selector(ApplyConv:))
    {
        valid = YES;
        
        if( [[item title] isEqualToString: curConvMenu]) [item setState:NSOnState];
        else [item setState:NSOffState];
    }
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
    else valid = YES;
    
    return valid;
}

- (IBAction) resetWindowsState:(id)sender
{
    NSArray *studiesArray = [ViewerController getDisplayedStudies];
    
    for( id loopItem in studiesArray)
    {
        [loopItem setValue: nil forKey:@"windowsState"];
    }
}

- (IBAction) loadWindowsState:(id) sender
{
    BOOL c = [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceLoad"];
    
    if( c == NO) [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"automaticWorkspaceLoad"];
    
    [[BrowserController currentBrowser] databaseOpenStudy: [[imageView seriesObj] valueForKey:@"study"]];
    
    if( c == NO) [[NSUserDefaults standardUserDefaults] setBool: c forKey:@"automaticWorkspaceLoad"];
}

- (IBAction) saveWindowsState:(id) sender
{
    [ViewerController saveWindowsState];
}

- (IBAction) saveWindowsStateAsDICOMSR:(id) sender
{
    self.windowsStateName = [NSUserDefaults formatDateTime: [NSDate date]];
    
    if( saveWindowsStateWindow)
        [NSApp beginSheet: saveWindowsStateWindow modalForWindow: self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    else
        [ViewerController saveWindowsStateWithDICOMSR: YES name: nil];
}

- (IBAction) endSaveWindowsStateAsDICOMSR:(id) sender
{
    [saveWindowsStateWindow orderOut:sender];
    
    [NSApp endSheet: saveWindowsStateWindow returnCode: [sender tag]];
    
    if( [sender tag])
        [ViewerController saveWindowsStateWithDICOMSR: YES name: self.windowsStateName];
}

+ (void) saveWindowsState
{
    [ViewerController saveWindowsStateWithDICOMSR: [[NSUserDefaults standardUserDefaults] boolForKey: @"alwaysArchiveWindowsStateAsDICOMSR"] name: nil];
}

+ (void) saveWindowsStateWithDICOMSR: (BOOL) DICOMSR name: (NSString*) name
{
    NSArray				*displayedViewers = [ViewerController getDisplayed2DViewers];
    NSMutableArray		*state = [NSMutableArray array];
    
    int indexImage;
    
    if( name.length == 0)
        name = [NSUserDefaults formatDateTime: [NSDate date]];
    
    @try
    {
        for( ViewerController *win in displayedViewers)
        {
            DCMView *view = [win imageView];
            //            if ([[view curDCM] generated])
            //                continue;
            
            NSMutableDictionary	*dict = [NSMutableDictionary dictionary];
            
            if( [win studyInstanceUID] && [[view seriesObj] valueForKey:@"seriesInstanceUID"])
            {
                NSRect	r = [[win window] frame];
                [dict setObject: name forKey: @"name"];
                [dict setObject: [NSString stringWithFormat: @"%f %f %f %f", r.origin.x, r.origin.y, r.size.width, r.size.height]  forKey:@"window position"];
                [dict setObject: NSStringFromRect( [AppController usefullRectForScreen: win.window.screen]) forKey: @"screen"];
                [dict setObject: @([[NSScreen screens] indexOfObject: win.window.screen]) forKey:@"screenIndex"];
                [dict setObject: @([view rows]) forKey:@"rows"];
                [dict setObject: @([view columns]) forKey:@"columns"];
                
                if( [view flippedData]) indexImage = [win getNumberOfImages] -1 -[[[win seriesView] firstView] curImage];
                else indexImage = [[[win seriesView] firstView] curImage];
                
                [dict setObject: @(indexImage) forKey:@"index"];
                
                if( [[view curDCM] SUVConverted] == NO)
                {
                    [dict setObject: @([view curWL]) forKey:@"wl"];
                    [dict setObject: @([view curWW]) forKey:@"ww"];
                }
                else
                {
                    [dict setObject: @([view curWL] / [win factorPET2SUV]) forKey:@"wl"];
                    [dict setObject: @([view curWW] / [win factorPET2SUV]) forKey:@"ww"];
                }
                [dict setObject: @([view scaleValue]) forKey:@"scale"];
                [dict setObject: @([view origin].x) forKey:@"x"];
                [dict setObject: @([view origin].y) forKey:@"y"];
                [dict setObject: @([view rotation]) forKey:@"rotation"];
                [dict setObject: @([view xFlipped]) forKey:@"xFlipped"];
                [dict setObject: @([view xFlipped]) forKey:@"yFlipped"];
                
                [dict setObject: [win studyInstanceUID] forKey:@"studyInstanceUID"];
                
                NSMutableArray *seriesUIDs = [NSMutableArray array];
                for( int x = 0 ; x <  [win maxMovieIndex] ; x++)
                {
                    DCMPix *dcmPix = [[win pixList: x] objectAtIndex: 0];
                    
                    if( dcmPix.seriesObj)
                        [seriesUIDs addObject: [dcmPix.seriesObj valueForKey:@"seriesInstanceUID"]];
                }
                
                BOOL allSeriesUIDidentical = YES;
                
                for( NSString *uid in seriesUIDs)
                {
                    if( [uid isEqualToString: [seriesUIDs lastObject]] == NO) allSeriesUIDidentical = NO;
                }
                
                if( allSeriesUIDidentical == NO)
                    [dict setObject: [seriesUIDs componentsJoinedByString:@"\\**\\"] forKey:@"seriesInstanceUID"];
                else if( seriesUIDs.count)
                    [dict setObject: [seriesUIDs lastObject] forKey:@"seriesInstanceUID"];
                
                [dict setObject: [win.currentSeries valueForKey:@"seriesDICOMUID"] forKey:@"seriesDICOMUID"];
                
                if( [win maxMovieIndex] > 1)
                    [dict setObject: @YES forKey:@"4DData"];
                else
                    [dict setObject: @NO forKey:@"4DData"];
                
                if( [[NSUserDefaults standardUserDefaults] objectForKey:@"LastWindowsTilingRowsColumns"])
                    [dict setObject: [[NSUserDefaults standardUserDefaults] objectForKey:@"LastWindowsTilingRowsColumns"] forKey:@"LastWindowsTilingRowsColumns"];
                
                [dict setObject: [[NSUserDefaults standardUserDefaults] objectForKey:@"COPYSETTINGS"] forKey:@"propagateSettings"];
                
                if( [DCMView syncro] == syncroLOC)
                    [dict setObject: @YES forKey:@"syncSettings"];
                else if( [DCMView syncro] == syncroOFF)
                    [dict setObject: @NO forKey:@"syncSettings"];
                
                if( SyncButtonBehaviorIsBetweenStudies)
                {
                    [dict setObject: @YES forKey:@"SyncButtonBehaviorIsBetweenStudies"];
                    [dict setObject: @(SYNCSERIES) forKey: @"SYNCSERIES"];
                    [dict setObject: @(view.syncRelativeDiff) forKey:@"syncRelativeDiff"];
                }
                else
                {
                    [dict setObject: @NO forKey:@"SyncButtonBehaviorIsBetweenStudies"];
                    [dict setObject: @(SYNCSERIES) forKey: @"SYNCSERIES"];
                }
                
                [dict setObject: [NSDate date] forKey:@"date"];
                
                [state addObject: dict];
            }
        }
        
        if( [displayedViewers count] != [state count]) return;	//We will save the states ONLY if we can save the state of ALL DISPLAYED windows !:!:!:
        
        //	NSString	*tmp = [NSString stringWithFormat:@"/tmp/windowsState"];
        //	[[NSFileManager defaultManager] removeItemAtPath: tmp error:NULL];
        //	[state writeToFile: tmp atomically: YES];
        
        NSData *windowsState = [NSPropertyListSerialization dataFromPropertyList: state  format: NSPropertyListXMLFormat_v1_0 errorDescription: nil];
        
        NSMutableArray	*studiesArray = [NSMutableArray array];
        
        for( ViewerController *win in displayedViewers)
        {
            DCMView *view = [win imageView];
            if ([[view curDCM] generated])
                continue;
            
            if( [[view seriesObj] valueForKey:@"seriesInstanceUID"])
            {
                if( [studiesArray containsObject: [[view seriesObj] valueForKey:@"study"]] == NO)
                    [studiesArray addObject: [[view seriesObj] valueForKey:@"study"]];
            }
        }
        
        for( DicomStudy *study in studiesArray)
        {
            [study setValue: windowsState forKey:@"windowsState"];
            
            if( DICOMSR)
                [study archiveWindowsStateAsDICOMSR];
        }
    }
    @catch (NSException *e) {
        N2LogExceptionWithStackTrace( e);
    }
}

- (void) executeUndo:(NSMutableArray*) u
{
    if( [u count])
    {
        [imageView stopROIEditing];
        
        if( [[[u lastObject] objectForKey: @"type"] isEqualToString:@"roi"])
        {
            NSMutableArray	*rois = [[u lastObject] objectForKey: @"rois"];
            
            int i, x, z;
            
            for( i = 0; i < maxMovieIndex; i++)
            {
                for( x = 0; x < [roiList[ i] count] ; x++)
                {
                    for( z = 0; z < [[roiList[ i] objectAtIndex: x] count]; z++)
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:[[roiList[ i] objectAtIndex: x] objectAtIndex: z] userInfo: nil];
                    
                    [[roiList[ i] objectAtIndex: x] removeAllObjects];
                }
            }
            
            for( i = 0; i < maxMovieIndex; i++)
            {
                NSArray *r = [rois objectAtIndex: i];
                
                for( x = 0; x < [roiList[ i] count] ; x++)
                {
                    [[roiList[ i] objectAtIndex: x] addObjectsFromArray: [r objectAtIndex: x]];
                    
                    for( ROI *r in [roiList[ i] objectAtIndex: x])
                    {
                        [imageView roiSet: r];
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object: r userInfo: nil];
                    }
                }
            }
            
            [imageView setIndex: [imageView curImage]];
            
            NSLog( @"roi undo");
            
            [u removeLastObject];
        }
    }
}

- (IBAction) redo:(id) sender
{
    if( [redoQueue count])
    {
        [undoQueue addObject: [self prepareObjectForUndo: [[redoQueue lastObject] objectForKey:@"type"]]];
        
        [self executeUndo: redoQueue];
    }
    else NSBeep();
}

- (IBAction) undo:(id) sender
{
    if( [undoQueue count])
    {
        [redoQueue addObject: [self prepareObjectForUndo: [[undoQueue lastObject] objectForKey:@"type"]]];
        
        [self executeUndo: undoQueue];
    }
    else NSBeep();
}

- (id) prepareObjectForUndo:(NSString*) string
{
    @try {
        if( [string isEqualToString: @"roi"])
        {
            NSMutableArray	*rois = [NSMutableArray array];
            
            for( int i = 0; i < maxMovieIndex; i++)
            {
                NSMutableArray *array = [NSMutableArray array];
                for( NSArray *ar in roiList[ i])
                {
                    NSMutableArray	*a = [NSMutableArray array];
                    
                    for( ROI *r in ar)
                        [a addObject: [[r copy] autorelease]];
                    
                    [array addObject: a];
                }
                [rois addObject: array];
            }
            
            return [NSDictionary dictionaryWithObjectsAndKeys: string, @"type", rois, @"rois", nil];
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    return nil;
}

- (void) removeLastItemFromUndoQueue
{
    if( [undoQueue count])
        [undoQueue removeLastObject];
}

- (void) addToUndoQueue:(NSString*) string
{
    if( [[NSUserDefaults standardUserDefaults] integerForKey: @"UndoQueueSize"] <= 0)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DontUseUndoQueueForROIs"] == NO)
        [undoQueue addObject: [self prepareObjectForUndo: string]];
    
    if( [undoQueue count] > [[NSUserDefaults standardUserDefaults] integerForKey: @"UndoQueueSize"])
    {
        [undoQueue removeObjectAtIndex: 0];
    }
}

#pragma mark-
#pragma mark 1. window and workplace

+ (void) correctGangtryTilt: (ViewerController*) viewerController
{
#ifdef OSIRIX_LIGHT
    N2LogStackTrace( @"Function NOT available in light version");
#else
    DCMPix *curPix;
    BOOL OK = YES;
    
    NSArray *pixList = [viewerController pixList];
    
    curPix = [pixList objectAtIndex: pixList.count/2];   //pixList.count/2];
    
    long imageSize, size;
    
    
    id w = [viewerController startWaitProgressWindow: NSLocalizedString( @"Gantry Tilt Correction", nil) :pixList.count];
    
    @try
    {
        imageSize = [curPix pwidth] * [curPix pheight];
        size = sizeof(float) * [pixList count]/2 * imageSize;
        
        double orientation[ 9];
        double origin[ 3];
        double matrix[ 12];
        
        [curPix orientationDouble: orientation];
        origin[ 0] = [curPix originX]; origin[ 1] = [curPix originY]; origin[ 2] = [curPix originZ];
        
        for( DCMPix *p in pixList)
        {
            double o[ 9];
            double xyz[ 3];
            
            [p orientationDouble: o];
            xyz[ 0] = [p originX]; xyz[ 1] = [p originY]; xyz[ 2] = [p originZ];
            
            BOOL equal = YES;
            for( int i = 0 ; i < 6 ; i++)
            {
                if( o[ i] != orientation[ i])
                    equal = NO;
            }
            
            if( equal == NO)
            {
                NSRunInformationalAlertPanel( NSLocalizedString(@"Error!", nil), NSLocalizedString(@"These slices have not the same orientation. Gantry Tilt Correction cannot be applied to this dataset.", nil), NSLocalizedString(@"OK", nil), 0L, 0L);
                OK = NO;
                break;
            }
        }
        
        if( OK)
        {
            for( DCMPix *p in pixList)
            {
                if( p != curPix)
                {
                    double o[ 9];
                    double xyz[ 3];
                    
                    [p orientationDouble: o];
                    xyz[ 0] = [p originX]; xyz[ 1] = [p originY]; xyz[ 2] = [p originZ];
                    
                    double vectorModel[ 9], vectorSensor[ 9];
                    
                    [p orientationDouble: vectorSensor];
                    [curPix orientationDouble: vectorModel];
                    
                    double length;
                    
                    // --
                    matrix[ 9] = xyz[ 0] - origin[ 0];
                    matrix[ 10] = xyz[ 1] - origin[ 1];
                    matrix[ 11] = xyz[ 2] - origin[ 2];
                    // --
                    
                    matrix[ 0] = vectorSensor[ 0] * vectorModel[ 0] + vectorSensor[ 1] * vectorModel[ 1] + vectorSensor[ 2] * vectorModel[ 2];
                    matrix[ 1] = vectorSensor[ 0] * vectorModel[ 3] + vectorSensor[ 1] * vectorModel[ 4] + vectorSensor[ 2] * vectorModel[ 5];
                    matrix[ 2] = vectorSensor[ 0] * vectorModel[ 6] + vectorSensor[ 1] * vectorModel[ 7] + vectorSensor[ 2] * vectorModel[ 8];
                    
                    length = sqrt(matrix[0]*matrix[0] + matrix[1]*matrix[1] + matrix[2]*matrix[2]);
                    
                    matrix[0] = matrix[ 0] / length;
                    matrix[1] = matrix[ 1] / length;
                    matrix[2] = matrix[ 2] / length;
                    
                    // --
                    
                    matrix[ 3] = vectorSensor[ 3] * vectorModel[ 0] + vectorSensor[ 4] * vectorModel[ 1] + vectorSensor[ 5] * vectorModel[ 2];
                    matrix[ 4] = vectorSensor[ 3] * vectorModel[ 3] + vectorSensor[ 4] * vectorModel[ 4] + vectorSensor[ 5] * vectorModel[ 5];
                    matrix[ 5] = vectorSensor[ 3] * vectorModel[ 6] + vectorSensor[ 4] * vectorModel[ 7] + vectorSensor[ 5] * vectorModel[ 8];
                    
                    length = sqrt(matrix[3]*matrix[3] + matrix[4]*matrix[4] + matrix[5]*matrix[5]);
                    
                    matrix[3] = matrix[ 3] / length;
                    matrix[4] = matrix[ 4] / length;
                    matrix[5] = matrix[ 5] / length;
                    
                    // --
                    
                    matrix[6] = matrix[1]*matrix[5] - matrix[2]*matrix[4];
                    matrix[7] = matrix[2]*matrix[3] - matrix[0]*matrix[5];
                    matrix[8] = matrix[0]*matrix[4] - matrix[1]*matrix[3];
                    
                    length = sqrt(matrix[6]*matrix[6] + matrix[7]*matrix[7] + matrix[8]*matrix[8]);
                    
                    matrix[6] = matrix[ 6] / length;
                    matrix[7] = matrix[ 7] / length;
                    matrix[8] = matrix[ 8] / length;
                    
                    long size;
                    
                    float *resultBuff = [ITKTransform reorient2Dimage: matrix firstObject: curPix firstObjectOriginal: p length: &size];
                    if( resultBuff)
                    {
                        memcpy( [p fImage] , resultBuff, size);
                        free( resultBuff);
                    }
                    else
                    {
                        NSRunInformationalAlertPanel( NSLocalizedString( @"Error!", nil), NSLocalizedString( @"Not Enough Memory", nil), NSLocalizedString(@"OK", nil), 0L, 0L);
                        break;
                    }
                    
                    // Project the 3D point on the plane : dot product of normal plane vector (vectorModel) and distance between point and plane origin (matrix9,10,11)
                    double distance = matrix[ 9] * vectorModel[ 6] + matrix[ 10] * vectorModel[ 7] + matrix[ 11] * vectorModel[ 8];
                    double outputOrigin[ 3];
                    
                    outputOrigin[0] = origin[ 0] + distance*vectorModel[ 6];
                    outputOrigin[1] = origin[ 1] + distance*vectorModel[ 7];
                    outputOrigin[2] = origin[ 2] + distance*vectorModel[ 8];
                    
                    [p setOriginDouble: outputOrigin];
                }
                
                [viewerController waitIncrementBy:w :1];
            }
            
            for( DCMPix *p in pixList)
                [p setSliceInterval: 0];
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    [viewerController endWaitWindow: w];
    
    // We modified the view: OsiriX please update the display!
    [viewerController needsDisplayUpdate];
#endif
}

- (void) refreshMenus
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: curConvMenu userInfo: nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
    
    [clutPopup setTitle:curCLUTMenu];
    [convPopup setTitle:curConvMenu];
    [wlwwPopup setTitle:curWLWWMenu];
    [OpacityPopup setTitle:curOpacityMenu];
}

- (void) refresh
{
    float   iwl, iww;
    [imageView getWLWW:&iwl :&iww];
    [imageView setWLWW:iwl :iww];
}

- (BOOL) isPostprocessed
{
    return postprocessed;
}

- (void) setPostprocessed:(BOOL) v
{
    postprocessed = v;
    [[NavigatorWindowController navigatorWindowController] initView];
    [self updateNavigator];
}

- (BOOL) postprocessed
{
    return postprocessed;
}

- (void) replaceSeriesWith:(NSMutableArray*)newPixList :(NSMutableArray*)newDcmList :(NSData*) newData
{
    [self changeImageData:newPixList :newDcmList :newData :NO];
    [self setPostprocessed: YES];
    
    [self computeInterval];
    [self setWindowTitle:self];
    [imageView setIndex: [newPixList count]/2];
    [imageView sendSyncMessage:0];
    [self adjustSlider];
}

static volatile int numberOfThreadsForRelisce = 0;

- (BOOL) waitForAProcessor
{
    int processors =  [[NSProcessInfo processInfo] processorCount];
    
    [processorsLock lockWhenCondition: 1];
    BOOL result = numberOfThreadsForRelisce >= processors;
    if( result == NO)
    {
        numberOfThreadsForRelisce++;
        if( numberOfThreadsForRelisce >= processors)
        {
            [processorsLock unlockWithCondition: 0];
        }
        else
        {
            [processorsLock unlockWithCondition: 1];
        }
    }
    else
    {
        NSLog( @"waitForAProcessor ?? We should not be here...");
        [processorsLock unlockWithCondition: 0];
    }
    
    return result;
}

- (void) resliceThread:(NSDictionary*) dict
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    
    int i = [[dict valueForKey:@"i"] intValue];
    int sign = [[dict valueForKey:@"sign"] intValue];
    int newX = [[dict valueForKey:@"newX"] intValue];
    int newY = [[dict valueForKey:@"newY"] intValue];
    BOOL square = [[dict valueForKey:@"square"] boolValue];
    DCMPix *curPix = [dict valueForKey:@"curPix"];
    register float *restrict curPixFImage = [[dict valueForKey:@"curPix"] fImage];
    int rowBytes = [[dict valueForKey:@"rowBytes"] intValue] / 4;
    int j = [[dict valueForKey:@"curMovieIndex"] intValue];
    
    register float *restrict srcPtr, *restrict dstPtr, *restrict mainSrcPtr;
    int count = [pixList[ j] count];
    
    count /= 2;
    count *= 2;
    
    if( sign > 0)
        mainSrcPtr = [[pixList[ j] objectAtIndex: count-1] fImage];
    else
        mainSrcPtr = [[pixList[ j] objectAtIndex: 0] fImage];
    
    int sliceSize = [[pixList[ j] objectAtIndex: 0] pwidth] * [[pixList[ j] objectAtIndex: 0] pheight];
    
    mainSrcPtr += i;
    
    if( sign > 0)
    {
        int x = count;
        while (x-->0)
        {
            srcPtr = mainSrcPtr - x*sliceSize;
            dstPtr = curPixFImage + x * newX;
            
            int y = newX;
            while (y-->0)
            {
                *dstPtr++ = *srcPtr;
                srcPtr += rowBytes;
            }
        }
    }
    else
    {
        int x = count;
        while (x-->0)
        {
            srcPtr = mainSrcPtr + x*sliceSize;
            dstPtr = curPixFImage + x * newX;
            
            int y = newX;
            while (y-->0)
            {
                *dstPtr++ = *srcPtr;
                srcPtr += rowBytes;
            }
        }
    }
    
    if( square)
    {
        vImage_Buffer	srcVimage, dstVimage;
        
        srcVimage.data = [curPix fImage];
        srcVimage.height =  [pixList[ j] count];
        srcVimage.width = newX;
        srcVimage.rowBytes = newX*4;
        
        dstVimage.data = [curPix fImage];
        dstVimage.height =  newY;
        dstVimage.width = newX;
        dstVimage.rowBytes = newX*4;
        
        vImageScale_PlanarF( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
    }
    
    [processorsLock lock];
    if( numberOfThreadsForRelisce >= 0) numberOfThreadsForRelisce--;
    [processorsLock unlockWithCondition: 1];
    
    [pool release];
}

-(BOOL) processReslice:(long) directionm :(BOOL) newViewer
{
    DCMPix				*firstPix = [pixList[ curMovieIndex] objectAtIndex: 0];
    DCMPix				*lastPix = nil;
    long				i, newTotal;
    unsigned char		*emptyData;
    long				imageSize, size, y, newX, newY;
    double				orientation[ 9], newXSpace, newYSpace, origin[ 3], sign;
    BOOL				square = NO;
    BOOL				succeed = YES;
    
    NSString			*previousCLUT = [curCLUTMenu retain];
    NSString			*previousOpacity = [curOpacityMenu retain];
    
    if( [pixList[ curMovieIndex] count] < 100 && firstPix.pheight <= 256 && firstPix.pwidth <= 256)
        square = YES;
    
    // Get Values
    if( directionm == 0)		// X - RESLICE
    {
        newTotal = [firstPix pheight];
        
        newX = [firstPix pwidth];
        
        if( square)
        {
            newXSpace = [firstPix pixelSpacingX];
            newYSpace = [firstPix pixelSpacingX];
            
            newY = ([pixList[ curMovieIndex] count] * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingX];
            
            int even = newY / 2;
            even *= 2;
            
            if( even <= [pixList[ curMovieIndex] count])
            {
                NSLog( @"---- newY < [pixList[ curMovieIndex] count]");
                square = NO;
            }
        }
        
        if( square == NO)
        {
            newXSpace = [firstPix pixelSpacingX];
            newYSpace = fabs( [firstPix sliceInterval]);
            newY = [pixList[ curMovieIndex] count];
        }
    }
    else
    {
        newTotal = [firstPix pwidth];				// Y - RESLICE
        
        newX = [firstPix pheight];
        
        if( square)
        {
            newXSpace = [firstPix pixelSpacingY];
            newYSpace = [firstPix pixelSpacingY];
            
            newY = ([pixList[ curMovieIndex] count]  * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingY];
            
            int even = newY / 2;
            even *= 2;
            
            if( even <= [pixList[ curMovieIndex] count])
            {
                NSLog( @"---- newY < [pixList[ curMovieIndex] count]");
                square = NO;
            }
        }
        
        
        if( square == NO)
        {
            newY = [pixList[ curMovieIndex] count];
            
            newXSpace = [firstPix pixelSpacingY];
            newYSpace = fabs( [firstPix sliceInterval]);
        }
    }
    
    newX /= 2;
    newX *= 2;
    
    newY /= 2;
    newY *= 2;
    
    i =  [pixList[ curMovieIndex] count];
    i /= 2;
    i *= 2;
    i--;
    lastPix = [pixList[ curMovieIndex] objectAtIndex: i];
    
    sign = 1.0;
    
    imageSize = sizeof(float) * newX * newY;
    size = newTotal * imageSize;
    
    NSMutableArray *xPix = [NSMutableArray array];
    NSMutableArray *xFiles = [NSMutableArray array];
    NSMutableArray *xData = [NSMutableArray array];
    
    succeed = YES;
    
    for( int j = 0 ; j < maxMovieIndex && succeed == YES; j++)
    {
        firstPix = [pixList[ j] objectAtIndex: 0];
        
        // CREATE A NEW SERIES WITH ALL IMAGES !
        emptyData = malloc( size);
        if( emptyData)
        {
            NSMutableArray	*newPixList = [NSMutableArray array];
            NSMutableArray	*newDcmList = [NSMutableArray array];
            
            NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
            
            NSLog( @"reslice start");
            
#ifdef VIMAGEYRESLICE
            if( directionm)
            {
                vImage_Buffer src;
                vImage_Buffer dst;
                
                src.height = firstPix.pheight * newY;
                src.width = firstPix.pwidth;
                src.rowBytes = src.width*4;
                src.data = firstPix.fImage;
                
                dst.width = firstPix.pheight * newY;
                dst.height = firstPix.pwidth;
                dst.rowBytes = dst.width*4;
                dst.data = emptyData;
                
                vImageRotate90_PlanarF( &src, &dst, kRotate270DegreesClockwise, 0, 0);
            }
#endif
            
            // Display a waiting window
            id waitWindow = [self startWaitProgressWindow: NSLocalizedString( @"Reslicing...", nil) :newTotal];
            
            for( i = 0 ; i < newTotal; i ++)
            {
                [newPixList addObject: [[[pixList[ j] objectAtIndex: 0] copy] autorelease]];
                
                // SUV
                [[newPixList lastObject] setDisplaySUVValue: [firstPix displaySUVValue]];
                [[newPixList lastObject] setSUVConverted: [firstPix SUVConverted]];
                [[newPixList lastObject] setFactorPET2SUV: [firstPix factorPET2SUV]];
                [[newPixList lastObject] setRadiopharmaceuticalStartTime: [firstPix radiopharmaceuticalStartTime]];
                [[newPixList lastObject] setPatientsWeight: [firstPix patientsWeight]];
                [[newPixList lastObject] setRadionuclideTotalDose: [firstPix radionuclideTotalDose]];
                [[newPixList lastObject] setRadionuclideTotalDoseCorrected: [firstPix radionuclideTotalDoseCorrected]];
                [[newPixList lastObject] setAcquisitionTime: [firstPix acquisitionTime]];
                [[newPixList lastObject] setDecayCorrection: [firstPix decayCorrection]];
                [[newPixList lastObject] setDecayFactor: [firstPix decayFactor]];
                [[newPixList lastObject] setUnits: [firstPix units]];
                
                [[newPixList lastObject] setPwidth: newX];
                //				[[newPixList lastObject] setRowBytes: newX*sizeof(float)];
                [[newPixList lastObject] setPheight: newY];
                
                [[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
                [[newPixList lastObject] setTot: newTotal];
                [[newPixList lastObject] setFrameNo: (long)[newPixList count]-1];
                [[newPixList lastObject] setID: (long)[newPixList count]-1];
                
                if( [fileList[ j] count])
                {
                    [newDcmList addObject: [fileList[ j] objectAtIndex: 0]];
                }
                
                if( directionm == 0)		// X - RESLICE
                {
                    DCMPix	*curPix = [newPixList lastObject];
                    
                    int count = [pixList[ j] count];
                    int pwidth = [[pixList[ j] objectAtIndex: 0] pwidth];
                    
                    count /= 2;
                    count *= 2;
                    
                    if( sign > 0)
                    {
                        for( y = 0; y < count; y++)
                        {
                            memcpy(	[curPix fImage] + (count-y-1) * newX,
                                   [[pixList[ j] objectAtIndex: y] fImage] + i * pwidth,
                                   newX * sizeof( float));
                        }
                    }
                    else
                    {
                        for( y = 0; y < count; y++)
                        {
                            memcpy(	[curPix fImage] + y * newX,
                                   [[pixList[ j] objectAtIndex: y] fImage] + i * pwidth,
                                   newX * sizeof( float));
                        }
                    }
                    
                    if( square)
                    {
                        vImage_Buffer	srcVimage, dstVimage;
                        
                        srcVimage.data = [curPix fImage];
                        srcVimage.height =  count;
                        srcVimage.width = newX;
                        srcVimage.rowBytes = newX*4;
                        
                        dstVimage.data = [curPix fImage];
                        dstVimage.height =  newY;
                        dstVimage.width = newX;
                        dstVimage.rowBytes = newX*4;
                        
                        vImageScale_PlanarF( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
                    }
                    
                    [lastPix orientationDouble: orientation];
                    
                    orientation[ 3] = orientation[ 6] * -sign;
                    orientation[ 4] = orientation[ 7] * -sign;
                    orientation[ 5] = orientation[ 8] * -sign;
                    
                    [curPix setOrientationDouble: orientation];	// Normal vector is recomputed in this procedure
                    
                    [curPix setPixelSpacingX: newXSpace];
                    [curPix setPixelSpacingY: newYSpace];
                    
                    [curPix setPixelRatio:  newYSpace / newXSpace];
                    
                    [curPix orientationDouble: orientation];
                    
                    [lastPix convertPixDoubleX:0 pixY: i toDICOMCoords: origin pixelCenter: NO];
                    
                    [curPix setOriginDouble: origin];
                    
                    [curPix computeSliceLocation];
                    
                    [curPix setSliceThickness: [firstPix pixelSpacingY]];
                    [curPix setSliceInterval: 0];
                    
                }
                else											// Y - RESLICE
                {
                    DCMPix	*curPix = [newPixList lastObject];
                    long	rowBytes = [firstPix pwidth]*4;
                    
#ifndef VIMAGEYRESLICE
                    [self waitForAProcessor];
                    
                    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys: @(i), @"i", @(sign), @"sign", @(newX), @"newX", @(newY), @"newY", @(square), @"square", [NSNumber numberWithInt: rowBytes], @"rowBytes", curPix, @"curPix", @(j), @"curMovieIndex", nil];
                    
                    [NSThread detachNewThreadSelector: @selector(resliceThread:) toTarget:self withObject: d];
#endif
                    [lastPix orientationDouble: orientation];
                    
                    // Y Vector = Normal Vector
                    orientation[ 0] = orientation[ 3];
                    orientation[ 1] = orientation[ 4];
                    orientation[ 2] = orientation[ 5];
                    
                    orientation[ 3] = orientation[ 6] * -sign;
                    orientation[ 4] = orientation[ 7] * -sign;
                    orientation[ 5] = orientation[ 8] * -sign;
                    
                    [curPix setOrientationDouble: orientation];	// Normal vector is recomputed in this procedure
                    
                    [curPix setPixelSpacingX: newXSpace];
                    [curPix setPixelSpacingY: newYSpace];
                    
                    [curPix setPixelRatio:  newYSpace / newXSpace];
                    
                    [curPix orientationDouble: orientation];
                    
                    [lastPix convertPixDoubleX:i pixY:0 toDICOMCoords: origin pixelCenter: NO];
                    
                    [curPix setOriginDouble: origin];
                    
                    [curPix computeSliceLocation];
                    
                    [curPix setSliceThickness: [firstPix pixelSpacingX]];
                    [curPix setSliceInterval: 0];
                }
                
                [self waitIncrementBy:waitWindow :1];
            }
            
            BOOL finished = NO;
            do
            {
                [processorsLock lockWhenCondition: 1];
                if( numberOfThreadsForRelisce <= 0)
                {
                    finished = YES;
                    [processorsLock unlockWithCondition: 1];
                }
                else [processorsLock unlockWithCondition: 0];
            }
            while( finished == NO);
            
            NSLog( @"reslice end");
            
            [xData addObject: newData];
            [xFiles addObject: newDcmList];
            [xPix addObject: newPixList];
            
            postprocessed = YES;
            
            // Close the waiting window
            [self endWaitWindow: waitWindow];
        }
        else succeed = NO;
    }
    
    if( succeed)
    {
        int mx = maxMovieIndex;
        
        for( int j = 0 ; j < mx; j++)
        {
            if( j == 0)
            {
                if( newViewer)
                {
                    ViewerController	*new2DViewer;
                    
                    // CREATE A SERIES
                    new2DViewer = [self newWindow: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j]];
                    [new2DViewer setImageIndex: [[xPix objectAtIndex: j] count] /2];
                    [[new2DViewer window] makeKeyAndOrderFront: self];
                }
                else
                {
                    [self changeImageData: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j] :NO];
                }
            }
            else
            {
                [self addMovieSerie: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j]];
            }
        }
        
        [self setPostprocessed: YES];
        
        [self computeInterval];
        [self setWindowTitle:self];
        [imageView setIndex: [[xPix objectAtIndex: 0] count]/2];
        [imageView sendSyncMessage:0];
        [self adjustSlider];
        
        [self ApplyCLUTString: previousCLUT];
        [self ApplyOpacityString: previousOpacity];
    }
    
    [previousCLUT release];
    [previousOpacity release];
    
    return succeed;
}

+ (int) orientation:(double*) vectors
{
    int o = 0;
    
    if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))	o = 0;
    if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))	o = 1;
    if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))	o = 2;
    
    return o;
}

- (IBAction) vertFlipDataSet:(id) sender
{
    int y, x;
    
    for( y = 0 ; y < maxMovieIndex; y++)
    {
        DCMPix			*firstObject = [pixList[ y] objectAtIndex: 0];
        float			*volumeDataPtr = [firstObject fImage];
        vImage_Buffer	src, dest;
        
        dest.data = malloc( [firstObject pheight] * [firstObject pwidth] * 4);
        
        if( dest.data)
        {
            for( x = 0; x < [pixList[ y] count]; x++)
            {
                src.height = dest.height = [firstObject pheight];
                src.width = dest.width = [firstObject pwidth];
                src.rowBytes = src.width*4;
                dest.rowBytes = dest.width*4;
                src.data = volumeDataPtr;
                
                vImageVerticalReflect_PlanarF ( &src, &dest, 0);
                
                memcpy( src.data, dest.data, [firstObject pheight] * [firstObject pwidth] * 4);
                volumeDataPtr += [firstObject pheight]*[firstObject pwidth];
            }
            
            free( dest.data);
        }
        else NSLog( @"***** not enough memory : vertFlipDataSet");
    }
    
    for( y = 0 ; y < maxMovieIndex; y++)
    {
        for( x = 0; x < [pixList[ y] count]; x++)
        {
            double	o[ 9], origin[ 3];
            DCMPix	*dcm = [pixList[ y] objectAtIndex: x];
            
            [dcm orientationDouble: o];
            
            o[ 3] *= -1;
            o[ 4] *= -1;
            o[ 5] *= -1;
            
            [dcm setOrientationDouble: o];
            [dcm setSliceInterval: 0];
            
            [dcm convertPixDoubleX: 0 pixY: -[dcm pheight]+1 toDICOMCoords: origin pixelCenter: NO];
            
            [dcm setOriginDouble: origin];
            
            [dcm computeSliceLocation];
        }
    }
    
    [self setPostprocessed: YES];
    
    [self computeInterval];
    [self updateImage: self];
}

- (IBAction) horzFlipDataSet:(id) sender
{
    int y, x;
    
    for( y = 0 ; y < maxMovieIndex; y++)
    {
        DCMPix	*firstObject = [pixList[ y] objectAtIndex: 0];
        float	*volumeDataPtr = [firstObject fImage];
        
        vImage_Buffer src, dest;
        
        src.height = dest.height = [firstObject pheight]*[pixList[ y] count];
        src.width = dest.width = [firstObject pwidth];
        src.rowBytes = dest.rowBytes = src.width*4;
        src.data = dest.data = volumeDataPtr;
        
        vImageHorizontalReflect_PlanarF ( &src, &dest, 0);
    }
    
    for( y = 0 ; y < maxMovieIndex; y++)
    {
        for( x = 0; x < [pixList[ y] count]; x++)
        {
            double	o[ 9];
            DCMPix	*dcm = [pixList[ y] objectAtIndex: x];
            
            [dcm orientationDouble: o];
            
            o[ 0] *= -1;
            o[ 1] *= -1;
            o[ 2] *= -1;
            
            [dcm setOrientationDouble: o];
            [dcm setSliceInterval: 0];
            
            double	origin[3];
            
            [dcm convertPixDoubleX: -[dcm pwidth]+1 pixY: 0 toDICOMCoords: origin pixelCenter: NO];
            [dcm setOriginDouble: origin];
            
            [dcm computeSliceLocation];
        }
    }
    
    [self setPostprocessed: YES];
    
    [self computeInterval];
    [self updateImage: self];
}

- (void) rotateDataSet:(int) constant
{
    int y, x;
    double rot = 0;
    
    switch( constant)
    {
        case kRotate90DegreesClockwise:		rot = 90;		break;
        case kRotate180DegreesClockwise:	rot = 180;		break;
        case kRotate270DegreesClockwise:	rot = 270;		break;
    }
    
    for( y = 0 ; y < maxMovieIndex; y++)
    {
        DCMPix			*firstObject = [pixList[ y] objectAtIndex: 0];
        float			*volumeDataPtr = [firstObject fImage];
        vImage_Buffer	src, dest;
        
        dest.data = malloc( [firstObject pheight] * [firstObject pwidth] * 4);
        
        for( x = 0; x < [pixList[ y] count]; x++)
        {
            src.height = dest.height = [firstObject pheight];
            src.width = dest.width = [firstObject pwidth];
            
            if( constant == kRotate90DegreesClockwise || constant == kRotate270DegreesClockwise)
            {
                dest.height = [firstObject pwidth];
                dest.width = [firstObject pheight];
            }
            
            src.rowBytes = src.width*4;
            dest.rowBytes = dest.width*4;
            src.data = volumeDataPtr;
            
            vImageRotate90_PlanarF ( &src, &dest, constant, 0, 0);
            
            memcpy( src.data, dest.data, [firstObject pheight] * [firstObject pwidth] * 4);
            
            volumeDataPtr += [firstObject pheight]*[firstObject pwidth];
        }
        
        free( dest.data);
    }
    
    for( y = 0 ; y < maxMovieIndex; y++)
    {
        for( x = 0; x < [pixList[ y] count]; x++)
        {
            double	o[ 9];
            DCMPix	*dcm = [pixList[ y] objectAtIndex: x];
            
            if( constant == kRotate90DegreesClockwise || constant == kRotate270DegreesClockwise)
            {
                float x = [dcm pixelSpacingX];
                float y = [dcm pixelSpacingY];
                
                [dcm setPixelSpacingX:  y];
                [dcm setPixelSpacingY:  x];
                
                [dcm setPixelRatio: x/y];
                
                // ***************************
                
                x = [dcm pwidth];
                y = [dcm pheight];
                
                [dcm setPheight: x];
                [dcm setPwidth: y];
                //				[dcm setRowBytes: y*sizeof(float)];
            }
            
            [dcm orientationDouble: o];
            
            // Compute normal vector
            o[6] = o[1]*o[5] - o[2]*o[4];
            o[7] = o[2]*o[3] - o[0]*o[5];
            o[8] = o[0]*o[4] - o[1]*o[3];
            
            XYZ vector, rotationVector;
            
            rotationVector.x = o[ 6];	rotationVector.y = o[ 7];	rotationVector.z = o[ 8];
            
            vector.x = o[ 0];	vector.y = o[ 1];	vector.z = o[ 2];
            vector =  ArbitraryRotate(vector, -rot*deg2rad, rotationVector);
            o[ 0] = vector.x;	o[ 1] = vector.y;	o[ 2] = vector.z;
            
            vector.x = o[ 3];	vector.y = o[ 4];	vector.z = o[ 5];
            vector =  ArbitraryRotate(vector, -rot*deg2rad, rotationVector);
            o[ 3] = vector.x;	o[ 4] = vector.y;	o[ 5] = vector.z;
            
            [dcm setOrientationDouble: o];
            [dcm setSliceInterval: 0];
            
            // Origin
            double		d[ 3];
            double		yy, xx;
            
            switch( constant)
            {
                case kRotate90DegreesClockwise:		yy = 0;						xx = -[dcm pwidth]+1;		break;
                case kRotate180DegreesClockwise:	yy = [dcm pheight]-1;		xx = -[dcm pwidth]+1;		break;
                case kRotate270DegreesClockwise:	yy = 0;						xx = [dcm pwidth]-1;		break;
            }
            
            double	originX, originY, originZ;
            
            originX = [dcm originX];
            originY = [dcm originY];
            originZ = [dcm originZ];
            
            [dcm orientationDouble: o];
            
            d[0] = originX + yy*o[3]*[dcm pixelSpacingY] + xx*o[0]*[dcm pixelSpacingX];
            d[1] = originY + yy*o[4]*[dcm pixelSpacingY] + xx*o[1]*[dcm pixelSpacingX];
            d[2] = originZ + yy*o[5]*[dcm pixelSpacingY] + xx*o[2]*[dcm pixelSpacingX];
            
            [dcm setOriginDouble: d];
            [dcm computeSliceLocation];
        }
    }
    
    [self setPostprocessed: YES];
    
    [self computeInterval];
    [self updateImage: self];
}

- (IBAction) squareDataSet:(id) sender
{
    int y;
    
    for( y = 0 ; y < maxMovieIndex; y++)
    {
        DCMPix	*curPix = [pixList[ y] objectAtIndex: 0];
        
        if( [curPix pixelSpacingX] != [curPix pixelSpacingY])
        {
            if( [curPix pixelSpacingX] < [curPix pixelSpacingY])
            {
                [self resampleDataWithXFactor:1.0 yFactor:[curPix pixelSpacingX] / [curPix pixelSpacingY] zFactor:1.0];
            }
            else
            {
                [self resampleDataWithXFactor:[curPix pixelSpacingY] / [curPix pixelSpacingX] yFactor:1.0 zFactor:1.0];
            }
            
            [self setPostprocessed: YES];
        }
    }
}

- (IBAction) setOrientationTool:(id) sender
{
    short newOrientationTool = [[sender selectedCell] tag];
    
    BOOL volumicData = [self isDataVolumicIn4D: NO];
    
    if( volumicData == NO)
    {
        NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool works only with 3D data series.", nil), nil, nil, nil);
        return;
    }
    
    BOOL executed = [self setOrientation:newOrientationTool];
    if( executed == NO)
        {
            // TODO check/create localizedStrings for first two strings
            if( NSRunCriticalAlertPanel(@"Error", @"Cannot execute this reslicing.\r\rPlease report this issue in Horos Project Issue Tracker.", NSLocalizedString(@"OK", nil), nil, nil) == NSAlertAlternateReturn)
                [[AppController sharedAppController] osirix64bit: self];
        }
}

- (BOOL) setOrientation: (int) newOrientationTool
{
    BOOL succeed = YES;
    
    if( newOrientationTool != currentOrientationTool)
    {
        float previousZooming = [imageView scaleValue] / [[pixList[ curMovieIndex] objectAtIndex: 0] pixelSpacingX];
        
        if( displayOnlyKeyImages)
        {
            [keyImagePopUpButton selectItemAtIndex: 0];
            [self keyImageDisplayButton: self];
        }
        
        [self checkEverythingLoaded];
        [self displayWarningIfGantryTitled];
        [self displayAWarningIfNonTrueVolumicData];
        
        int previousFusion = [popFusion selectedTag];
        int previousFusionActivated = [activatedFusion state];
        
        BOOL volumicData = [self isDataVolumicIn4D: NO];
        
        if( volumicData == NO)
        {
            NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool works only with 3D data series.", nil), nil, nil, nil);
            
            succeed = NO;
            
            return succeed;
        }
        
        //		if( [[pixList[ curMovieIndex] objectAtIndex: 0] isRGB])
        //		{
        //			NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool works only with B/W data series.", nil), nil, nil, nil);
        //			return;
        //		}
        
        // To stop any attempt to reload the data...
        postprocessed = YES;
        
        BOOL newViewer = NO;
        
        [imageView setDrawing: NO];
        
        [imageView stopROIEditingForce: YES];
        [self checkEverythingLoaded];
        
        if( blendingController)
            [self ActivateBlending: nil];
        
        
        NSLog( @"Orientation : current: %d new: %d", currentOrientationTool, newOrientationTool);
        
        switch( currentOrientationTool)
        {
            case 0:
            {
                switch( newOrientationTool)
                {
                    case 0:
                        [imageView setIndex: [pixList[curMovieIndex] count]/2];
                        [imageView sendSyncMessage:0];
                        [self adjustSlider];
                        break;
                        
                    case 1:
                        [self checkEverythingLoaded];
                        succeed = [self processReslice: 0 :newViewer];
                        break;
                        
                    case 2:
                        [self checkEverythingLoaded];
                        succeed = [self processReslice: 1 :newViewer];
                        break;
                }
            }
                break;
                
            case 1:	// coronal
            {
                switch( newOrientationTool)
                {
                    case 0:
                        [self checkEverythingLoaded];
                        succeed = [self processReslice: 0 :newViewer];
                        
                        if( succeed)
                            [self vertFlipDataSet: self];
                        break;
                        
                    case 1:
                        [imageView setIndex: [pixList[curMovieIndex] count]/2];
                        [imageView sendSyncMessage:0];
                        [self adjustSlider];
                        break;
                        
                    case 2:
                        [self checkEverythingLoaded];
                        succeed = [self processReslice: 1 :newViewer];
                        
                        if( succeed)
                            [self rotateDataSet: kRotate90DegreesClockwise];
                        break;
                }
            }
                break;
                
            case 2:	// sagi
            {
                switch( newOrientationTool)
                {
                    case 0:
                        [self checkEverythingLoaded];
                        succeed = [self processReslice: 0 :newViewer];
                        
                        if( succeed)
                        {
                            [self rotateDataSet: kRotate90DegreesClockwise];
                            [self horzFlipDataSet: self];
                        }
                        break;
                        
                    case 1:
                        [self checkEverythingLoaded];
                        succeed = [self processReslice: 1 :newViewer];
                        
                        if( succeed)
                        {
                            [self rotateDataSet: kRotate90DegreesClockwise];
                            [self horzFlipDataSet: self];
                        }
                        break;
                        
                    case 2:
                        [imageView setIndex: [pixList[curMovieIndex] count]/2];
                        [imageView sendSyncMessage:0];
                        [self adjustSlider];
                        break;
                }
            }
                break;
        }
        
        if( succeed == NO)
        {
            if( NSRunCriticalAlertPanel(NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"Cannot execute this reslicing.\r\rUpgrade to OsiriX 64-bit or OsiriX MD to solve this issue.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
                [[AppController sharedAppController] osirix64bit: self];
        }
        else
        {
            currentOrientationTool = newOrientationTool;
        }
        
        [self setPostprocessed: YES];
        
        if( newViewer == NO)
            [orientationMatrix selectCellWithTag: currentOrientationTool];
        
        float   iwl, iww;
        [imageView getWLWW:&iwl :&iww];
        [imageView setWLWW:iwl :iww];
        
        if( previousFusion != 0)
        {
            [self checkEverythingLoaded];
            [self computeInterval];
            if( previousFusionActivated == NSOnState)
                [self setFusionMode: previousFusion];
            [popFusion selectItemWithTag:previousFusion];
        }
        
        [imageView setScaleValue: previousZooming * [[pixList[ curMovieIndex] objectAtIndex: 0] pixelSpacingX]];
        [imageView scaleToFit];
        [imageView setDrawing: YES];
        
        [self propagateSettings];
        
        [self updateImage: self];
        
        [imageView sendSyncMessage:0];
        [self adjustSlider];
    }
    return succeed;
}

//- (void)setOrientationToolFrom2DMPR:(id)sender
//{
//	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing...", nil)];
//	[wait showWindow:self];
//	[orientationMatrix selectCellWithTag:[[sender selectedCell] tag]];
//	[self setOrientationTool:orientationMatrix];
//	[self checkEverythingLoaded];
//	[self performSelector:@selector(MPR2DViewer:) withObject:self afterDelay:0.05];
//	[wait close];
//	[wait autorelease];
//}

- (void)contextualDictionaryPath:(NSString *)newContextualDictionaryPath /* deprecated */ {
}

- (NSString *)contextualDictionaryPath /* deprecated */ {
    return @"default";
}

- (void) computeContextualMenu
{
    NSLog(@"2D Viewer Contextual Menu - Generate");
    NSMenu* menu = [[self contextualMenu] copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixPopulatedContextualMenuNotification object:menu
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                self, [ViewerController className], NULL]];
    [imageView setMenu:[menu autorelease]];
}

- (void)computeContextualMenuForROI:(ROI*)roi
{
    NSLog(@"2D Viewer Contextual Menu - Generate for ROI: %@", roi);
    NSMenu* menu = [[self contextualMenuForROI:roi] copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixPopulatedContextualMenuNotification object:menu
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                self, [ViewerController className],
                                                                roi, [ROI className], NULL]];
    [imageView setMenu:[menu autorelease]];
}

-(NSMenu*)contextualMenuForROI:(ROI*)roi
{
    NSMenu* menu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem* temp;
    
    temp = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"ROI: %@", [roi name]] action:NULL keyEquivalent:@""] autorelease];
    [menu addItem:temp];
    
    if( roi.locked == NO)
    {
        [menu addItem:[NSMenuItem separatorItem]];
        
        temp = [[[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(roiContextualMenuActionRemove:) keyEquivalent:@""] autorelease];
        [temp setRepresentedObject:roi];
        [temp setTarget:self];
        [menu addItem:temp];
    }
    
    return menu;
}

- (void)sendWillFreeVolumeDataNotificationWithVolumeData:(NSData *)freeingVolumeData movieIndex:(NSInteger)movieIndex
{
    if (freeingVolumeData) {
        NSAutoreleasePool *pool;
        pool = [[NSAutoreleasePool alloc] init];
        // this Autorelease pool is here to deal with some sort of race condition when freeing the ViewerController, if the viewercontroler
        // get's retain/autoreleased we get a crash in the main run loop. This is a hack...
        
        [[NSNotificationCenter defaultCenter] postNotification:
         [NSNotification notificationWithName:OsirixViewerControllerWillFreeVolumeDataNotification object:self
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:freeingVolumeData, @"volumeData", [NSNumber numberWithInteger:movieIndex], @"movieIndex", nil]]];
        
        [pool release];
    }
}

- (void)sendDidAllocateVolumeDataNotificationWithVolumeData:(NSData *)allocatingVolumeData movieIndex:(NSInteger)movieIndex
{
    if(allocatingVolumeData) {
        NSAutoreleasePool *pool;
        pool = [[NSAutoreleasePool alloc] init];
        // this Autorelease pool is here to deal with some sort of race condition when freeing the ViewerController, if the viewercontroler
        // get's retain/autoreleased we get a crash in the main run loop. This is a hack...
        
        [[NSNotificationCenter defaultCenter] postNotification:
         [NSNotification notificationWithName:OsirixViewerControllerDidAllocateVolumeDataNotification object:self
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:allocatingVolumeData, @"volumeData", [NSNumber numberWithInteger:movieIndex], @"movieIndex", nil]]];
        
        [pool release];
    }
}

-(void)roiContextualMenuActionRemove:(NSMenuItem*)source
{
    ROI* roi = [source representedObject];
    [roi retain];
    [[[roi curView] curRoiList] removeObject:roi];
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixRemoveROINotification object:roi];
    [roi release];
}

- (void) applyWindowProtocol:(id) sender
{
    [[AppController sharedAppController] closeAllViewers: self];
    
    DicomStudy *s = self.currentStudy;
    NSArray *imageSeries = s.imageSeries;
    
    [imageSeries setValue:nil forKey:@"rotationAngle"];
    [imageSeries setValue:nil forKey:@"scale"];
    [imageSeries setValue:nil forKey:@"windowLevel"];
    [imageSeries setValue:nil forKey:@"windowWidth"];
    [imageSeries setValue:nil forKey:@"xFlipped"];
    [imageSeries setValue:nil forKey:@"yFlipped"];
    [imageSeries setValue:nil forKey:@"xOffset"];
    [imageSeries setValue:nil forKey:@"yOffset"];
    [imageSeries setValue:nil forKey:@"displayStyle"];
    [s setValue:nil forKey:@"windowsState"];
    
    [[BrowserController currentBrowser] databaseOpenStudy: self.currentStudy withProtocol: [sender representedObject]];
}

- (NSMenu*) contextualMenu
{
    // if contextualMenuPath says @"default", recreate the default menu once and again
    // if contextualMenuPath contains a path, create the new contextual menu
    // if contextualMenuPath says @"custom", don't do anything
    
    [contextualMenu release];
    contextualMenu = nil;
    

    /******************* Tools menu ***************************/
    contextualMenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
    
    // ******************* series popup menu *********************
    
    [self buildSeriesPopup];
    [contextualMenu addItem: seriesPopupContextualMenu];
    [contextualMenu addItem: [NSMenuItem separatorItem]];
    
    
    //  *****
    
    NSMenu *submenu =  [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"ROI", nil)] autorelease];
    NSMenuItem *item;
    NSArray *titles = [NSArray arrayWithObjects:NSLocalizedString(@"Contrast", nil), NSLocalizedString(@"Move", nil), NSLocalizedString(@"Magnify", nil), NSLocalizedString(@"Rotate", nil), NSLocalizedString(@"Scroll", nil), nil];
    NSArray *images = [NSArray arrayWithObjects: @"WLWW", @"Move", @"Zoom",  @"Rotate",  @"Stack", @"Length", nil];	// DO NOT LOCALIZE THIS LINE ! -> filenames !
    NSEnumerator *enumerator2 = [images objectEnumerator];
    NSEnumerator *enumerator3 = [[popupRoi itemArray] objectEnumerator];
    NSString *title;
    NSString *image;
    
    NSMenuItem *subItem;
    int i = 0;
    
    [enumerator3 nextObject];	// First item is pop main menu
    while (subItem = [enumerator3 nextObject])
    {
        int tag = [subItem tag];
        if( tag)
        {
            item = [[[NSMenuItem alloc] initWithTitle: [subItem title] action: @selector(setROITool:) keyEquivalent:@""] autorelease];
            [item setTag:tag];
            
            [item setTarget:self];
            [[item image] setSize:ToolsMenuIconSize];
            [submenu addItem:item];
        }
        else [submenu addItem: [NSMenuItem separatorItem]];
    }
    
    for (title in titles)
    {
        image = [enumerator2 nextObject];
        item = [[[NSMenuItem alloc] initWithTitle: title action: @selector(setDefaultTool:) keyEquivalent:@""] autorelease];
        [item setTag:i++];
        [item setTarget:self];
        [item setImage:[NSImage imageNamed:image]];
        [[item image] setSize:ToolsMenuIconSize];
        [contextualMenu addItem:item];
    }
    
    image = [enumerator2 nextObject];
    item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"ROI", nil) action: nil keyEquivalent:@""] autorelease];
    [item setTag: -1];
    [item setTarget: self];
    
    
    if( [imageView currentTool] >= tMesure)
        [item setImage: [self imageForROI: [imageView currentTool]]];
    else
        [item setImage: [self imageForROI: tMesure]];
    
    [[item image] setSize:ToolsMenuIconSize];
    
    [contextualMenu addItem:item];
    [[contextualMenu itemAtIndex: contextualMenu.itemArray.count-1] setSubmenu:submenu];
    [contextualMenu addItem:[NSMenuItem separatorItem]];
    
    /******************* WW/WL menu items **********************/
    
    NSMenu *menu = [[[[AppController sharedAppController] wlwwMenu] copy] autorelease];
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Window Width & Level", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:menu];
    [contextualMenu addItem:item];
    
    [contextualMenu addItem:[NSMenuItem separatorItem]];
    
    /************* window resize Menu ****************/
    
    submenu =  [[[NSMenu alloc] initWithTitle:@"Resize window"] autorelease];
    
    NSArray *resizeWindowArray = [NSArray arrayWithObjects:@"25%", @"50%", @"100%", @"200%", @"300%", @"iPod Video", nil];
    i = 0;
    for (NSString *titleMenu in resizeWindowArray) {
        int tag = i++;
        item = [[[NSMenuItem alloc] initWithTitle:titleMenu action: @selector(resizeWindow:) keyEquivalent:@""] autorelease];
        [item setTag:tag];
        [item setTarget:imageView];
        [submenu addItem:item];
    }
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Resize window", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:submenu];
    [contextualMenu addItem:item];
    
    [contextualMenu addItem:[NSMenuItem separatorItem]];
    [contextualMenu addItemWithTitle:NSLocalizedString(@"No Rescale Size (100%)", nil) action: @selector(actualSize:) keyEquivalent:@""];
    [contextualMenu addItemWithTitle:NSLocalizedString(@"Actual size", nil) action: @selector(realSize:) keyEquivalent:@""];
    [contextualMenu addItemWithTitle:NSLocalizedString(@"Scale To Fit", nil) action: @selector(scaleToFit:) keyEquivalent:@""];
    [contextualMenu addItemWithTitle:NSLocalizedString(@"Mark as Key image", nil) action: @selector(setKeyImage:) keyEquivalent:@""];
    
    // Tiling
    menu = [[[[AppController sharedAppController] imageTilingMenu] copy] autorelease];
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Image Tiling", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:menu];
    [contextualMenu addItem:item];
    
    menu = [[[AppController sharedAppController].windowsTilingMenuRows copy] autorelease];
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Windows Tiling - Rows", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:menu];
    [contextualMenu addItem:item];
    
    menu = [[[AppController sharedAppController].windowsTilingMenuColumns copy] autorelease];
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Windows Tiling - Columns", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:menu];
    [contextualMenu addItem:item];
    
    /********** Protocol submenu ************/
    submenu =  [[[NSMenu alloc] initWithTitle: NSLocalizedString(@"Apply Window Protocol", nil)] autorelease];
    NSString *m = self.modality;
    for (NSDictionary *protocol in [WindowLayoutManager hangingProtocolsForModality:m]) {
        NSString *t = [NSString stringWithFormat: @"%@ - %@", m, [protocol objectForKey: @"Study Description"]];
        
        item = [[[NSMenuItem alloc] initWithTitle: t action: @selector( applyWindowProtocol:) keyEquivalent:@""] autorelease];
        [item setTarget: self];
        [item setRepresentedObject: protocol];
        [submenu addItem:item];
    }
    
    item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Apply Window Protocol", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:submenu];
    [contextualMenu addItem:item];
    
    /********** Orientation submenu ************/
    
    menu = [[[[AppController sharedAppController] orientationMenu] copy] autorelease];
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Orientation", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:menu];
    [contextualMenu addItem:item];
    
    /*************Export submenu**************/
    menu = [[[[AppController sharedAppController] exportMenu] copy] autorelease];
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", nil) action: nil keyEquivalent:@""] autorelease];
    [item setSubmenu:menu];
    [contextualMenu addItem:item];
    
    /*************Workspace submenu**************/
    if ([[AppController sharedAppController] workspaceMenu]) {
        [contextualMenu addItem: [NSMenuItem separatorItem]];
        [contextualMenu addItemWithTitle: NSLocalizedString(@"Save Workspace State", nil) action: @selector(saveWindowsState:) keyEquivalent:@""];
        [contextualMenu addItemWithTitle: NSLocalizedString(@"Save Workspace State as DICOM SR", nil) action: @selector(saveWindowsStateAsDICOMSR:) keyEquivalent:@""];
        NSMenuItem *mi = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Load Workspace State DICOM SR", nil) action: nil keyEquivalent:@""] autorelease];
        [mi setSubmenu: [[[[AppController sharedAppController] workspaceMenu] copy] autorelease]];
        [contextualMenu addItem: mi];
    }
    
    return contextualMenu;
}

- (void) setWindowTitle:(id) sender
{
    if( windowWillClose) return;
    
    NSString *loading = @"         ";
    
    @synchronized( loadingThread)
    {
        if( loadingThread.isExecuting)
        {
            if( [[loadingThread.threadDictionary objectForKey: @"loadingPercentage"] floatValue] != 1)
            {
                loading = [NSString stringWithFormat:NSLocalizedString(@" - %2.f%%", nil), [[loadingThread.threadDictionary objectForKey: @"loadingPercentage"] floatValue] * 100.];
                [NSTimer cancelPreviousPerformRequestsWithTarget:self selector:@selector(setWindowTitle:) object:nil];
                [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(setWindowTitle:) userInfo:nil repeats:NO];
            }
        }
    }
    
    if( [fileList[ curMovieIndex] count])
    {
        NSManagedObject	*curImage = [fileList[ curMovieIndex] objectAtIndex:0];
        
        if( [[[curImage valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"])
            [[self window] setTitle: NSLocalizedString( @"No images", nil)];
        else
        {
            NSDate	*bod = [curImage valueForKeyPath:@"series.study.dateOfBirth"];
            NSString *windowTitle;
            NSString *seriesName = [curImage valueForKeyPath:@"series.name"];
            
            if( seriesName == nil)
                seriesName = @"";
            
            if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotFull)
            {
                if( [curImage valueForKeyPath:@"series.study.dateOfBirth"])
                    windowTitle = [NSString stringWithFormat: @"%@ - %@ (%@) - %@", [curImage valueForKeyPath:@"series.study.name"], [[NSUserDefaults dateFormatter] stringFromDate:bod], [curImage valueForKeyPath:@"series.study.yearOld"], seriesName];
                else
                    windowTitle = [NSString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath:@"series.study.name"], seriesName];
            }
            else windowTitle = [NSString stringWithFormat: @"%@", seriesName];
            
            if( [[[curImage valueForKeyPath:@"series.id"] stringValue] length])
                windowTitle = [windowTitle stringByAppendingFormat: @" (%@)", [[curImage valueForKeyPath:@"series.id"] stringValue]];
            
            DCMPix *p = [pixList[ curMovieIndex] objectAtIndex:0];
            
            if( p.generated && p.generatedName.length)
                windowTitle = [windowTitle stringByAppendingString: [NSString stringWithFormat: @" - %@", p.generatedName]];
            
            if( [[imageView curDCM] SUVConverted])
                windowTitle = [windowTitle stringByAppendingString: NSLocalizedString( @" (SUV Converted)", nil)];
            
            windowTitle = [windowTitle stringByAppendingString: loading];
            
            [[self window] setTitle: windowTitle];
            
            @synchronized( loadingThread)
            {
                if( loadingThread.isExecuting == NO || [[loadingThread.threadDictionary objectForKey: @"loadingPercentage"] floatValue] >= 1)
                    if( [[imageView curDCM] srcFile] && [[NSFileManager defaultManager] fileExistsAtPath: [[imageView curDCM] srcFile]])
                        [[self window] setRepresentedFilename: [[imageView curDCM] srcFile]];
            }
        }
    }
    else [[self window] setTitle: @"Viewer"];
    
    [imageView checkCursor];	// <- To avoid a stupid bug between setTitle and NSTrackingArea.....
}

- (id) startWaitProgressWindow :(NSString*) message :(long) max
{
    Wait *splash = [[Wait alloc] initWithString:message];
    [splash showWindow:self];
    [[splash progress] setMaxValue:max];
    
    return splash;
}

- (void) waitIncrementBy:(id) waitWindow :(long) val
{
    [waitWindow incrementBy:val];
}

- (id) startWaitWindow :(NSString*) message
{
    WaitRendering *splash = [[WaitRendering alloc] init:message];
    [splash showWindow:self];
    
    return splash;
}

- (void) endWaitWindow:(id) waitWindow
{
    [waitWindow close];
    [waitWindow autorelease];
}

-(IBAction) updateImage:(id) sender
{
    for( DCMView *v in [seriesView imageViews])
    {
        [v updateImage];
    }
}

-(void) needsDisplayUpdate
{
    [self updateImage:self];
    
    float   iwl, iww;
    [imageView getWLWW:&iwl :&iww];
    [imageView setWLWW:iwl :iww];
    
    for( int y = 0; y < maxMovieIndex; y++)
    {
        for( int x = 0; x < [pixList[y] count]; x++)
            [[pixList[y] objectAtIndex: x] changeWLWW:iwl :iww];
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self checkView: subCtrlView :NO];
    
    [[self window] setInitialFirstResponder: imageView];
    
    
//	keyObjectPopupController = [[KeyObjectPopupController alloc]initWithViewerController:self popup:keyImagePopUpButton];
    [keyImagePopUpButton selectItemAtIndex: displayOnlyKeyImages];
    
    seriesView = [[[studyView seriesViews] objectAtIndex:0] retain];
    imageView = [[[seriesView imageViews] objectAtIndex:0] retain];
}

+ (ViewerController *) newWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v frame: (NSRect) frame
{
    ViewerController *win = [[ViewerController alloc] initWithPix:f withFiles:d withVolume:v];
    
    [win showWindowTransition];
    [win startLoadImageThread]; // Start async reading of all images
    
    if( NSIsEmptyRect( frame) == NO)
        [[win window] setFrame: frame display: NO];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
        [[AppController sharedAppController] tileWindows: nil];
    else
        [[AppController sharedAppController] checkAllWindowsAreVisible: nil makeKey: YES];
    
    return win;
}

+ (ViewerController *) newWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
    return [ViewerController newWindow:f :d : v frame: NSMakeRect(0, 0, 0, 0)];
}

- (ViewerController *) newWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
    return [ViewerController newWindow:f :d :v];
}

- (void) tileWindows
{
    [[AppController sharedAppController] tileWindows: nil];
}

- (IBAction) SetWindowsTiling:(NSPopUpButton*) menu
{
    int tag = [menu selectedTag];
    int rows = tag / 10;
    int columns = tag % 10;
    
    columns *= [[[AppController sharedAppController] viewerScreens] count];
    
    int displayedViewersCount = [ViewerController getDisplayed2DViewers].count;
    
    BOOL copyAutoTilingPreference = [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"];
    
    [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"AUTOTILING"];
    
    if( displayedViewersCount > rows*columns)
    {
        while( [ViewerController getDisplayed2DViewers].count > rows*columns)
        {
            if( [[ViewerController getDisplayed2DViewers] lastObject] != self)
                [[[[ViewerController getDisplayed2DViewers] lastObject] window] close];
            
            else if( [[ViewerController getDisplayed2DViewers] objectAtIndex: 0] != self)
                [[[[ViewerController getDisplayed2DViewers] objectAtIndex: 0] window] close];
        }
    }
    
    if( displayedViewersCount < rows*columns)
    {
        [[BrowserController currentBrowser] displayWaitWindowIfNecessary];
        
        NSMutableArray *seriesArray = [[[self.currentStudy imageSeriesContainingPixels: YES] mutableCopy] autorelease];
        NSUInteger index = [seriesArray indexOfObject: [imageView seriesObj]];
        
        if( index == NSNotFound)
            index = 0;
        
        // Remove series already displayed
        for( ViewerController *v in [ViewerController get2DViewers])
        {
            NSUInteger seriesIndex = [[seriesArray valueForKey: @"objectID"] indexOfObject: v.currentSeries.objectID];
            if( seriesIndex != NSNotFound)
                [seriesArray removeObjectAtIndex: seriesIndex];
        }
        for( int i = displayedViewersCount ; i < rows*columns; i++)
        {
            ViewerController *newViewer = nil;
            if( seriesArray.count > 0)
            {
                index++;
                if( index >= seriesArray.count)
                    index = 0;
                
                newViewer = [[BrowserController currentBrowser] loadSeries: [seriesArray objectAtIndex: index] :nil :YES keyImagesOnly: NO];
                
                [seriesArray removeObjectAtIndex: index];
            }
            else
                newViewer = [[BrowserController currentBrowser] loadSeries: [imageView seriesObj] :nil :YES keyImagesOnly: NO]; //Duplicate existing
            
            [newViewer showCurrentThumbnail: self];
        }
        
        [[BrowserController currentBrowser] closeWaitWindowIfNecessary];
        
        for( int i = 0; i < [[NSScreen screens] count]; i++) [thumbnailsListPanel[ i] setThumbnailsView: nil viewer:nil];
        [[self window] makeKeyAndOrderFront: self];
        [self refreshToolbar];
        [self updateNavigator];
    }
    
    if( delayedTileWindows)
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
    delayedTileWindows = YES;
    
    [[AppController sharedAppController] performSelector: @selector(tileWindows:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: rows], @"rows", [NSNumber numberWithInt: columns], @"columns", nil] afterDelay: 0.1];
    
    [[NSUserDefaults standardUserDefaults] setBool: copyAutoTilingPreference forKey: @"AUTOTILING"];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    NSRect currentFrame = [sender frame];
    NSRect screenRect = [AppController usefullRectForScreen: [sender screen]];
    
    if( NSIsEmptyRect( standardRect)) standardRect = currentFrame;
    
    if (currentFrame.size.height >= screenRect.size.height - 20 && currentFrame.size.width >= screenRect.size.width - 20)
        return standardRect;
    else
        return screenRect;
}

- (void)setWindowFrame:(NSRect)rect showWindow:(BOOL) showWindow animate: (BOOL) animate
{
    NSRect	curRect = [[self window] frame];
    BOOL wasAlreadyVisible = [[self window] isVisible];
    
    //To avoid the use of WindowDidMove function - Magnetic windows
    [OSIWindowController setDontEnterMagneticFunctions: YES];
    
    rect.origin.x =  roundf( rect.origin.x);
    rect.origin.y =  roundf(rect.origin.y);
    rect.size.width =  roundf(rect.size.width);
    rect.size.height =  roundf(rect.size.height);
    
    [self setStandardRect:rect];
    
    BOOL rectIdentical = YES;
    
    float maxdiff = 0, d;
    
    d = fabs( curRect.origin.y - rect.origin.y);	if( d > maxdiff) maxdiff = d;
    d = fabs( curRect.origin.x - rect.origin.x);	if( d > maxdiff) maxdiff = d;
    d = fabs( curRect.size.height - rect.size.height);	if( d > maxdiff) maxdiff = d;
    d = fabs( curRect.size.width - rect.size.width);	if( d > maxdiff) maxdiff = d;
    
    if( fabs( curRect.origin.y - rect.origin.y) >= 1.0) rectIdentical = NO;
    if( fabs( curRect.origin.x - rect.origin.x) >= 1.0) rectIdentical = NO;
    if( fabs( curRect.size.height - rect.size.height) >= 1.0) rectIdentical = NO;
    if( fabs( curRect.size.width - rect.size.width) >= 1.0) rectIdentical = NO;
    
    if( maxdiff < 5) animate = NO;
    
    if( rectIdentical == NO)
    {
        
        if( showWindow == YES && wasAlreadyVisible == YES)
            [[self window] orderFront:self];
        
        if( animate == YES && wasAlreadyVisible == YES)
        {
            [AppController resizeWindowWithAnimation: [self window] newSize: rect];
        }
        else [[self window] setFrame: rect display:NO];
        
        if( showWindow == YES && wasAlreadyVisible == NO)
            [[self window] orderFront:self];
        
        //		if( showWindow && [[NSUserDefaults standardUserDefaults] boolForKey: @"AlwaysScaleToFit"] == NO)
        //		{
        //			if( wasAlreadyVisible)
        //				[imageView setScaleValue: scaleValue * [imageView frame].size.width / previousHeight];
        //		}
    }
    else
    {
        if( NSEqualRects( curRect, rect) == NO)
            [[self window] setFrame: rect display:NO];
        
        if( showWindow) [[self window] orderFront:self];
    }
    
    [OSIWindowController setDontEnterMagneticFunctions: NO];
}

- (void)setWindowFrame:(NSRect)rect showWindow:(BOOL) showWindow
{
    [self setWindowFrame: rect showWindow: showWindow animate: NO];
}

- (void)setWindowFrame:(NSRect)rect
{
    [self setWindowFrame: rect showWindow: YES];
}


-(BOOL) windowWillClose
{
    return windowWillClose;
}

- (BOOL)windowShouldClose:(id)sender
{
    if( [toolbar customizationPaletteIsRunning])
        return NO;
    
    if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask)
        return NO;
    
    if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget: [AppController sharedAppController] selector:@selector(closeAllViewers:) object:nil];
        [[AppController sharedAppController] performSelector: @selector(closeAllViewers:) withObject:nil afterDelay: 0.1];
        
        return NO;
    }
    
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [ViewerController clearFrontMost2DViewerCache];
    
#ifndef OSIRIX_LIGHT
    [[OSIEnvironment sharedEnvironment] removeViewerController:self];
#endif
    
    [self.window makeFirstResponder: nil];
    
    [previewMatrixScrollView setPostsBoundsChangedNotifications: NO];
    [[[splitView subviews] objectAtIndex: 0] setPostsFrameChangedNotifications: NO];
    
    @synchronized( loadingThread) {
        [loadingThread cancel];
    }
    
    requestLoadingCancel = YES;
    if (blendingController)
        self.blendingController->requestLoadingCancel = YES;
    
    BOOL isExecuting = NO;
    do {
        @synchronized( loadingThread) {
            isExecuting = loadingThread.isExecuting;
        }
        if( isExecuting)
            [NSThread sleepForTimeInterval: 0.01];
    } while (isExecuting);
    
    @synchronized( loadingThread)
    {
        [loadingThread autorelease];
        loadingThread = nil;
    }
    
    [[self window] setAcceptsMouseMovedEvents: NO];
    
    [imageView stopROIEditingForce: YES];
    
    // **************************
    
    if( FullScreenOn == YES) [self fullScreenMenu: self];
    
    if( [subCtrlOnOff state]) [imageView setWLWW: 0 :0];
    
    [imageView setDrawing: NO];
    
    windowWillClose = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    
    [highLightedTimer invalidate];
    [highLightedTimer release];
    highLightedTimer = nil;
    
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
    }
    
    if( timer)
    {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
    
    //	if( timeriChat)
    //    {
    //        [timeriChat invalidate];
    //        [timeriChat release];
    //        timeriChat = nil;
    //    }
    
    if(t12BitTimer)
    {
        [t12BitTimer invalidate];
        [t12BitTimer release];
        t12BitTimer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixCloseViewerNotification object: self userInfo: nil];
    
    if( SYNCSERIES)
    {
        NSArray		*winList = [NSApp windows];
        long		win = 0;
        
        for( id loopItem in winList)
        {
            if( [[loopItem windowController] isKindOfClass:[ViewerController class]])
            {
                if( self != [loopItem windowController]) win++;
            }
        }
        
        if( win <= 1)
        {
            [self SyncSeries: self];
        }
    }
    
    [toolbarPanel close];
    [toolbarPanel release];
    toolbarPanel = nil;
    
    
    [self finalizeSeriesViewing];
    
    
    [self autorelease];
    
    
    numberOf2DViewer--;
    @synchronized( arrayOf2DViewers)
    {
        [arrayOf2DViewers removeObject: self];
    }
    
    if( numberOf2DViewer == 0)
    {
        [AppController setUSETOOLBARPANEL: NO];
        
        for( int i = 0; i < [[NSScreen screens] count]; i++)
            [[thumbnailsListPanel[ i] window] orderOut:self];
        
        [[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality: nil description: nil];
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
    {
        if( delayedTileWindows)
            [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
        delayedTileWindows = YES;
        [[AppController sharedAppController] performSelector: @selector(tileWindows:) withObject:nil afterDelay: 0.3];
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
    {
        [previewMatrix renewRows:0 columns:0];
        
        for( int i = 0 ; i < [[NSScreen screens] count]; i++)
            [thumbnailsListPanel[ i] thumbnailsListWillClose: previewMatrixScrollView];
    }
    
    [[NSCursor arrowCursor] set];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
    {
        [NSApp sendAction: @selector(tileWindows:) to:nil from: self];
    }
    
    if( [AppController USETOOLBARPANEL])
        [[toolbarPanel window] orderOut: self];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
    {
        for( int i = 0; i < [[NSScreen screens] count]; i++)
        {
            if( [thumbnailsListPanel[ i] thumbnailsView] == previewMatrixScrollView)
                [[thumbnailsListPanel[ i] window] orderOut:self];
        }
    }
}

- (void)windowDidDeminiaturize:(NSNotification *)notification
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
    {
        [NSApp sendAction: @selector(tileWindows:) to:nil from: self];
    }
    
    if( [AppController USETOOLBARPANEL])
        [[toolbarPanel window] orderFront: self];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
    {
        for( int i = 0; i < [[NSScreen screens] count]; i++)
        {
            if( [thumbnailsListPanel[ i] thumbnailsView] == previewMatrixScrollView)
                [[thumbnailsListPanel[ i] window] orderOut:self];
        }
    }
}

- (void) windowDidResignMain:(NSNotification *)aNotification
{
    [ViewerController clearFrontMost2DViewerCache];
    
    [imageView stopROIEditingForce: YES];
    
    [imageView sendSyncMessage: 0];
    
    [self autoHideMatrix];
    
    if( [AppController USETOOLBARPANEL])
        [toolbarPanel.window orderOut: self];
    
    [imageView setNeedsDisplay: YES];
}

//-(void) windowDidResignKey:(NSNotification *)aNotification
//{
//    [ViewerController clearFrontMost2DViewerCache];
//
//	[imageView stopROIEditingForce: YES];
//
//    [self autoHideMatrix];
//
////	if( FullScreenOn == YES)
////        [self fullScreenMenu: self];
//
//    if( [AppController USETOOLBARPANEL])
//        [toolbarPanel.window orderOut: self];
//
//    [imageView setNeedsDisplay: YES];
//}

- (void)windowDidChangeScreen:(NSNotification *)aNotification
{
    [cachedFrontMostDisplayed2DViewerForScreen removeAllObjects];
    
    if( windowWillClose)
        return;
    
    if( [OSIWindowController dontWindowDidChangeScreen])
        return;
    
    [ToolbarPanelController checkForValidToolbar];
    
    [self redrawToolbar];
}

- (void) redrawToolbar
{
    NSDisableScreenUpdates();
    
    if( [AppController USETOOLBARPANEL])
    {
        if( [ViewerController isFrontMost2DViewer: self.window])
        {
            if( [toolbarPanel.window.toolbar customizationPaletteIsRunning] == NO)
                [toolbarPanel.window orderBack: self];
        }
        else
            [toolbarPanel.window orderOut: self];
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
    {
        for( int i = 0; i < [[NSScreen screens] count]; i++)
        {
            if( [thumbnailsListPanel[ i] thumbnailsView] == previewMatrixScrollView && [[self window] screen] != [[NSScreen screens] objectAtIndex: i])
                [thumbnailsListPanel[ i] setThumbnailsView: nil viewer:nil];
        }
        
        BOOL found = NO;
        for( int i = 0; i < [[NSScreen screens] count]; i++)
        {
            if( [[self window] screen] == [[NSScreen screens] objectAtIndex: i])
            {
                [thumbnailsListPanel[ i] setThumbnailsView: previewMatrixScrollView viewer: self];
                found = YES;
            }
            else
                [[thumbnailsListPanel[ i] window] orderOut:self];
        }
        if( found == NO)
            N2LogStackTrace( @"Toolbar NOT found");
    }
    
    if( [AppController USETOOLBARPANEL] == NO)
        [[toolbarPanel window] orderOut:self];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO || [[NSUserDefaults standardUserDefaults] boolForKey: @"SeriesListVisible"] == NO)
    {
        for( int i = 0; i < [[NSScreen screens] count]; i++)
            [[thumbnailsListPanel[ i] window] orderOut:self];
    }
    
    NSEnableScreenUpdates();
}

- (void) refreshToolbar
{
    [self autoHideMatrix];
    
    [self redrawToolbar];
    
    if( [[self window] isVisible])
    {
        @try
        {
            if( fileList[ curMovieIndex] && [[[[fileList[ curMovieIndex] objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"] == NO)
            {
                if( [imageView curImage] >= 0)
                    [[BrowserController currentBrowser] findAndSelectFile: nil image:[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] shouldExpand:NO];
            }
        }
        @catch (NSException *e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
        }
    }
    
    [self SetSyncButtonBehavior: self];
    //	[self refreshMenus];
}

- (void) windowDidBecomeMain:(NSNotification *)aNotification
{
    [ViewerController clearFrontMost2DViewerCache];
    
    if( recursiveCloseWindowsProtected) return;
    
    NSDisableScreenUpdates();
    
    [self refreshToolbar];
    [self updateNavigator];
    [imageView setNeedsDisplay: YES];
    
    NSEnableScreenUpdates();
}

//- (void) windowDidBecomeKey:(NSNotification *)aNotification
//{
//    [ViewerController clearFrontMost2DViewerCache];
//
//	if( recursiveCloseWindowsProtected) return;
//
//    NSDisableScreenUpdates();
//
//	[self refreshToolbar];
//	[self updateNavigator];
//    [imageView setNeedsDisplay: YES];
//
//    NSEnableScreenUpdates();
//}

- (BOOL) is2DViewer
{
    return YES;
}

+ (void)closeAllWindows
{
    if( [NSThread isMainThread] == NO)
    {
        N2LogStackTrace( @"ViewerController closeAllWindows NOT on mainThread");
        return;
    }
    
    if( recursiveCloseWindowsProtected) return;
    recursiveCloseWindowsProtected = YES;
    
    if( delayedTileWindows)
    {
        delayedTileWindows = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
    }
    
    NSArray *v = [ViewerController getDisplayed2DViewers];
    
    if( [v count])
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceSave"])
        {
            [ViewerController saveWindowsState];
        }
        
        for (ViewerController* viewer in v)
        {
            if( [viewer FullScreenON])
                [viewer fullScreenMenu: self];
            
            [[viewer window] orderOut: self];
        }
        
        for (ViewerController*  viewer in v)
        {
            if( [viewer windowWillClose] == NO)
            {
                [[viewer window] close];	//performClose: self
            }
        }
    }
    
    if( delayedTileWindows)
    {
        delayedTileWindows = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
    }
    
    recursiveCloseWindowsProtected = NO;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DontResetListPODComparativesIn2DViewer"] == NO)
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"listPODComparativesIn2DViewer"];
    
    [[BrowserController currentBrowser] selectDatabaseOutline];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    [ViewerController clearFrontMost2DViewerCache];
    
    if( FullScreenOn == YES) [self fullScreenMenu: self];
}

-(IBAction) fullScreenMenu:(id) sender
{
    //	float scaleValue = [imageView scaleValue];
    
    NSDisableScreenUpdates();
    
    [self setUpdateTilingViewsValue: YES];
    [self selectFirstTilingView];
    
    if( FullScreenOn == YES) // we need to go back to non-full screen
    {
        [StartingWindow setContentView: contentView];
        
        [FullScreenWindow setDelegate:nil];
        [FullScreenWindow close];
        [FullScreenWindow release];
        FullScreenWindow = nil;
        
        FullScreenOn = NO;
        
        [StartingWindow setFrame: previousFrameRect display: YES];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"NoImageTilingInFullscreen"] && (previousFullscreenColumns != 1 || previousFullscreenRows != 1))
        {
            [imageView setIndex: previousFullscreenCurImage];
            [self setImageRows: previousFullscreenRows columns: previousFullscreenColumns];
            [[self window] makeFirstResponder: [[seriesView imageViews] objectAtIndex: previousFullscreenViewIndex]];
        }
        
        if( previousScaledFit)
            [imageView performSelector: @selector( scaleToFit) withObject: nil afterDelay: 0.01];
        
        [[NSUserDefaults standardUserDefaults] setBool:previousPropagate forKey: @"COPYSETTINGS"];
        
        [previewMatrix sizeToCells];
        
        [self redrawToolbar];
    }
    else // FullScreenOn == false
    {
        unsigned int windowStyle;
        NSRect contentRect;
        
        previousPropagate = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYSETTINGS"];
        
        if( self.blendingController == nil)
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"COPYSETTINGS"];
        
        previousFullscreenColumns = [imageView columns];
        previousFullscreenRows = [imageView rows];
        int selectedIndex = [imageView curImage];
        previousFullscreenViewIndex = [[seriesView imageViews] indexOfObject: imageView];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"NoImageTilingInFullscreen"] && (previousFullscreenColumns != 1 || previousFullscreenRows != 1))
            [self setImageRows: 1 columns: 1];
        
        previousFullscreenCurImage = [imageView curImage];
        
        [imageView setIndex: selectedIndex];
        
        StartingWindow = [self window];
        windowStyle = NSBorderlessWindowMask;
        contentRect = [self.window.screen frame];
        
        previousScaledFit = imageView.isScaledFit;
        previousFrameRect = StartingWindow.frame;
        [StartingWindow setFrame: contentRect display: NO];
        
        FullScreenWindow = [[NSFullScreenWindow alloc] initWithContentRect:contentRect styleMask: windowStyle backing:NSBackingStoreBuffered defer: NO];
        if(FullScreenWindow != nil)
        {
            [FullScreenWindow setTitle: @"myWindow"];
            [FullScreenWindow setReleasedWhenClosed: NO];
            [FullScreenWindow setLevel: NSScreenSaverWindowLevel - 1];
            [FullScreenWindow setBackgroundColor:[NSColor blackColor]];
            
            contentView = [[self window] contentView];
            [FullScreenWindow setContentView: contentView];
            
            [FullScreenWindow setDelegate:self];
            [FullScreenWindow setWindowController: self];
            
            //          [splitView adjustSubviews];
            //			frame.size.width = previous;
            //			[[[splitView subviews] objectAtIndex: 0] setFrameSize: frame.size];
            
            [FullScreenWindow makeKeyAndOrderFront: self];
            [FullScreenWindow makeFirstResponder: imageView];
            [FullScreenWindow setAcceptsMouseMovedEvents: YES];
            
            if( previousScaledFit)
                [imageView scaleToFit];
            
            FullScreenOn = YES;
        }
        
        [previewMatrix sizeToCells];
    }
    
    [self setUpdateTilingViewsValue : NO];
    
    //	[self selectFirstTilingView];
    //	[imageView setScaleValue: scaleValue];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AlwaysScaleToFit"])
        [imageView scaleToFit];
    
    [imageView display];
    
    NSEnableScreenUpdates();
}

- (BOOL) FullScreenON { return FullScreenOn;}

-(void) offFullScreen
{
    if( FullScreenOn == YES) [self fullScreenMenu:self];
}


-(void) UpdateConvolutionMenu: (NSNotification*) note
{
    if( windowWillClose)
        return;
    
    if( convolutionPresetsMenu == nil || [note userInfo] != nil)
    {
        //*** Build the menu
        short       i;
        NSArray     *keys;
        NSArray     *sortedKeys;
        
        keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] allKeys];
        sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        // Popup Menu
        
        [convolutionPresetsMenu release];
        convolutionPresetsMenu = [[NSMenu alloc] init];
        
        [convolutionPresetsMenu addItemWithTitle:NSLocalizedString(@"No Filter", nil) action:nil keyEquivalent:@""];
        [convolutionPresetsMenu addItemWithTitle:NSLocalizedString(@"No Filter", nil) action:@selector (ApplyConv:) keyEquivalent:@""];
        [convolutionPresetsMenu addItem: [NSMenuItem separatorItem]];
        
        for( i = 0; i < [sortedKeys count]; i++)
        {
            [convolutionPresetsMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyConv:) keyEquivalent:@""];
        }
        [convolutionPresetsMenu addItem: [NSMenuItem separatorItem]];
        [convolutionPresetsMenu addItemWithTitle:NSLocalizedString(@"Add a Filter", nil) action:@selector (AddConv:) keyEquivalent:@""];
        [convPopup setMenu: [[convolutionPresetsMenu copy] autorelease]];
        convPopupSet = YES;
    }
    else if( convPopupSet == NO)
    {
        [convPopup setMenu: [[convolutionPresetsMenu copy] autorelease]];
        convPopupSet = YES;
    }
    
    [convPopup setTitle: curConvMenu];
}

-(void) UpdateWLWWMenu: (NSNotification*) note
{
    if( windowWillClose)
        return;
    
    if( wlwwPresetsMenu == nil || [note userInfo] != nil)
    {
        //*** Build the menu
        NSArray     *keys;
        NSArray     *sortedKeys;
        
        // Presets VIEWER Menu
        
        keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] allKeys];
        sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        [wlwwPresetsMenu release];
        wlwwPresetsMenu = [[NSMenu alloc] init];
        
        [wlwwPresetsMenu addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:nil keyEquivalent:@""];
        [wlwwPresetsMenu addItemWithTitle: NSLocalizedString(@"Other", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
        [wlwwPresetsMenu addItemWithTitle: NSLocalizedString(@"Default WL & WW", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
        [wlwwPresetsMenu addItemWithTitle: NSLocalizedString(@"Full dynamic", nil) action:@selector (ApplyWLWW:) keyEquivalent:@""];
        [wlwwPresetsMenu addItem: [NSMenuItem separatorItem]];
        
        for( int i = 0; i < [sortedKeys count]; i++)
        {
            [wlwwPresetsMenu addItemWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector (ApplyWLWW:) keyEquivalent:@""];
        }
        [wlwwPresetsMenu addItem: [NSMenuItem separatorItem]];
        [wlwwPresetsMenu addItemWithTitle: NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
        [wlwwPresetsMenu addItemWithTitle: NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector (SetWLWW:) keyEquivalent:@""];
        
        [wlwwPopup setMenu: [[wlwwPresetsMenu copy] autorelease]];
        
        [contextualMenu release];
        contextualMenu = nil;
        [imageView setMenu: nil];	// Will force recomputing, when needed
        wlwwPopupSet = YES;
    }
    else if( wlwwPopupSet == NO)
    {
        [wlwwPopup setMenu: [[wlwwPresetsMenu copy] autorelease]];
        wlwwPopupSet = YES;
    }
    [wlwwPopup setTitle: curWLWWMenu];
}

- (void) AddCurrentWLWW:(id) sender
{
    float cwl, cww;
    
    [imageView getWLWW:&cwl :&cww];
    
    [wl setStringValue:[NSString stringWithFormat:@"%0.f", cwl ]];
    [ww setStringValue:[NSString stringWithFormat:@"%0.f", cww ]];
    
    [newName setStringValue: NSLocalizedString(@"Unnamed", nil)];
    
    [NSApp beginSheet: addWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(IBAction) endNameWLWW:(id) sender
{
    float iwl, iww;
    NSLog(@"endNameWLWW");
    
    iwl = [wl intValue];
    iww = [ww intValue];
    if( iww == 0) iww = 1;
    
    [addWLWWWindow orderOut:sender];
    
    [NSApp endSheet:addWLWWWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
        NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] mutableCopy] autorelease];
        [presetsDict setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:[newName stringValue]];
        [[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey:@"WLWW3"];
        
        if( curWLWWMenu != [newName stringValue])
        {
            [curWLWWMenu release];
            curWLWWMenu = [[newName stringValue] retain];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: [NSDictionary dictionary]];
        
        [imageView setWLWW: iwl: iww];
    }
}

- (void) renderButton:(id) sender
{
    NSLog( @"render Button");
}

-(void) UpdateOpacityMenu: (NSNotification*) note
{
    if( windowWillClose)
        return;
    
    if( opacityPresetsMenu == nil || [note userInfo] != nil)
    {
        //*** Build the menu
        short       i;
        NSArray     *keys;
        NSArray     *sortedKeys;
        
        // Presets VIEWER Menu
        
        keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] allKeys];
        sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        [opacityPresetsMenu release];
        opacityPresetsMenu = [[NSMenu alloc] init];
        
        [opacityPresetsMenu addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
        [opacityPresetsMenu addItemWithTitle:NSLocalizedString(@"Linear Table", nil) action:@selector (ApplyOpacity:) keyEquivalent:@""];
        for( i = 0; i < [sortedKeys count]; i++)
        {
            [opacityPresetsMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyOpacity:) keyEquivalent:@""];
        }
        [opacityPresetsMenu addItem: [NSMenuItem separatorItem]];
        [opacityPresetsMenu addItemWithTitle:NSLocalizedString(@"Add an Opacity Table", nil) action:@selector (AddOpacity:) keyEquivalent:@""];
        
        [OpacityPopup setMenu: [[opacityPresetsMenu copy] autorelease]];
        OpacityPopupSet = YES;
    }
    else if( OpacityPopupSet == NO)
    {
        [OpacityPopup setMenu: [[opacityPresetsMenu copy] autorelease]];
        OpacityPopupSet = YES;
    }
    
    [OpacityPopup setTitle: curOpacityMenu];
}

- (DCMView*) imageView
{
    return imageView;
}

- (NSArray*) imageViews
{
    return [seriesView imageViews];
}

-(NSString*) modality
{
    if( [imageView curImage] < fileList[ curMovieIndex].count)
        return [[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] valueForKeyPath:@"series.modality"];
    else
        return nil;
}

+ (int) numberOf2DViewer
{
    return numberOf2DViewer;
}

#ifndef OSIRIX_LIGHT
- (IBAction)querySelectedStudy: (id)sender
{
    [[BrowserController currentBrowser] querySelectedStudy: self];
}
#endif

#pragma mark-
#pragma mark 2. window subdivision

#define SERIESPOPUPSIZE 35

- (void) buildSeriesPopup
{
    if( needsToBuildSeriesPopupMenu == NO)
        return;
    
    needsToBuildSeriesPopupMenu = NO;
    
    [seriesPopupMenu.menu removeAllItems];
    
    if( seriesPopupContextualMenu == nil)
        seriesPopupContextualMenu = [[NSMenuItem alloc] initWithTitle: @"Displayed Series" action: nil keyEquivalent: @""];
    
    [seriesPopupContextualMenu setSubmenu: nil];
    
    BOOL hasComparatives = NO, hasComparativesNewerThanMostRecentLoaded = NO;
    
    @try
    {
        DicomDatabase *db = [[BrowserController currentBrowser] database];
        NSPredicate				*predicate;
        long					i, index = 0;
        NSManagedObject			*curImage = [fileList[0] objectAtIndex:0];
        
        DicomStudy *study = [curImage valueForKeyPath:@"series.study"];
        if( study == nil)
            return;
        
        NSMutableArray *viewerSeries = [NSMutableArray array];
        
        for( int i = 0 ; i < maxMovieIndex; i++)
            [viewerSeries addObject: [[fileList[ i] objectAtIndex:0] valueForKey:@"series"]];
        
        // FIND ALL STUDIES of this patient
        NSString *searchString = [study valueForKey:@"patientUID"];
        
        if( [searchString length] == 0 || [searchString isEqualToString:@"0"])
        {
            searchString = [study valueForKey:@"name"];
            predicate = [NSPredicate predicateWithFormat: @"(name == %@)", searchString];
        }
        else predicate = [NSPredicate predicateWithFormat: @"(patientUID BEGINSWITH[cd] %@)", searchString];
        
        NSArray *studiesArray = nil;
        // Use the 'history' array of the browser controller, if available (with the distant studies)
        if( [[[BrowserController currentBrowser] comparativePatientUID] compare: [study patientUID] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame && [[BrowserController currentBrowser] comparativeStudies] != nil)
            studiesArray = [BrowserController currentBrowser].comparativeStudies;
        else
        {
            if( [[BrowserController currentBrowser] selectThisStudy: study] == NO)
                NSLog( @"---- buildSeriesPopup - history not found");
            
            studiesArray = [db objectsForEntity:db.studyEntity predicate:predicate];
            studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"date" ascending: NO]]];
        }
        
#ifndef OSIRIX_LIGHT
        if (!retrieveImage) {
            retrieveImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DownArrowGreyRev" ofType:@"pdf"]];
            retrieveImage.size = NSMakeSize(50,50);
        }
#endif
        
        if ([studiesArray count])
        {
            studiesArray = [NSArray arrayWithArray: studiesArray];
            
            NSArray *displayedSeries = [ViewerController getDisplayedSeries];
            NSMutableArray *seriesArray = [NSMutableArray array];
            
            i = 0;
            for( id s in studiesArray)
            {
#ifndef OSIRIX_LIGHT
                if( [s isKindOfClass: [DCMTKStudyQueryNode class]] && [[s valueForKey: @"studyInstanceUID"] isEqualToString: study.studyInstanceUID]) // For the current study, always take the local images
                    s = study;
                else if ([s isKindOfClass: [DCMTKStudyQueryNode class]]) { // and still, if there are local series, display them!
                    NSArray* local = [db objectsForEntity:db.studyEntity predicate:[NSPredicate predicateWithFormat:@"studyInstanceUID = %@ AND patientID = %@", [s studyInstanceUID], [s patientID]]];
                    if (local.count)
                        s = [local objectAtIndex:0];
                }
#endif
                
                if( [s isKindOfClass: [DicomStudy class]]) //Local Study DicomStudy
                {
                    [seriesArray addObject: [[BrowserController currentBrowser] childrenArray: s]];
                    
                    //if( [s isHidden] == NO)
                    i += [[seriesArray lastObject] count];
                }
#ifndef OSIRIX_LIGHT
                else if( [s isKindOfClass: [DCMTKStudyQueryNode class]]) //Distant Study DCMTKQueryStudyNode
                {
                    [seriesArray addObject: [NSArray array]];
                }
#endif
            }
            
            NSArray *allStudiesArray = studiesArray;
            
#ifndef OSIRIX_LIGHT
            NSMutableArray* tstudiesArray = [NSMutableArray array];
            NSMutableArray* tseriesArray = [NSMutableArray array];
            BOOL iteratedFirstLoaded = NO;
            for (int i = 0; i < studiesArray.count; ++i) {
                id s = [studiesArray objectAtIndex:i];
                NSArray* series = [seriesArray objectAtIndex:i];
                
                BOOL isNonLoadedComp = [s isKindOfClass:[DCMTKQueryNode class]];
                if (!isNonLoadedComp || series.count || self.flagListPODComparatives.boolValue) {
                    [tstudiesArray addObject:s];
                    [tseriesArray addObject:series];
                }
                
                if (isNonLoadedComp) {
                    hasComparatives = YES;
                    if (!iteratedFirstLoaded)
                        hasComparativesNewerThanMostRecentLoaded = YES;
                } else
                    iteratedFirstLoaded = YES;
            }
            studiesArray = tstudiesArray;
            seriesArray = tseriesArray;
#endif
            
            for( id curStudy in studiesArray)
            {
                NSMenuItem *cell = [[[NSMenuItem alloc] initWithTitle: @"" action: @selector( seriesPopupSelect:) keyEquivalent: @""] autorelease];
                [cell setTarget: self];
                [seriesPopupMenu.menu addItem: cell];
                
                NSUInteger curStudyIndexAll = [allStudiesArray indexOfObject: curStudy];
                NSUInteger curStudyIndex = [studiesArray indexOfObject: curStudy];
                
                [cell setRepresentedObject:[O2ViewerThumbnailsMatrixRepresentedObject object:curStudy children:[seriesArray objectAtIndex:curStudyIndex]]];
                
#ifndef OSIRIX_LIGHT
                if( [curStudy isKindOfClass: [DCMTKStudyQueryNode class]] && [[curStudy valueForKey: @"studyInstanceUID"] isEqualToString: study.studyInstanceUID]) // For the current study, always take the local images
                    curStudy = study;
#endif
                NSArray *series = [seriesArray objectAtIndex: curStudyIndex];
                NSArray *images = nil;
                
                if( [curStudy isKindOfClass: [DicomStudy class]])
                {
                    @try
                    {
                        images = [[BrowserController currentBrowser] imagesArray: curStudy preferredObject: oAny];
                        
                        if( [series count] != [images count])
                            N2LogStackTrace(@"[series count] != [images count] : You should not be here......");
                        
                        NSString *name = [[curStudy valueForKey:@"studyName"] stringByTruncatingToLength: 50];
                        
                        NSString *stateText;
                        NSUInteger stateIndex = [[curStudy valueForKey:@"stateText"] intValue];
                        if( stateIndex && stateIndex < BrowserController.statesArray.count) stateText = [BrowserController.statesArray objectAtIndex: stateIndex];
                        else stateText = @"";
                        
                        NSString *comment = [curStudy valueForKey:@"comment"];
                        
                        if( comment == nil)
                            comment = @"";
                        comment = [comment stringWithTruncatingToLength: 50];
                        
                        NSString *modality = [curStudy valueForKey:@"modality"];
                        if( modality == nil)
                            modality = @"OT:";
                        
#ifndef OSIRIX_LIGHT
                        if ([[cell.representedObject object] isKindOfClass:[DCMTKStudyQueryNode class]]) { // this is an incomplete study
                            [cell setImage:retrieveImage];
                            
                        }
#endif
                        
                        NSString *patName = @"";
                        
                        if( [curStudy valueForKey:@"name"] && [curStudy valueForKey:@"dateOfBirth"])
                            patName = [NSString stringWithFormat: @"%@ %@", [curStudy valueForKey:@"name"], [NSUserDefaults formatDate:[curStudy valueForKey:@"dateOfBirth"]]];
                        
                        if( [[curStudy valueForKey:@"name"] isEqualToString: study.name])
                            patName = @"";
                        
                        if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] != annotFull)
                            patName = @"";
                        
                        NSImage *number = [[[NSImage alloc] initWithSize: NSMakeSize( SERIESPOPUPSIZE, SERIESPOPUPSIZE)] autorelease];
                        
                        NSMutableDictionary *d = [NSMutableDictionary dictionary];
                        
                        NSArray *colors = ViewerController.studyColors;
                        NSColor *bkgColor = nil;
                        if( curStudyIndexAll >= colors.count)
                            bkgColor = [colors lastObject];
                        else
                            bkgColor = [colors objectAtIndex: curStudyIndexAll];
                        
                        [d setObject: [NSFont boldSystemFontOfSize: 16] forKey: NSFontAttributeName];
                        
                        NSAttributedString *s = [[[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%d", (int) curStudyIndexAll+1] attributes: d] autorelease];
                        
                        [number lockFocus];
                        
                        if( DisplayUseInvertedPolarity)
                            bkgColor = [NSColor colorWithCalibratedRed: 1.0-bkgColor.redComponent green: 1.0-bkgColor.greenComponent blue:1.0-bkgColor.blueComponent alpha: bkgColor.alphaComponent];
                        
                        [bkgColor set];
                        [[NSBezierPath bezierPathWithRoundedRect: NSMakeRect( 0, 0, SERIESPOPUPSIZE, SERIESPOPUPSIZE) xRadius: 5 yRadius: 5] fill];
                        [s drawAtPoint: NSMakePoint( (SERIESPOPUPSIZE - s.size.width) / 2, (SERIESPOPUPSIZE - s.size.height) /2)];
                        [number unlockFocus];
                        
                        [cell setImage: number];
                        
                        NSMutableArray* components = [NSMutableArray array];
                        if( [curStudy date]) [components addObject:[[NSUserDefaults dateTimeFormatter] stringFromDate:[curStudy date]]];
                        if( patName.length) [components addObject:patName];
                        if( name.length) [components addObject:name];
                        if( modality.length) [components addObject:modality];
                        if( comment.length) [components addObject:comment];
                        
                        NSAttributedString *finalString = [[[NSAttributedString alloc] initWithString: [components componentsJoinedByString:@" / "] attributes: [NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize: 14] forKey: NSFontAttributeName]] autorelease];
                        [cell setAttributedTitle: finalString];
                    }
                    @catch (NSException *exception) {
                        N2LogException( exception);
                    }
                    index++;
                }
                
#ifndef OSIRIX_LIGHT
                if ([curStudy isKindOfClass: [DCMTKQueryNode class]]) //Distant Study DCMTKQueryStudyNode
                {
                    @try
                    {
                        NSArray* local = [db objectsForEntity:db.studyEntity predicate:[NSPredicate predicateWithFormat:@"studyInstanceUID = %@ AND patientID = %@", [curStudy studyInstanceUID], [curStudy patientID]]];
                        if (local.count)
                            images = [[BrowserController currentBrowser] imagesArray:[local objectAtIndex:0] preferredObject: oAny];
                        
                        NSString *name = [[curStudy valueForKey:@"studyName"] stringByTruncatingToLength: 50];
                        if( name == nil)
                            name = @"";
                        NSString *modality = [curStudy valueForKey:@"modality"];
                        if( modality == nil)
                            modality = @"OT";
                        
                        NSString *patName = @"";
                        
                        if( [curStudy valueForKey:@"name"] && [curStudy valueForKey:@"dateOfBirth"])
                            patName = [NSString stringWithFormat: @"%@\r%@", [curStudy valueForKey:@"name"], [NSUserDefaults formatDate:[curStudy valueForKey:@"dateOfBirth"]]];
                        
                        if( [[curStudy name] isEqualToString:study.name])
                            patName = @"";
                        if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] != annotFull)
                            patName = @"";
                        
                        NSMutableArray* components = [NSMutableArray array];
                        if ([curStudy date]) [components addObject:[[NSUserDefaults dateTimeFormatter] stringFromDate:[curStudy date]]];
                        if (patName.length) [components addObject:patName];
                        if (name.length) [components addObject:name];
                        if (modality.length) [components addObject:modality];
                        
                        NSAttributedString *title = [[[NSAttributedString alloc] initWithString: [components componentsJoinedByString:@" / "] attributes: [NSDictionary dictionaryWithObject: [NSFont boldSystemFontOfSize: 14] forKey: NSFontAttributeName]] autorelease];
                        [cell setAttributedTitle: title];
                        
                        [cell setImage:retrieveImage];
                    }
                    @catch ( NSException *e) {
                        N2LogException( e);
                    }
                    index++;
                }
#endif
                
                //                if(![curStudy respondsToSelector:@selector(isHidden)] || [curStudy isHidden] == NO)
                {
                    for( i = 0; i < [series count]; i++)
                    {
                        DicomSeries* curSeries = [series objectAtIndex:i];
                        
                        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
                        NSMenuItem *cell = [[[NSMenuItem alloc] initWithTitle: @"" action: @selector( seriesPopupSelect:) keyEquivalent: @""] autorelease];
                        [cell setTarget: self];
                        [seriesPopupMenu.menu addItem: cell];
                        
                        [cell setRepresentedObject: [O2ViewerThumbnailsMatrixRepresentedObject object:curSeries]];
                        
                        NSString *name = [curSeries valueForKey:@"name"];
                        
                        if( [name length] > 50)
                            name = [name stringByTruncatingToLength: 50];
                        
                        if( name == nil)
                            name = @"";
                        
                        if( [viewerSeries containsObject: curSeries]) // Red
                        {
                            [attributes setObject: [[self class] _selectedItemColor] forKey: NSBackgroundColorAttributeName];
                            [seriesPopupMenu selectItem: cell];
                        }
                        else if( [[self blendingController] currentSeries] == curSeries) // Green
                            [attributes setObject:  [[self class] _fusionedItemColor] forKey: NSBackgroundColorAttributeName];
                        
                        else if( [displayedSeries containsObject: curSeries]) // Yellow
                            [attributes setObject:  [[self class] _openItemColor] forKey: NSBackgroundColorAttributeName];
                        
                        [attributes setObject: [NSFont systemFontOfSize: 14] forKey: NSFontAttributeName];
                        
                        name = [name stringByAppendingFormat: @" / %@", N2LocalizedSingularPluralCount( curSeries.images.count, @"image", @"images")];
                        
                        NSAttributedString *title = [[[NSAttributedString alloc] initWithString: name attributes: attributes] autorelease];
                        [cell setAttributedTitle: title];
                        
                        if( 1)
                        {
                            NSImage	*img = [[[NSImage alloc] initWithData: [curSeries primitiveValueForKey:@"thumbnail"]] autorelease];
                            
                            if( img == nil)
                            {
                                @try
                                {
                                    DCMPix* dcmPix = [[DCMPix alloc] initWithPath: [[images objectAtIndex: i] valueForKey:@"completePath"] :0 :0 :nil :0 :[[[images objectAtIndex: i] valueForKeyPath:@"series.id"] intValue] isBonjour:[[BrowserController currentBrowser] isCurrentDatabaseBonjour] imageObj:[images objectAtIndex: i]];
                                    
                                    [dcmPix CheckLoad];
                                    
                                    if (dcmPix && dcmPix.notAbleToLoadImage == NO)
                                    {
                                        img = [dcmPix generateThumbnailImageWithWW:0 WL:0];
                                        
                                        if( img)
                                        {
                                            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"StoreThumbnailsInDB"])
                                                curSeries.thumbnail = [BrowserController produceJPEGThumbnail:img];
                                        }
                                        else
                                            img = [NSImage imageNamed:@"FileNotFound.tif"];
                                        
                                    }
                                    else
                                        img = [NSImage imageNamed:@"FileNotFound.tif"];
                                    
                                    [dcmPix release];
                                }
                                @catch (NSException* e)
                                {
                                    N2LogExceptionWithStackTrace(e);
                                    img = [NSImage imageNamed:@"FileNotFound.tif"];
                                }
                            }
                            
                            if( DisplayUseInvertedPolarity)
                                img = [img imageInverted];
                            
                            [cell setImage: [img imageByScalingProportionallyToSizeUsingNSImage: NSMakeSize( SERIESPOPUPSIZE, SERIESPOPUPSIZE)]];
                        }
                        
                        index++;
                    }
                }
                
                if( curStudy != studiesArray.lastObject)
                    [seriesPopupMenu.menu addItem: [NSMenuItem separatorItem]];
            }
        }
    }
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [seriesPopupContextualMenu setSubmenu: [[seriesPopupMenu.menu copy] autorelease]];
    [seriesPopupContextualMenu setImage: seriesPopupMenu.selectedItem.image];
    [seriesPopupContextualMenu setTitle: (self.currentSeries.name ? self.currentSeries.name : NSLocalizedString( @"Unnamed", nil))];
    
    for( DCMView *v in self.imageViews)
        [v computeColor];
}

- (void) loadSelectedSeries: (id) series rightClick: (BOOL) rightClick
{
    if( [series isKindOfClass: [DicomStudy class]])
    {
        DicomStudy *s = series;
        
        NSArray *seriesArray = [s imageSeriesContainingPixels: YES];
        if( seriesArray.count)
            series = [seriesArray objectAtIndex: 0];
        else
            return;
    }
    
    NSMutableArray *viewerSeries = [NSMutableArray array];
    
    for( int i = 0 ; i < maxMovieIndex; i++)
    {
        if( [[fileList[ i] objectAtIndex:0] valueForKey:@"series"])
            [viewerSeries addObject: [[fileList[ i] objectAtIndex:0] valueForKey:@"series"]];
    }
    
    if( (rightClick || ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSCommandKeyMask)) && FullScreenOn == NO)
    {
        if( ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask) || [[BrowserController currentBrowser] isUsingExternalViewer: series] == NO)
        {
            BOOL c = [[NSUserDefaults standardUserDefaults] boolForKey:@"syncPreviewList"];
            
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"syncPreviewList"];
            
            ViewerController *newViewer = [[BrowserController currentBrowser] loadSeries :series :nil :YES keyImagesOnly: displayOnlyKeyImages];
            [newViewer setHighLighted: 1.0];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
                [self showCurrentThumbnail: self];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
                [NSApp sendAction: @selector(tileWindows:) to:nil from: self];
            else
                [[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
            
            for( int i = 0; i < [[NSScreen screens] count]; i++) [thumbnailsListPanel[ i] setThumbnailsView: nil viewer: nil];
            
            [[self window] makeKeyAndOrderFront: self];
            [self refreshToolbar];
            [self updateNavigator];
            
            [newViewer showCurrentThumbnail: self];
            
            [[NSUserDefaults standardUserDefaults] setBool: c forKey:@"syncPreviewList"];
            [self syncThumbnails];
        }
    }
    else
    {
        if( [viewerSeries containsObject: series] == NO)
        {
            BOOL found = NO;
            BOOL showWindowIfDisplayed = [[NSUserDefaults standardUserDefaults] boolForKey: @"showWindowInsteadOfSwitching"];
            
            if( ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask))
                showWindowIfDisplayed = !showWindowIfDisplayed;
            
            if( showWindowIfDisplayed)
            {
                // is this series already displayed? -> select it !
                
                for( ViewerController *v in [ViewerController getDisplayed2DViewers])
                {
                    if( [[v imageView] seriesObj] == series && v != self)
                    {
                        [[v window] makeKeyAndOrderFront: self];
                        [v setHighLighted: 1.0];
                        
                        found = YES;
                    }
                }
            }
            
            if( found == NO)
            {
                BOOL savedAUTOHIDEMATRIX = [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOHIDEMATRIX"];
                
                [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"AUTOHIDEMATRIX"];
                
                if( ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask) || [[BrowserController currentBrowser] isUsingExternalViewer: series] == NO)
                {
                    [[BrowserController currentBrowser] loadSeries :series :self :YES keyImagesOnly: displayOnlyKeyImages];
                    
                    [self showCurrentThumbnail:self];
                    [self updateNavigator];
                }
                
                [[NSUserDefaults standardUserDefaults] setBool: savedAUTOHIDEMATRIX forKey:@"AUTOHIDEMATRIX"];
            }
        }
        else if( series != [[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"series"]) // Select it in 4D !
        {
            NSUInteger idx = [viewerSeries indexOfObject: series];
            
            if( idx != NSNotFound)
            {
                [self setMovieIndex: idx];
                [self propagateSettings];
            }
        }
        else
            [self mouseMoved];
    }
}
- (IBAction)seriesPopupSelect:(NSMenuItem *)sender
{
    id series = [sender.representedObject object];
    
    if( [series isKindOfClass: [DicomStudy class]])
    {
        DicomStudy *s = series;
        series = [s.imageSeries objectAtIndex: 0];
        
        for( NSMenuItem *i in seriesPopupMenu.menu.itemArray)
        {
            if( series == [i.representedObject object])
                [seriesPopupMenu selectItem: i];
        }
    }
    
#ifndef OSIRIX_LIGHT
    if( [series isKindOfClass: [DCMTKStudyQueryNode class]]) //Distant Study
    {
        [[BrowserController currentBrowser] retrieveComparativeStudy: series select: YES open: YES showGUI: YES viewer: self];
        return;
    }
#endif
    
    [self loadSelectedSeries: series rightClick: NO];
}

- (void) matrixPreviewLoadAllSeries: (id) sender
{
    
}

- (void) matrixPreviewPressed:(id) sender
{
    ThumbnailCell *cell = [sender selectedCell];
    
    [cell setLineBreakMode: NSLineBreakByWordWrapping];
    [cell setFont:[NSFont boldSystemFontOfSize: [[BrowserController currentBrowser] fontSize: @"dbSmallMatrixFont"]]];
    
    [cell setImagePosition: NSImageBelow];
    [cell setTransparent:NO];
    [cell setEnabled:YES];
    
    [cell setButtonType:NSMomentaryPushInButton];
    [cell setBezelStyle:NSShadowlessSquareBezelStyle];
    //[cell setShowsStateBy:NSPushInCellMask];
    [cell setHighlightsBy:NSContentsCellMask];
    [cell setImageScaling:NSImageScaleProportionallyDown];
    [cell setBordered:YES];
    
    id series = [[[sender selectedCell] representedObject] object];
    
    [self loadSelectedSeries: series rightClick: cell.rightClick];
}

-(BOOL) checkFrameSize
{
    BOOL visible = [self matrixIsVisible];
    
    return visible;
}

- (void) setMatrixVisible: (BOOL) visible
{
    if( windowWillClose)
        return;
    
    BOOL currentlyVisible = [self matrixIsVisible];
    
    if (currentlyVisible != visible)
    {
        NSView* v = [[splitView subviews] objectAtIndex:0];
        [v setHidden:!visible];
        if (visible) {
            NSRect f = v.frame; f.size.width = [ThumbnailCell thumbnailCellWidth];
            [v setFrame:f];
        }
        [splitView resizeSubviewsWithOldSize:splitView.bounds.size];
        
        if( visible && needsToBuildSeriesMatrix)
            [self buildMatrixPreview: NO];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool: visible forKey: @"SeriesListVisible"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
        return;
    
    if( [keyPath isEqualToString:@"SeriesListVisible"])
    {
        static int noReentry = 0;
        
        if( noReentry == 0)
        {
            noReentry = 1;
            NSDisableScreenUpdates();
            for( ViewerController *v in [ViewerController getDisplayed2DViewers])
                [v setMatrixVisible: [[change objectForKey:NSKeyValueChangeNewKey] intValue]];
            NSEnableScreenUpdates();
            noReentry = 0;
        }
    }
}

- (void) autoHideMatrix
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
        return;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOHIDEMATRIX"] == NO)
        return;
    
    BOOL hide = NO;
    NSWindow *window = nil;
    
    if( windowWillClose)
        return;
    
    if( [self FullScreenON] == NO)
    {
        window = self.window;
        if( [window isKeyWindow] == NO)
            hide = YES;
        //		if( [window isMainWindow] == NO)
        //            hide = YES;
    }
    else
        window = FullScreenWindow;
    
    NSPoint	mouse = [window mouseLocationOutsideOfEventStream];
    
    BOOL isCurrentlyVisible = [self matrixIsVisible];
    
    if( hide == NO)
    {
        if( isCurrentlyVisible == NO)
        {
            if( mouse.x >= 0 && mouse.x <= [previewMatrix cellSize].width+13 && mouse.y >= 0 && mouse.y <= [splitView frame].size.height-20)
            {
                
            }
            else
                hide = YES;
        }
        else
        {
            if( mouse.x >= 0 && mouse.x <= [previewMatrix cellSize].width+13 && mouse.y >= 0 && mouse.y <= [splitView frame].size.height)
            {
                
            }
            else
                hide = YES;
        }
    }
    
    if( isCurrentlyVisible == hide)
    {
        NSMutableArray *scaleValues = [NSMutableArray array];
        NSMutableArray *originValues = [NSMutableArray array];
        
        for( DCMView * v in [seriesView imageViews])
        {
            [scaleValues addObject: [NSNumber numberWithFloat: v.scaleValue]];
            [originValues addObject: NSStringFromPoint( v.origin)];
        }
        
        [self setMatrixVisible: !hide];
        
        NSDisableScreenUpdates();
        
        int i = 0;
        for( DCMView * v in [seriesView imageViews])
        {
            [v displayIfNeeded];
            v.scaleValue = [[scaleValues objectAtIndex: i] floatValue];
            v.origin = NSPointFromString( [originValues objectAtIndex: i]);
            i++;
        }
        
        [self propagateSettings];
        
        for( DCMView * v in [seriesView imageViews])
            [v displayIfNeeded];
        
        NSEnableScreenUpdates();
    }
}

- (NSScrollView*) previewMatrixScrollView
{
    return previewMatrixScrollView;
}

- (NSView*) previewRootView
{
    return previewRootView;
}

- (void) syncThumbnails
{
    ViewBoundsDidChangeProtect = YES;
    
    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    {
        BOOL same = NO;
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SyncSeriesListForAllComparativeStudies"])
            same = [v.currentStudy.patientUID isEqualToString: self.currentStudy.patientUID];
        else
            same = [[v studyInstanceUID] isEqualToString: [self studyInstanceUID]];
        
        if( v != self && same)
        {
            [[v.previewMatrixScrollView contentView] scrollToPoint: [[v.previewMatrixScrollView contentView] constrainScrollPoint: [[previewMatrix superview] bounds].origin]];
            [v.previewMatrixScrollView reflectScrolledClipView: [v.previewMatrixScrollView contentView]];
            
            
            //            [NSAnimationContext beginGrouping];
            //            [[NSAnimationContext currentContext] setDuration:0.2];
            //            NSClipView* clipView = [v.previewMatrixScrollView contentView];
            //            [[clipView animator] setBoundsOrigin: [[v.previewMatrixScrollView contentView] constrainScrollPoint: [[previewMatrix superview] bounds].origin]];
            //            [v.previewMatrixScrollView reflectScrolledClipView: [v.previewMatrixScrollView contentView]]; // may not bee necessary
            //            [NSAnimationContext endGrouping];
        }
    }
    
    ViewBoundsDidChangeProtect = NO;
}

- (void) ViewBoundsDidChange: (NSNotification*) note
{
    if( ViewBoundsDidChangeProtect == NO)
    {
        ViewBoundsDidChangeProtect = YES;
        
        if( [note object] == [previewMatrixScrollView contentView])
        {
            BOOL syncThumbnails = [[NSUserDefaults standardUserDefaults] boolForKey: @"syncPreviewList"];
            
            if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSCommandKeyMask)
                syncThumbnails = !syncThumbnails;
            
            if( syncThumbnails)
            {
                [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector( syncThumbnails) object:nil];
                [self performSelector: @selector( syncThumbnails) withObject:nil afterDelay: 0.1];
            }
        }
        
        ViewBoundsDidChangeProtect = NO;
    }
}

-(void) ViewFrameDidChange:(NSNotification*) note
{
    if( windowWillClose)
        return;
    
    if( [[splitView subviews] count] > 1)
    {
        if ([note object] == [[splitView subviews] objectAtIndex: 1])
        {
            if( [self matrixIsVisible] && matrixPreviewBuilt == NO)
            {
                [self buildMatrixPreview];
            }
        }
    }
}

- (NSRect)splitView:(NSSplitView *)s effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
    if( s == splitView)
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
            return NSZeroRect;
    }
    
    return proposedEffectiveRect;
}

- (void)splitViewDidResizeSubviews:(NSNotification *) notification
{
    if( windowWillClose)
        return;
    
    if (notification.object == splitView)
    {
        [previewMatrix sizeToCells];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOHIDEMATRIX"] == NO && FullScreenOn == NO)
        {
            NSDisableScreenUpdates();
            
            // Apply show / hide matrix to all viewers
            if( ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask) == NO)
            {
                static BOOL noreentry = NO;
                
                if( noreentry == NO)
                {
                    noreentry = YES;
                    
                    BOOL showMatrix = [self matrixIsVisible];
                    
                    for( ViewerController *v in [ViewerController get2DViewers])
                    {
                        if( v != self)
                        {
                            if (showMatrix != [v matrixIsVisible])
                                [v setMatrixVisible: showMatrix];
                        }
                        else
                        {
                            if( [v matrixIsVisible] && needsToBuildSeriesMatrix)
                                [self buildMatrixPreview: NO];
                        }
                    }
                }
                noreentry = NO;
            }
            
            NSEnableScreenUpdates();
        }
    }
}

-(void)splitViewWillResizeSubviews:(NSNotification *)notification
{
    if( windowWillClose)
        return;
    
    if (notification.object == splitView)
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
        {
            OSIWindow* window = (OSIWindow*)self.window;
            if( [window respondsToSelector:@selector(disableUpdatesUntilFlush)])
                [window disableUpdatesUntilFlush];
        }
    }
}

- (BOOL)splitView: (NSSplitView *)sender canCollapseSubview: (NSView *)subview
{
    if( sender == splitView)
    {
        if( subview == [[sender subviews] objectAtIndex:1]) // Main view
            return NO;
    }
    
    //    if (sender == leftSplitView)
    //    {
    //        if (subview == [[sender subviews] objectAtIndex:1])
    //            return NO;
    //    }
    
    return YES;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
    if( windowWillClose)
        return proposedPosition;
    
    if (sender == splitView)
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
            return 0;
        
        CGFloat rcs = [ThumbnailCell thumbnailCellWidth];
        
        NSScrollView* scrollView = previewMatrixScrollView;
        CGFloat scrollbarWidth = 0;
        if ([scrollView isKindOfClass:[NSScrollView class]])
        {
            NSScroller* scroller = [scrollView verticalScroller];
            if ([BrowserController _scrollerStyle:scroller] != 1)
                if ([scrollView hasVerticalScroller] && ![scroller isHidden])
                    scrollbarWidth = [scroller frame].size.width;
        }
        
        proposedPosition -= scrollbarWidth;
        
        NSUInteger f = roundf(proposedPosition/rcs);
        if (f > 1) f = 1;
        proposedPosition = rcs*f;
        
        if (proposedPosition)
            proposedPosition += (scrollbarWidth?scrollbarWidth+2:1);
        
        return proposedPosition;
    }
    //
    //    if (sender == leftSplitView)
    //    {
    //        if (offset == 0)
    //        {
    //            if ([sender isSubviewCollapsed:[sender.subviews objectAtIndex:0]])//[sender.subviews count] == 2)
    //                return 0;
    //            else
    //                return 15;
    //        }
    //    }
    
    return proposedPosition;
}

-(BOOL) matrixIsVisible
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
        return YES;
    
    NSView* v = [[splitView subviews] objectAtIndex:0];
    
    BOOL r = ![v isHidden] && [v frame].size.width >= [ThumbnailCell thumbnailCellWidth];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SeriesListVisible"] != r)
        [[NSUserDefaults standardUserDefaults] setBool: r forKey: @"SeriesListVisible"];
    
    return r;
}

-(void) splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
    if( windowWillClose)
        return;
    
    if( sender == splitView)
    {
        CGFloat dividerPosition = [self matrixIsVisible]? [ThumbnailCell thumbnailCellWidth] : 0;
        dividerPosition = [self splitView:sender constrainSplitPosition:dividerPosition ofSubviewAt:0];
        
        NSRect splitFrame = [sender frame];
        
        if( isnan(splitFrame.size.height) || splitFrame.size.height < 0 || isnan(splitFrame.size.width) || splitFrame.size.width < 0)
        {
            NSLog( @"******* splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize - %f", splitFrame.size.height);
            return;
        }
        
        [[[sender subviews] objectAtIndex:0] setFrame:NSMakeRect(0, 0, dividerPosition, splitFrame.size.height)];
        [[[sender subviews] objectAtIndex:1] setFrame:NSMakeRect(dividerPosition+sender.dividerThickness, 0, splitFrame.size.width-dividerPosition-sender.dividerThickness, splitFrame.size.height)];
    }
    
    //    if (sender == leftSplitView)
    //    {
    //        {
    //            CGFloat ch = [sender isSubviewCollapsed:[sender.subviews objectAtIndex:0]]? 0 : 15;
    //            [[sender.subviews objectAtIndex:0] setFrame:NSMakeRect(0, 0, sender.frame.size.width, ch)];
    //            if (ch > 0) ch += sender.dividerThickness;
    //            [[sender.subviews objectAtIndex:1] setFrame:NSMakeRect(0, ch, sender.frame.size.width, sender.frame.size.height-ch)];
    //        }
    //    }
}

-(void) observeScrollerStyleDidChangeNotification:(NSNotification*)n
{
    [splitView resizeSubviewsWithOldSize:[splitView bounds].size];
}

- (void) matrixPreviewSwitchHidden:(id) sender
{
    id curStudy = [[[sender selectedCell] representedObject] object];
    
    if( [curStudy isKindOfClass: [DicomStudy class]]) //Local study
    {
        if([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSCommandKeyMask)
        {
            [[BrowserController currentBrowser] databaseOpenStudy: curStudy];
        }
        else
        {
            [curStudy setHidden: ![curStudy isHidden]];
            
            for( ViewerController *v in [ViewerController getDisplayed2DViewers])
            {
                if( [v.studyInstanceUID isEqualToString: self.studyInstanceUID])
                    [v buildMatrixPreview: NO];
                else
                    [v buildMatrixPreview: YES];
            }
        }
    }
#ifndef OSIRIX_LIGHT
    else if( [curStudy isKindOfClass: [DCMTKStudyQueryNode class]]) //Distant Study
    {
        [[BrowserController currentBrowser] retrieveComparativeStudy: curStudy select: NO open: NO];
    }
#endif
}

- (void) checkBuiltMatrixPreview
{
    if( [self checkFrameSize] == YES && matrixPreviewBuilt == NO)
    {
        if( [[self window] isKeyWindow])
            [self buildMatrixPreview: YES];
        else
            [self buildMatrixPreview: NO];
    }
}

+ (NSColor*)_selectedItemColor { // red
    return [NSColor colorWithCalibratedRed:252./255 green:177./255 blue:141./255 alpha:1];
}

+ (NSColor*)_fusionedItemColor { // green
    return [NSColor colorWithCalibratedRed:195./255 green:249./255 blue:145./255 alpha:1];
}

+ (NSColor*)_openItemColor { // yellow
    return [NSColor colorWithCalibratedRed:249./255 green:240./255 blue:140./255 alpha:1];
}

+ (NSColor*)_differentStudyColor { // gray
    return [NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1];
}

- (void) buildMatrixPreview: (BOOL) showSelected
{
    if( [[self window] isVisible] == NO) return;	//we will do it in checkBuiltMatrixPreview : faster opening !
    if( windowWillClose) return;
    
    // series popup menu button : will build all the items, when needed, later
    
    needsToBuildSeriesPopupMenu = YES;
    needsToBuildSeriesMatrix = YES;
    
    [seriesPopupMenu.menu removeAllItems];
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: @"" action: @selector( seriesPopupSelect:) keyEquivalent: @""] autorelease];
    NSImage	*img = [[[NSImage alloc] initWithData: [self.currentSeries primitiveValueForKey:@"thumbnail"]] autorelease];
    
    if( DisplayUseInvertedPolarity)
        img = [img imageInverted];
    
    [menuItem setImage: [img imageByScalingProportionallyToSizeUsingNSImage: NSMakeSize( SERIESPOPUPSIZE, SERIESPOPUPSIZE)]];
    [seriesPopupMenu.menu addItem: menuItem];
    [seriesPopupContextualMenu setTitle: (self.currentSeries.name ? self.currentSeries.name : NSLocalizedString( @"Unnamed", nil))];
    
    if( [self matrixIsVisible] == NO)
        return;
    
    // *************
    
    BOOL hasComparatives = NO, hasComparativesNewerThanMostRecentLoaded = NO;
    
    @try
    {
        DicomDatabase *db = [[BrowserController currentBrowser] database];
        NSPredicate				*predicate;
        long					i, index = 0;
        NSManagedObject			*curImage = [fileList[0] objectAtIndex:0];
        NSPoint					origin = [[previewMatrix superview] bounds].origin;
        
        BOOL visible = [self checkFrameSize];
        
        if( visible == NO) matrixPreviewBuilt = NO;
        else matrixPreviewBuilt = YES;
        
        [previewMatrixScrollView setPostsBoundsChangedNotifications:YES];
        
        DicomStudy *study = [curImage valueForKeyPath:@"series.study"];
        if( study == nil)
        {
            [previewMatrix renewRows: 0 columns: 0];
            [previewMatrix sizeToCells];
            matrixPreviewBuilt = NO;
            return;
        }
        
        NSMutableArray *viewerSeries = [NSMutableArray array];
        
        for( int i = 0 ; i < maxMovieIndex; i++)
            [viewerSeries addObject: [[fileList[ i] objectAtIndex:0] valueForKey:@"series"]];
        
        // FIND ALL STUDIES of this patient
        NSString *searchString = [study valueForKey:@"patientUID"];
        
        if( [searchString length] == 0 || [searchString isEqualToString:@"0"])
        {
            searchString = [study valueForKey:@"name"];
            predicate = [NSPredicate predicateWithFormat: @"(name == %@)", searchString];
        }
        else predicate = [NSPredicate predicateWithFormat: @"(patientUID BEGINSWITH[cd] %@)", searchString];
        
        NSArray *studiesArray = nil;
        // Use the 'history' array of the browser controller, if available (with the distant studies)
        
        if( [[[BrowserController currentBrowser] comparativePatientUID] compare: [study patientUID] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame && [[BrowserController currentBrowser] comparativeStudies] != nil)
            studiesArray = [BrowserController currentBrowser].comparativeStudies;
        else
        {
            //            if( [[BrowserController currentBrowser] selectThisStudy: study] == NO)
            //                NSLog( @"---- buildMatrixPreview - history not found");
            
            studiesArray = [db objectsForEntity:db.studyEntity predicate:predicate];
            studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"date" ascending: NO]]];
        }
        
#ifndef OSIRIX_LIGHT
        
        if (!retrieveImage) {
            retrieveImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DownArrowGreyRev" ofType:@"pdf"]];
            retrieveImage.size = NSMakeSize(SERIESPOPUPSIZE,SERIESPOPUPSIZE);
        }
#endif
        
        if ([studiesArray count])
        {
            studiesArray = [NSArray arrayWithArray: studiesArray];
            
            NSArray *displayedSeries = [ViewerController getDisplayedSeries];
            NSMutableArray *seriesArray = [NSMutableArray array];
            
            i = 0;
            for( id s in studiesArray)
            {
#ifndef OSIRIX_LIGHT
                if( [s isKindOfClass: [DCMTKStudyQueryNode class]] && [[s valueForKey: @"studyInstanceUID"] isEqualToString: study.studyInstanceUID]) // For the current study, always take the local images
                    s = study;
                else if ([s isKindOfClass: [DCMTKStudyQueryNode class]]) { // and still, if there are local series, display them!
                    NSArray* local = [db objectsForEntity:db.studyEntity predicate:[NSPredicate predicateWithFormat:@"studyInstanceUID = %@ AND patientID = %@", [s studyInstanceUID], [s patientID]]];
                    if (local.count)
                        s = [local objectAtIndex:0];
                }
#endif
                
                if( [s isKindOfClass: [DicomStudy class]]) //Local Study DicomStudy
                {
                    [seriesArray addObject: [[BrowserController currentBrowser] childrenArray: s]];
                    
                    if( [s isHidden] == NO)
                        i += [[seriesArray lastObject] count];
                    
                    //                    i++; // display all button
                }
#ifndef OSIRIX_LIGHT
                else if( [s isKindOfClass: [DCMTKStudyQueryNode class]]) //Distant Study DCMTKQueryStudyNode
                {
                    [seriesArray addObject: [NSArray array]];
                }
#endif
            }
            
            NSArray *allStudiesArray = studiesArray;
            
#ifndef OSIRIX_LIGHT
            NSMutableArray* tstudiesArray = [NSMutableArray array];
            NSMutableArray* tseriesArray = [NSMutableArray array];
            BOOL iteratedFirstLoaded = NO;
            for (int i = 0; i < studiesArray.count; ++i) {
                id s = [studiesArray objectAtIndex:i];
                NSArray* series = [seriesArray objectAtIndex:i];
                
                BOOL isNonLoadedComp = [s isKindOfClass:[DCMTKQueryNode class]];
                if (!isNonLoadedComp || series.count || self.flagListPODComparatives.boolValue) {
                    [tstudiesArray addObject:s];
                    [tseriesArray addObject:series];
                }
                
                if (isNonLoadedComp) {
                    hasComparatives = YES;
                    if (!iteratedFirstLoaded)
                        hasComparativesNewerThanMostRecentLoaded = YES;
                } else
                    iteratedFirstLoaded = YES;
            }
            
            studiesArray = tstudiesArray;
            seriesArray = tseriesArray;
#endif
            
            [previewMatrix setCellClass: [ThumbnailCell class]];
            
            if( [previewMatrix numberOfRows] != i+[studiesArray count])
                [previewMatrix renewRows: i+[studiesArray count] columns: 1];
            
            [previewMatrix sizeToCells];
            
            for (NSButtonCell* cell in previewMatrix.cells)
            {
                [cell setLineBreakMode: NSLineBreakByWordWrapping];
                [cell setFont:[NSFont boldSystemFontOfSize: [[BrowserController currentBrowser] fontSize: @"dbSmallMatrixFont"]]];
                [cell setBackgroundColor:nil];
                
                [cell setRepresentedObject:nil];
                
                [cell setImagePosition: NSImageBelow];
                [cell setTransparent:NO];
                [cell setEnabled:YES];
                
                [cell setButtonType:NSMomentaryPushInButton];
                [cell setBezelStyle:NSShadowlessSquareBezelStyle];
                //[cell setShowsStateBy:NSPushInCellMask];
                [cell setHighlightsBy:NSContentsCellMask];
                [cell setImageScaling:NSImageScaleProportionallyDown];
                [cell setBordered:YES];
                
                [cell setTitle:@""];
                
                [cell setImage: nil];
                
                [cell setTarget: self];
            }
            
            
            for( id curStudy in studiesArray)
            {
                NSButtonCell* cell = [previewMatrix cellAtRow: index column:0];
                
                NSUInteger curStudyIndexAll = [allStudiesArray indexOfObject: curStudy];
                NSUInteger curStudyIndex = [studiesArray indexOfObject: curStudy];
                
                [cell setRepresentedObject:[O2ViewerThumbnailsMatrixRepresentedObject object:curStudy children:[seriesArray objectAtIndex:curStudyIndex]]];
                [cell setAction: @selector(matrixPreviewSwitchHidden:)];
                
#ifndef OSIRIX_LIGHT
                if( [curStudy isKindOfClass: [DCMTKStudyQueryNode class]] && [[curStudy valueForKey: @"studyInstanceUID"] isEqualToString: study.studyInstanceUID]) // For the current study, always take the local images
                    curStudy = study;
#endif
                
                if( [[curStudy valueForKey: @"studyInstanceUID"] isEqualToString: study.studyInstanceUID])
                    [cell setBackgroundColor: nil];
                else
                    [cell setBackgroundColor: [[self class] _differentStudyColor]];
                
                NSArray *series = [seriesArray objectAtIndex: curStudyIndex];
                NSArray *images = nil;
                
                if( [curStudy isKindOfClass: [DicomStudy class]])
                {
                    @try
                    {
                        images = [[BrowserController currentBrowser] imagesArray: curStudy preferredObject: oAny];
                        
                        if( [series count] != [images count])
                            N2LogStackTrace(@"[series count] != [images count] : You should not be here......");
                        
                        NSString *name = [[curStudy valueForKey:@"studyName"] stringByTruncatingToLength: 34];
                        
                        NSString *stateText;
                        NSUInteger stateIndex = [[curStudy valueForKey:@"stateText"] intValue];
                        if( stateIndex && stateIndex < BrowserController.statesArray.count) stateText = [BrowserController.statesArray objectAtIndex: stateIndex];
                        else stateText = @"";
                        NSString *comment = [curStudy valueForKey:@"comment"];
                        
                        if( comment == nil)
                            comment = @"";
                        comment = [comment stringWithTruncatingToLength: 32];
                        
                        NSString *modality = [curStudy valueForKey:@"modality"];
                        if( modality == nil)
                            modality = @"OT:";
                        
                        NSString *action = nil;
#ifndef OSIRIX_LIGHT
                        if ([[cell.representedObject object] isKindOfClass:[DCMTKStudyQueryNode class]]) { // this is an incomplete study
                            
                            switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
                            {
                                case -1:
                                    [cell setImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 0.6]];
                                    [cell setAlternateImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 0.6]];
                                    break;
                                case 0:
                                    [cell setImage: retrieveImage];
                                    [cell setAlternateImage: retrieveImage];
                                    break;
                                case 1:
                                    [cell setImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 1.3]];
                                    [cell setAlternateImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 1.3]];
                                    break;
                            }
                            
                            [cell setImagePosition:NSImageOverlaps];
                            [cell setImageScaling:NSImageScaleProportionallyDown];
                            
                        } else {
#endif
                            if( [curStudy isHidden])
                                action = NSLocalizedString(@"Show Series", nil);
                            else
                                action = NSLocalizedString(@"Hide Series", nil);
#ifndef OSIRIX_LIGHT
                        }
#endif
                        
                        NSString *patName = @"";
                        
                        if( [curStudy valueForKey:@"name"] && [curStudy valueForKey:@"dateOfBirth"])
                            patName = [NSString stringWithFormat: @"%@\r%@", [curStudy valueForKey:@"name"], [NSUserDefaults formatDate:[curStudy valueForKey:@"dateOfBirth"]]];
                        
                        if( [[curStudy valueForKey:@"name"] isEqualToString: study.name])
                            patName = @"";
                        
                        if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] != annotFull)
                            patName = @"";
                        
                        NSMutableArray* components = [NSMutableArray array];
                        [components addObject: [NSString stringWithFormat: @" %d ", (int) curStudyIndexAll+1]];
                        [components addObject: @""];
                        if (patName.length) [components addObject:patName];
                        if (name.length) [components addObject:name];
                        if ([curStudy date]) [components addObject:[[NSUserDefaults dateTimeFormatter] stringFromDate:[curStudy date]]];
                        [components addObject:[NSString stringWithFormat:NSLocalizedString(@"%@: %@", @"semicolon separator for spacing"), modality, N2SingularPluralCount([series count], NSLocalizedString(@"series", @"one series, singular"), NSLocalizedString(@"series", @"zero or 2 or more series, plural"))]];
                        if (stateText.length) [components addObject:stateText];
                        if (comment.length) [components addObject:comment];
                        if (action.length) [components addObject:[NSString stringWithFormat:@"\r%@", action]];
                        
                        
                        NSMutableAttributedString *finalString = [[[NSMutableAttributedString alloc] initWithString: [components componentsJoinedByString:@"\r"]] autorelease];
                        
                        NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
                        [attribs setObject: [NSFont boldSystemFontOfSize: [[BrowserController currentBrowser] fontSize: @"viewerNumberFont"]] forKey: NSFontAttributeName];
                        
                        NSArray *colors = ViewerController.studyColors;
                        NSColor *bkgColor = nil;
                        if( curStudyIndexAll >= colors.count)
                            bkgColor = [colors lastObject];
                        else
                            bkgColor = [colors objectAtIndex: curStudyIndexAll];
                        
                        if( DisplayUseInvertedPolarity)
                            bkgColor = [NSColor colorWithCalibratedRed: 1.0-bkgColor.redComponent green: 1.0-bkgColor.greenComponent blue:1.0-bkgColor.blueComponent alpha: bkgColor.alphaComponent];
                        
                        [attribs setObject: bkgColor forKey: NSBackgroundColorAttributeName];
                        [finalString setAttributes: attribs range: NSMakeRange( 0, [[components objectAtIndex: 0] length])];
                        
                        [attribs setObject: [NSFont boldSystemFontOfSize: [[BrowserController currentBrowser] fontSize: @"dbSmallMatrixFont"]] forKey: NSFontAttributeName];
                        [attribs removeObjectForKey: NSBackgroundColorAttributeName];
                        [finalString setAttributes: attribs range: NSMakeRange( [[components objectAtIndex: 0] length], finalString.length - [[components objectAtIndex: 0] length])];
                        
                        [finalString setAlignment:NSCenterTextAlignment range: NSMakeRange( 0, finalString.length)];
                        [cell setAttributedTitle: finalString];
                        
                        //                        index++;
                        //
                        //                        {
                        //                            cell = [previewMatrix cellAtRow: index column:0];
                        //
                        //                            [cell setRepresentedObject:[O2ViewerThumbnailsMatrixRepresentedObject object:curStudy children: nil]];
                        //                            [cell setAction: @selector(matrixPreviewLoadAllSeries:)];
                        //                            xxxxxx
                        //                            NSMutableAttributedString *finalString = [[[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"All series", nil)] autorelease];
                        //
                        //                            NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
                        //                            [attribs setObject: [NSFont boldSystemFontOfSize: [[BrowserController currentBrowser] fontSize: @"dbSmallMatrixFont"]] forKey: NSFontAttributeName];
                        //                            [finalString setAttributes: attribs range: NSMakeRange( 0, finalString.length)];
                        //
                        //                            [finalString setAlignment:NSCenterTextAlignment range: NSMakeRange( 0, finalString.length)];
                        //                            [cell setAttributedTitle: finalString];
                        //                        }
                    }
                    @catch (NSException *exception) {
                        N2LogException( exception);
                    }
                    index++;
                }
                
#ifndef OSIRIX_LIGHT
                if ([curStudy isKindOfClass: [DCMTKQueryNode class]]) //Distant Study DCMTKQueryStudyNode
                {
                    @try
                    {
                        NSArray* local = [db objectsForEntity:db.studyEntity predicate:[NSPredicate predicateWithFormat:@"studyInstanceUID = %@ AND patientID = %@", [curStudy studyInstanceUID], [curStudy patientID]]];
                        if (local.count)
                            images = [[BrowserController currentBrowser] imagesArray:[local objectAtIndex:0] preferredObject: oAny];
                        
                        NSString *name = [[curStudy valueForKey:@"studyName"] stringByTruncatingToLength: 34];
                        if( name == nil)
                            name = @"";
                        NSString *stateText = @"";
                        NSString *comment = @"";
                        NSString *modality = [curStudy valueForKey:@"modality"];
                        if( modality == nil)
                            modality = @"OT";
                        
                        NSString *patName = @"";
                        
                        if( [curStudy valueForKey:@"name"] && [curStudy valueForKey:@"dateOfBirth"])
                            patName = [NSString stringWithFormat: @"%@\r%@", [curStudy valueForKey:@"name"], [NSUserDefaults formatDate:[curStudy valueForKey:@"dateOfBirth"]]];
                        
                        if( [[curStudy name] isEqualToString:study.name])
                            patName = @"";
                        if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] != annotFull)
                            patName = @"";
                        
                        if ([stateText length] == 0 && [comment length] == 0) {
                            NSMutableArray* components = [NSMutableArray array];
                            if (patName.length) [components addObject:patName];
                            if (name.length) [components addObject:name];
                            if ([curStudy date]) [components addObject:[[NSUserDefaults dateTimeFormatter] stringFromDate:[curStudy date]]];
                            if (modality.length) [components addObject:modality];
                            [cell setTitle:[components componentsJoinedByString:@"\r"]];
                        }
                        
                        switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
                        {
                            case -1:
                                [cell setImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 0.6]];
                                [cell setAlternateImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 0.6]];
                                break;
                            case 0:
                                [cell setImage: retrieveImage];
                                [cell setAlternateImage:retrieveImage];
                                break;
                            case 1:
                                [cell setImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 1.3]];
                                [cell setAlternateImage: [retrieveImage imageByScalingProportionallyUsingNSImage: 1.3]];
                                break;
                        }
                        
                        [cell setImagePosition:NSImageOverlaps];
                        [cell setImageScaling:NSImageScaleProportionallyDown];
                    }
                    @catch ( NSException *e) {
                        N2LogException( e);
                    }
                    index++;
                }
#endif
                
                if(![curStudy respondsToSelector:@selector(isHidden)] || [curStudy isHidden] == NO)
                {
                    for( i = 0; i < [series count]; i++)
                    {
                        DicomSeries* curSeries = [series objectAtIndex:i];
                        
                        NSButtonCell *cell = [previewMatrix cellAtRow: index column:0];
                        
                        if( [[curStudy valueForKey: @"studyInstanceUID"] isEqualToString: study.studyInstanceUID])
                            [cell setBackgroundColor: nil];
                        else
                            [cell setBackgroundColor: [[self class] _differentStudyColor]];
                        
                        [cell setRepresentedObject: [O2ViewerThumbnailsMatrixRepresentedObject object:curSeries]];
                        [cell setFont:[NSFont systemFontOfSize: [[BrowserController currentBrowser] fontSize: @"dbSmallMatrixFont"]]];
                        [cell setAction: @selector(matrixPreviewPressed:)];
                        [cell setLineBreakMode: NSLineBreakByCharWrapping];
                        
                        NSString *name = [curSeries valueForKey:@"name"];
                        
                        if( [name length] > 18)
                        {
                            [cell setFont:[NSFont boldSystemFontOfSize: [[BrowserController currentBrowser] fontSize: @"viewerSmallCellFont"]]];
                            name = [name stringByTruncatingToLength: 34];
                        }
                        
                        NSString *singleType = NSLocalizedString( @"Image", nil);
                        NSString *pluralType = NSLocalizedString( @"Images", nil);
                        int count = [[curSeries valueForKey:@"noFiles"] intValue];
                        if( count == 1)
                        {
                            @try
                            {
                                int frames = [[[[curSeries valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
                                if( frames > 1)
                                {
                                    count = frames;
                                    pluralType = NSLocalizedString( @"Frames", @"Frames: for example, 50 Frames in a series");
                                }
                            }
                            @catch (NSException * e)
                            {
                                N2LogExceptionWithStackTrace(e);
                            }
                        }
                        else if (count == 0)
                        {
                            count = [[curSeries valueForKey: @"rawNoFiles"] intValue];
                            
                            int frames = [[[[curSeries valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
                            
                            if( count == 1 && frames > 1)
                                count = frames;
                            
                            if( count == 1)
                                singleType = NSLocalizedString( @"Object", nil);
                            else
                                pluralType = NSLocalizedString( @"Objects", nil);
                        }
                        
                        if( name == nil)
                            name = @"";
                        
                        [cell setTitle:[NSString stringWithFormat:@"%@\r%@\r%@", name, [[NSUserDefaults dateTimeFormatter] stringFromDate: [curSeries valueForKey:@"date"]], N2LocalizedSingularPluralCount(count, singleType, pluralType)]];
                        
                        if( [viewerSeries containsObject: curSeries]) // Red
                        {
                            [cell setBackgroundColor:[[self class] _selectedItemColor]];
                        }
                        else if( [[self blendingController] currentSeries] == curSeries) // Green
                        {
                            [cell setBackgroundColor: [[self class] _fusionedItemColor]];
                        }
                        else if( [displayedSeries containsObject: curSeries]) // Yellow
                        {
                            [cell setBackgroundColor: [[self class] _openItemColor]];
                        }
                        
                        if( visible)
                        {
                            NSImage	*img = [[[NSImage alloc] initWithData: [curSeries primitiveValueForKey:@"thumbnail"]] autorelease];
                            
                            if( img == nil)
                            {
                                @try
                                {
                                    DCMPix* dcmPix = [[DCMPix alloc] initWithPath: [[images objectAtIndex: i] valueForKey:@"completePath"] :0 :0 :nil :0 :[[[images objectAtIndex: i] valueForKeyPath:@"series.id"] intValue] isBonjour:[[BrowserController currentBrowser] isCurrentDatabaseBonjour] imageObj:[images objectAtIndex: i]];
                                    
                                    [dcmPix CheckLoad];
                                    
                                    if (dcmPix && dcmPix.notAbleToLoadImage == NO)
                                    {
                                        img = [dcmPix generateThumbnailImageWithWW:0 WL:0];
                                        
                                        if (img)
                                        {
                                            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"StoreThumbnailsInDB"])
                                                curSeries.thumbnail = [BrowserController produceJPEGThumbnail:img];
                                        }
                                        else img = [NSImage imageNamed:@"FileNotFound.tif"];
                                        
                                    }
                                    else img = [NSImage imageNamed:@"FileNotFound.tif"];
                                    
                                    [dcmPix release];
                                }
                                @catch (NSException* e)
                                {
                                    N2LogExceptionWithStackTrace(e);
                                    img = [NSImage imageNamed:@"FileNotFound.tif"];
                                }
                            }
                            
                            if( DisplayUseInvertedPolarity)
                                img = [img imageInverted];
                            
                            switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
                            {
                                case -1:
                                    [cell setImage: [img imageByScalingProportionallyUsingNSImage: 0.6]];
                                    [cell setAlternateImage:[img imageByScalingProportionallyUsingNSImage: 0.6]];
                                    break;
                                case 0:
                                    [cell setImage: img];
                                    [cell setAlternateImage:img];
                                    break;
                                case 1:
                                    [cell setImage: [img imageByScalingProportionallyUsingNSImage: 1.3]];
                                    [cell setAlternateImage:[img imageByScalingProportionallyUsingNSImage: 1.3]];
                                    break;
                            }
                        }
                        
                        index++;
                    }
                }
                else // series are hidden : color the study cell if series are selected
                {
                    //   [cell setBordered: YES];
                    for( i = 0; i < [series count]; i++)
                    {
                        DicomSeries* curSeries = [series objectAtIndex:i];
                        
                        if( [viewerSeries containsObject: curSeries]) // Red
                        {
                            [cell setBackgroundColor:[[self class] _selectedItemColor]];
                            //[cell setBordered: NO];
                            break;
                        }
                        else if( [[self blendingController] currentSeries] == curSeries) // Green
                        {
                            [cell setBackgroundColor: [[self class] _fusionedItemColor]];
                            //[cell setBordered: NO];
                            break;
                        }
                        else if( [displayedSeries containsObject: curSeries]) // Yellow
                        {
                            [cell setBackgroundColor: [[self class] _openItemColor]];
                            //[cell setBordered: NO];
                            break;
                        }
                    }
                }
                
                
            }
        }
        
        [previewMatrix sizeToCells];
        
        if( showSelected)
        {
            NSInteger index = [[[previewMatrix cells] valueForKeyPath:@"representedObject.object"] indexOfObject: [[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"series"]];
            
            if( index != NSNotFound)
                [previewMatrix scrollCellToVisibleAtRow: index column:0];
        }
        else
        {
            [[previewMatrixScrollView contentView] scrollToPoint: origin];
            [previewMatrixScrollView reflectScrolledClipView: [previewMatrixScrollView contentView]];
        }
        
        [previewMatrix setNeedsDisplay:YES];
    }
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        [comparativesButton setEnabled:hasComparatives];
        
        NSColor* color = [NSColor whiteColor];
        NSString* tip = @"";
        
        if( self.flagListPODComparatives.boolValue == NO)
        {
            comparativesButton.title = NSLocalizedString( @"Comparatives", nil);
            if (hasComparatives) {
                color = [[self class] _openItemColor]; // yellow
                tip = NSLocalizedString(@"There are PACS On-Demand comparatives", nil);
            }
            
            if (hasComparativesNewerThanMostRecentLoaded) {
                color = [[self class] _selectedItemColor]; // red
                tip = NSLocalizedString(@"There are more recent PACS On-Demand comparatives", nil);
            }
        }
        else
            comparativesButton.title = [NSString stringWithFormat: @"✓ %@", NSLocalizedString( @"Comparatives", nil)];
        
        if (hasComparatives)
        {
            if( tip.length)
                tip = [tip stringByAppendingString:@", "];
            
            if (self.flagListPODComparatives.boolValue)
                tip = [tip stringByAppendingString: NSLocalizedString( @"Click here to hide them", nil)];
            else
                tip = [tip stringByAppendingString: NSLocalizedString( @"Click here to show them", nil)];
        }
        NSMutableDictionary* attributes = [[[comparativesButton.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
        [attributes setObject:color forKey:NSForegroundColorAttributeName];
        [comparativesButton setAttributedTitle:[[[NSAttributedString alloc] initWithString:comparativesButton.title attributes:attributes] autorelease]];
        [comparativesButton setToolTip:tip];
        
        BOOL showComparativesButton = NO;
        
#ifndef OSIRIX_LIGHT
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"searchForComparativeStudiesOnDICOMNodes"] && !self.database.isReadOnly && self.database.isLocal) {
            NSArray* servers = [BrowserController comparativeServers];
            if (servers.count)
                showComparativesButton = YES;
        }
#endif
        
        //        [[leftSplitView.subviews objectAtIndex:0] setHidden:!showComparativesButton];
        //        [self splitView:leftSplitView resizeSubviewsWithOldSize:leftSplitView.bounds.size];
    }
    
    for( DCMView *v in self.imageViews)
        [v computeColor];
    
    [self buildSeriesPopup];
    
    needsToBuildSeriesMatrix = NO;
}

- (void) matrixPreviewSelectCurrentSeries
{
    [self showCurrentThumbnail: self];
}

- (void) showCurrentThumbnail:(id) sender;
{
    NSInteger index = [[[previewMatrix cells] valueForKeyPath:@"representedObject.object"] indexOfObject: [[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"series"]];
    
    if( index != NSNotFound)
        [previewMatrix scrollCellToVisibleAtRow: index column:0];
}

- (void) buildMatrixPreview
{
    [self buildMatrixPreview: YES];
}

- (void) updateRepresentedFileName
{
    NSString	*path = [[BrowserController currentBrowser] getLocalDCMPath:[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] : 0];
    [[self window] setRepresentedFilename: path];
}

- (BOOL)window:(NSWindow *)sender shouldPopUpDocumentPathMenu:(NSMenu *)titleMenu
{
    [self updateRepresentedFileName];
    
    return YES;
}

#ifndef OSIRIX_LIGHT
- (void) viewXML:(id) sender
{
    [self checkEverythingLoaded];
    
    NSString	*path = [[BrowserController currentBrowser] getLocalDCMPath:[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] : 0];
    [[self window] setRepresentedFilename: path];
    
    DicomImage *im = [fileList[curMovieIndex] objectAtIndex:[imageView curImage]];
    
    if( [XMLController windowForViewer: self])
        [[[XMLController windowForViewer: self] window] makeKeyAndOrderFront: self];
    else
    {
        XMLController * xmlController = [[XMLController alloc] initWithImage: im windowName:[NSString stringWithFormat: NSLocalizedString( @"Meta-Data: %@", nil), [[self window] title]] viewer: self];
        [[xmlController window] setAlphaValue: 0.01];
        
        [[AppController sharedAppController] tileWindows: nil];
        
        for( int i = 0; i < 15 ; i++)
        {
            [[xmlController window] setAlphaValue: (i+1.0) / 15.];
            [NSThread sleepForTimeInterval: 0.03];
        }
        
        [[self window] makeKeyAndOrderFront: self];
    }
}
#endif

#pragma mark-
#pragma mark 3. mouse management

static ViewerController *draggedController = nil;

- (void) completeDragOperation:(ViewerController*) vc
{
    // First reset all controls
    NSView* blendingTypeContent = [blendingTypeWindow contentView];
    for (NSView* view in [blendingTypeContent subviews])
    {
        if ([view isKindOfClass:[NSControl class]])
        {
            NSControl* control = (NSControl*) view;
            [control setEnabled:YES];
        }
    }
    
    int iz, xz;
    
    if( [[[vc imageView] curDCM] pwidth] != [[imageView curDCM] pwidth] ||
       [[[vc imageView] curDCM] pheight] != [[imageView curDCM] pheight])
    {
        [blendingTypeMultiply setEnabled: NO];
        [blendingTypeSubtract setEnabled: NO];
        [blendingTypeRGB setEnabled: NO];
    }
    
    if( [[[vc pixList] objectAtIndex: 0] isRGB])
        [blendingTypeRGB setEnabled: NO];
    
    if( [[self studyInstanceUID] isEqualToString: [vc studyInstanceUID]] == NO)
        [blendingResample setEnabled: NO];
    
    // Prepare fusion plug-ins menu
    for( iz = 0; iz < [[PluginManager fusionPluginsMenu] numberOfItems]; iz++)
    {
        [[[PluginManager fusionPluginsMenu] itemAtIndex:iz] setTag: -iz];
        
        if( [[[PluginManager fusionPluginsMenu] itemAtIndex:iz] hasSubmenu])
        {
            NSMenu  *subMenu = [[[PluginManager fusionPluginsMenu] itemAtIndex:iz] submenu];
            
            for( xz = 0; xz < [subMenu numberOfItems]; xz++)
            {
                [[subMenu itemAtIndex:xz] setTag: -iz];
                [[subMenu itemAtIndex:xz] setTarget:self];
                [[subMenu itemAtIndex:xz] setAction:@selector(endBlendingType:)];
            }
        }
        else
        {
            [[[PluginManager fusionPluginsMenu] itemAtIndex:iz] setTarget:self];
            [[[PluginManager fusionPluginsMenu] itemAtIndex:iz] setAction:@selector(endBlendingType:)];
        }
    }
    [blendingPlugins setMenu: [PluginManager fusionPluginsMenu]];
    
    [blendedWindow release];
    blendedWindow = [vc retain];
    
    // What type of blending?
    [NSApp beginSheet: blendingTypeWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(blendingSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    
    draggedController = nil;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard	*paste = [sender draggingPasteboard];
    long			i;
    
    if ([paste availableTypeFromArray:DCMView.PasteboardTypes])
    {
        DCMView	*vi = [sender draggingSource];
        
        if ([[[vi window] windowController] is2DViewer] == YES)
        {
            if ([[[[vi window] windowController] blendingController] isEqual:self])
                return NO;
            if( [[vi window] windowController] != self) [self completeDragOperation: [[vi window] windowController]];
        }
    }
	else if ([paste availableTypeFromArray:DCMView.PluginPasteboardTypes])
    {
        // in this case, the drag operation was performed from a plugin.
        id source = [sender draggingSource];
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        [userInfo setValue:self forKey:@"destination"]; // should not be used anymore, as [notification object] is the same (was NULL)
        [userInfo setValue:sender forKey:@"dragOperation"]; // should use key "NSDraggingInfo"
        [userInfo setValue:sender forKey:@"id<NSDraggingInfo>"];
        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixPerformDragOperationNotification object:self userInfo:userInfo];
        
        if ([source respondsToSelector:@selector(performPluginDragOperation:destination:)]) {
            return [source performPluginDragOperation:sender destination:self];
        }
    }
    else if ([paste availableTypeFromArray:BrowserController.DatabaseObjectXIDsPasteboardTypes])
    {
        NSArray* xids = [NSPropertyListSerialization propertyListFromData:[paste propertyListForType:[paste availableTypeFromArray:BrowserController.DatabaseObjectXIDsPasteboardTypes]]
                                                         mutabilityOption:NSPropertyListImmutable
                                                                   format:NULL
                                                         errorDescription:NULL];
        NSMutableArray* items = [NSMutableArray array];
        for (NSString* xid in xids)
            [items addObject:[BrowserController.currentBrowser.database objectWithID:[NSManagedObject UidForXid:xid]]];
        
        if( [[items lastObject] isKindOfClass: [DicomSeries class]])
        {
            [self.window makeKeyAndOrderFront: self];
            [self loadSelectedSeries: [items lastObject] rightClick: NO];
        }
    }
    else
    {
        NSArray			*types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
        NSString		*desiredType = [paste availableTypeFromArray:types];
        NSData			*carriedData = nil;
        
        if( desiredType) carriedData = [paste dataForType: desiredType];
        
        if (nil == carriedData)
        {
            //			//the operation failed for some reason
            //			NSRunAlertPanel(NSLocalizedString(@"Paste Error", nil), NSLocalizedString(@"Sorry, but the past operation failed", nil), nil, nil, nil);
            return NO;
        }
        else
        {
            //the pasteboard was able to give us some meaningful data
            if ([desiredType isEqualToString:NSFilenamesPboardType])
            {
                //we have a list of file names in an NSData object
                NSArray				*fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
                
                // Find a 2D viewer containing this specific file!
                
                NSArray				*winList = [NSApp windows];
                BOOL				found = NO;
                
                for( i = 0; i < [winList count] && found == NO; i++)
                {
                    if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
                    {
                        //						for( z = 0; z < [[[winList objectAtIndex:i] windowController] maxMovieIndex]; z++)
                        //						{
                        //							NSMutableArray  *pList = [[[winList objectAtIndex:i] windowController] pixList: z];
                        //
                        //							for( x = 0; x < [pList count]; x++)
                        //							{
                        //								if([[[pList objectAtIndex: x] sourceFile] isEqualToString: draggedFile])
                        //								{
                        if( found == NO)
                        {
                            if( [[winList objectAtIndex:i] windowController] == draggedController && draggedController != self)
                            {
                                [self completeDragOperation: [[winList objectAtIndex:i] windowController]];
                                found = YES;
                            }
                            else if( draggedController == self)
                            {
                                //											NSLog(@"Myself => Cancel fusion if previous one!");
                                [self ActivateBlending: nil];
                            }
                        }
                        //								}
                        //							}
                        //						}
                    }
                }
                
                if( found == NO)
                {
                    //Is it an image? -> Create a layer ROI
                    
                    for( NSString *file in fileArray)
                    {
                        if( [[file pathExtension] isEqualToString:@"roi"])
                        {
                            [imageView roiLoadFromFilesArray: [NSArray arrayWithObject: file]];
                        }
                        else if( [[file pathExtension] isEqualToString:@"rois_series"])
                        {
                            [self roiLoadFromSeries: file];
                        }
                        else
                        {
                            NSImage *im = [[NSImage alloc] initWithContentsOfFile: file];
                            if( im)
                            {
                                ROI* theNewROI = [self addLayerRoiToCurrentSliceWithImage: im referenceFilePath:@"none" layerPixelSpacingX:[[imageView curDCM] pixelSpacingX] layerPixelSpacingY:[[imageView curDCM] pixelSpacingY]];
                                
                                [theNewROI setName: [file lastPathComponent]];
                                [theNewROI setIsLayerOpacityConstant: YES];
                                [theNewROI setCanColorizeLayer: NO];
                                [theNewROI setCanResizeLayer: YES];
                                
                                NSRect r = {[NSEvent mouseLocation], NSZeroSize};
                                NSPoint eventLocation = [self.window convertRectFromScreen:r].origin;
                                eventLocation = [imageView convertPoint:eventLocation fromView:nil];
                                NSPoint imageLocation = [imageView ConvertFromNSView2GL:eventLocation];
                                
                                NSPoint centroid = [theNewROI centroid];
                                NSPoint offset;
                                
                                offset.x = imageLocation.x - centroid.x;
                                offset.y = imageLocation.y - centroid.y;
                                
                                NSArray *newROIPoints = [theNewROI points];
                                for ( MyPoint *p in newROIPoints)
                                    [p move:offset.x :offset.y];
                                
                                [im release];
                                
                                [self selectROI:theNewROI deselectingOther:YES];
                            }
                        }
                    }
                }
            }
            else
            {
                //this can't happen
                NSAssert(NO, @"This can't happen");
                return NO;
            }
        }
    }
    
    draggedController = nil;
    
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if( draggedController == nil)
    {
        draggedController = self;
        NSLog(@"catched");
    }
    
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they
        //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have
        //to tell them we aren't interested
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    NSLog(@"exited");
    
    //we aren't particularily interested in this so we will do nothing
    //this is one of the methods that we do not have to implement
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they
        //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have
        //to tell them we aren't interested
        return NSDragOperationNone;
    }
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    //we don't do anything in our implementation
    //this could be ommitted since NSDraggingDestination is an infomal
    //protocol and returns nothing
    NSLog(@"draggingEnded");
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    NSLog(@"prepareForDragOperation");
    return YES;
}

- (void) keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
    unichar c = [[event characters] characterAtIndex:0];
    
    if( c == 3 || c == 13 || c == ' ')
    {
        [self PlayStop:[self findPlayStopButton]];
    }
    else if((c >='1' && c <= '7') | (c >='a' && c <= 'g'))		// SHUTTLE PRO
    {
        if( !timer)  [self PlayStop:[self findPlayStopButton]];  // PLAY
        
        NSLog( @"%@", [event characters]);
        
        if( (c >='a' && c <= 'g')) {c -= 'a' -1;	direction = -1;}
        if( (c >='1' && c <= '7')) {c -= '1' -1;	direction = 1;}
        
        switch( c)
        {
            case 1:   [speedSlider setFloatValue:2];		break;
            case 2:   [speedSlider setFloatValue:5];		break;
            case 3:   [speedSlider setFloatValue:10];		break;
            case 4:   [speedSlider setFloatValue:15];		break;
            case 5:   [speedSlider setFloatValue:25];		break;
            case 6:   [speedSlider setFloatValue:30];		break;
            case 7:   [speedSlider setFloatValue:60];		break;
        }
        
        [self speedSliderAction:self];
    }
    else if( c == '0')
    {
        if( timer)
            [self PlayStop:[self findPlayStopButton]];  // STOP
    }
    
    else if (c == NSUpArrowFunctionKey)
    {
        if( maxMovieIndex > 1)
        {
            curMovieIndex --;
            if( curMovieIndex < 0) curMovieIndex = maxMovieIndex-1;
            
            [self setMovieIndex: curMovieIndex];
        }
        else [super keyDown:event];
    }
    else if(c ==  NSDownArrowFunctionKey)
    {
        if( maxMovieIndex > 1)
        {
            curMovieIndex ++;
            if( curMovieIndex >= maxMovieIndex) curMovieIndex = 0;
            
            [self setMovieIndex: curMovieIndex];
        }
        else [super keyDown:event];
    }
    else if (c == NSLeftArrowFunctionKey && ([event modifierFlags] & NSCommandKeyMask))
    {
        [[BrowserController currentBrowser] loadNextSeries:[fileList[0] objectAtIndex:0] : -1 :self :YES keyImagesOnly: displayOnlyKeyImages];
    }
    else if (c == NSRightArrowFunctionKey && ([event modifierFlags] & NSCommandKeyMask))
    {
        [[BrowserController currentBrowser] loadNextSeries:[fileList[0] objectAtIndex:0] : 1 :self :YES keyImagesOnly: displayOnlyKeyImages];
    }
    else
    {
        [super keyDown:event];
    }
}

- (float) highLighted
{
    return highLighted;
}

- (void) highLightTimerFunction:(NSTimer*)theTimer
{
    highLighted -= 0.05;
    for( DCMView * v in [seriesView imageViews])
        [v setNeedsDisplay: YES];
    
    if( highLighted <= 0.0)
    {
        [highLightedTimer invalidate];
        [highLightedTimer release];
        highLightedTimer = nil;
    }
}

- (void) setHighLighted: (float) b
{
    if( b != highLighted)
    {
        highLighted = b;
        
        for( DCMView * v in [seriesView imageViews])
            [v setNeedsDisplay: YES];
        
        if( b == 1.0)
        {
            [highLightedTimer invalidate];
            [highLightedTimer release];
            
            highLightedTimer = [[NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(highLightTimerFunction:) userInfo:0 repeats: YES] retain];
            [[NSRunLoop currentRunLoop] addTimer: highLightedTimer forMode:NSModalPanelRunLoopMode];
            [[NSRunLoop currentRunLoop] addTimer: highLightedTimer forMode:NSEventTrackingRunLoopMode];
        }
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [self mouseMoved];
}

- (void)mouseMoved
{
    if( ![[self window] isVisible] && ![self FullScreenON])
        return;
    
    if( windowWillClose) return;
    
    [self autoHideMatrix];
}

- (IBAction) setCurrentPosition:(id) sender
{
    if( [sender tag] == 0)
    {
        if( [imageView flippedData])
        {
            [dcmFrom setIntValue: [pixList[ curMovieIndex] count] - [imageView curImage]];
            [quicktimeFrom setIntValue:  [pixList[ curMovieIndex] count] - [imageView curImage]];
        }
        else
        {
            [dcmFrom setIntValue: [imageView curImage]+1];
            [quicktimeFrom setIntValue: [imageView curImage]+1];
        }
    }
    else
    {
        if( [imageView flippedData])
        {
            [dcmTo setIntValue:  [pixList[ curMovieIndex] count] - [imageView curImage]];
            [quicktimeTo setIntValue:  [pixList[ curMovieIndex] count] - [imageView curImage]];
        }
        else
        {
            [dcmTo setIntValue: [imageView curImage]+1];
            [quicktimeTo setIntValue: [imageView curImage]+1];
        }
    }
    
    [dcmFrom performClick: self];	// Will update the text field
    [dcmTo performClick: self];	// Will update the text field
    [dcmInterval performClick: self];	// Will update the text field
    [quicktimeFrom performClick: self];	// Will update the text field
    [quicktimeTo performClick: self];	// Will update the text field
    [quicktimeInterval performClick: self];	// Will update the text field
}

// functions s that plugins can also play with globals
+ (ViewerController *) draggedController
{
    return draggedController;
}

+ (void) setDraggedController:(ViewerController *) controller
{
    draggedController = controller;
}

#pragma mark-
#pragma mark 4. toolbox space

- (IBAction)customizeViewerToolBar:(id)sender
{
    [toolbar runCustomizationPalette:sender];
}

- (IBAction) switchCobbAngle:(id) sender
{
    [[NSUserDefaults standardUserDefaults] setBool: ![[NSUserDefaults standardUserDefaults] boolForKey: @"displayCobbAngle"] forKey: @"displayCobbAngle"];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTIFSELECTED"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"displayCobbAngle"] == YES)
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"ROITEXTIFSELECTED"]; // To display the Cobbs value -> show all ROIs information
}

#pragma mark - NSToolbarDelegate

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqualToString: QTSaveToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Movie Export", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Movie file", nil)];
        [toolbarItem setImage: [NSImage imageNamed: QTSaveToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(exportQuicktime:)];
    }
    else if ([itemIdent isEqualToString: PrintToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Print",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Print",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Print selected study/series to a DICOM printer",nil)];
        [toolbarItem setImage: [NSImage imageNamed: PrintToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(printDICOM:)];
    }
    else  if ([itemIdent isEqualToString: PhotosToolbarItemIdentifier]) {
        
        [toolbarItem setLabel:NSLocalizedString(@"Photos", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Photos", nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Export this image to Photos", nil)];
        [toolbarItem setImage:[NSImage imageNamed:@"Photos"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(export2iPhoto:)];
    }
    else if ([itemIdent isEqualToString: MailToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Email", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Email", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image", nil)];
        [toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(sendMail:)];
    }
    //	else if ([itemIdent isEqual: BrushToolsToolbarItemIdentifier])
    //	{
    //		[toolbarItem setLabel: @"BrushTool"];
    //		[toolbarItem setPaletteLabel: @"BrushTool"];
    //        [toolbarItem setToolTip: @"Brush Palette for plain ROI"];
    //		[toolbarItem setImage: [NSImage imageNamed: BrushToolsToolbarItemIdentifier]];
    //		[toolbarItem setTarget: self];
    //		[toolbarItem setAction: @selector(brushTool:)];
    //    }
    else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"DICOM File", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Export as DICOM File", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this image/series in a DICOM file", nil)];
        [toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(exportDICOMFile:)];
    }
    else if ([itemIdent isEqualToString: Send2PACSToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Send", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Send", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Send this series to a DICOM node", nil)];
        [toolbarItem setImage: [NSImage imageNamed: Send2PACSToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(export2PACS:)];
    }
    else if ([itemIdent isEqualToString: XMLToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Meta-Data", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Meta-Data", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"View meta-data of this image", nil)];
        [toolbarItem setImage: [NSImage imageNamed: XMLToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(viewXML:)];
    }
    else if ([itemIdent isEqualToString: PlayToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Browse", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Browse", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Browse this series", nil)];
        [toolbarItem setImage: [NSImage imageNamed: PlayToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(PlayStop:)];
    }
    else if ([itemIdent isEqualToString: SyncSeriesToolbarItemIdentifier]) {
        
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(SyncSeries:)];
        [toolbarItem setToolTip: NSLocalizedString(@"Syncronize slice position", nil)];
        if( SYNCSERIES)
        {
            [toolbarItem setLabel: NSLocalizedString(@"Sync", nil)];
            [toolbarItem setPaletteLabel: NSLocalizedString(@"Sync", nil)];
            [toolbarItem setImage: [NSImage imageNamed: @"SyncLock.pdf"]];
        }
        else
        {
            [toolbarItem setLabel: NSLocalizedString(@"Sync", nil)];
            [toolbarItem setPaletteLabel: NSLocalizedString(@"Sync", nil)];
            [toolbarItem setImage: [NSImage imageNamed: SyncSeriesToolbarItemIdentifier]];
        }
    }
    else if ([itemIdent isEqualToString: ResetToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Reset", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Reset", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Reset image to original view", nil)];
        [toolbarItem setImage: [NSImage imageNamed: ResetToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(resetImage:)];
    }
    else if ([itemIdent isEqualToString: RevertToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Revert", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Revert", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Revert series by re-loading images from disk", nil)];
        [toolbarItem setImage: [NSImage imageNamed: RevertToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(revertSeries:)];
    }
    else if ([itemIdent isEqualToString: FlipDataToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Flip", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Flip", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Flip series", nil)];
        [toolbarItem setImage: [NSImage imageNamed: FlipDataToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(flipDataSeries:)];
    }
    else if ([itemIdent isEqualToString: DatabaseWindowToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Database", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Database", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Close viewers and open Database window", nil)];
        [toolbarItem setImage: [NSImage imageNamed: DatabaseWindowToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(databaseWindow:)];
    }
    else if( [itemIdent isEqualToString: ROIManagerToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"ROI Manager", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"ROI Manager", nil)];
        [toolbarItem setImage: [NSImage imageNamed: ROIManagerToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(roiGetManager:)];
    }
    else if( [itemIdent isEqualToString: SUVToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"SUV", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"SUV", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Display SUVbw values", nil)];
        [toolbarItem setImage: [NSImage imageNamed: SUVToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(displaySUV:)];
    }
    
    else if ( [itemIdent isEqualToString: ReportToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Report", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Report", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Create/Open a report for selected study", nil)];
        [self setToolbarReportIconForItem:toolbarItem];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(generateReport:)];
    }
    
    else if ([itemIdent isEqualToString: TileWindowsToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Tile", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Tile", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Tile Windows", nil)];
        [toolbarItem setImage: [NSImage imageNamed: TileWindowsToolbarItemIdentifier]];
        [toolbarItem setTarget: [AppController sharedAppController]];
        [toolbarItem setAction: @selector(tileWindows:)];
    }
    //	else if ([itemIdent isEqualToString: iChatBroadCastToolbarItemIdentifier]) {
    //
    //	[toolbarItem setLabel: NSLocalizedString(@"iChat", nil)];
    //	[toolbarItem setPaletteLabel: NSLocalizedString(@"iChat", nil)];
    //	[toolbarItem setToolTip: NSLocalizedString(@"iChat", nil)];
    ////	[toolbarItem setImage: [NSImage imageNamed: iChatBroadCastToolbarItemIdentifier]]; //	/Applications/iChat/Contents/Resources/Prefs_Camera.icns is maybe a better image...
    //	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.iChat"];
    //	[toolbarItem setImage: [[NSWorkspace sharedWorkspace] iconForFile:path]];
    ////	[toolbarItem setImage: [NSImage imageNamed:NSImageNameIChatTheaterTemplate]];
    //	[toolbarItem setTarget: self];
    //	[toolbarItem setAction: @selector(iChatBroadcast:)];
    //    }
    else if([itemIdent isEqualToString: SpeedToolbarItemIdentifier]) {
        //	NSMenu *submenu = nil;
        //	NSMenuItem *submenuItem = nil, *menuFormRep = nil;
        
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Rate", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Rate", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Change the frame rate speed", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: speedView];
        [toolbarItem setMinSize:NSMakeSize(100, NSHeight([speedView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(200,NSHeight([speedView frame]))];
        
        // By default, in text only mode, a custom items label will be shown as disabled text, but you can provide a
        // custom menu of your own by using <item> setMenuFormRepresentation]
        /*submenu = [[[NSMenu alloc] init] autorelease];
         submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel" action: @selector(searchUsingSearchPanel:) keyEquivalent: @""] autorelease];
         menuFormRep = [[[NSMenuItem alloc] init] autorelease];
         
         [submenu addItem: submenuItem];
         [submenuItem setTarget: self];
         [menuFormRep setSubmenu: submenu];
         [menuFormRep setTitle: [toolbarItem label]];
         [toolbarItem setMenuFormRepresentation: menuFormRep];*/
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
    else if([itemIdent isEqualToString: SerieToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Series", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Series", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Next/Previous Series", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: serieView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([serieView frame]), NSHeight([serieView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([serieView frame]),NSHeight([serieView frame]))];
    }
    else if([itemIdent isEqualToString: PatientToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Patient", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Patient", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Next/Previous Patient", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: patientView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([patientView frame]), NSHeight([patientView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([patientView frame]), NSHeight([patientView frame]))];
    }
    else if([itemIdent isEqualToString: SubtractionToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Subtraction", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Subtraction", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Subtraction module", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: subCtrlView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([subCtrlView frame]), NSHeight([subCtrlView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([subCtrlView frame]),NSHeight([subCtrlView frame]))];
    }
    else if([itemIdent isEqualToString: WLWWToolbarItemIdentifier]) {
        //	NSMenu *submenu = nil;
        //	NSMenuItem *submenuItem = nil, *menuFormRep = nil;
        
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"WL/WW & CLUT", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"WL/WW & CLUT", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Modify WL/WW & CLUT", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: WLWWView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([WLWWView frame]), NSHeight([WLWWView frame]))];
        
        // Pulldown that doesnt change item
        //        [[wlwwPopup cell] setBezelStyle:NSSmallIconButtonBezelStyle];
        //        [[wlwwPopup cell] setArrowPosition:NSPopUpArrowAtBottom];
        
        [[wlwwPopup cell] setUsesItemFromMenu:YES];
        //        [wlwwPopup setMenu: presetsViewMenu];
        //        [wlwwPopup setPreferredEdge:NSMinXEdge];
        //        [[[wlwwPopup menu] menuRepresentation] setHorizontalEdgePadding:0.0];
    }
    else if([itemIdent isEqualToString: FilterToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Convolution Filters", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Convolution Filters", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Apply a convolution filter", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: ConvView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([ConvView frame]), NSHeight([ConvView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([ConvView frame]), NSHeight([ConvView frame]))];
        
        [[convPopup cell] setUsesItemFromMenu:YES];
        //	[convPopup setMenu: convViewMenu];
        //        [wlwwPopup setPreferredEdge:NSMinXEdge];
        //        [[[wlwwPopup menu] menuRepresentation] setHorizontalEdgePadding:0.0];
        
    }
    else if([itemIdent isEqualToString: FusionToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Thick Slab", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Thick Slab", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Change Thick Slab mode and number", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: FusionView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([FusionView frame]), NSHeight([FusionView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([FusionView frame]) + 200, NSHeight([FusionView frame]))];
    }
    else if([itemIdent isEqualToString: StatusToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Status & Comments", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Status & Comments", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: StatusView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([StatusView frame]), NSHeight([FusionView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([StatusView frame]), NSHeight([FusionView frame]))];
    }
    else if([itemIdent isEqualToString: BlendingToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Fusion", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Fusion", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Fusion Mode and Percentage", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: BlendingView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([BlendingView frame]), NSHeight([BlendingView frame]))];
    }
    else if([itemIdent isEqualToString: RGBFactorToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"RGB Factors", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"RGB Factors", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: RGBFactorsView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([RGBFactorsView frame]), NSHeight([RGBFactorsView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([RGBFactorsView frame]), NSHeight([RGBFactorsView frame]))];
    }
    else if([itemIdent isEqualToString: OrientationToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Orientation", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Orientation", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: orientationView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([orientationView frame]), NSHeight([orientationView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([orientationView frame]), NSHeight([orientationView frame]))];
    }
    else if([itemIdent isEqualToString: SeriesPopupToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Series", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Series Selection", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Series Selection", nil)];
        
        [toolbarItem setView: seriesPopupView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([seriesPopupView frame]), NSHeight([seriesPopupView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([seriesPopupView frame]), NSHeight([seriesPopupView frame]))];
    }
    else if([itemIdent isEqualToString: WindowsTilingToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Windows", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Windows Tiling", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Windows Tiling", nil)];
        
        [toolbarItem setView: windowsTiling];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([windowsTiling frame]), NSHeight([windowsTiling frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([windowsTiling frame]), NSHeight([windowsTiling frame]))];
    }
    else if([itemIdent isEqualToString: AnnotationsToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Annotations", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Annotations", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: annotations];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([annotations frame]), NSHeight([annotations frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([annotations frame]), NSHeight([annotations frame]))];
    }
    else if([itemIdent isEqualToString: ShutterToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Shutter", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Shutter", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: shutterView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([shutterView frame]), NSHeight([shutterView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([shutterView frame]), NSHeight([shutterView frame]))];
    }
    else if([itemIdent isEqualToString: PropagateSettingsToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Propagate", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Propagate", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Propagate settings (WL/WW, zoom, ...)", nil)];
        
        [toolbarItem setView: propagateSettingsView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([propagateSettingsView frame]), NSHeight([propagateSettingsView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([propagateSettingsView frame]), NSHeight([propagateSettingsView frame]))];
    }
    else if([itemIdent isEqualToString: ReconstructionToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"2D/3D", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"2D/3D", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"2D/3D Reconstruction Tools", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: ReconstructionView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([ReconstructionView frame]), NSHeight([ReconstructionView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([ReconstructionView frame]), NSHeight([ReconstructionView frame]))];
    }
    else if([itemIdent isEqualToString: KeyImagesToolbarItemIdentifier])
    {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Key Images", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Key Images", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: keyImages];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([keyImages frame]), NSHeight([keyImages frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([keyImages frame]), NSHeight([keyImages frame]))];
    }
    else if([itemIdent isEqualToString: ToolsToolbarItemIdentifier]) {
        // Set up the standard properties
        [toolbarItem setLabel: NSLocalizedString(@"Mouse button function", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Mouse button function", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Change the mouse button function", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: toolsView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([toolsView frame]), NSHeight([toolsView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([toolsView frame]),NSHeight([toolsView frame]))];
        
    }
    else if ([itemIdent isEqualToString: FlipVerticalToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Flip Vertical", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Flip Vertical", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Flip image vertically", nil)];
        [toolbarItem setImage: [NSImage imageNamed: FlipVerticalToolbarItemIdentifier]];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(flipVertical:)];
    }
    else if ([itemIdent isEqualToString: SetPixelValueItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Set Pixels", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Set Pixels", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Set Pixels Values to...", nil)];
        [toolbarItem setImage: [NSImage imageNamed: SetPixelValueItemIdentifier]];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(roiSetPixelsSetup:)];
    }
    else if ([itemIdent isEqualToString: GrowingRegionItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Growing", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Growing", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Growing Region", nil)];
        [toolbarItem setImage: [NSImage imageNamed: GrowingRegionItemIdentifier]];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(segmentationTest:)];
    }
   	else if ([itemIdent isEqualToString: VRPanelToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"3D Panel", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"3D Panel", nil)];
        [toolbarItem setImage: [NSImage imageNamed: VRPanelToolbarItemIdentifier]];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(Panel3D:)];
    }
    else if ([itemIdent isEqualToString: FlipHorizontalToolbarItemIdentifier]) {
        
        [toolbarItem setLabel: NSLocalizedString(@"Flip Horizontal", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Flip Horizontal", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Flip image horizontallly", nil)];
        [toolbarItem setImage: [NSImage imageNamed: FlipHorizontalToolbarItemIdentifier]];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(flipHorizontal:)];
    }
    else if([itemIdent isEqualToString: LUT12BitToolbarItemIdentifier] && [AppController canDisplay12Bit])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Display", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Display type", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Display type", nil)];
        
        [toolbarItem setView: display12bitToolbarItemView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([display12bitToolbarItemView frame]), NSHeight([display12bitToolbarItemView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([display12bitToolbarItemView frame]),NSHeight([display12bitToolbarItemView frame]))];
    }
    else if([itemIdent isEqualToString: CobbAngleToolbarItemIdentifier])
    {
        [toolbarItem setLabel:NSLocalizedString(@"Cobb", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Cobb", nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Cobb's Angle", nil)];
        [toolbarItem setImage:[NSImage imageNamed:@"CobbAngle.tif"]];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction:@selector(switchCobbAngle:)];
    }
    else if([itemIdent isEqualToString:ThreeDPositionToolbarItemIdentifier])
    {
        [toolbarItem setLabel:NSLocalizedString(@"3D Pos", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"3D Pos", nil)];
        [toolbarItem setImage:[NSImage imageNamed:@"OrientationWidget.tif"]];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(threeDPanel:)];
    }
    else if([itemIdent isEqualToString:NavigatorToolbarItemIdentifier])
    {
        [toolbarItem setLabel:NSLocalizedString(@"Navigator", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Navigator", nil)];
        [toolbarItem setImage:[NSImage imageNamed:NavigatorToolbarItemIdentifier]];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(navigator:)];
    }
    else
    {
        // Is it a plugin menu item?
        if( [[PluginManager pluginsDict] objectForKey: itemIdent] != nil)
        {
            NSBundle *bundle = [[PluginManager pluginsDict] objectForKey: itemIdent];
            NSDictionary *info = [bundle infoDictionary];
            
            [toolbarItem setLabel: itemIdent];
            [toolbarItem setPaletteLabel: itemIdent];
            NSDictionary* toolTips = [info objectForKey: @"ToolbarToolTips"];
            if( toolTips)
                [toolbarItem setToolTip: [toolTips objectForKey: itemIdent]];
            else
                [toolbarItem setToolTip: itemIdent];
            
            NSImage	*image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:[info objectForKey:@"ToolbarIcon"]]] autorelease];
            if( !image) image = [[NSWorkspace sharedWorkspace] iconForFile: [bundle bundlePath]];
            [toolbarItem setImage: image];
            
            [toolbarItem setTarget: self];
            [toolbarItem setAction: @selector(executeFilterFromToolbar:)];
        }
        else
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
    
    //    [toolbarItem setMinSize: NSMakeSize( toolbarItem.minSize.width, 53)];
    //    [toolbarItem setMaxSize: NSMakeSize( toolbarItem.maxSize.width, 53)];
    //
    //    [toolbarItem.view setFrameSize: NSMakeSize( toolbarItem.view.frame.size.width, 53)];
    
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used
    return [NSArray arrayWithObjects:	DatabaseWindowToolbarItemIdentifier,
            WindowsTilingToolbarItemIdentifier,
            SeriesPopupToolbarItemIdentifier,
            AnnotationsToolbarItemIdentifier,
            PatientToolbarItemIdentifier,
            ToolsToolbarItemIdentifier,
            WLWWToolbarItemIdentifier,
            ReconstructionToolbarItemIdentifier,
            OrientationToolbarItemIdentifier,
            FusionToolbarItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            QTSaveToolbarItemIdentifier,
            SyncSeriesToolbarItemIdentifier,
            PropagateSettingsToolbarItemIdentifier,
            PlayToolbarItemIdentifier,
            SpeedToolbarItemIdentifier,
            VRPanelToolbarItemIdentifier,
            XMLToolbarItemIdentifier,
            nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray *array = [NSMutableArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
                             NSToolbarFlexibleSpaceItemIdentifier,
                             NSToolbarSpaceItemIdentifier,
                             NSToolbarSeparatorItemIdentifier,
                             MailToolbarItemIdentifier,
                             Send2PACSToolbarItemIdentifier,
                             PrintToolbarItemIdentifier,
                             ExportToolbarItemIdentifier,
                             PhotosToolbarItemIdentifier,
                             QTSaveToolbarItemIdentifier,
                             XMLToolbarItemIdentifier,
                             ReconstructionToolbarItemIdentifier,
                             BlendingToolbarItemIdentifier,
                             SyncSeriesToolbarItemIdentifier,
                             PropagateSettingsToolbarItemIdentifier,
                             ResetToolbarItemIdentifier,
                             RevertToolbarItemIdentifier,
                             SUVToolbarItemIdentifier,
                             ROIManagerToolbarItemIdentifier,
                             FlipDataToolbarItemIdentifier,
                             DatabaseWindowToolbarItemIdentifier,
                             TileWindowsToolbarItemIdentifier,
                             WindowsTilingToolbarItemIdentifier,
                             SeriesPopupToolbarItemIdentifier,
                             AnnotationsToolbarItemIdentifier,
                             PlayToolbarItemIdentifier,
                             SpeedToolbarItemIdentifier,
                             MovieToolbarItemIdentifier,
                             SerieToolbarItemIdentifier,
                             PatientToolbarItemIdentifier,
                             WLWWToolbarItemIdentifier,
                             FusionToolbarItemIdentifier,
                             SubtractionToolbarItemIdentifier,
                             ShutterToolbarItemIdentifier,
                             OrientationToolbarItemIdentifier,
                             RGBFactorToolbarItemIdentifier,
                             FilterToolbarItemIdentifier,
                             ToolsToolbarItemIdentifier,
                             //														iChatBroadCastToolbarItemIdentifier,
                             StatusToolbarItemIdentifier,
                             KeyImagesToolbarItemIdentifier,
                             ReportToolbarItemIdentifier,
                             FlipVerticalToolbarItemIdentifier,
                             FlipHorizontalToolbarItemIdentifier,
                             VRPanelToolbarItemIdentifier,
                             NavigatorToolbarItemIdentifier,
                             ThreeDPositionToolbarItemIdentifier,
                             CobbAngleToolbarItemIdentifier,
                             GrowingRegionItemIdentifier,
                             SetPixelValueItemIdentifier,
                             nil];
    
    if([AppController canDisplay12Bit]) [array addObject: LUT12BitToolbarItemIdentifier];
    
    NSArray*		allPlugins = [[PluginManager pluginsDict] allKeys];
    NSMutableSet*	pluginsItems = [NSMutableSet setWithCapacity: [allPlugins count]];
    
    for( NSString* plugin in allPlugins)
    {
        if ([plugin isEqualToString: @"(-"])
            continue;
        
        NSBundle		*bundle = [[PluginManager pluginsDict] objectForKey: plugin];
        NSDictionary	*info = [bundle infoDictionary];
        NSString		*pluginType = [info objectForKey: @"pluginType"];
        
        if( [pluginType isEqualToString: @"imageFilter"] ||
           [pluginType isEqualToString: @"roiTool"] ||
           [pluginType isEqualToString: @"other"])
        {
            id allowToolbarIcon = [info objectForKey: @"allowToolbarIcon"];
            
            if( allowToolbarIcon)
            {
                if( [allowToolbarIcon boolValue] == YES)
                {
                    NSArray* toolbarNames = [info objectForKey: @"ToolbarNames"];
                    if( toolbarNames)
                    {
                        if( [toolbarNames containsObject: plugin])
                            [pluginsItems addObject: plugin];
                    }
                    else
                        [pluginsItems addObject: plugin];
                }
            }
        }
    }
    
    if( [pluginsItems count])
        [array addObjectsFromArray: [pluginsItems allObjects]];
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarAllowedIdentifiersForViewer:)])
            [array addObjectsFromArray: [[[PluginManager plugins] objectForKey:key] toolbarAllowedIdentifiersForViewer: self]];
    }
    
    return array;
}

- (NSToolbar*) toolbar
{
    return toolbar;
}

- (void) toolbarWillAddItem: (NSNotification *) notif
{
    // To avoid a bug related to the 'separated toolbar window' :  we need to retain each toolbar item. We release them in the dealloc function
    NSToolbarItem *item = [[notif userInfo] objectForKey: @"item"];
    if( [retainedToolbarItems containsObject: item] == NO) [retainedToolbarItems addObject: item];
}

- (void) toolbarDidRemoveItem: (NSNotification *) notif
{
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
#ifdef EXPORTTOOLBARITEM
    return YES;
#endif
    
    if( [[fileList[ 0] lastObject] isKindOfClass:[NSManagedObject class]] == NO)
        return NO;
    
    if ([self.database isReadOnly])
        if ([toolbarItem.itemIdentifier isEqualToString:ReportToolbarItemIdentifier])
            return NO;
    
    BOOL enable = YES;
    
    if ([[toolbarItem itemIdentifier] isEqualToString: PlayToolbarItemIdentifier])
    {
        if([fileList[ curMovieIndex] count] == 1 && [[[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] <=  1) enable = NO;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: SyncSeriesToolbarItemIdentifier])
    {
        if(numberOf2DViewer <= 1) enable = NO;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: SpeedToolbarItemIdentifier])
    {
        if([fileList[ curMovieIndex] count] == 1 && [[[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] <=  1) enable = NO;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: MovieToolbarItemIdentifier])
    {
        if(maxMovieIndex == 1) enable = NO;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: QTSaveToolbarItemIdentifier])
    {
        if([fileList[ curMovieIndex] count] == 1 && [[[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] <=  1 && maxMovieIndex == 1 && blendingController == nil) enable = NO;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: ReconstructionToolbarItemIdentifier])
    {
        if([fileList[ curMovieIndex] count] == 1 && [[[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] <=  1) enable = NO;
    }
    
    //	if ([[toolbarItem itemIdentifier] isEqualToString: iChatBroadCastToolbarItemIdentifier])
    //	{
    //		enable = YES;
    //	}
    
    if([[toolbarItem itemIdentifier] isEqualToString: SUVToolbarItemIdentifier])
    {
        enable = [[imageView curDCM] hasSUV];
    }
    
    if([[toolbarItem itemIdentifier] isEqualToString: LUT12BitToolbarItemIdentifier])
        enable = [AppController canDisplay12Bit];
    
    return enable;
}

-(void) setDefaultToolMenu:(id) sender
{
    if( [sender tag] >= 0)
    {
        [toolsMatrix selectCellWithTag:[sender tag]];
        [imageView setCurrentTool: [sender tag]];
    }
}

- (NSMatrix*) buttonToolMatrix {return buttonToolMatrix;}

-(void) defaultToolModified: (NSNotification*) note
{
    id sender = [note object];
    NSInteger tag;
    
    if( sender)
    {
        if ([sender isKindOfClass:[NSMatrix class]])
        {
            NSButtonCell *theCell = [sender selectedCell];
            tag = [theCell tag];
        }
        else
        {
            tag = [sender tag];
        }
    }
    else tag = [[[note userInfo] valueForKey:@"toolIndex"] intValue];
    
    switch( (ToolMode)tag)
    {
        case tMesure:
        case tAngle:
        case tROI:
        case tOval:
        case tText:
        case tArrow:
        case tOPolygon:
        case tCPolygon:
        case tPencil:
        case t2DPoint:
        case tPlain:
        case tRepulsor:
        case tROISelector:
        case tDynAngle:
        case tAxis:
        case tTAGT:
            [self setROIToolTag: (ToolMode)tag];
            break;
            
        default:
            [toolsMatrix selectCellWithTag: (ToolMode)tag];
            break;
    }
    
    if( tag >= 0)
    {
        [imageView setCurrentTool: (ToolMode)tag];
    }
}

-(void) defaultRightToolModified: (NSNotification*) note
{
    id sender = [note object];
    int tag;
    
    if ([sender isKindOfClass:[NSMatrix class]])
    {
        NSButtonCell *theCell = [sender selectedCell];
        tag = [theCell tag];
    }
    else
    {
        tag = [sender tag];
    }
    
    [toolsMatrix selectCellWithTag: tag];
    
    if( tag >= 0) [imageView setRightTool: tag];
}

- (IBAction) setButtonTool:(id) sender
{
    if( [[sender selectedCell] tag] == 0)
    {
        [[toolsMatrix cellAtRow:0 column: 5] setEnabled:YES];
        [popupRoi setEnabled:YES];
        [toolsMatrix selectCellWithTag:[imageView currentTool]];
    }
    else
    {
        [[toolsMatrix cellAtRow:0 column: 5] setEnabled:NO];
        [popupRoi setEnabled:NO];
        [toolsMatrix selectCellWithTag:[imageView currentToolRight]];
    }
}

-(void) setDefaultTool:(id) sender
{
    [imageView gClickCountSetReset];
    
    int ctag = 0;
    
    if ([sender isKindOfClass:[NSMatrix class]])
        ctag = [[sender selectedCell] tag];
    else
        ctag = [sender tag];
    
    if( [[buttonToolMatrix selectedCell] tag] == 0)
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDefaultToolModifiedNotification object:sender userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @(ctag), @"toolIndex", nil]];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDefaultRightToolModifiedNotification object:sender userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @(ctag), @"toolIndex", nil]];
}

- (void) setShutterOnOffButton:(NSNumber*) b
{
    [shutterOnOff setState: [b boolValue]];
}

- (IBAction) shutterOnOff:(id) sender
{
    //	{
    //	int i;
    //	NSArray	*rois = [self selectedROIs];
    //
    //	for( i = 0; i < 200; i++)
    //	{
    //		ROI	*c = [self roiMorphingBetween: [rois objectAtIndex: 0] and: [rois objectAtIndex: 1] ratio: (float) (i+1) / 201.];
    //
    //		if( c)
    //		{
    //			[imageView roiSet: c];
    //			[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] addObject: c];
    //		}
    //
    //		[imageView display];
    //
    //		[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] removeObject: c];
    //	}
    //	[imageView display];
    //	return;
    //	}
    
    if ([[sender title] isEqualToString:@"Shutter"])
        [shutterOnOff setState: (![shutterOnOff state])]; //from menu
    
    DCMPix *curPix = [[imageView dcmPixList] objectAtIndex:[imageView curImage]];
    
    NSRect shutterRect = NSMakeRect( 0, 0, 0, 0);
    
    if ([shutterOnOff state] == NSOnState)
    {
        // Find the first ROI selected for the current frame and copy the rectangle in shutterRect
        ROI *selectedROI = nil;
        for( ROI *r in [roiList[curMovieIndex] objectAtIndex: [imageView curImage]])
        {
            if( r.ROImode == ROI_selected || r.ROImode == ROI_selectedModify || r.ROImode == ROI_drawing)
            {
                shutterRect = [r rect];
                selectedROI = r;
                break;
            }
        }
        
        //using valid shutterRect
        if( selectedROI != 0 && shutterRect.size.width > 0)
        {
            [self deleteROI: selectedROI];
            
            for( DCMPix *p in [imageView dcmPixList])
            {
                //shutterRect inside frame?
                if (shutterRect.origin.x < 0) { shutterRect.size.width += shutterRect.origin.x; shutterRect.origin.x = 0;}
                if (shutterRect.origin.y < 0) { shutterRect.size.height += shutterRect.origin.y; shutterRect.origin.x = 0;}
                if (shutterRect.origin.x + shutterRect.size.width > p.pwidth) shutterRect.size.width = p.pwidth - shutterRect.origin.x;
                if (shutterRect.origin.y + shutterRect.size.height > p.pheight) shutterRect.size.height = p.pheight - shutterRect.origin.y;
                
                p.shutterRect = shutterRect;
                p.shutterEnabled = NSOnState;
            }
        }
        else
        {
            //using stored shutterRect?
            if( (curPix.shutterRect.size.width == 0 || (curPix.shutterRect.size.width == [curPix pwidth] && curPix.shutterRect.size.height == [curPix pheight])) && curPix.shutterPolygonal == nil)
            {
                [shutterOnOff setState:NSOffState];
                
                NSRunCriticalAlertPanel(NSLocalizedString(@"Shutter", nil), NSLocalizedString(@"Please first define a rectangle with a rectangular ROI.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            }
            else //reuse preconfigured shutterRect
            {
                for( DCMPix *p in [imageView dcmPixList]) p.shutterEnabled = NSOnState;
            }
        }
    }
    else
    {
        for( DCMPix *p in [imageView dcmPixList]) p.shutterEnabled = NSOffState;
    }
    [imageView setIndex: [imageView curImage]]; //refresh viewer only
}

- (IBAction) resetCLUT:(id) sender
{
    if( NSRunInformationalAlertPanel( NSLocalizedString(@"Reset CLUT List", nil), NSLocalizedString(@"Are you sure you want to reset the entire CLUT list to the default list?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"CLUT"];
        [[NSUserDefaults standardUserDefaults] setObject: [[DefaultsOsiriX getDefaults] objectForKey: @"CLUT"] forKey: @"CLUT"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: [NSDictionary dictionary]];
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


- (IBAction) AddCLUT:(id) sender
{
    [self clutAction:self];
    [clutName setStringValue: NSLocalizedString(@"Unnamed", nil)];
    
    [NSApp beginSheet: addCLUTWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


-(void) UpdateCLUTMenu: (NSNotification*) note
{
    if( clutPresetsMenu == nil || [note userInfo] != nil)
    {
        //*** Build the menu
        short       i;
        NSArray     *keys;
        NSArray     *sortedKeys;
        
        // Presets VIEWER Menu
        
        keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
        sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        [clutPresetsMenu release];
        clutPresetsMenu = [[NSMenu alloc] init];
        
        [clutPresetsMenu addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:nil keyEquivalent:@""];
        [clutPresetsMenu addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:@selector (ApplyCLUT:) keyEquivalent:@""];
        [clutPresetsMenu addItem: [NSMenuItem separatorItem]];
        
        for( i = 0; i < [sortedKeys count]; i++)
        {
            [clutPresetsMenu addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
        }
        [clutPresetsMenu addItem: [NSMenuItem separatorItem]];
        [clutPresetsMenu addItemWithTitle: NSLocalizedString(@"8-bit CLUT Editor", nil) action:@selector (AddCLUT:) keyEquivalent:@""];
        [clutPresetsMenu addItem: [NSMenuItem separatorItem]];
        [clutPresetsMenu addItemWithTitle: NSLocalizedString(@"Reset CLUT List", nil) action:@selector (resetCLUT:) keyEquivalent:@""];
        
        [clutPopup setTitle: curCLUTMenu];
        [clutPopup setMenu: [[clutPresetsMenu copy] autorelease]];
        clutPopupSet = YES;
    }
    else if( clutPopupSet == NO)
    {
        [clutPopup setMenu: [[clutPresetsMenu copy] autorelease]];
        clutPopupSet = YES;
    }
    
    [clutPopup setTitle: curCLUTMenu];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window
    toolbar = [[OsiriXToolbar alloc] initWithIdentifier: ViewerToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setShowsBaselineSeparator: NO];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    if( [AppController USETOOLBARPANEL] == NO && [[NSUserDefaults standardUserDefaults] boolForKey: @"USEALWAYSTOOLBARPANEL2"] == NO)
    {
        [[self window] setToolbar: toolbar];
        [[self window] setShowsToolbarButton:NO];
        [[[self window] toolbar] setVisible: YES];
    }
    
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

#pragma mark-
#pragma mark 4.1. single viewport

- (BOOL) isDataVolumic
{
    return [self isDataVolumicIn4D: NO checkEverythingLoaded: YES tryToCorrect: YES];
}

- (BOOL) isDataVolumicIn4D: (BOOL) check4D checkEverythingLoaded:(BOOL) c;
{
    return [self isDataVolumicIn4D: NO checkEverythingLoaded: YES tryToCorrect: YES];
}

- (BOOL) isDataVolumicIn4D: (BOOL) check4D checkEverythingLoaded:(BOOL) c tryToCorrect: (BOOL) tryToCorrect
{
    BOOL volumicData = YES;
    BOOL firstImage = NO, lastImage = NO;
    
    if( c == NO)
    {
        @synchronized( loadingThread)
        {
            if( loadingThread)
            {
                if( (!loadingThread.isExecuting) == NO)
                    return NO;
            }
        }
    }
    
    [self checkEverythingLoaded];
    
    isDataVolumicIn4DLevel++;
    
    @try
    {
        for( int x = 0 ; x < maxMovieIndex ; x++)
        {
            if( check4D == YES || x == curMovieIndex)
            {
                if( [pixList[ x] count] > 4)
                {
                    float orientation[ 9];
                    
                    [[pixList[ x] objectAtIndex: 1] orientation: orientation];
                    
                    int pw = [[[fileList[ x] objectAtIndex: [pixList[ x] count]/2] valueForKey: @"width"] intValue];
                    int ph = [[[fileList[ x] objectAtIndex: [pixList[ x] count]/2] valueForKey: @"height"] intValue];
                    int firstWrongImage = -1;
                    int numberOfNonVolumicImages = 0;
                    
                    // Check for non continuous matrix
                    for( int j = 0 ; j < [pixList[ x] count]; j++)
                    {
                        if( pw != [[[fileList[ x] objectAtIndex: j] valueForKey: @"width"] intValue] || ph != [[[fileList[ x] objectAtIndex: j] valueForKey: @"height"] intValue])
                        {
                            volumicData = NO;
                            numberOfNonVolumicImages++;
                            
                            if( firstWrongImage == -1)
                                firstWrongImage = j;
                        }
                    }
                    
                    if( tryToCorrect && numberOfNonVolumicImages == 1 && (firstWrongImage == 0 || firstWrongImage == (long)[pixList[ x] count]-1)) // First or last image with different matrix
                    {
                        NSMutableArray *newFileList = [NSMutableArray array];
                        NSMutableArray *newPixList = [NSMutableArray array];
                        
                        long newSize = pw * ph * ((long)[pixList[ x] count]-1) * sizeof( float);
                        
                        float *newPtr = (float*) malloc( newSize);
                        if( newPtr)
                        {
                            NSData *newVolumeData = [NSData dataWithBytesNoCopy: newPtr length: newSize freeWhenDone: YES];
                            
                            for( int n = 0; n < [pixList[ x] count]; n++)
                            {
                                if( firstWrongImage != n)
                                {
                                    DCMPix *newPix = [[[pixList[ x] objectAtIndex: n] copy] autorelease];
                                    
                                    memcpy( newPtr, [newPix fImage], pw * ph * sizeof( float));
                                    
                                    [newPix setfImage: newPtr];
                                    newPtr += pw * ph;
                                    
                                    [newPixList addObject: newPix];
                                    [newFileList addObject: [fileList[ x] objectAtIndex: n]];
                                }
                            }
                            
                            [self changeImageData: newPixList :newFileList :newVolumeData :NO];
                            
                            [self computeInterval];
                            [self setWindowTitle:self];
                            
                            [imageView setIndex: 0];
                            [imageView sendSyncMessage: 0];
                            
                            [self adjustSlider];
                            
                            postprocessed = YES;
                        }
                    }
                    
                    [[pixList[ x] objectAtIndex: 1] orientation: orientation];
                    
                    pw = [[[fileList[ x] objectAtIndex: [pixList[ x] count]/2] valueForKey: @"width"] intValue];
                    ph = [[[fileList[ x] objectAtIndex: [pixList[ x] count]/2] valueForKey: @"height"] intValue];
                    firstWrongImage = -1;
                    numberOfNonVolumicImages = 0;
                    
                    // Check for non same orientation
                    for( int j = 0 ; j < [pixList[ x] count]; j++)
                    {
                        if( pw != [[[fileList[ x] objectAtIndex: j] valueForKey: @"width"] intValue] || ph != [[[fileList[ x] objectAtIndex: j] valueForKey: @"height"] intValue])
                        {
                            volumicData = NO;
                        }
                        
                        if( volumicData)
                        {
                            float o[ 9];
                            [[pixList[ x] objectAtIndex: j] orientation: o];
                            for( int k = 0 ; k < 9; k++)
                            {
                                if( fabs( o[ k] - orientation[ k]) > ORIENTATION_SENSIBILITY)
                                {
                                    volumicData = NO;
                                    
                                    if( j == 0)
                                        firstImage = YES;
                                    
                                    if( j == (long)[pixList[ x] count] -1)
                                        lastImage = YES;
                                }
                            }
                        }
                    }
                }
                else volumicData = NO;
            }
        }
        
        if( volumicData == NO && (firstImage == YES || lastImage == YES))
        {
            if( firstImage)
            {
                for( int x = 0 ; x < maxMovieIndex ; x++)
                {
                    if( check4D == YES || x == curMovieIndex)
                    {
                        // Correct origin
                        float originA[ 3];
                        [[pixList[ x] objectAtIndex: 2] origin: originA];
                        float originB[ 3];
                        [[pixList[ x] objectAtIndex: 1] origin: originB];
                        
                        DCMPix *pix = [pixList[ x] objectAtIndex: 0];
                        
                        float savedOrigin[ 3];
                        [pix origin: savedOrigin];
                        
                        originB[ 0] -= originA[ 0] - originB[ 0];
                        originB[ 1] -= originA[ 1] - originB[ 1];
                        originB[ 2] -= originA[ 2] - originB[ 2];
                        
                        [pix setOrigin: originB];
                        
                        // Correct orientation
                        float orientation[ 9];
                        [[pixList[ x] objectAtIndex: 1] orientation: orientation];
                        
                        float savedOrientation[ 9];
                        [pix orientation: savedOrientation];
                        
                        [pix setOrientation: orientation];
                        
                        BOOL r = NO;
                        
                        if( isDataVolumicIn4DLevel < 4)
                            r = [self isDataVolumicIn4D: check4D checkEverythingLoaded: c tryToCorrect: NO];
                        
                        if( r && tryToCorrect)
                        {
                            if( [pix isRGB] == NO)
                            {
                                // Set this image to maxValueOfSeries, to find the true minValueOfSeries
                                float m = [pix maxValueOfSeries];
                                float *ptr = [pix fImage];
                                int z = [pix pwidth]*[pix pheight];
                                while( z-- > 0)
                                    *ptr++ = m;
                                
                                [pix computePixMinPixMax];
                                
                                // Then recompute minValueOfSeries
                                for( DCMPix *p in pixList[ x])
                                    p.minValueOfSeries = 0;
                                for( DCMPix *p in pixList[ x])
                                    [p minValueOfSeries];
                                
                                m = [pix minValueOfSeries];
                                ptr = [pix fImage];
                                z = [pix pwidth]*[pix pheight];
                                while( z-- > 0)
                                    *ptr++ = m;
                                
                                // Then recompute maxValueOfSeries
                                for( DCMPix *p in pixList[ x])
                                    p.maxValueOfSeries = 0;
                                
                                for( DCMPix *p in pixList[ x])
                                    [p maxValueOfSeries];
                                
                                [pix kill8bitsImage];
                                [self refresh];
                                [imageView setNeedsDisplay: YES];
                            }
                            else
                            {
                                unsigned char *ptr = (unsigned char*) [pix fImage];
                                int z = [pix pwidth]*[pix pheight]*4;
                                while( z-- > 0)
                                    *ptr++ = 0;
                                
                                [pix kill8bitsImage];
                                [self refresh];
                                [imageView setNeedsDisplay: YES];
                            }
                            
                            DCMPix *otherPix = [pixList[ x] objectAtIndex: 2];
                            [pix setPixelSpacingX: [otherPix pixelSpacingX]];
                            [pix setPixelSpacingY: [otherPix pixelSpacingY]];
                        }
                        else
                        {
                            [pix setOrigin: savedOrigin];
                            [pix setOrientation: savedOrientation];
                        }
                        
                        isDataVolumicIn4DLevel--;
                        return r;
                    }
                }
            }
            
            if( lastImage)
            {
                for( int x = 0 ; x < maxMovieIndex ; x++)
                {
                    if( check4D == YES || x == curMovieIndex)
                    {
                        // Correct origin
                        float originA[ 3];
                        [[pixList[ x] objectAtIndex: [pixList[ x] count]-2] origin: originA];
                        float originB[ 3];
                        [[pixList[ x] objectAtIndex: [pixList[ x] count]-3] origin: originB];
                        
                        DCMPix *pix = [pixList[ x] lastObject];
                        
                        float savedOrigin[ 3];
                        [pix origin: savedOrigin];
                        
                        originA[ 0] += originA[ 0] - originB[ 0];
                        originA[ 1] += originA[ 1] - originB[ 1];
                        originA[ 2] += originA[ 2] - originB[ 2];
                        
                        [pix setOrigin: originA];
                        
                        // Correct orientation
                        float orientation[ 9];
                        [[pixList[ x] objectAtIndex: 1] orientation: orientation];
                        
                        float savedOrientation[ 9];
                        [pix orientation: savedOrientation];
                        
                        [pix setOrientation: orientation];
                        
                        BOOL r = NO;
                        if( isDataVolumicIn4DLevel < 4)
                            r = [self isDataVolumicIn4D: check4D checkEverythingLoaded: c tryToCorrect: NO];
                        
                        if( r && tryToCorrect)
                        {
                            if( [pix isRGB] == NO)
                            {
                                // Set this image to maxValueOfSeries, to find the true minValueOfSeries
                                float m = [pix maxValueOfSeries];
                                float *ptr = [pix fImage];
                                int z = [pix pwidth]*[pix pheight];
                                while( z-- > 0)
                                    *ptr++ = m;
                                
                                [pix computePixMinPixMax];
                                
                                // Then recompute minValueOfSeries
                                for( DCMPix *p in pixList[ x])
                                    p.minValueOfSeries = 0;
                                for( DCMPix *p in pixList[ x])
                                    [p minValueOfSeries];
                                
                                m = [pix minValueOfSeries];
                                ptr = [pix fImage];
                                z = [pix pwidth]*[pix pheight];
                                while( z-- > 0)
                                    *ptr++ = m;
                                
                                // Then recompute maxValueOfSeries
                                for( DCMPix *p in pixList[ x])
                                    p.maxValueOfSeries = 0;
                                
                                for( DCMPix *p in pixList[ x])
                                    [p maxValueOfSeries];
                                
                                [pix kill8bitsImage];
                                [self refresh];
                                [imageView setNeedsDisplay: YES];
                            }
                            else
                            {
                                unsigned char *ptr = (unsigned char*) [pix fImage];
                                int z = [pix pwidth]*[pix pheight]*4;
                                while( z-- > 0)
                                    *ptr++ = 0;
                                
                                [pix kill8bitsImage];
                                [self refresh];
                                [imageView setNeedsDisplay: YES];
                            }
                            
                            DCMPix *otherPix = [pixList[ x] objectAtIndex: [pixList[ x] count]-3];
                            [pix setPixelSpacingX: [otherPix pixelSpacingX]];
                            [pix setPixelSpacingY: [otherPix pixelSpacingY]];
                        }
                        else
                        {
                            [pix setOrigin: savedOrigin];
                            [pix setOrientation: savedOrientation];
                        }
                        
                        isDataVolumicIn4DLevel--;
                        return r;
                    }
                }
            }
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    isDataVolumicIn4DLevel--;
    return volumicData;
}

- (BOOL) isDataVolumicIn4D: (BOOL) check4D
{
    return [self isDataVolumicIn4D: check4D checkEverythingLoaded: YES];
}

- (id) initWithPix:(NSMutableArray*)f withFiles:(NSMutableArray*)d withVolume:(NSData*) v
{
#ifdef WITH_IMPORTANT_NOTICE
    [AppController displayImportantNotice: self];
#endif
    
    //	*(long*)0 = 0xDEADBEEF; // ILCrashReporter test -- DO NOT ACTIVATE THIS LINE
    
    DicomImage* dicomImage = [d objectAtIndex:0];
    self.database = [DicomDatabase databaseForContext:dicomImage.managedObjectContext];
    
    [self setMagnetic: YES];
    
    if( [d count] == 0) d = nil;
    
    [[NSUserDefaults standardUserDefaults] setObject: [NSString stringWithFormat: @"%d%d", 1, 1] forKey: @"LastWindowsTilingRowsColumns"];
    
    self = [super initWithWindowNibName:@"Viewer"];
    
    retainedToolbarItems = [[NSMutableArray alloc] initWithCapacity: 0];
    
    [self setupToolbar];
    
    [ROI loadDefaultSettings];
    
    resampleRatio = 1.0;
    
    [imageView setDrawing: NO];
    
    processorsLock = [[NSConditionLock alloc] initWithCondition: 1];
    
    undoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
    redoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
    
    [self viewerControllerInit];
    [self changeImageData:f :d :v :YES];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(updateImageView:)
               name: OsirixDCMUpdateCurrentImageNotification
             object: nil];
    
    [seriesView setPixels:pixList[0] files:fileList[0] rois:roiList[0] firstImage:0 level:'i' reset:YES];	//[pixList[0] count]/2
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"RestoreLeftMouseTool"])
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTLEFTTOOL"]], @"toolIndex", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDefaultToolModifiedNotification object:nil userInfo: userInfo];
    }
    
    displayOnlyKeyImages = NO;
    
    //	[[IMService notificationCenter] addObserver:self selector:@selector(_stateChanged:) name:IMAVManagerStateChangedNotification object:nil];
    //	[[IMAVManager sharedAVManager] setVideoDataSource:imageView];
    //	[[IMAVManager sharedAVManager] setVideoOptimizationOptions:IMVideoOptimizationStills];
    
    [imageView setDrawing: YES];
    
    [self SetSyncButtonBehavior: self];
    // why turn off sync? let's try making this new window sync with the old ones...
    bool wedidsomethingsmart = NO;
    if (SYNCSERIES) {
        // find other viewer of same study
        ViewerController* samestudyviewer = nil;
        for (ViewerController* iv in [ViewerController getDisplayed2DViewers])
            if (iv != self && [iv.studyInstanceUID isEqualToString:self.studyInstanceUID]) {
                samestudyviewer = iv;
                break;
            }
        if (samestudyviewer) {
            [imageView setSyncRelativeDiff:[[samestudyviewer imageView] syncRelativeDiff]];
            [[self findSyncSeriesButton] setImage: [NSImage imageNamed: @"SyncLock.pdf"]];
            [imageView setSyncSeriesIndex: 0];
            wedidsomethingsmart = YES;
        }
    }
    if (!wedidsomethingsmart)
        [self turnOffSyncSeriesBetweenStudies: self]; // keep the old behavior
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOMATIC FUSE"])
        [self blendWindows: nil];
    
    [OpacityPopup setEnabled:YES];
    
    if([AppController canDisplay12Bit]) t12BitTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(verify12Bit:) userInfo:nil repeats:YES] retain];
    else t12BitTimer = nil;
    
    [self willChangeValueForKey: @"KeyImageCounter"];
    [self didChangeValueForKey: @"KeyImageCounter"];
    
#ifndef OSIRIX_LIGHT
    [[OSIEnvironment sharedEnvironment] addViewerController:self];
#endif
    
    toolbarPanel = [[ToolbarPanelController alloc] initForViewer: self withToolbar: toolbar];
    
    return self;
}

-(void)awakeFromNib
{
    /*
    NSButton* zoomButton = [[self window] standardWindowButton:NSWindowZoomButton];
    [zoomButton setTarget:[self window]];
    [zoomButton setAction:@selector(zoom:)];
    */
     
    DisplayUseInvertedPolarity = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO)
    {
        if( splitView == nil) { // For compatibility with old localized (without auto-layout) xibs....
            splitViewAllocated = YES;
            
            splitView = [[NSSplitView alloc] initWithFrame: [self.window.contentView bounds]];
            [splitView addSubview: previewMatrixScrollView];
            [splitView addSubview: [[self.window.contentView subviews] lastObject]]; // First custom view -- see viewer.xib
            [splitView setVertical: YES];
            [splitView setAutoresizingMask: NSViewWidthSizable+NSViewHeightSizable];
        }
        else
        {
            previewMatrix.translatesAutoresizingMaskIntoConstraints = NO;
            splitView.translatesAutoresizingMaskIntoConstraints = NO;
            
            [splitView replaceSubview: [[splitView subviews] objectAtIndex: 0] with: previewMatrixScrollView];
        }
        
        if( splitViewAllocated)
            [self.window.contentView addSubview: splitView];
        
        [self setMatrixVisible: NO];
        
        [previewMatrix setCellClass: [ThumbnailCell class]];
        [previewMatrix renewRows: 100 columns: 1];
        
        [self setMatrixVisible: YES];
    }
    else
        [splitView setDividerStyle: NSSplitViewDividerStyleThin];
    
    [splitView setDelegate: self];
    [splitView adjustSubviews];
    
    [previewMatrix setIntercellSpacing:NSMakeSize(-1, -1)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeScrollerStyleDidChangeNotification:) name:@"NSPreferredScrollerStyleDidChangeNotification" object:nil];
    [self observeScrollerStyleDidChangeNotification:nil];
    
    NSRect frame = [comparativesButton frame];
    frame.origin.y += frame.size.height-15;
    frame.size.height = 15;
    [comparativesButton setFrame:frame];
    
    flagListPODComparatives = [[NSNumber alloc] initWithBool:YES];
    [self bind:@"flagListPODComparatives" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.listPODComparativesIn2DViewer" options:nil];
    
    [ViewerController clearFrontMost2DViewerCache];
    
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_2D_VIEWER_LAUNCHED detail:@"{}"];
}

-(void)comparativeRefresh:(NSString*) patientUID
{
    DicomImage* firstObject = [fileList[curMovieIndex] count]? [fileList[curMovieIndex] objectAtIndex:0] : nil;
    
    if( firstObject && [patientUID compare: firstObject.series.study.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
        [self buildMatrixPreview: NO];
}

static int avoidReentryRefreshDatabase = 0;

-(void)refreshDatabase:(NSArray*)newImages
{
    if( avoidReentryRefreshDatabase > 0)
        return;
    
    avoidReentryRefreshDatabase++;
    @try
    {
        if( [[self imageView] mouseDragging])
        {
            [self performSelector:@selector(refreshDatabase:) withObject:newImages afterDelay:0.1];
            return;
        }
        
        BOOL rebuild = NO, reload = NO;
        
        if( !newImages)
            rebuild = YES;
        
        DicomImage* firstObject = [fileList[curMovieIndex] count]? [fileList[curMovieIndex] objectAtIndex:0] : nil;
        for( DicomImage* dicomImage in newImages)
        {
            if( [[dicomImage.series objectID] isEqualTo: [firstObject.series objectID]])
                reload = YES;
            else if( !firstObject || [dicomImage.series.study.patientUID isEqualToString:firstObject.series.study.patientUID])
                rebuild = YES;
            
            if( reload == YES && rebuild == YES)
                break;
        }
        
        if( rebuild)
            [self buildMatrixPreview: NO];
        
        if( reload) {
            BrowserController* bc = [BrowserController currentBrowser];
            [bc openViewerFromImages:[NSArray arrayWithObject:[bc childrenArray:firstObject.series]] movie:NO viewer:self keyImagesOnly:NO tryToFlipData:YES];
        }
        
        [super refreshDatabase: newImages];
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    @finally {
        avoidReentryRefreshDatabase--;
    }
}

- (NSNumber*) KeyImageCounter
{
    int total = 0;
    
    for( NSManagedObject *image in fileList[ 0])
    {
        if( [[image valueForKey:@"isKeyImage"] boolValue]) total++;
    }
    
    return [NSNumber numberWithInt: total];
}

- (id) viewCinit:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
    return [self initWithPix: f withFiles: d withVolume: v];
}

- (BOOL) updateTilingViewsValue
{
    return updateTilingViews;
}

- (void) setUpdateTilingViewsValue:(BOOL) v
{
    updateTilingViews = v;
}

-(void) finalizeSeriesViewing
{
    @synchronized( loadingThread)
    {
        [loadingThread cancel];
        [loadingThread autorelease];
        loadingThread = nil;
    }
    
    if( resampleRatio != 1)
        resampleRatio = 1;
    
    for( int i = 0; i < maxMovieIndex; i++)
    {
        @try
        {
            [self saveROI: i];
        }
        @catch( NSException *e)
        {
            NSLog( @"***** saveROI exception : %@", e);
        }
        
        
        
        for( NSArray *a in roiList[ i])
        {
            [a retain];
            
            for( ROI *r in a)
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object: r userInfo: nil];
            
            [a release];
        }
    }
    
    [self applyStatusValue];
    
    for( int i = 0; i < maxMovieIndex; i++)
    {
        [copyRoiList[ i] release]; copyRoiList[ i] = nil;
        [roiList[ i] release];  roiList[ i] = nil;
        [pixList[ i] release];  pixList[ i] = nil;
        [fileList[ i] release];  fileList[ i] = nil;
        
        [self sendWillFreeVolumeDataNotificationWithVolumeData:volumeData[ i] movieIndex:i];
        [volumeData[ i] release];  volumeData[ i] = nil;
    }
    
    [undoQueue removeAllObjects];
    [redoQueue removeAllObjects];
    
    if( thickSlab)
    {
        [thickSlab release];
        thickSlab = nil;
    }
}

- (void) dealloc
{
    [ViewerController clearFrontMost2DViewerCache];
    
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"dealloc NOT on main thread");
    
    @try
    {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"SeriesListVisible"];
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    [[self window] setDelegate: nil];
    
    [splitView setDelegate: nil];
    if( splitViewAllocated)
    {
        [splitView release];
        splitView = nil;
    }
    
    NSArray *windows = [NSApp windows];
    
    if([windows count] < 2)
        [[BrowserController currentBrowser] showDatabase:self];
    
    [self ActivateBlending: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    //[self finalizeSeriesViewing]; /**** CALLED IN windowWillClose *****/
    
    @synchronized( loadingThread)
    {
        [loadingThread cancel];
        [loadingThread autorelease];
        loadingThread = nil;
    }
    
    [seriesPopupContextualMenu release];
    seriesPopupContextualMenu = nil;
    
    [undoQueue release];
    undoQueue = nil;
    
    [redoQueue release];
    redoQueue = nil;
    
    [curOpacityMenu release];
    curOpacityMenu = nil;
    
    [imageView release];
    imageView = nil;
    
    [seriesView release];
    seriesView = nil;
    
    [exportDCM release];
    exportDCM = nil;
    
    [blendedWindow release];
    blendedWindow = nil;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
    {
        for( int i = 0 ; i < [[NSScreen screens] count]; i++)
            [thumbnailsListPanel[ i] thumbnailsListWillClose: previewMatrixScrollView];
    }
    
    [ROINamesArray release];
    ROINamesArray = nil;
    
    [roiLock release];
    roiLock = nil;
    
//    [contextualDictionaryPath release];
//    contextualDictionaryPath = nil;
    
    [backCurCLUTMenu release]; backCurCLUTMenu = nil;
    [curCLUTMenu release]; curCLUTMenu = nil;
    [curConvMenu release]; curConvMenu = nil;
    [curWLWWMenu release]; curWLWWMenu = nil;
    [processorsLock release]; processorsLock = nil;
    [retainedToolbarItems release]; retainedToolbarItems = nil;
    [editedRadiopharmaceuticalStartTime release]; editedRadiopharmaceuticalStartTime = nil;
    [editedAcquisitionTime release]; editedAcquisitionTime = nil;
    [toolbar release]; toolbar = nil;
    [injectionDateTime release]; injectionDateTime = nil;
    [convThread release];
    [flipDataThread release];
    self.windowsStateName = nil;
    
    [self unbind:@"flagListPODComparatives"];
    self.flagListPODComparatives = nil;
    
    //	[[AppController sharedAppController] tileWindows: nil];	<- We cannot do this, because:
    //	This is very important, or if we have a queue of closing windows, it will crash....
    
    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    {
        if( v != self) [v buildMatrixPreview: NO];
    }
    
    [toolbarPanel release];
    toolbarPanel = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    [super dealloc];
    
    NSLog(@"ViewController dealloc");
}

- (void) selectFirstTilingView
{
    [seriesView selectFirstTilingView];
}

- (BOOL) parallelToViewer: (ViewerController*) v
{
    float orientA[9], orientB[9];
    
    [imageView.curDCM orientation:orientA];
    [v.imageView.curDCM orientation:orientB];
    
    if( [DCMView angleBetweenVector: orientA+6 andVector:orientB+6] < [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"])
        return YES;
    else
        return NO;
}

- (void) copyVolumeData: (NSData**) vD andDCMPix: (NSMutableArray **) newPixList forMovieIndex: (int) v
{
    *vD = nil;
    *newPixList = nil;
    
    // First calculate the amount of memory needed for the new serie
    NSArray		*pL = [self pixList: v];
    DCMPix		*curPix;
    long		mem = 0;
    
    for( int i = 0; i < [pL count]; i++)
    {
        curPix = [pL objectAtIndex: i];
        mem += [curPix pheight] * [curPix pwidth] * 4;		// each pixel contains either a 32-bit float or a 32-bit ARGB value
    }
    
    unsigned char *fVolumePtr = malloc( mem);	// ALWAYS use malloc for allocating memory !
    if( fVolumePtr)
    {
        // Copy the source series in the new one !
        memcpy( fVolumePtr, [self volumePtr: v], mem);
        
        // Create a NSData object to control the new pointer
        *vD = [[[NSData alloc] initWithBytesNoCopy:fVolumePtr length:mem freeWhenDone:YES] autorelease];
        
        // Now copy the DCMPix with the new fVolumePtr
        *newPixList = [NSMutableArray array];
        for( int i = 0; i < [pL count]; i++)
        {
            curPix = [[[pL objectAtIndex: i] copy] autorelease];
            [curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * 4 * i)];
            [*newPixList addObject: curPix];
        }
    }
}

- (ViewerController*) copyViewerWindow
{
    ViewerController *new2DViewer = nil;
    
    // We will read our current series, and duplicate it by creating a new series!
    
    for( int v = 0; v < self.maxMovieIndex; v++)
    {
        NSData *vD = nil;
        NSMutableArray *newPixList = nil;
        
        [self copyVolumeData: &vD andDCMPix:&newPixList forMovieIndex: v];
        
        if( vD)
        {
            // We don't need to duplicate the DicomFile array, because it is identical!
            
            // A 2D Viewer window needs 3 things:
            // A mutable array composed of DCMPix objects
            // A mutable array composed of DicomFile objects
            // Number of DCMPix and DicomFile has to be EQUAL !
            // NSData volumeData contains the images, represented in the DCMPix objects
            if( new2DViewer == nil)
            {
                new2DViewer = [self newWindow:newPixList :[self fileList: v] :vD];
                [new2DViewer roiDeleteAll: self];
            }
            else
                [new2DViewer addMovieSerie:newPixList :[self fileList: v] :vD];
        }
    }
    
    return new2DViewer;
}

-(void) changeImageData:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v :(BOOL) newViewerWindow
{
    if( windowWillClose) return;
    
#ifndef OSIRIX_LIGHT
    [[OSIEnvironment sharedEnvironment] viewerControllerWillChangeData:self];
#endif
    
    if( delayedTileWindows)
    {
        delayedTileWindows = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
        [[AppController sharedAppController] tileWindows: nil];
    }
	   
    if( curMovieIndex != 0)
        [self setMovieIndex: 0];
    
    BOOL		sameSeries = NO;
    long		i, previousColumns = [imageView columns], previousRows = [imageView rows];
    int			previousFusion = [popFusion selectedTag], previousFusionActivated = [activatedFusion state];
    
    NSString	*previousPatientUID = [[[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.patientUID"] retain];
    NSString	*previousStudyInstanceUID = [[[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] retain];
    DicomImage    *previousDicomImage = [imageView imageObj];
    float		previousOrientation[ 9] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
    float		previousLocation;
    int			previousCurImage = [imageView curImage];
    BOOL		wasFlipped = [imageView flippedData];
    
    @synchronized( self)
    {
        NSDisableScreenUpdates();
        
        statusValueToApply = -1;
        
        @try
        {
            BOOL equalVector = YES;
            BOOL nonZeroVector = NO;
            
            nonVolumicDataWarningDisplayed = YES;
            
            if( previousColumns != 1 || previousRows != 1)
            {
                [imageView release];
                imageView = [[[seriesView imageViews] objectAtIndex:0] retain];
                [imageView becomeFirstResponder];
                
                [self setImageRows: 1 columns: 1];
            }
            
            [imageView mouseUp: [[NSApplication sharedApplication] currentEvent]];
            
            if( [pixList[ 0] count] && d.count)
            {
                [self selectFirstTilingView];
                [imageView updateTilingViews];
                
                [[pixList[ 0] objectAtIndex:0] orientation: previousOrientation];
                
                float newOrientation[ 9];
                [[f objectAtIndex:0] orientation: newOrientation];
                
                for( i = 0; i < 9; i++)
                {
                    if( previousOrientation[ i] != newOrientation[ i])
                        equalVector = NO;
                    
                    if( newOrientation[ i] != 0)
                        nonZeroVector = YES;
                }
                
                BOOL wasSyncButtonBehaviorIsBetweenStudies = NO;
                
                if( [previousStudyInstanceUID isEqualToString: [[d objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
                {
                    if( SyncButtonBehaviorIsBetweenStudies && SYNCSERIES)
                        wasSyncButtonBehaviorIsBetweenStudies = YES;
                }
                
                if( wasSyncButtonBehaviorIsBetweenStudies == NO)
                    [self turnOffSyncSeriesBetweenStudies: self];
                
                previousLocation = [[[imageView imageObj] sliceLocation] floatValue];
            }
            // Check if another post-processing viewer is open : we CANNOT release the fVolumePtr -> OsiriX WILL crash
            
            long minWindows = 1;
            if( [self FullScreenON]) minWindows++;
            
            if( newViewerWindow == NO && [[[AppController sharedAppController] FindRelatedViewers:pixList[0]] count] > minWindows)
            {
                NSBeep();
                NSLog( @"changeImageData not possible with other post-processing windows opened");
            }
            else
            {
                // *****************
                [imageView setDrawing: NO];
                
                
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixViewerWillChangeNotification object: self userInfo: nil];
                
                [self ActivateBlending: nil];
                [self clear8bitRepresentations];
                [shutterOnOff setState:NSOffState];
                
                [self setFusionMode: 0];
                
                [imageView setIndex: 0];
                
                DicomStudy *newStudy = nil;
                
                if( d.count)
                    newStudy = [[d objectAtIndex: 0] valueForKeyPath: @"series.study"];
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixCloseViewerNotification object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: newStudy.objectID, @"newStudyID", nil]];
                
                windowWillClose = YES;
                
                [self setUpdateTilingViewsValue: YES];
                
                if( [subCtrlOnOff state]) [imageView setWLWW: 0 :0];
                [self checkView: subCtrlView :NO];
                
                if( currentOrientationTool != originalOrientation && originalOrientation != -1)
                {
                    [imageView setXFlipped: NO];
                    [imageView setYFlipped: NO];
                    [imageView setRotation: 0];
                }
                
                [orientationMatrix setEnabled: NO];
                
                if( [d count] > 0 && [fileList[ 0] count] > 0 && [[[[fileList[ 0] objectAtIndex: 0] valueForKey: @"series"] objectID] isEqualTo: [[[d objectAtIndex: 0] valueForKey: @"series"] objectID]])
                    sameSeries = YES;
                
                // Release previous data
                [self finalizeSeriesViewing];
                
                [[[BrowserController currentBrowser] database] lock];
                
                @try
                {
                    [orientationMatrix selectCellWithTag: 0];
                    
                    curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
                    curConvMenu = [NSLocalizedString(@"No Filter", nil) retain];
                    curWLWWMenu = [NSLocalizedString(@"Default WL & WW", nil) retain];
                    
                    curMovieIndex = 0;
                    maxMovieIndex = 1;
                    subCtrlMaskID = -2;
                    registeredViewer = nil;
                    resampleRatio = 1.0;
                    
                    volumeData[ 0] = v;
                    [volumeData[ 0] retain];
                    [self sendDidAllocateVolumeDataNotificationWithVolumeData:volumeData[0] movieIndex:0];
                    
                    direction = 1;
                    
                    [f retain];
                    pixList[ 0] = f;
                    
                    // Prepare pixList for image thick slab
                    for( i = 0; i < [pixList[0] count]; i++)
                    {
                        [[pixList[0] objectAtIndex: i] setArrayPix: pixList[0] :i];
                    }
                    
                    if( [d count] == 0) d = nil;
                    [d retain];
                    fileList[ 0] = d;
                    
                    @try
                    {
                        // Prepare roiList
                        roiList[0] = [[NSMutableArray alloc] initWithCapacity: 0];
                        copyRoiList[0] = [[NSMutableArray alloc] initWithCapacity: 0];
                        for( i = 0; i < [pixList[0] count]; i++)
                        {
                            [roiList[0] addObject:[NSMutableArray array]];
                            [copyRoiList[0] addObject:[NSData data]];
                        }
                        [self loadROI:0];
                        
                        [imageView setPixels:pixList[0] files:fileList[0] rois:roiList[0] firstImage: 0 level:'i' reset:!sameSeries];
                        
                        [imageView setIndexWithReset: 0 :YES];
                    }
                    @catch( NSException *e)
                    {
                        NSLog(@"Exception change image data: %@", e);
                    }
                    
                    DCMPix *pic = [imageView curDCM];
                    
                    [self setWindowTitle:self];
                    
                    [slider setMaxValue:(long)[pixList[0] count]-1];
                    [slider setNumberOfTickMarks:[pixList[0] count]];
                    [self adjustSlider];
                    
                    if([fileList[0] count] == 1)
                    {
                        [speedSlider setEnabled:NO];
                        [slider setEnabled:NO];
                    }
                    else
                    {
                        if( [pic cineRate])
                            [speedSlider setFloatValue: [pic cineRate]];
                        else if( [[NSUserDefaults standardUserDefaults] floatForKey: @"defaultFrameRate"])
                            [speedSlider setFloatValue: [[NSUserDefaults standardUserDefaults] floatForKey: @"defaultFrameRate"]];
                        
                        [speedSlider setEnabled:YES];
                        [slider setEnabled:YES];
                    }
                    
                    [subCtrlOnOff setState: NSOffState];
                    [convPopup selectItemAtIndex:0];
                    [stacksFusion setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"stackThickness"]];
                    [sliderFusion setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"stackThickness"]];
                    [sliderFusion setEnabled:NO];
                    [activatedFusion setState: NSOffState];
                    
                    [movieRateSlider setEnabled: NO];
                    [moviePosSlider setEnabled: NO];
                    [moviePlayStop setEnabled:NO];

                    if( [[NSUserDefaults standardUserDefaults] floatForKey: @"defaultMovieRate"])
                    {
                        [movieRateSlider setFloatValue: [[NSUserDefaults standardUserDefaults] floatForKey: @"defaultMovieRate"]];
                        [movieTextSlide setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%0.0f im/s", @"im/s = images per second"), (float) [self movieRate]]];
                    }
                    
                    [speedText setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%0.1f im/s",  @"im/s = images per second"), (float) [self frameRate]*direction]];
                    
                    [seriesView setPixels:pixList[0] files:fileList[0] rois:roiList[0] firstImage: 0 level:'i' reset:!sameSeries];
                    
                    if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
                    {
                        if( [[self modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"]))
                        {
                            if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                                [self ApplyCLUTString: @"B/W Inverse"];
                            else
                                [self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
                        }
                        else [self ApplyCLUTString:NSLocalizedString(@"No CLUT", nil)];
                        
                        if( [[self modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpacityTableNM"] == YES && [[self modality] isEqualToString:@"NM"]))
                        {
                            if( [[NSUserDefaults standardUserDefaults] boolForKey:@"PETOpacityTable"])
                                [self ApplyOpacityString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default Opacity Table"]];
                            else [self ApplyOpacityString: NSLocalizedString( @"Linear Table", nil)];
                        }
                        else [self ApplyOpacityString: NSLocalizedString( @"Linear Table", nil)];
                        
                        if(([[self modality] isEqualToString:@"CR"] || [[self modality] isEqualToString:@"DR"] || [[self modality] isEqualToString:@"DX"] || [[self modality] isEqualToString:@"MG"] || [[self modality] isEqualToString:@"XA"] || [[self modality] isEqualToString:@"RF"]) && [[NSUserDefaults standardUserDefaults] boolForKey:@"automatic12BitTotoku"] && [AppController canDisplay12Bit])
                        {
                            [imageView setIsLUT12Bit:YES];
                            [display12bitToolbarItemMatrix selectCellWithTag:0];
                        }
                    }
                    else
                    {
                        [self ApplyCLUTString:NSLocalizedString(@"No CLUT", nil)];
                        [self ApplyOpacityString: NSLocalizedString( @"Linear Table", nil)];
                    }
                    
                    int curImage = [imageView curImage];
                    if( curImage >= [fileList[ curMovieIndex] count])
                        curImage = 0;
                    
                    NSNumber *status = [[fileList[ curMovieIndex] objectAtIndex: curImage] valueForKeyPath:@"series.study.stateText"];
                    
                    if( status == nil) [StatusPopup selectItemWithTitle: NSLocalizedString(@"empty", nil)];
                    else [StatusPopup selectItemWithTag: [status intValue]];
                    
                    NSString *com = [[fileList[ curMovieIndex] objectAtIndex: curImage] valueForKeyPath:@"series.comment"];
                    
                    if( com == nil || [com isEqualToString:@""])
                        com = [[fileList[ curMovieIndex] objectAtIndex: curImage] valueForKeyPath:@"series.study.comment"];
                    
                    if( com == nil || [com isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"Add a comment", nil)];
                    else [CommentsField setTitle: com];
                    
                    if( [[[[fileList[ curMovieIndex] objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"] == NO)
                        [[BrowserController currentBrowser] findAndSelectFile: nil image :[fileList[ curMovieIndex] objectAtIndex: curImage] shouldExpand :NO];
                    
                    ////////
                    
                    if( [previousPatientUID compare: [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.patientUID"] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
                    {
                        [self buildMatrixPreview];
                        [self showCurrentThumbnail:self];
                    }
                    else
                    {
                        [self showCurrentThumbnail:self];
                    }
                    
                    
                    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDisplayImagesOfSamePatient"])
                    {
                        NSString *curPatientUID = [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.patientUID"];
                        NSString *curPatientID = [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.patientID"];
                        
                        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
                        {
                            NSString *pUID = [[[v fileList] objectAtIndex:0] valueForKeyPath:@"series.study.patientUID"];
                            NSString *pID = [[[v fileList] objectAtIndex:0] valueForKeyPath:@"series.study.patientID"];
                            
                            if( [curPatientUID compare: pUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
                            {
                                if( [curPatientID isEqualToString: pID] == NO)
                                    [[v window] close];
                            }
                        }
                    }
                    
                    // If same study, same patient and same orientation (but NOT same series), try to go the same position (mm) if available
                    if( [previousStudyInstanceUID isEqualToString: [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
                    {
                        if( sameSeries)
                        {
                            // Can we find the same DicomImage?
                            
                            NSUInteger index = NSNotFound;
                            
                            if( previousDicomImage)
                                index = [fileList[0] indexOfObject: previousDicomImage];
                            
                            if( index != NSNotFound)
                            {
                                if( wasFlipped)
                                    index = (long)[fileList[ 0] count] -1 -index;
                                
                                [imageView setIndex: index];
                            }
                        }
                        else
                        {
                            BOOL keepFusion = NO;
                            
                            if( equalVector && nonZeroVector)
                            {
                                float start = [[[fileList[ 0] objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue];
                                float end = [[[fileList[ 0] lastObject] valueForKey:@"sliceLocation"] floatValue];
                                
                                if( start == end)
                                {
                                    [imageView setIndex: previousCurImage];
                                    [self adjustSlider];
                                    keepFusion = YES;
                                }
                                else
                                {
                                    if( start > end)
                                    {
                                        float temp = end;
                                        
                                        end = start;
                                        start = temp;
                                    }
                                    
                                    if( previousLocation >= start && previousLocation <= end)
                                    {
                                        long	index = 0;
                                        float   smallestdiff = -1, fdiff;
                                        
                                        for( int i = 0; i < [fileList[ 0] count]; i++)
                                        {
                                            float slicePosition = [[[fileList[ 0] objectAtIndex: i] valueForKey:@"sliceLocation"] floatValue];
                                            
                                            fdiff = fabs( slicePosition - previousLocation);
                                            
                                            if( fdiff < smallestdiff || smallestdiff == -1)
                                            {
                                                smallestdiff = fdiff;
                                                index = i;
                                            }
                                        }
                                        
                                        if( index != 0)
                                        {
                                            if( wasFlipped)
                                                index = (long)[fileList[ 0] count] -1 -index;
                                            [imageView setIndex: index];
                                            [self adjustSlider];
                                            keepFusion = YES;
                                        }
                                    }
                                }
                            }
                            else if( nonZeroVector) // Try to find another viewer, of the same study, with same orientation
                            {
                                for( ViewerController *v in [ViewerController getDisplayed2DViewers])
                                {
                                    if( v != self && v.isDataVolumic && [v.studyInstanceUID isEqualToString: self.studyInstanceUID] && [self parallelToViewer: v] && v.imageView.curImage != 0)
                                    {
                                        previousLocation = [v.currentImage.sliceLocation floatValue];
                                        
                                        float start = [[[fileList[ 0] objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue];
                                        float end = [[[fileList[ 0] lastObject] valueForKey:@"sliceLocation"] floatValue];
                                        if( start > end)
                                        {
                                            float temp = end;
                                            
                                            end = start;
                                            start = temp;
                                        }
                                        
                                        if( previousLocation >= start && previousLocation <= end)
                                        {
                                            long	index = 0;
                                            float   smallestdiff = -1, fdiff;
                                            
                                            for( int i = 0; i < [fileList[ 0] count]; i++)
                                            {
                                                float slicePosition = [[[fileList[ 0] objectAtIndex: i] valueForKey:@"sliceLocation"] floatValue];
                                                
                                                fdiff = fabs( slicePosition - previousLocation);
                                                
                                                if( fdiff < smallestdiff || smallestdiff == -1)
                                                {
                                                    smallestdiff = fdiff;
                                                    index = i;
                                                }
                                            }
                                            
                                            if( index != 0)
                                            {
                                                if( wasFlipped)
                                                    index = (long)[fileList[ 0] count] -1 -index;
                                                [imageView setIndex: index];
                                                [self adjustSlider];
                                                keepFusion = YES;
                                                
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if( keepFusion)
                                if( [[self modality] isEqualToString:@"CT"] == NO) keepFusion = NO;
                            
                            if( keepFusion == NO)
                            {
                                if( blendingController)
                                    [self ActivateBlending: nil];
                            }
                        }
                    }
                    else //If study ID changed, cancel the fusion, if existing
                    {
                        if( blendingController) [self ActivateBlending: nil];
                    }
                    
                    [previousStudyInstanceUID release];
                    [previousPatientUID release];
                    
                    // Is it only key images?
                    NSArray	*images = fileList[ 0];
                    BOOL onlyKeyImages = NO;
                    
                    if( [images count] != [[[images objectAtIndex: 0] valueForKeyPath: @"series.images"] count] && postprocessed == NO)
                    {
                        onlyKeyImages = YES;
                        for( NSManagedObject *image in images)
                        {
                            if( [[image valueForKey:@"isKeyImage"] boolValue] == NO) onlyKeyImages = NO;
                        }
                    }
                    
                    displayOnlyKeyImages = onlyKeyImages;
                    [keyImagePopUpButton selectItemAtIndex:displayOnlyKeyImages];
                    
                    windowWillClose = NO;
                    
                    [self setPostprocessed: NO];
                    
                    [self SetSyncButtonBehavior: self];
                    
                    if( [[self window] isVisible])
                        [imageView becomeMainWindow];	// This will send the image sync order !
                    
                    [self setUpdateTilingViewsValue: NO];
                    
                    [self selectFirstTilingView];
                    [imageView updateTilingViews];
                    
                    if( previousFusionActivated)
                    {
                        [self setFusionMode: previousFusion];
                        
                        [popFusion selectItemWithTag:previousFusion];
                        
                        [imageView sendSyncMessage: 0];
                    }
                    
                    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOMATIC FUSE"])
                        [self blendWindows: nil];
                    
                    [self refreshMenus];
                    
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDCMUpdateCurrentImageNotification object: imageView userInfo: userInfo];
                    
                    if( previousColumns != 1 || previousRows != 1)
                    {
                        [imageView release];
                        imageView = [[[seriesView imageViews] objectAtIndex:0] retain];
                        [imageView becomeFirstResponder];
                    }
                    
                    [self setCurWLWWMenu: [DCMView findWLWWPreset: [imageView curWL] :[imageView curWW] :[imageView curDCM]]];
                    
                    nonVolumicDataWarningDisplayed = NO;
                    
                    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
                        [v buildMatrixPreview: NO];
                    
                    NSPoint subtractionOffset = [[imageView curDCM] subPixOffset];
                    [self offsetMatrixSetting:([self threeTestsFivePosibilities: (int)subtractionOffset.y] * 5) + [self threeTestsFivePosibilities: (int)subtractionOffset.x]];
                    
                    [subCtrlSum setFloatValue: 1];
                    [subCtrlPercent setFloatValue: 1];
                    
                    [imageView setDrawing: YES];
                    [imageView setNeedsDisplay: YES];
                    
                    // **
                    
                    // Apply saved images tiling or default protocol
                    
                    DicomStudy *study = self.currentStudy;
                    DicomSeries *series = self.currentSeries;
                    
                    int newColumns = previousColumns;
                    int newRows = previousRows;
                    
                    // default protocol
                    [[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:[study valueForKey:@"modality"] description:[study valueForKey:@"studyName"]];
                    
                    newColumns = [[WindowLayoutManager sharedWindowLayoutManager] imagesColumns];
                    newRows = [[WindowLayoutManager sharedWindowLayoutManager] imagesRows];
                    
                    // is there a windows state?
                    
                    if( [study valueForKey:@"windowsState"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceLoad"])
                    {
                        NSArray *viewers = [NSPropertyListSerialization propertyListFromData: [study valueForKey:@"windowsState"] mutabilityOption: NSPropertyListImmutable format: nil errorDescription: nil];
                        
                        for( NSDictionary *dict in viewers)
                        {
                            NSString *studyUID = [dict valueForKey:@"studyInstanceUID"];
                            NSString *seriesUID = [dict valueForKey:@"seriesInstanceUID"];
                            
                            if( [studyUID isEqualToString: [study valueForKey: @"studyInstanceUID"]] && [seriesUID isEqualToString: [series valueForKey: @"seriesInstanceUID"]])
                            {
                                newRows = [[dict valueForKey:@"rows"] intValue];
                                newColumns = [[dict valueForKey:@"columns"] intValue];
                            }
                        }
                    }
                    
                    BOOL a = ![DCMView noPropagateSettingsInSeriesForModality: self.modality];
                    
                    for( DCMView *view in seriesView.imageViews)
                    {
                        if( view.COPYSETTINGSINSERIES != a)
                            [view setCOPYSETTINGSINSERIES: a];
                    }
                    
                    if( newRows != 1 || newColumns != 1)
                        [self setImageRows: newRows columns: newColumns rescale: YES];
                }
                @catch( NSException *e)
                {
                    NSLog( @"***** changeImageData exception : %@", e);
                    [[self window] close];
                }
                
                [[[BrowserController currentBrowser] database] unlock];
                
                [imageView computeColor];
                
                [self redrawToolbar];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixViewerDidChangeNotification object: self userInfo: nil];
            
            [self willChangeValueForKey: @"KeyImageCounter"];
            [self didChangeValueForKey: @"KeyImageCounter"];
            
            [imageView computeColor];
            
            if( exportDCM)
            {
                [exportDCM release]; //We want new UNIQUE seriesInstanceUID & studyInstanceUID
                exportDCM = nil;
            }
        }
        @catch( NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        @finally {
            NSEnableScreenUpdates();
        }
    }
    
    for( ViewerController * v in [ViewerController getDisplayed2DViewers])
    {
        if( v != self)
            [v propagateSettings];
    }
    
#ifndef OSIRIX_LIGHT
    [[OSIEnvironment sharedEnvironment] viewerControllerDidChangeData:self];
#endif
}

- (void) showWindowTransition
{
    NSScreen *screen = nil;
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"MULTIPLESCREENS"])
    {
        default:
        case 0:		// use main screen only
            screen = [[NSScreen screens] objectAtIndex:0];
            break;
            
        case 1:		// use second screen only
            if( [[NSScreen screens] count] > 1)
                screen = [[NSScreen screens] objectAtIndex:1];
            else
                screen = [[NSScreen screens] objectAtIndex:0];
            break;
            
        case 2:		// use all screens
            screen = [[NSScreen screens] objectAtIndex:0];
            break;
    }
    
    NSRect screenRect = [AppController usefullRectForScreen: screen];
    
    [[self window] setFrame:screenRect display:YES];
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"WINDOWSIZEVIEWER"])
    {
        case 0:	[self setWindowFrame:screenRect showWindow: NO]; break;
        case 1:	[imageView resizeWindowToScale: 1.0]; break;
        case 2:	[imageView resizeWindowToScale: 1.5]; break;
        case 3:	[imageView resizeWindowToScale: 2.0]; break;
    }
    
    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    {
        if( v != self)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt: v.imageView.currentTool], @"toolIndex", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDefaultToolModifiedNotification object:nil userInfo: userInfo];
            
            break;
        }
    }
}

- (void) startLoadImageThread
{
    if( windowWillClose) return;
    
    originalOrientation = -1;
    
    @synchronized( loadingThread)
    {
        [loadingThread cancel];
        [loadingThread autorelease];
        loadingThread = nil;
    }
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    NSMutableArray *volumeDataArray = [NSMutableArray array];
    NSMutableArray *pixListArray = [NSMutableArray array];
    NSMutableArray *fileListArray = [NSMutableArray array];
    for( int z = 0; z < maxMovieIndex; z++)
    {
        [volumeDataArray addObject: volumeData[ z]];
        [pixListArray addObject: pixList[ z]];
        [fileListArray addObject: fileList[ z]];
    }
    
    [d setObject: volumeDataArray forKey: @"volumeDataArray"];
    [d setObject: pixListArray forKey: @"pixListArray"];
    [d setObject: fileListArray forKey: @"fileListArray"];
    [d setObject: self forKey: @"viewerController"];
    
    NSThread *tempThread = [[NSThread alloc] initWithTarget: [ViewerController class] selector: @selector(loadImageData:) object: d];
    @synchronized( tempThread)
    {
        loadingThread = tempThread;
        [loadingThread start];
    }
    
    [self setWindowTitle:self];
}

- (BOOL) subtractionActivated
{
    return [subCtrlOnOff state];
}

- (void) computeSubCtrlMinMax
{
    if( subCtrlMinMaxComputed) return;
    
    subCtrlMinMaxComputed = YES;
    
    //define min and max value of the subtraction
    long subCtrlMin = 1024;
    long subCtrlMax = 0;
    
    DCMPix *pixMask = [[imageView dcmPixList]objectAtIndex:subCtrlMaskID];
    
    for( DCMPix *pix in [imageView dcmPixList])
    {
        subCtrlMinMax = [pix subMinMax :[pix fImage] :[pixMask fImage]];
        
        if( subCtrlMinMax.x < subCtrlMin) subCtrlMin = subCtrlMinMax.x ;
        if( subCtrlMinMax.y > subCtrlMax) subCtrlMax = subCtrlMinMax.y ;
    }
    subCtrlMinMax.x = subCtrlMin;
    subCtrlMinMax.y = subCtrlMax;
}

- (void) enableSubtraction
{
    if( enableSubtraction)
    {
        [subCtrlOnOff setEnabled: YES];
        
        subCtrlMaskID = 1;
        [subCtrlMaskText setStringValue: [NSString stringWithFormat:@"2"]];//changes tool text
        
        subCtrlMinMaxComputed = NO;
    }
    else [subCtrlOnOff setEnabled: NO];
}

//-(void) loadThread:(DCMPix*) pix
//{
//	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
//
//	[pix CheckLoad];
//
//	[processorsLock lock];
//	if( numberOfThreadsForRelisce >= 0) numberOfThreadsForRelisce--;
//	[processorsLock unlockWithCondition: 1];
//
//	[pool release];
//}

- (void) resampleDataIfNeeded:(id) sender
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ResampleData"])
    {
        int height = [[pixList[ 0] objectAtIndex: 0] pheight];
        int width = [[pixList[ 0] objectAtIndex: 0] pwidth];
        int minimumValue = [[NSUserDefaults standardUserDefaults] integerForKey: @"ResampleDataIfSmallerOrEqualValue"];
        float destinationValue = [[NSUserDefaults standardUserDefaults] floatForKey: @"ResampleDataValue"];
        
        if( width <= minimumValue || height <= minimumValue)
        {
            float ratio;
            
            if( width < height) ratio = width / destinationValue ;
            else ratio = height / destinationValue ;
            
            if( ratio > 0)
            {
                float s = [imageView scaleValue];
                if( [self resampleDataWithXFactor:ratio yFactor:ratio zFactor:1.0])
                    [imageView setScaleValue: s * ratio];
            }
        }
    }
    
    [pool release];
}


+ (BOOL) areLoadingViewers
{
    for( ViewerController *v in [ViewerController get2DViewers])
    {
        if( [v isEverythingLoaded] == NO)
            return YES;
    }
    return NO;
}

- (void) finishLoadImageData: (NSDictionary*) dict
{
    @synchronized( loadingThread)
    {
        if (requestLoadingCancel)
            return;
        
        if( [[dict objectForKey: @"pixListArray"] objectAtIndex: 0] != pixList[ 0])
        {
            [loadingThread cancel];
            [loadingThread autorelease];
            loadingThread = nil;
            
            return;
        }
        
        NSArray *pixListArray = [dict objectForKey: @"pixListArray"];
        DCMPix *firstPix = [[pixListArray objectAtIndex: 0] objectAtIndex: 0];
        
#pragma mark modality dependant code, once images are already displayed in 2D viewer
        
        for( NSArray *pList in pixListArray)
        {
            for( DCMPix *p in pList)
            {
                [p setMaxValueOfSeries: 0];
                [p setMinValueOfSeries: 0];
            }
        }
        
#pragma mark XA
        enableSubtraction = FALSE;
        subCtrlMinMaxComputed = NO;
        if([[firstPix modalityString] isEqualToString:@"XA"])
        {
            if([[pixListArray objectAtIndex: 0] count] > 1)
            {
                long moviePixWidth = [firstPix pwidth];
                long moviePixHeight = [firstPix pheight];
                
                enableSubtraction = TRUE;
                //if (moviePixWidth == moviePixHeight) enableSubtraction = TRUE;
                
                for( DCMPix *pix in [pixListArray objectAtIndex: 0])
                {
                    if ( moviePixWidth != [pix pwidth]) enableSubtraction = FALSE;
                    if ( moviePixHeight != [pix pheight]) enableSubtraction = FALSE;
                }
            }
        }
        
        [self enableSubtraction];
        
#pragma mark PET
        
        BOOL isPET = NO;
        
        if( [[firstPix modalityString] isEqualToString: @"PT"])
            isPET = YES;
        
        if( isPET || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[firstPix modalityString] isEqualToString:@"NM"]))
        {
            if( [[NSUserDefaults standardUserDefaults] integerForKey:@"DEFAULTPETWLWW"] != 0)
                [imageView updatePresentationStateFromSeries];
        }
        
        if( isPET)
        {
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ConvertPETtoSUVautomatically"])
            {
                [self convertPETtoSUV];
                [imageView setStartWLWW];
            }
        }
        
        if( firstPix.shutterEnabled)
            [self setShutterOnOffButton: [NSNumber numberWithBool: YES]];
        
        [self setWindowTitle:self];
        
        originalOrientation = -1;
        [self computeIntervalAsync];
        
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:OsirixViewerControllerDidLoadImagesNotification object:self]];
        
        ///////
        
        [loadingThread cancel];
        [loadingThread autorelease];
        loadingThread = nil;
    }
}


- (double) computeOriginalOrientation
{
    if( [pixList[ curMovieIndex] count] <= 2)
        return 0.0;
    
    double vectors[ 9], vectorsB[ 9];
    BOOL equalVector = YES;
    
    [[pixList[ curMovieIndex] objectAtIndex:1] orientationDouble: vectors];
    [[pixList[ curMovieIndex] objectAtIndex:2] orientationDouble: vectorsB];
    
    for( int i = 0; i < 9; i++)
    {
        const double epsilon = fabs(vectors[ i] - vectorsB[ i]);
        if (epsilon > ORIENTATION_SENSIBILITY)
        {
            equalVector = NO;
            break;
        }
    }
    
    double interval = 0;
    BOOL equalZero = YES;
    
    for( int i = 0; i < 9; i++)
    {
        if( vectors[ i] != 0) { equalZero = NO; break;}
        if( vectorsB[ i] != 0) { equalZero = NO; break;}
    }
    
    if( equalVector == YES && equalZero == NO)
    {
        if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
        {
            interval = [[pixList[curMovieIndex] objectAtIndex:1] originX] - [[pixList[curMovieIndex] objectAtIndex:2] originX];
            
            if( vectors[6] > 0)
            {
                interval = -interval;
                orientationVector = eSagittalPos;
            }
            else orientationVector = eSagittalNeg;
            currentOrientationTool = 2;
        }
        
        if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
        {
            interval = [[pixList[curMovieIndex] objectAtIndex:1] originY] - [[pixList[curMovieIndex] objectAtIndex:2] originY];
            
            if( vectors[7] > 0)
            {
                interval = -interval;
                orientationVector = eCoronalPos;
            }
            else orientationVector = eCoronalNeg;
            currentOrientationTool = 1;
        }
        
        if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
        {
            interval = [[pixList[curMovieIndex] objectAtIndex:1] originZ] - [[pixList[curMovieIndex] objectAtIndex:2] originZ];
            
            if( vectors[8] > 0)
            {
                interval = -interval;
                orientationVector = eAxialPos;
            }
            else orientationVector = eAxialNeg;
            currentOrientationTool = 0;
        }
        
        if( originalOrientation == -1)
            originalOrientation = currentOrientationTool;
    }
    
    return interval;
}

+ (void) loadImageData:(id) dict
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSLog( @"start loading");
    
    @autoreleasepool
    {
//        int i, x;
        BOOL compressed = NO;
        
        NSArray *pixListArray = [dict objectForKey: @"pixListArray"];
//        NSArray *fileListArray = [dict objectForKey: @"fileListArray"];
//        NSArray *volumeDataArray = [dict objectForKey: @"volumeDataArray"];
        ViewerController *viewer = [dict objectForKey: @"viewerController"];
        
        [NSThread currentThread].name = @"Load Image Data";
        
        @try {
            DCMPix *firstPix = [[pixListArray objectAtIndex: 0] objectAtIndex: 0];
            
            [DicomFile isDICOMFile: [firstPix srcFile] compressed: &compressed];
            
            if( compressed)
                if( [BrowserController isItCD: [firstPix srcFile]]) //Always Single thread for CD/DVD
                    compressed = NO;
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        
        int maxPix = 0;
        int count = 0;
        
        for( NSArray *a in pixListArray)
            maxPix += a.count;
        
        if( compressed == NO)
        {
            NSTimeInterval lastSet = 0;
            
            for( NSArray *a in pixListArray)
            {
                for( DCMPix *p in a)
                {
                    [p CheckLoad];
                    
                    float percentage = (float) ++count / (float) maxPix;
                    
                    if( [NSDate timeIntervalSinceReferenceDate] - lastSet > 0.3)
                    {
                        BOOL isExecuting = YES;
                        @synchronized( viewer->loadingThread)
                        {
                            isExecuting = ([viewer->loadingThread isExecuting] && viewer->requestLoadingCancel == NO);
                        }
                        
                        if (isExecuting)
                        {
                            @synchronized( [NSThread currentThread])
                            {
                                [[NSThread currentThread].threadDictionary setObject: [NSNumber numberWithFloat: percentage] forKey: @"loadingPercentage"];
                            }
                        }
                        else
                        {
                            [NSThread currentThread].progress = -1;
                            [NSThread currentThread].status = NSLocalizedString( @"Cancelling...", nil);
                            break;
                        }
                        
                        lastSet = [NSDate timeIntervalSinceReferenceDate];
                    }
                }
            }
        }
        else
        {
            NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
            
            static int mpprocessors = 0;
            if( mpprocessors == 0)
            {
                mpprocessors = [[NSProcessInfo processInfo] processorCount];
                NSLog( @"[[NSProcessInfo processInfo] processorCount]: %d", mpprocessors);
                if( mpprocessors < 1)
                    mpprocessors = 1;
                
                if( mpprocessors > 4)
                    mpprocessors --;
            }
            
            queue.maxConcurrentOperationCount = mpprocessors;
            
            BOOL isExecuting = YES;
            @synchronized( viewer->loadingThread)
            {
                isExecuting = ([viewer->loadingThread isExecuting] && viewer->requestLoadingCancel == NO);
            }
            
            while(isExecuting && viewer.window.isVisible == NO)
            {
                [NSThread sleepForTimeInterval: 0.01];
                @synchronized( viewer->loadingThread)
                {
                    isExecuting = [viewer->loadingThread isExecuting];
                }
            }
            
            for( NSArray *a in pixListArray)
            {
                for( DCMPix *p in a)
                {
                    @synchronized( viewer->loadingThread)
                    {
                        isExecuting = ([viewer->loadingThread isExecuting] && [viewer->loadingThread isCancelled] == NO);
                    }
                    
                    if (isExecuting)
                    {
                        [queue addOperationWithBlock: ^{
                            [p CheckLoadFromThread:viewer->loadingThread];
                        }];
                    }
                }
            }
            
            @synchronized( viewer->loadingThread)
            {
                isExecuting = [viewer->loadingThread isExecuting];
            }
            
            while (queue.operationCount && isExecuting)
            {
                @synchronized( viewer->loadingThread)
                {
                    isExecuting = [viewer->loadingThread isExecuting];
                }
                
                if(!isExecuting)
                {
                    [NSThread currentThread].progress = -1;
                    [NSThread currentThread].status = NSLocalizedString( @"Cancelling...", nil);
                    [queue cancelAllOperations];
                    break;
                }
                else
                {
                    float percentage = (float) queue.operationCount / (float) maxPix;
                    @synchronized( [NSThread currentThread])
                    {
                        [[NSThread currentThread].threadDictionary setObject: [NSNumber numberWithFloat: 1.0 - percentage] forKey: @"loadingPercentage"];
                    }
                    [NSThread sleepForTimeInterval:0.1];
                }
            }
            
            [queue waitUntilAllOperationsAreFinished];
        }
        
        BOOL isExecuting = YES;
        @synchronized( viewer->loadingThread)
        {
            isExecuting = ([viewer->loadingThread isExecuting] && viewer->requestLoadingCancel == NO);
        }
        
        if(!isExecuting)
        {
            [NSThread sleepForTimeInterval: 0.2];
            NSLog( @"Load Image Thread exiting");
        }
        
        @synchronized( viewer->loadingThread)
        {
            isExecuting = [viewer->loadingThread isExecuting];
        }
        
        if (isExecuting)
        {
            @synchronized( [NSThread currentThread])
            {
                [[NSThread currentThread].threadDictionary setObject: [NSNumber numberWithFloat: 1.0] forKey: @"loadingPercentage"];
            }
            
            [viewer computeOriginalOrientation];
            [viewer performSelectorOnMainThread: @selector(finishLoadImageData:) withObject: dict waitUntilDone: NO];
        }
        else
        {
            return;
        }
    }
    
    NSLog( @"end loading: %f [s]", [NSDate timeIntervalSinceReferenceDate] - start);
}

- (short) getNumberOfImages
{
    return [pixList[curMovieIndex] count];
}

-(short) maxMovieIndex { return maxMovieIndex;}


- (void) CloseViewerNotification: (NSNotification*) note
{
    if([note object] == blendingController) // our blended serie is closing itself....
    {
        [self ActivateBlending: nil];
    }
    
    if( [[self window] isMainWindow] || [[self window] isKeyWindow])
    {
        [self refreshToolbar];
    }
}

- (void)updateImageView:(NSNotification *)note
{
    if ([[self window] isEqual:[[note object] window]])
    {
        [imageView release];
        imageView = [[note object] retain];
        
        if( [imageView columns] != 1 || [imageView rows] != 1)
            [imageView updateTilingViews];
    }
}

-(IBAction) calibrate:(id) sender
{
    NSInteger result = NSRunCriticalAlertPanel( NSLocalizedString( @"Warning !", nil), NSLocalizedString( @"Modifying these parameters will:\r\r- Change the measurements results (length, surface, volume, ...)\r-Change the orientation of the slices and of the 3D objects (Left, Right, ...)\r-Change the aspect of the 3D images. It can introduce distortions.\r\rONLY change these parameters if you know WHAT and WHY you are doing it.", nil), NSLocalizedString( @"I agree", nil), NSLocalizedString( @"Cancel", nil), nil);
    
    if( result == NSAlertDefaultReturn)
    {
        [self computeInterval];
        [self SetThicknessInterval:sender];
    }
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


#pragma mark 4.1.1. DICOM pipeline

#pragma mark 4.1.1.1 Filters


// filter from plugin
- (void)executeFilterFromString:(NSString*)name {
    [self executeFilterFromBundle:nil title:name];
}

- (void)executeFilterFromBundle:(NSBundle*)bundle title:(NSString*)name
{
    long			result;
    id				filter = nil;
    
    if (bundle) {
        
    } else
        filter = [[PluginManager plugins] objectForKey:name];
    
    if( [AppController willExecutePlugin: filter] == NO)
        return;
    
    if( filter == nil)
    {
        NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
        return;
    }
    
    [self checkEverythingLoaded];
    [self computeInterval];
    
    [imageView stopROIEditingForce: YES];
    
    [PluginManager startProtectForCrashWithFilter: filter];
    
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_PLUGIN_LAUNCHED detail:[NSString stringWithFormat:@"{\"PluginName\": \"%@\"}",name]];
    
    NSLog( @"executeFilter");
    
    @try
    {
        result = [filter prepareFilter: self];
        if( result)
        {
            NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
            [PluginManager endProtectForCrash];
            
            return;
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
        NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
        [PluginManager endProtectForCrash];
        
        return;
    }
    
    @try
    {
        result = [filter filterImage: name];
        if( result)
        {
            NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot apply the selected plugin.", nil), nil, nil, nil);
            [PluginManager endProtectForCrash];
            
            return;
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
        NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
    }
    
    [PluginManager endProtectForCrash];
    
    [imageView roiSet];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRecomputeROINotification object:self userInfo: nil];
}


- (void)executeFilter:(id)sender
{
    [self executeFilterFromString: [sender title]];
}

- (void) executeFilterFromToolbar:(id) sender
{
    [self executeFilterFromString: [sender label]];
}

#pragma mark resample image

- (IBAction)resampleDataBy2:(id)sender;
{
    id waitWindow = [self startWaitWindow: NSLocalizedString( @"Resampling data...", nil)];
    BOOL isResampled = [self resampleDataBy2];
    [self endWaitWindow: waitWindow];
    if(!isResampled)
    {
        if( NSRunAlertPanel(NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"Cannot complete the resampling\r\rUpgrade to OsiriX 64-bit or OsiriX MD to solve this issue.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
            [[AppController sharedAppController] osirix64bit: self];
    }
}

- (BOOL)resampleDataBy2;
{
    return [self resampleDataWithFactor:2.0];
}

- (BOOL)resampleDataWithFactor:(float)factor;
{
    return [self resampleDataWithXFactor:factor yFactor:factor zFactor:factor];
}

- (BOOL)resampleDataWithXFactor:(float)xFactor yFactor:(float)yFactor zFactor:(float)zFactor;
{
    [self checkEverythingLoaded];
    [imageView stopROIEditingForce: YES];
    
    NSMutableArray *xPix = [NSMutableArray array];
    NSMutableArray *xFiles = [NSMutableArray array];
    NSMutableArray *xData = [NSMutableArray array];
    
    BOOL wasDataFlipped = [imageView flippedData];
    int index = [imageView curImage];
    BOOL isResampled = YES;
    
    NSMutableArray *savedROIs[ MAX4D];
    
    for( int j = 0 ; j < maxMovieIndex && isResampled == YES ; j ++)
    {
        NSMutableArray *newPixList = [NSMutableArray array];
        NSMutableArray *newDcmList = [NSMutableArray array];
        NSData *newData = nil;
        
        savedROIs[ j] = [NSMutableArray array];
        
        for( NSArray *r in roiList[ j])
            [savedROIs[ j] addObject: [NSArchiver archivedDataWithRootObject: r]];
        
        isResampled = [ViewerController resampleDataFromViewer:self inPixArray:newPixList fileArray:newDcmList data:&newData withXFactor:xFactor yFactor:yFactor zFactor:zFactor movieIndex: j];
        
        if( isResampled)
        {
            [xPix addObject: newPixList];
            [xFiles addObject: newDcmList];
            [xData addObject: newData];
            postprocessed = YES;
        }
    }
    
    if( isResampled)
    {
        resampleRatio = xFactor;
        
        int mx = maxMovieIndex;
        for( int j = 0 ; j < mx ; j ++)
        {
            if( j == 0)
                [self changeImageData: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j] :NO];
            else
                [self addMovieSerie: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j]];
        }
        
        [self setPostprocessed: YES];
        
        [self computeInterval];
        [self setWindowTitle:self];
        
        if( wasDataFlipped) [self flipDataSeries: self];
        
        [imageView setIndex: index];
        [imageView sendSyncMessage: 0];
        
        [self adjustSlider];
        
        for( int j = 0 ; j < maxMovieIndex; j ++)
        {
            
            for( int x = 0 ; x < [pixList[ j] count] ; x++)
            {
                int index = (x * [savedROIs[ j] count]) / [pixList[ j] count];
                
                if( index >= [savedROIs[ j] count]) index = (long)[savedROIs[ j] count] -1;
                
                NSData *r = [savedROIs[ j] objectAtIndex: index];
                
                [[roiList[ j] objectAtIndex: x] addObjectsFromArray: [NSUnarchiver unarchiveObjectWithData: r]];
                
                for( ROI *r in [roiList[ j] objectAtIndex: x])
                    [r setOriginAndSpacing :[imageView curDCM].pixelSpacingX : [imageView curDCM].pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: [imageView curDCM]]];	//NSMakePoint( [imageView curDCM].originX, [imageView curDCM].originY)];
            }
        }
        [imageView roiSet];
        [imageView setScaleValue: [imageView scaleValue] * xFactor];
    }
    
    return isResampled;
}

+ (BOOL)resampleDataFromViewer:(ViewerController *)aViewer inPixArray:(NSMutableArray*)aPixList fileArray:(NSMutableArray*)aFileList data:(NSData**)aData withXFactor:(float)xFactor yFactor:(float)yFactor zFactor:(float)zFactor;
{
    return [ViewerController resampleDataFromViewer:(ViewerController *)aViewer inPixArray:(NSMutableArray*)aPixList fileArray:(NSMutableArray*)aFileList data:(NSData**)aData withXFactor:(float)xFactor yFactor:(float)yFactor zFactor:(float)zFactor movieIndex: 0];
}

+ (BOOL)resampleDataFromViewer:(ViewerController *)aViewer inPixArray:(NSMutableArray*)aPixList fileArray:(NSMutableArray*)aFileList data:(NSData**)aData withXFactor:(float)xFactor yFactor:(float)yFactor zFactor:(float)zFactor movieIndex:(int) j;
{
    [aViewer setPostprocessed: YES];
    
    BOOL result =  [ViewerController resampleDataFromPixArray:[aViewer pixList: j] fileArray:[aViewer fileList: j] inPixArray:aPixList fileArray:aFileList data:aData withXFactor:xFactor yFactor:yFactor zFactor:zFactor];
    
    return result;
}

+ (BOOL)resampleDataFromPixArray:(NSArray *)originalPixlist fileArray:(NSArray*)originalFileList inPixArray:(NSMutableArray*)aPixList fileArray:(NSMutableArray*)aFileList data:(NSData**)aData withXFactor:(float)xFactor yFactor:(float)yFactor zFactor:(float)zFactor;
{
    NSLog( @"resampleDataFromPixArray - factor : %f", xFactor);
    
    long				i, y, z;
    unsigned long long	size, newX, newY, newZ, imageSize;
    float				*srcImage, *dstImage, *emptyData;
    DCMPix				*curPix;
    
    int originWidth = [[originalPixlist objectAtIndex:0] pwidth];
    int originHeight = [[originalPixlist objectAtIndex:0] pheight];
    int originZ = [originalPixlist count];
    float sliceInterval = [[originalPixlist objectAtIndex:0] sliceInterval];
    
    if( sliceInterval == 0)
    {
        NSLog( @"NOT A VOLUMIC SERIES: sliceInterval == 0. Cannot resample in Z direction");
        zFactor = 1.0;
    }
    
    newX = (unsigned long long)((float)originWidth / xFactor + 0.5);
    newY = (unsigned long long)((float)originHeight / yFactor + 0.5);
    newZ = (unsigned long long)((float)originZ / zFactor + 0.5);
    
    if( newZ <= 0) newZ = 1;
    if( originZ == 1) newZ = 1;
    
    if( sliceInterval == 0) newZ = originZ;
    
    int maxZ = originZ;
    if( maxZ < newZ) maxZ = newZ;
    
    imageSize = newX * newY;
    size = sizeof(float) * maxZ * imageSize;
    
    emptyData = malloc( size);		// Just to be sure we have enough memory to play with them !
    
    if( emptyData)
    {
        float vectors[ 9], vectorsB[ 9], interval = 0, origin[ 3], newOrigin[ 3];
        BOOL equalVector = YES;
        int o;
        
        if( [originalPixlist count] > 1)
        {
            DCMPix	*firstObject = [originalPixlist objectAtIndex:0];
            DCMPix	*secondObject = [originalPixlist objectAtIndex:1];
            
            [firstObject orientation: vectors];
            [secondObject orientation: vectorsB];
            
            origin[ 0] = [firstObject originX];
            origin[ 1] = [firstObject originY];
            origin[ 2] = [firstObject originZ];
            
            // DICOM Origin is the CENTER of the first pixel !
            
            origin[ 0] -= firstObject.pixelSpacingX/2.;
            origin[ 1] -= firstObject.pixelSpacingY/2.;
            origin[ 2] -= firstObject.sliceThickness/2.;
            
            for( i = 0; i < 9; i++)
            {
                if( vectors[ i] != vectorsB[ i]) equalVector = NO;
            }
            
            if( equalVector)
            {
                if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
                {
                    interval = [secondObject originX] - [firstObject originX];
                    
                    o = 0;
                }
                
                if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
                {
                    interval = [secondObject originY] - [firstObject originY];
                    
                    o = 1;
                }
                
                if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
                {
                    interval = [secondObject originZ] - [firstObject originZ];
                    
                    o = 2;
                }
            }
        }
        
        interval *= (float) zFactor;
        
        NSMutableArray	*newPixList = [NSMutableArray array];
        NSData *newData = [NSData dataWithBytesNoCopy:emptyData length:size freeWhenDone:YES];
        
        for( z = 0 ; z < newZ; z ++)
        {
            curPix = [originalPixlist objectAtIndex: (z * originZ) / newZ];
            
            DCMPix	*copyPix = [curPix copy];
            
            [newPixList addObject: copyPix];
            
            [copyPix setPwidth: newX];
            [copyPix setPheight: newY];
            
            [copyPix setfImage: (float*) (emptyData + imageSize * z)];
            [copyPix setTot: newZ];
            [copyPix setFrameNo: z];
            [copyPix setID: z];
            
            [copyPix setPixelSpacingX: [curPix pixelSpacingX] * xFactor];
            [copyPix setPixelSpacingY: [curPix pixelSpacingY] * yFactor];
            [copyPix setSliceThickness: [curPix sliceThickness] * zFactor];
            [copyPix setPixelRatio:  [curPix pixelRatio] / xFactor * yFactor];
            
            newOrigin[ 0] = origin[ 0];	newOrigin[ 1] = origin[ 1];	newOrigin[ 2] = origin[ 2];
            
            switch( o)
            {
                case 0:
                    newOrigin[ 0] = origin[ 0] + (float) z * interval;
                    break;
                    
                case 1:
                    newOrigin[ 1] = origin[ 1] + (float) z * interval;
                    break;
                    
                case 2:
                    newOrigin[ 2] = origin[ 2] + (float) z * interval;
                    break;
            }
            
            newOrigin[ 0] += copyPix.pixelSpacingX/2.;
            newOrigin[ 1] += copyPix.pixelSpacingY/2.;
            newOrigin[ 2] += copyPix.sliceThickness/2.;
            
            [copyPix setOrigin: newOrigin];
            
            [copyPix computeSliceLocation];
            
            [copyPix setSliceInterval: 0];
            
            [copyPix release];	// It's added to the newPixList array
        }
        
        // X - Y RESAMPLING
        
        if( originHeight != newY || originWidth != newX)
        {
            for( z = 0; z < originZ; z++)
            {
                vImage_Buffer	srcVimage, dstVimage;
                
                curPix = [originalPixlist objectAtIndex: z];
                
                srcImage = [curPix fImage];
                dstImage = emptyData + imageSize * z;
                
                srcVimage.data = srcImage;
                srcVimage.height =  originHeight;
                srcVimage.width = originWidth;
                srcVimage.rowBytes = originWidth*4;
                
                dstVimage.data = dstImage;
                dstVimage.height =  newY;
                dstVimage.width = newX;
                dstVimage.rowBytes = newX*4;
                
                if( [curPix isRGB])
                    vImageScale_ARGB8888( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
                else
                    vImageScale_PlanarF( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
            }
        }
        else
        {
            memcpy( emptyData, [[originalPixlist objectAtIndex: 0] fImage], originHeight * originWidth * 4 * originZ);
        }
        
        // Z RESAMPLING
        
        if( sliceInterval != 0)
        {
            if( originZ != newZ)
            {
                curPix = [newPixList objectAtIndex: 0];
                
                for( y = 0; y < newY; y++)
                {
                    vImage_Buffer	srcVimage, dstVimage;
                    
                    srcImage = [curPix  fImage] + y * newX;
                    dstImage = emptyData + y * newX;
                    
                    srcVimage.data = srcImage;
                    srcVimage.height =  originZ;
                    srcVimage.width = newX;
                    srcVimage.rowBytes = newY*newX*4;
                    
                    dstVimage.data = dstImage;
                    dstVimage.height =  newZ;
                    dstVimage.width = newX;
                    dstVimage.rowBytes = newY*newX*4;
                    
                    if( [curPix isRGB])
                        vImageScale_ARGB8888( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
                    else
                        vImageScale_PlanarF( &srcVimage, &dstVimage, nil, kvImageHighQualityResampling);
                }
            }
        }
        
        for( z = 0 ; z < newZ; z ++)
        {
            [aFileList addObject: [originalFileList objectAtIndex: (z * originZ) / newZ]];
            [aPixList addObject: [newPixList objectAtIndex: z]];
            
            [[aPixList lastObject] setArrayPix: aPixList :z];
            [[aPixList lastObject] setID: z];
        }
        *aData = newData;
        return YES;
    }
    
    return NO;
}

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

#pragma mark 4.1.1.2. Mask Subtraction
// These methods are enabled only if enableSubtraction
//(which is calculated in ViewerController -(void) loadImageData:(id) sender)
// is set to TRUE

- (IBAction) subCtrlOnOff:(id) sender
{
    [self checkEverythingLoaded];
    
    if (enableSubtraction)
    {
        //asked from menu (tag=0) or keyboard (tag=15 => asked from button)
        if( [sender tag] == 0) [subCtrlOnOff setState: ![subCtrlOnOff state]]; //"on"
        
        long i;
        
        [self computeSubCtrlMinMax];
        
        if([subCtrlOnOff state])			// subtraction asked for
        {
            [self checkView: subCtrlView :YES];
            
            [imageView setWLWW:128 :256];
            
            for ( i = 0; i < [[imageView dcmPixList] count]; i ++)
            {
                [[[imageView dcmPixList]objectAtIndex:i] setSubtractedfImage:[[[imageView dcmPixList]objectAtIndex:subCtrlMaskID]fImage] :subCtrlMinMax];
            }
        }
        else //without subtraction
        {
            for ( i = 0; i < [[imageView dcmPixList] count]; i ++)
            {
                [[[imageView dcmPixList] objectAtIndex:i]	setSubtractedfImage:nil :subCtrlMinMax];
            }
            
            [imageView setWLWW:0 :0];
            
            [self checkView: subCtrlView :NO];
            [subCtrlOnOff setEnabled: YES];
        }
        
        [self subSumSlider: nil];
        
        [imageView setIndex: [imageView curImage]]; //refresh viewer only
    }
    else
    {
        NSRunAlertPanel(NSLocalizedString(@"Subtraction", nil), NSLocalizedString(@"Subtraction works only for XA modality.", nil), nil, nil, nil);
        [subCtrlOnOff setState: NSOffState];
    }
}

- (IBAction) subCtrlNewMask:(id) sender
{
    if (enableSubtraction)
    {
        [self computeSubCtrlMinMax];
        
        if( [imageView flippedData]) subCtrlMaskID = [pixList[ curMovieIndex] count] - [imageView curImage] -1;
        else                         subCtrlMaskID = [imageView curImage];//starts at 1;
        
        [subCtrlMaskText setStringValue: [NSString stringWithFormat:@"%d", (int) (subCtrlMaskID+1)]];//changes tool text
        
        //---------------------------------------define min value of the subtraction
        long subCtrlMin = 1024;
        long subCtrlMax = 0;
        long i;
        float newMaskTime = [[[imageView dcmPixList] objectAtIndex:subCtrlMaskID]fImageTime];
        for ( i = 0; i < [[imageView dcmPixList] count]; i ++)
        {
            subCtrlMinMax = [[[imageView dcmPixList]objectAtIndex:i]   subMinMax:[[[imageView dcmPixList]objectAtIndex:i]fImage]
                                                                                :[[[imageView dcmPixList]objectAtIndex:subCtrlMaskID]fImage]
                             ];
            if (subCtrlMinMax.x < subCtrlMin) subCtrlMin = subCtrlMinMax.x ;
            if (subCtrlMinMax.y > subCtrlMax) subCtrlMax = subCtrlMinMax.y ;
            
            [[[imageView dcmPixList] objectAtIndex:i] maskID: subCtrlMaskID];
            [[[imageView dcmPixList] objectAtIndex:i] maskTime: newMaskTime];
        }
        subCtrlMinMax.x = subCtrlMin;
        subCtrlMinMax.y = subCtrlMax;
        
        [subCtrlOnOff setState: NSOnState]; //"on"
        [self subCtrlOnOff: subCtrlOnOff];//subtracts
    }
}

- (IBAction) subCtrlOffset:(id) sender
{
    if( enableSubtraction)
    {
        if ([subCtrlOnOff state] == NSOnState) //only when in subtraction mode
        {
            subCtrlOffset = [[[imageView dcmPixList] objectAtIndex:[imageView curImage]] subPixOffset];
            
            NSLog( @"subPixOffset before x: %2.2f y: %2.2f", subCtrlOffset.x, subCtrlOffset.y);
            
            switch( [sender tag]) //same tags in the main menu and in the subtraction tool
            {
                case 1://SW
                    --subCtrlOffset.x;
                    --subCtrlOffset.y;
                    break;
                    
                case 2://S
                    --subCtrlOffset.y;
                    break;
                    
                case 3://SE
                    ++subCtrlOffset.x;
                    --subCtrlOffset.y;
                    break;
                    
                case 4://W
                    --subCtrlOffset.x;
                    break;
                    
                case 5://No Pixel shift
                    subCtrlOffset.x = 0;
                    subCtrlOffset.y = 0;
                    break;
                    
                case 6://E
                    ++subCtrlOffset.x;
                    break;
                    
                case 7://NW
                    --subCtrlOffset.x;
                    ++subCtrlOffset.y;
                    break;
                    
                case 8://N
                    ++subCtrlOffset.y;
                    break;
                    
                case 9://NE
                    ++subCtrlOffset.x;
                    ++subCtrlOffset.y;
                    break;
            }
        }
        
        if ((subCtrlOffset.x > -30) && (subCtrlOffset.x < 30) && (subCtrlOffset.y > -30) && (subCtrlOffset.y < 30))
        {
            for(int i = 0; i < [[imageView dcmPixList] count]; i ++)
                [[[imageView dcmPixList] objectAtIndex:i] setSubPixOffset: subCtrlOffset];
            
            [self offsetMatrixSetting:([self threeTestsFivePosibilities: (int)subCtrlOffset.y] * 5) + [self threeTestsFivePosibilities: (int)subCtrlOffset.x]];
            
            [imageView setIndex:[imageView curImage]];
        }
    }
}

- (int) threeTestsFivePosibilities: (int) f
{
    //  -2  -1  0  1  2
    //   0   1  4  2  3
    if (f == 0) return 4;
    else
    {
        if (abs(f) > 1)
        {
            if (f > 1) return 3;
            else return 0;
        }
        else
        {
            if (f == 1) return 2;
            else return 1;
        }
    }
}

- (void) offsetMatrixSetting: (int) twentyFiveCodes
{
    switch(twentyFiveCodes)
    {
            // On stronger than Off
            //----------------------------------------------------------------------------------  y=-2
        case 0://x=-2 (On On Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOffState];	//Off
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];	//On
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];	//On
            break;
        case 1://x=-1 (On Off Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOffState];	[sc9 setState: NSOffState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            break;
        case 4:// x=0 (Off Off Off)
            [sc7 setState: NSOffState];	[sc8 setState: NSOffState];	[sc9 setState: NSOffState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            break;
        case 2://x=1
            [sc7 setState: NSOffState];	[sc8 setState: NSOffState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            break;
        case 3:// x=2
            [sc7 setState: NSOffState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            
            break;//------------------------------------------------------------------------------y=-1
        case 5://x=-2 (On On Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOffState];	//Off
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOffState];	//Off
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];	//On
            break;
        case 6://x=-1 (On Off Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOffState];	[sc9 setState: NSOffState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOffState];	[sc6 setState: NSOffState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            break;
        case 9:// x=0 (Off Off Off)
            [sc7 setState: NSOffState];	[sc8 setState: NSOffState];	[sc9 setState: NSOffState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOffState];	[sc6 setState: NSOffState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            break;
        case 7://x=1 y=-1
            [sc7 setState: NSOffState];	[sc8 setState: NSOffState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOffState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            break;
        case 8:// x=2 y=-1
            [sc7 setState: NSOffState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            
            break;//--------------------------------------------------------------------------------y=0
        case 20://x=-2 (On On Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOffState];	//Off
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOffState];	//Off
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOffState];	//Off
            break;
        case 21://x=-1 (On Off Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOffState];	[sc9 setState: NSOffState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOffState];	[sc6 setState: NSOffState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOffState];	[sc3 setState: NSOffState];
            break;
        case 24:// x=0 (Off Off Off)
            [sc7 setState: NSOffState];	[sc8 setState: NSOffState];	[sc9 setState: NSOffState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOffState];	[sc6 setState: NSOffState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOffState];	[sc3 setState: NSOffState];
            break;
        case 22://x=1 (Off Off On)
            [sc7 setState: NSOffState];	[sc8 setState: NSOffState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOffState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOffState];	[sc3 setState: NSOnState];
            break;
        case 23:// x=2 (Off On On)
            [sc7 setState: NSOffState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            
            break;//-------------------------------------------------------------------------------y=1
        case 10://x=-2 (On On Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];	//On
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOffState];	//Off
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOffState];	//Off
            break;
        case 11://x=-1 (On Off Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOffState];	[sc6 setState: NSOffState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOffState];	[sc3 setState: NSOffState];
            break;
        case 14:// x=0 (Off Off Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOffState];	[sc6 setState: NSOffState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOffState];	[sc3 setState: NSOffState];
            break;
        case 12://x=1 (Off Off On)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOffState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOffState];	[sc3 setState: NSOnState];
            break;
        case 13:// x=2 (Off On On)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOffState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            
            break;//------------------------------------------------------------------------------ y=2
        case 15://x=-2 (On On Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];	//On
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];	//On
            [sc1 setState: NSOnState];	[sc2 setState: NSOnState];	[sc3 setState: NSOffState];	//Off
            break;
        case 16://x=-1 (On Off Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOnState];	[sc2 setState: NSOffState];	[sc3 setState: NSOffState];
            break;
        case 19:// x=0 (Off Off Off)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOffState];	[sc3 setState: NSOffState];
            break;
        case 17://x=1 (Off Off On)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOffState];	[sc3 setState: NSOnState];
            break;
        case 18:// x=2 (Off On On)
            [sc7 setState: NSOnState];	[sc8 setState: NSOnState];	[sc9 setState: NSOnState];
            [sc4 setState: NSOnState];	[sc5 setState: NSOnState];	[sc6 setState: NSOnState];
            [sc1 setState: NSOffState];	[sc2 setState: NSOnState];	[sc3 setState: NSOnState];
            break;
    }
    
}

- (IBAction) subCtrlSliders:(id) sender
{
    if( enableSubtraction)
    {
        if ([subCtrlOnOff state] == NSOnState) //only when in subtraction mode
        {
            float	cwl, cww;
            [imageView getWLWW:&cwl :&cww];
            
            switch([sender tag]) //menu shortcut
            {
                    
                    // Gamma : wl
                    // Zero : ww
                    
                case 37: [imageView setWLWW:cwl-5	:cww];			break;
                case 38: [imageView setWLWW:128		:cww];			break;
                case 39: [imageView setWLWW:cwl+5	:cww];			break;
                    
                case 34: [imageView setWLWW:cwl	:cww-5];		break;
                case 35: [imageView setWLWW:cwl	:256];			break;
                case 36: [imageView setWLWW:cwl	:cww+5];		break;
            }
            
            for(int i = 0; i < [[imageView dcmPixList] count]; i ++)
            {
                [[[imageView dcmPixList] objectAtIndex:i]	setSubSlidersPercent:	[subCtrlPercent floatValue]];
                //															gamma:					[subCtrlGamma floatValue]
                //															zero:					[subCtrlZero floatValue]];
            }
            
            //NSLog(@"percent:%f   gamma:%f  zero:%f",[subCtrlPercent floatValue],[subCtrlGamma floatValue],[subCtrlZero floatValue]);
            [imageView setIndex:[imageView curImage]]; //refresh window image
        }
    }
}

- (IBAction) subSumSlider:(id) sender
{
    switch([sender tag]) //menu shortcut
    {
        case 31: [subCtrlSum setFloatValue:[subCtrlSum floatValue]-1];	break;  //Sum - (min 1)
        case 32: [subCtrlSum setFloatValue:1];							break;
        case 33: [subCtrlSum setFloatValue:[subCtrlSum floatValue]+1];	break;  //Sum + (max 10)
    }
    [self setFusionMode: 3];
    
    [imageView setFusion:-1 :[subCtrlSum intValue]];
    
    for( int x = 0; x < maxMovieIndex; x++)
    {
        if( x != curMovieIndex) // [imageView setFusion] already did it for current serie!
        {
            for( int i = 0; i < [pixList[ x] count]; i ++)
            {
                [[pixList[ x] objectAtIndex:i] setFusion:-1 :[subCtrlSum intValue] :-1];
            }
        }
    }
    
    [stacksFusion setIntValue:[subCtrlSum intValue]];
    [sliderFusion setIntValue:[subCtrlSum intValue]];
    
    if( [subCtrlSum intValue] <= 1)
    {
        [activatedFusion setState: NSOffState];
        [sliderFusion setEnabled:NO];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:[subCtrlSum intValue] forKey:@"stackThickness"];
    
    [imageView sendSyncMessage: 0];
    
}

- (IBAction) subSharpen:(id) sender
{
    if ([sender tag] == 30) [subCtrlSharpenButton  setState: ![subCtrlSharpenButton state]];
    if ([subCtrlSharpenButton state] == NSOnState)	[self ApplyConvString:@"Sharpen 5x5"];
    else [self ApplyConvString:NSLocalizedString(@"No Filter", nil)];
}

#pragma mark-
#pragma mark 4.1.1.3. VOI LUT transformation

- (void) setCurWLWWMenu:(NSString*) s
{
    if( s != curWLWWMenu && [s isEqualToString: curWLWWMenu] == NO)
    {
        [curWLWWMenu release];
        curWLWWMenu = [s retain];
        [wlwwPopup setTitle: curWLWWMenu];
    }
}

- (IBAction) resetImage:(id) sender
{
    [self setUpdateTilingViewsValue: YES];
    
    for( DCMView *v in [seriesView imageViews])
    {
        [v setOrigin: NSMakePoint( 0, 0)];
        [v scaleToFit];
        [v setRotation: 0];
        
        [v setWLWW:[[v curDCM] savedWL] :[[v curDCM] savedWW]];
    }
    
    [self setUpdateTilingViewsValue: NO];
    
    [self selectFirstTilingView];
    [imageView updateTilingViews];
}

-(IBAction) ConvertToRGBMenu:(id) sender
{
    long	x, i;
    float	cwl, cww;
    
    [imageView getWLWW:&cwl :&cww];
    
    if( [[pixList[ curMovieIndex] objectAtIndex: 0] isRGB] == YES)
    {
        NSRunAlertPanel(NSLocalizedString(@"RGB", nil), NSLocalizedString(@"Sorry, these images are already in RGB mode", nil), nil, nil, nil);
    }
    else
    {
        for( x = 0; x < maxMovieIndex; x++)
        {
            for( i = 0; i < [pixList[ x] count]; i++)
            {
                if( [[pixList[ x] objectAtIndex: i] isRGB] == NO)
                {
                    [[pixList[ x] objectAtIndex: i] ConvertToRGB: [sender tag] :cwl :cww];
                }
            }
        }
        
        [imageView setWLWW:127 : 256];
        [imageView loadTextures];
        [imageView setNeedsDisplay:YES];
    }
}

-(IBAction) ConvertToBWMenu:(id) sender
{
    long x, i;
    
    if( [[pixList[ curMovieIndex] objectAtIndex: 0] isRGB] == NO)
    {
        NSRunAlertPanel(NSLocalizedString(@"BW", nil), NSLocalizedString(@"Sorry, these images are already in BW mode", nil), nil, nil, nil);
    }
    else
    {
        for( x = 0; x < maxMovieIndex; x++)
        {
            for( i = 0; i < [pixList[ x] count]; i++)
            {
                if( [[pixList[ x] objectAtIndex: i] isRGB] == YES)
                {
                    [[pixList[ x] objectAtIndex: i] ConvertToBW: [sender tag]];
                }
            }
        }
        
        [imageView loadTextures];
        [imageView setNeedsDisplay:YES];
    }
}

- (void) flipDataThread: (NSDictionary*) d
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    long size = [[d objectForKey: @"size"] intValue];
    char *ptr = [[d objectForKey: @"ptr"] pointerValue];
    int start = [[d objectForKey: @"start"] intValue];
    int end = [[d objectForKey: @"end"] intValue];
    int no = [[d objectForKey: @"no"] intValue];
    
    size *= 4;
    char* tempData = (char*) malloc( size);
    if( tempData)
    {
        for( int i = start; i < end; i++)
        {
            memmove( tempData, ptr + size*i, size);
            memmove( ptr + size*i, ptr + size*(no-1-i), size);
            memmove( ptr + size*(no-1-i), tempData, size);
        }
        free( tempData);
    }
    
    [flipDataThread lock];
    [flipDataThread unlockWithCondition: [flipDataThread condition]-1];
    
    [pool release];
}

- (void) flipData:(char*) ptr :(long) no :(long) x :(long) y
{
    NSLog(@"flip data");
    //	NSLog(@"flip data-A");
    
    //	long size = x*y;
    //
    //	size *= 4;
    //	char* tempData = (char*) malloc( size);
    //
    //	for( int i = 0; i < no/2; i++)
    //	{
    //		memcpy( tempData, ptr + size*i, size);
    //		memcpy( ptr + size*i, ptr + size*(no-1-i), size);
    //		memcpy( ptr + size*(no-1-i), tempData, size);
    //	}
    //	free( tempData);
    
    if( no > 50)
    {
        int mpprocessors = [[NSProcessInfo processInfo] processorCount];
        
        if( flipDataThread == nil)
            flipDataThread = [[NSConditionLock alloc] initWithCondition: 0];
        
        [flipDataThread lockWhenCondition: 0];
        [flipDataThread unlockWithCondition: mpprocessors];
        
        int no2 = no/2;
        
        NSMutableDictionary *baseDict = [NSMutableDictionary dictionary];
        
        [baseDict setObject: [NSNumber numberWithInt: x*y] forKey: @"size"];
        [baseDict setObject: [NSValue valueWithPointer: ptr] forKey: @"ptr"];
        [baseDict setObject: [NSNumber numberWithInt: no] forKey: @"no"];
        
        for( int i = 0; i < mpprocessors; i++)
        {
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary: baseDict];
            
            int from = (i * no2) / mpprocessors;
            int to = ((i+1) * no2) / mpprocessors;
            
            [d setObject: [NSNumber numberWithInt: from] forKey: @"start"];
            [d setObject: [NSNumber numberWithInt: to] forKey: @"end"];
            
            [NSThread detachNewThreadSelector: @selector(flipDataThread:) toTarget: self withObject: d];
        }
        
        [flipDataThread lockWhenCondition: 0];
        [flipDataThread unlock];
    }
    //	NSLog(@"flip data-B");
    else
    {
        vImage_Buffer src, dest;
        src.height = dest.height = no;
        src.width = dest.width = x*y;
        src.rowBytes = dest.rowBytes = x*y*4;
        src.data = dest.data = ptr;
        vImageVerticalReflect_PlanarF ( &src, &dest, 0);
    }
    //	NSLog(@"flip data-C");
}

- (IBAction) flipDataSeries: (id) sender
{
    if( windowWillClose) return;
    
    int activatedFusionState = [activatedFusion state];
    int previousFusion = [popFusion selectedTag];
    int previousCurImage = [imageView curImage];
    
    imageView.drawing = NO;
    
    [seriesView setFlippedData: ![imageView flippedData]];
    [self setFusionMode: 0];
    
    [imageView setIndex: (long)[pixList[ 0] count] -1 -previousCurImage];
    
    [self adjustSlider];
    
    [imageView sendSyncMessage: 0];
    
    if( activatedFusionState == NSOnState)
        [self setFusionMode: previousFusion];
    
    imageView.drawing = YES;
    
    [popFusion selectItemWithTag:previousFusion];
    
    [imageView sendSyncMessage: 0];
}

- (short) orthogonalOrientation
{
    float		vectors[ 9];
    
    NSArray* localPixList = [[DCMView class] cleanedOutDcmPixArray:pixList[curMovieIndex]];
    
    [[localPixList objectAtIndex:0] orientation: vectors];
    
    if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
    {
        if( vectors[6] > 0) orientationVector = eSagittalPos;
        else orientationVector = eSagittalNeg;
    }
    
    if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
    {
        if( vectors[7] > 0) orientationVector = eCoronalPos;
        else orientationVector = eCoronalNeg;
    }
    
    if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
    {
        if( vectors[8] > 0) orientationVector = eAxialPos;
        else orientationVector = eAxialNeg;
    }
    
    switch( orientationVector)
    {
        case eAxialPos:
        case eAxialNeg:
            return 0;
            break;
            
        case eCoronalNeg:
        case eCoronalPos:
            return 1;
            break;
            
        case eSagittalNeg:
        case eSagittalPos:
            return 2;
            break;
    }
    
    return 0;
}

-(short) orientationVector
{
    return orientationVector;
}

-(void) displayWarningIfGantryTitled
{
    if( titledGantry)
    {
        NSString *message = nil;
#ifdef OSIRIX_LIGHT
        message = [NSString stringWithFormat: NSLocalizedString(@"These images were acquired with a gantry tilt: %0.2f\u00B0. This gantry tilt will produce a distortion in 3D post-processing. You can use the plugin 'Gantry Tilt Correction' to convert these images.", nil), titledGantryDegrees];
        NSRunInformationalAlertPanel( NSLocalizedString(@"Warning!", nil), @"%@", NSLocalizedString(@"OK", nil), nil, nil, message);
#else
        message = [NSString stringWithFormat: NSLocalizedString(@"These images were acquired with a gantry tilt: %0.2f\u00B0. This gantry tilt will produce a distortion in 3D post-processing. Should I convert these images to a real 3D dataset.", nil), titledGantryDegrees];
        NSInteger r = NSRunInformationalAlertPanel( NSLocalizedString(@"Warning!", nil), @"%@", NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), nil, message);
        
        if( r == NSAlertDefaultReturn)
            [ViewerController correctGangtryTilt: self];
#endif
    }
}

- (void) computeIntervalAsync
{
    [self computeIntervalFlipNow: [NSNumber numberWithBool: NO]];
    [imageView setNeedsDisplay: YES];
}

+ (float) computeIntervalForDCMPix: (DCMPix*) p1 And: (DCMPix*) p2
{
    double vectors[ 9], vectorsB[ 9];
    BOOL equalVector = YES;
    float interval = 0;
    
    [p1 orientationDouble: vectors];
    [p2 orientationDouble: vectorsB];
    
    for( int i = 0; i < 9; i++)
    {
        const double epsilon = fabs(vectors[ i] - vectorsB[ i]);
        if (epsilon > ORIENTATION_SENSIBILITY)
        {
            equalVector = NO;
            break;
        }
    }
    
    BOOL equalZero = YES;
    
    for( int i = 0; i < 9; i++)
    {
        if( vectors[ i] != 0) { equalZero = NO; break;}
        if( vectorsB[ i] != 0) { equalZero = NO; break;}
    }
    
    if( equalVector == YES && equalZero == NO)
    {
        if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
        {
            interval = [p1 originX] - [p2 originX];
            
            if( vectors[6] > 0) interval = -( interval);
            else interval = ( interval);
        }
        
        if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
        {
            interval = [p1 originY] - [p2 originY];
            
            if( vectors[7] > 0) interval = -( interval);
            else interval = ( interval);
        }
        
        if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
        {
            interval = [p1 originZ] - [p2 originZ];
            
            if( vectors[8] > 0) interval = -( interval);
            else interval = ( interval);
        }
    }
    
    return interval;
}

- (BOOL) isGantryTitled
{
    BOOL v = NO;
    
    if( pixList[ 0].count>= 3)
    {
        double Pn1[ 3];
        Pn1[ 0] = [[pixList[ 0] objectAtIndex: 2] originX] - [[pixList[ 0] objectAtIndex: 1] originX];
        Pn1[ 1] = [[pixList[ 0] objectAtIndex: 2] originY] - [[pixList[ 0] objectAtIndex: 1] originY];
        Pn1[ 2] = [[pixList[ 0] objectAtIndex: 2] originZ] - [[pixList[ 0] objectAtIndex: 1] originZ];
        
        double vectors[ 9];
        [[pixList[ 0] objectAtIndex:1] orientationDouble: vectors];
        
        double angle = fabs( [DCMView angleBetweenVectorD: Pn1 andVectorD: vectors+6]);
        angle /= deg2rad;
        if( angle < 90)
        {
            if( angle > [[NSUserDefaults standardUserDefaults] floatForKey: @"MinimumTitledGantryTolerance"]) {
                NSLog( @"---- titledGantry - Not a real 3D data set: %f degrees", angle);
                v = YES;
            }
            else if( angle > 0.001)
                NSLog( @"---- titledGantry (tolerated) - Not a real 3D data set: %f degrees", angle);
            
            titledGantryDegrees = angle;
        }
    }
    
    return v;
}

- (float) computeIntervalFlipNow: (NSNumber*) flipNowNumber
{
    [self selectFirstTilingView];
    
    int z = curMovieIndex;
    {
        double				interval = [[pixList[ z] objectAtIndex:0] sliceInterval];
        long				i, x;
        BOOL				flipNow = [flipNowNumber boolValue];
        
        if( flipNow)
            flipNow = [self isEverythingLoaded];
        
        if( [pixList[ z] count] > 1)
        {
            if( flipNow)
                interval = 0;
        }
        
        if( interval == 0 && [pixList[ z] count] > 2)
        {
            titledGantry = NO;
            
            double vectors[ 9], vectorsB[ 9];
            BOOL equalVector = YES;
            
            [[pixList[ z] objectAtIndex:1] orientationDouble: vectors];
            [[pixList[ z] objectAtIndex:2] orientationDouble: vectorsB];
            
            for( i = 0; i < 9; i++)
            {
                const double epsilon = fabs(vectors[ i] - vectorsB[ i]);
                if (epsilon > ORIENTATION_SENSIBILITY)
                {
                    equalVector = NO;
                    break;
                }
            }
            
            BOOL equalZero = YES;
            
            for( i = 0; i < 9; i++)
            {
                if( vectors[ i] != 0) { equalZero = NO; break;}
                if( vectorsB[ i] != 0) { equalZero = NO; break;}
            }
            
            if( equalVector == YES && equalZero == NO)
            {
                if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
                {
                    interval = [[pixList[ z] objectAtIndex:1] originX] - [[pixList[ z] objectAtIndex:2] originX];
                    
                    if( vectors[6] > 0) interval = -( interval);
                    else interval = ( interval);
                    
                    if( vectors[6] > 0) orientationVector = eSagittalPos;
                    else orientationVector = eSagittalNeg;
                    
                    [orientationMatrix selectCellWithTag: 2];
                    if( interval != 0) [orientationMatrix setEnabled: YES];
                    currentOrientationTool = 2;
                }
                
                if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
                {
                    interval = [[pixList[ z] objectAtIndex:1] originY] - [[pixList[ z] objectAtIndex:2] originY];
                    
                    if( vectors[7] > 0) interval = -( interval);
                    else interval = ( interval);
                    
                    if( vectors[7] > 0) orientationVector = eCoronalPos;
                    else orientationVector = eCoronalNeg;
                    
                    [orientationMatrix selectCellWithTag: 1];
                    if( interval != 0) [orientationMatrix setEnabled: YES];
                    currentOrientationTool = 1;
                }
                
                if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
                {
                    interval = [[pixList[ z] objectAtIndex:1] originZ] - [[pixList[ z] objectAtIndex:2] originZ];
                    
                    if( vectors[8] > 0) interval = -( interval);
                    else interval = ( interval);
                    
                    if( vectors[8] > 0) orientationVector = eAxialPos;
                    else orientationVector = eAxialNeg;
                    
                    [orientationMatrix selectCellWithTag: 0];
                    if( interval != 0) [orientationMatrix setEnabled: YES];
                    currentOrientationTool = 0;
                }
                
                if( originalOrientation == -1)
                {
                    switch( orientationVector)
                    {
                        case eAxialPos:
                        case eAxialNeg:
                            originalOrientation = 0;
                            break;
                            
                        case eCoronalNeg:
                        case eCoronalPos:
                            originalOrientation = 1;
                            break;
                            
                        case eSagittalNeg:
                        case eSagittalPos:
                            originalOrientation = 2;
                            break;
                    }
                }
                
                double xd = [[pixList[ z] objectAtIndex: 2] originX] - [[pixList[ z] objectAtIndex: 1] originX];
                double yd = [[pixList[ z] objectAtIndex: 2] originY] - [[pixList[ z] objectAtIndex: 1] originY];
                double zd = [[pixList[ z] objectAtIndex: 2] originZ] - [[pixList[ z] objectAtIndex: 1] originZ];
                
                double interval3d = sqrt(xd*xd + yd*yd + zd*zd);
                
                xd /= interval3d;
                yd /= interval3d;
                zd /= interval3d;
                
                if( interval == 0 && [[pixList[ z] objectAtIndex: 0] originX] == 0 && [[pixList[ z] objectAtIndex: 0] originY] == 0 && [[pixList[ z] objectAtIndex: 0] originZ] == 0)
                {
                    interval = [[pixList[ z] objectAtIndex:0] spacingBetweenSlices];
                    if( interval)
                    {
                        interval3d = -interval;
                        orientationVector = eAxialNeg;
                        [orientationMatrix setEnabled: YES];
                        
                        float v[ 9], o[ 3];
                        
                        o[ 0] = 0; o[ 1] = 0; o[ 2] = 0;
                        
                        v[ 0] = 1;	v[ 1] = 0;	v[ 2] = 0;
                        v[ 3] = 0;	v[ 4] = 1;	v[ 5] = 0;
                        v[ 6] = 1;	v[ 7] = 0;	v[ 8] = 1;
                        
                        for( DCMPix *pix in pixList[ z])
                        {
                            [pix setOrientation: v];
                            [pix setOrigin: o];
                            o[ 2] += interval;
                        }
                    }
                }
                
                // FLIP DATA !!!!!! FOR 3D TEXTURE MAPPING !!!!!
                if( interval < 0 && flipNow == YES)
                {
                    BOOL sameSize = YES;
                    
                    DCMPix	*firstObject = [pixList[ z] objectAtIndex: 0];
                    
                    for(  i = 0 ; i < [pixList[ z] count]; i++)
                    {
                        if( [firstObject pheight] != [[pixList[ z] objectAtIndex: i] pheight]) sameSize = NO;
                        if( [firstObject pwidth] != [[pixList[ z] objectAtIndex: i] pwidth]) sameSize = NO;
                    }
                    
                    if( sameSize)
                    {
                        if( interval3d)
                            interval = fabs( interval3d);	//interval3d;	//-interval;
                        else
                            interval = fabs( interval);
                        
                        for( x = 0; x < maxMovieIndex; x++)
                        {
                            firstObject = [pixList[ x] objectAtIndex: 0];
                            
                            float	*volumeDataPtr = [firstObject fImage];
                            
                            [self flipData: (char*) volumeDataPtr :[pixList[ x] count] :[firstObject pwidth] :[firstObject pheight]];
                            
                            for(  i = 0 ; i < [pixList[ x] count]; i++)
                            {
                                long offset = ((long)[pixList[ x] count]-1-i)*[firstObject pheight] * [firstObject pwidth];
                                
                                [[pixList[ x] objectAtIndex: i] setfImage: volumeDataPtr + offset];
                                [[pixList[ x] objectAtIndex: i] setSliceInterval: interval];
                            }
                            
                            id tempObj;
                            
                            for( i = 0; i < [pixList[ x] count]/2 ; i++)
                            {
                                tempObj = [[pixList[ x] objectAtIndex: i] retain];
                                [pixList[ x] replaceObjectAtIndex: i withObject:[pixList[ x] objectAtIndex: [pixList[ x] count]-i-1]];
                                [pixList[ x] replaceObjectAtIndex: [pixList[ x] count]-i-1 withObject: tempObj];
                                [tempObj release];
                                
                                tempObj = [[fileList[ x] objectAtIndex: i] retain];
                                [fileList[ x] replaceObjectAtIndex: i withObject:[fileList[ x] objectAtIndex: [fileList[ x] count]-i-1]];
                                [fileList[ x] replaceObjectAtIndex: [fileList[ x] count]-i-1 withObject: tempObj];
                                [tempObj release];
                                
                                tempObj = [[roiList[ x] objectAtIndex: i] retain];
                                [roiList[ x] replaceObjectAtIndex: i withObject:[roiList[ x] objectAtIndex: [roiList[ x] count]-i-1]];
                                [roiList[ x] replaceObjectAtIndex: [roiList[ x] count]-i-1 withObject: tempObj];
                                [tempObj release];
                            }
                        }
                        
                        for( x = 0; x < maxMovieIndex; x++)
                        {
                            for( i = 0; i < [pixList[ x] count]; i++)
                            {
                                [[pixList[ x] objectAtIndex: i] setArrayPix: pixList[ x] :i];
                                [[pixList[ x] objectAtIndex: i] setID: i];
                            }
                        }
                        
                        subCtrlMaskID = [pixList[ z] count] - subCtrlMaskID -1;
                        
                        [self flipDataSeries: self];
                    }
                    else NSLog( @"sameSize = NO");
                }
                else
                {
                    if( interval3d)
                    {
                        if( interval < 0) interval = -interval3d;
                        else interval = interval3d;
                    }
                    else
                    {
                        if( interval < 0) interval = -interval;
                        else interval = interval;
                    }
                    
                    for( x = 0; x < maxMovieIndex; x++)
                    {
                        for( i = 0; i < [pixList[ x] count]; i++)
                        {
                            [[pixList[ x] objectAtIndex: i] setSliceInterval: interval];
                        }
                    }
                }
                
                if( flipNow == YES)
                    titledGantry = [self isGantryTitled];
            }
        }
    }
    
    [blendingController computeInterval];
    
    float val = [[pixList[ curMovieIndex] objectAtIndex:0] sliceInterval];
    
    return val;
}

- (void) displayAWarningIfNonTrueVolumicData
{
    [self isDataVolumicIn4D: YES]; // Let this function try to correct the scout image first / GE SCAN
    
    if( nonVolumicDataWarningDisplayed == NO)
    {
        double previousInterval3d = 0;
        double minInterval = 0, maxInterval = 0;
        BOOL nonContinuous = NO;
        
        for( int i = 0 ; i < (long)[pixList[ 0] count] -1; i++)
        {
            double xd = [[pixList[ 0] objectAtIndex: i+1] originX] - [[pixList[ 0] objectAtIndex: i] originX];
            double yd = [[pixList[ 0] objectAtIndex: i+1] originY] - [[pixList[ 0] objectAtIndex: i] originY];
            double zd = [[pixList[ 0] objectAtIndex: i+1] originZ] - [[pixList[ 0] objectAtIndex: i] originZ];
            
            double interval3d = sqrt(xd*xd + yd*yd + zd*zd);
            
            xd /= interval3d;
            yd /= interval3d;
            zd /= interval3d;
            
            int sss = fabs( previousInterval3d - interval3d) * 100.;
            
            if( i == 0)
            {
                maxInterval = fabs( interval3d);
                minInterval = fabs( interval3d);
            }
            else
            {
                if( fabs( interval3d) > maxInterval) maxInterval = fabs( interval3d);
                if( fabs( interval3d) < minInterval) minInterval = fabs( interval3d);
            }
            
            if( sss != 0 && previousInterval3d != 0)
            {
                nonContinuous = YES;
                //				NSLog(@"nonContinuous interval: %f", previousInterval3d - interval3d);
            }
            
            previousInterval3d = interval3d;
        }
        
        if( nonContinuous)
        {
            NSRunInformationalAlertPanel( NSLocalizedString(@"Warning!", nil), NSLocalizedString(@"These slices have a non regular slice interval, varying from %.3f mm to %.3f mm. This will produce distortion in 3D representations, and in measurements.", nil), NSLocalizedString(@"OK", nil), nil, nil, minInterval, maxInterval);
            //
            //            // Resample origins, according to first and last image
            //
            //            double fullLength;
            //
            //            double xd = [[pixList[ 0] lastObject] originX] - [[pixList[ 0] objectAtIndex: 0] originX];
            //            double yd = [[pixList[ 0] lastObject] originY] - [[pixList[ 0] objectAtIndex: 0] originY];
            //            double zd = [[pixList[ 0] lastObject] originZ] - [[pixList[ 0] objectAtIndex: 0] originZ];
            //
            //            double interval3d = sqrt(xd*xd + yd*yd + zd*zd);
            //            NSLog( @"full length = %f, new mean interval: %f", interval3d, interval3d / (pixList[ 0].count-1));
            //
            //            interval3d /= (pixList[ 0].count-1);
            //
            //            double vectors[ 9];
            //
            //            [[pixList[0] objectAtIndex: 0] orientationDouble: vectors];
            //
            //            for( int i = 1 ; i < [pixList[ 0] count]; i++)
            //            {
            //                double newOrigin[ 3];
            //                newOrigin[ 0] = [[pixList[ 0] objectAtIndex: 0] originX] + interval3d*(float)i*vectors[6];
            //                newOrigin[ 1] = [[pixList[ 0] objectAtIndex: 0] originY] + interval3d*(float)i*vectors[7];
            //                newOrigin[ 2] = [[pixList[ 0] objectAtIndex: 0] originZ] + interval3d*(float)i*vectors[8];
            //
            //                [[pixList[ 0] objectAtIndex: i] setOriginDouble: newOrigin];
            //                [[pixList[ 0] objectAtIndex: i] setSliceInterval: 0];
            //            }
            //
            //            xd = [[pixList[ 0] lastObject] originX] - [[pixList[ 0] objectAtIndex: 0] originX];
            //            yd = [[pixList[ 0] lastObject] originY] - [[pixList[ 0] objectAtIndex: 0] originY];
            //            zd = [[pixList[ 0] lastObject] originZ] - [[pixList[ 0] objectAtIndex: 0] originZ];
            //
            //            interval3d = sqrt(xd*xd + yd*yd + zd*zd);
            //            NSLog( @"new full length = %f", interval3d);
            
        }
        else if( [self isDataVolumicIn4D: YES] == NO)
        {
            NSRunInformationalAlertPanel( NSLocalizedString(@"Warning!", nil), NSLocalizedString(@"These slices doesn't represent a true 3D volumic data. This will produce distortion in 3D representations, and in measurements.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        }
        
        nonVolumicDataWarningDisplayed = YES;
    }
}

-(float) computeInterval
{
    float s = 0;
    
    if( computeInterval == NO) // avoid re-entry
    {
        computeInterval = YES;
        s = [self computeIntervalFlipNow: [NSNumber numberWithBool: YES]];
        computeInterval = NO;
    }
    return s;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo;
{
    if( returnCode == 1)
    {
        switch( [contextInfo tag])
        {
                //			case 1: [self MPR2DViewer:contextInfo];		break;  //2DMPR
#ifndef OSIRIX_LIGHT
            case 10: [self mprViewer:contextInfo];		break;  //3DMPR
            case 3: [self VRViewer:contextInfo];		break;  //MIP
            case 4: [self VRViewer:contextInfo];		break;  //VR
            case 5: [self SRViewer:contextInfo];		break;  //SR
#endif
        }
    }
}

-(IBAction) endThicknessInterval:(id) sender
{
    if( ([customInterval floatValue] == 0 && [pixList[ curMovieIndex] count] > 1) || [customXSpacing floatValue] == 0 ||  [customYSpacing floatValue] == 0)
    {
        if( [sender tag])
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"These values CANNOT be equal to ZERO!", nil), NSLocalizedString(@"OK", nil), nil, nil);
            return;
        }
    }
    
    [ThickIntervalWindow orderOut:sender];
    
    if( [sender tag])   //User clicks OK Button
    {
        long i, x;
        float v[ 9], o[ 3];
        
        for( i = 0; i < 9; i++) v[ i] = [[customVectors cellWithTag: i] floatValue];
        for( i = 0; i < 3; i++) o[ i] = [[customOrigin cellWithTag: i] floatValue];
        
        for( i = 0 ; i < maxMovieIndex; i++)
        {
            int		dir = 2;
            
            v[6] = v[1]*v[5] - v[2]*v[4];
            v[7] = v[2]*v[3] - v[0]*v[5];
            v[8] = v[0]*v[4] - v[1]*v[3];
            
            if( fabs( v[6]) > fabs(v[7]) && fabs( v[6]) > fabs(v[8])) dir = 0;
            if( fabs( v[7]) > fabs(v[6]) && fabs( v[7]) > fabs(v[8])) dir = 1;
            if( fabs( v[8]) > fabs(v[6]) && fabs( v[8]) > fabs(v[7])) dir = 2;
            
            for( x = 0; x < [pixList[ i] count]; x++)
            {
                DCMPix	*pix = nil;
                
                pix = [pixList[ i] objectAtIndex:x];
                
                [pix setSliceInterval: 0];
                [pix setPixelSpacingX: fabs([customXSpacing floatValue])];
                [pix setPixelSpacingY: fabs([customYSpacing floatValue])];
                if( fabs([customXSpacing floatValue]) != 0 && fabs([customYSpacing floatValue]) != 0) [pix setPixelRatio: fabs([customYSpacing floatValue]) / fabs([customXSpacing floatValue])];
                [pix setOrientation: v];
                [pix setOrigin: o];
                [pix computeSliceLocation];
                
                switch( dir)
                {
                    case 0:	o[ 0] += [customInterval floatValue];	break;
                    case 1:	o[ 1] += [customInterval floatValue];	break;
                    case 2: o[ 2] += [customInterval floatValue];	break;
                }
            }
        }
        
        [imageView setIndex: [imageView curImage]];
        
        [self computeInterval];
    }
    
    [NSApp endSheet:ThickIntervalWindow returnCode:[sender tag]];
}

- (IBAction) updateZVector:(id) sender
{
    float v[ 9];
    int i;
    
    for( i = 0; i < 9; i++) v[ i] = [[customVectors cellWithTag: i] floatValue];
    
    // Compute normal vector
    v[6] = v[1]*v[5] - v[2]*v[4];
    v[7] = v[2]*v[3] - v[0]*v[5];
    v[8] = v[0]*v[4] - v[1]*v[3];
    
    for( i = 6; i < 9; i++)  [[customVectors cellWithTag: i] setFloatValue: v[ i]];
}

- (IBAction) setAxialOrientation:(id) sender
{
    [customInterval selectText: self];
    
    float v[ 9];
    int i;
    
    v[ 0] = 1;		v[ 1] = 0;		v[ 2] = 0;
    v[ 3] = 0;		v[ 4] = 1;		v[ 5] = 0;
    v[ 6] = 0;		v[ 7] = 0;		v[ 8] = 1;
    
    for( i = 0; i < 9; i++) [[customVectors cellWithTag: i] setFloatValue: v[ i]];
}

- (void) SetThicknessInterval:(id) sender
{
    float v[ 9], o[ 3];
    long i;
    DCMPix *p = [pixList[ curMovieIndex] objectAtIndex:0];
    
    if( [p sliceInterval])
        [customInterval setFloatValue: [p sliceInterval]];
    else
    {
        if( [p spacingBetweenSlices])
            [customInterval setFloatValue: [p spacingBetweenSlices]];
    }
    
    [customXSpacing setFloatValue: [p pixelSpacingX]];
    [customYSpacing setFloatValue: [p pixelSpacingY]];
    
    [p orientation: v];
    
    if( v[ 0] == 0 && v[ 1] == 0 && v[ 2] == 0)
    {
        v[ 0] = 1;		v[ 1] = 0;		v[ 2] = 0;
        v[ 3] = 0;		v[ 4] = 1;		v[ 5] = 0;
        v[ 6] = 0;		v[ 7] = 0;		v[ 8] = 1;
    }
    
    for( i = 0; i < 9; i++) [[customVectors cellWithTag: i] setFloatValue: v[ i]];
    
    o[ 0] = [p originX];
    o[ 1] = [p originY];
    o[ 2] = [p originZ];
    for( i = 0; i < 3; i++) [[customOrigin cellWithTag: i] setFloatValue: o[ i]];
    
    [NSApp beginSheet: ThickIntervalWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:(void*) sender];
}

- (void)deleteWLWW:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSString	*name = (id) contextInfo;
    
    if( returnCode == 1)
    {
        NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] mutableCopy] autorelease];
        [presetsDict removeObjectForKey: name];
        [[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey:@"WLWW3"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: [NSDictionary dictionary]];
    }
    
    [name release];
}

- (void) ApplyWLWW:(id) sender
{
    NSString *name = [sender title];
    
    if( [[sender title] isEqualToString:NSLocalizedString(@"Other", nil)])
    {
    }
    else if( [[sender title] isEqualToString:NSLocalizedString(@"Default WL & WW", nil)])
    {
        [imageView setWLWW:[[imageView curDCM] savedWL] :[[imageView curDCM] savedWW]];
    }
    else if( [[sender title] isEqualToString:NSLocalizedString(@"Full dynamic", nil)])
    {
        [imageView setWLWW:0 :0];
    }
    else
    {
        name = [[sender title] substringFromIndex: 4];
        
        if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
        {
            NSBeginAlertSheet( NSLocalizedString(@"Remove a WL/WW preset", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [name retain], NSLocalizedString( @"Are you sure you want to delete preset : '%@'?", nil), name);
            
            return;
        }
        else
        {
            NSArray		*value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] objectForKey: name];
            [imageView setWLWW:[[value objectAtIndex: 0] floatValue] :[[value objectAtIndex: 1] floatValue]];
        }
    }
    
    [[[wlwwPopup menu] itemAtIndex:0] setTitle: [sender title]];
    [self propagateSettings];
    
    if( curWLWWMenu != name)
    {
        [curWLWWMenu release];
        curWLWWMenu = [name retain];
    }
    
    [wlwwPopup setTitle: curWLWWMenu];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDCMUpdateCurrentImageNotification object: imageView userInfo: userInfo];
}

-(IBAction) updateSetWLWW:(id) sender
{
    if( [sender tag] == 0)
    {
        [imageView setWLWW: [wlset floatValue] :[wwset floatValue]];
        
        [fromset setStringValue: [NSString stringWithFormat:@"%.3f", [wlset floatValue] - [wwset floatValue]/2]];
        [toset setStringValue: [NSString stringWithFormat:@"%.3f", [wlset floatValue] + [wwset floatValue]/2]];
    }
    else
    {
        [imageView setWLWW: [fromset floatValue] + ([toset floatValue] - [fromset floatValue])/2 :[toset floatValue] - [fromset floatValue]];
        [wlset setStringValue: [NSString stringWithFormat:@"%.3f", [fromset floatValue] + ([toset floatValue] - [fromset floatValue])/2]];
        [wwset setStringValue: [NSString stringWithFormat:@"%.3f", [toset floatValue] - [fromset floatValue]]];
    }
}

static float oldsetww, oldsetwl;

-(IBAction) endSetWLWW:(id) sender
{
    [wlset selectText: self];
    
    [setWLWWWindow orderOut:sender];
    
    [NSApp endSheet:setWLWWWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
        [imageView setWLWW: [wlset floatValue] :[wwset floatValue] ];
    }
    else
    {
        [imageView setWLWW: oldsetwl :oldsetww ];
    }
}

- (IBAction) SetWLWW:(id) sender
{
    float cwl, cww;
    
    [imageView getWLWW:&cwl :&cww];
    
    oldsetww = cww;
    oldsetwl = cwl;
    
    [wlset setStringValue:[NSString stringWithFormat:@"%.3f", cwl ]];
    [wwset setStringValue:[NSString stringWithFormat:@"%.3f", cww ]];
    
    [fromset setStringValue: [NSString stringWithFormat:@"%.3f", [wlset floatValue] - [wwset floatValue]/2]];
    [toset setStringValue: [NSString stringWithFormat:@"%.3f", [wlset floatValue] + [wwset floatValue]/2]];
    
    [NSApp beginSheet: setWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

//static NSMutableArray		*TEMPviewersList;
//
//-(IBAction) endSyncSetOffset:(id) sender
//{
//    NSLog(@"endSyncSetOffset");
//
//    [syncOffsetWindow orderOut:sender];
//
//    [NSApp endSheet:syncOffsetWindow returnCode:[sender tag]];
//
//    if( [sender tag])   //User clicks OK Button
//    {
//		[imageView setSyncRelativeDiff: [syncOffsetText floatValue]];
//    }
//
//	[TEMPviewersList release];
//}
//
//- (IBAction) syncSelectSeriesPopup: (id) sender
//{
//	long				i, x;
//
//	float diff = [[[[TEMPviewersList objectAtIndex:[sender tag]] imageView] curDCM] sliceLocation] - [[imageView curDCM] sliceLocation];
//
//	[syncOffsetText setFloatValue: diff];
//}
//
//- (void) syncSetOffset
//{
//	NSArray				*winList = [NSApp windows];
//	BOOL				found = NO;
//	long				i, x;
//
//	TEMPviewersList = [[NSMutableArray alloc] initWithCapacity:0];
//
//	[syncOffsetToSeries removeAllItems];
//
//	for( x = 0, i = 0; i < [winList count]; i++)
//	{
//		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
//		{
//			if( [[winList objectAtIndex:i] windowController] != self)
//			{
//				[syncOffsetToSeries addItemWithTitle: [[[[winList objectAtIndex:i] windowController] window] title]];
//				[[syncOffsetToSeries lastItem] setTag: x++];
//				[TEMPviewersList addObject: [[winList objectAtIndex:i] windowController]];
//			}
//		}
//	}
//
//	[syncOffsetSeries setStringValue: [[self window] title]];
//
//	[syncOffsetText setIntValue: [imageView syncRelativeDiff]];
//    [NSApp beginSheet: syncOffsetWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
//}


- (NSString*) curWLWWMenu
{
    return curWLWWMenu;
}

- (NSString*) curOpacityMenu
{
    return curOpacityMenu;
}

#pragma mark convolution

- (void) applyConvolutionXYThread:(id) dict
{
    @autoreleasepool
    {
        @try {
            for( int x = 0; x < maxMovieIndex; x++)
            {
                for ( DCMPix *p in [pixList[ x] subarrayWithRange: NSMakeRange( [[dict objectForKey: @"from"] intValue], [[dict objectForKey: @"to"] intValue] - [[dict objectForKey: @"from"] intValue])])
                    [p applyConvolutionOnSourceImage];
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        
        [convThread lock];
        [convThread unlockWithCondition: [convThread condition]-1];
    }
}

- (void) applyConvolutionZThread: (id) dict
{
    @autoreleasepool {
        @try {
            for( int x = 0; x < maxMovieIndex; x++)
            {
                DCMPix	*pix = [pixList[ x] objectAtIndex: 0];
                
                vImage_Buffer dstf, srcf;
                
                srcf.height = [pixList[ x] count];
                srcf.width = pix.pwidth;
                srcf.rowBytes = pix.pwidth*pix.pheight*sizeof(float);
                
                float *t = malloc( srcf.height * srcf.width * sizeof( float));
                if( t)
                {
                    dstf.height = [pixList[ x] count];
                    dstf.width = pix.pwidth;
                    dstf.rowBytes = pix.pwidth*sizeof(float);
                    dstf.data = t;
                    
                    int from = [[dict objectForKey: @"from"] intValue];
                    int to = [[dict objectForKey: @"to"] intValue];
                    float *fkernel = [[dict objectForKey: @"kernel"] pointerValue];
                    
                    for( int y = from; y < to; y++)
                    {
                        srcf.data = (void*) [volumeData[ x] bytes] + y*pix.pwidth*sizeof(float);
                        
                        if( srcf.data)
                        {
                            if( vImageConvolve_PlanarF( &srcf, &dstf, 0, 0, 0, fkernel, [pix kernelsize], [pix kernelsize], 0, kvImageDoNotTile + kvImageEdgeExtend))
                                NSLog( @"Error applyConvolutionOnImage");
                            else
                            {
                                void *s = srcf.data, *d = dstf.data;
                                
                                for( int y = 0; y < dstf.height; y++)
                                {
                                    memcpy( s, d, dstf.rowBytes);
                                    
                                    s += srcf.rowBytes;
                                    d += dstf.rowBytes;
                                }
                            }
                        }
                    }
                    
                    free( t);
                }
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        
        [convThread lock];
        [convThread unlockWithCondition: [convThread condition]-1];
    }
}

- (IBAction) applyConvolutionOnSource:(id) sender
{
    if( [curConvMenu isEqualToString:NSLocalizedString(@"No Filter", nil)] == NO)
    {
        int mpprocessors = [[NSProcessInfo processInfo] processorCount];
        
        if( convThread == nil)
            convThread = [[NSConditionLock alloc] initWithCondition: 0];
        
        [convThread lockWhenCondition: 0];
        [convThread unlockWithCondition: mpprocessors];
        
        NSMutableDictionary *baseDict = [NSMutableDictionary dictionary];
        int no = [pixList[ 0] count];
        
        for( int i = 0; i < mpprocessors; i++)
        {
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary: baseDict];
            
            int from = (i * no) / mpprocessors;
            int to = ((i+1) * no) / mpprocessors;
            
            [d setObject: [NSNumber numberWithInt: from] forKey: @"from"];
            [d setObject: [NSNumber numberWithInt: to] forKey: @"to"];
            
            [NSThread detachNewThreadSelector: @selector(applyConvolutionXYThread:) toTarget: self withObject: d];
        }
        
        [convThread lockWhenCondition: 0];
        [convThread unlock];
        
        if( [self isDataVolumicIn4D: YES])
        {
            // Apply the convolution in the Z direction
            for ( int x = 0; x < maxMovieIndex; x++)
            {
                [convThread lockWhenCondition: 0];
                [convThread unlockWithCondition: mpprocessors];
                
                DCMPix *pix = [pixList[ x] objectAtIndex: 0];
                float m = *[pix fImage];
                
                if( [pix isRGB] == NO)
                {
                    float fkernel[25];
                    
                    if( [pix normalization] != 0)
                        for( int i = 0; i < 25; i++) fkernel[ i] = (float) [pix kernel][ i] / (float) [pix normalization];
                    else
                        for( int i = 0; i < 25; i++) fkernel[ i] = (float) [pix kernel][ i];
                    
                    baseDict = [NSMutableDictionary dictionary];
                    int no = [pix pheight];
                    
                    [baseDict setObject: [NSValue valueWithPointer: fkernel] forKey: @"kernel"];
                    
                    for( int i = 0; i < mpprocessors; i++)
                    {
                        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary: baseDict];
                        
                        int from = (i * no) / mpprocessors;
                        int to = ((i+1) * no) / mpprocessors;
                        
                        [d setObject: [NSNumber numberWithInt: from] forKey: @"from"];
                        [d setObject: [NSNumber numberWithInt: to] forKey: @"to"];
                        
                        [NSThread detachNewThreadSelector: @selector(applyConvolutionZThread:) toTarget: self withObject: d];
                    }
                }
                else
                {
                    [convThread lock];
                    [convThread unlockWithCondition: [convThread condition]-1];
                }
                
                [convThread lockWhenCondition: 0];
                [convThread unlock];
                
                // check the first line to avoid nan value....
                for( DCMPix *p in pixList[ x])
                {
                    if( [p isRGB] == NO)
                    {
                        float *ptr = (float*) [p fImage];
                        int x = [p pwidth];
                        while( x-- > 0)
                            *ptr++ = m;
                    }
                }
            }
        }
        
        [self ApplyConvString:NSLocalizedString(@"No Filter", nil)];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList[ curMovieIndex] userInfo: nil];
    }
    else NSRunAlertPanel(NSLocalizedString(@"Convolution", nil), NSLocalizedString(@"First, apply a convolution filter...", nil), nil, nil, nil);
    
    [convThread release];
    convThread = nil;
}

- (IBAction) computeSum:(id) sender
{
    float sum = 0;
    
    for( int i = 0; i < 25; i++)
    {
        NSCell  *theCell = [convMatrix cellWithTag: i];
        
        sum += [[theCell stringValue] floatValue];
    }
    
    [matrixNorm setFloatValue: sum];
    
    [self convMatrixAction:self];
}

- (IBAction) changeMatrixSize:(id) sender
{
    id          theCell = [sender selectedCell];
    long		x, y;
    
    switch( [theCell tag])
    {
        case 3: //3x3
            for( x = 0; x < 5; x++)
            {
                for( y = 0; y < 5; y++)
                {
                    theCell = [convMatrix cellAtRow:y column:x];
                    
                    if( x < 1 || x > 3 || y < 1 || y > 3)
                    {
                        [theCell setEnabled:NO];
                        [theCell setStringValue:@""];
                    }
                    else
                    {
                        [theCell setEnabled:YES];
                        if( [[theCell stringValue] isEqualToString:@""])
                            [theCell setStringValue:@"0"];
                    }
                    
                    [theCell setAlignment:NSCenterTextAlignment];
                }
            }
            break;
            
        case 5: //5x5
            for( x = 0; x < 5; x++)
            {
                for( y = 0; y < 5; y++)
                {
                    theCell = [convMatrix cellAtRow:y column:x];
                    
                    [theCell setEnabled:YES];
                    if( [[theCell stringValue] isEqualToString:@""])
                        [theCell setStringValue:@"0"];
                    
                    [theCell setAlignment:NSCenterTextAlignment];
                }
            }
            break;
    }
    
    [self convMatrixAction:self];
}

- (void)deleteConv:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if( returnCode == 1)
    {
        NSMutableDictionary		*convDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] mutableCopy] autorelease];
        
        [convDict removeObjectForKey: (id) contextInfo];
        [[NSUserDefaults standardUserDefaults] setObject: convDict forKey: @"Convolution"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: curConvMenu userInfo: [NSDictionary dictionary]];
    }
}

- (void) setConv:(float*) m :(short) s :(float) norm
{
    long x, i;
    short kernelsize;
    float kernel[ 25];
    
    kernelsize = s;
    
    if( m)
    {
        long i;
        for( i = 0; i < kernelsize*kernelsize; i++)
        {
            kernel[i] = m[i];
        }
    }
    
    for ( x = 0; x < maxMovieIndex; x++)
    {
        for ( i = 0; i < [pixList[ x] count]; i ++)
        {
            [[pixList[ x] objectAtIndex:i] setConvolutionKernel:m :kernelsize :norm];
        }
    }
}

-(void) ApplyConvString:(NSString*) str
{
    if( [str isEqualToString:NSLocalizedString(@"No Filter", nil)])
    {
        [self setConv:nil :0: 0];
        [imageView setIndex:[imageView curImage]];
        
        if( str != curConvMenu)
        {
            [curConvMenu release];
            curConvMenu = [str retain];
        }
    }
    else
    {
        NSDictionary   *aConv;
        NSArray			*array;
        long			size, i;
        float			nomalization;
        float			matrix[25];
        
        aConv = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] objectForKey:str];
        
        if( aConv == nil)
            NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"This convolution filter cannot be loaded.", nil), nil, nil, nil);
        else
        {
            nomalization = [[aConv objectForKey:@"Normalization"] longValue];
            size = [[aConv objectForKey:@"Size"] longValue];
            array = [aConv objectForKey:@"Matrix"];
            
            for( i = 0; i < size*size; i++)
            {
                matrix[i] = [[array objectAtIndex: i] longValue];
            }
            
            [self setConv:matrix :size: nomalization];
            [imageView setIndex:[imageView curImage]];
            if( str != curConvMenu)
            {
                [curConvMenu release];
                curConvMenu = [str retain];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: curConvMenu userInfo: nil];
        }
    }
    
    [[[convPopup menu] itemAtIndex:0] setTitle: str];
}

- (void) ApplyConv:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Remove a Convolution Filter", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteConv:returnCode:contextInfo:), NULL, [sender title], NSLocalizedString( @"Are you sure you want to delete this convolution filter : '%@'", nil), [sender title]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: curConvMenu userInfo: [NSDictionary dictionary]];
    }
    else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
    {
        NSDictionary   *aConv;
        NSArray			*array;
        long			size, x, y;
        long			inc, nomalization;
        
        aConv = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] objectForKey:[sender title]];
        nomalization = [[aConv objectForKey:@"Normalization"] longValue];
        size = [[aConv objectForKey:@"Size"] longValue];
        array = [aConv objectForKey:@"Matrix"];
        
        [matrixName setStringValue: [sender title]];
        [matrixNorm setFloatValue: nomalization];
        
        inc = 0;
        switch( size)
        {
            case 3:
                [sizeMatrix selectCellWithTag:3];
                for( x = 0; x < 5; x++)
                {
                    for( y = 0; y < 5; y++)
                    {
                        NSCell *theCell = [convMatrix cellAtRow:y column:x];
                        
                        if( x < 1 || x > 3 || y < 1 || y > 3)
                        {
                            [theCell setEnabled:NO];
                            [theCell setStringValue:@""];
                        }
                        else
                        {
                            [theCell setEnabled:YES];
                            if( [[theCell stringValue] isEqualToString:@""])
                                [theCell setStringValue:@"0"];
                            
                            [theCell setAlignment:NSCenterTextAlignment];
                            [[convMatrix cellAtRow:x column:y] setFloatValue: [[array objectAtIndex:inc++] floatValue]];
                        }
                    }
                }
                break;
                
            case 5:
                [sizeMatrix selectCellWithTag:5];
                for( x = 0; x < 5; x++)
                {
                    for( y = 0; y < 5; y++)
                    {
                        NSCell *theCell = [convMatrix cellAtRow:y column:x];
                        
                        [theCell setEnabled:YES];
                        if( [[theCell stringValue] isEqualToString:@""])
                            [theCell setStringValue:@"0"];
                        
                        [theCell setAlignment:NSCenterTextAlignment];
                        [[convMatrix cellAtRow:x column:y] setFloatValue: [[array objectAtIndex:inc++] floatValue]];
                    }
                }
                break;
        }
        
        [NSApp beginSheet: addConvWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
    else
    {
        [self ApplyConvString:[sender title]];
    }
}

-(NSMutableArray*) getMatrix:(short) size
{
    NSMutableArray		*valArray = [NSMutableArray array];
    long				x, y;
    
    switch( size)
    {
        case 3:
            for( x = 0; x < 5; x++)
            {
                for( y = 0; y < 5; y++)
                {
                    NSCell *theCell = [convMatrix cellAtRow:y column:x];
                    
                    if( x < 1 || x > 3 || y < 1 || y > 3)
                    {
                        
                    }
                    else
                    {
                        [valArray addObject: [NSNumber numberWithFloat:[theCell floatValue]]];
                    }
                }
            }
            break;
            
        case 5:
            for( x = 0; x < 5; x++)
            {
                for( y = 0; y < 5; y++)
                {
                    NSCell *theCell = [convMatrix cellAtRow:y column:x];
                    
                    [valArray addObject: [NSNumber numberWithFloat:[theCell floatValue]]];
                }
            }
            break;
    }
    
    return valArray;
}

-(IBAction) endConv:(id) sender
{
    NSLog(@"endConv");
    
    int x, y;
    for( x = 0; x < 5; x++)
    {
        for( y = 0; y < 5; y++)
        {
            NSCell *theCell = [convMatrix cellAtRow:y column:x];
            [theCell setEnabled:YES];
        }
    }
    
    if( [sender tag])   //User clicks OK Button
    {
        NSMutableDictionary		*aConvFilter = [NSMutableDictionary dictionary];
        NSMutableDictionary		*convDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] mutableCopy] autorelease];
        NSMutableArray			*valArray;
        
        [aConvFilter setObject:[NSNumber numberWithLong:[[sizeMatrix selectedCell] tag]] forKey: @"Size"];
        [aConvFilter setObject:[NSNumber numberWithFloat:[matrixNorm floatValue]] forKey: @"Normalization"];
        
        valArray = [self getMatrix:[[sizeMatrix selectedCell] tag]];
        
        [aConvFilter setObject:valArray forKey: @"Matrix"];
        [convDict setObject:aConvFilter forKey: [matrixName stringValue]];
        [[NSUserDefaults standardUserDefaults] setObject: convDict forKey: @"Convolution"];
        
        // Apply it!
        
        if( curConvMenu != [matrixName stringValue])
        {
            [curConvMenu release];
            curConvMenu = [[matrixName stringValue] retain];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: curConvMenu userInfo: [NSDictionary dictionary]];
    }
    
    [addConvWindow orderOut:sender];
    [NSApp endSheet:addConvWindow returnCode:[sender tag]];
    
    [self ApplyConvString: curConvMenu];
}

- (IBAction) convMatrixAction:(id)sender
{
    long				i, size = [[sizeMatrix selectedCell] tag];
    NSMutableArray		*array;
    float				matrix[25];
    
    array = [self getMatrix:size];
    for( i = 0; i < size*size; i++)
    {
        matrix[i] = [[array objectAtIndex: i] floatValue];
    }
    
    [self setConv:matrix :[[sizeMatrix selectedCell] tag] :[matrixNorm floatValue]];
    [imageView setIndex:[imageView curImage]];
}

- (IBAction) AddConv:(id) sender
{
    long x,y;
    
    for( x = 0; x < 5; x++)
    {
        for( y = 0; y < 5; y++)
        {
            NSCell *theCell = [convMatrix cellAtRow:y column:x];
            
            [theCell setEnabled:YES];
            if( [[theCell stringValue] isEqualToString:@""])
                [theCell setStringValue:@"0"];
            
            [theCell setAlignment:NSCenterTextAlignment];
        }
    }
    
    [self convMatrixAction:self];
    [matrixName setStringValue: NSLocalizedString(@"Unnamed", nil)];
    
    [NSApp beginSheet: addConvWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}



#pragma mark-
#pragma mark 4.1.1.4.a Presentation LUT

#pragma mark-
#pragma mark 4.1.1.4.b Pseudo Color

- (void)deleteCLUT:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if( returnCode == 1)
    {
        NSMutableDictionary *clutDict	= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy] autorelease];
        [clutDict removeObjectForKey: (id) contextInfo];
        [[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"CLUT"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: [NSDictionary dictionary]];
    }
}

-(void) ApplyCLUTString:(NSString*) str
{
    if( blendingController && [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
    {
        NSString *c = [[NSUserDefaults standardUserDefaults] stringForKey: @"PET Blending CLUT"];
        [[NSUserDefaults standardUserDefaults] setValue: str forKey: @"PET Blending CLUT"];
        [DCMView computePETBlendingCLUT];
        [[NSUserDefaults standardUserDefaults] setValue: c forKey: @"PET Blending CLUT"];
        
        [curCLUTMenu release];
        curCLUTMenu = [str copy];
        
        [[[clutPopup menu] itemAtIndex:0] setTitle: str];
    }
    else
    {
        if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)])
        {
            for( int x = 0; x < maxMovieIndex; x++)
            {
                for( DCMPix *p in pixList[ x]) [p setBlackIndex: 0];
            }
            
            [imageView setCLUT: nil :nil :nil];
            if( thickSlab)
            {
                [thickSlab setCLUT:nil :nil :nil];
            }
            
            [imageView setIndex:[imageView curImage]];
            
            if( str != curCLUTMenu)
            {
                [curCLUTMenu release];
                curCLUTMenu = [str retain];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
            
            [[[clutPopup menu] itemAtIndex:0] setTitle:str];
            
            [self propagateSettings];
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
                
                if( thickSlab)
                {
                    [thickSlab setCLUT:red :green :blue];
                }
                
                int darkness = 256 * 3;
                int darknessIndex = 0;
                
                for( i = 0; i < 256; i++)
                {
                    if( red[i] + green[i] + blue[i] < darkness)
                    {
                        darknessIndex = i;
                        darkness = red[i] + green[i] + blue[i];
                    }
                }
                
                int x;
                for ( x = 0; x < maxMovieIndex; x++)
                {
                    for ( i = 0; i < [pixList[ x] count]; i ++)
                    {
                        [[pixList[ x] objectAtIndex:i] setBlackIndex: darknessIndex];
                    }
                }
                
                [imageView setCLUT:red :green: blue];
                
                [imageView setIndex:[imageView curImage]];
                if( str != curCLUTMenu)
                {
                    [curCLUTMenu release];
                    curCLUTMenu = [str retain];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
                
                [self propagateSettings];
                [[[clutPopup menu] itemAtIndex:0] setTitle:str];
            }
        }
    }
    
    if( [curCLUTMenu isEqualToString: @"B/W Inverse"])
        imageView.whiteBackground = YES;
    else
        imageView.whiteBackground = NO;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDCMUpdateCurrentImageNotification object: imageView userInfo: userInfo];
    
    float   iwl, iww;
    [imageView getWLWW:&iwl :&iww];
    [imageView setWLWW:iwl :iww];
}

- (void) CLUTChanged: (NSNotification*) note
{
    unsigned char   r[256], g[256], b[256];
    
    [[note object] ConvertCLUT: r :g :b];
    
    [imageView setCLUT :r : g : b];
    [imageView setIndex:[imageView curImage]];
}

- (void) ApplyCLUT:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Remove a Color Look Up Table", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteCLUT:returnCode:contextInfo:), NULL, [sender title], NSLocalizedString( @"Are you sure you want to delete this CLUT : '%@'", nil), [sender title]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: [NSDictionary dictionary]];
    }
    else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
    {
        NSDictionary		*aCLUT;
        
        [self ApplyCLUTString:[sender title]];
        
        aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: curCLUTMenu];
        if( aCLUT)
        {
            if( [aCLUT objectForKey:@"Points"] != nil)
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
                NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Only CLUT created in OsiriX 1.3.1 or higher can be edited...", nil), nil, nil, nil);
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
        NSMutableDictionary *clutDict		= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy] autorelease];
        NSMutableDictionary *aCLUTFilter	= [NSMutableDictionary dictionary];
        unsigned char		red[256], green[256], blue[256];
        long				i;
        
        [clutView ConvertCLUT: red: green: blue];
        
        
        NSMutableArray		*rArray = [NSMutableArray array];
        NSMutableArray		*gArray = [NSMutableArray array];
        NSMutableArray		*bArray = [NSMutableArray array];
        for( i = 0; i < 256; i++) [rArray addObject: [NSNumber numberWithLong: red[ i]]];
        for( i = 0; i < 256; i++) [gArray addObject: [NSNumber numberWithLong: green[ i]]];
        for( i = 0; i < 256; i++) [bArray addObject: [NSNumber numberWithLong: blue[ i]]];
        
        [aCLUTFilter setObject:rArray forKey:@"Red"];
        [aCLUTFilter setObject:gArray forKey:@"Green"];
        [aCLUTFilter setObject:bArray forKey:@"Blue"];
        
        [aCLUTFilter setObject:[NSArray arrayWithArray: [[[clutView getPoints] copy] autorelease]] forKey:@"Points"];
        [aCLUTFilter setObject:[NSArray arrayWithArray: [[[clutView getColors] copy] autorelease]] forKey:@"Colors"];
        
        [clutDict setObject: aCLUTFilter forKey: [clutName stringValue]];
        [[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"CLUT"];
        
        // Apply it!
        
        if( [clutName stringValue] != curCLUTMenu)
        {
            [curCLUTMenu release];
            curCLUTMenu = [[clutName stringValue] retain];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: [NSDictionary dictionary]];
        
        [self ApplyCLUTString:curCLUTMenu];
    }
    else
    {
        [self ApplyCLUTString:curCLUTMenu];
    }
}

- (IBAction) clutAction:(id)sender
{
    //	[imageView setCLUT:matrix :[[sizeMatrix selectedCell] tag] :[matrixNorm intValue]];
    [imageView setIndex:[imageView curImage]];
}


- (void) OpacityChanged: (NSNotification*) note
{
    NSArray *array = [[note object] getPoints];
    
    [thickSlab setOpacity: array];
    
    NSData *table = nil;
    
    if( [array count] == 0)
        table = nil;
    else
        table = [OpacityTransferView tableWith4096Entries: array];
    
    for( int x = 0; x < maxMovieIndex; x++)
    {
        for( DCMPix * pix in pixList[ x])
            [pix setTransferFunction: table];
    }
    
    [self updateImage:self];
}

-(void) ApplyOpacityString:(NSString*) str
{
    NSDictionary		*aOpacity;
    NSArray				*array;
    
    if( [str isEqualToString:NSLocalizedString(@"Linear Table", nil)])
    {
        [thickSlab setOpacity:[NSArray array]];
        
        if( curOpacityMenu != str)
        {
            [curOpacityMenu release];
            curOpacityMenu = [str retain];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
        
        [[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
        
        for( int x = 0; x < maxMovieIndex; x++)
        {
            for( int i = 0; i < [pixList[ x] count]; i++)
                [[pixList[ x] objectAtIndex: i] setTransferFunction: nil];
        }
        
        [self updateImage:self];
    }
    else
    {
        aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
        if (aOpacity)
        {
            array = [aOpacity objectForKey:@"Points"];
            
            [thickSlab setOpacity:array];
            if( curOpacityMenu != str)
            {
                [curOpacityMenu release];
                curOpacityMenu = [str retain];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
            
            [[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
            
            NSData *table = nil;
            
            if( [array count] == 0)
                table = nil;
            else
                table = [OpacityTransferView tableWith4096Entries: [aOpacity objectForKey:@"Points"]];
            
            for( int x = 0; x < maxMovieIndex; x++)
            {
                for( int i = 0; i < [pixList[ x] count]; i++)
                    [[pixList[ x] objectAtIndex: i] setTransferFunction: table];
            }
        }
        [self updateImage:self];
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDCMUpdateCurrentImageNotification object: imageView userInfo: userInfo];
    
    NSArray *viewers = [ViewerController getDisplayed2DViewers];
    
    for( ViewerController *v in viewers)
        [v updateImage: self];
}

- (void)deleteOpacity:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if( returnCode == 1)
    {
        NSMutableDictionary *clutDict	= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] mutableCopy] autorelease];
        [clutDict removeObjectForKey: (id) contextInfo];
        [[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"OPACITY"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curCLUTMenu userInfo: [NSDictionary dictionary]];
    }
}

- (void) ApplyOpacity: (id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Remove a Color Look Up Table", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteOpacity:returnCode:contextInfo:), NULL, [sender title], NSLocalizedString( @"Are you sure you want to delete this Opacity Table : '%@'", nil), [sender title]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: [NSDictionary dictionary]];
    }
    else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
    {
        NSDictionary		*aOpacity, *aCLUT;
        NSArray				*array;
        long				i;
        unsigned char		red[256], green[256], blue[256];
        
        [self ApplyOpacityString:[sender title]];
        
        aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: curOpacityMenu];
        if( aOpacity)
        {
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
            
            if( [aOpacity objectForKey:@"Points"] != nil)
            {
                [OpacityName setStringValue: curOpacityMenu];
                
                NSMutableArray	*pts = [OpacityView getPoints];
                
                [pts removeAllObjects];
                
                [pts addObjectsFromArray: [aOpacity objectForKey:@"Points"]];
                
                [NSApp beginSheet: addOpacityWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
                
                [OpacityView setNeedsDisplay:YES];
            }
        }
    }
    else
    {
        [self ApplyOpacityString:[sender title]];
    }
}

-(IBAction) endOpacity: (id) sender
{
    [addOpacityWindow orderOut: sender];
    
    [NSApp endSheet:addOpacityWindow returnCode: [sender tag]];
    
    if ([sender tag])   //User clicks OK Button
    {
        NSMutableDictionary		*opacityDict	= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] mutableCopy] autorelease];
        NSMutableDictionary		*aOpacityFilter	= [NSMutableDictionary dictionary];
        
        [aOpacityFilter setObject: [[[OpacityView getPoints] copy] autorelease] forKey: @"Points"];
        [opacityDict setObject: aOpacityFilter forKey: [OpacityName stringValue]];
        [[NSUserDefaults standardUserDefaults] setObject: opacityDict forKey: @"OPACITY"];
        
        // Apply it!
        
        if( curOpacityMenu != [OpacityName stringValue])
        {
            [curOpacityMenu release];
            curOpacityMenu = [[OpacityName stringValue] retain];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: [NSDictionary dictionary]];
        
        [self ApplyOpacityString:curOpacityMenu];
    }
    else
    {
        [self ApplyOpacityString:curOpacityMenu];
    }
}

- (NSString*) curCLUTMenu
{
    if( backCurCLUTMenu)
        return backCurCLUTMenu;
    else
        return curCLUTMenu;
}


#pragma mark-
#pragma mark 4.1.1.4.c True Color

#pragma mark-
#pragma mark 4.1.1.4.d Indexed Color

#pragma mark-
#pragma mark 4.1.1.5 ICC input Profile

#pragma mark-
#pragma mark 4.1.2 Composition of various images

-(NSSlider*) sliderFusion { return sliderFusion;}

-(ThickSlabController*) thickSlabController { return thickSlab;}

-(NSString *) thicknessInMm
{
    float thickness = 0, location = 0;
    
    [imageView getThickSlabThickness:&thickness location:&location];
    
    return [NSString stringWithFormat: @"%2.1f mm", thickness];
}

- (void) setFusionMode:(long) m
{
    int i, x;
    
    if( m != 0)
    {
        if( [fileList[ curMovieIndex] count])
        {
            int pw = [[[fileList[ curMovieIndex] lastObject] valueForKey:@"width"] intValue];
            int ph = [[[fileList[ curMovieIndex] lastObject] valueForKey:@"height"] intValue];
            
            for( NSManagedObject *f in fileList[ curMovieIndex])
            {
                if( pw != [[f valueForKey:@"width"] intValue])
                    m = 0;
                if( ph != [[f valueForKey:@"height"] intValue])
                    m = 0;
            }
        }
    }
    
    // Thick Slab
    if( m == 4 || m == 5)
    {
        BOOL	flip;
        
        //		[OpacityPopup setEnabled:YES];
        
        if( m == 4) flip = YES;
        else flip = NO;
        
        if( thickSlab == nil)
        {
            unsigned char *r, *g, *b;
            DCMPix  *pix = [pixList[ curMovieIndex] objectAtIndex:0];
            
#ifndef OSIRIX_LIGHT
            thickSlab = [[ThickSlabController alloc] init];
#endif
            
            [thickSlab setImageData :[pix pwidth] :[pix pheight] :100 :[pix pixelSpacingX] :[pix pixelSpacingY] :[pix sliceThickness] :flip];
            
            [imageView getCLUT: &r :&g :&b];
            [thickSlab setCLUT:r :g :b];
        }
        
        [thickSlab setFlip: flip];
        
        for ( x = 0; x < maxMovieIndex; x++)
        {
            for ( i = 0; i < [pixList[ x] count]; i ++)
            {
                [[pixList[ x] objectAtIndex:i] setThickSlabController: thickSlab];
            }
        }
    }
    //	else [OpacityPopup setEnabled:NO];
    
    [imageView setFusion:m :[sliderFusion intValue]];
    
    for ( x = 0; x < maxMovieIndex; x++)
    {
        if( x != curMovieIndex) // [imageView setFusion] already did it for current serie!
        {
            for ( i = 0; i < [pixList[ x] count]; i ++)
            {
                [[pixList[ x] objectAtIndex:i] setFusion:m :[sliderFusion intValue] :-1];
            }
        }
    }
    
    if( m == 0)
    {
        [activatedFusion setState: NSOffState];
        [sliderFusion setEnabled:NO];
    }
    else
    {
        [activatedFusion setState: NSOnState];
        [sliderFusion setEnabled:YES];
    }
    
    //	[imageView sendSyncMessage: 0];
    
    float   iwl, iww;
    [imageView getWLWW:&iwl :&iww];
    [imageView setWLWW:iwl :iww];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRecomputeROINotification object:self userInfo: nil];
}

- (void) activateFusion:(id) sender
{
    if( [sender state] == NSOffState)
        [self setFusionMode: 0];
    else
        [self setFusionMode: [[popFusion selectedItem] tag]];
    
    [imageView sendSyncMessage: 0];
}

- (void) popFusionAction:(id) sender
{
    int tag = [[sender selectedItem] tag];
    
    [self checkEverythingLoaded];
    [self computeInterval];
    
    [self setFusionMode: tag];
    
    [imageView sendSyncMessage: 0];
}

- (void) sliderFusionAction:(id) sender
{
    [imageView setFusion:-1 :[sender intValue]];
    
    for( int x = 0; x < maxMovieIndex; x++)
    {
        if( x != curMovieIndex) // [imageView setFusion] already did it for current serie!
        {
            for( int i = 0; i < [pixList[ x] count]; i ++)
            {
                [[pixList[ x] objectAtIndex:i] setFusion:-1 :[sender intValue] :-1];
            }
        }
    }
    
    [stacksFusion setIntValue:[sender intValue]];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:@"stackThickness"];
    
    [imageView sendSyncMessage: 0];
}
#pragma mark blending

-(IBAction) blendWindows:(id) sender
{
    NSMutableArray *viewersCT = [ViewerController getDisplayed2DViewers];
    NSMutableArray *viewersPET = [ViewerController getDisplayed2DViewers];
    BOOL	fused = NO;
    
    if( sender && blendingController)
    {
        [self ActivateBlending: nil];
        return;
    }
    
    for( ViewerController *vCT in viewersCT)
    {
        if( [[vCT modality] isEqualToString:@"CT"])
        {
            for( ViewerController *vPET in viewersPET)
            {
                if( vPET != vCT)
                {
                    if( ([[vPET modality] isEqualToString:@"PT"] || [[vPET modality] isEqualToString:@"NM"]) && [[vPET studyInstanceUID] isEqualToString: [vCT studyInstanceUID]])
                    {
                        ViewerController* a = vCT;
                        
                        if( [a blendingController] == nil)
                        {
                            ViewerController* b = vPET;
                            
                            float orientA[ 9], orientB[ 9];
                            
                            [[[a imageView] curDCM] orientation:orientA];
                            [[[b imageView] curDCM] orientation:orientB];
                            
                            if( [DCMView angleBetweenVector: orientA+6 andVector:orientB+6] < [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"])
                            {
                                if( [a isGantryTitled] == NO && [b isGantryTitled] == NO)
                                {
                                    [[a imageView] sendSyncMessage: 0];
                                    [a ActivateBlending: b];
                                    
                                    fused = YES;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    if( fused == NO && sender != nil)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"PET-CT Fusion", nil), NSLocalizedString(@"This function requires two parallel series: a PT/NM series and a CT series in the same study.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
    }
}

-(void) ActivateBlending:(ViewerController*) bC
{
    static int noActivateBlendingReentry = 0;
    
    if( noActivateBlendingReentry > 0)
        return;
    
    noActivateBlendingReentry++;
    
    @try {
        if( bC == self) return;
        if( blendingController == bC) return;
        
        if( blendingController && bC)
            [self ActivateBlending: nil];
        
        [imageView sendSyncMessage:0];
        
        blendingController = bC;
        
        if( blendingController)
        {
            NSLog( @"Blending Activated!");
            
            if( [blendingController blendingController] == self)	// NO cross blending !
            {
                [blendingController ActivateBlending: nil];
            }
            
            if( [[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: [[[blendingController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
            {
                // By default, re-activate 'propagate settings'
                
                [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"COPYSETTINGS"];
            }
            
            float orientA[9], orientB[9];
            
            BOOL proceed = NO;
            
            [[[self imageView] curDCM] orientation:orientA];
            [[[blendingController imageView] curDCM] orientation:orientB];
            
            if( orientB[ 6] == 0 && orientB[ 7] == 0 && orientB[ 8] == 0) proceed = YES;
            if( orientA[ 6] == 0 && orientA[ 7] == 0 && orientA[ 8] == 0) proceed = YES;
            
            if( [DCMView angleBetweenVector: orientA+6 andVector:orientB+6] > [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"])  // Planes are not paralel!
            {
                // FROM SAME STUDY
                
                if( [[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: [[[blendingController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
                {
                    int result = NSRunCriticalAlertPanel(NSLocalizedString(@"2D Planes",nil),NSLocalizedString(@"These 2D planes are not parallel. If you continue the result will be distorted. You can instead 'Reorient' the series to have the same origin/orientation.",nil), NSLocalizedString(@"Reorient & Fusion",nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Fusion",nil));
                    
                    switch( result)
                    {
                        case NSAlertAlternateReturn:
                            proceed = NO;
                            break;
                            
#ifndef OSIRIX_LIGHT
                        case NSAlertDefaultReturn:		// Resample
                            blendingController = [self resampleSeries: blendingController rescale: NO];
                            if( blendingController) proceed = YES;
                            break;
#endif
                            
                        case NSAlertOtherReturn:
                            proceed = YES;
                            break;
                    }
                }
                else	// FROM DIFFERENT STUDY
                {
                    if( NSRunCriticalAlertPanel(NSLocalizedString(@"2D Planes",nil),NSLocalizedString(@"These 2D planes are not parallel. If you continue the result will be distorted. You can instead perform a 'Point-based registration' to have correct alignment/orientation.",nil), NSLocalizedString(@"Continue",nil), NSLocalizedString(@"Cancel",nil), nil) != NSAlertDefaultReturn)
                    {
                        proceed = NO;
                    }
                    else proceed = YES;
                }
            }
            else
            {
                [self displayWarningIfGantryTitled];
                [blendingController displayWarningIfGantryTitled];
                
                proceed = YES;
            }
            
            if( proceed)
            {
                [imageView setBlending: [blendingController imageView]];
                [blendingSlider setEnabled:YES];
                [blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
                
                if( [[blendingController curCLUTMenu] isEqualToString:NSLocalizedString(@"No CLUT", nil)] && [[[blendingController pixList] objectAtIndex: 0] isRGB] == NO)
                {
                    if( [[self modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"]))
                    {
                        if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                            [self ApplyCLUTString: @"B/W Inverse"];
                        else
                            [self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
                    }
                }
                
                [imageView setBlendingFactor: [blendingSlider floatValue]];
                
                [blendingPopupMenu selectItemWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTPETFUSION"]];
                [imageView setBlendingMode: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTPETFUSION"]];
                [seriesView setBlendingMode: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTPETFUSION"]];
                
                [seriesView ActivateBlending:blendingController blendingFactor:[blendingSlider floatValue]];
            }
            
            [backCurCLUTMenu release];
            backCurCLUTMenu = 0L;
            
            if( blendingController && [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
            {
                backCurCLUTMenu = [curCLUTMenu copy];
                [curCLUTMenu release];
                curCLUTMenu = [[[NSUserDefaults standardUserDefaults] stringForKey: @"PET Blending CLUT"] copy];
            }
        }
        else
        {
            [backCurCLUTMenu release];
            backCurCLUTMenu = 0L;
            
            [curCLUTMenu release];
            curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
            
            [imageView setBlending: nil];
            [blendingSlider setEnabled:NO];
            [blendingPercentage setStringValue:@"-"];
            [seriesView ActivateBlending: nil blendingFactor:[blendingSlider floatValue]];
            [imageView display];
        }
        
        [self buildMatrixPreview: NO];
        
        [imageView sendSyncMessage: 0];
        
        [self ApplyCLUTString:curCLUTMenu];
        [self refreshMenus];
    }
    @catch ( NSException *e) {
        N2LogException( e);
    }
    @finally {
        noActivateBlendingReentry--;
    }
}

-(ViewerController*) blendedWindow
{
    return blendedWindow;
}

- (IBAction) endBlendingType:(id) sender
{
    int blendingType = [sender tag];
    
    if( [sender isKindOfClass:[NSSegmentedControl class]])	//Add RGB
        blendingType += [sender selectedSegment];
    
    [blendingTypeWindow orderOut:sender];
    [NSApp endSheet:blendingTypeWindow returnCode:blendingType];
}

- (void)blendingSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode < 0)
    {
        returnCode = -returnCode - 1;
        [self clear8bitRepresentations];
        
        if( [[[PluginManager fusionPlugins] objectAtIndex: returnCode] isEqualToString: @"Subtraction Angio-CT"])
            [self blendWithViewer:blendedWindow blendingType: 9]; // LL filter
        else
            [self executeFilterFromString: [[PluginManager fusionPlugins] objectAtIndex: returnCode]];
    }
    else if (returnCode > 0)
    {
        [self clear8bitRepresentations];
        [self blendWithViewer:blendedWindow blendingType: returnCode];
    }
    
    [blendedWindow release];
    blendedWindow = nil;
}

- (void)blendWithViewer:(ViewerController *)bc blendingType:(int)blendingType
{
    _blendingType = blendingType;
    
    long i;
    switch(blendingType)
    {
        case -1:	// PLUG-INS METHOD
            //[self executeFilter:sender];
            break;
            
        case 1:		// Image fusion
            [self ActivateBlending: bc];
            break;
            
        case 2:
        {	// Image subtraction
            NSUInteger modifierFlags = [[[NSApplication sharedApplication] currentEvent] modifierFlags];
            
            if ((modifierFlags & NSControlKeyMask) != 0)
            {
                NSUInteger count = MIN([[self pixList] count], [[bc pixList] count]);
                for( i = 0; i < count; i++)
                {
                    [imageView setIndex:i];
                    [imageView sendSyncMessage: 0];
                    [[seriesView imageViews] makeObjectsPerformSelector:@selector(display)];
                    
                    [[bc imageView] setIndex:i];
                    [[bc imageView] sendSyncMessage:0];
                    [[[bc seriesView] imageViews] makeObjectsPerformSelector:@selector(display)];
                    
                    [imageView subtract: [bc imageView] absolute: ((modifierFlags & NSAlternateKeyMask) != 0)];
                }
            }
            else
            {
                for( i = 0; i < [pixList[ curMovieIndex] count]; i++)
                {
                    [imageView setIndex:i];
                    [imageView sendSyncMessage: 0];
                    [[seriesView imageViews] makeObjectsPerformSelector:@selector(display)];
                    
                    [imageView subtract: [bc imageView] absolute: ((modifierFlags & NSAlternateKeyMask) != 0)];
                }
            }
        }
            break;
            
        case 3:		// Image multiplication
            for( i = 0; i < [pixList[ curMovieIndex] count]; i++)
            {
                [imageView setIndex:i];
                [imageView sendSyncMessage: 0];
                [[seriesView imageViews] makeObjectsPerformSelector:@selector(display)];
                
                [imageView multiply: [bc imageView]];
            }
            break;
            
        case 4:		// RGB Composition
        case 5:
        case 6:
        {
            for( i = 0; i < [pixList[ curMovieIndex] count]; i++)   // Convert all images to RGB images if necessary
            {
                float	cwl, cww;
                
                [imageView getWLWW:&cwl :&cww];
                
                if( [[pixList[ curMovieIndex] objectAtIndex: i] isRGB] == NO)
                {
                    [[pixList[ curMovieIndex] objectAtIndex: i] ConvertToRGB :0 :cwl :cww];
                }
                
                DCMPix  *dstPix = [pixList[ curMovieIndex] objectAtIndex: i];
                DCMPix  *srcPix = [[bc pixList] objectAtIndex: i];
                
                if( [srcPix isRGB])   // Only works if srcImage is BW
                {
                    unsigned char*  srcPtr = (unsigned char*) [srcPix fImage];
                    unsigned char*  dstPtr = (unsigned char*) [dstPix fImage];
                    
                    long size = [srcPix pheight] * [srcPix pwidth]*4;
                    long temp;
                    
                    while( size-- > 0)
                    {
                        temp = dstPtr[ size];
                        temp += srcPtr[ size];
                        if( temp > 255) temp = 255;
                        dstPtr[ size] = temp;
                    }
                }
                else	// BW SOURCE
                {
                    // Convert srcImage to 8 bits
                    
                    vImage_Buffer		srcf, dst8;
                    
                    srcf.height = [srcPix pheight];
                    srcf.width = [srcPix pwidth];
                    srcf.rowBytes =  [srcPix pwidth]*sizeof(float);
                    srcf.data =  [srcPix fImage];
                    
                    dst8.height = [srcPix pheight];
                    dst8.width = [srcPix pwidth];
                    dst8.rowBytes = [srcPix pwidth];
                    dst8.data = malloc( [srcPix pheight] * [srcPix pwidth]);
                    
                    
                    cwl = [srcPix wl];
                    cww = [srcPix ww];
                    
                    long min = cwl - cww / 2;
                    long max = cwl + cww / 2;
                    
                    vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, max, min, 0);					// FLOAT TO 8 bit
                    
                    unsigned char*  srcPtr = dst8.data;
                    unsigned char*  dstPtr = (unsigned char*) [dstPix fImage];
                    long size = [srcPix pheight] * [srcPix pwidth];
                    
                    switch(blendingType)
                    {
                        case 4:
                            while( size-- > 0)
                            {
                                dstPtr[ size*4 + 1] = srcPtr[ size];
                            }
                            break;
                            
                        case 5:
                            while( size-- > 0)
                            {
                                dstPtr[ size*4 + 2] = srcPtr[ size];
                            }
                            break;
                            
                        case 6:
                            while( size-- > 0)
                            {
                                dstPtr[ size*4 + 3] = srcPtr[ size];
                            }
                            break;
                    }
                }
                
                [imageView getWLWW:&cwl :&cww];
                [dstPix changeWLWW:cwl :cww];
                [imageView loadTextures];
                [imageView setNeedsDisplay:YES];
            }
        }
            break;
            
#ifndef OSIRIX_LIGHT
        case 7:		// 2D Registration
            [self computeRegistrationWithMovingViewer: bc];
            break;
            
        case 11:
            [self resampleSeries: bc rescale: YES];
            break;
            
        case 12:
            [self resampleSeries: bc rescale: NO];
            break;
#endif
            
        case 8:		// 3D Registration
            
            break;
            
            //		#ifndef OSIRIX_LIGHT
            //		case 9: // LL
            //		{
            //			[self checkEverythingLoaded];
            //			[bc checkEverythingLoaded];
            //			if([LLScoutViewer verifyRequiredConditions:[self pixList] :[bc pixList]])
            //			{
            //				LLScoutViewer *llScoutViewer;
            //				llScoutViewer = [[LLScoutViewer alloc] initWithPixList: pixList[0] :fileList[0] :volumeData[0] :self :bc];
            //				[llScoutViewer showWindow:self];
            //			}
            //		}
            //		break;
            //		#endif
            
        case 10:	// Copy ROIs
        {
            WaitRendering *splash = [[WaitRendering alloc] init: NSLocalizedString( @"Copy ROIs between series...", nil)];
            [splash showWindow:self];
            
            int i, x, curIndex = [[bc imageView] curImage];
            NSArray	*bcRoiList = nil;
            
            for( x = 0; x < [[bc pixList] count]; x++)
            {
                [[bc imageView] setIndex: x];
                [[bc imageView] sendSyncMessage: 0];
                [bc adjustSlider];
                
                if( bcRoiList != [[bc roiList] objectAtIndex: [[bc imageView] curImage]])
                {
                    bcRoiList = [[bc roiList] objectAtIndex: [[bc imageView] curImage]];
                    
                    for( i = 0; i < [[[bc roiList] objectAtIndex: x] count]; i++)
                    {
                        ROI *curROI = [[[bc roiList] objectAtIndex: x] objectAtIndex:i];
                        
                        curROI = [[curROI copy] autorelease];
                        
                        [curROI setOriginAndSpacing:[[imageView curDCM] pixelSpacingX] :[[imageView curDCM] pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: [imageView curDCM]]];	//NSMakePoint( [[imageView curDCM] originX], [[imageView curDCM] originY])];
                        [imageView roiSet: curROI];
                        
                        [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] addObject: curROI];
                    }
                }
            }
            
            [[bc imageView] setIndex: curIndex];
            [[bc imageView] sendSyncMessage: 0];
            [bc adjustSlider];
            
            [splash close];
            [splash autorelease];
        }
            break;
            
        default:
            NSRunCriticalAlertPanel(NSLocalizedString(@"OsiriX Light",nil), NSLocalizedString(@"This function is not available in OsiriX Light. Download the complete version of OsiriX to solve this issue.",nil) , NSLocalizedString(@"OK",nil), nil, nil);
            break;
    }
}

-(NSSlider*) blendingSlider { return blendingSlider;}

- (void) blendingSlider:(id) sender
{
    [imageView setBlendingFactor: [sender floatValue]];
    
    [blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([sender floatValue]+256.) / 5.12]];
    
    [seriesView setBlendingFactor: [sender floatValue]];
}

- (void) blendingMode:(id) sender
{
    [imageView setBlendingMode: [sender tag]];
    [seriesView setBlendingMode: [sender tag]];
}

-(void) copySettingsToOthers: (id)sender
{
    [self propagateSettings];
    
    [imageView setNeedsDisplay:YES];
}

-(ViewerController*) blendingController
{
    return blendingController;
}

#pragma mark-
#pragma mark 4.1.3 Anchored graphical layer
#pragma mark ROI

//class setter and getter
// of ViewerController class field   static NSArray*	DefaultROINames;
// used in self generateROINameArray hereafter and in PluginManager.m

+ (NSArray*) defaultROINames
{
    return DefaultROINames;
}

+ (void) setDefaultROINames: (NSArray*) rn
{
    [DefaultROINames release];
    DefaultROINames = [rn retain];
}

- (void) loadROI:(long) mIndex
{
    int i, x;
    DicomStudy *study = [[fileList[0] objectAtIndex:0] valueForKeyPath: @"series.study"];
    NSArray *roisArray = [[[study roiSRSeries] valueForKey: @"images"] allObjects];
    
    [[[[BrowserController currentBrowser] database] managedObjectContext] lock];
    
    @try
    {
        if( [[fileList[ mIndex] lastObject] isKindOfClass:[NSManagedObject class]])
        {
            if ([[NSUserDefaults standardUserDefaults] boolForKey: @"SAVEROIS"])
            {
                for( i = 0; i < [fileList[ mIndex] count]; i++)
                {
                    if( [[pixList[ mIndex] objectAtIndex:i] generated] == NO)
                    {
                        NSString *str = [study roiPathForImage: [fileList[ mIndex] objectAtIndex:i] inArray: roisArray];
                        
                        NSData *data = [SRAnnotation roiFromDICOM: str];
                        
                        if( data)
                            [copyRoiList[ mIndex] replaceObjectAtIndex: i withObject: data];
                        else
                            [copyRoiList[ mIndex] replaceObjectAtIndex: i withObject: [NSData data]];
                        
                        //If data, we successfully unarchived from SR style ROI
                        NSArray *array = 0L;
                        
                        @try
                        {
                            if (data)
                                array = [NSUnarchiver unarchiveObjectWithData: data];
                            else
                                array = [NSUnarchiver unarchiveObjectWithFile: str];
                        }
                        @catch (NSException * e)
                        {
                            NSLog( @"failed to read a ROI");
                        }
                        
                        if( array)
                        {
                            [[roiList[ mIndex] objectAtIndex:i] addObjectsFromArray:array];
                            
                            for( ROI *r in array)
                            {
                                if( r.isAliased)
                                {
                                    r.originalIndexForAlias = i;
                                    
                                    DicomSeries *originalROIseries = [[fileList[ mIndex] objectAtIndex: i] valueForKey:@"series"];
                                    
                                    // propagate it to the entire series IF the images are from the same series
                                    for( x = 0; x < [pixList[ mIndex] count]; x++)
                                    {
                                        if( x != i && originalROIseries == [[fileList[ mIndex] objectAtIndex: x] valueForKey:@"series"])
                                        {
                                            [[roiList[ mIndex] objectAtIndex: x] addObject: r];
                                        }
                                    }
                                }
                            }
                            
                            for( ROI *r in array)
                                [imageView roiSet: r];
                        }
                    }
                }
            }
        }
    }
    @catch ( NSException *e)
    {
        NSLog( @"*** load ROI exception: %@", e);
    }
    [[[[BrowserController currentBrowser] database] managedObjectContext] unlock];
}

+ (BOOL) areROIsArraysIdentical: (NSArray*) copy with: (NSArray*) roisArray
{
    BOOL identical = YES;
    
    if( [roisArray count] != [copy count])
        identical = NO;
    else
    {
        for( int v = 0 ; v < [roisArray count]; v++)
        {
            if( [[[roisArray objectAtIndex: v] data] isEqualToData: [[copy objectAtIndex: v] data]] == NO)
            {
                identical = NO;
                break;
            }
        }
    }
    
    return identical;
}

- (IBAction) flipROIHorizontally:(id)sender
{
    for( ROI* roi in self.selectedROIs)
    {
        [roi flipVertically: NO];
    }
}

- (IBAction) flipROIVertically:(id)sender
{
    for( ROI* roi in self.selectedROIs)
    {
        [roi flipVertically: YES];
    }
}

- (void) saveROI:(long) mIndex
{
    DicomStudy *study = [[fileList[ mIndex] objectAtIndex:0] valueForKeyPath: @"series.study"];
    NSArray *roisArray = [[[study roiSRSeries] valueForKey: @"images"] allObjects];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SAVEROIS"] == NO)
        return;
    
    if( [[fileList[ mIndex] lastObject] isKindOfClass:[NSManagedObject class]])
    {
        DicomDatabase* database = [DicomDatabase databaseForContext:[[fileList[mIndex] lastObject] managedObjectContext]];
        [database lock];
        
        @try
        {
            NSMutableArray *allDICOMSR = [NSMutableArray array];
            
            for( int i = 0; i < [fileList[ mIndex] count]; i++)
            {
                if( [[pixList[mIndex] objectAtIndex:i] generated] == NO)
                {
                    DicomImage *image = [fileList[mIndex] objectAtIndex:i];
                    
                    {
                        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                        
                        @try
                        {
                            BOOL forceArchive = NO;
                            NSString *str = [study roiPathForImage: image inArray: roisArray];
                            
                            if (str == nil)
                                str = [database uniquePathForNewDataFileWithExtension:@"dcm"];
                            
                            else if( [[NSFileManager defaultManager] fileExistsAtPath: str] && [str isEqualToString: [image SRPath]]) // Old ROIs folder -> move it to DATABASE.index file
                            {
                                [[NSFileManager defaultManager] removeItemAtPath: [image SRPath] error: nil];
                                str = [database uniquePathForNewDataFileWithExtension: @"dcm"];
                                forceArchive = YES;
                            }
                            
                            NSMutableArray *roisArray = [NSMutableArray arrayWithArray: [roiList[ mIndex] objectAtIndex: i]];
                            
                            if( [[roiList[ mIndex] objectAtIndex: i] count] > 0)
                            {
                                NSMutableArray *aliasROIs = [NSMutableArray array];
                                
                                for( ROI *r in roisArray)
                                {
                                    [r setPix: [pixList[mIndex] objectAtIndex:i]];
                                    
                                    if( r.isAliased && i != r.originalIndexForAlias)
                                        [aliasROIs addObject: r];
                                }
                                
                                [roisArray removeObjectsInArray: aliasROIs];
                            }
                            
                            if( [roisArray count])
                            {
                                if( [ViewerController areROIsArraysIdentical: [NSUnarchiver unarchiveObjectWithData: [copyRoiList[ mIndex] objectAtIndex: i]] with: roisArray] == NO || forceArchive == YES)
                                {
                                    [SRAnnotation archiveROIsAsDICOM: roisArray toPath: str forImage: image];
                                    [allDICOMSR addObject: str];
                                }
                            }
                            else
                            {
                                if( [[NSFileManager defaultManager] fileExistsAtPath: str])
                                {
                                    if( [ViewerController areROIsArraysIdentical: [NSUnarchiver unarchiveObjectWithData: [copyRoiList[ mIndex] objectAtIndex: i]] with: roisArray] == NO || forceArchive == YES)
                                    {
                                        [SRAnnotation archiveROIsAsDICOM: roisArray toPath: str forImage: image];
                                        [allDICOMSR addObject: str];
                                    }
                                }
                            }
                        }
                        
                        @catch( NSException *ne)
                        {
                            NSLog( @"saveROI failed: %@", [ne description]);
                        }
                        @finally {
                            [pool release];
                        }
                    }
                }
            }
            
            if (allDICOMSR.count)
                [database addFilesAtPaths:allDICOMSR postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX:YES];
        }
        @catch ( NSException *e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        @finally {
            [database unlock];
        }
    }
}

- (ROI*) newROI: (ToolMode) type
{
    DCMPix *curPix = [imageView curDCM];
    ROI		*theNewROI;
    
    theNewROI = [[[ROI alloc] initWithType: type :[curPix pixelSpacingX] :[curPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: curPix]] autorelease];
    
    [imageView roiSet: theNewROI];
    
    return theNewROI;
}

- (BOOL) containsROI:(ROI*)roi
{
    for ( NSArray* roiImageList in [self roiList])
    {
        for (ROI *r in roiImageList)
            if (r == roi)
                return YES;
    }
    
    return NO;
}

- (NSMutableArray*) generateROINamesArray
{
    [ROINamesArray release];
    ROINamesArray = [[NSMutableArray alloc] initWithCapacity:0];
    [ROINamesArray addObjectsFromArray: DefaultROINames];
    
    // Scan all ROIs of current series to find other names!
    long	y, x, z;
    BOOL	first = YES, found;
    for( y = 0; y < maxMovieIndex; y++)
    {
        for( x = 0; x < [pixList[y] count]; x++)
        {
            for( z = 0; z < [[roiList[y] objectAtIndex: x] count]; z++)
            {
                //	NSLog( [[[roiList[y] objectAtIndex: x] objectAtIndex: z] name]);
                found = NO;
                for( id loopItem3 in ROINamesArray)
                {
                    if( [loopItem3 isEqualToString: [[[roiList[y] objectAtIndex: x] objectAtIndex: z] name]])
                    {
                        found = YES;
                    }
                }
                if( found == NO)
                {
                    if( first) [ROINamesArray addObject: @"-"];
                    first = NO;
                    [ROINamesArray addObject: [[[roiList[y] objectAtIndex: x] objectAtIndex: z] name] ];
                }
            }
        }
    }
    return ROINamesArray;
}

//-------------------------------------------------------------

- (NSImage*) imageForROI: (ToolMode) i
{
    NSString	*filename = nil;
    switch( i)
    {
        case tWL:			filename = @"WLWW";				break;
        case tZoom:			filename = @"Zoom";				break;
        case tTranslate:	filename = @"Move";				break;
        case tRotate:		filename = @"Rotate";			break;
        case tNext:			filename = @"Stack";			break;
        case tMesure:		filename = @"Length";			break;
        case tAngle:		filename = @"Angle";			break;
        case tROI:			filename = @"Rectangle";		break;
        case tOval:			filename = @"Oval";				break;
        case tText:			filename = @"Text";				break;
        case tArrow:		filename = @"Arrow";			break;
        case tOPolygon:		filename = @"Opened Polygon";	break;
        case tCPolygon:		filename = @"Closed Polygon";	break;
        case tPencil:		filename = @"Pencil";			break;
        case t2DPoint:		filename = @"Point";			break;
        case tPlain:		filename = @"Brush";			break;
        case tRepulsor:		filename = @"Repulsor";			break;
        case tROISelector:	filename = @"ROISelector";		break;
        case tAxis:			filename = @"Axis";				break;
        case tDynAngle:		filename = @"DynamicAngle";		break;
        case tTAGT:         filename = @"PerpendicularLines";             break;
        default:;
    }
    
    return [NSImage imageNamed: filename];
}

// shows on top the first ROI manager window found
- (IBAction) roiGetManager:(id) sender
{
    BOOL	found = NO;
    NSArray *winList = [NSApp windows];
    
    for( id loopItem in winList)
    {
        if( [[[loopItem windowController] windowNibName] isEqualToString:@"ROIManager"])
        {
            found = YES;
        }
    }
    
    if( !found)
    {
        ROIManagerController *manager = [[ROIManagerController alloc] initWithViewer: self];
        if( manager)
        {
            [manager showWindow:self];
            [[manager window] makeKeyAndOrderFront:self];
        }
    }
}


-(void)addRoiFromFullStackBuffer:(unsigned char*)buff
{
    [self addRoiFromFullStackBuffer:buff withName:@""];
}

-(void)addPlainRoiToCurrentSliceFromBuffer:(unsigned char*)buff
{
    [self addPlainRoiToCurrentSliceFromBuffer:buff withName:@""];
}

-(void)addPlainRoiToCurrentSliceFromBuffer:(unsigned char*)buff withName:(NSString*)name
{
    int i,j,l;
    unsigned char tempValue;
    BOOL alreadyIn=NO;
    
    RGBColor aColor;
    //float *r,*g,*b;
    int nbColor=6;
    
    // color init
    RGBColor rgbList[6];
    aColor.red = (239./255.)*65535.;
    aColor.green = (239./255.)*65535.;
    aColor.blue = 37;
    rgbList[0]=aColor;
    
    aColor.red = (239./255.)*65535.;
    aColor.green =(10./255.)*65535.;
    aColor.blue = (239./255.)*65535;
    rgbList[1]=aColor;
    
    aColor.red = 65535;
    aColor.green =0;
    aColor.blue = 0;
    rgbList[2]=aColor;
    
    aColor.red =0;
    aColor.green = 0;
    aColor.blue =65535;
    rgbList[3]=aColor;
    
    aColor.red = 0;
    aColor.green = 65535;
    aColor.blue = 0;
    rgbList[4]=aColor;
    
    aColor.red = 0;
    aColor.green =(241./255.)*65535.;
    aColor.blue = (220./255.)*65535.;
    rgbList[5]=aColor;
    
    NSMutableArray* nbRegion=[NSMutableArray array];
    DCMPix	*curPix = [[self pixList] objectAtIndex: [imageView curImage]];
    long height=[curPix pheight];
    long width=[curPix pwidth];
    for(j=0;j<height;j++)
    {
        for(i=0;i<width;i++)
        {
            tempValue=buff[(long)(i+j*width)];
            if (tempValue!=0)
            {
                alreadyIn=NO;
                // check if the region has not been already added to the nbRegion Mutable Array
                for(l=0;l<[nbRegion count];l++)
                    if ([[nbRegion objectAtIndex:l] intValue]==tempValue)
                        alreadyIn=YES;
                if(!alreadyIn)
                    [nbRegion addObject:[NSNumber numberWithInt:tempValue]];
            }
        }
    }
    
    for(l=0;l<[nbRegion count];l++)
        [self	addPlainRoiToCurrentSliceFromBuffer:buff
                                 forSpecificValue:[[nbRegion objectAtIndex:l] intValue]
                                        withColor:rgbList[l % nbColor]
                                         withName:name];
    
}
-(void)addPlainRoiToCurrentSliceFromBuffer:(unsigned char*)buff forSpecificValue:(unsigned char)value withColor:(RGBColor)aColor withName:(NSString*)name
{
    int i,j,l;
    ROI		*theNewROI;
    DCMPix	*curPix = [[self pixList] objectAtIndex: [imageView curImage]];
    long height=[curPix pheight];
    long width=[curPix pwidth];
    int upLeftX,upLeftY,dRightX,dRightY;
    int tWidth,tHeight;
    unsigned char* textureBuffer;
    BOOL findOne=false;
    
    // 1- For a Slice find the texture dimension for the specific value (param: value)
    findOne=NO;
    upLeftX=width;upLeftY=height;dRightX=0;dRightY=0; // initialisation with opposite values
    for(j=0;j<height;j++)
        for(i=0;i<width;i++)
        {
            if (buff[(long)(i+j*width)]==value)
            {
                findOne=YES;
                // boundary check
                if(i<upLeftX)
                    upLeftX=i;
                if(j<upLeftY)
                    upLeftY=j;
                if (i>dRightX)
                    dRightX=i;
                if (j>dRightY)
                    dRightY=j;
            }
        }
				
				// Create texture ...
				if (findOne)
                {
                    tWidth=dRightX-upLeftX+1;
                    tHeight=dRightY-upLeftY+1;
                    textureBuffer=(unsigned char*)malloc(tWidth*tHeight*sizeof(unsigned char));
                    // clear texture
                    for (l=0;l<tWidth*tHeight;l++)
                        textureBuffer[(long)l]=0;
                    
                    // fill in the texture
                    for(j=0;j<height;j++)
                        for(i=0;i<width;i++)
                            if (buff[(long)(i+j*width)]==value)
                                textureBuffer[(long)((i-upLeftX)+(j-upLeftY)*tWidth)]=0xFF;
                    
                    // 2- create a roi with the (initWithTexture) at slice k
                    name = ([name isEqualToString:@""])? [NSString stringWithFormat:@"area %d",value] : name;
                    theNewROI = [[[ROI alloc] initWithTexture:textureBuffer  textWidth:tWidth textHeight:tHeight textName:name
                                                    positionX:upLeftX positionY:upLeftY
                                                     spacingX:[curPix pixelSpacingX]  spacingY:[curPix pixelSpacingY]
                                                  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])] autorelease];
                    free(textureBuffer);
                    [theNewROI setColor:aColor];
                    //	NSLog(@"New roi has been created name=%@, color.red=%d, color.green=%d, color.blue=%d",[theNewROI name], aColor.red, aColor.green, aColor.blue);
                    [[[self roiList] objectAtIndex:[imageView curImage]] addObject:theNewROI];
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:theNewROI userInfo: nil];
                }
    
}

-(void)addRoiFromFullStackBuffer:(unsigned char*)buff withName:(NSString*)name
{
    int i,j,k,l;
    unsigned char tempValue;
    BOOL alreadyIn=NO;
    
    RGBColor aColor;
    //float *r,*g,*b;
    int nbColor=6;
    
    // color init
    RGBColor rgbList[6];
    aColor.red = (239./255.)*65535.;
    aColor.green = (239./255.)*65535.;
    aColor.blue = 37;
    rgbList[0]=aColor;
    
    aColor.red = (239./255.)*65535.;
    aColor.green =(10./255.)*65535.;
    aColor.blue = (239./255.)*65535;
    rgbList[1]=aColor;
    
    aColor.red = 65535;
    aColor.green =0;
    aColor.blue = 0;
    rgbList[2]=aColor;
    
    aColor.red =0;
    aColor.green = 0;
    aColor.blue =65535;
    rgbList[3]=aColor;
    
    aColor.red = 0;
    aColor.green = 65535;
    aColor.blue = 0;
    rgbList[4]=aColor;
    
    aColor.red = 0;
    aColor.green =(241./255.)*65535.;
    aColor.blue = (220./255.)*65535.;
    rgbList[5]=aColor;
    
    /*
     // 1- blue
     [[NSColor blueColor] getRed:r green:g blue:b alpha:nil];
     aColor.red = *r * 65535.;
     aColor.green = *g * 65535.;
     aColor.blue = *b * 65535.;
     rgbList[cpt]=aColor;
     cpt++;
     NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
     //  yellow
     [[NSColor yellowColor] getRed:r green:g blue:b alpha:nil];
     aColor.red = *r * 65535.;
     aColor.green = *g * 65535.;
     aColor.blue = *b * 65535.;
     rgbList[cpt]=aColor;
     cpt++;
     NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
     // purpleColor
     [[NSColor redColor] getRed:r green:g blue:b alpha:nil];
     aColor.red = *r * 65535.;
     aColor.green = *g * 65535.;
     aColor.blue = *b * 65535.;
     rgbList[cpt]=aColor;
     cpt++;
     NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
     //magentaColor
     [[NSColor magentaColor] getRed:r green:g blue:b alpha:nil];
     aColor.red = *r * 65535.;
     aColor.green = *g * 65535.;
     aColor.blue = *b * 65535.;
     rgbList[cpt]=aColor;
     cpt++;
     NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
     // orangeColor
     [[NSColor orangeColor] getRed:r green:g blue:b alpha:nil];
     aColor.red = *r * 65535.;
     aColor.green = *g * 65535.;
     aColor.blue = *b * 65535.;
     rgbList[cpt]=aColor;
     cpt++;
     NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
     // redColor
     [[NSColor redColor] getRed:r green:g blue:b alpha:nil];
     aColor.red = *r * 65535.;
     aColor.green = *g * 65535.;
     aColor.blue = *b * 65535.;
     rgbList[cpt]=aColor;
     cpt++;
     NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
     */
    NSMutableArray* nbRegion=[NSMutableArray array];
    DCMPix	*curPix = [[self pixList] objectAtIndex: [imageView curImage]];
    long height=[curPix pheight];
    long width=[curPix pwidth];
    long depth=[[self pixList] count];
    for (k=0;k<depth;k++)
    {
        for(j=0;j<height;j++)
        {
            for(i=0;i<width;i++)
            {
                tempValue=buff[(long)(i+j*width+k*width*height)];
                if (tempValue!=0)
                {
                    alreadyIn=NO;
                    // check if the region has not been already added to the nbRegion Mutable Array
                    for(l=0;l<[nbRegion count];l++)
                        if ([[nbRegion objectAtIndex:l] intValue]==tempValue)
                            alreadyIn=YES;
                    if(!alreadyIn)
                        [nbRegion addObject:[NSNumber numberWithInt:tempValue]];
                }
            }
        }
    }
    for(l=0;l<[nbRegion count];l++)
        [self	addRoiFromFullStackBuffer:buff
                       forSpecificValue:[[nbRegion objectAtIndex:l] intValue]
                              withColor:rgbList[l % nbColor]
                               withName:name];
    
}

-(void)addRoiFromFullStackBuffer:(unsigned char*)buff forSpecificValue:(unsigned char)value withColor:(RGBColor)aColor
{
    [self addRoiFromFullStackBuffer:buff forSpecificValue:value withColor:aColor withName:@""];
}
-(void)addRoiFromFullStackBuffer:(unsigned char*)buff forSpecificValue:(unsigned char)value withColor:(RGBColor)aColor withName:(NSString*)name
{
    int i,j,k,l;
    ROI		*theNewROI;
    DCMPix	*curPix = [[self pixList] objectAtIndex: [imageView curImage]];
    long height=[curPix pheight];
    long width=[curPix pwidth];
    long depth=[[self pixList] count];
    int upLeftX,upLeftY,dRightX,dRightY;
    int tWidth,tHeight;
    unsigned char* textureBuffer;
    BOOL findOne=false;
    for (k=0;k<depth;k++)
    {
        // 1- For a Slice find the texture dimension for the specific value (param: value)
        findOne=NO;
        upLeftX=width;upLeftY=height;dRightX=0;dRightY=0; // initialisation with opposite values
        for(j=0;j<height;j++)
            for(i=0;i<width;i++)
            {
                if (buff[(long)(i+j*width+k*width*height)]==value)
                {
                    findOne=YES;
                    // boundary check
                    if(i<upLeftX)
                        upLeftX=i;
                    if(j<upLeftY)
                        upLeftY=j;
                    if (i>dRightX)
                        dRightX=i;
                    if (j>dRightY)
                        dRightY=j;
                }
            }
        
        // Create texture ...
        if (findOne)
        {
            tWidth=dRightX-upLeftX+1;
            tHeight=dRightY-upLeftY+1;
            textureBuffer=(unsigned char*)malloc(tWidth*tHeight*sizeof(unsigned char));
            // clear texture
            for (l=0;l<tWidth*tHeight;l++)
                textureBuffer[(long)l]=0;
            
            // fill in the texture
            for(j=0;j<height;j++)
                for(i=0;i<width;i++)
                    if (buff[(long)(i+j*width+k*width*height)]==value)
                        textureBuffer[(long)((i-upLeftX)+(j-upLeftY)*tWidth)]=0xFF;
            
            // 2- create a roi with the (initWithTexture) at slice k
            name = ([name isEqualToString:@""])? [NSString stringWithFormat:@"area %d",value] : name;
            theNewROI = [[[ROI alloc] initWithTexture:textureBuffer  textWidth:tWidth textHeight:tHeight textName:name
                                            positionX:upLeftX positionY:upLeftY
                                             spacingX:[curPix pixelSpacingX]  spacingY:[curPix pixelSpacingY]
                                          imageOrigin:NSMakePoint( [curPix originX], [curPix originY])] autorelease];
            free(textureBuffer);
            [theNewROI setColor:aColor];
            //	NSLog(@"New roi has been created name=%@, color.red=%d, color.green=%d, color.blue=%d",[theNewROI name], aColor.red, aColor.green, aColor.blue);
            [[[self roiList] objectAtIndex:k] addObject:theNewROI];
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:theNewROI userInfo: nil];
        }
    }
}

//- (ROI*)addLayerRoiToCurrentSliceWithImage:(NSImage*)image imageWhenSelected:(NSImage*)imageWhenSelected referenceFilePath:(NSString*)path layerPixelSpacingX:(float)layerPixelSpacingX layerPixelSpacingY:(float)layerPixelSpacingY;
- (ROI*)addLayerRoiToCurrentSliceWithImage:(NSImage*)image referenceFilePath:(NSString*)path layerPixelSpacingX:(float)layerPixelSpacingX layerPixelSpacingY:(float)layerPixelSpacingY;
{
    DCMPix *curPix = [[self pixList] objectAtIndex:[imageView curImage]];
    
    ROI *theNewROI = [[[ROI alloc] initWithType:tLayerROI :[curPix pixelSpacingX] :[curPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: curPix]] autorelease];
    [theNewROI setLayerPixelSpacingX:layerPixelSpacingX];
    [theNewROI setLayerPixelSpacingY:layerPixelSpacingY];
    [theNewROI setLayerReferenceFilePath:path];
    [theNewROI setLayerImage:image];
    
    //	[theNewROI setLayerImageWhenSelected:imageWhenSelected];
    
    [[[self roiList] objectAtIndex:[imageView curImage]] addObject:theNewROI];
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:theNewROI userInfo:nil];
    [self selectROI:theNewROI deselectingOther:YES];
    
    return theNewROI;
}

- (ROI*)createLayerROIFromROI:(ROI*)roi;
{
    if( roi.type == tText) return nil;
    if( roi.type == tMesure) return nil;
    if( roi.type == tArrow) return nil;
    if( roi.type == t2DPoint) return nil;
    
    float *data;
    float *locations;
    long dataSize;
    data = [[[roi curView] curDCM] getROIValue:&dataSize :roi :&locations];
    
    float minX = locations[0];
    float minY = locations[1];
    float maxX = locations[0];
    float maxY = locations[1];
    float x, y;
    int i;
    for (i=1; i<dataSize; i++)
    {
        x = locations[2*i];
        y = locations[2*i+1];
        if(x<minX) minX = x;
        if(y<minY) minY = y;
        if(x>maxX) maxX = x;
        if(y>maxY) maxY = y;
    }
    
    int imageHeight = maxY - minY+1;
    int imageWidth = maxX - minX+1;
    NSLog(@"imageWidth : %d, imageHeight: %d", imageWidth, imageHeight);
    
    NSBitmapImageRep *bitmap;
    
    bitmap = [[NSBitmapImageRep alloc]
              initWithBitmapDataPlanes:nil
              pixelsWide:imageWidth
              pixelsHigh:imageHeight
              bitsPerSample:8
              samplesPerPixel:4
              hasAlpha:YES
              isPlanar:NO
              colorSpaceName:NSCalibratedRGBColorSpace
              bytesPerRow:imageWidth*4
              bitsPerPixel:32];
    
    unsigned char *imageBuffer = [bitmap bitmapData];
    
    // need the window level to do a RGB image
    float windowLevel, windowWidth;
    [imageView getWLWW:&windowLevel :&windowWidth];
    float windowLevelMax = windowLevel + 0.5 * windowWidth;
    float windowLevelMin = windowLevel - 0.5 * windowWidth;
    
    float value;
    unsigned char imageValue;
    
    int bytesPerRow = [bitmap bytesPerRow];
    
    //	NSBitmapFormat format = [bitmap bitmapFormat];
    
    BOOL isRGB = [[imageView curDCM] isRGB];
    
    // transfer curve rgb = a * value + b
    float a = 255.0 / windowWidth;
    float b = - a * windowLevelMin;
    
    for (i=0; i<dataSize; i++)
    {
        x = locations[2*i] - minX;
        y = locations[2*i+1] - minY;
        value = data[i];
        
        if(!isRGB)
        {
            if(value>windowLevelMax) imageValue = 255;
            else if(value<windowLevelMin) imageValue = 0;
            else
            {
                imageValue = (char)(a * value + b);
            }
        }
        else
            imageValue = value;
        imageBuffer[4*(int)x+(int)y*(int)bytesPerRow] = imageValue;
        imageBuffer[4*(int)x+1+(int)y*(int)bytesPerRow] = imageValue;
        imageBuffer[4*(int)x+2+(int)y*(int)bytesPerRow] = imageValue;
        imageBuffer[4*(int)x+3+(int)y*(int)bytesPerRow] = 255;
    }
    
    NSImage *image = [[NSImage alloc] init] ;
    
    [image addRepresentation: bitmap];
    
    NSLog(@"image: %f, %f", [image size].width, [image size].height);
    NSLog(@"pixelSpacing: %f, %f", [[imageView curDCM] pixelSpacingX], [[imageView curDCM] pixelSpacingY]);
    
    NSLog(@"addLayerRoiToCurrentSliceWithImage");
    ROI* theNewROI = [self addLayerRoiToCurrentSliceWithImage:image referenceFilePath:@"none" layerPixelSpacingX:[[imageView curDCM] pixelSpacingX] layerPixelSpacingY:[[imageView curDCM] pixelSpacingY]];
    
    NSLog(@"setName");
    [theNewROI setName:[NSString stringWithFormat:@"%@ %@", [roi name], NSLocalizedString(@"Layer", nil)]];
    [theNewROI setIsLayerOpacityConstant:NO];
    [theNewROI setCanColorizeLayer:YES];
    //[theNewROI loadLayerImageTexture];
    
    free(data);
    free(locations);
    [image release];
    [bitmap release];
    
    // move the new ROI to its location
    NSPoint offset;
    offset.x = maxX;
    offset.y = maxY;
    NSPoint p = [theNewROI lowerRightPoint];
    offset.x -= p.x;
    offset.y -= p.y;
    
    offset.x += 10;
    offset.y -= 10;
    
    NSArray *newROIPoints = [theNewROI points];
    for (i=0; i<[newROIPoints count]; i++)
    {
        [[newROIPoints objectAtIndex:i] move:offset.x :offset.y];
    }
    
    [self selectROI:theNewROI deselectingOther:YES];
    
    return theNewROI;
}

- (void)createLayerROIFromSelectedROI;
{
    [self createLayerROIFromROI:[self selectedROI]];
}

- (IBAction)createLayerROIFromSelectedROI:(id)sender;
{
    [self createLayerROIFromSelectedROI];
}

- (void) deleteROI: (ROI*) roi
{
    [imageView stopROIEditingForce: YES];
    
    for( NSMutableArray *x in roiList[curMovieIndex])
    {
        [x retain];
        
        for( int i = 0; i < [x count]; i++)
        {
            ROI	*curROI = [x objectAtIndex: i];
            if( curROI == roi)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:curROI userInfo: nil];
                [x removeObject:curROI];
                i--;
            }
        }
        
        [x autorelease];
    }
}

- (void) deleteSeriesROIwithName: (NSString*) name
{
    long i;
    
    [name retain];
    
    [imageView stopROIEditingForce: YES];
    
    for( NSMutableArray *x in roiList[curMovieIndex])
    {
        [x retain];
        
        for( i = 0; i < [x count]; i++)
        {
            ROI	*curROI = [x objectAtIndex: i];
            if( [[curROI name] isEqualToString: name])
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:curROI userInfo: nil];
                [x removeObject:curROI];
                i--;
            }
        }
        
        [x autorelease];
    }
    
    [name release];
}

- (void) renameSeriesROIwithName: (NSString*) name newName:(NSString*) newString
{
    long	x, i;
    
    [name retain];
    
    for( x = 0; x < [pixList[curMovieIndex] count]; x++)
    {
        
        for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
        {
            ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
            if( [[curROI name] isEqualToString: name])
            {
                [curROI setName: newString];
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
            }
        }
    }
    
    [name release];
}

- (void) roiLoadFromSeries: (NSString*) filename
{
    // Unselect all ROIs
    [self roiSelectDeselectAll: nil];
    
    NSArray *roisMovies = [NSUnarchiver unarchiveObjectWithFile: filename];
    
    for( int y = 0; y < maxMovieIndex; y++)
    {
        if( [roisMovies count] > y)
        {
            NSArray *roisSeries = [roisMovies objectAtIndex: y];
            
            for( int x = 0; x < [pixList[y] count]; x++)
            {
                DCMPix *pic = [pixList[ y] objectAtIndex: x];
                
                if( [roisSeries count] > x)
                {
                    NSArray *roisImages = [roisSeries objectAtIndex: x];
                    
                    for( ROI *r in roisImages)
                    {
                        //Correct the origin only if the orientation is the same
                        r.pix = pic;
                        
                        [r setOriginAndSpacing: pic.pixelSpacingX :pic.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: pic]];
                        
                        [[roiList[ y] objectAtIndex: x] addObject: r];
                        [imageView roiSet: r];
                    }
                }
            }
        }
    }
    
    [imageView setIndex: [imageView curImage]];
}

- (IBAction) roiLoadFromFiles: (id) sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:YES];
    [panel setCanChooseDirectories:NO];
    
    panel.allowedFileTypes = @[@"roi", @"rois_series", @"xml"];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        if( [[panel.URLs.lastObject pathExtension] isEqualToString:@"xml"])
            [imageView roiLoadFromXMLFiles:[panel.URLs valueForKeyPath:@"path"]];
        else if( [[panel.URLs.lastObject pathExtension] isEqualToString:@"rois_series"])
            [self roiLoadFromSeries:panel.URLs.lastObject.path];
        else
            [imageView roiLoadFromFilesArray:[panel.URLs valueForKeyPath:@"path"]];
    }];
}

- (IBAction) roiSaveSeries: (id) sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSMutableArray *roisPerMovies = [NSMutableArray  array];
    BOOL rois = NO;
    
    for( int y = 0; y < maxMovieIndex; y++)
    {
        NSMutableArray  *roisPerSeries = [NSMutableArray  array];
        
        for( int x = 0; x < [pixList[ y] count]; x++)
        {
            NSMutableArray  *roisPerImages = [NSMutableArray  array];
            
            for( int i = 0; i < [[roiList[ y] objectAtIndex: x] count]; i++)
            {
                ROI	*curROI = [[roiList[ y] objectAtIndex: x] objectAtIndex: i];
                
                [roisPerImages addObject: curROI];
                
                rois = YES;
            }
            
            [roisPerSeries addObject: roisPerImages];
        }
        
        [roisPerMovies addObject: roisPerSeries];
    }
    
    if( rois > 0)
    {
        [panel setCanSelectHiddenExtension:NO];
        [panel setAllowedFileTypes:@[@"rois_series"]];
        panel.nameFieldStringValue = [[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.name"];
        
        [panel beginWithCompletionHandler:^(NSInteger result) {
            if (result != NSFileHandlingPanelOKButton)
                return;
            [NSArchiver archiveRootObject: roisPerMovies toFile :panel.URL.path];
        }];
    }
    else
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Save Error",nil), NSLocalizedString(@"No ROIs in this series!",nil) , NSLocalizedString(@"OK",nil), nil, nil);
    }
}

- (IBAction) roiSelectDeselectAll:(id) sender
{
    int x, i;
    
    [self addToUndoQueue: @"roi"];
    
    for( x = 0; x < [pixList[curMovieIndex] count]; x++)
    {
        
        for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
        {
            ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
            
            if( [sender tag])
            {
                [curROI setROIMode: ROI_selected];
            }
            else
            {
                [curROI setROIMode: ROI_sleep];
            }
        }
    }
    
    [imageView setNeedsDisplay: YES];
}

- (IBAction) roiVolumeEraseRestore:(id) sender
{
#ifndef OSIRIX_LIGHT
    for( int i = 0; i < maxMovieIndex; i++)
        [self saveROI: i];
    
    [self computeInterval];
    
    ROI *selectedRoi = [self selectedROI];
    
    if( selectedRoi == nil)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Select a ROI.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    NSString *error = nil;
    [self computeVolume: selectedRoi points: nil generateMissingROIs: YES generatedROIs: nil computeData: nil error: &error];
    
    if( error)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), @"%@" , NSLocalizedString(@"OK", nil), nil, nil, error);
    }
    else
    {
        if( [sender tag])	// Restore
        {
            [self roiSetPixels: selectedRoi :0 :NO :NO :-FLT_MAX :FLT_MAX :0 :YES];	//MINFLOAT //maxfloat float.h
        }
        else				// Erase
        {
            [self roiSetPixels: selectedRoi :0 :NO :NO :-FLT_MAX :FLT_MAX :[[pixList[ curMovieIndex] objectAtIndex: 0] minValueOfSeries] :NO];
        }
        
        // Recompute!!!! Apply WL/WW
        float   iwl, iww;
        
        [imageView getWLWW:&iwl :&iww];
        [imageView setWLWW:iwl :iww];
        
        int y, x, i;
        // Recompute all ROIs
        for( y = 0; y < maxMovieIndex; y++)
        {
            for( x = 0; x < [pixList[y] count]; x++)
            {
                for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++) [[[roiList[y] objectAtIndex: x] objectAtIndex: i] recompute];
                
                [[pixList[y] objectAtIndex: x] changeWLWW:iwl :iww];	//recompute WLWW
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList[ curMovieIndex] userInfo: nil];
    }
#endif
}

- (IBAction) roiIntDeleteAllROIsWithSameName :(NSString*) name
{
    int i;
    
    [name retain];
    
    [self addToUndoQueue: @"roi"];
    
    for( NSMutableArray *x in roiList[curMovieIndex])
    {
        [x retain];
        
        for( i = 0; i < [x count]; i++)
        {
            ROI	*curROI = [x objectAtIndex: i];
            if( [[curROI name] isEqualToString: name] && curROI.locked == NO)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:curROI userInfo: nil];
                [x removeObject: curROI];
                i--;
            }
        }
        
        [x autorelease];
    }
    
    [name release];
    [[self imageView] setNeedsDisplay:YES];
}

- (IBAction) roiDeleteAllROIsWithSameName:(id) sender
{
    ROI	*selectedROI = [self selectedROI];
    
    if( selectedROI)
    {
        [self roiIntDeleteAllROIsWithSameName: [selectedROI name]];
    }
    else NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Error", nil), NSLocalizedString(@"Select a ROI to delete all ROIs with the same name.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
}

- (IBAction) roiDeleteWithName:(NSString*) name
{
    [self roiIntDeleteAllROIsWithSameName: name];
}

- (int) roiIntDeleteGeneratedROIsForName:(NSString*) name
{
    int no = 0;
    
    for( int i = 0; i < maxMovieIndex; i++)
        [self saveROI: i];
    
    [name retain];
    
    [self addToUndoQueue: @"roi"];
    
    [imageView stopROIEditingForce: YES];
    
    for( NSMutableArray *x in roiList[curMovieIndex])
    {
        [x retain];
        
        for( int i = 0; i < [x count]; i++)
        {
            ROI	*curROI = [x objectAtIndex: i];
            if( [[curROI comments] isEqualToString: @"morphing generated"])
            {
                if( [[curROI name] isEqualToString: name] || name == nil)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:curROI userInfo: nil];
                    [x removeObject: curROI];
                    i--;
                    
                    no++;
                }
            }
        }
        
        [x autorelease];
    }
    
    [imageView setIndex: [imageView curImage]];
    
    [name release];
    
    return no;
}

- (IBAction) roiDeleteGeneratedROIsForName:(NSString*) name
{
    [self roiIntDeleteGeneratedROIsForName: name];
}

- (IBAction) roiDeleteGeneratedROIs:(id) sender
{
    [self roiDeleteGeneratedROIsForName: nil];
}

#ifndef OSIRIX_LIGHT

- (IBAction) roiVolume:(id) sender
{
    float preLocation, interval;
    ROI *selectedRoi = nil;
    
    [self computeInterval];
    
    [self displayAWarningIfNonTrueVolumicData];
    
    for( int i = 0; i < maxMovieIndex; i++)
        [self saveROI: i];
    
    selectedRoi = [self selectedROI];
    
    if( selectedRoi == nil)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Select a ROI to compute volume of all ROIs with the same name.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    // Check that sliceLocation is available and identical for all images
    preLocation = 0;
    interval = 0;
    
    for( DCMPix *curPix in pixList[ curMovieIndex])
    {
        if( preLocation != 0)
        {
            if( interval)
            {
                if( fabs( [curPix sliceLocation] - preLocation - interval) > 1.0)
                {
                    NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Slice Interval is not constant!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
                    return;
                }
            }
            interval = [curPix sliceLocation] - preLocation;
        }
        preLocation = [curPix sliceLocation];
    }
    
    NSLog(@"Slice Interval : %f", interval);
    
    if( [sender tag] == 0) // Compute Volume
    {
        if( interval == 0)
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Slice Locations not available to compute a volume.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
            return;
        }
    }
    
    [self addToUndoQueue: @"roi"];
    
    WaitRendering *splash = [[[WaitRendering alloc] init:NSLocalizedString(@"Preparing data...", nil)] autorelease];
    [splash showWindow:self];
    
    // Show Volume Window
    if( [sender tag] == 0)
    {
        ROIVolumeController	*viewer = [[ROIVolumeController alloc] initWithRoi:selectedRoi viewer:self];
        
        [viewer showWindow: self];
        [[viewer window] center];
    }
    else if([sender tag] == 1)
    {
        [self computeVolume: selectedRoi points: nil generateMissingROIs: YES generatedROIs: nil computeData: nil error: nil];
        
        int	numberOfGeneratedROIafter = [[self roisWithComment: @"morphing generated"] count];
        if(!numberOfGeneratedROIafter)
            NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"The missing ROIs were not created : this feature does not work with ROIs that don't contain an area.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    
    [splash close];
}
#endif

-(IBAction) roiSetPixelsSetup:(id) sender
{
    ROI		*selectedRoi = nil;
    
    selectedRoi = [self selectedROI];
    
    [maxValueText setFloatValue: [[pixList[0] objectAtIndex: 0] maxValueOfSeries]];
    [minValueText setFloatValue: [[pixList[0] objectAtIndex: 0] minValueOfSeries]];
    [newValueText setFloatValue: [[pixList[0] objectAtIndex: 0] minValueOfSeries]];
    
    if( selectedRoi == nil)
    {
        [InOutROI setEnabled:NO];
        [InOutROI selectCellWithTag:1];
        
        [[AllROIsRadio cellWithTag:1] setEnabled:NO];
        [[AllROIsRadio cellWithTag:0] setEnabled:NO];
        
        [AllROIsRadio selectCellWithTag:2];
    }
    else
    {
        [InOutROI setEnabled:YES];
        
        [AllROIsRadio selectCellWithTag:0];
        [[AllROIsRadio cellWithTag:1] setEnabled:YES];
        [[AllROIsRadio cellWithTag:0] setEnabled:YES];
    }
    
    if( maxMovieIndex != 1) [setROI4DSeries setEnabled: YES];
    else [setROI4DSeries setEnabled: NO];
    
    [self roiSetPixelsCheckButton: self];
    
    [NSApp beginSheet: roiSetPixWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) recomputeROI :(NSNotification*) note
{
    long	i, x, y;
    
    if( [note object] == self)
    {
        // Recompute all ROIs
        for( y = 0; y < maxMovieIndex; y++)
        {
            for( x = 0; x < [pixList[y] count]; x++)
            {
                for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++) [[[roiList[y] objectAtIndex: x] objectAtIndex: i] recompute];
                
                //[[pixList[y] objectAtIndex: x] changeWLWW:iwl :iww];	//recompute image
            }
        }
    }
    
    [self willChangeValueForKey: @"thicknessInMm"];
    [self didChangeValueForKey: @"thicknessInMm"];
}

- (IBAction) roiSetPixelsCheckButton:(id) sender
{
    BOOL restoreAvailable = YES;
    
    if( [setROI4DSeries state] && maxMovieIndex > 1)
    {
        restoreAvailable = NO;
    }
    
    if( postprocessed)
    {
        restoreAvailable = NO;
    }
    
    if( [checkMaxValue state] || [checkMinValue state])
    {
        restoreAvailable = NO;
    }
    
    if( [[InOutROI selectedCell] tag])
    {
        restoreAvailable = NO;
    }
    
    if( [[AllROIsRadio selectedCell] tag] == 2)	// All pixels
    {
        restoreAvailable = NO;
    }
    
    if( restoreAvailable == NO)
    {
        [[newValueMatrix cellWithTag: 1] setEnabled: NO];
        [newValueMatrix selectCellWithTag: 0];
    }
    else [[newValueMatrix cellWithTag: 1] setEnabled: YES];
}

- (IBAction) roiSetPixels:(id) sender
{
    for( int i = 0; i < maxMovieIndex; i++)
        [self saveROI: i];
    
    // end sheet
    [roiSetPixWindow orderOut:sender];
    [NSApp endSheet:roiSetPixWindow returnCode:[sender tag]];
    // do it only if OK button pressed
    if( [sender tag] != 1) return;
    
    // Find the first ROI selected
    ROI *selectedROI = nil;
    long i,y,x;
    
    for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
    {
        long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
        
        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
        {
            selectedROI = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
        }
    }
    
    // user's parameters
    BOOL outside = [[InOutROI selectedCell] tag];
    short allRois = [[AllROIsRadio selectedCell] tag];
    
    float minValue = -FLT_MAX;
    float maxValue = FLT_MAX;
    if( [checkMaxValue state] == NSOnState) maxValue = [maxValueText floatValue];
    if( [checkMinValue state] == NSOnState) minValue = [minValueText floatValue];
    
    BOOL propagateIn4D = [setROI4DSeries state] == NSOnState;
    
    float newValue = [newValueText floatValue];
    BOOL revertToSaved = [newValueMatrix selectedTag];
    
    // proceed
    [self roiSetPixels:selectedROI :allRois :propagateIn4D :outside :minValue :maxValue :newValue :revertToSaved];
    
    // Recompute!!!! Apply WL/WW
    float   iwl, iww;
    
    [imageView getWLWW:&iwl :&iww];
    [imageView setWLWW:iwl :iww];
    
    // Recompute all ROIs
    for( y = 0; y < maxMovieIndex; y++)
    {
        for( x = 0; x < [pixList[y] count]; x++)
        {
            for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++) [[[roiList[y] objectAtIndex: x] objectAtIndex: i] recompute];
            
            [[pixList[y] objectAtIndex: x] changeWLWW:iwl :iww];	//recompute WLWW
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList[ curMovieIndex] userInfo: nil];
}

- (void) roiSetStartScheduler:(NSMutableArray*) roiToProceed
{
#ifndef OSIRIX_LIGHT
    if( [roiToProceed count])
    {
        [roiLock lock];
        
        @try
        {
            NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
            
            for( id loopItem in roiToProceed)
            {
                ViewerControllerOperation *op = [[[ViewerControllerOperation alloc] initWithController: self dict: loopItem] autorelease];
                
                [queue addOperation: op];
            }
            
            [queue waitUntilAllOperationsAreFinished];
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        
        [roiLock unlock];
    }
#endif
}

- (IBAction) roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL) propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue :(BOOL) revert
{
    long			i, x, y, z;
    BOOL			done, proceed;
    NSMutableArray	*roiToProceed = [NSMutableArray array];
    NSNumber		*nsnewValue, *nsminValue, *nsmaxValue, *nsoutside, *nsrevert;
    
    nsnewValue	= [NSNumber numberWithFloat: newValue];
    nsminValue	= [NSNumber numberWithFloat: minValue];
    nsmaxValue	= [NSNumber numberWithFloat: maxValue];
    nsoutside	= [NSNumber numberWithBool: outside];
    nsrevert	= [NSNumber numberWithBool: revert];
    
    [self checkEverythingLoaded];
    
    WaitRendering *splash = [[WaitRendering alloc] init: NSLocalizedString( @"Filtering...", nil)];
    [splash showWindow:self];
    
    NSLog(@"startSetPixel");
    
    for( y = 0; y < maxMovieIndex; y++)
    {
        if( y == curMovieIndex) proceed = YES;
        else proceed = NO;
        
        if( proceed)
        {
            for( x = 0; x < [pixList[y] count]; x++)
            {
                done = NO;
                
                if( allRois == 2)
                {
                    DCMPix *curPix = [pixList[ y] objectAtIndex: x];
                    [roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys: curPix, @"curPix", @"setPixel", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsrevert, @"revert", [NSNumber numberWithInt: x], @"stackNo", nil]];
                    
                    done = YES;
                }
                else
                {
                    for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                    {
                        if( [[[[roiList[y] objectAtIndex: x] objectAtIndex: i] name] isEqualToString: [aROI name]] || allRois == 1)
                        {
                            if( propagateIn4D)
                            {
                                for( z = 0; z < maxMovieIndex; z++)
                                {
                                    DCMPix *curPix = [pixList[ z] objectAtIndex: x];
                                    [roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [[roiList[y] objectAtIndex: x] objectAtIndex: i], @"roi", curPix, @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsrevert, @"revert", [NSNumber numberWithInt: x], @"stackNo", nil]];
                                    
                                    done = YES;
                                }
                            }
                            else
                            {
                                DCMPix *curPix = [pixList[ y] objectAtIndex: x];
                                [roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [[roiList[y] objectAtIndex: x] objectAtIndex: i], @"roi", curPix, @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsrevert, @"revert", [NSNumber numberWithInt: x], @"stackNo", nil]];
                                
                                done = YES;
                            }
                        }
                    }
                }
                
                if( outside && done == NO)
                {
                    if( propagateIn4D)
                    {
                        for( z = 0; z < maxMovieIndex; z++)
                        {
                            DCMPix *curPix = [pixList[ z] objectAtIndex: x];
                            [roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys: curPix, @"curPix", @"setPixel", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsrevert, @"revert", [NSNumber numberWithInt: x], @"stackNo", nil]];
                            
                        }
                    }
                    else
                    {
                        DCMPix *curPix = [pixList[ y] objectAtIndex: x];
                        [roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys: curPix, @"curPix", @"setPixel", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsrevert, @"revert", [NSNumber numberWithInt: x], @"stackNo", nil]];
                    }
                }
            }
        }
    }
    
    if( revert)
        [[pixList[ curMovieIndex] objectAtIndex: 0] prepareRestore];
    
    [self roiSetStartScheduler: roiToProceed];
    
    if( revert)
        [[pixList[ curMovieIndex] objectAtIndex: 0] freeRestore];
    
    [splash close];
    [splash autorelease];
    
    NSLog(@"endSetPixel");
}

- (IBAction) roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL) propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue
{
    return [self roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL) propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue :(BOOL) NO];
}

- (IBAction) endRoiRename:(id) sender
{
    [roiRenameWindow orderOut:sender];
    
    [NSApp endSheet:roiRenameWindow returnCode:[sender tag]];
    
    if( [sender tag] == 1)
    {
        long i, x, y;
        
        switch( [[roiRenameMatrix selectedCell] tag])
        {
            case 0:	// All ROIs of the image
                y = curMovieIndex;
                x = [imageView curImage];
                for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                {
                    ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                    
                    [curROI setName: [roiRenameName stringValue]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
                }
                break;
                
            case 1:	// All ROIs of the series
                for( y = 0; y < maxMovieIndex; y++)
                {
                    for( x = 0; x < [pixList[y] count]; x++)
                    {
                        for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                        {
                            ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                            
                            [curROI setName: [roiRenameName stringValue]];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
                        }
                    }
                }
                break;
                
            case 2:	// All selected ROIs
                y = curMovieIndex;
                x = [imageView curImage];
                for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                {
                    ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                    
                    long mode = [curROI ROImode];
                    
                    if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
                    {
                        [curROI setName: [roiRenameName stringValue]];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
                    }
                }
                break;
        }
    }
}

- (IBAction) roiRename:(id) sender
{
    [self addToUndoQueue: @"roi"];
    
    [NSApp beginSheet: roiRenameWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction) closeModal:(id) sender
{
    if( [sender tag])
    {
        [NSApp stopModal];
    }
    else
    {
        [NSApp abortModal];
    }
}

- (NSArray*) roiApplyWindow:(id) sender
{
    [NSApp beginSheet: roiApplyWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    int result = [NSApp runModalForWindow: roiApplyWindow];
    
    [NSApp endSheet:roiApplyWindow returnCode: 0];
    
    [roiApplyWindow orderOut:sender];
    
    NSMutableArray	*applyToROIs = [NSMutableArray array];
    
    if( result == NSRunStoppedResponse)
    {
        long i, x, y;
        
        switch( [[roiApplyMatrix selectedCell] tag])
        {
            case 0:	// All ROIs of the image
                y = curMovieIndex;
                x = [imageView curImage];
                for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                {
                    ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                    
                    [applyToROIs addObject: curROI];
                }
                break;
                
            case 1:	// All ROIs of the series
                for( y = 0; y < maxMovieIndex; y++)
                {
                    for( x = 0; x < [pixList[y] count]; x++)
                    {
                        for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                        {
                            ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                            
                            [applyToROIs addObject: curROI];
                        }
                    }
                }
                break;
                
            case 2:	// All selected ROIs
                y = curMovieIndex;
                x = [imageView curImage];
                for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                {
                    ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                    
                    long mode = [curROI ROImode];
                    
                    if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
                    {
                        [applyToROIs addObject: curROI];
                    }
                }
                break;
                
            case 3:	// All ROIs with same name as selected
            {
                y = curMovieIndex;
                x = [imageView curImage];
                NSString* name = nil;
                
                for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                {
                    ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                    
                    long mode = [curROI ROImode];
                    
                    if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
                    {
                        name = [curROI name];
                        break;
                    }
                }
                
                if( name)
                {
                    for( y = 0; y < maxMovieIndex; y++)
                    {
                        for( x = 0; x < [pixList[y] count]; x++)
                        {
                            for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
                            {
                                ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
                                
                                if( [[curROI name] isEqualToString: name])
                                    [applyToROIs addObject: curROI];
                            }
                        }
                    }
                }
            }
                break;
        }
    }
    
    return applyToROIs;
}

- (IBAction) roiDeleteAll:(id) sender
{
    [self addToUndoQueue: @"roi"];
    
    [imageView stopROIEditingForce: YES];
    
    for( int y = 0; y < maxMovieIndex; y++)
    {
        for( NSMutableArray *x in roiList[y])
        {
            [x retain];
            
            for( int i = ((long)[x count])-1; i >= 0 ; i--)
            {
                ROI *curROI = [x objectAtIndex:i];
                
                if( curROI.locked == NO)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:curROI userInfo: nil];
                    [x removeObject: curROI];
                }
            }
            
            [x autorelease];
        }
    }
    
    [imageView setIndex: [imageView curImage]];
}

- (IBAction) roiPropagateSetup: (id) sender
{
    ROI		*selectedRoi = nil;
    
    if( [pixList[curMovieIndex] count] > 1)
    {
        [self addToUndoQueue: @"roi"];
        
        selectedRoi = [self selectedROI];
        
        if( selectedRoi == nil)
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"No ROI(s) selected to propagate on the series!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
        }
        else
        {
            if( maxMovieIndex <= 1) [[roiPropaDim cellWithTag:1] setEnabled:NO];
            
            [NSApp beginSheet: roiPropaWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        }
    }
    else
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"There is only one image in this series. Nothing to propagate!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
    }
}

- (IBAction) roiHistogram:(id) sender
{
    for( int i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
    {
        long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
        
        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
        {
            ROI		*theROI = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
            BOOL	found = NO;
            
            for( id loopItem1 in [NSApp windows])
            {
                if( [[[loopItem1 windowController] windowNibName] isEqualToString:@"Histogram"])
                {
                    if( [[loopItem1 windowController] curROI] == theROI)
                    {
                        found = YES;
                        [[[loopItem1 windowController] window] makeKeyAndOrderFront:self];
                    }
                }
            }
            
            if( found == NO)
            {
                HistoWindow* roiWin = [[HistoWindow alloc] initWithROI: theROI];
                [roiWin showWindow:self];
            }
        }
    }
}

- (IBAction) roiGetInfo:(id) sender
{
    long i;
    
    if( [roiList[curMovieIndex] count] <= [imageView curImage]) return;
    
    for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
    {
        long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
        
        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
        {
            ROI		*theROI = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
            NSArray *winList = [NSApp windows];
            BOOL	found = NO;
            
            for( id loopItem1 in winList)
            {
                if( [[[loopItem1 windowController] windowNibName] isEqualToString:@"ROI"])
                {
                    if( [[loopItem1 windowController] curROI] == theROI)
                    {
                        found = YES;
                        [[[loopItem1 windowController] window] makeKeyAndOrderFront:self];
                    }
                }
            }
            
            if( found == NO)
            {
                ROIWindow* roiWin = [[ROIWindow alloc] initWithROI: theROI :self];
                [roiWin showWindow:self];
            }
            break;
        }
    }
}

- (IBAction) roiDefaults:(id) sender
{
    for( id loopItem in [NSApp windows])
    {
        if( [[[loopItem windowController] windowNibName] isEqualToString:@"ROIDefaults"])
        {
            [[[loopItem windowController] window] makeKeyAndOrderFront:self];
            return;
        }
    }
    
    ROIDefaultsWindow* roiDefaultsWin = [[ROIDefaultsWindow alloc] initWithController: self];
    [roiDefaultsWin showWindow:self];
}

- (IBAction) roiPropagateSlab:(id) sender
{
    NSMutableArray  *selectedROIs = [NSMutableArray  array];
    
    if( [[pixList[curMovieIndex] objectAtIndex:[imageView curImage]] stack] < 2)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"This function is only usefull if you use Thick Slab!", nil) , NSLocalizedString(@"OK", nil), nil, nil, nil);
        
        return;
    }
    
    if( [pixList[curMovieIndex] count] > 1)
    {
        [self addToUndoQueue: @"roi"];
        
        long upToImage, startImage, i, x;
        
        for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
        {
            long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
            
            if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
            {
                [selectedROIs addObject: [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i]];
            }
        }
        
        if( [imageView flippedData])
        {
            upToImage = [imageView curImage];
            startImage = [imageView curImage] - [[pixList[curMovieIndex] objectAtIndex:[imageView curImage]] stack];
            
            if( startImage < 0) startImage = 0;
        }
        else
        {
            upToImage = [imageView curImage] + [[pixList[curMovieIndex] objectAtIndex:[imageView curImage]] stack];
            startImage = [imageView curImage];
            
            if( upToImage > [pixList[curMovieIndex] count]) upToImage = [pixList[curMovieIndex] count];
        }
        
        if( [selectedROIs count] > 0)
        {
            for( x = startImage; x < upToImage; x++)
            {
                if( x != [imageView curImage])
                {
                    for( i = 0; i < [selectedROIs count]; i++)
                    {
                        ROI *newROI = [[[selectedROIs objectAtIndex: i] copy] autorelease];
                        
                        newROI.isAliased = NO;
                        
                        [[roiList[curMovieIndex] objectAtIndex: x] addObject: newROI];
                    }
                }
            }
            
            [imageView setIndex: [imageView curImage]];
        }
        else
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"No ROI(s) selected to propagate on the series!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
        }
    }
    else
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"There is only one image in this series. Nothing to propagate!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
    }
}

-(NSMutableArray*) roiList
{
    return roiList[curMovieIndex];
}

-(NSMutableArray*) roiList: (long) i
{
    if( i < 0) i = 0;
    if( i>= maxMovieIndex) i = maxMovieIndex-1;
    
    return roiList[i];
}

-(void) setRoiList: (long) i array:(NSMutableArray*) a
{
    if( i < 0) i = 0;
    if( i>= maxMovieIndex) i = maxMovieIndex-1;
    
    [roiList[ i] release];
    roiList[ i] = [a retain];;
}

- (IBAction) roiPropagate:(id) sender
{
    long			i, x;
    
    [roiPropaWindow orderOut:sender];
    
    [NSApp endSheet:roiPropaWindow returnCode:[sender tag]];
    
    if( [sender tag] != 1) return;
    
    NSMutableArray  *selectedROIs = [NSMutableArray  array];
    
    switch( [[roiPropaDim selectedCell] tag])
    {
        case 0:
            if( [pixList[curMovieIndex] count] > 1)
            {
                long upToImage, startImage;
                
                for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
                {
                    long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
                    
                    if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
                    {
                        [selectedROIs addObject: [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i]];
                    }
                }
                
                if( [[roiPropaMode selectedCell] tag] == 1)
                {
                    int pos, to;
                    
                    pos = [imageView curImage];
                    
                    if( [imageView flippedData]) to = (long)[pixList[curMovieIndex] count] -1 - [roiPropaDest floatValue];
                    else to = [roiPropaDest floatValue];
                    
                    startImage = pos;
                    upToImage = to;
                    
                    if( startImage > upToImage)
                    {
                        startImage = to;
                        upToImage = pos;
                    }
                    
                    if( upToImage > [pixList[curMovieIndex] count]) upToImage = [pixList[curMovieIndex] count];
                    if( startImage > [pixList[curMovieIndex] count]) startImage = [pixList[curMovieIndex] count];
                    
                    if( upToImage < 0) upToImage = 0;
                    if( startImage < 0) startImage = 0;
                }
                else
                {
                    upToImage = [pixList[curMovieIndex] count];
                    startImage = 0;
                }
                
                if( [selectedROIs count] > 0)
                {
                    for( x = startImage; x < upToImage; x++)
                    {
                        if( x != [imageView curImage])
                        {
                            if([[roiPropaCopy selectedCell] tag] == 1)
                            {
                                for( i = 0; i < [selectedROIs count]; i++)
                                {
                                    ROI *newROI = [[[selectedROIs objectAtIndex: i] copy] autorelease];
                                    
                                    newROI.isAliased = NO;
                                    [[roiList[curMovieIndex] objectAtIndex: x] addObject: newROI];
                                }
                            }
                            else
                            {
                                for( i = 0; i < [selectedROIs count]; i++)
                                {
                                    [[roiList[curMovieIndex] objectAtIndex: x] addObject: [selectedROIs objectAtIndex: i]];
                                }
                            }
                        }
                    }
                    
                    [imageView setIndex: [imageView curImage]];
                }
                else
                {
                    NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"No ROI(s) selected to propagate on the series!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
                }
            }
            else
            {
                NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"There is only one image in this series. Nothing to propagate!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
            }
            break;
            
        case 1:		// 4D Dimension
        {
            
            for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
            {
                long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
                
                if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
                {
                    [selectedROIs addObject: [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i]];
                }
            }
            
            if( [selectedROIs count] > 0)
            {
                for( x = 0; x < maxMovieIndex; x++)
                {
                    if( x != curMovieIndex)
                    {
                        if([[roiPropaCopy selectedCell] tag] == 1)
                        {
                            for( i = 0; i < [selectedROIs count]; i++)
                            {
                                ROI *newROI = [[[selectedROIs objectAtIndex: i] copy] autorelease];
                                
                                [[roiList[ x] objectAtIndex: [imageView curImage]] addObject: newROI];
                            }
                        }
                        else
                        {
                            for( i = 0; i < [selectedROIs count]; i++)
                            {
                                [[roiList[ x] objectAtIndex: [imageView curImage]] addObject: [selectedROIs objectAtIndex: i]];
                            }
                        }
                    }
                }
                
                [imageView setIndex: [imageView curImage]];
            }
            else
            {
                NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"No ROI(s) selected to propagate on the series!", nil) , NSLocalizedString(@"OK", nil), nil, nil);
            }
        }
            break;
    }
}

-(void) setROIToolTag:(ToolMode) roitype
{
    NSButtonCell *cell = [toolsMatrix cellAtRow:0 column:5];
    [cell setTag: roitype];
    [cell setImage: [self imageForROI: roitype]];
    [[cell image] setSize:ToolsMenuIconSize];
    
    [toolsMatrix selectCellAtRow:0 column:5];
    
    [self setDefaultToolMenu:[toolsMatrix selectedCell]];
    //change Image in contextual menu 4/22/04, removed on 2010-01-22 because menus are now regenerated when rightclick happens
    //	NSMenu *menu = [imageView menu];
    //	[[menu itemAtIndex:5] setImage: [self imageForROI: roitype]];
    //	[[menu itemAtIndex:5] setTag: -1];
}

-(void) setROITool:(id) sender
{
    [self setROIToolTag: [sender tag]];
    
    //change default Tool if sent from Menu
    if ([sender isKindOfClass:[NSMenuItem class]])
        [self setDefaultTool:sender];
}


// returns the names of all the ROIs (one occurrence of each name)
- (NSArray*) roiNames
{
    int x, i, j;
    BOOL found;
    
    NSMutableArray *names = [NSMutableArray array];
    
    for(x=0; x < [pixList[curMovieIndex] count]; x++)
    {
        for(i=0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
        {
            found = NO;
            ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
            NSString *name = [curROI name];
            for(j=0; j<[names count] && !found; j++)
            {
                if([name isEqualToString:[names objectAtIndex:j]])
                {
                    found = YES;
                }
            }
            if(!found)
            {
                [names addObject:name];
            }
        }
    }
    return names;
}

- (NSArray*) roisWithComment: (NSString*) comment
{
    int x, i;
    
    NSMutableArray *rois = [NSMutableArray array];
    
    for( x = 0; x < [pixList[curMovieIndex] count]; x++)
    {
        for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
        {
            ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
            if( [[curROI comments] isEqualToString: comment])
            {
                [curROI setPix:[pixList[curMovieIndex] objectAtIndex: x]];
                [rois addObject: curROI];
            }
        }
    }
    return rois;
}

- (NSArray*)roisWithName:(NSString*)name;
{
    return [self roisWithName:name in4D:NO];
}

- (NSArray*)roisWithName:(NSString*)name in4D:(BOOL)in4D;
{
    NSMutableArray *rois = [NSMutableArray array];
    
    if(in4D)
    {
        for (int m = 0; m<maxMovieIndex; m++)
        {
            [rois addObjectsFromArray:[self roisWithName:name forMovieIndex:m]];
        }
    }
    else
        [rois addObjectsFromArray:[self roisWithName:name forMovieIndex:curMovieIndex]];
    
    return rois;
}

- (NSArray*)roisWithName:(NSString*)name forMovieIndex:(int)m;
{
    NSMutableArray *rois = [NSMutableArray array];
    
    for(int x = 0; x < [pixList[m] count]; x++)
    {
        for(int i = 0; i < [[roiList[m] objectAtIndex: x] count]; i++)
        {
            ROI	*curROI = [[roiList[m] objectAtIndex: x] objectAtIndex: i];
            if( [[curROI name] isEqualToString: name])
            {
                [curROI setPix:[pixList[m] objectAtIndex: x]];
                [rois addObject: curROI];
            }
        }
    }
    return rois;
}

- (ROI*) isoContourROI: (ROI*) a numberOfPoints: (int) nof
{
#ifndef OSIRIX_LIGHT
    if( [a type] == tCPolygon || [a type] == tOPolygon || [a type] == tPencil)
    {
        [a setPoints: [ROI resamplePoints: [a splinePoints] number: nof]];
        return a;
    }
    else if( [a type] == tPlain)
    {
        a = [self convertBrushROItoPolygon: a numPoints: nof];
        [a setPoints: [ROI resamplePoints: [a splinePoints] number: nof]];
        return a;
    }
    else return nil;
#else
    return nil;
#endif
}

- (ROI*) roiMorphingBetween:(ROI*) a and:(ROI*) b ratio:(float) ratio
{
    if (a.type == tMesure && b.type == tMesure)
    {
        ROI* newMeasure = [self newROI: tMesure];
        
        [newMeasure addPoint:[ROI pointBetweenPoint:[a pointAtIndex:0] and:[b pointAtIndex:0] ratio:ratio]];
        [newMeasure addPoint:[ROI pointBetweenPoint:[a pointAtIndex:1] and:[b pointAtIndex:1] ratio:ratio]];
        
        [newMeasure setColor: [a rgbcolor]];
        [newMeasure setOpacity: [a opacity]];
        [newMeasure setThickness: [a thickness]];
        [newMeasure setName: [a name]];
        
        return newMeasure;
    }
    
    if( a.type == tMesure)
    {
        [a.points insertObject:[MyPoint point:[ROI pointBetweenPoint:[a pointAtIndex:0] and:[a pointAtIndex:1] ratio:0.5]] atIndex:1];
        a.type = tOPolygon;
    }
    
    if( b.type == tMesure)
    {
        [b.points insertObject:[MyPoint point:[ROI pointBetweenPoint:[b pointAtIndex:0] and:[b pointAtIndex:1] ratio:0.5]] atIndex:1];
        b.type = tOPolygon;
    }
    
    if( a.type == tROI || a.type == tOval)
    {
        NSMutableArray *points = a.points;
        if( a.type == tROI)
            a.isSpline = NO;
        
        a.type = tCPolygon;
        a.points = points;
    }
    
    if( b.type == tROI || b.type == tOval)
    {
        NSMutableArray *points = b.points;
        if( b.type == tROI)
            b.isSpline = NO;
        
        b.type = tCPolygon;
        b.points = points;
    }
    
    
    NSMutableArray	*aPts = [a points];
    NSMutableArray	*bPts = [b points];
    
    int maxPoints = MAX([aPts count], [bPts count]);
    maxPoints += maxPoints / 3;
    
    ROI* inputROI = a;
    
    a = [[a copy] autorelease];
    b = [[b copy] autorelease];
    
    a.isAliased = NO;
    b.isAliased = NO;
    
    // If the ROIs are brush ROIs, convert them into polygons, using a marching square isocontour
    // Otherwise update the points so they both have maxPoints number of points
    a = [self isoContourROI: a numberOfPoints: maxPoints];
    b = [self isoContourROI: b numberOfPoints: maxPoints];
    
    if( a == nil) return nil;
    if( b == nil) return nil;
    
    if( [[a points] count] != maxPoints || [[b points] count] != maxPoints)
    {
        NSLog( @"***** NoOfPoints !");
        return nil;
    }
    
    aPts = [a points];
    bPts = [b points];
    
    ROI* newROI = nil;
    if ( a.type == tOPolygon) {
        newROI = [self newROI: tOPolygon];
    }
    else
    {
        newROI = [self newROI: tCPolygon];
    }
    
    NSMutableArray *pts = [newROI points];
    int i;
    
    for( i = 0; i < [aPts count]; i++)
    {
        MyPoint	*aP = [aPts objectAtIndex: i];
        MyPoint	*bP = [bPts objectAtIndex: i];
        
        NSPoint newPt = [ROI pointBetweenPoint: [aP point] and: [bP point] ratio: ratio];
        
        [pts addObject: [MyPoint point: newPt]];
    }
    
    if( [inputROI type] == tPlain)
    {
        newROI = [self convertPolygonROItoBrush: newROI];
    }
    
    [newROI setColor: [inputROI rgbcolor]];
    [newROI setOpacity: [inputROI opacity]];
    [newROI setThickness: [inputROI thickness]];
    [newROI setName: [inputROI name]];
    
    return newROI;
}

- (MyPoint*) newPoint: (float) x :(float) y
{
    return( [MyPoint point: NSMakePoint(x, y)]);
}


- (void) roiChange :(NSNotification*) note
{
    //	if( curvedController)
    //	{
    //		if( [note object] == [curvedController roi])
    //		{
    //			[curvedController recompute];
    //		}
    //	}
}

//- (IBAction)exportAsDICOMSR:(id)sender;
//{
//	SRAnnotationController *srController = [[SRAnnotationController alloc] initWithViewerController:self];
//	[srController beginSheet];
//}

- (ROI*) selectedROI
{
    ROI *selectedRoi = nil;
    int i;
    
    for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
    {
        long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
        
        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
        {
            selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
        }
    }
    
    if( selectedRoi == nil)
    {
        // If there is only one roi on the image, choose it !
        if( [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count] == 1)
        {
            selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: 0];
            [selectedRoi setROIMode: ROI_selected];
            [imageView display];
        }
    }
    
    return selectedRoi;
}

- (NSMutableArray*) selectedROIs
{
    NSMutableArray *selectedRois = [NSMutableArray array];
    int i;
    
    for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
    {
        long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
        
        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
        {
            [selectedRois addObject: [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i]];
        }
    }
    
    return selectedRois;
}

- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;
{
    if(groupID==0.0) return;
    if(mode==ROI_selectedModify) mode=ROI_selected;
    // set the mode to all ROIs in the same group
    NSArray *curROIList = [roiList[curMovieIndex] objectAtIndex:[imageView curImage]];
    for(id loopItem in curROIList)
        if([loopItem groupID]==groupID)
            [loopItem setROIMode:mode];
}

- (void)selectROI:(ROI*)roi deselectingOther:(BOOL)deselectOther;
{
    if( deselectOther)
    {
        for(int i=0; i<[[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] count]; i++)
            [[[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] objectAtIndex:i] setROIMode:ROI_sleep];
    }
    
    if( roi)
    {
        // select the ROI
        [roi setROIMode:ROI_selected];
        // select the othher grouped ROIs (if any)
        [self setMode:ROI_selected toROIGroupWithID:[roi groupID]];
        
        // bring it to front
        [self bringToFrontROI:roi];
    }
}

- (void)deselectAllROIs;
{
    for(int i=0; i<[[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] count]; i++)
        [[[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] objectAtIndex:i] setROIMode:ROI_sleep];
}

- (void)setSelectedROIsGrouped:(BOOL)grouped;
{
    [self addToUndoQueue: @"roi"];
    
    NSArray *curROIList = [roiList[curMovieIndex] objectAtIndex:[imageView curImage]];
    long mode;
    
    NSTimeInterval newGroupID;
    if(grouped)
        newGroupID = [NSDate timeIntervalSinceReferenceDate];
    else
        newGroupID = 0.0;
    
    for(ROI *roi in curROIList)
    {
        mode = [roi ROImode];
        
        if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
        {
            [roi setGroupID:newGroupID];
        }
    }
}

- (void)groupSelectedROIs;
{
    [self setSelectedROIsGrouped:YES];
}

- (void)ungroupSelectedROIs;
{
    [self setSelectedROIsGrouped:NO];
}

- (IBAction)groupSelectedROIs:(id)sender;
{
    [self groupSelectedROIs];
}

- (IBAction)ungroupSelectedROIs:(id)sender;
{
    [self ungroupSelectedROIs];
}

- (void) setSelectedROIsLocked: (BOOL) locked
{
    [self addToUndoQueue: @"roi"];
    
    NSArray *curROIList = [roiList[curMovieIndex] objectAtIndex:[imageView curImage]];
    
    for(ROI *roi in curROIList)
    {
        if( [roi ROImode] == ROI_selected || [roi ROImode] == ROI_selectedModify || [roi ROImode] == ROI_drawing)
            roi.locked = locked;
    }
}

- (IBAction)lockSelectedROIs:(id)sender;
{
    [self setSelectedROIsLocked: YES];
}

- (IBAction)unlockSelectedROIs:(id)sender;
{
    [self setSelectedROIsLocked: NO];
}

- (IBAction) makeSelectedROIsUnselectable:(id)sender;
{
    [self addToUndoQueue: @"roi"];
    
    NSArray *curROIList = [roiList[curMovieIndex] objectAtIndex:[imageView curImage]];
    
    for(ROI *roi in curROIList)
    {
        if( [roi ROImode] == ROI_selected || [roi ROImode] == ROI_selectedModify || [roi ROImode] == ROI_drawing)
            roi.selectable = NO;
    }
}

- (IBAction) makeAllROIsSelectable:(id)sender;
{
    [self addToUndoQueue: @"roi"];
    
    NSArray *curROIList = [roiList[curMovieIndex] objectAtIndex:[imageView curImage]];
    
    for(ROI *roi in curROIList)
    {
        roi.selectable = YES;
    }
}

- (void)bringToFrontROI:(ROI*) roi;
{
    if([roi groupID]==0.0) // not grouped
    {
        [roi retain];
        [[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] removeObject:roi];
        [[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] insertObject:roi atIndex:0];
        [roi release];
    }
    else // bring the whole group to front, without changing order inside the group
    {
        NSMutableArray *group = [NSMutableArray array];
        NSMutableArray *ROIs = [roiList[curMovieIndex] objectAtIndex:[imageView curImage]];
        int i;
        for(i=0; i<[ROIs count]; i++)
        {
            if([[ROIs objectAtIndex:i] groupID]==[roi groupID])
            {
                [group addObject:[ROIs objectAtIndex:i]];
                [ROIs removeObject:[ROIs objectAtIndex:i]];
                i--;
            }
        }
        for(i=(long)[group count]-1; i>=0; i--)
        {
            [ROIs insertObject:[group objectAtIndex:i] atIndex:0];
        }
    }
}

- (void)sendToBackROI:(ROI*) roi;
{
    if([roi groupID]==0.0) // not grouped
    {
        [roi retain];
        [[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] insertObject:roi atIndex:[[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] count]];
        [[roiList[curMovieIndex] objectAtIndex:[imageView curImage]] removeObject:roi];
        [roi release];
    }
    else // bring the whole group to front, without changing order inside the group
    {
        NSMutableArray *group = [NSMutableArray array];
        NSMutableArray *ROIs = [roiList[curMovieIndex] objectAtIndex:[imageView curImage]];
        int i;
        for(i=0; i<[ROIs count]; i++)
        {
            if([[ROIs objectAtIndex:i] groupID]==[roi groupID])
            {
                [group addObject:[ROIs objectAtIndex:i]];
                [ROIs removeObject:[ROIs objectAtIndex:i]];
                i--;
            }
        }
        for(i=(long)[group count]-1; i>=0; i--)
        {
            [ROIs insertObject:[group objectAtIndex:i] atIndex:[ROIs count]];
        }
    }
}

#pragma mark BrushTool and ROI filters

-(void) brushTool:(id) sender
{
    BOOL	found = NO;
    NSArray *winList = [NSApp windows];
    
    for( id loopItem in winList)
    {
        if( [[[loopItem windowController] windowNibName] isEqualToString:@"PaletteBrush"])
        {
            found = YES;
        }
    }
    
    if( !found)
    {
        /*PaletteController *palette = */[[PaletteController alloc] initWithViewer: self];
    }
    //	else [self setROIToolTag: tPlain];
}

- (NSRecursiveLock*) roiLock { return roiLock;}

#ifndef OSIRIX_LIGHT
- (void) applyMorphology: (NSArray*) rois action:(NSString*) action	radius: (long) radius sendNotification: (BOOL) sendNotification
{
    NSLog( @"****** applyMorphology - START");
    
    
    [roiLock lock];
    
    ITKBrushROIFilter *filter = nil;
    
    @try
    {
        filter = [[ITKBrushROIFilter alloc] init];
        
        NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
        
        for ( int i = 0; i < [rois count]; i++)
        {
            ViewerControllerOperation *op = [[[ViewerControllerOperation alloc] initWithController: self dict: [NSDictionary dictionaryWithObjectsAndKeys: [rois objectAtIndex:i], @"roi", action, @"action", filter, @"filter", [NSNumber numberWithInt: radius], @"radius", nil]] autorelease];
            
            [queue addOperation: op];
        }
        
        [queue waitUntilAllOperationsAreFinished];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [roiLock unlock];
    
    if( sendNotification)
        for ( int i = 0; i < [rois count]; i++) [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:[rois objectAtIndex:i] userInfo: nil];
    
    [filter release];
    
    NSLog( @"****** applyMorphology - END");
}

- (IBAction) setStructuringElementRadius: (id) sender
{
    [structuringElementRadiusTextField setStringValue:[NSString stringWithFormat:@"%d",[structuringElementRadiusSlider intValue]]];
}

- (IBAction) morphoSelectedBrushROIWithRadius: (id) sender
{
    [brushROIFilterOptionsWindow orderOut: sender];
    [NSApp endSheet: brushROIFilterOptionsWindow];
    
    if( [sender tag])
    {
        ROI *selectedROI = [self selectedROI];
        
        // do the morpho function...
        ITKBrushROIFilter *filter = [[ITKBrushROIFilter alloc] init];
        
        WaitRendering	*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing...",nil)];
        [wait showWindow:self];
        if ([brushROIFilterOptionsAllWithSameName state]==NSOffState)
        {
            [self applyMorphology: [NSArray arrayWithObject:selectedROI] action:morphoFunction radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
        }
        else
        {
            [self applyMorphology: [self roisWithName:[selectedROI name] in4D:YES] action:morphoFunction radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
        }
        [filter release];
        [wait close];
        [wait autorelease];
    }
}

- (IBAction) morphoSelectedBrushROI: (id) sender
{
    ROI *selectedROI = [self selectedROI];
    
    [morphoFunction release];
    
    switch( [sender tag])
    {
        case 0:		morphoFunction = [@"erode" retain];		break;
        case 1:		morphoFunction = [@"dilate" retain];	break;
        case 2:		morphoFunction = [@"close" retain];		break;
        case 3:		morphoFunction = [@"open" retain];		break;
    }
    
    if (selectedROI && [selectedROI type] == tPlain)
    {
        [self addToUndoQueue: @"roi"];
        
        [NSApp beginSheet:brushROIFilterOptionsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
    else
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Brush ROI Error", nil), NSLocalizedString(@"Select a Brush ROI before to run the filter.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
}
#endif

- (ROI*) convertPolygonROItoBrush:(ROI*) selectedROI
{
    ROI *theNewROI = nil;
    
    if( selectedROI.type == tOval)
    {
        NSMutableArray *points = selectedROI.points;
        if( selectedROI.type == tROI)
            selectedROI.isSpline = NO;
        
        selectedROI.type = tCPolygon;
        selectedROI.points = points;
    }
    
    if( selectedROI.type == tCPolygon || selectedROI.type == tOPolygon || selectedROI.type == tPencil)
    {
        NSSize s;
        NSPoint o;
        unsigned char* texture = [DCMPix getMapFromPolygonROI: selectedROI size: &s origin: &o];
        
        if( texture)
        {
            theNewROI = [[ROI alloc]		initWithTexture: texture
                                            textWidth: s.width
                                           textHeight: s.height
                                             textName: @""
                                            positionX: o.x
                                            positionY: o.y
                                             spacingX: [[imageView curDCM] pixelSpacingX]
                                             spacingY: [[imageView curDCM] pixelSpacingY]
                                          imageOrigin: NSMakePoint([[imageView curDCM] originX], [[imageView curDCM] originY])];
            if( [theNewROI reduceTextureIfPossible] == NO)	// NO means that the ROI is NOT empty
            {
            }
            else
            {
                [theNewROI release];
                theNewROI = nil;
            }
            
            free( texture);
        }
    }
    
    return [theNewROI autorelease];
}


- (ROI*) convertBrushROItoPolygon:(ROI*) selectedROI numPoints: (int) numPoints
{
    ROI* newROI = nil;
    
#ifndef OSIRIX_LIGHT
    if( [selectedROI type] == tPlain)
    {
        // Convert it to Brush
        newROI = [self newROI: tCPolygon];
        
        NSArray	*points = [ITKSegmentation3D extractContour: [selectedROI textureBuffer] width: [selectedROI textureWidth] height: [selectedROI textureHeight] numPoints: numPoints];
        
        int		i;
        NSMutableArray	*pts = [NSMutableArray array];
        
        for( i = 0 ; i < [points count] ; i++)
        {
            [[points objectAtIndex: i] move: [selectedROI textureUpLeftCornerX] :[selectedROI textureUpLeftCornerY]];
        }
        
        for( i = 0 ; i < numPoints ; i++)
        {
            float x = (float) (i * [points count]) / (float) numPoints;
            int xint = (int) x;
            
            MyPoint *a = [points objectAtIndex: xint];
            
            MyPoint *b;
            if( xint+1 == [points count])  b = [points objectAtIndex: 0];
            else b = [points objectAtIndex: xint+1];
            
            NSPoint c = [ROI pointBetweenPoint: [a point] and: [b point] ratio: x - (float) xint];
            
            [pts addObject: [MyPoint point: c]];
        }
        
        [newROI setPoints: pts];
    }
#endif
    
    return newROI;
}

-(int) imageIndexOfROI:(ROI*) c
{
    int x, i;
    
    for( x = 0; x < [pixList[ curMovieIndex] count]; x++)
    {
        for( i = 0; i < [[roiList[ curMovieIndex] objectAtIndex: x] count]; i++)
        {
            ROI *curROI = [[roiList[ curMovieIndex] objectAtIndex: x] objectAtIndex:i];
            
            if( curROI == c) return x;
        }
    }
    
    return -1;
}

- (IBAction) mergeBrushROI: (id) sender ROIs: (NSArray*) s ROIList: (NSMutableArray*) roiListContained
{
    if( [s count])
    {
        NSMutableArray *rois = [NSMutableArray array];
        
        for( ROI *r in s)
        {
            if( [r type] == tPlain) [rois addObject: r];
        }
        
        if( [rois count])
        {
            ROI *f = [rois lastObject];
            
            [rois removeLastObject];
            
            for( ROI *r in rois)
            {
                [f mergeWithTexture: r];
            }
            
            for( ROI *r in rois)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object: r userInfo: nil];
                [roiListContained removeObject: r];
            }
        }
    }
}

- (IBAction) mergeBrushROI: (id) sender
{
    return [self mergeBrushROI: sender ROIs: [self selectedROIs] ROIList: [roiList[ curMovieIndex] objectAtIndex: [imageView curImage]] ];
}

- (IBAction) convertBrushPolygon: (id) sender
{
    [self addToUndoQueue: @"roi"];
    [imageView stopROIEditingForce: YES];
    
    for( int i = 0; i < maxMovieIndex; i++)
        [self saveROI: i];
    
    NSArray *selectedROIs = [self roiApplyWindow: self];
    
    int tag;
    
    for( ROI *selectedROI in selectedROIs)
    {
        
        NSInteger index = [self imageIndexOfROI: selectedROI];
        
        if( index >= 0)
        {
            ROI	*newROI = nil;
            
            if( [selectedROI type] == tPlain) tag = 1;
            else tag = 0;
            
            switch( tag)
            {
                case 1:
                {
                    newROI = [self convertBrushROItoPolygon: selectedROI numPoints:100];
                    
                    if( newROI)
                    {
                        // Add the new ROI
                        [[selectedROI curView] roiSet: newROI];
                        [[roiList[curMovieIndex] objectAtIndex: index] addObject: newROI];
                        [newROI setROIMode: ROI_selected];
                        [newROI setName: [selectedROI name]];
                        [newROI setComments: [selectedROI comments]];
                    }
                }
                    break;
                    
                case 0:
                {
                    newROI = [self convertPolygonROItoBrush: selectedROI];
                    
                    if( newROI)
                    {
                        // Add the new ROI
                        [[selectedROI curView] roiSet: newROI];
                        [[roiList[curMovieIndex] objectAtIndex: index] addObject: newROI];
                        [newROI setROIMode: ROI_selected];
                        [newROI setName: [selectedROI name]];
                        [newROI setComments: [selectedROI comments]];
                    }
                }
                    break;
            }
            
            // Remove the old ROI
            if( newROI)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:selectedROI userInfo: nil];
                [[roiList[curMovieIndex] objectAtIndex: index] removeObject: selectedROI];
            }
        }
    }
    
    [imageView setIndex: [imageView curImage]];
}

#pragma mark SUV

- (IBAction) cancel:(id)sender
{
    [NSApp stopModal];
    self.injectionDateTime = nil;
}

- (IBAction) ok:(id)sender
{
    [NSApp stopModal];
}

- (IBAction) editSUVinjectionTime:(id)sender
{
    if( [sender tag] == 0)
        self.injectionDateTime = [[[[imageView curDCM] radiopharmaceuticalStartTime] copy] autorelease];
    
    if( [sender tag] == 1)
        self.injectionDateTime = [[[[imageView curDCM] acquisitionTime] copy] autorelease];
    
    [NSApp beginSheet: injectionTimeWindow
       modalForWindow: displaySUVWindow
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    [NSApp runModalForWindow: injectionTimeWindow];
    [NSApp endSheet: injectionTimeWindow];
    [injectionTimeWindow orderOut: self];
    
    if( injectionDateTime != nil)
    {
        if( [sender tag] == 0)
        {
            [editedRadiopharmaceuticalStartTime release];
            editedRadiopharmaceuticalStartTime = [injectionDateTime copy];
        }
        
        if( [sender tag] == 1)
        {
            [editedAcquisitionTime release];
            editedAcquisitionTime = [injectionDateTime copy];
        }
        
        for( int y = 0; y < maxMovieIndex; y++)
        {
            for( DCMPix *p in pixList[y])
            {
                if( [sender tag] == 0)
                    p.radiopharmaceuticalStartTime = injectionDateTime;
                
                if( [sender tag] == 1)
                    p.acquisitionTime = injectionDateTime;
            }
        }
        
        if( [sender tag] == 0)
            [[suvForm cellAtIndex: 3] setObjectValue: injectionDateTime];
        
        if( [sender tag] == 1)
            [[suvForm cellAtIndex: 4] setObjectValue: injectionDateTime];
    }
}

- (float) factorPET2SUV
{
    return factorPET2SUV;
}

- (void) recomputePixMinMax
{
    for( int y = 0; y < maxMovieIndex; y++)
    {
        for( DCMPix * p in pixList[ y])
        {
            [p computePixMinPixMax];
            p.minValueOfSeries = 0;
            p.maxValueOfSeries = 0;
        }
    }
}

- (void) convertPETtoSUV
{
    long	y, x, i;
    BOOL	updatewlww = NO;
    double	updatefactor;
    
    if( [[imageView curDCM] isRGB]) return;
    if( [[[imageView curDCM] units] isEqualToString:@"CNTS"] && [[imageView curDCM] philipsFactor])
    {
        
    }
    else
    {
        if( [[imageView curDCM] radionuclideTotalDoseCorrected] <= 0) return;
        if( [[imageView curDCM] patientsWeight] <= 0) return;
    }
    if( [[imageView curDCM] hasSUV] == NO) return;
    
    if( [[imageView curDCM] SUVConverted] == NO)
    {
        updatewlww = YES;
        
        if( [[[imageView curDCM] units] isEqualToString:@"CNTS"]) updatefactor = [[imageView curDCM] philipsFactor];
        else updatefactor = [[imageView curDCM] patientsWeight] * 1000. / ([[imageView curDCM] radionuclideTotalDoseCorrected] * [[imageView curDCM] decayFactor]);
    }
    
    for( y = 0; y < maxMovieIndex; y++)
    {
        for( x = 0; x < [pixList[y] count]; x++)
        {
            DCMPix	*pix = [pixList[y] objectAtIndex: x];
            
            if( [pix SUVConverted] == NO)
            {
                float	*imageData = [pix fImage];
                if( [[pix units] isEqualToString:@"CNTS"])	// Philips
                {
                    factorPET2SUV = [pix philipsFactor];
                }
                else factorPET2SUV = ([pix patientsWeight] * 1000.) / ([pix radionuclideTotalDoseCorrected] * [pix decayFactor]);
                
                i = [pix pheight] * [pix pwidth];
                while( i--> 0)
                    *imageData++ *=  factorPET2SUV;
                
                pix.SUVConverted = YES;
                pix.factorPET2SUV = factorPET2SUV;
            }
            
            [pix computePixMinPixMax];
        }
    }
    
    NSLog(@"Convert to SUV - factor: %f", factorPET2SUV);
    
    for( y = 0; y < maxMovieIndex; y++)
    {
        for( DCMPix *p in pixList[y])
        {
            [p setMaxValueOfSeries: 0];
            [p setMinValueOfSeries: 0];
            
            [p setSavedWL: [p savedWL] * updatefactor];
            [p setSavedWW: [p savedWW] * updatefactor];
            p.displaySUVValue = YES;
        }
    }
    
    if(  updatewlww)
    {
        float cwl, cww;
        
        [imageView getWLWW:&cwl :&cww];
        
        if( [[NSUserDefaults standardUserDefaults] integerForKey:@"DEFAULTPETWLWW"] != 0)
            [imageView updatePresentationStateFromSeries];
        else [imageView setWLWW: cwl * updatefactor : cww * updatefactor];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList[ curMovieIndex] userInfo: nil];
    
    [self setWindowTitle:self];
}

- (void) restoreConvertPETtoSUVautomaticallyValue: (NSNumber*) valueToRestore
{
    [[NSUserDefaults standardUserDefaults] setBool: valueToRestore.boolValue forKey:@"ConvertPETtoSUVautomatically"];
}

-(IBAction) endDisplaySUV:(id) sender
{
    long y, x;
    
    if( [sender tag] == 1)
    {
        [self updateSUVValues: self];
        
        BOOL savedDefault = [[NSUserDefaults standardUserDefaults] boolForKey: @"ConvertPETtoSUVautomatically"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ConvertPETtoSUVautomatically"];
        
        if( [[imageView curDCM] SUVConverted])
        {
            [self revertSeries:self];
            
            for( y = 0; y < maxMovieIndex; y++)
            {
                for( DCMPix *p in pixList[ y])
                {
                    if( editedAcquisitionTime)
                        p.acquisitionTime = editedAcquisitionTime;
                    
                    if( editedRadiopharmaceuticalStartTime)
                        p.radiopharmaceuticalStartTime = editedRadiopharmaceuticalStartTime;
                }
            }
        }
        
        // Why this? Because SUV conversion happen on the main thread in the finishLoadImageData...
        [self performSelector: @selector( restoreConvertPETtoSUVautomaticallyValue:) withObject: [NSNumber numberWithBool: savedDefault] afterDelay: 2];
        
        for( y = 0; y < maxMovieIndex; y++)
        {
            for( DCMPix *p in pixList[ y])
                [p setDisplaySUVValue: NO];
        }
        
        if( [[suvForm cellAtIndex: 0] floatValue] > 0)
        {
            for( y = 0; y < maxMovieIndex; y++)
            {
                for( x = 0; x < [pixList[y] count]; x++)
                {
                    [[pixList[y] objectAtIndex: x] setPatientsWeight: [[suvForm cellAtIndex: 0] floatValue]];
                    [[pixList[y] objectAtIndex: x] setRadionuclideTotalDose: [[suvForm cellAtIndex: 1] floatValue] * 1000000.];
                    [[pixList[y] objectAtIndex: x] setRadiopharmaceuticalStartTime: [[suvForm cellAtIndex: 3] objectValue]];
                    [[pixList[y] objectAtIndex: x] computeTotalDoseCorrected];
                }
            }
            
            [[NSUserDefaults standardUserDefaults] setInteger: [[suvConversion selectedCell] tag] forKey:@"SUVCONVERSION"];
            
            switch( [[suvConversion selectedCell] tag])
            {
                case 1:	// Convert all pixels to SUV
                    [self convertPETtoSUV];
                    break;
                    
                case 2:	// Display SUV
                    for( y = 0; y < maxMovieIndex; y++)
                    {
                        for( x = 0; x < [pixList[y] count]; x++) [[pixList[y] objectAtIndex: x] setDisplaySUVValue: YES];
                    }
                case 0: // Do nothing
                    for( y = 0; y < maxMovieIndex; y++)
                    {
                        for( x = 0; x < [pixList[y] count]; x++)
                        {
                            [[pixList[y] objectAtIndex: x] setMaxValueOfSeries: 0];
                            [[pixList[y] objectAtIndex: x] setMinValueOfSeries: 0];
                        }
                    }
                    break;
            }
            
            [displaySUVWindow orderOut:sender];
            [NSApp endSheet:displaySUVWindow returnCode:[sender tag]];
        }
        else NSRunAlertPanel(NSLocalizedString(@"SUV Error", nil), NSLocalizedString(@"These values (weight and dose) are not correct.", nil), nil, nil, nil);
    }
    else
    {
        [displaySUVWindow orderOut:sender];
        [NSApp endSheet:displaySUVWindow returnCode:[sender tag]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRecomputeROINotification object:self userInfo: nil];
}

- (IBAction) updateSUVValues:(id) sender
{
    int			x, y;
    NSDate		*newDate = [[suvForm cellAtIndex: 3] objectValue];
    float		newInjectedDose = [[suvForm cellAtIndex: 1] floatValue] * 1000000.;
    
    if( -[newDate timeIntervalSinceDate: [[imageView curDCM] acquisitionTime]] <= 0)
    {
        NSRunAlertPanel(NSLocalizedString(@"SUV Error", nil), NSLocalizedString(@"Injection time CANNOT be after acquisition time !", nil), nil, nil, nil);
        
        if( [[imageView curDCM] radiopharmaceuticalStartTime])
            [[suvForm cellAtIndex: 3] setObjectValue: [[imageView curDCM] radiopharmaceuticalStartTime]];
    }
    else
    {
        for( y = 0; y < maxMovieIndex; y++)
        {
            for( x = 0; x < [pixList[y] count]; x++)
            {
                [[pixList[y] objectAtIndex: x] setRadionuclideTotalDose: newInjectedDose];
                [[pixList[y] objectAtIndex: x] setRadiopharmaceuticalStartTime: [[suvForm cellAtIndex: 3] objectValue]];
                [[pixList[y] objectAtIndex: x] computeTotalDoseCorrected];
            }
        }
        
        [[suvForm cellAtIndex: 1] setStringValue: [NSString stringWithFormat:@"%2.3f", [[imageView curDCM] radionuclideTotalDose] / 1000000. ]];
        
        [[suvForm cellAtIndex: 2] setStringValue: [NSString stringWithFormat:@"%2.3f", [[imageView curDCM] radionuclideTotalDoseCorrected] / 1000000. ]];
        
        if( [[imageView curDCM] radiopharmaceuticalStartTime])
            [[suvForm cellAtIndex: 3] setObjectValue: [[imageView curDCM] radiopharmaceuticalStartTime]];
    }
}

- (void) displaySUV:(id) sender
{
    [suvConversion selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"SUVCONVERSION"]];
    
    if( [[imageView curDCM] hasSUV] == NO)
    {
        NSRunAlertPanel(NSLocalizedString(@"SUV Error", nil), NSLocalizedString(@"Cannot compute SUV on these data.", nil), nil, nil, nil);
    }
    else
    {
        [[suvForm cellAtIndex: 0] setStringValue: [NSString stringWithFormat:@"%2.3f", [[imageView curDCM] patientsWeight]]];
        [[suvForm cellAtIndex: 1] setStringValue: [NSString stringWithFormat:@"%2.3f", [[imageView curDCM] radionuclideTotalDose] / 1000000.]];
        [[suvForm cellAtIndex: 2] setStringValue: [NSString stringWithFormat:@"%2.3f", [[imageView curDCM] radionuclideTotalDoseCorrected] / 1000000. ]];
        
        if( [[imageView curDCM] radiopharmaceuticalStartTime])
            [[suvForm cellAtIndex: 3] setObjectValue: [[imageView curDCM] radiopharmaceuticalStartTime]];
        
        if( [[imageView curDCM] acquisitionTime])
            [[suvForm cellAtIndex: 4] setObjectValue: [[imageView curDCM] acquisitionTime]];
        
        [[suvForm cellAtIndex: 5] setStringValue: [NSString stringWithFormat:@"%2.2f", [[imageView curDCM] halflife] / 60.]];
        
        [editedRadiopharmaceuticalStartTime release];
        editedRadiopharmaceuticalStartTime = nil;
        
        [editedAcquisitionTime release];
        editedAcquisitionTime = nil;
        
        [NSApp beginSheet: displaySUVWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
}


#pragma mark-
#pragma mark 4.1.4 Anchored textual layer

- (void) contextualMenuEvent:(id)sender
{
    // Receives a NSMenuItem (each intermediate NSMenu is also a NSMenuItem)
    // The complete title is obtain joining the ITEM title menu title with all its MENU supermenu titles, excepted the last one
    
    // Window anchored annotations need to be updated
    // Point clicked available in [imageView contextualMenuInWindowPosX] [imageView contextualMenuInWindowPosY]
    
    NSMenu *currentMenu = [sender menu];//init of menu
    NSMenu *superMenu = [currentMenu supermenu];//init of supermenu
    NSString *currentMenuTitle = [currentMenu title];
    NSString *tail;
    NSString *composedMenuTitle = [sender title];
    int i=0;
    while ( superMenu != nil)
    {
        tail = [[composedMenuTitle copy] autorelease];
        
        composedMenuTitle = [NSString stringWithFormat:@"%@ %@",currentMenuTitle, tail];
        currentMenu = superMenu;
        currentMenuTitle = [currentMenu title];
        superMenu = [currentMenu supermenu];
        i++;
    }
    
    if ([composedMenuTitle isEqualToString:@"?"]) //creating a content panel
    {
        [NSApp beginSheet: CommentsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
    else //same action as endSetComments, but with composedMenuTitle
    {
        [[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] setValue:composedMenuTitle forKeyPath:@"series.comment"];
        
        if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
        {
            [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[CommentsEditField stringValue] forKey:@"series.comment"];
        }
        
        [[[BrowserController currentBrowser] databaseOutline] reloadData];
        
        [CommentsField setTitle: composedMenuTitle];
        
        [self buildMatrixPreview: NO];
    }
}

#pragma mark-
#pragma mark 4.1.5 Presentation in viewport


- (void) flipVertical:(id) sender
{
    [imageView flipVertical:sender];
}

- (void) flipHorizontal:(id) sender
{
    [imageView flipHorizontal:sender];
}

- (void) rotate0:(id) sender
{
    [imageView setRotation: 0];
    [self propagateSettings];
    
    [imageView setNeedsDisplay: YES];
}

- (void) rotate90:(id) sender
{
    [imageView setRotation: 90];
    [self propagateSettings];
    
    [imageView setNeedsDisplay: YES];
}

- (void) rotate180:(id) sender
{
    [imageView setRotation: 180];
    [self propagateSettings];
    
    [imageView setNeedsDisplay: YES];
}

- (void)displayDICOMOverlays: (id)sender
{
    [self revertSeries: self];
}

- (void) applyLUT: (id) sender
{
    [DCMPix checkUserDefaults: YES];
    [self revertSeries: self];
    [imageView setWLWW:[[imageView curDCM] savedWL] :[[imageView curDCM] savedWW]];
}

- (void)useVOILUT: (id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool: ![[NSUserDefaults standardUserDefaults] boolForKey: @"UseVOILUT"] forKey: @"UseVOILUT"];
    
    [self performSelector:@selector(applyLUT:) withObject: self afterDelay:0.2];
}


#pragma mark-
#pragma mark 4.1.6 Fixed graphical layer

#pragma mark-
#pragma mark 4.1.7 Fixed textual layer

#pragma mark-
#pragma mark 4.2 Tiling

#pragma mark-
#pragma mark 4.3 Multi viewport series synchronization

-(id) findSyncSeriesButton
{
    
    NSArray *items = [toolbar items];
    
    for( id loopItem in items)
    {
        if( [[loopItem itemIdentifier] isEqualToString:SyncSeriesToolbarItemIdentifier])
        {
            return loopItem;
        }
    }
    return nil;
}

- (void) notificationSyncSeries:(NSNotification*)note
{
    if( SyncButtonBehaviorIsBetweenStudies)
    {
        if( SYNCSERIES)
        {
            NSNumber *sliceLocation = [[note userInfo] objectForKey:@"sliceLocation"];
            float offset = [(DCMPix*)[[imageView dcmPixList] objectAtIndex:[imageView  curImage]] sliceLocation] - [sliceLocation floatValue];
            
            [imageView setSyncRelativeDiff:offset];
            [[self findSyncSeriesButton] setImage: [NSImage imageNamed: @"SyncLock.pdf"]];
            
            [imageView setSyncSeriesIndex: 0];
        }
        else
        {
            [[self findSyncSeriesButton] setImage: [NSImage imageNamed: SyncSeriesToolbarItemIdentifier]];
            [imageView setSyncSeriesIndex: -1];
        }
    }
    else
    {
        if( [imageView syncro] != syncroOFF)
        {
            [[self findSyncSeriesButton] setImage: [NSImage imageNamed: @"SyncLock.pdf"]];
        }
        else
        {
            [[self findSyncSeriesButton] setImage: [NSImage imageNamed: SyncSeriesToolbarItemIdentifier]];
        }
    }
}

- (void) turnOffSyncSeriesBetweenStudies:(id) sender
{
    if( SyncButtonBehaviorIsBetweenStudies)
    {
        if( SYNCSERIES)
        {
            [self SyncSeries: self];
        }
    }
}

+ (void) activateSYNCSERIESBetweenStudies
{
    if( SyncButtonBehaviorIsBetweenStudies)
    {
        SYNCSERIES = YES;
        
        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
        {
            [[v findSyncSeriesButton] setImage: [NSImage imageNamed: @"SyncLock.pdf"]];
            [v.imageView setSyncSeriesIndex: 0];
        }
    }
}

- (void) SyncSeries:(id) sender
{
    if( SyncButtonBehaviorIsBetweenStudies)
    {
        SYNCSERIES = !SYNCSERIES;
        
        float sliceLocation =  [(DCMPix*)[[imageView dcmPixList] objectAtIndex:[imageView  curImage]] sliceLocation];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat:sliceLocation] forKey:@"sliceLocation"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixSyncSeriesNotification object: self userInfo: userInfo];
    }
    else
    {
        if( [imageView syncro] == syncroOFF)
        {
            if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask)
                [imageView setSyncro: syncroREL];
            else
                [imageView setSyncro: syncroLOC];
        }
        else [imageView setSyncro: syncroOFF];
        
        [imageView becomeMainWindow];
    }
}

- (NSString*) studyInstanceUID
{
    return [[fileList[ curMovieIndex] objectAtIndex:0] valueForKeyPath: @"series.study.studyInstanceUID"];
}

- (void) SetSyncButtonBehavior:(id) sender
{
    BOOL				allFromSameStudy = YES, previousSyncButtonBehaviorIsBetweenStudies = SyncButtonBehaviorIsBetweenStudies;
    NSMutableArray		*viewersList = [ViewerController getDisplayed2DViewers];
    
    [viewersList removeObject: self];
    
    
    if( [viewersList count])
    {
        NSString	*studyID = [self studyInstanceUID];
        
        for( ViewerController *v in viewersList)
        {
            if( [studyID isEqualToString: [v studyInstanceUID]] == NO)
            {
                allFromSameStudy = NO;
            }
        }
    }
    
    if( allFromSameStudy == NO) SyncButtonBehaviorIsBetweenStudies = YES;
    else SyncButtonBehaviorIsBetweenStudies = NO;
    
    if(( SyncButtonBehaviorIsBetweenStudies == YES && previousSyncButtonBehaviorIsBetweenStudies == NO) || SyncButtonBehaviorIsBetweenStudies == NO)
    {
        //NSLog( @"SyncButtonBehaviorIsBetweenStudies = %d", SyncButtonBehaviorIsBetweenStudies);
        
        [[AppController sharedAppController] willChangeValueForKey:@"SYNCSERIES"];
        SYNCSERIES = NO;
        [[AppController sharedAppController] didChangeValueForKey:@"SYNCSERIES"];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixSyncSeriesNotification object:nil userInfo: nil];
        
        for( ViewerController *v in viewersList)
            v.imageView.syncSeriesIndex = -1;
    }
}

- (IBAction) reSyncOrigin:(id) sender
{
    float	o[ 3];
    int		x, i;
    
    if( blendingController)
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"] == NO || [imageView syncro] != syncroLOC)
        {
            float zDiff = [[[blendingController imageView] curDCM] sliceLocation] - [[imageView curDCM] sliceLocation];
            
            for( i = 0; i < maxMovieIndex; i++)
            {
                for( x = 0; x < [pixList[ i] count]; x++)
                {
                    DCMPix		*pic = [pixList[ i] objectAtIndex:x];
                    float		vectorP[ 9], tempOrigin[ 3], tempOriginBlending[ 3];
                    NSPoint		offset;
                    
                    // Compute blended view offset
                    [pic orientation: vectorP];
                    
                    tempOrigin[ 0] = [pic originX] * vectorP[ 0] + [pic originY] * vectorP[ 1] + [pic originZ] * vectorP[ 2];
                    tempOrigin[ 1] = [pic originX] * vectorP[ 3] + [pic originY] * vectorP[ 4] + [pic originZ] * vectorP[ 5];
                    tempOrigin[ 2] = [pic originX] * vectorP[ 6] + [pic originY] * vectorP[ 7] + [pic originZ] * vectorP[ 8];
                    
                    tempOriginBlending[ 0] = [[[blendingController imageView] curDCM] originX] * vectorP[ 0] + [[[blendingController imageView] curDCM] originY] * vectorP[ 1] + [[[blendingController imageView] curDCM] originZ] * vectorP[ 2];
                    tempOriginBlending[ 1] = [[[blendingController imageView] curDCM] originX] * vectorP[ 3] + [[[blendingController imageView] curDCM] originY] * vectorP[ 4] + [[[blendingController imageView] curDCM] originZ] * vectorP[ 5];
                    tempOriginBlending[ 2] = [[[blendingController imageView] curDCM] originX] * vectorP[ 6] + [[[blendingController imageView] curDCM] originY] * vectorP[ 7] + [[[blendingController imageView] curDCM] originZ] * vectorP[ 8];
                    
                    [pic setPixelSpacingX: [[imageView curDCM] pixelSpacingX] * ([[blendingController imageView] pixelSpacingX] / [[blendingController imageView] scaleValue]) /  ([[imageView curDCM] pixelSpacingX]/[imageView scaleValue])];
                    [pic setPixelSpacingY: [[imageView curDCM] pixelSpacingY] * ([[blendingController imageView] pixelSpacingY] / [[blendingController imageView] scaleValue]) / ([[imageView curDCM] pixelSpacingY]/[imageView scaleValue])];
                    
                    offset.x = (tempOrigin[0] + [pic pwidth]*[pic pixelSpacingX]/2. - (tempOriginBlending[ 0] + [[[blendingController imageView] curDCM] pwidth]*[[[blendingController imageView] curDCM] pixelSpacingX]/2.));
                    offset.y = (tempOrigin[1] + [pic pheight]*[pic pixelSpacingY]/2. - (tempOriginBlending[ 1] + [[[blendingController imageView] curDCM] pheight]*[[[blendingController imageView] curDCM] pixelSpacingY]/2.));
                    
                    o[ 0] = [pic originX];		o[ 1] = [pic originY];		o[ 2] = [pic originZ];
                    
                    o[ 0] -= ([[blendingController imageView] origin].x*[[[blendingController imageView] curDCM] pixelSpacingX]/[[blendingController imageView] scaleValue] - [imageView origin].x*[pic pixelSpacingX]/[imageView scaleValue]) + offset.x;
                    o[ 1] += ([[blendingController imageView] origin].y*[[[blendingController imageView] curDCM] pixelSpacingY]/[[blendingController imageView] scaleValue] - [imageView origin].y*[pic pixelSpacingY]/[imageView scaleValue]) - offset.y;
                    o[ 2] += zDiff;
                    
                    [pic setOrigin: o];
                    [pic computeSliceLocation];
                }
            }
            
            [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"COPYSETTINGS"];
            [imageView setSyncro: syncroLOC];
            [imageView sendSyncMessage: 0];
            [self propagateSettings];
        }
        else NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Only useful if propagate settings is OFF.", nil), nil, nil, nil);
    }
    else NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Only useful if image fusion is activated.", nil), nil, nil, nil);
}

- (void) propagateSettingsToViewer: (ViewerController*) vC
{
    float   iwl, iww;
    float   dwl, dww;
    
    // 4D data
    if( curMovieIndex != [vC curMovieIndex] && maxMovieIndex ==  [vC maxMovieIndex] && ![NavigatorWindowController navigatorWindowController])
    {
        [vC setMovieIndex: curMovieIndex];
    }
    
    BOOL registeredViewers = NO;
    
    if( [self registeredViewer] == vC || [vC registeredViewer] == self)
        registeredViewers = YES;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"] == YES)
    {
        if( [[vC curCLUTMenu] isEqualToString:[self curCLUTMenu]])
        {
            BOOL	 propagate = YES;
            
            if( [[imageView curDCM] isRGB] != [[[vC imageView] curDCM] isRGB]) propagate = NO;
            
            if( [[vC modality] isEqualToString:[self modality]] == NO) propagate = NO;
            
            if( [vC subtractionActivated] != [self subtractionActivated]) propagate = NO;
            
            if( [[vC modality] isEqualToString: @"CR"]) propagate = NO;
            if( [[self modality] isEqualToString: @"CR"]) propagate = NO;
            
            if( [[vC modality] isEqualToString: @"NM"]) propagate = NO;
            
            if( [[vC modality] isEqualToString:@"PT"] && [[self modality] isEqualToString:@"PT"])
            {
                if( [[imageView curDCM] SUVConverted] != [[[vC imageView] curDCM] SUVConverted]) propagate = NO;
            }
            
            //			if( [[vC modality] isEqualToString:@"MR"] && [[self modality] isEqualToString:@"MR"])
            //			{
            //
            //			}
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey:@"DONTCOPYWLWWSETTINGS"] == NO)
            {
                if( propagate)
                {
                    [imageView getWLWW:&iwl :&iww];
                    [[vC imageView] getWLWW:&dwl :&dww];
                    
                    if( iwl != dwl || iww != dww)
                        [[vC imageView] setWLWW:iwl :iww];
                }
            }
        }
        
        
        float vectorsA[9], vectorsB[9];
        
        [[pixList[ 0] objectAtIndex: [pixList[ 0] count]/2] orientation: vectorsA];
        [[[vC pixList] objectAtIndex: [[vC pixList] count]/2] orientation: vectorsB];
        
        float fValue;
        
        //		if(  curvedController == nil && [vC curvedController] == nil)
        {
            if( [DCMView angleBetweenVector: vectorsA+6 andVector: vectorsB+6] < [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"AlwaysPropagateScaleLevel"])
                //				&&
                //				curvedController == nil)
            {
                BOOL propagateScale = YES;
                
                if( [DCMView noPropagateSettingsInSeriesForModality: [vC modality]] && [DCMView noPropagateSettingsInSeriesForModality: [self modality]])
                    propagateScale = NO;
                
                if( propagateScale)
                {
                    if( [imageView pixelSpacing] != 0 && [[vC imageView] pixelSpacing] != 0)
                    {
                        if( [imageView scaleValue] != 0)
                        {
                            fValue = [imageView scaleValue] / [imageView pixelSpacing];
                            [[vC imageView] setScaleValue: fValue * [[vC imageView] pixelSpacing]];
                        }
                    }
                    else
                    {
                        if( [imageView scaleValue] != 0)
                            [[vC imageView] setScaleValue: [imageView scaleValue]];
                    }
                }
            }
        }
        
        if( [DCMView angleBetweenVector: vectorsA+6 andVector: vectorsB+6] < [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"])
            //			&& curvedController == nil)
        {
            //if( [self isEverythingLoaded])
            {
                //	if( [[vC modality] isEqualToString:[self modality]])	For PET CT, we have to sync this even if the modalities are not equal!
                
                if( [DCMView noPropagateSettingsInSeriesForModality: [vC modality]] && [DCMView noPropagateSettingsInSeriesForModality: [self modality]])
                {
                    
                }
                else
                {
                    if( [[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: [[[vC fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]] || registeredViewers == YES)
                    {
                        // Overlapping rect? to avoid pan if left/right limb are acquired in the same study for example
                        if( NSIntersectsRect( vC.imageView.curDCM.rectCoordinates,imageView.curDCM.rectCoordinates))
                        {
                            if( [[vC imageView] curDCM].isOriginDefined && [imageView curDCM].isOriginDefined)
                            {
                                NSPoint pan = [imageView origin];
                                NSPoint delta = [DCMPix originDeltaBetween:[[vC imageView] curDCM] And:[imageView curDCM]];
                                
                                delta.x *= [imageView scaleValue];
                                delta.y *= [imageView scaleValue];
                                
                                [[vC imageView] setOrigin: NSMakePoint( pan.x + delta.x, pan.y - delta.y)];
                            }
                        }
                    }
                    
                    fValue = [imageView rotation];
                    [[vC imageView] setRotation: fValue];
                }
            }
        }
    }
    
    if( [vC blendingController])
    {
        if( [vC blendingController] != self)
            [self propagateSettingsToViewer: [vC blendingController]];
        else
            [vC refresh];
    }
}

-(void) propagateSettings
{
    NSMutableArray *viewersList;
    
    if( [[[[fileList[0] objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"])
        return;
    
    //	if( [[self window] isVisible] == NO) return;
    if( windowWillClose) return;
    
    // *** 2D Viewers ***
    viewersList = [ViewerController getDisplayed2DViewers];
    [viewersList removeObject: self];
    
    for( ViewerController *vC in viewersList)
    {
        if( vC != self)
        {
            if( [[vC imageView] shouldPropagate] == YES)
                [self propagateSettingsToViewer: vC];
        }
    }
    
    //	// *** 3D MPR Viewers ***
    //	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
    //
    //	for( i = 0; i < [winList count]; i++)
    //	{
    //		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"MPR"])
    //		{
    //			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
    //		}
    //	}
    //
    //	for( i = 0; i < [viewersList count]; i++)
    //	{
    //		MPRController	*vC = [viewersList objectAtIndex: i];
    //
    //		if( self == [vC blendingController])
    //		{
    //			[vC updateBlendingImage];
    //		}
    //	}
    //	[viewersList release];
    
    //	// *** 3D MIP Viewers ***
    //	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
    //
    //	for( i = 0; i < [winList count]; i++)
    //	{
    //		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"MIP"])
    //		{
    //			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
    //		}
    //	}
    //
    //	for( i = 0; i < [viewersList count]; i++)
    //	{
    //		MIPController	*vC = [viewersList objectAtIndex: i];
    //
    //		if( self == [vC blendingController])
    //		{
    //			[vC updateBlendingImage];
    //		}
    //	}
    //	[viewersList release];
    
    //	// *** 2D MPR Viewers ***
    //	viewersList = [NSMutableArray array];
    //
    //	for( NSWindow *win in winList)
    //	{
    //		if( [[[win windowController] windowNibName] isEqualToString:@"MPR2D"])
    //		{
    //			if( self != [win windowController]) [viewersList addObject: [win windowController]];
    //		}
    //	}
    //
    //	for( MPR2DController *vC in viewersList)
    //	{
    //		if( [vC blendingController])
    //			[vC updateBlendingImage];
    //	}
    
#ifndef OSIRIX_LIGHT
    // *** VR Viewers ***
    viewersList = [NSMutableArray array];
    
    for( NSWindow *win in [NSApp windows])
    {
        if( [[[win windowController] windowNibName] isEqualToString:@"VR"] ||
           [[[win windowController] windowNibName] isEqualToString:@"VRPanel"])
        {
            if( self != [win windowController]) [viewersList addObject: [win windowController]];
        }
    }
    
    for( VRController *vC in viewersList)
    {
        if( [vC blendingController])
            [vC updateBlendingImage];
    }
#endif
}

#pragma mark Registration

- (ViewerController*) registeredViewer
{
    return registeredViewer;
}

- (void) setRegisteredViewer: (ViewerController*) viewer
{
    registeredViewer = viewer;
}

- (NSMutableArray*) point2DList
{
    NSMutableArray * points2D = [NSMutableArray array];
    NSMutableArray * allROIs = [self roiList];
    
    ROI *curRoi;
    int s,i;
    
    for(s=0; s<[allROIs count]; s++)
    {
        for(i=0; i<[[allROIs objectAtIndex:s] count]; i++)
        {
            curRoi = (ROI*)[[allROIs objectAtIndex:s] objectAtIndex:i];
            [curRoi setPix: [[self pixList] objectAtIndex: s]];
            if([curRoi type] == t2DPoint)
            {
                [points2D addObject:curRoi];
            }
        }
    }
    return points2D;
}

#ifndef OSIRIX_LIGHT
- (ViewerController*) resampleSeriesInNewOrientation
{
    return nil;
}

- (ViewerController*) resampleSeries:(ViewerController*) movingViewer
{
    return [self resampleSeries: movingViewer rescale: YES];
}

- (ViewerController*) resampleSeries:(ViewerController*) movingViewer rescale: (BOOL) rescale
{
    [movingViewer displayWarningIfGantryTitled];
    [self displayWarningIfGantryTitled];
    
    ViewerController *newViewer = nil;
    
    BOOL volumicSelf = YES;
    BOOL volumicMoving = YES;
    
    if( self.pixList.count > 1)
    {
        if( [self isDataVolumicIn4D: YES] == NO)
            volumicSelf = NO;
        
        if( [self computeInterval] == 0)
            volumicSelf = NO;
    }
    else
    {
        DCMPix *p = self.pixList.lastObject;
        
        double orientation[ 9];
        [p orientationDouble: orientation];
        
        if( orientation[ 6] == 0 && orientation[ 7] == 0 && orientation[ 8] == 0)
            volumicSelf = NO;
    }
    
    if( movingViewer.pixList.count > 1)
    {
        if( [movingViewer isDataVolumicIn4D: YES] == NO)
            volumicMoving = NO;
        
        if( [movingViewer computeInterval] == 0)
            volumicMoving = NO;
    }
    else
    {
        DCMPix *p = movingViewer.pixList.lastObject;
        
        double orientation[ 9];
        [p orientationDouble: orientation];
        
        if( orientation[ 6] == 0 && orientation[ 7] == 0 && orientation[ 8] == 0)
            volumicMoving = NO;
    }
    
    if( volumicSelf == NO || volumicMoving == NO)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Resampling Error", nil),
                                NSLocalizedString(@"3D Resampling requires volumic data.", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
        
        return nil;
    }
    
    if( [[self studyInstanceUID] isEqualToString: [movingViewer studyInstanceUID]])
    {
        float vectorModel[ 9], vectorSensor[ 9];
        
        [[[movingViewer pixList] objectAtIndex:0] orientation: vectorSensor];
        [[[self pixList] objectAtIndex:0] orientation: vectorModel];
        
        double matrix[ 12], length;
        
        // No translation -> same origin, same study
        matrix[ 9] = 0;
        matrix[ 10] = 0;
        matrix[ 11] = 0;
        
        // --
        
        matrix[ 0] = vectorSensor[ 0] * vectorModel[ 0] + vectorSensor[ 1] * vectorModel[ 1] + vectorSensor[ 2] * vectorModel[ 2];
        matrix[ 1] = vectorSensor[ 0] * vectorModel[ 3] + vectorSensor[ 1] * vectorModel[ 4] + vectorSensor[ 2] * vectorModel[ 5];
        matrix[ 2] = vectorSensor[ 0] * vectorModel[ 6] + vectorSensor[ 1] * vectorModel[ 7] + vectorSensor[ 2] * vectorModel[ 8];
        
        length = sqrt(matrix[0]*matrix[0] + matrix[1]*matrix[1] + matrix[2]*matrix[2]);
        
        matrix[0] = matrix[ 0] / length;
        matrix[1] = matrix[ 1] / length;
        matrix[2] = matrix[ 2] / length;
        
        // --
        
        matrix[ 3] = vectorSensor[ 3] * vectorModel[ 0] + vectorSensor[ 4] * vectorModel[ 1] + vectorSensor[ 5] * vectorModel[ 2];
        matrix[ 4] = vectorSensor[ 3] * vectorModel[ 3] + vectorSensor[ 4] * vectorModel[ 4] + vectorSensor[ 5] * vectorModel[ 5];
        matrix[ 5] = vectorSensor[ 3] * vectorModel[ 6] + vectorSensor[ 4] * vectorModel[ 7] + vectorSensor[ 5] * vectorModel[ 8];
        
        length = sqrt(matrix[3]*matrix[3] + matrix[4]*matrix[4] + matrix[5]*matrix[5]);
        
        matrix[3] = matrix[ 3] / length;
        matrix[4] = matrix[ 4] / length;
        matrix[5] = matrix[ 5] / length;
        
        // --
        
        matrix[6] = matrix[1]*matrix[5] - matrix[2]*matrix[4];
        matrix[7] = matrix[2]*matrix[3] - matrix[0]*matrix[5];
        matrix[8] = matrix[0]*matrix[4] - matrix[1]*matrix[3];
        
        length = sqrt(matrix[6]*matrix[6] + matrix[7]*matrix[7] + matrix[8]*matrix[8]);
        
        matrix[6] = matrix[ 6] / length;
        matrix[7] = matrix[ 7] / length;
        matrix[8] = matrix[ 8] / length;
        
        // --
        
        ITKTransform * transform = [[ITKTransform alloc] initWithViewer:movingViewer];
        
        newViewer = [transform computeAffineTransformWithParameters: matrix resampleOnViewer: self rescale: rescale];
        
        [imageView sendSyncMessage: 0];
        [self adjustSlider];
        
        [transform release];
    }
    else
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Resampling Error", nil),
                                NSLocalizedString(@"Resampling is only available for series in the SAME study.", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
    }
    
    return newViewer;
}

- (void) computeRegistrationWithMovingViewer:(ViewerController*) movingViewer
{
    BOOL volumicSelf = YES;
    BOOL volumicMoving = YES;
    
    if( self.pixList.count > 1)
    {
        if( [self isDataVolumicIn4D: YES] == NO)
            volumicSelf = NO;
        
        if( [self computeInterval] == 0)
            volumicSelf = NO;
    }
    else
    {
        DCMPix *p = self.pixList.lastObject;
        
        double orientation[ 9];
        [p orientationDouble: orientation];
        
        if( orientation[ 6] == 0 && orientation[ 7] == 0 && orientation[ 8] == 0)
            volumicSelf = NO;
    }
    
    if( movingViewer.pixList.count > 1)
    {
        if( [movingViewer isDataVolumicIn4D: YES] == NO)
            volumicMoving = NO;
        
        if( [movingViewer computeInterval] == 0)
            volumicMoving = NO;
    }
    else
    {
        DCMPix *p = movingViewer.pixList.lastObject;
        
        double orientation[ 9];
        [p orientationDouble: orientation];
        
        if( orientation[ 6] == 0 && orientation[ 7] == 0 && orientation[ 8] == 0)
            volumicMoving = NO;
    }
    
    if( volumicSelf == NO || volumicMoving == NO)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Registration Error", nil),
                                NSLocalizedString(@"3D Resampling requires volumic data.", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    
    //	NSLog(@" ***** Points 2D ***** ");
    // find all the Point ROIs on this viewer (fixed)
    NSMutableArray * modelPointROIs = [self point2DList];
    // find all the Point ROIs on the dragged viewer (moving)
    NSMutableArray * sensorPointROIs = [movingViewer point2DList];
    
    // order the Points by name. Not necessary but useful for debugging.
    [modelPointROIs sortUsingFunction:sortROIByName context:NULL];
    [sensorPointROIs sortUsingFunction:sortROIByName context:NULL];
    
    int numberOfPoints = [modelPointROIs count];
    // we need the same number of points
    BOOL sameNumberOfPoints = ([sensorPointROIs count] == numberOfPoints);
    // we need at least 3 points
    BOOL enoughPoints = (numberOfPoints>=3);
    // each point on the moving viewer needs a twin on the fixed viewer.
    // two points are twin brothers if and only if they have the same name.
    BOOL pointsNamesMatch2by2 = YES;
    // triplets are illegal (since we don't know which point to map)
    BOOL triplets = NO;
    
    NSMutableArray *previousNames = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSString *modelName, *sensorName;
    NSMutableString *errorString = [NSMutableString stringWithString:@""];
    
    BOOL foundAMatchingName;
    
    if (sameNumberOfPoints && enoughPoints)
    {
        HornRegistration *hr = [[HornRegistration alloc] init];
        
        float vectorModel[ 9], vectorSensor[ 9];
        
        [[[movingViewer pixList] objectAtIndex:0] orientation: vectorSensor];
        [[[self pixList] objectAtIndex:0] orientation: vectorModel];
        
        int i,j; // 'for' indexes
        for (i=0; i<[modelPointROIs count] && pointsNamesMatch2by2 && !triplets; i++)
        {
            ROI *curModelPoint2D = [modelPointROIs objectAtIndex:i];
            modelName = [curModelPoint2D name];
            foundAMatchingName = NO;
            
            for (j=0; j<[sensorPointROIs count] && !foundAMatchingName; j++)
            {
                ROI *curSensorPoint2D = [sensorPointROIs objectAtIndex:j];
                sensorName = [curSensorPoint2D name];
                
                for (id loopItem2 in previousNames)
                {
                    triplets = triplets || [modelName isEqualToString:loopItem2]
                    || [sensorName isEqualToString:loopItem2];
                }
                
                pointsNamesMatch2by2 = [sensorName isEqualToString:modelName];
                
                if(pointsNamesMatch2by2)
                {
                    foundAMatchingName = YES; // stop the research
                    [sensorPointROIs removeObjectAtIndex:j]; // to accelerate the research
                    j--;
                    
                    [previousNames addObject:sensorName]; // to avoid triplets
                    
                    if(!triplets)
                    {
                        float modelLocation[3], sensorLocation[3];
                        
                        [[curModelPoint2D pix]	convertPixX:	[[[curModelPoint2D points] objectAtIndex:0] x]
                                                      pixY:			[[[curModelPoint2D points] objectAtIndex:0] y]
                                             toDICOMCoords:	modelLocation
                                               pixelCenter: YES];
                        
                        [[curSensorPoint2D pix]	convertPixX:	[[[curSensorPoint2D points] objectAtIndex:0] x]
                                                       pixY:			[[[curSensorPoint2D points] objectAtIndex:0] y]
                                              toDICOMCoords:	sensorLocation
                                                pixelCenter: YES];
                        
                        // Convert the point in 3D orientation of the model
                        
                        float modelLocationConverted[ 3];
                        
                        modelLocationConverted[ 0] = modelLocation[ 0];
                        modelLocationConverted[ 1] = modelLocation[ 1];
                        modelLocationConverted[ 2] = modelLocation[ 2];
                        modelLocationConverted[ 0] = modelLocation[ 0] * vectorModel[ 0] + modelLocation[ 1] * vectorModel[ 1] + modelLocation[ 2] * vectorModel[ 2];
                        modelLocationConverted[ 1] = modelLocation[ 0] * vectorModel[ 3] + modelLocation[ 1] * vectorModel[ 4] + modelLocation[ 2] * vectorModel[ 5];
                        modelLocationConverted[ 2] = modelLocation[ 0] * vectorModel[ 6] + modelLocation[ 1] * vectorModel[ 7] + modelLocation[ 2] * vectorModel[ 8];
                        
                        float sensorLocationConverted[ 3];
                        
                        sensorLocationConverted[ 0] = sensorLocation[ 0];
                        sensorLocationConverted[ 1] = sensorLocation[ 1];
                        sensorLocationConverted[ 2] = sensorLocation[ 2];
                        sensorLocationConverted[ 0] = sensorLocation[ 0] * vectorSensor[ 0] + sensorLocation[ 1] * vectorSensor[ 1] + sensorLocation[ 2] * vectorSensor[ 2];
                        sensorLocationConverted[ 1] = sensorLocation[ 0] * vectorSensor[ 3] + sensorLocation[ 1] * vectorSensor[ 4] + sensorLocation[ 2] * vectorSensor[ 5];
                        sensorLocationConverted[ 2] = sensorLocation[ 0] * vectorSensor[ 6] + sensorLocation[ 1] * vectorSensor[ 7] + sensorLocation[ 2] * vectorSensor[ 8];
                        
                        // add the points to the registration method
                        [hr addModelPointX: modelLocationConverted[0] Y: modelLocationConverted[1] Z: modelLocationConverted[2]];
                        [hr addSensorPointX: sensorLocationConverted[0] Y: sensorLocationConverted[1] Z: sensorLocationConverted[2]];
                    }
                }
            }
        }
        
        if(pointsNamesMatch2by2 && !triplets)
        {
            double matrix[ 16];
            
            [hr computeVTK :matrix];
            
            ITKTransform * transform = [[ITKTransform alloc] initWithViewer:movingViewer];
            
            /*ViewerController *newViewer =*/ [transform computeAffineTransformWithParameters: matrix resampleOnViewer: self];
            
            [imageView sendSyncMessage: 0];
            [self adjustSlider];
            
            [transform release];
        }
        [hr release];
    }
    else
    {
        if(!sameNumberOfPoints)
        {
            // warn user to set the same number of points on both viewers
            [errorString appendString:NSLocalizedString(@"Needs same number of points on both viewers.",nil)];
        }
        
        if(!enoughPoints)
        {
            // warn user to set at least 3 points on both viewers
            if([errorString length]!=0) [errorString appendString:@"\n"];
            [errorString appendString:NSLocalizedString(@"Needs at least 3 points on both viewers.",nil)];
        }
    }
    
    if(!pointsNamesMatch2by2)
    {
        // warn user
        if([errorString length]!=0) [errorString appendString:@"\n"];
        [errorString appendString:NSLocalizedString(@"Points names must match 2 by 2.",nil)];
    }
    
    if(triplets)
    {
        // warn user
        if([errorString length]!=0) [errorString appendString:@"\n"];
        [errorString appendString:NSLocalizedString(@"Max. 2 points with the same name.",nil)];
    }
    
    if([errorString length]!=0)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Point-Based Registration Error", nil),
                                @"%@",
                                NSLocalizedString(@"OK", nil), nil, nil, errorString);
    }
    
    [previousNames release];
}
#endif

#pragma mark segmentation
//
//-(IBAction) startMSRGWithAutomaticBounding:(id) sender
//{
//	NSLog(@"startMSRGWithAutomaticBounding !");
//}
//-(IBAction) startMSRG:(id) sender
//{
//	NSLog(@"Start MSRG ....");
//	// I - R√©cup√©ration des AUTRES ViewerController, nombre de crit√®res
//	NSMutableArray		*viewersList = [ViewerController getDisplayed2DViewers];;
//
//	[viewersList removeObject: self];
//
//	for( ViewerController *vC in viewersList)
//	{
//	}
//	/*
//	 DCMPix	*curPix = [[self pixList] objectAtIndex: [imageView curImage]];
//	 long height=[curPix pheight];
//	 long width=[curPix pwidth];
//	 long depth=[[self pixList] count];
//	 int* aBuffer=(int*)malloc(width*height*depth*sizeof(int));
//	 if (aBuffer)
//	 {
//		 // clear texture
//		 for(l=0;l<width*height*depth;l++)
//			 aBuffer[l]=0;
//		 // region 1
//
//		 for(k=0;k<depth;k++)
//			 for(j=50;j<70;j++)
//				 for(i=60;i<70;i++)
//					 aBuffer[i+j*width+k*width*height]=1;
//		 // region 2
//
//		 for(k=0;k<5;k++)
//			 for(j=0;j<10;j++)
//				 for(i=0;i<10;i++)
//					 aBuffer[i+j*width+k*width*height]=2;
//
//		 [self addRoiFromFullStackBuffer:aBuffer];
//		 free(aBuffer);
//	 }
//	 */
//	 MSRGWindowController *msrgController = [[MSRGWindowController alloc] initWithMarkerViewer:self andViewersList:viewersList];
//	 if( msrgController)
//		{
//			[msrgController showWindow:self];
//			[[msrgController window] makeKeyAndOrderFront:self];
//		}
///*
//	MSRGSegmentation *msrgSeg=[[MSRGSegmentation alloc] initWithViewerList:viewersList currentViewer:self];
//	[msrgSeg startMSRGSegmentation];
//	*/
//}


#pragma mark-
#pragma mark 4.4 Navigation
#pragma mark 4.4.1 Series navigation

- (NSMutableArray*) pixList: (long) i
{
    if( i < 0) i = 0;
    if( i>= maxMovieIndex) i = maxMovieIndex-1;
    
    return pixList[ i];
}

- (NSMutableArray*) pixList
{
    return pixList[ curMovieIndex];
}

- (NSMutableArray*) fileList
{
    return fileList[ curMovieIndex];
}

- (NSMutableArray*) fileList: (long) i
{
    if( i < 0) i = 0;
    if( i>= maxMovieIndex) i = maxMovieIndex-1;
    
    return fileList[ i];
}

-(void) addMovieSerie:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
    long	i;
    
    volumeData[ maxMovieIndex] = v;
    [volumeData[ maxMovieIndex] retain];
    [self sendDidAllocateVolumeDataNotificationWithVolumeData:volumeData[ maxMovieIndex] movieIndex:maxMovieIndex];
    
    [f retain];
    pixList[ maxMovieIndex] = f;
    
    [d retain];
    fileList[ maxMovieIndex] = d;
    
    // Prepare pixList for image thick slab
    for( i = 0; i < [pixList[maxMovieIndex] count]; i++)
    {
        [[pixList[maxMovieIndex] objectAtIndex: i] setArrayPix: pixList[maxMovieIndex] :i];
    }
    
    // create empty ROI List for this new serie
    copyRoiList[maxMovieIndex] = [[NSMutableArray alloc] initWithCapacity: 0];
    roiList[maxMovieIndex] = [[NSMutableArray alloc] initWithCapacity: 0];
    
    for( i = 0; i < [pixList[maxMovieIndex] count]; i++)
    {
        [roiList[maxMovieIndex] addObject:[NSMutableArray array]];
        [copyRoiList[maxMovieIndex] addObject: [NSData data]];
    }
    [self loadROI: maxMovieIndex];
    
    maxMovieIndex++;
    
    [moviePosSlider setMaxValue:maxMovieIndex-1];
    [moviePosSlider setNumberOfTickMarks:maxMovieIndex];
    
    [movieRateSlider setEnabled: YES];
    [moviePosSlider setEnabled: YES];
    [moviePlayStop setEnabled: YES];
    
    if( [pixList[ 0] count])
    {
        NSData *tf = [[pixList[ 0] lastObject] transferFunction];
        
        for( DCMPix *d in pixList[ maxMovieIndex-1])
            [d setTransferFunction: tf];
    }
}

- (float) frameRate
{
    return [speedSlider floatValue];
}

- (float) movieRate
{
    return [movieRateSlider floatValue];
}

- (void) speedSliderAction:(id) sender
{
    [speedText setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.1f im/s", @"im/s = images per second"), (float) [self frameRate] * direction]];
    
    if( [[self window] isKeyWindow])
    {
        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
        {
            if( v != self)
            {
                if( [v frameRate] == [[NSUserDefaults standardUserDefaults] floatForKey: @"defaultFrameRate"])
                {
                    if( v.speedSlider.floatValue != self.frameRate)
                    {
                        v.speedSlider.floatValue = self.frameRate;
                        v.speedText.stringValue = [NSString stringWithFormat: NSLocalizedString( @"%0.1f im/s", @"im/s = images per second"), (float) [self frameRate] * direction];
                    }
                }
            }
        }
        [[NSUserDefaults standardUserDefaults] setFloat: [self frameRate] forKey: @"defaultFrameRate"];
    }
}

- (void) movieRateSliderAction:(id) sender
{
    float movieRate = (float) [self movieRate];

    [movieTextSlide setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.0f im/s", @"im/s = images per second"), movieRate]];

    if( [[self window] isKeyWindow])
    {
        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
        {
            if( v != self)
            {
                if( [v movieRate] == [[NSUserDefaults standardUserDefaults] floatForKey: @"defaultMovieRate"])
                {
                    if( v.movieRateSlider.floatValue != movieRate)
                    {
                        v.movieRateSlider.floatValue = movieRate;
                        v.movieTextSlide.stringValue = [NSString stringWithFormat: NSLocalizedString( @"%0.0f im/s", @"im/s = images per second"), movieRate];
                    }
                }
            }
        }
        [[NSUserDefaults standardUserDefaults] setFloat: movieRate forKey: @"defaultMovieRate"];
    }
}

-(NSSlider*) moviePosSlider
{
    return moviePosSlider;
}

- (void) setMovieIndex: (short) i
{
    [[[NavigatorWindowController navigatorWindowController] navigatorView] removeNotificationObserver];
    
    int index = [imageView curImage];
    BOOL wasDataFlipped = [imageView flippedData];
    
    curMovieIndex = i;
    if( curMovieIndex < 0) curMovieIndex = maxMovieIndex-1;
    if( curMovieIndex >= maxMovieIndex) curMovieIndex = 0;
    
    [moviePosSlider setIntValue:curMovieIndex];
    
    [seriesView setPixels:pixList[ curMovieIndex] files:fileList[ curMovieIndex] rois:roiList[ curMovieIndex] firstImage:0 level:'i' reset: NO];	//[pixList[0] count]/2
    
    [self setWindowTitle: self];
    
    if( wasDataFlipped) [self flipDataSeries: self];
    
    [[[NavigatorWindowController navigatorWindowController] navigatorView] addNotificationObserver];
    
    if( [imageView columns] > 1 || [imageView rows] > 1)
    {
        if( index == 0)
            [imageView setIndex: (long)[pixList[ curMovieIndex] count] -1];
        else
            [imageView setIndex: 0];
    }
    
    [imageView setIndex: index];
    
    [imageView sendSyncMessage: 0];
    
    [self adjustSlider];
    
    [self showCurrentThumbnail:self];
}

- (void) moviePosSliderAction:(id) sender
{
    [self setMovieIndex: [moviePosSlider intValue]];
    [self propagateSettings];
}

- (void)adjustSlider
{
    if( [imageView flippedData]) [slider setIntValue: [pixList[ curMovieIndex] count] - [imageView curImage] -1];
    else [slider setIntValue:[imageView curImage]];
    
    [self adjustKeyImage];
}

- (short) curMovieIndex { return curMovieIndex;}

- (void) performMovieAnimation:(id) sender
{
    @synchronized( loadingThread)
    {
        if( loadingThread.isExecuting && [[loadingThread.threadDictionary objectForKey: @"loadingPercentage"] floatValue] < 0.5)
            return;
    }
    
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    
    if( thisTime - lastMovieTime > 1.0 / [movieRateSlider floatValue])
    {
        short val = curMovieIndex;
        val ++;
        
        if( val < 0) val = 0;
        if( val >= maxMovieIndex) val = 0;
        
        curMovieIndex = val;
        
        [self setMovieIndex: val];
        [self propagateSettings];
        
        lastMovieTime = thisTime;
    }
}

- (long) imageIndex
{
    if( [imageView flippedData]) return [self getNumberOfImages] -1 - [imageView curImage];
    return  [imageView curImage];
}

- (void) setImageIndex:(long) i
{
    if( i < 0) i = 0;
    if( i >= [self getNumberOfImages]) i = [self getNumberOfImages] -1;
    
    if( [imageView flippedData]) [imageView setIndex: [self getNumberOfImages] -1 -i];
    else [imageView setIndex: i];
    
    [imageView sendSyncMessage: 0];
    
    [self adjustSlider];
    
    [imageView displayIfNeeded];
}

- (void) setImage:(NSManagedObject*) image
{
    for( int x = 0 ; x < maxMovieIndex ; x++)
    {
        for( NSManagedObject* i in fileList[ x])
        {
            if( image == i)
            {
                [self setMovieIndex: x];
                [imageView setIndex: [fileList[ x] indexOfObject: i]];
                [imageView sendSyncMessage: 0];
                [self adjustSlider];
                [imageView displayIfNeeded];
                
                return;
            }
        }
    }
}

- (void) performAnimation:(id) sender
{
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
    if( windowWillClose)
        return;
    
    @synchronized( loadingThread)
    {
        if( loadingThread.isExecuting && [[loadingThread.threadDictionary objectForKey: @"loadingPercentage"] floatValue] < 0.5)
            return;
    }
    
    if( [pixList[ curMovieIndex] count] <= 1) return;
    
    if( thisTime - lastTimeFrame > 1.0)
    {
        [speedText setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.1f im/s", @"im/s = images per second"), (float) speedometer * direction / (thisTime - lastTimeFrame) ]];
        
        speedometer = 0;
        
        lastTimeFrame = thisTime;
    }
    
    if( thisTime - lastTime > 1.0 / [speedSlider floatValue])
    {
        val = [imageView curImage];
        
        if( [imageView flippedData]) val -= direction;
        else val += direction;
        
        if( [loopButton state] == NSOnState)
        {
            if( val < 0) val = (long)[pixList[ curMovieIndex] count]-1;
            if( val >= [pixList[ curMovieIndex] count]) val = 0;
        }
        else
        {
            if( val < 0)
            {
                val = 0;
                direction = -direction;
                val += direction;
                if( val < 0) val = 0;
            }
            
            if( val >= [pixList[ curMovieIndex] count])
            {
                val = (long)[pixList[ curMovieIndex] count]-1;
                direction = -direction;
                val += direction;
                if( val >= [pixList[ curMovieIndex] count]) val = (long)[pixList[ curMovieIndex] count]-1;
            }
        }
        
        [imageView setIndex:val];
        
        [self adjustSlider];
        
        [imageView sendSyncMessage: 0];
        
        lastTime = thisTime;
        
        //		if( TICKPLAY)
        //		{
        //			if( [[self modality] isEqualToString:@"XA"])
        //			{
        //				[tickSound stop];
        //				[tickSound play];
        //			}
        //		}
        
        [imageView displayIfNeeded];
        speedometer++;
    }
}

- (void) MovieStop:(id) sender
{
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
    }
}

- (void) MoviePlayStop:(id) sender
{
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
        
        [moviePlayStop setTitle: NSLocalizedString(@"Play", nil)];
        
        [movieTextSlide setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.0f im/s", @"im/s = images per second"), (float) [movieRateSlider floatValue]]];
    }
    else
    {
        NSArray		*winList = [NSApp windows];
        
        for( id loopItem in winList)
        {
            if( [[loopItem windowController] isKindOfClass:[ViewerController class]])
            {
                [[loopItem windowController] MovieStop: self];
            }
        }
        
        [self checkEverythingLoaded];
        
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
        
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
        
        [moviePlayStop setTitle: NSLocalizedString(@"Stop", nil)];
    }
}

- (BOOL)isPlaying4D;
{
    if(movieTimer) return YES;
    return NO;
}

- (void) notificationStopPlaying:(NSNotification*)note
{
    if( timer) [self PlayStop:[self findPlayStopButton]];
}


- (void) PlayStop:(id) sender
{
    if( timer)
    {
        [timer invalidate];
        [timer release];
        timer = nil;
        
        [sender setImage: [NSImage imageNamed: PlayToolbarItemIdentifier]];
        [sender setLabel: NSLocalizedString(@"Browse", nil)];
        [sender setPaletteLabel: NSLocalizedString(@"Browse", nil)];
        [sender setToolTip: NSLocalizedString(@"Browse this series", nil)];
        
        [speedText setStringValue:[NSString stringWithFormat: NSLocalizedString( @"%0.1f im/s", @"im/s = images per second"), (float) [self frameRate]*direction]];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixStopPlayingNotification object: self userInfo: nil];
        
        timer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(performAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
        
        lastTime = [NSDate timeIntervalSinceReferenceDate];
        lastTimeFrame = [NSDate timeIntervalSinceReferenceDate];
        
        [sender setImage: [NSImage imageNamed: PauseToolbarItemIdentifier]];
        [sender setLabel: NSLocalizedString(@"Stop", nil)];
        [sender setPaletteLabel: NSLocalizedString(@"Stop", nil)];
    }
}

#pragma mark-
#pragma mark 4.4.2 4D navigation

- (float) frame4DRate
{
    return [movieRateSlider floatValue];
}


#pragma mark-
#pragma mark 4.5 External functions
#pragma mark 4.5.1 Exportation of image
#pragma mark 4.5.1.1 Exportation of image produced


#ifndef OSIRIX_LIGHT
- (IBAction) sortSeriesByValue: (id) sender
{
    switch( [sender tag])
    {
        case 0:
            [self sortSeriesByValue: @"instanceNumber" ascending: YES];
            break;
        case 1:
            [self sortSeriesByValue: @"instanceNumber" ascending: NO];
            break;
        case 2:
            [self sortSeriesByValue: @"sliceLocation" ascending: YES];
            break;
        case 3:
            [self sortSeriesByValue: @"sliceLocation" ascending: NO];
            break;
    }
}

- (BOOL) sortSeriesByValue: (NSString*) key ascending: (BOOL) ascending
{
    [self checkEverythingLoaded];
    
    NSMutableArray *xPix = [NSMutableArray array];
    NSMutableArray *xFiles = [NSMutableArray array];
    NSMutableArray *xData = [NSMutableArray array];
    
    for( int i = 0; i < maxMovieIndex; i++)
    {
        NSArray *sortedArray = nil;
        
        @try
        {
            sortedArray = [fileList[ i] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: key ascending: ascending] autorelease]]];
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
            return NO;
        }
        // Create the new series
        
        NSMutableArray *newPixList = [NSMutableArray array];
        NSMutableArray *newDcmList = [NSMutableArray array];
        
        float *seriesData = (float*) malloc( [volumeData[ i] length]);
        if( seriesData == nil) return NO;
        
        NSData *newData = [NSData dataWithBytesNoCopy: seriesData length:[volumeData[ i] length] freeWhenDone: YES];
        
        for( int x = 0, size = 0; x < [pixList[ i] count]; x++)
        {
            int oldIndex = [fileList[ i] indexOfObjectIdenticalTo: [sortedArray objectAtIndex: x]];
            DCMPix *p = [pixList[ i] objectAtIndex: oldIndex];
            
            DCMPix *newPix = [[p copy] autorelease];
            
            [newPix setfImage: seriesData + size];
            memcpy( seriesData + size, [p fImage],  [p pwidth] * [p pheight] * sizeof( float));
            size += [p pwidth] * [p pheight];
            
            [newPixList addObject: newPix];
            [newDcmList addObject: [fileList[ i] objectAtIndex: oldIndex]];
        }
        
        [xPix addObject: newPixList];
        [xFiles addObject: newDcmList];
        [xData addObject: newData];
    }
    
    // Replace the current series with the new series
    
    int mx = maxMovieIndex;
    
    for( int j = 0 ; j < mx ; j ++)
    {
        if( j == 0)
            [self changeImageData: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j] :NO];
        else
            [self addMovieSerie: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j]];
    }
    
    [self computeInterval];
    [self setWindowTitle:self];
    
    [imageView setIndex: 0];
    [imageView sendSyncMessage: 0];
    
    [self adjustSlider];
    
    postprocessed = YES;
    
    return YES;
}

- (BOOL) sortSeriesByDICOMGroup: (int) gr element: (int) el
{
    [self checkEverythingLoaded];
    
    NSMutableArray *xPix = [NSMutableArray array];
    NSMutableArray *xFiles = [NSMutableArray array];
    NSMutableArray *xData = [NSMutableArray array];
    
    for( int i = 0; i < maxMovieIndex; i++)
    {
        NSMutableArray *sortingArray = [NSMutableArray array];
        
        for( int x = 0; x < [pixList[ i] count]; x++)
        {
            DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:[[pixList[i] objectAtIndex:x] srcFile] decodingPixelData:NO];
            
            DCMAttribute *attr = [dcmObject attributeForTag: [DCMAttributeTag tagWithGroup: gr element: el]];
            
            if( attr && [[attr values] objectAtIndex: 0])
            {
                if( [[[attr values] objectAtIndex: 0] isKindOfClass: [NSString class]])
                {
                    NSString *s = [[attr values] objectAtIndex: 0];
                    
                    BOOL dot = NO;
                    BOOL onlyNumber = YES;
                    
                    for( int z = 0; z < [s length]; z++)
                    {
                        unichar c = [s characterAtIndex: z];
                        
                        if( c == '.')
                        {
                            if( dot == NO) dot = YES;
                            else onlyNumber = NO;
                        }
                        else if( c >= '0' && c <= '9') onlyNumber = onlyNumber;
                        else if( c == '-') onlyNumber = onlyNumber;
                        else onlyNumber = NO;
                    }
                    
                    if( onlyNumber)
                    {
                        [sortingArray addObject: [NSNumber numberWithFloat: [s floatValue]]];
                    }
                    else [sortingArray addObject: s];
                }
                else
                    [sortingArray addObject: [[attr values] objectAtIndex: 0]];
            }
            else [sortingArray addObject: [NSNumber numberWithInt: 0]];
        }
        
        NSArray *sortedArray = [sortingArray sortedArrayUsingSelector: @selector(compare:)];
        
        // Create the new series
        
        NSMutableArray *newPixList = [NSMutableArray array];
        NSMutableArray *newDcmList = [NSMutableArray array];
        
        float *seriesData = (float*) malloc( [volumeData[ i] length]);
        if( seriesData == nil) return NO;
        
        NSData *newData = [NSData dataWithBytesNoCopy: seriesData length:[volumeData[ i] length] freeWhenDone: YES];
        
        for( int x = 0, size = 0; x < [pixList[ i] count]; x++)
        {
            int oldIndex = [sortingArray indexOfObjectIdenticalTo: [sortedArray objectAtIndex: x]];
            DCMPix *p = [pixList[ i] objectAtIndex: oldIndex];
            
            DCMPix *newPix = [[p copy] autorelease];
            
            [newPix setfImage: seriesData + size];
            memcpy( seriesData + size, [p fImage],  [p pwidth] * [p pheight] * sizeof( float));
            size += [p pwidth] * [p pheight];
            
            [newPixList addObject: newPix];
            [newDcmList addObject: [fileList[ i] objectAtIndex: oldIndex]];
        }
        
        [xPix addObject: newPixList];
        [xFiles addObject: newDcmList];
        [xData addObject: newData];
    }
    
    // Replace the current series with the new series
    
    int mx = maxMovieIndex;
    
    for( int j = 0 ; j < mx ; j ++)
    {
        if( j == 0)
            [self changeImageData: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j] :NO];
        else
            [self addMovieSerie: [xPix objectAtIndex: j] :[xFiles objectAtIndex: j] :[xData objectAtIndex: j]];
    }
    
    [self computeInterval];
    [self setWindowTitle:self];
    
    [imageView setIndex: 0];
    [imageView sendSyncMessage: 0];
    
    [self adjustSlider];
    
    postprocessed = YES;
    
    return YES;
}
#endif

-(IBAction) setPagesToPrint:(id) sender
{
    if( sender == printTo) [printToText setIntValue: [printTo intValue]];
    if( sender == printFrom) [printFromText setIntValue: [printFrom intValue]];
    if( sender == printInterval) [printIntervalText setIntValue: [printInterval intValue]];
    
    if( sender == printToText) [printTo setIntValue: [printToText intValue]];
    if( sender == printFromText) [printFrom setIntValue: [printFromText intValue]];
    if( sender == printIntervalText) [printInterval setIntValue: [printIntervalText intValue]];
    
    int from;
    int to;
    int interval;
    
    int ipp = [[printLayout selectedItem] tag];
    if( ipp < 1) ipp = 1;
    
    switch( [[printSelection selectedCell] tag])
    {
        case 0:
            from = [imageView curImage];
            to = from+1;
            interval = 1;
            break;
            
        case 1:
            from = 0;
            to = [pixList [curMovieIndex] count];
            interval = 1;
            break;
            
        case 2:
            if( [printFrom intValue] < [printTo intValue])
            {
                from = [printFrom intValue]-1;
                to = [printTo intValue];
            }
            else
            {
                to = [printFrom intValue];
                from = [printTo intValue]-1;
            }
            
            if( to == from) to = from+1;
            
            interval = [printInterval intValue];
            break;
    }
    
    int i, count = 0;
    for( i = from; i < to; i += interval)
    {
        BOOL saveImage = YES;
        
        if( [[printSelection selectedCell] tag] == 1)
        {
            if( ![[[fileList[ curMovieIndex] objectAtIndex: i] valueForKey: @"isKeyImage"] boolValue] && [[roiList[ curMovieIndex] objectAtIndex: i] count] == 0)
                saveImage = NO;
        }
        
        if( saveImage)
        {
            count++;
        }
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"autoAdjustPrintingFormat"])
    {
        NSInteger index = 0, tag, no_of_images = count;
        do
        {
            tag = [[[printLayout menu] itemAtIndex: index] tag];
            index++;
        }
        while( no_of_images > tag && index < [[printLayout menu] numberOfItems]);
        
        [printLayout selectItemWithTag: tag];
        ipp = [[printLayout selectedItem] tag];
        
        //		// optimize layout
        //		NSSize page = [[NSPrintInfo sharedPrintInfo] imageablePageBounds].size;
        //
        //		float optimizationFactor;
        //
        //		if( [[printFormat selectedCell] tag]) // original size
        //			optimizationFactor = (page.width*[imageView curDCM].pwidth) / (page.height*[imageView curDCM].pheight);
        //		else
        //			optimizationFactor = (page.width*imageView.frame.size.width) / (page.height*imageView.frame.size.height);
        //
        //		float new_columns = sqrt( ipp * optimizationFactor);
        //		float new_rows = ipp / new_columns;
        //
        //		int columns = (int) round( new_columns);
        //		int rows = (int) round( new_rows);
        //		ipp = columns * rows;
        //
        //		BOOL found = NO;
        //
        //		// Try to find it in the popup menu
        //		for( int i = 0 ; i < [[printLayout menu] numberOfItems] ; i++)
        //		{
        //			if( [[[printLayout menu] itemAtIndex: i] tag] == ipp && [[[[printLayout menu] itemAtIndex: i] title] rangeOfString: [NSString stringWithFormat:@"%dx%d"]].location != NSNotFound)
        //			{
        //				found = YES;
        //				[printLayout selectItemWithTag: ipp];
        //			}
        //		}
    }
    
    if( count % ipp == 0) [printPagesToPrint setStringValue: [NSString stringWithFormat: NSLocalizedString( @"%d pages", nil), count / ipp]];
    else [printPagesToPrint setStringValue: [NSString stringWithFormat: NSLocalizedString( @"%d pages", nil), 1 + (count / ipp)]];
}

- (void) restoreWindowsAfterPrint
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SquareWindowForPrinting"] && NSIsEmptyRect( windowFrameToRestore) == NO)
    {
        int AlwaysScaleToFit = [[NSUserDefaults standardUserDefaults] integerForKey: @"AlwaysScaleToFit"];
        [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"AlwaysScaleToFit"];
        
        [AppController resizeWindowWithAnimation: [self window] newSize: windowFrameToRestore];
        
        if( scaleFitToRestore) [imageView scaleToFit];
        
        [[NSUserDefaults standardUserDefaults] setInteger: AlwaysScaleToFit forKey: @"AlwaysScaleToFit"];
    }
    
    for( ViewerController *v in [ViewerController get2DViewers])
        [v.window orderFront: self];
    
    [self.window makeKeyAndOrderFront: self];
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation
                     success:(BOOL)success
                 contextInfo:(void*)info
{
    if (success)
    {
        
    }
    
    NSString	*tmpFolder = [NSString stringWithFormat:@"/tmp/print"];
    
    [[NSFileManager defaultManager] removeItemAtPath:tmpFolder error:NULL];
    
    [self restoreWindowsAfterPrint];
}

-(IBAction) endPrint:(id) sender
{
    [self checkEverythingLoaded];
    
    [printWindow orderOut:sender];
    [NSApp endSheet:printWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
        NSMutableDictionary	*settings = [NSMutableDictionary dictionary];
        
        //--------------------------Layout---------------------------------
        int columns = [[[[printLayout selectedItem] title] substringWithRange: NSMakeRange(0, 1)] intValue];
        int rows = [[[[printLayout selectedItem] title] substringWithRange: NSMakeRange(2, 1)] intValue];
        [settings setObject: [[printLayout selectedItem] title] forKey: @"layout"];
        
        //		NSSize page = [[NSPrintInfo sharedPrintInfo] imageablePageBounds].size;
        //		float optimizationFactor;
        //
        //		if( [[printFormat selectedCell] tag]) // original size
        //			optimizationFactor = (page.width*[imageView curDCM].pwidth) / (page.height*[imageView curDCM].pheight);
        //		else
        //			optimizationFactor = (page.width*imageView.frame.size.width) / (page.height*imageView.frame.size.height);
        //
        //		int ipp = [[printLayout selectedItem] tag];
        //		float new_columns = sqrt( ipp * optimizationFactor);
        //		float new_rows = ipp / new_columns;
        //
        //		int columns = (int) round( new_columns);
        //		int rows = (int) round( new_rows);
        
        [settings setObject: [NSNumber numberWithInt: columns] forKey: @"columns"];
        [settings setObject: [NSNumber numberWithInt: rows] forKey: @"rows"];
        
        //--------------------------Header---------------------------------
        if( [[printSettings cellWithTag: 2] state]) [settings setObject: [printText stringValue] forKey: @"comments"];
        if( [[printSettings cellWithTag: 0] state]) [settings setObject: @"YES" forKey: @"patientInfo"];
        if( [[printSettings cellWithTag: 1] state]) [settings setObject: @"YES" forKey: @"studyInfo"];
        
        //--------------------------Background color---------------------------------
        
        [settings setObject: @"YES" forKey: @"backgroundColor"];
        if( [[printSettings cellWithTag: 3] state])
        {
            [settings setObject: [NSNumber numberWithFloat: 1] forKey: @"backgroundColorR"];
            [settings setObject: [NSNumber numberWithFloat: 1] forKey: @"backgroundColorG"];
            [settings setObject: [NSNumber numberWithFloat: 1] forKey: @"backgroundColorB"];
        }
        else
        {
            [settings setObject: [NSNumber numberWithFloat: 0] forKey: @"backgroundColorR"];
            [settings setObject: [NSNumber numberWithFloat: 0] forKey: @"backgroundColorG"];
            [settings setObject: [NSNumber numberWithFloat: 0] forKey: @"backgroundColorB"];
        }
        
        //--------------------------Format ---------------------------------
        [settings setObject: [NSNumber numberWithInt: [[printFormat selectedCell] tag]] forKey: @"format"];
        
        //--------------------------Interval ---------------------------------
        [settings setObject: [NSNumber numberWithInt: [printInterval intValue]] forKey: @"interval"];
        
        
        [[NSUserDefaults standardUserDefaults] setObject: settings forKey: @"previousPrintSettings"];
        
        //--------------------------endpoints of the series to be printed---------------------------------
        int from;
        int to;
        int interval;
        
        switch( [[printSelection selectedCell] tag])
        {
                //current image
            case 0:
                if( [imageView flippedData]) from = [pixList[ curMovieIndex] count] - [imageView curImage] - 1;
                else from = [imageView curImage];
                
                to = from+1;
                interval = 1;
                break;
                
                
                //Only key images
            case 1:
                from = 0;
                to = [pixList [curMovieIndex] count];
                interval = 1;
                break;
                
                
                //Entire series, including
            case 2:
                if( [printFrom intValue] < [printTo intValue])
                {
                    from = [printFrom intValue]-1;
                    to = [printTo intValue];
                }
                else
                {
                    to = [printFrom intValue];
                    from = [printTo intValue]-1;
                }
                
                if( to == from) to = from+1;
                
                interval = [printInterval intValue];
                break;
        }
        
        //--------------------------Preparation images in /tmp/print---------------------------------
        
        NSMutableArray	*files = [NSMutableArray array];
        NSString	*tmpFolder = [NSString stringWithFormat:@"/tmp/print"];
        [[NSFileManager defaultManager] removeItemAtPath:tmpFolder error:NULL];
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpFolder withIntermediateDirectories:YES attributes:nil error:NULL];
        
        Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Preparing printing...", nil)];
        [splash setCancel: YES];
        [splash showWindow:self];
        [[splash progress] setMaxValue: (to - from) / interval];
        
        int currentImageIndex = [self imageIndex];
        
        /////// ****************
        
        float fontSizeCopy = [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"];
        float scaleFactor = 1.0;
        
        NSRect rf = [[self window] frame];
        BOOL m = [self magnetic];
        BOOL v = [self checkFrameSize];
        [OSIWindow setDontConstrainWindow: YES];
        [self setMagnetic : NO];
        [self setMatrixVisible: NO];
        
        float inc = (1 + ((columns - 1) * 0.35));
        if( inc > 2.0) inc = 2.0;
        
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"allowSmartCropping"];
        
        NSPoint o = [[[self window] screen] visibleFrame].origin;
        o.y += [[[self window] screen] visibleFrame].size.height;
        
        /////// ****************
        
        [OSIWindowController setDontEnterMagneticFunctions: YES];
        [OSIWindowController setDontEnterWindowDidChangeScreen: YES];
        
        int previousRows = [seriesView imageRows], previousColumns = [seriesView imageColumns];
        
        if( previousRows != 1 || previousColumns != 1)
            [self setImageRows: 1 columns: 1];
        
        BOOL copyFULL32BITPIPELINE = FULL32BITPIPELINE;
        BOOL whiteBackground = imageView.whiteBackground;
        
        if( [[settings objectForKey: @"backgroundColor"] boolValue] &&
           [[settings objectForKey: @"backgroundColorR"] floatValue] == 1 &&
           [[settings objectForKey: @"backgroundColorG"] floatValue] == 1 &&
           [[settings objectForKey: @"backgroundColorB"] floatValue] == 1)
            imageView.whiteBackground = YES;
        
        for( int i = from; i < to; i += interval)
        {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            BOOL saveImage = YES;
            
            if( [[printSelection selectedCell] tag] == 1) //key image
            {
                NSManagedObject	*image;
                NSUInteger index = 0;
                
                if( [imageView flippedData]) index = [[self fileList] count] -1 -i;
                else index = i;
                
                image = [[self fileList] objectAtIndex: index];
                
                if( ![[image valueForKey: @"isKeyImage"] boolValue] && [[self.roiList objectAtIndex: index] count] == 0) saveImage = NO;
            }
            
            if( saveImage)
            {
                [self setImageIndex: i];
                
                BOOL windowSizeChanged = NO;
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"printAt100%Minimum"] && [self scaleValue] < 1.0)
                {
                    scaleFactor = 1. / [self scaleValue];
                    
                    int MAXWindowSize = [[NSUserDefaults standardUserDefaults] integerForKey: @"MAXWindowSize"];
                    
                    int noFactor = (columns * rows) / 2;
                    if( noFactor < 1) noFactor = 1;
                    if( noFactor > 6) noFactor = 6;
                    
                    int cMAXWindowSize = MAXWindowSize / noFactor;
                    
                    if( rf.size.width * scaleFactor > cMAXWindowSize)
                        scaleFactor = cMAXWindowSize / rf.size.width;
                    
                    if( rf.size.height * scaleFactor > cMAXWindowSize)
                        scaleFactor = cMAXWindowSize / rf.size.height;
                    
                    if( scaleFactor <= 1.0)
                        scaleFactor = 1.0;
                    else
                    {
                        windowSizeChanged = YES;
                        [[self window] setFrame: NSMakeRect( o.x, o.y, rf.size.width * scaleFactor, rf.size.height * scaleFactor) display: YES];
                    }
                }
                else scaleFactor = 1.0;
                
                if( fontSizeCopy * inc * scaleFactor * 1.2 != [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"])
                {
                    [[NSUserDefaults standardUserDefaults] setFloat: fontSizeCopy * inc * scaleFactor * 1.2 forKey: @"FONTSIZE"];
                    [NSFont resetFont: 0];
                    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixGLFontChangeNotification object: self];
                }
                
                NSImage *im = [imageView nsimage: [[printFormat selectedCell] tag]];
                
                if( windowSizeChanged)
                {
                    [[NSUserDefaults standardUserDefaults] setFloat: fontSizeCopy forKey: @"FONTSIZE"];
                    [NSFont resetFont: 0];
                    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixGLFontChangeNotification object: self];
                    [[self window] setFrame: NSMakeRect( o.x, o.y, rf.size.width, rf.size.height) display: YES];
                }
                
                if( columns * rows > 4)
                    im = [DCMPix resizeIfNecessary: im dcmPix: [imageView curDCM]];
                
                NSData *bitmapData = [im  TIFFRepresentation];
                
                [files addObject: [tmpFolder stringByAppendingFormat:@"/%d", i]];
                [bitmapData writeToFile: [files lastObject] atomically:YES];
            }
            
            [splash incrementBy: 1];
            
            [pool release];
            
            if( [splash aborted])
                break;
        }
        
        imageView.whiteBackground = whiteBackground;
        FULL32BITPIPELINE = copyFULL32BITPIPELINE;
        
        /////// ****************
        
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"allowSmartCropping"];
        
        if( fontSizeCopy != [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"])
        {
            [[NSUserDefaults standardUserDefaults] setFloat: fontSizeCopy forKey: @"FONTSIZE"];
            [NSFont resetFont: 0];
            [[NSNotificationCenter defaultCenter] postNotificationName:OsirixGLFontChangeNotification object: self];
        }
        
        [self setMagnetic : m];
        [[self window] setFrame: rf display: YES];
        [self setMatrixVisible: v];
        
        [self setImageIndex: currentImageIndex];
        
        if( previousRows != 1 || previousColumns != 1)
            [self setImageRows: previousRows columns: previousColumns];
        
        [OSIWindowController setDontEnterMagneticFunctions: NO];
        [OSIWindowController setDontEnterWindowDidChangeScreen: NO];
        /////// ****************
        
        // Go back to initial frame
        [self setImageIndex: currentImageIndex];
        [[self window] update];
        [imageView sendSyncMessage: 0];
        
        [self adjustSlider];
        
        [splash close];
        [splash autorelease];
        
        // Start the actual print operation if there is something to print at all.
        if( [files count])
        {
            printView *pV = [[[printView alloc] initWithViewer: self
                                                      settings: settings
                                                         files: files
                                                     printInfo: [NSPrintInfo sharedPrintInfo]] autorelease];
            
            NSPrintOperation * printOperation = [NSPrintOperation printOperationWithView: pV];
            
            [printOperation setCanSpawnSeparateThread: YES];
            
            [printOperation runOperationModalForWindow:[self window]
                                              delegate:self
                                        didRunSelector: @selector(printOperationDidRun:success:contextInfo:)
                                           contextInfo:nil];
        }
    }
    else
        [self restoreWindowsAfterPrint];
}

- (IBAction) printSlider:(id) sender
{
    if( [[printSelection selectedCell] tag] == 2)
    {
        [printFromText takeIntValueFrom: printFrom];
        [printToText takeIntValueFrom: printTo];
        
        if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
        else [imageView setIndex:  [sender intValue]-1];
        
        [imageView sendSyncMessage: 0];
        
        [self adjustSlider];
    }
    
    [self setPagesToPrint: self];
}

- (void) print:(id) sender
{
    NSDictionary *p = [[NSUserDefaults standardUserDefaults] objectForKey: @"previousPrintSettings"];
    
    if( p)
    {
        [printLayout selectItemWithTitle: [p valueForKey: @"layout"]];
        
        if( [p valueForKey: @"comments"]) [[printSettings cellWithTag: 2] setState: NSOnState];
        else [[printSettings cellWithTag: 2] setState: NSOffState];
        
        if( [p valueForKey: @"patientInfo"]) [[printSettings cellWithTag: 0] setState: NSOnState];
        else [[printSettings cellWithTag: 0] setState: NSOffState];
        
        if( [p valueForKey: @"studyInfo"]) [[printSettings cellWithTag: 1] setState: NSOnState];
        else [[printSettings cellWithTag: 1] setState: NSOffState];
        
        if( imageView.whiteBackground || ([[p valueForKey: @"backgroundColor"] boolValue] &&
                                          [[p valueForKey: @"backgroundColorR"] floatValue] == 1 &&
                                          [[p valueForKey: @"backgroundColorG"] floatValue] == 1 &&
                                          [[p valueForKey: @"backgroundColorB"] floatValue] == 1))
            [[printSettings cellWithTag: 3] setState: NSOnState];
        else
            [[printSettings cellWithTag: 3] setState: NSOffState];
        
        [printFormat selectCellWithTag: [[p valueForKey: @"format"] intValue]];
        [printInterval setIntValue: [[p valueForKey: @"interval"] intValue]];
        
        if( [p valueForKey: @"comments"]) [printText setStringValue: [p valueForKey: @"comments"]];
    }
    
    // ****
    
    [printFrom setMaxValue: [pixList[ curMovieIndex] count]];
    [printTo setMaxValue: [pixList[ curMovieIndex] count]];
    
    [printFrom setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
    [printTo setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
    
    [printFrom setIntValue: 1];
    [printTo setIntValue: [pixList[ curMovieIndex] count]];
    
    [printToText setIntValue: [printTo intValue]];
    [printFromText setIntValue: [printFrom intValue]];
    [printIntervalText setIntValue: [printInterval intValue]];
    
    [self setCurrentdcmExport: printSelection];
    
    [self setPagesToPrint: self];
    
    if( [pixList[ curMovieIndex] count] == 1)
    {
        [printFrom setEnabled: NO];
        [printTo setEnabled: NO];
        [printInterval setEnabled: NO];
    }
    else
    {
        [printFrom setEnabled: YES];
        [printTo setEnabled: YES];
        [printInterval setEnabled: YES];
    }
    
    windowFrameToRestore = NSMakeRect(0, 0, 0, 0);
    scaleFitToRestore = imageView.isScaledFit;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SquareWindowForPrinting"])
    {
        int AlwaysScaleToFit = [[NSUserDefaults standardUserDefaults] integerForKey: @"AlwaysScaleToFit"];
        [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"AlwaysScaleToFit"];
        
        windowFrameToRestore = [[self window] frame];
        NSRect newFrame = [AppController usefullRectForScreen: self.window.screen];
        
        if( newFrame.size.width < newFrame.size.height) newFrame.size.height = newFrame.size.width;
        else newFrame.size.width = newFrame.size.height;
        
        [AppController resizeWindowWithAnimation: [self window] newSize: newFrame];
        if( scaleFitToRestore) [imageView scaleToFit];
        
        [[NSUserDefaults standardUserDefaults] setInteger: AlwaysScaleToFit forKey: @"AlwaysScaleToFit"];
    }
    
    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    {
        if( v != self)
            [v.window orderOut: self];
    }
    
    [NSApp beginSheet: printWindow modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

#ifndef OSIRIX_LIGHT
- (void) printDICOM:(id) sender
{
    [self checkEverythingLoaded];
    
    [[[AYDicomPrintWindowController alloc] init] autorelease];
}
#endif

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
    NSImage		*im = nil;
    BOOL		export = YES;
    int			curSample = [cur intValue] + qt_from;
    
    if( qt_dimension == 3)
    {
        NSManagedObject	*image;
        
        if( [imageView flippedData]) image = [[self fileList] objectAtIndex: (long)[[self fileList] count] -1 -curSample];
        else image = [[self fileList] objectAtIndex: curSample];
        export = [[image valueForKey:@"isKeyImage"] boolValue];
    }
    
    current_qt_interval--;
    if( current_qt_interval > 0) export = NO;
    else
    {
        current_qt_interval = qt_interval;
    }
    
    if( export)
    {
        switch( qt_dimension)
        {
            case 1:
            case 3:
                if( [imageView flippedData]) [imageView setIndex: [self getNumberOfImages] - 1 -curSample];
                else [imageView setIndex:curSample];
                [imageView sendSyncMessage: 0];
                [[seriesView imageViews] makeObjectsPerformSelector:@selector(display)];
                break;
                
            case 0:
                [[self blendingSlider] setIntValue: -256 + ((curSample * 512) / ([max intValue]-1))];
                [self blendingSlider:[self blendingSlider]];
                [[seriesView imageViews] makeObjectsPerformSelector:@selector(display)];
                break;
                
            case 2:
                [[self moviePosSlider] setIntValue: curSample];
                [self moviePosSliderAction:[self moviePosSlider]];
                [[seriesView imageViews] makeObjectsPerformSelector:@selector(display)];
                break;
        }
        
        im = [imageView nsimage: NO allViewers: qt_allViewers];
    }
    
    return im;
}

-(void) exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval
{
    [self exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval :NO];
}

-(void) exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval :(BOOL) allViewers
{
    [self exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval :allViewers mode: nil];
}

-(void) exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval :(BOOL) allViewers mode:(NSString*) mode
{
    QuicktimeExport *mov;
    
    qt_dimension = dimension;
    qt_allViewers = allViewers;
    
    switch( qt_dimension)
    {
        case 1:
            qt_to = to;
            qt_from = from;
            qt_interval = interval;
            break;
            
        case 3:
            qt_to = [self getNumberOfImages];
            qt_from = 0;
            qt_interval = 1;
            break;
            
        case 0:
            qt_to = 20;
            qt_from = 0;
            qt_interval = 1;
            break;
            
        case 2:
            qt_to = [self maxMovieIndex];
            qt_from = 0;
            qt_interval = 1;
            break;
    }
    
    current_qt_interval = qt_interval;
    
    mov = [[[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :qt_to - qt_from] autorelease];
    
    NSInteger fps = 0;
    switch( qt_dimension)
    {
        default:
        case 1:
        case 3:
            if ([self frameRate] > 0)
                fps = [self frameRate];
            break;
            
        case 0:
            // fps = 10; // the default value is set in [QuicktimeExport createMovieQTKit::::::::::] when fps is 0
            break;
            
        case 2:
            if ([self frame4DRate] > 0)
                fps = [self frame4DRate];
            break;
    }
    
    BOOL produceImageFiles = NO;
    
    if( [mode isEqualToString:@"export2iphoto"]) produceImageFiles = YES;
    else produceImageFiles = NO;
    
    NSString *path = [mov createMovieQTKit: NO  :produceImageFiles :[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"] :fps];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: path] == NO && path != nil)
        NSRunAlertPanel(NSLocalizedString(@"Export", nil), NSLocalizedString(@"Failed to export this file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
    {
        [[NSWorkspace sharedWorkspace] openFile: path withApplication: nil andDeactivate: YES];
        [NSThread sleepForTimeInterval: 1];
    }
}

-(IBAction) endQuicktime:(id) sender
{
    [quicktimeWindow orderOut:sender];
    
    [NSApp endSheet:quicktimeWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
        long from, to, interval;
        
        from = [quicktimeFrom intValue]-1;
        to = [quicktimeTo intValue];
        interval = [quicktimeInterval intValue];
        
        if( from >= to)
        {
            to = [quicktimeFrom intValue];
            from = [quicktimeTo intValue]-1;
        }
        
        if( [[quicktimeMode selectedCell] tag] == 3)	// key images
        {
            to = [pixList[ curMovieIndex] count];
            from = 0;
            interval = 1;
        }
        
        [self exportQuicktimeIn: [[quicktimeMode selectedCell] tag] :from :to :interval :[quicktimeAllViewers state]];
    }
    
    [self adjustSlider];
}

- (void) exportQuicktimeSetNumber:(id) sender
{
    int no;
    
    no = abs( [quicktimeFrom intValue] - [quicktimeTo intValue]);
    no ++;
    no /= [quicktimeInterval intValue];
    
    [quicktimeNumber setStringValue: [NSString stringWithFormat: NSLocalizedString( @"%d images", nil), no]];
}

- (IBAction) exportQuicktimeSlider:(id) sender
{
    if( [sender isKindOfClass: [NSSlider class]])
    {
        [quicktimeFromText takeIntValueFrom: quicktimeFrom];
        [quicktimeToText takeIntValueFrom: quicktimeTo];
        [quicktimeIntervalText takeIntValueFrom: quicktimeInterval];
    }
    else
    {
        [quicktimeFrom takeIntValueFrom: quicktimeFromText];
        [quicktimeTo takeIntValueFrom: quicktimeToText];
        [quicktimeInterval takeIntValueFrom: quicktimeIntervalText];
    }
    
    if( [sender tag] != 3)	// 3 = interval
    {
        if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
        else [imageView setIndex:  [sender intValue]-1];
    }
    
    [imageView sendSyncMessage: 0];
    
    [self adjustSlider];
    
    [self exportQuicktimeSetNumber: self];
}

- (void) exportQuicktime:(id) sender
{
    [quicktimeAllViewers setState: NSOffState];
    
    if( [[[imageView seriesObj] valueForKey: @"keyImages"] count]) [[quicktimeMode cellWithTag: 3] setEnabled: YES];
    else [[quicktimeMode cellWithTag: 3] setEnabled: NO];
    
    if( [[ViewerController getDisplayed2DViewers] count] > 1) [quicktimeAllViewers setEnabled: YES];
    else [quicktimeAllViewers setEnabled: NO];
    
    if( [sliderFusion isEnabled])
        [quicktimeInterval setIntValue: [sliderFusion intValue]];
    
    [quicktimeFrom setMaxValue: [pixList[ curMovieIndex] count]];
    [quicktimeTo setMaxValue: [pixList[ curMovieIndex] count]];
    
    [quicktimeFrom setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
    [quicktimeTo setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
    
    //	if( [pixList[ curMovieIndex] count] < 20)
    //	{
    [quicktimeFrom setIntValue: 1];
    [quicktimeTo setIntValue: [pixList[ curMovieIndex] count]];
    //	}
    //	else
    //	{
    //		if( [imageView flippedData]) [quicktimeFrom setIntValue: [pixList[ curMovieIndex] count] - [imageView curImage]];
    //		else [quicktimeFrom setIntValue: 1+ [imageView curImage]];
    //		[quicktimeTo setIntValue: [pixList[ curMovieIndex] count]];
    //	}
    
    [quicktimeToText setIntValue: [quicktimeTo intValue]];
    [quicktimeFromText setIntValue: [quicktimeFrom intValue]];
    [quicktimeIntervalText setIntValue: [quicktimeInterval intValue]];
    
    [self setCurrentdcmExport: quicktimeMode];
    
    if( blendingController)
    {
        [[quicktimeMode cellWithTag: 0] setEnabled:YES];
    }
    else [[quicktimeMode cellWithTag: 0] setEnabled:NO];
    
    if( maxMovieIndex > 1)
    {
        [[quicktimeMode cellWithTag: 2] setEnabled:YES];
    }
    else [[quicktimeMode cellWithTag: 2] setEnabled:NO];
    
    if( [[quicktimeMode selectedCell] isEnabled] == NO) [quicktimeMode selectCellWithTag: 1];
    
    [self exportQuicktimeSetNumber: self];
    
    [NSApp beginSheet: quicktimeWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

#ifndef OSIRIX_LIGHT
- (NSDictionary*) exportDICOMFileInt:(int) screenCapture
{
    return [self exportDICOMFileInt:screenCapture withName:[dcmSeriesName stringValue]];
}

- (NSDictionary*) exportDICOMFileInt:(int)screenCapture withName:(NSString*)name;
{
    return [self exportDICOMFileInt:(int)screenCapture withName:(NSString*)name allViewers: NO];
}

- (NSDictionary*) exportDICOMFileInt:(int)screenCapture withName:(NSString*)name allViewers: (BOOL) allViewers
{
    NSArray *viewers = [ViewerController getDisplayed2DViewers];
    long annotCopy,clutBarsCopy;
    BOOL modalityAsSource = NO;
    long width, height, spp, bpp, i, x;
    float cwl, cww;
    float o[ 9];
    BOOL isSigned;
    int offset;
    
    if( screenCapture || allViewers)
    {
        annotCopy		= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
        clutBarsCopy	= [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"keepCLUTBarsForSecondaryCapture"])
            [DCMView setCLUTBARS: clutBarsCopy ANNOTATIONS: annotGraphics];
        else
            [DCMView setCLUTBARS: barHide ANNOTATIONS: annotGraphics];
    }
    
    BOOL force8bits = YES;
    
    switch( screenCapture)
    {
        case 0: /*memory data*/		force8bits = NO;	modalityAsSource = YES;		break; // 16-bit
        case 1: /*screen capture*/	force8bits = YES;	break;
        case 2: /*screen capture*/	force8bits = NO;	modalityAsSource = YES;		break; // 16-bit
    }
    
    unsigned char *data = nil;
    
    float imOrigin[ 3], imSpacing[ 2];
    
    if( allViewers)
    {
        //order windows from left-top to right-bottom
        NSMutableArray	*cWindows = [NSMutableArray arrayWithArray: viewers];
        NSMutableArray	*cResult = [NSMutableArray array];
        int count = [cWindows count];
        for( i = 0; i < count; i++)
        {
            int index = 0;
            float minY = [[[cWindows objectAtIndex: 0] window] frame].origin.y;
            
            for( x = 0; x < [cWindows count]; x++)
            {
                if( [[[cWindows objectAtIndex: x] window] frame].origin.y > minY)
                {
                    minY  = [[[cWindows objectAtIndex: x] window] frame].origin.y;
                    index = x;
                }
            }
            
            float minX = [[[cWindows objectAtIndex: index] window] frame].origin.x;
            
            for( x = 0; x < [cWindows count]; x++)
            {
                if( [[[cWindows objectAtIndex: x] window] frame].origin.x < minX && [[[cWindows objectAtIndex: x] window] frame].origin.y >= minY)
                {
                    minX = [[[cWindows objectAtIndex: x] window] frame].origin.x;
                    index = x;
                }
            }
            
            [cResult addObject: [cWindows objectAtIndex: index]];
            [cWindows removeObjectAtIndex: index];
        }
        
        viewers = cResult;
        
        NSMutableArray	*viewsRect = [NSMutableArray array];
        
        // Compute the enclosing rect
        for( ViewerController *v in viewers)
        {
            NSRect	bounds = [[v imageView] bounds];
            NSPoint origin = [[v imageView] convertPoint: bounds.origin toView: nil];
            NSRect r = {origin, NSZeroSize};
            bounds.origin = [[v window] convertRectToScreen:r].origin;
            
            bounds = NSIntegralRect(bounds);
            
            bounds.origin.x *= v.window.backingScaleFactor;
            bounds.origin.y *= v.window.backingScaleFactor;
            
            bounds.size.width *= v.window.backingScaleFactor;
            bounds.size.height *= v.window.backingScaleFactor;
            
            [viewsRect addObject: [NSValue valueWithRect: bounds]];
        }
        
        data = [imageView getRawPixelsWidth: &width
                                     height: &height
                                        spp: &spp
                                        bpp: &bpp
                              screenCapture: screenCapture
                                 force8bits: force8bits
                            removeGraphical: YES
                               squarePixels: YES
                                   allTiles: [[NSUserDefaults standardUserDefaults] boolForKey:@"includeAllTiledViews"]
                         allowSmartCropping: NO
                                     origin: imOrigin
                                    spacing: imSpacing
                                     offset: &offset
                                   isSigned: &isSigned
                                      views: [viewers valueForKey: @"imageView"]
                                  viewsRect: viewsRect];
    }
    else data = [imageView getRawPixelsWidth: &width
                                      height: &height
                                         spp: &spp
                                         bpp: &bpp
                               screenCapture: screenCapture
                                  force8bits: force8bits
                             removeGraphical: YES
                                squarePixels: YES
                                    allTiles: [[NSUserDefaults standardUserDefaults] boolForKey:@"includeAllTiledViews"]
                          allowSmartCropping: YES
                                      origin: imOrigin
                                     spacing: imSpacing
                                      offset: &offset
                                    isSigned: &isSigned];
    
    NSString *f = nil;
    
    if( data)
    {
        if( exportDCM == nil) exportDCM = [[DICOMExport alloc] init];
        
        [exportDCM setSourceFile: [[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] valueForKey:@"completePath"]];
        
        if( [[exportDCM seriesDescription] isEqualToString: name] == NO)
        {
            [exportDCM setSeriesDescription: name];
            [exportDCM setSeriesNumber: 8200 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute]];
        }
        
        [imageView getWLWW:&cwl :&cww];
        
        if( [[self modality] isEqualToString:@"PT"])
        {
            float slope = [[imageView curDCM] appliedFactorPET2SUV] * [[imageView curDCM] slope];
            [exportDCM setSlope: slope];
        }
        
        [exportDCM setDefaultWWWL: cww :cwl];
        
        float thickness, location;
        
        [imageView getThickSlabThickness:&thickness location:&location];
        
        if( allViewers == NO)
        {
            [exportDCM setSliceThickness: thickness];
            [exportDCM setSlicePosition: location];
            
            [imageView orientationCorrectedToView: o];
            //		if( screenCapture) [imageView orientationCorrectedToView: o];	// <- Because we do screen capture !!!!! We need to apply the rotation of the image
            //		else [curPix orientation: o];
            
            [exportDCM setOrientation: o];
            
            [exportDCM setPosition: imOrigin];
        }
        
        [exportDCM setPixelSpacing: imSpacing[ 0] :imSpacing[ 1]];
        
        [exportDCM setPixelData: data samplesPerPixel:spp bitsPerSample:bpp width: width height: height];
        [exportDCM setSigned: isSigned];
        [exportDCM setOffset: offset];
        [exportDCM setModalityAsSource: modalityAsSource];
        
        f = [exportDCM writeDCMFile: nil withExportDCM: [imageView dcmExportPlugin]];
        if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
        
        free( data);
    }
    else NSLog( @"No Data");
    
    if( screenCapture || allViewers)
    {
        [DCMView setCLUTBARS: clutBarsCopy ANNOTATIONS: annotCopy];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil];
}
#endif

-(id) findPlayStopButton
{
    
    NSArray *items = [toolbar items];
    
    for( id loopItem in items)
    {
        if( [[loopItem itemIdentifier] isEqualToString:PlayToolbarItemIdentifier])
        {
            return loopItem;
        }
    }
    return nil;
}

#ifndef OSIRIX_LIGHT
-(IBAction) exportAllImages:(NSString*) seriesName
{
    NSMutableArray *producedFiles = [NSMutableArray array];
    
    if (exportDCM == nil) exportDCM = [[DICOMExport alloc] init];
    [exportDCM setSeriesNumber:5300 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute]];	//Try to create a unique series number... Do you have a better idea??
    [exportDCM setSeriesDescription: seriesName];
    
    NSLog( @"export start");
    
    NSString *savedSeriesName = [dcmSeriesName stringValue];
    
    [dcmSeriesName setStringValue: seriesName];
    
    for( int i = 0 ; i < [pixList[ curMovieIndex] count]; i ++)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        if( [imageView flippedData]) [imageView setIndex: (long)[pixList[ curMovieIndex] count] -1 -i];
        else [imageView setIndex:i];
        
        [imageView sendSyncMessage: 0];
        
        NSDictionary* s = [self exportDICOMFileInt: 1 withName: [dcmSeriesName stringValue] allViewers: NO];
        if( s) [producedFiles addObject: s];
        
        [pool release];
    }
    
    NSLog( @"export end");
    
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
    }
    
    [dcmSeriesName setStringValue: savedSeriesName];
}

-(IBAction) endExportDICOMFileSettings:(id) sender
{
    int i, curImage;
    
    [dcmExportWindow makeFirstResponder: nil];	// To force nstextfield validation.
    [dcmExportWindow orderOut:sender];
    
    [NSApp endSheet:dcmExportWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
        NSMutableArray *producedFiles = [NSMutableArray array];
        
        if( [[dcmSelection selectedCell] tag] == 0)
        {
            NSDictionary* s = [self exportDICOMFileInt:[[dcmFormat selectedCell] tag] withName:[dcmSeriesName stringValue] allViewers: [dcmAllViewers state]];
            
            if( [s valueForKey: @"file"]) [producedFiles addObject: s];
        }
        else if( [[dcmSelection selectedCell] tag] == 3) // 4th Dimension
        {
            for (i = 0 ; i < maxMovieIndex; i ++)
            {
                [self setMovieIndex: i];
                
                NSDictionary* s = [self exportDICOMFileInt:[[dcmFormat selectedCell] tag] withName:[dcmSeriesName stringValue] allViewers: [dcmAllViewers state]];
                if( [s valueForKey: @"file"]) [producedFiles addObject: s];
            }
        }
        else
        {
            int from, to, interval;
            
            from = [dcmFrom intValue]-1;
            to = [dcmTo intValue];
            interval = [dcmInterval intValue];
            
            if( to < from)
            {
                to = [dcmFrom intValue]-1;
                from = [dcmTo intValue];
            }
            
            if( [[dcmSelection selectedCell] tag] == 2)
            {
                to = [pixList[ curMovieIndex] count];
                from = 0;
                interval = 1;
            }
            
            Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Creating a DICOM series", nil)];
            [splash showWindow:self];
            [[splash progress] setMaxValue: (to - from) / interval];
            [splash setCancel: YES];
            
            curImage = [imageView curImage];
            
            if (exportDCM == nil) exportDCM = [[DICOMExport alloc] init];
            [exportDCM setSeriesNumber:5300 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute]];	//Try to create a unique series number... Do you have a better idea??
            [exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
            
            NSLog( @"export start");
            
            for (i = from ; i < to; i += interval)
            {
                NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
                
                BOOL	export = YES;
                
                if( [[dcmSelection selectedCell] tag] == 2)	// Only ROIs & key images
                {
                    NSManagedObject	*image;
                    NSUInteger index = 0;
                    
                    if( [imageView flippedData]) index = [[self fileList] count] -1 -i;
                    else index = i;
                    
                    image = [[self fileList] objectAtIndex: index];
                    
                    export = [[image valueForKey:@"isKeyImage"] boolValue];
                    
                    if( export == NO)
                    {
                        if( [[self.roiList objectAtIndex: index] count] > 0)
                            export = YES;
                    }
                }
                
                if( export)
                {
                    if( [imageView flippedData]) [imageView setIndex: (long)[pixList[ curMovieIndex] count] -1 -i];
                    else [imageView setIndex:i];
                    
                    [imageView sendSyncMessage: 0];
                    [self adjustSlider];
                    
                    NSDictionary* s = [self exportDICOMFileInt:[[dcmFormat selectedCell] tag] withName:[dcmSeriesName stringValue] allViewers: [dcmAllViewers state]];
                    if( [s valueForKey: @"file"]) [producedFiles addObject: s];
                }
                
                [splash incrementBy: 1];
                
                if( [splash aborted])
                    i = to;
                
                [pool release];
            }
            
            NSLog( @"export end");
            
            // Go back to initial frame
            [imageView setIndex: curImage];
            [imageView sendSyncMessage: 0];
            [self adjustSlider];
            
            [splash close];
            [splash autorelease];
        }
        
        NSArray *viewers = [ViewerController getDisplayed2DViewers];
        
        for( i = 0; i < [viewers count]; i++)
            [[[viewers objectAtIndex: i] imageView] setNeedsDisplay: YES];
        
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
                for( DicomImage *im in objects)
                    [im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
            }
        }
    }
    
    [self adjustSlider];
}
#endif

-(void) exportRAW:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
    
    [panel setCanSelectHiddenExtension:NO];
    
    panel.nameFieldStringValue = [[fileList[ curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.name"];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        for(int i = 0; i < [fileList[ curMovieIndex] count]; i++)
        {
            DCMPix  *pix = [pixList[ curMovieIndex] objectAtIndex:i];
            
            vImage_Buffer dst16, srcf;
            
            dst16.height = srcf.height = [pix pheight];
            dst16.width = srcf.width = [pix pwidth];
            dst16.rowBytes = [pix pwidth]*2;
            srcf.rowBytes = [pix pwidth]*sizeof(float);
            
            dst16.data = malloc([pix pwidth]*[pix pheight]*2L);
            srcf.data = [pix fImage];
            
            vImageConvert_FTo16S( &srcf, &dst16, 0, 1.0, 0);
            
            NSData *data = [NSData dataWithBytesNoCopy:dst16.data length:[pix pwidth]*[pix pheight]*2 freeWhenDone:NO];
            
            [data writeToFile:[NSString stringWithFormat:@"%@.%d", panel.URL.path, i] atomically:NO];
            
            free( dst16.data);
        }
    }];
}

- (IBAction) setCurrentdcmExport:(id) sender
{
    if( [[sender selectedCell] tag] == 1) [self checkView: dcmBox :YES];
    else [self checkView: dcmBox :NO];
    
    if( [[sender selectedCell] tag] == 1) [self checkView: quicktimeBox :YES];
    else [self checkView: quicktimeBox :NO];
    
    if( [[sender selectedCell] tag] == 2) [self checkView: printBox :YES];
    else [self checkView: printBox :NO];
    
    if( sender == printSelection) [self setPagesToPrint: self];
}

- (IBAction) exportDICOMAllViewers:(id) sender
{
    if( [dcmAllViewers state] == NSOnState)
    {
        [dcmFormat selectCellWithTag: 1];	// Always screen capture
        [dcmFormat setEnabled: NO];
    }
    else [dcmFormat setEnabled: YES];
}

- (void) exportDICOMSetNumber:(id) sender
{
    int no;
    
    no = abs( [dcmFrom intValue] - [dcmTo intValue]);
    no ++;
    no /= [dcmInterval intValue];
    
    [dcmNumber setStringValue: [NSString stringWithFormat: NSLocalizedString( @"%d images", nil), no]];
}

- (IBAction) exportDICOMSlider:(id) sender
{
    if( [[dcmSelection selectedCell] tag] == 1)
    {
        if( [sender isKindOfClass: [NSSlider class]])
        {
            [dcmFromText takeIntValueFrom: dcmFrom];
            [dcmToText takeIntValueFrom: dcmTo];
            [dcmIntervalText takeIntValueFrom: dcmInterval];
        }
        else
        {
            [dcmFrom takeIntValueFrom: dcmFromText];
            [dcmTo takeIntValueFrom: dcmToText];
            [dcmInterval takeIntValueFrom: dcmIntervalText];
        }
        
        if( [sender tag] != 3)
        {
            if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
            else [imageView setIndex:  [sender intValue]-1];
        }
        
        [imageView sendSyncMessage: 0];
        
        [self adjustSlider];
        
        [self exportDICOMSetNumber: self];
    }
}

#ifndef OSIRIX_LIGHT
- (void) exportDICOMFile:(id) sender
{
    [dcmFormat setEnabled: YES];
    [dcmAllViewers setState: NSOffState];
    
    if( [[imageView curDCM] isRGB] || [self subtractionActivated])
    {
        if( [dcmFormat selectedTag] == 2)
            [dcmFormat selectCellWithTag: 1];
        [[dcmFormat cellWithTag: 2] setEnabled: NO];
        
        if( [self subtractionActivated])
        {
            if( [dcmFormat selectedTag] == 0)
                [dcmFormat selectCellWithTag: 1];
            
            [[dcmFormat cellWithTag: 0] setEnabled: NO];
        }
    }
    else
    {
        [[dcmFormat cellWithTag: 2] setEnabled: YES];
        [[dcmFormat cellWithTag: 0] setEnabled: YES];
        
        if( [[imageView curRoiList] count] > 0)
            [dcmFormat selectCellWithTag: 1];
        else if( [dcmFormat selectedTag] == 1)
            [dcmFormat selectCellWithTag: 2];
    }
    
    if( maxMovieIndex > 1) [[dcmSelection cellWithTag: 3] setEnabled: YES];
    else [[dcmSelection cellWithTag: 3] setEnabled: NO];
    
    if( [[[imageView seriesObj] valueForKey: @"keyImages"] count]) [[dcmSelection cellWithTag: 2] setEnabled: YES];
    else [[dcmSelection cellWithTag: 2] setEnabled: NO];
    
    if( [[dcmSelection cellWithTag: 3] isEnabled] == NO && [dcmSelection selectedTag] == 3)
        [dcmSelection selectCellWithTag: 0];
    
    if( blendingController)
        [dcmFormat selectCellWithTag: 1];
    
    if( [[ViewerController getDisplayed2DViewers] count] > 1) [dcmAllViewers setEnabled: YES];
    else [dcmAllViewers setEnabled: NO];
    
    if( [sliderFusion isEnabled])
        [dcmInterval setIntValue: [sliderFusion intValue]];
    
    [dcmFrom setMaxValue: [pixList[ curMovieIndex] count]];
    [dcmTo setMaxValue: [pixList[ curMovieIndex] count]];
    
    [dcmFrom setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
    [dcmTo setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
    
    //	if( [pixList[ curMovieIndex] count] < 20)
    //	{
    [dcmFrom setIntValue: 1];
    [dcmTo setIntValue: [pixList[ curMovieIndex] count]];
    //	}
    //	else
    //	{
    //		if( [imageView flippedData]) [dcmFrom setIntValue: [pixList[ curMovieIndex] count] - [imageView curImage]];
    //		else [dcmFrom setIntValue: 1+ [imageView curImage]];
    //		[dcmTo setIntValue: [pixList[ curMovieIndex] count]];
    //	}
    
    [dcmToText setIntValue: [dcmTo intValue]];
    [dcmFromText setIntValue: [dcmFrom intValue]];
    [dcmIntervalText setIntValue: [dcmInterval intValue]];
    
    DCMExportPlugin *exportPlugin = [imageView dcmExportPlugin];
    if (exportPlugin && [exportPlugin seriesName])
        [dcmSeriesName setStringValue:[exportPlugin seriesName]];
    
    [self setCurrentdcmExport: dcmSelection];
    [self exportDICOMSetNumber: self];
    
    [NSApp beginSheet: dcmExportWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}
#endif

- (IBAction) export2PACS:(id) sender
{
    BOOL			all = NO;
    long			i,x;
    NSMutableArray  *files2Send;
    
    for( i = 0; i < maxMovieIndex; i++)
        [self saveROI: i];
    
    if( [pixList[ curMovieIndex] count] > 1)
    {
        int result = NSRunInformationalAlertPanel( NSLocalizedString(@"Send to DICOM node", nil), NSLocalizedString(@"Should I send only current image or all images of current series?", nil), NSLocalizedString(@"Current", nil), NSLocalizedString(@"All", nil), NSLocalizedString(@"Cancel", nil));
        
        if( result == NSAlertOtherReturn) return;
        
        if( result == NSAlertDefaultReturn) all = NO;
        else all = YES;
    }
    
    if( all)
    {
        files2Send = [NSMutableArray array];
        
        for( x = 0; x < maxMovieIndex; x++)
        {
            for( i = 0; i < [fileList[ x] count]; i++)
            {
                if( [files2Send containsObject:[fileList[ x] objectAtIndex: i]] == NO)
                    [files2Send addObject: [fileList[ x] objectAtIndex: i]];
            }
        }
    }
    else
    {
        files2Send = [NSMutableArray array];
        
        [files2Send addObject: [fileList[ curMovieIndex] objectAtIndex:[imageView curImage]]];
    }
    
    [[BrowserController currentBrowser] selectServer: files2Send];
}

- (void) exportImage:(id) sender
{
    [imageView flagsChanged];	// If shift key was pressed, hiding the ROI data	apple-shift-E
    
    [imageAllViewers setState: NSOffState];
    
    if( [[ViewerController getDisplayed2DViewers] count] > 1) [imageAllViewers setEnabled: YES];
    else [imageAllViewers setEnabled: NO];
    
    if( [[[imageView seriesObj] valueForKey: @"keyImages"] count]) [[imageSelection cellWithTag: 2] setEnabled: YES];
    else [[imageSelection cellWithTag: 2] setEnabled: NO];
    
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask) [self endExportImage: nil];
    else [NSApp beginSheet: imageExportWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(void) sendMail:(id) sender
{
    [imageFormat selectCellWithTag: 3];
    
    [self exportImage: sender];
    
    //	Mailer		*email;
    //	NSImage		*im = [imageView nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];
    //
    //	NSArray *representations;
    //	NSData *bitmapData;
    //
    //	representations = [im representations];
    //
    //	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
    //
    //	[bitmapData writeToFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/Horos.jpg"] atomically:YES];
    //
    //	email = [[Mailer alloc] init];
    //
    //	[email sendMail:@"--" to:@"--" subject:@"" isMIME:YES name:@"--" sendNow:NO image: [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/Horos.jpg"]];
    //
    //	[email release];
}

- (void) exportJPEG:(id) sender
{
    [imageFormat selectCellWithTag: 0];
    
    [self exportImage: sender];
}

-(IBAction) export2iPhoto:(id) sender
{
    [imageFormat selectCellWithTag: 2];
    
    [self exportImage: sender];
}

-(IBAction) PagePadCreate:(id) sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //check if the folder PAGES exists in OsiriX document folder
    NSString *pathToPAGES = [[[BrowserController currentBrowser] database] pagesDirPath];
    if (!([fileManager fileExistsAtPath:pathToPAGES]))
        [fileManager createDirectoryAtPath:pathToPAGES withIntermediateDirectories:YES attributes:nil error:NULL];
    
    //pathToPAGES = timeStamp
    NSDateFormatter *datetimeFormatter = [[[NSDateFormatter alloc]initWithDateFormat:@"%Y%m%d.%H%M%S" allowNaturalLanguage:NO] autorelease];
    pathToPAGES = [pathToPAGES stringByAppendingPathComponent: [datetimeFormatter stringFromDate:[NSDate date]]];
    
    if (!([[sender title] isEqualToString: @"SCAN"]))
    {
        //create pathToTemplate
        NSString *pathToTemplate = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PAGES"];
        pathToTemplate = [pathToTemplate stringByAppendingPathComponent:[sender title]];
        pathToTemplate = [pathToTemplate stringByAppendingPathExtension:@"template"];
        
        //copy file pathToTemplate to pathToPAGES
        if([fileManager copyItemAtPath:pathToTemplate toPath:[pathToPAGES stringByAppendingPathExtension:@"pages"] error:NULL])
            NSLog( @"%@", [NSString stringWithFormat:@"%@ is a copy of %@",[pathToPAGES stringByAppendingPathExtension:@"pages"], pathToTemplate]);
        else
            NSLog(@"template not available");
    }
    
    
    //create pathToPages/timeStamp.cfg, sibling of pathToPages (allows for use of dcm4che lib to reinject the pdf produced into OsiriX)
    //init and DICOM dateFormatter AAAAMMDD
    NSDate *tagDate;
    NSDateFormatter *NSDate2DA_Formatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y%m%d" allowNaturalLanguage:NO] autorelease];
    NSDateFormatter *NSDate2TM_Formatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%H%M%S" allowNaturalLanguage:NO] autorelease];
    NSDateFormatter *NSDate2DT_Formatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y%m%d%H%M%S.%F00%z" allowNaturalLanguage:NO] autorelease];
    
    NSString *tagString;
    
    NSNumberFormatter *NSNumberFloat2TM_Formatter= [[[NSNumberFormatter alloc] init] autorelease];
    [NSNumberFloat2TM_Formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [NSNumberFloat2TM_Formatter setAllowsFloats:YES];
    [NSNumberFloat2TM_Formatter setAlwaysShowsDecimalSeparator:NO];
    [NSNumberFloat2TM_Formatter setFormat:@"000000.#########"];
    float floatTime;
    
    NSString *pdf2dcmContent = @"# pdf2dcm Configuration";
    pdf2dcmContent = [pdf2dcmContent stringByAppendingString: @"\r# For use with dcm4che pdf2dcm, version 2.0.7"];
    NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
    
    //0010,0010	(2) Patient Module Attributes
    tagString = [curImage valueForKeyPath: @"series.study.name"];
    if ([tagString length] > 0) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Patient's Name\r00100010:%@",tagString];
    
    //0010,0020	(2) Patient Module Attributes
    tagString = [curImage valueForKeyPath: @"series.study.patientID"];
    if ([tagString length] > 0) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Patient ID\r00100020:%@",tagString];
    
    //0010,0021	(3) Patient Module Attributes
    tagString = @"OsiriX";
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Issuer of Patient ID\r00100021:%@",tagString];
    
    //0010,0030	(2) Patient Module Attributes
    tagDate = [curImage valueForKeyPath: @"series.study.dateOfBirth"];
    if (tagDate) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Patient's Birth Date\r00100030:%@",[NSDate2DA_Formatter stringFromDate:tagDate]];
    
    //0010,0040 (2) Patient Module Attributes
    tagString = [curImage valueForKeyPath: @"series.study.patientSex"];
    if ([tagString isEqualToString: @"M"] || [tagString isEqualToString: @"F"] || [tagString isEqualToString: @"O"])
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat:@"\r# Patient's Sex\r00100040:%@",tagString];
    
    
    
    //0020,000D (1) General Study
    tagString = [curImage valueForKeyPath: @"series.study.studyInstanceUID"];
    if ([tagString length] > 0) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Study Instance UID\r0020000D:%@",tagString];
    
    //0008,0020 (2) General Study
    tagDate = [curImage valueForKeyPath: @"series.study.date"];
    if (tagDate) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Study Date\r00080020:%@",[NSDate2DA_Formatter stringFromDate:tagDate]];
    
    //0008,0030 (2) General Study
    floatTime = [[curImage valueForKeyPath: @"series.study.dicomTime"] floatValue];
    if (floatTime)
    {
        NSNumber *tagTime = [NSNumber numberWithFloat:floatTime];
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Study Time\r00080030:%@",[NSNumberFloat2TM_Formatter stringFromNumber:tagTime]];
    }
    
    //0008,0090 (2) General Study
    tagString = [curImage valueForKeyPath: @"series.study.referringPhysician"];
    if (tagString) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Referring Physician's Name\r00080090:%@",tagString];
    
    //0008,1050 () General Study
    tagString = [[[self fileList] objectAtIndex:0] valueForKeyPath: @"series.study.performingPhysician"];
    if (tagString) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Performing Physician's Name\r00081050:%@",tagString];
    
    //0020,0010 (2) General Study
    tagString = [curImage valueForKeyPath: @"series.study.id"];
    if (tagString) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Study ID\r00200010:%@",tagString];
    
    //0008,0050 (2) General Study
    tagString = [curImage valueForKeyPath: @"series.study.accessionNumber"];
    if (tagString) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Accession Number\r00080050:%@",tagString];
    
    //0008,1030 (3) General Study
    tagString = [curImage valueForKeyPath: @"series.study.studyName"];
    if (tagString) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Study Description\r00081030:%@",tagString];
    
    
    
    //0008,0060 (1) Encapsulated Document Series Attributes
    tagString = @"OT"; //Other (in this case, ... pdf)
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Modality\r00080060:%@",tagString];
    
    //0020,000E (1) Encapsulated Document Series Attributes
    tagString = [curImage valueForKeyPath: @"series.study.studyInstanceUID"];//series UID = study UID + timestamp
    if ([tagString length] > 0) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Series Instance UID\r0020000E:%@.%@",tagString,[datetimeFormatter stringFromDate:[NSDate date]]];
    
    //0020,0011 (1) Encapsulated Document Series Attributes
    tagString = @"5002";//always the first series, since Series Instance UID contains a timeStamp
    if (tagString) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Series Number\r00200011:%@",tagString];
    
    
    
    //0008,0070 (2) General Equipment Module Attributes.... to be modified with reading from the dicom file...
    if ([[sender title] isEqualToString: @"SCAN"])
    {
        tagString = @"Apple Mac OSX 10.4";
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Manufacturer\r00080070:%@",tagString];
    }
    else
    {
        tagString = @"Philips Medical Systems (Netherlands)";
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Manufacturer\r00080070:%@",tagString];
    }
    
    //0008,0064 (1) SC Equipment Module Attributes
    tagString = @"WSD";//Workstation
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Conversion Type\r00080064:%@",tagString];
    
    
    
    //0020,0013 (1) Encapsulated Document Module Attributes
    tagString = @"1";
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Instance Number\r00200013:%@",tagString];
    
    //0008,0023 (2) Encapsulated Document Module Attributes
    //0008,0033 (2) Encapsulated Document Module Attributes
    tagDate = [NSDate date];
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Content Date\r00080023:%@",[NSDate2DA_Formatter stringFromDate:tagDate]];
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Content Time\r00080033:%@",[NSDate2TM_Formatter stringFromDate:tagDate]];
    
    //0008,002A (2) Encapsulated Document Module Attributes
    //Needs to be improved ... normally acquisition datetime - replaced by study datetime !!!
    tagDate = [curImage valueForKeyPath: @"series.study.date"];
    if (tagDate) pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Acquisition Datetime\r0008002A:%@",[NSDate2DT_Formatter stringFromDate:tagDate]];
    
    //0028,0301 (1) Encapsulated Document Module Attributes
    tagString = @"YES";
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Burned In Annotation\r00280301:%@",tagString];
    
    //0042,0010 (2) Encapsulated Document Module Attributes
    //0008,103E SeriesDescription
    //Better asking for the title... or copying it from the study or from the performed procedure step
    if ([[sender title] isEqualToString: @"SCAN"])
    {
        tagString = @"SCAN";
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Document Title\r00420010:%@",tagString];
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Series Description\r0008103E:%@",tagString];
    }
    else
    {
        tagString = @"FILM";
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Document Title\r00420010:%@",tagString];
        pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Series Description\r0008103E:%@",tagString];
    }
    //0040,A043 (2) Encapsulated Document Module Attributes
    //tagString = @" ";
    //pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Concept Name Code Value\r#0040A043:%@",tagString];
    //0040,A043/0008,0100 (1c) Encapsulated Document Module Attributes
    //tagString = @" ";
    //pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Concept Name Code Value\r#0040A043/00080100:%@",tagString];
    //0040,A043/0008,0102	 (1c) Encapsulated Document Module Attributes
    //tagString = @" ";
    //pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Concept Name Coding Scheme Designator\r0040A043/00080102:%@",tagString];
    //0040,A043/0008,0104 (1c) Encapsulated Document Module Attributes
    //tagString = @" ";
    //pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# Concept Name Meaning\r0040A043/00080104:%@",tagString];
    //0042,0012	 (1) Encapsulated Document Module Attributes
    tagString = @"application/pdf";
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# MIME Type of Encapsulated Document\r00420012:%@",tagString];
    
    
    //0008,0016 (1) SOP Common Module Attributes
    tagString = [DCMAbstractSyntaxUID pdfStorageClassUID];
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# SOP Class UID\r00080016:%@",tagString];
    
    //0008,0018 (1) SOP Common Module Attributes
    pdf2dcmContent = [pdf2dcmContent stringByAppendingFormat: @"\r# SOP Instance UID\r#00080018"];
    
    if( [fileManager createFileAtPath:[pathToPAGES stringByAppendingPathExtension:@"cfg"]
                             contents:[pdf2dcmContent dataUsingEncoding:NSUTF8StringEncoding]
                           attributes:nil])
        NSLog( @"%@", [NSString stringWithFormat:@"created %@ for dicom pdf creation with dcm4che pdf2dcm",[pathToPAGES stringByAppendingPathExtension:@"cfg"]]);
    
    
    if (!([[sender title] isEqualToString: @"SCAN"]))
    {
        //open pathToPAGES
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: [pathToPAGES stringByAppendingPathExtension:@"pages"]] == NO)
            NSRunAlertPanel(NSLocalizedString(@"Export", nil), NSLocalizedString(@"Failed to export this file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        
        [[NSWorkspace sharedWorkspace] openFile: [pathToPAGES stringByAppendingPathExtension:@"pages"] withApplication: nil andDeactivate: YES];
        [NSThread sleepForTimeInterval: 1];
    }
}

- (void) exportTIFF:(id) sender
{
    [imageFormat selectCellWithTag: 1];
    
    [self exportImage: sender];
}

- (IBAction) endExportImage: (id) sender
{
    if( sender)
    {
        [imageExportWindow orderOut:sender];
        [NSApp endSheet:imageExportWindow returnCode:[sender tag]];
    }
    
    int numberOfExportedImages = 0;
    for( int i = 0; i < [pixList[ curMovieIndex] count]; i++)
    {
        BOOL export = YES;
        int index;
        
        if( [imageView flippedData])
            index = [pixList[curMovieIndex] count] -i -1;
        else
            index = i;
        
        if( [[imageSelection selectedCell] tag] == 1)	// All images
        {
            export = YES;
        }
        
        if( [[imageSelection selectedCell] tag] == 2)	// Keyimages only
        {
            NSManagedObject	*image;
            
            image = [[self fileList] objectAtIndex: index];
            
            export = [[image valueForKey:@"isKeyImage"] boolValue];
        }
        
        if( [[imageSelection selectedCell] tag] == 0)	// Current image only
        {
            if( index == [imageView curImage]) export = YES;
            else export = NO;
        }
        
        if( export)
            numberOfExportedImages++;
    }
    
    NSSavePanel     *panel = [NSSavePanel savePanel];
    long			i;
    
    [panel setCanSelectHiddenExtension:YES];
    
    if( [[imageFormat selectedCell] tag] == 0)
        [panel setAllowedFileTypes:@[@"jpg"]];
    else
        [panel setAllowedFileTypes:@[@"tif"]];
    
    if( [sender tag] != 0 || sender == nil)
    {
        BOOL pathOK = YES;
        
        if( [[imageFormat selectedCell] tag] != 2 && [[imageFormat selectedCell] tag] != 3)		//Mail or Photos
        {
            NSString *defaultExportName = [[fileList[ curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.name"];
            
            if( numberOfExportedImages > 1)
                defaultExportName = [defaultExportName stringByAppendingPathExtension: [NSString stringWithFormat:@"%4.4d", 1]];
            
            panel.nameFieldStringValue = defaultExportName;
            
            if( [panel runModal] != NSFileHandlingPanelOKButton)
                pathOK = NO;
        }
        
        if( pathOK == YES)
        {
            [[NSFileManager defaultManager] removeItemAtPath: [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"EXPORT"] error:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath: [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"EXPORT"] withIntermediateDirectories:YES attributes:nil error:nil];
            
            int fileIndex;
            
            for( i = 0, fileIndex = 1; i < [pixList[ curMovieIndex] count]; i++)
            {
                BOOL export = YES;
                int index;
                
                if( [imageView flippedData])
                    index = [pixList[curMovieIndex] count] -i -1;
                else
                    index = i;
                
                if( [[imageSelection selectedCell] tag] == 1)	// All images
                {
                    export = YES;
                }
                
                if( [[imageSelection selectedCell] tag] == 2)	// Keyimages only
                {
                    NSManagedObject	*image;
                    
                    image = [[self fileList] objectAtIndex: index];
                    
                    export = [[image valueForKey:@"isKeyImage"] boolValue];
                }
                
                if( [[imageSelection selectedCell] tag] == 0)	// Current image only
                {
                    if( index == [imageView curImage]) export = YES;
                    else export = NO;
                }
                
                if( export)
                {
                    [imageView setIndex: index];
                    [imageView sendSyncMessage: 0];
                    [[seriesView imageViews] makeObjectsPerformSelector:@selector(display)];
                    
                    NSImage *im = [imageView nsimage: NO allViewers:[imageAllViewers state]];
                    
                    NSArray *representations;
                    NSData *bitmapData;
                    
                    representations = [im representations];
                    
                    if( [[imageFormat selectedCell] tag] == 2 || [[imageFormat selectedCell] tag] == 3)		//Mail or Photos
                    {
                        //						if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportImageInGrayColorSpace"] && ) // 8-bit
                        //						{
                        //							NSBitmapImageRep *grayRepresentation = [NSBitmapImageRep imageRepWithData: [im TIFFRepresentation]];
                        //							bitmapData = [[grayRepresentation bitmapImageRepByConvertingToColorSpace: [NSColorSpace genericGrayColorSpace] renderingIntent: NSColorRenderingIntentDefault] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
                        //						}
                        //						else
                        bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
                        
                        NSString *jpegFile = [[[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"EXPORT"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%4.4d.jpg", fileIndex++]];
                        
                        [bitmapData writeToFile: jpegFile atomically:YES];
                        
                        NSManagedObject	*curImage = [fileList[ 0] objectAtIndex:0];
                        
                        NSDictionary *exifDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  @"Exported from OsiriX", kCGImagePropertyExifUserComment,
                                                  [[curImage valueForKeyPath: @"series.study.date"] descriptionWithCalendarFormat:@"%Y:%m:%d %H:%M:%S" timeZone:nil locale: nil] , kCGImagePropertyExifDateTimeOriginal,
                                                  nil];
                        
                        [JPEGExif addExif: [NSURL fileURLWithPath: jpegFile] properties: exifDict format:@"jpeg"];
                    }
                    else
                    {
                        if( [[imageFormat selectedCell] tag] == 0)
                        {
                            NSString *jpegFile;
                            
                            if( numberOfExportedImages > 1)
                                jpegFile = [[[panel.URL.path stringByDeletingPathExtension] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%4.4d.jpg", fileIndex++]];
                            else
                                jpegFile = panel.URL.path;
                            
                            //							if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportImageInGrayColorSpace"]) // 8-bit
                            //							{
                            //								NSBitmapImageRep *grayRepresentation = [NSBitmapImageRep imageRepWithData: [im TIFFRepresentation]];
                            //								bitmapData = [[grayRepresentation bitmapImageRepByConvertingToColorSpace: [NSColorSpace genericGrayColorSpace] renderingIntent: NSColorRenderingIntentDefault] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
                            //							}
                            //							else
                            bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
                            
                            [bitmapData writeToFile: jpegFile atomically:YES];
                            
                            NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
                            
                            NSDictionary *exifDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      @"Exported from OsiriX", kCGImagePropertyExifUserComment,
                                                      [[curImage valueForKeyPath: @"series.study.date"] descriptionWithCalendarFormat:@"%Y:%m:%d %H:%M:%S" timeZone:nil locale: nil] , kCGImagePropertyExifDateTimeOriginal,
                                                      nil];
                            
                            [JPEGExif addExif: [NSURL fileURLWithPath: jpegFile] properties: exifDict format:@"jpeg"];
                        }
                        else
                        {
                            NSString *tiffFile;
                            
                            if( numberOfExportedImages > 1)
                                tiffFile = [[[panel.URL.path stringByDeletingPathExtension] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%4.4d.tif", fileIndex++]];
                            else
                                tiffFile = panel.URL.path;
                            
                            //							if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportImageInGrayColorSpace"]) // 8-bit
                            //							{
                            //								NSBitmapImageRep *grayRepresentation = [NSBitmapImageRep imageRepWithData: [im TIFFRepresentation]];
                            //								[[[grayRepresentation bitmapImageRepByConvertingToColorSpace: [NSColorSpace genericGrayColorSpace] renderingIntent: NSColorRenderingIntentDefault] TIFFRepresentation] writeToFile: tiffFile atomically:NO];
                            //							}
                            //							else
                            [[im TIFFRepresentation] writeToFile: tiffFile atomically:NO];
                        }
                    }
                }
            }
            
            NSString *root = [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"EXPORT"];
            
            if( [[imageFormat selectedCell] tag] == 2) // Photos
            {
                Photos	*ifoto = [[Photos alloc] init];
                [ifoto importInPhotos: [NSArray arrayWithObject: root]];
                [ifoto release];
            }
            
            if( [[imageFormat selectedCell] tag] == 3)	// Mail
            {
#define kScriptName (@"Mail")
#define kScriptType (@"scpt")
#define kHandlerName (@"mail_images")
#define noScriptErr 0
                
                /* Locate the script within the bundle */
                NSString *scriptPath = [[NSBundle mainBundle] pathForResource: kScriptName ofType: kScriptType];
                NSURL *scriptURL = [NSURL fileURLWithPath: scriptPath];
                
                NSDictionary *errorInfo = nil;
                
                /* Here I am using "initWithContentsOfURL:" to load a pre-compiled script, rather than using "initWithSource:" to load a text file with AppleScript source.  The main reason for this is that the latter technique seems to give rise to inexplicable -1708 (errAEEventNotHandled) errors on Jaguar. */
                NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL: scriptURL error: &errorInfo];
                
                /* See if there were any errors loading the script */
                if (!script || errorInfo)
                    NSLog(@"%@", errorInfo);
                
                /* We have to construct an AppleEvent descriptor to contain the arguments for our handler call.  Remember that this list is 1, rather than 0, based. */
                NSAppleEventDescriptor *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
                [arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @"subject"] atIndex: 1];
                [arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @"defaultaddress@mac.com"] atIndex: 2];
                
                
                NSAppleEventDescriptor *listFiles = [NSAppleEventDescriptor listDescriptor];
                NSAppleEventDescriptor *listCaptions = [NSAppleEventDescriptor listDescriptor];
                NSAppleEventDescriptor *listComments = [NSAppleEventDescriptor listDescriptor];
                
                int f = 0;
                NSString *root = [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"EXPORT"];
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: root error: nil];
                for( int x = 0; x < [files count] ; x++)
                {
                    if( [[[files objectAtIndex: x] pathExtension] isEqualToString: @"jpg"])
                    {
                        [listFiles insertDescriptor: [NSAppleEventDescriptor descriptorWithString: [root stringByAppendingPathComponent: [files objectAtIndex: x]]] atIndex:1+f];
                        [listCaptions insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @""] atIndex:1+f];
                        [listComments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @""] atIndex:1+f];
                        f++;
                    }
                }
                
                [arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithInt32: f] atIndex: 3];
                [arguments insertDescriptor: listFiles atIndex: 4];
                [arguments insertDescriptor: listCaptions atIndex: 5];
                [arguments insertDescriptor: listComments atIndex: 6];
                
                [arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @"Cancel"] atIndex: 7];
                
                errorInfo = nil;
                
                /* Call the handler using the method in our special category */
                NSAppleEventDescriptor *result = [script callHandler: kHandlerName withArguments: arguments errorInfo: &errorInfo];
                
                int scriptResult = [result int32Value];
                
                /* Check for errors in running the handler */
                if (errorInfo)
                {
                    NSLog(@"%@", errorInfo);
                }
                /* Check the handler's return value */
                else if (scriptResult != noScriptErr) {
                    NSRunAlertPanel(NSLocalizedString(@"Script Failure", @"Title on script failure window."), @"%@ %d",NSLocalizedString(@"OK", @""), nil, nil, NSLocalizedString(@"The script failed:", @"Message on script failure window."), scriptResult);
                }
                
                [script release];
                [arguments release];
            }
            
            if( [[imageFormat selectedCell] tag] == 0 || [[imageFormat selectedCell] tag] == 1)
            {
                NSString	*filePath;
                
                if( numberOfExportedImages > 1)
                {
                    if( [[imageFormat selectedCell] tag] == 0)
                        filePath = [[[panel.URL.path stringByDeletingPathExtension] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%4.4d.jpg", 1]];
                    else
                        filePath = [[[panel.URL.path stringByDeletingPathExtension] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%4.4d.tif", 1]];
                }
                else
                    filePath = panel.URL.path;
                
                if( filePath)
                {
                    if( [[NSFileManager defaultManager] fileExistsAtPath: filePath] == NO)
                        NSRunAlertPanel(NSLocalizedString(@"Export", nil), NSLocalizedString(@"Failed to export this file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                    
                    else if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
                        [[NSWorkspace sharedWorkspace] openFile:filePath];
                }
            }
        }
        //			{
        //				NSImage *im = [imageView nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"] allViewers:[imageAllViewers state]];
        //				
        //				NSArray *representations;
        //				NSData *bitmapData;
        //				
        //				representations = [im representations];
        //				
        //				if( [[imageFormat selectedCell] tag] == 2)	// ifoto
        //				{
        //					bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
        //					
        //					NSString *jpegFile = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/Horos.jpg"];
        //					
        //					[bitmapData writeToFile: jpegFile atomically:YES];
        //					
        //					NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
        //								
        //					NSDictionary *exifDict = [NSDictionary dictionaryWithObjectsAndKeys:
        //													@"Exported from OsiriX", kCGImagePropertyExifUserComment,
        //													[[curImage valueForKeyPath: @"series.study.date"] descriptionWithCalendarFormat:@"%Y:%m:%d %H:%M:%S" timeZone:nil locale: nil] , kCGImagePropertyExifDateTimeOriginal,
        //													nil];
        //
        //					[JPEGExif addExif: [NSURL fileURLWithPath: jpegFile] properties: exifDict format:@"jpeg"];
        //					
        //					Photos	*ifoto = [[Photos alloc] init];
        //					[ifoto importInPhotos: [NSArray arrayWithObject: jpegFile]];
        //					[ifoto release];
        //				}
        //				else
        //				{
        //					if( [[imageFormat selectedCell] tag] == 0)
        //					{
        //						bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
        //						[bitmapData writeToFile:[panel filename] atomically:YES];
        //						
        //						NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
        //						
        //						NSDictionary *exifDict = [NSDictionary dictionaryWithObjectsAndKeys:
        //															@"Exported from OsiriX", kCGImagePropertyExifUserComment,
        //															[[curImage valueForKeyPath: @"series.study.date"] descriptionWithCalendarFormat:@"%Y:%m:%d %H:%M:%S" timeZone:nil locale: nil] , kCGImagePropertyExifDateTimeOriginal,
        //															nil];
        //
        //						
        //						[JPEGExif addExif: [NSURL fileURLWithPath: [panel filename]] properties: exifDict format:@"jpeg"]; 
        //					}
        //					else
        //					{
        //						NSString *tiffFile = [[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"tif"]];
        //						[[im TIFFRepresentation] writeToFile: tiffFile atomically:NO];
        //						
        //						NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
        //						
        //						NSDictionary *exifDict = [NSDictionary dictionaryWithObjectsAndKeys:
        //															@"Exported from OsiriX", kCGImagePropertyExifUserComment,
        //															[[curImage valueForKeyPath: @"series.study.date"] descriptionWithCalendarFormat:@"%Y:%m:%d %H:%M:%S" timeZone:nil locale: nil] , kCGImagePropertyExifDateTimeOriginal,
        //															nil];
        //
        //						
        //						[JPEGExif addExif: [NSURL fileURLWithPath: [panel filename]] properties: exifDict format:@"tiff"]; 
        //					}
        //					
        //					if( [[NSFileManager defaultManager] fileExistsAtPath: [panel filename]] == NO)
        //						NSRunAlertPanel(NSLocalizedString(@"Export", nil), NSLocalizedString(@"Failed to export this file.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        //					
        //					if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
        //					{
        //						[ws openFile:[panel filename]];
        //					}
        //				}									
        //			}
    }
}

//#define ICHAT_WIDTH 640
//#define ICHAT_HEIGHT 480
//
//#ifndef OSIRIX_LIGHT
//- (void)iChatBroadcast:(id)sender
//{
//    if( [IChatTheatreDelegate initSharedDelegate])
//    {
//        [[IChatTheatreDelegate sharedDelegate] showIChatHelp];
//        NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.iChat"];
//        [[NSWorkspace sharedWorkspace] launchApplication:path];
//    }
//    else
//    {
//        NSRunAlertPanel(NSLocalizedString( @"Address Book", nil), NSLocalizedString(@"Access to address book is required to start an iChat session. See Privacy tab in System Preferences.", nil), nil, nil, nil);
//    }
//}
//
//- (void) notificationiChatBroadcast:(NSNotification*)note
//{
//	if( timeriChat) [self iChatBroadcast:[self findiChatButton]];
//}
//
//
//-(id) findiChatButton
//{
////	for( x = 0; x < [[NSScreen screens] count]; x++)
//	{
//		NSArray *items = [toolbar items];
//		
//		for( id loopItem in items)
//		{
//			if( [[loopItem itemIdentifier] isEqualToString:iChatBroadCastToolbarItemIdentifier])
//			{
//				return loopItem;
//			}
//		}
//	}
//	
//	return nil;
//}
//#endif

- (void)exportTextFieldDidChange:(NSNotification *)note
{
    if([[note object] isEqualTo:dcmIntervalText])
    {
        if([dcmIntervalText intValue] > [dcmInterval maxValue])
        {
            [dcmIntervalText setIntValue:[dcmInterval maxValue]];
        }
        [dcmInterval takeIntValueFrom:dcmIntervalText];
    }
    else if([[note object] isEqualTo:dcmFromText])
    {
        if([dcmFromText intValue] > [dcmFrom maxValue])
        {
            [dcmFromText setIntValue:[dcmFrom maxValue]];
        }
        [dcmFrom takeIntValueFrom:dcmFromText];
    }
    else if([[note object] isEqualTo:dcmToText])
    {
        if([dcmToText intValue] > [dcmTo maxValue])
        {
            [dcmToText setIntValue:[dcmTo maxValue]];
        }
        [dcmTo takeIntValueFrom:dcmToText];
    }
    else if([[note object] isEqualTo:quicktimeIntervalText])
    {
        if([quicktimeIntervalText intValue] > [quicktimeInterval maxValue])
        {
            [quicktimeIntervalText setIntValue:[quicktimeInterval maxValue]];
        }
        [quicktimeInterval takeIntValueFrom:quicktimeIntervalText];
    }
    else if([[note object] isEqualTo:quicktimeFromText])
    {
        if([quicktimeFromText intValue] > [quicktimeFrom maxValue])
        {
            [quicktimeFromText setIntValue:[quicktimeFrom maxValue]];
        }
        [quicktimeFrom takeIntValueFrom:quicktimeFromText];
    }
    else if([[note object] isEqualTo:quicktimeToText])
    {
        if([quicktimeToText intValue] > [quicktimeTo maxValue])
        {
            [quicktimeToText setIntValue:[quicktimeTo maxValue]];
        }
        [quicktimeTo takeIntValueFrom:quicktimeToText];
    }
}

#pragma mark-
#pragma mark 4.5.1.2 Exportation of image raw

#pragma mark-
#pragma mark 4.5.2 Importation

#pragma mark-
#pragma mark 4.5.3 3D

- (void) clear8bitRepresentations
{
    // This function will free about 1/4 of the data
    
    for( int i = 0; i < maxMovieIndex; i++)
    {
        for( int x = 0; x < [pixList[ i] count]; x++)
        {
            if( [pixList[ i] objectAtIndex:x] != [imageView curDCM])
                [[pixList[ i] objectAtIndex:x] kill8bitsImage];
        }
    }
    
    [self updateImage: self];	// <- compute at least current image...
}

-(float*) volumePtr
{
    return  (float*) [volumeData[ curMovieIndex] bytes];
}

-(float*) volumePtr: (long) i
{
    if( i < 0) i = 0;
    if( i >= maxMovieIndex) i = maxMovieIndex-1;
    
    return  (float*) [volumeData[ i] bytes];
}

- (NSData*)volumeData;
{
    return volumeData[ curMovieIndex];
}

- (NSData*)volumeData:(long)i;
{
    if( i < 0) i = 0;
    if( i>= maxMovieIndex) i = maxMovieIndex-1;
    
    return volumeData[ i];
}

#ifndef OSIRIX_LIGHT
- (float) computeVolume:(ROI*) selectedRoi points:(NSMutableArray**) pts error:(NSString**) error
{
    return [self computeVolume:(ROI*) selectedRoi points:(NSMutableArray**) pts generateMissingROIs: NO generatedROIs: nil computeData: nil error:(NSString**) error];
}

- (float) computeVolume:(ROI*) selectedRoi points:(NSMutableArray**) pts generateMissingROIs:(BOOL) generateMissingROIs error:(NSString**) error
{
    return [self computeVolume:(ROI*) selectedRoi points:(NSMutableArray**) pts generateMissingROIs:(BOOL) generateMissingROIs generatedROIs: nil computeData: nil error:(NSString**) error];
}

- (float) computeVolume:(ROI*) selectedRoi points:(NSMutableArray**) pts generateMissingROIs:(BOOL) generateMissingROIs generatedROIs:(NSMutableArray*) generatedROIs computeData:(NSMutableDictionary*) data error:(NSString**) error
{
    long globalCount, imageCount, lastImageIndex;
    double volume, prevArea, preLocation, location, sliceInterval;
    ROI	*lastROI;
    BOOL missingSlice = NO;
    NSMutableArray *theSlices = [NSMutableArray array];
    
    if( pts) *pts = [NSMutableArray array];
    
    lastROI = nil;
    lastImageIndex = -1;
    if( error) *error = nil;
    
    NSLog( @"computeVolume started");
    
    if( generateMissingROIs)
    {
        [self roiDeleteGeneratedROIsForName: [selectedRoi name]];
        
        for( int x = 0; x < [pixList[curMovieIndex] count]; x++)
        {
            imageCount = 0;
            
            for( int i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
            {
                ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
                
                if( [[curROI name] isEqualToString: [selectedRoi name]] && [curROI isValidForVolume])
                {
                    imageCount++;
                    
                    if( generateMissingROIs)
                    {
                        if( lastROI && (lastImageIndex+1) < x)
                        {
                            for( int y = lastImageIndex+1; y < x; y++)
                            {
                                ROI	*c = [self roiMorphingBetween: lastROI  and: curROI ratio: (float) (y - lastImageIndex) / (float) (x - lastImageIndex)];
                                
                                if( c)
                                {
                                    [c setComments: @"morphing generated"];
                                    [c setName: [selectedRoi name]];
                                    [imageView roiSet: c];
                                    [[roiList[curMovieIndex] objectAtIndex: y] addObject: c];
                                    
                                    [generatedROIs addObject: c];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixAddROINotification object:self
                                                                                      userInfo:@{@"ROI": c, @"sliceNumber": [NSNumber numberWithLong:x]}];
                                }
                            }
                        }
                    }
                    
                    lastImageIndex = x;
                    lastROI = curROI;
                }
            }
        }
        
        NSLog( @"generated ROI done");
    }
    
    lastROI = nil;
    prevArea = 0;
    globalCount = 0;
    lastImageIndex = -1;
    preLocation = 0;
    location = 0;
    volume = 0;
    sliceInterval = [[pixList[curMovieIndex] objectAtIndex: 0] sliceInterval];
    
    ROI *fROI = nil, *lROI = nil;
    int	fROIIndex, lROIIndex;
    ROI	*curROI = nil;
    NSOperationQueue* queue = [[[NSOperationQueue alloc] init] autorelease];
    
    for( int x = 0; x < [pixList[curMovieIndex] count]; x++)
    {
        DCMPix	*pic = [pixList[curMovieIndex] objectAtIndex: x];
        imageCount = 0;
        
        location = x * sliceInterval;
        
        // TODO : convert to NSOperation: ITKSegmentation3D extractContour is slow
        
        for( int i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
        {
            curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
            if( [[curROI name] isEqualToString: [selectedRoi name]] == YES  && [curROI isValidForVolume])		//&& [[curROI comments] isEqualToString:@"morphing generated"] == NO)
            {
                if( fROI == nil)
                {
                    fROI = curROI;
                    fROIIndex = x;
                }
                lROI = curROI;
                lROIIndex = x;
                
                globalCount++;
                imageCount++;
                
                DCMPix *curPix = [pixList[ curMovieIndex] objectAtIndex: x];
                float curArea = [curROI roiArea];
                
                [curROI setPix: curPix];
                
                if( curArea == 0)
                {
                    if( error) *error = [NSString stringWithString: NSLocalizedString(@"One ROI has an area equal to ZERO!", nil)];
                    return 0;
                }
                
                if( preLocation != 0)
                    volume += ((location - preLocation)/10.) * (curArea + prevArea)/2.;
                
                prevArea = curArea;
                preLocation = location;
                
                if( pts)
                {
                    [queue addOperationWithBlock:^{
                        NSMutableArray	*points = nil;
                        
                        if( [curROI type] == tPlain)
                        {
                            points = [ITKSegmentation3D extractContour:[curROI textureBuffer] width:[curROI textureWidth] height:[curROI textureHeight] numPoints: 100 largestRegion: NO];
                            
                            float mx = [curROI textureUpLeftCornerX], my = [curROI textureUpLeftCornerY];
                            
                            for( int zz = 0; zz < [points count]; zz++)
                            {
                                MyPoint	*pt = [points objectAtIndex: zz];
                                [pt move: mx :my];
                            }
                        }
                        else points = [curROI splinePoints];
                        
                        for( int y = 0; y < [points count]; y++)
                        {
                            float location[ 3];
                            
                            [pic convertPixX: [[points objectAtIndex: y] x] pixY: [[points objectAtIndex: y] y] toDICOMCoords: location pixelCenter: YES];
                            
                            NSArray	*pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
                            
                            @synchronized( self)
                            {
                                [*pts addObject: pt3D];
                            }
                        }
                    }];
                }
                
                if( lastROI && (lastImageIndex+1) < x)
                    missingSlice = YES;
                
                [theSlices addObject: [NSDictionary dictionaryWithObjectsAndKeys: curROI, @"roi", curPix, @"dcmPix", nil]];
                
                lastImageIndex = x;
                lastROI = curROI;
            }
        }
        
        if( imageCount > 1)
        {
            if( [imageView flippedData])
            {
                if( error) *error = [NSString stringWithFormat: NSLocalizedString(@"Only ONE ROI per image supported! (im: %d)", nil), [pixList[curMovieIndex] count] -x];
            }
            else
            {
                if( error) *error = [NSString stringWithFormat: NSLocalizedString(@"Only ONE ROI per image supported! (im: %d)", nil), x+1];
            }
            return 0;
        }
    }
    
    while (queue.operationCount)
    {
        [NSThread sleepForTimeInterval:0.05];
    }
    
    if( volume == 0)
    {
        if( error)
            *error = NSLocalizedString(@"Not possible to compute a volume!", nil);
        return 0L;
    }
    
    NSLog( @"********");
    
    if( pts)
    {
        if( fROI && lROI)
        {
            // Close the floor and the ceil of the volume
            
            //			float *data;
            //			float *locations;
            //			long dataSize;
            //			
            //			data = [[fROI pix] getROIValue:&dataSize :fROI :&locations];
            //			
            //			for( i = 0 ; i < dataSize; i +=4)
            //			{
            //				float location[ 3];
            //				NSArray	*pt3D;
            //				
            //				[[fROI pix] convertPixX: locations[i*2] pixY: locations[i*2+1] toDICOMCoords: location];
            //				
            //				pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
            //				NSLog( [pt3D description]);
            //				[*pts addObject: pt3D];
            //			}
            //			
            //			free( data);
            //			free( locations);
            //			
            //			data = [[lROI pix] getROIValue:&dataSize :lROI :&locations];
            //			
            //			for( i = 0 ; i < dataSize; i +=4)
            //			{
            //				float location[ 3];
            //				NSArray	*pt3D;
            //				
            //				[[lROI pix] convertPixX: locations[i*2] pixY: locations[i*2+1] toDICOMCoords: location];
            //				
            //				pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
            //				NSLog( [pt3D description]);
            //				[*pts addObject: pt3D];
            //			}
            //			
            //			free( data);
            //			free( locations);
            
            float location[ 3];
            NSArray	*pt3D;
            NSPoint centroid;
            DCMPix	*pic;
            
            if( fROIIndex > 0) fROIIndex--;
            if( lROIIndex < (long)[pixList[curMovieIndex] count]-1) lROIIndex++;
            
            pic = [pixList[curMovieIndex] objectAtIndex: fROIIndex];
            centroid = [fROI centroid];
            [pic  convertPixX: centroid.x pixY: centroid.y toDICOMCoords: location pixelCenter: YES];
            pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]-1], [NSNumber numberWithFloat:location[2]], nil];
            [*pts addObject: pt3D];
            pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]+1], [NSNumber numberWithFloat:location[2]], nil];
            [*pts addObject: pt3D];
            pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
            [*pts addObject: pt3D];
            
            pic = [pixList[curMovieIndex] objectAtIndex: lROIIndex];
            centroid = [lROI centroid];
            [pic  convertPixX: centroid.x pixY: centroid.y toDICOMCoords: location pixelCenter: YES];
            pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]-1], [NSNumber numberWithFloat:location[2]], nil];
            [*pts addObject: pt3D];
            pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]-1], [NSNumber numberWithFloat:location[1]+1], [NSNumber numberWithFloat:location[2]], nil];
            [*pts addObject: pt3D];
            pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
            [*pts addObject: pt3D];
        }
        
        if( [*pts count] == 0)
        {
            if( error)
                *error = NSLocalizedString(@"Not possible to compute a volume!", nil);
            return 0L;
        }
    }
    
    NSLog( @"volume computation done");
    
    if( pts && [*pts count] > 0)
    {
        NSLog( @"number of points: %d", (int) [*pts count]);
        
#define MAXPOINTS 7000
        
        if( [*pts count] > MAXPOINTS*2)
        {
            NSMutableArray *newpts = [NSMutableArray arrayWithCapacity: MAXPOINTS*2];
            
            int add = [*pts count] / MAXPOINTS;
            
            if( add > 1)
            {
                for( int i = 0; i < [*pts count]; i += add)
                {
                    [newpts addObject: [*pts objectAtIndex: i]];
                }
                
                NSLog( @"too much points, reducing from: %d, to: %d", (int) [*pts count], (int) [newpts count]);
                
                [*pts removeAllObjects];
                [*pts addObjectsFromArray: newpts];
            }
        }
    }
    
    if( data)
    {
        if( missingSlice) NSLog( @"**** Warning cannot compute data on a ROI with missing slices. Turn generateMissingROIs to TRUE to solve this.");
        else
        {
            double gmean = 0, gtotal = 0, gmin = 0, gmax = 0, gdev = 0, gskewness = 0, gkurtosis = 0;
            
            //			for( i = 0 ; i < [theSlices count]; i++)
            //			{
            //				DCMPix	*curPix = [[theSlices objectAtIndex: i] objectForKey:@"dcmPix"];
            //				ROI		*curROI = [[theSlices objectAtIndex: i] objectForKey:@"roi"];
            //				
            //				float mean = 0, total = 0, dev = 0, min = 0, max = 0;
            //				[curPix computeROIInt: curROI :&mean :&total :&dev :&min :&max];
            //				
            //				gmean  = ((gmean * gtotal) + (mean*total)) / (gtotal+total);
            //				gdev  = ((gdev * gtotal) + (dev*total)) / (gtotal+total);
            //				
            //				gtotal += total;
            //
            //				if( i == 0)
            //				{
            //					gmin = min;
            //					gmax = max;
            //				}
            //				else
            //				{
            //					if( min < gmin) gmin = min;
            //					if( max > gmax) gmax = max;
            //				}
            //			}
            //			
            //			NSLog( @"%f\r%f\r%f\r%f\r%f", gtotal, gmean, gdev, gmin, gmax);
            
            long				memSize = 0;
            float				*totalPtr = nil;
            NSMutableArray		*rois = [NSMutableArray array];
            
            for( int i = 0 ; i < [theSlices count]; i++)
            {
                DCMPix	*curPix = [[theSlices objectAtIndex: i] objectForKey:@"dcmPix"];
                ROI		*curROI = [[theSlices objectAtIndex: i] objectForKey:@"roi"];
                
                [rois addObject: curROI];
                
                long numberOfValues;
                
                float *tempPtr = [curPix getROIValue: &numberOfValues :curROI :nil];
                if( tempPtr)
                {
                    float *newPtr = malloc( (memSize + numberOfValues)*sizeof( float));
                    if( newPtr)
                    {
                        if( totalPtr)
                            memcpy( newPtr, totalPtr, memSize * sizeof(float));
                        
                        free( totalPtr);
                        totalPtr = newPtr;
                        
                        memcpy( newPtr + memSize, tempPtr, numberOfValues * sizeof(float));
                        
                        memSize += numberOfValues;
                    }
                    
                    free( tempPtr);
                }
            }
            
            if( memSize > 0 && totalPtr != nil)
            {
                gtotal = 0;
                for( int i = 0; i < memSize; i++)
                {
                    gtotal += totalPtr[ i];
                }
                
                gmean = gtotal / memSize;
                
                gdev = 0;
                gmin = totalPtr[ 0];
                gmax = totalPtr[ 0];
                for( int i = 0; i < memSize; i++)
                {
                    float val = totalPtr[ i];
                    
                    float temp = gmean - val;
                    temp *= temp;
                    gdev += temp;
                    
                    if( val < gmin) gmin = val;
                    if( val > gmax) gmax = val;
                }
                gdev = gdev / (double) (memSize-1);
                gdev = sqrt( gdev);
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ROIComputeSkewnessAndKurtosis"])
                {
                    gskewness = [DCMPix skewness: totalPtr length: memSize mean: gmean];
                    gkurtosis = [DCMPix kurtosis: totalPtr length: memSize mean: gmean];
                }
            }
            
            free( totalPtr);
            
            [data setObject: [NSNumber numberWithDouble: gmin] forKey:@"min"];
            [data setObject: [NSNumber numberWithDouble: gmax] forKey:@"max"];
            [data setObject: [NSNumber numberWithDouble: gmean] forKey:@"mean"];
            [data setObject: [NSNumber numberWithDouble: gtotal] forKey:@"total"];
            [data setObject: [NSNumber numberWithDouble: gdev] forKey:@"dev"];
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ROIComputeSkewnessAndKurtosis"])
            {
                [data setObject: [NSNumber numberWithDouble: gskewness] forKey:@"skewness"];
                [data setObject: [NSNumber numberWithDouble: gkurtosis] forKey:@"kurtosis"];
            }
            [data setObject: [NSNumber numberWithDouble: fabs( volume)] forKey:@"volume"];
            [data setObject: rois forKey:@"rois"];
        }
    }
    
    NSLog( @"data computation done");
    
    if( globalCount == 1)
    {
        if( error) *error = NSLocalizedString(@"I found only ONE ROI : not possible to compute a volume!", nil);
        return 0;
    }
    
    if( volume < 0) volume = -volume;
    
    return volume;
}
#endif

-(void) updateVolumeData: (NSNotification*) note
{
    if( [note object] == pixList[ curMovieIndex])
    {
        float iwl, iww;
        
        [imageView getWLWW:&iwl :&iww];
        
        for( int y = 0; y < maxMovieIndex; y++)
        {
            for( DCMPix *p in pixList[ y])
                [p changeWLWW:iwl :iww];	//recompute WLWW
            
            for( NSArray *r in roiList[ y])
            {
                for( ROI *roi in r)
                    [roi recompute];
            }
        }
        
        [imageView setWLWW:iwl :iww];
    }
}

- (void) viewerControllerInit
{
    BOOL matrixVisible = [[NSUserDefaults standardUserDefaults] boolForKey: @"SeriesListVisible"];
    
    [[self window] zoom: self];
    
    numberOf2DViewer++;
    
    @synchronized( arrayOf2DViewers)
    {
        if( arrayOf2DViewers == nil)
            arrayOf2DViewers = [[NSMutableArray alloc] init];
        
        [arrayOf2DViewers addObject: self];
    }
    
    if( numberOf2DViewer > 1 || [[NSUserDefaults standardUserDefaults] boolForKey: @"USEALWAYSTOOLBARPANEL2"] == YES)
    {
        if( [AppController USETOOLBARPANEL] == NO)
        {
            [AppController setUSETOOLBARPANEL: YES];
            
            for( NSWindow *win in [NSApp windows])
            {
                if( [[win windowController] isKindOfClass:[ViewerController class]])
                {
                    if( [win toolbar])
                        [win setToolbar: nil];
                }
            }
        }
    }
    
    roiLock = [[NSRecursiveLock alloc] init];
    
    factorPET2SUV = 1.0;
    
    subCtrlMaskID = -2;
    maxMovieIndex = 1;
    
    [curCLUTMenu release];
    [curConvMenu release];
    [curWLWWMenu release];
    
    curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
    curConvMenu = [NSLocalizedString(@"No Filter", nil) retain];
    curWLWWMenu = [NSLocalizedString(@"Default WL & WW", nil) retain];
    
    direction = 1;
    
    [[self window] center];
    
    [[self window] setDelegate:self];
    
    [wlwwPopup setTitle:NSLocalizedString(@"Default WL & WW", nil)];
    [convPopup setTitle:NSLocalizedString(@"No Filter", nil)];
    curOpacityMenu = [NSLocalizedString(@"Linear Table", nil) retain];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(applicationDidResignActive:) name:NSApplicationDidResignActiveNotification object:nil];
    [nc addObserver:self selector:@selector(UpdateWLWWMenu:) name:OsirixUpdateWLWWMenuNotification object:nil];
    //	[nc	addObserver:self selector:@selector(Display3DPoint:) name:OsirixDisplay3dPointNotification object:nil];
    [nc addObserver:self selector:@selector(ViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(ViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:nil];
    
    [nc addObserver:self selector:@selector(revertSeriesNotification:) name:OsirixRevertSeriesNotification object:nil];
    [nc addObserver:self selector:@selector(updateVolumeData:) name:OsirixUpdateVolumeDataNotification object:nil];
    [nc addObserver:self selector:@selector(roiChange:) name:OsirixROIChangeNotification object:nil];
    [nc addObserver:self selector:@selector(OpacityChanged:) name:OsirixOpacityChangedNotification object:nil];
    [nc addObserver:self selector:@selector(defaultToolModified:) name:OsirixDefaultToolModifiedNotification object:nil];
    [nc addObserver:self selector:@selector(defaultRightToolModified:) name:OsirixDefaultRightToolModifiedNotification object:nil];
    [nc addObserver:self selector:@selector(UpdateConvolutionMenu:) name:OsirixUpdateConvolutionMenuNotification object:nil];
    [nc addObserver:self selector:@selector(CLUTChanged:) name:OsirixCLUTChangedNotification object:nil];
    [nc addObserver:self selector:@selector(UpdateCLUTMenu:) name:OsirixUpdateCLUTMenuNotification object:nil];
    [nc addObserver:self selector:@selector(UpdateOpacityMenu:) name:OsirixUpdateOpacityMenuNotification object:nil];
    [nc addObserver:self selector:@selector(CloseViewerNotification:) name:OsirixCloseViewerNotification object:nil];
    [nc addObserver:self selector:@selector(recomputeROI:) name:OsirixRecomputeROINotification object:nil];
    [nc addObserver:self selector:@selector(notificationStopPlaying:) name:OsirixStopPlayingNotification object:nil];
    //	[nc addObserver:self selector:@selector(notificationiChatBroadcast:) name:OsirixChatBroadcastNotification object:nil];
    [nc addObserver:self selector:@selector(notificationSyncSeries:) name:OsirixSyncSeriesNotification object:nil];
    [nc	addObserver:self selector:@selector(exportTextFieldDidChange:) name:NSControlTextDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(updateReportToolbarIcon:) name:OsirixReportModeChangedNotification object:nil];
    [nc addObserver:self selector:@selector(updateReportToolbarIcon:) name:OsirixDeletedReportNotification object:nil];
    [nc addObserver:self selector:@selector(reportToolbarItemWillPopUp:) name:NSPopUpButtonWillPopUpNotification object:nil];
    
    
    NSMutableArray *draggedTypes = [NSMutableArray arrayWithObject:NSFilenamesPboardType];
    [draggedTypes addObjectsFromArray:BrowserController.DatabaseObjectXIDsPasteboardTypes];
    [draggedTypes addObjectsFromArray:DCMView.PasteboardTypes];
    [draggedTypes addObjectsFromArray:DCMView.PluginPasteboardTypes];
    [[self window] registerForDraggedTypes:draggedTypes];
    
    if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
    {
        if( [[self modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"]))
        {
            if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                [self ApplyCLUTString: @"B/W Inverse"];
            else
                [self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
        }
        
        if( [[self modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpacityTableNM"] == YES && [[self modality] isEqualToString:@"NM"]))
        {
            if( [[NSUserDefaults standardUserDefaults] boolForKey:@"PETOpacityTable"])
                [self ApplyOpacityString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default Opacity Table"]];
        }
        
        if(([[self modality] isEqualToString:@"CR"] || [[self modality] isEqualToString:@"MG"] || [[self modality] isEqualToString:@"XA"] || [[self modality] isEqualToString:@"RF"]) && [[NSUserDefaults standardUserDefaults] boolForKey:@"automatic12BitTotoku"] && [AppController canDisplay12Bit])
        {
            [imageView setIsLUT12Bit:YES];
            [display12bitToolbarItemMatrix selectCellWithTag:0];
        }
    }
    
    //
    for( int i = 0; i < [popupRoi numberOfItems]; i++)
    {
        if( [[popupRoi itemAtIndex: i] image] == nil)
        {
            [[popupRoi itemAtIndex: i] setImage: [self imageForROI: [[popupRoi itemAtIndex: i] tag]]];
            [[[popupRoi itemAtIndex: i] image] setSize:ToolsMenuIconSize];
        }
    }
    
    for( int i = 0; i < [ReconstructionRoi numberOfItems]; i++)
    {
        if( [[ReconstructionRoi itemAtIndex: i] image] == nil)
        {
            switch( [[ReconstructionRoi itemAtIndex: i] tag])
            {
                case 1:	[[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"MPR"]];				break;
                case 2:	[[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"MPR3D"]];				break;
                case 3: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"MIP"]];				break;
                case 4: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"VolumeRendering"]];	break;
                case 5: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"Surface"]];			break;
                case 6: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"VolumeRendering"]];	break;
                case 7:
                    //				if( [VRPROController available] == NO)
                {
                    [ReconstructionRoi removeItemAtIndex: i];
                    i--;
                }
                    //				else
                    //					[[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"VolumeRendering"]];
                    break;
                case 8: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"orthogonalReslice"]];	break;
                case 9: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"Endoscopy"]];	break;
                case 10: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"MPR"]];	break;
            }
        }
    }
    
    [[self window] setInitialFirstResponder: imageView];
    
    NSNumber	*status = [[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] valueForKeyPath:@"series.study.stateText"];
    
    if( status == nil) [StatusPopup selectItemWithTitle: @"empty"];
    else [StatusPopup selectItemWithTag: [status intValue]];
    
    NSString *com = [[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] valueForKeyPath:@"series.comment"];//JF20070103
    
    if( com == nil || [com isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"Add a comment", nil)];
    else [CommentsField setTitle: com];
    
    [previewMatrixScrollView setPostsFrameChangedNotifications:YES];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"] == NO && [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"] == NO)
        [self setMatrixVisible: matrixVisible];
    
    [[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: @"SeriesListVisible" options:NSKeyValueObservingOptionNew context:nil];
    
    originalOrientation = -1;
    [orientationMatrix setEnabled: NO];
}

#ifndef OSIRIX_LIGHT
- (IBAction) Panel3D:(id) sender
{
    long i;
    
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( [self isDataVolumicIn4D: YES] == NO)
    {
        NSRunAlertPanel(NSLocalizedString(@"Volume Rendering", nil), NSLocalizedString(@"Volume Rendering requires volumic data.", nil), nil, nil, nil);
        return;
    }
    
    if( [self computeInterval] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        [self displayAWarningIfNonTrueVolumicData];
        [self displayWarningIfGantryTitled];
        
        [self MovieStop: self];
        
        NSArray *viewers = [[AppController sharedAppController] FindRelatedViewers:pixList[0]];
        
        VRController *viewer = nil;
        
        for( NSWindowController *v in viewers)
        {
            if( [v.windowNibName isEqualToString: @"VR"])
            {
                VRController *vv = (VRController*) v;
                
                if( [vv.style isEqualToString: @"panel"])
                    viewer = vv;
            }
        }
        
        if( viewer)
        {
            [[viewer window] makeKeyAndOrderFront:self];
        }
        else
        {
            viewer = [[VRController alloc] initWithPix:pixList[curMovieIndex] :fileList[0] :volumeData[ 0] :blendingController :self style:@"panel" mode:@"MIP"];
            for( i = 1; i < maxMovieIndex; i++)
            {
                [viewer addMoviePixList:pixList[ i] :volumeData[ i]];
            }
            
            if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
            {
                if( [[self modality] isEqualToString:@"PT"])
                {
                    if( [[imageView curDCM] SUVConverted] == YES)
                    {
                        [viewer setWLWW: 3 : 6];
                    }
                    else
                    {
                        [viewer setWLWW:[[pixList[0] objectAtIndex: 0] maxValueOfSeries]/4 : [[pixList[0] objectAtIndex: 0] maxValueOfSeries]/2];
                    }
                }
            }
            
            [viewer load3DState];
            
            if( [[self modality] isEqualToString:@"PT"] && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
            {
                if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                    [viewer ApplyCLUTString: @"B/W Inverse"];
                else
                    [viewer ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
                
                [viewer ApplyOpacityString: @"Logarithmic Table"];
            }
            else
            {
                float   iwl, iww;
                [imageView getWLWW:&iwl :&iww];
                [viewer setWLWW:iwl :iww];
            }
            
            [[viewer window] setFrameOrigin: [[[self window] screen] visibleFrame].origin];
            [viewer showWindow:self];
            [[viewer window] makeKeyAndOrderFront:self];
            [[viewer window] display];
            [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
        }
    }
}
#endif

#ifndef OSIRIX_LIGHT
-(IBAction) segmentationTest:(id) sender
{
    BOOL volumicData = [self isDataVolumicIn4D: NO];
    
    if( volumicData == NO)
        // Force 2D mode
        [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"growingRegionType"];
    else
        [self displayAWarningIfNonTrueVolumicData];
    
    [self clear8bitRepresentations];
    
    float ci = [self computeInterval];
    
    if( [pixList[ curMovieIndex] count] <= 1) ci = 1;
    
    if( ci == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        ITKSegmentation3DController *itk = [[ITKSegmentation3DController alloc] initWithViewer: self];
        if( itk)
        {
            [itk showWindow:self];
            [[itk window] makeKeyAndOrderFront:self];
        }
    }
}
#endif

#ifndef OSIRIX_LIGHT
- (VRController *)openVRViewerForMode:(NSString *)mode
{
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_3DVOL_LAUNCHED detail:[NSString stringWithFormat:@"{\"Mode\": \"%@\"}",mode]];
    
    long i;
    
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];	
    [self MovieStop: self];
    
    NSArray *viewers = [[AppController sharedAppController] FindRelatedViewers:pixList[0]];
    
    VRController *viewer = nil;
    
    for( NSWindowController *v in viewers)
    {
        if( [v.windowNibName isEqualToString: @"VR"])
        {
            VRController *vv = (VRController*) v;
            
            if( [vv.style isEqualToString: @"standard"] && ([vv.renderingMode isEqualToString:@"VR"] || [vv.renderingMode isEqualToString:@"MIP"]))
                viewer = vv;
        }
    }
    
    if( viewer)
    {
        return viewer;
    }
    else
    {
        viewer = [[VRController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[ 0] :blendingController :self style:@"standard" mode: mode];
        for( i = 1; i < maxMovieIndex; i++)
        {
            [viewer addMoviePixList:pixList[ i] :volumeData[ i]];
        }
        
        if( [[self modality] isEqualToString:@"PT"] && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
        {
            if( [[imageView curDCM] SUVConverted] == YES)
            {
                [viewer setWLWW: 2 : 6];
            }
            else
            {
                [viewer setWLWW:[[pixList[0] objectAtIndex: 0] maxValueOfSeries]/2 : [[pixList[0] objectAtIndex: 0] maxValueOfSeries]];
            }
            
            if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                [viewer ApplyCLUTString: @"B/W Inverse"];
            else
                [viewer ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
            
            [viewer ApplyOpacityString: @"Logarithmic Table"];
        }
        else
        {
            float   iwl, iww;
            [imageView getWLWW:&iwl :&iww];
            [viewer setWLWW:iwl :iww];
        }
    }
    return viewer;
}
#endif

- (NSScreen*) get3DViewerScreen: (ViewerController*) v
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ThreeDViewerOnAnotherScreen"])
    {
        NSArray		*allScreens = [NSScreen screens];
        
        for( id loopItem in allScreens)
        {
            if( [[[v window] screen] frame].origin.x != [loopItem frame].origin.x || [[[v window] screen] frame].origin.y != [loopItem frame].origin.y)
            {
                return loopItem;
            }
        }
        
        return [[v window] screen];
    }
    else
    {
        return [[v window] screen];
    }
}

- (void) place3DViewerWindow:(NSWindowController*) viewer
{
    [[viewer window] setFrame: [[self get3DViewerScreen: self] visibleFrame] display:NO];
}

#ifndef OSIRIX_LIGHT
-(IBAction) VRViewer:(id) sender
{
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( [self isDataVolumicIn4D: YES] == NO)
    {
        NSRunAlertPanel(NSLocalizedString(@"Volume Rendering", nil), NSLocalizedString(@"Volume Rendering requires volumic data.", nil), nil, nil, nil);
        return;
    }
    
    if( [self computeInterval] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        [self displayAWarningIfNonTrueVolumicData];
        
        [self displayWarningIfGantryTitled];
        
        if( [curConvMenu isEqualToString:NSLocalizedString(@"No Filter", nil)] == NO)
        {
            if( NSRunInformationalAlertPanel( NSLocalizedString(@"Convolution", nil), NSLocalizedString(@"Should I apply current convolution filter on raw data? 2D/3D post-processing viewers can only display raw data.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                [self applyConvolutionOnSource: self];
        }
        
        [self MovieStop: self];
        
        NSArray *viewers = [[AppController sharedAppController] FindRelatedViewers:pixList[0]];
        
        VRController *viewer = nil;
        
        for( NSWindowController *v in viewers)
        {
            if( [v.windowNibName isEqualToString: @"VR"])
            {
                VRController *vv = (VRController*) v;
                
                if( [vv.style isEqualToString: @"standard"])
                    viewer = vv;
            }
        }
        
        if( viewer)
        {
            [[viewer window] makeKeyAndOrderFront:self];
            if( [sender tag] == 3) 
                [viewer setModeIndex: 1];
            else
                [viewer setModeIndex: 0];
        }
        else
        {
            NSString	*mode;
            if( [sender tag] == 3) mode = @"MIP";
            else mode = @"VR";
            viewer = [self openVRViewerForMode:mode];
            
            NSString *c;
            
            if( backCurCLUTMenu) c = backCurCLUTMenu;
            else c = curCLUTMenu;
            
            [viewer ApplyCLUTString: c];
            float   iwl, iww;
            [imageView getWLWW:&iwl :&iww];
            [viewer setWLWW:iwl :iww];
            [self place3DViewerWindow: viewer];
            [viewer load3DState];
            [viewer showWindow:self];			
            [[viewer window] makeKeyAndOrderFront:self];
            [[viewer window] display];
            [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
        }
    }
}

- (SRController *)openSRViewer
{
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_3DSUR_LAUNCHED detail:@"{}"];
    
    SRController *viewer;
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    if ((viewer = [[AppController sharedAppController] FindViewer :@"SR" :pixList[0]]))
        return viewer;
    viewer = [[SRController alloc] initWithPix:pixList[curMovieIndex] :fileList[0] :volumeData[curMovieIndex] :blendingController :self];
    return viewer;
    
}

-(IBAction) SRViewer:(id) sender
{
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( [self isDataVolumicIn4D: YES] == NO)
    {
        NSRunAlertPanel(NSLocalizedString(@"Surface Rendering", nil), NSLocalizedString(@"Surface Rendering requires volumic data.", nil), nil, nil, nil);
        return;
    }
    
    if( [self computeInterval] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        [self displayAWarningIfNonTrueVolumicData];
        [self displayWarningIfGantryTitled];
        
        [self MovieStop: self];
        
        SRController *viewer = [[AppController sharedAppController] FindViewer :@"SR" :pixList[0]];
        
        if( viewer)
        {
            [[viewer window] makeKeyAndOrderFront:self];
        }
        else
        {
            viewer = [self openSRViewer];
            [self place3DViewerWindow: viewer];
            //			[[viewer window] performZoom:self];
            [viewer showWindow:self];
            [[viewer window] makeKeyAndOrderFront:self];
            [viewer ChangeSettings:self];
            [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
        }
    }
}
#endif

- (OrthogonalMPRViewer *)openOrthogonalMPRViewer
{
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_2DMPR_LAUNCHED detail:@"{}"];
    
    OrthogonalMPRViewer *viewer;
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( blendingController)
    {
        viewer = [[AppController sharedAppController] FindViewer :@"PETCT" :pixList[0]];
    }
    else
    {
        viewer = [[AppController sharedAppController] FindViewer :@"OrthogonalMPR" :pixList[0]];
    }
    if (viewer)
        return viewer;
    
    viewer = [[OrthogonalMPRViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :self :nil];
    
    float sww = imageView.curWW;
    float swl = imageView.curWL;
    
    NSString *c;
    
    if( backCurCLUTMenu) c = backCurCLUTMenu;
    else c = curCLUTMenu;
    
    if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
    {
        if( [[self modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"]))
        {
            if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
                [viewer ApplyCLUTString: @"B/W Inverse"];
            else
                [viewer ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
        }
        else [viewer ApplyCLUTString: c];
    }
    else [viewer ApplyCLUTString: c];
    
    [viewer ApplyOpacityString: curOpacityMenu];
    
    [viewer setWLWW: swl :sww];
    
    return viewer;
}

#ifndef OSIRIX_LIGHT
- (OrthogonalMPRPETCTViewer *)openOrthogonalMPRPETCTViewer
{
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_2DMPR_LAUNCHED detail:@"{}"];
    
    OrthogonalMPRPETCTViewer  *viewer;
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if ((viewer = [[AppController sharedAppController] FindViewer :@"PETCT" :pixList[0]]))
        return viewer;
    
    if (blendingController)
    {
        float orientA[9], orientB[9];
        
        [[[self imageView] curDCM] orientation:orientA];
        [[[blendingController imageView] curDCM] orientation:orientB];
        
        if( [DCMView angleBetweenVector: orientA+6 andVector:orientB+6] > [[NSUserDefaults standardUserDefaults] floatForKey: @"PARALLELPLANETOLERANCE"])  // Planes are not paralel!
        {
            NSRunCriticalAlertPanel(NSLocalizedString(@"2D Planes",nil),NSLocalizedString(@"These 2D planes are not parallel, you cannot use the 2D Orthogonal MPR viewer. Instead, try the 3D MPR viewer.",nil), NSLocalizedString(@"OK",nil), nil, nil);
        }
        else
        {
            viewer = [[OrthogonalMPRPETCTViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :self : blendingController];
            [self place3DViewerWindow: viewer];
            
            NSString *c;
            
            if( backCurCLUTMenu) c = backCurCLUTMenu;
            else c = curCLUTMenu;
            
            [[viewer CTController] ApplyCLUTString: c];
            [[viewer PETController] ApplyCLUTString: [blendingController curCLUTMenu]];
            [[viewer PETCTController] ApplyCLUTString: c];
            
            [[viewer CTController] ApplyOpacityString: curOpacityMenu];
            [[viewer PETController] ApplyOpacityString:[blendingController curOpacityMenu]];
            [[viewer PETCTController] ApplyOpacityString: curOpacityMenu];
            
            [(OrthogonalMPRPETCTView*)[[viewer PETCTController] originalView] setCurCLUTMenu: [blendingController curCLUTMenu]];
            [(OrthogonalMPRPETCTView*)[[viewer PETCTController] xReslicedView] setCurCLUTMenu: [blendingController curCLUTMenu]];
            [(OrthogonalMPRPETCTView*)[[viewer PETCTController] yReslicedView] setCurCLUTMenu: [blendingController curCLUTMenu]];
            
            [(OrthogonalMPRPETCTView*)[[viewer PETCTController] originalView] setCurOpacityMenu: [blendingController curOpacityMenu]];
            [(OrthogonalMPRPETCTView*)[[viewer PETCTController] xReslicedView] setCurOpacityMenu: [blendingController curOpacityMenu]];
            [(OrthogonalMPRPETCTView*)[[viewer PETCTController] yReslicedView] setCurOpacityMenu: [blendingController curOpacityMenu]];
            
            [viewer showWindow:self];
            
            float   iwl, iww;
            [imageView getWLWW:&iwl :&iww];
            [[viewer CTController] setWLWW:iwl :iww];
            [[blendingController imageView] getWLWW:&iwl :&iww];
            [[viewer PETController] setWLWW:iwl :iww];
            
            [viewer setBlendingMode: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTPETFUSION"]];
            
            return viewer;
        }
    }
    return nil;	
}
#endif

-(IBAction) orthogonalMPRViewer:(id) sender
{
    
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( [self computeInterval] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        if( [self isDataVolumicIn4D: YES] == NO) // || [[imageView curDCM] isRGB] == YES)
        {
            NSRunAlertPanel(NSLocalizedString(@"MPR", nil), NSLocalizedString(@"MPR requires volumic data.", nil), nil, nil, nil);
            return;
        }
        
        [self displayAWarningIfNonTrueVolumicData];
        [self displayWarningIfGantryTitled];
        
        [blendingController displayAWarningIfNonTrueVolumicData];
        [blendingController displayWarningIfGantryTitled];
        
        [self MovieStop: self];
        
        OrthogonalMPRViewer *viewer;
        
        if( blendingController)
        {
            viewer = [[AppController sharedAppController] FindViewer :@"PETCT" :pixList[0]];
        }
        else
        {
            viewer = [[AppController sharedAppController] FindViewer :@"OrthogonalMPR" :pixList[0]];
        }
        
        if( viewer)
        {
            [[viewer window] makeKeyAndOrderFront:self];
        }
        else
        {
#ifndef OSIRIX_LIGHT
            if( blendingController)
            {
                OrthogonalMPRPETCTViewer *pcviewer = [self openOrthogonalMPRPETCTViewer];
                NSDate *studyDate = [[fileList[curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.study.date"];
                
                [[pcviewer window] setTitle: [NSString stringWithFormat:@"%@: %@ - %@", [[pcviewer window] title], [[NSUserDefaults dateTimeFormatter] stringFromDate:studyDate], [[self window] title]]];
            }
            else
#endif
            {
                viewer = [self openOrthogonalMPRViewer];
                
                [self place3DViewerWindow: viewer];
                [viewer showWindow:self];
                
                float   iwl, iww;
                [imageView getWLWW:&iwl :&iww];
                [viewer setWLWW:iwl :iww];
                
                [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@ - %@", [[viewer window] title], [NSUserDefaults formatDateTime: [[fileList[0] objectAtIndex:0]  valueForKeyPath:@"series.study.date"]], [[self window] title]]];
            }
        }
    }
}

#ifndef OSIRIX_LIGHT
- (EndoscopyViewer *)openEndoscopyViewer
{
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_3DEND_LAUNCHED detail:@"{}"];
    
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    EndoscopyViewer *viewer;
    
    viewer = [[AppController sharedAppController] FindViewer :@"Endoscopy" :pixList[0]];
    if (viewer)
        return viewer;
    
    viewer = [[EndoscopyViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :blendingController : self];
    return viewer;
}


-(IBAction) endoscopyViewer:(id) sender
{
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( [self computeInterval] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        if( [self isDataVolumicIn4D: YES] == NO)
        {
            NSRunAlertPanel(NSLocalizedString(@"Endoscopy", nil), NSLocalizedString(@"Endoscopy requires volumic data.", nil), nil, nil, nil);
            return;
        }
        
        [self displayAWarningIfNonTrueVolumicData];
        [self displayWarningIfGantryTitled];
        
        [self MovieStop: self];
        
        EndoscopyViewer *viewer;
        
        viewer = [[AppController sharedAppController] FindViewer :@"Endoscopy" :pixList[0]];
        
        if( viewer)
        {
            [[viewer window] makeKeyAndOrderFront:self];
        }
        else
        {
            viewer = [self openEndoscopyViewer];
            [self place3DViewerWindow: viewer];
            [viewer showWindow:self];
            [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
        }
    }
}
#endif

//-(IBAction) MIPViewer:(id) sender
//{
//	long i;
//	
//	[self checkEverythingLoaded];
//	[self clear8bitRepresentations];
//	
//	if( [self computeInterval] == 0 ||
//		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
//		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
//		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
//	{
//		[self SetThicknessInterval:sender];
//	}
//	else
//	{
//		MIPController *viewer = [[AppController sharedAppController] FindViewer :@"MIP" :pixList[0]];
//		
//		if( viewer)
//		{
//			[[viewer window] makeKeyAndOrderFront:self];
//		}
//		else
//		{
//			viewer = [[MIPController alloc] initWithPix :pixList[curMovieIndex] :fileList[0] :volumeData[curMovieIndex] :blendingController];
//			for( i = 1; i < maxMovieIndex; i++)
//			{
//				[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
//			}
//			
//			[viewer ApplyCLUTString:curCLUTMenu];
//			long   iwl, iww;
//			[imageView getWLWW:&iwl :&iww];
//			[viewer setWLWW:iwl :iww];
//			[viewer load3DState];
//			[viewer showWindow:self];
//			[[viewer window] makeKeyAndOrderFront:self];
//		}
//	}
//}

#ifndef OSIRIX_LIGHT
- (MPRController *)openMPRViewer
{
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_3DMPR_LAUNCHED detail:@"{}"];
    
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    MPRController *viewer;
    viewer = [[AppController sharedAppController] FindViewer:@"MPR" :pixList[0]];
    if (viewer)
        return viewer;
    
    viewer = [[MPRController alloc] initWithDCMPixList:pixList[0]
                                             filesList:fileList[0]
                                            volumeData:volumeData[0]
                                      viewerController:self
                                 fusedViewerController:blendingController];
    for( int i = 1; i < maxMovieIndex; i++)
    {
        [viewer addMoviePixList:pixList[ i] :volumeData[ i]];
    }
    
    return viewer;
}


- (IBAction) mprViewer:(id) sender
{
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( [self computeInterval] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        if( [self isDataVolumicIn4D: YES] == NO) // || [[imageView curDCM] isRGB] == YES)
        {
            NSRunAlertPanel(NSLocalizedString(@"MPR", nil), NSLocalizedString(@"MPR requires volumic data.", nil), nil, nil, nil);
            return;
        }
        
        [self displayAWarningIfNonTrueVolumicData];
        [self displayWarningIfGantryTitled];
        
        [self MovieStop: self];
        
        MPRController *viewer;
        
        viewer = [[AppController sharedAppController] FindViewer :@"MPR" :pixList[0]];
        
        if( viewer)
        {
            [[viewer window] makeKeyAndOrderFront:self];
        }
        else
        {
            viewer = [self openMPRViewer];
            [self place3DViewerWindow:viewer];
            [viewer showWindow:self];
            [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [viewer showWindow:self];
                [viewer showWindow:self];
            });

        }
    }
}

/** Action to open the CPRViewer */
- (CPRController *)openCPRViewer
{
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_3DCPR_LAUNCHED detail:@"{}"];
    
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    CPRController *viewer;
    viewer = [[AppController sharedAppController] FindViewer:@"CPR" :pixList[0]];
    if (viewer)
        return viewer;
    
    viewer = [[CPRController alloc] initWithDCMPixList:pixList[0] filesList:fileList[0] volumeData:volumeData[0] viewerController:self fusedViewerController:blendingController];
    for( int i = 1; i < maxMovieIndex; i++)
    {
        [viewer addMoviePixList:pixList[ i] :volumeData[ i]];
    }
    
    return viewer;
}


- (IBAction) cprViewer:(id) sender
{
    [self checkEverythingLoaded];
    [self clear8bitRepresentations];
    
    if( [self computeInterval] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
       [[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
       ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [self SetThicknessInterval:sender];
    }
    else
    {
        if( [self isDataVolumicIn4D: YES] == NO || [[imageView curDCM] isRGB] == YES)
        {
            NSRunAlertPanel(NSLocalizedString(@"CPR", nil), NSLocalizedString(@"CPR requires volumic data and BW images.", nil), nil, nil, nil);
            return;
        }
        
        [self displayAWarningIfNonTrueVolumicData];
        [self displayWarningIfGantryTitled];
        
        [self MovieStop: self];
        
        CPRController *viewer;
        
        viewer = [[AppController sharedAppController] FindViewer :@"CPR" :pixList[0]];
        
        if( viewer)
        {
            [[viewer window] makeKeyAndOrderFront:self];
        }
        else
        {
            id waitWindow = [self startWaitWindow:NSLocalizedString(@"Loading...",nil)];
            viewer = [self openCPRViewer];
            [self place3DViewerWindow:viewer];
            [viewer showWindow:self];
            [[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [viewer showWindow:self];
                [viewer showWindow:self];
                [self endWaitWindow:waitWindow];
            });
        }
    }
}

#endif

#pragma mark-
#pragma mark 4.5.4 Study navigation


-(IBAction) loadPatient:(id) sender
{
    if( windowWillClose) return;
    
    if( delayedTileWindows)
    {
        delayedTileWindows = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
        [[AppController sharedAppController] tileWindows: nil];
    }
    
    [[BrowserController currentBrowser] loadNextPatient:[fileList[0] objectAtIndex:0] :[sender tag] :self :YES keyImagesOnly: displayOnlyKeyImages];
}

-(void) loadSeries:(NSNumber*) t
{
    if( windowWillClose) return;
    
    int dir = [t intValue];
    
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:@"nextSeriesToAllViewers"];
    
    if( b)
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"nextSeriesToAllViewers"];
    
    int curImage;
    
    if( dir == -1)
    {
        if( [imageView flippedData]) curImage = 0;
        else curImage = (long)[[imageView dcmPixList] count]-1;
    }
    else
    {
        if( [imageView flippedData]) curImage = (long)[[imageView dcmPixList] count]-1;
        else curImage = 0;
    }
    [imageView setIndex: curImage];
    
    [[BrowserController currentBrowser] loadNextSeries:[fileList[0] objectAtIndex:0] :dir :self :YES keyImagesOnly: displayOnlyKeyImages];
    
    if( dir == -1)
    {
        if( [imageView flippedData]) curImage = 0;
        else curImage = (long)[[imageView dcmPixList] count]-1;
    }
    else
    {
        if( [imageView flippedData]) curImage = (long)[[imageView dcmPixList] count]-1;
        else curImage = 0;
    }
    
    [imageView setIndex: curImage];
    [self adjustSlider];
    [imageView sendSyncMessage: 0];
    [imageView setNeedsDisplay: YES];
    
    if( b)
        [[NSUserDefaults standardUserDefaults] setBool: b forKey:@"nextSeriesToAllViewers"];
}

-(void) loadSeriesUp
{
    if( windowWillClose) return;
    
    [self loadSeries: [NSNumber numberWithInt: 1]];
}

-(void) loadSeriesDown
{
    if( windowWillClose) return;
    
    [self loadSeries: [NSNumber numberWithInt: -1]];
}

-(IBAction) loadSerie:(id) sender
{
    if( windowWillClose) return;
    
    if( delayedTileWindows)
    {
        delayedTileWindows = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
        [[AppController sharedAppController] tileWindows: nil];
    }
    // tag=-1 backwards, tag=1 forwards, tag=3 ???
    if( [sender tag] == 3)
    {
        [[sender selectedItem] setImage:nil];
        
        [[BrowserController currentBrowser] loadSeries :[[[sender selectedItem] representedObject] object] :self :YES keyImagesOnly: displayOnlyKeyImages];
    }
    else
    {
        [[BrowserController currentBrowser] loadNextSeries:[fileList[0] objectAtIndex:0] :[sender tag] :self :YES keyImagesOnly: displayOnlyKeyImages];
    }
}

- (BOOL) isEverythingLoaded
{
    if (loadingThread)
    {
        @synchronized( loadingThread)
        {
            if( loadingThread)
                return !loadingThread.isExecuting;
        }
    }
    
    if( [[pixList[0] objectAtIndex: pixList[0].count/2] isLoaded] == NO) // The loadingThread was maybe not yet created...
        return NO;
    
    return YES;
}

-(void) checkEverythingLoaded
{
    BOOL isExecuting;
    
    @synchronized( loadingThread)
    {
        if( loadingThread)
            isExecuting = loadingThread.isExecuting && requestLoadingCancel == NO;
        else
            isExecuting = NO;
    }
    
    if( isExecuting)
    {
        checkEverythingLoaded = YES;
        
        Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Data loading...", nil)];
        [splash showWindow:self];
        
        {
            BOOL isExecuting;
            int percentage = 0, lastPercentage = 0;
            
            do
            {
                [NSThread sleepForTimeInterval: 0.1];
                
                @synchronized( loadingThread)
                {
                    isExecuting = loadingThread.isExecuting && requestLoadingCancel == NO;
                    percentage = [[loadingThread.threadDictionary objectForKey: @"loadingPercentage"] floatValue] * 100.;
                }
                
                if(isExecuting && percentage != lastPercentage)
                {
                    [self setWindowTitle: self];
                    [[self window] display];
                    
                    [splash incrementBy: percentage - lastPercentage];
                    lastPercentage = percentage;
                }
            }
            while( isExecuting);
        }
        
        [splash close];
        [splash autorelease];
        
        [self setWindowTitle: self];
        
        checkEverythingLoaded = NO;
        
        if (blendingController && blendingController->requestLoadingCancel == NO)
            [blendingController checkEverythingLoaded];
    }
    
    if (windowWillClose == NO && requestLoadingCancel == NO)
        [self computeInterval];
}

-(void) executeRevert
{
    [self checkEverythingLoaded];
    
    for( int x = 0; x < maxMovieIndex; x++)
    {
        for( int i = 0 ; i < [pixList[ x] count]; i++)
        {
            DCMPix* pix = [pixList[ x] objectAtIndex: i];
            [pix revert];
        }
    }
    
    [self startLoadImageThread];
    
    [imageView updatePresentationStateFromSeries];
    
    [self checkEverythingLoaded];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList[ curMovieIndex] userInfo: nil];
}

-(void) revertSeries:(id) sender
{
    if( postprocessed)
    {
        NSRunAlertPanel(NSLocalizedString(@"Revert", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot revert it.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        
        return;
    }
    
    [self executeRevert];
}

-(void) revertSeriesNotification:(id) note
{
    long x;
    
    for( x = 0; x < maxMovieIndex; x++)
    {
        if( [note object] == pixList[ x])
        {
            [self revertSeries:self];
        }
    }
}

#pragma mark key image

- (IBAction) keyImageCheckBox:(id) sender
{
    if( postprocessed == NO)
    {
        [[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[NSNumber numberWithBool:[sender state]] forKey:@"isKeyImage"];
        
        if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
        {
            [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[NSNumber numberWithBool:[sender state]] forKey:@"isKeyImage"];
        }
        
        [self willChangeValueForKey: @"KeyImageCounter"];
        [self didChangeValueForKey: @"KeyImageCounter"];
        
        [self buildMatrixPreview: NO];
        
        [imageView setNeedsDisplay:YES];
        
        [[[BrowserController currentBrowser] database] save:nil];
    }
}

- (IBAction) findNextPreviousKeyImage:(id)sender
{
    if( postprocessed)
    {
        NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot create/modify/search key images. Revert to the original series or create a secondary capture series to do this.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    [self checkEverythingLoaded];
    
    BOOL tag = [sender tag];
    
    if( [imageView flippedData]) tag = !tag;
    
    if( tag == 0)
    {
        // First find in this series
        for( int i = [imageView curImage]+1; i < [fileList[ curMovieIndex] count]; i++)
        {
            NSManagedObject *image = [fileList[ curMovieIndex] objectAtIndex: i];
            
            if( [[image valueForKey:@"isKeyImage"] boolValue])
            {
                [imageView setIndex: i];
                [imageView sendSyncMessage: 0];
                [self adjustSlider];
                [imageView displayIfNeeded];
                return;
            }
        }
    }
    else
    {
        for( int i = [imageView curImage]-1; i >= 0 ; i--)
        {
            NSManagedObject *image = [fileList[ curMovieIndex] objectAtIndex: i];
            
            if( [[image valueForKey:@"isKeyImage"] boolValue])
            {
                [imageView setIndex: i];
                [imageView sendSyncMessage: 0];
                [self adjustSlider];
                [imageView displayIfNeeded];
                return;
            }
        }
    }
    
    if( [imageView flippedData]) tag = !tag; // We RE-inverse the tag !
    
    if( tag == 0)
    {
        //Nothing found -> search in next series
        NSArray *seriesArray = [[BrowserController currentBrowser] childrenArray: [[imageView seriesObj] valueForKey:@"study"]];
        
        NSUInteger indexOfObject = [seriesArray indexOfObject: [imageView seriesObj]];
        if( indexOfObject != NSNotFound)
        {
            for( int i = indexOfObject+1; i < seriesArray.count; i++)
            {
                if( [[[seriesArray objectAtIndex: i] keyImages] count])
                {
                    //Load this series
                    [[BrowserController currentBrowser] loadSeries :[seriesArray objectAtIndex: i] :self :YES keyImagesOnly: displayOnlyKeyImages];
                    
                    [self showCurrentThumbnail:self];
                    [self updateNavigator];
                    
                    if( [imageView flippedData])
                    {
                        for( int i = (long)[fileList[ curMovieIndex] count]-1; i >= 0 ; i--)
                        {
                            NSManagedObject *image = [fileList[ curMovieIndex] objectAtIndex: i];
                            
                            if( [[image valueForKey:@"isKeyImage"] boolValue])
                            {
                                [imageView setIndex: i];
                                [imageView sendSyncMessage: 0];
                                [self adjustSlider];
                                [imageView displayIfNeeded];
                                return;
                            }
                        }
                    }
                    else
                    {
                        for( int i = 0; i < [fileList[ curMovieIndex] count]; i++)
                        {
                            NSManagedObject *image = [fileList[ curMovieIndex] objectAtIndex: i];
                            
                            if( [[image valueForKey:@"isKeyImage"] boolValue])
                            {
                                [imageView setIndex: i];
                                [imageView sendSyncMessage: 0];
                                [self adjustSlider];
                                [imageView displayIfNeeded];
                                return;
                            }
                        }
                    }
                }
            }
        }
        
        NSBeep();
    }
    else
    {
        //Nothing found -> search in next series
        NSArray *seriesArray = [[BrowserController currentBrowser] childrenArray: [[imageView seriesObj] valueForKey:@"study"]];
        
        NSUInteger indexOfObject = [seriesArray indexOfObject: [imageView seriesObj]];
        if( indexOfObject != NSNotFound)
        {
            for( int i = indexOfObject-1; i >= 0; i++)
            {
                if( [[[seriesArray objectAtIndex: i] keyImages] count])
                {
                    //Load this series
                    [[BrowserController currentBrowser] loadSeries :[seriesArray objectAtIndex: i] :self :YES keyImagesOnly: displayOnlyKeyImages];
                    
                    [self showCurrentThumbnail:self];
                    [self updateNavigator];
                    
                    if( [imageView flippedData] == NO)
                    {
                        for( int i = (long)[fileList[ curMovieIndex] count]-1; i >= 0 ; i--)
                        {
                            NSManagedObject *image = [fileList[ curMovieIndex] objectAtIndex: i];
                            
                            if( [[image valueForKey:@"isKeyImage"] boolValue])
                            {
                                [imageView setIndex: i];
                                [imageView sendSyncMessage: 0];
                                [self adjustSlider];
                                [imageView displayIfNeeded];
                                return;
                            }
                        }
                    }
                    else
                    {
                        for( int i = 0; i < [fileList[ curMovieIndex] count]; i++)
                        {
                            NSManagedObject *image = [fileList[ curMovieIndex] objectAtIndex: i];
                            
                            if( [[image valueForKey:@"isKeyImage"] boolValue])
                            {
                                [imageView setIndex: i];
                                [imageView sendSyncMessage: 0];
                                [self adjustSlider];
                                [imageView displayIfNeeded];
                                return;
                            }
                        }
                    }
                }
            }
        }
        
        NSBeep();
    }
}

- (IBAction) keyImageDisplayButton:(id) sender
{
    if( postprocessed)
    {
        NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot create/modify/search key images. Revert to the original series or create a secondary capture series to do this.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    NSManagedObject	*series = [[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] valueForKey:@"series"];
    
    [self checkEverythingLoaded];
    
    displayOnlyKeyImages = [keyImagePopUpButton indexOfSelectedItem];
    if( series)
    {
        if(!displayOnlyKeyImages)
        {
            // ALL IMAGES ARE DISPLAYED			
            NSArray	*images = [[BrowserController currentBrowser] childrenArray: series];
            [[BrowserController currentBrowser] openViewerFromImages :[NSArray arrayWithObject: images] movie: NO viewer :self keyImagesOnly: displayOnlyKeyImages];
        }
        else
        {
            // ONLY KEY IMAGES
            NSArray	*images = [[BrowserController currentBrowser] childrenArray: series];
            NSArray *keyImagesArray = [NSArray array];
            
            for( NSManagedObject *image in images)
            {
                if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
                    keyImagesArray = [keyImagesArray arrayByAddingObject: image];
            }
            
            if( [keyImagesArray count] == 0)
            {
                NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"No key images have been selected in this series.", nil), nil, nil, nil);
                [keyImagePopUpButton selectItemAtIndex: 0];
            }
            else
            {
                [[BrowserController currentBrowser] openViewerFromImages :[NSArray arrayWithObject: keyImagesArray] movie: NO viewer :self keyImagesOnly: displayOnlyKeyImages];
                
            }
        }
    }
}

- (IBAction) setROIsImagesKeyImages:(id)sender
{
    if( postprocessed)
    {
        NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot create/modify/search key images. Revert to the original series or create a secondary capture series to do this.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    NSNumber *yes = [NSNumber numberWithBool: YES];
    
    for( int x = 0 ; x < maxMovieIndex ; x++)
    {
        for( int i = 0 ; i < [fileList[ x] count] ; i++)
        {
            NSManagedObject *o = [fileList[ x] objectAtIndex: i];
            if( [[roiList[ x] objectAtIndex: i] count])
                [o setValue: yes forKey:@"isKeyImage"];
        }
    }
    
    if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
    {
        for( int x = 0 ; x < maxMovieIndex ; x++)
        {
            for( int i = 0 ; i < [fileList[ x] count] ; i++)
            {
                NSManagedObject *o = [fileList[ x] objectAtIndex: i];
                if( [[roiList[ x] objectAtIndex: i] count])
                    [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:o setValue:yes forKey:@"isKeyImage"];
            }
        }
    }
    
    [self buildMatrixPreview: NO];
    [imageView setNeedsDisplay:YES];
    [[[BrowserController currentBrowser] database] save:nil];
    
    [self adjustKeyImage];
}

- (IBAction) setAllNonKeyImages:(id)sender
{
    if( postprocessed)
    {
        NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot create/modify/search key images. Revert to the original series or create a secondary capture series to do this.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    NSNumber *yes = [NSNumber numberWithBool: NO];
    
    for( int x = 0 ; x < maxMovieIndex ; x++)
        for( NSManagedObject *o in fileList[ x])
            [o setValue: yes forKey:@"isKeyImage"];
    
    if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
    {
        for( int x = 0 ; x < maxMovieIndex ; x++)
            for( NSManagedObject *o in fileList[ x])
                [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:o setValue:yes forKey:@"isKeyImage"];
    }
    
    [self willChangeValueForKey: @"KeyImageCounter"];
    [self didChangeValueForKey: @"KeyImageCounter"];
    
    [self buildMatrixPreview: NO];
    [imageView setNeedsDisplay:YES];
    [[[BrowserController currentBrowser] database] save:nil];
    
    [self adjustKeyImage];
}

- (IBAction) setAllKeyImages:(id)sender
{
    if( postprocessed)
    {
        NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot create/modify/search key images. Revert to the original series or create a secondary capture series to do this.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    NSNumber *yes = [NSNumber numberWithBool: YES];
    
    for( int x = 0 ; x < maxMovieIndex ; x++)
        for( NSManagedObject *o in fileList[ x])
            [o setValue: yes forKey:@"isKeyImage"];
    
    if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
    {
        for( int x = 0 ; x < maxMovieIndex ; x++)
            for( NSManagedObject *o in fileList[ x])
                [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:o setValue:yes forKey:@"isKeyImage"];
    }
    
    [self willChangeValueForKey: @"KeyImageCounter"];
    [self didChangeValueForKey: @"KeyImageCounter"];
    
    [self buildMatrixPreview: NO];
    [imageView setNeedsDisplay:YES];
    [[[BrowserController currentBrowser] database] save:nil];
    
    [self adjustKeyImage];
}

- (IBAction) setKeyImage:(id)sender
{
    if( postprocessed)
    {
        NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot create/modify/search key images. Revert to the original series or create a secondary capture series to do this.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    [keyImageCheck setState: ![keyImageCheck state]];
    [self keyImageCheckBox: keyImageCheck];
}

- (void) adjustKeyImage
{
    if( postprocessed)
    {
        [keyImageCheck setEnabled: NO];
        [keyImagePopUpButton setEnabled: NO];
        return;
    }
    
    // multiframes
    // it is impossible in Osirix to select only one frame of a multiframe
    // the condition below was disabling the possibility to see only key images
    // but since end of 2008 multiframe cached loading modification, the controls WERE NOT DISABLED at 2D Viewer opening
    // it is better not disabling them later
    //
    // keyImage remains usefull with multiframes in order to make key files, that is sequences or series	
    //
    // nota: elsewhere in the programm, the popup is moved back from "key image" to "all images" when all the images are key images
    /*
     if( [fileList[ curMovieIndex] count] != 1)
     {
     if( [fileList[ curMovieIndex] objectAtIndex: 0] == [fileList[ curMovieIndex] lastObject])
     {
     [keyImageCheck setState: NSOffState];
     [keyImageCheck setEnabled: NO];
     //			[keyImageDisplay setEnabled: NO];
     [keyImagePopUpButton setEnabled: NO];
     
     return;
     }
     }
     */
    
    
    //	[keyImageDisplay setEnabled: YES];
    [keyImageCheck setEnabled: YES];
    [keyImagePopUpButton setEnabled: YES];
    
    // Update Key Image check box
    if( [imageView curImage] >= 0 && [[[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] valueForKey:@"isKeyImage"] boolValue] == YES)
    {
        [keyImageCheck setState: NSOnState];
    }
    else
    {
        [keyImageCheck setState: NSOffState];
    }
}

- (BOOL)isKeyImage:(int)index
{
    if( postprocessed)
        return NO;
    
    return [[[fileList[curMovieIndex] objectAtIndex:index] valueForKey:@"isKeyImage"] boolValue];
}

#pragma mark-

- (IBAction) endSetComments:(id) sender
{
    [CommentsWindow orderOut:sender];
    
    [NSApp endSheet:CommentsWindow returnCode:[sender tag]];
    
    if( [sender tag] == 1) //series
    {
        [[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[CommentsEditField stringValue] forKeyPath:@"series.comment"];
        
        if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
            [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[CommentsEditField stringValue] forKey:@"series.comment"];
        
        [[[BrowserController currentBrowser] databaseOutline] reloadData];
        
        [self buildMatrixPreview: NO];
    }
    else if( [sender tag] == 2) //study
    {
        [[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[CommentsEditField stringValue] forKeyPath:@"series.study.comment"];
        
        if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
            [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[CommentsEditField stringValue] forKey:@"series.study.comment"];
        
        [[[BrowserController currentBrowser] databaseOutline] reloadData];
        
        [self buildMatrixPreview: NO];
    }
    
    NSString *com = [[fileList[ curMovieIndex] objectAtIndex: [imageView curImage]] valueForKeyPath:@"series.comment"];
    
    if( com == nil || [com isEqualToString:@""])
        com = [[fileList[ curMovieIndex] objectAtIndex: [imageView curImage]] valueForKeyPath:@"series.study.comment"];
    
    if( com == nil || [com isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"Add a comment", nil)];
    else [CommentsField setTitle: com];
}

- (IBAction) setComments:(id) sender
{
    if( [[CommentsField title] isEqualToString:NSLocalizedString(@"Add a comment", nil)]) [CommentsEditField setStringValue: @""];
    else [CommentsEditField setStringValue: [CommentsField title]];
    
    [CommentsEditField selectText: self];
    
    [NSApp beginSheet: CommentsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) applyStatusValue
{
    if( statusValueToApply != -1)
    {
        [[fileList[ curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[NSNumber numberWithInt: statusValueToApply] forKeyPath:@"series.study.stateText"];
        
        if([[BrowserController currentBrowser] isCurrentDatabaseBonjour])
        {
            [(RemoteDicomDatabase *)[[BrowserController currentBrowser] database] object:[fileList[curMovieIndex] objectAtIndex:[imageView curImage]] setValue:[NSNumber numberWithInt: statusValueToApply] forKey:@"series.study.stateText"];
        }
        
        [StatusPopup selectItemWithTag: statusValueToApply];
        
        [[[BrowserController currentBrowser] databaseOutline] reloadData];
        [self buildMatrixPreview: NO];
    }
}

- (void) setStatusValue:(int) v
{
    statusValueToApply = v;
}

- (IBAction) setStatus:(id) sender
{
    [self setStatusValue: [[sender selectedItem] tag]];
}

- (IBAction) databaseWindow : (id) sender
{
    if (!([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
    {
        [ViewerController closeAllWindows];
    }
    [[BrowserController currentBrowser] showDatabase:self];
}

- (void)setStandardRect:(NSRect)rect
{
    standardRect = rect;
}

#pragma mark-
#pragma mark Key Objects
//- (IBAction)createKeyObjectNote:(id)sender
//{
//	id study = [[imageView seriesObj] valueForKey:@"study"];
//	KeyObjectController *controller = [[KeyObjectController alloc] initWithStudy:(id)study];
//	[NSApp beginSheet:[controller window]  modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(keyObjectSheetDidEnd:returnCode:contextInfo:) contextInfo:controller];
//}
//
//- (void)keyObjectSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(id)contextInfo
//{
//	[contextInfo autorelease];
//	[keyImagePopUpButton selectItemAtIndex:displayOnlyKeyImages];
//}

- (BOOL)displayOnlyKeyImages
{
    return displayOnlyKeyImages;
}

#pragma mark-
#pragma mark report

- (IBAction)deleteReport:(id)sender;
{
    [[BrowserController currentBrowser] deleteReport:sender];
    [self performSelector: @selector(updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];
}

#ifndef OSIRIX_LIGHT
- (IBAction)generateReport:(id)sender;
{
    [[BrowserController currentBrowser] generateReport:sender];
    [self performSelector: @selector(updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];
}
#endif

- (NSImage*)reportIcon;
{
    NSString *iconName = @"Report.icns";
    switch([[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue])
    {
        case 0: // M$ Word
        {
            iconName = @"ReportWord.icns";
        }
            break;
        case 1: // TextEdit (RTF)
        {
            iconName = @"ReportRTF.icns";
        }
            break;
        case 2: // Pages.app
        {
            iconName = @"ReportPages.icns";
        }
            break;
    }
    return [NSImage imageNamed:iconName];
}

- (void) updateReportToolbarIcon:(NSNotification *)note
{
    long i;
    NSToolbarItem *item;
    NSArray *toolbarItems = [toolbar items];
    for(i=0; i<[toolbarItems count]; i++)
    {
        item = [toolbarItems objectAtIndex:i];
        if ([[item itemIdentifier] isEqualToString: ReportToolbarItemIdentifier])
        {
            [toolbar removeItemAtIndex:i];
            [toolbar insertItemWithItemIdentifier: ReportToolbarItemIdentifier atIndex:i];
        }
    }
}


- (void)setToolbarReportIconForItem:(NSToolbarItem *)item;
{
#ifndef OSIRIX_LIGHT
    NSMutableArray* templatesArray = nil;
    switch ([[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue]) {
        case 2:
            templatesArray = [Reports pagesTemplatesList];
            break;
        case 0:
            templatesArray = [Reports wordTemplatesList];
            break;
    }
    
    DicomStudy* studySelected = [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study"];
    
    if (!studySelected.reportURL && templatesArray.count > 1)
    {
        [reportTemplatesImageView setImage:[self reportIcon]];
        [item setView:reportTemplatesView];
        [item setMinSize:NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
        [item setMaxSize:NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
    }
    else
    {
        [item setImage:[self reportIcon]];
    }
#else
    [item setImage: [NSImage imageNamed: @"Report.icns"]];
#endif
}


- (void)reportToolbarItemWillPopUp:(NSNotification *)notif;
{
#ifndef OSIRIX_LIGHT
    if([[notif object] isEqualTo:reportTemplatesListPopUpButton])
    {
        [reportTemplatesListPopUpButton removeAllItems];
        [reportTemplatesListPopUpButton addItemWithTitle:@""];
        
        switch ([[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue]) {
            case 2:
                [reportTemplatesListPopUpButton addItemsWithTitles:[Reports pagesTemplatesList]];
                break;
            case 0:
                [reportTemplatesListPopUpButton addItemsWithTitles:[Reports wordTemplatesList]];
                break;
        }
        
        [reportTemplatesListPopUpButton setAction:@selector(generateReport:)];
    }
#endif
}


#pragma mark-
#pragma mark current Core Data Objects
- (DicomStudy *)currentStudy
{
    return [[imageView seriesObj] valueForKey:@"study"];
}
- (DicomSeries *)currentSeries
{
    return [imageView seriesObj];
}
- (DicomImage *)currentImage
{
    return [imageView imageObj];
}


#pragma mark-
#pragma mark Convience methods for accessing values in the current imageView
-(float)curWW
{
    return [imageView curWW];
}

-(float)curWL
{
    return [imageView curWL];
}

- (void)setWL:(float)cwl  WW:(float)cww
{
    [imageView setWLWW:cwl :cww];
}

- (BOOL)xFlipped
{
    return [imageView xFlipped];
}

- (BOOL)yFlipped
{
    return [imageView yFlipped];
}

- (float)rotation
{
    return [imageView rotation];
}

- (void)setRotation:(float)rotation
{
    [imageView setRotation:rotation];
}

- (void)setOrigin:(NSPoint) o
{
    [imageView setOrigin:o];
}

- (float)scaleValue
{
    return [imageView scaleValue];
}

- (void)setScaleValue:(float)scaleValue
{
    [imageView setScaleValue:scaleValue];
}

- (void)setYFlipped:(BOOL) v
{
    [imageView setYFlipped:(BOOL) v];
}

- (void)setXFlipped:(BOOL) v
{
    [imageView setXFlipped:(BOOL) v];
}

- (SeriesView *) seriesView
{
    return seriesView;
}

- (void)setImageRows:(int)rows columns:(int)columns
{
    [self setImageRows: rows columns: columns rescale: YES];
}

- (void)setImageRows:(int)rows columns:(int)columns rescale: (BOOL) rescale
{
    if( rows > 8) rows = 8;
    if( columns > 8) columns = 8;
    
    if( rows < 1) rows = 1;
    if( columns < 1) columns = 1;
    
    [seriesView setImageViewMatrixForRows: rows columns: columns rescale: rescale];
    
    [imageView updateTilingViews];
}

- (IBAction)setImageTiling: (id)sender
{
    int columns = 1;
    int rows = 1;
    int tag = 0;
    NSMenuItem *item;
    
    if ([sender class] == [NSMenuItem class])
    {
        NSArray *menuItems = [[sender menu] itemArray];
        for(item in menuItems)
            [item setState:NSOffState];
        tag = [(NSMenuItem *)sender tag];
    }
    
    if (tag < 16)
    {
        rows = (tag / 4) + 1;
        columns =  (tag %  4) + 1;
    }
    
    [self setImageRows: rows columns: columns];
}

#ifndef OSIRIX_LIGHT
- (IBAction)calciumScoring:(id)sender
{
    BOOL	found = NO;
    NSArray *winList = [NSApp windows];
    
    for( id loopItem in winList)
    {
        if( [[[loopItem windowController] windowNibName] isEqualToString:@"CalciumScoring"]) found = YES;
    }
    
    if( !found)
    {
        CalciumScoringWindowController *calciumScoringWindowController = [[CalciumScoringWindowController alloc] initWithViewer:self];
        [calciumScoringWindowController showWindow:self];
    }
}
#endif

//- (IBAction)centerline: (id)sender
//{
//	BOOL	found = NO;
//	NSArray *winList = [NSApp windows];
//	
//	for( id loopItem in winList)
//	{
//		if( [[[loopItem windowController] windowNibName] isEqualToString:@"CenterlineSegmentation"]) found = YES;
//	}
//	
//	if( !found)
//	{
//		EndoscopySegmentationController *endoscopySegmentationController = [[EndoscopySegmentationController alloc] initWithViewer:self];
//		[endoscopySegmentationController showWindow:self];
//	}
//}

#pragma mark-
#pragma mark 12 Bit

-(IBAction)enable12Bit:(id)sender;
{
    BOOL t12Bit = ([[sender selectedCell] tag]==0);
    [imageView setIsLUT12Bit:t12Bit];
    [imageView updateImage];
}

- (void)verify12Bit:(NSTimer*)theTimer
{
    BOOL t12Bit = [imageView isLUT12Bit];
    if(t12Bit) [display12bitToolbarItemMatrix selectCellWithTag:0];
    else [display12bitToolbarItemMatrix selectCellWithTag:1];
}

#pragma mark-
#pragma mark Navigator

- (IBAction)navigator:(id)sender;
{
    if([[[self imageView] curDCM] isRGB])
    {
        NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool currently does not work with RGB data series.", nil), nil, nil, nil);
        return;
    }
    
    if( [NavigatorWindowController navigatorWindowController] == nil)
    {
        BOOL volumicData = [self isDataVolumicIn4D: YES];
        
        if( volumicData == NO)
        {
            NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool works only with 3D data series with identical matrix sizes.", nil), nil, nil, nil);
            return;
        }
        
        NavigatorWindowController *navigatorWindowController = [[NavigatorWindowController alloc] initWithViewer:self];
        [navigatorWindowController showWindow:self];
        [[AppController sharedAppController] tileWindows: nil];
    }
    else [[NavigatorWindowController navigatorWindowController] setViewer:self];
}

- (IBAction)threeDPanel:(id)sender;
{
    if( [ThreeDPositionController threeDPositionController] == nil)
    {
        BOOL volumicData = [self isDataVolumicIn4D: YES];
        
        if( volumicData == NO)
        {
            NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool works only with 3D data series with identical matrix sizes.", nil), nil, nil, nil);
            return;
        }
        
        ThreeDPositionController *threeDPositionController = [[ThreeDPositionController alloc] initWithViewer:self];
        [threeDPositionController showWindow:self];
    }
    else [[ThreeDPositionController threeDPositionController] setViewer:self];
}

- (void)updateNavigator;
{
    [[ThreeDPositionController threeDPositionController] setViewer:self];
    
    [[NavigatorWindowController navigatorWindowController] setViewer:self];
    
    NSRect navigatorFrame = [[[NavigatorWindowController navigatorWindowController] window] frame];
    navigatorFrame.origin.x = [[[self window] screen] visibleFrame].origin.x;
    navigatorFrame.size.width = [[[self window] screen] visibleFrame].size.width;
    [[[NavigatorWindowController navigatorWindowController] window] setFrame:navigatorFrame display:YES];
}

#pragma mark Comparatives GUI

- (IBAction)toggleComparativesVisibility:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"listPODComparativesIn2DViewer"] forKey:@"listPODComparativesIn2DViewer"];
    for (ViewerController* vc in [ViewerController get2DViewers])
        [vc buildMatrixPreview:YES];
}


@end

