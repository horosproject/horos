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
	parameters[3]=aRotation[3]; parameters[4]=aRotation[4]; parameters[5]=aRotation[6];
	parameters[6]=aRotation[6]; parameters[7]=aRotation[7]; parameters[8]=aRotation[8];
	
	// translation vector
	parameters[9]=aTranslation[0]; parameters[10]=aTranslation[1]; parameters[11]=aTranslation[2];
	
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
	for(i=0; i<12; i++)
	{
		parameters[i] = theParameters[i];
		NSLog(@"parameters[%d], %f",i,parameters[i]);
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
	
	double outputOrigin[3];
	outputOrigin[0] = [[[referenceViewer pixList] objectAtIndex: 0] originX];
	outputOrigin[1] = [[[referenceViewer pixList] objectAtIndex: 0] originY];
	outputOrigin[2] = [[[referenceViewer pixList] objectAtIndex: 0] originZ];	
	resample->SetOutputOrigin(outputOrigin);
	
	ImageType::SizeType size;
	size[0] = [[[referenceViewer pixList] objectAtIndex: 0] pwidth];
	size[1] = [[[referenceViewer pixList] objectAtIndex: 0] pheight];
	size[2] = [[referenceViewer pixList] count];
		
	resample->Update();
	
	float* resultBuff = resample->GetOutput()->GetBufferPointer();

	[self createNewViewerWithBuffer:resultBuff resampleOnViewer:referenceViewer];
}

- (void) createNewViewerWithBuffer:(float*)aBuffer resampleOnViewer:(ViewerController*)referenceViewer
{
	long				i;
	ViewerController	*new2DViewer;
	float				*fVolumePtr;
	
//	// First calculate the amount of memory needed for the new serie
	NSArray	*pixList = [referenceViewer pixList];		
	DCMPix	*curPix;
	long	mem = 0;
	
	for( i = 0; i < [pixList count]; i++)
	{
		curPix = [pixList objectAtIndex: i];
		mem += [curPix pheight] * [curPix pwidth] * sizeof(float);		// each pixel contains either a 32-bit float or a 32-bit ARGB value
	}
	NSLog(@"size : %d x %d x %d", [[pixList objectAtIndex:0] pwidth], [[pixList objectAtIndex:0] pheight], [pixList count]);
	NSLog(@"mem : %d", mem);
	
	fVolumePtr = (float*) malloc(mem);	// ALWAYS use malloc for allocating memory !
	if( fVolumePtr && aBuffer && NO) // '&& NO' because it doesn't work yet. Just a security...
	{
		// Copy the source series in the new one !
		//memcpy(fVolumePtr, aBuffer, mem);
		BlockMoveData(aBuffer,fVolumePtr,mem);
		NSLog(@"BlockMoveData OK");
		
		// Create a NSData object to control the new pointer
		NSData	*volumeData = [[NSData alloc] initWithBytesNoCopy:aBuffer length:mem freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new buffer
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[pixList objectAtIndex: i] copy];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * 4 * i)];
			[newPixList addObject: curPix];
		}
		
		// We don't need to duplicate the DicomFile array, because it is identical!
		
		// A 2D Viewer window needs 3 things:
		// A mutable array composed of DCMPix objects
		// A mutable array composed of DicomFile objects
		// Number of DCMPix and DicomFile has to be EQUAL !
		// NSData volumeData contains the images, represented in the DCMPix objects
		new2DViewer = [originalViewer newWindow:newPixList :[originalViewer fileList] :volumeData];
	}
}

@end
