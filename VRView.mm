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

#import "VRView.h"
#import "DCMCursor.h"
#import "AppController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#import "wait.h"
#import "QuicktimeExport.h"
#include "vtkImageResample.h"
#import "VRController.h"
#import "BrowserController.h"
#import "DICOMExport.h"
#import "DefaultsOsiriX.h" // for HotKeys

#include "vtkAbstractPropPicker.h"
#include "vtkInteractorStyle.h"
#include "vtkWorldPointPicker.h"
#include "vtkOpenGLVolumeTextureMapper3D.h"

#include "vtkSphereSource.h"
#include "vtkAssemblyPath.h"

#define id Id
#include "itkImage.h"
#include "itkImportImageFilter.h"
#undef id
#import "ITKSegmentation3D.h"
#import "ITKBrushROIFilter.h"

//vtkVolumeMapper

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

#define BONEVALUE 250
#define BONEOPACITY 1.1

extern BrowserController *browserWindow;

extern "C"
{
OSErr VRObject_MakeObjectMovie (FSSpec *theMovieSpec, FSSpec *theDestSpec, long maxFrames);
extern NSString * documentsDirectory();
}

typedef struct _xyzArray
{
	short x;
	short y;
	short z;
} xyzArray;


// intersect3D_SegmentPlane(): intersect a segment and a plane
//    Input:  S = a segment, and Pn = a plane = {Point V0; Vector n;}
//    Output: *I0 = the intersect point (when it exists)
//    Return: 0 = disjoint (no intersection)
//            1 = intersection in the unique point *I0
//            2 = the segment lies in the plane

#define SMALL_NUM  0.00000001 // anything that avoids division overflow
#define DOT(v1,v2) (v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2])

int intersect3D_SegmentPlane( float *P0, float *P1, float *Pnormal, float *Ppoint, float* resultPt )
{
    float    u[ 3];
	float    w[ 3];
	
	u[ 0]  = P1[ 0] - P0[ 0];
	u[ 1]  = P1[ 1] - P0[ 1];
	u[ 2]  = P1[ 2] - P0[ 2];
	
	w[ 0] =  P0[ 0] - Ppoint[ 0];
	w[ 1] =  P0[ 1] - Ppoint[ 1];
	w[ 2] =  P0[ 2] - Ppoint[ 2];
	
    float     D = DOT(Pnormal, u);
    float     N = -DOT(Pnormal, w);
	
    if (fabs(D) < SMALL_NUM) {          // segment is parallel to plane
        if (N == 0)                     // segment lies in plane
            return 0;
        else
            return 0;                   // no intersection
    }
	
    // they are not parallel
    // compute intersect param
	
    float sI = N / D;
    if (sI < 0 || sI > 1)
        return 0;						// no intersection
	
    resultPt[ 0] = P0[ 0] + sI * u[ 0];		// compute segment intersect point
	resultPt[ 1] = P0[ 1] + sI * u[ 1];
	resultPt[ 2] = P0[ 2] + sI * u[ 2];
	
    return 1;
}

/*
 class vtkPlaneCallback : public vtkCommand
 {
public:
  static vtkPlaneCallback *New() 
    { return new vtkPlaneCallback; }
  void Delete()
    { delete this; }
  virtual void Execute(vtkObject *caller, unsigned long, void*)
    {
		vtkPlaneWidget *widget = reinterpret_cast<vtkPlaneWidget*>(caller);
		
		vtkPlane *pd1 = vtkPlane::New();
		widget->GetPlane( pd1);
		pd1->Push( -30);
		
		vtkVolume *volume = widget->GetProp3D();
		vtkVolumeRayCastMapper *mapper = volume->GetMapper();		//vtkVolumeRayCastMapper
		
		mapper->RemoveAllClippingPlanes();
		
		mapper->AddClippingPlane( pd1);
		pd1->Delete();
		
		pd1 = vtkPlane::New();
		widget->GetPlane( pd1);
		pd1->Push( 30);
		
		double x[3];
		pd1->GetNormal(x);
		
		x[0] = -x[0];   x[1] = -x[1];   x[2] = -x[2];
		pd1->SetNormal(x);
		
		mapper->AddClippingPlane( pd1);
		pd1->Delete();
		
		widget->SetHandleSize( 0.005);
	}
};*/

static void startRendering(vtkObject*,unsigned long c, void* ptr, void*)
{
	VRView* mipv = (VRView*) ptr;
	
	//vtkRenderWindow
	//[self renderWindow] SetAbortRender( true);
	if( c == vtkCommand::StartEvent)
	{
		[mipv newStartRenderingTime];
	}
	
	if( c == vtkCommand::EndEvent)
	{
		[mipv stopRendering];
		[mipv deleteStartRenderingTime];
	}
	
	if( c == vtkCommand::AbortCheckEvent)
	{
		if( [[NSDate date] timeIntervalSinceDate:[mipv startRenderingTime]] > 2.0)
		{
			[mipv startRendering];
			[mipv runRendering];
		}
	}
}

class vtkMyCallbackVR : public vtkCommand
{
public:
	vtkVolume *blendingVolume;
	
	void setBlendingVolume(vtkVolume *bV)
	{
		blendingVolume = bV;
	}
	
  static vtkMyCallbackVR *New( ) 
    {
		return new vtkMyCallbackVR;
	}
  void Delete()
    { delete this; }
	
	virtual void Execute(vtkObject *caller, unsigned long, void*)
    {
		double a[ 6];
		
		vtkBoxWidget *widget = reinterpret_cast<vtkBoxWidget*>(caller);
		
		vtkVolume *volume = (vtkVolume*) widget->GetProp3D();
		
		[VRView getCroppingBox: a :volume :widget];
		[VRView setCroppingBox: a :volume];
		
		[VRView getCroppingBox: a :blendingVolume :widget];
		[VRView setCroppingBox: a :blendingVolume];
		
		widget->SetHandleSize( 0.005);
    }
	
//	
//	
//  virtual void Execute(vtkObject *caller, unsigned long, void*)
//    {
//    //  vtkTransform *t = vtkTransform::New();
//		vtkBoxWidget *widget = reinterpret_cast<vtkBoxWidget*>(caller);
//	//	widget->GetTransform(t);
//	//	widget->GetProp3D()->SetUserTransform(t);
//		
//		vtkPolyData *pd = vtkPolyData::New();
//		widget->GetPolyData( pd);
//		
//		vtkVolume *volume = (vtkVolume*) widget->GetProp3D();
//		vtkAbstractVolumeMapper *mapper = volume->GetMapper();
//		
//		vtkPlanes   *planes = vtkPlanes::New();
//		widget->GetPlanes( planes);
//		
//		long i;
//		mapper->RemoveAllClippingPlanes();
//		for( i = 0; i < planes->GetNumberOfPlanes(); i++)
//		{
//			mapper->AddClippingPlane( planes->GetPlane( i));
//		}
//		
//		if( blendingVolume)
//		{
//			vtkAbstractVolumeMapper *blendingMapper = blendingVolume->GetMapper();
//			blendingMapper->RemoveAllClippingPlanes();
//			for( i = 0; i < planes->GetNumberOfPlanes(); i++)
//			{
//				blendingMapper->AddClippingPlane( planes->GetPlane( i));
//			}
//		}
//		
//		planes->Delete();
//		
//		widget->SetHandleSize( 0.005);
//		
////		mapper->SetCroppingRegionFlagsToInvertedFence();
//    }
};

@implementation VRView

+ (BOOL) getCroppingBox:(double*) a :(vtkVolume *) volume :(vtkBoxWidget*) croppingBox
{
	if( volume == 0L) return NO;

	vtkVolumeMapper *mapper = (vtkVolumeMapper*) volume->GetMapper();
	if( mapper)
	{
		// cropping box
		vtkPolyData *pd = vtkPolyData::New();
		croppingBox->GetPolyData(pd);
		
		vtkTransform *Transform = vtkTransform::New();
		Transform->SetMatrix(volume->GetUserMatrix());
		Transform->Push();
		Transform->Inverse();
		
		double min[3], max[3];
		double pointA[3], pointB[3];
			
		pd->GetPoint(8, pointA);	pd->GetPoint(9, pointB);
		min[0] = pointA[0];			max[0] = pointB[0];

		pd->GetPoint(10, pointA);	pd->GetPoint(11, pointB);
		min[1] = pointA[1];			max[1] = pointB[1];
		
		pd->GetPoint(12, pointA);	pd->GetPoint(13, pointB);
		min[2] = pointA[2];			max[2] = pointB[2];

		Transform->TransformPoint( min, min);
		Transform->TransformPoint (max, max);
		
		a[ 0] = min[ 0];
		a[ 2] = min[ 1];
		a[ 4] = min[ 2];

		a[ 1] = max[ 0];
		a[ 3] = max[ 1];
		a[ 5] = max[ 2];
		
		double origin[3];
		volume->GetPosition(origin);	//GetOrigin		
		a[0] -= origin[0];		a[1] -= origin[0];
		a[2] -= origin[1];		a[3] -= origin[1];
		a[4] -= origin[2];		a[5] -= origin[2];

		double temp;
		if(fabs(a[0]) > fabs(a[1])) {temp = a[0]; a[0] = a[1]; a[1] = temp;}
		if(fabs(a[2]) > fabs(a[3])) {temp = a[2]; a[2] = a[3]; a[3] = temp;}
		if(fabs(a[4]) > fabs(a[5])) {temp = a[4]; a[4] = a[5]; a[5] = temp;}
		
		pd->Delete();
		Transform->Delete();

		return YES;
	}
	else return NO;
}

+ (void) setCroppingBox:(double*) a :(vtkVolume*) volume
{
	long	i;
	
	if( volume == 0L) return;
	
	vtkVolumeMapper *mapper = (vtkVolumeMapper*) volume->GetMapper();
	if( mapper)
	{
		mapper->SetCropping(true);
		
		for( i = 0 ; i < 6; i++)
		{
			if( a[ i] < 0) a[ i] = 0;
		}
		
	//	NSLog(@"%f %f = %f %f = %f %f",  a[0], a[1], a[2], a[3], a[4], a[5]);
		
		mapper->SetCroppingRegionPlanes( a[0], a[1], a[2], a[3], a[4], a[5]);
	}
}

- (void) print:(id) sender
{
	bestRenderingMode = YES;
	
	[controller print: sender];
}

- (void) getOrientationText:(char *) string : (float *) vector :(BOOL) inv
{
	char orientationX;
	char orientationY;
	char orientationZ;

	char *optr = string;
	*optr = 0;
	
	if( inv)
	{
		orientationX = -vector[ 0] < 0 ? 'R' : 'L';
		orientationY = -vector[ 1] < 0 ? 'A' : 'P';
		orientationZ = -vector[ 2] < 0 ? 'I' : 'S';
	}
	else
	{
		orientationX = vector[ 0] < 0 ? 'R' : 'L';
		orientationY = vector[ 1] < 0 ? 'A' : 'P';
		orientationZ = vector[ 2] < 0 ? 'I' : 'S';
	}
	
	float absX = fabs( vector[ 0]);
	float absY = fabs( vector[ 1]);
	float absZ = fabs( vector[ 2]);
	
	int i; 
	for (i=0; i<1; ++i)
	{
		if (absX>.0001 && absX>absY && absX>absZ)
		{
			*optr++=orientationX; absX=0;
		}
		else if (absY>.0001 && absY>absX && absY>absZ)
		{
			*optr++=orientationY; absY=0;
		} else if (absZ>.0001 && absZ>absX && absZ>absY)
		{
			*optr++=orientationZ; absZ=0;
		} else break; *optr='\0';
	}
}

//- (void) flipData:(char*) ptr :(long) no :(long) size
//{
//	long i;
//	char*	tempData;
//	
//	NSLog(@"flip data");
//	
//	size *= 4;
//	
//	tempData = (char*) malloc( size);
//	
//	for( i = 0; i < no/2; i++)
//	{
//		BlockMoveData( ptr + size*i, tempData, size);
//		BlockMoveData( ptr + size*(no-1-i), ptr + size*i, size);
//		BlockMoveData( tempData, ptr + size*(no-1-i), size);
//	}
//	
//	free( tempData);
//}

- (void) setBlendingMode: (long) modeID
{
	if( blendingController == 0L) return;
	
	switch( modeID)
	{
		case 0:
			if( blendingVolumeMapper) blendingVolumeMapper->SetBlendModeToComposite();
			break;
			
		case 1:
			if( blendingVolumeMapper) blendingVolumeMapper->SetBlendModeToMaximumIntensity();
			break;
	}
}

- (long) mode
{
	return renderingMode;
}

- (IBAction)setRenderMode:(id)sender
{
	long modeID = [sender tag];
	[self setMode: modeID];
}

- (void) setMode: (long) modeID
{
	renderingMode = modeID;
	
	switch( modeID)
	{
		case 0:
			if( volumeMapper)
				volumeMapper->SetBlendModeToComposite();
				
			if( textureMapper)
				textureMapper->SetBlendModeToComposite();
		break;
		
		case 1:
			if( volumeMapper)
				volumeMapper->SetBlendModeToMaximumIntensity();
				
			if( textureMapper)
				textureMapper->SetBlendModeToMaximumIntensity();
		break;
	}
	
	[self setBlendingFactor:blendingFactor];
	
	if( volumeMapper)
	{
//		volumeMapper->SetLockSampleDistanceToInputSpacing( 1);
//		NSLog(@"SetLockSampleDistanceToInputSpacing");
	}
	
	[self setNeedsDisplay:YES];
}

- (void) setEngine: (long) engineID
{
	[self setEngine: engineID showWait: YES];
}

- (void) setEngine: (long) engineID showWait:(BOOL) showWait
{
	double a[ 6];
	
	[[NSUserDefaults standardUserDefaults] setInteger: engineID forKey:@"MAPPERMODEVR"];
	
	NSLog(@"Engine: %d", engineID);
	
	WaitRendering	*www = 0L;
	
	if( showWait) www = [[WaitRendering alloc] init:@"Preparing 3D data..."];
	[www start];
	
	BOOL validBox = [VRView getCroppingBox: a :volume :croppingBox];
	
	switch( engineID)
	{
		case 0:		// RAY CAST
			if( volumeMapper == 0L)
			{
				volumeMapper = vtkFixedPointVolumeRayCastMapper::New();
				volumeMapper->SetInput((vtkDataSet *) reader->GetOutput());
			}
			volumeMapper->SetMinimumImageSampleDistance( LOD);
			
			volume->SetMapper( volumeMapper);
		break;
		
		case 1:		// TEXTURE
			if( textureMapper == 0L)
			{
				textureMapper = vtkVolumeTextureMapper3D::New();
				textureMapper->SetInput((vtkDataSet *) reader->GetOutput());
				
				if( volumeProperty->GetShade())
					textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
				else
					textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
			}
			volume->SetMapper( textureMapper);
		break;
		
		case 2:		// BOTH
			if( volumeMapper == 0L)
			{
				volumeMapper = vtkFixedPointVolumeRayCastMapper::New();
				volumeMapper->SetInput((vtkDataSet *) reader->GetOutput());
			}
			volumeMapper->SetMinimumImageSampleDistance( LOD);
			
			if( textureMapper == 0L)
			{
				textureMapper = vtkVolumeTextureMapper3D::New();
				textureMapper->SetInput((vtkDataSet *) reader->GetOutput());
				
				if( volumeProperty->GetShade()) textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
				else textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
			}
			volume->SetMapper( textureMapper);
		break;
	}
	
	[self setMode: renderingMode];	// VR or MIP ?
	
	if( validBox)
	{
		[VRView setCroppingBox: a :volume];
		
		[VRView getCroppingBox: a :blendingVolume :croppingBox];
		[VRView setCroppingBox: a :blendingVolume];
	}
	else
	{
		[self resetImage: self];
		
		croppingBox->PlaceWidget();
	}
	
	if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
	if( volumeMapper) volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
	if( volumeMapper) volumeMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
	
	[self display];
	
	[www end];
	[www close];
	[www release];
}

- (void) setBlendingEngine: (long) engineID
{
	if( blendingController == 0L) return;
	
	double a[ 6];
	
	[[NSUserDefaults standardUserDefaults] setInteger: engineID forKey:@"MAPPERMODEVR"];
	
	NSLog(@"Blending Engine: %d", engineID);
	
	WaitRendering	*www = [[WaitRendering alloc] init:@"Preparing 3D data..."];
	[www start];
	
	BOOL validBox = [VRView getCroppingBox: a :volume :croppingBox];
	
	switch( engineID)
	{
		case 0:		// RAY CAST
			if( blendingVolumeMapper == 0L)
			{
				blendingVolumeMapper = vtkFixedPointVolumeRayCastMapper::New();
				blendingVolumeMapper->SetInput((vtkDataSet *) blendingReader->GetOutput());
			}
			blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
			
			blendingVolume->SetMapper( blendingVolumeMapper);
		break;
		
		case 1:		// TEXTURE
			if( blendingTextureMapper == 0L)
			{
				blendingTextureMapper = vtkVolumeTextureMapper3D::New();
				blendingTextureMapper->SetInput((vtkDataSet *) blendingReader->GetOutput());
				
				if( blendingVolumeProperty->GetShade())
					blendingTextureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
				else
					blendingTextureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
			}
			blendingVolume->SetMapper( blendingTextureMapper);
		break;
		
		case 2:		// BOTH
			if( blendingVolumeMapper == 0L)
			{
				blendingVolumeMapper = vtkFixedPointVolumeRayCastMapper::New();
				blendingVolumeMapper->SetInput((vtkDataSet *) blendingReader->GetOutput());
			}
			blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
			
			if( blendingTextureMapper == 0L)
			{
				blendingTextureMapper = vtkVolumeTextureMapper3D::New();
				blendingTextureMapper->SetInput((vtkDataSet *) blendingReader->GetOutput());
				
				if( blendingVolumeProperty->GetShade()) blendingTextureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
				else blendingTextureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
			}
			blendingVolume->SetMapper( blendingTextureMapper);
		break;
	}
	
	if( validBox)
	{
		[VRView setCroppingBox: a :volume];
		
		[VRView getCroppingBox: a :blendingVolume :croppingBox];
		[VRView setCroppingBox: a :blendingVolume];
	}
	else
	{
		[self resetImage: self];
		
		croppingBox->PlaceWidget();
	}
	[self display];
	
	[www end];
	[www close];
	[www release];
}

-(NSImage*) image4DForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
//	if( [cur intValue] != -1) [[[self window] windowController] setMovieFrame: [cur intValue]];
	if( [cur intValue] != -1) [controller setMovieFrame: [cur intValue]];
	
//	NSLog(@"frame: %d", [cur intValue]);
	
	bestRenderingMode = YES;
	
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
		
		if( [cur intValue] != 0)
		{
			if(verticalAngleForVR!=0 &&verticalAngleForVR!=-90 )
			{
				[self Vertical: -verticalAngleForVR]; // rotate to standard direction ( top of object facing right up)
			}
			if( [cur intValue] % numberOfFrames == 0 )//if need increase the vertical rotation angle
			{
				// Evaluating beyond 90 or -90 causes problems! Don't know why, seems it is vtk's limit.
				if(verticalAngleForVR==-90) 
				{
					aCamera->Roll(-rotateDirectionForVR * 360 / numberOfFrames);
					// Evaluation(90)
					[self Vertical: -45];
					[self Vertical: -45];
					verticalAngleForVR -= 360 / numberOfFrames;
					verticalAngleForVR+=180;
					aCamera->Azimuth(-rotateDirectionForVR * 360 / numberOfFrames);
					
					
				}
				else
				{
					verticalAngleForVR -= 360 / numberOfFrames;
					if(verticalAngleForVR<-90)//to avoid evaluating beyond 90 or -90, rotate the camera 180 vertically
					{
						// Evaluation(180)
						[self Vertical: 60];
						[self Vertical: 60];
						[self Vertical: 60];
						verticalAngleForVR+=180;
						rotateDirectionForVR = -rotateDirectionForVR;
					}
					else if(verticalAngleForVR==-90)
					{
						aCamera->Azimuth( rotateDirectionForVR * 360 / numberOfFrames);
						[self Vertical: -45];
						[self Vertical: -45];
						rotateDirectionForVR = -rotateDirectionForVR;
												
					}
				}
				
	
			}
			if(verticalAngleForVR!=-90)
			{
				aCamera->Azimuth( rotateDirectionForVR * 360 / numberOfFrames);// rotate camera horizontally when the top facing right up
				if(verticalAngleForVR!=0)
					aCamera->Elevation(verticalAngleForVR);//rotate camera vertically
			}
			else
			{
				if( [cur intValue] % numberOfFrames != 0 )
					aCamera->Roll(-rotateDirectionForVR * 360 / numberOfFrames);//if on the top or bottom use roll instead of azimuth
			}
		}
	}
	else
	{
		if([cur intValue] != 0) aCamera->Azimuth( 360 / numberOfFrames);
	}
	
	aCamera->SetFocalPoint( volume->GetCenter());
	aCamera->OrthogonalizeViewUp();
	aCamera->ComputeViewPlaneNormal();
	
	return [self nsimageQuicktime];
}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	switch( rotationOrientation)
	{
		case 0:
			[self Azimuth: [self rotation] / [max floatValue]];
		break;
	
		case 1:
			[self Vertical: [self rotation] / [max floatValue]];
		break;
	}
	
	if( [[[self window] windowController] movieFrames] > 1)
	{	
		short movieIndex = [cur intValue];
		
		while( movieIndex >= [[[self window] windowController] movieFrames]) movieIndex -= [[[self window] windowController] movieFrames];
		if( movieIndex < 0) movieIndex = 0;
		
		[[[self window] windowController] setMovieFrame: movieIndex];
	}
	
	return [self nsimageQuicktime];
}

-(IBAction) switchToSeriesRadio:(id) sender
{
	 [dcmExportMode selectCellWithTag:1];
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

- (IBAction) setCurrentdcmExport:(id) sender
{
	if( [[sender selectedCell] tag] == 1) [self checkView: dcmBox :YES];
	else [self checkView: dcmBox :NO];
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] == 1 ) { [[dcmquality cellWithTag: 1] setEnabled: NO]; if( [[dcmquality selectedCell] tag] == 1) [dcmquality selectCellWithTag: 0];}
	else [[dcmquality cellWithTag: 1] setEnabled: YES];
}

- (NSRect) centerRect: (NSRect) smallRect
               inRect: (NSRect) bigRect
{
    NSRect centerRect;
    centerRect.size = smallRect.size;

    centerRect.origin.x = (bigRect.size.width - smallRect.size.width) / 2.0;
    centerRect.origin.y = (bigRect.size.height - smallRect.size.height) / 2.0;

    return (centerRect);
}

-(void) restoreViewSizeAfterMatrix3DExport
{
	[self setFrame: savedViewSizeFrame];
}

-(void) setViewSizeToMatrix3DExport
{
	savedViewSizeFrame = [self frame];
	
	NSRect windowFrame;
	
	windowFrame.origin.x = 0;
	windowFrame.origin.y = 0;
	windowFrame.size.width = [[[self window] contentView] frame].size.width;
	windowFrame.size.height = [[[self window] contentView] frame].size.height - 10;
	
	switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"EXPORTMATRIXFOR3D"])
	{
		case 0:
		break;
		
		case 1:		[self setFrame: [self centerRect: NSMakeRect(0,0,512,512) inRect: windowFrame]];	break;
		case 2:		[self setFrame: [self centerRect: NSMakeRect(0,0,768,768) inRect: windowFrame]];	break;
	}
}

#define DATABASEPATH @"/DATABASE/"
-(IBAction) endDCMExportSettings:(id) sender
{
	[exportDCMWindow orderOut:sender];
	
	[NSApp endSheet:exportDCMWindow returnCode:[sender tag]];
	
	numberOfFrames = [dcmframesSlider intValue];
	bestRenderingMode = [[dcmquality selectedCell] tag];
	if( [[dcmrotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [[dcmorientation selectedCell] tag] == 1) rotationOrientation = 1;
	else rotationOrientation = 0;
	
	if( [sender tag])
	{
		[self setViewSizeToMatrix3DExport];
		
		// CURRENT image only
		if( [[dcmExportMode selectedCell] tag] == 0)
		{
			long	width, height, spp, bpp, err;
			float	cwl, cww;
			float	o[ 9];
			
			if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
			
			[self renderImageWithBestQuality: bestRenderingMode waitDialog: NO];
			unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :NO];
			[self endRenderImageWithBestQuality];
			
			if( dataPtr)
			{
				if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
				
				[exportDCM setSourceFile: [firstObject sourceFile]];
				[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
				[exportDCM setSeriesNumber:5500];
				[exportDCM setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				
				[self getOrientation: o];
				[exportDCM setOrientation: o];
				
				if( aCamera->GetParallelProjection())
					[exportDCM setPixelSpacing: [self getResolution] :[self getResolution]];
				
				err = [exportDCM writeDCMFile: 0L];
				if( err)  NSRunCriticalAlertPanel( NSLocalizedString(@"Error", 0L),  NSLocalizedString( @"Error during the creation of the DICOM File!", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
				
				free( dataPtr);
			}
		}
		// 4th dimension
		else if( [[dcmExportMode selectedCell] tag] == 2)
		{
			float			o[ 9];
			long			i;
			DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
			
			Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating a DICOM series", nil)];
			[progress showWindow:self];
			[[progress progress] setMaxValue: [[[self window] windowController] movieFrames]];
			
			[dcmSequence setSeriesNumber:5250 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
			[dcmSequence setSeriesDescription:@"4D VR"];
			[dcmSequence setSourceFile: [firstObject sourceFile]];
			
			for( i = 0; i < [[[self window] windowController] movieFrames]; i++)
			{
				NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
				
				[[[self window] windowController] setMovieFrame: i];
				
				if( croppingBox->GetEnabled()) croppingBox->Off();
			//	aRenderer->RemoveActor(outlineRect);
				aRenderer->RemoveActor(textX);
				
				noWaitDialog = YES;
				[self display];
				noWaitDialog = NO;
				
			//	aRenderer->AddActor(outlineRect);
				aRenderer->AddActor(textX);

				long	width, height, spp, bpp, err;
				
				unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :NO];
				
				if( dataPtr)
				{
					[self getOrientation: o];
					[dcmSequence setOrientation: o];
					
					[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
			//		[dcmSequence setPixelSpacing: 1 :1];
					
					err = [dcmSequence writeDCMFile: 0L];
					
					free( dataPtr);
				}
				
				[progress incrementBy: 1];
				
				[pool release];
			}
			
			[progress close];
			[progress release];
			
			[dcmSequence release];
		}
		else // A 3D sequence
		{
			long			i;
			float			o[ 9];
			DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
			
			if( [[[self window] windowController] movieFrames] > 1)
			{
				numberOfFrames /= [[[self window] windowController] movieFrames];
				numberOfFrames *= [[[self window] windowController] movieFrames];
			}
			
			Wait *progress = [[Wait alloc] initWithString:@"Creating a DICOM series"];
			[progress showWindow:self];
			[[progress progress] setMaxValue: numberOfFrames];
			
			[dcmSequence setSeriesNumber:5500 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
			[dcmSequence setSeriesDescription: [dcmSeriesName stringValue]];
			[dcmSequence setSourceFile: [firstObject sourceFile]];
			
			if( croppingBox->GetEnabled()) croppingBox->Off();
			aRenderer->RemoveActor(outlineRect);
			aRenderer->RemoveActor(textX);
			
			for( i = 0; i < numberOfFrames; i++)
			{
				NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
				
				if( [[[self window] windowController] movieFrames] > 1)
				{	
					short movieIndex = i;
			
					while( movieIndex >= [[[self window] windowController] movieFrames]) movieIndex -= [[[self window] windowController] movieFrames];
					if( movieIndex < 0) movieIndex = 0;
			
					[[[self window] windowController] setMovieFrame: movieIndex];
				}
				
				[self renderImageWithBestQuality: bestRenderingMode waitDialog: NO];

				long	width, height, spp, bpp, err;
				
				unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :NO];
				
				if( dataPtr)
				{
					[self getOrientation: o];
					[dcmSequence setOrientation: o];
					
					[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				
					if( aCamera->GetParallelProjection())
						[dcmSequence setPixelSpacing: [self getResolution] :[self getResolution]];
					
					err = [dcmSequence writeDCMFile: 0L];
					
					free( dataPtr);
				}
				
				switch( rotationOrientation)
				{
					case 0:
						[self Azimuth: (float) rotationValue / (float) numberOfFrames];
					break;
					
					case 1:
						[self Vertical: (float) rotationValue / (float) numberOfFrames];
					break;
				}
				[progress incrementBy: 1];
				
				[pool release];
			}
			
			[self endRenderImageWithBestQuality];
			
			[progress close];
			[progress release];
			
			[dcmSequence release];
		}
		
		[self restoreViewSizeAfterMatrix3DExport];
	}
}

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
		
//		[mov generateMovie: YES  :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		[mov createMovieQTKit:YES :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov release];
		
		[self restoreViewSizeAfterMatrix3DExport];
	}
	
}

- (void) exportDICOMFile:(id) sender
{
	if( exportDCMWindow == 0L)
	{
		NSRunAlertPanel(NSLocalizedString(@"Not available", nil), NSLocalizedString(@"This function is not available for this window.", nil), NSLocalizedString(@"OK", nil), nil, nil);
	}
	
	[self setCurrentdcmExport: dcmExportMode];
	if( [[[self window] windowController] movieFrames] > 1) [[dcmExportMode cellWithTag:2] setEnabled: YES];
	else [[dcmExportMode cellWithTag:2] setEnabled: NO];
	[NSApp beginSheet: exportDCMWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

-(float) rotation {return rotationValue;}
-(float) numberOfFrames {return numberOfFrames;}

-(void) Azimuth:(float) a
{
	aCamera->Azimuth( a);
	aCamera->OrthogonalizeViewUp();
}

-(void) Vertical:(float) a
{
	aCamera->Elevation( a);
	aCamera->OrthogonalizeViewUp();
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
		#if !__LP64__
		NSString			*path, *newpath;
		FSRef				fsref;
		FSSpec				spec, newspec;
		QuicktimeExport		*mov;
		
		[self setViewSizeToMatrix3DExport];
		
		verticalAngleForVR = 0;
		rotateDirectionForVR= 1;
		
		if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames*numberOfFrames];
		else
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames];
		
		path = [mov createMovieQTKit: NO  :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		if( path)
		{
			FSPathMakeRef((unsigned const char *)[path fileSystemRepresentation], &fsref, NULL);
			FSGetCatalogInfo( &fsref, kFSCatInfoNone,NULL, NULL, &spec, NULL);
			
			FSMakeFSSpec(spec.vRefNum, spec.parID, "\ptempMovie", &newspec);
			
			if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
				VRObject_MakeObjectMovie (&spec,&newspec, numberOfFrames*numberOfFrames);
			else
				VRObject_MakeObjectMovie (&spec,&newspec, numberOfFrames);
			
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			
			newpath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tempMovie"];
			
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			
			[[NSFileManager defaultManager] movePath: newpath  toPath: path handler: nil];
			
			
			
			[[NSWorkspace sharedWorkspace] openFile:path];
		}
		
		[mov release];
		
		[self restoreViewSizeAfterMatrix3DExport];
		
		#endif
	}
}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower
{
	volumeProperty->SetAmbient(ambient);
	volumeProperty->SetDiffuse(diffuse);
	volumeProperty->SetSpecular(specular);
	volumeProperty->SetSpecularPower(specularpower);
}

- (void) getShadingValues:(float*) ambient :(float*) diffuse :(float*) specular :(float*) specularpower
{
	*ambient = volumeProperty->GetAmbient();
	*diffuse = volumeProperty->GetDiffuse();
	*specular = volumeProperty->GetSpecular();
	*specularpower = volumeProperty->GetSpecularPower();
}

-(long) shading
{
	return volumeProperty->GetShade();
}

-(IBAction) switchProjection:(id) sender
{
//	projectionMode = [[sender selectedCell] tag];
//	switch( [[sender selectedCell] tag])
//	{
//		case 0:
//			aCamera->SetParallelProjection( false);
//			aCamera->SetViewAngle( 30);
//		break;
//		
//		case 2:
//			aCamera->SetParallelProjection( false);
//			aCamera->SetViewAngle( 60);
//		break;
//		
//		case 1:
//			aCamera->SetParallelProjection( true);
//			aCamera->SetViewAngle( 30);
//		break;
//	}
	
	[self setProjectionMode: [[sender selectedCell] tag]];
	
	if( aCamera->GetParallelProjection())
	{
//		[[[[[self window] windowController] toolsMatrix] cellWithTag: tMesure] setEnabled: YES];
		[[[controller toolsMatrix] cellWithTag: tMesure] setEnabled: YES];
	}
	else
	{
//		[[[[[self window] windowController] toolsMatrix] cellWithTag: tMesure] setEnabled: NO];
		[[[controller toolsMatrix] cellWithTag: tMesure] setEnabled: NO];
				
		if( currentTool == tMesure)
		{
			[self setCurrentTool: t3DRotate];
//			[[[[self window] windowController] toolsMatrix] selectCellWithTag: t3DRotate];
			[[controller toolsMatrix] selectCellWithTag: t3DRotate];
		}
	}
	
//	[self setNeedsDisplay:YES];
}

- (void) setProjectionMode: (int) mode
{
	projectionMode = mode;
	switch( mode)
	{
		case 0:
			aCamera->SetParallelProjection( false);
			aCamera->SetViewAngle( 30);
			
			aCamera->SetFocalPoint( volume->GetCenter());
			aCamera->ComputeViewPlaneNormal();
			aCamera->OrthogonalizeViewUp();
		break;
		
		case 2:
			aCamera->SetParallelProjection( false);
			aCamera->SetViewAngle( 60);
		break;
		
		case 1:
			aCamera->SetParallelProjection( true);
			aCamera->SetViewAngle( 30);
			
			aCamera->SetFocalPoint( volume->GetCenter());
			aCamera->ComputeViewPlaneNormal();
			aCamera->OrthogonalizeViewUp();
		break;
	}	
	[self setNeedsDisplay:YES];
}

-(void)activateShading:(BOOL)on;
{
	if(on)
		volumeProperty->ShadeOn();
	else
		volumeProperty->ShadeOff();
}

-(IBAction) switchShading:(id) sender
{
	if( [sender state] == NSOnState)
	{
		volumeProperty->ShadeOn();
		
		WaitRendering	*www = [[WaitRendering alloc] init:@"Preparing 3D data..."];
		[www start];
		
		if( textureMapper)
		{
			if( volumeProperty->GetShade()) textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
			else textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
			reader->GetOutput()->Modified();
		}
		
		[self display];
		[www end];
		[www close];
		[www release];
	}
	else
	{
		volumeProperty->ShadeOff();
		
		WaitRendering	*www = [[WaitRendering alloc] init:@"Preparing 3D data..."];
		[www start];
		
		if( textureMapper)
		{
			if( volumeProperty->GetShade()) textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
			else textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
			reader->GetOutput()->Modified();
		}
		
		[self display];
		[www end];
		[www close];
		[www release];
	}
}

-(IBAction) exportQuicktime3DVR:(id) sender
{
	if( export3DVRWindow == 0L)
	{
		NSRunAlertPanel(NSLocalizedString(@"Not available", nil), NSLocalizedString(@"This function is not available for this window.", nil), NSLocalizedString(@"OK", nil), nil, nil);
	}
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] == 1 ) { [[VRquality cellWithTag: 1] setEnabled: NO]; if( [[VRquality selectedCell] tag] == 1) [VRquality selectCellWithTag: 0];}
	else [[VRquality cellWithTag: 1] setEnabled: YES];
	
	[NSApp beginSheet: export3DVRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

- (IBAction) exportQuicktime:(id) sender
{
	long i;
	
	if( export3DWindow == 0L)
	{
		NSRunAlertPanel(NSLocalizedString(@"Not available", nil), NSLocalizedString(@"This function is not available for this window.", nil), NSLocalizedString(@"OK", nil), nil, nil);
	}
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] == 1 ) { [[quality cellWithTag: 1] setEnabled: NO]; if( [[quality selectedCell] tag] == 1) [quality selectCellWithTag: 0];}
	else [[quality cellWithTag: 1] setEnabled: YES];
	
//	if( [[[self window] windowController] movieFrames] > 1)
	if( [controller movieFrames] > 1)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"Quicktime Export", nil), NSLocalizedString(@"Should I export the temporal series or the 3D scene?", nil), NSLocalizedString(@"3D Scene", nil), NSLocalizedString(@"Temporal Series", nil), 0L) == NSAlertDefaultReturn)
		{
						[NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
		}
		else
		{
			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(image4DForFrame: maxFrame:) :[controller movieFrames]];
			[mov createMovieQTKit: YES  :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];			
			[mov release];
		}
	}
	else [NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
	return YES;
}

- (NSDate*) startRenderingTime
{
	return startRenderingTime;
}

- (void) newStartRenderingTime
{
	startRenderingTime = [[NSDate date] retain];
}

- (void) deleteStartRenderingTime
{
	[startRenderingTime release];
	startRenderingTime = 0L;
}

-(void) startRendering
{
	if( noWaitDialog == NO)
	{
		[splash start];
	}
}
//vtkRenderer
-(void) runRendering
{
	if( noWaitDialog == NO)
	{
		if( [splash run] == NO)
		{
			[self renderWindow]->SetAbortRender( true);
		}
	}
}

-(void) stopRendering
{
	if( noWaitDialog == NO)
	{
		[splash end];
	}
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == blendingController) // our blended serie is closing itself....
	{
		[self setBlendingPixSource:0L];
		[self setNeedsDisplay:YES];
	}
}

- (void) CLUTChanged: (NSNotification*) note
{
	unsigned char   r[256], g[256], b[256];
	
	[[note object] ConvertCLUT: r :g :b];
	
	//aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
	
	[self setCLUT :r : g : b];
}

- (void) OpacityChanged: (NSNotification*) note
{
	[self setOpacity: [[note object] getPoints]];
}

- (long) getTool: (NSEvent*) event
{
	long tool;
	
	if( [event type] == NSRightMouseDown || [event type] == NSRightMouseDragged || [event type] == NSRightMouseUp) tool = tZoom;
	else if( [event type] == NSOtherMouseDown || [event type] == NSOtherMouseDragged || [event type] == NSOtherMouseUp) tool = tTranslate;
	else tool = currentTool;
	
	if (([event modifierFlags] & NSControlKeyMask))  tool = tRotate;
	if (([event modifierFlags] & NSShiftKeyMask))  tool = tZoom;
	if (([event modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
	if (([event modifierFlags] & NSAlternateKeyMask))  tool = tWL;
	if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))
	{
		tool = tWLBlended;
	}
	if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSControlKeyMask))
	{
		tool = tCamera3D;
	}
	
	return tool;
}

- (void) resetAutorotate:(id) sender
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"autorotate3D"] && [[[self window] windowController] isKindOfClass:[VRController class]])
	{
		[startAutoRotate invalidate];
		[startAutoRotate release];
		
		startAutoRotate = [[NSTimer scheduledTimerWithTimeInterval:60*3 target:self selector:@selector(startAutoRotate:) userInfo:nil repeats:NO] retain];
	}
}

- (void) startAutoRotate:(id) sender
{
	rotate = YES;
}

- (void) autoRotate:(id) sender
{
	if( rotate)
	{
		[self Azimuth: 4.];
		[self mouseMoved: [[NSApplication sharedApplication] currentEvent]];
		[self setNeedsDisplay: YES];
	}
}

- (void) checkMouseModifiers:(id) sender
{
	if( [[NSApp currentEvent] modifierFlags])
	{
		long tool = [self getTool:[NSApp currentEvent]];
		[self setCursorForView: tool];
	}
}

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame] )
    {
		rotate = NO;
		
		splash = [[WaitRendering alloc] init:NSLocalizedString(@"Rendering...", nil)];
		currentTool = t3DRotate;
		[self setCursorForView: currentTool];
		
		deleteRegion = [[NSLock alloc] init];
		
		valueFactor = 1.0;
		OFFSET16 = 1500;
		blendingValueFactor = 1.0;
		blendingOFFSET16 = 1500;
		
		renderingMode = 0;	// VR, MIP = 1
		blendingController = 0L;
		blendingFactor = 128.;
		blendingVolume = 0L;
		exportDCM = 0L;
		currentOpacityArray = 0L;
		textWLWW = 0L;
		cursor = 0L;
		
		dataFRGB = 0L;
		
		isViewportResizable = YES;
		
		data8 = 0L;
		
		opacityTransferFunction = 0L;
		volumeProperty = 0L;
		compositeFunction = 0L;
		red = 0L;
		green = 0L;
		blue = 0L;
		pixList = 0L;
		
		firstTime = YES;
		ROIUPDATE = NO;
		
		aCamera = 0L;
		
		needToFlip = NO;
		blendingNeedToFlip = NO;
		
		// MAPPERS
		textureMapper = 0L;
		volumeMapper = 0L;
//		shearWarpMapper = 0L;
		
		blendingTextureMapper = 0L;
		blendingVolumeMapper = 0L;
//		blendingShearWarpMapper = 0L;
		
		noWaitDialog = NO;
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
				 
		[nc addObserver: self
			   selector: @selector(OpacityChanged:)
				   name: @"OpacityChanged"
				 object: nil];
				 
		[nc addObserver: self
			   selector: @selector(CLUTChanged:)
				   name: @"CLUTChanged"
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
		
		mouseModifiers = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkMouseModifiers:) userInfo:nil repeats:YES] retain];
		autoRotate = [[NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(autoRotate:) userInfo:nil repeats:YES] retain];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"autorotate3D"] && [[[self window] windowController] isKindOfClass:[VRController class]])
			startAutoRotate = [[NSTimer scheduledTimerWithTimeInterval:60*3 target:self selector:@selector(startAutoRotate:) userInfo:nil repeats:NO] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: 0L];
		advancedCLUT = NO;
		
		lowResLODFactor = 3.0;
	}
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
		if(clutOpacityView) [[clutOpacityView window] close];
		
		[startAutoRotate invalidate];
		[startAutoRotate release];
		startAutoRotate = 0L;
		
		[autoRotate invalidate];
		[autoRotate release];
		autoRotate = 0L;
		
		[mouseModifiers invalidate];
		[mouseModifiers release];
		mouseModifiers = 0L;
		
		[[NSNotificationCenter defaultCenter] removeObserver: self];
	}
}

- (IBAction) resetImage:(id) sender
{
	aCamera->SetViewUp (0, 1, 0);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, 1);
	aCamera->SetRoll(180);
	aCamera->Dolly(1.5);
		
	aRenderer->ResetCamera();
	[self saView:self];
    [self setNeedsDisplay:YES];
}

-(void) set3DStateDictionary:(NSDictionary*) dict
{
	float   temp[ 5];
	NSArray *tempArray;
	
	if( dict)
	{
		tempArray = [dict objectForKey:@"ShadingValues"];
		if( tempArray)
		{
			[self setShadingValues:[[tempArray objectAtIndex:0] floatValue] :[[tempArray objectAtIndex:1] floatValue] :[[tempArray objectAtIndex:2] floatValue] :[[tempArray objectAtIndex:3] floatValue]];
		}
		
		if( renderingMode == 0)				// volume rendering
			volumeProperty->SetShade( [[dict objectForKey:@"ShadingFlag"] longValue]);
		
		[self setEngine: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]];
		
		if( [[dict objectForKey:@"SUVConverted"] boolValue] == [firstObject SUVConverted])
			[self setWLWW: [[dict objectForKey:@"WL"] floatValue] :[[dict objectForKey:@"WW"] floatValue]];
		
		tempArray = [dict objectForKey:@"CameraPosition"];
		aCamera->SetPosition( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);

		tempArray = [dict objectForKey:@"CameraViewUp"];
		aCamera->SetViewUp( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);

		tempArray = [dict objectForKey:@"CameraFocalPoint"];
		aCamera->SetFocalPoint( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);
		
		tempArray = [dict objectForKey:@"CameraClipping"];
		aCamera->SetClippingRange( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue]);
		
		if( [dict objectForKey:@"Projection"])
		{
			[projection selectCellWithTag: [[dict objectForKey:@"Projection"] intValue]];
			[self switchProjection: projection];
		}
	}
	else
	{
		[self setEngine: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]];
		
		#if __ppc__
		volumeProperty->SetShade( 0);
		#else
		if( renderingMode == 0)				// volume rendering
			volumeProperty->SetShade( 1);
		#endif
	}
}

-(NSMutableDictionary*) get3DStateDictionary
{
	double	temp[ 3];
	float	ambient, diffuse, specular, specularpower;
	
	if( aCamera == 0L) return 0L;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:[NSNumber numberWithFloat:wl] forKey:@"WL"];
	[dict setObject:[NSNumber numberWithFloat:ww] forKey:@"WW"];
	[dict setObject:[NSNumber numberWithBool:[firstObject SUVConverted]] forKey:@"SUVConverted"];
	
	aCamera->GetPosition( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], 0L] forKey:@"CameraPosition"];
	aCamera->GetViewUp( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], 0L] forKey:@"CameraViewUp"];
	aCamera->GetFocalPoint( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], 0L] forKey:@"CameraFocalPoint"];
	aCamera->GetClippingRange( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]], 0L] forKey:@"CameraClipping"];

	[self getShadingValues:&ambient :&diffuse :&specular :&specularpower];
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:ambient],  [NSNumber numberWithFloat:diffuse], [NSNumber numberWithFloat:specular],  [NSNumber numberWithFloat:specularpower], 0L] forKey:@"ShadingValues"];
	[dict setObject:[NSNumber numberWithLong:volumeProperty->GetShade()] forKey:@"ShadingFlag"];
	[dict setObject:[NSNumber numberWithLong:projectionMode] forKey:@"Projection"];
	
	return dict;
}

- (void) drawRect:(NSRect)aRect
{
	WaitRendering	*www = 0;
	
	if( firstTime)
	{
		NSLog( @"POP");
		firstTime = NO;	
		www = [[WaitRendering alloc] init:NSLocalizedString(@"Preparing 3D data...", nil)];
		[www start];
	}
	
	[self computeOrientationText];
	[super drawRect:aRect];
	
	if( www)
	{
		NSLog( @"OPO");
		[www end];
		[www close];
		[www release];
		
		if( isRGB == NO)
		{
			*(data+0) = firstPixel;
			*(data+1) = secondPixel;
			
			vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
		}
	}
}

-(void)dealloc
{
	long i;
	
    NSLog(@"Dealloc VRView");
	
	[deleteRegion lock];
	[deleteRegion unlock];
	[deleteRegion release];
	
	[exportDCM release];
	[splash close];
	[splash release];
	[currentOpacityArray release];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
//	cropcallback->Delete();
	
	[self setBlendingPixSource: 0L];
	
	cbStart->Delete();
	opacityTransferFunction->Delete();
	volumeProperty->Delete();
	compositeFunction->Delete();
	
	orientationWidget->Delete();
	
	if( volumeMapper) volumeMapper->Delete();
	if( textureMapper) textureMapper->Delete();
//	if( shearWarpMapper) shearWarpMapper->Delete();
	
	red->Delete();
	green->Delete();
	blue->Delete();
	
	volume->Delete();
	outlineData->Delete();
	mapOutline->Delete();
	outlineRect->Delete();
	croppingBox->Delete();
	textWLWW->Delete();
	textX->Delete();
	for( i = 0; i < 4; i++) oText[ i]->Delete();
	colorTransferFunction->Delete();
	reader->Delete();
    aCamera->Delete();
//	aRenderer->Delete();
	
	ROI3DData->Delete();
	ROI3D->Delete();
	ROI3DActor->Delete();
	
	Line2D->Delete();
	Line2DActor->Delete();
	Line2DText->Delete();
	
    [pixList release];
    pixList = 0L;
	
	if( dataFRGB) free( dataFRGB);
	
	if( data8) free( data8);
	
	[point3DActorArray release];
	[point3DPositionsArray release];
	[point3DRadiusArray release];
	[point3DColorsArray release];
	
	[cursor release];
	
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];
	
	[destinationImage release];
	
	[_hotKeyDictionary release];
	[appliedCurves release];
	
    [super dealloc];
}


- (void)finalize {
	[deleteRegion lock];
	[deleteRegion unlock];
	
	cbStart->Delete();
	opacityTransferFunction->Delete();
	volumeProperty->Delete();
	compositeFunction->Delete();
	
	orientationWidget->Delete();
	
	if( volumeMapper) volumeMapper->Delete();
	if( textureMapper) textureMapper->Delete();
//	if( shearWarpMapper) shearWarpMapper->Delete();
	
	red->Delete();
	green->Delete();
	blue->Delete();
	
	volume->Delete();
	outlineData->Delete();
	mapOutline->Delete();
	outlineRect->Delete();
	croppingBox->Delete();
	textWLWW->Delete();
	textX->Delete();
	int i;
	for( i = 0; i < 4; i++) oText[ i]->Delete();
	colorTransferFunction->Delete();
	reader->Delete();
    aCamera->Delete();
//	aRenderer->Delete();
	
	ROI3DData->Delete();
	ROI3D->Delete();
	ROI3DActor->Delete();
	
	Line2D->Delete();
	Line2DActor->Delete();
	Line2DText->Delete();
	
	if( dataFRGB) free( dataFRGB);	
	if( data8) free( data8);
	
	[super finalize];

}


- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self mouseDown:theEvent];
			//show contextual menu  added LP 12/5/05
//		if ([theEvent type] == NSRightMouseDown && [theEvent clickCount] > 1)
//			[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
}

- (void) timerUpdate:(id) sender
{
	if( ROIUPDATE == YES)
		[self display];
		
	ROIUPDATE = NO;
}

- (float) getResolution
{
	if( aCamera->GetParallelProjection())
	{
		double			point1[ 4] = { 0, 0, 0, 0}, point2[ 4] = { 1, 0, 0, 0};
		char			text[ 256];
		
		aRenderer->SetDisplayPoint( point1);
		aRenderer->DisplayToWorld();
		aRenderer->GetWorldPoint( point1);
		
		aRenderer->SetDisplayPoint( point2);
		aRenderer->DisplayToWorld();
		aRenderer->GetWorldPoint( point2);
		
		double xd = point2[ 0]- point1[ 0];
		double yd = point2[ 1]- point1[ 1];
		double zd = point2[ 2]- point1[ 2];
		double length = sqrt(xd*xd + yd*yd + zd*zd);

		return (length/factor);
	}
	else return 0;
}

- (void) computeLength
{
	vtkPoints		*pts = Line2DData->GetPoints();
	
	if( pts->GetNumberOfPoints() == 2)
	{
		double			point1[ 4], point2[ 4];
		char			text[ 256];
		
		pts->GetPoint( 0, point1);
		pts->GetPoint( 1, point2);
		
		aRenderer->SetDisplayPoint( point1);
		aRenderer->DisplayToWorld();
		aRenderer->GetWorldPoint( point1);
		
		aRenderer->SetDisplayPoint( point2);
		aRenderer->DisplayToWorld();
		aRenderer->GetWorldPoint( point2);
		
		double xd = point2[ 0]- point1[ 0];
        double yd = point2[ 1]- point1[ 1];
        double zd = point2[ 2]- point1[ 2];
        double length = sqrt(xd*xd + yd*yd + zd*zd);
		
		
		pts->GetPoint( 0, point1);
		pts->GetPoint( 1, point2);
		
		Line2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
		if( point1[ 0] > point2[ 0]) Line2DText->GetPositionCoordinate()->SetValue( point1[0] + 3, point1[ 1]);
		else Line2DText->GetPositionCoordinate()->SetValue( point2[0], point2[ 1]);
		
		if (length/(10.*factor) < .1)
			sprintf( text, "Length: %2.2f %cm", (length/(10.*factor)) * 10000.0, 0xB5);
		else
			sprintf( text, "Length: %2.2f cm", length/(10.*factor));
		
		Line2DText->SetInput( text);
		aRenderer->AddActor(Line2DText);
	}
	else aRenderer->RemoveActor(Line2DText);
}

- (void) getOrientation: (float*) o 
{
	long			i, j;
	vtkMatrix4x4	*matrix;
	
	matrix = aCamera->GetViewTransformMatrix();
	
	for( i = 0; i < 3; i++)
		for( j = 0; j < 3; j++)
			o[ 3*i + j] = matrix->GetElement( i , j);
			
	o[ 3] = -o[ 3];
	o[ 4] = -o[ 4];
	o[ 5] = -o[ 5];
}

- (void) computeOrientationText
{
	long			i, j;
	char			string[ 10];
	float			vectors[ 9];
	
	[self getOrientation: vectors];
	
	[self getOrientationText:string :vectors :YES];
	oText[ 0]->SetInput( string);
	
	[self getOrientationText:string :vectors :NO];
	oText[ 1]->SetInput( string);
	
	[self getOrientationText:string :vectors+3 :NO];
	oText[ 2]->SetInput( string);
	
	[self getOrientationText:string :vectors+3 :YES];
	oText[ 3]->SetInput( string);
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	vtkCocoaRenderWindowInteractor *interactor = [self getInteractor];
	if (!interactor) return;
	
	rotate = NO;
	[self resetAutorotate: self];
	
	if( projectionMode != 2)
	{
		// Rotate
		[self Azimuth: [theEvent deltaY] * 2];
		[self mouseMoved: [[NSApplication sharedApplication] currentEvent]];
		[self setNeedsDisplay: YES];
	}
	else
	{
		// Endoscopy - Zoom in/out
		
		float distance = aCamera->GetDistance();
		
		float dolly = [theEvent deltaY] / 40.;
		
		if( dolly < -0.9) dolly = -0.9;
		
		aCamera->Dolly( 1.0 + dolly); 
		aCamera->SetDistance( distance);
		aCamera->ComputeViewPlaneNormal();
		aCamera->OrthogonalizeViewUp();
		aRenderer->ResetCameraClippingRange();
		
		[self setNeedsDisplay:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
	}
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	int tool = [self getTool: theEvent];
	[self setCursorForView: tool];
	
	[super otherMouseDown: theEvent];
}

- (void) setRotate: (BOOL) r
{
	rotate = r;
}

-(void) mouseMoved: (NSEvent*) theEvent
{
//	#if __LP64__
//	return;
//	#endif
	
	long	pix[ 3];
	float	pos[ 3], value;
	
	NSPoint mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: 0L];
	
	if( [self get3DPixelUnder2DPositionX:mouseLocStart.x Y:mouseLocStart.y pixel:pix position:pos value:&value])
	{
		long sliceNo;
		if( [[[controller viewer2D] imageView] flippedData]) sliceNo = pix[ 2];
		else sliceNo = [pixList count] -1 -pix[ 2];
	
		NSString	*pixLoc = [[NSString stringWithFormat: @"X:%d Y:%d Z:%d (px)", pix[ 0], pix[ 1], sliceNo] stringByPaddingToLength: 23 withString: @" " startingAtIndex: 0];
		NSString	*mmLoc = [[NSString stringWithFormat: @"X:%.2f Y:%.2f Z:%.2f (mm)", pos[ 0], pos[ 1], pos[ 2]] stringByPaddingToLength: 38 withString: @" " startingAtIndex: 0];
		NSString	*val = [[NSString stringWithFormat: @"%.2f", value] stringByPaddingToLength: 9 withString: @" " startingAtIndex:  0];
		
		[pixelInformation setStringValue: [NSString stringWithFormat: @"View Size: %d x %d   Pixel: %@    %@ %@", (int) [self frame].size.width, (int)[self frame].size.height, val, pixLoc, mmLoc]];
	}
	else [pixelInformation setStringValue: [NSString stringWithFormat: @"View Size: %d x %d", (int) [self frame].size.width, (int) [self frame].size.height]];
}

-(void) squareView:(id) sender
{
	NSLog(@"%d", [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"]);
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 1) return;
	
	NSRect  selfFrame = [[[self window] contentView] frame];
	
	selfFrame.size.height -= 30;
	
	NSRect	newFrame = selfFrame;
	NSRect	beforeFrame = selfFrame;
	
	int		border = selfFrame.size.height-1;
	
	if( border > selfFrame.size.width) border = selfFrame.size.width;
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 2) border = 512;
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 3) border = 768;
	
	newFrame.size.width = (int)border;
	newFrame.size.height = (int)border;

	newFrame.origin.x = (int) ((beforeFrame.size.width - border) / 2);
	newFrame.origin.y = (int) (10 + (beforeFrame.size.height - border) / 2);
	
	[self setFrame: newFrame];
	
	[[self window] display];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (_dragInProgress == NO && ([theEvent deltaX] != 0 || [theEvent deltaY] != 0)) {
			[self deleteMouseDownTimer];
		}
		
	if (_dragInProgress == YES) return;
	
	if (_resizeFrame)
	{
		NSRect	newFrame = [self frame];
		NSRect	beforeFrame;
		NSPoint mouseLoc = [theEvent locationInWindow];
		//if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*3);
		if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD * lowResLODFactor);
		
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
					return;
				}
				else
					colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
				

				if( [[[controller viewer2D] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller viewer2D] modality] isEqualToString:@"NM"] == YES))
				{
					if( ww < 50) sprintf(WLWWString, "From: %0.4f   To: %0.4f", wl-ww/2, wl+ww/2);
					else sprintf(WLWWString, "From: %0.f   To: %0.f", wl-ww/2, wl+ww/2);
				}
				else
				{
					if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f", wl, ww);
					else sprintf(WLWWString, "WL: %0.f WW: %0.f", wl, ww);
				}
				
				textWLWW->SetInput( WLWWString);
				[self setNeedsDisplay:YES];
			break;
				
				case t3DCut:
				
				if( fabs(mouseLoc.x - _previousLoc.x) > 5. || fabs(mouseLoc.y - _previousLoc.y) > 5.)
				{
					double	*pp;
					long	i;
					
					aRenderer->SetDisplayPoint( mouseLoc.x, mouseLoc.y, 0);
					aRenderer->DisplayToWorld();
					pp = aRenderer->GetWorldPoint();
					
					// Create the 2D Actor
					
					aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
					aRenderer->WorldToDisplay();
					
					double *tempPoint = aRenderer->GetDisplayPoint();
					
					NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
					
					vtkPoints *pts = ROI3DData->GetPoints();
					pts->InsertPoint( pts->GetNumberOfPoints(), tempPoint[0], tempPoint[ 1], 0);
					
					vtkCellArray *rect = vtkCellArray::New();
					rect->InsertNextCell( pts->GetNumberOfPoints()+1);
					for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
					rect->InsertCellPoint( 0);
					
					ROI3DData->SetVerts( rect);
					ROI3DData->SetLines( rect);		rect->Delete();
					
					ROI3DData->SetPoints( pts);
					
					if( ROIUPDATE == NO)
					{
						ROIUPDATE = YES;
						[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:0]; 
					}
					
					_previousLoc = mouseLoc;
				}
				break;
				
				case tRotate:
					shiftDown = 0;
					controlDown = 1;
					[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
					break;
				
				case t3DRotate:
					shiftDown = 0;
					controlDown = 0;
					[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
					break;
				case tTranslate:
					shiftDown = 1;
					controlDown = 0;
					[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
					break;
				case tZoom:
					[self rightMouseDragged:theEvent];
					break;
				case tCamera3D:
					aCamera->Yaw( -([theEvent deltaX]) / 5.);
					aCamera->Pitch( -([theEvent deltaY]) / 5.);
					aCamera->ComputeViewPlaneNormal();
					aCamera->OrthogonalizeViewUp();
					aRenderer->ResetCameraClippingRange();
					[self computeOrientationText];
					[self setNeedsDisplay:YES];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
					break;
			default:
				break;
		}
	}
}

- (void)rightMouseDragged:(NSEvent *)theEvent{
	NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
	float distance ;
	
	if( projectionMode != 2)
	{
		int shiftDown = 0;
		int controlDown = 1;
		[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		[self computeLength];
		[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
		[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
	}
	else
	{
		distance = aCamera->GetDistance();
		aCamera->Dolly( 1.0 + (-[theEvent deltaY]) / 1200.);
		aCamera->SetDistance( distance);
		aCamera->ComputeViewPlaneNormal();
		aCamera->OrthogonalizeViewUp();
		aRenderer->ResetCameraClippingRange();
		[self setNeedsDisplay:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
	}
}

- (void)mouseUp:(NSEvent *)theEvent{
	[self deleteMouseDownTimer];
	
	if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
	
	if (_resizeFrame)
	{
		[self setNeedsDisplay:YES];
	}
	else {
		switch (_tool) {
			case tWL:
			case tWLBlended:
			case tCamera3D:
				[self setNeedsDisplay:YES];
				break;
			case tRotate:
			case t3DRotate:
			case tTranslate:
				if( volumeMapper)
				{
					volumeMapper->SetAutoAdjustSampleDistances( 1);
					volumeMapper->SetMinimumImageSampleDistance( LOD);
				}
				
				[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
				break;
			case tZoom:
				[self rightMouseUp:theEvent];
				break;
			case t3DCut:			// <- DO NOTHING !
			case tBonesRemoval:		// <- DO NOTHING !
			break;
			default:
				[self setNeedsDisplay:YES];
				break;
		}
	}
}

- (void)rightMouseUp:(NSEvent *)theEvent{
	if (_tool == tZoom)
	{
		if( volumeMapper)
		{
			volumeMapper->SetAutoAdjustSampleDistances( 1);
			volumeMapper->SetMinimumImageSampleDistance( LOD);
		}
		
		if( projectionMode != 2)
		{
			[self computeLength];
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
		}
		else
		{
			[self setNeedsDisplay:YES];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL		keepOn = YES;
    NSPoint		mouseLoc, mouseLocPre;
	short		tool;
	
	[cursor set];
	
	noWaitDialog = YES;
	tool = currentTool;
		
	if ([theEvent type] == NSLeftMouseDown) {
		if (_mouseDownTimer) {
			[self deleteMouseDownTimer];
		}
		
		_mouseDownTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self   selector:@selector(startDrag:) userInfo:theEvent  repeats:NO] retain];
	}
	
	mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: 0L];
	
	if( [theEvent clickCount] > 1 && (tool != t3Dpoint))
	{
		long	pix[ 3];
		float	pos[ 3], value;
		
		if( [self get3DPixelUnder2DPositionX:_mouseLocStart.x Y:_mouseLocStart.y pixel:pix position:pos value:&value])
		{
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: pix[0]], @"x", [NSNumber numberWithInt: pix[1]], @"y", [NSNumber numberWithInt: pix[2]], @"z",
																				0L];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"Display3DPoint" object:pixList  userInfo: dict];
		}
		
		return;
	}

	if( _mouseLocStart.x < 10 && _mouseLocStart.y < 10 && isViewportResizable)
	{
		_resizeFrame = YES;
	}
	else
	{
		_resizeFrame = NO;
		tool = [self getTool: theEvent];
		_tool = tool;
		[self setCursorForView: tool];
		
		if( tool != tWL && tool != tZoom)
		{
			rotate = NO;
			
			[self resetAutorotate: self];
		}
		
		if( tool == tMesure)
		{
			double	*pp;
			long	i;
			
			vtkPoints		*pts = Line2DData->GetPoints();
		
			if( pts->GetNumberOfPoints() >= 2)
			{
				// Delete current ROI
				pts = vtkPoints::New();
				vtkCellArray *rect = vtkCellArray::New();
				Line2DData-> SetPoints( pts);		pts->Delete();
				Line2DData-> SetLines( rect);		rect->Delete();
				
				pts = Line2DData->GetPoints();
			}
			
			// Click point 3D to 2D
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: 0L];
			
			aRenderer->SetDisplayPoint( _mouseLocStart.x, _mouseLocStart.y, 0);
			aRenderer->DisplayToWorld();
			pp = aRenderer->GetWorldPoint();
			
			// Create the 2D Actor
			
			aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
			aRenderer->WorldToDisplay();
			
			double *tempPoint = aRenderer->GetDisplayPoint();
			
			NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
			
			pts->InsertPoint( pts->GetNumberOfPoints(), tempPoint[0], tempPoint[ 1], 0);
			
			vtkCellArray *rect = vtkCellArray::New();
			rect->InsertNextCell( pts->GetNumberOfPoints()+1);
			for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
			rect->InsertCellPoint( 0);
			
			Line2DData->SetVerts( rect);
			Line2DData->SetLines( rect);		rect->Delete();
			
			Line2DData->SetPoints( pts);
			
			[self computeLength];
				
			if( ROIUPDATE == NO)
			{
				ROIUPDATE = YES;
				[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:0]; 
			}
		}
		else if( tool == t3DCut)
		{
			double	*pp;
			long	i;
			
			// Click point 3D to 2D
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: 0L];
			
			aRenderer->SetDisplayPoint( _mouseLocStart.x, _mouseLocStart.y, 0);
			aRenderer->DisplayToWorld();
			pp = aRenderer->GetWorldPoint();
			
			// Create the 2D Actor
			
			aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
			aRenderer->WorldToDisplay();
			
			double *tempPoint = aRenderer->GetDisplayPoint();
			
			NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
			
			vtkPoints *pts = ROI3DData->GetPoints();
			pts->InsertPoint( pts->GetNumberOfPoints(), tempPoint[0], tempPoint[ 1], 0);
			
			vtkCellArray *rect = vtkCellArray::New();
			rect->InsertNextCell( pts->GetNumberOfPoints()+1);
			for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
			rect->InsertCellPoint( 0);
			
			ROI3DData->SetVerts( rect);
			ROI3DData->SetLines( rect);		rect->Delete();
			
			ROI3DData->SetPoints( pts);
			
			if( ROIUPDATE == NO)
			{
				ROIUPDATE = YES;
				[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:0]; 
			}
		}
		else if( tool == tWL)
		{
			_startWW = ww;
			_startWL = wl;
			_startMin = wl - ww/2;
			_startMax = wl + ww/2;
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
		}
		else if( tool == tWLBlended)
		{
			_startWW = blendingWw;
			_startWL = blendingWl;
			_startMin = blendingWl - blendingWw/2;
			_startMax = blendingWl + blendingWw/2;
			
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
		}
		else if( tool == tRotate)
		{
			int shiftDown = 0;
			int controlDown = 1;
			
			if( volumeMapper)
			{
				volumeMapper->SetAutoAdjustSampleDistances( 0);
				volumeMapper->SetImageSampleDistance( LOD*lowResLODFactor);
			}
			
			mouseLoc = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		}
		else if( tool == t3DRotate)
		{
			int shiftDown = 0;//([theEvent modifierFlags] & NSShiftKeyMask);
			int controlDown = 0;//([theEvent modifierFlags] & NSControlKeyMask);

			if( volumeMapper)
			{
				volumeMapper->SetAutoAdjustSampleDistances( 0);
				volumeMapper->SetImageSampleDistance( LOD*lowResLODFactor);
			}
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];

		//	NSLog( @"x=%d, y=%d", (int) mouseLoc.x, (int) mouseLoc.y);
			
			//vtkActor, vtkCamera
			
//			aCamera->SetFocalPoint( outlineRect->GetCenter());
//			aCamera->ComputeViewPlaneNormal();
//			aCamera->OrthogonalizeViewUp();
	
			[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		}
		else if( tool == tTranslate)
		{
			int shiftDown = 1;
			int controlDown = 0;
			
			if( volumeMapper)
			{
				volumeMapper->SetAutoAdjustSampleDistances( 0);
				volumeMapper->SetImageSampleDistance( LOD*lowResLODFactor);
			}
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		}
		else if( tool == tZoom)
		{
			if( volumeMapper)
			{
				volumeMapper->SetAutoAdjustSampleDistances( 0);
				volumeMapper->SetImageSampleDistance( LOD*lowResLODFactor);
			}
			
			if( projectionMode != 2)
			{
				int shiftDown = 0;
				int controlDown = 1;

				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
			}
			else
			{
				// vtkCamera
				mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				
				if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
			}
		}
		else if( tool == tCamera3D)
		{
			// vtkCamera
			mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
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
  			[super keyDown:artificialPKeyDown];
			
			if (![self isAny3DPointSelected])
			{
				// add a point on the surface under the mouse click
				[self throw3DPointOnSurface: _mouseLocStart.x : _mouseLocStart.y];
				[self setNeedsDisplay:YES];
			}
			else
			{
				[point3DRadiusSlider setFloatValue: [[point3DRadiusArray objectAtIndex:[self selected3DPointIndex]] floatValue]];
				[point3DColorWell setColor: [point3DColorsArray objectAtIndex:[self selected3DPointIndex]]];
				
				if ([theEvent clickCount]==2)
				{
					NSPoint mouseLocationOnScreen = [[self window] convertBaseToScreen:[theEvent locationInWindow]];
					[point3DInfoPanel setAlphaValue:0.8];
					[point3DInfoPanel	setFrame:	NSMakeRect(	mouseLocationOnScreen.x - [point3DInfoPanel frame].size.width/2.0, 
																mouseLocationOnScreen.y-[point3DInfoPanel frame].size.height-20.0,
																[point3DInfoPanel frame].size.width,
																[point3DInfoPanel frame].size.height)
										display:YES animate:YES];
					[point3DInfoPanel orderFront:self];
					
					
					float pos[3];
					[[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:pos];
					
					int pix[3];
					pix[0] = (int)[[[[[controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]] points] objectAtIndex:0] x];
					pix[1] = (int)[[[[[controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]] points] objectAtIndex:0] y];
					pix[2] = [[[controller sliceNumber2DPointsArray] objectAtIndex:[self selected3DPointIndex]] intValue];
					
					NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: pix[0]], @"x", [NSNumber numberWithInt: pix[1]], @"y", [NSNumber numberWithInt: pix[2]], @"z",
																						0L];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"Display3DPoint" object:pixList  userInfo: dict];
					
//					NSLog(@"mouseLocationOnScreen : %f, %f", [point3DInfoPanel frame].origin.x, [point3DInfoPanel frame].origin.y);
//					NSLog(@"point3DInfoPanel position : %f, %f", mouseLocationOnScreen.x, mouseLocationOnScreen.y);
//					NSLog(@"dble click on a Point in VR view");
				}
			}
		}
		else if( tool == tBonesRemoval)
		{
			[self deleteMouseDownTimer];
			
			NSLog( @"**** Bone Removal Start");
			// enable Undo
			[controller prepareUndo];
			NSLog( @"**** Undo");
						
			// clicked point (2D coordinate)
			_mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: 0L];
			
			long	pix[ 3], i;
			float	pos[ 3], value;
	
			if( [self get3DPixelUnder2DPositionX:_mouseLocStart.x Y:_mouseLocStart.y pixel:pix position:pos value:&value maxOpacity: BONEOPACITY minValue: BONEVALUE])
			{
				WaitRendering	*waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Applying Bone Removal...", nil)];
				[waiting showWindow:self];

				NSLog( @"**** Bone Raycast");

				NSPoint seedPoint;
				seedPoint.x = pix[ 0];
				seedPoint.y = pix[ 1];
				
				long seed[ 3];
				
				seed[ 0] = (long) seedPoint.x;
				seed[ 1] = (long) seedPoint.y;
				seed[ 2] = pix[ 2];
				
				NSArray	*roiList =	[ITKSegmentation3D fastGrowingRegionWithVolume:		data
																						width:		[[pixList objectAtIndex: 0] pwidth]
																						height:		[[pixList objectAtIndex: 0] pheight]
																						depth:		[pixList count]
																						seedPoint:	seed
																						from:		BONEVALUE
																						pixList:	pixList];
				
				// Dilatation
				
				[[controller viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"dilate" radius: 10 sendNotification:NO];
				[[controller viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"erode" radius: 6 sendNotification:NO];
				
				BOOL addition = NO;
				
				// Bone Removal
				NSNumber		*nsnewValue	= [NSNumber numberWithFloat: -1000];		//-1000
				NSNumber		*nsminValue	= [NSNumber numberWithFloat: -99999];		//-99999
				NSNumber		*nsmaxValue	= [NSNumber numberWithFloat: 99999];
				NSNumber		*nsoutside	= [NSNumber numberWithBool: NO];
				NSNumber		*nsaddition	= [NSNumber numberWithBool: addition];
				NSMutableArray	*roiToProceed = [NSMutableArray array];
				
				for( i = 0 ; i < [roiList count]; i++)
				{
					NSDictionary	*rr = [roiList objectAtIndex: i];
				
					[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [rr objectForKey:@"roi"], @"roi", [rr objectForKey:@"curPix"], @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsaddition, @"addition", 0L]];
				}
				
				[[controller viewer2D] roiSetStartScheduler: roiToProceed];
				
				NSLog( @"**** Set Pixels");
				
				// Update 3D image
				if( textureMapper) 
				{
					// Force min/max recomputing
					[self movieChangeSource: data];
					//reader->Modified();
				}
				else
				{
					if( isRGB == NO)
						vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
				}
				[self setNeedsDisplay:YES];
				
				[waiting close];
				[waiting release];
			}
		}
		else [super mouseDown:theEvent];
		
		croppingBox->SetHandleSize( 0.005);
	}
	noWaitDialog = NO;
}

- (void) deleteRegion:(int) c :(NSArray*) pxList :(BOOL) blendedSeries
{
	long			tt, stackMax, stackOrientation, i;
	vtkPoints		*roiPts = ROI3DData->GetPoints();
	NSMutableArray	*ROIList = [NSMutableArray arrayWithCapacity:0];
	double			xyz[ 3], cameraProj[ 3], cameraProjObj[ 3];
	float			vector[ 9];
	DCMPix			*fObject = [pxList objectAtIndex: 0];

	NSLog(@"Scissor Start");
//			[[[self window] windowController] prepareUndo];
	[controller prepareUndo];
	
	vtkMatrix4x4 *ActorMatrix;
	
	if( blendedSeries)  ActorMatrix = blendingVolume->GetUserMatrix();
	else ActorMatrix = volume->GetUserMatrix();
	
	vtkTransform *Transform = vtkTransform::New();
	
	Transform->SetMatrix( ActorMatrix);
	Transform->Push();
	
	aCamera->GetViewPlaneNormal( cameraProj);
	aCamera->GetPosition( xyz);
	
	if( blendedSeries)
	{
		xyz[ 0] /= blendingFactor;
		xyz[ 1] /= blendingFactor;
		xyz[ 2] /= blendingFactor;
	}
	else
	{
		xyz[ 0] /= factor;
		xyz[ 1] /= factor;
		xyz[ 2] /= factor;
	}
	[fObject orientation: vector];
	
	cameraProjObj[ 0] = cameraProj[ 0] * vector[ 0] + cameraProj[ 1] * vector[ 1] + cameraProj[ 2] * vector[ 2];
	cameraProjObj[ 1] = cameraProj[ 0] * vector[ 3] + cameraProj[ 1] * vector[ 4] + cameraProj[ 2] * vector[ 5];
	cameraProjObj[ 2] = cameraProj[ 0] * vector[ 6] + cameraProj[ 1] * vector[ 7] + cameraProj[ 2] * vector[ 8];
				
	if( fabs( cameraProjObj[ 0]) > fabs(cameraProjObj[ 1]) && fabs(cameraProjObj[ 0]) > fabs(cameraProjObj[ 2]))
	{
		NSLog(@"X Stack");
		stackOrientation = 0;
	}
	else if( fabs(cameraProjObj[ 1]) > fabs(cameraProjObj[ 0]) && fabs(cameraProjObj[ 1]) > fabs(cameraProjObj[ 2]))
	{
		NSLog(@"Y Stack");
		stackOrientation = 1;
	}
	else
	{
		NSLog(@"Z Stack");
		stackOrientation = 2;
	}
	
	switch( stackOrientation)
	{
		case 0:		stackMax = [fObject pwidth];		break;
		case 1:		stackMax = [fObject pheight];		break;
		case 2:		stackMax = [pxList count];				break;
	}
	
	for( i = 0 ; i < stackMax ; i++)
		[ROIList addObject: [[[ROI alloc] initWithType: tCPolygon :[fObject pixelSpacingX]*factor :[fObject pixelSpacingY]*factor :NSMakePoint( [fObject originX], [fObject originY])] autorelease]];
		
	for( tt = 0; tt < roiPts->GetNumberOfPoints(); tt++)
	{
		float	point1[ 3], point2[ 3];
		long	x, y, z;
		
		double	point2D[ 3], *pp;
		
		roiPts->GetPoint( tt, point2D);
		aRenderer->SetDisplayPoint( point2D[ 0], point2D[ 1], 0);
		aRenderer->DisplayToWorld();
		pp = aRenderer->GetWorldPoint();
		
		if( blendedSeries)
		{
			pp[ 0] /= blendingFactor;
			pp[ 1] /= blendingFactor;
			pp[ 2] /= blendingFactor;
		}
		else
		{
			pp[ 0] /= factor;
			pp[ 1] /= factor;
			pp[ 2] /= factor;
		}
		
	//	NSLog(@"point: %f %f %f", pp[ 0], pp[ 1], pp[ 2]);
		
		if( aCamera->GetParallelProjection())
		{
			NSLog(@"Cam Proj: %f %f %f",cameraProj[ 0], cameraProj[ 1], cameraProj[ 2]);
			
			aCamera->GetPosition( xyz);
			
			xyz[ 0] = pp[0] + cameraProj[ 0];
			xyz[ 1] = pp[1] + cameraProj[ 1];
			xyz[ 2] = pp[2] + cameraProj[ 2];
							
			// Go beyond the object...
							
			pp[0] = xyz[ 0] + (pp[0] - xyz[ 0]) * 5000.;
			pp[1] = xyz[ 1] + (pp[1] - xyz[ 1]) * 5000.;
			pp[2] = xyz[ 2] + (pp[2] - xyz[ 2]) * 5000.;
			
			point1[ 0] = xyz[ 0];
			point1[ 1] = xyz[ 1];
			point1[ 2] = xyz[ 2];
					
			point2[ 0] = pp[ 0];
			point2[ 1] = pp[ 1];
			point2[ 2] = pp[ 2];
		}
		else
		{
			// Go beyond the object...
			
			point1[ 0] = xyz[ 0];
			point1[ 1] = xyz[ 1];
			point1[ 2] = xyz[ 2];
		
			point2[0] = xyz[ 0] + (pp[0] - xyz[ 0])*5000.;
			point2[1] = xyz[ 1] + (pp[1] - xyz[ 1])*5000.;
			point2[2] = xyz[ 2] + (pp[2] - xyz[ 2])*5000.;		
		}
		
//		NSLog( @"Start Pt : x=%f, y=%f, z=%f"	, point1[ 0], point1[ 1], point1[ 2]);
//		NSLog( @"End Pt : x=%f, y=%f, z=%f"		, point2[ 0], point2[ 1], point2[ 2]);
					
		// Intersection between this line and planes in Z direction
		for( x = 0; x < stackMax; x++)
		{
			float	planeVector[ 3];
			float	point[ 3];
			float	resultPt[ 3];
			double	vPos[ 3];
			
			if( blendedSeries)  blendingVolume->GetPosition( vPos);
			else volume->GetPosition( vPos);
	
			 // factor
			
			if( blendedSeries)
			{
				vPos[ 0] /= blendingFactor;
				vPos[ 1] /= blendingFactor;
				vPos[ 2] /= blendingFactor;
			}
			else
			{
				vPos[ 0] /= factor;
				vPos[ 1] /= factor;
				vPos[ 2] /= factor;
			}
			
//			vPos[ 0] = [fObject originX];
//			vPos[ 1] = [fObject originY];
//			vPos[ 2] = [fObject originZ];
			
			switch( stackOrientation)
			{
				case 0:
					point[ 0] = x * [fObject pixelSpacingX];
					point[ 1] = 0;
					point[ 2] = 0;
												
					planeVector[ 0] =  vector[ 0];
					planeVector[ 1] =  vector[ 1];
					planeVector[ 2] =  vector[ 2];
				break;
				
				case 1:
					point[ 0] = 0;
					point[ 1] = x * [fObject pixelSpacingY];
					point[ 2] = 0;
					
					planeVector[ 0] =  vector[ 3];
					planeVector[ 1] =  vector[ 4];
					planeVector[ 2] =  vector[ 5];
				break;
				
				case 2:
					point[ 0] = 0;
					point[ 1] = 0;
			//		point[ 2] = x * fabs( [fObject sliceInterval]);
					point[ 2] = x * ( [fObject sliceInterval]);
					
					planeVector[ 0] =  vector[ 6];
					planeVector[ 1] =  vector[ 7];
					planeVector[ 2] =  vector[ 8];
				break;
			}
			
			point[ 0] += vPos[ 0];
			point[ 1] += vPos[ 1];
			point[ 2] += vPos[ 2];
			
			Transform->TransformPoint(point,point);
			
			if( intersect3D_SegmentPlane( point2, point1, planeVector, point, resultPt ))
			{
				float	tempPoint3D[ 3];
				long	ptInt[ 3];
				long	roiID;
				// Convert this 3D point to 2D point projected in the plane
				
				Transform->Inverse();
				Transform->TransformPoint(resultPt,tempPoint3D);
				Transform->Inverse();
				
				tempPoint3D[ 0] -= vPos[ 0];
				tempPoint3D[ 1] -= vPos[ 1];
				tempPoint3D[ 2] -= vPos[ 2];
				
				tempPoint3D[0] /= [fObject pixelSpacingX];
				tempPoint3D[1] /= [fObject pixelSpacingY];
			//	tempPoint3D[2] /= fabs( [fObject sliceInterval]);
				tempPoint3D[2] /= ( [fObject sliceInterval]);
				
			//	tempPoint3D[0] /= factor;
			//	tempPoint3D[1] /= factor;
			//	tempPoint3D[2] /= factor;
				
				ptInt[ 0] = (long) (tempPoint3D[0] + 0.5);
				ptInt[ 1] = (long) (tempPoint3D[1] + 0.5);
				ptInt[ 2] = (long) (tempPoint3D[2] + 0.5);
				
				
				if( needToFlip) 
				{
					ptInt[ 2] = [pxList count] - ptInt[ 2] -1;
				}
				
//						if( ptInt[0] >= 0 && ptInt[0] < [fObject pwidth] && ptInt[1] >= 0 && ptInt[1] < [fObject pheight] &&  ptInt[ 2] >= 0 && ptInt[ 2] < [pxList count])
//						{						
//							// Test delete...
//							
//							float *src = [[pxList objectAtIndex: ptInt[ 2]] fImage];
//							*(src + (long) ptInt[1] * [fObject pwidth] + (long) ptInt[0]) = 10000;
//						}
				
				switch( stackOrientation)
				{
					case 0:	
						roiID = ptInt[0];
						
						if( roiID >= 0 && roiID < stackMax)
							[[[ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[1], ptInt[2])]];
					break;
					
					case 1:
						roiID = ptInt[1];
						
						if( roiID >= 0 && roiID < stackMax)
							[[[ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[2])]];
					break;
					
					case 2:
						roiID = ptInt[2];
						
						if( roiID >= 0 && roiID < stackMax)
							[[[ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[1])]];
					break;
				}
//				NSLog(@"Slide ID: %d", roiID);
			}
		}
	}
	
	Transform->Delete();
	
	[[pixList objectAtIndex: 0] prepareRestore];
	
	BOOL	addition = NO;
	float	newVal = 0;
	
	if( c == NSDeleteCharacter)
	{
		if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
		{
			addition = YES;
			gDataValuesChanged = YES;
			
			newVal = 1024;
		}
		
		if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
		{
			addition = YES;
			gDataValuesChanged = YES;
			
			newVal = -1024;
		}
	}
	
	if( c == NSTabCharacter)
	{
		gDataValuesChanged = YES;
	}
	
	// Create a scheduler
	id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
	[sched setDelegate: self];
	
	// Create the work units. These can be anything. We will use NSNumbers
	NSMutableSet *unitsSet = [NSMutableSet set];
	for ( i = 0; i < stackMax; i++ )
	{
		[unitsSet addObject: [NSArray arrayWithObjects: [NSNumber numberWithInt:i], [NSNumber numberWithInt:stackOrientation], [NSNumber numberWithInt: c], [ROIList objectAtIndex: i], [NSNumber numberWithInt: blendedSeries], [NSNumber numberWithBool: addition], [NSNumber numberWithFloat: newVal], 0L]];
	}
	// Perform work schedule
	[sched performScheduleForWorkUnits:unitsSet];
	
	// Delete current ROI
	vtkPoints *pts = vtkPoints::New();
	vtkCellArray *rect = vtkCellArray::New();
	ROI3DData-> SetPoints( pts);		pts->Delete();
	ROI3DData-> SetLines( rect);		rect->Delete();
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
    
	if( c == NSTabCharacter)
	{
		NSLog( @"tab key");
	}
	
	if( c == ' ')
	{
		if( [[[self window] windowController] isKindOfClass:[VRController class]]) rotate = !rotate;
	}
	
	if( c == 't')
	{
		NSDate	*now = [NSDate date];
	
		NSLog( @"360 degree rotation - 100 images - START");
		int i;
		
		for( i = 0 ; i < 100; i++)
		{
			[self Azimuth: 360. / 100.];
			[self display];
		}
		NSLog( @"360 degree rotation - 100 images - END");
		NSLog( @"360 degree rotation - Result in [s]: %f", -[now timeIntervalSinceNow]);
		
		[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Performance Test", 0L) description: [NSString stringWithFormat: NSLocalizedString(@"360 degree rotation - 100 images\rResult in [s] : %f", 0L), -[now timeIntervalSinceNow]] name:@"result"];
	}
	
	if( c == 27)
	{
//		[[[self window] windowController] offFullScreen];
		[controller offFullScreen];
	}
	
	if( (c == 27) && currentTool == t3DCut)
	{
		vtkPoints		*roiPts = ROI3DData->GetPoints();
		
		if( roiPts->GetNumberOfPoints() != 0)
		{
			// Delete current ROI
			vtkPoints *pts = vtkPoints::New();
			vtkCellArray *rect = vtkCellArray::New();
			ROI3DData-> SetPoints( pts);		pts->Delete();
			ROI3DData-> SetLines( rect);		rect->Delete();
			
			[self setNeedsDisplay:YES];
		}
	}
	
	if( c == NSDeleteCharacter && currentTool == tMesure)
	{
		vtkPoints		*pts = ROI3DData->GetPoints();
		
		if( pts->GetNumberOfPoints() != 0)
		{
			// Delete current ROI
			vtkPoints *pts = vtkPoints::New();
			vtkCellArray *rect = vtkCellArray::New();
			ROI3DData-> SetPoints( pts);		pts->Delete();
			ROI3DData-> SetLines( rect);		rect->Delete();
			[self setNeedsDisplay:YES];
		}
	}
	
	if( (c == NSCarriageReturnCharacter || c == NSEnterCharacter || c == NSDeleteCharacter || c == NSTabCharacter) && currentTool == t3DCut)
	{
		vtkPoints		*roiPts = ROI3DData->GetPoints();
		
		if( roiPts->GetNumberOfPoints() < 3)
		{
			NSRunAlertPanel(NSLocalizedString(@"3D Cut", nil), NSLocalizedString(@"Draw an ROI on the 3D image and then press Return (include) or Delete (exclude) keys.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
		else if( c == NSTabCharacter && [[controller viewer2D] postprocessed] == YES)
		{
			NSRunAlertPanel(NSLocalizedString(@"Restore", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot restore it.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
		else
		{
			WaitRendering	*waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Applying Scissor...", nil)];
			[waiting showWindow:self];
			
			if( [deleteRegion tryLock])
			{
				[self deleteRegion: c :pixList :NO];
			}
			
//			if( blendingController)
//			{
//				[self deleteRegion: c :blendingPixList :YES];
//			}
			
			[waiting close];
			[waiting release];
		}
	}
	
	if((c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter) && currentTool == t3Dpoint)
	{
		if([self isAny3DPointSelected])
		{
			[self removeSelected3DPoint];
		}
	}
	
	if( [self actionForHotKey:[event characters]] == NO) [super keyDown:event];
}

-(void) schedulerDidFinishSchedule: (Scheduler *)scheduler
{
	NSLog(@"Scissor End");
	
	// Update everything..
	ROIUPDATE = NO;
	//[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList userInfo: 0];	<- This is slow
	
	cropcallback->Execute(croppingBox, 0, 0L);
	
	[scheduler release];
	
	if( textureMapper || gDataValuesChanged)
	{
		[self computeValueFactor];
		// Force min/max recomputing
		[self movieChangeSource: data];
		
		gDataValuesChanged = NO;
	}
	else
	{
		if( isRGB == NO)
			vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
	}
	
	[[pixList objectAtIndex: 0] freeRestore];
	
	[self setNeedsDisplay:YES];
	
	[deleteRegion unlock];
	
	if(clutOpacityView)
	{
		[clutOpacityView computeHistogram];
		[clutOpacityView updateView];
	}
}

-(void)performWorkUnits:(NSSet *)workUnits forScheduler:(Scheduler *)scheduler
{
	NSEnumerator *enumerator = [workUnits objectEnumerator];
	NSArray	*object;
	
	while (object = [enumerator nextObject])
	{
		[controller applyScissor :object];
	}
}

- (IBAction) undo:(id) sender
{
	[controller undo: sender];
}

- (void) setCurrentTool:(short) i
{
	long previousTool = currentTool;
	
    currentTool = i;
	
	if( currentTool != t3DRotate)
	{
		if( croppingBox->GetEnabled()) croppingBox->Off();
	}
	
	if( currentTool == tMesure || previousTool == tMesure)
	{
		vtkPoints		*pts = Line2DData->GetPoints();
		
		if( pts->GetNumberOfPoints() != 0)
		{
			// Delete current ROI
			vtkPoints *pts = vtkPoints::New();
			vtkCellArray *rect = vtkCellArray::New();
			Line2DData-> SetPoints( pts);		pts->Delete();
			Line2DData-> SetLines( rect);		rect->Delete();
			aRenderer->RemoveActor( Line2DText);
			
			[self setNeedsDisplay:YES];
		}
	}
	
	if( (currentTool == t3DCut && previousTool == t3DCut) || currentTool != t3DCut)
	{
		vtkPoints		*roiPts = ROI3DData->GetPoints();
		
		if( roiPts->GetNumberOfPoints() != 0)
		{
			// Delete current ROI
			vtkPoints *pts = vtkPoints::New();
			vtkCellArray *rect = vtkCellArray::New();
			ROI3DData-> SetPoints( pts);		pts->Delete();
			ROI3DData-> SetLines( rect);		rect->Delete();
			
			[self setNeedsDisplay:YES];
		}
	}
	
	if(currentTool!=t3Dpoint && previousTool==t3Dpoint)
	{
		[self unselectAllActors];
		if ([point3DInfoPanel isVisible]) [point3DInfoPanel performClose:self];
		[self setNeedsDisplay:YES];
	}
	
	[self setCursorForView: currentTool];
}

- (void) getWLWW:(float*) iwl :(float*) iww
{
    *iwl = wl;
    *iww = ww;
}

-(void) setBlendingWLWW:(float) iwl :(float) iww
{
	if( blendingController == 0L) return;

    double newValues[2];
    
	blendingWl = iwl;
	blendingWw = iww;
	
//	vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);
//	if( blendingNeedToFlip)
//	{
//		[self flipData: (char*) blendingDst8.data :[blendingPixList count] :[blendingFirstObject pheight] * [blendingFirstObject pwidth]];
//	}
//	if( blendingFlip)
//	{
//		blendingFlip->Delete();
//		
//		blendingFlip = vtkImageFlip::New();
//		blendingFlip->SetInput( reader->GetOutput());
//		blendingFlip->SetFlipAboutOrigin( TRUE);
//		blendingFlip->SetFilteredAxis(2);
//		
//		if( blendingVolumeMapper) blendingVolumeMapper->SetInput((vtkDataSet *) blendingFlip->GetOutput());
//		if( blendingTextureMapper) blendingTextureMapper->SetInput((vtkDataSet *) blendingFlip->GetOutput());
//	}
	
	blendingOpacityTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &alpha);
	blendingColorTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &blendingtable);
	
    [self setNeedsDisplay:YES];
}

-(void) setBlendingFactor:(float) a
{
	long	i, blendMode;
	float   val, ii;
	
	
	if( blendingController)
	{
		if( volumeMapper) blendMode = volumeMapper->GetBlendMode();
		if( textureMapper) blendMode = textureMapper->GetBlendMode();
		
		blendingFactor = a;
		
		if( blendMode == vtkVolumeMapper::MAXIMUM_INTENSITY_BLEND)
		{
			a *= 2;
			
			for(i=0; i < 256; i++) 
			{
				ii = i;
				val = (a * ii) / 256.;
				
				if( val > 255) val = 255;
				if( val < 0) val = 0;
				
				alpha[ i] = val / 255.0;
			}
		}
		else
		{
			a /= 3;
			
			for(i=0; i < 256; i++) 
			{
				ii = i;
				val = (a * ii) / 256.;
				val -= 8.;
				
				if( val > 255) val = 255;
				if( val < 0) val = 0;
				
				alpha[ i] = val / 255.;
			}
		}
		blendingOpacityTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &alpha);
		
		[self setNeedsDisplay: YES];
	}
}

-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long	i;
	
	if( blendingController)
	{
		if( r)
		{
			for( i = 0; i < 256; i++)
			{
				blendingtable[i][0] = r[i] / 255.;
				blendingtable[i][1] = g[i] / 255.;
				blendingtable[i][2] = b[i] / 255.;
			}
			blendingColorTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &blendingtable);
		}
		else
		{
			for( i = 0; i < 256; i++)
			{
				blendingtable[i][0] = i / 255.;
				blendingtable[i][1] = i / 255.;
				blendingtable[i][2] = i / 255.;
			}
			blendingColorTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &blendingtable);
		}
		
		[self setNeedsDisplay:YES];
	}
}

-(void) setOpacity:(NSArray*) array
{
	long		i;
	NSPoint		pt;
	float		start, end;
	
	if( isRGB)
	{
		start = wl - ww/2;
		end = wl + ww/2;
	}
	else
	{
		start = valueFactor*(OFFSET16 + wl - ww/2);
		end = valueFactor*(OFFSET16 + wl + ww/2);
	}
	
	if( currentOpacityArray != array)
	{
		[currentOpacityArray release];
		currentOpacityArray = [array retain];
	}
	
	opacityTransferFunction->RemoveAllPoints();
	
	if( [array count] > 0)
	{
		pt = NSPointFromString( [array objectAtIndex: 0]);
		pt.x -=1000;
		if(pt.x != 0) opacityTransferFunction->AddPoint(0 +start, 0);
//		else NSLog(@"start point");
	}
	else opacityTransferFunction->AddPoint(0 +start, 0);
	
	for( i = 0; i < [array count]; i++)
	{
		pt = NSPointFromString( [array objectAtIndex: i]);
		pt.x -= 1000;
		opacityTransferFunction->AddPoint(start + (pt.x / 256.0) * (end - start), pt.y);
	}
	
	if( [array count] == 0 || pt.x != 256) opacityTransferFunction->AddPoint(end, 1);
	else
	{
		opacityTransferFunction->AddPoint(end, pt.y);
		//NSLog(@"end point");
	}
	[self setNeedsDisplay:YES];
}

-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	advancedCLUT = NO;
	if(appliedCurves)
	{
		[appliedCurves release];
		appliedCurves = nil;
	}
	
	long	i;

	if( isRGB)
	{
		if( r)
		{
			for( i = 0; i < 256; i++)
			{
				table[i][0] = r[i] / 255.;
				table[i][1] = g[i] / 255.;
				table[i][2] = b[i] / 255.;
			}
			
			colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
			
			volumeProperty->SetColor( 1, colorTransferFunction);
			volumeProperty->SetColor( 2, colorTransferFunction);
			volumeProperty->SetColor( 3, colorTransferFunction);
		}
		else
		{
			volumeProperty->SetColor( 1,red);
			volumeProperty->SetColor( 2,green);
			volumeProperty->SetColor( 3,blue);
		}
	}
	else
	{
		if( r)
		{
			for( i = 0; i < 256; i++)
			{
				table[i][0] = r[i] / 255.;
				table[i][1] = g[i] / 255.;
				table[i][2] = b[i] / 255.;
			}
			
			colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
		}
		else
		{
			for( i = 0; i < 256; i++)
			{
				table[i][0] = i / 255.;
				table[i][1] = i / 255.;
				table[i][2] = i / 255.;
			}
			
			colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
		}
	}
	
    [self setNeedsDisplay:YES];
}

- (void) setWLWW:(float) iwl :(float) iww
{
	if( iwl == 0 && iww == 0)
	{
		iwl = [[pixList objectAtIndex:0] fullwl];
		
		if( [controller maximumValue])
		{
			iwl = [controller maximumValue] /2;
			iww = [controller maximumValue];
		}
		else
			iww = [[pixList objectAtIndex:0] fullww];
	}
	
	wl = iwl;
	ww = iww;
	
	if(advancedCLUT)
	{
		[clutOpacityView setWL:wl ww:ww];
		[clutOpacityView setCLUTtoVRView:YES];
	}
	else
		[self setOpacity: currentOpacityArray];
	
	if( isRGB)
		colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
	else if(!advancedCLUT)
		colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
	
//	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
//	if( needToFlip)
//	{
//		[self flipData: (char*) dst8.data :[pixList count] :[firstObject pheight] * [firstObject pwidth]];
//	}
	
//	if( flip)
//	{
//		flip->Delete();
//		
//		flip = vtkImageFlip::New();
//		flip->SetInput( reader->GetOutput());
//		flip->SetFlipAboutOrigin( TRUE);
//		flip->SetFilteredAxis(2);
//		
//		outlineData->SetInput((vtkDataSet *) flip->GetOutput());
//		if( volumeMapper) volumeMapper->SetInput((vtkDataSet *) flip->GetOutput());
//		if( textureMapper) textureMapper->SetInput((vtkDataSet *) flip->GetOutput());
//	}
	
	if( [[[controller viewer2D] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller viewer2D] modality] isEqualToString:@"NM"] == YES))
	{
		if( ww < 50) sprintf(WLWWString, "From: %0.4f   To: %0.4f", wl-ww/2, wl+ww/2);
		else sprintf(WLWWString, "From: %0.f   To: %0.f", wl-ww/2, wl+ww/2);
	}
	else
	{
		if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f", wl, ww);
		else sprintf(WLWWString, "WL: %0.f WW: %0.f", wl, ww);
	}
	textWLWW->SetInput( WLWWString);
	
	[self setNeedsDisplay:YES];
}

- (void) endRenderImageWithBestQuality
{
	// Standard Rendering...
	
	if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
	if( volumeMapper) volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
	
	if( blendingController)
	{
		if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		if( blendingVolumeMapper) blendingVolumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
	}
	
//	aRenderer->AddActor(outlineRect);
	aRenderer->AddActor(textX);
	
	[splash setCancel:NO];
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] == 2)
	{
		volume->SetMapper(textureMapper);
	}
	
	if( [splash aborted]) [self display];
}

- (void) renderImageWithBestQuality: (BOOL) best waitDialog: (BOOL) wait
{
	[splash setCancel:YES];
		
	// REMOVE CROPPING BOX
	
	if( croppingBox->GetEnabled()) croppingBox->Off();
	aRenderer->RemoveActor(outlineRect);
	aRenderer->RemoveActor(textX);
	
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
					[VRView setCroppingBox: a :volume];
					
					[VRView getCroppingBox: a :blendingVolume :croppingBox];
					[VRView setCroppingBox: a :blendingVolume];
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
	
	if( wait == NO) noWaitDialog = YES;
	
	[self display];
	
	if( wait == NO) noWaitDialog = NO;
}

-(void) bestRendering:(id) sender
{
	NSLog( @"start Best");
	[self renderImageWithBestQuality: YES waitDialog: YES];
	[self endRenderImageWithBestQuality];
	NSLog( @"end Best");
}

-(void) axView:(id) sender
{
	float distance = aCamera->GetDistance();
	float pp = aCamera->GetParallelScale();

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();

	croppingBox->SetHandleSize( 0.005);
	[self setNeedsDisplay:YES];
}

-(void) saView:(id) sender
{
	float distance = aCamera->GetDistance();
	float pp = aCamera->GetParallelScale();
	
	//vtkCamera
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (1, 0, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();
	
	croppingBox->SetHandleSize( 0.005);
	[self setNeedsDisplay:YES];
}

-(void) saViewOpposite:(id) sender
{
	float distance = aCamera->GetDistance();
	float pp = aCamera->GetParallelScale();

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (-1, 0, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();
	
	croppingBox->SetHandleSize( 0.005);
	[self setNeedsDisplay:YES];
}

-(void) coView:(id) sender
{
	float distance = aCamera->GetDistance();
	float pp = aCamera->GetParallelScale();

	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, -1, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();

	// Apply the same zoom
	
	double vn[ 3], center[ 3];
	aCamera->GetFocalPoint(center);
	aCamera->GetViewPlaneNormal(vn);
	aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
	aCamera->SetParallelScale( pp);
	aRenderer->ResetCameraClippingRange();

	croppingBox->SetHandleSize( 0.005);
	[self setNeedsDisplay:YES];
}

-(void) setLOD:(float) f
{
	if( f != LOD)
	{
		LOD = f;
		
		#if __ppc__
		LOD += 0.5;
		#else
		LOD += 0.2;
		#endif
		
		if( LOD < 1.5) LOD = 1.5;
		
		if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
		if( volumeMapper) volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
		if( volumeMapper) volumeMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
		
		[self setNeedsDisplay:YES];
	}
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

		float blendingSliceThickness = [blendingFirstObject sliceInterval];
		
		if( blendingSliceThickness == 0)
		{
			NSLog(@"Blending slice interval = slice thickness!");
			blendingSliceThickness = [blendingFirstObject sliceThickness];
		}
		NSLog(@"slice: %0.2f", blendingSliceThickness);

		// PLAN 
		[blendingFirstObject orientation:blendingcosines];
				
//		if( blendingcosines[6] + blendingcosines[7] + blendingcosines[8] < 0 && cosines[6] + cosines[7] + cosines[8] > 0)
//		{
//			NSLog(@"Oposite Vector!");
//			blendingSliceThickness = -blendingSliceThickness;
//		}
//		
//		if( blendingcosines[6] + blendingcosines[7] + blendingcosines[8] > 0 && cosines[6] + cosines[7] + cosines[8] < 0)
//		{
//			NSLog(@"Oposite Vector!");
//			blendingSliceThickness = -blendingSliceThickness;
//		}
		
		// Convert float to char
		
//		blendingSrcf.height = [blendingFirstObject pheight] * [blendingPixList count];
//		blendingSrcf.width = [blendingFirstObject pwidth];
//		blendingSrcf.rowBytes = [blendingFirstObject pwidth] * sizeof(float);
//		
//		blendingDst8.height = [blendingFirstObject pheight] * [blendingPixList count];
//		blendingDst8.width = [blendingFirstObject pwidth];
//		blendingDst8.rowBytes = [blendingFirstObject pwidth] * sizeof(char);
//		
//		blendingData8 = (char*) malloc( blendingDst8.height * blendingDst8.width * sizeof(char));
//		
//		blendingDst8.data = blendingData8;
//		blendingSrcf.data = blendingData;
		
		isBlendingRGB = NO;
		if( [blendingFirstObject isRGB])
		{
			isBlendingRGB = YES;
		}
		else
		{
			// Convert float to short !!!
			blendingSrcf.height = [blendingFirstObject pheight] * [blendingPixList count];
			blendingSrcf.width = [blendingFirstObject pwidth];
			blendingSrcf.rowBytes = [blendingFirstObject pwidth] * sizeof(float);
			
			blendingDst8.height = [blendingFirstObject pheight] * [blendingPixList count];
			blendingDst8.width = [blendingFirstObject pwidth];
			blendingDst8.rowBytes = [blendingFirstObject pwidth] * sizeof(short);
			
			blendingData8 = (char*) malloc( blendingDst8.height * blendingDst8.width * sizeof(short));
			if( blendingData8 == 0L)
			{
				[blendingPixList release];
				blendingController = 0L;
				return;
			}
			
			blendingDst8.data = blendingData8;
			blendingSrcf.data = blendingData;
			
			if( [blendingFirstObject SUVConverted])
			{
				blendingValueFactor = 4095. / [controller blendingMaximumValue];
				blendingOFFSET16 = 0;
				
				vImageConvert_FTo16U( &blendingSrcf, &blendingDst8, -blendingOFFSET16, 1./blendingValueFactor, 0);
			}
			else
			{
				if( [controller blendingMaximumValue] - [controller blendingMinimumValue] > 4095 ||  [controller blendingMaximumValue] - [controller blendingMinimumValue] < 50)
				{
					blendingValueFactor = 4095. / ( [controller blendingMaximumValue] - [controller blendingMinimumValue]);
					blendingOFFSET16 = -[controller blendingMinimumValue];
				
					vImageConvert_FTo16U( &blendingSrcf, &blendingDst8, -blendingOFFSET16, 1./blendingValueFactor, 0);
				}
				else
				{
					blendingValueFactor = 1;
					vImageConvert_FTo16U( &blendingSrcf, &blendingDst8, -blendingOFFSET16, 1./blendingValueFactor, 0);
				}
			}
		}
		
		blendingWl = [blendingFirstObject wl];
		blendingWw = [blendingFirstObject ww];
		
//		vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);

		
		blendingReader = vtkImageImport::New();
		blendingReader->SetWholeExtent(0, [blendingFirstObject pwidth]-1, 0, [blendingFirstObject pheight]-1, 0, [blendingPixList count]-1);
		blendingReader->SetDataExtentToWholeExtent();
		
		if( isBlendingRGB)
		{
			blendingReader->SetDataScalarTypeToUnsignedChar();
			blendingReader->SetNumberOfScalarComponents( 4);
			blendingReader->SetImportVoidPointer( blendingData );					//AVOID VTK BUG
		}
		else 
		{
//			blendingReader->SetNumberOfScalarComponents( 1);
//			blendingReader->SetDataScalarTypeToFloat();
//			blendingReader->SetImportVoidPointer( blendingData );					//AVOID VTK BUG
			blendingReader->SetNumberOfScalarComponents( 1);
			blendingReader->SetDataScalarTypeToUnsignedShort();
			blendingReader->SetImportVoidPointer( blendingData8 );					//AVOID VTK BUG
		}
		
		blendingNeedToFlip = NO;
		if( blendingSliceThickness < 0 )
		{
			NSLog(@"ERROR : NEED TO FLIP....");
		}
		
		blendingReader->SetDataSpacing( factor*[blendingFirstObject pixelSpacingX], factor*[blendingFirstObject pixelSpacingY], factor*blendingSliceThickness);
		
		blendingColorTransferFunction = vtkColorTransferFunction::New();
		
		
		blendingOpacityTransferFunction = vtkPiecewiseFunction::New();
		[self setBlendingFactor:blendingFactor];
		
		blendingVolumeProperty = vtkVolumeProperty::New();
		
		if( isBlendingRGB)
		{
			blendingVolumeProperty->IndependentComponentsOn();
			
			blendingVolumeProperty->SetColor( 1,red);
			blendingVolumeProperty->SetColor( 2,green);
			blendingVolumeProperty->SetColor( 3,blue);
			
			blendingVolumeProperty->SetScalarOpacity( 1, blendingOpacityTransferFunction);
			blendingVolumeProperty->SetScalarOpacity( 2, blendingOpacityTransferFunction);
			blendingVolumeProperty->SetScalarOpacity( 3, blendingOpacityTransferFunction);
			
			blendingVolumeProperty->SetComponentWeight( 0, 0);
			
		}
		else
		{
			blendingVolumeProperty->SetColor( blendingColorTransferFunction);	//	if( isRGB == NO) 
			blendingVolumeProperty->SetScalarOpacity( blendingOpacityTransferFunction);
		}
		
		[self setBlendingCLUT:0L :0L :0L];

		blendingVolumeProperty->SetInterpolationTypeToLinear();
		
	//	vtkVolumeRayCastCompositeFunction  *compositeFunction = vtkVolumeRayCastCompositeFunction::New();
		blendingCompositeFunction = vtkVolumeRayCastCompositeFunction::New();
		
//		blendingVolumeMapper = vtkVolumeRayCastMapper::New();		//vtkVolumeRayCastMapper
//		blendingVolumeMapper->SetVolumeRayCastFunction( blendingCompositeFunction);
//		blendingVolumeMapper->SetInput( blendingReader->GetOutput());
//	//	blendingVolumeMapper->SetSampleDistance( 12.0);
		
//		LOD = 2.0;
//		blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		
		blendingVolume = vtkVolume::New();
		blendingVolume->SetProperty( blendingVolumeProperty);
		
		[self setBlendingEngine: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]];
		
		vtkMatrix4x4	*matrice = vtkMatrix4x4::New();
		matrice->Element[0][0] = blendingcosines[0];			matrice->Element[1][0] = blendingcosines[1];			matrice->Element[2][0] = blendingcosines[2];			matrice->Element[3][0] = 0;
		matrice->Element[0][1] = blendingcosines[3];			matrice->Element[1][1] = blendingcosines[4];			matrice->Element[2][1] = blendingcosines[5];			matrice->Element[3][1] = 0;
		matrice->Element[0][2] = blendingcosines[6];			matrice->Element[1][2] = blendingcosines[7];			matrice->Element[2][2] = blendingcosines[8];			matrice->Element[3][2] = 0;
		matrice->Element[0][3] = 0;								matrice->Element[1][3] = 0;								matrice->Element[2][3] = 0;								matrice->Element[3][3] = 1;
		
//		blendingVolume->SetOrigin( [blendingFirstObject originX], [blendingFirstObject originY], [blendingFirstObject originZ]);
		
//		blendingFirstObject = [blendingPixList objectAtIndex:[blendingPixList count]-1];

		blendingVolume->SetPosition(	factor*[blendingFirstObject originX] * (matrice->Element[0][0]) + factor*[blendingFirstObject originY] * (matrice->Element[1][0]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][0]),
										factor*[blendingFirstObject originX] * (matrice->Element[0][1]) + factor*[blendingFirstObject originY] * (matrice->Element[1][1]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][1]),
										factor*[blendingFirstObject originX] * (matrice->Element[0][2]) + factor*[blendingFirstObject originY] * (matrice->Element[1][2]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][2]));
//		blendingVolume->SetPosition(	[blendingFirstObject originX],
//										[blendingFirstObject originY],
//										[blendingFirstObject originZ]);
		blendingVolume->SetUserMatrix( matrice);
		matrice->Delete();
		
//		if( blendingFlip) outlineData->SetInput((vtkDataSet *) blendingFlip->GetOutput());
//		else outlineData->SetInput((vtkDataSet *) blendingReader->GetOutput());
		
//		blendingVolume->RotateWXYZ(-90, 1, 0, 0);
//		blendingVolume->RotateWXYZ(0, 0, 1, 0);
//		blendingVolume->RotateWXYZ(90, 0, 0, 1);
		
//		blendingVolume->RotateWXYZ(R2D*asin( blendingnormal[0] - normalv[0]), 1, 0, 0);
//		blendingVolume->RotateWXYZ(R2D*asin( blendingnormal[1] - normalv[1]), 0, 1, 0);
//		blendingVolume->RotateWXYZ(R2D*asin( blendingnormal[2] - normalv[2]), 0, 0, 1);
		
//		blendingVolume->SetOrientation(90, 0, -90);
//		blendingVolume->SetOrientation( R2D*acos( normal[0]), R2D*acos( normal[ 1]), R2D*acos (normal[ 2]));
//		NSLog(@"%0.1f / %0.1f / %0.1f", ( normalv[0]), ( normalv[ 1]),  (normalv[ 2]));
//		NSLog(@"%0.1f / %0.1f / %0.1f", ( blendingnormal[0]), ( blendingnormal[ 1]),  (blendingnormal[ 2]));
		
		cropcallback->setBlendingVolume( blendingVolume);
//		cropcallback->Execute(croppingBox, 0, 0L);
		
	    aRenderer->AddVolume( blendingVolume);
	}
	else
	{
		if( blendingVolume)
		{
			aRenderer->RemoveVolume( blendingVolume);
			
			blendingVolume->Delete();
			blendingVolume = 0L;
			
			if( blendingVolumeMapper) blendingVolumeMapper->Delete();
			if( blendingTextureMapper) blendingTextureMapper->Delete();
			
			blendingVolumeMapper = 0L;
			blendingTextureMapper = 0L;
			
			blendingOpacityTransferFunction->Delete();
			blendingCompositeFunction->Delete();
			blendingVolumeProperty->Delete();
			blendingColorTransferFunction->Delete();
			blendingReader->Delete();
			
			if(blendingData8) free(blendingData8);
			blendingData8 = 0L;
			
			[blendingPixList release];
			blendingPixList = 0L;
		}
	}
}

-(void) movieBlendingChangeSource:(long) index
{
	if( blendingController)
	{
		[blendingPixList release];
		blendingPixList = [blendingController pixList: index];
		[blendingPixList retain];
		
		blendingData = [blendingController volumePtr: index];
		
		blendingReader->SetImportVoidPointer( blendingData);	//AVOID VTK BUG
		
		// Force min/max recomputing
		if( blendingVolumeMapper) blendingVolumeMapper->Delete();
		blendingVolumeMapper = vtkFixedPointVolumeRayCastMapper::New();
		blendingVolumeMapper->SetInput((vtkDataSet *) blendingReader->GetOutput());
		blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		blendingVolume->SetMapper( blendingVolumeMapper);
		
		[self setNeedsDisplay:YES];
	}
}

-(void) movieChangeSource:(float*) volumeData showWait :(BOOL) showWait
{
	double a[ 6];
	WaitRendering	*www;
	BOOL validBox;
	
	if( showWait)
	{
		www = [[WaitRendering alloc] init:@"Preparing 3D data..."];
		[www start];
	}
	
	data = volumeData;
	
	if( isRGB)
	{
		reader->SetImportVoidPointer( data);
		reader->GetOutput()->Modified();
	}
	else
	{
		srcf.data = data;
		vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
		
		reader->SetImportVoidPointer( data8);
		reader->GetOutput()->Modified();
	}
		
	if( volumeMapper) volumeMapper->Delete();
	volumeMapper = 0L;
	if( textureMapper) textureMapper->Delete();
	textureMapper = 0L;
	
	[self setEngine: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"] showWait: NO];

	if( showWait)
	{
		[www end];
		[www close];
		[www release];
	}
}

-(void) movieChangeSource:(float*) volumeData
{
	[self movieChangeSource: volumeData showWait:YES];
}

- (void) ViewFrameDidChangeNotification:(NSNotification*) note
{
	if( textWLWW)
	{
		int *wsize = [self renderWindow]->GetSize();
		textWLWW->GetPositionCoordinate()->SetValue( 2., wsize[ 1]-11);
	}
}

- (void) computeValueFactor
{
	if( [firstObject SUVConverted])
	{
		valueFactor = 4095. / [controller maximumValue];
		OFFSET16 = 0;
	}
	else
	{
		if( [controller maximumValue] - [controller minimumValue] > 4095 || [controller maximumValue] - [controller minimumValue] < 50)
		{
			valueFactor = 4095. / ([controller maximumValue] - [controller minimumValue]);
			OFFSET16 = -[controller minimumValue];
		}
		else
		{
			valueFactor = 1;
			OFFSET16 = 1500;
		}
	}
}

-(short) setPixSource:(NSMutableArray*)pix :(float*) volumeData
{
	short   error = 0;
	long	i;
    
	[[self window] setAcceptsMouseMovedEvents: YES];
	
    [pix retain];
    pixList = pix;
	
	projectionMode = 1;
	
	data = volumeData;
	
	aRenderer = [self renderer];
	cbStart = vtkCallbackCommand::New();
	cbStart->SetCallback( startRendering);
	cbStart->SetClientData( self);
	
	//vtkCommand.h
	[self renderWindow]->AddObserver(vtkCommand::StartEvent, cbStart);
	[self renderWindow]->AddObserver(vtkCommand::EndEvent, cbStart);
	[self renderWindow]->AddObserver(vtkCommand::AbortCheckEvent, cbStart);

	firstObject = [pixList objectAtIndex:0];
	float sliceThickness = [firstObject sliceInterval];  //[[pixList objectAtIndex:1] sliceLocation] - [firstObject sliceLocation];
	
	if( sliceThickness == 0)
	{
		NSLog(@"slice interval = slice thickness!");
		sliceThickness = [firstObject sliceThickness];
	}
	
	NSLog(@"slice: %0.2f", sliceThickness);

	wl = [firstObject wl];
	ww = [firstObject ww];
	
	isRGB = NO;
	if( [firstObject isRGB])
	{
		isRGB = YES;
		
//		long	i, size, val;
//		unsigned char	*srcPtr = (unsigned char*) data;
//		float   *dstPtr;
//		
//		size = [firstObject pheight] * [pix count];
//		size *= [firstObject pwidth];
//		size *= sizeof( float);
//		
//		dataFRGB = (float*) malloc( size);
//		
//		size /= 4;
//		
//		dstPtr = dataFRGB;
//		for( i = 0 ; i < size; i++)
//		{
//			srcPtr++;
//			val = *srcPtr++;
//			val += *srcPtr++;
//			val += *srcPtr++;
//			*dstPtr++ = val/3;
//		}
		
//		long	i, size, val;
//		unsigned char	*srcPtr = (unsigned char*) data;
//		unsigned char   *dstPtr;
//		
//		size = [firstObject pheight] * [pix count];
//		size *= [firstObject pwidth];
//		
//		dataFRGB = (unsigned char*) malloc( size*3);
//		
//		dstPtr = dataFRGB;
//		i = size;
//		while( i-->0)
//		{
//			srcPtr++;
//			*dstPtr++ = *srcPtr++;
//			*dstPtr++ = *srcPtr++;
//			*dstPtr++ = *srcPtr++;
//		}
	}
	
//	else
//	{
//		// Convert float to char
//		
//		srcf.height = [firstObject pheight] * [pix count];
//		srcf.width = [firstObject pwidth];
//		srcf.rowBytes = [firstObject pwidth] * sizeof(float);
//		
//		dst8.height = [firstObject pheight] * [pix count];
//		dst8.width = [firstObject pwidth];
//		dst8.rowBytes = [firstObject pwidth] * sizeof(char);
//		
//		data8 = (char*) malloc( dst8.height * dst8.width * sizeof(char));
//		
//		dst8.data = data8;
//		srcf.data = data;
//		
//	//	vImageConvert_FTo16S( &srcf, &dst8, 0, 1, 0);
//		vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
//	}
	else
	{
		// Convert float to short !!!
		srcf.height = [firstObject pheight] * [pix count];
		srcf.width = [firstObject pwidth];
		srcf.rowBytes = [firstObject pwidth] * sizeof(float);
		
		dst8.height = [firstObject pheight] * [pix count];
		dst8.width = [firstObject pwidth];
		dst8.rowBytes = [firstObject pwidth] * sizeof(short);
		
		data8 = (char*) malloc( dst8.height * dst8.width * sizeof(short));
		if( data8 == 0L) return -1;
		
		dst8.data = data8;
		srcf.data = data;
		
		NSLog( @"maxValueOfSeries = %f", [controller maximumValue]);
		NSLog( @"minValueOfSeries = %f", [controller minimumValue]);
		
		firstPixel = *(data+0);
		secondPixel = *(data+1);
		
		*(data+0) = [controller maximumValue];		// To avoid the min/max saturation problem with 4D data...
		*(data+1) = [controller minimumValue];		// To avoid the min/max saturation problem with 4D data...
		
		[self computeValueFactor];
		vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
	}
	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);	//AVOID VTK BUG
	reader->SetDataExtentToWholeExtent();
	
	if( isRGB)
	{
		reader->SetDataScalarTypeToUnsignedChar();
		reader->SetNumberOfScalarComponents( 4);
		reader->SetImportVoidPointer(data);
	}
	else 
	{
	//	reader->SetDataScalarTypeToFloat();
		reader->SetDataScalarTypeToUnsignedShort();
		reader->SetNumberOfScalarComponents( 1);
	//	reader->SetImportVoidPointer(data);
		reader->SetImportVoidPointer(data8);
	}
	
	[firstObject orientation:cosines];
	
//	float invThick;
	
//	if( cosines[6] + cosines[7] + cosines[8] < 0) invThick = -1;
//	else invThick = 1;
	
	factor = 1.0;
//	if( [firstObject pixelSpacingX] < 0.5 || [firstObject pixelSpacingY] < 0.5 || fabs( sliceThickness) < 0.3) factor = 10;
	
	needToFlip = NO;
	if( sliceThickness < 0 )
	{
		sliceThickness = fabs( sliceThickness);
		NSLog(@"We should not be here....");
		needToFlip = YES;
		NSLog(@"Flip !!");
	}
	//
//	if( needToFlip)
//	{
//		[self flipData: (char*) volumeData :[pixList count] :[firstObject pheight] * [firstObject pwidth]];
//		
//		for(  i = 0 ; i < [pixList count]; i++)
//		{
//			[[pixList objectAtIndex: i] setfImage: volumeData + ([pixList count]-1-i)*[firstObject pheight] * [firstObject pwidth]];
//			[[pixList objectAtIndex: i] setSliceInterval: sliceThickness];
//		}
//		
//		id tempObj;
//		
//		for( i = 0; i < [pixList count]/2 ; i++)
//		{
//			tempObj = [[pixList objectAtIndex: i] retain];
//			
//			[pixList replaceObjectAtIndex: i withObject:[pixList objectAtIndex: [pixList count]-i-1]];
//			[pixList replaceObjectAtIndex: [pixList count]-i-1 withObject: tempObj];
//			
//			[tempObj release];
//		}
//		
//		firstObject = [pixList objectAtIndex: 0];
//	}
//	
//	if( [firstObject flipData])
//	{
//		NSLog(@"firstObject = [pixList lastObject]");
//		firstObject = [pixList lastObject];
//	}
	
	factor = 1.0 / [firstObject pixelSpacingX];
	NSLog(@"Thickness: %2.2f Factor: %2.2f", sliceThickness, factor);
//	factor = 1.0;
	
	if( [firstObject pixelSpacingX] == 0 || [firstObject pixelSpacingY] == 0) reader->SetDataSpacing( 1, 1, sliceThickness);
	else reader->SetDataSpacing( factor*[firstObject pixelSpacingX], factor*[firstObject pixelSpacingY], factor * sliceThickness);
	
		
//	reader->SetDataOrigin(  [firstObject originX],
//							[firstObject originY],
//							[firstObject originZ]);


//	vtkPlane *aplane = vtkPlane::New();
//	aplane->SetNormal( normalv[0], normalv[1], normalv[2]);
//	aplane->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
	
	
//	vtkPlaneWidget  *aplaneWidget = vtkPlaneWidget::New();
//	aplaneWidget->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
//	aplaneWidget->SetNormal( normal[0], normal[1], normal[2] );
//	aplaneWidget->SetResolution(10);
//	aplaneWidget->PlaceWidget();
//    aplaneWidget->SetInteractor( [self renderWindowInteractor]);
	
	opacityTransferFunction = vtkPiecewiseFunction::New();
	opacityTransferFunction->AddPoint(0, 0);
	opacityTransferFunction->AddPoint(255, 1);
//	opacityTransferFunction->ClampingOff();
	
//	vtkPiecewiseFunction	*colorTransferFunction = vtkPiecewiseFunction::New();
//	colorTransferFunction->AddPoint(0, 0);
//	colorTransferFunction->AddPoint(255, 1);
	
	colorTransferFunction = vtkColorTransferFunction::New();
//	colorTransferFunction->ClampingOff();
	
	red = vtkColorTransferFunction::New();
	red->AddRGBPoint(   0, 0, 0, 0 );
	red->AddRGBPoint( 255, 1, 0, 0 );
	
	green = vtkColorTransferFunction::New();
	green->AddRGBPoint(   0, 0, 0, 0 );
	green->AddRGBPoint( 255, 0, 1, 0 );
	
	blue = vtkColorTransferFunction::New();
	blue->AddRGBPoint(   0, 0, 0, 0 );
	blue->AddRGBPoint( 255, 0, 0, 1 );
	
	volumeProperty = vtkVolumeProperty::New();
	if( isRGB)
	{
		volumeProperty->IndependentComponentsOn();
		
		volumeProperty->SetColor( 1,red);
		volumeProperty->SetColor( 2,green);
		volumeProperty->SetColor( 3,blue);
		
		volumeProperty->SetScalarOpacity( 1, opacityTransferFunction);
		volumeProperty->SetScalarOpacity( 2, opacityTransferFunction);
		volumeProperty->SetScalarOpacity( 3, opacityTransferFunction);
		
		volumeProperty->SetComponentWeight( 0, 0);

//		volumeProperty->SetColor( 0,red);
//		volumeProperty->SetColor( 1,green);
//		volumeProperty->SetColor( 2,blue);
//		
//		volumeProperty->SetScalarOpacity( 0, opacityTransferFunction);
//		volumeProperty->SetScalarOpacity( 1, opacityTransferFunction);
//		volumeProperty->SetScalarOpacity( 2, opacityTransferFunction);
		
	}
	else
	{
		volumeProperty->SetColor( colorTransferFunction);	//	if( isRGB == NO) 
		volumeProperty->SetScalarOpacity( opacityTransferFunction);
	}
	
	
	[self setCLUT:0L :0L :0L];
	
	[self setShadingValues:0.15 :0.9 :0.3 :15];

//	volumeProperty->ShadeOn();

	if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) volumeProperty->SetInterpolationTypeToNearest();
    else volumeProperty->SetInterpolationTypeToLinear();//SetInterpolationTypeToNearest();	//SetInterpolationTypeToLinear
		
	compositeFunction = vtkVolumeRayCastCompositeFunction::New();
//	compositeFunction->SetCompositeMethodToClassifyFirst();
//	compositeFunction = vtkVolumeRayCastMIPFunction::New();
	
	LOD = 2.0;
	#if __ppc__
	LOD += 0.5;
	#endif
	
	volume = vtkVolume::New();
    volume->SetProperty( volumeProperty);
	
//	[self setEngine: [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"]];
	
	vtkMatrix4x4	*matrice = vtkMatrix4x4::New();
	matrice->Element[0][0] = cosines[0];		matrice->Element[1][0] = cosines[1];		matrice->Element[2][0] = cosines[2];		matrice->Element[3][0] = 0;
	matrice->Element[0][1] = cosines[3];		matrice->Element[1][1] = cosines[4];		matrice->Element[2][1] = cosines[5];		matrice->Element[3][1] = 0;
	matrice->Element[0][2] = cosines[6];		matrice->Element[1][2] = cosines[7];		matrice->Element[2][2] = cosines[8];		matrice->Element[3][2] = 0;
	matrice->Element[0][3] = 0;					matrice->Element[1][3] = 0;					matrice->Element[2][3] = 0;					matrice->Element[3][3] = 1;

//	volume->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
	volume->SetPosition(	factor*[firstObject originX] * matrice->Element[0][0] + factor*[firstObject originY] * matrice->Element[1][0] + factor*[firstObject originZ]*matrice->Element[2][0],
							factor*[firstObject originX] * matrice->Element[0][1] + factor*[firstObject originY] * matrice->Element[1][1] + factor*[firstObject originZ]*matrice->Element[2][1],
							factor*[firstObject originX] * matrice->Element[0][2] + factor*[firstObject originY] * matrice->Element[1][2] + factor*[firstObject originZ]*matrice->Element[2][2]);
//	volume->SetPosition(	[firstObject originX],// * matrice->Element[0][0] + [firstObject originY] * matrice->Element[1][0] + [firstObject originZ]*matrice->Element[2][0],
//							[firstObject originY],// * matrice->Element[0][1] + [firstObject originY] * matrice->Element[1][1] + [firstObject originZ]*matrice->Element[2][1],
//							[firstObject originZ]);// * matrice->Element[0][2] + [firstObject originY] * matrice->Element[1][2] + [firstObject originZ]*matrice->Element[2][2]);
	volume->SetUserMatrix( matrice);
	matrice->Delete();
	
	volume->PickableOff();
	
	outlineData = vtkOutlineFilter::New();
	outlineData->SetInput((vtkDataSet *) reader->GetOutput());
	
    mapOutline = vtkPolyDataMapper::New();
    mapOutline->SetInput(outlineData->GetOutput());
    
    outlineRect = vtkActor::New();
    outlineRect->SetMapper(mapOutline);
    outlineRect->GetProperty()->SetColor(0,1,0);
    outlineRect->GetProperty()->SetOpacity(0.5);
	outlineRect->SetUserMatrix( matrice);
	outlineRect->SetPosition(	factor*[firstObject originX] * matrice->Element[0][0] + factor*[firstObject originY] * matrice->Element[1][0] + factor*[firstObject originZ]*matrice->Element[2][0],
								factor*[firstObject originX] * matrice->Element[0][1] + factor*[firstObject originY] * matrice->Element[1][1] + factor*[firstObject originZ]*matrice->Element[2][1],
								factor*[firstObject originX] * matrice->Element[0][2] + factor*[firstObject originY] * matrice->Element[1][2] + factor*[firstObject originZ]*matrice->Element[2][2]);
	outlineRect->PickableOff();

	vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
	cube->SetXPlusFaceText ( "L" );
	cube->SetXMinusFaceText( "R" );
	cube->SetYPlusFaceText ( "P" );
	cube->SetYMinusFaceText( "A" );
	cube->SetZPlusFaceText ( "S" );
	cube->SetZMinusFaceText( "I" );
	cube->SetFaceTextScale( 0.67 );

	vtkProperty* property = cube->GetXPlusFaceProperty();
	property->SetColor(0, 0, 1);
	property = cube->GetXMinusFaceProperty();
	property->SetColor(0, 0, 1);
	property = cube->GetYPlusFaceProperty();
	property->SetColor(0, 1, 0);
	property = cube->GetYMinusFaceProperty();
	property->SetColor(0, 1, 0);
	property = cube->GetZPlusFaceProperty();
	property->SetColor(1, 0, 0);
	property = cube->GetZMinusFaceProperty();
	property->SetColor(1, 0, 0);

	vtkProperty* propertyEdges = cube->GetTextEdgesProperty();
	propertyEdges->SetColor(0.5, 0.5, 0.5);
	cube->CubeOn();
	cube->FaceTextOn();
	
	orientationWidget = vtkOrientationMarkerWidget::New();
	orientationWidget->SetOrientationMarker( cube );

	cube->Delete();

	croppingBox = vtkBoxWidget::New();
	
	croppingBox->GetHandleProperty()->SetColor(0, 1, 0);
	croppingBox->SetProp3D( volume);
	croppingBox->SetPlaceFactor( 1.0);
	croppingBox->SetHandleSize( 0.005);
	croppingBox->PlaceWidget();
	croppingBox->SetInteractor( [self getInteractor]);
	croppingBox->SetRotationEnabled( false);
	croppingBox->SetInsideOut( true);
	croppingBox->OutlineCursorWiresOff();
	
	cropcallback = vtkMyCallbackVR::New();
	cropcallback->setBlendingVolume( 0L);
	croppingBox->AddObserver(vtkCommand::InteractionEvent, cropcallback);
		
	textWLWW = vtkTextActor::New();
	if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f", wl, ww);
	else sprintf(WLWWString, "WL: %0.f WW: %0.f", wl, ww);
	textWLWW->SetInput( WLWWString);
	textWLWW->SetScaledText( false);												//vtkviewPort
	textWLWW->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
	textWLWW->GetPositionCoordinate()->SetValue( 0,0);
	aRenderer->AddActor2D(textWLWW);
	
	textX = vtkTextActor::New();
	if (isViewportResizable)
		textX->SetInput( "X");
	else
		textX->SetInput( "");
	textX->SetScaledText( false);
	textX->GetPositionCoordinate()->SetCoordinateSystemToViewport();
	textX->GetPositionCoordinate()->SetValue( 2., 2.);
	aRenderer->AddActor2D(textX);
	
	for( i = 0; i < 4; i++)
	{
		oText[ i]= vtkTextActor::New();
		oText[ i]->SetInput( "X");
		oText[ i]->SetScaledText( false);
		oText[ i]->GetPositionCoordinate()->SetCoordinateSystemToNormalizedViewport();
		oText[ i]->GetTextProperty()->SetFontSize( 16);
		oText[ i]->GetTextProperty()->SetBold( true);
		oText[ i]->GetTextProperty()->SetShadow( true);
		
		aRenderer->AddActor2D( oText[ i]);
	}
	oText[ 0]->GetPositionCoordinate()->SetValue( 0.01, 0.5);
	oText[ 1]->GetPositionCoordinate()->SetValue( 0.99, 0.5);
	oText[ 1]->GetTextProperty()->SetJustificationToRight();
	
	oText[ 2]->GetPositionCoordinate()->SetValue( 0.5, 0.03);
	oText[ 2]->GetTextProperty()->SetVerticalJustificationToTop();
	oText[ 3]->GetPositionCoordinate()->SetValue( 0.5, 0.97);
		
    aCamera = vtkCamera::New();
	aCamera->SetViewUp (0, 1, 0);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, 1);
	aCamera->SetRoll(180);
	aCamera->SetParallelProjection( true);
	
//	aCamera->ComputeViewPlaneNormal();
//	aCamera->OrthogonalizeViewUp();
    
	aCamera->Dolly(1.5);

//	_cocoaRenderWindow->SetLineSmoothing( true);
//	_cocoaRenderWindow->SetPolygonSmoothing(true);
    aRenderer->AddVolume( volume);
//	aRenderer->AddActor(outlineRect);

	aRenderer->SetActiveCamera(aCamera);
	aRenderer->ResetCamera();
	
//	[self renderWindow]->StereoRenderOn();
//	[self renderWindow]->SetStereoTypeToRedBlue();
	
	
	// 3D Cut ROI
	vtkPoints *pts = vtkPoints::New();
	vtkCellArray *rect = vtkCellArray::New();
	
	ROI3DData = vtkPolyData::New();
    ROI3DData-> SetPoints( pts);
	pts->Delete();
    ROI3DData-> SetLines( rect);
	rect->Delete();
	
	ROI3D = vtkPolyDataMapper2D::New();
	ROI3D->SetInput( ROI3DData);
	
	ROI3DActor = vtkActor2D::New();
	ROI3DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
    ROI3DActor->SetMapper( ROI3D);
	ROI3DActor->GetProperty()->SetPointSize( 1);	//vtkProperty2D
	ROI3DActor->GetProperty()->SetLineWidth( 2);
	ROI3DActor->GetProperty()->SetColor(0.3,1,0);
	
	aRenderer->AddActor2D( ROI3DActor);
	
	//	2D Line
	pts = vtkPoints::New();
	rect = vtkCellArray::New();
	
	Line2DData = vtkPolyData::New();
    Line2DData-> SetPoints( pts);
	pts->Delete();
    Line2DData-> SetLines( rect);
	rect->Delete();
	
	Line2D = vtkPolyDataMapper2D::New();
	Line2D->SetInput( Line2DData);
	
	Line2DActor = vtkActor2D::New();
	Line2DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
    Line2DActor->SetMapper( Line2D);
	Line2DActor->GetProperty()->SetPointSize( 6);	//vtkProperty2D
	Line2DActor->GetProperty()->SetLineWidth( 3);
	Line2DActor->GetProperty()->SetColor(1,1,0);

	Line2DText = vtkTextActor::New();
	Line2DText->SetInput( "");
	Line2DText->SetScaledText( false);
	Line2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
	Line2DText->GetPositionCoordinate()->SetValue( 2., 2.);
	Line2DText->GetTextProperty()->SetShadow( YES);
	
	aRenderer->AddActor2D( Line2DActor);
	
//	#if !__LP64__
	orientationWidget->SetInteractor( [self getInteractor] );
	orientationWidget->SetEnabled( 1 );
	orientationWidget->SetViewport( 0.90, 0.90, 1, 1);
//	orientationWidget->InteractiveOff();
//	#endif
	
	[self saView:self];
	
	[self setNeedsDisplay:YES];
	
    return error;
}

-(IBAction) SwitchStereoMode :(id) sender
{
	if( [self renderWindow]->GetStereoRender() == false)
	{
		[self renderWindow]->StereoRenderOn();
		[self renderWindow]->SetStereoTypeToRedBlue();
	}
	else
	{
		[self renderWindow]->StereoRenderOff();
	}
	
	[self setNeedsDisplay:YES];
}

- (NSImage*) resizeMatrix:(NSImage*) currentImage size: (int) matrixsize
{
	NSRect sourceRect = NSMakeRect(0.0, 0.0, [currentImage size].width, [currentImage size].height);
	NSRect imageRect;
	float rescale = 1;
	
	if( [currentImage size].width > [currentImage size].height)
	{
		float ratio = [currentImage size].width / matrixsize;
		imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
		
		NSLog( @"ratio: %f", ratio);
	}
	else
	{
		float ratio = [currentImage size].height / matrixsize;
		imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
		
		NSLog( @"ratio: %f", ratio);
	}
	[currentImage setScalesWhenResized:YES];
	
	NSImage *compositingImage = [[NSImage alloc] initWithSize: imageRect.size];
	
	[compositingImage lockFocus];
//	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationDefault];
	[currentImage drawInRect: imageRect fromRect: sourceRect operation: NSCompositeCopy fraction: 1.0];
	[compositingImage unlockFocus];
	
	return [compositingImage autorelease];
}

-(NSImage*) nsimageQuicktime
{
	NSImage *theIm;

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

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	unsigned char	*buf = 0L;
	long			i;
	
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
		[self getVTKRenderWindow]->MakeCurrent();
		
		glReadPixels(0, 0, *width, *height, GL_RGB, GL_UNSIGNED_BYTE, buf);
		
		long rowBytes = *width**spp**bpp/8;
		
		unsigned char	*tempBuf = (unsigned char*) malloc( rowBytes);
		
		for( i = 0; i < *height/2; i++)
		{
			memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
			memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
			memcpy( buf + i*rowBytes, tempBuf, rowBytes);
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
	
	return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
	NSBitmapImageRep	*rep;
	long				width, height, i, x, spp, bpp;
	NSString			*colorSpace;
	unsigned char		*dataPtr;
	
	[self resetAutorotate: self];
	
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

	memcpy( [rep bitmapData], dataPtr, height*width*bpp*spp/8);
		
	 NSImage *image = [[NSImage alloc] init];
	 [image addRepresentation:rep];
	 
	free( dataPtr);
	
	return image;
}

-(void) switchOrientationWidget:(id) sender
{
	long i;
	
	if( orientationWidget->GetEnabled())
	{
		orientationWidget->Off();
		for( i = 0; i < 4; i++) aRenderer->RemoveActor2D( oText[ i]);
	}
	else
	{
		orientationWidget->On();
		for( i = 0; i < 4; i++) aRenderer->AddActor2D( oText[ i]);
	}
	
	[self setNeedsDisplay:YES];
}

-(void) showCropCube:(id) sender
{
	if( croppingBox->GetEnabled()) croppingBox->Off();
	else
	{
		croppingBox->On();
		
		[self setCurrentTool: t3DRotate];
//		[[[[self window] windowController] toolsMatrix] selectCellWithTag: t3DRotate];
		[[controller toolsMatrix] selectCellWithTag: t3DRotate];
	}
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

- (void) updateScissorStateButtons
{
	NSString		*str = [VRController getUniqueFilenameScissorStateFor: [firstObject imageObj]];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: str] == NO)
	{
		[[scissorStateMatrix cellWithTag: 1] setEnabled: NO];
		[[scissorStateMatrix cellWithTag: 2] setEnabled: NO];
	}
	else
	{
		[[scissorStateMatrix cellWithTag: 1] setEnabled: YES];
		[[scissorStateMatrix cellWithTag: 2] setEnabled: YES];
	}
}

-(IBAction) scissorStateButtons:(id) sender
{
	NSString		*str = [VRController getUniqueFilenameScissorStateFor: [firstObject imageObj]];	
	NSData			*volumeData;
	long			volumeSize = [firstObject pheight] * [pixList count] * [firstObject pwidth] * sizeof(float);
	WaitRendering	*waiting = 0L;
	
	switch( [[sender selectedCell] tag])
	{
		case 2:
			[[NSFileManager defaultManager] removeFileAtPath: str handler: 0L];
		break;
		
		case 1:	// Load
			waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Loading 3D object...", nil)];
			[waiting showWindow:self];
			
			volumeData = [[NSData alloc] initWithContentsOfFile:str];
			
			if( volumeData)
			{
				if( [volumeData length] == volumeSize)
				{
					memcpy( data, [volumeData bytes], volumeSize);
					[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList userInfo: 0];
					
					cropcallback->Execute(croppingBox, 0, 0L);
				}
				else NSRunAlertPanel(NSLocalizedString(@"3D Scissor State", nil), NSLocalizedString(@"No saved data are available.", nil), NSLocalizedString(@"OK", nil), nil, nil);
				
				[volumeData release];
			}
			else NSRunAlertPanel(NSLocalizedString(@"3D Scissor State", nil), NSLocalizedString(@"No saved data are available.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		break;
		
		case 0:	// Save
			waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Saving 3D object...", nil)];
			[waiting showWindow:self];
			volumeData = [NSData dataWithBytesNoCopy:data length:volumeSize freeWhenDone:NO];
			[volumeData writeToFile:str atomically:NO];
		break;
	}
	
	[waiting close];
	[waiting release];
	
	[self updateScissorStateButtons];
}

- (vtkCamera*) vtkCamera;
{
	return aCamera;
}

- (void) setVtkCamera:(vtkCamera*)aVtkCamera;
{
	double pos[3], focal[3], vUp[3];
	aVtkCamera->GetPosition(pos);
	aVtkCamera->GetFocalPoint(focal);
//	aVtkCamera->OrthogonalizeViewUp();
	aVtkCamera->GetViewUp(vUp);
	double clippingRange[2];
	aVtkCamera->GetClippingRange(clippingRange);
	double viewAngle, eyeAngle, parallelScale;
	viewAngle = aVtkCamera->GetViewAngle();
	eyeAngle = aVtkCamera->GetEyeAngle();
	parallelScale = aVtkCamera->GetParallelScale();
	
	aCamera->SetPosition(pos);
	aCamera->SetFocalPoint(focal);
	aCamera->SetViewUp(vUp);
	aCamera->SetClippingRange(clippingRange);
	aCamera->SetViewAngle(viewAngle);
	aCamera->SetEyeAngle(eyeAngle);
	aCamera->SetParallelScale(parallelScale);
	
	aCamera->SetParallelProjection(aVtkCamera->GetParallelProjection());
	[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
}

- (Camera*) camera
{
	// data extraction from the vtkCamera
	
	double pos[3], focal[3], vUp[3];
	
	aCamera->GetPosition(pos);
	aCamera->GetFocalPoint(focal);
	aCamera->OrthogonalizeViewUp();
	aCamera->GetViewUp(vUp);
	double clippingRange[2];
	aCamera->GetClippingRange(clippingRange);
	double viewAngle, eyeAngle, parallelScale;
	viewAngle = aCamera->GetViewAngle();
	eyeAngle = aCamera->GetEyeAngle();
	parallelScale = aCamera->GetParallelScale();
	
	// creation of the Camera
	Camera *cam = [[Camera alloc] init];
	[cam setPosition: [[[Point3D alloc] initWithValues:pos[0] :pos[1] :pos[2]] autorelease]];
	[cam setFocalPoint: [[[Point3D alloc] initWithValues:focal[0] :focal[1] :focal[2]] autorelease]];
	[cam setViewUp: [[[Point3D alloc] initWithValues:vUp[0] :vUp[1] :vUp[2]] autorelease]];
	[cam setClippingRangeFrom: clippingRange[0] To: clippingRange[1]];
	[cam setViewAngle: viewAngle];
	[cam setEyeAngle: eyeAngle];
	[cam setParallelScale: parallelScale];

	// window level
	[cam setWLWW: wl : ww];

	// cropping box
	double a[ 6];
	
	[VRView getCroppingBox: a :volume :croppingBox];
	
	[cam setMinCroppingPlanes: [[[Point3D alloc] initWithValues:a[0] :a[2] :a[4]] autorelease]];
	[cam setMaxCroppingPlanes: [[[Point3D alloc] initWithValues:a[1] :a[3] :a[5]] autorelease]];
	
	// fusion percentage
	[cam setFusionPercentage:blendingFactor];
	
	// 4D
	[cam setMovieIndexIn4D:[controller curMovieIndex]];
	
	// thumbnail
	[cam setPreviewImage: [[self nsimage:TRUE] autorelease]];
	
	return [cam autorelease];
}

- (void) setCamera: (Camera*) cam
{	
	double pos[3], focal[3], vUp[3];
	pos[0] = [[cam position] x];
	pos[1] = [[cam position] y];
	pos[2] = [[cam position] z];
	focal[0] = [[cam focalPoint] x];
	focal[1] = [[cam focalPoint] y];
	focal[2] = [[cam focalPoint] z];	
	vUp[0] = [[cam viewUp] x];
	vUp[1] = [[cam viewUp] y];
	vUp[2] = [[cam viewUp] z];
	double clippingRange[2];
	clippingRange[0] = [cam clippingRangeNear];
	clippingRange[1] = [cam clippingRangeFar];
	double viewAngle, eyeAngle, parallelScale;
	viewAngle = [cam viewAngle];
	eyeAngle = [cam eyeAngle];
	parallelScale = [cam parallelScale];

	// window level
	[self setWLWW:[cam wl] :[cam ww]];
	// cropping box
	double min[3], max[3], a[ 6];
	a[0] = [[cam minCroppingPlanes] x];
	a[2] = [[cam minCroppingPlanes] y];
	a[4] = [[cam minCroppingPlanes] z];
	a[1] = [[cam maxCroppingPlanes] x];
	a[3] = [[cam maxCroppingPlanes] y];
	a[5] = [[cam maxCroppingPlanes] z];
	
	[VRView setCroppingBox: a :volume];
	
	double origin[3];
	volume->GetPosition(origin);	//GetOrigin		
	a[0] += origin[0];		a[1] += origin[0];
	a[2] += origin[1];		a[3] += origin[1];
	a[4] += origin[2];		a[5] += origin[2];
	croppingBox->PlaceWidget(a[0], a[1], a[2], a[3], a[4], a[5]);

	[VRView getCroppingBox: a :blendingVolume :croppingBox];
	[VRView setCroppingBox: a :blendingVolume];

	// fusion percentage
	[self setBlendingFactor:[cam fusionPercentage]];

	// 4D
	if([controller is4D])
		[controller setMovieFrame:[cam movieIndexIn4D]];

	aCamera->SetPosition(pos);
	aCamera->SetFocalPoint(focal);
	aCamera->SetViewUp(vUp);
	//aCamera->SetClippingRange(clippingRange);
	aCamera->SetViewAngle(viewAngle);
	aCamera->SetEyeAngle(eyeAngle);
	aCamera->SetParallelScale(parallelScale);
	aRenderer->ResetCameraClippingRange();
	[[NSNotificationCenter defaultCenter] postNotificationName: @"VRCameraDidChange" object:self  userInfo: 0L];
}

- (void) setLowResolutionCamera: (Camera*) cam
{
	if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
	
	[self setCamera: cam];
	
	[[self window] display];
	
	if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
}

- (void)changeColorWith:(NSColor*) color
{
	if( color)
	{
		//change background color
		aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
		
		if( [color redComponent]+[color greenComponent]+[ color blueComponent] < 1.5) textWLWW->GetTextProperty()->SetColor(1,1,1);
		else textWLWW->GetTextProperty()->SetColor(0,0,0);
		
		[backgroundColor setColor: [NSColor colorWithDeviceRed:[color redComponent] green:[color greenComponent] blue:[ color blueComponent] alpha:1.0]];
		
		[self setNeedsDisplay:YES];
	}
}

- (void)changeColor:(id)sender
{
	if( [backgroundColor isActive])
		[self changeColorWith: [[(NSColorPanel*)sender color]  colorUsingColorSpaceName: NSDeviceRGBColorSpace]];
}

- (NSColor*)backgroundColor;
{
	return [backgroundColor color];
}

- (void) convert3Dto2Dpoint:(float*) pt3D :(float*) pt2D
{
	vtkTransform *Transform = vtkTransform::New();
			
	Transform->SetMatrix( volume->GetUserMatrix());
	Transform->Push();
	
	Transform->Inverse();
	
	Transform->TransformPoint( pt3D, pt2D);
	
	double vPos[ 3];
	
	volume->GetPosition( vPos);
	
	pt2D[ 0] -= vPos[ 0];
	pt2D[ 1] -= vPos[ 1];
	pt2D[ 2] -= vPos[ 2];
	
	pt2D[0] /= [firstObject pixelSpacingX];
	pt2D[1] /= [firstObject pixelSpacingY];
	pt2D[2] /= [firstObject sliceInterval];
						
	Transform->Delete();
}

- (BOOL) isViewportResizable
{
	return isViewportResizable;
}

- (void) setViewportResizable: (BOOL) boo
{
	isViewportResizable = boo;
}

- (float) offset
{
	return OFFSET16;
}

- (float) valueFactor
{
	return valueFactor;
}

// 3D points
#pragma mark-
#pragma mark 3D Points

#pragma mark add
- (void) add3DPoint: (double) x : (double) y : (double) z : (float) radius : (float) r : (float) g : (float) b
{
	x *= factor;
	y *= factor;
	z *= factor;
	
	//Sphere
	vtkSphereSource *sphereSource = vtkSphereSource::New();
	sphereSource->SetRadius(radius);
	sphereSource->SetCenter(x, y, z);
	//Mapper
	vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
	mapper->SetInputConnection(sphereSource->GetOutputPort());
	//Actor
	vtkActor *sphereActor = vtkActor::New();
	sphereActor->SetMapper(mapper);
	sphereActor->GetProperty()->SetColor(r,g,b);
	sphereActor->DragableOn();
	sphereActor->PickableOn();

	float center[3];
	center[0]=x;
	center[1]=y;
	center[2]=z;
	[point3DPositionsArray addObject:[NSValue value:center withObjCType:@encode(float[3])]];
	[point3DRadiusArray addObject:[NSNumber numberWithFloat:radius]];
	[point3DColorsArray addObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0]];
	
	[self add3DPointActor: sphereActor];
	
	sphereSource->Delete();
}

- (void) add3DPoint: (double) x : (double) y : (double) z
{
	[self add3DPoint: x : y : z : point3DDefaultRadius : point3DDefaultColorRed : point3DDefaultColorGreen : point3DDefaultColorBlue];
}

- (void) add3DPointActor: (vtkActor*) actor
{
	void* actorPointer = actor;
	[point3DActorArray addObject:[NSValue valueWithPointer:actorPointer]];
	aRenderer->AddActor(actor);
}

- (void) addRandomPoints: (int) n : (int) r
{
	double origin[ 3];
	volume->GetPosition(origin);
	
	long i;
	// add some random points
	for(i=0; i<n ; i++)
	{
		[self add3DPoint: ((double)(random()/(pow(2,31)-1))*2.0-1.0)*(double)r+origin[0]/2.0 // x coordinate
						: ((double)(random()/(pow(2,31)-1))*2.0-1.0)*(double)r+origin[1]/2.0 // y
						: ((double)(random()/(pow(2,31)-1))*2.0-1.0)*(double)r+origin[2] // z
						: 2.0 // radius
						: 1.0 // red
						: 0.0 // green
						: 0.0 // blue
		];
	}
}

- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val
{
	[self get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val maxOpacity: 1.1 minValue: 0];
}

- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val maxOpacity: (float) maxOpacity minValue: (float) minValue
{
	NSArray	*curPixList = [controller curPixList];
	
	// world point
	double	*worldPointClicked;
	aRenderer->SetDisplayPoint( x, y, 0);
	aRenderer->DisplayToWorld();
	worldPointClicked = aRenderer->GetWorldPoint();

	worldPointClicked[0] /= factor;
	worldPointClicked[1] /= factor;
	worldPointClicked[2] /= factor;
	
	// transform matrix
	vtkMatrix4x4 *ActorMatrix = volume->GetUserMatrix();
	vtkTransform *Transform = vtkTransform::New();
	Transform->SetMatrix(ActorMatrix);
	Transform->Push();
	
	// camera view plane normal
	double cameraViewPlaneNormal[3];
	aCamera->GetViewPlaneNormal(cameraViewPlaneNormal);
	
	// camera position
	double cameraPosition[3];
	aCamera->GetPosition(cameraPosition);
	cameraPosition[0] /= factor;
	cameraPosition[1] /= factor;
	cameraPosition[2] /= factor;
	
	float o[9];
	[firstObject orientation: o];
	
	double cameraProjObj[3];
	cameraProjObj[0] =	cameraViewPlaneNormal[0] * o[0]
						+ cameraViewPlaneNormal[1] * o[1]
						+ cameraViewPlaneNormal[2] * o[2];
	cameraProjObj[1] =	cameraViewPlaneNormal[0] * o[3]
						+ cameraViewPlaneNormal[1] * o[4]
						+ cameraViewPlaneNormal[2] * o[5];
	cameraProjObj[2] =	cameraViewPlaneNormal[0] * o[6]
						+ cameraViewPlaneNormal[1] * o[7]
						+ cameraViewPlaneNormal[2] * o[8];
	
	long stackOrientation, stackMax;
	if( fabs(cameraProjObj[0]) > fabs(cameraProjObj[1]) && fabs(cameraProjObj[0]) > fabs(cameraProjObj[2]))
	{
		stackOrientation = 0; //NSLog(@"X Stack");
		stackMax = [firstObject pwidth];
	}
	else if( fabs(cameraProjObj[1]) > fabs(cameraProjObj[0]) && fabs(cameraProjObj[1]) > fabs(cameraProjObj[2]))
	{
		stackOrientation = 1; //NSLog(@"Y Stack");
		stackMax = [firstObject pheight];
	}
	else
	{
		stackOrientation = 2; //NSLog(@"Z Stack");
		stackMax = [curPixList count];
	}
	
	if(aCamera->GetParallelProjection())
	{				
		cameraPosition[0] = worldPointClicked[0] + cameraViewPlaneNormal[0];
		cameraPosition[1] = worldPointClicked[1] + cameraViewPlaneNormal[1];
		cameraPosition[2] = worldPointClicked[2] + cameraViewPlaneNormal[2];
	}
	
	// the two points defining the line going through the volume
	float	point1[3], point2[3];
	point1[0] = cameraPosition[0];
	point1[1] = cameraPosition[1];
	point1[2] = cameraPosition[2];
	
		// Go beyond the object...
	point2[0] = cameraPosition[0] + (worldPointClicked[0] - cameraPosition[0])*5000.;
	point2[1] = cameraPosition[1] + (worldPointClicked[1] - cameraPosition[1])*5000.;
	point2[2] = cameraPosition[2] + (worldPointClicked[2] - cameraPosition[2])*5000.;
	
	// volume position
	double volumePosition[3];
	volume->GetPosition(volumePosition);
	volumePosition[0] /= factor;
	volumePosition[1] /= factor;
	volumePosition[2] /= factor;

	BOOL direction;
	
	switch(stackOrientation)
	{
		case 0:
			if( point1[0] - point2[0] < 0) direction = YES;
			else direction = NO;
		break;
		
		case 1:
			if( point1[1] - point2[1] < 0) direction = YES;
			else direction = NO;
		break;
		
		case 2:
			if( point1[2] - point2[2] < 0) direction = YES;
			else direction = NO;
		break;
	}
	
	long p, n;
	BOOL pointFound = NO;
	float opacitySum = 0.0;
	float maxValue = -99999;
	int blendMode;
	if( volumeMapper) blendMode = volumeMapper->GetBlendMode();
	if( textureMapper) blendMode = textureMapper->GetBlendMode();
				
	for( p = 0; p < stackMax; p++)
	{
		n = (direction)? p : (stackMax-1)-p;
		
		float currentPoint[3], planeVector[3];
		switch(stackOrientation)
		{
			case 0:
				currentPoint[0] = n * [firstObject pixelSpacingX];
				currentPoint[1] = 0;
				currentPoint[2] = 0;
											
				planeVector[0] = o[0];
				planeVector[1] = o[1];
				planeVector[2] = o[2];
			break;
			
			case 1:
				currentPoint[0] = 0;
				currentPoint[1] = n * [firstObject pixelSpacingY];
				currentPoint[2] = 0;
				
				planeVector[0] = o[3];
				planeVector[1] = o[4];
				planeVector[2] = o[5];
			break;
			
			case 2:
				currentPoint[0] = 0;
				currentPoint[1] = 0;
				currentPoint[2] = n * [firstObject sliceInterval];
				
				planeVector[0] = o[6];
				planeVector[1] = o[7];
				planeVector[2] = o[8];
			break;
		}
			
		currentPoint[0] += volumePosition[0];
		currentPoint[1] += volumePosition[1];
		currentPoint[2] += volumePosition[2];
		
		Transform->TransformPoint(currentPoint,currentPoint);
		
		float resultPt[3];
			
		if( intersect3D_SegmentPlane(point2, point1, planeVector, currentPoint, resultPt))
		{
			// Convert this 3D point to 2D point projected in the plane
			float tempPoint3D[3];
			
			Transform->Inverse();
			Transform->TransformPoint(resultPt,tempPoint3D);
			Transform->Inverse();
			
			tempPoint3D[0] -= volumePosition[0];
			tempPoint3D[1] -= volumePosition[1];
			tempPoint3D[2] -= volumePosition[2];
			
			tempPoint3D[0] /= [firstObject pixelSpacingX];
			tempPoint3D[1] /= [firstObject pixelSpacingY];
			tempPoint3D[2] /= [firstObject sliceInterval];
			
			// convert to long
			long ptInt[3];
			ptInt[0] = (long) (tempPoint3D[0] + 0.5);
			ptInt[1] = (long) (tempPoint3D[1] + 0.5);
			ptInt[2] = (long) (tempPoint3D[2] + 0.5);

			if(needToFlip) 
			{
				ptInt[2] = [curPixList count] - ptInt[2] -1;
			}
			
			long currentSliceNumber, xPosition, yPosition;
			DCMPix *currentDCMPix;
			float *imageBuffer;
			float currentPointValue;
								
			currentSliceNumber = ptInt[2];
			if( ptInt[0] >= 0 && ptInt[0] < [firstObject pwidth] && ptInt[1] >= 0 && ptInt[1] < [firstObject pheight] &&  ptInt[ 2] >= 0 && ptInt[ 2] < [curPixList count])
			{
				currentDCMPix = [curPixList objectAtIndex:currentSliceNumber];
				imageBuffer = [currentDCMPix fImage];
				xPosition = ptInt[0];
				yPosition = ptInt[1];
				
				currentPointValue = imageBuffer[xPosition+yPosition*[currentDCMPix pwidth]];
				
				if( blendMode != vtkVolumeMapper::MAXIMUM_INTENSITY_BLEND)
				{
					// Volume Rendering Mode
				
					opacitySum += opacityTransferFunction->GetValue( (currentPointValue + OFFSET16) * valueFactor);
					
					if( minValue)
					{
						pointFound = currentPointValue >= minValue;
						pointFound = pointFound && opacitySum >= maxOpacity;
					}
					else
						pointFound = opacitySum >= maxOpacity;
					
					if( pointFound)
					{
						*val = currentPointValue;
						
						pix[ 0] = ptInt[ 0];
						pix[ 1] = ptInt[ 1];
						pix[ 2] = ptInt[ 2];
						
						position[ 0] = resultPt[0];
						position[ 1] = resultPt[1];
						position[ 2] = resultPt[2];
						
						p = stackMax;	// stop the 'for loop'
					}
				}
				else
				{
					if( currentPointValue > maxValue)
					{
						if( minValue)
						{
							pointFound = currentPointValue >= minValue;
						}
						else pointFound = YES;
						
						maxValue = currentPointValue;
						*val = currentPointValue;
						
						pix[ 0] = ptInt[ 0];
						pix[ 1] = ptInt[ 1];
						pix[ 2] = ptInt[ 2];
						
						position[ 0] = resultPt[0];
						position[ 1] = resultPt[1];
						position[ 2] = resultPt[2];
					}
				}
			}
		}
	}
	
	Transform->Delete();
	
	return pointFound;
}

//- (void) vtkThrow3DPointOnSurface: (double) x : (double) y			<- Doesn't always work.......
//{
//	vtkWorldPointPicker *picker = vtkWorldPointPicker::New();
//	picker->Pick(x, y, 0.0, aRenderer);
//	double wXYZ[3];
//	picker->GetPickPosition(wXYZ);
//	
////	double origin[3];
////	volume->GetPosition(origin);	//GetOrigin
////	wXYZ[0] -= origin[0];
////	wXYZ[1] -= origin[1];
////	wXYZ[2] -= origin[2];
////	NSLog(@"picked x: %f, y: %f, z: %f", wXYZ[0], wXYZ[1], wXYZ[2]);
//	[self add3DPoint: (float)wXYZ[0]/factor : (float)wXYZ[1]/factor : (float)wXYZ[2]/factor];
//	[controller add2DPoint: (float)wXYZ[0] : (float)wXYZ[1] : (float)wXYZ[2]];
//  picker->Delete();
//}

- (void) throw3DPointOnSurface: (double) x : (double) y
{
	long	pix[ 3];
	float	pos[ 3], value;

	if( [self get3DPixelUnder2DPositionX:x Y:y pixel:pix position:pos value:&value])
	{
		[self add3DPoint: pos[0] : pos[1] : pos[2]];
		
		[controller add2DPoint: pix[0] : pix[1] : pix[ 2] :pos];
	}
}

#pragma mark display
- (void) setDisplay3DPoints: (BOOL) on
{
	display3DPoints = on;
	
	NSEnumerator *enumerator = [point3DActorArray objectEnumerator];
	id object;
	vtkActor *actor;
		
	while (object = [enumerator nextObject])
	{
		actor = (vtkActor*)[object pointerValue];
		if(on)
		{
			aRenderer->AddActor(actor);
		}
		else
		{
			aRenderer->RemoveActor(actor);
		}	
	}
	[self unselectAllActors];
	[self setNeedsDisplay:YES];
}

- (void) toggleDisplay3DPoints
{
	[self setDisplay3DPoints:!display3DPoints];
}

#pragma mark selection
- (BOOL) isAny3DPointSelected
{
	BOOL boo = NO;
	
	if(((vtkAbstractPropPicker*)aRenderer->GetRenderWindow()->GetInteractor()->GetPicker())->GetViewProp()!=NULL)
	{
		// a vtkObject is selected, let's check if it is one of our 3D Points
		if([self selected3DPointIndex] < [point3DActorArray count])
		{
			boo = YES;
		}
	}

	return boo;
}

- (unsigned int) selected3DPointIndex
{
	vtkProp *pickedProp = ((vtkAbstractPropPicker*)aRenderer->GetRenderWindow()->GetInteractor()->GetPicker())->GetPath()->GetFirstNode()->GetViewProp();
	
	void *pickedPropPointer = pickedProp;
	
	NSEnumerator *enumerator = [point3DActorArray objectEnumerator];
	id object;
	void *actorPointer;
	unsigned int i = 0;
	
	while (object = [enumerator nextObject])
	{
		actorPointer = [object pointerValue];
		if(pickedPropPointer==actorPointer)
		{
			return i;
		}
		i++;
	}
	return i; // if no point is selected, returns [point3DActorArray count], i.e. out of bounds...
}

- (void) unselectAllActors
{
	((vtkInteractorStyle*)aRenderer->GetRenderWindow()->GetInteractor()->GetInteractorStyle())->HighlightProp3D(NULL);
}

#pragma mark remove
- (void) remove3DPointAtIndex: (unsigned int) index
{
	// point to remove
	vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
	// remove from Renderer
	aRenderer->RemoveActor(actor);
	// remove the highlight bounding box
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

- (void) removeSelected3DPoint
{
	if([self isAny3DPointSelected])
	{
		// remove 2D Point
		float position[3];
		[[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:position];
		
		[controller remove2DPoint: position[0] : position[1] : position[2]];
		// remove 3D Point
		// the 3D Point is removed through notification (sent in [controller remove2DPoint..)
		//[self remove3DPointAtIndex:[self selected3DPointIndex]];
	}
}

#pragma mark modify 3D point appearence

- (IBAction) IBSetSelected3DPointColor: (id) sender
{
	if([point3DPropagateToAll state])
	{
		[self setAll3DPointsColor: [sender color]];
		[self setAll3DPointsRadius: [point3DRadiusSlider floatValue]];
	}
	else
	{
		[self setSelected3DPointColor: [sender color]];
	}
	[self setNeedsDisplay:YES];
}

- (IBAction) IBSetSelected3DPointRadius: (id) sender
{
	if([point3DPropagateToAll state])
	{
		[self setAll3DPointsRadius: [sender floatValue]];
		[self setAll3DPointsColor: [point3DColorWell color]];
	}
	else
	{
		[self setSelected3DPointRadius: [sender floatValue]];
	}
	[self setNeedsDisplay:YES];
}

- (IBAction) IBPropagate3DPointsSettings: (id) sender
{
	if([sender state]==NSOnState)
	{
		[self setAll3DPointsRadius: [point3DRadiusSlider floatValue]];
		[self setAll3DPointsColor: [point3DColorWell color]];
		[self setNeedsDisplay:YES];
	}
}

- (void) setSelected3DPointColor: (NSColor*) color
{
	if([self isAny3DPointSelected])[self set3DPointAtIndex:[self selected3DPointIndex] Color: color];
}

- (void) setAll3DPointsColor: (NSColor*) color
{
	unsigned int i = 0;	
	for(i=0 ; i<[point3DColorsArray count] ; i++)
	{
		[self set3DPointAtIndex:i Color: color];
	}
}

- (void) set3DPointAtIndex:(unsigned int) index Color: (NSColor*) color
{
	vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
	actor->GetProperty()->SetColor([color redComponent],[color greenComponent],[color blueComponent]);

	[point3DColorsArray removeObjectAtIndex:index];
	[point3DColorsArray insertObject:color atIndex:index];
}

- (void) setSelected3DPointRadius: (float) radius
{
	if([self isAny3DPointSelected])[self set3DPointAtIndex:[self selected3DPointIndex] Radius: radius];
}

- (void) setAll3DPointsRadius: (float) radius
{
	unsigned int i = 0;	
	for(i=0 ; i<[point3DRadiusArray count] ; i++)
	{
		[self set3DPointAtIndex:i Radius: radius];
	}
}

- (void) set3DPointAtIndex:(unsigned int) index Radius: (float) radius
{
	vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
	//Sphere
	vtkSphereSource *sphereSource = vtkSphereSource::New();
	sphereSource->SetRadius(radius);
	float center[3];
	[[point3DPositionsArray objectAtIndex:index] getValue:center];
	sphereSource->SetCenter(center[0],center[1],center[2]);
	//Mapper
	vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
	mapper->SetInputConnection(sphereSource->GetOutputPort());
	//Actor
	actor->SetMapper(mapper);
	[point3DRadiusArray removeObjectAtIndex:index];
	[point3DRadiusArray insertObject:[NSNumber numberWithFloat:radius] atIndex:index];
	
	sphereSource->Delete();
}

- (IBAction) save3DPointsDefaultProperties: (id) sender
{
	//color
	point3DDefaultColorRed = [[point3DColorWell color] redComponent];
	point3DDefaultColorGreen = [[point3DColorWell color] greenComponent];
	point3DDefaultColorBlue = [[point3DColorWell color] blueComponent];
	point3DDefaultColorAlpha = [[point3DColorWell color] alphaComponent];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorRed forKey:@"points3DcolorRed"];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorGreen forKey:@"points3DcolorGreen"];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorBlue forKey:@"points3DcolorBlue"];
	[[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorAlpha forKey:@"points3DcolorAlpha"];

	// radius
	point3DDefaultRadius = [point3DRadiusSlider floatValue];
	[[NSUserDefaults standardUserDefaults] setFloat:[point3DRadiusSlider floatValue] forKey:@"points3Dradius"];
}

- (void) load3DPointsDefaultProperties
{	
	//color
	float r, g, b, a;
	point3DDefaultColorRed = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorRed"];
	point3DDefaultColorGreen = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorGreen"];
	point3DDefaultColorBlue = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorBlue"];
	point3DDefaultColorAlpha = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorAlpha"];
	
	if(a==0.0)
	{
		point3DDefaultColorRed = 0.0;
		point3DDefaultColorGreen = 1.0;
		point3DDefaultColorBlue = 0.0;
		point3DDefaultColorAlpha = 1.0;
	}

	//radius
	point3DDefaultRadius = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3Dradius"];
	if (point3DDefaultRadius==0) point3DDefaultRadius = 5.0;
}

- (float) factor
{
	return factor;
}

#pragma mark-
#pragma mark Export mode

- (void) sendMail:(id) sender
{
	[controller sendMail: sender];
}

- (void) exportJPEG:(id) sender
{
	[controller exportJPEG: sender];
}

- (void) export2iPhoto:(id) sender
{
	[controller export2iPhoto: sender];
}

- (void) exportTIFF:(id) sender
{
	[controller exportTIFF: sender];
}

#pragma mark-
#pragma mark Cursors

- (void) resetCursorRects
{
	[self addCursorRect:[self bounds] cursor: cursor];
}

-(void) setCursorForView: (long) tool
{
	NSCursor	*c;
	
	if (tool == tMesure || tool == t3Dpoint)
		c = [NSCursor crosshairCursor];
	else if( tool == t3DCut)
		c = [NSCursor crosshairCursor];
	else if (tool == t3DRotate)
		c = [NSCursor rotate3DCursor];
	else if (tool == tCamera3D)
		c = [NSCursor rotate3DCameraCursor];
	else if (tool == tTranslate)
		c = [NSCursor openHandCursor];
	else if (tool == tRotate)
		c = [NSCursor rotateCursor];
	else if (tool == tZoom)
		c = [NSCursor zoomCursor];
	else if (tool == tWL || tool == tWLBlended)
		c = [NSCursor contrastCursor];
	else if (tool == tNext)
		c = [NSCursor stackCursor];
	else if (tool == tText)
		c = [NSCursor IBeamCursor];
	else if (tool == t3DRotate)
		c = [NSCursor crosshairCursor];
	else if (tool == tCross)
		c = [NSCursor crosshairCursor];
	else if (tool == tBonesRemoval)
		c = [NSCursor bonesRemovalCursor];
	else	
		c = [NSCursor arrowCursor];
		
	if( c != cursor)
	{
		[cursor release];
		
		cursor = [c retain];
		
		[[self window] invalidateCursorRectsForView: self];
		[self resetCursorRects];
		[cursor set];
	}
}

#pragma mark-  Drag and Drop

- (void) startDrag:(NSTimer*)theTimer{
	NS_DURING
	_dragInProgress = YES;
	
	NSEvent *event = (NSEvent *)[theTimer userInfo];
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard]; 
	NSMutableArray *pbTypes = [NSMutableArray array];
	// The image we will drag 
	NSImage *image;
	if ([event modifierFlags] & NSShiftKeyMask)
		image = [self nsimage: YES];
	else
		image = [self nsimage: NO];
		
	// Thumbnail image and position
	NSPoint event_location = [event locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	local_point.x -= 35;
	local_point.y -= 35;

	NSSize originalSize = [image size];
	
	float ratio = originalSize.width / originalSize.height;
	
	NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize(100, 100/ratio)] autorelease];

	[thumbnail lockFocus];
	[image drawInRect: NSMakeRect(0, 0, 100, 100/ratio) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
	[thumbnail unlockFocus];
	
	if ([event modifierFlags] & NSAlternateKeyMask)
		[ pbTypes addObject: NSFilesPromisePboardType];
	else
		[pbTypes addObject: NSTIFFPboardType];	
	

	[pboard declareTypes:pbTypes  owner:self];

		
	if ([event modifierFlags] & NSAlternateKeyMask) {
		NSRect imageLocation;
		local_point = [self convertPoint:event_location fromView:nil];
		imageLocation.origin =  local_point;
		imageLocation.size = NSMakeSize(32,32);
		[pboard setData:nil forType:NSFilesPromisePboardType]; 
		
		if (destinationImage)
			[destinationImage release];
		destinationImage = [image copy];
		
		[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"jpg"]
            fromRect:imageLocation
            source:self
            slideBack:YES
            event:event];
	} 
	else {		
		[pboard setData: [[NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] forType:NSTIFFPboardType];
		
		[ self dragImage:thumbnail
			at:local_point
			offset:dragOffset
			event:event 
			pasteboard:pboard 
			source:self 
			slideBack:YES];
	}
	
	[image release];
	
	NS_HANDLER
		NSLog(@"Exception while dragging: %@", [localException description]);
	NS_ENDHANDLER
	
	_dragInProgress = NO;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination{
	NSString *name = @"OsiriX";
	name = [name stringByAppendingPathExtension:@"jpg"];
	NSArray *array = [NSArray arrayWithObject:name];
	NSData *_data = [[NSBitmapImageRep imageRepWithData: [destinationImage TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	NSURL *url = [NSURL  URLWithString:name  relativeToURL:dropDestination];
	[_data writeToURL:url  atomically:YES];
	[destinationImage release];
	destinationImage = nil;
	return array;
}

- (void)deleteMouseDownTimer{
	[_mouseDownTimer invalidate];
	[_mouseDownTimer release];
	_mouseDownTimer = nil;
	_dragInProgress = NO;
}

//part of Dragging Source Protocol
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
	return NSDragOperationEvery;
}

#pragma mark -
#pragma mark Hot Keys.
//Hot key action
-(BOOL)actionForHotKey:(NSString *)hotKey
{
	BOOL returnedVal = YES;
	
	if (!_hotKeyDictionary)
		_hotKeyDictionary = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYS"] retain];
	
	if ([hotKey length] > 0)
	{
		NSDictionary *userInfo = nil;
		NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"];
		NSArray *wwwlValues = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
		NSArray *wwwl = nil;
		NSString *wwwlMenuString = nil;
		unichar key = [hotKey characterAtIndex:0];
		
		if( [_hotKeyDictionary objectForKey:hotKey])
		{
			key = [[_hotKeyDictionary objectForKey:hotKey] intValue];
			id windowController = [[self window] windowController];
			NSLog( @"hot key: %d", key);
			
			int index = 1;
			switch (key){
				case DefaultWWWLHotKeyAction: // default WW/WL
								wwwlMenuString = NSLocalizedString(@"Default WL & WW", 0L);	// default WW/WL
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						break;
				case FullDynamicWWWLHotKeyAction:  // full dynamic WW/WL
								wwwlMenuString = NSLocalizedString(@"Full dynamic", 0L);	
								[windowController applyWLWWForString:wwwlMenuString];	
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];								
						break;
																							// 1 - 9 will be presets WW/WL
				case Preset1WWWLHotKeyAction: if([wwwlValues count] >= 1) {
								wwwlMenuString = [wwwlValues objectAtIndex:0];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset2WWWLHotKeyAction: if([wwwlValues count] >= 2) {
								wwwlMenuString = [wwwlValues objectAtIndex:1];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset3WWWLHotKeyAction: if([wwwlValues count] >= 3) {
								wwwlMenuString = [wwwlValues objectAtIndex:2];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset4WWWLHotKeyAction: if([wwwlValues count] >= 4) {
								wwwlMenuString = [wwwlValues objectAtIndex:3];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset5WWWLHotKeyAction: if([wwwlValues count] >= 5) {
								wwwlMenuString = [wwwlValues objectAtIndex:4];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset6WWWLHotKeyAction: if([wwwlValues count] >= 6) {
								wwwlMenuString = [wwwlValues objectAtIndex:5];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset7WWWLHotKeyAction: if([wwwlValues count] >= 7) {
								wwwlMenuString = [wwwlValues objectAtIndex:6];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset8WWWLHotKeyAction: if([wwwlValues count] >= 8) {
								wwwlMenuString = [wwwlValues objectAtIndex:7];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				case Preset9WWWLHotKeyAction: if([wwwlValues count] >= 9) {
								wwwlMenuString = [wwwlValues objectAtIndex:8];
								[windowController applyWLWWForString: wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						}	
						break;
				
					// Flip  Don't flip Vertical or Horizontal in VR Do nothing
					
				// mouse functions
				case WWWLToolHotKeyAction:		
					[windowController setCurrentTool:tWL];
					break;
				case MoveHotKeyAction:		
					[windowController setCurrentTool:tTranslate];
					break;
				case ZoomHotKeyAction:		
					[windowController setCurrentTool:tZoom];
					break;
				case RotateHotKeyAction:		
					[windowController setCurrentTool:tRotate];
					break;
				case ScrollHotKeyAction:		
					[windowController setCurrentTool:tNext];
					break;
				case LengthHotKeyAction:		
					[windowController setCurrentTool:tMesure];
					break;
					/*
				case AngleHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tAngle], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case RectangleHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tROI], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case OvalHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tOval], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case TextHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tText], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
				case ArrowHotKeyAction:		
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tArrow], @"toolIndex", nil];
					[[NSNotificationCenter defaultCenter] postNotificationName: @"defaultToolModified" object:nil userInfo: userInfo];
					break;
		*/
				case Rotate3DHotKeyAction:		
					[windowController setCurrentTool:t3DRotate];
					break;
				case Camera3DotKeyAction:		
					[windowController setCurrentTool:tCamera3D];
					break;
				case scissors3DHotKeyAction:		
					[windowController setCurrentTool:t3DCut];
					break;
				
				case ThreeDPointHotKeyAction:		
					[windowController setCurrentTool:t3Dpoint];
					break;
				case PlainToolHotKeyAction:		
					[windowController setCurrentTool:tPlain];
					break;
				case BoneRemovalHotKeyAction:		
					[windowController setCurrentTool:tBonesRemoval];
					break;
				
				default:
					returnedVal = NO;
				break;
			}
		}
		else returnedVal = NO;
	}
	else returnedVal = NO;
	
	return returnedVal;
}

#pragma mark -
#pragma mark Advanced CLUT / Opacity

- (void)setAdvancedCLUT:(NSMutableDictionary*)clut lowResolution:(BOOL)lowRes;
{
	advancedCLUT = YES;
	
	NSArray *curves = [clut objectForKey:@"curves"];
	NSArray *pointColors = [clut objectForKey:@"colors"];
	NSArray *name = [clut objectForKey:@"name"];
	
	NSArray *firstCurve = [curves objectAtIndex:0];
	NSArray *firstColors = [pointColors objectAtIndex:0];
	
	if( [[NSArchiver archivedDataWithRootObject: clut] isEqualToData: appliedCurves] == NO || (appliedResolution == YES && lowRes == NO))
	{	
		colorTransferFunction->RemoveAllPoints();
		opacityTransferFunction->RemoveAllPoints();
	
		opacityTransferFunction->AddSegment([controller minimumValue], 0.0, [controller maximumValue], 0.0);
		
		int i,j;
		for(i=0; i<[curves count]; i++)
		{
			NSMutableArray *aCurve = [NSMutableArray arrayWithArray:[curves objectAtIndex:i]];
			NSMutableArray *someColors = [NSMutableArray arrayWithArray:[pointColors objectAtIndex:i]];
			for(j=0; j<[aCurve count]; j++)
			{
				colorTransferFunction->AddRGBPoint(OFFSET16 + [[aCurve objectAtIndex:j] pointValue].x, [[someColors objectAtIndex:j] redComponent], [[someColors objectAtIndex:j] greenComponent], [[someColors objectAtIndex:j] blueComponent]);
				opacityTransferFunction->AddPoint(OFFSET16 + [[aCurve objectAtIndex:j] pointValue].x, [[aCurve objectAtIndex:j] pointValue].y * [[aCurve objectAtIndex:j] pointValue].y);
			}
			
//			float x0, x1, x00, x11, alpha0, alpha1, alpha00, alpha11, r0, g0, b0, r1, g1, b1;
//			
//			opacityTransferFunction->AddSegment([controller minimumValue], 0.0, [[aCurve objectAtIndex:0] pointValue].x, 0.0);
//			opacityTransferFunction->AddSegment([[aCurve lastObject] pointValue].x, 0.0, [controller maximumValue], 0.0);
//					
//			for(j=1; j<[aCurve count]; j++)
//			{
//				x0 = OFFSET16 + [[aCurve objectAtIndex:j-1] pointValue].x;
//				x1 = OFFSET16 + [[aCurve objectAtIndex:j] pointValue].x;
//				x00 = [[aCurve objectAtIndex:j-1] pointValue].x;
//				x11 = [[aCurve objectAtIndex:j] pointValue].x;
//				alpha0 = [[aCurve objectAtIndex:j-1] pointValue].y * [[aCurve objectAtIndex:j-1] pointValue].y;
//				alpha1 = [[aCurve objectAtIndex:j] pointValue].y * [[aCurve objectAtIndex:j] pointValue].y;
//				alpha00 = [[aCurve objectAtIndex:j-1] pointValue].y;
//				alpha11 = [[aCurve objectAtIndex:j] pointValue].y;
//				
//				r0 = [[someColors objectAtIndex:j-1] redComponent];
//				g0 = [[someColors objectAtIndex:j-1] greenComponent];
//				b0 = [[someColors objectAtIndex:j-1] blueComponent];
//				
//				r1 = [[someColors objectAtIndex:j] redComponent];
//				g1 = [[someColors objectAtIndex:j] greenComponent];
//				b1 = [[someColors objectAtIndex:j] blueComponent];
//				
//				if(alpha0 >= opacityTransferFunction->GetValue(x0) && alpha1 >= opacityTransferFunction->GetValue(x1))
//				{
//					colorTransferFunction->AddRGBSegment(x0, r0, g0, b0, x1, r1, g1, b1);
//					opacityTransferFunction->AddSegment(x0, alpha0, x1, alpha1);
//				}
//				else if(alpha0 <= opacityTransferFunction->GetValue(x0) && alpha1 >= opacityTransferFunction->GetValue(x1))
//				{
//					[aCurve replaceObjectAtIndex:j-1 withObject:[NSValue valueWithPoint:NSMakePoint((x00+x11)*0.5, (alpha00+alpha11)*0.5)]];
//					[someColors replaceObjectAtIndex:j-1 withObject:[[someColors objectAtIndex:j-1] blendedColorWithFraction:0.5 ofColor:[someColors objectAtIndex:j]]];
//					j--;
//				}
//				else if(alpha0 > opacityTransferFunction->GetValue(x0) && alpha1 < opacityTransferFunction->GetValue(x1))
//				{
//					[aCurve insertObject:[NSValue valueWithPoint:NSMakePoint((x00+x11)*0.5, (alpha00+alpha11)*0.5)] atIndex:j];
//					[someColors insertObject:[[someColors objectAtIndex:j-1] blendedColorWithFraction:0.5 ofColor:[someColors objectAtIndex:j]] atIndex:j];
//					j--;
//				}
//				// else means that the 2 points are under an oder curve -> they are invisible -> don't add them
//			}
		}
		
		[appliedCurves release];
		appliedCurves = [[NSArchiver archivedDataWithRootObject: clut] retain];
		appliedResolution = lowRes;
		
		if(volumeMapper)
		{
			if(lowRes)
				volumeMapper->SetMinimumImageSampleDistance(LOD*lowResLODFactor*2); // was LOD*5
 			else
				volumeMapper->SetMinimumImageSampleDistance(LOD);
		}
		
		[self setNeedsDisplay: YES];
	}
}

- (void)setAdvancedCLUTWithName:(NSString*)name;
{
}

- (BOOL)advancedCLUT;
{
	return advancedCLUT;
}

-(VRController*)controller;
{
	return controller;
}

- (BOOL)isRGB;
{
	return isRGB;
}

- (vtkFixedPointVolumeRayCastMapper*)volumeMapper;
{
	return volumeMapper;
}

- (void)setVolumeMapper:(vtkFixedPointVolumeRayCastMapper*)aVolumeMapper;
{
	if(volumeMapper) volumeMapper->Delete();
	volumeMapper = aVolumeMapper;
//	volumeMapper->Register( volumeMapper);
	volume->SetMapper(volumeMapper);
}

- (vtkVolume*)volume;
{
	return volume;
}

- (void)setVolume:(vtkVolume*)aVolume;
{
	if(volume) volume->Delete();
	volume = aVolume;
}

- (char*)data8;
{
	return data8;
}

- (void)setData8:(char*)someData;
{
	if(data8) free(data8);
	data8 = someData;
}

@end
