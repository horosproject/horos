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
#import "SRView+StereoVision.h"


#import "SRView.h"
#import "SRController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "DCMCursor.h"
#import "DICOMExport.h"
#import "Notifications.h"
#import "Wait.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#include "vtkImageFlip.h"
#import "QuicktimeExport.h"
#import "AppController.h"
#import "BrowserController.h"
#include "vtkRIBExporter.h"
#include "vtkIVExporter.h"
#include "vtkOBJExporter.h"
#include "vtkSTLWriter.h"
#include "vtkVRMLExporter.h"
#include "vtkInteractorStyleFlight.h"

#include "vtkAbstractPropPicker.h"
#include "vtkInteractorStyle.h"
#include "vtkWorldPointPicker.h"

#include "vtkSphereSource.h"
#include "vtkAssemblyPath.h"

#include "vtkVectorText.h"
#include "vtkFollower.h"

// ****************************
// Added SilvanWidmer 03-08-09
#import "vtkCocoaGLView.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkInteractorStyleTrackballCamera.h"
#include "vtkParallelRenderManager.h"
#include "vtkRendererCollection.h"
#import "SRController+StereoVision.h"
#import "Window3DController+StereoVision.h"
#import "SRFlyThruAdapter+StereoVision.h"

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees
// ****************************

static void  updateRight(vtkObject*, unsigned long eid, void* clientdata, void *calldata)
{
	
	SRView* mipv = (SRView*) clientdata;
	
	[mipv setNeedsDisplay:YES];
}


@implementation SRView (StereoVision)

-(id)initWithFrame:(NSRect)frame
{
		
    if ( self = [super initWithFrame:frame] )
    {
		NSTrackingArea *cursorTracking = [[[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil] autorelease];
		[self addTrackingArea: cursorTracking];
		
		//Added SilvanWidmer 10-08-09
		StereoVisionOn = NO;	
		
		splash = [[WaitRendering alloc] init: NSLocalizedString( @"Rendering...", nil)];
		//		[[splash window] makeKeyAndOrderFront:self];
		
		cursor = nil;
		isoExtractor[ 0] = isoExtractor[ 1] = nil;
		isoResample = nil;
		
		BisoExtractor[ 0] = BisoExtractor[ 1] = nil;
		BisoResample = nil;
		
		currentTool = t3DRotate;
		[self setCursorForView: currentTool];
		
		blendingController = nil;
		blendingFactor = 0.5;
		blendingReader = nil;
		//		cbStart = nil;
		
		exportDCM = nil;
		
		noWaitDialog = NO;
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: OsirixCloseViewerNotification
				 object: nil];
		
		point3DActorArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DPositionsArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DRadiusArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DColorsArray = [[NSMutableArray alloc] initWithCapacity:0];
		
		point3DDisplayPositionArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DTextArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DPositionsStringsArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DTextColorsArray = [[NSMutableArray alloc] initWithCapacity:0];
		point3DTextSizesArray = [[NSMutableArray alloc] initWithCapacity:0];
		
		display3DPoints = YES;
		[self load3DPointsDefaultProperties];
		
		[self connect2SpaceNavigator];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: nil];
    }
    
    return self;
}

- (void) changeActor:(long) actor :(float) resolution :(float) transparency :(float) r :(float) g :(float) b :(float) isocontour :(BOOL) useDecimate :(float) decimateVal :(BOOL) useSmooth :(long) smoothVal
{	
	//	[splash setCancel:YES];

	
	try
	{
		
		NSLog(@"ChangeActor IN");
		
		// RESAMPLE IMAGE ?
		
		if( resolution == 1.0)
		{	
			if( isoResample) isoResample->Delete();
			isoResample = nil;
		}
		else
		{
			if( isoResample)
			{
				if( isoResample->GetAxisMagnificationFactor( 0) != resolution)
				{
					isoResample->SetAxisMagnificationFactor(0, resolution);
					isoResample->SetAxisMagnificationFactor(1, resolution);
				}
			}
			else
			{
				isoResample = vtkImageResample::New();
				if( flip) isoResample->SetInput( flip->GetOutput());
				else isoResample->SetInput( reader->GetOutput());
				isoResample->SetAxisMagnificationFactor(0, resolution);
				isoResample->SetAxisMagnificationFactor(1, resolution);
			}
		}
		
		[self deleteActor: actor];
		
		if( isoResample)
		{
			isoExtractor[ actor] = vtkContourFilter::New();
			isoExtractor[ actor]->SetInput( isoResample->GetOutput());
			isoExtractor[ actor]->SetValue(0, isocontour);
		}
		else
		{
			isoExtractor[ actor] = vtkContourFilter::New();
			if( flip) isoExtractor[ actor]->SetInput( flip->GetOutput());
			else isoExtractor[ actor]->SetInput( reader->GetOutput());
			isoExtractor[ actor]->SetValue(0, isocontour);
		}
		
		vtkPolyData* previousOutput = isoExtractor[ actor]->GetOutput();
		
		if( useDecimate)
		{
			isoDeci[ actor] = vtkDecimatePro::New();
			isoDeci[ actor]->SetInput( previousOutput);
			isoDeci[ actor]->SetTargetReduction(decimateVal);
			isoDeci[ actor]->SetPreserveTopology( TRUE);
			
			//		isoDeci[ actor]->SetFeatureAngle(60);
			//		isoDeci[ actor]->SplittingOff();
			//		isoDeci[ actor]->AccumulateErrorOn();
			//		isoDeci[ actor]->SetMaximumError(0.3);
			
			isoDeci[ actor]->Update();
			
			previousOutput = isoDeci[ actor]->GetOutput();
			
			NSLog(@"Use Decimate : %f", decimateVal);
		}
		
		if( useSmooth)
		{
			isoSmoother[ actor] = vtkSmoothPolyDataFilter::New();
			isoSmoother[ actor]->SetInput( previousOutput);
			isoSmoother[ actor]->SetNumberOfIterations( smoothVal);
			//		isoSmoother[ actor]->SetRelaxationFactor(0.05);
			
			isoSmoother[ actor]->Update();
			
			previousOutput = isoSmoother[ actor]->GetOutput();
			
			NSLog(@"Use Smooth: %d", smoothVal);
		}
		
		
		isoNormals[ actor] = vtkPolyDataNormals::New();
		isoNormals[ actor]->SetInput( previousOutput);
		isoNormals[ actor]->SetFeatureAngle(120);
		
		isoMapper[ actor] = vtkPolyDataMapper::New();
		isoMapper[ actor]->SetInput( isoNormals[ actor]->GetOutput());
		isoMapper[ actor]->ScalarVisibilityOff();
		
		//	isoMapper[ actor]->GlobalImmediateModeRenderingOff();
		//	isoMapper[ actor]->SetResolveCoincidentTopologyToPolygonOffset();
		//	isoMapper[ actor]->SetResolveCoincidentTopologyToShiftZBuffer();
		//	isoMapper[ actor]->SetResolveCoincidentTopologyToOff();
		
		iso[ actor] = vtkActor::New();
		iso[ actor]->SetMapper( isoMapper[ actor]);
		iso[ actor]->GetProperty()->SetDiffuseColor( r, g, b);
		iso[ actor]->GetProperty()->SetSpecular( .3);
		iso[ actor]->GetProperty()->SetSpecularPower( 20);
		iso[ actor]->GetProperty()->SetOpacity( transparency);
		
		iso[ actor]->SetOrigin(		[firstObject originX], [firstObject originY], [firstObject originZ]);
		iso[ actor]->SetPosition(	[firstObject originX] * matrice->Element[0][0] + [firstObject originY] * matrice->Element[1][0] + [firstObject originZ]*matrice->Element[2][0],
								 [firstObject originX] * matrice->Element[0][1] + [firstObject originY] * matrice->Element[1][1] + [firstObject originZ]*matrice->Element[2][1],
								 [firstObject originX] * matrice->Element[0][2] + [firstObject originY] * matrice->Element[1][2] + [firstObject originZ]*matrice->Element[2][2]);
		iso[ actor]->SetUserMatrix( matrice);
		
		iso[ actor]->PickableOff();
		
		//Added SilvanWidmer 12-08-09
		if (actor == (long) 0)
		{
			first.actor = actor;
			first.resolution = resolution;
			first.transparency = transparency;
			first.r = r;
			first.g = g;
			first.b = b;
			first.isocontour = isocontour;
			first.useDecimate = useDecimate;
			first.decimateVal = decimateVal;
			first.useSmooth = useSmooth;
			first.smoothVal = smoothVal;
		}
		
		if (actor == (long) 1)
		{
			second.actor = actor;
			second.resolution = resolution;
			second.transparency = transparency;
			second.r = r;
			second.g = g;
			second.b = b;
			second.isocontour = isocontour;
			second.useDecimate = useDecimate;
			second.decimateVal = decimateVal;
			second.useSmooth = useSmooth;
			second.smoothVal = smoothVal;
		}
		

		//	std::cout << "address of the actor " << &iso[actor] << std::endl;
		aRenderer->AddActor( iso[ actor]);
		
		[self setNeedsDisplay:YES];
		
		NSLog(@"ChangeActor OUT");
		
	}
	catch (...)
	{
		if( NSRunAlertPanel( NSLocalizedString(@"32-bit",nil), NSLocalizedString( @"Cannot use the 3D engine.\r\rUpgrade to OsiriX 64-bit or OsiriX MD to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
			[[AppController sharedAppController] osirix64bit: self];
	}
}



-(void)dealloc
{
	long i;
	
    NSLog(@"Dealloc SRView");
	
	[splash close];
	[splash autorelease];
	[exportDCM release];
	
	if([firstObject isRGB]) free( dataFRGB);
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self setBlendingPixSource: nil];
	
	for( i = 0 ; i < 2; i++)
	{
		[self deleteActor:i];
		[self BdeleteActor:i];
	}
	NSLog(@"Should close the Stereo Window");
	// Added SilvanWidmer 12-08-09
	if (StereoVisionOn)
	{
		[self disableStereoModeLeftRight];
	}
	
	if( flip) flip->Delete();
	
	if( isoResample) isoResample->Delete();
	if( BisoResample) BisoResample->Delete();
	
	//	cbStart->Delete();
	matrice->Delete();
	
	outlineData->Delete();
	mapOutline->Delete();
	outlineRect->Delete();
	
	reader->Delete();
    aCamera->Delete();
	textX->Delete();
	if( orientationWidget)
		orientationWidget->Delete();
	for( i = 0; i < 4; i++) oText[ i]->Delete();
	//	aRenderer->Delete();
	
    [pixList release];
    pixList = nil;
	
	[point3DActorArray release];
	[point3DPositionsArray release];
	[point3DRadiusArray release];
	[point3DColorsArray release];
	
	[point3DDisplayPositionArray release];
	[point3DTextArray release];
	[point3DPositionsStringsArray release];
	[point3DTextColorsArray release];
	[point3DTextSizesArray release];
	
	[cursor release];
	
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];
	
	[destinationImage release];
	
	// 3D Connexion SpaceNavigator: Make sure the framework is installed
#if USE3DCONNEXION
	if(InstallConnexionHandlers != NULL)
	{
		// 3D Connexion SpaceNavigator: Unregister our client and clean up all handlers
		if(snConnexionClientID) UnregisterConnexionClient(snConnexionClientID);
		CleanupConnexionHandlers();
	}
#endif
	
    [super dealloc];
}

#pragma mark Initialisation of Left-Right-Side-View



- (void) setNeedsDisplay: (BOOL) flag
{
	[super setNeedsDisplay:flag];
	if(StereoVisionOn){
		[rightView setNeedsDisplay:flag];
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
		case 0: //Turning off Stereo
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

-(void) updateStereoLeftRight
{
	// **************************************************************
	// Comment: SilvanWidmer 27-08-09
	// Here lays a serios Bug. 
	// By changing the Surface Settings, actors could be removed. The function, rightRenderer->removeActor(iso[xy]); is executed. Theoretically the Actor is removed, 
	// also a IsItemPresent shows no actor. But the Actor is still present on the screen. 
	// **************************************************************
	
	if( aRenderer->GetActors()->IsItemPresent( iso[0]))
	{
		[rightView renderer]->AddActor(iso[0]);
		[self changeActor:(long) 0 :first.resolution : first.transparency : first.r : first.g :first.b :first.isocontour :first.useDecimate :first.decimateVal :first.useSmooth :first.smoothVal];
	}
	else{
		[rightView renderer] -> RemoveActor(iso[0]);


	}
	if( aRenderer->GetActors()->IsItemPresent( iso[1]))
	{
		[rightView renderer]->AddActor(iso[1]);
		[self changeActor:(long) 1 :second.resolution : second.transparency : second.r : second.g :second.b :second.isocontour :second.useDecimate :second.decimateVal :second.useSmooth :second.smoothVal];
	}
	else{
		[rightView renderer] -> RemoveActor(iso[1]);
	}
	[self setNeedsDisplay:YES];
}

-(void) initStereoLeftRight
{	

	[rightView renderer]->SetActiveCamera(aCamera);
	[self setDisplayStereo3DPoints: [rightView renderer]: YES];

	
	if( aRenderer->GetActors()->IsItemPresent( outlineRect))
	{
		[rightView renderer]->AddActor(outlineRect);
	}
	if( aRenderer->GetActors()->IsItemPresent( iso[0]))
	{
		[rightView renderer]->AddActor(iso[0]);
		[self changeActor:(long) 0 :first.resolution : first.transparency : first.r : first.g :first.b :first.isocontour :first.useDecimate :first.decimateVal :first.useSmooth :first.smoothVal];
	}
	if( aRenderer->GetActors()->IsItemPresent( iso[1]))
	{
		[rightView renderer]->AddActor(iso[1]);
		[self changeActor:(long) 1 :second.resolution : second.transparency : second.r : second.g :second.b :second.isocontour :second.useDecimate :second.decimateVal :second.useSmooth :second.smoothVal];
	}
	
	//taking the same colors as the left renderer
	double red, green, blue;
	aRenderer->GetBackground(red,green,blue);
	[rightView renderer]->SetBackground(red, green	, blue);
	
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
	
//	[self setNewGeometry: [[NSUserDefaults standardUserDefaults] doubleForKey:@"SCREENHEIGHT"]: 
//				[[NSUserDefaults standardUserDefaults] doubleForKey:@"DISTANCETOSCREEN"] : 
//				[[NSUserDefaults standardUserDefaults] doubleForKey:@"EYESEPARATION"]];

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
	contentRectLeftScreen.origin.y = contentRectLeftScreen.origin.y+20;
	
	contentRectRightScreen = [self frame];
	contentRectRightScreen.size.width = [[self window] frame].size.width/2.0;
	contentRectRightScreen.origin.x = contentRectLeftScreen.size.width;
	contentRectRightScreen.origin.y = contentRectRightScreen.origin.y+10;
	
	
	rightView = [[VTKStereoSRView alloc] initWithFrame:contentRectRightScreen:self];

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
		rightView = [[VTKStereoSRView alloc] initWithFrame:contentRectRightScreen:self];
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
		[RightFullScreenWindow setBackgroundColor:[NSColor blueColor]];
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
	
	//	StereoVisionOn = YES;
	return 1;
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
	
	[rightView getInteractor]->RemoveObserver(vtkCommand::AnyEvent);	rightView = nil;
	leftView = nil;
	[rightView release];
	[leftView release];
	
	StereoVisionOn = NO;
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

//Added SilvanWidmer 19-08-09
- (short) LeftRightMovieScreen
{
	NSLog(@"--- Dual Stereo Vision Movie ---");

	[rightView removeFromSuperview];
	
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
		rightView = [[VTKStereoSRView alloc] initWithFrame:contentRectRightScreen:self];
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


#pragma mark Movie-Export 
-(IBAction) endQuicktimeSettings:(id) sender
{
	
	[export3DWindow orderOut:sender]; 
	[NSApp endSheet:export3DWindow returnCode:[sender tag]];
	
	numberOfFrames = [framesSlider intValue];
	
	if( [[rotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [sender tag])
	{	
		
		[self setViewSizeToMatrix3DExport];
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :numberOfFrames];
		
		[mov createMovieQTKit: YES  :NO  :[[[[[self window] windowController] fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov release];
		//Added SilvanWidmer 19-08-09
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
	
	if( aRenderer->GetActors()->IsItemPresent( outlineRect))
	{
		aRenderer->RemoveActor( outlineRect);
		//Added SilvanWidmer
		if (StereoVisionOn)
			[rightView renderer]->RemoveActor(outlineRect);
		wasPresent = YES;
	}
	
	[self display];
	if (StereoVisionOn)
		[rightView display];
	
	theIm = [self nsimage:YES];
	
	if( wasPresent){
		aRenderer->AddActor(outlineRect);
		//Added SilvanWidmer
		if (StereoVisionOn)
			[rightView renderer]->AddActor(outlineRect);
	}
	
	return theIm;
}

-(IBAction) endQuicktimeVRSettings:(id) sender
{
	[export3DVRWindow orderOut:sender];
	
	[NSApp endSheet:export3DVRWindow returnCode:[sender tag]];
	
	numberOfFrames = [[VRFrames selectedCell] tag];
	
	rotationValue = 360;
	
	if( [sender tag])
	{
		NSString			*path, *newpath;
		QuicktimeExport		*mov;
		
		[self setViewSizeToMatrix3DExport];
		
		if( numberOfFrames == 10 || numberOfFrames == 20)
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames*numberOfFrames];
		else
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames];
		
		//[mov setCodec:kJPEGCodecType :codecHighQuality];
		
		path = [mov createMovieQTKit: NO  :NO :[[[[[self window] windowController] fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		if( path)
		{
			if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames*numberOfFrames];
			else
				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames];
			
			[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
			[[NSFileManager defaultManager] moveItemAtPath: newpath  toPath: path error:NULL];
			
			[[NSWorkspace sharedWorkspace] openFile:path withApplication: nil andDeactivate: YES];
			[NSThread sleepForTimeInterval: 1];
		}
		
		[mov release];
		// Added SilvanWidmer 19-08-09
		if(StereoVisionOn)
			[self disableStereoModeLeftRight];
		else [self restoreViewSizeAfterMatrix3DExport];
	}
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	// Added SilvanWidmer 19-08-09
	if (StereoVisionOn)
	{
		unsigned char	*buf = nil;
		unsigned char  *leftBuf = nil;
		unsigned char *rightBuf = nil;
		long			i;
		
		//	if( screenCapture)	// Pixels displayed in current window -> only RGB 8 bits data
		{
			NSRect size = [self bounds];
			
			*width = (long) size.size.width*2.0;
			long leftWidth = (long) size.size.width;
			long rightWidth = (long) size.size.width;
			
			*width/=4;
			*width*=4;
			*height = (long) size.size.height;//[LeftFullScreenWindow frame].size.height;//(long) size.size.height;
			*spp = 3;
			*bpp = 8;
			
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
				
				while(i-->0)
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
				
				//			[[NSOpenGLContext currentContext] flushBuffer];
				[NSOpenGLContext clearCurrentContext];
			}
		}
		//	else NSLog(@"Err getRawPixels...");
		free(rightBuf);
		free(leftBuf);
		return buf;
	}
	else{
		
		
		unsigned char	*buf = nil;
		long			i;
		
		//	if( screenCapture)	// Pixels displayed in current window -> only RGB 8 bits data
		{
			NSRect size = [self bounds];
			
			*width = (long) size.size.width;
			*width/=4;
			*width*=4;
			*height = (long) size.size.height;
			*spp = 3;
			*bpp = 8;
			
			buf = (unsigned char*) malloc( *width * *height * 4 * *bpp/8);
			if( buf)
			{
				[self getVTKRenderWindow]->MakeCurrent();
				//			[[NSOpenGLContext currentContext] flushBuffer];
				
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
				
				//			[[NSOpenGLContext currentContext] flushBuffer];
				[NSOpenGLContext clearCurrentContext];
			}
		}
		//	else NSLog(@"Err getRawPixels...");
		
		return buf;
	}
	
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

- (IBAction)changeColor:(id)sender
{	
	if( [backgroundColor isActive])
	{
		NSColor *color=  [[(NSColorPanel*)sender color]  colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
		aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
		
		//Added SilvanWidmer 20-08-09
		if(StereoVisionOn)
		{
			[rightView renderer]->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
		}
		[self setNeedsDisplay:YES];
	}
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
		{
			//[controller ];
			[self disableStereoModeLeftRight];
		}
		else
			[[[self window] windowController] offFullScreen];
	}
	
	else if ( c== 'c')
	{
		static BOOL cHidden = true;
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
	/*Test-purpose
	else if (c == 'i')
	{
		double someBounds [6];
		double camPos[3];
		double camFocPos[3];
		std::cout<< "View Angle " << aCamera->GetViewAngle() << " Distance " << aCamera->GetDistance() << std::endl;
		std::cout<< "pixel Spacing X/Y " << [firstObject pixelSpacingX] << " / "<< [firstObject pixelSpacingY] << " Slice Interval" << [firstObject sliceInterval] << std::endl; 
		std::cout <<"Window Size = " << [self frame].size.width << " / " << [self frame].size.height << std::endl;
		std::cout <<"Origin X = " <<[firstObject originX] << " Y= "<< [firstObject originY]<< " Z= "<<[firstObject originZ]<<std::endl;
		iso[0]->GetBounds(someBounds);
		for (int i = 0; i<6; i++)
		{
			std::cout << "bound " << i << " = " << someBounds[i];
		}
		std::cout << std::endl;
		aCamera->GetPosition(camPos);
		aCamera->GetFocalPoint(camFocPos);
		std::cout << "Camera Position ";
		for (int i = 0; i<3; i++)
		{
			std::cout <<" // "<<  i << " = " << camPos[i];
		}
		std::cout << std::endl;
		std::cout << "Focal Point ";
		for (int i = 0; i<3; i++)
		{
			std::cout <<" // " <<i << " = " << camFocPos[i];
		}
		std::cout << std::endl;
		std::cout <<"--------------------------------------" << std::endl;
	 
	 
	}
	*/	
	
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

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint		mouseLoc, mouseLocStart, mouseLocPre;
	ToolMode	tool;
	
	//	NSLog(@"--> First Surface: %i ; Second Surface: %i ", aRenderer->GetActors()->IsItemPresent( iso[0]),aRenderer->GetActors()->IsItemPresent( iso[1]));
	
	noWaitDialog = YES;
	tool = currentTool;
	
	if( snCloseEventTimer)
	{
		[snCloseEventTimer fire];
	}
	snStopped = YES;
	
	if ([theEvent type] == NSLeftMouseDown) {
		if (_mouseDownTimer) {
			[self deleteMouseDownTimer];
		}
		_mouseDownTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self   selector:@selector(startDrag:) userInfo:theEvent  repeats:NO] retain];
	}
	
	
	mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	_mouseLocStart = mouseLocStart;
	
	if( mouseLocStart.x < 10 && mouseLocStart.y < 10)
	{
		_resizeFrame = YES;
		return;
		
	}
	else
	{
		if( [theEvent clickCount] > 1 && (tool != t3Dpoint))
		{
			
			vtkWorldPointPicker *picker = vtkWorldPointPicker::New();
			
			picker->Pick(mouseLocStart.x, mouseLocStart.y, 0.0, aRenderer);
			
			double wXYZ[3];
			picker->GetPickPosition(wXYZ);
			picker->Delete();
			
			double dc[3], sc[3];
			dc[0] = wXYZ[0];
			dc[1] = wXYZ[1];
			dc[2] = wXYZ[2];
			
			[self convert3Dto2Dpoint:dc :sc];
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: sc[0]*[firstObject pixelSpacingX]], @"x", [NSNumber numberWithInt: sc[1]*[firstObject pixelSpacingY]], @"y", [NSNumber numberWithInt: sc[2]], @"z",
								  nil];
			
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixDisplay3dPointNotification object:pixList  userInfo: dict];
			
			return;
		}
		
		_resizeFrame = NO;
		tool = [self getTool:theEvent ];
		tool = [self getTool: theEvent];
		_tool = tool;
		[self setCursorForView: tool];
		
		if( tool == tRotate)
		{
			int shiftDown = 0;
			int controlDown = 1;
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			// Added SilvanWidmer 10-08-09
	
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			if(StereoVisionOn)
			{
				[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			}
			
			
		}
		else if( tool == t3DRotate)
		{
			int shiftDown = 0;//([theEvent modifierFlags] & NSShiftKeyMask);
			int controlDown = 0;//([theEvent modifierFlags] & NSControlKeyMask);
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			// Added SilvanWidmer 10-08-09
			
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			if(StereoVisionOn)
			{
				[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			}
			
			}
		else if( tool == tTranslate)
		{
			int shiftDown = 1;
			int controlDown = 0;
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			// Added SilvanWidmer 10-08-09
			
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			
			if(StereoVisionOn)
			{
				[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			}
		}
		else if( tool == tZoom)
		{
			if( projectionMode != 2)
			{
				int shiftDown = 0;
				int controlDown = 1;
				
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
			
				if(StereoVisionOn)
				{
					[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[rightView getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
				}
				
			}
			else
			{
				// vtkCamera
				mouseLocPre = mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				
				//if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*3);
				//if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
				
				[self setNeedsDisplay:YES];
			}
		}
		else if( tool == tCamera3D)
		{
			// vtkCamera
			mouseLocPre = mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			//			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*3);
			//			if( textureMapper) textureMapper->SetMaximumNumberOfPlanes( 512 / 10);
						
			//			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
			//			if( textureMapper) textureMapper->SetMaximumNumberOfPlanes( (int) (512 / LOD));
			
			[self setNeedsDisplay:YES];
		}
		else if( tool == t3Dpoint)
		{
			NSEvent *artificialPKeyDown = [NSEvent keyEventWithType:NSKeyDown
														   location:[theEvent locationInWindow]
													  modifierFlags:nil
														  timestamp:[theEvent timestamp]
													   windowNumber:[theEvent windowNumber]
															context:[theEvent context]
														 characters:@"p"
										charactersIgnoringModifiers:nil
														  isARepeat:NO
															keyCode:112
										   ];
			[self keyDown:artificialPKeyDown];
			
			if (![self isAny3DPointSelected])
			{
				// add a point on the surface under the mouse click
				[self throw3DPointOnSurface: mouseLocStart.x : mouseLocStart.y];
				[self setNeedsDisplay:YES];
				
			}
			else
			{
				[point3DRadiusSlider setFloatValue: [[point3DRadiusArray objectAtIndex:[self selected3DPointIndex]] floatValue]];
				[point3DColorWell setColor: [point3DColorsArray objectAtIndex:[self selected3DPointIndex]]];
				[point3DPositionTextField setStringValue:[point3DPositionsStringsArray objectAtIndex:[self selected3DPointIndex]]];
				
				//point3DDisplayPositionArray
				[point3DDisplayPositionButton setState:[[point3DDisplayPositionArray objectAtIndex:[self selected3DPointIndex]] intValue]];
				[point3DTextSizeSlider setFloatValue: [[point3DTextSizesArray objectAtIndex:[self selected3DPointIndex]] floatValue]];
				[point3DTextColorWell setColor: [point3DTextColorsArray objectAtIndex:[self selected3DPointIndex]]];
				
				if ([theEvent clickCount]==2)
				{
					NSPoint mouseLocationOnScreen = [[controller window] convertBaseToScreen:[theEvent locationInWindow]];
					//[point3DInfoPanel setAlphaValue:0.8];
					[point3DInfoPanel	setFrame:	NSMakeRect(	mouseLocationOnScreen.x - [point3DInfoPanel frame].size.width/2.0, 
															   mouseLocationOnScreen.y-[point3DInfoPanel frame].size.height-20.0,
															   [point3DInfoPanel frame].size.width,
															   [point3DInfoPanel frame].size.height)
									   display:YES animate: NO];
					[point3DInfoPanel orderFront:self];
				}
			}
		}
		else if (_tool == tWL) {
			NSLog(@"WL do nothing");
		}
		
		else [super mouseDown:theEvent];
		
		//	croppingBox->SetHandleSize( 0.005);
	}
	
	noWaitDialog = NO;
}

- (void)mouseUp:(NSEvent *)theEvent{
	[self deleteMouseDownTimer];
	
	switch (_tool) {
		case tRotate:
		case t3DRotate:
		case tTranslate:
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
			// Added SilvanWidmer 21-08-09
			if(StereoVisionOn)
				[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
			break;
		case tZoom:
			[self rightMouseUp:theEvent];
			break;
		default:
			break;
	}
	
	[super mouseUp:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent{
	NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];	
	if (_tool == tZoom && ( projectionMode != 2)) {
		int shiftDown = 0;
		int controlDown = 1;
		[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
		
		if(StereoVisionOn)
		{
			[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			[rightView getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);	
		}
	}
	
}

- (void)mouseDragged:(NSEvent *)theEvent{
	if (_dragInProgress == NO && ([theEvent deltaX] != 0 || [theEvent deltaY] != 0)) {
		[self deleteMouseDownTimer];
	}
	if (_dragInProgress == YES) return;
	
	if (_resizeFrame){
		NSRect	newFrame = [self frame];
		NSRect	beforeFrame = [self frame];;
		NSPoint mouseLoc = [theEvent locationInWindow];	//[self convertPoint: [theEvent locationInWindow] fromView:nil];
		
		if( [theEvent modifierFlags] & NSShiftKeyMask)
		{
			newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
			newFrame.size.height = newFrame.size.width;
			
			mouseLoc.x = ([[[self window] contentView] frame].size.width - newFrame.size.width) / 2;
			mouseLoc.y = ([[[self window] contentView] frame].size.height - newFrame.size.height) / 2;
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
		newFrame.size.height = [[[self window] contentView] frame].size.height - mouseLoc.y*2;
		
		[self setFrame: newFrame];
		
		aCamera->Zoom( beforeFrame.size.height / newFrame.size.height);
		
		[[self window] display];
		
		[self setNeedsDisplay:YES];
	}	
	else{
		int shiftDown;
		int controlDown;
		
		NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];		
		switch (_tool) {
			case tRotate:
				shiftDown  = 0;
				controlDown = 1;
				
	
					[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				
				if(StereoVisionOn)
				{
					[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				}
				
				break;
			case t3DRotate:
				shiftDown  = 0;
				controlDown = 0;		
				
					[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				
				if(StereoVisionOn)
				{
					[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				}
				
				break;
			case tTranslate:
				shiftDown  = 1;
				controlDown = 0;
				
				
					[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				
				if (StereoVisionOn)
				{
					[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				}
				break;
			case tZoom:				
				[self rightMouseDragged:theEvent];
				break;
			case tCamera3D:
				
				aCamera->Yaw( -(mouseLoc.x - _mouseLocStart.x) / 5.);
				aCamera->Pitch( (mouseLoc.y - _mouseLocStart.y) / 5.);
				aCamera->ComputeViewPlaneNormal();
				aCamera->OrthogonalizeViewUp();
				aRenderer->ResetCameraClippingRange();
				[self computeOrientationText];
				_mouseLocStart = mouseLoc;
				[self setNeedsDisplay:YES];
				
				
				
				break;
			default:
				break;
		}
	}	
}

- (void)rightMouseDragged:(NSEvent *)theEvent{
	int shiftDown, controlDown;
	float distance;
	NSPoint		mouseLoc,  mouseLocPre;
	mouseLocPre = mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	switch (_tool) {
		case tZoom:
			if( projectionMode != 2){
				shiftDown = 0;
				controlDown = 1;				
				
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self computeOrientationText];
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				
				if (StereoVisionOn)
				{
					[rightView getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[rightView getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				}
				
			}
			else{
				distance = aCamera->GetDistance();
				aCamera->Dolly( 1.0 + ( mouseLocPre.y - _mouseLocStart.y) / 1200.);
				aCamera->SetDistance( distance);
				aCamera->ComputeViewPlaneNormal();
				aCamera->OrthogonalizeViewUp();
				aRenderer->ResetCameraClippingRange();
				_mouseLocStart = mouseLoc;
				
				[self setNeedsDisplay:YES];
				
			}
			break;
	}
	
}

-(void) setCurrentTool:(ToolMode) i
{
	if(currentTool==t3Dpoint && currentTool!=i)
	{
		[self unselectAllActors];
		if ([point3DInfoPanel isVisible]) [point3DInfoPanel performClose:self];
		[self setNeedsDisplay:YES];
	}
	
    currentTool = i;
	
	
	if( currentTool != t3DRotate)
	{
		//if( croppingBox->GetEnabled()) croppingBox->Off();
	}
	
	[self setCursorForView: currentTool];
}


#pragma mark Generating 3D Points
//Added SilvanWidmer
- (void) setDisplayStereo3DPoints: (vtkRenderer*) theRenderer: (BOOL) on
{
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
	//Added SilvanWidmer 21-08-09
	if(StereoVisionOn)
		[rightView renderer]->RemoveActor(actor);
	// remove the highlight bounding box
	[self unselectAllActors];
	// remove from list
	[point3DActorArray removeObjectAtIndex:index];
	[point3DPositionsArray removeObjectAtIndex:index];
	[point3DRadiusArray removeObjectAtIndex:index];
	[point3DColorsArray removeObjectAtIndex:index];
	
	
	vtkFollower *text = (vtkFollower*)[[point3DTextArray objectAtIndex:index] pointerValue];
	aRenderer->RemoveActor(text);
	//Added SilvanWidmer 21-08-09
	if(StereoVisionOn)
		[rightView renderer]->RemoveActor(text);
	text->Delete();
	[point3DTextArray removeObjectAtIndex:index];
	[point3DPositionsStringsArray removeObjectAtIndex:index];
	[point3DTextColorsArray removeObjectAtIndex:index];
	[point3DTextSizesArray removeObjectAtIndex:index];
	// refresh display
	[self setNeedsDisplay:YES];
}

- (void) hideAnnotationFor3DPointAtIndex:(unsigned int) index
{
	vtkFollower* text = (vtkFollower*)[[point3DTextArray objectAtIndex:index] pointerValue];
	aRenderer->RemoveActor(text);
	
	[self setNeedsDisplay:YES];
	//Added SilvanWidmer 21-08-09
	if(StereoVisionOn)
	{	
		[rightView renderer]->RemoveActor(text);
		[rightView setNeedsDisplay:YES];
	}
}

- (void) add3DPointActor: (vtkActor*) actor
{
	void* actorPointer = actor;
	[point3DActorArray addObject:[NSValue valueWithPointer:actorPointer]];
	aRenderer->AddActor(actor);
	if(StereoVisionOn)
		[rightView renderer]->AddActor(actor);
	//actor->Delete();
}




@end
#endif
