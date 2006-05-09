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

/***************************************** Modifications *********************************************

Version 2.3

	20060123	LP	added sliceLocation to userinfo for synchronize to allow calculation of relative slice location
	20060124	LP	SyncSeriesMenuItem status updated with status of sync series
	
Version 2.3.1

	20060208	LP	Revised zooming behavior
	20060217	LP	Added some more menu items 
	20060216	LP	Added a Shift option to databaseWindow. Holding down the shift key will bring the browser to the front without closing viewers

Version 2.3.2	JF	Started to classify methods, adding pragma marks, but without changing anything else (work in progress)
	
****************************************/




#import "MyOutlineView.h"
#import "xNSImage.h"
#import "PluginFilter.h"
#import "DCMPix.h"
#import "DicomImage.h"
#import "VRController.h"
#import "VRControllerVPRO.h"
#import "NSSplitViewSave.h"
#import "SRController.h"
#import "MPRController.h"
#import "MPR2DController.h"
#import "NSFullScreenWindow.h"
#import "ViewerController.h"
#import "browserController.h"
#import "wait.h"
#import <QuickTime/QuickTime.h>
#import "XMLController.h"
#include <Accelerate/Accelerate.h>
#import "WaitRendering.h"
#import "HistogramWindow.h"
#import "ROIWindow.h"
#import "ROIDefaultsWindow.h"
#import <ScreenSaver/ScreenSaverView.h>
#import "AppController.h"
#import "ToolbarPanel.h"
#import "Papyrus3/Papyrus3.h"
#import "DCMView.h"
#import "StudyView.h"
#import "ColorTransferView.h"
#import "ThickSlabController.h"
#import "Mailer.h"
#import "ITKSegmentation3DController.h"
#import "MSRGWindowController.h"
#import "iPhoto.h"
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
#import "MSRGSegmentation.h"
#import "ITKBrushROIFilter.h"


#import "HornRegistration.h"
#import "ITKTransform.h"

@class VRPROController;

extern	NSMutableDictionary		*plugins, *pluginsDict;
extern  ToolbarPanelController  *toolbarPanel[ 10];
extern  AppController			*appController;
extern  BrowserController       *browserWindow;
extern  BOOL					USETOOLBARPANEL;
extern  NSMenu					*fusionPluginsMenu;
		BOOL					SYNCSERIES = NO;

		
static NSString* 	ViewerToolbarIdentifier				= @"Viewer Toolbar Identifier";
static NSString*	QTSaveToolbarItemIdentifier			= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier			= @"iPhoto2";
static NSString*	PlayToolbarItemIdentifier			= @"Play.icns";
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
static NSString*	iChatBroadCastToolbarItemIdentifier = @"iChat.icns";
static NSString*	StatusToolbarItemIdentifier			= @"status";
static NSString*	SyncSeriesToolbarItemIdentifier		= @"Sync.tif";
static NSString*	ResetToolbarItemIdentifier			= @"Reset.tiff";
static NSString*	RevertToolbarItemIdentifier			= @"Revert.tiff";
static NSString*	FlipDataToolbarItemIdentifier		= @"FlipData.tiff";
static NSString*	DatabaseWindowToolbarItemIdentifier = @"DatabaseWindow.icns";
static NSString*	KeyImagesToolbarItemIdentifier		= @"keyImages";
static NSString*	DeleteToolbarItemIdentifier			= @"trash.icns";
static NSString*	TileWindowsToolbarItemIdentifier	= @"windows.tif";
static NSString*	SUVToolbarItemIdentifier			= @"SUV.tif";
static NSString*	ROIManagerToolbarItemIdentifier		= @"ROIManager.tiff";
static NSString*	ReportToolbarItemIdentifier			= @"Report.icns";
static NSString*	FlipVerticalToolbarItemIdentifier	= @"FlipVertical.tif";
static NSString*	FlipHorizontalToolbarItemIdentifier	= @"FlipHorizontal.tif";
static NSString*	VRPanelToolbarItemIdentifier		= @"MIP.tif";
static NSArray*		DefaultROINames;

static	BOOL EXPORT2IPHOTO								= NO;
static	ViewerController *blendedwin					= 0L;
static	float	deg2rad									= 3.14159265358979/180.0; 

static ViewerController *gSelf;

long numberOf2DViewer = 0;

Movie CreateMovie(Rect *trackFrame, NSString *filename, long dimension, long from, long to, long interval);
NSString * documentsDirectory();
NSString* convertDICOM( NSString *inputfile);

static void CheckError(OSErr err, char *message )
{
    if (err != noErr)
    {
        printf(message);
    }
}

void CopyNSImageToGWorld(NSImage *image, GWorldPtr gWorldPtr)
{
    NSArray				*repArray;
    PixMapHandle		pixMapHandle;
    unsigned char* 		pixBaseAddr;
    int					imgRepresentationIndex;
    NSImage             *newImage;
//    NSRect            frameRect;
    NSImageRep          *sourceImageRep = [image bestRepresentationForDevice:nil];
    NSBitmapImageRep	*bitmap;
    
/*    frameRect = [[gSelf imageView] frame];

    NSSize  size = [image size];
    NSSize  sizeView = [[[gSelf imageView] enclosingScrollView] contentSize];
    NSRect  visibleRect = [[[gSelf imageView] enclosingScrollView] documentVisibleRect];
    */
    
    NSSize  size = [image size];
    NSRect  sRect;
    
    newImage = [[NSImage alloc] initWithSize:size];
    
        [newImage lockFocus];

            
            sRect.origin.x = 0;
            sRect.origin.y = 0;
            sRect.size.width = size.width;
            sRect.size.height = size.height;
                    
            [sourceImageRep drawInRect:sRect];  // rect
            bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:sRect];  // frameRect

    [newImage unlockFocus];    
    [newImage addRepresentation:bitmap];
    
    // Lock the pixels
    pixMapHandle = GetGWorldPixMap(gWorldPtr);
    LockPixels (pixMapHandle);
    pixBaseAddr = (unsigned char*) GetPixBaseAddr(pixMapHandle);
    
    repArray = [newImage representations];
    for (imgRepresentationIndex = 0; imgRepresentationIndex < [repArray count]; ++imgRepresentationIndex)
    {
        NSObject *imageRepresentation = [repArray objectAtIndex:imgRepresentationIndex];
        
        if ([imageRepresentation isKindOfClass:[NSBitmapImageRep class]])
        {
            unsigned char* bitMapDataPtr = [(NSBitmapImageRep *)imageRepresentation bitmapData];

            if ((bitMapDataPtr != nil) && (pixBaseAddr != nil))
            {
                int i,j;
                int pixmapRowBytes = GetPixRowBytes(pixMapHandle);
                
                NSSize imageSize = [(NSBitmapImageRep *)imageRepresentation size];
                
                for (i=0; i< imageSize.height; i++)
                {
                    unsigned char *src = bitMapDataPtr + i * [(NSBitmapImageRep *)imageRepresentation bytesPerRow];
                    unsigned char *dst = pixBaseAddr + i * pixmapRowBytes;
                    
                    for (j = 0; j < imageSize.width; j++)
                    {
                        *dst++ = 0;        // X - our src is 24-bit only
                        *dst++ = *src++;	// Red component
                        *dst++ = *src++;	// Green component
                        *dst++ = *src++;	// Blue component
                        
                        if( [(NSBitmapImageRep *)imageRepresentation bitsPerPixel] == 32) src++;
                    }
                }
            }
        }
    }
    UnlockPixels(pixMapHandle);
    
    [newImage release];
	[bitmap release];
}

static ICMCompressionSessionOptionsRef GrabCSessionOptionsFromStdCompression()
{
    ComponentInstance stdCompression = 0;
    long scPreferences;
    ICMCompressionSessionOptionsRef sessionOptionsRef = NULL;

    ComponentResult err;

    // open the standard compression component
    err = OpenADefaultComponent(StandardCompressionType, StandardCompressionSubType, &stdCompression);
    if (err || 0 == stdCompression) goto bail;

    // Indicates the client is ready to use the ICM compression session API to perform compression operations
    // StdCompression will disable frame reordering and multi pass encoding if this flag not set because the
    // older sequence APIs do not support these capabilities
    scPreferences = scAllowEncodingWithCompressionSession;

    // set the preferences we want
    err = SCSetInfo(stdCompression, scPreferenceFlagsType, &scPreferences);
    if (err) goto bail;

    // display the standard compression dialog box
    err = SCRequestSequenceSettings(stdCompression);
    if (err) goto bail;

    // creates a compression session options object based on configured settings
    err = SCCopyCompressionSessionOptions(stdCompression, &sessionOptionsRef);

bail:
    if (0 != stdCompression) CloseComponent(stdCompression);

    return sessionOptionsRef;
}

static short QTVideo_AddVideoSamplesToMedia(Media theMedia, const Rect *trackFrame, long dimension, long from, long to, long interval)
{
	GWorldPtr					theGWorld = nil;
	long						curSample;
	ImageDescriptionHandle		imageDesc = nil;
	CGrafPtr					oldPort;
	GDHandle					oldGDeviceH;
	OSErr						err = noErr;
	ComponentInstance			ci;
	long						dataSize;
	ComponentResult				result;
	short						notSyncFlag;
	Handle						theRes;
	NSImage						*im;
                
		// Create a graphics world
	err = NewGWorld (&theGWorld,	/* pointer to created gworld */	
			32,		/* pixel depth */
			trackFrame, 		/* bounds */
			nil, 			/* color table */
			nil,			/* handle to GDevice */ 
			(GWorldFlags)0);	/* flags */
	CheckError (err, "NewGWorld error");


	// Lock the pixels
	LockPixels (GetGWorldPixMap(theGWorld)/*GetPortPixMap(theGWorld)*/);


    ci = OpenDefaultComponent (StandardCompressionType, StandardCompressionSubType);


//MovieExportDoUserDialog

    // Do not requite the user to enter the keyframe data
     long flags;
     SCGetInfo(ci, scPreferenceFlagsType, &flags);
     flags &= ~scAllowZeroKeyFrameRate;
     SCSetInfo(ci, scPreferenceFlagsType, &flags);
    
    SCSpatialSettings theDefaultChoice = { kJPEGCodecType,
                                       (CodecComponent)0L,
                                       0,
                                       codecHighQuality };
    SCSetInfo(ci, scSpatialSettingsType, &theDefaultChoice);

    SCTemporalSettings timeSettings;
     timeSettings.temporalQuality = codecHighQuality;
	 
	 switch( dimension)
	 {
		default:
		case 1:
		case 3:
			if( [gSelf frameRate] > 0) timeSettings.frameRate = X2Fix([gSelf frameRate]);
			else timeSettings.frameRate = X2Fix(60.0);
		break;
		
		case 0:
			timeSettings.frameRate = X2Fix(10.0);
		break;
		
		case 2:
			if( [gSelf frame4DRate] > 0) timeSettings.frameRate = X2Fix([gSelf frameRate]);
			else timeSettings.frameRate = X2Fix(60.0);
		break;
	}
     
	timeSettings.keyFrameRate = 0;
	SCSetInfo(ci, scTemporalSettingsType, &timeSettings);
    
    im = [[gSelf imageView] nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];
    
	CopyNSImageToGWorld( im, theGWorld);
	
	if( EXPORT2IPHOTO == NO)
	{
		result = SCSetTestImagePixMap (ci,
						   GetGWorldPixMap(theGWorld),
						   0L,
						   scPreferScalingAndCropping);
		
		result = SCRequestSequenceSettings (ci);
	}
	else result = 0;
	
    [im release];
    if (result < 0 || result == scUserCancelled) return -1;
     
        Wait    *wait= [[Wait alloc] initWithString:0L];
        [wait showWindow:gSelf];

    SCGetInfo(ci, scTemporalSettingsType, &timeSettings);
    timeSettings.keyFrameRate = 0;
	SCSetInfo(ci, scTemporalSettingsType, &timeSettings);
	
	result = SCCompressSequenceBegin (ci,
      					GetGWorldPixMap(theGWorld),
      					0L,
      					&imageDesc);

        // Change the current graphics port to the GWorld
        GetGWorld(&oldPort, &oldGDeviceH);
        SetGWorld(theGWorld, nil);
        
        // For each sample...
		switch( dimension)
		{
			case 1:
			break;
			
			case 3:
				to = [gSelf getNumberOfImages];
				from = 0;
				interval = 1;
			break;
			
			case 0:
				to = 20;
				from = 0;
				interval = 1;
			break;
			
			case 2:
				to = [gSelf maxMovieIndex];
				from = 0;
				interval = 1;
			break;
		}
		
        [[wait progress] setMaxValue: (to-from) / interval];
		
        for (curSample = from; curSample < to; curSample += interval) 
        {
			BOOL export = YES;
			
			if( dimension == 3)
			{
				NSManagedObject	*image = [[gSelf fileList] objectAtIndex: curSample];
				export = [[image valueForKey:@"isKeyImage"] boolValue];
			}
			
			if( export)
			{
				switch( dimension)
				{
					case 1:
					case 3:
						if( [[gSelf imageView] flippedData]) [[gSelf imageView] setIndex: [gSelf getNumberOfImages] - 1 -curSample];
						else [[gSelf imageView] setIndex:curSample];
						[[gSelf imageView] sendSyncMessage:1];
						[[gSelf imageView] display];
					break;

					case 0:
						[[gSelf blendingSlider] setIntValue: -256 + ((curSample * 512) / (to-1))];
						[gSelf blendingSlider:[gSelf blendingSlider]];
						[[gSelf imageView] display];
					break;

					case 2:
						[[gSelf moviePosSlider] setIntValue: curSample];
						[gSelf moviePosSliderAction:[gSelf moviePosSlider]];
						[[gSelf imageView] display];
					break;
				}
						
				im = [[gSelf imageView] nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];

				if( EXPORT2IPHOTO == NO)
				{
					CopyNSImageToGWorld(im, theGWorld);

					result = SCCompressSequenceFrame (ci,
								  GetGWorldPixMap(theGWorld),
								  0L,
								  &theRes,
								  &dataSize,
								  &notSyncFlag);

					// Add sample data and a description to a media
					err = AddMediaSample(theMedia,	/* media specifier */ 
							theRes,	/* handle to sample data - dataIn */
							0,		/* specifies offset into data reffered to by dataIn handle */
							dataSize, /* number of bytes of sample data to be added */ 
							X2Fix( 0.01 / Fix2X(timeSettings.frameRate)),		 /* frame duration = 1/10 sec */
							(SampleDescriptionHandle)imageDesc,	/* sample description handle */ 
							1,	/* number of samples */
							notSyncFlag,	/* control flag indicating self-contained samples */
							nil);		/* returns a time value where sample was insterted */
					CheckError( err, "AddMediaSample error" );
				}
				else
				{
					NSString *curFile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/OsiriX%4d.tif", curSample];
					
					[[im TIFFRepresentation] writeToFile:curFile atomically:YES];
				}

				[im release];
			}
			[wait incrementBy:1];
        }
        	
      UnlockPixels (GetGWorldPixMap(theGWorld));

       SetGWorld (oldPort, oldGDeviceH);
        
		[wait close];
        [wait release];
        
        // Dealocate our previously alocated handles and GWorld
        
        if (theGWorld)
        {
                DisposeGWorld (theGWorld);
        }
        
        return err;
} 

static short QTVideo_CreateMyVideoTrack(Movie theMovie, Rect *trackFrame, long dimension, long from, long to, long interval)
{
	Track theTrack;
	Media theMedia;
	OSErr err = noErr;
        
        // 1. Create the track
        theTrack = NewMovieTrack (theMovie, 		/* movie specifier */
                            FixRatio((*trackFrame).right,1),  /* width */
                            FixRatio((*trackFrame).bottom,1), /* height */
                                                        kNoVolume);  /* trackVolume */
        
        // 2. Create the media for the track
        theMedia = NewTrackMedia (theTrack,		/* track identifier */
                                VideoMediaType,		/* type of media */
                                600, 	/* time coordinate system */
                                nil,			/* data reference - use the file that is associated with the movie  */
                                0);			/* data reference type */

        // 3. Establish a media-editing session
        BeginMediaEdits (theMedia);

        // 3a. Add Samples to the media
        err = QTVideo_AddVideoSamplesToMedia (theMedia, trackFrame,  dimension,  from,  to,  interval);
        
        // 3b. End media-editing session
        EndMediaEdits (theMedia);

        // 4. Insert a reference to a media segment into the track
        InsertMediaIntoTrack (theTrack,		/* track specifier */
                                0,	/* track start time */
                                0, 	/* media start time */
                                GetMediaDuration(theMedia), /* media duration */
                                X2Fix(1.0));		/* media rate ((Fixed) 0x00010000L) */

    return err;
} 

static StringPtr QTUtils_ConvertCToPascalString (char *theString)
{
	StringPtr	myString = malloc(strlen(theString) + 1);
	short		myIndex = 0;

	while (theString[myIndex] != '\0') {
		myString[myIndex + 1] = theString[myIndex];
		myIndex++;
	}
	
	myString[0] = (unsigned char)myIndex;
	
	return(myString);
}

Movie CreateMovie(Rect *trackFrame, NSString *filename, long dimension, long from, long to, long interval)
{
    Movie theMovie = nil;
    FSSpec mySpec;
    short resRefNum = 0;
    short resId = movieInDataForkResID;
    OSErr err = noErr;
    FSRef fsRef;


    [filename writeToFile:filename atomically:false];
    
    err = [gSelf getFSRefAtPath:filename ref:&fsRef];
    
    
    err =FSGetCatalogInfo(&fsRef, 
                                    kFSCatInfoNone, 
                                    NULL,
                                    NULL,
                                    &mySpec,
                                    NULL);
    
    err = CreateMovieFile (&mySpec, 
                            'TVOD',
                            smCurrentScript, 
                            createMovieFileDeleteCurFile | createMovieFileDontCreateResFile,
                            &resRefNum, 
                            &theMovie );
    if( err == 0)
    {
        err = QTVideo_CreateMyVideoTrack (theMovie, trackFrame, dimension, from, to, interval);
        if( err == noErr)
        {
            err = AddMovieResource (theMovie, resRefNum, &resId, QTUtils_ConvertCToPascalString ("testing"));
            if (resRefNum)
            {
                CloseMovieFile (resRefNum);
            }
        }
        else
        {
			CloseMovieFile (resRefNum);
			
            DisposeMovie( theMovie);
            theMovie = 0L;
            
            FSpDelete( &mySpec);
        }
    }
    else
    {
        NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"I cannot create this file... File is busy? opened? not enough place?", nil), nil, nil, nil);
    }
    return theMovie;
}

// compares the names of 2 ROIs.
// using the option NSNumericSearch => "Point 1" < "Point 5" < "Point 21".
// use it with sortUsingFunction:context: to order an array of ROIs
int sortROIByName(id roi1, id roi2, void *context)
{
    NSString *n1 = [roi1 name];
    NSString *n2 = [roi2 name];
    return [n1 compare:n2 options:NSNumericSearch];
}

#pragma mark-

@implementation ViewerController

#pragma mark-
#pragma mark 1. window and workplace
-(void)createDCMViewMenu{

/******************* Tools menu ***************************/
	NSMenu *contextual =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	NSMenu *submenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"ROI", nil)];
	NSMenuItem *item;
    NSArray *titles = [NSArray arrayWithObjects:NSLocalizedString(@"Contrast", nil), NSLocalizedString(@"Move", nil), NSLocalizedString(@"Magnify", nil), 
												NSLocalizedString(@"Rotate", nil), NSLocalizedString(@"Scroll", nil), NSLocalizedString(@"ROI", nil), nil];
	NSArray *images = [NSArray arrayWithObjects: @"WLWW", @"Move", @"Zoom",  @"Rotate",  @"Stack", @"Length", nil];	// DO NOT LOCALIZE THIS LINE ! -> filenames !
	NSEnumerator *enumerator = [titles objectEnumerator];
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
		item = [[NSMenuItem alloc] initWithTitle: [subItem title] action: @selector(setROITool:) keyEquivalent:@""];
		[item setTag:tag];
		[item setImage: [self imageForROI: tag]];
		[item setTarget:self];
		[submenu addItem:item];
		[item release];
	}

	while (title = [enumerator nextObject]) {
		image = [enumerator2 nextObject];
		item = [[NSMenuItem alloc] initWithTitle: title action: @selector(setDefaultTool:) keyEquivalent:@""];
		[item setTag:i++];
		[item setTarget:self];
		[item setImage:[NSImage imageNamed:image]];
		[contextual addItem:item];
		[item release];
	}
	[[contextual itemAtIndex:5] setSubmenu:submenu];
	
	[contextual addItem:[NSMenuItem separatorItem]];
	
/******************* WW/WL menu items **********************/
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
	
	
	/************* window resize Menu ****************/
	
	[submenu release];
	submenu =  [[NSMenu alloc] initWithTitle:@"Resize window"];
	
	NSArray *resizeWindowArray = [NSArray arrayWithObjects:@"25%", @"50%", @"100%", @"200%", @"300%", @"iPod Video", nil];
	NSEnumerator *resizeEnumerator = [resizeWindowArray objectEnumerator];
	i = 0;
	NSString	*titleMenu;
	while (titleMenu = [resizeEnumerator nextObject]) {
		int tag = i++;
		item = [[NSMenuItem alloc] initWithTitle:titleMenu action: @selector(resizeWindow:) keyEquivalent:@""];
		[item setTag:tag];
		[item setTarget:imageView];
		[submenu addItem:item];
		[item release];
	}
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Resize window", nil) action: nil keyEquivalent:@""];
	[item setSubmenu:submenu];
	[contextual addItem:item];
	[item release];
	
	[contextual addItem:[NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Actual size", nil) action: @selector(actualSize:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Key image", nil) action: @selector(setKeyImage:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	//Export Added 12/5/05
	/*************Export submenu**************/
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *exportSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Export", nil)];
	[item setSubmenu:exportSubmenu];
		NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"QuickTime", nil)  action:@selector(exportQuicktime:) keyEquivalent:@""];
		[subMenuItem setTarget:self];
		[exportSubmenu addItem:subMenuItem];
		[subMenuItem release];
		
		
		subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DICOM", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""];
		[subMenuItem setTarget:self];
		[exportSubmenu addItem:subMenuItem];
		[subMenuItem release];
		
		subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Email", nil)  action:@selector(sendMail:) keyEquivalent:@""];
		[subMenuItem setTarget:self];
		[exportSubmenu addItem:subMenuItem];
		[subMenuItem release];
		
		subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"iPhoto", nil)  action:@selector(export2iPhoto:) keyEquivalent:@""];
		[subMenuItem setTarget:self];
		[exportSubmenu addItem:subMenuItem];
		[subMenuItem release];
		
		subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"JPEG", nil)  action:@selector(exportJPEG:) keyEquivalent:@""];
		[subMenuItem setTarget:self];
		[exportSubmenu addItem:subMenuItem];
		[subMenuItem release];
		
		subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"TIFF", nil)  action:@selector(exportTIFF:) keyEquivalent:@""];
		[subMenuItem setTarget:self];
		[exportSubmenu addItem:subMenuItem];
		[subMenuItem release];
		
		
	
	[exportSubmenu release];
	[item release];
	
	/********** Flip submenu ************/ 
	
	[contextual addItem:[NSMenuItem separatorItem]];
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Flip", nil) action: nil  keyEquivalent:@""];
	[contextual addItem:item];
	NSMenu *flipSubmenu =  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Flip", nil)];
	[item setSubmenu:flipSubmenu ];
	subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Vertical", nil)  action:@selector(flipVertical:) keyEquivalent:@""];
	[subMenuItem setTarget:imageView];
	[flipSubmenu addItem:subMenuItem];
	[subMenuItem release];
	subMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Horizontal", nil)  action:@selector(flipHorizontal:) keyEquivalent:@""];
	[subMenuItem setTarget:imageView];
	[flipSubmenu addItem:subMenuItem];
	[subMenuItem release];
	[item release];
	[flipSubmenu release];
	
	
	[contextual addItem:[NSMenuItem separatorItem]];
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open database", nil) action: @selector(databaseWindow:)  keyEquivalent:@""];
	[item setTarget:self];
	[contextual addItem:item];
	[item release];

	
	//Add menu to view
	[imageView setMenu:contextual];
	
	[contextual release];
	[submenu release];
}


- (void) setWindowTitle:(id) sender
{
	NSString	*loading = [NSString stringWithString:@""];
	
	if( ThreadLoadImage == YES || loadingPercentage == 0)
	{
		loading = [NSString stringWithFormat:NSLocalizedString(@"Loading (%2.f%%) - ", nil), loadingPercentage * 100.];
		
		if( loadingPercentage != 1) [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(setWindowTitle:)  userInfo:0L repeats:NO];
	}
	
	NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
	
	if( [[[curImage valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"])
	{
		[[self window] setTitle: NSLocalizedString( @"No images", 0L)];
	}
	else
	{
		NSDate	*bod = [curImage valueForKeyPath:@"series.study.dateOfBirth"];
		
		NSString	*shortDateString = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString];
		NSDictionary	*localeDictionnary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotFull)
		{
			if( [curImage valueForKeyPath:@"series.study.dateOfBirth"])
				[[self window] setTitle: [NSString stringWithFormat: @"%@%@ - %@ (%@) - %@ (%@)", loading, [curImage valueForKeyPath:@"series.study.name"], [bod descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary], [curImage valueForKeyPath:@"series.study.yearOld"], [curImage valueForKeyPath:@"series.name"], [[curImage valueForKeyPath:@"series.id"] stringValue]]];
			else
				[[self window] setTitle: [NSString stringWithFormat: @"%@%@ - %@ (%@)", loading, [curImage valueForKeyPath:@"series.study.name"], [curImage valueForKeyPath:@"series.name"], [[curImage valueForKeyPath:@"series.id"] stringValue]]];
		}	
		else [[self window] setTitle: [NSString stringWithFormat: @"%@%@ (%@)", loading, [curImage valueForKeyPath:@"series.name"], [[curImage valueForKeyPath:@"series.id"] stringValue]]];
	}
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
	[waitWindow release];
}

-(IBAction) updateImage:(id) sender
{
	float cwl, cww;
	
	[imageView getWLWW:&cwl :&cww];
	[imageView setWLWW:cwl :cww];
}

-(void) needsDisplayUpdate
{
	[self updateImage:self];
}


- (void)windowDidLoad
{
	[[self window] setInitialFirstResponder: imageView];
	[self createDCMViewMenu];
	
	seriesView = [[[studyView seriesViews] objectAtIndex:0] retain];
	imageView = [[[seriesView imageViews] objectAtIndex:0] retain];
}

- (ViewerController *) newWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
    ViewerController *win = [[ViewerController alloc] viewCinit:f :d :v];
	
	[win showWindowTransition];
	[win startLoadImageThread]; // Start async reading of all images
	

	[appController tileWindows: self];

	return win;
}

- (void) tileWindows
{
	[appController tileWindows: self];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame{
	
	NSRect currentFrame = [sender frame];
	NSRect	screenRect    = [[sender screen] visibleFrame];
	
	if( USETOOLBARPANEL )
		screenRect.size.height -= [ToolbarPanelController fixedHeight];	

	if (currentFrame.size.height >= screenRect.size.height - 20 && currentFrame.size.width >= screenRect.size.width - 20) {
		return standardRect;
	}
	else
		return screenRect;
}


- (void)setWindowFrame:(NSRect)rect{
	[self setStandardRect:rect];
	[[self window] setFrame:rect display:YES];				
	[[self window] orderFront:self];	
	[[self imageView] scaleToFit];
}


-(BOOL) windowWillClose
{
	return windowWillClose;
}

- (BOOL)windowShouldClose:(id)sender
{
	stopThreadLoadImage = YES;
	if( [browserWindow isCurrentDatabaseBonjour])
	{
		while( [ThreadLoadImageLock tryLock] == NO) [browserWindow bonjourRunLoop: self];
	}
	else [ThreadLoadImageLock lock];
	[ThreadLoadImageLock unlock];

	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
	
	
	windowWillClose = YES;
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	NSLog(@"windowWillClose");

	[splitView saveDefault:@"SPLITVIEWER"];
	
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
	
	if( timeriChat)
    {
        [timeriChat invalidate];
        [timeriChat release];
        timeriChat = nil;
    }
	
	stopThreadLoadImage = YES;
	if( [browserWindow isCurrentDatabaseBonjour])
	{
		while( [ThreadLoadImageLock tryLock] == NO) [browserWindow bonjourRunLoop: self];
	}
	else [ThreadLoadImageLock lock];
	[ThreadLoadImageLock unlock];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"CloseViewerNotification" object: self userInfo: 0L];
	
	if( SYNCSERIES)
	{
		NSArray		*winList = [NSApp windows];
		long		i, win = 0;
		
		for( i = 0; i < [winList count]; i++)
		{
			if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
			{
				if( self != [[winList objectAtIndex:i] windowController]) win++;
			}
		}
		
		if( win <= 1)
		{
			[self SyncSeries: self];
		}
	}
	
	[self release];
}


- (void) WindowDidResignMainNotification:(NSNotification *)aNotification
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"]) [self autoHideMatrix];
}

-(void) WindowDidResignKeyNotification:(NSNotification *)aNotification
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"]) [self autoHideMatrix];
}

- (void) WindowDidBecomeMainNotification:(NSNotification *)aNotification
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"]) [self autoHideMatrix];
}

- (void)windowDidChangeScreen:(NSNotification *)aNotification
{
	long i;
	
	if( USETOOLBARPANEL)
	{
		for( i = 0; i < [[NSScreen screens] count]; i++)
		{
			if( [toolbarPanel[ i] toolbar] == toolbar && [[self window] screen] != [[NSScreen screens] objectAtIndex: i])
			{
				[toolbarPanel[ i] setToolbar: 0L];
			}
		}
		
		for( i = 0; i < [[NSScreen screens] count]; i++)
		{
			if( [[self window] screen] == [[NSScreen screens] objectAtIndex: i])
			{
				[toolbarPanel[ i] setToolbar: toolbar];
				NSLog(@"found");
			}
		}
	}
	else
	{
		for( i = 0; i < [[NSScreen screens] count]; i++)
			[[toolbarPanel[ i] window] orderOut:self];
	}
}

- (void) windowDidBecomeKey:(NSNotification *)aNotification
{
	long i;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"]) [self autoHideMatrix];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	if( USETOOLBARPANEL)
	{
		for( i = 0; i < [[NSScreen screens] count]; i++)
		{
			if( [toolbarPanel[ i] toolbar] == toolbar && [[self window] screen] != [[NSScreen screens] objectAtIndex: i])
			{
				[toolbarPanel[ i] setToolbar: 0L];
			}
		}
		
		for( i = 0; i < [[NSScreen screens] count]; i++)
		{
			if( [[self window] screen] == [[NSScreen screens] objectAtIndex: i])
			{
				[toolbarPanel[ i] setToolbar: toolbar];
				NSLog(@"found");
			}
		}
	}
	else
	{
		for( i = 0; i < [[NSScreen screens] count]; i++)
			[[toolbarPanel[ i] window] orderOut:self];
	}
	
	if( fileList[ curMovieIndex] && [[[[fileList[ curMovieIndex] objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"] == NO)
	{
		[browserWindow findAndSelectFile: 0L image:[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] shouldExpand:NO];
	}
}

/*
- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame
{
	NSRect	screenRect    = [[sender screen] visibleFrame];
	if ([sender isZoomed])
		screenRect = newFrame;
		//screenRect = standardRect;
		
	else if( USETOOLBARPANEL ) {
		NSLog(@"toolbar height: %d", [ToolbarPanelController fixedHeight]);
		screenRect.size.height -= [ToolbarPanelController fixedHeight];	
	}
	
	[[self window] setFrame:screenRect display:YES];
	return YES;

	if( USETOOLBARPANEL)
	{
	
		long	i;
		NSRect	screenRect    = [[sender screen] visibleFrame];
		
		screenRect.size.height -= [ToolbarPanelController fixedHeight];
		
		for( i = 0; i < [[NSScreen screens] count]; i++)
		{
			if ( NSPointInRect( newFrame.origin, [[[NSScreen screens] objectAtIndex: i] frame]))
			{
				screenRect = [[[NSScreen screens] objectAtIndex: i] visibleFrame];
				screenRect.size.height -= [[toolbarPanel[ i] window] frame].size.height;
			}
		}
		
		NSLog(@"Wanted: Y: %2.2f Height: %2.2f", newFrame.origin.y, newFrame.size.height);
		
		
		newFrame.origin.y = screenRect.origin.y;
		
		if( newFrame.size.height > screenRect.size.height) newFrame.size.height = screenRect.size.height;
		
		[[self window] setMaxSize: screenRect.size];
		
		[[self window] setFrame:newFrame display:YES];
		
		return NO;
	}
	else
	{
		return YES;	//[[self window] setMaxSize: screenRect.size];
	}
	
}
*/

- (BOOL) is2DViewer
{
	return YES;
}


- (void)closeAllWindows:(NSNotification *)note{
	if (![[note object] isEqual:self]) {
		NSLog(@"close");
		[[self window] close];
	}
}


-(IBAction) fullScreenMenu:(id) sender
{
    if( FullScreenOn == YES ) // we need to go back to non-full screen
    {
        [StartingWindow setContentView: contentView];
    //    [FullScreenWindow setContentView: nil];
    
        [FullScreenWindow setDelegate:nil];
        [FullScreenWindow close];
		[FullScreenWindow release];
        
        
   //     [contentView release];
        
        [StartingWindow makeKeyAndOrderFront: self];
        FullScreenOn = NO;
		
		NSRect	rr = [StartingWindow frame];
		
		rr.size.width--;
		[StartingWindow setFrame: rr display: NO];
		rr.size.width++;
		[StartingWindow setFrame: rr display: YES];
	}
    else // FullScreenOn == false
    {
        unsigned int windowStyle;
        NSRect       contentRect;
        
        StartingWindow = [self window];
        windowStyle    = NSBorderlessWindowMask; 
        contentRect    = [[NSScreen mainScreen] frame];
        FullScreenWindow = [[NSFullScreenWindow alloc] initWithContentRect:contentRect styleMask: windowStyle backing:NSBackingStoreBuffered defer: NO];
        if(FullScreenWindow != nil)
        {
            NSLog(@"Window was created");			
            [FullScreenWindow setTitle: @"myWindow"];			
            [FullScreenWindow setReleasedWhenClosed: NO];
            [FullScreenWindow setLevel: NSScreenSaverWindowLevel - 1];
            [FullScreenWindow setBackgroundColor:[NSColor blackColor]];
            
            contentView = [[self window] contentView];
            [FullScreenWindow setContentView: contentView];
            
            [FullScreenWindow makeKeyAndOrderFront:self ];
            [FullScreenWindow makeFirstResponder:imageView];
            
            [FullScreenWindow setDelegate:self];
            [FullScreenWindow setWindowController: self];
            [splitView adjustSubviews];
			
            FullScreenOn = YES;
        }
    }
}

- (BOOL) FullScreenON { return FullScreenOn;}

-(void) offFullScreen
{
	if( FullScreenOn == YES ) [self fullScreenMenu:self];
}


-(void) UpdateConvolutionMenu: (NSNotification*) note
{
    //*** Build the menu
    NSMenu      *mainMenu;
    NSMenu      *viewerMenu, *convMenu;
    short       i;
    NSArray     *keys;
    NSArray     *sortedKeys;
    
    keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    // Popup Menu

    i = [[convPopup menu] numberOfItems];
    while(i-- > 0) [[convPopup menu] removeItemAtIndex:0];
    
	[[convPopup menu] addItemWithTitle:NSLocalizedString(@"No Filter", nil) action:nil keyEquivalent:@""];
    [[convPopup menu] addItemWithTitle:NSLocalizedString(@"No Filter", nil) action:@selector (ApplyConv:) keyEquivalent:@""];
	[[convPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[convPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyConv:) keyEquivalent:@""];
    }
    [[convPopup menu] addItem: [NSMenuItem separatorItem]];
    [[convPopup menu] addItemWithTitle:NSLocalizedString(@"Add a Filter", nil) action:@selector (AddConv:) keyEquivalent:@""];

	[[[convPopup menu] itemAtIndex:0] setTitle:curConvMenu];
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
    [[wlwwPopup menu] addItem: [NSMenuItem separatorItem]];
    [[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Add Current WL/WW", nil) action:@selector (AddCurrentWLWW:) keyEquivalent:@""];
	[[wlwwPopup menu] addItemWithTitle: NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector (SetWLWW:) keyEquivalent:@""];
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:curWLWWMenu];
	
	[self createDCMViewMenu];
	
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
		NSMutableDictionary *presetsDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] mutableCopy];
		[presetsDict setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:[newName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey: @"WLWW3"];
        
		curWLWWMenu = [newName stringValue];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
		
		[imageView setWLWW: iwl: iww];
    }
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


- (void) dealloc
{
	long	i;

	stopThreadLoadImage = YES;
	if( [browserWindow isCurrentDatabaseBonjour])
	{
		while( [ThreadLoadImageLock tryLock] == NO) [browserWindow bonjourRunLoop: self];
	}
	else [ThreadLoadImageLock lock];
	[ThreadLoadImageLock unlock];
	
	[ThreadLoadImageLock release];
	ThreadLoadImageLock = 0L;

    [[NSNotificationCenter defaultCenter] removeObserver: self];

	[curOpacityMenu release];

	[imageView release];
	
	[seriesView release];
	
	[exportDCM release];

	NSLog(@"ViewController dealloc");
	
	if( USETOOLBARPANEL)
	{
		for( i = 0 ; i < [[NSScreen screens] count]; i++)
			[toolbarPanel[ i] toolbarWillClose : toolbar];
	}
	
    [[self window] setDelegate:nil];
	
    NSArray *windows = [NSApp windows];
    
    if([windows count] < 2)
    {
        [browserWindow showDatabase:self];
    }
	
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Close All Viewers" object:self userInfo: 0L];
	
	numberOf2DViewer--;
	if( numberOf2DViewer == 0)
	{
		USETOOLBARPANEL = NO;
		for( i = 0; i < [[NSScreen screens] count]; i++)
			[[toolbarPanel[ i] window] orderOut:self];
	}
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		[self saveROI: i];
	}
	
//    [[fileList[0] objectAtIndex:0] setViewer: nil forSerie:[[pixList[ 0] objectAtIndex:0] serieNo]];

	for( i = 0; i < maxMovieIndex; i++)
	{
		[roiList[ i] release];
		[pixList[ i] release];
		[fileList[ i] release];
		[volumeData[ i] release];
	}
	
//	NSString *tempDirectory = [documentsDirectory() stringByAppendingString:@"/TEMP/"];
//	if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) [[NSFileManager defaultManager] removeFileAtPath:tempDirectory handler: 0L];
//	[[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory attributes:nil];
	
//	for( i = 0; i < [[NSScreen screens] count] ; i++)
	[toolbar setDelegate: 0L];
	[toolbar release];
	
	[ROINamesArray release];
	
	[thickSlab release];
	
	[curvedController release];
		
	[roiLock release];
	
    [super dealloc];

//	[appController tileWindows: 0L];	<- We cannot do this, because:
//	This is very important, or if we have a queue of closing windows, it will crash....
	[NSObject cancelPreviousPerformRequestsWithTarget:appController selector:@selector(tileWindows:) object:0L];
	[appController performSelector: @selector(tileWindows:) withObject:0L afterDelay: 0.1];
}


- (DCMView*) imageView { return imageView;}


-(NSString*) modality
{
	return [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.modality"];
}

#pragma mark-
#pragma mark 2. window subdivision

- (void) matrixPreviewSelectCurrentSeries
{
	NSManagedObject		*series = [[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"series"];
	long				index = [[[previewMatrix cells] valueForKey:@"representedObject"] indexOfObject: series];
	
	if( index != NSNotFound)
	{
		[previewMatrix selectCellAtRow:index column:0];
		[previewMatrix scrollCellToVisibleAtRow: index column:0];
	}
	else
	{
		[previewMatrix selectCellAtRow:-1 column:-1];
	}
}

- (void) matrixPreviewPressed:(id) sender
{
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSCommandKeyMask) 
	{
		[browserWindow loadSeries :[[sender selectedCell] representedObject] :0L :YES keyImagesOnly: [keyImageDisplay tag]];
		[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
		[self matrixPreviewSelectCurrentSeries];
	}
	else
	{
		if( [[sender selectedCell] representedObject] != [[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"series"])
			[browserWindow loadSeries :[[sender selectedCell] representedObject] :self :YES keyImagesOnly: [keyImageDisplay tag]];
	}
}

-(BOOL) checkFrameSize
{
	NSRect previous, frame;
	
	frame = previous = [[[splitView subviews] objectAtIndex: 0] frame];
	
	if( frame.size.width > 0) frame.size.width = [previewMatrix cellSize].width+13;
	
	if( fabs( frame.size.width - previous.size.width) > 2)
		[[[splitView subviews] objectAtIndex: 0] setFrameSize: frame.size];
		
	if( frame.size.width > 0) return YES;
	else return NO;
}

- (void) autoHideMatrix
{
	BOOL hide = NO;
	
	if( [[self window] isKeyWindow] == NO) hide = YES;
	if( [[self window] isMainWindow] == NO) hide = YES;

	NSPoint	mouse = [[self window] mouseLocationOutsideOfEventStream];
	
	if( hide == NO)
	{
		if( mouse.x >= 0 && mouse.x <= [previewMatrix cellSize].width+13 && mouse.y >= 0 && mouse.y <= [splitView frame].size.height-20)
		{
			
		}
		else hide = YES;
	}
	
	NSRect frame, previous;
	
	frame =  previous  = [[[splitView subviews] objectAtIndex: 0] frame];
	if( hide == NO) frame.size.width = [previewMatrix cellSize].width+13;
	else frame.size.width = 0;
	
	if( previous.size.width != frame.size.width)
	{
		[[[splitView subviews] objectAtIndex: 0] setFrameSize: frame.size];
		[splitView adjustSubviews];
	}
}

-(void) ViewFrameDidChange:(NSNotification*) note
{
	if( [note object] == [[splitView subviews] objectAtIndex: 0])
	{
		BOOL visible = [self checkFrameSize];
		
		if( visible == YES && matrixPreviewBuilt == NO)
		{
			[self buildMatrixPreview];
		}
	}
}

- (float)splitView:(NSSplitView *)sender constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)offset
{
    if( [sender isVertical] == YES)
    {
		NSSize size = [previewMatrix cellSize];
		
        long pos = proposedPosition;
		
		if( pos <  size.width/2) pos = 0;
		else pos = size.width+13;
		
		[splitView saveDefault:@"SPLITVIEWER"];
		
        return (float) pos;
    }
	
	return proposedPosition;
}

- (void) buildMatrixPreview
{
	NSManagedObjectModel	*model = [browserWindow managedObjectModel];
	NSManagedObjectContext	*context = [browserWindow managedObjectContext];
	NSPredicate				*predicate;
	NSFetchRequest			*dbRequest;
	NSError					*error = 0L;
	long					i, x, index = 0;
	NSManagedObject			*curImage = [fileList[0] objectAtIndex:0];
	
	BOOL visible = [self checkFrameSize];
	
	if( visible == NO) matrixPreviewBuilt = NO; 
	else matrixPreviewBuilt = YES;
	
	NSManagedObject			*study = [curImage valueForKeyPath:@"series.study"];
	if( study == 0L) return;
	
	// FIND ALL STUDIES of this patient
	
	predicate = [NSPredicate predicateWithFormat: @"(patientID == %@) AND (name == %@)", [study valueForKey:@"patientID"], [study valueForKey:@"name"]];
	dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: predicate];
	
	[context lock];
	error = 0L;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
	if ([studiesArray count])
	{
		NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
		[sort release];
		
		studiesArray = [studiesArray sortedArrayUsingDescriptors: sortDescriptors];
		
		NSString*		sdf = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortTimeDateFormatString];
		NSDictionary*	locale = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
		
		i = 0;
		for( x = 0; x < [studiesArray count]; x++)
		{
			NSArray				*series = [browserWindow childrenArray: [studiesArray objectAtIndex: x]];
			i += [series count];
		}
		
		[previewMatrix renewRows: i+[studiesArray count] columns: 1];
		[previewMatrix sizeToCells];
		
		for( x = 0; x < [studiesArray count]; x++)
		{
			NSManagedObject		*curStudy = [studiesArray objectAtIndex: x];
			NSArray				*series = [browserWindow childrenArray: curStudy];
			NSArray				*images = [browserWindow imagesArray: curStudy];
			
			if( [series count] != [images count])
			{
				NSLog(@"[series count] != [images count] : You should not be here......");
			}
			
			NSButtonCell *cell = [previewMatrix cellAtRow: index column:0];
				
			[cell setBezelStyle: NSShadowlessSquareBezelStyle];
			[cell setFont:[NSFont boldSystemFontOfSize:9]];
			[cell setButtonType:NSPushOnPushOffButton];
			[cell setEnabled:NO];
			[cell setImage: 0L];
			
			NSString	*name = [curStudy valueForKey:@"studyName"];
			if( [name length] > 15) name = [name substringToIndex: 15];
			[cell setTitle:[NSString stringWithFormat:@"%@\r%@\r%d %@", name, [[curStudy valueForKey:@"date"] descriptionWithCalendarFormat:sdf timeZone:0L locale:locale], [series count], @"series"]];
			
			index++;
			
			for( i = 0; i < [series count]; i++)
			{
				NSManagedObject	*curSeries = [series objectAtIndex:i];
				
				NSButtonCell *cell = [previewMatrix cellAtRow: index column:0];
				
				[cell setBezelStyle: NSShadowlessSquareBezelStyle];
				[cell setRepresentedObject: curSeries];
				[cell setFont:[NSFont systemFontOfSize:9]];
				[cell setImagePosition: NSImageBelow];
				[cell setAction: @selector(matrixPreviewPressed:)];
				[cell setTarget: self];
				[cell setButtonType:NSPushOnPushOffButton];
				[cell setEnabled:YES];
				
				NSString	*name = [curSeries valueForKey:@"name"];
				if( [name length] > 15) name = [name substringToIndex: 15];
				
				NSString	*type = @"Image";
				long count = [[curSeries valueForKey:@"images"] count];
				if( count == 1)
				{
					long frames = [[[[curSeries valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
					if( frames > 1)
					{
						count = frames;
						type = @"Frames";
					}
				}
				else type=[type stringByAppendingString: @"s"];
				
				[cell setTitle:[NSString stringWithFormat:@"%@\r%@\r%d %@", name, [[curSeries valueForKey:@"date"] descriptionWithCalendarFormat:sdf timeZone:0L locale:locale], count, type]];
				
				[previewMatrix setToolTip:[NSString stringWithFormat:@"Series ID:%@\rClick to load this series\rClick + Option to load it in a separate window", [curSeries valueForKey:@"id"]] forCell:cell];
				
				if( [curImage valueForKey:@"series"] == curSeries)
				{
					[previewMatrix selectCellAtRow:index column:0];
					
				}
				
				if( visible)
				{
					DCMPix*     dcmPix = [[DCMPix alloc] myinit: [[images objectAtIndex: i] valueForKey:@"completePath"] :0 :0 :0L :0 :[[[images objectAtIndex: i] valueForKeyPath:@"series.id"] intValue] isBonjour:[browserWindow isCurrentDatabaseBonjour] imageObj:[images objectAtIndex: i]];
					
					if( dcmPix)
					{
						xNSImage *img = [dcmPix computeWImage:YES :0 :0];
						[cell setImage: img];
						[dcmPix release];
					}
				}
				
				index++;
			}
		}
	}
	
	int row, column;
	
	[previewMatrix getRow:&row column:&column ofCell:[previewMatrix selectedCell]];
	[previewMatrix scrollCellToVisibleAtRow: row column:0];
	
	[previewMatrix setNeedsDisplay:YES];
	
	[context unlock];
}


- (void) viewXML:(id) sender
{
	NSString	*path = [browserWindow getLocalDCMPath:[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] : 0]; 

	[[self window] setRepresentedFilename: path];
	
    XMLController * xmlController = [[XMLController alloc] init: path :[NSString stringWithFormat:@"Meta-Data: %@", [[self window] title]]];
    
    [xmlController showWindow:self];
}


#pragma mark-
#pragma mark 3. mouse management

static ViewerController *draggedController = 0L;

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
        //gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
	//a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
	long	i, x, z, iz, xz;
	
    if (nil == carriedData)
    {
        //the operation failed for some reason
        NSRunAlertPanel(NSLocalizedString(@"Paste Error", nil), NSLocalizedString(@"Sorry, but the past operation failed", nil), nil, nil, nil);
        return NO;
    }
    else
    {
        //the pasteboard was able to give us some meaningful data
        if ([desiredType isEqualToString:NSFilenamesPboardType])
        {
            //we have a list of file names in an NSData object
            NSArray				*fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
			NSString			*draggedFile = [fileArray objectAtIndex:0];
 			
			// Find a 2D viewer containing this specific file!
			
			NSArray				*winList = [NSApp windows];
			BOOL				found = NO;
			
			for( i = 0; i < [winList count]; i++)
			{
				if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
				{
					for( z = 0; z < [[[winList objectAtIndex:i] windowController] maxMovieIndex]; z++)
					{
						NSMutableArray  *pList = [[[winList objectAtIndex:i] windowController] pixList: z];
						
						for( x = 0; x < [pList count]; x++)
						{
							if([[[pList objectAtIndex: x] sourceFile] isEqualToString:draggedFile])
							{
								if( found == NO)
								{
									if( [[winList objectAtIndex:i] windowController] == draggedController && draggedController != self)
									{
										found = YES;
										
										blendedwin = [[winList objectAtIndex:i] windowController];
										
										if( [[[blendedwin imageView] curDCM] pwidth] != [[imageView curDCM] pwidth] ||
											[[[blendedwin imageView] curDCM] pheight] != [[imageView curDCM] pheight])
											{
												[blendingTypeMultiply setEnabled: NO];
												[blendingTypeSubtract setEnabled: NO];
												
												[blendingTypeRed	setEnabled: NO];
												[blendingTypeGreen  setEnabled: NO];
												[blendingTypeBlue   setEnabled: NO];
												[blendingTypeRGB   setEnabled: NO];
											}
											
										if( [[[blendedwin pixList] objectAtIndex: 0] isRGB])
										{
											[blendingTypeRed	setEnabled: NO];
											[blendingTypeGreen  setEnabled: NO];
											[blendingTypeBlue   setEnabled: NO];
										}
										else
										{
											[blendingTypeRGB   setEnabled: NO];
										}
										
										// Prepare fusion plug-ins menu
										for( iz = 0; iz < [fusionPluginsMenu numberOfItems]; iz++)
										{
											if( [[fusionPluginsMenu itemAtIndex:iz] hasSubmenu])
											{
												NSMenu  *subMenu = [[fusionPluginsMenu itemAtIndex:iz] submenu];
												
												for( xz = 0; xz < [subMenu numberOfItems]; xz++)
												{
													[[subMenu itemAtIndex:xz] setTarget:self];
													[[subMenu itemAtIndex:xz] setAction:@selector(endBlendingType:)];
												}
											}
											else
											{
												[[fusionPluginsMenu itemAtIndex:iz] setTarget:self];
												[[fusionPluginsMenu itemAtIndex:iz] setAction:@selector(endBlendingType:)];
											}
										}
										[blendingPlugins setMenu: fusionPluginsMenu];
										
										//[self checkEverythingLoaded];
										//[draggedController checkEverythingLoaded];
										
										// What type of blending?
										[NSApp beginSheet: blendingTypeWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
										
										draggedController = 0L;
										// We found the windowcontroller of the incoming file
										//[self ActivateBlending: [[winList objectAtIndex:i] windowController]];
									}
									else if( draggedController == self)
									{
										NSLog(@"Myself => Cancel fusion if previous one!");
										
										[self ActivateBlending: 0L];
									}
								}
							}
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
	
	draggedController = 0L;

    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if( draggedController == 0L)
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
    unichar c = [[event characters] characterAtIndex:0];
    if( c == 3 || c == 13 || c == ' ')
    {
		[self PlayStop:[self findPlayStopButton]];
    }
	else if((c >='1' && c <= '7') | (c >='a' && c <= 'g'))		// SHUTTLE PRO
	{
		if( !timer)  [self PlayStop:[self findPlayStopButton]];  // PLAY
		
		NSLog([event characters]);
		
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
		if( timer)  [self PlayStop:[self findPlayStopButton]];  // STOP
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
		[browserWindow loadNextSeries:[fileList[0] objectAtIndex:0] : -1 :self :YES keyImagesOnly: [keyImageDisplay tag]];
	}
	else if (c == NSRightArrowFunctionKey && ([event modifierFlags] & NSCommandKeyMask))
	{
		[browserWindow loadNextSeries:[fileList[0] objectAtIndex:0] : 1 :self :YES keyImagesOnly: [keyImageDisplay tag]];
	}
	else
    {
        [super keyDown:event];
    }
}

-(void) mouseMoved: (NSEvent*) theEvent
{
	if( windowWillClose) return;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"])
	{
		[self autoHideMatrix];
	}
//	[super mouseMoved: theEvent];
}

- (void) Display3DPoint:(NSNotification*) note
{
	NSMutableArray	*v = [note object];
	
	if( v == pixList[ 0])
	{
		[imageView setIndex: [[[note userInfo] valueForKey:@"z"] intValue]];
		[imageView sendSyncMessage:1];
	}
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


#pragma mark-
#pragma mark 4. toolbox space

- (IBAction)customizeViewerToolBar:(id)sender
{
    [toolbar runCustomizationPalette:sender];
}


- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
    if ([itemIdent isEqualToString: QTSaveToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Export QT", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Export QT", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file", nil)];
	[toolbarItem setImage: [NSImage imageNamed: QTSaveToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(exportQuicktime:)];
    }
	else  if ([itemIdent isEqualToString: iPhotoToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"iPhoto", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"iPhoto", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Export this image to iPhoto", nil)];
	
	[toolbarItem setImage: [NSImage imageNamed: @"iPhoto"]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(export2iPhoto:)];
	
//	// Use a custom view, a text field, for the search item 
//	[toolbarItem setView: iPhotoView];
//	[toolbarItem setMinSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([iPhotoView frame]), NSHeight([iPhotoView frame]))];
    }
	else if ([itemIdent isEqualToString: MailToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Email", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Email", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Email this image", nil)];
	[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector( sendMail:)];
    }
//	else if ([itemIdent isEqual: BrushToolsToolbarItemIdentifier])
//	{        
//		[toolbarItem setLabel: @"BrushTool"];
//		[toolbarItem setPaletteLabel: @"BrushTool"];
//        [toolbarItem setToolTip: @"Brush Palette for plain ROI"];
//		[toolbarItem setImage: [NSImage imageNamed: BrushToolsToolbarItemIdentifier]];
//		[toolbarItem setTarget: self];
//		[toolbarItem setAction: @selector( brushTool:)];
//    }	
	else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"DICOM File", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Save as DICOM", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Export this image/series in a DICOM file", nil)];
	[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
	else if ([itemIdent isEqualToString: Send2PACSToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Send", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Send", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Send this series to a PACS server", nil)];
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
	
	if( SYNCSERIES)
	{
		[toolbarItem setLabel: NSLocalizedString(@"Stop Sync", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Stop Sync", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Stop Sync", nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"SyncLock.tif"]];
	}
	else
	{
		[toolbarItem setLabel: NSLocalizedString(@"Sync Series", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Sync Series", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Sync series from different studies", nil)];
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
	[toolbarItem setToolTip: NSLocalizedString(@"ROI Manager", nil)];
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
	[toolbarItem setImage: [NSImage imageNamed: ReportToolbarItemIdentifier]];
	[toolbarItem setTarget: browserWindow];
	[toolbarItem setAction: @selector(generateReport:)];
    } 
	else if ( [itemIdent isEqualToString: DeleteToolbarItemIdentifier])
	{
	[toolbarItem setLabel: NSLocalizedString(@"Delete", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Delete", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Delete this series from the database and close window", nil)];
	[toolbarItem setImage: [NSImage imageNamed: DeleteToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(deleteSeries:)];
    } 
	
	else if ([itemIdent isEqualToString: TileWindowsToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Tile", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Tile", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Tile Windows", nil)];
	[toolbarItem setImage: [NSImage imageNamed: TileWindowsToolbarItemIdentifier]];
	[toolbarItem setTarget: appController];
	[toolbarItem setAction: @selector(tileWindows:)];
    } 
	else if ([itemIdent isEqualToString: iChatBroadCastToolbarItemIdentifier]) {
	
	[toolbarItem setLabel: NSLocalizedString(@"Broadcast", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Broadcast", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Broadcast", nil)];
	[toolbarItem setImage: [NSImage imageNamed: iChatBroadCastToolbarItemIdentifier]];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(iChatBroadcast:)];
    } 
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
	else if([itemIdent isEqualToString: SubtractionToolbarItemIdentifier]) {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Subtraction", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Subtraction", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Subtraction module", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: subtractView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([subtractView frame]), NSHeight([subtractView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([subtractView frame]),NSHeight([subtractView frame]))];
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
	[toolbarItem setLabel: NSLocalizedString(@"Filters", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Filters", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Apply a filter", nil)];
	
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
	[toolbarItem setToolTip: NSLocalizedString(@"Status & Comments", nil)];
	
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
	[toolbarItem setToolTip: NSLocalizedString(@"RGB Factors", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: RGBFactorsView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([RGBFactorsView frame]), NSHeight([RGBFactorsView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([RGBFactorsView frame]), NSHeight([RGBFactorsView frame]))];
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
	[toolbarItem setToolTip: NSLocalizedString(@"Key Images", nil)];
	
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
   	else if ([itemIdent isEqualToString: VRPanelToolbarItemIdentifier]) {

 	[toolbarItem setLabel: NSLocalizedString(@"3D Panel", nil)];
 	[toolbarItem setPaletteLabel: NSLocalizedString(@"3D Panel", nil)];
 	[toolbarItem setToolTip: NSLocalizedString(@"3D Panel", nil)];
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
    else
	{
		// Is it a plugin menu item?
		if( [pluginsDict objectForKey: itemIdent] != 0L)
		{
			NSBundle *bundle = [pluginsDict objectForKey: itemIdent];
			NSDictionary *info = [bundle infoDictionary];
			
			[toolbarItem setLabel: itemIdent];
			[toolbarItem setPaletteLabel: itemIdent];
			[toolbarItem setToolTip: itemIdent];
			
			NSImage	*image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:[info objectForKey:@"ToolbarIcon"]]] autorelease];
			if( !image ) image = [[NSWorkspace sharedWorkspace] iconForFile: [bundle bundlePath]];
			[toolbarItem setImage: image];
			
			[toolbarItem setTarget: self];
			[toolbarItem setAction: @selector(executeFilterFromToolbar:)];
		}
		else toolbarItem = nil;
    }
    return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	DatabaseWindowToolbarItemIdentifier,
										TileWindowsToolbarItemIdentifier,
										SerieToolbarItemIdentifier,
										PatientToolbarItemIdentifier,
										ToolsToolbarItemIdentifier,
										WLWWToolbarItemIdentifier,
										ReconstructionToolbarItemIdentifier,
										BlendingToolbarItemIdentifier,
										FusionToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										QTSaveToolbarItemIdentifier,
										SyncSeriesToolbarItemIdentifier,
										PlayToolbarItemIdentifier,
										SpeedToolbarItemIdentifier,
										VRPanelToolbarItemIdentifier,
										nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    NSArray		*array = [NSArray arrayWithObjects: 	NSToolbarCustomizeToolbarItemIdentifier,
														NSToolbarFlexibleSpaceItemIdentifier,
														NSToolbarSpaceItemIdentifier,
														NSToolbarSeparatorItemIdentifier,
														MailToolbarItemIdentifier,
														Send2PACSToolbarItemIdentifier,
														ExportToolbarItemIdentifier,
														iPhotoToolbarItemIdentifier,
														QTSaveToolbarItemIdentifier,
														XMLToolbarItemIdentifier,
														ReconstructionToolbarItemIdentifier,
														BlendingToolbarItemIdentifier,
														SyncSeriesToolbarItemIdentifier,
														ResetToolbarItemIdentifier,
														RevertToolbarItemIdentifier,
														SUVToolbarItemIdentifier,
														ROIManagerToolbarItemIdentifier,
														FlipDataToolbarItemIdentifier,
														DatabaseWindowToolbarItemIdentifier,
														TileWindowsToolbarItemIdentifier,
														PlayToolbarItemIdentifier,
														SpeedToolbarItemIdentifier,
														MovieToolbarItemIdentifier,
														SerieToolbarItemIdentifier,
														PatientToolbarItemIdentifier,
														WLWWToolbarItemIdentifier,
														FusionToolbarItemIdentifier,
														SubtractionToolbarItemIdentifier,
														RGBFactorToolbarItemIdentifier,
														FilterToolbarItemIdentifier,
														ToolsToolbarItemIdentifier,
														iChatBroadCastToolbarItemIdentifier,
														StatusToolbarItemIdentifier,
														KeyImagesToolbarItemIdentifier,
														DeleteToolbarItemIdentifier,
														ReportToolbarItemIdentifier,
														FlipVerticalToolbarItemIdentifier,
														FlipHorizontalToolbarItemIdentifier,
														VRPanelToolbarItemIdentifier,
														nil];
	
	long		i;
	NSArray*	allPlugins = [pluginsDict allKeys];
	
	for( i = 0; i < [allPlugins count]; i++)
	{
		NSBundle		*bundle = [pluginsDict objectForKey: [allPlugins objectAtIndex: i]];
		NSDictionary	*info = [bundle infoDictionary];
		//NSLog(@"plugin %@", [[allPlugins objectAtIndex: i] description]);
		if( [[info objectForKey:@"pluginType"] isEqualToString: @"imageFilter"] == YES || [[info objectForKey:@"pluginType"] isEqualToString: @"roiTool"] == YES || [[info objectForKey:@"pluginType"] isEqualToString: @"other"] == YES)
		{	
			//NSLog(@"allow allowToolbarIcon: %@", [[allPlugins objectAtIndex: i] description]);
			if( [info objectForKey:@"allowToolbarIcon"])
			{
				//NSLog(@"allow allowToolbarIcon %@", [bundle description]);
				if( [[info objectForKey:@"allowToolbarIcon"] boolValue] == YES) array = [array arrayByAddingObject: [allPlugins objectAtIndex: i]];
			}
		}
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
    
//    [addedItem retain];
    
//    if ([[addedItem itemIdentifier] isEqualToString: PlayToolbarItemIdentifier]) {
	
    //    playstopItem = addedItem;

//    }
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
 /*   if (removedItem==playstopItem) {
	playstopItem = nil;    
    }*/
    
//    [removedItem release];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
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
	   if([fileList[ curMovieIndex] count] == 1 && [[[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] <=  1 && maxMovieIndex == 1 && blendingController == 0L) enable = NO;
	}
    
    if ([[toolbarItem itemIdentifier] isEqualToString: ReconstructionToolbarItemIdentifier])
    {
        if([fileList[ curMovieIndex] count] == 1 && [[[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] <=  1) enable = NO;
    }
	
	if ([[toolbarItem itemIdentifier] isEqualToString: iChatBroadCastToolbarItemIdentifier])
	{
		if( [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Quicktime/OsiriX Broadcasting.component"] == NO)
		{
			enable = NO;
		}
	}
	
	if([[toolbarItem itemIdentifier] isEqualToString: SUVToolbarItemIdentifier])
	{
		enable = [[imageView curDCM] hasSUV];
	}
	
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
	
	if( tag >= 0) [imageView setCurrentTool: tag];
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
		[[toolsMatrix cellWithTag:5] setEnabled:YES];
		[popupRoi setEnabled:YES];
		[toolsMatrix selectCellWithTag:[imageView currentTool]];
	}
	else
	{
		[[toolsMatrix cellWithTag:5] setEnabled:NO];
		[popupRoi setEnabled:NO];
		[toolsMatrix selectCellWithTag:[imageView currentToolRight]];
	}
}

//revised lp 4/22/04 to work with contextual menus.
-(void) setDefaultTool:(id) sender
{
	if( [[buttonToolMatrix selectedCell] tag] == 0)
		[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:sender userInfo: 0L];
	else
		[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultRightToolModified" object:sender userInfo: 0L];
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
    [[clutPopup menu] addItemWithTitle: NSLocalizedString(@"No CLUT", nil) action:@selector (ApplyCLUT:) keyEquivalent:@""];
	[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
    }
    [[clutPopup menu] addItem: [NSMenuItem separatorItem]];
    [[clutPopup menu] addItemWithTitle: NSLocalizedString(@"Add a CLUT", nil) action:@selector (AddCLUT:) keyEquivalent:@""];

	[[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
}

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar
{
	long i;
	
//	for( i = 0 ; i < [[NSScreen screens] count]; i++)
	{
		// Create a new toolbar instance, and attach it to our document window 
		toolbar = [[NSToolbar alloc] initWithIdentifier: ViewerToolbarIdentifier];
		
		// Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
		[toolbar setAllowsUserCustomization: YES];
		[toolbar setAutosavesConfiguration: YES];
	//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
		
		// We are the delegate
		[toolbar setDelegate: self];
		
		if( USETOOLBARPANEL == NO && [[NSUserDefaults standardUserDefaults] boolForKey: @"USEALWAYSTOOLBARPANEL"] == NO) [[self window] setToolbar: toolbar];
		
		[[self window] setShowsToolbarButton:NO];
		[[[self window] toolbar] setVisible: YES];
    }
//    [window makeKeyAndOrderFront:nil];
}



#pragma mark-
#pragma mark 4.1. single viewport


- (id) viewCinit:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
	self = [super initWithWindowNibName:@"Viewer"];
	
	[self setPixelList:f fileList:d volumeData:v];
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
	   selector: @selector(updateImageView:)
		   name: @"DCMUpdateCurrentImage"
		 object: nil];
//	[nc addObserver: self
//	   selector: @selector(updateImageTiling:)
//		   name:@"DCMImageTilingHasChanged"
//		object: nil];
		
	[seriesView setDCM:pixList[0] :fileList[0] :roiList[0] :0 :'i' :YES];	//[pixList[0] count]/2
	
	[imageView setCurrentTool: tWL];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:toolsMatrix userInfo: 0L];
		
	return self;

}


-(void) changeImageData:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v :(BOOL) applyTransition
{
	BOOL		sameSeries = NO;
	long		i, imageIndex;
	long		type;
	float		startScale;
	long		startWL;
	long		diffWL;
	long		startWW;
	long		previousColumns = [imageView columns], previousRows = [imageView rows];
	NSString	*previousPatientUID = [[[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.patientUID"] retain];

	[[NSNotificationCenter defaultCenter] postNotificationName: @"CloseViewerNotification" object: self userInfo: 0L];

	// Check if another post-processing viewer is open : we CANNOT release the fVolumePtr -> OsiriX WILL crash
	
	long minWindows = 1;
	if( [self FullScreenON]) minWindows++;
	if( [[appController FindRelatedViewers:pixList[0]] count] > minWindows)
	{
		NSLog( @"changeImageData not possible with other post-processing windows opened");
		return;
	}
	
	windowWillClose = YES;
	
	if( previousColumns != 1 || previousRows != 1)
	{
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:1], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"Columns", @"Rows", nil];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMImageTilingHasChanged"  object:self userInfo: userInfo];
	}
	
	// Release previous data
	
	stopThreadLoadImage = YES;
	if( [browserWindow isCurrentDatabaseBonjour])
	{
		while( [ThreadLoadImageLock tryLock] == NO) [browserWindow bonjourRunLoop: self];
	}
	else [ThreadLoadImageLock lock];
	[ThreadLoadImageLock unlock];
	
	long index2compare;
	
	if( [imageView flippedData]) index2compare = [fileList[ 0] count]-1;
	else index2compare = 0;
	
	if( [fileList[ 0] objectAtIndex: index2compare] == [d objectAtIndex: 0])
	{
		NSLog( @"same series");
		if( [d count] >= [fileList[ 0] count])
		{
			sameSeries = YES;
			if( [imageView flippedData]) imageIndex = [fileList[ 0] count] -1 -[imageView curImage];
			else imageIndex = [imageView curImage];
		}
		else imageIndex = 0;
	}
	else
	{
		imageIndex = 0;
	}
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		[self saveROI: i];
		
		[roiList[ i] release];
		[pixList[ i] release];
		[fileList[ i] release];
		[volumeData[ i] release];
	}
	
//	NSString *tempDirectory = [documentsDirectory() stringByAppendingString:@"/TEMP/"];
//	if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) [[NSFileManager defaultManager] removeFileAtPath:tempDirectory handler: 0L];
//	[[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory attributes:nil];

	curCLUTMenu = NSLocalizedString(@"No CLUT", nil);
	curConvMenu = NSLocalizedString(@"No Filter", nil);
	curWLWWMenu = NSLocalizedString(@"Default WL & WW", nil);
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	// Load new data
	curMovieIndex = 0;
	maxMovieIndex = 1;
	
	volumeData[ 0] = v;
	[volumeData[ 0] retain];
	
	direction = 1;
	
    [f retain];
    pixList[ 0] = f;
    
	// Prepare pixList for image thick slab
	for( i = 0; i < [pixList[0] count]; i++)
	{
		[[pixList[0] objectAtIndex: i] setArrayPix: pixList[0] :i];
	}
	

   [d retain];
    fileList[ 0] = d;

	// Prepare roiList
	roiList[0] = [[NSMutableArray alloc] initWithCapacity: 0];
	for( i = 0; i < [pixList[0] count]; i++)
	{
		[roiList[0] addObject:[NSMutableArray arrayWithCapacity:0]];
	}
	[self loadROI:0];
	
 	
	[imageView setDCM:pixList[0] :fileList[0] :roiList[0] :imageIndex :'i' :!sameSeries];
	if( sameSeries) [imageView setIndex: imageIndex];
	else [imageView setIndexWithReset: imageIndex :YES];
		
	DCMPix *curDCM = [pixList[0] objectAtIndex: imageIndex];
	NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
	
	loadingPercentage = 0;
	[self setWindowTitle:self];
	
    [slider setMaxValue:[pixList[0] count]-1];
	[slider setNumberOfTickMarks:[pixList[0] count]];
	[self adjustSlider];
		
	if([fileList[0] count] == 1)
    {
        [speedSlider setEnabled:NO];
        [slider setEnabled:NO];
    }
	else
	{
		[speedSlider setEnabled:YES];
        [slider setEnabled:YES];
	}
    
	[subtractOnOff setState: NSOffState];
	[popFusion selectItemAtIndex:0];
	[convPopup selectItemAtIndex:0];
	[stacksFusion setIntValue:2];
	[sliderFusion setIntValue:1];
	[sliderFusion setEnabled:NO];
	
	[seriesView setDCM:pixList[0] :fileList[0] :roiList[0] :imageIndex :'i' :!sameSeries];
	
//	i = [[NSApp orderedWindows] indexOfObject: [self window]];
//	if( i != NSNotFound)
//	{
//		i++;
//		for( ; i < [[NSApp orderedWindows] count]; i++)
//		{
//			if( [[[[NSApp orderedWindows] objectAtIndex: i] windowController] isKindOfClass:[ViewerController class]])
//			{
//				[[[[[NSApp orderedWindows] objectAtIndex: i] windowController] imageView]  sendSyncMessage:1];
//				[[[[NSApp orderedWindows] objectAtIndex: i] windowController] propagateSettings];
//			}
//		}
//		
//	}
	
	
	
	if( [[self modality] isEqualToString:@"PT"] == YES && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
	{
		if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
			[self ApplyCLUTString: @"B/W Inverse"];
		else
			[self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
	}
	else [self ApplyCLUTString:NSLocalizedString(@"No CLUT", nil)];
	
	NSNumber	*status = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.study.stateText"];
	
	if( status == 0L) [StatusPopup selectItemWithTitle: NSLocalizedString(@"empty", nil)];
	else [StatusPopup selectItemWithTag: [status intValue]];
	
	NSString	*com = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.study.comment"];
	
	if( com == 0L || [com isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"No Comments", nil)];
	else [CommentsField setTitle: com];
	
	if( [[[[fileList[ curMovieIndex] objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"] == NO)
		[browserWindow findAndSelectFile: 0L image :[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] shouldExpand :NO];
		
	////////
	
	if( previousColumns != 1 || previousRows != 1)
	{
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:previousColumns], [NSNumber numberWithInt:previousRows], nil];
		NSArray *keys = [NSArray arrayWithObjects:@"Columns", @"Rows", nil];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMImageTilingHasChanged"  object:self userInfo: userInfo];
	}
	
	if( [previousPatientUID isEqualToString: [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.patientUID"]] == NO)
	{
		[self buildMatrixPreview];
		[self matrixPreviewSelectCurrentSeries];
	}
	else
	{
		[self matrixPreviewSelectCurrentSeries];
	}

	[previousPatientUID release];
	
	// Is it only key images?
	NSArray	*images = fileList[ 0];
	BOOL onlyKeyImages = YES;
	
	for( i = 0; i < [images count]; i++)
	{
		NSManagedObject	*image = [images objectAtIndex: i];
		if( [[image valueForKey:@"isKeyImage"] boolValue] == NO) onlyKeyImages = NO;
	}
	
	if( onlyKeyImages)
	{
		[keyImageDisplay setTag: 1];
		[keyImageDisplay setTitle: NSLocalizedString(@"All Images", nil)];
	}
	else
	{
		[keyImageDisplay setTag: 0];
		[keyImageDisplay setTitle: NSLocalizedString(@"Key Images", nil)];
	}
	
	[imageView becomeMainWindow];	// This will send the image sync order !
	
	windowWillClose = NO;
}

- (void) showWindowTransition
{
	long	type;
	float   startScale;
	long	startWL;
	long	diffWL;
	long	startWW, i;
	NSRect	screenRect;
	
	switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"MULTIPLESCREENS"])
	{
		case 0:		// use main screen only
			screenRect    = [[[NSScreen screens] objectAtIndex:0] visibleFrame];
		break;
		
		case 1:		// use second screen only
			if( [[NSScreen screens] count] > 1)
			{
				screenRect = [[[NSScreen screens] objectAtIndex: 1] visibleFrame];
			}
			else
			{
				screenRect    = [[[NSScreen screens] objectAtIndex:0] visibleFrame];
			}
		break;
		
		case 2:		// use all screens
			screenRect    = [[[NSScreen screens] objectAtIndex:0] visibleFrame];
		break;
	}
	
	if( USETOOLBARPANEL || [[NSUserDefaults standardUserDefaults] boolForKey: @"USEALWAYSTOOLBARPANEL"] == YES)
	{
		screenRect.size.height -= [ToolbarPanelController fixedHeight];
	}
	
	[[self window] setFrame:screenRect display:YES];
	
	switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"WINDOWSIZEVIEWER"])
	{
		case 0:	[[self window] setFrame:screenRect display:YES];	break;
		case 1:	[imageView resizeWindowToScale: 1.0];	break;
		case 2:	[imageView resizeWindowToScale: 1.5];	break;
		case 3:	[imageView resizeWindowToScale: 2.0];	break;
	}
	
	[imageView scaleToFit];
	
//	[[self window] makeKeyAndOrderFront:self];
//	[[self window] makeMainWindow];
//	[self showWindow:self];
}


- (void) startLoadImageThread
{	
	stopThreadLoadImage = NO;
	[NSThread detachNewThreadSelector: @selector(loadImageData:) toTarget: self withObject: nil];
	[self setWindowTitle:self];
}


-(void) loadImageData:(id) sender
{
    NSAutoreleasePool   *pool=[[NSAutoreleasePool alloc] init];
    long				i, x;
	BOOL				isPET = NO;
	
	if( ThreadLoadImageLock == 0L)
	{
		[pool release];
		return;
	}
	
	[ThreadLoadImageLock lock];
	ThreadLoadImage = YES;
	
	NSLog(@"LOADING: Start loading images");
	
	loadingPercentage = 0;
	
	if( [[[fileList[ 0] objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"PT"] == YES) isPET = YES;
	
	float maxValueOfSeries = 0;
	
	for( x = 0; x < maxMovieIndex; x++)
	{
		for( i = 0 ; i < [pixList[ x] count]; i++)
		{
			if( stopThreadLoadImage == NO)
			{
				if ([fileList[ x] count] == [pixList[ x] count]) // I'm not quite sure what this line does, but I'm afraid to take it out. 
					[browserWindow getLocalDCMPath:[fileList[ x] objectAtIndex: i] : 2]; // Anyway, we are not guarantied to have as many files as pixs, so that is why I put in the if() - Joel
				else
					[browserWindow getLocalDCMPath:[fileList[ x] objectAtIndex: 0] : 2]; 
				
				
				DCMPix* pix = [pixList[ x] objectAtIndex: i];
				[pix CheckLoad];
				
				if( maxValueOfSeries < [pix fullwl] + [pix fullww]/2) maxValueOfSeries = [pix fullwl] + [pix fullww]/2;
			}
			
			loadingPercentage = (float) ((x*[pixList[ x] count]) + i) / (float) (maxMovieIndex * [pixList[ x] count]);
			
			while(loadingPause)
			{
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
			}
		}
	}
		
	if( stopThreadLoadImage == NO)
	{
		for( x = 0; x < maxMovieIndex; x++)
		{
			for( i = 0 ; i < [pixList[ x] count]; i++)
			{
				[[pixList[ x] objectAtIndex: i] setMaxValueOfSeries: maxValueOfSeries];
			}
		}
	}
	
	ThreadLoadImage = NO;
	if( stopThreadLoadImage == YES)
	{
		[pool release];
		[ThreadLoadImageLock unlock];
		return;
	}
	
	[ThreadLoadImageLock unlock];
	
	if( stopThreadLoadImage == NO)
	{
		if( isPET)
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ConvertPETtoSUVautomatically"])
			{
				[self performSelectorOnMainThread:@selector( convertPETtoSUV) withObject:nil waitUntilDone: YES];
				
				[imageView performSelectorOnMainThread:@selector( mouseDown:) withObject:[[NSApplication sharedApplication] currentEvent] waitUntilDone: YES];
			}
		}
	}
	
	NSLog(@"LOADING: All images loaded");
	
	if( stopThreadLoadImage == NO)
	{
		[self performSelectorOnMainThread:@selector( computeInterval) withObject:nil waitUntilDone: YES];
		[self performSelectorOnMainThread:@selector( setWindowTitle:) withObject:self waitUntilDone: YES];
	}
	
	loadingPercentage = 1;
	
    [pool release];
}

//static volatile BOOL someoneIsLoading = NO;

-(void) setLoadingPause:(BOOL) lp
{
	loadingPause = lp;
}



- (long) indexForPix: (long) pixIndex
{
	if ([[[fileList[curMovieIndex] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] == 1)
		return pixIndex;
	else
		return 0;
}

- (short) getNumberOfImages
{
    return [pixList[curMovieIndex] count];
}

-(long) maxMovieIndex { return maxMovieIndex;}


- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == blendingController) // our blended serie is closing itself....
	{
		[self ActivateBlending: 0L];
	}
}

- (void)updateImageView:(NSNotification *)note{
	if ([[self window] isEqual:[[note object] window]]) {
		[imageView release];
		imageView = [[note object] retain];
	//	NSLog(@"updateImageView");
	}

	//else
	//	NSLog(@"not my view");
}

-(IBAction) calibrate:(id) sender
{
	[self computeInterval];
	[self SetThicknessInterval:sender];
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
- (void)executeFilterFromString:(NSString*) name
{
	long			result;
    id				filter = [plugins objectForKey:name];
	
	[self checkEverythingLoaded];
	
	NSLog(@"executeFilter");
	
	result = [filter prepareFilter: self];
	if( result)
	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"I cannot launch the selected plugin", nil), nil, nil, nil);
		return;
	}   
	
	result = [filter filterImage: name];
	if( result)
	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"I cannot apply the selected plugin", nil), nil, nil, nil);
		return;
	}
	
	[imageView roiSet];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"recomputeROI" object:self userInfo: 0L];
}


- (void)executeFilter:(id)sender
{
	[self executeFilterFromString: [sender title]];
}

- (void) executeFilterFromToolbar:(id) sender
{
	[self executeFilterFromString: [sender label]];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark 4.1.1.2. Mask Subtraction

- (IBAction) subtractSwitch:(id) sender
{
	short firstAfterMask;
	if( [sender state])
	{
		// subtraction asked for
		
		// mask contains the cardinality of the mask. At initialization, set to 1 (segond image)
		// curImage contains the image in the series to which the mask will be applied
		[imageView setSubtraction: mask :subOffset];
		
		//needs to to to frame 3 ?
		if ([imageView curImage] < (mask + 1)) firstAfterMask=(mask + 1);
		else firstAfterMask=[imageView curImage];		

		float	iww;
		[imageView getWLWW:&wlBeforeSubtract :&iww];
		
		[imageView setWLWW: 0 :iww];
	}
	else
	{
		[imageView setSubtraction: -1 :subOffset];
		
		float	iwl, iww;
		
		[imageView getWLWW:&iwl :&iww];
		[imageView setWLWW: wlBeforeSubtract :iww];
	}
	[imageView setIndex:firstAfterMask];
	[self adjustSlider];
}


- (IBAction) subtractCurrent:(id) sender
{
	if( [subtractOnOff state] == NSOffState)
	{
		[subtractOnOff setState: NSOnState];
		[self subtractSwitch:subtractOnOff];
	}
	
	mask = [imageView curImage];
	[imageView setSubtraction: mask :subOffset];
	
	[subtractIm setIntValue: mask+1];
	[imageView setIndex:[imageView curImage]+1];
	[self adjustSlider];
}


- (IBAction) subtractStepper:(id) sender
{
	switch( [sender tag])
	{
		case 0:
			subOffset.x = [sender floatValue];
			[XOffset setStringValue: [NSString stringWithFormat:@"X: %d", (long) subOffset.x]];
		break;
		
		case 1:
			subOffset.y = [sender floatValue];
			[YOffset setStringValue: [NSString stringWithFormat:@"Y: %d", (long) subOffset.y]];
		break;
	}
	
	if( [subtractOnOff state] == NSOnState)
	{
		[imageView setSubtraction: mask :subOffset];
		[imageView setIndex:[imageView curImage]];
	}
}

#pragma mark-
#pragma mark 4.1.1.3. VOI LUT transformation

- (void) setCurWLWWMenu:(NSString*) s
{
	curWLWWMenu = s;
}


- (IBAction) resetImage:(id) sender
{
	[imageView setOrigin: NSMakePoint( 0, 0)];
	[imageView scaleToFit];
	[imageView setRotation: 0];
	
	[imageView setWLWW:[[imageView curDCM] savedWL] :[[imageView curDCM] savedWW]];
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

- (void) flipData:(char*) ptr :(long) no :(long) size
{
	long i;
	char*	tempData;
	
	NSLog(@"flip data");
	
	size *= 4;
	
	tempData = (char*) malloc( size);
	
	for( i = 0; i < no/2; i++)
	{
		BlockMoveData( ptr + size*i, tempData, size);
		BlockMoveData( ptr + size*(no-1-i), ptr + size*i, size);
		BlockMoveData( tempData, ptr + size*(no-1-i), size);
	}
	
	free( tempData);
}

- (IBAction) flipDataSeries: (id) sender
{
	[self setFusionMode: 0];
	[popFusion selectItemAtIndex:0];
	
	[imageView setFlippedData: ![imageView flippedData]];
	[imageView setIndex: [pixList[ 0] count] -1 -[imageView curImage]];
	
	[self adjustSlider];
	
	[imageView sendSyncMessage:1];
}

-(float) computeInterval
{
	float				interval = [[pixList[ curMovieIndex] objectAtIndex:0] sliceInterval];
	float				vectors[ 9], vectorsB[ 9];
	long				i, x;
	
	if( interval == 0 && [pixList[ curMovieIndex] count] > 1)
	{
		BOOL equalVector = YES;
		
		[[pixList[ curMovieIndex] objectAtIndex:0] orientation: vectors];
		
		[[pixList[ curMovieIndex] objectAtIndex:1] orientation: vectorsB];
		
		for( i = 0; i < 9; i++)
		{
			if( vectors[ i] != vectorsB[ i]) equalVector = NO;
		}
		
		if( equalVector)
		{
			if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
			{
				NSLog(@"Saggital");
				interval = [[pixList[ curMovieIndex] objectAtIndex:0] originX] - [[pixList[ curMovieIndex] objectAtIndex:1] originX];
				
				if( vectors[6] > 0) interval = -( interval);
				else interval = ( interval);
			}
			
			if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
			{
				NSLog(@"Coronal");
				interval = [[pixList[ curMovieIndex] objectAtIndex:0] originY] - [[pixList[ curMovieIndex] objectAtIndex:1] originY];
				
				if( vectors[7] > 0) interval = -( interval);
				else interval = ( interval);
			}
			
			if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
			{
				NSLog(@"Axial");
				interval = [[pixList[ curMovieIndex] objectAtIndex:0] originZ] - [[pixList[ curMovieIndex] objectAtIndex:1] originZ];
				
				if( vectors[8] > 0) interval = -( interval);
				else interval = ( interval);
			}
			
			// FLIP DATA !!!!!! FOR 3D TEXTURE MAPPING !!!!!
			if( interval < 0)
			{
				BOOL sameSize = YES;
				
				DCMPix	*firstObject = [pixList[ curMovieIndex] objectAtIndex: 0];
				
				for(  i = 0 ; i < [pixList[ curMovieIndex] count]; i++)
				{
					if( [firstObject pheight] != [[pixList[ curMovieIndex] objectAtIndex: i] pheight] ) sameSize = NO;
					if( [firstObject pwidth] != [[pixList[ curMovieIndex] objectAtIndex: i] pwidth] ) sameSize = NO;
				}
				
				if( sameSize)
				{
					NSLog(@"Flip Data Now");
					
					interval = -interval;
					
					for( x = 0; x < maxMovieIndex; x++)
					{
						firstObject = [pixList[ x] objectAtIndex: 0];
						
						float	*volumeDataPtr = [firstObject fImage];
						
						[self flipData: (char*) volumeDataPtr :[pixList[ x] count] :[firstObject pheight] * [firstObject pwidth]];
						
						for(  i = 0 ; i < [pixList[ x] count]; i++)
						{
							long offset = ([pixList[ x] count]-1-i)*[firstObject pheight] * [firstObject pwidth];		//
							
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
					
					[self flipDataSeries: self];
				}
			}
			else
			{
				for( x = 0; x < maxMovieIndex; x++)
				{
					for( i = 0; i < [pixList[ x] count]; i++)
					{
						[[pixList[ x] objectAtIndex: i] setSliceInterval: interval];
					}
				}
			}
			
			NSLog( @"Interval: %2.2f", interval);
			NSLog( @"%2.2f %2.2f %2.2f", vectors[0], vectors[1], vectors[2]);
			NSLog( @"%2.2f %2.2f %2.2f", vectors[3], vectors[4], vectors[5]);
			NSLog( @"%2.2f %2.2f %2.2f", vectors[6], vectors[7], vectors[8]);
		}
	}
	
	[blendingController computeInterval];
	
	return interval;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo;
{
	if( returnCode == 1)
	{
		switch( [contextInfo tag])
		{
			case 1: [self MPR2DViewer:contextInfo];		break;  //2DMPR
			case 2: [self MPRViewer:contextInfo];		break;  //3DMPR
			case 3: [self VRViewer:contextInfo];		break;  //MIP
			case 4: [self VRViewer:contextInfo];		break;  //VR
			case 5: [self SRViewer:contextInfo];		break;  //SR
		}
	}
}

-(IBAction) endThicknessInterval:(id) sender
{
	if( [customInterval floatValue] == 0 || [customXSpacing floatValue] == 0 ||  [customYSpacing floatValue] == 0)
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
		long i, x, y;
		float v[ 6], o[ 3];
		
		for( i = 0; i < 6; i++) v[ i] = [[customVectors cellWithTag: i] floatValue];
		for( i = 0; i < 3; i++) o[ i] = [[customOrigin cellWithTag: i] floatValue];
		
		for( i = 0 ; i < maxMovieIndex; i++)
		{
			for( x = 0; x < [pixList[ i] count]; x++)
			{
				DCMPix	*pix = [pixList[ i] objectAtIndex:x];
				
				[pix setSliceInterval: [customInterval floatValue]];
				[pix setPixelSpacingX: fabs([customXSpacing floatValue])];
				[pix setPixelSpacingY: fabs([customYSpacing floatValue])];
				[pix setOrientation: v];
				[pix setOrigin: o];
			}
		}
		[imageView setIndex: [imageView curImage]];
    }
	
    [NSApp endSheet:ThickIntervalWindow returnCode:[sender tag]];
}

- (void) SetThicknessInterval:(id) sender
{
	float v[ 9], o[ 3];
	long i;
	
    [customInterval setFloatValue: [[pixList[ 0] objectAtIndex:0] sliceInterval]];
	[customXSpacing setFloatValue: [[pixList[ 0] objectAtIndex:0] pixelSpacingX]];
	[customYSpacing setFloatValue: [[pixList[ 0] objectAtIndex:0] pixelSpacingY]];
	
	[[pixList[ 0] objectAtIndex:0] orientation: v];
	for( i = 0; i < 6; i++) [[customVectors cellWithTag: i] setFloatValue: v[ i]];
	
	o[ 0] = [[pixList[ 0] objectAtIndex:0] originX];
	o[ 1] = [[pixList[ 0] objectAtIndex:0] originY];
	o[ 2] = [[pixList[ 0] objectAtIndex:0] originZ];
	for( i = 0; i < 3; i++) [[customOrigin cellWithTag: i] setFloatValue: o[ i]];
    
	[NSApp beginSheet: ThickIntervalWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:(void*) sender];
}

- (void)deleteWLWW:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if( returnCode == 1)
    {
		NSMutableDictionary *presetsDict = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] mutableCopy];
        [presetsDict removeObjectForKey: (id) contextInfo];
		[[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey: @"WLWW3"];
		
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
    }
}

- (void) ApplyWLWW:(id) sender
{
	
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Remove a WL/WW preset", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete preset : '%@'?", [sender title]]);
    }
    else
    {
		if( [[sender title] isEqualToString:NSLocalizedString(@"Other", nil)] == YES)
		{
			//[imageView setWLWW:0 :0];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Default WL & WW", nil)] == YES)
		{
			[imageView setWLWW:[[imageView curDCM] savedWL] :[[imageView curDCM] savedWW]];
		}
		else if( [[sender title] isEqualToString:NSLocalizedString(@"Full dynamic", nil)] == YES)
		{
			[imageView setWLWW:0 :0];
		}
		else
		{			
			NSArray		*value;
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] objectForKey: [sender title]];
			[imageView setWLWW:[[value objectAtIndex: 0] floatValue] :[[value objectAtIndex: 1] floatValue]];
		}
		[[[wlwwPopup menu] itemAtIndex:0] setTitle:[sender title]];
		[self propagateSettings];
    }
	
	curWLWWMenu = [sender title];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: imageView userInfo: userInfo];
}

-(IBAction) updateSetWLWW:(id) sender
{
	if( [sender tag] == 0)
	{
		[imageView setWLWW: [wlset intValue] :[wwset intValue]];
		
		[fromset setIntValue: [wlset intValue] - [wwset intValue]/2];
		[toset setIntValue: [wlset intValue] + [wwset intValue]/2];
	}
	else
	{
		[imageView setWLWW: [fromset intValue] + ([toset intValue] - [fromset intValue])/2 :[toset intValue] - [fromset intValue]];
		[wlset setIntValue: [fromset intValue] + ([toset intValue] - [fromset intValue])/2];
		[wwset setIntValue: [toset intValue] - [fromset intValue]];
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
		[imageView setWLWW: [wlset intValue] :[wwset intValue] ];
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
	
    [wlset setStringValue:[NSString stringWithFormat:@"%.0f", cwl ]];
    [wwset setStringValue:[NSString stringWithFormat:@"%.0f", cww ]];
	
	[fromset setIntValue: [wlset floatValue] - [wwset floatValue]/2];
	[toset setIntValue: [wlset floatValue] + [wwset floatValue]/2];
	
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



#pragma mark convolution


- (IBAction) computeSum:(id) sender
{
	long sum, i;
	
	sum = 0;
	for( i = 0; i < 25; i++)
	{
		NSCell  *theCell = [convMatrix cellWithTag: i];
		
		sum += [[theCell stringValue] intValue];
	}
	
	[matrixNorm setIntValue: sum];
	
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
				
				if( x < 1 | x > 3 | y < 1 | y > 3)
				{
					[theCell setEnabled:NO];
					[theCell setStringValue:@""];
					[theCell setAlignment:NSCenterTextAlignment];
				}
				else
				{
					[theCell setEnabled:YES];
					if( [[theCell stringValue] isEqualToString:@""] == YES) [theCell setStringValue:@"0"];
					[theCell setAlignment:NSCenterTextAlignment];
				}
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
				if( [[theCell stringValue] isEqualToString:@""] == YES) [theCell setStringValue:@"0"];
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
		NSMutableDictionary		*convDict=[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] mutableCopy];

		[convDict removeObjectForKey: (id) contextInfo];
		[[NSUserDefaults standardUserDefaults] setObject: convDict forKey: @"Convolution"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
    }
}

-(void) ApplyConvString:(NSString*) str
{
	if( [str isEqualToString:NSLocalizedString(@"No Filter", nil)] == YES)
	{
		[imageView setConv:0L :0: 0];
		[imageView setIndex:[imageView curImage]];
		curConvMenu = str;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
	}
	else
	{
		NSDictionary   *aConv;
		NSArray			*array;
		long			size, i;
		long			nomalization;
		short			matrix[25];
		
		aConv = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] objectForKey:str];
		
		nomalization = [[aConv objectForKey:@"Normalization"] longValue];
		size = [[aConv objectForKey:@"Size"] longValue];
		array = [aConv objectForKey:@"Matrix"];
		
		for( i = 0; i < size*size; i++)
		{
			matrix[i] = [[array objectAtIndex: i] longValue];
		}
		
		[imageView setConv:matrix :size: nomalization];
		[imageView setIndex:[imageView curImage]];
		curConvMenu = str;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
	}
	
	[[[convPopup menu] itemAtIndex:0] setTitle:str];
}

- (void) ApplyConv:(id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Remove a Convolution Filter", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteConv:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete this convolution filter : '%@'", [sender title]]);
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
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
		[matrixNorm setIntValue: nomalization];
		
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
						
						if( x < 1 | x > 3 | y < 1 | y > 3)
						{
							[theCell setEnabled:NO];
							[theCell setStringValue:@""];
							[theCell setAlignment:NSCenterTextAlignment];
						}
						else
						{
							[theCell setEnabled:YES];
							if( [[theCell stringValue] isEqualToString:@""] == YES) [theCell setStringValue:@"0"];
							[theCell setAlignment:NSCenterTextAlignment];
							[[convMatrix cellAtRow:y column:x] setIntValue: [[array objectAtIndex:inc++] longValue]];
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
						if( [[theCell stringValue] isEqualToString:@""] == YES) [theCell setStringValue:@"0"];
						[theCell setAlignment:NSCenterTextAlignment];
						[[convMatrix cellAtRow:y column:x] setIntValue: [[array objectAtIndex:inc++] longValue]];
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
NSMutableArray		*valArray = [NSMutableArray arrayWithCapacity:0];
long				x, y;

	switch( size)
	{
		case 3:
			for( x = 0; x < 5; x++)
			{
				for( y = 0; y < 5; y++)
				{
					NSCell *theCell = [convMatrix cellAtRow:y column:x];
					
					if( x < 1 | x > 3 | y < 1 | y > 3)
					{
					
					}
					else
					{
						[valArray addObject: [NSNumber numberWithLong:[theCell intValue]]];
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
					
					[valArray addObject: [NSNumber numberWithLong:[theCell intValue]]];
				}
			}
		break;
	}
	
	return valArray;
}

-(IBAction) endConv:(id) sender
{
    NSLog(@"endConv");
	
    [addConvWindow orderOut:sender];
    
    [NSApp endSheet:addConvWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		NSMutableDictionary		*aConvFilter = [NSMutableDictionary dictionary];
		NSMutableDictionary		*convDict=[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] mutableCopy];
		NSMutableArray			*valArray;
		short					matrix[25];
		
		[aConvFilter setObject:[NSNumber numberWithLong:[[sizeMatrix selectedCell] tag]] forKey: @"Size"];
		[aConvFilter setObject:[NSNumber numberWithLong:[matrixNorm intValue]] forKey: @"Normalization"];
		
		valArray = [self getMatrix:[[sizeMatrix selectedCell] tag]];
		
		[aConvFilter setObject:valArray forKey: @"Matrix"];
		[convDict setObject:aConvFilter forKey: [matrixName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: convDict forKey: @"Convolution"];
		
		// Apply it!
		
		curConvMenu = [matrixName stringValue];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
		
    }
	[self ApplyConvString: curConvMenu];
}

- (IBAction) convMatrixAction:(id)sender
{
long				i, size = [[sizeMatrix selectedCell] tag];
NSMutableArray		*array;
long				nomalization = [matrixNorm intValue];
short				matrix[25];

	array = [self getMatrix:size];	
	for( i = 0; i < size*size; i++)
	{
		matrix[i] = [[array objectAtIndex: i] longValue];
	}
	
	[imageView setConv:matrix :[[sizeMatrix selectedCell] tag] :[matrixNorm intValue]];
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
			if( [[theCell stringValue] isEqualToString:@""] == YES) [theCell setStringValue:@"0"];
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
		NSMutableDictionary *clutDict	= [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy];
		[clutDict removeObjectForKey: (id) contextInfo];
		[[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"CLUT"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
    }
}

-(void) ApplyCLUTString:(NSString*) str
{
	if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES)
	{
		[imageView setCLUT: 0L :0L :0L];
		if( thickSlab)
		{
			[thickSlab setCLUT:0L :0L :0L];
		}
		
		[imageView setIndex:[imageView curImage]];
		curCLUTMenu = str;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
		
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
			
			[imageView setCLUT:red :green: blue];
			[imageView setIndex:[imageView curImage]];
			curCLUTMenu = str;
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
			
			[self propagateSettings];
			[[[clutPopup menu] itemAtIndex:0] setTitle:str];
		}
	}
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: imageView userInfo: userInfo];
	
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
        NSBeginAlertSheet( NSLocalizedString(@"Remove a Color Look Up Table", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteCLUT:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete this CLUT : '%@'", [sender title]]);
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	}
    else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
    {
		NSDictionary		*aCLUT;
		NSArray				*array;
		long				i;
		unsigned char		red[256], green[256], blue[256];
		
		[self ApplyCLUTString:[sender title]];
		
		aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: curCLUTMenu];
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
		NSMutableDictionary *clutDict		= [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy];
		NSMutableDictionary *aCLUTFilter	= [NSMutableDictionary dictionary];
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
		
		[clutDict setObject: aCLUTFilter forKey: [clutName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"CLUT"];

		// Apply it!
		
		curCLUTMenu = [clutName stringValue];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
		
		[self ApplyCLUTString:curCLUTMenu];
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

//	[imageView setCLUT:matrix :[[sizeMatrix selectedCell] tag] :[matrixNorm intValue]];
	[imageView setIndex:[imageView curImage]];
}


- (void) OpacityChanged: (NSNotification*) note
{
	[thickSlab setOpacity: [[note object] getPoints]];
	
	[self updateImage:self];
}

-(void) ApplyOpacityString:(NSString*) str
{
	NSDictionary		*aOpacity;
	NSArray				*array;
	long				i;
	
	if( [str isEqualToString:NSLocalizedString(@"Linear Table", nil)])
	{
		[thickSlab setOpacity:[NSArray array]];
		curOpacityMenu = str;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
		
		[self updateImage:self];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if (aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			[thickSlab setOpacity:array];
			curOpacityMenu = str;
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
			
			[self updateImage:self];
		}
	}

	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: imageView userInfo: userInfo];
}

- (void) ApplyOpacity: (id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet( NSLocalizedString(@"Remove a Color Look Up Table", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteOpacity:returnCode:contextInfo:), NULL, [sender title], [NSString stringWithFormat:@"Are you sure you want to delete this Opacity Table : '%@'", [sender title]]);
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
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
	
			if( [aOpacity objectForKey:@"Points"] != 0L)
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
		NSMutableDictionary		*opacityDict	= [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] mutableCopy];
		NSMutableDictionary		*aOpacityFilter	= [NSMutableDictionary dictionary];
		NSArray					*points;
		long					i;
		
		[aOpacityFilter setObject: [[OpacityView getPoints] copy] forKey: @"Points"];
		[opacityDict setObject: aOpacityFilter forKey: [OpacityName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: opacityDict forKey: @"OPACITY"];
		
		// Apply it!
		
		curOpacityMenu = [OpacityName stringValue];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];
		
		[self ApplyOpacityString:curOpacityMenu];
    }
	else
	{
		[self ApplyOpacityString:curOpacityMenu];
	}
}

- (NSString*) curCLUTMenu
{
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

- (void) setFusionMode:(long) m
{
	long i, x;
	
	// Thick Slab
	if( m == 4 || m == 5)
	{
		BOOL	flip;
		
		[OpacityPopup setEnabled:YES];
		
		if( thickSlab == 0L)
		{
			unsigned char *r, *g, *b;
			DCMPix  *pix = [pixList[ curMovieIndex] objectAtIndex:0];
			
			thickSlab = [[ThickSlabController alloc] init];
			
			[thickSlab setImageData :[pix pwidth] :[pix pheight] :100 :[pix pixelSpacingX] :[pix pixelSpacingY] :[pix sliceThickness] :flip];
			
			[imageView getCLUT: &r :&g :&b];
			[thickSlab setCLUT:r :g :b];
		}
		
		if( m == 4) flip = YES;
		else flip = NO;
		
		[thickSlab setFlip: flip];
		
		for ( x = 0; x < maxMovieIndex; x++)
		{
			for ( i = 0; i < [pixList[ x] count]; i ++)
			{
				[[pixList[ x] objectAtIndex:i] setThickSlabController: thickSlab];
			}
		}
	}
	else [OpacityPopup setEnabled:NO];
	
	[imageView setFusion:m :-1];
	
	for ( x = 0; x < maxMovieIndex; x++)
	{
		if( x != curMovieIndex) // [imageView setFusion] already did it for current serie!
		{
			for ( i = 0; i < [pixList[ x] count]; i ++)
			{
				[[pixList[ x] objectAtIndex:i] setFusion:m :-1 :-1];
			}
		}
	}
	
	if( m == 0)
	{
		[sliderFusion setEnabled:NO];
	}
	else
	{
		[sliderFusion setEnabled:YES];
	}
	
	[imageView sendSyncMessage:1];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"recomputeROI" object:self userInfo: 0L];
}

- (void) popFusionAction:(id) sender
{
	[self checkEverythingLoaded];
	[self computeInterval];
	
	[self setFusionMode: [[sender selectedItem] tag]];
}

- (void) sliderFusionAction:(id) sender
{
	long x, i;
	
	[imageView setFusion:-1 :[sender intValue]];
	
	for ( x = 0; x < maxMovieIndex; x++)
	{
		if( x != curMovieIndex) // [imageView setFusion] already did it for current serie!
		{
			for ( i = 0; i < [pixList[ x] count]; i ++)
			{
				[[pixList[ x] objectAtIndex:i] setFusion:-1 :[sender intValue] :-1];
			}
		}
	}
	
	[stacksFusion setIntValue:[sender intValue]];
	
	[imageView sendSyncMessage:1];
}
#pragma mark blending
-(void) ActivateBlending:(ViewerController*) bC
{
	if( bC == self) return;
	
	NSLog( @"Blending Activated!");
	
//	[self checkEverythingLoaded];
//	[bC checkEverythingLoaded];
	
	[imageView sendSyncMessage:0];
	
	blendingController = bC;
	
	if( blendingController)
	{
		[imageView setBlending: [blendingController imageView]];
		[blendingSlider setEnabled:YES];
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
		
		if( [[blendingController curCLUTMenu] isEqualToString:NSLocalizedString(@"No CLUT", nil)] && [[[blendingController pixList] objectAtIndex: 0] isRGB] == NO)
		{
			if( [[self modality] isEqualToString:@"PT"] == YES)
			{
				if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
					[self ApplyCLUTString: @"B/W Inverse"];
				else
					[self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
			}
		}
		
		[imageView setBlendingFactor: [blendingSlider floatValue]];
	}
	else
	{
		[imageView setBlending: 0L];
		[blendingSlider setEnabled:NO];
		[blendingPercentage setStringValue:@"-"];
	}
	
	if (bC != self)
		[seriesView ActivateBlending:bC blendingFactor:[blendingSlider floatValue]];
}

-(ViewerController*) blendedWindow
{
	return blendedwin;
}

- (IBAction) endBlendingType:(id) sender
{
	long i;
		
	[blendingTypeWindow orderOut:sender];
	[NSApp endSheet:blendingTypeWindow returnCode:[sender tag]];
	
	switch( [sender tag])
	{
		case -1:	// PLUG-INS METHOD
			[self executeFilter:sender];
		break;
		
		case 1:		// Image fusion
			[self ActivateBlending: blendedwin];
		break;
		
		case 2:		// Image subtraction
			for( i = 0; i < [pixList[ curMovieIndex] count]; i++)
			{
				[imageView setIndex:i];
				[imageView sendSyncMessage:1];
				[imageView display];
				
				[imageView subtract: [blendedwin imageView]];
			}
		break;
		
		case 3:		// Image multiplication
			for( i = 0; i < [pixList[ curMovieIndex] count]; i++)
			{
				[imageView setIndex:i];
				[imageView sendSyncMessage:1];
				[imageView display];
				
				[imageView multiply: [blendedwin imageView]];
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
					DCMPix  *srcPix = [[blendedwin pixList] objectAtIndex: i];
					
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
						
						long i;
						
						cwl = [srcPix wl];
						cww = [srcPix ww];
						
						long min = cwl - cww / 2;
						long max = cwl + cww / 2;
						
						vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, max, min, 0);					// FLOAT TO 8 bit
						
						unsigned char*  srcPtr = dst8.data;
						unsigned char*  dstPtr = (unsigned char*) [dstPix fImage];
						long size = [srcPix pheight] * [srcPix pwidth];
						
						switch( [sender tag])
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
		
		case 7:		// 2D Registration
			[self computeRegistrationWithMovingViewer: blendedwin];
		break;
		
		case 8:		// 3D Registration
		
		break;
	}
	
	blendedwin = 0L;
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

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

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
+ (NSArray*) defaultROINames {return DefaultROINames;}
+ (void) setDefaultROINames: (NSArray*) rn {DefaultROINames = rn;}


extern NSString * documentsDirectory();

#define ROIDATABASE @"/ROIs/"
- (void) loadROI:(long) mIndex
{
	NSString		*path = [documentsDirectory() stringByAppendingString:ROIDATABASE];
	BOOL			isDir = YES;
	long			i, x;
	NSMutableArray  *array;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"SAVEROIS"])
	{
		for( i = 0; i < [fileList[ mIndex] count]; i++)
		{
			if( [[pixList[mIndex] objectAtIndex:i] generated] == NO)
			{
				NSMutableString		*mutStr = [NSMutableString stringWithString: [[fileList[mIndex] objectAtIndex:i] valueForKey:@"uniqueFilename"]];
				[mutStr replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, [mutStr length])];
				NSString			*str = [path stringByAppendingFormat: @"%@-%d",mutStr , [[pixList[mIndex] objectAtIndex:i] frameNo]];
				
				array = [NSUnarchiver unarchiveObjectWithFile: str];
				if( array)
				{
					[[roiList[ mIndex] objectAtIndex:i] addObjectsFromArray:array];
					
					for( x = 0; x < [array count]; x++)
					{
						[imageView roiSet: [array objectAtIndex: x]];
					}
				}
			}
		}
	}
}

- (void) saveROI:(long) mIndex
{
	NSString		*path = [documentsDirectory() stringByAppendingString:ROIDATABASE];
	BOOL			isDir = YES;
	long			i;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"SAVEROIS"])
	{
		for( i = 0; i < [fileList[ mIndex] count]; i++)
		{
			if( [[pixList[mIndex] objectAtIndex:i] generated] == NO)
			{
				NSManagedObject	*image = [fileList[mIndex] objectAtIndex:i];
				
				if( [image isFault] == NO)
				{
					NSMutableString		*mutStr = [NSMutableString stringWithString: [image valueForKey:@"uniqueFilename"]];
					[mutStr replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, [mutStr length])];
					NSString			*str = [path stringByAppendingFormat: @"%@-%d",mutStr , [[pixList[mIndex] objectAtIndex:i] frameNo]];
					
					if( [[roiList[ mIndex] objectAtIndex: i] count] > 0)
					{
						[NSArchiver archiveRootObject: [roiList[ mIndex] objectAtIndex: i] toFile : str];
					}
					else
					{
						[[NSFileManager defaultManager] removeFileAtPath: str handler: 0L];
					}
				}
			}
		}
	}
}

- (ROI*) newROI: (long) type
{
	DCMPix *curPix = [imageView curDCM];
	ROI		*theNewROI;
	
	theNewROI = [[[ROI alloc] initWithType: type :[curPix pixelSpacingX] :[curPix pixelSpacingY] :NSMakePoint( [curPix originX], [curPix originY])] autorelease];
	
	[imageView roiSet: theNewROI];
	
	return theNewROI;
}



- (NSMutableArray*) generateROINamesArray
{
	[ROINamesArray release];	
	ROINamesArray = [[NSMutableArray alloc] initWithCapacity:0];	
	[ROINamesArray addObjectsFromArray: DefaultROINames];	
	// Scan all ROIs of current series to find other names!
	long	y, x, z, i;
	BOOL	first = YES, found;	
	for( y = 0; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[y] count]; x++)
		{
			for( z = 0; z < [[roiList[y] objectAtIndex: x] count]; z++)
			{
			//	NSLog( [[[roiList[y] objectAtIndex: x] objectAtIndex: z] name]);
				found = NO;
				for( i = 0; i < [ROINamesArray count]; i++)
				{
					if( [[ROINamesArray objectAtIndex:i] isEqualToString: [[[roiList[y] objectAtIndex: x] objectAtIndex: z] name]])
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

- (NSImage*) imageForROI: (int) i
{
	NSString	*filename = 0L;
			
	switch( i)
	{
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
	}
	
	return [NSImage imageNamed: filename];
}

// shows on top the first ROI manager window found
- (IBAction) roiGetManager:(id) sender
{
	BOOL	found = NO;
	NSArray *winList = [NSApp windows];
	long i;
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"ROIManager"])
		{
			found = YES;
		}
	}
	
	if( !found)
	{
		ROIManagerController		*manager = [[ROIManagerController alloc] initWithViewer: self];
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
	int cpt=0;
	
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
	
	NSMutableArray* nbRegion=[NSMutableArray arrayWithCapacity:0];
	DCMPix	*curPix = [[self pixList] objectAtIndex: [[self imageView] curImage]];
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
	DCMPix	*curPix = [[self pixList] objectAtIndex: [[self imageView] curImage]];
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
					[[[self roiList] objectAtIndex:[[self imageView] curImage]] addObject:theNewROI];		
					[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:theNewROI userInfo: 0L];
					
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
	int cpt=0;
	
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
	 [[NSColor blueColor] getRed:r green:g blue:b alpha:0L];
	 aColor.red = *r * 65535.;
	 aColor.green = *g * 65535.;
	 aColor.blue = *b * 65535.;
	 rgbList[cpt]=aColor;
	 cpt++;
	 NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
	 //  yellow
	 [[NSColor yellowColor] getRed:r green:g blue:b alpha:0L];
	 aColor.red = *r * 65535.;
	 aColor.green = *g * 65535.;
	 aColor.blue = *b * 65535.;
	 rgbList[cpt]=aColor;
	 cpt++;
	 NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
	 // purpleColor
	 [[NSColor redColor] getRed:r green:g blue:b alpha:0L];
	 aColor.red = *r * 65535.;
	 aColor.green = *g * 65535.;
	 aColor.blue = *b * 65535.;
	 rgbList[cpt]=aColor;
	 cpt++;
	 NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
	 //magentaColor
	 [[NSColor magentaColor] getRed:r green:g blue:b alpha:0L];
	 aColor.red = *r * 65535.;
	 aColor.green = *g * 65535.;
	 aColor.blue = *b * 65535.;
	 rgbList[cpt]=aColor;
	 cpt++;
	 NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
	 // orangeColor
	 [[NSColor orangeColor] getRed:r green:g blue:b alpha:0L];
	 aColor.red = *r * 65535.;
	 aColor.green = *g * 65535.;
	 aColor.blue = *b * 65535.;
	 rgbList[cpt]=aColor;
	 cpt++;
	 NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
	 // redColor
	 [[NSColor redColor] getRed:r green:g blue:b alpha:0L];
	 aColor.red = *r * 65535.;
	 aColor.green = *g * 65535.;
	 aColor.blue = *b * 65535.;
	 rgbList[cpt]=aColor;
	 cpt++;
	 NSLog(@"color r=%d, g=%d, b=%d", aColor.red, aColor.green, aColor.blue);
	 */
	NSMutableArray* nbRegion=[NSMutableArray arrayWithCapacity:0];
	DCMPix	*curPix = [[self pixList] objectAtIndex: [[self imageView] curImage]];
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
	DCMPix	*curPix = [[self pixList] objectAtIndex: [[self imageView] curImage]];
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
					[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:theNewROI userInfo: 0L];
					
				}
	}
}

- (void) deleteSeriesROIwithName: (NSString*) name
{
	long	x, i;
	
	[name retain];
	
	for( x = 0; x < [pixList[curMovieIndex] count]; x++)
	{
		DCMPix	*curDCM = [pixList[curMovieIndex] objectAtIndex: x];
		
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
		{
			ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
			if( [[curROI name] isEqualToString: name])
			{
				[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:curROI userInfo: 0L];
				[[roiList[curMovieIndex] objectAtIndex: x] removeObject:curROI];
				i--;
			}
		}
	}
	
	[name release];
}

- (void) renameSeriesROIwithName: (NSString*) name newName:(NSString*) newString
{
	long	x, i;
	
	[name retain];
	
	for( x = 0; x < [pixList[curMovieIndex] count]; x++)
	{
		DCMPix	*curDCM = [pixList[curMovieIndex] objectAtIndex: x];
		
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
		{
			ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
			if( [[curROI name] isEqualToString: name])
			{
				[curROI setName: newString];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"changeROI" object:curROI userInfo: 0L];
			}
		}
	}
	
	[name release];
}

- (IBAction) roiVolume:(id) sender
{
	long				i, x, y, globalCount, imageCount;
	float				volume = 0, prevArea, preLocation, interval;
	ROI					*selectedRoi = 0L;
	long				err = 0;
	NSMutableArray		*pts;
	
	[self computeInterval];
	
	// Find the first selected
	for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
	{
		long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
		if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
		{
			selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
		}
	}
	
	if( selectedRoi == 0L)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Select an ROI to compute volume of all ROIs with the same name.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	// Check that sliceLocation is available and identical for all images
	preLocation = 0;
	interval = 0;
	
	for( x = 0; x < [pixList[curMovieIndex] count]; x++)
	{
		DCMPix *curPix = [pixList[ curMovieIndex] objectAtIndex: x];
		
		if( preLocation != 0)
		{
			if( interval)
			{
				if( fabs( [curPix sliceLocation] - preLocation - interval) > 1.0 )
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", 0L), NSLocalizedString(@"Slice Interval is not constant!", 0L) , NSLocalizedString(@"OK", 0L), nil, nil);
					return;
				}
			}
			interval = [curPix sliceLocation] - preLocation;
		}
		preLocation = [curPix sliceLocation];
	}
	
	NSLog(@"Slice Interval : %f", interval);
	
	if( interval == 0)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), NSLocalizedString(@"Slice Locations not available to compute a volume.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	NSString	*error;
	
	volume = [self computeVolume: selectedRoi points:&pts error: &error];
	
	if( error)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Volume Error", nil), error , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	ROIVolumeController	*viewer = [[ROIVolumeController alloc] initWithPoints:pts :volume :self];
	[viewer showWindow:self];
	[[viewer window] center];
}

-(IBAction) roiSetPixelsSetup:(id) sender
{
	ROI		*selectedRoi = 0L;
	long	i;
	
	// Find the first selected
	for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
	{
		long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
		if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
		{
			selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
		}
	}
	
	if( selectedRoi == 0L)
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
}

- (IBAction) roiSetPixels:(id) sender
{
	// end sheet
    [roiSetPixWindow orderOut:sender];
    [NSApp endSheet:roiSetPixWindow returnCode:[sender tag]];
    // do it only if OK button pressed
	if( [sender tag] != 1) return;

	// Find the first ROI selected
	ROI *selectedROI = 0L;
	long i;
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
	
	float minValue = -99999;
	float maxValue = 99999;
	if( [checkMaxValue state] == NSOnState) maxValue = [maxValueText floatValue];
	if( [checkMinValue state] == NSOnState) minValue = [minValueText floatValue];

	BOOL propagateIn4D = [setROI4DSeries state] == NSOnState;
	float newValue = [newValueText floatValue];
	
	// proceed
	[self roiSetPixels:selectedROI :allRois :propagateIn4D :outside :minValue :maxValue :newValue];
}

- (IBAction) roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL)propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue :(BOOL) updateVolumeData
{
	long			i, x, y, z;
	float			volume = 0;
	long			err = 0;
	BOOL			done, proceed;
	NSMutableArray	*roiToProceed = [NSMutableArray array];
	NSNumber		*nsnewValue, *nsminValue, *nsmaxValue, *nsoutside;
	
	nsnewValue	= [NSNumber numberWithFloat: newValue];
	nsminValue	= [NSNumber numberWithFloat: minValue];
	nsmaxValue	= [NSNumber numberWithFloat: maxValue];
	nsoutside	= [NSNumber numberWithBool: outside];
	
	WaitRendering *splash = [[WaitRendering alloc] init:@"Filtering..."];
	[splash showWindow:self];
	
	NSLog(@"startSetPixel");

	for( y = 0; y < maxMovieIndex; y++)
	{
		if( propagateIn4D)
		{
			if( y == curMovieIndex) proceed = YES;
			else proceed = NO;
		}
		else proceed = YES;
		
		if( proceed)
		{
			for( x = 0; x < [pixList[y] count]; x++)
			{
				done = NO;
				
				if( allRois == 2)
				{
					DCMPix *curPix = [pixList[ y] objectAtIndex: x];
					[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys: curPix, @"curPix", @"setPixel", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", 0L]];
					
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
									[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [[roiList[y] objectAtIndex: x] objectAtIndex: i], @"roi", curPix, @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", 0L]];
									
									done = YES;
								}
							}
							else
							{
								DCMPix *curPix = [pixList[ y] objectAtIndex: x];
								[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [[roiList[y] objectAtIndex: x] objectAtIndex: i], @"roi", curPix, @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", 0L]];
								
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
							[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys: curPix, @"curPix", @"setPixel", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", 0L]];

						}
					}
					else
					{
						DCMPix *curPix = [pixList[ y] objectAtIndex: x];
						[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys: curPix, @"curPix", @"setPixel", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", 0L]];
					}
				}
			}
		}
	}
	
	if( [roiToProceed count])
	{
		// Create a scheduler
		id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
		[sched setDelegate: self];
		
		// Create the work units.
		long i;
		NSMutableSet *unitsSet = [NSMutableSet set];
		for ( i = 0; i < [roiToProceed count]; i++ )
		{
			[unitsSet addObject: [roiToProceed  objectAtIndex: i]];
		}
		
		[sched performScheduleForWorkUnits:unitsSet];
		
		while( [sched numberOfDetachedThreads] > 0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		
		[sched release];
	}
	
	[splash close];
	[splash release];
	
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
	
	if( updateVolumeData)
		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ curMovieIndex] userInfo: 0L];
		
	NSLog(@"endSetPixel");
}

- (IBAction) roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL)propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue
{
	[self roiSetPixels:aROI :allRois :propagateIn4D :outside :minValue :maxValue :newValue :YES];
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
					
					[[NSNotificationCenter defaultCenter] postNotificationName: @"changeROI" object:curROI userInfo: 0L];
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
							
							[[NSNotificationCenter defaultCenter] postNotificationName: @"changeROI" object:curROI userInfo: 0L];
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
						
						[[NSNotificationCenter defaultCenter] postNotificationName: @"changeROI" object:curROI userInfo: 0L];
					}
				}
			break;
		}
	}
}

- (IBAction) roiRename:(id) sender
{
	[NSApp beginSheet: roiRenameWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction) roiDeleteAll:(id) sender
{
	long i, x, y;
	
	for( y = 0; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[y] count]; x++)
		{
			//[[roiList[y] objectAtIndex: x] removeAllObjects];
			for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
			{
				ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
				//[[roiList[y] objectAtIndex: x] removeObjectAtIndex:i];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:curROI userInfo: 0L];
			}
			[[roiList[y] objectAtIndex: x] removeAllObjects];
		}
	}
	
	[imageView setIndex: [imageView curImage]];
}

- (IBAction) roiPropagateSetup: (id) sender
{
	ROI		*selectedRoi = 0L;
	long	i;
	
	if( [pixList[curMovieIndex] count] > 1)
	{
		// Find the first selected
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
		{
			long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
			if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
			{
				selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
			}
		}
		
		if( selectedRoi == 0L)
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
	long i, x;
	
	for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
	{
		long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
		if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
		{
			ROI		*theROI = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
			NSArray *winList = [NSApp windows];
			BOOL	found = NO;
			
			for( x = 0; x < [winList count]; x++)
			{
				if( [[[[winList objectAtIndex:x] windowController] windowNibName] isEqualToString:@"Histogram"])
				{
					if( [[[winList objectAtIndex:x] windowController] curROI] == theROI)
					{
						found = YES;
						[[[[winList objectAtIndex:x] windowController] window] makeKeyAndOrderFront:self];
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
	long i, x;
	
	for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
	{
		long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
		if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
		{
			ROI		*theROI = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
			NSArray *winList = [NSApp windows];
			BOOL	found = NO;
			
			for( x = 0; x < [winList count]; x++)
			{
				if( [[[[winList objectAtIndex:x] windowController] windowNibName] isEqualToString:@"ROI"])
				{
					if( [[[winList objectAtIndex:x] windowController] curROI] == theROI)
					{
						found = YES;
						[[[[winList objectAtIndex:x] windowController] window] makeKeyAndOrderFront:self];
					}
				}
			}
			
			if( found == NO)
			{
				ROIWindow* roiWin = [[ROIWindow alloc] initWithROI: theROI :self];
				[roiWin showWindow:self];
			}
		}
	}
}

- (IBAction) roiDefaults:(id) sender
{
	long x;
	NSArray *winList = [NSApp windows];
				
	for( x = 0; x < [winList count]; x++)
	{
		if( [[[[winList objectAtIndex:x] windowController] windowNibName] isEqualToString:@"ROIDefaults"])
		{
			[[[[winList objectAtIndex:x] windowController] window] makeKeyAndOrderFront:self];
			return;
		}
	}
	
	ROIDefaultsWindow* roiDefaultsWin = [[ROIDefaultsWindow alloc] initWithController: self];
	[roiDefaultsWin showWindow:self];
}

- (IBAction) roiPropagateSlab:(id) sender
{
	NSMutableArray  *selectedROIs = [NSMutableArray  arrayWithCapacity:0];
	
	if( [[pixList[curMovieIndex] objectAtIndex:[imageView curImage]] stack] < 2)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"ROIs Propagate Error", nil), NSLocalizedString(@"This function is only usefull if you use Thick Slab!", nil) , NSLocalizedString(@"OK", nil), nil, nil, nil);
	}
	
	if( [pixList[curMovieIndex] count] > 1)
	{
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
						ROI *newROI = [NSUnarchiver unarchiveObjectWithData: [NSArchiver archivedDataWithRootObject: [selectedROIs objectAtIndex: i]]];
						
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

- (IBAction) roiPropagate:(id) sender
{
	long			i, x;

    [roiPropaWindow orderOut:sender];
    
    [NSApp endSheet:roiPropaWindow returnCode:[sender tag]];
    
	if( [sender tag] != 1) return;

	NSMutableArray  *selectedROIs = [NSMutableArray  arrayWithCapacity:0];
	
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
					startImage = [imageView curImage];
					upToImage = [roiPropaDest floatValue];
					
					if( upToImage > [pixList[curMovieIndex] count]) upToImage = [pixList[curMovieIndex] count];
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
									ROI *newROI = [NSUnarchiver unarchiveObjectWithData: [NSArchiver archivedDataWithRootObject: [selectedROIs objectAtIndex: i]]];
									
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
				long upToImage, startImage;
				
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
									ROI *newROI = [NSUnarchiver unarchiveObjectWithData: [NSArchiver archivedDataWithRootObject: [selectedROIs objectAtIndex: i]]];
									
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

-(void) setROITool:(int) roitype name :(NSString*) title
{
	NSButtonCell *cell = [toolsMatrix cellAtRow:0 column:5];
	[cell setTag: roitype];
	[cell setImage: [self imageForROI: roitype]];
	
	[toolsMatrix selectCellAtRow:0 column:5];
	
	[self setDefaultToolMenu:[toolsMatrix selectedCell]];
	//change Image in contextual menu 4/22/04
	NSMenu *menu = [imageView menu];
	[[menu itemAtIndex:5] setImage: [self imageForROI: roitype]];
	[[menu itemAtIndex:5] setTag:roitype];
}

-(void) setROITool:(id) sender
{
	[self setROITool: [sender tag] name:[sender title]];
	
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

- (NSArray*) roisWithName: (NSString*) name
{
	int x, i;
	
	NSMutableArray *rois = [NSMutableArray array];
	
	for( x = 0; x < [pixList[curMovieIndex] count]; x++)
	{
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
		{
			ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
			if( [[curROI name] isEqualToString: name])
			{
				[curROI setPix:[pixList[curMovieIndex] objectAtIndex: x]];
				[rois addObject: curROI];
			}
		}
	}
	return rois;
}


- (MyPoint*) newPoint: (float) x :(float) y
{
	return( [MyPoint point: NSMakePoint(x, y)]);
}


- (void) roiChange :(NSNotification*) note
{
	if( curvedController)
	{
		if( [note object] == [curvedController roi])
		{
			[curvedController recompute];
		}
	}
}

#pragma mark BrushTool and ROI filters

-(void) brushTool:(id) sender
{
	BOOL	found = NO;
	NSArray *winList = [NSApp windows];
	long i;
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"PaletteBrush"])
		{
			found = YES;
		}
	}
	
	if( !found)
	{
		PaletteController *palette = [[PaletteController alloc] initWithViewer: self];
	}
//	else [self setROITool: tPlain name:@"Brush"];
}

- (NSLock*) roiLock { return roiLock;}

//obligatory class for protocol Schedulable.h
-(void)performWorkUnits:(NSSet *)workUnits forScheduler:(Scheduler *)scheduler
{
	NSEnumerator	*enumerator = [workUnits objectEnumerator];
	NSDictionary	*object;
	
	[roiLock lock];
	
	while (object = [enumerator nextObject])
	{
		// ** Set Pixels
		
		if( [[object valueForKey:@"action"] isEqualToString:@"setPixel"])
			[[object objectForKey:@"curPix"] fillROI:0L :[[object objectForKey:@"newValue"] floatValue] :[[object objectForKey:@"minValue"] floatValue] :[[object objectForKey:@"maxValue"] floatValue] :[[object objectForKey:@"outside"] boolValue] :2 :-1];

		if( [[object valueForKey:@"action"] isEqualToString:@"setPixelRoi"])
			[[object objectForKey:@"curPix"] fillROI:[object objectForKey:@"roi"] :[[object objectForKey:@"newValue"] floatValue] :[[object objectForKey:@"minValue"] floatValue] :[[object objectForKey:@"maxValue"] floatValue] :[[object objectForKey:@"outside"] boolValue] :2 :-1];
		
		// ** Math Morphology
		
		if( [[object valueForKey:@"action"] isEqualToString:@"close"])
			[[object objectForKey:@"filter"] close: [object objectForKey:@"roi"] withStructuringElementRadius: [[object objectForKey:@"radius"] intValue]];
		
		if( [[object valueForKey:@"action"] isEqualToString:@"open"])
			[[object objectForKey:@"filter"] open: [object objectForKey:@"roi"] withStructuringElementRadius: [[object objectForKey:@"radius"] intValue]];
		
		if( [[object valueForKey:@"action"] isEqualToString:@"dilate"])
			[[object objectForKey:@"filter"] dilate: [object objectForKey:@"roi"] withStructuringElementRadius: [[object objectForKey:@"radius"] intValue]];
		
		if( [[object valueForKey:@"action"] isEqualToString:@"erode"])
			[[object objectForKey:@"filter"] erode: [object objectForKey:@"roi"] withStructuringElementRadius: [[object objectForKey:@"radius"] intValue]];
	}
	
	[roiLock unlock];
}

- (void) applyMorphology: (NSArray*) rois action:(NSString*) action	radius: (long) radius sendNotification: (BOOL) sendNotification
{
	// Create a scheduler
	id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
	[sched setDelegate: self];
	
	ITKBrushROIFilter *filter = [[ITKBrushROIFilter alloc] init];
	
	// Create the work units.
	long i;
	NSMutableSet *unitsSet = [NSMutableSet set];
	for ( i = 0; i < [rois count]; i++ )
	{
		[unitsSet addObject: [NSDictionary dictionaryWithObjectsAndKeys: [rois objectAtIndex:i], @"roi", action, @"action", filter, @"filter", [NSNumber numberWithInt: radius], @"radius", 0L]];
	}
	
	[sched performScheduleForWorkUnits:unitsSet];
	
	while( [sched numberOfDetachedThreads] > 0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	
	[sched release];
	
	if( sendNotification)
		for ( i = 0; i < [rois count]; i++ ) [[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:[rois objectAtIndex:i] userInfo: 0L];
	
	[filter release];
}

- (ROI*) selectedROI
{
	ROI *selectedRoi = 0L;
	int i;
	for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
	{
		long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
		if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
		{
			selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
		}
	}
	return selectedRoi;
}

- (IBAction) setStructuringElementRadius: (id) sender
{
	[structuringElementRadiusTextField setStringValue:[NSString stringWithFormat:@"%d",[structuringElementRadiusSlider intValue]]];
}

- (IBAction) closeBrushROIFilterOptionsSheet: (id) sender
{
	[brushROIFilterOptionsWindow orderOut:sender];
	[NSApp endSheet:brushROIFilterOptionsWindow];
}

- (IBAction) erodeSelectedBrushROIWithRadius: (id) sender
{
	[self closeBrushROIFilterOptionsSheet:self];
	
	ROI *selectedROI = [self selectedROI];

	// do the erosion...
	
	WaitRendering	*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing Erosion...",0L)];
	[wait showWindow:self];
	if ([brushROIFilterOptionsAllWithSameName state]==NSOffState)
	{
		[self applyMorphology: [NSArray arrayWithObject:selectedROI] action:@"erode" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	else
	{
		[self applyMorphology: [self roisWithName:[selectedROI name]] action:@"erode" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	[wait close];
	[wait release];
}

- (IBAction) erodeSelectedBrushROI: (id) sender
{
	ROI *selectedROI = [self selectedROI];
	
	if (selectedROI && [selectedROI type]==tPlain)
	{
		[NSApp beginSheet:brushROIFilterOptionsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		[brushROIFilterOptionsOKButton setAction:@selector(erodeSelectedBrushROIWithRadius:)];
		[brushROIFilterOptionsOKButton setTarget:self];
	}
	else
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Brush ROI Erode Error", nil), NSLocalizedString(@"Select a Brush ROI before to run the filter.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
}

- (IBAction) dilateSelectedBrushROIWithRadius: (id) sender
{
	[self closeBrushROIFilterOptionsSheet:self];
	
	ROI *selectedROI = [self selectedROI];

	// do the dilatation...
	ITKBrushROIFilter *filter = [[ITKBrushROIFilter alloc] init];

	WaitRendering	*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing Dilatation...",0L)];
	[wait showWindow:self];
	if ([brushROIFilterOptionsAllWithSameName state]==NSOffState)
	{
		[self applyMorphology: [NSArray arrayWithObject:selectedROI] action:@"dilate" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	else
	{
		[self applyMorphology: [self roisWithName:[selectedROI name]] action:@"dilate" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	[filter release];
	[wait close];
	[wait release];
}

- (IBAction) dilateSelectedBrushROI: (id) sender
{
	ROI *selectedROI = [self selectedROI];
	
	if (selectedROI && [selectedROI type]==tPlain)
	{
		[NSApp beginSheet:brushROIFilterOptionsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		[brushROIFilterOptionsOKButton setAction:@selector(dilateSelectedBrushROIWithRadius:)];
		[brushROIFilterOptionsOKButton setTarget:self];
	}
	else
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Brush ROI Dilate Error", nil), NSLocalizedString(@"Select a Brush ROI before to run the filter.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
}

- (IBAction) closeSelectedBrushROIWithRadius: (id) sender
{
	[self closeBrushROIFilterOptionsSheet:self];
	
	ROI *selectedROI = [self selectedROI];

	// do the closing...
	ITKBrushROIFilter *filter = [[ITKBrushROIFilter alloc] init];

	WaitRendering	*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing Closing...",0L)];
	[wait showWindow:self];
	if ([brushROIFilterOptionsAllWithSameName state]==NSOffState)
	{
		[self applyMorphology: [NSArray arrayWithObject:selectedROI] action:@"close" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	else
	{
		[self applyMorphology: [self roisWithName:[selectedROI name]] action:@"close" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	[filter release];
	[wait close];
	[wait release];
}

- (IBAction) closeSelectedBrushROI: (id) sender
{
	ROI *selectedROI = [self selectedROI];
	
	if (selectedROI && [selectedROI type]==tPlain)
	{
		[NSApp beginSheet:brushROIFilterOptionsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		[brushROIFilterOptionsOKButton setAction:@selector(closeSelectedBrushROIWithRadius:)];
		[brushROIFilterOptionsOKButton setTarget:self];
	}
	else
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Brush ROI Close Error", nil), NSLocalizedString(@"Select a Brush ROI before to run the filter.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
}

- (IBAction) openSelectedBrushROIWithRadius: (id) sender
{
	[self closeBrushROIFilterOptionsSheet:self];
	
	ROI *selectedROI = [self selectedROI];

	// do the opening...
	ITKBrushROIFilter *filter = [[ITKBrushROIFilter alloc] init];

	WaitRendering	*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing Opening...",0L)];
	[wait showWindow:self];
	if ([brushROIFilterOptionsAllWithSameName state]==NSOffState)
	{
		[self applyMorphology: [NSArray arrayWithObject:selectedROI] action:@"open" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	else
	{
		[self applyMorphology: [self roisWithName:[selectedROI name]] action:@"open" radius: [structuringElementRadiusSlider intValue] sendNotification:YES];
	}
	[filter release];
	[wait close];
	[wait release];
}

- (IBAction) openSelectedBrushROI: (id) sender
{
	ROI *selectedROI = [self selectedROI];
	
	if (selectedROI && [selectedROI type]==tPlain)
	{
		[NSApp beginSheet:brushROIFilterOptionsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		[brushROIFilterOptionsOKButton setAction:@selector(openSelectedBrushROIWithRadius:)];
		[brushROIFilterOptionsOKButton setTarget:self];
	}
	else
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Brush ROI Open Error", nil), NSLocalizedString(@"Select a Brush ROI before to run the filter.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
}
#pragma mark SUV
- (void) convertPETtoSUV
{
	long	y, x, i;
	BOOL	updatewlww = NO;
	float	updatefactor;
	float	maxValueOfSeries = 0;
	
	if( [[imageView curDCM] radionuclideTotalDoseCorrected] <= 0) return;
	if( [[imageView curDCM] patientsWeight] <= 0) return;
	
	if( [[imageView curDCM] SUVConverted] == NO)
	{
		updatewlww = YES;
		updatefactor = [[imageView curDCM] patientsWeight] * 1000. / [[imageView curDCM] radionuclideTotalDoseCorrected];
	}
	
	maxValueOfSeries = 0;
	
	for( y = 0; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[y] count]; x++)
		{
			DCMPix	*pix = [pixList[y] objectAtIndex: x];
			
			if( [pix SUVConverted] == NO)
			{
				float	*imageData = [pix fImage];
				float	factor = [pix patientsWeight] * 1000. / ([pix radionuclideTotalDoseCorrected]);
				
				i = [pix pheight] * [pix pwidth];
				
				while( i--> 0)
				{
					*imageData++ *=  factor;
				}
				
				[pix setSUVConverted : YES];
			}
			
			[pix computePixMinPixMax];
			
			if( maxValueOfSeries < [pix fullwl] + [pix fullww]/2) maxValueOfSeries = [pix fullwl] + [pix fullww]/2;
		}
	}
	
	for( y = 0; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[y] count]; x++)
		{
			[[pixList[y] objectAtIndex: x] setMaxValueOfSeries: maxValueOfSeries];
		}
	}
	
	if(  updatewlww)
	{
		float cwl, cww;
			
		[imageView getWLWW:&cwl :&cww];
		[imageView setWLWW: cwl * updatefactor : cww * updatefactor];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ curMovieIndex] userInfo: 0L];
	
	for( y = 0; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[y] count]; x++) [[pixList[y] objectAtIndex: x] setDisplaySUVValue: YES];
	}
}

-(IBAction) endDisplaySUV:(id) sender
{
	long y, x, i;
	
	if( [sender tag] == 1)
	{
		BOOL savedDefault = [[NSUserDefaults standardUserDefaults] boolForKey: @"ConvertPETtoSUVautomatically"];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ConvertPETtoSUVautomatically"];
		
		if( [[imageView curDCM] SUVConverted]) [self revertSeries:self];
		
		[[NSUserDefaults standardUserDefaults] setBool:savedDefault forKey:@"ConvertPETtoSUVautomatically"];
		
		for( y = 0; y < maxMovieIndex; y++)
		{
			for( x = 0; x < [pixList[y] count]; x++) [[pixList[y] objectAtIndex: x] setDisplaySUVValue: NO];
		}
		
		if( [[suvForm cellAtIndex: 0] floatValue] > 0)	//&& [[suvForm cellAtIndex: 1] floatValue])
		{
			for( y = 0; y < maxMovieIndex; y++)
			{
				for( x = 0; x < [pixList[y] count]; x++)
				{
					[[pixList[y] objectAtIndex: x] setPatientsWeight: [[suvForm cellAtIndex: 0] floatValue]];
				}
			}
			
			[[NSUserDefaults standardUserDefaults] setInteger: [[suvConversion selectedCell] tag] forKey:@"SUVCONVERSION"];
			
			float maxValueOfSeries = 0;
			
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
				
					maxValueOfSeries = 0;
					for( y = 0; y < maxMovieIndex; y++)
					{
						for( x = 0; x < [pixList[y] count]; x++)
						{
							DCMPix	*pix = [pixList[y] objectAtIndex: x];
							
							[pix computePixMinPixMax];
							
							if( maxValueOfSeries < [pix fullwl] + [pix fullww]/2) maxValueOfSeries = [pix fullwl] + [pix fullww]/2;
						}
					}
					
					for( y = 0; y < maxMovieIndex; y++)
					{
						for( x = 0; x < [pixList[y] count]; x++)
						{
							[[pixList[y] objectAtIndex: x] setMaxValueOfSeries: maxValueOfSeries];
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"recomputeROI" object:self userInfo: 0L];
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
		[[suvForm cellAtIndex: 1] setStringValue: [NSString stringWithFormat:@"%2.3f / %2.3f", [[imageView curDCM] radionuclideTotalDose] / 1000000., [[imageView curDCM] radionuclideTotalDoseCorrected] / 1000000. ]];
		
		if( [[imageView curDCM] radiopharmaceuticalStartTime])
			[[suvForm cellAtIndex: 2] setStringValue: [[[[[imageView curDCM] radiopharmaceuticalStartTime] description] substringFromIndex:11] substringToIndex:8]];
		
		if( [[imageView curDCM] radiopharmaceuticalStartTime])
			[[suvForm cellAtIndex: 3] setStringValue: [[[[[imageView curDCM] acquisitionTime] description] substringFromIndex:11] substringToIndex:8]];
		
		[[suvForm cellAtIndex: 4] setStringValue: [NSString stringWithFormat:@"%2.2f", [[imageView curDCM] halflife] / 60.]];
		
		[NSApp beginSheet: displaySUVWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	}
}


#pragma mark-
#pragma mark 4.1.4 Anchored textual layer

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
	unsigned long i, x;
	
	NSArray *items = [toolbar items];
	
	for( i = 0; i < [items count]; i++)
	{
		if( [[[items objectAtIndex:i] itemIdentifier] isEqualToString:SyncSeriesToolbarItemIdentifier] == YES)
		{
			return [items objectAtIndex:i];
		}
	}
	return nil;
}


- (void) notificationSyncSeries:(NSNotification*)note
{
	if( SYNCSERIES)
	{
		NSNumber *sliceLocation = [[note userInfo] objectForKey:@"sliceLocation"];
		float offset = [[[imageView dcmPixList] objectAtIndex:[imageView  curImage]] sliceLocation] - [sliceLocation floatValue];
		[imageView setSyncRelativeDiff:offset];
		[[self findSyncSeriesButton] setLabel: NSLocalizedString(@"Stop Sync", nil)];
		[[self findSyncSeriesButton] setPaletteLabel: NSLocalizedString(@"Stop Sync", nil)];
		[[self findSyncSeriesButton] setToolTip: NSLocalizedString(@"Stop Sync", nil)];
		[[self findSyncSeriesButton] setImage: [NSImage imageNamed: @"SyncLock.tif"]];
		[[appController syncSeriesMenuItem] setState:NSOnState];
		
		[imageView setSyncSeriesIndex: [imageView curImage]];
	}
	else
	{
		[[self findSyncSeriesButton] setLabel: NSLocalizedString(@"Sync Series", nil)];
		[[self findSyncSeriesButton] setPaletteLabel: NSLocalizedString(@"Sync Series", nil)];
		[[self findSyncSeriesButton] setToolTip: NSLocalizedString(@"Sync series from different studies", nil)];
		[[self findSyncSeriesButton] setImage: [NSImage imageNamed: SyncSeriesToolbarItemIdentifier]];
		[[appController syncSeriesMenuItem] setState:NSOffState];
		[imageView setSyncSeriesIndex: -1];
	}
}

- (void) SyncSeries:(id) sender
{
	SYNCSERIES = !SYNCSERIES;
	
	float sliceLocation =  [[[imageView dcmPixList] objectAtIndex:[imageView  curImage]] sliceLocation];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat:sliceLocation] forKey:@"sliceLocation"];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"notificationSyncSeries" object:0L userInfo: userInfo];
}


-(void) propagateSettings
{
	long				i;
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList;
	
	if( [[[[fileList[0] objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"] == YES) return;
	
	// *** 2D Viewers ***
	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	for( i = 0; i < [winList count]; i++)
	{
		//if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"Viewer"])
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
		{
			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		ViewerController	*vC = [viewersList objectAtIndex: i];
		
		float   iwl, iww;
		
		// 4D data
		if( curMovieIndex != [vC curMovieIndex])
		{
			[vC setMovieIndex: curMovieIndex];
		}
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"] == YES)
		{
			if( [[vC curCLUTMenu] isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES && [[self curCLUTMenu] isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES)
			{
				BOOL	 propagate = YES;
				
				if( [[imageView curDCM] isRGB] != [[[vC imageView] curDCM] isRGB]) propagate = NO;
				
				if( [[vC modality] isEqualToString:[self modality]] == NO) propagate = NO;
				
				if( [[vC modality] isEqualToString:@"MR"] == YES && [[self modality] isEqualToString:@"MR"] == YES)
				{
					if(		[[[imageView curDCM] repetitiontime] isEqualToString: [[[vC imageView] curDCM] repetitiontime]] == NO || 
							[[[imageView curDCM] echotime] isEqualToString: [[[vC imageView] curDCM] echotime]] == NO)
							{
								propagate = NO;
							}
				}
				
				if( propagate)
				{
					[imageView getWLWW:&iwl :&iww];
					[[vC imageView] setWLWW:iwl :iww];
				}
			}
			
			float fValue;
			
			if(  curvedController == 0L && [vC curvedController] == 0L)
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
			
			
			float vectorsA[9], vectorsB[9];
			
			[[pixList[0] objectAtIndex:0] orientation: vectorsA];
			[[[vC pixList] objectAtIndex:0] orientation: vectorsB];
			
//			NSLog(@"VecA: %f %f %f", vectorsA[ 0], vectorsA[ 1], vectorsA[ 2]);
//			NSLog(@"VecA: %f %f %f", vectorsA[ 3], vectorsA[ 4], vectorsA[ 5]);
//			NSLog(@"VecA: %f %f %f", vectorsA[ 6], vectorsA[ 7], vectorsA[ 8]);
//			
//			NSLog(@"VecB: %f %f %f", vectorsB[ 0], vectorsB[ 1], vectorsB[ 2]);
//			NSLog(@"VecB: %f %f %f", vectorsB[ 3], vectorsB[ 4], vectorsB[ 5]);
//			NSLog(@"VecB: %f %f %f", vectorsB[ 6], vectorsB[ 7], vectorsB[ 8]);
			
			if( ( vectorsA[ 6]) == (vectorsB[ 6]) && (vectorsA[ 7]) == (vectorsB[ 7]) && (vectorsA[ 8]) == (vectorsB[ 8]) && curvedController == 0L)
			{
				NSPoint pan;
				
				pan = [imageView origin];
				[[vC imageView] setOrigin: NSMakePoint( pan.x, pan.y)];
				
				fValue = [imageView rotation];
				[[vC imageView] setRotation: fValue];
			}
		}
		
		if( self == [vC blendingController])
		{
			[[vC imageView] loadTextures];
			[[vC imageView] setNeedsDisplay:YES];
		}
	}
	
	[viewersList release];
	
	// *** 3D MPR Viewers ***
	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"MPR"])
		{
			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		MPRController	*vC = [viewersList objectAtIndex: i];
		
		if( self == [vC blendingController])
		{
			[vC updateBlendingImage];
		}
	}
	[viewersList release];
	
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
	
	// *** 2D MPR Viewers ***
	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"MPR2D"])
		{
			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		MPR2DController	*vC = [viewersList objectAtIndex: i];
		
		if( self == [vC blendingController])
		{
			[vC updateBlendingImage];
		}
	}
	[viewersList release];
	
	// *** VR Viewers ***
	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"VR"] == YES || [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"VRPanel"] == YES)
		{
			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		VRController	*vC = [viewersList objectAtIndex: i];
		
		if( self == [vC blendingController])
		{
			[vC updateBlendingImage];
		}
	}
	
	[viewersList release];

}
#pragma mark Registration

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

- (void) computeRegistrationWithMovingViewer:(ViewerController*) movingViewer
{	
//	NSLog(@" ***** test 1 : test Horn Registration API ***** ");
//	[HornRegistration test]; //test if the connection to the Horn Registration API is OK
//	NSLog(@" ***** test 2 : test cocoa wrapper ***** ");
//	double *m1, *m2, *m3, *m4;
//	m1 = (double*) malloc(3*sizeof(double)); m2 = (double*) malloc(3*sizeof(double)); m3 = (double*) malloc(3*sizeof(double)); m4 = (double*) malloc(3*sizeof(double));
//	m1[0] = 0.0; m1[1] = 0.0; m1[2] = 0.0;
//	m2[0] = 10.0; m2[1] = 0.0; m2[2] = 0.0;
//	m3[0] = 10.0; m3[1] = 10.0; m3[2] = 0.0;
//	m4[0] = 0.0; m4[1] = 10.0; m4[2] = 0.0;
//	double *s1, *s2, *s3, *s4;
//	s1 = (double*) malloc(3*sizeof(double)); s2 = (double*) malloc(3*sizeof(double)); s3 = (double*) malloc(3*sizeof(double)); s4 = (double*) malloc(3*sizeof(double));
//	s1[0] = 5.0; s1[1] = 0.0; s1[2] = 0.0;
//	s2[0] = 5.0; s2[1] = 10.0; s2[2] = 0.0;
//	s3[0] = 5.0; s3[1] = 10.0; s3[2] = 11.0;
//	s4[0] = 5.0; s4[1] = 0.0; s4[2] = 10.0;
//	
//	HornRegistration *hr = [[HornRegistration alloc] init];
//	
//	[hr addModelPoint: m1]; [hr addModelPoint: m2]; [hr addModelPoint: m3]; [hr addModelPoint: m4];
//	[hr addSensorPoint: s1]; [hr addSensorPoint: s2]; [hr addSensorPoint: s3]; [hr addSensorPoint: s4];
//
//	[hr compute];
//	[hr release];
//
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
		
		int i,j,k; // 'for' indexes
		for (i=0; i<[modelPointROIs count] && pointsNamesMatch2by2 && !triplets; i++)
		{
			ROI *curModelPoint2D = [modelPointROIs objectAtIndex:i];
			modelName = [curModelPoint2D name];
			foundAMatchingName = NO;
			
			for (j=0; j<[sensorPointROIs count] && !foundAMatchingName; j++)
			{
				ROI *curSensorPoint2D = [sensorPointROIs objectAtIndex:j];
				sensorName = [curSensorPoint2D name];
			
				for (k=0; k<[previousNames count]; k++)
				{
					triplets = triplets || [modelName isEqualToString:[previousNames objectAtIndex:k]]
										|| [sensorName isEqualToString:[previousNames objectAtIndex:k]];
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
												toDICOMCoords:	modelLocation];
						
						[[curSensorPoint2D pix]	convertPixX:	[[[curSensorPoint2D points] objectAtIndex:0] x]
												pixY:			[[[curSensorPoint2D points] objectAtIndex:0] y]
												toDICOMCoords:	sensorLocation];
						
						// Convert the point in 3D orientation of the model
						
//						float modelLocationConverted[ 3];
//						
//						modelLocationConverted[ 0] = modelLocation[ 0] * vectorModel[ 0] + modelLocation[ 1] * vectorModel[ 1] + modelLocation[ 2] * vectorModel[ 2];
//						modelLocationConverted[ 1] = modelLocation[ 0] * vectorModel[ 3] + modelLocation[ 1] * vectorModel[ 4] + modelLocation[ 2] * vectorModel[ 5];
//						modelLocationConverted[ 2] = modelLocation[ 0] * vectorModel[ 6] + modelLocation[ 1] * vectorModel[ 7] + modelLocation[ 2] * vectorModel[ 8];

						float sensorLocationConverted[ 3];
						
//						sensorLocationConverted[ 0] = sensorLocation[ 0];
//						sensorLocationConverted[ 1] = sensorLocation[ 1];
//						sensorLocationConverted[ 2] = sensorLocation[ 2];
						
						sensorLocationConverted[ 0] = sensorLocation[ 0] * vectorSensor[ 0] + sensorLocation[ 1] * vectorSensor[ 1] + sensorLocation[ 2] * vectorSensor[ 2];
						sensorLocationConverted[ 1] = sensorLocation[ 0] * vectorSensor[ 3] + sensorLocation[ 1] * vectorSensor[ 4] + sensorLocation[ 2] * vectorSensor[ 5];
						sensorLocationConverted[ 2] = sensorLocation[ 0] * vectorSensor[ 6] + sensorLocation[ 1] * vectorSensor[ 7] + sensorLocation[ 2] * vectorSensor[ 8];
						
						// add the points to the registration method
						[hr addModelPointX: modelLocation[0] Y: modelLocation[1] Z: modelLocation[2]];
						[hr addSensorPointX: sensorLocationConverted[0] Y: sensorLocationConverted[1] Z: sensorLocationConverted[2]];
					}
				}
			}
		}
		
		if(pointsNamesMatch2by2 && !triplets)
		{
			// compute the registration
			[hr compute];
			
			ITKTransform * transform = [[ITKTransform alloc] initWithViewer:movingViewer];
			
			double	*rotation, rotationConverted[ 9];
			double	*translation, translationConverted[ 3];
			
			rotation = [hr rotation];
			translation = [hr translation];
			
			for( i = 0; i < 9 ; i++) rotationConverted[ i] = rotation[ i];
			for( i = 0; i < 3 ; i++) translationConverted[ i] = translation[ i];
			
//			rotationConverted[ 0] = 1;
//			rotationConverted[ 1] = 0;
//			rotationConverted[ 2] = 0;
//			
//			rotationConverted[ 3] = 0;
//			rotationConverted[ 4] = 1;
//			rotationConverted[ 5] = 0;
//
//			rotationConverted[6] = rotationConverted[1]*rotationConverted[5] - rotationConverted[2]*rotationConverted[4];
//			rotationConverted[7] = rotationConverted[2]*rotationConverted[3] - rotationConverted[0]*rotationConverted[5];
//			rotationConverted[8] = rotationConverted[0]*rotationConverted[4] - rotationConverted[1]*rotationConverted[3];
			
			[transform computeAffineTransformWithRotation: rotationConverted translation: translationConverted resampleOnViewer: self];
			[transform release];
		}
		[hr release];
	}
	else
	{
		if(!sameNumberOfPoints)
		{
			// warn user to set the same number of points on both viewers
			[errorString appendString:NSLocalizedString(@"Needs same number of points on both viewers.",0L)];
		}
		
		if(!enoughPoints)
		{
			// warn user to set at least 3 points on both viewers
			if([errorString length]!=0) [errorString appendString:@"\n"];
			[errorString appendString:NSLocalizedString(@"Needs at least 3 points on both viewers.",0L)];
		}
	}
	
	if(!pointsNamesMatch2by2)
	{
		// warn user
		if([errorString length]!=0) [errorString appendString:@"\n"];
		[errorString appendString:NSLocalizedString(@"Points names must match 2 by 2.",0L)];
	}
	
	if(triplets)
	{
		// warn user
		if([errorString length]!=0) [errorString appendString:@"\n"];
		[errorString appendString:NSLocalizedString(@"Max. 2 points with the same name.",0L)];
	}

	if([errorString length]!=0)
	{			
		NSRunCriticalAlertPanel(NSLocalizedString(@"Point-Based Registration Error", nil),
								errorString,
								NSLocalizedString(@"OK", nil), nil, nil);
	}
	
	[previousNames release];
}

#pragma mark segmentation

-(IBAction) startMSRGWithAutomaticBounding:(id) sender
{
	NSLog(@"startMSRGWithAutomaticBounding !");
}
-(IBAction) startMSRG:(id) sender
{
	NSLog(@"Start MSRG ....");
	int i,j,k,l=0;
	// I - RŽcupŽration des AUTRES ViewerController, nombre de critres
	
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList;
	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
		{
			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		ViewerController	*vC = [viewersList objectAtIndex: i];
	}
	/*
	 DCMPix	*curPix = [[self pixList] objectAtIndex: [[self imageView] curImage]];
	 long height=[curPix pheight];
	 long width=[curPix pwidth];
	 long depth=[[self pixList] count];
	 int* aBuffer=(int*)malloc(width*height*depth*sizeof(int));
	 if (aBuffer)
	 {
		 // clear texture
		 for(l=0;l<width*height*depth;l++)
			 aBuffer[l]=0;
		 // region 1
		 
		 for(k=0;k<depth;k++)
			 for(j=50;j<70;j++)
				 for(i=60;i<70;i++)
					 aBuffer[i+j*width+k*width*height]=1;
		 // region 2
		 
		 for(k=0;k<5;k++)
			 for(j=0;j<10;j++)
				 for(i=0;i<10;i++)
					 aBuffer[i+j*width+k*width*height]=2;
		 
		 [self addRoiFromFullStackBuffer:aBuffer];
		 free(aBuffer);
	 }
	 */
	 MSRGWindowController *msrgController = [[MSRGWindowController alloc] initWithMarkerViewer:self andViewersList:viewersList];
	 if( msrgController)
		{
			[msrgController showWindow:self];
			[[msrgController window] makeKeyAndOrderFront:self];
		}
/*
	MSRGSegmentation *msrgSeg=[[MSRGSegmentation alloc] initWithViewerList:viewersList currentViewer:self];
	[msrgSeg startMSRGSegmentation];
	*/
	[viewersList release];
	
}


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


-(void) addMovieSerie:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
	long	i;
	
	volumeData[ maxMovieIndex] = v;
	[volumeData[ maxMovieIndex] retain];
	
    [f retain];
    pixList[ maxMovieIndex] = f;
	
    [d retain];
    fileList[ maxMovieIndex] = d;
	
//	NSLog( [d valueForKeyPath:@"series.id"]);
	
	// Prepare pixList for image thick slab
	for( i = 0; i < [pixList[maxMovieIndex] count]; i++)
	{
		[[pixList[maxMovieIndex] objectAtIndex: i] setArrayPix: pixList[maxMovieIndex] :i];
	}
	
	// create empty ROI List for this new serie
	roiList[maxMovieIndex] = [[NSMutableArray alloc] initWithCapacity: 0];
	for( i = 0; i < [pixList[maxMovieIndex] count]; i++)
	{
		[roiList[maxMovieIndex] addObject:[NSMutableArray arrayWithCapacity:0]];
	}
	[self loadROI: maxMovieIndex];
	
	maxMovieIndex++;
	
	[moviePosSlider setMaxValue:maxMovieIndex-1];
	[moviePosSlider setNumberOfTickMarks:maxMovieIndex];
	
	[movieRateSlider setEnabled: YES];
	[moviePosSlider setEnabled: YES];
	[moviePlayStop setEnabled: YES];
}

-(void) deleteSeries:(id) sender
{
	[browserWindow delItemMatrix: [fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]]];
}


- (float) frameRate
{
    return [speedSlider floatValue];
}


- (void) speedSliderAction:(id) sender
{
	[speedText setStringValue:[NSString stringWithFormat:@"%0.1f im/s", (float) [self frameRate]*direction]];
}

- (void) movieRateSliderAction:(id) sender
{
	[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
}

-(NSSlider*) moviePosSlider {return moviePosSlider;}

- (void) setMovieIndex: (short) i
{
	curMovieIndex = i;
	if( curMovieIndex < 0) curMovieIndex = maxMovieIndex-1;
	if( curMovieIndex >= maxMovieIndex) curMovieIndex = 0;
	
	[moviePosSlider setIntValue:curMovieIndex];
	
	[imageView setDCM:pixList[curMovieIndex] :fileList[curMovieIndex] :roiList[curMovieIndex] :0 :'i' :NO];
	[imageView setIndex:[imageView curImage]];
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
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
	if( [self isEverythingLoaded] == NO) return;
	
    if( thisTime - lastMovieTime > 1.0 / [movieRateSlider floatValue])
    {
        val = curMovieIndex;
        val ++;
        
		if( val < 0) val = 0;
		if( val >= maxMovieIndex) val = 0;
		
		curMovieIndex = val;
		
		[self setMovieIndex: val];
		[self propagateSettings];
		
        lastMovieTime = thisTime;
    }
}

- (void) setImageIndex:(long) i
{	
	[imageView setIndex: i];

	[self adjustSlider];
	
	[imageView displayIfNeeded];
}

- (void) performAnimation:(id) sender
{
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
	if( [self isEverythingLoaded] == NO) return;
	
	if( [pixList[ curMovieIndex] count] <= 1)
	{
		[self PlayStop:[self findPlayStopButton]];
		return;
	}

    if( thisTime - lastTimeFrame > 1.0)
    {
		[speedText setStringValue:[NSString stringWithFormat:@"%0.1f im/s", (float) speedometer * direction / (thisTime - lastTimeFrame) ]];
        
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
			if( val < 0) val = [pixList[ curMovieIndex] count]-1;
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
				val = [pixList[ curMovieIndex] count]-1;
				direction = -direction;
				val += direction;
				if( val >= [pixList[ curMovieIndex] count]) val = [pixList[ curMovieIndex] count]-1;
			}
		}
		
        [imageView setIndex:val];
		
		[self adjustSlider];
        
		[imageView sendSyncMessage:1];
		
        lastTime = thisTime;
		
//		if( TICKPLAY)
//		{
//			if( [[self modality] isEqualToString:@"XA"] == YES)
//			{
//				[tickSound stop];
//				[tickSound play];
//			}
//		}
		
		[imageView displayIfNeeded];
		speedometer++;
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
        
        [sender setLabel: NSLocalizedString(@"Browse", nil)];
		[sender setPaletteLabel: NSLocalizedString(@"Browse", nil)];
        [sender setToolTip: NSLocalizedString(@"Browse this series", nil)];
        
		[speedText setStringValue:[NSString stringWithFormat:@"%0.1f im/s", (float) [self frameRate]*direction]];
    }
    else
    {
		[[NSNotificationCenter defaultCenter] postNotificationName: @"notificationStopPlaying" object:0L userInfo: 0L];
		
        timer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(performAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
    
        lastTime = [NSDate timeIntervalSinceReferenceDate];
        lastTimeFrame = [NSDate timeIntervalSinceReferenceDate];
        
        [sender setLabel: NSLocalizedString(@"Stop", nil)];
		[sender setPaletteLabel: NSLocalizedString(@"Stop", nil)];
        [sender setToolTip: NSLocalizedString(@"Stop", nil)];
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


#define DATABASEPATH @"/DATABASE/"


-(NSArray*) produceFilesFromMovie: (Movie) mov
{
	TimeValue			aTime = 0;
	OSType				mediatype = 'eyes';
	long				curFrame, i;
	Rect				tempRect;
	GWorldPtr			ftheGWorld = 0L;
	PixMapHandle		pixMapHandle;
	Ptr					pixBaseAddr;
	NSMutableArray		*files = [NSMutableArray arrayWithCapacity:0];
	NSBitmapImageRep	*rep;
	NSString			*curFile;
	
	GetMovieBox (mov, &tempRect);
	OffsetRect (&tempRect, -tempRect.left, -tempRect.top);
	
	NewGWorld (   &ftheGWorld,
				 32,			// 32 Bits color !
				 &tempRect,
				 0,
				 NULL,
				 (GWorldFlags) keepLocal);
	
	SetMovieGWorld (mov, ftheGWorld, 0L);
	SetMovieActive (mov, TRUE);
	SetMovieBox (mov, &tempRect);
	
	
	curFrame = 0;
	while (aTime != -1)
	{
		SetMovieTimeValue (mov, aTime);
		UpdateMovie (mov);
		MoviesTask (mov, 0);
		
		// We have the image...
			
		pixMapHandle = GetGWorldPixMap(ftheGWorld);
		LockPixels (pixMapHandle);
		pixBaseAddr = GetPixBaseAddr(pixMapHandle);
		
		rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes: nil
						   pixelsWide: tempRect.right
						   pixelsHigh: tempRect.bottom
						bitsPerSample: 8
					  samplesPerPixel: 3
							 hasAlpha: NO
							 isPlanar: NO
					   colorSpaceName: NSCalibratedRGBColorSpace
						  bytesPerRow: GetPixRowBytes(pixMapHandle)
						 bitsPerPixel: 32] autorelease];
						 
		BlockMoveData( pixBaseAddr, [rep bitmapData], GetPixRowBytes(pixMapHandle)*tempRect.bottom);
		
		i = GetPixRowBytes(pixMapHandle) * tempRect.bottom /4;
		
		unsigned long *argb = (unsigned long*) [rep bitmapData];
		while( i-- > 0)
		{
			*argb = (*argb << 8) + 0xFF;
			argb++;
		}
		
		UnlockPixels (pixMapHandle);
		
		// NEXT FRAME
		
		GetMovieNextInterestingTime (   mov,
									   nextTimeMediaSample,
									   1,
									   &mediatype,
									   aTime,
									   1,
									   &aTime,
									   0L);
									   
		
		
		curFile = [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/OsiriX%4d.tif", curFrame];
		
		
		 NSImage *image = [[NSImage alloc] init];
		 
		[image addRepresentation:rep];
		
		[[image TIFFRepresentation] writeToFile:curFile atomically:YES];
		
		[files addObject: curFile];
		
		[image release];
		
		curFrame++;
	}
	
	return files;
}

-(void) exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval
{
    NSRect          imageSize;
    Rect            trackFrame;
    NSSavePanel     *panel = [NSSavePanel savePanel];
    Movie           theMovie = nil;
	long			result, i;
	NSString		*destFilename;
	
	if( EXPORT2IPHOTO == NO)
	{
		[panel setCanSelectHiddenExtension:YES];
		[panel setRequiredFileType:@"mov"];
		
		result = [panel runModalForDirectory:0L file:[[fileList[ curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.name"]];
		
		destFilename = [panel filename];
	}
	else
	{
		result = NSFileHandlingPanelOKButton;
		
		destFilename =  [documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriXMovieTemp.mov"];
		
		[[NSFileManager defaultManager] removeFileAtPath: [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"] handler: 0L];
		[[NSFileManager defaultManager] createDirectoryAtPath: [documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"] attributes: 0L];
	}
	
	if( result == NSFileHandlingPanelOKButton)
	{
		gSelf = self;
		
		// resize and update all images:
		//for( i =0; i < [pixList count]; i++) [imageView setIndex:i];
				
		imageSize = [imageView bounds];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"])
		{
			trackFrame.top = 0;
			trackFrame.left = 0;
			trackFrame.bottom = [[imageView curDCM] pheight];
			trackFrame.right = [[imageView curDCM] pwidth];
		}
		else
		{
			trackFrame.top = 0;
			trackFrame.left = 0;
			trackFrame.bottom = imageSize.size.height;
			trackFrame.right = imageSize.size.width;
		}
		
		
		theMovie = CreateMovie( &trackFrame, destFilename, dimension, from, to, interval);
		
		//theMovie = [QTMovie movie];
		
		
		
		if( theMovie)
		{
			NSWorkspace *ws = [NSWorkspace sharedWorkspace];
			
			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"] && EXPORT2IPHOTO == NO)
				[ws openFile: [panel filename]];
		
					
			DisposeMovie( theMovie);
			theMovie = 0L;
			
			if( EXPORT2IPHOTO)
			{
				iPhoto *ifoto = [[iPhoto alloc] init];
				[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"]]];
				[ifoto release];
				
				[[NSFileManager defaultManager] removeFileAtPath: destFilename handler: 0L];
			}
		}
	}
	
	EXPORT2IPHOTO = NO;
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
		
		if( from > to)
		{
			long temp = to;
		
			to = from;
			from = temp;
		}
				
		if( [[quicktimeMode selectedCell] tag] == 3)	// key images
		{
			to = [pixList[ curMovieIndex] count];
			from = 0;
			interval = 1;
		}
		
		[self exportQuicktimeIn: [[quicktimeMode selectedCell] tag] :from :to :interval];
	}
}

- (IBAction) exportQuicktimeSlider:(id) sender
{
	[quicktimeFromText takeIntValueFrom: quicktimeFrom];
	[quicktimeToText takeIntValueFrom: quicktimeTo];
	
	if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
	else [imageView setIndex:  [sender intValue]-1];
	
	[imageView sendSyncMessage:1];
}

- (void) exportQuicktime:(id) sender
{
	if( [sender tag] == 1) EXPORT2IPHOTO = YES;
	else EXPORT2IPHOTO = NO;
	
	if( [sliderFusion isEnabled])
		[quicktimeInterval setIntValue: [sliderFusion intValue]];
	
	[quicktimeFrom setMaxValue: [pixList[ curMovieIndex] count]];
	[quicktimeTo setMaxValue: [pixList[ curMovieIndex] count]];

	[quicktimeFrom setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
	[quicktimeTo setNumberOfTickMarks: [pixList[ curMovieIndex] count]];

	[quicktimeFrom setIntValue: 1];
	[quicktimeTo setIntValue: [pixList[ curMovieIndex] count]];
	
	[quicktimeFrom performClick: self];	// Will update the text field
	[quicktimeTo performClick: self];	// Will update the text field
	[quicktimeInterval performClick: self];	// Will update the text field
	
	[self setCurrentdcmExport: quicktimeMode];
	
	if( blendingController) [[quicktimeMode cellWithTag: 0] setEnabled:YES];
	else [[quicktimeMode cellWithTag: 0] setEnabled:NO];
		
	if( maxMovieIndex > 1) [[quicktimeMode cellWithTag: 2] setEnabled:YES];
	else [[quicktimeMode cellWithTag: 2] setEnabled:NO];
	
	if( [[quicktimeMode selectedCell] isEnabled] == NO) [quicktimeMode selectCellWithTag: 1];
	
	[NSApp beginSheet: quicktimeWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (void) exportDICOMFileInt :(BOOL) screenCapture
{
	DCMPix			*curPix = [imageView curDCM];

	long	annotCopy		= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"],
			clutBarsCopy	= [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	long	width, height, spp, bpp, err;
	float	cwl, cww;
	float	o[ 9];
	
	[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
	[[NSUserDefaults standardUserDefaults] setInteger: barHide forKey: @"CLUTBARS"];
	
	unsigned char *data = [imageView getRawPixels:&width :&height :&spp :&bpp :screenCapture :NO];
	
	if( data)
	{
		if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
		
		[exportDCM setSourceFile: [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKey:@"completePath"]];
		[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
		
		[imageView getWLWW:&cwl :&cww];
		[exportDCM setDefaultWWWL: cww :cwl];
		
		if( screenCapture)
		{
			[exportDCM setPixelSpacing: [curPix pixelSpacingX] / [imageView scaleValue] :[curPix pixelSpacingX] / [imageView scaleValue]];
		}
		else
		{
			[exportDCM setPixelSpacing: [curPix pixelSpacingX]:[curPix pixelSpacingY]];
		}
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



-(id) findPlayStopButton
{
	unsigned long i, x;
	
	NSArray *items = [toolbar items];
	
	for( i = 0; i < [items count]; i++)
	{
		if( [[[items objectAtIndex:i] itemIdentifier] isEqualToString:PlayToolbarItemIdentifier] == YES)
		{
			return [items objectAtIndex:i];
		}
	}
	return nil;
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
			[self exportDICOMFileInt:[[dcmFormat selectedCell] tag]];
		}
		else
		{
			long from, to, interval;
			
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
			
			curImage = [imageView curImage];
			
			if (exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
			[exportDCM setSeriesNumber:5300 + [[NSCalendarDate date] minuteOfHour] ];	//Try to create a unique series number... Do you have a better idea??
			[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
			
			for (i = from ; i < to; i += interval)
			{
				BOOL	export = YES;
				
				if( [[dcmSelection selectedCell] tag] == 2)	// Only key images
				{
					NSManagedObject	*image = [fileList[ curMovieIndex] objectAtIndex: i];
					export = [[image valueForKey:@"isKeyImage"] boolValue];
				}
				
				if( export)
				{
					if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] -1 -i];
					else [imageView setIndex:i];
					
					[imageView sendSyncMessage:1];
					[imageView display];
					
					{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						[self exportDICOMFileInt:[[dcmFormat selectedCell] tag] ];
						[pool release];
					}
				}
				
				[splash incrementBy: 1];
			}
			
			[imageView setIndex: curImage];
			[imageView display];
			
			[splash close];
			[splash release];
		}
	}
}

-(void) exportRAW:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
    short           i;

    [panel setCanSelectHiddenExtension:NO];
    
	if( [panel runModalForDirectory:0L file: [[fileList[ curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.name"]] == NSFileHandlingPanelOKButton)
    {
        [panel filename];
        
        for( i = 0; i < [fileList[ curMovieIndex] count]; i++)
        {
            DCMPix  *pix = [pixList[ curMovieIndex] objectAtIndex:i];
            
			#ifdef USEVIMAGE
			vImage_Buffer dst16, srcf;
			
			dst16.height = srcf.height = [pix pheight];
			dst16.width = srcf.width = [pix pwidth];
			dst16.rowBytes = [pix pwidth]*2;
			srcf.rowBytes = [pix pwidth]*sizeof(float);
			
			dst16.data = malloc([pix pwidth]*[pix pheight]*2L);
			srcf.data = [pix fImage];
			
			vImageConvert_FTo16S( &srcf, &dst16, 0, 1.0, 0);
			
			NSData *data = [NSData dataWithBytesNoCopy:dst16.data length:[pix pwidth]*[pix pheight]*2 freeWhenDone:NO];
			
            [data writeToFile:[NSString stringWithFormat:@"%@.%d",[panel filename],i] atomically:NO];
			
			free( dst16.data);
			#else
            NSData *data = [NSData dataWithBytesNoCopy:[pix oImage] length:[pix width]*[pix height]*2 freeWhenDone:NO];

            [data writeToFile:[NSString stringWithFormat:@"%@.%d",[panel filename],i] atomically:NO];
			#endif
        }
    }
}


- (IBAction) setCurrentdcmExport:(id) sender
{
	if( [[sender selectedCell] tag] == 1) [self checkView: dcmBox :YES];
	else [self checkView: dcmBox :NO];
	
	if( [[sender selectedCell] tag] == 1) [self checkView: quicktimeBox :YES];
	else [self checkView: quicktimeBox :NO];
}


- (IBAction) exportDICOMSlider:(id) sender
{
	[dcmFromText takeIntValueFrom: dcmFrom];
	[dcmToText takeIntValueFrom: dcmTo];
	
	if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
	else [imageView setIndex:  [sender intValue]-1];
	
	[imageView sendSyncMessage:1];
}

- (void) exportDICOMFile:(id) sender
{
	if( [sliderFusion isEnabled])
		[dcmInterval setIntValue: [sliderFusion intValue]];
	
	[dcmFrom setMaxValue: [pixList[ curMovieIndex] count]];
	[dcmTo setMaxValue: [pixList[ curMovieIndex] count]];
	
	[dcmFrom setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
	[dcmTo setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
	
	[dcmFrom setIntValue: 1];
	[dcmTo setIntValue: [pixList[ curMovieIndex] count]];
	
	[dcmFrom performClick: self];	// Will update the text field
	[dcmTo performClick: self];	// Will update the text field
	[dcmInterval performClick: self];	// Will update the text field
	
	[self setCurrentdcmExport: dcmSelection];
	
    [NSApp beginSheet: dcmExportWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction) export2PACS:(id) sender
{
	BOOL			all = NO;
	long			i,x;
	NSMutableArray  *files2Send;
	
	if( [pixList[ curMovieIndex] count] > 1)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"Send to PACS", nil), NSLocalizedString(@"Should I send only current image or all images of current series?", nil), NSLocalizedString(@"Current", nil), NSLocalizedString(@"All", nil), 0L) == NSAlertDefaultReturn) all = NO;
		else all = YES;
	}
	
	if( all)
	{
		files2Send = [NSMutableArray arrayWithCapacity:0];
		
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
		files2Send = [NSMutableArray arrayWithCapacity:0];
		
		[files2Send addObject: [fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]]];
	}
	
	[browserWindow selectServer: files2Send];
}


-(void) sendMail:(id) sender
{
	Mailer		*email;
	NSImage		*im = [imageView nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];

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


- (void) exportImage:(id) sender
{
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask) [self endExportImage: 0L];
	else [NSApp beginSheet: imageExportWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
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
	
	NSSavePanel     *panel = [NSSavePanel savePanel];
	BOOL			all = NO;
	long			i;
	NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
	
	[panel setCanSelectHiddenExtension:YES];
	
	if( [[imageFormat selectedCell] tag] == 0)
		[panel setRequiredFileType:@"jpg"];
	else
		[panel setRequiredFileType:@"tif"];
		
	if( [sender tag] != 0 || sender == 0L)
	{
		BOOL pathOK = YES;
		
		if( [[imageFormat selectedCell] tag] != 2)
		{
			if( [panel runModalForDirectory:0L file:[[fileList[ curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.name"]] != NSFileHandlingPanelOKButton)
				pathOK = NO;
		}
		
		if( pathOK == YES)
		{
			if( [[imageSelection selectedCell] tag] == 1 || [[imageSelection selectedCell] tag] == 2)
			{
				if( [[imageFormat selectedCell] tag] == 2 && [[imageSelection selectedCell] tag] == 1)
				{
					EXPORT2IPHOTO = YES;
					[self exportQuicktimeIn: 1 :0 :[pixList[ curMovieIndex] count]: 1];
					EXPORT2IPHOTO = NO;
				}
				else
				{
					for( i = 0; i < [pixList[ curMovieIndex] count]; i++)
					{
						BOOL export = YES;
						
						if( [[imageSelection selectedCell] tag] == 2)
						{
							NSManagedObject	*image = [fileList[ curMovieIndex] objectAtIndex: i];
							export = [[image valueForKey:@"isKeyImage"] boolValue];
						}
						
						if( export)
						{					
							[imageView setIndex:i];
							[imageView sendSyncMessage:1];
							[imageView display];
							
							NSImage *im = [imageView nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];
							
							NSArray *representations;
							NSData *bitmapData;

							representations = [im representations];
							
							if( [[imageFormat selectedCell] tag] == 2)
							{
								bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];

								[bitmapData writeToFile:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
								
								iPhoto	*ifoto = [[iPhoto alloc] init];
								[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
								[ifoto release];
							}
							else
							{
								if( [[imageFormat selectedCell] tag] == 0)
								{
									bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
									[bitmapData writeToFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.jpg", i+1]] atomically:YES];
								}
								else
									[[im TIFFRepresentation] writeToFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.tif", i+1]] atomically:NO];
							}
							
							[im release];
						}
					}
					
					if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%d.jpg", 1]]];
				}
			}
			else
			{
				NSImage *im = [imageView nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];
				
				NSArray *representations;
				NSData *bitmapData;
				
				representations = [im representations];
				
				if( [[imageFormat selectedCell] tag] == 2)
				{
					bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];

					[bitmapData writeToFile:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"] atomically:YES];
					
					iPhoto	*ifoto = [[iPhoto alloc] init];
					[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/OsiriX.jpg"]]];
					[ifoto release];
				}
				else
				{
					if( [[imageFormat selectedCell] tag] == 0)
					{
						bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
						[bitmapData writeToFile:[panel filename] atomically:YES];
					}
					else
						[[im TIFFRepresentation] writeToFile:[[[panel filename] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"tif"]] atomically:NO];
				}
				
				[im release];
				
				if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
			}
		}
	}
}

#define ICHAT_WIDTH 640
#define ICHAT_HEIGHT 480

-(IBAction) produceIChatData:(id) sender
{
	long			i, x, z, zz, inv, swidth, sheight, offsetX, offsetY;
	float			ratioX, ratioY;
	unsigned char   *rgbPtr;
	unsigned char   *finalPtr;
	FILE			*fp;
	long			line3, line4, spp, bpp;
	unsigned char   *src, *dst;
	long			scrapSize;
	ScrapRef		scrap;

	// Is there an image in clipboard?
	
	GetCurrentScrap( &scrap); 
	if( GetScrapFlavorSize(scrap, 'OXRA', &scrapSize) == noErr) return;
	
	rgbPtr = [imageView getRawPixels: &swidth :&sheight :&spp :&bpp :YES :NO];
	finalPtr = malloc( 3L*ICHAT_WIDTH*ICHAT_HEIGHT);
	
	bzero( finalPtr, 3L*ICHAT_WIDTH*ICHAT_HEIGHT);
	
	ratioX = (float) swidth / (float) ICHAT_WIDTH;
	ratioY = (float) sheight / (float) ICHAT_HEIGHT;

	if( ratioX > ratioY)
	{
		offsetX = 0;
		offsetY =(ICHAT_HEIGHT - sheight/ratioX)/2;
		offsetY += 2;
		
	}
	else
	{
		offsetY = 0;
		offsetX =(ICHAT_WIDTH - swidth/ratioY)/2;
		offsetX += 2;
	}
	
	if( ratioX > ratioY)
	{
		for( i = offsetY; i < ICHAT_HEIGHT-offsetY; i++)
		{
			line3 = (i)* ICHAT_WIDTH * 3L;
			
			line4 = (((i-offsetY)* swidth) / ICHAT_WIDTH);
			line4 *= swidth*3L;
			
			for( z = 0 ; z < ICHAT_WIDTH; z++)
			{
				dst = &finalPtr[ line3 +z*3];
				src = &rgbPtr[ line4 + (((z)*swidth) / ICHAT_WIDTH)*3];
				
				*dst++		= *src++;
				*dst++		= *src++;
				*dst		= *src;
			}
		}
	}
	else
	{
		for( i = 0; i < ICHAT_HEIGHT ; i++)
		{
			line3 = i * ICHAT_WIDTH * 3L;
			line4 = ( (i* sheight) / ICHAT_HEIGHT) * swidth * 3L;
			
			for( z = offsetX ; z < ICHAT_WIDTH-offsetX; z++)
			{
				dst = &finalPtr[ line3 +(z) *3];
				src = &rgbPtr[ line4 + (((z-offsetX)*sheight) / ICHAT_HEIGHT)*3];
				
				*dst++		= *src++;
				*dst++		= *src++;
				*dst		= *src;
			}
		}
	}
	
	//Draw Mouse
	
	NSPoint cursorLoc;// = [imageView convertPoint:[[self window] convertScreenToBase: [NSEvent mouseLocation]] fromView:0L];
	
//	cursorLoc = [[[self window] contentView] convertPoint:[NSEvent mouseLocation] toView:self];
	
//	cursorLoc = [imageView convertPoint:[NSEvent mouseLocation] fromView:imageView];
	cursorLoc = [[[self window] contentView] convertPoint:[[self window] mouseLocationOutsideOfEventStream] toView:imageView];
	
//	NSLog( @"x: %2.2f y: %2.2f", cursorLoc.x, cursorLoc.y);
	
	long	xx = cursorLoc.x;
	long	yy = cursorLoc.y;
	
	if( ratioX > ratioY)
	{
		xx = (xx * ICHAT_WIDTH) / swidth;
	//	xx = ICHAT_WIDTH - xx;
		
		yy = (yy * ICHAT_WIDTH) / swidth;
		yy = ICHAT_HEIGHT - yy;
		yy -= offsetY;
	}
	else
	{
		xx = (xx * ICHAT_HEIGHT) / sheight;
	//	xx = ICHAT_WIDTH - xx;
		xx += offsetX;
		
		yy = (yy * ICHAT_HEIGHT) / sheight;
		yy = ICHAT_HEIGHT - yy;
	}
	
//	NSLog( @"offset: %d", offsetX);
	
	for( x = -3; x< 3; x++)
	{
		for( z = -3; z < 3; z++)
		{
			if( x + xx >= 0 && x + xx < ICHAT_WIDTH)
			{
				if( z + yy >= 0 && z + yy < ICHAT_HEIGHT)
				{
					dst = &finalPtr[ (z + yy)*ICHAT_WIDTH*3L + (x + xx)*3L];
					*dst++ = 0x00;
					*dst++ = 0xFF;
					*dst = 0;
				}
			}
		}
	}
	
//	NSPasteboard	*pb = [NSPasteboard generalPasteboard];
//	[pb declareTypes:[NSArray arrayWithObject:@"OXRA"] owner:self];
//	[pb setData: [NSData dataWithBytesNoCopy: finalPtr length:3L*ICHAT_WIDTH*ICHAT_HEIGHT freeWhenDone:YES] forType:@"OXRA"];

	{
//		ScrapFlavorInfo info[100];
		
		ClearCurrentScrap ();
		GetCurrentScrap( &scrap); 
		
		PutScrapFlavor ( scrap, 'OXRA',kScrapFlavorMaskNone ,3L*ICHAT_WIDTH*ICHAT_HEIGHT,finalPtr ); 

	}
//	fp = fopen("/tmp/osirix24bitsTemp", "wb");
//	fwrite( finalPtr, 3L*ICHAT_WIDTH*ICHAT_HEIGHT, 1, fp);
//	fclose( fp);
//	rename("/tmp/osirix24bitsTemp", "/tmp/osirix24bits");
	
	free( rgbPtr);
	free( finalPtr);
//	
//	
//	{
//		long scrapSize;
//		ScrapRef scrap;
//		ScrapFlavorInfo info[100];
//		
//		GetCurrentScrap( &scrap); 
//		
//		GetScrapFlavorCount ( scrap, &scrapSize);
//		
//		GetScrapFlavorInfoList ( scrap,     &scrapSize,     info ); 
//		
//		if( GetScrapFlavorSize(scrap, 'OXRA', &scrapSize) == noErr)
//		{
//			
//		}
//	}
//
//	NSImage *sourceImage = [imageView nsimage:NO];
//	
//	[sourceImage setScalesWhenResized:YES];
//	
//	// Report an error if the source isn't a valid image
//	if (![sourceImage isValid])
//	{
//			NSLog(@"Invalid Image");
//	} else
//	{
//			NSImage *smallImage = [[[NSImage alloc] initWithSize:NSMakeSize(ICHAT_WIDTH, ICHAT_HEIGHT)] autorelease];
//			
//			[smallImage lockFocus];
//			
//			[[NSColor blackColor] set];
//			[NSBezierPath fillRect: NSMakeRect(0, 0, ICHAT_WIDTH, ICHAT_HEIGHT)];
//			
//			NSSize size = [sourceImage size];
//			
//			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
//			
//			float ratioX, ratioY;
//			
//			ratioX = size.width / ICHAT_WIDTH;
//			ratioY = size.height / ICHAT_HEIGHT;
//			
//			if( ratioX > ratioY)
//			{
//				[sourceImage setSize:NSMakeSize(size.width/ratioX, size.height/ratioX)];
//				
//				[sourceImage compositeToPoint:NSMakePoint(0, (ICHAT_HEIGHT - size.height/ratioX)/2) operation:NSCompositeCopy];
//				
//			}
//			else
//			{
//				[sourceImage setSize:NSMakeSize(size.width/ratioY, size.height/ratioY)];
//				
//				[sourceImage compositeToPoint:NSMakePoint((ICHAT_WIDTH - size.width/ratioY)/2, 0) operation:NSCompositeCopy];
//			}
//			
//			[smallImage unlockFocus];
//			
//			NSBitmapImageRep *bm = [NSBitmapImageRep imageRepWithData: [smallImage TIFFRepresentation]];
//			
//			unsigned char *rgb = malloc( 3L*ICHAT_WIDTH*ICHAT_HEIGHT);
//			
//			if( bm != 0L && rgb != 0L)
//			{
//				long i, x, z, line3, line4, inv;
//				unsigned char *src = [bm bitmapData];
//				
//				NSLog(@"BPP:%d", [bm bitsPerPixel]);
//				
//				if( [bm bitsPerPixel] == 24)
//				{
//					for( i = 0; i < ICHAT_HEIGHT ; i++)
//					{
//						line3 = i * ICHAT_WIDTH * 3L;
//						line4 = i * ICHAT_WIDTH * 3L;
//						
//						for( z = 0 ; z < ICHAT_WIDTH; z++)
//						{
//							inv = (ICHAT_WIDTH-1-z);
//							
//							rgb[ line3 +z*3]		= src[ line4 + inv*3];
//							rgb[ line3 +z*3 +1]		= src[ line4 + inv*3 +1];
//							rgb[ line3 +z*3 +2]		= src[ line4 + inv*3 +2];
//						}
//					}
//				}
//				else if( [bm bitsPerPixel] == 32)
//				{
//					for( i = 0; i < ICHAT_HEIGHT ; i++)
//					{
//						line3 = i * ICHAT_WIDTH * 3L;
//						line4 = i * ICHAT_WIDTH * 4L;
//						
//						for( z = 0 ; z < ICHAT_WIDTH; z++)
//						{
//							inv = (ICHAT_WIDTH-1-z);
//							
//							rgb[ line3 +z*3]		= src[ line4 + inv*4];
//							rgb[ line3 +z*3 +1]		= src[ line4 + inv*4 +1];
//							rgb[ line3 +z*3 +2]		= src[ line4 + inv*4 +2];
//						}
//					}
//				}
//				
//				NSData *rawData = [NSData dataWithBytesNoCopy:rgb  length:3L*ICHAT_WIDTH*ICHAT_HEIGHT freeWhenDone:YES];
//				
//				[rawData writeToFile:@"/tmp/osirix24bits" atomically:YES];
//			}
//	//		free( rgb);
//			
//	//		[[smallImage TIFFRepresentation] writeToFile:@"/test.tiff" atomically:NO];
//	}
//
//	[sourceImage release];
}

- (void) iChatBroadcast:(id) sender
{
	if( timeriChat)
    {
        [timeriChat invalidate];
        [timeriChat release];
        timeriChat = nil;
        
        [sender setLabel: NSLocalizedString(@"BroadCast", 0L)];
		[sender setPaletteLabel: NSLocalizedString(@"BroadCast", 0L)];
        [sender setToolTip: NSLocalizedString(@"BroadCast", 0L)];
    }
    else
    {
		[[NSNotificationCenter defaultCenter] postNotificationName: @"notificationiChatBroadcast" object:0L userInfo: 0L];
		
        timeriChat = [[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(produceIChatData:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:timeriChat forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:timeriChat forMode:NSEventTrackingRunLoopMode];
		
        [sender setLabel: NSLocalizedString(@"Stop", nil)];
		[sender setPaletteLabel: NSLocalizedString(@"Stop", nil)];
        [sender setToolTip: NSLocalizedString(@"Stop", nil)];
    }
}

- (void) notificationiChatBroadcast:(NSNotification*)note
{
	if( timeriChat) [self iChatBroadcast:[self findiChatButton]];
}


-(id) findiChatButton
{
	unsigned long i, x;
	
//	for( x = 0; x < [[NSScreen screens] count]; x++)
	{
		NSArray *items = [toolbar items];
		
		for( i = 0; i < [items count]; i++)
		{
			if( [[[items objectAtIndex:i] itemIdentifier] isEqualToString:iChatBroadCastToolbarItemIdentifier] == YES)
			{
				return [items objectAtIndex:i];
			}
		}
	}
	
	return nil;
}

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

- (float) computeVolume:(ROI*) selectedRoi points:(NSMutableArray**) pts error:(NSString**) error
{
	long				i, x, y, globalCount, imageCount;
	float				volume = 0, prevArea, preLocation, interval;
	long				err = 0;
	
	if( pts) *pts = [NSMutableArray arrayWithCapacity:0];

	globalCount = 0;
	prevArea = 0;
	preLocation = 0;
	volume = 0;
	if( error) *error = 0L;
	
	for( x = 0; x < [pixList[curMovieIndex] count]; x++)
	{
		DCMPix	*curDCM = [pixList[curMovieIndex] objectAtIndex: x];
		imageCount = 0;
		
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: x] count]; i++)
		{
			ROI	*curROI = [[roiList[curMovieIndex] objectAtIndex: x] objectAtIndex: i];
			if( [[curROI name] isEqualToString: [selectedRoi name]])
			{
				globalCount++;
				imageCount++;
				
				DCMPix *curPix = [pixList[ curMovieIndex] objectAtIndex: x];
				float curArea = [curROI roiArea];
				
				if( curArea == 0)
				{
					if( error) *error = [NSString stringWithString: NSLocalizedString(@"One ROI has an area equal to ZERO!", nil)];
					return 0;
				}
				
				if( preLocation != 0)
					volume += (([curPix sliceLocation] - preLocation)/10.) * (curArea + prevArea)/2.;
				
				prevArea = curArea;
				preLocation = [curPix sliceLocation];
				
				if( pts)
				{
					NSMutableArray	*points = [curROI points];
					
					for( y = 0; y < [points count]; y++)
					{
						float location[ 3];
						
						[curDCM convertPixX: [[points objectAtIndex: y] x] pixY: [[points objectAtIndex: y] y] toDICOMCoords: location];
						
						NSArray	*pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], 0L];
						[*pts addObject: pt3D];
					}
				}
			}
		}
		
		if( imageCount > 1)
		{
			if( error) *error = [NSString stringWithFormat: NSLocalizedString(@"Only ONE ROI per image, please! (im: %d)", nil), x+1];
			return 0;
		}
	}
	
	if( globalCount == 1)
	{
		if( error) *error = [NSString stringWithFormat: NSLocalizedString(@"If found only ONE ROI : not enable to compute a volume!", nil), x+1];
		return 0;
	}
	
	if( volume < 0) volume = -volume;
	
	return volume;
}


-(void) updateVolumeData: (NSNotification*) note
{
	if( [note object] == pixList[ curMovieIndex])
	{
		float   iwl, iww;
		long x, y;
		
		[imageView getWLWW:&iwl :&iww];
		
		for( y = 0; y < maxMovieIndex; y++)
		{
			for( x = 0; x < [pixList[y] count]; x++)
			{
				[[pixList[y] objectAtIndex: x] changeWLWW:iwl :iww];	//recompute WLWW
			}
		}
		
		[imageView setWLWW:iwl :iww];
	}
}

- (void) setPixelList:(NSMutableArray*)f fileList:(NSMutableArray*)d volumeData:(NSData*) v
{
	long i;
	
	speedometer = 0;
	matrixPreviewBuilt = NO;
	
	ThreadLoadImageLock = [[NSLock alloc] init];
	roiLock = [[NSLock alloc] init];
	
	windowWillClose = NO;
	EXPORT2IPHOTO = NO;
	loadingPause = NO;
	loadingPercentage = 0;
	exportDCM = 0L;
	curvedController = 0L;
	thickSlab = 0L;
	ROINamesArray = 0L;
	ThreadLoadImage = NO;
	
	subOffset.y = subOffset.x = 0;
	mask = 1;
	
	curMovieIndex = 0;
	maxMovieIndex = 1;
	blendingController = 0L;
	
	curCLUTMenu = NSLocalizedString(@"No CLUT", nil);
	curConvMenu = NSLocalizedString(@"No Filter", nil);
	curWLWWMenu = NSLocalizedString(@"Default WL & WW", nil);

	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];

	volumeData[ 0] = v;
	[volumeData[ 0] retain];
	
	direction = 1;
	
    [f retain];
    pixList[ 0] = f;
    
	// Prepare pixList for image thick slab
	for( i = 0; i < [pixList[0] count]; i++)
	{
		[[pixList[0] objectAtIndex: i] setArrayPix: pixList[0] :i];
	}
	
    [d retain];
    fileList[ 0] = d;

	// Create empty ROI Lists
	roiList[0] = [[NSMutableArray alloc] initWithCapacity: 0];
	for( i = 0; i < [pixList[0] count]; i++)
	{
		[roiList[0] addObject:[NSMutableArray arrayWithCapacity:0]];
	}
	//
	[self loadROI: 0];
	
	
	[self setupToolbar];
	
    [[self window] performZoom:self];
	
	[stacksFusion setIntValue:2];
	[sliderFusion setIntValue:1];
	[sliderFusion setEnabled:NO];

	[imageView setDCM:pixList[0] :fileList[0] :roiList[0] :0 :'i' :YES];	//[pixList[0] count]/2
	[imageView setIndexWithReset: 0 :YES];	//[pixList[0] count]/2
	

	NSRect  rect;
	NSRect  visibleRect;
	DCMPix *curDCM = [pixList[0] objectAtIndex: 0];	//[pixList[0] count]/2

	rect.origin.x = 0;
	rect.origin.y = 0;
	rect.size.width = [curDCM pwidth] + 50;
	rect.size.height = [curDCM pheight] + 110;

	if( rect.size.width < 600) rect.size.width = 600;
	if( rect.size.height < 400) rect.size.height = 400;

	visibleRect = [[[self window] screen] visibleFrame];

	if( rect.size.width > visibleRect.size.width) rect.size.width = visibleRect.size.width;
	if( rect.size.height > visibleRect.size.height) rect.size.height = visibleRect.size.height;
	
	[[self window] center];
	
	timer = 0L;
	timeriChat = 0L;
	movieTimer = 0L;
	
	NSManagedObject	*curImage = [fileList[0] objectAtIndex:0];
	
	[self setWindowTitle: self];
	
    [slider setMaxValue:[pixList[0] count]-1];
	[slider setNumberOfTickMarks:[pixList[0] count]];
	[self adjustSlider];
	[movieRateSlider setEnabled: NO];
	[moviePosSlider setEnabled: NO];
	[moviePlayStop setEnabled:NO];
    
    
    if([fileList[0] count] == 1 && [[curImage valueForKey:@"numberOfFrames"] intValue] <=  1)
    {
        [speedSlider setEnabled:NO];
        [slider setEnabled:NO];
    }
	else
	{
		if( [curDCM cineRate])
		{
			[speedSlider setFloatValue:[curDCM cineRate]];
		}
	}
    
	[speedText setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%0.1f im/s", nil), (float) [self frameRate]*direction]];

//    [[fileList[0] objectAtIndex:0] setViewer: self forSerie:[[pixList[ 0] objectAtIndex:0] serieNo]];
    
    [[self window] setDelegate:self];
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:NSLocalizedString(@"Default WL & WW", nil)];
	[[[convPopup menu] itemAtIndex:0] setTitle:NSLocalizedString(@"No Filter", nil)];
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(UpdateWLWWMenu:)
               name: @"UpdateWLWWMenu"
             object: nil];
	
	[nc	addObserver: self
			selector: @selector(Display3DPoint:)
				name: @"Display3DPoint"
			object: nil];
			
	[nc addObserver: self
           selector: @selector(ViewFrameDidChange:)
               name: NSViewFrameDidChangeNotification
             object: nil];
			 
	[nc addObserver: self
           selector: @selector(revertSeriesNotification:)
               name: @"revertSeriesNotification"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(updateVolumeData:)
               name: @"updateVolumeData"
             object: nil];
			 
	[nc addObserver: self
		   selector: @selector(roiChange:)
			   name: @"roiChange"
			 object: nil];
			 
	[nc addObserver: self
			   selector: @selector(OpacityChanged:)
				   name: @"OpacityChanged"
				 object: nil];
	
	[nc addObserver: self
           selector: @selector(defaultToolModified:)
               name: @"defaultToolModified"
             object: nil];
			 
	[nc addObserver: self
           selector: @selector(defaultRightToolModified:)
               name: @"defaultRightToolModified"
             object: nil];
	
	[nc postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
    [nc addObserver: self
           selector: @selector(UpdateConvolutionMenu:)
               name: @"UpdateConvolutionMenu"
             object: nil];
	
	[nc addObserver: self
			   selector: @selector(CLUTChanged:)
				   name: @"CLUTChanged"
				 object: nil];
				 
	[nc postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];

    [nc addObserver: self
           selector: @selector(UpdateCLUTMenu:)
               name: @"UpdateCLUTMenu"
             object: nil];
	
	[nc postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];

	curOpacityMenu = @"Linear Table";
	[curOpacityMenu retain];
	
    [nc addObserver: self
           selector: @selector(UpdateOpacityMenu:)
               name: @"UpdateOpacityMenu"
             object: nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateOpacityMenu" object: curOpacityMenu userInfo: 0L];

    [nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: @"CloseViewerNotification"
             object: nil];
	
	[nc addObserver: self
			selector: @selector(recomputeROI:)
               name: @"recomputeROI"
             object: nil];
			 
	[nc addObserver: self
		selector: @selector(closeAllWindows:)
               name: @"Close All Viewers"
             object: nil];
	
	[nc addObserver: self
		selector: @selector(notificationStopPlaying:)
               name: @"notificationStopPlaying"
             object: nil];
			 
	[nc addObserver: self
		selector: @selector(notificationiChatBroadcast:)
               name: @"notificationiChatBroadcast"
             object: nil];
			 
	[nc addObserver: self
			selector: @selector(notificationSyncSeries:)
               name: @"notificationSyncSeries"
             object: nil];
	
	[nc	addObserver: self
		   selector: @selector(exportTextFieldDidChange:)
			   name: @"NSControlTextDidChangeNotification"
			 object: nil];
	
	[[self window] registerForDraggedTypes: [NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
	if( [[self modality] isEqualToString:@"PT"] == YES  && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
	{
		if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
			[self ApplyCLUTString: @"B/W Inverse"];
		else
			[self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
	}
	
	numberOf2DViewer++;
	
	//
	for( i = 0; i < [popupRoi numberOfItems]; i++)
	{
		if( [[popupRoi itemAtIndex: i] image] == 0L)
		{
			NSString	*filename = 0L;
			
			[[popupRoi itemAtIndex: i] setImage: [self imageForROI: [[popupRoi itemAtIndex: i] tag]]];
		}
	}
	
	for( i = 0; i < [ReconstructionRoi numberOfItems]; i++)
	{
		if( [[ReconstructionRoi itemAtIndex: i] image] == 0L)
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
				if( [VRPROController available] == NO)
				{
					[ReconstructionRoi removeItemAtIndex: i];
					i--;
				}
				else
					[[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"VolumeRendering"]];
				break;
				case 8: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"orthogonalReslice"]];	break;
				case 9: [[ReconstructionRoi itemAtIndex: i] setImage: [NSImage imageNamed: @"Endoscopy"]];	break;
			}
		}
	}
	
	if( numberOf2DViewer > 1 || [[NSUserDefaults standardUserDefaults] boolForKey: @"USEALWAYSTOOLBARPANEL"] == YES)
	{
		if( USETOOLBARPANEL == NO)
		{
			USETOOLBARPANEL = YES;
			
			NSArray				*winList = [NSApp windows];
			
			for( i = 0; i < [winList count]; i++)
			{
				if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
				{
					if( [[winList objectAtIndex:i] toolbar])
						[[winList objectAtIndex:i] toggleToolbarShown: self];
				}
			}
		}
	}
	
	[[self window] setInitialFirstResponder: imageView];
	
//	[[self window] makeKeyAndOrderFront: self];
//	i = [[NSApp orderedWindows] indexOfObject: [self window]];
//	if( i != NSNotFound)
//	{
//		i++;
//		for( ; i < [[NSApp orderedWindows] count]; i++)
//		{
//			if( [[[[NSApp orderedWindows] objectAtIndex: i] windowController] isKindOfClass:[ViewerController class]])
//			{
//				[[[[[NSApp orderedWindows] objectAtIndex: i] windowController] imageView]  sendSyncMessage:1];
//			}
//		}
//	}
//	else if( [[self window] isKeyWindow]) [imageView sendSyncMessage:1];
	NSNumber	*status = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.study.stateText"];
	
	if( status == 0L) [StatusPopup selectItemWithTitle: @"empty"];
	else [StatusPopup selectItemWithTag: [status intValue]];
	
	NSString	*com = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.study.comment"];
	
	if( com == 0L || [com isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"No Comments", nil)];
	else [CommentsField setTitle: com];

	// SplitView
	[[[splitView subviews] objectAtIndex: 0] setPostsFrameChangedNotifications:YES]; 
	[splitView restoreDefault:@"SPLITVIEWER"];
	
	[self buildMatrixPreview];
	
	[self matrixPreviewSelectCurrentSeries];
}

- (IBAction) Panel3D:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];
	
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		VRController *viewer = [appController FindViewer :@"VRPanel" :pixList[0]];
		
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
			
			[viewer load3DState];
			
			if( [[self modality] isEqualToString:@"PT"] == YES && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
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
			}
			else
			{
				float   iwl, iww;
				[imageView getWLWW:&iwl :&iww];
				[viewer setWLWW:iwl :iww];
			}
			
			
			[viewer showWindow:self];
			[[viewer window] makeKeyAndOrderFront:self];
			[[viewer window] display];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

-(IBAction) MPRViewer:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];

	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		MPRController *viewer = [appController FindViewer :@"MPR" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			viewer = [[MPRController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[0] :blendingController];
			
			for( i = 1; i < maxMovieIndex; i++)
			{
				[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
			}
			
			[viewer ApplyCLUTString:curCLUTMenu];
			float   iwl, iww;
			[imageView getWLWW:&iwl :&iww];
			[viewer setWLWW:iwl :iww];
			[viewer showWindow:self];
			[[viewer window] makeKeyAndOrderFront:self];
			[viewer setWLWW:iwl :iww];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

-(IBAction) segmentationTest:(id) sender
{
	[self checkEverythingLoaded];
	
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		ITKSegmentation3DController		*itk = [[ITKSegmentation3DController alloc] initWithViewer: self];
		if( itk)
		{
			[itk showWindow:self];
			[[itk window] makeKeyAndOrderFront:self];
		}
	}
}

-(IBAction) VRVPROViewer:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];
	
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		if( [VRPROController available])
		{
			if( [VRPROController  hardwareCheck])
			{
				VRPROController *viewer = [appController FindViewer :@"VRVPRO" :pixList[0]];
				
				if( viewer)
				{
					[[viewer window] makeKeyAndOrderFront:self];
				}
				else
				{
					NSString	*mode;
					
					if( [sender tag] == 3) mode = @"MIP";
					else mode = @"VR";
					
					viewer = [[VRPROController alloc] initWithPix:pixList[curMovieIndex] :fileList[0] :volumeData[ 0] :blendingController :self mode: mode];
					for( i = 1; i < maxMovieIndex; i++)
					{
						[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
					}
					
					if( [[self modality] isEqualToString:@"PT"] == YES && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
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
					}
					else
					{
						float   iwl, iww;
						[imageView getWLWW:&iwl :&iww];
						[viewer setWLWW:iwl :iww];
					}
					
					[viewer ApplyCLUTString:curCLUTMenu];
					float   iwl, iww;
					[imageView getWLWW:&iwl :&iww];
					[viewer setWLWW:iwl :iww];
					[viewer load3DState];
					[viewer showWindow:self];
					[[viewer window] makeKeyAndOrderFront:self];
					[[viewer window] display];
					[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
				}
			}
		}
		else NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"VolumePRO hardware not detected.", nil), NSLocalizedString(@"OK", nil), nil, nil);
	}
}

-(IBAction) VRViewer:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];
	
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		VRController *viewer = [appController FindViewer :@"VR" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			NSString	*mode;
			
			if( [sender tag] == 3) mode = @"MIP";
			else mode = @"VR";
			
			viewer = [[VRController alloc] initWithPix:pixList[curMovieIndex] :fileList[0] :volumeData[ 0] :blendingController :self style:@"standard" mode: mode];
			for( i = 1; i < maxMovieIndex; i++)
			{
				[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
			}
			
			if( [[self modality] isEqualToString:@"PT"] == YES && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
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
			}
			else
			{
				float   iwl, iww;
				[imageView getWLWW:&iwl :&iww];
				[viewer setWLWW:iwl :iww];
			}
			
			[viewer ApplyCLUTString:curCLUTMenu];
			float   iwl, iww;
			[imageView getWLWW:&iwl :&iww];
			[viewer setWLWW:iwl :iww];
			[viewer load3DState];
			if( [sender tag] == 3) [viewer setModeIndex: 1];
			[viewer showWindow:self];
			[[viewer window] makeKeyAndOrderFront:self];
			[[viewer window] display];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

-(IBAction) SRViewer:(id) sender
{
	[self checkEverythingLoaded];
	
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		SRController *viewer = [appController FindViewer :@"SR" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			viewer = [[SRController alloc] initWithPix:pixList[curMovieIndex] :fileList[0] :volumeData[curMovieIndex] :blendingController :self];
			[viewer showWindow:self];
			[[viewer window] makeKeyAndOrderFront:self];
			[viewer ChangeSettings:self];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

-(CurvedMPR*) curvedController
{
	return curvedController;
}

- (void) setCurvedController: (CurvedMPR*) cmpr
{
	curvedController = cmpr;
}


//static long curvedMPRthickslab, curvedMPRinterval, curvedMPRsize ;

-(IBAction) setCurvedMPRslider:(id) sender
{
	long i;
	
	i = [sender intValue];
	
	switch( [sender tag])
	{
		case 0:		
			i /= 2;
			i *= 2;
			i++;
			[curvedMPRtext setStringValue: [NSString stringWithFormat: NSLocalizedString(@"%d images, %2.2f mm", nil), i, i * [[imageView curDCM] pixelSpacingX]]];
		break;
		
		case 1:		
			i /= 2;
			i *= 2;
			[curvedMPRintervalText setStringValue: [NSString stringWithFormat: NSLocalizedString(@"%d pixels, %2.2f mm", nil), i, i * [[imageView curDCM] pixelSpacingX]]];
		break;
		
		case 2:		
			i /= 4;
			i *= 4;
			[curvedMPRsizeText setStringValue: [NSString stringWithFormat: NSLocalizedString(@"%d pixels, %2.2f mm", nil), i, i * [[imageView curDCM] pixelSpacingX]]];
		break;
	}
}

-(IBAction) endCurvedMPR:(id) sender
{
	[curvedMPRWindow orderOut:sender];
    
    [NSApp endSheet:curvedMPRWindow returnCode:[sender tag]];
	
	if( [sender tag] == 1)
	{
		long	i, x, y;
		float   volume = 0;
		ROI		*selectedRoi = 0L;
		long	err = 0;
	
		// Find the first selected
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
		{
			long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
			if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
			{
				selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
				
				if( [selectedRoi type] == tOPolygon || [selectedRoi type] == tCPolygon || [selectedRoi type] == tPencil)
				{
				
				}
				else selectedRoi = 0L;
			}
		}
		
		if( selectedRoi)
		{
			CurvedMPR *curvedMPR;
			
			if( [curvedMPRper state] == NSOnState)
				curvedMPR = [[CurvedMPR alloc] initWithObjectsPer:pixList[0] :fileList[0] :volumeData[0] :selectedRoi :self :[curvedMPRinterval intValue] :[curvedMPRsize intValue]];
			
			curvedMPR = [[CurvedMPR alloc] initWithObjects:pixList[0] :fileList[0] :volumeData[0] :selectedRoi :self :[curvedMPRslid intValue]];
		}
	}
}

-(IBAction) CurvedMPR:(id) sender
{
long i;
	
	[self checkEverythingLoaded];
	
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		long	i, x, y;
		float   volume = 0;
		ROI		*selectedRoi = 0L;
		long	err = 0;
	
		// Find the first selected
		for( i = 0; i < [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count]; i++)
		{
			long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];
			
			if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
			{
				selectedRoi = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
				
				if( [selectedRoi type] == tOPolygon || [selectedRoi type] == tCPolygon || [selectedRoi type] == tPencil)
				{
				
				}
				else selectedRoi = 0L;
			}
		}
		
		if( selectedRoi == 0L)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"Curved-MPR Error", nil), NSLocalizedString(@"Select a Polygon ROI to compute a Curved MPR.", nil) , NSLocalizedString(@"OK", nil), nil, nil);
		}
		else
		{
			[curvedMPRslid setIntValue:1];
			[curvedMPRtext setStringValue: [NSString stringWithFormat: NSLocalizedString(@"%d images, %2.2f mm", nil), [curvedMPRslid intValue], [[imageView curDCM] pixelSpacingX]]];
			
			[curvedMPRinterval setIntValue:4];
			[curvedMPRintervalText setStringValue: [NSString stringWithFormat: NSLocalizedString(@"%d pixels, %2.2f mm", nil), [curvedMPRinterval intValue], [curvedMPRinterval intValue]*[[imageView curDCM] pixelSpacingX]]];
			
			[curvedMPRsize setIntValue:48];
			[curvedMPRsizeText setStringValue: [NSString stringWithFormat: NSLocalizedString(@"%d pixels, %2.2f mm", nil), [curvedMPRsize intValue], [curvedMPRsize intValue]*[[imageView curDCM] pixelSpacingX]]];
			
			[NSApp beginSheet: curvedMPRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		}
	}
}

-(IBAction) MPR2DViewer:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];
	
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		MPR2DController *viewer = [appController FindViewer :@"MPR2D" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			// TURN OFF Thick Slab of current window... Reason? SPEEEEED !
			[self setFusionMode: 0];
			[popFusion selectItemAtIndex:0];
			
			
			viewer = [[MPR2DController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[0] :blendingController];
			
			for( i = 1; i < maxMovieIndex; i++)
			{
				[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
			}
			
			[viewer ApplyCLUTString:curCLUTMenu];
			float   iwl, iww;
			[imageView getWLWW:&iwl :&iww];
			[viewer setWLWW:iwl :iww];
			[viewer load3DState];
			[viewer showWindow:self];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

-(IBAction) orthogonalMPRViewer:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];
			
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		OrthogonalMPRViewer *viewer;
		
		if( blendingController)
		{
			viewer = [appController FindViewer :@"PETCT" :pixList[0]];
		}
		else
		{
			viewer = [appController FindViewer :@"OrthogonalMPR" :pixList[0]];
		}
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			// TURN OFF Thick Slab of current window... Reason? SPEEEEED !
			[self setFusionMode: 0];
			[popFusion selectItemAtIndex:0];
			
			if( blendingController)
			{
				OrthogonalMPRPETCTViewer *pcviewer = [[OrthogonalMPRPETCTViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :self : blendingController];
				
				[[pcviewer CTController] ApplyCLUTString:curCLUTMenu];
				[[pcviewer PETController] ApplyCLUTString:[blendingController curCLUTMenu]];
				[[pcviewer PETCTController] ApplyCLUTString:curCLUTMenu];
				// the PETCT will display the PET CLUT in CLUTpoppuMenu
				[(OrthogonalMPRPETCTView*)[[pcviewer PETCTController] originalView] setCurCLUTMenu: [blendingController curCLUTMenu]];
				[(OrthogonalMPRPETCTView*)[[pcviewer PETCTController] xReslicedView] setCurCLUTMenu: [blendingController curCLUTMenu]];
				[(OrthogonalMPRPETCTView*)[[pcviewer PETCTController] yReslicedView] setCurCLUTMenu: [blendingController curCLUTMenu]];
				
				[pcviewer showWindow:self];
				
				float   iwl, iww;
				[imageView getWLWW:&iwl :&iww];
				[[pcviewer CTController] setWLWW:iwl :iww];
				[[blendingController imageView] getWLWW:&iwl :&iww];
				[[pcviewer PETController] setWLWW:iwl :iww];
				[[pcviewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[pcviewer window] title], [[self window] title]]];
//  The following methods are NOT defined in their receivers!				
//				[[pcviewer CTController] setCurWLWWMenu:curWLWWMenu];
//				[[pcviewer PETCTController] setCurWLWWMenu:curWLWWMenu];
//				[[pcviewer PETController] setCurWLWWMenu:[blendingController curWLWWMenu]];
				
			}
			else
			{
				viewer = [[OrthogonalMPRViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :self :nil];
				
				if( [[self modality] isEqualToString:@"PT"] == YES && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
				{
					if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
						[viewer ApplyCLUTString: @"B/W Inverse"];
					else
						[viewer ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
				}
				else [viewer ApplyCLUTString:curCLUTMenu];

				[viewer showWindow:self];
				
				float   iwl, iww;
				[imageView getWLWW:&iwl :&iww];
				[viewer setWLWW:iwl :iww];
				[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
//				[[viewer controller] setCurWLWWMenu:curWLWWMenu];				
			}
		}
	}
}


-(IBAction) endoscopyViewer:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];
			
	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		EndoscopyViewer *viewer;
		
		viewer = [appController FindViewer :@"Endoscopy" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			// TURN OFF Thick Slab of current window... Reason? SPEEEEED !
			[self setFusionMode: 0];
			[popFusion selectItemAtIndex:0];
			
			viewer = [[EndoscopyViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :blendingController : self];
			
//			[viewer ApplyCLUTString:curCLUTMenu];
//			
//			float   iwl, iww;
//			[imageView getWLWW:&iwl :&iww];
//			[viewer setWLWW:iwl :iww];
			//[viewer setCurWLWWMenu:curWLWWMenu];
			
			[viewer showWindow:self];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

//-(IBAction) MIPViewer:(id) sender
//{
//	long i;
//	
//	[self checkEverythingLoaded];
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
//		MIPController *viewer = [appController FindViewer :@"MIP" :pixList[0]];
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


#pragma mark-
#pragma mark 4.5.4 Study navigation


-(IBAction) loadPatient:(id) sender
{
	[browserWindow loadNextPatient:[fileList[0] objectAtIndex:0] :[sender tag] :self :YES keyImagesOnly: [keyImageDisplay tag]];
}

-(IBAction) loadSerie:(id) sender
{
	if( [sender tag] == 3)
	{
		[[sender selectedItem] setImage:0L];
		[browserWindow loadSeries :[[sender selectedItem] representedObject] :self :YES keyImagesOnly: [keyImageDisplay tag]];
	}
	else [browserWindow loadNextSeries:[fileList[0] objectAtIndex:0] :[sender tag] :self :YES keyImagesOnly: [keyImageDisplay tag]];
}
- (BOOL) isEverythingLoaded
{
	if( ThreadLoadImage) return NO;
	else return YES;
}

-(void) checkEverythingLoaded
{
	if( ThreadLoadImage == YES)
	{
		WaitRendering *splash = [[WaitRendering alloc] init:NSLocalizedString(@"Data loading...", nil)];
		[splash showWindow:self];
		
		if( [browserWindow isCurrentDatabaseBonjour])
		{
			while( [ThreadLoadImageLock tryLock] == NO) [browserWindow bonjourRunLoop: self];
		}
		else [ThreadLoadImageLock lock];
		[ThreadLoadImageLock unlock];
		
		while( loadingPercentage != 1)
		{
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];		// To be sure that PerformOnMainThread has been called !
		}
		
		[splash close];
		[splash release];
		
		[self setWindowTitle: self];
	}
}

-(void) revertSeries:(id) sender
{
	long i, x;
	
	[self checkEverythingLoaded];
	
	for( x = 0; x < maxMovieIndex; x++)
	{
		for( i = 0 ; i < [pixList[ x] count]; i++)
		{
			if( stopThreadLoadImage == NO)
			{
				DCMPix* pix = [pixList[ x] objectAtIndex: i];
				[pix revert];
			}
		}
	}
	
	[self startLoadImageThread];
	
	ThreadLoadImage = YES;
	[self checkEverythingLoaded];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ curMovieIndex] userInfo: 0L];
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
	[[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] setValue:[NSNumber numberWithBool:[sender state]] forKey:@"isKeyImage"];
	
	if([browserWindow isCurrentDatabaseBonjour])
	{
		[browserWindow setBonjourDatabaseValue:[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] value:[NSNumber numberWithBool:[sender state]] forKey:@"isKeyImage"];
	}
}



- (IBAction) keyImageDisplayButton:(id) sender
{
	NSManagedObject	*series = [[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKey:@"series"];
	long i;
	
	[self checkEverythingLoaded];
	
	if( series)
	{
		if( [keyImageDisplay tag] == 1)
		{
			// ALL IMAGES ARE DISPLAYED
			[keyImageDisplay setTag: 0];
			[keyImageDisplay setTitle: NSLocalizedString(@"Key Images", nil)];
			
			NSArray	*images = [browserWindow childrenArray: series];
			
			[browserWindow openViewerFromImages :[NSArray arrayWithObject: images] movie: NO viewer :self keyImagesOnly: [keyImageDisplay tag]];
		}
		else
		{
			// ONLY KEY IMAGES
			NSArray	*images = [browserWindow childrenArray: series];
			NSArray *keyImagesArray = [NSArray array];
			
			for( i = 0; i < [images count]; i++)
			{
				NSManagedObject	*image = [images objectAtIndex: i];
				
				if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
					keyImagesArray = [keyImagesArray arrayByAddingObject: image];
			}
			
			if( [keyImagesArray count] == 0)
			{
				NSRunAlertPanel(NSLocalizedString(@"Key Images", nil), NSLocalizedString(@"No key images have been selected in this series.", nil), nil, nil, nil);
			}
			else
			{
				[keyImageDisplay setTag: 1];
				[keyImageDisplay setTitle: NSLocalizedString(@"All images", nil)];
				
				[browserWindow openViewerFromImages :[NSArray arrayWithObject: keyImagesArray] movie: NO viewer :self keyImagesOnly: [keyImageDisplay tag]];
			}
		}
	}
}


- (IBOutlet)setKeyImage:(id)sender
{
	[keyImageCheck setState: ![keyImageCheck state]];
	[self keyImageCheckBox: keyImageCheck];
}


- (void) adjustKeyImage
{
	// Update Key Image check box
	if( [[[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKey:@"isKeyImage"] boolValue] == YES)
	{
		[keyImageCheck setState: NSOnState];
	}
	else
	{
		[keyImageCheck setState: NSOffState];
	}
}

#pragma mark-

- (OSErr)getFSRefAtPath:(NSString*)sourceItem ref:(FSRef*)sourceRef
{
    OSErr    err;
    BOOL    isSymLink;
    id manager=[NSFileManager defaultManager];
    NSDictionary *sourceAttribute = [manager fileAttributesAtPath:sourceItem
traverseLink:NO];
    isSymLink = ([sourceAttribute objectForKey:@"NSFileType"] ==
NSFileTypeSymbolicLink);
    if(isSymLink){
        const char    *sourceParentPath;
        FSRef        sourceParentRef;
        HFSUniStr255    sourceFileName;

        sourceParentPath = (char*)[[sourceItem stringByDeletingLastPathComponent] fileSystemRepresentation];
        err = FSPathMakeRef((UInt8 *) sourceParentPath, &sourceParentRef, NULL);
        if(err == noErr){
            [[sourceItem lastPathComponent] getCharacters:sourceFileName.unicode];
            sourceFileName.length = [[sourceItem lastPathComponent] length];
            if (sourceFileName.length == 0){
                err = fnfErr;
            }
            else err = FSMakeFSRefUnicode(&sourceParentRef,
sourceFileName.length, sourceFileName.unicode, kTextEncodingFullName,
sourceRef);
        }
    }
    else{
        err = FSPathMakeRef((UInt8 *)[sourceItem fileSystemRepresentation], sourceRef, NULL);
    }

    return err;
}


/*
-(void) ShowHideBlending: (id) sender
{
    NSDrawerState state = [blendingDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
        [blendingDrawer close];
    } else {
        [blendingDrawer openOnEdge:NSMinXEdge];
    }
}*/



- (IBAction) endSetComments:(id) sender
{
	[CommentsWindow orderOut:sender];
    
    [NSApp endSheet:CommentsWindow returnCode:[sender tag]];
	
	if( [sender tag] == 1)
	{
		[[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] setValue:[CommentsEditField stringValue] forKeyPath:@"series.study.comment"];
		
		if([browserWindow isCurrentDatabaseBonjour])
		{
			[browserWindow setBonjourDatabaseValue:[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] value:[CommentsEditField stringValue] forKey:@"series.study.comment"];
		}
		
		[[browserWindow databaseOutline] reloadData];
		
		if( [[CommentsEditField stringValue] isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"No Comments", nil)];
		else [CommentsField setTitle: [CommentsEditField stringValue]];
	}
}

- (IBAction) setComments:(id) sender
{
	if( [[CommentsField title] isEqualToString:NSLocalizedString(@"No Comments", nil)]) [CommentsEditField setStringValue: @""];
	else [CommentsEditField setStringValue: [CommentsField title]];
	
	[CommentsEditField selectText: self];
	
	[NSApp beginSheet: CommentsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction) setStatus:(id) sender
{
	[[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] setValue:[NSNumber numberWithInt:[[sender selectedItem] tag]] forKeyPath:@"series.study.stateText"];
	
	if([browserWindow isCurrentDatabaseBonjour])
	{
		[browserWindow setBonjourDatabaseValue:[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] value:[NSNumber numberWithInt:[[sender selectedItem] tag]] forKey:@"series.study.stateText"];
	}
		
	[[browserWindow databaseOutline] reloadData];
}

- (IBAction) databaseWindow : (id) sender
{
	if (!([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Close All Viewers" object:self userInfo: 0L];	
		[self close];
	}
	else
		[browserWindow showDatabase:self];
	
}
//Modify window zoom behavior
- (void)setStandardRect:(NSRect)rect{
	standardRect = rect;
	
}


@end
