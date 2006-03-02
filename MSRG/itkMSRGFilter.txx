/***************************************************************************
*              Copyright (C) 2004 by Arnaud GARCIA                        *
*                   arnaud.garcia@sim.hcuge.ch                            *
***************************************************************************/

#ifndef __itkMSRGFilter_txx_
#define __itkMSRGFilter_txx_

#include <queue>
#include <vector>
#include <itkMatrix.h>
#include "vnl/vnl_math.h"
#include "itkConnectedComponentImageFilter.h"
#include "itkImageLinearConstIteratorWithIndex.h"
#include "itkConstNeighborhoodIterator.h"
#include "itkMeanCalculator.h"
#include "itkCovarianceCalculator.h"
#include "itkMahalanobisDistanceMembershipFunction.h"
#include "itkVector.h"
#include "itkListSample.h"
#include "itkProgressReporter.h"
#include "SeedMSRG.h"
#include "itkListSample.h"
#include "itkMeanCalculator.h"
#include "MSRGImageHelper.h"
#include "MorphoHelper.h"
#include "itkMSRGFilter.h"
using namespace std;
namespace itk
{
	template < class TInputImage, class TOutputImage, class TCriteriaImage, unsigned int NbCriteria >
    MSRGFilter < TInputImage, TOutputImage, TCriteriaImage, NbCriteria >::MSRGFilter ()
{
		// TODO initialiser m_Marker
		//m_Upper = NumericTraits < InputImagePixelType >::max ();
}

template < class TInputImage, class TOutputImage, class TCriteriaImage, unsigned int NbCriteria >
void MSRGFilter <
TInputImage, TOutputImage, TCriteriaImage, NbCriteria >::PrintSelf (std::ostream & os, Indent indent) const
{
    this->Superclass::PrintSelf (os, indent);
}

template < class TInputImage, class TOutputImage, class TCriteriaImage, unsigned int NbCriteria >
void MSRGFilter <
TInputImage, TOutputImage, TCriteriaImage, NbCriteria >::GenerateInputRequestedRegion ()
{
    Superclass::GenerateInputRequestedRegion ();
    if (this->GetInput ())
	{
		InputImagePointer image =
		const_cast < InputImageType * >(this->GetInput ());
		image->SetRequestedRegionToLargestPossibleRegion ();
	}
}

template < class TInputImage,class TOutputImage, class TCriteriaImage, unsigned int NbCriteria >
void MSRGFilter <
TInputImage, TOutputImage, TCriteriaImage, NbCriteria >::EnlargeOutputRequestedRegion (DataObject * output)
{
    Superclass::EnlargeOutputRequestedRegion (output);
    output->SetRequestedRegionToLargestPossibleRegion ();
}

template < class TInputImage, class TOutputImage, class TCriteriaImage, unsigned int NbCriteria >
void MSRGFilter < TInputImage, TOutputImage, TCriteriaImage, NbCriteria >::GenerateData ()
{
	std::cout << "Inside MSRG Algorithm ..." << std::endl;
    InputImageConstPointer inputImage = this->GetInput ();
    OutputImagePointer outputImage = this->GetOutput ();
    
    const unsigned int MarkerDimension=OutputImageType::ImageDimension;
    const unsigned int CriteriaDimension=CriteriaImageType::ImageDimension;
	
    // *************************************************************
    // *                INIT        IMAGE                          *
    // *************************************************************  
	
	
    // Zero the output
    OutputImageRegionType region = outputImage->GetRequestedRegion ();
    outputImage->SetBufferedRegion (region);
    outputImage->Allocate ();
    outputImage->FillBuffer (NumericTraits < OutputImagePixelType >::Zero);
	
    // init status - 0 empty, 1 permanent, 2 in queue
	
	StatusImagePointer statusImage = StatusImageType::New ();
	statusImage->SetRegions(region);
	statusImage->Allocate();
	statusImage->FillBuffer (NumericTraits < StatusImagePixelType >::Zero);
	
    // *************************************************************
    // *                REGION INIT                                *
    // *************************************************************  
	
    // 1- Relabel marker image and find number of regions
	//MSRGImageHelper<MarkerImageType>::Display(m_Marker,"INSIDE - MakerImage  -");
	//m_Marker=MorphoHelper<MarkerImageType>::LabelImage(m_Marker);
	
	
	int NumberOfRegions=static_cast<int>(MSRGImageHelper<OutputImageType>::GetImageMax(m_Marker));
	std::cout << "NumberOfRegions=" << NumberOfRegions << std::endl;
    // 2- Extract internal zone for statistic init
    
	
    // 3 -Statistic init process (sample extraction for all regions)
	
	// 3.1 Sample creation
	
	
	typedef typename itk::Vector< CriteriaImagePixelType, NbCriteria > MeasurementVectorType;
	typedef typename  itk::Statistics::ListSample< MeasurementVectorType > SampleType;	
	typedef typename SampleType::Pointer SamplePointerType;
	SamplePointerType *SRGSample = new SamplePointerType[NumberOfRegions];
	
	for( int i=0; i<NumberOfRegions; i++ )
	{
		SRGSample[i]  = SampleType::New();
		SRGSample[i]->SetMeasurementVectorSize( NbCriteria );
	}
	
	typedef typename itk::ImageLinearConstIteratorWithIndex < OutputImageType > ConstIteratorType;
	ConstIteratorType inputIt (m_Marker, m_Marker->GetRequestedRegion ());
	inputIt.SetDirection (0);
	OutputImagePixelType label;
	IndexOutputType MarkerIndex;
	IndexCriteriaType CriteriaIndex;
	for (inputIt.GoToBegin (); !inputIt.IsAtEnd (); inputIt.NextLine ())
	{
		inputIt.GoToBeginOfLine ();
		while (!inputIt.IsAtEndOfLine ())
		{
			
			label=inputIt.Get ();
			if (label!=0)
			{
				MarkerIndex=inputIt.GetIndex ();
				
				for(int i=0;i<MarkerDimension;i++)
				{
					CriteriaIndex[i]=MarkerIndex[i];
					
				}
				CriteriaImagePixelType* buffVect=MSRGImageHelper<CriteriaImageType>::ExtractCriteriaVector(m_Criteria,CriteriaIndex,NbCriteria);
				MeasurementVectorType mv(buffVect);
				SRGSample[static_cast<int>(label)-1]->PushBack( mv );
				
			}
			
			++inputIt;
		}
	}  
	// 3.2 statistic evaluation
	// Mean
	typedef typename itk::Statistics::MeanCalculator< SampleType > MeanAlgorithmType;
	typedef typename MeanAlgorithmType::Pointer MeanPointerType;
	MeanPointerType*meanAlgorithm = new MeanPointerType[NumberOfRegions];
	for (int i=0;i<NumberOfRegions;i++){
		meanAlgorithm[i] = MeanAlgorithmType::New();
		meanAlgorithm[i]->SetInputSample( SRGSample[i]);
		meanAlgorithm[i]->Update();	
		std::cout << "Mean  Vector :" << *(meanAlgorithm[i]->GetOutput()) << std::endl;
		
		
	}
	// Covariance
	typedef typename itk::Statistics::CovarianceCalculator< SampleType > CovarianceAlgorithmType;
	typedef typename CovarianceAlgorithmType::Pointer CovariancePointerType;
	CovariancePointerType *covarianceAlgorithm = new CovariancePointerType[NumberOfRegions];
	for (int i=0;i<NumberOfRegions;i++){
		covarianceAlgorithm[i]= CovarianceAlgorithmType::New();
		covarianceAlgorithm[i]->SetInputSample( SRGSample[i] );
		covarianceAlgorithm[i]->SetMean( meanAlgorithm[i]->GetOutput() );
		covarianceAlgorithm[i]->Update();
		std::cout << "Covariance Matrix :\n" << *(covarianceAlgorithm[i]->GetOutput()) << std::endl;
		// if covariance matrix is =0 => set to identity, the evolution will be based only with the mean
		// @TODO: A voir avec Corinne ....
		vnl_matrix_fixed<double, NbCriteria, NbCriteria> mat=covarianceAlgorithm[i]->GetOutput()->GetVnlMatrix();
		int indic=0;
		for(int i=0;i<NbCriteria;i++)
			for(int j=0;j<NbCriteria;j++)
				if (mat[i][j]!=0)
					indic=1;
		if (indic==0)
		{
			//covarianceAlgorithm[i]->GetOutput()->SetIdentity();
			//std::cout << " ! Covariance Matrix is set to Identity:\n" << *(covarianceAlgorithm[i]->GetOutput()) << std::endl;
		}
		
	}
	
	typedef typename itk::Statistics::MahalanobisDistanceMembershipFunction< MeasurementVectorType > MahalanobisDistanceMembershipFunctionType;
	typename MahalanobisDistanceMembershipFunctionType::Pointer MahalanobisDistance = MahalanobisDistanceMembershipFunctionType::New();
	
    // 4- Add seeds to queue
	// *************************************************************
	// *                PRIORITY QUEUE INIT                        *
	// *************************************************************  
	IndexStatusType StatusIndex;
	typedef SeedMSRG < IndexOutputType, double > seedType;    
	priority_queue < seedType, vector < seedType >, seedType > PQ;
	seedType seed;
	
	for (inputIt.GoToBegin (); !inputIt.IsAtEnd (); inputIt.NextLine ())
	{
		inputIt.GoToBeginOfLine ();
		while (!inputIt.IsAtEndOfLine ())
		{
			label=inputIt.Get ();
			if (label!=0)
			{
				seed.index = inputIt.GetIndex ();
				seed.label = inputIt.Get ();
				for(int i=0;i<MarkerDimension;i++)
				{
					CriteriaIndex[i]=seed.index[i];
					StatusIndex[i]=seed.index[i];
				}
				CriteriaImagePixelType* buffVect=MSRGImageHelper<CriteriaImageType>::ExtractCriteriaVector(m_Criteria,CriteriaIndex,NbCriteria);
				MeasurementVectorType mv(buffVect);
				MahalanobisDistance->SetMean(*(meanAlgorithm[seed.label-1]->GetOutput()));
				MahalanobisDistance->SetCovariance(covarianceAlgorithm[seed.label-1]->GetOutput()->GetVnlMatrix());
				seed.distance=MahalanobisDistance->Evaluate(mv);
				PQ.push (seed);
			}
			++inputIt;
		}
	}  
	// *************************************************************
	// *                      MAIN                                 *
	// *************************************************************  
	
	typedef typename itk::ConstNeighborhoodIterator < OutputImageType > NeighborhoodIteratorType;
	typename NeighborhoodIteratorType::RadiusType radius;
	radius.Fill (1);
	NeighborhoodIteratorType it (radius, m_Marker, m_Marker->GetRequestedRegion ());
	OutputImagePixelType w;
	seedType pi;
	IndexOutputType piIndex, qiIndex;
	bool boundary = false;
	while (!PQ.empty ())
	{
		
		pi = PQ.top ();
		PQ.pop ();
		piIndex = pi.index;
		statusImage->SetPixel (piIndex, 1);
		outputImage->SetPixel (piIndex, pi.label);	// propagate label
		m_Marker->SetPixel (piIndex, pi.label); // Also in marker image ...
		it.SetLocation (piIndex);
		for (unsigned i = 0; i < it.Size (); i++)
		{
			w = it.GetPixel (i, boundary); 
			if (boundary)
			{		
				qiIndex = it.GetIndex (i);		
				if (statusImage->GetPixel (qiIndex) == 0) 
				{
					seed.index = qiIndex;
					seed.label = pi.label;
					for(int i=0;i<MarkerDimension;i++)
					{
						CriteriaIndex[i]=seed.index[i];
						StatusIndex[i]=seed.index[i];
					}
					statusImage->SetPixel (StatusIndex, 2);
					// compute Mahalanobis ...
					CriteriaImagePixelType* buffVect=MSRGImageHelper<CriteriaImageType>::ExtractCriteriaVector(m_Criteria,CriteriaIndex,NbCriteria);
					MeasurementVectorType mv(buffVect);
					MahalanobisDistance->SetMean(*(meanAlgorithm[seed.label-1]->GetOutput()));
					MahalanobisDistance->SetCovariance(covarianceAlgorithm[seed.label-1]->GetOutput()->GetVnlMatrix());
					seed.distance=MahalanobisDistance->Evaluate(mv);	
					PQ.push (seed);					
				}
			}
		}
		
	}
	//MSRGImageHelper<OutputImageType>::Display(m_Marker,"End of process - CB  -");
	
}


}
// end namespace itk

#endif
