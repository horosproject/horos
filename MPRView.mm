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





#import "MPRView.h"

#import "DCMPix.h"
#include <Accelerate/Accelerate.h>
#import "DCMView.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>

#import "QuicktimeExport.h"

#include "vtkProp3DCollection.h"


extern short	Altivec;

void vminNoAltivecLong( unsigned long *a,  unsigned long *b,  unsigned long *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		if( *a < *b) { *r++ = *a++; b++; }
		else { *r++ = *b++; a++; }
	}
}

#if __ppc__
void vminLong(vector  unsigned int *a, vector  unsigned int *b, vector  unsigned int *r,  long size)
{
	long i = size / 4;
	
	while(i-- > 0)
	{
		*r++ = vec_min( *a++, *b++);
	}
}

void vmaxLong(vector  unsigned int *a, vector  unsigned int *b, vector  unsigned int *r, long size)
{
		long i = size / 4;
	
		while(i-- > 0)
		{
			*r++ = vec_max( *a++, *b++);
		}
}
#endif

void vmaxNoAltivecLong(unsigned long *a, unsigned long *b, unsigned long *r, long size)
{
	long i = size;
	
	while(i-- > 0)
	{
		if( *a > *b) { *r++ = *a++; b++; }
		else { *r++ = *b++; a++; }
	}
}

extern "C"
{
OSErr VRObject_MakeObjectMovie (FSSpec *theMovieSpec, FSSpec *theDestSpec, long maxFrames);
}

@implementation MPRView

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [cur intValue] != -1) [self Azimuth: [self rotation] / [max floatValue]];
	return [self nsimageQuicktime];
}

-(NSImage*) imageForFrameVR:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [cur intValue] == -1)
	{
		aCamera->GetPosition( camPosition);
		aCamera->GetViewUp( camFocal);
		
		return [self nsimageQuicktime];
	}
	
	if( [max intValue] > 36)
	{
		long line = (long) ([cur floatValue] / numberOfFrames);
		long deg = (long) ([cur floatValue] - numberOfFrames*numberOfFrames);
		long val =  (360*line) / (numberOfFrames);
		
		if( [cur intValue] % numberOfFrames == 0)
		{
			aCamera->SetPosition( camPosition);
			
			NSLog(@"%d", val);
			
			if( val >= 90 && val <= 270) 
			{
				double viewUpCopy[ 3];
				
				viewUpCopy[ 0] = -camFocal[ 0];
				viewUpCopy[ 1] = -camFocal[ 1];
				viewUpCopy[ 2] = -camFocal[ 2];
				
				aCamera->SetViewUp( viewUpCopy);
				
				if( val == 90) aCamera->Elevation( 90.1);
				else if( val == 270) aCamera->Elevation( 269.9);
				else aCamera->Elevation( val);
			}
			else
			{
				
				aCamera->SetViewUp( camFocal);
				
				aCamera->Elevation( -val);
			}
			
			double viewUp[ 3];
			
			aCamera->GetViewUp( viewUp);
			NSLog(@"%0.0f, %0.0f, %0.0f", viewUp[0], viewUp[1], viewUp[2]);
		}
		
		if( val >= 90 && val <= 270) aCamera->Azimuth( -360 / numberOfFrames);
		else aCamera->Azimuth( 360 / numberOfFrames);
	}
	else
	{
		aCamera->Azimuth( 360 / numberOfFrames);
	}
	
	return [self nsimageQuicktime];
}

-(IBAction) endQuicktimeSettings:(id) sender
{
	[export3DWindow orderOut:sender];
	
	[NSApp endSheet:export3DWindow returnCode:[sender tag]];
	
	numberOfFrames = [framesSlider intValue];
	
	if( [[rotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [sender tag])
	{
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :numberOfFrames];
		
		[mov generateMovie: YES :NO :[[fileList objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov dealloc];
	}
}

-(float) rotation {return rotationValue;}
-(float) numberOfFrames {return numberOfFrames;}

-(void) Azimuth:(float) a
{
	aCamera->Azimuth( a);
	aCamera->OrthogonalizeViewUp();
}

-(IBAction) endQuicktimeVRSettings:(id) sender
{
	[export3DVRWindow orderOut:sender];
	
	[NSApp endSheet:export3DVRWindow returnCode:[sender tag]];
	
	numberOfFrames = [[VRFrames selectedCell] tag];
	
	rotationValue = 360;
	
	if( [sender tag])
	{
		NSString	*path, *newpath;
		FSRef		fsref;
		FSSpec		spec, newspec;
		QuicktimeExport *mov;
		
		if( numberOfFrames == 10 || numberOfFrames == 20)
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames*numberOfFrames];
		else
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames];
		
		[mov setCodec:kJPEGCodecType :codecHighQuality];
		
		path = [mov generateMovie: NO  :NO :[[fileList objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		FSPathMakeRef((unsigned const char *)[path fileSystemRepresentation], &fsref, NULL);
		FSGetCatalogInfo( &fsref, kFSCatInfoNone,NULL, NULL, &spec, NULL);
		
		FSMakeFSSpec(spec.vRefNum, spec.parID, "\ptempMovie", &newspec);
		
		if( numberOfFrames == 10 || numberOfFrames == 20)
			VRObject_MakeObjectMovie (&spec,&newspec, numberOfFrames*numberOfFrames);
		else
			VRObject_MakeObjectMovie (&spec,&newspec, numberOfFrames);
		
		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		
		newpath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tempMovie"];
		
		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		
		[[NSFileManager defaultManager] movePath: newpath  toPath: path handler: nil];
					
		[mov dealloc];
		
		[[NSWorkspace sharedWorkspace] openFile:path];
	}
}

-(IBAction) exportQuicktime3DVR:(id) sender
{
	[NSApp beginSheet: export3DVRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

- (IBAction) exportQuicktime :(id) sender
{
	long i;
	
    [NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
	return YES;
}

-(void) axView:(id) sender
{
//	if( blendingController)
//	{
//		if( [bcor state] == NSOnState) aRenderer->RemoveActor(blendingCoronal);
//		if( [bsag state] == NSOnState) aRenderer->RemoveActor(blendingSaggital);
//		if( [bax state] == NSOffState) aRenderer->AddActor(blendingAxial);
//	}
//	else
//	{
//		if( [bcor state] == NSOnState) aRenderer->RemoveActor(coronal);
//		if( [bsag state] == NSOnState) aRenderer->RemoveActor(saggital);
//		if( [bax state] == NSOffState) aRenderer->AddActor(axial);
//	}
	
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();
	
//	aRenderer->SetViewport( 0, 0, 2, 2);	//vtkViewport - vtkRenderWindow

	[self setNeedsDisplay:YES];
}

-(void) saView:(id) sender
{
//	if( blendingController)
//	{
//		if( [bcor state] == NSOnState) aRenderer->RemoveActor(blendingCoronal);
//		if( [bsag state] == NSOffState) aRenderer->AddActor(blendingSaggital);
//		if( [bax state] == NSOnState) aRenderer->RemoveActor(blendingAxial);
//	}
//	else
//	{
//		if( [bcor state] == NSOnState) aRenderer->RemoveActor(coronal);
//		if( [bsag state] == NSOffState) aRenderer->AddActor(saggital);
//		if( [bax state] == NSOnState) aRenderer->RemoveActor(axial);
//	}
	
	//vtkCamera
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (-1, 0, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();
	
	[self setNeedsDisplay:YES];
}

-(void) coView:(id) sender
{
//	if( blendingController)
//	{
//		if( [bcor state] == NSOffState) aRenderer->AddActor(blendingCoronal);
//		if( [bsag state] == NSOnState) aRenderer->RemoveActor(blendingSaggital);
//		if( [bax state] == NSOnState) aRenderer->RemoveActor(blendingAxial);
//	}
//	else
//	{
//		if( [bcor state] == NSOffState) aRenderer->AddActor(coronal);
//		if( [bsag state] == NSOnState) aRenderer->RemoveActor(saggital);
//		if( [bax state] == NSOnState) aRenderer->RemoveActor(axial);
//	}
	
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, -1, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();
	
	[self setNeedsDisplay:YES];
}

-(void) scrollMPR3D:(NSNotification*) note
{
	NSDictionary	*dict = [note userInfo];
	
//	[self setWLWW: [[dict objectForKey:@"WL"] longValue] :[[dict objectForKey:@"WW"] longValue]];
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == blendingController) // our blended serie is closing itself....
	{
		[self setBlendingPixSource:0L];
	}
}

-(id)initWithFrame:(NSRect)frame
{
	long i;
	
    if ( self = [super initWithFrame:frame] )
    {
		currentTool = t3DRotate;

		thickSlab = 2;
		thickSlabMode = 0;

		rotateSpeed = 1;
		blendingFactor = 0.5;
		blendingSaggital = 0L;
		thickSlabActor = 0L;
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
				 
		[nc addObserver: self
			   selector: @selector(SetWLWWMPR3D:)
				   name: @"SetWLWWMPR3D"
				 object: nil];
				 
		for( i =0; i < 3; i++)
		{
			rotationpane[i] = 0;
			scalepane[i] = 0;
			originpane[i].x = originpane[i].y = 0;
		}
    }
    
    return self;
}

- (void)stopRotateTimer
{
	if( rotateTimer)
	{
        [rotateTimer invalidate];
        [rotateTimer release];
        rotateTimer = nil;
	}
}

-(void) dealloc
{
    NSLog(@"Dealloc MPRView3D");
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	if( [firstObject isRGB]) free( dataFRGB);
	
	[self setBlendingPixSource:0L];
	
	reader->Delete();
    outlineData->Delete();
    mapOutline->Delete();
    outlineRect->Delete();
	
    bwLut->Delete();
    saggitalColors->Delete();
    saggital->Delete();
    axialColors->Delete();
    axial->Delete();
    coronalColors->Delete();
    coronal->Delete();
	if(thickSlabActor) thickSlabActor->Delete();
	if( doRotate) rotate->Delete();
	
    aCamera->Delete();
	
    [pixList release];
	[fileList release];
	[perPixList release];
  
    [super dealloc];
}

-(void) setSelectedPlaneID:(long) i
{
	if( i != selectedPlaneID)
	{
		// Save position and rotation of previous pane
		
		rotationpane[selectedPlaneID] = [selectedPlane rotation];
		scalepane[selectedPlaneID] = [selectedPlane scaleValue];
		originpane[selectedPlaneID] = [selectedPlane origin];
		
		selectedPlaneID = i;
		
		[selectedPlane setRotation: rotationpane[selectedPlaneID]];
		if( scalepane[selectedPlaneID] != 0) [selectedPlane setScaleValue: scalepane[selectedPlaneID]];
		[selectedPlane setOrigin: originpane[selectedPlaneID]];
	}
}

-(long) selectedPlaneID { return selectedPlaneID;}

-(IBAction) setThickSlab:(id) sender
{
	thickSlab = [sender intValue];
	
	[textThickSlab setFloatValue: thickSlab];
	
	[self movePlanes:-1 :-1: -1];
}

-(IBAction) setThickSlabMode:(id) sender
{
	thickSlabMode = [sender tag];
	
	if( thickSlabMode)
	{
		[sliderThickSlab setEnabled: YES];
	}
	else
	{
		[sliderThickSlab setEnabled: NO];
	}
	
	[self movePlanes:-1 :-1: -1];
}

- (void) movePlanes:(float) x :(float) y :(float) z 
{
	int					displayedExtent[ 6], xx, yy, zz;
	long				thickSlabCount = thickSlab, i;
	long				width, height;
	unsigned char*		imResult = 0L;
	BOOL				firstPlane = YES;
	vtkImageActor       *curImageActor = 0L;
	
	if( thickSlabMode == 0) thickSlabCount = 1;

	if( x == -1)
	{
		if( blendingController) blendingSaggital->GetDisplayExtent( displayedExtent);
		else saggital->GetDisplayExtent( displayedExtent);
		x = displayedExtent[ 0];
	}
	
	if( y == -1)
	{
		if( blendingController) blendingCoronal->GetDisplayExtent( displayedExtent);
		else coronal->GetDisplayExtent( displayedExtent);
		y = displayedExtent[ 2];
	}
	
	if( z == -1)
	{
		if( blendingController) blendingAxial->GetDisplayExtent( displayedExtent);
		else axial->GetDisplayExtent( displayedExtent);
		z = displayedExtent[ 4];
	}
	
//	NSLog( @"Start MPR-3D");
	
	for( i = 0; i < thickSlabCount; i++)
	{
		//vtkImageActor
		
		rotate->GetOutput()->GetWholeExtent(extent);
		
//		NSLog( @"%d %d %d", extent[ 1], extent[ 3], extent[ 5]);
		
		xx = (int) x;
		yy = (int) y;
		zz = (int) z;
		
		switch( selectedPlaneID)
		{
			case 0: xx += i; break;
			case 1: yy += i; break;
			case 2: zz += i; break;
		}
		
		if( xx > [firstObject pwidth]-1) xx = [firstObject pwidth]-1;
		if( yy > [firstObject pheight]-1) yy = [firstObject pheight]-1;
		if( zz > [pixList count]-1) zz = [pixList count]-1;
		
		if( x != -1 || y != -1 || z != -1 || i != 0)
		{
			if( blendingController)
			{
				blendingSaggital->SetDisplayExtent((int) xx,(int) xx, 0, extent[ 3], 0,extent[ 5]);
				blendingCoronal->SetDisplayExtent(0,extent[ 1], (int) yy,(int) yy, 0,extent[ 5]);
				blendingAxial->SetDisplayExtent(0,extent[ 1], 0, extent[ 3] , (int) zz,(int) zz);
			}
			else
			{
				saggital->SetDisplayExtent((int) xx,(int) xx, 0,extent[ 3], 0,extent[ 5]);
				coronal->SetDisplayExtent(0,extent[ 1], (int) yy,(int) yy, 0,extent[ 5]);
				axial->SetDisplayExtent(0,extent[ 1], 0, extent[ 3] , (int) zz,(int) zz);
				
				//saggital->GetInput()->GetScalarPointer();
			}
		}
		
//		aRenderer->Render();
		
		vtkImageData *temp;
		
		switch( selectedPlaneID)
		{
			case 0:
				if( blendingController) curImageActor = blendingSaggital;
				else curImageActor = saggital;
			break;
			
			case 1:
				if( blendingController) curImageActor = blendingCoronal;
				else curImageActor = coronal;
			break;
			
			case 2:
				if( blendingController) curImageActor = blendingAxial;
				else curImageActor = axial;
			break;
		}

		temp = curImageActor->GetInput();
		
		temp->SetUpdateExtent( curImageActor->GetDisplayExtent());
		temp->PropagateUpdateExtent();
		temp->UpdateData();
		
//		rotate->Update();
//		axialColors->Update();
//		temp->SetUpdateExtent(0,extent[ 1], 0, extent[ 3] , (int) zz,(int) zz);
//		temp->SetExtent(0,extent[ 1], 0, extent[ 3] , (int) zz,(int) zz);
//		temp->UpdateData();
//		temp->Update();
		
		if( temp)
		{
			unsigned char*			im = (unsigned char*) temp->GetScalarPointer(); ////GetScalarPointerForExtent( extent);
			
			int				imExtent[ 6];
		//	temp->GetWholeExtent( imExtent);
		//	NSLog( @"%d %d %d", imExtent[ 1], imExtent[ 3], imExtent[ 5]);
			
			temp->GetUpdateExtent( imExtent);
		//	NSLog( @"%d %d %d", imExtent[ 1], imExtent[ 3], imExtent[ 5]);
			
			if( imExtent[ 1] != -1 && imExtent[ 1] != 0 && im != 0L)
			{
				float		*convert;
				double		space[ 3], origin[ 3];
				DCMPix*		mypix;
				
				temp->GetSpacing( space);
				temp->GetSpacing( origin);
				
				if( firstPlane)
				{
					switch( selectedPlaneID)
					{
						case 0:
							width = imExtent[ 3]+1;
							height = imExtent[ 5]+1;
						break;
						
						case 1:
							width = imExtent[ 1]+1;
							height = imExtent[ 5]+1;
						break;
						
						case 2:
							width = imExtent[ 1]+1;
							height = imExtent[ 3]+1;
						break;
					}
					
					if( thickSlabCount > 1)
					{
						imResult = (unsigned char*) malloc( width * height * sizeof(float));
						BlockMoveData( im, imResult, height*width*sizeof(float));
					}
				}
				
				if( thickSlabCount > 1)
				{
					if( firstPlane == NO)
					{
						long x;
						
						switch( thickSlabMode)
						{
							case 2:		// Maximum IP
							case 3:		// Minimum IP
								#if __ppc__
								if( Altivec)
								{
									if( thickSlabMode == 2) vmaxLong((vector  unsigned int*)imResult, (vector unsigned int*)im, (vector  unsigned int*)imResult, height * width);
									else vminLong((vector  unsigned int*)imResult, (vector  unsigned int*)im, (vector  unsigned int*)imResult, height * width);
								}
								else
								#endif
								{
									if( thickSlabMode == 2) vmaxNoAltivecLong(( long unsigned int*)imResult, ( long unsigned int*)im, ( long unsigned int*)imResult, height * width);
									else vminNoAltivecLong(( long unsigned int*)imResult, ( long unsigned int*)im, ( long unsigned int*)imResult, height * width);
								}
							break;
						}
					}
					
					firstPlane = NO;
					
					im = imResult;
				}
				
				if( i == thickSlabCount - 1)
				{
					switch( selectedPlaneID)
					{
						case 0:
							mypix = [[DCMPix alloc] initwithdata:(float*) im :8 :imExtent[ 3]+1 :imExtent[ 5]+1 :fabs(space[1]) :fabs(space[2]) :0 :0 :0];
							[mypix setPixelRatio: fabs(space[2]) / fabs(space[1])];
						break;
						
						case 1:
							mypix = [[DCMPix alloc] initwithdata:(float*) im :8 :imExtent[ 1]+1 :imExtent[ 5]+1 :fabs(space[1]) :fabs(space[2]) :0 :0 :0];
							[mypix setPixelRatio: fabs(space[2]) / fabs(space[1])];
						break;
						
						case 2:
							mypix = [[DCMPix alloc] initwithdata:(float*) im :8 :imExtent[ 1]+1 :imExtent[ 3]+1 :fabs(space[0]) :fabs(space[1]) :0 :0 :0];
							[mypix setPixelRatio: 1.0];
						break;
					}
					
					[perPixList removeAllObjects];
					[perPixList addObject: mypix];
					[mypix release];
					
					if( firstTime)
					{
						NSLog(@"firstTime");
						firstTime = NO;
						[selectedPlane setDCM:perPixList :fileList :0L :0 :'i' :YES];
						[selectedPlane setStringID:@"MPR3D"];
						
						[selectedPlane setCurrentTool: currentTool];
						
						[selectedPlane setRotation: rotationpane[selectedPlaneID]];
						if( scalepane[selectedPlaneID] != 0) [selectedPlane setScaleValue: scalepane[selectedPlaneID]];
						[selectedPlane setOrigin: originpane[selectedPlaneID]];
					}
					
					if( coronalPlane)
					{
						switch( selectedPlaneID)
						{
							case 0: if( sliceThickness*invThick > 0) [selectedPlane setYFlipped:YES];	break;
							case 1: if( sliceThickness*invThick < 0) [selectedPlane setYFlipped:YES];	break;
							case 2: if( sliceThickness*invThick < 0) [selectedPlane setYFlipped:NO];	break;
						}
					}
					else
					{
						switch( selectedPlaneID)
						{
							case 0: if( sliceThickness*invThick > 0) [selectedPlane setYFlipped:YES];	break;
							case 1: if( sliceThickness*invThick > 0) [selectedPlane setYFlipped:YES];	break;
							case 2: if( sliceThickness*invThick > 0) [selectedPlane setYFlipped:NO];	break;
						}
					}
					
					[selectedPlane setIndex:0];
				}
			}
		}
	}
	
	if( thickSlabCount > 1)
	{
		free( imResult);		
		
		if( blendingController)
		{
			blendingSaggital->SetDisplayExtent((int) x,(int) x, 0, extent[ 3], 0,extent[ 5]);
			blendingCoronal->SetDisplayExtent(0,extent[ 1], (int) y,(int) y, 0,extent[ 5]);
			blendingAxial->SetDisplayExtent(0,extent[ 1], 0, extent[ 3] , (int) z,(int) z);
		}
		else
		{
			saggital->SetDisplayExtent((int) x,(int) x, 0,extent[ 3], 0,extent[ 5]);
			coronal->SetDisplayExtent(0,extent[ 1], (int) y,(int) y, 0,extent[ 5]);
			axial->SetDisplayExtent(0,extent[ 1], 0, extent[ 3] , (int) z,(int) z);
		}
		
		aRenderer->AddActor( thickSlabActor);
		
		switch( selectedPlaneID)
		{
			case 0:		thickSlabActor->SetDisplayExtent((int) xx,(int) xx, 0, extent[ 3], 0,extent[ 5]);   break;
			case 1:		thickSlabActor->SetDisplayExtent(0,extent[ 1], (int) yy,(int) yy, 0,extent[ 5]);	break;
			case 2:		thickSlabActor->SetDisplayExtent(0,extent[ 1], 0, extent[ 3] , (int) zz,(int) zz);  break;
		}
	}
	else
	{
		aRenderer->RemoveActor( thickSlabActor);
	}
	
//	NSLog( @"End MPR-3D");
	
	[self display];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL		keepOn = YES;
    NSPoint		mouseLoc, mouseLocStart;
	short		tool;
	
	tool = currentTool;
	
		if (([theEvent modifierFlags] & NSControlKeyMask))  tool = tRotate;
        if (([theEvent modifierFlags] & NSShiftKeyMask))  tool = tZoom;
        if (([theEvent modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
		if (([theEvent modifierFlags] & NSAlternateKeyMask))  tool = tWL;
        if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask))  tool = tRotate;
	
    if( tool == tWL)
    {
        double fdata[2];
        mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
        
        bwLut->GetTableRange( fdata);
        
        do
		{
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
            mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
            switch ([theEvent type])
            {
            case NSLeftMouseDragged:
                double  newValues[2];
				float   WWAdapter;
				
				WWAdapter  = (fdata[1] - fdata[0]) / 200.0;
				
                newValues[0] = fdata[0]+(mouseLoc.y - mouseLocStart.y + (mouseLocStart.x - mouseLoc.x))*WWAdapter;
                newValues[1] = fdata[1]+(mouseLoc.y - mouseLocStart.y - (mouseLocStart.x - mouseLoc.x))*WWAdapter;
                
                if( newValues[0] > newValues[1]) newValues[0] = newValues[1];
                
                bwLut->SetTableRange (newValues[0], newValues[1]);
				
				[self movePlanes:-1 :-1: -1];
				
                //[self setNeedsDisplay:YES];
            break;
			
            case NSLeftMouseUp:
                
                keepOn = NO;
                return;
                
            case NSPeriodic:
                
                break;
                
            default:
                break;
            }
        }while (keepOn);
    }
	else if( tool == tRotate)
	{
		int shiftDown = 0;
		int controlDown = 1;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == t3DRotate)
	{
		int shiftDown = 0;
		int controlDown = 0;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
		[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == tTranslate)
    {
		int shiftDown = 1;
		int controlDown = 0;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
		[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == tZoom)
    {
		int shiftDown = 0;
		int controlDown = 1;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
		[self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
    else [super mouseDown:theEvent];
    
    return;
}

-(void) switchActor:(id) sender
{
	if( blendingController)
	{
		switch( [sender tag])
		{
			case 1:
				if( [sender state] == NSOnState) aRenderer->AddActor(blendingCoronal);
				else aRenderer->RemoveActor(blendingCoronal);
			break;
			case 0:
				if( [sender state] == NSOnState) aRenderer->AddActor(blendingSaggital);
				else aRenderer->RemoveActor(blendingSaggital);
			break;
			case 2:
				if( [sender state] == NSOnState) aRenderer->AddActor(blendingAxial);
				else aRenderer->RemoveActor(blendingAxial);
			break;
		}
	}
	else
	{
		switch( [sender tag])
		{
			case 1:
				if( [sender state] == NSOnState) aRenderer->AddActor(coronal);
				else aRenderer->RemoveActor(coronal);
			break;
			case 0:
				if( [sender state] == NSOnState) aRenderer->AddActor(saggital);
				else aRenderer->RemoveActor(saggital);
			break;
			case 2:
				if( [sender state] == NSOnState) aRenderer->AddActor(axial);
				else aRenderer->RemoveActor(axial);
			break;
		}
	}
	[self setNeedsDisplay:YES];
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];

	if( c == 27)
	{
		[[[self window] windowController] offFullScreen];
	}
	
	[super keyDown:event];
}

-(void) setBlendingWLWW:(float) wl :(float) ww
{
    double newValues[2];
    
    newValues[0] = wl - ww/2;
    newValues[1] = wl + ww/2;
    
    blendingBwLut->SetTableRange (newValues[0], newValues[1]);
    [self setNeedsDisplay:YES];
}

-(void) setBlendingFactor:(float) a
{
	long	i;
	float   val, ii;
	double  *RGBA;
	
	blendingFactor = a;
	
	if( a <= 0)
	{
		a += 256;
		
		for(i=0; i < 256; i++) 
		{
			ii = i;
			val = (a * ii) / 256.;
			
			if( val > 255) val = 255;
			if( val < 0) val = 0;
			
			RGBA = blendingBwLut->GetTableValue( i);
			blendingBwLut->SetTableValue(i, RGBA[0], RGBA[1], RGBA[2], val / 255.);
		}
	}
	else
	{
		if( a == 256)
		{
			for(i=0; i < 256; i++)
			{
				RGBA = blendingBwLut->GetTableValue( i);
				blendingBwLut->SetTableValue(i, RGBA[0], RGBA[1], RGBA[2], 1.0);
			}
		}
		else
		{
			for(i=0; i < 256; i++) 
			{
				ii = i;
				val = (256. * ii)/(256 - a);
				
				if( val > 255) val = 255;
				if( val < 0) val = 0;
				
				RGBA = blendingBwLut->GetTableValue( i);
				blendingBwLut->SetTableValue(i, RGBA[0], RGBA[1], RGBA[2], val / 255.);
			}
		}
	}
	
	[self movePlanes:-1:-1:-1];
	
	[self setNeedsDisplay: YES];
}

-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long	i;
	double  *RGBA;
	
	if( r)
	{
		for( i = 0; i < 256; i++)
		{
			RGBA = blendingBwLut->GetTableValue( i);
			blendingBwLut->SetTableValue(i, r[i] / 255., g[i] / 255., b[i] / 255., RGBA[3]);
		}
	}
	else
	{
		for( i = 0; i < 256; i++)
		{
			RGBA = blendingBwLut->GetTableValue( i);
			blendingBwLut->SetTableValue(i,i / 255., i / 255., i / 255., RGBA[3]);
		}
	}
	
	[self movePlanes :-1 :-1: -1];
	
    [self setNeedsDisplay:YES];
}

-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long i;

	if( r)
	{
		for( i = 0; i < 256; i++)
		{
			bwLut->SetTableValue(i, r[i] / 255., g[i] / 255., b[i] / 255., 1.0);
		}
	}
	else
	{
		for( i = 0; i < 256; i++)
		{
			bwLut->SetTableValue(i,i / 255., i / 255., i / 255., 1.0);
		}
	}
	
	[self movePlanes:-1:-1:-1];
	[self movePlanes:-1:-1:-1];
	
    [self setNeedsDisplay:YES];
}

-(void) setCurrentTool:(short) i
{
    currentTool = i;
	[selectedPlane setCurrentTool: i];
}

- (void) getWLWW:(float*) wl :(float*) ww
{
    double newValues[2];

    bwLut->GetTableRange ( newValues);
    
    *wl = (newValues[0] + (newValues[1] - newValues[0])/2);
    *ww = (newValues[1] - newValues[0]);
}


- (void) SetWLWWMPR3D: (NSNotification*) note
{
	NSDictionary	*dict = [note userInfo];
	double			fdata[2];
	double			wl, ww;
	
	bwLut->GetTableRange( fdata);
	
	wl = fdata[0] + (fdata[1] - fdata[0])/2;
	ww = (fdata[1] - fdata[0]);
	
	float WWAdapter = ww / 200.0;
	
	wl += [[dict objectForKey:@"WL"] longValue]*WWAdapter;
	ww += [[dict objectForKey:@"WW"] longValue]*WWAdapter;
	
	[self setWLWW:  wl: ww];
}

- (void) setWLWW:(float) wl :(float) ww
{
    double newValues[2];
    
	if( wl == 0 && ww == 0)
	{
		wl = [[pixList objectAtIndex:0] fullwl];
		ww = [[pixList objectAtIndex:0] fullww];
	}
	
    newValues[0] = wl - ww/2;
    newValues[1] = wl + ww/2;
    
    bwLut->SetTableRange (newValues[0], newValues[1]);
	
	[self movePlanes:-1:-1:-1];
	
    [self setNeedsDisplay:YES];
}

-(void) setBlendingPixSource:(ViewerController*) bC
{
    long i;
	
	blendingController = bC;
	
	if( blendingController)
	{
		blendingPixList = [bC pixList];
		[blendingPixList retain];
		
		blendingData = [bC volumePtr];
		
		blendingFirstObject = [blendingPixList objectAtIndex:0];
		
		blendingSliceThickness = [blendingFirstObject sliceInterval];   //[[blendingPixList objectAtIndex:1] sliceLocation] - [blendingFirstObject sliceLocation];
		
		if( blendingSliceThickness == 0)
		{
			NSLog(@"Blending slice interval = slice thickness!");
			blendingSliceThickness = [blendingFirstObject sliceThickness];
		}
		
		// PLAN 
		[blendingFirstObject orientation:blendingVectors];
		
//		if( blendingVectors[6] + blendingVectors[7] + blendingVectors[8] < 0)
//		{
//			NSLog(@"Oposite Vector!");
//			blendingSliceThickness = -blendingSliceThickness;
//		}

		vtkImageImport *blendingReader = vtkImageImport::New();
		blendingReader->SetWholeExtent( 0,
								[blendingFirstObject pwidth]-1,
								0,
								[blendingFirstObject pheight]-1,
								0,
								[blendingPixList count]-1);
//		blendingReader->SetDataExtent( 0,
//										[blendingFirstObject pwidth]-1,
//										0,
//										[blendingFirstObject pheight]-1,
//										0,
//										[blendingPixList count]-1);
//		NSLog(@"%d %d %d", [blendingFirstObject pwidth]-1, [blendingFirstObject pheight]-1, [blendingPixList count]-1);
		blendingReader->SetDataSpacing( [blendingFirstObject pixelSpacingX], [blendingFirstObject pixelSpacingY], blendingSliceThickness);//sliceThickness
		blendingReader->SetDataOrigin(  ([blendingFirstObject originX] ) * vectors[0] + ([blendingFirstObject originY]) * vectors[1] + ([blendingFirstObject originZ] )*vectors[2],
										([blendingFirstObject originX] ) * vectors[3] + ([blendingFirstObject originY]) * vectors[4] + ([blendingFirstObject originZ] )*vectors[5],
										([blendingFirstObject originX] ) * vectors[6] + ([blendingFirstObject originY]) * vectors[7] + ([blendingFirstObject originZ] )*vectors[8]);
//		blendingReader->SetDataOrigin(  [blendingFirstObject originX],
//										[blendingFirstObject originY],
//										[blendingFirstObject originZ]);
//		blendingReader->SetDataExtentToWholeExtent();
		blendingReader->SetDataScalarTypeToFloat();//SetDataScalarTypeToFloat();
		blendingReader->SetImportVoidPointer(blendingData);
		
		// X - Y - Z planes
		
		blendingBwLut = vtkLookupTable::New();  
		blendingBwLut->SetTableRange (200, 2000);
		blendingBwLut->SetNumberOfTableValues(256);
		
		// ******************* SAG
		slice = vtkImageReslice::New();
		slice->SetInput( blendingReader->GetOutput());
		
//		slice->SetResliceAxesOrigin(   [blendingFirstObject originX],
//										[blendingFirstObject originY],
//										[blendingFirstObject originZ]);

		
		slice->SetResliceAxesDirectionCosines(  blendingVectors[0], blendingVectors[3], blendingVectors[6],
												blendingVectors[1], blendingVectors[4], blendingVectors[7],
												blendingVectors[2], blendingVectors[5], blendingVectors[8]);
		slice->SetInterpolationModeToLinear();		// SetInterpolationModeToNearestNeighbor //SetInterpolationModeToCubic();
		slice->SetBackgroundLevel( 0);
		
		slice->SetOutputSpacing( rotate->GetOutput()->GetSpacing());
		slice->SetOutputOrigin( rotate->GetOutput()->GetOrigin());
		slice->SetOutputExtent( rotate->GetOutput()->GetExtent());
		
//		slice->SetOutputExtent(0,[firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);
		
//		slice->SetTransformInputSampling( true);
//		slice->SetAutoCropOutput( true);
		
		slice->Update();
		

		// *******************
		
		blendingAxialColors = vtkImageMapToColors::New();
		blendingAxialColors->SetInput(slice->GetOutput());
		blendingAxialColors->SetLookupTable(blendingBwLut);
		
		blendingSaggitalColors = vtkImageMapToColors::New();
		blendingSaggitalColors->SetInput(slice->GetOutput());
		blendingSaggitalColors->SetLookupTable(blendingBwLut);
		
		blendingCoronalColors = vtkImageMapToColors::New();
		blendingCoronalColors->SetInput(slice->GetOutput());
		blendingCoronalColors->SetLookupTable(blendingBwLut);
		
		blendingThickSlabColors = vtkImageMapToColors::New();
		blendingThickSlabColors->SetInput(slice->GetOutput());
		blendingThickSlabColors->SetLookupTable(blendingBwLut);
		
		slice->Delete();

		// *******************  SAG
		
		vtkImageBlend		*blender;
		
		blender = vtkImageBlend::New();
		blender->SetInput(0, saggitalColors->GetOutput());				blender->SetOpacity(0, 1.0);
		blender->SetInput(1, blendingSaggitalColors->GetOutput());		blender->SetOpacity(1, 1.0);
		
		blendingSaggital = vtkImageActor::New();
		blendingSaggital->SetInput(blender->GetOutput());
		
		blender->Delete();
		//
		
		// ******************* COR
		blender = vtkImageBlend::New();
		
		blender->SetInput(0, coronalColors->GetOutput());				blender->SetOpacity(0, 1.0);
		blender->SetInput(1, blendingCoronalColors->GetOutput());		blender->SetOpacity(1, 1.0);


		blendingCoronal = vtkImageActor::New();
		blendingCoronal->SetInput(blender->GetOutput());

		
		blender->Delete();

		// ******************* AXI
		blender = vtkImageBlend::New();
		blender->SetInput(0, axialColors->GetOutput());				blender->SetOpacity(0, 1.0);
		blender->SetInput(1, blendingAxialColors->GetOutput());		blender->SetOpacity(1, 1.0);


		blendingAxial = vtkImageActor::New();
		blendingAxial->SetInput(blender->GetOutput());
		
		blender->Delete();
		
		// ******************* THICK SLAB
		blender = vtkImageBlend::New();
		blender->SetInput(0, thickSlabColors->GetOutput());				blender->SetOpacity(0, 1.0);
		blender->SetInput(1, blendingSaggitalColors->GetOutput());		blender->SetOpacity(1, 1.0);
		
		thickSlabActor->SetInput(blender->GetOutput());
		
		blender->Delete();
		
		// *****************
		
		[[[self window] windowController] sliderAction:self];
		
		aRenderer->RemoveActor(saggital);
		aRenderer->RemoveActor(axial);
		aRenderer->RemoveActor(coronal);
		
		aRenderer->AddActor(blendingCoronal);
		aRenderer->AddActor(blendingSaggital);
		aRenderer->AddActor(blendingAxial);
		
		[self setBlendingFactor: blendingFactor];
	}
	else
	{
		if( blendingSaggital)
		{
			aRenderer->RemoveActor(blendingSaggital);
			aRenderer->RemoveActor(blendingAxial);
			aRenderer->RemoveActor(blendingCoronal);
			
			blendingBwLut->Delete();
			blendingSaggitalColors->Delete();
			blendingSaggital->Delete();
			blendingAxialColors->Delete();
			blendingAxial->Delete();
			blendingCoronalColors->Delete();
			blendingCoronal->Delete();

			aRenderer->AddActor(coronal);
			aRenderer->AddActor(saggital);
			aRenderer->AddActor(axial);
			
			thickSlabActor->SetInput(thickSlabColors->GetOutput());
			
			[self movePlanes:-1 :-1: -1];
			
			blendingSaggital = 0L;
		}
	}
}

-(void) movieChangeSource:(float*) volumeData
{
	data = volumeData;

	reader->SetImportVoidPointer(data);
	
	[self movePlanes:-1 :-1: -1];
}

-(short) setPixSource:(NSMutableArray*)pix :(NSArray*)f :(float*) volumeData
{
    short   error = 0;
	long	i;
	
	firstTime = YES;
	selectedPlaneID = 0;
	rotateTimer = 0L;
	
    perPixList = [[NSMutableArray alloc] initWithCapacity:0];
	
    [pix retain];
    pixList = pix;
	fileList = f;
	[fileList retain];
	
	data = volumeData;
	
	aRenderer = [self renderer];
	
	firstObject = [pixList objectAtIndex:0];
	sliceThickness = [firstObject sliceInterval];   //[[pixList objectAtIndex:1] sliceLocation] - [firstObject sliceLocation];
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [firstObject sliceThickness];
	}
	
	NSLog(@"Interval=%2.2f", sliceThickness);
	
	// PLAN 
	[firstObject orientation:vectors];

//	if( vectors[6] + vectors[7] + vectors[8] < 0)
//	{
//		sliceThickness = -sliceThickness;
//	}
	
	if( [firstObject isRGB])
	{
		// Convert RGB to BW... We could add support for RGB later if needed by users....
		
		long	i, size, val;
		unsigned char	*srcPtr = (unsigned char*) data;
		float   *dstPtr;
		
		size = [firstObject pheight] * [pix count];
		size *= [firstObject pwidth];
		size *= sizeof( float);
		
		dataFRGB = (float*) malloc( size);
		
		size /= 4;
		
		dstPtr = dataFRGB;
		for( i = 0 ; i < size; i++)
		{
			srcPtr++;
			val = *srcPtr++;
			val += *srcPtr++;
			val += *srcPtr++;
			*dstPtr++ = val/3;
		}
		
		data = dataFRGB;
	}
	
	if( vectors[6] + vectors[7] + vectors[8] < 0)
	{
		NSLog( @"Inverse thickness!");
		invThick = -1;
	}
	else invThick = 1;
	
	NSLog( @"%2.2f %2.2f %2.2f", vectors[6], vectors[7], vectors[8]);
	
	coronalPlane = NO;
	
	if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
	{
		NSLog(@"Saggital");
		rotationpane[0] = -90*invThick;
		rotationpane[1] = -90*invThick;
	}

	if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
	{
		NSLog(@"Coronal");
		rotationpane[0] = 90*invThick;
		coronalPlane = YES;
	}

	if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
	{
		NSLog(@"Axial");
	}
	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);
//	reader->SetDataExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);
//	NSLog(@"%d %d %d", [firstObject pwidth]-1, [firstObject pheight]-1, [pixList count]-1);
	
	reader->SetDataSpacing( [firstObject pixelSpacingX], [firstObject pixelSpacingY], sliceThickness);
	reader->SetDataOrigin(  ([firstObject originX] ) * vectors[0] + ([firstObject originY]) * vectors[1] + ([firstObject originZ] )*vectors[2],
							([firstObject originX] ) * vectors[3] + ([firstObject originY]) * vectors[4] + ([firstObject originZ] )*vectors[5],
							([firstObject originX] ) * vectors[6] + ([firstObject originY]) * vectors[7] + ([firstObject originZ] )*vectors[8]);
//	reader->SetDataOrigin(  [firstObject originX],
//							[firstObject originY],
//							[firstObject originZ]);
	reader->SetDataExtentToWholeExtent();
	reader->SetDataScalarTypeToFloat();
	reader->SetImportVoidPointer(data);

	if( vectors[0] == 1 && vectors[1] == 0 && vectors[2] == 0 &&
		vectors[3] == 0 && vectors[4] == 1 && vectors[5] == 0)			// Images are PURE AXIAL !
		{
			doRotate = NO;
		}
		else doRotate = YES;
	
	doRotate = NO;
	
	if( doRotate == YES)
	{
		NSLog(@"Rotate");
		rotate = vtkImageReslice::New();
		rotate->SetInput( reader->GetOutput());
		
//		rotate->SetResliceAxesOrigin(   [firstObject originX],
//										[firstObject originY],
//										[firstObject originZ]);
		
		rotate->SetResliceAxesDirectionCosines(		vectors[0], vectors[3], vectors[6],
													vectors[1], vectors[4], vectors[7],
													vectors[2], vectors[5], vectors[8]);
		
		rotate->SetInterpolationModeToLinear();
		rotate->SetTransformInputSampling( true);
		rotate->SetAutoCropOutput( true);
		
//		rotate->SetOutputSpacing(0.41, 0.41, 0.41);		<- We can increase or decrease resolution.... cool
		
//		vtkSphereSource *sphere = vtkSphereSource::New();
//		sphere->SetPhiResolution( 12);
//		sphere->SetThetaResolution( 12);
//		sphere->SetCenter( 0, 0, 0);
//		sphere->SetRadius( 300); 
//		
//		vtkPolyDataToImageStencil *dataToStencil = vtkPolyDataToImageStencil::New();
//		dataToStencil->SetInput( sphere->GetOutput());
//		
//		rotate->SetStencil( dataToStencil->GetOutput());
	
		rotate->Update();
		
	}
	else
	{
		rotate = (vtkImageReslice*) reader;
		reader->Update();
	}
	
    // An outline provides context around the data.
    //
    outlineData = vtkOutlineFilter::New();
	outlineData->SetInput((vtkDataSet *) rotate->GetOutput());
	
    mapOutline = vtkPolyDataMapper::New();
    mapOutline->SetInput(outlineData->GetOutput());
    
    outlineRect = vtkActor::New();
    outlineRect->SetMapper(mapOutline);
    outlineRect->GetProperty()->SetColor(0,1,0);
    outlineRect->GetProperty()->SetOpacity(0.5);
	
	// X - Y - Z planes
	
    bwLut = vtkLookupTable::New();  
    bwLut->SetTableRange (0, 256);
	bwLut->SetNumberOfTableValues(256);
	
	for( i = 0; i < 256; i++)
	{
		bwLut->SetTableValue(i, i / 256., i / 256., i / 256., 1);
	}
    
    axialColors = vtkImageMapToColors::New();
    axialColors->SetInput(rotate->GetOutput());
    axialColors->SetLookupTable(bwLut);
	
    saggitalColors = vtkImageMapToColors::New();
    saggitalColors->SetInput(rotate->GetOutput());
    saggitalColors->SetLookupTable(bwLut);
	
    coronalColors = vtkImageMapToColors::New();
    coronalColors->SetInput(rotate->GetOutput());
    coronalColors->SetLookupTable(bwLut);

    thickSlabColors = vtkImageMapToColors::New();
    thickSlabColors->SetInput(rotate->GetOutput());
    thickSlabColors->SetLookupTable(bwLut);

	
	
//    image2DColors = vtkImageMapToColors::New();
//    image2DColors->SetInput(reader2->GetOutput());
//    image2DColors->SetLookupTable(bwLut);
//
//	vtkImageMapper *imageMapper2D = vtkImageMapper::New();
//	imageMapper2D->SetInput( image2DColors->GetOutput());
//	imageMapper2D->SetColorWindow( 256);
//	imageMapper2D->SetColorLevel( 128);
	
//	imageMapper2D->SetUseCustomExtents(true);
//	imageMapper2D->SetZSlice(20);
	
//	vtkActor2D  *actor2D = vtkActor2D::New();
//	actor2D->SetMapper( imageMapper2D);
//	actor2D->GetProperty()->SetDisplayLocationToBackground();
	
//	vtkImageData*   imData;
	
//	imageActor2D = vtkImageActor::New();
//    imageActor2D->SetInput(image2DColors->GetOutput());
	
    saggital = vtkImageActor::New();
    saggital->SetInput(saggitalColors->GetOutput());

	coronal = vtkImageActor::New();
    coronal->SetInput(coronalColors->GetOutput());

    axial = vtkImageActor::New();
    axial->SetInput(axialColors->GetOutput());
	
	thickSlabActor = vtkImageActor::New();
	thickSlabActor->SetInput(thickSlabColors->GetOutput());

	// Links actors to camera & render view
	
    aCamera = vtkCamera::New();
    aCamera->SetViewUp (0, 0, -1);
    aCamera->SetPosition (0, 1, 0);
    aCamera->SetFocalPoint (0, 0, 0);
    aCamera->ComputeViewPlaneNormal();    
    
//	aRenderer->AddActor2D(actor2D);
	aRenderer->AddActor(outlineRect);
//	aRenderer->AddActor(imageActor2D);
	
	//vtkActor
//	[self renderWindow]->SetPosition(100, 100);
//	aRenderer->SetViewport( 0.5, 0.5, 1, 1);	//vtkViewport - vtkRenderWindow
//	outlineRect->SetPosition(100, 100, 0);
//vtkActor

    aRenderer->AddActor(saggital);
    aRenderer->AddActor(axial);
    aRenderer->AddActor(coronal);
    
//	vtkImplicitPlaneWidget  *planeWidgetX = vtkImplicitPlaneWidget::New();
//    planeWidgetX->SetInteractor( [self renderWindowInteractor]);
//	planeWidgetX->SetPlaceFactor(1.0);
//    planeWidgetX->SetInput(saggitalColors->GetOutput());
//    planeWidgetX->PlaceWidget();
//	planeWidgetX->PlaneProperty()->SetOpacity(0.5);
	
//  vtkImagePlaneWidget* planeWidgetX = vtkImagePlaneWidget::New();
//    planeWidgetX->SetInteractor( [self renderWindowInteractor]);
//    planeWidgetX->SetKeyPressActivationValue('x');
//    planeWidgetX->RestrictPlaneToVolumeOn();
//    planeWidgetX->GetPlaneProperty()->SetColor(1,0,0);
//    planeWidgetX->SetResliceInterpolateToNearestNeighbour();
//    planeWidgetX->SetInput(saggitalColors->GetOutput());
//    planeWidgetX->SetPlaneOrientationToXAxes();
//	planeWidgetX->SetSliceIndex(32);
//    planeWidgetX->DisplayTextOn();
//    planeWidgetX->On();
//    planeWidgetX->InteractionOff();
//    planeWidgetX->InteractionOn();

  // An initial camera view is created.  The Dolly() method moves 
  // the camera towards the FocalPoint, thereby enlarging the image.
  aRenderer->SetActiveCamera(aCamera);
  aRenderer->ResetCamera ();
  aCamera->Dolly(1.5);

    //vtkImageViewer2
/* vtkLight *light = vtkLight::New();
  light->SetFocalPoint(1.875,0.6125,0);
  light->SetPosition(0.875,1.6125,1);
  light->SetColor(1.0, 0, 0);
  aRenderer->AddLight(light);   */
//  aCamera->AddLight(light);
/*  aRenderer->GetActiveCamera()->SetFocalPoint(0,0,0);
  aRenderer->GetActiveCamera()->SetPosition(0,0,1);
  aRenderer->GetActiveCamera()->SetViewUp(0,1,0);
  aRenderer->GetActiveCamera()->ParallelProjectionOn();
  aRenderer->ResetCamera();
  aRenderer->GetActiveCamera()->SetParallelScale(1.5);  */

//	[self renderWindow]->StereoRenderOn();
//	[self renderWindow]->SetStereoTypeToRedBlue();
		
    [self setNeedsDisplay:YES];
	
	
	rotateTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(performRotateAnimation:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:rotateTimer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:rotateTimer forMode:NSEventTrackingRunLoopMode];
	rotateActivated = YES;

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (1, 0, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();
	
	[self movePlanes:[firstObject pwidth]/2 :[firstObject pheight]/2 :[pix count]/2];
	
    return error;
}

- (IBAction) switchRotate:(id) sender
{
	if( [sender state])
	{
		rotateActivated = YES;
	}
	else
	{
		rotateActivated = NO;
	}
}

- (IBAction) rotateSpeed:(id) sender
{
//	[rotateTimer invalidate];
//	[rotateTimer release];
//
//	rotateTimer = [[NSTimer scheduledTimerWithTimeInterval: 1 / [sender floatValue]  target:self selector:@selector(performRotateAnimation:) userInfo:nil repeats:YES] retain];
//	[[NSRunLoop currentRunLoop] addTimer:rotateTimer forMode:NSModalPanelRunLoopMode];
//	[[NSRunLoop currentRunLoop] addTimer:rotateTimer forMode:NSEventTrackingRunLoopMode];
	rotateSpeed = [sender floatValue];
}

- (void) performRotateAnimation:(id) sender
{
	if( rotateActivated)
	{
		aCamera->Azimuth( rotateSpeed);
		
		[self setNeedsDisplay:YES];
	}
}

-(IBAction) SwitchStereoMode :(id) sender
{
	if( [self renderWindow]->GetStereoRender() == false)
	{
		[self renderWindow]->StereoRenderOn();
		[self renderWindow]->SetStereoTypeToRedBlue();
	//	[self renderWindow]->SetStereoTypeToInterlaced();
	}
	else
	{
		[self renderWindow]->StereoRenderOff();
	}
	
	[self setNeedsDisplay:YES];
}

-(NSImage*) nsimageQuicktime
{
	NSImage *theIm;

	aRenderer->RemoveActor(outlineRect);
	
	[self display];
	
	theIm = [self nsimage:YES];
	
	aRenderer->AddActor(outlineRect);
	
	return theIm;
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	unsigned char	*buf = 0L;
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
		
		buf = (unsigned char*) malloc( *width * *height * *spp * *bpp/8);
		if( buf)
		{
			//[[self openGLContext] makeCurrentContext];
			[self getVTKRenderWindow]->MakeCurrent();
			glReadPixels(0, 0, *width, *height, GL_RGB, GL_UNSIGNED_BYTE, buf);
			
			long rowBytes = *width**spp**bpp/8;
			
			unsigned char	*tempBuf = (unsigned char*) malloc( rowBytes);
			
			for( i = 0; i < *height/2; i++)
			{
				BlockMoveData( buf + (*height - 1 - i)*rowBytes, tempBuf, rowBytes);
				BlockMoveData( buf + i*rowBytes, buf + (*height - 1 - i)*rowBytes, rowBytes);
				BlockMoveData( tempBuf, buf + i*rowBytes, rowBytes);
			}
		}
	}
//	else NSLog(@"Err getRawPixels...");
		
	return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
	NSBitmapImageRep	*rep;
	long				width, height, i, x, spp, bpp;
	NSString			*colorSpace;
	unsigned char		*dataPtr;
	
	dataPtr = [self getRawPixels :&width :&height :&spp :&bpp :!originalSize : YES];
	
	if( spp == 3) colorSpace = NSCalibratedRGBColorSpace;
	else colorSpace = NSCalibratedWhiteColorSpace;
	
	rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:0L
						   pixelsWide:width
						   pixelsHigh:height
						bitsPerSample:bpp
					  samplesPerPixel:spp
							 hasAlpha:NO
							 isPlanar:NO
					   colorSpaceName:colorSpace
						  bytesPerRow:width*bpp*spp/8
						 bitsPerPixel:bpp*spp] autorelease];
	
	BlockMoveData( dataPtr, [rep bitmapData], height*width*bpp*spp/8);
	
	//Add the small OsiriX logo at the bottom right of the image
	NSImage				*logo = [NSImage imageNamed:@"SmallLogo.tif"];
	NSBitmapImageRep	*TIFFRep = [[NSBitmapImageRep alloc] initWithData: [logo TIFFRepresentation]];
	
	for( i = 0; i < [TIFFRep pixelsHigh]; i++)
	{
		unsigned char	*srcPtr = ([TIFFRep bitmapData] + i*[TIFFRep bytesPerRow]);
		unsigned char	*dstPtr = ([rep bitmapData] + (height - [TIFFRep pixelsHigh] + i)*[rep bytesPerRow] + ((width-10)*3 - [TIFFRep bytesPerRow]));
		
		x = [TIFFRep bytesPerRow]/3;
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
	
     NSImage *image = [[NSImage alloc] init];
     [image addRepresentation:rep];
     
	 free( dataPtr);
	 
    return image;
}

-(IBAction) copy:(id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    NSImage *im;
    
    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    
    im = [self nsimage:NO];
    
    [pb setData: [im TIFFRepresentation] forType:NSTIFFPboardType];
    
    [im release];
}

- (void)changeColor:(id)sender{
	//change background color
	NSColor *color= [(NSColorPanel*)sender color];
	aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
	[self setNeedsDisplay:YES];
}



@end
