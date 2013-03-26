//
// Program:   OsiriX
// 
// Created by Silvan Widmer on 8/25/09.
// 
// Copyright (c) LIB-EPFL
// All rights reserved.
// Distributed under GNU - GPL
// 
// See http://www.osirix-viewer.com/copyright.html for details.
// 
// This software is distributed WITHOUT ANY WARRANTY; without even
// the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.
// =========================================================================
#ifdef _STEREO_VISION_
dddd

#import "VRView+StereoVision.h"


#define USE3DCONNEXION 1

#import "VRView.h"
#import "DCMCursor.h"
#import "AppController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#include <OpenGL/CGLMacro.h>
#include "math.h"
#import "wait.h"
#import "QuicktimeExport.h"
#include "vtkImageResample.h"
#import "VRController.h"
#import "BrowserController.h"
#import "DICOMExport.h"
#import "DefaultsOsiriX.h" // for HotKeys
//#import "IChatTheatreDelegate.h"
#import "DicomImage.h"
#import "Notifications.h"

#include "vtkMath.h"
#include "vtkAbstractPropPicker.h"
#include "vtkInteractorStyle.h"
#include "vtkWorldPointPicker.h"
#include "vtkOpenGLVolumeTextureMapper3D.h"
#include "vtkPropAssembly.h"
#include "vtkFixedPointRayCastImage.h"

#include "vtkSphereSource.h"
#include "vtkAssemblyPath.h"

// ****************************
// Added SilvanWidmer 03-08-09
#import "vtkCocoaGLView.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderView.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkInteractorStyleTrackballCamera.h"
#include "vtkParallelRenderManager.h"
#include "vtkRendererCollection.h"
#import "VRController+StereoVision.h"
#import "Window3DController+StereoVision.h"
#import "VRFlyThruAdapter+StereoVision.h"

#import "ITKBrushROIFilter.h"
#import "OSIVoxel.h"

#include <CoreVideo/CVPixelBuffer.h>

//#import <InstantMessage/IMService.h>
//#import <InstantMessage/IMAVManager.h>


#if USE3DCONNEXION
#include <3DConnexionClient/ConnexionClientAPI.h>
extern "C" 
{
	extern OSErr InstallConnexionHandlers(ConnexionMessageHandlerProc messageHandler, ConnexionAddedHandlerProc addedHandler, ConnexionRemovedHandlerProc removedHandler) __attribute__((weak_import));
}
#endif

extern "C" 
{
	extern int spline(NSPoint *Pt, int tot, NSPoint **newPt, double scale);
}

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

//#define BONEVALUE 250
#define BONEOPACITY 1.1

extern int dontRenderVolumeRenderingOsiriX;	// See OsiriXFixedPointVolumeRayCastMapper.cxx

static NSRecursiveLock *drawLock = nil;
static unsigned short *linearOpacity = nil;
static VRView	*snVRView = nil;

static void  updateRight(vtkObject*, unsigned long eid, void* clientdata, void *calldata)
{
	
	VRView* mipv = (VRView*) clientdata;
	
	[mipv setNeedsDisplay:YES];
}


@implementation VRView (StereoVision)

//Same Function as before, but added flag for stereo-vision
-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame] )
    {
		NSTrackingArea *cursorTracking = [[[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil] autorelease];
		
		[self addTrackingArea: cursorTracking];
		
		rotate = NO;
		
		
		//Added SilvanWidmer 04-03-10
		StereoVisionOn = NO;
		
		splash = nil;	//[[WaitRendering alloc] init:NSLocalizedString(@"Rendering...", nil)];
		currentTool = t3DRotate;
		[self setCursorForView: currentTool];
		
		deleteRegion = [[NSLock alloc] init];
		
		valueFactor = 1.0;
		OFFSET16 = -[controller minimumValue];
		blendingValueFactor = 1.0;
		blendingOFFSET16 = -[controller blendingMinimumValue];
		
		renderingMode = 0;	// VR, MIP = 1
		blendingController = nil;
		blendingFactor = 128.;
		blendingVolume = nil;
		exportDCM = nil;
		currentOpacityArray = nil;
		textWLWW = nil;
		cursor = nil;
		ROIPoints = [[NSMutableArray array] retain];
		
		dataFRGB = nil;
		
		superSampling = [[NSUserDefaults standardUserDefaults] floatForKey: @"superSampling"];
		
		isViewportResizable = YES;
		
		data8 = nil;
		
		opacityTransferFunction = nil;
		volumeProperty = nil;
		compositeFunction = nil;
		red = nil;
		green = nil;
		blue = nil;
		pixList = nil;
		
		firstTime = YES;
		ROIUPDATE = NO;
		
		aCamera = nil;
		
		needToFlip = NO;
		blendingNeedToFlip = NO;
		
		// MAPPERS
		textureMapper = nil;
		volumeMapper = nil;
		//		shearWarpMapper = nil;
		
		blendingTextureMapper = nil;
		blendingVolumeMapper = nil;
		//		blendingShearWarpMapper = nil;
		
		noWaitDialog = NO;
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: OsirixCloseViewerNotification
				 object: nil];
		
		[nc addObserver: self
			   selector: @selector(OpacityChanged:)
				   name: OsirixOpacityChangedNotification
				 object: nil];
		
		[nc addObserver: self
			   selector: @selector(CLUTChanged:)
				   name: OsirixCLUTChangedNotification
				 object: nil];
		
		[nc addObserver: self
			   selector: @selector(ViewFrameDidChangeNotification:)
				   name: NSViewFrameDidChangeNotification
				 object: nil];
		
		point3DActorArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DPositionsArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DRadiusArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DColorsArray = [[NSMutableArray alloc] initWithCapacity:0];
		display3DPoints = YES;
		
		[self load3DPointsDefaultProperties];
		
		autoRotate = [[NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(autoRotate:) userInfo:nil repeats:YES] retain];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"autorotate3D"] && [[[self window] windowController] isKindOfClass:[VRController class]])
			startAutoRotate = [[NSTimer scheduledTimerWithTimeInterval:60*3 target:self selector:@selector(startAutoRotate:) userInfo:nil repeats:NO] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: [self window]];
		
		advancedCLUT = NO;
		
		if( [[NSProcessInfo processInfo] processorCount]ors() >= 4)
			lowResLODFactor = 1.5;
		else
			lowResLODFactor = 2.5;
		
		[[IMService notificationCenter] addObserver:self selector:@selector(_iChatStateChanged:) name:IMAVManagerStateChangedNotification object:nil];
	}
    
    return self;
}

#pragma mark Initialisation of Left-Right-Side-View



- (void) setNeedsDisplay: (BOOL) flag
{
	[super setNeedsDisplay:flag];
	if(StereoVisionOn){
		[rightView setNeedsDisplay:flag];
	}
}

- (void) displayIfNeeded
{
	[super displayIfNeeded];
	if(StereoVisionOn){
		[rightView displayIfNeeded];
	}
	
}

-(IBAction) SwitchStereoMode :(id) sender
{	
	for (int i = 0; i <6; i++)
	{
		[[[sender menu]itemWithTag: i] setState: false];
	}
	[sender setState:true];
	
	switch( [sender tag])
	{
		case 0: //Turni Stereo off 
		{
			if([self renderWindow]->GetStereoRender() == true)
			{
				if (StereoVisionOn)
					[self disableStereoModeLeftRight];	
				else{
					[self renderWindow]->StereoRenderOff();
					[self setNeedsDisplay:YES];
				}
			}
		}
			break;
			
		case 1: // Anaglyph
		{
			if (StereoVisionOn)
				[self disableStereoModeLeftRight];
			[self renderWindow]->StereoRenderOn();
			[self renderWindow]->SetStereoTypeToAnaglyph();
			if( orientationWidget)
				orientationWidget->Off();
			for(int i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
			[self setNeedsDisplay:YES];
		}
			break;
			
		case 2: //RedBlue
		{
			if (StereoVisionOn)
				[self disableStereoModeLeftRight];
			[self renderWindow]->StereoRenderOn();
			[self renderWindow]->SetStereoTypeToRedBlue();
			if( orientationWidget)
				orientationWidget->Off();
			for(int i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
			[self setNeedsDisplay:YES];
		}
			break;
			
		case 3: //Interlaced
		{
			if (StereoVisionOn)
				[self disableStereoModeLeftRight];
			[self renderWindow]->StereoRenderOn();
			[self renderWindow]->SetStereoTypeToInterlaced();
			if( orientationWidget)
				orientationWidget->Off();
			for(int i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
			[self setNeedsDisplay:YES];
		}
			break;
			
		case 4: //LeftRight Dual Screens
		{
			[self LeftRightDualScreen];
		}
			break;
			
		case 5: // LeftRight Single Screen
		{
			if (StereoVisionOn)
				[self disableStereoModeLeftRight];
			[self LeftRightSingleScreen];
		}
			break;
	}
	
}

-(void) LeftRightSingleScreen
{	
	NSLog(@"---Stereo Vision ON ---");
	StereoVisionOn = YES;
	//storing the previous window
	if (rootWindow == nil)
	{
		rootWindow = [self window];
		rootSize = [self frame];
		rootBorder.width = [[self window] frame].size.width - rootSize.origin.x- rootSize.size.width; 
		rootBorder.height = [[self window] frame].size.height - rootSize.origin.y- rootSize.size.height;
	}
	
	if( orientationWidget)
		orientationWidget->Off();
	for(int i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
	
	NSRect contentRectLeftScreen;
	NSRect contentRectRightScreen;
	
	contentRectLeftScreen = [self bounds];
	contentRectLeftScreen.size.width =  [[self window] frame].size.width/2.0;
	contentRectLeftScreen.origin.x = 0.0;
	contentRectLeftScreen.origin.y = contentRectLeftScreen.origin.y+10;
	
	contentRectRightScreen = [self frame];
	contentRectRightScreen.size.width = [[self window] frame].size.width/2.0;
	contentRectRightScreen.origin.x = contentRectLeftScreen.size.width;
	contentRectRightScreen.origin.y = contentRectRightScreen.origin.y+0;
	
	
	if (rightView==nil)
		rightView = [[VTKStereoVRView alloc] initWithFrame:contentRectRightScreen:self];
	else [rightView setFrame:contentRectRightScreen];

	[self initStereoLeftRight];
	
	[self setFrame: contentRectLeftScreen];
	[[self window] setMovableByWindowBackground:NO];
	
	[[[self window] contentView] addSubview:rightView];
	[[self superview] setAutoresizesSubviews:YES];
	
	[self setNeedsDisplay:YES];
}


- (short) LeftRightDualScreen
{
	NSLog(@"--- Dual Stereo Vision ON ---");
	StereoVisionOn = YES;
		
	currentTool = t3DRotate;
	[self setCursorForView: currentTool];
	//storing the previous window
	if (rootWindow == nil)
	{
		rootWindow = [self window];
		rootSize = [self frame];
		rootBorder.width = [[self window] frame].size.width - rootSize.origin.x- rootSize.size.width; 
		rootBorder.height = [[self window] frame].size.height - rootSize.origin.y- rootSize.size.height;
		
	}
	[[[self window] windowController] disableFullScreen];
	
	if( orientationWidget)
		orientationWidget->Off();
	for(int i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
	
	unsigned int windowStyle    = NSBorderlessWindowMask;		
	NSRect contentRectLeftScreen;
	NSRect contentRectRightScreen;
	
	NSArray *screenInformations = [NSScreen screens];
	
	if ([screenInformations count] < 2 )
	{	
		NSLog(@"No dual display available");
		[self LeftRightSingleScreen];
		return 0;
	}
	
	[NSCursor hide];
	// Getting ScreenInformations
	
	NSScreen *leftScreen = [screenInformations objectAtIndex:0];
	NSScreen *rightScreen = [screenInformations objectAtIndex:1];
	contentRectLeftScreen= [leftScreen frame];
	contentRectRightScreen =[rightScreen frame];
	
	contentRectRightScreen.origin = NSZeroPoint;
	contentRectLeftScreen.origin = NSZeroPoint;
	if (leftView == nil)
		leftView = [[vtkCocoaGLView alloc]initWithFrame:contentRectLeftScreen];
	else [leftView setFrame:contentRectLeftScreen];
	
	if (rightView==nil)
		rightView = [[VTKStereoVRView alloc] initWithFrame:contentRectRightScreen:self];
	else [rightView setFrame:contentRectRightScreen];
	
	LeftFullScreenWindow = [[NSWindow alloc] initWithContentRect:contentRectLeftScreen
													   styleMask:windowStyle
														 backing:NSBackingStoreBuffered
														   defer:NO
														  screen:leftScreen];
	
	RightFullScreenWindow = [[NSWindow alloc] initWithContentRect:contentRectRightScreen
														styleMask:windowStyle
														  backing:NSBackingStoreBuffered
															defer:NO
														   screen:rightScreen];
	
	if(LeftFullScreenWindow != nil)
	{
		[LeftFullScreenWindow setTitle: @"myLeftWindow"];			
		[LeftFullScreenWindow setReleasedWhenClosed: NO];
		[LeftFullScreenWindow setBackgroundColor:[NSColor blackColor]];
		[LeftFullScreenWindow setLevel: NSScreenSaverWindowLevel - 1];
		[LeftFullScreenWindow setContentView:leftView];
		
	}
	else return -1;
	
	if(RightFullScreenWindow != nil)
	{
		[RightFullScreenWindow setTitle: @"myRightWindow"];			
		[RightFullScreenWindow setReleasedWhenClosed: NO];
		[RightFullScreenWindow setBackgroundColor:[NSColor blackColor]];
		[RightFullScreenWindow setLevel: NSScreenSaverWindowLevel - 1];
		[RightFullScreenWindow setContentView:rightView];
		
	}	
	else return -1;
	

	[self initStereoLeftRight];
	
	LeftContentView = [[self window] contentView];
	[LeftFullScreenWindow setContentView: LeftContentView];
	[self setFrame:contentRectLeftScreen];
	
	[LeftFullScreenWindow makeFirstResponder: leftView];
	[LeftFullScreenWindow makeKeyAndOrderFront: leftView];	
	[RightFullScreenWindow makeFirstResponder: rightView];
	[RightFullScreenWindow makeKeyAndOrderFront: rightView];
	
	[self setNeedsDisplay:YES];
	
	return 1;
}

-(void) initStereoLeftRight
{	
	[rightView renderer]->SetActiveCamera(aCamera);
	[self setDisplayStereo3DPoints: [rightView renderer]: YES];
	
	
	if( textX)
		aRenderer->RemoveActor(textX);
	
	if( textWLWW)
		[rightView renderer]->AddActor(textWLWW);
	
	//rightRenderer->AddActor(outlineRect);
	[rightView renderer]->AddVolume( volume);
	[rightView renderer]->AddVolume(blendingVolume);
	
	
	if( aRenderer->GetActors()->IsItemPresent( outlineRect))
	{
		[rightView renderer]->AddActor(outlineRect);
	}
	
	//taking the same colors as the left renderer
	double t_red, t_green, t_blue;
	aRenderer->GetBackground(t_red,t_green,t_blue);
	[rightView renderer]->SetBackground(t_red, t_green	,t_blue);
		
	rightResponder = vtkCallbackCommand::New();
	rightResponder->SetCallback(updateRight);
	rightResponder->SetClientData( self);
	[rightView getInteractor]->AddObserver( vtkCommand::AnyEvent,  rightResponder);
	[self getInteractor]->AddObserver(vtkCommand::MouseWheelForwardEvent, rightResponder);
	[self getInteractor]->AddObserver(vtkCommand::MouseWheelBackwardEvent, rightResponder);
	
	[self renderWindow]->StereoRenderOn();
	[self renderWindow]->SetStereoTypeToLeft();
	
	[rightView renderWindow]->StereoRenderOn(); 
	[rightView renderWindow]->SetStereoTypeToRight();
	/*
	[self setNewGeometry: [[NSUserDefaults standardUserDefaults] doubleForKey:@"SCREENHEIGHT"]: 
	 [[NSUserDefaults standardUserDefaults] doubleForKey:@"DISTANCETOSCREEN"] : 
	 [[NSUserDefaults standardUserDefaults] doubleForKey:@"EYESEPARATION"]];
	*/
}


- (void) disableStereoModeLeftRight
{
	if (!StereoVisionOn)
		NSLog(@"Error! Stereo Mode was not activated");
	
	if (LeftFullScreenWindow != nil && RightFullScreenWindow != nil)
	{
		[NSCursor unhide];		
		[rootWindow setContentView: LeftContentView];
		
		[rootWindow makeFirstResponder:self];
		[rootWindow makeKeyAndOrderFront: self];
		
		[LeftFullScreenWindow setDelegate:nil];
		[LeftFullScreenWindow close];
		[LeftFullScreenWindow release];
		LeftFullScreenWindow = nil;
		
		[RightFullScreenWindow setDelegate:nil];
		[RightFullScreenWindow close];
		[RightFullScreenWindow release];
		RightFullScreenWindow = nil;
		
		[[[self window] windowController] enableFullScreen];
	}
	else{
		[rightView removeFromSuperview];
		[[self window] setMovableByWindowBackground:YES];
	}
	NSRect winRect ;
	winRect.origin= rootSize.origin;
	
	winRect.size.height =  [[self window] frame].size.height - winRect.origin.y - rootBorder.height;
	winRect.size.width = 	[[self window] frame].size.width - winRect.origin.x - rootBorder.width;
	
	[self setFrame: winRect];
	
	[self renderWindow]->StereoRenderOff();
	if( orientationWidget)
		orientationWidget->On();
	for(int i = 0; i < 4; i++) aRenderer->AddActor2D( oText[ i]);
	[self setNeedsDisplay:YES];
	
	if( textWLWW)
	{
		[self renderer]->AddActor(textWLWW);
	}
	[rightView getInteractor]->RemoveObserver(vtkCommand::AnyEvent);	

	[rightView release];
	[leftView release];
	rightView = nil;
	leftView = nil;
	
	StereoVisionOn = NO;
}

-(void) setNewViewAngle: (double) viewAngle
{
	aCamera->SetEyeAngle(viewAngle);
}

- (short) LeftRightMovieScreen
{
	NSLog(@"--- Dual Stereo Vision Movie ---");
	
	[[[self window] windowController] disableFullScreen];
	
	if( orientationWidget)
		orientationWidget->Off();
	for(int i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
	
	unsigned int windowStyle    = NSBorderlessWindowMask;
	NSRect contentRectLeftScreen;
	NSRect contentRectRightScreen;
	
	NSArray *screenInformations = [NSScreen screens];
	
	if([screenInformations count] > 1 )
	{
		NSScreen *leftScreen = [screenInformations objectAtIndex:0];
		NSScreen *rightScreen = [screenInformations objectAtIndex:1];
		contentRectLeftScreen= [leftScreen frame];
		contentRectRightScreen =[rightScreen frame];
		
		if( contentRectLeftScreen.size.width == contentRectRightScreen.size.width && contentRectLeftScreen.size.height == contentRectRightScreen.size.height)
		{
			contentRectRightScreen.origin = NSZeroPoint;
			contentRectLeftScreen.origin = NSZeroPoint;
			
			LeftFullScreenWindow = [[NSWindow alloc] initWithContentRect:contentRectLeftScreen
															   styleMask:windowStyle
																 backing:NSBackingStoreBuffered
																   defer:NO
																  screen:leftScreen];
			
			RightFullScreenWindow = [[NSWindow alloc] initWithContentRect:contentRectRightScreen
																styleMask:windowStyle
																  backing:NSBackingStoreBuffered
																	defer:NO
																   screen:rightScreen];
		}
	}
	
	else
	{	
		NSScreen* mainScreen = [NSScreen mainScreen]; 
		contentRectLeftScreen= [mainScreen frame];
		contentRectLeftScreen.origin = NSZeroPoint;
		
		contentRectRightScreen =[mainScreen frame];
		contentRectRightScreen.origin.x = contentRectLeftScreen.size.width;
		contentRectRightScreen.origin.y = 0.0;
		
		LeftFullScreenWindow = [[NSWindow alloc] initWithContentRect:contentRectLeftScreen
														   styleMask:windowStyle
															 backing:NSBackingStoreBuffered
															   defer:NO
															  screen:mainScreen];
		
		RightFullScreenWindow = [[NSWindow alloc] initWithContentRect:contentRectRightScreen
															styleMask:windowStyle
															  backing:NSBackingStoreBuffered
																defer:NO
															   screen:mainScreen];
		
	}
	
	if (leftView == nil)
		leftView = [[vtkCocoaGLView alloc]initWithFrame:contentRectLeftScreen];
	else [leftView setFrame:contentRectLeftScreen];
	
	if (rightView==nil)
		rightView = [[VTKStereoVRView alloc] initWithFrame:contentRectRightScreen:self];
	else [rightView setFrame:contentRectRightScreen];
	
	if(LeftFullScreenWindow != nil)
	{
		[LeftFullScreenWindow setTitle: @"myLeftWindow"];			
		[LeftFullScreenWindow setReleasedWhenClosed: NO];
		[LeftFullScreenWindow setBackgroundColor:[NSColor blackColor]];
		[LeftFullScreenWindow setLevel: NSNormalWindowLevel];
		[LeftFullScreenWindow setContentView:leftView];
		
	}
	else return -1;
	
	if(RightFullScreenWindow != nil)
	{
		[RightFullScreenWindow setTitle: @"myRightWindow"];			
		[RightFullScreenWindow setReleasedWhenClosed: NO];
		[RightFullScreenWindow setBackgroundColor:[NSColor blackColor]];
		[RightFullScreenWindow setLevel: NSNormalWindowLevel];
		[RightFullScreenWindow setContentView:rightView];
		
	}	
	else return -1;
	
	
	[self initStereoLeftRight];
	
	LeftContentView = [[self window] contentView];
	[LeftFullScreenWindow setContentView: LeftContentView];
	[self setFrame:contentRectLeftScreen];
	
	[LeftFullScreenWindow makeFirstResponder: leftView];
	[LeftFullScreenWindow makeKeyAndOrderFront: leftView];	
	[RightFullScreenWindow makeFirstResponder: rightView];
	[RightFullScreenWindow makeKeyAndOrderFront: rightView];
	
	[self setNeedsDisplay:YES];
	
	StereoVisionOn = YES;
	return 1;
	
}


-(IBAction) invertedSides :(id) sender
{
	[sender setState:![sender state]];
	double angle; 
	angle = aCamera->GetEyeAngle();
	if([sender state]==YES)
	{
		if (angle<0)
			aCamera->SetEyeAngle(angle);
		else
			aCamera->SetEyeAngle(-angle);
	}
	else{
		if (angle>0)
			aCamera->SetEyeAngle(angle);
		else
			aCamera->SetEyeAngle(-angle);
	}
	
	[self setNeedsDisplay:YES];
}

#pragma mark User Commands
- (void) keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
    unichar c = [[event characters] characterAtIndex:0];
	
	if( c == ' ')
	{
		if( aRenderer->GetActors()->IsItemPresent( outlineRect))
		{
			aRenderer->RemoveActor( outlineRect);
			if(StereoVisionOn)
				[rightView renderer]->RemoveActor(outlineRect);
		}
		else{
			aRenderer->AddActor( outlineRect);
			if(StereoVisionOn)
				[rightView renderer]->AddActor(outlineRect);
		}
		
		[self setNeedsDisplay: YES];
	}
	else if( c == 27)
	{
		if (StereoVisionOn && LeftFullScreenWindow!=nil && RightFullScreenWindow!=nil)
			[self disableStereoModeLeftRight];
		else
			[[[self window] windowController] offFullScreen];
	}
	
	else if (c == 's')
	{
		float distance = aCamera->GetDistance();
		//	float pp = aCamera->GetParallelScale();
		
		aCamera->SetFocalPoint (0, 0, 0);
		aCamera->SetPosition (1, 0, 0);
		aCamera->ComputeViewPlaneNormal();
		aCamera->SetViewUp(0, 0, 1);
		aCamera->OrthogonalizeViewUp();
		aRenderer->ResetCamera();
		
		// Apply the same zoom
		
		double vn[ 3], center[ 3];
		aCamera->GetFocalPoint(center);
		aCamera->GetViewPlaneNormal(vn);
		aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
		//	aCamera->SetParallelScale( pp);
		aRenderer->ResetCameraClippingRange();
		aCamera->SetEyeAngle(2.0);
		
		[self setNeedsDisplay:YES];
	}
	
	else if ( c== 'c')
	{
		static BOOL cHidden = true;
		std::cout << "the cursor is : " << cHidden <<std::endl;
		if (cHidden)
		{
			[NSCursor unhide];
			cHidden = false;
		}
		else 
		{
			[NSCursor hide];
			cHidden = true;
		}
	}
	
	else if (c == 'a')
	{
		double focalDist = aCamera->GetDistance();
		double newFocalDist = focalDist-40.0;
		double vn[ 3], focalPoint[ 3] , cameraPosition[3];
		
		aCamera->GetFocalPoint(focalPoint);
		aCamera->GetViewPlaneNormal(vn);
		aCamera->GetPosition(cameraPosition);
		
		std::cout<< "old Distance: "<< focalDist <<" New Distance: " << newFocalDist << std::endl;
		
		aCamera->SetFocalPoint(cameraPosition[0]-newFocalDist*vn[0], cameraPosition[1]-newFocalDist*vn[1], cameraPosition[2]-newFocalDist*vn[2]);
		aRenderer->ResetCameraClippingRange();
		std::cout<< "Eye Angle: " << aCamera->GetEyeAngle() << std::endl;
		double eyeAngle = aCamera->GetEyeAngle();
		
		eyeAngle = eyeAngle* D2R;
		double newViewAngle = 2.0 * atan((focalDist/newFocalDist)*(tan(eyeAngle/2.0)));
		newViewAngle = newViewAngle* R2D;
		aCamera->SetEyeAngle(newViewAngle);
		std::cout<< "Eye Angle: " << aCamera->GetEyeAngle() << std::endl;
		
		[self setNeedsDisplay:YES];
		
	}
	
	else if (c == 'd')
	{
		double focalDist = aCamera->GetDistance();
		double newFocalDist = focalDist+40.0;
		//	double newFocalDist = focalDist+ focalDist*0.1;
		double vn[ 3], focalPoint[ 3] , cameraPosition[3];
		
		aCamera->GetFocalPoint(focalPoint);
		aCamera->GetViewPlaneNormal(vn);
		aCamera->GetPosition(cameraPosition);
		
		std::cout<< "old Distance: "<< focalDist <<" New Distance: " << newFocalDist << std::endl;
		
		aCamera->SetFocalPoint(cameraPosition[0]-newFocalDist*vn[0], cameraPosition[1]-newFocalDist*vn[1], cameraPosition[2]-newFocalDist*vn[2]);
		aRenderer->ResetCameraClippingRange();
		std::cout<< "Eye Angle: " << aCamera->GetEyeAngle() << std::endl;
		double eyeAngle = aCamera->GetEyeAngle();
		
		eyeAngle = eyeAngle* D2R;
		double newViewAngle = 2.0 * atan((focalDist/newFocalDist)*(tan(eyeAngle/2.0)));
		newViewAngle = newViewAngle* R2D;
		aCamera->SetEyeAngle(newViewAngle);
		std::cout<< "Eye Angle: " << aCamera->GetEyeAngle() << std::endl;
		
		[self setNeedsDisplay:YES];
	}
	
	else if(c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter)
	{
		if([self isAny3DPointSelected])
		{
			[self removeSelected3DPoint];
		}
		else [self yaw:-90.0];
	}
	else [super keyDown:event];
}

#pragma mark Service Routines

-(void) adjustWindowContent: (NSSize) proposedFrameSize
{
	NSRect left;
	NSRect right;
	
	left = [self frame];
	left.size.width =  ceilf(proposedFrameSize.width/2.0);
	left.origin.x = 0.0;
	right = [self frame];
	right.size.width =  ceilf(proposedFrameSize.width/2.0);
	right.origin.x = floorf(proposedFrameSize.width/2.0);
	
	[self setFrame:left];
	[rightView setFrame:right];
	[self setNeedsDisplay:YES];
}


- (void)changeColorWith:(NSColor*) color
{
	
	if( color)
	{
		//change background color
		aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
		if(StereoVisionOn)
		{
			[rightView renderer]->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
		}
		
		if( [color redComponent]+[color greenComponent]+[ color blueComponent] < 1.5)
		{
			textWLWW->GetTextProperty()->SetColor(1,1,1);
			for( int i = 0 ; i < 4 ; i++) oText[ i]->GetTextProperty()->SetColor(1,1,1);
			if( textX)
				textX->GetTextProperty()->SetColor(1,1,1);
		}
		else
		{
			textWLWW->GetTextProperty()->SetColor(0,0,0);
			for( int i = 0 ; i < 4 ; i++) oText[ i]->GetTextProperty()->SetColor(0,0,0);
			if( textX)
				textX->GetTextProperty()->SetColor(0,0,0);
		}
		[backgroundColor setColor: [NSColor colorWithDeviceRed:[color redComponent] green:[color greenComponent] blue:[ color blueComponent] alpha:1.0]];
		
		[self setNeedsDisplay:YES];
	}
}

-(void) setNewGeometry: (double) screenHeight: (double) screenDistance: (double) eyeDistance
{
	double oldFocalPoint[3];
	double oldCameraPosition[3];
	aCamera->GetFocalPoint(oldFocalPoint);
	aCamera->GetPosition(oldCameraPosition);
	aRenderer->ResetCamera();
	
	double viewAngle = 2*atan(screenHeight/(2*screenDistance));
	viewAngle= viewAngle*57.2957795130823208767981548141;
	NSLog(@"The new ViewAngle is: %.2f", viewAngle);
	aCamera->SetViewAngle(viewAngle);
	
	double eyeAngle =  2*atan(eyeDistance/(2*screenDistance));
	eyeAngle = eyeAngle*57.2957795130823208767981548141;
	NSLog(@"The new EyeAngle is: %.2f", eyeAngle);
	aCamera->SetEyeAngle(eyeAngle);
	
	aCamera->SetFocalPoint(oldFocalPoint);
	aCamera->SetPosition(oldCameraPosition);
	[self setNeedsDisplay:	YES];
}


#pragma mark Mouse mouvements
- (void)mouseDragged:(NSEvent *)theEvent
{
	//snVRView = self;
	
	//NSLog(@"Mouse dragged!!");
	
	_hasChanged = YES;
	
	if (_dragInProgress == NO && ([theEvent deltaX] != 0 || [theEvent deltaY] != 0))
	{
		[self deleteMouseDownTimer];
	}
	
	if (_dragInProgress == YES) return;
	
	[drawLock lock];
	
	if (_resizeFrame)
	{
		NSRect	newFrame = [self frame];
		NSRect	beforeFrame;
		NSPoint mouseLoc = [theEvent locationInWindow];
		
		if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD * lowResLODFactor);
		if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD * lowResLODFactor);
		
		beforeFrame = [self frame];
		
		if( [theEvent modifierFlags] & NSShiftKeyMask)
		{
			newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
			newFrame.size.height = newFrame.size.width;
			
			mouseLoc.x = ([[[self window] contentView] frame].size.width - newFrame.size.width) / 2;
			mouseLoc.y = ([[[self window] contentView] frame].size.height - newFrame.size.height) / 2;
			mouseLoc.y -= 5;
		}
		
		if( [[[self window] contentView] frame].size.width - mouseLoc.x*2 < 100)
			mouseLoc.x = ([[[self window] contentView] frame].size.width - 100) / 2;
		
		if( [[[self window] contentView] frame].size.height - mouseLoc.y*2 < 100)
			mouseLoc.y = ([[[self window] contentView] frame].size.height - 100) / 2;
		
		if( mouseLoc.x < 10)
			mouseLoc.x = 10;
		
		if( mouseLoc.y < 10)
			mouseLoc.y = 10;
		
		newFrame.origin.x = mouseLoc.x;
		newFrame.origin.y = mouseLoc.y;
		
		newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
		newFrame.size.height = [[[self window] contentView] frame].size.height - 10 - mouseLoc.y*2;
		
		[self setFrame: newFrame];
		
		[self mouseMoved: theEvent];
		
		aCamera->Zoom( beforeFrame.size.height / newFrame.size.height);
		
		[[self window] display];
	}
	else 
	{
		NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		float WWAdapter, endlevel, startlevel;
		int shiftDown;
		int controlDown;
		switch (_tool)
		{
			case tMesure:
			{
				if( bestRenderingWasGenerated)
				{
					bestRenderingWasGenerated = NO;
					[self display];
				}
				dontRenderVolumeRenderingOsiriX = 1;
				
				double	*pp;
				long	i;
				
				vtkPoints *pts = Line2DData->GetPoints();
				
				if( pts->GetNumberOfPoints() > 0)
				{
					// Click point 3D to 2D
					
					aRenderer->SetDisplayPoint( mouseLoc.x, mouseLoc.y, 0);
					aRenderer->DisplayToWorld();
					pp = aRenderer->GetWorldPoint();
					
					// Create the 2D Actor
					
					aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
					aRenderer->WorldToDisplay();
					
					double *tempPoint = aRenderer->GetDisplayPoint();
					
					pts->SetPoint( pts->GetNumberOfPoints()-1, tempPoint[0], tempPoint[ 1], 0);
					
					vtkCellArray *rect = vtkCellArray::New();
					rect->InsertNextCell( pts->GetNumberOfPoints()+1);
					for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
					rect->InsertCellPoint( 0);
					
					Line2DData->SetVerts( rect);
					Line2DData->SetLines( rect);		rect->Delete();
					
					Line2DData->SetPoints( pts);
					
					[self computeLength];
					
					[self setNeedsDisplay: YES];
				}
			}
				break;
				
			case tWLBlended:	
				_startWW = blendingWw;
				_startWL = blendingWl;
				_startMin = blendingWl - blendingWw/2;
				_startMax = blendingWl + blendingWw/2;
				WWAdapter  = _startWW / 100.0;
				
				if( [[[controller blendingController] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller blendingController] modality] isEqualToString:@"NM"] == YES))
				{
					switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"])
					{
						case 0:
							blendingWl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
							blendingWw =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
							
							if( blendingWw < 0.1) blendingWw = 0.1;
							break;
							
						case 1:
							endlevel = _startMax + (-[theEvent deltaY]) * WWAdapter ;
							
							blendingWl =  (endlevel - _startMin) / 2 + [[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"];
							blendingWw = endlevel - _startMin;
							
							if( blendingWw < 0.1) blendingWw = 0.1;
							if( blendingWl - blendingWw/2 < 0) blendingWl = blendingWw/2;
							break;
							
						case 2:
							endlevel = _startMax - ([theEvent deltaY]) * WWAdapter ;
							startlevel = _startMin + ([theEvent deltaX]) * WWAdapter ;
							
							if( startlevel < 0) startlevel = 0;
							
							blendingWl = startlevel + (endlevel - startlevel) / 2;
							blendingWw = endlevel - startlevel;
							
							if( blendingWw < 0.1) blendingWw = 0.1;
							if( blendingWl - blendingWw/2 < 0) wl = blendingWw/2;
							break;
					}
				}
				else
				{
					blendingWl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
					blendingWw =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
				}
				
				if( blendingWw < 0.1) blendingWw = 0.1;
				
				[self setBlendingWLWW: blendingWl :blendingWw];
				
				[self setNeedsDisplay:YES];
				break;
				
			case tWL:
			{
				_startWW = ww;
				_startWL = wl;
				_startMin = wl - ww/2;
				_startMax = wl + ww/2;
				WWAdapter  = _startWW / 100.0;
				
				if( [[[controller viewer2D] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller viewer2D] modality] isEqualToString:@"NM"] == YES))
				{
					switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"])
					{
						case 0:
							wl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
							ww =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
							
							if( ww < 0.1) ww = 0.1;
							break;
							
						case 1:
							endlevel = _startMax + (-[theEvent deltaY]) * WWAdapter ;
							
							wl =  (endlevel - _startMin) / 2 + [[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"];
							ww = endlevel - _startMin;
							
							if( ww < 0.1) ww = 0.1;
							if( wl - ww/2 < 0) wl = ww/2;
							break;
							
						case 2:
							endlevel = _startMax - ([theEvent deltaY]) * WWAdapter ;
							startlevel = _startMin + ([theEvent deltaX]) * WWAdapter ;
							
							if( startlevel < 0) startlevel = 0;
							
							wl = startlevel + (endlevel - startlevel) / 2;
							ww = endlevel - startlevel;
							
							if( ww < 0.1) ww = 0.1;
							if( wl - ww/2 < 0) wl = ww/2;
							break;
					}
				}
				else
				{
					wl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
					ww =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
				}
				
				if( ww < 0.1) ww = 0.1;
				
				[self setOpacity: currentOpacityArray];
				
				if( isRGB)
					colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
				else if (advancedCLUT)
				{
					[clutOpacityView setWL:wl ww:ww];
					[clutOpacityView setCLUTtoVRView:YES];
					[drawLock unlock];
					return;
				}
				else
					colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
				
				if( [[[controller viewer2D] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller viewer2D] modality] isEqualToString:@"NM"] == YES))
				{
					if( ww < 50) sprintf(WLWWString, "From: %0.4f   To: %0.4f ", wl-ww/2, wl+ww/2);
					else sprintf(WLWWString, "From: %0.f   To: %0.f ", wl-ww/2, wl+ww/2);
				}
				else
				{
					if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f ", wl, ww);
					else sprintf(WLWWString, "WL: %0.f WW: %0.f ", wl, ww);
				}
				
//				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAutoCropScissors"] == NO)
//					[self autoCroppingBox];
				
				textWLWW->SetInput( WLWWString);
				[self setNeedsDisplay:YES];
			}
				break;
				
			case t3DCut:
				
				if( fabs(mouseLoc.x - _previousLoc.x) > 5. || fabs(mouseLoc.y - _previousLoc.y) > 5.)
				{
					double	*pp;
					
					aRenderer->SetDisplayPoint( mouseLoc.x, mouseLoc.y, 0);
					aRenderer->DisplayToWorld();
					pp = aRenderer->GetWorldPoint();
					
					// Create the 2D Actor
					
					aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
					aRenderer->WorldToDisplay();
					
					double *tempPoint = aRenderer->GetDisplayPoint();
					
					[ROIPoints addObject: [NSValue valueWithPoint: NSMakePoint( tempPoint[0], tempPoint[ 1])]];
					
					[self generateROI];
					
					[self setNeedsDisplay: YES];
					
					_previousLoc = mouseLoc;
				}
				break;
				
			case tRotate:
				shiftDown = 0;
				controlDown = 1;
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self computeOrientationText];
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				if(StereoVisionOn)
				{
					[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent,NULL);
				}
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
				break;
				
			case t3DRotate:
			case tCamera3D:
			{
				if( _tool == tCamera3D || clipRangeActivated == YES)
				{
					aCamera->Yaw( -([theEvent deltaX]) / 5.);
					aCamera->Pitch( -([theEvent deltaY]) / 5.);
					aCamera->ComputeViewPlaneNormal();
					aCamera->OrthogonalizeViewUp();
					
					if( clipRangeActivated)
						aCamera->SetClippingRange( 0.0, clippingRangeThickness);
					else
						aRenderer->ResetCameraClippingRange();
					
					[self computeOrientationText];
					[self setNeedsDisplay:YES];
					[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
				}
				else
				{
					shiftDown = 0;
					controlDown = 0;
					[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					if(StereoVisionOn)
					{
						[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
						[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent,NULL);
					}
					[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
				}
			}
				break;
			case tTranslate:
				shiftDown = 1;
				controlDown = 0;
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				if(StereoVisionOn)
				{
					[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent,NULL);
				}
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
				break;
			case tZoom:
				[self rightMouseDragged:theEvent];
				break;
				
			default:
				break;
		}
	}
	
	if( croppingBox)
		croppingBox->SetHandleSize( 0.005);
	
	[drawLock unlock];
	
	bestRenderingWasGenerated = NO;
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	_hasChanged = YES;
	[drawLock lock];
	NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	float distance ;
	
	if (([theEvent deltaX] != 0 || [theEvent deltaY] != 0))
	{
		[self deleteRightMouseDownTimer];
	}
	
	if( projectionMode != 2)
	{
		int shiftDown = 0;
		int controlDown = 1;
		[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		[self computeLength];
		[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
		if(StereoVisionOn)
		{
			[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent,NULL);
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
	}
	else
	{
		distance = aCamera->GetDistance();
		aCamera->Dolly( 1.0 + (-[theEvent deltaY]) / 1200.);
		aCamera->SetDistance( distance);
		aCamera->ComputeViewPlaneNormal();
		aCamera->OrthogonalizeViewUp();
		
		if( clipRangeActivated)
			aCamera->SetClippingRange( 0.0, clippingRangeThickness);
		else
			aRenderer->ResetCameraClippingRange();
		
		[self setNeedsDisplay:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
	}
	
	if( croppingBox)
		croppingBox->SetHandleSize( 0.005);
	
	[drawLock unlock];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	_hasChanged = YES;
	[self deleteMouseDownTimer];
	if (_contextualMenuActive)
	{
		[self rightMouseUp:theEvent];
		return;
	}
	
	[drawLock lock];
	
	if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
	if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
	
	if (_resizeFrame)
		[self setNeedsDisplay:YES];
	else
	{
		switch (_tool)
		{
			case t3DRotate:
			case tCamera3D:
			{
				if( _tool == tCamera3D || clipRangeActivated == YES)
				{
					if( keep3DRotateCentered == NO)
					{
						// Reset window center
						double xx = 0;
						double yy = 0;
						
						double pWC[ 2];
						aCamera->GetWindowCenter( pWC);
						pWC[ 0] *= ([self frame].size.width/2.);
						pWC[ 1] *= ([self frame].size.height/2.);
						
						if( pWC[ 0] != xx || pWC[ 1] != yy)
						{
							aCamera->SetWindowCenter( 0, 0);
							[self panX: ([self frame].size.width/2.) -(pWC[ 0] - xx)*10000. Y: ([self frame].size.height/2.) -(pWC[ 1] - yy) *10000.];
						}
					}
					[self setNeedsDisplay:YES];
				}
				else
				{
					if( volumeMapper)
						volumeMapper->SetMinimumImageSampleDistance( LOD);
					
					if( blendingVolumeMapper)
						blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
					
					[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
					if(StereoVisionOn)
					{
						[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent,NULL);
					}
					[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
				}
			}
				break;
				
			case tWL:
			case tWLBlended:
				[self setNeedsDisplay:YES];
				break;
			case tRotate:
			case tTranslate:
				if( volumeMapper)
					volumeMapper->SetMinimumImageSampleDistance( LOD);
				
				if( blendingVolumeMapper)
					blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
				
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				if(StereoVisionOn)
				{
					[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent,NULL);
				}
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
				break;
			case tZoom:
				[self zoomMouseUp:(NSEvent *)theEvent];
				break;
			case tMesure:
			case t3DCut:
				[self displayIfNeeded];
				dontRenderVolumeRenderingOsiriX = 0;
				break;
			case tBonesRemoval:		// <- DO NOTHING !
				break;
			default:
				[self setNeedsDisplay:YES];
				break;
		}
	}
	
	bestRenderingWasGenerated = NO;
	
	[drawLock unlock];
}

- (void)zoomMouseUp:(NSEvent *)theEvent
{
	_hasChanged = YES;
	if (_tool == tZoom)
	{
		if( volumeMapper)
			volumeMapper->SetMinimumImageSampleDistance( LOD);
		
		if( blendingVolumeMapper)
			blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		
		if( projectionMode != 2)
		{
			[self computeLength];
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
			if(StereoVisionOn)
			{
				[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent,NULL);
			}
		}
		else
		{
			[self setNeedsDisplay:YES];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
	}
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	_hasChanged = YES;
	[drawLock lock];
	
	[self deleteRightMouseDownTimer];
	if (_contextualMenuActive)
	{
		_contextualMenuActive = NO;
		[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
		if(StereoVisionOn)
		{
			[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent,NULL);
		}
		return;
	}
	
	if (_tool == tZoom)
		[self zoomMouseUp:(NSEvent *)theEvent];
	
	[drawLock unlock];
}

#pragma mark Movie-Export 
-(IBAction) endQuicktimeSettings:(id) sender
{
	[export3DWindow orderOut:sender];
	[NSApp endSheet:export3DWindow returnCode:[sender tag]];
	
	numberOfFrames = [framesSlider intValue];
	bestRenderingMode = [[quality selectedCell] tag];
	
	if( [[rotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [[orientation selectedCell] tag] == 1) rotationOrientation = 1;
	else rotationOrientation = 0;
	
	if( [sender tag])
	{
		if( [[[self window] windowController] movieFrames] > 1)
		{
			numberOfFrames /= [[[self window] windowController] movieFrames];
			numberOfFrames *= [[[self window] windowController] movieFrames];
		}
		
		[self setViewSizeToMatrix3DExport];
		
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :numberOfFrames];
		
		[mov createMovieQTKit:YES :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov release];
		
		//Added SilvanWidmer 10-03-10
		if(StereoVisionOn)
			[self disableStereoModeLeftRight];
		else 
			[self restoreViewSizeAfterMatrix3DExport];
	}
}

-(NSImage*) nsimageQuicktime
{
	NSImage *theIm;
	
	BOOL wasPresent = NO;
	//Added SilvanWidmer
	if(StereoVisionOn && RightFullScreenWindow==nil && LeftFullScreenWindow ==nil)
	{
		[self LeftRightMovieScreen];
	}
	
	[self renderImageWithBestQuality: bestRenderingMode waitDialog: NO];
	
	theIm = [self nsimage:YES];
	
	[self endRenderImageWithBestQuality];
	
	return theIm;
}

-(NSImage*) nsimageQuicktime:(BOOL) renderingModec
{
	bestRenderingMode = renderingModec;
	return [self nsimageQuicktime];
}

- (void) renderImageWithBestQuality: (BOOL) best waitDialog: (BOOL) wait display: (BOOL) display
{
	[splash setCancel:YES];
	
	// REMOVE CROPPING BOX
	
	if( croppingBox)
		if( croppingBox->GetEnabled()) croppingBox->Off();
	
	aRenderer->RemoveActor(outlineRect);
	//Added SilvanWidmer
	if (StereoVisionOn)
		[rightView renderer]->RemoveActor(outlineRect);
	
	if( textX)
	{
		aRenderer->RemoveActor(textX);
		//Added SilvanWidmer
		if (StereoVisionOn)
			[rightView renderer]->RemoveActor(textX);
	}
	if (StereoVisionOn)
	{
		if( textWLWW)
		{
			[self renderer]->RemoveActor(textWLWW);
			[rightView renderer]->RemoveActor(textWLWW);
		}
	}

	
	// RAY CASTING SETTINGS
	if( best)
	{
		// SWITCH TO RAY CASTING IF WE USE BOTH ENGINES
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] == 2)
		{
			double a[6];
			
			if( volume->GetMapper() != volumeMapper)
			{
				BOOL validBox = [VRView getCroppingBox: a :volume :croppingBox];
				volume->SetMapper( volumeMapper);
				if( validBox)
				{
					[self setCroppingBox: a];
					
					[VRView getCroppingBox: a :blendingVolume :croppingBox];
					[self setBlendingCroppingBox: a];
				}
			}
		}
		
		if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask || projectionMode == 2)
		{
			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( 1.0);
			if( volumeMapper) volumeMapper->SetSampleDistance( 1.0);
			
			if( blendingController)
			{
				if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( 1.0);
				if( blendingVolumeMapper) blendingVolumeMapper->SetSampleDistance( 1.0);
			}
			
			NSLog(@"resol = 1.0");
		}
		else
		{
			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
			if( volumeMapper) volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
			
			if( blendingController)
			{
				if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
				if( blendingVolumeMapper) blendingVolumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
			}
		}
	}
	
	if( display)
	{
		if( wait == NO) noWaitDialog = YES;
		
		if( dontRenderVolumeRenderingOsiriX)
		{
			[self render];
		}
		else
		{
			[self display];
			if (StereoVisionOn)
				[rightView display];
		}
		
		if( wait == NO) noWaitDialog = NO;
	}
	
	bestRenderingWasGenerated = YES;
}

-(IBAction) endQuicktimeVRSettings:(id) sender
{
	[export3DVRWindow orderOut:sender];
	
	[NSApp endSheet:export3DVRWindow returnCode:[sender tag]];
	
	numberOfFrames = [[VRFrames selectedCell] tag];
	bestRenderingMode = [[VRquality selectedCell] tag];
	
	rotationValue = 360;
	
	if( [sender tag])
	{
		NSString			*path, *newpath;
		QuicktimeExport		*mov;
		
		[self setViewSizeToMatrix3DExport];
		
		verticalAngleForVR = 0;
		rotateDirectionForVR = 1;
		
		if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames*numberOfFrames];
		else
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames];
		
		path = [mov createMovieQTKit: NO  :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		if( path)
		{
			if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames*numberOfFrames];
			else
				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames];
			
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			[[NSFileManager defaultManager] moveItemAtPath: newpath  toPath: path error:NULL];
			
			[[NSWorkspace sharedWorkspace] openFile:path withApplication: nil andDeactivate: YES];
			[NSThread sleepForTimeInterval: 1];
		}
		
		[mov release];
		
		// Added SilvanWidmer 10-03-10
		if(StereoVisionOn)
			[self disableStereoModeLeftRight];
		else [self restoreViewSizeAfterMatrix3DExport];
		
	}
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits offset:(int*) offset isSigned:(BOOL*) isSigned
{
	if (StereoVisionOn)
	{
		unsigned char	*buf = nil;
		unsigned char  *leftBuf = nil;
		unsigned char *rightBuf = nil;
		long			i;
		
	[drawLock lock];
	
	BOOL fullDepthCapture = NO;
	
	if( force8bits == NO)
		fullDepthCapture = YES;

	
	/*
	if( fullDepthCapture)
	{
		vImage_Buffer sf, d8;
		BOOL rgb;
		
		sf.data = [self imageInFullDepthWidth: width height:height isRGB: &rgb];
		
		if( rgb)
		{
			*spp = 3;
			*bpp = 8;
			
			buf = (unsigned char*) sf.data;
			
			i = *width * *height;
			unsigned char *t_argb = buf+1;
			unsigned char *t_rgb = buf;
			while( i-->0)
			{
				*((int*) t_rgb) = *((int*) t_argb);
				t_argb+=4;
				t_rgb+=3;
			}
		}
		else
		{
			*spp = 1;
			*bpp = 16;
			
			sf.height = *height;
			sf.width = *width;
			sf.rowBytes = *width * sizeof( float);
			
			d8.height =  *height;
			d8.width = *width;
			d8.rowBytes = *width * sizeof( short);
			
			float slope = 1;
			
			if( [[[controller viewer2D] modality] isEqualToString:@"PT"] == YES)
				slope = firstObject.appliedFactorPET2SUV * firstObject.slope;
			
			buf = (unsigned char*) malloc( *width * *height * *spp * *bpp / 8);
			if( buf)
			{
				d8.data = buf;
				
				if( [controller minimumValue] < -1024)
				{
					if( isSigned) *isSigned = YES;
					if( offset) *offset = 0;
					
					vImageConvert_FTo16S( &sf, &d8, 0, slope, 0);
				}
				else
				{
					if( isSigned) *isSigned = NO;
					
					if( [controller minimumValue] >= 0)
					{
						if( offset) *offset = 0;
						vImageConvert_FTo16U( &sf, &d8, 0, slope, 0);
					}
					else
					{
						if( offset) *offset = -1024;
						vImageConvert_FTo16U( &sf, &d8, -1024, slope, 0);
					}
				}
			}
			
			free( sf.data);
		}
	}
	else*/
	{
				
		NSRect size = [self bounds];
		
		*width = (long) size.size.width*2.0;
		long leftWidth = (long) size.size.width;
		long rightWidth = (long) size.size.width;
		
		*width/=4;
		*width*=4;
		*height = (long) size.size.height;
		*spp = 3;
		*bpp = 8;
		
//		[self getVTKRenderWindow]->MakeCurrent();
		
		buf = (unsigned char*) malloc( *width * *height * 4 * *bpp/8);
		leftBuf = (unsigned char*) malloc( leftWidth * *height * 4 * *bpp/8);
		rightBuf = (unsigned char*) malloc( rightWidth * *height * 4 * *bpp/8);
		
		if( buf)
		{
			[self getVTKRenderWindow]->MakeCurrent();
			CGLContextObj cgl_ctx = (CGLContextObj) [[NSOpenGLContext currentContext] CGLContextObj];
			glReadBuffer(GL_FRONT);
			glReadPixels(0, 0, leftWidth, *height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, leftBuf);
			[NSOpenGLContext clearCurrentContext];
			
			[rightView getVTKRenderWindow]->MakeCurrent();
			cgl_ctx = (CGLContextObj) [[NSOpenGLContext currentContext] CGLContextObj];
			glReadBuffer(GL_FRONT);
			glReadPixels(0, 0, rightWidth, *height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, rightBuf);
			
			i = *width * *height;
			
			//	unsigned char	*t_argb = buf;
			unsigned char	*t_rgb = buf;
			unsigned char *left_argb = leftBuf;
			unsigned char *right_argb = rightBuf;
			
			while( i-->0)
			{
				if((i % *width) >= leftWidth)
				{
					*((int*) t_rgb) = *((int*) left_argb);
					t_rgb +=3;
					left_argb+=4;
				}
				else {
					*((int*) t_rgb) = *((int*) right_argb);
					t_rgb +=3;
					right_argb+=4;
				}
			}
			
			long rowBytes = *width**spp**bpp/8;
			
			{
				unsigned char	*tempBuf = (unsigned char*) malloc( rowBytes);
				
				for( i = 0; i < *height/2; i++)
				{
					memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
					memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
					memcpy( buf + i*rowBytes, tempBuf, rowBytes);
				}
				
				free( tempBuf);
			}
			
			
		}
		[NSOpenGLContext clearCurrentContext];
	}
	
	[drawLock unlock];
		free(rightBuf);
		free(leftBuf);
	return buf;
	}
	//if no stereo!
	else{
		unsigned char	*buf = nil;
				
		[drawLock lock];
		
		BOOL fullDepthCapture = NO;
		
		if( force8bits == NO)
			fullDepthCapture = YES;
		
		if( fullDepthCapture)
		{
			vImage_Buffer sf, d8;
			BOOL rgb;
			
			sf.data = [self imageInFullDepthWidth: width height:height isRGB: &rgb];
			
			if( rgb)
			{
				*spp = 3;
				*bpp = 8;
				
				buf = (unsigned char*) sf.data;
				
				int i = *width * *height;
				unsigned char *t_argb = buf+1;
				unsigned char *t_rgb = buf;
				while( i-->0)
				{
					*((int*) t_rgb) = *((int*) t_argb);
					t_argb+=4;
					t_rgb+=3;
				}
			}
			else
			{
				*spp = 1;
				*bpp = 16;
				
				sf.height = *height;
				sf.width = *width;
				sf.rowBytes = *width * sizeof( float);
				
				d8.height =  *height;
				d8.width = *width;
				d8.rowBytes = *width * sizeof( short);
				
				float slope = 1;
				
				if( [[[controller viewer2D] modality] isEqualToString:@"PT"] == YES)
					slope = firstObject.appliedFactorPET2SUV * firstObject.slope;
				
				buf = (unsigned char*) malloc( *width * *height * *spp * *bpp / 8);
				if( buf)
				{
					d8.data = buf;
					
					if( [controller minimumValue] < -1024)
					{
						if( isSigned) *isSigned = YES;
						if( offset) *offset = 0;
						
						vImageConvert_FTo16S( &sf, &d8, 0, slope, 0);
					}
					else
					{
						if( isSigned) *isSigned = NO;
						
						if( [controller minimumValue] >= 0)
						{
							if( offset) *offset = 0;
							vImageConvert_FTo16U( &sf, &d8, 0, slope, 0);
						}
						else
						{
							if( offset) *offset = -1024;
							vImageConvert_FTo16U( &sf, &d8, -1024, slope, 0);
						}
					}
				}
				
				free( sf.data);
			}
		}
		else
		{
			int i;
			
			NSRect size = [self bounds];
			
			*width = (long) size.size.width;
			*width/=4;
			*width*=4;
			*height = (long) size.size.height;
			*spp = 3;
			*bpp = 8;
			
			[self getVTKRenderWindow]->MakeCurrent();
			
			buf = (unsigned char*) malloc( *width * *height * 4 * *bpp/8);
			if( buf)
			{
				CGLContextObj cgl_ctx = (CGLContextObj) [[NSOpenGLContext currentContext] CGLContextObj];
				
				glReadBuffer(GL_FRONT);
				
#if __BIG_ENDIAN__
				glReadPixels(0, 0, *width, *height, GL_RGB, GL_UNSIGNED_BYTE, buf);
#else
				glReadPixels(0, 0, *width, *height, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, buf);
				i = *width * *height;
				unsigned char	*t_argb = buf;
				unsigned char	*t_rgb = buf;
				while( i-->0)
				{
					*((int*) t_rgb) = *((int*) t_argb);
					t_argb+=4;
					t_rgb+=3;
				}
#endif
				
				long rowBytes = *width**spp**bpp/8;
				
				{
					unsigned char	*tempBuf = (unsigned char*) malloc( rowBytes);
					
					for( i = 0; i < *height/2; i++)
					{
						memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
						memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
						memcpy( buf + i*rowBytes, tempBuf, rowBytes);
					}
					
					free( tempBuf);
				}
				
				//Add the small OsiriX logo at the bottom right of the image
				NSImage				*logo = [NSImage imageNamed:@"SmallLogo.tif"];
				NSBitmapImageRep	*TIFFRep = [[NSBitmapImageRep alloc] initWithData: [logo TIFFRepresentation]];
				
				for( i = 0; i < [TIFFRep pixelsHigh]; i++)
				{
					unsigned char	*srcPtr = ([TIFFRep bitmapData] + i*[TIFFRep bytesPerRow]);
					unsigned char	*dstPtr = (buf + (*height - [TIFFRep pixelsHigh] + i)*rowBytes + ((*width-10)*3 - [TIFFRep bytesPerRow]));
					
					long x = [TIFFRep bytesPerRow]/3;
					while( x-->0)
					{
						if( srcPtr[ 0] != 0 || srcPtr[ 1] != 0 || srcPtr[ 2] != 0)
						{
							dstPtr[ 0] = srcPtr[ 0];
							dstPtr[ 1] = srcPtr[ 1];
							dstPtr[ 2] = srcPtr[ 2];
						}
						
						dstPtr += 3;
						srcPtr += 3;
					}
				}
				
				[TIFFRep release];
			}
			[NSOpenGLContext clearCurrentContext];
		}
		
		[drawLock unlock];
		
		return buf;
	}
}


- (float*) imageInFullDepthWidth: (long*) w height:(long*) h isRGB:(BOOL*) rgb blendingView:(BOOL) blendingView
{
	OsiriXFixedPointVolumeRayCastMapper *mapper = nil;
	DCMPix *firstObj = nil;
	
	if( blendingView)
	{
		firstObj = blendingFirstObject;
		mapper = blendingVolumeMapper;
	}
	else 
	{
		firstObj = firstObject;
		mapper = volumeMapper;
	}
	
	if( mapper)
	{
		vtkFixedPointRayCastImage *rayCastImage = mapper->GetRayCastImage();
		
		unsigned short *im = rayCastImage->GetImage();
		
		int fullSize[2];
		rayCastImage->GetImageMemorySize( fullSize);
		
		int size[2];
		rayCastImage->GetImageInUseSize( size);
		
		*w = size[0];
		*h = size[1];
		
		if( renderingMode == 1 || renderingMode == 3 || renderingMode == 2)		// MIP
		{
			unsigned short *destPtr, *destFixedPtr;
			
			destPtr = destFixedPtr = (unsigned short*) malloc( (*w+1) * (*h+1) * sizeof( unsigned short));
			if( destFixedPtr)
			{
				unsigned short *iptr;
				
				iptr = im + 3 + 4*(*h-1)*fullSize[0];
				vImage_Buffer src, dst;
				
				int j = *h, rowBytes = 4*fullSize[0];
				while( j-- > 0)
				{
					unsigned short *iptrTemp = iptr;
					int i = *w;
					while( i-- > 0)
					{
						*destPtr++ = *iptrTemp;
						iptrTemp += 4;
					}
					
					iptr -= rowBytes;
				}
				
				float mul;
				float add;
				
				if( blendingView)
				{
					mul = 1./blendingValueFactor;
					add = -blendingOFFSET16;
					
					if( blendingValueFactor != 1)
						mul = mul;
					else
						mul = 1;
				}
				else
				{
					mul = 1./valueFactor;
					add = -OFFSET16;
					
					if( valueFactor != 1)
						mul = mul;
					else
						mul = 1;
				}
				
				src.data = destFixedPtr;
				src.height = *h;
				src.width = *w;
				src.rowBytes = *w * 2;
				
				dst.data = malloc( (*w+1) * (*h+1) * sizeof( float));
				if( dst.data)
				{
					dst.height = *h;
					dst.width = *w;
					dst.rowBytes = *w * 4;
					
					vImageConvert_16UToF( &src, &dst, add, mul, 0);
				}
				
				*rgb = NO;
				
				free( destFixedPtr);
				
				return (float*) dst.data;
			}
		}
		else
		{
			unsigned char *destPtr, *destFixedPtr;
			
			destPtr = destFixedPtr = (unsigned char*) malloc( (*w+1) * (*h+1) * 4 * sizeof( unsigned char));
			if( destFixedPtr)
			{
				unsigned short *iptr = im + 3 + 4*(*h-1)*fullSize[0];
				vImage_Buffer src, dst;
				
				int j = *h, rowBytes = 4*fullSize[0];
				while( j-- > 0)
				{
					unsigned short *iptrTemp = iptr;
					int i = *w;
					while( i-- > 0)
					{
						*destPtr = 255;
						destPtr++;
						iptrTemp++;
						
						*destPtr++ = *iptrTemp++ >> 7;
						*destPtr++ = *iptrTemp++ >> 7;
						*destPtr++ = *iptrTemp++ >> 7;
					}
					
					iptr -= rowBytes;
				}
				
				*rgb = YES;
				
				return (float*) destFixedPtr;
			}
		}
	}
	
	return nil;
}

#pragma mark Generating 3D Points

//Added SilvanWidmer
- (void) setDisplayStereo3DPoints: (vtkRenderer*) theRenderer: (BOOL) on
{
	display3DPoints = on;
	
	//id object;
	vtkActor *actor;
	
	for  (id object in point3DActorArray)
	{
		actor = (vtkActor*)[object pointerValue];
		if(on)
		{
			theRenderer->AddActor(actor);
		}
		else
		{
			theRenderer->RemoveActor(actor);
		}	
	}
//	[self unselectAllActors];
	[self setNeedsDisplay:YES];
	
	/*
	display3DPoints = on;
	
	NSEnumerator *enumeratorPoint = [point3DActorArray objectEnumerator];
	NSEnumerator *enumeratorText = [point3DTextArray objectEnumerator];
	id objectPoint, objectText;
	vtkActor *actor;
	vtkFollower* text;
	
	while (objectPoint = [enumeratorPoint nextObject])
	{
		actor = (vtkActor*)[objectPoint pointerValue];
		objectText = [enumeratorText nextObject];
		text = (vtkFollower*)[objectText pointerValue];
		if(on)
		{
			theRenderer->AddActor(actor);
			theRenderer->AddActor(text);
		}
		else
		{
			theRenderer->RemoveActor(actor);
			theRenderer->RemoveActor(text);
		}	
	}
	[self setNeedsDisplay:YES];
	*/
}

- (void) toggleDisplay3DPoints
{
	[self setDisplay3DPoints:!display3DPoints];
	//Added SilvanWidmer 21-08-09
	if(StereoVisionOn)
		[self setDisplayStereo3DPoints:[rightView renderer] :!display3DPoints];
}

- (void) remove3DPointAtIndex: (unsigned int) index
{
	// point to remove
	vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
	// remove from Renderer
	aRenderer->RemoveActor(actor);
	// remove the highlight bounding box
	if(StereoVisionOn)
		[rightView renderer]->RemoveActor(actor);
	[self unselectAllActors];
	// kill the actor himself
	actor->Delete();
	// remove from list
	[point3DActorArray removeObjectAtIndex:index];
	[point3DPositionsArray removeObjectAtIndex:index];
	[point3DRadiusArray removeObjectAtIndex:index];
	[point3DColorsArray removeObjectAtIndex:index];
	// refresh display
	[self setNeedsDisplay:YES];
}

- (void) add3DPointActor: (vtkActor*) actor
{
	void* actorPointer = actor;
	[point3DActorArray addObject:[NSValue valueWithPointer:actorPointer]];
	aRenderer->AddActor(actor);
	if(StereoVisionOn)
		[rightView renderer]->AddActor(actor);
}

@end
#endif
