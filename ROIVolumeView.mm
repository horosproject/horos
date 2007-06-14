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

#include "vtkPowerCrustSurfaceReconstruction.h"

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
	
	triangulation->Delete();
	ballActor->Delete();
	
    [super dealloc];
}

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

//	vtkDecimatePro *isoDeci = vtkDecimatePro::New();
//	isoDeci->SetInput( profile);
////	isoDeci->SetTargetReduction( decimateVal);
//	isoDeci->SetPreserveTopology( TRUE);
	
//		isoDeci->SetFeatureAngle(60);
//		isoDeci->SplittingOff();
//		isoDeci->AccumulateErrorOn();
//		isoDeci->SetMaximumError(0.3);
	
//	vtkSmoothPolyDataFilter *isoSmoother = vtkSmoothPolyDataFilter::New();
//	isoSmoother->SetInput( profile);
//	isoSmoother->SetNumberOfIterations( smoothVal);
//		isoSmoother->SetRelaxationFactor(0.05);

	// Delaunay3D is used to triangulate the points. The Tolerance is the distance
	// that nearly coincident points are merged together. (Delaunay does better if
	// points are well spaced.) The alpha value is the radius of circumcircles,
	// circumspheres. Any mesh entity whose circumcircle is smaller than this
	// value is output.
	
	//vtkGaussian
	//vtkSurfaceReconstructionFilter
	//vtkContourFilter
	
//	vtkSurfaceReconstructionFilter *surf = vtkSurfaceReconstructionFilter::New();
//	surf->SetInput( profile);
//	
//	vtkContourFilter *cf = vtkContourFilter::New();
//    cf->SetInput(surf->GetOutput());
//    cf->SetValue(0, 0.0);
	
//	vtkPolyDataNormals *polyDataNormals = vtkPolyDataNormals::New();
//		polyDataNormals->SetInput( del->GetOutput());
//		polyDataNormals->ConsistencyOn();
//		polyDataNormals->AutoOrientNormalsOn();
		
//	vtkDelaunay3D *del = vtkDelaunay3D::New();
//		del->SetInput( profile);
//		del->SetTolerance( 0.001);
//		del->SetAlpha( 20);
////		del->SetOffset( 50);
//		del->BoundingTriangulationOff();
////	profile->Delete();
	
	vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();
		power->SetInput( profile);
	profile->Delete();

	vtkPolyDataNormals *polyDataNormals = vtkPolyDataNormals::New();
		polyDataNormals->SetInput( power->GetOutput());
		polyDataNormals->ConsistencyOn();
		polyDataNormals->AutoOrientNormalsOn();
	power->Delete();
	
	//do a bit of decimation
//	vtkDecimatePro *pDeci = vtkDecimatePro::New();
//	pDeci->SetInput(power->GetOutput());
//	pDeci->SetTargetReduction(0.0);

	//ok, now lets try some filtering
//	vtkSmoothPolyDataFilter * pSmooth = vtkSmoothPolyDataFilter::New();
//	pSmooth->SetInput(polyDataNormals->GetOutput());
//	pSmooth->SetNumberOfIterations( 100);
////	pSmooth->SetRelaxationFactor(fRelax);
//	pSmooth->SetFeatureEdgeSmoothing(TRUE);
//	pSmooth->SetFeatureAngle( 90);
//	pSmooth->SetEdgeAngle( 90);
//	pSmooth->SetBoundarySmoothing(TRUE);
//	pSmooth->Update();

	vtkDataSetMapper *map = vtkDataSetMapper::New();
		map->SetInput( polyDataNormals->GetOutput());
		map->ScalarVisibilityOff();
	polyDataNormals->Delete();
	
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


	triangulation = vtkActor::New();
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
		balls->SetInput( profile);
		balls->SetSource( ball->GetOutput());
	ball->Delete();
	
	vtkPolyDataMapper *mapBalls = vtkPolyDataMapper::New();
		mapBalls->SetInput( balls->GetOutput());
	balls->Delete();
	
	ballActor = vtkActor::New();
		ballActor->SetMapper( mapBalls);
		ballActor->GetProperty()->SetSpecular( 0.5);
		ballActor->GetProperty()->SetSpecularPower( 20);
		ballActor->GetProperty()->SetAmbient( 0.2);
		ballActor->GetProperty()->SetDiffuse( 0.8);
		ballActor->GetProperty()->SetOpacity( 0.8);
	mapBalls->Delete();
	
	aRenderer->AddActor( ballActor);
	
	triangulation->GetProperty()->FrontfaceCullingOn();
	triangulation->GetProperty()->BackfaceCullingOn();
	
	aRenderer->AddActor( triangulation);
	
    aCamera = vtkCamera::New();
	aCamera->Zoom(1.5);

	aRenderer->SetActiveCamera(aCamera);
	
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aCamera->SetParallelProjection( false);
	aCamera->SetViewAngle( 60);

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

- (void) setOpacity: (float) opacity showPoints: (BOOL) sp showSurface: (BOOL) sS showWireframe:(BOOL) w
{
	if( sp == NO) aRenderer->RemoveActor( ballActor);
	else aRenderer->AddActor( ballActor);

	if( sS == NO) aRenderer->RemoveActor( triangulation);
	else aRenderer->AddActor( triangulation);

	if( w) triangulation->GetProperty()->SetRepresentationToWireframe();
	else triangulation->GetProperty()->SetRepresentationToSurface();

	triangulation->GetProperty()->SetOpacity( opacity);
	
	[self setNeedsDisplay: YES];
}
@end
