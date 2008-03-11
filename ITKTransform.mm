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

#define id Id
#include "Accelerate.h"
#include "itkImage.h"
#include "itkImportImageFilter.h"
#include "itkAffineTransform.h"
#include "itkResampleImageFilter.h"
#undef id

#import "ITKTransform.h"
#import "DCMPix.h"
#import "WaitRendering.h"
#import "AppController.h"

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
	double	vectorReference[ 9];
	double	vectorOriginal[ 9];

	[firstObject orientationDouble: vectorReference];
	[firstObjectOriginal orientationDouble: vectorOriginal];

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
	
	origin[0] =  [firstObjectOriginal originX];
	origin[1] =  [firstObjectOriginal originY];
	origin[2] =  [firstObjectOriginal originZ];
	
	originConverted[ 0] = origin[ 0] * vectorOriginal[ 0] + origin[ 1] * vectorOriginal[ 1] + origin[ 2] * vectorOriginal[ 2];
	originConverted[ 1] = origin[ 0] * vectorOriginal[ 3] + origin[ 1] * vectorOriginal[ 4] + origin[ 2] * vectorOriginal[ 5];
	originConverted[ 2] = origin[ 0] * vectorOriginal[ 6] + origin[ 1] * vectorOriginal[ 7] + origin[ 2] * vectorOriginal[ 8];

	[itkImage itkImporter]->SetOrigin( originConverted );

	ResampleFilterType::Pointer resample = ResampleFilterType::New();
	
	resample->SetTransform(transform);
	resample->SetInput([itkImage itkImporter]->GetOutput());
	resample->SetDefaultPixelValue( [firstObjectOriginal minValueOfSeries]);
	
	double outputSpacing[3];
	outputSpacing[0] = [firstObject pixelSpacingX];
	outputSpacing[1] = [firstObject pixelSpacingY];
	outputSpacing[2] = [firstObject sliceInterval];
	
	if( outputSpacing[2] == 0 || noOfImages == 1)
		outputSpacing[2] = 1;
	
	resample->SetOutputSpacing(outputSpacing);
	
	double outputOrigin[3] = {0, 0, 0}, outputOriginConverted[3] = {0, 0, 0};
	
	outputOrigin[0] =  [firstObject originX];
	outputOrigin[1] =  [firstObject originY];
	outputOrigin[2] =  [firstObject originZ];
	
	outputOriginConverted[ 0] = outputOrigin[ 0] * vectorReference[ 0] + outputOrigin[ 1] * vectorReference[ 1] + outputOrigin[ 2] * vectorReference[ 2];
	outputOriginConverted[ 1] = outputOrigin[ 0] * vectorReference[ 3] + outputOrigin[ 1] * vectorReference[ 4] + outputOrigin[ 2] * vectorReference[ 5];
	outputOriginConverted[ 2] = outputOrigin[ 0] * vectorReference[ 6] + outputOrigin[ 1] * vectorReference[ 7] + outputOrigin[ 2] * vectorReference[ 8];
	
	resample->SetOutputOrigin( outputOriginConverted);
	
	ImageType::SizeType size;
	size[0] = [firstObject pwidth];
	size[1] = [firstObject pheight];
	size[2] = noOfImages;
	
	resample->SetSize(size);

//	int u, v;
//	// Display translation
//	printf ("\nTranslation:\n");
//	for (u = 0; u < 3; u++)
//		printf ("\t%3.2f", theParameters [9+u]);
//	printf ("\n\n");
//
//	// Display rotation
//	printf ("Rotation:\n");
//	for (u = 0; u < 3; u++)
//	{
//		for (v = 0; v < 3; v++)
//			printf ("\t%3.2f", theParameters [u*3+v]);
//		printf ("\n");
//	}
//	printf ("\n\n");
	
	WaitRendering *splash = 0L;
	
	if( noOfImages > 2)
		splash = [[WaitRendering alloc] init:NSLocalizedString(@"Resampling...", nil)];
	[splash showWindow:self];
	
	resample->Update();
	
	float* resultBuff = resample->GetOutput()->GetBufferPointer();
	
	[splash close];
	[splash release];

	long	mem = 0;
	for( i = 0; i < noOfImages; i++)
	{
		mem += [firstObject pheight] * [firstObject pwidth] * 4;
	}
	
	float *fVolumePtr = (float*) malloc( mem);
	if( fVolumePtr && resultBuff) 
	{
		memcpy( fVolumePtr, resultBuff, mem);
		*length = mem;
		
		return fVolumePtr;
	}
	else return 0L;
}

+ (float*) reorient2Dimage: (double*) theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*) firstObjectOriginal length: (long*) length
{
	float *p = 0L;
	int size = [firstObjectOriginal pwidth] * [firstObjectOriginal pheight];
	
	float *tempPtr = (float*) malloc( size * 2 * sizeof( float));
	
	if( tempPtr)
	{
		memcpy( tempPtr, [firstObjectOriginal fImage], size * sizeof( float));
		memcpy( tempPtr + size, [firstObjectOriginal fImage], size * sizeof( float));
		
		ITK *itk = [[ITK alloc] initWith: [NSArray arrayWithObjects: firstObjectOriginal, firstObjectOriginal, 0L] : tempPtr : -1];
		
		p = [ITKTransform resampleWithParameters: theParameters firstObject: firstObject firstObjectOriginal: firstObjectOriginal noOfImages: 1 length: length itkImage: itk];
		
		[itk release];
		
		free( tempPtr);
	}
	
	return p;
}

- (ViewerController*) computeAffineTransformWithParameters: (double*)theParameters resampleOnViewer:(ViewerController*)referenceViewer
{
	DCMPix *firstObject = [[referenceViewer pixList] objectAtIndex: 0];
	DCMPix *firstObjectOriginal = [[originalViewer pixList] objectAtIndex: 0];
	int noOfImages = [[referenceViewer pixList] count];
	long length;
	
	float *resultBuff = [ITKTransform resampleWithParameters: theParameters firstObject: firstObject firstObjectOriginal: firstObjectOriginal noOfImages: noOfImages length: &length itkImage: (ITK*) itkImage];
	
	return [self createNewViewerWithBuffer:resultBuff length: length resampleOnViewer:referenceViewer];
}

- (ViewerController*) createNewViewerWithBuffer:(float*)fVolumePtr length: (long) length resampleOnViewer:(ViewerController*)referenceViewer
{
	long				i;
	ViewerController	*new2DViewer = 0L;
	float				wl, ww;
	
	// First calculate the amount of memory needed for the new serie
	
	NSArray	*pixList = [referenceViewer pixList];
	DCMPix	*curPix;
	
	if( fVolumePtr) 
	{
		// Create a NSData object to control the new pointer
		NSData	*volumeData = [NSData dataWithBytesNoCopy: fVolumePtr length: length freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new buffer
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray *newFileList = [NSMutableArray arrayWithCapacity:0];
		
		DCMPix	*originalPix = [[originalViewer pixList] objectAtIndex: 0];
		wl = [originalPix wl];
		ww = [originalPix ww];
		
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[[pixList objectAtIndex: i] copy] autorelease];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * i)];
			
			// to keep settings propagated for MRI we need the old values for echotime & repetitiontime
			[curPix setEchotime: [originalPix echotime]];
			[curPix setRepetitiontime: [originalPix repetitiontime]];
			
			[curPix setSavedWL: [originalPix savedWL]];
			[curPix setSavedWW: [originalPix savedWW]];
			[curPix changeWLWW: wl : ww];
			
			// SUV
			[curPix setDisplaySUVValue: [originalPix displaySUVValue]];
			[curPix setSUVConverted: [originalPix SUVConverted]];
			[curPix setRadiopharmaceuticalStartTime: [originalPix radiopharmaceuticalStartTime]];
			[curPix setPatientsWeight: [originalPix patientsWeight]];
			[curPix setRadionuclideTotalDose: [originalPix radionuclideTotalDose]];
			[curPix setRadionuclideTotalDoseCorrected: [originalPix radionuclideTotalDoseCorrected]];
			[curPix setAcquisitionTime: [originalPix acquisitionTime]];
			[curPix setDecayCorrection: [originalPix decayCorrection]];
			[curPix setDecayFactor: [originalPix decayFactor]];
			[curPix setUnits: [originalPix units]];
			
			[newPixList addObject: curPix];
			[newFileList addObject:[[originalViewer fileList] objectAtIndex:0]];
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
		[new2DViewer propagateSettings];
		[new2DViewer setRegisteredViewer: referenceViewer];
	}
	else
	{
		if( NSRunCriticalAlertPanel(NSLocalizedString(@"Memory", nil),
								NSLocalizedString(@"Not enough memory to complete the operation.\r\rUpgrade to OsiriX 64-bit to solve this issue.", nil),
								NSLocalizedString(@"OK", nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
									[[AppController sharedAppController] osirix64bit: self];
	}
	
	return new2DViewer;
}

@end
