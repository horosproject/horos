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
#ifndef __itkJointHistogramMutualInformationComputeJointPDFThreaderBase_h
#define __itkJointHistogramMutualInformationComputeJointPDFThreaderBase_h

#include "itkDomainThreader.h"
#include "itkImage.h"

namespace itk
{

/** \class JointHistogramMutualInformationComputeJointPDFThreaderBase
 * \brief Comput the JointPDF image.
 *
 * This is a helper to compute the joint pdf image for the
 * JointHistogramMutualInformationImageToImageMetricv4.
 *
 * \ingroup ITKMetricsv4
 */
template < typename TDomainPartitioner, typename TJointHistogramMetric >
class JointHistogramMutualInformationComputeJointPDFThreaderBase
  : public DomainThreader< TDomainPartitioner, TJointHistogramMetric >
{
public:
  /** Standard class typedefs. */
  typedef JointHistogramMutualInformationComputeJointPDFThreaderBase  Self;
  typedef DomainThreader< TDomainPartitioner, TJointHistogramMetric > Superclass;
  typedef SmartPointer< Self >                                        Pointer;
  typedef SmartPointer< const Self >                                  ConstPointer;

  itkTypeMacro( JointHistogramMutualInformationComputeJointPDFThreaderBase, DomainThreader );

  /** Superclass types.  */
  typedef typename Superclass::DomainType    DomainType;
  typedef typename Superclass::AssociateType AssociateType;

  /** Types of the associate class. */
  typedef TJointHistogramMetric                                JointHistogramMetricType;
  typedef typename JointHistogramMetricType::VirtualImageType  VirtualImageType;
  typedef typename JointHistogramMetricType::VirtualIndexType  VirtualIndexType;
  typedef typename JointHistogramMetricType::VirtualPointType  VirtualPointType;
  typedef typename JointHistogramMetricType::JointPDFType      JointPDFType;
  typedef typename JointHistogramMetricType::JointPDFIndexType JointPDFIndexType;
  typedef typename JointHistogramMetricType::JointPDFPointType JointPDFPointType;
  typedef typename JointHistogramMetricType::JointPDFValueType JointPDFValueType;

  typedef typename JointHistogramMetricType::InternalComputationValueType InternalComputationValueType;

protected:
  JointHistogramMutualInformationComputeJointPDFThreaderBase();
  virtual ~JointHistogramMutualInformationComputeJointPDFThreaderBase();

  /** Create the \c m_JointPDFPerThread's. */
  virtual void BeforeThreadedExecution();

  /** Called by the \c ThreadedExecution of derived classes. */
  virtual void ProcessPoint( const VirtualIndexType & virtualIndex,
                             const VirtualPointType & virtualPoint,
                             const ThreadIdType threadId );

  /** Collect the results per and normalize. */
  virtual void AfterThreadedExecution();

  typedef Image< SizeValueType, 2 >                   JointHistogramType;
  //TODO: This needs updating
  struct JointHistogramMIPerThreadStruct
    {
    typename JointHistogramType::Pointer JointHistogram;
    SizeValueType                        JointHistogramCount;
    };
  itkPadStruct( ITK_CACHE_LINE_ALIGNMENT, JointHistogramMIPerThreadStruct,
                                            PaddedJointHistogramMIPerThreadStruct);
  itkAlignedTypedef( ITK_CACHE_LINE_ALIGNMENT, PaddedJointHistogramMIPerThreadStruct,
                                               AlignedJointHistogramMIPerThreadStruct );
  AlignedJointHistogramMIPerThreadStruct * m_JointHistogramMIPerThreadVariables;

private:
  JointHistogramMutualInformationComputeJointPDFThreaderBase( const Self & ); // purposely not implemented
  void operator=( const Self & ); // purposely not implemented
};

} // end namespace itk

#endif

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkJointHistogramMutualInformationComputeJointPDFThreaderBase.hxx"
#endif
