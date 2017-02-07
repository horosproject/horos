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
#ifndef __itkFullToHalfHermitianImageFilter_h
#define __itkFullToHalfHermitianImageFilter_h

#include "itkImageToImageFilter.h"

namespace itk
{
/** \class FullToHalfHermitianImageFilter
 *
 * \brief Reduces the size of a full complex image produced from a
 * forward discrete Fourier transform of a real image to only the
 * non-redundant half of the image.
 *
 * In particular, this filter reduces the size of the image in the
 * first dimension to \f$\lfloor N/2 \rfloor + 1 \f$.
 *
 * \ingroup FourierTransform
 *
 * \sa HalfToFullHermitianImageFilter
 * \sa ForwardFFTImageFilter
 * \sa InverseFFTImageFilter
 * \sa RealToHalfHermitianForwardFFTImageFilter
 * \sa HalfHermitianToRealInverseFFTImageFilter
 * \ingroup ITKFFT
 */
template< typename TInputImage >
class FullToHalfHermitianImageFilter :
  public ImageToImageFilter< TInputImage, TInputImage >
{
public:
  /** Standard class typedefs. */
  typedef TInputImage                              InputImageType;
  typedef typename InputImageType::PixelType       InputImagePixelType;
  typedef typename InputImageType::IndexType       InputImageIndexType;
  typedef typename InputImageType::IndexValueType  InputImageIndexValueType;
  typedef typename InputImageType::SizeType        InputImageSizeType;
  typedef typename InputImageType::SizeValueType   InputImageSizeValueType;
  typedef typename InputImageType::RegionType      InputImageRegionType;
  typedef TInputImage                              OutputImageType;
  typedef typename OutputImageType::PixelType      OutputImagePixelType;
  typedef typename OutputImageType::IndexType      OutputImageIndexType;
  typedef typename OutputImageType::IndexValueType OutputImageIndexValueType;
  typedef typename OutputImageType::SizeType       OutputImageSizeType;
  typedef typename OutputImageType::SizeValueType  OutputImageSizeValueType;
  typedef typename OutputImageType::RegionType     OutputImageRegionType;

  typedef FullToHalfHermitianImageFilter                 Self;
  typedef ImageToImageFilter< TInputImage, TInputImage > Superclass;
  typedef SmartPointer< Self >                           Pointer;
  typedef SmartPointer< const Self >                     ConstPointer;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(FullToHalfHermitianImageFilter,
               ImageToImageFilter);

  /** Extract the dimensionality of the input and output images. */
  itkStaticConstMacro(ImageDimension, unsigned int,
                      TInputImage::ImageDimension);

protected:
  FullToHalfHermitianImageFilter() {}
  ~FullToHalfHermitianImageFilter() {}

  void ThreadedGenerateData(const OutputImageRegionType & outputRegionForThread,
                            ThreadIdType threadId);

  /** The output is a different size from the input. */
  virtual void GenerateOutputInformation();

  /** This class requires the entire input. */
  virtual void GenerateInputRequestedRegion();

private:
  FullToHalfHermitianImageFilter(const Self &); // purposely not implemented
  void operator=(const Self &);           // purposely not implemented
};
} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkFullToHalfHermitianImageFilter.hxx"
#endif

#endif // __itkFullToHalfHermitianImageFilter_h
