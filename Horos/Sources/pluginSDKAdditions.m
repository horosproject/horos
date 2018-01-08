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
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
