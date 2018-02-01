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

//#define id Id
#include <Accelerate/Accelerate.h>
#include <itkImage.h>
#include <itkImportImageFilter.h>
#include <itkAffineTransform.h>
#include <itkResampleImageFilter.h>
//#undef id

#import "ITKTransform.h"
#import "DCMPix.h"
#import "WaitRendering.h"
#import "AppController.h"
#import "ViewerController.h"
#import "DCMPix.h"
#import "N2Debug.h"

#include "options.h"

typedef itk::ResampleImageFilter<ImageType, ImageType> ResampleFilterType;

@implementation ITKTransform

- (id) initWithViewer: (ViewerController *) viewer;
{
	self = [super init];
	if (self != nil)
	{
		originalViewer = viewer;
		itkImage = [[ITK alloc] initWith:[originalViewer pixList] :[originalViewer volumePtr] : -1];
	}
	return self;
}

- (void) dealloc
{
	[itkImage release];
	[super dealloc];
}

+ (float*) resampleWithParameters: (double*)theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*)  firstObjectOriginal noOfImages: (int) noOfImages length: (long*) length itkImage: (ITK*) itkImage
{
    return [ITKTransform resampleWithParameters: theParameters firstObject: firstObject firstObjectOriginal: firstObjectOriginal noOfImages: noOfImages length: length itkImage: itkImage rescale: YES];
}

+ (float*) resampleWithParameters: (double*)theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*)  firstObjectOriginal noOfImages: (int) noOfImages length: (long*) length itkImage: (ITK*) itkImage rescale: (BOOL) rescale
{
	double vectorReference[ 9], vectorOriginal[ 9];
    float *fVolumePtr = nil;
    
	[firstObject orientationDouble: vectorReference];
	[firstObjectOriginal orientationDouble: vectorOriginal];
    
    WaitRendering *splash = nil;
    float* resultBuff = nil;
    
    try
    {
        @try
        {
            typedef itk::AffineTransform< double, 3 > AffineTransformType;
            typedef AffineTransformType::ParametersType ParametersType;
            
            AffineTransformType::Pointer transform = AffineTransformType::New();
            
            ParametersType parameters(transform->GetNumberOfParameters());
            
            int i;
            for(i=0; i<transform->GetNumberOfParameters(); i++)
            {
                parameters[i] = theParameters[i];
            }
            
            transform->SetParameters(parameters);
            
            double origin[ 3] = {0, 0, 0}, originConverted[ 3];
            
            // DICOM Origin is voxel center
            origin[0] =  [firstObjectOriginal originX] - firstObjectOriginal.pixelSpacingX/2.;
            origin[1] =  [firstObjectOriginal originY] - firstObjectOriginal.pixelSpacingY/2.;
            origin[2] =  [firstObjectOriginal originZ] - firstObjectOriginal.sliceThickness/2.;
            
            originConverted[ 0] = origin[ 0] * vectorOriginal[ 0] + origin[ 1] * vectorOriginal[ 1] + origin[ 2] * vectorOriginal[ 2];
            originConverted[ 1] = origin[ 0] * vectorOriginal[ 3] + origin[ 1] * vectorOriginal[ 4] + origin[ 2] * vectorOriginal[ 5];
            originConverted[ 2] = origin[ 0] * vectorOriginal[ 6] + origin[ 1] * vectorOriginal[ 7] + origin[ 2] * vectorOriginal[ 8];
            
            [itkImage itkImporter]->SetOrigin( originConverted );
            
            ResampleFilterType::Pointer resample = ResampleFilterType::New();
            
            resample->SetTransform(transform);
            resample->SetInput([itkImage itkImporter]->GetOutput());
            resample->SetDefaultPixelValue( [firstObjectOriginal minValueOfSeries]);
            
            double outputSpacing[3];
            
            if( rescale)
            {
                outputSpacing[0] = [firstObject pixelSpacingX];
                outputSpacing[1] = [firstObject pixelSpacingY];
                outputSpacing[2] = [firstObject sliceInterval];
            }
            else
            {
                outputSpacing[0] = [firstObjectOriginal pixelSpacingX];
                outputSpacing[1] = [firstObjectOriginal pixelSpacingY];
                outputSpacing[2] = [firstObject sliceInterval];
            }
            
            if( outputSpacing[2] == 0 || noOfImages == 1)
                outputSpacing[2] = 1;
            
            resample->SetOutputSpacing(outputSpacing);
            
            double outputOrigin[3] = {0, 0, 0}, outputOriginConverted[3] = {0, 0, 0};
            
            outputOrigin[0] =  [firstObject originX] - firstObject.pixelSpacingX/2.;
            outputOrigin[1] =  [firstObject originY] - firstObject.pixelSpacingY/2.;
            outputOrigin[2] =  [firstObject originZ] - firstObject.sliceThickness/2.;
            
            outputOriginConverted[ 0] = outputOrigin[ 0] * vectorReference[ 0] + outputOrigin[ 1] * vectorReference[ 1] + outputOrigin[ 2] * vectorReference[ 2];
            outputOriginConverted[ 1] = outputOrigin[ 0] * vectorReference[ 3] + outputOrigin[ 1] * vectorReference[ 4] + outputOrigin[ 2] * vectorReference[ 5];
            outputOriginConverted[ 2] = outputOrigin[ 0] * vectorReference[ 6] + outputOrigin[ 1] * vectorReference[ 7] + outputOrigin[ 2] * vectorReference[ 8];
            
            resample->SetOutputOrigin( outputOriginConverted);
            
            if( rescale)
            {
                ImageType::SizeType size;
                size[0] = [firstObject pwidth];
                size[1] = [firstObject pheight];
                size[2] = noOfImages;
                
                resample->SetSize(size);
            }
            else
            {
                ImageType::SizeType size;
                size[0] = [firstObjectOriginal pwidth];
                size[1] = [firstObjectOriginal pheight];
                size[2] = noOfImages;
                
                resample->SetSize(size);
            }
            if( noOfImages > 2)
                splash = [[WaitRendering alloc] init:NSLocalizedString(@"Resampling...", nil)];
            [splash showWindow:self];
            
            resample->Update();
            
            resultBuff = resample->GetOutput()->GetBufferPointer();
            
            long mem;
            if( rescale)
                mem = noOfImages * [firstObject pheight] * [firstObject pwidth] * sizeof(float);
            else
                mem = noOfImages * [firstObjectOriginal pheight] * [firstObjectOriginal pwidth] * sizeof(float);
            
            fVolumePtr = (float*) malloc( mem);
            if( fVolumePtr && resultBuff)
            {
                memcpy( fVolumePtr, resultBuff, mem);
                *length = mem;
            }
        }
        @catch (NSException *e)
        {
            N2LogException( e);
        }
    }
    catch (...)
    {
        N2LogStackTrace( @"C++ exception");
    }
    
	[splash close];
	[splash autorelease];
	
    return fVolumePtr;
}

+ (float*) reorient2Dimage: (double*) theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*) firstObjectOriginal length: (long*) length
{
	float *p = nil;
	int size = [firstObjectOriginal pwidth] * [firstObjectOriginal pheight];
	
	float *tempPtr = (float*) malloc( size * 2 * sizeof( float));
	
	if( tempPtr)
	{
		memcpy( tempPtr, [firstObjectOriginal fImage], size * sizeof( float));
		memcpy( tempPtr + size, [firstObjectOriginal fImage], size * sizeof( float));
		
		ITK *itk = [[ITK alloc] initWith: [NSArray arrayWithObjects: firstObjectOriginal, firstObjectOriginal, nil] : tempPtr : -2];
		
		p = [ITKTransform resampleWithParameters: theParameters firstObject: firstObject firstObjectOriginal: firstObjectOriginal noOfImages: 1 length: length itkImage: itk];
		
		[itk release];
		
		free( tempPtr);
	}
	
	return p;
}

- (ViewerController*) computeAffineTransformWithParameters: (double*)theParameters resampleOnViewer:(ViewerController*)referenceViewer
{
    return [self computeAffineTransformWithParameters: theParameters resampleOnViewer: referenceViewer rescale: [[NSUserDefaults standardUserDefaults] boolForKey: @"RescaleDuring3DResampling"]];
}

- (ViewerController*) computeAffineTransformWithParameters: (double*)theParameters resampleOnViewer:(ViewerController*)referenceViewer rescale: (BOOL) rescale
{
	DCMPix *firstObject = [[referenceViewer pixList] objectAtIndex: 0];
	DCMPix *firstObjectOriginal = [[originalViewer pixList] objectAtIndex: 0];
	int noOfImages = [[referenceViewer pixList] count];
	long length;
	
	float *resultBuff = [ITKTransform resampleWithParameters: theParameters firstObject: firstObject firstObjectOriginal: firstObjectOriginal noOfImages: noOfImages length: &length itkImage: (ITK*) itkImage rescale: rescale];
	
	ViewerController *v = [self createNewViewerWithBuffer:resultBuff length: length resampleOnViewer:referenceViewer rescale: rescale];
    
    return v;
}

- (ViewerController*) createNewViewerWithBuffer:(float*)fVolumePtr length: (long) length resampleOnViewer:(ViewerController*)referenceViewer
{
    return [self createNewViewerWithBuffer: fVolumePtr length: length resampleOnViewer: referenceViewer rescale: YES];
}

- (ViewerController*) createNewViewerWithBuffer:(float*)fVolumePtr length: (long) length resampleOnViewer:(ViewerController*)referenceViewer rescale: (BOOL) rescale
{
	long				i;
	ViewerController	*new2DViewer = nil;
	float				wl, ww;
	
	// First calculate the amount of memory needed for the new serie
	
	NSArray	*pixList = [referenceViewer pixList];
	DCMPix	*curPix;
	
	if( fVolumePtr) 
	{
		// Create a NSData object to control the new pointer
		NSData	*volumeData = [NSData dataWithBytesNoCopy: fVolumePtr length: length freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new buffer
		NSMutableArray *newPixList = [NSMutableArray array];
		NSMutableArray *newFileList = [NSMutableArray array];
		
		DCMPix	*originalPix = [[originalViewer pixList] objectAtIndex: 0];
		wl = [originalPix wl];
		ww = [originalPix ww];
		
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[[pixList objectAtIndex: i] copy] autorelease];
			
            if( rescale)
                [curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * i)];
			else
            {
                [curPix setfImage: (float*) (fVolumePtr + originalPix.pheight * originalPix.pwidth * i)];
                [curPix setPwidth: originalPix.pwidth];
				[curPix setPheight: originalPix.pheight];
                [curPix setPixelSpacingX: originalPix.pixelSpacingX];
                [curPix setPixelSpacingY: originalPix.pixelSpacingY];
                [curPix kill8bitsImage];
            }
			
			// to keep settings propagated for MRI we need the old values for echotime & repetitiontime
            
			[curPix setSavedWL: [originalPix savedWL]];
			[curPix setSavedWW: [originalPix savedWW]];
			[curPix changeWLWW: wl : ww];
			
            [curPix setAcquisitionDate: [originalPix acquisitionDate]];
            [curPix setAcquisitionTime: [originalPix acquisitionTime]];
            
			// SUV
			[curPix setDisplaySUVValue: [originalPix displaySUVValue]];
			[curPix setSUVConverted: [originalPix SUVConverted]];
			[curPix setFactorPET2SUV: [originalPix factorPET2SUV]];
			[curPix setRadiopharmaceuticalStartTime: [originalPix radiopharmaceuticalStartTime]];
			[curPix setPatientsWeight: [originalPix patientsWeight]];
			[curPix setRadionuclideTotalDose: [originalPix radionuclideTotalDose]];
			[curPix setRadionuclideTotalDoseCorrected: [originalPix radionuclideTotalDoseCorrected]];
			[curPix setDecayCorrection: [originalPix decayCorrection]];
			[curPix setDecayFactor: [originalPix decayFactor]];
			[curPix setUnits: [originalPix units]];
			
			[curPix setImageObjectID: [originalPix imageObjectID]];
            curPix.srcFile = originalPix.srcFile;
            
            curPix.yearOld = originalPix.yearOld;
            curPix.yearOldAcquisition = originalPix.yearOldAcquisition;
            
			curPix.annotationsDictionary = originalPix.annotationsDictionary;
            curPix.annotationsDBFields = originalPix.annotationsDBFields;
            
            DicomImage *dicomObject = [[originalViewer fileList] objectAtIndex:0];
            
			[newPixList addObject: curPix];
			[newFileList addObject: dicomObject];
            
            [curPix reloadAnnotations];
		}
		
		if( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
		{
			new2DViewer = [ViewerController newWindow:newPixList :newFileList :volumeData];
		}
		else
		{
			// Close original viewer
			BOOL prefTileWindows = [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"];
		
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"AUTOTILING"];
		
			NSRect f = [[originalViewer window] frame];
			[[originalViewer window] close]; 
			
			new2DViewer = [ViewerController newWindow:newPixList :newFileList :volumeData frame: f];
			
			[[NSUserDefaults standardUserDefaults] setBool:prefTileWindows forKey: @"AUTOTILING"];
		}
		
		[[new2DViewer window] makeKeyAndOrderFront: self];
		[new2DViewer setWL: wl WW: ww];
		[referenceViewer propagateSettings]; // avolz: previously [new2DViewer propagateSettings], the consequence was that both the reference and the new viewer were awkwardly zoomed in - by propagating the untouched viewer's settings the user will get what he was viewing before the fusion
		[new2DViewer setRegisteredViewer: referenceViewer];
	}
	else
	{
		if( NSRunCriticalAlertPanel(NSLocalizedString(@"32-bit", nil),
								NSLocalizedString(@"Cannot complete the operation.\r\rUpgrade to Horos 64-bit or Horos MD to solve this issue.", nil),
								NSLocalizedString(@"OK", nil), NSLocalizedString(@"Horos 64-bit", nil), nil) == NSAlertAlternateReturn)
									[[AppController sharedAppController] osirix64bit: self];
	}
	
	return new2DViewer;
}

@end
