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
#ifndef __itkGPUImageToImageFilter_hxx
#define __itkGPUImageToImageFilter_hxx

#include "itkGPUImageToImageFilter.h"

namespace itk
{

template< typename TInputImage, typename TOutputImage, typename TParentImageFilter >
GPUImageToImageFilter< TInputImage, TOutputImage, TParentImageFilter >::GPUImageToImageFilter() : m_GPUEnabled(true)
{
  m_GPUKernelManager = GPUKernelManager::New();
}

template< typename TInputImage, typename TOutputImage, typename TParentImageFilter >
GPUImageToImageFilter< TInputImage, TOutputImage, TParentImageFilter >::~GPUImageToImageFilter()
{
}

template< typename TInputImage, typename TOutputImage, typename TParentImageFilter >
void
GPUImageToImageFilter< TInputImage, TOutputImage, TParentImageFilter >::PrintSelf(std::ostream & os,
                                                                                  Indent indent) const
{
  Superclass::PrintSelf(os, indent);
  os << indent << "GPU: " << ( m_GPUEnabled ? "Enabled" : "Disabled" ) << std::endl;
}

template< typename TInputImage, typename TOutputImage, typename TParentImageFilter >
void
GPUImageToImageFilter< TInputImage, TOutputImage, TParentImageFilter >::GenerateData()
{
  if( !m_GPUEnabled ) // call CPU update function
    {
    Superclass::GenerateData();
    }
  else // call GPU update function
    {
    // Call a method to allocate memory for the filter's outputs
    this->AllocateOutputs();

    GPUGenerateData();
    }
}

template< typename TInputImage, typename TOutputImage, typename TParentImageFilter >
void
GPUImageToImageFilter< TInputImage, TOutputImage, TParentImageFilter >::GraftOutput(DataObject *output)
{
  typedef typename itk::GPUTraits< TOutputImage >::Type GPUOutputImage;
  typename GPUOutputImage::Pointer otPtr = dynamic_cast< GPUOutputImage * >( this->GetOutput() );

  otPtr->Graft( output );
}

template< typename TInputImage, typename TOutputImage, typename TParentImageFilter >
void
GPUImageToImageFilter< TInputImage, TOutputImage, TParentImageFilter >::GraftOutput(const DataObjectIdentifierType & key, DataObject *output)
{
  typedef typename itk::GPUTraits< TOutputImage >::Type GPUOutputImage;
  typename GPUOutputImage::Pointer otPtr = dynamic_cast< GPUOutputImage * >( this->ProcessObject::GetOutput(key) );

  otPtr->Graft( output );
}

} // end namespace itk

#endif
