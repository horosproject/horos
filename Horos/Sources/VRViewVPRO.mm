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
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "VRViewVPRO.h"

#import "VRControllerVPRO.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "DCMCursor.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#import "wait.h"
#import "QuicktimeExport.h"
#include "vtkImageResample.h"
#import "ROI.h"
#import "BrowserController.h"
#import "DICOMExport.h"

#define id Id
#include "itkImage.h"
#include "itkImportImageFilter.h"
#undef id
#import "ITKSegmentation3D.h"
#import "ITKBrushROIFilter.h"

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

#define OFFSET16 1500
#define BONEVALUE 250
#define BONEOPACITY 4.0

extern int intersect3D_SegmentPlane( float *P0, float *P1, float *Pnormal, float *Ppoint, float* resultPt );
extern BrowserController *browserWindow;

typedef struct _xyzArray
{
	short x;
	short y;
	short z;
} xyzArray;

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

static void startRendering(vtkObject*,unsigned long c, void* mipv, void*)
{
	//vtkRenderWindow
	//[self renderWindow] SetAbortRender( true);
	if( c == vtkCommand::StartEvent)
	{
		[mipv newStartRenderingTime];
	}
	
	if( c == vtkCommand::EndEvent)
	{
		[mipv stopRendering];
		[[mipv startRenderingTime] release];
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

class vtkMyCallbackVP : public vtkCommand
{
public:
	vtkVolume *blendingVolume;
	
	void setBlendingVolume(vtkVolume *bV)
	{
		blendingVolume = bV;
	}
	
  static vtkMyCallbackVP *New( ) 
    {
		return new vtkMyCallbackVP;
	}
  void Delete()
    { delete this; }
  virtual void Execute(vtkObject *caller, unsigned long, void*)
    {
    //  vtkTransform *t = vtkTransform::New();
		vtkBoxWidget *widget = reinterpret_cast<vtkBoxWidget*>(caller);
	//	widget->GetTransform(t);
	//	widget->GetProp3D()->SetUserTransform(t);
				
		vtkPolyData *pd = vtkPolyData::New();
		widget->GetPolyData( pd);
		
		vtkVolume *volume = (vtkVolume*) widget->GetProp3D();
		
		double a[ 6];
		
		[VRPROView getCroppingBox: a :volume :widget];
		[VRPROView setCroppingBox: a :volume];
				
		widget->SetHandleSize( 0.005);
    }
};

@implementation VRPROView

+ (BOOL) getCroppingBox:(double*) a :(vtkVolume *) volume :(vtkBoxWidget*) croppingBox
{
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

-(void) restoreViewSizeAfterMatrix3DExport
{
	[self setFrame: savedViewSizeFrame];
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
	
	[self display];
}

- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val maxOpacity: (float) maxOpacity minValue: (float) minValue
{
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
		stackMax = [pixList count];
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
			if( point1[0] - point2[0] > 0) direction = YES;
			else direction = NO;
		break;
		
		case 1:
			if( point1[1] - point2[1] > 0) direction = YES;
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
				ptInt[2] = [pixList count] - ptInt[2] -1;
			}
			
			long currentSliceNumber, xPosition, yPosition;
			DCMPix *currentDCMPix;
			float *imageBuffer;
			float currentPointValue;
								
			currentSliceNumber = ptInt[2];
			if( ptInt[0] >= 0 && ptInt[0] < [firstObject pwidth] && ptInt[1] >= 0 && ptInt[1] < [firstObject pheight] &&  ptInt[ 2] >= 0 && ptInt[ 2] < [pixList count])
			{
				currentDCMPix = [pixList objectAtIndex:currentSliceNumber];
				imageBuffer = [currentDCMPix fImage];
				xPosition = ptInt[0];
				yPosition = ptInt[1];
				
				currentPointValue = imageBuffer[xPosition+yPosition*[currentDCMPix pwidth]];

				float currentOpacity = currentPointValue;
				currentOpacity = currentOpacity - (wl - ww/2);
				currentOpacity /= ww;
				if( currentOpacity < 0) currentOpacity = 0;
				if( currentOpacity > 1.0) currentOpacity = 1.0;
				if( textureMapper->GetBlendMode() != vtkVolumeMapper::MAXIMUM_INTENSITY_BLEND)
				
				if( blendMode != vtkVolumeMapper::MAXIMUM_INTENSITY_BLEND)
				{
					// Volume Rendering Mode
					
					opacitySum += opacityTransferFunction->GetValue( currentOpacity*255.0);
				//	opacitySum += opacityTransferFunction->GetValue( (currentPointValue + OFFSET16));
					
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

- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val
{
	[self get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val maxOpacity: 1.1 minValue: 0];
}

- (void)getOrientationText:(char *) orientation : (float *) vector :(BOOL) inv {
	
	NSString *orientationX;
	NSString *orientationY;
	NSString *orientationZ;

	NSMutableString *optr = [NSMutableString string];
	
	if( inv)
	{
		orientationX = -vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
		orientationY = -vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
		orientationZ = -vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
	}
	else
	{
		orientationX = vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
		orientationY = vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
		orientationZ = vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
	}
	
	float absX = fabs( vector[ 0]);
	float absY = fabs( vector[ 1]);
	float absZ = fabs( vector[ 2]);
	
	// get first 3 AXIS
	for ( int i=0; i < 3; ++i) {
		if (absX>.2 && absX>=absY && absX>=absZ)
		{
			[optr appendString: orientationX]; absX=0;
		}
		else if (absY>.2 && absY>=absX && absY>=absZ)	{
			[optr appendString: orientationY]; absY=0;
		} else if (absZ>.2 && absZ>=absX && absZ>=absY) {
			[optr appendString: orientationZ]; absZ=0;
		} else break; *optr='\0';
	}
	
	strcpy( orientation, [optr UTF8String]);
}

//- (void) getOrientationText:(char *) string : (float *) vector :(BOOL) inv
//{
//	char orientationX;
//	char orientationY;
//	char orientationZ;
//
//	char *optr = string;
//	*optr = 0;
//	
//	if( inv)
//	{
//		orientationX = -vector[ 0] < 0 ? 'R' : 'L';
//		orientationY = -vector[ 1] < 0 ? 'A' : 'P';
//		orientationZ = -vector[ 2] < 0 ? 'I' : 'S';
//	}
//	else
//	{
//		orientationX = vector[ 0] < 0 ? 'R' : 'L';
//		orientationY = vector[ 1] < 0 ? 'A' : 'P';
//		orientationZ = vector[ 2] < 0 ? 'I' : 'S';
//	}
//	
//	float absX = fabs( vector[ 0]);
//	float absY = fabs( vector[ 1]);
//	float absZ = fabs( vector[ 2]);
//	
//	int i; 
//	for (i=0; i<1; ++i)
//	{
//		if (absX>.0001 && absX>absY && absX>absZ)
//		{
//			*optr++=orientationX; absX=0;
//		}
//		else if (absY>.0001 && absY>absX && absY>absZ)
//		{
//			*optr++=orientationY; absY=0;
//		} else if (absZ>.0001 && absZ>absX && absZ>absY)
//		{
//			*optr++=orientationZ; absZ=0;
//		} else break; *optr='\0';
//	}
//}

- (void) flipData:(char*) ptr :(long) no :(long) size
{
	long i;
	char*	tempData;
	
	tempData = (char*) malloc( size);
	
	for( i = 0; i < no/2; i++)
	{
		memcpy( tempData, ptr + size*i, size);
		memcpy( ptr + size*i, ptr + size*(no-1-i), size);
		memcpy( ptr + size*(no-1-i), tempData, size);
	}
	
	free( tempData);
}

- (void) updateVolumePRO
{
	if( textureMapper)
	{
		long			i;
		unsigned short	o[ 256];
		unsigned char	r[ 256], g[ 256], b[ 256];
		
		NSLog(@"*******************");
		for( i = 0; i < 256; i++)
		{
			o[ i] = opacityTransferFunction->GetValue( i) * 4095.;
			r[ i] = table[ i][ 0] * 255.;
			g[ i] = table[ i][ 1] * 255.;
			b[ i] = table[ i][ 2] * 255.;
		}
		NSLog(@"*******************");
		
		textureMapper->SetShading( aRenderer, volume);
		
		textureMapper->SetLookUpTable( OFFSET16 + wl - ww/2, OFFSET16 + wl + ww/2, r, g, b, o, aRenderer, volume);
		
	//	textureMapper->SetBlendModeToMaximumIntensity();
		
	//	textureMapper->UpdateLights( aRenderer, volume);
	//	 textureMapper->UpdateProperties( aRenderer, volume ); 
	//	textureMapper->SetSubVolume(100, 100, 100, 512, 512, 300);
	}
}

- (void) setMode: (long) modeID
{
	if( textureMapper)
	{
		switch( modeID)
		{
			case 0:
				textureMapper->SetBlendModeToComposite();
			break;
			
			case 1:
				textureMapper->SetBlendModeToMaximumIntensity();
				volumeProperty->ShadeOff();
			break;
		}
		
		[self updateVolumePRO];
	}
	
	[self setNeedsDisplay:YES];
}

- (void) setEngine: (long) engineID
{
	switch( engineID)
	{
		case 0:		// RAY CAST
			if( volumeMapper) return;
			
			if( textureMapper) textureMapper->Delete();
//			if( shearWarpMapper) shearWarpMapper->Delete();
			
			textureMapper = nil;
//			shearWarpMapper = nil;
			
			volumeMapper = vtkVolumeRayCastMapper::New();
			volumeMapper->SetVolumeRayCastFunction( compositeFunction);
			
			volumeMapper->SetInput((vtkDataSet *) reader->GetOutput());
			volumeMapper->SetMinimumImageSampleDistance( LOD);
			
		//	volumeMapper->SetBlendModeToMaximumIntensity();
			
			volume->SetMapper( volumeMapper);
		break;
		
		case 1:		// TEXTURE
			if( textureMapper) return;

			if( volumeMapper) volumeMapper->Delete();
//			if( shearWarpMapper) shearWarpMapper->Delete();
			
			volumeMapper = nil;
//			shearWarpMapper = nil;
			
			textureMapper = vtkOpenGLVolumeProVP1000Mapper::New();
			textureMapper->SetInput((vtkDataSet *) reader->GetOutput());
			
			volume->SetMapper( textureMapper);
			
		//	textureMapper->SetCursor( 1);
			textureMapper->SetSuperSampling( 1);
			textureMapper->SetSuperSamplingFactor( 1, 1, 1);
		//	textureMapper->SetIntermixIntersectingGeometry( 0);
		
			if( textureMapper) [self updateVolumePRO];  
		break;
		
		case 2:		// SHEAR-WARP
//			if( shearWarpMapper) return;

//			if( volumeMapper) volumeMapper->Delete();
//			if( textureMapper) textureMapper->Delete();

			volumeMapper = nil;
			textureMapper = nil;
			
			// SHEAR-WARP - NOT IMPLEMENTED IN THIS VERSION
		break;
	}
	
	[self setNeedsDisplay:YES];
}

- (void) setBlendingEngine: (long) engineID
{
	if( blendingController == nil) return;
	
	switch( engineID)
	{
		case 0:		// RAY CAST
			if( blendingVolumeMapper) return;
			
			if( blendingTextureMapper) blendingTextureMapper->Delete();
//			if( blendingShearWarpMapper) blendingShearWarpMapper->Delete();
			
			blendingTextureMapper = nil;
//			blendingShearWarpMapper = nil;
			
			blendingVolumeMapper = vtkVolumeRayCastMapper::New();
			blendingVolumeMapper->SetVolumeRayCastFunction( blendingCompositeFunction);
			
			blendingVolumeMapper->SetInput(blendingReader->GetOutput());
			blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
			
			blendingVolume->SetMapper( blendingVolumeMapper);
		break;
		
		case 1:		// TEXTURE
			if( blendingTextureMapper) return;

			if( blendingVolumeMapper) blendingVolumeMapper->Delete();
//			if( blendingShearWarpMapper) blendingShearWarpMapper->Delete();
			
			blendingVolumeMapper = nil;
//			blendingShearWarpMapper = nil;
			
			blendingTextureMapper = vtkOpenGLVolumeProVP1000Mapper::New();
			blendingTextureMapper->SetInput(blendingReader->GetOutput());
			
			blendingVolume->SetMapper( blendingTextureMapper);
		break;
		
		case 2:		// SHEAR-WARP
//			if( blendingShearWarpMapper) return;

//			if( blendingVolumeMapper) blendingVolumeMapper->Delete();
//			if( blendingTextureMapper) blendingTextureMapper->Delete();

			blendingVolumeMapper = nil;
			blendingTextureMapper = nil;
			
			// SHEAR-WARP - NOT IMPLEMENTED IN THIS VERSION
		break;
	}
	
	[self setNeedsDisplay:YES];
}

-(NSImage*) image4DForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [cur intValue] != -1) [[[self window] windowController] setMovieFrame: [cur intValue]];
	
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
		if( [cur intValue] % numberOfFrames == 0 && [cur intValue] != 0)
		{
			aCamera->Azimuth( 360 / numberOfFrames);
			[self Vertical: - 360 / numberOfFrames];
		}
		else if([cur intValue] != 0) aCamera->Azimuth( 360 / numberOfFrames);
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

-(IBAction) endDCMExportSettings:(id) sender
{
	[exportDCMWindow orderOut:sender];
	
	[NSApp endSheet:exportDCMWindow returnCode:[sender tag]];
	
	numberOfFrames = [dcmframesSlider intValue];
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
			
			if( exportDCM == nil) exportDCM = [[DICOMExport alloc] init];
			
			unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :YES];
			
			if( dataPtr)
			{
				[exportDCM setSourceFile: [firstObject sourceFile]];
				[exportDCM setSeriesDescription: [dcmSeriesName stringValue]];
				[exportDCM setSeriesNumber:5600];
				[exportDCM setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				
				[self getOrientation: o];
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportOrientationIn3DExport"])
					[exportDCM setOrientation: o];
				
				if( aCamera->GetParallelProjection())
					[exportDCM setPixelSpacing: [self getResolution] :[self getResolution]];
					
			//	[exportDCM setPixelSpacing: 1 :1];
				
				NSString *f = [exportDCM writeDCMFile: nil];
				if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
				
				free( dataPtr);
			}
			
			[[BrowserController currentBrowser] checkIncoming: self];
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
			[dcmSequence setSeriesDescription: [dcmSeriesName stringValue]];
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
				
				unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :YES];
				
				if( dataPtr)
				{
					[self getOrientation: o];
					[dcmSequence setOrientation: o];
					
					[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
					
					if( aCamera->GetParallelProjection())
						[dcmSequence setPixelSpacing: [self getResolution] :[self getResolution]];
					
					NSString *f = [dcmSequence writeDCMFile: nil];
					
					free( dataPtr);
				}
				
				[progress incrementBy: 1];
				
				[pool release];
			}
			
			[progress close];
			[progress release];
			
			[dcmSequence release];
			
			[[BrowserController currentBrowser] checkIncoming: self];
		}
		else // A 3D sequence
		{
			float			o[ 9];
			long			i;
			DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
			
			if( [[[self window] windowController] movieFrames] > 1)
			{
				numberOfFrames /= [[[self window] windowController] movieFrames];
				numberOfFrames *= [[[self window] windowController] movieFrames];
			}
			
			Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating a DICOM series", nil)];
			[progress showWindow:self];
			[[progress progress] setMaxValue: numberOfFrames];
			
			[dcmSequence setSeriesNumber:5600 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
			[dcmSequence setSeriesDescription: [dcmSeriesName stringValue]];
			[dcmSequence setSourceFile: [firstObject sourceFile]];
			
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
			
				if( croppingBox->GetEnabled()) croppingBox->Off();
			//	aRenderer->RemoveActor(outlineRect);
				aRenderer->RemoveActor(textX);
				
				noWaitDialog = YES;
				[self display];
				noWaitDialog = NO;
				
			//	aRenderer->AddActor(outlineRect);
				aRenderer->AddActor(textX);

				long	width, height, spp, bpp, err;
				
				unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :YES];
				
				if( dataPtr)
				{
					[self getOrientation: o];
					[dcmSequence setOrientation: o];
					
					[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
					
					if( aCamera->GetParallelProjection())
						[dcmSequence setPixelSpacing: [self getResolution] :[self getResolution]];
					
					NSString *f = [dcmSequence writeDCMFile: nil];
					
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
			
			[progress close];
			[progress release];
			
			[dcmSequence release];
			
			[[BrowserController currentBrowser] checkIncoming: self];
		}
		
		[self restoreViewSizeAfterMatrix3DExport];
	}
}

- (void) exportDICOMFile:(id) sender
{
	[self setCurrentdcmExport: dcmExportMode];
	if( [[[self window] windowController] movieFrames] > 1) [[dcmExportMode cellWithTag:2] setEnabled: YES];
	else [[dcmExportMode cellWithTag:2] setEnabled: NO];
	[NSApp beginSheet: exportDCMWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

-(IBAction) endQuicktimeSettings:(id) sender
{
	[export3DWindow orderOut:sender];
	
	[NSApp endSheet:export3DWindow returnCode:[sender tag]];
	
	numberOfFrames = [framesSlider intValue];
	bestRenderingMode = YES;
	
	if( [[rotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [[orientation selectedCell] tag] == 1) rotationOrientation = 1;
	else rotationOrientation = 0;
	
	if( [sender tag])
	{
		[self setViewSizeToMatrix3DExport];
		
		if( croppingBox->GetEnabled()) croppingBox->Off();
	//	aRenderer->RemoveActor(outlineRect);
		aRenderer->RemoveActor(textX);
		
		if( [[[self window] windowController] movieFrames] > 1)
		{
			numberOfFrames /= [[[self window] windowController] movieFrames];
			numberOfFrames *= [[[self window] windowController] movieFrames];
		}
		
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :numberOfFrames];
		
		[mov createMovieQTKit: YES  :NO :[[[[[self window] windowController] fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov release];
		
		[self restoreViewSizeAfterMatrix3DExport];
		
	//	aRenderer->AddActor(outlineRect);
		aRenderer->AddActor(textX);
	}
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
	bestRenderingMode = YES;
	
	rotationValue = 360;
	
	if( [sender tag])
	{
		NSString	*path, *newpath;
		FSRef		fsref;
		FSSpec		spec, newspec;
		QuicktimeExport *mov;
		
		[self setViewSizeToMatrix3DExport];
		
		if( croppingBox->GetEnabled()) croppingBox->Off();
	//	aRenderer->RemoveActor(outlineRect);
		aRenderer->RemoveActor(textX);
		
		if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
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
			
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			[[NSFileManager defaultManager] movePath: newpath  toPath: path handler: nil];
			
			[[NSWorkspace sharedWorkspace] openFile:path];
		}
		
		[self restoreViewSizeAfterMatrix3DExport];
		
		[mov release];
		
	//	aRenderer->AddActor(outlineRect);
		aRenderer->AddActor(textX);
	}
}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower
{
	//vtkVolumeProperty.h
	
	volumeProperty->SetAmbient(ambient);
	volumeProperty->SetDiffuse(diffuse);
	volumeProperty->SetSpecular(specular);
	volumeProperty->SetSpecularPower(specularpower);
	
	[self updateVolumePRO];
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
	projectionMode = [[sender selectedCell] tag];
	switch( [[sender selectedCell] tag])
	{
		case 0:
			aCamera->SetParallelProjection( false);
			aCamera->SetViewAngle( 30);
		break;
		
		case 2:
			aCamera->SetParallelProjection( false);
			aCamera->SetViewAngle( 60);
		break;
		
		case 1:
			aCamera->SetParallelProjection( true);
			aCamera->SetViewAngle( 30);
		break;
	}
	
	if( aCamera->GetParallelProjection())
	{
		[[[[[self window] windowController] toolsMatrix] cellWithTag: tMesure] setEnabled: YES];
		
		aRenderer->AddActor( Line2DActor);
	}
	else
	{
		[[[[[self window] windowController] toolsMatrix] cellWithTag: tMesure] setEnabled: NO];
		
		aRenderer->RemoveActor( Line2DText);
		aRenderer->RemoveActor( Line2DActor);
		
		// Delete current ROI
		vtkPoints *pts = vtkPoints::New();
		vtkCellArray *rect = vtkCellArray::New();
		Line2DData-> SetPoints( pts);		pts->Delete();
		Line2DData-> SetLines( rect);		rect->Delete();
				
		if( currentTool == tMesure)
		{
			[self setCurrentTool: t3DRotate];
			[[[[self window] windowController] toolsMatrix] selectCellWithTag: t3DRotate];
		}
	}
	
	[self setNeedsDisplay:YES];
}

-(IBAction) switchShading:(id) sender
{
	if( [sender state] == NSOnState)
	{
		volumeProperty->ShadeOn();
		
		[self setNeedsDisplay:YES];
	}
	else
	{
		volumeProperty->ShadeOff();
		
		[self setNeedsDisplay:YES];
	}
	
	[self updateVolumePRO];
}


-(IBAction) exportQuicktime3DVR:(id) sender
{
	[NSApp beginSheet: export3DVRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

- (IBAction) exportQuicktime:(id) sender
{
	long i;
	
	if( [[[self window] windowController] movieFrames] > 1)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"Quicktime Export", nil), NSLocalizedString(@"Should I export the temporal series or the 3D scene?", nil), NSLocalizedString(@"3D Scene", nil), NSLocalizedString(@"Temporal Series", nil), nil) == NSAlertDefaultReturn)
		{
			[NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
		}
		else
		{
			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(image4DForFrame: maxFrame:) :[[[self window] windowController] movieFrames]];
		
			[mov createMovieQTKit: YES :NO :[[[[[self window] windowController] fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
			
			[mov release];
		}
	}
	else [NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
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
		[self setBlendingPixSource:nil];
	}
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
	if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask))  tool = tRotate;
	if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSControlKeyMask))  tool = tCamera3D;
	
	return tool;
}

- (void) flagsChanged:(NSEvent *)event
{
	if( [event modifierFlags])
	{
		long tool = [self getTool: event];
		[self setCursorForView: tool];
		if( cursorSet) [cursor set];
	}
	
	[super flagsChanged: event];
}

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame] )
    {
		NSTrackingArea *cursorTracking = [[[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil] autorelease];
		
		[self addTrackingArea: cursorTracking];
		
		//vtkRenderWindow
		//[self renderWindow]->SetDoubleBuffer(0);
		//vtkMapper::SetGlobalImmediateModeRendering(1);
		
		rotate = NO;
		
		splash = [[WaitRendering alloc] init:@"Rendering..."];
//		[[splash window] makeKeyAndOrderFront:self];
		
		currentTool = t3DRotate;
		[self setCursorForView: currentTool];
		
		blendingController = nil;
		blendingFactor = 0.5;
		blendingVolume = nil;
		exportDCM = nil;
		cursor = nil;
		
		ROIUPDATE = NO;
		
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
				 
		autoRotate = [[NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(autoRotate:) userInfo:nil repeats:YES] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: nil];
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [notification object] == [self window])
	{
		[autoRotate invalidate];
		[autoRotate release];
		autoRotate = nil;
		
		[[NSNotificationCenter defaultCenter] removeObserver: self];
	}
}

-(void) set3DStateDictionary:(NSDictionary*) dict
{
	float   temp[ 5];
	NSArray *tempArray;
	
	if( dict)
	{
		[self setWLWW: [[dict objectForKey:@"WL"] floatValue] :[[dict objectForKey:@"WW"] floatValue]];
		
		tempArray = [dict objectForKey:@"CameraPosition"];
		aCamera->SetPosition( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);

		tempArray = [dict objectForKey:@"CameraViewUp"];
		aCamera->SetViewUp( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);

		tempArray = [dict objectForKey:@"CameraFocalPoint"];
		aCamera->SetFocalPoint( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);
		
		tempArray = [dict objectForKey:@"CameraClipping"];
		aCamera->SetClippingRange( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue]);
	
		tempArray = [dict objectForKey:@"ShadingValues"];
		if( tempArray)
		{
			[self setShadingValues:[[tempArray objectAtIndex:0] floatValue] :[[tempArray objectAtIndex:1] floatValue] :[[tempArray objectAtIndex:2] floatValue] :[[tempArray objectAtIndex:3] floatValue]];
		}
		volumeProperty->SetShade( [[dict objectForKey:@"ShadingFlag"] longValue]);
		
		if( [dict objectForKey:@"Projection"])
		{
			[projection selectCellWithTag: [[dict objectForKey:@"Projection"] intValue]];
			[self switchProjection: projection];
		}
		
		[self updateVolumePRO];
	}
	else
	{
		[self setWLWW: 256 :440];
	}
}

-(NSMutableDictionary*) get3DStateDictionary
{
	double	temp[ 3];
	float	ambient, diffuse, specular, specularpower;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:[NSNumber numberWithFloat:wl] forKey:@"WL"];
	[dict setObject:[NSNumber numberWithFloat:ww] forKey:@"WW"];
	
	aCamera->GetPosition( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], nil] forKey:@"CameraPosition"];
	aCamera->GetViewUp( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], nil] forKey:@"CameraViewUp"];
	aCamera->GetFocalPoint( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], nil] forKey:@"CameraFocalPoint"];
	aCamera->GetClippingRange( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]], nil] forKey:@"CameraClipping"];

	[self getShadingValues:&ambient :&diffuse :&specular :&specularpower];
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:ambient],  [NSNumber numberWithFloat:diffuse], [NSNumber numberWithFloat:specular],  [NSNumber numberWithFloat:specularpower], nil] forKey:@"ShadingValues"];
	[dict setObject:[NSNumber numberWithLong:volumeProperty->GetShade()] forKey:@"ShadingFlag"];
	[dict setObject:[NSNumber numberWithLong:projectionMode] forKey:@"Projection"];
	
	return dict;
}

- (void) drawRect:(NSRect)aRect
{
	[self computeOrientationText];
	[super drawRect:aRect];
}

-(void)dealloc
{
	long i;
//	VLIClose();
	
    NSLog(@"Dealloc VRView");
	[exportDCM release];
	[splash close];
	[splash release];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];

//	cropcallback->Delete();
	
	[self setBlendingPixSource: nil];
	
//	cbStart->Delete();
	opacityTransferFunction->Delete();
	volumeProperty->Delete();
	compositeFunction->Delete();
	if( orientationWidget)
		orientationWidget->Delete();
	
	if( volumeMapper) volumeMapper->Delete();
	if( textureMapper) textureMapper->Delete();
//	if( shearWarpMapper) shearWarpMapper->Delete();
	
	volume->Delete();
	outlineData->Delete();
	mapOutline->Delete();
//	outlineRect->Delete();
	croppingBox->Delete();
	textWLWW->Delete();
	textX->Delete();
	for( i = 0; i < 4; i++) oText[ i]->Delete();
	colorTransferFunction->Delete();
	reader->Delete();
	
    aCamera->Delete();

	ROI3D->Delete();
	ROI3DData->Delete();
	ROI3DActor->Delete();
	
	Line2D->Delete();
	Line2DActor->Delete();
	Line2DText->Delete();
	
    [pixList release];
    pixList = nil;
	
	if( isRGB) free( dataFRGB);
	
	free( data8);
	
	[cursor release];
	
    [super dealloc];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{

	[self mouseDown:theEvent];

	//show contextual menu  added LP 12/5/05
//		if ([theEvent type] == NSRightMouseDown && [theEvent clickCount] > 1)
//			[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
			
//    BOOL		keepOn = YES;
//    NSPoint		mouseLoc, mouseLocStart;
//	short		tool;
//	
//	noWaitDialog = YES;
//	
//	{
//		int shiftDown = 0;
//		int controlDown = 1;
//		
//		if( textureMapper)
//		{
//			textureMapper->SetSuperSampling( 0);
//			textureMapper->SetSuperSamplingFactor( 1, 1, 1);
//			textureMapper->SetMaxWindow( 256);
//		}
//		
//		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
//		[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
//		[self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
//		
//		do {
//			theEvent = [[self window] nextEventMatchingMask: NSRightMouseUpMask | NSRightMouseDraggedMask | NSPeriodicMask];
//			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
//			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
//			switch ([theEvent type]) {
//			case NSRightMouseDragged:
//				[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
//				break;
//			case NSRightMouseUp:
//				noWaitDialog = NO;
//				[self getInteractor]->InvokeEvent(vtkCommand::RightButtonReleaseEvent, NULL);
//				keepOn = NO;
//				break;
//			case NSPeriodic:
//				[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
//				break;
//			default:
//				break;
//			}
//		}while (keepOn);
//		
//		if( textureMapper)
//		{
//			textureMapper->SetSuperSampling( 1);
//			textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
//			textureMapper->SetMaxWindow( 800);
//		}
//		
//		[self setNeedsDisplay:YES];
//	}
//	
//	noWaitDialog = NO;
}

- (void) timerUpdate:(id) sender
{
	if( ROIUPDATE == YES)
		[self display];
		
	ROIUPDATE = NO;
}

- (void) computeLength
{
	vtkPoints		*pts = Line2DData->GetPoints();
	
	if( pts->GetNumberOfPoints() == 2)
	{
		double			point1[ 4], point2[ 4];
		char			text[ 256];
	
		
		pts->GetPoint( 0, point1);
		aRenderer->SetDisplayPoint( point1);
		aRenderer->DisplayToWorld();
		aRenderer->GetWorldPoint( point1);
		
		pts->GetPoint( 1, point2);
		aRenderer->SetDisplayPoint( point2);
		aRenderer->DisplayToWorld();
		aRenderer->GetWorldPoint( point2);


		double xd = point2[ 0]- point1[ 0];
        double yd = point2[ 1]- point1[ 1];
        double zd = point2[ 2]- point1[ 2];
        double length = sqrt(xd*xd + yd*yd + zd*zd);


//		double sideA = fabs(point1[ 0] - point2[ 0]);
//		double sideB = fabs(point1[ 1] - point2[ 1]);
//		double length;
//		
//		if( sideA == 0) length = sideB;
//		else if( sideB == 0) length = sideA;
//		else length = sideB / (sin (atan( sideB / sideA)));
		
		pts->GetPoint( 0, point1);
		pts->GetPoint( 1, point2);
		
		Line2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
		if( point1[ 0] > point2[ 0]) Line2DText->GetPositionCoordinate()->SetValue( point1[0] + 3, point1[ 1]);
		else Line2DText->GetPositionCoordinate()->SetValue( point2[0], point2[ 1]);
		
		if (length/10. < .1)
			sprintf( text, "Length: %2.2f %cm", (length/10.) * 10000.0, 0xB5);
		else
			sprintf( text, "Length: %2.2f cm", length/10.);
		
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

- (void)otherMouseDown:(NSEvent *)theEvent
{
	int tool = [self getTool: theEvent];
	[self setCursorForView: tool];
	
	[super otherMouseDown: theEvent];
}

- (void) autoRotate:(id) sender
{
	if( rotate)
	{
		[self Azimuth: 8.];
		[self setNeedsDisplay: YES];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL		keepOn = YES;
    NSPoint		mouseLoc, mouseLocPre, mouseLocStart;
	short		tool;
	
//	if ([theEvent clickCount] > 1) rotate = !rotate;
	
	noWaitDialog = YES;
	tool = currentTool;
	
	mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	
	if( [theEvent clickCount] > 1 && (tool != t3Dpoint))
	{
		long	pix[ 3];
		float	pos[ 3], value;
		
		if( [self get3DPixelUnder2DPositionX:mouseLocStart.x Y:mouseLocStart.y pixel:pix position:pos value:&value])
		{
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: pix[0]], @"x", [NSNumber numberWithInt: pix[1]], @"y", [NSNumber numberWithInt: pix[2]], @"z",
																				nil];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"Display3DPoint" object:pixList  userInfo: dict];
		}
		
		return;
	}
	
	if( mouseLocStart.x < 10 && mouseLocStart.y < 10)
	{
		NSRect	newFrame = [self frame];
		NSRect	beforeFrame;
		
		do
		{
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			
			mouseLoc = [theEvent locationInWindow];	//[self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 0);
				textureMapper->SetSuperSamplingFactor( 1, 1, 1);
				textureMapper->SetMaxWindow( 256);
			}
			
			switch ([theEvent type])
			{
				case NSLeftMouseDragged:
					beforeFrame = [self frame];
					
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
					
				//	NSLog(@"%f", aCamera->GetParallelScale());
				//	NSLog(@"%f", aCamera->GetViewAngle());
				break;
				
				case NSLeftMouseUp:
					noWaitDialog = NO;
					keepOn = NO;
				break;
					
				case NSPeriodic:
					
				break;
					
				default:
				
				break;
			}
		}while (keepOn);
		
		if( textureMapper)
		{
			textureMapper->SetSuperSampling( 1);
			textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
			textureMapper->SetMaxWindow( 800);
		}
		
		[self setNeedsDisplay:YES];
	}
	else
	{
		tool = [self getTool: theEvent];
		[self setCursorForView: tool];
		
		if( tool == tMesure)
		{
			double	*pp;
			long	i;
			
			QDDisplayWaitCursor( true);
			
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
			
			mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
			
			aRenderer->SetDisplayPoint( mouseLocStart.x, mouseLocStart.y, 0);
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
			
			QDDisplayWaitCursor( false);
		}
		else if( tool == t3DCut)
		{
			double	*pp;
			long	i;
			
			QDDisplayWaitCursor( true);
			
			// Click point 3D to 2D
			
			mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
			
			aRenderer->SetDisplayPoint( mouseLocStart.x, mouseLocStart.y, 0);
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
				[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:0]; 
			}
			
			QDDisplayWaitCursor( false);
		}
		else if( tool == tWL)
		{
			float	startWW = ww, startWL = wl;
			
			mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( 10.0);
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 0);
				textureMapper->SetSuperSamplingFactor( 1, 1, 1);
				textureMapper->SetMaxWindow( 256);
			}
			
			long i;
			
			unsigned short	o[ 256];
			unsigned char	r[ 256], g[ 256], b[ 256];
			
			for( i = 0; i < 256; i++)
			{
				o[ i] = opacityTransferFunction->GetValue( i) * 4095.;
				r[ i] = table[ i][ 0] * 255.;
				g[ i] = table[ i][ 1] * 255.;
				b[ i] = table[ i][ 2] * 255.;
			}
			
			do
			{
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				switch ([theEvent type])
				{
				case NSLeftMouseDragged:
				{
					float WWAdapter  = startWW / 100.0;
					
					wl = startWL + (long) (mouseLoc.y - mouseLocStart.y)*WWAdapter;
					ww = startWW + (long) (mouseLoc.x - mouseLocStart.x)*WWAdapter;
					if( ww < 1) ww = 1;
					
					if( ww > 10000) ww = 10000;
					
					sprintf(WLWWString, "WL: %0.f WW: %0.f", wl, ww);
					textWLWW->SetInput( WLWWString);
					
					if( textureMapper) textureMapper->SetLookUpTable( OFFSET16 + wl - ww/2, OFFSET16 + wl + ww/2, r, g, b, o, aRenderer, volume);	//vtkDataSet
					
					[self setNeedsDisplay:YES];
				}
				break;
				
				case NSLeftMouseUp:
					noWaitDialog = NO;
					keepOn = NO;
					break;
					
				case NSPeriodic:
					
					break;
					
				default:
					break;
				}
			}while (keepOn);
			
			if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 1);
				textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
				textureMapper->SetMaxWindow( 800);
			}
			
			[self setNeedsDisplay:YES];
		}
		else if( tool == tRotate)
		{
			int shiftDown = 0;
			int controlDown = 1;
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 0);
				textureMapper->SetSuperSamplingFactor( 1, 1, 1);
				textureMapper->SetMaxWindow( 256);
			}
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			
			do {
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				switch ([theEvent type]) {
				case NSLeftMouseDragged:
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					break;
				case NSLeftMouseUp:
					noWaitDialog = NO;
					[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
					keepOn = NO;
					break;
				case NSPeriodic:
					[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
					break;
				default:
					break;
				}
			}while (keepOn);
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 1);
				textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
				textureMapper->SetMaxWindow( 800);
			}
			
			[self setNeedsDisplay:YES];
		}
		else if( tool == t3DRotate)
		{
			int shiftDown = 0;//([theEvent modifierFlags] & NSShiftKeyMask);
			int controlDown = 0;//([theEvent modifierFlags] & NSControlKeyMask);
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 0);
				textureMapper->SetSuperSamplingFactor( 1, 1, 1);
				textureMapper->SetMaxWindow( 256);
			}
			
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			NSLog( @"x=%d, y=%d", (int) mouseLoc.x, (int) mouseLoc.y);
			
			[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
			
			do {
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
				switch ([theEvent type]) {
				case NSLeftMouseDragged:
					[self computeOrientationText];
					[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
					break;
				case NSLeftMouseUp:
					noWaitDialog = NO;
					[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
					keepOn = NO;
					break;
				case NSPeriodic:
					[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
					break;
				default:
					break;
				}
			}while (keepOn);
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 1);
				textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
				textureMapper->SetMaxWindow( 800);
			}
			
			[self setNeedsDisplay:YES];
		}
		else if( tool == tTranslate)
		{
			int shiftDown = 1;
			int controlDown = 0;
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 0);
				textureMapper->SetSuperSamplingFactor( 1, 1, 1);
				textureMapper->SetMaxWindow( 256);
			}
			
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
					noWaitDialog = NO;
					[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
					keepOn = NO;
					break;
				case NSPeriodic:
					[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
					break;
				default:
					break;
				}
			}while (keepOn);
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 1);
				textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
				textureMapper->SetMaxWindow( 800);
			}
			
			[self setNeedsDisplay:YES];
		}
		else if( tool == tZoom)
		{
			if( projectionMode != 2)
			{
				int shiftDown = 0;
				int controlDown = 1;
				
				if( textureMapper)
				{
					textureMapper->SetSuperSampling( 0);
					textureMapper->SetSuperSamplingFactor( 1, 1, 1);
					textureMapper->SetMaxWindow( 256);
				}
				
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
				[self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
				
				do {
					theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
					mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
					[self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
					switch ([theEvent type]) {
					case NSLeftMouseDragged:
					case NSRightMouseDragged:
						[self computeLength];
						[self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
						break;
					case NSLeftMouseUp:
					case NSRightMouseUp:
						noWaitDialog = NO;
						[self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
						keepOn = NO;
						break;
					case NSPeriodic:
						[self getInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
						break;
					default:
						break;
					}
				}while (keepOn);
				
				if( textureMapper)
				{
					textureMapper->SetSuperSampling( 1);
					textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
					textureMapper->SetMaxWindow( 800);
				}
				
				[self computeLength];
				[self setNeedsDisplay:YES];
			}
			else
			{
				// vtkCamera
				mouseLocPre = mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				
				if( textureMapper)
				{
					textureMapper->SetSuperSampling( 0);
					textureMapper->SetSuperSamplingFactor( 1, 1, 1);
					textureMapper->SetMaxWindow( 256);
				}
				
				do
				{
					theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
					mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
					switch ([theEvent type])
					{
					case NSLeftMouseDragged:
					case NSRightMouseDragged:
					{
						float distance = aCamera->GetDistance();
						aCamera->Dolly( 1.0 + (mouseLoc.y - mouseLocPre.y) / 1200.);
						aCamera->SetDistance( distance);
						aCamera->ComputeViewPlaneNormal();
						aCamera->OrthogonalizeViewUp();
						aRenderer->ResetCameraClippingRange();
						
						[self setNeedsDisplay:YES];
					}
					break;
					
					case NSLeftMouseUp:
					case NSRightMouseUp:
						noWaitDialog = NO;
						keepOn = NO;
						break;
						
					case NSPeriodic:
						
						break;
						
					default:
						break;
					}
					
					mouseLocPre = mouseLoc;
				}while (keepOn);
				
				if( textureMapper)
				{
					textureMapper->SetSuperSampling( 1);
					textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
					textureMapper->SetMaxWindow( 800);
				}
				
				[self setNeedsDisplay:YES];

			}
		}
		else if( tool == tCamera3D)
		{
			// vtkCamera
			mouseLocPre = mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 0);
				textureMapper->SetSuperSamplingFactor( 1, 1, 1);
				textureMapper->SetMaxWindow( 256);
			}
			
			do
			{
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
				mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
				switch ([theEvent type])
				{
				case NSLeftMouseDragged:
				{
					aCamera->Yaw( -(mouseLoc.x - mouseLocPre.x) / 5.);
					aCamera->Pitch( (mouseLoc.y - mouseLocPre.y) / 5.);
					aCamera->ComputeViewPlaneNormal();
					aCamera->OrthogonalizeViewUp();
					aRenderer->ResetCameraClippingRange();
					
					[self computeOrientationText];
					
					[self setNeedsDisplay:YES];
				}
				break;
				
				case NSLeftMouseUp:
					noWaitDialog = NO;
					keepOn = NO;
					break;
					
				case NSPeriodic:
					
					break;
					
				default:
					break;
				}
				mouseLocPre = mouseLoc;
			}while (keepOn);
			
			if( textureMapper)
			{
				textureMapper->SetSuperSampling( 1);
				textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
				textureMapper->SetMaxWindow( 800);
			}
			
			[self setNeedsDisplay:YES];
		}
		else if( tool == tBonesRemoval)
		{
			QDDisplayWaitCursor( true);
			
			NSLog( @"**** Bone Removal Start");
			// enable Undo
			[[[self window] windowController] prepareUndo];
			
			NSLog( @"**** Undo");
			
			// clicked point (2D coordinate)
			mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
			
			// world point
			double	*worldPointClicked;
			aRenderer->SetDisplayPoint( mouseLocStart.x, mouseLocStart.y, 0);
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
				stackMax = [pixList count];
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
	
//			NSLog( @"Start Pt : x=%f, y=%f, z=%f"	, point1[0], point1[1], point1[2]);
//			NSLog( @"End Pt : x=%f, y=%f, z=%f"		, point2[0], point2[1], point2[2]);
	
			// volume position
			double volumePosition[3];
			volume->GetPosition(volumePosition);
			NSLog( @"volumePosition : %f, %f, %f" , volumePosition[0], volumePosition[1], volumePosition[2]);
			volumePosition[0] /= factor;
			volumePosition[1] /= factor;
			volumePosition[2] /= factor;

			float point1ToVolume[3];
			point1ToVolume[0] = fabs(volumePosition[0]-point1[0]);
			point1ToVolume[1] = fabs(volumePosition[1]-point1[1]);
			point1ToVolume[2] = fabs(volumePosition[2]-point1[2]);
			
			float point1ToNextPosition[3];
			switch(stackOrientation)
			{
				case 0:
					point1ToNextPosition[0] = fabs(volumePosition[0] + [firstObject pixelSpacingX] - point1[0]);
					point1ToNextPosition[1] = fabs(volumePosition[1] - point1[1]);
					point1ToNextPosition[2] = fabs(volumePosition[2] - point1[2]);
				break;
				case 1:
					point1ToNextPosition[0] = fabs(volumePosition[0] - point1[0]);
					point1ToNextPosition[1] = fabs(volumePosition[1] + [firstObject pixelSpacingY] - point1[1]);
					point1ToNextPosition[2] = fabs(volumePosition[2] - point1[2]);
				break;
				case 2:
					point1ToNextPosition[0] = fabs(volumePosition[0] - point1[0]);
					point1ToNextPosition[1] = fabs(volumePosition[1] - point1[1]);
					point1ToNextPosition[2] = fabs(volumePosition[2] + [firstObject sliceInterval] - point1[2]);	
				break;
			}
				
			float distancePoint1ToVolume, distancePoint1ToNextPosition;
			distancePoint1ToVolume = sqrt(point1ToVolume[0]*point1ToVolume[0]+point1ToVolume[1]*point1ToVolume[1]+point1ToVolume[2]*point1ToVolume[2]);
			distancePoint1ToNextPosition = sqrt(point1ToNextPosition[0]*point1ToNextPosition[0]
												+point1ToNextPosition[1]*point1ToNextPosition[1]
												+point1ToNextPosition[2]*point1ToNextPosition[2]);
			
			BOOL direction = distancePoint1ToVolume < distancePoint1ToNextPosition;
			long currentSliceNumber, xPosition, yPosition;
			long x, n;
			BOOL boneFound = NO;
			float opacitySum = 0.0;

//			NSLog(@"stackMax : %d", stackMax);
			for( x = 0; (x < stackMax) && (!boneFound) && (opacitySum<=BONEOPACITY); x++)
			{
				n = (direction)? x : (stackMax-1)-x;
				
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
						ptInt[2] = [pixList count] - ptInt[2] -1;
					}
					
					
					DCMPix *currentDCMPix;
					float *imageBuffer;
					float currentPointValue;
					
							
					currentSliceNumber = ptInt[2];
					if( ptInt[0] >= 0 && ptInt[0] < [firstObject pwidth] && ptInt[1] >= 0 && ptInt[1] < [firstObject pheight] &&  ptInt[ 2] >= 0 && ptInt[ 2] < [pixList count])
					{
						currentDCMPix = [pixList objectAtIndex:currentSliceNumber];
						imageBuffer = [currentDCMPix fImage];
						xPosition = ptInt[0];
						yPosition = ptInt[1];
						
						currentPointValue = imageBuffer[xPosition+yPosition*[currentDCMPix pwidth]];
						
						float currentOpacity = currentPointValue;
						
						currentOpacity = currentOpacity - (wl - ww/2);
						currentOpacity /= ww;
						
						if( currentOpacity < 0) currentOpacity = 0;
						if( currentOpacity > 1.0) currentOpacity = 1.0;
						
						if( textureMapper->GetBlendMode() != vtkVolumeMapper::MAXIMUM_INTENSITY_BLEND) opacitySum += opacityTransferFunction->GetValue( currentOpacity*255.0);

						boneFound = currentPointValue >= BONEVALUE;
						
						boneFound = boneFound && (opacitySum<=BONEOPACITY); // take bones only if (nearly) visible
					}
				}
			}
			
			NSLog( @"**** Bone Raycast");
			if(boneFound)
			{
				NSLog(@"BONE FOUND!!");
				
				NSPoint seedPoint;
				seedPoint.x = xPosition;
				seedPoint.y = yPosition;
				
				
				long seed[ 3];
				
				seed[ 0] = (long) seedPoint.x;
				seed[ 1] = (long) seedPoint.y;
				seed[ 2] = currentSliceNumber;
				
				NSArray	*roiList =	[ITKSegmentation3D fastGrowingRegionWithVolume:		data
																						width:		[[pixList objectAtIndex: 0] pwidth]
																						height:		[[pixList objectAtIndex: 0] pheight]
																						depth:		[pixList count]
																						seedPoint:	seed
																						from:		BONEVALUE
																						pixList:	pixList];
				
				
				NSLog( @"**** Growing3D");
				
				[[[[self window] windowController] viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"dilate" radius: 10 sendNotification:NO];
				[[[[self window] windowController] viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"erode" radius: 6 sendNotification:NO];

				NSLog( @"**** Dilate/Erode");
				
				// Bone Removal
				NSNumber		*nsnewValue	= [NSNumber numberWithFloat: -1000];
				NSNumber		*nsminValue	= [NSNumber numberWithFloat: -99999];
				NSNumber		*nsmaxValue	= [NSNumber numberWithFloat: 99999];
				NSNumber		*nsoutside	= [NSNumber numberWithBool: NO];
				NSMutableArray	*roiToProceed = [NSMutableArray array];
				int				i;
				
				for( i = 0 ; i < [roiList count]; i++)
				{
					NSDictionary	*rr = [roiList objectAtIndex: i];
					
					[roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys: [rr objectForKey:@"roi"], @"roi", [rr objectForKey:@"curPix"], @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nil]];
				}
				
				[[[[self window] windowController] viewer2D] roiSetStartScheduler: roiToProceed];
				
				[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList userInfo: 0];
				
				NSLog( @"**** Set Pixels");
			}
			else
			{
				//NSLog(@"bone not found.....");
			}
			QDDisplayWaitCursor( false);
			Transform->Delete();
		}
		else [super mouseDown:theEvent];
	}
	
	croppingBox->SetHandleSize( 0.005);
	
	noWaitDialog = NO;
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
    
	if( c == ' ')
	{
		rotate = !rotate;
	}
	
	if( c == 27)
	{
		[[[self window] windowController] offFullScreen];
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
	
	if( (c == NSCarriageReturnCharacter || c == NSEnterCharacter || c == NSDeleteCharacter) && currentTool == t3DCut)
	{
		long			tt, stackMax, stackOrientation, i;
		vtkPoints		*roiPts = ROI3DData->GetPoints();
		NSMutableArray	*ROIList = [NSMutableArray arrayWithCapacity:0];
		double			xyz[ 3], cameraProj[ 3], cameraProjObj[ 3];
		float			vector[ 9];
		
		textureMapper->SetRenderFlag( 1);
		
		if( roiPts->GetNumberOfPoints() < 3)
		{
			NSRunAlertPanel(NSLocalizedString(@"3D Cut", nil), NSLocalizedString(@"Draw an ROI on the 3D image and then press Return (include) or Delete (exclude) keys.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
		else
		{
			QDDisplayWaitCursor( true);
			NSLog(@"Scissor Start");
			[[[self window] windowController] prepareUndo];
			
			vtkMatrix4x4 *ActorMatrix = volume->GetUserMatrix();
			vtkTransform *Transform = vtkTransform::New();
			
			Transform->SetMatrix( ActorMatrix);
			Transform->Push();
			
			aCamera->GetViewPlaneNormal( cameraProj);
			aCamera->GetPosition( xyz);
			
			xyz[ 0] /= factor;
			xyz[ 1] /= factor;
			xyz[ 2] /= factor;
			
			[firstObject orientation: vector];
			
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
				case 0:		stackMax = [firstObject pwidth];		break;
				case 1:		stackMax = [firstObject pheight];		break;
				case 2:		stackMax = [pixList count];				break;
			}
			
			for( i = 0 ; i < stackMax ; i++)
				[ROIList addObject: [[[ROI alloc] initWithType: tCPolygon :[firstObject pixelSpacingX]*factor :[firstObject pixelSpacingY]*factor :NSMakePoint( [firstObject originX], [firstObject originY])] autorelease]];
				
			for( tt = 0; tt < roiPts->GetNumberOfPoints(); tt++)
			{
				float	point1[ 3], point2[ 3];
				long	x, y, z;
				
				double	point2D[ 3], *pp;
				
				roiPts->GetPoint( tt, point2D);
				aRenderer->SetDisplayPoint( point2D[ 0], point2D[ 1], 0);
				aRenderer->DisplayToWorld();
				pp = aRenderer->GetWorldPoint();
				
				pp[ 0] /= factor;
				pp[ 1] /= factor;
				pp[ 2] /= factor;
				
			//	NSLog(@"point: %f %f %f", pp[ 0], pp[ 1], pp[ 2]);
				
				if( aCamera->GetParallelProjection())
				{
					NSLog(@"Cam Proj: %f %f %f",cameraProj[ 0], cameraProj[ 1], cameraProj[ 2]);
					
					aCamera->GetPosition( xyz);
					
					xyz[ 0] = pp[0] + cameraProj[ 0];
					xyz[ 1] = pp[1] + cameraProj[ 1];
					xyz[ 2] = pp[2] + cameraProj[ 2];
									
					// Go beyond the object...
									
					pp[0] = xyz[ 0] + (pp[0]- xyz[ 0])  * 5000.0;
					pp[1] = xyz[ 1] + (pp[1]- xyz[ 1])  * 5000.0;
					pp[2] = xyz[ 2] + (pp[2]- xyz[ 2])  * 5000.0;
					
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
				
					point2[0] = xyz[ 0] + (pp[0]*5000.0) - xyz[ 0];
					point2[1] = xyz[ 1] + (pp[1]*5000.0) - xyz[ 1];
					point2[2] = xyz[ 2] + (pp[2]*5000.0) - xyz[ 2];		
				}
				
			//	NSLog( @"Start Pt : x=%f, y=%f, z=%f"	, point1[ 0], point1[ 1], point1[ 2]);
			//	NSLog( @"End Pt : x=%f, y=%f, z=%f"		, point2[ 0], point2[ 1], point2[ 2]);
							
				// Intersection between this line and planes in Z direction
				for( x = 0; x < stackMax; x++)
				{
					float	planeVector[ 3];
					float	point[ 3];
					float	resultPt[ 3];
					double	vPos[ 3];
					
					volume->GetPosition( vPos); // factor
//
					vPos[ 0] /= factor;
					vPos[ 1] /= factor;
					vPos[ 2] /= factor;
										
//					vPos[ 0] = [firstObject originX];
//					vPos[ 1] = [firstObject originY];
//					vPos[ 2] = [firstObject originZ];
					
					switch( stackOrientation)
					{
						case 0:
							point[ 0] = x * [firstObject pixelSpacingX];
							point[ 1] = 0;
							point[ 2] = 0;
														
							planeVector[ 0] =  vector[ 0];
							planeVector[ 1] =  vector[ 1];
							planeVector[ 2] =  vector[ 2];
						break;
						
						case 1:
							point[ 0] = 0;
							point[ 1] = x * [firstObject pixelSpacingY];
							point[ 2] = 0;
							
							planeVector[ 0] =  vector[ 3];
							planeVector[ 1] =  vector[ 4];
							planeVector[ 2] =  vector[ 5];
						break;
						
						case 2:
							point[ 0] = 0;
							point[ 1] = 0;
							point[ 2] = x * fabs( [firstObject sliceInterval]);
							
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
						
						tempPoint3D[0] /= [firstObject pixelSpacingX];
						tempPoint3D[1] /= [firstObject pixelSpacingY];
						tempPoint3D[2] /= fabs( [firstObject sliceInterval]);
						
					//	tempPoint3D[0] /= factor;
					//	tempPoint3D[1] /= factor;
					//	tempPoint3D[2] /= factor;
						
						ptInt[ 0] = (tempPoint3D[0] + 0.5);
						ptInt[ 1] = (tempPoint3D[1] + 0.5);
						ptInt[ 2] = (tempPoint3D[2] + 0.5);
						
						
						if( needToFlip) 
						{
							ptInt[ 2] = [pixList count] - ptInt[ 2] -1;
						}
						
//						if( ptInt[0] >= 0 && ptInt[0] < [firstObject pwidth] && ptInt[1] >= 0 && ptInt[1] < [firstObject pheight] &&  ptInt[ 2] >= 0 && ptInt[ 2] < [pixList count])
//						{						
//							// Test delete...
//							
//							float *src = [[pixList objectAtIndex: ptInt[ 2]] fImage];
//							*(src + (long) ptInt[1] * [firstObject pwidth] + (long) ptInt[0]) = 10000;
//						}
						
						switch( stackOrientation)
						{
							case 0:	
								roiID = ptInt[0];
								
								if( roiID >= 0 && roiID < stackMax)
									[[ [ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[1], ptInt[2])]];
							break;
							
							case 1:
								roiID = ptInt[1];
								
								if( roiID >= 0 && roiID < stackMax)
									[[ [ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[2])]];
							break;
							
							case 2:
								roiID = ptInt[2];
								
								if( roiID >= 0 && roiID < stackMax)
									[[ [ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[1])]];
							break;
						}
						//NSLog(@"Slide ID: %d", roiID);
					}
				}
			}
			
			Transform->Delete();
		}
		
		// Fill ROIs
		
		// Create a scheduler
		id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
		[sched setDelegate: self];
		
		// Create the work units. These can be anything. We will use NSNumbers
		NSMutableSet *unitsSet = [NSMutableSet set];
		for ( i = 0; i < stackMax; i++ )
		{
			[unitsSet addObject: [NSArray arrayWithObjects: [NSNumber numberWithInt:i], [NSNumber numberWithInt:stackOrientation], [NSNumber numberWithInt: c], [ROIList objectAtIndex: i], nil]];
		}
		// Perform work schedule
		[sched performScheduleForWorkUnits:unitsSet];
	}
	
	[super keyDown:event];
}

-(void) schedulerDidFinishSchedule: (Scheduler *)scheduler
{
	// Delete current ROI
	vtkPoints *pts = vtkPoints::New();
	vtkCellArray *rect = vtkCellArray::New();
	ROI3DData-> SetPoints( pts);		pts->Delete();
	ROI3DData-> SetLines( rect);		rect->Delete();
	
	//vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
	//[self setNeedsDisplay:YES];
	
	NSLog(@"Scissor End");
	QDDisplayWaitCursor( false);
	
	// Update everything..
	ROIUPDATE = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList userInfo: 0];

	[scheduler release];
}

-(void)performWorkUnits:(NSSet *)workUnits forScheduler:(Scheduler *)scheduler
{
	NSEnumerator *enumerator = [workUnits objectEnumerator];
	NSArray	*object;
	
	while (object = [enumerator nextObject])
	{
		[[[self window] windowController] applyScissor : object];
	}
}

- (IBAction) undo:(id) sender
{
	[[[self window] windowController] undo: sender];
}

-(void) setCurrentTool:(short) i
{
	long previousTool = currentTool;
	
    currentTool = i;
	
	if( currentTool != t3DRotate)
	{
		if( croppingBox->GetEnabled()) croppingBox->Off();
	}
	
	if( currentTool == t3DCut)
	{
		textureMapper->SetRenderFlag( 0);
	}
	else
	{
		textureMapper->SetRenderFlag( 1);
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
	
	if( currentTool == t3DCut && previousTool == t3DCut)
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
	
	[self setCursorForView: currentTool];
}

- (void) getWLWW:(float*) iwl :(float*) iww
{
    *iwl = wl;
    *iww = ww;
}

-(void) setBlendingWLWW:(float) iwl :(float) iww
{
    double newValues[2];
    
	blendingWl = iwl;
	blendingWw = iww;
	
//	vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);
		
    [self setNeedsDisplay:YES];
}

-(void) setBlendingFactor:(float) a
{
	long	i;
	float   val, ii;
	double  alpha[ 256];

	if( blendingController)
	{
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
				
				alpha[ i] = val / 255.;
			}
		}
		else
		{
			if( a == 256)
			{
				for(i=0; i < 256; i++)
				{
					alpha[ i] = 1.0;
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
					
					alpha[ i] = val / 255.0;
				}
			}
		}
		
		blendingOpacityTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &alpha);
		
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
				table[i][0] = r[i] / 255.;
				table[i][1] = g[i] / 255.;
				table[i][2] = b[i] / 255.;
			}
			blendingColorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
		}
		else
		{
			for( i = 0; i < 256; i++)
			{
				table[i][0] = i / 255.;
				table[i][1] = i / 255.;
				table[i][2] = i / 255.;
			}
			blendingColorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
		}
	}
    [self setNeedsDisplay:YES];
}

-(void) setOpacity:(NSArray*) array
{
	long		i;
	NSPoint		pt;
	
	opacityTransferFunction->RemoveAllPoints();
	
	if( [array count] > 0)
	{
		pt = NSPointFromString( [array objectAtIndex: 0]);
		pt.x -=1000;
		if(pt.x != 0) opacityTransferFunction->AddPoint(0, 0);
		else NSLog(@"start point");
	}
	else opacityTransferFunction->AddPoint(0, 0);
	
	for( i = 0; i < [array count]; i++)
	{
		pt = NSPointFromString( [array objectAtIndex: i]);
		pt.x -= 1000;
		opacityTransferFunction->AddPoint(pt.x, pt.y);
	}
	
	if( [array count] == 0 || pt.x != 256) opacityTransferFunction->AddPoint(255, 1);
	else
	{
		opacityTransferFunction->AddPoint(255, pt.y);
		NSLog(@"end point");
	}
	
	if( textureMapper) [self updateVolumePRO];
	
	[self setNeedsDisplay:YES];
}

-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long	i;

	if( r)
	{
		for( i = 0; i < 256; i++)
		{
			table[i][0] = r[i] / 255.;
			table[i][1] = g[i] / 255.;
			table[i][2] = b[i] / 255.;
		}
		colorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
	else
	{
		for( i = 0; i < 256; i++)
		{
			table[i][0] = i / 255.;
			table[i][1] = i / 255.;
			table[i][2] = i / 255.;
		}
		colorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
	
	if( textureMapper) [self updateVolumePRO];  
	
    [self setNeedsDisplay:YES];
}

- (void) setWLWW:(float) iwl :(float) iww
{
	if( iwl == 0 && iww == 0)
	{
		iwl = [[pixList objectAtIndex:0] fullwl];
		iww = [[pixList objectAtIndex:0] fullww];
	}
	
	wl = iwl;
	ww = iww;
	
//	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
		
	sprintf(WLWWString, "WL: %0.f WW: %0.f", wl, ww);
	textWLWW->SetInput( WLWWString);

	[self updateVolumePRO];
		
	[self setNeedsDisplay:YES];
}

-(void) bestRendering:(id) sender
{
	if( textureMapper) return;

	[splash setCancel:YES];
		
	// Best Rendering...
	if( croppingBox->GetEnabled()) croppingBox->Off();
	
//	aRenderer->RemoveActor(outlineRect);
	aRenderer->RemoveActor(textX);
	
	if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	{
		if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( 0.5);
		NSLog(@"resol = 0.5");
	}
	else
	{
		if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( 1.0);
		
		if( textureMapper)
		{
			textureMapper->SetSuperSampling( 1);
			textureMapper->SetSuperSamplingFactor(0.5, 0.5, 0.5);
			textureMapper->SetMaxWindow( 800);
		}
	}
	
	volumeProperty->SetInterpolationTypeToLinear();

	if( blendingController)
	{
		if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
		{
			if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( 0.5);
			NSLog(@"resol = 0.5");
		}
		else
		{
			if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( 1.0);
		}
		
		blendingVolumeProperty->SetInterpolationTypeToLinear();
	}
	
	[self display];
	
	// Standard Rendering...
	if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
	
	if( textureMapper)
	{
		textureMapper->SetSuperSampling( 1);
		textureMapper->SetSuperSamplingFactor( 1, 1, 1);
		textureMapper->SetMaxWindow( 256);
	//	textureMapper->GetContextPointer()->SetSamplingFactor( 0.2);
	//	textureMapper->GetContextPointer()->SetGradientInterpolationMode( kVLINearestNeighbor);
	//	textureMapper->GetContextPointer()->SetRayTermination( 0.5, VLItrue);
	}
	
	//volumeProperty->SetInterpolationTypeToNearest();

	if( blendingController)
	{
		if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		
		blendingVolumeProperty->SetInterpolationTypeToNearest();
	}
	
//	aRenderer->AddActor(outlineRect);
	aRenderer->AddActor(textX);
	
	[splash setCancel:NO];
	
	if( [splash aborted]) [self display];
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
		if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
		
		
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
		
		blendingSrcf.height = [blendingFirstObject pheight] * [blendingPixList count];
		blendingSrcf.width = [blendingFirstObject pwidth];
		blendingSrcf.rowBytes = [blendingFirstObject pwidth] * sizeof(float);
		
		blendingDst8.height = [blendingFirstObject pheight] * [blendingPixList count];
		blendingDst8.width = [blendingFirstObject pwidth];
		blendingDst8.rowBytes = [blendingFirstObject pwidth] * sizeof(char);
		
		blendingData8 = (char*) malloc( blendingDst8.height * blendingDst8.width * sizeof(char));
		
		blendingDst8.data = blendingData8;
		blendingSrcf.data = blendingData;
		
		blendingWl = [blendingFirstObject wl];
		blendingWw = [blendingFirstObject ww];
		
//		vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);
		
		blendingReader = vtkImageImport::New();
		blendingReader->SetWholeExtent(0, [blendingFirstObject pwidth]-1, 0, [blendingFirstObject pheight]-1, 0, [blendingPixList count]-1);
		blendingReader->SetDataExtentToWholeExtent();
		blendingReader->SetDataScalarTypeToUnsignedChar();
//		blendingReader->SetDataOrigin(  [blendingFirstObject originX],
//										[blendingFirstObject originY],
//										[blendingFirstObject originZ]);
		blendingReader->SetImportVoidPointer(blendingData8);
		blendingReader->SetDataSpacing( factor*[blendingFirstObject pixelSpacingX], factor*[blendingFirstObject pixelSpacingY], factor*blendingSliceThickness);
//		blendingReader->SetTransform( );
		
//		tester vtkImageReader avec setTransform!!!
//		vtkI


		
//		vtkPlaneWidget  *aplaneWidget = vtkPlaneWidget::New();
//		aplaneWidget->SetOrigin( [blendingFirstObject originX], [blendingFirstObject originY], [blendingFirstObject originZ]);
//		aplaneWidget->SetNormal( normal[0], normal[1], normal[2] );
//		aplaneWidget->SetResolution(10);
//		aplaneWidget->PlaceWidget();
//		aplaneWidget->SetInteractor( [self renderWindowInteractor]);
		
//		vtkTransform	*rotation = vtkTransform::New();
//		rotation->RotateX( R2D*acos( normal[0]));
//		rotation->RotateY( R2D*acos( normal[0]));
//		rotation->RotateZ( R2D*acos( normal[0]));
//		rotation->SetInput( blendingReader->GetOutput());


		blendingColorTransferFunction = vtkColorTransferFunction::New();
		[self setBlendingCLUT:nil :nil :nil];
		
		blendingOpacityTransferFunction = vtkPiecewiseFunction::New();
		[self setBlendingFactor:blendingFactor];
		blendingOpacityTransferFunction->AddPoint(0, 0);
		blendingOpacityTransferFunction->AddPoint(255, 1);
		
		blendingVolumeProperty = vtkVolumeProperty::New();
		blendingVolumeProperty->SetColor( blendingColorTransferFunction);
		blendingVolumeProperty->SetScalarOpacity( blendingOpacityTransferFunction);
	//    volumeProperty->ShadeOn();
		blendingVolumeProperty->SetInterpolationTypeToNearest();
		
	//	vtkVolumeRayCastCompositeFunction  *compositeFunction = vtkVolumeRayCastCompositeFunction::New();
		blendingCompositeFunction = vtkVolumeRayCastCompositeFunction::New();
		
//		blendingVolumeMapper = vtkVolumeRayCastMapper::New();		//vtkVolumeRayCastMapper
//		blendingVolumeMapper->SetVolumeRayCastFunction( blendingCompositeFunction);
//		blendingVolumeMapper->SetInput( blendingReader->GetOutput());
//	//	blendingVolumeMapper->SetSampleDistance( 12.0);
		
		LOD = 4.0;
//		blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		
		blendingVolume = vtkVolume::New();
		blendingVolume->SetProperty( blendingVolumeProperty);
		
		[self setBlendingEngine: 1];
		
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
//		cropcallback->Execute(croppingBox, 0, nil);
		
	    aRenderer->AddVolume( blendingVolume);
	}
	else
	{
		if( blendingVolume)
		{
			aRenderer->RemoveVolume( blendingVolume);
			
			blendingVolume->Delete();
			blendingVolume = nil;
			
			if( blendingVolumeMapper) blendingVolumeMapper->Delete();
			if( blendingTextureMapper) blendingTextureMapper->Delete();
			
			blendingCompositeFunction->Delete();
			blendingVolumeProperty->Delete();
			blendingColorTransferFunction->Delete();
			blendingReader->Delete();
			free(blendingData8);
			
			[blendingPixList release];
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
		blendingSrcf.data = blendingData;
		
		vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);
		if( needToFlip)
		{
			[self flipData: (char*) blendingDst8.data :[blendingPixList count] :[blendingFirstObject pheight] * [blendingFirstObject pwidth]];
		}
		
		[self setNeedsDisplay:YES];
	}
}

-(void) movieChangeSource:(float*) volumeData
{
	data = volumeData;
	
	srcf.height = [firstObject pheight] * [pixList count];
	srcf.width = [firstObject pwidth];
	srcf.rowBytes = [firstObject pwidth] * sizeof(float);
	
	dst8.height = [firstObject pheight] * [pixList count];
	dst8.width = [firstObject pwidth];
	dst8.rowBytes = [firstObject pwidth] * sizeof(short);
	
	dst8.data = data8;
	srcf.data = data;

	vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16,  1, 0);

	if( needToFlip)
	{
		[self flipData: (char*)dst8.data :[pixList count] :[firstObject pheight] * [firstObject pwidth] * 2L];
	}

	if( textureMapper)
	{
		textureMapper->GetInput()->Modified();
	}
		
	[self updateVolumePRO];
	
	[self setNeedsDisplay:YES];
}

- (void) ViewFrameDidChangeNotification:(NSNotification*) note
{
	if( textWLWW)
	{
		int *wsize = [self renderWindow]->GetSize();
		textWLWW->GetPositionCoordinate()->SetValue( 2., wsize[ 1]-11);
	}
}

-(short) setPixSource:(NSMutableArray*)pix :(float*) volumeData
{
	short   error = 0;
	long	i;
    
	projectionMode = 1;

	
    [pix retain];
    pixList = pix;
	
	data = volumeData;
	
	aRenderer = [self renderer];
//	cbStart = vtkCallbackCommand::New();
//	cbStart->SetCallback( startRendering);
//	cbStart->SetClientData( self);
	
	//vtkCommand.h
//	[self renderWindow]->AddObserver(vtkCommand::StartEvent, cbStart);
//	[self renderWindow]->AddObserver(vtkCommand::EndEvent, cbStart);
//	[self renderWindow]->AddObserver(vtkCommand::AbortCheckEvent, cbStart);

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
	
	// Convert float to short
	
	srcf.height = [firstObject pheight] * [pix count];
	srcf.width = [firstObject pwidth];
	srcf.rowBytes = [firstObject pwidth] * sizeof(float);
	
	dst8.height = [firstObject pheight] * [pix count];
	dst8.width = [firstObject pwidth];
//	dst8.rowBytes = [firstObject pwidth] * sizeof(char);
	dst8.rowBytes = [firstObject pwidth] * sizeof(short);
	
//	data8 = (char*) malloc( dst8.height * dst8.width * sizeof(char));
	data8 = (char*) malloc( dst8.height * dst8.width * sizeof(short));
	if( data8 == nil)
	{
		[pix release];
		return -1;
	}
	dst8.data = data8;
	
	if( isRGB) srcf.data = dataFRGB;
	else srcf.data = data;
	
//	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
	
//	unsigned short *us = (unsigned short*) data8;
//	
//	for( i = 0; i < dst8.height * dst8.width; i++)
//	{
//		us[ i] = data[ i] + OFFSET16;
//	}
	
	vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16,  1, 0);
	
	/// VOLUMEPRO TEST
	
//	NSLog( @"VPRO: %d", VLIOpen());
//	
//	NSLog( @"No of boards: %d", VLIConfiguration::GetNumberOfBoards());
//	
//	NSLog( @"Memory: %d", VLIConfiguration::GetAvailableMemory( 0));
//	
//	VLIVolume	*m_volume = VLIVolume::Create( 8, [firstObject pwidth], [firstObject pheight], [pixList count], 0, 0, data8);
//
//	m_volume->SetFieldDescriptor(kVLIField0, VLIFieldDescriptor(0, 8, kVLIUnsignedFraction));
//										 
//	m_volume->LockVolume(); // Create a context with all parameters defaulted
//	
//	VLIContext	*m_context = VLIContext::Create(); // Add a light to the context VLIVector3D direction (-0.5, -0.5, -1.0);
//	
//	
//	VLILookupTable	*LookupTable = VLILookupTable::Create(VLILookupTable::kSize4096);
//	
//	float scale = 255.0 / 4095.0, val;
//  VLIuint8                  rgbTable[4096][3];
//  VLIuint16                 aTable[4096];
//  
//	for ( i= 0; i< 4096; i++)
//        {
//        val = 0.5 + ( i*scale)*255.0;
//        val = (val < 0)?(0):(val);
//        val = (val > 255)?(255):(val);
//        rgbTable[i][0] = rgbTable[i][1] = rgbTable[i][2]  = static_cast<unsigned char>( val );
//        
//        val = 0.5 + 4095.0 * (i)*scale;
//        val = (val < 0)?(0):(val);
//        val = (val > 4095)?(4095):(val);
//        aTable[i] = static_cast<unsigned short>( val );
//        }
//		
//	LookupTable->SetColorEntries( 0, 4096, rgbTable );
//	
//	m_context->GetClassifier().SetLookupTable(kVLITable0, LookupTable);
//
////	VLICutPlane	*Cut = VLICutPlane::Create( 1.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
//	
//	
//	VLIVector3D direction (-0.5, -0.5, -1.0); 
//	VLILight	*light = VLILight::CreateDirectional(direction);
//	
//	m_context->AddLight(light);
//	
//	
//	m_context->GetCamera().SetViewport(0, 0, 2000, 2000); 
//
//	static VLIFieldDescriptor fields[4];
//
//		fields[0] = VLIFieldDescriptor (0, 8);		// red
//		fields[1] = VLIFieldDescriptor (8,  8);		// green
//		fields[2] = VLIFieldDescriptor (16,  8);		// blue
//		fields[3] = VLIFieldDescriptor (24, 8);		// alpha
//
//	VLILocation loc = m_volume->GetBufferLocation();
//
////	VLIImageBuffer	*m_image0 = VLIImageBuffer::Create(loc, 512, 512, 32, 4, fields); 
//	VLIDepthBuffer	*m_depth0 = VLIDepthBuffer::Create(loc, 2000, 2000); 
//	
//	VLIImageBuffer	*m_image0 = VLIImageBuffer::Create(kVLIBoard0, 2000, 2000, 32, 4, fields);
//    m_image0->SetBorderValue(0, 0, 0, 0);
//	
//	m_volume->Render(m_context, m_image0); 
//	
//	VLIuint32 * pdata = 0;
//	
//	pdata = malloc( 2000*2000*4);
//	
//	for( i = 0 ; i < 2000*2000; i++)
//	{
//		pdata[ i] = i;
//	}
//	
//	m_image0->Unload (pdata, m_image0->GetOutputLimits());
//	
//
//	NSBitmapImageRep *rep;
//          // STEP 1: Initialize a place to put the pixels.
//		rep = [[[NSBitmapImageRep alloc]
//		 initWithBitmapDataPlanes:nil
//					   pixelsWide:2000
//					   pixelsHigh:2000
//					bitsPerSample:8
//				  samplesPerPixel:4
//						 hasAlpha:YES
//						 isPlanar:NO
//				   colorSpaceName:NSCalibratedRGBColorSpace
//					  bytesPerRow:2000*4
//					 bitsPerPixel:32] autorelease];
//					 
//	BlockMoveData( pdata, [rep bitmapData], 2000*2000*4);
//	
//	NSImage *image = [[NSImage alloc] init];
//	[image addRepresentation:rep];
//	
//	NSArray		*representations;
//	NSData		*bitmapData;
//	
//	representations = [image representations];
//	
//	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
//	
//	[bitmapData writeToFile:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP/VPRO.jpg"] atomically:YES];
//	
//	[image release];
	
	// ******************
	
	
//	unsigned short* data16 = ( unsigned short*) malloc( [firstObject pwidth]*[firstObject pheight] * [pix count] * sizeof(unsigned short));
//	
//	for (int i=0;i<[firstObject pwidth]*[firstObject pheight]* [pix count];i++)
//	{
//			
//		data16[i] = data[i];
//	}
	
	
	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);
	reader->SetDataExtentToWholeExtent();
	
//	if( isRGB)
//	{
//		reader->SetDataScalarTypeToUnsignedChar();
//		reader->SetNumberOfScalarComponents( 3);
//		reader->SetImportVoidPointer(dataFRGB);
//	}
//	else 
	{
		reader->SetNumberOfScalarComponents( 1);
		
//		reader->SetDataScalarTypeToUnsignedChar();
//		reader->SetImportVoidPointer(data8);

		reader->SetDataScalarTypeToUnsignedShort();
		reader->SetImportVoidPointer(data8);
	}
	
//	sliceThickness= fabs( sliceThickness);
	
	if( sliceThickness < 0 )
	{
		needToFlip = YES;
		[self flipData: (char*)dst8.data :[pixList count] :[firstObject pheight] * [firstObject pwidth] * 2L];
		
		[[pixList lastObject] setSliceInterval: [firstObject sliceInterval]];
		firstObject = [pixList lastObject];
	}
	else needToFlip = NO;
	
	sliceThickness = fabs(sliceThickness);
	
	[firstObject orientation:cosines];
	
//	float invThick;
	
//	if( cosines[6] + cosines[7] + cosines[8] < 0) invThick = -1;
//	else invThick = 1;
	
	factor = 1.0;
//	if( [firstObject pixelSpacingX] < 0.5 || [firstObject pixelSpacingY] < 0.5 || sliceThickness < 0.5) factor = 10;
	
	NSLog(@"Thickness: %2.2f Factor: %2.2f", sliceThickness, factor);
	
//	if( sliceThickness < 0 )
//	{
//		flip = vtkImageFlip::New();
//		flip->SetInput( reader->GetOutput());
//		flip->SetFlipAboutOrigin( TRUE);
//		flip->SetFilteredAxis(2);
//		sliceThickness = fabs( sliceThickness);
//	}
//	else flip = nil;
	
//	reader->SetDataSpacing( 1, 1, sliceThickness);
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
	[self setCLUT:nil :nil :nil];
	
	volumeProperty = vtkVolumeProperty::New();
    volumeProperty->SetColor( colorTransferFunction);
	volumeProperty->SetScalarOpacity( opacityTransferFunction);
	volumeProperty->SetShade( 1);
	[self setShadingValues:0.2 :0.8 :0.5 :10];

//	volumeProperty->ShadeOn();
    volumeProperty->SetInterpolationTypeToNearest();
	
	compositeFunction = vtkVolumeRayCastCompositeFunction::New();
//	compositeFunction->SetCompositeMethodToClassifyFirst();
//	compositeFunction = (vtkVolumeRayCastCompositeFunction*) vtkVolumeRayCastMIPFunction::New();
	
	LOD = 4.0;
	
	volume = vtkVolume::New();
    volume->SetProperty( volumeProperty);
	
	[self setEngine: 1];
	
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
	
	outlineData = vtkOutlineFilter::New();
	outlineData->SetInput((vtkDataSet *) reader->GetOutput());
	
    mapOutline = vtkPolyDataMapper::New();
    mapOutline->SetInput(outlineData->GetOutput());
    
//    outlineRect = vtkActor::New();
//    outlineRect->SetMapper(mapOutline);
//    outlineRect->GetProperty()->SetColor(0,1,0);
//    outlineRect->GetProperty()->SetOpacity(0.5);
//	outlineRect->SetUserMatrix( matrice);
//	outlineRect->SetPosition(	factor*[firstObject originX] * matrice->Element[0][0] + factor*[firstObject originY] * matrice->Element[1][0] + factor*[firstObject originZ]*matrice->Element[2][0],
//								factor*[firstObject originX] * matrice->Element[0][1] + factor*[firstObject originY] * matrice->Element[1][1] + factor*[firstObject originZ]*matrice->Element[2][1],
//								factor*[firstObject originX] * matrice->Element[0][2] + factor*[firstObject originY] * matrice->Element[1][2] + factor*[firstObject originZ]*matrice->Element[2][2]);

//	outlineRect->SetPosition(	[firstObject originX],
//								[firstObject originY],
//								[firstObject originZ]);

	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontShow3DCubeOrientation"] == NO)
	{
		vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
		cube->SetXPlusFaceText ( [NSLocalizedString( @"L", @"L: Left") UTF8String] );		
		cube->SetXMinusFaceText( [NSLocalizedString( @"R", @"R: Right") UTF8String] );
		cube->SetYPlusFaceText ( [NSLocalizedString( @"P", @"P: Posterior") UTF8String] );
		cube->SetYMinusFaceText( [NSLocalizedString( @"A", @"A: Anterior") UTF8String] );
		cube->SetZPlusFaceText ( [NSLocalizedString( @"S", @"S: Superior") UTF8String] );
		cube->SetZMinusFaceText( [NSLocalizedString( @"I", @"I: Inferior") UTF8String] );
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

		cube->SetTextEdgesVisibility( 1);
		cube->SetCubeVisibility( 1);
		cube->SetFaceTextVisibility( 1);

		orientationWidget = vtkOrientationMarkerWidget::New();
		orientationWidget->SetOrientationMarker( cube );
		orientationWidget->SetInteractor( [self getInteractor] );
		orientationWidget->SetViewport( 0.90, 0.90, 1, 1);
		orientationWidget->SetEnabled( 1 );
		orientationWidget->InteractiveOff();
		cube->Delete();
	}
	
	croppingBox = vtkBoxWidget::New();
	croppingBox->GetHandleProperty()->SetColor(0, 1, 0);
	
	croppingBox->SetProp3D(volume);
	croppingBox->SetPlaceFactor( 1.0);
	croppingBox->SetHandleSize( 0.005);
	croppingBox->PlaceWidget();
    croppingBox->SetInteractor( [self getInteractor]);
	croppingBox->SetRotationEnabled( false);
	croppingBox->SetInsideOut( true);
	croppingBox->OutlineCursorWiresOff();
	
//	double origin[ 3];
//	double size[ 3];
//	volume->GetPosition( origin);
//	
//	size[ 0] = factor*[firstObject pwidth]*[firstObject pixelSpacingX] * matrice->Element[0][0] + factor*[firstObject pheight]*[firstObject pixelSpacingY] * matrice->Element[1][0] + factor*sliceThickness*[pixList count]*matrice->Element[2][0];
//	size[ 1] = factor*[firstObject pwidth]*[firstObject pixelSpacingX] * matrice->Element[0][1] + factor*[firstObject pheight]*[firstObject pixelSpacingY] * matrice->Element[1][1] + factor*sliceThickness*[pixList count]*matrice->Element[2][1];
//	size[ 2] = factor*[firstObject pwidth]*[firstObject pixelSpacingX] * matrice->Element[0][2] + factor*[firstObject pheight]*[firstObject pixelSpacingY] * matrice->Element[1][2] + factor*sliceThickness*[pixList count]*matrice->Element[2][2];
//
//	size[ 0] = [firstObject pwidth]*[firstObject pixelSpacingX];
//	size[ 1] = [firstObject pheight]*[firstObject pixelSpacingY];
//	size[ 2] = sliceThickness*[pixList count];
	
//	origin[ 0] = 0;
//	origin[ 1] = 0;
//	origin[ 2] = 0;
	
//	vtkMatrix4x4 *ActorMatrix = volume->GetUserMatrix();
//			vtkTransform *Transform = vtkTransform::New();
//			
//			Transform->SetMatrix( ActorMatrix);
//			Transform->Push();
//
//	croppingBox->SetTransform( Transform);
//	croppingBox->PlaceWidget( origin[ 0], origin[ 0] + size[ 0], origin[ 1], origin[ 1] + size[ 1], origin[ 2], origin[ 2] + size[ 2]);
	
	cropcallback = vtkMyCallbackVP::New();
	cropcallback->setBlendingVolume( nil);
	croppingBox->AddObserver(vtkCommand::InteractionEvent, cropcallback);
	
/*	planeWidget = vtkPlaneWidget::New();
	
	planeWidget->GetHandleProperty()->SetColor(0, 0, 1);
	planeWidget->SetHandleSize( 0.005);
	planeWidget->SetProp3D(volume);
	planeWidget->SetResolution( 1);
	planeWidget->SetPoint1(-50, -50, -50);
	planeWidget->SetPoint2(50, 50, 50);
	planeWidget->PlaceWidget();
	planeWidget->SetRepresentationToWireframe();
    planeWidget->SetInteractor( [self renderWindowInteractor]);
	planeWidget->On();
	vtkPlaneCallback *planecallback = vtkPlaneCallback::New();
	planeWidget->AddObserver(vtkCommand::InteractionEvent, planecallback);
*/	

//	vtkScalarBarActor	*scalarBar = vtkScalarBarActor::New();
//	scalarBar->SetLookupTable( colorTransferFunction);
//	scalarBar->SetTitle("CLUT");
//	scalarBar->SetOrientationToHorizontal();
//	scalarBar->GetPositionCoordinate()->SetCoordinateSystemToNormalizedViewport();
//	scalarBar->GetPositionCoordinate()->SetValue( 0.1, 0.01);
//	scalarBar->SetWidth( 0.8);
//	scalarBar->SetHeight(0.17);
//	scalarBar->SetMaximumNumberOfColors(256);
//	aRenderer->AddActor2D(scalarBar);

//	vtkTextMapper *textMapper = vtkTextMapper::New();
//	textMapper->SetInput( "WL: 287 WW: 890");
//	textMapper->GetTextProperty()->SetFontSize( 12);
//	textMapper->GetTextProperty()->SetFontFamilyToArial();
	textWLWW = vtkTextActor::New();
	sprintf(WLWWString, "WL: %0.f WW: %0.f", wl, ww);
	textWLWW->SetInput( WLWWString);
	textWLWW->SetScaledText( false);
	textWLWW->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
	textWLWW->GetPositionCoordinate()->SetValue( 0,0);
	aRenderer->AddActor2D(textWLWW);
	
	textX = vtkTextActor::New();
	textX->SetInput( "X");
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
//		oText[ i]->GetTextProperty()->SetShadow( true);
		
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

//    aCamera->ComputeViewPlaneNormal();    
    
	aCamera->Dolly(1.5);
	
    aRenderer->AddVolume( volume);
//	aRenderer->AddActor(outlineRect);

	aRenderer->SetActiveCamera(aCamera);
	aRenderer->ResetCamera();
	
//	[self renderWindow]->StereoRenderOn();
//	[self renderWindow]->SetStereoTypeToRedBlue();
	
	[self setEngine: 1];
	
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
	ROI3DActor->GetProperty()->SetPointSize( 5);	//vtkProperty2D
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
//	Line2DText->GetTextProperty()->SetShadow( YES);
	
	aRenderer->AddActor2D( Line2DActor);
	
	[self saView:self];
	
	GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
	[self getVTKRenderWindow]->MakeCurrent();
	[[NSOpenGLContext currentContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];

	[self updateVolumePRO];
	
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

-(NSImage*) nsimageQuicktime
{
	NSImage *theIm;

	if( croppingBox->GetEnabled()) croppingBox->Off();
	
//	aRenderer->RemoveActor(outlineRect);
	aRenderer->RemoveActor(textX);
	aRenderer->RemoveActor(textWLWW);
	
	if( bestRenderingMode)
	{
		if( volumeMapper)
		{
			volumeMapper->SetMinimumImageSampleDistance( 1.0);
		}
		
		if( textureMapper)
		{
			textureMapper->SetSuperSampling( 1);
			textureMapper->SetSuperSamplingFactor(0.5, 0.5, 0.5);
		}
		
		volumeProperty->SetInterpolationTypeToLinear();
		
		if( blendingController)
		{
			blendingVolumeMapper->SetMinimumImageSampleDistance( 1.0);
			blendingVolumeProperty->SetInterpolationTypeToLinear();
		}
	}
	
	noWaitDialog = YES;
	[self display];
	noWaitDialog = NO;
	
	theIm = [self nsimage:YES];
	
	if( bestRenderingMode)
	{
		if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
	
		if( textureMapper)
		{
		//	textureMapper->SetSuperSampling( 1);
		//	textureMapper->SetSuperSamplingFactor( 1, 1, 1);
		}
		
		volumeProperty->SetInterpolationTypeToNearest();

		if( blendingController)
		{
			blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
			blendingVolumeProperty->SetInterpolationTypeToNearest();
		}
	}
	
//	aRenderer->AddActor(outlineRect);
	aRenderer->AddActor(textX);
	aRenderer->AddActor(textWLWW);
	
	return theIm;
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	unsigned char	*buf = nil;
	long			i;

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
//		[[NSOpenGLContext currentContext] flushBuffer];
		
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
				memcpy(buf + (*height - 1 - i)*rowBytes,  buf + i*rowBytes, rowBytes);
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
		
//		[[NSOpenGLContext currentContext] flushBuffer];
		[NSOpenGLContext clearCurrentContext];
	}
	
	return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
	NSBitmapImageRep	*rep;
	long				width, height, i, spp, bpp;
	NSString			*colorSpace;
	unsigned char		*dataPtr;
	
	dataPtr = [self getRawPixels :&width :&height :&spp :&bpp :!originalSize : YES];
	
	if( spp == 3) colorSpace = NSCalibratedRGBColorSpace;
	else colorSpace = NSCalibratedWhiteColorSpace;
	
	rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:nil
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
	
//	//Add the small OsiriX logo at the bottom right of the image
//	NSImage				*logo = [NSImage imageNamed:@"SmallLogo.tif"];
//	NSBitmapImageRep	*TIFFRep = [[NSBitmapImageRep alloc] initWithData: [logo TIFFRepresentation]];
//	
//	for( i = 0; i < [TIFFRep pixelsHigh]; i++)
//	{
//		unsigned char	*srcPtr = ([TIFFRep bitmapData] + i*[TIFFRep bytesPerRow]);
//		unsigned char	*dstPtr = ([rep bitmapData] + (height - [TIFFRep pixelsHigh] + i)*[rep bytesPerRow] + ((width-10)*3 - [TIFFRep bytesPerRow]));
//		
//		long x = [TIFFRep bytesPerRow]/3;
//		while( x-->0)
//		{
//			if( srcPtr[ 0] != 0 || srcPtr[ 1] != 0 || srcPtr[ 2] != 0)
//			{
//				dstPtr[ 0] = srcPtr[ 0];
//				dstPtr[ 1] = srcPtr[ 1];
//				dstPtr[ 2] = srcPtr[ 2];
//			}
//			
//			dstPtr += 3;
//			srcPtr += 3;
//		}
//	}
//	
//	[TIFFRep release];

	
     NSImage *image = [[[NSImage alloc] init] autorelease];
     [image addRepresentation:rep];
     
	 free( dataPtr);
	 
    return image;
}

-(void) switchOrientationWidget:(id) sender
{
	long i;
	
	if( orientationWidget)
	{
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
		[[[[self window] windowController] toolsMatrix] selectCellWithTag: t3DRotate];
	}
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
	WaitRendering	*waiting = nil;
	
	switch( [[sender selectedCell] tag])
	{
		case 2:
			[[NSFileManager defaultManager] removeFileAtPath: str handler: nil];
		break;
		
		case 1:	// Load
			waiting = [[WaitRendering alloc] init:@"Loading 3D object..."];
			[waiting showWindow:self];
			
			volumeData = [[NSData alloc] initWithContentsOfFile:str];
			
			if( volumeData)
			{
				if( [volumeData length] == volumeSize)
				{
					memcpy( data, [volumeData bytes], volumeSize);
					[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList userInfo: 0];
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

-(IBAction) copy:(id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    NSImage *im;
    
    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    
    im = [self nsimage:NO];
    
    [pb setData: [im TIFFRepresentation] forType:NSTIFFPboardType];
}

- (IBAction) resetImage:(id) sender
{
	aCamera->SetViewUp (0, 1, 0);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, 1);
	aCamera->SetRoll(180);
//	aCamera->SetParallelProjection( true);
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();
	[self saView:self];
    [self setNeedsDisplay:YES];
}

// joris' modifications for fly thru

- (Camera*) camera
{
	// data extraction from the vtkCamera
	
	double pos[3], focal[3], vUp[3];
	
	aCamera->GetPosition(pos);
	aCamera->GetFocalPoint(focal);
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
	
	[VRPROView getCroppingBox: a :volume :croppingBox];
	
	[cam setMinCroppingPlanes: [[[Point3D alloc] initWithValues:a[0] :a[2] :a[4]] autorelease]];
	[cam setMaxCroppingPlanes: [[[Point3D alloc] initWithValues:a[1] :a[3] :a[5]] autorelease]];

	// fusion percentage
	[cam setFusionPercentage:blendingFactor];

	[cam setPreviewImage: [self nsimage:TRUE]];
	
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
	
	[VRPROView setCroppingBox: a :volume];
	
	double origin[3];
	volume->GetPosition(origin);	//GetOrigin		
	a[0] += origin[0];		a[1] += origin[0];
	a[2] += origin[1];		a[3] += origin[1];
	a[4] += origin[2];		a[5] += origin[2];
	croppingBox->PlaceWidget(a[0], a[1], a[2], a[3], a[4], a[5]);
	
	// fusion percentage
	[self setBlendingFactor:[cam fusionPercentage]];
	
	aCamera->SetPosition(pos);
	aCamera->SetFocalPoint(focal);
	aCamera->SetViewUp(vUp);
	//aCamera->SetClippingRange(clippingRange);
	aCamera->SetViewAngle(viewAngle);
	aCamera->SetEyeAngle(eyeAngle);
	aCamera->SetParallelScale(parallelScale);
	aRenderer->ResetCameraClippingRange();
}

- (void) setLowResolutionCamera: (Camera*) cam
{
	if( textureMapper)
	{
		textureMapper->SetSuperSampling( 0);
		textureMapper->SetSuperSamplingFactor( 1, 1, 1);
		textureMapper->SetMaxWindow( 256);
	}
	
	[self setCamera: cam];
	
	[[self window] display];
	
	if( textureMapper)
	{
		textureMapper->SetSuperSampling( 1);
		textureMapper->SetSuperSamplingFactor( 0.5, 0.5, 0.5);
		textureMapper->SetMaxWindow( 800);
	}
}

- (void)changeColorWith:(NSColor*) color
{
	if( color)
	{
		//change background color
		aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
		[self setNeedsDisplay:YES];
	}
}

- (void)changeColor:(id)sender{
	//change background color
	NSColor *color= [(NSColorPanel*)sender color];
	aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
	[self setNeedsDisplay:YES];
}

- (long) offset
{
	return OFFSET16;
}

- (float) valueFactor
{
	return 1.0;
}

#pragma mark-
#pragma mark Cursors

//cursor methods

- (void)mouseEntered:(NSEvent *)theEvent
{
	cursorSet = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	cursorSet = NO;
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    [cursor set];
}

- (void) checkCursor
{
	if(cursorSet) [cursor set];
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
	else if (tool == tWL)
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
		c = [NSCursor crosshairCursor];
	else	
		c = [NSCursor arrowCursor];
		
	if( c != cursor)
	{
		[cursor release];
		cursor = [c retain];
	}
}

-(void) squareView:(id) sender
{
	NSLog(@"%d", [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"]);
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 1) return;
	
	NSRect	newFrame = [self frame];
	NSRect	beforeFrame = [self frame];
	
	int		border = [self frame].size.height-1;
	
	if( border > [self frame].size.width) border = [self frame].size.width;
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 2) border = 512;
	if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 3) border = 768;
	
	newFrame.size.width = border;
	newFrame.size.height = border;

	newFrame.origin.x = (int) ((beforeFrame.size.width - border) / 2);
	newFrame.origin.y = (int) (10 + (beforeFrame.size.height - border) / 2);
	
	[self setFrame: newFrame];
	
	[[self window] display];
}

@end
