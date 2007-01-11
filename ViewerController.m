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


#if !__LP64__
#import "AYDicomPrintWindowController.h"
#endif

#import "MyOutlineView.h"
#import "PluginFilter.h"
#import "DCMPix.h"
#import "DicomImage.h"
#import "VRController.h"
#import "VRControllerVPRO.h"
#import "NSSplitViewSave.h"
#import "SRController.h"
//#import "MPRController.h"
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
#import "DCMAbstractSyntaxUID.h"
#import "printView.h"
#import "HornRegistration.h"
#import "ITKTransform.h"
#import "LLScoutViewer.h"

#import "KeyObjectController.h"
#import "KeyObjectPopupController.h"

#import "SRAnnotationController.h"
#import "Reports.h"
#import "ViewerControllerDCMTKCategory.h"
#import "MenuDictionary.h"

#if defined (MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	#import <InstantMessage/IMService.h>
	#import <InstantMessage/IMAVManager.h>
#endif

@class VRPROController;

extern	NSMutableDictionary		*plugins, *pluginsDict;
extern  ToolbarPanelController  *toolbarPanel[ 10];
extern  AppController			*appController;
extern  BrowserController       *browserWindow;
extern  BOOL					USETOOLBARPANEL;
extern  NSMenu					*fusionPluginsMenu;
extern	BOOL					SYNCSERIES;

		
static NSString* 	ViewerToolbarIdentifier				= @"Viewer Toolbar Identifier";
static NSString*	QTSaveToolbarItemIdentifier			= @"QTExport.icns";
static NSString*	iPhotoToolbarItemIdentifier			= @"iPhoto2";
static NSString*	PagePadToolbarItemIdentifier		= @"PagePad";
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
static NSString*	ShutterToolbarItemIdentifier		= @"Shutter";
static NSString*	OrientationToolbarItemIdentifier	= @"Orientation";
static NSString*	PrintToolbarItemIdentifier			= @"Print.icns";

static NSArray*		DefaultROINames;

static	BOOL EXPORT2IPHOTO								= NO;
static	ViewerController *blendedwin					= 0L;
static	float	deg2rad									= 3.14159265358979/180.0; 

//static ViewerController *gSelf;

long numberOf2DViewer = 0;

NSString * documentsDirectory();
NSString* convertDICOM( NSString *inputfile);

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

- (void) setPostprocessed:(BOOL) v
{
	postprocessed = v;
}

- (BOOL) postprocessed
{
	return postprocessed;
}

- (void) replaceSeriesWith:(NSMutableArray*)newPixList :(NSMutableArray*)newDcmList :(NSData*) newData
{
	[self changeImageData:newPixList :newDcmList :newData :NO];
	loadingPercentage = 1;
	[self computeInterval];
	[self setWindowTitle:self];
	[imageView setIndex: [newPixList count]/2];
	[imageView sendSyncMessage:1];
	[self adjustSlider];
}

static volatile int numberOfThreadsForRelisce = 0;

- (BOOL) waitForAProcessor
{
	int processors =  MPProcessors ();
	
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
	
	int x,y;
	int i = [[dict valueForKey:@"i"] intValue];
	int sign = [[dict valueForKey:@"sign"] intValue];
	int newX = [[dict valueForKey:@"newX"] intValue];
	float *curPixFImage = [[dict valueForKey:@"curPix"] fImage];
	int rowBytes = [[dict valueForKey:@"rowBytes"] intValue];
	
	float *srcPtr, *dstPtr, *mainSrcPtr;
	int count = [pixList[ curMovieIndex] count];
	
	count /= 2;
	count *= 2;
	
	if( sign > 0)
		mainSrcPtr = [[pixList[ curMovieIndex] objectAtIndex: count-1] fImage];
	else
		mainSrcPtr = [[pixList[ curMovieIndex] objectAtIndex: 0] fImage];
	
	int sliceSize = [[pixList[ curMovieIndex] objectAtIndex: 0] pwidth] * [[pixList[ curMovieIndex] objectAtIndex: 0] pheight];
	
	for(x = 0; x < count; x++)
	{
		if( sign > 0)
			srcPtr = mainSrcPtr - x*sliceSize + i;
		else
			srcPtr = mainSrcPtr + x*sliceSize + i;
		dstPtr = curPixFImage + x * newX;
		
		y = newX;
		while (y-->0)
		{
			*dstPtr++ = *srcPtr;
			srcPtr += rowBytes;
		}
	}

	[processorsLock lock];
	if( numberOfThreadsForRelisce >= 0) numberOfThreadsForRelisce--;
	[processorsLock unlockWithCondition: 1];
	
	[pool release];
}

-(void) processReslice:(long) directionm :(BOOL) newViewer
{
	DCMPix				*firstPix = [pixList[ curMovieIndex] objectAtIndex: 0];
	DCMPix				*lastPix = 0L;
	long				i, newTotal;
	unsigned char		*emptyData;
	ViewerController	*new2DViewer;
	long				imageSize, size, x, y, newX, newY;
	float				orientation[ 9], newXSpace, newYSpace, origin[ 3], sign, ratio;
	BOOL				square = NO;
	
	
	// Get Values
	if( directionm == 0)		// X - RESLICE
	{
		newTotal = [firstPix pheight];
		
		newX = [firstPix pwidth];
		
		if( square)
		{
			newXSpace = [firstPix pixelSpacingX];
			newYSpace = [firstPix pixelSpacingX];
			
			ratio = fabs( [firstPix sliceInterval]) / [firstPix pixelSpacingX];
			
			newY = ([pixList[ curMovieIndex] count] * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingX];
		}
		else
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
			
			ratio = fabs( [firstPix sliceInterval]) / [firstPix pixelSpacingY];
			
			newY = ([pixList[ curMovieIndex] count]  * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingY];
		}
		else
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
	
	// Display a waiting window
	id waitWindow = [self startWaitWindow:@"Reslicing..."];
	
	if( [firstPix sliceInterval] > 0) sign = 1.0;
	else sign = -1.0;
	
	imageSize = sizeof(float) * newX * newY;
	size = newTotal * imageSize;
	
	// CREATE A NEW SERIES WITH ALL IMAGES !
	emptyData = malloc( size);
	if( emptyData)
	{
		NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
		NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
		
		NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
		
		NSLog( @"reslice start");
		
		for( i = 0 ; i < newTotal; i ++)
		{
			[newPixList addObject: [[[pixList[ curMovieIndex] objectAtIndex: 0] copy] autorelease]];
			
			// SUV
			[[newPixList lastObject] setDisplaySUVValue: [firstPix displaySUVValue]];
			[[newPixList lastObject] setSUVConverted: [firstPix SUVConverted]];
			[[newPixList lastObject] setRadiopharmaceuticalStartTime: [firstPix radiopharmaceuticalStartTime]];
			[[newPixList lastObject] setPatientsWeight: [firstPix patientsWeight]];
			[[newPixList lastObject] setRadionuclideTotalDose: [firstPix radionuclideTotalDose]];
			[[newPixList lastObject] setRadionuclideTotalDoseCorrected: [firstPix radionuclideTotalDoseCorrected]];
			[[newPixList lastObject] setAcquisitionTime: [firstPix acquisitionTime]];
			[[newPixList lastObject] setDecayCorrection: [firstPix decayCorrection]];
			[[newPixList lastObject] setDecayFactor: [firstPix decayFactor]];
			[[newPixList lastObject] setUnits: [firstPix units]];
			
			[[newPixList lastObject] setPwidth: newX];
			[[newPixList lastObject] setPheight: newY];
			
			[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
			[[newPixList lastObject] setTot: newTotal];
			[[newPixList lastObject] setFrameNo: [newPixList count]-1];
			[[newPixList lastObject] setID: [newPixList count]-1];
			
			[newDcmList addObject: [fileList[ curMovieIndex] objectAtIndex: 0] ];
			
			if( directionm == 0)		// X - RESLICE
			{
				DCMPix	*curPix = [newPixList lastObject];
				
				int count = [pixList[ curMovieIndex] count];
				int pwidth = [[pixList[ curMovieIndex] objectAtIndex: 0] pwidth];
				
				count /= 2;
				count *= 2;
				
				if( sign > 0)
				{
					for( y = 0; y < count; y++)
					{
						memcpy(	[curPix fImage] + (count-y-1) * newX,
								[[pixList[ curMovieIndex] objectAtIndex: y] fImage] + i * pwidth,
								newX * sizeof( float));
					}
				}
				else
				{
					for( y = 0; y < count; y++)
					{
						memcpy(	[curPix fImage] + y * newX,
								[[pixList[ curMovieIndex] objectAtIndex: y] fImage] + i * pwidth,
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
					
					vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
											
//						for( x = 0; x < newX; x++)
//						{
//							srcPtr = [curPix fImage] + x ;
//							
//							for( y = newY-1; y >= 0; y--)
//							{
//								s = y / ratio;
//								left = s - floor(s);
//								right = 1-left;
//								
//								*(srcPtr + y * rowBytes) = right * *(srcPtr + (long) (s) * rowBytes) + left * *(srcPtr + (long) ((s)+1) * rowBytes);
//							}
//						}
				}
				
				if( sign > 0)
						[lastPix orientation: orientation];
				else
						[firstPix orientation: orientation];
				
				float cc[ 3];
				
				cc[ 0] = orientation[ 3];
				cc[ 1] = orientation[ 4];
				cc[ 2] = orientation[ 5];
				
				if( sign > 0)
				{
					// Y Vector = Normal Vector
					orientation[ 3] = orientation[ 6] * -sign;
					orientation[ 4] = orientation[ 7] * -sign;
					orientation[ 5] = orientation[ 8] * -sign;
				}
				else
				{
					// Y Vector = Normal Vector
					orientation[ 3] = orientation[ 6] * sign;
					orientation[ 4] = orientation[ 7] * sign;
					orientation[ 5] = orientation[ 8] * sign;
				}
				
				[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
				
				[curPix setPixelSpacingX: newXSpace];
				[curPix setPixelSpacingY: newYSpace];
				
				[curPix setPixelRatio:  newYSpace / newXSpace];
				
				[curPix orientation: orientation];
				
				if( sign > 0)
				{
					origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * sign;
					origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * sign;
					origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * sign;
				}
				else
				{
					origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * -sign;
					origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * -sign;
					origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * -sign;
				}
				
				if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
				{
					[[newPixList lastObject] setSliceLocation: origin[ 0]];
				}
				if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
				{
					[[newPixList lastObject] setSliceLocation: origin[ 1]];
				}
				if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
				{
					[[newPixList lastObject] setSliceLocation: origin[ 2]];
				}
				
				[[newPixList lastObject] setSliceThickness: [firstPix pixelSpacingY]];
				[[newPixList lastObject] setSliceInterval: 0];
				[curPix setOrigin: origin];
			}
			else											// Y - RESLICE
			{
				DCMPix	*curPix = [newPixList lastObject];
				float	*srcPtr;
				float	*dstPtr;
				long	rowBytes = [firstPix pwidth];
				
				[self waitForAProcessor];
				
				[NSThread detachNewThreadSelector: @selector( resliceThread:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: i], @"i", [NSNumber numberWithInt: sign], @"sign", [NSNumber numberWithInt: newX], @"newX",[NSNumber numberWithInt: rowBytes], @"rowBytes", curPix, @"curPix", 0L]];
				
//				for(x = 0; x < [pixList[ curMovieIndex] count]; x++)
//				{
//					if( sign > 0)
//						srcPtr = [[pixList[ curMovieIndex] objectAtIndex: [pixList[ curMovieIndex] count]-x-1] fImage] + i;
//					else
//						srcPtr = [[pixList[ curMovieIndex] objectAtIndex: x] fImage] + i;
//					dstPtr = [curPix fImage] + x * newX;
//					
//					y = newX;
//					while (y-->0)
//					{
//						*dstPtr = *srcPtr;
//						dstPtr++;
//						srcPtr += rowBytes;
//					}
//				}
									
				if( square)
				{
					vImage_Buffer	srcVimage, dstVimage;
					
					srcVimage.data = [curPix fImage];
					srcVimage.height =  [pixList[ curMovieIndex] count];
					srcVimage.width = newX;
					srcVimage.rowBytes = newX*4;
					
					dstVimage.data = [curPix fImage];
					dstVimage.height =  newY;
					dstVimage.width = newX;
					dstVimage.rowBytes = newX*4;
					
					vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
					
//						for( x = 0; x < newX; x++)
//						{
//							srcPtr = [curPix fImage] + x ;
//							
//							for( y = newY-1; y >= 0; y--)
//							{
//								s = y / ratio;
//								left = s - floor(s);
//								right = 1-left;
//								
//								*(srcPtr + y * rowBytes) = right * *(srcPtr + (long) (s) * rowBytes) + left * *(srcPtr + (long) ((s)+1) * rowBytes);
//							}
//						}
				}
				
				if( sign > 0)
						[lastPix orientation: orientation];
				else
						[firstPix orientation: orientation];
				
				// Y Vector = Normal Vector
				orientation[ 0] = orientation[ 3];
				orientation[ 1] = orientation[ 4];
				orientation[ 2] = orientation[ 5];
				
				if( sign > 0)
				{
					orientation[ 3] = orientation[ 6] * -sign;
					orientation[ 4] = orientation[ 7] * -sign;
					orientation[ 5] = orientation[ 8] * -sign;
				}
				else
				{
					orientation[ 3] = orientation[ 6] * sign;
					orientation[ 4] = orientation[ 7] * sign;
					orientation[ 5] = orientation[ 8] * sign;
				}
				
				[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
				
				[curPix setPixelSpacingX: newXSpace];
				[curPix setPixelSpacingY: newYSpace];
				
				[curPix setPixelRatio:  newYSpace / newXSpace];
				
				[curPix orientation: orientation];
				if( sign > 0)
				{
					origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * -sign;
					origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * -sign;
					origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * -sign;
				}
				else
				{
					origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * sign;
					origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * sign;
					origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * sign;
				}
				
				if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
				{
					[[newPixList lastObject] setSliceLocation: origin[ 0]];
				}
				if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
				{
					[[newPixList lastObject] setSliceLocation: origin[ 1]];
				}
				if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
				{
					[[newPixList lastObject] setSliceLocation: origin[ 2]];
				}
				
				[[newPixList lastObject] setSliceThickness: [firstPix pixelSpacingX]];
				[[newPixList lastObject] setSliceInterval: 0];
				
				[curPix setOrigin: origin];
			}
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
		
		if( newViewer)
		{
			ViewerController	*new2DViewer;
			
			// CREATE A SERIES
			new2DViewer = [self newWindow	:newPixList :newDcmList :newData];
			[new2DViewer setImageIndex: [newPixList count]/2];
			[[new2DViewer window] makeKeyAndOrderFront: self];
		}
		else [self replaceSeriesWith :newPixList :newDcmList :newData];
		
		postprocessed = YES;
	}
	
	// Close the waiting window
	[self endWaitWindow: waitWindow];
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
		
		for( x = 0; x < [pixList[ y] count]; x++)
		{
			src.height = dest.height = [firstObject pheight];
			src.width = dest.width = [firstObject pwidth];
			src.rowBytes = src.width*4;
			dest.rowBytes = dest.width*4;
			src.data = volumeDataPtr;
			
			vImageVerticalReflect_PlanarF ( &src, &dest, 0L);
			
			memcpy( src.data, dest.data, [firstObject pheight] * [firstObject pwidth] * 4);
			volumeDataPtr += [firstObject pheight]*[firstObject pwidth];
		}
		
		free( dest.data);
	}
	
	for( y = 0 ; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[ y] count]; x++)
		{
			float	o[ 9];
			DCMPix	*dcm = [pixList[ y] objectAtIndex: x];
			
			[dcm orientation: o];
			
			o[ 3] *= -1;
			o[ 4] *= -1;
			o[ 5] *= -1;
			
			[dcm setOrientation: o];
			[dcm setSliceInterval: 0];
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
		
		vImageHorizontalReflect_PlanarF ( &src, &dest, 0L);
	}
	
	for( y = 0 ; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[ y] count]; x++)
		{
			float	o[ 9];
			DCMPix	*dcm = [pixList[ y] objectAtIndex: x];
			
			[dcm orientation: o];
			
			o[ 0] *= -1;
			o[ 1] *= -1;
			o[ 2] *= -1;
			
			[dcm setOrientation: o];
			[dcm setSliceInterval: 0];
		}
	}
	
	[self setPostprocessed: YES];
	
	[self computeInterval];
	[self updateImage: self];
}

- (void) rotateDataSet:(int) constant
{
	int y, x;
	float rot = 0;
	
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
			
			
			vImageRotate90_PlanarF ( &src, &dest, constant, 0, 0L);
			
			memcpy( src.data, dest.data, [firstObject pheight] * [firstObject pwidth] * 4);
			
			volumeDataPtr += [firstObject pheight]*[firstObject pwidth];
		}
		
		free( dest.data);
	}
	
	for( y = 0 ; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[ y] count]; x++)
		{
			float	o[ 9];
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
				[dcm setRowBytes: y*4];
			}
			
			[dcm orientation: o];
			
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
			
			[dcm setOrientation: o];
			[dcm setSliceInterval: 0];
		}
	}
	
	[self setPostprocessed: YES];
	
	[self computeInterval];
	[self updateImage: self];
}

- (IBAction) squareDataSet:(id) sender
{
	int x, y;
	
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
		}
	}
	
	[self setPostprocessed: YES];
}

- (IBAction) setOrientationTool:(id) sender
{
	short newOrientationTool = [[sender selectedCell] tag];
	
	if( newOrientationTool != currentOrientationTool)
	{
		float previousZooming = [imageView scaleValue] / [[pixList[ curMovieIndex] objectAtIndex: 0] pixelSpacingX];

		if( displayOnlyKeyImages)
		{
			[keyImagePopUpButton selectItemAtIndex: 0];
			[self keyImageDisplayButton: self];
		}
		
		[self checkEverythingLoaded];
	
		BOOL volumicData = YES;
		
		int previousFusion = [popFusion selectedTag];
		
		long moviePixWidth = [[pixList[ curMovieIndex] objectAtIndex: 0] pwidth];
		long moviePixHeight = [[pixList[ curMovieIndex] objectAtIndex: 0] pheight];
		
		long j;
		for( j = 0 ; j < [pixList[ curMovieIndex] count]; j++)
		{
			if ( moviePixWidth != [[pixList[ curMovieIndex] objectAtIndex: j] pwidth]) volumicData = NO;
			if ( moviePixHeight != [[pixList[ curMovieIndex] objectAtIndex: j] pheight]) volumicData = NO;
		}
		
		if( volumicData == NO)
		{
			NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool works only with 3D data series.", nil), nil, nil, nil);
			return;
		}
		
		if( [[pixList[ curMovieIndex] objectAtIndex: 0] isRGB])
		{
			NSRunAlertPanel(NSLocalizedString(@"Data Error", nil), NSLocalizedString(@"This tool works only with B/W data series.", nil), nil, nil, nil);
			return;
		}
	
		BOOL newViewer = NO;
		
		[imageView setDrawing: NO];
		
		[imageView stopROIEditingForce: YES];
		[self checkEverythingLoaded];

		if( blendingController) [self ActivateBlending: 0L];
		
		switch( currentOrientationTool)
		{
			case 0:
			{
				switch( newOrientationTool)
				{
					case 0:
						[imageView setIndex: [pixList[curMovieIndex] count]/2];
						[imageView sendSyncMessage:1];
						[self adjustSlider];
					break;
					
					case 1:
						[self checkEverythingLoaded];
						[self processReslice: 0 :newViewer];
					break;
					
					case 2:
						[self checkEverythingLoaded];
						[self processReslice: 1 :newViewer];
					break;
				}
			}
			break;

			case 1:
			{
				switch( newOrientationTool)
				{
					case 0:
						[self checkEverythingLoaded];
						[self processReslice: 0 :newViewer];
						
						[self vertFlipDataSet: self];
					break;
					
					case 1:
						[imageView setIndex: [pixList[curMovieIndex] count]/2];
						[imageView sendSyncMessage:1];
						[self adjustSlider];
					break;
					
					case 2:
						[self checkEverythingLoaded];
						[self processReslice: 1 :newViewer];
						
						[self rotateDataSet: kRotate90DegreesClockwise];
					break;
				}
			}
			break;

			case 2:
			{
				switch( newOrientationTool)
				{
					case 0:
						[self checkEverythingLoaded];
						[self processReslice: 0 :newViewer];
						
						[self rotateDataSet: kRotate90DegreesClockwise];
						[self horzFlipDataSet: self];
					break;
					
					case 1:
						[self checkEverythingLoaded];
						[self processReslice: 1 :newViewer];
						
						[self rotateDataSet: kRotate90DegreesClockwise];
						[self horzFlipDataSet: self];
					break;
					
					case 2:
						[imageView setIndex: [pixList[curMovieIndex] count]/2];
						[imageView sendSyncMessage:1];
						[self adjustSlider];
					break;
				}
			}
			break;
		}
		
		currentOrientationTool = newOrientationTool;
		
		if( newViewer == NO) [orientationMatrix selectCellWithTag: currentOrientationTool];

		float   iwl, iww;
		[imageView getWLWW:&iwl :&iww];
		[imageView setWLWW:iwl :iww];
		
		if( previousFusion != 0)
		{
			[self checkEverythingLoaded];
			[self computeInterval];
			[self setFusionMode: previousFusion];
			[popFusion selectItemWithTag:previousFusion];
		}
		
		NSLog( @"originalOrientation: %d", originalOrientation);
				
		[imageView setScaleValue: previousZooming * [[pixList[ curMovieIndex] objectAtIndex: 0] pixelSpacingX]];
		
		[imageView setDrawing: YES];
		
		[self updateImage: self];
	}
}

- (void) contextualDictionaryPath:(NSString *)newContextualDictionaryPath
{
	if (contextualDictionaryPath != newContextualDictionaryPath)
	{
		[contextualDictionaryPath release];
		contextualDictionaryPath = [newContextualDictionaryPath retain];
	}
}

- (NSString *) contextualDictionaryPath {return contextualDictionaryPath;}

-(void)createDCMViewMenu{
// if contextualMenuPath says @"default", recreate the default menu once and again
// if contextualMenuPath contains a path, create the new contextual menu
// if contextualMenuPath says @"custom", don't do anything
//	NSLog([self contextualDictionaryPath]);

		if([contextualDictionaryPath isEqualToString:@"default"]) // JF20070102
		{

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
	else //use the menuDictionary of the path JF20070102
	{
		   NSArray *pathComponents = [[self contextualDictionaryPath] pathComponents];
		   NSString *plistTitle = [[pathComponents objectAtIndex:([pathComponents count]-1)] stringByDeletingPathExtension];
		   NSMenu *contextual = [[NSMenu alloc] initWithTitle:plistTitle
											   withDictionary:[NSDictionary dictionaryWithContentsOfFile:[self contextualDictionaryPath]]
										  forWindowController:self
								 ];
		   [imageView setMenu:contextual];
	}

}


- (void) setWindowTitle:(id) sender
{
	NSString	*loading = [NSString stringWithString:@"         "];
	
	if( ThreadLoadImage == YES || loadingPercentage == 0)
	{
		if( loadingPercentage != 1)
		{
			loading = [NSString stringWithFormat:NSLocalizedString(@" - %2.f%%", nil), loadingPercentage * 100.];
			[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(setWindowTitle:)  userInfo:0L repeats:NO];
		}
	}
	
	NSManagedObject	*curImage = [fileList[ curMovieIndex] objectAtIndex:0];
	
	if( [[[curImage valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"])
	{
		[[self window] setTitle: NSLocalizedString( @"No images", 0L)];
	}
	else
	{
		NSDate	*bod = [curImage valueForKeyPath:@"series.study.dateOfBirth"];
		
		NSString	*shortDateString = [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateOfBirthFormat"];
		NSDictionary	*localeDictionnary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotFull)
		{
			if( [curImage valueForKeyPath:@"series.study.dateOfBirth"])
				[[self window] setTitle: [NSString stringWithFormat: @"%@ - %@ (%@) - %@ (%@)%@", [curImage valueForKeyPath:@"series.study.name"], [bod descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary], [curImage valueForKeyPath:@"series.study.yearOld"], [curImage valueForKeyPath:@"series.name"], [[curImage valueForKeyPath:@"series.id"] stringValue], loading]];
			else
				[[self window] setTitle: [NSString stringWithFormat: @"%@ - %@ (%@)%@", [curImage valueForKeyPath:@"series.study.name"], [curImage valueForKeyPath:@"series.name"], [[curImage valueForKeyPath:@"series.id"] stringValue], loading]];
		}	
		else [[self window] setTitle: [NSString stringWithFormat: @"%@ (%@)%@", [curImage valueForKeyPath:@"series.name"], [[curImage valueForKeyPath:@"series.id"] stringValue], loading]];
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
	contextualDictionaryPath = [@"default" retain];//JF20070103
	//[self createDCMViewMenu];
	keyObjectPopupController = [[KeyObjectPopupController alloc]initWithViewerController:self popup:keyImagePopUpButton];
	[keyImagePopUpButton selectItemAtIndex:displayOnlyKeyImages];
	seriesView = [[[studyView seriesViews] objectAtIndex:0] retain];
	imageView = [[[seriesView imageViews] objectAtIndex:0] retain];
}

+ (ViewerController *) newWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
    ViewerController *win = [[ViewerController alloc] viewCinit:f :d :v];
	
	[win showWindowTransition];
	[win startLoadImageThread]; // Start async reading of all images
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
		[appController tileWindows: self];
	else
		[appController checkAllWindowsAreVisible: self];
	return win;
}

- (ViewerController *) newWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
	return [ViewerController newWindow:f :d :v];
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

- (void)setWindowFrame:(NSRect)rect
{
	NSRect	curRect = [[self window] frame];
	
	[self setStandardRect:rect];
	
	if( NSEqualRects( curRect, rect) == NO)
	{
		[[self window] setFrame:rect display:YES];
		[[self window] orderFront:self];
		[[self imageView] scaleToFit];
	}
	else
	{
		[[self window] orderFront:self];
	}
}


-(BOOL) windowWillClose
{
	return windowWillClose;
}

- (BOOL)windowShouldClose:(id)sender
{
	[imageView stopROIEditingForce: YES];
	
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
	if( FullScreenOn == YES ) [self fullScreenMenu: self];
	
	[imageView stopROIEditingForce: YES];
	[imageView setDrawing: NO];
	
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


- (void)windowDidResize:(NSNotification *)aNotification
{
	if( [aNotification object] == [self window])
	{
		[self matrixPreviewSelectCurrentSeries];
	}
}

- (void) WindowDidResignMainNotification:(NSNotification *)aNotification
{
	[imageView stopROIEditingForce: YES];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOHIDEMATRIX"]) [self autoHideMatrix];
}

-(void) WindowDidResignKeyNotification:(NSNotification *)aNotification
{
	[imageView stopROIEditingForce: YES];
	
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
	if (![[note object] isEqual:self])
	{
		if( FullScreenOn == YES ) [self fullScreenMenu: self];
		NSLog(@"close");
		[[self window] close];
	}
}


-(IBAction) fullScreenMenu:(id) sender
{
//	[self squareDataSet: self];
//	return;

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
        
		NSRect frame = [[[splitView subviews] objectAtIndex: 0] frame];
		int previous = frame.size.width;
		frame.size.width = 0;
		[[[splitView subviews] objectAtIndex: 0] setFrameSize: frame.size];
		
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
			
			frame.size.width = previous;
			[[[splitView subviews] objectAtIndex: 0] setFrameSize: frame.size];
			
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
		NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] mutableCopy] autorelease];
		[presetsDict setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], 0L] forKey:[newName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey: @"WLWW3"];
        
		if( curWLWWMenu != [newName stringValue])
		{
			[curWLWWMenu release];
			curWLWWMenu = [[newName stringValue] retain];
        }
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

	NSLog(@"ViewController dealloc Start");
	
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

	int x, z;
	for( i = 0; i < maxMovieIndex; i++)
	{
		for( x = 0; x < [roiList[ i] count] ; x++)
		{
			for( z = 0; z < [[roiList[ i] objectAtIndex: x] count]; z++)
				[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:[[roiList[ i] objectAtIndex: x] objectAtIndex: z] userInfo: 0L];
		}
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
	
	[keyObjectPopupController release];
	
	[contextualDictionaryPath release];
	
	[curCLUTMenu release];
	[curConvMenu release];
	[curWLWWMenu release];
	[processorsLock release];
	
    [super dealloc];

//	[appController tileWindows: 0L];	<- We cannot do this, because:
//	This is very important, or if we have a queue of closing windows, it will crash....
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:appController selector:@selector(tileWindows:) object:0L];
		[appController performSelector: @selector(tileWindows:) withObject:0L afterDelay: 0.1];
	}
	
	NSLog(@"ViewController dealloc End");
	
#if defined (MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
#if !__LP64__
	[[IMAVManager sharedAVManager] setVideoDataSource:nil];
	[[IMService notificationCenter] removeObserver:self];
#endif
#endif
}


- (DCMView*) imageView { return imageView;}


-(NSString*) modality
{
	return [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.modality"];
}

+ (long) numberOf2DViewer
{
	return numberOf2DViewer;
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
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSCommandKeyMask && FullScreenOn == NO) 
	{
		[browserWindow loadSeries :[[sender selectedCell] representedObject] :0L :YES keyImagesOnly: displayOnlyKeyImages];
		
//		[browserWindow findAndSelectFile: 0L image: [[[[sender selectedCell] representedObject] valueForKey:@"images"] anyObject] shouldExpand:NO];
//		[browserWindow viewerDICOMInt:NO dcmFile:[NSArray arrayWithObject: [[sender selectedCell] representedObject]] viewer:0L];
		
		[self matrixPreviewSelectCurrentSeries];
		
		// For toolbar
		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidBecomeKeyNotification object:[self window]];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
			[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
		else
			[NSApp sendAction: @selector(checkAllWindowsAreVisible:) to:0L from: self];
	}
	else
	{
		if( [[sender selectedCell] representedObject] != [[fileList[ curMovieIndex] objectAtIndex:0] valueForKey:@"series"])
		{
			[browserWindow loadSeries :[[sender selectedCell] representedObject] :self :YES keyImagesOnly: displayOnlyKeyImages];
			
//			[browserWindow findAndSelectFile: 0L image: [[[[sender selectedCell] representedObject] valueForKey:@"images"] anyObject] shouldExpand:NO];
//			[browserWindow viewerDICOMInt:NO dcmFile:[NSArray arrayWithObject: [[sender selectedCell] representedObject]] viewer:self];
		}
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

- (void) buildMatrixPreview: (BOOL) showSelected
{
	NSManagedObjectModel	*model = [browserWindow managedObjectModel];
	NSManagedObjectContext	*context = [browserWindow managedObjectContext];
	NSPredicate				*predicate;
	NSFetchRequest			*dbRequest;
	NSError					*error = 0L;
	long					i, x, index = 0;
	NSManagedObject			*curImage = [fileList[0] objectAtIndex:0];
	BOOL					StoreThumbnailsInDB = [[NSUserDefaults standardUserDefaults] boolForKey: @"StoreThumbnailsInDB"];
	
	BOOL visible = [self checkFrameSize];
	
	if( visible == NO) matrixPreviewBuilt = NO; 
	else matrixPreviewBuilt = YES;
	
	NSManagedObject			*study = [curImage valueForKeyPath:@"series.study"];
	if( study == 0L) return;
	
	// FIND ALL STUDIES of this patient
	
	predicate = [NSPredicate predicateWithFormat: @"(patientUID LIKE[cd] %@)", [study valueForKey:@"patientUID"]];  // , [study valueForKey:@"name"]
	dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: predicate];
	
	[context lock];
	error = 0L;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
	if ([studiesArray count])
	{
		NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
		NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
		[sort release];
		
		studiesArray = [studiesArray sortedArrayUsingDescriptors: sortDescriptors];
		
		NSString*		sdf = [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateFormat"];
		NSDictionary*	locale = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
		
		i = 0;
		for( x = 0; x < [studiesArray count]; x++)
		{
			NSArray				*series = [browserWindow childrenArray: [studiesArray objectAtIndex: x]];
			i += [series count];
		}
		
		if( [previewMatrix numberOfRows] != i+[studiesArray count])
		{
			[previewMatrix renewRows: i+[studiesArray count] columns: 1];
			[previewMatrix sizeToCells];
		}
		
		for( x = 0; x < [studiesArray count]; x++)
		{
			NSManagedObject		*curStudy = [studiesArray objectAtIndex: x];
			NSArray				*series = [browserWindow childrenArray: curStudy];
			NSArray				*images = [browserWindow imagesArray: curStudy preferredObject: oAny];
			
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
			
			NSString	*stateText;
			if( [[curStudy valueForKey:@"stateText"] intValue]) stateText = [[BrowserController statesArray] objectAtIndex: [[curStudy valueForKey:@"stateText"] intValue]];
			else stateText = @"";
			NSString	*comment = [curStudy valueForKey:@"comment"];
			
			if( comment == 0L) comment = @"";
			
			[cell setTitle:[NSString stringWithFormat:@"%@\r%@\r%d %@\r%@\r%@", name, [[curStudy valueForKey:@"date"] descriptionWithCalendarFormat:sdf timeZone:0L locale:locale], [series count], @"series", stateText, comment]];
			
			index++;
			
			for( i = 0; i < [series count]; i++)
			{
				NSManagedObject	*curSeries = [series objectAtIndex:i];
				
				int keyImagesNumber = 0, z;
				NSArray	*keyImagesArray = [[[curSeries valueForKey:@"images"] allObjects] valueForKey:@"isKeyImage"];
				for( z = 0; z < [keyImagesArray count]; z++)
				{
					if( [[keyImagesArray objectAtIndex: z] boolValue]) keyImagesNumber++;
				}
				
				NSButtonCell *cell = [previewMatrix cellAtRow: index column:0];
				
				[cell setBezelStyle: NSShadowlessSquareBezelStyle];
				[cell setRepresentedObject: curSeries];
				if( keyImagesNumber) [cell setFont:[NSFont boldSystemFontOfSize:9]];
				else [cell setFont:[NSFont systemFontOfSize:9]];
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
				
				if( keyImagesNumber) [cell setTitle:[NSString stringWithFormat:@"%@\r%@\r%d/%d %@", name, [[curSeries valueForKey:@"date"] descriptionWithCalendarFormat:sdf timeZone:0L locale:locale], keyImagesNumber, count, type]];
				else [cell setTitle:[NSString stringWithFormat:@"%@\r%@\r%d %@", name, [[curSeries valueForKey:@"date"] descriptionWithCalendarFormat:sdf timeZone:0L locale:locale], count, type]];
				
				[previewMatrix setToolTip:[NSString stringWithFormat:@"Series ID:%@\rClick + Option:\rOpen in new window", [curSeries valueForKey:@"id"]] forCell:cell];
				
				if( [curImage valueForKey:@"series"] == curSeries)
				{
					[previewMatrix selectCellAtRow:index column:0];
				}
				
				if( visible)
				{
					NSImage	*img = 0L;
					
					if( StoreThumbnailsInDB)
					{
						img = [[[NSImage alloc] initWithData: [[images objectAtIndex:i] valueForKeyPath:@"series.thumbnail"]] autorelease];
					}
					
					if( img == 0L)
					{
						DCMPix*     dcmPix = [[DCMPix alloc] myinit: [[images objectAtIndex: i] valueForKey:@"completePath"] :0 :0 :0L :0 :[[[images objectAtIndex: i] valueForKeyPath:@"series.id"] intValue] isBonjour:[browserWindow isCurrentDatabaseBonjour] imageObj:[images objectAtIndex: i]];
						
						if( dcmPix)
						{
							NSImage *img = [dcmPix computeWImage:YES :0 :0];
							
							if( img)
							{
								[cell setImage: img];
								
								if( StoreThumbnailsInDB)
								{
									[[[images objectAtIndex:i] valueForKey: @"series"] setValue: [img TIFFRepresentationUsingCompression: NSTIFFCompressionPackBits factor:0.5] forKey:@"thumbnail"];
								}
							}
							else [cell setImage: [NSImage imageNamed: @"FileNotFound.tif"]];
							
							[dcmPix release];
						}
						else [cell setImage: [NSImage imageNamed: @"FileNotFound.tif"]];
						
					}
					else [cell setImage: img];
				}
				
				index++;
			}
		}
	}
	
	#if !__LP64__
	int row, column;
	#else
	long row, column;
	#endif
	
	if( showSelected)
	{
		[previewMatrix getRow:&row column:&column ofCell:[previewMatrix selectedCell]];
		[previewMatrix scrollCellToVisibleAtRow: row column:0];
	}
	
	[previewMatrix setNeedsDisplay:YES];
	
	[context unlock];
}


- (void) buildMatrixPreview
{
	[self buildMatrixPreview: YES];
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

- (void) completeDragOperation:(ViewerController*) v
{
	// if we are already blending the other way we crash
	if ([[v blendingController] isEqual:self])
		return;
		
	int iz, xz;
	
	blendedwin = v;
	
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
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard	*paste = [sender draggingPasteboard];
	long			i, x, z, iz, xz;
	
	if( [[paste availableTypeFromArray: [NSArray arrayWithObject: pasteBoardOsiriX]] isEqualToString: pasteBoardOsiriX])
	{
		DCMView	*vi = [sender draggingSource];
		
		if ([[[vi window] windowController] is2DViewer] == YES)
		{
			if ([[[[vi window] windowController] blendingController] isEqual:self])
				return NO;
			if( [[vi window] windowController] != self) [self completeDragOperation: [[vi window] windowController]];
		}
	}
	else
	{
	    NSArray			*types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
		NSString		*desiredType = [paste availableTypeFromArray:types];
		NSData			*carriedData = 0L;
		
		if( desiredType) carriedData = [paste dataForType: desiredType];

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
											[self completeDragOperation: [[winList objectAtIndex:i] windowController]];
											found = YES;
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
		[browserWindow loadNextSeries:[fileList[0] objectAtIndex:0] : -1 :self :YES keyImagesOnly: displayOnlyKeyImages];
	}
	else if (c == NSRightArrowFunctionKey && ([event modifierFlags] & NSCommandKeyMask))
	{
		[browserWindow loadNextSeries:[fileList[0] objectAtIndex:0] : 1 :self :YES keyImagesOnly: displayOnlyKeyImages];
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


- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
    
    if ([itemIdent isEqualToString: QTSaveToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"Movie Export", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export this series in a Quicktime file", nil)];
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
	else  if ([itemIdent isEqualToString: PagePadToolbarItemIdentifier]) {
        
	[toolbarItem setLabel: NSLocalizedString(@"PagePad", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"PagePad", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Open a PagePad template for the current study", nil)];
	
	[toolbarItem setView: PagePad];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([PagePad frame]), NSHeight([PagePad frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([PagePad frame]), NSHeight([PagePad frame]))];
/*	
	[toolbarItem setView: subCtrlView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([subCtrlView frame]), NSHeight([subCtrlView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([subCtrlView frame]),NSHeight([subCtrlView frame]))];

	
	// By default, in text only mode, a custom items label will be shown as disabled text, but you can provide a 
	// custom menu of your own by using <item> setMenuFormRepresentation] 
	submenu = [[[NSMenu alloc] init] autorelease];
	submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel" action: @selector(searchUsingSearchPanel:) keyEquivalent: @""] autorelease];
	menuFormRep = [[[NSMenuItem alloc] init] autorelease];

	[submenu addItem: submenuItem];
	[submenuItem setTarget: self];
	[menuFormRep setSubmenu: submenu];
	[menuFormRep setTitle: [toolbarItem label]];
	[toolbarItem setMenuFormRepresentation: menuFormRep];
*/
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
	[self setToolbarReportIconForItem:toolbarItem];
	[toolbarItem setTarget: self];
	[toolbarItem setAction: @selector(generateReport:)];
//	[toolbarItem setImage: [NSImage imageNamed: ReportToolbarItemIdentifier]];
//	[toolbarItem setTarget: browserWindow];
//	[toolbarItem setAction: @selector(generateReport:)];
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
	else if([itemIdent isEqualToString: ShutterToolbarItemIdentifier])
	 {
	// Set up the standard properties 
	[toolbarItem setLabel: NSLocalizedString(@"Shutter", nil)];
	[toolbarItem setPaletteLabel: NSLocalizedString(@"Shutter", nil)];
	[toolbarItem setToolTip: NSLocalizedString(@"Shutter", nil)];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: shutterView];
	[toolbarItem setMinSize:NSMakeSize(NSWidth([shutterView frame]), NSHeight([shutterView frame]))];
	[toolbarItem setMaxSize:NSMakeSize(NSWidth([shutterView frame]), NSHeight([shutterView frame]))];
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
										OrientationToolbarItemIdentifier,
										FusionToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										QTSaveToolbarItemIdentifier,
										SyncSeriesToolbarItemIdentifier,
										PlayToolbarItemIdentifier,
										SpeedToolbarItemIdentifier,
										VRPanelToolbarItemIdentifier,
										PrintToolbarItemIdentifier,
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
														PrintToolbarItemIdentifier,
														ExportToolbarItemIdentifier,
														iPhotoToolbarItemIdentifier,
														PagePadToolbarItemIdentifier,
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
														ShutterToolbarItemIdentifier,
														OrientationToolbarItemIdentifier,
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
		#if defined (MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
			enable = YES;
		#else
		if( [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Quicktime/OsiriX Broadcasting.component"] == NO)
		{
			enable = NO;
		}
		#endif
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
	
	switch( tag)
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
			[self setROIToolTag: tag];
		break;
		
		default:
			[toolsMatrix selectCellWithTag: tag];
		break;
	}
	
	if( tag >= 0)
	{
		[imageView setCurrentTool: tag];
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

//added by Jacques Fauquex 2006-09-30
- (IBAction) shutterOnOff:(id) sender
{
	if ([[sender title] isEqualToString:@"Shutter"] == YES) [shutterOnOff setState: (![shutterOnOff state])];//from menu
	long i;
	
	NSRect shutterRect;
	shutterRect.origin.x = 0;
	shutterRect.origin.y = 0;
	shutterRect.size.width = 0;
	shutterRect.size.height = 0;

	if ([shutterOnOff state] == NSOnState)
	{
		// Find the first ROI selected for the current frame and copy the rectangle in shutterRect
		
		long ii = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] count];
		for( i = 0; i < ii; i++)
		{
			long mode = [[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i] ROImode];				
			if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
			{
				ROI *selectedROI = [[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] objectAtIndex: i];
				//check if selectedROI bounds remain within image bounds
				shutterRect = [selectedROI rect];
				[[roiList[curMovieIndex] objectAtIndex: [imageView curImage]] removeObject:selectedROI];
				i = ii;
			}
		}
		
		//shutterRect inside frame?
		//NSLog(@"x:%f, y:%f, w:%f, h:%f",shutterRect.origin.x,shutterRect.origin.y,shutterRect.size.width,shutterRect.size.height);
		float DCMPixWidth = [[[imageView dcmPixList] objectAtIndex:[imageView curImage]] pwidth];
		float DCMPixHeight = [[[imageView dcmPixList] objectAtIndex:[imageView curImage]] pheight];
		//NSLog(@"DCMPix w:%f",DCMPixWidth);
		//NSLog(@"DCMPix h:%f",DCMPixHeight);		
		if (shutterRect.origin.x < 0) shutterRect.origin.x = 0;
		if (shutterRect.origin.y < 0) shutterRect.origin.y = 0;
		if (shutterRect.origin.x + shutterRect.size.width > DCMPixWidth) shutterRect.size.width = DCMPixWidth - shutterRect.origin.x;
		if (shutterRect.origin.y + shutterRect.size.height > DCMPixHeight) shutterRect.size.height = DCMPixHeight - shutterRect.origin.y;
		
		//using valid shutterRect
		if (shutterRect.size.width != 0)
		{
			for( i = 0; i < [[imageView dcmPixList] count]; i++)
			{
				[[[imageView dcmPixList] objectAtIndex: i] DCMPixShutterRect:(long)shutterRect.origin.x :(long)shutterRect.origin.y :(long)shutterRect.size.width :(long)shutterRect.size.height];
				[[[imageView dcmPixList] objectAtIndex: i] DCMPixShutterOnOff: NSOnState];
			}
			[imageView scaleBy2AndCenterShutter];
		}
		else
		{
			//using stored shutterRect?
			if  ([[[imageView dcmPixList] objectAtIndex:[imageView curImage]] DCMPixShutterRectWidth] == 0)
			{
				//NSLog(@"no shutter rectangle available");
				[shutterOnOff setState:NSOffState];
				
				NSRunCriticalAlertPanel(NSLocalizedString(@"Shutter", nil), NSLocalizedString(@"Please first define a rectangle with a rectangular ROI.", nil), NSLocalizedString(@"OK", nil), nil, nil);
			}
			else //reuse preconfigured shutterRect
			{
				for( i = 0; i < [[imageView dcmPixList] count]; i++) [[[imageView dcmPixList] objectAtIndex: i] DCMPixShutterOnOff: NSOnState];
				[imageView scaleBy2AndCenterShutter];	
			}
		}
	}
	else
	{
		for( i = 0; i < [[imageView dcmPixList] count]; i++) [[[imageView dcmPixList] objectAtIndex: i] DCMPixShutterOnOff: NSOffState];
		[imageView setOrigin: NSMakePoint( 0, 0)];
		[imageView scaleToFit];
	}
	[imageView setIndex: [imageView curImage]]; //refresh viewer only
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
	
	[imageView setDrawing: NO];
	
	processorsLock = [[NSConditionLock alloc] initWithCondition: 1];
	
	[self setPixelList:f fileList:d volumeData:v];
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
	   selector: @selector(updateImageView:)
		   name: @"DCMUpdateCurrentImage"
		 object: nil];
	
	[seriesView setDCM:pixList[0] :fileList[0] :roiList[0] :0 :'i' :YES];	//[pixList[0] count]/2
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTLEFTTOOL"]], @"toolIndex", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
	
	displayOnlyKeyImages = NO;
		
#if defined (MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
#if !__LP64__
	[[IMService notificationCenter] addObserver:self selector:@selector(_stateChanged:)
                                           name:IMAVManagerStateChangedNotification object:nil];
	[[IMAVManager sharedAVManager] setVideoDataSource:imageView];
#endif
#endif
	
	[imageView setDrawing: YES];
	
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
	NSString	*previousStudyInstanceUID = [[[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] retain];
	float		previousOrientation[ 9];
	float		previousLocation = 0;
		
	[[pixList[ 0] objectAtIndex:0] orientation: previousOrientation];
	previousLocation = [[imageView curDCM] sliceLocation];
	
	[self setFusionMode: 0];
	[imageView setIndex: 0];
	
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
	[imageView setDrawing: NO];
	
	if( currentOrientationTool != originalOrientation)
	{
		[imageView setXFlipped: NO];
		[imageView setYFlipped: NO];
		[imageView setRotation: 0];
	}
	
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
	
	if( thickSlab)
	{
		[thickSlab release];
		thickSlab = 0L;
	}
	
//	NSString *tempDirectory = [documentsDirectory() stringByAppendingString:@"/TEMP/"];
//	if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) [[NSFileManager defaultManager] removeFileAtPath:tempDirectory handler: 0L];
//	[[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory attributes:nil];
	
	[orientationMatrix selectCellWithTag: 0];
	
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	curConvMenu = [NSLocalizedString(@"No Filter", nil) retain];
	curWLWWMenu = [NSLocalizedString(@"Default WL & WW", nil) retain];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	// Load new data (JF: previously curMovieIndex=0 maxMovieIndex=1  subCtrlMaskID=-1)
	curMovieIndex = 0;
	maxMovieIndex = 1;
	subCtrlMaskID = -2;
	
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
	
	[subCtrlOnOff setState: NSOffState];
	[popFusion selectItemAtIndex:0];
	[convPopup selectItemAtIndex:0];
	[stacksFusion setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"stackThickness"]];
	[sliderFusion setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"stackThickness"]];
	[sliderFusion setEnabled:NO];

	[movieRateSlider setEnabled: NO];
	[moviePosSlider setEnabled: NO];
	[moviePlayStop setEnabled:NO];
	
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
	
	if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
	{
		if( [[self modality] isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"] == YES))
		{
			if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
				[self ApplyCLUTString: @"B/W Inverse"];
			else
				[self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
		}
		else [self ApplyCLUTString:NSLocalizedString(@"No CLUT", nil)];
	}
	else [self ApplyCLUTString:NSLocalizedString(@"No CLUT", nil)];
	
	NSNumber	*status = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.study.stateText"];
	
	if( status == 0L) [StatusPopup selectItemWithTitle: NSLocalizedString(@"empty", nil)];
	else [StatusPopup selectItemWithTag: [status intValue]];
	
	NSString	*com = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.comment"];//JF20070103
	
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
//		[self matrixPreviewSelectCurrentSeries];
	}
	
	// If same study, same patient and same orientation, try to go the same position (mm) if available
	if( [previousStudyInstanceUID isEqualToString: [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
	{
		float	currentOrientation[ 9];
		BOOL	equalVector = YES;
		
		[[pixList[ 0] objectAtIndex:0] orientation: currentOrientation];
		
		for( i = 0; i < 9; i++)
		{
			if( previousOrientation[ i] != currentOrientation[ i]) equalVector = NO;
		}
		
		if( equalVector)
		{
			float start = [[[fileList[ 0] objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue];
			float end = [[[fileList[ 0] objectAtIndex: [fileList[ 0] count]-1] valueForKey:@"sliceLocation"] floatValue];
			
			if( start > end)
			{
				float temp = end;
				
				end = start;
				start = temp;
			}
			
			if( previousLocation > start && previousLocation < end)
			{
				long	index = 0, i;
				float   smallestdiff = -1, fdiff;
				
				for( i = 0; i < [fileList[ 0] count]; i++)
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
					[imageView setIndex: index];
					[self adjustSlider];
				}
			}
		}
	}
	//If study ID changed, cancel the fusion, if existing
	else
	{
		if( blendingController) [self ActivateBlending: 0L];
	}
	
	[previousStudyInstanceUID release];
	[previousPatientUID release];
	
	// Is it only key images?
	NSArray	*images = fileList[ 0];
	BOOL onlyKeyImages = YES;	
	
	for( i = 0; i < [images count]; i++)
	{
		NSManagedObject	*image = [images objectAtIndex: i];
		if( [[image valueForKey:@"isKeyImage"] boolValue] == NO) onlyKeyImages = NO;
	}
	
	displayOnlyKeyImages = onlyKeyImages; 
	[keyImagePopUpButton selectItemAtIndex:displayOnlyKeyImages];
	
	/*
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
	*/
	[imageView becomeMainWindow];	// This will send the image sync order !
	
	windowWillClose = NO;
	
	[imageView setDrawing: YES];
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

- (void) enableSubtraction
{
	if( enableSubtraction)
	{
		subCtrlMaskID = 1;
		[subCtrlMaskText setStringValue: [NSString stringWithFormat:@"2"]];//changes tool text
		
		//define min and max value of the subtraction
		long subCtrlMin = 1024;
		long subCtrlMax = 0;
		long i;
		for ( i = 0; i < [[imageView dcmPixList] count]; i ++)
				{
					subCtrlMinMax = [[[imageView dcmPixList]objectAtIndex:i]   subMinMax:[[[imageView dcmPixList]objectAtIndex:i]fImage]
																						:[[[imageView dcmPixList]objectAtIndex:subCtrlMaskID]fImage]
									];
					if (subCtrlMinMax.x < subCtrlMin) subCtrlMin = subCtrlMinMax.x ;
					if (subCtrlMinMax.y > subCtrlMax) subCtrlMax = subCtrlMinMax.y ;
				}
		subCtrlMinMax.x = subCtrlMin;
		subCtrlMinMax.y = subCtrlMax;
		
		// By default, the tool should not be activated.
		
		[self checkView: subCtrlView :YES];
	}
	else [self checkView: subCtrlView :NO];
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

-(void) setDefaultPETWLWW:(id) sender
{
	[imageView updatePresentationStateFromSeries];
	[imageView setIndex: [imageView curImage]];
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
	
	for( x = 0; x < maxMovieIndex; x++)
	{
		for( i = 0 ; i < [pixList[ x] count]; i++)
		{
			if( stopThreadLoadImage == NO) //there is no interrruption
			{
				if ([fileList[ x] count] == [pixList[ x] count]) // I'm not quite sure what this line does, but I'm afraid to take it out. 
					[browserWindow getLocalDCMPath:[fileList[ x] objectAtIndex: i] : 2]; // Anyway, we are not guarantied to have as many files as pixs, so that is why I put in the if() - Joel
				else
					[browserWindow getLocalDCMPath:[fileList[ x] objectAtIndex: 0] : 2]; 
				
				
				DCMPix* pix = [pixList[ x] objectAtIndex: i];
				
//				[self waitForAProcessor];
//				[NSThread detachNewThreadSelector: @selector( loadThread:) toTarget:self withObject:  pix];
				
				[pix CheckLoad];
			}
			
			loadingPercentage = (float) ((x*[pixList[ x] count]) + i) / (float) (maxMovieIndex * [pixList[ x] count]);
			
			while(loadingPause)
			{
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
			}
		}
	}
	
//	BOOL finished = NO;
//	do
//	{
//		[processorsLock lockWhenCondition: 1];
//		if( numberOfThreadsForRelisce <= 0)
//		{
//			finished = YES;
//			[processorsLock unlockWithCondition: 1];
//		}
//		else [processorsLock unlockWithCondition: 0];
//	}
//	while( finished == NO);
	
	if( stopThreadLoadImage == NO)	 
	{	
		float maxValueOfSeries = -100000;
		float minValueOfSeries = 100000;

		for( x = 0; x < maxMovieIndex; x++)	 
		{	 
			for( i = 0 ; i < [pixList[ x] count]; i++)	 
			{
				DCMPix* pix = [pixList[ x] objectAtIndex: i];
				
				if( maxValueOfSeries < [pix fullwl] + [pix fullww]/2) maxValueOfSeries = [pix fullwl] + [pix fullww]/2;
				if( minValueOfSeries > [pix fullwl] - [pix fullww]/2) minValueOfSeries = [pix fullwl] - [pix fullww]/2;
			}
		}
		
		for( x = 0; x < maxMovieIndex; x++)	 
		{	 
			for( i = 0 ; i < [pixList[ x] count]; i++)	 
			{
				[[pixList[ x] objectAtIndex: i] setMaxValueOfSeries: maxValueOfSeries];
				[[pixList[ x] objectAtIndex: i] setMinValueOfSeries: minValueOfSeries];
			}
		 }	 
	}
	
	if( stopThreadLoadImage == YES)
	{
		ThreadLoadImage = NO;
		[pool release];
		[ThreadLoadImageLock unlock];
		return;
	}
	
	[ThreadLoadImageLock unlock];

#pragma mark modality dependant code, once images are already displayed in 2D viewer
	if( stopThreadLoadImage == NO)
	{
#pragma mark XA
		enableSubtraction = FALSE;
		if([[[fileList[ 0] objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"XA"] == YES)
		{
			NSLog(@"XA");
			long runSize = [pixList[ 0] count];
			if(runSize > 1)
			{
				long moviePixWidth = [[pixList[ 0] objectAtIndex: 0] pwidth];
				long moviePixHeight = [[pixList[ 0] objectAtIndex: 0] pheight];

				if (moviePixWidth == moviePixHeight) enableSubtraction = TRUE;

				long j;
				for( j = 0 ; j < runSize; j++)
				{
					if ( moviePixWidth != [[pixList[0] objectAtIndex: j] pwidth]) enableSubtraction = FALSE;
					if ( moviePixHeight != [[pixList[0] objectAtIndex: j] pheight]) enableSubtraction = FALSE;
				}
			}
		}
		
		// You CANNOT call ANY GUI functions if you are NOT in the MAIN thread !!!!!!!!!!!!!!!!!!
		[self performSelectorOnMainThread:@selector( enableSubtraction) withObject:nil waitUntilDone: YES];
		
#pragma mark PET	

		if( isPET)
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"ConvertPETtoSUVautomatically"])
			{
				[self performSelectorOnMainThread:@selector( convertPETtoSUV) withObject:nil waitUntilDone: YES];
				
				[imageView performSelectorOnMainThread:@selector( setStartWLWW) withObject:0L waitUntilDone: YES];
			}
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DEFAULTPETWLWW"] != 0)
			{
				[self performSelectorOnMainThread:@selector( setDefaultPETWLWW:) withObject:self waitUntilDone: YES];
			}
		}
	}
	
	NSLog(@"LOADING: All images loaded");
	
	
	loadingPercentage = 1;
	
	if( stopThreadLoadImage == NO)
	{
		[self performSelectorOnMainThread:@selector( computeIntervalFlipNow:) withObject:[NSNumber numberWithBool: NO] waitUntilDone: YES];
		[self performSelectorOnMainThread:@selector( setWindowTitle:) withObject:self waitUntilDone: YES];
		
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
	
	ThreadLoadImage = NO;
	
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
	
	[self computeInterval];
	[self checkEverythingLoaded];
	[imageView stopROIEditingForce: YES];
	
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

#pragma mark resample image

- (IBAction)resampleDataBy2:(id)sender;
{
	id waitWindow = [self startWaitWindow:@"Resampling data..."];
	BOOL isResampled = [self resampleDataBy2];
	[self endWaitWindow: waitWindow];
	if(!isResampled)
	{
		NSRunAlertPanel(NSLocalizedString(@"Not enough memory", nil), NSLocalizedString(@"Your computer doesn't have enough RAM to complete the resampling", nil), NSLocalizedString(@"OK", nil), nil, nil);
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
	
	NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
	NSMutableArray *newDcmList = [NSMutableArray arrayWithCapacity:0];
	NSData *newData = 0L;
	BOOL wasDataFlipped = [imageView flippedData];
	int index = [imageView curImage];
	
	BOOL isResampled = [ViewerController resampleDataFromViewer:self inPixArray:newPixList fileArray:newDcmList data:&newData withXFactor:xFactor yFactor:yFactor zFactor:zFactor];
	if(isResampled)
	{
		[self changeImageData:newPixList :newDcmList :newData :NO];
		loadingPercentage = 1;
		[self computeInterval];
		[self setWindowTitle:self];
		
		if( wasDataFlipped) [self flipDataSeries: self];
		
		[imageView setIndex: index];
		[imageView sendSyncMessage:1];
		
		[self adjustSlider];
	}
	return isResampled;
}

+ (BOOL)resampleDataFromViewer:(ViewerController *)aViewer inPixArray:(NSMutableArray*)aPixList fileArray:(NSMutableArray*)aFileList data:(NSData**)aData withXFactor:(float)xFactor yFactor:(float)yFactor zFactor:(float)zFactor;
{
	[aViewer setPostprocessed: YES];
	
	BOOL result =  [ViewerController resampleDataFromPixArray:[aViewer pixList] fileArray:[aViewer fileList] inPixArray:aPixList fileArray:aFileList data:aData withXFactor:xFactor yFactor:yFactor zFactor:zFactor];
	
	return result;
}

+ (BOOL)resampleDataFromPixArray:(NSArray *)originalPixlist fileArray:(NSArray*)originalFileList inPixArray:(NSMutableArray*)aPixList fileArray:(NSMutableArray*)aFileList data:(NSData**)aData withXFactor:(float)xFactor yFactor:(float)yFactor zFactor:(float)zFactor;
{
	long				i, y, z, imageSize, newX, newY, newZ, size;
	float				*srcImage, *dstImage, *emptyData;
	DCMPix				*curPix;
	
	int originWidth = [[originalPixlist objectAtIndex:0] pwidth];
	int originHeight = [[originalPixlist objectAtIndex:0] pheight];
	int originZ = [originalPixlist count];
		
	newX = (int)((float)originWidth / xFactor + 0.5);
	newY = (int)((float)originHeight / yFactor + 0.5);
	newZ = (int)((float)originZ / zFactor + 0.5);
	
	if( newZ <= 0) newZ = 1;
	if( originZ == 1) newZ = 1;
	
	int maxZ = originZ;
	if( maxZ < newZ) maxZ = newZ;
	
	imageSize = newX * newY;
	size = sizeof(float) * maxZ * imageSize;
	
	emptyData = malloc( size);
	if( emptyData)
	{
		float vectors[ 9], vectorsB[ 9], interval = 0, origin[ 3], newOrigin[ 3];
		BOOL equalVector = YES;
		int o;
		
		if( [originalPixlist count] > 1)
		{
			DCMPix	*firstObject = [originalPixlist objectAtIndex:0];
			DCMPix	*secondObject = [originalPixlist objectAtIndex:1];
			DCMPix	*lastObject = [originalPixlist lastObject];
			
			[firstObject orientation: vectors];
			[secondObject orientation: vectorsB];
			
//			if( [firstObject fImage] != [*aData bytes])
//			{
//				NSLog(@"flipped Data in resampleDataFromPixArray");
//				
//				if( [lastObject fImage] != [*aData bytes]) NSLog( @"uh?");
//				
//				origin[ 0] = [lastObject originX]; 
//				origin[ 1] = [lastObject originY]; 
//				origin[ 2] = [lastObject originZ]; 
//			}
//			else
			{
				origin[ 0] = [firstObject originX]; 
				origin[ 1] = [firstObject originY]; 
				origin[ 2] = [firstObject originZ]; 
			}
			
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
		
		NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
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
					[copyPix setSliceLocation: newOrigin[ 0]];
					break;
					
				case 1:
					newOrigin[ 1] = origin[ 1] + (float) z * interval;
					[copyPix setSliceLocation: newOrigin[ 1]];
					break;
					
				case 2:
					newOrigin[ 2] = origin[ 2] + (float) z * interval;
					[copyPix setSliceLocation: newOrigin[ 2]];
					break;
			}
			[copyPix setOrigin: newOrigin];
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
					vImageScale_ARGB8888( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
				else
					vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
			}
		}
		else
		{
			memcpy( emptyData, [[originalPixlist objectAtIndex: 0] fImage], originHeight * originWidth * 4 * originZ);
		}
		
		// Z RESAMPLING
		
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
					vImageScale_ARGB8888( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
				else
					vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
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
	else
	{
		return NO;
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

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
		if( [sender tag] == 0 ) [subCtrlOnOff setState: ![subCtrlOnOff state]]; //"on"

		long i;	
		
		if([subCtrlOnOff state])			// subtraction asked for
			{	
				for ( i = 0; i < [[imageView dcmPixList] count]; i ++)
				{
					[[[imageView dcmPixList]objectAtIndex:i]	setSubtractedfImage:[[[imageView dcmPixList]objectAtIndex:subCtrlMaskID]fImage] :subCtrlMinMax];
				}
			}	
				
		else //without subtraction
			{				
			for ( i = 0; i < [[imageView dcmPixList] count]; i ++)
				{
					[[[imageView dcmPixList] objectAtIndex:i]	setSubtractedfImage:0L :subCtrlMinMax];
				}
			}
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
		if( [imageView flippedData]) subCtrlMaskID = [pixList[ curMovieIndex] count] - [imageView curImage] -1;
		else                         subCtrlMaskID = [imageView curImage];//starts at 1;
		
		[subCtrlMaskText setStringValue: [NSString stringWithFormat:@"%d", (subCtrlMaskID+1)]];//changes tool text
		
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
	if(enableSubtraction)
	{
		if ([subCtrlOnOff state] == NSOnState) //only when in subtraction mode
		{
		subCtrlOffset = [  [[imageView dcmPixList] objectAtIndex:[imageView curImage]]  subPixOffset];
		NSLog(@"subPixOffset before x:%f y:%f", subCtrlOffset.x, subCtrlOffset.y);
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
				//NSLog(@"subCtrlOffset x:%f :y:%f",subCtrlOffset.x, subCtrlOffset.y);
		}

	if ((subCtrlOffset.x > -30) && (subCtrlOffset.x < 30) && (subCtrlOffset.y > -30) && (subCtrlOffset.y < 30))
		{
		//write changes in dcmPixList
		long i;	
		for ( i = 0; i < [[imageView dcmPixList] count]; i ++) [[[imageView dcmPixList] objectAtIndex:i] setSubPixOffset: subCtrlOffset];
		//refresh tool
		[self offsetMatrixSetting:([self threeTestsFivePosibilities: (int)subCtrlOffset.y] * 5) + [self threeTestsFivePosibilities: (int)subCtrlOffset.x]];		
		//refresh window image
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
	if(enableSubtraction)
	{
		if ([subCtrlOnOff state] == NSOnState) //only when in subtraction mode
		{
			switch([sender tag]) //menu shortcut
			{
				case 37: [subCtrlGamma setFloatValue:[subCtrlGamma floatValue]-0.5];	break;  //Ctr - (min 0.5)
				case 38: [subCtrlGamma setFloatValue:2];								break;
				case 39: [subCtrlGamma setFloatValue:[subCtrlGamma floatValue]+0.5];	break;  //Ctr + (max 6.0)
				case 34: [subCtrlZero setFloatValue:[subCtrlZero floatValue]-0.05];		break;  //Bri - (min 0.6)
				case 35: [subCtrlZero setFloatValue:0.8];								break;
				case 36: [subCtrlZero setFloatValue:[subCtrlZero floatValue]+0.05] ;	break;  //Bri + (max 1.2)
			}
			long i;				
			for ( i = 0; i < [[imageView dcmPixList] count]; i ++)
				{
				[[[imageView dcmPixList] objectAtIndex:i]
														setSubSlidersPercent:	[subCtrlPercent floatValue]
														gamma:					[subCtrlGamma floatValue] 
														zero:					[subCtrlZero floatValue]
				];
				}
				NSLog(@"percent:%f   gamma:%f  zero:%f",[subCtrlPercent floatValue],[subCtrlGamma floatValue],[subCtrlZero floatValue]);
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
	long x, i;
	
	[imageView setFusion:-1 :[subCtrlSum intValue]];
	
	for ( x = 0; x < maxMovieIndex; x++)
	{
		if( x != curMovieIndex) // [imageView setFusion] already did it for current serie!
		{
			for ( i = 0; i < [pixList[ x] count]; i ++)
			{
				[[pixList[ x] objectAtIndex:i] setFusion:-1 :[subCtrlSum intValue] :-1];
			}
		}
	}
	
	[stacksFusion setIntValue:[subCtrlSum intValue]];
	
	[[NSUserDefaults standardUserDefaults] setInteger:[subCtrlSum intValue] forKey:@"stackThickness"];
	
	[imageView sendSyncMessage:1];

}

- (IBAction) subSharpen:(id) sender
{
	if ([sender tag] == 30) [subCtrlSharpenButton  setState: ![subCtrlSharpenButton state]];
	if ([subCtrlSharpenButton state] == NSOnState)	[self ApplyConvString:@"5x5 sharpen"];
	else								[self ApplyConvString:NSLocalizedString(@"No Filter", nil)];
}

#pragma mark-
#pragma mark 4.1.1.3. VOI LUT transformation

- (void) setCurWLWWMenu:(NSString*) s
{
	if( s != curWLWWMenu)
	{
		[curWLWWMenu release];
		curWLWWMenu = [s retain];
	}
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

- (void) flipData:(char*) ptr :(long) no :(long) x :(long) y
{
	long	i, size = x*y;
	char*	tempData;
	
//	NSLog(@"flip data-A");
//	
//	size *= 4;
//	tempData = (char*) malloc( size);
//	for( i = 0; i < no/2; i++)
//	{
//		BlockMoveData( ptr + size*i, tempData, size);
//		BlockMoveData( ptr + size*(no-1-i), ptr + size*i, size);
//		BlockMoveData( tempData, ptr + size*(no-1-i), size);
//	}
//	free( tempData);
//	
//	NSLog(@"flip data-B");
	
// The vImage version seems about 20% faster on my Core Duo processor.. maybe even faster on dual-dual-Xeon?
	
	vImage_Buffer src, dest;
	src.height = dest.height = no;
	src.width = dest.width = x*y;
	src.rowBytes = dest.rowBytes = x*y*4;
	src.data = dest.data = ptr;
	vImageVerticalReflect_PlanarF ( &src, &dest, 0L);
	
//	NSLog(@"flip data-C");
}

- (IBAction) flipDataSeries: (id) sender
{
	int previousFusion = [popFusion selectedTag];
	[self setFusionMode: 0];
	[popFusion selectItemAtIndex:0];
	
	[imageView setFlippedData: ![imageView flippedData]];
	[imageView setIndex: [pixList[ 0] count] -1 -[imageView curImage]];
	
	[self adjustSlider];
	
	[imageView sendSyncMessage:1];
	
	[self setFusionMode: previousFusion];
	[popFusion selectItemWithTag:previousFusion];
}

- (short) orthogonalOrientation
{
	float		vectors[ 9];
	
	[[pixList[ curMovieIndex] objectAtIndex:0] orientation: vectors];
	
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

-(float) computeIntervalFlipNow: (NSNumber*) flipNowNumber
{
	float				interval = [[pixList[ curMovieIndex] objectAtIndex:0] sliceInterval];
	
	long				i, x;
	BOOL				flipNow = [flipNowNumber boolValue];
	
	if( interval < 0 && [pixList[ curMovieIndex] count] > 1)
	{
		if( flipNow)
		{
			interval = 0;
		}
	}
	
	if( interval == 0 && [pixList[ curMovieIndex] count] > 1)
	{
		[orientationMatrix setEnabled: NO];
		
		float		vectors[ 9], vectorsB[ 9];
		BOOL		equalVector = YES;
		
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
				NSLog(@"Sagittal");
				interval = [[pixList[ curMovieIndex] objectAtIndex:0] originX] - [[pixList[ curMovieIndex] objectAtIndex:1] originX];
				
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
				NSLog(@"Coronal");
				interval = [[pixList[ curMovieIndex] objectAtIndex:0] originY] - [[pixList[ curMovieIndex] objectAtIndex:1] originY];
				
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
				NSLog(@"Axial");
				interval = [[pixList[ curMovieIndex] objectAtIndex:0] originZ] - [[pixList[ curMovieIndex] objectAtIndex:1] originZ];
				
				if( vectors[8] > 0) interval = -( interval);
				else interval = ( interval);
				
				if( vectors[8] > 0) orientationVector = eAxialPos;
				else orientationVector = eAxialNeg;
				
				[orientationMatrix selectCellWithTag: 0];
				if( interval != 0) [orientationMatrix setEnabled: YES];
				currentOrientationTool = 0;
			}
			
			NSLog( @"Orientation Vector: %d", orientationVector);
			NSLog( @"Interval: %2.2f", interval);
			
			// FLIP DATA !!!!!! FOR 3D TEXTURE MAPPING !!!!!
			if( interval < 0 && flipNow == YES)
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
						
						[self flipData: (char*) volumeDataPtr :[pixList[ x] count] :[firstObject pwidth] :[firstObject pheight]];
						
						for(  i = 0 ; i < [pixList[ x] count]; i++)
						{
							long offset = ([pixList[ x] count]-1-i)*[firstObject pheight] * [firstObject pwidth];
							
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
					
					subCtrlMaskID = [pixList[ curMovieIndex] count] - subCtrlMaskID -1;
					
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
		}
	}
	else if( interval == 0) [orientationMatrix setEnabled: NO];
	
	[blendingController computeInterval];
	
	return interval;
}

-(float) computeInterval
{
	return [self computeIntervalFlipNow: [NSNumber numberWithBool: YES]];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo;
{
	if( returnCode == 1)
	{
		switch( [contextInfo tag])
		{
			case 1: [self MPR2DViewer:contextInfo];		break;  //2DMPR
//			case 2: [self MPRViewer:contextInfo];		break;  //3DMPR
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
			BOOL	equalVector = YES;
			int		dir = 2;
			float	vectors[ 9], vectorsB[ 9];
			
			if( [pixList[ i] count] > 1)
			{
				[[pixList[ i] objectAtIndex:0] orientation: vectors];
				[[pixList[ i] objectAtIndex:1] orientation: vectorsB];
				
				for( x = 0; x < 9; x++)
				{
					if( vectors[ x] != vectorsB[ x]) equalVector = NO;
				}
			
				if( equalVector)
				{
					if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8])) dir = 0;
					if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8])) dir = 1;
					if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7])) dir = 2;
				}
			}
			
			for( x = 0; x < [pixList[ i] count]; x++)
			{
				DCMPix	*pix = 0L;
				
				pix = [pixList[ i] objectAtIndex:x];
				
				[pix setSliceInterval: 0];
				[pix setPixelSpacingX: fabs([customXSpacing floatValue])];
				[pix setPixelSpacingY: fabs([customYSpacing floatValue])];
				if( fabs([customXSpacing floatValue]) != 0 && fabs([customYSpacing floatValue]) != 0) [pix setPixelRatio: fabs([customYSpacing floatValue]) / fabs([customXSpacing floatValue])];
				[pix setOrientation: v];
				[pix setOrigin: o];
				
				switch( dir)
				{
					case 0:	[pix setSliceLocation: o[ 0]];	o[ 0] += [customInterval floatValue];	break;
					case 1:	[pix setSliceLocation: o[ 1]];	o[ 1] += [customInterval floatValue];	break;
					case 2: [pix setSliceLocation: o[ 2]];	o[ 2] += [customInterval floatValue];	break;
				}
			}
		}
		
		[imageView setIndex: [imageView curImage]];
		
		[self computeInterval];
    }
	
    [NSApp endSheet:ThickIntervalWindow returnCode:[sender tag]];
}

- (void) SetThicknessInterval:(id) sender
{
	float v[ 9], o[ 3];
	long i;
	
    [customInterval setFloatValue: [[pixList[ curMovieIndex] objectAtIndex:0] sliceInterval]];
	[customXSpacing setFloatValue: [[pixList[ curMovieIndex] objectAtIndex:0] pixelSpacingX]];
	[customYSpacing setFloatValue: [[pixList[ curMovieIndex] objectAtIndex:0] pixelSpacingY]];
	
	[[pixList[ curMovieIndex] objectAtIndex:0] orientation: v];
	for( i = 0; i < 6; i++) [[customVectors cellWithTag: i] setFloatValue: v[ i]];
	
	o[ 0] = [[pixList[ curMovieIndex] objectAtIndex:0] originX];
	o[ 1] = [[pixList[ curMovieIndex] objectAtIndex:0] originY];
	o[ 2] = [[pixList[ curMovieIndex] objectAtIndex:0] originZ];
	for( i = 0; i < 3; i++) [[customOrigin cellWithTag: i] setFloatValue: o[ i]];
    
	[NSApp beginSheet: ThickIntervalWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:(void*) sender];
}

- (void)deleteWLWW:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if( returnCode == 1)
    {
		NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"] mutableCopy] autorelease];
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
	
	if( curWLWWMenu != [sender title])
	{
		[curWLWWMenu release];
		curWLWWMenu = [[sender title] retain];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: curWLWWMenu userInfo: 0L];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMUpdateCurrentImage" object: imageView userInfo: userInfo];
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

#pragma mark convolution

- (IBAction) applyConvolutionOnSource:(id) sender
{
	int x, i;
	
	if( [curConvMenu isEqualToString:NSLocalizedString(@"No Filter", nil)] == NO)
	{
		for ( x = 0; x < maxMovieIndex; x++)
		{
			for ( i = 0; i < [pixList[ x] count]; i ++)
			{
				[[pixList[ x] objectAtIndex:i] applyConvolutionOnSourceImage];
			}
		}
	
		[self ApplyConvString:NSLocalizedString(@"No Filter", nil)];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ curMovieIndex] userInfo: 0L];
	}
	else NSRunAlertPanel(NSLocalizedString(@"Convolution", nil), NSLocalizedString(@"First, apply a convolution filter...", nil), nil, nil, nil);
}

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
		NSMutableDictionary		*convDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"Convolution"] mutableCopy] autorelease];

		[convDict removeObjectForKey: (id) contextInfo];
		[[NSUserDefaults standardUserDefaults] setObject: convDict forKey: @"Convolution"];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
    }
}

- (void) setConv:(short*) m :(short) s :(short) norm
{
	long			x, i;
	BOOL			convolution;
	short			kernelsize, normalization;
	short			kernel[ 25];
	
	kernelsize = s;
	normalization = norm;
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
	if( [str isEqualToString:NSLocalizedString(@"No Filter", nil)] == YES)
	{
		[self setConv:0L :0: 0];
		[imageView setIndex:[imageView curImage]];
		
		if( str != curConvMenu)
		{
			[curConvMenu release];
			curConvMenu = [str retain];
		}
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
		
		[self setConv:matrix :size: nomalization];
		[imageView setIndex:[imageView curImage]];
		if( str != curConvMenu)
		{
			[curConvMenu release];
			curConvMenu = [str retain];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
	}
	
	[[[convPopup menu] itemAtIndex:0] setTitle: str];
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
		short					matrix[25];
		
		[aConvFilter setObject:[NSNumber numberWithLong:[[sizeMatrix selectedCell] tag]] forKey: @"Size"];
		[aConvFilter setObject:[NSNumber numberWithLong:[matrixNorm intValue]] forKey: @"Normalization"];
		
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
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];
    }

    [addConvWindow orderOut:sender];
    [NSApp endSheet:addConvWindow returnCode:[sender tag]];
	
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
	
	[self setConv:matrix :[[sizeMatrix selectedCell] tag] :[matrixNorm intValue]];
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
		NSMutableDictionary *clutDict	= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy] autorelease];
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
		
		if( str != curCLUTMenu)
		{
			[curCLUTMenu release];
			curCLUTMenu = [str retain];
		}
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
			if( str != curCLUTMenu)
			{
				[curCLUTMenu release];
				curCLUTMenu = [str retain];
			}
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
		NSMutableDictionary *clutDict		= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy] autorelease];
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
		
		if( curOpacityMenu != str)
		{
			[curOpacityMenu release];
			curOpacityMenu = [str retain];
		}
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
			if( curOpacityMenu != str)
			{
				[curOpacityMenu release];
				curOpacityMenu = [str retain];
			}
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
		NSMutableDictionary		*opacityDict	= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] mutableCopy] autorelease];
		NSMutableDictionary		*aOpacityFilter	= [NSMutableDictionary dictionary];
		NSArray					*points;
		long					i;
		
		[aOpacityFilter setObject: [[[OpacityView getPoints] copy] autorelease] forKey: @"Points"];
		[opacityDict setObject: aOpacityFilter forKey: [OpacityName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: opacityDict forKey: @"OPACITY"];
		
		// Apply it!
		
		if( curOpacityMenu != [OpacityName stringValue])
		{
			[curOpacityMenu release];
			curOpacityMenu = [[OpacityName stringValue] retain];
        }
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
		[sliderFusion setEnabled:NO];
	}
	else
	{
		[sliderFusion setEnabled:YES];
	}
	
	[imageView sendSyncMessage:1];
	
	float   iwl, iww;
	[imageView getWLWW:&iwl :&iww];
	[imageView setWLWW:iwl :iww];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"recomputeROI" object:self userInfo: 0L];
}

- (void) popFusionAction:(id) sender
{
	int tag = [[sender selectedItem] tag];
	
	[self checkEverythingLoaded];
	[self computeInterval];
	
	[self setFusionMode: tag];
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
	
	[[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:@"stackThickness"];
	
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
		if( [[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: [[[blendingController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
		{
			// By default, re-activate 'propagate settings'
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"COPYSETTINGS"];
		}
	
		[imageView setBlending: [blendingController imageView]];
		[blendingSlider setEnabled:YES];
		[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
		
		if( [[blendingController curCLUTMenu] isEqualToString:NSLocalizedString(@"No CLUT", nil)] && [[[blendingController pixList] objectAtIndex: 0] isRGB] == NO)
		{
			if( [[self modality] isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"] == YES))
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
	
	[self clear8bitRepresentations];
	int blendingType = [sender tag];
	if (blendingType == -1)
		[self executeFilter:sender];
	else
		[self blendWithViewer:blendedwin blendingType:(int)blendingType];
	blendedwin = 0L;
}
	
- (void)blendWithViewer:(ViewerController *)bc blendingType:(int)blendingType{
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
		
		case 2:		// Image subtraction
			for( i = 0; i < [pixList[ curMovieIndex] count]; i++)
			{
				[imageView setIndex:i];
				[imageView sendSyncMessage:1];
				[imageView display];
				
				[imageView subtract: [bc imageView]];
			}
		break;
		
		case 3:		// Image multiplication
			for( i = 0; i < [pixList[ curMovieIndex] count]; i++)
			{
				[imageView setIndex:i];
				[imageView sendSyncMessage:1];
				[imageView display];
				
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
						
						long i;
						
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
		
		case 7:		// 2D Registration
			[self computeRegistrationWithMovingViewer: bc];
		break;
		
		case 8:		// 3D Registration
		
		break;
		
		case 9: // LL
		{
			[self checkEverythingLoaded];
			[bc checkEverythingLoaded];
			if([LLScoutViewer verifyRequiredConditions:[self pixList] :[bc pixList]])
			{
				LLScoutViewer *llScoutViewer;
				llScoutViewer = [[LLScoutViewer alloc] initWithPixList: pixList[0] :fileList[0] :volumeData[0] :self :bc];
				[llScoutViewer showWindow:self];
			}
		}
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
											
				NSData *data = [self roiFromDICOM:[str stringByAppendingPathExtension:@"dcm"]];	
				//If data, we successfully unarchived from SR style ROI
				if (data)
					array = [NSUnarchiver unarchiveObjectWithData:data];
				else
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
					NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
					
					@try
					{
						NSMutableString		*mutStr = [NSMutableString stringWithString: [image valueForKey:@"uniqueFilename"]];
						[mutStr replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, [mutStr length])];
						NSString *str = [path stringByAppendingFormat: @"%@-%d", mutStr , [[pixList[mIndex] objectAtIndex:i] frameNo]];
						if( [[roiList[ mIndex] objectAtIndex: i] count] > 0)
						{
							// [NSArchiver archiveRootObject: [roiList[ mIndex] objectAtIndex: i] toFile : str];
							[self archiveROIsAsDICOM:[roiList[ mIndex] objectAtIndex: i]  toPath: [str stringByAppendingPathExtension:@"dcm"] forImage:image];
							[[NSFileManager defaultManager] removeFileAtPath: str handler: 0L];
						}
						else
						{
							[[NSFileManager defaultManager] removeFileAtPath: str handler: 0L];
							[[NSFileManager defaultManager] removeFileAtPath: [str stringByAppendingPathExtension:@"dcm"] handler: 0L];
						}
					}
					
					@catch( NSException *ne)
					{
						NSLog(@"saveROI failed.");
					}
					
					[pool release];
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
		case tPushBack:		filename = @"Repulsor";			break;
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
	
	[imageView stopROIEditingForce: YES];
	
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
	
	float minValue = -99999;
	float maxValue = 99999;
	if( [checkMaxValue state] == NSOnState) maxValue = [maxValueText floatValue];
	if( [checkMinValue state] == NSOnState) minValue = [minValueText floatValue];

	BOOL propagateIn4D = [setROI4DSeries state] == NSOnState;
	float newValue = [newValueText floatValue];
	
	// proceed
	[self roiSetPixels:selectedROI :allRois :propagateIn4D :outside :minValue :maxValue :newValue];
	
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList[ curMovieIndex] userInfo: 0L];
}

- (void) roiSetStartScheduler:(NSMutableArray*) roiToProceed
{
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
}

- (IBAction) roiSetPixels:(ROI*)aROI :(short)allRois :(BOOL) propagateIn4D :(BOOL)outside :(float)minValue :(float)maxValue :(float)newValue
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
	
	[self checkEverythingLoaded];
	
	WaitRendering *splash = [[WaitRendering alloc] init:@"Filtering..."];
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
	
	[self roiSetStartScheduler: roiToProceed];
	
	[splash close];
	[splash release];
			
	NSLog(@"endSetPixel");
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

- (IBAction) roiDeleteWithName:(NSString*) name
{
	long i, x, y;
	
	[imageView stopROIEditingForce: YES];
	
	for( y = 0; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[y] count]; x++)
		{
			//[[roiList[y] objectAtIndex: x] removeAllObjects];
			for( i = 0; i < [[roiList[y] objectAtIndex: x] count]; i++)
			{
				ROI *curROI = [[roiList[y] objectAtIndex: x] objectAtIndex:i];
				
				if( [[curROI name] isEqualToString: name])
				{
					[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:curROI userInfo: 0L];
					[[roiList[y] objectAtIndex: x] removeObject: curROI];
				}
			}
		}
	}
	
	[imageView setIndex: [imageView curImage]];
}

- (IBAction) roiDeleteAll:(id) sender
{
	long i, x, y;
	
	[imageView stopROIEditingForce: YES];
	
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
	
	if( [roiList[curMovieIndex] count] <= [imageView curImage]) return;
	
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

-(NSMutableArray*) roiList: (long) i
{
	if( i < 0) i = 0;
	if( i>= maxMovieIndex) i = maxMovieIndex-1;

	return roiList[i];
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
					int pos, to;
					
					pos = [imageView curImage];
					
					if( [imageView flippedData]) to = [pixList[curMovieIndex] count] -1 - [roiPropaDest floatValue];
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

-(void) setROIToolTag:(int) roitype
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

- (IBAction)exportAsDICOMSR:(id)sender;
{
	SRAnnotationController *srController = [[SRAnnotationController alloc] initWithViewerController:self];
	[srController beginSheet];
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
//	else [self setROIToolTag: tPlain];
}

- (NSLock*) roiLock { return roiLock;}

//obligatory class for protocol Schedulable.h
-(void)performWorkUnits:(NSSet *)workUnits forScheduler:(Scheduler *)scheduler
{
	NSEnumerator	*enumerator = [workUnits objectEnumerator];
	NSDictionary	*object;
	
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
}

- (void) applyMorphology: (NSArray*) rois action:(NSString*) action	radius: (long) radius sendNotification: (BOOL) sendNotification
{
	// Create a scheduler
	id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
	[sched setDelegate: self];
	
	[roiLock lock];
	
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
	
	[roiLock unlock];
	
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

- (float) factorPET2SUV
{
	return factorPET2SUV;
}

- (void) convertPETtoSUV
{
	long	y, x, i;
	BOOL	updatewlww = NO;
	float	updatefactor;
	float	maxValueOfSeries = -100000, minValueOfSeries = 100000;
	
	if( [[imageView curDCM] radionuclideTotalDoseCorrected] <= 0) return;
	if( [[imageView curDCM] patientsWeight] <= 0) return;
	if( [[imageView curDCM] hasSUV] == NO) return;
	
	if( [[imageView curDCM] SUVConverted] == NO)
	{
		updatewlww = YES;
		
		if( [[[imageView curDCM] units] isEqualToString:@"CNTS"]) updatefactor = [[imageView curDCM] philipsFactor];
		else updatefactor = [[imageView curDCM] patientsWeight] * 1000. / [[imageView curDCM] radionuclideTotalDoseCorrected];
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
				else factorPET2SUV = [pix patientsWeight] * 1000. / ([pix radionuclideTotalDoseCorrected]);
				
				i = [pix pheight] * [pix pwidth];
				
				while( i--> 0)
				{
					*imageData++ *=  factorPET2SUV;
				}
				
				[pix setSUVConverted : YES];
			}
			
			[pix computePixMinPixMax];
			
			if( maxValueOfSeries < [pix fullwl] + [pix fullww]/2) maxValueOfSeries = [pix fullwl] + [pix fullww]/2;
			if( minValueOfSeries > [pix fullwl] - [pix fullww]/2) minValueOfSeries = [pix fullwl] - [pix fullww]/2;
		}
	}
	
	for( y = 0; y < maxMovieIndex; y++)
	{
		for( x = 0; x < [pixList[y] count]; x++)
		{
			[[pixList[y] objectAtIndex: x] setMaxValueOfSeries: maxValueOfSeries];
			[[pixList[y] objectAtIndex: x] setMinValueOfSeries: minValueOfSeries];
			
			[[pixList[y] objectAtIndex: x] setSavedWL: [[pixList[y] objectAtIndex: x] savedWL]* updatefactor];
			[[pixList[y] objectAtIndex: x] setSavedWW: [[pixList[y] objectAtIndex: x] savedWW]* updatefactor];
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
		
		if( [[suvForm cellAtIndex: 0] floatValue] > 0)
		{
			for( y = 0; y < maxMovieIndex; y++)
			{
				for( x = 0; x < [pixList[y] count]; x++)
				{
					[[pixList[y] objectAtIndex: x] setPatientsWeight: [[suvForm cellAtIndex: 0] floatValue]];
					[[pixList[y] objectAtIndex: x] setRadionuclideTotalDose: [[suvForm cellAtIndex: 1] floatValue] * 1000000.];
					[[pixList[y] objectAtIndex: x] setRadiopharmaceuticalStartTime: [NSCalendarDate dateWithString:[[suvForm cellAtIndex: 3] stringValue] calendarFormat:@"%H:%M:%S"]];
					[[pixList[y] objectAtIndex: x] computeTotalDoseCorrected];
				}
			}
			
			[[NSUserDefaults standardUserDefaults] setInteger: [[suvConversion selectedCell] tag] forKey:@"SUVCONVERSION"];
			
			float maxValueOfSeries = -100000, minValueOfSeries = 100000;
			
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
							DCMPix	*pix = [pixList[y] objectAtIndex: x];
							
							[pix computePixMinPixMax];
							
							if( maxValueOfSeries < [pix fullwl] + [pix fullww]/2) maxValueOfSeries = [pix fullwl] + [pix fullww]/2;
							if( minValueOfSeries > [pix fullwl] - [pix fullww]/2) minValueOfSeries = [pix fullwl] - [pix fullww]/2;
						}
					}
					
					for( y = 0; y < maxMovieIndex; y++)
					{
						for( x = 0; x < [pixList[y] count]; x++)
						{
							[[pixList[y] objectAtIndex: x] setMaxValueOfSeries: maxValueOfSeries];
							[[pixList[y] objectAtIndex: x] setMinValueOfSeries: minValueOfSeries];
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

- (IBAction) updateSUVValues:(id) sender
{
	int			x, y;
	NSDate		*newDate = [NSCalendarDate dateWithString:[[suvForm cellAtIndex: 3] stringValue] calendarFormat:@"%H:%M:%S"];
	float		newInjectedDose = [[suvForm cellAtIndex: 1] floatValue] * 1000000.;
	
	if( -[newDate timeIntervalSinceDate: [[imageView curDCM] acquisitionTime]] <= 0)
	{
		NSRunAlertPanel(NSLocalizedString(@"SUV Error", nil), NSLocalizedString(@"Injection time CANNOT be after acquisition time !", nil), nil, nil, nil);

		if( [[imageView curDCM] radiopharmaceuticalStartTime])
			[[suvForm cellAtIndex: 3] setStringValue: [[[imageView curDCM] radiopharmaceuticalStartTime] descriptionWithCalendarFormat:@"%H:%M:%S"]];			
	}
	else
	{
		for( y = 0; y < maxMovieIndex; y++)
		{
			for( x = 0; x < [pixList[y] count]; x++)
			{
				[[pixList[y] objectAtIndex: x] setRadionuclideTotalDose: newInjectedDose];
				[[pixList[y] objectAtIndex: x] setRadiopharmaceuticalStartTime: [NSCalendarDate dateWithString:[[suvForm cellAtIndex: 3] stringValue] calendarFormat:@"%H:%M:%S"]];
				[[pixList[y] objectAtIndex: x] computeTotalDoseCorrected];
			}
		}
		
		[[suvForm cellAtIndex: 1] setStringValue: [NSString stringWithFormat:@"%2.3f", [[imageView curDCM] radionuclideTotalDose] / 1000000. ]];
		
		[[suvForm cellAtIndex: 2] setStringValue: [NSString stringWithFormat:@"%2.3f", [[imageView curDCM] radionuclideTotalDoseCorrected] / 1000000. ]];

		if( [[imageView curDCM] radiopharmaceuticalStartTime])
			[[suvForm cellAtIndex: 3] setStringValue: [[[imageView curDCM] radiopharmaceuticalStartTime] descriptionWithCalendarFormat:@"%H:%M:%S"]];
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
			[[suvForm cellAtIndex: 3] setStringValue: [[[imageView curDCM] radiopharmaceuticalStartTime] descriptionWithCalendarFormat:@"%H:%M:%S"]];
		
		if( [[imageView curDCM] radiopharmaceuticalStartTime])
			[[suvForm cellAtIndex: 4] setStringValue: [[[imageView curDCM] acquisitionTime] descriptionWithCalendarFormat:@"%H:%M:%S"]];
		
		[[suvForm cellAtIndex: 5] setStringValue: [NSString stringWithFormat:@"%2.2f", [[imageView curDCM] halflife] / 60.]];
		
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
		tail = [composedMenuTitle copy];
		[composedMenuTitle release];
		composedMenuTitle = [NSString stringWithFormat:@"%@ %@",currentMenuTitle, tail];
		currentMenu = superMenu;
		currentMenuTitle = [currentMenu title];
		superMenu = [currentMenu supermenu];
		i++;
	}
	NSLog(composedMenuTitle);
	
	if ([composedMenuTitle isEqualToString:@"?"]) //creating a content panel
	{
		[NSApp beginSheet: CommentsWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	}
	else //same action as endSetComments, but with composedMenuTitle
	{
		[[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] setValue:composedMenuTitle forKeyPath:@"series.comment"];
		
		if([browserWindow isCurrentDatabaseBonjour])
		{
			[browserWindow setBonjourDatabaseValue:[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] value:[CommentsEditField stringValue] forKey:@"series.comment"];
		}
		
		[[browserWindow databaseOutline] reloadData];
		
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


- (void)displayDICOMOverlays: (id)sender
{
	[self revertSeries: self];
}

- (void)useVOILUT: (id)sender
{
	[self revertSeries: self];
	[imageView setWLWW:[[imageView curDCM] savedWL] :[[imageView curDCM] savedWW]];
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
	[appController willChangeValueForKey:@"SYNCSERIES"];
	
	SYNCSERIES = !SYNCSERIES;
	
	[appController didChangeValueForKey:@"SYNCSERIES"];
	
	float sliceLocation =  [[[imageView dcmPixList] objectAtIndex:[imageView  curImage]] sliceLocation];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithFloat:sliceLocation] forKey:@"sliceLocation"];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"notificationSyncSeries" object:0L userInfo: userInfo];
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
					DCMPix		*curDCM = [pixList[ i] objectAtIndex:x];
					float		vectorP[ 9], tempOrigin[ 3], tempOriginBlending[ 3];
					NSPoint		offset;
					
					// Compute blended view offset
					[curDCM orientation: vectorP];
					
					tempOrigin[ 0] = [curDCM originX] * vectorP[ 0] + [curDCM originY] * vectorP[ 1] + [curDCM originZ] * vectorP[ 2];
					tempOrigin[ 1] = [curDCM originX] * vectorP[ 3] + [curDCM originY] * vectorP[ 4] + [curDCM originZ] * vectorP[ 5];
					tempOrigin[ 2] = [curDCM originX] * vectorP[ 6] + [curDCM originY] * vectorP[ 7] + [curDCM originZ] * vectorP[ 8];
					
					tempOriginBlending[ 0] = [[[blendingController imageView] curDCM] originX] * vectorP[ 0] + [[[blendingController imageView] curDCM] originY] * vectorP[ 1] + [[[blendingController imageView] curDCM] originZ] * vectorP[ 2];
					tempOriginBlending[ 1] = [[[blendingController imageView] curDCM] originX] * vectorP[ 3] + [[[blendingController imageView] curDCM] originY] * vectorP[ 4] + [[[blendingController imageView] curDCM] originZ] * vectorP[ 5];
					tempOriginBlending[ 2] = [[[blendingController imageView] curDCM] originX] * vectorP[ 6] + [[[blendingController imageView] curDCM] originY] * vectorP[ 7] + [[[blendingController imageView] curDCM] originZ] * vectorP[ 8];
					
					[curDCM setPixelSpacingX: [[imageView curDCM] pixelSpacingX] * ([[blendingController imageView] pixelSpacingX] / [[blendingController imageView] scaleValue]) /  ([[imageView curDCM] pixelSpacingX]/[imageView scaleValue])];
					[curDCM setPixelSpacingY: [[imageView curDCM] pixelSpacingY] * ([[blendingController imageView] pixelSpacingY] / [[blendingController imageView] scaleValue]) / ([[imageView curDCM] pixelSpacingY]/[imageView scaleValue])];
					
					offset.x = (tempOrigin[0] + [curDCM pwidth]*[curDCM pixelSpacingX]/2. - (tempOriginBlending[ 0] + [[[blendingController imageView] curDCM] pwidth]*[[[blendingController imageView] curDCM] pixelSpacingX]/2.));
					offset.y = (tempOrigin[1] + [curDCM pheight]*[curDCM pixelSpacingY]/2. - (tempOriginBlending[ 1] + [[[blendingController imageView] curDCM] pheight]*[[[blendingController imageView] curDCM] pixelSpacingY]/2.));
					
					o[ 0] = [curDCM originX];		o[ 1] = [curDCM originY];		o[ 2] = [curDCM originZ];

					o[ 0] -= ([[blendingController imageView] origin].x*[[[blendingController imageView] curDCM] pixelSpacingX]/[[blendingController imageView] scaleValue] - [imageView origin].x*[curDCM pixelSpacingX]/[imageView scaleValue]) + offset.x;
					o[ 1] += ([[blendingController imageView] origin].y*[[[blendingController imageView] curDCM] pixelSpacingY]/[[blendingController imageView] scaleValue] - [imageView origin].y*[curDCM pixelSpacingY]/[imageView scaleValue]) - offset.y;
					o[ 2] += zDiff;
					
					[curDCM setOrigin: o];
					[curDCM setSliceLocation: o[ 2]];
				}
			}
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"COPYSETTINGS"];
			[imageView setSyncro: syncroLOC];
			[imageView sendSyncMessage:1];
			[self propagateSettings];
		}
		else NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Only useful if propagate settings is OFF.", nil), nil, nil, nil);
	}
	else NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Only useful if image fusion is activated.", nil), nil, nil, nil);
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
		if( curMovieIndex != [vC curMovieIndex] && maxMovieIndex ==  [vC maxMovieIndex])
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
				
				if( [[vC modality] isEqualToString: @"CR"]) propagate = NO;
				
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

			
			float vectorsA[9], vectorsB[9];
			
			[[pixList[0] objectAtIndex:0] orientation: vectorsA];
			[[[vC pixList] objectAtIndex:0] orientation: vectorsB];
			
			float fValue;
			
			if(  curvedController == 0L && [vC curvedController] == 0L)
			{
//				if( (int) (vectorsA[ 6]*1000.) == (int) (vectorsB[ 6]*1000.) && (int) (vectorsA[ 7]*1000.) == (int) (vectorsB[ 7]*1000.) && (int) (vectorsA[ 8]*1000.) == (int) (vectorsB[ 8]*1000.) && curvedController == 0L)
				if( curvedController == 0L)
				{
				//	if( [[vC modality] isEqualToString:[self modality]])	For PET CT, we have to sync this even if the modalities are not equal!
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
			
			if( (int) (vectorsA[ 6]*1000.) == (int) (vectorsB[ 6]*1000.) && (int) (vectorsA[ 7]*1000.) == (int) (vectorsB[ 7]*1000.) && (int) (vectorsA[ 8]*1000.) == (int) (vectorsB[ 8]*1000.) && curvedController == 0L)
			{
			//	if( [[vC modality] isEqualToString:[self modality]])	For PET CT, we have to sync this even if the modalities are not equal!
				{
//					if( [[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: [[[vC fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]]) // We should be able to propagate across series -JS
					{
						NSPoint pan;
					
						pan = [imageView origin];
						[[vC imageView] setOrigin: NSMakePoint( pan.x, pan.y)];
					
						fValue = [imageView rotation];
						[[vC imageView] setRotation: fValue];
					}
				}
			}
		}
		
		if( self == [vC blendingController])
		{
			[[vC imageView] loadTextures];
			[[vC imageView] setNeedsDisplay:YES];
		}
	}
	
	[viewersList release];
	
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

-(NSSlider*) moviePosSlider
{
	return moviePosSlider;
}

- (void) setMovieIndex: (short) i
{
	int index = [imageView curImage];
	BOOL wasDataFlipped = [imageView flippedData];
	
	curMovieIndex = i;
	if( curMovieIndex < 0) curMovieIndex = maxMovieIndex-1;
	if( curMovieIndex >= maxMovieIndex) curMovieIndex = 0;
	
	[moviePosSlider setIntValue:curMovieIndex];
	
	[imageView setDCM:pixList[curMovieIndex] :fileList[curMovieIndex] :roiList[curMovieIndex] :0 :'i' :NO];
	[self setWindowTitle: self];
	
	if( wasDataFlipped) [self flipDataSeries: self];
	
	[imageView setIndex: index];
	[imageView sendSyncMessage:1];
	
	[self adjustSlider];
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
    
//	if( [self isEverythingLoaded] == NO) return;
	
	if( loadingPercentage < 0.5) return;
	
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
	if( [[self imageView] flippedData]) [[self imageView] setIndex: [self getNumberOfImages] -1 -i];
	else [[self imageView] setIndex: i];

	[imageView sendSyncMessage:1];
	
	[self adjustSlider];
	
	[imageView displayIfNeeded];
}

- (void) performAnimation:(id) sender
{
	NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
	short           val;
	
//	if( [self isEverythingLoaded] == NO) return;
	
	if( loadingPercentage < 0.5) return;
	
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
        
		[movieTextSlide setStringValue:[NSString stringWithFormat:@"%0.0f im/s", (float) [movieRateSlider floatValue]]];
    }
    else
    {
		NSArray		*winList = [NSApp windows];
		int			i;
		
		for( i = 0; i < [winList count]; i++)
		{
			if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
			{
				[[[winList objectAtIndex:i] windowController] MovieStop: self];
			}
		}
		
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
	
	int columns = [[[[printLayout selectedItem] title] substringWithRange: NSMakeRange(0, 1)] intValue];
	int rows = [[[[printLayout selectedItem] title] substringWithRange: NSMakeRange(2, 1)] intValue];
	int ipp = columns * rows;
	
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
			if (![[[fileList[ curMovieIndex] objectAtIndex: i] valueForKey: @"isKeyImage"] boolValue]) saveImage = NO;
		}
		
		if( saveImage)
		{
			count++;
		}
	}
	
	if( count % ipp == 0) [printPagesToPrint setStringValue: [NSString stringWithFormat:@"%d pages", count / ipp]];
	else [printPagesToPrint setStringValue: [NSString stringWithFormat:@"%d pages", 1 + (count / ipp)]];
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation
                success:(BOOL)success
                contextInfo:(void*)info
{
    if (success)
	{
	
    }
	
	NSString	*tmpFolder = [NSString stringWithFormat:@"/tmp/print"];
	
	[[NSFileManager defaultManager] removeFileAtPath: tmpFolder handler:nil];
}

-(IBAction) endPrint:(id) sender
{
	[self checkEverythingLoaded];
	
    [printWindow orderOut:sender];
    [NSApp endSheet:printWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		NSMutableDictionary	*settings = [NSMutableDictionary dictionary];
		
		int columns = [[[[printLayout selectedItem] title] substringWithRange: NSMakeRange(0, 1)] intValue];
		int rows = [[[[printLayout selectedItem] title] substringWithRange: NSMakeRange(2, 1)] intValue];
		
		[settings setObject: [[printLayout selectedItem] title] forKey: @"layout"];
		[settings setObject: [NSNumber numberWithInt: columns] forKey: @"columns"];
		[settings setObject: [NSNumber numberWithInt: rows] forKey: @"rows"];
		
		if( [[printSettings cellWithTag: 2] state]) [settings setObject: [printText stringValue] forKey: @"comments"];
		if( [[printSettings cellWithTag: 3] state]) [settings setObject: @"YES" forKey: @"backgroundColor"];
		float r, g, b;
		
		NSColor	*rgbColor = [[printColor color] colorUsingColorSpaceName: NSDeviceRGBColorSpace];
		
		[rgbColor getRed:&r green:&g blue:&b alpha:0L];
		[settings setObject: [NSNumber numberWithFloat: r] forKey: @"backgroundColorR"];
		[settings setObject: [NSNumber numberWithFloat: g] forKey: @"backgroundColorG"];
		[settings setObject: [NSNumber numberWithFloat: b] forKey: @"backgroundColorB"];
		if( [[printSettings cellWithTag: 0] state]) [settings setObject: @"YES" forKey: @"patientInfo"];
		if( [[printSettings cellWithTag: 1] state]) [settings setObject: @"YES" forKey: @"studyInfo"];
		[settings setObject: [NSNumber numberWithInt: [[printFormat selectedCell] tag]] forKey: @"format"];
		[settings setObject: [NSNumber numberWithInt: [printInterval intValue]] forKey: @"interval"];
		
		[[NSUserDefaults standardUserDefaults] setObject: settings forKey: @"previousPrintSettings"];
		
		NSString	*tmpFolder = [NSString stringWithFormat:@"/tmp/print"];

		int from;
		int to;
		int interval;
		
		switch( [[printSelection selectedCell] tag])
		{
			case 0:
				if( [imageView flippedData]) from = [pixList[ curMovieIndex] count] - [imageView curImage] - 1;
				else from = [imageView curImage];
				
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
		
		NSMutableArray	*files = [NSMutableArray array];
		
		[[NSFileManager defaultManager] removeFileAtPath: tmpFolder handler:nil];
		[[NSFileManager defaultManager] createDirectoryAtPath:tmpFolder attributes:nil];
		
		Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Preparing printing...", nil)];
		[splash showWindow:self];
		[[splash progress] setMaxValue: (to - from) / interval];
		
		int currentImageIndex = [imageView curImage];
		
		int i;
		for( i = from; i < to; i += interval)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			BOOL saveImage = YES;
			
			if( [[printSelection selectedCell] tag] == 1)
			{
				NSManagedObject	*image;
				
				if( [[self imageView] flippedData]) image = [[self fileList] objectAtIndex: [[self fileList] count] -1 -i];
				else image = [[self fileList] objectAtIndex: i];
				
				if (![[image valueForKey: @"isKeyImage"] boolValue]) saveImage = NO;
			}
			
			if( saveImage)
			{
				[self setImageIndex: i];
				NSImage *im = [[imageView nsimage: [[printFormat selectedCell] tag]] autorelease];
				im = [DCMPix resizeIfNecessary: im dcmPix: [imageView curDCM]];
				
				NSData *imageData = [im  TIFFRepresentation];
				NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
				NSData *bitmapData = [imageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
				
				[files addObject: [tmpFolder stringByAppendingFormat:@"/%d", i]];
				
				[bitmapData writeToFile: [files lastObject] atomically:YES];
			}
			
			[splash incrementBy: 1];
			
			[pool release];
		}
		
		[imageView setIndex: currentImageIndex];
		[imageView sendSyncMessage:1];
		[self adjustSlider];
		
		[splash close];
		[splash release];
		
		if( [files count])
		{
			printView	*pV = [[[printView alloc] initWithViewer: self settings: settings files: files] autorelease];
			
			NSPrintOperation * printOperation = [NSPrintOperation printOperationWithView: pV];
			
			[printOperation setCanSpawnSeparateThread: YES];
			
			[printOperation runOperationModalForWindow:[self window]
                delegate:self
                didRunSelector: @selector(printOperationDidRun:success:contextInfo:)
                contextInfo:0L];
		}
    }
	else
	{
	}
}

- (IBAction) printSlider:(id) sender
{
	if( [[printSelection selectedCell] tag] == 2)
	{
		[printFromText takeIntValueFrom: printFrom];
		[printToText takeIntValueFrom: printTo];
		
		if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
		else [imageView setIndex:  [sender intValue]-1];
		
		[imageView sendSyncMessage:1];
		
		[self adjustSlider];
	}
	
	[self setPagesToPrint: self];
}

- (void) print:(id) sender
{
	NSDictionary	*p = [[NSUserDefaults standardUserDefaults] objectForKey: @"previousPrintSettings"];
	
	if( p)
	{
		[printLayout selectItemWithTitle: [p valueForKey: @"layout"]];
		if( [p valueForKey: @"comments"]) [[printSettings cellWithTag: 2] setState: NSOnState];
		else [[printSettings cellWithTag: 2] setState: NSOffState];
		if( [p valueForKey: @"backgroundColor"]) [[printSettings cellWithTag: 3] setState: NSOnState];
		else [[printSettings cellWithTag: 3] setState: NSOffState];
		
		[printColor setColor: [NSColor colorWithDeviceRed:[[p valueForKey: @"backgroundColorR"] floatValue] green:[[p valueForKey: @"backgroundColorG"] floatValue] blue:[[p valueForKey: @"backgroundColorB"] floatValue] alpha: 1.0]];
		
		if( [p valueForKey: @"patientInfo"]) [[printSettings cellWithTag: 0] setState: NSOnState];
		else [[printSettings cellWithTag: 0] setState: NSOffState];
		if( [p valueForKey: @"studyInfo"]) [[printSettings cellWithTag: 1] setState: NSOnState];
		else [[printSettings cellWithTag: 1] setState: NSOffState];
		
		[printFormat selectCellWithTag: [[p valueForKey: @"format"] intValue]];
		[printInterval setIntValue: [[p valueForKey: @"interval"] intValue]];
		
		[printText setStringValue: [p valueForKey: @"comments"]];
	}
	
	// ****
	
	[printFrom setMaxValue: [pixList[ curMovieIndex] count]];
	[printTo setMaxValue: [pixList[ curMovieIndex] count]];

	[printFrom setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
	[printTo setNumberOfTickMarks: [pixList[ curMovieIndex] count]];

	if( [imageView flippedData]) [printFrom setIntValue: [pixList[ curMovieIndex] count] - [imageView curImage]];
	else [printFrom setIntValue: 1+ [imageView curImage]];
	[printTo setIntValue: [pixList[ curMovieIndex] count]];
	
	[printToText setIntValue: [printTo intValue]];
	[printFromText setIntValue: [printFrom intValue]];
	[printIntervalText setIntValue: [printInterval intValue]];
	
	[self setCurrentdcmExport: printSelection];
	
	[self setPagesToPrint: self];
	
	[NSApp beginSheet: printWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) printDICOM:(id) sender
{
	[self checkEverythingLoaded];
	
	#if !__LP64__
	[[[AYDicomPrintWindowController alloc] init] autorelease];
	#endif
}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	NSImage		*im = 0L;
	BOOL		export = YES;
	int			curSample = [cur intValue] + qt_from;
			
	if( qt_dimension == 3)
	{
		NSManagedObject	*image;
		
		if( [[self imageView] flippedData]) image = [[self fileList] objectAtIndex: [[self fileList] count] -1 -curSample];
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
				if( [[self imageView] flippedData]) [[self imageView] setIndex: [self getNumberOfImages] - 1 -curSample];
				else [[self imageView] setIndex:curSample];
				[[self imageView] sendSyncMessage:1];
				[[self imageView] display];
			break;

			case 0:
				[[self blendingSlider] setIntValue: -256 + ((curSample * 512) / ([max intValue]-1))];
				[self blendingSlider:[self blendingSlider]];
				[[self imageView] display];
			break;

			case 2:
				[[self moviePosSlider] setIntValue: curSample];
				[self moviePosSliderAction:[self moviePosSlider]];
				[[self imageView] display];
			break;
		}
				
		im = [[self imageView] nsimage: [[NSUserDefaults standardUserDefaults] boolForKey: @"ORIGINALSIZE"]];
	}
	
	return im;
}

-(void) exportQuicktimeIn:(long) dimension :(long) from :(long) to :(long) interval
{
	QuicktimeExport *mov;
	
	qt_dimension = dimension;
	
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
	
	mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :qt_to - qt_from];
	
	switch( qt_dimension)
	{
		default:
		case 1:
		case 3:
			if( [self frameRate] > 0) [mov setRate: [NSNumber numberWithInt: [self frameRate]]];
		break;
		
		case 0:
			[mov setRate: [NSNumber numberWithInt: 10]];
		break;
		
		case 2:
			if( [self frame4DRate] > 0) [mov setRate: [NSNumber numberWithInt: [self frame4DRate]]];
		break;
	}
	
	NSString *path = [mov createMovieQTKit: NO  :EXPORT2IPHOTO :[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
	
	if( EXPORT2IPHOTO)
	{
		iPhoto *ifoto = [[iPhoto alloc] init];
		[ifoto importIniPhoto: [NSArray arrayWithObject:[documentsDirectory() stringByAppendingFormat:@"/TEMP/IPHOTO/"]]];
		[ifoto release];
		
		[[NSFileManager defaultManager] removeFileAtPath: path handler: 0L];
	}
	else
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [[NSWorkspace sharedWorkspace] openFile: path];
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
				
		[self exportQuicktimeIn: [[quicktimeMode selectedCell] tag] :from :to :interval];
	}
	
	[self adjustSlider];
}

- (IBAction) exportQuicktimeSlider:(id) sender
{
	[quicktimeFromText takeIntValueFrom: quicktimeFrom];
	[quicktimeToText takeIntValueFrom: quicktimeTo];
	
	if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
	else [imageView setIndex:  [sender intValue]-1];
	
	[imageView sendSyncMessage:1];
	
	[self adjustSlider];
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

	if( [imageView flippedData]) [quicktimeFrom setIntValue: [pixList[ curMovieIndex] count] - [imageView curImage]];
	else [quicktimeFrom setIntValue: 1+ [imageView curImage]];
	[quicktimeTo setIntValue: [pixList[ curMovieIndex] count]];
	
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
		
		float thickness, location;
		
		[imageView getThickSlabThickness:&thickness location:&location];
		[exportDCM setSliceThickness: thickness];
		[exportDCM setSlicePosition: location];
		
		if( screenCapture) [imageView orientationCorrectedToView: o];	// <- Because we do screen capture !!!!! We need to apply the rotation of the image
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
			[exportDCM setSeriesNumber:5300 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute]];	//Try to create a unique series number... Do you have a better idea??
			[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
			
			for (i = from ; i < to; i += interval)
			{
				NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
				
				BOOL	export = YES;
				
				if( [[dcmSelection selectedCell] tag] == 2)	// Only key images
				{
					NSManagedObject	*image;
					
					if( [[self imageView] flippedData]) image = [[self fileList] objectAtIndex: [[self fileList] count] -1 -i];
					else image = [[self fileList] objectAtIndex: i];
					
					export = [[image valueForKey:@"isKeyImage"] boolValue];
				}
				
				if( export)
				{
					if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] -1 -i];
					else [imageView setIndex:i];
					
					[imageView sendSyncMessage:1];
					[imageView display];
					[self adjustSlider];
					
					[self exportDICOMFileInt:[[dcmFormat selectedCell] tag]];
				}
				
				[splash incrementBy: 1];
				
				[pool release];
			}
			
			[splash close];
			[splash release];
		}
	}
	
	[self adjustSlider];
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
	
	if( [[sender selectedCell] tag] == 2) [self checkView: printBox :YES];
	else [self checkView: printBox :NO];
	
	if( sender == printSelection)[self setPagesToPrint: self];
}

- (IBAction) exportDICOMSlider:(id) sender
{
	if( [[dcmSelection selectedCell] tag] == 1)
	{
		[dcmFromText takeIntValueFrom: dcmFrom];
		[dcmToText takeIntValueFrom: dcmTo];
		
		if( [imageView flippedData]) [imageView setIndex: [pixList[ curMovieIndex] count] - [sender intValue]];
		else [imageView setIndex:  [sender intValue]-1];
		
		[imageView sendSyncMessage:1];
		
		[self adjustSlider];
	}
}

- (void) exportDICOMFile:(id) sender
{
	if( [sliderFusion isEnabled])
		[dcmInterval setIntValue: [sliderFusion intValue]];
	
	[dcmFrom setMaxValue: [pixList[ curMovieIndex] count]];
	[dcmTo setMaxValue: [pixList[ curMovieIndex] count]];
	
	[dcmFrom setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
	[dcmTo setNumberOfTickMarks: [pixList[ curMovieIndex] count]];
	
	if( [imageView flippedData]) [dcmFrom setIntValue: [pixList[ curMovieIndex] count] - [imageView curImage]];
	else [dcmFrom setIntValue: 1+ [imageView curImage]];
	[dcmTo setIntValue: [pixList[ curMovieIndex] count]];
	
	[dcmToText setIntValue: [dcmTo intValue]];
	[dcmFromText setIntValue: [dcmFrom intValue]];
	[dcmIntervalText setIntValue: [dcmInterval intValue]];
	
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
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"Send to DICOM node", nil), NSLocalizedString(@"Should I send only current image or all images of current series?", nil), NSLocalizedString(@"Current", nil), NSLocalizedString(@"All", nil), 0L) == NSAlertDefaultReturn) all = NO;
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

-(IBAction) PagePadCreate:(id) sender
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//check if the folder PAGES exists in OsiriX document folder
	NSString *pathToPAGES = [documentsDirectory() stringByAppendingString:@"/PAGES/"];
	if (!([fileManager fileExistsAtPath:pathToPAGES]))
	[fileManager createDirectoryAtPath:pathToPAGES attributes:nil];

	//pathToPAGES = timeStamp
	NSDateFormatter *datetimeFormatter = [[[NSDateFormatter alloc]initWithDateFormat:@"%Y%m%d.%H%M%S" allowNaturalLanguage:NO] autorelease];
	pathToPAGES = [pathToPAGES stringByAppendingString: [datetimeFormatter stringFromDate:[NSDate date]]];

	if (!([[sender title] isEqualToString: @"SCAN"]))
	{
		//create pathToTemplate
		NSString *pathToTemplate = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/PAGES/"];
		pathToTemplate = [pathToTemplate stringByAppendingString:[sender title]];
		pathToTemplate = [pathToTemplate stringByAppendingPathExtension:@"template"];	
		
		//copy file pathToTemplate to pathToPAGES
		if([fileManager copyPath:pathToTemplate toPath:[pathToPAGES stringByAppendingPathExtension:@"pages"] handler:0L]) NSLog([NSString stringWithFormat:@"%@ is a copy of %@",[pathToPAGES stringByAppendingPathExtension:@"pages"], pathToTemplate]);
		else NSLog(@"template not available");
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

//0008,1050 ( ) General Study
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

	if(
		[fileManager createFileAtPath:[pathToPAGES stringByAppendingPathExtension:@"cfg"]
							contents:[pdf2dcmContent dataUsingEncoding:NSUTF8StringEncoding]
						  attributes:nil
	    ]) NSLog([NSString stringWithFormat:@"created %@ for dicom pdf creation with dcm4che pdf2dcm",[pathToPAGES stringByAppendingPathExtension:@"cfg"]]);


	if (!([[sender title] isEqualToString: @"SCAN"]))
	{
		//open pathToPAGES
		[[NSWorkspace sharedWorkspace] openFile:[pathToPAGES stringByAppendingPathExtension:@"pages"]];
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
							NSManagedObject	*image;
							
							image = [[self fileList] objectAtIndex: i];
							
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

#if defined (MAC_OS_X_VERSION_10_5) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
#if !__LP64__
// IMAVManager notification callback.
- (void)_stateChanged:(NSNotification *)aNotification {
    // Read the state.
    IMAVManagerState state = [[IMAVManager sharedAVManager] state];
}

- (void) iChatBroadcast:(id) sender
{
	NSLog(@"ichat broadcast");
    IMAVManager *avManager = [IMAVManager sharedAVManager];
    if ([avManager state] != IMAVRunning) {
        [avManager start];
		NSLog(@"Start broadcast");
    } else {
        [avManager stop];
    }
}
#endif
#else

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
#endif

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

- clear8bitRepresentations
{
	// This function will free about 1/4 of the data
	
	int i, x;
	
	for( i = 0; i < maxMovieIndex; i++)
	{
		for( x = 0; x < [pixList[ i] count]; x++)
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
	
	factorPET2SUV = 1.0;
	windowWillClose = NO;
	EXPORT2IPHOTO = NO;
	loadingPause = NO;
	loadingPercentage = 0;
	exportDCM = 0L;
	curvedController = 0L;
	thickSlab = 0L;
	ROINamesArray = 0L;
	ThreadLoadImage = NO;
	
	subCtrlOffset.y = subCtrlOffset.x = 0;
	
	subCtrlMaskID = -2;
	curMovieIndex = 0;
	maxMovieIndex = 1;
	blendingController = 0L;
	
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	curConvMenu = [NSLocalizedString(@"No Filter", nil) retain];
	curWLWWMenu = [NSLocalizedString(@"Default WL & WW", nil) retain];

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
	
	[stacksFusion setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"stackThickness"]];
	[sliderFusion setIntValue: [[NSUserDefaults standardUserDefaults] integerForKey:@"stackThickness"]];
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
	
    [nc addObserver:self selector:@selector(UpdateWLWWMenu:) name:@"UpdateWLWWMenu" object:nil];
	[nc	addObserver:self selector:@selector(Display3DPoint:) name:@"Display3DPoint" object:nil];
	[nc addObserver:self selector:@selector(ViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:nil];
	[nc addObserver:self selector:@selector(revertSeriesNotification:) name:@"revertSeriesNotification" object:nil];
	[nc addObserver:self selector:@selector(updateVolumeData:) name:@"updateVolumeData" object:nil];
	[nc addObserver:self selector:@selector(roiChange:) name:@"roiChange" object:nil];
	[nc addObserver:self selector:@selector(OpacityChanged:) name:@"OpacityChanged" object:nil];
	[nc addObserver:self selector:@selector(defaultToolModified:) name:@"defaultToolModified" object:nil];
	[nc addObserver:self selector:@selector(defaultRightToolModified:) name:@"defaultRightToolModified" object:nil];
	
	[nc postNotificationName:@"UpdateWLWWMenu" object:curWLWWMenu userInfo:0L];
	
    [nc addObserver:self selector:@selector(UpdateConvolutionMenu:) name:@"UpdateConvolutionMenu" object:nil];
	[nc addObserver:self selector:@selector(CLUTChanged:) name:@"CLUTChanged" object:nil];
				 
	[nc postNotificationName: @"UpdateConvolutionMenu" object: curConvMenu userInfo: 0L];

    [nc addObserver:self selector:@selector(UpdateCLUTMenu:) name:@"UpdateCLUTMenu" object:nil];
	
	[nc postNotificationName: @"UpdateCLUTMenu" object: curCLUTMenu userInfo: 0L];

	curOpacityMenu = [@"Linear Table" retain];
	
    [nc addObserver:self selector:@selector(UpdateOpacityMenu:) name:@"UpdateOpacityMenu" object:nil];
	
	[nc postNotificationName:@"UpdateOpacityMenu" object:curOpacityMenu userInfo:0L];

    [nc addObserver:self selector:@selector(CloseViewerNotification:) name:@"CloseViewerNotification" object:nil];
	[nc addObserver:self selector:@selector(recomputeROI:) name:@"recomputeROI" object:nil];
	[nc addObserver:self selector:@selector(closeAllWindows:) name:@"Close All Viewers" object:nil];
	[nc addObserver:self selector:@selector(notificationStopPlaying:) name:@"notificationStopPlaying" object:nil];
	[nc addObserver:self selector:@selector(notificationiChatBroadcast:) name:@"notificationiChatBroadcast" object:nil];
	[nc addObserver:self selector:@selector(notificationSyncSeries:) name:@"notificationSyncSeries" object:nil];
	[nc	addObserver:self selector:@selector(exportTextFieldDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
	[nc addObserver:self selector:@selector(updateReportToolbarIcon:) name:@"reportModeChanged" object:nil];
	[nc addObserver:self selector:@selector(updateReportToolbarIcon:) name:@"OsirixDeletedReport" object:nil];
	[nc addObserver:self selector:@selector(reportToolbarItemWillPopUp:) name:NSPopUpButtonWillPopUpNotification object:nil];
	
	[[self window] registerForDraggedTypes: [NSArray arrayWithObjects:NSFilenamesPboardType, pasteBoardOsiriX, nil]];
	
	if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
	{
		if( [[self modality] isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"] == YES))
		{
			if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
				[self ApplyCLUTString: @"B/W Inverse"];
			else
				[self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
		}
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
	
	NSNumber	*status = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.study.stateText"];
	
	if( status == 0L) [StatusPopup selectItemWithTitle: @"empty"];
	else [StatusPopup selectItemWithTag: [status intValue]];
	
	NSString	*com = [[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKeyPath:@"series.comment"];//JF20070103
	
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
		[self MovieStop: self];
		
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
			
			if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
			{
				if( [[self modality] isEqualToString:@"PT"] == YES )
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
			
			if( [[self modality] isEqualToString:@"PT"] == YES && [[pixList[0] objectAtIndex: 0] isRGB] == NO)
			{
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

//-(IBAction) MPRViewer:(id) sender
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
//		MPRController *viewer = [appController FindViewer :@"MPR" :pixList[0]];
//		
//		if( viewer)
//		{
//			[[viewer window] makeKeyAndOrderFront:self];
//		}
//		else
//		{
//			viewer = [[MPRController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[0] :blendingController];
//			
//			for( i = 1; i < maxMovieIndex; i++)
//			{
//				[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
//			}
//			
//			[viewer ApplyCLUTString:curCLUTMenu];
//			float   iwl, iww;
//			[imageView getWLWW:&iwl :&iww];
//			[viewer setWLWW:iwl :iww];
//			[viewer showWindow:self];
//			[[viewer window] makeKeyAndOrderFront:self];
//			[viewer setWLWW:iwl :iww];
//			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
//		}
//	}
//}

-(IBAction) segmentationTest:(id) sender
{
	BOOL volumicData = YES;
	
	long j;
	for( j = 0 ; j < [pixList[ curMovieIndex] count]; j++)
	{
		if ( [[pixList[ curMovieIndex] objectAtIndex: 0] pwidth] != [[pixList[ curMovieIndex] objectAtIndex: j] pwidth]) volumicData = NO;
		if ( [[pixList[ curMovieIndex] objectAtIndex: 0] pheight] != [[pixList[ curMovieIndex] objectAtIndex: j] pheight]) volumicData = NO;
		if ( [[pixList[ curMovieIndex] objectAtIndex: 0] isRGB] == YES) volumicData = NO;
	}
		
	if( volumicData == NO)
	{
		NSRunAlertPanel(NSLocalizedString(@"Growing Region", nil), NSLocalizedString(@"Growing Region algorithms are currently supported only for B/W images.", nil), nil, nil, nil);
		return;
	}

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
		[self MovieStop: self];
		
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
					viewer = [self openVRVPROViewerForMode:mode];
					/*
					viewer = [[VRPROController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[ 0] :blendingController :self mode: mode];
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
					*/
					[viewer ApplyCLUTString:curCLUTMenu];
					float   iwl, iww;
					[imageView getWLWW:&iwl :&iww];
					[viewer setWLWW:iwl :iww];
					[viewer load3DState];
					[[viewer window] performZoom:self];
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

- (VRPROController *)openVRVPROViewerForMode:(NSString *)mode{
	long i;
	
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];	
	[self MovieStop: self];
	
	if( [VRPROController available])
	{
		if( [VRPROController  hardwareCheck])
		{
			VRPROController *viewer = [appController FindViewer :@"VRVPRO" :pixList[0]];

			if( viewer)
			{
				return viewer;
			}
			else
			{		
				viewer = [[VRPROController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[ 0] :blendingController :self style:@"standard" mode: mode];
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
			}
			return viewer;
		}
	}
	return nil;
}


- (VRController *)openVRViewerForMode:(NSString *)mode{
	long i;
	
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];	
	[self MovieStop: self];
	
	VRController *viewer = [appController FindViewer :@"VR" :pixList[0]];
	
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
	}
	return viewer;
}


-(IBAction) VRViewer:(id) sender
{
	long i;
	
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
		if( [curConvMenu isEqualToString:NSLocalizedString(@"No Filter", nil)] == NO)
		{
			if( NSRunInformationalAlertPanel( NSLocalizedString(@"Convolution", nil), NSLocalizedString(@"Should I apply current convolution filter on raw data? 2D/3D post-processing viewers can only display raw data.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
				[self applyConvolutionOnSource: self];
		}
		
		[self MovieStop: self];
		
		VRController *viewer = [appController FindViewer :@"VR" :pixList[0]];
		
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
		/*
			NSString	*mode;
			
			if( [sender tag] == 3) mode = @"MIP";
			else mode = @"VR";
			
			viewer = [[VRController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[ 0] :blendingController :self style:@"standard" mode: mode];
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
		*/
			NSString	*mode;
			if( [sender tag] == 3) mode = @"MIP";
			else mode = @"VR";
			viewer = [self openVRViewerForMode:mode];
			
			[viewer ApplyCLUTString:curCLUTMenu];
			float   iwl, iww;
			[imageView getWLWW:&iwl :&iww];
			[viewer setWLWW:iwl :iww];
			[viewer load3DState];
			[[viewer window] performZoom:self];
			[viewer showWindow:self];			
			[[viewer window] makeKeyAndOrderFront:self];
			[[viewer window] display];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

- (SRController *)openSRViewer{
	SRController *viewer;
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];
	if (viewer = [appController FindViewer :@"SR" :pixList[0]])
		return viewer;
	viewer = [[SRController alloc] initWithPix:pixList[curMovieIndex] :fileList[0] :volumeData[curMovieIndex] :blendingController :self];
	return viewer;
	
}
-(IBAction) SRViewer:(id) sender
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
		[self MovieStop: self];
		
		SRController *viewer = [appController FindViewer :@"SR" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			viewer = [self openSRViewer];
			[[viewer window] performZoom:self];
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
			CurvedMPR *curvedMPR[3];
			
			if( [curvedMPRper state] == NSOnState)
				curvedMPR[0] = [[CurvedMPR alloc] initWithObjectsPer:pixList[0] :fileList[0] :volumeData[0] :selectedRoi :self :[curvedMPRinterval intValue] :[curvedMPRsize intValue]];
			
			///curvedMPR = [[CurvedMPR alloc] initWithObjects:pixList[0] :fileList[0] :volumeData[0] :selectedRoi :self :[curvedMPRslid intValue]];
			
			short i;
			for(i=0;i<3;i++)
			{
			if([[curvedMPRaxis cellWithTag:i] state] == NSOnState)
				curvedMPR[0] = [[CurvedMPR alloc] initWithObjects:pixList[0] :fileList[0] :volumeData[0] :selectedRoi :self :[curvedMPRslid intValue] forView:i];
			}
		}
	}
}

-(IBAction) CurvedMPR:(id) sender
{
long i;
	
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

			int oldStateForCellWithTag[3];
			oldStateForCellWithTag[1] = [[curvedMPRaxis cellWithTag:1] state];
			oldStateForCellWithTag[2] = [[curvedMPRaxis cellWithTag:2] state];
			[[curvedMPRaxis cellWithTag:1] setState:NSOffState];
			[[curvedMPRaxis cellWithTag:2] setState:NSOffState];
			[[curvedMPRaxis cellWithTag:1] setEnabled:NO];
			[[curvedMPRaxis cellWithTag:2] setEnabled:NO];

			int zPos = [[[selectedRoi zPositions] objectAtIndex:0] intValue];
			for(i=1; i < [[selectedRoi zPositions] count]; i++)
			{
				if(zPos != [[[selectedRoi zPositions] objectAtIndex:i] intValue])
				{
					[[curvedMPRaxis cellWithTag:1] setEnabled:YES];
					[[curvedMPRaxis cellWithTag:2] setEnabled:YES];
					[[curvedMPRaxis cellWithTag:1] setState:oldStateForCellWithTag[1]];
					[[curvedMPRaxis cellWithTag:2] setState:oldStateForCellWithTag[2]];
					i = [[selectedRoi zPositions] count];
				}
			}
			
			[NSApp beginSheet: curvedMPRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		}
	}
}

- (MPR2DController *)openMPR2DViewer{
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];
	// TURN OFF Thick Slab of current window... Reason? SPEEEEED !
	int i;
	[self setFusionMode: 0];
	[popFusion selectItemAtIndex:0];
	MPR2DController *		viewer = [[MPR2DController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[0] :blendingController :self];			
	for( i = 1; i < maxMovieIndex; i++)
	{
		[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
	}
	return viewer;
}

-(IBAction) MPR2DViewer:(id) sender
{
	long i;
	
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];
	[self squareDataSet: self];		// MPR2D works better if pixel are squares !

	if( [self computeInterval] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingX] == 0 ||
		[[pixList[0] objectAtIndex:0] pixelSpacingY] == 0 ||
		([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask))
	{
		[self SetThicknessInterval:sender];
	}
	else
	{
		[self MovieStop: self];
		
		MPR2DController *viewer = [appController FindViewer :@"MPR2D" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			/*
			// TURN OFF Thick Slab of current window... Reason? SPEEEEED !
			[self setFusionMode: 0];
			[popFusion selectItemAtIndex:0];
			
			
			viewer = [[MPR2DController alloc] initWithPix:pixList[0] :fileList[0] :volumeData[0] :blendingController :self];
			
			for( i = 1; i < maxMovieIndex; i++)
			{
				[viewer addMoviePixList:pixList[ i] :volumeData[ i]];
			}
			*/
			viewer = [self openMPR2DViewer];
			[viewer ApplyCLUTString:curCLUTMenu];
			float   iwl, iww;
			[imageView getWLWW:&iwl :&iww];
			[viewer setWLWW:iwl :iww];
			[viewer load3DState];
			[[viewer window] performZoom:self];
			[viewer showWindow:self];
			[[viewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[viewer window] title], [[self window] title]]];
		}
	}
}

- (OrthogonalMPRViewer *)openOrthogonalMPRViewer{
	OrthogonalMPRViewer *viewer;
	long i;	
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];
	// TURN OFF Thick Slab of current window... Reason? SPEEEEED !
	[self setFusionMode: 0];
	[popFusion selectItemAtIndex:0];
	if( blendingController)
	{
		viewer = [appController FindViewer :@"PETCT" :pixList[0]];
	}
	else
	{
		viewer = [appController FindViewer :@"OrthogonalMPR" :pixList[0]];
	}
	if (viewer)
		return viewer;
		
	viewer = [[OrthogonalMPRViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :self :nil];
	if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
	{
		if( [[self modality] isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"] == YES))
		{
			if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
				[viewer ApplyCLUTString: @"B/W Inverse"];
			else
				[viewer ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
		}
		else [viewer ApplyCLUTString:curCLUTMenu];
	}
	else [viewer ApplyCLUTString:curCLUTMenu];
	return viewer;
}

- (OrthogonalMPRPETCTViewer *)openOrthogonalMPRPETCTViewer{
	OrthogonalMPRPETCTViewer  *viewer;
	long i;	
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];
	if (viewer = [appController FindViewer :@"PETCT" :pixList[0]])
		return viewer;
	if (blendingController) {	
		viewer = [[OrthogonalMPRPETCTViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :self : blendingController];
		[[viewer window] performZoom:self];
		[[viewer CTController] ApplyCLUTString:curCLUTMenu];
		[[viewer PETController] ApplyCLUTString:[blendingController curCLUTMenu]];
		[[viewer PETCTController] ApplyCLUTString:curCLUTMenu];
		// the PETCT will display the PET CLUT in CLUTpoppuMenu
		[(OrthogonalMPRPETCTView*)[[viewer PETCTController] originalView] setCurCLUTMenu: [blendingController curCLUTMenu]];
		[(OrthogonalMPRPETCTView*)[[viewer PETCTController] xReslicedView] setCurCLUTMenu: [blendingController curCLUTMenu]];
		[(OrthogonalMPRPETCTView*)[[viewer PETCTController] yReslicedView] setCurCLUTMenu: [blendingController curCLUTMenu]];
		
		[viewer showWindow:self];
		
		float   iwl, iww;
		[imageView getWLWW:&iwl :&iww];
		[[viewer CTController] setWLWW:iwl :iww];
		[[blendingController imageView] getWLWW:&iwl :&iww];
		[[viewer PETController] setWLWW:iwl :iww];
		return viewer;
	}
	return nil;	
}

-(IBAction) orthogonalMPRViewer:(id) sender
{
	long i;
	
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
		[self MovieStop: self];
		
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
			/*
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
				//[[pcviewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[pcviewer window] title], [[self window] title]]];

				NSDate *studyDate = [[fileList[curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.study.date"];
				[[pcviewer window] setTitle: [NSString stringWithFormat:@"%@ - %@", [[fileList[curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.study.name"], [studyDate descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString] timeZone:0L locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]]];
			*/	
//  The following methods are NOT defined in their receivers!				
//				[[pcviewer CTController] setCurWLWWMenu:curWLWWMenu];
//				[[pcviewer PETCTController] setCurWLWWMenu:curWLWWMenu];
//				[[pcviewer PETController] setCurWLWWMenu:[blendingController curWLWWMenu]];
				NSLog(@"have blending controller");
				OrthogonalMPRPETCTViewer *pcviewer = [self openOrthogonalMPRPETCTViewer];
				NSDate *studyDate = [[fileList[curMovieIndex] objectAtIndex:0] valueForKeyPath:@"series.study.date"];
				[[pcviewer window] setTitle: [NSString stringWithFormat:@"%@: %@", [[pcviewer window] title], [[self window] title]]];
			}
			else
			{
			/*
				viewer = [[OrthogonalMPRViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :self :nil];
				
				if( [[pixList[0] objectAtIndex: 0] isRGB] == NO)
				{
					if( [[self modality] isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"] == YES))
					{
						if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
							[viewer ApplyCLUTString: @"B/W Inverse"];
						else
							[viewer ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];
					}
					else [viewer ApplyCLUTString:curCLUTMenu];
				}
				else [viewer ApplyCLUTString:curCLUTMenu];
			*/
				viewer = [self openOrthogonalMPRViewer];
				[[viewer window] performZoom:self];
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

- (EndoscopyViewer *)openEndoscopyViewer{
	long i;	
	[self checkEverythingLoaded];
	[self clear8bitRepresentations];
	EndoscopyViewer *viewer;
		
	viewer = [appController FindViewer :@"Endoscopy" :pixList[0]];
	if (viewer)
		return viewer;
		
	[self setFusionMode: 0];
	[popFusion selectItemAtIndex:0];
			
	viewer = [[EndoscopyViewer alloc] initWithPixList:pixList[0] :fileList[0] :volumeData[0] :blendingController : self];
	return viewer;
}


-(IBAction) endoscopyViewer:(id) sender
{
	long i;
	
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
		[self MovieStop: self];
		
		EndoscopyViewer *viewer;
		
		viewer = [appController FindViewer :@"Endoscopy" :pixList[0]];
		
		if( viewer)
		{
			[[viewer window] makeKeyAndOrderFront:self];
		}
		else
		{
			// TURN OFF Thick Slab of current window... Reason? SPEEEEED !
			//[self setFusionMode: 0];
			//[popFusion selectItemAtIndex:0];
			
			viewer = [self openEndoscopyViewer];
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
	[browserWindow loadNextPatient:[fileList[0] objectAtIndex:0] :[sender tag] :self :YES keyImagesOnly: displayOnlyKeyImages];
}

-(IBAction) loadSerie:(id) sender
{
	// tag=-1 backwards, tag=1 forwards, tag=3 ???
	if( [sender tag] == 3)
	{
		[[sender selectedItem] setImage:0L];
		
		[browserWindow loadSeries :[[sender selectedItem] representedObject] :self :YES keyImagesOnly: displayOnlyKeyImages];
	}
	else
	{
		[browserWindow loadNextSeries:[fileList[0] objectAtIndex:0] :[sender tag] :self :YES keyImagesOnly: displayOnlyKeyImages];

	}
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
			while( [ThreadLoadImageLock tryLock] == NO)
			{
				[browserWindow bonjourRunLoop: self];
				
			}
		}
		else
		{
			while( [ThreadLoadImageLock tryLock] == NO) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
		}
		
		[ThreadLoadImageLock unlock];
		
		while( ThreadLoadImage)
		{
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];		// To be sure that PerformOnMainThread has been called !
		}
		
		[splash close];
		[splash release];
		
		[self setWindowTitle: self];
	}
	
	[self computeInterval];
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
	
	[self buildMatrixPreview: NO];
	
	[imageView setNeedsDisplay:YES];
}

- (IBAction) keyImageDisplayButton:(id) sender
{
	NSManagedObject	*series = [[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] valueForKey:@"series"];
	long i;
	
	[self checkEverythingLoaded];
	
	displayOnlyKeyImages = [keyImagePopUpButton indexOfSelectedItem];
	if( series)
	{
		if(!displayOnlyKeyImages)
		{
			// ALL IMAGES ARE DISPLAYED
			//[keyImageDisplay setTag: 0];
			//[keyImageDisplay setTitle: NSLocalizedString(@"Key Images", nil)];
			
			NSArray	*images = [browserWindow childrenArray: series];
			[browserWindow openViewerFromImages :[NSArray arrayWithObject: images] movie: NO viewer :self keyImagesOnly: displayOnlyKeyImages];
			//[browserWindow openViewerFromImages :[NSArray arrayWithObject: images] movie: NO viewer :self keyImagesOnly: tag];
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
				[keyImagePopUpButton selectItemAtIndex: 0];
			}
			else
			{
				//[keyImageDisplay setTag: 1];
				//[keyImageDisplay setTitle: NSLocalizedString(@"All images", nil)];
				[browserWindow openViewerFromImages :[NSArray arrayWithObject: keyImagesArray] movie: NO viewer :self keyImagesOnly: displayOnlyKeyImages];
				//[browserWindow openViewerFromImages :[NSArray arrayWithObject: keyImagesArray] movie: NO viewer :self keyImagesOnly: tag];
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
	if( [fileList[ curMovieIndex] count] != 1)
	{
		if( [fileList[ curMovieIndex] objectAtIndex: 0] == [fileList[ curMovieIndex] lastObject])
		{
			[keyImageCheck setState: NSOffState];
			[keyImageCheck setEnabled: NO];
			[keyImageDisplay setEnabled: NO];
			[keyImagePopUpButton setEnabled: NO];
			
			return;
		}
	}
	
	[keyImageDisplay setEnabled: YES];
	[keyImageCheck setEnabled: YES];
	[keyImagePopUpButton setEnabled: YES];
	
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

- (BOOL)isKeyImage:(int)index{
	return [[[fileList[curMovieIndex] objectAtIndex:[self indexForPix:index]] valueForKey:@"isKeyImage"] boolValue];
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
	
	if( [sender tag] == 1) //series
	{
		[[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] setValue:[CommentsEditField stringValue] forKeyPath:@"series.comment"];
		
		if([browserWindow isCurrentDatabaseBonjour])
		{
			[browserWindow setBonjourDatabaseValue:[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] value:[CommentsEditField stringValue] forKey:@"series.comment"];
		}
		
		[[browserWindow databaseOutline] reloadData];
		
		if( [[CommentsEditField stringValue] isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"No Comments", nil)];
		else [CommentsField setTitle: [CommentsEditField stringValue]];
		
		[self buildMatrixPreview: NO];
	}
	else if( [sender tag] == 2) //study
	{
		[[fileList[ curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] setValue:[CommentsEditField stringValue] forKeyPath:@"series.study.comment"];
		
		if([browserWindow isCurrentDatabaseBonjour])
		{
			[browserWindow setBonjourDatabaseValue:[fileList[curMovieIndex] objectAtIndex:[self indexForPix:[imageView curImage]]] value:[CommentsEditField stringValue] forKey:@"series.study.comment"];
		}
		
		[[browserWindow databaseOutline] reloadData];
		
		//if( [[CommentsEditField stringValue] isEqualToString:@""]) [CommentsField setTitle: NSLocalizedString(@"No Comments", nil)];
		//else [CommentsField setTitle: [CommentsEditField stringValue]];
		
		[self buildMatrixPreview: NO];
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
	[self buildMatrixPreview: NO];
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

#pragma mark-
#pragma mark Key Objects
- (IBAction)createKeyObjectNote:(id)sender{
	id study = [[imageView seriesObj] valueForKey:@"study"];
	KeyObjectController *controller = [[KeyObjectController alloc] initWithStudy:(id)study];
	[NSApp beginSheet:[controller window]  modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(keyObjectSheetDidEnd:returnCode:contextInfo:) contextInfo:controller];
}

- (void)keyObjectSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(id)contextInfo{
	[contextInfo autorelease];
	[keyImagePopUpButton selectItemAtIndex:displayOnlyKeyImages];
}

- (IBAction)keyObjectNotes:(id)sender{
}

- (BOOL)displayOnlyKeyImages{
	return displayOnlyKeyImages;
}

#pragma mark-
#pragma mark report

- (IBAction)deleteReport:(id)sender;
{
	[browserWindow deleteReport:sender];
	[self updateReportToolbarIcon:nil];
}

- (IBAction)generateReport:(id)sender;
{
	[self updateReportToolbarIcon:nil];
	[browserWindow generateReport:sender];
	[self updateReportToolbarIcon:nil];
}

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

- (void)updateReportToolbarIcon:(NSNotification *)note
{
	long i;
	NSToolbarItem *item;
	NSArray *toolbarItems = [toolbar items];
	for(i=0; i<[toolbarItems count]; i++)
	{
		item = [toolbarItems objectAtIndex:i];
		if ([[item itemIdentifier] isEqualToString:ReportToolbarItemIdentifier])
		{
			[toolbar removeItemAtIndex:i];
			[toolbar insertItemWithItemIdentifier:ReportToolbarItemIdentifier atIndex:i];
		}
	}
}

- (void)setToolbarReportIconForItem:(NSToolbarItem *)item;
{
	NSMutableArray *pagesTemplatesArray = [Reports pagesTemplatesList];

	NSManagedObject *studySelected = [[fileList[0] objectAtIndex:0] valueForKeyPath:@"series.study"];
	
	if([pagesTemplatesArray count]>1 && [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue]==2 && ![[NSFileManager defaultManager] fileExistsAtPath:[studySelected valueForKey:@"reportURL"]])
	{
		[item setView:reportTemplatesView];
		[item setMinSize:NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
		[item setMaxSize:NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
	}
	else
	{
		[item setImage:[self reportIcon]];
	}
}

- (void)reportToolbarItemWillPopUp:(NSNotification *)notif;
{
	if([[notif object] isEqualTo:reportTemplatesListPopUpButton])
	{
		NSMutableArray *pagesTemplatesArray = [Reports pagesTemplatesList];
		[reportTemplatesListPopUpButton removeAllItems];
		[reportTemplatesListPopUpButton addItemWithTitle:@""];
		[reportTemplatesListPopUpButton addItemsWithTitles:pagesTemplatesArray];
		[reportTemplatesListPopUpButton setAction:@selector(generateReport:)];
	}
}


#pragma mark-
#pragma mark current Core Data Objects
- (NSManagedObject *)currentStudy{
	return [[imageView seriesObj] valueForKey:@"study"];
}
- (NSManagedObject *)currentSeries{
	return [imageView seriesObj];
}
- (NSManagedObject *)currentImage{
	return [imageView imageObj];
}


#pragma mark-
#pragma mark Convience methods for accessing values in the current imageView
-(float)curWW{
	return [imageView curWW];
}

-(float)curWL{
	return [imageView curWL];
}

- (void)setWL:(float)cwl  WW:(float)cww{
	[imageView setWLWW:cwl :cww];
}

- (BOOL)xFlipped{
		return [imageView xFlipped];
}
	
- (BOOL)yFlipped{
	return [imageView yFlipped];
}

- (float)rotation{
	return [imageView angle];
}

- (void)setRotation:(float)rotation{
	[imageView setRotation:rotation];
}

- (float)scaleValue{
	return [imageView scaleValue];
}

- (void)setScaleValue:(float)scaleValue{
	[imageView setScaleValue:scaleValue];
}

- (void)setYFlipped:(BOOL) v{
	[imageView setYFlipped:(BOOL) v];
}
- (void)setXFlipped:(BOOL) v{
	[imageView setXFlipped:(BOOL) v];
}

- (SeriesView *) seriesView{
	return seriesView;
}

- (void)setImageRows:(int)rows columns:(int)columns{
	[seriesView setImageViewMatrixForRows:(int)rows  columns:columns];
}


@end
