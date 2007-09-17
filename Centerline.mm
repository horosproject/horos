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

- (NSArray *)generateCenterline:(vtkDataSet*)polyData{
	NSMutableSet *visitedPoints = [NSMutableSet set];
	NSMutableArray *connectedPoints = [NSMutableArray array];
	NSMutableArray *stack = [NSMutableArray array];
	
	
	vtkPolyDataNormals *polyDataNormals = 0L;
	vtkDecimatePro *isoDeci = 0L;
	vtkSmoothPolyDataFilter * pSmooth = 0L;
	vtkDataSet*	output = 0L;
	vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();
	power->SetInput( polyData);
	//polyDataNormals = vtkPolyDataNormals::New();
	//polyDataNormals->ConsistencyOn();
	//polyDataNormals->AutoOrientNormalsOn();


	vtkPolyData *medialSurface;
	power->Update();
	medialSurface = power->GetMedialSurface();
	isoDeci = vtkDecimatePro::New();
	isoDeci->SetInput(medialSurface);
	isoDeci->SetTargetReduction(0.9);
	isoDeci->SetPreserveTopology( TRUE);
	//polyDataNormals->SetInput(isoDeci->GetOutput());


	NSLog(@"Build Links");
	isoDeci->Update();
	vtkPolyData *data = isoDeci->GetOutput();
	data->BuildLinks();

	vtkPoints *medialPoints = data->GetPoints();
	int nPoints = data->GetNumberOfPoints();
	vtkIdType i;
	int j, k, neighbors;			
	double x , y, z;
	// get all cells around a point
	data->BuildCells();
	for (int a = 0; a < 5 ;  a++){
		for (i = 0; i < nPoints; i++) {	
			// count self
			neighbors = 1;
			double *position = medialPoints->GetPoint(i);
			// Get position
			x = position[0];
			y = position[1];
			z = position[2];
			NSSet *ptSet = [self connectedPointsForPoint:i fromPolyData:data];
			for (NSNumber *number in ptSet) {
				vtkIdType pt = [number intValue];
				position = medialPoints->GetPoint(pt);
				x += position[0];
				y += position[1];
				z += position[2];
				neighbors++;
				
			}
			
			// get average
			x /= neighbors;
			y /= neighbors;
			z /= neighbors;
			/// Set Point
			medialPoints->SetPoint(i, x ,y ,z);	
			
		}
	}
	
	// input for display
	//polyDataNormals->SetInput(data);
	


	// Find most inferior Point. Rrpresent Rectum
	// Could be a seed point to generalize.  
	vtkIdType startingPoint;
	double zPoint = 100000; 
	//NSLog(@"get starting Point");
	for (i = 0; i < nPoints; i++) {	
		double *position = medialPoints->GetPoint(i);
		if (position[2] < zPoint) {
			zPoint = position[2];
			startingPoint = i;
		}
	}

	double *sp = medialPoints->GetPoint(startingPoint);
	//NSLog(@"starting Point %d : %f %f %f",startingPoint, sp[0], sp[1], sp[2]);
	
	//get connected Points


	NSNumber *start = [NSNumber numberWithInt:startingPoint];
	[visitedPoints addObject:start];
	[connectedPoints addObject:start];
	[stack  addObject:start];
	
	vtkIdType currentPoint;
	currentPoint = startingPoint;
	while ([stack count] > 0) {
		neighbors = 0;
		[stack removeObjectAtIndex:0];
		double *position;
		double avgX = 0; 
		double avgY = 0;
		double avgZ = 0;
		//Loop through neighbors to get avg neighbor position Go three connections out
		NSSet *ptSet = [self connectedPointsForPoint:currentPoint fromPolyData:data];
		NSMutableSet *closeNeighbors = [NSMutableSet set];
		NSMutableSet *distantNeighbors = [NSMutableSet set];
		for (NSNumber *number in ptSet) {
			NSSet *neighborSet = [self connectedPointsForPoint:[number intValue]  fromPolyData:data];
			[closeNeighbors unionSet:neighborSet];
		}
		for (NSNumber *number in closeNeighbors) {
			NSSet *neighborSet = [self connectedPointsForPoint:[number intValue]  fromPolyData:data];
			[distantNeighbors unionSet:neighborSet];
		}
		
		for (NSNumber *number in distantNeighbors) {
			vtkIdType pt = [number intValue];
			if (![visitedPoints containsObject:number]) {
				position = medialPoints->GetPoint(pt);
				avgX += position[0];
				avgY += position[1];
				avgZ += position[2];
				neighbors++;
				//NSLog(@"pt %f %f %f", position[0], position[1], position[2]);
			}
		}

		// get average
		avgX /= neighbors;
		avgY /= neighbors;
		avgZ /= neighbors;
		//NSLog(@"avg: %f %f %f count: %d", avgX, avgY, avgZ, neighbors);
		//go through neighbors again and find closet neighbor to avgPt.
		//add closest neighbor to connected points

		double closestDistance = 100000;
		BOOL foundNeighbor = NO;
		vtkIdType closestNeighbor;
		for (NSNumber *number in distantNeighbors) {
			vtkIdType pt = [number intValue];
			position = medialPoints->GetPoint(pt);
			double distance = sqrt( pow(avgX - position[0],2) + pow(avgY - position[1],2) + pow(avgZ - position[2],2));

			if ((distance < closestDistance) && ![visitedPoints containsObject:number]) {
				// closet neighbor cannot be a visited Point
				closestNeighbor = pt;
				closestDistance = distance;
				foundNeighbor = YES;
				
			}
		}
		// add closest neighbor to connected points
		if (foundNeighbor) 
		{
			currentPoint = closestNeighbor;
			NSNumber *closest = [NSNumber numberWithInt:closestNeighbor];
			[connectedPoints addObject:closest];
			[stack addObject:closest];
			position = medialPoints->GetPoint(currentPoint);
			//NSLog(@"%d next Point: %f % f %f",[connectedPoints count], position[0], position[1], position[2]);
		}
		
		[visitedPoints unionSet:distantNeighbors];

	}
	
	power->Delete();
	polyDataNormals->Delete();
	isoDeci->Delete();
	
	//Convert Points to OSIPoints
	NSMutableArray *outputArray = [NSMutableArray array];
	for (NSNumber *number in connectedPoints) {
		double *position = medialPoints->GetPoint([number intValue]);
		OSIPoint3D *point3D = [OSIPoint3D pointWithX:position[0]  y:position[1]  z:position[2] value:nil];
		[outputArray addObject:point3D];
	}
	
	
	return outputArray;			

}

- (NSSet *)connectedPointsForPoint:(vtkIdType)pt fromPolyData:(vtkPolyData *)data{
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
