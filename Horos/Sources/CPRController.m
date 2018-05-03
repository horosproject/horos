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

#import "options.h"

#import "CPRController.h"
#import "BrowserController.h"
#import "Wait.h"
#import "DICOMExport.h"
#import "DicomImage.h"
#import "ROI.h"
#import "Photos.h"
#import "Notifications.h"
#import "ROIWindow.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "CPRCurvedPath.h"
#import "CPRDisplayInfo.h"
#import "N3BezierPath.h"
#import "CPRView.h"
#import "CPRVolumeData.h"
#import "N3BezierCoreAdditions.h"
#import "CPRTransverseView.h"
#import "CPRGeneratorRequest.h"
#import "CPRGenerator.h"
#import "CPRUnsignedInt16ImageRep.h"
#import "CPRMPRDCMView.h"
#import "N2OpenGLViewWithSplitsWindow.h"
#import "AppController.h"
#import "DicomDatabase.h"
#import <N2Debug.h>
#import "PluginManager.h"
#import "DicomDatabase.h"

static NSString *MPRPlaneObservationContext = @"MPRPlaneObservationContext";


extern void setvtkMeanIPMode( int m);
extern short intersect3D_2Planes( float *Pn1, float *Pv1, float *Pn2, float *Pv2, float *u, float *iP);
static float deg2rad = M_PI / 180.0; 

@interface CPRController ()
@property (nonatomic, readwrite, copy) CPRCurvedPath *curvedPath;
@property (readwrite, copy) CPRDisplayInfo *displayInfo;
@end


@implementation CPRController

@synthesize selectedInterpolationMode = _selectedInterpolationMode;
@synthesize clippingRangeThickness, clippingRangeMode, mousePosition, mouseViewID, originalPix, wlwwMenuItems, LOD;
@synthesize colorAxis1, colorAxis2, colorAxis3, displayMousePosition, movieRate, blendingPercentage, horizontalSplit1, horizontalSplit2, verticalSplit, lowLOD;
@synthesize mprView1, mprView2, mprView3, curMovieIndex, maxMovieIndex, blendingMode, blendingModeAvailable, highResolutionMode;
@synthesize curvedPath, displayInfo, curvedPathCreationMode, curvedPathColor, straightenedCPRAngle, cprType, cprView;//, assistantPathMode;
@synthesize topTransverseView, middleTransverseView, bottomTransverseView;

// export related synthesize
@synthesize exportSeriesName;
@synthesize exportImageFormat;
@synthesize exportSequenceType;
@synthesize exportSeriesType;
@synthesize exportRotationSpan;
@synthesize exportReverseSliceOrder;
//@synthesize exportSlabThinknessSameAsSlabThickness;
@synthesize exportSlabThickness, exportNumberOfRotationFrames;
@synthesize exportSliceIntervalSameAsVolumeSliceInterval;
@synthesize exportSliceInterval, exportTransverseSliceInterval;
@synthesize dcmIntervalMin, dcmIntervalMax;

+ (double) angleBetweenVector:(float*) a andPlane:(float*) orientation
{
	double sc[ 2];
	
    //	double la = sqrt( a[0]*a[0] + a[1]*a[1] + a[2]*a[2]);
    //	double lo = sqrt( orientation[0]*orientation[0] + orientation[1]*orientation[1] + orientation[2]*orientation[2]);
    //	
    //	sc[ 0 ] = a[ 0]/la * orientation[ 0 ]/lo + a[ 1]/la * orientation[ 1 ]/lo + a[ 2]/la * orientation[ 2 ]/lo;
    //	sc[ 1 ] = a[ 0]/la * orientation[ 3 ]/lo + a[ 1]/la * orientation[ 4 ]/lo + a[ 2]/la * orientation[ 5 ]/lo;
	
	
	sc[ 0 ] = a[ 0] * orientation[ 0 ] + a[ 1] * orientation[ 1 ] + a[ 2] * orientation[ 2 ];
	sc[ 1 ] = a[ 0] * orientation[ 3 ] + a[ 1] * orientation[ 4 ] + a[ 2] * orientation[ 5 ];
	
	return ((atan2( sc[1], sc[0])) / deg2rad);
}

- (DCMPix*) emptyPix: (DCMPix*) oP width: (long) w height: (long) h
{
	long size = sizeof( float) * w * h;
	float *imagePtr = malloc( size);
	DCMPix *emptyPix = [[DCMPix alloc] initWithData: imagePtr :32 :w :h :[oP pixelSpacingX] :[oP pixelSpacingY] :[oP originX] :[oP originY] :[oP originZ]];
	free( imagePtr);
	
	[emptyPix setImageObjectID: [oP imageObjectID]];
	[emptyPix setSrcFile: [oP srcFile]];
	[emptyPix setAnnotationsDictionary: [oP annotationsDictionary]];
	
	return [emptyPix autorelease];
}

- (void) setHighResolutionMode: (BOOL) newValue
{
    highResolutionMode = newValue;
    
    if( highResolutionMode)
    {
        if( HR_PixList == nil)
        {
            HR_PixList = [[NSMutableArray array] retain];
            HR_FileList = [[NSMutableArray array] retain];
            HR_Data = nil;
            
            DCMPix* firstObject = [pixList[0] objectAtIndex:0];
            float originalSliceInterval = [firstObject sliceInterval];
            
            float factor = 1.0 / 1.5;
            
            WaitRendering *www = [[[WaitRendering alloc] init:NSLocalizedString( @"Computing High Resolution data...", nil)] autorelease];
            [www start];
            
            BOOL succeed = [ViewerController resampleDataFromPixArray: pixList[0] fileArray: filesList[0] inPixArray: HR_PixList fileArray: HR_FileList data: &HR_Data withXFactor: factor yFactor: factor zFactor: factor];
            
            [www end];
			[www close];
            
            if( succeed == NO)
            {
                if( NSRunAlertPanel( NSLocalizedString(@"32-bit",nil), NSLocalizedString( @"Cannot compute the high resolution data.\r\rUpgrade to Horos 64-bit or Horos MD to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Horos 64-bit", nil), nil) == NSAlertAlternateReturn)
                    [[AppController sharedAppController] osirix64bit: self];
                
                [HR_PixList release];
                HR_PixList = nil;
                
                [HR_FileList release];
                HR_FileList = nil;
                
                HR_Data = nil;
                
                [self performSelector: @selector(setHighResolutionMode:) withObject: nil afterDelay: 0.1];
            }
            else
            {
                for( DCMPix *p in HR_PixList)
                    p.sliceInterval = originalSliceInterval*factor;
                
                [HR_Data retain];
            }
        }
        
        if( HR_PixList)
        {
            [cprVolumeData release];
            
            cprVolumeData = [[CPRVolumeData alloc] initWithWithPixList:HR_PixList volume:HR_Data];
            cprView.volumeData = cprVolumeData;
            topTransverseView.volumeData = cprView.volumeData;
            middleTransverseView.volumeData = cprView.volumeData;
            bottomTransverseView.volumeData = cprView.volumeData;
        }
    }
    else
    {
        [cprVolumeData release];
        
        cprVolumeData = [[CPRVolumeData alloc] initWithWithPixList: pixList[0] volume: volumeData[0]];
        cprView.volumeData = cprVolumeData;
        topTransverseView.volumeData = cprView.volumeData;
        middleTransverseView.volumeData = cprView.volumeData;
        bottomTransverseView.volumeData = cprView.volumeData;
    }
    
    self.straightenedCPRAngle = self.straightenedCPRAngle + 0.1; // To force the update...
}

- (id)initWithDCMPixList:(NSMutableArray*)pix
               filesList:(NSMutableArray*)files
              volumeData:(NSData*)volume
        viewerController:(ViewerController*)viewer
   fusedViewerController:(ViewerController*)fusedViewer;
{
	@try
	{
        self->isInitializing = YES;
        
        self->selectedInterpolationMode = CPRInterpolationModeNearestNeighbor;
        
		if( [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"] == annotNone)
			[[NSUserDefaults standardUserDefaults] setInteger: annotGraphics forKey: @"ANNOTATIONS"];
		
		viewer2D = viewer;
		
		self = [super initWithWindowNibName:@"CPR"];
				
		originalPix = [pix lastObject];
		
		if( [originalPix isRGB])
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"RGB",nil), NSLocalizedString( @"RGB images are not supported.",nil), NSLocalizedString(@"OK",nil), nil, nil);
            [self autorelease];
            
			return nil;
		}
		
        [[self window] setWindowController: self];
		[[[self window] toolbar] setDelegate: self];
        
		pixList[0] = pix;
		filesList[0] = files;
		volumeData[0] = volume;
		
		fusedViewer2D = fusedViewer;
		clippingRangeMode = 1;
		LOD = 1;
		if( LOD < 1) LOD = 1;
		
		if( fusedViewer2D)
			self.blendingModeAvailable = YES;
		
		self.displayMousePosition = [[NSUserDefaults standardUserDefaults] boolForKey: @"MPRDisplayMousePosition"];
		self.maxMovieIndex = 0;
		
		[self updateToolbarItems];
		
		for( int i = 0; i < [popupRoi numberOfItems]; i++)
			[[popupRoi itemAtIndex: i] setImage: [self imageForROI: [[popupRoi itemAtIndex: i] tag]]];
		
        int dim[3];
        DCMPix* firstObject = [pix objectAtIndex:0];
        dim[0] = [firstObject pwidth];
        dim[1] = [firstObject pheight];
        dim[2] = [pix count];
        float spacing[3];
        spacing[0]=[firstObject pixelSpacingX];
        spacing[1]=[firstObject pixelSpacingY];
        float sliceThickness = [firstObject sliceInterval];   
        if( sliceThickness == 0)
        {
            NSLog(@"Slice interval = slice thickness!");
            sliceThickness = [firstObject sliceThickness];
        }
        spacing[2]=sliceThickness;
        float resamplesize=spacing[0];
        if(dim[0]>256 || dim[1]>256)
        {
            if(spacing[0]*(float)dim[0]>spacing[1]*(float)dim[1])
                resamplesize = spacing[0]*(float)dim[0]/256.0;
            else {
                resamplesize = spacing[1]*(float)dim[1]/256.0;
            }
            
        }
        assistant = [[FlyAssistant alloc] initWithVolume:(float*)[volume bytes] WidthDimension:dim Spacing:spacing ResampleVoxelSize:resamplesize];
        [assistant setCenterlineResampleStepLength:3.0];
        centerline = [[NSMutableArray alloc] init];
        nodeRemovalCost = [[NSMutableArray alloc] init];
        delHistory = [[NSMutableArray alloc] init];
        delNodes = [[NSMutableArray alloc] init];
        curvedPath = [[CPRCurvedPath alloc] init];
        displayInfo = [[CPRDisplayInfo alloc] init];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0], @"CPRColorR",
                                                                                                           [NSNumber numberWithFloat:1], @"CPRColorG",
                                                                                                           [NSNumber numberWithFloat:0], @"CPRColorB", nil]];
		self.curvedPathCreationMode = YES;
        cprVolumeData = [[CPRVolumeData alloc] initWithWithPixList:pix volume:volume];
        cprView.volumeData = cprVolumeData;
        mprView1.delegate = self;
        mprView2.delegate = self;
        mprView3.delegate = self;
        cprView.delegate = self;
        mprView1.curvedPath = curvedPath;
        mprView2.curvedPath = curvedPath;
        mprView3.curvedPath = curvedPath;
		cprView.curvedPath = curvedPath;
        mprView1.displayInfo = displayInfo;
        mprView2.displayInfo = displayInfo;
        mprView3.displayInfo = displayInfo;
        topTransverseView.displayInfo = displayInfo;
        middleTransverseView.displayInfo = displayInfo;
        bottomTransverseView.displayInfo = displayInfo;
		cprView.displayInfo = displayInfo;
        topTransverseView.delegate = self;
        topTransverseView.curvedPath = curvedPath;
        topTransverseView.sectionType = CPRTransverseViewLeftSectionType;
        middleTransverseView.delegate = self;
        middleTransverseView.curvedPath = curvedPath;
        middleTransverseView.sectionType = CPRTransverseViewCenterSectionType;
        bottomTransverseView.delegate = self;
        bottomTransverseView.curvedPath = curvedPath;
        bottomTransverseView.sectionType = CPRTransverseViewRightSectionType;
        topTransverseView.sectionWidth = cprView.generatedHeight;
        middleTransverseView.sectionWidth = cprView.generatedHeight;
        bottomTransverseView.sectionWidth = cprView.generatedHeight;
        topTransverseView.volumeData = cprView.volumeData;
        middleTransverseView.volumeData = cprView.volumeData;
        bottomTransverseView.volumeData = cprView.volumeData;
        
		DCMPix *emptyPix = [self emptyPix: originalPix width: 100 height: 100];
		[mprView1 setDCMPixList: [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] roiList: nil firstImage:0 type:'i' reset:YES];
		[mprView1 setFlippedData: [[viewer imageView] flippedData]];
		
		emptyPix = [self emptyPix: originalPix width: 100 height: 100];
		[mprView2 setDCMPixList: [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] roiList: nil firstImage:0 type:'i' reset:YES];
		[mprView2 setFlippedData: [[viewer imageView] flippedData]];
		
		emptyPix = [self emptyPix: originalPix width: 100 height: 100];
		[mprView3 setDCMPixList: [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] roiList: nil firstImage:0 type:'i' reset:YES];
		[mprView3 setFlippedData: [[viewer imageView] flippedData]];
		
//		emptyPix = [self emptyPix: originalPix width: 100 height: 100];
//		[cprView setDCMPixList: [NSMutableArray arrayWithObject: emptyPix] filesList: [NSArray arrayWithObject: [files lastObject]] roiList: nil firstImage:0 type:'i' reset:YES];
//		[cprView setFlippedData: [[viewer imageView] flippedData]];
//		
		if( fusedViewer2D)
		{
			blendedMprView1 = [[DCMView alloc] initWithFrame: [mprView1 frame]];
			blendedMprView2 = [[DCMView alloc] initWithFrame: [mprView2 frame]];
			blendedMprView3 = [[DCMView alloc] initWithFrame: [mprView3 frame]];
			
			emptyPix = [[[[fusedViewer2D imageView] curDCM] copy] autorelease];
			[blendedMprView1 setPixels: [NSMutableArray arrayWithObject: emptyPix] files: [NSArray arrayWithObject: [files lastObject]] rois:nil firstImage:0 level:'i' reset:YES];
			
			emptyPix = [[[[fusedViewer2D imageView] curDCM] copy] autorelease];
			[blendedMprView2 setPixels:  [NSMutableArray arrayWithObject: emptyPix] files: [NSArray arrayWithObject: [files lastObject]] rois:nil firstImage:0 level:'i' reset:YES];
			
			emptyPix = [[[[fusedViewer2D imageView] curDCM] copy] autorelease];
			[blendedMprView3 setPixels:  [NSMutableArray arrayWithObject: emptyPix] files: [NSArray arrayWithObject: [files lastObject]] rois:nil firstImage:0 level:'i' reset:YES];
			
			unsigned char *aR, *aG, *aB;
			[[fusedViewer2D imageView] getCLUT: &aR :&aG :&aB];
			
			[blendedMprView1 setCLUT: aR :aG :aB];
			[blendedMprView2 setCLUT: aR :aG :aB];
			[blendedMprView3 setCLUT: aR :aG :aB];
			
			[mprView1 setBlending: blendedMprView1];
			[mprView2 setBlending: blendedMprView2];
			[mprView3 setBlending: blendedMprView3];
			
			[mprView1 setBlendingFactor: 0.5];
			[mprView2 setBlendingFactor: 0.5];
			[mprView3 setBlendingFactor: 0.5];
			
			[blendedMprView1 setWLWW: [[fusedViewer2D imageView] curDCM].wl :[[fusedViewer2D imageView] curDCM].ww];
			[blendedMprView2 setWLWW: [[fusedViewer2D imageView] curDCM].wl :[[fusedViewer2D imageView] curDCM].ww];
			[blendedMprView3 setWLWW: [[fusedViewer2D imageView] curDCM].wl :[[fusedViewer2D imageView] curDCM].ww];
			
			self.blendingPercentage = 50;
			self.blendingMode = 0;
		}
        
        hiddenVRController = [[VRController alloc] initWithPix:pix
                                                              :files
                                                              :volume
                                                              :fusedViewer2D
                                                              :viewer
                                                         style:@"noNib"
                                                          mode:@"MIP"];
		[hiddenVRController retain];
		
		// To avoid the "invalid drawable" message
		[[hiddenVRController window] setLevel: 0];
		[[hiddenVRController window] orderBack: self];
		//[[hiddenVRController window] orderOut: self];
		
		[hiddenVRController load3DState];
		
		hiddenVRView = [hiddenVRController view];
		[hiddenVRView setClipRangeActivated: YES];
		[hiddenVRView resetImage: self];
		[hiddenVRView setLOD: 20];
		hiddenVRView.keep3DRotateCentered = YES;
		
		[mprView1 setVRView: hiddenVRView viewID: 1];
		[mprView1 setWLWW: [[viewer imageView] curWL] :[[viewer imageView] curWW]];
		
		[mprView2 setVRView: hiddenVRView viewID: 2];
		[mprView2 setWLWW: [[viewer imageView] curWL] :[[viewer imageView] curWW]];
		
		[mprView3 setVRView: hiddenVRView viewID: 3];
		[mprView3 setWLWW: [[viewer imageView] curWL] :[[viewer imageView] curWW]];
		
		[hiddenVRView setWLWW: [[viewer imageView] curWL] :[[viewer imageView] curWW]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultToolModified:) name:OsirixDefaultToolModifiedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateWLWWMenu:) name:OsirixUpdateWLWWMenuNotification object:nil];
		curWLWWMenu = [[viewer2D curWLWWMenu] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateCLUTMenu:) name:OsirixUpdateCLUTMenuNotification object: nil];
		curCLUTMenu = [[viewer2D curCLUTMenu] retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
		
		startingOpacityMenu = [[viewer2D curOpacityMenu] retain];
		curOpacityMenu = [startingOpacityMenu retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateOpacityMenu:) name:OsirixUpdateOpacityMenuNotification object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:OsirixCloseViewerNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(changeWLWW:) name: OsirixChangeWLWWNotification object: nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(updateCurvedPathCost) name:OsirixUpdateCurvedPathCostNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(resetSlider) name:OsirixDeletedCurvedPathNotification object: nil];

//        [shadingCheck setAction:@selector(switchShading:)];
//        [shadingCheck setTarget:self];
		
//		self.dcmNumberOfFrames = 50;
//		self.dcmRotationDirection = 0;
//		self.dcmRotation = 360;
//		self.dcmSeriesName = @"CPR";
        
        self.exportSeriesName = @"CPR";;
        self.exportSequenceType = CPRCurrentOnlyExportSequenceType;
        self.exportSeriesType = CPRRotationExportSeriesType;
        self.exportRotationSpan = CPR180ExportRotationSpan;
        self.exportReverseSliceOrder = NO;
        
		float r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3;
		r1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_RED"];
		g1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_GREEN"];
		b1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_BLUE"];
		a1 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_1_ALPHA"];
		
		r2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_RED"];
		g2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_GREEN"];
		b2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_BLUE"];
		a2 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_2_ALPHA"];
		
		r3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_RED"];
		g3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_GREEN"];
		b3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_BLUE"];
		a3 = [[NSUserDefaults standardUserDefaults] floatForKey:@"MPR_AXIS_3_ALPHA"];
		
		if(r1==0.0 && g1==0.0 && b1==0.0 && a1==0.0 && r2==0.0 && g2==0.0 && b2==0.0 && a2==0.0 && r3==0.0 && g3==0.0 && b3==0.0 && a3==0.0)
		{
			r1 = 1.0; g1 = 0.67; b1 = 0.0; a1 = 0.8;
			r2 = 0.6; g2 = 0.0; b2 = 1.0; a2 = 0.8;
			r3 = 0.0; g3 = 0.5; b3 = 1.0; a3 = 0.8;
		}
		
		self.colorAxis1 = [NSColor colorWithDeviceRed:r1 green:g1 blue:b1 alpha:a1];
		self.colorAxis2 = [NSColor colorWithDeviceRed:r2 green:g2 blue:b2 alpha:a2];
		self.colorAxis3 = [NSColor colorWithDeviceRed:r3 green:g3 blue:b3 alpha:a3];
		
		cprView.orangePlaneColor = self.colorAxis1;
		cprView.purplePlaneColor = self.colorAxis2;
		cprView.bluePlaneColor = self.colorAxis3;
		
		[mprView1 addObserver:self forKeyPath:@"plane" options:0 context:MPRPlaneObservationContext];
		[mprView2 addObserver:self forKeyPath:@"plane" options:0 context:MPRPlaneObservationContext];
		[mprView3 addObserver:self forKeyPath:@"plane" options:0 context:MPRPlaneObservationContext];
		
		[[NSColorPanel sharedColorPanel] setShowsAlpha: YES];
		
		undoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
		redoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
		
		[self setToolIndex: tWL];
        
        self.cprType = [[NSUserDefaults standardUserDefaults] integerForKey: @"SavedCPRType"];
        
        [[self window] registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
        
        [self setupToolbar];
	}
	
	@catch (NSException *e)
	{
		NSLog( @"CPR Init failed: %@", e);
		return nil;
	}
	
	return self;
}

- (void) delayedFullLODRendering:(id) sender
{
	if( windowWillClose) return;
	
	if( hiddenVRView.lowResLODFactor > 1 || sender != nil)
	{
		lowLOD = NO;
        
		[self updateViewsAccordingToFrame: sender];
        
		lowLOD = YES;
	}
}

- (void) updateViewsAccordingToFrame:(id) sender	// see setFrame in CPRMPRDCMView.m
{
	if( windowWillClose) return;
	
	id view = [[self window] firstResponder];
	
	[mprView1 camera].forceUpdate = YES;
	[mprView2 camera].forceUpdate = YES;
	[mprView3 camera].forceUpdate = YES;
	
	if( sender)
	{
		if( [[self window] firstResponder] != sender)
			[[self window] makeFirstResponder: sender];
		[sender restoreCamera];
		[sender updateViewMPR];
	}
	else
	{
		CPRMPRDCMView *selectedView = [self selectedView];
		if( [[self window] firstResponder] != selectedView)
			[[self window] makeFirstResponder: selectedView];
		[selectedView restoreCamera];
		[selectedView updateViewMPR];
	}
	
	if( view)
		if( [[self window] firstResponder] != view)
			[[self window] makeFirstResponder: view];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
}

- (void) showWindow:(id) sender
{
	mprView1.dontUseAutoLOD = YES;
	mprView2.dontUseAutoLOD = YES;
	mprView3.dontUseAutoLOD = YES;
	mprView1.LOD = 40;
	mprView2.LOD = 40;
	mprView3.LOD = 40;
	
	BOOL c = [[NSUserDefaults standardUserDefaults] boolForKey: @"syncZoomLevelMPR"];
	
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"syncZoomLevelMPR"];
	
	// Default Init
	[self setClippingRangeMode: 1]; // MIP
    
    if ([originalPix sliceInterval] > 1.0f)
        [self setClippingRangeThicknessInMm:1.0f];
    else
        [self setClippingRangeThicknessInMm:[originalPix sliceInterval]];
    
    //self.clippingRangeThickness = 0.5;
	
    int min = [self getClippingRangeThicknessInMm] * 100.;
    self.dcmIntervalMin = (float) min / 100.;
    self.dcmIntervalMin -= 0.001;
    if( self.dcmIntervalMin < 0.01)
        self.dcmIntervalMin = 0.01;
    
    self.dcmIntervalMax = 100;
    
	[[self window] makeFirstResponder: mprView1];
	[mprView1.vrView resetImage: self];
	
	mprView1.angleMPR = 0;
	mprView2.angleMPR = 0;
	mprView3.angleMPR = 0;
    
	[mprView1 updateViewMPROnLoading:isInitializing];
	
	mprView2.camera.viewUp = [Point3D pointWithX:0 y:-1 z:0];
	
	[[self window] makeFirstResponder: mprView3];
	mprView3.camera.viewUp = [Point3D pointWithX:0 y:0 z:1];
	mprView3.camera.rollAngle = 0;
	mprView3.angleMPR = 0;
	mprView3.camera.parallelScale /= 1.5;
	[mprView3 restoreCamera];
	[mprView3 updateViewMPROnLoading:isInitializing];
	
	[super showWindow: sender];
	
	[self setTool: toolsMatrix];
	
	if( c == NO)
		[[NSUserDefaults standardUserDefaults] setBool: c forKey: @"syncZoomLevelMPR"];
    
	mprView1.dontUseAutoLOD = NO;
	mprView2.dontUseAutoLOD = NO;
	mprView3.dontUseAutoLOD = NO;
	
	[self setLOD: 1];
    
    [self setViewsPosition:NormalPosition];
    
    //
	
	[self CPRViewWillEditCurvedPath: mprView1];
	while( mprView1.curvedPath.nodes.count > 0)
		[mprView1.curvedPath removeNodeAtIndex: 0];
	[self CPRViewDidUpdateCurvedPath: mprView1];
	[self CPRViewDidEditCurvedPath: mprView1];
    
    // Restore previous path, if it exists
    
    NSString *path = [[[BrowserController currentBrowser] database] statesDirPath];
    
	if (![[NSFileManager defaultManager] fileExistsAtPath: path])
        [[NSFileManager defaultManager] createDirectoryAtPath: path withIntermediateDirectories:YES attributes:nil error:NULL];
    
    path = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"CPR-%@", [[[viewer2D fileList: 0] objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
	
    if( path)
        [self loadBezierPathFromFile: path];
    
    // Enable VTK Render
    
    self->isInitializing = NO;
    
    [[hiddenVRController window] orderOut: self];
}


- (CPRInterpolationMode) selectedInterpolationMode
{
    @synchronized(self)
    {
        return self->selectedInterpolationMode;
    }
}


- (NSNumber*) interpolationMode
{
    return [NSNumber numberWithInteger:self.selectedInterpolationMode];
}


- (void) setInterpolationMode:(NSNumber*)value
{
    self.selectedInterpolationMode = [value integerValue];
}


- (void) setSelectedInterpolationMode:(CPRInterpolationMode) value
{
    @synchronized(self)
    {
        if (self.selectedInterpolationMode != value)
        {
            self->selectedInterpolationMode = value;
            [[NSUserDefaults standardUserDefaults] setInteger:self.selectedInterpolationMode
                                                       forKey:@"selectedCPRInterpolationMode"];
            [ self->topTransverseView    _setNeedsNewRequest ];
            [ self->middleTransverseView _setNeedsNewRequest ];
            [ self->bottomTransverseView _setNeedsNewRequest ];
            [ self->cprView _setNeedsNewRequest ];
        }
    }
}

-(void) awakeFromNib
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"selectedCPRInterpolationMode"])
    {
        [self willChangeValueForKey:@"interpolationMode"];
        self->selectedInterpolationMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedCPRInterpolationMode"];
        if (self->selectedInterpolationMode != CPRInterpolationModeNearestNeighbor &&
            self->selectedInterpolationMode != CPRInterpolationModeCubic)
        {
            self->selectedInterpolationMode = CPRInterpolationModeCubic;
        }
        [self didChangeValueForKey:@"interpolationMode"];
    }
    else
    {
        self->selectedInterpolationMode = CPRInterpolationModeCubic;
        [[NSUserDefaults standardUserDefaults] setInteger:self.selectedInterpolationMode
                                                   forKey:@"selectedCPRInterpolationMode"];
    }
    
    
	NSScreen *s = [viewer2D get3DViewerScreen: viewer2D];
	
    [horizontalSplit1 setDelegate: self];
    [horizontalSplit2 setDelegate: self];
    [verticalSplit setDelegate: self];
    
	if( [s frame].size.height > [s frame].size.width)
	{
		[horizontalSplit1 setVertical: NO];
		[horizontalSplit2 setVertical: NO];
		[verticalSplit setVertical: YES];
	}
	
//    [shadingsPresetsController setWindowController: self];
//    [shadingsPresetsController addObserver:self forKeyPath:@"selectedObjects" options:0 context:CPRController.class];
    
//    [shadingCheck setAction:@selector(switchShading:)];
//    [shadingCheck setTarget:self];
}

-(void)splitViewWillResizeSubviews:(NSNotification *)notification
{
    N2OpenGLViewWithSplitsWindow *window = (N2OpenGLViewWithSplitsWindow*)self.window;
	
	if( [window respondsToSelector:@selector(disableUpdatesUntilFlush)])
		[window disableUpdatesUntilFlush];
}

- (void) dealloc
{
//    [shadingsPresetsController removeObserver:self forKeyPath:@"selectedObjects" context:CPRController.class];
    
    [cprVolumeData invalidateData];
    [cprVolumeData release];
    
	[mprView1 removeObserver:self forKeyPath:@"plane"];
	[mprView2 removeObserver:self forKeyPath:@"plane"];
	[mprView3 removeObserver:self forKeyPath:@"plane"];
	
	[mousePosition release];
	[wlwwMenuItems release];
	[toolbar release];
	
	[colorAxis1 release];
	[colorAxis2 release];
	[colorAxis3 release];
	
	[undoQueue release];
	[redoQueue release];
	
	[movieTimer release];
	
	[blendedMprView1 release];
	[blendedMprView2 release];
	[blendedMprView3 release];
	
    [curvedPath release];
    [curvedPathColor release];
    [displayInfo release];
    mprView1.delegate = nil;
    mprView2.delegate = nil;
    mprView3.delegate = nil;   
    cprView.delegate = nil;
    topTransverseView.delegate = nil;
    middleTransverseView.delegate = nil;
    bottomTransverseView.delegate = nil;
    
	[startingOpacityMenu release];
    
    [exportSeriesName release];
	
	[_delegateCurveViewDebugging release];
	_delegateCurveViewDebugging = nil;
	[_delegateDisplayInfoDebugging release];
	_delegateDisplayInfoDebugging = nil;
    
    [assistant release];
    [centerline release];
    [nodeRemovalCost release];
    [delHistory release];
    [delNodes release];
	
    [HR_PixList release];
    [HR_FileList release];
    [HR_Data release];
    
	[super dealloc];
	
	NSLog( @"dealloc CPRController");
}

- (BOOL) is2DViewer
{
	return NO;
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if( [note object] == viewer2D || [note object] == fusedViewer2D)
	{
		[self offFullScreen];
		[[self window] close];
	}
}

- (NSArray*) pixList
{
	return pixList[ curMovieIndex];
}

- (void) setToolIndex: (ToolMode) toolIndex
{
	[mprView1 setCurrentTool:toolIndex];
	[mprView2 setCurrentTool:toolIndex];
	[mprView3 setCurrentTool:toolIndex];
	[cprView setCurrentTool:toolIndex];
	[topTransverseView setCurrentTool:toolIndex];
	[middleTransverseView setCurrentTool:toolIndex];
	[bottomTransverseView setCurrentTool:toolIndex];
	
	[mprView1.vrView setCurrentTool:toolIndex];
	[mprView2.vrView setCurrentTool:toolIndex];
	[mprView3.vrView setCurrentTool:toolIndex];
}

- (IBAction) setTool:(id)sender;
{
	int toolIndex = 0;
	
	if([sender isKindOfClass:[NSMatrix class]])
		toolIndex = [[sender selectedCell] tag];
	else if([sender respondsToSelector:@selector(tag)])
		toolIndex = [sender tag];
	
	[self setToolIndex: toolIndex];
	[self setROIToolTag: toolIndex];
}

- (void) computeCrossReferenceLinesBetween: (CPRMPRDCMView*) mp1 and:(CPRMPRDCMView*) mp2 result: (float[2][3]) s
{
	float vectorA[ 9], vectorB[ 9];
	float originA[ 3], originB[ 3];
    
	s[ 0][ 0] = HUGE_VALF; s[ 0][ 1] = HUGE_VALF; s[ 0][ 2] = HUGE_VALF;
	s[ 1][ 0] = HUGE_VALF; s[ 1][ 1] = HUGE_VALF; s[ 1][ 2] = HUGE_VALF;
	
    if( mp2.frame.size.height > 10 && mp2.frame.size.width > 10)
    {
        originA[ 0] = mp2.pix.originX; originA[ 1] = mp2.pix.originY; originA[ 2] = mp2.pix.originZ;
        originB[ 0] = mp1.pix.originX; originB[ 1] = mp1.pix.originY; originB[ 2] = mp1.pix.originZ;
	
        [mp2.pix orientation: vectorA];
        [mp1.pix orientation: vectorB];
	
        float slicePoint[ 3];
        float sliceVector[ 3];
	
        if( intersect3D_2Planes( vectorA+6, originA, vectorB+6, originB, sliceVector, slicePoint) == noErr)
        {
            [mp1 computeSliceIntersection: mp2.pix sliceFromTo: s vector: vectorB origin: originB];
        }
    }
}

- (void) propagateOriginRotationAndZoomToTransverseViews: (CPRTransverseView*) sender
{
	[topTransverseView setOrigin: [sender origin]];
	[middleTransverseView setOrigin: [sender origin]];
	[bottomTransverseView setOrigin: [sender origin]];
	
	[topTransverseView setScaleValue: [sender scaleValue]];
	[middleTransverseView setScaleValue: [sender scaleValue]];
	[bottomTransverseView setScaleValue: [sender scaleValue]];
	
	[topTransverseView setRotation: [sender rotation]];
	[middleTransverseView setRotation: [sender rotation]];
	[bottomTransverseView setRotation: [sender rotation]];
}

- (void) propagateWLWW:(DCMView*) sender
{
	[mprView1 setWLWW: [sender curWL] :[sender curWW]];
	[mprView2 setWLWW: [sender curWL] :[sender curWW]];
	[mprView3 setWLWW: [sender curWL] :[sender curWW]];
	[cprView setWLWW: [sender curWL] :[sender curWW]];
	[topTransverseView setWLWW: [sender curWL] :[sender curWW]];
	[middleTransverseView setWLWW: [sender curWL] :[sender curWW]];
	[bottomTransverseView setWLWW: [sender curWL] :[sender curWW]];
    
	mprView1.camera.wl = [sender curWL];	mprView1.camera.ww = [sender curWW];
	mprView2.camera.wl = [sender curWL];	mprView2.camera.ww = [sender curWW];
	mprView3.camera.wl = [sender curWL];	mprView3.camera.ww = [sender curWW];
}

- (void) computeCrossReferenceLines:(CPRMPRDCMView*) sender
{
	float a[2][3];
	float b[2][3];
	
	if( sender)
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"syncZoomLevelMPR"])
		{
			CPRMPRDCMView *selectedView = [self selectedView];
			
			if( selectedView != mprView1) mprView1.camera.parallelScale = selectedView.camera.parallelScale;
			if( selectedView != mprView2) mprView2.camera.parallelScale = selectedView.camera.parallelScale;
			if( selectedView != mprView3) mprView3.camera.parallelScale = selectedView.camera.parallelScale;
		}
	}
    
	// Center other views on the sender view
	if( sender && [sender isKeyView] == YES && avoidReentry == NO)
	{
		avoidReentry = YES;
		
		float x, y, z;
		Camera *cam = sender.camera;
		Point3D *position = cam.position;
//		Point3D *viewUp = cam.viewUp;
		float halfthickness = sender.vrView.clippingRangeThickness / 2.;
		float cos[ 9];
		[sender.pix orientation: cos];
		
		// Correct slice position according to slice center (VR: position is the beginning of the slice)
		position = [Point3D pointWithX: position.x + halfthickness*cos[ 6] y:position.y + halfthickness*cos[ 7] z:position.z + halfthickness*cos[ 8]];
		
		if( sender != mprView1) mprView1.camera.position = position;
		if( sender != mprView2) mprView2.camera.position = position;
		if( sender != mprView3) mprView3.camera.position = position;
		
		if( sender == mprView1)
		{
			float angle = mprView1.angleMPR;
			XYZ vector, rotationVector;
			rotationVector.x = cos[ 6];	rotationVector.y = cos[ 7];	rotationVector.z = cos[ 8];
			
			vector.x = cos[ 3];	vector.y = cos[ 4];	vector.z = cos[ 5];
			vector =  ArbitraryRotate(vector, (angle-180.)*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView2.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			Point3D *p = mprView2.camera.position;
			mprView2.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
			
			vector.x = cos[ 0];	vector.y = cos[ 1];	vector.z = cos[ 2];
			vector =  ArbitraryRotate(vector, angle*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView3.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			p = mprView3.camera.position;
			mprView3.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
		}
		
		if( sender == mprView2)
		{
			float angle = mprView2.angleMPR;
			XYZ vector, rotationVector;
			rotationVector.x = cos[ 6];	rotationVector.y = cos[ 7];	rotationVector.z = cos[ 8];
			
			vector.x = cos[ 3];	vector.y = cos[ 4];	vector.z = cos[ 5];
			vector =  ArbitraryRotate(vector, angle*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView3.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			Point3D *p = mprView3.camera.position;
			mprView3.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
			
			vector.x = cos[ 0];	vector.y = cos[ 1];	vector.z = cos[ 2];
			vector =  ArbitraryRotate(vector, (angle-180.)*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView1.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			p = mprView1.camera.position;
			mprView1.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
		}
		
		if( sender == mprView3)
		{
			float angle = mprView3.angleMPR;
			XYZ vector, rotationVector;
			rotationVector.x = cos[ 6];	rotationVector.y = cos[ 7];	rotationVector.z = cos[ 8];
			
			vector.x = cos[ 3];	vector.y = cos[ 4];	vector.z = cos[ 5];
			vector =  ArbitraryRotate(vector, (angle-180.)*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView2.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			Point3D *p = mprView2.camera.position;
			mprView2.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
			
			vector.x = -cos[ 0];	vector.y = -cos[ 1];	vector.z = -cos[ 2];
			vector =  ArbitraryRotate(vector, angle*deg2rad, rotationVector);
			x = position.x + vector.x;	y = position.y + vector.y;	z = position.z + vector.z;
			mprView1.camera.focalPoint = [Point3D pointWithX:x y:y z:z];
			
			// Correct slice position according to slice center (VR: position is the beginning of the slice)
			p = mprView1.camera.position;
			mprView1.camera.position = [Point3D pointWithX: p.x + halfthickness*-vector.x y:p.y + halfthickness*-vector.y z:p.z + halfthickness*-vector.z];
		}
		
		float l, w;
		[sender.vrView getWLWW: &l : &w];
        
		if( sender != mprView1)
		{
			[mprView1 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView1.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView1.vrView setWLWW: l : w];
			}
			
			[mprView1 updateViewMPROnLoading:isInitializing];
		}
		
		if( sender != mprView2)
		{
			[mprView2 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView2.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView2.vrView setWLWW: l : w];
			}
			
			[mprView2 updateViewMPROnLoading:isInitializing];
		}
		
		if( sender != mprView3)
		{
			[mprView3 restoreCamera];
			
			if( clippingRangeMode == 0) // VR mode
			{
				[mprView3.vrView setOpacity: [sender.vrView currentOpacityArray]];
				[mprView3.vrView setWLWW: l : w];
			}
			
			[mprView3 updateViewMPROnLoading:isInitializing];
		}
		
		if( sender == mprView1)
		{
			float o[ 9], orientation[ 9];
			
			[sender.pix orientation: o];
			
			[mprView2.pix orientation: orientation];
			mprView2.angleMPR = [CPRController angleBetweenVector: o+6 andPlane:orientation]-180.;
			
			[mprView3.pix orientation: orientation];
			mprView3.angleMPR = [CPRController angleBetweenVector: o+6 andPlane:orientation]-180.;
		}
		
		if( sender == mprView2)
		{
			float o[ 9], orientation[ 9];
			[sender.pix orientation: o];
			
			[mprView1.pix orientation: orientation];
			mprView1.angleMPR = [CPRController angleBetweenVector: o+6 andPlane:orientation]+90.;
			
			[mprView3.pix orientation: orientation];
			mprView3.angleMPR = [CPRController angleBetweenVector: o+6 andPlane:orientation]+90.;
		}
		
		if( sender == mprView3)
		{
			float o[ 9], orientation[ 9];
			[sender.pix orientation: o];
			
			[mprView1.pix orientation: orientation];
			mprView1.angleMPR = [CPRController angleBetweenVector: o+6 andPlane:orientation];
			
			[mprView2.pix orientation: orientation];
			mprView2.angleMPR = [CPRController angleBetweenVector: o+6 andPlane:orientation]-90.;
		}
	}
	
	[self computeCrossReferenceLinesBetween: mprView1 and: mprView2 result: a];
	[self computeCrossReferenceLinesBetween: mprView1 and: mprView3 result: b];
	[mprView1 setCrossReferenceLines: a and: b];
	
	[self computeCrossReferenceLinesBetween: mprView2 and: mprView1 result: a];
	[self computeCrossReferenceLinesBetween: mprView2 and: mprView3 result: b];
	[mprView2 setCrossReferenceLines: a and: b];
	
	[self computeCrossReferenceLinesBetween: mprView3 and: mprView1 result: a];
	[self computeCrossReferenceLinesBetween: mprView3 and: mprView2 result: b];
	[mprView3 setCrossReferenceLines: a and: b];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
	
	avoidReentry = NO;
}

- (void) setMousePosition:(Point3D*) pt
{
	[mousePosition release];
	mousePosition = [pt retain];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
}

- (void)keyDown:(NSEvent *)theEvent
{
    if( [[theEvent characters] length] == 0) return;
    
    unichar c = [[theEvent characters] characterAtIndex:0];
    
	if( c ==  ' ')
	{
		[self toogleAxisVisibility: self];
	}
	else if(c == 27) // 27 : escape
	{
		if( FullScreenOn)
			[self fullScreenMenu:self];
		else
			[super keyDown: theEvent];
	}
	else [super keyDown: theEvent];
}

- (id) view
{
	return mprView1;
}

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
			tag = [sender tag];
	}
	else
		tag = [[[note userInfo] valueForKey:@"toolIndex"] intValue];
	
	if( tag >= 0)
	{
		[toolsMatrix selectCellWithTag: tag];
		[self setToolIndex: tag];
		[self setROIToolTag: tag];
	}
}

- (void) assistedCurvedPath:(NSNotification*) note
{
    unsigned int nodeCount = [curvedPath.nodes count];
    if ( nodeCount > 1)
    {
        WaitRendering* waiting = [[[WaitRendering alloc] init:NSLocalizedString(@"Finding Path...", nil)] autorelease];
        [waiting showWindow:self];
        N3AffineTransform patient2VolumeDataTransform = cprVolumeData.volumeTransform;
        N3AffineTransform volumeData2PatientTransform = N3AffineTransformInvert(patient2VolumeDataTransform);
        
        CPRCurvedPath * newCP = [[[CPRCurvedPath alloc] init] autorelease];
        N3Vector node;
        OSIVoxel * pt;

        for (unsigned int i = 0; i < nodeCount - 1; ++i)
        {
            N3Vector na = N3VectorApplyTransform([[curvedPath.nodes objectAtIndex:i] N3VectorValue], patient2VolumeDataTransform);
            N3Vector nb = N3VectorApplyTransform([[curvedPath.nodes objectAtIndex:i+1] N3VectorValue], patient2VolumeDataTransform);
            
            Point3D *pta = [[[Point3D alloc] initWithX:na.x y:na.y z:na.z] autorelease];
            Point3D *ptb = [[[Point3D alloc] initWithX:nb.x y:nb.y z:nb.z] autorelease];
            
            [centerline removeAllObjects];
            
            int err = [assistant createCenterline:centerline FromPointA:pta ToPointB:ptb withSmoothing:NO];
            if(!err)
            {
                unsigned int lineCount = [centerline count] - 1;
                for( unsigned int i = 0; i < lineCount ; ++i)
                {
                    pt = [centerline objectAtIndex:i];
                    node.x = pt.x;
                    node.y = pt.y;
                    node.z = pt.z;
                    [newCP addPatientNode:N3VectorApplyTransform(node, volumeData2PatientTransform)];
                }
            }
            else if(err == ERROR_NOENOUGHMEM)
            {
                NSRunAlertPanel(NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"Path Assistant can not allocate enough memory, try to increase the resample voxel size in the settings.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            }
            else if(err == ERROR_CANNOTFINDPATH)
            {
                NSRunAlertPanel(NSLocalizedString(@"Can't find path", nil), NSLocalizedString(@"Path Assistant can not find a path from A to B.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            }
            else if(err==ERROR_DISTTRANSNOTFINISH)
            {
                [waiting close];
                waiting = [[[WaitRendering alloc] init:NSLocalizedString(@"Distance Transform...", nil)] autorelease];
                [waiting showWindow:self];
                
                for(unsigned int i=0; i<5; i++)
                {
                    [centerline removeAllObjects];
                    err= [assistant createCenterline:centerline FromPointA:pta ToPointB:ptb withSmoothing:NO];
                    if(err!=ERROR_DISTTRANSNOTFINISH)
                        break;
                    
                    for(unsigned int i=0;i<[centerline count] - 1;i++)
                    {
                        pt = [centerline objectAtIndex:i];
                        node.x = pt.x;
                        node.y = pt.y;
                        node.z = pt.z;
                        [newCP addPatientNode:N3VectorApplyTransform(node, volumeData2PatientTransform)];
                    }
                }
                if(err==ERROR_CANNOTFINDPATH)
                {
                    NSRunAlertPanel(NSLocalizedString(@"Can't find path", nil), NSLocalizedString(@"Path Assistant can not find a path from current location.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                    [waiting close];
                    return;
                }
                else if(err==ERROR_DISTTRANSNOTFINISH)
                {
                    NSRunAlertPanel(NSLocalizedString(@"Unexpected error", nil), NSLocalizedString(@"Path Assistant failed to initialize!", nil), NSLocalizedString(@"OK", nil), nil, nil);
                    [waiting close];
                    return;
                }        
            }
        }
        pt = [centerline lastObject];
        node.x = pt.x;
        node.y = pt.y;
        node.z = pt.z;
        [newCP addPatientNode:N3VectorApplyTransform(node, volumeData2PatientTransform)];
        
        self.curvedPath = newCP;
        
        [self updateCurvedPathCost];
        [pathSimplificationSlider setDoubleValue:[pathSimplificationSlider maxValue]];
        
        mprView1.curvedPath = curvedPath;
        mprView2.curvedPath = curvedPath;
        mprView3.curvedPath = curvedPath;
        cprView.curvedPath = curvedPath;
        topTransverseView.curvedPath = curvedPath;
        middleTransverseView.curvedPath = curvedPath;
        bottomTransverseView.curvedPath = curvedPath;
        
        [waiting close];
    }
    else {
        NSLog(@"Not enough points to launch assistant");
    }    
}

#pragma mark ROI

- (IBAction) roiGetInfo:(id) sender
{
    DCMView *s = [self selectedViewOnlyMPRView : NO];
    
    if( [s isKindOfClass: [CPRView class]])
        s = [(CPRView*)s reformationView];
    
    @try
    {
        for( ROI *r in [s curRoiList])
        {
            long mode = [r ROImode];
            
            if( mode == ROI_selected || mode == ROI_selectedModify || mode == ROI_drawing)
            {
                NSArray *winList = [NSApp windows];
                BOOL	found = NO;
                
                for( id loopItem1 in winList)
                {
                    if( [[[loopItem1 windowController] windowNibName] isEqualToString:@"ROI"])
                    {
                        if( [[loopItem1 windowController] curROI] == r)
                        {
                            found = YES;
                            [[[loopItem1 windowController] window] makeKeyAndOrderFront:self];
                        }
                    }
                }
                
                if( found == NO)
                {
                    ROIWindow* roiWin = [[ROIWindow alloc] initWithROI: r :viewer2D];
                    [roiWin showWindow:self];
                }
                break;
            }
        }
    }
    @catch (NSException *exception) {
        N2LogExceptionWithStackTrace( exception);
    }
}

- (void)bringToFrontROI:(ROI*) roi;
{
    
}

- (NSImage*) imageForROI: (ToolMode) i
{
	NSString	*filename = nil;
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
		case tRepulsor:		filename = @"Repulsor";			break;
		case tROISelector:	filename = @"ROISelector";		break;
		case tAxis:			filename = @"Axis";				break;
		case tDynAngle:		filename = @"DynamicAngle";		break;
        case tTAGT:         filename = @"PerpendicularLines";             break;
        default:;
	}
	
	if( filename == nil)
		return nil;
	
	return [NSImage imageNamed: filename];
}

-(void) setROIToolTag:(ToolMode) roitype
{
	if( roitype != tRepulsor)
	{
		NSImage *im = [self imageForROI: roitype];
		
		if( im)
		{
			NSButtonCell *cell = [toolsMatrix cellAtRow:0 column:7];
			[cell setTag: roitype];
			[cell setImage: im];
			
			[toolsMatrix selectCellAtRow:0 column:7];
		}
	}
}

- (IBAction) roiDeleteAll:(id) sender
{
	[self addToUndoQueue: @"roi"];
	
	DCMView *s = [self selectedViewOnlyMPRView : NO];
    
    if( [s isKindOfClass: [CPRView class]])
         s = [(CPRView*)s reformationView];
	
	[s stopROIEditingForce: YES];
	
	NSArray *roiListCopy = [[[s curRoiList] copy] autorelease];
	
	for( ROI *r in roiListCopy)
		[viewer2D deleteROI: r.parentROI];
	
	[[s curRoiList] removeAllObjects];
	
	[s setIndex: [s curImage]];
	
	[mprView1 detect2DPointInThisSlice];
	[mprView2 detect2DPointInThisSlice];
	[mprView3 detect2DPointInThisSlice];
}

#pragma mark Undo

- (id) prepareObjectForUndo:(NSString*) string
{
    //	if( [string isEqualToString: @"roi"])
    //	{
    //		NSMutableArray	*rois = [NSMutableArray array];
    //		
    //		for( int i = 0; i < maxMovieIndex+1; i++)
    //		{
    //			NSMutableArray *array = [NSMutableArray array];
    //			for( NSArray *ar in roiList[ i])
    //			{
    //				NSMutableArray	*a = [NSMutableArray array];
    //				
    //				for( ROI *r in ar)
    //					[a addObject: [[r copy] autorelease]];
    //				
    //				[array addObject: a];
    //			}
    //			[rois addObject: array];
    //		}
    //		
    //		return [NSDictionary dictionaryWithObjectsAndKeys: string, @"type", rois, @"rois", nil];
    //	}
	
	if( [string isEqualToString: @"mprCamera"] && mprView1.camera && mprView2.camera && mprView3.camera)
	{
		NSMutableArray	*cameras = [NSMutableArray array];
		
		[cameras addObject: [[mprView1.camera copy] autorelease]];
		[cameras addObject: [[mprView2.camera copy] autorelease]];
		[cameras addObject: [[mprView3.camera copy] autorelease]];
		
		NSMutableArray	*angleMPRs = [NSMutableArray array];
		
		[angleMPRs addObject: [NSNumber numberWithFloat: mprView1.angleMPR]];
		[angleMPRs addObject: [NSNumber numberWithFloat: mprView2.angleMPR]];
		[angleMPRs addObject: [NSNumber numberWithFloat: mprView3.angleMPR]];
		
		return [NSDictionary dictionaryWithObjectsAndKeys: string, @"type", cameras, @"cameras", angleMPRs, @"angleMPRs", nil];
	} else if ([string isEqualToString:@"curvedPath"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:string, @"type", [NSKeyedArchiver archivedDataWithRootObject:curvedPath], @"curvedPath", nil];
	}
	
	return nil;
}

- (void) executeUndo:(NSMutableArray*) u
{
	if( [u count])
	{
		if( [[[u lastObject] objectForKey: @"type"] isEqualToString:@"mprCamera"])
		{
			NSArray	*cameras = [[u lastObject] objectForKey: @"cameras"];
			
			mprView1.camera = [cameras objectAtIndex: 0];
			mprView2.camera = [cameras objectAtIndex: 1];
			mprView3.camera = [cameras objectAtIndex: 2];
			
			NSArray	*angleMPRs = [[u lastObject] objectForKey: @"angleMPRs"];
			
			mprView1.angleMPR = [[angleMPRs objectAtIndex: 0] floatValue];
			mprView2.angleMPR = [[angleMPRs objectAtIndex: 1] floatValue];
			mprView3.angleMPR = [[angleMPRs objectAtIndex: 2] floatValue];
			
			[self updateViewsAccordingToFrame: nil];
		} else if( [[[u lastObject] objectForKey: @"type"] isEqualToString:@"curvedPath"]) {
			self.curvedPath = [NSKeyedUnarchiver unarchiveObjectWithData:[[u lastObject] objectForKey:@"curvedPath"]];
			mprView1.curvedPath = curvedPath;
			mprView2.curvedPath = curvedPath;
			mprView3.curvedPath = curvedPath;
			cprView.curvedPath = curvedPath;
			topTransverseView.curvedPath = curvedPath;
			middleTransverseView.curvedPath = curvedPath;
			bottomTransverseView.curvedPath = curvedPath;
		}
		
        //		if( [[[u lastObject] objectForKey: @"type"] isEqualToString:@"roi"])
        //		{
        //			NSMutableArray	*rois = [[u lastObject] objectForKey: @"rois"];
        //			
        //			int i, x, z;
        //			
        //			for( i = 0; i < maxMovieIndex+1; i++)
        //			{
        //				for( x = 0; x < [roiList[ i] count] ; x++)
        //				{
        //					for( z = 0; z < [[roiList[ i] objectAtIndex: x] count]; z++)
        //						[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:[[roiList[ i] objectAtIndex: x] objectAtIndex: z] userInfo: nil];
        //						
        //					[[roiList[ i] objectAtIndex: x] removeAllObjects];
        //				}
        //			}
        //			
        //			for( i = 0; i < maxMovieIndex+1; i++)
        //			{
        //				NSArray *r = [rois objectAtIndex: i];
        //				
        //				for( x = 0; x < [roiList[ i] count] ; x++)
        //				{
        //					[[roiList[ i] objectAtIndex: x] addObjectsFromArray: [r objectAtIndex: x]];
        //					
        //					for( ROI *r in [roiList[ i] objectAtIndex: x])
        //					{
        //						[imageView roiSet: r];
        //						[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object: r userInfo: nil];
        //					}
        //				}
        //			}
        //			
        //			[imageView setIndex: [imageView curImage]];
        //			
        //			NSLog( @"roi undo");
        //		}
		
		[u removeLastObject];
	}
}

- (IBAction) redo:(id) sender
{
	if( [redoQueue count])
	{
		id obj = [self prepareObjectForUndo: [[redoQueue lastObject] objectForKey:@"type"]];
		
		if( obj)
			[undoQueue addObject: obj];
		
		[self executeUndo: redoQueue];
	}
	else NSBeep();
}

- (IBAction) undo:(id) sender
{
	if( [undoQueue count])
	{
		id obj = [self prepareObjectForUndo: [[undoQueue lastObject] objectForKey:@"type"]];
		
		if( obj)
			[redoQueue addObject: obj];
		
		[self executeUndo: undoQueue];
	}
	else NSBeep();
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
    
	id obj = [self prepareObjectForUndo: string];
	
	if( obj)
		[undoQueue addObject: obj];
	
	if( [undoQueue count] > [[NSUserDefaults standardUserDefaults] integerForKey: @"UndoQueueSize"])
	{
		[undoQueue removeObjectAtIndex: 0];
	}
}

#pragma mark LOD

- (void) bestRendering:(id) sender
{
	float savedLOD = LOD;
	
	[self setLOD: 1.0];
	
	LOD = savedLOD;
	[hiddenVRView setLOD: LOD];
	mprView1.LOD = LOD;
	mprView2.LOD = LOD;
	mprView3.LOD = LOD;
}

- (void) setLOD: (float)lod;
{
	if( lod < 1) lod = 1;
	
	LOD = lod;
	[hiddenVRView setLOD: lod];
	
	mprView1.LOD = LOD;
	mprView2.LOD = LOD;
	mprView3.LOD = LOD;
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPROnLoading:isInitializing];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPROnLoading:isInitializing];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPROnLoading:isInitializing];
}

#pragma mark Window Level / Window width

- (void)createWLWWMenuItems;
{
    // Presets VIEWER Menu
	NSArray *keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] allKeys];
	NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableArray *tmp = [NSMutableArray array];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:curWLWWMenu action:nil keyEquivalent:@""] autorelease]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other", nil) action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Default WL & WW", nil) action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];
	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Full dynamic", nil) action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];
	[tmp addObject:[NSMenuItem separatorItem]];
    for(int i = 0; i < [sortedKeys count]; i++)
		[tmp addObject:[[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%d - %@", i+1, [sortedKeys objectAtIndex:i]] action:@selector(ApplyWLWW:) keyEquivalent:@""] autorelease]];
    
    //    [tmp addObject:[NSMenuItem separatorItem]];
    //	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Current WL/WW", nil) action:@selector(AddCurrentWLWW:) keyEquivalent:@""] autorelease]];
    //	[tmp addObject:[[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Set WL/WW Manually", nil) action:@selector(SetWLWW:) keyEquivalent:@""] autorelease]];	
	
	self.wlwwMenuItems = tmp;
}


- (void)UpdateWLWWMenu:(NSNotification*)note;
{
    [[wlwwPopup menu] removeAllItems];
	
	[self createWLWWMenuItems];
	
    for( NSMenuItem *item in self.wlwwMenuItems)
        [[wlwwPopup menu] addItem: item];
    
	if( [note object])
	{
		[curWLWWMenu release];
		curWLWWMenu = [[note object] retain];
		[wlwwPopup setTitle: curWLWWMenu];
	}
}

- (void)ApplyWLWW:(id)sender;
{
	NSString *menuString = [sender title];
	
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

- (void)applyWLWWForString:(NSString *)menuString;
{
	if( [menuString isEqualToString:NSLocalizedString(@"Other", nil)])
	{
		//[imageView setWLWW:0 :0];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Default WL & WW", nil)])
	{
		[mprView1 setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[mprView2 setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[mprView3 setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[cprView setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[topTransverseView setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[middleTransverseView setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
		[bottomTransverseView setWLWW:[[pixList[0] objectAtIndex:0] savedWL] :[[pixList[0] objectAtIndex:0] savedWW]];
	}
	else if( [menuString isEqualToString:NSLocalizedString(@"Full dynamic", nil)])
	{
		[mprView1 setWLWW:0 :0];
		[mprView2 setWLWW:0 :0];
		[mprView3 setWLWW:0 :0];
		[cprView setWLWW:0 :0];
		[topTransverseView setWLWW:0 :0];
		[middleTransverseView setWLWW:0 :0];
		[bottomTransverseView setWLWW:0 :0];
	}
	else
	{
		if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
		{
			NSBeginAlertSheet( NSLocalizedString(@"Delete a WL/WW preset",nil), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), nil, [self window], self, @selector(deleteWLWW:returnCode:contextInfo:), NULL, [menuString retain], NSLocalizedString( @"Are you sure you want to delete preset : '%@'?", nil), menuString);
		}
		else
		{
			NSArray    *value;
			
			value = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] objectForKey:menuString];
			
			[mprView1 setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[mprView2 setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[mprView3 setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[cprView setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[topTransverseView setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[middleTransverseView setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
			[bottomTransverseView setWLWW:[[value objectAtIndex:0] floatValue] :[[value objectAtIndex:1] floatValue]];
		}
	}
	
	[[[wlwwPopup menu] itemAtIndex:0] setTitle:menuString];
	
	if( curWLWWMenu != menuString)
	{
		[curWLWWMenu release];
		curWLWWMenu = [menuString retain];
	}	
}

#pragma mark CLUTs

- (void)UpdateCLUTMenu:(NSNotification*)note
{
    //*** Build the menu
    int i;
    NSArray *keys;
    NSArray *sortedKeys;
    
    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    [[clutPopup menu] removeAllItems];
	
	[[clutPopup menu] addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:nil keyEquivalent:@""];
    [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:@selector (ApplyCLUT:) keyEquivalent:@""];
	[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
    }
	
	[[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
	
    //	// path 1 : /Horos Data/CLUTs/
    //	NSMutableString *path = [NSMutableString stringWithString: [[BrowserController currentBrowser] documentsDirectory]];
    //	[path appendString: CLUTDATABASE];
    //	// path 2 : /resources_bundle_path/CLUTs/
    //	NSMutableString *bundlePath = [NSMutableString stringWithString:[[NSBundle mainBundle] resourcePath]];
    //	[bundlePath appendString: CLUTDATABASE];
    //	
    //	NSMutableArray *paths = [NSMutableArray arrayWithObjects:path, bundlePath, nil];
    //	
    //	NSMutableArray *clutArray = [NSMutableArray array];
    //	BOOL isDir;
    //	
    //	for (NSUInteger j=0; j<[paths count]; j++)
    //	{
    //		if([[NSFileManager defaultManager] fileExistsAtPath:[paths objectAtIndex:j] isDirectory:&isDir] && isDir)
    //		{
    //			NSArray *content = [[NSFileManager defaultManager] directoryContentsAtPath:[paths objectAtIndex:j]];
    //			for (NSUInteger i=0; i<[content count]; i++)
    //			{
    //				if( [[content objectAtIndex:i] length] > 0)
    //				{
    //					if( [[content objectAtIndex:i] characterAtIndex: 0] != '.')
    //					{
    //						NSDictionary* clut = [CLUTOpacityView presetFromFileWithName:[[content objectAtIndex:i] stringByDeletingPathExtension]];
    //						if(clut)
    //						{
    //							[clutArray addObject:[[content objectAtIndex:i] stringByDeletingPathExtension]];
    //						}
    //					}
    //				}
    //			}
    //		}
    //	}
    //	
    //	[clutArray sortUsingSelector:@selector(caseInsensitiveCompare:)];
    //	
    //	NSMenuItem *item;
    //	item = [[clutPopup menu] insertItemWithTitle:@"8-bit CLUTs" action:@selector(noAction:) keyEquivalent:@"" atIndex:3];
    //	
    //	if( [clutArray count])
    //	{
    //		[[clutPopup menu] insertItem:[NSMenuItem separatorItem] atIndex:[[clutPopup menu] numberOfItems]-2];
    //		
    //		item = [[clutPopup menu] insertItemWithTitle:@"16-bit CLUTs" action:@selector(noAction:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
    //		
    //		for (NSUInteger i=0; i<[clutArray count]; i++)
    //		{
    //			item = [[clutPopup menu] insertItemWithTitle:[clutArray objectAtIndex:i] action:@selector(loadAdvancedCLUTOpacity:) keyEquivalent:@"" atIndex:[[clutPopup menu] numberOfItems]-2];
    //			if([mprView1.vrView isRGB])
    //				[item setEnabled:NO];
    //		}
    //	}
    //	
    //    item = [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"16-bit CLUT Editor", nil) action:@selector(showCLUTOpacityPanel:) keyEquivalent:@""];
    //	if([[pixList[ 0] objectAtIndex:0] isRGB])
    //		[item setEnabled:NO];
}

-(void) ApplyCLUTString:(NSString*) str
{
	if( str == nil) return;
    
	[OpacityPopup setEnabled:YES];
	
	[self ApplyOpacityString:curOpacityMenu];
	
	if( [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: str] == nil)
		str = NSLocalizedString(@"No CLUT", nil);
	
	if( curCLUTMenu != str)
	{
		[curCLUTMenu release];
		curCLUTMenu = [str retain];
	}
	
	mprView1.camera.forceUpdate = YES;
	mprView2.camera.forceUpdate = YES;
	mprView3.camera.forceUpdate = YES;
	
	if( clippingRangeMode == 0) //VR
	{
		[mprView1 setCLUT: nil :nil :nil];
		[mprView2 setCLUT: nil :nil :nil];
		[mprView3 setCLUT: nil :nil :nil];
		
		[mprView1 setIndex:[mprView1 curImage]];
		[mprView2 setIndex:[mprView2 curImage]];
		[mprView3 setIndex:[mprView3 curImage]];
		
		[cprView setCLUT: nil :nil :nil];
		[topTransverseView setCLUT: nil :nil :nil];
		[middleTransverseView setCLUT: nil :nil :nil];
		[bottomTransverseView setCLUT: nil :nil :nil];
		
		[cprView setIndex:[cprView curImage]];
		[topTransverseView setIndex:[topTransverseView curImage]];
		[middleTransverseView setIndex:[middleTransverseView curImage]];
		[bottomTransverseView setIndex:[bottomTransverseView curImage]];
	}
	
	if([str isEqualToString:NSLocalizedString(@"No CLUT", nil)])
	{
		if(clippingRangeMode==0)
		{
			[mprView1.vrView setCLUT: nil :nil :nil];
			
			[mprView1 restoreCamera];
			mprView1.camera.forceUpdate = YES;
			[mprView1 updateViewMPR];
            
			[mprView2 restoreCamera];
			mprView2.camera.forceUpdate = YES;
			[mprView2 updateViewMPR];
            
			[mprView3 restoreCamera];
			mprView3.camera.forceUpdate = YES;
			[mprView3 updateViewMPR];
		}
		else
		{
			[mprView1 setCLUT: nil :nil :nil];
			[mprView2 setCLUT: nil :nil :nil];
			[mprView3 setCLUT: nil :nil :nil];
			
			[mprView1 setIndex:[mprView1 curImage]];
			[mprView2 setIndex:[mprView2 curImage]];
			[mprView3 setIndex:[mprView3 curImage]];
			
			[cprView setCLUT: nil :nil :nil];
			[topTransverseView setCLUT: nil :nil :nil];
			[middleTransverseView setCLUT: nil :nil :nil];
			[bottomTransverseView setCLUT: nil :nil :nil];
			
			[cprView setIndex:[cprView curImage]];
			[topTransverseView setIndex:[topTransverseView curImage]];
			[middleTransverseView setIndex:[middleTransverseView curImage]];
			[bottomTransverseView setIndex:[bottomTransverseView curImage]];
			
			if( str != curCLUTMenu)
			{
				[curCLUTMenu release];
				curCLUTMenu = [str retain];
			}					
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
		
		[[[clutPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		NSDictionary *aCLUT;
		NSArray *array;
		long i;
		unsigned char red[256], green[256], blue[256];
		
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
			
			if(clippingRangeMode==0)
			{
				[mprView1.vrView setCLUT:red :green: blue];
                
				[mprView1 restoreCamera];
				mprView1.camera.forceUpdate = YES;
				[mprView1 updateViewMPR];
				
				[mprView2 restoreCamera];
				mprView2.camera.forceUpdate = YES;
				[mprView2 updateViewMPR];
				
				[mprView3 restoreCamera];
				mprView3.camera.forceUpdate = YES;
				[mprView3 updateViewMPR];
			}
			else
			{
				[mprView1 setCLUT:red :green: blue];
				[mprView2 setCLUT:red :green: blue];
				[mprView3 setCLUT:red :green: blue];
				
				[cprView setCLUT:red :green: blue];
				[topTransverseView setCLUT:red :green: blue];
				[middleTransverseView setCLUT:red :green: blue];
				[bottomTransverseView setCLUT:red :green: blue];
				
				[mprView1 setIndex:[mprView1 curImage]];
				[mprView2 setIndex:[mprView2 curImage]];
				[mprView3 setIndex:[mprView3 curImage]];
				
				[cprView setIndex:[cprView curImage]];
				[topTransverseView setIndex:[topTransverseView curImage]];
				[middleTransverseView setIndex:[middleTransverseView curImage]];
				[bottomTransverseView setIndex:[bottomTransverseView curImage]];
				
				if( str != curCLUTMenu)
				{
					[curCLUTMenu release];
					curCLUTMenu = [str retain];
				}
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle: curCLUTMenu];
		}
	}
}

#pragma mark Opacity

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
    //    [[OpacityPopup menu] addItem: [NSMenuItem separatorItem]];
    //    [[OpacityPopup menu] addItemWithTitle:NSLocalizedString(@"Add an Opacity Table", nil) action:@selector (AddOpacity:) keyEquivalent:@""];
	
	[[[OpacityPopup menu] itemAtIndex:0] setTitle:curOpacityMenu];
}

- (void) OpacityChanged: (NSNotification*) note
{
	[hiddenVRView setOpacity: [[note object] getPoints]];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];	
}

- (void)ApplyOpacityString:(NSString*)str
{
	if( clippingRangeMode == 1 || clippingRangeMode == 3  || clippingRangeMode == 2)
	{
		[self Apply2DOpacityString:str];
	}
	else
	{
		[self Apply3DOpacityString:str];
	}
}

- (void)Apply3DOpacityString:(NSString*)str;
{
	NSDictionary *aOpacity;
	NSArray *array;
	
	if( str == nil) return;
	
	if( curOpacityMenu != str)
	{
		[curOpacityMenu release];
		curOpacityMenu = [str retain];
	}
	
	if( [str isEqualToString: NSLocalizedString(@"Linear Table", nil)])
	{
		[mprView1.vrView setOpacity:[NSArray array]];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if( aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			[mprView1.vrView setOpacity:array];
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle: curOpacityMenu];
		}
	}
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];	
}

- (void)Apply2DOpacityString:(NSString*)str;
{
	NSDictionary *aOpacity;
	NSArray *array;
	
	if( [str isEqualToString:NSLocalizedString(@"Linear Table", nil)])
	{
		//[thickSlab setOpacity:[NSArray array]];
		
		if( curOpacityMenu != str)
		{
			[curOpacityMenu release];
			curOpacityMenu = [str retain];
		}
		
		//lastMenuNotification = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
		
		[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
		
		[[mprView1 pix] setTransferFunction:nil];
		[[mprView2 pix] setTransferFunction:nil];
		[[mprView3 pix] setTransferFunction:nil];
		
		[mprView1 setIndex:[mprView1 curImage]];
		[mprView2 setIndex:[mprView2 curImage]];
		[mprView3 setIndex:[mprView3 curImage]];
		
		[[cprView curDCM] setTransferFunction:nil];
		[[topTransverseView curDCM] setTransferFunction:nil];
		[[middleTransverseView curDCM] setTransferFunction:nil];
		[[bottomTransverseView curDCM] setTransferFunction:nil];
		
		[cprView setIndex:[cprView curImage]];
		[topTransverseView setIndex:[topTransverseView curImage]];
		[middleTransverseView setIndex:[middleTransverseView curImage]];
		[bottomTransverseView setIndex:[bottomTransverseView curImage]];
	}
	else
	{
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: str];
		if (aOpacity)
		{
			array = [aOpacity objectForKey:@"Points"];
			
			//[thickSlab setOpacity:array];
			if( curOpacityMenu != str)
			{
				[curOpacityMenu release];
				curOpacityMenu = [str retain];
			}
			
			//lastMenuNotification = nil;
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
			
			[[[OpacityPopup menu] itemAtIndex:0] setTitle:str];
			
			NSData	*table = [OpacityTransferView tableWith4096Entries: [aOpacity objectForKey:@"Points"]];
			
			[[mprView1 pix] setTransferFunction: table];
			[[mprView2 pix] setTransferFunction: table];
			[[mprView3 pix] setTransferFunction: table];
			
			[[cprView curDCM] setTransferFunction: table];
			[[topTransverseView curDCM] setTransferFunction: table];
			[[middleTransverseView curDCM] setTransferFunction: table];
			[[bottomTransverseView curDCM] setTransferFunction: table];
		}
		
		[mprView1 setIndex:[mprView1 curImage]];
		[mprView2 setIndex:[mprView2 curImage]];
		[mprView3 setIndex:[mprView3 curImage]];
		
		[cprView setIndex:[cprView curImage]];
		[topTransverseView setIndex:[topTransverseView curImage]];
		[middleTransverseView setIndex:[middleTransverseView curImage]];
		[bottomTransverseView setIndex:[bottomTransverseView curImage]];
	}
}

#pragma mark GUI ObjectController - Cocoa Bindings

- (float) getClippingRangeThicknessInMm
{
	return [mprView1.vrView getClippingRangeThicknessInMm];
}

- (void) setClippingRangeThicknessInMm:(float) c
{
	[mprView1.vrView setClippingRangeThicknessInMm: c];
    
    self.clippingRangeThickness = [mprView1.vrView getClippingRangeThickness];
}

- (void) setClippingRangeThickness:(float) f
{
	float previousThickness = clippingRangeThickness;
	
    if( f <= 0)
        f = 0.5;
    
	clippingRangeThickness = f;
	
	if( clippingRangeThickness <= 3)
		hiddenVRView.lowResLODFactor = 1.0;
	else
	{
		if( [[NSProcessInfo processInfo] processorCount] >= 4)
			hiddenVRView.lowResLODFactor = 1.5;
		else
			hiddenVRView.lowResLODFactor = 2.5;
	}
	
	// Correct slice position according to slice center (VR: position is the beginning of the slice)
	CPRMPRDCMView *v = [self selectedView];
	Point3D *position = v.camera.position;
	float cos[ 9];
	[v.pix orientation: cos];
	
	float halfthicknessChange = ((previousThickness - clippingRangeThickness) /2.) * [[NSUserDefaults standardUserDefaults] floatForKey: @"superSampling"];
	
	v.camera.position = [Point3D pointWithX: position.x + halfthicknessChange*cos[ 6] y:position.y + halfthicknessChange*cos[ 7] z:position.z + halfthicknessChange*cos[ 8]];
	v.camera.focalPoint = [Point3D pointWithX: v.camera.position.x + cos[ 6] y: v.camera.position.y + cos[ 7] z:v.camera.position.z + cos[ 8]];
	
	// Update all views
	[mprView1 restoreCamera];
	mprView1.vrView.dontResetImage = YES;
	[mprView1.vrView setClippingRangeThickness: f];
	[mprView1 updateViewMPROnLoading:isInitializing];
	
	[mprView2 restoreCamera];
	mprView2.vrView.dontResetImage = YES;
	[mprView2.vrView setClippingRangeThickness: f];
	[mprView2 updateViewMPROnLoading:isInitializing];
	
	[mprView3 restoreCamera];
	mprView3.vrView.dontResetImage = YES;
	[mprView3.vrView setClippingRangeThickness: f];
	[mprView3 updateViewMPROnLoading:isInitializing];
    
	if ([self getClippingRangeThicknessInMm] > 2.0) {
		curvedPath.thickness = [self getClippingRangeThicknessInMm];
	} else {
		curvedPath.thickness = 0;
	}
	
	cprView.orangeSlabThickness = curvedPath.thickness;
	cprView.purpleSlabThickness = curvedPath.thickness;
	cprView.blueSlabThickness = curvedPath.thickness;
    mprView1.curvedPath = curvedPath;
    mprView2.curvedPath = curvedPath;
    mprView3.curvedPath = curvedPath;
    cprView.curvedPath = curvedPath;
    topTransverseView.curvedPath = curvedPath;
    middleTransverseView.curvedPath = curvedPath;
    bottomTransverseView.curvedPath = curvedPath;
    	
	[self willChangeValueForKey:@"clippingRangeThicknessInMm"];
	[self didChangeValueForKey:@"clippingRangeThicknessInMm"];
}

- (void) setClippingRangeMode:(int) f
{
	float pWL, pWW;
	float bpWL, bpWW;
	
	if( clippingRangeMode == 1 || clippingRangeMode == 3 || clippingRangeMode == 2)		// MIP
	{
		[mprView1 getWLWW: &pWL :&pWW];
		[blendedMprView1 getWLWW: &bpWL :&bpWW];
	}
	else
	{
		[mprView1.vrView getWLWW: &pWL :&pWW];
		[mprView1.vrView getBlendingWLWW: &bpWL :&bpWW];
	}
	
	clippingRangeMode = f;
	
	[mprView1.vrView setMode: clippingRangeMode];
	[mprView1.vrView setBlendingMode: clippingRangeMode];
    
	if( clippingRangeMode == 1 || clippingRangeMode == 3 || clippingRangeMode == 2)	// MIP - Mean - minIP
	{
		if( clippingRangeMode == 3) //mean
			setvtkMeanIPMode( 1);
		else
			setvtkMeanIPMode( 0);
		
		[mprView1.vrView prepareFullDepthCapture];
		
		// switch linear opacity table
		[curOpacityMenu release];
		curOpacityMenu = [startingOpacityMenu retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateOpacityMenu:) name:OsirixUpdateOpacityMenuNotification object:nil];
	}
	else
	{
		// VR mode
		[mprView1.vrView restoreFullDepthCapture];
		
		[mprView1 setWLWW:128 :256];
		[mprView2 setWLWW:128 :256];
		[mprView3 setWLWW:128 :256];
		[cprView setWLWW:128 :256];
		[topTransverseView setWLWW:128 :256];
		[middleTransverseView setWLWW:128 :256];
		[bottomTransverseView setWLWW:128 :256];
		
		[blendedMprView1 setWLWW:128 :256];
		[blendedMprView2 setWLWW:128 :256];
		[blendedMprView3 setWLWW:128 :256];
		
		// switch log inverse table
		[curOpacityMenu release];
		curOpacityMenu = [NSLocalizedString(@"Logarithmic Inverse Table", nil) retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateOpacityMenu:) name:OsirixUpdateOpacityMenuNotification object:nil];
		
		[self setTool: toolsMatrix];
	}
	[self ApplyCLUTString:curCLUTMenu];
	[self ApplyOpacityString:curOpacityMenu];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3 || clippingRangeMode == 2)
	{
		[mprView1 setWLWW: pWL :pWW];
		[blendedMprView1 setWLWW: bpWL :bpWW];
	}
	else
	{
		[mprView1.vrView setWLWW: pWL :pWW];
		[mprView1.vrView setBlendingWLWW: bpWL :bpWW];
	}
	[mprView1 updateViewMPROnLoading:isInitializing];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3 || clippingRangeMode == 2)
	{
		[mprView2 setWLWW: pWL :pWW];
		[blendedMprView2 setWLWW: bpWL :bpWW];
	}
	else
	{
		[mprView2.vrView setWLWW: pWL :pWW];
		[mprView2.vrView setBlendingWLWW: bpWL :bpWW];
	}
	[mprView2 updateViewMPROnLoading:isInitializing];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	if( clippingRangeMode == 1  || clippingRangeMode == 3 || clippingRangeMode == 2)
	{
		[mprView3 setWLWW: pWL :pWW];
		[blendedMprView3 setWLWW: bpWL :bpWW];
	}
	else
	{
		[mprView3.vrView setWLWW: pWL :pWW];
		[mprView3.vrView setBlendingWLWW: bpWL :bpWW];
	}
    
	[mprView3 updateViewMPROnLoading:isInitializing];
    [cprView setClippingRangeMode:clippingRangeMode];
}

#pragma mark Export	

// KVC methods for export

- (NSInteger)exportSequenceNumberOfFrames
{
    CGFloat slabWidth;
    CGFloat sliceInterval;
    if (self.exportSequenceType == CPRCurrentOnlyExportSequenceType)
	{ // export current only, or 4D
        return 1;
    }
	else if (self.exportSequenceType == CPRSeriesExportSequenceType)
	{ // export a series
        if (self.exportSeriesType == CPRRotationExportSeriesType)
		{ // a rotation
            return MAX(1, self.exportNumberOfRotationFrames);
        }
		else if (self.exportSeriesType == CPRSlabExportSeriesType)
		{
//            if (self.exportSlabThinknessSameAsSlabThickness) {
//                slabWidth = [self getClippingRangeThicknessInMm];
//            } else {
                slabWidth = exportSlabThickness;
//            }
            
            if (self.exportSliceIntervalSameAsVolumeSliceInterval)
			{
                sliceInterval = fabs([cprView.volumeData minPixelSpacing]);
            } else {
                sliceInterval = fabs(exportSliceInterval);
            }
            
            return MAX(1, ceil(slabWidth / sliceInterval));
        }
		else if (self.exportSeriesType == CPRTransverseViewsExportSeriesType)
		{
			N3MutableBezierPath *flattenedPath = [[curvedPath.bezierPath mutableCopy] autorelease];
			[flattenedPath subdivide:N3BezierDefaultSubdivideSegmentLength];
			[flattenedPath flatten:N3BezierDefaultFlatness];
			
			float curveLength = [flattenedPath length];
			int requestCount = ( curveLength / self.exportTransverseSliceInterval);
			requestCount++;
			
			return requestCount;
		}
    }
	
    assert(0);
    
    return 0;
}

- (void)setExportSequenceType:(CPRExportSequenceType)newExportSequenceType
{
    assert(newExportSequenceType == CPRCurrentOnlyExportSequenceType || newExportSequenceType == CPRSeriesExportSequenceType);
    if (exportSequenceType != newExportSequenceType)
	{
        [self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
        exportSequenceType = newExportSequenceType;
        [self didChangeValueForKey:@"exportSequenceNumberOfFrames"];
		
		[cprView setNeedsDisplay: YES];
    }
}

- (void)setExportNumberOfRotationFrames:(NSInteger)newExportNumberOfRotationFrames
{
	if( exportNumberOfRotationFrames != newExportNumberOfRotationFrames)
	{
		[self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
		exportNumberOfRotationFrames = newExportNumberOfRotationFrames;
		[self didChangeValueForKey:@"exportSequenceNumberOfFrames"];
	}
}

- (void)setExportSeriesType:(CPRExportSeriesType)newExportSeriesType
{
    assert(newExportSeriesType == CPRRotationExportSeriesType || newExportSeriesType == CPRSlabExportSeriesType || newExportSeriesType == CPRTransverseViewsExportSeriesType);
    if (exportSeriesType != newExportSeriesType)
	{
        [self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
        exportSeriesType = newExportSeriesType;
		
		if( exportSeriesType == CPRSlabExportSeriesType)
			self.exportImageFormat = CPR16BitExportImageFormat;
		
		if( exportSeriesType == CPRTransverseViewsExportSeriesType)
			self.exportImageFormat = CPR16BitExportImageFormat;
		
		if( exportSeriesType != CPRSlabExportSeriesType)
			self.exportSlabThickness = 0;
		
        [self didChangeValueForKey:@"exportSequenceNumberOfFrames"];
		
		[cprView setNeedsDisplay: YES];
    }
}

- (void)setExportSlabThickness:(CGFloat)newExportSlabThickness
{
    if (exportSlabThickness != newExportSlabThickness)
    {
        [self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
        exportSlabThickness = newExportSlabThickness;
        [self didChangeValueForKey:@"exportSequenceNumberOfFrames"];
    }
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
}

- (void)setExportSliceInterval:(CGFloat)newExportSliceInterval
{
    BOOL isSame;
    
    isSame = self.exportSliceIntervalSameAsVolumeSliceInterval;
    if (exportSliceInterval != newExportSliceInterval) {
        if (!isSame) {
            [self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
        }
        exportSliceInterval = fabs(newExportSliceInterval);
        if (!isSame) {
            [self didChangeValueForKey:@"exportSequenceNumberOfFrames"];        
        }
		
		self.exportSeriesType = CPRSlabExportSeriesType;
    }
}

- (void)setExportTransverseSliceInterval:(CGFloat)newExportSliceInterval
{
    if (exportTransverseSliceInterval != newExportSliceInterval)
	{
		[self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
		
        exportTransverseSliceInterval = newExportSliceInterval;
		
		[cprView setNeedsDisplay: YES];
		
		[self didChangeValueForKey:@"exportSequenceNumberOfFrames"];
    }
}

//- (void)setExportSlabThinknessSameAsSlabThickness:(BOOL)newExportSlabThinknessSameAsSlabThickness
//{
//    if (exportSlabThinknessSameAsSlabThickness != newExportSlabThinknessSameAsSlabThickness) {
//        [self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
//        exportSlabThinknessSameAsSlabThickness = newExportSlabThinknessSameAsSlabThickness;
//        if (exportSlabThinknessSameAsSlabThickness) {
//            self.exportSlabThickness = [self getClippingRangeThicknessInMm];
//        }
//        [self didChangeValueForKey:@"exportSequenceNumberOfFrames"];        
//    }
//}

- (void)setExportSliceIntervalSameAsVolumeSliceInterval:(BOOL)newExportSliceIntervalSameAsVolumeSliceInterval
{
    if (exportSliceIntervalSameAsVolumeSliceInterval != newExportSliceIntervalSameAsVolumeSliceInterval)
	{
        [self willChangeValueForKey:@"exportSequenceNumberOfFrames"];
        exportSliceIntervalSameAsVolumeSliceInterval = newExportSliceIntervalSameAsVolumeSliceInterval;
        if (exportSliceIntervalSameAsVolumeSliceInterval) {
            self.exportSliceInterval = fabs([cprView.volumeData minPixelSpacing]);
        }
		
		self.exportSeriesType = CPRSlabExportSeriesType;
		
        [self didChangeValueForKey:@"exportSequenceNumberOfFrames"];      
    }
}

//- (void) setDcmBatchReverse: (BOOL) v
//{
//	dcmBatchReverse = v;
//	
//	[self willChangeValueForKey: @"dcmFromString"];
//	[self didChangeValueForKey: @"dcmFromString"];
//	
//	[self willChangeValueForKey: @"dcmToString"];
//	[self didChangeValueForKey: @"dcmToString"];
//	
//	[mprView1 setNeedsDisplay: YES];
//	[mprView2 setNeedsDisplay: YES];
//	[mprView3 setNeedsDisplay: YES];
//}
//
//- (NSString*) getDcmFromString
//{
//	if( dcmBatchReverse) return NSLocalizedString(@"To:", nil);
//	else return NSLocalizedString(@"From:", nil);
//}
//
//- (NSString*) getDcmToString
//{
//	if( dcmBatchReverse) return NSLocalizedString(@"From:", nil);
//	else return NSLocalizedString(@"To:", nil);
//}

- (CPRMPRDCMView*) selectedView
{
	return [self selectedViewOnlyMPRView: YES];
}

- (id) selectedViewOnlyMPRView: (BOOL) onlyMPRView
{
	id v = nil;
	
	if( [[self window] firstResponder] == mprView1)
		v = mprView1;
	if( [[self window] firstResponder] == mprView2)
		v = mprView2;
	if( [[self window] firstResponder] == mprView3)
		v = mprView3;
	if( onlyMPRView == NO && [[self window] firstResponder] == cprView)
		v = cprView;
	if( onlyMPRView == NO && [[self window] firstResponder] == topTransverseView)
		v = topTransverseView;
	if( onlyMPRView == NO && [[self window] firstResponder] == middleTransverseView)
		v = middleTransverseView;
	if( onlyMPRView == NO && [[self window] firstResponder] == bottomTransverseView)
		v = bottomTransverseView;
	
	if( onlyMPRView)
	{
		if( v == nil)
			v = mprView3;
	}
	else
	{
		if( v == nil)
			v = cprView;
	}
	
	return v;
}

- (BOOL) isPlaneMeasurable
{
    if( cprType == CPRStretchedType)
        return YES;
    
    if( cprType == CPRStraightenedType)
    {
        return [cprView.curvedPath isPlaneMeasurable];
    }
    
    return NO;
}

-(IBAction) endDCMExportSettings:(id) sender
{
    NSUInteger exportWidth;
    NSUInteger exportHeight;
    float windowWidth;
    float windowLevel;
    float orientation[6];
    float origin[3];
    CPRStraightenedGeneratorRequest *requestStraightened = nil;
    CPRStretchedGeneratorRequest *requestStretched = nil;
    CPRVolumeData *curvedVolumeData;
    CPRUnsignedInt16ImageRep *imageRep;
    unsigned char *dataPtr;
    DICOMExport *dicomExport;
    CGFloat angle;
    
	[dcmWindow makeFirstResponder: nil];	// To force nstextfield validation.
	
	if( movieTimer)
		[self moviePlayStop: self];
	
	if( quicktimeExportMode)
	{
		[quicktimeWindow orderOut: sender];
		[NSApp endSheet: quicktimeWindow returnCode: [sender tag]];
		
		qtFileArray = [[NSMutableArray alloc] initWithCapacity: 0];
	}
	else
	{
		[dcmWindow orderOut: sender];
		[NSApp endSheet: dcmWindow returnCode: [sender tag]];
	}
	
    [cprView getWLWW:&windowLevel :&windowWidth];
    NSString *f = nil;
    
	if( [sender tag])
	{
		NSMutableArray *producedFiles = [NSMutableArray array];
		
        dicomExport = [[[DICOMExport alloc] init] autorelease];
        
        [dicomExport setSeriesDescription:self.exportSeriesName]; 
        [dicomExport setSeriesNumber:9983]; 
        
		if( self.exportImageFormat == CPR8BitRGBExportImageFormat)
			[dicomExport setModalityAsSource: NO];
		else
			[dicomExport setModalityAsSource: YES];
		
        [dicomExport setSourceFile:[[pixList[0] lastObject] srcFile]];
        
		if( self.viewsPosition == VerticalPosition)
        {
			exportWidth = NSHeight([cprView bounds]);
            exportHeight = NSWidth([cprView bounds]);
		}
        else
        {
            exportWidth = NSWidth([cprView bounds]);
            exportHeight = NSHeight([cprView bounds]);
		}
        
		if( self.exportSeriesType == CPRTransverseViewsExportSeriesType && self.exportSequenceType != CPRCurrentOnlyExportSequenceType)
		{
			exportWidth = NSWidth([middleTransverseView bounds]);
			exportHeight = NSHeight([middleTransverseView bounds]);
		}
		
		int resizeImage = 0;
		
		BOOL copyDisplayCrossLines = cprView.displayCrossLines;
		BOOL copyDisplayMousePosition = self.displayMousePosition;
		
		cprView.displayInfo = [[[CPRDisplayInfo alloc] init] autorelease];;
		cprView.displayCrossLines = NO;
		self.displayMousePosition = NO;
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportDCMIncludeAllCPRViews"] == NO)
			cprView.displayTransverseLines = NO;
		
		if( self.exportImageFormat == CPR16BitExportImageFormat)
		{
			switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"EXPORTMATRIXFOR3D"])
			{
				case 1: 
					exportWidth = exportHeight = 512;
					resizeImage = 512;
					break;
				case 2:
					exportWidth = exportHeight = 768;
					resizeImage = 768;
					break;
			}
		}
		
		NSMutableArray *views = nil, *viewsRect = nil;
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportDCMIncludeAllCPRViews"])
		{
			views = [NSMutableArray array];
			viewsRect = [NSMutableArray array];
			
			[views addObject: cprView];
			[views addObject: topTransverseView];
			[views addObject: middleTransverseView];
			[views addObject: bottomTransverseView];
			
			for( int i = (long)views.count-1; i >= 0; i--)
			{
				if( NSEqualRects( [[views objectAtIndex: i] visibleRect], NSZeroRect))
					[views removeObjectAtIndex: i];
			}
			
			for( NSView *v in views)
			{
				NSRect bounds = [v bounds];
				NSPoint or = [v convertPoint: bounds.origin toView: nil];
                NSRect r = {or, NSZeroSize};
                bounds.origin = [[self window] convertRectToScreen: r].origin;
                
                bounds.origin.x *= v.window.backingScaleFactor;
                bounds.origin.y *= v.window.backingScaleFactor;
                
                bounds.size.width *= v.window.backingScaleFactor;
                bounds.size.height *= v.window.backingScaleFactor;
                
				[viewsRect addObject: [NSValue valueWithRect: bounds]];
			}
		}
		
         dicomExport.rotateRawDataBy90degrees = NO;
        
		// CURRENT image only
		if( self.exportSequenceType == CPRCurrentOnlyExportSequenceType)
		{
			if( self.exportImageFormat == CPR16BitExportImageFormat)
			{
                if( cprType == CPRStraightenedType)
                {
                    requestStraightened = [[[CPRStraightenedGeneratorRequest alloc] init] autorelease];
                    requestStraightened.pixelsWide = exportWidth;
                    requestStraightened.pixelsHigh = exportHeight;
                    requestStraightened.bezierPath = curvedPath.bezierPath;
                    requestStraightened.initialNormal = curvedPath.initialNormal;    
                    
                    curvedVolumeData = [CPRGenerator synchronousRequestVolume: requestStraightened volumeData:cprView.volumeData];                            
                }
                else
                {
                    requestStretched = [[[CPRStretchedGeneratorRequest alloc] init] autorelease];
                    requestStretched.pixelsWide = exportWidth;
                    requestStretched.pixelsHigh = exportHeight;
                    requestStretched.bezierPath = curvedPath.bezierPath;
                    
                    N3Vector curveDirection = N3VectorSubtract([ curvedPath.bezierPath vectorAtEnd], [ curvedPath.bezierPath vectorAtStart]);
                    N3Vector baseNormalVector = N3VectorNormalize(N3VectorCrossProduct( curvedPath.baseDirection, curveDirection));
                    
                    requestStretched.projectionNormal = N3VectorApplyTransform( baseNormalVector, N3AffineTransformMakeRotationAroundVector( curvedPath.angle, curveDirection));
                    requestStretched.midHeightPoint = N3VectorLerp([ curvedPath.bezierPath topBoundingPlaneForNormal: requestStretched.projectionNormal].point, 
                                                          [ curvedPath.bezierPath bottomBoundingPlaneForNormal: requestStretched.projectionNormal].point, 0.5);
                    
                    curvedVolumeData = [CPRGenerator synchronousRequestVolume:requestStretched volumeData:cprView.volumeData];                            
                }  
                
                if( curvedVolumeData)
                {
                    imageRep = [curvedVolumeData unsignedInt16ImageRepForSliceAtIndex:0];
                    dataPtr = (unsigned char *)[imageRep unsignedInt16Data];
                    [dicomExport setPixelData:dataPtr samplesPerPixel:1 bitsPerSample:16 width:exportWidth height:exportHeight];
                    
                    if( self.viewsPosition == VerticalPosition)
                        dicomExport.rotateRawDataBy90degrees = YES;
                    
                    [dicomExport setOffset:[imageRep offset]];
                    [dicomExport setSigned:NO];
					
                    [dicomExport setDefaultWWWL:windowWidth :windowLevel];
					
					if( [self isPlaneMeasurable])
						[dicomExport setPixelSpacing:[imageRep pixelSpacingX]:[imageRep pixelSpacingY]];
                    
					f = [dicomExport writeDCMFile: nil];
                    if( f == nil)
					{
                        NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
                    }
                    [producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil]];
				}
			}
			else // CPR8BitRGBExportImageFormat
			{
				BOOL exportSpacingAndOrigin = [self isPlaneMeasurable];
				
				[producedFiles addObject: [[cprView reformationView] exportDCMCurrentImage: dicomExport size: resizeImage views: views viewsRect: viewsRect exportSpacingAndOrigin: exportSpacingAndOrigin]];
			}
		}
		else if (self.exportSequenceType == CPRSeriesExportSequenceType) // A 3D rotation or batch sequence
		{
			dicomExport = [[[DICOMExport alloc] init] autorelease];
			[dicomExport setSeriesDescription: self.exportSeriesName];
			[dicomExport setSeriesNumber:8930 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
            [dicomExport setSourceFile:[[pixList[0] lastObject] srcFile]];
			
			if( self.exportImageFormat == CPR8BitRGBExportImageFormat)
				[dicomExport setModalityAsSource: NO];
			else
				[dicomExport setModalityAsSource: YES];
			
			if( self.exportSeriesType == CPRRotationExportSeriesType) // 3D rotation
			{
                NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
                
                if( cprType == CPRStraightenedType)
                {
                    requestStraightened = [[[CPRStraightenedGeneratorRequest alloc] init] autorelease];
                    requestStraightened.pixelsWide = exportWidth;
                    requestStraightened.pixelsHigh = exportHeight;
                    requestStraightened.bezierPath = curvedPath.bezierPath;
                    requestStraightened.initialNormal = curvedPath.initialNormal;
                }
                else
                {
                    requestStretched = [[[CPRStretchedGeneratorRequest alloc] init] autorelease];
                    requestStretched.pixelsWide = exportWidth;
                    requestStretched.pixelsHigh = exportHeight;
                    requestStretched.bezierPath = curvedPath.bezierPath;
                    
                    N3Vector curveDirection = N3VectorSubtract([ curvedPath.bezierPath vectorAtEnd], [ curvedPath.bezierPath vectorAtStart]);
                    N3Vector baseNormalVector = N3VectorNormalize(N3VectorCrossProduct( curvedPath.baseDirection, curveDirection));
                    
                    requestStretched.projectionNormal = N3VectorApplyTransform( baseNormalVector, N3AffineTransformMakeRotationAroundVector( curvedPath.angle, curveDirection));
                    requestStretched.midHeightPoint = N3VectorLerp([ curvedPath.bezierPath topBoundingPlaneForNormal: requestStretched.projectionNormal].point, 
                                                                   [ curvedPath.bezierPath bottomBoundingPlaneForNormal: requestStretched.projectionNormal].point, 0.5);
                }
                
				N3Vector initialNormal = mprView1.curvedPath.initialNormal;
				
				Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating series", nil)];
				[progress showWindow: self];
				[progress setCancel: YES];
				[[progress progress] setMaxValue: self.exportSequenceNumberOfFrames];
				
				for( int i = 0; i < self.exportSequenceNumberOfFrames; i++)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
                    @try
                    {
                        if (self.exportRotationSpan == CPR180ExportRotationSpan)
                            angle = ((CGFloat)i/(CGFloat)self.exportSequenceNumberOfFrames) * M_PI;
                        else
                            angle = ((CGFloat)i/(CGFloat)self.exportSequenceNumberOfFrames) * 2.0*M_PI;
                        
                        if( self.exportImageFormat == CPR16BitExportImageFormat)
                        {
                            if( cprType == CPRStraightenedType)
                            {
                                requestStraightened.initialNormal = N3VectorApplyTransform(curvedPath.initialNormal, N3AffineTransformMakeRotationAroundVector(angle, [curvedPath.bezierPath tangentAtStart]));
                                
                                curvedVolumeData = [CPRGenerator synchronousRequestVolume: requestStraightened volumeData:cprView.volumeData];
                            }
                            else
                            {
                                N3Vector curveDirection = N3VectorSubtract([ curvedPath.bezierPath vectorAtEnd], [ curvedPath.bezierPath vectorAtStart]);
                                N3Vector baseNormalVector = N3VectorNormalize(N3VectorCrossProduct( curvedPath.baseDirection, curveDirection));
                                
                                requestStretched.projectionNormal = N3VectorApplyTransform( baseNormalVector, N3AffineTransformMakeRotationAroundVector( angle, curveDirection));
                                requestStretched.midHeightPoint = N3VectorLerp([ curvedPath.bezierPath topBoundingPlaneForNormal: requestStretched.projectionNormal].point, 
                                                                               [ curvedPath.bezierPath bottomBoundingPlaneForNormal: requestStretched.projectionNormal].point, 0.5);
                                
                                curvedVolumeData = [CPRGenerator synchronousRequestVolume: requestStretched volumeData:cprView.volumeData];
                            }
                            
                            if(curvedVolumeData)
                            {
                                imageRep = [curvedVolumeData unsignedInt16ImageRepForSliceAtIndex:0];
                                dataPtr = (unsigned char *)[imageRep unsignedInt16Data];
                                
                                [dicomExport setPixelData:dataPtr samplesPerPixel:1 bitsPerSample:16 width:exportWidth height:exportHeight];
                                
                                if( self.viewsPosition == VerticalPosition)
                                    dicomExport.rotateRawDataBy90degrees = YES;
                                
                                [dicomExport setOffset:[imageRep offset]];
                                [dicomExport setSigned:NO];
                                
                                [dicomExport setDefaultWWWL:windowWidth :windowLevel];
                                
                                if( [self isPlaneMeasurable])
                                    [dicomExport setPixelSpacing:[imageRep pixelSpacingX]:[imageRep pixelSpacingY]];
                                
                                f = [dicomExport writeDCMFile: nil];
                                if( f == nil)
                                {
                                    NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
                                    break;
                                }
                                [producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil]];
                            }
                        }
                        else // CPR8BitRGBExportImageFormat
                        {
                            [self CPRViewWillEditCurvedPath: mprView1];
                            mprView1.curvedPath.initialNormal = N3VectorApplyTransform( initialNormal, N3AffineTransformMakeRotationAroundVector(angle, [curvedPath.bezierPath tangentAtStart]));
                            [self CPRViewDidEditCurvedPath: mprView1];
                            
                            [cprView waitUntilPixUpdate];
                            // transverse view use synchronous generators, so this is no longer needed
                            //						[topTransverseView runMainRunLoopUntilAllRequestsAreFinished];
                            //						[middleTransverseView runMainRunLoopUntilAllRequestsAreFinished];
                            //						[bottomTransverseView runMainRunLoopUntilAllRequestsAreFinished];
                            
                            BOOL exportSpacingAndOrigin = [self isPlaneMeasurable];
                            
                            [producedFiles addObject: [[cprView reformationView] exportDCMCurrentImage: dicomExport size: resizeImage views: views viewsRect: viewsRect exportSpacingAndOrigin: exportSpacingAndOrigin]];
                        }
                    }
                    @catch (NSException *e) {
                        NSLog( @"%@", e);
                    }
                    @finally {
                        [pool release];
                    }
					
					[progress incrementBy: 1];
					if( [progress aborted])
						break;
				}
				
				[progress close];
				[progress autorelease];
                
                NSLog( @"Export Rotation: %f",  (float) ([NSDate timeIntervalSinceReferenceDate] - start));
			}
			else if(self.exportSeriesType == CPRSlabExportSeriesType)
			{
                Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating series", nil)];
				[progress showWindow: self];
				[progress setCancel: YES];
				[[progress progress] setMaxValue: self.exportSequenceNumberOfFrames];
                
                if( cprType == CPRStraightenedType)
                {
                    requestStraightened = [[[CPRStraightenedGeneratorRequest alloc] init] autorelease];
                    requestStraightened.pixelsWide = exportWidth;
                    requestStraightened.pixelsHigh = exportHeight;
                    if (self.exportSequenceNumberOfFrames > 1)
                    {
                        //					if (self.exportSlabThinknessSameAsSlabThickness)
                        //						requestStraightened.slabWidth = [self getClippingRangeThicknessInMm];
                        //					else
						requestStraightened.slabWidth = exportSlabThickness;
                        
                        if (self.exportSliceIntervalSameAsVolumeSliceInterval)
                            requestStraightened.slabSampleDistance = [cprView.volumeData minPixelSpacing];
                        else
                            requestStraightened.slabSampleDistance = self.exportSliceInterval;
                    }
                    requestStraightened.bezierPath = curvedPath.bezierPath;
                    requestStraightened.initialNormal = curvedPath.initialNormal;
                    curvedVolumeData = [CPRGenerator synchronousRequestVolume: requestStraightened volumeData:cprView.volumeData];
                }
                else
                {
                    requestStretched = [[[CPRStretchedGeneratorRequest alloc] init] autorelease];
                    requestStretched.pixelsWide = exportWidth;
                    requestStretched.pixelsHigh = exportHeight;
                    if (self.exportSequenceNumberOfFrames > 1)
                    {
                        //					if (self.exportSlabThinknessSameAsSlabThickness)
                        //						requestStretched.slabWidth = [self getClippingRangeThicknessInMm];
                        //					else
						requestStretched.slabWidth = exportSlabThickness;
                        
                        if (self.exportSliceIntervalSameAsVolumeSliceInterval)
                            requestStretched.slabSampleDistance = [cprView.volumeData minPixelSpacing];
                        else
                            requestStretched.slabSampleDistance = self.exportSliceInterval;
                    }
                    requestStretched.bezierPath = curvedPath.bezierPath;
                    
                    N3Vector curveDirection = N3VectorSubtract([ curvedPath.bezierPath vectorAtEnd], [ curvedPath.bezierPath vectorAtStart]);
                    N3Vector baseNormalVector = N3VectorNormalize(N3VectorCrossProduct( curvedPath.baseDirection, curveDirection));
                    
                    requestStretched.projectionNormal = N3VectorApplyTransform( baseNormalVector, N3AffineTransformMakeRotationAroundVector( curvedPath.angle, curveDirection));
                    requestStretched.midHeightPoint = N3VectorLerp([ curvedPath.bezierPath topBoundingPlaneForNormal: requestStretched.projectionNormal].point, 
                                                                   [ curvedPath.bezierPath bottomBoundingPlaneForNormal: requestStretched.projectionNormal].point, 0.5);
                    
                    curvedVolumeData = [CPRGenerator synchronousRequestVolume: requestStretched volumeData:cprView.volumeData];
                }
                
				if(curvedVolumeData)
				{
					for( int i = 0; i < self.exportSequenceNumberOfFrames; i++)
					{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						
                        //						if (self.exportImageFormat == CPR16BitExportImageFormat)
                        @try
						{  
                            if (self.exportReverseSliceOrder == NO)
                                imageRep = [curvedVolumeData unsignedInt16ImageRepForSliceAtIndex:i];
							else
                                imageRep = [curvedVolumeData unsignedInt16ImageRepForSliceAtIndex:self.exportSequenceNumberOfFrames - i - 1];
                            
                            dataPtr = (unsigned char *)[imageRep unsignedInt16Data];
                            
                            [dicomExport setPixelData:dataPtr samplesPerPixel:1 bitsPerSample:16 width:exportWidth height:exportHeight];
                            
                            if( self.viewsPosition == VerticalPosition)
                                dicomExport.rotateRawDataBy90degrees = YES;
                            
                            [dicomExport setOffset:[imageRep offset]];
                            [dicomExport setSigned:NO];
                            
                            [dicomExport setDefaultWWWL:windowWidth :windowLevel];
							
							if( [self isPlaneMeasurable])
								[dicomExport setPixelSpacing:[imageRep pixelSpacingX]:[imageRep pixelSpacingY]];
							
                            f = [dicomExport writeDCMFile: nil];
                            if( f == nil)
							{
                                NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
                                break;
                            }
                            [producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil]];
                        }
						@catch (NSException *e) {
                            NSLog( @"%@", e);
                        }
                        @finally {
                            [pool release];
                        }
						
						[progress incrementBy: 1];
						if( [progress aborted])
							break;
                    }
                }
				[progress close];
				[progress autorelease];
			}
			else if( self.exportSeriesType == CPRTransverseViewsExportSeriesType)
			{
				Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating series", nil)];
				[progress showWindow: self];
				[progress setCancel: YES];
				[[progress progress] setMaxValue: self.exportSequenceNumberOfFrames];
				
				NSArray *requests = [curvedPath transverseSliceRequestsForSpacing: self.exportTransverseSliceInterval outputWidth: exportWidth outputHeight: exportHeight mmWide: [[middleTransverseView curDCM] pwidth] * [[middleTransverseView curDCM] pixelSpacingX]];
				
				for( CPRObliqueSliceGeneratorRequest *r in requests)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
                    @try {
                        curvedVolumeData = [CPRGenerator synchronousRequestVolume: r volumeData:cprView.volumeData];
                        if(curvedVolumeData)
                        {
                            imageRep = [curvedVolumeData unsignedInt16ImageRepForSliceAtIndex: 0];
                            
                            dataPtr = (unsigned char *)[imageRep unsignedInt16Data];
                            
                            [dicomExport setPixelData:dataPtr samplesPerPixel:1 bitsPerSample:16 width:exportWidth height:exportHeight];
                            
                            [dicomExport setOffset:[imageRep offset]];
                            [dicomExport setSlope:[imageRep slope]];
                            [dicomExport setSigned:NO];
                            
                            [dicomExport setDefaultWWWL:windowWidth :windowLevel];
                            
                            [dicomExport setPixelSpacing:[imageRep pixelSpacingX]:[imageRep pixelSpacingY]];
                            
                            [imageRep getOrientation:orientation];
                            origin[0] = [imageRep originX];
                            origin[1] = [imageRep originY];
                            origin[2] = [imageRep originZ];
                            
                            [dicomExport setOrientation:orientation];
                            [dicomExport setPosition:origin];
                            
                            f = [dicomExport writeDCMFile: nil];
                            if( f == nil)
                            {
                                NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
                                break;
                            }
                            [producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil]];
                        }
                    }
                    @catch (NSException *e) {
                        NSLog( @"%@", e);
                    }
                    @finally {
                        [pool release];
                    }
					
					[progress incrementBy: 1];
					if( [progress aborted])
						break;
                }
				[progress close];
				[progress autorelease];
			}
		}
		
		if( quicktimeExportMode == NO)
		{
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
		
		cprView.displayCrossLines = copyDisplayCrossLines;
        cprView.displayInfo = displayInfo;
		self.displayMousePosition = copyDisplayMousePosition;
		cprView.displayTransverseLines = YES;
        
    }
    //		else
    //		{
    //			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :[qtFileArray count]];
    //			[mov createMovieQTKit: YES  :NO :[[filesList[0] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];			
    //			[mov release];
    //		}
    
    //		if( self.dcmFormat) 
    //			[curExportView.vrView restoreViewSizeAfterMatrix3DExport];
    
    //		[self setLOD: savedLOD];
    
    //		[[NSUserDefaults standardUserDefaults] setInteger: dcmMode forKey: @"lastMPRdcmExportMode"];
    
    //		mprView1.camera = c1;
    //		mprView2.camera = c2;
    //		mprView3.camera = c3;
    
    //		[self updateViewsAccordingToFrame: nil];
	
	[qtFileArray release];
	qtFileArray = nil;
	quicktimeExportMode = NO;
	self.exportSlabThickness = 0;
	self.exportTransverseSliceInterval = 0;
}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	return [qtFileArray objectAtIndex: [cur intValue]];
}

- (void) exportDICOMFile:(id) sender
{
	if( [quicktimeWindow isVisible])
		return;
	if( [dcmWindow isVisible])
		return;
	
	curExportView = [self selectedView];
	
	if( quicktimeExportMode)
        [NSApp beginSheet:quicktimeWindow modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:NULL];
	else
        [NSApp beginSheet:dcmWindow modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:NULL];
    
    self.exportSlabThickness = fabs([self getClippingRangeThicknessInMm]);
    self.exportSliceInterval = fabs([cprView.volumeData minPixelSpacing]);
    self.exportTransverseSliceInterval = fabs([curvedPath transverseSectionSpacing]);
	self.exportNumberOfRotationFrames = 50;
	
	if( clippingRangeThickness <= 3)
	{
//		self.exportSlabThinknessSameAsSlabThickness = NO;
        self.exportSliceIntervalSameAsVolumeSliceInterval = NO;
	}
	else
    {
//		self.exportSlabThinknessSameAsSlabThickness = YES;
        self.exportSliceIntervalSameAsVolumeSliceInterval = YES;
    }
	
    self.exportImageFormat = CPR8BitRGBExportImageFormat;
	
	if( quicktimeExportMode)
	{
		if( self.exportSequenceType == CPRCurrentOnlyExportSequenceType) // Current Image is not supported for Quicktime Export
			self.exportSequenceType = CPRSeriesExportSequenceType;
	}
	
	if( [self getMovieDataAvailable] == NO && self.exportSequenceType == CPRSeriesExportSequenceType)
		self.exportSequenceType = CPRCurrentOnlyExportSequenceType;
}

//- (void) exportQuicktime:(id) sender
//{
//	if( [quicktimeWindow isVisible])
//		return;
//	if( [dcmWindow isVisible])
//		return;
//    
//	quicktimeExportMode = YES;
//	[self exportDICOMFile: sender];
//}

//- (void) displayFromToSlices
//{
//	mprView1.viewExport = mprView2.viewExport = mprView3.viewExport = -1;
//	
//	if( curExportView == mprView3)
//	{
//		if( dcmSeriesMode == 0) // Batch
//		{
//			mprView1.toIntervalExport = dcmTo;
//			mprView1.fromIntervalExport = dcmFrom;
//			mprView1.viewExport = 1;
//			
//			mprView2.toIntervalExport = dcmTo;
//			mprView2.fromIntervalExport = dcmFrom;
//			mprView2.viewExport = 1;
//		}
//		else // Rotation
//		{
//			if( dcmRotationDirection == 1)
//				mprView1.viewExport = 1;
//			else
//				mprView2.viewExport = 1;
//		}
//	}
//	
//	if( curExportView == mprView2)
//	{
//		if( dcmSeriesMode == 0) // Batch
//		{
//			mprView1.toIntervalExport = dcmTo;
//			mprView1.fromIntervalExport = dcmFrom;
//			mprView1.viewExport = 0;
//			
//			mprView3.toIntervalExport = dcmTo;
//			mprView3.fromIntervalExport = dcmFrom;
//			mprView3.viewExport = 1;
//		}
//		else // Rotation
//		{
//			if( dcmRotationDirection == 1)
//				mprView1.viewExport = 0;
//			else
//				mprView3.viewExport = 1;
//		}
//	}
//	
//	if( curExportView == mprView1)
//	{
//		if( dcmSeriesMode == 0) // Batch
//		{
//			mprView2.toIntervalExport = dcmTo;
//			mprView2.fromIntervalExport = dcmFrom;
//			mprView2.viewExport = 0;
//			
//			mprView3.toIntervalExport = dcmTo;
//			mprView3.fromIntervalExport = dcmFrom;
//			mprView3.viewExport = 0;
//		}
//		else // Rotation
//		{
//			if( dcmRotationDirection == 1)
//				mprView3.viewExport = 0;
//			else
//				mprView2.viewExport = 0;
//		}
//	}
//	
//	[mprView1 setNeedsDisplay: YES];
//	[mprView2 setNeedsDisplay: YES];
//	[mprView3 setNeedsDisplay: YES];
//	
//	self.dcmBatchNumberOfFrames = 1 + dcmTo + dcmFrom;
//}

- (void) setExportImageFormat: (NSInteger) f
{
	exportImageFormat = f;
	
	if( exportImageFormat == CPR16BitExportImageFormat)
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"exportDCMIncludeAllCPRViews"];
	
	if( exportImageFormat == CPR8BitRGBExportImageFormat)
	{
		if( self.exportSeriesType == CPRSlabExportSeriesType)
			self.exportSeriesType = CPRRotationExportSeriesType;
		
		if( self.exportSeriesType == CPRTransverseViewsExportSeriesType)
			self.exportSeriesType = CPRRotationExportSeriesType;
		
		[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey:@"EXPORTMATRIXFOR3D"];
	}
}

//- (void) setDcmSeriesMode: (int) f
//{
//	dcmSeriesMode = f;
//	
////	[self displayFromToSlices];
//}
//
//- (void) setDcmMode: (int) f
//{
//	dcmMode = f;
//	
////	[self displayFromToSlices];
//}
//
//- (void) setDcmInterval:(float) f
//{    
//	dcmInterval = f;
//	
//	if( previousDcmInterval)
//	{
//		self.dcmTo =  round(( (float) dcmTo * previousDcmInterval) /  dcmInterval);
//		self.dcmFrom = round(( (float) dcmFrom * previousDcmInterval) / dcmInterval);
//	}
//	
//	previousDcmInterval = f;
//	
////	[self displayFromToSlices];
//}
//
//- (void)setDcmSameExportSlabThinknessAsThickSlab:(BOOL)newDcmSameExportSlabThinknessAsThickSlab
//{
//    if (dcmSameExportSlabThinknessAsThickSlab != newDcmSameExportSlabThinknessAsThickSlab) {
//        dcmSameExportSlabThinknessAsThickSlab = newDcmSameExportSlabThinknessAsThickSlab;
//        
//        if (dcmSameExportSlabThinknessAsThickSlab) {
//            self.exportSlabThickness = [self getClippingRangeThicknessInMm];
//        }
//    }
//}
//
//- (void) setDcmRotation:(int) v
//{
//	dcmRotation = v;
////	[self displayFromToSlices];
//}
//
//- (void) setDcmRotationDirection:(int) v
//{
//	dcmRotationDirection = v;
////	[self displayFromToSlices];
//}
//
//- (void) setDcmNumberOfFrames:(int) v
//{
//	dcmNumberOfFrames = v;
////	[self displayFromToSlices];
//}
//
//- (void) setDcmTo:(int) f
//{
//	dcmTo = f;
////	[self displayFromToSlices];
//}
//
//- (void) setDcmFrom:(int) f
//{
//	dcmFrom = f;
////	[self displayFromToSlices];
//}
//
//- (void) setDcmSameIntervalAndThickness: (BOOL) f
//{
//	dcmSameIntervalAndThickness = f;
//	
//	if( dcmSameIntervalAndThickness)
//		self.dcmInterval = [curExportView.vrView getClippingRangeThicknessInMm];
//}

-(void) sendMail:(id) sender
{
	NSImage *im = [[self selectedView] nsimage:NO];
	
	[self sendMailImage: im];
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
    
	[panel setCanSelectHiddenExtension:YES];
    [panel setAllowedFileTypes:@[@"jpg"]];
    panel.nameFieldStringValue = NSLocalizedString(@"Curved MPR Image", nil);
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSImage *im = [[self selectedViewOnlyMPRView: NO] nsimage:NO];
        
        NSArray *representations;
        NSData *bitmapData;
        
        representations = [im representations];
        
        if( representations.count)
        {
            bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
            
            [bitmapData writeToURL:panel.URL atomically:YES];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
                [[NSWorkspace sharedWorkspace] openURL:panel.URL];
        }
    }];
}

-(void) export2iPhoto:(id) sender
{
	Photos		*ifoto;
	NSImage		*im = [[self selectedView] nsimage:NO];
	
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

- (void) exportTIFF:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];
    
	[panel setCanSelectHiddenExtension:YES];
    [panel setAllowedFileTypes:@[@"tif"]];
    panel.nameFieldStringValue = @"3D MPR Image";
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSImage *im = [[self selectedView] nsimage:NO];
        
        [[im TIFFRepresentation] writeToURL:panel.URL atomically:YES];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"])
            [[NSWorkspace sharedWorkspace] openURL:panel.URL];
    }];
}

//- (int)dcmBatchNumberOfFrames
//{
//    CGFloat slabWidth;
//    CGFloat sliceInterval;
//    if (self.dcmMode < 2) { // export current only, or 4D
//        return 1;
//    } else if (self.dcmMode == 2) { // export a series
//        if (self.dcmSeriesMode == 0) { // a rotation
//            return dcmNumberOfRotationFrames;
//        } else if (self.dcmSeriesMode == 1) {
//            if (self.dcmSameExportSlabThinknessAsThickSlab) {
//                slabWidth = [self getClippingRangeThicknessInMm];
//            } else {
//                slabWidth = exportSlabThickness;
//            }
//            
//            if (self.dcmSameIntervalAndThickness) {
//                sliceInterval = [cprView.volumeData minPixelSpacing];
//            } else {
//                sliceInterval = dcmInterval;
//            }
//            
//            return slabWidth / sliceInterval;
//        }
//    }
//    return 0;
//}

#pragma mark Path Loading And Saving

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
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

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
    NSArray	*types = [NSArray arrayWithObjects: NSFilenamesPboardType, nil];
    NSString *desiredType = [paste availableTypeFromArray: types];

    if( [desiredType isEqualToString: NSFilenamesPboardType])
    {
        NSArray *fileArray = [paste propertyListForType: @"NSFilenamesPboardType"];
        
        for( NSString *file in fileArray)
        {
            if( [[file pathExtension] isEqualToString: @"curvedPath"])
            {
                [self loadBezierPathFromFile: file];
                
                return YES;
            }
        }
    }
    
    return NO;
}

- (IBAction) saveBezierPath: (id) sender
{
    NSSavePanel *sPanel	= [NSSavePanel savePanel];
    [sPanel setAllowedFileTypes:@[@"curvedPath"]];
    sPanel.nameFieldStringValue = [[[viewer2D currentStudy] valueForKey: @"name"] stringByAppendingPathExtension: @"curvedPath"];
    
    [sPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [self saveBezierPathToFile:sPanel.URL.path];
    }];
}

- (IBAction) loadBezierPath: (id) sender;
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowedFileTypes:@[@"curvedPath"]];
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [self loadBezierPathFromFile:oPanel.URL.path];
    }];
}

-(void) saveBezierPathToFile: (NSString*) path
{
    NSData *curvedPathData = [NSKeyedArchiver archivedDataWithRootObject:curvedPath];

    [curvedPathData writeToFile: path atomically: YES];
}

-(void) loadBezierPathFromFile: (NSString*) path
{
    NSData *data = [NSData dataWithContentsOfFile: path];
    if( data)
    {
        CPRCurvedPath *newCurvedPath = [NSKeyedUnarchiver unarchiveObjectWithData: data];
        
        if( newCurvedPath)
        {
            self.curvedPath = newCurvedPath;
            
            mprView1.curvedPath = curvedPath;
			mprView2.curvedPath = curvedPath;
			mprView3.curvedPath = curvedPath;
			cprView.curvedPath = curvedPath;
			topTransverseView.curvedPath = curvedPath;
			middleTransverseView.curvedPath = curvedPath;
			bottomTransverseView.curvedPath = curvedPath;
            
            self.clippingRangeThicknessInMm = curvedPath.thickness;
        }
    }
}

#pragma mark NSWindow Notifications action

- (ViewerController*) viewer
{
	return viewer2D;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
        // Save current path for next time
        NSString *path = [[[BrowserController currentBrowser] database] statesDirPath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
            [[NSFileManager defaultManager] createDirectoryAtPath: path withIntermediateDirectories:YES attributes:nil error:NULL];
        
        path = [path stringByAppendingPathComponent: [NSString stringWithFormat:@"CPR-%@", [[[viewer2D fileList: 0] objectAtIndex:0] valueForKey:@"uniqueFilename"]]];
        
        if( path)
            [self saveBezierPathToFile: path];
        
        // *******
        
        cprView.rotation = 0;
        
		[[self window] setAcceptsMouseMovedEvents: NO];
		
		windowWillClose = YES;
		
		[[NSUserDefaults standardUserDefaults] setBool: self.displayMousePosition forKey: @"MPRDisplayMousePosition"];
        [[NSUserDefaults standardUserDefaults] setInteger: self.cprType forKey: @"SavedCPRType"];
        
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(updateViewsAccordingToFrame:) object: nil];
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(delayedFullLODRendering:) object: nil];
		
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixWindow3dCloseNotification object: self userInfo: 0];
		
		if( movieTimer)
		{
			[movieTimer invalidate];
			[movieTimer release];
			movieTimer = nil;
		}
		
		[hiddenVRController close];
		[hiddenVRController release];
		
		[ob setContent: nil];	// To allow the dealloc of CPRController ! otherwise memory leak
		
		[self autorelease];
	}
}

/*
#pragma mark Shadings

- (IBAction)switchShading:(id)sender;
{
	[hiddenVRView switchShading:sender];
	
	[mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPR];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPR];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPR];
	
}

- (IBAction)applyShading:(id)sender;
{
	NSDictionary *dict = [[shadingsPresetsController selectedObjects] lastObject];
	
	float ambient, diffuse, specular, specularpower;
	
	ambient = [[dict valueForKey:@"ambient"] floatValue];
	diffuse = [[dict valueForKey:@"diffuse"] floatValue];
	specular = [[dict valueForKey:@"specular"] floatValue];
	specularpower = [[dict valueForKey:@"specularPower"] floatValue];
	
	float sambient, sdiffuse, sspecular, sspecularpower;	
	[hiddenVRView getShadingValues: &sambient :&sdiffuse :&sspecular :&sspecularpower];
	
	if( sambient != ambient || sdiffuse != diffuse || sspecular != specular || sspecularpower != specularpower)
	{
		[hiddenVRView setShadingValues: ambient :diffuse :specular :specularpower];
		[shadingValues setStringValue: [NSString stringWithFormat: NSLocalizedString( @"Ambient: %2.2f\nDiffuse: %2.2f\nSpecular :%2.2f, %2.2f", nil), ambient, diffuse, specular, specularpower]];
        
		[mprView1 restoreCamera];
		mprView1.camera.forceUpdate = YES;
		[mprView1 updateViewMPR];
		
		[mprView2 restoreCamera];
		mprView2.camera.forceUpdate = YES;
		[mprView2 updateViewMPR];
		
		[mprView3 restoreCamera];
		mprView3.camera.forceUpdate = YES;
		[mprView3 updateViewMPR];		
	}
}

- (void)findShadingPreset:(id)sender;
{
	float ambient, diffuse, specular, specularpower;
	
	[hiddenVRView getShadingValues: &ambient :&diffuse :&specular :&specularpower];
	
	NSArray *shadings = [shadingsPresetsController arrangedObjects];
	int i;
	for( i = 0; i < [shadings count]; i++)
	{
		NSDictionary *dict = [shadings objectAtIndex: i];
		if( ambient == [[dict valueForKey:@"ambient"] floatValue] && diffuse == [[dict valueForKey:@"diffuse"] floatValue] && specular == [[dict valueForKey:@"specular"] floatValue] && specularpower == [[dict valueForKey:@"specularPower"] floatValue])
		{
			[shadingsPresetsController setSelectedObjects: [NSArray arrayWithObject: dict]];
			break;
		}
	}
}

- (IBAction)editShadingValues:(id)sender;
{
	[shadingPanel makeKeyAndOrderFront: self];
	[self findShadingPreset: self];
}
*/

#pragma mark Toolbar

- (void) setupToolbar
{
	toolbar = [[NSToolbar alloc] initWithIdentifier: @"3DMPR Toolbar Identifier"];
    
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    
    [toolbar setDelegate: self];
    
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton: NO];
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

- (IBAction)customizeViewerToolBar:(id)sender
{
    [toolbar runCustomizationPalette:sender];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqualToString: @"tbLOD"])
    {
        [toolbarItem setLabel: NSLocalizedString(@"LOD",nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString( @"LOD",nil)];
        
        [toolbarItem setView: tbLOD];
        [toolbarItem setMinSize: NSMakeSize(NSWidth([tbLOD frame]), NSHeight([tbLOD frame]))];
    }
    else
	if ([itemIdent isEqualToString: @"tbCPRType"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Reformation Type",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Reformation Type",nil)];
		
		[toolbarItem setView: tbCPRType];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbCPRType frame]), NSHeight([tbCPRType frame]))];
    }
    else if ([itemIdent isEqualToString: @"tbCPRPathMode"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Path Mode",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Path Mode",nil)];
		
		[toolbarItem setView: tbCPRPathMode];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbCPRPathMode frame]), NSHeight([tbCPRPathMode frame]))];
    }
    else if ([itemIdent isEqualToString: @"tbViewsPosition"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Views",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Views",nil)];
		
		[toolbarItem setView: tbViewsPosition];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbViewsPosition frame]), NSHeight([tbViewsPosition frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbStraightenedCPRAngle"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Curved MPR Angle",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Curved MPR Angle",nil)];
		
		[toolbarItem setView: tbStraightenedCPRAngle];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbStraightenedCPRAngle frame]), NSHeight([tbStraightenedCPRAngle frame]))];
    }    
	else if ([itemIdent isEqualToString: @"Reset.pdf"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Reset",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Reset",nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"Reset.pdf"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showWindow:)];
    }
	else if ([itemIdent isEqualToString: @"Export.icns"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"DICOM",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"DICOM",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Export this image in a DICOM file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"Export.icns"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportDICOMFile:)];
    }
    else if ([itemIdent isEqualToString: @"curvedPath.icns"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Curved Path",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Curved Path",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Export this curved path in a file",nil)];
		[toolbarItem setImage: [NSImage imageNamed: @"curvedPath.icns"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(saveBezierPath:)];
    }
//	else if ([itemIdent isEqualToString: @"BestRendering.pdf"])
//	{
//		[toolbarItem setLabel: NSLocalizedString(@"Best",nil)];
//		[toolbarItem setPaletteLabel:NSLocalizedString(@"Best",nil)];
//		[toolbarItem setImage: [NSImage imageNamed: @"BestRendering.pdf"]];
//		[toolbarItem setTarget: self];
//		[toolbarItem setAction: @selector(bestRendering:)];
//    }
//	else if ([itemIdent isEqualToString: @"QTExport.pdf"])
//	{
//		[toolbarItem setLabel: NSLocalizedString(@"Movie Export",nil)];
//		[toolbarItem setPaletteLabel:NSLocalizedString(@"Movie Export",nil)];
//		[toolbarItem setImage: [NSImage imageNamed: @"QTExport.icns"]];
//		[toolbarItem setTarget: self];
//		[toolbarItem setAction: @selector(exportQuicktime:)];
//    }
//	else if ([itemIdent isEqualToString: @"tbBlending"])
//	{
//		[toolbarItem setLabel: NSLocalizedString(@"Fusion",nil)];
//		[toolbarItem setPaletteLabel:NSLocalizedString( @"Fusion",nil)];
//		
//		[toolbarItem setView: tbBlending];
//		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbBlending frame]), NSHeight([tbBlending frame]))];
//    }
	else if ([itemIdent isEqualToString: @"tbThickSlab"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Thick Slab",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Thick Slab",nil)];
		
		[toolbarItem setView: tbThickSlab];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbThickSlab frame]), NSHeight([tbThickSlab frame]))];
        [toolbarItem setMaxSize: NSMakeSize(2*NSWidth([tbThickSlab frame]), NSHeight([tbThickSlab frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbWLWW"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"WL & WW",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"WL & WW",nil)];
		
		[toolbarItem setView: tbWLWW];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbWLWW frame]), NSHeight([tbWLWW frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbTools"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Tools",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Tools",nil)];
		
		[toolbarItem setView: tbTools];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbTools frame]), NSHeight([tbTools frame]))];
    }
	else if ([itemIdent isEqualToString: @"tbPathAssistant"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Path Assistant",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Path Assistant",nil)];
		[toolbarItem setToolTip:NSLocalizedString(@"Automatically finds a path between two points", nil)];
		
		[toolbarItem setView: tbPathAssistant];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbPathAssistant frame]), NSHeight([tbPathAssistant frame]))];
    }
    else if ([itemIdent isEqualToString: @"tbHighRes"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Resolution",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Resolution",nil)];
		
		[toolbarItem setView: tbHighResolution];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbHighResolution frame]), NSHeight([tbHighResolution frame]))];
    }
    else if ([itemIdent isEqualToString: @"tbInterpolationMode"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Interpolation Mode",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Interpolation Mode",nil)];
		
		[toolbarItem setView: tbInterpolationMode];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbInterpolationMode frame]), NSHeight([tbInterpolationMode frame]))];
    }
//	else if ([itemIdent isEqualToString: @"tbMovie"])
//	{
//		[toolbarItem setLabel: NSLocalizedString(@"4D Player",nil)];
//		[toolbarItem setPaletteLabel:NSLocalizedString( @"4D Player",nil)];
//		
//		[toolbarItem setView: tbMovie];
//		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbMovie frame]), NSHeight([tbMovie frame]))];
//    }
//	else if ([itemIdent isEqualToString: @"tbShading"])
//	{
//		[toolbarItem setLabel: NSLocalizedString(@"Shadings",nil)];
//		[toolbarItem setPaletteLabel:NSLocalizedString( @"Shadings",nil)];
//		
//		[toolbarItem setView: tbShading];
//		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbShading frame]), NSHeight([tbShading frame]))];
//    }
	else if ([itemIdent isEqualToString:@"AxisColors"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Axis Colors",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Axis Colors",nil)];
		[toolbarItem setView: tbAxisColors];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbAxisColors frame]), NSHeight([tbAxisColors frame]))];
    }
	else if ([itemIdent isEqualToString:@"AxisShowHide"])
	{
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Axis",nil)];
		
		[toolbarItem setLabel:NSLocalizedString(@"Axis",nil)];
		if( ![[self selectedViewOnlyMPRView: YES] displayCrossLines])
			[toolbarItem setImage:[NSImage imageNamed:@"MPRAxisHide"]];
		else
			[toolbarItem setImage:[NSImage imageNamed:@"MPRAxisShow"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(toogleAxisVisibility:)];
    }
    else if ([itemIdent isEqualToString:@"CPRAxisShowHide"])
	{
		[toolbarItem setPaletteLabel:NSLocalizedString(@"CPR Axis",nil)];
		
		[toolbarItem setLabel:NSLocalizedString(@"CPR Axis",nil)];
		if( !cprView.displayCrossLines)
			[toolbarItem setImage:[NSImage imageNamed:@"MPRAxisHide"]];
		else
			[toolbarItem setImage:[NSImage imageNamed:@"MPRAxisShow"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(toogleCPRAxisVisibility:)];
    }
	else if ([itemIdent isEqualToString:@"MousePositionShowHide"])
	{
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Mouse Position",nil)];
		
		[toolbarItem setLabel:NSLocalizedString(@"Mouse Position",nil)];
		if( !self.displayMousePosition)
			[toolbarItem setImage:[NSImage imageNamed:@"MPRMousePositionHide"]];
		else
			[toolbarItem setImage:[NSImage imageNamed:@"MPRMousePositionShow"]];
		
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(toogleMousePositionVisibility:)];
    }
	else if ([itemIdent isEqualToString: @"syncZoomLevel"])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Sync Zoom",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString( @"Sync Zoom",nil)];
		
		[toolbarItem setView: tbSyncZoomLevel];
		[toolbarItem setMinSize: NSMakeSize(NSWidth([tbSyncZoomLevel frame]), NSHeight([tbSyncZoomLevel frame]))];
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

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects: @"tbTools", @"tbWLWW", @"tbLOD", @"tbStraightenedCPRAngle", @"tbCPRType", @"tbHighRes", @"tbPathAssistant", @"testDelNode", @"tbCPRPathMode", @"tbViewsPosition", @"tbThickSlab", NSToolbarFlexibleSpaceItemIdentifier, @"Reset.pdf", @"Export.icns", @"curvedPath.icns", @"BestRendering.pdf", @"AxisShowHide", @"CPRAxisShowHide", @"MousePositionShowHide", @"syncZoomLevel", nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray *array = [NSMutableArray arrayWithObjects: NSToolbarCustomizeToolbarItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarSeparatorItemIdentifier,
            @"tbTools", @"tbWLWW", @"tbLOD", @"tbStraightenedCPRAngle", @"tbCPRType", @"tbHighRes", @"tbPathAssistant", @"tbCPRPathMode", @"tbViewsPosition", @"tbThickSlab", @"Reset.pdf", @"Export.icns", @"curvedPath.icns", @"BestRendering.pdf", @"AxisColors", @"AxisShowHide", @"CPRAxisShowHide", @"MousePositionShowHide", @"syncZoomLevel", @"tbInterpolationMode", nil];
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarAllowedIdentifiersForViewer:)])
            [array addObjectsFromArray: [[[PluginManager plugins] objectForKey:key] toolbarAllowedIdentifiersForViewer: self]];
    }
    
    return array;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if( [item action] == @selector(exportDICOMFile:))
	{
		if( [curvedPath.nodes count] < 3)
			return NO;
	}
	
    if( [item action] == @selector(saveBezierPath:))
	{
		if( [curvedPath.nodes count] < 3)
			return NO;
	}
    
	return YES;
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
	if ([[toolbarItem itemIdentifier] isEqualToString: @"tbStraightenedCPRAngle"])
	{
		if( [curvedPath.nodes count] < 3)
			return NO;
	}
	
	if ([[toolbarItem itemIdentifier] isEqualToString: @"Export.icns"])
	{
		if( [curvedPath.nodes count] < 3)
			return NO;
	}
    
    if ([[toolbarItem itemIdentifier] isEqualToString: @"curvedPath.icns"])
	{
		if( [curvedPath.nodes count] < 3)
			return NO;
	}
    
	return YES;
}

- (void)updateToolbarItems;
{
	NSArray *toolbarItems = [toolbar items];
	for(NSToolbarItem *item in toolbarItems)
	{
		if([[item itemIdentifier] isEqualToString:@"AxisShowHide"])
		{
			if( ![[self selectedViewOnlyMPRView: YES] displayCrossLines])
				[item setImage:[NSImage imageNamed:@"MPRAxisHide"]];
			else
				[item setImage:[NSImage imageNamed:@"MPRAxisShow"]];
		}
        else if([[item itemIdentifier] isEqualToString:@"CPRAxisShowHide"])
		{
			if( !cprView.displayCrossLines)
				[item setImage:[NSImage imageNamed:@"MPRAxisHide"]];
			else
				[item setImage:[NSImage imageNamed:@"MPRAxisShow"]];
		}
		else if([[item itemIdentifier] isEqualToString:@"MousePositionShowHide"])
		{
			if( !self.displayMousePosition)
				[item setImage:[NSImage imageNamed:@"MPRMousePositionHide"]];
			else
				[item setImage:[NSImage imageNamed:@"MPRMousePositionShow"]];
		}
	}
}

#pragma mark Axis / Mouse Position : Show / Hide

- (void)toogleCPRAxisVisibility:(id) sender;
{
    cprView.displayCrossLines = !cprView.displayCrossLines;

    topTransverseView.displayCrossLines = !topTransverseView.displayCrossLines;
    middleTransverseView.displayCrossLines = !middleTransverseView.displayCrossLines;
    bottomTransverseView.displayCrossLines = !bottomTransverseView.displayCrossLines;
	
	[cprView setNeedsDisplay: YES];
	[topTransverseView setNeedsDisplay: YES];
	[middleTransverseView setNeedsDisplay: YES];
	[bottomTransverseView setNeedsDisplay: YES];
	
	[self updateToolbarItems];
}


- (void)toogleAxisVisibility:(id) sender;
{
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask)
	{
		[[self selectedViewOnlyMPRView: YES] setDisplayCrossLines: ![[self selectedViewOnlyMPRView: YES] displayCrossLines]];
	}
	else
	{
		mprView1.displayCrossLines = !mprView1.displayCrossLines;
		mprView2.displayCrossLines = !mprView2.displayCrossLines;
		mprView3.displayCrossLines = !mprView3.displayCrossLines;
	}
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
	
	[self updateToolbarItems];
}

- (void)toogleMousePositionVisibility:(id) sender;
{
	self.displayMousePosition = !self.displayMousePosition;
	
	if( self.displayMousePosition && ![self selectedView].displayCrossLines)
		[self toogleAxisVisibility: sender];
	
	[mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
	[cprView setNeedsDisplay: YES];
	
	[self updateToolbarItems];
}

#pragma mark Blending

- (void) changeWLWW: (NSNotification*) note
{
	DCMPix	*otherPix = [note object];
	
	if( [[fusedViewer2D pixList] containsObject: otherPix])
	{
		float iwl, iww;
		
		iww = [[fusedViewer2D imageView] curWW];
		iwl = [[fusedViewer2D imageView] curWL];
		
		if( iww != [blendedMprView1 curWW] || iwl != [blendedMprView1 curWL])
		{
			if( clippingRangeMode == 0)
			{
				[blendedMprView1 setWLWW:128 :256];
				[blendedMprView2 setWLWW:128 :256];
				[blendedMprView3 setWLWW:128 :256];
				
				[mprView1.vrView setBlendingWLWW: iwl :iww];
				
				[mprView1 restoreCamera];
				mprView1.camera.forceUpdate = YES;
				[mprView1 updateViewMPR];
				
				[mprView2 restoreCamera];
				mprView2.camera.forceUpdate = YES;
				[mprView2 updateViewMPR];
				
				[mprView3 restoreCamera];
				mprView3.camera.forceUpdate = YES;
				[mprView3 updateViewMPR];
			}
			else
			{
				[blendedMprView1 setWLWW: iwl :iww];
				[blendedMprView2 setWLWW: iwl :iww];
				[blendedMprView3 setWLWW: iwl :iww];
			}
			
			[mprView1 updateImage];
			[mprView2 updateImage];
			[mprView3 updateImage];
		}
	}
}

- (void) setBlendingMode: (int) m
{
	blendingMode = m;
	
	[mprView1 setBlendingMode: m];
	[mprView2 setBlendingMode: m];
	[mprView3 setBlendingMode: m];
}

- (void) setBlendingPercentage: (float) f
{
	blendingPercentage = f;
	
	f -= 50.;
	f /= 50.;
	f *= 256.;
	
	[mprView1 setBlendingFactor: f];
	[mprView2 setBlendingFactor: f];
	[mprView3 setBlendingFactor: f];
}

#pragma mark 4D Data

- (BOOL) getMovieDataAvailable
{
	if( self.maxMovieIndex > 0) return YES;
	else return NO;
}

-(void) addMoviePixList:(NSMutableArray*) pix :(NSData*) vData
{
	pixList[ maxMovieIndex] = pix;
	volumeData[ maxMovieIndex] = vData;
	
	self.movieRate = 20;
	self.maxMovieIndex++;
	[moviePosSlider setNumberOfTickMarks: maxMovieIndex+1];
	
	[hiddenVRController addMoviePixList: pix :vData];	
    
	if( clippingRangeMode == 1 || clippingRangeMode == 3 || clippingRangeMode == 2)
		[mprView1.vrView prepareFullDepthCapture];
	else
		[mprView1.vrView restoreFullDepthCapture];
	
	[self willChangeValueForKey: @"movieDataAvailable"];
	[self didChangeValueForKey: @"movieDataAvailable"];
}

- (void) setCurMovieIndex: (int) m
{
	curMovieIndex = m;
	
	mprView1.camera.movieIndexIn4D = m;
	mprView2.camera.movieIndexIn4D = m;
	mprView3.camera.movieIndexIn4D = m;
	
	[fusedViewer2D setMovieIndex: curMovieIndex];
	
	[hiddenVRController setMovieFrame: m];
	
	if( clippingRangeMode == 1 || clippingRangeMode == 3 || clippingRangeMode == 2)
		[mprView1.vrView prepareFullDepthCapture];
	else
		[mprView1.vrView restoreFullDepthCapture];
	
	[self updateViewsAccordingToFrame: nil];
	
	[self setTool: toolsMatrix];
	
	[mprView1 mouseMoved: [[NSApplication sharedApplication] currentEvent]];
	[mprView2 mouseMoved: [[NSApplication sharedApplication] currentEvent]];
	[mprView3 mouseMoved: [[NSApplication sharedApplication] currentEvent]];
	
	[viewer2D setMovieIndex: m];
}

- (void) performMovieAnimation:(id) sender
{
    NSTimeInterval  thisTime = [NSDate timeIntervalSinceReferenceDate];
    short           val;
    
    if( thisTime - lastMovieTime > 1.0 / self.movieRate)
    {
        val = self.curMovieIndex;
        val ++;
        
		if( val < 0) val = 0;
		if( val > self.maxMovieIndex) val = 0;
		
		self.curMovieIndex = val;
        lastMovieTime = thisTime;
    }
}

- (NSString*) playStopButtonString
{
	if( movieTimer)
		return NSLocalizedString(@"Stop", nil);
	else
		return NSLocalizedString(@"Play", nil);
}

- (void) moviePlayStop:(id) sender
{
    if( movieTimer)
    {
        [movieTimer invalidate];
        [movieTimer release];
        movieTimer = nil;
    }
    else
    {
        movieTimer = [[NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(performMovieAnimation:) userInfo:nil repeats:YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSModalPanelRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:movieTimer forMode:NSEventTrackingRunLoopMode];
        
        lastMovieTime = [NSDate timeIntervalSinceReferenceDate];
    }
	
	[self willChangeValueForKey: @"playStopButtonString"];
	[self didChangeValueForKey: @"playStopButtonString"];
}

#pragma mark Axis Colors

- (void)setColorAxis1:(NSColor*)color;
{
	[colorAxis1 release];
	colorAxis1 = [color retain];
	[mprView1 setNeedsDisplay:YES];
	[mprView2 setNeedsDisplay:YES];
	[mprView3 setNeedsDisplay:YES];
    [cprView setOrangePlaneColor:colorAxis1];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 redComponent] forKey:@"MPR_AXIS_1_RED"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 greenComponent] forKey:@"MPR_AXIS_1_GREEN"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 blueComponent] forKey:@"MPR_AXIS_1_BLUE"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis1 alphaComponent] forKey:@"MPR_AXIS_1_ALPHA"];
}

- (void)setColorAxis2:(NSColor*)color;
{
	[colorAxis2 release];
	colorAxis2 = [color retain];
	[mprView1 setNeedsDisplay:YES];
	[mprView2 setNeedsDisplay:YES];
	[mprView3 setNeedsDisplay:YES];
    [cprView setPurplePlaneColor:colorAxis2];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 redComponent] forKey:@"MPR_AXIS_2_RED"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 greenComponent] forKey:@"MPR_AXIS_2_GREEN"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 blueComponent] forKey:@"MPR_AXIS_2_BLUE"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis2 alphaComponent] forKey:@"MPR_AXIS_2_ALPHA"];
}

- (void)setColorAxis3:(NSColor*)color;
{
	[colorAxis3 release];
	colorAxis3 = [color retain];
	[mprView1 setNeedsDisplay:YES];
	[mprView2 setNeedsDisplay:YES];
	[mprView3 setNeedsDisplay:YES];
    [cprView setBluePlaneColor:colorAxis3];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 redComponent] forKey:@"MPR_AXIS_3_RED"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 greenComponent] forKey:@"MPR_AXIS_3_GREEN"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 blueComponent] forKey:@"MPR_AXIS_3_BLUE"];
	[[NSUserDefaults standardUserDefaults] setFloat:[colorAxis3 alphaComponent] forKey:@"MPR_AXIS_3_ALPHA"];
}

#pragma mark CPR

- (void) setCurvedPathCreationMode: (BOOL) m
{
	curvedPathCreationMode = m;
	
	[curvedPathColor release];
	
	if( curvedPathCreationMode)
		curvedPathColor = [NSColor colorWithDeviceRed: 1.0
                                                 green: 0.1
                                                  blue: 0
                                                 alpha:1];
	else
		curvedPathColor = [NSColor colorWithDeviceRed:[[NSUserDefaults standardUserDefaults] floatForKey: @"CPRColorR"]
                                                 green:[[NSUserDefaults standardUserDefaults] floatForKey: @"CPRColorG"]
                                                  blue:[[NSUserDefaults standardUserDefaults] floatForKey: @"CPRColorB"]
                                                 alpha:1];
												 
	[curvedPathColor retain];
    
    [mprView1 setNeedsDisplay: YES];
	[mprView2 setNeedsDisplay: YES];
	[mprView3 setNeedsDisplay: YES];
}

- (void)setCurvedPath:(CPRCurvedPath *)newCurvedPath
{
//	N3Vector initialNormal;
//    N3Vector tangentAtStart;
//    N3Vector previousInitialNormal;
    CGFloat previousAngle;
	
	if (newCurvedPath != curvedPath)
    {
		previousAngle = curvedPath.angle;
		[curvedPath release];
		curvedPath = [newCurvedPath copy];

		if (N3VectorEqualToVector(curvedPath.baseDirection, N3VectorZero)) {
            curvedPath.baseDirection = baseNormal;
            curvedPath.angle = straightenedCPRAngle * (M_PI / 180.0);
            
//			tangentAtStart = [curvedPath.bezierPath tangentAtStart];
//			initialNormal = N3VectorNormalize(N3VectorCrossProduct(baseNormal, tangentAtStart));
//			initialNormal = N3VectorApplyTransform(initialNormal, N3AffineTransformMakeRotationAroundVector(straightenedCPRAngle * (M_PI / 180.0), tangentAtStart));
			
//			curvedPath.initialNormal = initialNormal; 
		} else {
			if (previousAngle != curvedPath.angle) {
                [self willChangeValueForKey:@"straightenedCPRAngle"];
				straightenedCPRAngle = curvedPath.angle * (180.0 / M_PI);
				[self didChangeValueForKey:@"straightenedCPRAngle"];
//                
//                
//				tangentAtStart = [curvedPath.bezierPath tangentAtStart];
//				initialNormal = N3VectorNormalize(N3VectorCrossProduct(baseNormal, tangentAtStart));
//				
//				[self willChangeValueForKey:@"straightenedCPRAngle"];
//				straightenedCPRAngle = N3VectorAngleBetweenVectorsAroundVector(initialNormal, self.curvedPath.initialNormal, tangentAtStart) * (180.0 / M_PI);
//				[self didChangeValueForKey:@"straightenedCPRAngle"];
			}
		}
        
        [self willChangeValueForKey: @"onSliderEnabled"];
        [self didChangeValueForKey: @"onSliderEnabled"];
        
//        if (N3VectorEqualToVector(curvedPath.initialNormal, N3VectorZero)) {
//			tangentAtStart = [curvedPath.bezierPath tangentAtStart];
//			initialNormal = N3VectorNormalize(N3VectorCrossProduct(baseNormal, tangentAtStart));
//			initialNormal = N3VectorApplyTransform(initialNormal, N3AffineTransformMakeRotationAroundVector(straightenedCPRAngle * (M_PI / 180.0), tangentAtStart));
//			
//			curvedPath.initialNormal = initialNormal; 
//		} else {
//			if (N3VectorEqualToVector(previousInitialNormal, self.curvedPath.initialNormal) == NO) {
//				tangentAtStart = [curvedPath.bezierPath tangentAtStart];
//				initialNormal = N3VectorNormalize(N3VectorCrossProduct(baseNormal, tangentAtStart));
//				
//				[self willChangeValueForKey:@"straightenedCPRAngle"];
//				straightenedCPRAngle = N3VectorAngleBetweenVectorsAroundVector(initialNormal, self.curvedPath.initialNormal, tangentAtStart) * (180.0 / M_PI);
//				[self didChangeValueForKey:@"straightenedCPRAngle"];
//			}
//		}
    }
}

- (void)setStraightenedCPRAngle:(double)newAngle
{
    if (straightenedCPRAngle != newAngle) {
		[self addToUndoQueue:@"curvedPath"];
        straightenedCPRAngle = newAngle;
        
        curvedPath.angle = straightenedCPRAngle * (M_PI / 180.0);
        mprView1.curvedPath = curvedPath;
        mprView2.curvedPath = curvedPath;
        mprView3.curvedPath = curvedPath;
        cprView.curvedPath = curvedPath;
        topTransverseView.curvedPath = curvedPath;
        middleTransverseView.curvedPath = curvedPath;
        bottomTransverseView.curvedPath = curvedPath;
    }
}

- (void)setCprType:(CPRType)newCprType
{
    if (newCprType != cprType) {
        cprType = newCprType;
        mprView1.CPRType = cprType;
        mprView2.CPRType = cprType;
        mprView3.CPRType = cprType;
        cprView.reformationType = cprType;
        topTransverseView.reformationDisplayStyle = cprType;
        middleTransverseView.reformationDisplayStyle = cprType;
        bottomTransverseView.reformationDisplayStyle = cprType;
    }
}

- (void)setViewsPosition:(ViewsPosition) newViewsPosition
{
    NSDisableScreenUpdates();
    
    viewsPosition = newViewsPosition;
    
    switch ( viewsPosition)
    {
        case NormalPosition:
            [verticalSplit setPosition:([verticalSplit minPossiblePositionOfDividerAtIndex:0]+[verticalSplit maxPossiblePositionOfDividerAtIndex:0])/2 ofDividerAtIndex:0];
            [horizontalSplit2 setPosition:([horizontalSplit2 minPossiblePositionOfDividerAtIndex:0]+[horizontalSplit2 maxPossiblePositionOfDividerAtIndex:0])/2 ofDividerAtIndex:0];
            cprView.rotation = 0;
        break;
        
        case VerticalPosition:
            [verticalSplit setPosition:([verticalSplit minPossiblePositionOfDividerAtIndex:0]+[verticalSplit maxPossiblePositionOfDividerAtIndex:0])/2 ofDividerAtIndex:0];
            [horizontalSplit2 setPosition: [horizontalSplit2 minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
            cprView.rotation = 90;
        break;
        
        case HorizontalPosition:
             [horizontalSplit2 setPosition:([horizontalSplit2 minPossiblePositionOfDividerAtIndex:0]+[horizontalSplit2 maxPossiblePositionOfDividerAtIndex:0])/2 ofDividerAtIndex:0];
             [verticalSplit setPosition:[verticalSplit minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
            cprView.rotation = 0;
        break;
    }
    
    [mprView1 restoreCamera];
	mprView1.camera.forceUpdate = YES;
	[mprView1 updateViewMPROnLoading:isInitializing];
	
	[mprView2 restoreCamera];
	mprView2.camera.forceUpdate = YES;
	[mprView2 updateViewMPROnLoading:isInitializing];
	
	[mprView3 restoreCamera];
	mprView3.camera.forceUpdate = YES;
	[mprView3 updateViewMPROnLoading:isInitializing];
    
    NSEnableScreenUpdates();
}

- (ViewsPosition)viewsPosition
{
    return viewsPosition;
}


//- (void)setStraightenedCPRAngle:(double)newAngle
//{
//    N3Vector initialNormal;
//    N3Vector tangentAtStart;
//    
//    if (straightenedCPRAngle != newAngle) {
//		[self addToUndoQueue:@"curvedPath"];
//        straightenedCPRAngle = newAngle;
//        
//        tangentAtStart = [curvedPath.bezierPath tangentAtStart];
//        initialNormal = N3VectorNormalize(N3VectorCrossProduct(baseNormal, tangentAtStart));
//        initialNormal = N3VectorApplyTransform(initialNormal, N3AffineTransformMakeRotationAroundVector(straightenedCPRAngle * (M_PI / 180.0), tangentAtStart));
//        
//        curvedPath.initialNormal = initialNormal;
//        mprView1.curvedPath = curvedPath;
//        mprView2.curvedPath = curvedPath;
//        mprView3.curvedPath = curvedPath;
//        cprView.curvedPath = curvedPath;
//        topTransverseView.curvedPath = curvedPath;
//        middleTransverseView.curvedPath = curvedPath;
//        bottomTransverseView.curvedPath = curvedPath;
//    }
//}

- (NSDictionary*)exportDCMImage16bitWithWidth:(NSUInteger)width height:(NSUInteger)height fullDepth:(BOOL)fullDepth withDicomExport:(DICOMExport *)dicomExport // dicomExport can be nil
{
	NSString *f = nil;
    float windowWidth;
    float windowLevel;
    CPRStraightenedGeneratorRequest *request;
    CPRVolumeData *curvedVolumeData;
    CPRUnsignedInt16ImageRep *imageRep;
	
	if( dicomExport == nil)
	{
		dicomExport = [[[DICOMExport alloc] init] autorelease];
		[dicomExport setSeriesNumber:5500];
	}
    
    request = [[[CPRStraightenedGeneratorRequest alloc] init] autorelease];
    request.pixelsWide = width;
    request.pixelsHigh = height;
    request.bezierPath = curvedPath.bezierPath;
    request.initialNormal = curvedPath.initialNormal;    
    
    curvedVolumeData = [CPRGenerator synchronousRequestVolume:request volumeData:cprView.volumeData];
    imageRep = [curvedVolumeData unsignedInt16ImageRepForSliceAtIndex:0];
	unsigned char *dataPtr = (unsigned char *)[imageRep unsignedInt16Data];
	
	
//	NSMutableArray *producedFiles = [NSMutableArray array];
	
	if(curvedVolumeData)
	{
        [dicomExport setModalityAsSource:YES];
		
		[dicomExport setSourceFile:[[pixList[0] lastObject] srcFile]];
		[dicomExport setSeriesDescription:self.exportSeriesName];
		
		[dicomExport setPixelData:dataPtr samplesPerPixel:1 bitsPerSample:16 width:width height:height];
		
		[dicomExport setOffset:[imageRep offset]];
		[dicomExport setSigned:NO];
		
//		if( [[[self viewer2D] modality] isEqualToString:@"PT"])
//		{
//			float slope = firstObject.appliedFactorPET2SUV * firstObject.slope;
//			[exportDCM setSlope: slope];
//		}
        [cprView getWLWW:&windowLevel :&windowWidth];
		[dicomExport setDefaultWWWL:windowWidth :windowLevel];
		
		
//		if( aCamera->GetParallelProjection())
//		{
        [dicomExport setPixelSpacing:[imageRep pixelSpacingX]:[imageRep pixelSpacingY]];
//			if( fullDepth)
//			{
//				double r = volumeMapper->GetRayCastImage()->GetImageSampleDistance();
//				
//				[exportDCM setPixelSpacing:[imageRep pixelSpacingX]:[imageRep pixelSpacingY]];
//			}
//			else
//				[exportDCM setPixelSpacing: [self getResolution] :[self getResolution]];
			
//			if( clipRangeActivated)
//			{
//				float cos[ 9];
//				
//				[self getCosMatrix: cos];
//				[exportDCM setOrientation: cos];
//				
//				float position[ 3];
//				
//				[self getOrigin: position];
//				[exportDCM setPosition: position];
//				[exportDCM setSliceThickness: [self getClippingRangeThicknessInMm]];
//			}
//		}
		
		f = [dicomExport writeDCMFile: nil];
		if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
//		free( dataPtr);
	}
    
	return [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    if (context == CPRController.class && object == shadingsPresetsController && [keyPath isEqualToString:@"selectedObjects"]) {
//        [self applyShading:self];
//        return;
//    }
    
    if (context == MPRPlaneObservationContext) {        
        if ([keyPath isEqualToString:@"plane"]) {
			if (object == mprView1) {
				if( [mprView1 frame].size.width > 10 && [mprView1 frame].size.height > 10)
                   cprView.orangePlane = [mprView1 plane];
                else
                    cprView.orangePlane = N3PlaneInvalid;
			} else if (object == mprView2) {
                if( [mprView2 frame].size.width > 10 && [mprView2 frame].size.height > 10)
                    cprView.purplePlane = [mprView2 plane];
                else
                    cprView.purplePlane = N3PlaneInvalid;
			} else if (object == mprView3) {
                 if( [mprView3 frame].size.width > 10 && [mprView3 frame].size.height > 10)
                     cprView.bluePlane = [mprView3 plane];
                 else
                     cprView.bluePlane = N3PlaneInvalid;
			}
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (float) costFunction:(NSUInteger)index
{
    float cost;
    assert(index >= 0);
    assert(index < [[curvedPath nodes] count]);
//    NSUInteger n = [[curvedPath nodes] count];
    if (index == 0 || index == [[curvedPath nodes] count] - 1)
    {
        cost = MAXFLOAT;
    }
    else
    {
        N3Vector next = [[[curvedPath nodes] objectAtIndex:index+1] N3VectorValue];
        N3Vector cur  = [[[curvedPath nodes] objectAtIndex:index  ] N3VectorValue];
        N3Vector prev = [[[curvedPath nodes] objectAtIndex:index-1] N3VectorValue];
        cost = (cur.x - next.x) * (cur.x - next.x) + (cur.y - next.y) * (cur.y - next.y) + (cur.z - next.z) * (cur.z - next.z)
             + (cur.x - prev.x) * (cur.x - prev.x) + (cur.y - prev.y) * (cur.y - prev.y) + (cur.z - prev.z) * (cur.z - prev.z);
    }
    
    return cost;
}

- (void)removeNode
{
    NSUInteger delCount = [nodeRemovalCost count];
    
    if (delCount > 3) // prevents the removal of too many points: CPR view is shown with at least 3 points.
    {
        NSUInteger index;
        float cost = MAXFLOAT;
        // Find the index of the node that lowers the delation cost
        for (NSUInteger i = 0; i < delCount; ++i)
        {
            if (cost > [[nodeRemovalCost objectAtIndex:i] floatValue])
            {
                index = i;
                cost = [[nodeRemovalCost objectAtIndex:i] floatValue];
            }
        }
        
        // Remove the node
        N3Vector node = [[[curvedPath nodes] objectAtIndex:index] N3VectorValue];
        [self.curvedPath removeNodeAtIndex:index];
        [nodeRemovalCost removeObjectAtIndex:index];
        [delHistory addObject:[NSNumber numberWithUnsignedInteger:index]];
        [delNodes addObject:[NSValue valueWithN3Vector:node]];
        
        // Update the cost list
        if (index > 0)
        {
            [nodeRemovalCost replaceObjectAtIndex:index-1 withObject:[NSNumber numberWithFloat:[self costFunction:index-1]]];
        }
        
        if (index < delCount - 1)
        {
            [nodeRemovalCost replaceObjectAtIndex:index withObject:[NSNumber numberWithFloat:[self costFunction:index]]];
        }
        
        // Update the curved path on all views
        mprView1.curvedPath = curvedPath;
        mprView2.curvedPath = curvedPath;
        mprView3.curvedPath = curvedPath;
        cprView.curvedPath = curvedPath;
        topTransverseView.curvedPath = curvedPath;
        middleTransverseView.curvedPath = curvedPath;
        bottomTransverseView.curvedPath = curvedPath;
    }
}

- (void)undoLastNodeRemoval
{
    if ([delHistory count] > 0)
    {
        NSUInteger index = [[delHistory lastObject] unsignedIntegerValue];
        [delHistory removeLastObject];
        
        [curvedPath insertPatientNode:[[delNodes lastObject] N3VectorValue] atIndex:index];
        [delNodes removeLastObject];
        // Update the cost list
        // the index in delHistory and delationCost do not include first and last two indexes of centerline (can't remoce first and last points)
        [nodeRemovalCost insertObject:[NSNumber numberWithFloat:[self costFunction:index]] atIndex:index];
        
        if (index > 0)
        {
            [nodeRemovalCost replaceObjectAtIndex:index-1 withObject:[NSNumber numberWithFloat:[self costFunction:index-1]]];
        }
        
        if (index < [nodeRemovalCost count] - 1)
        {
            [nodeRemovalCost replaceObjectAtIndex:index+1 withObject:[NSNumber numberWithFloat:[self costFunction:index+1]]];
        }
        
        // Update the curved path on all views
        mprView1.curvedPath = curvedPath;
        mprView2.curvedPath = curvedPath;
        mprView3.curvedPath = curvedPath;
        cprView.curvedPath = curvedPath;
        topTransverseView.curvedPath = curvedPath;
        middleTransverseView.curvedPath = curvedPath;
        bottomTransverseView.curvedPath = curvedPath;
    }
}

- (void) updateCurvedPathCost
{
    [nodeRemovalCost removeAllObjects];
    NSUInteger pathSize = [[curvedPath nodes] count];
    for (NSUInteger i = 0; i < pathSize ; ++i)
    {
        [nodeRemovalCost addObject:[NSNumber numberWithFloat:[self costFunction:i]]];
    }
}

- (void) resetSlider
{
    [nodeRemovalCost removeAllObjects];
    [delNodes removeAllObjects];
    [delHistory removeAllObjects];
    [pathSimplificationSlider setDoubleValue:[pathSimplificationSlider maxValue]];
}

#pragma mark CPRViewDelegate Methods

- (NSMutableArray *)_delegateCurveViewDebugging
{
	if (_delegateCurveViewDebugging == nil) {
		_delegateCurveViewDebugging = [[NSMutableArray alloc] init];
	}
	return _delegateCurveViewDebugging;
}

- (NSMutableArray *)_delegateDisplayInfoDebugging
{
	if (_delegateDisplayInfoDebugging == nil) {
		_delegateDisplayInfoDebugging = [[NSMutableArray alloc] init];
	}
	return _delegateDisplayInfoDebugging;
}

- (void)CPRViewWillEditCurvedPath:(id)CPRMPRDCMView
{
	assert([[self _delegateCurveViewDebugging] containsObject:[NSValue valueWithPointer:CPRMPRDCMView]] == NO);
	
	[[self _delegateCurveViewDebugging] addObject:[NSValue valueWithPointer:CPRMPRDCMView]];
    	
	[self addToUndoQueue:@"curvedPath"];
    if ([curvedPath.nodes count] == 0) {
        if (mprView1 != CPRMPRDCMView) {
            baseNormal = N3VectorMake(-1, 0, 0);
        }
        if (mprView2 != CPRMPRDCMView) {
            baseNormal = N3VectorMake(0, 0, -1);
        }
        if (mprView3 != CPRMPRDCMView) {
            baseNormal = N3VectorMake(0, 1, 0);
        }
    }
}

- (void)CPRViewDidUpdateCurvedPath:(id)CPRMPRDCMView
{
	assert([[self _delegateCurveViewDebugging] containsObject:[NSValue valueWithPointer:CPRMPRDCMView]] == YES);
	
    [centerline removeAllObjects];
    [pathSimplificationSlider setDoubleValue:[pathSimplificationSlider maxValue]];
    
	self.curvedPath = [CPRMPRDCMView curvedPath];
	
	// this is a bit of a hack, but the -[self setCurvedPath] will change the initial angle if it was N3VectortZero
	if (N3VectorEqualToVector([[CPRMPRDCMView curvedPath] initialNormal], N3VectorZero))
		[CPRMPRDCMView setCurvedPath:self.curvedPath];
	
    if (mprView1 != CPRMPRDCMView)
        mprView1.curvedPath = curvedPath;
    
    if (mprView2 != CPRMPRDCMView)
        mprView2.curvedPath = curvedPath;
    
    if (mprView3 != CPRMPRDCMView)
        mprView3.curvedPath = curvedPath;
    
    if (cprView != CPRMPRDCMView)
        cprView.curvedPath = curvedPath;
    
    if (topTransverseView != CPRMPRDCMView)
        topTransverseView.curvedPath = curvedPath;
    
    if (middleTransverseView != CPRMPRDCMView)
        middleTransverseView.curvedPath = curvedPath;
    
    if (bottomTransverseView != CPRMPRDCMView)
        bottomTransverseView.curvedPath = curvedPath;
}

- (void)CPRViewDidEditCurvedPath:(id)CPRMPRDCMView
{
	assert([[self _delegateCurveViewDebugging] containsObject:[NSValue valueWithPointer:CPRMPRDCMView]] == YES);
	[[self _delegateCurveViewDebugging] removeObject:[NSValue valueWithPointer:CPRMPRDCMView]];

	
	self.curvedPath = [CPRMPRDCMView curvedPath];
	
	// this is a bit of a hack, but the -[self setCurvedPath] will change the initial angle if it was N3VectortZero
	if (N3VectorEqualToVector([[CPRMPRDCMView curvedPath] initialNormal], N3VectorZero)) {
		[CPRMPRDCMView setCurvedPath:self.curvedPath];
	}

    if (mprView1 != CPRMPRDCMView) {
        mprView1.curvedPath = curvedPath;
    }
    if (mprView2 != CPRMPRDCMView) {
        mprView2.curvedPath = curvedPath;
    }
    if (mprView3 != CPRMPRDCMView) {
        mprView3.curvedPath = curvedPath;
    }
    if (cprView != CPRMPRDCMView) {
        cprView.curvedPath = curvedPath;
    }
    
    if (topTransverseView != CPRMPRDCMView) {
        topTransverseView.curvedPath = curvedPath;
    }
    if (middleTransverseView != CPRMPRDCMView) {
        middleTransverseView.curvedPath = curvedPath;
    }
    if (bottomTransverseView != CPRMPRDCMView) {
        bottomTransverseView.curvedPath = curvedPath;
    }
}

- (void)CPRViewWillEditDisplayInfo:(id)CPRMPRDCMView
{
	assert([[self _delegateDisplayInfoDebugging] containsObject:[NSValue valueWithPointer:CPRMPRDCMView]] == NO);
	[[self _delegateDisplayInfoDebugging] addObject:[NSValue valueWithPointer:CPRMPRDCMView]];

}

- (void)CPRViewDidEditDisplayInfo:(id)CPRMPRDCMView
{
	assert([[self _delegateDisplayInfoDebugging] containsObject:[NSValue valueWithPointer:CPRMPRDCMView]] == YES);
	[[self _delegateDisplayInfoDebugging] removeObject:[NSValue valueWithPointer:CPRMPRDCMView]];
	
	
    self.displayInfo = [CPRMPRDCMView displayInfo];
    
    if (mprView1 != CPRMPRDCMView) {
        mprView1.displayInfo = displayInfo;
    }
    if (mprView2 != CPRMPRDCMView) {
        mprView2.displayInfo = displayInfo;
    }
    if (mprView3 != CPRMPRDCMView) {
        mprView3.displayInfo = displayInfo;
    }
    if (topTransverseView != CPRMPRDCMView) {
        topTransverseView.displayInfo = displayInfo;
    }
    if (middleTransverseView != CPRMPRDCMView) {
        middleTransverseView.displayInfo = displayInfo;
    }
    if (bottomTransverseView != CPRMPRDCMView) {
        bottomTransverseView.displayInfo = displayInfo;
    }
    if (cprView != CPRMPRDCMView) {
        cprView.displayInfo = displayInfo;
    }
}

- (void)CPRViewDidChangeGeneratedHeight:(id)CPRMPRDCMView
{
    topTransverseView.sectionWidth = cprView.generatedHeight;
    middleTransverseView.sectionWidth = cprView.generatedHeight;
    bottomTransverseView.sectionWidth = cprView.generatedHeight;
}

- (void)CPRTransverseViewDidChangeRenderingScale:(CPRTransverseView*)CPRTransverseView
{
    topTransverseView.renderingScale = CPRTransverseView.renderingScale;
    middleTransverseView.renderingScale = CPRTransverseView.renderingScale;
    bottomTransverseView.renderingScale = CPRTransverseView.renderingScale;
}

- (void)CPRView:(CPRMPRDCMView*) CPRMPRDCMView setCrossCenter:(N3Vector)crossCenter
{
	N3Vector viewCrossCenter;
	
    viewCrossCenter = N3VectorApplyTransform(crossCenter, N3AffineTransformInvert(N3AffineTransformConcat([mprView1 viewToPixTransform], [mprView1 pixToDicomTransform])));
    [mprView1 setCrossCenter:NSPointFromN3Vector(viewCrossCenter)];
	
	viewCrossCenter = N3VectorApplyTransform(crossCenter, N3AffineTransformInvert(N3AffineTransformConcat([mprView2 viewToPixTransform], [mprView2 pixToDicomTransform])));
    [mprView2 setCrossCenter:NSPointFromN3Vector(viewCrossCenter)];
	
	viewCrossCenter = N3VectorApplyTransform(crossCenter, N3AffineTransformInvert(N3AffineTransformConcat([mprView3 viewToPixTransform], [mprView3 pixToDicomTransform])));
    [mprView3 setCrossCenter:NSPointFromN3Vector(viewCrossCenter)];
	
//	if( [curvedPath.nodes count] > 1 && curvedPathCreationMode)
//	{
//		// Orient the planes to the last point
//		CPRVector normal;
//		CPRVector tangent;
//		CPRVector cross;
//		
//		tangent = [curvedPath.bezierPath tangentAtRelativePosition: 1];
//		normal = [curvedPath.bezierPath normalAtRelativePosition: 1 initialNormal:curvedPath.initialNormal];
//		
//		cross = CPRVectorNormalize(CPRVectorCrossProduct(normal, tangent));
//		
//		NSLog( @"%2.2f %2.2f %2.2f", cross.x, cross.y, cross.z);
//		NSLog( @"%2.2f %2.2f %2.2f", tangent.x, tangent.y, tangent.z);
//		NSLog( @"%2.2f %2.2f %2.2f", normal.x, normal.y, normal.z);
//		
//		mprView1.camera.rollAngle = 0;
//		mprView1.angleMPR = 0;
//		mprView2.camera.rollAngle = 0;
//		mprView2.angleMPR = 0;
//		mprView3.camera.rollAngle = 0;
//		mprView3.angleMPR = 0;
//
//		CPRMPRDCMView.camera.viewUp = [Point3D pointWithX: cross.x y: cross.y z: cross.z];
//	}
	
	[self delayedFullLODRendering: CPRMPRDCMView];
}

- (IBAction)runFlyAssistant:(id)sender;
{
    if( [curvedPath.nodes count] > 1 && [curvedPath.nodes count] <= 5)
        [self assistedCurvedPath:nil];
    else
         NSRunAlertPanel(NSLocalizedString(@"Path Assistant error", nil), NSLocalizedString(@"Path Assistant requires at least 2 points, and no more than 5 points. Use the Curved Path tool to define at least two points.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    
    [self willChangeValueForKey: @"onSliderEnabled"];
    [self didChangeValueForKey: @"onSliderEnabled"];
}

- (BOOL) onSliderEnabled
{
    if ([centerline count] && [[curvedPath nodes] count] > 2)
        return YES;
    else
        return NO;
}

- (IBAction)onSliderMove:(id)sender
{
    if ([centerline count] && [[curvedPath nodes] count] > 2)
    {
        int targetValue = ([centerline count] - 3) * [pathSimplificationSlider floatValue] / 100 + 3;
        while ([[curvedPath nodes] count] != targetValue)
        {
            if (targetValue < [[curvedPath nodes] count])
            {
                [self removeNode];
            }
            else
            {
                [self undoLastNodeRemoval];
            }
        }
    }
    [self willChangeValueForKey: @"onSliderEnabled"];
    [self didChangeValueForKey: @"onSliderEnabled"];
}

- (void)CPRViewDidEditAssistedCurvedPath:(id)CPRMPRDCMView
{
	assert([[self _delegateCurveViewDebugging] containsObject:[NSValue valueWithPointer:CPRMPRDCMView]] == YES);
	[[self _delegateCurveViewDebugging] removeObject:[NSValue valueWithPointer:CPRMPRDCMView]];

	// this is a bit of a hack, but the -[self setCurvedPath] will change the initial angle if it was N3VectortZero
	if (N3VectorEqualToVector([[CPRMPRDCMView curvedPath] initialNormal], N3VectorZero)) {
		[CPRMPRDCMView setCurvedPath:self.curvedPath];
	}
    
    mprView1.curvedPath = curvedPath;
    mprView2.curvedPath = curvedPath;
    mprView3.curvedPath = curvedPath;
    cprView.curvedPath = curvedPath;
    topTransverseView.curvedPath = curvedPath;
    middleTransverseView.curvedPath = curvedPath;
    bottomTransverseView.curvedPath = curvedPath;
}

@end
