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




- (NSArray *)generateCenterline:(vtkPolyData *)polyData startingPoint:(OSIPoint3D *)start endingPoint:(OSIPoint3D *)end{
	NSMutableArray *connectedPoints = [NSMutableArray array];
	NSMutableArray *stack = [NSMutableArray array];
	NSMutableArray *outputArray = [NSMutableArray array];

	vtkDecimatePro *decimate = 0L;
	vtkDecimatePro *decimate2 = 0L;
	vtkDataSet*	output = 0L;
	
	BOOL atEnd = NO;
	
	OSIPoint3D *endingPoint;
	OSIPoint3D *startingPoint;



	int oPoints = polyData->GetNumberOfPoints();
	NSLog(@"original Points: %d", oPoints);
	NSLog(@"original Polys: %d", polyData->GetNumberOfPolys());
	vtkPolyData *medialSurface;
	//power->Update();
	//medialSurface = power->GetMedialSurface();
	
	float reduction = 0.9;
	NSLog(@"Decimate: %f", reduction);
	decimate = vtkDecimatePro::New();
	//decimate->SetInput(medialSurface);
	decimate->SetInput(polyData);
	decimate->SetTargetReduction(reduction);
	decimate->SetPreserveTopology(YES);
	decimate->BoundaryVertexDeletionOn();
	decimate->SplittingOn();
	decimate->SetMaximumError(VTK_DOUBLE_MAX);
	decimate->Update();
	
	vtkPolyData *data = decimate->GetOutput();
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
	for (int a = 0; a < 300 ;  a++){
		for (OSIPoint3D *point3D in pointArray) {
			x = [point3D x];
			y = [point3D y];
			z = [point3D z];
			
			NSSet *ptSet = [point3D userInfo];
			for (NSNumber *number in ptSet) {
				OSIPoint3D *nextPoint = [pointArray objectAtIndex:[number intValue]];
				x += [nextPoint x];
				y += [nextPoint y];
				z += [nextPoint z];			
			}
			neighbors = [ptSet count] + 1;		
			// get average
			x /= neighbors;
			y /= neighbors;
			z /= neighbors;
			
			[point3D setX:(float)x y:(float)y z:(float)z];
			
		}
	}
	NSLog(@"end Thinning NSArray");
	

	

	NSLog(@"find starting Point");
	// Find most inferior Point. Rrpresent Rectum
	// Could be a seed point to generalize.  

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
	
	
	if (end) {
		x = [end x];
		y = [end y];
		z = [end z];
		for (OSIPoint3D *point3D in pointArray) {
			double distance = sqrt( pow(x - [point3D x],2) + pow(y - [point3D y],2) + pow(z - [point3D z],2));
			if (distance < minDistance) {
				minDistance = distance;
				endingPoint = point3D;
			}
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
	[stack  addObject:[NSNumber numberWithInt:startIndex]];
	NSLog(@"get centerline Points");
	vtkIdType currentPoint;

	
	int count = 0;
	int currentModelIndex = startIndex; 
	OSIPoint3D *currentModelPoint = startingPoint;
	x = [startingPoint x]; 
	y = [startingPoint y];
	z = [startingPoint z];
	
	while (([stack count] > 0 ) && !atEnd) {

		neighbors = 0;
		currentPoint = [[stack lastObject] intValue];
		[stack removeLastObject];

	
		//NSLog(@"get neighbors");
		//Loop through neighbors to get avg neighbor position Go three connections out
		NSSet *ptSet = [self connectedPointsForPoint:currentPoint fromPolyData:data];
		NSMutableSet *neighbors = [NSMutableSet set];
		[neighbors unionSet:ptSet];
		for (int i = 0; i < 2; i++) {
			NSMutableSet *newNeighbors = [NSMutableSet set];
			for (NSNumber *number in neighbors)  {
				NSSet *neighborSet = (NSSet *)[[pointArray objectAtIndex:[number intValue]] userInfo];
				[newNeighbors unionSet:neighborSet];
			}
			[neighbors unionSet:newNeighbors];
		}

		

		double modellingDistance = 5.0;

		for (NSNumber *number in neighbors)  {
			int index = [number intValue];
			OSIPoint3D *nextPoint = [pointArray objectAtIndex:index];
			
			if (visited[index] == 0) {
				double distance = sqrt( pow(x - [nextPoint x],2) + pow(y - [nextPoint y],2) + pow(z - [nextPoint z],2));
				//NSLog(@"distance: %f visited: %d", distance,  visited[pt]);
				
				if (distance > modellingDistance) {
					// if point is within modelling distance of an existing point don't add
					
					BOOL tooClose = NO;
					for (OSIPoint3D *existingPoint in connectedPoints) {						
						if (sqrt( pow([currentModelPoint x] - [existingPoint x],2)
							+ pow([currentModelPoint y] - [existingPoint y],2)
							+ pow([currentModelPoint z] - [existingPoint z],2)) <  modellingDistance) tooClose = YES;
					}
					if (!tooClose)	
					
					[connectedPoints addObject:currentModelPoint];
					
					if ([currentModelPoint isEqual:endingPoint]) {
						atEnd = YES;
						break;
					}
					currentModelIndex = index;
					currentModelPoint = nextPoint;
					x = [nextPoint x]; 
					y = [nextPoint y];
					z = [nextPoint z];
				}
				[stack addObject:[NSNumber numberWithInt:index]];
				visited[index] = 1;
			}
			
		}				
		// try and make sure visited most points
		// Find next closest point
	}
	
	NSLog(@"npoints: %d", nPoints);	
	NSLog(@"connected Points: %d", [connectedPoints count]);

	

	decimate->Delete();
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
