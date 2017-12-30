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


#import "Centerline.h"
#import "OSIVoxel.h"
#import "WaitRendering.h"

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
@synthesize wait = _wait, startingPoint = _startingPoint, endingPoint = _endingPoint, thinningIterations = _thinningIterations;

+ (id)centerline{
	return [[[Centerline alloc] init] autorelease];
}

- (id)init {
	if (self = [super init]) {
		_thinningIterations = 750;
		_wait = nil;
		_startingPoint = nil;
		_endingPoint = nil;
	}
	return self;
}

- (NSArray *)generateCenterline:(vtkPolyData *)polyData startingPoint:(OSIVoxel *)start endingPoint:(OSIVoxel *)end{
	int oPoints = polyData->GetNumberOfPoints();
	if (oPoints == 0) {
		NSLog(@"No data to create centerline");
		return nil;
	}
	
	NSMutableArray *connectedPoints = [NSMutableArray array];
	NSMutableArray *stack = [NSMutableArray array];
	NSMutableArray *centerlinePoints = [NSMutableArray array];

	vtkDecimatePro *decimate = nil;
	
	BOOL atEnd = NO;
	
	OSIVoxel *endingPoint;
	OSIVoxel *startingPoint;
	
	float voxelWidth = start.voxelWidth;
	float voxelHeight = start.voxelHeight;
	float voxelDepth = start.voxelDepth;

	

	// Never reach 0.8. Usually around 0.5, but we can hope.
	[_wait setString:NSLocalizedString(@"Decimating Polygons", nil)];
	float reduction = 0.8;
	decimate = vtkDecimatePro::New();
	decimate->SetInput(polyData);
	decimate->SetTargetReduction(reduction);
	decimate->SetPreserveTopology(YES);
	decimate->BoundaryVertexDeletionOn();
	decimate->SplittingOn();
	decimate->SetMaximumError(VTK_DOUBLE_MAX);
	decimate->Update();
		
	vtkPolyData *data = decimate->GetOutput();
	int nPoints = data->GetNumberOfPoints();
	vtkPoints *medialPoints = data->GetPoints();
	data->BuildLinks();


	vtkIdType i;
	int  neighbors;			
	double x , y, z;
	// get all cells around a point
	data->BuildCells();
	
	// Thinning Needs to be fast.  Paper says iterate 1000
	// point array will be thinnned
	NSMutableArray *pointArray = [NSMutableArray array];
	// originalPoints is unaltered so we can use the polygon points to calculate the centerline
	NSMutableArray *originalPoints = [NSMutableArray array];
	[_wait setString:NSLocalizedString(@"Building Points", nil)];
	for (i = 0; i < nPoints; i++) {	
		double *position = medialPoints->GetPoint(i);
		OSIVoxel *point3D = [OSIVoxel pointWithX:position[0]  y:position[1]  z:position[2] value:nil];
		[point3D setUserInfo:[self connectedPointsForPoint:i fromPolyData:data]];
		OSIVoxel *point2 = [[point3D copy] autorelease];
		[pointArray addObject:point3D];
		[originalPoints addObject:point2];
	}
	
	NSString *thinning = NSLocalizedString(@"Thinning", nil);
	[_wait setString:thinning];
 // Create NSArray from Polygon points
	for (int a = 0; a < _thinningIterations ;  a++){
		for (OSIVoxel *point3D in pointArray) {
			x = point3D.x;
			y = point3D.y;
			z = point3D.z;
			
			NSSet *ptSet = [point3D userInfo];
			for (NSNumber *number in ptSet) {
				OSIVoxel *nextPoint = [pointArray objectAtIndex:[number intValue]];
				x += nextPoint.x;
				y += nextPoint.y;
				z += nextPoint.z;			
			}
			neighbors = [ptSet count] + 1;		
			// get average
			x /= neighbors;
			y /= neighbors;
			z /= neighbors;
			
			[point3D setX:(float)x y:(float)y z:(float)z];
			//[_wait setString:[thinning stringByAppendingFormat:@" %d", a]];
		}
	}
 

	x = [start x];
	y = [start y];
	z = [start z];
	
	double minDistance = 1000000;
	for (OSIVoxel *point3D in pointArray) {
		double distance = sqrt( pow((x - point3D.x) * voxelWidth,2) + pow((y - point3D.y) * voxelHeight,2) + pow((z - point3D.z) * voxelDepth,2));
		if (distance < minDistance) {
			minDistance = distance;
			startingPoint = point3D;
		}
	}
	
	
	if (end) {
		x = [end x];
		y = [end y];
		z = [end z];
		for (OSIVoxel *point3D in pointArray) {
			double distance = sqrt( pow((x - point3D.x) * voxelWidth,2) + pow((y - point3D.y) * voxelHeight,2) + pow((z - point3D.z) * voxelDepth,2));
			if (distance < minDistance) {
				minDistance = distance;
				endingPoint = point3D;
			}
		}
	}
	
	
	int startIndex = [pointArray indexOfObject:startingPoint];

	//set array to 0
	unsigned char visited[nPoints];
	for (int i = 0; i < nPoints; i++) visited[i] = 0;
	
	visited[startIndex] = 1;
	[stack  addObject:[NSNumber numberWithInt:startIndex]];
	vtkIdType currentPoint;

	int currentModelIndex = startIndex; 
	OSIVoxel *currentModelPoint = startingPoint;
	x = startingPoint.x; 
	y = startingPoint.y;
	z = startingPoint.z;
	
	
	[_wait setString:NSLocalizedString(@"Finding Index Points", nil)];
	while (([stack count] > 0 ) && !atEnd) {

		neighbors = 0;
		currentPoint = [[stack lastObject] intValue];
		[stack removeLastObject];

	
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
			OSIVoxel *nextPoint = [pointArray objectAtIndex:index];
			
			if (visited[index] == 0) {
				double distance = sqrt( pow((x - nextPoint.x) * voxelWidth,2) + pow((y - nextPoint.y) * voxelHeight,2) + pow((z - nextPoint.z) * voxelDepth,2));
				
				if (distance > modellingDistance) {
					// if point is within modelling distance of an existing point don't add					
					BOOL tooClose = NO;
					for (OSIVoxel *existingPoint in connectedPoints) {						
						if (sqrt( pow((currentModelPoint.x - existingPoint.x) * voxelWidth,2)
							+ pow((currentModelPoint.y - existingPoint.y) * voxelHeight,2)
							+ pow((currentModelPoint.z - existingPoint.z) * voxelDepth,2)) <  modellingDistance) tooClose = YES;
					}
					if (!tooClose) [connectedPoints addObject:currentModelPoint];
					
					if ([currentModelPoint isEqual:endingPoint]) {
						atEnd = YES;
						break;
					}
					currentModelIndex = index;
					currentModelPoint = nextPoint;
					x = nextPoint.x; 
					y = nextPoint.y;
					z = nextPoint.z;
				}
				[stack addObject:[NSNumber numberWithInt:index]];
				visited[index] = 1;
			}
			
		}				
		// try and make sure visited most points
		// Find next closest point
	}
	
	[_wait setString:NSLocalizedString(@"Arranging Points", nil)];
	if ([connectedPoints count] > 0) {
	// Arrange points from start to end based on proximity
	NSMutableArray *arrangedPoints = [NSMutableArray array];
	[arrangedPoints addObject:startingPoint];
	[connectedPoints removeObject:startingPoint];
	OSIVoxel *nextPoint;
	currentModelPoint = startingPoint;
	
	while ([connectedPoints count] > 1) {
			minDistance = 1000000;
			for (OSIVoxel *point3D in connectedPoints) {
				double distance = sqrt( pow((currentModelPoint.x - point3D.x) * voxelWidth,2)
					+ pow((currentModelPoint.y - point3D.y) * voxelHeight,2)
					+ pow((currentModelPoint.z - point3D.z) * voxelDepth,2));
				if (distance < minDistance) {
						minDistance = distance;
						nextPoint = point3D;
				}							
			}

			[arrangedPoints addObject:nextPoint];
			[connectedPoints removeObject:nextPoint];		
			currentModelPoint = nextPoint;
		}

		[arrangedPoints addObject:[connectedPoints lastObject]];
				
		// Get all points lying between our selected points.  
		//Get points from original surface.  
		//Get average for centerline
		
		int pointCount = [arrangedPoints count] - 1;
		[_wait setString:NSLocalizedString(@"Finding Centerline Points", nil)];
		for (int i = 0; i < pointCount; i++) {
			NSMutableSet *nearbyPoints = [NSMutableSet set];
			OSIVoxel *firstPoint = [arrangedPoints objectAtIndex:i];
			OSIVoxel *nextPoint = [arrangedPoints objectAtIndex: i+1];
			double distance = sqrt( pow((firstPoint.x - nextPoint.x) * voxelWidth,2)
					+ pow((firstPoint.y - nextPoint.y) * voxelHeight,2)
					+ pow((firstPoint.z - nextPoint.z) * voxelDepth,2));
			for (OSIVoxel *point3D in pointArray) {
				double distance1 = sqrt( pow((firstPoint.x - point3D.x) * voxelWidth,2)
					+ pow((firstPoint.y - point3D.y) * voxelHeight,2)
					+ pow((firstPoint.z - point3D.z) * voxelDepth,2));
				double distance2 = sqrt( pow((nextPoint.x - point3D.x) * voxelWidth,2)
					+ pow((nextPoint.y - point3D.y) * voxelHeight,2)
					+ pow((nextPoint.z - point3D.z) * voxelDepth,2));
				if ((distance1 <= distance) && (distance2 <= distance)) {
					int index = [pointArray indexOfObject:point3D];
					if (index < [originalPoints count]);
						[nearbyPoints addObject:[originalPoints objectAtIndex:index]];
				}
			}
			
			double neighborsCount = (double)[nearbyPoints count];
			double xPos, yPos, zPos;
			for (OSIVoxel *point3D in nearbyPoints) {
				xPos += point3D.x;
				yPos += point3D.y;
				zPos += point3D.z;
				
			}
			
			xPos /= neighborsCount;
			yPos /= neighborsCount;
			zPos /= neighborsCount;
			
			[centerlinePoints addObject:[OSIVoxel pointWithX: xPos y:yPos z:zPos value:nil]];		
		}
	}
	
	decimate->Delete();
	return centerlinePoints;	
	

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
	return ptSet;
}




@end
