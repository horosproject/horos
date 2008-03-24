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

#import "ROIVolumeView.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "DICOMExport.h"
#import "ROIVolumeController.h"

#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#import "QuicktimeExport.h"

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

@implementation ROIVolumeView



-(void) coView:(id) sender
{
	aCamera = aRenderer->GetActiveCamera();
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
	
	[self setNeedsDisplay:YES];
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
		
//		[[NSOpenGLContext currentContext] flushBuffer];
		[NSOpenGLContext clearCurrentContext];
	}
	
	return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
	NSBitmapImageRep	*rep;
	long				width, height, i, x, spp, bpp;
	NSString			*colorSpace;
	unsigned char		*dataPtr;
	
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
		
	 NSImage *image = [[[NSImage alloc] init] autorelease];
	 [image addRepresentation:rep];
	 
	free( dataPtr);
	
	return image;
}

- (void) exportJPEG:(id) sender
{
    NSSavePanel     *panel = [NSSavePanel savePanel];

	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"jpg"];
	
	if( [panel runModalForDirectory:0L file:@"Volume Image"] == NSFileHandlingPanelOKButton)
	{
		NSImage *im = [self nsimage:NO];
		
		NSArray *representations;
		NSData *bitmapData;
		
		representations = [im representations];
		
		bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
		[bitmapData writeToFile:[panel filename] atomically:YES];
		
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OPENVIEWER"]) [ws openFile:[panel filename]];
	}
}

-(IBAction) copy:(id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    NSImage *im;
    
    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    
    im = [self nsimage:NO];
    
    [pb setData: [im TIFFRepresentation] forType:NSTIFFPboardType];
}

- (void) exportDICOMFile:(id) sender
{
	long	width, height, spp, bpp, err;
	float	cwl, cww;
	float	o[ 9];
	
	DICOMExport *exportDCM = [[DICOMExport alloc] init];
	
	unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :YES];
	
	if( dataPtr)
	{
		ROIVolumeController *co = [[self window] windowController];
		NSArray	*pixList = [[co viewer] pixList];
		
		[exportDCM setSourceFile: [[pixList objectAtIndex: 0] srcFile]];
		[exportDCM setSeriesDescription:[[co roi] name]];
		[exportDCM setSeriesNumber:5500];
		[exportDCM setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
		
		err = [exportDCM writeDCMFile: 0L];
		if( err)  NSRunCriticalAlertPanel( NSLocalizedString(@"Error", 0L),  NSLocalizedString( @"Error during the creation of the DICOM File!", 0L), NSLocalizedString(@"OK", 0L), nil, nil);
		
		free( dataPtr);
	}

	[exportDCM release];
}

- (void) CloseViewerNotification: (NSNotification*) note
{

}

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame] )
    {
		NSLog(@"init ROIVolumeView");
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
		computeMedialSurface = NO;
    }
    
    return self;
}

-(void)dealloc
{	
    NSLog(@"Dealloc ROIVolumeView");
		
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	roiVolumeActor->Delete();
	ballActor->Delete();
	texture->Delete();
	orientationWidget->Delete();
	[_points3D release];
    [super dealloc];
}

- (short) setPixSource:(NSMutableArray*)pts
{
	GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
	[self getVTKRenderWindow]->MakeCurrent();
	[[NSOpenGLContext currentContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];

	[_points3D release];
	_points3D = [pts copy];
	return [self renderVolume];
}

- (short) renderVolume
{
	WaitRendering *splash = [[WaitRendering alloc] init:@"Rendering 3D Object..."];
	[splash showWindow:self]; 

	short   error = 0;
	long	i;
	aRenderer = [self renderer];
	
	vtkPoints *points = vtkPoints::New();
	NSArray *pts = _points3D;
	for( i = 0; i < [pts count]; i++)
	{
		NSArray	*pt3D = [pts objectAtIndex: i];
		points->InsertPoint( i, [[pt3D objectAtIndex: 0] floatValue], [[pt3D objectAtIndex: 1] floatValue], [[pt3D objectAtIndex: 2] floatValue]);
	}
	
	vtkPolyData *profile = vtkPolyData::New();
    profile->SetPoints( points);
	points->Delete();

	vtkDelaunay3D *delaunayTriangulator = 0L;
	vtkPolyDataNormals *polyDataNormals = 0L;
	vtkDecimatePro *isoDeci = 0L;
	vtkSmoothPolyDataFilter * pSmooth = 0L;
	vtkDataSet*	output = 0L;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"UseDelaunayFor3DRoi"])
	{
		delaunayTriangulator = vtkDelaunay3D::New();
		delaunayTriangulator->SetInput(profile);
		
		delaunayTriangulator->SetTolerance( 0.001);
		delaunayTriangulator->SetAlpha( 20);
		delaunayTriangulator->BoundingTriangulationOff();
		
		output = (vtkDataSet*) delaunayTriangulator -> GetOutput();
	}
	else
	
	{	
		
		vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();
		power->SetInput( profile);
		polyDataNormals = vtkPolyDataNormals::New();
		polyDataNormals->ConsistencyOn();
		polyDataNormals->AutoOrientNormalsOn();
		//if (computeMedialSurface) 
		if (NO)
		{
			vtkPolyData *medialSurface;
			power->Update();
			medialSurface = power->GetMedialSurface();
			//polyDataNormals->SetInput(power->GetOutput());
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
			for (int a = 0; a < 5 ;  a++){
				for (i = 0; i < nPoints; i++) {	
					vtkIdType ncells;
					vtkIdList *cellIds = vtkIdList::New();;
					//int j = 0;
					// count self
					neighbors = 1;
					double *position = medialPoints->GetPoint(i);
					// Get position
					x = position[0];
					y = position[1];
					z = position[2];
					NSSet *ptSet = [self connectedPointsForPoint:i fromPolyData:data];
					for (NSNumber *number in ptSet) {
						vtkIdType pt = [number doubleValue];
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
			polyDataNormals->SetInput(data);
			


			// Find most inferior Point. Rrpresent Rectum
			// Could be a seed point to generalize.  
			vtkIdType startingPoint;
			double zPoint = 100000; 
			NSLog(@"get starting Point");
			for (i = 0; i < nPoints; i++) {	
				double *position = medialPoints->GetPoint(i);
				if (position[2] < zPoint) {
					zPoint = position[2];
					startingPoint = i;
				}
			}

			double *sp = medialPoints->GetPoint(startingPoint);
			NSLog(@"starting Point %d : %f %f %f",startingPoint, sp[0], sp[1], sp[2]);
			
			//get connected Points
			NSMutableSet *visitedPoints = [NSMutableSet set];
			NSMutableArray *connectedPoints = [NSMutableArray array];
			NSMutableArray *stack = [NSMutableArray array];

			NSNumber *start = [NSNumber numberWithDouble:startingPoint];
			[visitedPoints addObject:start];
			[connectedPoints addObject:start];
			[stack  addObject:start];
			
			vtkIdType currentPoint;
			currentPoint = startingPoint;
			while ([stack count] > 0) {
				neighbors = 0;
				[stack removeObjectAtIndex:0];
				double *position;
				//double *position = medialPoints->GetPoint(startingPoint);
				// Get position
				//x = position[0];
				//y = position[1];
				//z = position[2];
				// All cells for Point and number of cells

				double avgX = 0; 
				double avgY = 0;
				double avgZ = 0;
				//Loop through neighbors to get avg neighbor position Go three connections out
				NSSet *ptSet = [self connectedPointsForPoint:currentPoint fromPolyData:data];
				NSMutableSet *closeNeighbors = [NSMutableSet set];
				NSMutableSet *distantNeighbors = [NSMutableSet set];
				for (NSNumber *number in ptSet) {
					NSSet *neighborSet = [self connectedPointsForPoint:[number doubleValue]  fromPolyData:data];
					[closeNeighbors unionSet:neighborSet];
				}
				for (NSNumber *number in closeNeighbors) {
					NSSet *neighborSet = [self connectedPointsForPoint:[number doubleValue]  fromPolyData:data];
					[distantNeighbors unionSet:neighborSet];
				}
				
				for (NSNumber *number in distantNeighbors) {
					vtkIdType pt = [number doubleValue];
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
					vtkIdType pt = [number doubleValue];
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
					NSNumber *closest = [NSNumber numberWithDouble:closestNeighbor];
					[connectedPoints addObject:closest];
					[stack addObject:closest];
					position = medialPoints->GetPoint(currentPoint);
					//NSLog(@"%d next Point: %f % f %f",[connectedPoints count], position[0], position[1], position[2]);
				}
				
				[visitedPoints unionSet:distantNeighbors];

			}			
			
			//NSLog(@"Visited Points: %d total Points: %d", [visitedPoints count], nPoints);
			//NSLog(@"Medial Surface number of Polygons: %d", medialSurface->GetNumberOfPolys());
			//NSLog(@"Medial Surface number of Points: %d", medialSurface->GetNumberOfPoints());

		}
		else 
		{
			polyDataNormals->SetInput(power->GetOutput());
		}
		power->Delete();		
		output = (vtkDataSet*) polyDataNormals -> GetOutput();
	}
	
	// ****************** Mapper
	vtkTextureMapToSphere *tmapper = vtkTextureMapToSphere::New();
		tmapper -> SetInput( output);
		tmapper -> PreventSeamOn();
	
	if( polyDataNormals) polyDataNormals->Delete();
	if( delaunayTriangulator) delaunayTriangulator->Delete();
	if (isoDeci) isoDeci->Delete();
	if (pSmooth) pSmooth->Delete();

	vtkTransformTextureCoords *xform = vtkTransformTextureCoords::New();
		xform->SetInput(tmapper->GetOutput());
		xform->SetScale(4,4,4);
	tmapper->Delete();
		
	vtkDataSetMapper *map = vtkDataSetMapper::New();
	map->SetInput( tmapper->GetOutput());
	map->ScalarVisibilityOff();
	
	map->Update();
	if (!roiVolumeActor) {
		roiVolumeActor = vtkActor::New();
		roiVolumeActor->GetProperty()->FrontfaceCullingOn();
		roiVolumeActor->GetProperty()->BackfaceCullingOn();
	}
	roiVolumeActor->SetMapper(map);


	map->Delete();
	
	// *****************Texture
	NSString	*location = [[NSUserDefaults standardUserDefaults] stringForKey:@"textureLocation"];
	
	if( location == 0L || [location isEqualToString:@""])
		location = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"texture.tif"];
	
	vtkTIFFReader *bmpread = vtkTIFFReader::New();
	   bmpread->SetFileName( [location UTF8String]);

	if (!texture) {
		texture = vtkTexture::New();
		texture->InterpolateOn();
	}
	texture->SetInput( bmpread->GetOutput());
	   
	bmpread->Delete();

	roiVolumeActor->SetTexture( texture);







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
	
	//vtkGaussian
	//vtkSurfaceReconstructionFilter
	//vtkContourFilter
	
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
	
//	vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();
//		power->SetInput( profile);
//
//	vtkPolyDataNormals *polyDataNormals = vtkPolyDataNormals::New();
//		polyDataNormals->SetInput( power->GetOutput());
//		polyDataNormals->ConsistencyOn();
//		polyDataNormals->AutoOrientNormalsOn();
//	power->Delete();
	
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
	
//	polyDataNormals->Update();
//	if( polyDataNormals->GetOutput()->GetNumberOfPoints() < 1)
//	{
//		NSLog( @"%d", polyDataNormals->GetOutput()->GetNumberOfPoints());
//		NSLog( @"vtkPowerCrustSurfaceReconstruction failed...");
//		
//		vtkDelaunay3D *del = vtkDelaunay3D::New();
//			del->SetInput( profile);
//			del->SetTolerance( 0.001);
//			del->SetAlpha( 20);
////			del->SetOffset( 50);
//			del->BoundingTriangulationOff();
////			profile->Delete();
//		
//		polyDataNormals->Delete();
//		
//		polyDataNormals = vtkPolyDataNormals::New();
//			polyDataNormals->SetInput( power->GetOutput());
//			polyDataNormals->ConsistencyOn();
//			polyDataNormals->AutoOrientNormalsOn();
//			del->Delete();
//	}
	

//	vtkTextureMapToSphere *tmapper = vtkTextureMapToSphere::New();
//		tmapper -> SetInput (polyDataNormals->GetOutput());
//		tmapper -> PreventSeamOn();
//	polyDataNormals->Delete();
//
//	vtkTransformTextureCoords *xform = vtkTransformTextureCoords::New();
//		xform->SetInput(tmapper->GetOutput());
//		xform->SetScale(4,4,4);
//	tmapper->Delete();
//
//	vtkDataSetMapper *map = vtkDataSetMapper::New();
//		map->SetInput( xform->GetOutput());
//		map->ScalarVisibilityOff();
//	xform->Delete();
//	
//	roiVolumeActor = vtkActor::New();
//		roiVolumeActor->SetMapper( map);
//		roiVolumeActor->GetProperty()->SetColor(1, 0, 0);
//		roiVolumeActor->GetProperty()->SetSpecular( 0.3);
//		roiVolumeActor->GetProperty()->SetSpecularPower( 20);
//		roiVolumeActor->GetProperty()->SetAmbient( 0.2);
//		roiVolumeActor->GetProperty()->SetDiffuse( 0.8);
//		roiVolumeActor->GetProperty()->SetOpacity(0.5);
//	map->Delete();
	
	// Texture
//
//	NSString	*location = [[NSUserDefaults standardUserDefaults] stringForKey:@"textureLocation"];
//
//	if( location == 0L || [location isEqualToString:@""])
//		location = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"texture.tif"];
//	
//	vtkTIFFReader *bmpread = vtkTIFFReader::New();
//       bmpread->SetFileName( [location UTF8String]);
//
//		texture = vtkTexture::New();
//		texture->SetInput( bmpread->GetOutput());
//		texture->InterpolateOn();
//	bmpread->Delete();
//	
//	roiVolumeActor->SetTexture(texture);
	
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
	
	if(!ballActor) {
		ballActor = vtkActor::New();
		ballActor->GetProperty()->SetSpecular( 0.5);
		ballActor->GetProperty()->SetSpecularPower( 20);
		ballActor->GetProperty()->SetAmbient( 0.2);
		ballActor->GetProperty()->SetDiffuse( 0.8);
		ballActor->GetProperty()->SetOpacity( 0.8);
	}
	ballActor->SetMapper( mapBalls);

	mapBalls->Delete();
	
	profile->Delete();
	
	aRenderer->AddActor( ballActor);
	
	roiVolumeActor->GetProperty()->FrontfaceCullingOn();
	roiVolumeActor->GetProperty()->BackfaceCullingOn();
	
	aRenderer->AddActor( roiVolumeActor);
	
	// *********************** Orientation Cube
	
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

	cube->TextEdgesOff();
	cube->CubeOn();
	cube->FaceTextOn();
	if (!orientationWidget) {
		orientationWidget = vtkOrientationMarkerWidget::New();	
		orientationWidget->SetInteractor( [self getInteractor] );
		orientationWidget->SetViewport( 0.90, 0.90, 1, 1);
	}
	orientationWidget->SetOrientationMarker( cube );
	orientationWidget->SetEnabled( 1 );
	orientationWidget->InteractiveOff();
	cube->Delete();

	orientationWidget->On();
	
	// *********************** Camera
	
	aCamera = aRenderer->GetActiveCamera();
	aCamera->Zoom(1.5);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aCamera->SetParallelProjection( false);
	aCamera->SetViewAngle( 60);
	aRenderer->ResetCamera();		

	
	[self coView: self];

	[splash close];
	[splash release];

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

- (void) setOpacity: (float) opacity showPoints: (BOOL) sp showSurface: (BOOL) sS showWireframe:(BOOL) w texture:(BOOL) tex useColor:(BOOL) usecol color:(NSColor*) col
{
	if( sp == NO) aRenderer->RemoveActor( ballActor);
	else aRenderer->AddActor( ballActor);

	if( sS == NO) aRenderer->RemoveActor( roiVolumeActor);
	else aRenderer->AddActor( roiVolumeActor);

	if( w) roiVolumeActor->GetProperty()->SetRepresentationToWireframe();
	else roiVolumeActor->GetProperty()->SetRepresentationToSurface();

	roiVolumeActor->GetProperty()->SetOpacity( opacity);
	
	NSColor*	rgbCol = [col colorUsingColorSpaceName: NSDeviceRGBColorSpace];
	
	if( usecol) roiVolumeActor->GetProperty()->SetColor( [rgbCol redComponent], [rgbCol greenComponent], [rgbCol blueComponent]);
	else roiVolumeActor->GetProperty()->SetColor( 1, 1, 1);
	
	if( tex) roiVolumeActor->SetTexture(texture);
	else roiVolumeActor->SetTexture( 0L);
	
	[self setNeedsDisplay: YES];
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
			NSNumber *number = [NSNumber numberWithDouble:cellPoints[k]];
			[ptSet addObject:number];
		 }
	}
	cellIds -> Delete();
	//NSLog(@"number in Set: %d\n%@", [ptSet count], ptSet);
	return ptSet;
}

@end
