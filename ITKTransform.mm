//
//  ITKTransform.mm
//  OsiriX
//
//  Created by joris on 08/03/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//
#define id Id
#include "Accelerate.h"
#include "itkImage.h"
#include "itkImportImageFilter.h"
#include "itkAffineTransform.h"
#include "itkResampleImageFilter.h"
#undef id

#import "ITKTransform.h"
#import "DCMPix.h"

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

/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/

- (void) computeAffineTransformWithRotation: (double*)aRotation translation: (double*)aTranslation resampleOnViewer:(ViewerController*)referenceViewer
{
	double *parameters = (double*) malloc(12*sizeof(double));
	
	// rotation matrix
	parameters[0]=aRotation[0]; parameters[1]=aRotation[1]; parameters[2]=aRotation[2];
	parameters[3]=aRotation[3]; parameters[4]=aRotation[4]; parameters[5]=aRotation[5];
	parameters[6]=aRotation[6]; parameters[7]=aRotation[7]; parameters[8]=aRotation[8];
	
	// translation vector
	parameters[9]=aTranslation[0]; parameters[10]=aTranslation[1]; parameters[11]=aTranslation[2];

//	// rotation matrix
//	parameters[0]=1.0; parameters[1]=0.0; parameters[2]=0.0;
//	parameters[3]=0.0; parameters[4]=1.0; parameters[5]=0.0;
//	parameters[6]=0.0; parameters[7]=0.0; parameters[8]=1.0;
//	
//	// translation vector
//	parameters[9]=0.0; parameters[10]=0.0; parameters[11]=0.0;
	
	[self computeAffineTransformWithParameters: parameters resampleOnViewer:referenceViewer];
	free(parameters);
}

- (void) computeAffineTransformWithParameters: (double*)theParameters resampleOnViewer:(ViewerController*)referenceViewer
{
	typedef itk::AffineTransform< double, 3 > AffineTransformType;
	typedef AffineTransformType::ParametersType ParametersType;
	
	AffineTransformType::Pointer transform = AffineTransformType::New();
	
	ParametersType parameters(transform->GetNumberOfParameters());
	
	int i;
	for(i=0; i<transform->GetNumberOfParameters(); i++)
	{
		parameters[i] = theParameters[i];
		//NSLog(@"parameters[%d], %f",i,parameters[i]);
	}
	
	transform->SetParameters(parameters);

	ResampleFilterType::Pointer resample = ResampleFilterType::New();

	resample->SetTransform(transform);
	resample->SetInput([itkImage itkImporter]->GetOutput());
	resample->SetDefaultPixelValue(-1024.0);	
	
	double outputSpacing[3];
	outputSpacing[0] = [[referenceViewer imageView] pixelSpacingX];
	outputSpacing[1] = [[referenceViewer imageView] pixelSpacingY];
	outputSpacing[2] = [referenceViewer computeInterval];
	resample->SetOutputSpacing(outputSpacing);
	
	double outputOrigin[3], outputOriginConverted[3];	
	outputOrigin[0] = [[[referenceViewer pixList] objectAtIndex: 0] originX];// - [[[originalViewer pixList] objectAtIndex: 0] originX];
	outputOrigin[1] = [[[referenceViewer pixList] objectAtIndex: 0] originY];// - [[[originalViewer pixList] objectAtIndex: 0] originY];
	outputOrigin[2] = [[[referenceViewer pixList] objectAtIndex: 0] originZ];// - [[[originalViewer pixList] objectAtIndex: 0] originZ];

	outputOriginConverted[ 0] = outputOrigin[ 0] * theParameters[ 0] + outputOrigin[ 1] * theParameters[ 1] + outputOrigin[ 2] * theParameters[ 2];
	outputOriginConverted[ 1] = outputOrigin[ 0] * theParameters[ 3] + outputOrigin[ 1] * theParameters[ 4] + outputOrigin[ 2] * theParameters[ 5];
	outputOriginConverted[ 2] = outputOrigin[ 0] * theParameters[ 6] + outputOrigin[ 1] * theParameters[ 7] + outputOrigin[ 2] * theParameters[ 8];

	resample->SetOutputOrigin( outputOriginConverted);
	
	ImageType::SizeType size;
	size[0] = [[[referenceViewer pixList] objectAtIndex: 0] pwidth];
	size[1] = [[[referenceViewer pixList] objectAtIndex: 0] pheight];
	size[2] = [[referenceViewer pixList] count];
	resample->SetSize(size);

	int u, v;
	// Display translation
	printf ("\nTranslation:\n");
	for (u = 0; u < 3; u++)
		printf ("\t%3.2f", theParameters [9+u]);
	printf ("\n\n");

	// Display rotation
	printf ("Rotation:\n");
	for (u = 0; u < 3; u++)
	{
		for (v = 0; v < 3; v++)
			printf ("\t%3.2f", theParameters [u*3+v]);
		printf ("\n");
	}
	printf ("\n\n");
	
	NSLog(@"start transform");
	resample->Update();
	
	float* resultBuff = resample->GetOutput()->GetBufferPointer();
	
	NSLog(@"transform done");
		
	[self createNewViewerWithBuffer:resultBuff resampleOnViewer:referenceViewer];
}

- (void) createNewViewerWithBuffer:(float*)aBuffer resampleOnViewer:(ViewerController*)referenceViewer
{
	long				i;
	ViewerController	*new2DViewer;
	float				*fVolumePtr;
	
//	// First calculate the amount of memory needed for the new serie
	NSArray	*pixList = [referenceViewer pixList];
	//NSArray	*pixList = [originalViewer pixList];
	DCMPix	*curPix;
	long	mem = 0;
	
	NSLog(@"[pixList count] : %d", [pixList count]);
	
	for( i = 0; i < [pixList count]; i++)
	{
		curPix = [pixList objectAtIndex: i];
		mem += [curPix pheight] * [curPix pwidth] * 4;		// each pixel contains either a 32-bit float or a 32-bit ARGB value
	}
	
	NSLog(@"size : %d x %d x %d", [[pixList objectAtIndex:0] pwidth], [[pixList objectAtIndex:0] pheight], [pixList count]);
	NSLog(@"mem : %d", mem);
	
	fVolumePtr = (float*) malloc(mem);
	if( fVolumePtr && aBuffer)//&& NO) // '&& NO' because it doesn't work yet. Just a security...
	{
		// Copy the source series in the new one !
		memcpy(fVolumePtr,aBuffer,mem);
		NSLog(@"BlockMoveData OK");
		
		// Create a NSData object to control the new pointer
		NSData	*volumeData = [[NSData alloc] initWithBytesNoCopy:aBuffer length:mem freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new buffer
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < [pixList count]; i++)
		//for( i = 0; i < [[originalViewer pixList] count]; i++)
		{
			curPix = [[[pixList objectAtIndex: i] copy] autorelease];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * i)];
			
			// to keep settings propagated for MRI we need the old values for echotime & repetitiontime
			[curPix setEchotime: [[[originalViewer pixList] objectAtIndex: i] echotime]];
			[curPix setRepetitiontime: [[[originalViewer pixList] objectAtIndex: i] repetitiontime]];
			
//			curPix = [[DCMPix alloc] initwithdata	: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * i)
//													: 32
//													: [[pixList objectAtIndex: i] pwidth]
//													: [[pixList objectAtIndex: i] pheight]
//													: [[pixList objectAtIndex: i] pixelSpacingX]
//													: [[pixList objectAtIndex: i] pixelSpacingY]
//													: [[pixList objectAtIndex: i] originX]
//													: [[pixList objectAtIndex: i] originY]
//													: [[pixList objectAtIndex: i] originZ]];

			[newPixList addObject: curPix];
			//NSLog(@"[curPix sliceLocation] : %f", [curPix sliceLocation]);
		}
		
		NSLog(@"i : %d", i);
		
		// We don't need to duplicate the DicomFile array, because it is identical!
		// just make sure we have the same amout of DicomFile than DCMPix
		NSMutableArray *newFileList = [NSMutableArray arrayWithCapacity:0];
		if([pixList count]<=[[originalViewer fileList] count])
		{
			for( i = 0; i < [pixList count]; i++)
			{
				[newFileList addObject:[[originalViewer fileList] objectAtIndex:i]];
			}
		}
		else
		{
//			for( i = 0; i < [[originalViewer fileList] count]; i++)
//			{
//				[newFileList addObject:[[originalViewer fileList] objectAtIndex:i]];
//			}
//			for( i = [[originalViewer fileList] count]; i < [pixList count]; i++)
//			{
//				[newFileList addObject:[[originalViewer fileList] objectAtIndex:[[originalViewer fileList] count]-1]];
//			}
			for( i = 0; i < [pixList count]; i++)
			{
				[newFileList addObject:[[originalViewer fileList] objectAtIndex:0]];
			}
		}
		
		// A 2D Viewer window needs 3 things:
		// A mutable array composed of DCMPix objects
		// A mutable array composed of DicomFile objects
		// Number of DCMPix and DicomFile has to be EQUAL !
		// NSData volumeData contains the images, represented in the DCMPix objects
		new2DViewer = [originalViewer newWindow:newPixList :newFileList :volumeData];
	}
}

@end
