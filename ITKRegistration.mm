/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/





#define id Id
#include "itkImageRegistrationMethod.h"
#include "itkTranslationTransform.h"
#include "itkMeanSquaresImageToImageMetric.h"
#include "itkLinearInterpolateImageFunction.h"
#include "itkRegularStepGradientDescentOptimizer.h"
#include "itkImage.h"

#include "itkMesh.h"
#include "itkImportImageFilter.h"
#include "itkConnectedThresholdImageFilter.h"
#include "itkCurvatureFlowImageFilter.h"
#include "itkCastImageFilter.h"
#include "itkBinaryMaskToNarrowBandPointSetFilter.h"
//#include "itkBinaryMask3DMeshSource.h"
#include "itkVTKImageExport.h"
#include "itkVTKImageExportBase.h"

#include "vtkImageImport.h"
#include "vtkMarchingSquares.h"
#include "vtkPolyData.h"
#include "vtkCleanPolyData.h"
#include "vtkPolyDataConnectivityFilter.h"
#include "vtkCell.h"
#include "vtkContourFilter.h"
#include "vtkImageData.h"
#undef id

#import "ViewerController.h"
#import "WaitRendering.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"

#import "ITKRegistration.h"

/**
 * This function will connect the given itk::VTKImageExport filter to
 * the given vtkImageImport filter.
 */
template <typename ITK_Exporter, typename VTK_Importer>
void ConnectPipelines(ITK_Exporter exporter, VTK_Importer* importer)
{
  importer->SetUpdateInformationCallback(exporter->GetUpdateInformationCallback());
  importer->SetPipelineModifiedCallback(exporter->GetPipelineModifiedCallback());
  importer->SetWholeExtentCallback(exporter->GetWholeExtentCallback());
  importer->SetSpacingCallback(exporter->GetSpacingCallback());
  importer->SetOriginCallback(exporter->GetOriginCallback());
  importer->SetScalarTypeCallback(exporter->GetScalarTypeCallback());
  importer->SetNumberOfComponentsCallback(exporter->GetNumberOfComponentsCallback());
  importer->SetPropagateUpdateExtentCallback(exporter->GetPropagateUpdateExtentCallback());
  importer->SetUpdateDataCallback(exporter->GetUpdateDataCallback());
  importer->SetDataExtentCallback(exporter->GetDataExtentCallback());
  importer->SetBufferPointerCallback(exporter->GetBufferPointerCallback());
  importer->SetCallbackUserData(exporter->GetCallbackUserData());
}

//template <typename VTK_Exporter, typename ITK_Importer>
//void ConnectPipelines(VTK_Exporter* exporter, ITK_Importer importer)
//{
//  importer->SetUpdateInformationCallback(exporter->GetUpdateInformationCallback());
//  importer->SetPipelineModifiedCallback(exporter->GetPipelineModifiedCallback());
//  importer->SetWholeExtentCallback(exporter->GetWholeExtentCallback());
//  importer->SetSpacingCallback(exporter->GetSpacingCallback());
//  importer->SetOriginCallback(exporter->GetOriginCallback());
//  importer->SetScalarTypeCallback(exporter->GetScalarTypeCallback());
//  importer->SetNumberOfComponentsCallback(exporter->GetNumberOfComponentsCallback());
//  importer->SetPropagateUpdateExtentCallback(exporter->GetPropagateUpdateExtentCallback());
//  importer->SetUpdateDataCallback(exporter->GetUpdateDataCallback());
//  importer->SetDataExtentCallback(exporter->GetDataExtentCallback());
//  importer->SetBufferPointerCallback(exporter->GetBufferPointerCallback());
//  importer->SetCallbackUserData(exporter->GetCallbackUserData());
//}

@implementation ITKRegistration

-(void) dealloc
{
	[itkImageFix dealloc];
	[itkImageMoving dealloc];
	
	[super dealloc];
}

- (id) initWithViewers: (ViewerController*) fV :(ViewerController*) mV :(long) s
{
    if (self = [super init])
	{
		itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
		
		slice = s;
		fixViewer = fV;
		movingViewer = mV;
		
		itkImageFix = [[ITK alloc] initWith: [fixViewer pixList] :[fixViewer volumePtr] :slice];		
		itkImageMoving = [[ITK alloc] initWith: [movingViewer pixList] :[movingViewer volumePtr] :slice];
    }
    return self;
}

//- (void) computeRegistration
//{
//	const    unsigned int    Dimension = 3;
//	typedef  float           PixelType;
//	
//	typedef itk::Image< PixelType, Dimension >  FixedImageType;
//	typedef itk::Image< PixelType, Dimension >  MovingImageType;
//
//	typedef itk::TranslationTransform< double, Dimension > TransformType;
//
//	typedef itk::RegularStepGradientDescentOptimizer       OptimizerType;
//
//	typedef itk::MeanSquaresImageToImageMetric< 
//									FixedImageType, 
//									MovingImageType >    MetricType;
//
//	typedef itk:: LinearInterpolateImageFunction< 
//									MovingImageType,
//									double          >    InterpolatorType;
//
//	typedef itk::ImageRegistrationMethod< 
//									FixedImageType, 
//									MovingImageType >    RegistrationType;
//
//
//	MetricType::Pointer         metric        = MetricType::New();
//	TransformType::Pointer      transform     = TransformType::New();
//	OptimizerType::Pointer      optimizer     = OptimizerType::New();
//	InterpolatorType::Pointer   interpolator  = InterpolatorType::New();
//	RegistrationType::Pointer   registration  = RegistrationType::New();
//
//	registration->SetMetric(metric);
//	registration->SetOptimizer(optimizer);
//	registration->SetTransform(transform);
//	registration->SetInterpolator(interpolator);
//
//	// ** INPUT IMAGES
//	
//	registration->SetFixedImage(    [itkImageFix itkImporter]->GetOutput());
//	registration->SetMovingImage(   [itkImageMoving itkImporter]->GetOutput());
//	
//	registration->SetFixedImageRegion( [itkImageFix itkImporter]->GetOutput()->GetBufferedRegion() );
//
//	typedef RegistrationType::ParametersType ParametersType;
//	ParametersType initialParameters( transform->GetNumberOfParameters() );
//	
//	initialParameters[0] = 0.0;  // Initial offset in mm along X
//	initialParameters[1] = 0.0;  // Initial offset in mm along Y
//
//	registration->SetInitialTransformParameters( initialParameters );
//	
//	// ** EXECUTE
//	
//	optimizer->SetMaximumStepLength( 4.00 );  
//	optimizer->SetMinimumStepLength( 0.01 );
//	optimizer->SetNumberOfIterations( 200 );
//	
//	try 
//	{ 
//		registration->Update(); 
//	} 
//	catch( itk::ExceptionObject & err ) 
//	{ 
//		std::cout << "ExceptionObject caught !" << std::endl; 
//		std::cout << err << std::endl; 
//		return;
//	} 
//
//	// ** RESULTS
//	
//	ParametersType finalParameters = registration->GetLastTransformParameters();
//	
//	const double TranslationAlongX = finalParameters[0];
//	const double TranslationAlongY = finalParameters[1];
//	const unsigned int numberOfIterations = optimizer->GetCurrentIteration();
//	const double bestValue = optimizer->GetValue();
//	
//	std::cout << "Result = " << std::endl;
//	std::cout << " Translation X = " << TranslationAlongX  << std::endl;
//	std::cout << " Translation Y = " << TranslationAlongY  << std::endl;
//	std::cout << " Iterations    = " << numberOfIterations << std::endl;
//	std::cout << " Metric value  = " << bestValue          << std::endl;
//
//}

@end
