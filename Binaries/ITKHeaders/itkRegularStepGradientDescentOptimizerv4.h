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
#ifndef __itkRegularStepGradientDescentOptimizerv4_h
#define __itkRegularStepGradientDescentOptimizerv4_h

#include "itkGradientDescentOptimizerv4.h"
#include <itkCompensatedSummation.h>

namespace itk
{
  /** \class RegularStepGradientDescentOptimizerv4
   *  \brief Regular Step Gradient descent optimizer.
   *
   *   This optimizer is a variant of gradient descent that attempts to prevent it
   *   from taking steps that are too large. At each iteration, this optimizer
   *   will take a step along the direction of the metric derivative. Each time the
   *   direction of the derivative abruptly changes, the optimizer assumes that a
   *   local extrema has been passed and reacts by reducing the step length by a
   *   relaxation factor that is set to 0.5 by default.
   *   The default value for the initial step length is 1, and this value can only
   *   be changed manually via SetLearningRate() since this optimizer does not use
   *   the ScaleEstimator to automatically estimate the learning rate.
   *   Also note that unlike the previous version of ReuglarStepGradientDescentOptimizer,
   *   ITKv4 does not have a "maximize/minimize" option to modify the effect of
   *   the metric derivative. The assigned metric is assumed to return a parameter
   *   derivative result that "improves" the optimization.
   *
   * \ingroup ITKOptimizersv4
   */
template<typename TInternalComputationValueType>
class RegularStepGradientDescentOptimizerv4
: public GradientDescentOptimizerv4Template<TInternalComputationValueType>
{
public:
  /** Standard class typedefs. */
  typedef RegularStepGradientDescentOptimizerv4                               Self;
  typedef GradientDescentOptimizerv4Template<TInternalComputationValueType>   Superclass;
  typedef SmartPointer< Self >                                                Pointer;
  typedef SmartPointer< const Self >                                          ConstPointer;

  /** Run-time type information (and related methods). */
  itkTypeMacro(RegularStepGradientDescentOptimizerv4, Superclass);

  /** New macro for creation of through a Smart Pointer   */
  itkNewMacro(Self);


  /** It should be possible to derive the internal computation type from the class object. */
  typedef TInternalComputationValueType                     InternalComputationValueType;

  /** Derivative type */
  typedef typename Superclass::DerivativeType               DerivativeType;

  /** Metric type over which this class is templated */
  typedef typename Superclass::MeasureType                  MeasureType;
  typedef typename Superclass::IndexRangeType               IndexRangeType;
  typedef typename Superclass::ScalesType                   ScalesType;
  typedef typename Superclass::ParametersType               ParametersType;
  typedef typename Superclass::StopConditionType            StopConditionType;

  /** Compensated summation type */
  typedef CompensatedSummation< InternalComputationValueType >   CompensatedSummationType;

  /** Minimum step length (learning rate) value for convergence checking.
   *  The step length is decreased by relaxation factor if the step is too
   *  long, and the algorithm passes the local minimum.
   *  When the step length value reaches a small value, it would be treated
   *  as converged.
   *
   *  The default m_MinimumStepLength is set to 1e-4 to pass all
   *  tests.
   */
  itkSetMacro(MinimumStepLength, TInternalComputationValueType);
  itkGetConstReferenceMacro(MinimumStepLength, TInternalComputationValueType);

  /** Set/Get relaxation factor value */
  itkSetMacro(RelaxationFactor, TInternalComputationValueType);
  itkGetConstReferenceMacro(RelaxationFactor, TInternalComputationValueType);

  /** Set/Get gradient magnitude tolerance value */
  itkSetMacro(GradientMagnitudeTolerance, TInternalComputationValueType);
  itkGetConstReferenceMacro(GradientMagnitudeTolerance, TInternalComputationValueType);

  /** Start and run the optimization */
  virtual void StartOptimization( bool doOnlyInitialization = false ) ITK_OVERRIDE;

  /** Estimate the learning rate based on the current gradient. */
  virtual void EstimateLearningRate();

  /** Get current gradient step value */
  double GetCurrentStepLength() const;

protected:

  /** Advance one Step following the gradient direction.
   * Includes transform update. */
  virtual void AdvanceOneStep(void) ITK_OVERRIDE;

  /** Modify the input gradient over a given index range. */
  virtual void ModifyGradientByScalesOverSubRange( const IndexRangeType& subrange ) ITK_OVERRIDE;
  virtual void ModifyGradientByLearningRateOverSubRange( const IndexRangeType& subrange ) ITK_OVERRIDE;

  /**
   *  When the local minima is passed by taking a large step,
   *  the step size is adjusted by the relaxation factor, so we
   *  can take smaller steps toward the minimum point.
   */
  TInternalComputationValueType  m_RelaxationFactor;

  /** Default constructor */
  RegularStepGradientDescentOptimizerv4();

  /** Destructor */
  virtual ~RegularStepGradientDescentOptimizerv4();

  virtual void PrintSelf( std::ostream & os, Indent indent ) const;

  /** Minimum gradient step value for convergence checking */
  TInternalComputationValueType  m_MinimumStepLength;

  /** Minimum gradient magnitude value for convergence checking */
  TInternalComputationValueType  m_GradientMagnitudeTolerance;

  /** Current scale for learning rate */
  MeasureType                  m_CurrentLearningRateRelaxation;

private:
  RegularStepGradientDescentOptimizerv4( const Self & ); //purposely not implemented
  void operator=( const Self& ); //purposely not implemented
};

} // end namespace itk

#ifndef ITK_MANUAL_INSTANTIATION
#include "itkRegularStepGradientDescentOptimizerv4.hxx"
#endif

#endif
