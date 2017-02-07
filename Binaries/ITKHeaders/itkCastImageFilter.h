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
#ifndef __itkCastImageFilter_h
#define __itkCastImageFilter_h

#include "itkUnaryFunctorImageFilter.h"
#include "itkProgressReporter.h"


namespace itk
{
namespace Functor
{
/** \class Cast
 *
 *  \deprecated This functor is no longer used by the CastImageFilter.
 * \ingroup ITKImageFilterBase
 */

template< typename TInput, typename TOutput >
class Cast
{
public:
  Cast() {}
  virtual ~Cast() {}
  bool operator!=(const Cast &) const
  {
    return false;
  }

  bool operator==(const Cast & other) const
  {
    return !( *this != other );
  }

  inline TOutput operator()(const TInput & A) const
  {
    return static_cast< TOutput >( A );
  }
};
}


/** \class CastImageFilter
 *
 * \brief Casts input pixels to output pixel type.
 *
 * This filter is templated over the input image type
 * and the output image type.
 *
 * A typical use is to cast a
 * \code
 * itk::Image<type1, dim>
 * \endcode
 * to a
 * \code
 * itk::Image<type2, dim>
 * \endcode
 *
 * This filter can also be used to cast a
 * \code
 * itk::VectorImage<type1, dim>
 * \endcode
 * to a
 * \code
 * itk::VectorImage<type2, dim>
 * \endcode
 *
 * If you need to perform a dimensionaly reduction, you may want
 * to use the ExtractImageFilter instead of the CastImageFilter.
 *
 * \ingroup IntensityImageFilters  MultiThreaded
 * \sa UnaryFunctorImageFilter
 * \sa ExtractImageFilter
 * \ingroup ITKImageFilterBase
 *
 * \wiki
 * \wikiexample{ImageProcessing/CastImageFilter,Cast an image from one type to another}
 * \endwiki
 */
template< typename TInputImage, typename TOutputImage >
class CastImageFilter:
    public UnaryFunctorImageFilter< TInputImage, TOutputImage,
                                    Functor::Cast<
                                      typename TInputImage::PixelType,
                                      typename TOutputImage::PixelType > >
{
public:
  /** Standard class typedefs. */
  typedef CastImageFilter Self;
  typedef UnaryFunctorImageFilter< TInputImage, TOutputImage,
                                   Functor::Cast<
                                     typename TInputImage::PixelType,
                                     typename TOutputImage::PixelType >
                                   >  Superclass;

  typedef SmartPointer< Self >       Pointer;
  typedef SmartPointer< const Self > ConstPointer;


  typedef typename Superclass::OutputImageRegionType OutputImageRegionType;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(CastImageFilter, UnaryFunctorImageFilter);

#ifdef ITK_USE_CONCEPT_CHECKING
  // Begin concept checking
  itkConceptMacro( InputConvertibleToOutputCheck,
                   ( Concept::Convertible< typename TInputImage::PixelType,
                                           typename TOutputImage::PixelType > ) );
  // End concept checking
#endif

protected:
  CastImageFilter();
  // virtual ~CastImageFilter() {} default OK

  void GenerateData() ITK_OVERRIDE;

  void ThreadedGenerateData(const OutputImageRegionType & outputRegionForThread, ThreadIdType threadId) ITK_OVERRIDE;

private:
  CastImageFilter(const Self &); //purposely not implemented
  void operator=(const Self &);  //purposely not implemented
};
} // end namespace itk

#endif


#ifndef ITK_MANUAL_INSTANTIATION
#include "itkCastImageFilter.hxx"
#endif
