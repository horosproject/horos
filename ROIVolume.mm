/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - GPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/


#import "ROIVolume.h"


#import "ITKSegmentation3D.h"

#import "WaitRendering.h"

@implementation ROIVolume

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		roiList = [[NSMutableArray alloc] initWithCapacity:0];
		roiVolumeActor = nil;
		name = @"";
		volume = 0.0;
		red = 0.0;
		green = 1.0;
		blue = 1.0;
		opacity = 1.0;
		factor = 1.0;
		textured = YES;
		color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
		visible = NO;

		NSArray *keys   = [NSArray arrayWithObjects:@"name", @"volume", @"red", @"green", @"blue", @"opacity", @"color", @"visible", @"texture", nil];
		NSArray *values = [NSArray arrayWithObjects:	name,
														[NSNumber numberWithFloat:volume],
														[NSNumber numberWithFloat:red],
														[NSNumber numberWithFloat:green],
														[NSNumber numberWithFloat:blue],
														[NSNumber numberWithFloat:opacity],
														color,
														[NSNumber numberWithBool:visible],
														[NSNumber numberWithBool:textured], nil];
		properties = [[NSMutableDictionary alloc] initWithObjects: values forKeys: keys];
	}
	return self;
}

- (void) dealloc
{
	[roiList release];
	[properties release];
	
	if(roiVolumeActor != nil)
		roiVolumeActor->Delete();
	
	if( textureImage)
		textureImage->Delete();

	[super dealloc];
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
		// points
		NSMutableArray	*points = nil;
					
		if( [curROI type] == tPlain)
		{
			points = [ITKSegmentation3D extractContour:[curROI textureBuffer] width:[curROI textureWidth] height:[curROI textureHeight] numPoints: 100 largestRegion: NO];
			
			float mx = [curROI textureUpLeftCornerX], my = [curROI textureUpLeftCornerY];
			
			for( j = 0; j < [points count]; j++)
			{
				MyPoint	*pt = [points objectAtIndex: j];
				[pt move: mx :my];
			}
		}
		else points = [curROI splinePoints];
		
		for( j = 0; j < [points count]; j++)
		{
			float location[3];
			
			[curDCM convertPixX: [[points objectAtIndex: j] x] pixY: [[points objectAtIndex: j] y] toDICOMCoords: location pixelCenter: YES];
			//NSLog(@"location : %f, %f, %f", location[0], location[1], location[2]);
			
			location[0] *= factor;
			location[1] *= factor;
			location[2] *= factor;
			
			NSArray	*pt3D = [NSArray arrayWithObjects: [NSNumber numberWithFloat: location[0]], [NSNumber numberWithFloat:location[1]], [NSNumber numberWithFloat:location[2]], nil];
			[pts addObject: pt3D];
		}		
	}
	
	#define MAXPOINTS 3000
	
	NSMutableArray *newpts = [NSMutableArray arrayWithCapacity: MAXPOINTS*2];
	
	if( [pts count] > MAXPOINTS*2)
	{
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
//		if (NO) // deactivated
//		// SURFACE
//		{		
//			NSLog(@"vtkPolygon");
//			vtkPolygon *polygon = vtkPolygon::New();
//			polygon->GetPoints()->SetData(points->GetData());
//
//			NSLog(@"polygon->GetPoints()->GetNumberOfPoints() : %d", polygon->GetPoints()->GetNumberOfPoints());
//
//			NSLog(@"vtkCellArray");
//			vtkCellArray *polygons = vtkCellArray::New();
//			polygons->InsertNextCell(polygon);
//			
//			NSLog(@"vtkPolyData");
//			vtkPolyData *surface = vtkPolyData::New();
//			surface->SetPoints(points);
//			surface->SetPolys(polygons);
//
//			NSLog(@"surface->GetNumberOfPolys() : %d", surface->GetNumberOfPolys());		
//			
//			NSLog(@"vtkDataSetMapper");
//			vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
//			mapper->SetInput(surface);
//			mapper->ScalarVisibilityOff();
//			
//			NSLog(@"roiVolumeActor->SetMapper(mapper);");
//			roiVolumeActor->SetMapper(mapper);
//			polygon->Delete();
//			polygons->Delete();
//			surface->Delete();
//			mapper->Delete();
//		}
//		else
		// VOLUME
		{
			vtkDelaunay3D *delaunayTriangulator = nil;
			vtkPolyDataNormals *polyDataNormals = nil;
			vtkDecimatePro *isoDeci = nil;
			vtkDataSet*	output = nil;
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"UseDelaunayFor3DRoi"])
			{
				delaunayTriangulator = vtkDelaunay3D::New();
				delaunayTriangulator->SetInput(pointsDataSet);
				
				delaunayTriangulator->SetTolerance( 0.001);
				delaunayTriangulator->SetAlpha( 20);
				delaunayTriangulator->BoundingTriangulationOff();
				
				output = (vtkDataSet*) delaunayTriangulator -> GetOutput();
			}
			
			else
			
			{		
			vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();
			power->SetInput(pointsDataSet);
			
			polyDataNormals = vtkPolyDataNormals::New();
			polyDataNormals->ConsistencyOn();
			polyDataNormals->AutoOrientNormalsOn();
			if (NO) 
			{
				vtkPolyData *medialSurface;
				power->Update();
				medialSurface = power->GetMedialSurface();
				//polyDataNormals->SetInput(medialSurface);
				isoDeci = vtkDecimatePro::New();
				isoDeci->SetInput(medialSurface);
				isoDeci->SetTargetReduction(0.9);
				isoDeci->SetPreserveTopology( TRUE);
				polyDataNormals->SetInput(isoDeci->GetOutput());
			

				NSLog(@"Build Links");
				isoDeci->Update();
				vtkPolyData *data = isoDeci->GetOutput();
				//vtkPolyData *data = power->GetOutput();
				data->BuildLinks();

				vtkPoints *medialPoints = data->GetPoints();
				int nPoints = data->GetNumberOfPoints();
				vtkIdType i;
				int j, k, neighbors;			
				double x , y, z;
				// get all cells around a point
			
				data->BuildCells();
				for (int a = 0; a < 50 ;  a++){
					for (i = 0; i < nPoints; i++) {	
						vtkIdType ncells;
						vtkIdList *cellIds = vtkIdList::New();;
						
						// count self
						neighbors = 1;
						double *position = medialPoints->GetPoint(i);
						// Get position
						x = position[0];
						y = position[1];
						z = position[2];
						// All cells for Point and number of cells
						data->GetPointCells	(i, cellIds);	
						ncells = cellIds->GetNumberOfIds();
		
						for (j = 0;  j < ncells; j++) {
							vtkIdType numPoints;
							vtkIdType *cellPoints ;
							vtkIdType cellId = cellIds->GetId(j);
							//get all points for the cell
							data->GetCellPoints(cellId, numPoints, cellPoints);				

							 for (k = 0; k < numPoints; k++) {						
								position = medialPoints->GetPoint(cellPoints[k]);

								x += position[0];
								y += position[1];
								z += position[2];
								neighbors++;
							 }
						}

						// get average
						x /= neighbors;
						y /= neighbors;
						z /= neighbors;
						medialPoints->SetPoint(i, x ,y ,z);
						
						cellIds->Delete();
					}
				}
				
				polyDataNormals->SetInput(data);
			}

			else 
			{
				polyDataNormals->SetInput(power->GetOutput());
			}
			power->Delete();		
			output = (vtkDataSet*) polyDataNormals -> GetOutput();
		}

			
			vtkTextureMapToSphere *tmapper = vtkTextureMapToSphere::New();
				tmapper -> SetInput( output);
				tmapper -> PreventSeamOn();
			
			if( polyDataNormals) polyDataNormals->Delete();
			if( delaunayTriangulator) delaunayTriangulator->Delete();
			if (isoDeci) isoDeci->Delete();

			vtkTransformTextureCoords *xform = vtkTransformTextureCoords::New();
				xform->SetInput(tmapper->GetOutput());
				xform->SetScale(4,4,4);
			tmapper->Delete();
				
			vtkDataSetMapper *map = vtkDataSetMapper::New();
			map->SetInput( tmapper->GetOutput());
			map->ScalarVisibilityOff();
			
			map->Update();
			
			roiVolumeActor->SetMapper(map);
			roiVolumeActor->GetProperty()->FrontfaceCullingOn();
			roiVolumeActor->GetProperty()->BackfaceCullingOn();

			map->Delete();
			
			//Texture
			NSString	*location = [[NSUserDefaults standardUserDefaults] stringForKey:@"textureLocation"];
			
			if( location == nil || [location isEqualToString:@""])
				location = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"texture.tif"];
			
			vtkTIFFReader *bmpread = vtkTIFFReader::New();
			   bmpread->SetFileName( [location UTF8String]);

			textureImage = vtkTexture::New();
			   textureImage->SetInput( bmpread->GetOutput());
			   textureImage->InterpolateOn();
			bmpread->Delete();

			roiVolumeActor->SetTexture( textureImage);
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
	if(roiVolumeActor == nil)
		[self prepareVTKActor];
	
	return [NSValue valueWithPointer:roiVolumeActor];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ROIVolumePropertiesChanged" object:self userInfo:[NSDictionary dictionaryWithObject:@"color" forKey:@"key"]];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ROIVolumePropertiesChanged" object:self userInfo:[NSDictionary dictionaryWithObject:@"red" forKey:@"key"]];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ROIVolumePropertiesChanged" object:self userInfo:[NSDictionary dictionaryWithObject:@"green" forKey:@"key"]];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ROIVolumePropertiesChanged" object:self userInfo:[NSDictionary dictionaryWithObject:@"blue" forKey:@"key"]];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ROIVolumePropertiesChanged" object:self userInfo:[NSDictionary dictionaryWithObject:@"opacity" forKey:@"key"]];
}

- (BOOL) texture
{
	return textured;
}

- (void) setTexture: (BOOL) o
{
	textured = o;
	
	if( roiVolumeActor)
	{
		if( o) roiVolumeActor->SetTexture( textureImage);
		else roiVolumeActor->SetTexture( nil);
	}
	[properties setValue:[NSNumber numberWithBool: textured] forKey:@"texture"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ROIVolumePropertiesChanged" object:self userInfo:[NSDictionary dictionaryWithObject:@"texture" forKey:@"key"]];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ROIVolumePropertiesChanged" object:self userInfo:[NSDictionary dictionaryWithObject:@"visible" forKey:@"key"]];
}

- (NSString*) name
{
	return name;
}

- (NSDictionary*) properties
{
	return properties;
}

- (NSMutableDictionary*)displayProperties;
{
	NSMutableDictionary *displayProperties = [NSMutableDictionary dictionary];
	[displayProperties setValue:[properties valueForKey:@"color"] forKey:@"color"];
	[displayProperties setValue:[properties valueForKey:@"red"] forKey:@"red"];
	[displayProperties setValue:[properties valueForKey:@"green"] forKey:@"green"];
	[displayProperties setValue:[properties valueForKey:@"blue"] forKey:@"blue"];
	[displayProperties setValue:[properties valueForKey:@"opacity"] forKey:@"opacity"];
	[displayProperties setValue:[properties valueForKey:@"texture"] forKey:@"texture"];
	[displayProperties setValue:[properties valueForKey:@"visible"] forKey:@"visible"];

	return displayProperties;
}

- (void)setDisplayProperties:(NSDictionary*)newProperties;
{
	[self setColor:[newProperties valueForKey:@"color"]];
	[self setRed:[[newProperties valueForKey:@"red"] floatValue]];
	[self setGreen:[[newProperties valueForKey:@"green"] floatValue]];
	[self setBlue:[[newProperties valueForKey:@"blue"] floatValue]];
	[self setOpacity:[[newProperties valueForKey:@"opacity"] floatValue]];
	[self setTexture:[[newProperties valueForKey:@"texture"] boolValue]];
	[self setVisible:[[newProperties valueForKey:@"visible"] boolValue]];
}

@end
