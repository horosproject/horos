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
	
	double translation[ 3];
	
	translation[ 0] = theParameters[ 9];
	translation[ 1] = theParameters[ 10];
	translation[ 2] = theParameters[ 11];
	
	theParameters[ 9] = translation[ 0] * theParameters[ 0] + translation[ 1] * theParameters[ 1] + translation[ 2] * theParameters[ 2];
	theParameters[ 10] = translation[ 0] * theParameters[ 3] + translation[ 1] * theParameters[ 4] + translation[ 2] * theParameters[ 5];
	theParameters[ 11] = translation[ 0] * theParameters[ 6] + translation[ 1] * theParameters[ 7] + translation[ 2] * theParameters[ 8];


	double	vectorReference[ 9];
	double	vectorOriginal[ 9];

	[[[referenceViewer pixList] objectAtIndex: 0] orientationDouble: vectorReference];
	[[[originalViewer pixList] objectAtIndex: 0] orientationDouble: vectorOriginal];
	
	DCMPix *firstObject = [[referenceViewer pixList] objectAtIndex: 0];


	int i;
	for(i=0; i<transform->GetNumberOfParameters(); i++)
	{
		parameters[i] = theParameters[i];
	}
	
	transform->SetParameters(parameters);

	ResampleFilterType::Pointer resample = ResampleFilterType::New();

	double origin[ 3] = {0, 0, 0}, originConverted[ 3];
	
	origin[0] =  [[[originalViewer pixList] objectAtIndex: 0] originX];
	origin[1] =  [[[originalViewer pixList] objectAtIndex: 0] originY];
	origin[2] =  [[[originalViewer pixList] objectAtIndex: 0] originZ];
	
	originConverted[ 0] = origin[ 0] * vectorOriginal[ 0] + origin[ 1] * vectorOriginal[ 1] + origin[ 2] * vectorOriginal[ 2];
	originConverted[ 1] = origin[ 0] * vectorOriginal[ 3] + origin[ 1] * vectorOriginal[ 4] + origin[ 2] * vectorOriginal[ 5];
	originConverted[ 2] = origin[ 0] * vectorOriginal[ 6] + origin[ 1] * vectorOriginal[ 7] + origin[ 2] * vectorOriginal[ 8];

	[itkImage itkImporter]->SetOrigin( originConverted );

	resample->SetTransform(transform);
	resample->SetInput([itkImage itkImporter]->GetOutput());
	resample->SetDefaultPixelValue(-1024.0);
	
	
	double outputSpacing[3];
	outputSpacing[0] = [firstObject pixelSpacingX];
	outputSpacing[1] = [firstObject pixelSpacingY];
	outputSpacing[2] = [firstObject sliceInterval];
	resample->SetOutputSpacing(outputSpacing);
	
	double outputOrigin[3] = {0, 0, 0}, outputOriginConverted[3] = {0, 0, 0};
	
	outputOrigin[0] =  [firstObject originX];
	outputOrigin[1] =  [firstObject originY];
	outputOrigin[2] =  [firstObject originZ];
	
	outputOriginConverted[ 0] = outputOrigin[ 0] * vectorReference[ 0] + outputOrigin[ 1] * vectorReference[ 1] + outputOrigin[ 2] * vectorReference[ 2];
	outputOriginConverted[ 1] = outputOrigin[ 0] * vectorReference[ 3] + outputOrigin[ 1] * vectorReference[ 4] + outputOrigin[ 2] * vectorReference[ 5];
	outputOriginConverted[ 2] = outputOrigin[ 0] * vectorReference[ 6] + outputOrigin[ 1] * vectorReference[ 7] + outputOrigin[ 2] * vectorReference[ 8];
	
	NSLog( @"%f %f %f", outputOrigin[ 0], outputOrigin[ 1], outputOrigin[ 2]);
	NSLog( @"%f %f %f", outputOriginConverted[ 0], outputOriginConverted[ 1], outputOriginConverted[ 2]);
	
	resample->SetOutputOrigin( outputOriginConverted);
	
	ImageType::SizeType size;
	size[0] = [firstObject pwidth];
	size[1] = [firstObject pheight];
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
	
	itk::Point<double, 3> tmp;

	double *newOrigin;
	
	tmp = resample->GetOutput()->GetOrigin();
	
	NSLog( @"%f %f %f", tmp[ 0], tmp[ 1], tmp[ 2]);
	
	NSLog(@"transform done");
		
	[self createNewViewerWithBuffer:resultBuff resampleOnViewer:referenceViewer];
}

- (void) createNewViewerWithBuffer:(float*)aBuffer resampleOnViewer:(ViewerController*)referenceViewer
{
	long				i;
	ViewerController	*new2DViewer;
	float				*fVolumePtr;
	
	// First calculate the amount of memory needed for the new serie
	NSArray	*pixList = [referenceViewer pixList];
	DCMPix	*curPix;
	long	mem = 0;
	
	NSLog(@"[pixList count] : %d", [pixList count]);
	
	for( i = 0; i < [pixList count]; i++)
	{
		curPix = [pixList objectAtIndex: i];
		mem += [curPix pheight] * [curPix pwidth] * 4;		// each pixel contains either a 32-bit float or a 32-bit ARGB value
	}
	
	fVolumePtr = (float*) malloc(mem);
	if( fVolumePtr && aBuffer) 
	{
		// Copy the source series in the new one !
		memcpy(fVolumePtr,aBuffer,mem);
		
		// Create a NSData object to control the new pointer
		NSData	*volumeData = [NSData dataWithBytesNoCopy:fVolumePtr length:mem freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new buffer
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray *newFileList = [NSMutableArray arrayWithCapacity:0];
		
		DCMPix	*originalPix = [[originalViewer pixList] objectAtIndex: 0];
		
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[[pixList objectAtIndex: i] copy] autorelease];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * i)];
			
			// to keep settings propagated for MRI we need the old values for echotime & repetitiontime
//			[curPix setEchotime: [originalPix echotime]];
//			[curPix setRepetitiontime: [originalPix repetitiontime]];
//
//			// SUV
//			[curPix setDisplaySUVValue: [originalPix displaySUVValue]];
//			[curPix setSUVConverted: [originalPix SUVConverted]];
//			[curPix setRadiopharmaceuticalStartTime: [originalPix radiopharmaceuticalStartTime]];
//			[curPix setPatientsWeight: [originalPix patientsWeight]];
//			[curPix setRadionuclideTotalDose: [originalPix radionuclideTotalDose]];
//			[curPix setRadionuclideTotalDoseCorrected: [originalPix radionuclideTotalDoseCorrected]];
//			[curPix setAcquisitionTime: [originalPix acquisitionTime]];
//			[curPix setDecayCorrection: [originalPix decayCorrection]];
//			[curPix setDecayFactor: [originalPix decayFactor]];
//			[curPix setUnits: [originalPix units]];
			
			[newPixList addObject: curPix];
			[newFileList addObject:[[originalViewer fileList] objectAtIndex:0]];
		}
		
		new2DViewer = [originalViewer newWindow:newPixList :newFileList :volumeData];
	}
}

@end
