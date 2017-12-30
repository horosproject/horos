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

