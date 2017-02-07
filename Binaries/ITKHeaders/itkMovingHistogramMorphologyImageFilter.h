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
#ifndef __itkMovingHistogramMorphologyImageFilter_h
#define __itkMovingHistogramMorphologyImageFilter_h

#include "itkMorphologyHistogram.h"
#include "itkMovingHistogramImageFilter.h"
#include <list>
#include <map>

namespace itk
{

/**
 * \class MovingHistogramMorphologyImageFilter
 * \brief base class for MovingHistogramDilateImageFilter and MovingHistogramErodeImageFilter
 *
 * This class is similar to MovingHistogramImageFilter but add support
 * for boundaries and don't fully update the histogram to enhance performances.
 *
 * \sa MovingHistogramImageFilter, MovingHistogramDilateImageFilter, MovingHistogramErodeImageFilter
 * \ingroup ImageEnhancement  MathematicalMorphologyImageFilters
 * \ingroup ITKMathematicalMorphology
 */

template< typename TInputImage, typename TOutputImage, typename TKernel, typename THistogram >
class MovingHistogramMorphologyImageFilter:
  public MovingHistogramImageFilter< TInputImage, TOutputImage, TKernel, THistogram >
{
public:
  /** Standard class typedefs. */
  typedef MovingHistogramMorphologyImageFilter Self;
  typedef MovingHistogramImageFilter< TInputImage, TOutputImage, TKernel, THistogram >
  Superclass;
  typedef SmartPointer< Self >       Pointer;
  typedef SmartPointer< const Self > ConstPointer;

  /** Standard New method. */
  itkNewMacro(Self);

  /** Runtime information support. */
  itkTypeMacro(MovingHistogramMorphologyImageFilter,
               ImageToImageFilter);

  /** Image related typedefs. */
  typedef TInputImage                                InputImageType;
  typedef TOutputImage                               OutputImageType;
  typedef typename TInputImage::RegionType           RegionType;
  typedef typename TInputImage::SizeType             SizeType;
  typedef typename TInputImage::IndexType            IndexType;
  typedef typename TInputImage::PixelType            PixelType;
  typedef typename TInputImage::OffsetType           OffsetType;
  typedef typename Superclass::OutputImageRegionType OutputImageRegionType;
  typedef typename TOutputImage::PixelType           OutputPixelType;

  /** Image related typedefs. */
  itkStaticConstMacro(ImageDimension, unsigned int,
                      TInputImage::ImageDimension);

  /** Kernel typedef. */
  typedef TKernel KernelType;

  /** Kernel (structuring element) iterator. */
  typedef typename KernelType::ConstIterator KernelIteratorType;

  /** n-dimensional Kernel radius. */
  typedef typename KernelType::SizeType RadiusType;

  typedef typename std::list< OffsetType > OffsetListType;

  typedef typename std::map< OffsetType, OffsetListType, typename OffsetType::LexicographicCompare > OffsetMapType;

  /** Set/Get the boundary value. */
  itkSetMacro(Boundary, PixelType);
  itkGetConstMacro(Boundary, PixelType);

  /** Return true if the vector based algorithm is used, and
   * false if the map based algorithm is used */
  static bool GetUseVectorBasedAlgorithm()
  { return THistogram::UseVectorBasedAlgorithm(); }

protected:
  MovingHistogramMorphologyImageFilter();
  ~MovingHistogramMorphologyImageFilter() {}
  void PrintSelf(std::ostream & os, Indent indent) const;

  /** Multi-thread version GenerateData. */
//   void  ThreadedGenerateData (const OutputImageRegionType&
//                               outputRegionForThread,
//                               ThreadIdType threadId);

  /** needed to pass the boundary value to the histogram object */
  virtual void ConfigureHistogram(THistogram & histogram);

  PixelType m_Boundary;

private:
  MovingHistogramMorphologyImageFilter(const Self &); //purposely not
                                                      // implemented
  void operator=(const Self &);                       //purposely not
                                                      // implemented
};                                                    // end of class
} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkMovingHistogramMorphologyImageFilter.hxx"
#endif

#endif
