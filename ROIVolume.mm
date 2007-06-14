//
//  ROIVolume.m
//  OsiriX
//
//  Created by joris on 1/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ROIVolume.h"
#include "vtkPowerCrustSurfaceReconstruction.h"
#include "vtkPolyDataNormals.h"
#import "WaitRendering.h"

@implementation ROIVolume

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		roiList = [[NSMutableArray alloc] initWithCapacity:0];
		roiVolumeActor = 0L;
		name = @"";
		volume = 0.0;
		red = 0.0;
		green = 1.0;
		blue = 1.0;
		opacity = 1.0;
		factor = 1.0;
		color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
		visible = NO;

		NSArray *keys   = [NSArray arrayWithObjects:@"name", @"volume", @"red", @"green", @"blue", @"opacity", @"color", @"visible", nil];
		NSArray *values = [NSArray arrayWithObjects:	name,
														[NSNumber numberWithFloat:volume],
														[NSNumber numberWithFloat:red],
														[NSNumber numberWithFloat:green],
														[NSNumber numberWithFloat:blue],
														[NSNumber numberWithFloat:opacity],
														color,
														[NSNumber numberWithBool:visible], nil];
		properties = [[NSMutableDictionary alloc] initWithObjects: values forKeys: keys];
	}
	return self;
}

- (void) dealloc
{
	[roiList release];
	[properties release];
	
	if(roiVolumeActor != 0L)
		roiVolumeActor->Delete();
		
	[super dealloc];
}


- (void)finalize {
	if(roiVolumeActor != 0L)
		roiVolumeActor->Delete();
		
	[super finalize];
}


- (void) setROIList: (NSArray*) newRoiList
{
	int i;
	float prevArea, preLocation;
	prevArea = 0.;
	preLocation = 0.;
	volume = 0.;
	
	for(i = 0; i < [newRoiList count]; i++)
	{
		ROI *curROI = [newRoiList objectAtIndex:i];
		if([curROI type]==tPencil || [curROI type]==tCPolygon || [curROI type]==tPlain)
		{
			[roiList addObject:curROI];
			// volume
			DCMPix *curDCM = [curROI pix];
			float curArea = [curROI roiArea];
			if( preLocation != 0)
				volume += (([curDCM sliceLocation] - preLocation)/10.) * (curArea + prevArea)/2.;
			prevArea = curArea;
			preLocation = [curDCM sliceLocation];
		}
	}
	
	if([roiList count])
	{
		ROI *curROI = [roiList objectAtIndex:0];
		name = [curROI name];
		[properties setValue:name forKey:@"name"];
		[properties setValue:[NSNumber numberWithFloat:volume] forKey:@"volume"];
	}
}

- (void) prepareVTKActor
{
	WaitRendering *splash = [[WaitRendering alloc] init:@"Preparing 3D Object..."];
	[splash showWindow:self]; 

	roiVolumeActor = vtkActor::New();
	
	int i, j;

	NSMutableArray *pts = [NSMutableArray array];

	for(i = 0; i < [roiList count]; i++)
	{
		ROI *curROI = [roiList objectAtIndex:i];

		DCMPix *curDCM = [curROI pix];
		//NSLog(@"[curDCM sliceLocation] : %d", [curDCM sliceLocation]);

		// points
		NSMutableArray	*points = [curROI points];
		for( j = 0; j < [points count]; j++)
		{
			float location[3];
			
			[curDCM convertPixX: [[points objectAtIndex: j] x] pixY: [[points objectAtIndex: j] y] toDICOMCoords: location];
			//NSLog(@"location : %f, %f, %f", location[0], location[1], location[2]);
			
			location[0] *= factor;
			location[1] *= factor;
			location[2] *= factor;
			
			NSArray	*pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], 0L];
			[pts addObject: pt3D];
		}		
	}
	
	#define MAXPOINTS 4000
		
	if( [pts count] > MAXPOINTS*2)
	{
		NSMutableArray *newpts = [NSMutableArray arrayWithCapacity: MAXPOINTS*2];
		
		int i, add = [pts count] / MAXPOINTS;
		
		if( add > 1)
		{
			for( i = 0; i < [pts count]; i += add)
			{
				[newpts addObject: [pts objectAtIndex: i]];
			}
			
			NSLog( @"too much points, reducing from: %d, to: %d", [pts count], [newpts count]);
			
			pts = newpts;
		}
	}

	if([pts count] > 0)
	{
		vtkPoints *points = vtkPoints::New();
		for(i = 0; i < [pts count]; i++)
		{
			NSArray	*pt3D = [pts objectAtIndex: i];
			points->InsertPoint(i, [[pt3D objectAtIndex: 0] floatValue], [[pt3D objectAtIndex: 1] floatValue], [[pt3D objectAtIndex: 2] floatValue]);
		}
		//NSLog(@"points->GetNumberOfPoints() : %d", points->GetNumberOfPoints());
		
		vtkPolyData *pointsDataSet = vtkPolyData::New();
		pointsDataSet->SetPoints(points);
		points->Delete();
		
		//if ([roiList count]==1)
		if (NO) // deactivated
		// SURFACE
		{		
			NSLog(@"vtkPolygon");
			vtkPolygon *polygon = vtkPolygon::New();
			polygon->GetPoints()->SetData(points->GetData());

			NSLog(@"polygon->GetPoints()->GetNumberOfPoints() : %d", polygon->GetPoints()->GetNumberOfPoints());

			NSLog(@"vtkCellArray");
			vtkCellArray *polygons = vtkCellArray::New();
			polygons->InsertNextCell(polygon);
			
			NSLog(@"vtkPolyData");
			vtkPolyData *surface = vtkPolyData::New();
			surface->SetPoints(points);
			surface->SetPolys(polygons);

			NSLog(@"surface->GetNumberOfPolys() : %d", surface->GetNumberOfPolys());		
			
			NSLog(@"vtkDataSetMapper");
			vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
			mapper->SetInput(surface);
			mapper->ScalarVisibilityOff();
			
			NSLog(@"roiVolumeActor->SetMapper(mapper);");
			roiVolumeActor->SetMapper(mapper);
			polygon->Delete();
			polygons->Delete();
			surface->Delete();
			mapper->Delete();
		}
		else
		// VOLUME
		{
//			vtkDelaunay3D *delaunayTriangulator = vtkDelaunay3D::New();
//			delaunayTriangulator->SetInput(pointsDataSet);
//			
//			delaunayTriangulator->SetTolerance( 0.001);
//			delaunayTriangulator->SetAlpha( 20); /// pimp my Alpha!!!
//			delaunayTriangulator->BoundingTriangulationOff();
//			
//			vtkDataSetMapper *map = vtkDataSetMapper::New();
//			map->SetInput((vtkDataSet*) delaunayTriangulator->GetOutput());
//			delaunayTriangulator->Delete();
//			
//			roiVolumeActor->SetMapper(map);
//			map->Delete();
			
			
			vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();
				power->SetInput( pointsDataSet);
			
			vtkPolyDataNormals *polyDataNormals = vtkPolyDataNormals::New();
				polyDataNormals->SetInput( power->GetOutput());
				polyDataNormals->ConsistencyOn();
				polyDataNormals->AutoOrientNormalsOn();
			power->Delete();
			
			vtkDataSetMapper *map = vtkDataSetMapper::New();
			map->SetInput( polyDataNormals->GetOutput());
			polyDataNormals->Delete();
			
			map->Update();
			
			roiVolumeActor->SetMapper(map);
			roiVolumeActor->GetProperty()->FrontfaceCullingOn();
			roiVolumeActor->GetProperty()->BackfaceCullingOn();

			map->Delete();
		}
		
		pointsDataSet->Delete();
		
//		roiVolumeActor->GetProperty()->SetRepresentationToWireframe();
		
		roiVolumeActor->GetProperty()->SetColor(red, green, blue);
		roiVolumeActor->GetProperty()->SetSpecular(0.3);
		roiVolumeActor->GetProperty()->SetSpecularPower(20);
		roiVolumeActor->GetProperty()->SetAmbient(0.2);
		roiVolumeActor->GetProperty()->SetDiffuse(0.8);
		roiVolumeActor->GetProperty()->SetOpacity(opacity);
	}
	
	[splash close];
	[splash release];
}

- (BOOL) isVolume
{
	return ([roiList count]>0);
}

- (NSValue*) roiVolumeActor
{
	if(roiVolumeActor == 0L)
		[self prepareVTKActor];
	[NSValue valueWithPointer:roiVolumeActor];
}

- (float) volume
{
	return volume;
}

- (NSColor*) color
{
	return color;
}

- (void) setColor: (NSColor*) c;
{
	color = c;
	red = [c redComponent];
	green = [c greenComponent];
	blue = [c blueComponent];
	opacity = [c alphaComponent];
	[properties setValue:color forKey:@"color"];
}

- (float) red
{
	return red;
}

- (void) setRed: (float) r
{
	red = r;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetColor(red, green, blue);
	[properties setValue:[NSNumber numberWithFloat:red] forKey:@"red"];
}

- (float) green
{
	return green;
}

- (void) setGreen: (float) g
{
	green = g;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetColor(red, green, blue);
	[properties setValue:[NSNumber numberWithFloat:green] forKey:@"green"];
}

- (float) blue
{
	return blue;
}

- (void) setBlue: (float) b
{
	blue = b;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetColor(red, green, blue);
	[properties setValue:[NSNumber numberWithFloat:blue] forKey:@"blue"];
}

- (float) opacity
{
	return opacity;
}

- (void) setOpacity: (float) o
{
	opacity = o;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetOpacity(opacity);
	[properties setValue:[NSNumber numberWithFloat:opacity] forKey:@"opacity"];
}

- (float) factor
{
	return factor;
}

- (void) setFactor: (float) f
{
	factor = f;
}

- (BOOL) visible
{
	return visible;
}

- (void) setVisible: (BOOL) d
{
	visible = d;
	[properties setValue:[NSNumber numberWithBool:visible] forKey:@"visible"];
}

- (NSString*) name
{
	return name;
}

- (NSDictionary*) properties
{
	return properties;
}

@end
