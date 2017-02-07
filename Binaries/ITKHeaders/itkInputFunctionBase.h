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
#ifndef __itkInputFunctionBase_h
#define __itkInputFunctionBase_h

#include "itkFunctionBase.h"

namespace itk
{
namespace Statistics
{
/** \class InputFunctionBase
 * \brief This is the itkInputFunctionBase class.
 *
 * \ingroup ITKNeuralNetworks
 */

template<typename TMeasurementVector, typename TTargetVector>
class InputFunctionBase : public FunctionBase<TMeasurementVector, TTargetVector>
{
public:

  /** Standard class typedefs. */
  typedef InputFunctionBase                               Self;
  typedef FunctionBase<TMeasurementVector, TTargetVector> Superclass;
  typedef SmartPointer<Self>                              Pointer;
  typedef SmartPointer<const Self>                        ConstPointer;

  /** Run-time type information (and related methods). */
  itkTypeMacro(InputFunctionBase, FunctionBase);

  /** Input type */
  typedef TMeasurementVector InputVectorType;

  /** Output type */
  typedef TTargetVector OutputType;

  /** Evaluate at the specified input position */
  virtual OutputType Evaluate(const InputVectorType& input) const = 0;

  virtual void SetSize(unsigned int) = 0;

protected:

  InputFunctionBase() {};
  ~InputFunctionBase() {};

  /** Method to print the object. */
  virtual void PrintSelf( std::ostream& os, Indent indent ) const
    {
    os << indent << "InputFunctionBase(" << this << ")" << std::endl;
    Superclass::PrintSelf( os, indent );
    }

private:

  InputFunctionBase(const Self&); //purposely not implemented
  void operator=(const Self&); //purposely not implemented

};//class

} // end namespace Statistics
} // end namespace itk

#endif
