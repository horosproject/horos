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


#ifndef _MorphoHelper_txx
#define _MorphoHelper_txx
#include "MorphoHelper.h"

 // STATIC METHOD !  
   template <class TImage>  typename MorphoHelper<TImage>::InputImagePointer  MorphoHelper<TImage>::InternalGradient(const ImageType* inputImage)
   {	
	const int Dimension =ImageType::ImageDimension;  	
	// start gradient
	typedef itk::BinaryBallStructuringElement<PixelType,Dimension > StructuringElementType;
	typedef itk::GrayscaleErodeImageFilter<ImageType, ImageType,StructuringElementType >  ErodeFilterType;
	typedef itk::SubtractImageFilter<ImageType,ImageType,ImageType> SubtractFilterType;
	typename SubtractFilterType::Pointer subtractFilter = SubtractFilterType::New();	    
	typename ErodeFilterType::Pointer  grayscaleErode  = ErodeFilterType::New();	    
	StructuringElementType  structuringElement;
	structuringElement.SetRadius( 1 );  // 3x3 structuring element
	structuringElement.CreateStructuringElement();
	grayscaleErode->SetKernel(  structuringElement );
	grayscaleErode->SetInput(  inputImage );
	grayscaleErode->Update();
	subtractFilter->SetInput1(inputImage);	
	subtractFilter->SetInput2(grayscaleErode->GetOutput());	
	subtractFilter->Update();
	return subtractFilter->GetOutput();
   }
// STATIC METHOD !  
   template <class TImage>  typename MorphoHelper<TImage>::InputImagePointer  MorphoHelper<TImage>::ErodeImageByRadius(const ImageType* inputImage, int radius)
   {	
	const int Dimension =ImageType::ImageDimension;  	
	// start gradient
	typedef itk::BinaryBallStructuringElement<PixelType,Dimension > StructuringElementType;
	typedef itk::GrayscaleErodeImageFilter<ImageType, ImageType,StructuringElementType >  ErodeFilterType;
	typename ErodeFilterType::Pointer  grayscaleErode  = ErodeFilterType::New();	    
	StructuringElementType  structuringElement;
	structuringElement.SetRadius( radius );  
	structuringElement.CreateStructuringElement();
	grayscaleErode->SetKernel(  structuringElement );
	grayscaleErode->SetInput(  inputImage );
	grayscaleErode->Update();
	return grayscaleErode->GetOutput();
   }   
// STATIC METHOD !  
   template <class TImage>  typename MorphoHelper<TImage>::InputImagePointer  MorphoHelper<TImage>::DilateImageByRadius(const ImageType* inputImage, int radius)
   {	
	const int Dimension =ImageType::ImageDimension;  	
	// start gradient
	typedef itk::BinaryBallStructuringElement<PixelType,Dimension > StructuringElementType;
	typedef itk::GrayscaleDilateImageFilter<ImageType, ImageType,StructuringElementType >  DilateFilterType;
	typename DilateFilterType::Pointer  grayscaleDilate  = DilateFilterType::New();	    
	StructuringElementType  structuringElement;
	structuringElement.SetRadius( radius );  
	structuringElement.CreateStructuringElement();
	grayscaleDilate->SetKernel(  structuringElement );
	grayscaleDilate->SetInput(  inputImage );
	grayscaleDilate->Update();
	return grayscaleDilate->GetOutput();
   }      
// STATIC METHOD !  
   template <class TImage>  typename MorphoHelper<TImage>::InputImagePointer  MorphoHelper<TImage>::OpenImageByRadius(const ImageType* inputImage, int radius)
   {	
       InputImagePointer erodeImage=MorphoHelper<TImage>::ErodeImageByRadius(inputImage,radius);
	return MorphoHelper<TImage>::DilateImageByRadius(erodeImage,radius);
   }      
// STATIC METHOD !  
   template <class TImage>  typename MorphoHelper<TImage>::InputImagePointer  MorphoHelper<TImage>::CloseImageByRadius(const ImageType* inputImage, int radius)
   {	
       InputImagePointer dilateImage=MorphoHelper<TImage>::DilateImageByRadius(inputImage,radius);
	return MorphoHelper<TImage>::ErodeImageByRadius(dilateImage,radius);
   }      
template <class TImage>  typename MorphoHelper<TImage>::InputImagePointer  MorphoHelper<TImage>::LabelImage(const ImageType* inputImage){
   typedef itk::ConnectedComponentImageFilter < ImageType, ImageType > ConnectedComponentImageFilterType;
   typename ConnectedComponentImageFilterType::Pointer labelFilter = ConnectedComponentImageFilterType::New ();
   typedef itk::RelabelComponentImageFilter<ImageType, ImageType> RelabelImageComponentType;
   typename RelabelImageComponentType::Pointer relabelFilter=RelabelImageComponentType::New();
   labelFilter->SetInput(inputImage);
   relabelFilter->SetInput(labelFilter->GetOutput());
   relabelFilter->Update();
   return relabelFilter->GetOutput();
}   
#endif
