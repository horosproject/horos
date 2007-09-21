//
//  Centerline.mm
//  OsiriX
//
//  Created by Lance Pysher on 9/17/07.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
	 
	 
	Centerline extracts the centerline from a volume using thinning of the extracted surface
	Used to created automated fly through for virtual endoscopy
=========================================================================*/

#import "Centerline.h"
#import "OSIPoint3D.h"

#define id Id

//#include "vtkSurfaceReconstructionFilter.h"
#include "vtkReverseSense.h"

#include "vtkShrinkFilter.h"
#include "vtkDelaunay3D.h"
#include "vtkDelaunay2D.h"
#include "vtkProperty.h"


#include "vtkActor.h"
#include "vtkOutlineFilter.h"
#include "vtkImageReader.h"
#include "vtkImageImport.h"
#include "vtkCamera.h"
#include "vtkStripper.h"
#include "vtkLookupTable.h"
#include "vtkImageDataGeometryFilter.h"
#include "vtkProperty.h"
#include "vtkPolyDataNormals.h"
#include "vtkContourFilter.h"
#include "vtkImageData.h"

#include "vtkExtractPolyDataGeometry.h"
#include "vtkPolyDataConnectivityFilter.h"
#include "vtkTransformPolyDataFilter.h"

#include "vtkImageResample.h"
#include "vtkDecimatePro.h"
#include "vtkSmoothPolyDataFilter.h"

#include "vtkPolyDataNormals.h"

#include "vtkTextureMapToSphere.h"
#include "vtkTransformTextureCoords.h"
#include "vtkPowerCrustSurfaceReconstruction.h"
#include "vtkTriangleFilter.h"

#undef id

@implementation Centerline




- (NSArray *)generateCenterline:(vtkPolyData *)polyData startingPoint:(OSIPoint *)start{
	//NSMutableSet *visitedPoints = [NSMutableSet set];
	NSMutableArray *connectedPoints = [NSMutableArray array];
	NSMutableArray *stack = [NSMutableArray array];

	vtkDecimatePro *decimate = 0L;
	vtkDecimatePro *decimate2 = 0L;
	vtkDataSet*	output = 0L;
	vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();


	int oPoints = polyData->GetNumberOfPoints();
	NSLog(@"original Points: %d", oPoints);
	NSLog(@"original Polys: %d", polyData->GetNumberOfPolys());
	vtkPolyData *medialSurface;
	//power->Update();
	//medialSurface = power->GetMedialSurface();
	
	float reduction = 1.0 - 10000.0/oPoints;
	NSLog(@"Decimate: %f", reduction);
	decimate = vtkDecimatePro::New();
	//decimate->SetInput(medialSurface);
	decimate->SetInput(polyData);
	decimate->SetTargetReduction(reduction);
	decimate->SetPreserveTopology(YES);
	decimate->BoundaryVertexDeletionOn();
	decimate->SplittingOn();

	
	//decimate->Update();
/*
	NSLog(@"medial surface");
	power->SetInput(decimate->GetOutput());
	power->Update();
	medialSurface = power->GetMedialSurface();
	NSLog(@"Decimate2");
	decimate2 = vtkDecimatePro::New();
	decimate2->SetInput(medialSurface);
	decimate2->SetTargetReduction(0.9);
	decimate2->SetPreserveTopology(YES);
	decimate2->Update();
*/	
	decimate->Update();
	vtkPolyData *data = decimate->GetOutput();
	//vtkPolyData *data = decimate2->GetOutput();
	NSLog(@"getPoints");
	vtkPoints *medialPoints = data->GetPoints();
	int nPoints = data->GetNumberOfPoints();
	NSLog(@"number of Points: %d", nPoints);
	NSLog(@"number of Polys: %d", data->GetNumberOfPolys());
	NSLog(@"Build Links");
	data->BuildLinks();


	vtkIdType i;
	int j, k, neighbors;			
	double x , y, z;
	// get all cells around a point
	data->BuildCells();
	
	// Thinning Needs to be fast.  Paper says iterate 1000
	NSMutableArray *pointArray = [NSMutableArray array];
	for (i = 0; i < nPoints; i++) {	
		double *position = medialPoints->GetPoint(i);
		OSIPoint3D *point3D = [OSIPoint3D pointWithX:position[0]  y:position[1]  z:position[2] value:nil];
		[point3D setUserInfo:[self connectedPointsForPoint:i fromPolyData:data]];
		[pointArray addObject:point3D];
	}
	
	NSLog(@"thinning NSArray" );
	for (int a = 0; a < 100 ;  a++){
		for (OSIPoint3D *point3D in pointArray) {
			x = [point3D x];
			y = [point3D y];
			z = [point3D z];
			
			NSSet *ptSet = [point3D userInfo];
			for (NSNumber *number in ptSet) {
				OSIPoint *nextPoint = [pointArray objectAtIndex:[number intValue]];
				x += [nextPoint x];
				y += [nextPoint y];
				z += [nextPoint z];			
			}
				
			// get average
			x /= neighbors;
			y /= neighbors;
			z /= neighbors;
			
			neighbors = [ptSet count] + 1;	
		}
	}
	NSLog(@"end Thinning NSArray");
	

	

	NSLog(@"find starting Point");
	// Find most inferior Point. Rrpresent Rectum
	// Could be a seed point to generalize.  
	OSIPoint3D *startingPoint;
	x = [start x];
	y = [start y];
	z = [start z];
	
	 double minDistance = 1000000;
	

	
	for (OSIPoint3D *point3D in pointArray) {
		double distance = sqrt( pow(x - [point3D x],2) + pow(y - [point3D y],2) + pow(z - [point3D z],2));
		if (distance < minDistance) {
			minDistance = distance;
			startingPoint = point3D;
		}
	}
	
	int startIndex = [pointArray indexOfObject:startingPoint];

	//double *sp = medialPoints->GetPoint(startingPoint);
	NSLog(@"seed: %@", start);
	NSLog(@"starting Point %@",startingPoint);
	//get connected Points
	
	vtkPolyDataConnectivityFilter *connectFilter = vtkPolyDataConnectivityFilter::New();
	connectFilter->SetInput(data);
	connectFilter->SetExtractionModeToPointSeededRegions();
	connectFilter->AddSeed(startIndex);
	connectFilter->Update();
	vtkPolyData *connectionData = connectFilter->GetOutput();
	NSLog(@"connected cells: %d", connectionData->GetNumberOfPolys());
	NSLog(@"connected Points: %d", connectionData->GetNumberOfPoints());
	

	
		//set array to 0
	unsigned char visited[nPoints];
	for (int i = 0; i < nPoints; i++) visited[i] = 0;
	
	visited[startIndex] = 1;
	NSNumber *first = [NSNumber numberWithInt:startIndex];
	
	[connectedPoints addObject:startingPoint];
	[stack  addObject:first];
	NSLog(@"get centerline Points");
	vtkIdType currentPoint;
	//currentPoint = startingPoint;
	//double *position;
	
	int count = 0;
	while ([stack count] > 0 && (count++ < nPoints)) {
		if (count %500 == 0)
			NSLog(@"count %d stack: %d", count, [stack count]);
		neighbors = 0;
		currentPoint = [[stack lastObject] intValue];
		[stack removeLastObject];
		OSIPoint3D *point3D = [pointArray objectAtIndex:currentPoint];

		x = [point3D x]; 
		y = [point3D y];
		z = [point3D z];
		//NSLog(@"get neighbors");
		//Loop through neighbors to get avg neighbor position Go three connections out
		NSSet *ptSet = [self connectedPointsForPoint:currentPoint fromPolyData:data];
		NSMutableSet *neighbors = [NSMutableSet set];
		[neighbors unionSet:ptSet];
		for (int i = 0; i < 4; i++) {
			NSMutableSet *newNeighbors = [NSMutableSet set];
			for (NSNumber *number in neighbors)  {
				NSSet *neighborSet = (NSSet *)[[pointArray objectAtIndex:[number intValue]] userInfo];
				[newNeighbors unionSet:neighborSet];
			}
			[neighbors unionSet:newNeighbors];
		}

		
		//go through neighbors again and find closet neighbor to avgPt.
		//add closest neighbor to connected points

		double modellingDistance = 7.0;
		BOOL foundNeighbor = NO;
		vtkIdType closestNeighbor;
		//NSLog(@"neighbor count: %d", [neighbors count]);
		for (NSNumber *number in neighbors)  {
			OSIPoint3D *nextPoint = [pointArray objectAtIndex:[number intValue]];
			double distance = sqrt( pow(x - [nextPoint x],2) + pow(y - [nextPoint y],2) + pow(z - [nextPoint z],2));
			//NSLog(@"distance: %f visited: %d", distance,  visited[pt]);
			int index = [pointArray indexOfObject:nextPoint];
			if ((distance > modellingDistance) && visited[index] == 0) {
				// closet neighbor cannot be a visited Point
				//NSLog(@"add point: ");
				[stack addObject:[NSNumber numberWithInt:index]];
				[connectedPoints addObject:point3D];
			}
			visited[index] = 1;
		}
				
		// try and make sure visited most points
		// Find next closest point

	}
	NSLog(@"npoints: %d", nPoints);
	NSLog(@"count: %d", count);
	// NSLog(@"connectedPoints: %@",  [connectedPoints count]);


	
	power->Delete();
	decimate->Delete();
	//decimate2->Delete();
	return connectedPoints;			

}

- (NSMutableSet *)connectedPointsForPoint:(vtkIdType)pt fromPolyData:(vtkPolyData *)data{
	NSMutableSet *ptSet = [NSMutableSet set];
	vtkIdType ncells;
	vtkIdList *cellIds = vtkIdList::New();

	// All cells for Point and number of cells
	data->GetPointCells	(pt, cellIds);	
	ncells = cellIds->GetNumberOfIds();
	// loop through the cells
	for (int j = 0;  j < ncells; j++) {
		vtkIdType numPoints;
		vtkIdType *cellPoints ;
		vtkIdType cellId = cellIds->GetId(j);
		//get all points for the cell
		data->GetCellPoints(cellId, numPoints, cellPoints);				
		// points may be duplicate
		for (int k = 0; k < numPoints; k++) {	
			NSNumber *number = [NSNumber numberWithInt:cellPoints[k]];
			[ptSet addObject:number];
		 }
	}
	cellIds -> Delete();
	//NSLog(@"number in Set: %d\n%@", [ptSet count], ptSet);
	return ptSet;
}




@end
