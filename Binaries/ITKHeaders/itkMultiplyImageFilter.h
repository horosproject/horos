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
#ifndef __itkMultiplyImageFilter_h
#define __itkMultiplyImageFilter_h

#include "itkBinaryFunctorImageFilter.h"

namespace itk
{
namespace Functor
{
/**
 * \class Mult
 * \brief
 * \ingroup ITKImageIntensity
 */
template< typename TInput1, typename TInput2 = TInput1, typename TOutput = TInput1 >
class Mult
{
public:
  Mult() {}
  ~Mult() {}
  bool operator!=(const Mult &) const
  {
    return false;
  }

  bool operator==(const Mult & other) const
  {
    return !( *this != other );
  }

  inline TOutput operator()(const TInput1 & A, const TInput2 & B) const
  { return (TOutput)( A * B ); }
};
}
/** \class MultiplyImageFilter
 * \brief Pixel-wise multiplication of two images.
 *
 * This class is templated over the types of the two
 * input images and the type of the output image.
 * Numeric conversions (castings) are done by the C++ defaults.
 *
 * \ingroup IntensityImageFilters
 * \ingroup MultiThreaded
 * \ingroup ITKImageIntensity
 *
 * \wiki
 * \wikiexample{ImageProcessing/MultiplyImageFilter,Multiply two images together}
 * \wikiexample{ImageProcessing/MultiplyByConstantImageFilter,Multiply every pixel in an image by a constant}
 * \endwiki
 */
template< typename TInputImage1, typename TInputImage2 = TInputImage1, typename TOutputImage = TInputImage1 >
class MultiplyImageFilter:
  public
  BinaryFunctorImageFilter< TInputImage1, TInputImage2, TOutputImage,
                            Functor::Mult<
                              typename TInputImage1::PixelType,
                              typename TInputImage2::PixelType,
                              typename TOutputImage::PixelType >   >
{
public:
  /** Standard class typedefs. */
  typedef MultiplyImageFilter Self;
  typedef BinaryFunctorImageFilter< TInputImage1, TInputImage2, TOutputImage,
                                    Functor::Mult<
                                      typename TInputImage1::PixelType,
                                      typename TInputImage2::PixelType,
                                      typename TOutputImage::PixelType >
                                    >                                 Superclass;
  typedef SmartPointer< Self >       Pointer;
  typedef SmartPointer< const Self > ConstPointer;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Runtime information support. */
  itkTypeMacro(MultiplyImageFilter,
               BinaryFunctorImageFilter);

#ifdef ITK_USE_CONCEPT_CHECKING
  // Begin concept checking
  itkConceptMacro( Input1Input2OutputMultiplyOperatorCheck,
                   ( Concept::MultiplyOperator< typename TInputImage1::PixelType,
                                                typename TInputImage2::PixelType,
                                                typename TOutputImage::PixelType > ) );
  // End concept checking
#endif

protected:
  MultiplyImageFilter() {}
  virtual ~MultiplyImageFilter() {}

private:
  MultiplyImageFilter(const Self &); //purposely not implemented
  void operator=(const Self &);      //purposely not implemented
};
} // end namespace itk

#endif
