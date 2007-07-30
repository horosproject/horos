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

#ifndef __MSRGImageHelper_h
#define __MSRGImageHelper_h
//#include <vnl/vnl_vector.h>
//#include <vnl/vnl_matrix.h>
#include "itkImage.h"
#include "itkImageLinearConstIteratorWithIndex.h"
#include "itkConstNeighborhoodIterator.h"
#include "itkConstShapedNeighborhoodIterator.h"
#include "itkImportImageFilter.h"
#include "itkMinimumMaximumImageCalculator.h"
#include "itkDiscreteGaussianImageFilter.h"
#include "itkNeighborhoodAlgorithm.h"
using namespace std;
template <class TImage>
class MSRGImageHelper
  {
  public:
    //typedef vnl_vector<double>  MeanVectorType;
    //typedef vnl_matrix<double>  CovarianceMatrixType;
    typedef TImage ImageType;
    static  int Dimension; 
    typedef typename ImageType::Pointer InputImagePointer;
    typedef typename ImageType::PixelType PixelType;
    typedef typename ImageType::IndexType IndexType;
    typedef typename ImageType::SizeType SizeType;
    static void Display (const ImageType* inputImage, char* title);
    static InputImagePointer BuildImageWithArray(PixelType* v, int* imageSize);
    static InputImagePointer GaussianImageFilter(const ImageType* inputImage, double variance, unsigned int kernelSize);
    static PixelType GetImageMax(const ImageType* inputImage);
    static PixelType GetImageMin(const ImageType* inputImage);
    static PixelType* ExtractCriteriaVector(const ImageType* inputImage, IndexType& index, int nbCrit);
    /*
     * compute the freePoint in the Neighborhood of point at index.
     * !!! if you use N8 you will just have the points not included in N4
     * so to have all the points in N8, use the function two times: once with N4 and then with N8
     * connectivity: 0 for knight, 4 for 4-conn, 8 for 8-conn
	*/
    static int computeFreePointIn2DNeighborhood(const ImageType* inputImage,IndexType index, int connectivity);
    static int computeFreePointIn3DNeighborhood(const ImageType* inputImage,IndexType index, int connectivity);
  };
#ifndef ITK_MANUAL_INSTANTIATION
#include "MSRGImageHelper.txx"
#endif
#endif
