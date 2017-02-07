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
#ifndef __itkPathToChainCodePathFilter_h
#define __itkPathToChainCodePathFilter_h

#include "itkPathToPathFilter.h"
#include "itkOffset.h"
//Templates require interfaces conforming to itkPath.h and itkChainCodePath.h

namespace itk
{
/** \class PathToChainCodePathFilter
 * \brief Filter that produces a chain code version of a path
 *
 * PathToChainCodePathFilter produces a chain code representation of a path.
 * If MaximallyConnectedOn() is called, then the resulting chain code will be
 * maximally connected (for example, 4-connected instead of 8-connected in 2D).
 *
 * \ingroup PathFilters
 * \ingroup ITKPath
 */
template< typename TInputPath, typename TOutputChainCodePath >
class PathToChainCodePathFilter:public
  PathToPathFilter< TInputPath, TOutputChainCodePath >
{
public:
  /** Standard class typedefs. */
  typedef PathToChainCodePathFilter                            Self;
  typedef PathToPathFilter< TInputPath, TOutputChainCodePath > Superclass;
  typedef SmartPointer< Self >                                 Pointer;
  typedef SmartPointer< const Self >                           ConstPointer;

  /** Method for creation through the object factory. */
  itkNewMacro(Self);

  /** Run-time type information (and related methods). */
  itkTypeMacro(PathToChainCodePathFilter, PathToPathFilter);

  /** Some convenient typedefs. */
  typedef TInputPath                         InputPathType;
  typedef typename InputPathType::Pointer    InputPathPointer;
  typedef typename InputPathType::InputType  InputPathInputType;
  typedef TOutputChainCodePath               OutputPathType;
  typedef typename OutputPathType::Pointer   OutputPathPointer;
  typedef typename OutputPathType::InputType OutputPathInputType;
  typedef typename InputPathType::IndexType  IndexType;
  typedef typename InputPathType::OffsetType OffsetType;

  /** Set the direction in which to reflect the data. */
  itkSetMacro(MaximallyConnected, bool)
  itkBooleanMacro(MaximallyConnected)

protected:
  PathToChainCodePathFilter();
  virtual ~PathToChainCodePathFilter() {}
  void PrintSelf(std::ostream & os, Indent indent) const;

  void GenerateData(void);

private:
  PathToChainCodePathFilter(const Self &); //purposely not implemented
  void operator=(const Self &);            //purposely not implemented

  bool m_MaximallyConnected;
};
} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkPathToChainCodePathFilter.hxx"
#endif

#endif
