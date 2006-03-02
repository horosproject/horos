/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "MIPView.h"
#import "MIPController.h"
#import "DCMPix.h"
#import "ROI.h"
#import "DCMView.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include "math.h"
#import "QuicktimeExport.h"
#import "BrowserController.h"
#include "vtkImageResample.h"
#import "DICOMExport.h"
#import "Wait.h"

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

extern BrowserController *browserWindow;

extern long DatabaseIndex;
extern BOOL DICOMFILEINDATABASE, OPENVIEWER;

extern "C"
{
OSErr VRObject_MakeObjectMovie (FSSpec *theMovieSpec, FSSpec *theDestSpec, long maxFrames);
extern NSString * documentsDirectory();
}

typedef struct _xyzArray
{
	short x;
	short y;
	short z;
} xyzArray;

long bresenham_linie_3D(long x1, long y1, long z1, long x2, long y2, long z2, long *noPixels, xyzArray *pixels)
{
    long	i, dx, dy, dz, l, m, n, x_inc, y_inc, z_inc, err_1, err_2, dx2, dy2, dz2;
    long	pixel[3];
	
	*noPixels = 0;
    pixel[0] = x1;
    pixel[1] = y1;
    pixel[2] = z1;
    dx = x2 - x1;
    dy = y2 - y1;
    dz = z2 - z1;
    x_inc = (dx < 0) ? -1 : 1;
    l = abs(dx);
    y_inc = (dy < 0) ? -1 : 1;
    m = abs(dy);
    z_inc = (dz < 0) ? -1 : 1;
    n = abs(dz);
    dx2 = l << 1;
    dy2 = m << 1;
    dz2 = n << 1;

    if ((l >= m) && (l >= n)) {
        err_1 = dy2 - l;
        err_2 = dz2 - l;
        for (i = 0; i < l; i++) {
			pixels[*noPixels].x = pixel[0];
			pixels[*noPixels].y = pixel[1];
			pixels[*noPixels].z = pixel[2];
			(*noPixels)++;
			
            if (err_1 > 0) {
                pixel[1] += y_inc;
                err_1 -= dx2;
            }
            if (err_2 > 0) {
                pixel[2] += z_inc;
                err_2 -= dx2;
            }
            err_1 += dy2;
            err_2 += dz2;
            pixel[0] += x_inc;
        }
    } else if ((m >= l) && (m >= n)) {
        err_1 = dx2 - m;
        err_2 = dz2 - m;
        for (i = 0; i < m; i++) {
			pixels[*noPixels].x = pixel[0];
			pixels[*noPixels].y = pixel[1];
			pixels[*noPixels].z = pixel[2];
			(*noPixels)++;
            if (err_1 > 0) {
                pixel[0] += x_inc;
                err_1 -= dy2;
            }
            if (err_2 > 0) {
                pixel[2] += z_inc;
                err_2 -= dy2;
            }
            err_1 += dx2;
            err_2 += dz2;
            pixel[1] += y_inc;
        }
    } else {
        err_1 = dy2 - n;
        err_2 = dx2 - n;
        for (i = 0; i < n; i++) {
			pixels[*noPixels].x = pixel[0];
			pixels[*noPixels].y = pixel[1];
			pixels[*noPixels].z = pixel[2];
			(*noPixels)++;
            if (err_1 > 0) {
                pixel[1] += y_inc;
                err_1 -= dz2;
            }
            if (err_2 > 0) {
                pixel[0] += x_inc;
                err_2 -= dz2;
            }
            err_1 += dy2;
            err_2 += dx2;
            pixel[2] += z_inc;
        }
    }
	pixels[*noPixels].x = pixel[0];
	pixels[*noPixels].y = pixel[1];
	pixels[*noPixels].z = pixel[2];
	(*noPixels)++;
}

// intersect3D_SegmentPlane(): intersect a segment and a plane
//    Input:  S = a segment, and Pn = a plane = {Point V0; Vector n;}
//    Output: *I0 = the intersect point (when it exists)
//    Return: 0 = disjoint (no intersection)
//            1 = intersection in the unique point *I0
//            2 = the segment lies in the plane

#define SMALL_NUM  0.00000001 // anything that avoids division overflow
#define DOT(v1,v2) (v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2])

int intersect3D_SegmentPlane( float *P0, float *P1, float *Pnormal, float *Ppoint, float* resultPt )
{
    float    u[ 3];
	float    w[ 3];
	
	u[ 0]  = P1[ 0] - P0[ 0];
	u[ 1]  = P1[ 1] - P0[ 1];
	u[ 2]  = P1[ 2] - P0[ 2];
	
	w[ 0] =  P0[ 0] - Ppoint[ 0];
	w[ 1] =  P0[ 1] - Ppoint[ 1];
	w[ 2] =  P0[ 2] - Ppoint[ 2];
	
    float     D = DOT(Pnormal, u);
    float     N = -DOT(Pnormal, w);

    if (fabs(D) < SMALL_NUM) {          // segment is parallel to plane
        if (N == 0)                     // segment lies in plane
            return 0;
        else
            return 0;                   // no intersection
    }
	
    // they are not parallel
    // compute intersect param
	
    float sI = N / D;
    if (sI < 0 || sI > 1)
        return 0;						// no intersection

    resultPt[ 0] = P0[ 0] + sI * u[ 0];		// compute segment intersect point
	resultPt[ 1] = P0[ 1] + sI * u[ 1];
	resultPt[ 2] = P0[ 2] + sI * u[ 2];
	
    return 1;
}

/*
class vtkPlaneCallback : public vtkCommand
{
public:
  static vtkPlaneCallback *New() 
    { return new vtkPlaneCallback; }
  void Delete()
    { delete this; }
  virtual void Execute(vtkObject *caller, unsigned long, void*)
    {
		vtkPlaneWidget *widget = reinterpret_cast<vtkPlaneWidget*>(caller);
		
		vtkPlane *pd1 = vtkPlane::New();
		widget->GetPlane( pd1);
		pd1->Push( -30);
		
		vtkVolume *volume = widget->GetProp3D();
		vtkVolumeRayCastMapper *mapper = volume->GetMapper();		//vtkVolumeRayCastMapper
		
		mapper->RemoveAllClippingPlanes();
		
		mapper->AddClippingPlane( pd1);
		pd1->Delete();
		
		pd1 = vtkPlane::New();
		widget->GetPlane( pd1);
		pd1->Push( 30);
		
		double x[3];
		pd1->GetNormal(x);
		
		x[0] = -x[0];   x[1] = -x[1];   x[2] = -x[2];
		pd1->SetNormal(x);
		
		mapper->AddClippingPlane( pd1);
		pd1->Delete();
		
		widget->SetHandleSize( 0.005);
	}
};*/

static void startRendering(vtkObject*,unsigned long c, void* ptr, void*)
{
	MIPView *mipv = (MIPView*) ptr;
	
	//vtkRenderWindow
	//[self renderWindow] SetAbortRender( true);
	if( c == vtkCommand::StartEvent)
	{
		[mipv newStartRenderingTime];
	}
	
	if( c == vtkCommand::EndEvent)
	{
		[mipv stopRendering];
		[[mipv startRenderingTime] release];
	}
	
	if( c == vtkCommand::AbortCheckEvent)
	{
		if( [[NSDate date] timeIntervalSinceDate:[mipv startRenderingTime]] > 2.0)
		{
			[mipv startRendering];
			[mipv runRendering];
		}
	}
}

class vtkMyCallback : public vtkCommand
{
public:
	vtkVolume *blendingVolume;
	
	void setBlendingVolume(vtkVolume *bV)
	{
		blendingVolume = bV;
	}
	
  static vtkMyCallback *New( ) 
    {
		return new vtkMyCallback;
	}
  void Delete()
    { delete this; }
  virtual void Execute(vtkObject *caller, unsigned long, void*)
    {
    //  vtkTransform *t = vtkTransform::New();
		vtkBoxWidget *widget = reinterpret_cast<vtkBoxWidget*>(caller);
	//	widget->GetTransform(t);
	//	widget->GetProp3D()->SetUserTransform(t);
		
		vtkPolyData *pd = vtkPolyData::New();
		widget->GetPolyData( pd);
		
		vtkVolume *volume = (vtkVolume*) widget->GetProp3D();
		vtkVolumeRayCastMapper *mapper = (vtkVolumeRayCastMapper*) volume->GetMapper();		//vtkVolumeRayCastMapper
		
		
		vtkPlanes   *planes = vtkPlanes::New();
		widget->GetPlanes( planes);
		
		long i;
		mapper->RemoveAllClippingPlanes();
		for( i = 0; i < planes->GetNumberOfPlanes(); i++)
		{
			mapper->AddClippingPlane( planes->GetPlane( i));
		}
		

		if( blendingVolume)
		{
			vtkVolumeRayCastMapper *blendingMapper = (vtkVolumeRayCastMapper*) blendingVolume->GetMapper();		//vtkVolumeRayCastMapper
			blendingMapper->RemoveAllClippingPlanes();
			for( i = 0; i < planes->GetNumberOfPlanes(); i++)
			{
				blendingMapper->AddClippingPlane( planes->GetPlane( i));
			}
		}
		
		planes->Delete();
		
		widget->SetHandleSize( 0.005);
    }
};

@implementation MIPView

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [cur intValue] != -1) [self Azimuth: [self rotation] / [max floatValue]];
	return [self nsimageQuicktime];
}

-(IBAction) endQuicktimeSettings:(id) sender
{
	[export3DWindow orderOut:sender];
	
	[NSApp endSheet:export3DWindow returnCode:[sender tag]];
	
	numberOfFrames = [framesSlider intValue];
	bestRenderingMode = [[quality selectedCell] tag];
	
	if( [[rotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [sender tag])
	{
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :numberOfFrames];
		
		[mov generateMovie: YES :[self bounds] :NO];
		
		[mov release];
	}
}

-(float) rotation {return rotationValue;}
-(float) numberOfFrames {return numberOfFrames;}

-(void) Azimuth:(float) a
{
	aCamera->Azimuth( a);
	aCamera->OrthogonalizeViewUp();
}

#define DATABASEPATH @"/DATABASE/"
-(IBAction) endDCMExportSettings:(id) sender
{
	[exportDCMWindow orderOut:sender];
	
	[NSApp endSheet:exportDCMWindow returnCode:[sender tag]];
	
	numberOfFrames = [dcmframesSlider intValue];
	bestRenderingMode = [[dcmquality selectedCell] tag];
	if( [[dcmrotation selectedCell] tag] == 1) rotationValue = 360;
	else rotationValue = 180;
	
	if( [sender tag])
	{
		// CURRENT image only
		if( [[dcmExportMode selectedCell] tag] == 0)
		{
			NSString		*dstPath = 0L;
			NSString        *OUTpath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
			BOOL			isDir = YES;
	
			if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];

			do
			{
				dstPath = [NSString stringWithFormat:@"%@%d.dcm", OUTpath, DatabaseIndex];
				DatabaseIndex++;
			}
			while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
	
			if( dstPath)
			{
				long	width, height, spp, bpp, err, cwl, cww;
				float	o[ 9];
				
				if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
				
				unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :NO];
				
				if( dataPtr)
				{
					if( exportDCM == 0L) exportDCM = [[DICOMExport alloc] init];
					
					[exportDCM setSourceFile: [firstObject sourceFile]];
					[exportDCM setSeriesDescription:@"3D VR"];
					[exportDCM setSeriesNumber:5400];
					[exportDCM setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
					
					err = [exportDCM writeDCMFile: dstPath];
					if( err)  NSRunCriticalAlertPanel( @"Error",  NSLocalizedString( @"Error during the creation of the DICOM File!", 0L), @"OK", nil, nil);
					else [browserWindow addToDatabaseFiles:[NSArray arrayWithObject: dstPath]];
					
					free( dataPtr);
				}
			}
		}
		else // A 3D sequence
		{
			NSString		*dstPath = 0L;
			NSString        *OUTpath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
			BOOL			isDir = YES;
			long			i;
			DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
			
			Wait *progress = [[Wait alloc] initWithString:@"Creating a DICOM series"];
			[progress showWindow:self];
			[[progress progress] setMaxValue: numberOfFrames];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];
			
			[dcmSequence setSeriesNumber:5400 + [[NSCalendarDate date] minuteOfHour] ];
			[dcmSequence setSeriesDescription:@"3D VR"];
			[dcmSequence setSourceFile: [firstObject sourceFile]];
			
			for( i = 0; i < numberOfFrames; i++)
			{
				if( croppingBox->GetEnabled()) croppingBox->Off();
				aRenderer->RemoveActor(outlineRect);
				
				if( bestRenderingMode)
				{
					volumeMapper->SetMinimumImageSampleDistance( 1.5);
					volumeMapper->SetSampleDistance( 2.0);
					volumeProperty->SetInterpolationTypeToLinear();

					if( blendingController)
					{
						blendingVolumeMapper->SetMinimumImageSampleDistance( 1.5);
						blendingVolumeMapper->SetSampleDistance( 2.0);
						
						blendingVolumeProperty->SetInterpolationTypeToLinear();
					}
				}
				noWaitDialog = YES;
				[self display];
				noWaitDialog = NO;
				if( bestRenderingMode)
				{
					volumeMapper->SetMinimumImageSampleDistance( LOD);
					volumeMapper->SetSampleDistance( 4.0);
					//volumeProperty->SetInterpolationTypeToNearest();

					if( blendingController)
					{
						blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
						blendingVolumeMapper->SetSampleDistance( 4.0);
						//blendingVolumeProperty->SetInterpolationTypeToNearest();
					}
				}
				
				aRenderer->AddActor(outlineRect);

				do
				{
					dstPath = [NSString stringWithFormat:@"%@%d.dcm", OUTpath, DatabaseIndex];
					DatabaseIndex++;
				}
				while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
				
				if( dstPath)
				{
					long	width, height, spp, bpp, err;
					
					unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES :NO];
					
					if( dataPtr)
					{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						
						[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
						
						err = [dcmSequence writeDCMFile: dstPath];
						if( err == 0) [browserWindow addToDatabaseFiles:[NSArray arrayWithObject: dstPath]];
						
						free( dataPtr);
						[pool release];
					}
				}
				
				[self Azimuth: (float) rotationValue / (float) numberOfFrames];
				
				[progress incrementBy: 1];
			}
			
			[progress close];
			[progress release];
			
			[dcmSequence release];
		}
	}
}

-(IBAction) endQuicktimeVRSettings:(id) sender
{
	[export3DVRWindow orderOut:sender];
	
	[NSApp endSheet:export3DVRWindow returnCode:[sender tag]];
	
	numberOfFrames = [[VRFrames selectedCell] tag];
	bestRenderingMode = [[VRquality selectedCell] tag];
	
	rotationValue = 360;
	
	if( [sender tag])
	{
		NSString	*path, *newpath;
		FSRef		fsref;
		FSSpec		spec, newspec;
		QuicktimeExport *mov;
		
		if( numberOfFrames == 10 || numberOfFrames == 20)
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames*numberOfFrames];
		else
			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames];
		
		[mov setCodec:kMPEG4VisualCodecType :codecHighQuality];
		
		path = [mov generateMovie: NO :[self bounds] :NO];
		if( path)
		{
			FSPathMakeRef((unsigned const char *)[path fileSystemRepresentation], &fsref, NULL);
			FSGetCatalogInfo( &fsref, kFSCatInfoNone,NULL, NULL, &spec, NULL);
			
			FSMakeFSSpec(spec.vRefNum, spec.parID, "\ptempMovie", &newspec);
			
			if( numberOfFrames == 10 || numberOfFrames == 20)
				VRObject_MakeObjectMovie (&spec,&newspec, numberOfFrames*numberOfFrames);
			else
				VRObject_MakeObjectMovie (&spec,&newspec, numberOfFrames);
			
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			
			newpath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tempMovie"];
			
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
			
			[[NSFileManager defaultManager] movePath: newpath  toPath: path handler: nil];
		}
		[mov release];
		
		[[NSWorkspace sharedWorkspace] openFile:path];
	}
}

-(IBAction) exportDICOM:(id) sender
{
	[NSApp beginSheet: exportDCMWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

-(IBAction) exportQuicktime3DVR:(id) sender
{
	[NSApp beginSheet: export3DVRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

- (IBAction) exportQuicktime3D :(id) sender
{
	long i;
	
    [NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:0L contextInfo:(void*) 0L];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
	return YES;
}

- (NSDate*) startRenderingTime
{
	return startRenderingTime;
}

- (void) newStartRenderingTime
{
	startRenderingTime = [[NSDate date] retain];
}

-(void) startRendering
{
	if( noWaitDialog == NO)
	{
		[splash start];
	}
}

-(void) runRendering
{
	if( noWaitDialog == NO)
	{
		if( [splash run] == NO)
		{
			[self renderWindow]->SetAbortRender( true);
		}
	}
}

-(void) stopRendering
{
	if( noWaitDialog == NO)
	{
		[splash end];
	}
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == blendingController) // our blended serie is closing itself....
	{
		[self setBlendingPixSource:0L];
		[self setNeedsDisplay:YES];
	}
}

-(NSImage*) imageForFrameVR:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	if( [cur intValue] == -1)
	{
		aCamera->GetPosition( camPosition);
		aCamera->GetViewUp( camFocal);
		
		return [self nsimageQuicktime];
	}
	
	if( [max intValue] > 36)
	{
		long line = [cur floatValue] / numberOfFrames;
		long deg = [cur floatValue] - numberOfFrames*numberOfFrames;
		long val =  (360*line) / (numberOfFrames);
		
		if( [cur intValue] % numberOfFrames == 0)
		{
			aCamera->SetPosition( camPosition);
			
			if( val >= 90 && val <= 270) 
			{
				double viewUpCopy[ 3];
				
				viewUpCopy[ 0] = -camFocal[ 0];
				viewUpCopy[ 1] = -camFocal[ 1];
				viewUpCopy[ 2] = -camFocal[ 2];
				
				aCamera->SetViewUp( viewUpCopy);
				
				if( val == 90) aCamera->Elevation( 90.1);
				else if( val == 270) aCamera->Elevation( 269.9);
				else aCamera->Elevation( val);
			}
			else
			{
				
				aCamera->SetViewUp( camFocal);
				
				aCamera->Elevation( -val);
			}
			
			double viewUp[ 3];
			
			aCamera->GetViewUp( viewUp);
			NSLog(@"%0.0f, %0.0f, %0.0f", viewUp[0], viewUp[1], viewUp[2]);
		}
		
		if( val >= 90 && val <= 270) aCamera->Azimuth( -360 / numberOfFrames);
		else aCamera->Azimuth( 360 / numberOfFrames);
	}
	else
	{
		aCamera->Azimuth( 360 / numberOfFrames);
	}
	
	return [self nsimageQuicktime];
}

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame] )
    {
		splash = [[WaitRendering alloc] init:@"Rendering..."];
//		[[splash window] makeKeyAndOrderFront:self];
		
		currentTool = t3DRotate;
		blendingController = 0L;
		blendingFactor = 0.5;
		blendingVolume = 0L;
		exportDCM = 0L;
		currentOpacityArray = 0L;
		
		ROIUPDATE = NO;
		
		noWaitDialog = NO;
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
    }
    
    return self;
}

-(void) set3DStateDictionary:(NSDictionary*) dict
{
	float   temp[ 3];
	NSArray *tempArray;
	
	if( dict)
	{
		[self setWLWW: [[dict objectForKey:@"WL"] longValue] :[[dict objectForKey:@"WW"] longValue]];
		
		tempArray = [dict objectForKey:@"CameraPosition"];
		aCamera->SetPosition( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);

		tempArray = [dict objectForKey:@"CameraViewUp"];
		aCamera->SetViewUp( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);

		tempArray = [dict objectForKey:@"CameraFocalPoint"];
		aCamera->SetFocalPoint( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue], [[tempArray objectAtIndex:2] floatValue]);
		
		tempArray = [dict objectForKey:@"CameraClipping"];
		aCamera->SetClippingRange( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue]);
	}
}

-(NSMutableDictionary*) get3DStateDictionary
{
	double temp[ 3];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:[NSNumber numberWithLong:wl] forKey:@"WL"];
	[dict setObject:[NSNumber numberWithLong:ww] forKey:@"WW"];
	
	aCamera->GetPosition( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], 0L] forKey:@"CameraPosition"];
	aCamera->GetViewUp( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], 0L] forKey:@"CameraViewUp"];
	aCamera->GetFocalPoint( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], 0L] forKey:@"CameraFocalPoint"];
	aCamera->GetClippingRange( temp);
	[dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]], 0L] forKey:@"CameraClipping"];

	return dict;
}

-(void)dealloc
{
    NSLog(@"Dealloc MIPView");
	
	[exportDCM release];
	
	[currentOpacityArray release];
	[splash close];
	[splash release];
	
//	if([firstObject isRGB]) free( dataFRGB);
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];

//	cropcallback->Delete();
	
	[self setBlendingPixSource: 0L];

	red->Delete();
	green->Delete();
	blue->Delete();

	opacityTransferFunction->Delete();
	volumeProperty->Delete();
	compositeFunction->Delete();
	volumeMapper->Delete();
	volume->Delete();
	outlineData->Delete();
	mapOutline->Delete();
	outlineRect->Delete();
	croppingBox->Delete();
	textWLWW->Delete();
	colorTransferFunction->Delete();
	reader->Delete();
    aCamera->Delete();
//	aRenderer->Delete();
	
	ROI3DData->Delete();
	ROI3D->Delete();
	ROI3DActor->Delete();
	
    [pixList release];
    pixList = 0L;
	
//	free( data8);
	
    [super dealloc];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	noWaitDialog = YES;
	
	[super rightMouseDown:theEvent];
	
	noWaitDialog = NO;
}

-(void) movieBlendingChangeSource:(long) index
{
	if( blendingController)
	{
		[blendingPixList release];
		blendingPixList = [blendingController pixList: index];
		[blendingPixList retain];
		
		blendingData = [blendingController volumePtr: index];
		blendingSrcf.data = blendingData;
		
		vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);
		
		[self setNeedsDisplay:YES];
	}
}

-(void) movieChangeSource:(float*) volumeData
{
	// Le 4D Viewer ne supporte pas le RGB pour l'instant....
	
	data = volumeData;
	
//	srcf.height = [firstObject pheight] * [pixList count];
//	srcf.width = [firstObject pwidth];
//	srcf.rowBytes = [firstObject pwidth] * sizeof(float);
//	
//	dst8.height = [firstObject pheight] * [pixList count];
//	dst8.width = [firstObject pwidth];
//	dst8.rowBytes = [firstObject pwidth] * sizeof(char);
//	
//	dst8.data = data8;
//	srcf.data = data;
//	
//	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
	
	[self setNeedsDisplay:YES];
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
    
	if( c == 27)
	{
		[[[self window] windowController] offFullscren];
	}
	
	if( (c == NSCarriageReturnCharacter || c == NSEnterCharacter || c == NSDeleteCharacter) && currentTool == t3DCut)
	{
		long			tt, stackMax, stackOrientation, i;
		vtkPoints		*roiPts = ROI3DData->GetPoints();
		double			xyz[ 3], cameraProj[ 3], cameraProjObj[ 3];
		float			vector[ 9];
		NSMutableArray *ROIList = [NSMutableArray arrayWithCapacity:0];
		
		if( roiPts->GetNumberOfPoints() < 3)
		{
			NSRunAlertPanel(@"3D Cut", @"Draw a ROI on the 3D image and then press Return(include) or Delete(exclude) keys.", @"OK", nil, nil);
		}
		else
		{
			QDDisplayWaitCursor( true);
			NSLog(@"Scissor Start");
			[[[self window] windowController] prepareUndo];
			
			vtkMatrix4x4 *ActorMatrix = volume->GetUserMatrix();
			vtkTransform *Transform = vtkTransform::New();
			
			Transform->SetMatrix( ActorMatrix);
			Transform->Push();
			
			aCamera->GetViewPlaneNormal( cameraProj);
			aCamera->GetPosition( xyz);
			
			xyz[ 0] /= factor;
			xyz[ 1] /= factor;
			xyz[ 2] /= factor;
			
			[firstObject orientation: vector];
			
			cameraProjObj[ 0] = cameraProj[ 0] * vector[ 0] + cameraProj[ 1] * vector[ 1] + cameraProj[ 2] * vector[ 2];
			cameraProjObj[ 1] = cameraProj[ 0] * vector[ 3] + cameraProj[ 1] * vector[ 4] + cameraProj[ 2] * vector[ 5];
			cameraProjObj[ 2] = cameraProj[ 0] * vector[ 6] + cameraProj[ 1] * vector[ 7] + cameraProj[ 2] * vector[ 8];
						
			if( fabs( cameraProjObj[ 0]) > fabs(cameraProjObj[ 1]) && fabs(cameraProjObj[ 0]) > fabs(cameraProjObj[ 2]))
			{
				NSLog(@"X Stack");
				stackOrientation = 0;
			}
			else if( fabs(cameraProjObj[ 1]) > fabs(cameraProjObj[ 0]) && fabs(cameraProjObj[ 1]) > fabs(cameraProjObj[ 2]))
			{
				NSLog(@"Y Stack");
				stackOrientation = 1;
			}
			else
			{
				NSLog(@"Z Stack");
				stackOrientation = 2;
			}
			
			switch( stackOrientation)
			{
				case 0:		stackMax = [firstObject pwidth];		break;
				case 1:		stackMax = [firstObject pheight];		break;
				case 2:		stackMax = [pixList count];				break;
			}
			
			for( i = 0 ; i < stackMax ; i++)
				[ROIList addObject: [[[ROI alloc] initWithType: tCPolygon :[firstObject pixelSpacingX]*factor :[firstObject pixelSpacingY]*factor :NSMakePoint( [firstObject originX], [firstObject originY])] autorelease]];
				
			for( tt = 0; tt < roiPts->GetNumberOfPoints(); tt++)
			{
				float	point1[ 3], point2[ 3];
				long	x, y, z;
				
				double	point2D[ 3], *pp;
				
				roiPts->GetPoint( tt, point2D);
				aRenderer->SetDisplayPoint( point2D[ 0], point2D[ 1], 0);
				aRenderer->DisplayToWorld();
				pp = aRenderer->GetWorldPoint();
				
				pp[ 0] /= factor;
				pp[ 1] /= factor;
				pp[ 2] /= factor;
				
			//	NSLog(@"point: %f %f %f", pp[ 0], pp[ 1], pp[ 2]);
				
				if( aCamera->GetParallelProjection())
				{
					NSLog(@"Cam Proj: %f %f %f",cameraProj[ 0], cameraProj[ 1], cameraProj[ 2]);
					
					aCamera->GetPosition( xyz);
					
					xyz[ 0] = pp[0] + cameraProj[ 0] * 1000;
					xyz[ 1] = pp[1] + cameraProj[ 1] * 1000;
					xyz[ 2] = pp[2] + cameraProj[ 2] * 1000;
									
					// Go beyond the object...
									
					pp[0] = xyz[ 0] + (pp[0] - xyz[ 0]) * 1000;
					pp[1] = xyz[ 1] + (pp[1] - xyz[ 1]) * 1000;
					pp[2] = xyz[ 2] + (pp[2] - xyz[ 2]) * 1000;
					
					point1[ 0] = xyz[ 0];
					point1[ 1] = xyz[ 1];
					point1[ 2] = xyz[ 2];
							
					point2[ 0] = pp[ 0];
					point2[ 1] = pp[ 1];
					point2[ 2] = pp[ 2];
				}
				else
				{
					// Go beyond the object...
					
					point1[ 0] = xyz[ 0];
					point1[ 1] = xyz[ 1];
					point1[ 2] = xyz[ 2];
				
					point2[0] = xyz[ 0] + (pp[0] - xyz[ 0])*1000;
					point2[1] = xyz[ 1] + (pp[1] - xyz[ 1])*1000;
					point2[2] = xyz[ 2] + (pp[2] - xyz[ 2])*1000;		
				}
				
			//	NSLog( @"Start Pt : x=%f, y=%f, z=%f"	, point1[ 0], point1[ 1], point1[ 2]);
			//	NSLog( @"End Pt : x=%f, y=%f, z=%f"		, point2[ 0], point2[ 1], point2[ 2]);
							
				// Intersection between this line and planes in Z direction
				for( x = 0; x < stackMax; x++)
				{
					float	planeVector[ 3];
					float	point[ 3];
					float	resultPt[ 3];
					double	vPos[ 3];
					
					volume->GetPosition( vPos); // factor
//
					vPos[ 0] /= factor;
					vPos[ 1] /= factor;
					vPos[ 2] /= factor;
										
//					vPos[ 0] = [firstObject originX];
//					vPos[ 1] = [firstObject originY];
//					vPos[ 2] = [firstObject originZ];
					
					switch( stackOrientation)
					{
						case 0:
							point[ 0] = x * [firstObject pixelSpacingX];
							point[ 1] = 0;
							point[ 2] = 0;
														
							planeVector[ 0] =  vector[ 0];
							planeVector[ 1] =  vector[ 1];
							planeVector[ 2] =  vector[ 2];
						break;
						
						case 1:
							point[ 0] = 0;
							point[ 1] = x * [firstObject pixelSpacingY];
							point[ 2] = 0;
							
							planeVector[ 0] =  vector[ 3];
							planeVector[ 1] =  vector[ 4];
							planeVector[ 2] =  vector[ 5];
						break;
						
						case 2:
							point[ 0] = 0;
							point[ 1] = 0;
							point[ 2] = x * [firstObject sliceInterval];
							
							planeVector[ 0] =  vector[ 6];
							planeVector[ 1] =  vector[ 7];
							planeVector[ 2] =  vector[ 8];
						break;
					}
					
					point[ 0] += vPos[ 0];
					point[ 1] += vPos[ 1];
					point[ 2] += vPos[ 2];
					
					Transform->TransformPoint(point,point);
					
					if( intersect3D_SegmentPlane( point2, point1, planeVector, point, resultPt ))
					{
						float	tempPoint3D[ 3];
						long	ptInt[ 3];
						long	roiID;
						// Convert this 3D point to 2D point projected in the plane
						
						Transform->Inverse();
						Transform->TransformPoint(resultPt,tempPoint3D);
						Transform->Inverse();
						
						tempPoint3D[ 0] -= vPos[ 0];
						tempPoint3D[ 1] -= vPos[ 1];
						tempPoint3D[ 2] -= vPos[ 2];
						
						tempPoint3D[0] /= [firstObject pixelSpacingX];
						tempPoint3D[1] /= [firstObject pixelSpacingY];
						tempPoint3D[2] /= [firstObject sliceInterval];
						
					//	tempPoint3D[0] /= factor;
					//	tempPoint3D[1] /= factor;
					//	tempPoint3D[2] /= factor;
						
						ptInt[ 0] = (tempPoint3D[0] + 0.5);
						ptInt[ 1] = (tempPoint3D[1] + 0.5);
						ptInt[ 2] = (tempPoint3D[2] + 0.5);
						
//						if( ptInt[0] >= 0 && ptInt[0] < [firstObject pwidth] && ptInt[1] >= 0 && ptInt[1] < [firstObject pheight] &&  ptInt[ 2] >= 0 && ptInt[ 2] < [pixList count])
//						{						
//							// Test delete...
//							
//							float *src = [[pixList objectAtIndex: ptInt[ 2]] fImage];
//							*(src + (long) ptInt[1] * [firstObject pwidth] + (long) ptInt[0]) = 10000;
//						}
						
						switch( stackOrientation)
						{
							case 0:	
								roiID = ptInt[0];
								
								if( roiID >= 0 && roiID < stackMax)
									[[ [ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[1], ptInt[2])]];
							break;
							
							case 1:
								roiID = ptInt[1];
								
								if( roiID >= 0 && roiID < stackMax)
									[[ [ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[2])]];
							break;
							
							case 2:
								roiID = ptInt[2];
								
								if( roiID >= 0 && roiID < stackMax)
									[[ [ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[1])]];
							break;
						}
						//NSLog(@"Slide ID: %d", roiID);
					}
				}
			}
			
			Transform->Delete();
		}
		
		// Fill ROIs
		
		// Create a scheduler
		id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
		[sched setDelegate: self];
		
		// Create the work units. These can be anything. We will use NSNumbers
		NSMutableSet *unitsSet = [NSMutableSet set];
		for ( i = 0; i < stackMax; i++ )
		{
			[unitsSet addObject: [NSArray arrayWithObjects: [NSNumber numberWithInt:i], [NSNumber numberWithInt:stackOrientation], [NSNumber numberWithInt: c], [ROIList objectAtIndex: i], 0L]];
		}
		// Perform work schedule
		[sched performScheduleForWorkUnits:unitsSet];
	}
	
	[super keyDown:event];
}

-(void) schedulerDidFinishSchedule: (Scheduler *)scheduler
{
	// Delete current ROI
	vtkPoints *pts = vtkPoints::New();
	vtkCellArray *rect = vtkCellArray::New();
	ROI3DData-> SetPoints( pts);		pts->Delete();
	ROI3DData-> SetLines( rect);		rect->Delete();
	
	//vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
	//[self setNeedsDisplay:YES];
	
	NSLog(@"Scissor End");
	QDDisplayWaitCursor( false);
	
	// Update everything..
	ROIUPDATE = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateVolumeData" object: pixList userInfo: 0];
	
	[scheduler release];
}

-(void)performWorkUnits:(NSSet *)workUnits forScheduler:(Scheduler *)scheduler
{
	NSEnumerator *enumerator = [workUnits objectEnumerator];
	NSArray	*object;
	
	while (object = [enumerator nextObject])
	{
		[[[self window] windowController] applyScissor : object];
	}
}

- (IBAction) undo:(id) sender
{
	[[[self window] windowController] undo: sender];
}

- (void) timerUpdate:(id) sender
{
	if( ROIUPDATE == YES)
		[self display];
		
	ROIUPDATE = NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL		keepOn = YES;
    NSPoint		mouseLoc, mouseLocStart;
	short		tool;
	
	noWaitDialog = YES;
	tool = currentTool;
	
	if (([theEvent modifierFlags] & NSControlKeyMask))  tool = tRotate;
	if (([theEvent modifierFlags] & NSShiftKeyMask))  tool = tZoom;
	if (([theEvent modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
	if (([theEvent modifierFlags] & NSAlternateKeyMask))  tool = tWL;
	if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask))  tool = tRotate;
	
	if( tool == t3DCut)
	{
		double	*pp;
		long	i;
		
		QDDisplayWaitCursor( true);
		
		// Click point 3D to 2D
		
		mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: 0L];
		
		aRenderer->SetDisplayPoint( mouseLocStart.x, mouseLocStart.y, 0);
		aRenderer->DisplayToWorld();
		pp = aRenderer->GetWorldPoint();
		
		// Create the 2D Actor
		
		aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
		aRenderer->WorldToDisplay();
		
		double *tempPoint = aRenderer->GetDisplayPoint();
		
		NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
		
		vtkPoints *pts = ROI3DData->GetPoints();
		pts->InsertPoint( pts->GetNumberOfPoints(), tempPoint[0], tempPoint[ 1], 0);
		
		vtkCellArray *rect = vtkCellArray::New();
		rect->InsertNextCell( pts->GetNumberOfPoints()+1);
		for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
		rect->InsertCellPoint( 0);
		
		ROI3DData->SetVerts( rect);
		ROI3DData->SetLines( rect);		rect->Delete();
		
		ROI3DData->SetPoints( pts);
		
		if( ROIUPDATE == NO)
		{
			ROIUPDATE = YES;
			[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:0]; 
		}
		
		QDDisplayWaitCursor( false);
	}
	else if( tool == tWL)
    {
        long	startWW = ww, startWL = wl;
		
        mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
        
		volumeMapper->SetMinimumImageSampleDistance( 6);
		
		do
		{
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
            mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
            switch ([theEvent type])
            {
            case NSLeftMouseDragged:
			{
				float WWAdapter  = startWW / 200.0;
				
				wl = (long) startWL + (long) (mouseLoc.y - mouseLocStart.y)*WWAdapter;
				ww = (long) startWW + (long) (mouseLoc.x - mouseLocStart.x)*WWAdapter;
				if( ww < 1) ww = 1;
		//      vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
				
				[self setOpacity: currentOpacityArray];
				colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
				
				sprintf(WLWWString, "WL: %d WW: %d", wl, ww);
				textWLWW->SetInput( WLWWString);
				
		//		colorTransferFunction->BuildFunctionFromTable( wl - ww/2, wl + ww/2, 255, (double*) &table);
		//		colorTransferFunction->SetRange(wl + ww/2, wl - ww/2);
				
                [self setNeedsDisplay:YES];
			}
            break;
			
            case NSLeftMouseUp:
                noWaitDialog = NO;
                keepOn = NO;
                break;
                
            case NSPeriodic:
                
                break;
                
            default:
                break;
            }
        }while (keepOn);
		
		volumeMapper->SetMinimumImageSampleDistance( LOD);
		
		// vtkRenderer vtkActor
		//aRenderer->Render();
		[self setNeedsDisplay:YES];
	}
	else if( tool == tRotate)
	{
		int shiftDown = 0;
		int controlDown = 1;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getVTKRenderWindowInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getVTKRenderWindowInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				noWaitDialog = NO;
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				break;
			case NSPeriodic:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == t3DRotate)
	{
		int shiftDown = 0;//([theEvent modifierFlags] & NSShiftKeyMask);
		int controlDown = 0;//([theEvent modifierFlags] & NSControlKeyMask);

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getVTKRenderWindowInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
		[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getVTKRenderWindowInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				noWaitDialog = NO;
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				break;
			case NSPeriodic:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == tTranslate)
    {
		int shiftDown = 1;
		int controlDown = 0;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getVTKRenderWindowInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
		[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getVTKRenderWindowInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				noWaitDialog = NO;
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				break;
			case NSPeriodic:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == tZoom)
    {
		int shiftDown = 0;
		int controlDown = 1;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		[self getVTKRenderWindowInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			[self getVTKRenderWindowInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				noWaitDialog = NO;
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				break;
			case NSPeriodic:
				[self getVTKRenderWindowInteractor]->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
    else [super mouseDown:theEvent];
	
	croppingBox->SetHandleSize( 0.005);
	
	noWaitDialog = NO;
}

-(void) setCurrentTool:(short) i
{
	long previousTool = currentTool;
	
    currentTool = i;
	
	if( currentTool != t3DRotate)
	{
		if( croppingBox->GetEnabled()) croppingBox->Off();
	}
	
	if( currentTool == t3DCut && previousTool == t3DCut)
	{
		vtkPoints		*roiPts = ROI3DData->GetPoints();
		
		if( roiPts->GetNumberOfPoints() != 0)
		{
			// Delete current ROI
			vtkPoints *pts = vtkPoints::New();
			vtkCellArray *rect = vtkCellArray::New();
			ROI3DData-> SetPoints( pts);		pts->Delete();
			ROI3DData-> SetLines( rect);		rect->Delete();
			
			[self setNeedsDisplay:YES];
		}
	}
}

- (void) getWLWW:(long*) iwl :(long*) iww
{
    *iwl = (long) wl;
    *iww = (long) ww;
}

-(void) setBlendingWLWW:(long) iwl :(long) iww
{
    double newValues[2];
    
	blendingWl = iwl;
	blendingWw = iww;
	
	vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);
	
    [self setNeedsDisplay:YES];
}

-(void) setBlendingFactor:(float) a
{
	long	i;
	float   val, ii;
	double  alpha[ 256];
	
	if( blendingController)
	{
		blendingFactor = a;
		
		if( a <= 0)
		{
			a += 256;
			
			for(i=0; i < 256; i++) 
			{
				ii = i;
				val = (a * ii) / 256.;
				
				if( val > 255) val = 255;
				if( val < 0) val = 0;
				
				alpha[ i] = val / 255.;
			}
		}
		else
		{
			if( a == 256)
			{
				for(i=0; i < 256; i++)
				{
					alpha[ i] = 1.0;
				}
			}
			else
			{
				for(i=0; i < 256; i++) 
				{
					ii = i;
					val = (256. * ii)/(256 - a);
					
					if( val > 255) val = 255;
					if( val < 0) val = 0;
					
					alpha[ i] = val / 255.0;
				}
			}
		}
		
		blendingOpacityTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &alpha);
		
		[self setNeedsDisplay: YES];
	}
}

-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long	i;
	
	if( r)
	{
		for( i = 0; i < 256; i++)
		{
			table[i][0] = r[i] / 255.;
			table[i][1] = g[i] / 255.;
			table[i][2] = b[i] / 255.;
		}
		blendingColorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
	else
	{
		for( i = 0; i < 256; i++)
		{
			table[i][0] = i / 255.;
			table[i][1] = i / 255.;
			table[i][2] = i / 255.;
		}
		blendingColorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
	
    [self setNeedsDisplay:YES];
}

-(void) setOpacity:(NSArray*) array
{
	long		i;
	NSPoint		pt;
	float		start = wl - ww/2, end = wl + ww/2;
	
	if( currentOpacityArray != array)
	{
		[currentOpacityArray release];
		currentOpacityArray = [array retain];
	}
	
	opacityTransferFunction->RemoveAllPoints();
	
	if( [array count] > 0)
	{
		pt = NSPointFromString( [array objectAtIndex: 0]);
		pt.x -=1000;
		if(pt.x != 0) opacityTransferFunction->AddPoint(0 +start, 0);
		else NSLog(@"start point");
	}
	else opacityTransferFunction->AddPoint(0 +start, 0);
	
	for( i = 0; i < [array count]; i++)
	{
		pt = NSPointFromString( [array objectAtIndex: i]);
		pt.x -= 1000;
		opacityTransferFunction->AddPoint(start + (pt.x / 256.0) * (end - start), pt.y);
	}
	
	if( [array count] == 0 || pt.x != 256) opacityTransferFunction->AddPoint(end, 1);
	else
	{
		opacityTransferFunction->AddPoint(end, pt.y);
		NSLog(@"end point");
	}
	
	[self setNeedsDisplay:YES];
}

-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long	i;
	
	if( [firstObject isRGB])
	{
		if( r)
		{
			for( i = 0; i < 256; i++)
			{
				table[i][0] = r[i] / 255.;
				table[i][1] = g[i] / 255.;
				table[i][2] = b[i] / 255.;
			}
			
			colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
			
			volumeProperty->SetColor( 1, colorTransferFunction);
			volumeProperty->SetColor( 2, colorTransferFunction);
			volumeProperty->SetColor( 3, colorTransferFunction);
		}
		else
		{
			volumeProperty->SetColor( 1,red);
			volumeProperty->SetColor( 2,green);
			volumeProperty->SetColor( 3,blue);
		}
	}
	else
	{
		if( r)
		{
			for( i = 0; i < 256; i++)
			{
				table[i][0] = r[i] / 255.;
				table[i][1] = g[i] / 255.;
				table[i][2] = b[i] / 255.;
			}
			
			colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
		}
		else
		{
			for( i = 0; i < 256; i++)
			{
				table[i][0] = i / 255.;
				table[i][1] = i / 255.;
				table[i][2] = i / 255.;
			}
			
			colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
		}
	}
	
    [self setNeedsDisplay:YES];
}

- (void) setWLWW:(long) iwl :(long) iww
{
	if( iwl == 0 && iww == 0)
	{
		iwl = [[pixList objectAtIndex:0] fullwl];
		iww = [[pixList objectAtIndex:0] fullww];
	}
	
	wl = iwl;
	ww = iww;
//	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
	
	[self setOpacity: currentOpacityArray];
	colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
	
	sprintf(WLWWString, "WL: %d WW: %d", wl, ww);
	textWLWW->SetInput( WLWWString);

	[self setNeedsDisplay:YES];
}

-(void) bestRendering:(id) sender
{
	[splash setCancel:YES];
	
	// Best Rendering...
	if( croppingBox->GetEnabled()) croppingBox->Off();
	
	aRenderer->RemoveActor(outlineRect);
	
	if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	{
		volumeMapper->SetMinimumImageSampleDistance( 1.0);
		volumeMapper->SetSampleDistance( 1.0);
	}
	else
	{
		volumeMapper->SetMinimumImageSampleDistance( 1.5);
		volumeMapper->SetSampleDistance( 2.0);
	}
	volumeProperty->SetInterpolationTypeToLinear();

	if( blendingController)
	{
		if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
		{
			blendingVolumeMapper->SetMinimumImageSampleDistance( 1.0);
			blendingVolumeMapper->SetSampleDistance( 1.0);
		}
		else
		{
			blendingVolumeMapper->SetMinimumImageSampleDistance( 1.5);
			blendingVolumeMapper->SetSampleDistance( 2.0);
		}
		blendingVolumeProperty->SetInterpolationTypeToLinear();
	}
	
	[self display];
	
	// Standard Rendering...
	volumeMapper->SetMinimumImageSampleDistance( LOD);
	volumeMapper->SetSampleDistance( 4.0);
	//volumeProperty->SetInterpolationTypeToNearest();

	if( blendingController)
	{
		blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		blendingVolumeMapper->SetSampleDistance( 4.0);
		//blendingVolumeProperty->SetInterpolationTypeToNearest();
	}
	
	aRenderer->AddActor(outlineRect);
	
	[splash setCancel:NO];
}

-(void) axView:(id) sender
{
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();

//	aCamera->SetViewUp (0, 1, 0);
//	aCamera->SetFocalPoint (0, 0, 0);
//	aCamera->SetPosition (0, 0, -1);
//	aCamera->SetRoll(180);
//	aCamera->Dolly(1.5);
//	aRenderer->ResetCamera();
	croppingBox->SetHandleSize( 0.005);
	[self setNeedsDisplay:YES];
}

-(void) saView:(id) sender
{
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (1, 0, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();


//	aCamera->SetViewUp (0, 1, 0);
//	aCamera->SetFocalPoint (0, 0, 0);
//	aCamera->SetPosition (-1, 0, 0);
//	aCamera->SetRoll(90);
//	aCamera->Dolly(1.5);
//	aRenderer->ResetCamera();
	
	croppingBox->SetHandleSize( 0.005);
	[self setNeedsDisplay:YES];
}

-(void) coView:(id) sender
{
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, -1, 0);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, 0, 1);
	aCamera->OrthogonalizeViewUp();
	aRenderer->ResetCamera();

//	aCamera->SetViewUp (0, 1, 0);
//	aCamera->SetFocalPoint (0, 0, 0);
//    aCamera->SetPosition (0, -1, 0);
//	aCamera->Dolly(1.5);
//	aRenderer->ResetCamera();
	croppingBox->SetHandleSize( 0.005);
	[self setNeedsDisplay:YES];
}

-(void) setLOD:(float) f
{
	if( f != LOD)
	{
		LOD = f;
		volumeMapper->SetMinimumImageSampleDistance( LOD);
		volumeMapper->SetSampleDistance( 4.0);
		
		[self setNeedsDisplay:YES];
	}
}

-(void) setBlendingPixSource:(ViewerController*) bC
{
    long i;
	
	blendingController = bC;
	
	if( blendingController)
	{
		blendingPixList = [bC pixList];
		[blendingPixList retain];

		blendingData = [bC volumePtr];

		blendingFirstObject = [blendingPixList objectAtIndex:0];

		float blendingSliceThickness = ([blendingFirstObject sliceInterval]);
		
		if( blendingSliceThickness == 0)
		{
			NSLog(@"Blending slice interval = slice thickness!");
			blendingSliceThickness = [blendingFirstObject sliceThickness];
		}
		NSLog(@"slice: %0.2f", blendingSliceThickness);

		// PLAN 
		[blendingFirstObject orientation:blendingcosines];
				
//		if( blendingcosines[6] + blendingcosines[7] + blendingcosines[8] < 0 && cosines[6] + cosines[7] + cosines[8] > 0)
//		{
//			NSLog(@"Oposite Vector!");
//			blendingSliceThickness = -blendingSliceThickness;
//		}
//		
//		if( blendingcosines[6] + blendingcosines[7] + blendingcosines[8] > 0 && cosines[6] + cosines[7] + cosines[8] < 0)
//		{
//			NSLog(@"Oposite Vector!");
//			blendingSliceThickness = -blendingSliceThickness;
//		}
		
		// Convert float to char
		
		blendingSrcf.height = [blendingFirstObject pheight] * [blendingPixList count];
		blendingSrcf.width = [blendingFirstObject pwidth];
		blendingSrcf.rowBytes = [blendingFirstObject pwidth] * sizeof(float);
		
		blendingDst8.height = [blendingFirstObject pheight] * [blendingPixList count];
		blendingDst8.width = [blendingFirstObject pwidth];
		blendingDst8.rowBytes = [blendingFirstObject pwidth] * sizeof(char);
		
		blendingData8 = (char*) malloc( blendingDst8.height * blendingDst8.width * sizeof(char));
		
		blendingDst8.data = blendingData8;
		blendingSrcf.data = blendingData;
		
		blendingWl = [blendingFirstObject wl];
		blendingWw = [blendingFirstObject ww];
		
		vImageConvert_PlanarFtoPlanar8( &blendingSrcf, &blendingDst8, blendingWl + blendingWw/2, blendingWl - blendingWw/2, 0);
		
		blendingReader = vtkImageImport::New();
		blendingReader->SetWholeExtent(0, [blendingFirstObject pwidth]-1, 0, [blendingFirstObject pheight]-1, 0, [blendingPixList count]-1);
		blendingReader->SetDataExtentToWholeExtent();
		blendingReader->SetDataScalarTypeToUnsignedChar();
//		blendingReader->SetDataOrigin(  [blendingFirstObject originX],
//										[blendingFirstObject originY],
//										[blendingFirstObject originZ]);
		blendingReader->SetImportVoidPointer(blendingData8);
		blendingReader->SetDataSpacing( factor*[blendingFirstObject pixelSpacingX], factor*[blendingFirstObject pixelSpacingY], factor*blendingSliceThickness);
//		blendingReader->SetTransform( );
		
//		tester vtkImageReader avec setTransform!!!
//		vtkI


		
//		vtkPlaneWidget  *aplaneWidget = vtkPlaneWidget::New();
//		aplaneWidget->SetOrigin( [blendingFirstObject originX], [blendingFirstObject originY], [blendingFirstObject originZ]);
//		aplaneWidget->SetNormal( normal[0], normal[1], normal[2] );
//		aplaneWidget->SetResolution(10);
//		aplaneWidget->PlaceWidget();
//		aplaneWidget->SetInteractor( [self renderWindowInteractor]);
		
//		vtkTransform	*rotation = vtkTransform::New();
//		rotation->RotateX( R2D*acos( normal[0]));
//		rotation->RotateY( R2D*acos( normal[0]));
//		rotation->RotateZ( R2D*acos( normal[0]));
//		rotation->SetInput( blendingReader->GetOutput());


		blendingColorTransferFunction = vtkColorTransferFunction::New();
		[self setBlendingCLUT:0L :0L :0L];
		
		blendingOpacityTransferFunction = vtkPiecewiseFunction::New();
		[self setBlendingFactor:blendingFactor];
	//	blendingOpacityTransferFunction->AddPoint(0, 0);
	//	blendingOpacityTransferFunction->AddPoint(255, 1);
		
		blendingVolumeProperty = vtkVolumeProperty::New();
		blendingVolumeProperty->SetColor( blendingColorTransferFunction);
		blendingVolumeProperty->SetScalarOpacity( blendingOpacityTransferFunction);
	//    volumeProperty->ShadeOn();
		blendingVolumeProperty->SetInterpolationTypeToLinear();
		
	//	vtkVolumeRayCastCompositeFunction  *compositeFunction = vtkVolumeRayCastCompositeFunction::New();
		blendingCompositeFunction = vtkVolumeRayCastMIPFunction::New();
		
		blendingVolumeMapper = vtkVolumeRayCastMapper::New();		//vtkVolumeRayCastMapper
		blendingVolumeMapper->SetVolumeRayCastFunction( blendingCompositeFunction);
		blendingVolumeMapper->SetInput( blendingReader->GetOutput());
	//	blendingVolumeMapper->SetSampleDistance( 12.0);
		LOD = 3.0;
		blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
		blendingVolumeMapper->SetSampleDistance( 4.0);
		
		blendingVolume = vtkVolume::New();
		blendingVolume->SetMapper( blendingVolumeMapper);
		blendingVolume->SetProperty( blendingVolumeProperty);
		
		vtkMatrix4x4	*matrice = vtkMatrix4x4::New();
		matrice->Element[0][0] = blendingcosines[0];			matrice->Element[1][0] = blendingcosines[1];			matrice->Element[2][0] = blendingcosines[2];			matrice->Element[3][0] = 0;
		matrice->Element[0][1] = blendingcosines[3];			matrice->Element[1][1] = blendingcosines[4];			matrice->Element[2][1] = blendingcosines[5];			matrice->Element[3][1] = 0;
		matrice->Element[0][2] = blendingcosines[6];			matrice->Element[1][2] = blendingcosines[7];			matrice->Element[2][2] = blendingcosines[8];		matrice->Element[3][2] = 0;
		matrice->Element[0][3] = 0;								matrice->Element[1][3] = 0;								matrice->Element[2][3] = 0;						matrice->Element[3][3] = 1;
		
//		blendingVolume->SetOrigin( [blendingFirstObject originX], [blendingFirstObject originY], [blendingFirstObject originZ]);
		
//		blendingFirstObject = [blendingPixList objectAtIndex:[blendingPixList count]-1];

		blendingVolume->SetPosition(	factor*[blendingFirstObject originX] * (matrice->Element[0][0]) + factor*[blendingFirstObject originY] * (matrice->Element[1][0]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][0]),
										factor*[blendingFirstObject originX] * (matrice->Element[0][1]) + factor*[blendingFirstObject originY] * (matrice->Element[1][1]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][1]),
										factor*[blendingFirstObject originX] * (matrice->Element[0][2]) + factor*[blendingFirstObject originY] * (matrice->Element[1][2]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][2]));
//		blendingVolume->SetPosition(	[blendingFirstObject originX],
//										[blendingFirstObject originY],
//										[blendingFirstObject originZ]);
		blendingVolume->SetUserMatrix( matrice);
		
//		blendingVolume->RotateWXYZ(-90, 1, 0, 0);
//		blendingVolume->RotateWXYZ(0, 0, 1, 0);
//		blendingVolume->RotateWXYZ(90, 0, 0, 1);
		
//		blendingVolume->RotateWXYZ(R2D*asin( blendingnormal[0] - normalv[0]), 1, 0, 0);
//		blendingVolume->RotateWXYZ(R2D*asin( blendingnormal[1] - normalv[1]), 0, 1, 0);
//		blendingVolume->RotateWXYZ(R2D*asin( blendingnormal[2] - normalv[2]), 0, 0, 1);
		
//		blendingVolume->SetOrientation(90, 0, -90);
//		blendingVolume->SetOrientation( R2D*acos( normal[0]), R2D*acos( normal[ 1]), R2D*acos (normal[ 2]));
//		NSLog(@"%0.1f / %0.1f / %0.1f", ( normalv[0]), ( normalv[ 1]),  (normalv[ 2]));
//		NSLog(@"%0.1f / %0.1f / %0.1f", ( blendingnormal[0]), ( blendingnormal[ 1]),  (blendingnormal[ 2]));
		
		cropcallback->setBlendingVolume( blendingVolume);
//		cropcallback->Execute(croppingBox, 0, 0L);
		
	    aRenderer->AddVolume( blendingVolume);
	}
	else
	{
		if( blendingVolume)
		{
			aRenderer->RemoveVolume( blendingVolume);
			
			blendingVolume->Delete();
			blendingVolume = 0L;
			
			blendingOpacityTransferFunction->Delete();
			blendingVolumeMapper->Delete();
			blendingCompositeFunction->Delete();
			blendingVolumeProperty->Delete();
			blendingColorTransferFunction->Delete();
			blendingReader->Delete();
			free(blendingData8);
			
			[blendingPixList release];
		}
	}
}

-(short) setPixSource:(NSMutableArray*)pix :(float*) volumeData
{
	short   error = 0;
	long	i;
    
    [pix retain];
    pixList = pix;
	
	data = volumeData;
	
	aRenderer = [self renderer];
	vtkCallbackCommand *cbStart = vtkCallbackCommand::New();
	cbStart->SetCallback( startRendering);
	cbStart->SetClientData( self);
	
	[self renderWindow]->AddObserver(vtkCommand::StartEvent, cbStart);
	[self renderWindow]->AddObserver(vtkCommand::EndEvent, cbStart);
	[self renderWindow]->AddObserver(vtkCommand::AbortCheckEvent, cbStart);
	
	firstObject = [pixList objectAtIndex:0];
	float sliceThickness = [firstObject sliceInterval];		//[[pixList objectAtIndex:1] sliceLocation] - [firstObject sliceLocation];
	
	if( sliceThickness == 0)
	{
		NSLog(@"slice interval = slice thickness!");
		sliceThickness = [firstObject sliceThickness];
	}
	
	NSLog(@"slice: %0.2f", sliceThickness);
	
	// Convert float to char
	
//	if( [firstObject isRGB])
//	{
//		// Convert RGB to BW... We could add support for RGB later if needed by users....
//		
//		long	i, size, val;
//		unsigned char	*srcPtr = (unsigned char*) data;
//		float   *dstPtr;
//		
//		size = [firstObject pheight] * [pix count];
//		size *= [firstObject pwidth];
//		size *= sizeof( float);
//		
//		dataFRGB = (float*) malloc( size);
//		
//		size /= 4;
//		
//		dstPtr = dataFRGB;
//		for( i = 0 ; i < size; i++)
//		{
//			srcPtr++;
//			val = *srcPtr++;
//			val += *srcPtr++;
//			val += *srcPtr++;
//			*dstPtr++ = val/3;
//		}
//	}
	
//	srcf.height = [firstObject pheight] * [pix count];
//	srcf.width = [firstObject pwidth];
//	srcf.rowBytes = [firstObject pwidth] * sizeof(float);
//	
//	dst8.height = [firstObject pheight] * [pix count];
//	dst8.width = [firstObject pwidth];
//	dst8.rowBytes = [firstObject pwidth] * sizeof(char);
//	
//	data8 = (char*) malloc( dst8.height * dst8.width * sizeof(char));
//	
//	dst8.data = data8;
//	srcf.data = data;
//	
//	if( [firstObject isRGB]) srcf.data = dataFRGB;
//	else srcf.data = data;
	
	wl = [firstObject wl];
	ww = [firstObject ww];
	
//	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
	
	[firstObject orientation:cosines];
	
//	float invThick;
//	
//	if( cosines[6] + cosines[7] + cosines[8] < 0) invThick = -1;
//	else invThick = 1;
	
	factor = 1.0;
	if( [firstObject pixelSpacingY] < 0.5 || [firstObject pixelSpacingY] < 0.5 || sliceThickness < 0.5)
	{
		factor = 10;
		NSLog(@"Factor activated");
	}
	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);
	reader->SetDataExtentToWholeExtent();
	
//	reader->SetImportVoidPointer(data);
//	reader->SetDataScalarTypeToUnsignedShort();
	
	if( [firstObject isRGB])
	{
		reader->SetDataScalarTypeToUnsignedChar();
		reader->SetNumberOfScalarComponents( 4);
		reader->SetImportVoidPointer(data);
	}
	else
	{
		reader->SetImportVoidPointer(data);
		reader->SetDataScalarTypeToFloat();
	}
//	reader->SetDataOrigin(  [firstObject originX],
//							[firstObject originY],
//							[firstObject originZ]);
	reader->SetDataSpacing( factor*[firstObject pixelSpacingX], factor*[firstObject pixelSpacingY], factor*sliceThickness);


	// PLAN 
	

	
//	cosines[6] = cosines[1]*cosines[5] - cosines[2]*cosines[4];
//	cosines[7] = cosines[2]*cosines[3] - cosines[0]*cosines[5];
//	cosines[8] = cosines[0]*cosines[4] - cosines[1]*cosines[3];
	
//	vtkPlane *aplane = vtkPlane::New();
//	aplane->SetNormal( normalv[0], normalv[1], normalv[2]);
//	aplane->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
	
	
//	vtkPlaneWidget  *aplaneWidget = vtkPlaneWidget::New();
//	aplaneWidget->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
//	aplaneWidget->SetNormal( normal[0], normal[1], normal[2] );
//	aplaneWidget->SetResolution(10);
//	aplaneWidget->PlaceWidget();
//    aplaneWidget->SetInteractor( [self renderWindowInteractor]);
	
	
	
	
	opacityTransferFunction = vtkPiecewiseFunction::New();
	opacityTransferFunction->AddPoint(0, 0);
	opacityTransferFunction->AddPoint(255, 1);
	
//	vtkPiecewiseFunction	*colorTransferFunction = vtkPiecewiseFunction::New();
//	colorTransferFunction->AddPoint(0, 0);
//	colorTransferFunction->AddPoint(255, 1);
	
	colorTransferFunction = vtkColorTransferFunction::New();
	
	red = vtkColorTransferFunction::New();
	red->AddRGBPoint(   0, 0, 0, 0 );
	red->AddRGBPoint( 255, 1, 0, 0 );
	
	green = vtkColorTransferFunction::New();
	green->AddRGBPoint(   0, 0, 0, 0 );
	green->AddRGBPoint( 255, 0, 1, 0 );
	
	blue = vtkColorTransferFunction::New();
	blue->AddRGBPoint(   0, 0, 0, 0 );
	blue->AddRGBPoint( 255, 0, 0, 1 );
	
	volumeProperty = vtkVolumeProperty::New();
	if( [firstObject isRGB])
	{
		volumeProperty->IndependentComponentsOn();
		
		volumeProperty->SetColor( 1,red);
		volumeProperty->SetColor( 2,green);
		volumeProperty->SetColor( 3,blue);
		
		volumeProperty->SetScalarOpacity( 1, opacityTransferFunction);
		volumeProperty->SetScalarOpacity( 2, opacityTransferFunction);
		volumeProperty->SetScalarOpacity( 3, opacityTransferFunction);
		
		volumeProperty->SetComponentWeight( 0, 0);
		
	}
	else
	{
		volumeProperty->SetColor( colorTransferFunction);	//	if( isRGB == NO) 
		volumeProperty->SetScalarOpacity( opacityTransferFunction);
	}
	[self setCLUT:0L :0L :0L];
	
//  volumeProperty->ShadeOn();
    volumeProperty->SetInterpolationTypeToLinear();
	
//	vtkVolumeRayCastCompositeFunction  *compositeFunction = vtkVolumeRayCastCompositeFunction::New();
	compositeFunction = vtkVolumeRayCastMIPFunction::New();
//	compositeFunction->SetMaximizeMethodToOpacity();	// SLOOOW
	compositeFunction->SetMaximizeMethodToScalarValue();
	
//	textureMapper = vtkVolumeTextureMapper2D::New();	NO MIP AVAILABLE IN vtkVolumeTextureMapper2D
//	textureMapper->SetVolumeRayCastFunction( compositeFunction);
//	textureMapper->SetInput( reader->GetOutput());
	
	volumeMapper = vtkFixedPointVolumeRayCastMapper::New();		//vtkVolumeRayCastMapper
	volumeMapper->SetBlendModeToMaximumIntensity();
	volumeMapper->SetInput( reader->GetOutput());
//	volumeMapper->SetSampleDistance( 12.0);
	LOD = 3.0;
	volumeMapper->SetMinimumImageSampleDistance( LOD);
	volumeMapper->SetSampleDistance( 4.0);
	
	volume = vtkVolume::New();
    volume->SetMapper( volumeMapper);
//  volume->SetMapper( textureMapper);
    volume->SetProperty( volumeProperty);
	
	vtkMatrix4x4	*matrice = vtkMatrix4x4::New();
	matrice->Element[0][0] = cosines[0];		matrice->Element[1][0] = cosines[1];		matrice->Element[2][0] = cosines[2];		matrice->Element[3][0] = 0;
	matrice->Element[0][1] = cosines[3];		matrice->Element[1][1] = cosines[4];		matrice->Element[2][1] = cosines[5];		matrice->Element[3][1] = 0;
	matrice->Element[0][2] = cosines[6];		matrice->Element[1][2] = cosines[7];		matrice->Element[2][2] = cosines[8];		matrice->Element[3][2] = 0;
	matrice->Element[0][3] = 0;					matrice->Element[1][3] = 0;					matrice->Element[2][3] = 0;					matrice->Element[3][3] = 1;

//	volume->SetOrigin( [firstObject originX], [firstObject originY], [firstObject originZ]);
	volume->SetPosition(	factor * [firstObject originX] * matrice->Element[0][0] + factor * [firstObject originY] * matrice->Element[1][0] + factor * [firstObject originZ]*matrice->Element[2][0],
							factor * [firstObject originX] * matrice->Element[0][1] + factor * [firstObject originY] * matrice->Element[1][1] + factor * [firstObject originZ]*matrice->Element[2][1],
							factor * [firstObject originX] * matrice->Element[0][2] + factor * [firstObject originY] * matrice->Element[1][2] + factor * [firstObject originZ]*matrice->Element[2][2]);
//	volume->SetPosition(	[firstObject originX],// * matrice->Element[0][0] + [firstObject originY] * matrice->Element[1][0] + [firstObject originZ]*matrice->Element[2][0],
//							[firstObject originY],// * matrice->Element[0][1] + [firstObject originY] * matrice->Element[1][1] + [firstObject originZ]*matrice->Element[2][1],
//							[firstObject originZ]);// * matrice->Element[0][2] + [firstObject originY] * matrice->Element[1][2] + [firstObject originZ]*matrice->Element[2][2]);
	volume->SetUserMatrix( matrice);

	outlineData = vtkOutlineFilter::New();
    outlineData->SetInput((vtkDataSet *) reader->GetOutput());
	
    mapOutline = vtkPolyDataMapper::New();
    mapOutline->SetInput(outlineData->GetOutput());
    
    outlineRect = vtkActor::New();
    outlineRect->SetMapper(mapOutline);
    outlineRect->GetProperty()->SetColor(0,1,0);
    outlineRect->GetProperty()->SetOpacity(0.5);
	outlineRect->SetUserMatrix( matrice);
	outlineRect->SetPosition(	factor * [firstObject originX] * matrice->Element[0][0] + factor * [firstObject originY] * matrice->Element[1][0] + factor * [firstObject originZ]*matrice->Element[2][0],
								factor * [firstObject originX] * matrice->Element[0][1] + factor * [firstObject originY] * matrice->Element[1][1] + factor * [firstObject originZ]*matrice->Element[2][1],
								factor * [firstObject originX] * matrice->Element[0][2] + factor * [firstObject originY] * matrice->Element[1][2] + factor * [firstObject originZ]*matrice->Element[2][2]);

	croppingBox = vtkBoxWidget::New();
	croppingBox->GetHandleProperty()->SetColor(0, 1, 0);
	
	croppingBox->SetProp3D(volume);
	croppingBox->SetPlaceFactor( 1.0);
	croppingBox->SetHandleSize( 0.005);
	croppingBox->PlaceWidget();
    croppingBox->SetInteractor( [self renderWindowInteractor]);
//	croppingBox->SetRotationEnabled( false);
	croppingBox->SetInsideOut( true);
	croppingBox->OutlineCursorWiresOff();
	cropcallback = vtkMyCallback::New();
	cropcallback->setBlendingVolume( 0L);
	croppingBox->AddObserver(vtkCommand::InteractionEvent, cropcallback);
	
/*	planeWidget = vtkPlaneWidget::New();
	
	planeWidget->GetHandleProperty()->SetColor(0, 0, 1);
	planeWidget->SetHandleSize( 0.005);
	planeWidget->SetProp3D(volume);
	planeWidget->SetResolution( 1);
	planeWidget->SetPoint1(-50, -50, -50);
	planeWidget->SetPoint2(50, 50, 50);
	planeWidget->PlaceWidget();
	planeWidget->SetRepresentationToWireframe();
    planeWidget->SetInteractor( [self renderWindowInteractor]);
	planeWidget->On();
	vtkPlaneCallback *planecallback = vtkPlaneCallback::New();
	planeWidget->AddObserver(vtkCommand::InteractionEvent, planecallback);
*/	
	textWLWW = vtkTextActor::New();
	sprintf(WLWWString, "WL: %d WW: %d", wl, ww);
	textWLWW->SetInput( WLWWString);
	textWLWW->SetScaledText( false);
	textWLWW->GetPositionCoordinate()->SetCoordinateSystemToViewport();
	textWLWW->GetPositionCoordinate()->SetValue( 2., 2.);
	aRenderer->AddActor2D(textWLWW);


    aCamera = vtkCamera::New();
	aCamera->SetViewUp (0, 1, 0);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, 1);
	aCamera->SetRoll(180);
	aCamera->SetParallelProjection( true);
//    aCamera->ComputeViewPlaneNormal();    
    
	aCamera->Dolly(1.5);

	
    aRenderer->AddVolume( volume);
	aRenderer->AddActor(outlineRect);

	aRenderer->SetActiveCamera(aCamera);
	aRenderer->ResetCamera();
	
	// 3D Cut ROI
	vtkPoints *pts = vtkPoints::New();
	vtkCellArray *rect = vtkCellArray::New();
	
	ROI3DData = vtkPolyData::New();
    ROI3DData-> SetPoints( pts);
	pts->Delete();
    ROI3DData-> SetLines( rect);
	rect->Delete();
	
	ROI3D = vtkPolyDataMapper2D::New();
	ROI3D->SetInput( ROI3DData);
	
	ROI3DActor = vtkActor2D::New();
	ROI3DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
    ROI3DActor->SetMapper( ROI3D);
	ROI3DActor->GetProperty()->SetPointSize( 5);	//vtkProperty2D
	ROI3DActor->GetProperty()->SetLineWidth( 2);
	ROI3DActor->GetProperty()->SetColor(0.3,1,0);
	
	aRenderer->AddActor2D( ROI3DActor);
	
	
	
	[self saView:self];
	
    [self setNeedsDisplay:YES];
    
    return error;
}

-(IBAction) SwitchStereoMode :(id) sender
{
	if( [self renderWindow]->GetStereoRender() == false)
	{
		[self renderWindow]->StereoRenderOn();
		[self renderWindow]->SetStereoTypeToRedBlue();
	}
	else
	{
		[self renderWindow]->StereoRenderOff();
	}
	
	[self setNeedsDisplay:YES];
}

-(IBAction) switchProjection:(id) sender
{
	aCamera->SetParallelProjection( [[sender selectedCell] tag]);
	
	[self setNeedsDisplay:YES];
}

-(void)awakeFromNib {

}

-(NSImage*) nsimageQuicktime
{
	NSImage *theIm;

	if( croppingBox->GetEnabled()) croppingBox->Off();
	
	aRenderer->RemoveActor(outlineRect);
	
	if( bestRenderingMode)
	{
		volumeMapper->SetMinimumImageSampleDistance( 1.5);
		volumeMapper->SetSampleDistance( 2.0);
		volumeProperty->SetInterpolationTypeToLinear();

		if( blendingController)
		{
			blendingVolumeMapper->SetMinimumImageSampleDistance( 1.5);
			blendingVolumeMapper->SetSampleDistance( 2.0);
			
			blendingVolumeProperty->SetInterpolationTypeToLinear();
		}
	}
	
	noWaitDialog = YES;
	[self display];
	noWaitDialog = NO;
	
	theIm = [self nsimage:YES];
	
	if( bestRenderingMode)
	{
		volumeMapper->SetMinimumImageSampleDistance( LOD);
		volumeMapper->SetSampleDistance( 4.0);
		//volumeProperty->SetInterpolationTypeToNearest();

		if( blendingController)
		{
			blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
			blendingVolumeMapper->SetSampleDistance( 4.0);
			//blendingVolumeProperty->SetInterpolationTypeToNearest();
		}
	}
	
	aRenderer->AddActor(outlineRect);
	
	return theIm;
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	unsigned char	*buf = 0L;
	long			i;
	
//	if( screenCapture)	// Pixels displayed in current window -> only RGB 8 bits data
	{
		NSRect size = [self bounds];
		
		*width = (long) size.size.width+8;
		*width/=4;
		*width*=4;
		*height = (long) size.size.height;
		*spp = 3;
		*bpp = 8;
		
		buf = (unsigned char*) malloc( *width * *height * *spp * *bpp/8);
		if( buf)
		{
			[[self openGLContext] makeCurrentContext];
			glReadPixels(0, 0, *width, *height, GL_RGB, GL_UNSIGNED_BYTE, buf);
			
			long rowBytes = *width**spp**bpp/8;
			
			unsigned char	*tempBuf = (unsigned char*) malloc( rowBytes);
			
			for( i = 0; i < *height/2; i++)
			{
				BlockMoveData( buf + (*height - 1 - i)*rowBytes, tempBuf, rowBytes);
				BlockMoveData( buf + i*rowBytes, buf + (*height - 1 - i)*rowBytes, rowBytes);
				BlockMoveData( tempBuf, buf + i*rowBytes, rowBytes);
			}
		}
	}
//	else NSLog(@"Err getRawPixels...");
		
	return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
	NSBitmapImageRep	*rep;
	long				width, height, i, spp, bpp;
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
	
	BlockMoveData( dataPtr, [rep bitmapData], height*width*bpp*spp/8);
	
	//Add the small OsiriX logo at the bottom right of the image
	NSImage				*logo = [NSImage imageNamed:@"SmallLogo.tif"];
	NSBitmapImageRep	*TIFFRep = [[NSBitmapImageRep alloc] initWithData: [logo TIFFRepresentation]];
	
	for( i = 0; i < [TIFFRep pixelsHigh]; i++)
	{
		BlockMoveData(		[TIFFRep bitmapData] + i*[TIFFRep bytesPerRow],
							[rep bitmapData] + (height - [TIFFRep pixelsHigh] + i)*[rep bytesPerRow] + ((width-10)*3 - [TIFFRep bytesPerRow]),
							[TIFFRep bytesPerRow]);
	}
	
	[TIFFRep release];
	
     NSImage *image = [[NSImage alloc] init];
     [image addRepresentation:rep];
     
	 free( dataPtr);
	 
    return image;
}

-(void) showCropCube:(id) sender
{
	if( croppingBox->GetEnabled()) croppingBox->Off();
	else
	{
		croppingBox->On();
		
		[self setCurrentTool: t3DRotate];
		[[[[self window] windowController] toolsMatrix] selectCellWithTag: t3DRotate];
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

- (IBAction) resetImage:(id) sender
{
	aCamera->SetViewUp (0, 1, 0);
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, 1);
	aCamera->SetRoll(180);
//	aCamera->SetParallelProjection( true);
	aCamera->Dolly(1.5);
	aRenderer->ResetCamera();
	[self saView:self];
    [self setNeedsDisplay:YES];
}
@end
