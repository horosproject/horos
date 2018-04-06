/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "options.h"

#define USE3DCONNEXION 1

#import "VRView.h"

#import "vtkHorosFixedPointVolumeRayCastMapper.h"

#import "DCMCursor.h"
#import "AppController.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#include <OpenGL/CGLMacro.h>
#include "math.h"
#import "Wait.h"
#import "QuicktimeExport.h"
#include <vtkImageResample.h>
#import "VRController.h"
#import "BrowserController.h"
#import "DICOMExport.h"
#import "DefaultsOsiriX.h" // for HotKeys
#import "DicomDatabase.h"
#import "DicomImage.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "Notifications.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "N2Debug.h"
#import "PluginManager.h"

#include <vtkMath.h>
#include <vtkAbstractPropPicker.h>
#include <vtkInteractorStyle.h>
#include <vtkWorldPointPicker.h>
//#include <vtkOpenGLVolumeTextureMapper3D.h>
#include <vtkPropAssembly.h>
#include <vtkFixedPointRayCastImage.h>
#include <vtkSmartVolumeMapper.h>
#include <vtkSphereSource.h>
#include <vtkAssemblyPath.h>
#include <vtkDoubleArray.h>

//#define id Id
#include <itkImage.h>
#include <itkImportImageFilter.h>

#import "ITKSegmentation3D.h"
//#undef id
#import "ITKBrushROIFilter.h"
#import "OSIVoxel.h"

#include <CoreVideo/CVPixelBuffer.h>

#import <InstantMessage/IMService.h>
#import <InstantMessage/IMAVManager.h>

#ifdef _STEREO_VISION_
// ****************************
// Added SilvanWidmer 03-08-09
#import "vtkCocoaGLView.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCocoaRenderWindow.h"
#include "vtkInteractorStyleTrackballCamera.h"
#include "vtkParallelRenderManager.h"
#include "vtkRendererCollection.h"
// ****************************
#endif

#import <vtkConfigure.h>

#define MAXDYNAMICVALUE 32000.

#if USE3DCONNEXION
#include <3DConnexionClient/ConnexionClientAPI.h>
extern "C"
{
    extern OSErr InstallConnexionHandlers(ConnexionMessageHandlerProc messageHandler, ConnexionAddedHandlerProc addedHandler, ConnexionRemovedHandlerProc removedHandler) __attribute__((weak_import));
}
#endif

#define D2R 0.01745329251994329576923690768    // degrees to radians
#define R2D 57.2957795130823208767981548141    // radians to degrees

//#define BONEVALUE 250
#define BONEOPACITY 1.1

extern int dontRenderVolumeRenderingOsiriX;	// See vtkHorosFixedPointVolumeRayCastMapper.cxx
extern unsigned int minimumStep;

static NSRecursiveLock *drawLock = nil;
static unsigned short *linearOpacity = nil;
static VRView	*snVRView = nil;

typedef struct _xyzArray
{
    short x;
    short y;
    short z;
} xyzArray;

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


class vtkMyCallbackVR : public vtkCommand
{
public:
    vtkVolume *blendingVolume;
    
    void setBlendingVolume(vtkVolume *bV)
    {
        blendingVolume = bV;
    }
    
    static vtkMyCallbackVR *New( )
    {
        return new vtkMyCallbackVR;
    }
    // void Delete()
    //    { delete this; }
    
    virtual void Execute(vtkObject *caller, unsigned long, void*)
    {
        vtkBoxWidget *widget = reinterpret_cast<vtkBoxWidget*>(caller);
        
        vtkVolume *volume = (vtkVolume*) widget->GetProp3D();
        
        vtkPlanes *planes = vtkPlanes::New();
        widget->GetPlanes(planes);
        
        vtkVolumeMapper *mapper = (vtkVolumeMapper*) volume->GetMapper();
        mapper->SetClippingPlanes(planes);
        
        if( blendingVolume)
        {
            mapper = (vtkVolumeMapper*) blendingVolume->GetMapper();
            mapper->SetClippingPlanes(planes);
        }
        
        planes->Delete();
        //      double a[ 6];
        //		[VRView getCroppingBox: a :volume :widget];
        //		[VRView setCroppingBox: a :volume];
        //
        //		[VRView getCroppingBox: a :blendingVolume :widget];
        //		[VRView setCroppingBox: a :blendingVolume];
        
        //		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAutoCropScissors"] == NO)
        //			[snVRView autoCroppingBox];
        
        widget->SetHandleSize( 0.005);
    }
};


@interface VRViewOperation: NSOperation
{
    VRController *controller;
    NSArray *objects;
}

- (id) initWithController:(VRController*) c objects: (NSArray*) objects;

@end

@implementation VRViewOperation

- (id) initWithController:(VRController*) c objects:(NSArray *) o
{
    self = [super init];
    
    controller = [c retain];
    objects = [o retain];
    
    return self;
}

- (void) main
{
    @autoreleasepool
    {
        [controller applyScissor: objects];
    }
}

- (void) dealloc
{
    [controller release];
    [objects release];
    [super dealloc];
}

@end


@implementation VRView

#ifdef _STEREO_VISION_
//added SilvanWidmer
@synthesize StereoVisionOn;
//@synthesize currentTool;
#endif

@synthesize clipRangeActivated, projectionMode, clippingRangeThickness, keep3DRotateCentered, dontResetImage, renderingMode, currentOpacityArray, exportDCM, dcmSeriesString, bestRenderingMode;
@synthesize lowResLODFactor, engine, lodDisplayed;


- (BOOL) eventToPlugins: (NSEvent*) event
{
    BOOL used = NO;
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(handleEvent:forVRViewer:)])
            if ([[[PluginManager plugins] objectForKey:key] handleEvent:event forVRViewer: [[self window] windowController]])
                used = YES;
    }
    
    return used;
}

- (BOOL) checkPointInVolume: (double*) position
{
    double bounds[ 6];
    
    volume->GetBounds( bounds);
    
    if( position[ 0] <= bounds[ 0]) return NO;
    if( position[ 0] >= bounds[ 1]) return NO;
    
    if( position[ 1] <= bounds[ 2]) return NO;
    if( position[ 1] >= bounds[ 3]) return NO;
    
    if( position[ 2] <= bounds[ 4]) return NO;
    if( position[ 2] >= bounds[ 5]) return NO;
    
    return YES;
}

- (void) goToCenter
{
    double bounds[ 6];
    
    volume->GetBounds( bounds);
    
    double center[ 3] = { bounds[ 0] + (bounds[ 1] - bounds[ 0])/2., bounds[ 2] + (bounds[ 3] - bounds[ 2])/2., bounds[ 4] + (bounds[ 5] - bounds[ 4])/2.};
    
    aCamera->SetPosition( center);
    
    center[ 0] = center[ 0] ;
    center[ 1] = center[ 1] -1.;	// Sag
    center[ 2] = center[ 2] ;
    
    aCamera->SetFocalPoint( center);
    
    aCamera->OrthogonalizeViewUp();
    aCamera->ComputeViewPlaneNormal();
}

- (void) checkInVolume
{
    if( clipRangeActivated)
    {
        double position[ 3], newPosition[ 3], center[ 3];
        double distance;
        
        distance = aCamera->GetDistance();
        aCamera->GetPosition( position);
        aCamera->GetPosition( newPosition);
        
        double bounds[ 6];
        
        volume->GetBounds( bounds);
        
        if( newPosition[ 0] <= bounds[ 0]) newPosition[ 0] = bounds[ 0];
        if( newPosition[ 0] >= bounds[ 1]) newPosition[ 0] = bounds[ 1];
        
        if( newPosition[ 1] <= bounds[ 2]) newPosition[ 1] = bounds[ 2];
        if( newPosition[ 1] >= bounds[ 3]) newPosition[ 1] = bounds[ 3];
        
        if( newPosition[ 2] <= bounds[ 4]) newPosition[ 2] = bounds[ 4];
        if( newPosition[ 2] >= bounds[ 5]) newPosition[ 2] = bounds[ 5];
        
        aCamera->SetPosition( newPosition);
        
        aCamera->GetFocalPoint( center);
        
        center[ 0] += newPosition[ 0] - position[ 0];
        center[ 1] += newPosition[ 1] - position[ 1];
        center[ 2] += newPosition[ 2] - position[ 2];
        
        aCamera->SetFocalPoint( center);
        
        aCamera->OrthogonalizeViewUp();
        aCamera->ComputeViewPlaneNormal();
    }
}

- (double) getClippingRangeThickness
{
    return clippingRangeThickness / superSampling;
}

- (void) setClippingRangeThickness: (double) c
{
    c *= superSampling;
    
    clippingRangeThickness = c;
    
    if( c == 0)
        clipRangeActivated = NO;
    else
    {
        if( c < superSampling)
            c = superSampling + 0.01;
        
        clipRangeActivated = YES;
        
        if( projectionMode != 1)	// Parallel
        {
            [self setProjectionMode: 1];
            aCamera->SetFocalPoint( volume->GetCenter());
            aCamera->SetPosition( volume->GetCenter());
        }
        
        [self willChangeValueForKey:@"clippingRangeThicknessInMm"];
    }
    
    if( clipRangeActivated)
    {
        aCamera->SetClippingRange( 0, clippingRangeThickness);
    }
    else
    {
        aCamera->SetClippingRange( 0, 10000);
        aRenderer->ResetCameraClippingRange();
    }
    
    if (clipRangeActivated)
    {
        [self didChangeValueForKey:@"clippingRangeThicknessInMm"];
    }
    
    [self setNeedsDisplay: YES];
}

- (void) setClipRangeActivated: (BOOL) c
{
    if( c == NO)
        [self setClippingRangeThickness: 0];
    else
        [self setClippingRangeThickness: 2];
    
    if( dontResetImage == NO)
        [self resetImage: self];
}

- (double) getClippingRangeThicknessInMm
{
    if( volumeMapper)
    {
        if( clipRangeActivated)
            return clippingRangeThickness / factor;
    }
    return 0;
}

- (void) setClippingRangeThicknessInMm:(double) c
{
    if( volumeMapper)
    {
        if( clipRangeActivated)
            [self setClippingRangeThickness: c * factor / superSampling];
    }
}

+ (unsigned short*) linearOpacity
{
    if( linearOpacity == nil)
    {
        linearOpacity = (unsigned short*) malloc( 32767 * sizeof(unsigned short));
        
        for( int i = 0; i < 32767; i++)
            linearOpacity[ i] = i;
    }
    
    return linearOpacity;
}

+ (BOOL) getCroppingBox:(double*) a :(vtkVolume *) volume :(vtkBoxWidget*) croppingBox
{
    if( volume == nil) return NO;
    if( croppingBox == nil) return NO;
    
    vtkVolumeMapper *mapper = (vtkVolumeMapper*) volume->GetMapper();
    if( mapper)
    {
        // cropping box
        vtkPolyData *pd = vtkPolyData::New();
        croppingBox->GetPolyData(pd);
        
        vtkTransform *Transform = vtkTransform::New();
        Transform->SetMatrix(volume->GetUserMatrix());
        Transform->Push();
        Transform->Inverse();
        
        double min[3], max[3], pointA[3];
        
        for( int i = 0 ; i < 8; i++)
        {
            pd->GetPoint( i, pointA);
            //            NSLog( @"%f %f %f", pointA[ 0], pointA[ 1], pointA[ 2]);
            
            Transform->TransformPoint( pointA, pointA);
            
            if( i == 0)
            {
                min[ 0] = pointA[ 0];
                min[ 1] = pointA[ 1];
                min[ 2] = pointA[ 2];
                max[ 0] = pointA[ 0];
                max[ 1] = pointA[ 1];
                max[ 2] = pointA[ 2];
            }
            else
            {
                if( pointA[ 0] < min[ 0]) min[ 0] = pointA[ 0];
                if( pointA[ 1] < min[ 1]) min[ 1] = pointA[ 1];
                if( pointA[ 2] < min[ 2]) min[ 2] = pointA[ 2];
                
                if( pointA[ 0] > max[ 0]) max[ 0] = pointA[ 0];
                if( pointA[ 1] > max[ 1]) max[ 1] = pointA[ 1];
                if( pointA[ 2] > max[ 2]) max[ 2] = pointA[ 2];
            }
        }
        
        
        //		pd->GetPoint(8, pointA);	pd->GetPoint(9, pointB);
        //		min[0] = pointA[0];			max[0] = pointB[0];
        //
        //		pd->GetPoint(10, pointA);	pd->GetPoint(11, pointB);
        //		min[1] = pointA[1];			max[1] = pointB[1];
        //
        //		pd->GetPoint(12, pointA);	pd->GetPoint(13, pointB);
        //		min[2] = pointA[2];			max[2] = pointB[2];
        
        //		Transform->TransformPoint( min, min);
        //		Transform->TransformPoint (max, max);
        
        a[ 0] = min[ 0];
        a[ 2] = min[ 1];
        a[ 4] = min[ 2];
        
        a[ 1] = max[ 0];
        a[ 3] = max[ 1];
        a[ 5] = max[ 2];
        
        double origin[3];
        volume->GetPosition(origin);	//GetOrigin
        
        a[0] -= origin[0];		a[1] -= origin[0];
        a[2] -= origin[1];		a[3] -= origin[1];
        a[4] -= origin[2];		a[5] -= origin[2];
        
        double temp;
        if((a[0]) > (a[1]))
        {temp = a[0]; a[0] = a[1]; a[1] = temp;}
        
        if((a[2]) > (a[3]))
        {temp = a[2]; a[2] = a[3]; a[3] = temp;}
        
        if((a[4]) > (a[5]))
        {temp = a[4]; a[4] = a[5]; a[5] = temp;}
        
        pd->Delete();
        Transform->Delete();
        
        return YES;
    }
    else return NO;
}

//+ (void) setCroppingBox:(double*) a :(vtkVolume*) volume
//{
//	long	i;
//
//	if( volume == nil) return;
//
//	vtkVolumeMapper *mapper = (vtkVolumeMapper*) volume->GetMapper();
//	if( mapper)
//	{
//		mapper->SetCropping(true);
//
//		double min[3], max[3];
//
//		min[ 0] = a[ 0];
//		min[ 1] = a[ 2];
//		min[ 2] = a[ 4];
//
//		max[ 0] = a[ 1];
//		max[ 1] = a[ 3];
//		max[ 2] = a[ 5];
//
//		mapper->SetCroppingRegionPlanes( min[0], max[0], min[1], max[1], min[2], max[2]);
//	}
//}

- (void) checkForMovedVolume: (NSNotification*) notification
{
    float cos[ 9];
    BOOL valid = [self getCosMatrix: cos];
    
    if( valid)
    {
        if( Oval2DRadius > 0.001)
        {
            float position[ 3];
            [self getOrigin: position];
            
            BOOL moved = NO;
            
            for( int i = 0 ; i < 9 ; i++)
                if( Oval2DCos[ i] != cos[ i])
                    moved = YES;
            
            for( int i = 0 ; i < 3 ; i++)
                if( Oval2DPosition[ i] != position[ i])
                    moved = YES;
            
            if( moved)
            {
                [Oval2DPix release];
                Oval2DPix = nil;
                
                aRenderer->RemoveActor( Oval2DText);
                aRenderer->RemoveActor2D( Oval2DActor);
                Oval2DRadius = 0;
                [self setNeedsDisplay: YES];
            }
        }
    }
}


- (void) adaptLine2DToResize:(NSRect) newFrame before: (NSRect) beforeFrame rescale:(BOOL) rescale
{
    if( Line2DData)
    {
        vtkPoints *pts = Line2DData->GetPoints();
        
        if( pts->GetNumberOfPoints() == 2)
        {
            double pt1[ 3];
            pts->GetPoint( 0, pt1);
            
            double pt2[ 3];
            pts->GetPoint( 1, pt2);
            
            pts = vtkPoints::New();
            vtkCellArray *rect = vtkCellArray::New();
            Line2DData-> SetPoints( pts);		pts->Delete();
            Line2DData-> SetLines( rect);		rect->Delete();
            
            pts = Line2DData->GetPoints();
            
            if( rescale == NO)
            {
                pts->InsertPoint( pts->GetNumberOfPoints(), pt1[0] + (newFrame.size.width - beforeFrame.size.width)/2, pt1[ 1] + (newFrame.size.height - beforeFrame.size.height)/2 , 0);
                pts->InsertPoint( pts->GetNumberOfPoints(), pt2[0] + (newFrame.size.width - beforeFrame.size.width)/2, pt2[ 1] + (newFrame.size.height - beforeFrame.size.height)/2, 0);
            }
            else
            {
                pts->InsertPoint( pts->GetNumberOfPoints(), pt1[0] * (newFrame.size.width/beforeFrame.size.width), pt1[ 1] * (newFrame.size.height / beforeFrame.size.height) , 0);
                pts->InsertPoint( pts->GetNumberOfPoints(), pt2[0] * (newFrame.size.width/beforeFrame.size.width), pt2[ 1] * (newFrame.size.height / beforeFrame.size.height), 0);
            }
            rect = vtkCellArray::New();
            rect->InsertNextCell( pts->GetNumberOfPoints()+1);
            for( int i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
            rect->InsertCellPoint( 0);
            
            Line2DData->SetVerts( rect);
            Line2DData->SetLines( rect);		rect->Delete();
            
            Line2DData->SetPoints( pts);
            
            // Move the text
            
            pts->GetPoint( 0, pt1);
            pts->GetPoint( 1, pt2);
            
            Line2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
            if( pt1[ 0] > pt2[ 0]) Line2DText->GetPositionCoordinate()->SetValue( pt1[0] + 3, pt1[ 1]);
            else Line2DText->GetPositionCoordinate()->SetValue( pt2[0], pt2[ 1]);
        }
        else
        {
            // Delete
            
            pts = vtkPoints::New();
            vtkCellArray *rect = vtkCellArray::New();
            Line2DData-> SetPoints( pts);		pts->Delete();
            Line2DData-> SetLines( rect);		rect->Delete();
        }
    }
}

- (void) setFrame: (NSRect) r rescaleLine: (BOOL) rescale
{
    if( [[controller style] isEqualToString:@"noNib"] == NO)
        [self adaptLine2DToResize: r before: [self frame] rescale: rescale];
    
    [super setFrame: r];
}

- (void) setFrame: (NSRect) r
{
    [self setFrame: r rescaleLine: NO];
}

//- (BOOL) croppingBox:(double*) a
//{
//	BOOL validBox = [VRView getCroppingBox: a :volume :croppingBox];
//
//	return validBox;
//}
//
//- (void) setCroppingBox:(double*) a
//{
//	if( a && croppingBox)
//		[VRView setCroppingBox: a :volume];
//}
//
//- (void) setBlendingCroppingBox:(double*) a
//{
//	if( a && croppingBox)
//		[VRView setCroppingBox: a :blendingVolume];
//}

- (void) print:(id) sender
{
    bestRenderingMode = YES;
    
    [controller print: sender];
}

- (void)getOrientationText:(char *) o vector: (float *) vector inversion:(BOOL) inv
{
    NSString *orientationX;
    NSString *orientationY;
    NSString *orientationZ;
    
    NSMutableString *optr = [NSMutableString string];
    
    if( inv)
    {
        orientationX = -vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
        orientationY = -vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
        orientationZ = -vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
    }
    else
    {
        orientationX = vector[ 0] < 0 ? NSLocalizedString( @"R", @"R: Right") : NSLocalizedString( @"L", @"L: Left");
        orientationY = vector[ 1] < 0 ? NSLocalizedString( @"A", @"A: Anterior") : NSLocalizedString( @"P", @"P: Posterior");
        orientationZ = vector[ 2] < 0 ? NSLocalizedString( @"I", @"I: Inferior") : NSLocalizedString( @"S", @"S: Superior");
    }
    
    float absX = fabs( vector[ 0]);
    float absY = fabs( vector[ 1]);
    float absZ = fabs( vector[ 2]);
    
    // get first 3 AXIS
    for ( int i=0; i < 3; ++i)
    {
        if (absX>.2 && absX>=absY && absX>=absZ)
        {
            [optr appendString: orientationX]; absX=0;
        }
        else if (absY>.2 && absY>=absX && absY>=absZ)
        {
            [optr appendString: orientationY]; absY=0;
        }
        else if (absZ>.2 && absZ>=absX && absZ>=absY)
        {
            [optr appendString: orientationZ]; absZ=0;
        }
        else break;
    }
    
    strcpy( o, [optr UTF8String]);
    strcat( o, " ");
}

- (void) setBlendingMode: (long) modeID
{
    if( blendingController == nil) return;
    
    switch( modeID)
    {
        case 0:
            if( blendingVolumeMapper) blendingVolumeMapper->SetBlendModeToComposite();
            break;
            
        case 1:
            if( blendingVolumeMapper) blendingVolumeMapper->SetBlendModeToMaximumIntensity();
            break;
            
        case 2:
        case 3:
            if( blendingVolumeMapper) blendingVolumeMapper->SetBlendModeToMinimumIntensity();
            break;
    }
}

- (long) mode
{
    return renderingMode;
}

- (IBAction)setRenderMode:(id)sender
{
    long modeID = [sender tag];
    [self setMode: modeID];
    [self setBlendingMode: modeID];
}

- (void) setMode: (long) modeID
{
    renderingMode = modeID;
    
    switch( modeID)
    {
        case 0: //Volume
            if( volumeMapper)
                volumeMapper->SetBlendModeToComposite();
            
            if( textureMapper)
                textureMapper->SetBlendModeToComposite();
            break;
            
        case 1: //Max
            if( volumeMapper)
                volumeMapper->SetBlendModeToMaximumIntensity();
            
            if( textureMapper)
                textureMapper->SetBlendModeToMaximumIntensity();
            break;
            
        case 2: //Min
            if( volumeMapper)
                volumeMapper->SetBlendModeToMinimumIntensity();
            
            if( textureMapper)
                textureMapper->SetBlendModeToMinimumIntensity();
            break;
            
            
        case 3: // Mean - Effect of Mean is triggered externally by setvtkMeanIPMode
            if( volumeMapper)
                volumeMapper->SetBlendModeToMinimumIntensity();
            
            if( textureMapper)
                textureMapper->SetBlendModeToMinimumIntensity();
            break;
            
            //        case 4: // Additive mode
            //            if( volumeMapper)
            //				volumeMapper->SetBlendModeToAdditive();
            //
            //			if( textureMapper)
            //				textureMapper->SetBlendModeToAdditive();
            //        break;
    }
    
    [self setBlendingFactor: blendingFactor];
    
    [self setWLWW: wl : ww];
    
    [self setNeedsDisplay:YES];
}

- (void) setEngine: (int) newEngine
{
    [self setEngine: newEngine showWait: YES];
}

- (void) setLodDisplayed: (float) newValue
{
    [self setLOD: newValue];
}

+ (void) testGraphicBoard
{
    int vramMB = [VTKView VRAMSizeForDisplayID: [[[[NSScreen mainScreen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]];
    
    if( [[NSUserDefaults standardUserDefaults] integerForKey: @"VRAMAmount"] != vramMB)
    {
        if( vramMB >= 2000 && [AppController hasMacOSXLion])
        {
            [[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"VRDefaultViewSize"];     // full screen
            [[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"MAPPERMODEVR"];          // gpu
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"VRDefaultViewSize"];     // square
            [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"MAPPERMODEVR"];          // cpu
        }
        
        [[NSUserDefaults standardUserDefaults] setInteger: vramMB forKey: @"VRAMAmount"];
        
        NSLog( @"--- Changing Volume Rendering settings (vram: %d)", (int) vramMB);
    }
}

- (void) allocateGPUMapper
{
    if( textureMapper == nil)
    {
        textureMapper = vtkGPUVolumeRayCastMapper::New();
        textureMapper->SetInputConnection(reader->GetOutputPort());
        textureMapper->Update();
        
        unsigned
        long memoryMB = [VTKView VRAMSizeForDisplayID: [[[[[self window] screen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]];
        
        textureMapper->SetMaxMemoryInBytes( memoryMB*1024*1024);
        
        NSLog( @"Graphic Board memory: %d MiB", (int)memoryMB);
        
        textureMapper->SetMaxMemoryFraction( 0.9);
    }
    
    volume->SetMapper( textureMapper);
}

- (void) allocateCPUMapper
{
    if( volumeMapper == nil)
    {
        volumeMapper = vtkHorosFixedPointVolumeRayCastMapper::New();
        volumeMapper->SetInputConnection(reader->GetOutputPort());
    }
    
    volumeMapper->Update();
    volume->SetMapper( volumeMapper);
}

- (void) instantiateEngine: (int) e
{
    @try
    {
        //        double a[ 6];
        //		BOOL validBox = [VRView getCroppingBox: a :volume :croppingBox];
        
        switch( e)
        {
            case 0:		// FIXED RAY CAST
                [self allocateCPUMapper];
                
                LOD = 2.0;
                
                if( [[NSProcessInfo processInfo] processorCount] >= 4)
                    lowResLODFactor = 1.5;
                else
                    lowResLODFactor = 2.5;
                break;
                
            case 1:     // GPURenderMode
                [self allocateGPUMapper];
                
                LOD = 1.0;
                lowResLODFactor = 1.2;
                break;
                
            default:
                NSLog( @"Unknown Engine");
                break;
        }
        
        [self setLOD: LOD];
        [self setMode: renderingMode];	// VR or MIP ?
        
        if( firstTime == NO)
        {
            if( cropcallback)
                cropcallback->Execute( croppingBox, 0, nil);
        }
        else
        {
            if( [[controller style] isEqualToString: @"noNib"] == NO)
            {
                [self resetImage: self];
                croppingBox->PlaceWidget();
            }
        }
        
        if( volumeMapper)
        {
            volumeMapper->SetMinimumImageSampleDistance( LOD);
            volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
            volumeMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
        }
        
        if( textureMapper)
        {
            textureMapper->SetMinimumImageSampleDistance( LOD);
            textureMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
            textureMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
        }
    }
    @catch (NSException * e)
    {
        NSLog( @"setEngine exception: %@", e);
    }
}

- (void) setEngine: (long) newEngine showWait:(BOOL) showWait
{
    if( newEngine != 0 && [AppController hasMacOSXLion] == NO)
    {
        NSRunCriticalAlertPanel( NSLocalizedString(@"GPU Rendering", nil),  NSLocalizedString( @"GPU Rendering requires MacOS 10.7 or higher.", nil), NSLocalizedString( @"OK", nil), nil, nil);
        newEngine = 0;
    }
    
    if( newEngine == 1)
    {
        unsigned long vramMB = [VTKView VRAMSizeForDisplayID: [[[[[self window] screen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]];
        
        //vramMB /= 1024*1024;
        
        if( vramMB <= 512)
        {
            //NSRunCriticalAlertPanel(NSLocalizedString(@"GPU Rendering", nil),[NSString stringWithFormat: NSLocalizedString( @"Your graphic board has only %d MB of VRAM. Performances will be very limited with large dataset.", nil), vramMB],NSLocalizedString( @"OK", nil),nil,nil);
        }
    }
    
    [self willChangeValueForKey: @"engine"];
    engine = newEngine;
    [self didChangeValueForKey: @"engine"];
    
    WaitRendering *www = nil;
    
    if( showWait) www = [[WaitRendering alloc] init: NSLocalizedString( @"Preparing 3D data...", nil)];
    [www start];
    
    [self instantiateEngine: engine];
    
    switch( engine)
    {
        case 0: volume->SetMapper( volumeMapper); break;
        case 1: volume->SetMapper( textureMapper); break;
    }
    
    [self display];
    
    [www end];
    [www close];
    [www autorelease];
}

- (void) setBlendingEngine: (long) engineID
{
    [self setBlendingEngine: engineID showWait: YES];
}

- (void) setBlendingEngine: (long) engineID showWait:(BOOL) showWait
{
    if( blendingController == nil) return;
    
    WaitRendering	*www = nil;
    
    if( showWait) www = [[WaitRendering alloc] init: NSLocalizedString( @"Preparing 3D data...", nil)];
    [www start];
    
    //    double a[ 6];
    //	BOOL validBox = [VRView getCroppingBox: a :volume :croppingBox];
    
    switch( engineID)
    {
        case 0:		// RAY CAST
            if( blendingVolumeMapper == nil)
            {
                blendingVolumeMapper = vtkHorosFixedPointVolumeRayCastMapper::New();
                blendingVolumeMapper->SetInputConnection(blendingReader->GetOutputPort());
                
            }
            blendingVolumeMapper->Update();
            
            blendingVolume->SetMapper( blendingVolumeMapper);
            break;
            
        case 1:		// GPURenderMode
            
            if( blendingTextureMapper == nil)
            {
                blendingTextureMapper = vtkGPUVolumeRayCastMapper::New();
                blendingTextureMapper->SetInputConnection(blendingReader->GetOutputPort());
                
                unsigned
                long memoryMB = [VTKView VRAMSizeForDisplayID: [[[[[self window] screen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]];
                
                blendingTextureMapper->SetMaxMemoryInBytes( memoryMB*1024*1024);
                
                NSLog( @"Graphic Board memory: %ld MiB", memoryMB);
                
                blendingTextureMapper->SetMaxMemoryFraction( 0.9);
            }
            
            blendingTextureMapper->Update();
            
            blendingVolume->SetMapper( blendingTextureMapper);
            break;
    }
    
    [self setLOD: LOD];
    
    [self setBlendingMode: renderingMode];
    
    if( firstTime == NO)
    {
        if( cropcallback)
            cropcallback->Execute( croppingBox, 0, nil);
    }
    else
    {
        if( [[controller style] isEqualToString: @"noNib"] == NO)
        {
            [self resetImage: self];
            
            if( croppingBox)
                croppingBox->PlaceWidget();
        }
    }
    
    [self display];
    
    [www end];
    [www close];
    [www autorelease];
}

-(NSImage*) image4DForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
    if( [cur intValue] != -1) [controller setMovieFrame: [cur intValue]];
    
    bestRenderingMode = YES;
    
    return [self nsimageQuicktime];
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
        
        if( [cur intValue] != 0)
        {
            if(verticalAngleForVR!=0 &&verticalAngleForVR!=-90 )
            {
                [self Vertical: -verticalAngleForVR]; // rotate to standard direction ( top of object facing right up)
            }
            if( [cur intValue] % numberOfFrames == 0 )//if need increase the vertical rotation angle
            {
                // Evaluating beyond 90 or -90 causes problems! Don't know why, seems it is vtk's limit.
                if(verticalAngleForVR==-90)
                {
                    aCamera->Roll(-rotateDirectionForVR * 360 / numberOfFrames);
                    // Evaluation(90)
                    [self Vertical: -45];
                    [self Vertical: -45];
                    verticalAngleForVR -= 360 / numberOfFrames;
                    verticalAngleForVR+=180;
                    aCamera->Azimuth(-rotateDirectionForVR * 360 / numberOfFrames);
                    
                    
                }
                else
                {
                    verticalAngleForVR -= 360 / numberOfFrames;
                    if(verticalAngleForVR<-90)//to avoid evaluating beyond 90 or -90, rotate the camera 180 vertically
                    {
                        // Evaluation(180)
                        [self Vertical: 60];
                        [self Vertical: 60];
                        [self Vertical: 60];
                        verticalAngleForVR+=180;
                        rotateDirectionForVR = -rotateDirectionForVR;
                    }
                    else if(verticalAngleForVR==-90)
                    {
                        aCamera->Azimuth( rotateDirectionForVR * 360 / numberOfFrames);
                        [self Vertical: -45];
                        [self Vertical: -45];
                        rotateDirectionForVR = -rotateDirectionForVR;
                        
                    }
                }
                
                
            }
            if(verticalAngleForVR!=-90)
            {
                aCamera->Azimuth( rotateDirectionForVR * 360 / numberOfFrames);// rotate camera horizontally when the top facing right up
                if(verticalAngleForVR!=0)
                    aCamera->Elevation(verticalAngleForVR);//rotate camera vertically
            }
            else
            {
                if( [cur intValue] % numberOfFrames != 0 )
                    aCamera->Roll(-rotateDirectionForVR * 360 / numberOfFrames);//if on the top or bottom use roll instead of azimuth
            }
        }
    }
    else
    {
        if([cur intValue] != 0) aCamera->Azimuth( 360 / numberOfFrames);
    }
    
    aCamera->SetFocalPoint( volume->GetCenter());
    aCamera->OrthogonalizeViewUp();
    aCamera->ComputeViewPlaneNormal();
    
    return [self nsimageQuicktime];
}

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
    switch( rotationOrientation)
    {
        case 0:
            [self Azimuth: [self rotation] / [max floatValue]];
            break;
            
        case 1:
            [self Vertical: [self rotation] / [max floatValue]];
            break;
    }
    
    if( [[[self window] windowController] movieFrames] > 1)
    {
        short movieIndex = [cur intValue];
        
        while( movieIndex >= [[[self window] windowController] movieFrames]) movieIndex -= [[[self window] windowController] movieFrames];
        if( movieIndex < 0) movieIndex = 0;
        
        [[[self window] windowController] setMovieFrame: movieIndex];
    }
    
    return [self nsimageQuicktime];
}

-(IBAction) switchToSeriesRadio:(id) sender
{
    [dcmExportMode selectCellWithTag:1];
}

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
    
    if ([aView isKindOfClass: [NSControl class] ])
    {
        [(NSControl*) aView setEnabled: OnOff];
        return;
    }
    // Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
}

- (IBAction) setCurrentdcmExport:(id) sender
{
    if( [[sender selectedCell] tag] == 1) [self checkView: dcmBox :YES];
    else [self checkView: dcmBox :NO];
    
    [[dcmquality cellWithTag: 1] setEnabled: YES];
}

- (NSRect) centerRect: (NSRect) smallRect
               inRect: (NSRect) bigRect
{
    NSRect centerRect;
    centerRect.size = smallRect.size;
    
    centerRect.origin.x = (bigRect.size.width - smallRect.size.width) / 2.0;
    centerRect.origin.y = (bigRect.size.height - smallRect.size.height) / 2.0;
    
    return (centerRect);
}

-(void) restoreViewSizeAfterMatrix3DExport
{
    [self setFrame: savedViewSizeFrame rescaleLine: YES];
}

-(void) setViewSizeToMatrix3DExport
{
    savedViewSizeFrame = [self frame];
    
    NSRect windowFrame;
    
    windowFrame.origin.x = 0;
    windowFrame.origin.y = 0;
    windowFrame.size.width = [[[self window] contentView] frame].size.width;
    windowFrame.size.height = [[[self window] contentView] frame].size.height - 10;
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey:@"EXPORTMATRIXFOR3D"])
    {
        case 0:
            break;
            
        case 1:		[self setFrame: [self centerRect: NSMakeRect(0,0,512,512) inRect: windowFrame] rescaleLine: YES];		[self display];		break;
        case 2:		[self setFrame: [self centerRect: NSMakeRect(0,0,768,768) inRect: windowFrame] rescaleLine: YES];		[self display];		break;
    }
}

- (NSDictionary*) exportDCMCurrentImage
{
    return [self exportDCMCurrentImageIn16bit : YES];
}

- (NSDictionary*) exportDCMCurrentImageIn16bit: (BOOL) fullDepth
{
    [self resetAutorotate: self];
    
    long width, height, spp, bpp;
    float o[ 9];
    NSString *f = nil;
    int offset = 0;
    BOOL isSigned = NO;
    
    if( exportDCM == nil)
    {
        exportDCM = [[DICOMExport alloc] init];
        [exportDCM setSeriesNumber:5500];
    }
    
    [self renderImageWithBestQuality: bestRenderingMode waitDialog: NO display: YES];
    
    unsigned char *dataPtr = [self getRawPixels:&width :&height :&spp :&bpp :YES : !fullDepth offset: &offset isSigned: &isSigned];
    
    [self endRenderImageWithBestQuality];
    
    if( dataPtr)
    {
        if( fullDepth) [exportDCM setModalityAsSource: YES];
        else [exportDCM setModalityAsSource: YES];
        
        [exportDCM setSourceFile: [firstObject srcFile]];
        [exportDCM setSeriesDescription: dcmSeriesString];
        
        [exportDCM setPixelData: dataPtr samplesPerPixel:spp bitsPerSample:bpp width: width height: height];
        
        [exportDCM setOffset: offset];
        [exportDCM setSigned: isSigned];
        
        if( [[[controller viewer2D] modality] isEqualToString:@"PT"])
        {
            float slope = firstObject.appliedFactorPET2SUV * firstObject.slope;
            [exportDCM setSlope: slope];
        }
        [exportDCM setDefaultWWWL: ww :wl];
        
        [self getOrientation: o];
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"exportOrientationIn3DExport"])
            [exportDCM setOrientation: o];
        
        if( aCamera->GetParallelProjection())
        {
            if( fullDepth)
            {
                double r = 1.0;
                
                if( volumeMapper)
                    r = volumeMapper->GetRayCastImage()->GetImageSampleDistance();
                
                [exportDCM setPixelSpacing: [self getResolution]*r :[self getResolution]*r];
            }
            else
                [exportDCM setPixelSpacing: [self getResolution] :[self getResolution]];
            
            if( clipRangeActivated)
            {
                float cos[ 9];
                
                [self getCosMatrix: cos];
                [exportDCM setOrientation: cos];
                
                float position[ 3];
                
                [self getOrigin: position];
                [exportDCM setPosition: position];
                [exportDCM setSliceThickness: [self getClippingRangeThicknessInMm]];
            }
        }
        
        f = [exportDCM writeDCMFile: nil];
        if( f == nil) NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString( @"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
        
        free( dataPtr);
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys: f, @"file", nil];
}

-(IBAction) endDCMExportSettings:(id) sender
{
    [exportDCMWindow makeFirstResponder: nil];	// To force nstextfield validation.
    [exportDCMWindow orderOut:sender];
    
    [NSApp endSheet:exportDCMWindow returnCode:[sender tag]];
    
    numberOfFrames = [dcmframesSlider intValue];
    bestRenderingMode = [[dcmquality selectedCell] tag];
    if( [[dcmrotation selectedCell] tag] == 1) rotationValue = 360;
    else rotationValue = 180;
    
    if( [[dcmorientation selectedCell] tag] == 1) rotationOrientation = 1;
    else rotationOrientation = 0;
    
    NSMutableArray *producedFiles = [NSMutableArray array];
    
    aRenderer->SetDraw( 1);
    
    self.dcmSeriesString = [dcmSeriesName stringValue];
    
    if( [sender tag])
    {
        BOOL fullDepthCapture = NO;
        
        if( [dcmExportDepth selectedTag] == 1 && [dcmExportDepth isEnabled] && (renderingMode == 1 || renderingMode == 3 || renderingMode == 2))
            fullDepthCapture = YES;
        
        [self setViewSizeToMatrix3DExport];
        
        if( fullDepthCapture)
            [self prepareFullDepthCapture];
        
        // CURRENT image only
        if( [[dcmExportMode selectedCell] tag] == 0)
        {
            if( exportDCM == nil)
            {
                exportDCM = [[DICOMExport alloc] init];
                [exportDCM setSeriesNumber:5220 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
            }
            
            [producedFiles addObject: [self exportDCMCurrentImageIn16bit: fullDepthCapture]];
        }
        // 4th dimension
        else if( [[dcmExportMode selectedCell] tag] == 2)
        {
            Wait *progress = [[Wait alloc] initWithString:NSLocalizedString(@"Creating a DICOM series", nil)];
            [progress showWindow:self];
            [[progress progress] setMaxValue: [[[self window] windowController] movieFrames]];
            
            if( exportDCM) [exportDCM release];
            exportDCM = [[DICOMExport alloc] init];
            [exportDCM setSeriesNumber:5250 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
            
            for( int i = 0; i < [[[self window] windowController] movieFrames]; i++)
            {
                [[[self window] windowController] setMovieFrame: i];
                
                [producedFiles addObject: [self exportDCMCurrentImageIn16bit: fullDepthCapture]];
                
                [progress incrementBy: 1];
                if( [progress aborted])
                    break;
                
                [self resetAutorotate: self];
            }
            
            [progress close];
            [progress autorelease];
            
            [exportDCM release];
            exportDCM = nil;
        }
        else // A 3D sequence
        {
            if( [[[self window] windowController] movieFrames] > 1)
            {
                numberOfFrames /= [[[self window] windowController] movieFrames];
                numberOfFrames *= [[[self window] windowController] movieFrames];
            }
            
            Wait *progress = [[Wait alloc] initWithString: NSLocalizedString(@"Creating a DICOM series", nil)];
            [progress showWindow:self];
            [[progress progress] setMaxValue: numberOfFrames];
            [progress setCancel:YES];
            
            if( exportDCM) [exportDCM release];
            exportDCM = [[DICOMExport alloc] init];
            [exportDCM setSeriesNumber:5500 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
            
            if( croppingBox)
            {
                if( croppingBox->GetEnabled()) croppingBox->Off();
            }
            aRenderer->RemoveActor(outlineRect);
            if( textX)
                aRenderer->RemoveActor(textX);
            
            for( int i = 0; i < numberOfFrames; i++)
            {
                if( [[[self window] windowController] movieFrames] > 1)
                {
                    short movieIndex = i;
                    
                    while( movieIndex >= [[[self window] windowController] movieFrames]) movieIndex -= [[[self window] windowController] movieFrames];
                    if( movieIndex < 0) movieIndex = 0;
                    
                    [[[self window] windowController] setMovieFrame: movieIndex];
                }
                
                [producedFiles addObject: [self exportDCMCurrentImageIn16bit: fullDepthCapture]];
                
                [progress incrementBy: 1];
                
                if( [progress aborted])
                    break;
                
                switch( rotationOrientation)
                {
                    case 0:
                        [self Azimuth: (float) rotationValue / (float) numberOfFrames];
                        break;
                        
                    case 1:
                        [self Vertical: (float) rotationValue / (float) numberOfFrames];
                        break;
                }
            }
            
            [self endRenderImageWithBestQuality];
            
            [progress close];
            [progress autorelease];
            
            [exportDCM release];
            exportDCM = nil;
        }
        
        if( fullDepthCapture)
            [self restoreFullDepthCapture];
        
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
                for( DicomImage *im in objects)
                    [im setValue: [NSNumber numberWithBool: YES] forKey: @"isKeyImage"];
            }
        }
        
        [self restoreViewSizeAfterMatrix3DExport];
    }
}

-(IBAction) endQuicktimeSettings:(id) sender
{
    [export3DWindow orderOut:sender];
    [NSApp endSheet:export3DWindow returnCode:[sender tag]];
    
    numberOfFrames = [framesSlider intValue];
    bestRenderingMode = [[quality selectedCell] tag];
    
    if( [[rotation selectedCell] tag] == 1) rotationValue = 360;
    else rotationValue = 180;
    
    if( [[orientation selectedCell] tag] == 1) rotationOrientation = 1;
    else rotationOrientation = 0;
    
    if( [sender tag])
    {
        if( [[[self window] windowController] movieFrames] > 1)
        {
            numberOfFrames /= [[[self window] windowController] movieFrames];
            numberOfFrames *= [[[self window] windowController] movieFrames];
        }
        
        [self setViewSizeToMatrix3DExport];
        
        QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :numberOfFrames];
        
        [mov createMovieQTKit:YES :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
        
        [mov release];
        
        [self restoreViewSizeAfterMatrix3DExport];
    }
}

- (void) exportDICOM
{
    if( exportDCMWindow == nil)
    {
        NSRunAlertPanel(NSLocalizedString(@"Not available", nil), NSLocalizedString(@"This function is not available for this window.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
    
    aRenderer->SetDraw( 0);
    
    [self setCurrentdcmExport: dcmExportMode];
    
    if( [[[self window] windowController] movieFrames] > 1) [[dcmExportMode cellWithTag:2] setEnabled: YES];
    else [[dcmExportMode cellWithTag:2] setEnabled: NO];
    
    if( renderingMode == 1 || renderingMode == 3 || renderingMode == 2)
        [dcmExportDepth setEnabled: YES];
    else
    {
        [dcmExportDepth setEnabled: NO];
    }
    [NSApp beginSheet: exportDCMWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

-(float) rotation {return rotationValue;}
-(float) numberOfFrames {return numberOfFrames;}

-(void) Azimuth:(float) a
{
    aCamera->Azimuth( a);
    aCamera->OrthogonalizeViewUp();
}

-(void) Vertical:(float) a
{
    aCamera->Elevation( a);
    aCamera->OrthogonalizeViewUp();
}

//-(IBAction) endQuicktimeVRSettings:(id) sender
//{
//	[export3DVRWindow orderOut:sender];
//
//	[NSApp endSheet:export3DVRWindow returnCode:[sender tag]];
//
//	numberOfFrames = [[VRFrames selectedCell] tag];
//	bestRenderingMode = [[VRquality selectedCell] tag];
//
//	rotationValue = 360;
//
//	if( [sender tag])
//	{
//		NSString			*path, *newpath;
//		QuicktimeExport		*mov;
//
//		[self setViewSizeToMatrix3DExport];
//
//		verticalAngleForVR = 0;
//		rotateDirectionForVR = 1;
//
//		if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
//			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames*numberOfFrames];
//		else
//			mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrameVR: maxFrame:) :numberOfFrames];
//
//		path = [mov createMovieQTKit: NO  :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
//		if( path)
//		{
//			if( numberOfFrames == 10 || numberOfFrames == 20 || numberOfFrames == 40)
//				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames*numberOfFrames];
//			else
//				newpath = [QuicktimeExport generateQTVR: path frames: numberOfFrames];
//
//			[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
//			[[NSFileManager defaultManager] movePath: newpath  toPath: path handler: nil];
//
//			[[NSWorkspace sharedWorkspace] openFile: path withApplication: nil andDeactivate: YES];
//			[NSThread sleepForTimeInterval: 1];
//		}
//
//		[mov release];
//
//		[self restoreViewSizeAfterMatrix3DExport];
//	}
//}

- (void) setShadingValues:(float) ambient :(float) diffuse :(float) specular :(float) specularpower
{
    if( volumeProperty == nil)
        return;
    
    volumeProperty->SetAmbient(ambient);
    volumeProperty->SetDiffuse(diffuse);
    volumeProperty->SetSpecular(specular);
    volumeProperty->SetSpecularPower(specularpower);
}

- (void) getShadingValues:(float*) ambient :(float*) diffuse :(float*) specular :(float*) specularpower
{
    if( volumeProperty == nil)
        return;
    
    *ambient = volumeProperty->GetAmbient();
    *diffuse = volumeProperty->GetDiffuse();
    *specular = volumeProperty->GetSpecular();
    *specularpower = volumeProperty->GetSpecularPower();
}

-(long) shading
{
    if( volumeProperty == nil)
        return 0;
    
    return volumeProperty->GetShade();
}

- (void) setProjectionMode: (int) mode
{
    projectionMode = mode;
    
    if( aCamera == nil) return;
    
    int wasMode = mode;
    
    switch( mode)
    {
        case 0:
            aCamera->SetParallelProjection( false);
            aCamera->SetViewAngle( 30);
            break;
            
        case 2:
            aCamera->SetParallelProjection( false);
            aCamera->SetViewAngle( 60);
            break;
            
        case 1:
            aCamera->SetParallelProjection( true);
            aCamera->SetViewAngle( 30);
            
            break;
    }
    
    if( clipRangeActivated == NO && (mode == 0 || mode == 1) && (wasMode == 0 || wasMode == 1))
    {
        
    }
    else
    {
        [self resetImage: self];
    }
    
    if( aCamera->GetParallelProjection())
        [[[controller toolsMatrix] cellWithTag: tMesure] setEnabled: YES];
    else
    {
        [[[controller toolsMatrix] cellWithTag: tMesure] setEnabled: NO];
        
        if( currentTool == tMesure)
        {
            [self setCurrentTool: t3DRotate];
            [[controller toolsMatrix] selectCellWithTag: t3DRotate];
        }
    }
    
    [self setNeedsDisplay:YES];
}

-(void)activateShading:(BOOL)on;
{
    if(on)
        volumeProperty->ShadeOn();
    else
        volumeProperty->ShadeOff();
}

-(IBAction) switchShading:(id) sender
{
    if( [sender state] == NSOnState)
    {
        volumeProperty->ShadeOn();
        
        WaitRendering	*www = [[WaitRendering alloc] init: NSLocalizedString( @"Preparing 3D data...", nil)];
        [www start];
        
        if( textureMapper)
        {
            //			if( volumeProperty->GetShade()) textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
            //			else textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
            reader->GetOutput()->Modified();
        }
        
        [self display];
        [www end];
        [www close];
        [www autorelease];
    }
    else
    {
        volumeProperty->ShadeOff();
        
        WaitRendering	*www = [[WaitRendering alloc] init: NSLocalizedString( @"Preparing 3D data...", nil)];
        [www start];
        
        if( textureMapper)
        {
            //			if( volumeProperty->GetShade()) textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURESHADING"]);
            //			else textureMapper->SetMaximumNoOfSlices( [[NSUserDefaults standardUserDefaults] integerForKey: @"MAX3DTEXTURE"]);
            reader->GetOutput()->Modified();
        }
        
        [self display];
        [www end];
        [www close];
        [www autorelease];
    }
}

-(IBAction) exportQuicktime3DVR:(id) sender
{
    if( export3DVRWindow == nil)
    {
        NSRunAlertPanel(NSLocalizedString(@"Not available", nil), NSLocalizedString(@"This function is not available for this window.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    
    [[VRquality cellWithTag: 1] setEnabled: YES];
    
    [NSApp beginSheet: export3DVRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

- (IBAction) exportQuicktime:(id) sender
{
    
    if( export3DWindow == nil)
    {
        NSRunAlertPanel(NSLocalizedString(@"Not available", nil), NSLocalizedString(@"This function is not available for this window.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    
    [[quality cellWithTag: 1] setEnabled: YES];
    
    //	if( [[[self window] windowController] movieFrames] > 1)
    if( [controller movieFrames] > 1)
    {
        if( NSRunInformationalAlertPanel( NSLocalizedString(@"Quicktime Export", nil), NSLocalizedString(@"Should I export the temporal series or the 3D scene?", nil), NSLocalizedString(@"3D Scene", nil), NSLocalizedString(@"Temporal Series", nil), nil) == NSAlertDefaultReturn)
        {
            [NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
        }
        else
        {
            QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(image4DForFrame: maxFrame:) :[controller movieFrames]];
            [mov createMovieQTKit: YES  :NO :[[[controller fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
            [mov release];
        }
    }
    else [NSApp beginSheet: export3DWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:(void*) nil];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
    return YES;
}

- (void) CloseViewerNotification: (NSNotification*) note
{
    if([note object] == blendingController) // our blended serie is closing itself....
    {
        [self setBlendingPixSource:nil];
        [self setNeedsDisplay:YES];
    }
}

- (void) CLUTChanged: (NSNotification*) note
{
    unsigned char   r[256], g[256], b[256];
    
    [[note object] ConvertCLUT: r :g :b];
    
    //aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
    
    [self setCLUT :r : g : b];
}

- (void) OpacityChanged: (NSNotification*) note
{
    [self setOpacity: [[note object] getPoints]];
}

- (ToolMode) getTool: (NSEvent*) event
{
    ToolMode tool;
    if(([event type] == NSRightMouseDown || [event type] == NSRightMouseDragged || [event type] == NSRightMouseUp) && !_contextualMenuActive) tool = tZoom;
    else if( [event type] == NSOtherMouseDown || [event type] == NSOtherMouseDragged || [event type] == NSOtherMouseUp) tool = tTranslate;
    else tool = currentTool;
    
    if (([event modifierFlags] & NSControlKeyMask))  tool = tRotate;
    if (([event modifierFlags] & NSShiftKeyMask))  tool = tZoom;
    if (([event modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
    if (([event modifierFlags] & NSAlternateKeyMask))  tool = tWL;
    if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSAlternateKeyMask)) tool = tRotate;
    if (([event modifierFlags] & NSCommandKeyMask) && ([event modifierFlags] & NSControlKeyMask)) tool = tCamera3D;
    
    return tool;
}

- (void) resetAutorotate:(id) sender
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"autorotate3D"] && [[[self window] windowController] isKindOfClass:[VRController class]])
    {
        [startAutoRotate invalidate];
        [startAutoRotate release];
        
        startAutoRotate = [[NSTimer scheduledTimerWithTimeInterval:60*3 target:self selector:@selector(startAutoRotate:) userInfo:nil repeats:NO] retain];
    }
}

- (void) startAutoRotate:(id) sender
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"autorotate3D"])
        isRotating = YES;
}

- (void) autoRotate:(id) sender
{
    if( isRotating)
    {
        [self Azimuth: 4.];
        [self mouseMoved: [[NSApplication sharedApplication] currentEvent]];
        [self setNeedsDisplay: YES];
    }
    
    if( flyto)
    {
        [self processFlyTo];
    }
}

- (void) flagsChanged:(NSEvent *) event
{
    [self setCursorForView: [self getTool: event]];
    if( cursorSet) [cursor set];
    [super flagsChanged: event];
}

-(id)initWithFrame:(NSRect)frame
{
    if ( self = [super initWithFrame:frame])
    {
        NSTrackingArea *cursorTracking = [[[NSTrackingArea alloc] initWithRect: [self visibleRect] options: (NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) owner: self userInfo: nil] autorelease];
        
        [self addTrackingArea: cursorTracking];
        
        isRotating = NO;
        
        splash = nil;	//[[WaitRendering alloc] init:NSLocalizedString(@"Rendering...", nil)];
        currentTool = t3DRotate;
        [self setCursorForView: currentTool];
        
        deleteRegion = [[NSLock alloc] init];
        
        valueFactor = 1.0;
        OFFSET16 = -[controller minimumValue];
        blendingValueFactor = 1.0;
        blendingOFFSET16 = -[controller blendingMinimumValue];
        
        renderingMode = 0;	// VR, MIP = 1
        blendingController = nil;
        blendingFactor = 128.;
        blendingVolume = nil;
        exportDCM = nil;
        currentOpacityArray = nil;
        textWLWW = nil;
        cursor = nil;
        ROIPoints = [[NSMutableArray array] retain];
        
        dataFRGB = nil;
        
        superSampling = [[NSUserDefaults standardUserDefaults] floatForKey: @"superSampling"];
        
        isViewportResizable = YES;
        
        data8 = nil;
        
        opacityTransferFunction = nil;
        volumeProperty = nil;
        compositeFunction = nil;
        red = nil;
        green = nil;
        blue = nil;
        pixList = nil;
        
        firstTime = YES;
        ROIUPDATE = NO;
        
        aCamera = nil;
        
        needToFlip = NO;
        blendingNeedToFlip = NO;
        
        // MAPPERS
        textureMapper = nil;
        volumeMapper = nil;
        //		shearWarpMapper = nil;
        
        blendingTextureMapper = nil;
        blendingVolumeMapper = nil;
        //		blendingShearWarpMapper = nil;
        
        noWaitDialog = NO;
        
        NSNotificationCenter *nc;
        nc = [NSNotificationCenter defaultCenter];
        [nc addObserver: self
               selector: @selector(CloseViewerNotification:)
                   name: OsirixCloseViewerNotification
                 object: nil];
        
        [nc addObserver: self
               selector: @selector(OpacityChanged:)
                   name: OsirixOpacityChangedNotification
                 object: nil];
        
        [nc addObserver: self
               selector: @selector(CLUTChanged:)
                   name: OsirixCLUTChangedNotification
                 object: nil];
        
        [nc addObserver: self
               selector: @selector(ViewFrameDidChangeNotification:)
                   name: NSViewFrameDidChangeNotification
                 object: nil];
        
        [nc addObserver: self
               selector: @selector(checkForMovedVolume:)
                   name: OsirixVRCameraDidChangeNotification
                 object: nil];
        
        point3DActorArray = [[NSMutableArray alloc] initWithCapacity:0];
        point3DPositionsArray = [[NSMutableArray alloc] initWithCapacity:0];
        point3DRadiusArray = [[NSMutableArray alloc] initWithCapacity:0];
        point3DColorsArray = [[NSMutableArray alloc] initWithCapacity:0];
        display3DPoints = YES;
        
        [self load3DPointsDefaultProperties];
        
        autoRotate = [[NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(autoRotate:) userInfo:nil repeats:YES] retain];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey:@"autorotate3D"] && [[[self window] windowController] isKindOfClass:[VRController class]])
            startAutoRotate = [[NSTimer scheduledTimerWithTimeInterval:60*3 target:self selector:@selector(startAutoRotate:) userInfo:nil repeats:NO] retain];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name: NSWindowWillCloseNotification object: [self window]];
        
        advancedCLUT = NO;
        
        
        
        //        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"InvertViewsColors"];
        //        if( [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue])
        //        {
        //            NSView *v = (NSView*) _cocoaRenderWindow->GetWindowId();
        //
        //            [v setWantsLayer: YES];
        //            CIFilter *CIColorInvert = [CIFilter filterWithName:@"CIColorInvert"];
        //            [CIColorInvert setDefaults];
        //            v.contentFilters = [NSArray arrayWithObject:CIColorInvert];
        //        }
        
        
        //        [[IMService notificationCenter] addObserver:self selector:@selector(_iChatStateChanged:) name:IMAVManagerStateChangedNotification object:nil];
    }
    
    return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
    if( [self window] && [self window] == [notification object])
    {
        if( [[[self window] windowController] isKindOfClass:[VRController class]])
            [[self window] setAcceptsMouseMovedEvents: NO];
        
        [startAutoRotate invalidate];
        [startAutoRotate release];
        startAutoRotate = nil;
        
        [autoRotate invalidate];
        [autoRotate release];
        autoRotate = nil;
        
        [self deleteMouseDownTimer];
        [self deleteRightMouseDownTimer];
        
        [[NSNotificationCenter defaultCenter] removeObserver: self];
    }
}

- (IBAction) resetImage:(id) sender
{
    aRenderer->ResetCamera();
    [self saView:self];
    
    if( clipRangeActivated)
        [self goToCenter];
    
    [self saView:self];
    
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
    
    [self setCurrentTool: t3DRotate];
    [[controller toolsMatrix] selectCellWithTag: t3DRotate];
    
    [self setNeedsDisplay:YES];
}

-(void) set3DStateDictionary:(NSDictionary*) dict
{
    NSArray *tempArray;
    
    if( dict)
    {
        tempArray = [dict objectForKey:@"ShadingValues"];
        if( tempArray)
        {
            [self setShadingValues:[[tempArray objectAtIndex:0] floatValue] :[[tempArray objectAtIndex:1] floatValue] :[[tempArray objectAtIndex:2] floatValue] :[[tempArray objectAtIndex:3] floatValue]];
        }
        
        if( renderingMode == 0 && volumeProperty)
            volumeProperty->SetShade( [[dict objectForKey:@"ShadingFlag"] longValue]);
        
        float savedSupersampling = [[dict objectForKey:@"superSampling"] floatValue];
        float ratio = 1;
        
        if( savedSupersampling)
            ratio = superSampling / savedSupersampling;
        
        if( [[dict objectForKey:@"SUVConverted"] boolValue] == [firstObject SUVConverted])
            [self setWLWW: [[dict objectForKey:@"WL"] floatValue] :[[dict objectForKey:@"WW"] floatValue]];
        
        tempArray = [dict objectForKey:@"CameraPosition"];
        if( aCamera)
            aCamera->SetPosition( [[tempArray objectAtIndex:0] floatValue]*ratio, [[tempArray objectAtIndex:1] floatValue]*ratio, [[tempArray objectAtIndex:2] floatValue]*ratio);
        
        tempArray = [dict objectForKey:@"CameraViewUp"];
        if( aCamera)
            aCamera->SetViewUp( [[tempArray objectAtIndex:0] floatValue]*ratio, [[tempArray objectAtIndex:1] floatValue]*ratio, [[tempArray objectAtIndex:2] floatValue]*ratio);
        
        tempArray = [dict objectForKey:@"CameraFocalPoint"];
        if( aCamera)
            aCamera->SetFocalPoint( [[tempArray objectAtIndex:0] floatValue]*ratio, [[tempArray objectAtIndex:1] floatValue]*ratio, [[tempArray objectAtIndex:2] floatValue]*ratio);
        
        tempArray = [dict objectForKey:@"CameraClipping"];
        if( aCamera)
            aCamera->SetClippingRange( [[tempArray objectAtIndex:0] floatValue], [[tempArray objectAtIndex:1] floatValue]);
        
        if( [dict objectForKey:@"Projection"])
            [self setProjectionMode: [[dict objectForKey:@"Projection"] intValue]];
        
        dontResetImage = YES;
        if( [dict valueForKey: @"clipRangeActivated"])
        {
            self.clipRangeActivated = [[dict valueForKey: @"clipRangeActivated"] boolValue];
            self.clippingRangeThickness = [[dict valueForKey: @"clippingRangeThickness"] floatValue];
        }
        else self.clipRangeActivated = NO;
        dontResetImage = NO;
    }
    else
    {
        if( renderingMode == 0 && volumeProperty)				// volume rendering
            volumeProperty->SetShade( [[NSUserDefaults standardUserDefaults] boolForKey: @"defaultShading"]);
    }
    
    if( volume && volume->GetMapper() == nil)
        self.engine = [[NSUserDefaults standardUserDefaults] integerForKey: @"MAPPERMODEVR"];
}

-(NSMutableDictionary*) get3DStateDictionary
{
    double	temp[ 3];
    float	ambient, diffuse, specular, specularpower;
    
    if( aCamera == nil) return nil;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:[NSNumber numberWithFloat:wl] forKey:@"WL"];
    [dict setObject:[NSNumber numberWithFloat:ww] forKey:@"WW"];
    [dict setObject:[NSNumber numberWithBool:[firstObject SUVConverted]] forKey:@"SUVConverted"];
    
    aCamera->GetPosition( temp);
    [dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], nil] forKey:@"CameraPosition"];
    aCamera->GetViewUp( temp);
    [dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], nil] forKey:@"CameraViewUp"];
    aCamera->GetFocalPoint( temp);
    [dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]],  [NSNumber numberWithFloat:temp[2]], nil] forKey:@"CameraFocalPoint"];
    aCamera->GetClippingRange( temp);
    [dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:temp[0]],  [NSNumber numberWithFloat:temp[1]], nil] forKey:@"CameraClipping"];
    
    [self getShadingValues:&ambient :&diffuse :&specular :&specularpower];
    [dict setObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:ambient],  [NSNumber numberWithFloat:diffuse], [NSNumber numberWithFloat:specular],  [NSNumber numberWithFloat:specularpower], nil] forKey:@"ShadingValues"];
    [dict setObject:[NSNumber numberWithLong:volumeProperty->GetShade()] forKey:@"ShadingFlag"];
    [dict setObject:[NSNumber numberWithLong:projectionMode] forKey:@"Projection"];
    
    [dict setObject:[NSNumber numberWithBool:self.clipRangeActivated] forKey:@"clipRangeActivated"];
    [dict setObject:[NSNumber numberWithFloat: [self getClippingRangeThickness]] forKey:@"clippingRangeThickness"];
    
    [dict setObject:[NSNumber numberWithFloat: superSampling] forKey:@"superSampling"];
    
    return dict;
}

- (void) render
{
    if( volumeMapper)
    {
        aRenderer->SetDraw( 0);
        
        dontRenderVolumeRenderingOsiriX = 0;
        volumeMapper->SetIntermixIntersectingGeometry( 0);
        
        _cocoaRenderWindow->UpdateContext();
        _cocoaRenderWindow->MakeCurrent();
        volumeMapper->Render( aRenderer, volume);
        
        dontRenderVolumeRenderingOsiriX = 1;
    }
}

- (void) renderBlendedVolume
{
    if( blendingVolumeMapper)
    {
        aRenderer->SetDraw( 0);
        
        dontRenderVolumeRenderingOsiriX = 0;
        blendingVolumeMapper->SetIntermixIntersectingGeometry( 0);
        
        _cocoaRenderWindow->UpdateContext();
        _cocoaRenderWindow->MakeCurrent();
        blendingVolumeMapper->Render( aRenderer, blendingVolume);
        
        dontRenderVolumeRenderingOsiriX = 1;
    }
}

- (void) displayVTKError
{
    if( alertDisplayed == NO)
    {
        alertDisplayed = YES;
        
        NSLog( @"C++ Exception during drawRect... not enough memory?");
        
        if( NSRunAlertPanel( NSLocalizedString(@"32-bit",nil), NSLocalizedString( @"Cannot use the 3D engine.\r\rUpgrade to OsiriX 64-bit or OsiriX MD to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
            [[AppController sharedAppController] osirix64bit: self];
        
        [[self window] performClose: self];
    }
}

- (void) drawRect:(NSRect)aRect
{
    if( drawLock == nil) drawLock = [[NSRecursiveLock alloc] init];
    
    //	BOOL iChatRunning = [[IChatTheatreDelegate sharedDelegate] isIChatTheatreRunning];
    
    //	if(iChatRunning) [drawLock lock];
    
    minimumStep = 0;
    
    @try
    {
        WaitRendering	*www = 0;
        
        if( firstTime)
        {
            firstTime = NO;
            www = [[WaitRendering alloc] init:NSLocalizedString(@"Preparing 3D data...", nil)];
            [www start];
        }
        
        try
        {
            [self computeOrientationText];
            
            [super drawRect:aRect];
        }
        
        catch (...)
        {
            if( alertDisplayed == NO)
                [self performSelector: @selector( displayVTKError) withObject:nil afterDelay:0.1];
        }
        
        if( www)
        {
            [www end];
            [www close];
            [www autorelease];
            
            if( isRGB == NO)
            {
                if( [[controller viewer2D] maxMovieIndex] > 1)
                {
                    *(data+0+[firstObject pwidth]) = firstPixel;
                    *(data+1+[firstObject pwidth]) = secondPixel;
                    
                    //					vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
                    [BrowserController multiThreadedImageConvert: @"FTo16U" :&srcf :&dst8 :-OFFSET16 :1./valueFactor];
                }
                
                //				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAutoCropScissors"] == NO)
                //					[self autoCroppingBox];
            }
        }
        
        _hasChanged = YES;
        
    }
    @catch (NSException * e)
    {
        NSLog( @"Exception during drawRect: %@", e);
    }
    
    //	if(iChatRunning) [drawLock unlock];
}

-(void)dealloc
{
    long i;
    
    NSLog(@"Dealloc VRView");
    
    [NSObject cancelPreviousPerformRequestsWithTarget: [self window]];
    
    //	[[IMService notificationCenter] removeObserver: self];
    
    [dcmSeriesString release];
    [deleteRegion lock];
    [deleteRegion unlock];
    [deleteRegion release];
    [ROIPoints release];
    [exportDCM release];
    [splash close];
    [splash autorelease];
    [currentOpacityArray release];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self setBlendingPixSource: nil];
    
    //	cbStart->Delete();
    if( opacityTransferFunction)
        opacityTransferFunction->Delete();
    
    if( volumeProperty)
        volumeProperty->Delete();
    
    if( compositeFunction)
        compositeFunction->Delete();
    
    if( orientationWidget)
        orientationWidget->Delete();
    
    if( volumeMapper) volumeMapper->Delete();
    if( textureMapper) textureMapper->Delete();
    //	if( shearWarpMapper) shearWarpMapper->Delete();
    
    if( red)
        red->Delete();
    if( green)
        green->Delete();
    if( blue)
        blue->Delete();
    if( volume)
        volume->Delete();
    if( outlineData)
        outlineData->Delete();
    if( mapOutline)
        mapOutline->Delete();
    if( outlineRect)
        outlineRect->Delete();
    
    if( croppingBox)
    {
        croppingBox->InvokeEvent(vtkCommand::EndEvent,NULL);
        croppingBox->RemoveObserver(cropcallback);
        croppingBox->Delete();
    }
    
    if( cropcallback)
        cropcallback->Delete();
    
    if( textWLWW)
        textWLWW->Delete();
    if( textX)
        textX->Delete();
    for( i = 0; i < 5; i++) if( oText[ i]) oText[ i]->Delete();
    if( colorTransferFunction) colorTransferFunction->Delete();
    if( reader) reader->Delete();
    if( aCamera) aCamera->Delete();
    //	aRenderer->Delete();
    
    if( Oval2DData) Oval2DData->Delete();
    if( Oval2D) Oval2D->Delete();
    if( Oval2DActor) Oval2DActor->Delete();
    if( Oval2DText) Oval2DText->Delete();
    [Oval2DPix release];
    
    if( ROI3DData) ROI3DData->Delete();
    if( ROI3D) ROI3D->Delete();
    if( ROI3DActor) ROI3DActor->Delete();
    
    if( Line2DData) Line2DData->Delete();
    if( Line2D) Line2D->Delete();
    if( Line2DActor) Line2DActor->Delete();
    if( Line2DText) Line2DText->Delete();
    
    [pixList release];
    pixList = nil;
    
    if( dataFRGB) free( dataFRGB);
    
    if( data8) free( data8);
    
    [point3DActorArray release];
    [point3DPositionsArray release];
    [point3DRadiusArray release];
    [point3DColorsArray release];
    
    [cursor release];
    
    [_mouseDownTimer invalidate];
    [_mouseDownTimer release];
    
    [_rightMouseDownTimer invalidate];
    [_rightMouseDownTimer release];
    
    [destinationImage release];
    
    [appliedCurves release];
    
    // 3D Connexion SpaceNavigator: Make sure the framework is installed
#if USE3DCONNEXION
    if(InstallConnexionHandlers != NULL)
    {
        // 3D Connexion SpaceNavigator: Unregister our client and clean up all handlers
        if(snConnexionClientID) UnregisterConnexionClient(snConnexionClientID);
        CleanupConnexionHandlers();
    }
#endif
    
    [super dealloc];
}

- (void) timerUpdate:(id) sender
{
    if( ROIUPDATE == YES)
        [self display];
    
    ROIUPDATE = NO;
}

- (float) blendingImageSampleDistance
{
    if( blendingVolumeMapper)
        return blendingVolumeMapper->GetRayCastImage()->GetImageSampleDistance();
    else
        return 0;
}

- (float) imageSampleDistance
{
    if( volumeMapper)
        return volumeMapper->GetRayCastImage()->GetImageSampleDistance();
    else
        return 0;
}

- (void) getOrigin: (float *) origin
{
    return [self getOrigin: origin windowCentered: NO];
}

- (void) getOrigin: (float *) origin windowCentered:(BOOL) wc
{
    return [self getOrigin: origin windowCentered: wc sliceMiddle: YES];
}

- (void) getOrigin: (float *) origin windowCentered:(BOOL) wc sliceMiddle:(BOOL) sliceMiddle
{
    return [self getOrigin: origin windowCentered: wc sliceMiddle: sliceMiddle blendedView: NO];
}

- (void) getOrigin: (float *) origin windowCentered:(BOOL) wc sliceMiddle:(BOOL) sliceMiddle blendedView:(BOOL) blendedView
{
    if( volumeMapper == nil)
    {
        NSLog( @"****** vrView getOrigin volumeMapper == nil");
        return;
    }
    
    @try
    {
        double cameraPosition[3];
        aCamera->GetPosition(cameraPosition);
        
        cameraPosition[ 0] /= factor;
        cameraPosition[ 1] /= factor;
        cameraPosition[ 2] /= factor;
        
        vtkFixedPointRayCastImage *rayCastImage = nil;
        
        if( blendedView) rayCastImage = blendingVolumeMapper->GetRayCastImage();
        else rayCastImage = volumeMapper->GetRayCastImage();
        
        int size[2];
        rayCastImage->GetImageInUseSize( size);
        
        // Position of upper left part of the image
        
        double *viewport = aRenderer->GetViewport();
        int *renWinSize = aRenderer->GetRenderWindow()->GetSize();
        
        // Origin
        int x1, x2, y1, y2;
        
        double sampleDistance = 0;
        
        if( blendedView) sampleDistance = blendingVolumeMapper->GetRayCastImage()->GetImageSampleDistance();
        else sampleDistance = volumeMapper->GetRayCastImage()->GetImageSampleDistance();
        
        // turn ImageOrigin into (x1,y1) in window (not viewport!) coordinates.
        int imageOrigin[2];
        int imageInUseSize[2];
        
        if( blendedView)
        {
            blendingVolumeMapper->GetRayCastImage()->GetImageOrigin( imageOrigin);
            blendingVolumeMapper->GetRayCastImage()->GetImageInUseSize( imageInUseSize);
        }
        else
        {
            volumeMapper->GetRayCastImage()->GetImageOrigin( imageOrigin);
            volumeMapper->GetRayCastImage()->GetImageInUseSize( imageInUseSize);
        }
        
        x1 = static_cast<int> ( viewport[0] * static_cast<double>(renWinSize[0]) + static_cast<double>(imageOrigin[0]) * sampleDistance);
        y1 = static_cast<int> ( viewport[1] * static_cast<double>(renWinSize[1]) + static_cast<double>(imageOrigin[1]) * sampleDistance);
        
        int zbufferSize[2];
        
        // compute z buffer size
        zbufferSize[0] = static_cast<int>( static_cast<double>(imageInUseSize[0]) * sampleDistance);
        zbufferSize[1] = static_cast<int>( static_cast<double>(imageInUseSize[1]) * sampleDistance);
        
        // Use the size to compute (x2,y2) in window coordinates
        x2 = x1 + zbufferSize[0] - 1;
        y2 = y1 + zbufferSize[1] - 1;
        
        // cameraPosition is in the center of the screen
        double x = ((double) x1 - (double) renWinSize[ 0]/2.);
        double y = ((double) y1 - (double) renWinSize[ 1]/2.);
        
        if( wc)
        {
            NSPoint wC = [self windowCenter];
            x -= wC.x;
            y -= wC.y;
        }
        
        float cos[ 9];
        
        [self getCosMatrix: cos];
        
        double r = [self getResolution];
        
        // Upper Left corner
        origin[0] = cameraPosition[ 0] + y*cos[3]*r + x*cos[0]*r;
        origin[1] = cameraPosition[ 1] + y*cos[4]*r + x*cos[1]*r;
        origin[2] = cameraPosition[ 2] + y*cos[5]*r + x*cos[2]*r;
        
        // Take into account the sliceThickness -> Origin is in the middle of the slice thickness
        if( sliceMiddle)
        {
            double thickness = clippingRangeThickness / factor;
            
            thickness /= 2.;
            
            origin[0] = origin[ 0] + thickness*cos[6];
            origin[1] = origin[ 1] + thickness*cos[7];
            origin[2] = origin[ 2] + thickness*cos[8];
        }
    }
    @catch( NSException *e)
    {
        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
    }
}

- (BOOL) getCosMatrix: (float *) cos
{
    double viewUp[ 3];
    double length;
    
    if( aCamera == nil)
    {
        for( int i = 0; i < 9; i++)
            cos[ i] = 0;
        return NO;
    }
    
    aCamera->GetViewUp( viewUp);
    
    cos[3] = viewUp[ 0] * -1.0;
    cos[4] = viewUp[ 1] * -1.0;
    cos[5] = viewUp[ 2] * -1.0;
    
    length = sqrt(cos[3]*cos[3] + cos[4]*cos[4] + cos[5]*cos[5]);
    if( length != 0)
    {
        cos[3] = cos[ 3] / length;
        cos[4] = cos[ 4] / length;
        cos[5] = cos[ 5] / length;
    }
    else return NO;
    
    double cos6[ 3];
    
    aCamera->GetDirectionOfProjection( cos6);
    
    cos[ 6] = cos6[ 0];
    cos[ 7] = cos6[ 1];
    cos[ 8] = cos6[ 2];
    
    length = sqrt(cos[6]*cos[6] + cos[7]*cos[7] + cos[8]*cos[8]);
    if( length != 0)
    {
        cos[6] = cos[ 6] / length;
        cos[7] = cos[ 7] / length;
        cos[8] = cos[ 8] / length;
    }
    
    cos[0] = cos[7]*cos[5] - cos[8]*cos[4];
    cos[1] = cos[8]*cos[3] - cos[6]*cos[5];
    cos[2] = cos[6]*cos[4] - cos[7]*cos[3];
    
    cos[0] *= -1.;
    cos[1] *= -1.;
    cos[2] *= -1.;
    
    length = sqrt(cos[0]*cos[0] + cos[1]*cos[1] + cos[2]*cos[2]);
    if( length != 0)
    {
        cos[0] = cos[ 0] / length;
        cos[1] = cos[ 1] / length;
        cos[2] = cos[ 2] / length;
    }
    else return NO;
    
    return YES;
}

- (double) getResolution
{
    if( aCamera && aCamera->GetParallelProjection() && factor > 0)
    {
        double point1[ 4] = { 0, 0, 0, 0}, point2[ 4] = { 1, 0, 0, 0};
        
        aRenderer->SetDisplayPoint( point1);
        aRenderer->DisplayToWorld();
        aRenderer->GetWorldPoint( point1);
        
        aRenderer->SetDisplayPoint( point2);
        aRenderer->DisplayToWorld();
        aRenderer->GetWorldPoint( point2);
        
        double xd = point2[ 0]- point1[ 0];
        double yd = point2[ 1]- point1[ 1];
        double zd = point2[ 2]- point1[ 2];
        double length = sqrt(xd*xd + yd*yd + zd*zd);
        
        if( isnan( length) || length < 0.00001 || length > 1000)
        {
            NSLog( @"****** vrView getResolution: isnan(%f) == %d",length, isnan(length));
        }
        else
        {
            //NSLog( @"****** vrView getResolution: isnan(%f) == %d",length, isnan(length));
        }
        
        return (length/factor);
    }
    else
        return 0;
}

- (void) computeLength
{
    vtkPoints *pts = Line2DData->GetPoints();
    
    if( pts->GetNumberOfPoints() == 2)
    {
        double point1[ 4], point2[ 4];
        
        pts->GetPoint( 0, point1);
        pts->GetPoint( 1, point2);
        
        aRenderer->SetDisplayPoint( point1);
        aRenderer->DisplayToWorld();
        aRenderer->GetWorldPoint( point1);
        
        aRenderer->SetDisplayPoint( point2);
        aRenderer->DisplayToWorld();
        aRenderer->GetWorldPoint( point2);
        
        double xd = point2[ 0]- point1[ 0];
        double yd = point2[ 1]- point1[ 1];
        double zd = point2[ 2]- point1[ 2];
        double length = sqrt(xd*xd + yd*yd + zd*zd);
        
        
        pts->GetPoint( 0, point1);
        pts->GetPoint( 1, point2);
        
        Line2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
        if( point1[ 0] > point2[ 0]) Line2DText->GetPositionCoordinate()->SetValue( point1[0] + 3, point1[ 1]);
        else Line2DText->GetPositionCoordinate()->SetValue( point2[0], point2[ 1]);
        
        NSString *localizedText = nil;
        
        if (length/(10.*factor) < .1)
            localizedText = [NSString stringWithFormat: NSLocalizedString( @"Length: %2.2f mm ", @"ONLY ASCII CHARACTERS ! NO ACCENTS OR HIEROGLYPHS"), (length/(10.*factor)) * 10.0];
        else
            localizedText = [NSString stringWithFormat: NSLocalizedString( @"Length: %2.2f cm ", @"ONLY ASCII CHARACTERS ! NO ACCENTS OR HIEROGLYPHS"), length/(10.*factor)];
        
        Line2DText->SetInput( [localizedText UTF8String]);
        aRenderer->AddActor(Line2DText);
        
        measureLength = length/(10.*factor);
    }
    else
    {
        aRenderer->RemoveActor(Line2DText);
        measureLength = 0;
    }
    
    if( Oval2DRadius > 0.001)
    {
        if( Oval2DPix == nil)
        {
            if( renderingMode == 1 || renderingMode == 3 || renderingMode == 2) // MIP modes - full depth
            {
                dontRenderVolumeRenderingOsiriX = 1;
                
                aRenderer->SetDraw( 0);
                
                [self prepareFullDepthCapture];
                
                [self renderImageWithBestQuality: NO waitDialog: NO display: YES];
                
                long width, height;
                BOOL rgb;
                
                float *pixels = [self imageInFullDepthWidth: &width height: &height isRGB: &rgb];
                
                Oval2DPixZBufferOrigin[ 0] = Oval2DPixZBufferOrigin[ 1] = 0;
                volumeMapper->GetRayCastImage()->GetImageOrigin( Oval2DPixZBufferOrigin);
                Oval2DSampleDistance = volumeMapper->GetRayCastImage()->GetImageSampleDistance();
                Oval2DPixZBufferOrigin[ 0] *= Oval2DSampleDistance;
                Oval2DPixZBufferOrigin[ 1] *= Oval2DSampleDistance;
                
                if( rgb == NO)
                {
                    [Oval2DPix release];
                    Oval2DPix = [[DCMPix alloc] initWithData: pixels :32 :width :height :1 :1 :0 :0 :0 :NO];
                    
                    //                    #ifdef NDEBUG
                    //                    #else
                    //                    [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/VR.tiff" error: nil];
                    //                    [[[Oval2DPix image] TIFFRepresentation] writeToFile: @"/tmp/VR.tiff" atomically: YES];
                    //                    #endif
                }
                
                
                [self endRenderImageWithBestQuality];
                
                [self restoreFullDepthCapture];
                
                aRenderer->SetDraw( 1);
                
                dontRenderVolumeRenderingOsiriX = 0;
                
                free( pixels);
            }
        }
        
        if( Oval2DPix)
        {
            ROI *circle = [[ROI alloc] initWithType: tOval :1 :1 :NSMakePoint(0,0)];
            
            NSPoint center = Oval2DCenter;
            float radius = Oval2DRadius;
            
            center.x -= Oval2DPixZBufferOrigin[0];   center.y -= Oval2DPixZBufferOrigin[1];
            center.x /= Oval2DSampleDistance; center.y /= Oval2DSampleDistance;
            
            radius /= Oval2DSampleDistance;
            
            [circle setROIRect: NSMakeRect( center.x ,
                                           Oval2DPix.pheight - center.y,
                                           radius,
                                           radius)];
            
            float rmean, rtotal, rdev, rmin, rmax;
            
            [Oval2DPix computeROI: circle :&rmean :&rtotal :&rdev :&rmin :&rmax];
            
            //#ifdef NDEBUG
            //#else
            //             [Oval2DPix fillROI: circle : 1000 :-2000 :2000 :NO];
            //            [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/VR.tiff" error: nil];
            //            [[[Oval2DPix image] TIFFRepresentation] writeToFile: @"/tmp/VR.tiff" atomically: YES];
            //#endif
            
            Oval2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
            
#define OVAL2DTEXTHEIGHT 35
            
            if( Oval2DCenter.y/Oval2DSampleDistance > Oval2DPix.pheight/2)
                Oval2DText->GetPositionCoordinate()->SetValue( Oval2DCenter.x-Oval2DRadius, Oval2DCenter.y-Oval2DRadius - OVAL2DTEXTHEIGHT);
            else
                Oval2DText->GetPositionCoordinate()->SetValue( Oval2DCenter.x-Oval2DRadius, Oval2DCenter.y+Oval2DRadius + 5);
            
            NSString *localizedText = [NSString stringWithFormat: NSLocalizedString( @"Mean: %2.2f SDev: %2.2f\nMin: %2.2f Max: %2.2f", @"ONLY ASCII CHARACTERS ! NO ACCENTS OR HIEROGLYPHS"), rmean, rdev, rmin, rmax];
            
            Oval2DText->SetInput( [localizedText UTF8String]);
            
            aRenderer->AddActor( Oval2DText);
            
            [circle release];
        }
        else
            aRenderer->RemoveActor( Oval2DText);
    }
    
    [self mouseMoved: [[NSApplication sharedApplication] currentEvent]];
}

- (void) getOrientation: (float*) o
{
    long			i, j;
    vtkMatrix4x4	*matrix;
    
    if( aCamera == nil)
        return;
    
    matrix = aCamera->GetViewTransformMatrix();
    
    if( matrix == nil)
        return;
    
    for( i = 0; i < 3; i++)
        for( j = 0; j < 3; j++)
            o[ 3*i + j] = matrix->GetElement( i , j);
    
    o[ 3] = -o[ 3];
    o[ 4] = -o[ 4];
    o[ 5] = -o[ 5];
}

- (void) computeOrientationText
{
    float cos[ 9];
    float vectors[ 9];
    char string[ 256];
    
    [self getCosMatrix: cos];
    [self getOrientation: vectors];
    
    float theta = acos( cos[8]);
    float psi = -atan2( cos[ 6], cos[ 7]);
    float phi = atan2( cos[ 2], cos[ 5]);
    
    phi *= R2D;
    theta *= R2D;
    psi *= R2D;
    
    if( phi < 0)
        phi += 180;
    else
        phi -= 180;
    
    sprintf( string, "S-I: %2.1f\nL-R: %2.1f\nRoll: %2.1f", theta - 90., psi, phi);
    if( oText[ 4])
        oText[ 4]->SetInput( string);
    
    [self getOrientationText:string vector:vectors inversion:YES];
    if( oText[ 0])
        oText[ 0]->SetInput( string);
    
    [self getOrientationText:string vector:vectors inversion:NO];
    if( oText[ 1])
        oText[ 1]->SetInput( string);
    
    [self getOrientationText:string vector:vectors+3 inversion:NO];
    if( oText[ 2])
        oText[ 2]->SetInput( string);
    
    [self getOrientationText:string vector:vectors+3 inversion:YES];
    if( oText[ 3])
        oText[ 3]->SetInput( string);
}

- (void) scrollInStack: (float) delta
{
    _hasChanged = YES;
    vtkCocoaRenderWindowInteractor *interactor = [self getInteractor];
    if (!interactor) return;
    
    isRotating = NO;
    [self resetAutorotate: self];
    
    if( projectionMode != 2 && clipRangeActivated == NO)
    {
        [self Azimuth: delta * 2];
        [self mouseMoved: [[NSApplication sharedApplication] currentEvent]];
        [self setNeedsDisplay: YES];
    }
    else
    {
        if( firstObject.pixelSpacingX > 0)
            delta *= firstObject.pixelSpacingX * 2.;
        
        double position[ 3], focal[ 3];
        float cos[ 9];
        double distance = aCamera->GetDistance();
        
        [self getCosMatrix: cos];
        
        aCamera->GetPosition( position);
        aCamera->GetFocalPoint( focal);
        
        position[ 0] = position[ 0] + cos[ 6] * delta * factor;
        position[ 1] = position[ 1] + cos[ 7] * delta * factor;
        position[ 2] = position[ 2] + cos[ 8] * delta * factor;
        
        focal[ 0] = focal[ 0] + cos[ 6] * delta * factor;
        focal[ 1] = focal[ 1] + cos[ 7] * delta * factor;
        focal[ 2] = focal[ 2] + cos[ 8] * delta * factor;
        
        if( clipRangeActivated)
        {
            if( [self checkPointInVolume: position])
            {
                aCamera->SetPosition( position);
                aCamera->SetFocalPoint( focal);
            }
        }
        else
        {
            aCamera->SetPosition( position);
            aCamera->SetFocalPoint( focal);
        }
        
        aCamera->SetDistance( distance);
        aCamera->ComputeViewPlaneNormal();
        aCamera->OrthogonalizeViewUp();
        
        if( clipRangeActivated)
            aCamera->SetClippingRange( 0.0, clippingRangeThickness);
        else
            aRenderer->ResetCameraClippingRange();
        
        [self setNeedsDisplay:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
    }
}

- (void) scrollWheel:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    return [self scrollInStack: [theEvent deltaY]];
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    _hasChanged = YES;
    ToolMode tool = [self getTool: theEvent];
    [self setCursorForView: tool];
    
    [super otherMouseDown: theEvent];
}

- (void) setRotate: (BOOL) r
{
    isRotating = r;
}

-(void) mouseMoved: (NSEvent*) theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    if( ![[self window] isVisible])
        return;
    
    if( [controller windowWillClose])
        return;
    
    [drawLock lock];
    
    long	pix[ 3];
    float	pos[ 3], value;
    
    NSPoint mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    
    if( isViewportResizable)
    {
        if( mouseLocStart.x < 20 && mouseLocStart.y < 20 && isViewportResizable)
            [self setCursorForView: tTranslate];
        else [self setCursorForView: [self getTool: theEvent]];
        
        if( cursorSet) [cursor set];
    }
    
    NSMutableString *s = [NSMutableString stringWithFormat: NSLocalizedString( @"View Size: %d x %d", nil), (int) [self frame].size.width, (int) [self frame].size.height];
    
    if( [self get3DPixelUnder2DPositionX:mouseLocStart.x Y:mouseLocStart.y pixel:pix position:pos value:&value])
    {
        int sliceNo;
        if( [[[controller viewer2D] imageView] flippedData]) sliceNo = pix[ 2];
        else sliceNo = (long)[pixList count] -1 -pix[ 2];
        
        NSString	*pixLoc = [[NSString stringWithFormat: @"X:%d Y:%d Z:%d (px)", (int) pix[ 0], (int) pix[ 1], sliceNo] stringByPaddingToLength: 23 withString: @" " startingAtIndex: 0];
        NSString	*mmLoc = [[NSString stringWithFormat: @"X:%.2f Y:%.2f Z:%.2f (mm)", pos[ 0], pos[ 1], pos[ 2]] stringByPaddingToLength: 38 withString: @" " startingAtIndex: 0];
        NSString	*val = [[NSString stringWithFormat: @"%.2f", value] stringByPaddingToLength: 9 withString: @" " startingAtIndex:  0];
        
        [s appendFormat: NSLocalizedString( @"   Pixel: %@    %@ %@", nil), val, pixLoc, mmLoc];
    }
    
    if( measureLength)
    {
        if( measureLength < .1)
            [s appendFormat: NSLocalizedString( @"   Measurement: %2.2f mm ", nil), measureLength * 10.0];
        else
            [s appendFormat: NSLocalizedString( @"   Measurement: %2.2f cm ", nil), measureLength];
    }
    
    if( aCamera->GetParallelProjection())
    {
        [s appendFormat: NSLocalizedString( @"   Scale: %2.3f %% ", nil), [self scaleFactor]];
    }
    
    [pixelInformation setStringValue: s];
    
    [drawLock unlock];
    
    //	NSLog(@"Mouse moved!!");
}

- (float) scaleFactor
{
    return 100./([firstObject pixelSpacingX] * aCamera->GetParallelScale());
}

-(void) squareView:(id) sender
{
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 1) return;
    
    NSRect  selfFrame = [[[self window] contentView] frame];
    
    selfFrame.size.height -= 30;
    
    NSRect	newFrame = selfFrame;
    NSRect	beforeFrame = selfFrame;
    
    int		border = selfFrame.size.height-1;
    
    if( border > selfFrame.size.width) border = selfFrame.size.width;
    
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 2) border = 512;
    if( [[NSUserDefaults standardUserDefaults] integerForKey:@"VRDefaultViewSize"] == 3) border = 768;
    
    newFrame.size.width = (int)border;
    newFrame.size.height = (int)border;
    
    newFrame.origin.x = (int) ((beforeFrame.size.width - border) / 2);
    newFrame.origin.y = (int) (10 + (beforeFrame.size.height - border) / 2);
    
    [self setFrame: newFrame];
    
    [[self window] display];
}

- (void) generateROI
{
    vtkPoints *pts = vtkPoints::New();
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"SplineForScissors"] && [ROIPoints count] >= 3)		// Spline
    {
        int nb;
        
        nb = [ROIPoints count]+1;
        
        NSPoint nspts[nb];
        
        for(long i=0; i<[ROIPoints count]; i++)
            nspts[i] = [[ROIPoints objectAtIndex:i] pointValue];
        
        nspts[[ROIPoints count]] = [[ROIPoints objectAtIndex:0] pointValue]; // we add the first point as the last one to smooth the spline
        
        NSPoint *splinePts;
        
        long newNb = spline(nspts, nb, &splinePts, nil, 0.1);
        
        for( long i=0; i<newNb; i++)
            pts->InsertPoint( pts->GetNumberOfPoints(), splinePts[i].x, splinePts[i].y, 0);
        
        if(newNb) free(splinePts);
    }
    else
    {
        for( NSValue *pt in ROIPoints)
            pts->InsertPoint( pts->GetNumberOfPoints(), [pt pointValue].x, [pt pointValue].y, 0);
    }
    
    vtkCellArray *rect = vtkCellArray::New();
    rect->InsertNextCell( pts->GetNumberOfPoints()+1);
    for( int i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
    rect->InsertCellPoint( 0);
    
    ROI3DData->SetVerts( rect);
    ROI3DData->SetLines( rect);		rect->Delete();
    ROI3DData->SetPoints( pts);		pts->Delete();
}

-(void) magnifyWithEvent:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
}

-(void) rotateWithEvent:(NSEvent *)event
{
    if ([self eventToPlugins:event]) return;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    _hasChanged = YES;
    
    if (_dragInProgress == NO && ([theEvent deltaX] != 0 || [theEvent deltaY] != 0))
    {
        [self deleteMouseDownTimer];
    }
    
    if (_dragInProgress == YES) return;
    
    [drawLock lock];
    
    if (_resizeFrame)
    {
        NSRect	newFrame = [self frame];
        NSRect	beforeFrame;
        NSPoint mouseLoc = [theEvent locationInWindow];
        
        if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD * lowResLODFactor);
        if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD * lowResLODFactor);
        
        beforeFrame = [self frame];
        
        if( [theEvent modifierFlags] & NSShiftKeyMask)
        {
            newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
            newFrame.size.height = newFrame.size.width;
            
            mouseLoc.x = ([[[self window] contentView] frame].size.width - newFrame.size.width) / 2;
            mouseLoc.y = ([[[self window] contentView] frame].size.height - newFrame.size.height) / 2;
            mouseLoc.y -= 5;
        }
        
        if( [[[self window] contentView] frame].size.width - mouseLoc.x*2 < 100)
            mouseLoc.x = ([[[self window] contentView] frame].size.width - 100) / 2;
        
        if( [[[self window] contentView] frame].size.height - mouseLoc.y*2 < 100)
            mouseLoc.y = ([[[self window] contentView] frame].size.height - 100) / 2;
        
        if( mouseLoc.x < 10)
            mouseLoc.x = 10;
        
        if( mouseLoc.y < 10)
            mouseLoc.y = 10;
        
        newFrame.origin.x = mouseLoc.x;
        newFrame.origin.y = mouseLoc.y;
        
        newFrame.size.width = [[[self window] contentView] frame].size.width - mouseLoc.x*2;
        newFrame.size.height = [[[self window] contentView] frame].size.height - 10 - mouseLoc.y*2;
        
        [self setFrame: newFrame];
        
        [self mouseMoved: theEvent];
        
        aCamera->Zoom( beforeFrame.size.height / newFrame.size.height);
        
        [[self window] display];
    }
    else
    {
        NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
        float WWAdapter, endlevel, startlevel;
        int shiftDown;
        int controlDown;
        switch (_tool)
        {
            case tOval:
            {
                [self deleteMouseDownTimer];
                
                if( bestRenderingWasGenerated)
                {
                    bestRenderingWasGenerated = NO;
                    [self display];
                }
                dontRenderVolumeRenderingOsiriX = 1;
                
                double	*pp;
                
                // Click point 3D to 2D
                
                aRenderer->SetDisplayPoint( mouseLoc.x, mouseLoc.y, 0);
                aRenderer->DisplayToWorld();
                pp = aRenderer->GetWorldPoint();
                
                // Create the 2D Actor
                
                aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
                aRenderer->WorldToDisplay();
                
                double *tempPoint = aRenderer->GetDisplayPoint();
                
                float dx = Oval2DCenter.x - tempPoint[ 0];
                float dy = Oval2DCenter.y - tempPoint[ 1];
                Oval2DRadius = sqrt(dx*dx+dy*dy);
                
                Oval2DData->SetRadius( Oval2DRadius);
                Oval2DData->SetCenter( Oval2DCenter.x, Oval2DCenter.y, 0);
                
                aRenderer->AddActor2D( Oval2DActor);
                
                [self computeLength];
                
                [self getCosMatrix: Oval2DCos];
                [self getOrigin: Oval2DPosition];
                
                [self setNeedsDisplay: YES];
            }
                break;
                
            case tMesure:
            {
                [self deleteMouseDownTimer];
                
                if( bestRenderingWasGenerated)
                {
                    bestRenderingWasGenerated = NO;
                    [self display];
                }
                dontRenderVolumeRenderingOsiriX = 1;
                
                double	*pp;
                long	i;
                
                vtkPoints *pts = Line2DData->GetPoints();
                
                if( pts->GetNumberOfPoints() > 0)
                {
                    // Click point 3D to 2D
                    
                    aRenderer->SetDisplayPoint( mouseLoc.x, mouseLoc.y, 0);
                    aRenderer->DisplayToWorld();
                    pp = aRenderer->GetWorldPoint();
                    
                    // Create the 2D Actor
                    
                    aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
                    aRenderer->WorldToDisplay();
                    
                    double *tempPoint = aRenderer->GetDisplayPoint();
                    
                    pts->SetPoint( pts->GetNumberOfPoints()-1, tempPoint[0], tempPoint[ 1], 0);
                    
                    vtkCellArray *rect = vtkCellArray::New();
                    rect->InsertNextCell( pts->GetNumberOfPoints()+1);
                    for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
                    rect->InsertCellPoint( 0);
                    
                    Line2DData->SetVerts( rect);
                    Line2DData->SetLines( rect);		rect->Delete();
                    
                    Line2DData->SetPoints( pts);
                    
                    [self computeLength];
                    
                    [self setNeedsDisplay: YES];
                }
            }
                break;
                
            case tWLBlended:
                _startWW = blendingWw;
                _startWL = blendingWl;
                _startMin = blendingWl - blendingWw/2;
                _startMax = blendingWl + blendingWw/2;
                WWAdapter  = _startWW / 100.0;
                
                if( [[[controller blendingController] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller blendingController] modality] isEqualToString:@"NM"]))
                {
                    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"])
                    {
                        case 0:
                            blendingWl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
                            blendingWw =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
                            
                            if( blendingWw < 0.1) blendingWw = 0.1;
                            break;
                            
                        case 1:
                            endlevel = _startMax + (-[theEvent deltaY]) * WWAdapter ;
                            
                            blendingWl =  (endlevel - _startMin) / 2 + [[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"];
                            blendingWw = endlevel - _startMin;
                            
                            if( blendingWw < 0.1) blendingWw = 0.1;
                            if( blendingWl - blendingWw/2 < 0) blendingWl = blendingWw/2;
                            break;
                            
                        case 2:
                            endlevel = _startMax - ([theEvent deltaY]) * WWAdapter ;
                            startlevel = _startMin + ([theEvent deltaX]) * WWAdapter ;
                            
                            if( startlevel < 0) startlevel = 0;
                            
                            blendingWl = startlevel + (endlevel - startlevel) / 2;
                            blendingWw = endlevel - startlevel;
                            
                            if( blendingWw < 0.1) blendingWw = 0.1;
                            if( blendingWl - blendingWw/2 < 0) wl = blendingWw/2;
                            break;
                    }
                }
                else
                {
                    blendingWl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
                    blendingWw =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
                }
                
                if( blendingWw < 0.1) blendingWw = 0.1;
                
                [self setBlendingWLWW: blendingWl :blendingWw];
                
                [self setNeedsDisplay:YES];
                break;
                
            case tWL:
            {
                _startWW = ww;
                _startWL = wl;
                _startMin = wl - ww/2;
                _startMax = wl + ww/2;
                WWAdapter  = _startWW / 100.0;
                
                if( [[[controller viewer2D] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller viewer2D] modality] isEqualToString:@"NM"]))
                {
                    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"])
                    {
                        case 0:
                            wl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
                            ww =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
                            
                            if( ww < 0.1) ww = 0.1;
                            break;
                            
                        case 1:
                            endlevel = _startMax + (-[theEvent deltaY]) * WWAdapter ;
                            
                            wl =  (endlevel - _startMin) / 2 + [[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"];
                            ww = endlevel - _startMin;
                            
                            if( ww < 0.1) ww = 0.1;
                            if( wl - ww/2 < 0) wl = ww/2;
                            break;
                            
                        case 2:
                            endlevel = _startMax - ([theEvent deltaY]) * WWAdapter ;
                            startlevel = _startMin + ([theEvent deltaX]) * WWAdapter ;
                            
                            if( startlevel < 0) startlevel = 0;
                            
                            wl = startlevel + (endlevel - startlevel) / 2;
                            ww = endlevel - startlevel;
                            
                            if( ww < 0.1) ww = 0.1;
                            if( wl - ww/2 < 0) wl = ww/2;
                            break;
                    }
                }
                else
                {
                    wl =  (_startWL - (long) ([theEvent deltaY])*WWAdapter);
                    ww =  (_startWW + (long) ([theEvent deltaX])*WWAdapter);
                }
                
                if( ww < 0.1) ww = 0.1;
                
                [self setOpacity: currentOpacityArray];
                
                if( isRGB)
                    colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
                else if (advancedCLUT)
                {
                    [clutOpacityView setWL:wl ww:ww];
                    [clutOpacityView setCLUTtoVRView:YES];
                    [drawLock unlock];
                    return;
                }
                else
                    colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
                
                if( [[[controller viewer2D] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller viewer2D] modality] isEqualToString:@"NM"]))
                {
                    if( ww < 50) sprintf(WLWWString, "From: %0.4f   To: %0.4f ", wl-ww/2, wl+ww/2);
                    else sprintf(WLWWString, "From: %0.f   To: %0.f ", wl-ww/2, wl+ww/2);
                }
                else
                {
                    if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f ", wl, ww);
                    else sprintf(WLWWString, "WL: %0.f WW: %0.f ", wl, ww);
                }
                
                //					if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAutoCropScissors"] == NO)
                //						[self autoCroppingBox];
                
                textWLWW->SetInput( WLWWString);
                [self setNeedsDisplay:YES];
            }
                break;
                
            case t3DCut:
                
                if( fabs(mouseLoc.x - _previousLoc.x) > 5. || fabs(mouseLoc.y - _previousLoc.y) > 5.)
                {
                    double	*pp;
                    
                    aRenderer->SetDisplayPoint( mouseLoc.x, mouseLoc.y, 0);
                    aRenderer->DisplayToWorld();
                    pp = aRenderer->GetWorldPoint();
                    
                    // Create the 2D Actor
                    
                    aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
                    aRenderer->WorldToDisplay();
                    
                    double *tempPoint = aRenderer->GetDisplayPoint();
                    
                    [ROIPoints addObject: [NSValue valueWithPoint: NSMakePoint( tempPoint[0], tempPoint[ 1])]];
                    
                    [self generateROI];
                    
                    [self setNeedsDisplay: YES];
                    
                    _previousLoc = mouseLoc;
                }
                break;
                
            case tRotate:
                shiftDown = 0;
                controlDown = 1;
                [self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
                [self computeOrientationText];
                [self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
                break;
                
            case t3DRotate:
            case tCamera3D:
            {
                if( _tool == tCamera3D || clipRangeActivated == YES)
                {
                    aCamera->Yaw( -([theEvent deltaX]) / 5.);
                    aCamera->Pitch( -([theEvent deltaY]) / 5.);
                    aCamera->ComputeViewPlaneNormal();
                    aCamera->OrthogonalizeViewUp();
                    
                    if( clipRangeActivated)
                        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
                    else
                        aRenderer->ResetCameraClippingRange();
                    
                    [self computeOrientationText];
                    [self setNeedsDisplay:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
                }
                else
                {
                    shiftDown = 0;
                    controlDown = 0;
                    [self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
                    [self computeOrientationText];
                    [self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
                }
            }
                break;
            case tTranslate:
                shiftDown = 1;
                controlDown = 0;
                [self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
                [self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
                break;
                
            case tZoom:
                [self rightMouseDragged:theEvent];
                break;
                
            default:
                break;
        }
    }
    
    if( croppingBox)
        croppingBox->SetHandleSize( 0.005);
    
    [drawLock unlock];
    
    bestRenderingWasGenerated = NO;
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    _hasChanged = YES;
    [drawLock lock];
    NSPoint mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
    float distance ;
    
    if (([theEvent deltaX] != 0 || [theEvent deltaY] != 0))
    {
        [self deleteRightMouseDownTimer];
    }
    
    if( projectionMode != 2)
    {
        int shiftDown = 0;
        int controlDown = 1;
        [self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
        [self computeLength];
        [self getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
    }
    else
    {
        distance = aCamera->GetDistance();
        aCamera->Dolly( 1.0 + (-[theEvent deltaY]) / 1200.);
        aCamera->SetDistance( distance);
        aCamera->ComputeViewPlaneNormal();
        aCamera->OrthogonalizeViewUp();
        
        if( clipRangeActivated)
            aCamera->SetClippingRange( 0.0, clippingRangeThickness);
        else
            aRenderer->ResetCameraClippingRange();
        
        [self setNeedsDisplay:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
    }
    
    if( croppingBox)
        croppingBox->SetHandleSize( 0.005);
    
    [drawLock unlock];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    _hasChanged = YES;
    [self deleteMouseDownTimer];
    if (_contextualMenuActive)
    {
        [self rightMouseUp:theEvent];
        return;
    }
    
    [drawLock lock];
    
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
    
    if (_resizeFrame)
        [self setNeedsDisplay:YES];
    else
    {
        switch (_tool)
        {
            case t3DRotate:
            case tCamera3D:
            {
                if( _tool == tCamera3D || clipRangeActivated == YES)
                {
                    if( keep3DRotateCentered == NO)
                    {
                        // Reset window center
                        double xx = 0;
                        double yy = 0;
                        
                        double pWC[ 2];
                        aCamera->GetWindowCenter( pWC);
                        pWC[ 0] *= ([self frame].size.width/2.);
                        pWC[ 1] *= ([self frame].size.height/2.);
                        
                        if( pWC[ 0] != xx || pWC[ 1] != yy)
                        {
                            aCamera->SetWindowCenter( 0, 0);
                            [self panX: ([self frame].size.width/2.) -(pWC[ 0] - xx)*10000. Y: ([self frame].size.height/2.) -(pWC[ 1] - yy) *10000.];
                        }
                    }
                    [self setNeedsDisplay:YES];
                }
                else
                {
                    if( volumeMapper)
                        volumeMapper->SetMinimumImageSampleDistance( LOD);
                    
                    if( blendingVolumeMapper)
                        blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
                    
                    [self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
                }
            }
                break;
                
            case tWL:
            case tWLBlended:
                [self setNeedsDisplay:YES];
                break;
            case tRotate:
            case tTranslate:
                if( volumeMapper)
                    volumeMapper->SetMinimumImageSampleDistance( LOD);
                
                if( blendingVolumeMapper)
                    blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
                
                [self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
                break;
            case tZoom:
                [self zoomMouseUp:(NSEvent *)theEvent];
                break;
            case tMesure:
            case tOval:
            case t3DCut:
                [self displayIfNeeded];
                dontRenderVolumeRenderingOsiriX = 0;
                break;
            case tBonesRemoval:		// <- DO NOTHING !
                break;
            default:
                [self setNeedsDisplay:YES];
                break;
        }
    }
    
    bestRenderingWasGenerated = NO;
    
    [drawLock unlock];
}

- (void)zoomMouseUp:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    _hasChanged = YES;
    if (_tool == tZoom)
    {
        if( volumeMapper)
            volumeMapper->SetMinimumImageSampleDistance( LOD);
        
        if( blendingVolumeMapper)
            blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
        
        if( projectionMode != 2)
        {
            [self computeLength];
            [self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
        }
        else
        {
            [self setNeedsDisplay:YES];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    _hasChanged = YES;
    [drawLock lock];
    _contextualMenuActive = NO;
    if (_rightMouseDownTimer)
        [self deleteRightMouseDownTimer];
    
    [self mouseDown:theEvent];
    
    [drawLock unlock];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    _hasChanged = YES;
    [drawLock lock];
    
    [self deleteRightMouseDownTimer];
    if (_contextualMenuActive)
    {
        _contextualMenuActive = NO;
        [self getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
        return;
    }
    
    if (_tool == tZoom)
        [self zoomMouseUp:(NSEvent *)theEvent];
    
    [drawLock unlock];
}

- (NSPoint) windowCenter
{
    double pWC[ 2];
    aCamera->GetWindowCenter( pWC);
    pWC[ 0] *= ([self frame].size.width/2.);
    pWC[ 1] *= ([self frame].size.height/2.);
    
    return NSMakePoint( -pWC[ 0], pWC[ 1]);
}

- (void) setWindowCenter: (NSPoint) loc
{
    double xx = -(loc.x - [self frame].size.width/2.);
    double yy = -(loc.y - [self frame].size.height/2.);
    
    double pWC[ 2];
    aCamera->GetWindowCenter( pWC);
    pWC[ 0] *= ([self frame].size.width/2.);
    pWC[ 1] *= ([self frame].size.height/2.);
    
    if( pWC[ 0] != xx || pWC[ 1] != yy)
    {
        aCamera->SetWindowCenter( xx / ([self frame].size.width/2.), yy / ([self frame].size.height/2.));
        [self panX: ([self frame].size.width/2.) -(pWC[ 0] - xx)*10000. Y: ([self frame].size.height/2.) -(pWC[ 1] - yy) *10000.];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    snVRView = self;
    dontRenderVolumeRenderingOsiriX = 0;
    
    _hasChanged = YES;
    [drawLock lock];
    
    if( snCloseEventTimer)
        [snCloseEventTimer fire];
    
    snStopped = YES;
    
    NSPoint		mouseLoc, mouseLocPre;
    ToolMode    tool;
    
    [cursor set];
    
    noWaitDialog = YES;
    tool = currentTool;
    
    if ([theEvent type] == NSLeftMouseDown)
    {
        if (_mouseDownTimer)
        {
            [self deleteMouseDownTimer];
        }
        
        if( [[controller style] isEqualToString: @"noNib"] == NO)
            _mouseDownTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startDrag:) userInfo:theEvent  repeats:NO] retain];
    }
    
    mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    
    int clickCount = 1;
    
    @try
    {
        if( [theEvent type] ==	NSLeftMouseDown || [theEvent type] ==	NSRightMouseDown || [theEvent type] ==	NSLeftMouseUp || [theEvent type] == NSRightMouseUp)
            clickCount = [theEvent clickCount];
    }
    @catch (NSException * e)
    {
        clickCount = 1;
    }
    
    if( clickCount > 1 && (tool != t3Dpoint))
    {
        long	pix[ 3];
        float	pos[ 3], value;
        
        if( clipRangeActivated)
        {
            float position[ 3], sc[ 3], cos[ 9], r = [self getResolution];
            
            [self getOrigin: position];
            [self getCosMatrix: cos];
            
            position[0] = ([self frame].size.height - _mouseLocStart.y)*cos[3]*r + _mouseLocStart.x*cos[0]*r +position[0];
            position[1] = ([self frame].size.height - _mouseLocStart.y)*cos[4]*r + _mouseLocStart.x*cos[1]*r +position[1];
            position[2] = ([self frame].size.height - _mouseLocStart.y)*cos[5]*r + _mouseLocStart.x*cos[2]*r +position[2];
            
            [firstObject convertDICOMCoords: position toSliceCoords: sc pixelCenter: YES];
            
            sc[ 0] /= [firstObject pixelSpacingX];
            sc[ 1] /= [firstObject pixelSpacingY];
            sc[ 2] /= [firstObject sliceInterval];
            
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: sc[0]], @"x", [NSNumber numberWithInt: sc[1]], @"y", [NSNumber numberWithInt: sc[2]], @"z", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDisplay3dPointNotification object:pixList  userInfo: dict];
        }
        else
        {
            if( [self get3DPixelUnder2DPositionX:_mouseLocStart.x Y:_mouseLocStart.y pixel:pix position:pos value:&value])
            {
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: pix[0]], @"x", [NSNumber numberWithInt: pix[1]], @"y", [NSNumber numberWithInt: pix[2]], @"z",
                                      nil];
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDisplay3dPointNotification object:pixList  userInfo: dict];
            }
        }
        [drawLock unlock];
        return;
    }
    
    if( _mouseLocStart.x < 20 && _mouseLocStart.y < 20 && isViewportResizable)
    {
        _resizeFrame = YES;
    }
    else
    {
        _resizeFrame = NO;
        tool = [self getTool: theEvent];
        _tool = tool;
        [self setCursorForView: tool];
        
        if( tool != tWL && tool != tZoom)
        {
            isRotating = NO;
            
            [self resetAutorotate: self];
        }
        
        if( tool == tMesure)
        {
            [self deleteMouseDownTimer];
            
            if( bestRenderingWasGenerated)
            {
                bestRenderingWasGenerated = NO;
                [self display];
            }
            dontRenderVolumeRenderingOsiriX = 1;
            
            double	*pp;
            long	i;
            
            vtkPoints		*pts = Line2DData->GetPoints();
            
            if( pts->GetNumberOfPoints() >= 2)
            {
                // Delete current ROI
                pts = vtkPoints::New();
                vtkCellArray *rect = vtkCellArray::New();
                Line2DData-> SetPoints( pts);		pts->Delete();
                Line2DData-> SetLines( rect);		rect->Delete();
                
                pts = Line2DData->GetPoints();
            }
            
            // Click point 3D to 2D
            
            _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
            
            aRenderer->SetDisplayPoint( _mouseLocStart.x, _mouseLocStart.y, 0);
            aRenderer->DisplayToWorld();
            pp = aRenderer->GetWorldPoint();
            
            // Create the 2D Actor
            
            aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
            aRenderer->WorldToDisplay();
            
            double *tempPoint = aRenderer->GetDisplayPoint();
            
            NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
            
            vtkCellArray *rect;
            
            pts->InsertPoint( pts->GetNumberOfPoints(), tempPoint[0], tempPoint[ 1], 0);
            
            rect = vtkCellArray::New();
            rect->InsertNextCell( pts->GetNumberOfPoints()+1);
            for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
            rect->InsertCellPoint( 0);
            
            Line2DData->SetVerts( rect);
            Line2DData->SetLines( rect);		rect->Delete();
            
            pts->InsertPoint( pts->GetNumberOfPoints(), tempPoint[0], tempPoint[ 1], 0);
            
            rect = vtkCellArray::New();
            rect->InsertNextCell( pts->GetNumberOfPoints()+1);
            for( i = 0; i < pts->GetNumberOfPoints(); i++) rect->InsertCellPoint( i);
            rect->InsertCellPoint( 0);
            
            Line2DData->SetVerts( rect);
            Line2DData->SetLines( rect);		rect->Delete();
            
            Line2DData->SetPoints( pts);
            
            [self computeLength];
            
            [self setNeedsDisplay: YES];
        }
        else if( tool == tOval)
        {
            [self deleteMouseDownTimer];
            
            aRenderer->RemoveActor( Oval2DText);
            aRenderer->RemoveActor2D( Oval2DActor);
            Oval2DRadius = 0;
            
            if( bestRenderingWasGenerated)
            {
                bestRenderingWasGenerated = NO;
                [self display];
            }
            dontRenderVolumeRenderingOsiriX = 1;
            
            // Click point 3D to 2D
            _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
            
            aRenderer->SetDisplayPoint( _mouseLocStart.x, _mouseLocStart.y, 0);
            aRenderer->DisplayToWorld();
            double *pp = aRenderer->GetWorldPoint();
            
            WorldOval2DCenter.x = pp[0];
            WorldOval2DCenter.y = pp[ 1];
            
            // Create the 2D Actor
            aRenderer->SetWorldPoint( pp[0], pp[1], pp[2], 1.0);
            aRenderer->WorldToDisplay();
            
            double *tempPoint = aRenderer->GetDisplayPoint();
            
            Oval2DCenter.x = tempPoint[ 0];
            Oval2DCenter.y = tempPoint[ 1];
            
            [self computeLength];
            
            [self setNeedsDisplay: YES];
        }
        else if( tool == t3DCut)
        {
            double	*pp;
            
            if( bestRenderingWasGenerated)
            {
                bestRenderingWasGenerated = NO;
                [self display];
            }
            
            dontRenderVolumeRenderingOsiriX = 1;
            
            // Click point 3D to 2D
            
            _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
            
            aRenderer->SetDisplayPoint( _mouseLocStart.x, _mouseLocStart.y, 0);
            aRenderer->DisplayToWorld();
            pp = aRenderer->GetWorldPoint();
            
            // Create the 2D Actor
            
            aRenderer->SetWorldPoint(pp[0], pp[1], pp[2], 1.0);
            aRenderer->WorldToDisplay();
            
            double *tempPoint = aRenderer->GetDisplayPoint();
            
            NSLog(@"New pt: %2.2f %2.2f", tempPoint[0] , tempPoint[ 1]);
            
            [ROIPoints addObject: [NSValue valueWithPoint: NSMakePoint( tempPoint[0], tempPoint[ 1])]];
            [self generateROI];
            
            //			if( ROIUPDATE == NO)
            //			{
            //				ROIUPDATE = YES;
            //				[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:0];
            //			}
            
            [self setNeedsDisplay: YES];
        }
        else if( tool == tWL)
        {
            _startWW = ww;
            _startWL = wl;
            _startMin = wl - ww/2;
            _startMax = wl + ww/2;
            
            _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
            
            if( volumeMapper)
                volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            if( blendingVolumeMapper)
                blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
        }
        else if( tool == tWLBlended)
        {
            _startWW = blendingWw;
            _startWL = blendingWl;
            _startMin = blendingWl - blendingWw/2;
            _startMax = blendingWl + blendingWw/2;
            
            _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
            
            if( volumeMapper)
                volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            if( blendingVolumeMapper)
                blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
        }
        else if( tool == tRotate)
        {
            int shiftDown = 0;
            int controlDown = 1;
            
            if( volumeMapper)
                volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            if( blendingVolumeMapper)
                blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            mouseLoc = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
            [self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
            [self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
        }
        else if( tool == t3DRotate || tool == tCamera3D)
        {
            if( _tool == tCamera3D || clipRangeActivated == YES)
            {
                mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
                
                if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
                if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
                
                if( clipRangeActivated)
                {
                    if( keep3DRotateCentered == NO)
                    {
                        double xx = -(mouseLocPre.x - [self frame].size.width/2.);
                        double yy = -(mouseLocPre.y - [self frame].size.height/2.);
                        
                        double pWC[ 2];
                        aCamera->GetWindowCenter( pWC);
                        pWC[ 0] *= ([self frame].size.width/2.);
                        pWC[ 1] *= ([self frame].size.height/2.);
                        
                        if( pWC[ 0] != xx || pWC[ 1] != yy)
                        {
                            aCamera->SetWindowCenter( xx / ([self frame].size.width/2.), yy / ([self frame].size.height/2.));
                            [self panX: ([self frame].size.width/2.) -(pWC[ 0] - xx)*10000. Y: ([self frame].size.height/2.) -(pWC[ 1] - yy) *10000.];
                        }
                    }
                }
            }
            else
            {
                int shiftDown = 0;//([theEvent modifierFlags] & NSShiftKeyMask);
                int controlDown = 0;//([theEvent modifierFlags] & NSControlKeyMask);
                
                if( volumeMapper)
                    volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
                
                if( blendingVolumeMapper)
                    blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
                
                mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
                
                [self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
                [self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
                
                if( clipRangeActivated)
                    aCamera->SetClippingRange( 0.0, clippingRangeThickness);
                else
                    aRenderer->ResetCameraClippingRange();
            }
        }
        else if( tool == tTranslate)
        {
            int shiftDown = 1;
            int controlDown = 0;
            
            if( volumeMapper)
                volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            if( blendingVolumeMapper)
                blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
            [self getInteractor]->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
            [self getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
        }
        else if( tool == tZoom)
        {
            if( volumeMapper)
                volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            if( blendingVolumeMapper)
                blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            
            if( projectionMode != 2)
            {
                int shiftDown = 0;
                int controlDown = 1;
                
                mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
                [self getInteractor]->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
                [self getInteractor]->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
            }
            else
            {
                // vtkCamera
                mouseLocPre = _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
                
                if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
                if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
            }
        }
        else if( tool == t3Dpoint)
        {
            [self deleteMouseDownTimer];
            
            NSEvent *artificialPKeyDown = [NSEvent keyEventWithType:NSKeyDown
                                                           location:[theEvent locationInWindow]
                                                      modifierFlags:0x0
                                                          timestamp:[theEvent timestamp]
                                                       windowNumber:[theEvent windowNumber]
                                                            context:[theEvent context]
                                                         characters:@"p"
                                        charactersIgnoringModifiers:@"p"
                                                          isARepeat:NO
                                                            keyCode:112
                                           ];
            if( blendingVolume)
                blendingVolume->SetPickable( NO);
            
            [super keyDown: artificialPKeyDown];
            
            if (![self isAny3DPointSelected])
            {
                // add a point on the surface under the mouse click
                [self throw3DPointOnSurface: _mouseLocStart.x : _mouseLocStart.y];
                [self setNeedsDisplay:YES];
            }
            else
            {
                [point3DRadiusSlider setFloatValue: [[point3DRadiusArray objectAtIndex:[self selected3DPointIndex]] floatValue]];
                [point3DColorWell setColor: [point3DColorsArray objectAtIndex:[self selected3DPointIndex]]];
                
                if (clickCount == 2)
                {
                    NSRect r = {[theEvent locationInWindow],NSZeroSize};
                    NSPoint mouseLocationOnScreen = [[self window] convertRectToScreen:r].origin;
                    [point3DInfoPanel setAlphaValue:0.8];
                    [point3DInfoPanel	setFrame:	NSMakeRect(	mouseLocationOnScreen.x - [point3DInfoPanel frame].size.width/2.0,
                                                               mouseLocationOnScreen.y-[point3DInfoPanel frame].size.height-20.0,
                                                               [point3DInfoPanel frame].size.width,
                                                               [point3DInfoPanel frame].size.height)
                                       display:YES animate: NO];
                    [point3DInfoPanel orderFront:self];
                    
                    
                    float pos[3];
                    [[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:pos];
                    
                    int pix[3];
                    pix[0] = (int)[[[[[controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]] points] objectAtIndex:0] x];
                    pix[1] = (int)[[[[[controller roi2DPointsArray] objectAtIndex:[self selected3DPointIndex]] points] objectAtIndex:0] y];
                    pix[2] = [[[controller sliceNumber2DPointsArray] objectAtIndex:[self selected3DPointIndex]] intValue];
                    
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithInt: pix[0]], @"x", [NSNumber numberWithInt: pix[1]], @"y", [NSNumber numberWithInt: pix[2]], @"z",
                                          nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixDisplay3dPointNotification object:pixList  userInfo: dict];
                }
            }
        }
        else if( tool == tBonesRemoval)
        {
            [self deleteMouseDownTimer];
            
            NSLog( @"**** Bone Removal Start");
            // enable Undo
            [controller prepareUndo];
            NSLog( @"**** Undo");
            
            // clicked point (2D coordinate)
            _mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView: nil];
            
            long pix[ 3];
            float pos[ 3], value;
            float minValue = [[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionValue"]-[[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionInterval"]/3.;
            
            if( [self get3DPixelUnder2DPositionX:_mouseLocStart.x Y:_mouseLocStart.y pixel:pix position:pos value:&value maxOpacity: BONEOPACITY minValue: minValue])
            {
                WaitRendering	*waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Applying Bone Removal...", nil)];
                [waiting showWindow:self];
                
                NSArray	*roiList = nil;
                
                NSLog( @"ITKSegmentation3D");
                
                int savedMovieIndex = [[controller viewer2D] curMovieIndex];
                
                for ( int m = 0; m < [[controller viewer2D] maxMovieIndex] ; m++)
                {
                    [[controller viewer2D] setMovieIndex: m];
                    [[[controller viewer2D] imageView] setIndex: pix[ 2]]; //set the DCMview on the good slice
                    
                    NSPoint seedPoint;
                    seedPoint.x = pix[ 0];
                    seedPoint.y = pix[ 1];
                    
                    ITKSegmentation3D *itkSegmentation = [[ITKSegmentation3D alloc] initWith:[[controller viewer2D] pixList] :[[controller viewer2D] volumePtr] :-1];
                    
                    [itkSegmentation regionGrowing3D	:[controller viewer2D]	// source viewer
                                                     :nil					// destination viewer = nil means we don't want a new serie
                                                     :-1						// slice = -1 means 3D region growing
                                                     :seedPoint				// startingPoint
                                                     :1						// algorithmNumber, 1 = threshold connected with low & up threshold
                                                     :[NSArray arrayWithObjects:	[NSNumber numberWithFloat: [[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionValue"] -[[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionInterval"]/2.],
                                                       [NSNumber numberWithFloat: [[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionValue"] +[[NSUserDefaults standardUserDefaults] floatForKey: @"VRGrowingRegionInterval"]/2.],
                                                       nil]// algo parameters
                                                     :0						// setIn
                                                     :0.0					// inValue
                                                     :0						// setOut
                                                     :0.0					// outValue
                                                     :(ToolMode)0						// roiType
                                                     :0						// roiResolution
                                                     :@"BoneRemovalAlgorithmROIUniqueName" // newname (I tried to make it unique ;o)
                                                     :NO];					// merge with existing ROIs?
                    
                    // find all ROIs with name = BoneRemoval
                    NSArray *rois = [[controller viewer2D] roisWithName:@"BoneRemovalAlgorithmROIUniqueName"];
                    
                    NSMutableArray *d = [NSMutableArray array];
                    for( ROI *r in rois)
                    {
                        [d addObject: [NSDictionary dictionaryWithObjectsAndKeys: r, @"roi", [r pix], @"curPix", nil]];
                    }
                    
                    roiList = d;
                    
                    [itkSegmentation release];
                    
                    // Dilatation
                    
                    [[controller viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"dilate" radius: 10 sendNotification:NO];
                    [[controller viewer2D] applyMorphology: [roiList valueForKey:@"roi"] action:@"erode" radius: 6 sendNotification:NO];
                    
                    BOOL addition = NO;
                    
                    // Bone Removal
                    NSNumber		*nsnewValue	= [NSNumber numberWithFloat: -1000];		//-1000
                    NSNumber		*nsminValue	= [NSNumber numberWithFloat: -FLT_MAX];		//-99999
                    NSNumber		*nsmaxValue	= [NSNumber numberWithFloat: FLT_MAX];
                    NSNumber		*nsoutside	= [NSNumber numberWithBool: NO];
                    NSNumber		*nsaddition	= [NSNumber numberWithBool: addition];
                    NSMutableArray	*roiToProceed = [NSMutableArray array];
                    
                    for( NSDictionary *rr in roiList)
                    {
                        [roiToProceed addObject: [NSDictionary dictionaryWithObjectsAndKeys:  [rr objectForKey:@"roi"], @"roi", [rr objectForKey:@"curPix"], @"curPix", @"setPixelRoi", @"action", nsnewValue, @"newValue", nsminValue, @"minValue", nsmaxValue, @"maxValue", nsoutside, @"outside", nsaddition, @"addition", nil]];
                    }
                    
                    [[controller viewer2D] roiSetStartScheduler: roiToProceed];
                    
                    NSLog( @"**** Set Pixels");
                    
                    // Update 3D image
                    if( textureMapper)
                    {
                        // Force min/max recomputing
                        [self movieChangeSource: data];
                        //reader->Modified();
                    }
                    else
                    {
                        if( isRGB == NO)
                            //							vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
                            [BrowserController multiThreadedImageConvert: @"FTo16U" :&srcf :&dst8 :-OFFSET16 :1./valueFactor];
                    }
                }
                
                [[controller viewer2D] setMovieIndex: savedMovieIndex];
                
                [self setNeedsDisplay:YES];
                
                [waiting close];
                [waiting autorelease];
                
                [[controller viewer2D] roiIntDeleteAllROIsWithSameName:@"BoneRemovalAlgorithmROIUniqueName"];
                
                [[controller viewer2D] needsDisplayUpdate];
            }
            else NSRunAlertPanel(NSLocalizedString(@"Bone Removing", nil), NSLocalizedString(@"Failed to detect a high density voxel to start growing region.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            
            NSLog( @"**** Bone Removal End");
        }
        else [super mouseDown:theEvent];
        
        if( croppingBox)
            croppingBox->SetHandleSize( 0.005);
    }
    
    bestRenderingWasGenerated = NO;
    noWaitDialog = NO;
    [drawLock unlock];
}

//- (void) autoCroppingBox
//{
//    return;
//
//	if( croppingBox && isRGB == NO && dontUseAutoCropping == NO)
//	{
//		double a[6], originalPositions[ 6];
//		int aa[6];
//
//		[VRView getCroppingBox:a :volume :croppingBox];
//
//		float b;
//		BOOL found;
//		int width = [firstObject pwidth], height = [firstObject pheight], depth = [pixList count], slice = width * height, x, y, z;
//
//		for( x = 0 ; x < 6; x++)
//			originalPositions[ x] = a[ x];
//
//		for( x = 0 ; x < 6; x++)
//			a[ x] /= superSampling;
//
//		float sliceThickness = [firstObject sliceInterval];
//
//		if( sliceThickness == 0)
//			sliceThickness = [firstObject sliceThickness];
//
//		a[ 4] *= [firstObject pixelSpacingX];
//		a[ 4] /= sliceThickness;
//		a[ 5] *= [firstObject pixelSpacingX];
//		a[ 5] /= sliceThickness;
//
//		a[ 2] *= [firstObject pixelSpacingX] / [firstObject pixelSpacingY];
//		a[ 3] *= [firstObject pixelSpacingX] / [firstObject pixelSpacingY];
//
//		a[ 0] = a[ 0] >= width ? width-1 : a[ 0];		a[ 1] = a[ 1] >= width ? width-1 : a[ 1];
//		a[ 2] = a[ 2] >= height ? height-1 : a[ 2];		a[ 3] = a[ 3] >= height ? height-1 : a[ 3];
//		a[ 4] = a[ 4] >= depth ? depth-1 : a[ 4];		a[ 5] = a[ 5] >= depth ? depth-1 : a[ 5];
//
//		for( x = 0 ; x < 6; x++)
//			aa[ x] = a[ x];
//
//		aa[ 0] = aa[ 0] < 0 ? 0 : aa[ 0];		aa[ 1] = aa[ 1] < 0 ? 0 : aa[ 1];
//		aa[ 2] = aa[ 2] < 0 ? 0 : aa[ 2];		aa[ 3] = aa[ 3] < 0 ? 0 : aa[ 3];
//		aa[ 4] = aa[ 4] < 0 ? 0 : aa[ 4];		aa[ 5] = aa[ 5] < 0 ? 0 : aa[ 5];
//
//        if(aa[ 1] - aa[ 0] > 0 &&
//           aa[ 3] - aa[ 2] > 0 &&
//           aa[ 5] - aa[ 4] > 0 )
//        {
//    //		NSLog( @"start autocropping");
//
//            int opacityTableSize = (([controller maximumValue] - [controller minimumValue]) * valueFactor);
//
//            opacityTableSize += 100;
//
//            double *opacityTable = (double*) malloc( opacityTableSize * sizeof( double));
//
//            if( opacityTable)
//            {
//                opacityTransferFunction->GetTable(	([controller minimumValue] + OFFSET16) * valueFactor,
//                                                    ([controller maximumValue] + OFFSET16) * valueFactor,
//                                                    opacityTableSize,
//                                                    opacityTable);
//                short *sdata = (short*) data8;
//                short v = ([controller minimumValue] + OFFSET16) * valueFactor;
//
//                #define CHECKINTERVAL 3
//
//                for( found = NO, x = aa[ 0]; x < width && x < aa[ 1]; x+=CHECKINTERVAL)
//                {
//                    for(  y = aa[ 2]; y < height && y < aa[ 3]; y+=CHECKINTERVAL)
//                    {
//                        for(  z = aa[ 4]; z < depth && z < aa[ 5]; z+=CHECKINTERVAL)
//                        {
//                            short p = *(sdata + x + y * width + z * slice);
//                            if( p != v && opacityTable[ p] > 0)
//                            {
//                                aa[ 0] = x;
//                                goto A2;
//                            }
//                        }
//                    }
//                }
//                aa[ 0] = a[ 1];
//
//                A2:
//                for( found = NO, x = aa[ 1]; x >= 0 && x > aa[ 0]; x-=CHECKINTERVAL)
//                {
//                    for(  y = aa[ 2]; y < height && y < aa[ 3]; y+=CHECKINTERVAL)
//                    {
//                        for(  z = aa[ 4]; z < depth && z < aa[ 5]; z+=CHECKINTERVAL)
//                        {
//                            short p = *(sdata + x + y * width + z * slice);
//                            if( p != v && opacityTable[ p] > 0)
//                            {
//                                aa[ 1] = x;
//                                goto A3;
//                            }
//                        }
//                    }
//                }
//                aa[ 1] = aa[ 0];
//
//                ////////////
//                A3:
//                for( found = NO, y = aa[ 2]; y < height && y < aa[ 3]; y+=CHECKINTERVAL)
//                {
//                    for(  x = aa[ 0]; x < width && x < aa[ 1]; x+=CHECKINTERVAL)
//                    {
//                        for(  z = aa[ 4]; z < depth && z < aa[ 5]; z+=CHECKINTERVAL)
//                        {
//                            short p = *(sdata + x + y * width + z * slice);
//                            if( p != v && opacityTable[ p] > 0)
//                            {
//                                aa[ 2] = y;
//                                goto A4;
//                            }
//                        }
//                    }
//                }
//                aa[ 2] = aa[ 3];
//
//                A4:
//                for( found = NO, y = aa[ 3]; y >= 0 && y > aa[ 2]; y-=CHECKINTERVAL)
//                {
//                    for(  x = aa[ 0]; x < width && x < aa[ 1]; x+=CHECKINTERVAL)
//                    {
//                        for(  z = aa[ 4]; z < depth && z < aa[ 5]; z+=CHECKINTERVAL)
//                        {
//                            short p = *(sdata + x + y * width + z * slice);
//                            if( p != v && opacityTable[ p] > 0)
//                            {
//                                aa[ 3] = y;
//                                goto A5;
//                            }
//                        }
//                    }
//                }
//                aa[ 3] = aa[ 2];
//
//                ////////////
//                A5:
//                for( found = NO, z = aa[ 4]; z < depth && z < aa[ 5]; z+=CHECKINTERVAL)
//                {
//                    for(  x = aa[ 0]; x < width && x < aa[ 1]; x+=CHECKINTERVAL)
//                    {
//                        for(  y = aa[ 2]; y < height && y < aa[ 3]; y+=CHECKINTERVAL)
//                        {
//                            short p = *(sdata + x + y * width + z * slice);
//                            if( p != v && opacityTable[ p] > 0)
//                            {
//                                aa[ 4] = z;
//                                goto A6;
//                            }
//                        }
//                    }
//                }
//                aa[ 4] = aa[ 5];
//
//                A6:
//                for( found = NO, z = aa[ 5]; z >= 0 && z > aa[ 4]; z-=CHECKINTERVAL)
//                {
//                    for(  x = aa[ 0]; x < width && x < aa[ 1]; x+=CHECKINTERVAL)
//                    {
//                        for(  y = aa[ 2]; y < height && y < aa[ 3]; y+=CHECKINTERVAL)
//                        {
//                            short p = *(sdata + x + y * width + z * slice);
//                            if( p != v && opacityTable[ p] > 0)
//                            {
//                                aa[ 5] = z;
//                                goto A7;
//                            }
//                        }
//                    }
//                }
//                aa[ 5] = aa[ 4];
//
//                A7:
//
//                aa[ 1]+=CHECKINTERVAL;	aa[ 0]-=CHECKINTERVAL;
//                aa[ 3]+=CHECKINTERVAL;	aa[ 2]-=CHECKINTERVAL;
//                aa[ 5]+=CHECKINTERVAL;	aa[ 4]-=CHECKINTERVAL;
//
//                aa[ 0] = aa[ 0] < 0 ? 0 : aa[ 0];		aa[ 1] = aa[ 1] < 0 ? 0 : aa[ 1];
//                aa[ 2] = aa[ 2] < 0 ? 0 : aa[ 2];		aa[ 3] = aa[ 3] < 0 ? 0 : aa[ 3];
//                aa[ 4] = aa[ 4] < 0 ? 0 : aa[ 4];		aa[ 5] = aa[ 5] < 0 ? 0 : aa[ 5];
//
//                for( x = 0 ; x < 6; x++)
//                    a[ x] = aa[ x];
//
//                a[ 0] = a[ 0] >= width ? width-1 : a[ 0];		a[ 1] = a[ 1] >= width ? width-1 : a[ 1];
//                a[ 2] = a[ 2] >= height ? height-1 : a[ 2];		a[ 3] = a[ 3] >= height ? height-1 : a[ 3];
//                a[ 4] = a[ 4] >= depth ? depth-1 : a[ 4];		a[ 5] = a[ 5] >= depth ? depth-1 : a[ 5];
//
//                NSLog( @"x: %2.2f %%, y: %2.2f %%, z: %2.2f %%",  100 * (a[ 1] - a[ 0]) / (width), 100 * (a[ 3] - a[ 2]) / (height), 100 * (a[ 5] - a[ 4]) / (depth));
//
//
//                a[ 2] /= [firstObject pixelSpacingX] / [firstObject pixelSpacingY];
//                a[ 3] /= [firstObject pixelSpacingX] / [firstObject pixelSpacingY];
//
//                a[ 4] /= [firstObject pixelSpacingX];
//                a[ 4] *= sliceThickness;
//                a[ 5] /= [firstObject pixelSpacingX];
//                a[ 5] *= sliceThickness;
//
//                free( opacityTable);
//
//                ////////////
//
//                for( x = 0 ; x < 6; x++)
//                    a[ x] *= superSampling;
//
//                for( x = 0 ; x < 6; x++)
//                {
//                    if( originalPositions[ 0] > a[ 0]) a[ 0] = originalPositions[ 0];
//                    if( originalPositions[ 1] < a[ 1]) a[ 1] = originalPositions[ 1];
//
//                    if( originalPositions[ 2] > a[ 2]) a[ 2] = originalPositions[ 2];
//                    if( originalPositions[ 3] < a[ 3]) a[ 3] = originalPositions[ 3];
//
//                    if( originalPositions[ 4] > a[ 4]) a[ 4] = originalPositions[ 4];
//                    if( originalPositions[ 5] < a[ 5]) a[ 5] = originalPositions[ 5];
//                }
//
//                [VRView setCroppingBox: a :volume];
//            }
//        }
//	}
//}

- (void) deleteRegion:(int) c :(NSArray*) pxList :(BOOL) blendedSeries
{
    long			tt, stackMax, stackOrientation, i;
    vtkPoints		*roiPts = ROI3DData->GetPoints();
    NSMutableArray	*ROIList = [NSMutableArray array];
    double			xyz[ 3], cameraProj[ 3], cameraProjObj[ 3];
    float			vector[ 9];
    DCMPix			*fObject = [pxList objectAtIndex: 0];
    
    NSLog(@"Scissor Start");
    //	[[[self window] windowController] prepareUndo];
    [controller prepareUndo];
    
    vtkMatrix4x4 *ActorMatrix;
    
    if( blendedSeries)  ActorMatrix = blendingVolume->GetUserMatrix();
    else ActorMatrix = volume->GetUserMatrix();
    
    vtkTransform *Transform = vtkTransform::New();
    
    Transform->SetMatrix( ActorMatrix);
    Transform->Push();
    
    aCamera->GetViewPlaneNormal( cameraProj);
    aCamera->GetPosition( xyz);
    
    if( blendedSeries)
    {
        xyz[ 0] /= blendingFactor;
        xyz[ 1] /= blendingFactor;
        xyz[ 2] /= blendingFactor;
    }
    else
    {
        xyz[ 0] /= factor;
        xyz[ 1] /= factor;
        xyz[ 2] /= factor;
    }
    [fObject orientation: vector];
    
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
        case 0:		stackMax = [fObject pwidth];		break;
        case 1:		stackMax = [fObject pheight];		break;
        case 2:		stackMax = [pxList count];				break;
    }
    
    for( i = 0 ; i < stackMax ; i++)
        [ROIList addObject: [[[ROI alloc] initWithType: tCPolygon :[fObject pixelSpacingX]*factor :[fObject pixelSpacingY]*factor :[DCMPix originCorrectedAccordingToOrientation: fObject]] autorelease]];
    
    // Clip the polygons to the crop box?
    NSValue *minClip = [NSValue valueWithPoint: NSMakePoint( 0, 0)];
    NSValue *maxClip = [NSValue valueWithPoint: NSMakePoint( 0, 0)];
    NSPoint zClip = NSMakePoint( 0, stackMax);
    double a[ 6];
    BOOL applyInsideCroppBox = NO;
    
    if( [VRView getCroppingBox: a :volume :croppingBox])
    {
        int width = [firstObject pwidth], height = [firstObject pheight], depth = [pixList count];
        
        for( int x = 0 ; x < 6; x++)
            a[ x] /= superSampling;
        
        float sliceThickness = [firstObject sliceInterval];
        
        if( sliceThickness == 0)
            sliceThickness = [firstObject sliceThickness];
        
        a[ 4] *= [firstObject pixelSpacingX];
        a[ 4] /= sliceThickness;
        a[ 5] *= [firstObject pixelSpacingX];
        a[ 5] /= sliceThickness;
        
        a[ 2] *= [firstObject pixelSpacingX] / [firstObject pixelSpacingY];
        a[ 3] *= [firstObject pixelSpacingX] / [firstObject pixelSpacingY];
        
        a[ 0] --;   a[ 1] ++;
        a[ 2] --;   a[ 3] ++;
        a[ 4] --;   a[ 5] ++;
        
        a[ 0] = a[ 0] >= width ? width : a[ 0];		a[ 1] = a[ 1] >= width ? width : a[ 1];
        a[ 2] = a[ 2] >= height ? height : a[ 2];	a[ 3] = a[ 3] >= height ? height : a[ 3];
        a[ 4] = a[ 4] >= depth ? depth : a[ 4];		a[ 5] = a[ 5] >= depth ? depth : a[ 5];
        
        a[ 0] = a[ 0] < 0 ? 0 : a[ 0];		a[ 1] = a[ 1] < 0 ? 0 : a[ 1];
        a[ 2] = a[ 2] < 0 ? 0 : a[ 2];		a[ 3] = a[ 3] < 0 ? 0 : a[ 3];
        a[ 4] = a[ 4] < 0 ? 0 : a[ 4];		a[ 5] = a[ 5] < 0 ? 0 : a[ 5];
        
        applyInsideCroppBox = YES;
        
        switch( stackOrientation)
        {
            case 0:
                minClip = [NSValue valueWithPoint: NSMakePoint( floor(a[ 2]), floor( a[ 4]))];
                maxClip = [NSValue valueWithPoint: NSMakePoint( ceil(a[ 3]), ceil( a[ 5]))];
                zClip = NSMakePoint( floor( a[ 0]), ceil( a[ 1]));
                break;
                
            case 1:
                minClip = [NSValue valueWithPoint: NSMakePoint( floor(a[ 0]), floor( a[ 4]))];
                maxClip = [NSValue valueWithPoint: NSMakePoint( ceil(a[ 1]), ceil( a[ 5]))];
                zClip = NSMakePoint( floor( a[ 2]), ceil( a[ 3]));
                break;
                
            case 2:
                minClip = [NSValue valueWithPoint: NSMakePoint( floor(a[ 0]), floor( a[ 2]))];
                maxClip = [NSValue valueWithPoint: NSMakePoint( ceil(a[ 1]), ceil( a[ 3]))];
                zClip = NSMakePoint( floor( a[ 4]), ceil( a[ 5]));
                break;
        }
    }
    
    for( tt = 0; tt < roiPts->GetNumberOfPoints(); tt++)
    {
        float	point1[ 3], point2[ 3];
        long	x;
        
        double	point2D[ 3], *pp;
        
        roiPts->GetPoint( tt, point2D);
        aRenderer->SetDisplayPoint( point2D[ 0], point2D[ 1], 0);
        aRenderer->DisplayToWorld();
        pp = aRenderer->GetWorldPoint();
        
        if( blendedSeries)
        {
            pp[ 0] /= blendingFactor;
            pp[ 1] /= blendingFactor;
            pp[ 2] /= blendingFactor;
        }
        else
        {
            pp[ 0] /= factor;
            pp[ 1] /= factor;
            pp[ 2] /= factor;
        }
        
        if( aCamera->GetParallelProjection())
        {
            aCamera->GetPosition( xyz);
            
            xyz[ 0] = pp[0] + cameraProj[ 0];
            xyz[ 1] = pp[1] + cameraProj[ 1];
            xyz[ 2] = pp[2] + cameraProj[ 2];
            
            // Go beyond the object...
            
            pp[0] = xyz[ 0] + (pp[0] - xyz[ 0]) * 5000.;
            pp[1] = xyz[ 1] + (pp[1] - xyz[ 1]) * 5000.;
            pp[2] = xyz[ 2] + (pp[2] - xyz[ 2]) * 5000.;
            
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
            
            point2[0] = xyz[ 0] + (pp[0] - xyz[ 0])*5000.;
            point2[1] = xyz[ 1] + (pp[1] - xyz[ 1])*5000.;
            point2[2] = xyz[ 2] + (pp[2] - xyz[ 2])*5000.;
        }
        
        // Intersection between this line and planes in Z direction
        for( x = 0; x < stackMax; x++)
        {
            float	planeVector[ 3];
            float	point[ 3];
            float	resultPt[ 3];
            double	vPos[ 3];
            
            if( blendedSeries)  blendingVolume->GetPosition( vPos);
            else volume->GetPosition( vPos);
            
            // factor
            
            if( blendedSeries)
            {
                vPos[ 0] /= blendingFactor;
                vPos[ 1] /= blendingFactor;
                vPos[ 2] /= blendingFactor;
            }
            else
            {
                vPos[ 0] /= factor;
                vPos[ 1] /= factor;
                vPos[ 2] /= factor;
            }
            
            switch( stackOrientation)
            {
                case 0:
                    point[ 0] = x * [fObject pixelSpacingX];
                    point[ 1] = 0;
                    point[ 2] = 0;
                    
                    planeVector[ 0] =  vector[ 0];
                    planeVector[ 1] =  vector[ 1];
                    planeVector[ 2] =  vector[ 2];
                    break;
                    
                case 1:
                    point[ 0] = 0;
                    point[ 1] = x * [fObject pixelSpacingY];
                    point[ 2] = 0;
                    
                    planeVector[ 0] =  vector[ 3];
                    planeVector[ 1] =  vector[ 4];
                    planeVector[ 2] =  vector[ 5];
                    break;
                    
                case 2:
                    point[ 0] = 0;
                    point[ 1] = 0;
                    //		point[ 2] = x * fabs( [fObject sliceInterval]);
                    point[ 2] = x * ( [fObject sliceInterval]);
                    
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
                
                tempPoint3D[0] /= [fObject pixelSpacingX];
                tempPoint3D[1] /= [fObject pixelSpacingY];
                tempPoint3D[2] /= ( [fObject sliceInterval]);
                
                ptInt[ 0] = (long) (tempPoint3D[0] + 0.5);
                ptInt[ 1] = (long) (tempPoint3D[1] + 0.5);
                ptInt[ 2] = (long) (tempPoint3D[2] + 0.5);
                
                if( needToFlip)
                    ptInt[ 2] = [pxList count] - ptInt[ 2] -1;
                
                switch( stackOrientation)
                {
                    case 0:
                        roiID = ptInt[0];
                        
                        if( roiID >= zClip.x && roiID < zClip.y)
                            [[[ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[1], ptInt[2])]];
                        break;
                        
                    case 1:
                        roiID = ptInt[1];
                        
                        if( roiID >= zClip.x && roiID < zClip.y)
                            [[[ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[2])]];
                        break;
                        
                    case 2:
                        roiID = ptInt[2];
                        
                        if( roiID >= zClip.x && roiID < zClip.y)
                            [[[ROIList objectAtIndex: roiID] points] addObject: [MyPoint point: NSMakePoint(ptInt[0], ptInt[1])]];
                        break;
                }
            }
        }
    }
    
    Transform->Delete();
    
    BOOL	addition = NO;
    float	newVal = 0;
    
    if( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
    {
        if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
        {
            addition = YES;
            gDataValuesChanged = YES;
            
            newVal = 1024;
        }
        
        if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
        {
            addition = YES;
            gDataValuesChanged = YES;
            
            newVal = -1024;
        }
    }
    
    if( c == NSTabCharacter)
    {
        gDataValuesChanged = YES;
    }
    
    int savedMovieFrame = [controller curMovieIndex];
    
    [self display];
    
    dontRenderVolumeRenderingOsiriX = 1;
    aRenderer->SetDraw( 0);
    
    for ( int m = 0; m < [[controller viewer2D] maxMovieIndex] ; m++)
    {
        [controller setMovieFrame: m];
        
        [[[controller curPixList] objectAtIndex: 0] prepareRestore];
        
        
        
        NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
        
        for ( i = 0; i < stackMax; i++ )
        {
            VRViewOperation *op = [[[VRViewOperation alloc] initWithController: controller objects: [NSArray arrayWithObjects: [NSNumber numberWithInt:i], [NSNumber numberWithInt:stackOrientation], [NSNumber numberWithInt: c], [ROIList objectAtIndex: i], [NSNumber numberWithInt: blendedSeries], [NSNumber numberWithBool: addition], [NSNumber numberWithFloat: newVal], minClip, maxClip, nil]] autorelease];
            
            [queue addOperation: op];
        }
        
        [queue waitUntilAllOperationsAreFinished];
        
        
        
        [[[controller curPixList] objectAtIndex: 0] freeRestore];
    }
    
    // Update everything..
    ROIUPDATE = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList userInfo: [NSDictionary dictionaryWithObject: self forKey: @"sender"]];
    
    if( cropcallback)
        cropcallback->Execute(croppingBox, 0, nil);
    
    if( textureMapper || gDataValuesChanged)
    {
        [self computeValueFactor];
        // Force min/max recomputing
        [self movieChangeSource: data];
        
        gDataValuesChanged = NO;
    }
    else
    {
        if( isRGB == NO)
            [BrowserController multiThreadedImageConvert: @"FTo16U" :&srcf :&dst8 :-OFFSET16 :1./valueFactor];
    }
    
    if( clutOpacityView)
    {
        [clutOpacityView callComputeHistogram];
        [clutOpacityView updateView];
    }
    
    [self setNeedsDisplay:YES];
    
    dontRenderVolumeRenderingOsiriX = 0;
    aRenderer->SetDraw( 1);
    
    [controller setMovieFrame: savedMovieFrame];
    
    // Delete current ROI
    vtkPoints *pts = vtkPoints::New();
    vtkCellArray *rect = vtkCellArray::New();
    ROI3DData-> SetPoints( pts);		pts->Delete();
    ROI3DData-> SetLines( rect);		rect->Delete();
    [ROIPoints removeAllObjects];
    
    NSLog(@"Scissor End");
}

- (void) flyTo:(float) x :(float) y :(float) z
{
    double flyFrom[3], flyTo[3];
    double d[3], focalPt[3];
    int i, j;
    
    flyTo[0]=x; flyTo[1]=y; flyTo[2]=z;
    
    aRenderer->GetActiveCamera()->GetFocalPoint(flyFrom);
    
    for (i=0; i<3; i++)
    {
        d[i] = flyTo[i] - flyFrom[i];
    }
    
    
    double delta = [firstObject pixelSpacingX]*factor;
    
    double flyToFactor = 1/15.0f;
    
    for (j=0; j<3; j++)
    {
        focalPt[j] = flyFrom[j] + d[j]*delta*flyToFactor;
    }
    
    aRenderer->GetActiveCamera()->SetFocalPoint(focalPt);
    
    double distance = aCamera->GetDistance();
    aCamera->SetDistance( 10.*delta);
    aRenderer->GetActiveCamera()->Dolly( 0.15 + 1.0);
    aCamera->SetDistance( distance);
    aRenderer->GetActiveCamera()->OrthogonalizeViewUp();
    
    if( clipRangeActivated)
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    else
        aRenderer->ResetCameraClippingRange();
}

- (void) flyToVoxel:(OSIVoxel *)voxel{
    float pt2D[3];
    float pt3D[3];
    pt2D[0] = voxel.x;
    pt2D[1] = voxel.y;
    pt2D[2] = voxel.z;
    //DCMPix *slice = [pixList objectAtIndex:voxel.z];
    //[slice  convertPixX: voxel.x pixY: voxel.y toDICOMCoords: pt3D];
    [self convert2DPoint:(float *)pt2D to3DPoint:(float *)pt3D];
    [self flyTo:pt3D[0] :pt3D[1]  :pt3D[2]];
}

//Fly to 2D position on a slice;
- (void) flyToPoint:(NSPoint)point  slice:(int)slice{
    float pt2D[3];
    pt2D[0] = point.x;
    pt2D[1] = point.y;
    pt2D[2] = slice;
    float pt3D[3];
    [self convert2DPoint:(float *)pt2D to3DPoint:(float *)pt3D];
    [self flyTo:pt3D[0] :pt3D[1]  :pt3D[2]];
}

- (void) processFlyTo
{
    [self flyTo: flyToDestination[0]*factor :flyToDestination[1]*factor :flyToDestination[2]*factor];
    
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
    
    [self display];
    
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
}

- (void) keyUp:(NSEvent *)event
{
    if ([self eventToPlugins: event]) return;
    
    if( [[event characters] length] == 0) return;
    
    unichar c = [[event characters] characterAtIndex:0];
    
    if( c ==  'f')
    {
        flyto = NO;
        [self setNeedsDisplay: YES];
    }
}

- (void) keyDown:(NSEvent *)event
{
    if ([self eventToPlugins: event]) return;
    
    if( [[event characters] length] == 0) return;
    
    unichar c = [[event characters] characterAtIndex:0];
    
    if( c ==  'f')
    {
        if( aCamera->GetParallelProjection() == NO && flyto == NO)
        {
            NSPoint mousePoint = [self convertPoint: [[self window] mouseLocationOutsideOfEventStream] fromView: nil];
            long	pix[ 3];
            float	value;
            
            if( [self get3DPixelUnder2DPositionX:mousePoint.x Y:mousePoint.y pixel:pix position:flyToDestination value:&value])
            {
                flyto = YES;
            }
            else flyto = NO;
        }
    }
    else if( c == ' ')
    {
        if( [[[self window] windowController] isKindOfClass:[VRController class]])
            isRotating = !isRotating;
    }
    else if( c == '?')
    {
        NSDate	*now = [NSDate date];
        
        NSLog( @"360 degree rotation - 100 images - START");
        int i;
        
        for( i = 0 ; i < 100; i++)
        {
            [self Azimuth: 360. / 100.];
            [self display];
        }
        NSLog( @"360 degree rotation - 100 images - END");
        NSLog( @"360 degree rotation - Result in [s]: %f", -[now timeIntervalSinceNow]);
        
        [[AppController sharedAppController] growlTitle: NSLocalizedString( @"Performance Test", nil) description: [NSString stringWithFormat: NSLocalizedString(@"360 degree rotation - 100 images\rResult in [s] : %f", nil), -[now timeIntervalSinceNow]] name:@"result"];
    }
    else if( c == 27 && currentTool == t3DCut)
    {
        vtkPoints *pts = ROI3DData->GetPoints();
        
        if( bestRenderingWasGenerated)
        {
            bestRenderingWasGenerated = NO;
            [self display];
        }
        
        dontRenderVolumeRenderingOsiriX = 1;
        
        if( pts->GetNumberOfPoints() != 0)
        {
            // Delete current ROI
            vtkPoints *pts = vtkPoints::New();
            vtkCellArray *rect = vtkCellArray::New();
            ROI3DData-> SetPoints( pts); pts->Delete();
            ROI3DData-> SetLines( rect); rect->Delete();
            [ROIPoints removeAllObjects];
            
            [self display];
        }
        
        dontRenderVolumeRenderingOsiriX = 0;
    }
    else if( currentTool == tMesure || currentTool == tOval)
    {
        if( c == 27 || c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
        {
            if(currentTool == tMesure)
            {
                vtkPoints *pts = Line2DData->GetPoints();
                
                if( bestRenderingWasGenerated)
                {
                    bestRenderingWasGenerated = NO;
                    [self display];
                }
                dontRenderVolumeRenderingOsiriX = 1;
                
                if( pts->GetNumberOfPoints() != 0)
                {
                    // Delete current ROI
                    vtkPoints *pts = vtkPoints::New();
                    vtkCellArray *rect = vtkCellArray::New();
                    Line2DData-> SetPoints( pts); pts->Delete();
                    Line2DData-> SetLines( rect); rect->Delete();
                    
                    [self computeLength];
                    
                    [self display];
                }
                
                dontRenderVolumeRenderingOsiriX = 0;
            }
            else if( currentTool == tOval)
            {
                if( bestRenderingWasGenerated)
                {
                    bestRenderingWasGenerated = NO;
                    [self display];
                }
                dontRenderVolumeRenderingOsiriX = 1;
                
                // Delete current ROI
                aRenderer->RemoveActor( Oval2DText);
                aRenderer->RemoveActor2D( Oval2DActor);
                Oval2DRadius = 0;
                
                [self computeLength];
                [self display];
                
                dontRenderVolumeRenderingOsiriX = 0;
            }
        }
    }
    else if( (c == NSCarriageReturnCharacter || c == NSEnterCharacter || c == NSTabCharacter || c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey) && currentTool == t3DCut)
    {
        vtkPoints *roiPts = ROI3DData->GetPoints();
        
        if( roiPts->GetNumberOfPoints() < 3)
        {
            NSRunAlertPanel(NSLocalizedString(@"3D Cut", nil), NSLocalizedString(@"Draw an ROI on the 3D image and then press Return (include) or Delete (exclude) keys.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        }
        else if( c == NSTabCharacter && [[controller viewer2D] postprocessed] == YES)
        {
            NSRunAlertPanel(NSLocalizedString(@"Restore", nil), NSLocalizedString(@"This dataset has been post processed (reslicing, MPR, ...). You cannot restore it.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        }
        else
        {
            WaitRendering	*waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Applying Scissor...", nil)];
            [waiting showWindow:self];
            
            if( [deleteRegion tryLock])
            {
                [self deleteRegion: c :pixList :NO];
                
                [deleteRegion unlock];
            }
            
            //			if( blendingController)
            //			{
            //				[self deleteRegion: c :blendingPixList :YES];
            //			}
            
            [waiting close];
            [waiting autorelease];
        }
    }
    else if((c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey) && currentTool == t3Dpoint)
    {
        if([self isAny3DPointSelected])
        {
            [self removeSelected3DPoint];
        }
    }
    else if( c == 27)
    {
        [controller offFullScreen];
    }
    else if( [self actionForHotKey:[event characters]] == NO) [super keyDown:event];
    
}

//- (void) resetCroppingBox
//{
//	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAutoCropScissors"] == NO)
//	{
//		if( croppingBox)
//		{
//			croppingBox->SetProp3D( volume);
//			croppingBox->PlaceWidget();
//
//			double a[ 6];
//
//			[VRView getCroppingBox: a :volume :croppingBox];
//			[VRView setCroppingBox: a :volume];
//
//			[VRView getCroppingBox: a :blendingVolume :croppingBox];
//			[VRView setCroppingBox: a :blendingVolume];
//
//			[self setNeedsDisplay: YES];
//		}
//	}
//}


- (IBAction) undo:(id) sender
{
    [controller undo: sender];
}

- (ToolMode) currentTool
{
    return currentTool;
}

- (ToolMode) _tool
{
    return _tool;
}

- (void) setCurrentTool:(ToolMode) i
{
    ToolMode previousTool = currentTool;
    
    currentTool = i;
    
    if( currentTool != t3DRotate)
    {
        if( croppingBox)
            if( croppingBox->GetEnabled()) croppingBox->Off();
    }
    
    if( currentTool == tOval || previousTool == tOval)
    {
        if( bestRenderingWasGenerated)
        {
            bestRenderingWasGenerated = NO;
            [self display];
        }
        dontRenderVolumeRenderingOsiriX = 1;
        
        //		vtkPoints *pts = Oval2DData->GetPoints();
        //
        //		if( pts->GetNumberOfPoints() != 0)
        //		{
        //			// Delete current ROI
        //			vtkPoints *pts = vtkPoints::New();
        //			vtkCellArray *rect = vtkCellArray::New();
        //			Oval2DData-> SetPoints( pts);		pts->Delete();
        //			Oval2DData-> SetLines( rect);		rect->Delete();
        //			aRenderer->RemoveActor( Oval2DText);
        //			measureLength = 0;
        //
        //			[self display];
        //		}
        
        dontRenderVolumeRenderingOsiriX = 0;
    }
    
    if( currentTool == tMesure || previousTool == tMesure)
    {
        if( bestRenderingWasGenerated)
        {
            bestRenderingWasGenerated = NO;
            [self display];
        }
        dontRenderVolumeRenderingOsiriX = 1;
        
        vtkPoints *pts = Line2DData->GetPoints();
        
        if( pts->GetNumberOfPoints() != 0)
        {
            // Delete current ROI
            vtkPoints *pts = vtkPoints::New();
            vtkCellArray *rect = vtkCellArray::New();
            Line2DData-> SetPoints( pts);		pts->Delete();
            Line2DData-> SetLines( rect);		rect->Delete();
            aRenderer->RemoveActor( Line2DText);
            measureLength = 0;
            
            [self display];
        }
        
        dontRenderVolumeRenderingOsiriX = 0;
    }
    
    if( (currentTool == t3DCut && previousTool == t3DCut) || currentTool != t3DCut)
    {
        if( bestRenderingWasGenerated)
        {
            bestRenderingWasGenerated = NO;
            [self display];
        }
        dontRenderVolumeRenderingOsiriX = 1;
        vtkPoints		*roiPts = ROI3DData->GetPoints();
        
        if( roiPts->GetNumberOfPoints() != 0)
        {
            // Delete current ROI
            vtkPoints *pts = vtkPoints::New();
            vtkCellArray *rect = vtkCellArray::New();
            ROI3DData-> SetPoints( pts);		pts->Delete();
            ROI3DData-> SetLines( rect);		rect->Delete();
            [ROIPoints removeAllObjects];
            
            [self display];
        }
        
        dontRenderVolumeRenderingOsiriX = 0;
    }
    
    if(currentTool!=t3Dpoint && previousTool==t3Dpoint)
    {
        [self unselectAllActors];
        if ([point3DInfoPanel isVisible]) [point3DInfoPanel performClose:self];
        [self setNeedsDisplay:YES];
    }
    
    [self setCursorForView: currentTool];
}

- (void) getWLWW:(float*) iwl :(float*) iww
{
    *iwl = wl;
    *iww = ww;
}

-(void) getBlendingWLWW:(float*) iwl :(float*) iww
{
    *iwl = blendingWl;
    *iww = blendingWw;
}

-(void) setBlendingWLWW:(float) iwl :(float) iww
{
    if( blendingController == nil) return;
    
    if( fullDepthMode) return;
    
    blendingWl = iwl;
    blendingWw = iww;
    
    blendingOpacityTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &alpha);
    blendingColorTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &blendingtable);
    
    [self setNeedsDisplay:YES];
}

-(void) setBlendingFactor:(float) a
{
    long	i, blendMode;
    float   val, ii;
    
    if( fullDepthMode) return;
    
    if( blendingController)
    {
        if( volumeMapper) blendMode = volumeMapper->GetBlendMode();
        if( textureMapper) blendMode = textureMapper->GetBlendMode();
        
        blendingFactor = a;
        
        if( blendMode == vtkVolumeMapper::MAXIMUM_INTENSITY_BLEND)
        {
            a *= 2;
            
            for(i=0; i < 256; i++)
            {
                ii = i;
                val = (a * ii) / 256.;
                
                if( val > 255) val = 255;
                if( val < 0) val = 0;
                
                alpha[ i] = val / 255.0;
            }
        }
        else
        {
            a /= 3;
            
            for(i=0; i < 256; i++)
            {
                ii = i;
                val = (a * ii) / 256.;
                val -= 8.;
                
                if( val > 255) val = 255;
                if( val < 0) val = 0;
                
                alpha[ i] = val / 255.;
            }
        }
        blendingOpacityTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &alpha);
        
        [self setNeedsDisplay: YES];
    }
}

-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
    long	i;
    
    if( fullDepthMode) return;
    
    if( r == nil || g == nil || b == nil)
        return;
    
    if( blendingController)
    {
        if( r)
        {
            for( i = 0; i < 256; i++)
            {
                blendingtable[i][0] = r[i] / 255.;
                blendingtable[i][1] = g[i] / 255.;
                blendingtable[i][2] = b[i] / 255.;
            }
            blendingColorTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &blendingtable);
        }
        else
        {
            for( i = 0; i < 256; i++)
            {
                blendingtable[i][0] = i / 255.;
                blendingtable[i][1] = i / 255.;
                blendingtable[i][2] = i / 255.;
            }
            blendingColorTransferFunction->BuildFunctionFromTable( blendingValueFactor*(blendingOFFSET16 + blendingWl-blendingWw/2), blendingValueFactor*(blendingOFFSET16 + blendingWl+blendingWw/2), 255, (double*) &blendingtable);
        }
        
        [self setNeedsDisplay:YES];
    }
}

-(void) setOpacity:(NSArray*) array
{
    if( fullDepthMode) return;
    if( opacityTransferFunction == nil) return;
    
    long		i;
    NSPoint		pt;
    float		start, end;
    float		opacityAdapter = 1;
    
    if( renderingMode == 0) // VR
        opacityAdapter = superSampling;
    
    if( isRGB)
    {
        start = wl - ww/2;
        end = wl + ww/2;
    }
    else
    {
        start = valueFactor*(OFFSET16 + wl - ww/2);
        end = valueFactor*(OFFSET16 + wl + ww/2);
    }
    
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
    }
    else opacityTransferFunction->AddPoint(0 +start, 0);
    
    for( i = 0; i < [array count]; i++)
    {
        pt = NSPointFromString( [array objectAtIndex: i]);
        pt.x -= 1000;
        opacityTransferFunction->AddPoint(start + (pt.x / 256.0) * (end - start), pt.y / opacityAdapter);
    }
    
    if( [array count] == 0 || pt.x != 256)
        opacityTransferFunction->AddPoint(end, 1. / opacityAdapter);
    else
    {
        opacityTransferFunction->AddPoint(end, pt.y / opacityAdapter);
    }
    [self setNeedsDisplay:YES];
}

-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
    if( fullDepthMode) return;
    if( colorTransferFunction == nil) return;
    if( volumeProperty == nil) return;
    
    advancedCLUT = NO;
    if(appliedCurves)
    {
        [appliedCurves release];
        appliedCurves = nil;
    }
    
    int i;
    
    unsigned char rr[ 256], rg[ 256], rb[ 256];
    
    if( [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue])
    {
        if( r)
        {
            for( i = 0; i < 256; i++)
            {
                rr[ i] = 255-r[ i];
                rg[ i] = 255-g[ i];
                rb[ i] = 255-b[ i];
            }
            r = rr;
            g = rg;
            b = rb;
        }
    }
    
    if( isRGB)
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
            
            colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
        }
        else
        {
            if( [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue])
            {
                for( i = 0; i < 256; i++)
                {
                    table[255-i][0] = i / 255.;
                    table[255-i][1] = i / 255.;
                    table[255-i][2] = i / 255.;
                }
            }
            else
            {
                for( i = 0; i < 256; i++)
                {
                    table[i][0] = i / 255.;
                    table[i][1] = i / 255.;
                    table[i][2] = i / 255.;
                }
            }
            
            colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void) setWLWW:(float) iwl :(float) iww
{
    if( colorTransferFunction == nil)
        return;
    
    if( iwl == 0 && iww == 0)
    {
        iwl = [[pixList objectAtIndex:0] fullwl];
        
        if( [controller maximumValue])
        {
            iwl = [controller maximumValue] /2;
            iww = [controller maximumValue];
        }
        else
            iww = [[pixList objectAtIndex:0] fullww];
    }
    
    wl = iwl;
    ww = iww;
    
    if( fullDepthMode) return;
    
    if(advancedCLUT)
    {
        [clutOpacityView setWL:wl ww:ww];
        [clutOpacityView setCLUTtoVRView:YES];
    }
    else
        [self setOpacity: currentOpacityArray];
    
    if( isRGB)
        colorTransferFunction->BuildFunctionFromTable( wl-ww/2, wl+ww/2, 255, (double*) &table);
    else if(!advancedCLUT)
        colorTransferFunction->BuildFunctionFromTable( valueFactor*(OFFSET16 + wl-ww/2), valueFactor*(OFFSET16 + wl+ww/2), 255, (double*) &table);
    
    if( [[[controller viewer2D] modality] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[controller viewer2D] modality] isEqualToString:@"NM"]))
    {
        if( ww < 50) sprintf(WLWWString, "From: %0.4f   To: %0.4f ", wl-ww/2, wl+ww/2);
        else sprintf(WLWWString, "From: %0.f   To: %0.f ", wl-ww/2, wl+ww/2);
    }
    else
    {
        if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f ", wl, ww);
        else sprintf(WLWWString, "WL: %0.f WW: %0.f ", wl, ww);
    }
    textWLWW->SetInput( WLWWString);
    
    //	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontAutoCropScissors"] == NO)
    //		[self autoCroppingBox];
    
    [self setNeedsDisplay:YES];
}

- (void) endRenderImageWithBestQuality
{
    // Standard Rendering...
    
    if( volumeMapper)
    {
        volumeMapper->SetMinimumImageSampleDistance( LOD);
        volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
    }
    
    if( textureMapper)
    {
        textureMapper->SetMinimumImageSampleDistance( LOD);
        textureMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
    }
    
    if( blendingController)
    {
        if( blendingVolumeMapper)
        {
            blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
            blendingVolumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
        }
    }
    
    if( textX)
        aRenderer->AddActor(textX);
    
    [splash setCancel:NO];
    
    if( [splash aborted]) [self display];
}

- (void) renderImageWithBestQuality: (BOOL) best waitDialog: (BOOL) wait
{
    return [self renderImageWithBestQuality: best waitDialog: wait display: YES];
}

- (void) renderImageWithBestQuality: (BOOL) best waitDialog: (BOOL) wait display: (BOOL) display
{
    [splash setCancel:YES];
    
    // REMOVE CROPPING BOX
    
    if( croppingBox)
        if( croppingBox->GetEnabled()) croppingBox->Off();
    
    aRenderer->RemoveActor(outlineRect);
    if( textX)
        aRenderer->RemoveActor(textX);
    
    // RAY CASTING SETTINGS
    if( best)
    {
        if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask || projectionMode == 2)
        {
            if( volumeMapper)
            {
                volumeMapper->SetMinimumImageSampleDistance( 1.0);
                volumeMapper->SetSampleDistance( 1.0);
            }
            
            if( textureMapper)
            {
                textureMapper->SetMinimumImageSampleDistance( 0.8);
                textureMapper->SetSampleDistance( 0.8);
            }
            
            if( blendingController)
            {
                if( blendingVolumeMapper)
                {
                    blendingVolumeMapper->SetMinimumImageSampleDistance( 1.0);
                    blendingVolumeMapper->SetSampleDistance( 1.0);
                }
            }
            
            NSLog(@"resol = 1.0");
        }
        else
        {
            if( volumeMapper)
            {
                volumeMapper->SetMinimumImageSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
                volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
            }
            
            if( textureMapper)
            {
                textureMapper->SetMinimumImageSampleDistance( 1.0);
                textureMapper->SetSampleDistance( 1.0);
            }
            
            if( blendingController)
            {
                if( blendingVolumeMapper)
                {
                    blendingVolumeMapper->SetMinimumImageSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
                    blendingVolumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
                }
            }
        }
    }
    
    if( display)
    {
        if( wait == NO) noWaitDialog = YES;
        
        if( dontRenderVolumeRenderingOsiriX)
        {
            [self render];
        }
        else
        {
            [self display];
        }
        
        if( wait == NO) noWaitDialog = NO;
    }
    
    bestRenderingWasGenerated = YES;
}

-(void) bestRendering:(id) sender
{
    NSLog( @"start Best");
    [self renderImageWithBestQuality: YES waitDialog: YES];
    [self endRenderImageWithBestQuality];
    NSLog( @"end Best");
}

-(void) axView:(id) sender
{
    float distance = aCamera->GetDistance();
    float pp = aCamera->GetParallelScale();
    
    aCamera->SetFocalPoint (0, 0, 0);
    aCamera->SetPosition (0, 0, -1);
    aCamera->ComputeViewPlaneNormal();
    aCamera->SetViewUp(0, -1, 0);
    aCamera->OrthogonalizeViewUp();
    aRenderer->ResetCamera();
    
    // Apply the same zoom
    
    double vn[ 3], center[ 3];
    aCamera->GetFocalPoint(center);
    aCamera->GetViewPlaneNormal(vn);
    aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
    [self checkInVolume];
    aCamera->SetParallelScale( pp);
    
    
    if( clipRangeActivated)
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    else
        aRenderer->ResetCameraClippingRange();
    
    if( croppingBox)
        croppingBox->SetHandleSize( 0.005);
    
    [self setNeedsDisplay:YES];
}

-(void) saView:(id) sender
{
    float distance = aCamera->GetDistance();
    float pp = aCamera->GetParallelScale();
    
    //vtkCamera
    aCamera->SetFocalPoint (0, 0, 0);
    aCamera->SetPosition (1, 0, 0);
    aCamera->ComputeViewPlaneNormal();
    aCamera->SetViewUp(0, 0, 1);
    aCamera->OrthogonalizeViewUp();
    aCamera->Dolly(1.5);
    aRenderer->ResetCamera();
    
    // Apply the same zoom
    
    double vn[ 3], center[ 3];
    aCamera->GetFocalPoint(center);
    aCamera->GetViewPlaneNormal(vn);
    aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
    [self checkInVolume];
    aCamera->SetParallelScale( pp);
    
    if( clipRangeActivated)
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    else
        aRenderer->ResetCameraClippingRange();
    
    if( croppingBox)
        croppingBox->SetHandleSize( 0.005);
    
    [self setNeedsDisplay:YES];
}

-(void) saViewOpposite:(id) sender
{
    float distance = aCamera->GetDistance();
    float pp = aCamera->GetParallelScale();
    
    aCamera->SetFocalPoint (0, 0, 0);
    aCamera->SetPosition (-1, 0, 0);
    aCamera->ComputeViewPlaneNormal();
    aCamera->SetViewUp(0, 0, 1);
    aCamera->OrthogonalizeViewUp();
    aCamera->Dolly(1.5);
    aRenderer->ResetCamera();
    
    // Apply the same zoom
    
    double vn[ 3], center[ 3];
    aCamera->GetFocalPoint(center);
    aCamera->GetViewPlaneNormal(vn);
    aCamera->SetPosition(center[0]+distance*vn[0], center[1]+distance*vn[1], center[2]+distance*vn[2]);
    [self checkInVolume];
    aCamera->SetParallelScale( pp);
    
    if( clipRangeActivated)
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    else
        aRenderer->ResetCameraClippingRange();
    
    if( croppingBox)
        croppingBox->SetHandleSize( 0.005);
    
    [self setNeedsDisplay:YES];
}

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
    [self checkInVolume];
    aCamera->SetParallelScale( pp);
    
    if( clipRangeActivated)
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    else
        aRenderer->ResetCameraClippingRange();
    
    if( croppingBox)
        croppingBox->SetHandleSize( 0.005);
    
    [self setNeedsDisplay:YES];
}

- (float) LOD
{
    return LOD;
}

-(void) setLOD: (float) f
{
    [self willChangeValueForKey: @"lodDisplayed"];
    lodDisplayed = f;
    [self didChangeValueForKey: @"lodDisplayed"];
    
    LOD = f;
    
    if( textureMapper)
    {
        textureMapper->SetAutoAdjustSampleDistances( 1);
        textureMapper->SetMinimumImageSampleDistance( LOD);
        textureMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
        textureMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
    }
    
    if( blendingTextureMapper)
    {
        blendingTextureMapper->SetAutoAdjustSampleDistances( 1);
        blendingTextureMapper->SetMinimumImageSampleDistance( LOD);
        blendingTextureMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
        blendingTextureMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
    }
    
    if( engine == 0)
    {
        if( [[controller style] isEqualToString: @"noNib"])
        {
            if( LOD < 1.0)
                LOD = 1.0;
        }
        else
        {
            if( LOD < 1.3)
                LOD = 1.3;
        }
    }
    
    if( volumeMapper)
    {
        volumeMapper->SetAutoAdjustSampleDistances( 1);
        volumeMapper->SetMinimumImageSampleDistance( LOD);
        volumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
        volumeMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
    }
    
    if( blendingVolumeMapper)
    {
        blendingVolumeMapper->SetAutoAdjustSampleDistances( 1);
        blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
        blendingVolumeMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
        blendingVolumeMapper->SetMaximumImageSampleDistance( LOD*lowResLODFactor);
    }
    
    [self setNeedsDisplay:YES];
}

- (void) setLODLow:(BOOL) l
{
    if( volumeMapper)
    {
        if( l)
            volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
        else
            volumeMapper->SetMinimumImageSampleDistance( LOD);
    }
    
    if( blendingVolumeMapper)
    {
        if( l) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
        else blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
    }
    
    [self setNeedsDisplay: YES];
    
}

-(void) setBlendingPixSource:(ViewerController*) bC
{
    blendingController = bC;
    
    if( blendingController)
    {
        blendingPixList = [bC pixList];
        [blendingPixList retain];
        
        blendingData = [bC volumePtr];
        
        blendingFirstObject = [blendingPixList objectAtIndex:0];
        
        float blendingSliceThickness = [blendingFirstObject sliceInterval];
        
        if( blendingSliceThickness == 0)
        {
            NSLog(@"Blending slice interval = slice thickness!");
            blendingSliceThickness = [blendingFirstObject sliceThickness];
        }
        // PLAN
        [blendingFirstObject orientation:blendingcosines];
        
        isBlendingRGB = NO;
        if( [blendingFirstObject isRGB])
        {
            isBlendingRGB = YES;
        }
        else
        {
            // Convert float to short !!!
            blendingSrcf.height = [blendingFirstObject pheight] * [blendingPixList count];
            blendingSrcf.width = [blendingFirstObject pwidth];
            blendingSrcf.rowBytes = [blendingFirstObject pwidth] * sizeof(float);
            
            blendingDst8.height = [blendingFirstObject pheight] * [blendingPixList count];
            blendingDst8.width = [blendingFirstObject pwidth];
            blendingDst8.rowBytes = [blendingFirstObject pwidth] * sizeof(short);
            
            blendingData8 = (char*) malloc( blendingDst8.height * blendingDst8.width * sizeof(short));
            if( blendingData8 == nil)
            {
                [blendingPixList release];
                blendingController = nil;
                return;
            }
            
            blendingDst8.data = blendingData8;
            blendingSrcf.data = blendingData;
            
            if( [blendingFirstObject SUVConverted])
            {
                blendingValueFactor = MAXDYNAMICVALUE / [controller blendingMaximumValue];
                blendingOFFSET16 = 0;
                
                [BrowserController multiThreadedImageConvert: @"FTo16U" :&blendingSrcf :&blendingDst8 :-blendingOFFSET16 :1./blendingValueFactor];
                //				vImageConvert_FTo16U( &blendingSrcf, &blendingDst8, -blendingOFFSET16, 1./blendingValueFactor, 0);
            }
            else
            {
                if( [controller blendingMaximumValue] - [controller blendingMinimumValue] > MAXDYNAMICVALUE ||  [controller blendingMaximumValue] - [controller blendingMinimumValue] < 50)
                {
                    blendingValueFactor = MAXDYNAMICVALUE / ( [controller blendingMaximumValue] - [controller blendingMinimumValue]);
                    blendingOFFSET16 = -[controller blendingMinimumValue];
                    
                    [BrowserController multiThreadedImageConvert: @"FTo16U" :&blendingSrcf :&blendingDst8 :-blendingOFFSET16 :1./blendingValueFactor];
                    //					vImageConvert_FTo16U( &blendingSrcf, &blendingDst8, -blendingOFFSET16, 1./blendingValueFactor, 0);
                }
                else
                {
                    blendingValueFactor = 1;
                    blendingOFFSET16 = -[controller blendingMinimumValue];
                    [BrowserController multiThreadedImageConvert: @"FTo16U" :&blendingSrcf :&blendingDst8 :-blendingOFFSET16 :1./blendingValueFactor];
                    //					vImageConvert_FTo16U( &blendingSrcf, &blendingDst8, -blendingOFFSET16, 1./blendingValueFactor, 0);
                }
            }
        }
        
        blendingWl = [blendingFirstObject wl];
        blendingWw = [blendingFirstObject ww];
        
        blendingReader = vtkImageImport::New();
        blendingReader->SetWholeExtent(0, [blendingFirstObject pwidth]-1, 0, [blendingFirstObject pheight]-1, 1, [blendingPixList count]-2);
        blendingReader->SetDataExtentToWholeExtent();
        
        if( isBlendingRGB)
        {
            blendingReader->SetDataScalarTypeToUnsignedChar();
            blendingReader->SetNumberOfScalarComponents( 4);
            blendingReader->SetImportVoidPointer( blendingData );					//AVOID VTK BUG
        }
        else
        {
            blendingReader->SetNumberOfScalarComponents( 1);
            blendingReader->SetDataScalarTypeToUnsignedShort();
            blendingReader->SetImportVoidPointer( blendingData8 );					//AVOID VTK BUG
        }
        
        blendingReader->Update();
        
        blendingNeedToFlip = NO;
        if( blendingSliceThickness < 0 )
        {
            NSLog(@"ERROR : NEED TO FLIP....");
        }
        
        blendingReader->SetDataSpacing( factor*[blendingFirstObject pixelSpacingX], factor*[blendingFirstObject pixelSpacingY], factor*blendingSliceThickness);
        
        blendingColorTransferFunction = vtkColorTransferFunction::New();
        
        
        blendingOpacityTransferFunction = vtkPiecewiseFunction::New();
        [self setBlendingFactor:blendingFactor];
        
        blendingVolumeProperty = vtkVolumeProperty::New();
        
        if( isBlendingRGB)
        {
            blendingVolumeProperty->IndependentComponentsOn();
            
            blendingVolumeProperty->SetColor( 1,red);
            blendingVolumeProperty->SetColor( 2,green);
            blendingVolumeProperty->SetColor( 3,blue);
            
            blendingVolumeProperty->SetScalarOpacity( 1, blendingOpacityTransferFunction);
            blendingVolumeProperty->SetScalarOpacity( 2, blendingOpacityTransferFunction);
            blendingVolumeProperty->SetScalarOpacity( 3, blendingOpacityTransferFunction);
            
            blendingVolumeProperty->SetComponentWeight( 0, 0);
            
        }
        else
        {
            blendingVolumeProperty->SetColor( blendingColorTransferFunction);
            blendingVolumeProperty->SetScalarOpacity( blendingOpacityTransferFunction);
        }
        
        [self setBlendingCLUT:nil :nil :nil];
        
        blendingVolumeProperty->SetInterpolationTypeToLinear();
        
        blendingCompositeFunction = vtkVolumeRayCastCompositeFunction::New();
        
        blendingVolume = vtkVolume::New();
        blendingVolume->SetProperty( blendingVolumeProperty);
        
        [self setBlendingEngine: self.engine];
        
        vtkMatrix4x4	*matrice = vtkMatrix4x4::New();
        matrice->Element[0][0] = blendingcosines[0];			matrice->Element[1][0] = blendingcosines[1];			matrice->Element[2][0] = blendingcosines[2];			matrice->Element[3][0] = 0;
        matrice->Element[0][1] = blendingcosines[3];			matrice->Element[1][1] = blendingcosines[4];			matrice->Element[2][1] = blendingcosines[5];			matrice->Element[3][1] = 0;
        matrice->Element[0][2] = blendingcosines[6];			matrice->Element[1][2] = blendingcosines[7];			matrice->Element[2][2] = blendingcosines[8];			matrice->Element[3][2] = 0;
        matrice->Element[0][3] = 0;								matrice->Element[1][3] = 0;								matrice->Element[2][3] = 0;								matrice->Element[3][3] = 1;
        
        blendingVolume->SetPosition(	factor*[blendingFirstObject originX] * (matrice->Element[0][0]) + factor*[blendingFirstObject originY] * (matrice->Element[1][0]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][0]),
                                    factor*[blendingFirstObject originX] * (matrice->Element[0][1]) + factor*[blendingFirstObject originY] * (matrice->Element[1][1]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][1]),
                                    factor*[blendingFirstObject originX] * (matrice->Element[0][2]) + factor*[blendingFirstObject originY] * (matrice->Element[1][2]) + factor*[blendingFirstObject originZ]*(matrice->Element[2][2]));
        blendingVolume->SetUserMatrix( matrice);
        matrice->Delete();
        
        if( cropcallback)
            cropcallback->setBlendingVolume( blendingVolume);
        
        aRenderer->AddVolume( blendingVolume);
    }
    else
    {
        if( blendingVolume)
        {
            aRenderer->RemoveVolume( blendingVolume);
            
            blendingVolume->Delete();
            blendingVolume = nil;
            
            if( blendingVolumeMapper) blendingVolumeMapper->Delete();
            if( blendingTextureMapper) blendingTextureMapper->Delete();
            
            blendingVolumeMapper = nil;
            blendingTextureMapper = nil;
            
            blendingOpacityTransferFunction->Delete();
            blendingCompositeFunction->Delete();
            blendingVolumeProperty->Delete();
            blendingColorTransferFunction->Delete();
            blendingReader->Delete();
            
            if(blendingData8) free(blendingData8);
            blendingData8 = nil;
            
            [blendingPixList release];
            blendingPixList = nil;
        }
    }
}

-(void) movieBlendingChangeSource:(long) index
{
    if( blendingController)
    {
        [blendingPixList release];
        blendingPixList = [blendingController pixList: index];
        [blendingPixList retain];
        
        blendingData = [blendingController volumePtr: index];
        
        blendingReader->SetImportVoidPointer( blendingData);	//AVOID VTK BUG
        blendingReader->Update();
        
        // Force min/max recomputing
        if( blendingVolumeMapper) blendingVolumeMapper->Delete();
        blendingVolumeMapper = vtkHorosFixedPointVolumeRayCastMapper::New();
        blendingVolumeMapper->SetInputConnection(blendingReader->GetOutputPort());
        blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
        blendingVolumeMapper->Update();
        blendingVolume->SetMapper( blendingVolumeMapper);
        
        [self setNeedsDisplay:YES];
    }
}

-(void) movieChangeSource:(float*) volumeData showWait :(BOOL) showWait
{
    WaitRendering	*www;
    
    if( showWait)
    {
        www = [[WaitRendering alloc] init: NSLocalizedString( @"Preparing 3D data...", nil)];
        [www start];
        
        if( engine == 1)
        {
            unsigned long memory = [VTKView VRAMSizeForDisplayID: [[[[NSScreen mainScreen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]] * 1024 * 1024;
            if( 0.9 * memory < dst8.rowBytes * dst8.height)
            {
                [[AppController sharedAppController] growlTitle: NSLocalizedString( @"Warning!", nil) description: NSLocalizedString( @"3D Dataset volume is larger than the amount of graphic board VRAM: GPU Rendering could be slower than CPU Rendering.", nil)  name: @"result"];
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideVRAMAlert"] == NO)
                {
                    NSAlert* alert = [[NSAlert new] autorelease];
                    [alert setMessageText: NSLocalizedString( @"Warning!", nil)];
                    [alert setInformativeText: NSLocalizedString( @"3D Dataset volume is larger than the amount of graphic board VRAM: GPU Rendering could be slower than CPU Rendering.", nil)];
                    [alert setShowsSuppressionButton:YES ];
                    [alert addButtonWithTitle: NSLocalizedString( @"Continue", nil)];
                    [alert runModal];
                    if ([[alert suppressionButton] state] == NSOnState)
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"hideVRAMAlert"];
                }
            }
        }
    }
    
    @try
    {
        data = volumeData;
        
        if( isRGB)
        {
            reader->SetImportVoidPointer( data);
            reader->GetOutput()->Modified();
        }
        else
        {
            srcf.data = data;
            //			vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
            [BrowserController multiThreadedImageConvert: @"FTo16U" :&srcf :&dst8 :-OFFSET16 :1./valueFactor];
            
            reader->SetImportVoidPointer( data8);
            reader->GetOutput()->Modified();
        }
        reader->Update();
        if( volumeMapper)
        {
            volumeMapper->Delete();
            volumeMapper = nil;
            
            [self instantiateEngine: 0];
        }
        
        if( textureMapper)
        {
            textureMapper->ReleaseGraphicsResources( aRenderer->GetRenderWindow());
            textureMapper->Delete();
            textureMapper = nil;
            
            [self instantiateEngine: 1];
        }
        
        if( engine == 0)
            volume->SetMapper( volumeMapper);
        
        if( engine == 1)
            volume->SetMapper( textureMapper);
        
        if( blendingController)
        {
            if( blendingData != [blendingController volumePtr])
            {
                blendingData = [blendingController volumePtr];
                
                if( isRGB)
                {
                    blendingReader->SetImportVoidPointer( blendingData);
                    blendingReader->GetOutput()->Modified();
                }
                else
                {
                    blendingSrcf.data = blendingData;
                    //vImageConvert_FTo16U( &blendingSrcf, &blendingDst8, -blendingOFFSET16, 1./blendingValueFactor, 0);
                    [BrowserController multiThreadedImageConvert: @"FTo16U" :&blendingSrcf :&blendingDst8 :-blendingOFFSET16 :1./blendingValueFactor];
                    
                    blendingReader->SetImportVoidPointer( blendingData8);
                    blendingReader->GetOutput()->Modified();
                }
                
                blendingReader->Update();
                if( blendingVolumeMapper) blendingVolumeMapper->Delete();
                blendingVolumeMapper = nil;
                if( blendingTextureMapper)
                {
                    blendingTextureMapper->ReleaseGraphicsResources( aRenderer->GetRenderWindow());
                    blendingTextureMapper->Delete();
                }
                blendingTextureMapper = nil;
                
                [self setBlendingEngine: self.engine showWait: NO];
            }
        }
    }
    @catch (NSException *e)
    {
        NSLog( @"movieChangeSource exception: %@", e);
    }
    
    if( showWait)
    {
        [www end];
        [www close];
        [www autorelease];
    }
}

-(void) movieChangeSource:(float*) volumeData
{
    [self movieChangeSource: volumeData showWait:YES];
}

- (void) ViewFrameDidChangeNotification:(NSNotification*) note
{
    if( textWLWW)
    {
        int *wsize = [self renderWindow]->GetSize();
        textWLWW->GetPositionCoordinate()->SetValue( 2., wsize[ 1]-15);
    }
}

- (void) computeValueFactor
{
    if( firstObject)
    {
        if( [firstObject SUVConverted])
        {
            valueFactor = MAXDYNAMICVALUE / [controller maximumValue];
            OFFSET16 = 0;
        }
        else
        {
            if([controller maximumValue] - [controller minimumValue] > MAXDYNAMICVALUE || [controller maximumValue] - [controller minimumValue] < 50)
            {
                valueFactor = MAXDYNAMICVALUE / ([controller maximumValue] - [controller minimumValue]);
                //				OFFSET16 = -[controller minimumValue];
            }
            else
            {
                valueFactor = 1;
                OFFSET16 = -[controller minimumValue];
            }
        }
    }
}

- (void) initAnnotatedCubeActor
{
    vtkAnnotatedCubeActor* cube = vtkAnnotatedCubeActor::New();
    cube->SetXPlusFaceText ( [NSLocalizedString( @"L", @"L: Left") UTF8String]);
    cube->SetXMinusFaceText( [NSLocalizedString( @"R", @"R: Right") UTF8String]);
    cube->SetYPlusFaceText ( [NSLocalizedString( @"P", @"P: Posterior") UTF8String]);
    cube->SetYMinusFaceText( [NSLocalizedString( @"A", @"A: Anterior") UTF8String]);
    cube->SetZPlusFaceText ( [NSLocalizedString( @"S", @"S: Superior") UTF8String]);
    cube->SetZMinusFaceText( [NSLocalizedString( @"I", @"I: Inferior") UTF8String]);
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
    
    cube->GetTextEdgesProperty()->SetColor(0.5, 0.5, 0.5);
    cube->SetTextEdgesVisibility( 1);
    cube->SetCubeVisibility( 1);
    cube->SetFaceTextVisibility( 1);
    
    vtkPropAssembly *assembly = vtkPropAssembly::New();
    assembly->AddPart ( cube);
    
    orientationWidget = vtkOrientationMarkerWidget::New();
    orientationWidget->SetOrientationMarker( assembly);
    
    orientationWidget->SetInteractor( [self getInteractor]);
    orientationWidget->SetViewport( 0.90, 0.90, 1, 1);
    orientationWidget->SetEnabled( 1 );
    orientationWidget->SetInteractive( 0);
    
    cube->Delete();
    assembly->Delete();
}

-(short) setPixSource:(NSMutableArray*)pix :(float*) volumeData
{
    short   error = 0;
    long	i;
    
    if( [[[self window] windowController] isKindOfClass:[VRController class]])
        [[self window] setAcceptsMouseMovedEvents: YES];
    
    [pix retain];
    pixList = pix;
    
    [self setProjectionMode: 1];
    
    data = volumeData;
    
    aRenderer = [self renderer];
    firstObject = [pixList objectAtIndex:0];
    float sliceThickness = [firstObject sliceInterval];
    
    if( sliceThickness == 0)
    {
        NSLog(@"slice interval = slice thickness!");
        sliceThickness = [firstObject sliceThickness];
    }
    
    //	NSLog(@"slice: %0.2f", sliceThickness);
    
    wl = [firstObject wl];
    ww = [firstObject ww];
    
    isRGB = NO;
    if( [firstObject isRGB])
        isRGB = YES;
    else
    {
        // Convert float to short !!!
        srcf.height = [firstObject pheight] * [pix count];
        srcf.width = [firstObject pwidth];
        srcf.rowBytes = [firstObject pwidth] * sizeof(float);
        
        dst8.height = [firstObject pheight] * [pix count];
        dst8.width = [firstObject pwidth];
        dst8.rowBytes = [firstObject pwidth] * sizeof(short);
        
        data8 = (char*) malloc( dst8.height * dst8.width * sizeof(short));
        if( data8 == nil) return -1;
        
        dst8.data = data8;
        srcf.data = data;
        
        NSLog( @"maxValueOfSeries = %f", [controller maximumValue]);
        NSLog( @"minValueOfSeries = %f", [controller minimumValue]);
        
        firstPixel = *(data+0+[firstObject pwidth]);
        secondPixel = *(data+1+[firstObject pwidth]);
        
        if( [[controller viewer2D] maxMovieIndex] > 1)
        {
            *(data+0+[firstObject pwidth]) = [controller minimumValue];		// To avoid the min/max saturation problem with 4D data...
            *(data+1+[firstObject pwidth]) = [controller maximumValue];		// To avoid the min/max saturation problem with 4D data...
        }
        
        [self computeValueFactor];
        //		vImageConvert_FTo16U( &srcf, &dst8, -OFFSET16, 1./valueFactor, 0);
        [BrowserController multiThreadedImageConvert: @"FTo16U" :&srcf :&dst8 :-OFFSET16 :1./valueFactor];
    }
    
    try
    {
        
        reader = vtkImageImport::New();
        
        if( isRGB)
        {
            reader->SetImportVoidPointer(data);
            reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 1, [pixList count]-2);	//AVOID VTK BUG
            reader->SetDataExtentToWholeExtent();
            reader->SetDataScalarTypeToUnsignedChar();
            reader->SetNumberOfScalarComponents( 4);
            
        }
        else
        {
            reader->SetImportVoidPointer(data8);
            reader->SetWholeExtent( 0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 1, [pixList count]-2);	//AVOID VTK BUG
            reader->SetDataExtentToWholeExtent();
            //	reader->SetDataScalarTypeToFloat();
            reader->SetDataScalarTypeToUnsignedShort();
            reader->SetNumberOfScalarComponents( 1);
            //	reader->SetImportVoidPointer(data);
            
        }
        
        reader->Update();
        [firstObject orientation:cosines];
        
        factor = 1.0;
        
        needToFlip = NO;
        if( sliceThickness < 0 )
        {
            sliceThickness = fabs( sliceThickness);
            NSLog(@"We should not be here....");
            needToFlip = YES;
            NSLog(@"Flip !!");
        }
        
        factor = superSampling / [firstObject pixelSpacingX];
        
        if( [firstObject pixelSpacingX] == 0 || [firstObject pixelSpacingY] == 0) reader->SetDataSpacing( 1, 1, sliceThickness);
        else reader->SetDataSpacing( factor*[firstObject pixelSpacingX], factor*[firstObject pixelSpacingY], factor * sliceThickness);
        
        opacityTransferFunction = vtkPiecewiseFunction::New();
        opacityTransferFunction->AddPoint(0, 0);
        
        float opacityAdapter = 1;
        
        if( renderingMode == 0) // VR
            opacityAdapter = superSampling;
        
        opacityTransferFunction->AddPoint(255., 1. / opacityAdapter);
        
        colorTransferFunction = vtkColorTransferFunction::New();
        
        if( [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue])
        {
            red = vtkColorTransferFunction::New();
            red->AddRGBPoint( 255, 1, 0, 0 );
            red->AddRGBPoint(   0, 0, 0, 0 );
            
            green = vtkColorTransferFunction::New();
            green->AddRGBPoint( 255, 0, 1, 0 );
            green->AddRGBPoint(   0, 0, 0, 0 );
            
            blue = vtkColorTransferFunction::New();
            blue->AddRGBPoint( 255, 0, 0, 1 );
            blue->AddRGBPoint(   0, 0, 0, 0 );
        }
        else
        {
            red = vtkColorTransferFunction::New();
            red->AddRGBPoint(   0, 0, 0, 0 );
            red->AddRGBPoint( 255, 1, 0, 0 );
            
            green = vtkColorTransferFunction::New();
            green->AddRGBPoint(   0, 0, 0, 0 );
            green->AddRGBPoint( 255, 0, 1, 0 );
            
            blue = vtkColorTransferFunction::New();
            blue->AddRGBPoint(   0, 0, 0, 0 );
            blue->AddRGBPoint( 255, 0, 0, 1 );
        }
        
        volumeProperty = vtkVolumeProperty::New();
        if( isRGB)
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
        
        
        [self setCLUT:nil :nil :nil];
        
        [self setShadingValues:0.15 :0.9 :0.3 :15];
        
        if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) volumeProperty->SetInterpolationTypeToNearest();
        else volumeProperty->SetInterpolationTypeToLinear();//SetInterpolationTypeToNearest();	//SetInterpolationTypeToLinear
        
        compositeFunction = vtkVolumeRayCastCompositeFunction::New();
        
        LOD = 2.0;
#if __ppc__
        LOD += 0.5;
#endif
        
        volume = vtkVolume::New();
        volume->SetProperty( volumeProperty);
        
        vtkMatrix4x4	*matrice = vtkMatrix4x4::New();
        matrice->Element[0][0] = cosines[0];		matrice->Element[1][0] = cosines[1];		matrice->Element[2][0] = cosines[2];		matrice->Element[3][0] = 0;
        matrice->Element[0][1] = cosines[3];		matrice->Element[1][1] = cosines[4];		matrice->Element[2][1] = cosines[5];		matrice->Element[3][1] = 0;
        matrice->Element[0][2] = cosines[6];		matrice->Element[1][2] = cosines[7];		matrice->Element[2][2] = cosines[8];		matrice->Element[3][2] = 0;
        matrice->Element[0][3] = 0;					matrice->Element[1][3] = 0;					matrice->Element[2][3] = 0;					matrice->Element[3][3] = 1;
        
        volume->SetPosition(	factor*[firstObject originX] * matrice->Element[0][0] + factor*[firstObject originY] * matrice->Element[1][0] + factor*[firstObject originZ]*matrice->Element[2][0],
                            factor*[firstObject originX] * matrice->Element[0][1] + factor*[firstObject originY] * matrice->Element[1][1] + factor*[firstObject originZ]*matrice->Element[2][1],
                            factor*[firstObject originX] * matrice->Element[0][2] + factor*[firstObject originY] * matrice->Element[1][2] + factor*[firstObject originZ]*matrice->Element[2][2]);
        volume->SetUserMatrix( matrice);
        matrice->Delete();
        
        volume->PickableOff();
        
        outlineData = vtkOutlineFilter::New();
        outlineData->SetInputConnection(reader->GetOutputPort());
        outlineData->Update();
        
        mapOutline = vtkPolyDataMapper::New();
        mapOutline->SetInputConnection(outlineData->GetOutputPort());
        mapOutline->Update();
        
        outlineRect = vtkActor::New();
        outlineRect->SetMapper(mapOutline);
        outlineRect->GetProperty()->SetColor(0,1,0);
        outlineRect->GetProperty()->SetOpacity(0.5);
        outlineRect->SetUserMatrix( matrice);
        outlineRect->SetPosition(	factor*[firstObject originX] * matrice->Element[0][0] + factor*[firstObject originY] * matrice->Element[1][0] + factor*[firstObject originZ]*matrice->Element[2][0],
                                 factor*[firstObject originX] * matrice->Element[0][1] + factor*[firstObject originY] * matrice->Element[1][1] + factor*[firstObject originZ]*matrice->Element[2][1],
                                 factor*[firstObject originX] * matrice->Element[0][2] + factor*[firstObject originY] * matrice->Element[1][2] + factor*[firstObject originZ]*matrice->Element[2][2]);
        outlineRect->PickableOff();
        
        cropcallback = nil;
        croppingBox = nil;
        if( [[controller style] isEqualToString: @"noNib"] == NO)
        {
            croppingBox = vtkBoxWidget::New();
            
            croppingBox->GetHandleProperty()->SetColor(0, 1, 0);
            croppingBox->SetProp3D( volume);
            croppingBox->SetPlaceFactor( 1.0);
            croppingBox->SetHandleSize( 0.005);
            croppingBox->PlaceWidget();
            croppingBox->SetInteractor( [self getInteractor]);
            croppingBox->SetRotationEnabled( true);
            croppingBox->SetInsideOut( true);
            croppingBox->OutlineCursorWiresOff();
            
            croppingBox->SetDefaultRenderer( aRenderer);
            
            
            cropcallback = vtkMyCallbackVR::New();
            cropcallback->setBlendingVolume( nil);
            croppingBox->AddObserver(vtkCommand::InteractionEvent, cropcallback);
        }
        
        textWLWW = vtkTextActor::New();
        if( ww < 50) sprintf(WLWWString, "WL: %0.4f WW: %0.4f ", wl, ww);
        else sprintf(WLWWString, "WL: %0.f WW: %0.f ", wl, ww);
        textWLWW->SetInput( WLWWString);
        textWLWW->SetTextScaleModeToNone();												//vtkviewPort
        textWLWW->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
        int *wsize = [self renderWindow]->GetSize();
        textWLWW->GetPositionCoordinate()->SetValue( 2., wsize[ 1]-15);
        textWLWW->GetTextProperty()->SetShadow(true);
        textWLWW->GetTextProperty()->SetShadowOffset(1, 1);
        
        aRenderer->AddActor2D(textWLWW);
        
        if (isViewportResizable)
        {
            textX = vtkTextActor::New();
            textX->SetInput( "X ");
            textX->SetTextScaleModeToNone();
            textX->GetPositionCoordinate()->SetCoordinateSystemToViewport();
            textX->GetPositionCoordinate()->SetValue( 2., 2.);
            textX->GetTextProperty()->SetShadow(true);
            textX->GetTextProperty()->SetShadowOffset(1, 1);
            
            aRenderer->AddActor2D(textX);
        }
        
        for( i = 0; i < 5; i++)
        {
            oText[ i] = vtkTextActor::New();
            oText[ i]->SetInput( "X ");
            oText[ i]->SetTextScaleModeToNone();
            oText[ i]->GetPositionCoordinate()->SetCoordinateSystemToNormalizedViewport();
            oText[ i]->GetTextProperty()->SetBold( true);
            oText[ i]->GetTextProperty()->SetShadow(true);
            oText[ i]->GetTextProperty()->SetShadowOffset(1, 1);
            
            aRenderer->AddActor2D( oText[ i]);
        }
        oText[ 0]->GetPositionCoordinate()->SetValue( 0.01, 0.5);
        oText[ 1]->GetPositionCoordinate()->SetValue( 0.99, 0.5);
        oText[ 1]->GetTextProperty()->SetJustificationToRight();
        
        oText[ 2]->GetPositionCoordinate()->SetValue( 0.5, 0.03);
        oText[ 2]->GetTextProperty()->SetVerticalJustificationToTop();
        oText[ 3]->GetPositionCoordinate()->SetValue( 0.5, 0.97);
        
        oText[ 4]->GetPositionCoordinate()->SetValue( 0.99, 0.01);
        oText[ 4]->GetTextProperty()->SetBold( false);
        oText[ 4]->GetTextProperty()->SetJustificationToRight();
        
        aCamera = vtkCamera::New();
        aCamera->SetViewUp (0, 1, 0);
        aCamera->SetFocalPoint (0, 0, 0);
        aCamera->SetPosition (0, 0, 1);
        aCamera->SetRoll(180);
        aCamera->SetParallelProjection( true);
        
        aCamera->Dolly(1.5);
        
        aRenderer->AddVolume( volume);
        
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
        ROI3D->SetInputData( ROI3DData);
        
        ROI3DActor = vtkActor2D::New();
        ROI3DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
        ROI3DActor->SetMapper( ROI3D);
        ROI3DActor->GetProperty()->SetPointSize( 1);	//vtkProperty2D
        ROI3DActor->GetProperty()->SetLineWidth( 2);
        ROI3DActor->GetProperty()->SetColor(0.3,1,0);
        
        aRenderer->AddActor2D( ROI3DActor);
        
        // 2D Oval
        Oval2DData = vtkRegularPolygonSource::New();
        Oval2DData->SetNumberOfSides( 50);
        Oval2DData->SetRadius( 200);
        Oval2DData->SetCenter( 200, 200,0);
        Oval2DData->SetGeneratePolygon( 0);
        
        Oval2D = vtkPolyDataMapper2D::New();
        Oval2D->SetInputConnection( Oval2DData->GetOutputPort());
        Oval2D->Update();
        
        Oval2DActor = vtkActor2D::New();
        Oval2DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
        Oval2DActor->SetMapper( Oval2D);
        Oval2DActor->GetProperty()->SetPointSize( 6);	//vtkProperty2D
        Oval2DActor->GetProperty()->SetLineWidth( 2.5);
        Oval2DActor->GetProperty()->SetColor(1,1,0);
        
        Oval2DText = vtkTextActor::New();
        Oval2DText->SetInput( " ");
        Oval2DText->SetTextScaleModeToNone();
        Oval2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
        Oval2DText->GetPositionCoordinate()->SetValue( 2., 2.);
        Oval2DText->GetTextProperty()->SetColor( 1.0, 1.0, 0.0);
        Oval2DText->GetTextProperty()->SetBold( true);
        Oval2DText->GetTextProperty()->SetShadow(true);
        Oval2DText->GetTextProperty()->SetShadowOffset(1, 1);
        
        //		aRenderer->AddActor2D( Oval2DActor);
        
        // 2D Line
        pts = vtkPoints::New();
        rect = vtkCellArray::New();
        
        Line2DData = vtkPolyData::New();
        Line2DData-> SetPoints( pts);
        pts->Delete();
        Line2DData-> SetLines( rect);
        rect->Delete();
        
        Line2D = vtkPolyDataMapper2D::New();
        Line2D->SetInputData( Line2DData);
        
        Line2DActor = vtkActor2D::New();
        Line2DActor->GetPositionCoordinate()->SetCoordinateSystemToDisplay();
        Line2DActor->SetMapper( Line2D);
        Line2DActor->GetProperty()->SetPointSize( 6);	//vtkProperty2D
        Line2DActor->GetProperty()->SetLineWidth( 2.5);
        Line2DActor->GetProperty()->SetColor(1,1,0);
        
        Line2DText = vtkTextActor::New();
        Line2DText->SetInput( " ");
        Line2DText->SetTextScaleModeToNone();
        Line2DText->GetPositionCoordinate()->SetCoordinateSystemToViewport();
        Line2DText->GetPositionCoordinate()->SetValue( 2., 2.);
        Line2DText->GetTextProperty()->SetColor( 1.0, 1.0, 0.0);
        Line2DText->GetTextProperty()->SetBold( true);
        Line2DText->GetTextProperty()->SetShadow(true);
        Line2DText->GetTextProperty()->SetShadowOffset(1, 1);
        
        aRenderer->AddActor2D( Line2DActor);
        
        [self saView:self];
        
        GLint swap = 1;  // LIMIT SPEED TO VBL if swap == 1
        [self getVTKRenderWindow]->MakeCurrent();
        [[NSOpenGLContext currentContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
        
        [self setNeedsDisplay:YES];
        
        //		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"dontShow3DCubeOrientation"] == NO)
        [self initAnnotatedCubeActor];
        
        
        if( [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue])
            [self changeColorWith: [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1  alpha:1]];
    }
    
    catch (...)
    {
        NSLog( @"setPixSource VRView C++ exception");
        return -1;
    }
    
    
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

- (NSImage*) resizeMatrix:(NSImage*) currentImage size: (int) matrixsize
{
    NSRect sourceRect = NSMakeRect(0.0, 0.0, [currentImage size].width, [currentImage size].height);
    NSRect imageRect;
    
    if( [currentImage size].width > [currentImage size].height)
    {
        float ratio = [currentImage size].width / matrixsize;
        imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
        
        NSLog( @"ratio: %f", ratio);
    }
    else
    {
        float ratio = [currentImage size].height / matrixsize;
        imageRect = NSMakeRect(0.0, 0.0, (int) ([currentImage size].width/ratio), (int) ([currentImage size].height/ratio));
        
        NSLog( @"ratio: %f", ratio);
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [currentImage setScalesWhenResized:YES];
#pragma clang diagnostic pop

    NSImage *compositingImage = [[NSImage alloc] initWithSize: imageRect.size];
    if( [compositingImage size].width > 0 && [compositingImage size].height > 0)
    {
        [compositingImage lockFocus];
        [currentImage drawInRect: imageRect fromRect: sourceRect operation: NSCompositeCopy fraction: 1.0];
        [compositingImage unlockFocus];
    }
    
    return [compositingImage autorelease];
}

-(NSImage*) nsimageQuicktime
{
    NSImage *theIm;
    
    [self renderImageWithBestQuality: bestRenderingMode waitDialog: NO];
    
    theIm = [self nsimage:YES];
    
    [self endRenderImageWithBestQuality];
    
    return theIm;
}

-(NSImage*) nsimageQuicktime:(BOOL) renderingModec
{
    bestRenderingMode = renderingModec;
    return [self nsimageQuicktime];
}

- (void) prepareFullDepthCapture
{
    fullDepthEngineCopy = engine;
    
    if( engine != 0)
        self.engine = 0; // Switch to CPU !
    
    if( firstObject.isRGB)
        return;
    
    if( volumeMapper)
    {
        volumeMapper->SetIntermixIntersectingGeometry( 0);
        
        vtkPiecewiseFunction *tempOpacity = vtkPiecewiseFunction::New();
        
        float start = valueFactor*(OFFSET16 + [controller minimumValue]);
        float end = valueFactor*(OFFSET16 + [controller maximumValue]);
        
        tempOpacity->AddPoint(start, 0);
        tempOpacity->AddPoint(end, 1);
        
        volumeProperty->SetScalarOpacity( tempOpacity);
        volumeMapper->PerVolumeInitialization( aRenderer, volume);
        
        unsigned short *o = volumeMapper->GetScalarOpacityTable( 0);	// Fake the opacity table to have full '16-bit' image
        memcpy( o, [VRView linearOpacity], 32767 * sizeof( unsigned short));
        
        tempOpacity->Delete();
        
        fullDepthMode = 1;
    }
    
    if( blendingVolumeMapper)
    {
        blendingVolumeMapper->SetIntermixIntersectingGeometry( 0);
        
        vtkPiecewiseFunction *tempOpacity = vtkPiecewiseFunction::New();
        
        float start = blendingValueFactor*(blendingOFFSET16 + [controller blendingMinimumValue]);
        float end = blendingValueFactor*(blendingOFFSET16 + [controller blendingMaximumValue]);
        
        tempOpacity->AddPoint(start, 0);
        tempOpacity->AddPoint(end, 1);
        
        blendingVolumeProperty->SetScalarOpacity( tempOpacity);
        blendingVolumeMapper->PerVolumeInitialization( aRenderer, blendingVolume);
        
        unsigned short *o = blendingVolumeMapper->GetScalarOpacityTable( 0);	// Fake the opacity table to have full '16-bit' image
        memcpy( o, [VRView linearOpacity], 32767 * sizeof( unsigned short));
        
        tempOpacity->Delete();
    }
}

- (void) restoreFullDepthCapture
{
    if( volumeMapper)
    {
        volumeMapper->SetIntermixIntersectingGeometry( 1);
        
        volumeProperty->SetScalarOpacity( opacityTransferFunction);
        volumeMapper->PerVolumeInitialization( aRenderer, volume);
        
        fullDepthMode = 0;
    }
    
    if( blendingVolumeMapper)
    {
        blendingVolumeMapper->SetIntermixIntersectingGeometry( 1);
        
        blendingVolumeProperty->SetScalarOpacity( blendingOpacityTransferFunction);
        blendingVolumeMapper->PerVolumeInitialization( aRenderer, blendingVolume);
    }
    
    if( engine != fullDepthEngineCopy)
        self.engine = fullDepthEngineCopy; // Restore !
    
    minimumStep = 0;
    
    [self setNeedsDisplay: YES];
}

- (float*) imageInFullDepthWidth: (long*) w height:(long*) h isRGB:(BOOL*) rgb
{
    return [self imageInFullDepthWidth:  w height: h isRGB: rgb blendingView: NO];
}

- (float*) imageInFullDepthWidth: (long*) w height:(long*) h isRGB:(BOOL*) rgb blendingView:(BOOL) blendingView
{
    float *returnedPtr = nil;
    
    @try
    {
        
        vtkHorosFixedPointVolumeRayCastMapper *mapper = nil;
        DCMPix *firstObj = nil;
        
        if( blendingView)
        {
            firstObj = blendingFirstObject;
            mapper = blendingVolumeMapper;
        }
        else
        {
            firstObj = firstObject;
            mapper = volumeMapper;
        }
        
        if( mapper)
        {
            vtkFixedPointRayCastImage *rayCastImage = mapper->GetRayCastImage();
            
            unsigned short *im = rayCastImage->GetImage();
            
            int fullSize[2];
            rayCastImage->GetImageMemorySize( fullSize);
            
            int size[2];
            rayCastImage->GetImageInUseSize( size);
            
            *w = size[0];
            *h = size[1];
            
            if( firstObject.isRGB == NO && ( renderingMode == 1 || renderingMode == 3 || renderingMode == 2))		// MIP
            {
                unsigned short *destPtr, *destFixedPtr;
                
                destPtr = destFixedPtr = (unsigned short*) malloc( (*w+1) * (*h+1) * sizeof( unsigned short));
                if( destFixedPtr)
                {
                    unsigned short *iptr;
                    
                    iptr = im + 3 + 4*(*h-1)*fullSize[0];
                    vImage_Buffer src, dst;
                    
                    int j = *h, rowBytes = 4*fullSize[0];
                    while( j-- > 0)
                    {
                        unsigned short *iptrTemp = iptr;
                        int i = *w;
                        while( i-- > 0)
                        {
                            *destPtr++ = *iptrTemp;
                            iptrTemp += 4;
                        }
                        
                        iptr -= rowBytes;
                    }
                    
                    float mul;
                    float add;
                    
                    if( blendingView)
                    {
                        mul = 1./blendingValueFactor;
                        add = -blendingOFFSET16;
                        
                        if( blendingValueFactor != 1)
                            mul = mul;
                        else
                            mul = 1;
                    }
                    else
                    {
                        mul = 1./valueFactor;
                        add = -OFFSET16;
                        
                        if( valueFactor != 1)
                            mul = mul;
                        else
                            mul = 1;
                    }
                    
                    src.data = destFixedPtr;
                    src.height = *h;
                    src.width = *w;
                    src.rowBytes = *w * 2;
                    
                    dst.data = malloc( (*w+1) * (*h+1) * sizeof( float));
                    if( dst.data)
                    {
                        dst.height = *h;
                        dst.width = *w;
                        dst.rowBytes = *w * 4;
                        
                        vImageConvert_16UToF( &src, &dst, add, mul, 0);
                    }
                    
                    *rgb = NO;
                    
                    free( destFixedPtr);
                    
                    returnedPtr = (float*) dst.data;
                }
            }
            else
            {
                unsigned char *destPtr, *destFixedPtr;
                
                destPtr = destFixedPtr = (unsigned char*) malloc( (*w+1) * (*h+1) * 4 * sizeof( unsigned char));
                if( destFixedPtr)
                {
                    unsigned short *iptr = im + 3 + 4*(*h-1)*fullSize[0];
                    
                    int j = *h, rowBytes = 4*fullSize[0];
                    while( j-- > 0)
                    {
                        unsigned short *iptrTemp = iptr;
                        int i = *w;
                        while( i-- > 0)
                        {
                            *destPtr = 255;
                            destPtr++;
                            iptrTemp++;
                            
                            *destPtr++ = *iptrTemp++ >> 7;
                            *destPtr++ = *iptrTemp++ >> 7;
                            *destPtr++ = *iptrTemp++ >> 7;
                        }
                        
                        iptr -= rowBytes;
                    }
                    
                    *rgb = YES;
                    
                    returnedPtr = (float*) destFixedPtr;
                }
            }
        }
    }
    @catch (NSException * e)
    {
        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
    }
    
    return returnedPtr;
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
    return [self getRawPixels: width : height : spp : bpp : screenCapture : force8bits offset: nil isSigned: nil];
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits offset:(int*) offset isSigned:(BOOL*) isSigned
{
    unsigned char *buf = nil;
    
    [drawLock lock];
    
    BOOL fullDepthCapture = NO;
    
    @try
    {
        if( force8bits == NO)
            fullDepthCapture = YES;
        
        if( fullDepthCapture)
        {
            vImage_Buffer sf, d8;
            BOOL rgb;
            
            sf.data = [self imageInFullDepthWidth: width height:height isRGB: &rgb];
            
            if( sf.data)
            {
                if( rgb)
                {
                    *spp = 3;
                    *bpp = 8;
                    
                    buf = (unsigned char*) sf.data;
                    
                    int i = *width * *height;
                    unsigned char *t_argb = buf+1;
                    unsigned char *t_rgb = buf;
                    while( i-->0)
                    {
                        *((int*) t_rgb) = *((int*) t_argb);
                        t_argb+=4;
                        t_rgb+=3;
                    }
                }
                else
                {
                    *spp = 1;
                    *bpp = 16;
                    
                    sf.height = *height;
                    sf.width = *width;
                    sf.rowBytes = *width * sizeof( float);
                    
                    d8.height =  *height;
                    d8.width = *width;
                    d8.rowBytes = *width * sizeof( short);
                    
                    float slope = 1;
                    
                    if( [[[controller viewer2D] modality] isEqualToString:@"PT"])
                        slope = firstObject.appliedFactorPET2SUV * firstObject.slope;
                    
                    buf = (unsigned char*) malloc( *width * *height * *spp * *bpp / 8);
                    if( buf)
                    {
                        d8.data = buf;
                        
                        if( [controller minimumValue] < -1024)
                        {
                            if( isSigned) *isSigned = YES;
                            if( offset) *offset = 0;
                            
                            vImageConvert_FTo16S( &sf, &d8, 0, slope, 0);
                        }
                        else
                        {
                            if( isSigned) *isSigned = NO;
                            
                            if( [controller minimumValue] >= 0)
                            {
                                if( offset) *offset = 0;
                                vImageConvert_FTo16U( &sf, &d8, 0, slope, 0);
                            }
                            else
                            {
                                if( offset) *offset = -1024;
                                vImageConvert_FTo16U( &sf, &d8, -1024, slope, 0);
                            }
                        }
                    }
                    
                    free( sf.data);
                }
            }
        }
        else
        {
            int i;
            
            NSRect size = [self bounds];
            
            *width = (long) size.size.width;
            *width/=4;
            *width*=4;
            *height = (long) size.size.height;
            *spp = 3;
            *bpp = 8;
            
            [self getVTKRenderWindow]->MakeCurrent();
            
            buf = (unsigned char*) malloc( *width * *height * 4 * *bpp/8);
            if( buf)
            {
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
                    
                    if( tempBuf)
                    {
                        for( i = 0; i < *height/2; i++)
                        {
                            memcpy( tempBuf, buf + (*height - 1 - i)*rowBytes, rowBytes);
                            memcpy( buf + (*height - 1 - i)*rowBytes, buf + i*rowBytes, rowBytes);
                            memcpy( buf + i*rowBytes, tempBuf, rowBytes);
                        }
                        
                        free( tempBuf);
                    }
                }
                
                //Add the small OsiriX logo at the bottom right of the image
                NSImage	 *logo = [NSImage imageNamed:@"SmallLogo.tif"];
                NSBitmapImageRep *TIFFRep = [[NSBitmapImageRep alloc] initWithData: [logo TIFFRepresentation]];
                
                if( TIFFRep)
                {
                    for( i = 0; i < [TIFFRep pixelsHigh]; i++)
                    {
                        unsigned char	*srcPtr = ([TIFFRep bitmapData] + i*[TIFFRep bytesPerRow]);
                        unsigned char	*dstPtr = (buf + (*height - [TIFFRep pixelsHigh] + i)*rowBytes + 2*3);
                        
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
            }
            [NSOpenGLContext clearCurrentContext];
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [drawLock unlock];
    
    return buf;
}

-(NSImage*) nsimage:(BOOL) originalSize
{
    NSBitmapImageRep	*rep;
    long				width, height, spp, bpp;
    NSString			*colorSpace;
    unsigned char		*dataPtr;
    
    [self resetAutorotate: self];
    
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

-(void) switchOrientationWidget:(id) sender
{
    long i;
    
    if( orientationWidget)
    {
        if( orientationWidget->GetEnabled())
        {
            orientationWidget->Off();
            for( i = 0; i < 5; i++) aRenderer->RemoveActor2D( oText[ i]);
        }
        else
        {
            orientationWidget->On();
            for( i = 0; i < 5; i++) aRenderer->AddActor2D( oText[ i]);
        }
    }
    
    [self setNeedsDisplay:YES];
}

-(void) showCropCube:(id) sender
{
    if( croppingBox)
    {
        if( croppingBox->GetEnabled()) croppingBox->Off();
        else
        {
            croppingBox->On();
            
            [self setCurrentTool: t3DRotate];
            [[controller toolsMatrix] selectCellWithTag: t3DRotate];
            
            cropcallback->Execute(croppingBox, 0, nil);
        }
    }
}

-(IBAction) copy:(id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    
    NSImage *im;
    
    [pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeTIFF] owner:self];
    
    im = [self nsimage:NO];
    
    [pb setData: [im TIFFRepresentation] forType:NSPasteboardTypeTIFF];
}

- (void) updateScissorStateButtons
{
    NSString *str = [VRController getUniqueFilenameScissorStateFor: [firstObject imageObj]];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: str] == NO)
    {
        [[scissorStateMatrix cellWithTag: 1] setEnabled: NO];
        [[scissorStateMatrix cellWithTag: 2] setEnabled: NO];
    }
    else
    {
        [[scissorStateMatrix cellWithTag: 1] setEnabled: YES];
        [[scissorStateMatrix cellWithTag: 2] setEnabled: YES];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if( [menuItem action] == @selector( scissorStateButtons:))
    {
        if( menuItem.tag == 2) // Delete
        {
            NSString *str = [VRController getUniqueFilenameScissorStateFor: [firstObject imageObj]];
            
            if( [[NSFileManager defaultManager] fileExistsAtPath: str] == NO)
                return NO;
            else
                return YES;
        }
        else if( menuItem.tag == 1) // Load
        {
            NSString *str = [VRController getUniqueFilenameScissorStateFor: [firstObject imageObj]];
            
            if( [[NSFileManager defaultManager] fileExistsAtPath: str] == NO)
                return NO;
            else
                return YES;
        }
    }
    
    return YES;
}

-(IBAction) scissorStateButtons:(id) sender
{
    NSString		*str = [VRController getUniqueFilenameScissorStateFor: [firstObject imageObj]];
    NSData			*volumeData;
    long			volumeSize = [firstObject pheight] * [pixList count] * [firstObject pwidth] * sizeof(float);
    WaitRendering	*waiting = nil;
    
    int tag;
    
    if ([sender isKindOfClass:[NSMatrix class]])
        tag = [[sender selectedCell] tag];
    else
        tag = [sender tag];
    
    switch( tag)
    {
        case 2:
            if( NSRunAlertPanel(NSLocalizedString(@"3D Scissor State", nil), NSLocalizedString(@"Are you sure you want to delete this 3D state? You cannot undo this operation.", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
                [[NSFileManager defaultManager] removeItemAtPath: str error:NULL];
            break;
            
        case 1:	// Load
            waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Loading 3D object...", nil)];
            [waiting showWindow:self];
            
            if( [[NSFileManager defaultManager] fileExistsAtPath: str])
            {
                volumeData = [[NSData alloc] initWithContentsOfFile:str];
                
                if( volumeData)
                {
                    if( [volumeData length] == volumeSize)
                    {
                        memcpy( data, [volumeData bytes], volumeSize);
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateVolumeDataNotification object: pixList userInfo: 0];
                        
                        if( croppingBox)
                            cropcallback->Execute(croppingBox, 0, nil);
                    }
                    else NSRunAlertPanel(NSLocalizedString(@"3D Scissor State", nil), NSLocalizedString(@"No saved data are available.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                    
                    [volumeData release];
                }
                else NSRunAlertPanel(NSLocalizedString(@"3D Scissor State", nil), NSLocalizedString(@"No saved data are available.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            }
            else NSRunAlertPanel(NSLocalizedString(@"3D Scissor State", nil), NSLocalizedString(@"No saved data are available.", nil), NSLocalizedString(@"OK", nil), nil, nil);
            break;
            
        case 0:	// Save
            
            if( ([[NSFileManager defaultManager] fileExistsAtPath: str] && NSRunAlertPanel(NSLocalizedString(@"3D Scissor State", nil), NSLocalizedString(@"A 3D Scissor State already exists. Do you want to replace it with curent state?", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn) || [[NSFileManager defaultManager] fileExistsAtPath: str] == NO)
            {
                waiting = [[WaitRendering alloc] init:NSLocalizedString(@"Saving 3D object...", nil)];
                [waiting showWindow:self];
                volumeData = [NSData dataWithBytesNoCopy:data length:volumeSize freeWhenDone:NO];
                [volumeData writeToFile:str atomically:NO];
            }
            break;
    }
    
    [waiting close];
    [waiting autorelease];
    
    [self updateScissorStateButtons];
}

- (vtkRenderer*) vtkRenderer;
{
    return aRenderer;
}

- (vtkCamera*) vtkCamera;
{
    return aCamera;
}

- (void) setVtkCamera:(vtkCamera*)aVtkCamera;
{
    if( aCamera == nil)
        return;
    
    double pos[3], focal[3], vUp[3], parallelScale;
    aVtkCamera->GetPosition(pos);
    aVtkCamera->GetFocalPoint(focal);
    aVtkCamera->GetViewUp(vUp);
    parallelScale = aVtkCamera->GetParallelScale();
    
    double currentPos[3], currentFocal[3], currentVUp[3], currentParallelScale;
    aCamera->GetPosition(currentPos);
    aCamera->GetFocalPoint(currentFocal);
    aCamera->GetViewUp(currentVUp);
    currentParallelScale = aCamera->GetParallelScale();
    
    if(currentPos[0]==pos[0] && currentPos[1]==pos[1] && currentPos[2]==pos[2]
       && currentFocal[0]==focal[0] && currentFocal[1]==focal[1] && currentFocal[2]==focal[2]
       && currentVUp[0]==vUp[0] && currentVUp[1]==vUp[1] && currentVUp[2]==vUp[2]
       && currentParallelScale==parallelScale)
        return;
    
    double clippingRange[2];
    aVtkCamera->GetClippingRange(clippingRange);
    double viewAngle, eyeAngle;
    viewAngle = aVtkCamera->GetViewAngle();
    eyeAngle = aVtkCamera->GetEyeAngle();
    
    aCamera->SetPosition(pos);
    aCamera->SetFocalPoint(focal);
    aCamera->SetViewUp(vUp);
    aCamera->SetClippingRange(clippingRange);
    aCamera->SetViewAngle(viewAngle);
    aCamera->SetEyeAngle(eyeAngle);
    aCamera->SetParallelScale(parallelScale);
    
    aCamera->SetParallelProjection(aVtkCamera->GetParallelProjection());
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
    [self setNeedsDisplay:YES];
}

- (Camera*) cameraWithThumbnail:(BOOL) produceThumbnail
{
    // data extraction from the vtkCamera
    
    double pos[3], focal[3], vUp[3];
    double pWC[ 2];
    
    aCamera->GetWindowCenter( pWC);
    aCamera->GetPosition(pos);
    aCamera->GetFocalPoint(focal);
    aCamera->OrthogonalizeViewUp();
    aCamera->GetViewUp(vUp);
    double clippingRange[2];
    aCamera->GetClippingRange(clippingRange);
    double viewAngle, eyeAngle, parallelScale, rollAngle;
    viewAngle = aCamera->GetViewAngle();
    eyeAngle = aCamera->GetEyeAngle();
    rollAngle = aCamera->GetRoll();
    parallelScale = aCamera->GetParallelScale();
    
    // creation of the Camera
    Camera *cam = [[Camera alloc] init];
    Point3D *pt = [[[Point3D alloc] initWithValues:pos[0] :pos[1] :pos[2]] autorelease];
    
    cam.windowCenterX = pWC[ 0];
    cam.windowCenterY = pWC[ 1];
    
    if( volumeMapper)
        cam.LOD = volumeMapper->GetMinimumImageSampleDistance();
    
    [cam setPosition: pt];
    [cam setFocalPoint: [[[Point3D alloc] initWithValues:focal[0] :focal[1] :focal[2]] autorelease]];
    [cam setViewUp: [[[Point3D alloc] initWithValues:vUp[0] :vUp[1] :vUp[2]] autorelease]];
    [cam setClippingRangeFrom: clippingRange[0] To: clippingRange[1]];
    [cam setViewAngle: viewAngle];
    [cam setEyeAngle: eyeAngle];
    [cam setRollAngle: rollAngle];
    [cam setParallelScale: parallelScale];
    
    // window level
    [cam setWLWW: wl : ww];
    
    if( croppingBox)
    {
        vtkPlanes *planes = vtkPlanes::New();
        croppingBox->GetPlanes(planes);
        
        // cropping box
        if( planes->GetNumberOfPlanes() != 6)
            NSLog( @"****** planes->GetNumberOfPlanes() != 6");
        
        for( int i = 0; i < planes->GetNumberOfPlanes(); i++)
        {
            N3Vector p;
            N3Vector n;
            
            vtkPlane *vtkPlane = planes->GetPlane( i);
            
            double *normal, *origin;
            
            origin = vtkPlane->GetOrigin();
            normal = vtkPlane->GetNormal();
            
            p = N3VectorMake( origin[ 0], origin[ 1], origin[ 2]);
            n = N3VectorMake( normal[ 0], normal[ 1], normal[ 2]);
            
            N3Plane plane = N3PlaneMake( p, n);
            [[cam croppingPlanes] replaceObjectAtIndex: i withObject: [NSValue valueWithN3Plane: plane]];
        }
        
        planes->Delete();
    }
    
    // fusion percentage
    [cam setFusionPercentage:blendingFactor];
    
    // 4D
    [cam setMovieIndexIn4D: [controller curMovieIndex]];
    
    // thumbnail
    if( produceThumbnail)
        [cam setPreviewImage: [self nsimage:TRUE]];
    
    return [cam autorelease];
}

- (Camera*) camera
{
    return [self cameraWithThumbnail: YES];
}

- (void)setCenterlineCamera: (Camera *) cam
{
    double pos[3], focal[3], fpVector[3];
    
    pos[0] = [[cam position] x];
    pos[1] = [[cam position] y];
    pos[2] = [[cam position] z];
    focal[0] = [[cam focalPoint] x];
    focal[1] = [[cam focalPoint] y];
    focal[2] = [[cam focalPoint] z];
    fpVector[0] = focal[0] - pos[0];
    fpVector[1] = focal[1] - pos[1];
    fpVector[2] = focal[2] - pos[2];
    
    //double distance = aCamera->GetDistance();
    aCamera->Dolly(1.0);
    aCamera->SetPosition(pos);
    aCamera->SetFocalPoint(focal);
    //aCamera->SetDistance(distance);
    aCamera->ComputeViewPlaneNormal();
    aCamera->OrthogonalizeViewUp();
    
    if( clipRangeActivated)
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    else
        aRenderer->ResetCameraClippingRange();
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
}

- (void) setCamera: (Camera*) cam
{
    if( cam == nil) return;
    
    double pos[3], focal[3], vUp[3], pWC[ 2];
    pWC[0] = cam.windowCenterX;
    pWC[1] = cam.windowCenterY;
    pos[0] = [[cam position] x];
    pos[1] = [[cam position] y];
    pos[2] = [[cam position] z];
    focal[0] = [[cam focalPoint] x];
    focal[1] = [[cam focalPoint] y];
    focal[2] = [[cam focalPoint] z];
    vUp[0] = [[cam viewUp] x];
    vUp[1] = [[cam viewUp] y];
    vUp[2] = [[cam viewUp] z];
    double clippingRange[2];
    clippingRange[0] = [cam clippingRangeNear];
    clippingRange[1] = [cam clippingRangeFar];
    double viewAngle, eyeAngle, parallelScale;
    viewAngle = [cam viewAngle];
    eyeAngle = [cam eyeAngle];
    parallelScale = [cam parallelScale];
    
    // window level
    if( !advancedCLUT)
    {
        if( [cam ww] > 1)
            [self setWLWW:[cam wl] :[cam ww]];
    }
    
    // cropping box
    vtkPlanes *planes = vtkPlanes::New();
    
    vtkPoints *pts = vtkPoints::New(VTK_DOUBLE);
    pts->SetNumberOfPoints(6);
    
    vtkDoubleArray *normals = vtkDoubleArray::New();
    normals->SetNumberOfComponents(3);
    normals->SetNumberOfTuples(6);
    
    // Set the normals and coordinate values
    for (int i=0; i<6; i++)
    {
        N3Plane plane = [[[cam croppingPlanes] objectAtIndex: i] N3PlaneValue];
        
        pts->SetPoint(i, plane.point.x, plane.point.y, plane.point.z);
        normals->SetTuple3(i, plane.normal.x, plane.normal.y, plane.normal.z);
    }
    
    planes->SetPoints(pts);
    planes->SetNormals(normals);
    
    pts->Delete();
    normals->Delete();
    
    vtkVolumeMapper *mapper = (vtkVolumeMapper*) volume->GetMapper();
    mapper->SetClippingPlanes( planes);
    
    if( blendingVolume)
    {
        mapper = (vtkVolumeMapper*) blendingVolume->GetMapper();
        mapper->SetClippingPlanes( planes);
    }
    
    planes->Delete();
    
    if( croppingBox && croppingBox->GetEnabled())
        croppingBox->Off();
    
    // fusion percentage
    [self setBlendingFactor:[cam fusionPercentage]];
    
    // 4D
    if([controller is4D])
    {
        if( [cam movieIndexIn4D] != [controller curMovieIndex])
            [controller setMovieFrame: [cam movieIndexIn4D]];
    }
    //vtkCamera
    aCamera->SetWindowCenter( pWC[0], pWC[1]);
    
    aCamera->SetPosition( pos);
    aCamera->SetFocalPoint( focal);
    
    // Compute view plane from position and focalPoint
    aCamera->ComputeViewPlaneNormal();
    aCamera->SetViewUp(vUp);
    aCamera->SetViewAngle(viewAngle);
    aCamera->SetEyeAngle(eyeAngle);
    aCamera->SetParallelScale(parallelScale);
    
    aRenderer->UpdateLightsGeometryToFollowCamera();
    
    if( clipRangeActivated)
    {
        aCamera->SetDistance( 40.);
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    }
    else
        aRenderer->ResetCameraClippingRange();
    
    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixVRCameraDidChangeNotification object:self  userInfo: nil];
}

- (void) setLowResolutionCamera: (Camera*) cam
{
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD*lowResLODFactor);
    
    [self setCamera: cam];
    
    [[self window] display];
    
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
}

- (void)changeColorWith:(NSColor*) color
{
    if( color && aRenderer)
    {
        //change background color
        aRenderer->SetBackground([color redComponent],[color greenComponent],[ color blueComponent]);
        
        if( [color redComponent]+[color greenComponent]+[ color blueComponent] < 1.5)
        {
            textWLWW->GetTextProperty()->SetColor(1,1,1);
            for( int i = 0 ; i < 5 ; i++) oText[ i]->GetTextProperty()->SetColor(1,1,1);
            if( textX)
                textX->GetTextProperty()->SetColor(1,1,1);
        }
        else
        {
            textWLWW->GetTextProperty()->SetColor(0,0,0);
            for( int i = 0 ; i < 5 ; i++) oText[ i]->GetTextProperty()->SetColor(0,0,0);
            if( textX)
                textX->GetTextProperty()->SetColor(0,0,0);
        }
        [viewBackgroundColor setColor: [NSColor colorWithDeviceRed:[color redComponent] green:[color greenComponent] blue:[ color blueComponent] alpha:1.0]];
        
        [self setNeedsDisplay:YES];
    }
}

- (void)changeColor:(id)sender
{
    if( [viewBackgroundColor isActive])
        [self changeColorWith: [[(NSColorPanel*)sender color]  colorUsingColorSpaceName: NSCalibratedRGBColorSpace]];
}

- (NSColor*)backgroundColor;
{
    return [viewBackgroundColor color];
}

- (void) convert3Dto2Dpoint:(double*) pt3D :(double*) pt2D
{
    if( pt3D == nil) return;
    if( pt2D == nil) return;
    if( volume == nil) return;
    
    vtkTransform *Transform = vtkTransform::New();
    
    if( Transform)
    {
        Transform->SetMatrix( volume->GetUserMatrix());
        Transform->Push();
        
        Transform->Inverse();
        
        Transform->TransformPoint( pt3D, pt2D);
        
        double vPos[ 3];
        
        volume->GetPosition( vPos);
        
        pt2D[ 0] -= vPos[ 0];
        pt2D[ 1] -= vPos[ 1];
        pt2D[ 2] -= vPos[ 2];
        
        pt2D[0] /= [firstObject pixelSpacingX];
        pt2D[1] /= [firstObject pixelSpacingY];
        pt2D[2] /= [firstObject sliceInterval];
        
        Transform->Delete();
    }
}

- (void)convert2DPoint:(float *)pt2D to3DPoint:(float *)pt3D
{
    // convert to world size
    pt2D[0] *= [firstObject pixelSpacingX];
    pt2D[1] *= [firstObject pixelSpacingY];
    pt2D[2] *= [firstObject sliceInterval];
    
    double vPos[ 3];
    volume->GetPosition( vPos);
    
    // add in origin
    pt2D[ 0] += vPos[ 0];
    pt2D[ 1] += vPos[ 1];
    pt2D[ 2] += vPos[ 2];
    
    // tranform the point using the volume trnsform matrix
    vtkTransform *Transform = vtkTransform::New();
    Transform->SetMatrix( volume->GetUserMatrix());
    Transform->Push();
    Transform->TransformPoint( pt2D, pt3D);
    Transform->Delete();
}

- (BOOL) isViewportResizable
{
    return isViewportResizable;
}

- (void) setViewportResizable: (BOOL) boo
{
    isViewportResizable = boo;
}

- (float) offset
{
    return OFFSET16;
}

- (float) valueFactor
{
    return valueFactor;
}

// 3D points
#pragma mark-
#pragma mark 3D Points

#pragma mark add
- (void) add3DPoint: (double) x : (double) y : (double) z : (float) radius : (float) r : (float) g : (float) b
{
    x *= factor;
    y *= factor;
    z *= factor;
    
    //Sphere
    vtkSphereSource *sphereSource = vtkSphereSource::New();
    sphereSource->SetRadius(radius*superSampling);
    sphereSource->SetCenter(x, y, z);
    //Mapper
    vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
    mapper->SetInputConnection(sphereSource->GetOutputPort());
    mapper->Update();
    //Actor
    vtkActor *sphereActor = vtkActor::New();
    sphereActor->SetMapper(mapper);
    mapper->Delete();
    
    sphereActor->GetProperty()->SetColor(r,g,b);
    sphereActor->DragableOn();
    sphereActor->PickableOn();
    
    float center[3];
    center[0]=x;
    center[1]=y;
    center[2]=z;
    [point3DPositionsArray addObject:[NSValue value:center withObjCType:@encode(float[3])]];
    [point3DRadiusArray addObject:[NSNumber numberWithFloat:radius * superSampling]];
    [point3DColorsArray addObject:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0]];
    
    [self add3DPointActor: sphereActor];
    sphereSource->Delete();
}

- (void) add3DPoint: (double) x : (double) y : (double) z
{
    [self add3DPoint: x : y : z : point3DDefaultRadius : point3DDefaultColorRed : point3DDefaultColorGreen : point3DDefaultColorBlue];
}

- (void) add3DPointActor: (vtkActor*) actor
{
    void* actorPointer = actor;
    [point3DActorArray addObject:[NSValue valueWithPointer:actorPointer]];
    aRenderer->AddActor(actor);
}

- (void) addRandomPoints: (int) n : (int) r
{
    double origin[ 3];
    volume->GetPosition(origin);
    
    long i;
    // add some random points
    for(i=0; i<n ; i++)
    {
        [self add3DPoint: ((double)(random()/(pow(2.,31.)-1))*2.0-1.0)*(double)r+origin[0]/2.0 // x coordinate
                        : ((double)(random()/(pow(2.,31.)-1))*2.0-1.0)*(double)r+origin[1]/2.0 // y
                        : ((double)(random()/(pow(2.,31.)-1))*2.0-1.0)*(double)r+origin[2] // z
                        : 2.0 // radius
                        : 1.0 // red
                        : 0.0 // green
                        : 0.0 // blue
         ];
    }
}

- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val
{
    return [self get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val maxOpacity: 1.1 minValue: 0];
}

- (BOOL) get3DPixelUnder2DPositionX:(float) x Y:(float) y pixel: (long*) pix position:(float*) position value:(float*) val maxOpacity: (float) maxOpacity minValue: (float) minValue
{
    NSArray	*curPixList = [controller curPixList];
    
    // world point
    double	*worldPointClicked;
    aRenderer->SetDisplayPoint( x, y, 0);
    aRenderer->DisplayToWorld();
    worldPointClicked = aRenderer->GetWorldPoint();
    
    worldPointClicked[0] /= factor;
    worldPointClicked[1] /= factor;
    worldPointClicked[2] /= factor;
    
    // transform matrix
    vtkMatrix4x4 *ActorMatrix = volume->GetUserMatrix();
    vtkTransform *Transform = vtkTransform::New();
    Transform->SetMatrix(ActorMatrix);
    Transform->Push();
    
    // camera view plane normal
    double cameraViewPlaneNormal[3];
    aCamera->GetViewPlaneNormal(cameraViewPlaneNormal);
    
    // camera position
    double cameraPosition[3];
    aCamera->GetPosition(cameraPosition);
    cameraPosition[0] /= factor;
    cameraPosition[1] /= factor;
    cameraPosition[2] /= factor;
    
    float o[9];
    [firstObject orientation: o];
    
    double cameraProjObj[3];
    cameraProjObj[0] =	cameraViewPlaneNormal[0] * o[0]
    + cameraViewPlaneNormal[1] * o[1]
    + cameraViewPlaneNormal[2] * o[2];
    cameraProjObj[1] =	cameraViewPlaneNormal[0] * o[3]
    + cameraViewPlaneNormal[1] * o[4]
    + cameraViewPlaneNormal[2] * o[5];
    cameraProjObj[2] =	cameraViewPlaneNormal[0] * o[6]
    + cameraViewPlaneNormal[1] * o[7]
    + cameraViewPlaneNormal[2] * o[8];
    
    long stackOrientation, stackMax;
    if( fabs(cameraProjObj[0]) > fabs(cameraProjObj[1]) && fabs(cameraProjObj[0]) > fabs(cameraProjObj[2]))
    {
        stackOrientation = 0; //NSLog(@"X Stack");
        stackMax = [firstObject pwidth];
    }
    else if( fabs(cameraProjObj[1]) > fabs(cameraProjObj[0]) && fabs(cameraProjObj[1]) > fabs(cameraProjObj[2]))
    {
        stackOrientation = 1; //NSLog(@"Y Stack");
        stackMax = [firstObject pheight];
    }
    else
    {
        stackOrientation = 2; //NSLog(@"Z Stack");
        stackMax = [curPixList count];
    }
    
    if(aCamera->GetParallelProjection())
    {
        cameraPosition[0] = worldPointClicked[0] + cameraViewPlaneNormal[0];
        cameraPosition[1] = worldPointClicked[1] + cameraViewPlaneNormal[1];
        cameraPosition[2] = worldPointClicked[2] + cameraViewPlaneNormal[2];
    }
    
    // the two points defining the line going through the volume
    float	point1[3], point2[3];
    point1[0] = cameraPosition[0];
    point1[1] = cameraPosition[1];
    point1[2] = cameraPosition[2];
    
    // Go beyond the object...
    point2[0] = cameraPosition[0] + (worldPointClicked[0] - cameraPosition[0])*5000.;
    point2[1] = cameraPosition[1] + (worldPointClicked[1] - cameraPosition[1])*5000.;
    point2[2] = cameraPosition[2] + (worldPointClicked[2] - cameraPosition[2])*5000.;
    
    // volume position
    double volumePosition[3];
    volume->GetPosition(volumePosition);
    volumePosition[0] /= factor;
    volumePosition[1] /= factor;
    volumePosition[2] /= factor;
    
    BOOL direction;
    
    switch(stackOrientation)
    {
        case 0:
            if( point1[0] - point2[0] < 0) direction = YES;
            else direction = NO;
            break;
            
        case 1:
            if( point1[1] - point2[1] < 0) direction = YES;
            else direction = NO;
            break;
            
        case 2:
            if( point1[2] - point2[2] < 0) direction = YES;
            else direction = NO;
            break;
    }
    
    long p, n;
    BOOL pointFound = NO;
    float opacitySum = 0.0;
    float maxValue = -FLT_MAX;
    int blendMode;
    if( volumeMapper) blendMode = volumeMapper->GetBlendMode();
    if( textureMapper) blendMode = textureMapper->GetBlendMode();
				
    for( p = 0; p < stackMax; p++)
    {
        n = (direction)? p : (stackMax-1)-p;
        
        float currentPoint[3], planeVector[3];
        switch(stackOrientation)
        {
            case 0:
                currentPoint[0] = n * [firstObject pixelSpacingX];
                currentPoint[1] = 0;
                currentPoint[2] = 0;
                
                planeVector[0] = o[0];
                planeVector[1] = o[1];
                planeVector[2] = o[2];
                break;
                
            case 1:
                currentPoint[0] = 0;
                currentPoint[1] = n * [firstObject pixelSpacingY];
                currentPoint[2] = 0;
                
                planeVector[0] = o[3];
                planeVector[1] = o[4];
                planeVector[2] = o[5];
                break;
                
            case 2:
                currentPoint[0] = 0;
                currentPoint[1] = 0;
                currentPoint[2] = n * [firstObject sliceInterval];
                
                planeVector[0] = o[6];
                planeVector[1] = o[7];
                planeVector[2] = o[8];
                break;
        }
        
        currentPoint[0] += volumePosition[0];
        currentPoint[1] += volumePosition[1];
        currentPoint[2] += volumePosition[2];
        
        Transform->TransformPoint(currentPoint,currentPoint);
        
        float resultPt[3];
        
        if( intersect3D_SegmentPlane(point2, point1, planeVector, currentPoint, resultPt))
        {
            // Convert this 3D point to 2D point projected in the plane
            float tempPoint3D[3];
            
            Transform->Inverse();
            Transform->TransformPoint(resultPt,tempPoint3D);
            Transform->Inverse();
            
            tempPoint3D[0] -= volumePosition[0];
            tempPoint3D[1] -= volumePosition[1];
            tempPoint3D[2] -= volumePosition[2];
            
            tempPoint3D[0] /= [firstObject pixelSpacingX];
            tempPoint3D[1] /= [firstObject pixelSpacingY];
            tempPoint3D[2] /= [firstObject sliceInterval];
            
            // convert to long
            long ptInt[3];
            ptInt[0] = (long) (tempPoint3D[0] + 0.5);
            ptInt[1] = (long) (tempPoint3D[1] + 0.5);
            ptInt[2] = (long) (tempPoint3D[2] + 0.5);
            
            if(needToFlip)
            {
                ptInt[2] = [curPixList count] - ptInt[2] -1;
            }
            
            long currentSliceNumber, xPosition, yPosition;
            DCMPix *currentDCMPix;
            float *imageBuffer;
            float currentPointValue;
            
            currentSliceNumber = ptInt[2];
            if( ptInt[0] >= 0 && ptInt[0] < [firstObject pwidth] && ptInt[1] >= 0 && ptInt[1] < [firstObject pheight] &&  ptInt[ 2] >= 0 && ptInt[ 2] < [curPixList count])
            {
                currentDCMPix = [curPixList objectAtIndex:currentSliceNumber];
                imageBuffer = [currentDCMPix fImage];
                xPosition = ptInt[0];
                yPosition = ptInt[1];
                
                currentPointValue = imageBuffer[xPosition+yPosition*[currentDCMPix pwidth]];
                
                if( blendMode != vtkVolumeMapper::MAXIMUM_INTENSITY_BLEND)
                {
                    // Volume Rendering Mode
                    
                    opacitySum += opacityTransferFunction->GetValue( (currentPointValue + OFFSET16) * valueFactor) * superSampling;
                    
                    if( minValue)
                    {
                        pointFound = currentPointValue >= minValue;
                        pointFound = pointFound && opacitySum >= maxOpacity;
                    }
                    else
                        pointFound = opacitySum >= maxOpacity;
                    
                    if( pointFound)
                    {
                        *val = currentPointValue;
                        
                        pix[ 0] = ptInt[ 0];
                        pix[ 1] = ptInt[ 1];
                        pix[ 2] = ptInt[ 2];
                        
                        position[ 0] = resultPt[0];
                        position[ 1] = resultPt[1];
                        position[ 2] = resultPt[2];
                        
                        p = stackMax;	// stop the 'for loop'
                    }
                }
                else
                {
                    if( currentPointValue > maxValue)
                    {
                        if( minValue)
                        {
                            pointFound = currentPointValue >= minValue;
                        }
                        else pointFound = YES;
                        
                        maxValue = currentPointValue;
                        *val = currentPointValue;
                        
                        pix[ 0] = ptInt[ 0];
                        pix[ 1] = ptInt[ 1];
                        pix[ 2] = ptInt[ 2];
                        
                        position[ 0] = resultPt[0];
                        position[ 1] = resultPt[1];
                        position[ 2] = resultPt[2];
                    }
                }
            }
        }
    }
    
    Transform->Delete();
    
    return pointFound;
}

- (void) throw3DPointOnSurface: (double) x : (double) y
{
    long	pix[ 3];
    float	pos[ 3], value;
    
    if( [self get3DPixelUnder2DPositionX:x Y:y pixel:pix position:pos value:&value])
    {
        [self add3DPoint: pos[0] : pos[1] : pos[2]];
        
        RGBColor rgb;
        
        rgb.red = point3DDefaultColorRed * 65535.;
        rgb.green = point3DDefaultColorGreen * 65535.;
        rgb.blue = point3DDefaultColorBlue * 65535.;
        
        [controller add2DPoint: pix[0] : pix[1] : pix[ 2] :pos :rgb];
    }
}

#pragma mark display
- (void) setDisplay3DPoints: (BOOL) on
{
    display3DPoints = on;
    
    //id object;
    vtkActor *actor;
    
    for  (id object in point3DActorArray)
    {
        actor = (vtkActor*)[object pointerValue];
        if(on)
        {
            aRenderer->AddActor(actor);
        }
        else
        {
            aRenderer->RemoveActor(actor);
        }
    }
    [self unselectAllActors];
    [self setNeedsDisplay:YES];
}

- (void) toggleDisplay3DPoints
{
    [self setDisplay3DPoints:!display3DPoints];
}

#pragma mark selection
- (BOOL) isAny3DPointSelected
{
    BOOL boo = NO;
    
    if(((vtkAbstractPropPicker*)aRenderer->GetRenderWindow()->GetInteractor()->GetPicker())->GetViewProp() != NULL)
    {
        // a vtkObject is selected, let's check if it is one of our 3D Points
        if([self selected3DPointIndex] < [point3DActorArray count])
        {
            boo = YES;
        }
    }
    
    return boo;
}

- (unsigned int) selected3DPointIndex
{
    vtkProp *pickedProp = ((vtkAbstractPropPicker*)aRenderer->GetRenderWindow()->GetInteractor()->GetPicker())->GetPath()->GetFirstNode()->GetViewProp();
    
    void *pickedPropPointer = pickedProp;
    
    NSEnumerator *enumerator = [point3DActorArray objectEnumerator];
    id object;
    void *actorPointer;
    unsigned int i = 0;
    
    while (object = [enumerator nextObject])
    {
        actorPointer = [object pointerValue];
        if(pickedPropPointer==actorPointer)
        {
            return i;
        }
        i++;
    }
    return i; // if no point is selected, returns [point3DActorArray count], i.e. out of bounds...
}

- (void) unselectAllActors
{
    ((vtkInteractorStyle*)aRenderer->GetRenderWindow()->GetInteractor()->GetInteractorStyle())->HighlightProp3D(NULL);
}

#pragma mark remove
- (void) remove3DPointAtIndex: (unsigned int) index
{
    // point to remove
    vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
    // remove from Renderer
    aRenderer->RemoveActor(actor);
    // remove the highlight bounding box
    [self unselectAllActors];
    // kill the actor himself
    actor->Delete();
    // remove from list
    [point3DActorArray removeObjectAtIndex:index];
    [point3DPositionsArray removeObjectAtIndex:index];
    [point3DRadiusArray removeObjectAtIndex:index];
    [point3DColorsArray removeObjectAtIndex:index];
    // refresh display
    [self setNeedsDisplay:YES];
}

- (void) removeSelected3DPoint
{
    if([self isAny3DPointSelected])
    {
        // remove 2D Point
        float position[3];
        [[point3DPositionsArray objectAtIndex:[self selected3DPointIndex]] getValue:position];
        
        [controller remove2DPoint: position[0] : position[1] : position[2]];
        // remove 3D Point
        // the 3D Point is removed through notification (sent in [controller remove2DPoint..)
        //[self remove3DPointAtIndex:[self selected3DPointIndex]];
    }
}

#pragma mark modify 3D point appearence

- (IBAction) IBSetSelected3DPointColor: (id) sender
{
    if([point3DPropagateToAll state])
    {
        [self setAll3DPointsColor: [sender color]];
        [self setAll3DPointsRadius: [point3DRadiusSlider floatValue]];
    }
    else
    {
        [self setSelected3DPointColor: [sender color]];
    }
    [self setNeedsDisplay:YES];
}

- (IBAction) IBSetSelected3DPointRadius: (id) sender
{
    if([point3DPropagateToAll state])
    {
        [self setAll3DPointsRadius: [sender floatValue]];
        [self setAll3DPointsColor: [[point3DColorWell color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]];
    }
    else
    {
        [self setSelected3DPointRadius: [sender floatValue]];
    }
    [self setNeedsDisplay:YES];
}

- (IBAction) IBPropagate3DPointsSettings: (id) sender
{
    if([sender state]==NSOnState)
    {
        [self setAll3DPointsRadius: [point3DRadiusSlider floatValue]];
        [self setAll3DPointsColor: [[point3DColorWell color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]];
        [self setNeedsDisplay:YES];
    }
}

- (void) setSelected3DPointColor: (NSColor*) color
{
    if([self isAny3DPointSelected])[self set3DPointAtIndex:[self selected3DPointIndex] Color: color];
}

- (void) setAll3DPointsColor: (NSColor*) color
{
    unsigned int i = 0;
    for(i=0 ; i<[point3DColorsArray count] ; i++)
    {
        [self set3DPointAtIndex:i Color: color];
    }
}

- (void) set3DPointAtIndex:(unsigned int) index Color: (NSColor*) color
{
    vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
    actor->GetProperty()->SetColor([color redComponent],[color greenComponent],[color blueComponent]);
    
    [point3DColorsArray removeObjectAtIndex:index];
    [point3DColorsArray insertObject:color atIndex:index];
}

- (void) setSelected3DPointRadius: (float) radius
{
    if([self isAny3DPointSelected])[self set3DPointAtIndex:[self selected3DPointIndex] Radius: radius];
}

- (void) setAll3DPointsRadius: (float) radius
{
    unsigned int i = 0;
    for(i=0 ; i<[point3DRadiusArray count] ; i++)
    {
        [self set3DPointAtIndex:i Radius: radius];
    }
}

- (void) set3DPointAtIndex:(unsigned int) index Radius: (float) radius
{
    vtkActor *actor = (vtkActor*)[[point3DActorArray objectAtIndex:index] pointerValue];
    //Sphere
    vtkSphereSource *sphereSource = vtkSphereSource::New();
    sphereSource->SetRadius(radius*superSampling);
    float center[3];
    [[point3DPositionsArray objectAtIndex:index] getValue:center];
    sphereSource->SetCenter(center[0],center[1],center[2]);
    //Mapper
    vtkPolyDataMapper *mapper = vtkPolyDataMapper::New();
    mapper->SetInputConnection(sphereSource->GetOutputPort());
    mapper->Update();
    //Actor
    actor->SetMapper(mapper);
    mapper->Delete();
    
    [point3DRadiusArray removeObjectAtIndex:index];
    [point3DRadiusArray insertObject:[NSNumber numberWithFloat:radius] atIndex:index];
    
    sphereSource->Delete();
}

- (IBAction) save3DPointsDefaultProperties: (id) sender
{
    NSColor *color = [[point3DColorWell color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
    
    //color
    point3DDefaultColorRed = [color redComponent];
    point3DDefaultColorGreen = [color greenComponent];
    point3DDefaultColorBlue = [color blueComponent];
    point3DDefaultColorAlpha = [color alphaComponent];
    [[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorRed forKey:@"points3DcolorRed"];
    [[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorGreen forKey:@"points3DcolorGreen"];
    [[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorBlue forKey:@"points3DcolorBlue"];
    [[NSUserDefaults standardUserDefaults] setFloat:point3DDefaultColorAlpha forKey:@"points3DcolorAlpha"];
    
    // radius
    point3DDefaultRadius = [point3DRadiusSlider floatValue];
    [[NSUserDefaults standardUserDefaults] setFloat:[point3DRadiusSlider floatValue] forKey:@"points3Dradius"];
}

- (void) load3DPointsDefaultProperties
{
    //color
    point3DDefaultColorRed = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorRed"];
    point3DDefaultColorGreen = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorGreen"];
    point3DDefaultColorBlue = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorBlue"];
    point3DDefaultColorAlpha = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3DcolorAlpha"];
    
    if(point3DDefaultColorAlpha==0.0)
    {
        point3DDefaultColorRed = 0.0;
        point3DDefaultColorGreen = 1.0;
        point3DDefaultColorBlue = 0.0;
        point3DDefaultColorAlpha = 1.0;
    }
    
    //radius
    point3DDefaultRadius = [[NSUserDefaults standardUserDefaults] floatForKey:@"points3Dradius"];
    if (point3DDefaultRadius==0) point3DDefaultRadius = 5.0;
}

- (float) factor
{
    return factor;
}

#pragma mark-
#pragma mark Export mode

- (void) sendMail:(id) sender
{
    aRenderer->SetDraw( 0);
    [controller sendMail: sender];
    aRenderer->SetDraw( 1);
}

- (void) exportJPEG:(id) sender
{
    aRenderer->SetDraw( 0);
    [controller exportJPEG: sender];
    aRenderer->SetDraw( 1);
}

- (void) export2iPhoto:(id) sender
{
    aRenderer->SetDraw( 0);
    [controller export2iPhoto: sender];
    aRenderer->SetDraw( 1);
}

- (void) exportTIFF:(id) sender
{
    aRenderer->SetDraw( 0);
    [controller exportTIFF: sender];
    aRenderer->SetDraw( 1);
}

#pragma mark-
#pragma mark Cursors

//cursor methods

- (void)mouseEntered:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    cursorSet = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    cursorSet = NO;
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    if ([self eventToPlugins:theEvent]) return;
    
    cursorSet = YES;
    [cursor set];
}

- (void) checkCursor
{
    if(cursorSet) [cursor set];
}

-(void) setCursorForView: (ToolMode) tool
{
    NSCursor	*c;
    
    if (tool == tMesure || tool == t3Dpoint)
        c = [NSCursor crosshairCursor];
    else if( tool == t3DCut)
        c = [NSCursor crosshairCursor];
    else if (tool == t3DRotate)
        c = [NSCursor rotate3DCursor];
    else if (tool == tCamera3D)
        c = [NSCursor rotate3DCameraCursor];
    else if (tool == tTranslate)
        c = [NSCursor openHandCursor];
    else if (tool == tRotate)
        c = [NSCursor rotateCursor];
    else if (tool == tZoom)
        c = [NSCursor zoomCursor];
    else if (tool == tWL || tool == tWLBlended)
        c = [NSCursor contrastCursor];
    else if (tool == tNext)
        c = [NSCursor stackCursor];
    else if (tool == tText)
        c = [NSCursor IBeamCursor];
    else if (tool == t3DRotate)
        c = [NSCursor crosshairCursor];
    else if (tool == tCross)
        c = [NSCursor crosshairCursor];
    else if (tool == tBonesRemoval)
        c = [NSCursor bonesRemovalCursor];
    else
        c = [NSCursor arrowCursor];
    
    if( c != cursor)
    {
        [cursor release];
        
        cursor = [c retain];
    }
}

#pragma mark-  Drag and Drop

static NSString * const O2PasteboardTypeEventModifierFlags = @"com.opensource.osirix.eventmodifierflags";

- (void) startDrag:(NSTimer*)theTimer
{
    @try {
        _dragInProgress = YES;
        NSEvent *event = (NSEvent *)[theTimer userInfo];
        
        NSImage *image = [self nsimage:(event.modifierFlags&NSShiftKeyMask)];
        
        NSSize originalSize = [image size];
        float ratio = originalSize.width / originalSize.height;
        NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize(100, 100/ratio)] autorelease];
        if( [thumbnail size].width > 0 && [thumbnail size].height > 0) {
            [thumbnail lockFocus];
            [image drawInRect: NSMakeRect(0, 0, 100, 100/ratio) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
            [thumbnail unlockFocus];
        }
        
        NSPasteboardItem* pbi = [[[NSPasteboardItem alloc] init] autorelease];
        [pbi setData:image.TIFFRepresentation forType:NSPasteboardTypeTIFF];
        NSEventModifierFlags mf = event.modifierFlags;
        [pbi setData:[NSData dataWithBytes:&mf length:sizeof(NSEventModifierFlags)] forType:O2PasteboardTypeEventModifierFlags];
        [pbi setDataProvider:self forTypes:@[NSPasteboardTypeString, (NSString *)kPasteboardTypeFileURLPromise]];
        [pbi setString:(id)kUTTypeImage forType:(id)kPasteboardTypeFilePromiseContent];

        NSDraggingItem* di = [[[NSDraggingItem alloc] initWithPasteboardWriter:pbi] autorelease];
        NSPoint p = [self convertPoint:event.locationInWindow fromView:nil];
        [di setDraggingFrame:NSMakeRect(p.x-thumbnail.size.width/2, p.y-thumbnail.size.height/2, thumbnail.size.width, thumbnail.size.height) contents:thumbnail];
        
        NSDraggingSession* session = [self beginDraggingSessionWithItems:@[di] event:event source:self];
        session.animatesToStartingPositionsOnCancelOrFail = YES;
    }
    @catch( NSException *localException) {
        NSLog(@"Exception while dragging: %@", [localException description]);
    }
    
    _dragInProgress = NO;
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return NSDragOperationGeneric;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    if ([type isEqualToString:(id)kPasteboardTypeFileURLPromise]) {
        PasteboardRef pboardRef = NULL;
        PasteboardCreate((__bridge CFStringRef)[pasteboard name], &pboardRef);
        if (!pboardRef)
            return;
        
        PasteboardSynchronize(pboardRef);
        
        CFURLRef urlRef = NULL;
        PasteboardCopyPasteLocation(pboardRef, &urlRef);
        
        if (urlRef) {
            NSString *description = firstObject.imageObj.series.name;
            if (!description.length)
                description = firstObject.imageObj.series.seriesDescription;
            
            NSString *name = firstObject.imageObj.series.study.name;
            if (description.length)
                name = [name stringByAppendingFormat:@" - %@", description];
            
            if (!name.length)
                name = @"Horos";
            
            NSURL *url = [(NSURL *)urlRef URLByAppendingPathComponent:[name stringByAppendingPathExtension:@"jpg"]];
            size_t i = 0;
            while ([url checkResourceIsReachableAndReturnError:NULL])
                url = [(NSURL *)urlRef URLByAppendingPathComponent:[name stringByAppendingFormat:@" (%lu).jpg", ++i]];
            
            NSEventModifierFlags mf; [[item dataForType:O2PasteboardTypeEventModifierFlags] getBytes:&mf];
            NSImage *image = [self nsimage:(mf&NSShiftKeyMask)];
            
            NSData *idata = [[NSBitmapImageRep imageRepWithData:image.TIFFRepresentation] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
            [idata writeToURL:url atomically:YES];
            
            [item setString:[url absoluteString] forType:type];
            
            CFRelease(urlRef);
        }
        
        CFRelease(pboardRef);
    }
}

- (void)deleteMouseDownTimer
{
    [_mouseDownTimer invalidate];
    [_mouseDownTimer release];
    _mouseDownTimer = nil;
    _dragInProgress = NO;
}

- (void)deleteRightMouseDownTimer
{
    [_rightMouseDownTimer invalidate];
    [_rightMouseDownTimer release];
    _rightMouseDownTimer = nil;
}

//- (void) showMenu:(NSTimer*)theTimer
//{
//	_contextualMenuActive = YES;
//	NSEvent *event = (NSEvent *)[theTimer userInfo];
//	[self performSelectorOnMainThread:@selector(showMenuOnMainThread:) withObject:event waitUntilDone:YES];
//}

//- (void)showMenuOnMainThread:(NSEvent *)event
//{
//	[NSMenu popUpContextMenu:[self defaultMenu] withEvent:event forView:self];
//}

//part of Dragging Source Protocol
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal{
    return NSDragOperationEvery;
}

#pragma mark -
#pragma mark Hot Keys.
//Hot key action
-(BOOL)actionForHotKey:(NSString *)hotKey
{
    BOOL returnedVal = YES;
    
    if ([hotKey length] > 0)
    {
        NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"];
        NSArray *wwwlValues = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        NSDictionary *opacityDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"];
        NSArray *opacityValues = [[opacityDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        NSString *wwwlMenuString = nil;
        hotKey = [hotKey lowercaseString];
        unichar key = [hotKey characterAtIndex:0];
        
        if( [[DCMView hotKeyDictionary] objectForKey:hotKey])
        {
            key = [[[DCMView hotKeyDictionary] objectForKey:hotKey] intValue];
            id windowController = [[self window] windowController];
            NSLog( @"hot key: %d", key);
            
            switch (key)
            {
                case DefaultWWWLHotKeyAction: // default WW/WL
                    wwwlMenuString = NSLocalizedString(@"Default WL & WW", nil);	// default WW/WL
                    [windowController applyWLWWForString:wwwlMenuString];
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: wwwlMenuString userInfo: nil];
                    break;
                case FullDynamicWWWLHotKeyAction:  // full dynamic WW/WL
                    wwwlMenuString = NSLocalizedString(@"Full dynamic", nil);
                    [windowController applyWLWWForString:wwwlMenuString];
                    [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: wwwlMenuString userInfo: nil];
                    break;
                    
                case Preset1WWWLHotKeyAction:																	// 1 - 9 will be presets WW/WL
                case Preset2WWWLHotKeyAction:
                case Preset3WWWLHotKeyAction:
                case Preset4WWWLHotKeyAction:
                case Preset5WWWLHotKeyAction:
                case Preset6WWWLHotKeyAction:
                case Preset7WWWLHotKeyAction:
                case Preset8WWWLHotKeyAction:
                case Preset9WWWLHotKeyAction:
                    if([wwwlValues count] > key-Preset1WWWLHotKeyAction)
                    {
                        wwwlMenuString = [wwwlValues objectAtIndex:key-Preset1WWWLHotKeyAction];
                        [windowController applyWLWWForString:wwwlMenuString];
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: wwwlMenuString userInfo: nil];
                    }
                    break;
                    
                case Preset1OpacityHotKeyAction:																	// 1 - 9 will be opacity presets
                case Preset2OpacityHotKeyAction:
                case Preset3OpacityHotKeyAction:
                case Preset4OpacityHotKeyAction:
                case Preset5OpacityHotKeyAction:
                case Preset6OpacityHotKeyAction:
                case Preset7OpacityHotKeyAction:
                case Preset8OpacityHotKeyAction:
                case Preset9OpacityHotKeyAction:
                    if([opacityValues count] >= key-Preset1OpacityHotKeyAction)
                    {
                        int index = key-Preset1OpacityHotKeyAction-1;
                        
                        NSString *opacityMenuString;
                        
                        if( index < 0)
                            opacityMenuString = NSLocalizedString(@"Linear Table", nil);
                        else
                            opacityMenuString = [opacityValues objectAtIndex: index];
                        
                        [windowController ApplyOpacityString: opacityMenuString];
                        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: opacityMenuString userInfo: nil];
                    }
                    break;
                    
                    // Flip  Don't flip Vertical or Horizontal in VR Do nothing
                    
                    // mouse functions
                case WWWLToolHotKeyAction:
                case MoveHotKeyAction:
                case ZoomHotKeyAction:
                case RotateHotKeyAction:
                case ScrollHotKeyAction:
                case LengthHotKeyAction:
                case OvalHotKeyAction:
                case Rotate3DHotKeyAction:
                case Camera3DotKeyAction:
                case scissors3DHotKeyAction:
                case ThreeDPointHotKeyAction:
                case PlainToolHotKeyAction:
                case BoneRemovalHotKeyAction:
                    if( [ViewerController getToolEquivalentToHotKey: key] >= 0)
                    {
                        ToolMode tool = [ViewerController getToolEquivalentToHotKey: key];
                        
                        if( tool == t2DPoint)
                            tool = t3Dpoint;
                        
                        [windowController setCurrentTool: tool];
                    }
                    break;
                    
                default:
                    returnedVal = NO;
                    break;
            }
        }
        else returnedVal = NO;
    }
    else returnedVal = NO;
    
    return returnedVal;
}

#pragma mark -
#pragma mark Advanced CLUT / Opacity

- (void)setAdvancedCLUT:(NSMutableDictionary*)clut lowResolution:(BOOL)lowRes;
{
    if( [controller windowWillClose]) return;
    
    advancedCLUT = YES;
    
    NSArray *curves = [clut objectForKey:@"curves"];
    NSArray *pointColors = [clut objectForKey:@"colors"];
    
    
    if( [[NSArchiver archivedDataWithRootObject: clut] isEqualToData: appliedCurves] == NO || (appliedResolution == YES && lowRes == NO))
    {
        colorTransferFunction->RemoveAllPoints();
        opacityTransferFunction->RemoveAllPoints();
        
        opacityTransferFunction->AddSegment([controller minimumValue], 0.0, [controller maximumValue], 0.0);
        
        for(int i=0; i<[curves count]; i++)
        {
            NSMutableArray *aCurve = [NSMutableArray arrayWithArray:[curves objectAtIndex:i]];
            NSMutableArray *someColors = [NSMutableArray arrayWithArray:[pointColors objectAtIndex:i]];
            for(int j=0; j<[aCurve count]; j++)
            {
                colorTransferFunction->AddRGBPoint( (OFFSET16 + [[aCurve objectAtIndex:j] pointValue].x) * valueFactor, [[someColors objectAtIndex:j] redComponent], [[someColors objectAtIndex:j] greenComponent], [[someColors objectAtIndex:j] blueComponent]);
                
                float opacityAdapter = 1;
                
                if( renderingMode == 0) // VR
                    opacityAdapter = superSampling;
                
                float o = [[aCurve objectAtIndex:j] pointValue].y * [[aCurve objectAtIndex:j] pointValue].y / opacityAdapter;
                
                opacityTransferFunction->AddPoint( (OFFSET16 + [[aCurve objectAtIndex:j] pointValue].x) * valueFactor, o);
            }
        }
        
        [appliedCurves release];
        appliedCurves = [[NSArchiver archivedDataWithRootObject: clut] retain];
        appliedResolution = lowRes;
        
        if( volumeMapper)
        {
            if(lowRes)
                volumeMapper->SetMinimumImageSampleDistance(LOD*lowResLODFactor*2); // was LOD*5
            else
                volumeMapper->SetMinimumImageSampleDistance(LOD);
        }
        
        if( blendingVolumeMapper)
        {
            if(lowRes)
                blendingVolumeMapper->SetMinimumImageSampleDistance(LOD*lowResLODFactor*2); // was LOD*5
            else
                blendingVolumeMapper->SetMinimumImageSampleDistance(LOD);
        }
        
        [self setNeedsDisplay: YES];
    }
}

- (void)setAdvancedCLUTWithName:(NSString*)name;
{
}

- (BOOL)advancedCLUT;
{
    return advancedCLUT;
}

-(VRController*)controller;
{
    return controller;
}

- (void)setController:(VRController*)aController;
{
    controller = aController;
}

- (BOOL)isRGB;
{
    return isRGB;
}

- (vtkVolumeMapper*) mapper;
{
    if( volumeMapper == nil)
    {
        volumeMapper = vtkHorosFixedPointVolumeRayCastMapper::New();
        volumeMapper->SetInputConnection(reader->GetOutputPort());
    }
    
    volumeMapper->Update();
    return volumeMapper;
}

- (void)setMapper:(vtkVolumeMapper*) mapper;
{
    if( mapper && mapper != volumeMapper)
    {
        if( volumeMapper)
            volumeMapper->Delete();
        
        volumeMapper = (vtkHorosFixedPointVolumeRayCastMapper*) mapper;
        volume->SetMapper( volumeMapper);
    }
}

- (vtkVolume*)volume;
{
    return volume;
}

- (void)setVolume:(vtkVolume*)aVolume;
{
    if(volume) volume->Delete();
    volume = aVolume;
}

- (char*)data8;
{
    return data8;
}

- (void)setData8:(char*)someData;
{
    if(data8) free(data8);
    data8 = someData;
}


#pragma mark -
#pragma mark IMAVManager delegate methods.

// Callback from IMAVManager asking what pixel format we'll be providing frames in.
- (void)getPixelBufferPixelFormat:(OSType *)pixelFormatOut {
    //	NSLog(@"getPixelBufferPixelFormat");
    *pixelFormatOut = kCVPixelFormatType_32ARGB;
}

// This callback is called periodically when we're in the IMAVActive state.
// We copy (actually, re-render) what's currently on the screen into the provided
// CVPixelBufferRef.
//
// Note that this will be called on a non-main thread.
- (BOOL) renderIntoPixelBuffer:(CVPixelBufferRef)buffer forTime:(CVTimeStamp*)timeStamp
{
    //	NSLog(@"renderIntoPixelBuffer");
    // We ignore the timestamp, signifying that we're providing content for 'now'.
    CVReturn err;
    
    // If the image has not changed since we provided the last one return 'NO'.
    // This enables more efficient transmission of the frame when there is no
    // new information.
    if ([self checkHasChanged] == NO)
    {
        return NO;
    }
    
    
    // Lock the pixel buffer's base address so that we can draw into it.
    if((err = CVPixelBufferLockBaseAddress(buffer, 0)) != kCVReturnSuccess) {
        // This should not happen.  If it does, the safe thing to do is return
        // 'NO'.
        NSLog(@"Warning, could not lock pixel buffer base address in %s - error %ld", __func__, (long)err);
        return NO;
    }
    @synchronized (self) {
        // Create a CGBitmapContext with the CVPixelBuffer.  Parameters /must/ match
        // pixel format returned in getPixelBufferPixelFormat:, above, width and
        // height should be read from the provided CVPixelBuffer.
        iChatWidth = CVPixelBufferGetWidth(buffer);
        iChatHeight = CVPixelBufferGetHeight(buffer);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef cgContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(buffer),
                                                       iChatWidth, iChatHeight,
                                                       8,
                                                       CVPixelBufferGetBytesPerRow(buffer),
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(colorSpace);
        
        [self setIChatFrame:YES];
        
        // Derive an NSGraphicsContext, make it current, and ask our SlideshowView
        // to draw.
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
        [NSGraphicsContext setCurrentContext:context];
        //get NSImage and draw in the rect
        NSImage *image = [self nsimage:NO];
        
        if(image) //if([image size].width>0 && [image size].height>0)
            [self drawImage:image inBounds:NSMakeRect(0.0, 0.0, iChatWidth, iChatHeight)];
        else
            [self drawImage:[[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] bundlePath]] inBounds:NSMakeRect(0.0, 0.0, iChatWidth, iChatHeight)];
        [context flushGraphics];
        
        // Clean up - remember to unlock the pixel buffer's base address (we locked
        // it above so that we could draw into it).
        CGContextRelease(cgContext);
        CVPixelBufferUnlockBaseAddress(buffer, 0);
    }
    return YES;
}

- (void)drawImage:(NSImage *)image inBounds:(NSRect)rect
{
    // We synchronise to make sure we're not drawing in two threads
    // simultaneously.
    
    [[NSColor blackColor] set];
    NSRectFill(rect);
    
    if (image != nil) {
        NSRect imageBounds = { NSZeroPoint, [image size] };
        float scaledHeight = NSWidth(rect) * NSHeight(imageBounds);
        float scaledWidth  = NSHeight(rect) * NSWidth(imageBounds);
        
        if (scaledHeight < scaledWidth) {
            // rect is wider than image: fit height
            float horizMargin = NSWidth(rect) - scaledWidth / NSHeight(imageBounds);
            rect.origin.x += horizMargin / 2.0;
            rect.size.width -= horizMargin;
        } else {
            // rect is taller than image: fit width
            float vertMargin = NSHeight(rect) - scaledHeight / NSWidth(imageBounds);
            rect.origin.y += vertMargin / 2.0;
            rect.size.height -= vertMargin;
        }
        
        [image drawInRect:rect fromRect:imageBounds operation:NSCompositeSourceOver fraction:fraction];
    }
    
    //}
}

// The _hasChanged flag is set to 'NO' after any check (by a client of this
// class), and 'YES' after a frame is drawn that is not identical to the
// previous one (in the drawInBounds: method).

// Returns the current state of the flag, and sets it to the passed in value.
- (BOOL)_checkHasChanged:(BOOL)flag {
    //NSLog(@"_checkHasChanged");
    BOOL hasChanged;
    @synchronized (self) {
        hasChanged = _hasChanged;
        _hasChanged = flag;
    }
    return hasChanged;
}

- (BOOL)checkHasChanged {
    
    // Calling with 'NO' clears _hasChanged after the call (see above).
    return [self _checkHasChanged:NO];
}

- (void)setIChatFrame:(BOOL)set;
{
    if([[[self controller] style] isEqualToString:@"panel"]) return;
    
    //NSLog(@"setIChatFrame");
    if(set)
    {
        if(iChatFrameIsSet) return;
        //NSLog(@"iChatWidth : %f , iChatHeight : %f", iChatWidth, iChatHeight);
        if(iChatWidth==0 || iChatHeight==0) return;
        
        iChatFrameIsSet = YES;
        
        savedViewSizeFrame = [self frame];
        
        NSRect frame;
        frame.size.width = iChatWidth;
        frame.size.height = iChatHeight;
        frame.origin.x = savedViewSizeFrame.origin.x + (savedViewSizeFrame.size.width-iChatWidth)/2.0;
        frame.origin.y = savedViewSizeFrame.origin.y + (savedViewSizeFrame.size.height-iChatHeight)/2.0;
        [self setFrame:frame];
    }
    else
    {
        iChatFrameIsSet = NO;
        if(savedViewSizeFrame.size.width>0 && savedViewSizeFrame.size.height>0)
            [self setFrame:savedViewSizeFrame];
    }
}

//- (void)_iChatStateChanged:(NSNotification *)aNotification;
//{
//	[self setIChatFrame:[[IChatTheatreDelegate sharedDelegate] isIChatTheatreRunning]];
//}

- (BOOL)becomeFirstResponder
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixVRViewDidBecomeFirstResponderNotification object:self];
    [self connect2SpaceNavigator];
    return [super becomeFirstResponder];
}

- (void) displayLowRes
{
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD * lowResLODFactor);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD * lowResLODFactor);
    
    if( [self needsDisplay])
        [self display];
    
    if( volumeMapper) volumeMapper->SetMinimumImageSampleDistance( LOD);
    if( blendingVolumeMapper) blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
}

- (void)yaw:(float)degrees;
{
    aCamera->Yaw( degrees);
    
    if( clipRangeActivated)
        aCamera->SetClippingRange( 0.0, clippingRangeThickness);
    else
        aRenderer->ResetCameraClippingRange();
    
    [self setNeedsDisplay:YES];
}

- (void)panX:(double)x Y:(double)y;
{
    vtkRenderWindowInteractor *rwi = [self getInteractor];
    
    double ViewFocus[4];
    double NewPickPoint[4];
    
    // Calculate the focal depth
    vtkCamera* camera = aCamera;
    camera->GetFocalPoint(ViewFocus);
    rwi->GetInteractorStyle()->ComputeWorldToDisplay(aRenderer, ViewFocus[0], ViewFocus[1], ViewFocus[2], ViewFocus);
    double focalDepth = ViewFocus[2];
    
    rwi->GetInteractorStyle()->ComputeDisplayToWorld(aRenderer, (double)x, (double)y, focalDepth, NewPickPoint);
    
    // Get the current focal point and position
    
    camera->GetFocalPoint(ViewFocus);
    
    double *ViewPoint = camera->GetPosition();
    
    // Compute a translation vector, moving everything
    // the distance to the cursor. (Arbitrary scale factor)
    
    double MotionVector[3];
    MotionVector[0] = 0.0001 * (ViewFocus[0] - NewPickPoint[0]);
    MotionVector[1] = 0.0001 * (ViewFocus[1] - NewPickPoint[1]);
    MotionVector[2] = 0.0001 * (ViewFocus[2] - NewPickPoint[2]);
    
    camera->SetFocalPoint(MotionVector[0] + ViewFocus[0],
                          MotionVector[1] + ViewFocus[1],
                          MotionVector[2] + ViewFocus[2]);
    
    camera->SetPosition(MotionVector[0] + ViewPoint[0],
                        MotionVector[1] + ViewPoint[1],
                        MotionVector[2] + ViewPoint[2]);
    
    if (rwi->GetLightFollowCamera())
        aRenderer->UpdateLightsGeometryToFollowCamera();
}

- (void)recordFlyThru;
{
    [controller recordFlyThru];
}

#pragma mark-
#pragma mark  3DConnexion SpaceNavigator

- (void) closeEvent:(id) sender
{
    VRView *vV = (VRView*) snVRView;
    if( volumeMapper)
        volumeMapper->SetMinimumImageSampleDistance( LOD);
    
    if( blendingVolumeMapper)
        blendingVolumeMapper->SetMinimumImageSampleDistance( LOD);
    
    [vV getInteractor]->InvokeEvent(vtkCommand::LeftButtonReleaseEvent,NULL);
    
    snStopped = YES;
    
    [snCloseEventTimer release];
    snCloseEventTimer = nil;
}

#if USE3DCONNEXION
- (void)connect2SpaceNavigator;
{
    snVRView = self;
    snStopped = YES;
    OSErr	error;
    if(InstallConnexionHandlers != NULL)
    {
        // Install message handler and register our client
        error = InstallConnexionHandlers(VRSpaceNavigatorMessageHandler, nil, nil);
        
        // This takes over in our application only
        snConnexionClientID = RegisterConnexionClient('OsiX', (UInt8*) "\pOsiriX", kConnexionClientModeTakeOver, kConnexionMaskAll);
    }
}

void VRSpaceNavigatorMessageHandler(io_connect_t connection, natural_t messageType, void *messageArgument)
{
    static ConnexionDeviceState	lastState;
    ConnexionDeviceState		*state;
    VRView *vV = (VRView*) snVRView;
    
    SInt16 tx, ty, tz, rx, ry, rz, xPos, yPos;
    float axis_max, speed, rot;
    
    BOOL record = NO;
    
    switch(messageType)
    {
        case kConnexionMsgDeviceState:
            state = (ConnexionDeviceState*)messageArgument;
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            AbsoluteTime theTime = UpTime();
#pragma clang diagnostic pop
            uint64_t t = ((uint64_t*) &theTime)[0];
            
            if(t - state->time > 2*1000*1000)
            {
                break;
            }
            
            if(state->client == snVRView->snConnexionClientID)
            {
                // decipher what command/event is being reported by the driver
                switch (state->command)
                {
                    case kConnexionCmdHandleAxis:
                        // get the axis movement (names are taken from the SDK documentation)
                        tx = state->axis[0];
                        ty = state->axis[1];
                        tz = state->axis[2];
                        rx = state->axis[3];
                        ry = state->axis[4];
                        rz = state->axis[5];
                        
                        // normalization
                        axis_max = 500.0; // typical value according to the SDK
                        
                        // if shift is pressed -> faster movement
                        BOOL faster;
                        if([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask)
                            faster = YES;
                        else faster = NO;
                        
                        // if ctrl is pressed -> record
                        if([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSControlKeyMask)
                            record = YES;
                        else record = NO;
                        
                        if( vV->snCloseEventTimer)
                        {
                            [vV->snCloseEventTimer invalidate];
                            [vV->snCloseEventTimer release];
                            vV->snCloseEventTimer = nil;
                        }
                        
                        // *** zoom ***
                        if( vV->projectionMode != 2)
                        {
                            speed = 0.2; // zoom speed 0.2 is slow 1.0 is fast
                            float zoom = ((float)tz/axis_max)*speed +1.0;
                            
                            if( zoom < 0.98 || zoom > 1.02)
                            {
                                [vV vtkCamera]->Zoom(zoom);
                                [vV setNeedsDisplay:YES];
                            }
                        }
                        else // endosocpy
                        {
                            float distance = [vV vtkCamera]->GetDistance();
                            float dolly = ((float)tz/axis_max) / 60.;
                            if(faster) dolly*=3.;
                            if( dolly < -0.9) dolly = -0.9;
                            
                            [vV vtkCamera]->Dolly( 1.0 + dolly);
                            [vV vtkCamera]->SetDistance( distance);
                            [vV vtkCamera]->ComputeViewPlaneNormal();
                            [vV vtkCamera]->OrthogonalizeViewUp();
                            [vV vtkRenderer]->ResetCameraClippingRange();
                            [vV setNeedsDisplay:YES];
                        }
                        
                        // *** rotation ***
                        rot = -(float)rz;
                        if( vV->projectionMode == 2) rot = (float)rz;
                        
                        float rotX, rotY;
                        rotX = [vV frame].size.width/2.0 + cos(rot/axis_max)*50.0;
                        rotY = [vV frame].size.height/2.0 + sin(rot/axis_max)*50.0;
                        [vV vtkCamera]->Roll(rot/axis_max*10.0);
                        [vV setNeedsDisplay:YES];
                        
                        // *** pan ***
                        if( vV->projectionMode != 2)
                        {
                            [vV panX:[vV frame].size.width/2.0+tx*1000.0 Y:[vV frame].size.height/2.0-ty*1000.0];
                            [vV setNeedsDisplay:YES];
                        }
                        // no pan for endoscopy mode
                        
                        // *** 3D rotation ***
                        if( vV->projectionMode != 2)
                        {
                            xPos = lastState.axis[4]-(float)ry/axis_max*50.0;
                            yPos = lastState.axis[3]-(float)rx/axis_max*50.0;
                            [vV getInteractor]->SetEventInformation((int)xPos, (int)yPos, 0, 0);
                            if( vV->snStopped)
                            {
                                [vV getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
                                vV->snStopped = NO;
                            }
                            else
                                [vV getInteractor]->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
                            state->axis[3] = yPos;
                            state->axis[4] = xPos;
                        }
                        else // endoscopy
                        {
                            if( vV->snStopped)
                            {
                                [vV getInteractor]->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
                                vV->snStopped = NO;
                            }
                            
                            [vV vtkCamera]->Yaw((float)ry/axis_max*8.0);
                            [vV vtkCamera]->Pitch((float)rx/axis_max*8.0);
                            [vV vtkCamera]->ComputeViewPlaneNormal();
                            [vV vtkCamera]->OrthogonalizeViewUp();
                            [vV vtkRenderer]->ResetCameraClippingRange();
                            [vV computeOrientationText];
                            [vV setNeedsDisplay:YES];
                        }
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:OsirixVRCameraDidChangeNotification object:vV userInfo:nil];
                        [vV computeOrientationText];
                        
                        [vV displayLowRes];
                        
                        vV->snCloseEventTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:vV selector:@selector(closeEvent:) userInfo:nil repeats:0] retain];
                        break;
                        
                    case kConnexionCmdHandleButtons:
                        if(state->buttons==0) // buttons released
                        {
                            [vV closeEvent:nil];
                        }
                        else if(state->buttons==1) // left button pressed
                        {
                            if( vV->projectionMode != 2) [vV coView:nil];
                            else [vV yaw:180.0];
                            [[NSNotificationCenter defaultCenter] postNotificationName:OsirixVRCameraDidChangeNotification object:vV userInfo:nil];
                        }
                        else if(state->buttons==2) // right button pressed
                        {
                            if( vV->projectionMode != 2) [vV saView:nil];
                            else [vV yaw:90.0];
                            [[NSNotificationCenter defaultCenter] postNotificationName:OsirixVRCameraDidChangeNotification object:vV userInfo:nil];
                        }
                        else if(state->buttons==3) // both button are presed
                        {
                            if( vV->projectionMode != 2) [vV saViewOpposite:nil];
                            [[NSNotificationCenter defaultCenter] postNotificationName:OsirixVRCameraDidChangeNotification object:vV userInfo:nil];
                        }
                        break;
                }
                
                memcpy( &lastState, state, (long)sizeof(ConnexionDeviceState));
            }
            break;
    }
    if(record) [vV recordFlyThru];
}
#else
- (void)connect2SpaceNavigator
{
}
#endif
@end
