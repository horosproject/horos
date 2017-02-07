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
#ifndef __itkPasteImageFilter_hxx
#define __itkPasteImageFilter_hxx

#include "itkPasteImageFilter.h"
#include "itkObjectFactory.h"
#include "itkProgressReporter.h"
#include "itkImageAlgorithm.h"

namespace itk
{
/**
 *
 */
template< typename TInputImage, typename TSourceImage, typename TOutputImage >
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::PasteImageFilter()
{
  this->ProcessObject::SetNumberOfRequiredInputs(2);

  this->InPlaceOff();
  m_DestinationIndex.Fill(0);
}

template< typename TInputImage, typename TSourceImage, typename TOutputImage >
void
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::SetSourceImage(const SourceImageType *src)
{
  // Process object is not const-correct so the const casting is required.
  this->SetNthInput( 1, const_cast< SourceImageType * >( src ) );
}

template< typename TInputImage, typename TSourceImage, typename TOutputImage >
const typename PasteImageFilter< TInputImage, TSourceImage, TOutputImage >::SourceImageType *
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::GetSourceImage() const
{
  const SourceImageType *sourceImage =
    dynamic_cast< const SourceImageType * >( this->ProcessObject::GetInput(1) );

  return sourceImage;
}

template< typename TInputImage, typename TSourceImage, typename TOutputImage >
void
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::SetDestinationImage(const InputImageType *src)
{
  // Process object is not const-correct so the const casting is required.
  this->SetNthInput( 0, const_cast< InputImageType * >( src ) );
}

template< typename TInputImage, typename TSourceImage, typename TOutputImage >
const typename PasteImageFilter< TInputImage, TSourceImage, TOutputImage >::InputImageType *
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::GetDestinationImage() const
{
  const InputImageType *destinationImage =
    dynamic_cast< const InputImageType * >( this->ProcessObject::GetInput(0) );

  return destinationImage;
}

/**
 *
 */
template< typename TInputImage, typename TSourceImage, typename TOutputImage >
void
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::PrintSelf(std::ostream & os, Indent indent) const
{
  Superclass::PrintSelf(os, indent);

  os << indent << "DestinationIndex: " << m_DestinationIndex << std::endl;
  os << indent << "SourceRegion: " << m_SourceRegion << std::endl;
}

/**
 *
 */
template< typename TInputImage, typename TSourceImage, typename TOutputImage >
void
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::GenerateInputRequestedRegion()
{
  // call the superclass' implementation of this method
  Superclass::GenerateInputRequestedRegion();

  // get the pointers for the inputs and output
  InputImagePointer  destPtr = const_cast< InputImageType * >( this->GetInput() );
  SourceImagePointer sourcePtr = const_cast< SourceImageType * >( this->GetSourceImage() );
  OutputImagePointer outputPtr = this->GetOutput();

  if ( !destPtr || !sourcePtr || !outputPtr )
    {
    return;
    }

  // second input must include the SourceRegion
  sourcePtr->SetRequestedRegion(m_SourceRegion);

  // first input must match the output requested region
  destPtr->SetRequestedRegion( outputPtr->GetRequestedRegion() );
}

/**
   * PasteImageFilter can be implemented as a multithreaded filter.
   * Therefore, this implementation provides a ThreadedGenerateData()
   * routine which is called for each processing thread. The output
   * image data is allocated automatically by the superclass prior to
   * calling ThreadedGenerateData().  ThreadedGenerateData can only
   * write to the portion of the output image specified by the
   * parameter "outputRegionForThread"
   *
   * \sa ImageToImageFilter::ThreadedGenerateData(),
   *     ImageToImageFilter::GenerateData()
   */
template< typename TInputImage, typename TSourceImage, typename TOutputImage >
void
PasteImageFilter< TInputImage, TSourceImage, TOutputImage >
::ThreadedGenerateData(const OutputImageRegionType & outputRegionForThread,
                       ThreadIdType threadId)
{
  itkDebugMacro(<< "Actually executing");

  // Get the input and output pointers
  const InputImageType  *destPtr = this->GetInput();
  const SourceImageType *sourcePtr = this->GetSourceImage();
  OutputImageType       *outputPtr = this->GetOutput();

  // support progress methods/callbacks
  ProgressReporter progress( this, threadId, 1 );

  // What is the region on the destination image would be overwritten by the
  // source?
  // Do we need to use the source image at all for the region generated by this
  // thread?

  bool                  useSource;
  SourceImageRegionType sourceRegionInDestinationImage;
  SourceImageRegionType sourceRegionInDestinationImageCropped;
  sourceRegionInDestinationImage.SetIndex(m_DestinationIndex);
  sourceRegionInDestinationImage.SetSize( m_SourceRegion.GetSize() );

  if ( sourceRegionInDestinationImage.Crop(outputRegionForThread) )
    {
    // paste region is inside this thread
    useSource = true;
    sourceRegionInDestinationImageCropped = sourceRegionInDestinationImage;
    }
  else
    {
    // paste region is outside this thread
    useSource = false;
    }

  // If the source image needs to be used to generate the output image, does the
  // destination image need to be used? i.e. will the source region completely
  // overlap the destination region for this thread?
  bool useOnlySource;
  if ( useSource && ( sourceRegionInDestinationImageCropped == outputRegionForThread ) )
    {
    // sourceRegionInDestinationImage completely overlaps the output
    // region for this thread, so we'll only copy data from the source
    useOnlySource = true;
    }
  else
    {
    // sourceRegionInDestinationImage only partially overlaps the
    // output region for this thread so we need to copy from both
    // inputs
    useOnlySource = false;
    }

  // If the source needs to be used, what part of the source needs to copied
  // by this thread?
  SourceImageRegionType sourceRegionInSourceImageCropped;
  if ( useSource )
    {
    // what is the proposed shift from destination to source?
    Offset< InputImageDimension > originalOffsetFromDestinationToSource;
    originalOffsetFromDestinationToSource = m_SourceRegion.GetIndex() - m_DestinationIndex;

    // transform the cropped index back into the source image
    InputImageIndexType sourceIndexInSourceImageCropped;
    sourceIndexInSourceImageCropped = sourceRegionInDestinationImageCropped.GetIndex()
                                      + originalOffsetFromDestinationToSource;

    // set the values in the region
    sourceRegionInSourceImageCropped.SetIndex(sourceIndexInSourceImageCropped);
    sourceRegionInSourceImageCropped.SetSize( sourceRegionInDestinationImageCropped.GetSize() );
    }


  // There are three cases that we need to consider:
  //
  // 1. source region does not impact this thread, so copy data from
  //    from the destination image to the output
  //
  // 2. source region completely overlaps the output region for this
  //    thread, so copy data from the source image to the output
  //
  // 3. source region partially overlaps the output region for this
  //    thread, so copy data as needed from both the source and
  //    destination.
  //
  if ( !useSource && !( this->GetInPlace() && this->CanRunInPlace() ) )
    {
    // paste region is outside this thread, so just copy the destination
    // input to the output
    ImageAlgorithm::Copy( destPtr, outputPtr, outputRegionForThread, outputRegionForThread );

    progress.CompletedPixel();

    }
  else if ( useOnlySource )
    {
    // paste region completely overlaps the output region
    // for this thread, so copy data from the second input
    // to the output
    ImageAlgorithm::Copy(  sourcePtr, outputPtr, sourceRegionInSourceImageCropped, outputRegionForThread);

    progress.CompletedPixel();
    }
  else
    {
    // paste region partially overlaps the output region for the
    // thread, so we need copy data from both inputs as necessary. the
    // following code could be optimized.  this case could be
    // decomposed further such the output is broken into a set of
    // regions where each region would get data from either the
    // destination or the source images (but not both).  but for the
    // sake of simplicity and running under the assumption that the
    // source image is smaller than the destination image, we'll just
    // copy the destination to the output then overwrite the
    // appropriate output pixels with the source.

     if ( !( this->GetInPlace() && this->CanRunInPlace() ) )
       {
       // Copy destination to output
       ImageAlgorithm::Copy( destPtr, outputPtr, outputRegionForThread, outputRegionForThread );
       }

     // copy the cropped source region to output
     ImageAlgorithm::Copy( sourcePtr, outputPtr, sourceRegionInSourceImageCropped, sourceRegionInDestinationImageCropped );

     progress.CompletedPixel();
    }
}
} // end namespace itk

#endif
