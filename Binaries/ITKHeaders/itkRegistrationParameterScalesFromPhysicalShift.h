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
#ifndef __itkRegistrationParameterScalesFromPhysicalShift_h
#define __itkRegistrationParameterScalesFromPhysicalShift_h

#include "itkRegistrationParameterScalesFromShiftBase.h"

namespace itk
{

/** \class RegistrationParameterScalesFromPhysicalShift
 *  \brief Registration helper class for estimating scales of
 * transform parameters a step sizes, from the maximum voxel shift
 * in physical space caused by a parameter change.
 *
 * \ingroup ITKOptimizersv4
 */
template < typename TMetric >
class RegistrationParameterScalesFromPhysicalShift :
  public RegistrationParameterScalesFromShiftBase< TMetric >
{
public:
  /** Standard class typedefs. */
  typedef RegistrationParameterScalesFromPhysicalShift        Self;
  typedef RegistrationParameterScalesFromShiftBase< TMetric > Superclass;
  typedef SmartPointer<Self>                                  Pointer;
  typedef SmartPointer<const Self>                            ConstPointer;

  /** Method for creation through the object factory. */
  itkNewMacro( Self );

  /** Run-time type information (and related methods). */
  itkTypeMacro( RegistrationParameterScalesFromPhysicalShift, RegistrationParameterScalesFromShiftBase );

  /** Type of scales */
  typedef typename Superclass::ScalesType                ScalesType;
  /** Type of parameters of the optimizer */
  typedef typename Superclass::ParametersType            ParametersType;
  /** Type of float */
  typedef typename Superclass::FloatType                 FloatType;

  typedef typename Superclass::VirtualPointType          VirtualPointType;
  typedef typename Superclass::VirtualIndexType          VirtualIndexType;
  typedef typename Superclass::MovingTransformType       MovingTransformType;
  typedef typename Superclass::FixedTransformType        FixedTransformType;
  typedef typename Superclass::JacobianType              JacobianType;
  typedef typename Superclass::VirtualImageConstPointer  VirtualImageConstPointer;

protected:
  RegistrationParameterScalesFromPhysicalShift();
  ~RegistrationParameterScalesFromPhysicalShift(){};

  virtual void PrintSelf(std::ostream &os, Indent indent) const;

  virtual void ComputeSampleShifts(const ParametersType &deltaParameters, ScalesType &localShifts);

private:
  RegistrationParameterScalesFromPhysicalShift(const Self&); //purposely not implemented
  void operator=(const Self&); //purposely not implemented

  template <typename TTransform>
  void ComputeSampleShiftsInternal(const ParametersType &deltaParameters, ScalesType &localShifts);

}; //class RegistrationParameterScalesFromPhysicalShift

}  // namespace itk


#ifndef ITK_MANUAL_INSTANTIATION
#include "itkRegistrationParameterScalesFromPhysicalShift.hxx"
#endif

#endif /* __itkRegistrationParameterScalesFromPhysicalShift_h */
