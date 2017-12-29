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
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://www.osirix-viewer.com/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/


#ifndef __itkMSRGFilter_txx_
#define __itkMSRGFilter_txx_

#include <queue>
#include <vector>
#include <itkMatrix.h>
#include "vnl/vnl_math.h"
#include "itkConnectedComponentImageFilter.h"
#include "itkImageLinearConstIteratorWithIndex.h"
#include "itkMinimumMaximumImageCalculator.h"
#include "itkConstNeighborhoodIterator.h"
#include "itkMeanCalculator.h"
#include "itkCovarianceCalculator.h"
#include "itkMahalanobisDistanceMembershipFunction.h"
#include "itkSubtractImageFilter.h"
#include "itkVector.h"
#include "itkListSample.h"
#include "itkProgressReporter.h"
#include "SeedMSRG.h"
#include "itkListSample.h"
#include "itkMeanCalculator.h"
#include "MSRGImageHelper.h"
#include "MorphoHelper.h"
#include "itkMSRGFilter.h"
//#include "itkImageFileWriter.h"

using namespace std;
namespace itk
{
	template < class TInputImage > MSRGFilter < TInputImage >::MSRGFilter ()
{
		// default value
		labelMarker=false;
		// TODO initialiser m_Marker
		//m_Upper = NumericTraits < InputImagePixelType >::max ();
}

template < class TInputImage > void MSRGFilter < TInputImage >::PrintSelf (std::ostream & os, Indent indent) const
{
    this->Superclass::PrintSelf (os, indent);
}

template < class TInputImage > void MSRGFilter < TInputImage >::GenerateInputRequestedRegion ()
{
    Superclass::GenerateInputRequestedRegion ();
    if (this->GetInput ())
	{
		InputImagePointer image = const_cast < InputImageType * >(this->GetInput ());
		//image->SetRequestedRegionToLargestPossibleRegion ();
		image->SetRequestedRegion( m_Marker->GetRequestedRegion());
	}
}

template < class TInputImage > void MSRGFilter < TInputImage >::EnlargeOutputRequestedRegion (DataObject * output)
{
    Superclass::EnlargeOutputRequestedRegion (output);
	// output->SetRequestedRegionToLargestPossibleRegion ();
	this->GetOutput()->SetRequestedRegion( m_Marker->GetRequestedRegion() );
	
}


template < class TInputImage > void MSRGFilter < TInputImage >::GenerateData ()
{
	std::cout << "Inside MSRG Algorithm ..." << std::endl;
	
	
    InputImageConstPointer m_Criteria = this->GetInput ();
    OutputImagePointer outputImage = this->GetOutput ();
	
    
	
	typedef typename itk::ImageRegionIterator< OutputImageType > OutputIteratorType;
	typedef typename itk::ImageRegionConstIterator< OutputImageType > ConstOutputIteratorType;
	
    // *************************************************************
    // *                INIT        IMAGES                         *
    // *************************************************************  
	
	
    // Zero the output
    OutputImageRegionType region = outputImage->GetLargestPossibleRegion ();
    outputImage->SetBufferedRegion (region);
    outputImage->Allocate ();
 	outputImage->FillBuffer (NumericTraits < OutputImagePixelType >::Zero);
	
    // init status - 0 empty, 1 permanent, 2 in queue
	OutputImagePointer statusImage = OutputImageType::New ();
	statusImage->SetRegions(region);
	statusImage->Allocate();
	statusImage->FillBuffer (NumericTraits < OutputImagePixelType >::Zero);	
	statusImage->SetRequestedRegion(m_Marker->GetRequestedRegion());
	
    // *************************************************************
    // *                REGION INIT                                *
    // *************************************************************  
	
	OutputImagePointer relabelMarker;
	bool boundingBox=false;
	if (m_Marker->GetLargestPossibleRegion()!=m_Marker->GetRequestedRegion())
	{
		boundingBox=true;
		std::cout << "Bounding Box Activated !" << std::endl;
	}
	// Do we need to relabel the image markers ?
	if (labelMarker)
	{
		
		// PROBLEM: if you set a RequestedRegion the labelisation do not use it => if you have markers outside your bounding box
		// you will  have more regions ! => clear outside the bounding box.
		if (boundingBox)
		{
			//1- recopy the requested region to the status Image (tempory image)
			OutputIteratorType statusIterator( statusImage, statusImage->GetRequestedRegion ()  );
			OutputIteratorType markerIterator( m_Marker, m_Marker->GetRequestedRegion ()  );
			for ( statusIterator.GoToBegin(), markerIterator.GoToBegin(); !statusIterator.IsAtEnd();
				  ++statusIterator, ++markerIterator)
			{
				statusIterator.Set(markerIterator.Get());
			}
			
			//2- recopy the full statusImage to the marker image
			unsigned long outputImageDataSize = outputImage->GetPixelContainer()->Size();
			OutputImagePixelType* importPointer = statusImage->GetPixelContainer()->GetBufferPointer();
			OutputImagePixelType* bufferPointer = m_Marker->GetPixelContainer()->GetBufferPointer();
			memcpy(bufferPointer, importPointer, outputImageDataSize*sizeof(OutputImagePixelType));
			
			//3- don't forget to clean the statusImage
			statusImage->FillBuffer (NumericTraits < OutputImagePixelType >::Zero);
			
		}
		
		relabelMarker=MorphoHelper<OutputImageType>::LabelImage(m_Marker);
		m_Marker=relabelMarker;
	}
	
	m_Marker->SetRequestedRegion(statusImage->GetRequestedRegion ());
	
	// GetImageMax can works with requestedRegion => no problem when bounding is activated with setRequestedRegion
	int NumberOfRegions=static_cast<int>(MSRGImageHelper<OutputImageType>::GetImageMax(m_Marker));
	std::cout << "NumberOfRegions=" << NumberOfRegions << std::endl; 
	
	// *************************************************************
    // *                MEAN and COV EXTRACTION                    *
    // *************************************************************  
	
	
	typedef typename  itk::Statistics::ListSample< CriteriaImagePixelType > SampleType;
	typedef typename SampleType::Pointer SamplePointerType;
	SamplePointerType *SRGSample = new SamplePointerType[NumberOfRegions];
	
	for( int i=0; i<NumberOfRegions; i++ )
		SRGSample[i]  = SampleType::New();
	
	
	typedef typename itk::ImageRegionConstIterator< InputImageType>  ConstCriteriaIteratorType;
	ConstOutputIteratorType inputMarkerIt( m_Marker, m_Marker->GetRequestedRegion ()  );
	ConstCriteriaIteratorType  inputCriteriaIt(  m_Criteria, m_Criteria->GetRequestedRegion() );
	OutputImagePixelType label;
	
	// find samples for all regions...
	for ( inputMarkerIt.GoToBegin(), inputCriteriaIt.GoToBegin(); !inputMarkerIt.IsAtEnd();
		  ++inputMarkerIt, ++inputCriteriaIt)
	{
		label=inputMarkerIt.Get();
		if (label!=0)
			SRGSample[static_cast<int>(label)-1]->PushBack( inputCriteriaIt.Get() );
	}
	
	// Mean
	
	typedef typename itk::Statistics::MeanCalculator< SampleType > MeanAlgorithmType;
	typedef typename MeanAlgorithmType::Pointer MeanPointerType;
	MeanPointerType* meanAlgorithm = new MeanPointerType[NumberOfRegions];
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
	}
	
	
	
	
	
    //  Extract only the rings of the regions 
	// *************************************************************
	// *               SEEDS EXTRACTION                            *
	// *************************************************************  
	
	
	// extract initial solution (user markers)
	OutputImagePointer erodMarker=MorphoHelper<OutputImageType>::ErodeImageByRadius(m_Marker,1);
	
	// Overide SetRequestedRegion ! others itkFilters update to LargestPossibleRegion 
	m_Marker->SetRequestedRegion(statusImage->GetRequestedRegion ());
	erodMarker->SetRequestedRegion(statusImage->GetRequestedRegion ());
	
	
	
	ConstOutputIteratorType erodMarkerIt( erodMarker, erodMarker->GetRequestedRegion ()  );
	OutputIteratorType outputImageIt1( outputImage, outputImage->GetRequestedRegion ()  );
	
	for ( erodMarkerIt.GoToBegin(), outputImageIt1.GoToBegin(); !erodMarkerIt.IsAtEnd();
	 	  ++outputImageIt1, ++erodMarkerIt)
	{
		outputImageIt1.Set(erodMarkerIt.Get());
	}
	/*
	 OutputImagePixelType* importPointer = erodMarker->GetPixelContainer()->GetBufferPointer();
	 OutputImagePixelType* bufferPointer = outputImage->GetPixelContainer()->GetBufferPointer();
	 memcpy(bufferPointer, importPointer, outputImageDataSize*sizeof(OutputImagePixelType));
	 */
	// set status values to permanent 
	
	ConstOutputIteratorType outputImageIt( outputImage, outputImage->GetRequestedRegion ()  );
	OutputIteratorType statusIt( statusImage, statusImage->GetRequestedRegion ()  );
	for ( outputImageIt.GoToBegin(), statusIt.GoToBegin(); !outputImageIt.IsAtEnd();
		  ++outputImageIt, ++statusIt)
	{
		if (outputImageIt.Get()!=0)
			statusIt.Set(1); // permanent
	}
	
	
	// remove these points from the initial markerImage, so we will just have the ring of the region => (the inputs seeds for the PQ)	
	typedef typename itk::SubtractImageFilter<OutputImageType,OutputImageType,OutputImageType> SubtractFilterType;
	typename SubtractFilterType::Pointer subtractFilter = SubtractFilterType::New();
	subtractFilter->SetInput1(m_Marker);	
	subtractFilter->SetInput2(outputImage);	
	subtractFilter->Update();
	m_Marker=subtractFilter->GetOutput();
	
	// Overide SetRequestedRegion ! others itkFilters update to LargestPossibleRegion 
	m_Marker->SetRequestedRegion(statusImage->GetRequestedRegion ());
	outputImage->SetRequestedRegion(statusImage->GetRequestedRegion ());
				
	// *************************************************************
	// *                PRIORITY QUEUE INIT                        *
	// *************************************************************  
	
	
	typedef typename itk::Statistics::MahalanobisDistanceMembershipFunction< CriteriaImagePixelType > MahalanobisDistanceMembershipFunctionType;
	typename MahalanobisDistanceMembershipFunctionType::Pointer MahalanobisDistance = MahalanobisDistanceMembershipFunctionType::New();
	typedef typename itk::ImageLinearConstIteratorWithIndex < OutputImageType > ConstIteratorWithIndexType;
	ConstIteratorWithIndexType inputIt (m_Marker, m_Marker->GetRequestedRegion ());
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
				statusImage->SetPixel(seed.index,2); // in queue				
				MahalanobisDistance->SetMean(*(meanAlgorithm[seed.label-1]->GetOutput()));				 
				MahalanobisDistance->SetCovariance(covarianceAlgorithm[seed.label-1]->GetOutput()->GetVnlMatrix());
				seed.distance=MahalanobisDistance->Evaluate(m_Criteria->GetPixel(seed.index));
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
	NeighborhoodIteratorType it (radius, m_Marker, m_Marker->GetLargestPossibleRegion());//<= TODO:(BUG1) change to GetRequestedRegion when boundary works with it !
	OutputImagePixelType w;
	seedType pi;
	IndexOutputType piIndex, qiIndex,downRightCorner,upperLeftCorner,tempIndex;
	upperLeftCorner=m_Marker->GetRequestedRegion().GetIndex();//TODO: remove this line when BUG1 fixed
	downRightCorner=upperLeftCorner+m_Marker->GetRequestedRegion().GetSize();//TODO: remove this line when BUG1 fixed
	std::cout << "upperLeftCorner="<< upperLeftCorner <<std::endl;
	std::cout << "downRightCorner="<< downRightCorner <<std::endl;
	
	bool boundary = false;
	while (!PQ.empty ())
	{
		
		pi = PQ.top ();
		PQ.pop ();
		piIndex = pi.index;
		statusImage->SetPixel (piIndex, 1);
		outputImage->SetPixel (piIndex, pi.label);	// propagate label
		it.SetLocation (piIndex);
		for (unsigned i = 0; i < it.Size (); i++)
		{
			w = it.GetPixel (i, boundary); 
			// patch for BUG1
			if (boundingBox)
			{
				boundary = true;
				tempIndex=it.GetIndex (i);
				for (unsigned int k=0; k<ImageDimension; k++)
					if (tempIndex[k]<upperLeftCorner[k] || tempIndex[k]>=downRightCorner[k])
						boundary=false;	
			}
			
			if (boundary)
			{		
				qiIndex = it.GetIndex (i);		
				if (statusImage->GetPixel (qiIndex) == 0) 
				{
					seed.index = qiIndex;
					seed.label = pi.label;
					statusImage->SetPixel (seed.index, 2);
					MahalanobisDistance->SetMean(*(meanAlgorithm[seed.label-1]->GetOutput()));
					MahalanobisDistance->SetCovariance(covarianceAlgorithm[seed.label-1]->GetOutput()->GetVnlMatrix());
					seed.distance=MahalanobisDistance->Evaluate(m_Criteria->GetPixel(seed.index));	
					PQ.push (seed);					
				}
			}
		}
		
	}
	/*
	 typedef typename itk::ImageFileWriter < OutputImageType > WriterType;
	 typename WriterType::Pointer writer = WriterType::New ();
	 writer->SetFileName ("OsirixMSRGOutput.png");
	 writer->SetInput (outputImage);
	 writer->Update ();
	 */
}


}
// end namespace itk

#endif
