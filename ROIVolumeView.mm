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
	}
	
	[NSOpenGLContext clearCurrentContext];
	
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
		
	 NSImage *image = [[NSImage alloc] init];
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
		
		[im release];
		
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
    
    [im release];
}

- (void) exportDICOMFile:(id) sender
{
	long	width, height, spp, bpp, err;
	float	cwl, cww;
	float	o[ 9];
	
	DICOMExport *exportDCM = [[DICOMExport alloc] init];
	
	unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :NO];
	
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
	
	roiVolumeActor->Delete();
	ballActor->Delete();
	texture->Delete();
	orientationWidget->Delete();
	
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

	vtkDelaunay3D *delaunayTriangulator = 0L;
	vtkPolyDataNormals *polyDataNormals = 0L;
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
		polyDataNormals->SetInput(  power->GetOutput());
		polyDataNormals->ConsistencyOn();
		polyDataNormals->AutoOrientNormalsOn();
		power->Delete();
		
		output = (vtkDataSet*) polyDataNormals -> GetOutput();
	}
	
	vtkTextureMapToSphere *tmapper = vtkTextureMapToSphere::New();
		tmapper -> SetInput( output);
		tmapper -> PreventSeamOn();
	
	if( polyDataNormals) polyDataNormals->Delete();
	if( delaunayTriangulator) delaunayTriangulator->Delete();

	vtkTransformTextureCoords *xform = vtkTransformTextureCoords::New();
		xform->SetInput(tmapper->GetOutput());
		xform->SetScale(4,4,4);
	tmapper->Delete();
		
	vtkDataSetMapper *map = vtkDataSetMapper::New();
	map->SetInput( tmapper->GetOutput());
	map->ScalarVisibilityOff();
	
	map->Update();
	
	roiVolumeActor = vtkActor::New();
	roiVolumeActor->SetMapper(map);
	roiVolumeActor->GetProperty()->FrontfaceCullingOn();
	roiVolumeActor->GetProperty()->BackfaceCullingOn();

	map->Delete();
	
	//Texture
	NSString	*location = [[NSUserDefaults standardUserDefaults] stringForKey:@"textureLocation"];
	
	if( location == 0L || [location isEqualToString:@""])
		location = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"texture.tif"];
	
	vtkTIFFReader *bmpread = vtkTIFFReader::New();
	   bmpread->SetFileName( [location UTF8String]);

	texture = vtkTexture::New();
	   texture->SetInput( bmpread->GetOutput());
	   texture->InterpolateOn();
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
	
	ballActor = vtkActor::New();
		ballActor->SetMapper( mapBalls);
		ballActor->GetProperty()->SetSpecular( 0.5);
		ballActor->GetProperty()->SetSpecularPower( 20);
		ballActor->GetProperty()->SetAmbient( 0.2);
		ballActor->GetProperty()->SetDiffuse( 0.8);
		ballActor->GetProperty()->SetOpacity( 0.8);
	mapBalls->Delete();
	
	profile->Delete();
	
	aRenderer->AddActor( ballActor);
	
	roiVolumeActor->GetProperty()->FrontfaceCullingOn();
	roiVolumeActor->GetProperty()->BackfaceCullingOn();
	
	aRenderer->AddActor( roiVolumeActor);
	
	// ***********************
	
	vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
	cube->SetXPlusFaceText ( "L" );
	cube->SetXMinusFaceText( "R" );
	cube->SetYPlusFaceText ( "P" );
	cube->SetYMinusFaceText( "A" );
	cube->SetZPlusFaceText ( "S" );
	cube->SetZMinusFaceText( "I" );
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

	orientationWidget = vtkOrientationMarkerWidget::New();
	orientationWidget->SetOrientationMarker( cube );
	orientationWidget->SetInteractor( [self getInteractor] );
	orientationWidget->SetViewport( 0.90, 0.90, 1, 1);
	orientationWidget->SetEnabled( 1 );
	orientationWidget->InteractiveOff();
	cube->Delete();

	orientationWidget->On();
	
	// ***********************
	
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
	
	[self coView: self];
	
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
@end
