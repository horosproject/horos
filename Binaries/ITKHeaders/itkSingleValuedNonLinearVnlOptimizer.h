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
#ifndef __itkSingleValuedNonLinearVnlOptimizer_h
#define __itkSingleValuedNonLinearVnlOptimizer_h

#include "itkSingleValuedNonLinearOptimizer.h"
#include "itkSingleValuedVnlCostFunctionAdaptor.h"
#include "itkCommand.h"

namespace itk
{
/** \class SingleValuedNonLinearVnlOptimizer
 * \brief This class is a base for the Optimization methods that
 * optimize a single valued function.
 *
 * It is an Adaptor class for optimizers provided by the vnl library
 *
 * \ingroup Numerics Optimizers
 * \ingroup ITKOptimizers
 */
class SingleValuedNonLinearVnlOptimizer:
  public SingleValuedNonLinearOptimizer
{
public:
  /** Standard class typedefs. */
  typedef SingleValuedNonLinearVnlOptimizer Self;
  typedef SingleValuedNonLinearOptimizer    Superclass;
  typedef SmartPointer< Self >              Pointer;
  typedef SmartPointer< const Self >        ConstPointer;

  /** Run-time type information (and related methods). */
  itkTypeMacro(SingleValuedNonLinearVnlOptimizer,
               SingleValueNonLinearOptimizer);

  /** Command observer that will interact with the ITKVNL cost-function
   * adaptor in order to generate iteration events. This will allow to overcome
   * the limitation of VNL optimizers not offering callbacks for every
   * iteration */
  typedef ReceptorMemberCommand< Self > CommandType;

  /** Set the cost Function. This method has to be overloaded
   *  by derived classes because the CostFunctionAdaptor requires
   *  to know the number of parameters at construction time. This
   *  number of parameters is obtained at run-time from the itkCostFunction.
   *  As a consequence each derived optimizer should construct its own
   *  CostFunctionAdaptor when overloading this method  */
  virtual void SetCostFunction(SingleValuedCostFunction *costFunction) = 0;

  /** Methods to define whether the cost function will be maximized or
   * minimized. By default the VNL amoeba optimizer is only a minimizer.
   * Maximization is implemented here by notifying the CostFunctionAdaptor
   * which in its turn will multiply the function values and its derivative by
   * -1.0. */
  itkGetConstReferenceMacro(Maximize, bool);
  itkSetMacro(Maximize, bool);
  itkBooleanMacro(Maximize);
  bool GetMinimize() const
  { return !m_Maximize; }
  void SetMinimize(bool v)
  { this->SetMaximize(!v); }
  void MinimizeOn()
  { this->MaximizeOff(); }
  void MinimizeOff()
  { this->MaximizeOn(); }

  /** Return Cached Values. These method have the advantage of not triggering a
   * recomputation of the metric value, but it has the disadvantage of returning
   * a value that may not be the one corresponding to the current parameters. For
   * GUI update purposes, this method is a good option, for mathematical
   * validation you should rather call GetValue(). */
  itkGetConstReferenceMacro(CachedValue, MeasureType);
  itkGetConstReferenceMacro(CachedDerivative, DerivativeType);
  itkGetConstReferenceMacro(CachedCurrentPosition, ParametersType);

protected:
  SingleValuedNonLinearVnlOptimizer();
  virtual ~SingleValuedNonLinearVnlOptimizer();

  typedef SingleValuedVnlCostFunctionAdaptor CostFunctionAdaptorType;

  void SetCostFunctionAdaptor(CostFunctionAdaptorType *adaptor);

  const CostFunctionAdaptorType * GetCostFunctionAdaptor(void) const;

  CostFunctionAdaptorType * GetCostFunctionAdaptor(void);

  /** The purpose of this method is to get around the lack of
   *  const-correctness in VNL cost-functions and optimizers */
  CostFunctionAdaptorType * GetNonConstCostFunctionAdaptor(void) const;

  /** Print out internal state */
  virtual void PrintSelf(std::ostream & os, Indent indent) const ITK_OVERRIDE;

private:
  /** Callback function for the Command Observer */
  void IterationReport(const EventObject & event);

  SingleValuedNonLinearVnlOptimizer(const Self &); //purposely not implemented
  void operator=(const Self &);                    //purposely not implemented

  CostFunctionAdaptorType *m_CostFunctionAdaptor;

  bool m_Maximize;

  CommandType::Pointer m_Command;

  mutable ParametersType m_CachedCurrentPosition;
  mutable MeasureType    m_CachedValue;
  mutable DerivativeType m_CachedDerivative;
};
} // end namespace itk

#endif
