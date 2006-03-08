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
#undef id

#import "ITKTransform.h"

@implementation ITKTransform

- (id) initWithDCMPix: (DCMPix *) pix
{
	self = [super init];
	if (self != nil)
	{
		originalPix = pix;
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) computeAffineTransformWithRotation: (double*)aRotation translation: (double*)aTranslation
{
	double *parameters = (double*) malloc(12*sizeof(double));
	
	// rotation matrix
	parameters[0]=aRotation[0]; parameters[1]=aRotation[1]; parameters[2]=aRotation[2];
	parameters[3]=aRotation[3]; parameters[4]=aRotation[4]; parameters[5]=aRotation[6];
	parameters[6]=aRotation[6]; parameters[7]=aRotation[7]; parameters[8]=aRotation[8];
	
	// translation vector
	parameters[9]=aTranslation[0]; parameters[10]=aTranslation[1]; parameters[11]=aTranslation[2];
	
	[self computeAffineTransformWithParameters: parameters];
	free(parameters);
}

- (void) computeAffineTransformWithParameters: (double*)theParameters
{
	typedef itk::AffineTransform< itkPixelType, 3 > AffineTransformType;
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
}

@end
