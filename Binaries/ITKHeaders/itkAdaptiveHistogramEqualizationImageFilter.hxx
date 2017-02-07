/*=========================================================================
 *
 *  Copyright Insight Software Consortium
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0.txt
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *=========================================================================*/
#ifndef __itkAdaptiveHistogramEqualizationImageFilter_hxx
#define __itkAdaptiveHistogramEqualizationImageFilter_hxx

#include <map>
#include <set>
#include "vnl/vnl_math.h"

#include "itkAdaptiveHistogramEqualizationImageFilter.h"
#include "itkImageRegionIterator.h"
#include "itkImageRegionIteratorWithIndex.h"
#include "itkConstNeighborhoodIterator.h"
#include "itkNeighborhoodAlgorithm.h"
#include "itkProgressReporter.h"

namespace itk
{
template< typename TImageType >
float
AdaptiveHistogramEqualizationImageFilter< TImageType >
::CumulativeFunction(float u, float v)
{
  // Calculate cumulative function
  float s, ad;

  s = vnl_math_sgn(u - v);
  ad = vnl_math_abs( 2.0 * ( u - v ) );

  return 0.5 *s *std::pow(ad, m_Alpha) - m_Beta * 0.5 * s * ad + m_Beta * u;
}

template< typename TImageType >
void
AdaptiveHistogramEqualizationImageFilter< TImageType >
::GenerateData()
{
  typename ImageType::ConstPointer input = this->GetInput();
  typename ImageType::Pointer output = this->GetOutput();

  // Allocate the output
  this->AllocateOutputs();

  unsigned int i;

  //Set the kernel value of PLAHE algorithm
  float kernel = 1;
  for ( i = 0; i < ImageDimension; i++ )
    {
    kernel = kernel * ( 2 * this->GetRadius()[i] + 1 );
    }
  kernel = 1 / kernel;

  // Iterator which traverse the input
  ImageRegionConstIterator< ImageType > itInput( input,
                                                 input->GetRequestedRegion() );

  // Calculate min and max gray level of an input image
  double min = static_cast< double >( itInput.Get() );
  double max = min;
  double value;
  while ( !itInput.IsAtEnd() )
    {
    value = static_cast< double >( itInput.Get() );
    if ( min > value )
      {
      min = value;
      }
    if ( max < value )
      {
      max = value;
      }
    ++itInput;
    }

  // Allocate a float type image which has the same size with an input image.
  // This image store normalized pixel values [-0.5 0.5] of the input image.
  typedef Image< float, ImageDimension > ImageFloatType;
  typename ImageFloatType::Pointer inputFloat = ImageFloatType::New();
  inputFloat->SetRegions( input->GetRequestedRegion() );
  inputFloat->Allocate();

  // Scale factors to convert back and forth to the [-0.5, 0.5] and
  // original gray level range
  float iscale = max - min;
  float scale = (float)1 / iscale;

  // Normalize input image to [-0.5 0.5] gray level and store in
  // inputFloat. AdaptiveHistogramEqualization only use float type
  // image which has gray range [-0.5 0.5]
  ImageRegionIterator< ImageFloatType > itFloat( inputFloat,
                                                 input->GetRequestedRegion() );

  itInput.GoToBegin(); // rewind the previous input iterator
  while ( !itInput.IsAtEnd() )
    {
    itFloat.Set(scale * ( itInput.Get() - min ) - 0.5);
    ++itFloat;
    ++itInput;
    }

  // Calculate cumulative array which will store the value of
  // cumulative function. During the AdaptiveHistogramEqualization
  // process, cumulative function will not be calculated, instead the
  // cumulative function will be pre-calculated and result will be
  // stored in cumulative array.  The cumulative array will be
  // referenced during AdaptiveHistogramEqualization processing.  This
  // pre-calculation can reduce computation time even though this
  // method uses a huge array.  If the cumulative array can not be
  // assigned, the cumulative function will be calculated each time.
  //
  //
  bool cachedCumulative = false;

  typedef std::set< float > FloatSetType;
  FloatSetType row;

  typedef std::map< std::pair< float, float >, float > ArrayMapType;
  ArrayMapType CumulativeArray;

  if ( m_UseLookupTable )
    {
    // determine what intensities are used on the input
    itFloat.GoToBegin(); // rewind the iterator for the normalized image
    while ( !itFloat.IsAtEnd() )
      {
      row.insert( itFloat.Get() );
      ++itFloat;
      }
    // only cache the array if it can be done without taking too much space
    if ( row.size() < ( input->GetRequestedRegion().GetNumberOfPixels() / 10 ) )
      {
      cachedCumulative = true;
      }
    else
      {
      cachedCumulative = false;
      row.clear();
      }

    if ( cachedCumulative )
      {
      // calculate cumulative function for each possible pairing of
      // intensities and store result in cumulative array
      FloatSetType::iterator itU, itV;
      ArrayMapType::key_type key;
      for ( itU = row.begin(); itU != row.end(); ++itU )
        {
        key.first = *itU;
        for ( itV = row.begin(); itV != row.end(); ++itV )
          {
          key.second = *itV;
          CumulativeArray.insert( ArrayMapType::value_type( key,
                                                            this->CumulativeFunction(*itU, *itV) ) );
          }
        }
      }
    }

  // Setup for processing the image
  //
  ZeroFluxNeumannBoundaryCondition< ImageFloatType > nbc;
  ConstNeighborhoodIterator< ImageFloatType >        bit;

  // Find the data-set boundary "faces"
  typename NeighborhoodAlgorithm::ImageBoundaryFacesCalculator< ImageFloatType >::FaceListType faceList;
  NeighborhoodAlgorithm::ImageBoundaryFacesCalculator< ImageFloatType > bC;
  faceList = bC( inputFloat, output->GetRequestedRegion(), this->GetRadius() );

  typename NeighborhoodAlgorithm::ImageBoundaryFacesCalculator< ImageFloatType >::FaceListType::iterator fit;

  // Map stores (number of pixel)/(window size) for each gray value.
  typedef std::map< float, float > MapType;
  MapType           count;
  MapType::iterator itMap;

  ProgressReporter progress( this, 0, output->GetRequestedRegion().GetNumberOfPixels() );

  // Process each faces.  These are N-d regions which border
  // the edge of the buffer.
  for ( fit = faceList.begin(); fit != faceList.end(); ++fit )
    {
    // Create a neighborhood iterator for the normalized image for the
    // region for this face
    bit = ConstNeighborhoodIterator< ImageFloatType >(this->GetRadius(),
                                                      inputFloat, *fit);
    bit.OverrideBoundaryCondition(&nbc);
    bit.GoToBegin();
    unsigned int neighborhoodSize = bit.Size();

    // iterator for the output for this face
    ImageRegionIterator< ImageType > itOut(output, *fit);

    // iterate over the region for this face
    ArrayMapType::key_type key;
    while ( !bit.IsAtEnd() )
      {
      // AdaptiveHistogramEqualization algorithm
      //
      //
      float f;
      float sum;

      // "Histogram the window"
      count.clear();
      for ( i = 0; i < neighborhoodSize; ++i )
        {
        f = bit.GetPixel(i);
        itMap = count.find(f);
        if ( itMap != count.end() )
          {
          count[f] = count[f] + kernel;
          }
        else
          {
          count.insert( MapType::value_type(f, kernel) );
          }
        }

      typedef typename ImageType::PixelType PixelType;

      // if we cached the cumulative array
      // if not, use CumulativeFunction()
      if ( cachedCumulative )
        {
        sum = 0;
        itMap = count.begin();
        f = bit.GetCenterPixel();
        key.first = f;
        while ( itMap != count.end() )
          {
          key.second = itMap->first;
          sum = sum
                + itMap->second * CumulativeArray[key];
          ++itMap;
          }
        itOut.Set( (PixelType)( iscale * ( sum + 0.5 ) + min ) );
        }
      else
        {
        sum = 0;
        itMap = count.begin();
        f = bit.GetCenterPixel();
        while ( itMap != count.end() )
          {
          sum = sum + itMap->second *CumulativeFunction(f, itMap->first);
          ++itMap;
          }
        itOut.Set( (PixelType)( iscale * ( sum + 0.5 ) + min ) );
        }

      // move the neighborhood
      ++bit;
      ++itOut;
      progress.CompletedPixel();
      }
    }
}

template< typename TImageType >
void
AdaptiveHistogramEqualizationImageFilter< TImageType >
::PrintSelf(std::ostream & os, Indent indent) const
{
  Superclass::PrintSelf(os, indent);

  os << "Alpha: " << m_Alpha << std::endl;
  os << "Beta: " << m_Beta << std::endl;
  os << "UseLookupTable: " << ( m_UseLookupTable ? "On" : "Off" ) << std::endl;
}
} // end namespace

#endif
