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


#ifndef __MorphoHelper_h
#define __MorphoHelper_h
#include "itkImage.h"
#include "itkGrayscaleErodeImageFilter.h"
#include "itkGrayscaleDilateImageFilter.h"
#include "itkBinaryBallStructuringElement.h" 
#include "itkSubtractImageFilter.h"
#include "itkRelabelComponentImageFilter.h"
#include "itkConnectedComponentImageFilter.h"

using namespace std;
template <class TImage> class MorphoHelper
{
public:
	typedef TImage ImageType;
	typedef typename ImageType::Pointer InputImagePointer;  
	typedef typename TImage::PixelType PixelType;
	static InputImagePointer InternalGradient(const ImageType* inputImage);
	static InputImagePointer ErodeImageByRadius(const ImageType* inputImage, int radius);
	static InputImagePointer DilateImageByRadius(const ImageType* inputImage, int radius);
	static InputImagePointer OpenImageByRadius(const ImageType* inputImage, int radius);
	static InputImagePointer CloseImageByRadius(const ImageType* inputImage, int radius);
	static InputImagePointer LabelImage(const ImageType* inputImage);
};
#ifndef ITK_MANUAL_INSTANTIATION
#include "MorphoHelper.txx"
#endif
#endif
