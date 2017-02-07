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
#ifndef __itkLevelSetEvolutionUpdateLevelSetsThreader_h
#define __itkLevelSetEvolutionUpdateLevelSetsThreader_h

#include "itkCompensatedSummation.h"
#include "itkDomainThreader.h"
#include "itkLevelSetDenseImage.h"
#include "itkThreadedImageRegionPartitioner.h"

namespace itk
{

/** \class LevelSetEvolutionUpdateLevelSetsThreader
 * \brief Threade the UpdateLevelSets method.
 *
 * Thread the \c UpdateLevelSets method of the LevelSetEvolution class.
 *
 * \ingroup ITKLevelSetsv4
 */
template< typename TLevelSet, typename TDomainPartitioner, typename TLevelSetEvolution >
class LevelSetEvolutionUpdateLevelSetsThreader
{};

// For dense image level set.
template< typename TImage, typename TLevelSetEvolution >
class LevelSetEvolutionUpdateLevelSetsThreader< LevelSetDenseImage< TImage >, ThreadedImageRegionPartitioner< TImage::ImageDimension >, TLevelSetEvolution >
  : public DomainThreader< ThreadedImageRegionPartitioner< TImage::ImageDimension >, TLevelSetEvolution >
{
public:
  /** Standard class typedefs. */
  typedef LevelSetEvolutionUpdateLevelSetsThreader                                                       Self;
  typedef DomainThreader< ThreadedImageRegionPartitioner< TImage::ImageDimension >, TLevelSetEvolution > Superclass;
  typedef SmartPointer< Self >                                                                           Pointer;
  typedef SmartPointer< const Self >                                                                     ConstPointer;

  /** Run time type information. */
  itkTypeMacro( LevelSetEvolutionUpdateLevelSetsThreader, DomainThreader );

  /** Standard New macro. */
  itkNewMacro( Self );

  /** Superclass types. */
  typedef typename Superclass::DomainType    DomainType;
  typedef typename Superclass::AssociateType AssociateType;

  /** Types of the associate class. */
  typedef TLevelSetEvolution                                     LevelSetEvolutionType;
  typedef typename LevelSetEvolutionType::LevelSetContainerType  LevelSetContainerType;
  typedef typename LevelSetEvolutionType::LevelSetType           LevelSetType;
  typedef typename LevelSetEvolutionType::LevelSetImageType      LevelSetImageType;
  typedef typename LevelSetEvolutionType::LevelSetOutputRealType LevelSetOutputRealType;

protected:
  LevelSetEvolutionUpdateLevelSetsThreader();

  virtual void BeforeThreadedExecution();

  virtual void ThreadedExecution( const DomainType & imageSubRegion, const ThreadIdType threadId );

  virtual void AfterThreadedExecution();

  typedef CompensatedSummation< LevelSetOutputRealType > RMSChangeAccumulatorType;
  typedef std::vector< RMSChangeAccumulatorType > RMSChangeAccumulatorPerThreadType;

  RMSChangeAccumulatorPerThreadType m_RMSChangeAccumulatorPerThread;

private:
  LevelSetEvolutionUpdateLevelSetsThreader( const Self & ); // purposely not implemented
  void operator=( const Self & ); // purposely not implemented
};

} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkLevelSetEvolutionUpdateLevelSetsThreader.hxx"
#endif

#endif
