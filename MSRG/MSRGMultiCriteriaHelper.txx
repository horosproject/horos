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


#ifndef _MSRGMultiCriteriaHelper_txx
#define _MSRGMultiCriteriaHelper_txx
#include "MSRGMultiCriteriaHelper.h"
#include "itkImageFileWriter.h"
template <class TInputImage, class TOutputImage>  typename MSRGMultiCriteriaHelper<TInputImage,TOutputImage>::OutputImagePointer  MSRGMultiCriteriaHelper<TInputImage,TOutputImage>::ExtractImageFromVectorialImageAtSlice(const ImageType* inputImage, int level)
{
	
	// Create the outputImage
	OutputImagePointer outputImage=OutputImageType::New(); 
	typename OutputImageType::RegionType region; 
	region.SetSize( inputImage->GetLargestPossibleRegion().GetSize() ); 
	outputImage->SetRegions(region);
	outputImage->Allocate();
	
	PixelType vectorPixel;
	
	typedef typename itk::ImageRegionConstIterator< ImageType > ConstIteratorType;
	typedef typename itk::ImageRegionIterator< OutputImageType> IteratorType;
	
	ConstIteratorType inputIt( inputImage, inputImage->GetRequestedRegion()  );
	IteratorType      outputIt(  outputImage, outputImage->GetRequestedRegion() );
	for ( inputIt.GoToBegin(), outputIt.GoToBegin(); !inputIt.IsAtEnd();
		  ++inputIt, ++outputIt)
	{
		vectorPixel=inputIt.Get(); 
		outputIt.Set( static_cast<OutputPixelType>(vectorPixel[level])); 
	}
	
	return outputImage;
}
// STATIC METHOD !  
template <class TInputImage, class TOutputImage>  void  MSRGMultiCriteriaHelper<TInputImage,TOutputImage>::buildVectorialImage(const ImageType* inputImage, OutputImageType* outputImage)
{
	 typedef typename itk::ImageRegionConstIterator< ImageType > ConstIteratorType;
     typedef typename itk::ImageRegionIterator< OutputImageType>       IteratorType;
	 
	 OutputPixelType vectorPixel;
	 ConstIteratorType inputIt( inputImage, inputImage->GetRequestedRegion()  );
	 IteratorType      outputIt(  outputImage, outputImage->GetRequestedRegion() );
	 for ( inputIt.GoToBegin(), outputIt.GoToBegin(); !inputIt.IsAtEnd();
			   ++inputIt, ++outputIt)
		 {
			 vectorPixel=outputIt.Get(); 		
			 vectorPixel[0]=inputIt.Get();  
			 outputIt.Set( vectorPixel); 
		 }

}
template <class TInputImage, class TOutputImage>  void  MSRGMultiCriteriaHelper<TInputImage,TOutputImage>::buildVectorialImageFromRGB(const ImageType* inputImage, OutputImageType* outputImage)
{
     typedef typename itk::ImageRegionConstIterator< ImageType > ConstIteratorType; // RGB Image
     typedef typename itk::ImageRegionIterator< OutputImageType>       IteratorType; // Criteria Image
	 
	 OutputPixelType vectorPixel;
	 typedef typename TInputImage::PixelType RGBType;
	 RGBType rgbPixel;
	 ConstIteratorType inputIt( inputImage, inputImage->GetRequestedRegion()  );
	 IteratorType      outputIt(  outputImage, outputImage->GetRequestedRegion() );
	 for ( inputIt.GoToBegin(), outputIt.GoToBegin(); !inputIt.IsAtEnd();
			   ++inputIt, ++outputIt)
		 {
			 vectorPixel=outputIt.Get(); 		
			 rgbPixel=inputIt.Get();
			 vectorPixel[0]=rgbPixel.GetRed();  
			 vectorPixel[1]=rgbPixel.GetGreen();  
			 vectorPixel[2]=rgbPixel.GetBlue();  
			 outputIt.Set( vectorPixel); 
		 }

}
// STATIC METHOD !  
template <class TInputImage, class TOutputImage>  void  MSRGMultiCriteriaHelper<TInputImage,TOutputImage>::MultiResolutionPyramid(const ImageType* inputImage, OutputImageType* outputImage)
{	
	
	
	const int Dimension = ImageType::ImageDimension; 
	unsigned int numberOfLevels=OutputPixelType::GetVectorDimension();
	
	typedef itk::Image< float, Dimension >    PyramidImageType;
	
	
    // MultiResolution Filter
	typedef typename itk::MultiResolutionPyramidImageFilter<ImageType, PyramidImageType > FixedImagePyramidType;
	typename FixedImagePyramidType::Pointer myPyramid = FixedImagePyramidType::New();
	myPyramid->SetNumberOfLevels(numberOfLevels );
	myPyramid->SetInput(inputImage ); 
	myPyramid->Update();
	
    // Resample the outputs images of MultiResolutionPyramidImageFilter
    typedef typename itk::ResampleImageFilter<PyramidImageType,PyramidImageType> FilterType;
    typename FilterType::Pointer filter = FilterType::New();
	
	typedef typename itk::AffineTransform< double, 2 >  TransformType;
    typename TransformType::Pointer transform = TransformType::New();
    filter->SetTransform( transform );
    typedef typename itk::NearestNeighborInterpolateImageFunction<PyramidImageType, double >  InterpolatorType;
    typename InterpolatorType::Pointer interpolator = InterpolatorType::New();
    filter->SetInterpolator( interpolator );
    filter->SetDefaultPixelValue( 0 );
    filter->SetOutputSpacing( inputImage->GetSpacing() );
    filter->SetOutputOrigin( inputImage->GetOrigin() );
    filter->SetSize(inputImage->GetLargestPossibleRegion().GetSize() );
	
	
	typedef typename itk::CastImageFilter< PyramidImageType, ImageType > CastingFilterType;
	typename CastingFilterType::Pointer caster = CastingFilterType::New();
	//InputImagePointer temp= ImageType::New(); // double check ...
	InputImagePointer temp;
	
  	 typedef typename itk::ImageRegionConstIterator< ImageType > ConstIteratorType;
     typedef typename itk::ImageRegionIterator< OutputImageType>       IteratorType;
	 
	 OutputPixelType vectorPixel;
	 
	 
	 for (unsigned int i = 0; i < myPyramid->GetNumberOfOutputs(); i++)
	 {	
		 filter->SetInput( myPyramid->GetOutput(i) );
		 caster->SetInput( filter->GetOutput());
		 caster->Update();
		 temp=caster->GetOutput();
		 ConstIteratorType inputIt( temp, temp->GetRequestedRegion()  );
		 IteratorType      outputIt(  outputImage, outputImage->GetRequestedRegion() );
		 for ( inputIt.GoToBegin(), outputIt.GoToBegin(); !inputIt.IsAtEnd();
			   ++inputIt, ++outputIt)
		 {
			 vectorPixel=outputIt.Get(); 		
			 vectorPixel[i]=inputIt.Get();  
			 outputIt.Set( vectorPixel); 
		 }
		 
	 }
}
template <class TInputImage, class TOutputImage>  void  MSRGMultiCriteriaHelper<TInputImage,TOutputImage>::saveAllSlices(const ImageType* inputImage)
{	
	unsigned int numberOfLevels=PixelType::GetVectorDimension();
	typedef typename itk::ImageFileWriter < OutputImageType > WriterType;
	typename WriterType::Pointer writer = WriterType::New ();
	//typename OutputImageType::Pointer temp=OutputImageType::New(); //TODO double check if we need the New()
	typename OutputImageType::Pointer temp; 
	for (unsigned int i = 0; i < numberOfLevels; i++)
	{
		char tempFilename[50];
		sprintf( tempFilename, "outputResolution%d.png", i );	
		temp=MSRGMultiCriteriaHelper<ImageType,OutputImageType>::ExtractImageFromVectorialImageAtSlice(inputImage,i);  
		writer->SetFileName (tempFilename);
		writer->SetInput (temp);
		
		try 
		{
			writer->Update ();
		} 
		catch (itk::ExceptionObject & excep) 
		{
			
			std::cerr << "MSRGMultiCriteriaHelper::saveAllSlices, Exception caught  !" << std::endl;
			std::cerr << excep << std::endl;
		} 
	}
}
#endif

