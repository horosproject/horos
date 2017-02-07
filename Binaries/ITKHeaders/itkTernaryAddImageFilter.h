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
#ifndef __itkTernaryAddImageFilter_h
#define __itkTernaryAddImageFilter_h

#include "itkTernaryFunctorImageFilter.h"

namespace itk
{
namespace Functor
{
/**
 * \class Add3
 * \brief
 * \ingroup ITKImageIntensity
 */
template< typename TInput1, typename TInput2, typename TInput3, typename TOutput >
class Add3
{
public:
  Add3() {}
  ~Add3() {}
  bool operator!=(const Add3 &) const
  {
    return false;
  }

  bool operator==(const Add3 & other) const
  {
    return !( *this != other );
  }

  inline TOutput operator()(const TInput1 & A,
                            const TInput2 & B,
                            const TInput3 & C) const
  { return (TOutput)( A + B + C ); }
};
}
/** \class TernaryAddImageFilter
 * \brief Pixel-wise addition of three images.
 *
 * This class is templated over the types of the three
 * input images and the type of the output image.
 * Numeric conversions (castings) are done by the C++ defaults.
 *
 * \ingroup IntensityImageFilters
 * \ingroup ITKImageIntensity
 */
template< typename TInputImage1, typename TInputImage2,
          typename TInputImage3, typename TOutputImage >
class TernaryAddImageFilter:
  public
  TernaryFunctorImageFilter< TInputImage1, TInputImage2,
                             TInputImage3, TOutputImage,
                             Functor::Add3< typename TInputImage1::PixelType,
                                            typename TInputImage2::PixelType,
                                            typename TInputImage3::PixelType,
                                            typename TOutputImage::PixelType >   >
{
public:
  /** Standard class typedefs. */
  typedef TernaryAddImageFilter Self;
  typedef TernaryFunctorImageFilter<
    TInputImage1, TInputImage2,
    TInputImage3, TOutputImage,
    Functor::Add3< typename TInputImage1::PixelType,
                   typename TInputImage2::PixelType,
                   typename TInputImage3::PixelType,
                   typename TOutputImage::PixelType >   >  Superclass;

  typedef SmartPointer< Self >       Pointer;
  typedef SmartPointer< const Self > ConstPointer;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Runtime information support. */
  itkTypeMacro(TernaryAddImageFilter,
               TernaryFunctorImageFilter);

protected:
  TernaryAddImageFilter() {}
  virtual ~TernaryAddImageFilter() {}

private:
  TernaryAddImageFilter(const Self &); //purposely not implemented
  void operator=(const Self &);        //purposely not implemented
};
} // end namespace itk

#endif
