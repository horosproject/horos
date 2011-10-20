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

#import "pluginSDKAdditions.h"
#import "OSIEnvironment.h"
#import "OSIVolumeWindow.h"
#import "OSIFloatVolumeData.h"
#import "N3Geometry.h"

@interface DCMPix (PrivatePluginSDKAdditions)
- (BOOL)_testOrientationMatrix:(double[9])orientationMatrix; // returns YES if the orientation matrix's determinant is non-zero
@end

@implementation ViewerController (PluginSDKAdditions)

- (OSIVolumeWindow *)volumeWindow
{
	return [[OSIEnvironment sharedEnvironment] volumeWindowForViewerController:self];
}

//- (OSIFloatVolumeData *)floatVolumeDataForMovieIndex:(long)index
//{
//	return [[[OSIFloatVolumeData alloc] initWithWithPixList:pixList[index] volume:volumeData[index]] autorelease];
//}

@end


@implementation DCMPix (PluginSDKAdditions)

- (N3AffineTransform)pixToDicomTransform // converts points in the DCMPix's coordinate space ("Slice Coordinates") into the DICOM space (patient space with mm units)
{
    N3AffineTransform pixToDicomTransform;
    double spacingX;
    double spacingY;
    //    double spacingZ;
    double pixOrientation[9];
    
    memset(pixOrientation, 0, sizeof(double) * 9);
    [self orientationDouble:pixOrientation];
    
    if ([self _testOrientationMatrix:pixOrientation] == NO) {
        memset(pixOrientation, 0, sizeof(double)*9);
        pixOrientation[0] = pixOrientation[4] = pixOrientation[8] = 1;
    }
    
    spacingX = [self pixelSpacingX];
    spacingY = [self pixelSpacingY];
    //    spacingZ = pix.sliceInterval;
    
    pixToDicomTransform = N3AffineTransformIdentity;
    pixToDicomTransform.m41 = [self originX];
    pixToDicomTransform.m42 = [self originY];
    pixToDicomTransform.m43 = [self originZ];
    pixToDicomTransform.m11 = pixOrientation[0]*spacingX;
    pixToDicomTransform.m12 = pixOrientation[1]*spacingX;
    pixToDicomTransform.m13 = pixOrientation[2]*spacingX;
    pixToDicomTransform.m21 = pixOrientation[3]*spacingY;
    pixToDicomTransform.m22 = pixOrientation[4]*spacingY;
    pixToDicomTransform.m23 = pixOrientation[5]*spacingY;
    pixToDicomTransform.m31 = pixOrientation[6];
    pixToDicomTransform.m32 = pixOrientation[7];
    pixToDicomTransform.m33 = pixOrientation[8];
    
    return pixToDicomTransform;
}

@end

@implementation DCMPix (PrivatePluginSDKAdditions)

- (BOOL)_testOrientationMatrix:(double[9])orientationMatrix // returns YES if the orientation matrix's determinant is non-zero
{
    N3AffineTransform transform;
    
    transform = N3AffineTransformIdentity;
    transform.m11 = orientationMatrix[0];
    transform.m12 = orientationMatrix[1];
    transform.m13 = orientationMatrix[2];
    transform.m21 = orientationMatrix[3];
    transform.m22 = orientationMatrix[4];
    transform.m23 = orientationMatrix[5];
    transform.m31 = orientationMatrix[6];
    transform.m32 = orientationMatrix[7];
    transform.m33 = orientationMatrix[8];
    
    return N3AffineTransformDeterminant(transform) != 0.0;
}

@end