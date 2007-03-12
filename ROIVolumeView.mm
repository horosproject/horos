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

#import "ROIVolumeView.h"
#import "DCMPix.h"
#import "DCMView.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#import "QuicktimeExport.h"

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

@implementation ROIVolumeView

- (void) CloseViewerNotification: (NSNotification*) note
{

}

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame] )
    {
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
    }
    
    return self;
}

-(void)dealloc
{	
    NSLog(@"Dealloc ROIVolumeView");
		
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
    [super dealloc];
}

/* Nothing to do
- (void)finalize {
}
*/

- (short) setPixSource:(NSMutableArray*)pts
{
	short   error = 0;
	long	i;
	
	aRenderer = [self renderer];
	
	vtkPoints *points = vtkPoints::New();
	
	for( i = 0; i < [pts count]; i++)
	{
		NSArray	*pt3D = [pts objectAtIndex: i];
		points->InsertPoint( i, [[pt3D objectAtIndex: 0] floatValue], [[pt3D objectAtIndex: 1] floatValue], [[pt3D objectAtIndex: 2] floatValue]);
	}

	vtkPolyData *profile = vtkPolyData::New();
    profile->SetPoints( points);
	points->Delete();
	
	// Delaunay3D is used to triangulate the points. The Tolerance is the distance
	// that nearly coincident points are merged together. (Delaunay does better if
	// points are well spaced.) The alpha value is the radius of circumcircles,
	// circumspheres. Any mesh entity whose circumcircle is smaller than this
	// value is output.
	
	//vtkGaussian
	//vtkSurfaceReconstructionFilter
	//vtkContourFilter
	
	// vtkDelaunay3D
	
	vtkDelaunay3D *del = vtkDelaunay3D::New();
		del->SetInput( profile);
		del->SetTolerance( 0.001);
		del->SetAlpha( 20);
		del->BoundingTriangulationOff();
	profile->Delete();
	
	vtkDataSetMapper *map = vtkDataSetMapper::New();
		map->SetInput( (vtkDataSet*) del->GetOutput());
	del->Delete();
	
	//  vtkSurfaceReconstructionFilter

//	vtkSurfaceReconstructionFilter *surf = vtkSurfaceReconstructionFilter::New();
//	surf->SetInput( profile);
//
//	vtkContourFilter *cf = vtkContourFilter::New();
//	cf->SetInput( surf->GetOutput());
//	cf->SetValue( 0, 0.0);
//	surf->Delete();
//
//	vtkReverseSense *reverse = vtkReverseSense::New();
//	reverse->SetInput( cf->GetOutput());
//	reverse->ReverseCellsOn();
//	reverse->ReverseNormalsOn();
//
//	vtkPolyDataMapper *popMapper = vtkPolyDataMapper::New();
//	popMapper->SetInput(cf->GetOutput());
//	popMapper->ScalarVisibilityOff();
//
//	cf->Delete();


	vtkActor *triangulation = vtkActor::New();
		triangulation->SetMapper( map);
		triangulation->GetProperty()->SetColor(1, 0, 0);
		triangulation->GetProperty()->SetSpecular( 0.3);
		triangulation->GetProperty()->SetSpecularPower( 20);
		triangulation->GetProperty()->SetAmbient( 0.2);
		triangulation->GetProperty()->SetDiffuse( 0.8);
		triangulation->GetProperty()->SetOpacity(0.5);
	map->Delete();
	
	// The balls
	
	vtkSphereSource *ball = vtkSphereSource::New();
		ball->SetRadius(0.3);
		ball->SetThetaResolution( 12);
		ball->SetPhiResolution( 12);
	
	vtkGlyph3D *balls = vtkGlyph3D::New();
		balls->SetInput( (vtkDataObject*) del->GetOutput());
		balls->SetSource( ball->GetOutput());
	ball->Delete();
	
	vtkPolyDataMapper *mapBalls = vtkPolyDataMapper::New();
		mapBalls->SetInput( balls->GetOutput());
	balls->Delete();
	
	vtkActor *ballActor = vtkActor::New();
		ballActor->SetMapper( mapBalls);
		ballActor->GetProperty()->SetSpecular( 0.5);
		ballActor->GetProperty()->SetSpecularPower( 20);
		ballActor->GetProperty()->SetAmbient( 0.2);
		ballActor->GetProperty()->SetDiffuse( 0.8);
		ballActor->GetProperty()->SetOpacity( 0.8);
	mapBalls->Delete();
	
	aRenderer->AddActor( ballActor);
	ballActor->Delete();
	
	aRenderer->AddActor( triangulation);
	triangulation->Delete();
	
    aCamera = vtkCamera::New();
	aCamera->Zoom(1.5);
	
	aRenderer->SetActiveCamera(aCamera);
	
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();
	
	aCamera->Delete();
	
	return error;
}

- (void) setROIActorVolume:(NSValue*)roiActorPointer
{
	aRenderer = [self renderer];
	
	aRenderer->AddActor((vtkActor*)[roiActorPointer pointerValue]);
	
    aCamera = vtkCamera::New();
	aCamera->Zoom(1.5);
	
	aRenderer->SetActiveCamera(aCamera);
	
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();
	
	aCamera->Delete();
}

@end
