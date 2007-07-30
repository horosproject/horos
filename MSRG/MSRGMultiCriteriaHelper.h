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


#ifndef __MSRGMultiCriteriaHelper_h
#define __MSRGMultiCriteriaHelper_h
#include "itkImage.h"
#include "itkMultiResolutionPyramidImageFilter.h"
#include "itkResampleImageFilter.h"
#include "itkAffineTransform.h"
#include "itkNearestNeighborInterpolateImageFunction.h"
#include "itkImageRegionConstIterator.h"
#include "itkImageRegionIterator.h"

template <class TInputImage, class TOutputImage> class MSRGMultiCriteriaHelper
{
public:
	typedef TInputImage ImageType;
	typedef TOutputImage OutputImageType;
	
	typedef typename ImageType::Pointer InputImagePointer;  
	typedef typename TInputImage::PixelType PixelType;
	typedef typename TInputImage::IndexType InputImageIndex;
	
	typedef typename OutputImageType::Pointer OutputImagePointer;  
	typedef typename OutputImageType::PixelType OutputPixelType;
	
	// build a MultiResolution from inputImage => to outputImage (CriteriaImage), the number of levels is deduced from CriteriaImage Pixel depth ..
	static void MultiResolutionPyramid(const ImageType* inputImage,OutputImageType* outputImage);
	// build a VectorialImage from a standard inputImage ..
	static void buildVectorialImage(const ImageType* inputImage,OutputImageType* outputImage);
	static void buildVectorialImageFromRGB(const ImageType* inputImage,OutputImageType* outputImage);
	// image Extraction from the criteria (vectorial image) => the InputImage at the specified level 
	static OutputImagePointer ExtractImageFromVectorialImageAtSlice(const ImageType* inputImage, int level);
	
	// extract and save all the criteria images (inputImage) ... 
	
	//TODO add the format png, ect ... as a parameter !!
	static void saveAllSlices(const ImageType* inputImage);

		
	};
#ifndef ITK_MANUAL_INSTANTIATION
#include "MSRGMultiCriteriaHelper.txx"
#endif
#endif

