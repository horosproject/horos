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
