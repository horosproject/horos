/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
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
#import "BrowserController.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#import "QuicktimeExport.h"
#import "Notifications.h"
#import "AppController.h"
#import "N2Debug.h"
#import "DicomDatabase.h"
#import "ROI.h"

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
	unsigned char	*buf = nil;
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
		
		CGLContextObj cgl_ctx = (CGLContextObj) [[NSOpenGLContext currentContext] CGLContextObj];
		
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
		
		{
			unsigned char	*tempBuf = (unsigned char*) malloc( rowBytes);
			
			for( i = 0; i < *height/2; i++)
			{
				memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
				memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
				memcpy( buf + i*rowBytes, tempBuf, rowBytes);
			}
			
			free( tempBuf);
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
	long				width, height, spp, bpp;
	NSString			*colorSpace;
	unsigned char		*dataPtr;
	
	dataPtr = [self getRawPixels :&width :&height :&spp :&bpp :!originalSize : YES];

	if( spp == 3) colorSpace = NSCalibratedRGBColorSpace;
	else colorSpace = NSCalibratedWhiteColorSpace;

	rep = [[[NSBitmapImageRep alloc]
			 initWithBitmapDataPlanes:nil
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
	
	if( [panel runModalForDirectory:nil file:@"Volume Image"] == NSFileHandlingPanelOKButton)
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

- (IBAction) exportDICOMFile:(id) sender
{
	long	width, height, spp, bpp;
	
	DICOMExport *exportDCM = [[DICOMExport alloc] init];
	
	unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :YES];
	
	NSMutableArray *producedFiles = [NSMutableArray array];
	
	if( dataPtr)
	{
		ROIVolumeController *co = [[self window] windowController];
		NSArray	*pixList = [[co viewer] pixList];
		
		[exportDCM setSourceFile: [[pixList objectAtIndex: 0] sourceFile]];
		[exportDCM setSeriesDescription: [co.seriesName stringValue]];
		[exportDCM setSeriesNumber: 8856];
		[exportDCM setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
		
		NSString *f = [exportDCM writeDCMFile: nil];
		if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		if( f)
			[producedFiles addObject: [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil]];
		
		free( dataPtr);
	}

	[exportDCM release];
	
	if( [producedFiles count])
	{
		NSArray *objects = [BrowserController.currentBrowser.database addFilesAtPaths: [producedFiles valueForKey: @"file"]
                                                                    postNotifications: YES
                                                                            dicomOnly: YES
                                                                  rereadExistingItems: YES
                                                                    generatedByOsiriX: YES];
		
        objects = [BrowserController.currentBrowser.database objectsWithIDs: objects];
        
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportSendToDICOMNode"])
			[[BrowserController currentBrowser] selectServer: objects];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"afterExportMarkThemAsKeyImages"])
		{
			for( NSManagedObject *im in objects)
				[im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
		}
	}
}

- (void) CloseViewerNotification: (NSNotification*) note
{

}

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame])
    {
		NSLog(@"init ROIVolumeView");
        
		[[NSNotificationCenter defaultCenter] addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: OsirixCloseViewerNotification
				 object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: [self window]];
        
		computeMedialSurface = NO;
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	if( [self window] && [self window] == [notification object])
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
        
        [self prepareForRelease]; //Very important: VTK memory leak !
	}
}

-(void)dealloc
{	
    NSLog(@"Dealloc ROIVolumeView");
		
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
    if( roiVolumeActor)
    {
        aRenderer->RemoveActor( roiVolumeActor);
        roiVolumeActor->Delete();
    }
	
    if( texture)
        texture->Delete();
	
    if( orientationWidget)
		orientationWidget->Delete();
    
    [roi release];
    [super dealloc];
}

- (NSDictionary*) setPixSource:(ROI*) r
{
	GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
	[self getVTKRenderWindow]->MakeCurrent();
	[[NSOpenGLContext currentContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];

    [roi release];
    roi = [r retain];
    
	return [self renderVolume];
}

+ (vtkMapper*) generateMapperForRoi:(ROI*) roi viewerController: (ViewerController*) vc factor: (float) factor statistics: (NSMutableDictionary*) statistics
{
    vtkMapper *mapper = nil;
    
    NSMutableArray *generatedROIs = [NSMutableArray array];
    NSMutableArray *ptsArray = nil;
    
//    display an error !
    
    NSString *error = 0L;
    
    NSMutableArray **ptsPtr = nil;
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"UseDelaunayFor3DRoi"] != 2)
        ptsPtr = &ptsArray;
    
    float volume = [vc computeVolume: roi points: ptsPtr generateMissingROIs: YES generatedROIs: generatedROIs computeData: statistics error: &error];
    
    if( error || volume == 0) {
        
        if( error == nil)
            error = NSLocalizedString( @"Not possible to compute a volume!", nil);
        
        NSRunCriticalAlertPanel( NSLocalizedString( @"ROIs", nil), @"%@", NSLocalizedString( @"OK", nil), nil, nil, error);
        return nil;
    }
    
    vtkPolyData *profile = nil;
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"UseDelaunayFor3DRoi"] != 2)
    {
        vtkPoints *points = vtkPoints::New();
        long i = 0;
        for( NSArray *pt3D in ptsArray)
            points->InsertPoint( i++, [[pt3D objectAtIndex: 0] floatValue]*factor, [[pt3D objectAtIndex: 1] floatValue]*factor, [[pt3D objectAtIndex: 2] floatValue]*factor);
        
        profile = vtkPolyData::New();
        profile->SetPoints( points);
        points->Delete();
    }
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"UseDelaunayFor3DRoi"])
    {
        // IsoContour
        case 2:
        {
            NSData *vD = nil;
            NSMutableArray *copyPixList = nil;
            [vc copyVolumeData: &vD andDCMPix: &copyPixList forMovieIndex: vc.curMovieIndex];
            
            for( DCMPix *p in copyPixList)
                memset( p.fImage, 0, p.pheight*p.pwidth*sizeof( float));
            
            for( int z = 1; z < [copyPixList count]-1; z++) // Black 3D Frame
            {
                for( int i = 0; i < [[vc.roiList objectAtIndex: z] count]; i++)
                {
                    ROI	*curROI = [[vc.roiList objectAtIndex: z] objectAtIndex: i];
                    
                    if( [[curROI name] isEqualToString: [roi name]])
                    {
                        DCMPix *p = [copyPixList objectAtIndex: z];
                        
                        [p fillROI: curROI newVal:1000 minValue:-FLT_MAX maxValue:FLT_MAX outside:NO orientationStack:2 stackNo:0 restore:NO addition:NO spline:[curROI isSpline] clipMin:NSMakePoint(1, 1) clipMax:NSMakePoint(p.pwidth-1, p.pheight-1)];  // Black 3D Frame
                    }
                }
            }
            
            vtkImageImport *reader = vtkImageImport::New();
            reader->SetWholeExtent(0, [copyPixList.lastObject pwidth]-1, 0, [copyPixList.lastObject pheight]-1, 0, copyPixList.count-1);
            reader->SetDataExtentToWholeExtent();
            reader->SetDataScalarTypeToFloat();
            reader->SetImportVoidPointer( (void*) [vD bytes]);
            reader->SetDataSpacing( factor*[copyPixList.lastObject pixelSpacingX], factor*[copyPixList.lastObject pixelSpacingY], factor * [copyPixList.lastObject sliceInterval]);
            
            vtkContourFilter *isoExtractor = vtkContourFilter::New();
            isoExtractor->SetInput( reader->GetOutput());
            isoExtractor->SetValue(0, 500);
            
            reader->Delete();
            
            vtkPolyData* previousOutput = isoExtractor->GetOutput();
            
            BOOL useDecimate = NO;
            BOOL useSmooth = NO;
            
            vtkDecimatePro *isoDeci = nil;
            if( useDecimate)
            {
                float decimateVal = 0.5;
                
                isoDeci = vtkDecimatePro::New();
                isoDeci->SetInput( previousOutput);
                isoDeci->SetTargetReduction( decimateVal);
                isoDeci->SetPreserveTopology( TRUE);
                
                //		isoDeci->SetFeatureAngle(60);
                //		isoDeci->SplittingOff();
                //		isoDeci->AccumulateErrorOn();
                //		isoDeci->SetMaximumError(0.3);
                
                isoDeci->Update();
                previousOutput = isoDeci->GetOutput();
            }
            
            vtkSmoothPolyDataFilter *isoSmoother = nil;
            if( useSmooth)
            {
                float smoothVal = 20;
                
                isoSmoother = vtkSmoothPolyDataFilter::New();
                isoSmoother->SetInput( previousOutput);
                isoSmoother->SetNumberOfIterations( smoothVal);
                //		isoSmoother->SetRelaxationFactor(0.05);
                
                isoSmoother->Update();
                previousOutput = isoSmoother->GetOutput();
            }
            
            
            vtkPolyDataNormals *isoNormals = vtkPolyDataNormals::New();
            isoNormals->SetInput( previousOutput);
            isoNormals->SetFeatureAngle( 120);
            
            vtkPolyDataMapper *isoMapper = vtkPolyDataMapper::New();
            isoMapper->SetInput( isoNormals->GetOutput());
            isoMapper->ScalarVisibilityOff();
            
            isoMapper->Update();
            
            mapper = isoMapper;
            
            isoNormals->Delete();
            isoExtractor->Delete();
            
            if( isoDeci)
                isoDeci->Delete();
            
            if( isoSmoother)
                isoSmoother->Delete();
        }
            break;
            
            // Delaunay
        case 1:
        {
            vtkDelaunay3D *delaunayTriangulator = vtkDelaunay3D::New();
            delaunayTriangulator->SetInput( profile);
            
            delaunayTriangulator->SetTolerance( 0.001);
            delaunayTriangulator->SetAlpha( 20);
            delaunayTriangulator->BoundingTriangulationOff();
            
            vtkTextureMapToSphere *tmapper = vtkTextureMapToSphere::New();
            tmapper->SetInput( (vtkDataSet*) delaunayTriangulator->GetOutput());
            tmapper->PreventSeamOn();
            
            vtkDataSetMapper *map = vtkDataSetMapper::New();
            map->SetInput( tmapper->GetOutput());
            map->ScalarVisibilityOff();
            
            map->Update();
            
            mapper = map;
            
            tmapper->Delete();
            delaunayTriangulator->Delete();
            
        }
            break;
            
            // PowerCrust
        case 0:
        {
            vtkPowerCrustSurfaceReconstruction *power = vtkPowerCrustSurfaceReconstruction::New();
            power->SetInput( profile);
            
            vtkPolyDataNormals *polyDataNormals = vtkPolyDataNormals::New();
            polyDataNormals->ConsistencyOn();
            polyDataNormals->AutoOrientNormalsOn();
            polyDataNormals->SetInput(power->GetOutput());
            power->Delete();
            
            vtkTextureMapToSphere *tmapper = vtkTextureMapToSphere::New();
            tmapper->SetInput( polyDataNormals->GetOutput());
            tmapper->PreventSeamOn();
            
            vtkDataSetMapper *map = vtkDataSetMapper::New();
            map->SetInput( tmapper->GetOutput());
            map->ScalarVisibilityOff();
            
            map->Update();
            
            mapper = map;
            
            tmapper->Delete();
            polyDataNormals->Delete();
        }
            break;
    }
    
    if( profile)
        profile->Delete();
    
    //Delete the generated ROIs - There was no generated ROIs previously
    for( ROI *c in generatedROIs)
    {
        NSInteger index = [vc imageIndexOfROI: c];
        
        if( index >= 0)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object: c userInfo: nil];
            [[vc.roiList objectAtIndex: index] removeObject: c];
        }
    }
    
    return mapper;
}

- (NSDictionary*) renderVolume
{
	WaitRendering *splash = [[[WaitRendering alloc] init: NSLocalizedString( @"Rendering 3D Object...", nil)] autorelease];
	[splash showWindow:self];
	
	NSMutableDictionary *statistics = [NSMutableDictionary dictionary];
	
    @try
    {
        try
        {
            ROIVolumeController *vc = self.window.windowController;
            
			vtkMapper *mapper = [ROIVolumeView generateMapperForRoi: roi viewerController: vc.viewer factor: 1.0 statistics: statistics];
            if( mapper == nil)
                return nil;
            
            aRenderer = [self renderer];
            
            if( roiVolumeActor) {
                aRenderer->RemoveActor( roiVolumeActor);
                roiVolumeActor->Delete();
                roiVolumeActor = nil;
            }
            
            if (!roiVolumeActor) {
                roiVolumeActor = vtkActor::New();
                roiVolumeActor->GetProperty()->FrontfaceCullingOn();
                roiVolumeActor->GetProperty()->BackfaceCullingOn();
            }
            roiVolumeActor->SetMapper( mapper);
            
            if( mapper)
                mapper->Delete();
            
            if( [[NSUserDefaults standardUserDefaults] integerForKey: @"UseDelaunayFor3DRoi"] == 2)
            {
                ROIVolumeController *wo = self.window.windowController;
                DCMPix *o = [wo.viewer.pixList objectAtIndex: 0];
                
                roiVolumeActor->SetOrigin( o.originX, o.originY, o.originZ);
                roiVolumeActor->SetPosition( o.originX, o.originY, o.originZ);
            }
            
			// *****************Texture
			NSString *location = [[NSUserDefaults standardUserDefaults] stringForKey:@"textureLocation"];
			
			if( location == nil || [location isEqualToString:@""])
				location = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"texture.tif"];
			
			vtkTIFFReader *bmpread = vtkTIFFReader::New();
			
			bmpread->SetFileName( [location UTF8String]);

			if( !texture)
			{
				texture = vtkTexture::New();
				texture->InterpolateOn();
                texture->SetRepeat( 1);
			}
			texture->SetInput( bmpread->GetOutput());
			   
			bmpread->Delete();

			roiVolumeActor->SetTexture( texture);

			// The balls
//			
//            if( ballActor) {
//                aRenderer->RemoveActor( ballActor);
//                ballActor->Delete();
//                ballActor = nil;
//            }
//            
//            if( [[NSUserDefaults standardUserDefaults] integerForKey: @"UseDelaunayFor3DRoi"] != 2)
//            {
//                vtkPolyData *profile = nil;
//                
//                vtkPoints *points = vtkPoints::New();
//                long i = 0;
//                for( NSArray *pt3D in _points3D)
//                    points->InsertPoint( i++, [[pt3D objectAtIndex: 0] floatValue], [[pt3D objectAtIndex: 1] floatValue], [[pt3D objectAtIndex: 2] floatValue]);
//                
//                profile = vtkPolyData::New();
//                profile->SetPoints( points);
//                points->Delete();
//                
//                vtkSphereSource *ball = vtkSphereSource::New();
//                    ball->SetRadius(0.3);
//                    ball->SetThetaResolution( 12);
//                    ball->SetPhiResolution( 12);
//                
//                vtkGlyph3D *balls = vtkGlyph3D::New();
//                    balls->SetInput( profile);
//                    balls->SetSource( ball->GetOutput());
//                ball->Delete();
//                
//                vtkPolyDataMapper *mapBalls = vtkPolyDataMapper::New();
//                    mapBalls->SetInput( balls->GetOutput());
//                balls->Delete();
//                
//                if(!ballActor) {
//                    ballActor = vtkActor::New();
//                    ballActor->GetProperty()->SetSpecular( 0.5);
//                    ballActor->GetProperty()->SetSpecularPower( 20);
//                    ballActor->GetProperty()->SetAmbient( 0.2);
//                    ballActor->GetProperty()->SetDiffuse( 0.8);
//                    ballActor->GetProperty()->SetOpacity( 0.8);
//                }
//                ballActor->SetMapper( mapBalls);
//
//                if( mapBalls)
//                    mapBalls->Delete();
//                
//                if( profile)
//                    profile->Delete();
//                
//                aRenderer->AddActor( ballActor);
//			}
            
			roiVolumeActor->GetProperty()->FrontfaceCullingOn();
			roiVolumeActor->GetProperty()->BackfaceCullingOn();
			
			aRenderer->AddActor( roiVolumeActor);
			
			// *********************** Orientation Cube
			
		//	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontShow3DCubeOrientation"] == NO)
			{
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

				cube->SetTextEdgesVisibility( 1);
				cube->SetCubeVisibility( 1);
				cube->SetFaceTextVisibility( 1);

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
			}
			
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
		}
        catch(...)
        {
            printf( "***** C++ exception in %s\r", __PRETTY_FUNCTION__);
            
            if( [[NSUserDefaults standardUserDefaults] integerForKey:@"UseDelaunayFor3DRoi"] != 2) // Iso Contour
            {
                [[NSUserDefaults standardUserDefaults] setInteger: 2 forKey:@"UseDelaunayFor3DRoi"];
                [self renderVolume];
            }
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
        
        if( [[NSUserDefaults standardUserDefaults] integerForKey:@"UseDelaunayFor3DRoi"] != 2) // Iso Contour
        {
            [[NSUserDefaults standardUserDefaults] setInteger: 2 forKey:@"UseDelaunayFor3DRoi"];
            [self renderVolume];
        }
    }
    
	[splash close];

	return statistics;
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
	if( roiVolumeActor)
	{
//		if( sp == NO) aRenderer->RemoveActor( ballActor);
//		else aRenderer->AddActor( ballActor);
		
        sS = YES;
        
		if( sS == NO) aRenderer->RemoveActor( roiVolumeActor);
		else aRenderer->AddActor( roiVolumeActor);
		
		if( w) roiVolumeActor->GetProperty()->SetRepresentationToWireframe();
		else roiVolumeActor->GetProperty()->SetRepresentationToSurface();
		
		roiVolumeActor->GetProperty()->SetOpacity( opacity);
		
		NSColor* rgbCol = [col colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
		
		if( usecol) roiVolumeActor->GetProperty()->SetColor( [rgbCol redComponent], [rgbCol greenComponent], [rgbCol blueComponent]);
		else roiVolumeActor->GetProperty()->SetColor( 1, 1, 1);
		
		if( tex) roiVolumeActor->SetTexture(texture);
		else roiVolumeActor->SetTexture( nil);
	}
	
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
	cellIds->Delete();
	//NSLog(@"number in Set: %d\n%@", [ptSet count], ptSet);
	return ptSet;
}

@end
